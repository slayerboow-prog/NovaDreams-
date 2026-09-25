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
		task.delay(0.05, function()
			loadModule(ROOT .. "/server/LifeStory/StoryEvents").emit(player, "LessonCompleted", { Subject = spec.Subject, Mode = spec.Mode, Grade = 8 })
			onDone({ Grade = 8, Correct = 4, Total = 5 })
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

print("\n▶ El resto del colegio: días normales, cumpleaños y fin de primaria")
leoData.Life.StageSeconds = 0.36 * HOURS.Nino * 3600
task.wait(0.8)
check(leoData.Life.AgeYears == 8 and received(leo, "Moment", "MOMENT.CUMPLEANOS"), "El tiempo jugado hace crecer: cumple 8 años")

leoData.Life.StageSeconds = HOURS.Nino * 3600
check(playUntil(leo, function()
	return leoData.Life.Stage == "Adolescente"
end), "Toda la primaria: recados, examen, excursión, trimestre y fin de primaria")
for _, questId in { "Cole01_PrimerDia", "Cole02_Mochila", "Cole03_Grupo", "Nino_Recados", "Nino_PrimerExamen", "Nino_Excursion", "Nino_SegundoTrimestre", "Nino_FinDePrimaria" } do
	check(leoData.Story.Completed[questId] ~= nil, "  hecha: " .. questId)
end
check(received(leo, "Moment", "MOMENT.DIA_COLE"), "Los días de cole terminados quedan como momentos")
check(cinematic(leo, "Nino_FinPrimaria") and cinematic(leo, "Nino_AInstituto"), "Cinemáticas de fin de primaria y paso al instituto")
task.wait(0.8)
check(leoData.Life.AgeYears == 13 and leoData.Story.Active.Adol_NuevoInstituto ~= nil, "Con 13 años empieza el instituto")

print("\n▶ El instituto: primer trabajo y decidir el futuro")
leoData.Life.StageSeconds = HOURS.Adolescente * 3600
check(playUntil(leo, function()
	return leoData.Life.Stage == "AdultoJoven"
end, "Ingenieria"), "Instituto terminado")
check(leoData.Story.Choices.Estudios and leoData.Story.Choices.Estudios.V == "Ingenieria" and leoData.Story.Flags.VaALaUniversidad, "Elige estudiar Ingeniería")
check(cinematic(leo, "Adol_Selectividad"), "Cinemática de selectividad")
task.wait(0.8)
check(leoData.Story.Active.Uni_PrimerDia ~= nil and cinematic(leo, "Uni_PrimerDia"), "Empieza la universidad con su cinemática")
state = lastState(leo)
check(state.Tracked.Args.placeKey ~= nil and state.Tracked.Args.placeKey:find("INGENIERIA") ~= nil, "La tarjeta manda a la Facultad de Ingeniería")

print("\n▶ La universidad: carrera elegida y graduación")
leoData.Life.StageSeconds = HOURS.AdultoJoven * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Uni_Graduacion ~= nil
end), "Semestres, prácticas y graduación")
local degreeSubjects = Subjects.Degrees.Ingenieria
local uniClasses = {}
for _, subject in classesOf(leo) do
	uniClasses[subject] = true
end
check(uniClasses[degreeSubjects.Asignatura1] and uniClasses[degreeSubjects.Asignatura2], "Las clases son las de Ingeniería")
check(leoData.Story.Flags.Graduado and leoData.Education.Degrees[degreeSubjects.Titulo] ~= nil, "Título guardado: graduado en Ingeniería")
check(cinematic(leo, "Uni_Graduacion"), "Cinemática de graduación")
task.wait(1)
check(leoData.Story.Active.Adulto_LlegadaValmar ~= nil or leoData.Story.Chapter == "Adulto_NuevaVida", "Después empieza la vida profesional")
check(pcall(serde.encode, "json", leoData), "Toda una vida se puede guardar (JSON válido)")

print("\n▶ Otra rama: dejar de estudiar y ponerse a trabajar")
local eva = newPlayer("Eva", "Adolescente")
local evaData = profiles[eva]
task.wait(0.3)
evaData.Life.StageSeconds = HOURS.Adolescente * 3600
check(playUntil(eva, function()
	return evaData.Life.Stage == "AdultoJoven"
end, "Trabajar"), "Instituto terminado")
task.wait(1)
check(evaData.Story.Flags.EmpiezaATrabajar and not evaData.Story.Flags.VaALaUniversidad, "Elige trabajar")
check(evaData.Story.Active.Uni_PrimerDia == nil and evaData.Story.Active.Adulto_LlegadaValmar ~= nil, "No va a la universidad: empieza directamente la vida adulta")

print(("\n%s"):format(if failures == 0 then "✅ Todo correcto" else ("❌ %d fallos"):format(failures)))
process.exit(if failures == 0 then 0 else 1)
