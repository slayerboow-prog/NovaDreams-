-- Prueba del MOTOR DE ESCENAS de la historia (Lune, fuera de Roblox).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-scenes.luau
--
-- Comprueba:
--   1. Todas las escenas (shared/LifeStory/Happenings) están bien escritas: pistas conocidas y con At,
--      anclas que existen (lugares de Locations), efectos del catálogo, emociones, criaturas, actores
--      que aparecen antes de moverse, esperas con una condición, Duration que cubre la última pista.
--   2. El secuenciador (Sequencer): orden de la línea de tiempo, qué toca entre dos instantes, reloj con
--      pausas (esperas), condiciones por lo que hizo el jugador, plan al saltar, duración máxima.
--   3. La cámara (CameraShots): plano activo, travelling, órbita, seguir, fijo, zoom, temblores y que
--      mira a donde debe.
--   4. El director (HappeningService) con dobles: actores (prestados y nuevos), emociones, esperas
--      («¡Cúbrete!» pulsado o no, acercarse a un punto), memoria del mundo, SALTAR (deja las mismas
--      consecuencias), MULTIJUGADOR (dos jugadores a la vez sin bloquearse; uno salta y el otro sigue),
--      escena ligera a la vez que una con cámara, espectadores cercanos, portal que te lleva al otro
--      lado (solo si estás junto a él), y el modo sin pantalla (consecuencias al momento).
--   5. Las criaturas y las emociones (StoryCreatures, ActorMoods).

local roblox = require("@lune/roblox")
local task = require("@lune/task")
local L = require("./lib/ModuleLoader")

local Vector3, CFrame = roblox.Vector3, L.CFrame
local check = L.check

-- Servicios que piden los módulos del servidor
local playerList = {}
local removing = {}
L.services.Players = {
	GetPlayers = function()
		return playerList
	end,
	PlayerRemoving = {
		Connect = function(_, fn)
			table.insert(removing, fn)
		end,
	},
	PlayerAdded = { Connect = function() end },
}

local Sequencer = L.load("src/shared/LifeStory/Sequencer")
local CameraShots = L.load("src/shared/CameraShots")
local HappeningIndex = L.load("src/shared/LifeStory/HappeningIndex")
local Locations = L.load("src/shared/LifeStory/Locations")
local Cast = L.load("src/shared/LifeStory/Cast")
local Catalog = L.load("src/shared/StoryFxCatalog")
local SkyMoods = L.load("src/shared/SkyMoods")
local ActorMoods = L.load("src/shared/LifeStory/ActorMoods")
local StoryCreatures = L.load("src/shared/LifeStory/StoryCreatures")

---------------------------------------------------------------------
print("1. Escenas bien escritas")
---------------------------------------------------------------------
local ctx = {
	Fx = Catalog.names(),
	SkyMoods = SkyMoods.names(),
	Moods = ActorMoods.names(),
	Creatures = StoryCreatures.names(),
	Places = Locations.Places,
	Zones = Locations.Zones,
	Cast = Cast.People,
}
local count = 0
for id, def in HappeningIndex.all() do
	count += 1
	local errors = Sequencer.validate(id, def, ctx)
	for _, e in errors do
		print("     " .. e)
	end
	check(#errors == 0, ("escena %s sin errores"):format(id))
end
check(count >= 3, ("hay escenas (%d)"):format(count))
check(HappeningIndex.has("Grieta_Caen") and HappeningIndex.has("Grieta_Recoger"), "las de la misión de ejemplo existen")

-- Una escena mal escrita se detecta
local bad = {
	Duration = 2,
	Anchors = { A = "Place:NoExiste" },
	Tracks = {
		Camera = { { At = 0, Duration = 1, Fixed = { "B" }, Look = { "A" } } },
		Fx = { { At = 1, Play = "NoEsUnEfecto" } },
		Actors = { { At = 0.5, Move = { Key = "X", To = { "A" } } } },
		Wait = { { At = 1 } },
		Lines = { { At = 3, Speaker = "Desconocido", Text = "hola" } },
		Inventada = {},
	},
}
local errors = Sequencer.validate("Mala", bad, ctx)
local joined = table.concat(errors, "\n")
check(joined:find("lugar desconocido", 1, true) or joined:find("no válida", 1, true), "detecta un ancla con un lugar que no existe")
check(joined:find("ancla desconocida 'B'", 1, true) ~= nil, "detecta un plano con un ancla sin definir")
check(joined:find("efecto desconocido", 1, true) ~= nil, "detecta un efecto que no está en el catálogo")
check(joined:find("antes de que aparezca", 1, true) ~= nil, "detecta mover a un actor que no ha aparecido")
check(joined:find("UNA condición", 1, true) ~= nil, "detecta una espera sin condición")
check(joined:find("pista desconocida", 1, true) ~= nil, "detecta una pista inventada")
check(joined:find("Duration", 1, true) ~= nil, "detecta una Duration más corta que la última pista")

---------------------------------------------------------------------
print("2. Secuenciador")
---------------------------------------------------------------------
local def = HappeningIndex.get("Grieta_Caen")
local tl = Sequencer.compile("Grieta_Caen", def)
local sorted = true
for i = 2, #tl.Events do
	if tl.Events[i].At < tl.Events[i - 1].At then
		sorted = false
	end
end
check(sorted, "la línea de tiempo está en orden")
check(math.abs(tl.Duration - 16.5) < 1e-6, "la duración es la de la escena (16,5 s)")
check(#tl.Waits == 1 and tl.Waits[1].At == 1.6, "tiene una espera en 1,6 s («¡Cúbrete!»)")
check(#tl.Shots == 7, "siete planos de cámara")
-- Mismo segundo: el mundo y los actores antes que la cámara
local first = Sequencer.due(tl, -1, 0)
check(first[1] and (first[1].Track == "Actors" or first[1].Track == "World"), "en el segundo 0 van primero los actores")
local serverAt0 = Sequencer.due(tl, -1, 0, "Server")
local onlyServer = true
for _, e in serverAt0 do
	if Sequencer.sideOf(e.Track) == "Client" then
		onlyServer = false
	end
end
check(onlyServer and #serverAt0 >= 2, "el servidor solo recibe sus pistas (actores, mundo, esperas)")
local between = Sequencer.due(tl, 4.8, 6.1, "Server")
local worldKeys = {}
for _, e in between do
	if e.Track == "World" then
		for k in e.Data.Set do
			table.insert(worldKeys, k)
		end
	end
end
check(#worldKeys == 3, "entre 4,8 y 6,1 s caen los tres cráteres")
check(Sequencer.nextWait(tl, -1) == tl.Waits[1] and Sequencer.nextWait(tl, 1.6) == nil, "la siguiente espera (y ninguna después de cumplirla)")
-- Reloj con pausa
local run = { StartAt = 100, Paused = 0 }
check(math.abs(Sequencer.sceneTime(run, 101.5) - 1.5) < 1e-9, "el reloj de la escena corre desde StartAt")
run.PausedAt = 101.6
check(math.abs(Sequencer.sceneTime(run, 110) - 1.6) < 1e-9, "parada en una espera, el reloj no avanza")
run.Paused, run.PausedAt = 8.4, nil
check(math.abs(Sequencer.sceneTime(run, 110.5) - 2.1) < 1e-9, "al seguir, descuenta lo que estuvo parada")
-- Condiciones por lo que hizo el jugador
check(Sequencer.passes({ If = { Input = "Cubrirse" } }, { Cubrirse = true }), "frase si te cubriste")
check(not Sequencer.passes({ If = { Input = "Cubrirse" } }, {}), "no sale si no te cubriste")
check(Sequencer.passes({ IfNot = { Input = "Cubrirse" } }, { Cubrirse = false }), "la otra frase si no")
-- Plan al saltar a mitad
local plan = Sequencer.skipPlan(tl, 5, {})
local planWorld, planSpawnOrDespawn, planGesture = 0, 0, 0
for _, e in plan do
	if e.Track == "World" then
		planWorld += 1
	elseif e.Data.Spawn or e.Data.Despawn then
		planSpawnOrDespawn += 1
	elseif e.Data.Gesture then
		planGesture += 1
	end
end
check(planWorld == 2, "saltando en el 5: faltan dos cráteres por apuntar (patio y camino)")
check(planSpawnOrDespawn == 2, "…y la aparición y la ida de Chispa")
check(planGesture == 0, "…pero no los gestos (no dejan consecuencias)")
check(Sequencer.maxDuration(tl) >= tl.Duration + 3 - 1e-6, "la duración máxima cuenta lo que puede durar la espera")

---------------------------------------------------------------------
print("3. Cámara")
---------------------------------------------------------------------
local anchors = {
	A = CFrame.new(0, 0, 0),
	B = CFrame.new(100, 0, 0),
}
local function resolve(name)
	return anchors[name]
end
local shots = {
	{ At = 0, Duration = 2, From = { "A", Vector3.new(0, 5, 10) }, To = { "A", Vector3.new(0, 5, 20) }, Look = { "A" }, Easing = "Linear" },
	{ At = 2, Duration = 2, Orbit = "B", Radius = 10, Height = 4, FromAngle = 0, ToAngle = 90, Easing = "Linear" },
	{ At = 4, Duration = 1, Fixed = { "A", Vector3.new(5, 2, 0) }, Look = { "B" }, Fov = { 70, 40 }, Easing = "Linear", Cut = "Dip" },
	{ At = 5, Duration = 1, Follow = "B", Offset = Vector3.new(0, 3, 8) },
}
local shot, u = CameraShots.active(shots, 1)
check(shot == shots[1] and math.abs(u - 0.5) < 1e-6, "plano activo y progreso (travelling a la mitad)")
local cf = CameraShots.base(shot, u, resolve)
check(cf and (cf.Position - Vector3.new(0, 5, 15)).Magnitude < 1e-4, "el travelling está a medio camino")
check(cf and cf.LookVector:Dot((Vector3.new(0, 0, 0) - cf.Position).Unit) > 0.999, "y mira a su ancla")
shot, u = CameraShots.active(shots, 4)
check(shot == shots[3], "a los 4 s, el plano fijo")
shot, u = CameraShots.active(shots, 2.5)
cf = CameraShots.base(shot, u, resolve)
local flat = Vector3.new(cf.Position.X - 100, 0, cf.Position.Z)
check(math.abs(flat.Magnitude - 10) < 1e-3 and math.abs(cf.Position.Y - 4) < 1e-3, "la órbita va a su radio y altura")
shot, u = CameraShots.active(shots, 4.5)
check(math.abs(CameraShots.fov(shot, u) - 55) < 1e-6, "zoom: a mitad del plano, campo de visión a mitad")
shot, u = CameraShots.active(shots, 9)
check(shot == shots[4] and u == 1, "después del último plano se queda congelado en él")
cf = CameraShots.base(shot, u, resolve)
check(cf and (cf.Position - Vector3.new(100, 3, 8)).Magnitude < 1e-4, "seguir: detrás y encima de lo que sigue")
anchors.B = CFrame.new(150, 0, 0)
cf = CameraShots.base(shot, u, resolve)
check(cf and (cf.Position - Vector3.new(150, 3, 8)).Magnitude < 1e-4, "seguir: si se mueve, la cámara va con él")
local shakes = { { At = 1, Strength = 1, Seconds = 1 } }
check(CameraShots.impulse(shakes, 0.9) == 0, "antes del golpe no tiembla")
check(CameraShots.impulse(shakes, 1) > 0.99 and CameraShots.impulse(shakes, 1.5) < 0.3, "el golpe tiembla fuerte y se apaga")
check(CameraShots.impulse(shakes, 2.1) == 0, "y se acaba")
check(CameraShots.cframe({ Fixed = { "Nada" }, Look = { "A" } }, 0, resolve, 0, 0) == nil, "un ancla que no existe no rompe: no hay plano")
check(CameraShots.Cuts.Dip and CameraShots.Cuts.Flash and CameraShots.Cuts.Fade and CameraShots.Cuts.Cut, "transiciones: corte, fundido rápido, lento y destello")

---------------------------------------------------------------------
print("4. Director (HappeningService)")
---------------------------------------------------------------------
-- Dobles
local clock = 1000
local inbox = {} -- [player] = { {Kind, Payload} }
local fakeRemote = {
	FireClient = function(_, player, kind, payload)
		inbox[player] = inbox[player] or {}
		table.insert(inbox[player], { Kind = kind, Payload = payload })
	end,
}
local remoteOn = true
local actorLog = {}
local function fakeModel(name)
	local m = { Name = name, Attributes = {}, Parent = true, Pivot = CFrame.new(0, 0, 0) }
	function m:SetAttribute(k, v)
		self.Attributes[k] = v
	end
	function m:GetAttribute(k)
		return self.Attributes[k]
	end
	function m:GetPivot()
		return self.Pivot
	end
	return m
end
local fakeActors = {
	spawn = function(player, key, spec, cf)
		local m = fakeModel(key)
		m.Pivot = cf
		m.Owner = player
		m:SetAttribute("HappeningKey", key)
		if spec.Mood then
			m:SetAttribute("Mood", ActorMoods.name(spec.Mood))
		end
		table.insert(actorLog, { Op = "Spawn", Player = player, Key = key, Spec = spec })
		return m
	end,
	bind = function(model, key)
		model:SetAttribute("HappeningKey", key)
		table.insert(actorLog, { Op = "Bind", Key = key })
	end,
	unbind = function(model)
		model:SetAttribute("HappeningKey", nil)
		model:SetAttribute("Mood", nil)
		model:SetAttribute("LookAt", nil)
		table.insert(actorLog, { Op = "Unbind", Key = model.Name })
	end,
	mood = function(model, mood)
		model:SetAttribute("Mood", ActorMoods.name(mood))
		table.insert(actorLog, { Op = "Mood", Key = model.Name, Mood = mood })
	end,
	look = function(model, target)
		model:SetAttribute("LookAt", target)
		table.insert(actorLog, { Op = "Look", Key = model.Name, Target = target })
	end,
	move = function(model, to, run)
		table.insert(actorLog, { Op = "Move", Key = model.Name, To = to, Run = run })
		model.Pivot = CFrame.new(to)
		model:SetAttribute("Arrived", true)
	end,
	place = function(model, to)
		table.insert(actorLog, { Op = "Place", Key = model.Name, To = to })
		model.Pivot = CFrame.new(to)
	end,
	play = function(model, name)
		table.insert(actorLog, { Op = "Play", Key = model.Name, Anim = name })
	end,
	despawn = function(model)
		model.Parent = nil
		table.insert(actorLog, { Op = "Despawn", Key = model.Name })
	end,
}
local sceneActors = {} -- [player] = { Cosme = model, Pip = model }
local teleports = {}
local gestures = {}
local fakeScene = {
	actorOf = function(player, npc)
		return sceneActors[player] and sceneActors[player][npc]
	end,
	gesture = function(player, npc, name)
		table.insert(gestures, { Player = player, Npc = npc, Anim = name })
	end,
	teleportTo = function(player, target)
		table.insert(teleports, { Player = player, Target = target })
	end,
}
local done, seen = {}, {}
local fakeCinematic = {
	clientDone = function(player, id)
		table.insert(done, { Player = player, Id = id })
	end,
	clientSeen = function(player, id)
		table.insert(seen, { Player = player, Id = id })
	end,
}
-- Memoria del mundo: la de verdad (WorldMemoryService) con un DataService de mentira
local profiles = {}
local fakeData = {
	get = function(player)
		return profiles[player]
	end,
	onLoaded = function() end,
}
L.mock("src/server/Services/DataService", fakeData)
local WorldMemoryService = L.load("src/server/Services/WorldMemoryService")
WorldMemoryService._inject(fakeData, function(_, d)
	return CFrame.new(10, 0, 10)
end)

local roots = {}
local Happening = L.load("src/server/Services/HappeningService")
Happening._inject({
	now = function()
		return clock
	end,
	remote = function()
		return if remoteOn then fakeRemote else nil
	end,
	actors = function()
		return fakeActors
	end,
	world = function()
		return WorldMemoryService
	end,
	scene = function()
		return fakeScene
	end,
	cinematic = function()
		return fakeCinematic
	end,
	locate = function(_, placeId, offset)
		local base = ({ GarajeCosme = Vector3.new(0, 0, 0), FuenteParque = Vector3.new(300, 0, 0), JuegosColegio = Vector3.new(0, 0, 300), CaminoAlCole = Vector3.new(-300, 0, 0) })[placeId] or Vector3.new(50, 0, 50)
		return CFrame.new(base + (offset or Vector3.zero))
	end,
	zone = function()
		return Vector3.new(0, 0, 0)
	end,
	root = function(player)
		return roots[player]
	end,
	ground = function(p)
		return p
	end,
	stream = function() end,
	wait = function()
		task.wait(0.001)
	end,
})

local function newPlayer(name, id)
	local p = L.player(name, id)
	table.insert(playerList, p)
	profiles[p] = { Story = { Completed = {}, Flags = {}, Choices = {}, Discovered = {}, Memories = {}, Active = {} }, Life = { Stage = "Nino" } }
	roots[p] = { Position = Vector3.new(0, 3, 0), CFrame = CFrame.new(0, 3, 0) }
	sceneActors[p] = { Cosme = fakeModel("Cosme"), Pip = fakeModel("Pip") }
	return p
end

local function messages(player, kind)
	local list = {}
	for _, m in inbox[player] or {} do
		if m.Kind == kind then
			table.insert(list, m.Payload)
		end
	end
	return list
end

-- Avanza el reloj de mentira (y deja correr los bucles de las escenas)
local function advance(seconds: number)
	local steps = math.ceil(seconds / 0.05)
	for _ = 1, steps do
		clock += seconds / steps
		Happening._step()
		task.wait(0.001)
	end
end

local A = newPlayer("Ana", 1)
local B = newPlayer("Beto", 2)

local maxSeconds = Happening.play(A, "Grieta_Caen")
check(maxSeconds > 16.5, ("play devuelve el tope de lo que puede durar (%.1f s)"):format(maxSeconds))
task.wait(0.01) -- (el aviso sale en otro hilo)
advance(0.05)
local playA = messages(A, "Play")[1]
check(playA ~= nil, "el jugador recibe la escena (Play)")
check(playA and playA.StartAt > 1000 and playA.Anchors.Parque ~= nil, "con la hora de empezar y sus anclas (su parque)")
check(playA and playA.Anchors.Parque.Position.X == 297, "el ancla del parque lleva el desplazamiento del objeto de la misión")
check(playA and playA.Names.Pip ~= nil and playA.Names.Chispa == "Chispa" and playA.Voices.Pip ~= nil, "nombres y voces de quien habla (Pip, Chispa)")
check(messages(B, "Play")[1] == nil, "el otro jugador NO recibe la escena de Ana")
check(#seen == 1, "la historia sabe que la escena se está viendo")

advance(1.3) -- t ≈ 0.8 (empieza medio segundo después del aviso)
local bound = 0
for _, entry in actorLog do
	if entry.Op == "Bind" then
		bound += 1
	end
end
check(bound == 2, "Cosme y Pip de la misión pasan a la escena (prestados)")
check(sceneActors[A].Pip:GetAttribute("Mood") == "Fear", "Pip tiene miedo")
check(sceneActors[A].Pip:GetAttribute("LookAt") == "Rift", "y mira a la Grieta")

-- Llega a la espera (1,6 s) y se para
advance(1.5)
local pauseA = messages(A, "Pause")[1]
check(pauseA and pauseA.At == 1.6, "la escena se para en «¡Cúbrete!»")
-- Mientras, Beto empieza la suya
Happening.play(B, "Grieta_Caen")
task.wait(0.01)
advance(2)
check(WorldMemoryService.get(A, "Cielo.Crater.Parque") == nil, "parada: el meteorito aún no ha caído")
check(messages(B, "Play")[1] ~= nil, "Beto empieza su escena aunque Ana esté parada")
-- Ana pulsa
local serialA = playA.Run
Happening.onClient(A, "Input", serialA, "Cubrirse")
advance(0.1)
local resumeA = messages(A, "Resume")[1]
check(resumeA and resumeA.Inputs.Cubrirse == true, "al pulsar a tiempo sigue, y se sabe que te cubriste")
check(resumeA and resumeA.Paused > 1.5, ("y descuenta el tiempo parada (%.1f s)"):format(resumeA and resumeA.Paused or -1))
-- Beto llega a su espera y no pulsa: a los 3 s sigue sola
advance(4)
local resumeB = messages(B, "Resume")[1]
check(resumeB and resumeB.Inputs.Cubrirse == false, "Beto no pulsa: a los 3 s sigue sola (sin cubrirse)")
-- Ana sigue su escena: cráter del parque
advance(1.5)
check(WorldMemoryService.get(A, "Cielo.Crater.Parque") == "Humeante", "el meteorito de Ana cae: cráter humeante en SU memoria")
check(WorldMemoryService.get(B, "Cielo.Crater.Parque") == nil, "…y no en la de Beto (aún no le ha caído)")
check(A.Attributes.WorldState and A.Attributes.WorldState:find("Humeante", 1, true) ~= nil, "la memoria se replica al cliente (WorldState)")
check(A.Attributes.StageSets and A.Attributes.StageSets:find("CraterParque", 1, true) ~= nil, "y el decorado del cráter aparece en sus StageSets")
advance(1)
local chispa = nil
for _, entry in actorLog do
	if entry.Op == "Spawn" and entry.Key == "Chispa" and entry.Player == A then
		chispa = entry
	end
end
check(chispa ~= nil and chispa.Spec.Creature == "Chispa", "de su cráter sale Chispa (criatura)")
-- Ana salta la escena
Happening.onClient(A, "Skip", serialA)
local stopA = messages(A, "Stop")[1]
check(stopA and stopA.Skipped == true, "Ana salta: su escena para")
check(WorldMemoryService.get(A, "Cielo.Crater.Camino") == "Humeante" and WorldMemoryService.get(A, "Cielo.Crater.Patio") == "Humeante", "saltar deja las mismas consecuencias (los tres cráteres)")
check(sceneActors[A].Pip:GetAttribute("Mood") == nil and sceneActors[A].Pip:GetAttribute("HappeningKey") == nil, "los actores prestados vuelven a ser los de la misión")
local doneA = 0
for _, d in done do
	if d.Player == A and d.Id == "Grieta_Caen" then
		doneA += 1
	end
end
check(doneA == 1, "la historia de Ana sigue (clientDone una vez)")
check(messages(B, "Stop")[1] == nil, "la escena de Beto sigue (no la para el salto de Ana)")
check(not Happening.isPlaying(A) and Happening.isPlaying(B), "Ana ya no tiene escena; Beto sí")
-- Beto la ve entera
advance(14)
local stopB = messages(B, "Stop")[1]
check(stopB and stopB.Skipped == false, "Beto la ve hasta el final")
check(WorldMemoryService.get(B, "Cielo.Crater.Camino") == "Humeante", "con sus tres cráteres")
local chispaGone = false
for _, entry in actorLog do
	if entry.Op == "Despawn" and entry.Key == "Chispa" then
		chispaGone = true
	end
end
check(chispaGone, "Chispa se va (desaparece) al final de su carrera")
local moved = false
for _, entry in actorLog do
	if entry.Op == "Move" and entry.Key == "Chispa" and entry.Run == true then
		moved = true
	end
end
check(moved, "Chispa corre (Move con Run) antes de irse")

-- Escena ligera a la vez que una con cámara; y una segunda con cámara salta la primera
inbox = {}
Happening.play(A, "Grieta_Caen")
task.wait(0.01)
advance(0.6)
Happening.play(A, "Grieta_Recoger")
task.wait(0.01)
advance(0.2)
local plays = messages(A, "Play")
check(#plays == 2 and plays[2].Light == true, "una escena ligera (solo efectos) va a la vez que la de cámara")
check(#messages(A, "Stop") == 0, "y no la para")
advance(3.6)
check(#messages(A, "Stop") == 1, "la ligera acaba sola a los 3 s (más el margen de aviso)")
Happening.play(A, "Demo_Catalogo")
task.wait(0.01)
advance(0.1)
local stops = messages(A, "Stop")
check(#stops == 2 and stops[2].Skipped == true, "otra escena con cámara salta la anterior (sus consecuencias quedan)")

-- Demo: espera «acércate» y portal
advance(1)
local demoPlay = messages(A, "Play")[3]
check(demoPlay ~= nil, "empieza el muestrario")
advance(11)
check(#messages(A, "Pause") >= 1, "el muestrario se para hasta que te acercas al portal")
local demoDef = HappeningIndex.get("Demo_Catalogo")
local portalIndex = nil
for i, fx in demoDef.Tracks.Fx do
	if fx.Play == "Portal" then
		portalIndex = i
	end
end
-- Lejos del portal: no te lleva
Happening.onClient(A, "Portal", demoPlay.Run, portalIndex)
check(#teleports == 0, "atravesar el portal desde lejos no vale (lo comprueba el servidor)")
-- Junto al portal (el ancla Yo está en 0,3,0; el portal en 0,0,-24)
roots[A] = { Position = Vector3.new(0, 4, -23), CFrame = CFrame.new(0, 4, -23) }
Happening.onClient(A, "Portal", demoPlay.Run, portalIndex)
check(#teleports == 1 and (teleports[1].Target - Vector3.new(0, 3, 40)).Magnitude < 1e-3, "junto al portal: te lleva al otro lado (destino del portal)")
Happening.onClient(A, "Portal", demoPlay.Run, portalIndex)
check(#teleports == 1, "y no dos veces seguidas")
advance(0.2)
check(#messages(A, "Resume") >= 1, "al acercarte, la escena sigue")
Happening.skip(A)
roots[A] = { Position = Vector3.new(0, 3, 0), CFrame = CFrame.new(0, 3, 0) }

-- Espectadores: alguien cerca ve los efectos de la escena de otro
local all = HappeningIndex.all()
all.Prueba_Publico = {
	Duration = 2,
	Audience = "Nearby",
	AudienceRadius = 100,
	Anchors = { Yo = "Player" },
	Tracks = { Fx = { { At = 0.5, Play = "Explosion", Anchor = "Yo" } }, Camera = { { At = 0, Duration = 2, Orbit = "Yo", Radius = 10, Height = 3, FromAngle = 0, ToAngle = 40 } } },
}
local C = newPlayer("Carla", 3)
roots[C] = { Position = Vector3.new(30, 3, 0), CFrame = CFrame.new(30, 3, 0) }
roots[B] = { Position = Vector3.new(900, 3, 0), CFrame = CFrame.new(900, 3, 0) }
inbox = {}
Happening.play(A, "Prueba_Publico")
task.wait(0.01)
advance(0.1)
local spectatorPlay = messages(C, "Play")[1]
check(spectatorPlay and spectatorPlay.Spectator == true, "Carla, que está cerca, ve los efectos (como espectadora)")
check(messages(B, "Play")[1] == nil, "Beto, lejos, no")
advance(3)
check(messages(C, "Stop")[1] ~= nil and #messages(A, "Stop") == 1, "acaba para los dos")
all.Prueba_Publico = nil

-- Sin pantalla (servidor sin remotos o pruebas de la historia): las consecuencias, al momento
remoteOn = false
local D = newPlayer("Dani", 4)
local before = #actorLog
local quick = Happening.play(D, "Grieta_Caen")
check(quick <= 0.2, "sin pantalla, la escena «dura» un instante")
check(WorldMemoryService.get(D, "Cielo.Crater.Parque") == "Humeante" and WorldMemoryService.get(D, "Cielo.Crater.Camino") == "Humeante", "…y deja sus consecuencias")
check(#actorLog == before, "…sin crear actores que nadie vería")
remoteOn = true

-- El jugador se va a mitad: su escena se acaba sola
inbox = {}
Happening.play(B, "Grieta_Caen")
task.wait(0.01)
advance(0.8)
B.Parent = nil
advance(0.1)
check(not Happening.isPlaying(B), "si se va a mitad, su escena termina (y no se queda colgada)")

---------------------------------------------------------------------
print("5. Criaturas y emociones")
---------------------------------------------------------------------
for id, c in StoryCreatures.List do
	local problems = StoryCreatures.check(id, c)
	for _, p in problems do
		print("     " .. p)
	end
	check(#problems == 0, "criatura " .. id .. " bien hecha")
end
check(StoryCreatures.List.SombraGigante.Scale > 2 and StoryCreatures.List.Duende.Scale < 0.5, "hay rigs agrandados y encogidos")
for _, name in { "Fear", "Angry", "Surprise", "Joy", "Sad", "Hurt" } do
	check(ActorMoods.valid(name), "emoción " .. name)
end
check(ActorMoods.name("Miedo") == "Fear" and ActorMoods.name("Herido") == "Hurt", "alias en español")
check(ActorMoods.walkSpeed(10, "Fear") > 10 and ActorMoods.walkSpeed(10, "Hurt") < 6, "con miedo corre más; herido, se arrastra")
check(ActorMoods.walkSpeed(10, "Fear", true) > ActorMoods.walkSpeed(10, "Fear"), "y corriendo, más")
check(ActorMoods.tremble("Fear", 1.3, 2) ~= 0 and ActorMoods.tremble("Joy", 1.3, 2) == 0, "el miedo tiembla, la alegría no")
local poses = {}
local Emotion = L.load("src/shared/LifeStory/Emotion")
for _, m in ActorMoods.List do
	if m.Pose then
		poses[m.Pose] = true
		check(Emotion.Poses[m.Pose] or ActorMoods.ExtraPoses[m.Pose], "la postura " .. m.Pose .. " la entiende ActorLife")
	end
end

L.finish("test-scenes")
