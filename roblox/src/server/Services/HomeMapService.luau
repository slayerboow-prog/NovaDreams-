-- HomeMapService: lo que los mapas necesitan saber de tus casas y tus filtros (Controllers/MapUI).
--
--   * 🏠 Casa: la casa familiar la pone BabyService (atributo FamilyHomePos). Aquí se calcula la TUYA,
--     la misma a la que te lleva «Ir a casa» si ya tienes edad (AdultoJoven en adelante): la vivienda
--     que elegiste o compraste (también la que te tocó al llegar), si no tu habitación de la residencia
--     y si no la parcela de HouseService. Atributos OwnHomePos (Vector3) y OwnHomeTitle.
--     Si te mudas, cambia sola (se repasa cada pocos segundos y al cambiar tus viviendas o tu etapa).
--   * Filtros de la leyenda (shared/MapLegend): las categorías que ocultas se guardan con la partida
--     (data.MapHidden, «Id,Id») y vuelven en el atributo MapHidden. Remoto MapFilters (texto).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MapLegend = require(ReplicatedStorage.Shared.MapLegend)
local Properties = require(ReplicatedStorage.Shared.Properties)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local DataService = require(script.Parent.DataService)

local HomeMapService = {}

HomeMapService.Refresh = 4 -- segundos entre repasos

-- ¿Tiene edad para tener casa propia? (la misma regla que «Ir a casa»)
local function grownUp(player: Player): boolean
	local stage = player:GetAttribute("LifeStage")
	return type(stage) == "string" and Stages.isValid(stage) and Stages.inRange(stage, Properties.MinStage, nil)
end

-- Dónde está tu casa propia (o nil) y cómo se llama
function HomeMapService.ownHome(player: Player): (Vector3?, string?)
	if not grownUp(player) then
		return nil, nil
	end
	local okInterior, InteriorService = pcall(require, script.Parent.InteriorService)
	local data = DataService.get(player)
	-- 1) Vivienda (comprada, alquilada o la que te tocó): la elegida como casa o la primera
	local list = data and data.Properties
	if okInterior and type(list) == "table" and #list > 0 then
		local chosen = data.Housing and data.Housing.Home
		local home = list[1]
		for _, entry in list do
			if type(chosen) == "table" and entry.Key == chosen.Key and entry.Floor == chosen.Floor and (entry.Letter or "A") == (chosen.Letter or "A") then
				home = entry
			end
		end
		local building = type(home) == "table" and type(home.Key) == "string" and InteriorService.byKey(home.Key)
		if building and typeof(building.Door) == "Vector3" then
			return building.Door, home.Title or building.Title
		end
	end
	-- 2) Tu habitación de la residencia
	local dorm = player:GetAttribute("DormUnit")
	if okInterior and type(dorm) == "string" then
		local key = string.match(dorm, "^(.+)#%w+$")
		local building = key and InteriorService.byKey(key)
		if building and typeof(building.Door) == "Vector3" then
			return building.Door, player:GetAttribute("DormTitle") or "Residencia"
		end
	end
	-- 3) La parcela que reclamaste en este servidor
	local plotId = player:GetAttribute("PlotId")
	if plotId ~= nil then
		for _, plot in CollectionService:GetTagged("Plot") do
			local origin = plot:GetAttribute("Origin")
			if plot:GetAttribute("PlotId") == plotId and typeof(origin) == "CFrame" then
				return origin.Position, "Tu parcela"
			end
		end
	end
	return nil, nil
end

function HomeMapService.refresh(player: Player)
	if not player.Parent then
		return
	end
	local ok, position, title = pcall(HomeMapService.ownHome, player)
	if not ok then
		return
	end
	if player:GetAttribute("OwnHomePos") ~= position then
		player:SetAttribute("OwnHomePos", position)
	end
	if player:GetAttribute("OwnHomeTitle") ~= title then
		player:SetAttribute("OwnHomeTitle", title)
	end
end

-- Filtros de la leyenda: se limpian (solo categorías que existen) y se guardan
function HomeMapService.setFilters(player: Player, text: any)
	if type(text) ~= "string" or #text > 600 then
		return
	end
	local encoded = MapLegend.encode(MapLegend.decode(text))
	local data = DataService.get(player)
	if data then
		data.MapHidden = encoded
	end
	player:SetAttribute("MapHidden", encoded)
end

function HomeMapService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local remote = remotes:FindFirstChild("MapFilters") :: RemoteEvent?
	if not remote then
		local created = Instance.new("RemoteEvent")
		created.Name = "MapFilters"
		created.Parent = remotes
		remote = created
	end
	(remote :: RemoteEvent).OnServerEvent:Connect(HomeMapService.setFilters)

	DataService.onLoaded(function(player, data)
		player:SetAttribute("MapHidden", MapLegend.encode(MapLegend.decode(data.MapHidden)))
		task.defer(HomeMapService.refresh, player)
	end)
	local function watch(player: Player)
		for _, name in { "LifeStage", "Homes", "Properties", "DormUnit", "PlotId" } do
			player:GetAttributeChangedSignal(name):Connect(function()
				task.defer(HomeMapService.refresh, player)
			end)
		end
		player.CharacterAdded:Connect(function()
			task.defer(HomeMapService.refresh, player)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	task.spawn(function()
		while true do
			task.wait(HomeMapService.Refresh)
			for _, player in Players:GetPlayers() do
				HomeMapService.refresh(player)
			end
		end
	end)
end

return HomeMapService
