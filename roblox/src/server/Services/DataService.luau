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
	OwnAvatar = false, -- true = usa su avatar de Roblox en vez del aspecto de Valmar (AvatarService)
	Hunger = Config.Needs.Max,
	Energy = Config.Needs.Max,
	Stats = {
		TasksDone = 0,
		MoneyEarned = 0,
		PlaySeconds = 0,
	},
	ProcessedReceipts = {},
	-- Etapa de vida (la edad real llegará con el sistema de vida)
	-- (Stage no va en la plantilla: LifeStoryService decide si un personaje nuevo nace bebé)
	Life = {
		AgeYears = Config.LifeStory.DefaultAge,
		StageSeconds = 0, -- tiempo jugado en la etapa actual
	},
	-- Mochila (InventoryService): objetos que se cuentan y en qué casilla va cada cosa
	Items = {},
	Slots = {},
	-- Neveras (FridgeService): lo guardado en cada una, por su clave ("casa:…", "residencia:…")
	Fridges = {},
	-- Pesca (FishingService): experiencia (el nivel sale de aquí) y cuántos has pescado de cada pez
	Fishing = {
		Xp = 0,
		Caught = {},
	},
	-- Campo (FarmService): experiencia, si tienes finca, lo plantado en cada bancal y tus animales
	Farm = {
		Xp = 0,
		Plots = {},
		Animals = {},
	},
	-- Gimnasio (GymService): Fuerza y Forma física (0..100), entrada o abono (PassUntil: hora real a
	-- la que caduca), series hechas y último entreno (para la pérdida suave si no entrenas)
	Gym = {
		Strength = 0,
		Cardio = 0,
		Sets = 0,
		PassUntil = 0,
		PassKind = "",
		LastTrain = 0,
		DecayApplied = 0,
	},
	-- Metro (MetroService): abono en vigor (PassKind) y hora real a la que caduca (PassUntil)
	Metro = {
		PassKind = "",
		PassUntil = 0,
	},
	-- Estudios: notas por asignatura, exámenes, títulos y asistencia (ClassService)
	Education = {
		Subjects = {},
		Exams = {},
		Degrees = {},
		Attendance = 0,
	},
	-- Historial de comportamiento (ConductService): puntos, lo que hiciste, castigo y paga
	Conduct = {
		Points = 0,
		Log = {},
	},
	-- Historia de vida (LifeStoryService): capítulos, misiones, decisiones, memoria de NPC y biografía
	Story = {
		Version = 1,
		Chapters = {},
		Active = {},
		Completed = {},
		Declined = {},
		Choices = {},
		Flags = {},
		Discovered = {},
		NpcMemory = {},
		Events = {},
		Counters = {}, -- cuántos días de cole, de instituto… se han vivido
		Traits = {}, -- rasgos del jugador (humor, empatía…) que suben con sus respuestas
		Memories = {}, -- grandes recuerdos (primer día de cole, primer amigo…)
		Later = {}, -- consecuencias diferidas: lo que pasará dentro de X horas de juego
		Clock = 0, -- segundos jugados con la historia (reloj de las consecuencias)
		PrologueDone = false, -- el prólogo («El sueño») ya se vio: os.time() al terminarlo o saltarlo
		PrologueResult = "", -- cómo acabó: "Done", "Skipped", "Error", "Timeout", "Left", "Veteran"…
		LastSeen = 0, -- última vez que se le vio jugando (os.time): para «Anteriormente en tu vida…»
		RecapAt = 0, -- cuándo se enseñó el último resumen
	},
	-- Primeros pasos (OnboardingService): el tutorial guiado ("" = sin decidir, "Pendiente", "Hecho",
	-- "Saltado" o "Veterano"), los pasos ya hechos y los consejos de la primera vez ya vistos
	Onboarding = {
		Tutorial = "",
		Steps = {},
		Tips = {},
	},
	-- Viviendas (HousingService): ya le tocó su piso al llegar, cuál es "su casa" para «Ir a casa»
	-- ({ Key, Floor, Letter }) y la deuda que le quedó de un alquiler perdido
	Housing = {
		Assigned = false,
		Debt = 0,
	},
	-- Barcos propios (BoatService): { Lancha = true, Gaviota = true }. Se sacan en el puerto deportivo.
	-- (Los del pase vuelven solos desde Cosmetics después de «Vida nueva»; los comprados, no.)
	Boats = {},
	-- Pase de temporada (BattlePassService): temporada, XP total (el nivel sale de aquí), si compró el
	-- premium de esta temporada, recompensas reclamadas por nivel (["5"] = true), misiones y topes del
	-- día. Al cambiar de temporada se archiva en SeasonArchive y empieza de cero.
	BattlePass = {
		Version = 1,
		SeasonId = "",
		TotalXp = 0,
		Level = 1,
		PremiumOwned = false,
		ClaimedFree = {},
		ClaimedPremium = {},
		Missions = {},
		Daily = {},
		Zones = {},
		Shop = {},
	},
	-- Lo conseguido con el pase (de todas las temporadas: nunca se borra), lo equipado y las fichas
	Cosmetics = {
		Owned = {},
		Equipped = {},
		Perks = {},
		Tokens = 0,
	},
	-- Resumen de cada temporada ya terminada (por SeasonId)
	SeasonArchive = {},
}

local profiles: { [Player]: { [string]: any } } = {}
local released: { [Player]: boolean } = {} -- ya se ha ido: los autoguardados pendientes no escriben
-- Guardado de salida en marcha, por UserId: si vuelve a entrar en ESTE servidor antes de que acabe,
-- el bloqueo es nuestro y cargaría los datos viejos; hay que esperar a que termine de escribirse
local pendingRelease: { [number]: number } = {} -- (cuántos guardados de salida hay en marcha)
local PENDING_RELEASE_WAIT = 30 -- (segundos máx.: los reintentos de salida tardan como mucho ~15 s)
local lastPlayCredit: { [Player]: number } = {} -- última vez (os.clock) que se le sumó tiempo jugado
local offline: { [Player]: number } = {} -- segundos que estuvo fuera del juego antes de esta sesión
local loadedCallbacks: { (Player, { [string]: any }) -> () } = {}
local beforeSaveCallbacks: { (Player, { [string]: any }) -> () } = {}
local earningCallbacks: { (Player, number) -> () } = {}
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
-- También arregla los de tipo equivocado de partidas viejas (un número guardado como texto, una
-- tabla que era un número…): si no, el primer "x += 1" rompería el servicio de ese jugador.
-- (Las tablas-mapa vacías de la plantilla solo se comprueban por fuera: su contenido es libre. Los
-- booleanos no se tocan: algunos guardan a propósito otra cosa, p. ej. PrologueDone = os.time().)
local function reconcile(data: { [string]: any }, template: { [string]: any })
	for key, value in template do
		local current = data[key]
		local kind = type(value)
		if current == nil then
			data[key] = deepCopy(value)
		elseif kind == "boolean" or type(current) == kind then
			if kind == "table" and next(value) ~= nil then
				reconcile(current, value)
			end
		elseif kind == "number" and tonumber(current) then
			data[key] = tonumber(current) -- ("50" guardado como texto: se conserva el número)
		else
			data[key] = deepCopy(value)
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

	-- Si se fue hace nada de este mismo servidor, esperar a que su guardado de salida acabe
	local waitUntil = os.clock() + PENDING_RELEASE_WAIT
	while pendingRelease[player.UserId] and player.Parent and os.clock() < waitUntil do
		task.wait(0.2)
	end
	if pendingRelease[player.UserId] then
		return nil -- sigue guardándose: mejor pedirle que reentre que cargar datos viejos
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

-- Cantidad de dinero válida (ni NaN, ni infinita, ni negativa): lo que llega de un remoto puede ser cualquier cosa
local function validAmount(x: any): boolean
	return type(x) == "number" and x == x and x >= 0 and x < 1e12
end
DataService.validAmount = validAmount

-- Guarda los datos. release = true suelta el session lock (al salir).
-- Devuelve true solo si de verdad se ha escrito.
function DataService.save(player: Player, release: boolean?): boolean
	local data = profiles[player]
	if not data then
		return false
	end
	-- Última vez que se le vio jugando: al volver, lo que caduca con la hora real (cárcel, abonos,
	-- alquiler…) se corre este tiempo para que no pase estando desconectado (offlineSeconds)
	data.LastOnline = os.time()
	for _, callback in beforeSaveCallbacks do
		local ok, err = pcall(callback, player, data)
		if not ok then
			warn("[DataService] Error antes de guardar:", err)
		end
	end
	if not savingEnabled or not store then
		return true -- en Studio sin API damos el guardado por bueno
	end

	local wrote = false
	local ok, err = pcall(function()
		(store :: DataStore):UpdateAsync(keyFor(player), function(old)
			wrote = false
			if type(old) == "table" and old.SessionLock and old.SessionLock.JobId ~= game.JobId then
				return nil -- otro servidor se ha quedado los datos: no pisarlos
			end
			-- Un autoguardado que acaba después de que el jugador se haya ido no vuelve a bloquear sus datos
			if not release and (not player.Parent or released[player]) then
				return nil
			end
			local toSave = deepCopy(data)
			toSave.SessionLock = if release then nil else { JobId = game.JobId, Time = os.time() }
			wrote = true
			return toSave
		end)
	end)
	if not ok then
		warn(("[DataService] Error guardando %s: %s"):format(player.Name, tostring(err)))
	end
	return ok and wrote
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

-- Segundos que el jugador estuvo desconectado antes de esta sesión (0 si no se sabe: partida nueva o
-- guardada antes de existir LastOnline). Sirve para "congelar" los plazos mientras no juega: al
-- cargar, cada servicio suma esto a sus horas de caducidad (Until += offlineSeconds).
function DataService.offlineSeconds(player: Player): number
	return offline[player] or 0
end

-- Registra una función que se llama cuando los datos de un jugador están listos.
function DataService.onLoaded(callback: (Player, { [string]: any }) -> ())
	table.insert(loadedCallbacks, callback)
	for player, data in profiles do
		task.spawn(callback, player, data)
	end
end

-- Registra una función que se llama cada vez que alguien gana dinero trabajando (Hacienda)
function DataService.onEarning(callback: (Player, number) -> ())
	table.insert(earningCallbacks, callback)
end

-- Registra una función que se llama justo antes de cada guardado (para apuntar lo último: dónde estás…)
function DataService.beforeSave(callback: (Player, { [string]: any }) -> ())
	table.insert(beforeSaveCallbacks, callback)
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
	if not data or type(amount) ~= "number" or amount ~= amount or math.abs(amount) >= 1e12 then
		return false
	end
	data.Money = math.max(0, math.floor(data.Money + amount))
	if isEarning and amount > 0 then
		data.Stats.MoneyEarned += amount
		for _, callback in earningCallbacks do
			task.spawn(callback, player, amount)
		end
	end
	syncMoney(player, data)
	return true
end

-- Cobra un precio si hay dinero suficiente. Devuelve true si se ha pagado.
function DataService.spend(player: Player, price: number): boolean
	local data = profiles[player]
	if not data or not validAmount(price) or data.Money < price then
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
		-- Se fue mientras cargaba: soltar el bloqueo para que pueda entrar enseguida en otro servidor
		if data and savingEnabled and store then
			pcall(function()
				(store :: DataStore):UpdateAsync(keyFor(player), function(old)
					if type(old) == "table" and old.SessionLock and old.SessionLock.JobId == game.JobId then
						old.SessionLock = nil
						return old
					end
					return nil
				end)
			end)
		end
		return
	end
	if not data then
		player:Kick("No hemos podido cargar tus datos. Vuelve a entrar en unos segundos.")
		return
	end

	reconcile(data, DEFAULT_DATA)
	if type(data.Money) ~= "number" or data.Money ~= data.Money or data.Money == math.huge then
		data.Money = 0 -- dinero roto (NaN) por un fallo antiguo
	end
	-- Cuánto tiempo ha estado fuera (se calcula una vez, antes de avisar a los servicios)
	-- (partidas de antes de LastOnline: vale la última vez que la historia le vio jugando, Story.LastSeen)
	local lastOnline = data.LastOnline
	if type(lastOnline) ~= "number" or lastOnline <= 0 then
		lastOnline = type(data.Story) == "table" and tonumber(data.Story.LastSeen) or nil
	end
	offline[player] = if type(lastOnline) == "number" and lastOnline > 0 then math.max(0, os.time() - lastOnline) else 0
	data.LastOnline = os.time()
	profiles[player] = data
	lastPlayCredit[player] = os.clock()
	syncMoney(player, data)

	for _, callback in loadedCallbacks do
		task.spawn(callback, player, data)
	end
end

local function markPending(userId: number, delta: number)
	local n = (pendingRelease[userId] or 0) + delta
	pendingRelease[userId] = if n > 0 then n else nil
end

-- Guarda soltando el bloqueo, con reintentos. Devuelve true si se escribió.
local function saveReleaseWithRetries(player: Player): boolean
	for attempt = 1, 3 do
		if DataService.save(player, true) then
			return true
		end
		task.wait(attempt * 2)
	end
	return false
end

-- Suma al tiempo jugado lo que de verdad ha pasado desde la última vez (no un autoguardado entero)
local function creditPlayTime(player: Player, data: { [string]: any })
	local now = os.clock()
	local last = lastPlayCredit[player] or now
	lastPlayCredit[player] = now
	data.Stats.PlaySeconds += math.max(0, math.floor(now - last + 0.5))
end

local function onPlayerRemoving(player: Player)
	local data = profiles[player]
	if data then
		-- (con pcall: unos datos rotos no deben impedir el guardado ni dejar el bloqueo puesto)
		local ok, err = pcall(creditPlayTime, player, data)
		if not ok then
			warn("[DataService] Error sumando tiempo jugado:", err)
		end
		released[player] = true
		markPending(player.UserId, 1)
		-- Guardar al salir (con reintentos: si falla se perdería lo último)
		ok, err = pcall(saveReleaseWithRetries, player)
		if not ok then
			warn(("[DataService] Error guardando al salir %s: %s"):format(player.Name, tostring(err)))
		end
		profiles[player] = nil
		released[player] = nil
		markPending(player.UserId, -1)
	end
	lastPlayCredit[player] = nil
	offline[player] = nil
end

-- "Empezar una vida nueva" (botón del Menú): borra la partida y vuelves a nacer bebé.
-- Se conservan las compras con Robux ya cobradas (ProcessedReceipts; los Game Pass los da Roblox).
-- Te saca del juego para que todos los sistemas empiecen de cero al volver a entrar.
local lastNewLife: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any -- (claves débiles: no se queda con los que se van)
function DataService.newLife(player: Player)
	local data = profiles[player]
	if not data or os.clock() - (lastNewLife[player] or -60) < 10 then
		return
	end
	lastNewLife[player] = os.clock()
	local fresh = deepCopy(DEFAULT_DATA)
	fresh.ProcessedReceipts = data.ProcessedReceipts or {}
	-- Las viviendas compradas siguen siendo tuyas (el registro de dueños está en otro DataStore)
	fresh.Properties = data.Properties
	-- El tutorial y los consejos ya vistos no se repiten en la vida nueva
	fresh.Onboarding = data.Onboarding
	fresh.Housing = data.Housing -- (su piso y su deuda del alquiler, Housing.Debt, siguen siendo suyos)
	-- Hacienda tampoco se olvida: renacer no borra lo pendiente ni las declaraciones sin presentar
	fresh.Tax = data.Tax
	-- El pase de temporada y lo conseguido con él (puede estar pagado con Robux) tampoco se pierden
	fresh.BattlePass = data.BattlePass
	fresh.Cosmetics = data.Cosmetics
	fresh.SeasonArchive = data.SeasonArchive
	fresh.Life.Stage = Config.LifeStory.NewCharacterStage
	-- El prólogo (tutorial) ya lo vio: no se repite solo (se puede volver a jugar desde «Mi historia»)
	if data.Story and data.Story.PrologueDone then
		fresh.Story.PrologueDone = data.Story.PrologueDone
		fresh.Story.PrologueResult = "NewLife"
	end
	-- Marcarlo como "ya se va" antes de guardar: un autoguardado a medias no vuelve a bloquear sus datos
	profiles[player] = fresh
	released[player] = true
	markPending(player.UserId, 1)
	local ok = saveReleaseWithRetries(player)
	markPending(player.UserId, -1)
	if not ok then
		-- No se pudo escribir: se queda con su vida de antes (mejor que perder las dos)
		if player.Parent then
			profiles[player] = data
			released[player] = nil
			local Notify = game:GetService("ReplicatedStorage").Remotes:FindFirstChild("Notify") :: RemoteEvent?
			if Notify then
				Notify:FireClient(player, "Error", "No se pudo guardar tu vida nueva. Inténtalo otra vez en un rato.")
			end
		end
		-- (si ya se ha ido, onPlayerRemoving se encarga de guardar y limpiar)
		return
	end
	profiles[player] = nil -- que el guardado al salir no pise la vida nueva
	released[player] = nil
	player:Kick("👶 Tu vida nueva está lista. Vuelve a entrar para nacer en Valmar.")
end

function DataService.init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	local remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("NewLife") :: RemoteEvent
	remote.OnServerEvent:Connect(DataService.newLife)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	-- Autoguardado + contador de tiempo jugado
	task.spawn(function()
		while true do
			task.wait(Config.AutosaveSeconds)
			for player, data in profiles do
				-- (un perfil roto no para el autoguardado de los demás)
				local ok, err = pcall(creditPlayTime, player, data)
				if not ok then
					warn("[DataService] Error sumando tiempo jugado:", err)
				end
				task.spawn(function()
					local saved, saveErr = pcall(DataService.save, player)
					if not saved then
						warn(("[DataService] Error en el autoguardado de %s: %s"):format(player.Name, tostring(saveErr)))
					end
				end)
			end
		end
	end)

	-- Al cerrar el servidor, guardar a todos
	game:BindToClose(function()
		local pending = 0
		for player, data in profiles do
			pcall(creditPlayTime, player, data)
			pending += 1
			task.spawn(function()
				pcall(DataService.save, player, true)
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
