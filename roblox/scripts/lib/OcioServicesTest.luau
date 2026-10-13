-- Parte 3 de scripts/test-ocio.luau: los servicios de las zonas verdes de ocio con dobles (FeriaService,
-- ZonasDeporteService, KartService, SkateService y OcioFun). Cada cartel nuevo empieza su actividad y da
-- lo que tiene que dar. Se carga con lib/ModuleLoader (L) sobre los sitios ya construidos (folder).

local roblox = require("@lune/roblox")
local task = require("@lune/task")

local Vector3, CFrame = roblox.Vector3, roblox.CFrame

local M = {}

local function signal()
	local handlers = {}
	local s = {}
	function s:Connect(fn)
		table.insert(handlers, fn)
		return { Disconnect = function() end }
	end
	function s:Fire(...)
		for _, fn in table.clone(handlers) do
			fn(...)
		end
	end
	return s
end

function M.run(L, folder)
	local check = L.check
	print("\n▶ 3. Servicios: cada cartel empieza su actividad")

	-----------------------------------------------------------------
	-- Dobles de Roblox: carteles, remotos, jugadores
	-----------------------------------------------------------------
	local prompts = {}
	L.fakeClasses.ProximityPrompt = function()
		local attrs = {}
		local p = { ClassName = "ProximityPrompt", Triggered = signal(), Enabled = true, ActionText = "", ObjectText = "", __tags = {} }
		function p:SetAttribute(k, v)
			attrs[k] = v
		end
		function p:GetAttribute(k)
			return attrs[k]
		end
		function p:IsA(c)
			return c == "ProximityPrompt"
		end
		table.insert(prompts, p)
		return p
	end
	local fired = {} -- { Kind, Data, Player }
	L.fakeClasses.RemoteEvent = function()
		local r = { ClassName = "RemoteEvent", OnServerEvent = signal(), OnClientEvent = signal() }
		function r:FireClient(player, kind, data)
			table.insert(fired, { Player = player, Kind = kind, Data = data })
		end
		function r:FireAllClients(kind, data)
			table.insert(fired, { Kind = kind, Data = data })
		end
		return r
	end
	local notes = {}
	local notify = { Name = "Notify" }
	function notify:FireClient(player, kind, text)
		table.insert(notes, { Player = player, Kind = kind, Text = text })
	end
	local remotes = { Name = "Remotes", Notify = notify }
	function remotes:FindFirstChild(name)
		return rawget(self, name)
	end
	L.services.ReplicatedStorage.Remotes = remotes

	local PlayersSvc = { PlayerRemoving = signal(), PlayerAdded = signal() }
	local list = {}
	function PlayersSvc:GetPlayers()
		return list
	end
	L.services.Players = PlayersSvc
	local heartbeat = signal()
	L.services.RunService.Heartbeat = heartbeat

	local function fakePlayer(name: string, id: number, pos: Vector3)
		local attrs = {}
		local p = { Name = name, DisplayName = name, UserId = id, Parent = PlayersSvc, Pos = pos }
		function p:SetAttribute(k, v)
			attrs[k] = v
		end
		function p:GetAttribute(k)
			return attrs[k]
		end
		p.Character = {
			GetPivot = function()
				return CFrame.new(p.Pos)
			end,
			PivotTo = function(_, cf)
				p.Pos = cf.Position
			end,
		}
		table.insert(list, p)
		return p
	end

	-----------------------------------------------------------------
	-- Dobles de los servicios del juego
	-----------------------------------------------------------------
	local data: { [any]: any } = {}
	local Data = {}
	function Data.get(player)
		data[player] = data[player] or { Money = 500, Tickets = 0 }
		return data[player]
	end
	function Data.spend(player, n)
		local d = Data.get(player)
		if d.Money < n then
			return false
		end
		d.Money -= n
		return true
	end
	function Data.addMoney(player, n)
		Data.get(player).Money += n
		return true
	end
	L.mock("src/server/Services/DataService", Data)

	local bags: { [any]: { [string]: number } } = {}
	local Inventory = {}
	function Inventory.count(player, id)
		return (bags[player] or {})[id] or 0
	end
	function Inventory.canAdd()
		return true
	end
	function Inventory.add(player, id, n)
		bags[player] = bags[player] or {}
		bags[player][id] = (bags[player][id] or 0) + (n or 1)
		return true
	end
	function Inventory.remove(player, id, n)
		local have = Inventory.count(player, id)
		if have < (n or 1) then
			return false
		end
		bags[player][id] = have - (n or 1)
		return true
	end
	L.mock("src/server/Services/InventoryService", Inventory)

	local games = {}
	local MiniGame = {}
	function MiniGame.isRunning(player)
		return games[player] ~= nil
	end
	function MiniGame.start(player, spec, onDone)
		games[player] = { Spec = spec, OnDone = onDone }
		return true
	end
	local function finishGame(player, result)
		local g = games[player]
		games[player] = nil
		g.OnDone(result)
	end
	L.mock("src/server/Services/MiniGameService", MiniGame)

	local fun: { any } = {}
	local Needs = {}
	L.mock("src/server/Services/NeedsService", Needs)
	local xp = {}
	L.mock("src/server/Services/ProgressionService", {
		addXp = function(player, n)
			xp[player] = (xp[player] or 0) + n
		end,
	})
	local events = {}
	L.mock("src/server/LifeStory/StoryEvents", {
		emit = function(player, name, info)
			table.insert(events, { Player = player, Name = name, Info = info })
		end,
	})
	local bypass = false
	L.mock("src/server/Services/TesterService", {
		bypass = function()
			return bypass
		end,
	})
	L.mock("src/server/World/Npc", {
		create = function()
			local m = roblox.Instance.new("Model")
			return m
		end,
	})

	-- Vehículos: el kart y el monopatín
	local riding: { [any]: string } = {}
	local launched = {}
	local Vehicles = {}
	function Vehicles.ridingKind(player)
		return riding[player]
	end
	function Vehicles.launchAt(player, kind, cf)
		local model = { Parent = true, CF = cf, Destroyed = false }
		function model:GetPivot()
			return self.CF
		end
		function model:Destroy()
			self.Destroyed = true
			self.Parent = nil
		end
		riding[player] = kind
		table.insert(launched, { Player = player, Kind = kind, CFrame = cf, Model = model })
		return model
	end
	function Vehicles.dismount(player)
		riding[player] = nil
	end
	L.mock("src/server/Services/VehicleService", Vehicles)

	-- Deportes
	local sports = {}
	L.mock("src/server/Services/VolleyService", {
		startFree = function(player, court, onDone)
			table.insert(sports, { Sport = "Voley", Player = player, Court = court, OnDone = onDone })
			player:SetAttribute("InSport", "Voley")
			return true
		end,
	})
	L.mock("src/server/Services/RacketService", {
		joinHere = function(player, kind)
			table.insert(sports, { Sport = kind, Player = player })
			return true
		end,
	})
	L.mock("src/server/Services/RaceService", {
		startPickup = function(player, kind)
			table.insert(sports, { Sport = kind, Player = player })
			return true, "Pista"
		end,
	})

	local function promptsOn(part, action: string?)
		local out = {}
		for _, p in prompts do
			if p.Parent == part and (action == nil or p.ActionText == action) then
				table.insert(out, p)
			end
		end
		return out
	end
	local function tagged(tag)
		local out = {}
		for _, d in folder:GetDescendants() do
			if d:HasTag(tag) then
				table.insert(out, d)
			end
		end
		return out
	end
	local function noteFor(player, pattern)
		for i = #notes, 1, -1 do
			if notes[i].Player == player and string.find(notes[i].Text, pattern, 1, true) then
				return notes[i]
			end
		end
		return nil
	end

	-----------------------------------------------------------------
	-- OcioFun: diversión con la API que haya
	-----------------------------------------------------------------
	local OcioFun = L.load("src/server/Services/OcioFun")
	local p0 = fakePlayer("Sin", 900, Vector3.new(0, 0, 0))
	check(OcioFun.add(p0, 5, "Prueba") == false, "OcioFun: sin la necesidad «Diversión» no hace nada (y no falla)")
	Needs.addFun = function(player, amount, reason)
		table.insert(fun, { Player = player, Amount = amount, Reason = reason })
	end
	check(OcioFun.add(p0, 5, "Prueba") == true and fun[#fun].Amount == 5, "OcioFun: con NeedsService.addFun, +diversión")
	OcioFun.reward(p0, { Fun = 3, Money = 10, Tickets = 4, Xp = 2, Event = "OcioPlayed" })
	check(Data.get(p0).Money == 510 and Data.get(p0).Tickets == 4 and xp[p0] == 2 and events[#events].Name == "OcioPlayed", "OcioFun.reward: dinero, tickets, experiencia y suceso")
	local function funOf(player): number
		local n = 0
		for _, f in fun do
			if f.Player == player then
				n += f.Amount
			end
		end
		return n
	end

	-----------------------------------------------------------------
	-- Mercadillo y feria
	-----------------------------------------------------------------
	local Feria = L.load("src/shared/OcioFeria")
	local FeriaService = L.load("src/server/Services/FeriaService")
	local clock = { 3, 10 } -- miércoles a las 10:00
	FeriaService.clock = function()
		return clock[1], clock[2]
	end
	FeriaService.init()
	local stallParts = tagged("OcioStall")
	table.sort(stallParts, function(a, b)
		return a:GetAttribute("StallId") < b:GetAttribute("StallId")
	end)
	local seller = fakePlayer("Vendedora", 1, Vector3.new(1840, 0, -172))
	local buyer = fakePlayer("Comprador", 2, Vector3.new(1840, 0, -168))
	local rent = promptsOn(stallParts[1], "Alquilar puesto")[1]
	check(rent ~= nil and string.find(rent.ObjectText, "40", 1, true) ~= nil, "Puesto: cartel «Alquilar puesto · 40 €»")
	-- Fuera de horario no se alquila
	clock = { 3, 20 }
	rent.Triggered:Fire(seller)
	check(FeriaService.ownedStall(seller) == nil and noteFor(seller, "cerrado") ~= nil, "Con el mercadillo cerrado no se alquila (y te dice el horario)")
	clock = { 3, 10 }
	Inventory.add(seller, "Agro_Huevos", 3)
	local farmEggs = L.load("src/shared/Farming").Products.Agro_Huevos
	rent.Triggered:Fire(seller)
	local stall = FeriaService.ownedStall(seller)
	check(stall ~= nil and Data.get(seller).Money == 460, "Alquilar puesto: paga 40 € y es tuyo")
	check(seller:GetAttribute("OcioStall") == 1 and not rent.Enabled, "El cartel de alquilar se apaga mientras está alquilado")
	local buy = promptsOn(stallParts[1], "Comprar")[1]
	check(buy and buy.Enabled and string.find(buy.ObjectText, "Huevos", 1, true) ~= nil, "Los demás ven «Comprar · Huevos · precio»")
	if farmEggs then
		-- Cliente NPC
		stall.NextCustomer = 0
		local before = Data.get(seller).Money
		FeriaService.tick()
		local price = FeriaService.priceOf("Agro_Huevos")
		check(Inventory.count(seller, "Agro_Huevos") == 2 and Data.get(seller).Money == before + price and price == Feria.priceFor("Agro_Huevos", farmEggs.Price), ("Un cliente compra huevos a precio de puesto (%d €)"):format(price))
		check(funOf(seller) >= FeriaService.SaleFun and noteFor(seller, "te ha comprado") ~= nil, "La venta da diversión y avisa")
		-- Otro jugador compra
		local mBuyer = Data.get(buyer).Money
		buy.Triggered:Fire(buyer)
		check(Inventory.count(buyer, "Agro_Huevos") == 1 and Data.get(buyer).Money == mBuyer - price and Inventory.count(seller, "Agro_Huevos") == 1, "Otro jugador compra en el puesto: dinero y huevos cambian de mano")
		buy.Triggered:Fire(seller)
		check(Inventory.count(seller, "Agro_Huevos") == 1, "La dueña no se compra a sí misma")
	else
		check(false, "Farming.Products.Agro_Huevos existe (para la prueba de venta)")
	end
	local close = promptsOn(stallParts[1], "Cerrar mi puesto")[1]
	close.Triggered:Fire(buyer)
	check(FeriaService.ownedStall(seller) == stall, "Solo la dueña cierra el puesto")
	close.Triggered:Fire(seller)
	check(FeriaService.ownedStall(seller) == nil and rent.Enabled, "Cerrar el puesto lo deja libre")
	-- Se acaba el tiempo
	rent.Triggered:Fire(buyer)
	local st2 = FeriaService.ownedStall(buyer)
	st2.Until = 0
	FeriaService.tick()
	check(FeriaService.ownedStall(buyer) == nil and noteFor(buyer, "acabado") ~= nil, "Al acabar el alquiler, el puesto se libera")

	-- Casetas: solo el día de fiesta
	local booths = {}
	for _, c in tagged("OcioFairGame") do
		booths[c:GetAttribute("Game")] = c
	end
	local tiro = promptsOn(booths.Tiro)[1]
	FeriaService.tick()
	check(tiro.ActionText == "Cerrado" and string.find(tiro.ObjectText, "sábado", 1, true) ~= nil, "Entre semana, las casetas dicen «Cerrado · abre el sábado»")
	local kid = fakePlayer("Niña", 3, Vector3.new(1961, 0, -150))
	tiro.Triggered:Fire(kid)
	check(games[kid] == nil and noteFor(kid, "sábado") ~= nil, "Entre semana no se juega en la feria")
	clock = { 6, 18 } -- sábado a las 18:00
	FeriaService.tick()
	check(tiro.ActionText == "Jugar" and L.workspace:GetAttribute("OcioFiesta") == true, "El sábado por la tarde abren las casetas (y hay fiesta)")
	for _, gameId in Feria.GameOrder do
		local p = promptsOn(booths[gameId])[1]
		local money = Data.get(kid).Money
		p.Triggered:Fire(kid)
		local g = games[kid]
		check(g ~= nil and g.Spec.Game == "Timing" and g.Spec.Rounds == Feria.Games[gameId].Spec.Rounds and Data.get(kid).Money == money - Feria.Games[gameId].Price, ("«Jugar · %s» empieza su minijuego y cobra %d €"):format(Feria.Games[gameId].Name, Feria.Games[gameId].Price))
		if g then
			local t0, f0 = Data.get(kid).Tickets or 0, funOf(kid)
			finishGame(kid, { Won = true, Score = g.Spec.Rounds })
			local prize = Feria.prize(gameId, g.Spec.Rounds, true)
			check((Data.get(kid).Tickets or 0) == t0 + prize.Tickets and funOf(kid) == f0 + prize.Fun, ("%s: premio de %d tickets y +%d de diversión"):format(gameId, prize.Tickets, prize.Fun))
		end
	end
	clock = { 7, 1.5 } -- madrugada del domingo: todavía es fiesta
	FeriaService.tick()
	check(tiro.ActionText == "Jugar", "La fiesta sigue hasta las 2:00 del domingo")
	clock = { 7, 3 }
	FeriaService.tick()
	check(tiro.ActionText == "Cerrado" and L.workspace:GetAttribute("OcioFiesta") == false, "A las 3:00 del domingo se ha acabado")
	bypass = true
	tiro.Triggered:Fire(kid)
	check(games[kid] ~= nil, "En modo pruebas se juega cualquier día")
	finishGame(kid, { Won = false, Score = 0 })
	bypass = false
	-- Escenario
	local stage = tagged("OcioStage")[1]
	local act = promptsOn(stage, "Actuar")[1]
	local m0 = Data.get(kid).Money
	act.Triggered:Fire(kid)
	check(games[kid] ~= nil and games[kid].Spec.Title == "Toca en el escenario", "«Actuar» en el escenario empieza la barra de precisión")
	finishGame(kid, { Won = true, Score = 4 })
	check(Data.get(kid).Money == m0 + 12 and events[#events].Name == "BuskPlayed", "Actuar da propinas (12 € fuera de fiesta) y el suceso BuskPlayed")
	act.Triggered:Fire(kid)
	finishGame(kid, { Won = true, Score = 4 })
	check(Data.get(kid).Money == m0 + 12, "Seguido no hay más propinas (solo diversión)")
	local info = tagged("OcioFeriaInfo")[1]
	local label = info:FindFirstChildWhichIsA("SurfaceGui"):FindFirstChildWhichIsA("TextLabel")
	check(string.find(label.Text, "Próxima fiesta", 1, true) ~= nil, "El panel enseña cuándo es la próxima fiesta")
	local Config = L.load("src/shared/Config")
	check(Config.Jobs.FoodTruck ~= nil and Config.Jobs.Boxes ~= nil, "Oficios nuevos: cocinero/a de food truck y mecánico/a de boxes (JobService)")

	-----------------------------------------------------------------
	-- Vóley, tenis, pádel y carrera
	-----------------------------------------------------------------
	local Zonas = L.load("src/server/Services/ZonasDeporteService")
	Zonas.init()
	local anchors = L.workspace:FindFirstChild("OcioDeportePrompts")
	check(anchors ~= nil, "Carteles de los deportes en su carpeta")
	local bySport = {}
	for _, p in prompts do
		local sport = p:GetAttribute("Sport")
		if sport then
			bySport[sport] = bySport[sport] or {}
			table.insert(bySport[sport], p)
		end
	end
	check(bySport.Voley and #bySport.Voley == 6 and bySport.Voley[1].ActionText == "Jugar" and bySport.Voley[1].ObjectText == "Vóley", "«Jugar · Vóley» en las 2 pistas de la playa")
	local volleyer = fakePlayer("Jugadora", 4, Vector3.new(3992, 0, -338))
	bySport.Voley[1].Triggered:Fire(volleyer)
	local v = sports[#sports]
	check(v and v.Sport == "Voley" and v.Player == volleyer and math.abs(v.Court.Position.Y - (-0.7)) < 0.1, "«Jugar · Vóley» empieza un partido libre en la pista (a ras de arena)")
	task.wait(0.2)
	local other = fakePlayer("Otro", 5, Vector3.new(3992, 0, -338))
	bySport.Voley[2].Triggered:Fire(other)
	check(sports[#sports].Player ~= other, "Una pista ocupada no empieza otro partido")
	local f1 = funOf(volleyer)
	v.OnDone({ Won = true, Score = 7, Against = 3 })
	check(funOf(volleyer) == f1 + 15 and Data.get(volleyer).Money == 510, "Ganar el partido de vóley: +15 de diversión y 10 €")
	volleyer:SetAttribute("InSport", nil)
	for _, sport in { "Tenis", "Padel", "Carrera" } do
		local p = bySport[sport] and bySport[sport][1]
		task.wait(0.2)
		local n = #sports
		if p then
			p.Triggered:Fire(volleyer)
		end
		check(p ~= nil and #sports == n + 1 and sports[#sports].Sport == sport, ("«%s · %s» empieza su deporte"):format(if p then p.ActionText else "?", sport))
	end

	-----------------------------------------------------------------
	-- Karting
	-----------------------------------------------------------------
	local KartTrack = L.load("src/shared/KartTrack")
	local KartService = L.load("src/server/Services/KartService")
	KartService.COUNTDOWN = 1
	KartService.moveBot = function(model, cf)
		model.PrimaryPart.CFrame = cf
	end
	KartService.init()
	local desk = tagged("OcioKartDesk")[1]
	local race = promptsOn(desk, "Correr")[1]
	local trial = promptsOn(desk, "Contrarreloj")[1]
	check(race ~= nil and trial ~= nil and string.find(race.ObjectText, "15", 1, true) ~= nil, "Taquilla: «Correr» y «Contrarreloj» (15 € la tanda)")
	local driver = fakePlayer("Piloto", 6, Vector3.new(-1326, 0, 3012))
	local mk = Data.get(driver).Money
	race.Triggered:Fire(driver)
	local session = KartService.session(driver)
	check(session ~= nil and launched[#launched].Kind == "Kart" and Data.get(driver).Money == mk - KartTrack.Entry, "«Correr · Karts» cobra la tanda y te sube a un kart en la parrilla")
	check(session and #session.Bots == 3, "Carrera contra 3 karts de la máquina")
	local kartModel = launched[#launched].Model
	local Sitios = L.load("src/shared/OcioSitios")
	local site = Sitios.get("Karting")
	local function moveTo(x, z)
		kartModel.CF = CFrame.new(site.Center[1] + x, 0.15, site.Center[2] + z)
	end
	-- Salida anticipada
	moveTo(10, 98)
	KartService.step(session, 0.1)
	check(session.Penalty == KartService.FALSE_START, "Moverse antes del verde: +3 s de castigo")
	task.wait(1.3)
	check(session.Go ~= nil and session.Timer ~= nil, "Semáforo: luego verde y empieza el cronómetro")
	local pts = KartTrack.centerline(4)
	local gates = KartTrack.gates(pts)
	local laps = 0
	for _ = 1, 3 do
		for g = 2, #gates do
			moveTo(gates[g][1], gates[g][2])
			KartService.step(session, 0.1)
		end
		moveTo(gates[1][1], gates[1][2])
		KartService.step(session, 0.1)
	end
	for _, f in fired do
		if f.Kind == "KartLap" and f.Player == driver then
			laps += 1
		end
	end
	local finishEvent
	for _, f in fired do
		if f.Kind == "KartFinish" and f.Player == driver then
			finishEvent = f.Data
		end
	end
	check(laps == 3 and finishEvent ~= nil and session.Finished, "3 vueltas por las puertas y bandera a cuadros")
	check(finishEvent and finishEvent.Best ~= nil and finishEvent.Total >= KartService.FALSE_START, "Resultado con mejor vuelta y el castigo sumado al total")
	check(#KartService.board() == 1 and KartService.board()[1].Name == "Piloto" and string.find(KartService.boardText(), "Piloto", 1, true) ~= nil, "La mejor vuelta entra en la clasificación (panel)")
	check(data[driver].Ocio and data[driver].Ocio.KartBest ~= nil, "Tu récord se guarda (data.Ocio.KartBest)")
	check(funOf(driver) >= KartTrack.Fun, "Acabar la tanda da diversión")
	KartService.endSession(session)
	check(KartService.session(driver) == nil and kartModel.Destroyed and riding[driver] == nil, "Al acabar se baja del kart y el kart desaparece")
	-- Contrarreloj y salirse del circuito
	trial.Triggered:Fire(driver)
	local s2 = KartService.session(driver)
	check(s2 ~= nil and s2.Mode == "Contrarreloj" and #s2.Bots == 0, "«Contrarreloj · Karts»: tú solo")
	kartModel = launched[#launched].Model
	kartModel.CF = CFrame.new(site.Center[1] + 400, 0.15, site.Center[2])
	KartService.step(s2, 0.1)
	check(KartService.session(driver) == nil and noteFor(driver, "solo corre por el circuito") ~= nil, "Si sacas el kart del karting se acaba la tanda")
	local broke = fakePlayer("SinDinero", 7, Vector3.new(-1326, 0, 3012))
	Data.get(broke).Money = 3
	race.Triggered:Fire(broke)
	check(KartService.session(broke) == nil, "Sin dinero no hay tanda")

	-----------------------------------------------------------------
	-- Skatepark
	-----------------------------------------------------------------
	local SkateTricks = L.load("src/shared/SkateTricks")
	local SkateService = L.load("src/server/Services/SkateService")
	SkateService.init()
	local board = tagged("OcioSkateChallenge")[1]
	local start = promptsOn(board, "Empezar")[1]
	local skater = fakePlayer("Skater", 8, Vector3.new(1332, 0, 1420))
	start.Triggered:Fire(skater)
	check(SkateService.state(skater).Challenge == nil and noteFor(skater, "monopatín") ~= nil, "Reto de trucos: sin monopatín te dice que cojas uno")
	riding[skater] = "Monopatin"
	start.Triggered:Fire(skater)
	check(SkateService.state(skater).Challenge ~= nil, "«Empezar · Reto de trucos» con el monopatín empieza el reto")
	local st = SkateService.state(skater)
	st.LastCombo -= 3
	local got = SkateService.combo(skater, { Tricks = { { Id = "GranSalto", S = 1.2 }, { Id = "Kickflip" }, { Id = "Giro360" } } })
	local _, _, expect = SkateTricks.score({ { Id = "GranSalto", S = 1.2 }, { Id = "Kickflip" }, { Id = "Giro360" } })
	check(got == expect and st.Challenge.Score == expect, ("Un combo cuenta lo que dice SkateTricks (%d puntos) y suma al reto"):format(expect))
	check(SkateService.combo(skater, { Tricks = { { Id = "Kickflip" } } }) == 0, "Dos combos seguidísimos: el segundo no cuenta")
	st.LastCombo -= 1
	local cheat = SkateService.combo(skater, { Tricks = { { Id = "GranSalto", S = 3 }, { Id = "GranSalto", S = 3 }, { Id = "GranSalto", S = 3 } } })
	check(cheat > 0 and cheat < expect, "Más tiempo en el aire del que ha pasado no cuenta entero")
	skater.Pos = Vector3.new(0, 0, 0)
	st.LastCombo -= 3
	check(SkateService.combo(skater, { Tricks = { { Id = "Kickflip" } } }) == 0, "Fuera del skatepark los trucos no cuentan")
	skater.Pos = Vector3.new(1332, 0, 1420)
	st.Challenge.Score = SkateTricks.Challenge.Goal
	st.Challenge.Until = 0
	local money = Data.get(skater).Money
	SkateService.tick()
	check(Data.get(skater).Money == money + SkateTricks.Challenge.Prize and st.Challenge == nil, ("Reto superado: premio de %d €"):format(SkateTricks.Challenge.Prize))
	check(data[skater].Ocio and data[skater].Ocio.SkateBest == expect, "Tu mejor combo se guarda (data.Ocio.SkateBest)")
	check(funOf(skater) > 0, "Los trucos dan diversión")
end

return M
