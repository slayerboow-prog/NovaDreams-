-- MiasmaCity: el PLANO del barrio de Anclaje Siete, la última ciudad de Miasma (docs/planetas/
-- diseno-mundos.md §3.6.7; marco común: docs/planetas/marco-planetas.md). Datos para shared/Cosmos/PlanetCity.
--
-- Anclaje Siete son discos de metal y cristal anclados a un pico por encima del mar de niebla venenosa,
-- unidos por pasarelas. Entre disco y disco, el vacío: abajo, la niebla verde (si caes, te suben con un
-- cable: World/MiasmaKit dibuja barandillas para que no pase). Este barrio son cinco discos:
--
--                       (−Z, norte)  LAS GÓNDOLAS (casas colgadas de globos, la barandilla de pañuelos)
--                                         │ pasarela
--   PLAZA DE LAS VELETAS ── pasarela ── MUELLE DE VIENTOS ── pasarela ── LA REFINERÍA
--   (la Gran Veleta, racionamiento)   (🛬 plataforma, torre, enfermería,   (la torre de gas, los depósitos)
--                                       hangar de la Defensa, batería)
--                                         │ pasarela
--                       (+Z, sur)    BARRIO LASTRE (taller de filtros, cantina, hangar de Mara)
--
-- Coordenadas LOCALES de Miasma (studs desde su Origin). Claves «Miasma_…».

local PlanetCity = require(script.Parent.PlanetCity)

local rgb = Color3.fromRGB

local DISCS = {
	{ Id = "Muelle", X = 0, Z = 0, R = 64 },
	{ Id = "Veletas", X = -122, Z = 0, R = 44 },
	{ Id = "Refineria", X = 122, Z = 0, R = 44 },
	{ Id = "Lastre", X = 0, Z = 122, R = 44 },
	{ Id = "Gondolas", X = 0, Z = -122, R = 44 },
}

local floors = {}
for _, d in DISCS do
	table.insert(floors, { Id = "Disco" .. d.Id, Kind = "Disc", X = d.X, Z = d.Z, R = d.R, Disc = true })
end
-- Las pasarelas (de un disco a otro, 12 studs de ancho)
for _, b in {
	{ "PasarelaVeletas", -82, -60, -6, 6 },
	{ "PasarelaRefineria", 60, 82, -6, 6 },
	{ "PasarelaLastre", -6, 6, 60, 82 },
	{ "PasarelaGondolas", -6, 6, -82, -60 },
} do
	table.insert(floors, { Id = b[1], Kind = "Rect", X0 = b[2], X1 = b[3], Z0 = b[4], Z1 = b[5], Bridge = true })
end

local function poly(cx: number, cz: number, r: number): { { number } }
	return { { cx - r, cz - r }, { cx + r, cz - r }, { cx + r, cz + r }, { cx - r, cz + r } }
end

local City = PlanetCity.new({
	Id = "AnclajeSiete",
	Name = "Anclaje Siete",
	Planet = "Miasma",
	KeyPrefix = "Miasma_",
	Rect = { X0 = -170, X1 = 170, Z0 = -170, Z1 = 170 },
	Blend = 2,
	Bank = 0,
	Floors = floors,
	Discs = DISCS,
	Void = { Depth = 80, Name = "El mar de niebla", Text = "🌫 ¡Casi caes a la niebla! Un cable de seguridad te sube a la pasarela. (Las barandillas están para algo.)" },
	Districts = {
		{ Id = "Muelle", Name = "Muelle de Vientos", Theme = "Puerto y hangares: la última base de la defensa", Icon = "🛬", Color = { 150, 200, 255 }, Poly = poly(0, 0, 80) },
		{ Id = "Veletas", Name = "Plaza de las Veletas", Theme = "Mercado y racionamiento", Icon = "🌬", Color = { 200, 230, 120 }, Poly = poly(-122, 0, 48) },
		{ Id = "Refineria", Name = "La Refinería", Theme = "El gas pesado que quiere el Dominio", Icon = "🏭", Color = { 230, 200, 90 }, Poly = poly(122, 0, 48) },
		{ Id = "Lastre", Name = "Barrio Lastre", Theme = "Talleres y contrabandistas, el más cerca de la niebla", Icon = "🔧", Color = { 170, 140, 220 }, Poly = poly(0, 122, 48) },
		{ Id = "Gondolas", Name = "Las Góndolas", Theme = "Casas colgadas de globos", Icon = "🎈", Color = { 240, 170, 200 }, Poly = poly(0, -122, 48) },
	},
	Buildings = {
		-- Muelle de Vientos (la plataforma en el centro)
		{ Id = "TorreControl", District = "Muelle", Kind = "Militar", Shape = "Box", Name = "Torre del Muelle", X = 40, Z = -36, W = 14, D = 14, Face = "W", Floors = 4,
			Style = "MiasmaCupula", Ground = "Lobby", Sign = "CONTROL DE VUELOS", Icon = "📡",
			Info = "📡 La torre del Muelle de Vientos. En la pizarra: «PROHIBIDO DESPEGAR SIN PERMISO DE VUELO — Comandante Andrés». Debajo, alguien ha escrito «¿y aterrizar?»." },
		{ Id = "Enfermeria", District = "Muelle", Kind = "Hospital", Shape = "Box", Name = "Enfermería del Muelle", X = -36, Z = -32, W = 22, D = 16, Face = "E", Floors = 2,
			Style = "MiasmaCupula", Ground = "Lobby", Sign = "ENFERMERÍA · AIRE LIMPIO", Icon = "🏥",
			Info = "🏥 La enfermería del Muelle: aquí se tratan las intoxicaciones. Dentro el aire está filtrado: respira." },
		{ Id = "HangarDefensa", District = "Muelle", Kind = "Militar", Shape = "Hangar", Name = "Hangar de la Defensa", X = 38, Z = 28, W = 24, D = 18, Face = "W", Height = 14, Icon = "✈",
			Info = "✈ El hangar de la Defensa: cazas remendados, pilotos de quince años y un cartel: «Cada nave cuenta»." },
		{ Id = "Bateria", District = "Muelle", Kind = "Militar", Shape = "Cannon", Name = "Batería antiaérea", X = -40, Z = 30, R = 6, Height = 9, Icon = "🎯" },
		-- Plaza de las Veletas
		{ Id = "GranVeleta", District = "Veletas", Kind = "Monumento", Shape = "Veleta", Name = "La Gran Veleta", X = -122, Z = 0, R = 5, Height = 46, Icon = "🌬",
			Info = "🌬 La Gran Veleta: la construyeron los del Anclaje Uno, hace trescientos años. Dicen que apunta siempre hacia el aire limpio. Hoy apunta hacia el bloqueo." },
		{ Id = "Racionamiento", District = "Veletas", Kind = "Tienda", Shape = "Box", Name = "Racionamiento de la Plaza", X = -146, Z = 0, W = 22, D = 16, Face = "E", Floors = 2,
			Style = "MiasmaCupula", Ground = "Shop", Sign = "RACIONAMIENTO", ShopId = "MiasmaRaciones", Icon = "🥫" },
		-- Barrio Lastre
		{ Id = "TallerFiltros", District = "Lastre", Kind = "Tienda", Shape = "Box", Name = "Taller de filtros de Lastre", X = 20, Z = 122, W = 24, D = 18, Face = "W", Floors = 2,
			Style = "MiasmaLastre", Ground = "Shop", Sign = "FILTROS · TALLER BRUMA", ShopId = "MiasmaFiltros", Icon = "😷",
			Info = "😷 El taller de filtros de la vieja Bruma: «Filtros nuevos, usados y de los que no preguntas». En la puerta, el tablón del oficio de filtrador." },
		{ Id = "Cantina", District = "Lastre", Kind = "Ocio", Shape = "Box", Name = "Cantina El Lastre", X = -20, Z = 128, W = 22, D = 16, Face = "E", Floors = 1,
			Style = "MiasmaLastre", Ground = "Lobby", Sign = "CANTINA EL LASTRE", Icon = "🍵",
			Info = "🍵 La cantina de los contrabandistas. Sirven caldo de musgo y «la última copa de aire»: aire limpio embotellado, para celebrar." },
		{ Id = "HangarMara", District = "Lastre", Kind = "Negocio", Shape = "Hangar", Name = "El hangar de Mara", X = 0, Z = 150, W = 20, D = 14, Face = "N", Height = 11, Icon = "🛩",
			Info = "🛩 Un hangar pequeño con un carguero viejo dentro, el «Último Respiro». En el morro, pintada a mano, una medusa de gas." },
		-- La Refinería
		{ Id = "TorreRefineria", District = "Refineria", Kind = "Fabrica", Shape = "Refineria", Name = "Torre de la Refinería", X = 130, Z = -8, R = 10, Height = 62, Icon = "🏭",
			Info = "🏭 La torre que saca el gas pesado de la niebla. Sus tubos bajan hasta perderse en el verde. Todo Miasma vive de esto. Y el Dominio también lo quiere." },
		{ Id = "OficinaRefineros", District = "Refineria", Kind = "Negocio", Shape = "Box", Name = "Oficina de los Refineros", X = 140, Z = -28, W = 18, D = 14, Face = "W", Floors = 2,
			Style = "MiasmaCupula", Ground = "Lobby", Sign = "REFINEROS · MAESTRO OLMO" },
		{ Id = "Deposito", District = "Refineria", Kind = "Fabrica", Shape = "GasTank", Name = "Depósito de gas pesado", X = 112, Z = 24, R = 8, Height = 18 },
		-- Las Góndolas (casas colgadas de globos)
		{ Id = "Gondola1", District = "Gondolas", Kind = "Vivienda", Shape = "Box", Name = "Góndola de los Garúa", X = -22, Z = -132, W = 16, D = 14, Face = "E", Floors = 1,
			Style = "MiasmaGondola", Ground = "House", Sign = "GARÚA", Balloon = true },
		{ Id = "Gondola2", District = "Gondolas", Kind = "Vivienda", Shape = "Box", Name = "Góndola de la Abuela Niebla", X = 22, Z = -132, W = 16, D = 14, Face = "W", Floors = 1,
			Style = "MiasmaGondola", Ground = "House", Sign = "NIEBLA", Balloon = true,
			Info = "🎈 La góndola de la Abuela Niebla. En la ventana, una radio vieja con la antena hacia abajo, hacia la niebla." },
	},
	Shelters = {
		Enfermeria = { Cool = 7, Name = "la enfermería del Muelle" },
		Cantina = { Cool = 4, Name = "la cantina El Lastre" },
		TallerFiltros = { Cool = 3, Name = "el taller de filtros" },
		Racionamiento = { Cool = 3, Name = "el racionamiento de la Plaza" },
		TorreControl = { Cool = 3, Name = "la torre del Muelle" },
	},
	Spots = {
		{ Id = "Panuelos", Name = "La barandilla de los pañuelos", X = 0, Z = -100, Icon = "🧣",
			Info = "🧣 Un pañuelo atado por cada nave que no volvió. Hay tantos que la barandilla parece una bandada. Los más nuevos aún están limpios." },
		{ Id = "BordeLastre", Name = "El borde de Lastre", X = -28, Z = 152, Icon = "🌫",
			Info = "🌫 Aquí la niebla sube casi hasta la pasarela. Huele a hierro y a fruta podrida. Cartel: «FILTRO OBLIGATORIO»." },
		{ Id = "Mirador", Name = "Mirador de la Refinería", X = 150, Z = 22, Icon = "👁",
			Info = "👁 Desde aquí se ven los picos saliendo de la niebla y, en lo alto, las luces de la flota del Dominio. Esperan." },
	},
	StorySpots = {
		{ Id = "Plataforma", Name = "Plataforma del Muelle de Vientos", X = 0, Z = 36 },
		{ Id = "Torre", Name = "Torre del Muelle", X = 30, Z = -36 },
		{ Id = "Enfermeria", Name = "Enfermería del Muelle", X = -24, Z = -32 },
		{ Id = "EnfermeriaDentro", Name = "Dentro de la enfermería", X = -36, Z = -32, Inside = "Miasma_Enfermeria" },
		{ Id = "Hangar", Name = "Hangar de la Defensa", X = 24, Z = 28 },
		{ Id = "Bateria", Name = "La batería antiaérea", X = -28, Z = 26 },
		{ Id = "Veleta", Name = "La Gran Veleta", X = -122, Z = -14 },
		{ Id = "Racionamiento", Name = "Racionamiento de la Plaza", X = -134, Z = 0 },
		{ Id = "PlazaEste", Name = "Plaza de las Veletas (puestos)", X = -100, Z = 20 },
		{ Id = "Lastre", Name = "Barrio Lastre", X = 0, Z = 104 },
		{ Id = "Taller", Name = "Taller de filtros de Lastre", X = 7, Z = 122 },
		{ Id = "Cantina", Name = "Cantina El Lastre", X = -8, Z = 128 },
		{ Id = "CantinaDentro", Name = "Dentro de la cantina", X = -20, Z = 128, Inside = "Miasma_Cantina" },
		{ Id = "HangarMara", Name = "El hangar de Mara", X = 0, Z = 138 },
		{ Id = "BordeLastre", Name = "El borde de Lastre", X = -28, Z = 150 },
		{ Id = "Refineria", Name = "La Refinería", X = 112, Z = -30 },
		{ Id = "Antena", Name = "La antena de la Refinería", X = 150, Z = 20 },
		{ Id = "Gondolas", Name = "Las Góndolas", X = 0, Z = -106 },
		{ Id = "GondolaGarua", Name = "Góndola de los Garúa", X = -11, Z = -132 },
		{ Id = "GondolaNiebla", Name = "Góndola de la Abuela Niebla", X = 11, Z = -132 },
		{ Id = "Panuelos", Name = "La barandilla de los pañuelos", X = 0, Z = -96 },
		-- Fuera (en los picos)
		{ Id = "TorreSilbadora", Name = "La Torre Silbadora", X = 520, Z = -220, Outside = true },
	},
	Gather = {
		{ Id = "Miasma_MusgoGondolas", Name = "Musgo filtro", X = -30, Z = -112, Item = "EsporaFiltro", Every = 40, Text = "🌿 +1 Espora de filtro (el musgo de los picos limpia el aire)" },
		{ Id = "Miasma_MusgoLastre", Name = "Musgo filtro", X = 26, Z = 146, Item = "EsporaFiltro", Every = 40, Text = "🌿 +1 Espora de filtro" },
		{ Id = "Miasma_PlataRayo", Name = "Plata de rayo", X = 150, Z = -4, Item = "PlataRayo", Every = 90, Text = "⚡ +1 Plata de rayo (la dejó el último rayo en el pararrayos)" },
	},
	Lamps = {
		{ X = 30, Z = 10 }, { X = -30, Z = 10 }, { X = 10, Z = -50 }, { X = -10, Z = 50 }, { X = 50, Z = -8 }, { X = -52, Z = 4 },
		{ X = -100, Z = -20 }, { X = -140, Z = 26 }, { X = 100, Z = 30 }, { X = 146, Z = 10 },
		{ X = 24, Z = 104 }, { X = -26, Z = 108 }, { X = 20, Z = -106 }, { X = -20, Z = -150 },
	},
	Benches = { { X = -104, Z = -24, Yaw = math.pi / 2 }, { X = -104, Z = 24, Yaw = math.pi / 2 }, { X = 14, Z = -100 } },
	Crowd = {
		{ Group = "Veletas", X = -102, Z = 6, FX = -122, FZ = 0 }, { Group = "Veletas", X = -108, Z = -10, FX = -122, FZ = 0 }, { Group = "Veletas", X = -132, Z = 14, FX = -146, FZ = 0 },
		{ Group = "Veletas", X = -132, Z = -12, FX = -146, FZ = 0, Work = "Carry" },
		{ Group = "Muelle", X = 20, Z = 14, FX = 38, FZ = 28 }, { Group = "Muelle", X = -18, Z = 42, FX = -40, FZ = 30 }, { Group = "Muelle", X = -22, Z = -50, FX = -36, FZ = -32 },
		{ Group = "Lastre", X = -4, Z = 110, FX = -20, FZ = 128 }, { Group = "Lastre", X = 4, Z = 134, FX = 0, FZ = 150 },
		{ Group = "Refineria", X = 104, Z = -16, FX = 130, FZ = -8, Work = "Carry" }, { Group = "Refineria", X = 116, Z = 6, FX = 112, FZ = 24 },
		{ Group = "Gondolas", X = -4, Z = -112, FX = 0, FZ = -96 }, { Group = "Gondolas", X = 8, Z = -146, FX = 22, FZ = -132 },
	},
	Areas = { { X0 = -150, X1 = -96, Z0 = -26, Z1 = 26 }, { X0 = -26, X1 = 26, Z0 = 98, Z1 = 112 } },
	Weather = function(clock: number): { Id: string, Name: string, Icon: string, Temp: number }
		local day = math.sin((clock - 8) / 24 * math.pi * 2)
		if clock >= 17 and clock < 17.5 then
			return { Id = "LluviaAcida", Name = "Lluvia ácida", Icon = "lluvia", Temp = math.floor(14 + 3 * day + 0.5) }
		end
		return { Id = "Niebla", Name = "Niebla tóxica abajo", Icon = "niebla", Temp = math.floor(14 + 4 * day + 0.5) }
	end,
	Arrival = { 0, 36 },
})

City.Palette = {
	Metal = rgb(150, 156, 170),
	Glass = rgb(150, 220, 210),
	Fog = rgb(150, 200, 70),
	Neon = rgb(140, 255, 220),
}

return City
