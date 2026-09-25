-- Districts: llena las manzanas de los 6 distritos (fases 6-7 del plano).
--
-- Recorre la cuadrícula de calles (Kit/Grid): dentro de la Ronda, manzanas de 250 studs; fuera,
-- manzanas de 500 divididas en 4 con paseos peatonales. Cada manzana recibe un uso según su distrito
-- y su posición (del centro hacia fuera: rascacielos -> pisos -> casas -> villas -> costa):
--   Centro        rascacielos, bloques con tiendas, plazas, aparcamientos
--   Norte         pisos junto a la Ronda, casas en medio, villas junto a las montañas
--   Oeste         villas y hoteles en la costa; casas, parques y huertas hacia dentro
--   Este          calles comerciales, ocio (bolera, discoteca, cine, spa…), hoteles en la costa
--   Universitario facultades, residencias, pistas deportivas
--   Sur           naves industriales, talleres y concesionarios, pisos obreros
-- Usa los edificios ligeros de Kit/Lite (pocas piezas cada uno) para que el juego vaya fluido.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Builder = require(script.Parent.Parent.Builder)
local Blocks = require(script.Parent.Blocks)
local Grid = require(script.Parent.Grid)
local Lite = require(script.Parent.Lite)
local Icons = require(script.Parent.Icons)
local Civic = require(script.Parent.Civic)
local Nature = require(script.Parent.Nature)
local Props = require(script.Parent.Props)
local CityPlan = require(ReplicatedStorage.Shared.CityPlan)

local Districts = {}

local rgb = Color3.fromRGB

type Rect = { X0: number, X1: number, Z0: number, Z1: number }
export type Cell = Rect & { Kind: string, District: string }

local function pick<T>(list: { T }): T
	return list[math.random(1, #list)]
end

---------------------------------------------------------------------
-- Tipos reutilizados (naves, oficinas, huertas)
---------------------------------------------------------------------
-- Huertas: parcelas de tierra con surcos de colores y una caseta
local CROPS = { rgb(90, 160, 60), rgb(200, 170, 60), rgb(120, 180, 70), rgb(170, 110, 60), rgb(80, 140, 80) }
local function fields(parent: Instance, lot: any)
	local m = Builder.model("Huerta", parent)
	local L, D = lot.Length, lot.Depth
	local plots = 2
	local each = (L - 20) / plots
	for i = 0, plots - 1 do
		local u = -L / 2 + 10 + each * (i + 0.5)
		local soil = lot.facing(u, D / 2 + 6, 0)
		Builder.part({ Name = "Soil", Size = Vector3.new(each - 10, 0.4, D - 36), CFrame = soil * CFrame.new(0, 0.2, 0), Color = rgb(110, 80, 56), Material = Enum.Material.Ground, Parent = m })
		local crop = CROPS[math.random(1, #CROPS)]
		local rows = math.floor((each - 16) / 5)
		for r = 0, rows - 1 do
			local x = -(each - 16) / 2 + r * 5 + 2.5
			Builder.decor({ Name = "Crop", Size = Vector3.new(2, 1.2, D - 44), CFrame = soil * CFrame.new(x, 1, 0), Color = crop, Material = Enum.Material.LeafyGrass, Parent = m })
		end
	end
	-- Caseta de aperos y valla de madera delante
	local shed = lot.facing(L / 2 - 14, 16, 0)
	Builder.part({ Name = "Shed", Size = Vector3.new(12, 8, 10), CFrame = shed * CFrame.new(0, 4, 0), Color = rgb(170, 60, 50), Material = Enum.Material.WoodPlanks, Parent = m })
	Builder.part({ Name = "ShedRoof", Size = Vector3.new(13, 0.8, 11), CFrame = shed * CFrame.new(0, 8.4, 0), Color = rgb(80, 70, 64), Material = Enum.Material.Slate, Parent = m })
	Builder.part({ Name = "Fence", Size = Vector3.new(L - 30, 0.4, 0.3), CFrame = lot.facing(-8, 3, 2.4), Color = rgb(150, 110, 70), Material = Enum.Material.Wood, Parent = m })
	Builder.part({ Name = "Fence", Size = Vector3.new(L - 30, 0.4, 0.3), CFrame = lot.facing(-8, 3, 1.2), Color = rgb(150, 110, 70), Material = Enum.Material.Wood, Parent = m })
	return m
end

-- Nave industrial con puertas de persiana, muelle de carga, camión y (a veces) silos
local BRANDS = { "LOGÍSTICA VALMAR", "TRANSPORTES DEL SUR", "METALES COSTA", "ALIMENTOS VALMAR", "RECICLAJES ECO", "MUEBLES NORTE", "TEXTIL MAR", "BEBIDAS DORADA" }
local WALLS = { rgb(200, 200, 196), rgb(170, 180, 190), rgb(210, 196, 170), rgb(150, 170, 160) }
local function industrial(parent: Instance, lot: any)
	local m = Builder.model("Nave", parent)
	local L, D = lot.Length, lot.Depth
	local w, d, h = math.min(L - 30, 120), math.min(D - 50, 90), math.random(18, 26)
	local base = lot.facing(0, 36 + d / 2, 0)
	local wall = WALLS[math.random(1, #WALLS)]
	Builder.part({ Name = "Yard", Size = Vector3.new(L - 8, 0.3, D - 8), CFrame = lot.facing(0, D / 2, 0.15), Color = rgb(120, 122, 126), Material = Enum.Material.Asphalt, Parent = m })
	Builder.part({ Name = "Hall", Size = Vector3.new(w, h, d), CFrame = base * CFrame.new(0, h / 2, 0), Color = wall, Material = Enum.Material.CorrodedMetal, Parent = m })
	Builder.part({ Name = "Roof", Size = Vector3.new(w + 2, 1.2, d + 2), CFrame = base * CFrame.new(0, h + 0.6, 0), Color = rgb(90, 96, 104), Material = Enum.Material.Metal, Parent = m })
	-- Puertas de persiana y muelle de carga en la fachada (la que mira a la calle es -Z)
	for _, x in { -w / 4, w / 4 } do
		Builder.decor({ Name = "RollerDoor", Size = Vector3.new(14, 12, 0.3), CFrame = base * CFrame.new(x, 6, -d / 2 - 0.2), Color = rgb(70, 80, 92), Material = Enum.Material.DiamondPlate, Parent = m })
	end
	Builder.part({ Name = "Dock", Size = Vector3.new(w * 0.8, 3, 6), CFrame = base * CFrame.new(0, 1.5, -d / 2 - 3), Color = rgb(150, 150, 146), Material = Enum.Material.Concrete, Parent = m })
	local sign = Builder.part({ Name = "Sign", Size = Vector3.new(math.min(w - 10, 50), 5, 0.4), CFrame = base * CFrame.new(0, h - 4, -d / 2 - 0.4), Color = rgb(30, 70, 140), Parent = m })
	Builder.sign(sign, BRANDS[math.random(1, #BRANDS)], Enum.NormalId.Front)
	-- Camión aparcado delante
	local truck = base * CFrame.new(w / 2 - 12, 0, -d / 2 - 20)
	Builder.part({ Name = "Trailer", Size = Vector3.new(8, 9, 26), CFrame = truck * CFrame.new(0, 5.5, 4), Color = rgb(235, 235, 232), Parent = m })
	Builder.part({ Name = "Cab", Size = Vector3.new(8, 7, 7), CFrame = truck * CFrame.new(0, 4.5, -13), Color = Color3.fromHSV(math.random(), 0.6, 0.75), Parent = m })
	Builder.decor({ Name = "CabWindow", Size = Vector3.new(7, 2.5, 0.2), CFrame = truck * CFrame.new(0, 6, -16.55), Color = rgb(40, 60, 80), Material = Enum.Material.Glass, Parent = m })
	-- Silos en algunas naves
	if math.random() < 0.5 then
		for i = 0, 1 do
			local silo = base * CFrame.new(-w / 2 - 9, 0, -d / 4 + i * 16)
			Builder.part({ Name = "Silo", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h + 8, 12, 12), CFrame = silo * CFrame.new(0, (h + 8) / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(210, 214, 218), Material = Enum.Material.Metal, Parent = m })
		end
	end
	-- Chimenea
	if math.random() < 0.4 then
		Builder.part({ Name = "Chimney", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h + 22, 4, 4), CFrame = base * CFrame.new(w / 2 - 8, (h + 22) / 2, d / 2 - 8) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(170, 60, 50), Material = Enum.Material.Brick, Parent = m })
	end
	return m
end

-- Edificio de oficinas de cristal con bandas por planta y aparcamiento
local GLASS = { rgb(90, 140, 170), rgb(70, 110, 140), rgb(110, 150, 160), rgb(80, 120, 150) }
local OFFICE_NAMES = { "TECNOVAL", "SEGUROS VALMAR", "BANCO COSTA", "CONSULTORA NORTE", "ENERGÍA VERDE", "VALMAR MEDIA" }
local function offices(parent: Instance, lot: any)
	local m = Builder.model("Oficinas", parent)
	local L, D = lot.Length, lot.Depth
	local w, d = math.min(L - 40, 70), math.min(D - 70, 44)
	local floors = math.random(4, 9)
	local fh = 12
	local base = lot.facing(0, 60 + d / 2, 0)
	local glass = GLASS[math.random(1, #GLASS)]
	Builder.part({ Name = "Core", Size = Vector3.new(w, floors * fh, d), CFrame = base * CFrame.new(0, floors * fh / 2, 0), Color = glass, Material = Enum.Material.Glass, Reflectance = 0.15, Parent = m })
	for f = 1, floors do
		Builder.part({ Name = "Band", Size = Vector3.new(w + 1, 1.2, d + 1), CFrame = base * CFrame.new(0, f * fh - 0.6, 0), Color = rgb(226, 228, 230), Material = Enum.Material.Concrete, Parent = m })
	end
	Builder.part({ Name = "Canopy", Size = Vector3.new(16, 0.8, 8), CFrame = base * CFrame.new(0, 10, -d / 2 - 4), Color = rgb(60, 64, 70), Material = Enum.Material.Metal, Parent = m })
	local sign = Builder.part({ Name = "Sign", Size = Vector3.new(math.min(w - 8, 30), 4, 0.4), CFrame = base * CFrame.new(0, floors * fh - 5, -d / 2 - 0.9), Color = rgb(20, 26, 36), Parent = m })
	Builder.sign(sign, OFFICE_NAMES[math.random(1, #OFFICE_NAMES)], Enum.NormalId.Front)
	-- Aparcamiento delante con plazas pintadas y unos coches
	local lotCf = lot.facing(0, 28, 0)
	Builder.part({ Name = "Parking", Size = Vector3.new(L - 16, 0.3, 40), CFrame = lotCf * CFrame.new(0, 0.15, 0), Color = rgb(60, 62, 66), Material = Enum.Material.Asphalt, Parent = m })
	for x = -(L - 30) / 2, (L - 30) / 2, 10 do
		Builder.decor({ Name = "Line", Size = Vector3.new(0.4, 0.05, 14), CFrame = lotCf * CFrame.new(x, 0.32, -10), Color = rgb(236, 236, 230), Parent = m })
	end
	for _ = 1, 3 do
		local x = math.random(-3, 3) * 10 + 5
		Props.car(m, lotCf * CFrame.new(x, 0.3, -10))
	end
	return m
end


---------------------------------------------------------------------
-- Manzanas
---------------------------------------------------------------------

-- Edificios alrededor de la manzana, mirando a la calle. build(lot, u, width, depth) en cada hueco.
local function perimeter(rect: Rect, depth: number, minW: number, maxW: number, sides: { string }, build: (any, number, number, number) -> ())
	local has = {}
	for _, s in sides do
		has[s] = true
	end
	for _, side in sides do
		local lot = Blocks.lot(rect, side)
		local u0, u1 = -lot.Length / 2 + 2, lot.Length / 2 - 2
		if side == "E" or side == "W" then
			if has.N then
				u0 += depth + 2
			end
			if has.S then
				u1 -= depth + 2
			end
		end
		local u = u0
		while u1 - u >= minW do
			local w = math.min(math.random(minW, maxW), u1 - u)
			if u1 - (u + w) < minW then
				w = u1 - u
			end
			build(lot, u + w / 2, w, depth)
			u += w + 2
		end
	end
end

local ALL = { "N", "S", "E", "W" }
local OCIO = { "BOLERA", "DISCOTECA", "CINE VALMAR", "ARCADE", "SPA", "GIMNASIO", "KARTS", "TEATRO", "SALA DE CONCIERTOS", "ESCAPE ROOM" }
local FACULTIES = { "AULARIO", "LABORATORIOS", "FACULTAD DE CIENCIAS", "FACULTAD DE ARTES", "FACULTAD DE PSICOLOGÍA", "CAFETERÍA UNIVERSITARIA", "PAPELERÍA", "LIBRERÍA" }
local GARAGES = { "TALLER MECÁNICO", "CONCESIONARIO", "DESGUACE", "NEUMÁTICOS", "CARPINTERÍA", "CONSTRUCCIONES VALMAR", "SEGURIDAD VALMAR" }

local function inner(rect: Rect, inset: number): (CFrame, number, number)
	local w, d = rect.X1 - rect.X0 - inset * 2, rect.Z1 - rect.Z0 - inset * 2
	return CFrame.new((rect.X0 + rect.X1) / 2, 0, (rect.Z0 + rect.Z1) / 2), w, d
end

local builders: { [string]: (Instance, Rect) -> () } = {}

builders.Towers = function(m, rect)
	-- Edificios bajos con tiendas en los lados E y O, y dos rascacielos en N y S
	for _, side in { "E", "W" } do
		local lot = Blocks.lot(rect, side)
		Lite.building(m, lot.facing(0, 20, 0), math.min(lot.Length - 130, 90), 36, math.random(3, 6), { Shop = true, Style = "Moderno" })
	end
	for _, side in { "N", "S" } do
		local lot = Blocks.lot(rect, side)
		local w, d = math.random(50, 72), math.random(46, 60)
		Lite.tower(m, lot.facing((math.random() - 0.5) * 40, 6 + d / 2, 0), w, d, math.random(16, 42), if math.random() < 0.4 then pick({ "BANCO VALMAR", "SEGUROS COSTA", "TECNOVAL", "GRUPO NORTE", "VALMAR MEDIA", "ENERGÍA VERDE" }) else nil)
	end
	local cf = inner(rect, 0)
	Builder.part({ Name = "Plaza", Size = Vector3.new(rect.X1 - rect.X0 - 4, 0.3, 30), CFrame = cf * CFrame.new(0, 0.15, 0), Color = rgb(214, 206, 190), Material = Enum.Material.Pavement, Parent = m })
end

builders.Downtown = function(m, rect)
	perimeter(rect, 40, 44, 80, ALL, function(lot, u, w, depth)
		Lite.building(m, lot.facing(u, depth / 2 + 1, 0), w, depth, math.random(7, 16), { Shop = true, Style = pick({ "Moderno", "Clasico", "Colorido", "Moderno" }) })
	end)
	local cf, w, d = inner(rect, 46)
	if w > 40 and d > 40 then
		Lite.park(m, cf, w, d, true)
	end
end

builders.Pisos = function(m, rect)
	perimeter(rect, 34, 40, 70, ALL, function(lot, u, w, depth)
		Lite.building(m, lot.facing(u, depth / 2 + 2, 0), w, depth, math.random(4, 8), { Shop = math.random() < 0.5 })
	end)
	local cf, w, d = inner(rect, 40)
	if w > 40 and d > 40 then
		for _ = 1, 5 do
			Nature.tree(m, (cf * CFrame.new((math.random() - 0.5) * (w - 12), 0, (math.random() - 0.5) * (d - 12))).Position)
		end
	end
end

builders.Residencia = function(m, rect)
	perimeter(rect, 34, 50, 80, ALL, function(lot, u, w, depth)
		Lite.building(m, lot.facing(u, depth / 2 + 2, 0), w, depth, math.random(4, 7), { Style = "Ladrillo", Shop = if math.random() < 0.3 then pick({ "BAR", "COPISTERÍA", "PIZZERÍA", "KEBAB", "CAFETERÍA" }) else false })
	end)
end

builders.Casas = function(m, rect)
	for _, side in ALL do
		local lot = Blocks.lot(rect, side)
		-- (los lados E y O dejan libres las esquinas, que ya ocupan las casas de N y S)
		local margin = if side == "E" or side == "W" then 52 else 4
		local length = lot.Length - margin * 2
		local count = math.floor(length / 44)
		local each = length / math.max(count, 1)
		for i = 0, count - 1 do
			local u = -lot.Length / 2 + margin + each * (i + 0.5)
			local w, d = math.random(20, 28), math.random(18, 24)
			Lite.house(m, lot.facing(u - 5, 14 + d / 2, 0), w, d)
		end
	end
	-- Jardín comunitario en el centro de la manzana
	local cf = inner(rect, 0)
	for _ = 1, 4 do
		Nature.tree(m, (cf * CFrame.new(math.random(-30, 30), 0, math.random(-30, 30))).Position)
	end
end

builders.Villas = function(m, rect)
	for _, side in { "N", "S" } do
		local lot = Blocks.lot(rect, side)
		local count = math.max(1, math.floor(lot.Length / 100))
		local each = lot.Length / count
		for i = 0, count - 1 do
			local u = -lot.Length / 2 + each * (i + 0.5)
			Lite.villa(m, lot.facing(u, 42, 0), math.min(each - 14, 80), 64)
		end
	end
end

builders.Hotel = function(m, rect)
	local lot = Blocks.lot(rect, pick({ "N", "S" }))
	Lite.hotel(m, lot.facing(-20, 32, 0), math.random(60, 90), 36)
	local cf, w, d = inner(rect, 20)
	Lite.park(m, cf * CFrame.new(0, 0, 0), w * 0.5, d * 0.4)
end

builders.Comercio = function(m, rect)
	perimeter(rect, 32, 30, 56, ALL, function(lot, u, w, depth)
		Lite.building(m, lot.facing(u, depth / 2 + 1, 0), w, depth, math.random(1, 3), { Shop = pick(Lite.ShopNames), Style = pick({ "Colorido", "Moderno", "Clasico" }) })
	end)
	local cf, w, d = inner(rect, 38)
	if w > 40 and d > 40 then
		Lite.parking(m, cf, w, d)
	end
end

builders.Ocio = function(m, rect)
	local lot = Blocks.lot(rect, pick(ALL))
	local w = math.min(lot.Length - 40, 130)
	local b = Lite.building(m, lot.facing(0, 45, 0), w, 70, 2, { Shop = pick(OCIO), Style = "Moderno", Balconies = false })
	b.Name = "Ocio_Local"
	Lite.parking(m, lot.facing(0, 130, 0), math.min(lot.Length - 20, 150), 70)
end

builders.Campus = function(m, rect)
	for _, side in { "N", "S" } do
		local lot = Blocks.lot(rect, side)
		local w = math.min(lot.Length - 40, 120)
		Lite.building(m, lot.facing(0, 30, 0), w, 40, math.random(3, 5), { Style = "Ladrillo", Shop = pick(FACULTIES), Balconies = false })
	end
	local cf, w, d = inner(rect, 60)
	if w > 30 and d > 30 then
		Lite.park(m, cf, w, d)
	end
end

builders.Deporte = function(m, rect)
	local cf, w, d = inner(rect, 14)
	local pw, pd = math.min(w - 20, 110), math.min(d - 20, 70)
	Builder.part({ Name = "Pitch", Size = Vector3.new(pw, 0.3, pd), CFrame = cf * CFrame.new(0, 0.15, 0), Color = rgb(70, 146, 66), Material = Enum.Material.Grass, Parent = m })
	local white = rgb(245, 245, 245)
	for _, l in { { pw, 0.5, 0, -pd / 2 + 1 }, { pw, 0.5, 0, pd / 2 - 1 }, { 0.5, pd, -pw / 2 + 1, 0 }, { 0.5, pd, pw / 2 - 1, 0 }, { 0.5, pd, 0, 0 } } do
		Builder.decor({ Name = "Line", Size = Vector3.new(l[1], 0.06, l[2]), CFrame = cf * CFrame.new(l[3], 0.33, l[4]), Color = white, Parent = m })
	end
	for _, x in { -pw / 2 + 1, pw / 2 - 1 } do
		Builder.part({ Name = "Goal", Size = Vector3.new(1, 8, 20), CFrame = cf * CFrame.new(x, 4, 0), Color = white, Material = Enum.Material.Metal, Transparency = 0.5, Parent = m })
	end
	Builder.part({ Name = "Stand", ClassName = "WedgePart", Size = Vector3.new(pw * 0.8, 8, 12), CFrame = cf * CFrame.new(0, 4, pd / 2 + 10), Color = rgb(170, 170, 176), Material = Enum.Material.Concrete, Parent = m })
end

builders.Parque = function(m, rect)
	local cf, w, d = inner(rect, 4)
	Lite.park(m, cf, w, d)
end

builders.Parking = function(m, rect)
	local cf, w, d = inner(rect, 6)
	Lite.parking(m, cf, w, d)
end

builders.Industrial = function(m, rect)
	industrial(m, Blocks.lot(rect, pick(ALL)))
end

builders.Oficinas = function(m, rect)
	offices(m, Blocks.lot(rect, pick(ALL)))
end

builders.Campo = function(m, rect)
	fields(m, Blocks.lot(rect, pick(ALL)))
end

builders.Taller = function(m, rect)
	local lot = Blocks.lot(rect, pick(ALL))
	local w = math.min(lot.Length - 40, 90)
	local b = Lite.building(m, lot.facing(-20, 30, 0), w, 40, math.random(1, 2), { Shop = pick(GARAGES), Style = "Moderno", Balconies = false })
	b.Name = "Taller"
	Lite.parking(m, lot.facing(0, 110, 0), math.min(lot.Length - 20, 130), 80)
end

-- Lugares emblemáticos y servicios (colegios, hospitales, comisarías con su interior completo)
for _, name in { "TorreValmar", "Ayuntamiento", "EstacionCentral", "EstacionAutobuses", "Museo", "Teatro", "GranCentroComercial", "Feria", "Camping" } do
	builders[name] = function(m, rect)
		Icons[name](m, rect)
	end
end
local function civic(kind: string, townName: string): (Instance, Rect) -> ()
	return function(m, rect)
		local lot = Blocks.lot(rect, "S")
		if kind == "Colegio" then
			Civic.school(m, lot, townName)
		elseif kind == "Hospital" then
			Civic.hospital(m, lot, townName, false)
		elseif kind == "Clinica" then
			Civic.hospital(m, lot, townName, true)
		else
			Civic.firePolice(m, lot)
		end
	end
end
builders.HospitalCentral = civic("Hospital", "Valmar Centro")
builders.ComisariaCentral = civic("Policia", "Valmar Centro")
builders.ColegioCentro = civic("Colegio", "Valmar Centro")
builders.ColegioNorte = civic("Colegio", "Valmar Norte")
builders.ColegioOeste = civic("Colegio", "Poniente")
builders.ColegioSur = civic("Colegio", "Distrito Sur")
builders.InstitutoEste = civic("Colegio", "Levante")
builders.ComisariaSur = civic("Policia", "Distrito Sur")
builders.ClinicaOeste = civic("Clinica", "Poniente")
builders.ClinicaEste = civic("Clinica", "Levante")

-- Dónde va cada uno (se elige la manzana más cercana a ese punto, dentro de su distrito)
local LANDMARKS = {
	{ "TorreValmar", "Centro", 750, -750 },
	{ "Ayuntamiento", "Centro", -750, 375 },
	{ "EstacionCentral", "Centro", 750, 625 },
	{ "EstacionAutobuses", "Centro", -750, 875 },
	{ "Museo", "Centro", -750, -375 },
	{ "Teatro", "Centro", 750, -375 },
	{ "HospitalCentral", "Centro", 375, 875 },
	{ "ComisariaCentral", "Centro", -375, 625 },
	{ "ColegioCentro", "Centro", 1000, 125 },
	{ "ColegioNorte", "Norte", 0, -1500 },
	{ "ColegioOeste", "Oeste", -2100, 600 },
	{ "ClinicaOeste", "Oeste", -2300, 1500 },
	{ "Camping", "Oeste", -2400, -900 },
	{ "GranCentroComercial", "Este", 2300, -500 },
	{ "Feria", "Este", 3000, -2000 },
	{ "InstitutoEste", "Este", 2300, -1300 },
	{ "ClinicaEste", "Este", 3100, -1500 },
	{ "ColegioSur", "Sur", 500, 1700 },
	{ "ComisariaSur", "Sur", 900, 2600 },
}

---------------------------------------------------------------------
-- Qué va en cada manzana
---------------------------------------------------------------------
local function weighted(options: { { any } }): string
	local total = 0
	for _, o in options do
		total += o[2]
	end
	local r = math.random() * total
	for _, o in options do
		r -= o[2]
		if r <= 0 then
			return o[1]
		end
	end
	return options[1][1]
end

local function kindFor(district: string, x: number, z: number, center: boolean): string
	if center then
		if z < -450 then
			return weighted({ { "Towers", 5 }, { "Downtown", 3 }, { "Parque", 1 } })
		end
		return weighted({ { "Downtown", 7 }, { "Towers", 1 }, { "Parque", 1.2 }, { "Parking", 0.8 } })
	elseif district == "Norte" then
		if z > -1750 then
			return weighted({ { "Pisos", 6 }, { "Parque", 1 }, { "Comercio", 1 } })
		elseif z > -2250 then
			return weighted({ { "Casas", 6 }, { "Parque", 1 }, { "Pisos", 1 } })
		end
		return weighted({ { "Villas", 5 }, { "Parque", 1 } })
	elseif district == "Oeste" then
		if x < -3000 then
			return weighted({ { "Villas", 4 }, { "Hotel", 2 }, { "Parque", 1 } })
		end
		return weighted({ { "Casas", 5 }, { "Pisos", 2 }, { "Parque", 2 }, { "Campo", 1 } })
	elseif district == "Este" then
		if x > 3300 then
			return weighted({ { "Hotel", 3 }, { "Comercio", 1 }, { "Parque", 1 } })
		end
		return weighted({ { "Comercio", 6 }, { "Ocio", 2.5 }, { "Pisos", 1.5 }, { "Parking", 1 }, { "Oficinas", 1 } })
	elseif district == "Universitario" then
		return weighted({ { "Campus", 5 }, { "Residencia", 3 }, { "Deporte", 1.5 }, { "Parque", 1.5 } })
	elseif district == "Sur" then
		return weighted({ { "Industrial", 6 }, { "Taller", 2 }, { "Pisos", 1.5 }, { "Parking", 1 } })
	end
	return "Parque"
end

-- Suelo: césped en zonas verdes y de casas; pavimento en las urbanas e industriales
local PAVED = {
	Towers = true, Downtown = true, Comercio = true, Industrial = true, Taller = true, Parking = true, Ocio = true, Oficinas = true,
	TorreValmar = true, Ayuntamiento = true, EstacionCentral = true, EstacionAutobuses = true, Museo = true, Teatro = true,
	GranCentroComercial = true, Feria = true,
}

local cellsCache: { Cell }? = nil

local function ok(rect: Rect, towns: { Vector3 }, outsideRing: boolean): boolean
	for i = 0, 4 do
		for j = 0, 4 do
			local x = rect.X0 + 2 + (rect.X1 - rect.X0 - 4) * i / 4
			local z = rect.Z0 + 2 + (rect.Z1 - rect.Z0 - 4) * j / 4
			if outsideRing and math.abs(x) < Grid.RING + 45 and math.abs(z) < Grid.RING + 45 then
				return false
			end
			if not Grid.allowed(x, z, towns) then
				return false
			end
			-- Las dos avenidas del centro (Region.Highways) cruzan la Ronda de lado a lado
			if (math.abs(x) < Grid.HALF + 4 or math.abs(z) < Grid.HALF + 4) and math.abs(x) < Grid.RING and math.abs(z) < Grid.RING then
				return false
			end
		end
	end
	return true
end

function Districts.cells(towns: { Vector3 }): { Cell }
	if cellsCache then
		return cellsCache
	end
	local cells: { Cell } = {}
	local e = Grid.HALF + 2
	local function add(rect: Rect, center: boolean)
		local cx, cz = (rect.X0 + rect.X1) / 2, (rect.Z0 + rect.Z1) / 2
		local district = CityPlan.districtAt(cx, cz)
		if district then
			table.insert(cells, {
				X0 = rect.X0, X1 = rect.X1, Z0 = rect.Z0, Z1 = rect.Z1,
				Kind = kindFor(district.Id, cx, cz, center),
				District = district.Id,
			})
		end
	end
	-- Dentro de la Ronda: manzanas de 250
	local s = Grid.STEP_CENTER
	for a = Grid.OFFSET - 5 * s, Grid.RING - s, s do
		for b = Grid.OFFSET - 5 * s, Grid.RING - s, s do
			local rect = { X0 = a + e, X1 = a + s - e, Z0 = b + e, Z1 = b + s - e }
			if rect.X0 > -Grid.RING and rect.X1 < Grid.RING and rect.Z0 > -Grid.RING and rect.Z1 < Grid.RING then
				-- Las manzanas que cruza una avenida del centro se parten en dos (una a cada lado)
				local pieces = { rect }
				local cut = Grid.HALF + 3
				if rect.X0 < 0 and rect.X1 > 0 then
					pieces = { { X0 = rect.X0, X1 = -cut, Z0 = rect.Z0, Z1 = rect.Z1 }, { X0 = cut, X1 = rect.X1, Z0 = rect.Z0, Z1 = rect.Z1 } }
				elseif rect.Z0 < 0 and rect.Z1 > 0 then
					pieces = { { X0 = rect.X0, X1 = rect.X1, Z0 = rect.Z0, Z1 = -cut }, { X0 = rect.X0, X1 = rect.X1, Z0 = cut, Z1 = rect.Z1 } }
				end
				for _, piece in pieces do
					if ok(piece, towns, false) then
						add(piece, true)
					end
				end
			end
		end
	end
	-- Fuera: manzanas de 500 partidas en 4 (con paseos de 16 studs entre ellas)
	local S = Grid.STEP
	local B = CityPlan.Bounds
	local k0x, k1x = math.floor((B.MinX - Grid.OFFSET) / S), math.ceil((B.MaxX - Grid.OFFSET) / S)
	local k0z, k1z = math.floor((B.MinZ - Grid.OFFSET) / S), math.ceil((B.MaxZ - Grid.OFFSET) / S)
	for kx = k0x, k1x do
		for kz = k0z, k1z do
			local a, b = Grid.OFFSET + kx * S, Grid.OFFSET + kz * S
			local x0, x1, z0 = a + e, a + S - e, b + e
			local half = (x1 - x0 - 16) / 2
			for i = 0, 1 do
				for j = 0, 1 do
					local rect = {
						X0 = x0 + i * (half + 16), X1 = x0 + i * (half + 16) + half,
						Z0 = z0 + j * (half + 16), Z1 = z0 + j * (half + 16) + half,
					}
					if ok(rect, towns, true) then
						add(rect, false)
					end
				end
			end
		end
	end
	-- Colocar los lugares emblemáticos en la manzana (grande) más cercana a su sitio
	for _, spec in LANDMARKS do
		local best, bestDistance = nil, math.huge
		for _, cell in cells do
			if cell.District == spec[2] and not (cell :: any).Landmark and cell.X1 - cell.X0 > 150 and cell.Z1 - cell.Z0 > 150 then
				local d = math.sqrt(((cell.X0 + cell.X1) / 2 - spec[3]) ^ 2 + ((cell.Z0 + cell.Z1) / 2 - spec[4]) ^ 2)
				if d < bestDistance then
					best, bestDistance = cell, d
				end
			end
		end
		if best then
			best.Kind = spec[1];
			(best :: any).Landmark = true
		end
	end
	cellsCache = cells
	return cells
end

-- Trabajadores de los edificios importantes: aquí solo se marca dónde están (pieza invisible
-- "WorkerSpot" con el oficio en Role); los crea WorldService al empezar la partida.
local WORKERS: { [string]: { string } } = {
	TorreValmar = { "Guardia", "Recepcionista" },
	Ayuntamiento = { "Funcionario", "Guardia" },
	EstacionCentral = { "Revisor", "Taquillero" },
	EstacionAutobuses = { "Conductor", "Revisor" },
	Museo = { "Guía" },
	Teatro = { "Taquillero" },
	GranCentroComercial = { "Dependiente", "Guardia" },
	Feria = { "Feriante", "Feriante" },
	Camping = { "Monitor" },
	HospitalCentral = { "Médico", "Enfermera" },
	ClinicaOeste = { "Médico" },
	ClinicaEste = { "Enfermera" },
	ComisariaCentral = { "Policía", "Policía" },
	ComisariaSur = { "Policía" },
	ColegioCentro = { "Conserje" },
	ColegioNorte = { "Conserje" },
	ColegioOeste = { "Conserje" },
	ColegioSur = { "Conserje" },
	InstitutoEste = { "Conserje" },
	Hotel = { "Recepcionista" },
}

-- Busca sitios libres cerca del borde de la manzana (sin paredes ni muebles encima)
local function workerSpots(block: Instance, cell: Rect, roles: { string })
	local boxes = {}
	for _, p in block:GetDescendants() do
		if p:IsA("BasePart") and p.Name ~= "BlockGround" then
			local cf, size = p.CFrame, p.Size
			local ex = math.abs(cf.RightVector.X) * size.X + math.abs(cf.UpVector.X) * size.Y + math.abs(cf.LookVector.X) * size.Z
			local ey = math.abs(cf.RightVector.Y) * size.X + math.abs(cf.UpVector.Y) * size.Y + math.abs(cf.LookVector.Y) * size.Z
			local ez = math.abs(cf.RightVector.Z) * size.X + math.abs(cf.UpVector.Z) * size.Y + math.abs(cf.LookVector.Z) * size.Z
			if cf.Y - ey / 2 < 6 and cf.Y + ey / 2 > 0.3 then
				table.insert(boxes, { cf.X - ex / 2 - 2.5, cf.X + ex / 2 + 2.5, cf.Z - ez / 2 - 2.5, cf.Z + ez / 2 + 2.5 })
			end
		end
	end
	local function free(x: number, z: number): boolean
		for _, b in boxes do
			if x > b[1] and x < b[2] and z > b[3] and z < b[4] then
				return false
			end
		end
		return true
	end
	-- Candidatos a 7 studs de cada borde, empezando por el centro de cada lado; mirando hacia fuera
	local cx, cz = (cell.X0 + cell.X1) / 2, (cell.Z0 + cell.Z1) / 2
	local w, d = cell.X1 - cell.X0, cell.Z1 - cell.Z0
	local candidates = {}
	for t = 0, 0.45, 0.05 do
		for _, sign in { 1, -1 } do
			local o = t * sign
			table.insert(candidates, { cx + o * w, cell.Z1 - 7, 0, 1, t })
			table.insert(candidates, { cx + o * w, cell.Z0 + 7, 0, -1, t })
			table.insert(candidates, { cell.X1 - 7, cz + o * d, 1, 0, t })
			table.insert(candidates, { cell.X0 + 7, cz + o * d, -1, 0, t })
		end
	end
	local placed = {}
	for _, c in candidates do
		if #placed >= #roles then
			break
		end
		local far = true
		for _, q in placed do
			if (q.X - c[1]) ^ 2 + (q.Z - c[2]) ^ 2 < 14 * 14 then
				far = false
			end
		end
		if far and free(c[1], c[2]) then
			local pos = Vector3.new(c[1], 0, c[2])
			table.insert(placed, pos)
			local spot = Builder.decor({
				Name = "WorkerSpot",
				Size = Vector3.new(1, 1, 1),
				CFrame = Builder.facing(pos + Vector3.new(0, 0.5, 0), Vector3.new(c[3], 0, c[4])),
				Transparency = 1,
				Parent = block,
			})
			spot:SetAttribute("Role", roles[#placed])
			spot:AddTag("WorkerSpot")
		end
	end
end

function Districts.build(world: Instance, towns: { Vector3 })
	local folder = Builder.model("Distritos", world)
	local models: { [string]: Model } = {}
	for _, cell in Districts.cells(towns) do
		local model = models[cell.District]
		if not model then
			model = Builder.model("District_" .. cell.District, folder)
			models[cell.District] = model
		end
		local block = Builder.model("Manzana_" .. cell.Kind, model)
		Builder.part({
			Name = "BlockGround",
			Size = Vector3.new(cell.X1 - cell.X0, 1, cell.Z1 - cell.Z0),
			CFrame = CFrame.new((cell.X0 + cell.X1) / 2, -0.5, (cell.Z0 + cell.Z1) / 2),
			Color = if PAVED[cell.Kind] then rgb(186, 182, 174) else rgb(98, 146, 70),
			Material = if PAVED[cell.Kind] then Enum.Material.Pavement else Enum.Material.Grass,
			CastShadow = false,
			Parent = block,
		})
		local build = builders[cell.Kind]
		if build then
			build(block, cell)
		end
		if WORKERS[cell.Kind] then
			workerSpots(block, cell, WORKERS[cell.Kind])
		end
	end
	return folder
end

-- ¿Punto dentro de alguna manzana? (para no plantar árboles del campo encima)
function Districts.blocked(x: number, z: number, towns: { Vector3 }): boolean
	for _, cell in Districts.cells(towns) do
		if x > cell.X0 - 6 and x < cell.X1 + 6 and z > cell.Z0 - 6 and z < cell.Z1 + 6 then
			return true
		end
	end
	return false
end

return Districts
