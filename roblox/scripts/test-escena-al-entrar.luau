-- Prueba: al entrar al juego no empieza ninguna escena lejos de su sitio (Lune, con StoryHarness).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-escena-al-entrar.luau   (~1 min)
--
-- Por qué existe (v114, móvil, docs/bugs/escena-al-entrar-chef-lola.png): el dueño entró (después de
-- usar el panel de pruebas para desbloquearlo todo y hacerse adulto) y nada más aparecer empezó la
-- bienvenida de «Una nueva vida en Valmar»: «Chef Lola: Tengo una cafetería aquí mismo», con las
-- bandas de cine, él solo en mitad de un solar de césped, sin Lola ni la cafetería. Cadena:
--   1. Roblox pone a todos en la entrada del juego (la Plaza Mayor) y PositionService los lleva luego a
--      su sitio guardado (atributo SpawnReady). La historia dejaba de esperar ese atributo a los 10 s
--      (en el móvil tarda más) y el paso «Ve a la Plaza Mayor» se cumplía en la entrada.
--   2. La escena de bienvenida (paso de cine) empezaba allí mismo con los actores al lado de la
--      entrada… y un momento después el jugador aparecía en su sitio, lejos, con los subtítulos.
-- Ahora:
--   * mientras no ha aparecido en su sitio, nada se cumple por estar en un sitio ni empieza nada solo
--     (LifeStoryService.spawnSettled, canAutoStart "Spawn");
--   * una escena de cine solo empieza donde ocurre (su Place o el del «Ve a…» de antes); lejos espera
--     y la tarjeta y el GPS llevan hasta allí ("Away");
--   * y solo si quien habla en ella está (o tiene sitio donde ponerlo); si no, no se juega ("Actors");
--     un sitio que no existe en el mapa tampoco ("NoPlace");
--   * los personajes que una misión pone solo en sus pasos (Lola en la cafetería) aparecen.

local process = require("@lune/process")
local roblox = require("@lune/roblox")
local task = require("@lune/task")

local H = require("./lib/StoryHarness")
local check = H.check
local ROOT = H.ROOT
local V = roblox.Vector3.new

local Service = H.boot()
local Cine = H.loadModule(ROOT .. "/server/Services/CinematicService")
local HappeningIndex = H.loadModule(ROOT .. "/shared/LifeStory/HappeningIndex")
local Loc = H.mocks[ROOT .. "/server/Services/LocationService"]

-- Qué escenas se lanzan (y a quién)
local played: { { any } } = {}
local realPlay = Cine.play
Cine.play = function(player, id)
	table.insert(played, { player, id })
	return realPlay(player, id)
end
local function playedFor(player, id: string): boolean
	for _, entry in played do
		if entry[1] == player and entry[2] == id then
			return true
		end
	end
	return false
end

-- Un mapa con distancias: la Plaza Mayor, la cafetería y un sitio que «no existe»
local PLACES = { PlazaCentro = V(-60, 0, -50), CafeteriaCentral = V(60, 0, -16), Correos = V(240, 0, -16) }
local MISSING: { [string]: boolean } = {}
local instance = {}
function instance:IsDescendantOf()
	return true
end
Loc.resolve = function(_, placeId)
	if MISSING[placeId] then
		return nil
	end
	local position = PLACES[placeId] or V(0, 0, 0)
	return { Instance = instance, Position = position, CFrame = roblox.CFrame.new(position), Radius = 10, Zone = "Valmar Centro", PlaceId = placeId }
end
Loc.positionOf = function(player)
	return player.Pos or V(0, 0, 0)
end
local FAR = V(-100, 0, -160) -- (el solar de césped entre la Plaza Mayor y los Jardines)

local function waitFor(condition: () -> boolean, seconds: number): boolean
	local since = os.clock()
	while os.clock() - since < seconds do
		if condition() then
			return true
		end
		task.wait(0.1)
	end
	return condition()
end

local function adult(name: string, active: { [string]: any }, tracked: string?): any
	return {
		Money = 9999999,
		Stats = { PlaySeconds = 99999 },
		Life = { Stage = "Adulto", AgeYears = 30, StageSeconds = 100 },
		Education = { Subjects = {}, Exams = {}, Degrees = {}, Attendance = 0 },
		Items = {},
		Story = {
			Version = 1, Chapter = "Adulto_NuevaVida", Chapters = {}, Active = active, Completed = {}, Declined = {},
			Choices = {}, Flags = {}, Discovered = {}, NpcMemory = {}, Events = {}, Tracked = tracked, PrologueDone = 1,
		},
	}
end
local function llegada(step: number): { [string]: any }
	return { Adulto_LlegadaValmar = { Step = step, Count = 0, Started = os.time(), Kind = "Main", V = Service.stepsVersion("Adulto_LlegadaValmar") } }
end
local function stepOf(player, questId: string): number?
	local prog = H.profiles[player].Story.Active[questId]
	return prog and prog.Step
end
local function near(a: any, b: any): boolean
	return typeof(a) == "Vector3" and (a - b).Magnitude < 1
end

print("1. Entrar en el móvil: aún en la entrada del juego (la plaza), antes de aparecer en su sitio")
local phone
do
	H.defaultAttributes.SpawnReady = false -- (PositionService aún no lo ha puesto en su sitio)
	phone = H.newPlayer("Movil", nil, nil, adult("Movil", llegada(1), "Adulto_LlegadaValmar"))
	H.defaultAttributes.SpawnReady = nil
	phone.At, phone.Pos = "PlazaCentro", PLACES.PlazaCentro -- (Roblox lo pone en la entrada: la Plaza Mayor)
	task.wait(13) -- (más que la espera del arranque, 10 s: la historia ya ha arrancado)
	check(H.lastState(phone) ~= nil, "la historia arranca igual (llega la tarjeta)")
	check(stepOf(phone, "Adulto_LlegadaValmar") == 1, "«Ve a la Plaza Mayor» NO se cumple en la entrada del juego")
	check(not playedFor(phone, "Adulto_Bienvenida"), "y la bienvenida de Lola y Ernesto no empieza")
	-- PositionService lo pone donde lo dejó: el solar de césped, lejos de la plaza
	phone.At, phone.Pos = nil, FAR
	phone:SetAttribute("SpawnReady", true)
	task.wait(2)
	check(stepOf(phone, "Adulto_LlegadaValmar") == 1 and not playedFor(phone, "Adulto_Bienvenida"), "ya en su sitio, lejos: ninguna escena, el paso sigue siendo «Ve a la Plaza Mayor»")
	local state = H.lastState(phone)
	check(state and state.Tracked and state.Tracked.QuestId == "Adulto_LlegadaValmar" and state.Tracked.StepType == "Reach", "la tarjeta enseña la misión y el paso de ir")
	check(near(phone:GetAttribute("StoryTarget"), PLACES.PlazaCentro), "y el GPS lleva a la Plaza Mayor")
	-- Llega andando
	phone.At, phone.Pos = "PlazaCentro", PLACES.PlazaCentro
	check(waitFor(function()
		return playedFor(phone, "Adulto_Bienvenida")
	end, 5), "al llegar a la plaza, empieza la bienvenida (donde ocurre)")
end

print("2. Una escena que esperaba (no seguías la misión) y te has ido lejos: espera en su sitio")
do
	local active = llegada(1)
	active.Side_TardeDePlaya = { Step = 1, Count = 0, Started = os.time(), Kind = "Side" }
	local p = H.newPlayer("Lejos", nil, nil, adult("Lejos", active, "Side_TardeDePlaya"))
	p.At, p.Pos = "PlazaCentro", PLACES.PlazaCentro -- (pasa por la plaza siguiendo otra misión)
	check(waitFor(function()
		return stepOf(p, "Adulto_LlegadaValmar") == 2
	end, 6), "pasa por la plaza: «Ve a la Plaza Mayor» se cumple")
	task.wait(1)
	check(not playedFor(p, "Adulto_Bienvenida"), "la escena espera: sigues otra misión")
	p.At, p.Pos = nil, FAR -- (se va lejos)
	H.fromClient(p, "Track", "Adulto_LlegadaValmar") -- (y luego la vuelve a seguir)
	task.wait(2)
	check(not playedFor(p, "Adulto_Bienvenida"), "la sigues pero estás lejos: la escena NO empieza en mitad de la nada")
	local state = H.lastState(p)
	check(state and state.Tracked and state.Tracked.QuestId == "Adulto_LlegadaValmar" and state.Tracked.TextKey == "QUEST.LLEGADA.PLAZA", "la tarjeta dice adónde ir («Ve a la Plaza Mayor»)")
	check(near(p:GetAttribute("StoryTarget"), PLACES.PlazaCentro), "y el GPS lleva a la Plaza Mayor")
	p.At, p.Pos = "PlazaCentro", PLACES.PlazaCentro
	check(waitFor(function()
		return playedFor(p, "Adulto_Bienvenida")
	end, 4), "al volver a la plaza, empieza")
end

print("3. Panel de pruebas: «Desbloquear todo» y «Hazme adulto», salir y volver a entrar lejos")
do
	local Tester = H.loadModule(ROOT .. "/server/Services/TesterService")
	local kid = H.newPlayer("DueñoPruebas", "Nino", 100)
	H.Config.Testers = { kid.UserId }
	task.wait(0.5)
	-- «Desbloquear todo» (TesterService, probado entero en test-tester) visto desde la historia: sin
	-- requisitos, dinero infinito y nivel máximo (avisa LevelUp a la historia)
	local data = H.profiles[kid]
	data.Tester = { Bypass = true, Money = true, RealMoney = data.Money }
	data.Money = 9999999
	data.Progress = { Level = 100, Xp = 0 }
	kid:SetAttribute("TesterBypass", true)
	local okUnlock, unlockErr = pcall(H.StoryEvents.emit, kid, "LevelUp", { Level = 100 })
	check(okUnlock, "«Desbloquear todo» no rompe la historia" .. (if okUnlock then "" else ": " .. tostring(unlockErr)))
	check(Tester.handle(kid, "Action", "MakeAdult") == true, "«Hazme adulto»")
	task.wait(1)
	local story = H.profiles[kid].Story
	local main = nil
	for id, prog in story.Active do
		if prog.Kind == "Main" then
			main = id
		end
	end
	check(main ~= nil, ("ya adulto, con la principal de su capítulo (%s)"):format(tostring(main)))
	local before = #played
	local saved = H.leave(kid)
	H.defaultAttributes.SpawnReady = false
	local back = H.rejoin(kid, saved)
	H.defaultAttributes.SpawnReady = nil
	back.At, back.Pos = "PlazaCentro", PLACES.PlazaCentro -- (la entrada del juego)
	task.wait(12)
	back.At, back.Pos = nil, FAR
	back:SetAttribute("SpawnReady", true)
	task.wait(2)
	local scenes = {}
	for i = before + 1, #played do
		if played[i][1] == back then
			table.insert(scenes, played[i][2])
		end
	end
	check(#scenes == 0, ("al volver a entrar (lejos) no empieza ninguna escena (%s)"):format(table.concat(scenes, ", ")))
	local state = H.lastState(back)
	check(state and state.Tracked ~= nil, "la tarjeta enseña su misión")
	H.Config.Testers = {}
end

print("4. Una escena sin su sitio o sin quien habla en ella no se juega")
do
	-- Una escena de prueba: Nadia (de la misión) habla, pero la misión no la pone en ningún sitio
	HappeningIndex.all().Prueba_SinActor = {
		Anchors = { Yo = "Player" },
		Tracks = {
			Actors = { { At = 0, Use = { Key = "Nadia", Npc = "Nadia" } } },
			Camera = { { At = 0, Duration = 3, Shot = "General" } },
			Dialogue = { { At = 0.5, S = "Nadia", T = "Hola." } },
		},
	}
	H.Quests.Prueba_EscenaSinActor = {
		Id = "Prueba_EscenaSinActor",
		Kind = "Side",
		TitleKey = "Prueba",
		Steps = {
			{ Type = "Reach", Place = "CafeteriaCentral", Text = "Ve a la cafetería" },
			{ Type = "Cinematic", Id = "Prueba_SinActor" },
			{ Type = "Wait", Seconds = 999, Text = "Fin" },
		},
	}
	H.Quests.Prueba_EscenaSinSitio = {
		Id = "Prueba_EscenaSinSitio",
		Kind = "Side",
		TitleKey = "Prueba",
		Steps = {
			{ Type = "Cinematic", Id = "Adulto_Bienvenida", Place = "Correos" },
			{ Type = "Wait", Seconds = 999, Text = "Fin" },
		},
	}
	local wait = Service.SceneActorWait
	Service.SceneActorWait = 3
	local p = H.newPlayer("SinActor", nil, nil, adult("SinActor", {
		Prueba_EscenaSinActor = { Step = 1, Count = 0, Started = os.time(), Kind = "Side" },
	}, "Prueba_EscenaSinActor"))
	p.At, p.Pos = "CafeteriaCentral", PLACES.CafeteriaCentral
	check(waitFor(function()
		return stepOf(p, "Prueba_EscenaSinActor") == 2
	end, 6), "llega a la cafetería")
	H.fromClient(p, "Track", "Prueba_EscenaSinActor") -- (la sigue: al entrar empezó la principal de su capítulo)
	task.wait(1.5)
	check(not playedFor(p, "Prueba_SinActor"), "Nadia no está en ningún sitio: la escena no empieza")
	check(waitFor(function()
		return stepOf(p, "Prueba_EscenaSinActor") == 3
	end, 8) and not playedFor(p, "Prueba_SinActor"), "pasado el tope, no se juega y la historia sigue")
	Service.SceneActorWait = wait

	MISSING.Correos = true
	local q = H.newPlayer("SinSitio", nil, nil, adult("SinSitio", {}, nil))
	task.wait(1)
	H.profiles[q].Story.Active.Prueba_EscenaSinSitio = { Step = 1, Count = 0, Started = os.time(), Kind = "Side" }
	H.profiles[q].Story.Tracked = "Prueba_EscenaSinSitio"
	Service.resetQuest(q, "Prueba_EscenaSinSitio")
	check(waitFor(function()
		return stepOf(q, "Prueba_EscenaSinSitio") == 2
	end, 4) and not playedFor(q, "Adulto_Bienvenida"), "su sitio no existe en el mapa: no se juega y la historia sigue")
	MISSING.Correos = nil
end

print("5. Los personajes que la misión pone solo en un paso aparecen en su sitio")
do
	local p = H.newPlayer("Cafe", nil, nil, adult("Cafe", llegada(4), "Adulto_LlegadaValmar"))
	p.Pos = FAR
	task.wait(2)
	local scene = H.scenes[p] and H.scenes[p].Adulto_LlegadaValmar
	local lola = scene and scene.Actors.Lola
	check(lola ~= nil and lola.Place == "CafeteriaCentral", "Lola espera en la cafetería («La primera invita la casa»)")
end

print("6. Los datos de la bienvenida")
do
	local def = HappeningIndex.get("Adulto_Bienvenida")
	local lastLine: { [string]: number } = {}
	for _, line in def.Tracks.Dialogue do
		lastLine[line.S] = math.max(lastLine[line.S] or 0, line.At or 0)
	end
	local ok = true
	for _, d in def.Tracks.Actors do
		if d.Exit and lastLine[d.Exit.Key] and d.At <= lastLine[d.Exit.Key] then
			ok = false
			print(("    %s se va a los %.1f s y habla a los %.1f s"):format(d.Exit.Key, d.At, lastLine[d.Exit.Key]))
		end
	end
	check(ok, "nadie se va de la escena mientras le quedan frases")
	local cafe = false
	for _, line in def.Tracks.Dialogue do
		cafe = cafe or (line.S == "Lola" and line.T:find("cafetería", 1, true) ~= nil and line.T:find("aquí mismo", 1, true) == nil)
	end
	check(cafe, "Lola no dice que la cafetería está «aquí mismo» (está a dos pasos de la plaza)")
end

print(("\n%s"):format(if H.failures == 0 then "✅ Todo correcto" else ("❌ %d fallos"):format(H.failures)))
process.exit(if H.failures == 0 then 0 else 1)
