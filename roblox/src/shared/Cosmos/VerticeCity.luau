-- VerticeCity: el PLANO de la Plaza del Primer Cliente, el corazón de DISTRITO CERO, la capital de
-- VÉRTICE (docs/planetas/diseno-mundos.md §3.7.7; marco común: docs/planetas/marco-planetas.md; lo
-- jugable: docs/planetas/talasa-vertice.md). Cuentas puras con shared/Cosmos/PlanetCity.new.
--
-- Vértice es una ciudad entera por niveles. El barrio está en el NIVEL MEDIO: plazas y pasarelas de
-- cristal y metal colgadas a 90 studs sobre el Nivel Bajo. Entre cubierta y cubierta solo hay hueco
-- (Void: si te caes, un dron de MegaVerso te sube a la pasarela). Abajo, la ciudad de siempre sigue hasta
-- el horizonte (sin colinas: el kit pone las torres de alrededor).
--
--   Plataforma de llegada (0, 0) · Plaza del Primer Cliente (sur) con la estatua del señor sonriente
--   Distrito Oficinas (norte): la Torre de Ventas de MegaVerso y el Museo de la Luz
--   Avenida Rebajas (oeste): el hipermercado y la tienda de ofertas · El Rastro (noroeste): el ascensor
--   al mercado de abajo y su clínica gratis · Estación del mag-lev (este) · Barrio Plantilla (sureste)
--
-- Coordenadas LOCALES (X = este, Z = sur). Todas las claves empiezan por «Vertice_».

local PlanetCity = require(script.Parent.PlanetCity)

local function deck(id: string, x0: number, x1: number, z0: number, z1: number, kind: string?): { [string]: any }
	return { Id = id, Kind = "Rect", X0 = x0, X1 = x1, Z0 = z0, Z1 = z1, Deck = kind or "Cristal" }
end

local City = PlanetCity.new({
	Id = "DistritoCero",
	Name = "Distrito Cero · Plaza del Primer Cliente",
	Planet = "Vertice",
	KeyPrefix = "Vertice_",
	Rect = { X0 = -152, X1 = 152, Z0 = -142, Z1 = 142 },
	Blend = 40,
	Arrival = { 0, 30 },
	Void = { Depth = 80, Name = "El hueco", Text = "🚁 Un dron de MegaVerso te sube a la pasarela. «Gracias por no caerse. Esta vez es gratis»." },
	Floors = {
		{ Id = "CubiertaPlataforma", Kind = "Disc", X = 0, Z = 0, R = 48, Deck = "Plataforma" },
		deck("PaseoSur", -10, 10, 40, 56, "Pasarela"),
		deck("PlazaPrimerCliente", -62, 62, 50, 130, "Plaza"),
		deck("PaseoNorte", -10, 10, -66, -40, "Pasarela"),
		deck("Oficinas", -60, 60, -140, -60, "Oficinas"),
		deck("PaseoEste", 40, 64, -10, 10, "Pasarela"),
		deck("Maglev", 60, 150, -32, 32, "Maglev"),
		deck("Avenida", -150, -58, 70, 112, "Avenida"),
		deck("PaseoRastro", -86, -40, -14, 6, "Pasarela"),
		deck("Rastro", -150, -80, -62, 12, "Rastro"),
		deck("PaseoPlantilla", 56, 74, 80, 96, "Pasarela"),
		deck("Plantilla", 70, 150, 60, 140, "Plantilla"),
	},
	Districts = {
		{ Id = "Oficinas", Name = "Distrito Oficinas", Theme = "MegaVerso", Icon = "🏢", Color = Color3.fromRGB(230, 236, 255), Poly = { { -70, -142 }, { 70, -142 }, { 70, -40 }, { -70, -40 } } },
		{ Id = "Rastro", Name = "El Rastro (entrada)", Theme = "La resistencia", Icon = "🛠", Color = Color3.fromRGB(255, 200, 80), Poly = { { -152, -70 }, { -70, -70 }, { -70, 20 }, { -152, 20 } } },
		{ Id = "Avenida", Name = "Avenida Rebajas", Theme = "Tiendas enormes", Icon = "🛍", Color = Color3.fromRGB(255, 90, 200), Poly = { { -152, 60 }, { -62, 60 }, { -62, 120 }, { -152, 120 } } },
		{ Id = "Maglev", Name = "Estación del mag-lev", Theme = "Transporte", Icon = "🚄", Color = Color3.fromRGB(80, 230, 255), Poly = { { 40, -40 }, { 152, -40 }, { 152, 40 }, { 40, 40 } } },
		{ Id = "Plantilla", Name = "Barrio Plantilla", Theme = "Casas iguales de los empleados", Icon = "🏘", Color = Color3.fromRGB(200, 200, 210), Poly = { { 54, 56 }, { 152, 56 }, { 152, 142 }, { 54, 142 } } },
		{ Id = "Plaza", Name = "Plaza del Primer Cliente", Theme = "El kilómetro cero", Icon = "🗽", Color = Color3.fromRGB(255, 240, 120), Poly = { { -152, -142 }, { 152, -142 }, { 152, 142 }, { -152, 142 } } },
	},
	Buildings = {
		-- Norte: la Torre de Ventas, el Museo de la Luz y una torre de oficinas
		{ Id = "TorreVentas", District = "Oficinas", Kind = "Torre", Shape = "Torre", Name = "Torre de Ventas de MegaVerso", X = 0, Z = -108, W = 40, D = 34, Height = 150, Icon = "🏢",
			Info = "La Torre de Ventas de MegaVerso, el kilómetro cero de Vértice. Las puertas solo se abren con puntuación de cliente de 900." },
		{ Id = "Museo", District = "Oficinas", Kind = "Museo", Shape = "Box", Name = "Museo de la Luz", X = -42, Z = -90, W = 22, D = 16, Face = "E", Floors = 2, Style = "VerticeCristal", Ground = "Lobby", Sign = "MUSEO DE LA LUZ", Icon = "🏛",
			Info = "El Museo de la Luz: «La historia oficial de Vértice, patrocinada por MegaVerso». Entrada gratuita. Salida, 3 €." },
		{ Id = "TorreOficinas", District = "Oficinas", Kind = "Torre", Shape = "Rascacielos", Name = "Torre de oficinas 7", X = 40, Z = -122, R = 11, Height = 120 },
		-- Oeste: la Avenida Rebajas
		{ Id = "Hiper", District = "Avenida", Kind = "Tienda", Shape = "Box", Name = "Hipermercado Avenida", X = -122, Z = 90, W = 30, D = 20, Face = "S", Floors = 2, Style = "VerticeNeon", Ground = "Lobby", Sign = "HIPER · OFERTAS", Icon = "🛒",
			Info = "El hipermercado de la Avenida. Los precios cambian cada hora. Ahora, todo un 300 % más caro «por demanda»." },
		{ Id = "TodoAUno", District = "Avenida", Kind = "Tienda", Shape = "Box", Name = "Todo a Uno (del Rastro)", X = -80, Z = 90, W = 18, D = 16, Face = "S", Floors = 1, Style = "VerticeNeon", Ground = "Shop", ShopId = "VerticeRastro", Sign = "TODO A UNO", Icon = "🧢",
			Info = "Una tienda de la gente del Rastro, metida en la Avenida. Barato, sin garantía y sin cámaras dentro." },
		-- Sur: la Plaza del Primer Cliente
		{ Id = "Arcade", District = "Plaza", Kind = "Arcade", Shape = "Box", Name = "Arcade de neón", X = -42, Z = 112, W = 20, D = 18, Face = "E", Floors = 1, Style = "VerticeNeon", Ground = "Lobby", Sign = "ARCADE", Icon = "🕹",
			Info = "El arcade de neón: las cámaras de MegaVerso no entran (el dueño las tapó con pegatinas)." },
		{ Id = "Holo", District = "Plaza", Kind = "Pantalla", Shape = "Holo", Name = "Pantalla de anuncios", X = 46, Z = 120, R = 7, Height = 34,
			Info = "La pantalla gigante de la plaza: «¡Gracias por su compra!». Cada 30 segundos. Desde hace 40 años." },
		-- Noroeste: el Rastro (entrada al mercado de abajo)
		{ Id = "Ascensor", District = "Rastro", Kind = "Ascensor", Shape = "Box", Name = "Ascensor al Rastro", X = -100, Z = -48, W = 12, D = 12, Face = "N", Floors = 1, Style = "VerticeChapa", Ground = "Lobby", Sign = "MANTENIMIENTO", Icon = "🛗",
			Info = "Un ascensor de «mantenimiento». Baja al Rastro de Abajo, el mercado secreto de la resistencia." },
		{ Id = "Clinica", District = "Rastro", Kind = "Clinica", Shape = "Box", Name = "Clínica gratis del Rastro", X = -126, Z = -26, W = 22, D = 18, Face = "E", Floors = 1, Style = "VerticeChapa", Ground = "Lobby", Sign = "CLÍNICA · GRATIS", Icon = "⛑",
			Info = "La clínica gratis del Rastro. Sin seguro, sin puntuación y sin preguntas." },
		-- Este: la estación del mag-lev
		{ Id = "Maglev", District = "Maglev", Kind = "Estacion", Shape = "Maglev", Name = "Estación del mag-lev", X = 106, Z = 0, W = 40, D = 18, Height = 16, Icon = "🚄",
			Info = "El mag-lev de MegaVerso: el tren que flota sobre su raíl. Billete: 12 €. Con anuncios, 9 €." },
		-- Sureste: el Barrio Plantilla (bloques iguales de los empleados y la casa de Rosa)
		{ Id = "BloqueA", District = "Plantilla", Kind = "Bloque", Shape = "Bloque", Name = "Bloque de empleados A", X = 90, Z = 80, W = 16, D = 16, Height = 64 },
		{ Id = "BloqueB", District = "Plantilla", Kind = "Bloque", Shape = "Bloque", Name = "Bloque de empleados B", X = 132, Z = 80, W = 16, D = 16, Height = 64 },
		{ Id = "BloqueC", District = "Plantilla", Kind = "Bloque", Shape = "Bloque", Name = "Bloque de empleados C", X = 98, Z = 124, W = 16, D = 16, Height = 64,
			Info = "Bloque C del Barrio Plantilla. En la puerta, un papel: «Aviso de desalojo. Liquidación Total. Gracias por su compra»." },
		{ Id = "CasaRosa", District = "Plantilla", Kind = "Casa", Shape = "Box", Name = "Casa de Rosa Cruz", X = 132, Z = 122, W = 16, D = 14, Face = "W", Floors = 1, Style = "VerticeCristal", Ground = "House", Sign = "Nº 0001", Icon = "🏠",
			Info = "La casa de Rosa Cruz, la madre de Abril. Huele a café de verdad, que en Vértice es carísimo." },
	},
	Shelters = {
		Arcade = { Cool = 9, Name = "el Arcade de neón" },
		Ascensor = { Cool = 10, Name = "el ascensor del Rastro" },
		Clinica = { Cool = 10, Name = "la clínica gratis del Rastro" },
		CasaRosa = { Cool = 8, Name = "la casa de Rosa" },
		TodoAUno = { Cool = 6, Name = "Todo a Uno" },
	},
	-- Las cámaras de MegaVerso (la desventaja: la vigilancia sube cerca de ellas)
	Cameras = {
		{ X = -58, Z = 54 }, { X = 58, Z = 54 }, { X = 0, Z = 128 }, { X = -100, Z = 72 }, { X = -146, Z = 108 },
		{ X = -36, Z = -64 }, { X = 36, Z = -64 }, { X = 92, Z = -28 }, { X = 146, Z = 28 }, { X = 76, Z = 64 },
	},
	StorySpots = {
		{ Id = "Plataforma", Name = "Plataforma de Distrito Cero", X = 0, Z = 30 },
		{ Id = "Plaza", Name = "Plaza del Primer Cliente", X = 0, Z = 66 },
		{ Id = "Estatua", Name = "Estatua del Primer Cliente", X = 14, Z = 86 },
		{ Id = "Avenida", Name = "Avenida Rebajas", X = -110, Z = 106 },
		{ Id = "Arcade", Name = "Puerta del Arcade de neón", X = -28, Z = 112 },
		{ Id = "Museo", Name = "Puerta del Museo de la Luz", X = -26, Z = -78 },
		{ Id = "MuseoDentro", Name = "Sala del Museo de la Luz", X = -44, Z = -90, Inside = true },
		{ Id = "Oficinas", Name = "Pies de la Torre de Ventas", X = 0, Z = -70 },
		{ Id = "Rastro", Name = "Entrada del Rastro", X = -104, Z = -6 },
		{ Id = "AscensorDentro", Name = "Ascensor al Rastro (dentro)", X = -100, Z = -46, Inside = true },
		{ Id = "Maglev", Name = "Andén del mag-lev", X = 96, Z = 22 },
		{ Id = "Plantilla", Name = "Barrio Plantilla", X = 112, Z = 102 },
	},
	Spots = {
		{ Id = "EstatuaCliente", Name = "Estatua del Primer Cliente", X = 0, Z = 92, Icon = "🗽",
			Info = "«El Primer Cliente. Gracias por elegirnos». Un señor sonriente de bronce con una bolsa de la compra. Nadie sabe cómo se llamaba." },
		{ Id = "TablonPrecios", Name = "Tablón de precios", X = -62, Z = 60,
			Info = "Los precios de la hora: pan 14 €, agua 6 €, luz embotellada 40 €. «Mañana, más ofertas»." },
		{ Id = "CarteDespidos", Name = "Lista de despidos", X = 70, Z = 60,
			Info = "Una pantalla con nombres que pasan despacio. Encima: «Liquidación Total. Fase 1: Barrio Plantilla»." },
	},
	Gather = {
		{ Id = "Vertice_ChipsRastro", Name = "Chips usados", X = -144, Z = -6, Item = "Vertice_ChipUsado", Every = 40, Action = "Rebuscar" },
		{ Id = "Vertice_ChipsAvenida", Name = "Chips usados", X = -144, Z = 76, Item = "Vertice_ChipUsado", Every = 40, Action = "Rebuscar" },
		{ Id = "Vertice_LuzMaglev", Name = "Luz embotellada (caja rota)", X = 144, Z = -24, Item = "Vertice_LuzEmbotellada", Every = 90 },
	},
	Lamps = {
		{ X = -24, Z = 56 }, { X = 24, Z = 56 }, { X = -58, Z = 84 }, { X = 58, Z = 84 }, { X = -24, Z = 126 }, { X = 24, Z = 126 },
		{ X = 6, Z = -56 }, { X = -6, Z = -44 }, { X = -54, Z = -66 }, { X = 54, Z = -66 },
		{ X = 50, Z = 4 }, { X = 70, Z = 28 }, { X = 140, Z = -28 },
		{ X = -96, Z = 108 }, { X = -140, Z = 74 }, { X = -84, Z = -10 }, { X = -144, Z = -56 },
		{ X = 76, Z = 104 }, { X = 146, Z = 104 }, { X = 112, Z = 64 },
	},
	Benches = { { X = -26, Z = 80, Yaw = math.pi / 2 }, { X = 26, Z = 80, Yaw = -math.pi / 2 } },
	Crowd = {
		{ Group = "Plaza", X = -12, Z = 74, FX = 0, FZ = 92 }, { Group = "Plaza", X = 12, Z = 100, FX = 0, FZ = 92 },
		{ Group = "Plaza", X = 32, Z = 108, FX = 46, FZ = 120 }, { Group = "Plaza", X = -26, Z = 66, FX = -26, FZ = 80, Sit = true },
		{ Group = "Avenida", X = -110, Z = 104, FX = -122, FZ = 100 }, { Group = "Avenida", X = -76, Z = 104, FX = -80, FZ = 98 },
		{ Group = "Oficinas", X = 14, Z = -72, FX = 0, FZ = -90 }, { Group = "Oficinas", X = -14, Z = -68, FX = 0, FZ = -90 },
		{ Group = "Rastro", X = -112, Z = -6, FX = -100, FZ = -54 }, { Group = "Rastro", X = -136, Z = -46, FX = -126, FZ = -26, Sit = true },
		{ Group = "Maglev", X = 86, Z = 22, FX = 106, FZ = 0 }, { Group = "Maglev", X = 128, Z = 22, FX = 106, FZ = 0 },
		{ Group = "Plantilla", X = 112, Z = 96, FX = 98, FZ = 124 }, { Group = "Plantilla", X = 116, Z = 70, FX = 90, FZ = 80 },
	},
	Areas = { { X0 = -56, X1 = 56, Z0 = 56, Z1 = 126 } },
	-- La Cúpula pone el día (7:00) y la noche (23:00); a las horas punta, todo se colapsa
	Weather = function(clock: number): { Id: string, Name: string, Icon: string, Temp: number }
		local h = clock % 24
		if h >= 23 or h < 7 then
			return { Id = "CupulaApagada", Name = "Cúpula apagada", Icon = "🌑", Temp = 16 }
		elseif (h >= 8 and h < 9) or (h >= 18 and h < 19) then
			return { Id = "HoraPunta", Name = "Hora punta", Icon = "🚦", Temp = 22 }
		elseif h >= 13 and h < 14 then
			return { Id = "Riego", Name = "Lluvia de mantenimiento", Icon = "🌧", Temp = 19 }
		end
		return { Id = "CieloFalso", Name = "Cielo de la Cúpula", Icon = "🖥", Temp = 21 }
	end,
})

-- Fuera del barrio no se levanta tierra: el Nivel Bajo sigue abajo, con sus torres
local baseShape = City.shape
function City.shape(lx: number, lz: number, h: number, base: number): number
	if City.rectDistance(lx, lz) > City.Bank then
		return h
	end
	return baseShape(lx, lz, h, base)
end

-- La distancia a la cámara más cercana (studs, en el plano del barrio)
function City.cameraDistances(lx: number, lz: number): { number }
	local out = {}
	for _, c in City.Cameras do
		table.insert(out, math.sqrt((lx - c.X) ^ 2 + (lz - c.Z) ^ 2))
	end
	return out
end

return City
