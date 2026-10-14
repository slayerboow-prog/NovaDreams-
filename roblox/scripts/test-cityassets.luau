-- Prueba de los modelos de la Tienda en la calle (World/CityAssets + World/CityAssetsKit) FUERA de
-- Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):  lune run scripts/test-cityassets.luau
--
-- En Lune no hay AssetService: se hacen packs falsos con lo malo que traen los de verdad (scripts,
-- virus escondidos en un ParticleEmitter y un PlaneConstraint con atributos, sonidos, GUIs, logos y
-- marcas, grafitis de otros juegos…) y una ciudad pequeña con las mismas piezas que la de verdad
-- (aires de fachada, obras, farolas y aceras, manzana industrial con su nave, campo de fútbol,
-- armario eléctrico con pintada, villa con su puerta, parque, puerto y playa). Comprueba:
--   * no queda ni un script ni nada raro, ni marcas, ni grafitis prohibidos; el camión pierde su textura
--   * cada cosa va en su sitio con sentido (dentro de su pieza o de su patio, en la acera, en el agua,
--     lejos al fondo) y sin pisar nada; la pieza de bloques queda escondida y la malla con su etiqueta
--   * el cartel del ascensor está en español
--   * si nada carga, o la carga revienta, no pasa nada (sin errores, sin piezas)

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Enum, Vector3, Color3, CFrame, Instance, UDim2 = roblox.Enum, roblox.Vector3, roblox.Color3, roblox.CFrame, roblox.Instance, roblox.UDim2

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local function load(path: string, env: { [string]: any }): any
	local full = setmetatable(env, { __index = getfenv(1) })
	return luau.load(fs.readFile(path), { debugName = path, environment = full })()
end

local warnings = {}
local base = {
	Enum = Enum, Vector3 = Vector3, Color3 = Color3, CFrame = CFrame, Instance = Instance, UDim2 = UDim2,
	task = { wait = function() end, defer = function(f) f() end },
	warn = function(...)
		table.insert(warnings, table.concat({ ... }, " "))
	end,
}
local function env(extra: { [string]: any }): { [string]: any }
	local out = table.clone(base)
	for k, v in extra do
		out[k] = v
	end
	return out
end

local Kit = load("src/server/World/CityAssetsKit.luau", env({}))
local KIT = {}
local CityAssets = load("src/server/World/CityAssets.luau", env({
	script = { Parent = { CityAssetsKit = KIT } },
	require = function(m)
		if m == KIT then
			return Kit
		end
		error("require inesperado")
	end,
}))

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------

local function part(parent: Instance?, name: string, size: Vector3, cf: CFrame, class: string?): BasePart
	local p = Instance.new(class or "Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.Parent = parent
	return p
end

local function model(parent: Instance?, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

-- Lo malo que traen los packs: scripts, virus de las familias 3 y 5, sonido, GUI con texto
local function junk(root: Instance)
	local s = Instance.new("Script")
	s.Name = "CoreValidation"
	s.Parent = root
	local holder = root:FindFirstChildWhichIsA("BasePart", true) or root
	local fx = Instance.new("ParticleEmitter")
	fx.Name = "VFXParticles"
	fx.Parent = holder
	local ls = Instance.new("LocalScript")
	ls.Parent = fx
	local pc = Instance.new("PlaneConstraint")
	pc:SetAttribute("a", "eliforP:ssecca")
	pc.Parent = holder
	local pose = Instance.new("NumberPose")
	pose.Name = "Pose"
	pose.Parent = root
	local snd = Instance.new("Sound")
	snd.Parent = holder
	local gui = Instance.new("SurfaceGui")
	local label = Instance.new("TextLabel")
	label.Text = "Model corruption detected"
	label.Parent = gui
	gui.Parent = holder
	holder:SetAttribute("InjectedByDependencyInjector", true)
end

local function pack(name: string, build: (Model) -> ()): Model
	local root = model(nil, name)
	build(root)
	junk(root)
	return root
end

local O = CFrame.new(0, 0, 0)
local function box(parent, name, size)
	return part(parent, name, size, CFrame.new(0, size.Y / 2, 0))
end

local function decal(parent: Instance, name: string, id: string)
	local d = Instance.new("Decal")
	d.Name = name
	d.Texture = "rbxassetid://" .. id
	d.Parent = parent
	return d
end

---------------------------------------------------------------------
-- Packs falsos (mismos nombres y tallas que los de verdad: docs/assets-usuario*.md)
---------------------------------------------------------------------

local PACKS: { [number]: () -> Instance } = {}

PACKS[5411055653] = function()
	return pack("Construction", function(r)
		local c = model(r, "TrafficCone")
		box(c, "Cone", Vector3.new(1.5, 2.5, 1.5))
		local f = model(r, "ConstructionFence")
		box(f, "Fence", Vector3.new(8, 4, 0.5))
		local b = model(r, "Barrel55")
		local bp = box(b, "Barrel", Vector3.new(2.6, 4, 2.6))
		decal(bp, "Roblox General Technologies", "1")
		local sc = model(r, "Scaffold")
		box(sc, "Frame", Vector3.new(10, 12, 4))
		local ct = model(r, "Container")
		box(ct, "Body", Vector3.new(8, 6, 20))
		local pl = model(r, "Pallet")
		box(pl, "Pallet", Vector3.new(4, 0.5, 4))
	end)
end
PACKS[113264079562085] = function()
	return pack("Factory", function(r)
		box(model(r, "Forklift_01_Prefab_01"), "Forklift_LOD0", Vector3.new(5.3, 7.6, 14.2))
		box(model(r, "Pallet_Jack_01"), "Jack", Vector3.new(2.3, 4.4, 5.6))
		box(model(r, "Wrapped_Boxes_01"), "Wrapped", Vector3.new(3.6, 4, 2.8))
		box(r, "Pallet_01", Vector3.new(3.6, 0.5, 3.6))
		box(r, "Stack_Box_01", Vector3.new(3, 2.5, 2))
	end)
end
PACKS[103449549978145] = function()
	return pack("Graffiti", function(r)
		local p1 = box(r, "Wall1", Vector3.new(8, 4, 0.2))
		decal(p1, "Seen", "1078699847")
		local p2 = box(r, "Wall2", Vector3.new(8, 4, 0.2))
		decal(p2, "Graffiti 23", "2629738446") -- CS:GO (no vale aunque el nombre no lo diga)
		local p3 = box(r, "CS:GO - Graffiti 32", Vector3.new(8, 4, 0.2))
		decal(p3, "CS:GO - Graffiti 32", "2629746499")
		local p4 = box(r, "Wall4", Vector3.new(8, 4, 0.2))
		decal(p4, "WT 2 Graffiti", "3098573602") -- Wu-Tang
		local p5 = box(r, "Wall5", Vector3.new(8, 4, 0.2))
		decal(p5, "Graffiti7", "8604374847")
	end)
end
PACKS[99479110531330] = function()
	return pack("Realistic city", function(r)
		local props = Instance.new("Folder")
		props.Name = "---City props---"
		props.Parent = r
		box(model(props, "FireHydrant_01_A"), "FireHydrant", Vector3.new(1.5, 3.3, 1.7))
		box(model(props, "Mailbox_01_A"), "Mailbox", Vector3.new(2.7, 5.4, 2.5))
		box(model(props, "Newspaper_Stand_01_A"), "Stand", Vector3.new(2.5, 4.7, 2.7))
		box(model(props, "Planter_Square_01_A"), "Planter", Vector3.new(9, 3.6, 6.9))
		box(model(props, "Garbage_Bin"), "Bin", Vector3.new(13.2, 13.1, 8.6))
		box(model(props, "AC_Unit_01_A"), "AC", Vector3.new(12, 6.5, 7.1))
		box(props, "CementBarrier", Vector3.new(4.9, 2.3, 1.3))
		box(props, "Coke", Vector3.new(0.7, 1.3, 0.7))
		box(model(props, "OnlyFantasVendingMachine"), "Machine", Vector3.new(4.1, 7.5, 3.6))
		box(props, "bms_metalcrate_64x", Vector3.new(5.9, 9, 5.9))
		local b = Instance.new("Folder")
		b.Name = "---Building---"
		b.Parent = r
		box(b, "Prefab Highrise", Vector3.new(44, 112, 52))
		box(b, "City House", Vector3.new(20, 34, 28))
	end)
end
PACKS[99043731526992] = function()
	return pack("Area51", function(r)
		local p = box(r, "Wall", Vector3.new(14, 10, 1))
		local tex = Instance.new("Texture")
		tex.Name = "MetalTexture"
		tex.Texture = "rbxassetid://5"
		tex.Parent = p
	end)
end
PACKS[9876129164] = function()
	return pack("basuraaaa", function(r)
		box(r, "Dumpster", Vector3.new(3.6, 3.6, 7.3), "MeshPart")
	end)
end
PACKS[10396819700] = function()
	return pack("pallete", function(r)
		box(r, "pallete", Vector3.new(11.9, 1.1, 11.2))
	end)
end
PACKS[2161748423] = function()
	return pack("Tracks", function(r)
		box(r, "TrackLong", Vector3.new(60, 1.5, 15))
		box(r, "BumperTrack", Vector3.new(11, 7, 11))
	end)
end
PACKS[8386763665] = function()
	return pack("Long track", function(r)
		local m = model(r, "16 Long")
		part(m, "Ballast", Vector3.new(16, 1, 16), CFrame.new(0, 0.5, 0))
		part(m, "Rail", Vector3.new(0.5, 1, 16), CFrame.new(-3, 1.5, 0))
		part(m, "Rail", Vector3.new(0.5, 1, 16), CFrame.new(3, 1.5, 0))
	end)
end
PACKS[18777387875] = function()
	return pack("Barbados", function(r)
		local g = model(r, "Gate")
		box(g, "GateLeaf", Vector3.new(12, 6, 0.5))
		local fl = model(r, "Flower Bush Plants")
		for i = 1, 20 do
			part(fl, "Leaf", Vector3.new(1, 1, 1), CFrame.new(i, 1, 0))
		end
	end)
end
PACKS[6795368713] = function()
	return pack("AC House", function(r)
		local house = model(r, "House")
		box(house, "Wall", Vector3.new(100, 40, 1))
		local ac = model(house, "Daikin")
		box(ac, "Body", Vector3.new(3, 1, 1))
		box(ac, "Daikin Logo", Vector3.new(0.5, 0.2, 0.05))
		local inner = model(ac, "Mitsubishi Kirigamine Zen")
		box(inner, "Cover", Vector3.new(3, 1, 1))
	end)
end
PACKS[13465440856] = function()
	return pack("Funiki", function(r)
		local ac = model(r, "Funiki air conditioner")
		local body = box(ac, "Body", Vector3.new(6.2, 2.8, 2))
		decal(body, "FunikiLogo", "7")
		box(ac, "Funiki Logo", Vector3.new(1, 0.3, 0.05))
		local remote = model(ac, "Remote")
		box(remote, "Remote", Vector3.new(0.3, 0.8, 0.1))
	end)
end
PACKS[82042358715900] = function()
	return pack("Socket", function(r)
		box(r, "Socket", Vector3.new(0.6, 0.9, 0.2), "MeshPart")
	end)
end
PACKS[111283915226740] = function()
	return pack("Polska Dom", function(r)
		box(r, "sciana", Vector3.new(60, 22, 70))
		box(r, "woda", Vector3.new(10, 1, 10))
	end)
end
PACKS[79665094662717] = function()
	return pack("Japan", function(r)
		box(model(r, "Building #1"), "Mesh", Vector3.new(183, 165, 131))
		box(model(r, "Building #4"), "Mesh", Vector3.new(109, 396, 162))
		box(model(r, "Road"), "Road", Vector3.new(27, 0.3, 41))
	end)
end
PACKS[124865259344404] = function()
	return pack("Truck", function(r)
		local t = box(r, "AW International LC", Vector3.new(9.8, 9.6, 24), "MeshPart")
		pcall(function()
			(t :: any).TextureID = "rbxassetid://99"
		end)
	end)
end
PACKS[11188629897] = function()
	return pack("Elevator", function(r)
		box(r, "Tower", Vector3.new(17.9, 11.6, 17.8))
		local l = Instance.new("PointLight")
		l.Parent = r:FindFirstChild("Tower")
	end)
end
PACKS[133967929770771] = function()
	return pack("Lift sign", function(r)
		local b = box(r, "Board", Vector3.new(2, 3, 0.2))
		decal(b, "Out of order", "11")
		box(r, "Consult Logo", Vector3.new(1, 0.5, 0.1))
	end)
end
PACKS[898778590] = function()
	return pack("Tennis", function(r)
		box(r, "Court", Vector3.new(56.5, 0.4, 70.5))
		local s = box(r, "Billionare Bench", Vector3.new(6, 2, 2), "Seat")
		local _ = s
	end)
end
PACKS[75541553] = function()
	return pack("Goal", function(r)
		part(r, "Post", Vector3.new(1, 15, 1), CFrame.new(0, 7.5, -20))
		part(r, "Post", Vector3.new(1, 15, 1), CFrame.new(0, 7.5, 20))
		for i = 1, 10 do
			part(r, "Net", Vector3.new(0.2, 14, 4), CFrame.new(8 + i * 0.3, 7, -20 + i * 4))
		end
	end)
end
PACKS[82136423205151] = function()
	return pack("Car show", function(r)
		box(r, "Base", Vector3.new(22, 1, 22))
		local h = Instance.new("HingeConstraint")
		h.Parent = r:FindFirstChild("Base")
	end)
end
PACKS[120631576642977] = function()
	return pack("Rack", function(r)
		box(r, "Rack", Vector3.new(2.3, 7.5, 2.6))
	end)
end
PACKS[13728551087] = function()
	return pack("Boats", function(r)
		local f = Instance.new("Folder")
		f.Name = "Boats"
		f.Parent = r
		box(f, "Trawler", Vector3.new(27.4, 30, 101.4), "MeshPart")
		box(f, "small boat", Vector3.new(19, 5.8, 5.2), "MeshPart")
		box(f, "Smash Mouth Boat", Vector3.new(8.5, 5.4, 25.5), "MeshPart")
		local war = model(f, "Warship")
		box(war, "Hull", Vector3.new(37.7, 60, 313))
		local wreck = model(f, "Wreck")
		for i = 1, 6 do
			part(wreck, "Piece", Vector3.new(4, 4, 7), CFrame.new(0, 2, i * 7))
		end
	end)
end
PACKS[10887600145] = function()
	return pack("Steam train", function(r)
		part(r, "Loco", Vector3.new(20.4, 25.2, 84.1), CFrame.new(0, 12.6, 0), "MeshPart")
		part(r, "Tender", Vector3.new(20.8, 23.6, 53.2), CFrame.new(0, 11.8, 70), "MeshPart")
	end)
end
PACKS[8380605189] = function()
	return pack("Trains", function(r)
		local bx = model(r, "CN Boxcar")
		box(bx, "Body", Vector3.new(15, 21.2, 60.6))
		decal(bx:FindFirstChild("Body") :: Instance, "CN", "12")
		box(bx, "CN logo", Vector3.new(4, 4, 0.1))
		local vs = Instance.new("VehicleSeat")
		vs.Parent = bx
		local bg = model(r, "Pullman American Baggage Car")
		box(bg, "Body", Vector3.new(13.8, 21.6, 97.8))
		local big = model(r, "Big Boy")
		box(big, "Body", Vector3.new(18.6, 24, 162.4))
	end)
end

-- Reemplazos limpios (docs/assets-reemplazos.md)
PACKS[16524471626] = function()
	return pack("City Background Night", function(r)
		box(r, "CityMesh", Vector3.new(617, 259, 545), "MeshPart")
	end)
end
PACKS[6418277837] = function()
	return pack("City Building Pack", function(r)
		local f = Instance.new("Folder")
		f.Name = "City Building Pack"
		f.Parent = r
		box(model(f, "building_01"), "Tower", Vector3.new(110, 290, 110))
		box(model(f, "building_01_sections"), "ground_floor", Vector3.new(110, 20, 110))
		box(model(f, "RobloxBillboard"), "Board", Vector3.new(129, 89, 47))
	end)
end
PACKS[76558120171446] = function()
	return pack("Modern Brick School", function(r)
		box(r, "SchoolMesh", Vector3.new(414, 79, 108), "MeshPart")
		for i = 1, 30 do
			part(r, "Window", Vector3.new(4, 6, 0.3), CFrame.new(-200 + i * 12, 30, -54))
		end
		Instance.new("Camera").Parent = r
	end)
end
PACKS[15569059562] = function()
	return pack("Mini Football stadium", function(r)
		part(r, "Field", Vector3.new(150, 0.5, 96), CFrame.new(0, 0.25, 0), "MeshPart")
		part(r, "StandN", Vector3.new(228, 39, 16), CFrame.new(0, 19.5, 56), "MeshPart")
		part(r, "StandS", Vector3.new(228, 20, 16), CFrame.new(0, 10, -56), "MeshPart")
		part(r, "GoalA", Vector3.new(3, 8, 24), CFrame.new(-75, 4, 0), "MeshPart")
	end)
end
PACKS[6432233485] = function()
	return pack("City Road Pack", function(r)
		local f = Instance.new("Folder")
		f.Name = "City Road Pack"
		f.Parent = r
		box(model(f, "Road_Patch_02_A"), "Patch", Vector3.new(29.3, 0.05, 9.9), "MeshPart")
		box(model(f, "Road_Patch_03_A"), "Patch", Vector3.new(7.9, 0.1, 12.9), "MeshPart")
		box(model(f, "RobloxBillboard"), "Board", Vector3.new(129, 89, 47))
		box(f, "Road_01_A", Vector3.new(40, 1, 40), "MeshPart")
	end)
end

local loaded = {}
local function loader(id: number): Instance?
	local make = PACKS[id]
	loaded[id] = true
	return make and make() or nil
end

---------------------------------------------------------------------
print("\n1) Limpieza: sin scripts, sin virus, sin marcas")
---------------------------------------------------------------------

local pools, report = CityAssets.loadAll(loader)
local skipped = 0
for id in CityAssets.Skipped do
	if loaded[id] then
		skipped += 1
	end
end
check(skipped == 0, "no se carga ninguno de los descartados")
local catalogIds = {}
for _, e in CityAssets.Catalog do
	catalogIds[e.Id] = true
	check(report[e.Id] and string.sub(report[e.Id], 1, 2) == "ok", ("%d %s: %s"):format(e.Id, e.Name, tostring(report[e.Id])))
end

local BAD = { ParticleEmitter = true, PlaneConstraint = true, NumberPose = true, Sound = true, SurfaceGui = true, TextLabel = true, HingeConstraint = true }
local scripts, bad, attrs, brands, total = 0, 0, 0, 0, 0
local function scan(root: Instance)
	for _, d in root:GetDescendants() do
		total += 1
		if d:IsA("LuaSourceContainer") then
			scripts += 1
		end
		if BAD[d.ClassName] then
			bad += 1
		end
		if next(d:GetAttributes()) ~= nil then
			attrs += 1
		end
		if Kit.branded(d.Name) then
			brands += 1
			print("     marca: " .. d:GetFullName())
		end
	end
end
for key, list in pools do
	for _, t in list do
		if type(t) == "table" then
			scan(t.Model)
			check(not Kit.branded(t.Name), "nombre en español sin marca: " .. key)
		end
	end
end
check(total > 0, "hay plantillas")
check(scripts == 0, "ningún script en las plantillas")
check(bad == 0, "ni sonidos, GUIs, partículas, NumberPose ni PlaneConstraint")
check(attrs == 0, "sin atributos (los virus esconden el código ahí)")
check(brands == 0, "ninguna pieza ni imagen con marca real o de otro juego")
check(pools.Grafiti and #pools.Grafiti == 2, "grafitis: solo los 2 permitidos de 5 (" .. tostring(pools.Grafiti and #pools.Grafiti) .. ")")
for _, img in pools.Grafiti or {} do
	check(not string.find(img, "2629738446") and not string.find(img, "3098573602"), "sin grafitis de CS:GO ni Wu-Tang: " .. img)
end
check(pools.AC and #pools.AC >= 3, "aires: de Funiki, de la casa y del city pack (" .. tostring(pools.AC and #pools.AC) .. ")")
local acParts = 0
for _, t in pools.AC or {} do
	acParts += #Kit.parts(t.Model)
end
check(acParts >= 4, "los aires conservan su cuerpo (aunque se llamaran Daikin/Mitsubishi): " .. acParts)
check(pools.Vagon and #pools.Vagon == 2, "train pack: solo el vagón cerrado y el furgón")
for _, t in pools.Vagon or {} do
	local seats = 0
	for _, p in Kit.parts(t.Model) do
		if p.ClassName == "VehicleSeat" and not (p :: any).Disabled then
			seats += 1
		end
	end
	check(seats == 0, "vagón sin asientos que conducir")
end
local truck = pools.CamionAbandonado and pools.CamionAbandonado[1]
local okTex, tex = pcall(function()
	return (Kit.parts(truck.Model)[1] :: any).TextureID
end)
check(truck and (not okTex or tex == "" or tex == nil), "camión sin la textura con la marca International")
check(truck and Kit.parts(truck.Model)[1].Material == Enum.Material.CorrodedMetal, "camión oxidado (color y material propios)")
check(pools.Pesquero and pools.Barca and pools.LanchaRapida and pools.BarcoHundido, "barcos: pesquero, barca, lancha rápida y hundido")
for _, list in { pools.Pesquero or {}, pools.Barca or {}, pools.Lancha or {} } do
	for _, t in list do
		check(t.Size.Y < math.max(t.Size.X, t.Size.Z), "barco tumbado puesto de pie: " .. t.Name)
	end
end
local warship = false
for _, key in { "Pesquero", "Barca", "Lancha", "LanchaRapida", "BarcoHundido" } do
	for _, t in pools[key] or {} do
		if math.max(t.Size.X, t.Size.Z) > 250 then
			warship = true
		end
	end
end
check(not warship, "sin el buque de guerra")
check(pools.Skyline and #pools.Skyline == 5, "skyline: 2 de Japón + 2 del city pack + 1 del City Building Pack (sin secciones, carretera ni cartel)")
check(pools.SkylineGrande and #pools.SkylineGrande == 1, "skyline grande de una malla (16524471626)")
check(pools.Instituto and #pools.Instituto == 1, "colegio de ladrillo (sin la Camera)")
check(pools.EstadioMalla and #pools.EstadioMalla == 1, "estadio de mallas con su césped reconocido")
check(pools.Parche and #pools.Parche == 2, "parches del City Road Pack (sin tramos de calle ni cartel)")
check(not pools.Coke and not pools.OnlyFantas, "sin lata de Coca-Cola ni la máquina de la parodia")

---------------------------------------------------------------------
-- Ciudad falsa
---------------------------------------------------------------------

local town = model(nil, "Town")
local streets = model(town, "Streets")
-- Acera de 12 de ancho a lo largo de X (z 0..12) con farolas en el borde de la calzada
part(streets, "Sidewalk", Vector3.new(400, 1, 12), CFrame.new(0, 0, 6))
part(streets, "Road", Vector3.new(400, 0.4, 30), CFrame.new(0, -0.3, -15))
for x = -180, 180, 30 do
	local lamp = model(streets, "StreetLamp")
	part(lamp, "Base", Vector3.new(1.2, 0.6, 1.2), CFrame.new(x, 0.8, 1))
	part(lamp, "Pole", Vector3.new(0.6, 14, 0.6), CFrame.new(x, 7.5, 1))
end
-- Casa con aire acondicionado en la fachada (la pared en z = 100)
local casa = model(town, "Casa")
part(casa, "Wall", Vector3.new(30, 12, 1), CFrame.new(0, 6, 100))
local ac = part(casa, "ACUnit", Vector3.new(2.4, 1.8, 1.2), CFrame.new(0, 4, 99))
part(casa, "ACGrille", Vector3.new(1.4, 1.4, 0.1), CFrame.new(0, 4, 98.35))
-- Obras en la calzada
local det = model(streets, "Detalles")
local obras = model(det, "Obras")
local cone = part(obras, "Cone", Vector3.new(0.8, 1.6, 0.8), CFrame.new(50, 0.8, -10))
local barrier = part(obras, "WorksBarrier", Vector3.new(5.2, 3, 1.6), CFrame.new(55, 1.5, -10))
local fence = part(obras, "WorksFence", Vector3.new(5, 2.6, 0.2), CFrame.new(55, 1.4, -10))
-- Armario eléctrico con pintada
local arm = model(det, "ArmarioElectrico")
part(arm, "Cabinet", Vector3.new(2.6, 3.6, 1.2), CFrame.new(90, 1.8, 8)).Color = Color3.fromRGB(90, 90, 90)
local graf = part(arm, "Graffiti", Vector3.new(2.4, 1.6, 0.1), CFrame.new(90, 2, 7.35))
-- Palé
local pallet = part(town, "Pallet", Vector3.new(5, 0.5, 5), CFrame.new(-60, 0.25, 300))
-- Polígono: manzana industrial (220×220) con nave al oeste y patio libre al este
local function industrial(cx: number, cz: number)
	local m = model(town, "Manzana_Industrial")
	part(m, "BlockGround", Vector3.new(220, 1, 220), CFrame.new(cx, -0.5, cz))
	local nave = model(m, "Nave")
	part(nave, "Yard", Vector3.new(212, 0.4, 212), CFrame.new(cx, 0.1, cz))
	part(nave, "Hall", Vector3.new(120, 23, 90), CFrame.new(cx - 29, 11.5, cz))
	part(nave, "Dock", Vector3.new(96, 3, 6), CFrame.new(cx - 29 - 60 - 3, 1.5, cz))
	return m
end
local yards = {}
for i = 0, 3 do
	table.insert(yards, industrial(1000, 1500 + i * 240))
end
-- Campo de fútbol
local dep = model(town, "Manzana_Deporte")
part(dep, "BlockGround", Vector3.new(220, 1, 220), CFrame.new(2757, -0.5, 2493))
part(dep, "Pitch", Vector3.new(110, 0.3, 70), CFrame.new(2757, 0.1, 2493))
local goal = part(dep, "Goal", Vector3.new(1, 8.1, 20), CFrame.new(2703, 4, 2493))
-- Taller
local tm = model(town, "Manzana_Taller")
part(tm, "BlockGround", Vector3.new(120, 1, 160), CFrame.new(-300, -0.5, 1500))
part(model(tm, "Taller"), "Body", Vector3.new(40, 12, 30), CFrame.new(-320, 6, 1500))
-- Villa con su puerta (pilares a x 545 y 551, la casa al sur)
local villa = model(town, "Villa")
part(villa, "Body", Vector3.new(56, 12, 35), CFrame.new(556, 6, -2445))
local p1 = part(villa, "GatePillar", Vector3.new(1.2, 4, 1.2), CFrame.new(551, 2, -2407.5))
part(villa, "GatePillar", Vector3.new(1.2, 4, 1.2), CFrame.new(545, 2, -2407.5))
part(villa, "Wall", Vector3.new(36.4, 3, 0.8), CFrame.new(569.8, 1.5, -2407.5))
-- Parques
for i = 0, 1 do
	local pm = model(town, "Manzana_Parque")
	part(pm, "BlockGround", Vector3.new(200, 1, 200), CFrame.new(-800 - i * 300, -0.5, 500))
end
-- Puerto (muelle a lo largo de X) y playa
local puerto = model(town, "Puerto")
local pier = part(puerto, "Pier", Vector3.new(230, 1, 14), CFrame.new(700, 0.5, 3450))
part(town, "Sea", Vector3.new(2000, 1, 2000), CFrame.new(700, -3, 3800))
local playa = model(town, "Playa")
local sand = part(playa, "Sand", Vector3.new(100, 0.6, 118), CFrame.new(3881, 0.3, -690))
-- Villaverde
local region = model(town, "Region")
local vv = model(region, "Villaverde")
part(vv, "BlockGround", Vector3.new(220, 1, 220), CFrame.new(-2700, -0.5, -1850))

-- Parche de asfalto procedural (Kit/CityDetail) en la calzada
local asphalt = part(streets, "AsphaltPatch", Vector3.new(8, 0.02, 4), CFrame.new(-100, -0.08, -20))
-- Estadio (como Region/Distrito Financiero): explanada, campo, porterías y gradas de bloques
local reg2 = model(town, "Distrito")
local estadio = model(reg2, "Estadio")
part(estadio, "Esplanade", Vector3.new(196, 1, 198), CFrame.new(120, 0.5, -681))
local stPitch = part(estadio, "Pitch", Vector3.new(110, 0.3, 70), CFrame.new(120, 1.15, -680))
local stPost = part(estadio, "Post", Vector3.new(0.4, 7.6, 0.4), CFrame.new(65, 4.8, -687))
local stStand = part(estadio, "Stand", Vector3.new(124, 18, 24), CFrame.new(120, 10, -630))
part(estadio, "Scoreboard", Vector3.new(26, 8, 0.6), CFrame.new(199, 21, -680))
-- Manzana de colegio con el colegio que se recorre (ocupa el norte) y sitio libre al sur
local mc = model(town, "Manzana_ColegioCentro")
part(mc, "BlockGround", Vector3.new(260, 1, 260), CFrame.new(1000, -0.5, 4000))
local colegio = model(mc, "Colegio")
local colegioBody = part(colegio, "Wall", Vector3.new(140, 29, 40), CFrame.new(1000, 14.5, 3900))

-- Consulta de huecos y rayo hacia abajo (como GetPartBoundsInBox y Raycast, con cajas)
local function allParts(): { BasePart }
	return Kit.parts(town)
end
local function aabb(cf: CFrame, size: Vector3): (Vector3, Vector3)
	return Kit.bounds({ { CFrame = cf, Size = size } :: any })
end
local function overlaps(alo, ahi, blo, bhi, eps: number?): boolean
	local e = eps or 0
	return alo.X < bhi.X - e and blo.X < ahi.X - e and alo.Y < bhi.Y - e and blo.Y < ahi.Y - e and alo.Z < bhi.Z - e and blo.Z < ahi.Z - e
end
local queries = 0
local function query(cf: CFrame, size: Vector3): { Instance }
	queries += 1
	local lo, hi = aabb(cf, size)
	local out = {}
	for _, p in allParts() do
		if not Kit.IgnoreNames[p.Name] then
			local plo, phi = Kit.bounds({ p })
			if overlaps(lo, hi, plo, phi) then
				table.insert(out, p)
			end
		end
	end
	return out
end
local function ground(from: Vector3): (number?, Instance?)
	local best, bestY = nil, -math.huge
	for _, p in allParts() do
		local lo, hi = Kit.bounds({ p })
		if from.X >= lo.X and from.X <= hi.X and from.Z >= lo.Z and from.Z <= hi.Z and hi.Y <= from.Y and hi.Y > bestY then
			best, bestY = p, hi.Y
		end
	end
	return if best then bestY else nil, best
end

---------------------------------------------------------------------
print("\n2) Colocación con sentido")
---------------------------------------------------------------------

local parent = Instance.new("Folder")
parent.Name = "ActivosCiudad"
parent.Parent = town
CityAssets.isSea = function(_x, z)
	return z > 3460
end
local ctx = { Town = town, Pools = pools, Parent = parent, Query = query, Ground = ground, Parts = 0, Counts = {}, Wait = function() end }
local counts = CityAssets.run(ctx)
local list = {}
for k, v in counts do
	table.insert(list, k .. "=" .. v)
end
table.sort(list)
print("     " .. table.concat(list, " "))
check(#warnings == 0, "sin avisos de error (" .. table.concat(warnings, " | ") .. ")")

-- Aire: la malla cabe en la caja del aire de bloques (un poco más grande), que queda escondido
local acMesh = ac:FindFirstChild("Malla")
check(acMesh ~= nil, "el aire de la fachada lleva malla")
if acMesh then
	local lo, hi = Kit.bounds(Kit.parts(acMesh))
	local blo, bhi = aabb(ac.CFrame, ac.Size * 1.16)
	check(lo.X >= blo.X - 0.01 and hi.X <= bhi.X + 0.01 and lo.Y >= blo.Y - 0.01 and hi.Y <= bhi.Y + 0.01 and lo.Z >= blo.Z - 0.01 and hi.Z <= bhi.Z + 0.01, "la malla del aire cabe en su sitio de la fachada")
	check(Kit.parts(acMesh)[1]:HasTag("PropMesh") and not Kit.parts(acMesh)[1]:HasTag("BuildingMesh"), "malla con PropMesh (pequeña y barata: se ve también en Bajo)")
end
check(ac.Transparency == 1 and ac:HasTag("PropShell") and not ac:HasTag("BuildingShell"), "el aire de bloques queda invisible con PropShell (en todos los niveles)")
check(ac.Parent:FindFirstChild("ACGrille").Transparency == 1, "la rejilla de bloques también se esconde")

-- Obras: el cono y la valla salen despedidos con su malla (soldada)
local coneMesh = cone:FindFirstChild("Malla")
local welded = coneMesh and Kit.parts(coneMesh)[1]:FindFirstChildWhichIsA("WeldConstraint")
check(welded and welded.Part0 == cone and not Kit.parts(coneMesh)[1].Anchored, "malla del cono soldada al cono (se mueve con él al chocar)")
check(barrier:FindFirstChild("Malla") and fence.Transparency == 1, "valla de obra con malla; la de bloques escondida")
check(pallet:FindFirstChild("Malla") ~= nil, "palé con malla PBR")
-- Portería: misma caja, y la red hacia fuera del campo (x menor)
local goalMesh = goal:FindFirstChild("Malla")
check(goalMesh ~= nil, "portería con malla")
if goalMesh then
	local sum, n = 0, 0
	for _, p in Kit.parts(goalMesh) do
		sum += p.CFrame.Position.X
		n += 1
	end
	check(sum / n < goal.CFrame.Position.X, "la red de la portería mira hacia fuera del campo")
end
check(goal.CanCollide ~= false and goal.Transparency == 1, "la portería de bloques sigue chocando (el balón) aunque no se vea")
-- Pintada
local gd = graf:FindFirstChildWhichIsA("Decal")
check(gd and (string.find(gd.Texture, "1078699847") or string.find(gd.Texture, "8604374847")), "el armario eléctrico lleva un grafiti permitido")

-- Calle: en la acera, sin pisar farolas, uno por farola como mucho
local calles = parent:FindFirstChild("Calles")
local nCalle, onWalk, clash = 0, 0, 0
if calles then
	for _, m in calles:GetChildren() do
		nCalle += 1
		local lo, hi = Kit.bounds(Kit.parts(m))
		if lo.Z >= 0 and hi.Z <= 12 and math.abs(lo.Y - 0.5) < 0.05 then
			onWalk += 1
		else
			print(("     fuera de la acera: %s %.1f..%.1f y %.2f"):format(m.Name, lo.Z, hi.Z, lo.Y))
		end
		for _, lamp in streets:GetChildren() do
			if lamp.Name == "StreetLamp" then
				for _, lp in Kit.parts(lamp) do
					local llo, lhi = Kit.bounds({ lp })
					if overlaps(lo, hi, llo, lhi, 0.01) then
						clash += 1
					end
				end
			end
		end
	end
end
check(nCalle > 0, "hay mobiliario de calle (" .. nCalle .. ")")
-- Nivel gráfico: el mobiliario de calle (hidrantes, buzones, quioscos, jardineras) es barato y se ve
-- también en Bajo (PropDetail; nada de CityDetail, que Bajo esconde)
local cheapTags = nCalle > 0
for _, m in (if calles then calles:GetChildren() else {}) do
	for _, p in Kit.parts(m) do
		if not p:HasTag("PropDetail") or p:HasTag("CityDetail") or p:HasTag("BuildingMesh") then
			cheapTags = false
		end
	end
end
check(cheapTags, "mobiliario de calle con PropDetail: Bajo no lo esconde")
check(onWalk == nCalle, "todo en la acera y apoyado en ella (" .. onWalk .. "/" .. nCalle .. ")")
check(clash == 0, "nada pisa una farola")

-- Industria: todo dentro de su patio y fuera de la nave
local ind = parent:FindFirstChild("Industria")
check(ind and ind:FindFirstChild("Obra"), "hay una obra")
check(ind and ind:FindFirstChild("Apartadero"), "hay un apartadero con vagones")
check(ind and ind:FindFirstChild("CamionAbandonado"), "hay un desguace con el camión")
local inside, hallHits, items = 0, 0, 0
for _, m in (ind and ind:GetChildren() or {}) do
	if m.Name == "GrafitiNave" or m.Name == "Enchufe" then
		continue
	end
	items += 1
	local lo, hi = Kit.bounds(Kit.parts(m))
	for _, y in yards do
		local g = y:FindFirstChild("BlockGround")
		local glo, ghi = Kit.bounds({ g })
		if lo.X >= glo.X and hi.X <= ghi.X and lo.Z >= glo.Z and hi.Z <= ghi.Z then
			inside += 1
			local hall = y.Nave.Hall
			local hlo, hhi = Kit.bounds({ hall })
			if overlaps(lo, hi, hlo, hhi, 0.01) then
				hallHits += 1
				print("     pisa la nave: " .. m.Name)
			end
		end
	end
end
check(items > 6, "patios con carretillas, palés, contenedores… (" .. items .. ")")
check(inside == items, "todo dentro de su manzana industrial")
check(hallHits == 0, "nada se mete dentro de la nave")
local sign = ind and ind.Obra:FindFirstChild("CartelAscensor")
local text = sign and sign:FindFirstChild("Texto", true)
check(text and string.find(text.Text, "FUERA DE SERVICIO"), "el cartel del ascensor, en español")
local sid = ind and ind:FindFirstChild("Apartadero")
if sid then
	local cars = 0
	for _, c in sid:GetChildren() do
		if c.Name == "VagonParado" then
			cars += 1
		end
	end
	check(cars == 2, "dos vagones parados en el apartadero")
end

-- Taller, villa, parques
check(parent:FindFirstChild("Talleres") and parent.Talleres:FindFirstChild("Expositor"), "plataforma de exposición en el taller")
local gate = parent:FindFirstChild("Villas") and parent.Villas:FindFirstChild("PuertaCorredera")
check(gate ~= nil, "puerta corredera en la villa")
if gate then
	local lo, hi = Kit.bounds(Kit.parts(gate))
	print(("     puerta x %.1f..%.1f z %.1f..%.1f y %.1f..%.1f"):format(lo.X, hi.X, lo.Z, hi.Z, lo.Y, hi.Y))
	check((hi.X <= 545.7 or lo.X >= 550.3) and hi.Y <= 4.6, "la puerta queda corrida a un lado (no cierra la entrada entre los pilares)")
	check(not Kit.parts(gate)[1].CanCollide, "la puerta no estorba")
end
local parks = parent:FindFirstChild("Parques")
check(parks and parks:FindFirstChild("PistaTenis"), "pista de tenis en un parque")
check(parks and parks:FindFirstChild("LocomotoraMonumento"), "locomotora de vapor de monumento en un parque")

-- Mar: amarrados junto al muelle, a flote; skyline lejos al sur
local mar = parent:FindFirstChild("Mar")
local afloat, moored = 0, 0
for _, b in (mar and mar:GetChildren() or {}) do
	local lo, hi = Kit.bounds(Kit.parts(b))
	if lo.Y < CityAssets.SeaLevel and hi.Y > CityAssets.SeaLevel then
		afloat += 1
		if math.abs((lo.Z + hi.Z) / 2 - 3450) < 40 then
			moored += 1
			local plo, phi = Kit.bounds({ pier })
			check(not overlaps(lo, hi, plo, phi, 0.01), "pesquero amarrado sin meterse en el muelle")
		end
	end
end
check(moored >= 1, "pesqueros amarrados en el puerto (" .. moored .. ")")
check(afloat >= 3, "barcos a flote (" .. afloat .. ")")
local beached = 0
for _, b in (mar and mar:GetChildren() or {}) do
	local lo, hi = Kit.bounds(Kit.parts(b))
	local slo, shi = Kit.bounds({ sand })
	if lo.X >= slo.X and hi.X <= shi.X and math.abs(lo.Y - shi.Y) < 0.05 then
		beached += 1
	end
end
check(beached >= 1, "barca o barco hundido en la arena de la playa")
local sky = parent:FindFirstChild("CostaDeEnfrente")
check(sky ~= nil, "skyline de la costa de enfrente")
if sky then
	local lo = Kit.bounds(Kit.parts(sky))
	local allOff = true
	for _, p in Kit.parts(sky) do
		if p.CanCollide or not p:HasTag("CityDetail") then
			allOff = false
		end
	end
	check(lo.Z > 5500, "el skyline está muy lejos, al otro lado del mar")
	check(allOff, "el skyline no choca y Bajo lo esconde")
end
check(parent:FindFirstChild("Campo") and parent.Campo:FindFirstChild("CasaCampo"), "casa de campo en Villaverde")

-- Parches PBR encima de los parches de bloques (mismo sitio, sin duplicar)
check(asphalt:FindFirstChild("Malla") and asphalt.Transparency == 1, "parche de asfalto con malla PBR; el de bloques escondido")
if asphalt:FindFirstChild("Malla") then
	local lo, hi = Kit.bounds(Kit.parts(asphalt.Malla))
	check(hi.X - lo.X <= 8.01 and hi.Z - lo.Z <= 4.01, "el parche PBR no se sale del sitio del parche de antes")
end
-- Estadio: césped de malla encima de nuestro campo, mismo largo; lo de bloques escondido
local em = estadio:FindFirstChild("EstadioMalla")
check(em ~= nil, "estadio de mallas encima del estadio")
if em then
	local cesped
	for _, p in Kit.parts(em) do
		if p.Name == "Cesped" then
			cesped = p
		end
	end
	local lo, hi = Kit.bounds({ cesped })
	check(math.abs((hi.X - lo.X) - 110) < 0.5 and math.abs((lo.X + hi.X) / 2 - 120) < 0.5 and math.abs((lo.Z + hi.Z) / 2 + 680) < 0.5, "el césped de malla encaja en nuestro campo (110 de largo, centrado)")
	check(math.abs(hi.Y - (stPitch.CFrame.Position.Y + 0.15)) < 0.2, "a ras de nuestro campo")
	check(not cesped.CanCollide, "el césped de malla no choca (el suelo sigue siendo el campo)")
	local alo, ahi = Kit.bounds(Kit.parts(em))
	check(ahi.X - alo.X <= 196.01 and ahi.Z - alo.Z <= 198.01, "el estadio de mallas cabe en la explanada")
end
check(stPitch.Transparency == 1 and stPitch.CanCollide ~= false, "nuestro campo escondido pero sigue de suelo")
check(stPost.Transparency == 1 and stPost.CanCollide ~= false, "postes escondidos pero chocan (el balón)")
check(stStand.Transparency == 1 and not stStand.CanCollide, "grada de bloques escondida (chocan las de malla)")
-- Instituto: en la manzana del colegio, sin pisar el colegio que se recorre
local inst = parent:FindFirstChild("Colegios") and parent.Colegios:FindFirstChild("Instituto")
check(inst ~= nil, "colegio de ladrillo en la manzana del colegio")
if inst then
	local lo, hi = Kit.bounds(Kit.parts(inst))
	local clo, chi = Kit.bounds({ colegioBody })
	check(not overlaps(lo, hi, clo, chi, 0.01), "no se mete en el colegio que se recorre")
	local g = mc.BlockGround
	local glo, ghi = Kit.bounds({ g })
	check(lo.X >= glo.X and hi.X <= ghi.X and lo.Z >= glo.Z and hi.Z <= ghi.Z, "dentro de su manzana")
	local box = inst:FindFirstChild("InstitutoChoque")
	check(box and box.CanCollide ~= false and box.Transparency == 1 and box:HasTag("BuildingShell"), "caja de choque invisible (Bajo la enseña)")
	local meshCollide = false
	for _, p in Kit.parts(inst) do
		if p ~= box and p.CanCollide then
			meshCollide = true
		end
	end
	check(not meshCollide, "las mallas del instituto no chocan (choca la caja)")
end
check(sky and sky:FindFirstChild("CiudadLejana"), "ciudad lejana de una malla en medio del skyline")

-- Oficina: dos armarios de servidores en la esquina libre
local room = model(nil, "Interior_Oficina")
part(room, "Floor", Vector3.new(52, 1, 40), CFrame.new(0, 499.5, 0))
local racks = CityAssets.dressOffice(room, ctx)
check(racks == 2, "dos armarios de servidores en la oficina")

-- Nada nuevo lleva scripts
local placedScripts = 0
for _, d in parent:GetDescendants() do
	if d:IsA("LuaSourceContainer") then
		placedScripts += 1
	end
end
check(placedScripts == 0, "nada de lo colocado lleva scripts")
check(ctx.Parts > 0 and ctx.Parts <= CityAssets.MaxParts, "piezas dentro del tope (" .. ctx.Parts .. ")")

---------------------------------------------------------------------
print("\n3) Si falla la carga, no pasa nada")
---------------------------------------------------------------------

warnings = {}
local emptyPools, emptyReport = CityAssets.loadAll(function()
	return nil
end)
local n = 0
for _ in emptyPools do
	n += 1
end
check(n == 0, "sin packs no hay plantillas")
check(emptyReport[5411055653] == "no carga", "el informe dice que no carga")
local boomPools = CityAssets.loadAll(function()
	error("HTTP 403")
end)
check(next(boomPools) == nil, "una carga que revienta no para nada")
local brokenPools = CityAssets.loadAll(function(id)
	local m = Instance.new("Model")
	m.Name = "Roto" .. id
	return m
end)
check(true, "packs vacíos o rotos no dan error")
local _ = brokenPools
local town2 = model(nil, "Town")
local p2 = Instance.new("Folder")
p2.Parent = town2
local ctx2 = { Town = town2, Pools = {}, Parent = p2, Query = query, Parts = 0, Counts = {} }
local okRun = pcall(CityAssets.run, ctx2)
check(okRun and ctx2.Parts == 0, "sin plantillas no se coloca nada y no hay errores")

print(("\n%s (%d fallos)"):format(if failures == 0 then "✅ Todo correcto" else "❌ Hay fallos", failures))
process.exit(if failures == 0 then 0 else 1)
