-- TesterService: MODO PRUEBAS, solo para el dueño del juego (y quien esté en Config.Testers).
--
-- Sirve para revisar todo el juego sin tener que progresar: dinero infinito, todas las armas, todos
-- los oficios sin requisitos, todos los carnets, nivel máximo, cambiar de etapa de vida, rellenar las
-- necesidades, quitar la búsqueda policial, teletransporte, hora del día y el pase de temporada
-- (premium SIMULADO que nunca se guarda como compra, sumar XP, poner nivel, adelantar el reloj).
--
-- Quién es tester (lo decide SIEMPRE el servidor; el atributo "Tester" solo le sirve al cliente
-- para enseñar el panel):
--   * en Studio (RunService:IsStudio()), cualquiera;
--   * el creador del juego si es de un usuario (game.CreatorId);
--   * el dueño del grupo (rango 255) si el juego es de un grupo;
--   * los UserId de Config.Testers.
-- A cualquier otro jugador el remoto y el comando /pruebas no le hacen nada (en silencio).
--
-- Los demás servicios preguntan TesterService.bypass(player) en sus requisitos (edad, carnet,
-- licencia, energía para trabajar…). Este módulo es una "hoja": arriba solo carga Config y
-- DataService, para que cualquiera pueda cargarlo sin dependencias circulares; los servicios que
-- usan sus acciones se cargan dentro de cada acción.
--
-- Datos guardados (solo en los testers; se crea al usarlo, como data.Progress o data.Licenses):
--   data.Tester = { Money = bool, Bypass = bool, RealMoney = number }
--   RealMoney: el dinero que tenías al encender el dinero infinito (se devuelve al apagarlo).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)

local TesterService = {}

local MONEY_FLOOR = 1000000 -- si baja de aquí…
local MONEY_TOP = 9999999 -- …se rellena hasta aquí
local RATE = 0.25 -- segundos mínimos entre dos peticiones del panel

-- Etapas a las que se puede saltar desde el panel (Bebe no: el tutorial de bebé tiene su propia
-- máquina de estados y solo se entra naciendo; ver BabyService)
TesterService.Stages = { "Nino", "Adolescente", "AdultoJoven", "Adulto", "Mayor" }
local STAGE_LABEL = { Nino = "niño", Adolescente = "adolescente", AdultoJoven = "adulto joven", Adulto = "adulto", Mayor = "mayor" }
-- Lugares del teletransporte (ids de LifeStory/Locations; LocationService los busca en el mapa)
TesterService.Places = {
	{ Id = "Home", Name = "🏠 Mi casa" },
	{ Id = "PlazaCentro", Name = "⛲ Plaza del centro" },
	{ Id = "Colegio", Name = "🏫 Colegio" },
	{ Id = "Instituto", Name = "🎒 Instituto" },
	{ Id = "Universidad", Name = "🎓 Universidad" },
	{ Id = "Hospital", Name = "🏥 Hospital" },
	{ Id = "Policia", Name = "🚓 Comisaría" },
	{ Id = "Bomberos", Name = "🚒 Bomberos" },
	{ Id = "Autoescuela", Name = "🚗 Autoescuela" },
	{ Id = "Supermercado", Name = "🛒 Supermercado" },
	{ Id = "CafeteriaCentral", Name = "☕ Cafetería" },
	{ Id = "Correos", Name = "📮 Correos" },
	{ Id = "CentroComercial", Name = "🛍 Centro comercial" },
	{ Id = "Banco", Name = "🏦 Banco" },
	{ Id = "Parque", Name = "🌳 Parque" },
	{ Id = "Playa", Name = "🏖 Playa" },
	{ Id = "Granja", Name = "🐄 Granja" },
	{ Id = "Aeropuerto", Name = "✈ Aeropuerto" },
	{ Id = "PuertoDeportivo", Name = "⛵ Puerto deportivo" },
}
-- Horas del día (WorldService.skipTo: el reloj salta para TODO el servidor; no cambia la duración
-- del día, Config.DayLengthMinutes)
TesterService.Hours = { 8, 12, 18, 22 }

local remote: RemoteEvent? = nil
local notify: RemoteEvent? = nil
local groupOwner: { [Player]: boolean } = {}
local lastRequest: { [Player]: number } = {}
local watching: { [Player]: boolean } = {}

local function studio(): boolean
	local ok, result = pcall(function()
		return RunService:IsStudio()
	end)
	return ok and result == true
end

-- ¿Es tester? (siempre lo calcula el servidor: nada que mande el cliente cuenta)
function TesterService.isTester(player: Player): boolean
	if typeof(player) ~= "Instance" and type(player) ~= "table" then
		return false
	end
	if studio() then
		return true
	end
	local userId = player.UserId
	if type(userId) ~= "number" or userId <= 0 then
		return false
	end
	for _, id in Config.Testers or {} do
		if id == userId then
			return true
		end
	end
	local name = (player :: any).Name
	if type(name) == "string" then
		for _, n in Config.TesterNames or {} do
			if type(n) == "string" and string.lower(n) == string.lower(name) then
				return true
			end
		end
	end
	if game.CreatorType == Enum.CreatorType.User then
		return game.CreatorId ~= 0 and userId == game.CreatorId
	elseif game.CreatorType == Enum.CreatorType.Group then
		return groupOwner[player] == true
	end
	return false
end

-- Ajustes guardados del tester (se crean la primera vez; valores rotos vuelven a los de siempre)
local function settingsOf(player: Player): { [string]: any }?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	local s = data.Tester
	if type(s) ~= "table" then
		s = {}
		data.Tester = s
	end
	if type(s.Money) ~= "boolean" then
		s.Money = false
	end
	if type(s.Bypass) ~= "boolean" then
		s.Bypass = true -- (al entrar en el modo pruebas, sin requisitos: para eso es)
	end
	if type(s.RealMoney) ~= "number" or s.RealMoney ~= s.RealMoney or s.RealMoney < 0 then
		s.RealMoney = 0
	end
	return s
end

-- ¿Se salta este jugador los requisitos (edad, carnet, licencia, energía…)? Lo preguntan los
-- servicios en cada comprobación. Solo testers con el interruptor «Sin requisitos» encendido.
function TesterService.bypass(player: Player): boolean
	if not TesterService.isTester(player) then
		return false
	end
	local data = DataService.get(player)
	local s = data and data.Tester
	-- (sin ajustes guardados todavía: encendido, como el valor por defecto)
	return not (type(s) == "table" and s.Bypass == false)
end

local function toast(player: Player, kind: string, text: string)
	if notify then
		notify:FireClient(player, kind, text)
	end
end

local function service(name: string): any
	return require(script.Parent[name])
end

---------------------------------------------------------------------
-- Dinero infinito
---------------------------------------------------------------------

-- Rellena el dinero si ha bajado del mínimo. Por DataService.addMoney (sin contar como ganancia:
-- no suma a Hacienda ni a las estadísticas de lo ganado), así la interfaz y las compras siguen igual.
function TesterService.topUp(player: Player): boolean
	if not TesterService.isTester(player) then
		return false
	end
	local s = settingsOf(player)
	local data = DataService.get(player)
	if not s or not data or not s.Money then
		return false
	end
	if type(data.Money) == "number" and data.Money < MONEY_FLOOR then
		return DataService.addMoney(player, MONEY_TOP - data.Money)
	end
	return false
end

local function setMoney(player: Player, on: boolean)
	local s = settingsOf(player)
	local data = DataService.get(player)
	if not s or not data or s.Money == on then
		return
	end
	if on then
		s.RealMoney = math.max(0, math.floor(tonumber(data.Money) or 0))
		s.Money = true
		TesterService.topUp(player)
		toast(player, "Success", "💰 Dinero infinito activado")
	else
		s.Money = false
		-- Vuelve el dinero que tenías antes (el de pruebas no se queda en la partida)
		DataService.addMoney(player, s.RealMoney - (tonumber(data.Money) or 0))
		toast(player, "Info", "💰 Dinero infinito desactivado: vuelves a tener tu dinero de antes")
	end
end

---------------------------------------------------------------------
-- Acciones
---------------------------------------------------------------------

local function publishFlags(player: Player)
	local s = settingsOf(player)
	player:SetAttribute("Tester", true)
	-- (solo para la interfaz: el cliente enseña los carteles de oficio aunque no tengas la edad;
	-- el servidor vuelve a comprobar TesterService.bypass en cada uso)
	player:SetAttribute("TesterBypass", if s and s.Bypass then true else nil)
end

-- Carnets de conducir (moto, coche…): se guardan de verdad (data.Licenses)
local function giveDrivingLicences(player: Player): number
	local given = 0
	local okV, VehicleService = pcall(service, "VehicleService")
	local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
	if okV and VehicleService then
		for key in Gameplay.Licenses do
			if not VehicleService.hasLicense(player, key) then
				VehicleService.grantLicense(player, key)
				given += 1
			end
		end
	end
	return given
end

-- Carnets de conducir y licencia de armas
local function giveLicences(player: Player): number
	local given = giveDrivingLicences(player)
	local okW, WeaponService = pcall(service, "WeaponService")
	if okW and WeaponService and WeaponService.grantLicence and WeaponService.grantLicence(player) then
		given += 1
	end
	return given
end

local function giveWeapons(player: Player): (number, number)
	local WeaponService = service("WeaponService")
	return WeaponService.grantAll(player)
end

local function giveVehicles(player: Player): number
	local VehicleService = service("VehicleService")
	local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
	local given = 0
	for kind, vehicle in Gameplay.Vehicles do
		if not vehicle.Hidden and VehicleService.grant(player, kind) then
			given += 1
		end
	end
	-- Y los barcos (se sacan en el puerto deportivo)
	local okB, BoatService = pcall(service, "BoatService")
	if okB and BoatService and BoatService.grantAll then
		local okG, boats = pcall(BoatService.grantAll, player)
		if okG and type(boats) == "number" then
			given += boats
		end
	end
	return given
end

local function maxLevel(player: Player): boolean
	local data = DataService.get(player)
	if not data then
		return false
	end
	local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
	local progress = type(data.Progress) == "table" and data.Progress or {}
	local level = tonumber(progress.Level) or 1
	local P = Gameplay.Progression
	if level >= P.MaxLevel then
		return false
	end
	local need = -(tonumber(progress.Xp) or 0)
	for l = level, P.MaxLevel - 1 do
		need += Gameplay.xpToNext(l)
	end
	-- (sin motivo: la experiencia sin fuente no tiene tope por minuto)
	service("ProgressionService").addXp(player, math.max(1, need))
	return true
end

local function refill(player: Player)
	local max = Config.Needs.Max
	service("NeedsService").change(player, max, max)
	pcall(function()
		service("ProgressionService").restoreStamina(player)
	end)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = humanoid.MaxHealth
	end
end

local function clearWanted(player: Player)
	pcall(function()
		service("WantedService").clear(player)
	end)
	pcall(function()
		local JusticeService = service("JusticeService")
		if JusticeService.isJailed(player) then
			JusticeService.release(player, "Tester")
		end
	end)
end

local function teleport(player: Player, placeId: any): boolean
	if type(placeId) ~= "string" then
		return false
	end
	local known = false
	for _, place in TesterService.Places do
		known = known or place.Id == placeId
	end
	if not known then
		return false
	end
	local spot = service("LocationService").resolve(player, placeId)
	if not spot then
		toast(player, "Error", "Ese sitio no está en el mapa.")
		return false
	end
	service("SceneService").teleportTo(player, spot.Position)
	return true
end

-- Cambiar de etapa de vida por el camino de la historia (LifeStoryService.setStage: edad, atributo
-- LifeStage —con él LifeService cambia el tamaño del cuerpo y AvatarService la ropa—, biografía y el
-- capítulo que toca; se guarda con la partida). Para que funcione SIEMPRE (el dueño seguía siendo
-- niño en mitad de «Recados por el barrio»):
--   * una conversación o un minijuego en marcha se cortan (antes: «termina la conversación»);
--   * el prólogo (el sueño) se da por terminado;
--   * las misiones de la etapa anterior que ya no pegan (la principal de niño, el día de cole…) se
--     dejan (LifeStoryService.dropOutgrown): si no, el capítulo nuevo no empezaba nunca.
-- De bebé no: el tutorial de bebé tiene su propia máquina de estados (BabyService).
-- Devuelve true si ahora estás en esa etapa, y el texto del aviso.
local function setStage(player: Player, stage: any): (boolean, string?)
	if type(stage) ~= "string" or not table.find(TesterService.Stages, stage) then
		return false, nil
	end
	local data = DataService.get(player)
	if not data or type(data.Life) ~= "table" then
		return false, "Aún no han cargado tus datos: inténtalo en un momento."
	end
	if data.Life.Stage == stage then
		-- (por si el atributo se quedó desfasado: se vuelve a poner)
		player:SetAttribute("LifeStage", stage)
		return true, nil
	end
	if data.Life.Stage == "Bebe" then
		return false, "De bebé no: termina antes el tutorial de bebé."
	end
	local LifeStoryService = service("LifeStoryService")
	local StoryContext = require(ReplicatedStorage.Shared.LifeStory.StoryContext)
	local story = type(data.Story) == "table" and data.Story or nil
	if story and type(story.Active) == "table" and story.Active[StoryContext.PrologueId] then
		pcall(LifeStoryService.endPrologue, player, "Skipped")
	end
	if player:GetAttribute("InDialogue") then
		pcall(function()
			local DialogueService = service("DialogueService")
			DialogueService.cancel(player, "tester")
			if not DialogueService.isBusy(player) then
				player:SetAttribute("InDialogue", nil) -- (un atributo que se quedó puesto sin conversación)
			end
		end)
	end
	pcall(LifeStoryService.dropOutgrown, player, stage)
	LifeStoryService.setStage(player, stage)
	if data.Life.Stage ~= stage then
		return false, "No se ha podido cambiar de etapa."
	end
	return true, nil
end

local function stageToast(player: Player, stage: string)
	local data = DataService.get(player)
	local age = data and type(data.Life) == "table" and tonumber(data.Life.AgeYears)
	toast(player, "Success", ("🎂 Ya eres %s%s"):format(STAGE_LABEL[stage] or stage, if age then (" (%d años)"):format(age) else ""))
end

local function setHour(player: Player, hour: any): boolean
	if type(hour) ~= "number" or not table.find(TesterService.Hours, hour) then
		return false
	end
	service("WorldService").skipTo(hour)
	return true
end

-- Estado para el panel
function TesterService.state(player: Player): { [string]: any }
	local s = settingsOf(player)
	local stages = {}
	for _, stage in TesterService.Stages do
		table.insert(stages, stage)
	end
	return {
		Money = s ~= nil and s.Money == true,
		Bypass = s ~= nil and s.Bypass == true,
		Stage = player:GetAttribute("LifeStage"),
		Stages = stages,
		Places = TesterService.Places,
		Hours = TesterService.Hours,
		-- Pase de temporada (premium simulado, nivel…): ver BattlePassService.testerState
		BattlePass = (function()
			local ok, state = pcall(function()
				return service("BattlePassService").testerState(player)
			end)
			return if ok then state else nil
		end)(),
	}
end

local function send(player: Player, kind: string, payload: any?)
	if remote then
		remote:FireClient(player, kind, payload)
	end
end

-- Atiende una petición del panel (o del chat). Devuelve true si se ha hecho algo.
-- Para quien no es tester no existe: no se contesta nada.
function TesterService.handle(player: Player, kind: any, a: any, b: any): boolean
	if not TesterService.isTester(player) then
		return false
	end
	if type(kind) ~= "string" or not DataService.get(player) then
		return false
	end
	publishFlags(player)
	local done = true
	if kind == "Open" then
		send(player, "Open", TesterService.state(player))
		return true
	elseif kind == "Toggle" then
		local s = settingsOf(player) :: { [string]: any }
		if a == "Money" then
			setMoney(player, not s.Money)
		elseif a == "Bypass" then
			s.Bypass = not s.Bypass
			publishFlags(player)
			if s.Bypass then
				giveDrivingLicences(player) -- (sin requisitos también al volante: ni edad ni carnet)
			end
			toast(player, "Info", if s.Bypass then "🔓 Sin requisitos: todos los oficios, carnets y edades (y conduces sin que te pare la policía)" else "🔒 Requisitos normales otra vez")
		else
			done = false
		end
	elseif kind == "Action" then
		if a == "Weapons" then
			local given, missing = giveWeapons(player)
			toast(player, if missing > 0 then "Error" else "Success", ("🔫 Armas y munición: %d añadidas%s"):format(given,
				if missing > 0 then (" (%d no caben en la mochila)"):format(missing) else ""))
		elseif a == "Licences" then
			local given = giveLicences(player)
			toast(player, "Success", ("🪪 Carnets y licencias: %d nuevos"):format(given))
		elseif a == "Vehicles" then
			toast(player, "Success", ("🚗 Vehículos y barcos: %d nuevos"):format(giveVehicles(player)))
		elseif a == "MaxLevel" then
			if maxLevel(player) then
				toast(player, "Success", "⭐ Nivel máximo")
			else
				toast(player, "Info", "⭐ Ya tienes el nivel máximo")
			end
		elseif a == "Refill" then
			refill(player)
			toast(player, "Success", "❤ Energía, hambre, salud y estamina al máximo")
		elseif a == "ClearWanted" then
			clearWanted(player)
			toast(player, "Success", "🚔 Ya no te busca la policía")
		elseif a == "UnlockAll" then
			local s = settingsOf(player) :: { [string]: any }
			s.Bypass = true
			publishFlags(player)
			giveLicences(player)
			local _, missing = giveWeapons(player)
			pcall(giveVehicles, player)
			maxLevel(player)
			refill(player)
			if not s.Money then
				setMoney(player, true)
			end
			toast(player, "Success", "🔓 Todo desbloqueado" .. (if missing > 0 then (" (%d armas no caben en la mochila)"):format(missing) else ""))
		elseif a == "Teleport" then
			done = teleport(player, b)
		elseif a == "Stage" then
			local ok, err = setStage(player, b)
			done = ok
			if ok then
				stageToast(player, b)
			elseif err then
				toast(player, "Error", err)
			end
		elseif a == "MakeAdult" then
			-- Un toque: adulto, con todos los carnets y sin búsqueda (para conducir sin la policía detrás)
			local ok, err = setStage(player, "Adulto")
			done = ok
			if ok then
				giveDrivingLicences(player)
				clearWanted(player)
				local data = DataService.get(player)
				local age = data and type(data.Life) == "table" and tonumber(data.Life.AgeYears)
				toast(player, "Success", ("🧑 Ya eres adulto%s, con todos los carnets y sin búsqueda: puedes conducir tranquilo"):format(if age then (" (%d años)"):format(age) else ""))
			else
				toast(player, "Error", err or "No se ha podido cambiar de etapa.")
			end
		elseif a == "BattlePass" then
			-- Pase de temporada: b = { Op = "Premium" (simular, solo en memoria) | "AddXp" | "SetLevel" |
			-- "NextDay" | "NextWeek" | "ResetClock" | "Reset", Value = número }
			local ok, result = pcall(function()
				return (service("BattlePassService").testerAction(player, b))
			end)
			done = ok and result == true
		elseif a == "Hour" then
			done = setHour(player, b)
			if done then
				toast(player, "Info", ("🕒 Son las %d:00 (para todo el servidor)"):format(b))
			end
		else
			done = false
		end
	else
		return false
	end
	send(player, "State", TesterService.state(player))
	return done
end

-- /pruebas en el chat
function TesterService.chat(player: Player, message: any): boolean
	if type(message) ~= "string" or #message > 60 then
		return false
	end
	local word = (message:match("^%s*(%S+)") or ""):lower()
	if word ~= "/pruebas" then
		return false
	end
	return TesterService.handle(player, "Open")
end

local function watchMoney(player: Player)
	if watching[player] then
		return
	end
	watching[player] = true
	player:GetAttributeChangedSignal("Money"):Connect(function()
		task.defer(TesterService.topUp, player)
	end)
end

local function setup(player: Player)
	if game.CreatorType == Enum.CreatorType.Group then
		task.spawn(function()
			local ok, rank = pcall(function()
				return player:GetRankInGroup(game.CreatorId)
			end)
			groupOwner[player] = ok and rank == 255
			if TesterService.isTester(player) then
				publishFlags(player)
				watchMoney(player)
			end
		end)
	end
	if TesterService.isTester(player) then
		player:SetAttribute("Tester", true)
		watchMoney(player)
	end
	pcall(function()
		player.Chatted:Connect(function(message)
			TesterService.chat(player, message)
		end)
	end)
end

function TesterService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	notify = remotes:FindFirstChild("Notify") :: RemoteEvent?
	local existing = remotes:FindFirstChild("Tester") :: RemoteEvent?
	if not existing then
		local created = Instance.new("RemoteEvent")
		created.Name = "Tester"
		created.Parent = remotes
		existing = created
	end
	remote = existing
	;(existing :: RemoteEvent).OnServerEvent:Connect(function(player, kind, a, b)
		-- (los que no son testers ni siquiera cuentan para el límite: se ignoran sin más)
		if not TesterService.isTester(player) then
			return
		end
		local now = os.clock()
		if now - (lastRequest[player] or -math.huge) < RATE then
			return
		end
		lastRequest[player] = now
		local ok, err = pcall(TesterService.handle, player, kind, a, b)
		if not ok then
			warn("[TesterService] " .. tostring(err))
		end
	end)
	-- Comando de chat de verdad (TextChatService): /pruebas
	pcall(function()
		local TextChatService = game:GetService("TextChatService")
		local command = Instance.new("TextChatCommand")
		command.Name = "TesterCommand"
		command.PrimaryAlias = "/pruebas"
		command.Triggered:Connect(function(source: TextSource, message: string)
			local player = Players:GetPlayerByUserId(source.UserId)
			if player then
				TesterService.chat(player, message)
			end
		end)
		command.Parent = TextChatService
	end)
	DataService.onLoaded(function(player)
		if TesterService.isTester(player) then
			publishFlags(player)
			TesterService.topUp(player)
			-- Sin requisitos: los carnets de conducir ya puestos (VehicleService.grantLicense los guarda)
			if TesterService.bypass(player) then
				task.defer(pcall, giveDrivingLicences, player)
			end
		end
	end)
	Players.PlayerAdded:Connect(setup)
	for _, player in Players:GetPlayers() do
		task.spawn(setup, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		groupOwner[player] = nil
		lastRequest[player] = nil
		watching[player] = nil
	end)
	-- Red de seguridad del dinero infinito (por si algo cambia el dinero sin el atributo)
	task.spawn(function()
		while true do
			task.wait(2)
			for _, player in Players:GetPlayers() do
				if TesterService.isTester(player) then
					pcall(TesterService.topUp, player)
				end
			end
		end
	end)
end

return TesterService
