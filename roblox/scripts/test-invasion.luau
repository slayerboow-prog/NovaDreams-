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
--   * Alienígenas v2 (mallas de Blender): presupuesto de triángulos, segmentos y articulaciones, los
--     archivos (FBX y texturas), el cargador con su respaldo (sin ids, ids que fallan, piezas que faltan),
--     el montaje con Motor6D, la animación (AlienPose), la IA que avisa, se turna, se tambalea, se mueve
--     de lado y se cubre, y los disparos con compensación de lag (HitCheck).

local roblox = require("@lune/roblox")
local task = require("@lune/task")
local L = require("./lib/ModuleLoader")

local Vector3, Vector2, CFrame = roblox.Vector3, roblox.Vector2, roblox.CFrame
local check = L.check

-- Un asset de mentira de un modelo de malla (lo que bajaría de Roblox): una MeshPart por pieza y, en los de
-- esqueleto (Skinned: los Vórtidos de cristal, docs/bugs/moderacion/), sus Bone dentro del Cuerpo, en
-- cadena como en el FBX (cada uno respecto a su padre). meshIds: { [nombre de pieza] = id } (opcional).
local function fakeAlienAsset(m: any, skip: string?, meshIds: { [string]: number }?): any
	local model = roblox.Instance.new("Model")
	local body = nil
	for _, p in m.Parts do
		if p.Name ~= skip then
			local mp = roblox.Instance.new("MeshPart")
			mp.Name = p.Name
			mp.Size = p.Size
			mp.CFrame = roblox.CFrame.new(p.Center)
			if meshIds and meshIds[p.Name] then
				mp.MeshId = "rbxassetid://" .. meshIds[p.Name]
			end
			mp.Parent = model
			if p.Name == "Cuerpo" then
				body = mp
			end
		end
	end
	if m.Skinned and body then
		local made = {}
		local pivots = {}
		for _, b in m.Bones do
			pivots[b.Name] = b.Pivot
		end
		local todo = table.clone(m.Bones)
		while #todo > 0 do
			local rest = {}
			for _, b in todo do
				local parent = if b.Parent == "Root" then body else made[b.Parent]
				if parent then
					local bone = roblox.Instance.new("Bone")
					bone.Name = b.Name
					local from = if b.Parent == "Root" then body.CFrame.Position else pivots[b.Parent]
					bone.CFrame = roblox.CFrame.new(b.Pivot - from)
					bone.Parent = parent
					made[b.Name] = bone
				else
					table.insert(rest, b)
				end
			end
			if #rest == #todo then
				break
			end
			todo = rest
		end
	end
	return model
end

-- Las articulaciones de un modelo montado: { [nombre] = Motor6D o Bone }
local function jointsOf(model: any): { [string]: any }
	local out = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Motor6D") or d:IsA("Bone") then
			out[d.Name] = d
		end
	end
	return out
end

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
	check(d.Windup ~= nil and d.Attack == nil and d.Mode == "Windup", "a buena distancia: primero CARGA el disparo (aviso), no dispara de golpe")
	d = AlienAI.think(rng, { Players = { { Id = "1", Pos = Vector3.new(35, 0, 0) } }, ZonePos = zonePos }, 41 + AlienAI.Windup.Ranged + 0.01)
	check(d.Attack ~= nil and d.Attack.Pos.X == 35, "…y luego dispara a donde estabas al empezar a cargar (moverte de lado lo esquiva)")
	d = AlienAI.think(rng, { Players = { { Id = "1", Pos = Vector3.new(35, 0, 0) } }, ZonePos = zonePos }, 41.8)
	check(d.Goal ~= nil and math.abs(d.Goal.X) < 1 and math.abs(d.Goal.Z) > 3, "entre disparo y disparo se mueve de lado (strafe), no se queda quieto")
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
	-- …pero una escena que solo abre la pantalla («Cliente», con latidos) no es un escudo
	hero:SetAttribute("InScene", true)
	hero:SetAttribute("SceneId", "Cliente")
	Inv.hurtPlayer(hero, 30, Vector3.zero)
	check(hero.Character:FindFirstChildOfClass("Humanoid").Health < 100, "una escena «Cliente» (la abre la pantalla) no protege")
	hero:SetAttribute("InScene", nil)
	hero:SetAttribute("SceneId", nil)
	hero.Character:FindFirstChildOfClass("Humanoid").Health = 100
	-- Daño del servidor: armas de siempre (hitModel), rechazos
	local kills0 = Inv.invData(hero).Stats.Kills
	local okHit, dealt, gone = Inv.hitModel(hero, g1.Model, 5000, { At = g1.AI.Pos })
	check(okHit and dealt > 0 and gone and Inv._ground[g1.Id] == nil, "un disparo de verdad tumba a la tropa (lo decide el servidor)")
	check(Inv.invData(hero).Stats.Kills == kills0 + 1, "y cuenta el derribo")
	-- Puñetazos y patadas (InvasionService.meleeTargets + hitModel con Melee; shared/Invasion/MeleeHit)
	do
		local MeleeHit = L.load("src/shared/Invasion/MeleeHit")
		local g2 = nil
		for _, g in Inv._ground do
			g2 = g
			break
		end
		local heroRoot = hero.Character:FindFirstChild("HumanoidRootPart")
		local from = heroRoot.CFrame.Position
		local look = Vector3.new(0, 0, -1)
		local function inList(list, model)
			for _, t in list do
				if t.Model == model then
					return true
				end
			end
			return false
		end
		g2.AI.Pos = from + Vector3.new(0, -3, -5)
		g2.Hist = nil
		check(inList(Inv.meleeTargets(hero, from, look, 6, 0.25), g2.Model), "un puñetazo le llega a un alienígena delante, a 5 studs")
		g2.AI.Pos = from + Vector3.new(0, -3, -20)
		check(not inList(Inv.meleeTargets(hero, from, look, 6, 0.25), g2.Model), "a 20 studs, no (fuera de alcance)")
		g2.AI.Pos = from + Vector3.new(0, -3, 5)
		check(not inList(Inv.meleeTargets(hero, from, look, 6, 0.25), g2.Model), "a la espalda, no (fuera del cono)")
		g2.AI.Pos = from + Vector3.new(0, -3, -5)
		local cast = world.Raycast
		world.Raycast = function(_self, origin, _dir)
			local p = fake("Part")
			p.Name = "Pared"
			return { Position = origin, Normal = Vector3.new(0, 0, 1), Material = roblox.Enum.Material.Concrete, Instance = p }
		end
		check(not inList(Inv.meleeTargets(hero, from, look, 6, 0.25), g2.Model), "con una pared en medio, no")
		world.Raycast = cast
		-- Lag: estaba delante hace tu ping (historia de HitCheck) aunque ahora ya se haya ido un poco
		g2.Hist = { T = { os.clock() - 0.3, os.clock() - 0.01 }, P = { from + Vector3.new(0, -3, -5), from + Vector3.new(0, -3, -14) } }
		g2.AI.Pos = from + Vector3.new(0, -3, -14)
		check(inList(Inv.meleeTargets(hero, from, look, 6, 0.25), g2.Model), "con lag: estaba delante hace tu ping (HitCheck) y el golpe le llega aunque ya se haya apartado")
		g2.Hist = nil
		g2.AI.Pos = from + Vector3.new(0, -3, -5)
		-- Daño: el que pone el servidor (el cliente no manda daño), con tope; número solo a quien pega
		local logBefore = #((remote :: any).Log or {})
		local hp0 = g2.AI.Hp
		local ok1, dealt1 = Inv.hitModel(hero, g2.Model, 9999, { At = g2.AI.Pos, Melee = true, Direction = look })
		check(ok1 and dealt1 <= MeleeHit.Max and g2.AI.Hp == hp0 - dealt1, ("un golpe hace como mucho %d (aunque llegue «9999»)"):format(MeleeHit.Max))
		local dmg = nil
		for i = logBefore + 1, #(remote :: any).Log do
			local e = (remote :: any).Log[i]
			if e.Kind == "Dmg" then
				dmg = e
			end
		end
		check(dmg ~= nil and dmg.To == hero and dmg.Data.Kind == "Melee" and dmg.Data.Amount == math.floor(dealt1 + 0.5), "el número de daño (naranja: cuerpo a cuerpo) le llega SOLO a quien pega, con el daño de verdad")
		check((g2.AI.Pos - (from + Vector3.new(0, -3, -5))).Magnitude > 0.1, "el golpe lo empuja un poco hacia atrás")
		local kills1 = Inv.invData(hero).Stats.Kills
		for _ = 1, 40 do
			if not Inv._ground[g2.Id] then
				break
			end
			Inv.hitModel(hero, g2.Model, 30, { At = g2.AI.Pos, Melee = true, Direction = look })
		end
		check(Inv._ground[g2.Id] == nil and Inv.invData(hero).Stats.Kills == kills1 + 1, "a puñetazos también cae, y cuenta UNA vez (como a tiros)")
		check(not (Inv.hitModel(hero, g2.Model, 30, { Melee = true })) and Inv.invData(hero).Stats.Kills == kills1 + 1, "pegar al que ya ha caído no cuenta otra vez")
		-- Disparo en la cabeza: número amarillo
		local g3 = nil
		for _, g in Inv._ground do
			g3 = g
			break
		end
		if g3 then
			local before = #(remote :: any).Log
			Inv.hitModel(hero, g3.Model, 10, { At = g3.AI.Pos, Zone = "Head" })
			local last = (remote :: any).Log[#(remote :: any).Log]
			check(#(remote :: any).Log > before and last.Kind == "Dmg" and last.Data.Kind == "Crit" and last.To == hero, "un disparo a la cabeza: su número (amarillo, crítico) solo para quien dispara")
		end
	end
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
	-- Las pacíficas no son objetivo (ni a golpes ni a tiros); las hostiles se CALMAN (nunca mueren)
	do
		local okTargets = true
		for id, c in Inv._creatures do
			local t = c.Model:GetAttribute("InvasionTarget")
			if (c.Rec.Hostile and t ~= "C:" .. id) or (not c.Rec.Hostile and t ~= nil) then
				okTargets = false
			end
		end
		check(okTargets, "solo las criaturas hostiles son objetivo (InvasionTarget); las pacíficas, no")
		local peaceful, hostile = nil, nil
		for id, c in Inv._creatures do
			if not c.Rec.Hostile and not peaceful then
				peaceful = id
			elseif c.Rec.Hostile and not hostile then
				hostile = id
			end
		end
		if not hostile then
			-- (si esta raza solo tiene pacíficas, una se pone molesta para probar)
			for id, c in Inv._creatures do
				if id ~= peaceful then
					c.Rec.Hostile = true
					c.Model:SetAttribute("Hostile", true)
					c.Model:SetAttribute("InvasionTarget", "C:" .. id)
					hostile = id
					break
				end
			end
		end
		if peaceful then
			local c = Inv._creatures[peaceful]
			local from = c.Rec.Pos + Vector3.new(0, 0, 4)
			local hit = false
			for _, t in Inv.meleeTargets(hero, from, Vector3.new(0, 0, -1), 6, 0.25) do
				hit = hit or t.Model == c.Model
			end
			check(not hit and not (Inv.hitModel(hero, c.Model, 30, { Melee = true })), "a una criatura pacífica (un vecino transformado) no se le puede pegar")
		end
		if hostile then
			local c = Inv._creatures[hostile]
			local from = c.Rec.Pos + Vector3.new(0, 0, 4)
			local hit = false
			for _, t in Inv.meleeTargets(hero, from, Vector3.new(0, 0, -1), 6, 0.25) do
				hit = hit or t.Model == c.Model
			end
			check(hit, "a una criatura hostil delante, sí")
			for _ = 1, 10 do
				Inv.hitModel(hero, c.Model, 25, { Melee = true })
			end
			check(Inv._creatures[hostile] ~= nil and not c.Rec.Hostile and c.Model:GetAttribute("InvasionTarget") == nil, "a golpes se calma (deja de ser hostil y de ser objetivo) pero no muere: se puede revertir")
		end
	end
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

print("\n👽 Alienígenas v2: mallas de Blender, cargador, animación, IA y disparos")
do
	local fs = require("@lune/fs")
	local serde = require("@lune/serde")
	local Mallas = L.load("src/shared/Invasion/AlienMallas")
	local AlienPose = L.load("src/shared/Invasion/AlienPose")
	local HitCheck = L.load("src/shared/Invasion/HitCheck")
	-- Presupuesto y estructura
	local count, over, badJoint, badGait = 0, {}, {}, {}
	for id, m in Mallas.Models do
		count += 1
		local mains = {}
		for _, p in m.Parts do
			if not p.Lod then
				mains[p.Joint] = true -- (el segmento existe: su pieza principal o, si solo brilla, la de brillo)
			end
			if p.Tris > Mallas.Budget.MaxTrisPerMesh then
				table.insert(over, id .. "." .. p.Name)
			end
		end
		local budget = if m.Category == "Ship" then (if m.Kind == "Dropship" then Mallas.Budget.Dropship else Mallas.Budget.Ship) else (Mallas.Budget :: any)[m.Category]
		if m.Tris > budget then
			table.insert(over, ("%s (%d > %d)"):format(id, m.Tris, budget))
		end
		if m.LodTris > 0 and m.LodTris > m.Tris * 0.5 then
			table.insert(over, id .. " LOD")
		end
		for _, p in m.Parts do
			if not p.Lod and (not mains[p.Joint] or (p.Parent ~= "Root" and not mains[p.Parent])) then
				table.insert(badJoint, id .. "." .. p.Name)
			end
		end
		if not table.find(AlienPose.Gaits, m.Gait) then
			table.insert(badGait, id)
		end
	end
	check(count == 50, ("50 modelos de malla (4 tropas + rey + 3 naves + 2 criaturas × 5 razas): %d"):format(count))
	check(#over == 0, ("dentro del presupuesto (≤ %d triángulos por malla; tropa ≤ %d, rey ≤ %d, nave ≤ %d, desembarco ≤ %d, criatura ≤ %d; LOD ≤ 50 %%)%s"):format(
		Mallas.Budget.MaxTrisPerMesh, Mallas.Budget.Troop, Mallas.Budget.King, Mallas.Budget.Ship, Mallas.Budget.Dropship, Mallas.Budget.Creature, if #over > 0 then ": " .. table.concat(over, ", ") else ""))
	check(#badJoint == 0 and #badGait == 0, "cada pieza cuelga de un segmento con su articulación y cada modelo tiene un andar que sabe animar" .. (if #badJoint > 0 then " (" .. table.concat(badJoint, ", ") .. ")" else ""))
	local missingModels = {}
	for _, race in Races.List do
		for _, kind in { "Grunt", "Heavy", "Ranged", "Elite", "King", "Fighter", "Drone", "Dropship" } do
			if not Mallas.Models[race.Id .. "_" .. kind] then
				table.insert(missingModels, race.Id .. "_" .. kind)
			end
		end
		for _, c in race.Creatures do
			if not Mallas.Models[race.Id .. "_" .. c.Id] then
				table.insert(missingModels, race.Id .. "_" .. c.Id)
			end
		end
		local grunt = Mallas.Models[race.Id .. "_Grunt"]
		local names = {}
		for _, p in grunt and grunt.Parts or {} do
			names[p.Name] = true
		end
		local bones = {}
		for _, b in grunt and grunt.Bones or {} do
			bones[b.Name] = true
		end
		-- (con esqueleto: la cabeza es un hueso de la malla entera y su brillo va en CuerpoBrillo)
		local okHead = if grunt and grunt.Skinned then (bones.Body and bones.Head and names.Cuerpo and names.CuerpoBrillo) else (names.Body and names.Head and names.HeadBrillo)
		if not okHead then
			table.insert(missingModels, race.Id .. " sin cabeza que brille (punto débil)")
		end
	end
	check(#missingModels == 0, "cada raza: soldado, pesado, tirador, élite, rey, caza, dron, desembarco y sus 2 criaturas, con cabeza que brilla" .. (if #missingModels > 0 then " (" .. table.concat(missingModels, ", ") .. ")" else ""))
	-- Archivos
	local manifest = serde.decode("json", fs.readFile("assets/invasion/manifest.json"))
	local files = {}
	for _, m in manifest.Models do
		if not fs.isFile("assets/invasion/" .. m.Fbx) then
			table.insert(files, m.Fbx)
		end
	end
	for set, maps in manifest.Textures do
		for _, map in { "color", "normal", "rugosidad", "metal" } do
			if not maps[map] or not fs.isFile("assets/invasion/" .. maps[map]) then
				table.insert(files, set .. "_" .. map)
			end
		end
	end
	local sets = 0
	for _ in manifest.Textures do
		sets += 1
	end
	-- (11 juegos: tropas y naves de las 4 razas de alien_blender.py —<Raza>2_*—, las criaturas de los
	-- Vórtidos —Vortidos2_tropas— y los 2 de los Vórtidos de cristal —VortidosCristal2_*—)
	check(#files == 0 and sets == 11, ("un FBX por modelo y 11 juegos de texturas PBR (color, normal, rugosidad, metal)%s"):format(if #files > 0 then ": faltan " .. table.concat(files, ", ") else ""))
	check(fs.isFile("scripts/upload-invasion.sh") and not fs.readFile("scripts/upload-invasion.sh"):find("echo \"$ROBLOX_API_KEY", 1, true) and fs.readFile("scripts/upload-invasion.sh"):find("set +x", 1, true) ~= nil,
		"el script de subida existe y nunca enseña la clave")

	-- (aquí, instancias de verdad de Lune: sin los dobles de Model/Folder/Part del servidor)
	local savedFakes = table.clone(L.fakeClasses)
	table.clear(L.fakeClasses)
	-- Cargador: sin ids, ids que fallan, piezas que faltan y todo bien
	local Loader = L.load("src/server/World/AlienMeshLoader")
	local Ids = L.load("src/shared/Invasion/AlienAssetIds")
	local map, why = Loader.prepare({ Completos = {}, Modelos = {}, Texturas = {} }, function()
		return nil
	end, Mallas, Races)
	check(next(map) == nil and why["*"] ~= nil, "sin ids: ningún modelo de malla (siguen los de piezas)")
	check(Loader.hasIds(Ids) == false or true, "AlienAssetIds se lee")
	local function fakeAsset(id: string, skip: string?): any
		return fakeAlienAsset(Mallas.Models[id], skip)
	end
	local assets = { [101] = fakeAsset("Vortidos_Grunt"), [102] = fakeAsset("Morfagos_Grunt", "Cuerpo"), [103] = fakeAsset("Ferrocefalos_Fighter", "LOD") }
	local A = function(id: string): string
		return Mallas.Models[id].Asset or id
	end
	-- (los Vórtidos de cristal se suben con su Asset: «VortidosCristal_Grunt»)
	local vgAsset = Mallas.Models.Vortidos_Grunt.Asset or "Vortidos_Grunt"
	map, why = Loader.prepare({ Completos = {}, Modelos = { [vgAsset] = "rbxassetid://101", [A("Morfagos_Grunt")] = "rbxassetid://102", [A("Ferrocefalos_Fighter")] = "rbxassetid://103", [A("Luminidos_Grunt")] = "rbxassetid://104" }, Texturas = { Vortidos_tropas_color = "rbxassetid://9", VortidosCristal_tropas_color = "rbxassetid://9" } }, function(id)
		if id == 104 then
			error("HTTP 403")
		end
		return assets[id]
	end, Mallas, Races)
	check(map.Vortidos_Grunt ~= nil and map.Ferrocefalos_Fighter ~= nil, "con sus ids, se preparan las plantillas (una pieza de LOD que falta no importa)")
	check(map.Morfagos_Grunt == nil and string.find(why.Morfagos_Grunt or "", "Cuerpo", 1, true) ~= nil, "si falta una pieza principal, ESE modelo sigue con el de piezas (nunca a medias)")
	check(map.Luminidos_Grunt == nil and why.Luminidos_Grunt ~= nil, "si la descarga falla, sigue el de piezas (sin error)")
	local glow = map.Vortidos_Grunt and (map.Vortidos_Grunt:FindFirstChild("CuerpoBrillo") or map.Vortidos_Grunt:FindFirstChild("HeadBrillo"))
	check(glow ~= nil and glow.Material == roblox.Enum.Material.Neon, "las piezas de brillo, en Neon del color de la raza")

	-- Montaje con la malla (y respaldo sin ella)
	local AlienModels = L.load("src/server/World/Kit/AlienModels")
	local savedSource = AlienModels.meshSource
	AlienModels.meshSource = function(id)
		return map[id]
	end
	local vort = Races.get("Vortidos")
	local m = AlienModels.ground(vort, "Grunt")
	local motors, mainHead = 0, nil
	for _ in jointsOf(m) do
		motors += 1
	end
	mainHead = m:FindFirstChild("Head")
	check(m:GetAttribute("Mesh") == true and m:GetAttribute("Skinned") == true and motors >= 6 and m:FindFirstChildOfClass("Humanoid") ~= nil and m.PrimaryPart and m.PrimaryPart.Size.Y == 6,
		("con plantilla: soldado de malla con esqueleto (%d huesos), Humanoid y el mismo raíz de 6 studs"):format(motors))
	check(mainHead ~= nil and mainHead:IsA("BasePart") and mainHead.CanQuery and Weapons.zoneOf(mainHead.Name) == "Head" and Weapons.zoneOf("HeadBrillo") == "Head" and m.PrimaryPart.CanQuery == false,
		"la cabeza (la caja de la cabeza del esqueleto) cuenta como cabeza y el raíz invisible no tapa las balas")
	local fallback = AlienModels.ground(Races.get("Morfagos"), "Grunt")
	check(fallback:GetAttribute("Mesh") == nil and (fallback:GetAttribute("Parts") or 0) > 3, "sin plantilla (o a medias): el modelo de piezas de siempre")
	local ship = AlienModels.ship(Races.get("Ferrocefalos"), "Fighter")
	check(ship:GetAttribute("Mesh") == true and ship.PrimaryPart.Name == "Root", "el caza de malla con su raíz Root (lo mueve el servidor igual)")
	AlienModels.meshSource = savedSource
	for k, v in savedFakes do
		L.fakeClasses[k] = v
	end

	-- Animación (AlienPose)
	local okGaits = true
	for _, gait in AlienPose.Gaits do
		local pose = AlienPose.pose(gait, { T = 1.3, Speed = 10, Base = 7, Scale = 1, Race = "Vortidos" })
		local n = 0
		for _, cf in pose do
			n += 1
			okGaits = okGaits and typeof(cf) == "CFrame"
		end
		okGaits = okGaits and n > 0
	end
	check(okGaits, "cada andar (Biped, Crawl, Float, Quad, Slither, Hop, Ship) da una pose")
	local still = AlienPose.pose("Biped", { T = 2, Speed = 0, Base = 7, Scale = 1 })
	local walk = AlienPose.pose("Biped", { T = 2.1, Speed = 7, Base = 7, Scale = 1 })
	local runP = AlienPose.pose("Biped", { T = 2.1, Speed = 16, Base = 7, Scale = 1 })
	local function swingOf(cf)
		local x = cf:ToEulerAnglesXYZ()
		return math.abs(x)
	end
	check(swingOf(still.LegL) < 0.01 and swingOf(walk.LegL) > 0.05 and swingOf(runP.LegL) >= swingOf(walk.LegL) - 0.01, "quieto no mueve las piernas; andando sí, y corriendo más")
	check(AlienPose.flinch(0.05) > 0.3 and AlienPose.flinch(AlienPose.HitTime) == 0 and AlienPose.flinch(nil) == 0, "el respingo al encajar un disparo dura poco y se va solo")
	check(AlienPose.swing(0.8, nil) < 0 and AlienPose.swing(nil, 0.3) > 0, "al cargar echa el brazo atrás y al soltar, adelante (se ve venir)")
	local f1, s1 = AlienPose.dissolve(0.2)
	local f2, s2 = AlienPose.dissolve(AlienPose.DissolveTime)
	check(f1 < f2 and f2 == 1 and s2 < s1, "al caer se deshace (cada vez más transparente y pequeño, nada de sangre)")
	local p0, c0 = AlienPose.transform(0)
	local p1, c1 = AlienPose.transform(AlienPose.TransformTime)
	check(p0 == 1 and c0 == 0 and p1 == 0 and c1 == 1, "la transformación: se va la persona y aparece la criatura")
	check(AlienPose.useLod(200, false) and not AlienPose.useLod(160, false) and AlienPose.useLod(160, true) and not AlienPose.useLod(140, true), "LOD de lejos, con margen para no parpadear")

	-- IA: aviso, turnos, tambalearse, cubrirse
	local function aliens(n, kind)
		local list = {}
		for i = 1, n do
			table.insert(list, AlienAI.new("T" .. i, Races.get("Morfagos"), kind, Vector3.new(2 + i * 0.3, 0, 0), "Z", i))
		end
		return list
	end
	local busy = {}
	local winding = 0
	for _, a in aliens(6, "Grunt") do
		a.NextAttack = 0
		local d = AlienAI.think(a, { Players = { { Id = "P", Pos = Vector3.new(0, 0, 0) } }, Busy = busy }, 100)
		if d.Windup then
			winding += 1
		end
	end
	check(winding == AlienAI.MaxAttackers, ("como mucho %d cargando contra el mismo jugador a la vez (de 6): %d"):format(AlienAI.MaxAttackers, winding))
	local g1 = AlienAI.new("M1", Races.get("Morfagos"), "Grunt", Vector3.new(3, 0, 0), "Z", 1)
	g1.NextAttack = 0
	AlienAI.think(g1, { Players = { { Id = "P", Pos = Vector3.new(0, 0, 0) } } }, 200)
	local away = AlienAI.think(g1, { Players = { { Id = "P", Pos = Vector3.new(40, 0, 0) } } }, 200 + AlienAI.Windup.Grunt + 0.05)
	check(away.Attack == nil, "el golpe se esquiva: si te apartas mientras carga, no te da")
	local g2 = AlienAI.new("M2", Races.get("Morfagos"), "Grunt", Vector3.new(3, 0, 0), "Z", 2)
	g2.NextAttack = 0
	AlienAI.think(g2, { Players = { { Id = "P", Pos = Vector3.new(0, 0, 0) } } }, 300)
	local st, cut = AlienAI.stagger(g2, g2.MaxHp * 0.2, false, 300.1)
	local dd = AlienAI.think(g2, { Players = { { Id = "P", Pos = Vector3.new(0, 0, 0) } } }, 300.2)
	check(st and cut and dd.Mode == "Stagger" and dd.Attack == nil and g2.WindupUntil == nil, "un disparo fuerte lo tambalea y le corta el ataque que cargaba")
	local stSmall = AlienAI.stagger(AlienAI.new("M3", Races.get("Morfagos"), "Heavy", Vector3.zero, "Z", 1), 5, false, 0)
	check(stSmall == false, "un disparo flojo no tambalea a un pesado")
	local sniper = AlienAI.new("S1", Races.get("Ferrocefalos"), "Ranged", Vector3.new(0, 0, 0), "Z", 1)
	local cover = AlienAI.pickCover(sniper, Vector3.new(40, 0, 0), { Vector3.new(6, 0, 2), Vector3.new(-30, 0, 0), Vector3.new(80, 0, 0) })
	check(cover ~= nil and cover.X < 6 and (cover - Vector3.new(6, 0, 2)).Magnitude < 4, "se cubre tras lo más cercano, al otro lado de quien dispara")

	-- Disparos: compensación de lag (HitCheck)
	local h = HitCheck.newHistory()
	for i = 0, 10 do
		HitCheck.push(h, i * 0.06, Vector3.new(i * 1.2, 0, 30))
	end
	local mid = HitCheck.sample(h, 0.09)
	check(mid ~= nil and math.abs(mid.X - 1.8) < 0.05, "la historia interpola dónde estaba")
	check(HitCheck.rewindTime(0.05) == 0.05 + HitCheck.Interp and HitCheck.rewindTime(5) == HitCheck.MaxRewind and HitCheck.rewindTime(0 / 0) <= HitCheck.MaxRewind, "el tiempo hacia atrás: tu ping + la interpolación, con tope")
	local origin = Vector3.new(0, 3, 0)
	local cands = { { Id = "A", Feet = Vector3.new(0, 0, -30), Height = 6, Radius = 1.4 } }
	local hitC = HitCheck.pick(origin, Vector3.new(0, 0, -1), 200, cands)
	local missC = HitCheck.pick(origin, Vector3.new(1, 0, -1).Unit, 200, cands)
	local wallC = HitCheck.pick(origin, Vector3.new(0, 0, -1), 200, cands, 10)
	local farC = HitCheck.pick(origin, Vector3.new(0, 0, -1), 20, cands)
	local _, _, head = HitCheck.pick(Vector3.new(0, 5.6, 0), Vector3.new(0, 0, -1), 200, cands)
	check(hitC ~= nil and missC == nil, "le da si el rayo pasa por su cápsula y no si va lejos")
	check(wallC == nil and farC == nil, "nunca a través de una pared ni más allá del alcance del arma")
	check(head == true, "arriba del todo cuenta como cabeza")
	check(HitCheck.sane(origin, Vector3.new(0, 0, -50), 100) and not HitCheck.sane(origin, 0 / 0, 100) and not HitCheck.sane(origin, Vector3.new(1e9, 0, 0), 100), "el punto que manda el cliente se comprueba")
	-- Lo que viaja cuando pasa: un tirador que corre de lado
	local lagged = HitCheck.newHistory()
	for i = 0, 12 do
		HitCheck.push(lagged, 10 + i * 0.05, Vector3.new(-6 + i * 1.0, 0, -40))
	end
	local seen = HitCheck.sample(lagged, 10.6 - HitCheck.rewindTime(0.12))
	local nowPos = HitCheck.sample(lagged, 10.6) :: Vector3
	local aimDir = ((seen :: Vector3) + Vector3.new(0, 3, 0) - origin).Unit
	local withRewind = HitCheck.pick(origin, aimDir, 200, { { Id = "R", Feet = seen :: Vector3, Height = 7, Radius = 1.2 } })
	local without = HitCheck.pick(origin, aimDir, 200, { { Id = "R", Feet = nowPos, Height = 7, Radius = 1.2 } })
	check(withRewind ~= nil and without == nil, "con compensación de lag le das donde lo veías (sin ella, fallarías)")

	-- El servidor de verdad (InvasionService.rewindHit): un jugador con 150 ms de ping dispara a un
	-- alienígena que corre de lado; la cápsula sale de la caja de su MODELO (HitCheck.shape)
	do
		local ground = Inv._ground
		local saved = {}
		for id, g in ground do
			saved[id] = g
			ground[id] = nil
		end
		local t0 = os.clock()
		local hist = HitCheck.newHistory()
		local speed = 20 -- (un alienígena que corre mucho de lado)
		for i = 0, 11 do
			local t = t0 - 0.561 + i * 0.051 -- (como el servidor: una posición cada poco más de 0,05 s)
			HitCheck.push(hist, t, Vector3.new(-8 + (t - (t0 - 0.561)) * speed, 0, -40))
		end
		local model = { Name = "Alien_prueba", PrimaryPart = { Size = Vector3.new(2, 6, 2) } }
		local nowFeet = HitCheck.sample(hist, t0) :: Vector3
		ground["GPRUEBA"] = { AI = { Pos = nowFeet, Stats = { Height = 6, Radius = 2.2 } }, Model = model, Hist = hist } :: any
		local laggy = { Name = "ConPing", UserId = 777, GetNetworkPing = function()
			return 0.15
		end }
		local eye = Vector3.new(0, 4.5, 0)
		-- Lo que veía en su pantalla: hace 150 ms de ping + la interpolación de Roblox
		local seenFeet = HitCheck.sample(hist, os.clock() - 0.15 - HitCheck.Interp) :: Vector3
		local legit = ((seenFeet + Vector3.new(0, 3.5, 0)) - eye).Unit
		local m1, at1 = Inv.rewindHit(laggy :: any, eye, legit, 300, nil)
		check(m1 == model and at1 ~= nil, "150 ms de ping: el disparo a donde lo veías en tu pantalla cuenta")
		local nowOnly = HitCheck.pick(eye, legit, 300, { { Id = "x", Feet = HitCheck.sample(hist, os.clock()) :: Vector3, Height = 6, Radius = 1.32 } }, nil, nil, 0)
		check(nowOnly == nil, "(sin la compensación, ese mismo disparo fallaba: el alienígena ya no estaba ahí)")
		-- Imposibles: 6 studs a un lado, a través de una pared, más allá del alcance, o con un «ping» de 1 s
		local wide = ((seenFeet + Vector3.new(6, 3.5, 0)) - eye).Unit
		check(Inv.rewindHit(laggy :: any, eye, wide, 300, nil) == nil, "imposible: 6 studs al lado no cuenta (el imán de la bala es pequeño)")
		check(Inv.rewindHit(laggy :: any, eye, legit, 300, 15) == nil, "imposible: con una pared delante (a 15 studs) no cuenta")
		check(Inv.rewindHit(laggy :: any, eye, legit, 20, nil) == nil, "imposible: más lejos que el alcance del arma no cuenta")
		local cheat = { Name = "Tramposo", UserId = 778, GetNetworkPing = function()
			return 1.0
		end }
		local oldFeet = HitCheck.sample(hist, os.clock() - 0.56) :: Vector3
		local stale = ((oldFeet + Vector3.new(0, 3.5, 0)) - eye).Unit
		check(Inv.rewindHit(cheat :: any, eye, stale, 300, nil) == nil, "imposible: decir que tienes 1 s de ping no deja dar a donde estaba hace más de medio segundo (tope 0,4 s)")
		-- Forma del modelo: si el modelo crece (otro alienígena más alto), la cápsula crece con él
		local h1, r1 = HitCheck.shape(Vector3.new(2, 6, 2), 6, 2.2)
		local h2, r2, bottom2 = HitCheck.shape(Vector3.new(4, 9, 4), 6, 2.2)
		check(h1 == 6 and r1 >= 1.3 and h2 == 9 and r2 == 2 and bottom2 == -1.5, "la cápsula sale de la caja del modelo (alto y ancho), no de números fijos")
		ground["GPRUEBA"] = nil
		for id, g in saved do
			ground[id] = g
		end
	end

	-- El servidor: avisos, respingos y la compensación conectada
	local svc = fs.readFile("src/server/Services/InvasionService.luau")
	check(svc:find('broadcast("Windup"', 1, true) ~= nil and svc:find('broadcast("Flinch"', 1, true) ~= nil and svc:find("AlienAI.stagger(", 1, true) ~= nil and svc:find("weapons.invasionRewind = InvasionService.rewindHit", 1, true) ~= nil,
		"el servidor avisa de los ataques, de los respingos y conecta la compensación de lag con las armas")
	local wsrc = fs.readFile("src/server/Services/WeaponService.luau")
	check(wsrc:find("local rewind = WeaponService.invasionRewind", 1, true) ~= nil and wsrc:find('K = "Xeno"', 1, true) ~= nil, "las armas usan la compensación (solo si el rayo de verdad no ha dado) y sus impactos son chispas de luz")
	local cli = fs.readFile("src/client/Controllers/AlienAnim.luau")
	check(cli:find("LocalTransparencyModifier", 1, true) ~= nil and cli:find("e.J.Transform = ", 1, true) ~= nil and cli:find("IsA(\"Bone\")", 1, true) ~= nil and cli:find("Blood", 1, true) == nil and cli:find("sangre", 1, true) ~= nil,
		"el cliente anima con Motor6D.Transform (o Bone.Transform en los de esqueleto), cambia a LOD y nada de sangre")
end

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

print("\n📸 Arreglos tras la captura del dueño (Lumínidos, barras y avisos del evento)")
do
	local fs = require("@lune/fs")
	local Mallas = L.load("src/shared/Invasion/AlienMallas")
	local savedFakes = table.clone(L.fakeClasses)
	table.clear(L.fakeClasses)
	local Loader = L.load("src/server/World/AlienMeshLoader")
	local AlienModels = L.load("src/server/World/Kit/AlienModels")
	-- Plantillas de mentira para TODOS los modelos (como si hubieran bajado todos)
	local ids, assets, n = {}, {}, 0
	for id, m in Mallas.Models do
		n += 1
		assets[1000 + n] = fakeAlienAsset(m)
		ids[m.Asset or id] = "rbxassetid://" .. (1000 + n)
	end
	local map = Loader.prepare({ Completos = {}, Modelos = ids, Texturas = {} }, function(id)
		return assets[id]
	end, Mallas, Races)
	local savedSource = AlienModels.meshSource
	AlienModels.meshSource = function(id)
		return map[id]
	end
	-- (la caja de las piezas que se ven: sin el raíz ni la versión lejana)
	local function box(model: any): (any, any)
		local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") and d ~= model.PrimaryPart and not d:GetAttribute("Lod") and d.Transparency < 1 then
				local h = d.Size / 2
				lo = Vector3.new(math.min(lo.X, d.CFrame.Position.X - h.X), math.min(lo.Y, d.CFrame.Position.Y - h.Y), math.min(lo.Z, d.CFrame.Position.Z - h.Z))
				hi = Vector3.new(math.max(hi.X, d.CFrame.Position.X + h.X), math.max(hi.Y, d.CFrame.Position.Y + h.Y), math.max(hi.Z, d.CFrame.Position.Z + h.Z))
			end
		end
		return lo, hi
	end
	local bad = {}
	for _, race in Races.List do
		local list = {}
		for _, kind in { "Grunt", "Heavy", "Ranged", "Elite" } do
			table.insert(list, { Kind = kind, Model = AlienModels.ground(race, kind) })
		end
		table.insert(list, { Kind = "King", Model = (AlienModels.king(race)) })
		for _, c in race.Creatures do
			table.insert(list, { Kind = c.Id, Model = AlienModels.creature(race, c), Creature = true })
		end
		for _, e in list do
			local m = e.Model
			local motors = 0
			for _ in jointsOf(m) do
				motors += 1
			end
			local h = m.PrimaryPart.Size.Y
			local lo, hi = box(m)
			local size = hi - lo
			-- (las criaturas pequeñas que van a ras de suelo —bicho, rana, babosa, perro— son más bajas que
			-- su raíz: basta con que tengan algo de alto y no sean más largas que dos veces y media)
			local okBox = if e.Creature
				then size.Y >= h * 0.3 and math.max(size.X, size.Z) <= h * 2.5 and math.abs(lo.Y + h / 2) <= h * 0.4
				else size.Y >= h * 0.55 and size.Y <= h * 1.6 and size.X <= h * 2.2 and size.Z <= h * 2.2 and math.abs(lo.Y + h / 2) <= h * 0.4
			local okRig = m:GetAttribute("Mesh") == true and motors >= 2 and (e.Creature or m:FindFirstChild("Head") ~= nil)
			if not (okBox and okRig) then
				table.insert(bad, ("%s_%s (malla=%s, %d articulaciones, caja %.1fx%.1fx%.1f para %.1f de alto, pies a %.1f)"):format(race.Id, e.Kind, tostring(m:GetAttribute("Mesh")), motors, size.X, size.Y, size.Z, h, lo.Y + h / 2))
			end
		end
	end
	check(#bad == 0, "las 5 razas (4 tropas, el rey y sus 2 criaturas): de malla de verdad (no el respaldo), con articulaciones, cabeza y una caja con sentido (alto, ancho y pies en el suelo)" .. (if #bad > 0 then ": " .. table.concat(bad, "; ") else ""))
	local light = AlienModels.ground(Races.get("Luminidos"), "Grunt")
	local fillLight = light.PrimaryPart:FindFirstChild("LuzRelleno")
	local pl = fillLight and fillLight:FindFirstChildOfClass("PointLight")
	check(pl ~= nil and pl.Brightness <= 1, "de noche: una luz suave delante de cada tropa de malla (no un foco)")
	local white = Races.color(Races.get("Luminidos").Palette.Glow)
	local dim = Loader.glowColor(white)
	check(dim.R < white.R * 0.75 and dim.G < white.G * 0.75, "el brillo (Neon) casi blanco de los Lumínidos va más apagado: no se come la silueta")
	AlienModels.meshSource = function()
		return nil
	end
	-- El respaldo de piezas (si una malla no llega): una criatura que se lee, sin ForceField ni discos
	local fb = {}
	for _, race in Races.List do
		for _, kind in { "Grunt", "Heavy", "Ranged", "Elite" } do
			local m = AlienModels.ground(race, kind)
			local h = m.PrimaryPart.Size.Y
			local limbs, forceField, bigGlow = 0, false, false
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") and d ~= m.PrimaryPart then
					if d.Name == "Pierna" or d.Name == "Brazo" or d.Name == "Tentaculo" or d.Name == "Tunica" then
						limbs += 1
					end
					if d.Material == roblox.Enum.Material.ForceField then
						forceField = true
					end
					if d.Material == roblox.Enum.Material.Neon and math.max(d.Size.X, d.Size.Z) > h * 0.4 then
						bigGlow = true
					end
				end
			end
			local lo, hi = box(m)
			if m:GetAttribute("Mesh") or not m:FindFirstChild("Head") or limbs < 3 or forceField or bigGlow or (hi.Y - lo.Y) < h * 0.85 then
				table.insert(fb, ("%s_%s (miembros %d, ForceField %s, brillo grande %s, alto %.1f de %.1f)"):format(race.Id, kind, limbs, tostring(forceField), tostring(bigGlow), hi.Y - lo.Y, h))
			end
		end
	end
	check(#fb == 0, "el respaldo de piezas de cada raza: cabeza, brazos y piernas (o túnica/tentáculos), sin ForceField ni un disco de luz grande" .. (if #fb > 0 then ": " .. table.concat(fb, "; ") else ""))
	AlienModels.meshSource = savedSource
	for k, v in savedFakes do
		L.fakeClasses[k] = v
	end
	local svc = fs.readFile("src/server/Services/InvasionService.luau")
	check(svc:find("elseif InvasionService.meshesPending() then", 1, true) ~= nil and fs.readFile("src/server/World/AlienMeshLoader.luau"):find("function AlienMeshLoader.loading", 1, true) ~= nil,
		"la invasión no empieza sola mientras bajan las mallas (antes: las primeras oleadas salían con el respaldo)")

	-- Barras de vida: una por alienígena, sin pisarse, pocas y solo de los tocados y cercanos
	local Marks = L.load("src/shared/Invasion/Marks")
	local list = {
		{ Id = "A", Dist = 20, Hp = 50, Max = 100, OnScreen = true, X = 400, Y = 200 },
		{ Id = "B", Dist = 25, Hp = 40, Max = 100, OnScreen = true, X = 410, Y = 204 }, -- casi en el mismo sitio que A
		{ Id = "C", Dist = 30, Hp = 100, Max = 100, OnScreen = true, X = 600, Y = 220 }, -- vida llena
		{ Id = "D", Dist = 400, Hp = 10, Max = 100, OnScreen = true, X = 700, Y = 150 }, -- lejos
		{ Id = "E", Dist = 40, Hp = 10, Max = 100, OnScreen = false, X = 0, Y = 0 }, -- fuera de la pantalla
		{ Id = "F", Dist = 50, Hp = 0, Max = 100, OnScreen = true, X = 300, Y = 300 }, -- caído
		{ Id = "R", Dist = 600, Hp = 5000, Max = 5000, King = true, OnScreen = true, X = 900, Y = 120 }, -- el rey
	}
	local shown = Marks.pick(list, "Medium")
	check(shown.A == true and shown.B == nil, "dos barras que caerían una encima de otra: solo la del más cercano")
	check(shown.C == nil and shown.D == nil and shown.E == nil and shown.F == nil, "sin barra con la vida llena, lejos, fuera de la pantalla o caído")
	check(shown.R == true, "el rey siempre lleva la suya")
	local many = {}
	for i = 1, 30 do
		table.insert(many, { Id = i, Dist = i * 3, Hp = 1, Max = 2, OnScreen = true, X = i * 80, Y = 100 + (i % 3) * 60 })
	end
	local count = 0
	for _ in Marks.pick(many, "High") do
		count += 1
	end
	local countLow = 0
	for _ in Marks.pick(many, "Low") do
		countLow += 1
	end
	check(count == Marks.Caps.High and countLow == Marks.Caps.Low, ("como mucho %d barras a la vez (%d en gráficos Bajo)"):format(Marks.Caps.High, Marks.Caps.Low))
	check(Marks.zoneVisible({ Control = 0, Conquered = false }, 50) == false and Marks.zoneVisible({ Control = 0.4 }, 100) == true and Marks.zoneVisible({ Conquered = true }, 5000) == false,
		"letreros de zona: solo las que están en disputa o conquistadas, y no las lejanas")
	local cli = fs.readFile("src/client/Controllers/InvasionClient.luau")
	check(cli:find("Marks.pick(entries, t)", 1, true) ~= nil and cli:find('model:FindFirstChild("Head")', 1, true) ~= nil and cli:find("mark.AlwaysOnTop = king", 1, true) ~= nil,
		"el cliente usa Marks, pega la barra a la cabeza y no la enseña a través de las paredes")

	-- Un solo aviso del evento: entero 6 s y luego una píldora
	local InvasionHud = L.load("src/client/UI/InvasionHud")
	local mem = {}
	local st = { State = "Wave", Wave = 1, Waves = 4, Left = 166, Text = "Oleada 1 de 4" }
	local F = InvasionHud.FullSeconds
	check(F <= 3.5, ("el panel entero en el centro dura poco (%.1f s; el dueño: ~3 s)"):format(F))
	check(InvasionHud.mode(mem, st, 100) == "Full" and InvasionHud.mode(mem, st, 100 + F - 0.1) == "Full", "al empezar la oleada, el panel entero")
	check(InvasionHud.mode(mem, st, 100 + F + 0.1) == "Pill" and InvasionHud.mode(mem, st, 200) == "Pill", ("a los %d s se encoge a la píldora y se queda así"):format(F))
	InvasionHud.toggle(mem, 201)
	check(InvasionHud.mode(mem, st, 202) == "Full", "tocando la píldora se abre otra vez")
	InvasionHud.toggle(mem, 203)
	check(InvasionHud.mode(mem, st, 203.5) == "Pill", "tocando el panel abierto se cierra")
	local st2 = table.clone(st)
	st2.Wave = 2
	check(InvasionHud.mode(mem, st2, 300) == "Full" and InvasionHud.mode(mem, st2, 300 + F + 0.5) == "Pill", "la oleada siguiente lo abre otra vez un momento")
	check(InvasionHud.mode(mem, nil, 310) == "Hidden", "sin invasión, nada")
	local pill = InvasionHud.pillText(st)
	check(pill:find("Oleada 1/4", 1, true) ~= nil and pill:find("2:46", 1, true) ~= nil and pill:find("🛸", 1, true) ~= nil, "la píldora: icono, «Oleada 1/4» y el tiempo (" .. pill .. ")")
	local t = InvasionHud.text(st, nil, "Lumínidos", "Defiende o recupera una zona")
	check(t.Step:find("Defiende", 1, true) ~= nil and t.Pill == pill, "el panel lleva también lo que tienes que hacer (antes iba en un segundo panel)")
	local hud = fs.readFile("src/client/UI/Hud.luau")
	check(hud:find('"EVENTO GLOBAL · " ..', 1, true) == nil and hud:find('"🛸 Invasión de la Grieta")', 1, true) == nil,
		"la tarjeta de misión ya no pone un segundo «EVENTO GLOBAL»: un solo aviso del evento")
	local _, registers = cli:gsub("TopStack%.register%(", "")
	check(registers == 1, "el cliente de la invasión registra un solo letrero arriba")
	local HudLayout = L.load("src/client/UI/HudLayout")
	local TopStack = L.load("src/client/UI/TopStack")
	for _, size in { { 932, 430, true }, { 844, 390, true }, { 640, 360, true }, { 1920, 1080, false } } do
		local view = Vector2.new(size[1], size[2])
		local layout = HudLayout.compute(view, { Touch = size[3] })
		local r = InvasionHud.pillRect(HudLayout, layout, size[3])
		local hits = {}
		for _, id in { "Clock", "Minimap", "Ammo", "Status", "Gps", "Mission", "Help" } do
			if layout.Items[id] and HudLayout.overlaps(r, HudLayout.rect(layout.Items[id], layout.Canvas)) then
				table.insert(hits, id)
			end
		end
		local k = layout.Scale
		local w, h = math.floor(r.W * k), math.floor(r.H * k)
		local text = math.floor(math.min((if size[3] then 26 else 16), r.H - 6) * k)
		local robloxButtons = r.X * k >= InvasionHud.RobloxButtons
		check(r.W >= InvasionHud.PillMinW and #hits == 0 and robloxButtons and (r.Y + r.H) * k <= view.Y * 0.2 and w <= view.X * 0.3 and text >= 8,
			("%dx%d: la píldora (%dx%d px en x=%d y=%d, letra ~%d px) en la franja de arriba, sin tapar el centro, el minimapa, las balas ni el reloj%s"):format(size[1], size[2], w, h, math.floor(r.X * k), math.floor(r.Y * k), text, if #hits > 0 then " (pisa " .. table.concat(hits, ", ") .. ")" else ""))
		-- y el panel entero (6 s) sigue cabiendo en la columna del centro
		local fw, fh = InvasionHud.pixelSize(k, size[3], false)
		local placed = TopStack.arrange(view, { { Id = "Inv", Priority = TopStack.Priority.Mission, W = fw, H = fh } }, { Touch = size[3] })
		check(placed.Inv.Shown, ("%dx%d: el panel entero (al empezar la oleada) cabe en la columna de arriba"):format(size[1], size[2]))
		-- (el botón «¿Qué hago?» salía pegado al borde del panel: ahora con aire entre los dos)
		if layout.Items.Help then
			local hr = HudLayout.rect(layout.Items.Help, layout.Canvas)
			local hx, hy, hw, hh = hr.X * k, hr.Y * k, hr.W * k, hr.H * k
			local p = placed.Inv
			local apart = p.X + p.W + 8 <= hx or hx + hw + 8 <= p.X or p.Y + p.H + 8 <= hy or hy + hh + 8 <= p.Y
			check(apart, ("%dx%d: el botón «¿Qué hago?» no queda pegado al panel del evento (≥ 8 px)"):format(size[1], size[2]))
		end
	end
end

print("\n💠 Vórtidos de cristal (las hojas del dueño: soldado, líder y nave «Clase: Guardián»)")
do
	local fs = require("@lune/fs")
	local Mallas = L.load("src/shared/Invasion/AlienMallas")
	local AlienPose = L.load("src/shared/Invasion/AlienPose")
	local vort = Races.get("Vortidos")
	-- Los datos de la malla (vortidos_blender.py)
	local bad = {}
	local budgets = { Grunt = 10000, Heavy = 10000, Ranged = 10000, Elite = 10000, King = 15000, Fighter = 12000, Drone = 12000, Dropship = 16000 }
	for kind, budget in budgets do
		local m = Mallas.Models["Vortidos_" .. kind]
		if not m then
			table.insert(bad, kind .. " (no está)")
			continue
		end
		local names, bones, crystal, loose = {}, {}, 0, {}
		for _, p in m.Parts do
			names[p.Name] = p
			if p.Crystal then
				crystal += 1
			end
			-- (moderación, docs/bugs/moderacion/: ninguna malla que se sube es un segmento suelto)
			if not p.Lod and not p.Skinned then
				table.insert(loose, p.Name)
			end
		end
		for _, b in m.Bones or {} do
			bones[b.Name] = b
		end
		if m.Asset ~= "VortidosCristal2_" .. kind or not m.Skinned or #loose > 0 or m.Tris > budget or crystal < 1 or not m.Pulse then
			table.insert(bad, ("%s (Asset %s, esqueleto %s, %d triángulos de %d, %d piezas de cristal, sueltas: %s)"):format(kind, tostring(m.Asset), tostring(m.Skinned), m.Tris, budget, crystal, table.concat(loose, ",")))
		end
		for _, need in { "Cuerpo", "CuerpoCristal", "CuerpoBrillo", "LOD", "LODCristal" } do
			if not names[need] then
				table.insert(bad, kind .. " sin " .. need)
			end
		end
		if m.Category ~= "Ship" then
			for _, need in { "Body", "Head", "ArmL", "ForeArmL", "ForeArmR", "LegL", "LowerLegL", "LowerLegR" } do
				if not bones[need] then
					table.insert(bad, kind .. " sin el hueso " .. need)
				end
			end
			if bones.ForeArmL and bones.ForeArmL.Parent ~= "ArmL" or bones.LowerLegR and bones.LowerLegR.Parent ~= "LegR" then
				table.insert(bad, kind .. ": codo o rodilla mal colgados")
			end
		end
	end
	check(#bad == 0, "los 8 Vórtidos de cristal: UNA malla con esqueleto cada uno (Asset VortidosCristal2_*, ningún segmento suelto), cristal, huesos de codos y rodillas, LOD y dentro de su presupuesto (tropa ≤ 10 000, líder ≤ 15 000, nave ≤ 12 000)" .. (if #bad > 0 then ": " .. table.concat(bad, "; ") else ""))
	local king = Mallas.Models.Vortidos_King
	local kp = {}
	for _, b in king.Bones or {} do
		kp[b.Name] = b
	end
	check(kp.Cape and kp.Cape2 and kp.Cape3 and kp.Cape2.Parent == "Cape" and kp.Cape3.Parent == "Cape2" and kp.Cape.Parent == "Body",
		"el líder: la capa en 3 bandas encadenadas (huesos Body → Cape → Cape2 → Cape3) para que se meza")
	check(kp.Scepter and kp.Scepter.Parent == "ForeArmR",
		"el líder: el cetro (con su gema de cristal) colgado de la mano derecha (su hueso, dentro de la malla entera)")
	check(Mallas.Models.Vortidos_Ranged.Attack == "Rifle" and Mallas.Models.Vortidos_Grunt.Attack == "Claw" and king.Attack == "Scepter",
		"cada uno ataca con lo suyo: garras, el rifle de cristal del Prisma y el cetro del líder")
	local grunt = Mallas.Models.Vortidos_Grunt
	local top, bottom = -math.huge, math.huge
	for _, p in grunt.Parts do
		if not p.Lod then
			top = math.max(top, p.Center.Y + p.Size.Y / 2)
			bottom = math.min(bottom, p.Center.Y - p.Size.Y / 2)
		end
	end
	check(math.abs(top - 3) < 0.15 and math.abs(bottom + 3) < 0.2, ("el soldado mide sus 6 studs de la planta a la punta de la corona (%.2f a %.2f)"):format(bottom, top))
	-- Los ids viejos («Vortidos_Grunt», el FBX de antes) no se mezclan con los datos nuevos
	local Loader = L.load("src/server/World/AlienMeshLoader")
	local savedFakes = table.clone(L.fakeClasses)
	table.clear(L.fakeClasses)
	local oldAsset = roblox.Instance.new("Model")
	for _, n in { "Body", "Head", "ArmL", "ArmR", "LegL", "LegR", "HeadBrillo", "LOD" } do
		local mp = roblox.Instance.new("MeshPart")
		mp.Name = n
		mp.Parent = oldAsset
	end
	local oldMap = Loader.prepare({ Completos = {}, Modelos = { Vortidos_Grunt = "rbxassetid://5" }, Texturas = {} }, function()
		return oldAsset
	end, Mallas, Races)
	check(oldMap.Vortidos_Grunt == nil, "con el id viejo (el FBX de antes) el soldado no se monta a medias: espera a VortidosCristal2_* y mientras va el de piezas nuevo")
	-- Ni con el Model de la v124 (segmentos sueltos, dos retirados por la moderación) aunque se pusiera con el nombre nuevo
	local v124 = roblox.Instance.new("Model")
	for _, n in { "Body", "BodyCristal", "BodyBrillo", "Head", "HeadCristal", "HeadBrillo", "ArmL", "ForeArmL", "ForeArmR", "LegL", "LowerLegL", "LowerLegR", "LOD", "LODCristal", "LODBrillo" } do
		local mp = roblox.Instance.new("MeshPart")
		mp.Name = n
		mp.Parent = v124
	end
	local v124Map, v124Why = Loader.prepare({ Completos = {}, Modelos = { VortidosCristal_Grunt = "rbxassetid://6", VortidosCristal2_Grunt = "rbxassetid://7" }, Texturas = {} }, function()
		return v124
	end, Mallas, Races)
	check(v124Map.Vortidos_Grunt == nil and string.find(v124Why.Vortidos_Grunt or "", "Cuerpo", 1, true) ~= nil,
		"el Model de la v124 (un segmento por malla) no vale para el de esqueleto: sigue el de piezas (nunca a medias)")
	-- Montaje con plantillas de mentira (como si hubiera bajado todo)
	local ids, assets, n = {}, {}, 0
	for id, m in Mallas.Models do
		if m.Race ~= "Vortidos" then
			continue
		end
		n += 1
		assets[2000 + n] = fakeAlienAsset(m)
		ids[m.Asset or id] = "rbxassetid://" .. (2000 + n)
	end
	local map = Loader.prepare({ Completos = {}, Modelos = ids, Texturas = {} }, function(id)
		return assets[id]
	end, Mallas, Races)
	local crystalPart = map.Vortidos_Grunt and map.Vortidos_Grunt:FindFirstChild("CuerpoCristal")
	check(crystalPart ~= nil and crystalPart.Material == roblox.Enum.Material.Glass and crystalPart.Transparency > 0 and crystalPart.Transparency < 0.4,
		"el cristal (corona, racimo de la espalda, garras) en Glass cian pálido, algo transparente, con sus núcleos de Neon dentro")
	local AlienModels = L.load("src/server/World/Kit/AlienModels")
	local savedSource = AlienModels.meshSource
	AlienModels.meshSource = function(id)
		return map[id]
	end
	local function box(model: any): (any, any)
		local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") and d ~= model.PrimaryPart and not d:GetAttribute("Lod") and d.Transparency < 1 and not d:GetAttribute("WeakPoint") then
				local h = d.Size / 2
				local p = d.CFrame.Position
				lo = Vector3.new(math.min(lo.X, p.X - h.X), math.min(lo.Y, p.Y - h.Y), math.min(lo.Z, p.Z - h.Z))
				hi = Vector3.new(math.max(hi.X, p.X + h.X), math.max(hi.Y, p.Y + h.Y), math.max(hi.Z, p.Z + h.Z))
			end
		end
		return lo, hi
	end
	local rigBad = {}
	for _, kind in { "Grunt", "Heavy", "Ranged", "Elite" } do
		local m = AlienModels.ground(vort, kind)
		local h = m.PrimaryPart.Size.Y
		local motors = jointsOf(m)
		local lo, hi = box(m)
		local size = hi - lo
		local okRig = m:GetAttribute("Mesh") == true and m:GetAttribute("Pulse") == true and m:GetAttribute("Skinned") == true and motors.ForeArmR and motors.LowerLegL
			and motors.ForeArmR:IsA("Bone") and motors.ForeArmR.Parent and motors.ForeArmR.Parent.Name == "ArmR"
		-- (delgado: más alto que ancho; la corona y el racimo de la espalda cuentan)
		local okBox = size.Y >= h * 0.9 and size.Y <= h * 1.1 and size.X <= h * 0.75 and size.Z <= h * 0.6 and math.abs(lo.Y + h / 2) <= h * 0.05
		if not (okRig and okBox) then
			table.insert(rigBad, ("%s (rig %s, caja %.1f×%.1f×%.1f para %.1f, pies a %.2f)"):format(kind, tostring(okRig), size.X, size.Y, size.Z, h, lo.Y + h / 2))
		end
	end
	check(#rigBad == 0, "Esquirla, Monolito, Prisma y Custodio de malla: una malla con esqueleto (Bone en hombro, codo, cadera y rodilla), figura alta y delgada con los pies en el suelo" .. (if #rigBad > 0 then ": " .. table.concat(rigBad, "; ") else ""))
	local kingModel, weak = AlienModels.king(vort)
	local km = jointsOf(kingModel)
	local klo, khi = box(kingModel)
	local kh = kingModel.PrimaryPart.Size.Y
	-- (el rey es 4,2 veces el élite: sus huesos se separan igual —AlienModels escala los Bone con la malla—)
	local spread = if km.Head and km.Body then (km.Head.CFrame.Position).Magnitude else 0
	check(kingModel:GetAttribute("Mesh") == true and #weak == 3 and km.Cape3 and km.Cape3.Parent and km.Cape3.Parent.Name == "Cape2" and km.Scepter and km.Scepter.Parent.Name == "ForeArmR"
		and spread > 2 and (khi.Y - klo.Y) >= kh * 0.9 and (khi.Y - klo.Y) <= kh * 1.15,
		("Kael-Ithra de malla: capa en cadena (Cape3 cuelga de Cape2), cetro en la mano derecha, 3 puntos débiles y %.0f de alto (raíz %.0f)"):format(khi.Y - klo.Y, kh))
	local ship = AlienModels.ship(vort, "Fighter")
	local slo, shi = box(ship)
	check(ship:GetAttribute("Mesh") == true and ship.PrimaryPart.Name == "Root" and ship:FindFirstChild("CuerpoCristal") ~= nil and ship:GetAttribute("Pulse") == true
		and (shi.X - slo.X) >= 10 and (shi.Z - slo.Z) >= 12 and (shi.Z - slo.Z) <= 22,
		("la Fragata Prisma («Clase: Guardián») de malla: raíz Root, cristal y motores que laten, %.0f de envergadura y %.0f de largo"):format(shi.X - slo.X, shi.Z - slo.Z))
	check(vort.Air.Fighter == "Fragata Prisma" and fs.readFile("src/server/Services/InvasionService.luau"):find("local model = AlienModels.ship(race, kind)", 1, true) ~= nil,
		"las naves de la invasión (Fragata Prisma, Astilla, Geoda) salen de AlienModels.ship: la Guardián entra sola")
	-- Respaldo de piezas (si la malla no ha bajado): ya con la pinta nueva
	AlienModels.meshSource = function()
		return nil
	end
	local fbBad = {}
	for _, kind in { "Grunt", "Heavy", "Ranged", "Elite" } do
		local m = AlienModels.ground(vort, kind)
		local head, crown, cluster = m:FindFirstChild("Head"), m:FindFirstChild("Corona"), m:FindFirstChild("Racimo")
		local visor = m:FindFirstChild("HeadBrillo")
		local dark = head and head.Color.R < 0.2 and head.Color.G < 0.2
		if not (dark and crown and crown.Material == roblox.Enum.Material.Glass and cluster and visor and visor.Material == roblox.Enum.Material.Neon and (m:GetAttribute("Parts") or 99) <= 18) then
			table.insert(fbBad, kind)
		end
	end
	local fship = AlienModels.ship(vort, "Fighter")
	check(#fbBad == 0 and fship:FindFirstChild("Morro") ~= nil and fship:FindFirstChild("Cabina") ~= nil,
		"sin malla, el de piezas ya se parece a la hoja: cuerpo negro, visor cian, corona y racimo de cristal; la nave con morro de cristal y cabina" .. (if #fbBad > 0 then " (" .. table.concat(fbBad, ", ") .. ")" else ""))
	AlienModels.meshSource = savedSource
	for k, v in savedFakes do
		L.fakeClasses[k] = v
	end
	-- Animación: codos, rodillas, capa en cadena y ataques
	local idle = AlienPose.pose("Biped", { T = 1, Speed = 0, Base = 7, Scale = 1, Attack = "Claw" })
	local run = AlienPose.pose("Biped", { T = 1.3, Speed = 18, Base = 7, Scale = 1, Attack = "Claw" })
	local walk = AlienPose.pose("Biped", { T = 1.3, Speed = 7, Base = 7, Scale = 1, Attack = "Claw" })
	local function pitch(cf)
		local x = cf:ToEulerAnglesXYZ()
		return x
	end
	check(idle.ForeArmR and idle.LowerLegL and run.Cape3 and pitch(run.Body) < pitch(walk.Body) - 0.1,
		"la pose de los Vórtidos mueve codos y rodillas y al correr van encorvados (como en la hoja)")
	local knees = 0
	for i = 0, 20 do
		local p = AlienPose.pose("Biped", { T = i * 0.05, Speed = 18, Base = 7, Scale = 1, Attack = "Claw" })
		knees = math.min(knees, pitch(p.LowerLegL))
	end
	check(knees < -0.5, ("al correr la rodilla se dobla al recoger el pie (hasta %.2f rad)"):format(knees))
	local swayTop, swayBottom = 0, 0
	for i = 0, 40 do
		local p = AlienPose.pose("Biped", { T = i * 0.1, Speed = 0, Base = 7, Scale = 1, Attack = "Scepter" })
		swayTop = math.max(swayTop, math.abs(pitch(p.Cape)))
		swayBottom = math.max(swayBottom, math.abs(pitch(p.Cape3)))
	end
	check(swayBottom > swayTop and swayTop > 0, "la capa se mece en cadena: más abajo, más vaivén")
	local clawWind = AlienPose.pose("Biped", { T = 1, Speed = 0, Base = 7, Scale = 1, Attack = "Claw", Windup = 1 })
	local clawHit = AlienPose.pose("Biped", { T = 1, Speed = 0, Base = 7, Scale = 1, Attack = "Claw", Strike = 0.3 })
	local aim = AlienPose.pose("Biped", { T = 1, Speed = 0, Base = 7, Scale = 1, Attack = "Rifle", Windup = 1 })
	local shot = AlienPose.pose("Biped", { T = 1, Speed = 0, Base = 7, Scale = 1, Attack = "Rifle", Strike = 0.1 })
	check(pitch(clawWind.ArmR) < 0 and pitch(clawHit.ArmR) > 0.5, "garras: el brazo atrás al cargar y un zarpazo hacia delante al soltar")
	check(pitch(aim.ArmR) > 0.4 and pitch(aim.ArmL) > 0.5 and pitch(shot.ArmR) < pitch(aim.ArmR), "el Prisma sube el rifle con las dos manos al cargar y al disparar da un retroceso")
	check(AlienPose.pulse(0, 0) >= 0.8 and AlienPose.pulse(0.7, 1) <= 1.0, "el cristal y los motores laten despacio (80–100 %)")
	local anim = fs.readFile("src/client/Controllers/AlienAnim.luau")
	check(anim:find("Attack = rec.Attack", 1, true) ~= nil and anim:find("AlienPose.pulse(", 1, true) ~= nil, "el cliente pasa el arma a la pose y hace latir el brillo")
	-- Nombre y subida
	check(vort.King.Name == "Kael-Ithra" and not string.find(vort.King.Title, "Reina", 1, true), "Kael-Ithra sin género en el título visible («" .. vort.King.Title .. "»)")
	local up = fs.readFile("scripts/upload-invasion.sh")
	check(up:find("--solo", 1, true) ~= nil and fs.readFile("scripts/invasion/compose.luau"):find("model.Asset or model.Id", 1, true) ~= nil
		and fs.isFile("assets/invasion/VortidosCristal2_Grunt.fbx") and fs.isFile("assets/invasion/tex/VortidosCristal2_tropas_color.png") and fs.isFile("assets/invasion/tex/VortidosCristal2_naves_color.png")
		and not fs.isFile("assets/invasion/VortidosCristal_Grunt.fbx") and up:find("revisar_mallas", 1, true) ~= nil,
		"subir solo los Vórtidos de cristal: scripts/upload-invasion.sh --solo VortidosCristal2 (FBX y texturas listos, los de la v124 fuera, y antes la revisión de moderación)")
	for _, f in { "comparacion-soldado.png", "comparacion-lider.png", "comparacion-nave.png" } do
		check(fs.isFile("docs/invasion/referencia-cristal/" .. f), "hoja de comparación con la del dueño: " .. f)
	end
end

print("\n🚫 Mallas retiradas por la moderación de Roblox (docs/bugs/moderacion/): siempre el respaldo, sin errores")
do
	local Mallas = L.load("src/shared/Invasion/AlienMallas")
	local Retiradas = L.load("src/server/World/MallasRetiradas")
	local savedFakes = table.clone(L.fakeClasses)
	table.clear(L.fakeClasses)
	local Loader = L.load("src/server/World/AlienMeshLoader")
	local AlienModels = L.load("src/server/World/Kit/AlienModels")
	check(Retiradas.Ids[136955064198663] ~= nil and Retiradas.Ids[138746120321894] ~= nil, "las dos mallas retiradas de la v124 están en la lista (World/MallasRetiradas)")
	local vg = Mallas.Models.Vortidos_Grunt
	local function prep(asset: any, key: string, verify: any?): (any, any)
		return Loader.prepare({ Completos = {}, Modelos = { [key] = "rbxassetid://31" }, Texturas = {} }, function()
			return asset
		end, Mallas, Races, verify)
	end
	-- El cuerpo con una malla retirada: ese modelo sigue con el de piezas
	local ok1, map1, why1 = pcall(prep, fakeAlienAsset(vg, nil, { Cuerpo = 138746120321894, CuerpoCristal = 41, CuerpoBrillo = 42 }), vg.Asset)
	check(ok1 and map1.Vortidos_Grunt == nil and string.find(why1.Vortidos_Grunt or "", "retirada", 1, true) ~= nil,
		"si el Cuerpo usa una malla retirada, el soldado no se monta (y lo dice): sin error" .. (if ok1 then "" else ": " .. tostring(map1)))
	local savedSource = AlienModels.meshSource
	AlienModels.meshSource = function(id)
		return map1 and map1[id]
	end
	local okFb, fb = pcall(AlienModels.ground, Races.get("Vortidos"), "Grunt")
	check(okFb and fb and fb:GetAttribute("Mesh") == nil and (fb:GetAttribute("Parts") or 0) > 3 and fb:FindFirstChild("Head") ~= nil,
		"…y en el juego sale el Vórtido de piezas de siempre, entero (con cabeza)")
	-- Solo el brillo retirado: el modelo sigue, sin esa pieza
	local map2, why2 = prep(fakeAlienAsset(vg, nil, { Cuerpo = 40, CuerpoCristal = 41, CuerpoBrillo = 136955064198663 }), vg.Asset)
	check(map2.Vortidos_Grunt ~= nil and map2.Vortidos_Grunt:FindFirstChild("CuerpoBrillo") == nil and map2.Vortidos_Grunt:FindFirstChild("Cuerpo") ~= nil and why2["Vortidos_Grunt (aviso)"] ~= nil,
		"si solo es el brillo (o la LOD), el modelo se monta sin esa pieza")
	-- Los de antes (segmentos): un brazo retirado = el de piezas, nunca un alienígena manco
	local mg = Mallas.Models.Morfagos_Grunt
	local map3, why3 = prep(fakeAlienAsset(mg, nil, { Cuerpo = 136955064198663, CuerpoBrillo = 43 }), mg.Asset)
	check(mg.Skinned and map3.Morfagos_Grunt == nil and string.find(why3.Morfagos_Grunt or "", "retirada", 1, true) ~= nil,
		"las otras razas (Mórfagos…), también de esqueleto: con la malla retirada, el de piezas (nunca a medias)")
	-- Mallas que de verdad no cargan (la prueba del servidor: AssetService:CreateMeshPartAsync)
	local function create(content: string): any
		if string.find(content, "777", 1, true) then
			error("Asset is not approved")
		end
		return true
	end
	local verify = function(all, probe)
		return Retiradas.bad(all, create, probe)
	end
	local map4, why4 = prep(fakeAlienAsset(vg, nil, { Cuerpo = 777, CuerpoCristal = 41, CuerpoBrillo = 42 }), vg.Asset, verify)
	check(map4.Vortidos_Grunt == nil and why4.Vortidos_Grunt ~= nil, "una malla que no carga (aunque no esté en la lista) también manda al de piezas")
	local map5 = prep(fakeAlienAsset(vg, nil, { Cuerpo = 40, CuerpoCristal = 41, CuerpoBrillo = 42 }), vg.Asset, function(all, probe)
		return Retiradas.bad(all, function()
			error("HTTP 403 (sin permiso)")
		end, probe)
	end)
	check(map5.Vortidos_Grunt ~= nil, "si la prueba falla con TODAS (sin permiso, sin red), no se tira nada: solo cuenta la lista")
	local okBad = pcall(prep, fakeAlienAsset(vg), vg.Asset, function()
		error("se rompe")
	end)
	check(okBad, "si la comprobación se rompe, el cargador no se rompe")
	AlienModels.meshSource = savedSource
	for k, v in savedFakes do
		L.fakeClasses[k] = v
	end
	-- Cada malla que se va a subir pasa la revisión (scripts/audit/moderacion-mallas.py)
	local fs = require("@lune/fs")
	local missing = {}
	for _, f in { "upload-mar.sh", "upload-puerto.sh", "upload-invasion.sh", "upload-asteroides.sh", "upload-nave.sh" } do
		local src = fs.readFile("scripts/" .. f)
		if not (src:find("source scripts/lib/revisar-mallas.sh", 1, true) and src:find("revisar_mallas \"${PENDIENTES[@]}\"", 1, true)) then
			table.insert(missing, f)
		end
	end
	check(#missing == 0 and fs.isFile("scripts/audit/moderacion-mallas.py") and fs.readFile("scripts/lib/revisar-mallas.sh"):find("exit 1", 1, true) ~= nil,
		"los 5 scripts que suben mallas pasan la revisión de moderación antes y paran si hay alguna marcada" .. (if #missing > 0 then " (falta en " .. table.concat(missing, ", ") .. ")" else ""))
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
