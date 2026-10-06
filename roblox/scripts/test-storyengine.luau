-- Prueba del motor de la historia (paquete P3 de la auditoría narrativa, LifeStoryService):
--   1. busy() cuenta las escenas de cámara (CinematicService.inScene / atributo InScene, e InCinematic): no empieza
--      una conversación, no se ofrece nada, no salen encargos encima; al acabar la escena, sigue sola.
--      Un InScene olvidado no para la historia para siempre (SceneMaxSeconds).
--   2. M-01: un Transition que dice una hora («Esa noche…») con más gente en el servidor no toca el
--      reloj de todos: pone StoryClock solo en ese jugador; se quita al acabar la misión, con otra
--      Transition sin hora o por tiempo. Solo en el servidor, mueve el reloj (como siempre).
--   3. M-02: al reaparecer en el hospital solo te lleva la misión que SIGUES.
--   4. M-03: un lugar que no está en el mapa se salta CON aviso (Reach y tarea de un Group).
--
-- Uso (desde la carpeta roblox/): lune run scripts/test-storyengine.luau   (~1 min)

local process = require("@lune/process")
local task = require("@lune/task")

local H = require("./lib/StoryHarness")
local check = H.check
local ROOT = H.ROOT
local profiles = H.profiles

-- El reloj del servidor: un doble que apunta los saltos (cargado antes que LifeStoryService)
local skips: { number } = {}
H.mocks[ROOT .. "/server/Services/WorldService"] = {
	skipTo = function(clock: number)
		table.insert(skips, clock)
		return true
	end,
}

local Validate = H.loadModule(ROOT .. "/shared/LifeStory/Validate")
local Quests = H.Quests
local Service, StoryEvents = H.boot()
local LocationService = H.mocks[ROOT .. "/server/Services/LocationService"]
H.lighting.ClockTime = 20 -- por la tarde-noche: sin horario de cole por medio

local events: { { Kind: string, Player: any, Quest: string?, Info: any } } = {}
Service.observe(function(kind, player, questId, info)
	table.insert(events, { Kind = kind, Player = player, Quest = questId, Info = info })
end)

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

local function inbox(player, kind: string): { any }
	local list = {}
	for _, message in player.Inbox do
		if message.Kind == kind then
			table.insert(list, message.Payload)
		end
	end
	return list
end

local function said(player, text: string): boolean
	for _, line in player.Said do
		if line:find(text, 1, true) then
			return true
		end
	end
	return false
end

-- Misiones de prueba (secundarias que se ofrecen al hablar con alguien que no existe)
local function testQuest(id: string, steps: { any }, extra: { [string]: any }?)
	local quest = {
		Kind = "Side",
		Title = id,
		TitleKey = id,
		OfferKey = "¿Me ayudas con " .. id .. "?",
		Description = "Una misión de prueba del motor de la historia, para " .. id .. ".",
		Offer = { Event = "Talk", Match = { Npc = "Tester_" .. id } },
		Steps = steps,
	}
	for k, v in extra or {} do
		quest[k] = v
	end
	Quests[id] = quest
end

local function accept(player, id: string): boolean
	StoryEvents.emit(player, "Talk", { Npc = "Tester_" .. id })
	task.wait(0.2)
	H.fromClient(player, "Offer", id, true)
	return waitFor(function()
		return profiles[player].Story.Active[id] ~= nil
	end, 2)
end

-- Un jugador recién llegado, sin la escena de llegada abierta (en la prueba no hay pantalla que
-- avise de que ha terminado: se cierra a mano, como haría CinematicDone)
local Cine = H.loadModule(ROOT .. "/server/Services/CinematicService")
local function newPlayer(name: string)
	local player = H.newPlayer(name, "Adulto", 3600)
	task.wait(0.5)
	if Cine.endScene then
		Cine.endScene(player)
	end
	return player
end

testQuest("Test_Escena", {
	{ Type = "Reach", Place = "PlazaCentro", Text = "Ve a la plaza" },
	{ Type = "Scene", Dialogue = "Charla" },
}, { Dialogues = { Charla = { Lines = { { S = "Narrador", T = "La plaza está tranquila esta tarde." } } } } })
testQuest("Test_Noche", {
	{ Type = "Transition", Text = "Esa noche…", Seconds = 1 },
	{ Type = "Reach", Place = "PlazaCentro", Text = "Ve a la plaza" },
	{ Type = "Transition", Text = "Un mes después…", Seconds = 1 },
	{ Type = "Reach", Place = "Patio", Text = "Ve al patio" },
	{ Type = "Transition", Text = "Esa noche…", Seconds = 1 },
	{ Type = "Reach", Place = "PuntoLimpio", Text = "Ve al Punto Limpio" },
})
testQuest("Test_Lejos", {
	{ Type = "Wait", GameMinutes = 600, MaxSeconds = 600, Teleport = "PuntoLimpio", Text = "Espera en el Punto Limpio" },
})
testQuest("Test_Aqui", {
	{ Type = "Wait", GameMinutes = 600, MaxSeconds = 600, Text = "Espera" },
})
testQuest("Test_Falta", {
	{ Type = "Reach", Place = "PuntoLimpio", Text = "Ve al Punto Limpio" },
	{ Type = "Group", Text = "Recados", Steps = { { Type = "Reach", Place = "PuntoLimpio", Text = "Pasa por el Punto Limpio" } } },
	{ Type = "Reach", Place = "PlazaCentro", Text = "Vuelve a la plaza" },
})

do
	local report = Validate.report()
	local bad = {}
	for id in report.BadQuests do
		if id:sub(1, 5) == "Test_" then
			table.insert(bad, id)
		end
	end
	for _, e in report.Errors do
		if e:find("Test_", 1, true) then
			print("    " .. e)
		end
	end
	check(#bad == 0, "Las misiones de prueba son válidas")
end

---------------------------------------------------------------------
print("\n▶ 1. busy() cuenta las escenas de cámara")
---------------------------------------------------------------------
do
	local ana = newPlayer("Ana")
	task.wait(0.5)
	-- Las escenas se abren y cierran como en el juego: CinematicService (P2) lleva la lista y pone
	-- InScene/SceneId. (sin latidos de pantalla en la prueba: se le da margen para que no caduquen)
	check(type(Cine.inScene) == "function", "CinematicService.inScene existe (la respuesta buena)")
	local grace = Cine.Timing and Cine.Timing.StartGrace
	if Cine.Timing then
		Cine.Timing.StartGrace = 600
	end
	-- La pantalla late cada segundo mientras enseña la escena (SceneClient → Remotes.Scene "Beat")
	local beating = false
	task.spawn(function()
		while ana.Parent do
			if beating then
				Service.sceneBeat(ana)
			end
			task.wait(1)
		end
	end)
	local function scene(id: string)
		Cine.beginScene(ana, id, 600)
		Service.sceneBeat(ana)
		beating = true
	end
	local function noScene()
		beating = false
		Cine.endScene(ana)
	end

	check(Service.errandBlock(ana) == nil, "Sin escena, nada bloquea los encargos")
	scene("Bebe_Nacimiento")
	check(ana:GetAttribute("InScene") == true, "Al abrir la escena, el servidor pone InScene")
	check(Service.errandBlock(ana) == "Busy", "Con una escena abierta, los encargos esperan")
	noScene()
	check(Service.errandBlock(ana) == nil, "Al cerrarla, ya no")
	Cine.beginScene(ana, "SinPantalla", 600)
	task.wait(Service.SceneAckSeconds + 1.2)
	check(Service.errandBlock(ana) == nil, "Una escena lanzada que ninguna pantalla confirma (sin latido) no para la historia")
	H.fromClient(ana, "CinematicSeen", "SinPantalla")
	check(Service.errandBlock(ana) == "Busy", "…en cuanto la pantalla dice que la ve (CinematicSeen), sí")
	Cine.endScene(ana)
	ana:SetAttribute("InCinematic", true)
	check(Service.errandBlock(ana) == "Busy", "Con InCinematic, también")
	ana:SetAttribute("InCinematic", nil)
	ana:SetAttribute("InScene", true)
	check(Service.errandBlock(ana) == nil, "Un InScene suelto que CinematicService no conoce no cuenta (manda inScene)")
	ana:SetAttribute("InScene", nil)

	-- Sin CinematicService.inScene (versión vieja): se mira el atributo, defensivamente
	local fn = Cine.inScene
	Cine.inScene = nil
	ana:SetAttribute("InScene", true)
	check(Service.errandBlock(ana) == "Busy", "Sin inScene, el atributo InScene cuenta")
	ana:SetAttribute("InScene", "Bebe_Nacimiento")
	check(Service.errandBlock(ana) == "Busy", "…también con el nombre de la escena")
	ana:SetAttribute("InScene", false)
	check(Service.errandBlock(ana) == nil, "…y InScene = false no cuenta")
	ana:SetAttribute("InScene", nil)
	Cine.inScene = fn

	-- No se ofrece nada en mitad de una escena
	scene("Escena")
	local offersBefore = #inbox(ana, "Offer")
	StoryEvents.emit(ana, "Talk", { Npc = "Tester_Test_Escena" })
	task.wait(0.3)
	check(#inbox(ana, "Offer") == offersBefore, "Durante la escena no sale ninguna oferta de misión")
	noScene()

	-- La conversación del paso siguiente espera a que acabe la escena… y luego empieza sola
	check(accept(ana, "Test_Escena"), "Sin escena, la misión se ofrece y se acepta")
	scene("Escena")
	ana.At = "PlazaCentro"
	local stepped = waitFor(function()
		local prog = profiles[ana].Story.Active.Test_Escena
		return prog ~= nil and prog.Step == 2
	end, 3)
	check(stepped, "Llegar al sitio cuenta aunque haya una escena")
	task.wait(2)
	check(not said(ana, "La plaza está tranquila"), "La conversación NO empieza encima de la escena")
	check(profiles[ana].Story.Active.Test_Escena ~= nil, "…y la misión sigue esperando")
	noScene()
	check(waitFor(function()
		return profiles[ana].Story.Completed.Test_Escena ~= nil
	end, 4), "Al acabar la escena, la conversación empieza sola y la misión termina")
	check(said(ana, "La plaza está tranquila"), "…con su frase")

	-- Una escena olvidada no bloquea la historia para siempre (además del tope de CinematicService)
	local old = Service.SceneMaxSeconds
	Service.SceneMaxSeconds = 1
	scene("Colgada")
	check(Service.errandBlock(ana) == "Busy", "Escena recién puesta: ocupado")
	task.wait(1.3)
	check(Service.errandBlock(ana) == nil, "Una escena colgada más de SceneMaxSeconds deja de contar")
	scene("OtraEscena")
	check(Service.errandBlock(ana) == "Busy", "Otra escena distinta vuelve a contar desde cero")
	noScene()
	Service.SceneMaxSeconds = old
	if Cine.Timing then
		Cine.Timing.StartGrace = grace
	end
	H.leave(ana)
end

---------------------------------------------------------------------
print("\n▶ 2. Hora de una Transition: local con más gente (M-01)")
---------------------------------------------------------------------
do
	local bea = newPlayer("Bea")
	local carlos = newPlayer("Carlos")
	task.wait(0.5)
	local skipsBefore = #skips
	check(accept(bea, "Test_Noche"), "La misión de la noche empieza")
	task.wait(0.3)
	check(bea:GetAttribute("StoryClock") == 21.5, "«Esa noche…» con dos jugadores: StoryClock = 21.5 solo para ella")
	check(carlos:GetAttribute("StoryClock") == nil, "…al otro jugador no le cambia nada")
	check(#skips == skipsBefore, "…y el reloj de todos no se toca")
	local transitions = inbox(bea, "Transition")
	local last = transitions[#transitions]
	check(last ~= nil and last.Clock == 21.5 and last.LocalClock == true, "La tarjeta lleva la hora y dice que es local")

	bea.At = "PlazaCentro"
	check(waitFor(function()
		local prog = profiles[bea].Story.Active.Test_Noche
		return prog ~= nil and prog.Step == 4
	end, 3), "Pasa a «Un mes después…»")
	check(bea:GetAttribute("StoryClock") == nil, "Una Transition sin hora de la misma misión quita la noche local")

	bea.At = "Patio"
	check(waitFor(function()
		return bea:GetAttribute("StoryClock") == 21.5
	end, 3), "Otra «Esa noche…»: vuelve la noche local")
	bea.At = "PuntoLimpio"
	check(waitFor(function()
		return profiles[bea].Story.Completed.Test_Noche ~= nil
	end, 3), "La misión termina")
	check(waitFor(function()
		return bea:GetAttribute("StoryClock") == nil
	end, 2), "Al acabar la misión, la hora vuelve a ser la de todos")

	-- Por tiempo
	local old = Service.LocalClockSeconds
	Service.LocalClockSeconds = 1
	profiles[bea].Story.Completed.Test_Noche = nil
	check(accept(bea, "Test_Noche"), "Otra vez la misión de la noche")
	task.wait(0.3)
	check(bea:GetAttribute("StoryClock") == 21.5, "Noche local puesta")
	check(waitFor(function()
		return bea:GetAttribute("StoryClock") == nil
	end, 3), "…y se quita sola pasado LocalClockSeconds")
	Service.LocalClockSeconds = old
	profiles[bea].Story.Active.Test_Noche = nil

	-- Solo en el servidor: el reloj salta, como siempre, y no hay hora local
	H.leave(carlos)
	profiles[bea].Story.Completed.Test_Noche = nil
	skipsBefore = #skips
	check(accept(bea, "Test_Noche"), "Sola en el servidor, la misión de la noche empieza")
	task.wait(0.3)
	check(#skips == skipsBefore + 1 and skips[#skips] == 21.5, "Sola: el reloj del servidor salta a las 21:30")
	check(bea:GetAttribute("StoryClock") == nil, "Sola: sin hora local")
	transitions = inbox(bea, "Transition")
	last = transitions[#transitions]
	check(last ~= nil and last.LocalClock == nil, "Sola: la tarjeta no es local")
	profiles[bea].Story.Active.Test_Noche = nil
	H.leave(bea)
end

---------------------------------------------------------------------
print("\n▶ 3. Reaparecer: solo la misión que sigues (M-02)")
---------------------------------------------------------------------
do
	local dani = newPlayer("Dani")
	task.wait(0.5)
	check(accept(dani, "Test_Lejos"), "Secundaria con Teleport en marcha")
	check(accept(dani, "Test_Aqui"), "Otra secundaria sin sitio en marcha")
	H.fromClient(dani, "Track", "Test_Aqui")
	task.wait(0.2)
	check(profiles[dani].Story.Tracked == "Test_Aqui", "Sigue la que no tiene sitio")
	task.wait(4) -- (teleportStep reintenta unos segundos al empezar el paso: que acabe)

	dani.At = "Hospital"
	dani.TeleportedTo = nil
	StoryEvents.emit(dani, "Revived", {})
	task.wait(1.5)
	check(dani.At == "Hospital" and dani.TeleportedTo == nil, "Al reaparecer, una secundaria que NO sigues no te lleva a su sitio")

	H.fromClient(dani, "Track", "Test_Lejos")
	task.wait(0.2)
	dani.At = "Hospital"
	StoryEvents.emit(dani, "Revived", {})
	task.wait(1.5)
	check(dani.At == "PuntoLimpio", "Al reaparecer, la misión que sigues sí te lleva a su sitio")

	-- Muerto o detenido: no se mueve
	dani.At = "Hospital"
	dani:SetAttribute("JailUntil", os.time() + 60)
	StoryEvents.emit(dani, "Revived", {})
	task.wait(1.5)
	check(dani.At == "Hospital", "Detenido al reaparecer: te quedas donde estás")
	dani:SetAttribute("JailUntil", nil)
	profiles[dani].Story.Active.Test_Lejos = nil
	profiles[dani].Story.Active.Test_Aqui = nil
	H.leave(dani)
end

---------------------------------------------------------------------
print("\n▶ 4. Lugar que falta en el mapa: se salta con aviso (M-03)")
---------------------------------------------------------------------
do
	local realResolve = LocationService.resolve
	LocationService.resolve = function(player, placeId, ...)
		if placeId == "PuntoLimpio" then
			return nil
		end
		return realResolve(player, placeId, ...)
	end
	local W = Service.Watchdog
	local oldMissing, oldEvery = W.MissingPlace, W.Every
	W.MissingPlace, W.Every = 1, 0.5

	local eva = newPlayer("Eva")
	task.wait(0.5)
	check(accept(eva, "Test_Falta"), "Misión con un lugar que no está en el mapa")
	H.fromClient(eva, "Track", "Test_Falta")
	local function skipped(): { any }
		local list = {}
		for _, e in events do
			if e.Kind == "PlaceSkipped" and e.Player == eva and e.Quest == "Test_Falta" then
				table.insert(list, e.Info)
			end
		end
		return list
	end
	check(waitFor(function()
		local prog = profiles[eva].Story.Active.Test_Falta
		return prog ~= nil and prog.Step >= 3
	end, 8), "El vigilante salta el Reach y la tarea del Group (la historia no se queda parada)")
	local list = skipped()
	check(#list == 2, ("Hay un aviso por cada lugar saltado (%d)"):format(#list))
	local first = list[1]
	check(first ~= nil and first.Place == "PuntoLimpio", "El aviso dice qué lugar falta")
	check(first ~= nil and type(first.Text) == "string" and first.Text:find("al Punto Limpio", 1, true) ~= nil and not first.Text:find("{", 1, true),
		"El aviso al jugador es una frase con el nombre del lugar: " .. tostring(first and first.Text))
	eva.At = "PlazaCentro"
	check(waitFor(function()
		return profiles[eva].Story.Completed.Test_Falta ~= nil
	end, 3), "Y la misión termina")

	LocationService.resolve = realResolve
	W.MissingPlace, W.Every = oldMissing, oldEvery
	H.leave(eva)
end

for id in Quests do
	if id:sub(1, 5) == "Test_" then
		Quests[id] = nil
	end
end

print(("\n%s %d fallo(s)"):format(if H.failures == 0 then "✅" else "❌", H.failures))
process.exit(if H.failures == 0 then 0 else 1)
