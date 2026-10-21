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
-- (v125.6) Un plano fijo largo sin campo de visión propio se acerca un poco mientras dura (DRIFT_FOV
-- grados): la cámara respira en vez de estar muerta. Drift = false en el plano lo quita.
CameraShots.DRIFT_FOV = 5
CameraShots.DRIFT_MIN = 2.5 -- (segundos: un plano más corto no se nota)
function CameraShots.fov(shot: Shot, u: number): number?
	local fov = shot.Fov
	if type(fov) == "number" then
		return fov
	elseif type(fov) == "table" then
		return fov[1] + (fov[2] - fov[1]) * CameraShots.ease(shot.Easing, u)
	end
	if shot.Drift ~= false and type(shot.Duration) == "number" and shot.Duration >= CameraShots.DRIFT_MIN and CameraShots.kind(shot) == "Fixed" then
		return CameraShots.DEFAULT_FOV - CameraShots.DRIFT_FOV * CameraShots.ease(nil, math.clamp(u, 0, 1))
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
CameraShots.SHOULDER = 3.2 -- (Over) cuánto se aparta la cámara hacia el lado del hombro
CameraShots.SHOULDER_AIM = 1.2 -- (Aim) cuánto se corre hacia ese lado el punto al que mira un plano de hombro
CameraShots.SHOULDER_FAR_MIN = 3.5 -- (Hombro) más cerca que esto de quien habla: el ajuste lo ha girado y
-- su cara llena la pantalla sin tu hombro; mejor su plano medio (DialogueUI, la auditoría)
CameraShots.SHOULDER_MIN = 3.2 -- (Hombro) más cerca que esto de la cabeza de quien queda de espaldas: su
-- nuca llena la pantalla; mejor el plano medio de quien está enfrente (DialogueUI, la auditoría)
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
		local aimA, aimB = name:match("^Aim:(.+)>(.+)$")
		if aimA and aimB then
			-- Adonde mira un plano de hombro: B corrido hacia el lado contrario al de la cámara (SHOULDER_AIM). Así quien
			-- habla queda en un tercio de la pantalla y el hombro de A, en el borde contrario (antes se
			-- miraba a B de lleno y la cabeza de A quedaba en medio, pegada a su cara)
			local cf, target = wrapped(aimA), wrapped(aimB)
			if not cf or not target then
				return target
			end
			local side = pairSide(aimA, aimB, cf, target) or Vector3.zero
			return CFrame.new(target.Position - side * CameraShots.SHOULDER_AIM) * target.Rotation
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
function CameraShots.preset(spec: any, refs: any, scales: { [string]: number }?): (Shot?, string?)
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
		local aim = "Aim:" .. x .. ">" .. (y :: string)
		shot = { From = { over, V(0, 2, 2.6), true }, To = { over, V(0, 2, 2.3), true }, Look = { aim, V(0, 1.4, 0) }, Fov = 55 }
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
	elseif kind == "Inserto" and (x == "Player" or x:match("^Actor:")) then
		-- (un inserto de una persona: de cerca, de frente y a la altura de sus manos; antes era el de un
		-- objeto, desde arriba y sin girar con ella, y salía su coronilla tapando la pantalla)
		shot = { From = { x, V(1.4, 0.6, -5), true }, To = { x, V(1.1, 0.6, -4.4), true }, Look = { x, V(0, 0.5, 0) }, Fov = 45 }
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
	-- (scales: la altura de cada uno respecto a un adulto, por id —"Yo" el jugador—: el plano de una
	-- persona a su medida, como en las escenas del motor. Un niño o un bebé en una conversación salía
	-- mirado desde arriba con la cámara de un adulto —«SinAire» en la auditoría—)
	if type(scales) == "table" then
		local subjectId = CameraShots.subjects(spec)[1]
		if type(subjectId) == "string" then
			local size = scales[if subjectId == "Player" then "Yo" else subjectId]
			if type(size) == "number" then
				shot = CameraShots.scaleShot(shot, refOf(subjectId, refs), size, true)
			end
		end
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
			return CameraShots.bake(shot, heads, origin :: string, scales)
		end
	end
	return shot
end

-- Un plano con nombre calculado con las cabezas de cada uno (ver preset). origin = el ancla a la que van
-- referidos los puntos ("Player" o una clave).
CameraShots.BAKED_SECONDS = 3.5
function CameraShots.bake(shot: Shot, heads: { [string]: CFrame }, origin: string, scales: { [string]: number }?): (Shot?, string?)
	local function idOf(name: string): string
		local id = name:match("^Actor:(.+)$") or name
		return if id == "Player" then "Yo" else id
	end
	local function head(name: string): CFrame?
		local id = idOf(name)
		if id == "Yo" then
			return heads.Player or heads.Yo
		end
		return heads[id]
	end
	-- Los planos están pensados desde el centro del cuerpo (1,5 por debajo de la cabeza; a su medida)
	local body = CameraShots.composite(function(name: string): CFrame?
		local cf = head(name)
		local size = if type(scales) == "table" and type(scales[idOf(name)]) == "number" then scales[idOf(name)] else 1
		return if cf then CFrame.new(cf.Position - Vector3.new(0, 1.5 * size, 0)) * cf.Rotation else nil
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
CameraShots.BODY_CLEAR = 1.2 -- nadie a menos de esto (más su cuerpo) delante de la cámara
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

-- Cuánto del cuadro tapa lo que está PEGADO a la cámara (0..1): rayos cortos por una rejilla de 5 × 3
-- puntos de la pantalla, hasta CLUTTER_NEAR (o el 45 % de la distancia al foco, si es menos). Una
-- pared de lado, el canto de un granero o la copa de un árbol a medio metro de la cámara ocupaban media
-- pantalla sin tapar la cara (la auditoría de cinemáticas lo llama «ParedDelante»).
CameraShots.CLUTTER_NEAR = 3
CameraShots.CLUTTER_MAX = 0.34
local CLUTTER_GRID = { -0.8, -0.4, 0, 0.4, 0.8 }
local CLUTTER_ROWS = { -0.6, 0, 0.6 }
function CameraShots.clutter(cf: CFrame, focus: Vector3, probe: any, tanHalf: number): number
	if type(probe) ~= "table" or type(probe.cast) ~= "function" then
		return 0
	end
	local near = math.min(CameraShots.CLUTTER_NEAR, (focus - cf.Position).Magnitude * 0.45)
	if near < 0.3 then
		return 0
	end
	local look, right, up = cf.LookVector, cf.RightVector, cf.UpVector
	local tx = tanHalf * CameraShots.ASPECT
	local hits, total = 0, 0
	for _, y in CLUTTER_ROWS do
		for _, x in CLUTTER_GRID do
			local dir = (look + right * (x * tx) + up * (y * tanHalf)).Unit
			local ok, hit = pcall(probe.cast, cf.Position, dir * near)
			total += 1
			if ok and hit ~= nil then
				hits += 1
			end
		end
	end
	return hits / total
end

-- ¿Tapa a la cámara una pieza SIN CanQuery? (Controllers/CineOccluders, World/SafeSpot.decorAt y la
-- auditoría, CineGeo: la misma regla). Las piezas de decoración (Builder.decor: copas, tejas, hastiales,
-- molduras, toldos, balcones, ventanas; los muebles de Furniture) no tienen CanQuery para que el motor
-- vaya más ligero, así que los rayos de la cámara (workspace:Raycast) las atravesaban y CameraShots.fit
-- dejaba la cámara DENTRO de un toldo, una copa o un armario («aparecen paredes»). Cuentan las que se
-- ven (Transparency < 0,6), no son cajas de choque (atributo Collider) y no son un hilo ni una mota.
function CameraShots.occluderSize(size: Vector3, longest: number?): boolean
	local a, b, c = size.X, size.Y, size.Z
	-- (el lado más largo de 1 stud o más y el mediano de 0,25 o más: una moldura o la pata de una mesa
	-- sí; un cable o una varilla fina, no)
	if a < b then
		a, b = b, a
	end
	if b < c then
		b, c = c, b
	end
	if a < b then
		a, b = b, a
	end
	return a >= (longest or 1) and b >= 0.25
end
-- longest: el lado más largo mínimo (1 para la cámara; World/SafeSpot.decorAt usa ACTOR_DECOR, más
-- pequeño: una flor de un parterre no tapa la cámara, pero un actor no se pone encima de ellas)
CameraShots.ACTOR_DECOR = 0.5
function CameraShots.occluder(transparency: number, size: Vector3, canQuery: boolean, collider: boolean?, longest: number?): boolean
	if canQuery or collider or transparency >= 0.6 then
		return false
	end
	return CameraShots.occluderSize(size, longest)
end

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

-- (cuánto puede ocupar del alto de la pantalla el cuerpo de otro delante de la cámara; con el campo de
-- visión del plano que se ajusta: fitCore lo pone en nearTan)
CameraShots.NEAR_BODY = 0.6
local nearTan: number? = nil

-- Cuánto tapa de la pantalla alguien que NO es de este plano y queda cortado en un borde (0..1 del área),
-- con el campo de visión del plano. allowed(body) -> número máximo permitido para ese cuerpo, o nil = no
-- cuenta (el sujeto, los que tienen que salir). Antes salía media Abu cortada en el borde de un primer plano.
CameraShots.EDGE_MAX = 0.08
CameraShots.EDGE_OTS = 0.3
CameraShots.ASPECT = 16 / 9
function CameraShots.edgeCut(cf: CFrame, bodies: { { Head: Vector3, Feet: Vector3 } }, tanHalf: number, allowed: (any) -> number?): (number, number)
	local worst, worstOver = 0, -math.huge
	for _, body in bodies do
		local limit = allowed(body)
		if limit then
			local loX, loY, hiX, hiY = math.huge, math.huge, -math.huge, -math.huge
			local ahead = false
			for _, sphere in spheresOf(body) do
				local rel = cf:PointToObjectSpace(sphere[1])
				local depth = -rel.Z
				if depth > 0.05 then
					ahead = true
					local x, y = rel.X / (depth * tanHalf * CameraShots.ASPECT), rel.Y / (depth * tanHalf)
					local rx, ry = sphere[2] / (depth * tanHalf * CameraShots.ASPECT), sphere[2] / (depth * tanHalf)
					loX, loY = math.min(loX, x - rx), math.min(loY, y - ry)
					hiX, hiY = math.max(hiX, x + rx), math.max(hiY, y + ry)
				end
			end
			-- (cortado: su silueta sale por un borde de la pantalla; lo que se ve dentro, en área)
			if ahead and (loX < -1 or hiX > 1 or loY < -1 or hiY > 1) then
				local w = math.max(0, math.min(hiX, 1) - math.max(loX, -1))
				local h = math.max(0, math.min(hiY, 1) - math.max(loY, -1))
				local area = w * h / 4 * 0.75 -- (la silueta llena ~3/4 de su caja)
				if area - limit > worstOver then
					worst, worstOver = area, area - limit
				end
			end
		end
	end
	return worst, worstOver
end

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
			elseif (at - sphere[1]).Magnitude < math.max(sphere[2] + CameraShots.BODY_CLEAR, if nearTan then sphere[2] / (CameraShots.NEAR_BODY * nearTan) else 0) and (focus - at):Dot(sphere[1] - at) > 0 then
				-- (alguien pegado a la cámara, delante de ella aunque no en la línea del foco: su cuerpo
				-- llenaba media pantalla. Cuenta como que tapa justo delante de la cámara)
				local along = math.max(0, distance - sphere[2] - CameraShots.BODY_CLEAR)
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

-- Mirar algo lejísimos (el cielo, la Grieta) desde dentro: si delante de la cámara hay una pared o el
-- techo (antes se veía el techo encima de la cuna), la cámara se mueve un poco, sin salir de la sala,
-- hasta donde se vea (la ventana). Si no hay sitio, como estaba.
function CameraShots.window(cf: CFrame, focus: Vector3, probe: Probe): CFrame
	-- (por una ventana sí se ve: probe.castGlass deja pasar los cristales, si la sonda lo tiene)
	local sky = (probe :: any).castGlass or probe.cast
	local dir = (focus - cf.Position).Unit
	local ok, hit = pcall(sky, cf.Position, dir * 40)
	if not ok or hit == nil then
		return cf
	end
	for _, r in { 1.5, 3, 4.5, 6, 8, 11, 14 } do
		for k = 0, 11 do
			local a = k * math.pi / 6
			local at = cf.Position + Vector3.new(math.cos(a), 0, math.sin(a)) * r
			local okMove, wall = pcall(probe.cast, cf.Position, at - cf.Position)
			if okMove and wall == nil then
				local d = (focus - at).Unit
				local okSee, block = pcall(sky, at, d * 40)
				if okSee and block == nil then
					return CameraShots.lookAt(at, focus)
				end
			end
		end
	end
	return cf
end

-- Plano de esquina dentro de una sala: de 16 direcciones, la que tiene la pared más lejos del foco;
-- la cámara a 0,8 de esa pared y algo más alta que las cabezas (sin tocar el techo), mirando al foco.
-- Solo si desde ahí se ve el foco (y, si se puede, las caras de keep). nil si no hay sitio.
CameraShots.ROOF_UP = 14 -- (un techo a menos de esto encima del foco: estás dentro)
CameraShots.INTERIOR_MIN = 4 -- (bajo techo) los planos se acortan un 30 %, pero nunca a menos de esto
function CameraShots.corner(focus: Vector3, probe: Probe, keep: { Vector3 }?, prefer: Vector3?): CFrame?
	local okRoof, roof = pcall(probe.cast, focus, Vector3.new(0, CameraShots.ROOF_UP, 0))
	local lift = math.clamp(((if okRoof and roof then roof else 6) - 0.8), 0.5, 3)
	local best, bestScore = nil, -math.huge
	for k = 0, 15 do
		local a = k * math.pi / 8
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local ok, wall = pcall(probe.cast, focus, dir * 30)
		local reach = (if ok and wall then wall else 30) - 0.8
		if reach >= 2.5 then
			local at = focus + dir * math.min(reach, 16) + Vector3.new(0, lift, 0)
			local cf = CameraShots.lookAt(at, focus)
			if not firstBlock(focus, at, probe) then
				local score = math.min(reach, 16)
				-- (del lado desde donde quería mirar el plano: dos planos distintos no acaban en la misma esquina)
				if prefer and prefer.Magnitude > 1e-3 then
					score += 6 * dir:Dot(Vector3.new(prefer.X, 0, prefer.Z).Unit)
				end
				for _, face in keep or {} do
					if typeof(face) == "Vector3" and not firstBlock(face, at, probe) then
						score += 10
					end
				end
				if score > bestScore then
					best, bestScore = cf, score
				end
			end
		end
	end
	return best
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

-- Un plano con nombre pensado para un adulto, a la medida de quien sale (scale: su altura / la de un
-- adulto). Los desplazamientos respecto a su ancla (dónde está la cámara y adónde mira) se multiplican:
-- con un bebé, la cámara baja y se acerca y su cara queda igual de grande y en su sitio (antes miraba
-- por encima de su cabeza y el bebé se salía por abajo).
function CameraShots.scaleShot(shot: { [string]: any }, anchor: string, scale: number, heightOnly: boolean?): { [string]: any }
	if math.abs(scale - 1) < 0.05 then
		return shot
	end
	local out = table.clone(shot)
	-- (seguir a alguien: la distancia a la que va detrás, también a su medida)
	if out.Follow == anchor and typeof(out.Offset) == "Vector3" then
		out.Offset = out.Offset * scale
	end
	-- (en un plano de hombro se mira a «Aim:A>B», que es B corrido a un lado: también a la medida de B.
	-- Antes, con un bebé enfrente, la cámara miraba 1,4 studs por encima de su ancla de adulto y sus
	-- ojos quedaban abajo del todo —auditoría de cinemáticas, «SinAire»—)
	local aimSuffix = ">" .. anchor
	local function isAnchor(name: any, field: string): boolean
		if name == anchor then
			return true
		end
		return (field == "Look" or field == "LookTo") and type(name) == "string" and name:sub(1, 4) == "Aim:" and name:sub(-#aimSuffix) == aimSuffix
	end
	for _, field in { "From", "To", "Fixed", "Look", "LookTo" } do
		local spec = out[field]
		if type(spec) == "table" and isAnchor(spec[1], field) and typeof(spec[2]) == "Vector3" then
			local copy = table.clone(spec)
			-- (heightOnly: solo la altura —las conversaciones: misma distancia, a la altura de sus ojos—)
			copy[2] = if heightOnly then Vector3.new(spec[2].X, spec[2].Y * scale, spec[2].Z) else spec[2] * scale
			out[field] = copy
		end
	end
	return out
end

-- Lo más cerca que puede quedar la cámara de la cara en un plano con nombre: que la cabeza (HEAD_SIZE)
-- no ocupe más de FACE_MAX del alto de la pantalla con su campo de visión. El primerísimo plano (PPP) y
-- los insertos son cerrados a propósito: FIT_MIN.
CameraShots.HEAD_SIZE = 1.2
CameraShots.FACE_PITCH_MAX = 35 -- (fit) en un plano de una cara, ningún giro más alto que esto (PITCH_MAX)
CameraShots.FACE_MAX = 0.4
function CameraShots.minDistance(spec: any, fov: number?): number
	local kind = CameraShots.parsePreset(spec)
	if kind == nil or kind == "PPP" or kind == "Inserto" then
		return CameraShots.FIT_MIN
	end
	local f = math.clamp(fov or CameraShots.DEFAULT_FOV, 10, 120)
	return math.max(CameraShots.FIT_MIN, CameraShots.HEAD_SIZE / (2 * math.tan(math.rad(f) / 2) * CameraShots.FACE_MAX))
end

-- En un plano de una persona (Medio, PrimerPlano, Reaccion, PPP), ¿la cabeza de OTRO queda pegada a
-- la cámara y delante de ella (a menos de SHOULDER_MIN)? Devuelve su id (la más cercana) o nil.
-- heads = { [id] = cabeza } ("Yo" = tú); cam = el plano ya ajustado
function CameraShots.nearIntruder(spec: any, heads: { [string]: Vector3 }, cam: CFrame): string?
	local kind, args = CameraShots.parsePreset(spec)
	if not (kind == "Medio" or kind == "PrimerPlano" or kind == "Reaccion" or kind == "PPP") or #args ~= 1 then
		return nil
	end
	local subject = if args[1] == "Player" then "Yo" else args[1]
	local best, bestDistance = nil, CameraShots.SHOULDER_MIN
	for id, head in heads do
		if id ~= subject and typeof(head) == "Vector3" then
			local offset = head - cam.Position
			local distance = offset.Magnitude
			if distance > 0.3 and distance < bestDistance and cam.LookVector:Dot(offset.Unit) > 0.5 then
				best, bestDistance = id, distance
			end
		end
	end
	return best
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
local fitCore: (CFrame, Vector3, Probe, { [string]: any }?) -> (CFrame, number?)
-- opts.Crowd = { V3 } (las cabezas de todos los de la escena): bajo techo, si desde el plano ajustado no
-- se ve a NADIE (una pared entre la cámara y todos: la sala de al lado), plano de esquina de la sala
-- desde donde se vea a los más posibles (CameraShots.corner)
local function fitCrowd(cf: CFrame, focus: Vector3, probe: Probe, opts: { [string]: any }?): (CFrame, number?)
	local result, choice = fitCore(cf, focus, probe, opts)
	local o = opts or {}
	local crowd = o.Crowd
	if type(crowd) ~= "table" or #crowd == 0 or type(probe) ~= "table" or type(probe.cast) ~= "function" then
		return result, choice
	end
	-- (se ve a alguien: sin nada en medio y dentro del cuadro, más o menos)
	local function sees(at: CFrame, head: any): boolean
		if typeof(head) ~= "Vector3" then
			return false
		end
		local d = head - at.Position
		if d.Magnitude < 0.5 then
			return true
		end
		return at.LookVector:Dot(d.Unit) > 0.8 and probe.cast(at.Position, d.Unit * math.max(0, d.Magnitude - 0.4)) == nil
	end
	local function seen(at: CFrame): number
		local n = 0
		for _, head in crowd do
			if sees(at, head) then
				n += 1
			end
		end
		return n
	end
	local best, bestSeen = result, seen(result)
	if bestSeen > 0 then
		return result, choice
	end
	local ok, up = pcall(probe.cast, focus, Vector3.new(0, CameraShots.ROOF_UP, 0))
	if not (ok and up) then
		return result, choice
	end
	-- (bajo techo, sin ver a nadie de la escena —la cámara en la sala de al lado—: plano de esquina de
	-- SU sala desde donde se vea a más, si lo hay; un primer plano que no ve a los demás está bien)
	local center = Vector3.zero
	local count = 0
	for _, head in crowd do
		if typeof(head) == "Vector3" then
			center += head
			count += 1
		end
	end
	for _, target in { center / math.max(count, 1), crowd[1], focus } do
		if typeof(target) == "Vector3" then
			local corner = CameraShots.corner(target, probe, crowd, cf.Position - target)
			if corner then
				local n = seen(corner)
				if n > bestSeen then
					best, bestSeen = corner, n
				end
			end
		end
	end
	return best, choice
end

-- La cámara nunca pegada a una pared (ni al techo, ni al suelo): si algo queda a menos de CAM_CLEAR por
-- un lado, detrás, arriba o abajo, se aparta lo justo, mirando igual. En el nacimiento la cámara
-- quedaba dentro de la esquina del cuarto y media pantalla era pared.
CameraShots.CAM_CLEAR = 0.7
function CameraShots.clearOff(cf: CFrame, probe: Probe): CFrame
	if type(probe) ~= "table" or type(probe.cast) ~= "function" then
		return cf
	end
	local at = cf.Position
	local dirs = { cf.RightVector, -cf.RightVector, cf.UpVector, -cf.UpVector, -cf.LookVector, cf.LookVector }
	for _ = 1, 2 do
		local push = Vector3.zero
		for _, dir in dirs do
			local ok, hit = pcall(probe.cast, at, dir * CameraShots.CAM_CLEAR)
			if ok and type(hit) == "number" and hit < CameraShots.CAM_CLEAR then
				push -= dir * (CameraShots.CAM_CLEAR - hit)
			end
		end
		if push.Magnitude < 1e-3 then
			break
		end
		at += push
	end
	return CFrame.new(at) * cf.Rotation
end

-- Ajusta el plano (fitCore + el grupo) y lo aparta de las paredes que lo rozan. opts.Fov: el campo de
-- visión del plano (nadie más ocupa más de NEAR_BODY del alto de la pantalla delante de la cámara)
function CameraShots.fit(cf: CFrame, focus: Vector3, probe: Probe, opts: { [string]: any }?): (CFrame, number?)
	local fov = opts and opts.Fov
	nearTan = if type(fov) == "number" then math.tan(math.rad(math.clamp(fov, 10, 120)) / 2) else nil
	local ok, result, choice = pcall(fitCrowd, cf, focus, probe, opts)
	nearTan = nil
	if not ok then
		error(result, 0)
	end
	-- (clearOff aparta la cámara de una pared, del techo o de una mesa sin girarla: a 2-3 studs de una
	-- cara, subirla medio stud dejaba la cara abajo del cuadro —«SinAire» en la auditoría—. Se gira lo
	-- justo para que el foco siga en el mismo sitio de la pantalla)
	-- (v125.6: antes, las reglas de sentido común —sin cenitales, distancia del plano, el foco en cuadro—;
	-- y después, apartarla de lo que roce)
	local saned = CameraShots.sane(result, focus, probe, opts)
	local cleared = CameraShots.clearOff(saned, probe)
	return CameraShots.keepAim(saned, cleared, focus), choice
end

---------------------------------------------------------------------
-- REGLAS DE SENTIDO COMÚN de la cámara (v125.5: en la Cinemateca, «El mar» se veía desde encima de la
-- cabeza de Abu, pegada a ella, con el rótulo encima de la cara). Se aplican al final de CameraShots.fit,
-- así que valen para TODAS las escenas y conversaciones (y la auditoría las mide con el mismo fit):
--   1. Nada de cenitales sobre una cabeza: con una persona de foco y a menos de SANE_NEAR, la cámara no
--      sube (ni baja) más de PITCH_MAX grados respecto a su cara.
--   2. Distancia mínima según el tamaño del plano (opts.Min, CameraShots.minDistance): si quedó más
--      cerca, se aleja por la misma línea (si no hay nada en medio).
--   3. Quien tiene que salir, sale: si el foco quedó fuera del cuadro, la cámara le vuelve a mirar.
---------------------------------------------------------------------
CameraShots.PITCH_MAX = 35
CameraShots.PITCH_HARD = 45 -- (el tope duro: la auditoría falla por encima de esto)
CameraShots.SANE_NEAR = 30
-- ¿Es el foco la cara de alguien? (las caras que tienen que salir o las de la escena)
local function personFocus(focus: Vector3, opts: { [string]: any }?): boolean
	if not opts then
		return false
	end
	for _, list in { opts.Keep or {}, opts.Crowd or {} } do
		for _, head in list do
			if typeof(head) == "Vector3" and (head - focus).Magnitude < 2.5 then
				return true
			end
		end
	end
	return false
end
CameraShots.personFocus = personFocus

-- Cuánto se puede alejar la cámara de `from` por `direction` sin meterse en nada (nil: sin límite)
local function room(from: Vector3, direction: Vector3, probe: Probe): number?
	if type(probe) ~= "table" or type(probe.cast) ~= "function" then
		return nil
	end
	local ok, hit = pcall(probe.cast, from, direction)
	if ok and type(hit) == "number" then
		return math.max(0, hit - CameraShots.FIT_MARGIN)
	end
	return nil
end

-- El ángulo (grados) desde la cara hasta la cámara: + por encima, − por debajo
function CameraShots.pitchOver(cf: CFrame, focus: Vector3): number
	local d = cf.Position - focus
	if d.Magnitude < 1e-3 then
		return 0
	end
	return math.deg(math.asin(math.clamp(d.Y / d.Magnitude, -1, 1)))
end

-- ¿Sale este punto en el cuadro? (con el campo de visión tanHalf = tan(fov/2) y la pantalla 16:9)
function CameraShots.inFrame(cf: CFrame, point: Vector3, tanHalf: number, margin: number?): boolean
	local d = point - cf.Position
	local depth = d:Dot(cf.LookVector)
	if depth <= 0.05 then
		return false
	end
	local x = d:Dot(cf.RightVector) / (depth * tanHalf * CameraShots.ASPECT)
	local y = d:Dot(cf.UpVector) / (depth * tanHalf)
	local m = margin or 1
	return math.abs(x) <= m and math.abs(y) <= m
end

function CameraShots.sane(cf: CFrame, focus: Vector3, probe: Probe, opts: { [string]: any }?): CFrame
	local o = opts or {}
	local offset = cf.Position - focus
	local distance = offset.Magnitude
	if distance < 0.05 or distance > CameraShots.SANE_NEAR or not personFocus(focus, o) then
		return cf
	end
	local tanHalf = math.tan(math.rad(math.clamp(if type(o.Fov) == "number" then o.Fov else CameraShots.DEFAULT_FOV, 10, 120)) / 2)
	-- Lo que estropea un sitio para la cámara (lo que ya cuidó el ajuste): alguien cortado en un borde,
	-- alguien pegado a la cámara o entre ella y la cara, algo del mapa tapando el cuadro. Un cambio de
	-- estas reglas solo se queda si no empeora nada de eso (si no, el ajuste ya eligió lo mejor posible).
	local bodies = if type(probe) == "table" and type(probe.bodies) == "table" then probe.bodies else {}
	local keep = o.Keep or {}
	local function allowed(body: any): number?
		if (body.Head - focus).Magnitude < 1.2 then
			return nil
		end
		for _, point in keep do
			if typeof(point) == "Vector3" and (body.Head - point).Magnitude < 1.2 then
				return nil
			end
		end
		return CameraShots.EDGE_MAX
	end
	local function harm(at: CFrame): number
		local score = 0
		local _, over = CameraShots.edgeCut(at, bodies, tanHalf, allowed)
		score += math.max(0, over)
		for _, body in bodies do
			if typeof(body.Head) == "Vector3" and (body.Head - focus).Magnitude > 1.2 then
				for _, sphere in spheresOf(body) do
					local d = (sphere[1] - at.Position).Magnitude
					local between, t = segmentDistance(at.Position, focus, sphere[1])
					if d < sphere[2] + 0.6 or (t > 0.05 and t < 0.95 and between < sphere[2]) then
						score += 1
						break
					end
				end
			end
		end
		if CameraShots.clutter(at, focus, probe, tanHalf) > CameraShots.CLUTTER_MAX then
			score += 1
		end
		return score
	end
	local base = harm(cf)
	local function better(candidate: CFrame): boolean
		return harm(candidate) <= base + 1e-3
	end
	local out = cf
	-- 1. Sin cenitales
	local pitch = CameraShots.pitchOver(cf, focus)
	if math.abs(pitch) > CameraShots.PITCH_MAX then
		local horizontal = Vector3.new(offset.X, 0, offset.Z)
		if horizontal.Magnitude < 0.05 then
			-- (justo encima: se baja por delante de quien sale, o hacia donde miraba la cámara)
			local front = if typeof(o.Front) == "Vector3" then Vector3.new(o.Front.X, 0, o.Front.Z) else Vector3.new(-cf.LookVector.X, 0, -cf.LookVector.Z)
			horizontal = if front.Magnitude > 0.05 then front else Vector3.new(0, 0, 1)
		end
		-- (PITCH_MAX; si ahí estorba algo que el ajuste esquivaba, lo más bajo que no estorbe, hasta
		-- PITCH_HARD: en un corrillo apretado no queda otra que mirar un poco desde arriba)
		for _, limit in { CameraShots.PITCH_MAX, CameraShots.PITCH_MAX + 5, CameraShots.PITCH_HARD - 1 } do
			if math.abs(pitch) <= limit then
				break
			end
			local a = math.rad(limit * (if pitch > 0 then 1 else -1))
			local direction = horizontal.Unit * math.cos(a) + Vector3.new(0, math.sin(a), 0)
			local free = room(focus, direction * distance, probe)
			local reach = if free then math.min(distance, free) else distance
			if reach >= math.max(CameraShots.FIT_MIN, math.min(o.Min or CameraShots.FIT_MIN, distance)) then
				local candidate = CameraShots.keepAim(cf, CFrame.new(focus + direction * reach) * cf.Rotation, focus)
				if better(candidate) then
					out = candidate
					break
				end
			end
		end
	end
	-- 2. Distancia mínima del plano
	local minimum = if type(o.Min) == "number" then o.Min else CameraShots.FIT_MIN
	local now = (out.Position - focus).Magnitude
	if now < minimum and now > 0.05 then
		local direction = (out.Position - focus).Unit
		local free = room(focus, direction * minimum, probe)
		local reach = if free then math.min(minimum, free) else minimum
		if reach > now then
			local candidate = CFrame.new(focus + direction * reach) * out.Rotation
			if better(candidate) then
				out = candidate
			end
		end
	end
	-- 3. El foco, dentro del cuadro (solo en los planos de alguien —Keep—: un travelling que pasa de tu
	-- cara al cielo deja de mirarte a propósito)
	if #keep > 0 and not CameraShots.inFrame(out, focus, tanHalf, 0.85) then
		local candidate = CameraShots.lookAt(out.Position, focus)
		if better(candidate) then
			out = candidate
		end
	end
	return out
end

-- La cámara movida de `before` a `after` (misma orientación), girada lo mínimo para que `focus` siga en
-- el mismo punto de la pantalla
function CameraShots.keepAim(before: CFrame, after: CFrame, focus: Vector3): CFrame
	local a = focus - before.Position
	local b = focus - after.Position
	if (after.Position - before.Position).Magnitude < 1e-3 or a.Magnitude < 0.3 or b.Magnitude < 0.3 then
		return after
	end
	a, b = a.Unit, b.Unit
	local axis = a:Cross(b)
	local sin = axis.Magnitude
	if sin < 1e-5 then
		return after
	end
	local angle = math.atan2(sin, a:Dot(b))
	return CFrame.new(after.Position) * CFrame.fromAxisAngle(axis / sin, angle) * after.Rotation
end

function fitCore(cf: CFrame, focus: Vector3, probe: Probe, opts: { [string]: any }?): (CFrame, number?)
	local o = opts or {}
	local distance0 = (cf.Position - focus).Magnitude
	if distance0 > CameraShots.FIT_FAR and type(probe) == "table" and type(probe.cast) == "function" then
		-- (mirando al cielo —la Grieta— la cámara va pegada a alguien, «por encima de su hombro»: si entre
		-- esa persona y la cámara hay una pared, la cámara está dentro de ella o al otro lado —en el
		-- prólogo, llegando de espaldas al garaje, dentro del garaje—. Se acerca a la persona hasta antes
		-- de la pared y desde ahí se busca el cielo)
		local ref, refDistance = nil, 15
		for _, list in { o.Keep or {}, o.Crowd or {} } do
			for _, point in list do
				-- (a menos de 2 studs de una cabeza, la cámara está dentro de esa persona: esa no es la referencia)
				if typeof(point) == "Vector3" and (point - cf.Position).Magnitude < refDistance and (point - cf.Position).Magnitude > 2 then
					ref, refDistance = point, (point - cf.Position).Magnitude
				end
			end
		end
		if ref and refDistance > 0.3 then
			local offset = cf.Position - ref
			local okHit, hit = pcall(probe.cast, ref, offset)
			if okHit and type(hit) == "number" then
				local keep = math.max(0.4, hit - CameraShots.FIT_MARGIN)
				cf = CFrame.new(ref + offset.Unit * keep) * cf.Rotation
			end
		end
		-- (y nadie a quemarropa delante: un plano «por encima del hombro» al cielo con alguien justo al
		-- lado de ti le metía la espalda en media pantalla. Se gira alrededor de la persona de referencia)
		local bodies = if type(probe.bodies) == "table" then probe.bodies else {}
		local function crowded(at: CFrame): boolean
			for _, body in bodies do
				if typeof(body.Head) == "Vector3" and (not ref or (body.Head - ref).Magnitude > 1.2) then
					for _, sphere in spheresOf(body) do
						local d = sphere[1] - at.Position
						local depth = d:Dot(at.LookVector)
						if depth > 0.1 and depth < 4 and (d - at.LookVector * depth).Magnitude < sphere[2] + depth * 0.6 then
							return true
						end
						-- (o, más lejos, un trozo de cuerpo que ocupa mucho del alto de la pantalla y sale en ella)
						if depth > 0.1 and nearTan then
							local lateral = (d - at.LookVector * depth).Magnitude
							if lateral < depth * nearTan * CameraShots.ASPECT + sphere[2] and sphere[2] / (depth * nearTan) > CameraShots.NEAR_BODY * 0.5 then
								return true
							end
						end
						if d.Magnitude < sphere[2] + 0.3 then
							return true
						end
					end
				end
			end
			return false
		end
		if ref and #bodies > 0 and crowded(cf) then
			local offset = cf.Position - ref
			for _, deg in { 35, -35, 70, -70, 110, -110, 150, -150 } do
				local turned = CFrame.Angles(0, math.rad(deg), 0):VectorToWorldSpace(offset)
				local at = ref + turned
				local okHit, hit = pcall(probe.cast, ref, turned)
				if okHit and hit == nil then
					local candidate = CameraShots.lookAt(at, at + cf.LookVector)
					if not crowded(candidate) then
						cf = candidate
						break
					end
				end
			end
		end
		return CameraShots.window(cf, focus, probe), nil
	end
	if distance0 < 0.05 or type(probe) ~= "table" or type(probe.cast) ~= "function" then
		return cf, nil
	end
	-- ¿Bajo techo? (sin decir Interior: HappeningClient y la auditoría) Entonces la sala es pequeña: los
	-- planos más cortos, como en DialogueUI
	local interior = o.Interior
	if interior == nil then
		local ok, up = pcall(probe.cast, focus, Vector3.new(0, CameraShots.ROOF_UP, 0))
		interior = ok and up ~= nil
	end
	-- (un plano de situación —opts.Wide— no se acorta: tiene que caber el grupo entero)
	if interior and not o.Wide and distance0 > CameraShots.INTERIOR_MIN then
		-- (un primer plano ya es corto: acortarlo más dejaba la cara fuera del cuadro)
		local k = math.max(0.7, CameraShots.INTERIOR_MIN / distance0)
		cf = CFrame.new(focus + (cf.Position - focus) * k) * cf.Rotation
	end
	local distance = (cf.Position - focus).Magnitude
	local minimum = math.min(o.Min or CameraShots.FIT_MIN, distance)
	local margin = CameraShots.FIT_MARGIN
	-- (opts.Front: hacia dónde mira quien sale. Ningún giro le deja la cámara detrás de la cara: antes,
	-- con la pared delante, el plano daba la vuelta y enseñaba la nuca llenando la pantalla)
	local front = if typeof(o.Front) == "Vector3" then flat(o.Front) else nil
	if front and front.Magnitude < 0.1 then
		front = nil
	end
	local function inFront(at: Vector3): boolean
		return front == nil or flat(at - focus):Dot(front.Unit) > 0.15 * flat(at - focus).Magnitude
	end
	-- Nadie ajeno cortado en un borde tapando más de EDGE_MAX (el del hombro, EDGE_OTS). Solo con el campo
	-- de visión del plano (opts.Fov) y con los cuerpos de la escena.
	local edgeBodies = if nearTan and type(probe.bodies) == "table" then probe.bodies else nil
	local near = if type(o.Line) == "table" and typeof(o.Line[1]) == "Vector3" then o.Line[1] else nil
	local function allowed(body: any): number?
		if (body.Head - focus).Magnitude < 1.2 or flat(body.Feet - focus).Magnitude < 1 then
			return nil -- (quien sale; o un inserto de sus manos: su propio cuerpo)
		end
		for _, point in o.Keep or {} do
			if typeof(point) == "Vector3" and (body.Head - point).Magnitude < 1.2 then
				return nil -- (los que tienen que salir)
			end
		end
		if near and (body.Head - near).Magnitude < 1.2 then
			return CameraShots.EDGE_OTS
		end
		return CameraShots.EDGE_MAX
	end
	local edgeFallback: CFrame?, edgeFallbackIndex: number?, edgeFallbackOver = nil, nil, math.huge
	local function edgeOk(candidate: CFrame, index: number?): boolean
		-- (una pared, una columna o una copa pegada a la cámara tapando buena parte del cuadro, aunque no
		-- tape la cara: «aparecen paredes». Se prueba otro giro; si ninguno, el que menos tapa)
		if nearTan then
			local clutter = CameraShots.clutter(candidate, focus, probe, nearTan)
			if clutter > CameraShots.CLUTTER_MAX then
				if clutter < edgeFallbackOver then
					edgeFallback, edgeFallbackIndex, edgeFallbackOver = candidate, index, clutter
				end
				return false
			end
		end
		if not edgeBodies or not nearTan then
			return true
		end
		local _, over = CameraShots.edgeCut(candidate, edgeBodies, nearTan, allowed)
		if over <= 0 then
			return true
		end
		if over < edgeFallbackOver then
			edgeFallback, edgeFallbackIndex, edgeFallbackOver = candidate, index, over
		end
		return false
	end
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
	-- (y que salgan en el cuadro: con el campo de visión del plano, opts.Fov. Un plano de situación de
	-- una conversación dejaba a quien habla fuera, en el borde)
	local function framesKeep(at: CFrame): boolean
		if not nearTan then
			return true
		end
		for _, point in keepList do
			if typeof(point) == "Vector3" then
				local rel = at:PointToObjectSpace(point)
				local depth = -rel.Z
				if depth <= 0.2 or math.abs(rel.X / (depth * nearTan * CameraShots.ASPECT)) > 0.95 or math.abs(rel.Y / (depth * nearTan)) > 0.95 then
					return false
				end
			end
		end
		return true
	end
	local function pulled(candidate: CFrame, floor: number): CFrame?
		local block = firstBlock(focus, candidate.Position, probe)
		if not block then
			return if seesKeep(candidate.Position) and framesKeep(candidate) then candidate else nil
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
		local result = CFrame.new(at) * candidate.Rotation
		return if framesKeep(result) then result else nil
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
		local kept = pulled(candidate, minimum) or (if front then nil else pulled(candidate, 0.5))
		if kept and inFront(kept.Position) and edgeOk(kept, o.Choice) then
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
	-- (en un plano de una cara, primero todos los giros a la altura de la cara y luego los de arriba: con un
	-- niño delante, subir 15-32° enseñaba su coronilla —«SinAire» en la auditoría— cuando girar de lado
	-- bastaba)
	local order = {}
	for index in orbits do
		table.insert(order, index)
	end
	if front then
		table.sort(order, function(a, b)
			local pa, pb = orbits[a][2] > 16, orbits[b][2] > 16
			if pa ~= pb then
				return pb
			end
			return a < b
		end)
	end
	for _, list in tries do
		keepList = list
		for pass = 1, if side ~= 0 then 2 else 1 do
			for _, index in order do
				local r = orbits[index]
				local candidate = orbit(cf, focus, r[1], r[2])
				local crosses = side ~= 0 and sideOf(candidate.Position) == -side
				-- (en un plano de una cara, nada de cenitales: desde 45° o más arriba se veía la coronilla)
				if crosses ~= (pass == 2) or not inFront(candidate.Position) or (front and r[2] > CameraShots.FACE_PITCH_MAX) then
					continue
				end
				local ok = pulled(candidate, minimum)
				if ok and edgeOk(ok, index) then
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
	-- (todos tenían a alguien cortado en un borde: más abierto, para que quepa entero —un bebé junto al
	-- sillón de Abu—; y si tampoco, el que menos)
	if edgeFallback and edgeBodies then
		for _, k in { 1.5, 2.2 } do
			for index, r in orbits do
				local candidate = orbit(cf, focus, r[1], r[2])
				if inFront(candidate.Position) and (side == 0 or sideOf(candidate.Position) ~= -side) then
					local wide = CFrame.new(focus + (candidate.Position - focus) * k) * candidate.Rotation
					local ok = pulled(wide, minimum)
					if ok and (ok.Position - focus).Magnitude > (candidate.Position - focus).Magnitude * 1.2 then
						local _, over = CameraShots.edgeCut(ok, edgeBodies, nearTan :: number, allowed)
						if over <= 0 and CameraShots.clutter(ok, focus, probe, nearTan :: number) <= CameraShots.CLUTTER_MAX then
							return ok, index
						end
					end
				end
			end
		end
	end
	if edgeFallback then
		return edgeFallback, edgeFallbackIndex
	end
	-- Dentro de una sala, si ningún giro vale: plano alto y abierto desde la esquina más lejana de la sala
	-- (la pared más lejos del foco, sin salir de ella), mirando a quien tiene que salir
	-- (en un plano de una cara, no si el mejor giro deja la cámara a una distancia que vale: desde la
	-- esquina, alto, a un niño se le veía la coronilla —«SinAire» en la auditoría—)
	if interior then
		local corner = CameraShots.corner(focus, probe, keepList, cf.Position - focus)
		if corner then
			return corner, nil
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
	-- (Ambient más alto: dentro de la casa grande las caras salían casi negras)
	InteriorCalido = { Tint = rgb(255, 236, 214), Ambient = rgb(152, 128, 106), Saturation = 0.06, Contrast = 0.06, Bloom = 0.9 },
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
