-- Prueba del PRÓLOGO DE VARKUN «La costura negra» (shared/Cosmos/Varkun, Services/VarkunService,
-- shared/LifeStory/Misiones/Saga2_Prologo; docs/universo/diseno-espacio.md §2), con Lune (sin Roblox).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-varkun.luau
--
-- Comprueba:
--   * Los sitios (carguero, anomalía, Rueca) están en el espacio, fuera de las zonas seguras y de las rocas.
--   * Las dos misiones existen en el motor de historia, sin errores del validador, con sus eventos en el
--     catálogo, Varkun y NILDA en el reparto y sus guiones generados (GuionOverlay).
--   * Servidor: atracar ofrece la parte 1 (solo con la Saga 1), cada paso se cumple por lo que pasa de
--     verdad (llegar, derribar a ESAS Agujas, atracar en la Cénit, escanear el tiempo, aguantar la Rueca),
--     la Rueca aparece y se va, y bajarse de la nave, ser derribado o salir del juego no deja nada colgado.

local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")

local Vector3 = roblox.Vector3
local check = L.check

local Varkun = L.load("src/shared/Cosmos/Varkun")
local Zone = L.load("src/shared/Cosmos/Zone")
local Layers = L.load("src/shared/Cosmos/Layers")
local Stations = L.load("src/shared/Cosmos/Stations")

---------------------------------------------------------------------
print("\n📍 Los sitios del prólogo")
---------------------------------------------------------------------
do
	for name, p in { Carguero = Varkun.WreckPos, Anomalia = Varkun.AnomalyPos, Rueca = Varkun.RuecaPos } do
		check(Layers.inSpace(p) and Layers.aiAllowed(p), name .. ": en el espacio, donde puede haber enemigos")
		check(not Zone.safeAt(p) and Zone.collide(p, 30) == nil, name .. ": fuera de las zonas seguras y sin rocas encima")
		check(math.abs(p.X) < Layers.Half and math.abs(p.Z) < Layers.Half and p.Y < Layers.TopY, name .. ": dentro de la columna del espacio")
	end
	local ruta = nil
	for _, s in Zone.Sectors do
		if s.Id == "Ruta" then
			ruta = s
		end
	end
	check(ruta and (Varkun.WreckPos - ruta.Center).Magnitude < ruta.Radius, "el carguero está en la Ruta de los Saqueadores")
	check(Stations.ById[Varkun.DeliverStation] ~= nil, "el carrete se entrega en una estación que existe")
	check(Varkun.offerPart({ Completed = {} }, false) == nil and Varkun.offerPart({ Completed = {} }, true) == 1, "sin la Saga 1 no se ofrece; con ella, la parte 1")
	check(Varkun.offerPart({ Completed = { Varkun_01_Costura = 1 } }, true) == 2 and Varkun.offerPart({ Completed = { Varkun_01_Costura = 1, Varkun_02_Escarcha = 1 } }, true) == nil, "luego la 2, y después nada")
	check(Varkun.offerPart({ Completed = {}, Active = { Varkun_01_Costura = { Step = 1 } } }, true) == nil, "con una parte a medias no se ofrece otra")
	local ph = Varkun.phaseOf({ Active = { Varkun_02_Escarcha = { Step = 3 } } })
	check(ph and ph.Step == "Rueca" and Varkun.row(ph).Target == Varkun.RuecaPos, "en qué paso estás y su flecha en el HUD")
end

---------------------------------------------------------------------
print("\n📜 Misiones, reparto, eventos y guiones")
---------------------------------------------------------------------
do
	local Quests = L.load("src/shared/LifeStory/Quests")
	local EventCatalog = L.load("src/shared/LifeStory/EventCatalog")
	local Cast = L.load("src/shared/LifeStory/Cast")
	local GuionOverlay = L.load("src/shared/LifeStory/GuionOverlay")
	local Validate = L.load("src/shared/LifeStory/Validate")
	for _, id in Varkun.Missions do
		local q = Quests[id]
		check(q ~= nil and q.Kind == "Side" and q.Offer and q.Offer.Event == "VarkunSignal", id .. ": secundaria que se ofrece con VarkunSignal")
		local okSteps = q ~= nil and #q.Steps == #Varkun.Steps[id]
		for i, s in (q and q.Steps) or {} do
			okSteps = okSteps and s.Type == "Event" and s.Event == "VarkunStep" and s.Match and s.Match.Step == Varkun.Steps[id][i]
		end
		check(okSteps, id .. ": cada paso espera su VarkunStep, en el mismo orden que el servidor")
		check(table.find(GuionOverlay.List, id) ~= nil, id .. ": tiene su guion generado (docs/historia/reescritura)")
	end
	check(EventCatalog.has("VarkunSignal") and EventCatalog.has("VarkunStep") and EventCatalog.has("SpaceJobDone"), "los eventos están en el catálogo")
	check(Cast.People.Varkun ~= nil and Cast.People.NILDA ~= nil, "Varkun y NILDA están en el reparto")
	local report = Validate.report()
	local mine = {}
	for _, e in report.Errors do
		if e:find("Varkun", 1, true) then
			table.insert(mine, e)
		end
	end
	check(#mine == 0, "el validador de misiones no encuentra errores en el prólogo" .. (if #mine > 0 then ": " .. table.concat(mine, " | ") else ""))
end

---------------------------------------------------------------------
print("\n🖥️ Servidor: el prólogo jugado de principio a fin (VarkunService)")
---------------------------------------------------------------------
do
	local data = { Money = 0, Story = { Active = {}, Completed = {} }, Space = { Chispas = 0, Ore = {}, Missions = {}, Planets = {} } }
	L.mock("src/server/Services/DataService", {
		get = function()
			return data
		end,
		addMoney = function()
			return true
		end,
	})
	local tester = false
	L.mock("src/server/Services/TesterService", { isTester = function()
		return tester
	end })
	local acState = { Pos = Vector3.new(0, 5000, 0), Look = Vector3.new(0, 0, -1), Down = false, World = "Cosmos" }
	local spawned, nextId = {}, 0
	L.mock("src/server/Services/AirCombatService", {
		status = function()
			return acState
		end,
		enemyList = function()
			return spawned
		end,
		spawnEnemy = function(_, kind, pos)
			nextId += 1
			local id = "v_" .. nextId
			table.insert(spawned, { Id = id, Kind = kind, Pos = pos })
			return id
		end,
		dropEnemy = function(_, id)
			for k, e in spawned do
				if e.Id == id then
					table.remove(spawned, k)
					break
				end
			end
		end,
	})
	local removing = {}
	L.services.Players = { PlayerRemoving = { Connect = function(_, fn)
		table.insert(removing, fn)
	end } }
	-- La historia de mentira: un oyente que hace lo que haría LifeStoryService con estas misiones
	local StoryEvents = L.load("src/server/LifeStory/StoryEvents")
	local signals, steps = {}, {}
	StoryEvents.connect(function(_, name, payload)
		if name == "VarkunSignal" then
			table.insert(signals, payload.Part)
		elseif name == "VarkunStep" then
			table.insert(steps, payload.Step)
			local ph = Varkun.phaseOf(data.Story)
			if ph and ph.Step == payload.Step then
				local prog = data.Story.Active[ph.Mission]
				prog.Step += 1
				if prog.Step > #Varkun.Steps[ph.Mission] then
					data.Story.Active[ph.Mission] = nil
					data.Story.Completed[ph.Mission] = 1
				end
			end
		end
	end)
	L.reset("src/server/Services/VarkunService")
	local V = L.load("src/server/Services/VarkunService")
	V.init()
	local clock = 100
	V.clock = function()
		return clock
	end
	local player = L.player("Piloto", 999)
	local function tick(n: number?, dt: number?)
		for _ = 1, n or 1 do
			clock += dt or 1
			V.tick(player)
		end
	end
	local scene = L.workspace:FindFirstChild("VarkunEscena")

	-- Sin la Saga 1: atracar no ofrece nada
	V.event(player, { Type = "Dock", Station = "Alba" })
	check(#signals == 0, "sin la Saga 1, atracar no ofrece el prólogo")
	data.Story.Completed.Saga_24_Final = 1
	V.event(player, { Type = "Dock", Station = "Alba" })
	check(signals[1] == 1, "con la Saga 1 terminada, atracar ofrece «La costura negra»")
	data.Story.Active.Varkun_01_Costura = { Step = 1 }

	-- 1 · La señal: el carguero aparece y se cumple al llegar
	acState.Pos = Stations.ById.Alba.Dock
	tick()
	scene = L.workspace:FindFirstChild("VarkunEscena")
	check(scene and scene:FindFirstChild("CargueroDestrozado") and #steps == 0, "el carguero destrozado está en el mundo y lejos no pasa nada")
	acState.Pos = Varkun.WreckPos + Vector3.new(0, 0, Varkun.WreckRadius - 20)
	tick()
	check(steps[1] == "Wreck", "al llegar al carguero, paso cumplido")
	-- 2 · Las Agujas
	tick()
	check(#spawned == 3 and spawned[1].Kind == "Aguja", "salen tres Agujas de los Hilanderos")
	V.event(player, { Type = "Kill", Id = "otra-cosa" })
	V.onExit(player) -- (se baja a mitad)
	check(#spawned == 0 and steps[2] == nil, "bajarse de la nave a mitad: las Agujas se van y el paso sigue pendiente")
	tick()
	check(#spawned == 3, "al volver, vuelven a salir")
	V.event(player, { Type = "Down" })
	check(#spawned == 0, "derribado: también se van")
	tick()
	for _, e in table.clone(spawned) do
		V.event(player, { Type = "Kill", Id = e.Id })
	end
	table.clear(spawned)
	tick()
	check(steps[2] == "Ambush", "derribar a ESAS tres Agujas cumple el paso")
	-- 3 · El carrete a la Cénit (y el 4 se cumple solo)
	V.event(player, { Type = "Dock", Station = "Alba" })
	check(steps[3] == nil, "atracar en otra estación no vale")
	V.event(player, { Type = "Dock", Station = "Cenit" })
	check(steps[3] == "Delivered", "atracar en la Cénit con el carrete: entregado")
	V.event(player, { Type = "Dock", Station = "Cenit" }) -- (vuelve a atracar antes de que pase solo)
	check(steps[4] == "Vault" and data.Story.Completed.Varkun_01_Costura, "el carrete se guarda y «La costura negra» se completa")
	V.event(player, { Type = "Dock", Station = "Cenit" })
	check(signals[#signals] == 2, "al volver a atracar se ofrece «Ruido en la Escarcha»")
	data.Story.Active.Varkun_02_Escarcha = { Step = 1 }

	-- Parte 2
	table.clear(steps)
	acState.Pos = Varkun.AnomalyPos + Vector3.new(0, 0, 100)
	tick()
	scene = L.workspace:FindFirstChild("VarkunEscena")
	check(steps[1] == "Anomaly" and scene:FindFirstChild("AnomaliaDeHilo"), "la anomalía de hilo está y se cumple al llegar")
	acState.Pos = Varkun.AnomalyPos + Vector3.new(0, 0, Varkun.ScanRadius + 300)
	tick(10)
	check(steps[2] == nil, "fuera de la anomalía no escanea")
	acState.Pos = Varkun.AnomalyPos + Vector3.new(0, 0, 100)
	tick(Varkun.ScanSeconds - 2)
	check(steps[2] == nil, ("dentro, el escaneo tarda %d s"):format(Varkun.ScanSeconds))
	tick(3)
	check(steps[2] == "Scanned", "escaneo completo")
	tick()
	check(scene:FindFirstChild("LaRueca") ~= nil and #spawned == #Varkun.RuecaKinds, "aparece la Rueca al fondo y salen sus Hilanderos (Agujas y una Pesada)")
	local pesadas = 0
	for _, e in spawned do
		pesadas += if e.Kind == "Pesada" then 1 else 0
	end
	check(pesadas == 1, "una sola Pesada (tope para el móvil)")
	tick(Varkun.RuecaSeconds + 1)
	check(steps[3] == "Rueca" and #spawned == 0 and scene:FindFirstChild("LaRueca") == nil, "al aguantar, la Rueca se va con los suyos")
	tick(Varkun.Auto.Calma + 2)
	check(steps[4] == "Calma" and data.Story.Completed.Varkun_02_Escarcha, "y «Ruido en la Escarcha» se completa sola mientras suenan las frases")
	V.event(player, { Type = "Dock", Station = "Cenit" })
	check(signals[#signals] == 2 and #signals == 3, "terminado el prólogo, no se ofrece nada más")

	-- Salir del juego con la Rueca delante: no queda nada colgado
	data.Story.Completed.Varkun_02_Escarcha = nil
	data.Story.Active.Varkun_02_Escarcha = { Step = 3 }
	tick()
	check(scene:FindFirstChild("LaRueca") ~= nil and #spawned > 0, "(otra vez con la Rueca delante)")
	for _, fn in removing do
		fn(player)
	end
	check(scene:FindFirstChild("LaRueca") == nil and #spawned == 0 and V._runtime[player] == nil, "salir del juego: la Rueca se quita, los Hilanderos se van y se olvida todo lo de memoria")
	-- Un tester sin la Saga 1 también lo puede probar
	local data2 = { Story = { Active = {}, Completed = {} } }
	data = data2
	tester = true
	table.clear(signals)
	V.event(player, { Type = "Dock", Station = "Alba" })
	check(signals[1] == 1, "un tester sin la Saga 1 recibe la señal (la misión pide la Saga 1 en la historia)")
end

L.finish("test-varkun")
