-- ResidenceService: la residencia universitaria del Campus Valmar.
--
--   * Algunos bloques del campus son residencias (InteriorService.residences): cada planta tiene
--     un pasillo con habitaciones, casi todas compartidas (dos camas y un compañero de cuarto) y
--     algunas individuales.
--   * Al llegar a la etapa de la universidad (AdultoJoven) te dan una habitación: con suerte (una
--     vez de cada cuatro) individual; si no, compartida. Siempre la misma para el mismo jugador.
--     Atributos: DormUnit ("clave del edificio#habitación") y DormTitle.
--   * Tu habitación tiene su nevera (FridgeService): allí guardas lo que compras en el supermercado.
--   * "Ir a casa" te lleva a tu habitación si no tienes otra vivienda.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Floors = require(ReplicatedStorage.Shared.Floors)
local InteriorService = require(script.Parent.InteriorService)

local ResidenceService = {}

ResidenceService.Stages = { AdultoJoven = true } -- etapa de la universidad
ResidenceService.SingleChance = 4 -- una de cada cuatro, individual

type Room = { Building: InteriorService.Building, Floor: number, Letter: string, Id: string, Label: string, Single: boolean }

local function rooms(): ({ Room }, { Room })
	local singles, shared = {}, {}
	for _, building in InteriorService.residences() do
		for floor = 1, building.Floors - 1 do
			for _, unit in Floors.units(building.Key, building.Kind, building.Upper, floor) do
				local single = Floors.dormSingle(building.Key, unit.Id)
				local room = { Building = building, Floor = floor, Letter = unit.Letter, Id = unit.Id, Label = unit.Label, Single = single }
				table.insert(if single then singles else shared, room)
			end
		end
	end
	return singles, shared
end

-- La habitación de un jugador (siempre la misma: sale de su UserId)
function ResidenceService.roomFor(userId: number): Room?
	local singles, shared = rooms()
	local lucky = Floors.hash("suerte:" .. userId) % ResidenceService.SingleChance == 0
	local list = if lucky and #singles > 0 then singles elseif #shared > 0 then shared else singles
	if #list == 0 then
		return nil
	end
	return list[Floors.hash("habitacion:" .. userId) % #list + 1]
end

function ResidenceService.assign(player: Player)
	local stage = player:GetAttribute("LifeStage")
	if type(stage) ~= "string" or not ResidenceService.Stages[stage] then
		player:SetAttribute("DormUnit", nil)
		player:SetAttribute("DormTitle", nil)
		return
	end
	local room = ResidenceService.roomFor(player.UserId)
	if not room then
		return
	end
	local key = room.Building.Key .. "#" .. room.Id
	if player:GetAttribute("DormUnit") == key then
		return
	end
	player:SetAttribute("DormUnit", key)
	player:SetAttribute("DormTitle", ("Residencia · %s (%s)"):format(room.Label, if room.Single then "individual" else "compartida"))
	local Notify = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify") :: RemoteEvent
	Notify:FireClient(player, "Success", if room.Single
		then ("🛏 ¡Qué suerte! En la residencia te toca la %s, para ti solo."):format(room.Label)
		else ("🛏 En la residencia te toca la %s, compartida con un compañero."):format(room.Label))
end

-- "Ir a casa" a la habitación de la residencia (false si no tienes)
function ResidenceService.goHome(player: Player): boolean
	local key = player:GetAttribute("DormUnit")
	if type(key) ~= "string" then
		return false
	end
	local buildingKey, unitId = string.match(key, "^(.+)#(%w+)$")
	local building = buildingKey and InteriorService.byKey(buildingKey)
	local floor, letter = Floors.parseUnit(unitId or "")
	if not building or not floor then
		return false
	end
	InteriorService.goToUnit(player, building, floor, letter)
	return true
end

function ResidenceService.init()
	local function watch(player: Player)
		player:GetAttributeChangedSignal("LifeStage"):Connect(function()
			ResidenceService.assign(player)
		end)
		task.defer(ResidenceService.assign, player)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
end

return ResidenceService
