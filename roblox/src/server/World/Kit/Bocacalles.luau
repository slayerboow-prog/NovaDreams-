-- Bocacalles: dónde una calle desemboca en otra de distinto tipo, y los pasos de peatones.
--
-- Las calles de los barrios (Kit/Street) y las carreteras principales (Kit/Roads) se construyen por
-- separado. Donde una acaba dentro de la otra (una calle de la cuadrícula que llega a una avenida,
-- una carretera que termina en la circunvalación de un barrio, las calles que entran en una rotonda)
-- hay que coserlas para que no quede ni un hueco ni una acera cruzando la calzada:
--   * la que llega corta sus aceras justo en el borde del asfalto de la otra (cada lado por separado,
--     también si llega en diagonal) y, de ahí al final, su calzada ocupa todo el ancho
--   * la que recibe abre su acera en la boca, la rellena de asfalto y pone un paso de cebra por el
--     que sigue la acera, con el bordillo rebajado a los dos lados
--   * en las rotondas, la calle corta sus aceras donde empieza el anillo y la rotonda (Kit/Roads)
--     deja el hueco en su acera circular y pone el paso de peatones
--
-- Todo son cuentas (nada se construye aquí salvo los pasos de cebra, con Bocacalles.crossing), y
-- dan lo mismo en Kit/Street, Kit/Roads, TerrainBuilder y las pruebas.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Builder = require(script.Parent.Parent.Builder)
local Palette = require(script.Parent.Palette)
local Roads = require(script.Parent.Roads)
local CityPlan = require(ReplicatedStorage.Shared.CityPlan)

local Bocacalles = {}

local G = Palette.Ground
local V3 = Vector3.new

local STREET_HALF = 12 -- media calzada de una calle de barrio (Kit/Street)
local STREET_W = 20 -- hasta el borde de su acera

type Corridor = {
	Ref: any,
	IsStreet: boolean,
	A: Vector3,
	B: Vector3,
	M: Vector3, -- a lo largo (de A a B)
	N: Vector3, -- de lado (el "lado +1" de la calle)
	Len: number,
	H: number, -- media calzada
	W: number, -- hasta el borde exterior de la acera
	Kind: string,
	Base: number, -- coordenada propia de A (u = Base + distancia desde A)
}

export type Cut = { From: number, To: number, SafeFrom: number, SafeTo: number }
export type Clip = { Walk: { [number]: number }, Mark: number, Apron: boolean }
export type Crossing = { Center: Vector3, WalkDir: Vector3, Length: number, Depth: number, Ramps: { boolean }?, Walk: boolean? }

export type Result = {
	Clips: { [any]: { [string]: Clip } }, -- [calle o tramo][ "A" | "B" ] → recorte de sus aceras
	Cuts: { [any]: { [number]: { Cut } } }, -- [calle o tramo][lado] → bocas abiertas en su acera
	Crossings: { Crossing }, -- pasos de cebra de las bocas (en la acera de la que recibe)
	Approaches: { [string]: { any } }, -- [rotonda] → calles que entran (además de las carreteras)
	Arrivals: { any }, -- tramos finales de las que llegan (para no poner nada encima)
}

local function flat(v: Vector3): Vector3
	return V3(v.X, 0, v.Z)
end

local function streetCorridor(road: any): Corridor
	local M = if road.Axis == "X" then V3(1, 0, 0) else V3(0, 0, 1)
	local N = if road.Axis == "X" then V3(0, 0, 1) else V3(1, 0, 0)
	local A = if road.Axis == "X" then V3(road.From, 0, road.At) else V3(road.At, 0, road.From)
	local B = if road.Axis == "X" then V3(road.To, 0, road.At) else V3(road.At, 0, road.To)
	return { Ref = road, IsStreet = true, A = A, B = B, M = M, N = N, Len = road.To - road.From, H = STREET_HALF, W = STREET_W, Kind = "Calle", Base = road.From }
end

local function mainCorridor(s: any): Corridor
	local kind = Roads.Kinds[s.Kind]
	local d = s.B - s.A
	local M = d.Unit
	return { Ref = s, IsStreet = false, A = s.A, B = s.B, M = M, N = V3(-M.Z, 0, M.X), Len = d.Magnitude, H = kind.Road / 2, W = kind.Road / 2 + kind.Walk, Kind = s.Kind, Base = 0 }
end

local cached: Result? = nil
local cachedFor: any = nil

-- Calcula todas las bocas para esta lista de calles de barrio (la de Region.roads())
function Bocacalles.compute(streets: { any }): Result
	if cached and cachedFor == #streets then
		return cached :: Result
	end
	local result: Result = { Clips = {}, Cuts = {}, Crossings = {}, Approaches = {}, Arrivals = {} }
	local corridors: { Corridor } = {}
	for _, s in Roads.segments() do
		table.insert(corridors, mainCorridor(s))
	end
	for _, road in streets do
		table.insert(corridors, streetCorridor(road))
	end
	local nodes = Roads.nodeMap()
	local R = Roads.ROUNDABOUT_R
	local RW = Roads.RING_WALK

	local function setClip(X: Corridor, endKey: string, side: number, along: number, mark: number, apron: boolean)
		local byEnd = result.Clips[X.Ref]
		if not byEnd then
			byEnd = {}
			result.Clips[X.Ref] = byEnd
		end
		local clip = byEnd[endKey]
		if not clip then
			clip = { Walk = {}, Mark = mark, Apron = apron }
			byEnd[endKey] = clip
		end
		clip.Walk[side] = X.Base + along
		clip.Mark = if endKey == "B" then math.min(clip.Mark, mark) else math.max(clip.Mark, mark)
	end

	for _, X in corridors do
		for _, endKey in { "A", "B" } do
			local E = if endKey == "A" then X.A else X.B
			local d = if endKey == "A" then -X.M else X.M -- hacia la punta
			local alongE = if endKey == "A" then 0 else X.Len
			local sign = if endKey == "A" then -1 else 1 -- (la coordenada propia crece hacia B)
			if not X.IsStreet then
				local n = nodes[Roads.key(E)]
				if n and (n.Roundabout or n.Count >= 2) then
					continue -- los cruces y rotondas de las carreteras los resuelve Kit/Roads
				end
			end
			-- ¿Entra en una rotonda?
			local done = false
			if X.IsStreet then
				for _, rb in CityPlan.Roundabouts do
					local c = V3(rb[1], 0, rb[2])
					if (E - c).Magnitude < R + RW + 3 then
						local markT = nil
						for _, s in { -1, 1 } do
							-- La esquina interior de la acera llega hasta el borde del anillo (R - 1)
							local q = E + X.N * (s * X.H) - c
							local qd = q:Dot(d)
							local disc = qd * qd - q:Dot(q) + (R - 1) ^ 2
							local t = if disc >= 0 then math.min(0, -qd - math.sqrt(disc)) else 0
							-- Las marcas acaban antes del paso de peatones (en la acera de la rotonda)
							local e0 = E - c
							local ed = e0:Dot(d)
							local disc2 = ed * ed - e0:Dot(e0) + (R + RW + 0.8) ^ 2
							markT = if disc2 >= 0 then math.min(0, -ed - math.sqrt(disc2)) else t
							setClip(X, endKey, s, alongE + sign * t, X.Base + alongE + sign * (markT :: number), false)
						end
						-- Si otra calle la cruza justo antes de la rotonda, se cruza por el paso de ese cruce
						local noCross = false
						for _, Y in corridors do
							if Y.IsStreet and Y ~= X and math.abs(Y.M:Dot(X.M)) < 0.1 then
								local t = -((E - Y.A):Dot(Y.N)) / d:Dot(Y.N)
								local crossAt = E + d * t
								local along = (crossAt - Y.A):Dot(Y.M)
								if t <= 1 and along > -1 and along < Y.Len + 1 and (crossAt - c).Magnitude < R + RW + 30 then
									noCross = true
								end
							end
						end
						local key = Roads.key(c)
						result.Approaches[key] = result.Approaches[key] or {}
						table.insert(result.Approaches[key], { E = E, D = d, N = X.N, H = X.H, W = X.W, Walk = true, Ref = X.Ref, NoCross = noCross })
						table.insert(result.Arrivals, { E = E, D = d, N = X.N, H = X.H, TMin = -(R + RW + 8) - (c - E):Dot(d) })
						done = true
						break
					end
				end
			end
			if done then
				continue
			end
			-- ¿Acaba dentro de otra carretera (de distinto tipo)?
			local best: Corridor? = nil
			local bestLat = math.huge
			for _, Y in corridors do
				if Y.IsStreet ~= X.IsStreet then
					local rel = E - Y.A
					local along = rel:Dot(Y.M)
					local lat = rel:Dot(Y.N)
					if along >= -2 and along <= Y.Len + 2 and math.abs(lat) <= Y.W + 2 and math.abs(d:Dot(Y.N)) >= 0.25 and math.abs(lat) < bestLat then
						best, bestLat = Y, math.abs(lat)
					end
				end
			end
			if not best then
				continue
			end
			local Y = best :: Corridor
			local sigma = if d:Dot(Y.N) > 0 then -1 else 1 -- lado de Y por el que llega
			local Ny = Y.N * sigma
			local latE = (E - Y.A):Dot(Ny)
			local a = d:Dot(Ny) -- (< 0: al avanzar se acerca)
			local b = X.N:Dot(Ny)
			local tMin = 0
			for _, s in { -1, 1 } do
				local v1, v2 = s * X.H, s * X.W
				local t = (Y.H - latE - math.min(v1 * b, v2 * b)) / a
				t = math.clamp(t, -X.Len + 1, 0)
				tMin = math.min(tMin, t)
				setClip(X, endKey, s, alongE + sign * t, X.Base + alongE + sign * t, true)
			end
			table.insert(result.Arrivals, { E = E, D = d, N = X.N, H = X.H, TMin = tMin - 3 })
			-- La que recibe abre su acera en la boca (si tiene acera)
			if Y.W - Y.H > 0.5 then
				local lo, hi = math.huge, -math.huge
				local safeLo, safeHi = -math.huge, math.huge
				for _, L in { Y.H, Y.W } do
					local l0, l1 = math.huge, -math.huge
					for _, v in { -X.H, X.H } do
						local t = (L - latE - v * b) / a
						local P = E + d * t + X.N * v
						local along = (P - Y.A):Dot(Y.M)
						lo, hi = math.min(lo, along), math.max(hi, along)
						l0, l1 = math.min(l0, along), math.max(l1, along)
					end
					safeLo, safeHi = math.max(safeLo, l0), math.min(safeHi, l1)
				end
				lo, hi = math.max(lo - 0.3, -2), math.min(hi + 0.3, Y.Len + 2)
				local cuts = result.Cuts[Y.Ref]
				if not cuts then
					cuts = { [-1] = {}, [1] = {} }
					result.Cuts[Y.Ref] = cuts
				end
				table.insert(cuts[sigma], { From = Y.Base + lo, To = Y.Base + hi, SafeFrom = Y.Base + safeLo, SafeTo = Y.Base + safeHi })
				-- Paso de cebra por donde sigue la acera, con rampas al llegar a cada trozo de acera
				local len = safeHi - safeLo
				if len >= 8 then
					local mid = (safeLo + safeHi) / 2
					local band = Y.W - Y.H
					local center = Y.A + Y.M * mid + Ny * (Y.H + band / 2)
					table.insert(result.Crossings, { Center = center, WalkDir = Y.M, Length = len, Depth = math.max(band - 1, 3) })
				end
			end
		end
	end
	cached = result
	cachedFor = #streets
	return result
end

-- ¿Cae el punto en la parte final de una calle que desemboca en otra? (ahí no va nada encima)
function Bocacalles.blocked(p: Vector3, margin: number?): boolean
	if not cached then
		return false
	end
	local m = margin or 0.5
	for _, arr in (cached :: Result).Arrivals do
		local rel = flat(p) - arr.E
		local t = rel:Dot(arr.D)
		local v = rel:Dot(arr.N)
		if math.abs(v) < arr.H + m and t > arr.TMin - m and t < 4 then
			return true
		end
	end
	return false
end

-- Recorta un tramo [a, b] quitando los huecos (bocas): devuelve los trozos que quedan
function Bocacalles.subtract(a: number, b: number, cuts: { Cut }?): { { number } }
	local pieces = { { a, b } }
	for _, c in cuts or {} do
		local out = {}
		for _, p in pieces do
			if c.To <= p[1] or c.From >= p[2] then
				table.insert(out, p)
			else
				if c.From > p[1] then
					table.insert(out, { p[1], c.From })
				end
				if c.To < p[2] then
					table.insert(out, { c.To, p[2] })
				end
			end
		end
		pieces = out
	end
	return pieces
end

-- ¿u cae en una boca (con margen)?
function Bocacalles.inCut(u: number, cuts: { Cut }?, margin: number): boolean
	for _, c in cuts or {} do
		if u > c.From - margin and u < c.To + margin then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
-- Paso de cebra con el bordillo rebajado
--   center: en el centro del paso, a ras del suelo; walkDir: por donde se cruza;
--   length: de bordillo a bordillo; depth: ancho del paso (a lo largo del tráfico)
--   ramps: { lado -1, lado +1 } (por defecto las dos): rampa donde hay acera
---------------------------------------------------------------------
function Bocacalles.crossing(parent: Instance, center: Vector3, walkDir: Vector3, length: number, depth: number, ramps: { boolean }?, roadTop: number?, walkTop: number?): Model
	local m = Builder.model("PasoCebra", parent)
	local top = roadTop or 0.4
	local rise = (walkTop or 1.0) - top
	local dir = flat(walkDir).Unit
	-- Marco: X local = por donde se cruza, Z local = a lo largo del tráfico
	local base = Builder.facing(V3(center.X, top, center.Z), V3(dir.Z, 0, -dir.X))
	local RAMP = 1.6
	local has = ramps or { true, true }
	if not has[1] and not has[2] then
		m:SetAttribute("NoWalk", true)
	end
	for i, s in { -1, 1 } do
		if has[i] then
			-- Cuña: alta junto a la acera (Z+ local de la cuña apunta hacia fuera)
			local x = s * (length / 2 - RAMP / 2)
			local pos = base * CFrame.new(x, rise / 2, 0)
			Builder.part({
				ClassName = "WedgePart",
				Name = "KerbRamp",
				Size = V3(depth, rise, RAMP),
				CFrame = CFrame.new(pos.Position) * CFrame.Angles(0, math.atan2(dir.X * s, dir.Z * s), 0),
				Color = G.Sidewalk,
				Material = Enum.Material.Pavement,
				CastShadow = false,
				Parent = m,
			})
		end
	end
	-- Franjas blancas (fuera de las rampas)
	local x0 = -length / 2 + (if has[1] then RAMP else 0) + 0.9
	local x1 = length / 2 - (if has[2] then RAMP else 0) - 0.9
	local count = math.max(1, math.floor((x1 - x0 + 1.3) / 2.5))
	local stepX = if count > 1 then (x1 - x0 - 1.1) / (count - 1) else 0
	for k = 0, count - 1 do
		local x = if count > 1 then x0 + 0.55 + k * stepX else (x0 + x1) / 2
		Builder.decor({
			Name = "Zebra",
			Size = V3(1.1, 0.05, depth),
			CFrame = base * CFrame.new(x, 0.035, 0),
			Color = G.Marking,
			Material = Enum.Material.SmoothPlastic,
			Parent = m,
		})
	end
	return m
end

return Bocacalles
