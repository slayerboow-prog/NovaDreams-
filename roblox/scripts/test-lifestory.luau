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

local remotes = { LifeStory = remote }
function remotes:FindFirstChild(name)
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
	local player = { Name = name, DisplayName = name, Parent = true, Inbox = {}, Attributes = {} }
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
check(cinematic(leo, "Nino_PrimerDia") and leoData.Story.Active.Nino_PrimerDiaColegio ~= nil, "Empieza el colegio: 'Tu primer día de cole' (ya no salta a buscar trabajo)")
check(leoData.Life.AgeYears == 6 and leo:GetAttribute("AgeYears") == 6, "Tiene 6 años")
check(pcall(serde.encode, "json", leoData), "Los datos del bebé se pueden guardar (JSON válido)")

---------------------------------------------------------------------
-- Jugador automático: hace lo que pide el paso actual de la misión principal
---------------------------------------------------------------------
local Quests = loadModule(ROOT .. "/shared/LifeStory/Quests")
local Subjects = loadModule(ROOT .. "/shared/LifeStory/Subjects")
local HOURS = Config.LifeStory.StageHours

local function mainStep(player)
	local story = profiles[player].Story
	for id, prog in story.Active do
		if Quests[id] and Quests[id].Kind == "Main" then
			local steps = prog.Steps or Quests[id].Steps
			return id, prog, steps[prog.Step]
		end
	end
	return nil
end

local function doStep(player, questId, step, choice)
	local story = profiles[player].Story
	local degree = story.Choices.Estudios and story.Choices.Estudios.V
	local function place(value)
		return Subjects.resolve(value, degree)
	end
	if step.Type == "Reach" or step.Type == "Class" then
		player.At = place(step.Place)
	elseif step.Type == "Talk" then
		StoryEvents.emit(player, "Talk", { Npc = step.Npc })
	elseif step.Type == "Event" then
		StoryEvents.emit(player, step.Event, table.clone(step.Match or {}))
	elseif step.Type == "Group" then
		for _, child in step.Steps do
			doStep(player, questId, child, choice)
		end
	elseif step.Type == "Wait" then
		day += 1 -- pasa un día de juego
	elseif step.Type == "Choice" then
		fromClient(player, "Choose", questId, choice)
	end
end

-- Juega hasta que se cumpla la condición (o se rinde tras muchos intentos)
local function playUntil(player, done: () -> boolean, choice: string?, maxSteps: number?): boolean
	for _ = 1, maxSteps or 250 do
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

local function classesOf(player)
	local list = {}
	for _, call in classCalls do
		if call.Player == player then
			table.insert(list, call.Subject)
		end
	end
	return list
end

print("\n▶ El colegio (5 horas): clases que se juegan, días normales y cumpleaños")
lighting.ClockTime = 9
check(playUntil(leo, function()
	return leoData.Story.Completed.Nino_PrimerDiaColegio ~= nil
end), "Primer día: entrada, profe Lucía, clase, recreo con Nico, Sara y Omar, y vuelta a casa")
local leoClasses = classesOf(leo)
check(leoClasses[1] == "Matematicas" and leoClasses[2] == "Lengua", "Las clases del primer día son Matemáticas y Lengua")
check(leoData.Story.LastGrade == 8, "La nota de la clase queda guardada")
task.wait(0.8)
local jornada = leoData.Story.Active.Nino_Jornada
check(jornada ~= nil and jornada.Steps and #jornada.Steps >= 4, "Mientras no toca el siguiente gran momento, se vive un día de cole normal")
check(leoData.Story.Active.Nino_MiSemana == nil, "'Mi primera semana' todavía espera (5 horas de etapa, no se corre)")
state = lastState(leo)
check(state and state.Tracked and state.Tracked.TitleKey:sub(1, 10) == "QUEST.DIA_", "La tarjeta muestra el día de hoy")

leoData.Life.StageSeconds = 0.05 * HOURS.Nino * 3600
check(playUntil(leo, function()
	return leoData.Story.Active.Nino_MiSemana ~= nil
end), "Pasado un rato de la etapa, llega 'Mi primera semana'")
check(received(leo, "Moment", "MOMENT.DIA_COLE"), "Cada día de cole terminado queda como momento")

leoData.Life.StageSeconds = 0.36 * HOURS.Nino * 3600
task.wait(0.8)
check(leoData.Life.AgeYears == 8 and received(leo, "Moment", "MOMENT.CUMPLEANOS"), "El tiempo jugado hace crecer: cumple 8 años")

leoData.Life.StageSeconds = HOURS.Nino * 3600
check(playUntil(leo, function()
	return leoData.Life.Stage == "Adolescente"
end), "Toda la primaria: recados, examen, excursión, trimestre y fin de primaria")
for _, questId in { "Nino_MiSemana", "Nino_Recados", "Nino_PrimerExamen", "Nino_Excursion", "Nino_SegundoTrimestre", "Nino_FinDePrimaria" } do
	check(leoData.Story.Completed[questId] ~= nil, "  hecha: " .. questId)
end
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
