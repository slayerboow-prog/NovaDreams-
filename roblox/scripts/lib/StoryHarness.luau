-- StoryHarness: el "Roblox de mentira" de las pruebas de la historia (test-lifestory,
-- test-playthrough). Carga los módulos reales de src/ con dobles de lo que necesita el mapa de verdad
-- (DataService, LocationService, SceneService, ClassService…) y trae el jugador automático.
--
-- Uso: local H = require("./lib/StoryHarness")   (desde scripts/)
--   H.boot() arranca los servicios de la historia (LifeStoryService, DialogueService…)

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
		Enum = roblox.Enum,
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
	player.Shows = (player.Shows or 0) + 1
	local choice = nil
	if payload.Options then
		choice = if player.Answer then player.Answer(payload.Ask, payload.Options) else 1
	end
	local function reply()
		dialogueRemote.OnServerEvent:Fire(player, "Next", payload.Token, choice, payload.Seq)
	end
	if player.Hold then
		-- El jugador "está leyendo": no contesta hasta H.release(player)
		player.Held = player.Held or {}
		table.insert(player.Held, reply)
		return
	end
	task.defer(reply)
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

-- Depuración del dueño: lo que el servidor le manda a cada jugador
local debugRemote = { OnServerEvent = signal() }
function debugRemote:FireClient(player, kind, payload)
	player.DebugInbox = player.DebugInbox or {}
	table.insert(player.DebugInbox, { Kind = kind, Payload = payload })
end
local remotes = { LifeStory = remote, Dialogue = dialogueRemote, MiniGame = miniGameRemote, Baby = sayRemote, Debug = debugRemote }
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
local players = { PlayerRemoving = signal(), PlayerAdded = signal() }
local activePlayers = {}
function players:GetPlayers()
	return activePlayers
end
local http = {}
function http:JSONEncode(value)
	return serde.encode("json", value)
end

fakeGame = { CreatorId = 1, CreatorType = roblox.Enum.CreatorType.User, JobId = "prueba" }
function fakeGame:GetService(name)
	return ({
		ReplicatedStorage = replicatedStorage,
		Lighting = lighting,
		Players = players,
		HttpService = http,
		RunService = { IsStudio = function()
			return false
		end },
		CollectionService = { GetTagged = function()
			return {}
		end },
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
-- Las pruebas de la historia empiezan sin el prólogo jugable (el sueño): así cada personaje nuevo va
-- directo al nacimiento, como antes. test-storycontext lo enciende para probarlo.
Config.LifeStory.Prologue = false
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
	respawn = function(player, questId)
		player.Respawns = (player.Respawns or 0) + 1
	end,
	-- Combates y huidas: el jugador de prueba decide si le atrapan (player.CaughtBy)
	caught = function(player)
		local by = player.CaughtBy
		player.CaughtBy = nil
		return by
	end,
	hit = function(player, questId, npc)
		player.Hits = (player.Hits or 0) + 1
	end,
	defeat = function(player, questId, npc)
		local scene = scenes[player] and scenes[player][questId]
		if scene then
			scene.Actors[npc] = nil
		end
	end,
	debugActors = function(player)
		local list = {}
		for questId, scene in scenes[player] or {} do
			for npc, spec in scene.Actors do
				table.insert(list, { Npc = npc, Quest = questId, Mode = spec.Mode or "Idle", Distance = 3 })
			end
		end
		return list
	end,
	teleportTo = function(player, position)
		player.TeleportedTo = position
	end,
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
local H = {}
H.failures = 0
local function check(condition: any, message: string)
	if condition then
		print("  ✅ " .. message)
	else
		H.failures += 1
		print("  ❌ " .. message)
	end
end

H.defaultAttributes = {} :: { [string]: any }

-- stage = nil: personaje recién creado (playSeconds 0 -> nace bebé; > 0 -> jugador veterano, adulto)
local nextUserId = 1000
local function newPlayer(name: string, stage: string?, playSeconds: number?, profile: any?)
	-- SpawnReady: ya ha aparecido donde lo dejó (en el juego lo pone PositionService)
	nextUserId += 1
	local player = { Name = name, DisplayName = name, UserId = nextUserId, Parent = true, Inbox = {}, Attributes = { SpawnReady = true }, Said = {}, Games = {}, Barks = {} }
	-- (atributos que pondrían otros servicios antes de cargar la historia, p. ej. LifeDay de CalendarService)
	for key, value in H.defaultAttributes do
		player.Attributes[key] = value
	end
	function player:SetAttribute(key, value)
		self.Attributes[key] = value
	end
	function player:GetAttribute(key)
		return self.Attributes[key]
	end
	profiles[player] = profile or {
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
	table.insert(activePlayers, player)
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


-- El jugador de mentira "termina de leer": contesta lo que tenía pendiente en las conversaciones
function H.release(player)
	player.Hold = false
	local held = player.Held or {}
	player.Held = {}
	for _, reply in held do
		reply()
	end
end

-- El jugador se va del juego (como Players.PlayerRemoving): se guarda su perfil tal y como lo
-- guardaría un DataStore (JSON) y deja de existir
function H.leave(player): string
	player.Parent = nil
	local index = table.find(activePlayers, player)
	if index then
		table.remove(activePlayers, index)
	end
	players.PlayerRemoving:Fire(player)
	local saved = serde.encode("json", profiles[player])
	profiles[player] = nil
	return saved
end

-- Lo que el DataStore de Roblox rechazaría de las partidas de todos los jugadores de la prueba
-- (Vector3, NaN, tablas con claves numéricas sueltas…: un solo problema y no se guarda NADA) y el
-- tamaño de la mayor (ver src/shared/SaveCheck)
function H.saveProblems(): ({ string }, number)
	local SaveCheck = loadModule(ROOT .. "/shared/SaveCheck")
	local seen, list, biggest = {}, {}, 0
	for _, profile in profiles do
		for _, problem in SaveCheck.scan(profile) do
			local text = problem.Path .. ": " .. problem.Reason
			if not seen[text] then
				seen[text] = true
				table.insert(list, text)
			end
		end
		biggest = math.max(biggest, SaveCheck.size((SaveCheck.sanitize(profile))))
	end
	table.sort(list)
	return list, biggest
end

-- Vuelve a entrar con lo guardado (un jugador nuevo con el mismo nombre y UserId)
function H.rejoin(old, saved: string)
	local profile = serde.decode("json", saved)
	local player = newPlayer(old.Name, nil, nil, profile)
	player.UserId = old.UserId
	return player
end

-- Arranca los servicios de la historia (una vez)
local Service, StoryEvents, RoleService
function H.boot()
	if Service then
		return Service, StoryEvents, RoleService
	end
	StoryEvents = loadModule(ROOT .. "/server/LifeStory/StoryEvents")
	RoleService = loadModule(ROOT .. "/server/Services/RoleService")
	Service = loadModule(ROOT .. "/server/Services/LifeStoryService")
	RoleService.init()
	loadModule(ROOT .. "/server/Services/DialogueService").init()
	loadModule(ROOT .. "/server/Services/MiniGameService").init()
	Service.init()
	H.Service, H.StoryEvents, H.RoleService = Service, StoryEvents, RoleService
	return Service, StoryEvents, RoleService
end

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
	elseif step.Type == "Fight" then
		-- Un golpe a cada enemigo que quede en pie (como un jugador pulsando el botón)
		local prog = story.Active[questId]
		for _, enemy in step.Enemies do
			if not (prog and prog.Sub and prog.Sub[enemy.Npc]) then
				Service.interact(player, "Actor", questId, enemy.Npc)
				task.wait(0.3)
			end
		end
	elseif step.Type == "Escape" then
		player.At = place(step.Place)
	elseif step.Type == "Wait" then
		day += 1 -- pasa un día de juego…
		while (day - 1) % 7 + 1 > 5 do
			day += 1 -- …de lunes a viernes (el fin de semana no hay cole: las pruebas juegan días de clase)
		end
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
-- Como un jugador de verdad: la misión que juega es la que sigue (las escenas de las que no sigues no
-- empiezan solas: LifeStoryService.canAutoStart). Si sigue otra, cambia a esta (panel de misiones).
local function follow(player, questId: string)
	local story = profiles[player].Story
	local prologue = false
	for id in story.Active do
		prologue = prologue or (Quests[id] ~= nil and Quests[id].Prologue == true)
	end
	if story.Active[questId] and story.Tracked ~= questId and not prologue then
		fromClient(player, "Track", questId)
	end
end

local function playUntil(player, done: () -> boolean, choice: string?, maxSteps: number?): boolean
	player.Answer = preferAnswer(player)
	for _ = 1, maxSteps or 300 do
		if done() then
			return true
		end
		local id, _, step = mainStep(player)
		if id and step then
			local tracked = profiles[player].Story.Tracked
			if tracked and tracked ~= id and profiles[player].Story.Active[tracked] then
				follow(player, id) -- (seguía una secundaria: vuelve a la historia principal)
			end
			doStep(player, id, step, choice)
		else
			-- Ninguna principal en marcha porque la siguiente espera una hora (a que acabe el cole, a que
			-- abra el colegio, al día siguiente): como un jugador que espera o duerme, se adelanta el reloj
			local dbg = Service.debugState(player)
			local waiting = dbg and dbg.Waiting
			if waiting and waiting.Reason == "Hours" and type(waiting.From) == "number" then
				if waiting.From <= lighting.ClockTime then
					H.nextSchoolDay()
				end
				lighting.ClockTime = waiting.From + 0.5
			end
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
			follow(player, questId)
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

-- Día de juego (workspace:GetAttribute("Day"))
function H.getDay()
	return day
end
function H.setDay(value: number)
	day = value
end
-- El día de clase siguiente (salta el fin de semana)
function H.nextSchoolDay()
	day += 1
	while (day - 1) % 7 + 1 > 5 do
		day += 1
	end
end

H.ROOT = ROOT
H.TestRandom = TestRandom
H.mocks = mocks
H.loadModule = loadModule
H.signal = signal
H.remote = remote
H.dialogueRemote = dialogueRemote
H.miniGameRemote = miniGameRemote
H.remotes = remotes
H.debugRemote = debugRemote
H.lighting = lighting
H.players = players
H.profiles = profiles
H.loadedCallbacks = loadedCallbacks
H.scenes = scenes
H.classCalls = classCalls
H.needsChanges = needsChanges
H.Config = Config
H.check = check
H.newPlayer = newPlayer
H.received = received
H.cinematic = cinematic
H.momentSting = momentSting
H.lastState = lastState
H.fromClient = fromClient
H.Quests = Quests
H.Subjects = Subjects
H.HOURS = HOURS
H.preferAnswer = preferAnswer
H.passes = passes
H.questStep = questStep
H.mainStep = mainStep
H.doStep = doStep
H.follow = follow
H.playUntil = playUntil
H.playQuest = playQuest
H.said = said
H.classesOf = classesOf
H.laterStarts = laterStarts
H.passTime = passTime

return H
