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
-- Random de Roblox (Lune no lo trae): misma interfaz, resultados repetibles
local TestRandom = {}
TestRandom.__index = TestRandom
function TestRandom.new(seed: number?)
	return setmetatable({ s = seed or 12345 }, TestRandom)
end
function TestRandom:NextNumber(a: number?, b: number?)
	self.s = (self.s * 1103515245 + 12345) % 2147483648
	local x = self.s / 2147483648
	if a and b then
		return a + x * (b - a)
	end
	return x
end
function TestRandom:NextInteger(a: number, b: number)
	return a + math.floor(self:NextNumber() * (b - a + 1))
end

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
		CFrame = roblox.CFrame,
		Random = TestRandom,
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

-- Cliente de mentira para las conversaciones: "lee" cada trozo y contesta (player.Answer elige)
local dialogueRemote = { OnServerEvent = signal() }
function dialogueRemote:FireClient(player, kind, payload)
	if kind ~= "Show" then
		return
	end
	for _, line in payload.Lines do
		table.insert(player.Said, line.Text)
		player.Emotions = player.Emotions or {}
		player.Emotions[line.Text] = line.Emotion or "ninguna"
	end
	local choice = nil
	if payload.Options then
		choice = if player.Answer then player.Answer(payload.Ask, payload.Options) else 1
	end
	task.defer(function()
		dialogueRemote.OnServerEvent:Fire(player, "Next", payload.Token, choice)
	end)
end
-- Minijuegos: el jugador de mentira juega lo justo y devuelve player.GameResult (o un buen resultado)
local miniGameRemote = { OnServerEvent = signal() }
function miniGameRemote:FireClient(player, kind, payload)
	if kind ~= "Start" then
		return
	end
	local spec = payload.Spec
	table.insert(player.Games, spec)
	local rounds = spec.Rounds or spec.Plays or 3
	task.delay(rounds * 0.45 + 0.1, function()
		local result = player.GameResult or (if spec.Game == "Futbol" then { Goals = 3, Against = 1 } else { Hits = rounds })
		miniGameRemote.OnServerEvent:Fire(player, "Result", payload.Token, result)
	end)
end
local sayRemote = {}
function sayRemote:FireClient(player, kind, payload)
	table.insert(player.Barks, payload.TextKey)
end

local remotes = { LifeStory = remote, Dialogue = dialogueRemote, MiniGame = miniGameRemote, Baby = sayRemote }
function remotes:FindFirstChild(name)
	return self[name]
end
function remotes:WaitForChild(name)
	return self[name]
end

local replicatedStorage = { Shared = node(ROOT .. "/shared"), Remotes = remotes }
function replicatedStorage:WaitForChild(name)
	return self[name]
end
function replicatedStorage:FindFirstChild(name)
	return rawget(self, name)
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
	spend = function(player, amount)
		if profiles[player].Money < amount then
			return false
		end
		profiles[player].Money -= amount
		return true
	end,
}

local fakeInstance = {}
function fakeInstance:IsDescendantOf()
	return true
end
mocks[ROOT .. "/server/Services/LocationService"] = {
	resolve = function(_, placeId)
		return { Instance = fakeInstance, Position = roblox.Vector3.new(0, 0, 0), CFrame = roblox.CFrame.new(), Radius = 10, Zone = "Valmar Centro", PlaceId = placeId }
	end,
	isAt = function(player, spot)
		return player.At == spot.PlaceId
	end,
	zoneAt = function()
		return "Valmar Centro"
	end,
	zoneCenter = function()
		return roblox.Vector3.new(0, 0, 0)
	end,
	positionOf = function()
		return roblox.Vector3.new(0, 0, 0)
	end,
}

-- Necesidades y mochila: dobles sencillos (guardan lo que pasa en el perfil)
local needsChanges = {}
mocks[ROOT .. "/server/Services/NeedsService"] = {
	change = function(player, hunger, energy)
		table.insert(needsChanges, { player, hunger, energy })
	end,
}
mocks[ROOT .. "/server/Services/InventoryService"] = {
	add = function(player, id, count)
		local items = profiles[player].Items
		items[id] = (items[id] or 0) + (count or 1)
		return true
	end,
	remove = function(player, id, count)
		local items = profiles[player].Items
		items[id] = math.max(0, (items[id] or 0) - (count or 1))
		if items[id] == 0 then
			items[id] = nil
		end
		return true
	end,
	count = function(player, id)
		return profiles[player].Items[id] or 0
	end,
}

-- Escenas: el doble recuerda qué actores y objetos hay (como los vería el jugador)
local scenes = {}
local function fakeModel(position)
	return {
		GetPivot = function()
			return roblox.CFrame.new(position)
		end,
	}
end
mocks[ROOT .. "/server/Services/SceneService"] = {
	set = function(player, questId, actors, props)
		scenes[player] = scenes[player] or {}
		local actorSet, propSet = {}, {}
		for _, spec in actors do
			actorSet[spec.Npc] = spec
		end
		for _, id in props do
			propSet[id] = true
		end
		scenes[player][questId] = { Actors = actorSet, Props = propSet }
	end,
	clear = function(player, questId)
		if scenes[player] then
			scenes[player][questId] = nil
		end
	end,
	removeProp = function(player, questId, id)
		local scene = scenes[player] and scenes[player][questId]
		if scene then
			scene.Props[id] = nil
		end
	end,
	hasProp = function(player, questId, id)
		local scene = scenes[player] and scenes[player][questId]
		return scene ~= nil and scene.Props[id] == true
	end,
	propPosition = function()
		return roblox.Vector3.new(1, 0, 1)
	end,
	actorOf = function(player, npc)
		for _, scene in scenes[player] or {} do
			if scene.Actors[npc] then
				return fakeModel(roblox.Vector3.new(2, 0, 2))
			end
		end
		return nil
	end,
	hasActor = function(player, questId, npc)
		local scene = scenes[player] and scenes[player][questId]
		return scene ~= nil and scene.Actors[npc] ~= nil
	end,
	gesture = function() end,
	teleport = function(player, where)
		player.At = if type(where) == "table" then where.Place else where
	end,
}

-- Clases: el doble "aprueba" al momento con un 8 (la clase de verdad necesita un jugador)
local classCalls = {}
mocks[ROOT .. "/server/Services/ClassService"] = {
	isRunning = function()
		return false
	end,
	start = function(player, spec, onDone)
		table.insert(classCalls, { Player = player, Subject = spec.Subject, Mode = spec.Mode })
		classCalls[#classCalls].Extra = spec.ExtraSeconds
		local grade = player.ClassGrade or 8
		task.delay(0.05, function()
			loadModule(ROOT .. "/server/LifeStory/StoryEvents").emit(player, "LessonCompleted", { Subject = spec.Subject, Mode = spec.Mode, Grade = grade })
			onDone({ Grade = grade, Correct = 4, Total = 5 })
		end)
		return true
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

-- stage = nil: personaje recién creado (playSeconds 0 -> nace bebé; > 0 -> jugador veterano, adulto)
local function newPlayer(name: string, stage: string?, playSeconds: number?)
	local player = { Name = name, DisplayName = name, Parent = true, Inbox = {}, Attributes = {}, Said = {}, Games = {}, Barks = {} }
	function player:SetAttribute(key, value)
		self.Attributes[key] = value
	end
	function player:GetAttribute(key)
		return self.Attributes[key]
	end
	profiles[player] = {
		Money = 0,
		Stats = { PlaySeconds = playSeconds or 0 },
		Life = { Stage = stage, AgeYears = 0, StageSeconds = 0 },
		Education = { Subjects = {}, Exams = {}, Degrees = {}, Attendance = 0 },
		Items = {},
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

local function cinematic(player, id: string): boolean
	for _, message in player.Inbox do
		if message.Kind == "Cinematic" and message.Payload.Id == id then
			return true
		end
	end
	return false
end

local function momentSting(player, key: string): any
	for _, message in player.Inbox do
		if message.Kind == "Moment" and message.Payload.TextKey == key then
			return message.Payload.Sting or "ninguno"
		end
	end
	return nil
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

print("\n▶ Personajes vivos: gestos y emociones al hablar")
local Emotion = loadModule(ROOT .. "/shared/LifeStory/Emotion")
check(Emotion.of({ S = "Nico", T = "¡Hola, {nombre}!" }) == "Wave" and Emotion.of({ S = "Nico", T = "Jajaja, qué bueno" }) == "Laugh" and Emotion.of({ S = "Omar", T = "¡Hemos ganado!" }) == "Cheer", "Saludan, se ríen y celebran según lo que dicen")
check(Emotion.of({ S = "Abu", T = "Lo siento mucho, cariño." }) == "Sad" and Emotion.of({ S = "Sara", T = "¿Vienes?" }) == "Ask" and Emotion.of({ S = "Sara", T = "Mira, allí está." }) == "Point", "Tristes, preguntando o señalando")
check(Emotion.of({ S = "Nico", T = "Es un día normal." }) == "Calm" and Emotion.of({ S = "Narrador", T = "¡Hola!" }) == nil and Emotion.of({ S = "Nico", T = "Hola", A = "Dance" }) == "Dance", "Tono normal, el narrador sin gestos y A = … manda sobre el texto")
check(Emotion.valid("Cheer") and Emotion.valid("Thinking") and not Emotion.valid("Volar"), "Solo se aceptan gestos que existen")

print("\n▶ Estaciones y tiempo")
local Seasons = loadModule(ROOT .. "/shared/Seasons")
check(Seasons.seasonOf(1) == "Primavera" and Seasons.seasonOf(8) == "Verano" and Seasons.seasonOf(15) == "Otono" and Seasons.seasonOf(22) == "Invierno" and Seasons.seasonOf(29) == "Primavera", "Las estaciones van en orden, una por semana de juego")
local seen, snowOutsideWinter, sameTwice = {}, false, true
for dayN = 1, 112 do
	for hour = 0, 23, 6 do
		local w = Seasons.weatherAt(dayN, hour + 0.5)
		seen[w] = (seen[w] or 0) + 1
		if w == "Nieve" and Seasons.seasonOf(dayN) ~= "Invierno" then
			snowOutsideWinter = true
		end
		if Seasons.weatherAt(dayN, hour + 0.5) ~= w then
			sameTwice = false
		end
	end
end
check(seen.Despejado and seen.Nublado and seen.Lluvia and seen.Tormenta and seen.Nieve and seen.Niebla and not snowOutsideWinter, "Hay sol, nubes, lluvia, tormenta, niebla y nieve (la nieve solo en invierno)")
check(sameTwice and seen.Despejado > seen.Tormenta, "El tiempo es igual para todos (no cambia al volver a preguntar) y hace sol más a menudo que tormenta")
check(Seasons.label("Otono", "Lluvia") == "🍂 Otoño · 🌧️ Lluvia", "Etiqueta de la estación y el tiempo")
local Conditions = loadModule(ROOT .. "/shared/LifeStory/Conditions")
local ctxInvierno = { Stage = "Nino", ClockTime = 12, Weekday = 1, Completed = {}, Flags = {}, Choices = {}, Discovered = {}, Season = "Invierno", Weather = "Nieve" }
check(Conditions.check({ Season = "Invierno", Weather = { "Nieve", "Lluvia" } }, ctxInvierno) and not Conditions.check({ Season = "Verano" }, ctxInvierno), "Las misiones pueden depender de la estación y del tiempo")

-- Una clave repetida en una tabla de Luau no da error: la segunda borra a la primera sin avisar
local duplicated = {}
for _, name in { "Quests", "Chapters", "Locations", "Cinematics", "Subjects", "Strings", "ShopItems" } do
	local seen = {}
	for line in fs.readFile(ROOT .. "/shared/LifeStory/" .. name .. ".luau"):gmatch("[^\n]+") do
		local key = line:match("^\t([%w_]+) = ") or line:match('^\t%["([^"]+)"%] = ')
		if key then
			if seen[key] then
				table.insert(duplicated, name .. "." .. key)
			end
			seen[key] = true
		end
	end
end
for _, key in duplicated do
	print("    repetida: " .. key)
end
check(#duplicated == 0, "Ninguna misión, capítulo, lugar ni texto está repetido")

local GameClock = loadModule(ROOT .. "/shared/GameClock")
local date = GameClock.fromDay(30, 13.5)
check(date.Weekday == 2 and date.Month == 2 and date.DayOfMonth == 2 and date.Hour == 13 and date.Minute == 30, "GameClock: día 30 = martes 2 del mes 2, 13:30")
check(GameClock.isBetween(22, 6, 23) and GameClock.isBetween(22, 6, 3) and not GameClock.isBetween(22, 6, 12), "GameClock: horarios nocturnos")

local StoryEvents = loadModule(ROOT .. "/server/LifeStory/StoryEvents")
local RoleService = loadModule(ROOT .. "/server/Services/RoleService")
local Service = loadModule(ROOT .. "/server/Services/LifeStoryService")
RoleService.init()
loadModule(ROOT .. "/server/Services/DialogueService").init()
loadModule(ROOT .. "/server/Services/MiniGameService").init()
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
local ana = newPlayer("Ana", nil, 3600) -- ya jugaba antes de la historia de vida
task.wait(0.2)
local data = profiles[ana]
check(data.Life.Stage == "Adulto", "Un jugador veterano sigue siendo adulto")
check(cinematic(ana, "Adulto_Llegada"), "Empieza el capítulo con su cinemática")
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
check(momentSting(ana, "MOMENT.PRIMER_HOGAR") == "Momento", "El momento suena con su efecto")
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
check(data.Story.Chapters.Adulto_NuevaVida ~= nil and cinematic(ana, "Adulto_TuCiudad"), "Capítulo terminado con su cinemática de cierre")
check(data.Story.Discovered.Playa and data.Story.Discovered.PlazaCentro, "Los lugares visitados quedan descubiertos")
local biography = {}
for _, event in data.Story.Events do
	table.insert(biography, event.K)
end
check(table.find(biography, "MOMENT.PRIMER_SUELDO") ~= nil and table.find(biography, "QUEST.REGION.OPT_PLAYA") ~= nil, "La biografía guarda momentos y decisiones")
check(pcall(serde.encode, "json", data), "Los datos se pueden guardar (JSON válido)")

print("\n▶ Fase 2: nacer, aprender a caminar, explorar la casa y crecer")
local leo = newPlayer("Leo") -- personaje nuevo
task.wait(0.2)
local leoData = profiles[leo]
check(leoData.Life.Stage == "Bebe" and leo:GetAttribute("LifeStage") == "Bebe", "Un personaje nuevo nace bebé")
check(cinematic(leo, "Bebe_Nacimiento"), "Empieza con la cinemática del nacimiento")
check(lastState(leo).ChapterMusic == "Nacimiento", "Suena la nana de fondo en casa")
check(leoData.Story.Active.Bebe_AprendeACaminar ~= nil, "Primera misión: aprende a caminar")
StoryEvents.emit(leo, "BabyStood", {})
for _ = 1, 4 do
	StoryEvents.emit(leo, "BabySteps", {})
end
task.wait(0.1)
state = lastState(leo)
check(state.Tracked.Args.count == 4 and state.Tracked.Args.total == 5, "La tarjeta cuenta los pasos (4/5)")
StoryEvents.emit(leo, "BabySteps", {})
task.wait(0.7)
state = lastState(leo)
check(state.Tracked.TextKey == "QUEST.BEBE_CAMINAR.S3" and leo:GetAttribute("StoryTarget") ~= nil, "Toca llegar hasta Abu, con línea guía hasta él")
StoryEvents.emit(leo, "Talk", { Npc = "Familia_Padre" })
task.wait(0.1)
check(leoData.Story.Active.Bebe_AprendeACaminar ~= nil, "Hablar con otra persona no cuenta como llegar hasta Abu")
StoryEvents.emit(leo, "Talk", { Npc = "Familia_Abu" })
task.wait(0.1)
check(cinematic(leo, "Bebe_PrimerosPasos") and leoData.Story.Active.Bebe_AprendeACaminar ~= nil, "Cinemática de primeros pasos (la historia espera a que acabe)")
task.wait(6.3)
check(leoData.Story.Completed.Bebe_AprendeACaminar ~= nil and received(leo, "Moment", "MOMENT.PRIMEROS_PASOS"), "Momento: 'Has dado tus primeros pasos'")
check(momentSting(leo, "MOMENT.PRIMEROS_PASOS") == "ninguno", "Sin efecto repetido (la cinemática ya tiene su música)")

StoryEvents.emit(leo, "BabyInteract", { Object = "Tele" })
leo.At = "HomeCocina"
task.wait(0.7)
state = lastState(leo)
check(state.Tracked.Children and state.Tracked.Children[1].Done and state.Tracked.Children[2].Done and not state.Tracked.Children[3].Done, "Explorar la casa: cocina y tele sí, bloques todavía no (en cualquier orden)")
StoryEvents.emit(leo, "BabyInteract", { Object = "Juguetes" })
task.wait(0.7)
state = lastState(leo)
check(state.Tracked.TextKey == "QUEST.BEBE_CASA.S2", "Después: pedir el biberón a la familia")
StoryEvents.emit(leo, "Talk", { Npc = "Familia_Padre" })
task.wait(0.1)
check(leoData.Story.Completed.Bebe_ExploraLaCasa ~= nil, "Casa explorada y familia conocida")
StoryEvents.emit(leo, "LookedOutside", {})
task.wait(0.3)
check(cinematic(leo, "Bebe_AnosDespues"), "Mirar por el ventanal lleva a la cinemática 'Han pasado varios años…'")
check(leoData.Life.Stage == "Nino" and leo:GetAttribute("LifeStage") == "Nino", "Ahora es niño")
check(leoData.Story.Chapters.Bebe_PrimerosPasos ~= nil, "Capítulo de bebé terminado")
check(cinematic(leo, "Cole01_Amanecer") and leoData.Story.Active.Cole01_PrimerDia ~= nil, "Empieza el colegio con la misión «El primer día» (amanece en Los Pinos)")
check(leoData.Life.AgeYears == 6 and leo:GetAttribute("AgeYears") == 6, "Tiene 6 años")
check(pcall(serde.encode, "json", leoData), "Los datos del bebé se pueden guardar (JSON válido)")

---------------------------------------------------------------------
-- Jugador automático: hace lo que pide el paso actual (habla, usa objetos, elige, llega a sitios)
--   player.Prefer = { "texto", … }  respuestas preferidas en los diálogos (si no, la primera)
--   player.Picks = { Clave = "Opcion" }  decisiones "en el mundo" (con quién sentarte…)
--   player.Skip = { Prop = true }        objetos que NO toca (para probar "ignorar a Mateo")
---------------------------------------------------------------------
local Quests = loadModule(ROOT .. "/shared/LifeStory/Quests")
local Subjects = loadModule(ROOT .. "/shared/LifeStory/Subjects")
local HOURS = Config.LifeStory.StageHours

local function preferAnswer(player)
	return function(_, options)
		for _, wanted in player.Prefer or {} do
			for i, option in options do
				if option:find(wanted, 1, true) then
					return i
				end
			end
		end
		return 1
	end
end

local function passes(player, condition)
	if not condition then
		return true
	end
	local story = profiles[player].Story
	for _, flag in condition.Flags or {} do
		if not story.Flags[flag] then
			return false
		end
	end
	for key, value in condition.Choices or {} do
		local choice = story.Choices[key]
		if not choice or choice.V ~= value then
			return false
		end
	end
	return true
end

local function questStep(player, questId)
	local prog = profiles[player].Story.Active[questId]
	if not prog then
		return nil
	end
	local steps = prog.Steps or Quests[questId].Steps
	return prog, steps[prog.Step]
end

local function mainStep(player)
	local story = profiles[player].Story
	for id in story.Active do
		if Quests[id] and Quests[id].Kind == "Main" then
			local prog, step = questStep(player, id)
			return id, prog, step
		end
	end
	return nil
end

local function doStep(player, questId, step, choice)
	local story = profiles[player].Story
	local quest = Quests[questId]
	local episodic = quest.Dialogues ~= nil
	local degree = story.Choices.Estudios and story.Choices.Estudios.V
	local function place(value)
		return Subjects.resolve(value, degree)
	end
	if step.Type == "Reach" or step.Type == "Class" then
		player.At = place(step.Place)
	elseif step.Type == "Talk" then
		if episodic then
			Service.interact(player, "Actor", questId, step.Npc)
		else
			StoryEvents.emit(player, "Talk", { Npc = step.Npc })
		end
	elseif step.Type == "Use" then
		if not (player.Skip and player.Skip[step.Prop]) then
			Service.interact(player, "Prop", questId, step.Prop)
		end
	elseif step.Type == "Event" then
		StoryEvents.emit(player, step.Event, table.clone(step.Match or {}))
	elseif step.Type == "Group" then
		local prog = story.Active[questId]
		for i, child in step.Steps do
			local skipped = child.Type == "Use" and player.Skip and player.Skip[child.Prop]
			if not (prog and prog.Sub and prog.Sub[tostring(i)]) and passes(player, child.If) and not skipped then
				doStep(player, questId, child, choice)
				if episodic and child.Type ~= "Reach" then
					break -- una conversación cada vez, como un jugador de verdad
				end
			end
		end
	elseif step.Type == "Wait" then
		day += 1 -- pasa un día de juego
	elseif step.Type == "Choice" then
		local pick = (player.Picks and player.Picks[step.Key]) or choice
		if type(pick) == "function" then
			pick = pick(profiles[player].Story)
		end
		local option = nil
		for _, candidate in step.Options do
			if candidate.Id == pick then
				option = candidate
			end
		end
		option = option or step.Options[1]
		if option.Npc then
			Service.interact(player, "Actor", questId, option.Npc)
		elseif option.Prop then
			Service.interact(player, "Prop", questId, option.Prop)
		else
			fromClient(player, "Choose", questId, pick or option.Id)
		end
	end
end

-- Juega hasta que se cumpla la condición (o se rinde tras muchos intentos)
local function playUntil(player, done: () -> boolean, choice: string?, maxSteps: number?): boolean
	player.Answer = preferAnswer(player)
	for _ = 1, maxSteps or 300 do
		if done() then
			return true
		end
		local id, _, step = mainStep(player)
		if id and step then
			doStep(player, id, step, choice)
		end
		task.wait(0.6)
	end
	return done()
end

-- Juega una misión concreta (secundarias y consecuencias)
local function playQuest(player, questId: string, maxSteps: number?): boolean
	player.Answer = preferAnswer(player)
	local story = profiles[player].Story
	for _ = 1, maxSteps or 120 do
		if story.Completed[questId] then
			return true
		end
		local _, step = questStep(player, questId)
		if step then
			doStep(player, questId, step)
		end
		task.wait(0.6)
	end
	return story.Completed[questId] ~= nil
end

local function said(player, fragment: string): boolean
	for _, text in player.Said do
		if text:find(fragment, 1, true) then
			return true
		end
	end
	return false
end

local function classesOf(player)
	local list = {}
	for _, call in classCalls do
		if call.Player == player then
			table.insert(list, call.Subject)
		end
	end
	return list
end

local function laterStarts(player)
	local set = {}
	for _, later in profiles[player].Story.Later or {} do
		if later.Start then
			set[later.Start] = later
		end
	end
	return set
end

-- Deja pasar horas de juego para las consecuencias diferidas
local function passTime(player, seconds: number)
	local story = profiles[player].Story
	story.Clock = (story.Clock or 0) + seconds
	task.wait(Config.LifeStory.RefreshSeconds + 0.6)
end

---------------------------------------------------------------------
print("\n▶ Misión 01 «El primer día» (casa, camino, entrada, colegio, clase, recreo, cena)")
lighting.ClockTime = 9
leo.Prefer = { "Ya estoy despierto", "sudadera", "¡Claro!", "Cereales", "Me alegro", "acompáñame", "Me encanta explorar", "experimentos", "Yo vigilo", "Mañana te sientas", "He hecho un amigo" }
leo.Picks = { Asiento = "Sara", GrupoRecreo = "Estudiantes" }
local scene1 = scenes[leo] and scenes[leo].Cole01_PrimerDia
check(scene1 and scene1.Actors.Familia and scene1.Actors.Abu, "Escena 1: {familia} te despierta en tu cuarto y Abu está en el salón")
check(leo.At == "HomeDormitorio", "Empiezas en tu dormitorio")
check(playUntil(leo, function()
	return leoData.Story.Completed.Cole01_PrimerDia ~= nil
end), "Misión 01 completa, de principio a fin")
local memories = leoData.Story.Memories
check(memories.PrimerDiaCole and memories.PrimerAmigo, "Recuerdos: «Tu primer día de colegio» y «tu primer amigo»")
check(leoData.Items.MochilaCole == 1 and leoData.Items.CromoSuerte == 1, "La mochila del cole y el cromo de la suerte están en la mochila (inventario)")
check(leoData.Story.Choices.Ropa.V == "Sudadera" and leoData.Story.Choices.Acompanante.V == "Familia", "Elegiste ropa y que te acompañaran")
check(leoData.Story.Flags.PaseADani and said(leo, "¡HALA! ¡Qué pase!"), "Minijuego del balón de Dani: pase acertado y Dani lo celebra")
check(leo.Emotions["¡HALA! ¡Qué pase! ¡Eres como los de la tele!"] == "Surprised", "Cada frase llega al cliente con su gesto (Dani, sorprendido)")
check(said(leo, "¿Fuiste tú quien le pasó el balón a mi hermano"), "Mateo recuerda el balón de su hermano (diálogo que depende de lo que hiciste)")
check(leoData.Story.Choices.Asiento.V == "Sara" and said(leo, "aquí delante se entiende todo"), "Te sientas junto a Sara (se elige tocando la silla)")
check(leoData.Story.Choices.Gusto.V == "Ciencia" and said(leo, "Tenemos que hablar"), "Te presentas: te gustan los experimentos")
check(leoData.Story.Choices.GrupoRecreo.V == "Estudiantes" and said(leo, "Estás dentro"), "En el recreo vas con Sara e Iker, que recuerdan lo que dijiste en clase")
check(classesOf(leo)[1] == "Matematicas", "Clase de Matemáticas jugable")
check(leoData.Story.Flags.AyudasteAMateo and (leoData.Story.NpcMemory.Mateo.Rel or 0) >= 15, "Ayudas a Mateo con sus libros: relación +")
check(said(leo, "Lo que te dije: el que ayuda nunca está solo"), "En la cena, Abu recuerda su consejo")
check(laterStarts(leo).Eco_MateoDibujo ~= nil, "Consecuencia programada: Mateo te buscará dentro de un rato")
check((leoData.Story.Traits.Responsabilidad or 0) >= 1 and (leoData.Story.Traits.Curiosidad or 0) >= 1, "Tus respuestas suben rasgos (responsabilidad, curiosidad…)")
check(received(leo, "Moment", "Tu primer día de colegio"), "Momento final: «Tu primer día de colegio»")
check(scenes[leo].Cole01_PrimerDia == nil, "Al terminar, sus actores y objetos se van")
check(pcall(serde.encode, "json", leoData), "Todo se puede guardar (JSON válido)")

task.wait(0.8)
local jornada = leoData.Story.Active.Nino_Jornada
check(jornada ~= nil and jornada.Steps and #jornada.Steps >= 4, "Hasta la siguiente misión, días de cole normales")
check(leoData.Story.Active.Cole02_Mochila == nil, "«La mochila desaparecida» espera su momento de la etapa")

print("\n▶ Consecuencia diferida: una hora después, Mateo te busca")
passTime(leo, 3700)
check(leoData.Story.Active.Eco_MateoDibujo ~= nil, "Pasada una hora de juego, empieza «Un regalo de Mateo»")
check(playQuest(leo, "Eco_MateoDibujo"), "Hablas con Mateo")
check(leoData.Items.DibujoMateo == 1, "Te regala su dibujo (va a tu mochila)")

print("\n▶ Misión 02 «La mochila desaparecida» (investigación, canastas, almacén, decisión)")
leo.Prefer = { "¿Y dónde van", "Gracias por contármelo", "Perdonarle" }
leoData.Life.StageSeconds = 0.09 * HOURS.Nino * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Cole02_Mochila ~= nil
end), "Misión 02 completa")
check(said(leo, "(Ya no está en tu inventario.)") and leoData.Items.MochilaCole == 1, "La mochila desaparece del inventario… y vuelve al final")
check(said(leo, "Fue Rubén. Bruno le dijo que lo hiciera"), "Mateo (tu amigo) te da una pista extra")
check(leoData.Story.Flags.PistaR and leoData.Story.Flags.PistaB, "Pistas del patio: la «R» y el llavero de la «B»")
local basket = nil
for _, spec in leo.Games do
	if spec.Title == "¡Mete 3 canastas!" then
		basket = spec
	end
end
check(basket and basket.Rounds == 8 and leoData.Story.Flags.CanastasAlex, "Minijuego: 3 canastas para que Álex hable")
check(leoData.Story.Choices.MochilaRuben.V == "Perdon" and leoData.Story.Flags.Ruben_Perdonado, "Decisión: perdonas a Rubén")
check(said(leo, "Un balón azul con forma de mochila"), "Lucía reacciona según tu decisión")
check(leoData.Story.Memories.MochilaPerdida ~= nil, "Recuerdo: «El día que desapareció tu mochila»")
check(laterStarts(leo).Eco_Ruben ~= nil and laterStarts(leo).Eco_Ruben.At >= leoData.Story.Clock + 9.9 * 3600, "Consecuencia programada para dentro de 10 horas de juego")

print("\n▶ Misión 03 «El grupo» (invitaciones, partido, parque, sueños, nombre del grupo)")
leo.Prefer = { "Como las pompas", "Delante", "Lo mejor ha sido jugar juntos", "Primero pido permiso", "Tiro lejano", "La hoja y la piña", "¡Invito yo", "Inventar cosas", "¡Claro! Mañana", "La Patrulla Valmar" }
leo.Picks = { Invitacion = "Sara" }
leo.Skip = { Columpio = true } -- en el parque: canasta, estanque y helados (3 de 4)
local moneyBefore = leoData.Money
leoData.Life.StageSeconds = 0.14 * HOURS.Nino * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Cole03_Grupo ~= nil
end), "Misión 03 completa")
check(leoData.Story.Choices.Invitacion.V == "Sara" and said(leo, "Registro científico número uno"), "Vas con Sara a seguir al escarabajo (3 sitios del colegio)")
local match = nil
for _, spec in leo.Games do
	if spec.Game == "Futbol" then
		match = spec
	end
end
check(match and match.Position == "Delantero", "Partido de fútbol jugable como delantero (la posición elegida cambia el minijuego)")
check(leoData.Story.Flags.PartidoGanado and said(leo, "¡HEMOS GANADO A BRUNO!"), "Ganáis el partido y el banquillo lo celebra")
check(said(leo, "Buen partido. En serio."), "Hugo se acerca (semilla de la misión 04)")
check(said(leo, "¿Amigos? ¿Ya tienes amigos?"), "Pides permiso en casa antes de ir al parque")
check(leoData.Money == moneyBefore - 8, "Invitas a helados a todos (8 $)")
check(leoData.Story.Choices.SuenoInfancia.V == "Ingenieria" and leoData.Story.Memories.SuenoDeMayor, "Tu sueño de mayor queda guardado (volverá en el instituto)")
check(leoData.Story.Choices.NombreGrupo.V == "La Patrulla Valmar" and said(leo, "¡La Patrulla Valmar! ¡Me encanta!"), "El grupo se llama «La Patrulla Valmar» y los amigos lo dicen")
check(leoData.Items.FotoGrupo == 1 and leoData.Items.CuadernoOmar == 1, "Foto del grupo y dibujo de Omar en la mochila")
check(cinematic(leo, "Cole03_Foto"), "Foto final (cinemática)")
check(leoData.Story.Memories.PrimerGrupo and leoData.Story.Memories.PrimerPartido, "Recuerdos: tu grupo y tu primer partido")

print("\n▶ Secundaria que nace de una conversación: el gato del colegio")
passTime(leo, 200)
check(leoData.Story.Active.Side_GatoDelCole ~= nil, "Omar y tú vais a buscar a Bigotes")
check(playQuest(leo, "Side_GatoDelCole"), "Seguís las huellas y lo encontráis")
check(said(leo, "¡Bigotes es mamá!") and leoData.Story.Memories.GatoDelCole, "¡Bigotes tenía gatitos! (recuerdo nuevo)")

print("\n▶ 10 horas de juego después: Rubén vuelve")
passTime(leo, 10 * 3600)
check(leoData.Story.Active.Eco_Ruben ~= nil, "Rubén aparece")
check(playQuest(leo, "Eco_Ruben"), "Hablas con Rubén")
check(said(leo, "Fuiste la única persona que me perdonó") and not said(leo, "Me acuerdo de cómo me gritaste"), "Su conversación depende de que le perdonaste hace 10 horas")

print("\n▶ Otro camino: ignorar a Mateo el primer día")
local noa = newPlayer("Noa", "Nino")
local noaData = profiles[noa]
task.wait(0.3)
noa.Prefer = { "Cinco minutitos", "dinosaurios", "Mejor no", "Tostadas", "Voy yo solo" }
noa.Picks = { Asiento = "Nico", GrupoRecreo = "Deportistas" }
noa.GameResult = { Hits = 0 } -- falla el pase a Dani
noa.Skip = { Libro1 = true, Libro2 = true, Libro3 = true, Libro4 = true }
local booksStep = nil
for i, step in Quests.Cole01_PrimerDia.Steps do
	if step.Timeout then
		booksStep = step
	end
end
local originalAfter = booksStep.Timeout.After
booksStep.Timeout.After = 2 -- en la prueba no se espera 45 s
check(playUntil(noa, function()
	return noaData.Story.Completed.Cole01_PrimerDia ~= nil
end), "Misión 01 completa por otro camino")
booksStep.Timeout.After = originalAfter
check(noaData.Story.Flags.FallastePase and said(noa, "se ha ido a la farola"), "Falla el pase: Dani se ríe y la historia sigue (nunca bloquea)")
check(noaData.Story.Flags.IgnorasteAMateo and (noaData.Story.NpcMemory.Mateo.Rel or 0) < 10, "Si no le ayudas, Mateo recoge solo sus cosas")
check(said(noa, "Mañana, si le ves solo, ve con él"), "En la cena, la familia te lo comenta")
check(not noaData.Story.Memories.PrimerAmigo and laterStarts(noa).Eco_MateoSolo ~= nil, "Sin «primer amigo»… pero con una segunda oportunidad programada")
passTime(noa, 3700)
check(noaData.Story.Active.Eco_MateoSolo ~= nil, "Una hora después, ves a Mateo comiendo solo")
check(playQuest(noa, "Eco_MateoSolo") and noaData.Story.Memories.SegundaOportunidad and noaData.Story.Flags.AyudasteAMateo, "Te sientas con él: ahora sí sois amigos")

print("\n▶ Misión 04 «Los malotes» (burlas, objeto robado, persecución, Hugo, decisión)")
leo.Prefer = { "Por lo menos nosotros", "Pedir ayuda a mi grupo" }
leo.Picks = {}
leo.Skip = {}
leoData.Life.StageSeconds = 0.19 * HOURS.Nino * 3600
local cromoAntes = leoData.Items.CromoSuerte
check(playUntil(leo, function()
	return leoData.Story.Completed.Cole04_Malotes ~= nil
end), "Misión 04 completa")
check(said(leo, "¿Mi cromo? ¿Dónde está mi cromo de la suerte?") and leoData.Items.CromoSuerte == cromoAntes, "Te quitan tu cromo de la suerte (el objeto que llevabas desde el primer día) y lo recuperas")
check(said(leo, "Salen disparados hacia el patio"), "Persecución: salen corriendo y les sigues")
check(said(leo, "Ramón pasa de largo"), "Te escondes de Ramón a tiempo")
check(said(leo, "Yo no quería. Bruno dijo") and said(leo, "¿«La isla de las mil llaves»?"), "Hugo no quería participar (y recuerda que viste su libro en el almacén)")
check(leoData.Story.Choices.Malotes.V == "Grupo" and leoData.Story.Flags.HugoConElGrupo and said(leo, "Somos cinco. Y estamos hartos."), "Decisión: tu grupo se planta contigo; Hugo se queda con vosotros")
check(leoData.Story.Memories.LosMalotes ~= nil and laterStarts(leo).Eco_Hugo ~= nil, "Recuerdo «Los malotes» y consecuencia programada con Hugo")
leo.Prefer = { "¿Por qué no te vienes" }
passTime(leo, 2 * 3600 + 100)
check(leoData.Story.Active.Eco_Hugo ~= nil and playQuest(leo, "Eco_Hugo"), "Dos horas después, Hugo te busca")
check(said(leo, "portero suplente") and leoData.Items.LibroPiratas == 1 and leoData.Story.Memories.HugoAmigo, "Te regala su libro de piratas y se une al grupo")

print("\n▶ Misión 05 «La venganza de la mochila» (pistas, acusar, confesión)")
leo.Prefer = { "Vente con nosotros" }
leo.Picks = {
	Culpable = function(story)
		return if story.Flags.AcusasteABruno then "Iker" else "Bruno" -- primero se equivoca
	end,
}
leoData.Life.StageSeconds = 0.25 * HOURS.Nino * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Cole05_Venganza ~= nil
end), "Misión 05 completa")
check(said(leo, "¡Esta vez NO he sido yo!") and not said(leo, "Tú hablaste conmigo"), "Todos culpan a Bruno (y no dice «tú hablaste conmigo»: en la misión 04 fuiste con tu grupo, no a hablar con él)")
check(said(leo, "Lunes, 11:05"), "Pistas: el registro de salidas al baño")
check(leoData.Story.Flags.AcusasteABruno and said(leo, "¡Por una vez que no hago nada!"), "Acusar a quien no era tiene consecuencias (y la decisión sigue abierta)")
check(leoData.Story.Choices.Culpable.V == "Iker" and said(leo, "nadie me escucha"), "Descubres a Iker y por qué lo hizo")
check(leoData.Story.Flags.IkerEnElGrupo and leoData.Items.Lupa == 1 and said(leo, "Me acusaste sin pruebas"), "Iker entra en el grupo, Lucía te da su lupa y Bruno se acuerda")

print("\n▶ Misión 06 «El examen imposible» (apuntes, estudiar, la noche antes, examen)")
leo.Prefer = { "Pedir ayuda a Abu" }
leo.Picks = { CompaneroEstudio = "Mateo" }
leo.ClassGrade = 3 -- esta vez sale mal
leoData.Life.StageSeconds = 0.31 * HOURS.Nino * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Cole06_Examen ~= nil
end), "Misión 06 completa")
check(said(leo, "Más o menos.") and said(leo, "Eso significa que no."), "Estudias con Mateo (diálogo con personalidad)")
check(said(leo, "contábamos con garbanzos") and leoData.Story.Flags.EstudiasteMas, "La noche antes, Abu te ayuda a repasar")
local examExtra = nil
for _, call in classCalls do
	if call.Player == leo and call.Mode == "Examen" then
		examExtra = call.Extra
	end
end
check(examExtra == 6, "Haber estudiado da 6 segundos más por pregunta en el examen")
check(leoData.Story.Flags.SuspendisteExamen and said(leo, "un examen no dice quién eres"), "Suspendes… y Lucía te ofrece otra oportunidad")
check(leoData.Items.ApuntesBiblioteca == nil, "Devuelves los apuntes a Marisa")
leo.ClassGrade = 7
passTime(leo, 90)
check(leoData.Story.Active.Cole06b_Recuperacion ~= nil and playQuest(leo, "Cole06b_Recuperacion"), "Recuperación con Lucía")
check(said(leo, "No era que no pudieras") and leoData.Story.Memories.CasiSuspendo, "Apruebas la recuperación: recuerdo «Aquel examen que casi suspendes»")
leo.ClassGrade = nil

print("\n▶ Misión 07 «La excursión» (autobús, granja, alguien se pierde, foto)")
leo.Prefer = { "Le das la mano" }
leo.Picks = { AsientoBus = "Mateo" }
leoData.Life.StageSeconds = 0.45 * HOURS.Nino * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Cole07_Excursion ~= nil
end), "Recados y misión 07 completos")
check(leoData.Story.Completed.Nino_Recados ~= nil, "Los recados van antes de la excursión")
check(said(leo, "Nunca he ido de excursión") and said(leo, "Mateo pega la nariz a la ventana"), "Te sientas con Mateo en el autobús (y el viaje lo recuerda)")
check(cinematic(leo, "Cole07_Viaje") and cinematic(leo, "Cole07_Foto"), "Cinemáticas del viaje y de la foto")
check(said(leo, "Falta Mateo") and said(leo, "«¡Le sigo!»"), "¡Falta Mateo! Las pistas llevan al granero")
check(leoData.Story.Choices.Rescate.V == "Juntos" and said(leo, "Copito os sigue"), "Le das la mano y volvéis juntos")
check(leoData.Items.FotoExcursion == 1 and leoData.Story.Memories.PrimeraExcursion ~= nil and said(leo, "empieza el torneo del colegio"), "Foto de la excursión, recuerdo, y Andrés anuncia el torneo")

print("\n▶ Misión 08 «El torneo» (deporte, capitán, clasificación, grada, final)")
leo.Prefer = { "Omar. Hace falta", "Que juegue todo el mundo", "Me tiemblan", "Que gane el mejor", "Dar la mano" }
leo.Picks = { Deporte = "Atletismo" }
leo.GameResult = { Hits = 1 } -- esta vez las carreras salen mal
local circuitos = 0
for _, call in classCalls do
	if call.Player == leo and call.Mode == "Circuito" then
		circuitos += 1
	end
end
leoData.Life.StageSeconds = 0.55 * HOURS.Nino * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Cole08_Torneo ~= nil
end), "Misión 08 completa")
local circuitosDespues = 0
for _, call in classCalls do
	if call.Player == leo and call.Mode == "Circuito" then
		circuitosDespues += 1
	end
end
check(said(leo, "ahora lo haremos A PROPÓSITO") and circuitosDespues == circuitos + 1, "Eliges atletismo: entrenas el circuito de la pista")
check(not said(leo, "Entrenamiento: tiros libres") and leoData.Story.Choices.Capitan.V == "Omar" and leoData.Story.Choices.Estrategia.V == "Todos", "Omar es el capitán y juega todo el mundo")
check(said(leo, "pasáis como mejor segundo"), "Pierdes la clasificación pero pasas como mejor segundo")
check(said(leo, "Mira, el detective") and said(leo, "Juego con ellos. Y ya está."), "Bruno recuerda que le acusaste; Hugo se planta")
check(leoData.Story.Flags.TorneoPerdido and leoData.Items.MedallaPlata == 1 and said(leo, "Me das la mano después de perder"), "Final perdida: medalla de plata y das la mano")
check(leoData.Story.Memories.PrimerTorneo ~= nil and said(leo, "la puerta del fondo del pasillo"), "Recuerdo del torneo y el rumor de la sala cerrada")
leo.GameResult = nil

print("\n▶ Misión 09 «El misterio del colegio» (nota, pistas, candado, la foto, Lucía)")
leo.Prefer = { "Guardar el secreto" }
leo.Picks = {
	Entrar = "Colarse",
	Candado = function()
		return if said(leo, "Lo has puesto al revés") then "199813" else "131998" -- primero se equivoca
	end,
	Capsula = "Pregunta",
}
leoData.Life.StageSeconds = 0.63 * HOURS.Nino * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Cole09_Misterio ~= nil
end), "Misión 09 completa")
check(said(leo, "NO ENTRES EN LA SALA DEL FONDO") and said(leo, "Caso: la sala del fondo"), "La nota en la taquilla (e Iker abre un caso)")
check(said(leo, "El número 13") and said(leo, "Concurso de Ciencias · 4.º A · 1998"), "Pistas: la llave 13 y el año 1998")
check(leoData.Story.Choices.Candado.V == "199813" and said(leo, "¡CLAC!"), "Un código mal no abre; el bueno sí")
check(said(leo, "¡Ajá! ¡Os pillé!") and said(leo, "¡es LUCÍA!"), "Te cuelas, Ramón te pilla… y encontráis la foto de Lucía")
check(leoData.Story.Flags.SecretoLucia and leoData.Story.Flags.CapsulaDelTiempo and leoData.Story.Choices.Capsula.V == "Pregunta", "Guardas el secreto y metes tu pregunta en la cápsula del tiempo")
check(leoData.Items.FotoLucia == 1 and leoData.Story.Memories.MisterioColegio ~= nil, "Copia de la foto y recuerdo del misterio")

print("\n▶ Misión 10 «El festival» (tarea, imprevistos, Bruno, escenario)")
leo.Prefer = { "Te agachas", "Le ayudas", "Subo a contar chistes" }
leo.Picks = { Festival = "Teatro" }
leo.Skip = { Farolillos = true } -- deja los farolillos a otros: resuelve los otros tres imprevistos
leoData.Life.StageSeconds = 0.73 * HOURS.Nino * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Cole10_Festival ~= nil
end), "Misión 10 completa")
check(said(leo, "Nico hará de loro") and said(leo, "La obra de Hugo arranca aplausos"), "Eliges el teatro con Hugo (solo si Hugo está en tu grupo) y la obra sale")
check(said(leo, "Alguien ha desenchufado el cable") and leoData.Story.Choices.NinaPerdida.V == "Juntos", "Imprevistos: el altavoz y la niña perdida")
check(leoData.Story.Choices.FestivalBruno.V == "Ayudar" and said(leo, "Gracias. En voz baja.") and said(leo, "…Casi. Gracias a"), "Ayudas a Bruno con su puesto (y lo dice delante de todos)")
check(leoData.Story.Flags.SubesAlEscenario and said(leo, "silba con dos dedos"), "Subes al escenario con Nico y el público aplaude")
check(cinematic(leo, "Cole10_Festival") and leoData.Items.FotoFestival == 1 and leoData.Story.Memories.ElFestival ~= nil, "Cinemática, foto del festival y recuerdo")
leo.Skip = {}

print("\n▶ Misión 11 «El proyecto final» (equipo, investigar, desastre, presentación)")
leo.Prefer = { "Un museo del colegio", "Presento delante", "Juntar las dos ideas", "Llamar al equipo" }
leo.Picks = { Companero = "Sara" }
leoData.Life.StageSeconds = 0.83 * HOURS.Nino * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Cole11_Proyecto ~= nil
end), "Misión 11 completa")
check(said(leo, "Ideas que no le he contado a nadie") and leoData.Story.Choices.Tema.V == "Museo" and leoData.Story.Choices.Rol.V == "Presentador", "Con Sara: el museo del colegio (solo si abriste la sala cerrada) y presentas tú")
check(said(leo, "Te puedo prestar la foto de mi clase") and said(leo, "Hay que hacerlo exacto"), "Investigas (Abu fue a tu colegio) y el equipo discute")
check(leoData.Story.Choices.Discusion.V == "Juntar" and leoData.Story.Flags.ArregloEnEquipo and said(leo, "Y… esta es la tirita"), "Juntáis ideas y arregláis la maqueta rota en equipo")
local projectExtra = nil
for _, call in classCalls do
	if call.Player == leo and call.Subject == "Ciencias" and call.Mode == "Examen" then
		projectExtra = call.Extra
	end
end
check(projectExtra == 5, "La maqueta bonita da 5 segundos más por pregunta del jurado")
check(leoData.Story.Flags.ProyectoPremiado and leoData.Items.Maqueta == 1 and leoData.Story.Memories.ProyectoFinal ~= nil, "Sobresaliente: proyecto premiado, maqueta y recuerdo")
passTime(leo, 3700)
check(leoData.Story.Active.Eco_Periodico ~= nil and playQuest(leo, "Eco_Periodico") and said(leo, "abrirá el museo"), "Una hora después, tu proyecto sale en el periódico")

print("\n▶ Misión 12 «El último día» (recuerdos reales, cápsula, despedidas, instituto)")
check(leoData.Life.AgeYears >= 8 and received(leo, "Moment", "MOMENT.CUMPLEANOS"), "El tiempo jugado hace crecer: ya tiene 8 años o más")
leo.Prefer = { "¿empezamos de cero?", "seguimos juntos" }
leo.Picks = {}
leoData.Life.StageSeconds = 0.95 * HOURS.Nino * 3600
check(playUntil(leo, function()
	return leoData.Life.Stage == "Adolescente"
end), "Misión 12 completa: fin de primaria")
check(said(leo, "✨ Te sentaste junto a Sara") and said(leo, "Medalla de plata… y Abu"), "Los recuerdos son los de tu partida (el asiento del primer día, la plata del torneo)")
check(said(leo, "✨ Aquel examen que casi suspendes") and not said(leo, "✨ Estudiaste con Sara"), "Solo aparecen los recuerdos que viviste")
check(said(leo, "Tu pregunta: «¿Seguimos siendo amigos?»"), "Se abre la cápsula: tu pregunta de la misión 09")
check(said(leo, "Y gracias por guardar mi secreto") and said(leo, "Todavía me acuerdo de cuando me acusaste"), "Lucía y Bruno se despiden según vuestra historia")
check(leoData.Story.Choices.AdiosBruno.V == "DeCero" and leoData.Story.Choices.Promesa.V == "Juntos", "Empezar de cero con Bruno y la promesa del grupo")
check(leoData.Items.DiplomaPrimaria == 1 and leoData.Items.Llavero13 == 1 and leoData.Story.Memories.UltimoDiaCole ~= nil, "Diploma, llavero de Ramón y recuerdo del último día")
for _, questId in { "Cole01_PrimerDia", "Cole02_Mochila", "Cole03_Grupo", "Cole04_Malotes", "Cole05_Venganza", "Cole06_Examen", "Nino_Recados", "Cole07_Excursion", "Cole08_Torneo", "Cole09_Misterio", "Cole10_Festival", "Cole11_Proyecto", "Cole12_UltimoDia" } do
	check(leoData.Story.Completed[questId] ~= nil, "  hecha: " .. questId)
end
check(received(leo, "Moment", "MOMENT.DIA_COLE"), "Los días de cole terminados quedan como momentos")
check(cinematic(leo, "Cole12_Foto") and cinematic(leo, "Nino_FinPrimaria") and cinematic(leo, "Nino_AInstituto"), "Cinemáticas: foto con tu grupo, fin de primaria y paso al instituto")
task.wait(0.8)
check(leoData.Life.AgeYears == 13 and leoData.Story.Active.Ins01_NuevoInstituto ~= nil, "Con 13 años empieza el instituto")
leoData.Life.StageSeconds = 0

print("\n▶ Instituto 01 «El nuevo instituto» (parada, veterano, Bruno, Leire)")
leo.Prefer = { "Puedo ir por mi cuenta", "Das una vuelta", "¿Me enseñas qué fotos" }
leo.Picks = { Veterano = "Creer", SitioInstituto = "Bruno" }
check(playUntil(leo, function()
	return leoData.Story.Completed.Ins01_NuevoInstituto ~= nil
end), "Instituto 01 completa")
check(said(leo, "Pero en el recreo sí. ¡Lo prometimos!"), "Tus amigos recuerdan la promesa del último día")
check(leoData.Story.Choices.Veterano.V == "Creer" and said(leo, "¡Todos los años alguien cae!"), "Caes en la broma del «ascensor de alumnos»")
check(said(leo, "Yo también estoy en 1.º C"), "Iker (que se unió al grupo en la misión 05) está en tu clase")
check(said(leo, "Aquí hay sitio. Si quieres. De cero") and leoData.Story.Choices.SitioInstituto.V == "Bruno", "Bruno te ofrece sitio (te despediste con «empezamos de cero») y te sientas con él")
check(said(leo, "Leire comiendo sola") and leoData.Story.Flags.ConocesALeire and said(leo, "Esta es mi antigua calle"), "En el recreo encuentras a Leire sola y te acercas")
check(leoData.Items.CarnetInstituto == 1 and leoData.Story.Memories.PrimerDiaInstituto ~= nil, "Carnet del instituto y recuerdo del primer día")
passTime(leo, 2 * 3600 + 100)
check(leoData.Story.Active.Eco_Leire ~= nil and leoData.Story.Active.Eco_LeireSola == nil and playQuest(leo, "Eco_Leire"), "Dos horas después, Leire te busca")
check(leoData.Items.FotoDeLeire == 1, "Te regala una foto del primer día")

print("\n▶ Instituto 02 «Los clubes» (feria, periódico, murales, el sábado)")
leo.Prefer = { "Convencerla para pedir permiso", "Intentar las dos cosas" }
leo.Picks = { Club = "Periodico" }
leoData.Life.StageSeconds = 0.13 * HOURS.Adolescente * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Ins02_Clubes ~= nil
end), "Instituto 02 completa")
check(said(leo, "Tu primer caso: los murales") and said(leo, "Hay purpurina pegada en la pintura") and said(leo, "Soy yo. Lo hago porque el patio era gris"), "Periódico: investigas los murales y descubres a Vega")
check(leoData.Story.Choices.Reportaje.V == "Permiso" and said(leo, "«Una alumna pinta el instituto»"), "Convences a Vega para pedir permiso")
check(leoData.Story.Choices.Sabado.V == "Ambas" and said(leo, "Sale el primer número de «La Voz del Campus»") and said(leo, "¡Justo a tiempo para la tarta!"), "Llegas al evento del club y al cumpleaños de Nico")
check(leoData.Items.InsigniaClub == 1 and leoData.Story.Memories.PrimerClub ~= nil, "Insignia del club y recuerdo")

print("\n▶ Instituto 03 «¿Qué quieres ser?» (ocho profesiones, tu sueño, orientación)")
leo.Prefer = { "Sí. Me lo imagino", "Añadir triángulos", "Tengo más dudas" }
leo.Picks = {}
leoData.Life.StageSeconds = 0.26 * HOURS.Adolescente * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Ins03_QueQuieresSer ~= nil
end), "Instituto 03 completa")
local visitas = 0
for _, flag in { "Interes_Medicina", "Interes_Ingenieria", "Interes_Derecho", "Interes_Economia", "Interes_Oficio", "Interes_Cocina", "Interes_Deporte", "Interes_Audiovisual" } do
	if leoData.Story.Flags[flag] then
		visitas += 1
	end
end
check(visitas == 4 and leoData.Story.Flags.Interes_Ingenieria, "Visitas cuatro profesiones y marcas lo que te interesa")
check(said(leo, "querías «inventar cosas que no existen»") and not said(leo, "dijiste que querías salvar vidas"), "Tu sueño de la infancia (inventar) aparece en el laboratorio, y no en el hospital")
check(said(leo, "Aguanta dos kilos y medio") and said(leo, "Sofía me ha dicho que tus puentes"), "El puente del laboratorio y Carmen lo comenta")
check(leoData.Story.Choices.Orientacion.V == "Dudas" and leoData.Items.CuadernoProfesiones == 1 and leoData.Story.Memories.QueQuieresSer ~= nil, "Sales con dudas (y es bueno), cuaderno y recuerdo")

print("\n▶ La pandilla 1 «Las malas compañías» (camino del bien: frenar a Nerea)")
leo.Prefer = {}
leo.Picks = { Pellas = "Nerea" }
leoData.Life.StageSeconds = 0.31 * HOURS.Adolescente * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Pan1_MalasCompanias ~= nil
end), "La pandilla 1 completa")
check(said(leo, "No eres como los demás pringados") and said(leo, "Nadie mira mis dibujos"), "Rayo te invita a hacer pellas; convences a Nerea de que no vaya")
check(leoData.Story.Flags.AmigaNerea and leoData.Story.Flags.RechazasteLaPandilla and not leoData.Story.Flags.HicistePellas, "Rechazas la pandilla")
check(leo:GetAttribute("Camino") == "Responsable" and said(leo, "Hiciste bien en volver"), "Tu reputación: persona responsable (y Bruno, que ya fue «el malo», te lo dice)")

print("\n▶ La pandilla 2 «La noche del supermercado» (intentas frenarles)")
leo.Prefer = { "No lo hagáis" }
leoData.Life.StageSeconds = 0.37 * HOURS.Adolescente * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Pan2_LaNoche ~= nil
end), "La pandilla 2 completa")
check(leoData.Story.Choices.Plan.V == "Frenar" and said(leo, "Esta vez me quedo en casa") and not leoData.Story.Flags.Hurto, "Intentas frenarles: Nerea se queda en casa")
check(said(leo, "Gracias por lo de esta tarde") and said(leo, "Rayo… Rayo no está bien"), "A Rayo le pillan; Nerea te cuenta que en su casa no hay nadie")

print("\n▶ Instituto 04 «El primer empleo» (perfil, ofertas, entrevista, jornada, sueldo)")
leo.Prefer = { "Una cámara, como la de Leire", "Soy responsable", "No, pero aprendo rápido", "Le pido perdón", "Lo cuentas tal cual", "Una parte para ti" }
leo.Picks = { Empleo = "Barista" }
leoData.Life.StageSeconds = 0.45 * HOURS.Adolescente * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Ins04_PrimerEmpleo ~= nil
end), "Instituto 04 completa")
check(leoData.Story.Choices.Meta.V == "Camara" and said(leo, "Tu club también cuenta"), "Quieres una cámara; Carmen te ayuda con el perfil (tu club cuenta)")
check(leoData.Story.Choices.Empleo.V == "Barista" and said(leo, "Siéntate. Entrevista rápida") and not leoData.Story.Flags.MentisteEntrevista, "Entrevista con Lola diciendo la verdad")
check(said(leo, "¡Puntual! Así me gusta") and said(leo, "Y el cliente de la mesa es… Bruno"), "Llegas puntual y en mitad del turno se te cae la bandeja delante de Bruno")
check(leoData.Story.Flags.BuenTrabajo and leoData.Story.Choices.Sueldo.V == "Mitad", "Lo cuentas y lo arreglas; guardas la mitad del sueldo")
check(leoData.Items.PrimerSobre == 1 and leoData.Story.Memories.PrimerSueldo ~= nil, "Sobre del primer sueldo y recuerdo")
passTime(leo, 3 * 3600 + 100)
check(leoData.Story.Active.Eco_Carta ~= nil and playQuest(leo, "Eco_Carta") and said(leo, "Firma: Lola") and leoData.Items.CartaRecomendacion == 1, "Tres horas después, carta de recomendación de Lola (no mentiste)")

print("\n▶ La pandilla 3 «El cruce de caminos» (salvar a Rayo)")
leo.Prefer = { "Porque eres mi amigo" }
leo.Picks = { Camino = "Salvar" }
leoData.Life.StageSeconds = 0.53 * HOURS.Adolescente * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Pan3_Cruce ~= nil
end), "La pandilla 3 completa")
check(said(leo, "Cincuenta pavos por tarde") and said(leo, "Me voy de la pandilla"), "Rayo te ofrece el negocio de camisetas falsas; Nerea quiere salir")
check(said(leo, "Que venga mañana a las ocho") and said(leo, "Eres la única persona que no me ha dejado tirado") and leoData.Story.Flags.RayoCambia, "Consigues que Tomás le dé una oportunidad a Rayo en su taller")
check(leoData.Story.Flags.Camino_Trabajador and not leoData.Story.Flags.Camino_Delincuente and said(leo, "Nunca te dejaste arrastrar"), "Tu camino: el de una persona trabajadora (y nunca te dejaste arrastrar)")
leo.Picks = {}

print("\n▶ Instituto 05 «El rumor» (la foto de Omar, investigar, Nico, Darío)")
leo.Prefer = { "Escribes en el grupo", "Te creo. Pero ayúdame", "Te lo llevas aparte", "Bórrala y pídele perdón", "Borré la foto del grupo" }
leo.Picks = {}
leoData.Life.StageSeconds = 0.63 * HOURS.Adolescente * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Ins05_ElRumor ~= nil
end), "Instituto 05 completa")
check(leoData.Story.Choices.Foto.V == "Frenar" and said(leo, "La foto deja de moverse"), "Plantas cara en el grupo de clase y la foto deja de circular")
check(said(leo, "es Nico.") and leoData.Story.Choices.Bruno.V == "Confiar" and said(leo, "Darío Ruiz. D. R."), "Pistas: la compartió Nico; confías en Bruno y te dice quién la hizo")
check(leoData.Story.Choices.HablasNico.V == "Privado" and said(leo, "Quería que se rieran conmigo"), "Hablas con Nico aparte")
check(leoData.Story.Choices.Dario.V == "Perdon" and said(leo, "La he borrado. Fue una idiotez."), "Darío borra la foto y pide perdón")
check(said(leo, "¿Fuiste tú? Leire me dijo") and said(leo, "He hecho pulseras para todos"), "Consuelas a Omar en el banco y vuelve a clase")
check(leoData.Items.PulseraGrupo == 1 and leoData.Story.Memories.ElRumor ~= nil, "Pulsera del grupo y recuerdo")
passTime(leo, 3 * 3600 + 100)
check(leoData.Story.Active.Eco_Nico ~= nil and playQuest(leo, "Eco_Nico") and said(leo, "Me hiciste pensar sin hacerme quedar mal"), "Tres horas después, Nico te da las gracias")

print("\n▶ Instituto 06 «La gran decisión» (planes, Carmen, selectividad, elegir, graduación)")
leo.Prefer = {}
leo.Picks = { Estudios = "Ingenieria" }
leoData.Life.StageSeconds = 0.91 * HOURS.Adolescente * 3600
check(playUntil(leo, function()
	return leoData.Life.Stage == "AdultoJoven"
end), "Instituto terminado")
check(said(leo, "Lola me ha dicho que si termino") and said(leo, "Por decírmelo a la cara, aparte."), "Los planes de tus amigos (Nico se acuerda del rumor)")
check(said(leo, "Sofía todavía habla de tu puente") and said(leo, "Y tu primer trabajo de verano"), "Carmen repasa tus intereses y tu primer trabajo")
check(said(leo, "¡La persona de los triángulos!"), "En la jornada de puertas abiertas, Sofía te reconoce")
local selectividadExtra = nil
for _, call in classCalls do
	if call.Player == leo and call.Subject == "Tecnologia" and call.Mode == "Examen" then
		selectividadExtra = call.Extra
	end
end
check(selectividadExtra == 5, "Estudiar da 5 segundos más por pregunta en la selectividad")
check(leoData.Story.Choices.Estudios and leoData.Story.Choices.Estudios.V == "Ingenieria" and leoData.Story.Flags.VaALaUniversidad and said(leo, "¡Ingeniería! Siempre desmontabas"), "Elige estudiar Ingeniería")
check(said(leo, "Algunos esperasteis un ascensor") and leoData.Items.OrlaInstituto == 1 and leoData.Story.Memories.LaGranDecision ~= nil, "Graduación del instituto: orla y recuerdo")
check(cinematic(leo, "Adol_Selectividad"), "Cinemática de selectividad")
task.wait(0.8)
check(leoData.Story.Active.Uni01_PrimerDia ~= nil and cinematic(leo, "Uni_PrimerDia"), "Empieza la universidad con su cinemática")

local function lastExtra(subject: string, mode: string): number?
	local extra = nil
	for _, call in classCalls do
		if call.Player == leo and call.Subject == subject and call.Mode == mode then
			extra = call.Extra
		end
	end
	return extra
end

print("\n▶ Universidad 01 «Primer día en el campus» (el reloj, Luca, tu facultad, Beltrán)")
leo.Prefer = { "Lo voy a cuidar" }
leo.Picks = { ComidaUni = "Luca" }
leoData.Life.StageSeconds = 0
check(playUntil(leo, function()
	return leoData.Story.Completed.Uni01_PrimerDia ~= nil
end), "Universidad 01 completa")
check(said(leo, "te da un reloj viejo") and leoData.Items.RelojAbu == 1, "{abu} te regala su reloj")
check(said(leo, "Facultad de Ingeniería. Física el primer día") and table.find(classesOf(leo), "Fisica") ~= nil, "El horario y la clase son los de tu carrera (Ingeniería)")
check(said(leo, "Juntos otra vez."), "Mateo (tu primer amigo) estudia Ingeniería contigo")
check(said(leo, "me ha dado croquetas gratis") and said(leo, "Por eso me hice voluntario"), "Descubres el campus y comes con Luca")
check(said(leo, "Me han llamado «el nuevo»") and leoData.Items.CarnetUniversitario == 1 and leoData.Story.Memories.PrimerDiaUni ~= nil, "Por la noche, el grupo de siempre por mensajes; carnet y recuerdo")

print("\n▶ Universidad 02 «El proyecto» (un grupo con personalidades)")
leo.Prefer = { "No tienes que cargar", "Coordinar no es mandar", "Hacemos las reuniones por la mañana", "¿Y si haces la música", "Cada uno en lo que se le da bien" }
leo.Picks = {
	Gestion = function()
		return if said(leo, "En la vida no se eligen los compañeros") then "Hablar" else "Cambiar" -- primero pide cambiarse
	end,
}
leoData.Life.StageSeconds = 0.19 * HOURS.AdultoJoven * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Uni02_ElProyecto ~= nil
end), "Universidad 02 completa")
check(said(leo, "diseñar un puente peatonal"), "El proyecto es de tu carrera")
check(said(leo, "En la vida no se eligen los compañeros") and leoData.Story.Choices.Gestion.V == "Hablar", "Pedir cambiar de grupo no se puede; decides hablar con cada uno")
check(said(leo, "Tengo una beca") and said(leo, "Es mi hermano") and said(leo, "Lo mío es esto"), "Descubres qué le pasa a cada uno")
check(leoData.Story.Flags.EquipoUnido and lastExtra("Calculo", "Examen") == 5, "Equipo unido: 5 segundos más en la presentación")
check(said(leo, "Se nota un equipo detrás") and leoData.Items.FotoEquipoUni == 1 and leoData.Story.Memories.ElProyectoUni ~= nil, "Sobresaliente, foto del grupo cuatro y recuerdo")
passTime(leo, 3 * 3600 + 100)
check(leoData.Story.Active.Eco_Concierto ~= nil and playQuest(leo, "Eco_Concierto") and said(leo, "Voy a terminar la carrera"), "Tres horas después, el concierto de Pablo")

print("\n▶ Universidad 03 «El primer trabajo» (perfil, ofertas, Alba, decir que no)")
leo.Prefer = { "Las fracciones con dinosaurios", "Decir que no, con educación" }
leo.Picks = { TrabajoUni = "Clases" }
leoData.Life.StageSeconds = 0.37 * HOURS.AdultoJoven * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Uni03_PrimerTrabajo ~= nil
end), "Universidad 03 completa")
check(said(leo, "Valía oro, sí."), "La carta de recomendación del instituto sirve en tu perfil")
check(leoData.Story.Choices.TrabajoUni.V == "Clases" and said(leo, "¡UN SIETE!"), "Clases particulares: Alba aprueba fracciones con dinosaurios")
check(not leoData.Story.Flags.CubristeTurno and lastExtra("Fisica", "Examen") == 5, "Dices que no a tiempo y llegas al examen con repaso (5 s más)")
check(leoData.Items.ContratoTrabajo == 1 and leoData.Story.Memories.PrimerTrabajoUni ~= nil and said(leo, "Te he hecho un dibujo"), "Contrato, recuerdo y el dibujo de Alba")

print("\n▶ Universidad 04 «Las prácticas» (según tu carrera, el error del informe)")
leo.Prefer = { "Decírselo a tu tutor" }
leo.Picks = {}
leoData.Life.StageSeconds = 0.56 * HOURS.AdultoJoven * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Uni04_Practicas ~= nil
end), "Universidad 04 completa")
check(said(leo, "¡La persona de los triángulos! Ahora trabajo para TecnoVal"), "Sofía, la de la semana de las profesiones, es tu tutora de Ingeniería")
check(said(leo, "Amortiguadores de masa") and not said(leo, "Sesenta años, fumador"), "El caso es de tu carrera (la pasarela del río), no de otra")
check(leoData.Story.Choices.ErrorInforme.V == "Decir" and said(leo, "Así se construyen puentes que no se caen") and lastExtra("PracticaIngenieria", "Practica") == 4, "Confiesas tu error: la tutora lo valora (y tienes 4 s más)")
check(leoData.Story.Flags.OfertaTrabajo and leoData.Items.InformePracticas == 1 and leoData.Story.Memories.Practicas ~= nil, "Oferta de trabajo para cuando termines, informe y recuerdo")

print("\n▶ Universidad 05 «Tu primer piso» (independizarte, la mudanza, {abu})")
leo.Prefer = { "Me da un poco de miedo", "Habláis y hacéis un reparto justo" }
leo.Picks = { CompiPiso = "Luca" }
leoData.Life.StageSeconds = 0.73 * HOURS.AdultoJoven * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Uni05_PrimerPiso ~= nil
end), "Universidad 05 completa")
check(said(leo, "Aquí tienes siempre tu cuarto") and said(leo, "el pacto italiano"), "Te da miedo irte de casa; vives con Luca")
check(said(leo, "una carta de tu familia") and said(leo, "Yo cocino para dos") and leoData.Story.Choices.Convivencia.V == "Hablar", "La caja de los recuerdos y un reparto justo en casa")
check(said(leo, "Traigo una planta") and leoData.Story.Flags.TieneHogar and leoData.Items.LlavesPiso == 1 and leoData.Story.Memories.PrimerPiso ~= nil, "{abu} viene de visita; ya tienes casa propia")

print("\n▶ Universidad 06 «La graduación» (ceremonia, foto, el brindis de toda una vida)")
leo.Prefer = { "La sudadera de dinosaurios" }
leo.Picks = {}
leoData.Life.StageSeconds = HOURS.AdultoJoven * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Uni06_Graduacion ~= nil
end), "Universidad 06 completa")
check(leoData.Story.Choices.LookGraduacion.V == "Dinosaurios" and said(leo, "Tienes trabajo esperando"), "La sudadera de dinosaurios bajo la toga, y la oferta de las prácticas")
check(said(leo, "Todo empezó ahí.") and said(leo, "La final del torneo. Plata.") and said(leo, "Nunca se lo agradecí bien"), "El brindis recuerda lo que viviste: Mateo, el torneo, Leire")
check(said(leo, "me acuerdo de que empezamos de cero") and not said(leo, "Ahora ya no me acuerdo de por qué"), "Bruno recuerda que empezasteis de cero")
local degreeSubjects = Subjects.Degrees.Ingenieria
local uniClasses = {}
for _, subject in classesOf(leo) do
	uniClasses[subject] = true
end
check(uniClasses[degreeSubjects.Asignatura1] and uniClasses[degreeSubjects.Asignatura2], "Las clases son las de Ingeniería")
check(leoData.Story.Flags.Graduado and leoData.Education.Degrees[degreeSubjects.Titulo] ~= nil, "Título guardado: graduado en Ingeniería")
check(cinematic(leo, "Uni_Graduacion") and leoData.Items.OrlaUniversidad == 1 and leoData.Story.Memories.Graduacion ~= nil, "Cinemática de graduación, orla y recuerdo")
task.wait(1)
check(leoData.Story.Chapter == "Adulto_VolarDelNido" and leoData.Story.Active.Adu01_PrimerContrato ~= nil, "Después empieza la vida adulta: «Volar del nido»")

print("\n▶ Vida adulta 01 «Mi primer contrato» (trabajo de tu carrera, facturas)")
leo.Prefer = { "Pido consejo", "Hacer un presupuesto" }
leo.Picks = {}
check(playUntil(leo, function()
	return leoData.Story.Completed.Adu01_PrimerContrato ~= nil
end), "Vida adulta 01 completa (sin volver a pedir casa: ya tienes la tuya)")
check(said(leo, "¡Por fin! En TecnoVal nadie se ha olvidado") and leoData.Story.Choices.PrimerCaso.V == "Consejo", "Te contratan donde hiciste las prácticas (confesaste tu error) y pides consejo")
check(leoData.Story.Choices.Facturas.V == "Presupuesto" and said(leo, "La persona de los números") and not leoData.Story.Flags.FacturaPendiente, "Primeras facturas: presupuesto con Ignacio")
check(leoData.Items.PrimeraNomina == 1 and leoData.Story.Memories.PrimerContrato ~= nil and said(leo, "no está muy bien"), "Primera nómina, recuerdo… y una llamada sobre {abu}")

print("\n▶ Vida adulta 02 «Un atardecer junto al mar» (el hospital, el carnet, la playa)")
leo.Prefer = { "Le coges la mano", "Haré cosas bonitas" }
leo.Picks = { ViajeAbu = "Coche" }
check(playUntil(leo, function()
	return leoData.Story.Completed.Adu02_Atardecer ~= nil
end), "Vida adulta 02 completa")
check(said(leo, "Me gustaría verlo otra vez. Contigo.") and said(leo, "¿Llevas el reloj? …Lo llevas."), "{abu} en el hospital: quiere ver el mar contigo (y te pregunta por su reloj)")
check(said(leo, "Toma las llaves del coche viejo"), "Te sacas el carnet de coche y tu familia te presta el coche")
check(said(leo, "Y de tu graduación.") and leoData.Story.Choices.PromesaAbu.V == "CosasBonitas", "En la playa, {abu} recuerda tu vida y le haces una promesa")
check(cinematic(leo, "Adu02_Atardecer") and leoData.Items.ConchaAbu == 1 and leoData.Story.Memories.AtardecerConAbu ~= nil, "El atardecer: cinemática, la concha y el recuerdo")

print("\n▶ Vida adulta 03 «El reencuentro» (la cafetería de Omar, Lucía, el banco del parque)")
leo.Prefer = { "¿Puedo venir a contarle", "Nada de promesas" }
leo.Picks = {}
check(playUntil(leo, function()
	return leoData.Story.Completed.Adu03_Reencuentro ~= nil
end), "Vida adulta 03 completa")
check(said(leo, "Firmé el mes pasado") and said(leo, "Mycena sarae") and said(leo, "Pues esto es el diez."), "Invitas al grupo: Nico futbolista, Sara bióloga, Bruno policía (empezasteis de cero)")
check(said(leo, "y que ahora las diseñas en TecnoVal") and leoData.Story.Flags.CharlaColegio, "Le cuentas a Lucía que cumpliste tu sueño de niño (inventar cosas)")
check(said(leo, "Perfecta según mis estándares") and said(leo, "Y aquí estamos. Con trabajos"), "La tortilla perfecta y la promesa del último día de colegio, cumplida")
check(leoData.Story.Choices.PromesaAdulta.V == "Siempre" and cinematic(leo, "Adu03_Foto") and leoData.Items.FotoReencuentro == 1 and leoData.Story.Memories.ElReencuentro ~= nil, "Promesa nueva, foto y recuerdo")
task.wait(1)
check(leoData.Story.Chapters.Adulto_VolarDelNido ~= nil and leoData.Story.Chapters.Adulto_NuevaVida == nil, "Capítulo «Volar del nido» terminado (el de los veteranos no se repite)")
passTime(leo, 13 * 3600)
check(leoData.Story.Active.Eco_RayoAdulto ~= nil and playQuest(leo, "Eco_RayoAdulto") and said(leo, "«Taller Rayo». Mío."), "Años después, Rayo tiene su propio taller gracias a ti")
check(pcall(serde.encode, "json", leoData), "Toda una vida se puede guardar (JSON válido)")

print("\n▶ Otra rama: dejar de estudiar y ponerse a trabajar")
local eva = newPlayer("Eva", "Adolescente")
local evaData = profiles[eva]
eva.Picks = { Camino = "Negocio" } -- en el cruce de caminos, elige el mal camino
task.wait(0.3)
evaData.Life.StageSeconds = HOURS.Adolescente * 3600
check(playUntil(eva, function()
	return evaData.Life.Stage == "AdultoJoven"
end, "Trabajar"), "Instituto terminado")
task.wait(1)
check(evaData.Story.Flags.EmpiezaATrabajar and not evaData.Story.Flags.VaALaUniversidad, "Elige trabajar")
check(evaData.Story.Active.Uni01_PrimerDia == nil and evaData.Story.Active.Adu01_PrimerContrato ~= nil, "No va a la universidad: empieza directamente la vida adulta")
check(playUntil(eva, function()
	return evaData.Story.Completed.Adu01_PrimerContrato ~= nil
end), "Sin carrera: busca casa y su jefe del primer verano le hace encargado o encargada")
check(said(eva, "Encargado o encargada. ¿Te atreves?") and evaData.Story.Flags.TieneHogar, "Lola le ofrece llevar la cafetería; ya tiene casa propia")

print("\n▶ El mal camino: pellas, pintada, el súper, las camisetas falsas… y las consecuencias")
check(evaData.Story.Flags.HicistePellas and evaData.Story.Flags.Pintada and evaData.Story.Flags.MentisteFamilia, "Hace pellas, pinta el muro y miente en casa")
check(evaData.Story.Flags.Hurto and evaData.Story.Flags.Escapaste and said(eva, "No sabe a nada."), "Roba en el súper de Paco y escapa")
check(evaData.Story.Flags.Camino_Delincuente and said(eva, "Son de MI equipo. ¿En serio?") and (evaData.Story.Traits.Rebeldia or 0) >= 6, "Entra en el negocio de camisetas falsas; Nico le ve (Rebeldía alta)")
check(eva:GetAttribute("Camino") == "Delincuente", "Su reputación: el mal camino")
eva.Prefer = { "Fui yo", "Lo dejo. Todo", "Colaboro" }
eva.Picks = { UltimoTrabajo = "Aceptar" }
passTime(eva, 3 * 3600 + 100)
-- Hay varias consecuencias pendientes a la vez: el juego las empieza de una en una
for _ = 1, 8 do
	if evaData.Story.Active.Eco_Camaras and evaData.Story.Active.Eco_Redada then
		break
	end
	passTime(eva, 60)
end
local ecoCamaras = evaData.Story.Active.Eco_Camaras ~= nil and playQuest(eva, "Eco_Camaras")
local ecoRedada = evaData.Story.Active.Eco_Redada ~= nil and playQuest(eva, "Eco_Redada")
check(ecoCamaras and evaData.Story.Flags.AvisoPolicia and evaData.Story.Flags.PerdonPaco, "Las cámaras la grabaron: la policía en la puerta, servicio a la comunidad y perdón a Paco")
check(ecoRedada and evaData.Story.Flags.Antecedentes, "La redada de las camisetas: queda en su expediente")
passTime(eva, 13 * 3600)
for _ = 1, 8 do
	if evaData.Story.Active.Eco_RayoAdulto then
		break
	end
	passTime(eva, 60)
end
check(evaData.Story.Active.Eco_RayoAdulto ~= nil and playQuest(eva, "Eco_RayoAdulto"), "Ya de adulta, Rayo vuelve con «un último trabajo»")
check(said(eva, "Doscientos por un viaje") and said(eva, "Cajas sin papeles"), "Acepta y en el control está… Bruno, ahora policía")
check(evaData.Story.Flags.Detenido and evaData.Story.Flags.Redimido and not evaData.Story.Flags.Camino_Delincuente and eva:GetAttribute("Camino") == "Responsable", "Detenida, colabora y cambia de camino: nunca es tarde")

print(("\n%s"):format(if failures == 0 then "✅ Todo correcto" else ("❌ %d fallos"):format(failures)))
process.exit(if failures == 0 then 0 else 1)
