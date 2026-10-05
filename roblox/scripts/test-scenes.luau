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
--   6. CINEMATIC_SCENE (auditoría §6.1): planos con nombre (General, Medio, PrimerPlano, PPP, Hombro,
--      DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt), anclas compuestas, Lock, luces.
--   7. Diálogo con tiempos (pausas, Beat, Alt, Shot por frase), variantes y condiciones (resolve/expand,
--      lo mismo en servidor y cliente), y la validación de todo lo nuevo.
--   8. El director con lo nuevo: entradas y salidas andando, miradas a quien habla (Look = "Speaker" y
--      miradas propias), variantes por relación y por marcas, Late e Items, saltar con OnSkip, morir,
--      Until (aviso, Match, tope), ambiente/luz/intensidad que llegan al cliente, escenas viejas igual.

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
		table.insert(actorLog, { Op = "Spawn", Player = player, Key = key, Spec = spec, CF = cf, Model = m })
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
	move = function(model, to, run, onArrive)
		table.insert(actorLog, { Op = "Move", Key = model.Name, To = to, Run = run })
		model.Pivot = CFrame.new(to)
		model:SetAttribute("Arrived", true)
		if onArrive then
			onArrive() -- (como StageActors.move: avisa al llegar)
		end
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
	later = function(_, fn)
		fn() -- (sin esperar: la prueba no se queda colgada 25 s)
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

local V = Vector3.new
local function near(a, b, eps)
	return type(a) == "number" and type(b) == "number" and math.abs(a - b) < (eps or 1e-6)
end

local function texts(def)
	local list = {}
	for _, line in def.Tracks.Dialogue or {} do
		table.insert(list, line.T)
	end
	return table.concat(list, " | ")
end
local EventCatalog = L.load("src/shared/LifeStory/EventCatalog")
local fullCtx = table.clone(ctx)
fullCtx.Events = EventCatalog.Names
fullCtx.Poses = L.load("src/shared/LifeStory/Emotion").Poses

---------------------------------------------------------------------
print("6. Planos con nombre, anclas compuestas y luces de cine")
---------------------------------------------------------------------
do
-- Lucía en el origen mirando a −Z (hacia ti, que estás en 0,0,−10); Mateo a su lado; una mesa
local stage = {
	Player = CFrame.lookAt(V(0, 0, -10), V(0, 0, 0)),
	["Actor:Lucia"] = CFrame.new(0, 0, 0),
	["Actor:Mateo"] = CFrame.new(4, 0, 0),
	Mesa = CFrame.new(10, 0, 10),
}
local function stageResolve(name)
	return stage[name]
end
local comp = CameraShots.composite(stageResolve)
local function shotAt(spec, u, refs)
	local shot = CameraShots.preset(spec, refs)
	return shot, shot and CameraShots.base(shot, u or 0, comp)
end
local function looksAt(cf, target)
	return cf ~= nil and cf.LookVector:Dot((target - cf.Position).Unit) > 0.99
end

local kind, args = CameraShots.parsePreset("Hombro:Lucia>Yo")
check(kind == "Hombro" and args[1] == "Lucia" and args[2] == "Yo", "«Hombro:Lucia>Yo» se lee: de Lucía hacia ti")
kind, args = CameraShots.parsePreset("DosPlanos:Lucia, Mateo")
check(kind == "DosPlanos" and args[1] == "Lucia" and args[2] == "Mateo", "«DosPlanos:Lucia, Mateo» se lee (con espacios)")
kind, args = CameraShots.parsePreset("General")
check(kind == "General" and #args == 0, "«General» sin nadie")

local everyOk = true
for name, arity in CameraShots.Presets do
	local names = { "Lucia", "Mateo" }
	local spec = name
	if arity[1] == 1 then
		spec = name .. ":Lucia"
	elseif arity[1] == 2 then
		spec = name .. ":" .. names[1] .. (if name == "DosPlanos" then "," else ">") .. names[2]
	end
	local shot, cf = shotAt(spec, 0.5)
	if not shot or not CameraShots.kind(shot) or not cf then
		everyOk = false
		print("     no sale el plano " .. spec)
	end
end
check(everyOk, "los 13 planos con nombre se traducen a planos que la cámara ya sabe hacer")
local missing, why = CameraShots.preset("Picado:Lucia")
check(missing == nil and why and why:find("desconocido", 1, true), "un plano que no existe no se inventa")
missing, why = CameraShots.preset("Hombro:Lucia")
check(missing == nil and why and why:find("pide 2", 1, true), "al plano de hombro le faltan personajes: se dice")

local pp, ppCf = shotAt("PrimerPlano:Lucia", 0)
check(pp.From[1] == "Actor:Lucia" and pp.Lock == true, "primer plano: anclado a Lucía y clavado (Lock)")
check(ppCf.Position.Z < -3 and looksAt(ppCf, V(0, 1.5, 0)), "primer plano: delante de su cara y mirándola")
local _, pppCf = shotAt("PPP:Lucia", 0)
local _, medioCf = shotAt("Medio:Lucia", 0)
local _, generalCf = shotAt("General:Lucia", 0)
local function dist(cf)
	return (cf.Position - V(0, 1.5, 0)).Magnitude
end
check(dist(pppCf) < dist(ppCf) and dist(ppCf) < dist(medioCf) and dist(medioCf) < dist(generalCf), "PPP < primer plano < medio < general (cada vez más lejos)")
local _, hombroCf = shotAt("Hombro:Lucia>Yo", 0)
check(hombroCf.Position.Z > 2 and looksAt(hombroCf, V(0, 1.4, -10)), "hombro: detrás de Lucía, mirándote a ti por encima de su hombro")
local _, hombro2 = shotAt("Hombro:Yo>Lucia", 0)
check(hombro2.Position.Z < -11 and looksAt(hombro2, V(0, 1.4, 0)), "contraplano: detrás de ti mirando a Lucía")
local _, dosCf = shotAt("DosPlanos:Lucia,Mateo", 0)
check(dosCf.Position.Z < -8 and near(dosCf.Position.X, 2, 1e-3), "dos planos: entre los dos y delante (hacia donde miran)")
stage["Actor:Lucia"] = CFrame.lookAt(V(0, 0, 0), V(4, 0, 0))
stage["Actor:Mateo"] = CFrame.lookAt(V(4, 0, 0), V(0, 0, 0))
_, dosCf = shotAt("DosPlanos:Lucia,Mateo", 0)
check(dosCf.Position.Z < -8, "dos planos de dos que se miran: desde tu lado")
stage.Player = CFrame.new(0, 0, 12)
_, dosCf = shotAt("DosPlanos:Lucia,Mateo", 0)
check(dosCf.Position.Z > 8, "…y si te mueves al otro lado, desde el otro lado (nunca cruza el eje al revés)")
stage.Player = CFrame.lookAt(V(0, 0, -10), V(0, 0, 0))
stage["Actor:Lucia"] = CFrame.new(0, 0, 0)
stage["Actor:Mateo"] = CFrame.new(4, 0, 0)
local _, lateralCf = shotAt("Lateral:Lucia", 0.5)
check(near(lateralCf.Position.X, 7, 1e-3) and looksAt(lateralCf, V(0, 1.2, 0)), "lateral: de perfil")
local reaccion = CameraShots.preset("Reaccion:Mateo")
check(reaccion.Cut == "Cut" and reaccion.From[1] == "Actor:Mateo", "reacción: corte seco a la cara de quien escucha")
local seguir, seguirCf = shotAt("Seguir:Lucia", 0)
check(seguir.Follow == "Actor:Lucia" and seguir.Local and not seguir.Lock, "seguir: detrás del actor y sin clavar (va con él)")
check((seguirCf.Position - V(0, 3.5, 10)).Magnitude < 1e-3, "seguir: a su espalda y algo por encima")
local inserto, insertoCf = shotAt("Inserto:Mesa", 1, { Mesa = "Mesa" })
check(inserto.From[1] == "Mesa" and looksAt(insertoCf, V(10, 0.4, 10)), "inserto: plano del objeto (un ancla de la escena)")
local dolly = CameraShots.preset("Dolly:Lucia")
check(dist(CameraShots.base(dolly, 0, comp)) > dist(CameraShots.base(dolly, 1, comp)) + 4, "dolly: la cámara se acerca")
local dollyOut = CameraShots.expand({ At = 0, Duration = 3, Shot = "Dolly:Lucia", Reverse = true })
check(dist(CameraShots.base(dollyOut, 0, comp)) < dist(CameraShots.base(dollyOut, 1, comp)), "dolly con Reverse: se aleja")
local pan = CameraShots.preset("Pan:Lucia>Mateo")
local pan0, pan1 = CameraShots.base(pan, 0, comp), CameraShots.base(pan, 1, comp)
check((pan0.Position - pan1.Position).Magnitude < 1e-3, "pan: la cámara no se mueve…")
check(looksAt(pan0, V(0, 1.4, 0)) and looksAt(pan1, V(4, 1.4, 0)), "…y gira de Lucía a Mateo")
local tilt = CameraShots.preset("Tilt:Lucia")
check(CameraShots.base(tilt, 0, comp).LookVector.Y < CameraShots.base(tilt, 1, comp).LookVector.Y, "tilt: sube de los pies a la cara")
check(CameraShots.preset("General").From[1] == "Player" and CameraShots.preset("General", { ["*"] = "Mesa" }).From[1] == "Mesa", "general: de la escena (Center) o de ti")
local expanded = CameraShots.expand({ At = 2, Duration = 3, Shot = "Medio:Lucia", Cut = "Dip", Fov = 40 })
check(expanded.At == 2 and expanded.Duration == 3 and expanded.Cut == "Dip" and expanded.Fov == 40 and expanded.Lock, "lo que dice la escena manda sobre el plano (At, Duration, Cut, Fov)")
local plain = { At = 0, Duration = 1, Fixed = { "A" }, Look = { "B" } }
check(CameraShots.expand(plain) == plain, "un plano normal se queda como está")
check(CameraShots.composite(stageResolve)("Mid:Actor:Lucia|Nadie") == stage["Actor:Lucia"], "entre dos, si falta uno: el que está")
-- Lock: el plano recuerda dónde estaba el actor al empezar
local calls = 0
local moving = CFrame.new(0, 0, 0)
local lockedResolve = CameraShots.locked(function(name)
	calls += 1
	return if name == "Actor:Lucia" then moving else nil
end)
local first = lockedResolve("Actor:Lucia")
moving = CFrame.new(5, 0, 0)
check(lockedResolve("Actor:Lucia") == first and calls == 1, "Lock: si el actor se gira o se mueve, el plano no da bandazos")
local notYet = CameraShots.locked(function()
	return CFrame.new()
end, function()
	return false
end)
notYet("Actor:X")
check(notYet("Actor:X") ~= nil, "Lock: lo que aún no ha aparecido no se clava (se vuelve a buscar)")
-- Luces de cine
local DayGrade = L.load("src/shared/DayGrade")
local gradeKeys = DayGrade.Keys[1].Key
local lightsOk = true
for name, mood in CameraShots.Lights do
	for key in mood do
		if gradeKeys[key] == nil then
			lightsOk = false
			print("     luz " .. name .. ": " .. key .. " no es un valor de DayGrade")
		end
	end
end
check(lightsOk, "las luces de cine usan valores que DayLight entiende")
check(CameraShots.light("InteriorCalido") and CameraShots.light("Atardecer") and CameraShots.light("Noche"), "luces: interior cálido, atardecer y noche")
check(CameraShots.light("Discoteca") == nil, "una luz que no existe no se pone")

end

---------------------------------------------------------------------
print("7. Diálogo con tiempos, variantes, condiciones y validación")
---------------------------------------------------------------------
do
check(Sequencer.sideOf("Dialogue") == "Both" and Sequencer.sideOf("Ambience") == "Client" and Sequencer.sideOf("Light") == "Client", "pistas nuevas: Dialogue (los dos), Ambience y Light (pantalla)")
local talk = {
	Anchors = { Yo = "Player", Sala = "Place:GarajeCosme" },
	Tracks = {
		Actors = {
			{ At = 0, Spawn = { Key = "Lucia", Npc = "Lucia", Anchor = "Sala" } },
			{ At = 0, Spawn = { Key = "Mateo", Npc = "Mateo", Anchor = "Sala", Offset = V(3, 0, 0) } },
		},
		Dialogue = {
			{ S = "Lucia", T = "Hola." },
			{ S = "Mateo", T = "Hola…", Pause = 1 },
			{ S = "Lucia", T = "¿Qué te pasa?", Beat = "Mirar", Shot = "PrimerPlano:Lucia" },
			{ S = "Mateo", T = "Nada.", Beat = "Suelo", To = "Lucia" },
			{ S = "Lucia", T = "Vale, si tú lo dices.", If = { Input = "Insistir" } },
			{ S = "Lucia", T = "Como quieras.", IfNot = { Input = "Insistir" }, Alt = true },
			{ At = 30, S = "Narrador", T = "Más tarde." },
		},
	},
}
local ex = Sequencer.expand(talk)
local dl = ex.Tracks.Dialogue
local GAP = Sequencer.LINE_GAP
check(#dl == 7 and dl[1].At == 0 and near(dl[1].Duration, Sequencer.lineSeconds("Hola.")), "sin At, la primera frase empieza al principio y dura lo que se tarda en leer")
check(near(dl[2].At, dl[1].At + dl[1].Duration + GAP + 1), "Pause = 1: un segundo de silencio antes de la frase")
check(dl[2].After >= 0.4 - 1e-9, "los puntos suspensivos se quedan en el aire (pausa después)")
check(near(dl[3].At, dl[2].At + dl[2].Duration + dl[2].After + GAP + Sequencer.BEAT_PAUSE), "Beat: una pausa para el gesto antes de hablar")
check(near(dl[6].At, dl[5].At), "Alt: la alternativa sale a la vez (If/IfNot con Input)")
check(dl[7].At == 30, "una frase con At sale cuando dice")
check(Sequencer.lineSeconds(string.rep("a", 400)) <= 9 and Sequencer.lineSeconds("") >= 1.8, "una frase dura entre 1,8 y 9 s")
local beatLooks, beatFloor = nil, nil
for _, ev in ex.Tracks.Actors do
	if ev.Look and ev.Look.Beat and ev.Look.Key == "Lucia" then
		beatLooks = ev
	elseif ev.Look and ev.Look.Beat and ev.Look.Key == "Mateo" then
		beatFloor = ev
	end
end
check(beatLooks and beatLooks.Look.At == "Player" and near(beatLooks.At, dl[3].At - Sequencer.BEAT_PAUSE), "Beat «Mirar»: en la pausa, Lucía te mira")
check(beatFloor and beatFloor.Look.At == "Suelo", "Beat «Suelo»: Mateo baja la mirada (vergüenza)")
local lineShot = ex.Tracks.Camera and ex.Tracks.Camera[1]
check(lineShot and lineShot.Preset == "PrimerPlano" and lineShot.From[1] == "Actor:Lucia" and near(lineShot.At, dl[3].At - Sequencer.BEAT_PAUSE), "Shot en una frase: primer plano de Lucía desde la pausa")
check(Sequencer.isLight(talk) and not Sequencer.isLight(ex), "con planos por frase la escena ya es de cámara (no ligera)")
check(talk.Tracks.Dialogue[1].At == nil and talk.Tracks.Camera == nil, "expandir no toca los datos de la escena")
local talkTl = Sequencer.compile("Charla", talk)
check(talkTl.Duration >= 30 + Sequencer.lineSeconds("Más tarde.") - 1e-6 and talkTl.Def ~= nil, "la duración cubre la última frase")
-- Las escenas viejas, igual que antes
local caen = HappeningIndex.get("Grieta_Caen")
local caenEx = Sequencer.expand(caen)
check(caenEx.Tracks.Camera[1] == caen.Tracks.Camera[1] and #caenEx.Tracks.Lines == #caen.Tracks.Lines, "las escenas viejas se quedan como estaban")
local oldCount = 0
for _, list in caen.Tracks do
	oldCount += #list
end
check(#Sequencer.compile("Grieta_Caen", caen).Events == oldCount, "…con los mismos sucesos")

-- Condiciones y variantes
check(Sequencer.conditionsOf({ Input = "X" }) == nil, "If con solo Input: no hay condiciones que mirar en el servidor")
local onlyCond = Sequencer.conditionsOf({ Input = "X", Flags = { "A" } })
check(onlyCond and onlyCond.Input == nil and onlyCond.Flags[1] == "A", "If con Input y Flags: el servidor mira las Flags y la escena el Input")
local varied = {
	Anchors = { Sala = "Place:GarajeCosme" },
	Tracks = {
		Actors = { { At = 0, Spawn = { Key = "Lucia", Npc = "Lucia", Anchor = "Sala" } } },
		Dialogue = {
			{ S = "Lucia", T = "Base 1." },
			{ S = "Lucia", T = "Has aprobado.", If = { Flags = { "Aprobado" } } },
			{ S = "Lucia", T = "No pasa nada.", IfNot = { Flags = { "Aprobado" } }, Alt = true },
			{ S = "Lucia", T = "Llegas tarde.", If = { Late = true } },
		},
		Fx = {
			{ At = 0, Play = "Poof", Anchor = "Sala", If = { Memories = { "PrimerAmigo" } } },
			{ At = 1, Play = "Poof", Anchor = "Sala" },
		},
	},
	Variants = {
		{ Name = "Amigos", If = { Rel = { Lucia = 20 } }, Tracks = { Dialogue = { { S = "Lucia", T = "¡Mi mejor amigo!" } } } },
		{ Name = "Enfadados", If = { RelBelow = { Lucia = -10 } }, Tracks = { Dialogue = { { S = "Lucia", T = "Ah. Eres tú." } } } },
	},
}
-- Un juez de mentira (en el juego: HappeningService.checker con la partida)
local function judge(facts)
	return function(req)
		for _, f in req.Flags or {} do
			if not (facts.Flags or {})[f] then
				return false
			end
		end
		for _, f in req.Memories or {} do
			if not (facts.Memories or {})[f] then
				return false
			end
		end
		for npc, min in req.Rel or {} do
			if ((facts.Rel or {})[npc] or 0) < min then
				return false
			end
		end
		for npc, max in req.RelBelow or {} do
			if ((facts.Rel or {})[npc] or 0) >= max then
				return false
			end
		end
		if req.Late ~= nil and (facts.Late == true) ~= req.Late then
			return false
		end
		return true
	end
end
local choice = Sequencer.resolve(varied, judge({}))
check(choice.Variant == nil, "sin relación especial: la escena de siempre")
check(choice.Gates["Dialogue#2"] == false and choice.Gates["Dialogue#3"] == true and choice.Gates["Dialogue#4"] == false, "las frases con condiciones, decididas en el servidor")
check(choice.Gates["Fx#1"] == false and choice.Gates["Fx#2"] == nil, "también los efectos (y lo que no tiene condición no se apunta)")
local base = Sequencer.expand(varied, choice)
check(texts(base) == "Base 1. | No pasa nada.", "sin aprobar: «No pasa nada.»")
check(near(base.Tracks.Dialogue[2].At, base.Tracks.Dialogue[1].At + base.Tracks.Dialogue[1].Duration + GAP), "la alternativa ocupa el sitio de la que no sale (sin huecos ni encima de otra)")
check(#base.Tracks.Fx == 1 and base.Tracks.Fx[1].At == 1, "el efecto con condición no sale")
local approved = Sequencer.expand(varied, Sequencer.resolve(varied, judge({ Flags = { Aprobado = true }, Late = true })))
check(texts(approved) == "Base 1. | Has aprobado. | Llegas tarde.", "aprobado y tarde: «Has aprobado.» y «Llegas tarde.»")
local friendsChoice = Sequencer.resolve(varied, judge({ Rel = { Lucia = 30 } }))
local friends = Sequencer.expand(varied, friendsChoice)
check(friendsChoice.Variant == 1 and friends.Variant == "Amigos" and texts(friends) == "¡Mi mejor amigo!", "buena relación con Lucía: la variante «Amigos»")
check(#friends.Tracks.Fx == 1 and friends.Tracks.Actors[1].Spawn.Key == "Lucia", "la variante solo sustituye sus pistas")
local angry = Sequencer.expand(varied, Sequencer.resolve(varied, judge({ Rel = { Lucia = -50 } })))
check(texts(angry) == "Ah. Eres tú.", "mala relación: la variante «Enfadados»")
-- Servidor y cliente expanden lo mismo con lo que manda el servidor
local serverTl = Sequencer.compile("Var", varied, friendsChoice)
local clientTl = Sequencer.compile("Var", varied, { Variant = friendsChoice.Variant, Gates = friendsChoice.Gates })
local same = #serverTl.Events == #clientTl.Events
for i, e in serverTl.Events do
	local o = clientTl.Events[i]
	if not o or o.Track ~= e.Track or o.At ~= e.At then
		same = false
	end
end
check(same and near(serverTl.Duration, clientTl.Duration), "servidor y cliente ven la misma escena (misma variante y condiciones)")
check(Sequencer.passes({ If = { Input = "I", Flags = { "A" } } }, { I = true }), "If con Input y Flags: en la escena solo cuenta el Input")

-- Validación de lo nuevo
local good = {
	Anchors = { Yo = "Player", Sala = "Place:GarajeCosme", Puerta = "Place:FuenteParque" },
	Center = "Sala",
	Intensity = "Intima",
	Until = { Event = "TalkDone", Match = { Npc = "Lucia" }, Timeout = 20 },
	OnSkip = { Inputs = { Insistir = false }, World = { ["Prueba.Saltada"] = true } },
	Tracks = {
		Camera = { { At = 0, Duration = 2, Shot = "General" }, { At = 2, Duration = 2, Shot = "Hombro:Yo>Lucia", Cut = "Cut" } },
		Ambience = { { At = 0, Kind = "Casa", Fade = 2 }, { At = 9, Kind = false } },
		Light = { { At = 0, Preset = "InteriorCalido" }, { At = 9, Preset = false } },
		Music = { { At = 0, Intensity = "Descubrimiento" }, { At = 5, Play = "TemaValmar" } },
		Actors = {
			{ At = 0, Enter = { Key = "Lucia", Npc = "Lucia", From = "Puerta", Anchor = "Sala" } },
			{ At = 0, Spawn = { Key = "Mateo", Npc = "Mateo", Anchor = "Sala", Offset = V(2, 0, 0) } },
			{ At = 1, Look = { Key = "Mateo", At = "Suelo" } },
			{ At = 4, Look = { Key = "Mateo", At = "Speaker" } },
			{ At = 8, Exit = { Key = "Lucia", To = { "Puerta", V(0, 0, 2) } } },
		},
		Dialogue = {
			{ S = "Lucia", T = "Hola.", To = "Mateo", A = "Happy", Pause = { Before = 0.5, After = 0.3 } },
			{ S = "Mateo", T = "…Hola.", Beat = "Suelo", Shot = "Reaccion:Mateo", If = { Rel = { Mateo = 5 } } },
			{ S = "Yo", T = "¡Hola!", IfNot = { Rel = { Mateo = 5 } }, Alt = true },
		},
	},
	Variants = { { Name = "Tarde", If = { Late = true }, Tracks = { Dialogue = { { S = "Lucia", T = "Llegas tarde." } } } } },
}
local goodErrors = Sequencer.validate("Buena", good, fullCtx)
for _, e in goodErrors do
	print("     " .. e)
end
check(#goodErrors == 0, "una CINEMATIC_SCENE completa y bien escrita no da errores")
local broken = {
	Look = "Todos",
	Intensity = "Epica",
	Anchors = { Yo = "Player", Sala = "Place:GarajeCosme" },
	Until = { Event = "NoExiste" },
	OnSkip = { Saltar = true },
	Tracks = {
		Camera = { { At = 0, Duration = 1, Shot = "Picado:Lucia" }, { At = 1, Duration = 1, Shot = "PrimerPlano:Fantasma" } },
		Ambience = { { At = 0, Kind = "Discoteca" } },
		Light = { { At = 0, Preset = "Disco" } },
		Music = { { At = 0, Intensity = "Epica" } },
		Actors = {
			{ At = 0, Enter = { Key = "Lucia", Npc = "Lucia", Anchor = "Sala" } },
			{ At = 1, Exit = { Key = "Nadie" } },
			{ At = 1, Look = { Key = "Lucia", At = "Ninguno" } },
		},
		Dialogue = {
			{ S = "Lucia" },
			{ S = "Desconocido", T = "¿Hola?" },
			{ S = "Lucia", T = "Bailo.", Beat = "Bailar", Pause = "mucho" },
			{ S = "Lucia", T = "Hola.", If = { Flagz = { "A" } } },
			{ S = "Lucia", T = "Hola.", If = { Rel = { Fantasma = 3 } } },
		},
	},
	Variants = {
		{ Name = "Rota", If = { Inventada = 1 }, Tracks = { Dialogue = { { S = "Lucia", T = "x", Shot = "Medio:Otro" } } } },
	},
}
local brokenErrors = table.concat(Sequencer.validate("Rota", broken, fullCtx), "\n")
local function has(text)
	return brokenErrors:find(text, 1, true) ~= nil
end
check(has("plano desconocido 'Picado:Lucia'"), "detecta un plano con nombre que no existe")
check(has("'Fantasma' no es un actor de la escena"), "detecta un plano de alguien que no está en la escena")
check(has("frase vacía (T)"), "detecta una frase vacía")
check(has("quién habla 'Desconocido'"), "detecta a alguien que habla sin estar")
check(has("Beat desconocido 'Bailar'") and has("Pause = segundos"), "detecta un Beat y una pausa mal escritos")
check(has("ambiente desconocido 'Discoteca'") and has("luz desconocida 'Disco'") and has("intensidad desconocida 'Epica'"), "detecta ambiente, luz e intensidad que no existen")
check(has("condición desconocida 'Flagz'"), "detecta una condición mal escrita")
check(has("Rel de 'Fantasma'"), "detecta una relación con alguien que no está en el reparto")
check(has("Enter sin From"), "detecta una entrada sin puerta (From)")
check(has("Exit de 'Nadie' antes de que aparezca"), "detecta una salida de quien no ha entrado")
check(has("'Ninguno' no es un actor de la escena ni un ancla"), "detecta una mirada a nadie")
check(has("aviso desconocido 'NoExiste'"), "detecta un Until con un aviso que nadie manda")
check(has("OnSkip: campo desconocido 'Saltar'"), "detecta un OnSkip mal escrito")
check(has('Look de la escena es "Speaker" o false'), "detecta un Look de escena raro")
check(has("(variante Rota)") and has("'Otro' no es un actor"), "los errores de una variante dicen de qué variante son")
check(has("variante Rota.If: condición desconocida 'Inventada'"), "detecta la condición mal escrita de una variante")

end

---------------------------------------------------------------------
print("8. Director: entradas, miradas, variantes, saltar, morir y Until")
---------------------------------------------------------------------
do
local finishedLog = {}
Happening.onFinished(function(player, id, skipped)
	table.insert(finishedLog, { Player = player, Id = id, Skipped = skipped })
end)
all.Prueba_Cine = {
	Skippable = true,
	Center = "Sala",
	Intensity = "Intima",
	Anchors = { Yo = "Player", Sala = "Place:GarajeCosme", Puerta = "Place:FuenteParque" },
	OnSkip = { World = { ["Prueba.Saltada"] = true } },
	Tracks = {
		Ambience = { { At = 0, Kind = "Casa" } },
		Light = { { At = 0, Preset = "InteriorCalido" } },
		Camera = { { At = 0, Duration = 1, Shot = "General" } },
		Actors = {
			{ At = 0, Use = { Key = "Cosme", Npc = "Cosme" } },
			{ At = 0, Spawn = { Key = "Mateo", Npc = "Mateo", Anchor = "Sala", Offset = V(-2, 0, 0) } },
			{ At = 0.2, Enter = { Key = "Lucia", Npc = "Lucia", From = "Puerta", Anchor = "Sala", Offset = V(2, 0, 0) } },
			{ At = 3.6, Look = { Key = "Mateo", At = "Suelo" } },
			{ At = 9.5, Look = { Key = "Mateo", At = "Speaker" } },
			{ At = 14.5, Exit = { Key = "Lucia", To = "Puerta" } },
		},
		Dialogue = {
			{ At = 1, S = "Lucia", T = "Hola, soy Lucía.", Shot = "PrimerPlano:Lucia" },
			{ S = "Cosme", T = "Encantado.", To = "Lucia" },
			{ S = "Mateo", T = "Yo… no sé si esto es buena idea…", Beat = "Suelo" },
			{ S = "Yo", T = "Tranquilo." },
			{ S = "Lucia", T = "Te ha salido genial.", If = { Flags = { "Aprobado" } } },
			{ S = "Lucia", T = "La próxima vez saldrá mejor.", IfNot = { Flags = { "Aprobado" } }, Alt = true },
		},
		World = { { At = 15, Set = { ["Prueba.Vista"] = true } } },
	},
	Variants = {
		{ Name = "Amigos", If = { Rel = { Lucia = 20 } }, Tracks = { Dialogue = { { At = 1, S = "Lucia", T = "¡Mi mejor amigo!" } } } },
	},
}
local cineErrors = Sequencer.validate("Prueba_Cine", all.Prueba_Cine, fullCtx)
for _, e in cineErrors do
	print("     " .. e)
end
check(#cineErrors == 0, "la escena de prueba está bien escrita")

local function lastRun(player)
	local best = nil
	for _, r in Happening._runs(player) do
		if not best or r.Serial > best.Serial then
			best = r
		end
	end
	return best
end
-- Avanza hasta el segundo t de la escena (sin esperas por medio)
local function advanceScene(r, t)
	local target = r.StartAt + r.Paused + t
	if target > clock then
		advance(target - clock + 0.02)
	end
end
local function lookOf(model)
	return model and model:GetAttribute("LookAt")
end
local function spawnedModel(player, key)
	local found = nil
	for _, entry in actorLog do
		if entry.Op == "Spawn" and entry.Player == player and entry.Key == key then
			found = entry
		end
	end
	return found
end

local E = newPlayer("Elena", 5)
profiles[E].Story.Flags = { Aprobado = true }
inbox = {}
Happening.play(E, "Prueba_Cine")
task.wait(0.01)
advance(0.05)
local cinePlay = messages(E, "Play")[1]
local cineRun = lastRun(E)
check(cinePlay ~= nil and cinePlay.Light == false, "la escena empieza y es de cámara")
check(cinePlay and cinePlay.Variant == nil and cinePlay.Gates["Dialogue#5"] == true and cinePlay.Gates["Dialogue#6"] == false, "aprobado: el servidor manda qué frase sale")
check(cinePlay and cinePlay.Names.Lucia ~= nil and cinePlay.Names.Mateo ~= nil and cinePlay.Names.Yo == "Elena", "nombres de quien habla en el diálogo")
local clientView = Sequencer.compile("Prueba_Cine", all.Prueba_Cine, { Variant = cinePlay.Variant, Gates = cinePlay.Gates })
check(#clientView.Events == #cineRun.Timeline.Events and texts(clientView.Def) == texts(cineRun.Def), "su pantalla expande la misma escena que el servidor")
check(texts(cineRun.Def):find("Te ha salido genial.", 1, true) and not texts(cineRun.Def):find("La próxima vez", 1, true), "…con la frase de aprobado")
local cueTracks = cineRun.Def.Tracks
check(cueTracks.Ambience[1].Kind == "Casa" and cueTracks.Light[1].Preset == "InteriorCalido" and cineRun.Def.Intensity == "Intima", "ambiente, luz e intensidad viajan con la escena (los pone su pantalla)")
local onlyClientCues = true
for _, e in Sequencer.skipPlan(cineRun.Timeline, -1, {}) do
	if e.Track == "Ambience" or e.Track == "Light" or e.Track == "Dialogue" then
		onlyClientCues = false
	end
end
check(onlyClientCues, "ambiente, luz y frases no dejan consecuencias en el servidor (nada que aplicar al saltar)")
local lines = cineRun.Def.Tracks.Dialogue
-- Entra andando
advanceScene(cineRun, 0.3)
local lucia = spawnedModel(E, "Lucia")
check(lucia and (lucia.CF.Position - V(300, 0, 0)).Magnitude < 1e-3, "Lucía aparece en la puerta (From)…")
local walked = false
for _, entry in actorLog do
	if entry.Op == "Move" and entry.Key == "Lucia" and (entry.To - V(2, 0, 0)).Magnitude < 1e-3 then
		walked = true
	end
end
check(walked, "…y anda hasta su marca (no aparece de golpe)")
local mateo = spawnedModel(E, "Mateo").Model
local luciaModel = lucia.Model
local cosme = sceneActors[E].Cosme
-- Primera frase: todos miran a Lucía; ella te mira a ti
advanceScene(cineRun, lines[1].At + 0.05)
check(lookOf(cosme) == "Key:Lucia" and lookOf(mateo) == "Key:Lucia", "habla Lucía: Cosme y Mateo la miran (Look = \"Speaker\")")
check(lookOf(luciaModel) == "Player", "y ella te mira a ti (nadie le habló antes)")
-- Cosme le contesta a Lucía (To)
advanceScene(cineRun, lines[2].At + 0.05)
check(lookOf(cosme) == "Key:Lucia", "Cosme habla mirando a Lucía (To), no a ti")
check(lookOf(luciaModel) == "Key:Cosme" and lookOf(mateo) == "Key:Cosme", "Lucía y Mateo miran a Cosme")
-- Mateo baja la mirada (su propia mirada manda)
advanceScene(cineRun, 3.7)
local floorLook = lookOf(mateo)
check(typeof(floorLook) == "Vector3" and floorLook.Y < mateo:GetPivot().Position.Y, "Mateo mira al suelo (vergüenza)")
advanceScene(cineRun, lines[3].At + 0.05)
check(lookOf(mateo) == floorLook, "y sigue mirando al suelo aunque hable (su mirada propia manda)")
check(lookOf(luciaModel) == "Key:Mateo" and lookOf(cosme) == "Key:Mateo", "los demás miran a Mateo cuando habla")
-- Hablas tú
advanceScene(cineRun, lines[4].At + 0.05)
check(lookOf(luciaModel) == "Player" and lookOf(cosme) == "Player", "hablas tú: te miran a ti")
check(lookOf(mateo) == floorLook, "(Mateo aún no levanta la vista)")
advanceScene(cineRun, 9.55)
check(lookOf(mateo) == "Player", "Look = Speaker: Mateo vuelve a mirar a quien habla")
advanceScene(cineRun, lines[5].At + 0.05)
check(lookOf(luciaModel) == "Player" and lookOf(mateo) == "Key:Lucia", "Lucía te contesta a ti; Mateo la mira")
-- Se va andando
advanceScene(cineRun, 14.6)
local walkedOut, gone = false, false
for _, entry in actorLog do
	if entry.Op == "Move" and entry.Key == "Lucia" and (entry.To - V(300, 0, 0)).Magnitude < 1e-3 then
		walkedOut = true
	elseif entry.Op == "Despawn" and entry.Key == "Lucia" and walkedOut then
		gone = true
	end
end
check(walkedOut and gone, "Lucía se va andando hasta la puerta y desaparece al llegar")
advanceScene(cineRun, 15.2)
check(messages(E, "Stop")[1] and messages(E, "Stop")[1].Skipped == false, "la escena acaba entera")
check(WorldMemoryService.get(E, "Prueba.Vista") == true and WorldMemoryService.get(E, "Prueba.Saltada") == nil, "con su consecuencia (y sin las de saltar)")
check(mateo.Parent == nil and lookOf(cosme) == nil and cosme:GetAttribute("HappeningKey") == nil, "Mateo se va; Cosme vuelve a su misión sin mirada puesta")

-- Variante por relación
local F = newPlayer("Fede", 6)
profiles[F].Story.NpcMemory = { Lucia = { Rel = 30 } }
inbox = {}
Happening.play(F, "Prueba_Cine")
task.wait(0.01)
advance(0.05)
local fPlay = messages(F, "Play")[1]
local fRun = lastRun(F)
check(fPlay and fPlay.Variant == 1 and fRun.Def.Variant == "Amigos", "buena relación con Lucía: el servidor elige la variante «Amigos»")
check(texts(fRun.Def) == "¡Mi mejor amigo!", "y su diálogo es el de la variante")
Happening.skip(F)

-- Saltar: entra ya en su sitio, se va, y OnSkip
local G = newPlayer("Gala", 7)
inbox = {}
Happening.play(G, "Prueba_Cine")
task.wait(0.01)
advance(0.05)
local gRun = lastRun(G)
advanceScene(gRun, 0.1)
Happening.onClient(G, "Skip", gRun.Serial)
local gLucia = spawnedModel(G, "Lucia")
check(gLucia and (gLucia.CF.Position - V(2, 0, 0)).Magnitude < 1e-3, "saltando antes de que entre: Lucía queda directamente en su marca")
check(WorldMemoryService.get(G, "Prueba.Vista") == true and WorldMemoryService.get(G, "Prueba.Saltada") == true, "saltar deja las consecuencias y las de OnSkip")
check(gLucia.Model.Parent == nil, "y nadie se queda en el mapa")
local gFinished = nil
for _, f in finishedLog do
	if f.Player == G then
		gFinished = f
	end
end
check(gFinished and gFinished.Skipped == true, "la historia sabe que se saltó")

-- OnSkip.Inputs: lo que se da por hecho en las esperas que faltaban
all.Prueba_Espera = {
	Anchors = { Yo = "Player" },
	OnSkip = { Inputs = { Cubrirse = true } },
	Tracks = {
		Camera = { { At = 0, Duration = 3, Shot = "General" } },
		Wait = { { At = 1, Input = "Cubrirse", Timeout = 3 } },
		World = {
			{ At = 2, Set = { ["Prueba.Cubierto"] = true }, If = { Input = "Cubrirse" } },
			{ At = 2, Set = { ["Prueba.Herido"] = true }, IfNot = { Input = "Cubrirse" } },
		},
	},
}
local Hh = newPlayer("Hugo", 8)
Happening.play(Hh, "Prueba_Espera")
task.wait(0.01)
advance(0.05)
advanceScene(lastRun(Hh), 0.3)
Happening.skip(Hh)
check(WorldMemoryService.get(Hh, "Prueba.Cubierto") == true and WorldMemoryService.get(Hh, "Prueba.Herido") == nil, "OnSkip.Inputs: saltando, se da por hecho que te cubriste")

-- Morir: la escena se acaba aunque no se pueda saltar
all.Prueba_Fija = {
	Skippable = false,
	Anchors = { Yo = "Player" },
	Tracks = {
		Camera = { { At = 0, Duration = 5, Shot = "Medio:Yo" } },
		Ambience = { { At = 0, Kind = "Hospital" } },
		Light = { { At = 0, Preset = "Noche" } },
		World = { { At = 4, Set = { ["Prueba.Fija"] = true } } },
	},
}
local I = newPlayer("Ines", 9)
inbox = {}
Happening.play(I, "Prueba_Fija")
task.wait(0.01)
advance(1)
check(not Happening.skip(I) and Happening.isPlaying(I), "una escena que no se puede saltar no se salta")
Happening.onDied(I)
local iStop = messages(I, "Stop")[1]
check(iStop and iStop.Skipped == true and not Happening.isPlaying(I), "al morir se acaba ya (su pantalla quita cámara, controles, ambiente y luz)")
check(WorldMemoryService.get(I, "Prueba.Fija") == true, "y sus consecuencias quedan")
local iDone = 0
for _, d in done do
	if d.Player == I then
		iDone += 1
	end
end
check(iDone == 1, "la historia sigue (una vez)")

-- Until: acaba con un aviso de StoryEvents
all.Prueba_Hasta = {
	Duration = 2,
	Anchors = { Yo = "Player" },
	Until = { Event = "TalkDone", Match = { Npc = "Lucia" } },
	Tracks = {
		Camera = { { At = 0, Duration = 2, Shot = "General" } },
		World = { { At = 1.5, Set = { ["Prueba.Hasta"] = true } } },
	},
}
check(Sequencer.maxDuration(Sequencer.compile("Prueba_Hasta", all.Prueba_Hasta)) >= 2 + Sequencer.MAX_WAIT - 1e-6, "con Until, el tope cuenta lo que se puede esperar el aviso")
local J = newPlayer("Juan", 10)
inbox = {}
finishedLog = {}
Happening.play(J, "Prueba_Hasta")
task.wait(0.01)
advance(0.05)
advanceScene(lastRun(J), 0.5)
Happening.onStoryEvent(J, "TalkDone", { Npc = "Otro" })
advance(0.1)
check(Happening.isPlaying(J), "un aviso que no es el suyo (Match) no la acaba")
Happening.onStoryEvent(J, "TalkDone", { Npc = "Lucia" })
advance(0.1)
local jStop = messages(J, "Stop")[1]
check(jStop and jStop.Skipped == false and not Happening.isPlaying(J), "llega el aviso: la escena acaba (sin contar como saltada)")
check(WorldMemoryService.get(J, "Prueba.Hasta") == true, "y lo que faltaba se deja hecho")
check(finishedLog[1] and finishedLog[1].Skipped == false, "la historia lo sabe como terminada")
-- Sin aviso: se queda en el último plano esperando
local K = newPlayer("Karla", 11)
inbox = {}
Happening.play(K, "Prueba_Hasta")
task.wait(0.01)
advance(0.05)
advanceScene(lastRun(K), 2.2)
local kPause = messages(K, "Pause")[1]
check(kPause and kPause.Until == true and near(kPause.At, 2), "acaba el tiempo sin el aviso: se queda en el último plano")
advance(5)
check(Happening.isPlaying(K) and #messages(K, "Stop") == 0, "…esperando el aviso")
Happening.onStoryEvent(K, "TalkDone", { Npc = "Lucia" })
advance(0.1)
check(#messages(K, "Stop") == 1, "y cuando llega, acaba")
-- Con tope
all.Prueba_HastaTope = {
	Duration = 1,
	Anchors = { Yo = "Player" },
	Until = { Event = "TalkDone", Timeout = 1 },
	Tracks = { Camera = { { At = 0, Duration = 1, Shot = "General" } } },
}
local M = newPlayer("Marta", 12)
inbox = {}
Happening.play(M, "Prueba_HastaTope")
task.wait(0.01)
advance(0.05)
advanceScene(lastRun(M), 1.2)
check(Happening.isPlaying(M), "Until con Timeout: espera…")
advance(1.2)
check(not Happening.isPlaying(M) and #messages(M, "Stop") == 1, "…y si no llega el aviso, acaba sola (nunca se queda colgada)")

-- Lines viejas: no cambian miradas salvo que la escena pida Look = "Speaker"
all.Prueba_Lineas = {
	Duration = 2,
	Anchors = { Yo = "Player" },
	Tracks = {
		Camera = { { At = 0, Duration = 2, Shot = "General" } },
		Actors = { { At = 0, Spawn = { Key = "Mateo", Npc = "Mateo", Anchor = "Yo" } }, { At = 0, Spawn = { Key = "Lucia", Npc = "Lucia", Anchor = "Yo" } } },
		Lines = { { At = 0.5, Speaker = "Lucia", Text = "Hola." } },
	},
}
local N = newPlayer("Nora", 13)
Happening.play(N, "Prueba_Lineas")
task.wait(0.01)
advance(0.05)
advanceScene(lastRun(N), 0.7)
check(lookOf(spawnedModel(N, "Mateo").Model) == nil, "escena vieja con Lines: las miradas como siempre")
Happening.skip(N)
all.Prueba_Lineas.Look = "Speaker"
local O = newPlayer("Olga", 14)
Happening.play(O, "Prueba_Lineas")
task.wait(0.01)
advance(0.05)
advanceScene(lastRun(O), 0.7)
check(lookOf(spawnedModel(O, "Mateo").Model) == "Key:Lucia", "con Look = \"Speaker\", también miran a quien habla en Lines")
Happening.skip(O)
-- Look = false: nadie gira la cabeza por el diálogo
local plainTalk = table.clone(all.Prueba_Cine)
plainTalk.Look = false
plainTalk.Variants = nil
all.Prueba_SinMiradas = plainTalk
local P = newPlayer("Pablo", 15)
Happening.play(P, "Prueba_SinMiradas")
task.wait(0.01)
advance(0.05)
local pRun = lastRun(P)
advanceScene(pRun, pRun.Def.Tracks.Dialogue[1].At + 0.05)
check(lookOf(spawnedModel(P, "Mateo").Model) == nil, "Look = false: el diálogo no gira miradas")
Happening.skip(P)

-- Condiciones con la partida de verdad (HappeningService.checker)
local Q = newPlayer("Quique", 16)
profiles[Q].Story.Flags = { TieneBici = true }
profiles[Q].Story.Memories = { PrimerAmigo = true }
profiles[Q].Story.NpcMemory = { Mateo = { Rel = 12 } }
profiles[Q].Items = { MochilaCole = 1 }
local judgeQ = Happening.checker(Q)
check(judgeQ({ Flags = { "TieneBici" } }) and not judgeQ({ Flags = { "NoTiene" } }), "Flags de la partida")
check(judgeQ({ Memories = { "PrimerAmigo" } }) and judgeQ({ Rel = { Mateo = 10 } }) and not judgeQ({ Rel = { Mateo = 20 } }), "recuerdos y relación")
check(judgeQ({ Items = { MochilaCole = 1 } }) and not judgeQ({ Items = { MochilaCole = 2 } }), "Items: lo que llevas en la mochila")
check(judgeQ({ Late = false }) and not judgeQ({ Late = true }), "Late: no llegaste tarde")
check(Happening.checker(Q, { Late = true })({ Late = true }), "Late: la historia dice que llegaste tarde (opts.Late)")
Q:SetAttribute("StoryLate", true)
check(Happening.checker(Q)({ Late = true }), "Late: o el atributo StoryLate")
local nobody = L.player("Nadie", 99)
check(not Happening.checker(nobody)({ Flags = { "X" } }) and Happening.checker(nobody)({ Late = false }), "sin partida cargada: la escena de siempre (sin variantes)")
-- Variante elegida por Late en una escena
all.Prueba_Tarde = {
	Duration = 1,
	Anchors = { Yo = "Player" },
	Tracks = { Dialogue = { { At = 0, S = "Narrador", T = "A tiempo." } } },
	Variants = { { Name = "Tarde", If = { Late = true }, Tracks = { Dialogue = { { At = 0, S = "Narrador", T = "Tarde." } } } } },
}
inbox = {}
Happening.play(Q, "Prueba_Tarde", { Late = true })
task.wait(0.01)
advance(0.05)
check(texts(lastRun(Q).Def) == "Tarde." and messages(Q, "Play")[1].Light == true, "llegaste tarde: la variante «Tarde» (y sin cámara, es ligera)")
Happening.skip(Q)

end

L.finish("test-scenes")
