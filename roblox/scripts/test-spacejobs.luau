-- Prueba de los TRABAJOS ESPACIALES (shared/Cosmos/SpaceJobs, Services/SpaceJobService;
-- docs/universo/diseno-espacio.md §1), con Lune (sin Roblox).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-spacejobs.luau
--
-- Comprueba:
--   * Cuentas: estado guardado (partidas viejas), rangos y paga, tablón con semilla (mismo para todos,
--     cambia cada franja, estaciones y sectores que existen), coger (estación, rango, tope a la vez, tope
--     por hora, ya hecho), paga (rango, reputación, repetir, tarde), cobrar UNA vez, atracar (pronto,
--     a tiempo, tarde, frágil roto, otra estación), caducar y filas del HUD.
--   * Servidor: el tablón de la estación abre los contratos, coger una carga, entregarla atracando de
--     verdad (antes de tiempo no, una sola vez), carga frágil rota, derribado = carga perdida; recompensa:
--     aparece al entrar en su sector con su escolta, otro derribo no cuenta, ESE derribo paga una vez,
--     se escapa y vuelve, bajarse de la nave lo quita sin perder el contrato, salir del juego no deja
--     nada colgado, tope de Chispas compartido con los derribos y filas en el HUD de la nave.

local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")

local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local check = L.check

local SpaceJobs = L.load("src/shared/Cosmos/SpaceJobs")
local Stations = L.load("src/shared/Cosmos/Stations")
local Zone = L.load("src/shared/Cosmos/Zone")
local ShipFlight = L.load("src/shared/AirCombat/ShipFlight")

local T0 = 1_800_000_000 -- (un os.time() cualquiera, al principio de una franja)
T0 -= T0 % SpaceJobs.SlotSeconds

-- El primer contrato de esa estación que cumpla `fn`, buscando en franjas seguidas (devuelve contrato, hora)
local function findOffer(station: string, fn: (any) -> boolean, from: number?): (any, number)
	local t = from or T0
	for _ = 1, 400 do
		for _, c in SpaceJobs.offers(station, t) do
			if fn(c) then
				return c, t
			end
		end
		t += SpaceJobs.SlotSeconds
	end
	error("no hay contrato así")
end

---------------------------------------------------------------------
print("\n💾 Estado guardado y rangos")
---------------------------------------------------------------------
do
	local j = SpaceJobs.ensure(nil)
	check(type(j.Xp) == "table" and j.Xp.Carga == 0 and j.Xp.Caza == 0 and j.Rep.Gremio == 0 and j.Rep.Vigilancia == 0 and next(j.Active) == nil, "partida sin trabajos: se crea todo vacío")
	local old = SpaceJobs.ensure({ Xp = { Carga = "7" }, Rep = { Gremio = 500 }, Active = "roto" })
	check(old.Xp.Carga == 7 and old.Rep.Gremio == 100 and type(old.Active) == "table", "partida vieja o rara: se arregla sin perder la experiencia (reputación con tope 100)")
	check(SpaceJobs.rankOf(0) == 1 and SpaceJobs.rankOf(5) == 1 and SpaceJobs.rankOf(6) == 2 and SpaceJobs.rankOf(18) == 3 and SpaceJobs.rankOf(80) == 5 and SpaceJobs.rankOf(999) == 5, "5 rangos: Aprendiz, Oficial (6), Veterano (18), Experto (40), Maestro (80)")
	local pays = {}
	for _, r in SpaceJobs.Ranks do
		table.insert(pays, r.Pay)
	end
	check(table.concat(pays, ",") == "1,1.2,1.45,1.75,2.1", "la paga por rango es la de los planetas (×1,0 … ×2,1)")
	check(SpaceJobs.toNext(0) == 6 and SpaceJobs.toNext(80) == nil, "lo que falta para el siguiente rango")
end

---------------------------------------------------------------------
print("\n📋 El tablón: contratos con semilla")
---------------------------------------------------------------------
do
	local a1 = SpaceJobs.offers("Alba", T0)
	local a2 = SpaceJobs.offers("Alba", T0 + 300)
	local same = #a1 == SpaceJobs.OffersPerStation and #a1 == #a2
	for i, c in a1 do
		same = same and a2[i].Id == c.Id and a2[i].Title == c.Title and a2[i].Pay == c.Pay
	end
	check(same, ("Alba ofrece %d contratos y son los mismos en toda la franja (todos los servidores ven lo mismo)"):format(#a1))
	local nextSlot = SpaceJobs.offers("Alba", T0 + SpaceJobs.SlotSeconds)
	check(nextSlot[1].Id ~= a1[1].Id, "a los 10 minutos cambian")
	check(SpaceJobs.offers("Cenit", T0)[1].Id ~= a1[1].Id and #SpaceJobs.offers("Nada", T0) == 0, "cada estación los suyos; una estación inventada, ninguno")
	local kinds, valid, ids = {}, true, {}
	for i = 0, 40 do
		for _, st in Stations.List do
			for _, c in SpaceJobs.offers(st.Id, T0 + i * SpaceJobs.SlotSeconds) do
				kinds[c.Job] = true
				valid = valid and not ids[c.Id]
				ids[c.Id] = true
				if c.Job == "Carga" then
					valid = valid and Stations.ById[c.To] ~= nil and c.To ~= c.Station and SpaceJobs.Cargo[c.Kind] ~= nil
				elseif c.Job == "Mercenario" then
					valid = valid and (c.Kind == "Defensa" or (c.Kind == "Convoy" and Stations.ById[c.To] ~= nil and c.To ~= c.Station)) and c.Level >= 1 and c.Level <= 2
				else
					valid = valid and SpaceJobs.sectorById(c.Sector) ~= nil and type(c.Target) == "string" and c.Level >= 1 and c.Level <= 3
				end
				valid = valid and c.Pay > 0 and c.Rank >= 1 and c.Expire > 0
			end
		end
	end
	check(kinds.Carga and kinds.Caza and kinds.Mercenario, "hay de transportista, de cazarrecompensas y de mercenario")
	check(valid, "ids únicos, y solo estaciones, sectores y cargas que existen")
	local a, b = Stations.ById.Alba, Stations.ById.Cenit
	local min = SpaceJobs.minSeconds("Alba", "Cenit")
	local boost = (a.Dock - b.Dock).Magnitude / ShipFlight.Specs.Caza.BoostSpeed
	local Q = L.load("src/shared/AirCombat/ShipAbilities").Quantum
	check(min >= SpaceJobs.MinDeliver and min > Q.Charge + 5 and min <= boost, ("tiempo mínimo de entrega Alba → Cénit: %d s (más que despegar y cargar el salto cuántico de %d s; menos que volando con impulso, %.1f s)"):format(min, Q.Charge, boost))
end

---------------------------------------------------------------------
print("\n✋ Coger un contrato")
---------------------------------------------------------------------
do
	local j = SpaceJobs.ensure(nil)
	local c, t = findOffer("Alba", function(c)
		return c.Job == "Carga" and c.Rank == 1
	end)
	check(not SpaceJobs.canAccept(j, c, "Cenit", t), "en otra estación: no")
	check(select(2, SpaceJobs.canAccept(j, nil, "Alba", t)) == "Unknown", "un contrato que no existe: no")
	check(SpaceJobs.accept(j, c, "Alba", t) and j.Active[c.Id] and j.Active[c.Id].At == t, "en su estación: sí (se guarda una copia con la hora)")
	check(select(2, SpaceJobs.canAccept(j, c, "Alba", t)) == "Active", "otra vez el mismo: no")
	local hard = findOffer("Alba", function(x)
		return x.Rank >= 2
	end)
	check(select(2, SpaceJobs.canAccept(j, hard, "Alba", t)) ~= nil and select(2, SpaceJobs.canAccept(SpaceJobs.ensure(nil), hard, hard.Station, t)) == "Rank", "uno de Oficial siendo Aprendiz: no (rango)")
	-- Tope a la vez
	local n = 1
	local tt = t
	while SpaceJobs.activeCount(j) < SpaceJobs.MaxActive do
		local more, at = findOffer("Alba", function(x)
			return x.Rank == 1 and not j.Active[x.Id]
		end, tt)
		SpaceJobs.accept(j, more, "Alba", at)
		tt = at
		n += 1
	end
	local extra = findOffer("Alba", function(x)
		return x.Rank == 1 and not j.Active[x.Id]
	end, tt)
	check(select(2, SpaceJobs.canAccept(j, extra, "Alba", tt)) == "Full", ("como mucho %d a la vez"):format(SpaceJobs.MaxActive))
	-- Ya hecho
	local done = SpaceJobs.ensure(nil)
	SpaceJobs.accept(done, c, "Alba", t)
	SpaceJobs.complete(done, c.Id, t + 100)
	check(select(2, SpaceJobs.canAccept(done, c, "Alba", t + 200)) == "Done", "uno ya cumplido no se puede coger otra vez")
	-- Tope por hora
	local busy = SpaceJobs.ensure(nil)
	for i = 1, SpaceJobs.HourCap do
		table.insert(busy.Log, t - i)
	end
	check(select(2, SpaceJobs.canAccept(busy, c, "Alba", t)) == "Hour", ("%d completados en la última hora: descansa"):format(SpaceJobs.HourCap))
	check(SpaceJobs.canAccept(busy, c, "Alba", t + 3700), "y una hora después, otra vez sí")
end

---------------------------------------------------------------------
print("\n💰 Paga y cobrar una sola vez")
---------------------------------------------------------------------
do
	local c = { Id = "x1", Job = "Carga", Kind = "Suministros", Title = "x", Text = "", Station = "Alba", To = "Cenit", Pay = 1000, Chispas = 2, Rank = 1, Xp = 1, Expire = 9999 }
	local j = SpaceJobs.ensure(nil)
	check(SpaceJobs.payFor(j, c) == 1000 and select(2, SpaceJobs.payFor(j, c)) == 2, "Aprendiz sin reputación: la paga base")
	j.Xp.Carga = 6
	check(SpaceJobs.payFor(j, c) == 1200, "Oficial: ×1,2")
	j.Rep.Gremio = 100
	check(SpaceJobs.payFor(j, c) == 1320, "con +100 de reputación: +10 %")
	j.Rep.Gremio = -100
	check(SpaceJobs.payFor(j, c) == 1080, "con −100: −10 %")
	j.Rep.Gremio = 0
	check(SpaceJobs.payFor(j, c, true) == 600 and select(2, SpaceJobs.payFor(j, c, true)) == 0, "tarde: la mitad y sin Chispas")
	j.Last, j.Streak = "Carga:Suministros", 2
	check(SpaceJobs.payFor(j, c) == 960, "repetir lo mismo seguido: −10 % cada vez")
	j.Streak = 20
	check(SpaceJobs.payFor(j, c) == math.floor(1200 * SpaceJobs.StreakFloor + 0.5), "pero nunca menos del 60 %")
	local k = SpaceJobs.ensure(nil)
	k.Active.x1 = table.clone(c)
	k.Active.x1.At = 0
	local m1 = SpaceJobs.complete(k, "x1", 100)
	local m2 = SpaceJobs.complete(k, "x1", 101)
	check(m1 == 1000 and m2 == nil and k.Done.x1 == 100 and k.Active.x1 == nil, "cobrar: una vez; la segunda, nada")
	check(k.Xp.Carga == 1 and k.Rep.Gremio == SpaceJobs.RepWin and k.Total == 1 and #k.Log == 1, "sube la experiencia, la reputación del Gremio y el registro de la hora")
	check(SpaceJobs.complete(k, "inventado", 100) == nil, "un contrato inventado no paga")
	local f = SpaceJobs.ensure(nil)
	f.Active.x1 = table.clone(c)
	check(SpaceJobs.fail(f, "x1") and f.Rep.Gremio == SpaceJobs.RepFail and f.Active.x1 == nil and SpaceJobs.fail(f, "x1") == nil, "fallar: se quita y baja la reputación (una vez)")
end

---------------------------------------------------------------------
print("\n🛰 Atracar con carga")
---------------------------------------------------------------------
do
	local j = SpaceJobs.ensure(nil)
	j.Active.n = { Id = "n", Job = "Carga", Kind = "Suministros", To = "Cenit", MinSeconds = 30, At = 0, Expire = 9999, Title = "n", Pay = 1, Chispas = 0, Xp = 1, Rank = 1 }
	j.Active.u = { Id = "u", Job = "Carga", Kind = "Medicinas", To = "Cenit", MinSeconds = 30, Urgent = 180, At = 0, Expire = 9999, Title = "u", Pay = 1, Chispas = 0, Xp = 1, Rank = 1 }
	j.Active.f = { Id = "f", Job = "Carga", Kind = "Instrumentos", To = "Cenit", MinSeconds = 30, Fragile = true, At = 0, Expire = 9999, Title = "f", Pay = 1, Chispas = 0, Xp = 1, Rank = 1 }
	j.Active.o = { Id = "o", Job = "Carga", Kind = "Suministros", To = "Alba", MinSeconds = 30, At = 0, Expire = 9999, Title = "o", Pay = 1, Chispas = 0, Xp = 1, Rank = 1 }
	local function res(list)
		local m = {}
		for _, r in list do
			m[r.Id] = r.Result
		end
		return m
	end
	local early = res(SpaceJobs.dockResults(j, "Cenit", 10, 1))
	check(early.n == "Early" and early.u == "Early" and early.f == "Early" and early.o == nil, "antes del tiempo mínimo: no vale (y la de Alba no cuenta en Cénit)")
	local ok = res(SpaceJobs.dockResults(j, "Cenit", 60, 1))
	check(ok.n == "Done" and ok.u == "Done" and ok.f == "Done", "a tiempo y con la nave entera: entregadas")
	local broken = res(SpaceJobs.dockResults(j, "Cenit", 60, SpaceJobs.FragileHull - 0.01))
	check(broken.f == "Broken" and broken.n == "Done", "casco por debajo del 60 %: la frágil se rompe; las otras valen")
	local late = res(SpaceJobs.dockResults(j, "Cenit", 400, 1))
	check(late.u == "Late" and late.n == "Done", "la urgente fuera de hora: tarde")
	check(#SpaceJobs.cargoIds(j) == 4, "las cargas activas (se pierden si te derriban)")
end

---------------------------------------------------------------------
print("\n⌛ Caducar, olvidar y filas del HUD")
---------------------------------------------------------------------
do
	local j = SpaceJobs.ensure(nil)
	j.Active.a = { Id = "a", Job = "Caza", Kind = "Recompensa", Sector = "Ruta", Level = 2, Target = "«Rasca» Ostrel", Title = "Se busca", At = 0, Expire = 100, Pay = 1, Chispas = 1, Xp = 2, Rank = 2 }
	j.Done.viejo = 0
	j.Done.nuevo = 5000
	check(#SpaceJobs.expire(j, 50) == 0 and j.Active.a, "antes de su hora: sigue")
	local rows = SpaceJobs.targets(j, 50)
	local ruta = SpaceJobs.sectorById("Ruta")
	check(#rows == 1 and rows[1].Target == ruta.Center and rows[1].TargetName == ruta.Name and string.find(rows[1].Title, "Rasca", 1, true), "fila del HUD: el objetivo con la flecha al centro de su sector")
	local gone = SpaceJobs.expire(j, 200 + SpaceJobs.DoneKeep)
	check(#gone == 1 and j.Active.a == nil and j.Rep.Vigilancia == SpaceJobs.RepExpire, "caducado: se quita con −1 de reputación")
	check(j.Done.viejo == nil and j.Done.nuevo ~= nil, "se olvidan los hechos de hace más de 3 h (no crece el guardado)")
	local carga = SpaceJobs.ensure(nil)
	carga.Active.c = { Id = "c", Job = "Carga", Kind = "Medicinas", To = "Cenit", Urgent = 200, At = 0, Expire = 9999, Title = "Medicinas urgentes → Estación Cénit" }
	local r2 = SpaceJobs.targets(carga, 80)
	check(r2[1].Target == Stations.ById.Cenit.Dock and string.find(r2[1].Progress, "2:00", 1, true), "fila de una carga urgente: al muelle de destino, con el reloj")
	local plan = SpaceJobs.planOf({ Level = 3 })
	check(plan.Kind == "Caza" and plan.Escort == 2 and plan.Scale.Hull > 2.2, "nivel 3: un caza más duro que cualquier patrulla, con 2 de escolta")
	check(string.find(SpaceJobs.careerText(SpaceJobs.ensure(nil), "Carga"), "Aprendiz", 1, true) ~= nil, "texto de la carrera para el tablón")
end

---------------------------------------------------------------------
print("\n🖥️ Servidor: tablón, entregas y recompensas (SpaceService + SpaceJobService)")
---------------------------------------------------------------------
do
	local data = {
		Money = 100,
		Story = { Completed = { Saga_24_Final = 1 } },
		Space = { Chispas = 0, Ore = {}, Missions = {}, Mined = 0, Kills = 0, Done = 0, Planets = {} },
	}
	L.mock("src/server/Services/DataService", {
		get = function()
			return data
		end,
		addMoney = function(_, amount)
			data.Money += amount
			return true
		end,
		spend = function(_, price)
			if data.Money < price then
				return false
			end
			data.Money -= price
			return true
		end,
	})
	L.mock("src/server/Services/TesterService", { isTester = function()
		return false
	end })
	L.mock("src/server/Services/SceneService", { dip = function() end })
	local removing = {}
	L.services.Players = { PlayerRemoving = { Connect = function(_, fn)
		table.insert(removing, fn)
	end }, GetPlayers = function()
		return {}
	end }
	L.services.RunService = { IsStudio = function()
		return false
	end, Heartbeat = { Connect = function()
		return { Disconnect = function() end }
	end } }
	local acState = { Pos = Vector3.new(0, 5000, 0), Look = Vector3.new(0, 0, -1), Hull = 100, MaxHull = 100, Missiles = 2, Down = false, Safe = false, World = "Cosmos" }
	local spawned, dropped, nextId = {}, {}, 0
	L.mock("src/server/Services/AirCombatService", {
		inArena = function()
			return false
		end,
		world = function()
			return acState.World
		end,
		status = function()
			return acState
		end,
		enter = function()
			return true
		end,
		exit = function() end,
		setReturn = function() end,
		enemyList = function()
			return spawned
		end,
		spawnEnemy = function(_, kind, pos, scale)
			nextId += 1
			local id = "777_" .. nextId
			table.insert(spawned, { Id = id, Kind = kind, Pos = pos, Scale = scale })
			return id
		end,
		dropEnemy = function(_, id)
			table.insert(dropped, id)
			for i, e in spawned do
				if e.Id == id then
					table.remove(spawned, i)
					break
				end
			end
		end,
		onEvent = function() end,
	})
	L.reset("src/server/Services/SpaceService")
	L.reset("src/server/Services/SpaceJobService")
	local Space = L.load("src/server/Services/SpaceService")
	local Jobs = L.load("src/server/Services/SpaceJobService")
	Jobs.init()
	local clock = T0
	Jobs.clock = function()
		return clock
	end
	local player = L.player("Piloto", 777)
	local function standIn(stationId)
		local st = Stations.ById[stationId]
		player.Character = { FindFirstChild = function(_, name)
			if name == "HumanoidRootPart" then
				return { Position = Stations.arrival(st).Position }
			end
			return nil
		end, FindFirstChildOfClass = function()
			return nil
		end }
	end
	local function menu()
		return Space._states[player].Menu
	end
	-- El tablón de siempre lleva al de contratos
	standIn("Alba")
	local menuTexts = {}
	local oldMenu = Space.menu
	Space.menu = function(p, title, body, options)
		menuTexts = {}
		for i, o in options do
			menuTexts[i] = o.Text
		end
		menuTexts.Title = title
		menuTexts.Body = body
		return oldMenu(p, title, body, options)
	end
	-- (missionBoard usa su `menu` local: se mira la ficha que deja)
	Space.missionBoard(player, "Alba")
	local m0 = menu()
	check(m0 ~= nil and #m0.Actions >= 2, "el tablón de la estación tiene su menú")
	Space._onMenu(player, m0.Token, #m0.Actions - 1) -- (la penúltima: «🧰 Contratos»)
	check(menuTexts.Title and string.find(menuTexts.Title, "Contratos", 1, true) ~= nil, "«🧰 Contratos» abre el tablón de trabajos de la estación")
	check(string.find(menuTexts.Body, "Transportista", 1, true) ~= nil and string.find(menuTexts.Body, "Cazarrecompensas", 1, true) ~= nil, "con la carrera de transportista y de cazarrecompensas")
	local jobs = Jobs.jobsOf(player)
	check(jobs ~= nil and data.Space.Jobs == jobs, "data.Space.Jobs se crea en la partida (guardado)")

	-- Coger una carga Alba → Cénit (normal o urgente; en esta franja)
	local cargo, t1 = findOffer("Alba", function(c)
		return c.Job == "Carga" and c.Rank == 1 and not c.Fragile
	end)
	clock = t1
	Jobs.board(player, "Alba")
	local idx = nil
	for i, text in menuTexts do
		if type(i) == "number" and string.find(text, cargo.Title, 1, true) then
			idx = i
		end
	end
	check(idx ~= nil and string.find(menuTexts[idx], "$", 1, true) ~= nil, "el contrato sale con su paga")
	standIn("Cenit")
	Space._onMenu(player, menu().Token, idx)
	check(jobs.Active[cargo.Id] == nil, "fuera de la estación no se coge (el servidor mira dónde estás)")
	standIn("Alba")
	Jobs.board(player, "Alba")
	Space._onMenu(player, menu().Token, idx)
	check(jobs.Active[cargo.Id] ~= nil and jobs.Active[cargo.Id].At == t1, "en la estación: cogido")
	local rows = Space.infoFor(player).Missions
	local hasRow = false
	for _, r in rows do
		hasRow = hasRow or (r.Id == cargo.Id and r.Target == Stations.ById.Cenit.Dock)
	end
	check(hasRow, "sale en las filas de misión del HUD de la nave, con la flecha al muelle de Cénit")

	-- Entregar: atracar de verdad en Cénit
	acState.Pos = Stations.ById.Cenit.Dock
	local money0 = data.Money
	clock = t1 + 5
	Space.dock(player)
	check(jobs.Active[cargo.Id] ~= nil and data.Money == money0, "atracar antes del tiempo mínimo: no cobra")
	clock = t1 + cargo.MinSeconds + 5
	Space.dock(player)
	local pay1 = data.Money - money0
	check(jobs.Active[cargo.Id] == nil and jobs.Done[cargo.Id] == clock and pay1 == cargo.Pay, ("atracar a tiempo: entregada, +$%d"):format(pay1))
	Space.dock(player)
	check(data.Money == money0 + pay1, "atracar otra vez: no paga dos veces")
	check(jobs.Xp.Carga == cargo.Xp and jobs.Rep.Gremio == SpaceJobs.RepWin, "experiencia de transportista y reputación del Gremio")
	-- (un contrato ya hecho tampoco se puede volver a coger)
	standIn("Alba")
	local okAgain, whyAgain = SpaceJobs.accept(jobs, cargo, "Alba", clock)
	check(not okAgain and whyAgain == "Done", "el mismo contrato no se puede repetir")

	-- Frágil: se rompe si llegas con el casco bajo
	local fragile, t2 = findOffer("Alba", function(c)
		return c.Job == "Carga" and c.Fragile == true
	end, t1 + SpaceJobs.SlotSeconds)
	clock = t2
	check(SpaceJobs.accept(jobs, fragile, "Alba", clock), "coger una carga frágil")
	acState.Pos = Stations.ById[fragile.To].Dock
	acState.Hull = 40
	clock = t2 + fragile.MinSeconds + 1
	local m2 = data.Money
	Space.dock(player)
	check(jobs.Active[fragile.Id] == nil and data.Money == m2 and not jobs.Done[fragile.Id], "con el casco al 40 %: la carga frágil se rompe y no cobra")
	acState.Hull = 100

	-- Derribado con carga: se pierde
	local lost, t3 = findOffer("Alba", function(c)
		return c.Job == "Carga" and c.Rank == 1 and not jobs.Done[c.Id] and c.Id ~= fragile.Id
	end, t2 + SpaceJobs.SlotSeconds)
	clock = t3
	SpaceJobs.accept(jobs, lost, "Alba", clock)
	local rep0 = jobs.Rep.Gremio
	Space.event(player, { Type = "Down" })
	check(jobs.Active[lost.Id] == nil and jobs.Rep.Gremio == rep0 + SpaceJobs.RepFail, "derribado: la carga se pierde (−3 de reputación)")

	-- Recompensa de nivel 1 (Sector Brasa)
	local bounty, t4 = findOffer("Cenit", function(c)
		return c.Job == "Caza" and c.Level == 1
	end, t3 + SpaceJobs.SlotSeconds)
	clock = t4
	check(SpaceJobs.accept(jobs, bounty, "Cenit", clock), "coger una recompensa en la Cénit")
	local sector = SpaceJobs.sectorById(bounty.Sector)
	acState.Pos = sector.Center + Vector3.new(0, 300, 0)
	acState.Down = false
	table.clear(spawned)
	Jobs.tick(player)
	local live = Jobs._runtime[player].Live[bounty.Id]
	check(live ~= nil and #spawned == 1 and spawned[1].Kind == "Caza" and spawned[1].Scale.Hull >= 2.4 and spawned[1].Id == live.Target, "al entrar en su sector aparece el objetivo (un caza reforzado)")
	check((spawned[1].Pos - acState.Pos).Magnitude > 400 and not Zone.safeAt(spawned[1].Pos), "delante de ti, a distancia y fuera de las zonas seguras")
	Jobs.tick(player)
	check(#spawned == 1, "solo uno a la vez (no se repite cada segundo)")
	local m3 = data.Money
	Space._onKill(player, { Kind = "Caza", Id = "otro" })
	check(jobs.Active[bounty.Id] ~= nil and data.Money == m3 + Space.KillReward.Caza, "derribar a otro caza: el derribo normal, pero la recompensa no")
	local m4, ch4 = data.Money, data.Space.Chispas
	Space._onKill(player, { Kind = "Caza", Id = live.Target })
	local bountyPay = data.Money - m4 - Space.KillReward.Caza
	check(jobs.Active[bounty.Id] == nil and jobs.Done[bounty.Id] ~= nil and bountyPay == bounty.Pay, ("derribar a ESE: recompensa cobrada (+$%d)"):format(bountyPay))
	check(data.Space.Chispas >= ch4 + bounty.Chispas, "con sus Chispas de estrella")
	local m5 = data.Money
	Space._onKill(player, { Kind = "Caza", Id = live.Target })
	check(data.Money == m5 + Space.KillReward.Caza, "el mismo derribo dos veces: la recompensa no se paga otra vez")
	check(jobs.Xp.Caza == bounty.Xp and jobs.Rep.Vigilancia == SpaceJobs.RepWin, "experiencia de cazarrecompensas y reputación de la Vigilancia")

	-- Se escapa y vuelve
	local b2, t5 = findOffer("Cenit", function(c)
		return c.Job == "Caza" and c.Level == 1 and not jobs.Done[c.Id]
	end, t4 + SpaceJobs.SlotSeconds)
	clock = t5
	SpaceJobs.accept(jobs, b2, "Cenit", clock)
	acState.Pos = SpaceJobs.sectorById(b2.Sector).Center + Vector3.new(0, 300, 0)
	table.clear(spawned)
	Jobs.tick(player)
	local live2 = Jobs._runtime[player].Live[b2.Id]
	check(live2 ~= nil, "otro objetivo aparece")
	table.clear(spawned) -- (el sistema de patrullas lo ha quitado: te alejaste mucho)
	Jobs.tick(player)
	check(Jobs._runtime[player].Live[b2.Id] == nil and jobs.Active[b2.Id] ~= nil, "si se escapa, el contrato sigue")
	Jobs.tick(player)
	check(#spawned == 0, "no vuelve al instante")
	clock += SpaceJobs.RespawnGap + 1
	Jobs.tick(player)
	check(#spawned == 1 and Jobs._runtime[player].Live[b2.Id] ~= nil, ("vuelve a los %d s si sigues en su sector"):format(SpaceJobs.RespawnGap))

	-- Bajarse de la nave a mitad: el objetivo se va, el contrato sigue
	table.clear(dropped)
	local target2 = Jobs._runtime[player].Live[b2.Id].Target
	Jobs.onExit(player)
	check(table.find(dropped, target2) ~= nil and Jobs._runtime[player].Live[b2.Id] == nil and jobs.Active[b2.Id] ~= nil, "bajarse de la nave: el objetivo desaparece (sin contar como derribo) y el contrato sigue guardado")

	-- Derribado con una recompensa: el objetivo se va, el contrato sigue
	clock += SpaceJobs.RespawnGap + 1
	table.clear(spawned)
	Jobs.tick(player)
	check(#spawned == 1, "al volver al sector, vuelve a aparecer")
	acState.Down = true
	Jobs.tick(player)
	check(#spawned == 0 and jobs.Active[b2.Id] ~= nil, "derribado: el objetivo se va y el contrato sigue")
	acState.Down = false

	-- Tope de Chispas compartido con los derribos
	local b3, t6 = findOffer("Cenit", function(c)
		return c.Job == "Caza" and c.Level == 1 and not jobs.Done[c.Id] and not jobs.Active[c.Id]
	end, t5 + SpaceJobs.SlotSeconds)
	clock = t6
	SpaceJobs.accept(jobs, b3, "Cenit", clock)
	Jobs.onExit(player)
	acState.Pos = SpaceJobs.sectorById(b3.Sector).Center + Vector3.new(0, 300, 0)
	table.clear(spawned)
	local ps = Space._states[player]
	ps.KillChispas = {}
	for _ = 1, Space.ChispasPerHour do
		table.insert(ps.KillChispas, os.clock())
	end
	-- (el de b2 también está en el Brasa: puede salir cualquiera de los dos; se derriba el que salga)
	Jobs.tick(player)
	local liveAny, liveId = nil, nil
	for id, l in Jobs._runtime[player].Live do
		liveAny, liveId = l, id
	end
	local ch6 = data.Space.Chispas
	Space._onKill(player, { Kind = "Caza", Id = liveAny and liveAny.Target })
	check(liveAny ~= nil and jobs.Done[liveId] ~= nil and data.Space.Chispas == ch6, "con el tope de Chispas por hora lleno: cobra el dinero pero no más Chispas")

	-- Salir del juego: nada queda colgado
	Jobs.tick(player)
	for _, fn in removing do
		fn(player)
	end
	check(Jobs._runtime[player] == nil, "al salir del juego se olvida lo que había en memoria (los contratos siguen en la partida)")
	check(next(jobs.Active) ~= nil, "y los contratos activos siguen guardados")

	-- Un menú viejo (de otra franja) no vale
	local stale, t7 = findOffer("Alba", function(c)
		return c.Rank == 1 and not jobs.Done[c.Id] and not jobs.Active[c.Id]
	end, t6 + SpaceJobs.SlotSeconds)
	clock = t7
	standIn("Alba")
	for id in table.clone(jobs.Active) do
		SpaceJobs.fail(jobs, id, 0)
	end
	Jobs.board(player, "Alba")
	local idx2 = nil
	for i, text in menuTexts do
		if type(i) == "number" and string.find(text, stale.Title, 1, true) then
			idx2 = i
		end
	end
	clock = t7 + SpaceJobs.SlotSeconds -- (pasa la franja con el menú abierto)
	Space._onMenu(player, menu().Token, idx2)
	check(idx2 ~= nil and jobs.Active[stale.Id] == nil, "elegir un contrato de un tablón que ya ha cambiado: no se coge")
	Space.menu = oldMenu
	check(#L.warnings == 0 or not string.find(table.concat(L.warnings, "\n"), "trabajos", 1, true), "sin avisos de error de los trabajos" .. (if #L.warnings > 0 then ": " .. table.concat(L.warnings, " | ") else ""))
end

---------------------------------------------------------------------
print("\n🛡 Mercenario: cuentas del convoy y de la defensa (Mercenary)")
---------------------------------------------------------------------
local Mercenary = L.load("src/shared/Cosmos/Mercenary")
do
	local route = Mercenary.route("Alba", "Cenit")
	check(route ~= nil and route.Length > 2000 and Mercenary.route("Alba", "Alba") == nil and Mercenary.route("Alba", "Nada") == nil, ("ruta Alba → Cénit (%d studs); a la misma estación o a una inventada, no"):format(route and math.floor(route.Length) or 0))
	local clear = true
	for k = 0, 40 do
		local p = route.Start + route.Dir * (route.Length * k / 40)
		for i = 1, 3 do
			local q = Mercenary.shipPos(route, route.Length * k / 40, i)
			clear = clear and Zone.collide(q, 14) == nil and Stations.hullHit(q, 14) == nil
		end
		_ = p
	end
	check(clear, "la ruta del convoy no atraviesa asteroides ni el casco de las estaciones")
	-- Escolta pegada y sin piratas: llega, con las dos emboscadas una vez cada una
	local c = Mercenary.newConvoy(1)
	local ambush, arrived, steps = 0, nil, 0
	while not c.Done and steps < 1000 do
		steps += 1
		local lead = Mercenary.shipPos(route, c.D, 1)
		for _, ev in Mercenary.stepConvoy(c, route, 1, 1, lead + Vector3.new(0, 40, 0), {}) do
			if ev.Type == "Ambush" then
				ambush += 1
			elseif ev.Type == "Arrived" then
				arrived = ev.Alive
			end
		end
	end
	check(arrived == 2 and ambush == #Mercenary.Ambushes, ("con escolta llega entero (%d cargueros) y le salen %d emboscadas"):format(arrived or 0, ambush))
	check(steps * Mercenary.Speed >= route.Length and Mercenary.Speed < ShipFlight.Specs.Caza.MaxSpeed, "va más despacio que la nave (se le puede escoltar)")
	-- Sin escolta: espera y, si no vuelves, falla
	local h = Mercenary.newConvoy(1)
	local ev1 = Mercenary.stepConvoy(h, route, 1, 1, nil, {})
	check(ev1[1] and ev1[1].Type == "Hold" and h.D == 0, "sin escolta, el convoy se para a esperarte")
	local ev2 = Mercenary.stepConvoy(h, route, 1, 1, Mercenary.shipPos(route, 0, 1), {})
	check(ev2[1] and ev2[1].Type == "Resume" and h.D > 0, "vuelves: sigue")
	local failed = nil
	for _ = 1, Mercenary.HoldMax + 2 do
		for _, e in Mercenary.stepConvoy(h, route, 1, 1, route.Start + Vector3.new(0, 0, 9000), {}) do
			if e.Type == "Failed" then
				failed = e.Why
			end
		end
	end
	check(failed == "Abandoned" and h.Done, ("lejos más de %d s: falla (abandonado)"):format(Mercenary.HoldMax))
	-- Piratas: dañan al carguero más cercano; una Pesada pegada lo destruye
	local d = Mercenary.newConvoy(2)
	local lost = 0
	for _ = 1, 40 do
		for _, e in Mercenary.stepConvoy(d, route, 2, 1, Mercenary.shipPos(route, d.D, 1), { { Pos = Mercenary.shipPos(route, d.D, 1) + Vector3.new(0, 30, 0), Kind = "Pesada" } }) do
			if e.Type == "Lost" then
				lost += 1
			end
		end
	end
	check(lost == 1 and Mercenary.alive(d) == 2 and d.Hull[1] == 0, "una Pesada encima del primer carguero lo destruye (los demás, enteros)")
	check(#Mercenary.capGroup({ "Pesada", "Pesada", "Interceptor" }, 0) == 2 and #Mercenary.capGroup({ "Interceptor", "Interceptor", "Interceptor" }, Mercenary.MaxPirates - 1) == 1, ("topes para el móvil: una Pesada por grupo y %d piratas vivos como mucho"):format(Mercenary.MaxPirates))
	for _, lvl in Mercenary.Levels do
		for _, w in lvl.Waves do
			check(#Mercenary.capGroup(w, 0) == #w, "cada oleada ya cabe en los topes")
			break
		end
	end
	-- Defensa
	local df = Mercenary.newDefense()
	local cenit = Stations.ById.Cenit
	check(#Mercenary.stepDefense(df, "Cenit", 1, 1, 0, cenit.Center + Vector3.new(0, 0, 9000), {}) == 0 and not df.Started, "lejos de la estación no empieza")
	local st = Mercenary.stepDefense(df, "Cenit", 1, 1, 0, cenit.Center + Vector3.new(0, 0, 1200), {})
	check(st[1] and st[1].Type == "Start", "al acercarte, empieza")
	local waves, won, t = 0, false, 0
	for _ = 1, 200 do
		t += 1
		for _, e in Mercenary.stepDefense(df, "Cenit", 1, 1, t, cenit.Center + Vector3.new(0, 0, 1200), {}) do
			if e.Type == "Wave" then
				waves += 1
				for _, p in Mercenary.waveSpots("Cenit", e.Index, #e.Group) do
					check((p - cenit.Center).Magnitude > Stations.SafeRadius + 100, "la oleada sale fuera de la zona segura")
					break
				end
			elseif e.Type == "Won" then
				won = true
			end
		end
		if won then
			break
		end
	end
	check(waves == 3 and won and df.Integrity == Mercenary.Integrity, "3 oleadas limpias: estación defendida")
	local bad = Mercenary.newDefense()
	Mercenary.stepDefense(bad, "Cenit", 2, 1, 0, cenit.Center, {})
	local destroyed = false
	local many = {}
	for i = 1, 5 do
		table.insert(many, { Pos = cenit.Center + Vector3.new(800, i * 10, 0), Kind = "Pesada" })
	end
	for i = 1, 400 do
		for _, e in Mercenary.stepDefense(bad, "Cenit", 2, 1, i, cenit.Center + Vector3.new(0, 0, 1200), many) do
			destroyed = destroyed or (e.Type == "Failed" and e.Why == "Destroyed")
		end
	end
	check(destroyed and bad.Integrity == 0, "con piratas atacando sin parar, la estación cae: fallado")
end

---------------------------------------------------------------------
print("\n✈ Arquetipos nuevos: Interceptor (pasada) y Pesada (apoyo)")
---------------------------------------------------------------------
do
	local EnemyAI = L.load("src/shared/AirCombat/EnemyAI")
	local Shields = L.load("src/shared/AirCombat/Shields")
	local ShipModel = L.load("src/shared/AirCombat/ShipModel")
	local i = EnemyAI.new("i", "Interceptor", Vector3.new(0, 0, 0), Vector3.new(0, 0, -1))
	local pilot = { Id = "p", Pos = Vector3.new(0, 0, -100), Look = Vector3.new(0, 0, 1) }
	local _, _, fireClose = EnemyAI.think(i, pilot, 10)
	check(i.Mode == "Break" and not fireClose, "Interceptor: si pasa muy cerca, rompe y se aleja (no se queda pegado)")
	local far = EnemyAI.new("j", "Interceptor", Vector3.new(0, 0, 0), Vector3.new(0, 0, -1))
	local dir = EnemyAI.think(far, { Id = "p", Pos = Vector3.new(0, 0, -500) }, 10)
	check(far.Mode == "Pass" and dir:Dot(Vector3.new(0, 0, -1)) > 0.9, "Interceptor: de lejos, entra de frente a toda velocidad")
	check(EnemyAI.Kinds.Interceptor.Speed > EnemyAI.Kinds.Caza.Speed and Shields.Specs.Interceptor.Hull < Shields.Specs.CazaEnemigo.Hull, "más rápido que el caza y más frágil")
	local h = EnemyAI.new("h", "Pesada", Vector3.new(0, 0, 0), Vector3.new(0, 0, -1))
	local away = EnemyAI.think(h, { Id = "p", Pos = Vector3.new(0, 0, -200) }, 10)
	check(h.Mode == "Standoff" and away:Dot(Vector3.new(0, 0, -1)) < 0.95, "Pesada: cerca, se queda a distancia de costado (no embiste)")
	check(EnemyAI.Kinds.Pesada.Range > EnemyAI.Kinds.Caza.Range and Shields.Specs.Pesada.Hull > Shields.Specs.CazaEnemigo.Hull * 2, "Pesada: dispara de más lejos y es mucho más dura")
	local mate = EnemyAI.new("m", "Interceptor", Vector3.new(100, 0, 0), Vector3.new(0, 0, -1))
	local lejos = EnemyAI.new("l", "Interceptor", Vector3.new(2000, 0, 0), Vector3.new(0, 0, -1))
	local helped = EnemyAI.support(h, { h, mate, lejos })
	check(#helped == 1 and helped[1] == mate and #EnemyAI.support(mate, { h, mate }) == 0, "Pesada: recarga el escudo solo de los suyos que tiene cerca")
	for _, kind in { "Interceptor", "Aguja", "Pesada", "Carguero" } do
		local specs = ShipModel.specs(kind)
		check(#specs >= 5 and #specs <= 16 and table.find(ShipModel.Kinds, kind) ~= nil, ("modelo de %s: %d piezas (ligero para el móvil)"):format(kind, #specs))
	end
	local AirArena = L.load("src/server/World/AirArena")
	local okModel, model = pcall(AirArena.enemy, "Pesada", CFrame.new(0, 5000, 0))
	check(okModel and model and model.PrimaryPart ~= nil, "la arena sabe construir la Pesada")
end

---------------------------------------------------------------------
print("\n🖥️ Servidor: mercenario (convoy de verdad y defensa)")
---------------------------------------------------------------------
do
	local data = {
		Money = 0,
		Story = { Completed = { Saga_24_Final = 1 } },
		Space = { Chispas = 0, Ore = {}, Missions = {}, Mined = 0, Kills = 0, Done = 0, Planets = {} },
	}
	L.mock("src/server/Services/DataService", {
		get = function()
			return data
		end,
		addMoney = function(_, amount)
			data.Money += amount
			return true
		end,
		spend = function()
			return false
		end,
	})
	local acState = { Pos = Vector3.new(0, 5000, 0), Look = Vector3.new(0, 0, -1), Hull = 100, MaxHull = 100, Down = false, Safe = false, World = "Cosmos" }
	local spawned, nextId = {}, 0
	L.mock("src/server/Services/AirCombatService", {
		world = function()
			return acState.World
		end,
		status = function()
			return acState
		end,
		enemyList = function()
			return spawned
		end,
		spawnEnemy = function(_, kind, pos)
			nextId += 1
			local id = "m_" .. nextId
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
		onEvent = function() end,
		exit = function() end,
		setReturn = function() end,
	})
	L.reset("src/server/Services/SpaceService")
	L.reset("src/server/Services/SpaceJobService")
	local Space = L.load("src/server/Services/SpaceService")
	local Jobs = L.load("src/server/Services/SpaceJobService")
	Jobs.TweenShips = false
	local clock = T0
	Jobs.clock = function()
		return clock
	end
	local player = L.player("Mercenaria", 888)
	local jobs = Jobs.jobsOf(player)
	local convoy, tc = findOffer("Alba", function(c)
		return c.Job == "Mercenario" and c.Kind == "Convoy" and c.Level == 1
	end)
	clock = tc
	check(SpaceJobs.accept(jobs, convoy, "Alba", clock), "coger una escolta de convoy en Alba")
	acState.Pos = Stations.ById.Cenit.Center + Vector3.new(0, 0, 3000)
	Jobs.tick(player)
	check(Jobs._runtime[player].Merc[convoy.Id] == nil, "lejos del muelle de salida, el convoy no arranca")
	local from = Stations.ById[convoy.Station]
	acState.Pos = from.Dock + Vector3.new(0, 80, 0)
	Jobs.tick(player)
	local m = Jobs._runtime[player].Merc[convoy.Id]
	local folder = L.workspace:FindFirstChild("ConvoyesEspacio")
	check(m ~= nil and #m.Ships == 2 and folder ~= nil and #folder:GetChildren() == 2, "al llegar al muelle, salen 2 cargueros de verdad (modelos en el mundo)")
	local rows = Space.infoFor(player).Missions
	local row = nil
	for _, r in rows do
		if r.Id == convoy.Id then
			row = r
		end
	end
	check(row and string.find(row.Progress, "Cargueros 2/2", 1, true) ~= nil, "fila del HUD: cuántos cargueros quedan y cuánto falta")
	local ambushed, money0, steps = 0, data.Money, 0
	while jobs.Active[convoy.Id] and steps < 400 do
		steps += 1
		clock += 2
		acState.Pos = Mercenary.shipPos(m.Route, m.Convoy.D, 1) + Vector3.new(0, 60, 0)
		local before = #spawned
		Jobs.tick(player)
		if #spawned > before then
			ambushed += 1
			-- (la escolta los derriba)
			for _, e in table.clone(spawned) do
				Space._onKill(player, { Kind = e.Kind, Id = e.Id })
				for k, x in spawned do
					if x.Id == e.Id then
						table.remove(spawned, k)
					end
				end
			end
		end
	end
	check(ambushed == #Mercenary.Ambushes, ("salen %d emboscadas de piratas por el camino"):format(ambushed))
	local paid = data.Money - money0
	check(jobs.Active[convoy.Id] == nil and jobs.Done[convoy.Id] ~= nil and paid >= convoy.Pay, ("el convoy llega entero: contrato cumplido (+$%d)"):format(paid))
	check(#folder:GetChildren() == 0, "al acabar, los cargueros se quitan del mundo")
	check(jobs.Xp.Mercenario == convoy.Xp and jobs.Rep.Liga == SpaceJobs.RepWin, "experiencia de mercenario y reputación de la Liga de Estaciones")

	-- Bajarse a mitad: los cargueros vuelven al muelle y el contrato sigue
	local c2, t2 = findOffer("Alba", function(c)
		return c.Job == "Mercenario" and c.Kind == "Convoy" and c.Level == 1 and not jobs.Done[c.Id]
	end, tc + SpaceJobs.SlotSeconds)
	clock = t2
	SpaceJobs.accept(jobs, c2, "Alba", clock)
	acState.Pos = Stations.ById[c2.Station].Dock + Vector3.new(0, 80, 0)
	Jobs.tick(player)
	check(Jobs._runtime[player].Merc[c2.Id] ~= nil, "otro convoy en marcha")
	Jobs.onExit(player)
	check(Jobs._runtime[player].Merc[c2.Id] == nil and #folder:GetChildren() == 0 and jobs.Active[c2.Id] ~= nil, "bajarse de la nave: los cargueros se quitan (nada flotando) y el contrato sigue para volver a empezar")
	-- Alejarse demasiado tiempo: falla
	Jobs.tick(player)
	local rep0 = jobs.Rep.Liga
	acState.Pos = Stations.ById.Cenit.Center + Vector3.new(0, 0, 3000)
	for _ = 1, 20 do
		clock += 5
		Jobs.tick(player)
	end
	check(jobs.Active[c2.Id] == nil and jobs.Rep.Liga == rep0 + SpaceJobs.RepFail and #folder:GetChildren() == 0, "dejar solo al convoy demasiado rato: contrato fallado y cargueros fuera")

	-- Defensa de estación
	local def, t3 = findOffer("Cenit", function(c)
		return c.Job == "Mercenario" and c.Kind == "Defensa" and c.Level == 1
	end, t2 + SpaceJobs.SlotSeconds)
	clock = t3
	check(SpaceJobs.accept(jobs, def, "Cenit", clock), "coger una defensa de la Cénit")
	acState.Pos = Stations.ById.Cenit.Center + Vector3.new(0, 0, 1300)
	table.clear(spawned)
	local waves, money1 = 0, data.Money
	for _ = 1, 100 do
		clock += 3
		local before = #spawned
		Jobs.tick(player)
		if #spawned > before then
			waves += 1
			local pesadas = 0
			for _, e in spawned do
				pesadas += if e.Kind == "Pesada" then 1 else 0
				check((e.Pos - Stations.ById.Cenit.Center).Magnitude > Stations.SafeRadius, "los piratas salen fuera de la zona segura")
				break
			end
			check(#spawned <= Mercenary.MaxPirates and pesadas <= 1, "y caben en los topes del móvil")
			for _, e in table.clone(spawned) do
				Space._onKill(player, { Kind = e.Kind, Id = e.Id })
			end
			table.clear(spawned)
		end
		if not jobs.Active[def.Id] then
			break
		end
	end
	check(waves == 3 and jobs.Active[def.Id] == nil and jobs.Done[def.Id] ~= nil and data.Money - money1 >= def.Pay, "3 oleadas derribadas: estación defendida y cobrada")
end

L.finish("test-spacejobs")
