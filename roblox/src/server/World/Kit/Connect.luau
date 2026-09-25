-- Connect: que ninguna calle acabe en la nada.
--
-- Repasa los extremos de todas las calles rectas (las de los barrios y la cuadrícula) y, si un
-- extremo no toca otra carretera:
--   1) la alarga en línea recta hasta la carretera más cercana que tenga delante (sin cruzar agua,
--      montañas, manzanas, lugares especiales ni salir de la isla), o
--   2) si no puede, la recorta hasta su último cruce (así no queda ningún trozo suelto).
-- Lo usa Region.roads(): el resultado es la lista de calles que se construye, la que usa el
-- tráfico y la que hunde el terreno.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CityPlan = require(ReplicatedStorage.Shared.CityPlan)
local Roads = require(script.Parent.Roads)
local Landmarks = require(script.Parent.Landmarks)

local Connect = {}

type Road = { Axis: string, At: number, From: number, To: number, [string]: any }
type Rect = { X0: number, X1: number, Z0: number, Z1: number }

local HALF = 12 -- media calzada de una calle
local STEP = 4 -- paso al buscar hacia delante
local MAX_EXTEND = 700 -- como mucho se alarga esto
local ROUNDABOUT_R = 56

local function point(road: Road, u: number): (number, number)
	if road.Axis == "X" then
		return u, road.At
	end
	return road.At, u
end

-- ¿El punto (x, z) cae sobre otra carretera (calle, carretera principal o rotonda)?
local function touches(self: Road, x: number, z: number, roads: { Road }): boolean
	for _, other in roads do
		if other ~= self then
			local along = if other.Axis == "X" then x else z
			local across = if other.Axis == "X" then z else x
			if math.abs(across - other.At) <= HALF + 1 and along >= other.From - HALF and along <= other.To + HALF then
				return true
			end
		end
	end
	for _, s in Roads.segments() do
		local kind = Roads.Kinds[s.Kind]
		if CityPlan.segmentDistance(x, z, s.A.X, s.A.Z, s.B.X, s.B.Z) <= kind.Road / 2 + 1 then
			return true
		end
	end
	for _, r in CityPlan.Roundabouts do
		if math.sqrt((x - r[1]) ^ 2 + (z - r[2]) ^ 2) <= ROUNDABOUT_R then
			return true
		end
	end
	return false
end

-- ¿Se puede asfaltar este punto al alargar una calle?
local function free(x: number, z: number, blocked: { Rect }): boolean
	for _, d in { { 0, 0 }, { 50, 0 }, { -50, 0 }, { 0, 50 }, { 0, -50 } } do
		if not CityPlan.inside(CityPlan.Coast, x + d[1], z + d[2]) then
			return false
		end
	end
	if CityPlan.riverDistance(x, z) < CityPlan.River.Width / 2 + 25 then
		return false -- las calles no tienen puente: no cruzan el río
	end
	for _, lake in CityPlan.Lakes do
		if math.sqrt((x - lake.X) ^ 2 + (z - lake.Z) ^ 2) < lake.R + 30 then
			return false
		end
	end
	for _, m in CityPlan.Mountains do
		local ground = math.sqrt(math.max(0, m.R * m.R - (m.R - m.H) ^ 2))
		if math.sqrt((x - m.X) ^ 2 + (z - m.Z) ^ 2) < ground + 15 then
			return false
		end
	end
	if Landmarks.blocked(x, z) then
		return false
	end
	for _, r in blocked do
		if x > r.X0 and x < r.X1 and z > r.Z0 and z < r.Z1 then
			return false
		end
	end
	return true
end

-- Cruces de una calle con las demás (posición a lo largo de la calle)
local function crossings(self: Road, roads: { Road }): { number }
	local list = {}
	for _, other in roads do
		if other ~= self and other.Axis ~= self.Axis then
			if other.At >= self.From - HALF and other.At <= self.To + HALF and self.At >= other.From - HALF and self.At <= other.To + HALF then
				table.insert(list, other.At)
			end
		end
	end
	for _, s in Roads.segments() do
		-- Cruce de la línea de la calle con el tramo
		local a = if self.Axis == "X" then s.A.Z else s.A.X
		local b = if self.Axis == "X" then s.B.Z else s.B.X
		if (a - self.At) * (b - self.At) <= 0 and a ~= b then
			local t = (self.At - a) / (b - a)
			local u = if self.Axis == "X" then s.A.X + (s.B.X - s.A.X) * t else s.A.Z + (s.B.Z - s.A.Z) * t
			if u >= self.From - HALF and u <= self.To + HALF then
				table.insert(list, u)
			end
		end
	end
	for _, r in CityPlan.Roundabouts do
		local along = if self.Axis == "X" then r[1] else r[2]
		local across = if self.Axis == "X" then r[2] else r[1]
		if math.abs(across - self.At) < ROUNDABOUT_R and along >= self.From - ROUNDABOUT_R and along <= self.To + ROUNDABOUT_R then
			table.insert(list, along)
		end
	end
	table.sort(list)
	return list
end

-- Intenta alargar el extremo (sign = -1: From, +1: To). Devuelve la nueva coordenada o nil.
local function extend(road: Road, sign: number, roads: { Road }, blocked: { Rect }): number?
	local u0 = if sign < 0 then road.From else road.To
	local d = STEP
	while d <= MAX_EXTEND do
		local u = u0 + sign * d
		local x, z = point(road, u)
		if not free(x, z, blocked) then
			return nil
		end
		if touches(road, x, z, roads) then
			return u + sign * 20 -- se mete en la otra calle: el cruce queda cerrado, sin huecos
		end
		d += STEP
	end
	return nil
end

function Connect.fix(list: { Road }, blocked: { Rect }): { Road }
	-- Copias (algunas calles son tablas compartidas, como Region.Highways)
	local roads: { Road } = {}
	for _, road in list do
		table.insert(roads, table.clone(road))
	end
	for _ = 1, 3 do
		local changed = false
		for _, road in roads do
			if not road.Removed then
				for _, sign in { -1, 1 } do
					local u = if sign < 0 then road.From else road.To
					local x, z = point(road, u)
					if not touches(road, x, z, roads) then
						local target = extend(road, sign, roads, blocked)
						if target then
							if sign < 0 then
								road.From = target
							else
								road.To = target
							end
						else
							-- Recortar hasta el último cruce hacia dentro
							local cuts = crossings(road, roads)
							local best: number? = nil
							for _, c in cuts do
								local inward = if sign < 0 then c > road.From + 1 and c < road.To else c < road.To - 1 and c > road.From
								local closer = not best or (if sign < 0 then c < best else c > best)
								if inward and closer then
									best = c
								end
							end
							if best then
								if sign < 0 then
									road.From = best
								else
									road.To = best
								end
							else
								road.Removed = true
							end
						end
						changed = true
					end
				end
				if road.To - road.From < 30 then
					road.Removed = true
				end
			end
		end
		-- Las quitadas dejan de contar como cruce
		local kept = {}
		for _, road in roads do
			if not road.Removed then
				table.insert(kept, road)
			end
		end
		roads = kept
		if not changed then
			break
		end
	end
	return roads
end

return Connect
