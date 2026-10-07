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
--                      (Hombro:X>Y y Hombro:Y>X quedan del mismo lado de la línea X-Y: regla de los 180°)
--   Lateral:X          de perfil                          Reaccion:X      la cara de quien escucha
--   Seguir:X           detrás de X mientras anda          Inserto:Objeto  plano de un objeto (un ancla)
--   Dolly:X            la cámara se acerca (Reverse = se aleja)
--   Pan:X>Y            la cámara gira de X a Y sin moverse (Pan:X: barrido hasta X)
--   Tilt:X             la cámara sube de los pies a la cara (Reverse = baja)
-- X e Y son actores de la escena (su clave), "Yo" (el jugador) o un ancla. Los planos de cámara fija se
-- quedan «clavados» (Lock) donde estaba el actor al empezar el plano: si gira la cabeza, la cámara no
-- da bandazos. Para dos personas, las anclas compuestas (CameraShots.composite):
--   "Mid:A|B"     entre A y B, mirando hacia donde miran los dos (o hacia el jugador si se miran)
--   "Wide:A|B"    como Mid, pero adelantado si están lejos el uno del otro: un plano a WIDE_BASE studs
--                 por delante de Wide se aleja lo justo para que quepan los dos (DosPlanos, Pan)
--   "Toward:A>B"  en A, mirando hacia B (para ponerse detrás de su hombro)
--   "Over:A>B"    como Toward, pero desplazado hacia el hombro de A del lado de la pareja (regla de los
--                 180°: el lado desde donde mira el jugador o, si es uno de los dos, uno fijo por nombre)
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

-- Envuelve un resolver para que entienda "Mid:A|B", "Wide:A|B", "Toward:A>B" y "Over:A>B" (A y B:
-- nombres de ancla)
CameraShots.WIDE_BASE = 10.5 -- (Wide) a esta distancia caben dos personas separadas hasta ~13 studs
CameraShots.SHOULDER = 1.5 -- (Over) cuánto se aparta la cámara hacia el lado del hombro
function CameraShots.composite(resolve: Resolver): Resolver
	local wrapped: (string) -> CFrame?
	-- De qué lado de la línea A-B va la cámara (regla de los 180°: igual en todos los planos de esa
	-- pareja, Hombro, contraplano y DosPlanos): del lado desde donde mira el jugador si está fuera de la
	-- línea; si no (o si es uno de los dos), a la derecha yendo del nombre menor al mayor.
	local function pairSide(a: string, b: string, ca: CFrame, cb: CFrame): Vector3?
		local across = flat(cb.Position - ca.Position)
		if across.Magnitude < 1e-3 then
			return nil
		end
		local lowToHigh = if a < b then across.Unit else -across.Unit
		local canonical = lowToHigh:Cross(Vector3.yAxis)
		if a ~= "Player" and b ~= "Player" then
			local me = resolve("Player")
			if me then
				local off = flat(me.Position - ca.Position):Dot(canonical)
				if math.abs(off) > 1 then
					return if off > 0 then canonical else -canonical
				end
			end
		end
		return canonical
	end
	function wrapped(name: string): CFrame?
		if type(name) ~= "string" then
			return nil
		end
		local wide = false
		local a, b = name:match("^Mid:(.+)|(.+)$")
		if not a then
			a, b = name:match("^Wide:(.+)|(.+)$")
			wide = a ~= nil
		end
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
			-- Hacia donde miran los dos; si se miran el uno al otro, del lado de la pareja (pairSide: desde
			-- donde lo ve el jugador, o el mismo lado que sus planos de hombro)
			local facing = flat(ca.LookVector + cb.LookVector)
			if facing.Magnitude < 0.2 then
				facing = pairSide(a, b, ca, cb) or Vector3.zero
			end
			if facing:Dot(front) < 0 then
				front = -front
			end
			if wide then
				-- (adelantado lo que haga falta para que, a WIDE_BASE studs por delante, quepan los dos)
				local extra = math.max(0, across.Magnitude * 0.62 + 2 - CameraShots.WIDE_BASE)
				return CameraShots.lookAt(mid + front * extra, mid + front * (extra + 1))
			end
			return CameraShots.lookAt(mid, mid + front)
		end
		local overA, overB = name:match("^Over:(.+)>(.+)$")
		if overA and overB then
			-- Como Toward, pero 1,5 studs hacia el lado de la pareja (pairSide): por encima del hombro
			-- de A que queda de ese lado (plano y contraplano nunca cruzan la línea)
			local cf, target = wrapped(overA), wrapped(overB)
			if not cf or not target then
				return cf
			end
			local dir = flat(target.Position - cf.Position)
			if dir.Magnitude < 1e-3 then
				return cf
			end
			local side = pairSide(overA, overB, cf, target) or Vector3.zero
			local at = cf.Position + side * CameraShots.SHOULDER
			return CameraShots.lookAt(at, at + dir)
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
	elseif type(refs) == "table" and type(refs[name]) == "string" then
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
		if type(refs) == "table" and type(refs["*"]) == "string" then
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
		-- Regla de los 180°: el plano y el contraplano de la misma pareja, siempre del mismo lado de la
		-- línea que les une (ancla Over: Hombro:A>B por un hombro de A y Hombro:B>A por el de B que
		-- queda del mismo lado; el mismo lado que DosPlanos:A,B)
		local over = "Over:" .. x .. ">" .. (y :: string)
		shot = { From = { over, V(0, 2, 3.6), true }, To = { over, V(0, 2, 3.3), true }, Look = { y, V(0, 1.4, 0) }, Fov = 50 }
	elseif kind == "DosPlanos" then
		local mid = "Mid:" .. x .. "|" .. (y :: string)
		local wide = "Wide:" .. x .. "|" .. (y :: string)
		shot = { From = { wide, V(0, 1.6, -10.5), true }, To = { wide, V(0, 1.6, -9.5), true }, Look = { mid, V(0, 1.2, 0) }, Fov = 55 }
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
			local wide = "Wide:" .. x .. "|" .. y
			shot = { From = { wide, V(0, 1.8, -11), true }, Look = { x, V(0, 1.4, 0) }, LookTo = { y, V(0, 1.4, 0) }, Fov = 55 }
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
	-- Con las posiciones a mano ({ [id] = CFrame en la cabeza }, como las pasa StageDirector en las
	-- conversaciones): el plano ya calculado, con puntos relativos a "Player" que entiende cualquier
	-- resolver sencillo (sin Mid/Toward) y un Duration para que se vea como un dolly.
	if type(refs) == "table" then
		local heads: { [string]: CFrame } = {}
		local origin: string? = nil
		for id, cf in refs do
			if type(id) == "string" and typeof(cf) == "CFrame" then
				heads[id] = cf
				origin = origin or id
			end
		end
		if heads.Player or heads.Yo then
			origin = "Player"
		end
		if origin then
			return CameraShots.bake(shot, heads, origin :: string)
		end
	end
	return shot
end

-- Un plano con nombre calculado con las cabezas de cada uno (ver preset). origin = el ancla a la que van
-- referidos los puntos ("Player" o una clave).
CameraShots.BAKED_SECONDS = 3.5
function CameraShots.bake(shot: Shot, heads: { [string]: CFrame }, origin: string): (Shot?, string?)
	local function head(name: string): CFrame?
		local id = name:match("^Actor:(.+)$") or name
		if id == "Player" or id == "Yo" then
			return heads.Player or heads.Yo
		end
		return heads[id]
	end
	-- Los planos están pensados desde el centro del cuerpo (1,5 por debajo de la cabeza)
	local body = CameraShots.composite(function(name: string): CFrame?
		local cf = head(name)
		return if cf then CFrame.new(cf.Position - Vector3.new(0, 1.5, 0)) * cf.Rotation else nil
	end)
	local a, b = CameraShots.base(shot, 0, body), CameraShots.base(shot, 1, body)
	local base = head(origin)
	if not a or not b or not base then
		return nil, "faltan personajes para el plano"
	end
	local o = base.Position
	return {
		From = { origin, a.Position - o },
		To = { origin, b.Position - o },
		Look = { origin, a.Position + a.LookVector * 10 - o },
		LookTo = { origin, b.Position + b.LookVector * 10 - o },
		Fov = if type(shot.Fov) == "number" then shot.Fov else nil,
		Cut = shot.Cut,
		Duration = CameraShots.BAKED_SECONDS,
		Preset = shot.Preset,
	}
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
-- Ajuste del plano al sitio (CameraShots.fit): la cámara nunca dentro de una pared, de un mueble ni de
-- la cabeza de alguien, y la cara de quien tiene que salir nunca tapada.
--
-- La usan DialogueUI (conversaciones) y HappeningClient (escenas del motor) en cada plano, y la
-- auditoría (scripts/audit/cine-planos.luau) con rayos contra el mapa construido. `probe`:
--   cast(origin, direction) -> número?   distancia a lo primero que TAPA (lo que se ve) en ese rayo
--   bodies = { { Head = V3, Feet = V3 } }  los personajes de la escena (también tú): ni la cámara
--                                          dentro de ellos ni su cuerpo entre la cámara y el foco
-- Cómo se arregla un plano malo, por orden (siempre se mira al mismo foco, en el mismo sitio de la
-- pantalla): 1) acercar la cámara por la misma línea si queda a FIT_MIN o más de la cara (como hacía
-- CineCamera.clamp); 2) girar el plano alrededor del foco (±20°, un poco más alto, ±40°, …) y acercarlo si
-- hace falta; 3) si nada vale, el giro que deja la cámara más lejos de la cara, sin meterse en nada.
-- Devuelve (CFrame, elección): la elección (giro) se pasa en opts.Choice a los fotogramas siguientes del
-- mismo plano para que la cámara no salte de un giro a otro a mitad de movimiento.
---------------------------------------------------------------------
CameraShots.FIT_MIN = 1.8 -- más cerca que esto de la cara, no vale (se mira por dentro de la nariz)
CameraShots.FIT_MARGIN = 0.6 -- a cuánto se queda de lo que tapa
CameraShots.FIT_FAR = 150 -- un foco más lejos que esto (el cielo, la Grieta): el plano se deja como está
-- Giros que se prueban: { grados alrededor del foco (eje vertical), grados hacia arriba }
CameraShots.FitOrbits = {
	{ 0, 0 },
	{ 20, 0 },
	{ -20, 0 },
	{ 0, 15 },
	{ 40, 0 },
	{ -40, 0 },
	{ 20, 20 },
	{ -20, 20 },
	{ 0, 32 },
	{ 65, 0 },
	{ -65, 0 },
	{ 90, 10 },
	{ -90, 10 },
	{ 180, 10 },
	-- (por encima de las cabezas: si alguien se pone delante de la cara desde todos los lados)
	{ 0, 48 },
	{ 35, 45 },
	{ -35, 45 },
	{ 0, 62 },
}

export type Probe = {
	cast: (origin: Vector3, direction: Vector3) -> number?,
	bodies: { { Head: Vector3, Feet: Vector3 } }?,
}

-- Distancia de un punto a un segmento a-b y en qué parte del segmento (0..1)
local function segmentDistance(a: Vector3, b: Vector3, p: Vector3): (number, number)
	local ab = b - a
	local len2 = ab:Dot(ab)
	local t = if len2 > 1e-9 then math.clamp((p - a):Dot(ab) / len2, 0, 1) else 0
	return (a + ab * t - p).Magnitude, t
end

-- El cuerpo de alguien como esferas (piernas, tronco, cabeza), escaladas por su altura
local function spheresOf(body: { Head: Vector3, Feet: Vector3 }): { { any } }
	local s = math.clamp((body.Head.Y - body.Feet.Y) / 4.5, 0.3, 2)
	local feet = body.Feet
	return {
		{ feet + Vector3.new(0, 1.0 * s, 0), 0.85 * s },
		{ feet + Vector3.new(0, 2.3 * s, 0), 0.95 * s },
		{ feet + Vector3.new(0, 3.3 * s, 0), 0.95 * s },
		{ body.Head, 0.7 * s },
	}
end
CameraShots.bodySpheres = spheresOf

-- Lo primero que tapa en el segmento foco → cámara (distancia desde el foco) o nil si está libre
local function firstBlock(focus: Vector3, at: Vector3, probe: Probe): number?
	local offset = at - focus
	local distance = offset.Magnitude
	if distance < 1e-3 then
		return nil
	end
	local best = probe.cast(focus, offset)
	-- (y al revés, de la cámara al foco: así se ve lo que tiene el foco dentro, una columna o una farola
	-- en medio del grupo, que el rayo desde dentro no ve; lo que está a menos de 0,8 del foco no cuenta)
	local back = probe.cast(at, -offset)
	if back and distance - back > 0.8 and (best == nil or distance - back < best) then
		best = distance - back
	end
	for _, body in probe.bodies or {} do
		-- (quien está en el foco es el sujeto: su cara no se tapa a sí misma)
		if (body.Head - focus).Magnitude < 1.2 then
			continue
		end
		for _, sphere in spheresOf(body) do
			local d, t = segmentDistance(focus, at, sphere[1])
			-- (alguien pegado al sujeto, a menos de 1 stud del foco en esa línea, sale con él en el plano:
			-- no cuenta como que lo tapa; la cámara metida en él sí)
			if d < sphere[2] and (t * distance > 1 or (at - sphere[1]).Magnitude < sphere[2]) then
				-- (desde dónde entra en la esfera, más o menos)
				local along = math.max(0, t * distance - math.sqrt(math.max(0, sphere[2] ^ 2 - d ^ 2)))
				if best == nil or along < best then
					best = along
				end
			end
		end
	end
	return best
end

-- El plano girado alrededor del foco (yaw: eje vertical; pitch: hacia arriba, por su eje derecho)
local function orbit(cf: CFrame, focus: Vector3, yaw: number, pitch: number): CFrame
	local out = cf
	if pitch ~= 0 then
		local right = cf.RightVector
		local flatRight = Vector3.new(right.X, 0, right.Z)
		if flatRight.Magnitude > 1e-3 then
			-- (girar hacia arriba = la cámara sube y mira más hacia abajo)
			local axis = flatRight.Unit
			out = CFrame.new(focus) * CFrame.fromAxisAngle(axis, -math.rad(pitch)) * CFrame.new(-focus) * out
		end
	end
	if yaw ~= 0 then
		out = CFrame.new(focus) * CFrame.Angles(0, math.rad(yaw), 0) * CFrame.new(-focus) * out
	end
	return out
end

-- ¿Puede la cámara ir de `a` a `b` sin atravesar nada ni a nadie? (un travelling o un dolly: si no,
-- mejor un plano quieto)
function CameraShots.clearPath(a: Vector3, b: Vector3, probe: Probe): boolean
	local offset = b - a
	if offset.Magnitude < 0.05 or type(probe) ~= "table" or type(probe.cast) ~= "function" then
		return true
	end
	if probe.cast(a, offset) ~= nil or probe.cast(b, -offset) ~= nil then
		return false
	end
	-- (ni por dentro de nadie: un dolly que pasa por la cabeza del que está delante)
	for _, body in probe.bodies or {} do
		for _, sphere in spheresOf(body) do
			if segmentDistance(a, b, sphere[1]) < sphere[2] then
				return false
			end
		end
	end
	return true
end

-- ¿Un movimiento de cámara (puntos por los que pasa, en orden) atraviesa algo o a alguien? Si sí, el
-- plano se queda quieto en su final (HappeningClient y DialogueUI; la auditoría hace lo mismo)
function CameraShots.travelBlocked(points: { Vector3 }, probe: Probe): boolean
	for i = 2, #points do
		if not CameraShots.clearPath(points[i - 1], points[i], probe) then
			return true
		end
	end
	return false
end

-- Quién tiene que verse en un plano con nombre ("Hombro:Yo>Nico" → { "Nico" }; "DosPlanos:A,B" → los
-- dos; General/Inserto/Seguir… → nadie en concreto). Lo usan DialogueUI y HappeningClient (opts.Keep de
-- fit) y la auditoría (quién tiene que salir en cuadro).
function CameraShots.subjects(spec: any): { string }
	local kind, args = CameraShots.parsePreset(spec)
	if kind == "Hombro" then
		return { args[2] }
	elseif kind == "DosPlanos" or kind == "Pan" then
		return { args[1], args[2] }
	elseif kind == "General" or kind == "Inserto" or kind == nil or #args == 0 then
		return {}
	end
	return { args[1] }
end

-- La pareja de un plano de hombro o de dos ("Hombro:Yo>Nico" → { "Yo", "Nico" }), o nil
function CameraShots.pair(spec: any): { string }?
	local kind, args = CameraShots.parsePreset(spec)
	if (kind == "Hombro" or kind == "DosPlanos" or kind == "Pan") and #args == 2 then
		return { args[1], args[2] }
	end
	return nil
end

-- Ajusta un plano (cf) que mira a `focus`. opts: Interior (dentro de una sala: planos un 30 % más
-- cortos), Min (FIT_MIN), Choice (la elección de un fotograma anterior del mismo plano), Keep = { V3 }
-- (otras caras que tienen que verse: en un plano de dos, la del otro), Line = { A, B } (la pareja de un
-- plano de hombro o de dos: los giros no cruzan su línea, regla de los 180°).
function CameraShots.fit(cf: CFrame, focus: Vector3, probe: Probe, opts: { [string]: any }?): (CFrame, number?)
	local o = opts or {}
	if o.Interior then
		cf = CFrame.new(focus + (cf.Position - focus) * 0.7) * cf.Rotation
	end
	local distance = (cf.Position - focus).Magnitude
	if distance < 0.05 or distance > CameraShots.FIT_FAR or type(probe) ~= "table" or type(probe.cast) ~= "function" then
		return cf, nil
	end
	local minimum = math.min(o.Min or CameraShots.FIT_MIN, distance)
	local margin = CameraShots.FIT_MARGIN
	-- Acerca la cámara por la línea del foco hasta antes de lo que tapa (nil si no hay que hacerlo)
	-- Las otras caras que tienen que verse desde ahí (sin pared ni nadie en medio)
	local keepList = o.Keep or {}
	local function seesKeep(at: Vector3): boolean
		for _, point in keepList do
			if typeof(point) == "Vector3" and (point - focus).Magnitude > 0.3 and firstBlock(point, at, probe) then
				return false
			end
		end
		return true
	end
	local function pulled(candidate: CFrame, floor: number): CFrame?
		local block = firstBlock(focus, candidate.Position, probe)
		if not block then
			return if seesKeep(candidate.Position) then candidate else nil
		end
		local keep = block - margin
		if keep < floor then
			return nil
		end
		local dir = (candidate.Position - focus).Unit
		local at = focus + dir * keep
		-- (el sitio acercado tiene que estar libre también: un pilar fino delante de una pared)
		if firstBlock(focus, at, probe) or not seesKeep(at) then
			return nil
		end
		return CFrame.new(at) * candidate.Rotation
	end
	-- Regla de los 180° (opts.Line = { A, B }: la pareja del plano): ningún giro cruza su línea
	local line = o.Line
	local function sideOf(at: Vector3): number
		if type(line) ~= "table" or typeof(line[1]) ~= "Vector3" or typeof(line[2]) ~= "Vector3" then
			return 0
		end
		local ab, ac = flat(line[2] - line[1]), flat(at - line[1])
		local cross = ab.X * ac.Z - ab.Z * ac.X
		return if math.abs(cross) < 0.3 * ab.Magnitude then 0 elseif cross > 0 then 1 else -1
	end
	local side = sideOf(cf.Position)
	local orbits = CameraShots.FitOrbits
	if type(o.Choice) == "number" and orbits[o.Choice] then
		-- (mismo giro que al empezar el plano; solo se acerca si algo se cruza ahora)
		local r = orbits[o.Choice]
		local candidate = orbit(cf, focus, r[1], r[2])
		local kept = pulled(candidate, minimum) or pulled(candidate, 0.5)
		if kept then
			return kept, o.Choice
		end
		-- Ahora algo tapa la cara y acercarse no basta (alguien que llega andando y se pone delante): se
		-- busca otro giro. Mejor un cambio de plano que la espalda de alguien llenando la pantalla.
	end
	local best, bestKeep, bestIndex = cf, -math.huge, 1
	-- (primero los giros que no cruzan la línea de la pareja; si ninguno vale, los que sí: mejor un
	-- salto de eje que una cara tapada). Si con todas las caras de Keep no hay ninguno, con la primera
	-- (quien habla, en un plano de dos) y luego solo el foco: mejor ver a quien habla que a nadie.
	local tries = { keepList }
	if #keepList > 1 then
		table.insert(tries, { keepList[1] })
	end
	if #keepList > 0 then
		table.insert(tries, {})
	end
	for _, list in tries do
		keepList = list
		for pass = 1, if side ~= 0 then 2 else 1 do
			for index, r in orbits do
				local candidate = orbit(cf, focus, r[1], r[2])
				local crosses = side ~= 0 and sideOf(candidate.Position) == -side
				if crosses ~= (pass == 2) then
					continue
				end
				local ok = pulled(candidate, minimum)
				if ok then
					return ok, index
				end
				local block = firstBlock(focus, candidate.Position, probe)
				local keep = if block then block - margin else (candidate.Position - focus).Magnitude
				if keep > bestKeep + 0.25 then
					best, bestKeep, bestIndex = candidate, keep, index
				end
			end
		end
	end
	-- Nada vale: el giro que deja la cámara más lejos de la cara, acercada hasta antes de lo que tapa
	local dir = (best.Position - focus).Unit
	return CFrame.new(focus + dir * math.max(0.5, math.min(bestKeep, (best.Position - focus).Magnitude))) * best.Rotation, bestIndex
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
