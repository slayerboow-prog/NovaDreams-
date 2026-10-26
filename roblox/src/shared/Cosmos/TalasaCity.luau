-- TalasaCity: el PLANO de «Las Balsas y el Faro», el barrio de Abisalia, la capital de TÁLASA
-- (docs/planetas/diseno-mundos.md §3.3.7; marco común: docs/planetas/marco-planetas.md; lo jugable:
-- docs/planetas/talasa-vertice.md). Cuentas puras con shared/Cosmos/PlanetCity.new.
--
-- Abisalia está SOBRE EL MAR: todo son cubiertas sobre pilotes y balsas flotantes a 14 studs del agua,
-- unidas por pasarelas. Entre cubierta y cubierta solo hay mar (Void: si te caes, los de las Balsas te
-- suben a la pasarela). Fuera del barrio NO hay tierra alrededor (como en los demás planetas): el mar de
-- verdad llega hasta el horizonte, y por la escalerilla del final del Muelle se baja a bucear.
--
--   Plataforma de llegada (0, 0) · Plaza de las Pecas (sur) con la Fuente de las Perlas
--   Faro de Mareas (este: el Consejo) · Estación Meridiana (norte: el laboratorio de los científicos)
--   Las Balsas (oeste: refugiados de abajo) · Jardín de algas y Mercado del Arrecife (cerrado)
--   Muelle flotante (sureste) con el taller de submarinos y la escalerilla de buceo
--
-- Coordenadas LOCALES (X = este, Z = sur), studs desde el centro de la plataforma. Todas las claves
-- empiezan por «Talasa_» (nunca las de Valmar).

local PlanetCity = require(script.Parent.PlanetCity)

local function deck(id: string, x0: number, x1: number, z0: number, z1: number, kind: string?): { [string]: any }
	return { Id = id, Kind = "Rect", X0 = x0, X1 = x1, Z0 = z0, Z1 = z1, Deck = kind or "Cubierta" }
end

local City = PlanetCity.new({
	Id = "Abisalia",
	Name = "Abisalia · Las Balsas y el Faro",
	Planet = "Talasa",
	KeyPrefix = "Talasa_",
	Rect = { X0 = -160, X1 = 160, Z0 = -150, Z1 = 150 },
	Blend = 40,
	Arrival = { 0, 30 },
	-- Lo que no es cubierta es mar
	Void = { Depth = 40, Name = "El mar", Text = "🌊 ¡Al agua! Los de las Balsas te suben a la pasarela de un tirón." },
	Floors = {
		{ Id = "CubiertaPlataforma", Kind = "Disc", X = 0, Z = 0, R = 48, Deck = "Plataforma" },
		deck("PaseoSur", -9, 9, 40, 56, "Pasarela"),
		deck("PlazaPecas", -55, 55, 52, 118, "Plaza"),
		deck("PaseoNorte", -9, 9, -70, -40, "Pasarela"),
		deck("CubiertaEstacion", -60, 60, -140, -66, "Laboratorio"),
		{ Id = "CubiertaFaro", Kind = "Disc", X = 118, Z = 20, R = 34, Deck = "Faro" },
		deck("PaseoFaro", 40, 92, 12, 30, "Pasarela"),
		deck("BalsaA", -150, -96, 30, 80, "Balsa"),
		deck("BalsaB", -150, -96, 92, 140, "Balsa"),
		deck("BalsaC", -150, -100, -60, -10, "Balsa"),
		deck("PaseoBalsas", -100, -54, 72, 88, "Pasarela"),
		deck("PuenteBalsasAB", -130, -116, 78, 94, "Pasarela"),
		deck("PuenteBalsasAC", -130, -116, -12, 32, "Pasarela"),
		deck("PaseoJardin", 54, 72, 74, 90, "Pasarela"),
		deck("Jardin", 70, 112, 60, 100, "Jardin"),
		deck("PaseoJardinFaro", 98, 112, 48, 62, "Pasarela"),
		deck("PaseoMuelle", 38, 58, 116, 132, "Pasarela"),
		deck("Muelle", 54, 160, 120, 150, "Muelle"),
	},
	Districts = {
		{ Id = "Faro", Name = "Faro de Mareas", Theme = "El Consejo de Mareas", Icon = "🗼", Color = Color3.fromRGB(120, 220, 230), Poly = { { 36, -20 }, { 160, -20 }, { 160, 62 }, { 36, 62 } } },
		{ Id = "Estacion", Name = "Estación Meridiana", Theme = "Laboratorio de los científicos", Icon = "🔬", Color = Color3.fromRGB(230, 240, 245), Poly = { { -70, -150 }, { 70, -150 }, { 70, -38 }, { -70, -38 } } },
		{ Id = "Balsas", Name = "Las Balsas", Theme = "Refugiados de abajo", Icon = "🛶", Color = Color3.fromRGB(200, 160, 110), Poly = { { -160, -70 }, { -56, -70 }, { -56, 150 }, { -160, 150 } } },
		{ Id = "Muelle", Name = "Muelle flotante", Theme = "Submarinos y buceo", Icon = "⚓", Color = Color3.fromRGB(80, 140, 200), Poly = { { 36, 104 }, { 160, 104 }, { 160, 150 }, { 36, 150 } } },
		{ Id = "Plaza", Name = "Plaza de las Pecas", Theme = "El centro", Icon = "✨", Color = Color3.fromRGB(110, 230, 210), Poly = { { -56, -38 }, { 160, -38 }, { 160, 150 }, { -56, 150 } } },
	},
	Buildings = {
		-- Norte: la Estación Meridiana con su antena y la boca del Tubo
		{ Id = "Estacion", District = "Estacion", Kind = "Laboratorio", Shape = "Box", Name = "Estación Meridiana", X = 0, Z = -110, W = 44, D = 30, Face = "S", Floors = 2, Style = "TalasaLab", Ground = "Lobby", Sign = "ESTACIÓN MERIDIANA", Icon = "🔬",
			Info = "La Estación Meridiana: el laboratorio de los científicos de Abisalia. Dentro, la cámara de presión está siempre abierta." },
		{ Id = "Antena", District = "Estacion", Kind = "Antena", Shape = "Antena", Name = "Antena del sónar", X = 45, Z = -122, R = 6, Height = 46,
			Info = "El sónar de la Estación. Escucha el fondo día y noche. Últimamente solo oye crujidos." },
		{ Id = "Tubo", District = "Estacion", Kind = "Metro", Shape = "Tubo", Name = "El Tubo (estación Meridiana)", X = -44, Z = -118, R = 9, Height = 14, Icon = "🚇",
			Info = "El Tubo, el metro de cristal entre barrios. El tramo a la Cúpula Honda está cerrado: «Cuarentena»." },
		-- Este: el Faro de Mareas (el Consejo) y su compuerta
		{ Id = "Faro", District = "Faro", Kind = "Faro", Shape = "Faro", Name = "Faro de Mareas", X = 118, Z = 20, R = 13, Height = 78, Icon = "🗼",
			Info = "El Faro de Mareas, la torre del Consejo. Su luz avisa de la marea a todo Abisalia. Ahora, también de la cuarentena." },
		{ Id = "CompuertaFaro", District = "Faro", Kind = "Compuerta", Shape = "Box", Name = "Compuerta del Faro", X = 96, Z = 22, W = 14, D = 12, Face = "W", Floors = 1, Style = "TalasaCompuerta", Ground = "Lobby", Sign = "COMPUERTA 1",
			Info = "Una compuerta estanca: dentro se para la tormenta y la presión baja enseguida." },
		-- Sur: la Plaza de las Pecas
		{ Id = "Enfermeria", District = "Plaza", Kind = "Enfermeria", Shape = "Box", Name = "Enfermería de las Pecas", X = -36, Z = 100, W = 26, D = 20, Face = "E", Floors = 2, Style = "TalasaBlanco", Ground = "Lobby", Sign = "ENFERMERÍA", Icon = "⛑",
			Info = "La enfermería, con su cámara de presión. Curan el mal de presión de los buceadores y a quien llega de abajo." },
		{ Id = "Burbuja", District = "Plaza", Kind = "Tienda", Shape = "Box", Name = "La Burbuja, equipo de buceo", X = 36, Z = 104, W = 24, D = 18, Face = "W", Floors = 1, Style = "TalasaBlanco", Ground = "Shop", ShopId = "TalasaBurbuja", Sign = "LA BURBUJA", Icon = "🤿",
			Info = "Equipo de buceo de alta gama y cargas de oxígeno. «Si no lo llevas, no bajes», dice el cartel." },
		{ Id = "Mercado", District = "Plaza", Kind = "Mercado", Shape = "Domo", Name = "Mercado del Arrecife (cerrado)", X = 96, Z = 86, R = 12, Height = 14,
			Info = "El Mercado del Arrecife, medio hundido. Cerrado: el coral negro ha trepado por sus columnas." },
		-- Oeste: Las Balsas
		{ Id = "CompuertaBalsas", District = "Balsas", Kind = "Compuerta", Shape = "Box", Name = "Compuerta de las Balsas", X = -140, Z = 66, W = 14, D = 12, Face = "E", Floors = 1, Style = "TalasaCompuerta", Ground = "Lobby", Sign = "COMPUERTA 4",
			Info = "La compuerta de las Balsas: la única de la zona barata. Siempre llena." },
		{ Id = "BalsaFamilia", District = "Balsas", Kind = "Balsa", Shape = "Balsa", Name = "Balsa de los Brea", X = -134, Z = 44, R = 8, Height = 10 },
		{ Id = "BalsaRemos", District = "Balsas", Kind = "Balsa", Shape = "Balsa", Name = "Balsa de los remendones", X = -110, Z = 58, R = 7, Height = 9 },
		{ Id = "BalsaFarol", District = "Balsas", Kind = "Balsa", Shape = "Balsa", Name = "Balsa del farolero", X = -134, Z = 118, R = 8, Height = 10 },
		{ Id = "CasaBruma", District = "Balsas", Kind = "Balsa", Shape = "Balsa", Name = "La balsa de Bruma", X = -126, Z = -40, R = 9, Height = 11,
			Info = "La balsa de Bruma, la buceadora. En la puerta, una perla atada con hilo por cada vecino desaparecido." },
		-- Sureste: el Muelle flotante
		{ Id = "Hangar", District = "Muelle", Kind = "Astillero", Shape = "Hangar", Name = "Taller de submarinos", X = 110, Z = 135, W = 30, D = 22, Face = "N", Height = 16, Icon = "⚓",
			Info = "El taller de submarinos del Muelle. Hay cola: todo el mundo quiere un barco para irse." },
	},
	Shelters = {
		Estacion = { Cool = 8, Name = "la cámara de presión de la Estación Meridiana" },
		CompuertaFaro = { Cool = 9, Name = "la Compuerta del Faro" },
		Enfermeria = { Cool = 10, Name = "la enfermería de las Pecas" },
		CompuertaBalsas = { Cool = 8, Name = "la Compuerta de las Balsas" },
		Burbuja = { Cool = 5, Name = "La Burbuja" },
	},
	-- Los sitios de la historia (Talasa_<Id> en LifeStory/Locations)
	StorySpots = {
		{ Id = "Plataforma", Name = "Plataforma de Abisalia", X = 0, Z = 30 },
		{ Id = "Plaza", Name = "Plaza de las Pecas", X = 0, Z = 64 },
		{ Id = "Fuente", Name = "Fuente de las Perlas", X = 14, Z = 76 },
		{ Id = "Faro", Name = "Faro de Mareas", X = 118, Z = -6 },
		{ Id = "CompuertaFaro", Name = "Compuerta del Faro (dentro)", X = 99, Z = 22, Inside = true },
		{ Id = "Estacion", Name = "Puerta de la Estación Meridiana", X = 0, Z = -88 },
		{ Id = "EstacionDentro", Name = "Laboratorio de la Estación Meridiana", X = 0, Z = -104, Inside = true },
		{ Id = "Balsas", Name = "Las Balsas", X = -116, Z = 102 },
		{ Id = "CasaBruma", Name = "La balsa de Bruma", X = -108, Z = -40 },
		{ Id = "Enfermeria", Name = "Puerta de la enfermería", X = -20, Z = 100 },
		{ Id = "Jardin", Name = "Jardín de algas", X = 78, Z = 66 },
		{ Id = "Muelle", Name = "Muelle flotante", X = 80, Z = 132 },
		{ Id = "Escalerilla", Name = "Escalerilla de buceo", X = 152, Z = 140 },
		{ Id = "Arrecife", Name = "Praderas de Luz (zona de buceo)", X = 205, Z = 150, Outside = true, Radius = 30 },
	},
	Spots = {
		{ Id = "FuentePerlas", Name = "Fuente de las Perlas", X = 0, Z = 86, Icon = "✨",
			Info = "La Fuente de las Perlas. Se tira una perla al mar por cada desaparecido. Este año, el fondo de la fuente ya no se ve." },
		{ Id = "TablaMareas", Name = "Tabla de mareas", X = 60, Z = 22,
			Info = "La tabla de mareas del Consejo: «Marea alta cada 12 minutos. Tormenta eléctrica: a cubierto en una compuerta»." },
		{ Id = "Desaparecidos", Name = "Carteles de desaparecidos", X = -50, Z = 64,
			Info = "Cientos de fotos clavadas en el poste. Gente de la Cúpula Honda. Una dice: «Elio Ferrán, 20 años. Laboratorio C»." },
	},
	-- Recoger el material del planeta
	Gather = {
		{ Id = "Talasa_AlgasJardin", Name = "Algas de luz", X = 90, Z = 66, Item = "Talasa_AlgaLuz", Every = 40 },
		{ Id = "Talasa_AlgasBalsas", Name = "Algas de luz", X = -100, Z = 136, Item = "Talasa_AlgaLuz", Every = 40 },
		{ Id = "Talasa_NacarMuelle", Name = "Nácar en los pilotes", X = 140, Z = 124, Item = "Talasa_Nacar", Every = 75, Action = "Raspar" },
	},
	Lamps = {
		{ X = -20, Z = 56 }, { X = 20, Z = 56 }, { X = -50, Z = 70 }, { X = 50, Z = 70 }, { X = -20, Z = 114 }, { X = 20, Z = 114 },
		{ X = 6, Z = -60 }, { X = -6, Z = -44 }, { X = 30, Z = -72 }, { X = -30, Z = -72 },
		{ X = 60, Z = 26 }, { X = 84, Z = 14 }, { X = 140, Z = 44 },
		{ X = -120, Z = 34 }, { X = -100, Z = 84 }, { X = -146, Z = 96 }, { X = -104, Z = -14 },
		{ X = 74, Z = 146 }, { X = 140, Z = 146 }, { X = 108, Z = 58 },
	},
	Benches = { { X = -24, Z = 78, Yaw = math.pi / 2 }, { X = 24, Z = 78, Yaw = -math.pi / 2 }, { X = 70, Z = 96, Yaw = 0 } },
	Crowd = {
		{ Group = "Plaza", X = -10, Z = 70, FX = 0, FZ = 86 }, { Group = "Plaza", X = 12, Z = 94, FX = 0, FZ = 86 },
		{ Group = "Plaza", X = -30, Z = 62, FX = -50, FZ = 64 }, { Group = "Plaza", X = 26, Z = 66, FX = 26, FZ = 80, Sit = true },
		{ Group = "Balsas", X = -124, Z = 56, FX = -134, FZ = 44, Work = "Fish" }, { Group = "Balsas", X = -112, Z = 104, FX = -134, FZ = 118 },
		{ Group = "Balsas", X = -140, Z = 132, FX = -134, FZ = 118, Sit = true }, { Group = "Balsas", X = -112, Z = -26, FX = -126, FZ = -40 },
		{ Group = "Faro", X = 96, Z = -2, FX = 118, FZ = 20 }, { Group = "Faro", X = 134, Z = 46, FX = 118, FZ = 20 },
		{ Group = "Estacion", X = 24, Z = -84, FX = 0, FZ = -95 }, { Group = "Estacion", X = -28, Z = -96, FX = -44, FZ = -118 },
		{ Group = "Muelle", X = 70, Z = 140, FX = 110, FZ = 135 }, { Group = "Muelle", X = 140, Z = 128, FX = 160, FZ = 140, Work = "Fish" },
	},
	Areas = { { X0 = -50, X1 = 50, Z0 = 56, Z1 = 116 } },
	-- La marea y las tormentas eléctricas (lo que enseña el tiempo del barrio)
	Weather = function(clock: number): { Id: string, Name: string, Icon: string, Temp: number }
		local h = clock % 24
		if (h >= 14 and h < 16) or (h >= 2 and h < 4) then
			return { Id = "Tormenta", Name = "Tormenta eléctrica", Icon = "⛈", Temp = 19 }
		end
		local tide = math.floor(h * 2) % 2 == 0
		return { Id = if tide then "MareaAlta" else "MareaBaja", Name = if tide then "Marea alta" else "Marea baja", Icon = "🌊", Temp = 22 }
	end,
})

-- (océano) Fuera del barrio NO se levanta tierra: el fondo del mar sigue igual hasta la orilla de las
-- cubiertas (PlanetCity rodea los barrios de una bajada de tierra; aquí sería una isla que no existe)
local baseShape = City.shape
function City.shape(lx: number, lz: number, h: number, base: number): number
	if City.rectDistance(lx, lz) > City.Bank then
		return h
	end
	return baseShape(lx, lz, h, base)
end

-- La tormenta eléctrica (las horas de juego en que cae): para la desventaja y el sonido
function City.storm(clock: number): boolean
	local h = clock % 24
	return (h >= 14 and h < 16) or (h >= 2 and h < 4)
end

return City
