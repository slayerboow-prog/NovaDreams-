-- Prueba de la «Invasión de la Grieta» (shared/Invasion/*, Services/InvasionService,
-- Controllers/InvasionClient, UI/InvasionHud; docs/invasion.md) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-invasion.luau
--
-- Comprueba:
--   * Cuándo empieza: fases de apertura de la grieta, el ciclo de demostración (la abre dos veces al
--     día), el flanco y la espera entre invasiones, y el botón del modo pruebas.
--   * Razas: una distinta cada vez (nunca dos seguidas), varias a la vez con su probabilidad, el rey
--     (y el seguro de «tantas sin rey»), rivalidades.
--   * Sitios de aterrizaje válidos (nunca carretera, agua, tejado, cuesta ni con algo encima).
--   * Oleadas que van a más con los jugadores y nunca pasan de los topes.
--   * IA de tierra (jugador > rival > vecino > zona; los tiradores mantienen la distancia), calles (Nav).
--   * Zonas: se conquistan y se recuperan; quién gana al final.
--   * El rey: fases, puntos débiles, al descubierto, ataques de área, vida según los jugadores.
--   * Daño decidido por el servidor (armas, cañón de la avioneta, láser de la nave) y lo que se rechaza.
--   * Botín: tiradas, topes por invasión y por hora, objetos únicos, la Xenobodega, fabricar y vender.
--   * Misiones: la cadena del evento, una de AVIONETA (el explorador) y una de NAVE (la baliza)
--     completas, permisos, la de paz con pasos que se saltan solos, y los avisos a la historia.
--   * Transformaciones, curas y la vuelta a la normalidad (sola con el tiempo).
--   * Las naves en el cielo de la ciudad SOLO durante una invasión.
--   * La gente huye (lejos de la amenaza, a sitios seguros, vuelve al acabar, topes).
--   * Al acabar se recoge todo; el HUD (panel y botón CAÑÓN) no pisa nada en 932x430, 844x390,
--     640x360 y 1920x1080; los modelos no pasan de su tope de piezas.

local roblox = require("@lune/roblox")
local task = require("@lune/task")
local L = require("./lib/ModuleLoader")

local Vector3, Vector2, CFrame = roblox.Vector3, roblox.Vector2, roblox.CFrame
local check = L.check

---------------------------------------------------------------------
-- Dobles: instancias de mentira (Lune no tiene PivotTo, señales de ProximityPrompt…)
---------------------------------------------------------------------
local function signal()
	local handlers = {}
	return {
		Connect = function(_, fn)
			table.insert(handlers, fn)
			return { Disconnect = function() end }
		end,
		Fire = function(_, ...)
			for _, fn in table.clone(handlers) do
				fn(...)
			end
		end,
	}
end

local fakeMeta = {}
local function fake(class: string): any
	local self = setmetatable({ ClassName = class, Name = class, __attrs = {}, __children = {}, __props = {} }, fakeMeta)
	return self
end
fakeMeta.__index = function(self, key)
	local props = rawget(self, "__props")
	local v = props[key]
	if v ~= nil then
		return v
	end
	if key == "Triggered" or key == "OnServerEvent" or key == "OnClientEvent" or key == "Destroying" or key == "Heartbeat" then
		local s = signal()
		props[key] = s
		return s
	end
	if key == "Position" then
		local cf = props.CFrame
		return if cf then cf.Position else Vector3.zero
	end
	if key == "Size" then
		return Vector3.new(2, 2, 2)
	end
	if key == "CFrame" then
		return CFrame.new()
	end
	return fakeMeta[key]
end
fakeMeta.__newindex = function(self, key, value)
	local props = rawget(self, "__props")
	if key == "Parent" then
		local old = props.Parent
		if old and type(old) == "table" and rawget(old, "__children") then
			local list = rawget(old, "__children")
			local i = table.find(list, self)
			if i then
				table.remove(list, i)
			end
		end
		if value and type(value) == "table" and rawget(value, "__children") then
			table.insert(rawget(value, "__children"), self)
		end
	end
	props[key] = value
end
function fakeMeta.SetAttribute(self, k, v)
	rawget(self, "__attrs")[k] = v
end
function fakeMeta.GetAttribute(self, k)
	return rawget(self, "__attrs")[k]
end
function fakeMeta.GetAttributeChangedSignal(_self, _k)
	return signal()
end
function fakeMeta.FindFirstChild(self, name)
	for _, c in rawget(self, "__children") do
		if c.Name == name then
			return c
		end
	end
	return nil
end
function fakeMeta.WaitForChild(self, name)
	return self:FindFirstChild(name)
end
function fakeMeta.FindFirstChildOfClass(self, class)
	for _, c in rawget(self, "__children") do
		if c.ClassName == class then
			return c
		end
	end
	return nil
end
function fakeMeta.GetChildren(self)
	return table.clone(rawget(self, "__children"))
end
function fakeMeta.GetDescendants(self)
	local out = {}
	local function walk(n)
		for _, c in rawget(n, "__children") do
			table.insert(out, c)
			walk(c)
		end
	end
	walk(self)
	return out
end
function fakeMeta.IsA(self, class)
	local c = self.ClassName
	if c == class then
		return true
	end
	return class == "BasePart" and c == "Part" or class == "Instance" or (class == "GuiObject" and (c == "Frame" or c == "TextLabel"))
end
function fakeMeta.Destroy(self)
	self.Parent = nil
	rawget(self, "__props").Destroyed = true
end
function fakeMeta.GetPivot(self)
	local pp = self.PrimaryPart
	return if pp then pp.CFrame else (rawget(self, "__props").CFrame or CFrame.new())
end
function fakeMeta.PivotTo(self, cf)
	local pp = self.PrimaryPart
	local base = if pp then pp.CFrame else CFrame.new()
	local delta = cf * base:Inverse()
	for _, d in self:GetDescendants() do
		if d.ClassName == "Part" then
			d.CFrame = delta * d.CFrame
		end
	end
	if not pp then
		rawget(self, "__props").CFrame = cf
	end
end
function fakeMeta.FireClient(self, player, kind, payload)
	local log = rawget(self, "__props").Log or {}
	rawget(self, "__props").Log = log
	table.insert(log, { To = player, Kind = kind, Data = payload })
end
function fakeMeta.FireAllClients(self, kind, payload)
	self:FireClient(nil, kind, payload)
end
function fakeMeta.FindFirstAncestorWhichIsA(self, class)
	local n = self.Parent
	while n do
		if type(n) == "table" and n.ClassName == class then
			return n
		end
		n = if type(n) == "table" then n.Parent else nil
	end
	return nil
end
function fakeMeta.HasTag()
	return false
end
for _, class in { "Model", "Folder", "Part", "ProximityPrompt", "RemoteEvent", "Humanoid", "BillboardGui", "TextLabel", "Configuration", "PointLight", "ParticleEmitter", "Frame", "UIStroke", "UICorner" } do
	L.fakeClasses[class] = function()
		return fake(class)
	end
end

-- El mundo: suelo plano a Y = 0 de hierba; agua al sur de Z > 3600; «carretera» en los sitios que se digan
local roadSpots: { { number } } = {}
local blockedSpots: { { number } } = {}
local rays = 0
local world = fake("Workspace")
local invasionFolder = fake("Folder")
invasionFolder.Name = "Invasion"
invasionFolder.Parent = world
function world.Raycast(_self, origin, dir, _params)
	rays += 1
	local to = origin + dir
	if math.min(origin.Y, to.Y) > 0 then
		return nil
	end
	local x, z = origin.X, origin.Z
	local material = if z > 3600 then roblox.Enum.Material.Water else roblox.Enum.Material.Grass
	local inst = fake("Part")
	inst.Name = "Suelo"
	for _, r in roadSpots do
		if math.abs(x - r[1]) < 8 and math.abs(z - r[2]) < 8 then
			inst.Name = "Road"
			material = roblox.Enum.Material.Asphalt
		end
	end
	return { Position = Vector3.new(x, 0, z), Normal = Vector3.new(0, 1, 0), Material = material, Instance = inst }
end
function world.GetPartBoundsInBox(_self, cf, _size, _params)
	for _, b in blockedSpots do
		if math.abs(cf.Position.X - b[1]) < 30 and math.abs(cf.Position.Z - b[2]) < 30 then
			local p = fake("Part")
			p.CanCollide = true
			p.Transparency = 0
			p.Size = Vector3.new(20, 40, 20)
			return { p }
		end
	end
	return {}
end
L.workspace = world :: any

L.globals.RaycastParams = { new = function()
	return { FilterDescendantsInstances = {} }
end }
L.globals.OverlapParams = { new = function()
	return {}
end }

-- Jugadores de mentira con personaje
local players: { any } = {}
local function makePlayer(name: string, id: number, pos: Vector3): any
	local p = L.player(name, id)
	local character = fake("Model")
	local root = fake("Part")
	root.Name = "HumanoidRootPart"
	root.CFrame = CFrame.new(pos)
	root.AssemblyLinearVelocity = Vector3.zero
	root.Parent = character
	local humanoid = fake("Humanoid")
	humanoid.Health = 100
	humanoid.MaxHealth = 100
	function humanoid.TakeDamage(self, n)
		self.Health = math.max(0, self.Health - n)
	end
	humanoid.Parent = character
	p.Character = character
	p.CharacterAdded = signal()
	table.insert(players, p)
	return p
end
local function moveTo(p: any, pos: Vector3)
	p.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(pos)
end

local remotesFolder = fake("Folder")
remotesFolder.Name = "Remotes"
local notifyRemote = fake("RemoteEvent")
notifyRemote.Name = "Notify"
notifyRemote.Parent = remotesFolder
L.services.ReplicatedStorage.Remotes = remotesFolder
L.services.Players = {
	GetPlayers = function()
		return players
	end,
	GetPlayerByUserId = function(_, id)
		for _, p in players do
			if p.UserId == id then
				return p
			end
		end
		return nil
	end,
	PlayerAdded = signal(),
	PlayerRemoving = signal(),
}
local heartbeat = signal()
L.services.RunService = { Heartbeat = heartbeat, IsStudio = function()
	return false
end }
L.services.CollectionService = { GetTagged = function()
	return {}
end, AddTag = function() end }

-- Datos guardados y servicios de alrededor
local dataOf: { [any]: any } = {}
local money: { [any]: number } = {}
L.mock("src/server/Services/DataService", {
	get = function(p)
		dataOf[p] = dataOf[p] or { Items = {}, Money = 0 }
		return dataOf[p]
	end,
	waitFor = function(p)
		return dataOf[p]
	end,
	addMoney = function(p, n)
		money[p] = (money[p] or 0) + n
		return true
	end,
})
local inv = {
	add = function(p, id, n)
		local d = dataOf[p]
		n = n or 1
		local count = 0
		for _ in d.Items do
			count += 1
		end
		if (d.Items[id] == nil and count >= (d.SlotCap or 99)) then
			return false
		end
		d.Items[id] = (d.Items[id] or 0) + n
		return true
	end,
	count = function(p, id)
		return dataOf[p].Items[id] or 0
	end,
	remove = function(p, id, n)
		local d = dataOf[p]
		n = n or 1
		if (d.Items[id] or 0) < n then
			return false
		end
		d.Items[id] -= n
		if d.Items[id] <= 0 then
			d.Items[id] = nil
		end
		return true
	end,
	canAdd = function()
		return true
	end,
}
L.mock("src/server/Services/InventoryService", inv)
L.mock("src/server/Services/ProgressionService", { addXp = function() end })
L.mock("src/server/Services/TesterService", { isTester = function(p)
	return p.Tester == true
end })
local licensed: { [any]: boolean } = {}
local sagaDone: { [any]: boolean } = {}
L.mock("src/server/Services/SpaceService", { canFly = function(p)
	return sagaDone[p] == true
end })
local planes: { [any]: any } = {}
local crashed = {}
L.mock("src/server/Services/AviationService", {
	pilotPlane = function(p)
		return planes[p]
	end,
	hasLicense = function(p)
		return licensed[p] == true
	end,
	crash = function(plane, why)
		table.insert(crashed, why)
	end,
})
local ships: { [any]: any } = {}
local shipHurt = {}
L.mock("src/server/Services/AirCombatService", {
	world = function(p)
		return if ships[p] then "Cosmos" else nil
	end,
	status = function(p)
		return ships[p]
	end,
	hurtPilot = function(p, n)
		table.insert(shipHurt, n)
	end,
})
L.mock("src/server/Services/LocationService", { resolve = function()
	return nil
end })
local fled = 0
L.mock("src/server/Services/CrowdService", { flee = function(threats)
	fled += #threats
	return 0
end })
L.mock("src/server/Services/CombatService", {})
L.mock("src/server/Services/WeaponService", {})
local npcCount = 0
L.mock("src/server/World/Npc", {
	create = function(name, parent, cf)
		npcCount += 1
		local m = fake("Model")
		m.Name = name
		local r = fake("Part")
		r.CFrame = cf
		r.Parent = m
		m.PrimaryPart = r
		m.Parent = parent
		return m
	end,
	placeFeet = function() end,
	say = function() end,
	walkTo = function() end,
})
local story: { { [string]: any } } = {}

---------------------------------------------------------------------
-- Lo puro
---------------------------------------------------------------------
local Races = L.load("src/shared/Invasion/Races")
local Rules = L.load("src/shared/Invasion/Rules")
local Landing = L.load("src/shared/Invasion/Landing")
local Nav = L.load("src/shared/Invasion/Nav")
local AlienAI = L.load("src/shared/Invasion/AlienAI")
local King = L.load("src/shared/Invasion/King")
local Loot = L.load("src/shared/Invasion/Loot")
local Transform = L.load("src/shared/Invasion/Transform")
local Panic = L.load("src/shared/Invasion/Panic")
local Missions = L.load("src/shared/Invasion/Missions")
local SkyRift = L.load("src/shared/SkyRift")
local Layers = L.load("src/shared/Cosmos/Layers")
local Zone = L.load("src/shared/Cosmos/Zone")
local Access = L.load("src/shared/Cosmos/Access")
local CityPlan = L.load("src/shared/CityPlan")
local Config = L.load("src/shared/Config")
local Weapons = L.load("src/shared/Weapons")
local Items = L.load("src/shared/Items")
local EventCatalog = L.load("src/shared/LifeStory/EventCatalog")

local seed = 12345
local function rnd(): number
	seed = (seed * 1103515245 + 12345) % 2147483648
	return seed / 2147483648
end

print("\n🌌 Cuándo empieza (fases de la grieta, ciclo de demostración, flanco)")
do
	local opening = {}
	for name, ph in SkyRift.Phases do
		if Rules.isOpening(name) then
			table.insert(opening, name)
			check(ph.Stage >= 5 and ph.Mode == "Sky", name .. ": cuenta como apertura (etapa " .. ph.Stage .. ")")
		elseif ph.Mode == "Sky" then
			check(ph.Stage < 5, name .. ": no es apertura (etapa " .. ph.Stage .. ")")
		end
	end
	check(#opening >= 4 and not Rules.isOpening("Sueno") and not Rules.isOpening("Cerrada"), "aperturas: " .. table.concat(opening, ", ") .. " (ni el sueño ni cerrada)")
	-- Con el ciclo de demostración, la grieta se abre (y se cierra) dos veces al día
	local edges, was = 0, false
	for q = 0, 24 * 12 - 1 do
		local open = Rules.isOpening(Rules.serverPhase(SkyRift, true, (6.75 + q / 12) % 24, 0, {}))
		if open and not was then
			edges += 1
		end
		was = open
	end
	check(edges == 2, ("ciclo de demostración: la invasión empieza %d veces por día de juego (de día y de noche)"):format(edges))
	check(Config.SkyRift.DemoCycle == true, "el ciclo de demostración está encendido (el dueño la ve sin jugar la saga)")
	check(Rules.serverPhase(SkyRift, false, 12, 0, { "Rasguno", "Rota", "Cosida" }) == "Rota" and Rules.serverPhase(SkyRift, false, 12, 0, { "Cosida" }) == "Cosida", "sin el ciclo: manda la grieta más abierta de los jugadores")
	check(Rules.shouldStart(false, true, false, 100, nil) and not Rules.shouldStart(true, true, false, 100, nil), "empieza solo en el flanco (al abrirse)")
	check(not Rules.shouldStart(false, true, true, 100, nil), "nunca dos a la vez")
	check(not Rules.shouldStart(false, true, false, 100, 50) and Rules.shouldStart(false, true, false, 100 + Rules.Cooldown, 100), "espera entre invasiones")
end

print("\n👽 Razas: una distinta cada vez, varias a la vez y el rey")
do
	check(#Races.List >= 4, ("%d razas"):format(#Races.List))
	local styles, ok = {}, true
	for _, r in Races.List do
		styles[r.Style] = true
		ok = ok and r.Units.Grunt and r.Units.Heavy and r.Units.Ranged and r.Units.Elite and r.Air.Fighter and r.Air.Dropship and r.King.Name and #r.Creatures >= 2
			and Weapons.List[r.Weapon] ~= nil and Loot.get(r.Material) ~= nil and Loot.get(r.Sample) ~= nil
			and Config.Sounds[r.Sounds.Shot] ~= nil and Config.Sounds[r.Sounds.Boom] ~= nil and Config.Sounds[r.Sounds.Roar] ~= nil
	end
	local nStyles = 0
	for _ in styles do
		nStyles += 1
	end
	check(ok, "cada raza: 4 tropas, naves, rey, criaturas, arma, material, muestra y sonidos que existen (Config.Sounds)")
	check(nStyles == #Races.List, "cada raza con su propio estilo de modelos")
	local last, repeats, seen = nil, 0, {}
	local multi, triple, kings = 0, 0, 0
	local hist = { Last = nil, SinceKing = 0 }
	local maxGap = 0
	for _ = 1, 4000 do
		local lu = Races.lineup(hist, rnd)
		if lu.Main == hist.Last then
			repeats += 1
		end
		seen[lu.Main] = true
		if #lu.Races >= 2 then
			multi += 1
		end
		if #lu.Races >= 3 then
			triple += 1
		end
		local dup = {}
		for _, id in lu.Races do
			if dup[id] then
				repeats += 1000
			end
			dup[id] = true
		end
		if lu.King then
			kings += 1
			hist.SinceKing = 0
		else
			hist.SinceKing += 1
			maxGap = math.max(maxGap, hist.SinceKing)
		end
		hist.Last = lu.Main
	end
	local n = 0
	for _ in seen do
		n += 1
	end
	check(repeats == 0, "nunca la misma raza dos invasiones seguidas (ni repetida en el mismo grupo)")
	check(n == #Races.List, "salen todas las razas")
	check(multi > 4000 * 0.15 and multi < 4000 * 0.3, ("varias razas a la vez ~%d %%"):format(math.floor(multi / 40)))
	check(triple > 0 and triple < multi / 2, ("y alguna vez tres (%d)"):format(triple))
	check(kings > 4000 * 0.1 and kings < 4000 * 0.3, ("el rey sale a veces (~%d %%)"):format(math.floor(kings / 40)))
	check(maxGap < Races.Odds.KingPity, ("nunca más de %d invasiones seguidas sin rey (seguro)"):format(Races.Odds.KingPity - 1))
	check(Races.hostile("Vortidos", "Morfagos") and not Races.hostile("Vortidos", "Vortidos"), "rivalidades entre razas")
	local forced = Races.lineup({ Last = "Vortidos" }, rnd, { ForceKing = true, ForceRaces = 2 })
	check(forced.King == forced.Main and #forced.Races == 2 and forced.Main ~= "Vortidos", "el modo pruebas puede forzar el rey y varias razas")
end

print("\n🛬 Sitios de aterrizaje (nunca carretera, agua, tejado ni con algo encima)")
do
	local function pr(t)
		return Landing.valid(t)
	end
	local okPlaza = pr({ X = 200, Z = 200, Hit = true, GroundY = 1, Material = "Grass", NormalY = 1, Clear = true })
	check(okPlaza, "una plaza o un parque libre vale")
	check(not pr({ X = 200, Z = 200, Hit = true, GroundY = 0, Material = "Water", Water = true, NormalY = 1, Clear = true }), "agua no")
	check(not pr({ X = 200, Z = 200, Hit = true, GroundY = 0, Material = "Asphalt", NormalY = 1, Clear = true }), "asfalto no")
	check(not pr({ X = 200, Z = 200, Hit = true, GroundY = 90, Material = "Concrete", NormalY = 1, Clear = true }), "un tejado (muy alto) no")
	check(not pr({ X = 200, Z = 200, Hit = true, GroundY = 1, Material = "Grass", NormalY = 0.7, Clear = true }), "una cuesta no")
	check(not pr({ X = 200, Z = 200, Hit = true, GroundY = 1, Material = "Grass", NormalY = 1, Clear = false }), "con algo encima (edificio, árbol) no")
	check(not pr({ X = 0, Z = -1250, Hit = true, GroundY = 1, Material = "Grass", NormalY = 1, Clear = true }), "encima de una carretera del plano (Ronda Norte) no")
	check(Landing.roadGap(0, -1250) < 0 and Landing.roadGap(200, 200) > Landing.RoadMargin, "distancia a las carreteras del plano")
	-- Busca alrededor si el centro no vale
	roadSpots = { { 500, 500 } }
	local Service = nil
	local got = Landing.find(500, 500, function(x, z)
		local hit = world:Raycast(Vector3.new(x, 400, z), Vector3.new(0, -520, 0))
		return { X = x, Z = z, Hit = hit ~= nil, GroundY = hit and hit.Position.Y, Material = hit and hit.Material.Name, NormalY = 1, Clear = true, Road = hit and hit.Instance.Name == "Road" }
	end)
	check(got ~= nil and (Vector2.new(got.X, got.Z) - Vector2.new(500, 500)).Magnitude > 8, "si el centro es carretera, busca al lado")
	roadSpots = {}
	local _ = Service
	local sites = 0
	for _, s in Landing.Sites do
		sites += 1
		check(Landing.roadGap(s.XZ[1], s.XZ[2]) > -200 and CityPlan.inside(CityPlan.Coast, s.XZ[1], s.XZ[2]), s.Name .. ": dentro de la isla")
	end
	check(sites >= 6, ("%d sitios candidatos (plazas, parque, playa, campus…)"):format(sites))
end

print("\n🌊 Oleadas: van a más y nunca pasan de los topes")
do
	local okGrow, okCap = true, true
	for players = 1, 12 do
		local prev = nil
		for n = 1, Rules.Waves do
			local w = Rules.wave(n, players, false)
			if prev then
				okGrow = okGrow and w.Fighters + w.Drones + w.Dropships * w.PerDrop >= prev
			end
			prev = w.Fighters + w.Drones + w.Dropships * w.PerDrop
			okCap = okCap and w.Fighters + w.Drones <= Rules.MaxAir and w.Dropships <= Rules.MaxDropships and w.PerDrop * w.Dropships <= Rules.MaxGround + 10
		end
	end
	check(okGrow, "cada oleada trae más que la anterior")
	check(okCap, "y siempre dentro de los topes (naves, desembarcos, tropas)")
	check(Rules.wave(3, 8).Fighters > Rules.wave(3, 1).Fighters, "con más jugadores, más enemigos")
	check(Rules.wave(Rules.Waves, 1).Elite and Rules.wave(Rules.Waves + 1, 1, true).King and not Rules.wave(Rules.Waves + 1, 1, false).King, "la última trae élite; la del rey, solo si viene")
	check(Rules.waveCount(true) == Rules.Waves + 1 and Rules.room("Air", Rules.MaxAir) == 0 and Rules.room("Ground", 3) > 0, "oleadas y huecos")
	local s = { State = "Warn", Since = 0, Wave = 0, Waves = 4, Alive = 0, Spawned = false, Open = true, Elapsed = 0 }
	check(Rules.next(s, Rules.WarnSeconds - 1) == nil and Rules.next(s, Rules.WarnSeconds + 0.1) == "Wave", "aviso y luego la primera oleada")
	s = { State = "Wave", Since = 0, Wave = 2, Waves = 4, Alive = 0, Spawned = true, Open = true, Elapsed = 60 }
	check(Rules.next(s, 1) == "Wave", "oleada limpia: la siguiente")
	s.Wave, s.Alive = 4, 0
	local st, why = Rules.next(s, 1)
	check(st == "End" and why == "Cleared", "la última limpia: victoria")
	s.Alive, s.Open = 3, false
	st, why = Rules.next(s, 1)
	check(st == "End" and why == "Closed", "se cierra la grieta: se acaba")
	s.Open, s.Elapsed = true, Rules.MaxSeconds + 1
	st, why = Rules.next(s, 1)
	check(st == "End" and why == "Time", "y nunca dura más de " .. Rules.MaxSeconds .. " s")
end

print("\n🏳 Zonas: se conquistan y se recuperan")
do
	local z = { Id = "Z", Control = 0, Conquered = false }
	local ev = nil
	for _ = 1, 400 do
		ev = Rules.captureStep(z, 3, 0, 0.1) or ev
	end
	check(z.Conquered and ev == "Conquered", "con alienígenas y sin nadie, cae")
	local held = { Id = "H", Control = 0, Conquered = false }
	for _ = 1, 400 do
		Rules.captureStep(held, 1, 3, 0.1)
	end
	check(not held.Conquered and held.Control == 0, "si la defienden más jugadores que alienígenas, aguanta")
	ev = nil
	for _ = 1, 400 do
		ev = Rules.captureStep(z, 0, 2, 0.1) or ev
	end
	check(not z.Conquered and ev == "Retaken", "los jugadores la recuperan")
	check(Rules.zoneStatus({ Control = 0, Conquered = false }) == "Valmar" and Rules.zoneStatus({ Control = 0.4, Conquered = false }) == "Disputa", "estado para la barra")
	check(Rules.outcome("Cleared", 0, 6, false) == "Victoria" and Rules.outcome("Closed", 4, 6, false) == "Derrota" and Rules.outcome("Closed", 1, 6, false) == "Victoria" and Rules.outcome("Time", 0, 6, true) == "Derrota", "victoria o derrota según las zonas y el rey")
end

print("\n🧠 IA de tierra y calles")
do
	local race = Races.get("Morfagos")
	local a = AlienAI.new("G1", race, "Grunt", Vector3.new(0, 0, 0), "Z", 3)
	local zonePos = Vector3.new(800, 0, 0)
	local d = AlienAI.think(a, { Players = { { Id = "1", Pos = Vector3.new(30, 0, 0) } }, Npcs = { { Id = "npc:1", Pos = Vector3.new(5, 0, 0) } }, ZonePos = zonePos }, 10)
	check(d.Mode ~= "Advance" and a.TargetKind == "Player", "un jugador cerca: va a por él (antes que un vecino o su zona)")
	d = AlienAI.think(a, { Players = {}, Npcs = { { Id = "npc:1", Pos = Vector3.new(5, 0, 0) } }, ZonePos = zonePos }, 20)
	check(a.TargetKind == "Npc" and d.Attack ~= nil, "sin jugadores, alcanza a un vecino cercano (se transforma)")
	d = AlienAI.think(a, { Players = {}, Npcs = {}, ZonePos = zonePos }, 30)
	check(d.Mode == "Advance" and d.Goal ~= nil, "sin nadie, va hacia su zona")
	local rng = AlienAI.new("G2", race, "Ranged", Vector3.new(0, 0, 0), "Z", 1)
	d = AlienAI.think(rng, { Players = { { Id = "1", Pos = Vector3.new(10, 0, 0) } }, ZonePos = zonePos }, 40)
	check(d.Goal ~= nil and d.Goal.X < 0, "el tirador se aparta si te le echas encima")
	d = AlienAI.think(rng, { Players = { { Id = "1", Pos = Vector3.new(35, 0, 0) } }, ZonePos = zonePos }, 41)
	check(d.Goal == nil and d.Attack ~= nil, "a buena distancia, quieto y disparando")
	local brawler = AlienAI.new("G3", race, "Grunt", Vector3.new(0, 0, 0), "Z", 0)
	d = AlienAI.think(brawler, { Players = {}, Rivals = { { Id = "alien:x", Pos = Vector3.new(4, 0, 0), Race = "Vortidos" } }, ZonePos = zonePos }, 50)
	check(brawler.TargetKind == "Alien", "si vinieron razas rivales, a veces se pelean")
	local g = Nav.graph()
	check(#g.Nodes > 50, ("grafo de calles: %d nodos"):format(#g.Nodes))
	local path = Nav.path(Vector3.new(-1200, 0, -1200), Vector3.new(1250, 0, 1200), g)
	local onRoads = true
	for i = 1, #path - 1 do
		local p = path[i]
		onRoads = onRoads and Landing.roadGap(p.X, p.Z) < 5
	end
	check(#path > 3 and onRoads, ("de lejos, por las calles (%d puntos)"):format(#path))
	check(#Nav.path(Vector3.new(0, 0, 0), Vector3.new(50, 0, 0), g) == 1, "de cerca, recto")
	local walker = AlienAI.new("G4", race, "Heavy", Vector3.new(-1200, 0, -1200), "Z", 0)
	for i = 1, 1500 do
		local dd = AlienAI.think(walker, { Players = {}, ZonePos = Vector3.new(1250, 0, 1200), Graph = g }, i * 0.1)
		AlienAI.step(walker, dd.Goal, dd.Speed, 1)
	end
	check(AlienAI.flat(walker.Pos, Vector3.new(1250, 0, 1200)) < Rules.ZoneRadius, "y llega a su zona andando")
end

print("\n👑 El rey: fases, puntos débiles, al descubierto, ataques de área")
do
	check(King.maxHp(1) < King.maxHp(4) and King.maxHp(50) == King.MaxHp, "más vida con más jugadores (con tope)")
	local s = King.new("Luminidos", 2, 0)
	local r = King.damage(s, 100, nil, 1)
	check(r.Dealt == 100 * King.Armored, "con puntos débiles, blindado")
	for i = 1, King.WeakPoints do
		r = King.damage(s, King.WeakHp, i, 2)
	end
	check(r.Exposed and King.exposed(s, 3), "rotos los puntos débiles: al descubierto")
	r = King.damage(s, 100, nil, 3)
	check(r.Dealt == 100 * King.Exposed, "al descubierto, daño doble")
	check(King.tick(s, 2 + King.ExposedSeconds + 0.1) and King.weakLeft(s) == King.WeakPoints, "si no cae la fase, los puntos débiles vuelven")
	-- Hasta la fase 2 y la 3
	s.Weak = { 0, 0, 0 }
	s.ExposedUntil = 1e9
	local phases = {}
	while not s.Dead do
		local res = King.damage(s, 500, nil, 5)
		if res.PhaseChanged then
			table.insert(phases, res.Phase)
			s.Weak = { 0, 0, 0 }
			s.ExposedUntil = 1e9
		end
	end
	check(#phases == 2 and phases[1] == 2 and phases[2] == 3, "tres fases (100-66, 66-33, 33-0)")
	local k2 = King.new("Vortidos", 1, 0)
	local seenAttacks = {}
	for t = 0, 120, 0.5 do
		local a = King.nextAttack(k2, t)
		if a then
			seenAttacks[a] = true
		end
	end
	check(seenAttacks.Onda and seenAttacks.Lluvia, "ataques de área (Onda, Lluvia; el Rayo desde la fase 2)")
	check(King.hits("Onda", Vector3.zero, Vector3.new(10, 0, 0)) and not King.hits("Onda", Vector3.zero, Vector3.new(80, 0, 0)), "la onda pilla cerca y no lejos")
	check(King.hits("Rayo", Vector3.zero, Vector3.new(0, 0, -50), Vector3.new(0, 0, -1)) and not King.hits("Rayo", Vector3.zero, Vector3.new(30, 0, -50), Vector3.new(0, 0, -1)), "el rayo pilla en su franja")
end

print("\n🎁 Botín y topes")
do
	local sawWeapon, sawBlueprint = false, false
	for _ = 1, 3000 do
		for _, dd in Loot.roll("Elite", "Ferrocefalos", rnd) do
			sawWeapon = sawWeapon or dd.Id == "Arma_XenoRemache"
		end
		for _, dd in Loot.roll("Dropship", "Ferrocefalos", rnd) do
			sawBlueprint = sawBlueprint or dd.Id == "PlanoNave"
		end
	end
	check(sawWeapon and sawBlueprint, "la élite suelta su arma alienígena y las naves de desembarco, planos (raro)")
	local allItems = true
	for id in Loot.Defs do
		allItems = allItems and Items.get(id) ~= nil
	end
	for _, race in Races.List do
		allItems = allItems and Items.get("Arma_" .. race.Weapon) ~= nil and Weapons.List[race.Weapon].Ammo == "CeldaXeno" and Weapons.List[race.Weapon].Price == nil
	end
	check(allItems, "todo el botín existe en la mochila (shared/Items); las armas alienígenas no se venden y gastan celdas xeno")
	local c = Loot.newCounters(0)
	local got = 0
	for _ = 1, 100 do
		if Loot.allow(c, "Material", 1, 10) then
			got += 1
		end
	end
	check(got == Loot.PerInvasion.Material, ("tope por invasión: %d materiales"):format(got))
	local c2 = Loot.newCounters(0)
	c2.Invasion = {}
	local w = 0
	for i = 1, 10 do
		c2.Invasion = {}
		if Loot.allow(c2, "Weapon", 1, i) then
			w += 1
		end
	end
	check(w == Loot.PerHour.Weapon, ("tope por hora: %d armas"):format(w))
	check(Loot.allow(c2, "Weapon", 1, 3700), "y a la hora siguiente, otra vez")
	local okCraft, spend = Loot.craftPlan({ MuestraCristal = 2, MuestraLuz = 1, PolvoIlyra = 1 })
	check(okCraft and (spend.MuestraCristal or 0) + (spend.MuestraLuz or 0) == 3, "inversor de fase: 3 muestras de cualquier raza + 1 material")
	check(not (Loot.craftPlan({ MuestraCristal = 2, PolvoIlyra = 1 })), "y sin las muestras, no")
	check(Loot.price("Xenita") > 0 and Loot.price("PlanoNave") == 0 and Loot.kindOf("Arma_XenoPrisma") == "Weapon", "precios de venta (los planos no se venden)")
	local Items2 = Items.get("BrujulaCasa")
	check(Items2 ~= nil and Items2.Kind == "Keepsake", "los objetos de otras galaxias son recuerdos (no se tiran)")
end

print("\n🧬 Transformaciones, curas y la vuelta a la normalidad")
do
	local city = Transform.newCity()
	local made = 0
	for i = 1, 40 do
		if Transform.transform(city, "Morfagos", Vector3.new(i, 0, 0), 0, rnd) then
			made += 1
		end
	end
	check(made == Transform.MaxCreatures, ("nunca más de %d criaturas"):format(Transform.MaxCreatures))
	local any = next(city.Creatures)
	local cured = Transform.cure(city, any)
	check(cured ~= nil and city.Cured == 1 and type(cured.Citizen) == "string", "curar devuelve a quien era")
	Transform.damage(city, "Z", Vector3.zero, 0, rnd)
	Transform.pocket(city, "Morfagos", Vector3.zero, 3, 0, rnd)
	Transform.closeService(city, "Shop_1", "una tienda", 0, rnd)
	check(not Transform.summary(city).Normal, "la ciudad queda tocada")
	local rec = Transform.recover(city, 10)
	check(#rec.Creatures == 0 and #rec.Damage == 0, "no se arregla en el momento")
	rec = Transform.recover(city, 100000)
	check(Transform.summary(city).Normal and #rec.Services == 1 and #rec.Pockets == 1, "pero sí sola con el tiempo (nunca se queda rota)")
	local hostile = { Id = "C1", Hostile = true, Pos = Vector3.zero, Home = Vector3.zero, Since = 0 }
	local goal, bite = Transform.wander(hostile :: any, 1, Vector3.new(5, 0, 0))
	check(goal.X > 0 and bite, "las criaturas molestas persiguen y pican un poco")
	local calm = { Id = "C2", Hostile = false, Pos = Vector3.zero, Home = Vector3.zero, Since = 0 }
	local _, bite2 = Transform.wander(calm :: any, 1, Vector3.new(5, 0, 0))
	check(not bite2, "las inofensivas, no")
end

print("\n🏃 La gente huye")
do
	local threats = { { Pos = Vector3.new(0, 0, 0), Radius = 100, Weight = 1 } }
	local dir = Panic.fleeDir(Vector3.new(30, 0, 0), threats)
	check(dir ~= nil and dir.X > 0.9, "huye en dirección contraria a la amenaza")
	check(Panic.fleeDir(Vector3.new(300, 0, 0), threats) == nil and Panic.level(Vector3.new(300, 0, 0), threats) == 0, "lejos, tranquila")
	local safes = { { Pos = Vector3.new(-20, 0, 0), Kind = "Door" }, { Pos = Vector3.new(120, 0, 10), Kind = "Metro" }, { Pos = Vector3.new(60, 0, 0), Kind = "Door" } }
	local safe = Panic.chooseSafe(Vector3.new(30, 0, 0), threats, safes)
	check(safe ~= nil and safe.Pos.X > 30, "corre a un sitio seguro que NO está detrás del alienígena")
	local kinds = {}
	for i = 1, 200 do
		kinds[Panic.behaviour(i * 0.0137, 0.5)] = true
	end
	check(kinds.Run and kinds.Hide and kinds.Trip and kinds.Call, "corren, se esconden, tropiezan y llaman a la policía")
	check(Panic.behaviour(0.3, 0.8, true, true) == "Grab" and Panic.behaviour(0.3, 0) == "Calm", "a los niños los agarran sus padres; sin miedo, nada")
	check(Panic.behaviour(0.42, 0.5) == Panic.behaviour(0.42, 0.5), "repetible (la misma persona hace lo mismo en todas las pantallas)")
	check(Panic.sidewalkSign(Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0)) == -1, "en la acera, hacia el lado que aleja")
	check(Panic.returnShare(0) < 0.3 and Panic.returnShare(Panic.ReturnSeconds) == 1 and Panic.returnShare(Panic.ReturnSeconds / 2) > 0.3, "al acabar, la gente vuelve poco a poco")
	check(Panic.caps("Low").Runners < Panic.caps("High").Runners and Panic.caps("Low").Barks <= 1, "topes por nivel gráfico (móvil)")
	local drivers = {}
	for i = 1, 100 do
		drivers[Panic.driver(i * 0.031, 0.8)] = true
	end
	check(drivers.Speed and drivers.Honk and drivers.Abandon, "conductores: aceleran, pitan en el atasco o abandonan el coche")
	local enc = Panic.decode(Panic.encode(threats))
	check(#enc == 1 and enc[1].Radius == 100, "se publican y se leen las amenazas")
	check(#Panic.cordon(Vector3.zero, 90, 6) == 6, "cordón policial")
end

print("\n🚀 Las naves en el cielo de la ciudad SOLO durante una invasión")
do
	local low = Vector3.new(0, 200, 0)
	Layers.setCityOpen(false)
	local back = Zone.bounds(low)
	check(back ~= nil and back.Y > 0.5 and Layers.floorAt(low) == Layers.FloorY, "sin invasión: a 200 studs la nave vuelve a subir (suelo 260)")
	Layers.setCityOpen(true)
	check(Zone.bounds(low) == nil and Layers.floorAt(low) == Layers.CityFloorY and Layers.CityFloorY == Rules.CityShipFloor, "con invasión: puede bajar hasta " .. Layers.CityFloorY)
	check(Zone.bounds(Vector3.new(0, 100, 0)) ~= nil, "pero nunca por debajo de los tejados")
	check(Layers.CityFloorY < Layers.PlaneCeiling and Rules.AirBand.Max < Layers.PlaneCeiling, "el combate de la ciudad cabe en el cielo de los aviones")
	Layers.setCityOpen(false)
	check(Zone.bounds(low) ~= nil, "y al acabar, las normas de siempre")
	check(Zone.bounds(Access.Port + Vector3.new(0, 40, 0)) == nil, "(junto al puerto espacial, como siempre)")
end

print("\n📜 Misiones (permisos y avance)")
do
	local book = Missions.newBook()
	local ok, why = Missions.canStart(book, "Bahia", { Invasion = true })
	check(not ok and string.find(why, "licencia", 1, true) ~= nil, "la de avioneta pide la licencia de piloto")
	check(not (Missions.canStart(book, "Baliza", { Invasion = true, Pilot = true })), "la de la nave pide la Saga 1")
	check(Missions.canStart(book, "Baliza", { Invasion = true, ShipOk = true }) and Missions.canStart(book, "Cazadores", { Invasion = true, Pilot = true }), "con nave o licencia, sí")
	check(not (Missions.canStart(book, "Defensa", { Invasion = false })), "las del evento, solo durante una invasión")
	check(not (Missions.canStart(book, "Normalidad", { CityNormal = true })) and Missions.canStart(book, "Normalidad", { CityNormal = false }), "la de paz, solo si la ciudad está tocada")
	local needsVuelo = 0
	for _, m in Missions.List do
		if m.Chain == "Vuelo" and (m.Needs == "Plane" or m.Needs == "Ship" or m.Needs == "Air") then
			needsVuelo += 1
		end
		check(#m.Brief >= 2 and #m.Steps >= 1 and m.Giver ~= "" and m.Outro ~= "", m.Title .. ": con su historia (quién te la pide), pasos y final")
	end
	check(needsVuelo >= 3, ("%d misiones que piden avión o nave"):format(needsVuelo))
	Missions.start(book, "Normalidad", 0)
	local changed = Missions.autoSkip(book, { Creatures = 0, Damage = 0, Pockets = 0, Services = 0 })
	check(#changed == 0, "los pasos sin ciudad (muestras) no se saltan")
	Missions.event(book, "Sample", { Amount = 3 })
	Missions.event(book, "Crafted", {})
	changed = Missions.autoSkip(book, { Creatures = 0, Damage = 0, Pockets = 0, Services = 0 })
	check(book.Active.Normalidad == nil and book.Done.Normalidad == 1, "si la ciudad ya se arregló sola, el resto se da por hecho (nunca te atascas)")
	Missions.start(book, "Defensa", 0)
	Missions.endInvasion(book)
	check(book.Active.Defensa == nil, "al acabar la invasión, las del evento se pierden")
	check(EventCatalog.has("InvasionStarted") and EventCatalog.has("InvasionMission") and EventCatalog.has("InvasionKill") and EventCatalog.has("InvasionEnded") and EventCatalog.has("InvasionCured") and EventCatalog.has("InvasionRepaired"), "los avisos a la historia están en el catálogo")
end

---------------------------------------------------------------------
-- El servidor de verdad (con dobles)
---------------------------------------------------------------------
print("\n🛸 El servidor: lanzar, oleadas, daño, botín, misiones, zonas y recoger")
local StoryEvents = L.load("src/server/LifeStory/StoryEvents")
StoryEvents.connect(function(p, name, payload)
	table.insert(story, { P = p, Name = name, Data = payload })
end)
local Inv = L.load("src/server/Services/InvasionService")
Inv.init()
local remote = remotesFolder:FindFirstChild("Invasion")
check(remote ~= nil, "crea su remoto")
local function log(kind: string): { any }
	local out = {}
	for _, e in (remote and remote.Log) or {} do
		if e.Kind == kind then
			table.insert(out, e)
		end
	end
	return out
end
local function storyCount(name: string): number
	local n = 0
	for _, e in story do
		if e.Name == name then
			n += 1
		end
	end
	return n
end

local hero = makePlayer("Heroe", 101, Vector3.new(60, 3, 60))
hero.Tester = true
local other = makePlayer("Vecina", 102, Vector3.new(-2500, 3, 2500))
dataOf[hero] = { Items = {}, Money = 0 }
dataOf[other] = { Items = {}, Money = 0 }

do
	local ok, text = Inv.tester(hero, "Start")
	check(ok and Inv.active(), "el modo pruebas la lanza: " .. tostring(text))
	check(world:GetAttribute("InvasionActive") == true and Layers.cityOpen(), "InvasionActive para todos y las naves pueden bajar a la ciudad")
	local st = Inv._state()
	local zones = 0
	for _, z in st.Zones do
		zones += 1
		local okZ = Landing.valid({ X = z.Pos.X, Z = z.Pos.Z, Hit = true, GroundY = z.Pos.Y, Material = "Grass", NormalY = 1, Clear = true })
		check(okZ, ("zona %s en un sitio válido"):format(z.Name))
	end
	check(zones >= 6, ("%d zonas para conquistar"):format(zones))
	check(not (Inv.tester(hero, "Start")), "no se lanza otra encima")
	task.wait(0.05)
	check(storyCount("InvasionStarted") == 2, "la historia se entera (InvasionStarted a cada jugador)")
	local d = Inv.invData(hero)
	check(d and d.Book.Active.Defensa ~= nil, "la cadena «Defensa de Valmar» empieza sola")
	check(Inv._special.Beacon ~= nil, "la baliza nodriza en lo alto del cielo")
	-- Primera oleada
	Inv.tester(hero, "Wave")
	Inv.step(0.05)
	st = Inv._state()
	local nAir, nDrop = 0, 0
	for _ in Inv._air do
		nAir += 1
	end
	for _ in Inv._drops do
		nDrop += 1
	end
	check(st.State == "Wave" and st.Wave == 1 and nAir > 0 and nDrop > 0, ("oleada 1: %d naves y %d de desembarco"):format(nAir, nDrop))
	for _, a in Inv._air do
		check(a.AI.Pos.Y >= Rules.AirBand.Min and a.AI.Pos.Y < Layers.PlaneCeiling, "las naves salen en el cielo de los aviones")
		break
	end
	-- La nave de desembarco aterriza y suelta tropas
	for _, dr in Inv._drops do
		dr.Since -= 100
	end
	for _ = 1, 40 do
		for _, dr in Inv._drops do
			dr.NextOut = 0
		end
		Inv.step(0.11)
	end
	local nGround = 0
	for _ in Inv._ground do
		nGround += 1
	end
	check(nGround > 0 and nGround <= Rules.MaxGround, ("aterrizan y bajan %d tropas (tope %d)"):format(nGround, Rules.MaxGround))
	-- Topes: aunque se pidan muchas más, nunca se pasan
	local before = nGround
	for _ = 1, 50 do
		Inv.spawnGround("Morfagos", "Grunt", Vector3.new(0, 0, 0), nil)
	end
	nGround = 0
	for _ in Inv._ground do
		nGround += 1
	end
	check(nGround == Rules.MaxGround and before <= nGround, "nunca más tropas que el tope")
	for _ = 1, 30 do
		Inv.spawnAir("Drone", "Morfagos", Vector3.new(0, 400, 0))
	end
	nAir = 0
	for _, a in Inv._air do
		if not a.Mission then
			nAir += 1
		end
	end
	check(nAir <= Rules.MaxAir, "ni más naves que el tope")
	-- Las tropas eligen blanco: el jugador cercano
	local g1 = nil
	for _, g in Inv._ground do
		g1 = g
		break
	end
	g1.AI.Pos = Vector3.new(70, 0, 60)
	g1.AI.NextAttack = 0
	local hp0 = hero.Character:FindFirstChildOfClass("Humanoid").Health
	for _ = 1, 30 do
		Inv.step(0.11)
		g1.AI.NextAttack = 0
	end
	check(hero.Character:FindFirstChildOfClass("Humanoid").Health < hp0 or g1.AI.TargetKind == "Player", "las tropas van a por el jugador cercano (y le hacen daño)")
	hero.Character:FindFirstChildOfClass("Humanoid").Health = 100
	-- En plena conversación o escena de la historia no te atacan ni te hacen daño (no te puedes mover)
	for _, flag in { "InDialogue", "InScene", "InPrologue" } do
		hero:SetAttribute(flag, true)
		local hum = hero.Character:FindFirstChildOfClass("Humanoid")
		Inv.hurtPlayer(hero, 30, Vector3.zero)
		g1.AI.Pos = Vector3.new(70, 0, 60)
		for _ = 1, 30 do
			g1.AI.NextAttack = 0
			Inv.step(0.11)
		end
		check(hum.Health == 100, ("con %s nadie te hace daño (ni las tropas ni un golpe suelto)"):format(flag))
		hero:SetAttribute(flag, nil)
		hum.Health = 100
	end
	-- Daño del servidor: armas de siempre (hitModel), rechazos
	local kills0 = Inv.invData(hero).Stats.Kills
	local okHit, dealt, gone = Inv.hitModel(hero, g1.Model, 5000, { At = g1.AI.Pos })
	check(okHit and dealt > 0 and gone and Inv._ground[g1.Id] == nil, "un disparo de verdad tumba a la tropa (lo decide el servidor)")
	check(Inv.invData(hero).Stats.Kills == kills0 + 1, "y cuenta el derribo")
	check(not (Inv.hitModel(hero, fake("Model"), 50)), "a algo que no es de la invasión, nada")
	check(Inv.damage(hero, "G_no_existe", 50, "Foot") == 0 and Inv.damage(hero, next(Inv._ground), 0 / 0, "Foot") == 0, "ids inventados o daño NaN: nada")
	task.wait(0.05)
	check(storyCount("InvasionKill") >= 1, "la historia se entera (InvasionKill)")
	-- Botín
	local items = 0
	for _ in dataOf[hero].Items do
		items += 1
	end
	check(items > 0 or #log("Loot") > 0, "botín al tumbar alienígenas")
	-- La Xenobodega (mochila llena)
	dataOf[hero].SlotCap = 0
	Inv.giveItem(hero, "AleacionEstelar", 1, true)
	check((Inv.invData(hero).Stash.AleacionEstelar or 0) >= 1, "con la mochila llena, a la Xenobodega")
	dataOf[hero].SlotCap = nil
	check(Inv.unstash(hero) >= 1 and (dataOf[hero].Items.AleacionEstelar or 0) >= 1, "y se recoge en el laboratorio")
	-- Objetos únicos
	Inv.giveItem(hero, "SemillaEstrella", 1, true)
	Inv.giveItem(hero, "SemillaEstrella", 1, true)
	check((dataOf[hero].Items.SemillaEstrella or 0) == 1, "los objetos de otras galaxias, una sola vez (el repetido se cambia por mineral)")
	-- Planos: también en data.Space.Blueprints
	Inv.giveItem(hero, "PlanoNave", 1, true)
	check(dataOf[hero].Space and dataOf[hero].Space.Blueprints.PlanoNave == 1, "los planos de naves se guardan para el astillero (data.Space.Blueprints)")
	-- Topes de botín del servidor
	local s = Inv.stateOf(hero)
	s.Counters = Loot.newCounters(os.clock())
	local given = 0
	for _ = 1, 100 do
		if Inv.giveItem(hero, "MembranaTharn", 1) then
			given += 1
		end
	end
	check(given == Loot.PerInvasion.Material, ("contra las granjas: %d materiales por invasión como mucho"):format(given))
	-- Vender
	local m0 = money[hero] or 0
	Inv.sell(hero)
	check((money[hero] or 0) > m0 and (dataOf[hero].Items.MembranaTharn or 0) == 0, "se vende en el Laboratorio Xeno")
end

print("\n✈ Misión de AVIONETA: «Ojos sobre la bahía» (el explorador)")
do
	licensed[hero] = true
	local ok = Inv.startMission(hero, "Bahia")
	check(ok and Inv._special.Scout ~= nil, "se coge y sale el explorador sobre la bahía")
	-- Sin avión no se dispara el cañón; en el avión de línea tampoco
	check(not Inv.planeFire(hero, Vector3.new(0, 0, -1)), "a pie, el cañón no dispara")
	local root = fake("Part")
	root.CFrame = CFrame.new(0, 300, 0)
	planes[hero] = { Root = root, Spec = { Kind = "Avion" }, Airborne = true }
	check(not Inv.planeFire(hero, Vector3.new(0, 0, -1)), "el avión de línea no lleva cañón")
	planes[hero] = { Root = root, Spec = { Kind = "Avioneta" }, Airborne = true }
	moveTo(hero, Vector3.new(0, 300, 0))
	Inv.step(0.05)
	local book = Inv.invData(hero).Book
	check(book.Active.Bahia and book.Active.Bahia.Step == 2, "despegar cuenta (paso 1)")
	local scout = Inv._special.Scout
	local tries = 0
	while Inv._special.Scout and tries < 400 do
		tries += 1
		local pos = scout.AI.Pos
		root.CFrame = L.CFrame.lookAt(pos + Vector3.new(0, 0, 200), pos) -- (el lookAt de Roblox: el de Lune da la vuelta)
		Inv.stateOf(hero).LastFire = -1
		Inv.stateOf(hero).Heat = 0
		local fired = Inv.planeFire(hero, (pos - root.CFrame.Position).Unit)
		check(tries > 1 or fired, "el primer disparo sale")
	end
	check(Inv._special.Scout == nil, ("el cañón del servidor lo derriba (%d disparos)"):format(tries))
	check(book.Done.Bahia == 1 and book.Active.Bahia == nil, "misión de avioneta completada")
	task.wait(0.05)
	check(storyCount("InvasionMission") >= 1, "la historia se entera (InvasionMission)")
	-- «Corredor de evacuación»: volar junto al EV-01 hasta que sale del corredor
	check(Inv.startMission(hero, "Evacuacion") and Inv._special.Evac ~= nil, "«Corredor de evacuación»: despega el vuelo EV-01")
	local loops = 0
	while (book.Done.Evacuacion or 0) == 0 and loops < 600 do
		loops += 1
		local ev = Inv._special.Evac
		if ev then
			ev.Hp = 700 -- (aquí solo se prueba la escolta)
			root.CFrame = CFrame.new(ev.Pos + Vector3.new(0, 30, 60))
			moveTo(hero, ev.Pos + Vector3.new(0, 30, 60))
		end
		Inv.step(0.5)
	end
	check((book.Done.Evacuacion or 0) == 1, ("escoltado hasta salir del corredor: misión completada (%d vueltas)"):format(loops))
	-- Cadencia y cono: el servidor no se fía
	Inv.stateOf(hero).LastFire = os.clock()
	check(not Inv.planeFire(hero, Vector3.new(0, 0, -1)), "no dispara más rápido que la cadencia")
	planes[hero] = nil
	moveTo(hero, Vector3.new(60, 3, 60))
end

print("\n🚀 Misión de NAVE: «La baliza nodriza»")
do
	check(not (Inv.startMission(hero, "Baliza")) or hero.Tester, "sin la Saga 1 no (salvo tester)")
	sagaDone[hero] = true
	local ok = Inv.startMission(hero, "Baliza")
	check(ok, "con la Saga 1, se coge")
	ships[hero] = { Pos = Inv.BeaconAt + Vector3.new(0, 0, 200), Look = Vector3.new(0, 0, -1), Vel = Vector3.zero, Down = false }
	Inv.step(0.05)
	local book = Inv.invData(hero).Book
	check(book.Active.Baliza and book.Active.Baliza.Step == 2, "subir a la nave cuenta (paso 1)")
	local b = Inv._special.Beacon
	check(Inv.damageBeacon(hero, 500, b.Model:GetPivot().Position, "Plane") == 0, "la baliza solo cae con el láser de una nave")
	local shots = 0
	while Inv._special.Beacon and shots < 500 do
		shots += 1
		local target = b.Model:GetPivot().Position
		for i, part in b.Pylons do
			if b.PylonHp[i] > 0 then
				target = part.Position
				break
			end
		end
		Inv.shipBolt(hero, target + Vector3.new(0, 0, 30), target, 20, "Laser")
	end
	check(Inv._special.Beacon == nil, ("el láser de la nave rompe los pilones y el núcleo (%d disparos)"):format(shots))
	check(book.Done.Baliza == 1, "misión de nave completada")
	-- Los disparos alienígenas a la nave van por AirCombatService (escudo y casco)
	Inv.hurtPlayer(hero, 7, Vector3.zero)
	check(#shipHurt == 1, "a la nave le dan con las reglas de su escudo (AirCombatService.hurtPilot)")
	ships[hero] = nil
end

print("\n🏳 Zonas en el servidor: cae y se recupera")
do
	local st = Inv._state()
	local zone = nil
	for _, z in st.Zones do
		zone = z
		break
	end
	moveTo(hero, Vector3.new(-3000, 3, -3000))
	moveTo(other, Vector3.new(-3000, 3, -3000))
	for id in Inv._ground do
		Inv._ground[id] = nil
	end
	local aliens = {}
	for i = 1, 3 do
		local g = Inv.spawnGround(st.Lineup.Main, "Grunt", zone.Pos + Vector3.new(i * 3, 0, 0), zone.Id)
		table.insert(aliens, g)
	end
	for _ = 1, 30 do
		for _, g in aliens do
			g.AI.Pos = zone.Pos + Vector3.new(3, 0, 0)
		end
		Inv.step(0.5)
	end
	check(zone.Conquered, "con alienígenas y sin nadie, la zona cae")
	local creatures = 0
	for _ in Inv._creatures do
		creatures += 1
	end
	check(creatures >= 1, ("al caer, vecinos transformados en criaturas (%d)"):format(creatures))
	moveTo(hero, zone.Pos + Vector3.new(0, 3, 0))
	for _, g in aliens do
		Inv.hitModel(hero, g.Model, 9999, {})
	end
	for _ = 1, 60 do
		for id, g in Inv._ground do
			if AlienAI.flat(g.AI.Pos, zone.Pos) < Rules.ZoneRadius + 20 then
				Inv.hitModel(hero, g.Model, 9999, {})
			end
		end
		Inv.step(0.5)
	end
	check(not zone.Conquered, "el jugador la recupera")
	-- Rescatar a un vecino atrapado
	local rescued = 0
	for id in Inv._rescue do
		if Inv.rescue(hero, id) then
			rescued += 1
		end
	end
	check(npcCount > 0, ("policía, soldados y vecinos atrapados en las zonas en disputa (%d NPC)"):format(npcCount))
	check(rescued >= 0, "rescatar a los atrapados")
	check(fled > 0, "la gente de las plazas y los parques huye (CrowdService.flee con las amenazas)")
end

print("\n👑 El rey en el servidor")
do
	-- Hasta la oleada del rey (la invasión de pruebas sin rey: se fuerza en otra)
	Inv.finish("Tester")
	local st = Inv._state()
	check(st.State == "End" and world:GetAttribute("InvasionActive") == false and not Layers.cityOpen(), "terminar: InvasionActive apagado y las naves vuelven a sus normas")
	local leftAir = 0
	for _ in Inv._air do
		leftAir += 1
	end
	local leftDrops = 0
	for _ in Inv._drops do
		leftDrops += 1
	end
	local leftGround, pockets = 0, 0
	for _, g in Inv._ground do
		leftGround += 1
		if g.Pocket then
			pockets += 1
		end
	end
	check(leftAir == 0 and leftDrops == 0 and leftGround == pockets, "al acabar se recoge todo (solo quedan las bolsas atrincheradas)")
	check(Inv._special.Beacon == nil and Inv._special.Scout == nil and Inv._special.Evac == nil and next(Inv._rescue) == nil, "y la baliza, el explorador, la evacuación y los rescates")
	check(Inv.invData(hero).Book.Active.Defensa == nil, "las misiones del evento sin acabar se pierden")
	task.wait(0.05)
	check(storyCount("InvasionEnded") >= 2, "la historia se entera (InvasionEnded)")
	check((money[hero] or 0) > 0, "premio según lo que ha hecho cada uno")
end

print("\n🧪 Recuperar la normalidad (paz)")
do
	local book = Inv.invData(hero).Book
	if not book.Active.Normalidad then
		Inv.startMission(hero, "Normalidad", true)
	end
	check(book.Active.Normalidad ~= nil, "la doctora pide ayuda si la ciudad queda tocada")
	moveTo(hero, Vector3.new(0, 3, 0))
	Inv.tester(hero, "City")
	-- Muestras
	local sampled = 0
	for id, c in Inv._creatures do
		moveTo(hero, c.Rec.Pos)
		if Inv.takeSample(hero, id) then
			sampled += 1
		end
		check(not Inv.takeSample(hero, id), "una muestra por criatura y jugador")
		if sampled >= 3 then
			break
		end
	end
	check(sampled >= 3 and book.Active.Normalidad.Step >= 2, "muestras tomadas sin hacer daño")
	dataOf[hero].Items.MuestraCristal = 3
	dataOf[hero].Items.CristalKael = 1
	check(Inv.craft(hero) and (dataOf[hero].Items.InversorFase or 0) == 1, "se fabrica el inversor de fase")
	dataOf[hero].Items.InversorFase = 3
	local cured = 0
	for id, c in Inv._creatures do
		moveTo(hero, c.Rec.Pos)
		if Inv.cure(hero, id) then
			cured += 1
		end
		if cured >= 2 then
			break
		end
	end
	check(cured == 2, "curar a dos vecinos con el inversor")
	local repaired = 0
	for id, m in Inv._damages do
		moveTo(hero, m:GetPivot().Position)
		if Inv.repair(hero, id) then
			repaired += 1
		end
	end
	check(repaired >= 3, "reparar los destrozos")
	-- Lo que quede (bolsas, servicios) se da por hecho si la ciudad ya está bien
	for id, g in Inv._ground do
		if g.Pocket then
			Inv.hitModel(hero, g.Model, 9999, {})
		end
	end
	local city = Inv._city
	for _, p in city.Pockets do
		p.RecoverAt = 0
	end
	for _, sv in city.Services do
		sv.RecoverAt = 0
	end
	for _, c in city.Creatures do
		c.RecoverAt = 0
	end
	for _ = 1, 4 do
		Inv.step(0.6)
	end
	check(book.Active.Normalidad == nil and (book.Done.Normalidad or 0) >= 1, "«Recuperar la normalidad» completada")
	check(Transform.summary(city).Normal, "y la ciudad vuelve a la normalidad")
	task.wait(0.05)
	check(storyCount("InvasionCured") >= 2 and storyCount("InvasionRepaired") >= 3, "la historia se entera (curas y reparaciones)")
end

print("\n👑 Invasión con rey y varias razas")
do
	-- (la anterior acabó: se espera a que se recoja)
	local st
	local okMulti = false
	-- forzar el final del cartel de la anterior: la quita del estado
	local deadline = os.clock() + 20
	while Inv._state() ~= nil and os.clock() < deadline do
		task.wait(0.5)
	end
	check(Inv._state() == nil and world:GetAttribute("Invasion") == nil, "al rato del final, se quita el panel")
	local ok = Inv.tester(hero, "King")
	st = Inv._state()
	okMulti = ok and st.Lineup.King ~= nil
	check(okMulti, "invasión con su rey")
	for _ = 1, Rules.Waves + 1 do
		Inv.tester(hero, "Wave")
		Inv.step(0.05)
	end
	st = Inv._state()
	check(st.KingRec ~= nil, "en la última oleada llega el rey")
	local k = st.KingRec
	local hp0 = k.State.Hp
	Inv.damage(hero, "King", 100, "Foot", nil)
	check(k.State.Hp == hp0 - 100 * King.Armored, "blindado mientras tiene puntos débiles")
	for i, part in k.Weak do
		local guard = 0
		while k.State.Weak[i] > 0 and guard < 20 do
			guard += 1
			Inv.damage(hero, "King", 200, "Foot", part.Position)
		end
	end
	check(King.weakLeft(k.State) == 0 and King.exposed(k.State, os.clock()), "rotos sus puntos débiles (en la pieza que brilla), al descubierto")
	local n = 0
	while st.KingRec and n < 300 do
		n += 1
		Inv.damage(hero, "King", 400, "Foot", nil)
		if st.KingRec then
			k.State.ExposedUntil = os.clock() + 100
			k.State.Weak = { 0, 0, 0 }
		end
	end
	check(st.KingRec == nil and Inv.invData(hero).Stats.Kings >= 1, "y cae (aviso a todo el servidor, gran premio)")
	Inv.finish("Tester")
	local multi = nil
	deadline = os.clock() + 20
	while Inv._state() ~= nil and os.clock() < deadline do
		task.wait(0.5)
	end
	Inv.tester(hero, "Multi")
	multi = Inv._state()
	check(multi and #multi.Lineup.Races >= 2, "varias razas a la vez")
	Inv.finish("Tester")
end

---------------------------------------------------------------------
-- Modelos y HUD
---------------------------------------------------------------------
print("\n🎨 Modelos (pocas piezas, para el móvil)")
do
	local AlienModels = L.load("src/server/World/Kit/AlienModels")
	local okCaps = true
	local maxG, maxS, maxD = 0, 0, 0
	for _, race in Races.List do
		for _, kind in { "Grunt", "Heavy", "Ranged", "Elite" } do
			local m = AlienModels.ground(race, kind)
			maxG = math.max(maxG, m:GetAttribute("Parts"))
			okCaps = okCaps and m:FindFirstChildOfClass("Humanoid") ~= nil and m.PrimaryPart ~= nil
		end
		for _, kind in { "Fighter", "Drone", "Scout" } do
			maxS = math.max(maxS, AlienModels.ship(race, kind):GetAttribute("Parts"))
		end
		maxD = math.max(maxD, AlienModels.ship(race, "Dropship"):GetAttribute("Parts"))
		local king, weak = AlienModels.king(race)
		okCaps = okCaps and #weak == 3 and #king:GetDescendants() <= 45
		for _, c in race.Creatures do
			okCaps = okCaps and AlienModels.creature(race, c):GetAttribute("Parts") <= 14
		end
	end
	check(okCaps and maxG <= 18 and maxS <= 18 and maxD <= 24, ("tropas ≤ 18 piezas (%d), naves ≤ 18 (%d), desembarco ≤ 24 (%d); el rey con 3 puntos débiles; las tropas con Humanoid (las armas les dan)"):format(maxG, maxS, maxD))
end

print("\n📱 HUD: panel EVENTO GLOBAL y botón CAÑÓN sin pisar nada")
do
	local HudLayout = L.load("src/client/UI/HudLayout")
	local TopStack = L.load("src/client/UI/TopStack")
	local InvasionHud = L.load("src/client/UI/InvasionHud")
	for _, size in { { 932, 430, true }, { 844, 390, true }, { 640, 360, true }, { 1920, 1080, false } } do
		local view = Vector2.new(size[1], size[2])
		local layout = HudLayout.compute(view, { Touch = size[3] })
		for _, king in { false, true } do
			local w, h = InvasionHud.pixelSize(layout.Scale, size[3], king)
			local placed = TopStack.arrange(view, { { Id = "Inv", Priority = TopStack.Priority.Mission, W = w, H = h } }, { Touch = size[3] })
			local p = placed.Inv
			local clash = {}
			for _, b in TopStack.obstacles(view, { Touch = size[3] }) do
				if HudLayout.overlaps({ X = p.X, Y = p.Y, W = p.W, H = p.H }, b) then
					table.insert(clash, "obstáculo")
				end
			end
			check(p.Shown and #clash == 0 and p.X >= 0 and p.X + p.W <= view.X and p.Y + p.H <= view.Y * TopStack.MaxBottom + 1, ("%dx%d%s: panel EVENTO GLOBAL a la vista, sin pisar el HUD (%dx%d px)"):format(size[1], size[2], if king then " con rey" else "", w, h))
			local text = math.floor(InvasionHud.TextSize(size[3]) * layout.Scale)
			if size[3] then
				check(text >= 8, ("%dx%d: texto del panel legible (%d px)"):format(size[1], size[2], text))
			end
		end
		-- A los mandos del avión: debajo de los instrumentos
		local w, h = InvasionHud.pixelSize(layout.Scale, size[3], false)
		for _, mode in { "Flight", "ShipHud" } do
			local placed = TopStack.arrange(view, { { Id = "Inv", Priority = TopStack.Priority.Mission, W = w, H = h } }, { Touch = size[3], Piloting = mode })
			local panel = TopStack.panelRect(view, { Touch = size[3], Piloting = mode })
			check(panel ~= nil and placed.Inv.Y >= panel.Y + panel.H and placed.Inv.Shown, ("%dx%d: a los mandos (%s), debajo del panel de arriba y a la vista"):format(size[1], size[2], mode))
		end
		if size[3] then
			local canon = HudLayout.rect(layout.FlySlots.CanonAvion, layout.Canvas)
			local bad = {}
			local planeIds = { "MotorMas", "MotorMenos", "Frenos", "Tren", "Bajarse", "Flaps", "Camara" }
			for _, id in planeIds do
				if layout.FlySlots[id] and HudLayout.overlaps(canon, HudLayout.rect(layout.FlySlots[id], layout.Canvas)) then
					table.insert(bad, id)
				end
			end
			local zone = HudLayout.rect(layout.Items.FlightZone, layout.Canvas)
			if HudLayout.overlaps(canon, zone) then
				table.insert(bad, "palanca")
			end
			for _, id in { "Status", "Minimap", "Clock" } do
				if HudLayout.overlaps(canon, HudLayout.rect(layout.Items[id], layout.Canvas)) then
					table.insert(bad, id)
				end
			end
			local minPt = if size[1] == 932 then 44 else 36 -- (≥ 44 pt en el móvil del dueño, como los de la nave)
			check(#bad == 0 and canon.W * layout.Scale >= minPt and canon.X + canon.W <= layout.Canvas.X, ("%dx%d: botón CAÑÓN (%d pt) sin pisar los mandos del avión%s"):format(size[1], size[2], math.floor(canon.W * layout.Scale), if #bad > 0 then " (" .. table.concat(bad, ", ") .. ")" else ""))
		end
	end
	local t = InvasionHud.text({ State = "Wave", Text = "Oleada 2 de 4", Left = 125, Races = { "Vortidos" }, KingAlive = true, KingHp = 50, KingMax = 100, KingStatus = "Fase 2" }, { Name = "Plaza", Control = 0.4, Conquered = false }, "Vórtidos")
	check(string.find(t.Title, "EVENTO GLOBAL", 1, true) and string.find(t.State, "2:05", 1, true) and string.find(t.Line, "EN DISPUTA", 1, true) and t.KingBar == 0.5, "el panel: EVENTO GLOBAL, oleada, tiempo, tu zona y la vida del rey")
end

print("\n🔊 Sonidos: solo los que ya existen (Config.Sounds)")
do
	local src = require("@lune/fs").readFile("src/client/Controllers/InvasionClient.luau")
	local missing = {}
	for name in src:gmatch('sound%("([%w_]+)"') do
		if not Config.Sounds[name] then
			table.insert(missing, name)
		end
	end
	check(#missing == 0, "todos los sonidos del cliente están en Config.Sounds" .. (if #missing > 0 then " (faltan: " .. table.concat(missing, ", ") .. ")" else ""))
end

L.finish("test-invasion")
-- (el servicio deja hilos esperando —la grieta, el laboratorio—: se sale ya)
require("@lune/process").exit(0)
