-- Textures: los materiales con textura PBR de verdad (MaterialService > MaterialVariant).
--
-- Las texturas se generan con código (scripts/textures/gen.py -> textures/<Juego>/color.png,
-- normal.png, roughness.png y, en los metales, metalness.png), se suben con
-- scripts/upload-textures.sh (escribe sus ids en shared/TextureIds) y el servidor crea un
-- MaterialVariant por cada material que tenga ids (World/Kit/MaterialLook).
--
-- Cuentas puras (sin Instances): se prueban fuera de Roblox (scripts/test-textures.luau).
--
--   * El ColorMap es NEUTRO: Roblox lo multiplica por el Color de la pieza. El color de cada fachada,
--     acera o coche lo sigue poniendo el kit (Palette); la textura pone el detalle (grano, juntas,
--     poros, vetas) y el relieve y el brillo (normal y rugosidad).
--   * Override = true: el variant sustituye al material de Roblox en TODO el juego (piezas y terreno:
--     el césped y la arena del terreno también). Los demás se ponen pieza a pieza (Textures.rule).
--   * Sin ids (aún no subidas o 0) no se crea nada ni se cambia ninguna pieza: se ve como siempre.

local Textures = {}

export type Variant = {
	Set: string, -- carpeta de textures/ (y prefijo en TextureIds)
	Base: string, -- Enum.Material de la pieza
	Studs: number, -- StudsPerTile: lo que mide una repetición de la textura (1 stud ≈ 28 cm)
	Pattern: "Regular" | "Organic", -- Organic: Roblox rompe la repetición (para lo que no tiene juntas)
	Override: boolean, -- sustituye al material base en todo el juego
	Maps: { string }, -- mapas del juego (color, normal, roughness, metalness)
}

local PBR = { "color", "normal", "roughness" }
local METAL = { "color", "normal", "roughness", "metalness" }

-- Nombre del MaterialVariant -> cómo es. (Los nombres también son los de textures/ salvo MaderaVeta,
-- que usa las tablas de Madera sobre el material Wood.)
Textures.Variants = {
	Asfalto = { Set = "Asfalto", Base = "Asphalt", Studs = 14, Pattern = "Organic", Override = true, Maps = PBR },
	AceraBaldosa = { Set = "AceraBaldosa", Base = "Pavement", Studs = 9.6, Pattern = "Regular", Override = true, Maps = PBR },
	Bordillo = { Set = "Bordillo", Base = "Granite", Studs = 5, Pattern = "Organic", Override = true, Maps = PBR },
	Hormigon = { Set = "Hormigon", Base = "Concrete", Studs = 14, Pattern = "Organic", Override = true, Maps = PBR },
	Ladrillo = { Set = "Ladrillo", Base = "Brick", Studs = 6.4, Pattern = "Regular", Override = true, Maps = PBR },
	Estuco = { Set = "Estuco", Base = "Plaster", Studs = 10, Pattern = "Organic", Override = true, Maps = PBR },
	Teja = { Set = "Teja", Base = "ClayRoofTiles", Studs = 9, Pattern = "Regular", Override = true, Maps = PBR },
	MetalPintado = { Set = "MetalPintado", Base = "Metal", Studs = 8, Pattern = "Organic", Override = true, Maps = METAL },
	MetalCepillado = { Set = "MetalCepillado", Base = "Metal", Studs = 4, Pattern = "Regular", Override = false, Maps = METAL },
	Madera = { Set = "Madera", Base = "WoodPlanks", Studs = 5, Pattern = "Regular", Override = true, Maps = PBR },
	MaderaVeta = { Set = "Madera", Base = "Wood", Studs = 5, Pattern = "Regular", Override = false, Maps = PBR },
	Marmol = { Set = "Marmol", Base = "Marble", Studs = 16, Pattern = "Regular", Override = true, Maps = PBR },
	CespedSuelo = { Set = "CespedSuelo", Base = "Grass", Studs = 8, Pattern = "Organic", Override = true, Maps = PBR },
	Arena = { Set = "Arena", Base = "Sand", Studs = 12, Pattern = "Organic", Override = true, Maps = PBR },
	Azulejo = { Set = "Azulejo", Base = "CeramicTiles", Studs = 8, Pattern = "Regular", Override = true, Maps = PBR },
	PinturaCoche = { Set = "PinturaCoche", Base = "SmoothPlastic", Studs = 3, Pattern = "Organic", Override = false, Maps = METAL },
	PinturaVial = { Set = "PinturaVial", Base = "SmoothPlastic", Studs = 6, Pattern = "Organic", Override = false, Maps = PBR },
} :: { [string]: Variant }

-- Propiedad del MaterialVariant para cada mapa
Textures.MapProperty = { color = "ColorMap", normal = "NormalMap", roughness = "RoughnessMap", metalness = "MetalnessMap" }

-- Lo que se pinta pieza a pieza (lo que no cubre el Override)
Textures.RoadPaint = { Marking = true, Zebra = true, RingMarking = true, BusLaneMark = true, ParkingMark = true }
Textures.RoadPaintLine = { Parking = true, Aparcamiento = true } -- "Line" solo en estos aparcamientos
Textures.Curbs = { Curb = true, IslandCurb = true, RingCurb = true, RoadKerb = true }
-- Madera que NO es de tablas ni muebles: troncos y ramas de los árboles se quedan con su corteza
Textures.Bark = { Trunk = true, Branch = true, Root = true, Roots = true, PalmTrunk = true, Log = true, Stump = true }

local function validId(id: any): boolean
	return type(id) == "string" and id:match("^rbxassetid://[1-9]%d*$") ~= nil
end

-- Ids de un variant: { ColorMap = "rbxassetid://…", NormalMap = … } o nil si falta el ColorMap
-- (sin color no se crea: se vería un material a medias). Los demás mapas, los que haya.
function Textures.maps(name: string, ids: { [string]: string }): { [string]: string }?
	local v = Textures.Variants[name]
	if not v then
		return nil
	end
	local out = {}
	for _, map in v.Maps do
		local id = ids[v.Set .. "_" .. map]
		if validId(id) then
			out[Textures.MapProperty[map]] = id
		end
	end
	if not out.ColorMap then
		return nil
	end
	return out
end

-- Nombres de los variants que se pueden crear con estos ids (ordenados)
function Textures.available(ids: { [string]: string }): { string }
	local names = {}
	for name in Textures.Variants do
		if Textures.maps(name, ids) then
			table.insert(names, name)
		end
	end
	table.sort(names)
	return names
end

-- Firma de lo que hay (para no repasar la ciudad dos veces con los mismos ids)
function Textures.signature(ids: { [string]: string }): string
	return table.concat(Textures.available(ids), ",")
end

-- Nivel gráfico Bajo: sin mapas normales (relieve) para ahorrar memoria y GPU en el móvil
function Textures.mapsForTier(maps: { [string]: string }, normalMaps: boolean): { [string]: string }
	local out = table.clone(maps)
	if not normalMaps then
		out.NormalMap = nil
	end
	return out
end

local function grayish(c: Color3): (number, number)
	local maxc = math.max(c.R, c.G, c.B)
	local minc = math.min(c.R, c.G, c.B)
	return (c.R + c.G + c.B) / 3, if maxc > 0 then (maxc - minc) / maxc else 0
end

-- Regla pieza a pieza: qué variant (y, si hace falta, qué material) le toca a una pieza que no cubre
-- un Override. info: Name, Material (nombre del Enum), Color, Parent (nombre), Paint (color de
-- carrocería del modelo, si es un coche). Devuelve nil si se queda como está.
export type PartInfo = { Name: string, Material: string, Color: Color3, Parent: string?, Paint: Color3? }
function Textures.rule(info: PartInfo): (string?, string?)
	local m = info.Material
	if m == "SmoothPlastic" then
		local paint = info.Paint
		local c = info.Color
		if paint and math.abs(c.R - paint.R) + math.abs(c.G - paint.G) + math.abs(c.B - paint.B) < 0.012 then
			return "PinturaCoche", nil
		end
		if Textures.RoadPaint[info.Name] or (info.Name == "Line" and info.Parent and Textures.RoadPaintLine[info.Parent]) then
			return "PinturaVial", nil
		end
	elseif m == "Concrete" and Textures.Curbs[info.Name] then
		return "Bordillo", "Granite" -- bordillo de granito (antes, hormigón liso)
	elseif m == "Metal" then
		local v, sat = grayish(info.Color)
		if v > 0.62 and sat < 0.12 then
			return "MetalCepillado", nil -- acero claro: barandillas, cromados, tubos, buzones…
		end
	elseif m == "Wood" and not Textures.Bark[info.Name] then
		return "MaderaVeta", nil
	end
	return nil, nil
end

-- Cristal de los vehículos: algo de reflejo (con la iluminación Future refleja el cielo y las calles)
Textures.VehicleGlassReflectance = 0.18

return Textures
