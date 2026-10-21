-- TerrainPalette (compartido): los colores del terreno y QUIÉN los puede cambiar.
--
-- En Roblox hay UN solo workspace.Terrain por place y sus colores por material
-- (Terrain:SetMaterialColor → Terrain.MaterialColors) valen para TODO el terreno, esté donde esté.
-- Valmar y los planetas (Tefra a 35 000 studs, Miasma, Siroco…) comparten ese terreno.
--
-- El fallo (v122–v124, «el fondo del mar es nieve blanca», 4.ª queja del dueño): TerrainBuilder ponía
-- Salt = arena dorada (204, 186, 146) al arrancar, pero ~20 s después World/PlanetWorld.setupLooks
-- (en Main.server, tras Images.resolve de las texturas del espacio) ponía los colores de Tefra en el
-- MISMO terreno: Salt = ceniza clara (186, 178, 182), Sandstone, Limestone, Slate y Basalt. El fondo
-- del mar de Valmar (Salt + ondas de Sandstone + manchas de Limestone, desde la v122) quedaba gris
-- blanquecino con el grano agrietado de Salt: el «campo de nieve» de las capturas (píxel del fondo
-- en captura-1: 220, 223, 232 — gris neutro, nada de dorado). Las pruebas con Lune no lo veían: cada
-- una carga su módulo con un terreno de mentira, nunca los dos en el mismo terreno.
--
-- Ahora:
--   * El servidor solo pone la paleta de Valmar (TerrainBuilder, OceanBuilder). Nadie más llama a
--     SetMaterialColor en el servidor con un material de Valmar (Reserved): scripts/test-mar.luau
--     revisa todo src/ buscando llamadas.
--   * Los planetas pintan su terreno EN EL CLIENTE y solo mientras la cámara está en el planeta
--     (Controllers/TerrainPaletteClient): al volver, se devuelve la paleta de Valmar.
--   * Y en Valmar el cliente vigila los colores del fondo del mar (Sea): si algo los cambia, los
--     devuelve y lo apunta (atributo TerrainPaletteFixes del jugador; la sonda de la nube lo lee).

local rgb = Color3.fromRGB

local TerrainPalette = {}

-- El fondo del mar de Valmar (materiales que solo usa el mar: ni World/UserMaterials los aclara ni
-- Controllers/Weather los cubre de nieve)
TerrainPalette.Sea = {
	-- (v124, captura del dueño v123: casi blanca bajo el agua turquesa clara se veía como un campo de
	-- nieve. Arena clara DORADA, con ondas de arenisca y caliza algo más oscura para el contraste)
	-- (v127.1: la arena del fondo vuelve a ser Salt. El «Snow» teñido de la v127 dominaba el fondo y podía
	-- verse como nieve; Snow queda para Nivalis y la nieve del invierno)
	Salt = rgb(204, 186, 146),
	Sandstone = rgb(190, 166, 122),
	Limestone = rgb(200, 192, 166),
	Mud = rgb(74, 70, 58), -- fango del kelp y del abismo (World/OceanBuilder)
	Basalt = rgb(46, 52, 66), -- basalto azulado (paredes y agujas del mar hondo)
}

-- Materiales del terreno que usa Valmar (isla, relieve y mar): el servidor no los tiñe para otro sitio
TerrainPalette.Reserved = {
	Grass = true,
	LeafyGrass = true,
	Rock = true,
	Slate = true,
	Sand = true,
	Ground = true,
	Salt = true,
	Sandstone = true,
	Limestone = true,
	Mud = true,
	Basalt = true,
	Water = true,
}

-- Estaciones y lluvia (v126, Controllers/Weather, EN EL CLIENTE y solo con la cámara en Valmar):
--   Seasonal: los que cambian de color con la estación (y se cubren de nieve).
--   Wettable: los que se oscurecen al mojarse. NINGUNO del fondo del mar (TerrainPalette.Sea) ni el agua:
--   scripts/test-estaciones lo comprueba.
TerrainPalette.Seasonal = { Grass = true, LeafyGrass = true }
TerrainPalette.Wettable = { Grass = true, LeafyGrass = true, Ground = true }

-- ¿Puede el tiempo de Valmar tocar este material del terreno?
function TerrainPalette.weatherMay(name: string): boolean
	return (TerrainPalette.Seasonal[name] or TerrainPalette.Wettable[name]) == true and TerrainPalette.Sea[name] == nil and name ~= "Water"
end

-- Colores casi iguales (lo que se lee del terreno vuelve redondeado a 8 bits)
function TerrainPalette.same(a: Color3, b: Color3): boolean
	return math.abs(a.R - b.R) < 3 / 255 and math.abs(a.G - b.G) < 3 / 255 and math.abs(a.B - b.B) < 3 / 255
end

-- ¿Es "blanco nieve"? (para la sonda y las pruebas: el fondo del mar nunca)
function TerrainPalette.snowy(c: Color3): boolean
	local hi, lo = math.max(c.R, c.G, c.B), math.min(c.R, c.G, c.B)
	return lo > 0.68 and hi - lo < 0.08
end

-- ¿Está en Valmar (el mar y la isla)? Los planetas están muy lejos (Tefra en −25 000, 25 000; los
-- de shared/Cosmos/PlanetSurface, también fuera): allí el fondo del mar no se vigila, que lo pinta su planeta.
TerrainPalette.ValmarArea = { MinX = -6500, MaxX = 6500, MinZ = -6000, MaxZ = 6500, MaxY = 2500 }
function TerrainPalette.inValmar(pos: Vector3): boolean
	local a = TerrainPalette.ValmarArea
	return pos.X >= a.MinX and pos.X <= a.MaxX and pos.Z >= a.MinZ and pos.Z <= a.MaxZ and pos.Y <= a.MaxY
end

-- Qué paleta toca donde está la cámara: "Valmar" o el planeta (con sus colores).
-- planets: lista de { Id, contains(pos, margin) -> boolean, TerrainColors }
function TerrainPalette.zoneAt(pos: Vector3, planets: { any }): (string, { [string]: Color3 }?)
	for _, planet in planets do
		local ok, inside = pcall(planet.contains, pos, 400)
		if ok and inside then
			return planet.Id, planet.TerrainColors
		end
	end
	return "Valmar", nil
end

return TerrainPalette
