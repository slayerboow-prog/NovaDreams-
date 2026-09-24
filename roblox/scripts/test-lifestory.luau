-- Prueba automática de la historia de vida (LifeStoryService) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-lifestory.luau
--
-- Carga los módulos reales de src/ con un "Roblox de mentira" (jugadores, reloj, remotos) y
-- simula vidas completas: el capítulo puente, una secundaria, una decisión con ramas y el
-- paso de bebé a niño. Sustituye por dobles solo lo que necesita el mapa de verdad
-- (DataService, LocationService), así que prueba la lógica de la historia tal cual.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local task = require("@lune/task")

local ROOT = "src"

---------------------------------------------------------------------
-- Cargador de módulos: imita script.Parent.X y require() de Roblox
---------------------------------------------------------------------
local mocks: { [string]: any } = {}
local cache: { [string]: any } = {}
local fakeGame: any
local fakeWorkspace: any

local nodeMeta = {}
local function node(path: string)
	return setmetatable({ __path = path }, nodeMeta)
end
nodeMeta.__index = function(self, key)
	local path = rawget(self, "__path")
	if key == "Parent" then
		return node((path:match("^(.*)/[^/]+$")))
	end
	return node(path .. "/" .. key)
end

local function loadModule(path: string): any
	if mocks[path] ~= nil then
		return mocks[path]
	end
	if cache[path] ~= nil then
		return cache[path]
	end
	local file = path .. ".luau"
	if not fs.isFile(file) then
		error("Módulo no encontrado: " .. path)
	end
	local env = setmetatable({
		script = node(path),
		require = function(target)
			return loadModule(rawget(target, "__path"))
		end,
		game = fakeGame,
		workspace = fakeWorkspace,
		task = task,
		Vector3 = roblox.Vector3,
		Color3 = roblox.Color3,
		warn = function(...)
			print("[warn]", ...)
		end,
	}, { __index = _G })
	local chunk = luau.load(fs.readFile(file), { debugName = file, environment = env })
	local result = chunk()
	cache[path] = result
	return result
end

---------------------------------------------------------------------
-- Roblox de mentira
---------------------------------------------------------------------
local function signal()
	local handlers = {}
	return {
		Connect = function(_, fn)
			table.insert(handlers, fn)
		end,
		Fire = function(_, ...)
			for _, fn in handlers do
				fn(...)
			end
		end,
	}
end

local remote = { OnServerEvent = signal() }
function remote:FireClient(player, kind, payload)
	table.insert(player.Inbox, { Kind = kind, Payload = payload })
end

local remotes = { LifeStory = remote }
function remotes:FindFirstChild(name)
	return self[name]
end

local replicatedStorage = { Shared = node(ROOT .. "/shared"), Remotes = remotes }
function replicatedStorage:WaitForChild(name)
	return self[name]
end

local lighting = { ClockTime = 14 }
local players = { PlayerRemoving = signal() }
local http = {}
function http:JSONEncode(value)
	return serde.encode("json", value)
end

fakeGame = {}
function fakeGame:GetService(name)
	return ({
		ReplicatedStorage = replicatedStorage,
		Lighting = lighting,
		Players = players,
		HttpService = http,
	})[name] or error("Servicio sin doble: " .. name)
end

local day = 1
fakeWorkspace = {}
function fakeWorkspace:GetAttribute(name)
	return if name == "Day" then day else nil
end

---------------------------------------------------------------------
-- Dobles de DataService y LocationService
---------------------------------------------------------------------
local Config = loadModule(ROOT .. "/shared/Config")
local profiles = {}
local loadedCallbacks = {}
mocks[ROOT .. "/server/Services/DataService"] = {
	get = function(player)
		return profiles[player]
	end,
	onLoaded = function(callback)
		table.insert(loadedCallbacks, callback)
	end,
	addMoney = function(player, amount)
		profiles[player].Money += amount
		return true
	end,
}

local fakeInstance = {}
function fakeInstance:IsDescendantOf()
	return true
end
mocks[ROOT .. "/server/Services/LocationService"] = {
	resolve = function(_, placeId)
		return { Instance = fakeInstance, Position = roblox.Vector3.new(0, 0, 0), Radius = 10, Zone = "Valmar Centro", PlaceId = placeId }
	end,
	isAt = function(player, spot)
		return player.At == spot.PlaceId
	end,
	zoneAt = function()
		return "Valmar Centro"
	end,
	positionOf = function()
		return roblox.Vector3.new(0, 0, 0)
	end,
}

---------------------------------------------------------------------
-- Utilidades de la prueba
---------------------------------------------------------------------
local failures = 0
local function check(condition: any, message: string)
	if condition then
		print("  ✅ " .. message)
	else
		failures += 1
		print("  ❌ " .. message)
	end
end

local function newPlayer(name: string, stage: string)
	local player = { Name = name, Parent = true, Inbox = {}, Attributes = {} }
	function player:SetAttribute(key, value)
		self.Attributes[key] = value
	end
	function player:GetAttribute(key)
		return self.Attributes[key]
	end
	profiles[player] = {
		Money = 0,
		Life = { Stage = stage, AgeYears = 0 },
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
		},
	}
	for _, callback in loadedCallbacks do
		callback(player, profiles[player])
	end
	task.wait(0.3)
	remote.OnServerEvent:Fire(player, "Sync") -- el cliente avisa de que ya escucha
	return player
end

local function received(player, kind: string, key: string?): boolean
	for _, message in player.Inbox do
		if message.Kind == kind and (key == nil or message.Payload.TextKey == key or message.Payload.TitleKey == key) then
			return true
		end
	end
	return false
end

local function lastState(player)
	for i = #player.Inbox, 1, -1 do
		if player.Inbox[i].Kind == "State" then
			return player.Inbox[i].Payload
		end
	end
	return nil
end

local function fromClient(player, ...)
	task.wait(0.3) -- el servidor ignora peticiones demasiado seguidas
	remote.OnServerEvent:Fire(player, ...)
end

---------------------------------------------------------------------
-- Pruebas
---------------------------------------------------------------------
print("\n▶ Datos de la historia")
local problems = loadModule(ROOT .. "/shared/LifeStory/Validate").run()
for _, problem in problems do
	print("    " .. problem)
end
check(#problems == 0, "Validate no encuentra errores")

local GameClock = loadModule(ROOT .. "/shared/GameClock")
local date = GameClock.fromDay(30, 13.5)
check(date.Weekday == 2 and date.Month == 2 and date.DayOfMonth == 2 and date.Hour == 13 and date.Minute == 30, "GameClock: día 30 = martes 2 del mes 2, 13:30")
check(GameClock.isBetween(22, 6, 23) and GameClock.isBetween(22, 6, 3) and not GameClock.isBetween(22, 6, 12), "GameClock: horarios nocturnos")

local StoryEvents = loadModule(ROOT .. "/server/LifeStory/StoryEvents")
local RoleService = loadModule(ROOT .. "/server/Services/RoleService")
local Service = loadModule(ROOT .. "/server/Services/LifeStoryService")
RoleService.init()
Service.init()

print("\n▶ Roles: jugador o NPC")
local teacher = newPlayer("Profe", "Adulto")
local npc = RoleService.assign("Profesor", { Subject = "Matematicas" })
check(npc.Kind == "NPC" and npc.Npc == "Npc_Profesor", "Sin profesores conectados, la clase la da un NPC")
RoleService.setOnDuty(teacher, "Profesor", { Subject = "Matematicas" })
local real = RoleService.assign("Profesor", { Subject = "Matematicas" })
check(real.Kind == "Player" and real.Player == teacher, "Con un profesor jugador de servicio, la da él")
local other = RoleService.assign("Profesor", { Subject = "Musica" })
check(other.Kind == "NPC", "Para otra asignatura sigue habiendo NPC")
RoleService.release(real)
RoleService.offDuty(teacher)

print("\n▶ Capítulo puente: una nueva vida en Valmar")
local ana = newPlayer("Ana", "Adulto")
task.wait(0.2)
local data = profiles[ana]
check(received(ana, "Chapter", "CHAPTER.NUEVA_VIDA.TITLE"), "Empieza el capítulo con su pantalla")
check(data.Story.Active.Adulto_LlegadaValmar ~= nil, "Primera misión principal en marcha")
local state = lastState(ana)
check(state and state.Tracked and state.Tracked.TextKey == "QUEST.LLEGADA.PLAZA" and state.Tracked.Args.placeKey == "PLACE.PLAZA_CENTRO", "La tarjeta dice 'Ve a la Plaza Mayor'")

ana.At = "PlazaCentro"
task.wait(0.7)
check(data.Story.Active.Adulto_LlegadaValmar.Step == 2, "Llegar a la plaza avanza al siguiente paso")
StoryEvents.emit(ana, "HomeClaimed", {})
StoryEvents.emit(ana, "Ate", {})
task.wait(0.1)
check(data.Story.Completed.Adulto_LlegadaValmar ~= nil, "Conseguir casa y comer completa 'Llegar a Valmar'")
check(data.Money == 100 and data.Story.Flags.TieneHogar, "Recompensa: dinero y marca TieneHogar")
check(received(ana, "Moment", "MOMENT.PRIMER_HOGAR"), "Momento de vida: 'Ya tienes un hogar en Valmar'")
check(data.Story.Active.Adulto_PrimerSueldo ~= nil, "Empieza 'Ganarte la vida'")

StoryEvents.emit(ana, "JobTaskDone", { JobId = "Barista" })
StoryEvents.emit(ana, "JobTaskDone", { JobId = "Barista" })
task.wait(0.1)
state = lastState(ana)
check(state.Tracked.Args.count == 2 and state.Tracked.Args.total == 3, "La tarjeta cuenta 2/3 entregas")
StoryEvents.emit(ana, "JobTaskDone", { JobId = "Barista" })
task.wait(0.1)
check(data.Story.Completed.Adulto_PrimerSueldo ~= nil and data.Money == 250, "Tres entregas: primer sueldo celebrado")

print("\n▶ Secundaria que nace de lo que haces (repartir)")
StoryEvents.emit(ana, "JobTaskDone", { JobId = "Repartidor" })
task.wait(0.1)
check(received(ana, "Offer", "QUEST.MEDICINAS.TITLE"), "Correos te pide llevar medicinas")
fromClient(ana, "Offer", "Side_MedicinasUrgentes", true)
check(data.Story.Active.Side_MedicinasUrgentes ~= nil, "Aceptada: la secundaria está en marcha")
check(data.Story.Active.Adulto_ConoceLaRegion ~= nil, "La principal sigue en paralelo")

print("\n▶ Decisión con ramas")
check(received(ana, "Choice"), "Se pregunta adónde ir en el día libre")
fromClient(ana, "Choose", "Adulto_ConoceLaRegion", "Playa")
check(data.Story.Choices.PrimeraExcursion and data.Story.Choices.PrimeraExcursion.V == "Playa", "La decisión queda guardada")
ana.At = "CentroSalud"
task.wait(0.7)
check(data.Story.Completed.Side_MedicinasUrgentes ~= nil and data.Money == 310, "Medicinas entregadas (+60)")
ana.At = "ParadaBus"
task.wait(0.7)
local step = data.Story.Active.Adulto_ConoceLaRegion and data.Story.Active.Adulto_ConoceLaRegion.Step
check(step == 4, "La rama 'campus' se salta: toca ir a la playa (paso 4)")
ana.At = "Playa"
task.wait(0.7)
check(data.Story.Completed.Adulto_ConoceLaRegion ~= nil, "Llegar a la playa completa la excursión")
local outro = false
for _, message in ana.Inbox do
	outro = outro or (message.Kind == "Chapter" and message.Payload.Phase == "Outro" and message.Payload.TextKey == "CHAPTER.NUEVA_VIDA.OUTRO")
end
check(data.Story.Chapters.Adulto_NuevaVida ~= nil and outro, "Capítulo terminado con su pantalla de cierre")
check(data.Story.Discovered.Playa and data.Story.Discovered.PlazaCentro, "Los lugares visitados quedan descubiertos")
local biography = {}
for _, event in data.Story.Events do
	table.insert(biography, event.K)
end
check(table.find(biography, "MOMENT.PRIMER_SUELDO") ~= nil and table.find(biography, "QUEST.REGION.OPT_PLAYA") ~= nil, "La biografía guarda momentos y decisiones")
check(pcall(serde.encode, "json", data), "Los datos se pueden guardar (JSON válido)")

print("\n▶ Bebé → niño (capítulos de las fases 2 y 4 activados solo para la prueba)")
local Chapters = loadModule(ROOT .. "/shared/LifeStory/Chapters")
Chapters.Bebe_PrimerosPasos.Enabled = true
Chapters.Nino_ElColegio.Enabled = true
lighting.ClockTime = 20 -- fuera del horario del colegio
local leo = newPlayer("Leo", "Bebe")
task.wait(0.2)
local leoData = profiles[leo]
check(leoData.Story.Active.Bebe_AprendeACaminar ~= nil, "El bebé empieza aprendiendo a caminar")
StoryEvents.emit(leo, "BabyStood", {})
for _ = 1, 5 do
	StoryEvents.emit(leo, "BabySteps", {})
end
StoryEvents.emit(leo, "Talk", { Npc = "Familia_Abu" })
task.wait(0.1)
check(leoData.Story.Completed.Bebe_AprendeACaminar ~= nil, "Primeros pasos completados")
StoryEvents.emit(leo, "RoomVisited", { Room = "Cocina" })
StoryEvents.emit(leo, "RoomVisited", { Room = "Salon" })
task.wait(0.1)
state = lastState(leo)
check(state.Tracked.Children and state.Tracked.Children[1].Done and state.Tracked.Children[2].Done and not state.Tracked.Children[3].Done, "Explorar la casa: 2 de 3 habitaciones, en cualquier orden")
StoryEvents.emit(leo, "RoomVisited", { Room = "Dormitorio" })
StoryEvents.emit(leo, "Talk", { Npc = "Familia_Padre" })
StoryEvents.emit(leo, "LookedOutside", {})
task.wait(0.2)
check(received(leo, "Transition", "TRANSITION.ANOS_DESPUES"), "Pantalla 'Han pasado varios años…'")
check(leoData.Life.Stage == "Nino" and leo:GetAttribute("LifeStage") == "Nino", "Ahora es niño")
state = lastState(leo)
check(state and state.Waiting and state.Waiting.Reason == "Hours", "A las 20:00 el primer día de colegio espera a mañana")
lighting.ClockTime = 8
task.wait(5.5)
check(leoData.Story.Active.Nino_PrimerDiaColegio ~= nil, "A las 8:00 empieza el primer día de colegio")

print(("\n%s"):format(if failures == 0 then "✅ Todo correcto" else ("❌ %d fallos"):format(failures)))
process.exit(if failures == 0 then 0 else 1)
