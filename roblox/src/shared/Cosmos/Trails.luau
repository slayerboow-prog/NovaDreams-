-- Trails: los SENDEROS de las tierras salvajes de los planetas (los usan shared/Cosmos/PlanetSurface y Tefra para
-- pintarlos en el terreno, y Services/BeastService para los carteles de cada zona de caza). Cuentas puras.

-- SENDEROS de las tierras salvajes: cuatro caminos que salen de la ciudad hacia los confines (pasan por las
-- cuatro zonas de caza), un poco serpenteantes. Devuelve (¿en el sendero?, índice del sendero)
local function trailAngle(seed: number, k: number): number
	return (seed % 360) * math.pi / 180 + (k - 1) * math.pi / 2 + 0.3
end
local function make(core: number, half: number, seed: number)
	local r0, r1 = core * 0.7, half - 460
	local T = { R0 = r0, R1 = r1, Width = 9 }
	-- el ángulo del sendero k a una distancia r del centro
	function T.angleAt(k: number, r: number): number
		return trailAngle(seed, k) + (38 * math.sin(r / 170 + k * 1.7)) / math.max(r, 1)
	end
	function T.at(lx: number, lz: number): (boolean, number?)
		if r1 <= r0 then
			return false, nil
		end
		local r = math.sqrt(lx * lx + lz * lz)
		if r < r0 or r > r1 then
			return false, nil
		end
		local a = math.atan2(lz, lx)
		for k = 1, 4 do
			local d = (a - T.angleAt(k, r) + math.pi) % (2 * math.pi) - math.pi
			if math.abs(d) * r <= T.Width then
				return true, k
			end
		end
		return false, nil
	end
	-- un punto del sendero k a la distancia r (local)
	function T.point(k: number, r: number): (number, number)
		local a = T.angleAt(k, r)
		return math.cos(a) * r, math.sin(a) * r
	end
	return T
end

return { make = make }
