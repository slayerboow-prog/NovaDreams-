-- DataService: carga y guarda los datos de cada jugador (dinero, casa, estadísticas...)
--
-- Detalles importantes para que NUNCA se pierda ni se duplique dinero:
--  * "Session lock": mientras un servidor tiene cargados tus datos, ningún otro
--    servidor puede sobrescribirlos (evita duplicar dinero saltando de servidor).
--  * Autoguardado cada Config.AutosaveSeconds y al salir / cerrar el servidor.
--  * En Roblox Studio, si no has activado "Enable Studio Access to API Services",
--    el juego funciona igual pero sin guardar (te avisa en la consola).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local DataService = {}

local LOCK_TIMEOUT = Config.AutosaveSeconds * 3
local MAX_RECEIPTS = 50

local DEFAULT_DATA = {
	Money = Config.StartingMoney,
	HouseTier = 1,
	Hunger = Config.Needs.Max,
	Energy = Config.Needs.Max,
	Stats = {
		TasksDone = 0,
		MoneyEarned = 0,
		PlaySeconds = 0,
	},
	ProcessedReceipts = {},
}

local profiles: { [Player]: { [string]: any } } = {}
local loadedCallbacks: { (Player, { [string]: any }) -> () } = {}
local savingEnabled = true
local store: DataStore? = nil

local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in value do
		copy[k] = deepCopy(v)
	end
	return copy
end

-- Añade los campos nuevos que falten (para cuando actualices el juego).
local function reconcile(data: { [string]: any }, template: { [string]: any })
	for key, value in template do
		if data[key] == nil then
			data[key] = deepCopy(value)
		elseif type(value) == "table" and type(data[key]) == "table" and next(value) ~= nil then
			reconcile(data[key], value)
		end
	end
end

local function keyFor(player: Player): string
	return "Player_" .. player.UserId
end

do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	else
		savingEnabled = false
		warn("[DataService] DataStore no disponible, los datos NO se guardarán:", result)
	end
end

-- Devuelve la tabla de datos o nil si no se pudo cargar.
local function loadFromStore(player: Player): { [string]: any }?
	if not savingEnabled or not store then
		return deepCopy(DEFAULT_DATA)
	end

	for attempt = 1, 5 do
		local loaded: { [string]: any }? = nil
		local locked = false
		local ok, err = pcall(function()
			(store :: DataStore):UpdateAsync(keyFor(player), function(old)
				local data = if type(old) == "table" then old else deepCopy(DEFAULT_DATA)
				local lock = data.SessionLock
				if lock and lock.JobId ~= game.JobId and os.time() - (lock.Time or 0) < LOCK_TIMEOUT then
					locked = true
					return nil -- no escribir nada, otro servidor tiene los datos
				end
				locked = false
				data.SessionLock = { JobId = game.JobId, Time = os.time() }
				loaded = data
				return data
			end)
		end)

		if ok and loaded then
			return loaded
		end

		if not ok then
			warn(("[DataService] Error cargando %s (intento %d): %s"):format(player.Name, attempt, tostring(err)))
			if RunService:IsStudio() then
				savingEnabled = false
				warn("[DataService] Estás en Studio sin acceso a la API. Activa 'Enable Studio Access to API Services' en Game Settings > Security para probar el guardado.")
				return deepCopy(DEFAULT_DATA)
			end
		elseif locked then
			warn(("[DataService] Datos de %s bloqueados por otro servidor, reintentando..."):format(player.Name))
		end

		if not player.Parent then
			return nil
		end
		task.wait(attempt * 2)
	end
	return nil
end

-- Guarda los datos. release = true suelta el session lock (al salir).
function DataService.save(player: Player, release: boolean?): boolean
	local data = profiles[player]
	if not data then
		return false
	end
	if not savingEnabled or not store then
		return true -- en Studio sin API damos el guardado por bueno
	end

	local ok, err = pcall(function()
		(store :: DataStore):UpdateAsync(keyFor(player), function(old)
			if type(old) == "table" and old.SessionLock and old.SessionLock.JobId ~= game.JobId then
				return nil -- otro servidor se ha quedado los datos: no pisarlos
			end
			local toSave = deepCopy(data)
			toSave.SessionLock = if release then nil else { JobId = game.JobId, Time = os.time() }
			return toSave
		end)
	end)
	if not ok then
		warn(("[DataService] Error guardando %s: %s"):format(player.Name, tostring(err)))
	end
	return ok
end

-- Devuelve los datos del jugador (nil si todavía no han cargado).
function DataService.get(player: Player): { [string]: any }?
	return profiles[player]
end

-- Espera a que carguen los datos (máx. timeout segundos).
function DataService.waitFor(player: Player, timeout: number?): { [string]: any }?
	local deadline = os.clock() + (timeout or 15)
	while not profiles[player] and player.Parent and os.clock() < deadline do
		task.wait(0.1)
	end
	return profiles[player]
end

-- Registra una función que se llama cuando los datos de un jugador están listos.
function DataService.onLoaded(callback: (Player, { [string]: any }) -> ())
	table.insert(loadedCallbacks, callback)
	for player, data in profiles do
		task.spawn(callback, player, data)
	end
end

---------------------------------------------------------------------
-- Dinero
---------------------------------------------------------------------

local function syncMoney(player: Player, data: { [string]: any })
	player:SetAttribute("Money", data.Money)
	local leaderstats = player:FindFirstChild("leaderstats")
	local money = leaderstats and leaderstats:FindFirstChild("Dinero")
	if money then
		(money :: IntValue).Value = data.Money
	end
end

-- Suma (o resta, si amount es negativo) dinero. Devuelve false si no hay datos.
function DataService.addMoney(player: Player, amount: number, isEarning: boolean?): boolean
	local data = profiles[player]
	if not data then
		return false
	end
	data.Money = math.max(0, math.floor(data.Money + amount))
	if isEarning and amount > 0 then
		data.Stats.MoneyEarned += amount
	end
	syncMoney(player, data)
	return true
end

-- Cobra un precio si hay dinero suficiente. Devuelve true si se ha pagado.
function DataService.spend(player: Player, price: number): boolean
	local data = profiles[player]
	if not data or data.Money < price then
		return false
	end
	data.Money -= price
	syncMoney(player, data)
	return true
end

function DataService.hasProcessedReceipt(player: Player, purchaseId: string): boolean
	local data = profiles[player]
	return data ~= nil and table.find(data.ProcessedReceipts, purchaseId) ~= nil
end

function DataService.markReceipt(player: Player, purchaseId: string)
	local data = profiles[player]
	if not data then
		return
	end
	table.insert(data.ProcessedReceipts, purchaseId)
	while #data.ProcessedReceipts > MAX_RECEIPTS do
		table.remove(data.ProcessedReceipts, 1)
	end
end

---------------------------------------------------------------------
-- Ciclo de vida
---------------------------------------------------------------------

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local money = Instance.new("IntValue")
	money.Name = "Dinero"
	money.Parent = leaderstats
	leaderstats.Parent = player

	local data = loadFromStore(player)
	if not player.Parent then
		return -- se fue mientras cargaba
	end
	if not data then
		player:Kick("No hemos podido cargar tus datos. Vuelve a entrar en unos segundos.")
		return
	end

	reconcile(data, DEFAULT_DATA)
	profiles[player] = data
	syncMoney(player, data)

	for _, callback in loadedCallbacks do
		task.spawn(callback, player, data)
	end
end

local function onPlayerRemoving(player: Player)
	if profiles[player] then
		DataService.save(player, true)
		profiles[player] = nil
	end
end

function DataService.init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	-- Autoguardado + contador de tiempo jugado
	task.spawn(function()
		while true do
			task.wait(Config.AutosaveSeconds)
			for player, data in profiles do
				data.Stats.PlaySeconds += Config.AutosaveSeconds
				task.spawn(DataService.save, player)
			end
		end
	end)

	-- Al cerrar el servidor, guardar a todos
	game:BindToClose(function()
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				DataService.save(player, true)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return DataService
