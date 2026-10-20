-- Prueba del MAPA GALÁCTICO (Controllers/GalaxyMapUI, UI/GalaxyMapLayout, shared/Cosmos/GalaxyMap,
-- Services/GalaxyMapService), con Lune (sin Roblox). Referencia: docs/espacio-aaa/referencia-mapa-galactico.png
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-mapagalactico.luau            (las comprobaciones)
--   lune run scripts/test-mapagalactico.luau --dump     (y escribe el plano de cada pantalla en JSON para
--                                                        scripts/espacio/mapa_galactico_mock.py)
--
-- Comprueba:
--   * la pantalla cabe en 4 móviles (640x360, 667x375, 844x390, 932x430) y en tableta y ordenador sin que
--     nada se pise (paneles, pestañas, tarjeta, botones de Roblox) y lo que se toca mide ≥ 44 px;
--   * los planetas y los puntos del anillo no se pisan entre sí ni quedan debajo de los paneles;
--   * salen los 8 mundos (Sistema Valmar + los 7 planetas en el orden del dueño) con sus nombres y su estado
--     sacado de los datos del jugador (cerrado, visitado, terminado, misiones, evento global, dónde estás);
--   * a un mundo cerrado no se puede viajar; VIAJAR usa el camino que ya existe (salto cuántico con las
--     reglas de QuantumJump, VALMAR, o la ruta del GPS al puerto si no vas en la nave);
--   * las pestañas abren los paneles que ya hay (Misiones, Mochila, Personaje, Ajustes);
--   * el servidor manda los datos de verdad y apunta las visitas.

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local Vector2, Vector3 = roblox.Vector2, roblox.Vector3

local L = require("./lib/ModuleLoader")
local check = L.check

local DUMP = table.find(process.args, "--dump") ~= nil

local GalaxyMap = L.load("src/shared/Cosmos/GalaxyMap")
local Layout = L.load("src/client/UI/GalaxyMapLayout")
local Planets = L.load("src/shared/Cosmos/Planets")

local PHONES = { { 640, 360 }, { 667, 375 }, { 844, 390 }, { 932, 430 } }
local OTHERS = { { 1024, 768 }, { 1366, 768 }, { 1920, 1080 }, { 2560, 1440 } }

---------------------------------------------------------------------
print("\n🗺️ La pantalla cabe y nada se pisa (UI/GalaxyMapLayout)")
---------------------------------------------------------------------
local dump = {}
local all = {}
for _, s in PHONES do
	table.insert(all, s)
end
for _, s in OTHERS do
	table.insert(all, s)
end
for _, size in all do
	local name = ("%dx%d"):format(size[1], size[2])
	local lay = Layout.layout(Vector2.new(size[1], size[2]))
	local k = lay.Scale
	local Rr = lay.Rects
	local bad, over, small = {}, {}, {}
	local topbar = { X = 0, Y = 0, W = Layout.Topbar.X / k, H = Layout.Topbar.Y / k }
	for i, a in lay.Fixed do
		if not Layout.inside(Rr[a], lay.Canvas) then
			table.insert(bad, a)
		end
		if Layout.overlaps(Rr[a], topbar) then
			table.insert(over, a .. "/botones de Roblox")
		end
		for j = i + 1, #lay.Fixed do
			local b = lay.Fixed[j]
			if Layout.overlaps(Rr[a], Rr[b]) then
				table.insert(over, a .. "/" .. b)
			end
		end
	end
	for _, d in lay.Drawers do
		if not Layout.inside(Rr[d], lay.Canvas) then
			table.insert(bad, d)
		end
		for _, other in { "Close", "Title", "Card", "Tabs", "Compass" } do
			if Rr[other] and Layout.overlaps(Rr[d], Rr[other]) then
				table.insert(over, d .. "/" .. other)
			end
		end
	end
	-- Lo que se toca ≥ 44 px
	local touchIds = { "Close" }
	for _, t in Layout.Tabs do
		table.insert(touchIds, "Tab_" .. t)
	end
	if not lay.Wide then
		table.insert(touchIds, "LegendBtn")
		table.insert(touchIds, "MissionsBtn")
	end
	for _, id in touchIds do
		local r = Rr[id]
		if not r or math.min(r.W, r.H) * k < 44 - 0.01 then
			table.insert(small, id)
		end
	end
	if lay.Ring.Hit * k < 44 - 0.01 or lay.Ring.Thumb * k < 44 - 0.01 then
		table.insert(small, "planetas")
	end
	check(#bad == 0 and #over == 0 and #small == 0, ("%s (%s): dentro (fuera: %s), sin pisarse (%s) y lo que se toca ≥ 44 px (%s)"):format(name, if lay.Wide then "ancha" else "compacta", table.concat(bad, ", "), table.concat(over, ", "), table.concat(small, ", ")))
	check(lay.Text.Small * k >= 10.5, ("%s: letra pequeña de %.1f px (≥ 10,5)"):format(name, lay.Text.Small * k))

	-- El anillo: nada se pisa y nada queda debajo de un panel (con el zoom 1). En el móvil, los puntos de
	-- dentro salen al acercar (PoiZoom): ahí tampoco se pisan.
	local entries = GalaxyMap.entries({}, {})
	local spots = Layout.arrange(lay, entries, GalaxyMap.place)
	local items = Layout.items(lay, spots, 1)
	local hits = {}
	local majors = 0
	for i, a in items do
		if a.Id == "Valmar" or Planets.ById[a.Id] then
			majors += 1
		end
		if not Layout.inside(a.Hit, lay.Canvas) then
			table.insert(hits, a.Id .. " fuera")
		end
		for j = i + 1, #items do
			local b = items[j]
			if Layout.overlaps(a.Hit, b.Hit) then
				table.insert(hits, a.Id .. "/" .. b.Id)
			end
		end
		for _, f in lay.Fixed do
			if Layout.overlaps(a.Hit, Rr[f]) then
				table.insert(hits, a.Id .. "/" .. f)
			end
		end
	end
	check(#hits == 0 and majors == 8, ("%s: con el zoom 1 se ven los 8 mundos (%d) y los %d del anillo no se pisan ni quedan debajo de un panel (%s)"):format(name, majors, #items, table.concat(hits, ", ")))
	local zoomed = Layout.items(lay, spots, lay.Ring.PoiZoom)
	local zhits, crowded = {}, {}
	for i, a in zoomed do
		for j = i + 1, #zoomed do
			if Layout.overlaps(a.Hit, zoomed[j].Hit) then
				table.insert(zhits, a.Id .. "/" .. zoomed[j].Id)
			end
		end
	end
	for id, sp in spots do
		if sp.MinZoom > lay.Ring.PoiZoom + 1e-3 or (sp.Big and sp.MinZoom > 1 + 1e-3) then
			table.insert(crowded, id)
		end
	end
	check(#zoomed == #entries and #zhits == 0 and #crowded == 0, ("%s: con el zoom %.1f salen los %d (también estaciones, campos y sectores) sin pisarse (%s; sin sitio: %s)"):format(name, lay.Ring.PoiZoom, #zoomed, table.concat(zhits, ", "), table.concat(crowded, ", ")))
	dump[name] = { Scale = k, Canvas = { lay.Canvas.X, lay.Canvas.Y }, Wide = lay.Wide, Rects = Rr, Ring = lay.Ring, Items = items }
end

---------------------------------------------------------------------
print("\n🪐 Los 8 mundos y su estado, de los datos del jugador (shared/Cosmos/GalaxyMap)")
---------------------------------------------------------------------
local QuantumJump = L.load("src/shared/Cosmos/QuantumJump")
local NavInfo = L.load("src/shared/Cosmos/NavInfo")
local Access = L.load("src/shared/Cosmos/Access")
local SpaceEvents = L.load("src/shared/Cosmos/SpaceEvents")
local function byId(list: { any }, id: string): any
	for _, e in list do
		if e.Id == id then
			return e
		end
	end
	return nil
end
do
	-- Partida nueva: Saga 1 sin terminar → todos los planetas «Desconocido 🔒»
	local fresh = GalaxyMap.entries({ SagaDone = false, Tester = false }, {})
	local names, worlds, allLocked = {}, 0, true
	for _, e in fresh do
		if e.Kind == "Center" or e.Kind == "Planet" then
			worlds += 1
			table.insert(names, e.Name)
		end
		if e.Kind == "Planet" and not (e.Locked and e.StatusText == "Desconocido 🔒" and e.Icon == "Unknown") then
			allLocked = false
		end
	end
	local want = "Sistema Valmar, Tefra, Miasma, Siroco, Nivalis, Umbría, Tálasa, Vértice"
	check(worlds == 8 and table.concat(names, ", ") == want, ("8 mundos con su nombre y en el orden del dueño: %s"):format(table.concat(names, ", ")))
	check(allLocked, "partida nueva (Saga 1 sin terminar): los 7 planetas salen «Desconocido 🔒» y cerrados")
	check(string.find(byId(fresh, "Tefra").Locked, "Saga 1", 1, true) ~= nil, "y el motivo es el de siempre (Planets.message): «termina la Saga 1…»")
	local foreign = {}
	for _, n in { "Alfa Centauri", "Andrómeda", "Polaris", "Kepler", "Sistema Solar", "Nova" } do
		for _, e in fresh do
			if string.find(e.Name, n, 1, true) then
				table.insert(foreign, e.Name)
			end
		end
	end
	check(#foreign == 0, "ningún nombre del dibujo (estrellas reales): nuestro universo")
	local inner = {}
	for _, e in fresh do
		if e.Kind ~= "Center" and e.Kind ~= "Planet" then
			table.insert(inner, e.Name)
		end
	end
	check(#inner == 7 and table.find(inner, "Cinturón de Hierro") and table.find(inner, "Estación Alba") and table.find(inner, "Estación Cénit") and table.find(inner, "Frente de Ovilla"), "por dentro, lo que ya hay en el juego: " .. table.concat(inner, ", "))

	-- Saga 1 terminada: Tefra abierta, visitada y con 2 misiones; Miasma y los demás, aún cerrados
	local snap = {
		SagaDone = true,
		CanFly = true,
		Planets = {
			Tefra = { Status = "Ready", Visited = true, Done = false, Missions = 2 },
			Miasma = { Status = "Order", Need = "Tefra" },
			Siroco = { Status = "Soon" },
		},
		Found = { Campo_Hierro = true },
		SideMissions = { { Id = "CargaCenit", Title = "Carga para Cénit", Progress = "Entregar", TargetName = "Estación Cénit" } },
		Invasion = "⚠ Invasión de la Grieta: oleada 2",
	}
	local list = GalaxyMap.entries(snap, { Now = 10, Main = "La mochila desaparecida", Where = { Planet = "Tefra" } })
	local tefra, miasma, siroco, valmar = byId(list, "Tefra"), byId(list, "Miasma"), byId(list, "Siroco"), byId(list, "Valmar")
	check(not tefra.Locked and tefra.StatusText == "Misiones activas" and tefra.Here and tefra.Lines[1][2] == "Bastión Ceniza", "Tefra (abierta, visitada, 2 misiones, estás ahí): «Misiones activas», «Tu posición» y su ciudad")
	check(miasma.Locked and miasma.StatusText == "Desconocido 🔒" and string.find(miasma.Locked, "Tefra", 1, true), "Miasma (antes Tefra): «Desconocido 🔒» y dice qué falta")
	check(siroco.Locked and string.find(siroco.Locked, "próximamente", 1, true), "Siroco (episodio sin hacer): cerrado, «próximamente»")
	check(valmar.StatusText == "Evento global" and valmar.Icon == "Event" and not valmar.Here, "Valmar con la Invasión de la Grieta en marcha: «Evento global» (rojo)")
	local hierro = byId(list, "Hierro")
	local ev = SpaceEvents.at(10)
	check(ev.Active and ev.Kind == "Tormenta" and ev.PlaceId == "Hierro" and hierro.StatusText == "Evento global" and not hierro.Locked, "Tormenta de asteroides en marcha en el Cinturón de Hierro (descubierto): «Evento global»")
	check(byId(list, "Brasa").Locked and byId(list, "Brasa").StatusText == "Sin descubrir 🔒", "Campo Brasa sin descubrir: cerrado (igual que en el salto cuántico)")
	check(byId(list, "Estacion_Cenit").StatusText == "Misiones activas" and byId(list, "Estacion_Alba").StatusText == "Zona segura", "la misión del tablón que lleva a Cénit sale en Cénit; Alba, «Zona segura»")
	local done = GalaxyMap.entries({ SagaDone = true, Planets = { Tefra = { Status = "Ready", Done = true } } }, {})
	check(byId(done, "Tefra").StatusText == "Explorado" and byId(done, "Tefra").Icon == "Visited", "Tefra terminada: «Explorado» (rombo verde de planeta visitado)")
	local notYet = GalaxyMap.entries({ SagaDone = true, Planets = { Tefra = { Status = "Ready" } } }, {})
	check(byId(notYet, "Tefra").StatusText == "Por explorar", "Tefra abierta pero sin pisar: «Por explorar»")
	check(GalaxyMap.hereId({ World = "Cosmos", Pos = L.load("src/shared/Cosmos/Stations").ById.Alba.Center }) == "Estacion_Alba" and GalaxyMap.hereId({}) == "Valmar", "«Tu posición»: en la nave junto a Alba, Alba; a pie en Valmar, Valmar")

	-----------------------------------------------------------------
	print("\n🚀 VIAJAR: los caminos de siempre y sus reglas (GalaxyMap.travel)")
	-----------------------------------------------------------------
	local ship = { CanFly = true, InShip = true, World = "Cosmos", Energy = 100, Cooldown = 0, Pos = NavInfo.Beacon, Found = snap.Found }
	local t = GalaxyMap.travel(tefra, ship)
	local d = QuantumJump.find(QuantumJump.list({}), "Planeta_Tefra")
	local ok2, _, cost = QuantumJump.validate({ World = "Cosmos", Energy = 100, Cooldown = 0, Pos = NavInfo.Beacon }, d)
	check(t.Ok and t.Action == "Quantum" and t.Dest == "Planeta_Tefra" and ok2 and t.Cost == cost, ("en la nave, en el espacio: salto cuántico a la órbita de Tefra (mismo destino y coste que QuantumJump: ⚡ %d)"):format(t.Cost or -1))
	check(not GalaxyMap.travel(miasma, ship).Ok and not GalaxyMap.travel(siroco, ship).Ok, "a un mundo cerrado no se puede viajar (ni con la nave)")
	local cool = table.clone(ship)
	cool.Cooldown = 5
	local tc = GalaxyMap.travel(tefra, cool)
	check(not tc.Ok and string.find(tc.Reason, "recargando", 1, true), "salto en recarga: no, y dice por qué (" .. tostring(tc.Reason) .. ")")
	local low = table.clone(ship)
	low.Energy = 5
	check(not GalaxyMap.travel(tefra, low).Ok, "sin energía: no")
	local fight = table.clone(ship)
	fight.InCombat = true
	check(not GalaxyMap.travel(tefra, fight).Ok, "en combate: no")
	local onPlanet = { CanFly = true, InShip = true, World = "Planet", Planet = "Tefra" }
	check(not GalaxyMap.travel(tefra, onPlanet).Ok and not GalaxyMap.travel(byId(list, "Estacion_Alba"), onPlanet).Ok, "en la atmósfera de un planeta: hay que subir al espacio primero")
	local tf = GalaxyMap.travel(tefra, { CanFly = true, InShip = false })
	check(tf.Ok and tf.Action == "Route" and tf.Label == "RUTA AL PUERTO", "a pie en Valmar: nada de teletransporte, el GPS te lleva al puerto espacial")
	check(not GalaxyMap.travel(tefra, { CanFly = true, InShip = false, NearPort = true }).Ok, "junto a la nave del puerto: «Sube a la nave»")
	local noFly = GalaxyMap.travel(tefra, { CanFly = false, InShip = false })
	check(not noFly.Ok and noFly.Reason == Access.Messages.Locked, "sin la Saga 1 (ni tester): el aviso de siempre de la nave")
	check(GalaxyMap.travel(valmar, ship).Action == "Home" and not GalaxyMap.travel(valmar, { InShip = false }).Ok, "Valmar: VALMAR desde la nave; a pie en Valmar, «Ya estás en Valmar»")
	check(not GalaxyMap.travel(byId(list, "Brasa"), ship).Ok and not GalaxyMap.travel(byId(list, "Ovilla"), ship).Ok, "punto sin descubrir y Frente de Ovilla (próximamente): no")
	local th = GalaxyMap.travel(hierro, ship)
	check(not th.Ok and string.find(th.Reason, "cerca", 1, true), "Cinturón de Hierro desde la baliza: demasiado cerca para saltar (regla de QuantumJump: ve volando)")
	local far = table.clone(ship)
	far.Pos = L.load("src/shared/Cosmos/Stations").ById.Cenit.Center
	local th2 = GalaxyMap.travel(hierro, far)
	check(th2.Ok and th2.Dest == "Campo_Hierro", "desde la Estación Cénit: salto al Cinturón de Hierro (Campo_Hierro)")
end

---------------------------------------------------------------------
print("\n🖼️ La pantalla de verdad (Controllers/GalaxyMapUI con instancias de mentira)")
---------------------------------------------------------------------
-- Instancias de mentira: hijos, Parent, señales, atributos y propiedades comprobadas contra la API de Roblox
local db = roblox.getReflectionDatabase()
local badProps = {}
local function hasProp(className: string, key: string): boolean
	local c = db:GetClass(className)
	while c do
		if c.Properties[key] then
			return true
		end
		c = c.Superclass and db:GetClass(c.Superclass)
	end
	return false
end
local function signal()
	local s = { Handlers = {} }
	function s:Connect(fn)
		table.insert(self.Handlers, fn)
		return { Disconnect = function() end, Connected = true }
	end
	function s:Fire(...)
		for _, fn in self.Handlers do
			fn(...)
		end
	end
	return s
end
local EVENTS = { Activated = true, InputBegan = true, InputChanged = true, InputEnded = true }
local Fake = {}
local methods = {}
local function newFake(className: string)
	assert(db:GetClass(className), "Clase desconocida: " .. className)
	return setmetatable({ __class = className, __props = { Name = className }, __children = {}, __signals = {}, __attrs = {} }, Fake)
end
function methods:IsA(c)
	local k = db:GetClass(rawget(self, "__class"))
	while k do
		if k.Name == c then
			return true
		end
		k = k.Superclass and db:GetClass(k.Superclass)
	end
	return false
end
function methods:GetChildren()
	return table.clone(rawget(self, "__children"))
end
function methods:GetDescendants()
	local out = {}
	local function walk(i)
		for _, ch in rawget(i, "__children") do
			table.insert(out, ch)
			walk(ch)
		end
	end
	walk(self)
	return out
end
function methods:FindFirstChild(name)
	for _, ch in rawget(self, "__children") do
		if ch.Name == name then
			return ch
		end
	end
	return nil
end
function methods:FindFirstChildWhichIsA(c)
	for _, ch in rawget(self, "__children") do
		if ch:IsA(c) then
			return ch
		end
	end
	return nil
end
function methods:FindFirstChildOfClass(c)
	return self:FindFirstChildWhichIsA(c)
end
function methods:WaitForChild(name)
	return self:FindFirstChild(name)
end
function methods:Destroy()
	self.Parent = nil
end
function methods:GetPropertyChangedSignal(_)
	return signal()
end
function methods:SetAttribute(k, v)
	rawget(self, "__attrs")[k] = v
end
function methods:GetAttribute(k)
	return rawget(self, "__attrs")[k]
end
Fake.__index = function(self, key)
	if methods[key] then
		return methods[key]
	end
	if EVENTS[key] then
		local sigs = rawget(self, "__signals")
		sigs[key] = sigs[key] or signal()
		return sigs[key]
	end
	local v = rawget(self, "__props")[key]
	if v ~= nil then
		return v
	end
	if key == "AbsoluteSize" then
		return Vector2.new(0, 0)
	end
	return nil
end
Fake.__newindex = function(self, key, value)
	local props = rawget(self, "__props")
	if key == "Parent" then
		local old = props.Parent
		if old then
			local list = rawget(old, "__children")
			local i = table.find(list, self)
			if i then
				table.remove(list, i)
			end
		end
		props.Parent = value
		if value and getmetatable(value) == Fake then
			table.insert(rawget(value, "__children"), self)
		end
		return
	end
	if key ~= "Name" and not hasProp(rawget(self, "__class"), key) then
		table.insert(badProps, rawget(self, "__class") .. "." .. key)
	end
	props[key] = value
end
local function find(root: any, name: string): any
	if root == nil then
		return nil
	end
	for _, d in root:GetDescendants() do
		if d.Name == name then
			return d
		end
	end
	return nil
end

do
	L.fakeClasses = setmetatable({}, {
		__index = function(_, class)
			return function()
				return newFake(class)
			end
		end,
	})
	local playerGui = newFake("Folder")
	playerGui.Name = "PlayerGui"
	local attrs = { Level = 12, Money = 4250, Energy = 70, Xp = 30, XpNext = 100 }
	local fakePlayer = {
		Name = "Sebas",
		DisplayName = "Sebas",
		UserId = 1234,
		Character = nil,
		GetAttribute = function(_, k)
			return attrs[k]
		end,
		GetAttributeChangedSignal = function()
			return signal()
		end,
		WaitForChild = function(_, name)
			return if name == "PlayerGui" then playerGui else nil
		end,
	}
	L.services.Players = { LocalPlayer = fakePlayer, PlayerAdded = signal(), PlayerRemoving = signal(), GetPlayers = function()
		return {}
	end }
	L.services.UserInputService = { TouchEnabled = true, KeyboardEnabled = false, GamepadEnabled = false, InputBegan = signal(), InputChanged = signal(), InputEnded = signal(), TouchPinch = signal() }
	L.services.TweenService = { Create = function()
		return { Play = function() end }
	end }
	local camera = { ViewportSize = Vector2.new(640, 360), CFrame = roblox.CFrame.new() }
	L.workspace = { CurrentCamera = camera, GetServerTimeNow = function()
		return 10
	end }
	L.task = { spawn = function() end, wait = function() end, delay = function() end }
	L.reset()
	local UI = L.load("src/client/Controllers/GalaxyMapUI")
	local calls = { Commands = {}, Quantum = {}, Toasts = {}, Home = 0, Route = 0 }
	local shipNow: any = nil
	UI.init({
		runCommand = function(id)
			table.insert(calls.Commands, id)
		end,
		toast = function(_, text)
			table.insert(calls.Toasts, text)
		end,
		objective = function()
			return { Title = "La mochila desaparecida", Step = "Ve al colegio" }
		end,
		ship = function()
			return shipNow
		end,
		shipState = function()
			return if shipNow then { Energy = 100, Cooldown = 0, Pos = NavInfo.Beacon } else nil
		end,
		quantumTo = function(id)
			table.insert(calls.Quantum, id)
			return true
		end,
		home = function()
			calls.Home += 1
		end,
		route = function()
			calls.Route += 1
		end,
	})
	local fired = {}
	UI._setRemote({ FireServer = function(_, ...)
		table.insert(fired, { ... })
	end })
	UI._onSnapshot({
		SagaDone = true,
		CanFly = true,
		Chispas = 7,
		Cargo = 3,
		CargoMax = 20,
		Crystals = 1,
		Planets = { Tefra = { Status = "Ready", Visited = true, Missions = 1 }, Miasma = { Status = "Order", Need = "Tefra", Text = "🔒 Miasma: antes tienes que terminar Tefra" } },
		Found = {},
		SideMissions = {},
	})
	for _, size in PHONES do
		camera.ViewportSize = Vector2.new(size[1], size[2])
		UI.close()
		local okOpen, err = pcall(UI.open)
		local name = ("%dx%d"):format(size[1], size[2])
		local gui = playerGui:FindFirstChild("MapaGalactico")
		local okParts = okOpen and gui and gui.Enabled and find(gui, "Titulo") and find(gui, "Tarjeta") and find(gui, "Viajar") and find(gui, "FichaJugador") and find(gui, "BotonLeyenda") and find(gui, "BotonMisiones") and find(gui, "Pestana_Ajustes")
		local sites = 0
		for _, dd in (if gui then gui:GetDescendants() else {}) do
			if string.sub(dd.Name, 1, 6) == "Sitio_" then
				sites += 1
			end
		end
		check(okParts and sites == 15, ("%s: se monta (título, ficha, LEYENDA, MISIONES, tarjeta con VIAJAR, pestañas) con los %d sitios%s"):format(name, sites, if okOpen then "" else ": " .. tostring(err)))
	end
	check(#badProps == 0, "todas las propiedades que se ponen existen en Roblox" .. (if #badProps > 0 then ": " .. table.concat(badProps, ", ") else ""))
	check(#fired >= 1 and fired[1][1] == "Get", "al abrir pide tus datos al servidor (GalaxyMap «Get»)")
	local gui = playerGui:FindFirstChild("MapaGalactico")
	local title = find(gui, "Titulo")
	check(find(title, "Texto") and find(title, "Texto").Text == "MAPA GALÁCTICO" and find(title, "Subtitulo").Text == "Explora el universo · Descubre nuevos mundos", "título y subtítulo del dibujo")
	local ficha = find(gui, "FichaJugador")
	check(find(ficha, "Nivel").Text == "Nv. 12" and find(ficha, "Nombre").Text == "Sebas" and string.find(find(ficha, "Dinero").Text, "✨ 7", 1, true) ~= nil and string.find(find(ficha, "Avatar").Image, "1234", 1, true) ~= nil, "ficha: Nv., nombre, dinero, contadores (✨ Chispas…) y la cara del avatar")
	-- Elegir Tefra y VIAJAR a pie: ruta al puerto (no teletransporte)
	find(gui, "Sitio_Tefra").Activated:Fire()
	check(find(find(gui, "Tarjeta"), "Nombre").Text == "Tefra", "tocar un planeta lo pone en la tarjeta")
	find(gui, "Viajar").Activated:Fire()
	check(calls.Route == 1 and #calls.Quantum == 0 and not UI.isOpen(), "VIAJAR a pie: ruta del GPS al puerto espacial (y se cierra)")
	-- En la nave en el espacio: VIAJAR = salto cuántico de siempre
	shipNow = { World = "Cosmos" }
	UI.open()
	gui = playerGui:FindFirstChild("MapaGalactico")
	find(gui, "Sitio_Tefra").Activated:Fire()
	find(gui, "Viajar").Activated:Fire()
	check(calls.Quantum[1] == "Planeta_Tefra" and not UI.isOpen(), "VIAJAR en la nave: salto cuántico a Planeta_Tefra por AirCombatClient.quantumTo")
	-- Un mundo cerrado: no viaja y dice por qué
	UI.open()
	gui = playerGui:FindFirstChild("MapaGalactico")
	find(gui, "Sitio_Miasma").Activated:Fire()
	local before = #calls.Quantum
	find(gui, "Viajar").Activated:Fire()
	check(#calls.Quantum == before and UI.isOpen() and string.find(calls.Toasts[#calls.Toasts] or "", "Tefra", 1, true) ~= nil and find(gui, "Motivo").Text ~= "", "Miasma cerrada: VIAJAR no viaja, dice por qué (y la tarjeta lo pone)")
	check(UI.wanted(), "en la nave, M / «Mapa» abren el mapa galáctico")
	-- Pestañas: los paneles de siempre
	for _, pair in { { "Misiones", "Misiones" }, { "Inventario", "Mochila" }, { "Personaje", "Personaje" }, { "Ajustes", "Menu" } } do
		UI.open()
		gui = playerGui:FindFirstChild("MapaGalactico")
		find(gui, "Pestana_" .. pair[1]).Activated:Fire()
		check(calls.Commands[#calls.Commands] == pair[2] and not UI.isOpen(), ("pestaña %s → abre «%s» (Hud.runCommand, el panel que ya existe)"):format(pair[1], pair[2]))
	end
	-- Valmar en la nave → VALMAR
	UI.open()
	gui = playerGui:FindFirstChild("MapaGalactico")
	find(gui, "Sitio_Valmar").Activated:Fire()
	check(UI._state.Zoom > 1.5, "tocar Valmar acerca para ver las estaciones y los campos")
	find(gui, "Viajar").Activated:Fire()
	check(calls.Home == 1, "Valmar desde la nave: VALMAR (el remoto Space «Home» de siempre)")
	UI.close()
	L.task = nil
end

---------------------------------------------------------------------
print("\n🛰️ El servidor manda tus datos y apunta las visitas (Services/GalaxyMapService)")
---------------------------------------------------------------------
do
	local sp = { Chispas = 9, Ore = { Hierro = 2, Cristal = 1 }, Missions = { Mineral = { P = 4 } }, Planets = { Tefra = os.time() }, Found = { Campo_Brasa = 1 }, Pistas = {} }
	L.mock("src/server/Services/SpaceService", {
		spaceData = function()
			return sp
		end,
		planetStatus = function(_, id)
			return (if id == "Tefra" then "Ready" else "Order"), (if id == "Tefra" then nil else "Tefra")
		end,
	})
	L.mock("src/server/Services/DataService", { get = function()
		return { Story = { Completed = { Saga_24_Final = true } } }
	end })
	L.mock("src/server/Services/TesterService", { isTester = function()
		return false
	end })
	L.mock("src/server/Services/InvasionService", { active = function()
		return true
	end, shipEventText = function()
		return "⚠ Oleada 1"
	end })
	L.reset("src/server/Services/GalaxyMapService")
	local S = L.load("src/server/Services/GalaxyMapService")
	local p = L.player("Sebas", 1)
	local snap = S.snapshot(p)
	check(snap.SagaDone and snap.CanFly and snap.Planets.Tefra.Status == "Ready" and snap.Planets.Tefra.Done and snap.Planets.Miasma.Status == "Order" and string.find(snap.Planets.Miasma.Text, "Tefra", 1, true), "estado de cada planeta: el de SpaceService.planetStatus (y Tefra terminada)")
	check(snap.Chispas == 9 and snap.Cargo == 3 and snap.Crystals == 1 and snap.Found.Campo_Brasa and #snap.SideMissions == 1 and snap.SideMissions[1].TargetName == "Cinturón de Hierro" and snap.Invasion == "⚠ Oleada 1", "Chispas, bodega, cristales, lo descubierto, la misión del tablón y la invasión")
	check(not snap.Planets.Siroco.Visited and S.markVisited(p, "Ocrea") and sp.Visited.Siroco ~= nil, "llegar a un planeta lo apunta en data.Space.Visited (también con el nombre viejo)")
	S.setPlanetMissions("Tefra", function()
		return 3
	end)
	check(S.snapshot(p).Planets.Tefra.Missions == 3 and S.snapshot(p).Planets.Siroco.Visited, "los episodios dicen cuántas misiones hay en su planeta; Siroco ya sale visitado")
	check(not S.markVisited(p, "Andromeda"), "un planeta que no existe no se apunta")
end

---------------------------------------------------------------------
print("\n🔗 Conectado con lo que ya existe")
---------------------------------------------------------------------
do
	local main = fs.readFile("src/client/Main.client.luau")
	local map = fs.readFile("src/client/Controllers/MapUI.luau")
	local ac = fs.readFile("src/client/Controllers/AirCombatClient.luau")
	check(string.find(main, "MapUI.setGalaxy(GalaxyMapUI.toggle, GalaxyMapUI.wanted)", 1, true) and string.find(map, "galaxy.Open()", 1, true), "M / «Mapa» en el espacio o en un planeta abren la galaxia (MapUI.toggleBig)")
	check(string.find(map, "🌌 Galaxia", 1, true) ~= nil and L.load("src/shared/MapScreen").layout(Vector2.new(844, 390)).Rects.Galaxy ~= nil, "botón «🌌 Galaxia» en el mapa grande de Valmar (MapScreen: Galaxy)")
	check(string.find(main, "AirCombatClient.setGalaxyOpener(GalaxyMapUI.open)", 1, true) and string.find(ac, 'fire("Quantum", id)', 1, true), "el panel SALTO CUÁNTICO abre el mapa y VIAJAR usa el «Quantum» de siempre (Services/ShipSystems lo valida)")
	check(string.find(fs.readFile("src/server/Main.server.luau"), '"GalaxyMapService"', 1, true) ~= nil, "el servicio arranca con los demás (Main.server)")
	check(fs.isFile("assets/espacio/mapa_galaxia.jpg") and string.find(fs.readFile("assets/espacio/LICENCIAS.md"), "mapa_galaxia.jpg", 1, true) ~= nil, "fondo de la galaxia hecho con código (assets/espacio/mapa_galaxia.jpg) y en LICENCIAS.md (se sube con upload-espacio.sh)")
	local src = fs.readFile("src/client/Controllers/GalaxyMapUI.luau")
	check(not string.find(src, "Heartbeat", 1, true) and not string.find(src, "RenderStepped", 1, true) and not string.find(src, "BindToRenderStep", 1, true), "nada por fotograma (solo al arrastrar o acercar, y una vez por segundo con el mapa abierto)")
	for _, f in { "src/client/Controllers/GalaxyMapUI.luau", "src/shared/Cosmos/GalaxyMap.luau", "src/client/UI/GalaxyMapLayout.luau", "src/client/UI/PlayerCard.luau", "src/server/Services/GalaxyMapService.luau" } do
		local text = fs.readFile(f)
		check(not string.find(text, "Nova", 1, true) and not string.find(text, "NV-7", 1, true), f .. ": sin nombres prohibidos")
	end
end

if DUMP then
	-- (una partida de ejemplo: Saga 1 terminada, Tefra visitada con misiones, la tormenta en el Cinturón)
	local entries = GalaxyMap.entries({
		SagaDone = true,
		Planets = { Tefra = { Status = "Ready", Visited = true, Missions = 2 }, Miasma = { Status = "Order", Need = "Tefra" } },
		Found = { Campo_Hierro = true, Sector_Escarcha = true },
		SideMissions = { { Title = "Carga para Cénit", TargetName = "Estación Cénit" } },
	}, { Now = 10, Main = "La mochila desaparecida", Where = {} })
	local meta = {}
	for _, e in entries do
		local c = e.Color
		local p = Planets.ById[e.Id]
		meta[e.Id] = { Name = e.Name, Kind = e.Kind, StatusText = e.StatusText, Icon = e.Icon, Color = { c.R, c.G, c.B }, Here = e.Here, Locked = e.Locked ~= nil, Lines = e.Lines, Sub = e.Sub, Hue = if p then { p.Hue.R, p.Hue.G, p.Hue.B } else nil }
	end
	local legend = {}
	for _, row in GalaxyMap.Legend do
		local c = GalaxyMap.Colors[row.Id]
		table.insert(legend, { Text = row.Text, Color = { c.R, c.G, c.B } })
	end
	local texts = {}
	for name in dump do
		local w, h = string.match(name, "(%d+)x(%d+)")
		texts[name] = Layout.layout(Vector2.new(tonumber(w), tonumber(h))).Text
	end
	fs.writeFile("/tmp/mapa-galactico-dump.json", serde.encode("json", { Sizes = dump, Entries = meta, Legend = legend, Texts = texts }, true))
	print("  📝 /tmp/mapa-galactico-dump.json")
end

L.finish("test-mapagalactico")
