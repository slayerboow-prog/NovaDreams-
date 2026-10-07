-- Prueba: que el jugador ENTIENDA su historia (docs/historia, StoryContext).
--   1. El validador avisa de las misiones sin descripción (y hoy todas la tienen).
--   2. Tipos de misión y tarjetas de contexto (⭐ tu vida, 🌀 misión loca, ❗ saga; quién te lo pide).
--   3. Prólogo jugable («El sueño»): empieza con un personaje nuevo y no con uno que vuelve; cada paso
--      se cumple con la acción de verdad (y no con otra); InPrologue se quita; después empieza el
--      primer capítulo (con su escena del nacimiento); solo una vez; se puede saltar.
--   4. «Anteriormente en tu vida…»: sale al volver con su contenido, y nunca durante una conversación.
--   5. «Mi historia»: capítulos, personajes que conoces y recuerdos.
--
-- Uso (desde la carpeta roblox/): lune run scripts/test-storycontext.luau   (~1-2 min)

local process = require("@lune/process")
local task = require("@lune/task")

local H = require("./lib/StoryHarness")
local check = H.check
local ROOT = H.ROOT

local Validate = H.loadModule(ROOT .. "/shared/LifeStory/Validate")
local StoryContext = H.loadModule(ROOT .. "/shared/LifeStory/StoryContext")
local Memories = H.loadModule(ROOT .. "/shared/LifeStory/Memories")
local Quests = H.Quests
local PROLOGUE = StoryContext.PrologueId

local function waitFor(condition: () -> boolean, seconds: number): boolean
	local since = os.clock()
	while os.clock() - since < seconds do
		if condition() then
			return true
		end
		task.wait(0.2)
	end
	return condition()
end

local function inbox(player, kind: string): { any }
	local list = {}
	for _, message in player.Inbox do
		if message.Kind == kind then
			table.insert(list, message.Payload)
		end
	end
	return list
end

---------------------------------------------------------------------
print("\n▶ 1. Descripciones de las misiones (validador)")
---------------------------------------------------------------------
do
	local problems = Validate.descriptionProblems({
		SinTexto = { Kind = "Main", Description = "" },
		Espacios = { Kind = "Side", Description = "   " },
		Nada = { Kind = "Main" },
		Corta = { Kind = "Main", Description = "Ayuda" },
		Buena = { Kind = "Main", Description = "Tu abu te pide que vayas a por pan antes de que cierre." },
	})
	local flagged = {}
	for _, problem in problems do
		flagged[problem:match("^(%w+):")] = true
	end
	check(flagged.SinTexto and flagged.Espacios and flagged.Nada, "el validador marca las misiones con la descripción vacía o sin ella")
	check(flagged.Corta, "y las que tienen una descripción demasiado corta para explicar nada")
	check(not flagged.Buena, "una descripción de verdad no se marca")
	local real = Validate.descriptionProblems(Quests)
	check(#real == 0, ("todas las misiones del juego tienen descripción (%d sin ella%s)"):format(#real, if #real > 0 then ": " .. real[1] else ""))
	local report = Validate.report()
	local descErrors = 0
	for _, e in report.Errors do
		if e:find("descripción", 1, true) then
			descErrors += 1
		end
	end
	check(#report.Errors == 0 and descErrors == 0, ("el informe del validador no tiene errores (%d)"):format(#report.Errors))
	check(not report.BadQuests[PROLOGUE], "el prólogo pasa el validador")
end

---------------------------------------------------------------------
print("\n▶ 2. Tipos de misión y tarjetas de contexto")
---------------------------------------------------------------------
do
	check(StoryContext.kindOf(Quests.Loco_N1_Cosme) == "Saga", "El vecino del garaje es de la saga de la Grieta (❗)")
	check(StoryContext.kindOf(Quests.Saga_03_Pez) == "Saga", "El pez que sabía demasiado es de la saga")
	check(StoryContext.kindOf(Quests.Loco_N2_Bigotes) == "Loca", "Bigotes, emperador de Gatonia es una misión loca (🌀)")
	check(StoryContext.kindOf(Quests.Cole01_PrimerDia) == "Principal", "Tu primer día de colegio es de la historia principal (⭐)")
	check(StoryContext.kindOf(Quests.Side_MochilaPerdida) == "Secundaria", "La mochila perdida es secundaria")
	check(StoryContext.kindOf(Quests[PROLOGUE]) == "Prologo", "el prólogo es el prólogo (✨)")
	local card = StoryContext.card("Saga_03_Pez")
	check(card ~= nil and card.Asker == "Don Escamas" and card.Icon == "❗" and (card.Description or ""):find("pez", 1, true) ~= nil,
		"la tarjeta de «El pez que sabía demasiado» dice quién lo pide (Don Escamas), su tipo (❗) y por qué")
	local cosme = StoryContext.card("Loco_N1_Cosme")
	check(cosme ~= nil and cosme.Asker == "Cosme" and cosme.Label == "Saga de la Grieta", "la de «El vecino del garaje»: Cosme, saga de la Grieta")
	local abu = StoryContext.card("Bebe_AprendeACaminar", { AbuKey = "NPC.ABU_TOMAS" })
	check(abu ~= nil and abu.Asker == "NPC.ABU_TOMAS" and abu.Label:find("principal", 1, true) ~= nil, "la del bebé: tu abu (el de tu casa), historia principal")
end

---------------------------------------------------------------------
print("\n▶ 3. Prólogo jugable: el sueño")
---------------------------------------------------------------------
local Service, StoryEvents = H.boot()
local DialogueService = H.loadModule(ROOT .. "/server/Services/DialogueService")
H.Config.LifeStory.Prologue = true
-- Las escenas del motor (Happenings: el nacimiento en la cuna…) no llegan como "Cinematic": se apuntan
-- al lanzarse
local scenesPlayed: { [any]: { [string]: boolean } } = {}
do
	local Happening = H.loadModule(ROOT .. "/server/Services/HappeningService")
	local realPlay = Happening.play
	Happening.play = function(p, id, ...)
		scenesPlayed[p] = scenesPlayed[p] or {}
		scenesPlayed[p][id] = true
		return realPlay(p, id, ...)
	end
end
local function sceneOrCinematic(p, id: string): boolean
	return H.cinematic(p, id) or (scenesPlayed[p] ~= nil and scenesPlayed[p][id] == true)
end

local nuevo = H.newPlayer("Nuevo")
local story = H.profiles[nuevo].Story
local function step(): number?
	local prog = story.Active[PROLOGUE]
	return prog and prog.Step
end
check(waitFor(function()
	return step() ~= nil
end, 3), "un personaje nuevo empieza con el prólogo")
check(nuevo:GetAttribute("InPrologue") == true, "mientras dura, el atributo InPrologue está puesto")
check(nuevo:GetAttribute("LifeStage") == "Nino" and H.profiles[nuevo].Life.Stage == "Bebe",
	"en el sueño es un poco mayor (LifeStage = Nino) pero lo guardado sigue siendo bebé")
check(story.Chapter == nil and not sceneOrCinematic(nuevo, "Bebe_NacimientoCuna"), "el primer capítulo (el nacimiento) espera a que acabe el sueño")
check(sceneOrCinematic(nuevo, Quests[PROLOGUE].Steps[1].Id), "empieza con la escena que cuenta qué es el juego y la Grieta")
check(nuevo.At == "PrologoInicio", "y le lleva a la isla del sueño")
check(waitFor(function()
	return step() == 2
end, 30), "al acabar la escena empieza el primer paso")

-- Cada paso: una acción equivocada no lo cumple; la de verdad, sí
local function beat(name: string, wrong: () -> (), right: () -> (), expected: number)
	local before = step()
	local state = H.lastState(nuevo)
	local tracked = state and state.Tracked
	check(tracked and tracked.QuestId == PROLOGUE and tracked.Hint and tracked.Hint.Pc and tracked.Hint.Touch,
		("[%s] la tarjeta de ayuda tiene texto para teclado y para móvil"):format(name))
	check(nuevo:GetAttribute("PrologueBeat") == (tracked and tracked.Beat), ("[%s] el atributo PrologueBeat dice qué se enseña (%s)"):format(name, tostring(nuevo:GetAttribute("PrologueBeat"))))
	wrong()
	task.wait(1.2)
	check(step() == before, ("[%s] con otra acción no avanza"):format(name))
	right()
	check(waitFor(function()
		return step() == expected or (expected > #Quests[PROLOGUE].Steps and story.Active[PROLOGUE] == nil)
	end, 8), ("[%s] con la acción de verdad, sí"):format(name))
end

beat("moverse", function()
	StoryEvents.emit(nuevo, "Sprinted", {})
end, function()
	nuevo.At = "PrologoCamino"
end, 3)
beat("correr", function()
	StoryEvents.emit(nuevo, "Ate", {})
end, function()
	StoryEvents.emit(nuevo, "Sprinted", {})
end, 4)
beat("saltar", function()
	nuevo.At = "PrologoCosme" -- (no se llega sin pasar la valla, pero aquí da igual: no es el sitio)
end, function()
	nuevo.At = "PrologoSalto"
end, 5)
beat("hablar", function()
	Service.interact(nuevo, "Prop", PROLOGUE, "Tornillo")
end, function()
	Service.interact(nuevo, "Actor", PROLOGUE, "Cosme")
end, 6)
check(story.Choices.Prologo and story.Choices.Prologo.V == "Ayudar" and (story.Traits.Valentia or 0) >= 1,
	"lo que respondes a Cosme se guarda (decisión y rasgo): las decisiones cuentan")
check(H.said(nuevo, "Grieta"), "Cosme habla de la Grieta")
beat("coger", function()
	Service.interact(nuevo, "Actor", PROLOGUE, "Cosme")
end, function()
	Service.interact(nuevo, "Prop", PROLOGUE, "Tornillo")
end, 7)
beat("seguir la línea", function()
	nuevo.At = "PrologoCamino"
end, function()
	nuevo.At = "PrologoPuerta"
end, 8)
beat("abrir el mapa", function()
	H.fromClient(nuevo, "Prologue", "Nada")
end, function()
	H.fromClient(nuevo, "Prologue", "MapOpened")
end, 9)
check(sceneOrCinematic(nuevo, Quests[PROLOGUE].Steps[#Quests[PROLOGUE].Steps].Id), "acaba con la escena que explica los tipos de misión")
check(waitFor(function()
	return story.Active[PROLOGUE] == nil
end, 25), "el prólogo termina")
check(nuevo:GetAttribute("InPrologue") == nil, "al terminar se quita InPrologue")
check(nuevo:GetAttribute("PrologueBeat") == nil, "y PrologueBeat")
check(nuevo:GetAttribute("LifeStage") == "Bebe", "vuelve a ser bebé")
check(nuevo.At == "Cuna", "y despierta en su cuna")
check(story.PrologueDone ~= nil and story.PrologueDone ~= false and story.PrologueResult == "Done", "queda guardado que ya lo vio (DataService)")
check(waitFor(function()
	return story.Chapter == "Bebe_PrimerosPasos" and sceneOrCinematic(nuevo, "Bebe_NacimientoCuna")
end, 3), "después empieza el primer capítulo con su escena del nacimiento")
check(waitFor(function()
	return story.Active.Bebe_AprendeACaminar ~= nil
end, 3), "y su primera misión (aprender a caminar)")
check(story.Memories.SuenoGrieta ~= nil, "el sueño queda como recuerdo")
local intro = nil
for _, card in inbox(nuevo, "QuestIntro") do
	if card.QuestId == "Bebe_AprendeACaminar" then
		intro = card
	end
end
check(intro ~= nil and intro.Description and intro.Icon == "⭐", "la primera misión llega con su tarjeta de contexto (por qué, ⭐ tu vida)")

-- Vuelve a entrar: el prólogo no se repite
local saved = H.leave(nuevo)
local vuelve = H.rejoin(nuevo, saved)
task.wait(1)
check(H.profiles[vuelve].Story.Active[PROLOGUE] == nil and vuelve:GetAttribute("InPrologue") == nil and not sceneOrCinematic(vuelve, Quests[PROLOGUE].Steps[1].Id),
	"al volver a entrar, el prólogo no sale otra vez")

-- Saltar
local salta = H.newPlayer("Salta")
local story2 = H.profiles[salta].Story
check(waitFor(function()
	return story2.Active[PROLOGUE] ~= nil
end, 3), "otro personaje nuevo: prólogo")
H.fromClient(salta, "Prologue", "Skip")
check(waitFor(function()
	return story2.Active[PROLOGUE] == nil
end, 3), "el botón Saltar lo cierra en cualquier momento")
check(salta:GetAttribute("InPrologue") == nil and salta:GetAttribute("LifeStage") == "Bebe", "al saltarlo se quita InPrologue y vuelve a ser bebé")
check(story2.PrologueResult == "Skipped" and story2.PrologueDone, "queda guardado como visto (saltado)")
check(waitFor(function()
	return story2.Chapter == "Bebe_PrimerosPasos" and sceneOrCinematic(salta, "Bebe_NacimientoCuna")
end, 3), "y empieza el primer capítulo igual")

-- Saltar en mitad de la conversación con Cosme: la conversación se corta (y los controles vuelven)
local habla = H.newPlayer("Habla")
local story3 = H.profiles[habla].Story
waitFor(function()
	return story3.Active[PROLOGUE] ~= nil
end, 3)
-- (la escena de apertura sigue en pantalla un momento: mientras, la historia no abre nada encima)
waitFor(function()
	return habla:GetAttribute("InScene") ~= true
end, 3)
story3.Active[PROLOGUE].Step = 5 -- (directamente al paso de hablar)
habla.Hold = true -- "está leyendo": la conversación se queda abierta
Service.interact(habla, "Actor", PROLOGUE, "Cosme")
task.wait(0.5)
check(DialogueService.isBusy(habla), "(la conversación con Cosme está abierta)")
H.fromClient(habla, "Prologue", "Skip")
check(waitFor(function()
	return not DialogueService.isBusy(habla) and story3.Active[PROLOGUE] == nil
end, 3), "saltar a media conversación la cierra (la caja se cierra y vuelven los controles)")
H.release(habla)

-- Volver a jugarlo desde «Mi historia» (cuando acaba la escena del nacimiento que sale al saltarlo:
-- encima de una escena no se empieza nada)
waitFor(function()
	return habla:GetAttribute("InScene") ~= true
end, 3)
H.fromClient(habla, "Prologue", "Replay")
check(waitFor(function()
	return story3.Active[PROLOGUE] ~= nil and habla:GetAttribute("InPrologue") == true
end, 3), "se puede volver a jugar desde «Mi historia»")
local chapterBefore = story3.Chapter
H.fromClient(habla, "Prologue", "Skip")
check(waitFor(function()
	return story3.Active[PROLOGUE] == nil and habla:GetAttribute("InPrologue") == nil
end, 3), "y saltarlo otra vez")
check(story3.Chapter == chapterBefore and story3.PrologueResult == "Skipped", "sin cambiar su vida (mismo capítulo)")

-- Quien ya tenía una vida no lo ve
local veterano = H.newPlayer("Veterano", nil, 3600)
task.wait(1)
check(H.profiles[veterano].Story.Active[PROLOGUE] == nil and veterano:GetAttribute("InPrologue") == nil, "un jugador que ya tenía partida no ve el prólogo")

---------------------------------------------------------------------
print("\n▶ 4. «Anteriormente en tu vida…»")
---------------------------------------------------------------------
local function returningProfile()
	local now = os.time()
	return {
		Money = 50,
		Stats = { PlaySeconds = 9000 },
		Life = { Stage = "Nino", AgeYears = 7, StageSeconds = 3000 },
		Education = { Subjects = {}, Exams = {}, Degrees = {}, Attendance = 0 },
		Items = {},
		Story = {
			Version = 1,
			Chapter = "Nino_ElColegio",
			Chapters = { Bebe_PrimerosPasos = now - 9000 },
			Active = { Cole02_Mochila = { Step = 1, Count = 0, Started = now - 100, Kind = "Main" } },
			Tracked = "Cole02_Mochila",
			Completed = { Bebe_AprendeACaminar = now - 9000, Bebe_ExploraLaCasa = now - 8800, Bebe_HoraDeSalir = now - 8600, Cole01_PrimerDia = now - 4000 },
			Declined = {},
			Choices = { Asiento = { V = "Mateo", D = 3 } },
			Flags = {},
			Discovered = {},
			NpcMemory = { Mateo = { Rel = 30, Affinity = 1, Facts = { PrimerAmigo = 3 } }, Nico = { Rel = 6, Facts = {} }, Bruno = { Rel = -12, Facts = {} } },
			Events = {
				{ Y = "Chapter", K = "CHAPTER.NINO.TITLE", T = now - 5000 },
				{ Y = "Memory", K = Memories.PrimerDiaCole.Text, T = now - 4100 },
				{ Y = "Choice", K = "Te sientas con Mateo", T = now - 4050 },
				{ Y = "Memory", K = Memories.PrimerAmigo.Text, T = now - 4000 },
				{ Y = "Moment", K = "MOMENT.DIA_COLE", A = { n = 1 }, T = now - 3000 },
			},
			Memories = { PrimerDiaCole = { T = now - 4100 }, PrimerAmigo = { T = now - 4000 } },
			Traits = {},
			Later = {},
			Clock = 3000,
			PrologueDone = now - 9000,
			LastSeen = now - 3 * 3600,
		},
	}
end

local tornado = H.newPlayer("Tornado", nil, nil, returningProfile())
check(waitFor(function()
	return #inbox(tornado, "Recap") > 0
end, 3), "un jugador que vuelve (con su vida empezada) ve el resumen")
local recap = inbox(tornado, "Recap")[1] or {}
check(recap.ChapterTitleKey == "CHAPTER.NINO.TITLE" and recap.Stage == "Nino" and recap.StageName ~= nil, "con el capítulo y la etapa en que está")
local recent = recap.Recent or {}
local keys = {}
for _, item in recent do
	keys[item.Key] = item.Kind
end
check(#recent == 3 and keys[Memories.PrimerAmigo.Text] == "Memory" and keys["Te sientas con Mateo"] == "Choice" and keys[Memories.PrimerDiaCole.Text] == "Memory",
	("con las 3 últimas cosas importantes (recuerdos y decisiones: %d)"):format(#recent))
check(keys["MOMENT.DIA_COLE"] == nil, "sin los días normales (no son importantes)")
check(recent[#recent] and recent[#recent].Key == Memories.PrimerAmigo.Text, "de la más antigua a la más nueva")
check(recap.Objective and recap.Objective.QuestId == "Cole02_Mochila" and recap.Objective.TitleKey and recap.Objective.TextKey,
	"y con lo que estaba haciendo (el objetivo de ahora)")
check(tornado:GetAttribute("InPrologue") == nil and H.profiles[tornado].Story.Active[PROLOGUE] == nil, "quien vuelve no ve el prólogo")

-- Si vuelve en mitad de una conversación, el resumen espera (nunca encima)
local realBusy = DialogueService.isBusy
DialogueService.isBusy = function()
	return true
end
local ocupado = H.newPlayer("Ocupado", nil, nil, returningProfile())
task.wait(1.5)
check(#inbox(ocupado, "Recap") == 0, "con una conversación abierta, el resumen no sale")
DialogueService.isBusy = realBusy
check(waitFor(function()
	return #inbox(ocupado, "Recap") > 0
end, H.Config.LifeStory.RefreshSeconds + 3), "sale en cuanto termina la conversación")

-- Quien acaba de salir y entrar (pocos segundos fuera) no lo ve otra vez
local profile = returningProfile()
profile.Story.LastSeen = os.time() - 5
local rapido = H.newPlayer("Rapido", nil, nil, profile)
task.wait(1)
check(#inbox(rapido, "Recap") == 0, "si solo ha estado fuera unos segundos, no sale")

---------------------------------------------------------------------
print("\n▶ 5. «Mi historia»")
---------------------------------------------------------------------
do
	local journal = StoryContext.journal(returningProfile(), { FamilyKey = "NPC.PAPA" })
	local chapters = {}
	for _, chapter in journal.Chapters do
		chapters[chapter.Id] = chapter
	end
	check(journal.Chapters[1] and journal.Chapters[1].Prologue, "capítulos: primero el prólogo (el sueño)")
	check(chapters.Bebe_PrimerosPasos and chapters.Bebe_PrimerosPasos.Done and chapters.Bebe_PrimerosPasos.IntroKey == "CHAPTER.BEBE.INTRO",
		"el capítulo terminado, con su frase de entrada")
	check(chapters.Nino_ElColegio and chapters.Nino_ElColegio.Current, "el capítulo de ahora, marcado")
	check(chapters.Adolescente_Instituto == nil, "y no los que aún no has vivido")
	local people = {}
	for _, person in journal.People do
		people[person.Id] = person
	end
	check(people.Mateo and people.Nico and people.Bruno, "personajes: los que conoces (Mateo, Nico, Bruno)")
	check(people.Mateo and people.Mateo.Who ~= "" and people.Mateo.RelText:find("amigos", 1, true) ~= nil, "cada uno con quién es y cómo os lleváis (Mateo: buenos amigos)")
	check(people.Bruno and people.Bruno.RelText:find("roces", 1, true) ~= nil, "Bruno: hay roces")
	check(people.Lucia ~= nil, "y la gente principal de lo que has vivido (tu tutora, del primer día de cole)")
	check(people.Cosme == nil, "pero no a quien aún no conoces (Cosme)")
	check(journal.People[1].Id == "Mateo", "ordenados: primero con quien mejor te llevas")
	check(#journal.Memories == 2 and journal.Memories[1].Key == "PrimerAmigo" and journal.Memories[1].Icon ~= nil, "recuerdos, del más nuevo al más antiguo, con su icono")
	check(#journal.Choices == 1 and journal.Choices[1].Key == "Te sientas con Mateo", "y las decisiones importantes")

	-- Desde el cliente: pide el diario y llega
	H.fromClient(tornado, "Journal")
	local sent = inbox(tornado, "Journal")[1]
	local mateo = false
	for _, person in (sent and sent.People) or {} do
		mateo = mateo or person.Id == "Mateo"
	end
	check(sent ~= nil and mateo and #sent.Chapters >= 2, "el servidor manda el diario al pedirlo («Mi historia»)")
end

---------------------------------------------------------------------
print("\n▶ 6. La isla del sueño (World/Kit/DreamIsland) con instancias de Roblox de verdad")
---------------------------------------------------------------------
do
	local fs = require("@lune/fs")
	local luau = require("@lune/luau")
	local roblox = require("@lune/roblox")
	local game = roblox.Instance.new("DataModel")
	local ws = game:GetService("Workspace")
	local cache = {}
	local nodeMeta = {}
	local function node(path)
		return setmetatable({ __path = path }, nodeMeta)
	end
	nodeMeta.__index = function(self, key)
		local path = rawget(self, "__path")
		if key == "Parent" then
			return node((path:match("^(.*)/[^/]+$")))
		end
		return node(path .. "/" .. key)
	end
	local function load(path)
		if cache[path] then
			return cache[path]
		end
		local env = setmetatable({
			script = node(path),
			require = function(t)
				return load(rawget(t, "__path"))
			end,
			workspace = ws,
			game = game,
			Instance = roblox.Instance,
			Vector3 = roblox.Vector3,
			CFrame = roblox.CFrame,
			Color3 = roblox.Color3,
			Enum = roblox.Enum,
		}, { __index = _G })
		local result = luau.load(fs.readFile(path .. ".luau"), { debugName = path, environment = env })()
		cache[path] = result
		return result
	end
	local ok, Dream = pcall(load, ROOT .. "/server/World/Kit/DreamIsland")
	local built = ok and Dream.build()
	check(built ~= nil, "la isla del sueño se construye sin errores")
	local Locations = H.loadModule(ROOT .. "/shared/LifeStory/Locations")
	local spots = {}
	for _, d in (built and built:GetDescendants()) or {} do
		if d:HasTag("StorySpot") then
			spots[d:GetAttribute("SpotId")] = d
		end
	end
	local missing = {}
	for id, place in Locations.Places do
		if id:find("^Prologo") and not spots[place.Attribute.SpotId] then
			table.insert(missing, id)
		end
	end
	check(ok and #missing == 0, "tiene todas las marcas de los lugares del prólogo " .. table.concat(missing, ", "))
	-- Saltar de verdad: el sitio de después de la valla no se alcanza sin cruzarla
	if ok then
		local salto = Dream.Spots.Prologo_Salto
		local radius = Locations.Places.PrologoSalto.Radius
		check(salto.X - radius > Dream.HedgeX + 1, "el sitio de «salta la valla» está detrás de la valla (hay que saltarla)")
		local camino = Dream.Spots.Prologo_Camino
		check(camino.X - Locations.Places.PrologoCamino.Radius > Dream.Spots.Prologo_Inicio.X + Locations.Places.PrologoInicio.Radius,
			"el círculo de luz está lejos del inicio (hay que moverse)")
		check(ws:FindFirstChild("DreamIsland") ~= nil and Dream.build() == ws:FindFirstChild("DreamIsland"), "construirla dos veces no la duplica")
	end
end

---------------------------------------------------------------------
print("\n▶ 7. Conduciendo o sin seguirla: la historia no interrumpe")
---------------------------------------------------------------------
-- (bug del dueño: «me saltan misiones mientras conduzco»: en la moto, en la acera junto al parque, saltó
-- la conversación de las palomas robot de «El tirachinas del campeón» —que ni siquiera seguía— y la
-- cámara de diálogo se llevó la de la moto)
do
	local RideState = H.loadModule(ROOT .. "/shared/RideState")
	local TIRA = "Loco_N6_Tirachinas"
	local function pings(player, reason: string?): { any }
		local list = {}
		for _, payload in inbox(player, "Ping") do
			if reason == nil or payload.Reason == reason then
				table.insert(list, payload)
			end
		end
		return list
	end
	local function inject(player, questId: string, stepIndex: number)
		H.profiles[player].Story.Active[questId] = { Step = stepIndex, Count = 0, Started = os.time(), Kind = Quests[questId].Kind }
	end
	local function stepOf(player, questId: string): number?
		local prog = H.profiles[player].Story.Active[questId]
		return prog and prog.Step
	end

	-- RideState: lo que ya ponen los servicios de vehículos (Riding, Passenger, BusLine, SeatPart)
	local fake = { Attributes = {} }
	function fake:GetAttribute(key)
		return self.Attributes[key]
	end
	check(RideState.vehicleOf(fake) == nil, "RideState: a pie no va en ningún vehículo")
	fake.Attributes.Riding = "Moto"
	check(RideState.vehicleOf(fake) == "Moto", "RideState: conduciendo la moto (Riding)")
	fake.Attributes.Riding = nil
	fake.Attributes.Passenger = "Coche"
	check(RideState.inVehicle(fake), "RideState: de pasajero en un coche (Passenger)")
	fake.Attributes.Passenger = nil
	fake.Attributes.BusLine = "L1"
	check(RideState.vehicleOf(fake) == nil, "RideState: un «BusLine» que se quedó puesto sin ir sentado no cuenta (la historia no se bloquea)")
	local seat = { Name = "PassengerSeat" }
	function seat:HasTag()
		return false
	end
	function seat:FindFirstAncestorOfClass()
		return nil
	end
	function seat:IsA()
		return false
	end
	local humanoid = { SeatPart = seat }
	fake.Character = {}
	function fake.Character:FindFirstChildOfClass(class)
		return if class == "Humanoid" then humanoid else nil
	end
	check(RideState.vehicleOf(fake) == "Bus", "RideState: en el autobús (BusLine y sentado)")
	fake.Attributes.BusLine = nil
	humanoid.SeatPart = nil

	-- A) En la moto: llegar al parque SÍ cuenta; el minijuego y la conversación esperan a que te bajes
	local moto = H.newPlayer("Moto", "Nino", 100)
	task.wait(1.5)
	inject(moto, TIRA, 3) -- «Vamos al parque a practicar con latas»
	H.fromClient(moto, "Track", TIRA)
	moto.Answer = H.preferAnswer(moto)
	moto:SetAttribute("Riding", "Moto")
	moto.At = "Parque"
	check(waitFor(function()
		return stepOf(moto, TIRA) == 4
	end, 5), "conduciendo, pasar por el parque cumple «ve al parque» (Reach)")
	task.wait(3)
	check(#moto.Games == 0, "…pero el minijuego que viene después NO empieza mientras vas en la moto")
	check(#pings(moto, "Ride") >= 1 and (pings(moto, "Ride")[1].Text or ""):find("📱", 1, true) ~= nil,
		"te llega un aviso pequeño de móvil (sin parar nada)")
	moto:SetAttribute("Riding", nil)
	check(waitFor(function()
		return #moto.Games >= 1
	end, 6), "al bajarte, el minijuego empieza")
	moto:SetAttribute("Riding", "Moto") -- (vuelve a subirse mientras juega)
	check(waitFor(function()
		return stepOf(moto, TIRA) == 5
	end, 10), "acaba el minijuego: toca la escena de las palomas robot")
	task.wait(3)
	check(not H.said(moto, "Son robots, no palomas") and not DialogueService.isBusy(moto),
		"montado en la moto, la conversación de las palomas NO sale (espera)")
	local waiting = nil
	for _, payload in pings(moto, "Ride") do
		if (payload.Text or ""):find("quiere hablar contigo — bájate para hablar", 1, true) then
			waiting = payload.Text
		end
	end
	check(waiting ~= nil, ("«📱 … quiere hablar contigo — bájate para hablar» (%s)"):format(tostring(waiting)))
	local before = #pings(moto, "Ride")
	task.wait(2)
	check(#pings(moto, "Ride") == before, "el aviso sale una vez, no en cada vuelta")
	moto:SetAttribute("Riding", nil)
	check(waitFor(function()
		return H.said(moto, "Son robots, no palomas")
	end, 6), "al bajarte, la conversación llega (estaba en cola, no se pierde)")
	check(waitFor(function()
		return stepOf(moto, TIRA) == 6
	end, 6), "y la misión sigue con su paso siguiente")

	-- De pasajero (autobús) tampoco: el plan B de «habla con…» y las decisiones también esperan
	local ok, why = Service.canAutoStart(moto, TIRA)
	check(ok, "a pie y siguiéndola, lo de esta misión puede empezar solo")
	moto:SetAttribute("BusLine", "L1")
	moto.Character = fake.Character -- (sentado en un asiento del autobús)
	humanoid.SeatPart = seat
	ok, why = Service.canAutoStart(moto, TIRA)
	check(not ok and why == "Ride", "de pasajero en el autobús, no (espera a que te bajes)")
	humanoid.SeatPart = nil
	ok = Service.canAutoStart(moto, TIRA)
	check(ok, "ya de pie, con un «BusLine» que se quedó puesto (murió o le cambió el cuerpo en el autobús), sí")
	moto.Character = nil
	moto:SetAttribute("BusLine", nil)
	moto:SetAttribute("Riding", "Moto")
	local before2 = #moto.Said
	Service.interact(moto, "Actor", TIRA, "Abu")
	task.wait(0.5)
	check(#moto.Said == before2 and not DialogueService.isBusy(moto), "desde la moto no se abre ninguna conversación al tocar a un personaje")
	moto:SetAttribute("Riding", nil)

	-- B) Misión que NO sigues: no empieza sola nunca; hablando con alguien de su escena, sí
	local nino = H.newPlayer("NoLaSigue", "Nino", 100)
	task.wait(1.5)
	nino.Answer = H.preferAnswer(nino)
	inject(nino, "Loco_N1_Cosme", 1) -- la que sigue: «El vecino del garaje»
	inject(nino, TIRA, 3)
	H.fromClient(nino, "Track", "Loco_N1_Cosme")
	task.wait(0.6)
	nino.At = "Parque" -- (a pie)
	check(waitFor(function()
		return stepOf(nino, TIRA) == 4
	end, 5), "pasar por el parque cumple el paso de llegar de otra misión (Reach)")
	task.wait(3.5)
	check(#nino.Games == 0 and not H.said(nino, "Son robots"), "pero su minijuego/escena NO empieza solo: sigues «El vecino del garaje»")
	check(#pings(nino, "Untracked") == 1, "te avisa una vez (sin abrir nada) de que esa misión te espera")
	local okU, whyU = Service.canAutoStart(nino, TIRA)
	check(not okU and whyU == "Untracked", "canAutoStart: no la sigues")
	Service.interact(nino, "Actor", TIRA, "Abu")
	check(waitFor(function()
		return #nino.Games >= 1
	end, 4), "hablar con alguien de su escena (tu abu) la empieza")
	check(waitFor(function()
		return H.said(nino, "Son robots, no palomas")
	end, 12), "y lo que va justo detrás (la escena de las palomas) sigue solo: la estás jugando")

	-- Seguirla desde el panel también la empieza
	local otro = H.newPlayer("LaSigueLuego", "Nino", 100)
	task.wait(1.5)
	otro.Answer = H.preferAnswer(otro)
	inject(otro, "Loco_N1_Cosme", 1)
	inject(otro, TIRA, 3)
	H.fromClient(otro, "Track", "Loco_N1_Cosme")
	task.wait(0.6)
	otro.At = "Parque"
	task.wait(4)
	check(stepOf(otro, TIRA) == 4 and #otro.Games == 0, "el minijuego de una misión que no sigues no salta solo")
	H.fromClient(otro, "Track", TIRA)
	check(waitFor(function()
		return #otro.Games >= 1
	end, 6), "al seguirla (panel de misiones), empieza")
	check(waitFor(function()
		return H.said(otro, "Son robots, no palomas")
	end, 12), "y después su escena")

	-- C) Pasos pensados para dentro de un vehículo: siguen funcionando (Adu02: «¡Carnet nuevo! Toma las llaves»)
	local adulto = H.newPlayer("Carnet", "AdultoJoven", 100)
	task.wait(1.5)
	adulto.Answer = H.preferAnswer(adulto)
	local adu = "Adu02_Atardecer"
	local steps = Quests[adu].Steps
	local licenseStep = nil
	for i, s in steps do
		if s.Type == "Event" and s.Event == "LicenseEarned" then
			licenseStep = i
		end
	end
	check(licenseStep ~= nil and steps[licenseStep + 1].Dialogue == "Coche" and steps[licenseStep + 1].InVehicle == true,
		"la escena «Coche» de Adu02 está marcada para poder pasar dentro de un vehículo (InVehicle)")
	H.profiles[adulto].Story.Choices.ViajeAbu = { V = "Coche", D = 1 }
	inject(adulto, adu, licenseStep :: number)
	H.fromClient(adulto, "Track", adu)
	adulto:SetAttribute("Riding", "Coche") -- sigue sentado en el coche del examen
	task.wait(0.4)
	StoryEvents.emit(adulto, "LicenseEarned", { License = "B" })
	check(waitFor(function()
		return H.said(adulto, "¿Son las del coche?")
	end, 6), "aprobar el carnet sentado en el coche: su escena sale igual (paso pensado para el vehículo)")
	adulto:SetAttribute("Riding", nil)
end

---------------------------------------------------------------------
print("\n▶ 8. Partidas guardadas a medias cuando una misión gana pasos")
---------------------------------------------------------------------
do
	-- Adu01 ganó tres escenas (pasos nuevos 7, 9 y 17): quien estaba en el paso 7 (el contrato) sigue en
	-- el contrato (ahora el 8), y quien estaba en el 15 (las facturas) sigue en las facturas (el 18)
	local contrato = { Step = 7 }
	Service.migrateSteps("Adu01_PrimerContrato", contrato)
	local facturas = { Step = 15 }
	Service.migrateSteps("Adu01_PrimerContrato", facturas)
	local antes = { Step = 3 }
	Service.migrateSteps("Adu01_PrimerContrato", antes)
	check(contrato.Step == 8 and facturas.Step == 18 and antes.Step == 3, ("Adu01: el paso guardado se corre a su sitio (%d, %d, %d)"):format(contrato.Step, facturas.Step, antes.Step))
	check(Quests.Adu01_PrimerContrato.Steps[8].Dialogue == "Contrato" and Quests.Adu01_PrimerContrato.Steps[18].Dialogue == "Facturas", "y son los mismos pasos que antes")
	local llegada = { Step = 2 }
	Service.migrateSteps("Adulto_LlegadaValmar", llegada)
	check(llegada.Step == 3 and llegada.V == 2, "Llegar a Valmar: el paso de la casa sigue siendo el de la casa")
	Service.migrateSteps("Adulto_LlegadaValmar", llegada)
	check(llegada.Step == 3, "y migrar dos veces no lo mueve otra vez")
	local nueva = { Step = 2, V = Service.stepsVersion("Adu02_Atardecer") }
	Service.migrateSteps("Adu02_Atardecer", nueva)
	check(nueva.Step == 2, "una partida empezada con los pasos nuevos no se toca")
	local otra = { Step = 4 }
	Service.migrateSteps("Cole01_PrimerDia", otra)
	check(otra.Step == 4 and otra.V == nil, "las misiones que no cambiaron, tampoco")
end

print("")
if H.failures > 0 then
	print(("❌ %d comprobaciones fallan"):format(H.failures))
	process.exit(1)
end
print("✅ La historia se entiende: prólogo, resumen al volver, contexto de las misiones y diario")
process.exit(0)
