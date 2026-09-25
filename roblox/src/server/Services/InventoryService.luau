-- InventoryService: la mochila del jugador (inventario al estilo Minecraft).
--   * 36 casillas: 1-9 son la barra rápida y 10-36 la mochila. El orden lo elige el jugador y se guarda.
--   * Reúne comida y objetos de las tiendas, vehículos, premios, carnets y títulos (Items.luau).
--   * El cliente solo pide: mover una casilla, usar (comer) o tirar uno. El servidor lo valida todo.
--   * Los vehículos y la ropa se usan con sus propios sistemas (VehicleService, ArcadeService);
--     aquí solo se muestran en su casilla.
--
-- Datos guardados: data.Items = { Pan = 3 }, data.Slots = { ["1"] = "Pan", ["2"] = "Vehiculo_Bici" }
-- Para el cliente: atributo "Inventory" (JSON con las 36 casillas).

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Items = require(ReplicatedStorage.Shared.Items)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)

local InventoryService = {}

local Remote: RemoteEvent
local Notify = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify") :: RemoteEvent
local lastRequest: { [Player]: number } = {}

-- Otros sistemas cambian lo que tienes: al cambiar estos atributos se recoloca la mochila
local WATCHED = { "OwnedVehicles", "Prizes", "Licenses" }

-- Pone cada objeto que tienes en una casilla (los nuevos, en el primer hueco: primero la barra rápida)
-- y quita de las casillas lo que ya no tienes.
local function layout(data: { [string]: any }): { [string]: number }
	local owned = Items.owned(data)
	data.Slots = data.Slots or {}
	local placed = {}
	for i = 1, Items.Slots do
		local key = tostring(i)
		local id = data.Slots[key]
		if id and (not owned[id] or placed[id]) then
			data.Slots[key] = nil
		elseif id then
			placed[id] = true
		end
	end
	-- Orden fijo para los nuevos (por nombre), así no bailan entre servidores
	local missing = {}
	for id in owned do
		if not placed[id] then
			table.insert(missing, id)
		end
	end
	table.sort(missing)
	for _, id in missing do
		for i = 1, Items.Slots do
			if not data.Slots[tostring(i)] then
				data.Slots[tostring(i)] = id
				break
			end
		end
	end
	return owned
end

local function sync(player: Player)
	local data = DataService.get(player)
	if not data then
		return
	end
	local owned = layout(data)
	local slots = table.create(Items.Slots, 0)
	for i = 1, Items.Slots do
		local id = data.Slots[tostring(i)]
		if id then
			slots[i] = { i = id, n = owned[id] }
		end
	end
	local encoded = HttpService:JSONEncode(slots)
	if player:GetAttribute("Inventory") ~= encoded then
		player:SetAttribute("Inventory", encoded)
	end
end

---------------------------------------------------------------------
-- API para otros servicios
---------------------------------------------------------------------

function InventoryService.count(player: Player, id: string): number
	local data = DataService.get(player)
	return data and data.Items and data.Items[id] or 0
end

-- ¿Cabe uno más? (cada objeto ocupa una casilla con su máximo, y hacen falta huecos para los nuevos)
function InventoryService.canAdd(player: Player, id: string, count: number?): boolean
	local item = Items.get(id)
	local data = DataService.get(player)
	if not item or not data then
		return false
	end
	local have = data.Items and data.Items[id] or 0
	if have + (count or 1) > item.Stack then
		return false
	end
	if have > 0 then
		return true
	end
	local used = 0
	for _ in data.Slots or {} do
		used += 1
	end
	return used < Items.Slots
end

function InventoryService.add(player: Player, id: string, count: number?): boolean
	if not InventoryService.canAdd(player, id, count) then
		return false
	end
	local data = DataService.get(player) :: { [string]: any }
	data.Items = data.Items or {}
	data.Items[id] = (data.Items[id] or 0) + (count or 1)
	sync(player)
	return true
end

function InventoryService.remove(player: Player, id: string, count: number?): boolean
	local data = DataService.get(player)
	local have = data and data.Items and data.Items[id] or 0
	if have < (count or 1) then
		return false
	end
	local left = have - (count or 1)
	data.Items[id] = if left > 0 then left else nil
	sync(player)
	return true
end

-- Para cuando otro sistema cambia algo sin atributo (p. ej. un título nuevo)
function InventoryService.refresh(player: Player)
	sync(player)
end

---------------------------------------------------------------------
-- Peticiones del cliente
---------------------------------------------------------------------

local function slotId(data: { [string]: any }, slot: any): string?
	if typeof(slot) ~= "number" or slot ~= slot then
		return nil
	end
	slot = math.floor(slot)
	if slot < 1 or slot > Items.Slots or not data.Slots then
		return nil
	end
	return data.Slots[tostring(slot)]
end

local function use(player: Player, data: { [string]: any }, slot: any)
	local id = slotId(data, slot)
	local item = Items.get(id)
	if not item or item.Kind ~= "Food" or (data.Items and data.Items[item.Id] or 0) <= 0 then
		return
	end
	-- Como en Minecraft: si no tienes hambre, no te lo comes (salvo que dé energía)
	if (item.Hunger or 0) > 0 and (item.Energy or 0) <= 0 and data.Hunger >= Config.Needs.Max - 1 then
		Notify:FireClient(player, "Info", "Ahora no tienes hambre.")
		return
	end
	InventoryService.remove(player, item.Id, 1)
	NeedsService.change(player, item.Hunger or 0, item.Energy or 0)
	Notify:FireClient(player, "Success", ("%s  %s"):format(item.Icon, item.Name))
end

local function drop(player: Player, data: { [string]: any }, slot: any)
	local item = Items.get(slotId(data, slot))
	if item and (item.Kind == "Food" or item.Kind == "Thing") then
		InventoryService.remove(player, item.Id, 1)
	end
end

local function move(player: Player, data: { [string]: any }, from: any, to: any)
	if typeof(from) ~= "number" or typeof(to) ~= "number" then
		return
	end
	from, to = math.floor(from), math.floor(to)
	if from == to or from < 1 or to < 1 or from > Items.Slots or to > Items.Slots then
		return
	end
	layout(data)
	local a, b = tostring(from), tostring(to)
	data.Slots[a], data.Slots[b] = data.Slots[b], data.Slots[a]
	sync(player)
end

function InventoryService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:FindFirstChild("Inventory") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "Inventory"
		Remote.Parent = remotes
	end
	Remote.OnServerEvent:Connect(function(player, action, a, b)
		local now = os.clock()
		if now - (lastRequest[player] or 0) < 0.08 then
			return
		end
		lastRequest[player] = now
		local data = DataService.get(player)
		if not data then
			return
		end
		if action == "Move" then
			move(player, data, a, b)
		elseif action == "Use" then
			use(player, data, a)
		elseif action == "Drop" then
			drop(player, data, a)
		end
	end)

	DataService.onLoaded(function(player)
		for _, attribute in WATCHED do
			player:GetAttributeChangedSignal(attribute):Connect(function()
				sync(player)
			end)
		end
		sync(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)

	-- Red de seguridad: títulos y otras cosas que llegan sin atributo
	task.spawn(function()
		while true do
			task.wait(5)
			for _, player in Players:GetPlayers() do
				sync(player)
			end
		end
	end)
end

return InventoryService
