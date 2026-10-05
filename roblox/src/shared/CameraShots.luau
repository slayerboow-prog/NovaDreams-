-- CameraShots: las cuentas de los PLANOS DE CÁMARA de las escenas de la historia (shared/LifeStory/
-- Happenings). Son puras (sin servicios de Roblox): las usa el cliente (Controllers/HappeningClient)
-- y se prueban fuera de Roblox (scripts/test-scenes.luau).
--
-- Un plano es una tabla con At (segundo en que empieza) y Duration, y UNO de estos tipos:
--   Travelling   { From = P, To = P, Look = P, LookTo = P? }      la cámara viaja de From a To mirando a Look
--   Fijo         { Fixed = P, Look = P }                          trípode
--   Órbita       { Orbit = "Ancla", Radius, Height, FromAngle, ToAngle, LookHeight? }
--   Seguir       { Follow = "Ancla" | "Actor:Clave" | "Fx:Clave" | "Player", Offset = V3, Look = P?, Local = bool? }
--                (detrás y encima de lo que se sigue; Local = el desplazamiento gira con ello)
-- P = { "Ancla", Vector3?, Local? } igual que en Cinematics (Local = el desplazamiento va girado con el ancla).
-- Extras de cualquier plano:
--   Fov = 50 | { 70, 40 }   campo de visión fijo o zoom (70 = el normal)
--   Roll = -4               inclinar la cámara (grados)
--   Shake = 0.4             cámara en mano (temblor suave y continuo)
--   Easing = "In" | "Out" | "Linear" | nil (suave)
--   Cut = "Cut" | "Dip" | "Fade" | "Flash"   cómo se entra en el plano (corte seco, fundido rápido a
--                            negro, fundido lento, destello blanco)
-- Temblores sueltos (pista Shake de la escena): { At, Strength, Seconds } — un golpe que se apaga solo.
--
-- PLANOS CON NOMBRE (presets, CameraShots.preset): la escena pide un plano con intención y aquí se
-- traduce a los tipos de arriba (sin código nuevo de cámara en el cliente):
--   { At, Duration, Shot = "PrimerPlano:Lucia" }   (y en una línea de diálogo: Shot = "Reaccion:Mateo")
--   General[:X]        plano general de situación (alto y lejos, con un acercamiento lento)
--   Medio:X            plano medio (de cintura para arriba)
--   PrimerPlano:X      primer plano (la cara)            PPP:X   primerísimo primer plano (los ojos)
--   Hombro:X>Y         sobre el hombro de X mirando a Y   DosPlanos:X,Y   los dos en el mismo plano
--   Lateral:X          de perfil                          Reaccion:X      la cara de quien escucha
--   Seguir:X           detrás de X mientras anda          Inserto:Objeto  plano de un objeto (un ancla)
--   Dolly:X            la cámara se acerca (Reverse = se aleja)
--   Pan:X>Y            la cámara gira de X a Y sin moverse (Pan:X: barrido hasta X)
--   Tilt:X             la cámara sube de los pies a la cara (Reverse = baja)
-- X e Y son actores de la escena (su clave), "Yo" (el jugador) o un ancla. Los planos de cámara fija se
-- quedan «clavados» (Lock) donde estaba el actor al empezar el plano: si gira la cabeza, la cámara no
-- da bandazos. Para dos personas, las anclas compuestas (CameraShots.composite):
--   "Mid:A|B"     entre A y B, mirando hacia donde miran los dos (o hacia el jugador si se miran)
--   "Toward:A>B"  en A, mirando hacia B (para ponerse detrás de su hombro)
--
-- LUZ DE CINE (pista Light de las escenas, CameraShots.Lights): capas de luz por escena que se mezclan
-- encima de la luz de la hora (Controllers/DayLight) y SIEMPRE se quitan al acabar (StoryFx.setLight).

local CameraShots = {}

export type Shot = { [string]: any }
-- Cómo se encuentra un ancla: devuelve su CFrame (o nil si no existe ahora)
export type Resolver = (name: string) -> CFrame?

CameraShots.Cuts = { Cut = true, Dip = true, Fade = true, Flash = true }
CameraShots.Easings = { In = true, Out = true, Linear = true }
CameraShots.DEFAULT_FOV = 70

function CameraShots.ease(kind: string?, t: number): number
	t = math.clamp(t, 0, 1)
	if kind == "In" then
		return t * t
	elseif kind == "Out" then
		return 1 - (1 - t) * (1 - t)
	elseif kind == "Linear" then
		return t
	end
	return 0.5 - 0.5 * math.cos(math.pi * t)
end

-- Mirar de `at` hacia `target` (hecho a mano con fromMatrix: igual en Roblox y en las pruebas)
function CameraShots.lookAt(at: Vector3, target: Vector3): CFrame
	local look = target - at
	if look.Magnitude < 1e-6 then
		return CFrame.new(at)
	end
	look = look.Unit
	local right = look:Cross(Vector3.yAxis)
	if right.Magnitude < 1e-6 then
		right = look:Cross(Vector3.zAxis)
	end
	right = right.Unit
	return CFrame.fromMatrix(at, right, right:Cross(look).Unit, -look)
end

-- ¿Qué tipo de plano es?
function CameraShots.kind(shot: Shot): string?
	if shot.Orbit then
		return "Orbit"
	elseif shot.Follow then
		return "Follow"
	elseif shot.Fixed then
		return "Fixed"
	elseif shot.From then
		return "Travel"
	end
	return nil
end

-- El plano que toca en el segundo t de la escena y cuánto lleva (0..1). Entre planos (o después del
-- último) se queda congelado el último que empezó (u = 1): la cámara nunca salta al jugador a medias.
function CameraShots.active(shots: { Shot }, t: number): (Shot?, number, number?)
	local best, bestIndex = nil, nil
	for i, shot in shots do
		local at = shot.At or 0
		if at <= t + 1e-6 and (best == nil or at >= (best.At or 0)) then
			best, bestIndex = shot, i
		end
	end
	if not best then
		return nil, 0, nil
	end
	local duration = math.max(best.Duration or 1, 0.01)
	return best, math.clamp((t - (best.At or 0)) / duration, 0, 1), bestIndex
end

-- Un punto P = { "Ancla", offset?, local? } en el mundo
function CameraShots.point(resolve: Resolver, spec: { any }?): Vector3?
	if type(spec) ~= "table" then
		return nil
	end
	local anchor = resolve(spec[1])
	if not anchor then
		return nil
	end
	local offset = spec[2] or Vector3.zero
	return if spec[3] then anchor:PointToWorldSpace(offset) else anchor.Position + offset
end

-- Cámara en mano: temblor suave y orgánico (suma de senos a distintas velocidades), como Cinematics
function CameraShots.handheld(amount: number, clock: number): CFrame
	if amount <= 0 then
		return CFrame.identity
	end
	local a = amount * 0.02
	return CFrame.Angles(
		(math.sin(clock * 1.3) + math.sin(clock * 2.9 + 1.7) * 0.5) * a,
		(math.sin(clock * 1.1 + 0.6) + math.sin(clock * 2.3 + 2.1) * 0.5) * a,
		math.sin(clock * 0.7 + 0.3) * a * 0.6
	)
end

-- Golpes de temblor (pista Shake): cuánto tiembla en el segundo t (se apaga solo en Seconds)
function CameraShots.impulse(shakes: { { [string]: any } }?, t: number): number
	local total = 0
	for _, s in shakes or {} do
		local at = s.At or 0
		local seconds = math.max(s.Seconds or 0.6, 0.05)
		if t >= at and t < at + seconds then
			local k = 1 - (t - at) / seconds
			total = math.max(total, (s.Strength or 0.5) * k * k)
		end
	end
	return total
end

-- El temblor de un golpe convertido en movimiento de cámara (desplazamiento pequeño + giro)
function CameraShots.shakeOffset(strength: number, clock: number): CFrame
	if strength <= 0.001 then
		return CFrame.identity
	end
	local k = strength
	return CFrame.new(math.sin(clock * 47) * k * 0.35, math.cos(clock * 53) * k * 0.35, 0)
		* CFrame.Angles(math.sin(clock * 31) * k * 0.02, math.cos(clock * 37) * k * 0.02, 0)
end

-- Campo de visión del plano (nil = el normal)
function CameraShots.fov(shot: Shot, u: number): number?
	local fov = shot.Fov
	if type(fov) == "number" then
		return fov
	elseif type(fov) == "table" then
		return fov[1] + (fov[2] - fov[1]) * CameraShots.ease(shot.Easing, u)
	end
	return nil
end

-- Dónde está la cámara y hacia dónde mira (sin temblores). nil si falta un ancla.
function CameraShots.base(shot: Shot, u: number, resolve: Resolver): CFrame?
	local a = CameraShots.ease(shot.Easing, u)
	local kind = CameraShots.kind(shot)
	if kind == "Orbit" then
		local anchor = resolve(shot.Orbit)
		if not anchor then
			return nil
		end
		local center = anchor.Position
		local angle = math.rad((shot.FromAngle or 0) + ((shot.ToAngle or 0) - (shot.FromAngle or 0)) * a)
		local radius = shot.Radius or 12
		local position = center + Vector3.new(math.cos(angle) * radius, shot.Height or 4, math.sin(angle) * radius)
		return CameraShots.lookAt(position, center + Vector3.new(0, shot.LookHeight or 1, 0))
	elseif kind == "Follow" then
		local target = resolve(shot.Follow)
		if not target then
			return nil
		end
		local offset = shot.Offset or Vector3.new(0, 4, 10)
		local position = if shot.Local then target:PointToWorldSpace(offset) else target.Position + offset
		local look = CameraShots.point(resolve, shot.Look) or target.Position
		if (look - position).Magnitude < 0.05 then
			look += Vector3.new(0, 0, -1)
		end
		return CameraShots.lookAt(position, look)
	elseif kind == "Fixed" then
		local position = CameraShots.point(resolve, shot.Fixed)
		local look = CameraShots.point(resolve, shot.Look)
		if not position or not look then
			return nil
		end
		if (look - position).Magnitude < 0.05 then
			look += Vector3.new(0, 0, -1)
		end
		return CameraShots.lookAt(position, look)
	elseif kind == "Travel" then
		local from, to = CameraShots.point(resolve, shot.From), CameraShots.point(resolve, shot.To or shot.From)
		local look = CameraShots.point(resolve, shot.Look)
		local lookTo = CameraShots.point(resolve, shot.LookTo) or look
		if not from or not to or not look or not lookTo then
			return nil
		end
		local position = from:Lerp(to, a)
		local target = look:Lerp(lookTo, a)
		if (target - position).Magnitude < 0.05 then
			target += Vector3.new(0, 0, -1)
		end
		return CameraShots.lookAt(position, target)
	end
	return nil
end

-- El plano completo: base + inclinación + cámara en mano + golpes de temblor
function CameraShots.cframe(shot: Shot, u: number, resolve: Resolver, clock: number, impulse: number?): CFrame?
	local cf = CameraShots.base(shot, u, resolve)
	if not cf then
		return nil
	end
	if shot.Roll then
		cf *= CFrame.Angles(0, 0, math.rad(shot.Roll))
	end
	cf *= CameraShots.handheld(shot.Shake or 0, clock)
	return cf * CameraShots.shakeOffset(impulse or 0, clock)
end

-- Lo que hay que revisar de un plano (para las pruebas y Validate): nombres de ancla que usa
function CameraShots.anchorsOf(shot: Shot): { string }
	local list = {}
	local function add(spec: any)
		if type(spec) == "table" and type(spec[1]) == "string" then
			table.insert(list, spec[1])
		elseif type(spec) == "string" then
			table.insert(list, spec)
		end
	end
	add(shot.Orbit)
	add(shot.Follow)
	add(shot.Fixed)
	add(shot.From)
	add(shot.To)
	add(shot.Look)
	add(shot.LookTo)
	return list
end

---------------------------------------------------------------------
-- Anclas compuestas: entre dos (Mid) y de uno hacia otro (Toward)
---------------------------------------------------------------------
local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- Envuelve un resolver para que entienda "Mid:A|B" y "Toward:A>B" (A y B: nombres de ancla)
function CameraShots.composite(resolve: Resolver): Resolver
	local function wrapped(name: string): CFrame?
		if type(name) ~= "string" then
			return nil
		end
		local a, b = name:match("^Mid:(.+)|(.+)$")
		if a and b then
			local ca, cb = wrapped(a), wrapped(b)
			if not ca or not cb then
				return ca or cb
			end
			local mid = ca.Position:Lerp(cb.Position, 0.5)
			local across = flat(cb.Position - ca.Position)
			if across.Magnitude < 1e-3 then
				return CFrame.new(mid) * ca.Rotation
			end
			local right = across.Unit
			local front = Vector3.yAxis:Cross(right)
			-- Hacia donde miran los dos; si se miran el uno al otro, hacia el jugador (el que lo ve)
			local facing = flat(ca.LookVector + cb.LookVector)
			if facing.Magnitude < 0.2 then
				local me = resolve("Player")
				facing = if me then flat(me.Position - mid) else Vector3.zero
			end
			if facing:Dot(front) < 0 then
				front = -front
			end
			return CameraShots.lookAt(mid, mid + front)
		end
		local from, to = name:match("^Toward:(.+)>(.+)$")
		if from and to then
			local cf, target = wrapped(from), wrapped(to)
			if not cf or not target then
				return cf
			end
			local dir = flat(target.Position - cf.Position)
			if dir.Magnitude < 1e-3 then
				return cf
			end
			return CameraShots.lookAt(cf.Position, cf.Position + dir)
		end
		return resolve(name)
	end
	return wrapped
end

-- Un resolver que recuerda la primera posición de cada ancla (planos con Lock): la cámara no sigue los
-- giros pequeños de un actor mientras dura el plano. `real(name)` dice si lo encontrado es de verdad
-- (si el actor aún no ha aparecido, no se recuerda y se vuelve a preguntar).
function CameraShots.locked(resolve: Resolver, real: ((string) -> boolean)?): Resolver
	local cache: { [string]: CFrame } = {}
	return function(name: string): CFrame?
		local known = cache[name]
		if known then
			return known
		end
		local cf = resolve(name)
		if cf and (real == nil or real(name)) then
			cache[name] = cf
		end
		return cf
	end
end

---------------------------------------------------------------------
-- Planos con nombre (presets)
---------------------------------------------------------------------
local V = Vector3.new

-- Cuántos nombres pide cada plano { mínimo, máximo }
CameraShots.Presets = {
	General = { 0, 1 },
	Medio = { 1, 1 },
	PrimerPlano = { 1, 1 },
	PPP = { 1, 1 },
	Hombro = { 2, 2 },
	DosPlanos = { 2, 2 },
	Lateral = { 1, 1 },
	Reaccion = { 1, 1 },
	Seguir = { 1, 1 },
	Inserto = { 1, 1 },
	Dolly = { 1, 1 },
	Pan = { 1, 2 },
	Tilt = { 1, 1 },
}

-- "Hombro:Lucia>Yo" -> "Hombro", { "Lucia", "Yo" }. Separadores: ">" (de uno a otro) o "," (los dos)
function CameraShots.parsePreset(spec: any): (string?, { string })
	if type(spec) ~= "string" then
		return nil, {}
	end
	local kind, rest = spec:match("^(%a+):(.+)$")
	if not kind then
		kind, rest = spec:match("^(%a+)$"), nil
	end
	local args = {}
	if rest then
		local sep = if rest:find(">", 1, true) then ">" else ","
		for part in (rest .. sep):gmatch("(.-)%" .. sep) do
			part = part:match("^%s*(.-)%s*$")
			if part ~= "" then
				table.insert(args, part)
			end
		end
	end
	return kind, args
end

-- Qué ancla es cada nombre: "Yo"/"Player" = el jugador; lo que diga `refs` (tabla o función); si no,
-- un actor de la escena ("Actor:<clave>"). Un nombre con prefijo ("Fx:M1", "Actor:X") se queda igual.
local function refOf(name: string, refs: any): string
	if name == "Yo" or name == "Player" then
		return "Player"
	end
	if name:match("^%a+:") then
		return name
	end
	if type(refs) == "function" then
		local r = refs(name)
		if r then
			return r
		end
	elseif type(refs) == "table" and refs[name] then
		return refs[name]
	end
	return "Actor:" .. name
end

-- Traduce un plano con nombre a un plano normal (travelling, fijo o seguir). Devuelve nil y el motivo
-- si el nombre no existe o le faltan personajes. `refs`: ver refOf. "General" sin nombre usa refs["*"].
function CameraShots.preset(spec: any, refs: any): (Shot?, string?)
	local kind, args = CameraShots.parsePreset(spec)
	local arity = kind and CameraShots.Presets[kind]
	if not kind or not arity then
		return nil, ("plano desconocido '%s'"):format(tostring(spec))
	end
	if #args < arity[1] or #args > arity[2] then
		return nil, ("el plano %s pide %d personaje(s)"):format(kind, arity[1])
	end
	local function center(): string
		if type(refs) == "table" and refs["*"] then
			return refs["*"]
		end
		return "Player"
	end
	local x = if args[1] then refOf(args[1], refs) else center()
	local y = if args[2] then refOf(args[2], refs) else nil
	local shot: Shot
	if kind == "General" then
		shot = { From = { x, V(10, 9, -26), true }, To = { x, V(7, 8, -21), true }, Look = { x, V(0, 1.5, 0) }, Fov = 60 }
	elseif kind == "Medio" then
		shot = { From = { x, V(1.6, 1.3, -8), true }, To = { x, V(1.2, 1.3, -7.2), true }, Look = { x, V(0, 1.1, 0) }, Fov = 55 }
	elseif kind == "PrimerPlano" then
		shot = { From = { x, V(0.8, 1.6, -4.6), true }, To = { x, V(0.7, 1.6, -4.2), true }, Look = { x, V(0, 1.5, 0) }, Fov = 45 }
	elseif kind == "PPP" then
		shot = { Fixed = { x, V(0.35, 1.55, -2.8), true }, Look = { x, V(0, 1.55, 0) }, Fov = 32, Shake = 0.1 }
	elseif kind == "Hombro" then
		local over = "Toward:" .. x .. ">" .. (y :: string)
		shot = { From = { over, V(1.5, 2, 3.6), true }, To = { over, V(1.4, 2, 3.3), true }, Look = { y, V(0, 1.4, 0) }, Fov = 50 }
	elseif kind == "DosPlanos" then
		local mid = "Mid:" .. x .. "|" .. (y :: string)
		shot = { From = { mid, V(0, 1.6, -10.5), true }, To = { mid, V(0, 1.6, -9.5), true }, Look = { mid, V(0, 1.2, 0) }, Fov = 55 }
	elseif kind == "Lateral" then
		shot = { From = { x, V(7, 1.4, -0.6), true }, To = { x, V(7, 1.4, 0.6), true }, Look = { x, V(0, 1.2, 0) }, Fov = 50 }
	elseif kind == "Reaccion" then
		shot = { From = { x, V(-0.9, 1.5, -5), true }, To = { x, V(-0.7, 1.5, -4.2), true }, Look = { x, V(0, 1.45, 0) }, Fov = 45, Cut = "Cut" }
	elseif kind == "Seguir" then
		shot = { Follow = x, Offset = V(0, 3.5, 10), Local = true, Look = { x, V(0, 1.5, 0) } }
	elseif kind == "Inserto" then
		shot = { From = { x, V(2.2, 2.4, 2.8) }, To = { x, V(1.6, 1.8, 2) }, Look = { x, V(0, 0.4, 0) }, Fov = 40 }
	elseif kind == "Dolly" then
		shot = { From = { x, V(0.8, 1.5, -11), true }, To = { x, V(0.6, 1.5, -5), true }, Look = { x, V(0, 1.4, 0) }, Fov = 50 }
	elseif kind == "Pan" then
		if y then
			local mid = "Mid:" .. x .. "|" .. y
			shot = { From = { mid, V(0, 1.8, -11), true }, Look = { x, V(0, 1.4, 0) }, LookTo = { y, V(0, 1.4, 0) }, Fov = 55 }
		else
			shot = { From = { x, V(3, 1.8, -10), true }, Look = { x, V(-7, 1.4, 0), true }, LookTo = { x, V(0, 1.4, 0) }, Fov = 55 }
		end
	else -- Tilt
		shot = { From = { x, V(0, 1, -7), true }, Look = { x, V(0, -2.5, 0) }, LookTo = { x, V(0, 1.6, 0) }, Fov = 50 }
	end
	shot.Preset = kind
	if kind ~= "Seguir" then
		shot.Lock = true
	end
	return shot
end

-- Un plano de la escena con Shot = "…" ya traducido (lo demás del suceso manda: At, Duration, Cut, Fov,
-- Easing, Shake, Roll; Reverse = el movimiento al revés). Sin Shot, el mismo plano.
function CameraShots.expand(entry: Shot, refs: any): Shot
	if type(entry) ~= "table" or entry.Shot == nil then
		return entry
	end
	local shot = CameraShots.preset(entry.Shot, refs)
	if not shot then
		return entry -- (Validate avisa; el cliente lo ignora: no hay plano)
	end
	for _, key in { "At", "Duration", "Cut", "Fov", "Easing", "Shake", "Roll", "If", "IfNot", "Lock" } do
		if entry[key] ~= nil then
			shot[key] = entry[key]
		end
	end
	if entry.Reverse then
		shot.From, shot.To = shot.To or shot.From, shot.From
		shot.Look, shot.LookTo = shot.LookTo or shot.Look, shot.Look
	end
	shot.Shot = entry.Shot
	return shot
end

---------------------------------------------------------------------
-- Luz de cine (pista Light): capas para Controllers/DayLight (nombres de shared/DayGrade). Suaves: no
-- cambian la identidad del juego, solo el tono de la escena.
---------------------------------------------------------------------
local rgb = Color3.fromRGB
CameraShots.Lights = {
	-- Interior cálido de casa (lámparas, hogar)
	InteriorCalido = { Tint = rgb(255, 236, 214), Ambient = rgb(118, 96, 78), Saturation = 0.06, Contrast = 0.08, Bloom = 0.9 },
	-- Hora dorada: naranja suave y largo
	Atardecer = {
		Tint = rgb(255, 216, 176),
		Outdoor = rgb(196, 142, 108),
		SunTint = rgb(120, 62, 30),
		AtmColor = rgb(255, 176, 128),
		Saturation = 0.12,
		Contrast = 0.12,
		Haze = 1.8,
	},
	-- Noche (solo en tu pantalla: «esa noche…» aunque en el servidor sea de día)
	Noche = {
		Exposure = -0.2,
		Ambient = rgb(44, 50, 74),
		Outdoor = rgb(64, 74, 112),
		SunTint = rgb(0, 6, 18),
		Tint = rgb(196, 208, 255),
		AtmColor = rgb(40, 50, 84),
		Decay = rgb(16, 20, 38),
		Saturation = -0.05,
		Contrast = 0.16,
	},
	-- Momento íntimo: cálido, poco contraste
	Intima = { Tint = rgb(255, 230, 220), Saturation = -0.04, Contrast = 0.03, Bloom = 1 },
	-- Tensión: frío, sin color, duro
	Tension = { Tint = rgb(214, 226, 255), Saturation = -0.22, Contrast = 0.26 },
	-- Recuerdo: lavado y cálido (los montajes)
	Recuerdo = { Tint = rgb(255, 238, 212), Saturation = -0.3, Contrast = -0.04, Bloom = 1.3 },
}

function CameraShots.light(name: any): { [string]: any }?
	return if type(name) == "string" then CameraShots.Lights[name] else nil
end

return CameraShots
