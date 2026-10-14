-- ReliefBake: hornea el relieve natural de la isla (shared/Relief) a partir de la ciudad YA construida.
-- Lo llama scripts/build-place.luau (y TownBuilder si el servidor tiene que construir la ciudad):
--
--   1. Huellas: cada pieza de workspace.Town marca su caja en planta (menos los árboles, arbustos y
--      piedras sueltas, que se recolocan encima del relieve, y lo que es solo de Studio, bajo tierra o
--      en el cielo). Más las zonas de misión que World/MissionZones monta al arrancar (los montes de
--      la mina y del cráter, el meteorito y los riscos) y los sitios que se ponen a mano.
--   2. Relief.bake: amplitudes en la rejilla (llano junto a todo lo construido, colinas y sierras en
--      lo salvaje, playa y acantilados en la costa).
--   3. Guarda el mapa en un StringValue «ReliefMap» en ServerStorage (TerrainBuilder escribe el terreno
--      con él al arrancar) y en ReplicatedStorage (las siluetas lejanas del cliente, shared/Horizon).
--   4. Recoloca encima del relieve los árboles, arbustos y piedras del campo y del monte que han
--      quedado debajo (solo suben: lo que está en lo llano no se mueve).
--   5. Bosques en las lomas (World/Kit/Forest): pocas piezas por árbol, en grupos que se cargan
--      enteros y de lejos se ven con su versión simplificada (StreamingMesh).
-- Sin azar de math.random (no cambia nada del resto del mapa).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Relief = require(ReplicatedStorage.Shared.Relief)
local CityPlan = require(ReplicatedStorage.Shared.CityPlan)

local ReliefBake = {}

ReliefBake.ValueName = "ReliefMap"
-- Modelos que no cuentan como «construido»: se apoyan en el relieve (se suben si hace falta)
ReliefBake.Movable = { Tree = true, Cypress = true, Palm = true, Bush = true, Arbol = true }
ReliefBake.MovableParts = { Piedra = true, Bush = true }
ReliefBake.SkyY = 160 -- piezas que empiezan más arriba: salas del cielo (interiores), no cuentan
ReliefBake.UndergroundY = -10 -- piezas que acaban más abajo: metro, no cuentan

-- Sitios que se montan al arrancar el servidor (no están en el archivo) y que deben quedar como están
function ReliefBake.runtimeDiscs(): { Relief.Disc }
	local out: { Relief.Disc } = {}
	local ok, MissionZones = pcall(function()
		return require(script.Parent.MissionZones)
	end)
	if ok and MissionZones then
		for _, key in { "Mountain", "Crater" } do
			local m = MissionZones[key]
			if m then
				table.insert(out, { X = m.X, Z = m.Z, R = m.R + 140 })
			end
		end
		local meteor = MissionZones.Meteor
		if meteor then
			table.insert(out, { X = meteor.X, Z = meteor.Z, R = 220 })
		end
		local okSpots, spots = pcall(MissionZones.cliffSpots)
		if okSpots then
			for _, spot in spots do
				table.insert(out, { X = spot.Position.X, Z = spot.Position.Z, R = 60 })
			end
		end
	end
	-- Lugares especiales del plano (puerto, marina, mirador, camping, aeropuerto…)
	for _, p in CityPlan.Places or {} do
		table.insert(out, { X = p[1], Z = p[2], R = 160 })
	end
	-- Pueblos de la historia (cada uno en su cuadrícula de 720 × 720)
	for _, t in CityPlan.Towns or {} do
		table.insert(out, { X = t[1], Z = t[2], R = 500 })
	end
	return out
end

local function movable(part: BasePart): boolean
	if ReliefBake.MovableParts[part.Name] then
		return true
	end
	local model = part:FindFirstAncestorWhichIsA("Model")
	return model ~= nil and ReliefBake.Movable[model.Name] == true
end

-- Caja en planta de una pieza (con su giro)
local function footprint(part: BasePart): (number, number, number, number, number, number)
	local cf, s = part.CFrame, part.Size
	local p = cf.Position
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local hx = math.abs(r.X) * s.X / 2 + math.abs(u.X) * s.Y / 2 + math.abs(l.X) * s.Z / 2
	local hy = math.abs(r.Y) * s.X / 2 + math.abs(u.Y) * s.Y / 2 + math.abs(l.Y) * s.Z / 2
	local hz = math.abs(r.Z) * s.X / 2 + math.abs(u.Z) * s.Y / 2 + math.abs(l.Z) * s.Z / 2
	return p.X - hx, p.X + hx, p.Y - hy, p.Y + hy, p.Z - hz, p.Z + hz
end

-- Huellas de lo construido en la ciudad
function ReliefBake.footprints(town: Instance): ({ Relief.Rect }, number)
	local rects: { Relief.Rect } = {}
	local skipped = 0
	for _, d in town:GetDescendants() do
		if d:IsA("BasePart") then
			local part = d :: BasePart
			if part:HasTag("EditOnly") or movable(part) then
				skipped += 1
			else
				local x0, x1, y0, y1, z0, z1 = footprint(part)
				if y0 > ReliefBake.SkyY or y1 < ReliefBake.UndergroundY then
					skipped += 1
				else
					table.insert(rects, { X0 = x0, X1 = x1, Z0 = z0, Z1 = z1 })
				end
			end
		end
	end
	return rects, skipped
end

-- Dónde está el pie de un árbol / arbusto / piedra (X y Z del tronco si lo tiene)
local function footOf(target: Instance): Vector3?
	if target:IsA("BasePart") then
		return (target :: BasePart).CFrame.Position
	end
	local trunk = target:FindFirstChild("Trunk")
	if trunk and trunk:IsA("BasePart") then
		return trunk.CFrame.Position
	end
	for _, d in target:GetDescendants() do
		if d:IsA("BasePart") then
			return d.CFrame.Position
		end
	end
	return nil
end

-- Sube una pieza o un modelo entero (sin GetPivot/PivotTo: también funciona al construir con Lune).
-- Los atributos Pivot (el punto del que se mecen las copas y las hojas) suben con él.
local function shift(target: Instance, delta: Vector3)
	local list = if target:IsA("BasePart") then { target } else target:GetDescendants()
	for _, d in list do
		if d:IsA("BasePart") then
			local p = d :: BasePart
			p.CFrame = p.CFrame + delta
			local pivot = p:GetAttribute("Pivot")
			if typeof(pivot) == "Vector3" then
				p:SetAttribute("Pivot", pivot + delta)
			elseif typeof(pivot) == "CFrame" then
				p:SetAttribute("Pivot", pivot + delta)
			end
		end
	end
	if target:IsA("Model") then
		pcall(function()
			(target :: any).WorldPivot = (target :: any).WorldPivot + delta
		end)
	end
end

-- Sube a su sitio lo que se apoya en el suelo (árboles, arbustos, piedras) y ha quedado bajo el relieve
function ReliefBake.lift(town: Instance, field: Relief.Field): number
	local moved = 0
	local seen: { [Instance]: boolean } = {}
	for _, d in town:GetDescendants() do
		local target: Instance? = nil
		if d:IsA("Model") and ReliefBake.Movable[d.Name] then
			target = d
		elseif d:IsA("BasePart") and ReliefBake.MovableParts[d.Name] and not (d.Parent and d.Parent:IsA("Model") and ReliefBake.Movable[d.Parent.Name]) then
			target = d
		end
		if target and not seen[target] then
			seen[target] = true
			local pos = footOf(target)
			local rise = if pos then Relief.height(field, pos.X, pos.Z) else 0
			if pos and rise > 0.3 then
				-- Lo que estaba en una montaña de siempre ya está a su altura: solo sube lo que falte
				local dome = Relief.domeY(CityPlan.Mountains, pos.X, pos.Z)
				local ground = Relief.Base + rise
				local current = math.max(Relief.Base, dome)
				local up = ground - current
				if up > 0.3 then
					-- (un poco hundido: en la cuesta no flota por el lado de abajo)
					local slope = Relief.slope(field, pos.X, pos.Z)
					local delta = Vector3.new(0, up - math.min(1.5, slope * 2), 0)
					shift(target, delta)
					moved += 1
				end
			end
		end
	end
	return moved
end

local function store(field: Relief.Field, parent: Instance)
	local old = parent:FindFirstChild(ReliefBake.ValueName)
	if old then
		old:Destroy()
	end
	local value = Instance.new("StringValue")
	value.Name = ReliefBake.ValueName
	value.Value = Relief.encode(field)
	value:SetAttribute("Version", Relief.Version)
	value:SetAttribute("NX", field.NX)
	value:SetAttribute("NZ", field.NZ)
	value:SetAttribute("MinX", field.MinX)
	value:SetAttribute("MinZ", field.MinZ)
	value:SetAttribute("Cell", field.Cell)
	value:SetAttribute("Step", field.Step)
	local built = Instance.new("StringValue")
	built.Name = "Built"
	built.Value = Relief.encodeBuilt(field)
	built.Parent = value
	value.Parent = parent
end

-- Todo el horneado. Devuelve el mapa y las cifras (piezas, celdas, árboles…)
function ReliefBake.run(town: Instance): (Relief.Field, { [string]: number })
	local rects, skipped = ReliefBake.footprints(town)
	local field, stats = Relief.bake(CityPlan, rects, ReliefBake.runtimeDiscs())
	stats.Footprints = #rects
	stats.Skipped = skipped
	stats.Lifted = ReliefBake.lift(town, field)
	local okForest, Forest = pcall(function()
		return require(script.Parent.Kit.Forest)
	end)
	if okForest and Forest then
		local trees, parts = Forest.build(town, field)
		stats.ForestTrees = trees
		stats.ForestParts = parts
	end
	store(field, ServerStorage)
	store(field, ReplicatedStorage)
	-- (las cifras quedan en el mapa guardado: informe de scripts/build-place.luau y pruebas)
	local saved = ServerStorage:FindFirstChild(ReliefBake.ValueName)
	if saved then
		for _, key in { "Raised", "Max", "Footprints", "Lifted", "ForestTrees", "ForestParts" } do
			local v = stats[key]
			if type(v) == "number" then
				saved:SetAttribute(key, math.floor(v + 0.5))
			end
		end
	end
	return field, stats
end

-- El mapa guardado (o nil si el archivo no lo trae)
function ReliefBake.load(): Relief.Field?
	local value = ServerStorage:FindFirstChild(ReliefBake.ValueName) or ReplicatedStorage:FindFirstChild(ReliefBake.ValueName)
	return Relief.fromValue(value)
end

return ReliefBake
