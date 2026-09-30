-- SeasonMath: cuentas puras del pase de temporada (sin Roblox: se prueban con Lune).
--   * Curva de XP: XP de cada nivel, total hasta un nivel y nivel a partir de la XP total.
--   * Días y semanas en UTC (los retos diarios cambian a las 00:00 UTC; los semanales, el lunes).
--   * Hash estable (FNV-1a) para elegir las misiones del día igual en todos los servidores.

local SeasonMath = {}

export type Curve = { Base: number, Step: number }

-- XP para pasar del nivel "level" al siguiente
function SeasonMath.xpToNext(curve: Curve, level: number): number
	return math.max(1, math.floor(curve.Base + curve.Step * (level - 1)))
end

-- XP total que hace falta para estar en "level" (nivel 1 = 0)
function SeasonMath.totalFor(curve: Curve, level: number): number
	local total = 0
	for l = 1, level - 1 do
		total += SeasonMath.xpToNext(curve, l)
	end
	return total
end

-- Nivel, XP dentro del nivel y XP que pide el nivel, a partir de la XP total (con tope maxLevel)
function SeasonMath.levelFrom(curve: Curve, maxLevel: number, total: number): (number, number, number)
	local level = 1
	local rest = math.max(0, math.floor(total))
	while level < maxLevel do
		local need = SeasonMath.xpToNext(curve, level)
		if rest < need then
			return level, rest, need
		end
		rest -= need
		level += 1
	end
	return maxLevel, rest, 0 -- (en el máximo: rest = XP de más)
end

-- Día (UTC) desde 1970 y semana (que empieza en lunes: el 1-ene-1970 fue jueves)
function SeasonMath.dayIndex(now: number): number
	return math.floor(now / 86400)
end
function SeasonMath.weekIndex(now: number): number
	return math.floor((SeasonMath.dayIndex(now) + 3) / 7)
end
-- Cuándo empieza el día / la semana siguiente (para «se renueva en…»)
function SeasonMath.nextDayAt(now: number): number
	return (SeasonMath.dayIndex(now) + 1) * 86400
end
function SeasonMath.nextWeekAt(now: number): number
	return ((SeasonMath.weekIndex(now) + 1) * 7 - 3) * 86400
end

-- Hash estable de un texto (FNV-1a de 32 bits)
function SeasonMath.hash(text: string): number
	local h = 2166136261
	for i = 1, #text do
		h = bit32.bxor(h, string.byte(text, i))
		h = (h * 16777619) % 4294967296
	end
	return h
end

-- Elige "count" elementos distintos de "pool" de forma estable para "seed" (sin repetir y sin los de "avoid")
function SeasonMath.pick(pool: { any }, count: number, seed: string, avoid: { [any]: boolean }?): { any }
	local chosen = {}
	local used: { [number]: boolean } = {}
	if #pool == 0 then
		return chosen
	end
	local n = 0
	for slot = 1, count do
		local start = SeasonMath.hash(seed .. ":" .. slot) % #pool
		for offset = 0, #pool - 1 do
			local index = (start + offset) % #pool + 1
			local item = pool[index]
			if not used[index] and not (avoid and avoid[item]) then
				used[index] = true
				table.insert(chosen, item)
				n += 1
				break
			end
		end
		if n < slot then
			break -- (no quedan más)
		end
	end
	return chosen
end

return SeasonMath
