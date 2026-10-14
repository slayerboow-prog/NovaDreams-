-- EspacioLook: qué imagen va en cada sitio del espacio, los planetas y la nave, y qué se hace si aún no
-- está subida (cuentas puras; docs/planetas.md). Como shared/CosmeLook: sin ids (EspacioTextureIds
-- vacío) TODO se ve igual de bien con colores y materiales de Roblox; con ids, se ponen las texturas.
--
-- Cómo se ponen las imágenes en un juego hecho con Rojo (SurfaceAppearance no se puede crear desde un
-- script en un servidor de verdad):
--   * Cielos (Sky): sus 6 caras SÍ se pueden poner desde un script → Sky "EspacioProfundo" y
--     "CieloLontana" en ReplicatedStorage.SkyLibrary (World/PlanetWorld) y Controllers/DayLight los pone.
--   * Planetas: esfera con SpecialMesh de tipo Sphere y su TextureId (se puede poner desde un script):
--     la imagen equirrectangular envuelve la esfera. Nubes: otra esfera un poco mayor con PNG
--     transparente. Atmósfera: un BillboardGui con el aro (halo_atmosfera) teñido del color del planeta.
--   * Casco de la nave y rocas de Lontana: MaterialVariant ("NaveCasco" sobre Metal y "LontanaRoca"
--     sobre Basalt, SIN sustituir el material en todo el juego: solo las piezas que lo piden). Sus
--     mapas solo se pueden escribir al construir el archivo (scripts/build-place.luau los deja puestos
--     con estos ids); en Studio también desde el servidor. Si el variant no existe, las piezas se
--     quedan con su material de siempre.

local EspacioLook = {}

EspacioLook.SkyFaces = { SkyboxBk = "bk", SkyboxDn = "dn", SkyboxFt = "ft", SkyboxLf = "lf", SkyboxRt = "rt", SkyboxUp = "up" }
EspacioLook.Skies = { EspacioProfundo = "cielo_espacio", CieloLontana = "cielo_lontana" }

-- MaterialVariant propios (no Override: pieza a pieza)
EspacioLook.Variants = {
	NaveCasco = { Prefix = "nave_casco", Base = "Metal", Studs = 9, Pattern = "Regular", Maps = { "color", "normal", "roughness", "metalness" } },
	LontanaRoca = { Prefix = "roca_lontana", Base = "Basalt", Studs = 14, Pattern = "Organic", Maps = { "color", "normal", "roughness" } },
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
	return if valid(v) then v else nil
end

-- Las 6 caras de un cielo, o nil si falta alguna (un cielo a medias se vería roto)
function EspacioLook.skyFaces(ids: { [string]: string }?, prefix: string): { [string]: string }?
	local out = {}
	for prop, suffix in EspacioLook.SkyFaces do
		local id = EspacioLook.id(ids, prefix .. "_" .. suffix)
		if not id then
			return nil
		end
		out[prop] = id
	end
	return out
end

export type PlanetLook = { Texture: string?, Clouds: string?, Halo: string? }

-- Texturas de un planeta (las que haya)
function EspacioLook.planet(ids: { [string]: string }?, planetId: string): PlanetLook
	local key = string.lower(planetId)
	return {
		Texture = EspacioLook.id(ids, "planeta_" .. key),
		Clouds = EspacioLook.id(ids, "nubes_" .. key),
		Halo = EspacioLook.id(ids, "halo_atmosfera"),
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
			table.insert(names, prefix .. "_" .. suffix)
		end
	end
	for _, id in { "lontana", "ocrea", "marena", "velaria", "fronda", "zefira", "mercadia" } do
		table.insert(names, "planeta_" .. id)
	end
	for _, id in { "lontana", "marena", "fronda" } do
		table.insert(names, "nubes_" .. id)
	end
	table.insert(names, "halo_atmosfera")
	for _, v in EspacioLook.Variants do
		for _, map in v.Maps do
			table.insert(names, v.Prefix .. "_" .. map)
		end
	end
	table.sort(names)
	return names
end

return EspacioLook
