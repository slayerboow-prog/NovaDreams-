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

return CameraShots
