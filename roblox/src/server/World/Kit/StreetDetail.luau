-- StreetDetail: los detalles pequeños que hacen que la calle parezca de verdad.
--
--   * En la franja de la acera junto al bordillo (entre farolas y árboles): bolardos, bocas de riego,
--     jardineras, aparcabicis, quioscos de prensa, mupis con anuncios, motos aparcadas, contenedores
--     de reciclaje, armarios eléctricos con grafitis, señales de zona azul y obras con conos y vallas.
--     Lo que sale depende del distrito (Centro, Este, Sur…): cada barrio tiene su aire.
--   * En la calzada: tapas de alcantarilla y rejillas junto al bordillo.
--   * En los cruces: el poste con el nombre de las dos calles.
--   * En las farolas del centro y de la zona de ocio: banderolas.
--   * Delante de las tiendas: terrazas con mesa y sombrilla, cajas de fruta, cubos de flores, pizarras.
--   * En las fachadas: aparatos de aire acondicionado, macetas y ropa tendida en los balcones.
--
-- Rendimiento: casi todo es decorativo (Builder.decor: sin colisiones, sin consultas y sin sombra si es
-- pequeño), con pocas piezas por objeto. Los objetos de la acera llevan la etiqueta LiteDetail: en
-- el modo ligero (móviles) el cliente los quita al cargarlos (UI/Perf). El azar sale de la posición
-- (no de math.random), así el resto del mapa no cambia al añadir o quitar detalles.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Builder = require(script.Parent.Parent.Builder)
local MetroAccess = require(script.Parent.MetroAccess)
local CityPlan = require(ReplicatedStorage.Shared.CityPlan)

local StreetDetail = {}

local rgb = Color3.fromRGB
local V3 = Vector3.new
local METAL = rgb(58, 62, 68)
local DARK = rgb(34, 36, 42)

StreetDetail.Count = 0 -- objetos puestos (para las pruebas y el informe)

-- Azar fijo según el sitio: 0..1 (cada "salt" da un número distinto e independiente)
local function hash(x: number, z: number, salt: number): number
	local v = math.sin(x * 12.9898 + z * 78.233 + salt * 37.719) * 43758.5453
	v -= math.floor(v)
	local w = math.sin(v * 91.345 + salt * 3.117 + x * 0.013) * 24634.6345
	return w - math.floor(w)
end

local function decor(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
	local props = { Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = parent }
	for k, v in extra or {} do
		props[k] = v
	end
	return Builder.decor(props)
end

local function solid(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
	local props = { Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, CastShadow = false, Parent = parent }
	for k, v in extra or {} do
		props[k] = v
	end
	return Builder.part(props)
end

local function cyl(parent: Instance, name: string, height: number, diameter: number, cf: CFrame, color: Color3, material: Enum.Material?, collide: boolean?): BasePart
	local fn = if collide then solid else decor
	return fn(parent, name, V3(height, diameter, diameter), cf * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), color, material, { Shape = Enum.PartType.Cylinder })
end

local function item(parent: Instance, name: string): Model
	local m = Builder.model(name, parent)
	m:AddTag("LiteDetail")
	StreetDetail.Count += 1
	return m
end

---------------------------------------------------------------------
-- Objetos de la acera (cf en el suelo de la acera, mirando a la calzada: -Z)
---------------------------------------------------------------------

local ADS = {
	{ "🎬 CINE VALMAR\nEstreno este viernes", rgb(120, 40, 160) },
	{ "🏖️ PLAYA DORADA\nTu verano empieza aquí", rgb(40, 160, 200) },
	{ "🍔 MEGA BURGER\nMenú gigante 5 €", rgb(230, 120, 30) },
	{ "🚇 METRO DE VALMAR\nLlega antes", rgb(200, 30, 40) },
	{ "🎡 FERIA\nNoria y algodón de azúcar", rgb(240, 170, 30) },
	{ "📚 BIBLIOTECA\nEntrada libre", rgb(40, 120, 80) },
	{ "⚽ VALMAR F.C.\nEl domingo, al estadio", rgb(30, 90, 170) },
	{ "🎵 CONCIERTO\nPlaza Mayor, 22:00", rgb(200, 60, 120) },
}
local GRAFFITI = { "VLM", "ZONA 8", "☮", "HOLA", "SK8", "VALMAR", "★" }
local GRAFFITI_COLORS = { rgb(240, 60, 150), rgb(60, 220, 120), rgb(250, 210, 40), rgb(60, 160, 250), rgb(250, 110, 40) }

local Kinds: { [string]: (Instance, CFrame, number) -> () } = {}

-- Bolardos (tres postes)
Kinds.Bollards = function(parent, cf, r)
	local m = item(parent, "Bolardos")
	local color = if r < 0.5 then rgb(40, 44, 50) else rgb(150, 150, 146)
	for _, x in { -2.4, 0, 2.4 } do
		cyl(m, "Bollard", 2.6, 0.6, cf * CFrame.new(x, 0, -0.4), color, Enum.Material.Metal, true)
	end
end

-- Boca de riego (de bomberos)
Kinds.Hydrant = function(parent, cf, r)
	local m = item(parent, "BocaRiego")
	local color = if r < 0.6 then rgb(200, 40, 36) else rgb(236, 190, 40)
	cyl(m, "Hydrant", 2.2, 0.9, cf, color, Enum.Material.Metal, true)
	decor(m, "HydrantCap", V3(1.5, 0.35, 0.5), cf * CFrame.new(0, 1.5, 0), color, Enum.Material.Metal)
end

-- Jardinera con arbusto o flores
Kinds.Planter = function(parent, cf, r)
	local m = item(parent, "Jardinera")
	local pots = { rgb(180, 110, 70), rgb(150, 150, 146), rgb(70, 74, 80), rgb(210, 200, 180) }
	solid(m, "Planter", V3(3.6, 1.6, 1.8), cf * CFrame.new(0, 0.8, 0), pots[math.floor(r * #pots) % #pots + 1], Enum.Material.Concrete)
	local green = if r < 0.4 then rgb(76, 112, 56) else rgb(62, 98, 50)
	decor(m, "Shrub", V3(3.2, 1.6, 1.5), cf * CFrame.new(0, 2.1, 0), green, Enum.Material.LeafyGrass, { Shape = Enum.PartType.Ball })
	if r > 0.55 then
		decor(m, "Flowers", V3(2.6, 0.5, 1.1), cf * CFrame.new(0, 2.8, 0), if r > 0.8 then rgb(226, 72, 92) else rgb(246, 196, 60), Enum.Material.SmoothPlastic)
	end
end

-- Aparcabicis (tres arcos) y, a veces, una bici atada
Kinds.BikeRack = function(parent, cf, r)
	local m = item(parent, "Aparcabicis")
	for _, x in { -1.6, 0, 1.6 } do
		decor(m, "Hoop", V3(0.2, 2, 1.6), cf * CFrame.new(x, 1, 0), rgb(150, 154, 160), Enum.Material.Metal)
	end
	if r > 0.5 then
		local bike = cf * CFrame.new(0.8, 0, 0.1) * CFrame.Angles(0, math.rad(90), 0)
		for _, z in { -1.2, 1.2 } do
			decor(m, "BikeWheel", V3(0.15, 1.9, 1.9), bike * CFrame.new(0, 0.95, z) * CFrame.Angles(0, math.rad(90), 0), DARK, Enum.Material.Rubber, { Shape = Enum.PartType.Cylinder })
		end
		decor(m, "BikeFrame", V3(0.2, 0.2, 2.4), bike * CFrame.new(0, 1.6, 0), if r > 0.75 then rgb(200, 50, 50) else rgb(40, 120, 190), Enum.Material.Metal)
	end
end

-- Quiosco de prensa
Kinds.Kiosk = function(parent, cf, r)
	local m = item(parent, "QuioscoPrensa")
	local color = if r < 0.5 then rgb(40, 100, 60) else rgb(30, 70, 120)
	local k = cf * CFrame.new(0, 0, 0.2)
	solid(m, "KioskBody", V3(5, 5.4, 3), k * CFrame.new(0, 2.7, 0), color, Enum.Material.Metal)
	decor(m, "KioskRoof", V3(6, 0.4, 4.4), k * CFrame.new(0, 5.6, -0.4), color:Lerp(rgb(0, 0, 0), 0.3), Enum.Material.Metal)
	local rack = decor(m, "Magazines", V3(4.4, 2.2, 0.12), k * CFrame.new(0, 2.8, -1.56), rgb(236, 230, 214))
	Builder.sign(rack, "📰 PRENSA · REVISTAS · CROMOS", Enum.NormalId.Front, DARK, rgb(236, 230, 214))
	decor(m, "Counter", V3(4.6, 0.3, 0.8), k * CFrame.new(0, 1.7, -1.8), rgb(120, 90, 60), Enum.Material.Wood)
end

-- Mupi: anuncio iluminado a dos caras
Kinds.Mupi = function(parent, cf, r)
	local m = item(parent, "Mupi")
	local ad = ADS[math.floor(r * #ADS) % #ADS + 1]
	local c = cf * CFrame.Angles(0, math.rad(90), 0) -- de canto a la calle (se lee al pasar)
	-- (el marco apoya en la acera: antes flotaba 0,6 studs)
	solid(m, "MupiFrame", V3(3.2, 6, 0.6), c * CFrame.new(0, 3, 0), rgb(70, 74, 80), Enum.Material.Metal)
	local board = decor(m, "MupiAd", V3(2.8, 4.2, 0.7), c * CFrame.new(0, 3.3, 0), ad[2], Enum.Material.Neon, { Transparency = 0.15 })
	Builder.sign(board, ad[1], Enum.NormalId.Front, Color3.new(1, 1, 1), ad[2])
	Builder.sign(board, ad[1], Enum.NormalId.Back, Color3.new(1, 1, 1), ad[2])
end

-- Moto o patinete aparcado
Kinds.Scooter = function(parent, cf, r)
	local m = item(parent, "MotoAparcada")
	local s = cf * CFrame.new(0, 0, 0.3) * CFrame.Angles(0, math.rad(if r < 0.5 then 90 else -90), 0)
	local colors = { rgb(200, 40, 40), rgb(240, 240, 240), rgb(30, 30, 34), rgb(60, 150, 210), rgb(240, 190, 40) }
	local color = colors[math.floor(r * 17) % #colors + 1]
	for _, z in { -1.5, 1.5 } do
		decor(m, "Wheel", V3(0.5, 1.5, 1.5), s * CFrame.new(0, 0.75, z) * CFrame.Angles(0, math.rad(90), 0), DARK, Enum.Material.Rubber, { Shape = Enum.PartType.Cylinder })
	end
	solid(m, "ScooterBody", V3(1.2, 1.4, 3.2), s * CFrame.new(0, 1.6, 0.2), color, Enum.Material.SmoothPlastic)
	decor(m, "Handlebar", V3(1.8, 1.6, 0.25), s * CFrame.new(0, 2.6, -1.4), METAL, Enum.Material.Metal)
end

-- Contenedores de reciclaje (verde, azul y amarillo)
Kinds.Recycling = function(parent, cf, _r)
	local m = item(parent, "Reciclaje")
	for i, color in { rgb(40, 120, 60), rgb(40, 80, 160), rgb(220, 180, 40) } do
		solid(m, "Container", V3(2.2, 3.4, 2.2), cf * CFrame.new((i - 2) * 2.4, 1.7, 0), color, Enum.Material.Plastic)
	end
end

-- Armario eléctrico (con algún grafiti)
Kinds.Cabinet = function(parent, cf, r)
	local m = item(parent, "ArmarioElectrico")
	local c = cf * CFrame.new(0, 0, 0.3)
	solid(m, "Cabinet", V3(2.6, 3.6, 1.2), c * CFrame.new(0, 1.8, 0), rgb(150, 150, 140), Enum.Material.Metal)
	if r > 0.35 then
		local tag = decor(m, "Graffiti", V3(2.4, 1.6, 0.05), c * CFrame.new(0, 2, -0.63), Color3.new(0, 0, 0), nil, { Transparency = 1 })
		local label = Builder.sign(tag, GRAFFITI[math.floor(r * 53) % #GRAFFITI + 1], Enum.NormalId.Front, GRAFFITI_COLORS[math.floor(r * 31) % #GRAFFITI_COLORS + 1])
		label.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
		label.Rotation = -8
	end
end

-- Señal de zona azul / carga y descarga
Kinds.Sign = function(parent, cf, r)
	local m = item(parent, "Senal")
	solid(m, "SignPole", V3(0.25, 7, 0.25), cf * CFrame.new(0, 3.5, 0), rgb(150, 154, 160), Enum.Material.Metal)
	local blue = r < 0.6
	local plate = decor(m, "SignPlate", V3(1.8, 1.8, 0.1), cf * CFrame.new(0, 6.2, -0.1), if blue then rgb(30, 90, 190) else rgb(240, 240, 240))
	Builder.sign(plate, if blue then "P\nZONA AZUL" else "🚚\nCARGA Y\nDESCARGA", Enum.NormalId.Front, if blue then Color3.new(1, 1, 1) else rgb(30, 90, 190))
end

-- Obras: vallas, conos y un saco
Kinds.Works = function(parent, cf, _r)
	local m = item(parent, "Obras")
	decor(m, "WorksFence", V3(5, 2.6, 0.2), cf * CFrame.new(0, 1.3, 0.2), rgb(240, 120, 30), Enum.Material.Plastic)
	decor(m, "WorksStripe", V3(5.02, 0.4, 0.22), cf * CFrame.new(0, 2.2, 0.2), rgb(245, 245, 245))
	for _, x in { -2, 0.2, 2.2 } do
		decor(m, "Cone", V3(0.8, 1.6, 0.8), cf * CFrame.new(x, 0.8, -0.8), rgb(250, 110, 30), Enum.Material.Plastic)
	end
	-- Barrera invisible para que no se atraviese la valla (una sola pieza)
	Builder.part({ Name = "WorksBarrier", Size = V3(5.2, 3, 1.6), CFrame = cf * CFrame.new(0, 1.5, -0.2), Transparency = 1, CastShadow = false, Parent = m })
end

-- Qué sale en cada distrito (peso relativo)
local WEIGHTS = {
	Centro = { Mupi = 3, Planter = 3, Kiosk = 1.2, BikeRack = 2, Bollards = 2, Hydrant = 1, Scooter = 2, Sign = 1.5, Cabinet = 0.6, Recycling = 0.6, Works = 0.4 },
	Este = { Mupi = 3, Planter = 3, Scooter = 2.5, Kiosk = 0.8, BikeRack = 1.5, Bollards = 1, Sign = 1, Hydrant = 0.8, Recycling = 0.6, Works = 0.3 },
	Norte = { Planter = 3, BikeRack = 2, Recycling = 2, Hydrant = 1.5, Sign = 1, Scooter = 1, Cabinet = 0.8, Mupi = 0.6, Works = 0.4 },
	Oeste = { Planter = 4, Bollards = 2.5, Mupi = 1, Scooter = 1.5, Hydrant = 1, Sign = 0.8, BikeRack = 1 },
	Universitario = { BikeRack = 4, Scooter = 3, Mupi = 2, Planter = 1.5, Cabinet = 1, Recycling = 1, Kiosk = 0.6, Sign = 1 },
	Sur = { Recycling = 2.5, Cabinet = 2.5, Hydrant = 2, Works = 1.5, Sign = 2, Bollards = 1, Scooter = 1, Planter = 0.5 },
	Campo = { Hydrant = 1, Cabinet = 1, Sign = 0.5 },
}

local function districtOf(x: number, z: number): string
	local d = CityPlan.districtAt(x, z)
	return if d then d.Id else "Campo"
end

local function choose(weights: { [string]: number }, r: number): string?
	local total = 0
	local keys = {}
	for k, w in weights do
		total += w
		table.insert(keys, k)
	end
	table.sort(keys) -- (orden fijo: el mismo resultado en cada construcción)
	local t = r * total
	for _, k in keys do
		t -= weights[k]
		if t <= 0 then
			return k
		end
	end
	return keys[#keys]
end

---------------------------------------------------------------------
-- Tramo de calle (lo llama Kit/Street)
--   point(u, v, y) → posición; along / across(sign) → direcciones; RW = ancho de la calzada;
--   lampAt(u) → ¿hay farola en u? (para no pisarla)
---------------------------------------------------------------------
function StreetDetail.segment(parent: Instance, road: any, u0: number, u1: number, point: (number, number, number) -> Vector3, across: (number) -> Vector3, RW: number, walkTop: number, roadTop: number, free: ((number, number) -> boolean)?)
	local length = u1 - u0
	if length < 30 then
		return
	end
	local folder = nil
	local function holder(): Instance
		if not folder then
			folder = Builder.model("Detalles", parent)
		end
		return folder :: Instance
	end
	local mid = point((u0 + u1) / 2, 0, 0)
	local district = districtOf(mid.X, mid.Z)
	local weights = WEIGHTS[district]
	local rural = district == "Campo"
	-- Objetos de la acera: a medio camino entre farolas (las farolas van cada 36 desde u0 + 12)
	local every = road.LampEvery or 36
	local slot = 0
	local u = u0 + 30
	while u <= u1 - 10 do
		slot += 1
		for _, s in { -1, 1 } do
			local p = point(u, s * (RW / 2 + 2.2), walkTop)
			local r = hash(p.X, p.Z, 1)
			local fill = if rural then 0.08 else 0.42
			if r < fill and not MetroAccess.blocked(p.X, p.Z) and (not free or free(u, s)) then
				local kind = choose(weights, hash(p.X, p.Z, 2))
				local fn = kind and Kinds[kind]
				if fn then
					fn(holder(), Builder.facing(p, across(-s)), hash(p.X, p.Z, 3))
				end
			end
		end
		u += every
	end
	-- En la calzada: tapas de alcantarilla (en el centro de un carril) y rejillas junto al bordillo
	if not rural then
		local k = 0
		u = u0 + 20
		while u <= u1 - 10 do
			k += 1
			local s = if k % 2 == 0 then 1 else -1
			local p = point(u, s * RW / 4, roadTop)
			decor(holder(), "Manhole", V3(0.06, 2.6, 2.6), CFrame.new(p + V3(0, 0.03, 0)) * CFrame.Angles(0, 0, math.rad(90)), rgb(44, 44, 46), Enum.Material.DiamondPlate, { Shape = Enum.PartType.Cylinder })
			local g = point(u + 9, -s * (RW / 2 - 0.7), roadTop)
			local along = if road.Axis == "X" then V3(1, 0, 0) else V3(0, 0, 1)
			decor(holder(), "Drain", V3(1, 0.06, 2.4), Builder.facing(g + V3(0, 0.03, 0), along), rgb(40, 40, 42), Enum.Material.DiamondPlate)
			u += 72
		end
	end
end

-- Banderola en una farola (centro y zona de ocio). cf = el de la farola (mira a la calzada)
function StreetDetail.lampBanner(parent: Instance, cf: CFrame, index: number)
	local p = cf.Position
	local district = districtOf(p.X, p.Z)
	if (district ~= "Centro" and district ~= "Este" and district ~= "Universitario") or index % 2 ~= 0 then
		return
	end
	local colors = { Centro = rgb(200, 40, 50), Este = rgb(150, 70, 200), Universitario = rgb(150, 30, 40) }
	local texts = { Centro = "VALMAR\nFIESTAS", Este = "PLAYA\nDORADA", Universitario = "CAMPUS\nVALMAR" }
	local banner = decor(parent, "Banner", V3(0.1, 3.2, 1.6), cf * CFrame.new(0, 10.2, -0.95), colors[district], Enum.Material.Fabric)
	Builder.sign(banner, texts[district], Enum.NormalId.Left, Color3.new(1, 1, 1))
	Builder.sign(banner, texts[district], Enum.NormalId.Right, Color3.new(1, 1, 1))
end

---------------------------------------------------------------------
-- Nombres de las calles en los cruces
---------------------------------------------------------------------
local NAMES = {
	"C/ Mayor", "C/ del Sol", "Av. de la Paz", "C/ Real", "C/ del Mar", "C/ Olivos", "C/ Cervantes", "C/ Alcalá",
	"C/ Luna", "C/ Nueva", "C/ Libertad", "C/ San Juan", "C/ Jardines", "C/ Toledo", "C/ Goya", "C/ Velázquez",
	"C/ Murillo", "C/ Lope de Vega", "C/ Quevedo", "C/ Picasso", "C/ Sorolla", "C/ Colón", "C/ Rosales", "C/ Pinar",
	"C/ Almendros", "C/ Naranjos", "C/ Castillo", "C/ Molinos", "C/ Estrella", "C/ Fuente", "C/ Río", "C/ Puerto",
}
function StreetDetail.nameOf(road: any): string
	if road.Name then
		return road.Name
	end
	local i = math.floor(hash(road.At, if road.Axis == "X" then 1 else 2, 7) * #NAMES) % #NAMES + 1
	return NAMES[i]
end

function StreetDetail.corner(parent: Instance, position: Vector3, a: any, b: any)
	if MetroAccess.blocked(position.X, position.Z) then
		return
	end
	local m = Builder.model("NombreCalles", parent)
	decor(m, "NamePole", V3(0.3, 9, 0.3), CFrame.new(position + V3(0, 4.5, 0)), METAL, Enum.Material.Metal)
	for i, road in { a, b } do
		-- La placa va a lo largo de su calle
		local dir = if road.Axis == "X" then V3(1, 0, 0) else V3(0, 0, 1)
		local plate = decor(m, "NamePlate", V3(4.2, 0.9, 0.12), Builder.facing(position + V3(0, 8.9 - (i - 1) * 1.05, 0), V3(dir.Z, 0, -dir.X)) * CFrame.new(2.1 * (if i == 1 then 1 else -1), 0, 0), rgb(30, 70, 150))
		Builder.sign(plate, StreetDetail.nameOf(road), Enum.NormalId.Front, Color3.new(1, 1, 1), rgb(30, 70, 150))
		Builder.sign(plate, StreetDetail.nameOf(road), Enum.NormalId.Back, Color3.new(1, 1, 1), rgb(30, 70, 150))
	end
end

---------------------------------------------------------------------
-- Delante de las tiendas (O = marco del edificio, frente en -D/2; y = suelo de la calle)
---------------------------------------------------------------------
local TERRACE = { "CAF", "BAR", "RESTAUR", "BURGER", "PIZZ", "HELAD", "PANAD", "CHURR", "TAPAS" }
local function has(name: string, keys: { string }): boolean
	local up = string.upper(name)
	for _, k in keys do
		if string.find(up, k, 1, true) then
			return true
		end
	end
	return false
end

local function umbrellaTable(m: Instance, cf: CFrame, color: Color3)
	cyl(m, "TerraceTable", 0.2, 2.6, cf * CFrame.new(0, 2.7, 0), rgb(236, 232, 224), Enum.Material.Marble, true)
	decor(m, "TableLeg", V3(0.25, 2.7, 0.25), cf * CFrame.new(0, 1.35, 0), METAL, Enum.Material.Metal)
	decor(m, "UmbrellaPole", V3(0.15, 4.8, 0.15), cf * CFrame.new(0, 5.1, 0), rgb(220, 220, 214), Enum.Material.Metal)
	decor(m, "Umbrella", V3(5.2, 0.8, 5.2), cf * CFrame.new(0, 7.2, 0), color, Enum.Material.Fabric, { Shape = Enum.PartType.Ball })
	for _, x in { -1.9, 1.9 } do
		solid(m, "TerraceChair", V3(1.3, 1.8, 1.3), cf * CFrame.new(x, 0.9, 0), rgb(60, 60, 64), Enum.Material.Metal)
	end
end

function StreetDetail.shopFront(parent: Instance, front: CFrame, width: number, name: string, color: Color3?)
	-- front: centro del escaparate en el suelo de la acera, mirando a la calle (-Z)
	local p = front.Position
	if MetroAccess.blocked(p.X, p.Z) then
		return
	end
	local r = hash(p.X, p.Z, 11)
	local m = item(parent, "Escaparate")
	m:SetAttribute("BaseY", p.Y) -- (StreetDetail.prune lo sube a la acera si la hay)
	local accent = color or rgb(170, 40, 40)
	local x = math.min(width / 2 - 3.5, 9)
	if x < 3 then
		return
	end
	if has(name, TERRACE) then
		-- Terraza: una o dos mesas con sombrilla y una pizarra con el menú
		umbrellaTable(m, front * CFrame.new(-x, 0, -3.4), accent)
		if width > 26 then
			umbrellaTable(m, front * CFrame.new(x, 0, -3.4), accent)
		end
		local board = decor(m, "MenuBoard", V3(1.6, 2.4, 0.15), front * CFrame.new(3.4, 1.2, -2.2) * CFrame.Angles(math.rad(-10), 0, 0), rgb(40, 44, 40))
		Builder.sign(board, "MENÚ DEL DÍA\n12 €", Enum.NormalId.Front, Color3.new(1, 1, 1))
	elseif has(name, { "FRUT", "SUPER", "ALIMENT", "MERCADO", "ULTRAMAR" }) then
		for i = 0, 2 do
			decor(m, "Crate", V3(2, 0.9, 1.4), front * CFrame.new(-x + i * 2.2, 1.6, -1.2), rgb(150, 110, 70), Enum.Material.WoodPlanks)
			decor(m, "Fruit", V3(1.8, 0.5, 1.2), front * CFrame.new(-x + i * 2.2, 2.2, -1.2), ({ rgb(240, 140, 30), rgb(200, 40, 40), rgb(120, 180, 60) })[i + 1], Enum.Material.SmoothPlastic)
		end
		solid(m, "CrateStand", V3(6.6, 1.2, 1.6), front * CFrame.new(-x + 2.2, 0.6, -1.2), rgb(110, 80, 50), Enum.Material.WoodPlanks)
	elseif has(name, { "FLOR" }) then
		for i = 0, 3 do
			decor(m, "Bucket", V3(1.1, 1.1, 1.1), front * CFrame.new(-x + i * 1.4, 0.55, -1.1), rgb(90, 96, 110), Enum.Material.Metal)
			decor(m, "Bouquet", V3(1.3, 1.1, 1.3), front * CFrame.new(-x + i * 1.4, 1.6, -1.1), ({ rgb(226, 72, 92), rgb(246, 196, 60), rgb(240, 240, 240), rgb(170, 90, 200) })[i + 1], Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Ball })
		end
	else
		-- Pizarra de ofertas y dos macetas a los lados de la puerta
		local board = decor(m, "SandwichBoard", V3(1.8, 2.6, 0.2), front * CFrame.new(x, 1.3, -2) * CFrame.Angles(math.rad(-12), 0, 0), rgb(36, 40, 38))
		Builder.sign(board, if r < 0.5 then "¡OFERTAS!\n-20 %" else "ABIERTO\n9:00-21:00", Enum.NormalId.Front, Color3.new(1, 1, 1))
		for _, sx in { -1, 1 } do
			if r > 0.3 then
				solid(m, "Pot", V3(1.3, 1.3, 1.3), front * CFrame.new(sx * 3.4, 0.65, -0.9), rgb(170, 100, 64), Enum.Material.Concrete)
				decor(m, "PotPlant", V3(1.8, 2.2, 1.8), front * CFrame.new(sx * 3.4, 2.2, -0.9), rgb(66, 108, 54), Enum.Material.LeafyGrass, { Shape = Enum.PartType.Ball })
			end
		end
	end
end

---------------------------------------------------------------------
-- Fachadas: aire acondicionado bajo algunas ventanas; macetas y ropa tendida en los balcones
-- (face = marco de la fachada: mira hacia fuera en -Z; o = el hueco)
---------------------------------------------------------------------
function StreetDetail.window(parent: Instance, face: CFrame, x: number, bottom: number, w: number)
	local p = (face * CFrame.new(x, bottom, 0)).Position
	if hash(p.X + p.Y * 3, p.Z, 21) > 0.08 then
		return
	end
	decor(parent, "ACUnit", V3(math.min(w - 0.4, 2.6), 1.4, 1.2), face * CFrame.new(x, bottom - 1.2, -0.75), rgb(226, 226, 222), Enum.Material.Metal)
end

function StreetDetail.balcony(parent: Instance, face: CFrame, x: number, bottom: number, w: number)
	local p = (face * CFrame.new(x, bottom, 0)).Position
	local r = hash(p.X + p.Y * 3, p.Z, 22)
	if r < 0.22 then
		-- Macetas con geranios en la barandilla
		decor(parent, "BalconyPots", V3(w * 0.6, 0.8, 0.8), face * CFrame.new(x, bottom + 3.4, -1.9), rgb(170, 90, 60), Enum.Material.Concrete)
		decor(parent, "Geraniums", V3(w * 0.6, 0.9, 1), face * CFrame.new(x, bottom + 4.1, -1.9), if r < 0.11 then rgb(220, 50, 70) else rgb(236, 120, 170), Enum.Material.LeafyGrass)
	elseif r < 0.32 then
		-- Ropa tendida
		decor(parent, "ClothesLine", V3(w + 1.6, 0.06, 0.06), face * CFrame.new(x, bottom + 4.6, -1.6), rgb(220, 220, 220))
		for i, c in { rgb(240, 240, 240), rgb(60, 110, 190), rgb(220, 70, 70) } do
			decor(parent, "Clothes", V3(0.9, 1.3, 0.05), face * CFrame.new(x - w / 2 + i * (w / 3.2), bottom + 3.9, -1.6), c, Enum.Material.Fabric)
		end
	end
end

---------------------------------------------------------------------
-- Repaso final: quita los detalles que caen encima de otra cosa (paradas, bancos, portales…)
---------------------------------------------------------------------
local SKIP = { Sidewalk = true, Curb = true, Road = true, Marking = true, BlockGround = true, Ground = true, Apron = true, ApronEdge = true, TreePit = true, Zebra = true, Junction = true, PlazaFloor = true, Lawn = true, Path = true, Floor = true, Parking = true, Line = true, Median = true, MedianGrass = true }
function StreetDetail.prune(world: Instance): number
	local CELL = 16
	local grid: { [string]: { any } } = {}
	local list = {}
	for _, m in world:GetDescendants() do
		if m:IsA("Model") and m:HasTag("LiteDetail") then
			local lo, hi = V3(math.huge, math.huge, math.huge), V3(-math.huge, -math.huge, -math.huge)
			for _, p in m:GetChildren() do
				if p:IsA("BasePart") then
					local k = { p.CFrame:GetComponents() }
					local sz = p.Size
					local h = V3(
						(math.abs(k[4]) * sz.X + math.abs(k[5]) * sz.Y + math.abs(k[6]) * sz.Z) / 2,
						(math.abs(k[7]) * sz.X + math.abs(k[8]) * sz.Y + math.abs(k[9]) * sz.Z) / 2,
						(math.abs(k[10]) * sz.X + math.abs(k[11]) * sz.Y + math.abs(k[12]) * sz.Z) / 2
					)
					local c = p.CFrame.Position
					lo = V3(math.min(lo.X, c.X - h.X), math.min(lo.Y, c.Y - h.Y), math.min(lo.Z, c.Z - h.Z))
					hi = V3(math.max(hi.X, c.X + h.X), math.max(hi.Y, c.Y + h.Y), math.max(hi.Z, c.Z + h.Z))
				end
			end
			local entry = { Model = m, Lo = lo, Hi = hi }
			table.insert(list, entry)
			for gx = math.floor(lo.X / CELL), math.floor(hi.X / CELL) do
				for gz = math.floor(lo.Z / CELL), math.floor(hi.Z / CELL) do
					local k = gx .. ":" .. gz
					grid[k] = grid[k] or {}
					table.insert(grid[k], entry)
				end
			end
		end
	end
	local removed = 0
	local floorTop: { [any]: number } = {}
	for _, p in world:GetDescendants() do
		if p:IsA("BasePart") and (p.Name == "Sidewalk" or p.Name == "PlazaFloor" or p.Name == "Apron") then
			-- Suelo bajo los escaparates: ¿a qué altura está la acera?
			local c = p.CFrame.Position
			local key = math.floor(c.X / CELL) .. ":" .. math.floor(c.Z / CELL)
			local r = math.max(p.Size.X, p.Size.Z) / 2
			if r < CELL * 2 then
				for _, e in grid[key] or {} do
					local base = e.Model:GetAttribute("BaseY")
					if base then
						local q = p.CFrame:PointToObjectSpace(V3((e.Lo.X + e.Hi.X) / 2, c.Y, (e.Lo.Z + e.Hi.Z) / 2))
						if math.abs(q.X) <= p.Size.X / 2 and math.abs(q.Z) <= p.Size.Z / 2 then
							floorTop[e] = math.max(floorTop[e] or -math.huge, c.Y + p.Size.Y / 2)
						end
					end
				end
			end
		end
	end
	for e, top in floorTop do
		local base = e.Model:GetAttribute("BaseY")
		if top > base + 0.05 and top < base + 3 then
			for _, part in e.Model:GetChildren() do
				if part:IsA("BasePart") then
					part.CFrame = part.CFrame + V3(0, top - base, 0)
				end
			end
			e.Lo += V3(0, top - base, 0)
			e.Hi += V3(0, top - base, 0)
		end
	end
	local dead = {}
	for _, p in world:GetDescendants() do
		if p:IsA("BasePart") and not SKIP[p.Name] and p.Transparency < 1 then
			local k = { p.CFrame:GetComponents() }
			local sz = p.Size
			local hx = (math.abs(k[4]) * sz.X + math.abs(k[5]) * sz.Y + math.abs(k[6]) * sz.Z) / 2
			local hy = (math.abs(k[7]) * sz.X + math.abs(k[8]) * sz.Y + math.abs(k[9]) * sz.Z) / 2
			local hz = (math.abs(k[10]) * sz.X + math.abs(k[11]) * sz.Y + math.abs(k[12]) * sz.Z) / 2
			local cx, cy, cz = k[1], k[2], k[3]
			-- (solo lo que está a la altura de la gente y no es enorme)
			if hx < 60 and hz < 60 and cy + hy > 1.3 and cy - hy < 6 then
				for gx = math.floor((cx - hx) / CELL), math.floor((cx + hx) / CELL) do
					for gz = math.floor((cz - hz) / CELL), math.floor((cz + hz) / CELL) do
						for _, e in grid[gx .. ":" .. gz] or {} do
							local m = e.Model
							-- (lo del mismo edificio o del mismo tramo de calle no cuenta: ya se ha puesto sabiendo dónde)
							if not dead[m] and cx + hx > e.Lo.X and cx - hx < e.Hi.X and cz + hz > e.Lo.Z and cz - hz < e.Hi.Z and not p:IsDescendantOf(m.Parent :: Instance) then
								dead[m] = true
								removed += 1
							end
						end
					end
				end
			end
		end
	end
	for m in dead do
		m:Destroy()
	end
	StreetDetail.Count -= removed
	return removed
end

return StreetDetail
