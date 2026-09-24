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
}

-- Centros de las 8 zonas (Valmar Centro está en el origen; las demás vienen del mapa)
local zoneCenters: { { Name: string, Center: Vector3 } } = { { Name = "Valmar Centro", Center = Vector3.zero } }
for _, town in Region.Towns do
	table.insert(zoneCenters, { Name = town.Name, Center = town.Center })
end

local byModelName: { [string]: { Spot } } = {}
local indexed = false

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
		return byModelName[place.Model] or {}
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

-- Devuelve el lugar concreto para este jugador (o nil si ahora mismo no existe en el mapa)
function LocationService.resolve(player: Player, placeId: string): Spot?
	local place = Locations.Places[placeId]
	if not place then
		return nil
	end
	if place.Special == "Home" then
		return homeSpot(player)
	end
	local list = candidates(place)
	if #list == 0 then
		return nil
	end
	local zone = place.Zone or "Nearest"
	if zone ~= "Nearest" and zone ~= "Home" then
		local inZone = {}
		for _, spot in list do
			if spot.Zone == zone then
				table.insert(inZone, spot)
			end
		end
		list = if #inZone > 0 then inZone else list
	end
	local from = playerPosition(player) or Vector3.zero
	if zone == "Home" then
		local home = homeSpot(player)
		from = if home then home.Position else from
	end
	return nearest(list, from)
end

-- ¿Está el jugador en ese lugar?
function LocationService.isAt(player: Player, spot: Spot): boolean
	local position = playerPosition(player)
	if not position then
		return false
	end
	local offset = position - spot.Position
	return Vector3.new(offset.X, 0, offset.Z).Magnitude <= spot.Radius and math.abs(offset.Y) < 60
end

function LocationService.positionOf(player: Player): Vector3?
	return playerPosition(player)
end

function LocationService.init()
	buildIndex()
end

return LocationService
