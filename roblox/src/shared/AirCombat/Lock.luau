-- Lock: fijar un blanco para los misiles y la ayuda a apuntar del láser (combate aéreo).
--
--   * Fijación: el blanco tiene que estar dentro del cono del morro (Cone) y a menos de Range. Se elige
--     el que esté más cerca del centro (y algo por cercanía). Mantenerlo dentro LockTime segundos lo
--     FIJA (tono de fijado y recuadro rojo). Se suelta si sale de un cono algo mayor (Hold), si se
--     aleja demasiado o si desaparece. Cambiar de blanco empieza de cero.
--   * Ayuda a apuntar (láser): si hay un blanco dentro de un cono pequeño (más grande en el móvil),
--     el disparo va a donde ESTARÁ (adelantado según su velocidad y la del proyectil).
-- Blancos: { { Id = string, Pos = Vector3, Vel = Vector3? } }. Cuentas puras (scripts/test-aircombat.luau).

local Lock = {}

Lock.Config = {
	Cone = math.rad(13),
	Hold = math.rad(20),
	Range = 950,
	LockTime = 0.85,
	AssistCone = math.rad(5), -- ordenador
	AssistConeTouch = math.rad(9), -- móvil (dedos menos precisos)
}

export type Target = { Id: string, Pos: Vector3, Vel: Vector3?, Kind: string? }
export type State = { Target: string?, Progress: number, Locked: boolean }

function Lock.new(): State
	return { Target = nil, Progress = 0, Locked = false }
end

-- Ángulo (rad) entre el morro y el blanco
function Lock.angle(origin: Vector3, look: Vector3, pos: Vector3): number
	local to = pos - origin
	if to.Magnitude < 1e-4 then
		return 0
	end
	return math.acos(math.clamp(look.Unit:Dot(to.Unit), -1, 1))
end

-- El mejor blanco dentro del cono y el alcance (nil si ninguno). Puntuación: ángulo + algo de distancia.
function Lock.best(origin: Vector3, look: Vector3, targets: { Target }, range: number?, cone: number?): Target?
	local r = range or Lock.Config.Range
	local c = cone or Lock.Config.Cone
	local best, bestScore = nil, math.huge
	for _, t in targets do
		local dist = (t.Pos - origin).Magnitude
		if dist <= r and dist > 1 then
			local a = Lock.angle(origin, look, t.Pos)
			if a <= c then
				local score = a / c + dist / r * 0.35
				if score < bestScore then
					best, bestScore = t, score
				end
			end
		end
	end
	return best
end

local function find(targets: { Target }, id: string?): Target?
	if not id then
		return nil
	end
	for _, t in targets do
		if t.Id == id then
			return t
		end
	end
	return nil
end

-- Avanza la fijación. Devuelve el evento: "Start" (empieza a fijar), "Locked", "Lost" o nil.
function Lock.update(s: State, origin: Vector3, look: Vector3, targets: { Target }, dt: number, cfg: { [string]: number }?): string?
	local C = cfg or Lock.Config
	local current = find(targets, s.Target)
	if current then
		local dist = (current.Pos - origin).Magnitude
		local a = Lock.angle(origin, look, current.Pos)
		if dist > (C.Range or Lock.Config.Range) * 1.1 or a > (C.Hold or Lock.Config.Hold) then
			current = nil
		end
	end
	if not current then
		local had = s.Target ~= nil
		s.Target, s.Progress, s.Locked = nil, 0, false
		local pick = Lock.best(origin, look, targets, C.Range, C.Cone)
		if pick then
			s.Target = pick.Id
			return "Start"
		end
		return if had then "Lost" else nil
	end
	if not s.Locked then
		s.Progress = math.min(1, s.Progress + dt / (C.LockTime or Lock.Config.LockTime))
		if s.Progress >= 1 then
			s.Locked = true
			return "Locked"
		end
	end
	return nil
end

-- Punto al que apuntar para dar a un blanco que se mueve (dos pasadas: basta para el arcade)
function Lock.lead(origin: Vector3, shotSpeed: number, pos: Vector3, vel: Vector3?): Vector3
	if not vel or shotSpeed <= 0 then
		return pos
	end
	local aim = pos
	for _ = 1, 2 do
		local t = (aim - origin).Magnitude / shotSpeed
		aim = pos + vel * t
	end
	return aim
end

-- Ayuda a apuntar: la dirección corregida hacia el blanco más centrado dentro del cono pequeño (con
-- adelanto), o la misma `aim` si no hay ninguno. Devuelve también el Id del blanco.
function Lock.assist(origin: Vector3, aim: Vector3, targets: { Target }, cone: number, shotSpeed: number, range: number?): (Vector3, string?)
	local dir = aim.Unit
	local best: Target? = nil
	local bestA = cone
	local r = range or Lock.Config.Range * 1.1
	for _, t in targets do
		local dist = (t.Pos - origin).Magnitude
		if dist <= r and dist > 1 then
			local lead = Lock.lead(origin, shotSpeed, t.Pos, t.Vel)
			local a = math.min(Lock.angle(origin, dir, t.Pos), Lock.angle(origin, dir, lead))
			if a <= bestA then
				best, bestA = t, a
			end
		end
	end
	if not best then
		return dir, nil
	end
	local lead = Lock.lead(origin, shotSpeed, best.Pos, best.Vel)
	return (lead - origin).Unit, best.Id
end

return Lock
