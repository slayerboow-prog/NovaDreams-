-- Walkable: por dónde pueden ir los animales sueltos (y quien no deba pisar la calzada).
--
-- Con las calles que publica el servidor (ReplicatedStorage.Ambient.Roads: A, B y Width = ancho de
-- la calzada) y las rotondas del plano, dice si un punto cae en la calzada y si un camino recto la
-- cruza. Los perros, gatos, palomas y gallinas eligen sitios que NO estén en la calzada (aceras,
-- parques, plazas, jardines) y no cruzan la calle: se dan la vuelta.
-- Funciones puras (sin Roblox): las prueba scripts/test-animals.luau.

local Walkable = {}

local CELL = 64
local ROUNDABOUT_R = 56 -- borde exterior del anillo de una rotonda (Kit/Roads)

type Seg = { AX: number, AZ: number, BX: number, BZ: number, Half: number }
export type Index = { Cells: { [string]: { Seg } }, Circles: { { number } }, Count: number }

local function key(gx: number, gz: number): string
	return gx .. ":" .. gz
end

-- roads: { { A: Vector3, B: Vector3, Width: number } }; roundabouts: { { x, z } } (CityPlan.Roundabouts)
function Walkable.new(roads: { any }, roundabouts: { { number } }?): Index
	local index: Index = { Cells = {}, Circles = {}, Count = 0 }
	for _, r in roads do
		local a, b = r.A, r.B
		local half = (r.Width or 24) / 2
		local seg: Seg = { AX = a.X, AZ = a.Z, BX = b.X, BZ = b.Z, Half = half }
		local pad = half + 4
		for gx = math.floor((math.min(a.X, b.X) - pad) / CELL), math.floor((math.max(a.X, b.X) + pad) / CELL) do
			for gz = math.floor((math.min(a.Z, b.Z) - pad) / CELL), math.floor((math.max(a.Z, b.Z) + pad) / CELL) do
				local k = key(gx, gz)
				local list = index.Cells[k]
				if not list then
					list = {}
					index.Cells[k] = list
				end
				table.insert(list, seg)
			end
		end
		index.Count += 1
	end
	for _, c in roundabouts or {} do
		table.insert(index.Circles, { c[1], c[2], ROUNDABOUT_R })
	end
	return index
end

-- Lee las calles de ReplicatedStorage.Ambient.Roads (Configurations con A, B y Width)
function Walkable.fromFolder(folder: Instance, roundabouts: { { number } }?): Index
	local roads = {}
	for _, config in folder:GetChildren() do
		local a, b = config:GetAttribute("A"), config:GetAttribute("B")
		if typeof(a) == "Vector3" and typeof(b) == "Vector3" then
			table.insert(roads, { A = a, B = b, Width = config:GetAttribute("Width") or 24 })
		end
	end
	return Walkable.new(roads, roundabouts)
end

local function segDistance(x: number, z: number, s: Seg): number
	local dx, dz = s.BX - s.AX, s.BZ - s.AZ
	local len2 = dx * dx + dz * dz
	local t = if len2 > 0 then math.clamp(((x - s.AX) * dx + (z - s.AZ) * dz) / len2, 0, 1) else 0
	local px, pz = s.AX + t * dx, s.AZ + t * dz
	return math.sqrt((x - px) ^ 2 + (z - pz) ^ 2)
end

-- ¿El punto (x, z) cae en la calzada (con margen: margin > 0 lo aparta también del bordillo)?
function Walkable.onRoad(index: Index?, x: number, z: number, margin: number?): boolean
	if not index then
		return false
	end
	local m = margin or 0
	for _, s in index.Cells[key(math.floor(x / CELL), math.floor(z / CELL))] or {} do
		if segDistance(x, z, s) < s.Half + m then
			return true
		end
	end
	for _, c in index.Circles do
		local dx, dz = x - c[1], z - c[2]
		if dx * dx + dz * dz < (c[3] + m) ^ 2 then
			return true
		end
	end
	return false
end

-- ¿Se puede ir en línea recta de a a b sin pisar la calzada? (se mira cada "step" studs)
function Walkable.pathClear(index: Index?, a: Vector3, b: Vector3, margin: number?, step: number?): boolean
	if not index then
		return true
	end
	local dx, dz = b.X - a.X, b.Z - a.Z
	local len = math.sqrt(dx * dx + dz * dz)
	local n = math.max(1, math.ceil(len / (step or 1.5)))
	for i = 0, n do
		local t = i / n
		if Walkable.onRoad(index, a.X + dx * t, a.Z + dz * t, margin) then
			return false
		end
	end
	return true
end

-- Un sitio para ir andando alrededor de "around" (entre minR y maxR): nunca en la calzada (ni pegado
-- al bordillo), alcanzable desde "from" sin cruzar la calle y, si hay "home", sin alejarse de él más
-- de homeRadius (los animales de granja). rand() da números de 0 a 1. Devuelve x, z o nil.
function Walkable.pick(index: Index?, around: Vector3, minR: number, maxR: number, from: Vector3?, home: Vector3?, homeRadius: number?, rand: (() -> number)?, margin: number?): (number?, number?)
	local r01 = rand or math.random
	local m = margin or 1.5
	local angle = r01() * math.pi * 2
	local r = minR + r01() * (maxR - minR)
	local x, z = around.X + math.cos(angle) * r, around.Z + math.sin(angle) * r
	if Walkable.onRoad(index, x, z, m) then
		return nil, nil
	end
	if from and not Walkable.pathClear(index, from, Vector3.new(x, from.Y, z), m * 0.5) then
		return nil, nil
	end
	if home and math.sqrt((x - home.X) ^ 2 + (z - home.Z) ^ 2) > (homeRadius or 26) then
		return nil, nil
	end
	return x, z
end

-- Hacia dónde huir de "from" sin acabar en la calzada: prueba la dirección contraria y, si no se
-- puede, gira poco a poco a un lado y a otro. Devuelve el punto de llegada o nil.
function Walkable.escape(index: Index?, pos: Vector3, from: Vector3, distance: number, margin: number?): Vector3?
	local away = Vector3.new(pos.X - from.X, 0, pos.Z - from.Z)
	if away.Magnitude < 0.05 then
		away = Vector3.new(1, 0, 0)
	end
	away = away.Unit
	for _, turn in { 0, 0.5, -0.5, 1, -1, 1.5, -1.5, 2.2, -2.2 } do
		local c, s = math.cos(turn), math.sin(turn)
		local dir = Vector3.new(away.X * c - away.Z * s, 0, away.X * s + away.Z * c)
		local target = pos + dir * distance
		if Walkable.pathClear(index, pos, target, margin) then
			return target
		end
	end
	return nil
end

return Walkable
