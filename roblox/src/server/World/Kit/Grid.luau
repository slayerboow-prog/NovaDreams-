-- Grid: la red de calles secundarias que cubre todos los distritos (fase 4 del plano).
--
-- Calles rectas norte-sur y este-oeste sobre una cuadrícula:
--   * cada 250 studs dentro de la Ronda (Distrito Centro, manzanas densas)
--   * cada 500 studs en el resto de distritos
-- Se cortan donde no puede haber calle (barrios ya construidos, río, lagos, montañas, playa,
-- carreteras principales) y después se recortan hasta su último cruce: así ninguna calle
-- acaba en medio de la nada. Son calles normales de Kit/Street (aceras, cruces con semáforos,
-- farolas), así que el tráfico, el mapa y la historia las usan como las demás.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CityPlan = require(ReplicatedStorage.Shared.CityPlan)
local Roads = require(script.Parent.Roads)
local Landmarks = require(script.Parent.Landmarks)

local Grid = {}

local OFFSET = 125 -- desplazamiento de la cuadrícula (así ninguna línea cae encima de la Ronda o de las avenidas)
local STEP_CENTER = 250
local STEP = 500
local RING = 1250 -- la Ronda de Valmar
local SAMPLE = 10
local HALF = 20 -- mitad del ancho de una calle con aceras

type Rect = { X0: number, X1: number, Z0: number, Z1: number }
type Road = { Axis: string, At: number, From: number, To: number, Lamps: boolean?, LampEvery: number?, Solid: boolean? }

-- ¿Puede ir una calle por este punto?
local function allowed(x: number, z: number, avoid: { Rect }): boolean
	-- Dentro de la isla y lejos de la playa
	for _, d in { { 0, 0 }, { 110, 0 }, { -110, 0 }, { 0, 110 }, { 0, -110 } } do
		if not CityPlan.inside(CityPlan.Coast, x + d[1], z + d[2]) then
			return false
		end
	end
	if not CityPlan.districtAt(x, z) then
		return false
	end
	for _, r in avoid do
		if x > r.X0 and x < r.X1 and z > r.Z0 and z < r.Z1 then
			return false
		end
	end
	if CityPlan.riverDistance(x, z) < CityPlan.River.Width / 2 + 40 then
		return false
	end
	for _, lake in CityPlan.Lakes do
		if math.sqrt((x - lake.X) ^ 2 + (z - lake.Z) ^ 2) < lake.R + 45 then
			return false
		end
	end
	for _, m in CityPlan.Mountains do
		local ground = math.sqrt(math.max(0, m.R * m.R - (m.R - m.H) ^ 2))
		if math.sqrt((x - m.X) ^ 2 + (z - m.Z) ^ 2) < ground + 30 then
			return false
		end
	end
	if Landmarks.blocked(x, z) then
		return false
	end
	-- Las carreteras principales (y sus rotondas) no se pisan: la calle se corta a su lado
	return not Roads.near(x, z, HALF + 4)
end

-- Tramos permitidos de una línea
local function spans(axis: string, at: number, from: number, to: number, avoid: { Rect }): { { number } }
	local out = {}
	local start: number? = nil
	local u = from
	while u <= to do
		local x, z = if axis == "X" then u else at, if axis == "X" then at else u
		local ok = allowed(x, z, avoid)
		if ok and not start then
			start = u
		elseif not ok and start then
			if u - SAMPLE - start > 60 then
				table.insert(out, { start, u - SAMPLE })
			end
			start = nil
		end
		u += SAMPLE
	end
	if start and to - start > 60 then
		table.insert(out, { start, to })
	end
	return out
end

local cache: { Road }? = nil

-- towns: centros de las cuadrículas de barrio ya construidas (se evitan)
function Grid.roads(towns: { Vector3 }, extra: { Road }): { Road }
	if cache then
		return cache
	end
	local avoid: { Rect } = {
		{ X0 = -420, X1 = 420, Z0 = -262, Z1 = 300 }, -- Valmar Centro
	}
	for _, c in towns do
		table.insert(avoid, { X0 = c.X - 400, X1 = c.X + 400, Z0 = c.Z - 400, Z1 = c.Z + 400 })
	end
	local b = CityPlan.Bounds
	local lines: { Road } = {}
	local function addLines(axis: string, step: number, lo: number, hi: number, crossLo: number, crossHi: number, onlyInsideRing: boolean?)
		local k0 = math.ceil((lo - OFFSET) / step)
		local k1 = math.floor((hi - OFFSET) / step)
		for k = k0, k1 do
			local at = OFFSET + k * step
			for _, span in spans(axis, at, crossLo, crossHi, avoid) do
				local road = { Axis = axis, At = at, From = span[1], To = span[2], Lamps = true, LampEvery = 72, Solid = true }
				-- Dentro de la Ronda la cuadrícula es más densa; fuera, se evita el anillo interior
				if onlyInsideRing then
					road.From = math.max(road.From, -RING + 40)
					road.To = math.min(road.To, RING - 40)
				end
				if road.To - road.From > 60 then
					table.insert(lines, road)
				end
			end
		end
	end
	-- Centro (dentro de la Ronda): cada 250
	addLines("X", STEP_CENTER, -RING + 40, RING - 40, -RING + 40, RING - 40, true)
	addLines("Z", STEP_CENTER, -RING + 40, RING - 40, -RING + 40, RING - 40, true)
	-- Resto de distritos (fuera de la Ronda): cada 500, sin entrar en el anillo
	local outside: { Road } = {}
	do
		local saved = lines
		lines = {}
		addLines("X", STEP, b.MinZ, b.MaxZ, b.MinX, b.MaxX)
		addLines("Z", STEP, b.MinX, b.MaxX, b.MinZ, b.MaxZ)
		for _, road in lines do
			-- quitar lo que cae dentro de la Ronda (allí ya está la cuadrícula densa)
			local inside = math.abs(road.At) < RING + 40
			if inside then
				if road.From < -RING - 40 then
					table.insert(outside, { Axis = road.Axis, At = road.At, From = road.From, To = math.min(road.To, -RING - 40), Lamps = true, LampEvery = 72, Solid = true })
				end
				if road.To > RING + 40 then
					table.insert(outside, { Axis = road.Axis, At = road.At, From = math.max(road.From, RING + 40), To = road.To, Lamps = true, LampEvery = 72, Solid = true })
				end
			else
				table.insert(outside, road)
			end
		end
		lines = saved
		for _, road in outside do
			if road.To - road.From > 60 then
				table.insert(lines, road)
			end
		end
	end

	-- Recortar cada calle hasta su primer y último cruce (con otra calle de la cuadrícula, de un
	-- barrio o una carretera principal): nada de calles que acaban en el campo
	local function crossings(road: Road, all: { Road }): { number }
		local list = {}
		for _, other in all do
			if other ~= road and other.Axis ~= road.Axis and other.At >= road.From - 1 and other.At <= road.To + 1 and road.At >= other.From - 1 and road.At <= other.To + 1 then
				table.insert(list, other.At)
			end
		end
		-- Donde toca una carretera principal (se cortó a su lado) también vale como final
		for _, edge in { road.From, road.To } do
			local x, z = if road.Axis == "X" then edge else road.At, if road.Axis == "X" then road.At else edge
			local ex, ez = if road.Axis == "X" then (if edge == road.From then -1 else 1) else 0, if road.Axis == "Z" then (if edge == road.From then -1 else 1) else 0
			if Roads.near(x + ex * (SAMPLE + 2), z + ez * (SAMPLE + 2), HALF + 4) then
				table.insert(list, edge)
			end
		end
		table.sort(list)
		return list
	end
	for _ = 1, 3 do
		local all = table.clone(lines)
		for _, r in extra do
			table.insert(all, r)
		end
		local kept = {}
		for _, road in lines do
			local list = crossings(road, all)
			if #list >= 2 then
				local from, to = list[1], list[#list]
				if to - from > 60 then
					road.From, road.To = from, to
					table.insert(kept, road)
				end
			end
		end
		lines = kept
	end
	cache = lines
	return lines
end

return Grid
