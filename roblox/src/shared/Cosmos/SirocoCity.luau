-- SirocoCity: el PLANO del barrio de Puerto Calcina, la ciudad de Siroco (docs/planetas/diseno-mundos.md
-- §3.2.7; marco común: docs/planetas/marco-planetas.md). Datos para shared/Cosmos/PlanetCity.
--
-- Puerto Calcina está encajada en el fondo de un cañón rojo: casas de adobe excavadas en la roca,
-- remendadas con chapa, toldos de colores y antenas. Por el medio pasa LA RECTA, la calle-circuito de las
-- carreras, que cruza el Arco del Campeón. Este barrio es el corazón de la ciudad:
--
--                  (−Z, norte)  🛬 MUELLE DE VELAS (la plataforma, donde llegan los veleros de arena)
--        ZOCO DEL VIENTO            │ LA RECTA │            LOS BOXES
--   (el aguador, la cantina,        │          │   (el taller de Rafa, el box de la Escudería
--    la Tía Cifra, los Túneles)     │ ARCO DEL │    Hierro, el Abuelo Tornillo)
--                                   │ CAMPEÓN  │
--                  (+Z, sur)    POZO HONDO (la fuente, la casa de Luz, casas en la roca)
--   Las paredes del cañón cierran el barrio por el este y el oeste (el terreno: shared/Cosmos/Siroco).
--
-- Coordenadas LOCALES de Siroco (studs desde su Origin). Claves «Siroco_…».

local PlanetCity = require(script.Parent.PlanetCity)

local City = PlanetCity.new({
	Id = "PuertoCalcina",
	Name = "Puerto Calcina",
	Planet = "Siroco",
	KeyPrefix = "Siroco_",
	Rect = { X0 = -130, X1 = 130, Z0 = -180, Z1 = 180 },
	Blend = 46,
	Bank = 4,
	OpenGround = true,
	Floors = {
		{ Id = "LaRecta", Kind = "Rect", X0 = -12, X1 = 12, Z0 = -110, Z1 = 178, Road = true },
		{ Id = "PlazaArco", Kind = "Rect", X0 = -34, X1 = 34, Z0 = 18, Z1 = 62, Plaza = true },
	},
	Pits = {
		{ Id = "PozoSilencio", Kind = "Disc", X = 84, Z = 138, R = 4, Depth = 40, Name = "El Pozo del Silencio", Text = "🕳 ¡Casi caes al Pozo del Silencio! Alguien te agarra del brazo. Abajo, muy abajo, se oye agua." },
	},
	Districts = {
		{ Id = "Muelle", Name = "Muelle de Velas", Theme = "Donde atracan los veleros de arena", Icon = "⛵", Color = { 230, 200, 150 }, Poly = { { -130, -180 }, { 130, -180 }, { 130, -110 }, { -130, -110 } } },
		{ Id = "Zoco", Name = "Zoco del Viento", Theme = "Agua, piezas, apuestas y deudas", Icon = "🏺", Color = { 230, 150, 80 }, Poly = { { -130, -110 }, { -14, -110 }, { -14, 100 }, { -130, 100 } } },
		{ Id = "Recta", Name = "La Recta", Theme = "La calle-circuito de las carreras", Icon = "🏁", Color = { 250, 240, 230 }, Poly = { { -14, -110 }, { 14, -110 }, { 14, 180 }, { -14, 180 } } },
		{ Id = "Boxes", Name = "Los Boxes", Theme = "Los garajes de los equipos", Icon = "🔧", Color = { 120, 180, 190 }, Poly = { { 14, -110 }, { 130, -110 }, { 130, 100 }, { 14, 100 } } },
		{ Id = "PozoHondo", Name = "Pozo Hondo", Theme = "El barrio pobre del fondo del cañón", Icon = "💧", Color = { 150, 120, 100 }, Poly = { { -130, 100 }, { -14, 100 }, { -14, 180 }, { -130, 180 }, { -130, 100 } } },
		{ Id = "PozoHondoEste", Name = "Pozo Hondo", Theme = "El barrio pobre del fondo del cañón", Icon = "💧", Color = { 150, 120, 100 }, Poly = { { 14, 100 }, { 130, 100 }, { 130, 180 }, { 14, 180 } } },
	},
	Buildings = {
		-- Zoco del Viento (las fachadas miran a La Recta: al este)
		{ Id = "Aguador", District = "Zoco", Kind = "Tienda", Shape = "Box", Name = "El aguador del Zoco", X = -50, Z = -60, W = 22, D = 16, Face = "E", Floors = 2,
			Style = "SirocoAdobe", Ground = "Shop", Sign = "AGUA · CON LICENCIA DE HIERRO", ShopId = "SirocoAgua", Icon = "💧",
			Info = "💧 El aguador del Zoco: el agua más cara de la galaxia. Precio de hoy escrito con tiza: «15 €». Ayer era 12." },
		{ Id = "Cantina", District = "Zoco", Kind = "Tienda", Shape = "Box", Name = "Cantina de La Recta", X = -52, Z = 0, W = 26, D = 18, Face = "E", Floors = 2,
			Style = "SirocoAdobe", Ground = "Shop", Sign = "CANTINA DE LA RECTA", ShopId = "SirocoCantina", Icon = "🍹",
			Info = "🍹 La cantina de La Recta: zumo de cactus, tortas de dátil y pantallas con las carreras de anoche. Dentro hace fresco." },
		{ Id = "TiaCifra", District = "Zoco", Kind = "Negocio", Shape = "Box", Name = "Apuestas de la Tía Cifra", X = -50, Z = 66, W = 20, D = 16, Face = "E", Floors = 1,
			Style = "SirocoChatarra", Ground = "Lobby", Sign = "APUESTAS · TÍA CIFRA", Icon = "🎲",
			Info = "🎲 La casa de apuestas de la Tía Cifra. En la pizarra, las carreras de esta noche y una frase: «La casa siempre gana. Casi siempre»." },
		{ Id = "Tuneles", District = "Zoco", Kind = "Refugio", Shape = "Box", Name = "Entrada a los Túneles", X = -104, Z = -20, W = 24, D = 18, Face = "E", Floors = 1,
			Style = "SirocoAdobe", Ground = "Lobby", Sign = "LOS TÚNELES · HORA ROJA: ADENTRO", Icon = "🛡",
			Info = "🛡 La entrada a los Túneles: la ciudad de debajo. A mediodía, en la hora roja, todo Calcina baja aquí. Se está fresco." },
		{ Id = "Puesto1", District = "Zoco", Kind = "Tienda", Shape = "Puesto", Name = "Puesto de piezas", X = -80, Z = -36, W = 8, D = 6, Face = "E" },
		{ Id = "CasaRocaO", District = "Zoco", Kind = "Vivienda", Shape = "CasaRoca", Name = "Casas de las Gradas", X = -118, Z = 66, W = 22, D = 12, Face = "E", Height = 26 },
		-- Los Boxes (las fachadas miran a La Recta: al oeste)
		{ Id = "TallerRafa", District = "Boxes", Kind = "Negocio", Shape = "Box", Name = "El taller de Rafa Quiroga", X = 52, Z = -50, W = 28, D = 20, Face = "W", Floors = 1,
			Style = "SirocoChatarra", Ground = "Garage", Sign = "TALLER QUIROGA · SE ARREGLA DE TODO", Icon = "🔧",
			Info = "🔧 El taller de Rafa «el Zorro» Quiroga. En la pared, un póster viejo: él, de joven, levantando la copa de la Gran Vuelta. Alguien le ha pintado bigote." },
		{ Id = "BoxHierro", District = "Boxes", Kind = "Negocio", Shape = "Box", Name = "Box de la Escudería Hierro", X = 56, Z = 20, W = 30, D = 22, Face = "W", Floors = 2,
			Style = "SirocoChatarra", Ground = "Closed", Sign = "ESCUDERÍA HIERRO · PRIVADO", Icon = "🏎",
			Info = "🏎 El box de la Escudería Hierro: cerrado a cal y canto. Por la rendija se ve un deslizador blindado nuevo. Brilla demasiado para este planeta." },
		{ Id = "Tornillo", District = "Boxes", Kind = "Negocio", Shape = "Box", Name = "Taller del Abuelo Tornillo", X = 52, Z = 80, W = 22, D = 16, Face = "W", Floors = 1,
			Style = "SirocoChatarra", Ground = "Garage", Sign = "TORNILLO · MOTORES DESDE SIEMPRE" },
		{ Id = "CasaRocaE", District = "Boxes", Kind = "Vivienda", Shape = "CasaRoca", Name = "Casas de las Gradas", X = 118, Z = -6, W = 26, D = 12, Face = "W", Height = 28 },
		-- Pozo Hondo (el fondo del cañón)
		{ Id = "CasaLuz", District = "PozoHondo", Kind = "Vivienda", Shape = "Box", Name = "Casa de Luz", X = -60, Z = 132, W = 18, D = 14, Face = "E", Floors = 1,
			Style = "SirocoAdobe", Ground = "House", Sign = "LUZ · POZO HONDO", Icon = "🏠",
			Info = "🏠 La casa de Luz, la que manda en Pozo Hondo. En la puerta, una lista de familias y cuánta agua le toca a cada una. La lista es larga. El agua, poca." },
		{ Id = "Fuente", District = "PozoHondo", Kind = "Agua", Shape = "Fuente", Name = "La fuente de Pozo Hondo", X = -30, Z = 140, R = 6, Height = 4, Icon = "⛲",
			Info = "⛲ La fuente de Pozo Hondo. Gotea. La cola de bidones llega hasta la esquina." },
		{ Id = "CasaRocaS", District = "PozoHondo", Kind = "Vivienda", Shape = "CasaRoca", Name = "Casas de la roca", X = -118, Z = 140, W = 24, D = 12, Face = "E", Height = 22 },
		{ Id = "CasaRocaSE", District = "PozoHondoEste", Kind = "Vivienda", Shape = "CasaRoca", Name = "Casas de la roca", X = 118, Z = 118, W = 24, D = 12, Face = "W", Height = 24 },
	},
	Shelters = {
		Tuneles = { Cool = 7, Name = "los Túneles" },
		Cantina = { Cool = 4, Name = "la cantina de La Recta" },
		Aguador = { Cool = 3, Name = "el aguador del Zoco" },
		TallerRafa = { Cool = 3, Name = "el taller de Rafa" },
		CasaLuz = { Cool = 3, Name = "la casa de Luz" },
		TiaCifra = { Cool = 2, Name = "las apuestas de la Tía Cifra" },
	},
	Spots = {
		{ Id = "Arco", Name = "El Arco del Campeón", X = 0, Z = 40, Icon = "🏆", Y = 0.9,
			Info = "🏆 El Arco del Campeón: los nombres de todos los ganadores de la Gran Vuelta, tallados en la piedra. Uno está tachado con una raya furiosa: «R. QUIROGA»." },
		{ Id = "Recta", Name = "La Recta", X = 0, Z = 120, Icon = "🏁",
			Info = "🏁 La Recta: de día, una calle; de noche, el circuito. Las marcas de las frenadas de mil carreras." },
		{ Id = "Muelle", Name = "Muelle de Velas", X = 60, Z = -150, Icon = "⛵",
			Info = "⛵ El Muelle de Velas: aquí atracaban los barcos cuando Siroco tenía mar. Ahora atracan los veleros de arena." },
	},
	StorySpots = {
		{ Id = "Plataforma", Name = "Plataforma del Muelle de Velas", X = 34, Z = -140 },
		{ Id = "Muelle", Name = "Muelle de Velas", X = 60, Z = -150 },
		{ Id = "Aguador", Name = "El aguador del Zoco", X = -38, Z = -60 },
		{ Id = "Cantina", Name = "Cantina de La Recta", X = -36, Z = 0 },
		{ Id = "CantinaDentro", Name = "Dentro de la cantina", X = -52, Z = 0, Inside = "Siroco_Cantina" },
		{ Id = "TiaCifra", Name = "Apuestas de la Tía Cifra", X = -36, Z = 66 },
		{ Id = "Tuneles", Name = "Entrada a los Túneles", X = -90, Z = -20 },
		{ Id = "TunelesDentro", Name = "Dentro de los Túneles", X = -104, Z = -20, Inside = "Siroco_Tuneles" },
		{ Id = "Zoco", Name = "Zoco del Viento", X = -70, Z = -30 },
		{ Id = "Taller", Name = "El taller de Rafa", X = 38, Z = -50 },
		{ Id = "TallerDentro", Name = "Dentro del taller de Rafa", X = 52, Z = -50, Inside = "Siroco_TallerRafa" },
		{ Id = "BoxHierro", Name = "Box de la Escudería Hierro", X = 38, Z = 20 },
		{ Id = "Tornillo", Name = "Taller del Abuelo Tornillo", X = 38, Z = 80 },
		{ Id = "Arco", Name = "El Arco del Campeón", X = 0, Z = 30 },
		{ Id = "PlazaArco", Name = "La plaza del Arco", X = 24, Z = 50 },
		{ Id = "Recta", Name = "La Recta", X = 0, Z = 120 },
		{ Id = "Fuente", Name = "La fuente de Pozo Hondo", X = -30, Z = 126 },
		{ Id = "CasaLuz", Name = "La casa de Luz", X = -48, Z = 132 },
		{ Id = "PozoSilencio", Name = "El Pozo del Silencio", X = 84, Z = 126 },
		-- Fuera (en el desierto)
		{ Id = "Cementerio", Name = "El Cementerio de Deslizadores", X = 430, Z = -300, Outside = true },
		{ Id = "Esfinge", Name = "La Esfinge Ciega", X = -600, Z = 500, Outside = true },
	},
	Gather = {
		{ Id = "Siroco_CactusZoco", Name = "Cactus de agua", X = -86, Z = 92, Item = "AguaFresca", Every = 75, Action = "Cortar con cuidado", Text = "🌵 Lo cortas por donde dice Nina: +1 💧 agua fresca" },
		{ Id = "Siroco_CactusBoxes", Name = "Cactus de agua", X = 92, Z = 54, Item = "AguaFresca", Every = 75, Action = "Cortar con cuidado", Text = "🌵 +1 💧 agua fresca (el cactus volverá a hincharse)" },
		{ Id = "Siroco_SalRocio", Name = "Sal de rocío", X = 100, Z = 160, Item = "SalRocio", Every = 50, Text = "🧂 +1 sal de rocío (de noche recoge la humedad del aire)" },
		{ Id = "Siroco_Chatarra", Name = "Chatarra", X = 92, Z = -86, Item = "ChatarraAntigua", Every = 120, Action = "Rebuscar", Text = "⚙ +1 chatarra antigua (una pieza de la Ciudad Primera, entre tornillos de hoy)" },
	},
	Lamps = {
		{ X = -18, Z = -90 }, { X = 18, Z = -70 }, { X = -18, Z = -30 }, { X = 18, Z = -10 }, { X = -18, Z = 70 }, { X = 18, Z = 90 },
		{ X = -18, Z = 130 }, { X = 18, Z = 150 }, { X = -36, Z = 16 }, { X = 36, Z = 64 }, { X = -76, Z = -60 }, { X = 80, Z = 0 },
		{ X = -86, Z = 120 }, { X = 90, Z = 140 },
	},
	Benches = { { X = -26, Z = 30, Yaw = -math.pi / 2 }, { X = 26, Z = 30, Yaw = math.pi / 2 }, { X = -20, Z = 150, Yaw = -math.pi / 2 } },
	Crowd = {
		{ Group = "Zoco", X = -74, Z = -46, FX = -80, FZ = -36 }, { Group = "Zoco", X = -66, Z = -30, FX = -80, FZ = -36 }, { Group = "Zoco", X = -36, Z = -66, FX = -50, FZ = -60, Work = "Carry" },
		{ Group = "Zoco", X = -34, Z = 8, FX = -52, FZ = 0 }, { Group = "Zoco", X = -32, Z = 72, FX = -50, FZ = 66 },
		{ Group = "Recta", X = 22, Z = 34, FX = 0, FZ = 40 }, { Group = "Recta", X = -22, Z = 54, FX = 0, FZ = 40 }, { Group = "Recta", X = 20, Z = 110, FX = 0, FZ = 110 },
		{ Group = "Boxes", X = 34, Z = -40, FX = 52, FZ = -50, Work = "Carry" }, { Group = "Boxes", X = 32, Z = 86, FX = 52, FZ = 80 },
		{ Group = "PozoHondo", X = -30, Z = 116, FX = -30, FZ = 140 }, { Group = "PozoHondo", X = -22, Z = 126, FX = -30, FZ = 140 }, { Group = "PozoHondo", X = -40, Z = 120, FX = -30, FZ = 140 },
		{ Group = "Muelle", X = 50, Z = -130, FX = 60, FZ = -150 },
	},
	Areas = { { X0 = -34, X1 = 34, Z0 = 18, Z1 = 62 }, { X0 = -100, X1 = -60, Z0 = -50, Z1 = -20 } },
	Weather = function(clock: number): { Id: string, Name: string, Icon: string, Temp: number }
		local day = math.sin((clock - 8) / 24 * math.pi * 2)
		if clock >= 13 and clock < 14 then
			return { Id = "HoraRoja", Name = "Hora roja", Icon = "sol", Temp = 58 }
		elseif (clock >= 16 and clock < 16.5) or (clock >= 4 and clock < 4.5) then
			return { Id = "Tormenta", Name = "Tormenta de arena", Icon = "tormenta", Temp = math.floor(38 + 6 * day + 0.5) }
		end
		local night = clock < 6.5 or clock >= 20
		return { Id = if night then "Noche" else "Sol", Name = if night then "Noche fresca" else "Sol rojo", Icon = if night then "luna" else "sol", Temp = math.floor(34 + 12 * day + 0.5) }
	end,
	Arrival = { 34, -140 },
})

return City
