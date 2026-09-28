-- LocationService: encuentra en el mapa los lugares de Locations ("el colegio más cercano a tu casa")
-- y dice en qué zona está cada punto. Solo LEE el mapa: no lo modifica.
-- El mapa se busca una vez al arrancar; si algo se reconstruye, se vuelve a buscar solo.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Locations = require(ReplicatedStorage.Shared.LifeStory.Locations)
local Region = require(script.Parent.Parent.World.Region)

local LocationService = {}

export type Spot = {
	Instance: Instance,
	Position: Vector3, -- centro, a la altura del suelo
	Radius: number, -- distancia (en planta) a la que ya "has llegado"
	Zone: string,
	CFrame: CFrame, -- caja del lugar (para Inside)
	Size: Vector3,
	Inside: boolean?, -- hay que estar DENTRO de la caja (habitaciones)
}

-- Centros de las 8 zonas (Valmar Centro está en el origen; las demás vienen del mapa)
local zoneCenters: { { Name: string, Center: Vector3 } } = { { Name = "Valmar Centro", Center = Vector3.zero } }
for _, town in Region.Towns do
	table.insert(zoneCenters, { Name = town.Name, Center = town.Center })
end

local byModelName: { [string]: { Spot } } = {}
local indexed = false

-- Centro de una zona por su nombre (o nil si no existe)
function LocationService.zoneCenter(name: string): Vector3?
	for _, zone in zoneCenters do
		if zone.Name == name then
			return zone.Center
		end
	end
	return nil
end

function LocationService.zoneAt(position: Vector3): string
	local best, bestDistance = "Valmar Centro", math.huge
	for _, zone in zoneCenters do
		local offset = position - zone.Center
		local distance = Vector3.new(offset.X, 0, offset.Z).Magnitude
		if distance < bestDistance then
			best, bestDistance = zone.Name, distance
		end
	end
	return best
end

local function spotFor(instance: Instance): Spot?
	local cf: CFrame, size: Vector3
	if instance:IsA("Model") then
		cf, size = instance:GetBoundingBox()
	elseif instance:IsA("BasePart") then
		cf, size = instance.CFrame, instance.Size
	else
		return nil
	end
	local ground = cf.Position - Vector3.new(0, size.Y / 2, 0)
	return {
		Instance = instance,
		Position = ground,
		Radius = math.max(size.X, size.Z) / 2 + Config.LifeStory.ReachPadding,
		Zone = LocationService.zoneAt(ground),
		CFrame = cf,
		Size = size,
	}
end

-- Busca una sola vez todos los modelos con los nombres que usa la historia
local function buildIndex()
	local town = workspace:FindFirstChild("Town")
	if not town then
		return
	end
	local wanted: { [string]: boolean } = {}
	for _, place in Locations.Places do
		if place.Model then
			wanted[place.Model] = true
		end
	end
	table.clear(byModelName)
	for _, descendant in town:GetDescendants() do
		if descendant:IsA("Model") and wanted[descendant.Name] then
			local spot = spotFor(descendant)
			if spot then
				byModelName[descendant.Name] = byModelName[descendant.Name] or {}
				table.insert(byModelName[descendant.Name], spot)
			end
		end
	end
	indexed = true
end

local function stillValid(list: { Spot }?): boolean
	return list ~= nil and #list > 0 and list[1].Instance:IsDescendantOf(workspace)
end

local function candidates(place: Locations.Place): { Spot }
	if place.Model then
		if not indexed or (byModelName[place.Model] and not stillValid(byModelName[place.Model])) then
			buildIndex()
		end
		local list = byModelName[place.Model] or {}
		if place.Attribute then
			local filtered = {}
			for _, spot in list do
				local ok = true
				for name, value in place.Attribute do
					if spot.Instance:GetAttribute(name) ~= value then
						ok = false
						break
					end
				end
				if ok then
					table.insert(filtered, spot)
				end
			end
			list = filtered
		end
		return list
	end
	if place.Tag then
		local list = {}
		for _, instance in CollectionService:GetTagged(place.Tag) do
			local ok = true
			for name, value in place.Attribute or {} do
				if instance:GetAttribute(name) ~= value then
					ok = false
					break
				end
			end
			if ok then
				local spot = spotFor(instance)
				if spot then
					table.insert(list, spot)
				end
			end
		end
		return list
	end
	return {}
end

local function homeSpot(player: Player): Spot?
	local plotId = player:GetAttribute("PlotId")
	local town = workspace:FindFirstChild("Town")
	local plot = plotId and town and town:FindFirstChild("Plot_" .. plotId, true)
	return if plot then spotFor(plot) else nil
end

local function familyHomeSpot(player: Player): Spot?
	local homeId = player:GetAttribute("FamilyHomeId")
	if not homeId then
		return nil
	end
	for _, model in CollectionService:GetTagged("FamilyHome") do
		if model:GetAttribute("HomeId") == homeId then
			return spotFor(model)
		end
	end
	return nil
end

local function playerPosition(player: Player): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root and root.Position
end

local function nearest(list: { Spot }, to: Vector3): Spot?
	local best, bestDistance = nil, math.huge
	for _, spot in list do
		local distance = (spot.Position - to).Magnitude
		if distance < bestDistance then
			best, bestDistance = spot, distance
		end
	end
	return best
end

-- La acera más cercana a un punto (las calles las publica el mapa en ReplicatedStorage.Ambient.Roads)
local SIDEWALK = 13 -- distancia del centro de la calzada a la acera
local function snapToSidewalk(point: Vector3): Vector3
	local ambient = ReplicatedStorage:FindFirstChild("Ambient")
	local roads = ambient and ambient:FindFirstChild("Roads")
	if not roads then
		return point
	end
	local best, bestDistance = point, math.huge
	for _, road in roads:GetChildren() do
		-- Cada calle es un tramo A-B en cualquier ángulo
		local a, b = road:GetAttribute("A"), road:GetAttribute("B")
		if typeof(a) == "Vector3" and typeof(b) == "Vector3" and (b - a).Magnitude > 1 then
			local flat = Vector3.new(point.X, 0, point.Z)
			local dir = (b - a).Unit
			local t = math.clamp((flat - a):Dot(dir), 0, (b - a).Magnitude)
			local onRoad = a + dir * t
			local perp = Vector3.new(-dir.Z, 0, dir.X)
			local side = if (flat - onRoad):Dot(perp) >= 0 then 1 else -1
			local width = road:GetAttribute("Width") or 24
			local offset = if width == 24 then SIDEWALK else width / 2 + 3.5
			local p = onRoad + perp * side * offset
			local candidate = Vector3.new(p.X, point.Y, p.Z)
			local distance = (candidate - point).Magnitude
			if distance < bestDistance then
				best, bestDistance = candidate, distance
			end
		end
	end
	return best
end

local function pointSpot(instance: Instance, position: Vector3, rotation: CFrame?, radius: number?): Spot
	return {
		Instance = instance,
		Position = position,
		Radius = radius or 8,
		Zone = LocationService.zoneAt(position),
		CFrame = CFrame.new(position) * (rotation or CFrame.identity),
		Size = Vector3.new(4, 4, 4),
	}
end

export type ResolveOptions = { Index: number?, Offset: Vector3? }

local resolveDepth = 0

-- Devuelve el lugar concreto para este jugador (o nil si ahora mismo no existe en el mapa).
-- options.Index = el n-ésimo del mismo edificio (pupitres); options.Offset = desplazamiento local extra.
function LocationService.resolve(player: Player, placeId: string, options: ResolveOptions?): Spot?
	local place = Locations.Places[placeId]
	if not place or resolveDepth > 4 then
		return nil
	end
	resolveDepth += 1
	local ok, spot = pcall(function()
		return LocationService._resolve(player, place, options)
	end)
	resolveDepth -= 1
	if not ok then
		warn("[LocationService] " .. tostring(spot))
		spot = nil
	end
	if not spot and place.Fallback then
		return LocationService.resolve(player, place.Fallback, options)
	end
	return spot
end

function LocationService._resolve(player: Player, place: Locations.Place, options: ResolveOptions?): Spot?
	local spot: Spot? = nil
	if place.Special == "Home" then
		spot = homeSpot(player)
	elseif place.Special == "NearPlayer" then
		-- Delante del jugador (para personajes que vienen a buscarte)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
			look = if look.Magnitude > 0.1 then look.Unit else Vector3.new(0, 0, -1)
			local ground = root.Position - Vector3.new(0, 3, 0) + look * 9
			spot = pointSpot(root, ground, CFrame.lookAt(Vector3.zero, -look), 10)
		end
	elseif place.Between then
		-- Un punto del camino entre dos lugares, en la acera
		local a = LocationService.resolve(player, place.Between[1])
		local b = LocationService.resolve(player, place.Between[2])
		if a and b then
			local point = a.Position:Lerp(b.Position, place.At or 0.5)
			point = snapToSidewalk(point)
			local direction = Vector3.new(b.Position.X - a.Position.X, 0, b.Position.Z - a.Position.Z)
			local rotation = if direction.Magnitude > 1 then CFrame.lookAt(Vector3.zero, direction) else nil
			spot = pointSpot(b.Instance, Vector3.new(point.X, math.min(a.Position.Y, b.Position.Y), point.Z), rotation, place.Radius or 16)
		end
	else
		local list = candidates(place)
		if #list == 0 then
			return nil
		end
		local zone = place.Zone or "Nearest"
		if zone == "FamilyHome" then
			-- Solo los de la casa familiar donde vive el jugador (la asigna BabyService)
			local homeId = player:GetAttribute("FamilyHomeId")
			local mine = {}
			for _, candidate in list do
				if homeId ~= nil and candidate.Instance:GetAttribute("HomeId") == homeId then
					table.insert(mine, candidate)
				end
			end
			list = mine
			if #list == 0 then
				return nil
			end
		elseif zone ~= "Nearest" and zone ~= "Home" then
			local inZone = {}
			for _, candidate in list do
				if candidate.Zone == zone then
					table.insert(inZone, candidate)
				end
			end
			list = if #inZone > 0 then inZone else list
		end
		local from = playerPosition(player) or Vector3.zero
		if zone == "Home" then
			-- Su casa; si aún no tiene (niños), la casa familiar donde vive
			local home = homeSpot(player) or familyHomeSpot(player)
			from = if home then home.Position else from
		end
		spot = nearest(list, from)
		local index = (options and options.Index) or place.Index
		if spot and index then
			-- El n-ésimo del mismo edificio (siempre el mismo orden: por posición)
			local group = {}
			for _, candidate in list do
				if candidate.Instance.Parent == spot.Instance.Parent then
					table.insert(group, candidate)
				end
			end
			-- En los ejes del edificio (no del mundo): 1-4 = primera fila, aunque la calle esté girada
			local basis = spot.CFrame.Rotation
			table.sort(group, function(x, y)
				local px, py = basis:PointToObjectSpace(x.Position), basis:PointToObjectSpace(y.Position)
				if math.abs(px.X - py.X) > 0.5 then
					return px.X < py.X
				end
				return px.Z < py.Z
			end)
			spot = group[(index - 1) % #group + 1]
		end
		if spot and place.Child then
			-- Una pieza con ese nombre dentro del edificio (la cancha del colegio, el estanque del parque…)
			local child = spot.Instance:FindFirstChild(place.Child, true)
			spot = if child then spotFor(child) else nil
		end
		if spot and place.Inside then
			-- Copia: el mismo lugar puede servir a la vez para "estar cerca" y "estar dentro"
			spot = table.clone(spot)
			spot.Inside = true
		end
	end
	local offset = place.Offset
	if options and options.Offset then
		offset = (offset or Vector3.zero) + options.Offset
	end
	if spot and offset then
		local rotation = spot.CFrame.Rotation
		local position = spot.Position + rotation:VectorToWorldSpace(offset)
		spot = pointSpot(spot.Instance, position, rotation, place.Radius)
	elseif spot and place.Radius then
		spot = table.clone(spot)
		spot.Radius = place.Radius
	end
	return spot
end

-- ¿Está el jugador en ese lugar?
function LocationService.isAt(player: Player, spot: Spot): boolean
	local position = playerPosition(player)
	if not position then
		return false
	end
	if spot.Inside then
		local rel = spot.CFrame:PointToObjectSpace(position)
		local half = spot.Size / 2
		return math.abs(rel.X) <= half.X and math.abs(rel.Z) <= half.Z and math.abs(rel.Y) <= half.Y + 3
	end
	local offset = position - spot.Position
	return Vector3.new(offset.X, 0, offset.Z).Magnitude <= spot.Radius and math.abs(offset.Y) < 60
end

function LocationService.positionOf(player: Player): Vector3?
	return playerPosition(player)
end

-- Publica las zonas para el mapa del cliente: ReplicatedStorage.MapZones (una Configuration por zona)
local function publishZones()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local old = ReplicatedStorage:FindFirstChild("MapZones")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "MapZones"
	for i, zone in zoneCenters do
		local config = Instance.new("Configuration")
		config.Name = "Zone" .. i
		config:SetAttribute("ZoneName", zone.Name)
		config:SetAttribute("Center", zone.Center)
		config.Parent = folder
	end
	folder.Parent = ReplicatedStorage
end

function LocationService.init()
	buildIndex()
	publishZones()
end

return LocationService
