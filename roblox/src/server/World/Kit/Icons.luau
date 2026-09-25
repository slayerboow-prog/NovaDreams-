-- Icons: los edificios emblemáticos de Valmar (para orientarse y para el juego).
--   Torre de Valmar, Ayuntamiento, Estación Central (con andenes y tren), Estación de Autobuses,
--   Museo, Teatro, Centro Comercial Valmar, Parque de Atracciones (noria, montaña rusa, carrusel)
--   y Camping. Cada uno ocupa una manzana (los elige Kit/Districts según el plano).
-- Todos reciben el rectángulo de la manzana y un lado que da a la calle (Blocks.lot).

local Builder = require(script.Parent.Parent.Builder)
local Blocks = require(script.Parent.Blocks)
local Lite = require(script.Parent.Lite)
local Nature = require(script.Parent.Nature)
local Props = require(script.Parent.Props)

local Icons = {}

local rgb = Color3.fromRGB

type Rect = { X0: number, X1: number, Z0: number, Z1: number }

local function part(parent: Instance, name: string, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material?, decor: boolean?): BasePart
	local props = { Name = name, CFrame = cf, Size = size, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = parent }
	return if decor then Builder.decor(props) else Builder.part(props)
end

local function cyl(parent: Instance, name: string, cf: CFrame, length: number, diameter: number, color: Color3, material: Enum.Material?): BasePart
	-- Cilindro vertical (el eje del cilindro de Roblox es X: se gira)
	return part(parent, name, cf * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(length, diameter, diameter), color, material)
end

local function sign(parent: Instance, cf: CFrame, text: string, width: number, height: number, color: Color3?)
	local p = part(parent, "Sign", cf, Vector3.new(width, height, 0.4), color or rgb(24, 30, 44))
	Builder.sign(p, text, Enum.NormalId.Front)
	return p
end

local function plaza(parent: Instance, rect: Rect, color: Color3?)
	part(parent, "Plaza", CFrame.new((rect.X0 + rect.X1) / 2, 0.15, (rect.Z0 + rect.Z1) / 2), Vector3.new(rect.X1 - rect.X0 - 4, 0.3, rect.Z1 - rect.Z0 - 4), color or rgb(214, 206, 190), Enum.Material.Pavement)
end

local function columns(parent: Instance, cf: CFrame, width: number, count: number, height: number, color: Color3)
	for i = 0, count - 1 do
		local x = -width / 2 + width * (i + 0.5) / count
		cyl(parent, "Column", cf * CFrame.new(x, height / 2, 0), height, 3, color, Enum.Material.Marble)
	end
end

---------------------------------------------------------------------
-- Centro
---------------------------------------------------------------------

-- El rascacielos más alto de la ciudad: tres cuerpos de cristal, corona iluminada y aguja
function Icons.TorreValmar(parent: Instance, rect: Rect)
	local m = Builder.model("TorreValmar", parent)
	plaza(m, rect)
	local lot = Blocks.lot(rect, "S")
	local base = lot.facing(0, lot.Depth / 2, 0)
	local glass, band = rgb(70, 120, 170), rgb(220, 224, 230)
	local y, w = 0, 66
	for _, s in { { 30, 1 }, { 22, 0.8 }, { 16, 0.62 } } do
		local h = s[1] * 10
		local ww = w * s[2]
		local core = part(m, "Core", base * CFrame.new(0, y + h / 2, 0), Vector3.new(ww, h, ww), glass, Enum.Material.Glass)
		core.Reflectance = 0.2
		for f = 3, s[1], 3 do
			part(m, "Band", base * CFrame.new(0, y + f * 10, 0), Vector3.new(ww + 0.8, 1.2, ww + 0.8), band, Enum.Material.Concrete, true)
		end
		y += h
	end
	-- Corona que brilla de noche y aguja
	local crown = part(m, "Crown", base * CFrame.new(0, y + 6, 0), Vector3.new(w * 0.55, 12, w * 0.55), rgb(180, 220, 255), Enum.Material.Glass)
	crown:AddTag("NightWindow")
	crown:SetAttribute("DayColor", rgb(180, 220, 255))
	crown:SetAttribute("NightColor", rgb(120, 200, 255))
	crown:SetAttribute("OnAt", 18)
	crown:SetAttribute("OffAt", 30)
	part(m, "Spire", base * CFrame.new(0, y + 12 + 40, 0), Vector3.new(1.6, 80, 1.6), rgb(210, 214, 220), Enum.Material.Metal)
	part(m, "Beacon", base * CFrame.new(0, y + 93, 0), Vector3.new(2.4, 2.4, 2.4), rgb(255, 60, 60), Enum.Material.Neon, true)
	part(m, "Lobby", base * CFrame.new(0, 7, -w / 2 - 6), Vector3.new(40, 1, 12), rgb(50, 54, 60), Enum.Material.Metal)
	sign(m, base * CFrame.new(0, 11, -w / 2 - 0.5), "TORRE VALMAR", 36, 4)
	for _, x in { -60, 60 } do
		Nature.tree(m, (base * CFrame.new(x, 0, -30)).Position, 1.2)
	end
end

-- Ayuntamiento: edificio clásico con pórtico de columnas, torre del reloj y banderas
function Icons.Ayuntamiento(parent: Instance, rect: Rect)
	local m = Builder.model("Ayuntamiento", parent)
	plaza(m, rect)
	local lot = Blocks.lot(rect, "S")
	local base = lot.facing(0, lot.Depth * 0.55, 0)
	local stone, trim = rgb(236, 226, 206), rgb(250, 246, 238)
	part(m, "Body", base * CFrame.new(0, 14, 0), Vector3.new(140, 28, 60), stone, Enum.Material.Limestone)
	part(m, "Cornice", base * CFrame.new(0, 28.8, 0), Vector3.new(143, 1.6, 63), trim, Enum.Material.Marble)
	for i = 0, 2 do
		part(m, "Step", base * CFrame.new(0, 0.5 + i, -30 - 12 + i * 2), Vector3.new(60 - i * 4, 1, 6), trim, Enum.Material.Marble)
	end
	columns(m, base * CFrame.new(0, 3, -34), 50, 6, 22, trim)
	part(m, "Pediment", base * CFrame.new(0, 27, -34), Vector3.new(56, 3, 8), trim, Enum.Material.Marble)
	Builder.part({ ClassName = "WedgePart", Name = "Gable", Size = Vector3.new(56, 8, 4), CFrame = base * CFrame.new(0, 32.5, -36), Color = trim, Material = Enum.Material.Marble, Parent = m })
	for f = 0, 1 do
		part(m, "Windows", base * CFrame.new(-50, 8 + f * 11, -30.2), Vector3.new(30, 5, 0.3), rgb(70, 90, 110), Enum.Material.Glass, true)
		part(m, "Windows", base * CFrame.new(50, 8 + f * 11, -30.2), Vector3.new(30, 5, 0.3), rgb(70, 90, 110), Enum.Material.Glass, true)
	end
	-- Torre del reloj con cúpula
	part(m, "ClockTower", base * CFrame.new(0, 40, 10), Vector3.new(18, 24, 18), stone, Enum.Material.Limestone)
	-- Esfera del reloj (disco en la cara delantera de la torre)
	part(m, "Clock", base * CFrame.new(0, 44, 0.7) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(0.6, 12, 12), rgb(250, 248, 240), Enum.Material.SmoothPlastic).Shape = Enum.PartType.Cylinder
	part(m, "Dome", base * CFrame.new(0, 54, 10), Vector3.new(16, 16, 16), rgb(90, 140, 120), Enum.Material.Metal).Shape = Enum.PartType.Ball
	sign(m, base * CFrame.new(0, 24, -38.3), "AYUNTAMIENTO DE VALMAR", 44, 3, rgb(120, 30, 40))
	for _, x in { -20, 0, 20 } do
		part(m, "Flagpole", base * CFrame.new(x, 12, -50), Vector3.new(0.5, 24, 0.5), rgb(200, 200, 204), Enum.Material.Metal, true)
		part(m, "Flag", base * CFrame.new(x + 3, 21, -50), Vector3.new(6, 4, 0.2), if x == 0 then rgb(40, 90, 170) else rgb(200, 40, 50), Enum.Material.Fabric, true)
	end
	Lite.park(m, lot.facing(0, 18, 0), 120, 26, true)
end

-- Estación Central: vestíbulo con bóveda, andenes, vías y un tren parado
function Icons.EstacionCentral(parent: Instance, rect: Rect)
	local m = Builder.model("EstacionCentral", parent)
	plaza(m, rect, rgb(200, 196, 188))
	local lot = Blocks.lot(rect, "S")
	local base = lot.facing(0, 45, 0)
	local L = math.min(lot.Length - 20, 180)
	part(m, "Hall", base * CFrame.new(0, 10, 0), Vector3.new(L, 20, 60), rgb(214, 196, 170), Enum.Material.Brick)
	-- Bóveda: medio cilindro de cristal y hierro
	local vault = part(m, "Vault", base * CFrame.new(0, 20, 0), Vector3.new(L - 4, 56, 56), rgb(150, 190, 210), Enum.Material.Glass)
	vault.Shape = Enum.PartType.Cylinder
	vault.Transparency = 0.25
	for x = -L / 2 + 10, L / 2 - 10, 20 do
		local rib = part(m, "Rib", base * CFrame.new(x, 20, 0), Vector3.new(1, 57, 57), rgb(60, 64, 70), Enum.Material.Metal, true)
		rib.Shape = Enum.PartType.Cylinder
	end
	part(m, "Entrance", base * CFrame.new(0, 9, -30.3), Vector3.new(40, 14, 0.4), rgb(150, 190, 210), Enum.Material.Glass, true)
	sign(m, base * CFrame.new(0, 18, -30.6), "ESTACIÓN CENTRAL", 50, 5, rgb(20, 60, 120))
	part(m, "Clock", base * CFrame.new(38, 16, -30.6) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(0.5, 8, 8), rgb(250, 248, 240)).Shape = Enum.PartType.Cylinder
	-- Andenes y vías detrás del vestíbulo
	local back = lot.facing(0, 120, 0)
	for i = -1, 1 do
		part(m, "Platform", back * CFrame.new(0, 1, i * 26), Vector3.new(L, 2, 8), rgb(196, 192, 184), Enum.Material.Concrete)
		part(m, "PlatformRoof", back * CFrame.new(0, 12, i * 26), Vector3.new(L * 0.8, 0.6, 10), rgb(60, 64, 70), Enum.Material.Metal)
		for x = -L * 0.35, L * 0.35, 30 do
			part(m, "Post", back * CFrame.new(x, 6.5, i * 26), Vector3.new(0.6, 11, 0.6), rgb(60, 64, 70), Enum.Material.Metal, true)
		end
	end
	for _, z in { -13, 13 } do
		part(m, "Ballast", back * CFrame.new(0, 0.2, z), Vector3.new(L, 0.4, 12), rgb(120, 110, 100), Enum.Material.Pebble)
		for _, r in { -2.3, 2.3 } do
			part(m, "Rail", back * CFrame.new(0, 0.6, z + r), Vector3.new(L, 0.4, 0.3), rgb(150, 150, 156), Enum.Material.Metal, true)
		end
	end
	-- Tren parado en la vía 1
	for i = 0, 3 do
		local car = back * CFrame.new(-L / 2 + 30 + i * 24, 5.2, -13)
		part(m, "Carriage", car, Vector3.new(22, 8, 8), if i == 0 then rgb(200, 40, 50) else rgb(236, 236, 240), Enum.Material.SmoothPlastic)
		part(m, "TrainWindows", car * CFrame.new(0, 1.2, -4.05), Vector3.new(18, 2.4, 0.2), rgb(40, 60, 80), Enum.Material.Glass, true)
	end
end

-- Estación de autobuses: gran marquesina con dársenas y autobuses
function Icons.EstacionAutobuses(parent: Instance, rect: Rect)
	local m = Builder.model("EstacionAutobuses", parent)
	plaza(m, rect, rgb(120, 122, 126))
	local lot = Blocks.lot(rect, "S")
	local base = lot.facing(0, 70, 0)
	local L = math.min(lot.Length - 30, 170)
	part(m, "Canopy", base * CFrame.new(0, 14, 0), Vector3.new(L, 1, 40), rgb(230, 232, 236), Enum.Material.Metal)
	for x = -L / 2 + 5, L / 2 - 5, 24 do
		part(m, "Pillar", base * CFrame.new(x, 7, 0), Vector3.new(1.2, 14, 1.2), rgb(60, 64, 70), Enum.Material.Metal, true)
	end
	part(m, "Terminal", base * CFrame.new(0, 6, 34), Vector3.new(L * 0.6, 12, 20), rgb(200, 206, 214), Enum.Material.Concrete)
	part(m, "TerminalGlass", base * CFrame.new(0, 6, 23.8), Vector3.new(L * 0.55, 8, 0.3), rgb(140, 180, 200), Enum.Material.Glass, true)
	sign(m, base * CFrame.new(0, 17, -20.4), "ESTACIÓN DE AUTOBUSES", 44, 4, rgb(20, 110, 60))
	for i = 0, 3 do
		local bus = base * CFrame.new(-L / 2 + 25 + i * 38, 0, -4)
		part(m, "Bus", bus * CFrame.new(0, 5.5, 0), Vector3.new(8, 9, 30), rgb(30, 120, 190), Enum.Material.SmoothPlastic)
		part(m, "BusWindows", bus * CFrame.new(4.05, 7, 0), Vector3.new(0.2, 3, 26), rgb(40, 60, 80), Enum.Material.Glass, true)
		part(m, "BusWindows", bus * CFrame.new(-4.05, 7, 0), Vector3.new(0.2, 3, 26), rgb(40, 60, 80), Enum.Material.Glass, true)
	end
end

-- Museo: edificio clásico con columnata, escalinata y escultura en la plaza
function Icons.Museo(parent: Instance, rect: Rect)
	local m = Builder.model("Museo", parent)
	plaza(m, rect)
	local lot = Blocks.lot(rect, "S")
	local base = lot.facing(0, lot.Depth * 0.55, 0)
	local stone = rgb(240, 236, 226)
	part(m, "Body", base * CFrame.new(0, 12, 0), Vector3.new(120, 24, 70), stone, Enum.Material.Marble)
	columns(m, base * CFrame.new(0, 2, -40), 90, 10, 20, stone)
	part(m, "Pediment", base * CFrame.new(0, 23, -40), Vector3.new(96, 3, 8), stone, Enum.Material.Marble)
	for i = 0, 1 do
		part(m, "Step", base * CFrame.new(0, 0.5 + i, -48 + i * 2), Vector3.new(96 - i * 4, 1, 6), stone, Enum.Material.Marble)
	end
	sign(m, base * CFrame.new(0, 21, -44.3), "MUSEO DE VALMAR", 40, 3, rgb(60, 40, 30))
	-- Escultura moderna
	local s = lot.facing(0, 20, 0)
	part(m, "Plinth", s * CFrame.new(0, 1.5, 0), Vector3.new(8, 3, 8), rgb(60, 60, 64), Enum.Material.Granite)
	part(m, "Sculpture", s * CFrame.new(0, 9, 0) * CFrame.Angles(0.4, 0.6, 0.3), Vector3.new(3, 12, 3), rgb(200, 90, 40), Enum.Material.Metal)
	part(m, "Sculpture", s * CFrame.new(1, 10, 0) * CFrame.Angles(-0.5, 0.2, -0.4), Vector3.new(2.4, 10, 2.4), rgb(200, 90, 40), Enum.Material.Metal)
end

-- Teatro: fachada con marquesina iluminada
function Icons.Teatro(parent: Instance, rect: Rect)
	local m = Builder.model("Teatro", parent)
	plaza(m, rect)
	local lot = Blocks.lot(rect, "S")
	local base = lot.facing(0, lot.Depth * 0.5, 0)
	part(m, "Body", base * CFrame.new(0, 16, 0), Vector3.new(110, 32, 80), rgb(150, 40, 50), Enum.Material.Brick)
	part(m, "FlyTower", base * CFrame.new(0, 38, 20), Vector3.new(60, 12, 30), rgb(130, 34, 44), Enum.Material.Brick)
	columns(m, base * CFrame.new(0, 0, -42), 60, 6, 18, rgb(240, 232, 214))
	local marquee = part(m, "Marquee", base * CFrame.new(0, 19, -46), Vector3.new(70, 3, 10), rgb(255, 214, 120), Enum.Material.Neon)
	marquee:AddTag("NightWindow")
	marquee:SetAttribute("DayColor", rgb(236, 200, 120))
	marquee:SetAttribute("NightColor", rgb(255, 220, 130))
	marquee.Material = Enum.Material.SmoothPlastic
	sign(m, base * CFrame.new(0, 25, -40.3), "TEATRO PRINCIPAL", 46, 4, rgb(30, 20, 20))
end

---------------------------------------------------------------------
-- Este: compras y ocio
---------------------------------------------------------------------
local MALL_SHOPS = { "MODA", "ZAPATOS", "TECNOLOGÍA", "MUEBLES", "CINE", "SUPERMERCADO", "JUGUETES", "DEPORTES", "VIDEOJUEGOS", "PELUQUERÍA", "LUJO", "RESTAURANTES" }

function Icons.GranCentroComercial(parent: Instance, rect: Rect)
	local m = Builder.model("GranCentroComercial", parent)
	local lot = Blocks.lot(rect, "S")
	local L = lot.Length - 16
	local base = lot.facing(0, 40 + 60, 0)
	part(m, "Floor", CFrame.new((rect.X0 + rect.X1) / 2, 0.15, (rect.Z0 + rect.Z1) / 2), Vector3.new(rect.X1 - rect.X0 - 4, 0.3, rect.Z1 - rect.Z0 - 4), rgb(70, 72, 76), Enum.Material.Asphalt)
	part(m, "Body", base * CFrame.new(0, 13, 0), Vector3.new(L, 26, 120), rgb(236, 236, 232), Enum.Material.Concrete)
	part(m, "Roof", base * CFrame.new(0, 26.5, 0), Vector3.new(L + 1, 1, 121), rgb(200, 202, 206), Enum.Material.Concrete)
	part(m, "Band", base * CFrame.new(0, 24, -60.4), Vector3.new(L + 1, 3, 0.6), rgb(40, 90, 160), Enum.Material.Metal)
	-- Atrio de cristal en la entrada
	local atrium = part(m, "Atrium", base * CFrame.new(0, 16, -60), Vector3.new(50, 32, 40), rgb(140, 190, 220), Enum.Material.Glass)
	atrium.Shape = Enum.PartType.Cylinder
	atrium.CFrame = base * CFrame.new(0, 16, -60) * CFrame.Angles(0, 0, math.rad(90))
	atrium.Size = Vector3.new(32, 44, 44)
	atrium.Transparency = 0.25
	sign(m, base * CFrame.new(0, 30.5, -60.5), "CENTRO COMERCIAL VALMAR", 60, 5, rgb(40, 90, 160))
	-- Escaparates con los nombres de las tiendas
	for i, name in MALL_SHOPS do
		local col = (i - 1) % 6
		local side = if i <= 6 then -1 else 1
		local x = side * (40 + col * ((L / 2 - 50) / 6))
		if math.abs(x) < L / 2 - 8 then
			part(m, "ShopGlass", base * CFrame.new(x, 5, -60.2), Vector3.new(14, 8, 0.3), rgb(150, 190, 210), Enum.Material.Glass, true)
			sign(m, base * CFrame.new(x, 11, -60.4), name, 14, 2, rgb(24, 28, 36))
		end
	end
	-- Aparcamiento delante
	local park = lot.facing(0, 20, 0)
	for x = -L / 2 + 8, L / 2 - 8, 9 do
		part(m, "Line", park * CFrame.new(x, 0.32, 0), Vector3.new(0.35, 0.05, 14), rgb(236, 236, 230), nil, true)
	end
	for _ = 1, 6 do
		Props.car(m, park * CFrame.new(math.random(-8, 8) * 9 + 4.5, 0.3, 0) * CFrame.Angles(0, math.rad(90), 0))
	end
end

-- Parque de atracciones: noria, montaña rusa, carrusel y taquilla
function Icons.Feria(parent: Instance, rect: Rect)
	local m = Builder.model("Feria", parent)
	local cx, cz = (rect.X0 + rect.X1) / 2, (rect.Z0 + rect.Z1) / 2
	part(m, "Ground", CFrame.new(cx, 0.15, cz), Vector3.new(rect.X1 - rect.X0 - 4, 0.3, rect.Z1 - rect.Z0 - 4), rgb(206, 190, 160), Enum.Material.Pavement)
	-- Noria (vertical, en el plano X-Y)
	local wheel = CFrame.new(cx - 50, 0, cz - 40)
	local R = 34
	for _, dz in { -4, 4 } do
		part(m, "Leg", wheel * CFrame.new(-12, R / 2 + 2, dz) * CFrame.Angles(0, 0, math.rad(-20)), Vector3.new(2, R + 8, 2), rgb(240, 240, 244), Enum.Material.Metal)
		part(m, "Leg", wheel * CFrame.new(12, R / 2 + 2, dz) * CFrame.Angles(0, 0, math.rad(20)), Vector3.new(2, R + 8, 2), rgb(240, 240, 244), Enum.Material.Metal)
	end
	local hub = wheel * CFrame.new(0, R + 4, 0)
	part(m, "Hub", hub * CFrame.Angles(0, math.rad(90), 0), Vector3.new(10, 5, 5), rgb(200, 40, 50), Enum.Material.Metal).Shape = Enum.PartType.Cylinder
	local cabins = { rgb(230, 70, 70), rgb(250, 200, 60), rgb(70, 160, 230), rgb(90, 200, 120) }
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		local p = hub * CFrame.new(math.cos(a) * R, math.sin(a) * R, 0)
		part(m, "Spoke", hub * CFrame.Angles(0, 0, a) * CFrame.new(R / 2, 0, 0), Vector3.new(R, 0.6, 0.6), rgb(240, 240, 244), Enum.Material.Metal, true)
		-- Tramo del aro (tangente al círculo, entre este radio y el siguiente)
		local chord = 2 * R * math.sin(math.pi / 16)
		part(m, "Rim", hub * CFrame.Angles(0, 0, a + math.pi / 16) * CFrame.new(R * math.cos(math.pi / 16), 0, 0), Vector3.new(0.8, chord + 0.4, 0.8), rgb(240, 240, 244), Enum.Material.Metal, true)
		if i % 2 == 0 then
			part(m, "Cabin", CFrame.new(p.Position - Vector3.new(0, 3, 0)), Vector3.new(4, 4, 5), cabins[(i / 2) % 4 + 1], Enum.Material.SmoothPlastic)
		end
	end
	-- Montaña rusa: vía sobre pilares que sube y baja
	local coaster = CFrame.new(cx + 30, 0, cz + 50)
	local prev: Vector3? = nil
	for i = 0, 12 do
		local x = -60 + i * 10
		local h = 8 + math.abs(math.sin(i * 0.7)) * 26
		local p = (coaster * CFrame.new(x, h, math.sin(i * 0.5) * 8)).Position
		part(m, "Pillar", CFrame.new(p.X, h / 2, p.Z), Vector3.new(1, h, 1), rgb(60, 64, 70), Enum.Material.Metal, true)
		if prev then
			local mid = (prev + p) / 2
			local d = p - prev
			local yaw = math.atan2(-d.X, -d.Z)
			local pitch = math.asin(d.Y / d.Magnitude)
			part(m, "Track", CFrame.new(mid) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0), Vector3.new(4, 0.8, d.Magnitude + 0.4), rgb(230, 60, 60), Enum.Material.Metal)
		end
		prev = p
	end
	-- Carrusel
	local car = CFrame.new(cx + 50, 0, cz - 50)
	cyl(m, "CarouselBase", car * CFrame.new(0, 1, 0), 2, 26, rgb(240, 220, 160), Enum.Material.Wood)
	cyl(m, "CarouselRoof", car * CFrame.new(0, 12, 0), 2, 28, rgb(220, 60, 80), Enum.Material.Fabric)
	cyl(m, "CarouselPole", car * CFrame.new(0, 6, 0), 10, 3, rgb(250, 230, 150), Enum.Material.Metal)
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		part(m, "Horse", car * CFrame.new(math.cos(a) * 9, 4, math.sin(a) * 9), Vector3.new(1.4, 3, 4), rgb(250, 250, 250), Enum.Material.SmoothPlastic, true)
	end
	-- Taquilla y cartel
	local lot = Blocks.lot(rect, "S")
	part(m, "Booth", lot.facing(-30, 8, 4), Vector3.new(10, 8, 6), rgb(250, 200, 60), Enum.Material.Plastic)
	sign(m, lot.facing(0, 3, 12), "PARQUE DE ATRACCIONES", 40, 4, rgb(200, 40, 60))
	for _, x in { -20, 20 } do
		part(m, "SignPost", lot.facing(x, 3, 5), Vector3.new(0.8, 10, 0.8), rgb(60, 64, 70), Enum.Material.Metal)
	end
end

---------------------------------------------------------------------
-- Oeste: naturaleza
---------------------------------------------------------------------
function Icons.Camping(parent: Instance, rect: Rect)
	local m = Builder.model("Camping", parent)
	local cx, cz = (rect.X0 + rect.X1) / 2, (rect.Z0 + rect.Z1) / 2
	local colors = { rgb(230, 120, 40), rgb(60, 140, 90), rgb(60, 110, 190), rgb(220, 190, 60), rgb(190, 60, 60) }
	for i = 0, 9 do
		local x, z = cx - 70 + (i % 5) * 35, cz - 40 + math.floor(i / 5) * 50
		local tent = CFrame.new(x, 0, z) * CFrame.Angles(0, math.random() * 0.6, 0)
		local c = colors[i % #colors + 1]
		Builder.part({ ClassName = "WedgePart", Name = "Tent", Size = Vector3.new(8, 5, 4), CFrame = tent * CFrame.new(0, 2.5, -2), Color = c, Material = Enum.Material.Fabric, Parent = m })
		Builder.part({ ClassName = "WedgePart", Name = "Tent", Size = Vector3.new(8, 5, 4), CFrame = tent * CFrame.new(0, 2.5, 2) * CFrame.Angles(0, math.pi, 0), Color = c, Material = Enum.Material.Fabric, Parent = m })
	end
	for i = 0, 2 do
		local van = CFrame.new(cx + 70, 0, cz - 60 + i * 45)
		part(m, "Caravan", van * CFrame.new(0, 5, 0), Vector3.new(9, 8, 20), rgb(240, 240, 236), Enum.Material.SmoothPlastic)
		part(m, "CaravanStripe", van * CFrame.new(0, 4, 0), Vector3.new(9.1, 1, 20.1), rgb(60, 120, 180), Enum.Material.SmoothPlastic, true)
	end
	-- Hoguera y recepción
	cyl(m, "FireRing", CFrame.new(cx, 0.5, cz + 10), 1, 6, rgb(110, 106, 100), Enum.Material.Slate)
	local fire = part(m, "Fire", CFrame.new(cx, 1.5, cz + 10), Vector3.new(2, 2, 2), rgb(255, 140, 40), Enum.Material.Neon, true)
	local light = Instance.new("PointLight")
	light.Color = rgb(255, 150, 60)
	light.Range = 20
	light.Brightness = 2
	light.Parent = fire
	local lot = Blocks.lot(rect, "S")
	part(m, "Reception", lot.facing(-60, 12, 0) * CFrame.new(0, 4.5, 0), Vector3.new(20, 9, 14), rgb(150, 110, 76), Enum.Material.WoodPlanks)
	sign(m, lot.facing(0, 3, 6), "CAMPING VALMAR", 26, 3, rgb(40, 100, 60))
	for _ = 1, 14 do
		Nature.tree(m, Vector3.new(cx + math.random(-100, 100), 0, cz + math.random(-100, 100)), 1 + math.random() * 0.5)
	end
end

return Icons
