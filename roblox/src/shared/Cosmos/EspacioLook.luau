-- EspacioLook: qué imagen va en cada sitio del espacio, los planetas y la nave, y qué se hace si aún no
-- está subida (cuentas puras; docs/planetas.md). Como shared/CosmeLook: sin ids (EspacioTextureIds
-- vacío) TODO se ve igual de bien con colores y materiales de Roblox; con ids, se ponen las texturas.
--
-- Cómo se ponen las imágenes en un juego hecho con Rojo (SurfaceAppearance no se puede crear desde un
-- script en un servidor de verdad):
--   * Cielos (Sky): sus 6 caras SÍ se pueden poner desde un script → Sky "EspacioProfundo" y
--     "CieloTefra" en ReplicatedStorage.SkyLibrary (World/PlanetWorld) y Controllers/DayLight los pone.
--   * Planetas: esfera con SpecialMesh de tipo Sphere y su TextureId (se puede poner desde un script):
--     la imagen equirrectangular envuelve la esfera. Nubes: otra esfera un poco mayor con PNG
--     transparente. Atmósfera: un BillboardGui con el aro (halo_atmosfera) teñido del color del planeta.
--   * Casco de la nave y rocas de Tefra: MaterialVariant ("NaveCasco" sobre Metal y "TefraRoca"
--     sobre Basalt, SIN sustituir el material en todo el juego: solo las piezas que lo piden). Sus
--     mapas solo se pueden escribir al construir el archivo (scripts/build-place.luau los deja puestos
--     con estos ids); en Studio también desde el servidor. Si el variant no existe, las piezas se
--     quedan con su material de siempre.

local EspacioLook = {}

EspacioLook.SkyFaces = { SkyboxBk = "bk", SkyboxDn = "dn", SkyboxFt = "ft", SkyboxLf = "lf", SkyboxRt = "rt", SkyboxUp = "up" }
EspacioLook.Skies = { EspacioProfundo = "cielo_nebulosa", CieloTefra = "cielo_tefra" }
-- (v122, referencia del dueño) Cielo nuevo del espacio, más vivo: nebulosas moradas, azules y rosas, Vía
-- Láctea brillante y muchas más estrellas (scripts/espacio/gen_espacio_v122.py). Hasta que se suba, el
-- de antes («cielo_espacio»): nunca un cielo a medias ni el azul de serie.
EspacioLook.SkyFallback = { cielo_nebulosa = "cielo_espacio" }

-- Imágenes nuevas de la v122 con su nombre de archivo tal cual (sin el alias de los nombres viejos):
-- el juego usa la nueva si está subida y, si no, la de antes (planeta_tefra → planeta_lontana…).
EspacioLook.NewNames = {
	"planeta_tefra", -- Tefra: basalto negro con grietas y mares de lava
	"planeta_vertice", -- Vértice: gigante gaseoso a franjas beige y marrones
	"valmar_tierra", -- Valmar como la Tierra (la isla de verdad arriba, más continentes y hielo)
	"nubes_valmar", -- nubes de Valmar (con transparencia)
	"anillos_vertice", -- anillos con bandas finas (con transparencia)
	"anillos_miasma",
}

-- (nombres nuevos de los planetas) Las imágenes ya subidas siguen con su nombre de archivo de antes
-- (assets/espacio, EspacioTextureIds): el código pide el nombre nuevo y, si no está, el de antes. Así
-- no hace falta volver a subir nada.
EspacioLook.FileAlias = { tefra = "lontana", siroco = "ocrea", talasa = "marena", nivalis = "velaria", umbria = "fronda", miasma = "zefira", vertice = "mercadia" }

-- El nombre de archivo de una imagen (con el nombre viejo del planeta)
function EspacioLook.fileName(name: string): string
	return (string.gsub(name, "%a+", function(word)
		return EspacioLook.FileAlias[word] or word
	end))
end

-- MaterialVariant propios (no Override: pieza a pieza)
EspacioLook.Variants = {
	NaveCasco = { Prefix = "nave_casco", Base = "Metal", Studs = 9, Pattern = "Regular", Maps = { "color", "normal", "roughness", "metalness" } },
	TefraRoca = { Prefix = "roca_tefra", Base = "Basalt", Studs = 14, Pattern = "Organic", Maps = { "color", "normal", "roughness" } },
}
EspacioLook.MapProperty = { color = "ColorMap", normal = "NormalMap", roughness = "RoughnessMap", metalness = "MetalnessMap" }

-- Piezas de la nave del jugador que llevan la chapa (el resto: cristal, neón, toberas… como siempre)
EspacioLook.HullParts = {
	Fuselaje = true, Lomo = true, LomoCola = true, MorroSup = true, MorroInf = true, Panza = true,
	AlaIzq = true, AlaDer = true, TomaIzq = true, TomaDer = true, GondolaIzq = true, GondolaDer = true,
	DerivaIzq = true, DerivaDer = true, MotorIzq = true, MotorDer = true, MotorCentro = true,
}

local function valid(id: any): boolean
	return type(id) == "string" and id:match("^rbxassetid://[1-9]%d*$") ~= nil
end
EspacioLook.valid = valid

function EspacioLook.id(ids: { [string]: string }?, name: string): string?
	local v = ids and ids[name]
	if not valid(v) and ids then
		v = ids[EspacioLook.fileName(name)]
	end
	return if valid(v) then v else nil
end

-- Las 6 caras de un cielo, o nil si falta alguna (un cielo a medias se vería roto). Si el cielo tiene
-- uno de antes (SkyFallback) y al nuevo le falta alguna cara, las 6 del de antes.
function EspacioLook.skyFaces(ids: { [string]: string }?, prefix: string): { [string]: string }?
	local out = {}
	for prop, suffix in EspacioLook.SkyFaces do
		local id = EspacioLook.id(ids, prefix .. "_" .. suffix)
		if not id then
			local older = EspacioLook.SkyFallback[prefix]
			return if older then EspacioLook.skyFaces(ids, older) else nil
		end
		out[prop] = id
	end
	return out
end

export type PlanetLook = { Texture: string?, Clouds: string?, Halo: string?, Rings: string? }

-- Texturas de un planeta (las que haya). Rings: la imagen de sus anillos (si los tiene y está subida).
function EspacioLook.planet(ids: { [string]: string }?, planetId: string): PlanetLook
	local key = string.lower(planetId)
	return {
		Texture = EspacioLook.id(ids, "planeta_" .. key),
		Clouds = EspacioLook.id(ids, "nubes_" .. key),
		Halo = EspacioLook.id(ids, "halo_atmosfera"),
		Rings = EspacioLook.id(ids, "anillos_" .. key),
	}
end

-- Valmar vista desde el espacio: la textura «como la Tierra» (v122) o, si aún no está, el mapa de
-- antes; sus nubes propias o, si no, las de Tálasa.
function EspacioLook.valmar(ids: { [string]: string }?): { Texture: string?, Clouds: string? }
	return {
		Texture = EspacioLook.id(ids, "valmar_tierra") or EspacioLook.id(ids, "valmar_planeta"),
		Clouds = EspacioLook.id(ids, "nubes_valmar") or EspacioLook.id(ids, "nubes_talasa"),
	}
end

-- Mapas de un MaterialVariant ({ ColorMap = …, NormalMap = … }) o nil si falta el color
function EspacioLook.variantMaps(ids: { [string]: string }?, name: string): { [string]: string }?
	local v = EspacioLook.Variants[name]
	if not v then
		return nil
	end
	local out = {}
	for _, map in v.Maps do
		local id = EspacioLook.id(ids, v.Prefix .. "_" .. map)
		if id then
			out[EspacioLook.MapProperty[map]] = id
		end
	end
	return if out.ColorMap then out else nil
end

-- Todos los nombres de archivo que el juego sabe usar (para LICENCIAS.md y el script de subida)
function EspacioLook.allNames(): { string }
	local names = {}
	for _, prefix in EspacioLook.Skies do
		for _, suffix in EspacioLook.SkyFaces do
			table.insert(names, EspacioLook.fileName(prefix .. "_" .. suffix))
		end
	end
	for _, id in { "tefra", "siroco", "talasa", "nivalis", "umbria", "miasma", "vertice" } do
		table.insert(names, EspacioLook.fileName("planeta_" .. id))
	end
	for _, id in { "tefra", "talasa", "umbria" } do
		table.insert(names, EspacioLook.fileName("nubes_" .. id))
	end
	table.insert(names, "halo_atmosfera")
	table.insert(names, "valmar_planeta")
	for _, name in EspacioLook.NewNames do
		table.insert(names, name)
	end
	for _, suffix in EspacioLook.SkyFaces do
		table.insert(names, "cielo_espacio_" .. suffix)
	end
	for _, v in EspacioLook.Variants do
		for _, map in v.Maps do
			table.insert(names, EspacioLook.fileName(v.Prefix .. "_" .. map))
		end
	end
	table.sort(names)
	return names
end

return EspacioLook
