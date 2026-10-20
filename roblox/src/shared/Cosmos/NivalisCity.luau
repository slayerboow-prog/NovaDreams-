-- NivalisCity: el PLANO del barrio de Fortaleza Albor, la capital de Nivalis (docs/planetas/nivalis-umbria.md;
-- diseño: docs/planetas/diseno-mundos.md §3.4). Hecho con el marco común (shared/Cosmos/PlanetCity.new):
-- un barrio pequeño dentro de la Muralla Vieja, de piedra gris y hielo tallado, con el Patio de Armas
-- (la plataforma), la Plaza de los Faroles (la Estatua Rota de la Reina y las hogueras de musgo), el
-- Mercado de Hielo, las Termas del Farol, la Biblioteca de los Ecos y la casa de Tila.
--
-- Coordenadas LOCALES de Nivalis (X = este, Z = sur; el norte, −Z, mira al Palacio de Escarcha).
--
--                    N  (Palacio de Escarcha y Picos del Silencio, a lo lejos)
--      ┌────────────── LA MURALLA VIEJA ──── Puerta Norte ──── (torres en las esquinas) ┐
--      │ pasadizo · casa farol    Torre del Farolero      casa farol   CUERPO DE GUARDIA │
--      │ TERMAS DEL FAROL            🛬 PATIO DE ARMAS         puesto          casa farol│ Puerta
--  Puerta  casa farol           puesto        puesto                       casa farol  │  Este
--      │ ~ estanque roto   SOPA ·  PLAZA DE LOS FAROLES (Estatua Rota)  · BIBLIOTECA     │
--      │ CASA DE TILA                    hogueras                         casa farol    │
--      └────────────────────────────── Puerta Sur ─────────────────────────────────────┘
--
-- Todas las claves empiezan por «Nivalis_». Nada se guarda nuevo en la partida.

local PlanetCity = require(script.Parent.PlanetCity)

local P = {}

P.Id = "FortalezaAlbor"
P.Name = "Fortaleza Albor"
P.Planet = "Nivalis"
P.KeyPrefix = "Nivalis_"
P.Rect = { X0 = -136, X1 = 136, Z0 = -126, Z1 = 126 }
P.Blend = 140
P.OpenGround = true -- (la nieve pisada de dentro de la muralla: se anda por todo lo que no es edificio)
P.Arrival = { 0, 30 }

-- Suelos (losas de piedra azulada y empedrado helado)
P.Floors = {
	{ Id = "PatioDeArmas", Kind = "Rect", X0 = -58, X1 = 58, Z0 = -52, Z1 = 40, Material = Enum.Material.Slate, Color = Color3.fromRGB(96, 104, 118) },
	{ Id = "PlazaFaroles", Kind = "Disc", X = 0, Z = 80, R = 38, Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(122, 132, 148) },
	{ Id = "CalleNorte", Kind = "Rect", X0 = -12, X1 = 12, Z0 = -118, Z1 = -52, Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(110, 118, 132) },
	{ Id = "CalleSur", Kind = "Rect", X0 = -12, X1 = 12, Z0 = 116, Z1 = 126, Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(110, 118, 132) },
	{ Id = "CalleEste", Kind = "Rect", X0 = 58, X1 = 136, Z0 = -10, Z1 = 10, Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(110, 118, 132) },
	{ Id = "CalleOeste", Kind = "Rect", X0 = -136, X1 = -58, Z0 = -10, Z1 = 10, Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(110, 118, 132) },
}

-- El estanque helado roto (hielo fino: si caes, sales a la orilla)
P.Pits = {
	{ Kind = "Disc", X = -104, Z = 70, R = 10, Depth = 12, Name = "Estanque roto", Text = "¡Hielo fino! El agua helada te escupe a la orilla." },
}

P.Districts = {
	{ Id = "Patio", Name = "Patio de Armas", Theme = "Muralla", Icon = "🏰", Color = Color3.fromRGB(150, 170, 200), Poly = { { -136, -126 }, { 136, -126 }, { 136, 40 }, { -136, 40 } } },
	{ Id = "Faroles", Name = "Barrio de los Faroles", Theme = "Faroles", Icon = "🏮", Color = Color3.fromRGB(240, 190, 110), Poly = { { -136, 40 }, { 136, 40 }, { 136, 126 }, { -136, 126 } } },
}

-- Edificios. Box = planta baja jugable (Kit/Building); las demás formas las dibuja World/NivalisKit.
local B = {
	-- Los que se pueden visitar por dentro
	{ Id = "Termas", District = "Patio", Shape = "Box", Name = "Termas del Farol", X = -98, Z = -30, W = 30, D = 22, Face = "E", Floors = 1, Style = "NivalisPiedra", Ground = "Lobby",
		Sign = "TERMAS DEL FAROL", Icon = "♨", Info = "Baños calientes de piedra. El único sitio del barrio donde el vapor no es un lujo… si no te pide nadie el carné de lealtad." },
	{ Id = "Sopa", District = "Faroles", Shape = "Box", Name = "Puesto de sopa de Brisa", X = -66, Z = 74, W = 22, D = 16, Face = "E", Floors = 1, Style = "NivalisPiedra", Ground = "Shop",
		Sign = "SOPA CALIENTE", ShopId = "NivalisSopa", Icon = "🍲", Info = "La sopa de musgo de Brisa. Dicen que aquí se oyen más secretos que en el Palacio." },
	{ Id = "Biblioteca", District = "Faroles", Shape = "Box", Name = "Biblioteca de los Ecos", X = 70, Z = 66, W = 30, D = 24, Face = "W", Floors = 2, Style = "NivalisHielo", Ground = "Lobby",
		Sign = "BIBLIOTECA DE LOS ECOS", Icon = "📚", Info = "Canciones guardadas en cristales. Cerrada por orden del Regente: cantar está prohibido." },
	{ Id = "CasaTila", District = "Faroles", Shape = "Box", Name = "La casa de Tila", X = -52, Z = 100, W = 18, D = 14, Face = "N", Floors = 1, Style = "NivalisPiedra", Ground = "House",
		Icon = "🏠", Info = "Una casa estrecha con una vela en la ventana. Está prohibido. Nadie la apaga." },
	{ Id = "CuerpoGuardia", District = "Patio", Shape = "Box", Name = "Cuerpo de Guardia del Regente", X = 84, Z = -74, W = 26, D = 20, Face = "W", Floors = 2, Style = "NivalisHielo", Ground = "Closed",
		Sign = "GUARDIA DEL REGENTE", Icon = "🛡", Info = "Faroles azules, perros de nieve y un registro de nombres. Mejor no acercarse." },
	-- El monumento, la torre y las casas de tejado-farol
	{ Id = "TorreFarol", District = "Patio", Shape = "Torre", Name = "Torre del Farolero", X = -64, Z = -78, R = 7, Height = 40, Icon = "🗼",
		Info = "Desde lo alto se encienden los faroles del barrio. Los faroleros lo saben todo; casi nunca lo dicen." },
	{ Id = "Estatua", District = "Faroles", Shape = "Estatua", Name = "Estatua Rota de la Reina", X = 0, Z = 84, R = 4, Height = 16, Icon = "👑",
		Info = "La Reina Alva, sin cabeza desde hace seis años. Alguien deja cada noche una vela a sus pies." },
	{ Id = "CasaFarolA", District = "Patio", Shape = "CasaFarol", Name = "Casa de tejado-farol", X = -100, Z = 30, W = 16, D = 14, Face = "E", Height = 24 },
	{ Id = "CasaFarolB", District = "Patio", Shape = "CasaFarol", Name = "Casa de tejado-farol", X = -104, Z = -86, W = 16, D = 14, Face = "E", Height = 24 },
	{ Id = "CasaFarolC", District = "Patio", Shape = "CasaFarol", Name = "Casa de tejado-farol", X = 100, Z = -20, W = 16, D = 14, Face = "W", Height = 24 },
	{ Id = "CasaFarolD", District = "Patio", Shape = "CasaFarol", Name = "Casa de tejado-farol", X = 102, Z = 22, W = 16, D = 14, Face = "W", Height = 24 },
	{ Id = "CasaFarolE", District = "Patio", Shape = "CasaFarol", Name = "Casa de tejado-farol", X = 30, Z = -96, W = 16, D = 14, Face = "S", Height = 26 },
	{ Id = "CasaFarolF", District = "Faroles", Shape = "CasaFarol", Name = "Casa de tejado-farol", X = 100, Z = 100, W = 16, D = 14, Face = "W", Height = 22 },
	-- El Mercado de Hielo (puestos de mantas, guantes y sopa)
	{ Id = "PuestoMantas", District = "Faroles", Shape = "Puesto", Name = "Puesto de mantas", X = -34, Z = 46, W = 10, D = 8, Face = "S", Height = 9, Info = "Mantas de lana de lanudo. El vendedor no levanta la vista: hay espías en el mercado." },
	{ Id = "PuestoGuantes", District = "Faroles", Shape = "Puesto", Name = "Puesto de guantes", X = 34, Z = 46, W = 10, D = 8, Face = "S", Height = 9 },
	{ Id = "PuestoCristal", District = "Patio", Shape = "Puesto", Name = "Puesto de cristal común", X = 42, Z = -58, W = 10, D = 8, Face = "W", Height = 9 },
	-- Las hogueras de musgo (calientan: shared/Cosmos/Nivalis.hazardContext)
	{ Id = "HogueraOeste", District = "Faroles", Shape = "Hoguera", Name = "Hoguera de musgo", X = -20, Z = 66, R = 2.5, Height = 5 },
	{ Id = "HogueraEste", District = "Faroles", Shape = "Hoguera", Name = "Hoguera de musgo", X = 20, Z = 66, R = 2.5, Height = 5 },
	{ Id = "HogueraSur", District = "Faroles", Shape = "Hoguera", Name = "Hoguera de musgo", X = 0, Z = 106, R = 2.5, Height = 5 },
}

-- La Muralla Vieja: cuatro lienzos con sus puertas y una torre en cada esquina
local WALL_H = 18
local function wall(id: string, x0: number, x1: number, z0: number, z1: number)
	table.insert(B, { Id = id, District = "Patio", Shape = "Muralla", Name = "La Muralla Vieja", X = (x0 + x1) / 2, Z = (z0 + z1) / 2, W = x1 - x0, D = z1 - z0, Face = "N", Height = WALL_H })
end
wall("MurallaNO", -118, -16, -123, -117)
wall("MurallaNE", 16, 118, -123, -117)
wall("MurallaSO", -118, -16, 117, 123)
wall("MurallaSE", 16, 118, 117, 123)
wall("MurallaON", -133, -127, -108, -14)
wall("MurallaOS", -133, -127, 14, 108)
wall("MurallaEN", 127, 133, -108, -14)
wall("MurallaES", 127, 133, 14, 108)
for _, c in { { -126, -116 }, { 126, -116 }, { -126, 116 }, { 126, 116 } } do
	table.insert(B, { Id = ("TorreMuralla_%d_%d"):format(c[1], c[2]), District = if c[2] < 0 then "Patio" else "Faroles", Shape = "TorreMuralla", Name = "Torre de la Muralla", X = c[1], Z = c[2], R = 8, Height = 30 })
end
P.Buildings = B

-- Las puertas de la muralla (por donde se sale al valle)
P.Gates = {
	{ Id = "Norte", X = 0, Z = -120, Dir = { 0, -1 } },
	{ Id = "Sur", X = 0, Z = 120, Dir = { 0, 1 } },
	{ Id = "Oeste", X = -130, Z = 0, Dir = { -1, 0 } },
	{ Id = "Este", X = 130, Z = 0, Dir = { 1, 0 } },
}

-- Refugios (dentro de su planta baja el frío baja: Cool = cuánto por segundo)
P.Shelters = {
	Termas = { Cool = 8, Name = "las Termas del Farol" },
	Sopa = { Cool = 5, Name = "el puesto de sopa de Brisa" },
	CasaTila = { Cool = 4, Name = "la casa de Tila" },
}

-- Las hogueras de musgo (local x, z): junto a ellas el frío baja (y en las Fuentes Calientes, fuera)
P.Fires = { { X = -20, Z = 66 }, { X = 20, Z = 66 }, { X = 0, Z = 106 } }

local function spot(id: string, name: string, x: number, z: number, extra: { [string]: any }?): { [string]: any }
	local s: { [string]: any } = { Id = id, Name = name, X = x, Z = z }
	for k, v in extra or {} do
		s[k] = v
	end
	return s
end

-- Los sitios de la historia («Nivalis_<Id>» en LifeStory/Locations)
P.StorySpots = {
	spot("Plataforma", "Patio de Armas (la plataforma)", 10, 22),
	spot("PuertaNorte", "Puerta Norte de la Muralla", 0, -104),
	spot("Mirador", "Mirador del Valle de Albor", 0, -300, { Outside = true }),
	spot("Hoguera", "Hoguera de la Plaza de los Faroles", -13, 61),
	spot("Plaza", "Plaza de los Faroles", 0, 56),
	spot("Estatua", "Estatua Rota de la Reina", 0, 74),
	spot("TorreFarol", "Torre del Farolero", -54, -66),
	spot("Termas", "Puerta de las Termas del Farol", -80, -30),
	spot("TermasDentro", "Dentro de las Termas del Farol", -96, -30, { Inside = "Nivalis_Termas" }),
	spot("CasaTila", "Puerta de la casa de Tila", -52, 88),
	spot("CasaTilaDentro", "Dentro de la casa de Tila", -52, 101, { Inside = "Nivalis_CasaTila" }),
	spot("Sopa", "Puesto de sopa de Brisa", -50, 74),
	spot("Farol1", "Farol del oeste de la plaza", -32, 58),
	spot("Farol2", "Farol del este de la plaza", 32, 58),
	spot("Farol3", "Farol del Patio", 0, 34),
	spot("FarolRespuesta", "Farol del otro lado de la plaza", 38, 98),
	spot("Biblioteca", "Puerta de la Biblioteca de los Ecos", 50, 66),
	spot("Callejon", "Callejón detrás de la Biblioteca", 112, 60),
	spot("BibliotecaDentro", "Sala de los cristales (Biblioteca de los Ecos)", 70, 66, { Inside = "Nivalis_Biblioteca" }),
	spot("CuerpoGuardia", "Delante del Cuerpo de Guardia", 64, -74),
	spot("Pasadizo", "Pasadizo de la Muralla Vieja", -112, -102),
	spot("Fuentes", "Fuentes Calientes", 420, 380, { Outside = true }),
}

-- Lo que se recoge (aviso «Recoger»): el musgo de nieve (combustible) y el cristal de eco
P.Gather = {
	{ Id = "Nivalis_MusgoOeste", Name = "Musgo de nieve", X = -118, Z = 40, Item = "MusgoNieve", Every = 60, Text = "+1 musgo de nieve (arde despacio y calienta)" },
	{ Id = "Nivalis_MusgoEste", Name = "Musgo de nieve", X = 118, Z = -50, Item = "MusgoNieve", Every = 60, Text = "+1 musgo de nieve (arde despacio y calienta)" },
	{ Id = "Nivalis_CristalEco", Name = "Cristal de eco", X = 116, Z = 80, Item = "CristalEco", Every = 120, Count = 1, Text = "+1 cristal de eco (si lo acercas al oído, suena una voz muy lejos)" },
}

-- Farolas (faroles de hierro con luz ámbar: siempre encendidos, aquí es de noche siempre)
P.Lamps = {
	{ X = -32, Z = 56 }, { X = 32, Z = 56 }, { X = 0, Z = 32 }, { X = 38, Z = 102 }, { X = -38, Z = 102 },
	{ X = -48, Z = -36 }, { X = 48, Z = -36 }, { X = -48, Z = 32 }, { X = 48, Z = 32 },
	{ X = -18, Z = -108 }, { X = 18, Z = -108 }, { X = 112, Z = -12 }, { X = -112, Z = 12 }, { X = 52, Z = 80 },
}

-- La gente (marcas CrowdSpot «Nivalis_<Grupo>»): susurran (S.CrowdLines)
P.Crowd = {
	{ Group = "Plaza", X = -26, Z = 72, FX = -20, FZ = 66 }, { Group = "Plaza", X = -14, Z = 72, FX = -20, FZ = 66 },
	{ Group = "Plaza", X = 26, Z = 72, FX = 20, FZ = 66 }, { Group = "Plaza", X = 14, Z = 60, FX = 20, FZ = 66 },
	{ Group = "Plaza", X = -6, Z = 112, FX = 0, FZ = 106 }, { Group = "Plaza", X = 8, Z = 112, FX = 0, FZ = 106 },
	{ Group = "Mercado", X = -34, Z = 54, FX = -34, FZ = 46, Work = "Vendedor" }, { Group = "Mercado", X = 34, Z = 54, FX = 34, FZ = 46, Work = "Vendedor" },
	{ Group = "Mercado", X = 34, Z = -58, FX = 42, FZ = -58, Work = "Vendedor" },
	{ Group = "Patio", X = -30, Z = -40, FX = 0, FZ = 0 }, { Group = "Patio", X = 30, Z = 20, FX = 0, FZ = 0 },
	{ Group = "Guardia", X = 66, Z = -66, FX = 0, FZ = -66, Work = "Guardia" }, { Group = "Guardia", X = 6, Z = -112, FX = 0, FZ = -80, Work = "Guardia" },
}
P.Benches = { { X = -24, Z = 98, Yaw = math.pi * 0.25 }, { X = 24, Z = 98, Yaw = -math.pi * 0.25 } }
P.Areas = { { X0 = -40, X1 = 40, Z0 = 44, Z1 = 112 }, { X0 = -50, X1 = 50, Z0 = -48, Z1 = 36 } }

-- Los oficios: el tablón del farolero (junto a su torre) y los faroles de su ruta
P.Jobs = {
	BoardFarolero = { -50, -60 },
	Faroles = { { -32, 58 }, { 32, 58 }, { 0, 34 }, { 38, 98 }, { -38, 98 }, { -48, -32 }, { 48, -32 }, { 112, -8 }, { -112, 8 }, { 52, 76 } },
	Buzones = { { -84, 40 }, { 86, 40 }, { -20, -96 }, { 64, -40 }, { -120, -60 }, { 120, 46 } },
}

-- Ventiscas: dos al día de Nivalis (de 5:00 a 6:12 y de 15:00 a 16:12 del reloj del juego: ~1 min cada una)
P.Blizzards = { { 5, 6.2 }, { 15, 16.2 } }
function P.blizzard(clock: number): boolean
	for _, w in P.Blizzards do
		if clock >= w[1] and clock < w[2] then
			return true
		end
	end
	return false
end

-- El tiempo del reloj en Nivalis: noche eterna, auroras y ventiscas
function P.Weather(clock: number): { Id: string, Name: string, Icon: string, Temp: number }
	if P.blizzard(clock) then
		return { Id = "Ventisca", Name = "Ventisca", Icon = "nieve", Temp = -34 }
	end
	local wave = math.sin(clock / 24 * math.pi * 4)
	return { Id = "Aurora", Name = "Noche de aurora", Icon = "nieve", Temp = math.floor(-19 + 3 * wave + 0.5) }
end

return PlanetCity.new(P)
