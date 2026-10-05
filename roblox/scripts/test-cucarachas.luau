-- Prueba de «Bigotes, emperador de Gatonia» (Loco_N2_Bigotes) FUERA de Roblox, con Lune: lo que cuenta
-- la misión se VE y se puede jugar en el móvil.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-cucarachas.luau
--
-- Comprueba que:
--   * la nave (World/Kit/Platillo) es una nave de verdad del tamaño de una furgoneta: casco de platillo,
--     cúpula, luces, patas, rampa que se abre, zumbido, polvo y destello al posarse (no un cubo); y que
--     la misión la usa posada en el patio, con la rampa hacia ti
--   * el aterrizaje (Controllers/Platillos): baja, se posa, abre la rampa; las luces corren
--   * las cucarachas (World/Kit/Cucaracha) son bichos de muchas piezas: seis patas, dos antenas,
--     articulaciones; se les puede dar con un disparo (CanQuery); corretean (Controllers/Cucarachas)
--   * en el combate, ningún enemigo lleva cartel de «Interactuar» (MissionCombat, SceneService,
--     ContextDetector) y el botón de atacar les da (CombatController, CombatService, WeaponService)
--   * la caja de globos ya no es un cubo liso
--   * dar el arma prestada es idempotente (InventoryService.ensure)
--   * cada arma de la barra tiene su propio icono (ninguno es 🔫, que el móvil dibuja como una pistola
--     de agua) y un nombre corto en su casilla

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")

local CFrame, Vector3, Color3, Enum, Instance = roblox.CFrame, roblox.Vector3, roblox.Color3, roblox.Enum, roblox.Instance
local V = Vector3.new

local services = {
	CollectionService = { GetTagged = function() return {} end },
	RunService = {},
}
local function load(path: string, extra: { [string]: any }?)
	local env = setmetatable({
		CFrame = CFrame, Vector3 = Vector3, Color3 = Color3, Enum = Enum, Instance = Instance,
		Vector2 = roblox.Vector2, UDim2 = roblox.UDim2, NumberRange = roblox.NumberRange, NumberSequence = roblox.NumberSequence,
		NumberSequenceKeypoint = roblox.NumberSequenceKeypoint, ColorSequence = roblox.ColorSequence,
		game = { GetService = function(_, name) return services[name] or {} end },
	}, { __index = getfenv(1) })
	for k, v in extra or {} do
		env[k] = v
	end
	return luau.load(fs.readFile(path), { debugName = path, environment = env })()
end

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local function partsOf(model: any): { any }
	local list = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(list, d)
		end
	end
	return list
end

local function bounds(parts: { any }): (any, any)
	local lo, hi = V(1e9, 1e9, 1e9), V(-1e9, -1e9, -1e9)
	for _, p in parts do
		local h = p.Size / 2
		for _, sx in { -1, 1 } do
			for _, sy in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local w = p.CFrame * V(h.X * sx, h.Y * sy, h.Z * sz)
					lo = lo:Min(w)
					hi = hi:Max(w)
				end
			end
		end
	end
	return lo, hi
end

local function named(model: any, name: string): { any }
	local list = {}
	for _, d in model:GetDescendants() do
		if d.Name == name then
			table.insert(list, d)
		end
	end
	return list
end

local function read(path: string): string
	return fs.readFile(path)
end

---------------------------------------------------------------------
print("\n▶ La nave (World/Kit/Platillo)")
local Platillo = load("src/server/World/Kit/Platillo.luau")
local ship = Platillo.build({ Aterriza = true, Hum = "rbxassetid://1", Pilot = Color3.fromRGB(110, 70, 40) })
local shipParts = partsOf(ship)
local lo, hi = bounds(shipParts)
local size = hi - lo
check(#shipParts >= 40, ("Es un modelo de muchas piezas, no un cubo (%d piezas)"):format(#shipParts))
check(size.X >= 18 and size.X <= 26 and size.Z >= 18 and size.Z <= 32, ("Del tamaño de una furgoneta (%.0f × %.0f studs de planta)"):format(size.X, size.Z))
check(size.Y >= 8 and size.Y <= 16, ("Alta como una furgoneta con su cúpula (%.1f studs)"):format(size.Y))
check(lo.Y >= -0.3 and lo.Y <= 0.3, ("Posada: las patas tocan el suelo (y = %.2f)"):format(lo.Y))
local hull = ship:FindFirstChild("Casco")
check(hull and hull:FindFirstChildOfClass("SpecialMesh") and hull.Size.X > hull.Size.Y * 4, "Casco con forma de platillo (elipsoide ancho y plano)")
local dome = ship:FindFirstChild("Cupula")
check(dome and dome.Material == Enum.Material.Glass and dome.Transparency > 0.2 and dome.CFrame.Position.Y > hull.CFrame.Position.Y, "Cúpula de cristal encima")
local lights = 0
for _, p in shipParts do
	if p:GetAttribute("Luz") and p.Material == Enum.Material.Neon then
		lights += 1
	end
end
check(lights == Platillo.LUCES, ("Luces de neón alrededor del borde (%d)"):format(lights))
check(#named(ship, "Pata") == 4 and #named(ship, "Pie") == 4, "Cuatro patas de aterrizaje con sus pies")
local ramp = ship:FindFirstChild("Rampa")
check(ramp ~= nil and typeof(ramp:GetAttribute("Bisagra")) == "CFrame", "Tiene rampa con bisagra (se abre)")
if ramp then
	local hinge, length, open = ramp:GetAttribute("Bisagra"), ramp:GetAttribute("Largo"), ramp:GetAttribute("Abierta")
	local openCf = Platillo.rampaCFrame(hinge, length, 1, open)
	local closedCf = Platillo.rampaCFrame(hinge, length, 0, open)
	local footOpen = openCf * V(0, 0, length / 2)
	check(footOpen.Y < 0.6 and footOpen.Z < -9, ("Abierta llega al suelo, por delante (hacia -Z, hacia ti): punta en y=%.2f z=%.1f"):format(footOpen.Y, footOpen.Z))
	local tipClosed = closedCf * V(0, 0, length / 2)
	check(tipClosed.Y > hinge.Position.Y + length * 0.9, "Cerrada queda de pie, metida en el casco (es la puerta)")
	local midway = Platillo.rampaCFrame(hinge, length, 0.5, open) * V(0, 0, length / 2)
	check(midway.Y > 0, "Al abrirse no atraviesa el suelo (se abre como un puente levadizo)")
end
check(#named(ship, "BordeRampa") == 2 and ship:FindFirstChild("Puerta") ~= nil, "Bordes de luz en la rampa y luz en la puerta")
local hum = nil
for _, d in ship:GetDescendants() do
	if d:IsA("Sound") then
		hum = d
	end
end
check(hum and hum.Looped and hum.PlaybackSpeed < 0.6, "Zumbido grave en bucle")
local dust = named(ship, "Polvo")[1]
check(dust and dust:IsA("ParticleEmitter") and dust.Enabled == false, "Polvo para cuando se posa (lo suelta el cliente)")
check(named(ship, "Destello")[1] ~= nil and named(ship, "LuzMotor")[1] ~= nil, "Destello al posarse y luz del motor")
check(#named(ship, "PilotoCabeza") == 1 and #named(ship, "PilotoAntena") == 2, "Se ve a la cucaracha piloto en la cúpula")
check(ship:HasTag(Platillo.TAG) and ship:GetAttribute("Aterriza") == true, "Etiqueta Platillo (el cliente la anima)")
local hover = Platillo.build({ Height = 20 })
check(hover:FindFirstChild("Rayo") ~= nil and hover:FindFirstChild("Casco").CFrame.Position.Y >= 19 and not hover:FindFirstChild("Rampa") and not hover:FindFirstChild("Pata"), "La que flota (otras misiones): sin patas, con su rayo tractor")
local cubeLike = 0
for _, p in shipParts do
	if p.Size.X >= 4 and math.abs(p.Size.X - p.Size.Y) < 0.1 and math.abs(p.Size.Y - p.Size.Z) < 0.1 and p.Shape == Enum.PartType.Block and not p:FindFirstChildOfClass("SpecialMesh") then
		cubeLike += 1
	end
end
check(cubeLike == 0, "Ninguna pieza grande es un cubo")

print("\n▶ Aterrizaje (Controllers/Platillos)")
local Platillos = load("src/client/Controllers/Platillos.luau")
local start = Platillos.landing(0)
check(start.height >= 40 and start.ramp == 0 and not start.landed, "Empieza en el cielo con la rampa cerrada")
local mid = Platillos.landing(Platillos.DESCENT / 2)
check(mid.height > 0 and mid.height < start.height, "Va bajando")
local touch = Platillos.landing(Platillos.DESCENT + 0.05)
check(touch.landed and touch.flash > 0.8 and touch.ramp == 0, "Al posarse: destello (y polvo), la rampa aún cerrada")
local opened = Platillos.landing(Platillos.DESCENT + Platillos.RAMP_DELAY + Platillos.RAMP_TIME + 0.1)
check(opened.ramp >= 1 and math.abs(opened.height) < 0.01 and opened.flash == 0, "Luego abre la rampa del todo y se queda quieta")
local onCount = 0
for i = 1, 12 do
	if Platillos.lightOn(i, 12, 1.23) then
		onCount += 1
	end
end
local moved = false
for i = 1, 12 do
	if Platillos.lightOn(i, 12, 1.23) ~= Platillos.lightOn(i, 12, 1.53) then
		moved = true
	end
end
check(onCount == 3 and moved, "Las luces del borde corren en círculo (3 encendidas que avanzan)")

---------------------------------------------------------------------
print("\n▶ Las cucarachas (World/Kit/Cucaracha)")
local Cucaracha = load("src/server/World/Kit/Cucaracha.luau")
local bug = Cucaracha.build(7, nil, { Gorra = Color3.fromRGB(70, 90, 50), Medallas = 6 })
local bugParts = partsOf(bug)
local blo, bhi = bounds(bugParts)
check(#bugParts >= 35, ("Un bicho de muchas piezas (%d), no un cubo ni una persona"):format(#bugParts))
local femurs, tibias, antennas = 0, 0, 0
for _, p in bugParts do
	if string.sub(p.Name, 1, 5) == "Femur" then
		femurs += 1
	elseif string.sub(p.Name, 1, 5) == "Tibia" then
		tibias += 1
	elseif string.sub(p.Name, 1, 6) == "Antena" then
		antennas += 1
	end
end
check(femurs == 6 and tibias == 6, "Seis patas de dos tramos")
check(antennas == 4, "Dos antenas largas (de dos tramos)")
local motors = {}
for _, d in bug:GetDescendants() do
	if d:IsA("Motor6D") then
		motors[d.Name] = true
	end
end
local legMotors = 0
for name in motors do
	if string.sub(name, 1, 6) == "M_Pata" then
		legMotors += 1
	end
end
check(legMotors == 6 and motors.M_AntenaL and motors.M_AntenaR and motors.M_Cabeza, "Articulaciones en patas, antenas y cabeza (para corretear)")
check(blo.Y >= -0.05 and blo.Y <= 0.3, "Las patas en el suelo")
check(bhi.Z - blo.Z > bhi.Y - blo.Y and bhi.X - blo.X > 4, "Es un bicho tumbado y ancho de patas (no una figura de pie)")
local queryable = true
for _, p in bugParts do
	if not p.CanQuery or p.CanCollide then
		queryable = false
	end
end
check(queryable, "Todas sus piezas se pueden tocar con un disparo (CanQuery) y no estorban (CanCollide = false)")
check(#named(bug, "Gorra") == 1 and #named(bug, "Medalla") == 6, "El sargento lleva gorra y seis medallas")
check(bug:HasTag(Cucaracha.TAG), "Etiqueta Cucaracha (el cliente la anima)")

-- Disfraz sobre un personaje (como SceneService con Cast.Body = "Cucaracha")
local rig = Instance.new("Model")
local root = Instance.new("Part")
root.Name = "HumanoidRootPart"
root.Size = V(2, 2, 1)
root.CFrame = CFrame.new(10, 3, 5)
root.Parent = rig
local torso = Instance.new("Part")
torso.Name = "UpperTorso"
torso.Size = V(2, 2, 1)
torso.Parent = rig
local hum = Instance.new("Humanoid")
hum.HipHeight = 2
hum.Parent = rig
local costume = Cucaracha.costume(rig, { Color = Color3.fromRGB(110, 70, 40) })
check(costume and costume.Parent == rig and torso.Transparency == 1, "Disfraza al personaje: el cuerpo de persona no se ve")
local weld = costume and costume.PrimaryPart:FindFirstChild("CucarachaPies")
check(weld and weld.Part0 == root, "La cucaracha va soldada al personaje (anda, persigue y recibe los disparos con él)")
local clo = bounds(partsOf(costume))
check(math.abs(clo.Y - 0) < 0.4, "Con los pies del personaje en el suelo")

print("\n▶ Corretean (Controllers/Cucarachas)")
local Cucarachas = load("src/client/Controllers/Cucarachas.luau")
local still = Cucarachas.pose(1, 0, 0)
local run1 = Cucarachas.pose(1, 12, 0)
local run2 = Cucarachas.pose(1.03, 12, 0)
local stillLegs = true
for name, cf in still do
	if string.sub(name, 1, 6) == "M_Pata" then
		local _, y = cf:ToEulerAnglesXYZ()
		if math.abs(y) > 1e-3 then
			stillLegs = false
		end
	end
end
check(stillLegs, "Quieta: las patas quietas")
local _, a1 = run1.M_PataDelanteraL:ToEulerAnglesXYZ()
local _, a2 = run2.M_PataDelanteraL:ToEulerAnglesXYZ()
local _, b1 = run1.M_PataDelanteraR:ToEulerAnglesXYZ()
check(math.abs(a1 - a2) > 0.05, "Corriendo: las patas van y vienen muy deprisa")
check(a1 * b1 < 0, "En trípodes alternos (un lado adelante y el otro atrás)")
local x1 = run1.M_AntenaL:ToEulerAnglesXYZ()
local x2 = still.M_AntenaL:ToEulerAnglesXYZ()
check(math.abs(x1) > 0 or math.abs(x2) > 0, "Las antenas se agitan")

---------------------------------------------------------------------
print("\n▶ La misión la usa (Loco_N2_Bigotes, Cast, SceneService)")
local scene = read("src/server/Services/SceneService.luau")
local cast = read("src/shared/LifeStory/Cast.luau")
local mision = read("src/shared/LifeStory/Misiones/Loco_Nino.luau")
check(string.find(scene, "Platillo.build(", 1, true) ~= nil, "El objeto Kind = \"Nave\" se construye con World/Kit/Platillo")
check(string.find(scene, "Cucaracha.costume", 1, true) ~= nil and string.find(cast, 'Cucaracha1 = { Name = "Crujo", Voice = "Profe", Kid = true, Body = "Cucaracha"', 1, true) ~= nil, "Las tres cucarachas (Cast) llevan el cuerpo de cucaracha")
check(string.find(cast, 'Cucaracha3 = { Name = "Sargento Patitas", Voice = "Abu", Kid = true, Body = "Cucaracha"', 1, true) ~= nil, "…también el sargento")
check(string.find(mision, 'Nave = { Kind = "Nave", Aterriza = true', 1, true) ~= nil, "En el patio la nave ATERRIZA (antes flotaba a 14 studs, fuera de la cámara)")
check(string.find(mision, 'Globos = { Kind = "Globos"', 1, true) ~= nil and string.find(scene, "Globos = function", 1, true) ~= nil, "La caja de globos de agua es una caja con globos (antes, un cubo azul)")
-- Las cucarachas salen por la rampa: la nave a -21 del patio, la rampa hacia ti, ellas delante
local QuestsSrc = mision
local navZ = tonumber(string.match(QuestsSrc, 'Aterriza = true[^\n]-Place = "Patio", Offset = V%(0, 0, (%-?%d+)%)'))
check(navZ ~= nil and navZ <= -19, "La nave, en un lado del patio (sus patas no pisan a las cucarachas)")
local roachZ = {}
for z in string.gmatch(QuestsSrc, '{ Npc = "Cucaracha%d", Offset = V%(%-?%d+, 0, (%-?%d+)%)') do
	table.insert(roachZ, tonumber(z))
end
local outside = #roachZ >= 3
for _, z in roachZ do
	-- Fuera del casco (radio 10), delante de la rampa
	if navZ == nil or z < navZ + 10 then
		outside = false
	end
end
check(outside, "Las cucarachas aparecen delante de la rampa, fuera del casco")

---------------------------------------------------------------------
print("\n▶ Enemigos sin cartel de «Interactuar» (MissionCombat)")
local MissionCombat = load("src/shared/MissionCombat.luau")
check(MissionCombat.wantsPrompt({ Npc = "Bigotes" }) == true, "Un personaje normal lleva su cartel (Hablar)")
check(MissionCombat.wantsPrompt({ Npc = "Cucaracha1", Enemy = true, Action = "Lanzar globo de agua 🎈" }) == false, "Un enemigo nunca lleva cartel (aunque tenga Action)")
local enemy = Instance.new("Model")
local eroot = Instance.new("Part")
eroot.Parent = enemy
local stale = Instance.new("ProximityPrompt")
stale.Parent = eroot
check(MissionCombat.blocksPrompt(stale) == false, "Sin marcar, su cartel no se toca")
MissionCombat.mark(enemy, "Loco_N2_Bigotes", 42)
check(MissionCombat.isEnemy(enemy) and enemy:GetAttribute("Owner") == 42 and enemy:HasTag("MissionEnemy"), "Marcado como enemigo (del jugador 42, con etiqueta)")
check(MissionCombat.blocksPrompt(stale) == true, "Un cartel que cuelgue de un enemigo se apaga (no le quita el sitio al botón de atacar)")
MissionCombat.mark(enemy, nil)
check(not MissionCombat.isEnemy(enemy) and not enemy:HasTag("MissionEnemy"), "Se desmarca al acabar")
check(#MissionCombat.mine({ enemy }, 42) == 0, "Desmarcado ya no cuenta como enemigo")
MissionCombat.mark(enemy, "Loco_N2_Bigotes", 42)
enemy.Parent = Instance.new("Folder")
check(#MissionCombat.mine({ enemy }, 42) == 1 and #MissionCombat.mine({ enemy }, 7) == 0, "Cada jugador solo ve (y ataca) a sus enemigos")
local list = { { P = V(30, 0, 0) }, { P = V(12, 0, 5) }, { P = V(60, 0, 0) } }
local best = MissionCombat.nearest(list, V(0, 0, 0), MissionCombat.Range, function(e) return e.P end)
check(best == list[2], "El botón de atacar le da al más cercano")
check(MissionCombat.nearest(list, V(200, 0, 0), MissionCombat.Range, function(e) return e.P end) == nil, "Si no hay nadie a tiro, el botón golpea como siempre")
check(MissionCombat.aimed(V(0, 2, 0), V(0, 0, -1), V(1, 1.5, -20), 45), "Un disparo que pasa rozando a una cucaracha le da (ayuda al apuntar)")
check(not MissionCombat.aimed(V(0, 2, 0), V(0, 0, -1), V(15, 1.5, -20), 45), "Uno que va lejos, no")
check(not MissionCombat.aimed(V(0, 2, 0), V(0, 0, -1), V(0, 1.5, -60), 45), "Más allá del alcance del arma, no")
check(MissionCombat.ready(nil, 0) and not MissionCombat.ready(10, 10.1) and MissionCombat.ready(10, 10 + MissionCombat.HitGap), "Ritmo máximo de impactos (la pistola de agua no tumba a nadie en un parpadeo)")

local combat = read("src/server/Services/CombatService.luau")
local weapon = read("src/server/Services/WeaponService.luau")
local ctrl = read("src/client/Controllers/CombatController.luau")
local detector = read("src/client/Commands/ContextDetector.luau")
local story = read("src/server/Services/LifeStoryService.luau")
check(string.find(scene, "MissionCombat.wantsPrompt(spec)", 1, true) ~= nil, "SceneService: el cartel solo si MissionCombat.wantsPrompt (nunca en un enemigo)")
check(string.find(story, "spec.Enemy = true", 1, true) ~= nil and string.find(story, "spec.Prompt = false", 1, true) ~= nil, "LifeStoryService: los enemigos de un paso Fight van sin cartel")
check(string.find(detector, "MissionCombat.blocksPrompt(instance)", 1, true) ~= nil and string.find(detector, "not MissionCombat.blocksPrompt(prompt)", 1, true) ~= nil, "El botón de Interactuar nunca ofrece a un enemigo")
check(string.find(combat, "local mission = missionTarget(attacker, model)", 1, true) ~= nil and string.find(combat, "local mission = missionTarget(att.Player, model)", 1, true) ~= nil, "Disparos y golpes a un enemigo de misión cuentan en el combate (CombatService)")
check(string.find(weapon, "missionAim", 1, true) ~= nil, "Las armas (también la pistola de agua) tienen ayuda al apuntar a los enemigos de misión")
check(string.find(ctrl, 'FireServer("Attack")', 1, true) ~= nil and string.find(ctrl, 'TouchLayout.setLabel("Ataque"', 1, true) ~= nil, "El botón grande de atacar le da al enemigo (y dice «Atacar»)")
check(string.find(story, 'kind == "Attack"', 1, true) ~= nil and string.find(story, "CombatService.missionHit = LifeStoryService.hitModel", 1, true) ~= nil, "El servidor atiende el botón de atacar y los impactos")

---------------------------------------------------------------------
print("\n▶ Préstamos idempotentes (InventoryService.ensure)")
local data = { Items = {}, Slots = {} }
L.mock("src/server/Services/DataService", { get = function() return data end, onLoaded = function() end })
L.mock("src/server/Services/NeedsService", {})
L.services.Players = { GetPlayers = function() return {} end, PlayerRemoving = { Connect = function() end } }
L.services.ReplicatedStorage.Remotes = {
	WaitForChild = function(self, name) return { FireClient = function() end } end,
	FindFirstChild = function() return nil end,
}
local okInv, Inventory = pcall(L.load, "src/server/Services/InventoryService")
if okInv then
	local fakePlayer = { GetAttribute = function() return nil end, SetAttribute = function() end }
	local has1, given1 = Inventory.ensure(fakePlayer, "RayoEncogedor")
	local has2, given2 = Inventory.ensure(fakePlayer, "RayoEncogedor")
	Inventory.ensure(fakePlayer, "RayoEncogedor")
	check(has1 and given1 and has2 and not given2 and data.Items.RayoEncogedor == 1, "Dar el arma prestada varias veces (cada paso, reaparecer, volver a entrar): solo una")
else
	check(false, "InventoryService se carga: " .. tostring(Inventory))
end

---------------------------------------------------------------------
print("\n▶ Iconos de las armas (barra rápida)")
local Items = L.load("src/shared/Items")
local seen, dup, gun = {}, {}, {}
local tagsOk = true
for id, item in Items.List do
	if item.Kind == "Weapon" or item.Kind == "Gadget" then
		if seen[item.Icon] then
			table.insert(dup, ("%s/%s %s"):format(seen[item.Icon], id, item.Icon))
		end
		seen[item.Icon] = id
		if item.Icon == "🔫" then
			table.insert(gun, id)
		end
		if item.Kind == "Weapon" and (type(item.Tag) ~= "string" or item.Tag == "" or #item.Tag > 12) then
			tagsOk = false
		end
	end
end
check(#dup == 0, "Ningún arma ni gadget comparte icono con otro" .. (if #dup > 0 then " (" .. table.concat(dup, ", ") .. ")" else ""))
check(#gun == 0, "Ninguno usa 🔫 (el móvil lo dibuja como una pistola de agua)" .. (if #gun > 0 then ": " .. table.concat(gun, ", ") else ""))
check(tagsOk, "Cada arma tiene un nombre corto para su casilla (Tag)")
local tags = {}
local tagDup = false
for _, item in Items.List do
	if item.Kind == "Weapon" then
		if tags[item.Tag] then
			tagDup = true
		end
		tags[item.Tag] = true
	end
end
check(not tagDup, "…y no se repite")
local inv = read("src/client/Controllers/InventoryUI.luau")
check(string.find(inv, "drawWeapon(view, weaponRef)", 1, true) ~= nil and string.find(inv, "item.Tag", 1, true) ~= nil, "La casilla dibuja el arma de verdad (sus piezas) y su nombre corto")
check(string.find(inv, "InventoryUI.describe(i)", 1, true) ~= nil, "Mantener pulsada una casilla (móvil) dice qué es")

print(if failures == 0 then "\n✅ Todo bien" else ("\n❌ %d fallos"):format(failures))
process.exit(if failures == 0 then 0 else 1)
