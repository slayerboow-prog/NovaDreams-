-- Prueba de las armas, el ejército y las zonas de terror de Sebastián (World/UserArsenal y
-- World/Kit/Pliegues) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):  lune run scripts/test-arsenal.luau
--
-- Los packs de mentira imitan lo que dice docs/assets-usuario*.md (Tool con «GunScript» que echaba
-- del juego, decals de sangre, armas de otros juegos mezcladas, el «Cee Four», el tanque con decals sin
-- revisar, el cámara «Nikon»…). Comprueba que:
--   * se borran TODOS los scripts, sonidos, valores, GUIs y decals de sangre/marcas; los nombres quedan
--     genéricos (ni armas reales, ni marcas, ni SCP); las armas de otros juegos y los cuchillos no entran
--   * cada arma va a su clase (pistola, fusil, francotirador…) y su plantilla mira con el cañón en X
--   * la colocación tiene sentido: dentro de la armería, en el armero y derechas; el armero policial
--     y la prueba del explosivo dentro de la comisaría; el carro del museo de 22 studs; etc.
--   * las criaturas persiguen, alcanzan sin hacer daño y pasean si no hay nadie
--   * si nada carga (o la carga revienta), no hay errores y no se pone nada

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Enum, Vector3, CFrame, Color3, Instance = roblox.Enum, roblox.Vector3, roblox.CFrame, roblox.Color3, roblox.Instance

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local MESH, LOADER, BUILDER, MARKS, PLIEGUES = {}, {}, {}, {}, {}
local modules: { [any]: any } = {}
local function load(path: string, scriptEnv: any): any
	local env = setmetatable({
		Enum = Enum, Vector3 = Vector3, CFrame = CFrame, Color3 = Color3, Instance = Instance,
		UDim2 = roblox.UDim2, UDim = roblox.UDim,
		warn = function() end, print = function() end,
		script = scriptEnv or {},
		require = function(m)
			local found = modules[m]
			if found == nil then
				error("require inesperado")
			end
			return found
		end,
	}, { __index = getfenv(1) })
	return luau.load(fs.readFile(path), { debugName = path, environment = env })()
end

modules[MESH] = load("src/server/World/MeshLibrary.luau")
modules[BUILDER] = load("src/server/World/Builder.luau")
modules[MARKS] = load("src/server/World/Kit/StoryMarks.luau", { Parent = { Parent = { Builder = BUILDER } } })
modules[LOADER] = { download = function() return nil end }
local Pliegues = load("src/server/World/Kit/Pliegues.luau", { Parent = { Parent = { Builder = BUILDER }, StoryMarks = MARKS } })
modules[PLIEGUES] = Pliegues
local A = load("src/server/World/UserArsenal.luau", { Parent = { MeshLibrary = MESH, AssetLoader = LOADER, Kit = { Pliegues = PLIEGUES } } })

---------------------------------------------------------------------
-- Packs de mentira
---------------------------------------------------------------------
local function part(parent: Instance, name: string, size: Vector3, pos: Vector3, class: string?): BasePart
	local p = Instance.new(class or "Part")
	p.Name = name
	p.Size = size
	p.CFrame = CFrame.new(pos)
	p.Parent = parent
	return p
end
local function add(parent: Instance, class: string, name: string): Instance
	local i = Instance.new(class)
	i.Name = name
	i.Parent = parent
	return i
end
local function decal(parent: Instance, name: string)
	local d = Instance.new("Decal")
	d.Name = name
	d.Texture = "rbxassetid://1"
	d.Parent = parent
end
-- Un arma: cañón largo en Z (mundo), cuerpo arriba y empuñadura que cuelga
local function gun(parent: Instance, class: string, name: string, length: number): Instance
	local m = Instance.new(class)
	m.Name = name
	part(m, "Barrel", Vector3.new(0.3, 0.4, length), Vector3.new(0, 1, 0), "MeshPart")
	part(m, "Body", Vector3.new(0.35, 0.6, length * 0.4), Vector3.new(0, 0.8, 0))
	part(m, "Grip", Vector3.new(0.25, 0.7, 0.3), Vector3.new(0, 0.3, length * 0.15))
	m.Parent = parent
	return m
end

local function weaponPack(): Instance
	local root = Instance.new("Model")
	local tool = gun(root, "Tool", "Golden Desert Eagle Ban Gun", 1.4)
	add(tool, "Script", "GunScript")
	add(tool:FindFirstChild("Body") :: Instance, "Sound", "Fire")
	add(tool, "IntValue", "Ammo")
	decal(tool:FindFirstChild("Body") :: Instance, "BloodEffect")
	local folder = add(root, "Folder", "Gun Models With Tool")
	gun(folder, "Model", "M4A1", 3.6)
	gun(folder, "Model", "Wingman", 1.5) -- de Apex: fuera
	gun(folder, "Model", "Karambit", 1) -- cuchillo: fuera
	local awp = part(folder, "AWP", Vector3.new(0.4, 0.8, 5), Vector3.new(0, 1, 0), "MeshPart")
	add(awp, "LocalScript", "Virus")
	local packWithModels = add(root, "Model", "ShotgunPack")
	gun(packWithModels, "Model", "SPAS-12", 3.2)
	add(root, "ModuleScript", "MainModule")
	return root
end

local function prop(name: string, size: Vector3): Instance
	local root = Instance.new("Model")
	local m = Instance.new("Model")
	m.Name = name
	part(m, name, size, Vector3.new(5, size.Y / 2, 5), "MeshPart")
	m.Parent = root
	add(m, "Script", "Giver")
	return root
end

local function tank(): Instance
	local root = Instance.new("Model")
	local m = add(root, "Model", "[FBF] Panzer IV")
	local hull = part(m, "Hull", Vector3.new(16, 8, 60), Vector3.new(0, 4, 0))
	part(m, "Turret", Vector3.new(10, 6, 14), Vector3.new(0, 11, 0))
	decal(hull, "RA")
	decal(hull, "Decal")
	part(m, "Seat", Vector3.new(2, 1, 2), Vector3.new(0, 9, 0), "VehicleSeat")
	add(m, "Script", "TankScript")
	return root
end

local function cameraman(): Instance
	local root = Instance.new("Model")
	local m = add(root, "Model", "Cameraman")
	local torso = part(m, "Torso", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0))
	torso.CFrame = CFrame.new(0, 3, 0) * CFrame.Angles(0, math.rad(90), 0)
	part(m, "Head", Vector3.new(2, 1, 1), Vector3.new(0, 4.5, 0))
	part(m, "Left Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, 1, 0))
	part(m, "Nikon", Vector3.new(1, 1, 2), Vector3.new(1, 4, 0))
	add(m, "Humanoid", "Humanoid")
	add(m, "LocalScript", "Animate")
	return root
end

local Props = A.Props
local packs: { [number]: () -> Instance } = {}
for _, p in A.WeaponPacks do
	packs[p.Id] = weaponPack
end
packs[Props.MiraPuntoRojo] = function() return prop("Red Dot Sight", Vector3.new(1.2, 1.2, 1.1)) end
packs[Props.PistolaGato] = function() return prop("Cat Gun", Vector3.new(1, 1.2, 2)) end
packs[Props.MazoGoma] = function() return prop("mallet", Vector3.new(0.9, 3.9, 1.4)) end
packs[Props.Bate] = function() return prop("Baseball_Bat", Vector3.new(4.4, 0.3, 0.3)) end
packs[Props.Explosivo] = function() return prop("Cee Four", Vector3.new(1.7, 0.5, 0.8)) end
packs[Props.CascoMilitar] = function() return prop("SSH68", Vector3.new(1.2, 0.8, 1.4)) end
packs[Props.CarroCombate] = tank
packs[Props.Camarografo] = cameraman
local requested = {}
local function getter(id: number): Instance?
	table.insert(requested, id)
	local f = packs[id]
	return f and f() or nil
end

---------------------------------------------------------------------
print("▶ Limpieza y clases de las armas")
local lib = A.load(getter)
check(#requested == #A.WeaponPacks + 8, "pide cada pack de armas y cada objeto una vez (el muerto no)")
check(not table.find(requested, 7105428424), "el «dead guy» (sangre) no se carga")
local all = {}
for kind, list in lib.Weapons do
	for _, t in list do
		table.insert(all, t)
		check(t.Kind == kind, kind .. ": " .. t.Name)
	end
end
check(lib.Weapons.Pistola and lib.Weapons.Fusil and lib.Weapons.Francotirador and lib.Weapons.Escopeta, "hay pistolas, fusiles, francotiradores y escopetas")
local bad, names, scripts = 0, 0, 0
for _, t in all do
	for _, d in t.Model:GetDescendants() do
		if d:IsA("LuaSourceContainer") then
			scripts += 1
		end
		if d:IsA("Sound") or d:IsA("ValueBase") or d:IsA("Decal") then
			bad += 1
		end
		if A.isBanned(d.Name) or string.find(string.lower(d.Name), "wingman") or string.find(string.lower(d.Name), "m4a1") or string.find(string.lower(d.Name), "awp") then
			names += 1
		end
	end
	check(not string.find(t.Name, "Glock") and string.find(t.Name, "^Arma_"), "nombre genérico: " .. t.Name)
end
check(scripts == 0, "ningún script en las armas")
check(bad == 0, "ni sonidos, ni valores, ni decals (sangre)")
check(names == 0, "ningún nombre real ni de otro juego")
local skipped = true
for _, t in all do
	if t.Kind == "Pistola" and t.Size.X < 1.2 then
		skipped = false -- (el cuchillo mide 1 y el Wingman 1.5: no tienen que estar)
	end
end
check(skipped and #(lib.Weapons.Pistola or {}) <= A.MaxPerKind, "fuera cuchillos y armas de Apex")
local rifle = lib.Weapons.Fusil[1]
check(rifle.Size.X > rifle.Size.Y and rifle.Size.Y >= rifle.Size.Z, "la plantilla tiene X = largo, Y = alto, Z = grosor")
check(rifle.Pivot.UpVector.Y > 0.9, "el «arriba» del arma es donde está el cuerpo (empuñadura abajo)")
check(A.classify("Holger26", Vector3.new(0.3, 1, 4)) == nil and A.classify("Model", Vector3.new(1, 1, 1)) == nil, "armas de CoD y cajas sin forma de arma: fuera")
check(A.classify("Riot Shield", Vector3.new(3, 4, 0.3)) == "Escudo" and A.classify("Mosin", Vector3.new(0.3, 0.6, 5)) == "Francotirador", "escudos y rifles por su nombre")

print("▶ Objetos sueltos")
for name in Props do
	check(lib.Props[name] ~= nil, name .. " cargado")
end
local tankT = lib.Props.CarroCombate
local decals, seats, tankNames = 0, 0, 0
for _, d in tankT.Model:GetDescendants() do
	if d:IsA("Decal") or d:IsA("Texture") then
		decals += 1
	end
	if d:IsA("Seat") or d:IsA("VehicleSeat") then
		seats += 1
	end
	if string.find(string.lower(d.Name), "panzer") then
		tankNames += 1
	end
end
check(decals == 0 and seats == 0 and tankNames == 0, "carro de combate: sin ninguna imagen (las de la torreta no se podían revisar), sin asiento y sin su nombre")
check(tankT.Model.Name == "CarroCombate", "el carro se llama en español")
local cam = lib.Props.Camarografo
check(cam.Model:FindFirstChild("Nikon", true) == nil and cam.Model:FindFirstChildWhichIsA("Humanoid", true) ~= nil, "cámara: sin la marca, con su Humanoid (para la ropa)")
check(cam.Model:FindFirstChildWhichIsA("LuaSourceContainer", true) == nil, "cámara: sin el Animate")
check(lib.Props.Explosivo.Model:FindFirstChild("Cee Four", true) == nil, "el explosivo ya no se llama «Cee Four»")

print("▶ Colocación")
local function inside(model: Instance, origin: CFrame, lo: Vector3, hi: Vector3): boolean
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			local p = origin:PointToObjectSpace(d.CFrame.Position)
			if p.X < lo.X or p.X > hi.X or p.Y < lo.Y or p.Y > hi.Y or p.Z < lo.Z or p.Z > hi.Z then
				return false
			end
		end
	end
	return true
end
-- Armería: W = 36, D = 34 (la de Districts), girada
local shop = Instance.new("Model")
shop.Name = "Armeria"
local shopCf = CFrame.new(300, 0.6, -120) * CFrame.Angles(0, math.rad(90), 0)
part(shop, "GunShopCounter", Vector3.new(14, 3.2, 2.4), Vector3.zero).CFrame = shopCf * CFrame.new(4, 1.6, -4)
local n = A.dressGunShop(shop, lib)
check(n >= 9, ("armería: %d mallas puestas"):format(n))
local shown = shop:FindFirstChild("ExpositorMallas") :: Instance
check(inside(shown, shopCf, Vector3.new(-18, 0, -17), Vector3.new(18, 12, 0)), "todo dentro de la tienda (la mitad de delante, no en la galería de tiro)")
local upright, onRack = true, 0
for _, m in shown:GetChildren() do
	if m.Name == "ArmaExpuesta" then
		local parts = {}
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				table.insert(parts, d)
			end
		end
		local lo, hi = modules[MESH].bounds(parts)
		local c = shopCf:PointToObjectSpace((lo + hi) / 2)
		if c.X < -17 or c.X > -15 or c.Y < 5.5 or c.Y > 9.5 then
			upright = false
		end
		onRack += 1
		-- La pieza «Grip» se llama ahora «Pieza»: se mira que el cuerpo quede por encima del centro
		local wv = 0
		local sum = 0
		for _, p in parts do
			local v = p.Size.X * p.Size.Y * p.Size.Z
			sum += (p.CFrame.Position.Y - (lo.Y + hi.Y) / 2) * v
			wv += v
		end
		if sum < 0 then
			upright = false
		end
	end
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and not d:HasTag("PropDetail") then
			upright = false
		end
	end
end
check(onRack == 6 and upright, "6 armas largas en el armero, derechas y con la etiqueta PropDetail (se ven también en Bajo)")
check(A.dressGunShop(shop, lib) == 0, "no se pone dos veces")

-- Comisaría: W = 44, D = 30
local station = Instance.new("Model")
local stationCf = CFrame.new(-375, 0.6, 625) * CFrame.Angles(0, math.rad(180), 0)
part(station, "FrontDesk", Vector3.new(10, 3.6, 2.4), Vector3.zero).CFrame = stationCf * CFrame.new(11, 1.8, -8)
part(station, "Emblem", Vector3.new(3, 3, 0.1), Vector3.zero).CFrame = stationCf * CFrame.new(0, 8, 14.4)
check(A.dressPoliceStation(station, lib) >= 4, "comisaría: armero con armas y la prueba del explosivo")
local armory = station:FindFirstChild("ArmeroPolicial") :: Instance
check(inside(armory, stationCf, Vector3.new(-22, 0, -15), Vector3.new(22, 9, 15)), "todo dentro de la comisaría")
check(armory:FindFirstChild("PruebaExplosivo") ~= nil, "el explosivo está como prueba desactivada")

-- Salas
local function room(name: string, w: number, d: number, attrs: { [string]: any }?): (Model, CFrame)
	local r = Instance.new("Model")
	r.Name = name
	local cf = CFrame.new(0, 3000, 400)
	part(r, "Floor", Vector3.new(w, 1, d), Vector3.zero).CFrame = cf * CFrame.new(0, -0.5, 0)
	for k, v in attrs or {} do
		r:SetAttribute(k, v)
	end
	return r, cf
end
local cuartel, ccf = room("Interior_Cuartel", 90, 70)
add(cuartel, "Part", "RifleRack")
check(A.dressCuartel(cuartel, lib) >= 7, "cuartel: fusiles en el armero y cascos")
check(inside(cuartel:FindFirstChild("MallasCuartel") :: Instance, ccf, Vector3.new(-45, 0, -35), Vector3.new(45, 18, 35)), "cuartel: todo dentro de la sala")
check((cuartel:FindFirstChild("RifleRack") :: BasePart).Transparency == 1, "las barras de antes se esconden")
local museo, mcf = room("Interior_Museo", 90, 60)
check(A.dressMuseo(museo, lib) == 1, "museo: el carro de combate")
local tankModel = (museo:FindFirstChild("CarroCombateMuseo") :: Instance):FindFirstChild("CarroDeCombate") :: Instance
do
	local parts = {}
	for _, d in tankModel:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		end
	end
	local lo, hi = modules[MESH].bounds(parts)
	local size = hi - lo
	check(math.abs(math.max(size.X, size.Z) - 22) < 0.5 and size.X > size.Z, ("carro de 22 studs a lo largo de la sala (%.1f × %.1f)"):format(size.X, size.Z))
	check(inside(tankModel, mcf, Vector3.new(-45, 0, -30), Vector3.new(45, 20, 30)), "el carro cabe en el museo")
end
local teatro = room("Interior_Teatro", 80, 70)
check(A.dressTeatro(teatro, lib) == 1, "teatro: el cámara")
local deportes = room("Interior_Local", 40, 30, { Shop = "Deportes" })
check(A.dressDeportes(deportes, lib) == 4, "tienda de deportes: 4 bates")
local feria = Instance.new("Model")
part(feria, "Booth", Vector3.new(10, 8, 6), Vector3.new(3000, 4, -2000))
check(A.dressFeria(feria, lib) == 4, "feria: 3 pistolas-gato de premio y el mazo")

print("▶ Criaturas (sin daño)")
local zone = { Name = "Amarillo", Origin = Vector3.new(0, 0, 0), Lo = Vector3.new(-50, 0, -50), Hi = Vector3.new(50, 20, 50), Spawn = CFrame.new(0, 3, 0), Model = Instance.new("Model") }
local cm = Instance.new("Model")
local body = part(cm, "Cuerpo", Vector3.new(2, 8, 1), Vector3.new(20, 4, 20))
local creature = { Model = cm, Parts = { body }, Rel = { CFrame.new(0, 4, 0) }, Pivot = CFrame.new(20, 0, 20), Zone = zone, Speed = 10, Text = "", Rest = 0 }
local rand = function() return 0.25 end
local who = { Name = "Ana" }
local caught = nil
for _ = 1, 60 do
	caught = Pliegues.step(creature, 0.1, { { who, Vector3.new(0, 3, 0) } }, rand)
	if caught then
		break
	end
end
check(caught == who, "persigue y alcanza al jugador (en unos segundos)")
check(Pliegues.step(creature, 0.1, { { who, Vector3.new(0, 3, 0) } }, rand) == nil, "después descansa (no te vuelve a coger enseguida)")
creature.Rest = 0
local before = creature.Pivot.Position
for _ = 1, 10 do
	Pliegues.step(creature, 0.1, {}, rand)
end
check((creature.Pivot.Position - before).Magnitude > 0.5 and creature.Goal ~= nil, "sin nadie cerca, pasea por su pliegue")
check(math.abs(body.CFrame.Position.Y - 4) < 0.01, "no se hunde ni vuela")
check(Pliegues.inside(Vector3.new(10, 5, 10), zone) and not Pliegues.inside(Vector3.new(100, 5, 10), zone), "sabe quién está en su pliegue")
local stairs = Instance.new("Model")
for i = 0, 99 do
	part(stairs, "Step", Vector3.new(4, 1, 4), Vector3.new(0, i * 5, 0))
end
check(Pliegues.cropTop(stairs, 70, A) == 86 and #stairs:GetChildren() == 14, "la escalera se queda con sus últimos 70 studs")
local zoneBuilt = Pliegues.buildZone(Instance.new("Model"), "Piso13", nil, A)
check(zoneBuilt.Model:FindFirstChild("Suelo") ~= nil and zoneBuilt.Spawn.Position.Y > Pliegues.Origin.Y, "sin kit, el pliegue es una sala vacía con suelo")

print("▶ Si nada carga")
local empty = A.load(function()
	return nil
end)
local any = next(empty.Weapons) ~= nil or next(empty.Props) ~= nil
check(not any, "sin carga: biblioteca vacía")
local boom = A.load(function()
	error("HTTP 403")
end)
check(next(boom.Weapons) == nil and next(boom.Props) == nil, "si la carga revienta: sin errores")
local shop2 = Instance.new("Model")
part(shop2, "GunShopCounter", Vector3.new(14, 3.2, 2.4), Vector3.zero)
local ok = pcall(function()
	A.dressGunShop(shop2, empty)
	A.dressPoliceStation(station:Clone(), empty)
	A.dressMuseo(room("Interior_Museo", 90, 60), empty)
	A.dressTeatro(room("Interior_Teatro", 80, 70), empty)
	A.dressFeria(feria:Clone(), empty)
end)
check(ok, "sin mallas, las salas y tiendas se quedan como estaban (sin errores)")
check(empty.Report[100792423689137] == "no carga", "el informe dice qué no cargó")

-- Ids que nunca cargan en un servidor de verdad (docs/diagnostico-v89.md): ya no se piden
local dropped = true
for _, id in { 101748452, 117850698505269, 546753609 } do
	for _, p in A.WeaponPacks do
		if p.Id == id then
			dropped = false
		end
	end
	for _, pid in A.Props do
		if pid == id then
			dropped = false
		end
	end
	if not table.find(A.Dropped, id) then
		dropped = false
	end
end
check(dropped, "fuera la pistola dorada (no autorizada) y los dos packs que no dan mallas (117850698505269, 546753609)")

print()
if failures > 0 then
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
print("✅ Armas, ejército y Pliegues: todo correcto")
