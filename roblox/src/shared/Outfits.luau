-- Outfits: los 30 conjuntos de ropa del pase de temporada (la hoja «30 vestimentas exclusivas»).
-- SOLO DATOS (y dos ayudas). Los usan:
--   * shared/OutfitBuilder  -> viste al personaje: colores del cuerpo, ropa clásica (Shirt/Pants) si ya
--                             se subieron sus plantillas (shared/OutfitIds) y accesorios 3D con piezas.
--   * server AvatarService  -> el conjunto equipado (data.Cosmetics.Equipped.Outfit) al vestir.
--   * shared BattlePass/Season1 -> dónde sale cada uno en el pase (y su rareza de la hoja).
--   * scripts/outfits/gen.py (vía scripts/outfits/export.luau) -> dibuja las plantillas de ropa.
--
-- Cada conjunto:
--   Key ("O01"…"O30", para siempre), Number, Name, Rarity (Rara / Epica / Legendaria, la de la hoja),
--   Icon, Description,
--   Top    = { Kind, Color, Sleeve?, Trim?, Inner?, Sleeves = "Long"|"Short"|"None", Midriff?, Open?,
--              Hood?, Zip?, Pocket?, Buttons?, Collar?, Pattern?, Print?, Back?, Stripe?, Bands?, Quilt?,
--              Neon?, Panel?, OneShoulder?, SleeveStripes? }
--   Bottom = { Kind, Color, Trim?, Length = "Long"|"Knee"|"Short"|"Mini", Stripe?, Pockets?, Pattern?,
--              Fishnet?, Straps?, Bands?, Neon?, Rips?, Wide? }
--   Shoes  = { Kind = "Sneaker"|"HighTop"|"Boot"|"Combat"|"Heel"|"Platform"|"Cowboy"|"Sandal", Color, Sole?, Trim? }
--   Gloves = Color3?, Hair = { Style, Color? }?, Accessories = { { Kind, … } }
--   Costume = true -> ropa «de estilo» de un oficio (bombero, sanitaria, policía): SOLO se ve. No da el
--             trabajo, ni sus botones, ni su autoridad (eso lo da el atributo Job del servidor, que la
--             ropa no toca); además es distinta del uniforme de verdad y, mientras trabajas en un
--             oficio con uniforme, se guarda y llevas el uniforme oficial (Outfits.SuspendJobs).
--
-- Etapas de la vida: el bebé siempre lleva su pelele. Los niños llevan el conjunto «en talla de niño»
-- (OutfitBuilder: sin ombligo al aire, sin tacones ni medias de rejilla; todo se adapta a su tamaño).
-- De mayor, igual que de adulto (con canas si el conjunto no trae peinado propio).

local Outfits = {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local WHITE, BLACK = rgb(242, 242, 240), rgb(20, 20, 23)
local GOLD, SILVER = rgb(232, 190, 80), rgb(200, 204, 212)

-- Oficios con uniforme: mientras estás de servicio en uno de ellos (atributo Job) o en prisión, el
-- conjunto del pase se guarda y se ve el uniforme oficial. Al acabar el turno vuelve solo.
Outfits.SuspendJobs = {
	Policia = true, Bombero = true, Juez = true, Funcionario = true, Militar = true, Hacienda = true,
}

-- Palabras que no pueden salir en ningún conjunto (marcas reales y el nombre del logo de la hoja)
Outfits.Forbidden = {
	"nova", "novalife", "nike", "adidas", "puma", "reebok", "jordan", "supreme", "gucci", "prada", "chanel", "dior",
	"vans", "converse", "balenciaga", "versace", "lacoste", "nba", "fila", "champion", "levi", "zara",
}

local list = {
	-------------------------------------------------------------------------- 01-10
	{
		Key = "O01", Number = 1, Name = "Urban Classic", Rarity = "Legendaria", Icon = "🧥",
		Description = "Sudadera negra abierta con estampado blanco, camiseta gráfica, cargo negro con franja, gorra, gafas y cadena de plata.",
		Top = { Kind = "Hoodie", Color = rgb(22, 22, 26), Trim = WHITE, Inner = WHITE, Sleeves = "Long", Open = true, Hood = true, Zip = true,
			Stripe = WHITE, Print = { Text = "VLM", Color = WHITE }, InnerPrint = { Text = "V", Color = rgb(30, 30, 34) }, Back = { Text = "VALMAR", Color = WHITE } },
		Bottom = { Kind = "Cargo", Color = rgb(24, 24, 28), Length = "Long", Stripe = WHITE, Pockets = true, Wide = true },
		Shoes = { Kind = "Sneaker", Color = WHITE, Sole = WHITE, Trim = rgb(30, 30, 34) },
		Accessories = {
			{ Kind = "Cap", Color = BLACK, Trim = WHITE },
			{ Kind = "Sunglasses", Style = "Square", Color = rgb(15, 15, 18) },
			{ Kind = "Chain", Color = SILVER },
		},
	},
	{
		Key = "O02", Number = 2, Name = "Coast Vibes", Rarity = "Epica", Icon = "🏖️",
		Description = "Todo en blanco: top corto, cargo ancho, gorra y zapatillas. Gafas oscuras y un colgante dorado para el paseo.",
		Top = { Kind = "Crop", Color = WHITE, Sleeves = "None", Midriff = true, Collar = "Round" },
		Bottom = { Kind = "Cargo", Color = rgb(236, 234, 226), Length = "Long", Pockets = true, Wide = true, Belt = rgb(200, 190, 170) },
		Shoes = { Kind = "Sneaker", Color = WHITE, Sole = WHITE, Trim = rgb(210, 210, 214) },
		Hair = { Style = "Long", Color = rgb(44, 30, 24) },
		Accessories = {
			{ Kind = "Cap", Color = WHITE, Trim = rgb(220, 220, 224) },
			{ Kind = "Sunglasses", Style = "Cat", Color = rgb(25, 20, 18) },
			{ Kind = "Necklace", Color = GOLD },
		},
	},
	{
		Key = "O03", Number = 3, Name = "Shadow Ops", Rarity = "Legendaria", Icon = "🥷",
		Description = "Negro táctico de pies a cabeza: chaqueta, chaleco de bolsillos, cargo, botas, guantes, gorra y braga de cuello. (Solo estilo: sin armas).",
		Top = { Kind = "Jacket", Color = rgb(20, 20, 22), Trim = rgb(48, 50, 54), Sleeves = "Long", Zip = true, Collar = "High" },
		Bottom = { Kind = "Cargo", Color = rgb(22, 22, 24), Length = "Long", Pockets = true, Straps = rgb(40, 42, 46) },
		Shoes = { Kind = "Combat", Color = rgb(16, 16, 18), Sole = rgb(30, 30, 32) },
		Gloves = rgb(18, 18, 20),
		Accessories = {
			{ Kind = "Cap", Color = rgb(16, 16, 18), Trim = rgb(40, 40, 44) },
			{ Kind = "Mask", Color = rgb(16, 16, 18) },
			{ Kind = "Sunglasses", Style = "Sport", Color = rgb(10, 10, 12) },
			{ Kind = "TacticalVest", Color = rgb(28, 30, 32), Trim = rgb(44, 46, 50) },
			{ Kind = "Belt", Color = rgb(30, 30, 32), Buckle = rgb(90, 92, 98), Pouches = true },
		},
	},
	{
		Key = "O04", Number = 4, Name = "Sporty Girl", Rarity = "Epica", Icon = "❤️",
		Description = "Rojo intenso: top corto de manga corta y cargo paracaídas con correas. Zapatillas blancas y gafas de cristal rojo.",
		Top = { Kind = "Crop", Color = rgb(206, 28, 36), Sleeves = "Short", Midriff = true, Collar = "Round", Trim = rgb(160, 18, 26) },
		Bottom = { Kind = "Cargo", Color = rgb(196, 26, 34), Length = "Long", Pockets = true, Straps = rgb(30, 30, 34), Wide = true },
		Shoes = { Kind = "Sneaker", Color = WHITE, Sole = WHITE, Trim = rgb(206, 28, 36) },
		Hair = { Style = "Long", Color = rgb(122, 52, 32) },
		Accessories = {
			{ Kind = "Sunglasses", Style = "Round", Color = rgb(200, 30, 40), Frame = GOLD },
			{ Kind = "Belt", Color = rgb(28, 28, 32), Buckle = SILVER },
		},
	},
	{
		Key = "O05", Number = 5, Name = "Valmar Team", Rarity = "Rara", Icon = "🔵",
		Description = "La chaqueta del equipo de Valmar: blanca con paneles azul marino, camiseta «VALMAR», vaqueros claros y gorra a juego.",
		Top = { Kind = "Jacket", Color = WHITE, Sleeve = WHITE, Panel = rgb(26, 44, 96), Trim = rgb(26, 44, 96), Inner = rgb(26, 44, 96), Sleeves = "Long", Open = true, Zip = true,
			Stripe = rgb(26, 44, 96), InnerPrint = { Text = "VALMAR", Color = WHITE }, Back = { Text = "VALMAR TEAM", Color = rgb(26, 44, 96) } },
		Bottom = { Kind = "Jeans", Color = rgb(150, 182, 216), Length = "Long", Pockets = true, Wide = true },
		Shoes = { Kind = "Sneaker", Color = WHITE, Sole = WHITE, Trim = rgb(26, 44, 96) },
		Accessories = {
			{ Kind = "Cap", Color = WHITE, Trim = rgb(26, 44, 96) },
			{ Kind = "Sunglasses", Style = "Square", Color = rgb(20, 20, 24) },
		},
	},
	{
		Key = "O06", Number = 6, Name = "Business Lady", Rarity = "Epica", Icon = "👜",
		Description = "Abrigo largo negro sobre top corto, pantalón ancho de pinzas, tacones y bolso con cierre dorado. Para mandar en el Distrito Financiero.",
		Top = { Kind = "Coat", Color = rgb(18, 18, 22), Inner = rgb(30, 30, 34), Sleeves = "Long", Open = true, Midriff = true, Collar = "Shirt", Trim = rgb(40, 40, 46) },
		Bottom = { Kind = "Trousers", Color = rgb(22, 22, 26), Length = "Long", Wide = true },
		Shoes = { Kind = "Heel", Color = rgb(16, 16, 18), Sole = rgb(16, 16, 18) },
		Hair = { Style = "Long", Color = rgb(30, 22, 20) },
		Accessories = {
			{ Kind = "Sunglasses", Style = "Cat", Color = rgb(12, 12, 14), Frame = GOLD },
			{ Kind = "CoatTails", Color = rgb(18, 18, 22) },
			{ Kind = "Handbag", Color = rgb(14, 14, 16), Trim = GOLD },
		},
	},
	{
		Key = "O07", Number = 7, Name = "Estilo Bombero", Rarity = "Legendaria", Icon = "🧑‍🚒", Costume = true,
		Description = "Traje de inspiración bombero en gris carbón con bandas amarillo flúor, casco negro, guantes y botas. Ropa de estilo: no te hace bombero (para eso, el turno en el parque de bomberos y su uniforme oficial).",
		Top = { Kind = "Turnout", Color = rgb(40, 42, 48), Trim = rgb(30, 30, 34), Sleeves = "Long", Zip = true, Collar = "High", Bands = rgb(214, 240, 40), Back = { Text = "ESTILO", Color = rgb(214, 240, 40) } },
		Bottom = { Kind = "Trousers", Color = rgb(40, 42, 48), Length = "Long", Bands = rgb(214, 240, 40), Wide = true },
		Shoes = { Kind = "Boot", Color = rgb(18, 18, 20), Sole = rgb(30, 30, 32) },
		Gloves = rgb(24, 24, 26),
		Accessories = {
			{ Kind = "FireHelmet", Color = rgb(20, 20, 22), Trim = rgb(214, 240, 40) },
			{ Kind = "Belt", Color = rgb(28, 28, 30), Buckle = rgb(214, 240, 40) },
		},
	},
	{
		Key = "O08", Number = 8, Name = "Estilo Sanitaria", Rarity = "Epica", Icon = "🩺", Costume = true,
		Description = "Pijama sanitario azul con cuello de pico, fonendo, tarjeta y zapatillas blancas. Ropa de estilo: no da el trabajo de médico (ese se coge en el hospital).",
		Top = { Kind = "Scrubs", Color = rgb(58, 108, 198), Sleeves = "Short", Collar = "V", Pocket = "Chest", Trim = rgb(44, 88, 170), Print = { Text = "♥", Color = WHITE } },
		Bottom = { Kind = "Joggers", Color = rgb(58, 108, 198), Length = "Long", Pockets = true },
		Shoes = { Kind = "Sneaker", Color = WHITE, Sole = WHITE, Trim = rgb(180, 200, 230) },
		Hair = { Style = "Ponytail", Color = rgb(60, 40, 30) },
		Accessories = {
			{ Kind = "Stethoscope", Color = rgb(40, 40, 46) },
			{ Kind = "IdBadge", Color = WHITE, Trim = rgb(58, 108, 198) },
			{ Kind = "Watch", Color = WHITE },
		},
	},
	{
		Key = "O09", Number = 9, Name = "Estilo Policía", Rarity = "Legendaria", Icon = "🕶️", Costume = true,
		Description = "Camisa azul noche, chaleco de bolsillos negro, cargo, botas, guantes y gorra negra. Ropa de estilo, sin placa ni armas: no te hace agente ni te deja multar o detener (eso solo con el turno en la comisaría y su uniforme oficial).",
		Top = { Kind = "Shirt", Color = rgb(26, 34, 62), Trim = rgb(20, 26, 48), Sleeves = "Long", Buttons = true, Collar = "Shirt", Pocket = "Chest" },
		Bottom = { Kind = "Cargo", Color = rgb(24, 30, 54), Length = "Long", Pockets = true },
		Shoes = { Kind = "Combat", Color = rgb(14, 14, 16), Sole = rgb(28, 28, 30) },
		Gloves = rgb(16, 16, 18),
		Accessories = {
			{ Kind = "Cap", Color = rgb(16, 16, 20), Trim = SILVER, Style = "Patrol" },
			{ Kind = "TacticalVest", Color = rgb(18, 20, 24), Trim = rgb(40, 44, 50), Back = "ESTILO" },
			{ Kind = "Belt", Color = rgb(18, 18, 20), Buckle = SILVER, Pouches = true },
			{ Kind = "Sunglasses", Style = "Sport", Color = rgb(30, 30, 36), Frame = SILVER },
		},
	},
	{
		Key = "O10", Number = 10, Name = "Summer Dream", Rarity = "Epica", Icon = "👒",
		Description = "Top blanco de tirantes, shorts vaqueros, sombrero de paja, bolso de rafia y gafas grandes. Huele a Playa Dorada.",
		Top = { Kind = "Tank", Color = WHITE, Sleeves = "None", Midriff = true, Collar = "Round" },
		Bottom = { Kind = "Shorts", Color = rgb(96, 140, 196), Length = "Short", Pockets = true, Rips = true },
		Shoes = { Kind = "Sneaker", Color = WHITE, Sole = WHITE, Trim = rgb(230, 200, 150) },
		Hair = { Style = "Wavy", Color = rgb(110, 70, 40) },
		Accessories = {
			{ Kind = "SunHat", Color = rgb(222, 196, 140), Trim = rgb(30, 30, 34) },
			{ Kind = "Sunglasses", Style = "Round", Color = rgb(40, 30, 24), Frame = GOLD },
			{ Kind = "ShoulderBag", Color = rgb(214, 186, 130), Trim = rgb(150, 110, 70) },
		},
	},
	-------------------------------------------------------------------------- 11-20
	{
		Key = "O11", Number = 11, Name = "Caballero", Rarity = "Rara", Icon = "🤵",
		Description = "Esmoquin negro con camisa blanca, pajarita y zapatos de charol. Gafas de sol para la alfombra roja.",
		Top = { Kind = "Tuxedo", Color = rgb(16, 16, 20), Inner = WHITE, Trim = rgb(34, 34, 40), Sleeves = "Long", Open = true, Buttons = true, Collar = "Shirt" },
		Bottom = { Kind = "Trousers", Color = rgb(16, 16, 20), Length = "Long", Stripe = rgb(34, 34, 40) },
		Shoes = { Kind = "Dress", Color = rgb(10, 10, 12), Sole = rgb(10, 10, 12) },
		Accessories = {
			{ Kind = "BowTie", Color = rgb(10, 10, 12) },
			{ Kind = "Sunglasses", Style = "Square", Color = rgb(10, 10, 12) },
			{ Kind = "Watch", Color = SILVER },
		},
	},
	{
		Key = "O12", Number = 12, Name = "Elegance", Rarity = "Legendaria", Icon = "💃",
		Description = "Vestido largo de satén rojo a un hombro con abertura, tacones rojos, melena rubia y joyas doradas. La gala del Estadio Altamar es tuya.",
		Top = { Kind = "Dress", Color = rgb(190, 18, 38), Sleeves = "None", OneShoulder = true, Trim = rgb(150, 10, 28) },
		Bottom = { Kind = "Gown", Color = rgb(186, 16, 36), Length = "Long", Slit = true },
		Shoes = { Kind = "Heel", Color = rgb(190, 18, 38), Sole = rgb(120, 10, 20) },
		Hair = { Style = "Wavy", Color = rgb(226, 196, 130) },
		Accessories = {
			{ Kind = "Gown", Color = rgb(186, 16, 36), Slit = true, Satin = true },
			{ Kind = "Necklace", Color = GOLD },
		},
	},
	{
		Key = "O13", Number = 13, Name = "Basket Life", Rarity = "Epica", Icon = "🏀",
		Description = "Camiseta de tirantes azul con el «VALMAR 23», pantalón corto negro, zapatillas altas y muñequeras. Para la cancha del parque.",
		Top = { Kind = "Jersey", Color = rgb(30, 52, 150), Trim = rgb(214, 30, 44), Sleeves = "None", Collar = "V", Print = { Text = "VALMAR", Color = WHITE }, Number = "23", Back = { Text = "23", Color = WHITE } },
		Bottom = { Kind = "Shorts", Color = rgb(20, 20, 24), Length = "Knee", Stripe = WHITE, Wide = true },
		Shoes = { Kind = "HighTop", Color = WHITE, Sole = WHITE, Trim = rgb(214, 30, 44) },
		Accessories = {
			{ Kind = "Wristbands", Color = WHITE },
			{ Kind = "Basketball", Color = rgb(222, 110, 40) },
		},
	},
	{
		Key = "O14", Number = 14, Name = "Gym Girl", Rarity = "Rara", Icon = "🏋️",
		Description = "Top deportivo negro, mallas con raya blanca, zapatillas y coleta alta. Del gimnasio a la calle.",
		Top = { Kind = "Bra", Color = rgb(18, 18, 22), Sleeves = "None", Midriff = true, Trim = rgb(60, 60, 66) },
		Bottom = { Kind = "Leggings", Color = rgb(18, 18, 22), Length = "Long", Stripe = WHITE },
		Shoes = { Kind = "Sneaker", Color = WHITE, Sole = WHITE, Trim = rgb(18, 18, 22) },
		Hair = { Style = "Ponytail", Color = rgb(28, 22, 20) },
		Accessories = {
			{ Kind = "Armband", Color = rgb(30, 30, 34) },
			{ Kind = "Wristbands", Color = rgb(18, 18, 22), Left = true },
		},
	},
	{
		Key = "O15", Number = 15, Name = "Tech Wear", Rarity = "Epica", Icon = "🎒",
		Description = "Plumífero blanco con correas negras, cargo técnico, gorra, gafas y mochila con hebillas. Ropa del futuro, cómoda hoy.",
		Top = { Kind = "Puffer", Color = rgb(240, 240, 238), Trim = rgb(24, 24, 28), Sleeves = "Long", Hood = true, Zip = true, Quilt = true, Straps = rgb(24, 24, 28) },
		Bottom = { Kind = "Cargo", Color = rgb(232, 232, 230), Length = "Long", Pockets = true, Straps = rgb(24, 24, 28), Wide = true },
		Shoes = { Kind = "Sneaker", Color = WHITE, Sole = rgb(220, 220, 220), Trim = rgb(24, 24, 28) },
		Accessories = {
			{ Kind = "Cap", Color = WHITE, Trim = rgb(24, 24, 28), Back = true },
			{ Kind = "Sunglasses", Style = "Sport", Color = rgb(20, 20, 24) },
			{ Kind = "Backpack", Color = rgb(24, 24, 28), Trim = rgb(120, 122, 128) },
			{ Kind = "CollarPuffer", Color = rgb(240, 240, 238) },
		},
	},
	{
		Key = "O16", Number = 16, Name = "Ranchera", Rarity = "Legendaria", Icon = "🤠",
		Description = "Chaqueta de ante con flecos, top blanco, vaqueros de campana, botas camperas y sombrero vaquero. Del Monte del Silencio a la verbena.",
		Top = { Kind = "Jacket", Color = rgb(116, 68, 36), Trim = rgb(90, 50, 26), Inner = WHITE, Sleeves = "Long", Open = true, Midriff = true, Collar = "Shirt" },
		Bottom = { Kind = "Flare", Color = rgb(58, 88, 148), Length = "Long", Pockets = true },
		Shoes = { Kind = "Cowboy", Color = rgb(110, 64, 34), Sole = rgb(60, 36, 20), Trim = rgb(170, 120, 70) },
		Hair = { Style = "Wavy", Color = rgb(96, 58, 34) },
		Accessories = {
			{ Kind = "CowboyHat", Color = rgb(206, 176, 128), Trim = rgb(90, 56, 30) },
			{ Kind = "Fringe", Color = rgb(116, 68, 36) },
			{ Kind = "Belt", Color = rgb(70, 42, 22), Buckle = GOLD, Big = true },
		},
	},
	{
		Key = "O17", Number = 17, Name = "Purple Vibes", Rarity = "Epica", Icon = "💜",
		Description = "Sudadera lila con estampado, cargo negro ancho con cadenas y zapatillas a juego. Imposible pasar desapercibido.",
		Top = { Kind = "Hoodie", Color = rgb(138, 70, 210), Trim = rgb(104, 46, 170), Sleeves = "Long", Hood = true, Pocket = "Kangaroo", Print = { Text = "★", Color = rgb(235, 220, 255) }, Back = { Text = "VIBES", Color = rgb(235, 220, 255) } },
		Bottom = { Kind = "Cargo", Color = rgb(20, 20, 24), Length = "Long", Pockets = true, Wide = true },
		Shoes = { Kind = "Sneaker", Color = rgb(24, 24, 28), Sole = WHITE, Trim = rgb(138, 70, 210) },
		Accessories = {
			{ Kind = "WaistChain", Color = SILVER },
			{ Kind = "Chain", Color = SILVER },
		},
	},
	{
		Key = "O18", Number = 18, Name = "Goth Style", Rarity = "Rara", Icon = "🖤",
		Description = "Top negro con mangas a rayas, falda plisada corta, medias de rejilla, botas de plataforma y gargantilla. Oscuro y con estilo.",
		Top = { Kind = "Crop", Color = rgb(16, 16, 18), Sleeves = "Long", Midriff = true, SleeveStripes = { rgb(16, 16, 18), rgb(230, 230, 232) }, Collar = "Round" },
		Bottom = { Kind = "Skirt", Color = rgb(18, 18, 20), Length = "Mini", Fishnet = true },
		Shoes = { Kind = "Platform", Color = rgb(14, 14, 16), Sole = rgb(30, 30, 32), Trim = SILVER },
		Hair = { Style = "Long", Color = rgb(14, 14, 16) },
		Accessories = {
			{ Kind = "Choker", Color = rgb(14, 14, 16), Trim = SILVER },
			{ Kind = "Skirt", Color = rgb(18, 18, 20), Pleats = true },
			{ Kind = "Sunglasses", Style = "Round", Color = rgb(10, 10, 12), Frame = SILVER },
			{ Kind = "Belt", Color = rgb(14, 14, 16), Buckle = SILVER },
		},
	},
	{
		Key = "O19", Number = 19, Name = "Tropical", Rarity = "Epica", Icon = "🌴",
		Description = "Camisa de flores y hojas tropicales, pantalón corto azul marino, zapatillas blancas y cadena dorada. Verano todo el año.",
		Top = { Kind = "Shirt", Color = rgb(40, 170, 160), Sleeves = "Short", Open = true, Inner = WHITE, Collar = "Shirt",
			Pattern = { Kind = "Tropical", Colors = { rgb(40, 170, 160), rgb(250, 214, 60), rgb(40, 120, 60), rgb(250, 120, 80), rgb(240, 240, 230) } } },
		Bottom = { Kind = "Shorts", Color = rgb(28, 40, 72), Length = "Knee", Pockets = true },
		Shoes = { Kind = "Sneaker", Color = WHITE, Sole = WHITE, Trim = rgb(40, 170, 160) },
		Accessories = {
			{ Kind = "Sunglasses", Style = "Square", Color = rgb(20, 20, 24), Frame = GOLD },
			{ Kind = "Chain", Color = GOLD },
		},
	},
	{
		Key = "O20", Number = 20, Name = "Street Skater", Rarity = "Legendaria", Icon = "🛹",
		Description = "Sudadera negra con mangas blancas y grafiti, vaqueros anchos claros, auriculares blancos y monopatín a la espalda.",
		Top = { Kind = "Hoodie", Color = rgb(20, 20, 24), Sleeve = WHITE, Trim = rgb(20, 20, 24), Sleeves = "Long", Hood = true, Print = { Text = "SK8", Color = WHITE },
			Pattern = { Kind = "Graffiti", Colors = { rgb(20, 20, 24), WHITE, rgb(80, 200, 255), rgb(255, 80, 160) } } },
		Bottom = { Kind = "Jeans", Color = rgb(160, 192, 224), Length = "Long", Pockets = true, Wide = true },
		Shoes = { Kind = "Sneaker", Color = rgb(24, 24, 28), Sole = WHITE, Trim = WHITE },
		Accessories = {
			{ Kind = "Headphones", Color = WHITE, Trim = rgb(40, 40, 46) },
			{ Kind = "Skateboard", Color = rgb(20, 20, 24), Trim = rgb(255, 80, 160) },
			{ Kind = "Chain", Color = SILVER },
		},
	},
	-------------------------------------------------------------------------- 21-30
	{
		Key = "O21", Number = 21, Name = "Montaña", Rarity = "Epica", Icon = "🏔️",
		Description = "Chaqueta acolchada azul y negra, cargo negro, botas de montaña, gorra y mochila. Lista para subir al Monte del Silencio.",
		Top = { Kind = "Puffer", Color = rgb(36, 98, 200), Panel = rgb(20, 20, 24), Trim = rgb(20, 20, 24), Sleeves = "Long", Zip = true, Quilt = true, Collar = "High" },
		Bottom = { Kind = "Cargo", Color = rgb(22, 22, 26), Length = "Long", Pockets = true },
		Shoes = { Kind = "Boot", Color = rgb(40, 36, 32), Sole = rgb(24, 22, 20), Trim = rgb(36, 98, 200) },
		Accessories = {
			{ Kind = "Cap", Color = rgb(20, 20, 24), Trim = WHITE },
			{ Kind = "Sunglasses", Style = "Sport", Color = rgb(20, 40, 80), Frame = rgb(20, 20, 24) },
			{ Kind = "Backpack", Color = rgb(30, 30, 34), Trim = rgb(36, 98, 200) },
			{ Kind = "CollarPuffer", Color = rgb(20, 20, 24) },
		},
	},
	{
		Key = "O22", Number = 22, Name = "Cyber Pink", Rarity = "Legendaria", Icon = "🩷",
		Description = "Plumífero rosa corto, top negro, shorts, botas altas rosas, coletas rosa chicle y visera de neón. Del futuro, en rosa.",
		Top = { Kind = "Puffer", Color = rgb(255, 128, 196), Inner = rgb(20, 20, 24), Sleeves = "Long", Open = true, Midriff = true, Quilt = true, Neon = rgb(255, 60, 200) },
		Bottom = { Kind = "Shorts", Color = rgb(20, 20, 24), Length = "Short", Neon = rgb(255, 60, 200) },
		Shoes = { Kind = "Platform", Color = rgb(255, 128, 196), Sole = rgb(30, 30, 34), Trim = rgb(255, 60, 200), Tall = true },
		Hair = { Style = "Twin", Color = rgb(255, 150, 210) },
		Accessories = {
			{ Kind = "Visor", Color = rgb(255, 60, 200) },
			{ Kind = "CollarPuffer", Color = rgb(255, 128, 196) },
			{ Kind = "Choker", Color = rgb(20, 20, 24), Trim = rgb(255, 60, 200) },
		},
	},
	{
		Key = "O23", Number = 23, Name = "Racing", Rarity = "Epica", Icon = "🏁",
		Description = "Mono de carreras blanco con paneles negros y rojos, guantes y el casco bajo el brazo. Para quien se sabe el circuito de memoria.",
		Top = { Kind = "Racing", Color = rgb(244, 244, 244), Panel = rgb(20, 20, 24), Trim = rgb(214, 30, 40), Sleeves = "Long", Zip = true, Collar = "High", Stripe = rgb(214, 30, 40), Print = { Text = "23", Color = rgb(214, 30, 40) } },
		Bottom = { Kind = "Racing", Color = rgb(244, 244, 244), Length = "Long", Stripe = rgb(20, 20, 24), Panel = rgb(20, 20, 24) },
		Shoes = { Kind = "HighTop", Color = rgb(20, 20, 24), Sole = rgb(240, 240, 240), Trim = rgb(214, 30, 40) },
		Gloves = rgb(20, 20, 24),
		Accessories = {
			{ Kind = "HelmetInHand", Color = rgb(244, 244, 244), Trim = rgb(214, 30, 40) },
		},
	},
	{
		Key = "O24", Number = 24, Name = "Bohemia", Rarity = "Rara", Icon = "🌻",
		Description = "Top mostaza con flecos, pantalón ancho de estampado étnico, sandalias, sombrero y collar de cuentas. Espíritu de mercadillo.",
		Top = { Kind = "Crop", Color = rgb(214, 156, 50), Sleeves = "None", Midriff = true, Collar = "V" },
		Bottom = { Kind = "Wide", Color = rgb(170, 80, 50), Length = "Long", Wide = true,
			Pattern = { Kind = "Paisley", Colors = { rgb(170, 80, 50), rgb(40, 120, 130), rgb(240, 200, 120), rgb(110, 40, 40) } } },
		Shoes = { Kind = "Sandal", Color = rgb(130, 82, 46), Sole = rgb(90, 56, 30) },
		Hair = { Style = "Wavy", Color = rgb(120, 76, 44) },
		Accessories = {
			{ Kind = "SunHat", Color = rgb(196, 160, 110), Trim = rgb(130, 82, 46) },
			{ Kind = "Beads", Colors = { rgb(214, 156, 50), rgb(40, 120, 130), rgb(170, 80, 50), WHITE } },
			{ Kind = "Fringe", Color = rgb(214, 156, 50), Chest = true },
			{ Kind = "Sunglasses", Style = "Round", Color = rgb(60, 40, 20), Frame = GOLD },
		},
	},
	{
		Key = "O25", Number = 25, Name = "Winter", Rarity = "Legendaria", Icon = "❄️",
		Description = "Plumífero negro con capucha, cargo negro con correa blanca, botas, gorra y bufanda. Ni el viento del puerto puede contigo.",
		Top = { Kind = "Puffer", Color = rgb(16, 16, 18), Trim = rgb(40, 40, 44), Sleeves = "Long", Hood = true, Zip = true, Quilt = true, Print = { Text = "VLM", Color = WHITE } },
		Bottom = { Kind = "Cargo", Color = rgb(18, 18, 20), Length = "Long", Pockets = true, Straps = WHITE },
		Shoes = { Kind = "Boot", Color = rgb(16, 16, 18), Sole = rgb(30, 30, 32) },
		Accessories = {
			{ Kind = "Cap", Color = rgb(16, 16, 18), Trim = WHITE },
			{ Kind = "Scarf", Color = rgb(36, 36, 40) },
			{ Kind = "CollarPuffer", Color = rgb(16, 16, 18) },
		},
	},
	{
		Key = "O26", Number = 26, Name = "Neon", Rarity = "Epica", Icon = "⚡",
		Description = "Chaqueta negra con paneles verde flúor, cargo neón, botas negras y gafas de ventisca. Brilla en la noche del Centro.",
		Top = { Kind = "Jacket", Color = rgb(20, 20, 24), Panel = rgb(176, 255, 40), Trim = rgb(176, 255, 40), Sleeves = "Long", Zip = true, Collar = "High", Neon = rgb(176, 255, 40) },
		Bottom = { Kind = "Cargo", Color = rgb(176, 255, 40), Length = "Long", Pockets = true, Straps = rgb(20, 20, 24), Wide = true },
		Shoes = { Kind = "Combat", Color = rgb(20, 20, 24), Sole = rgb(176, 255, 40) },
		Gloves = rgb(20, 20, 24),
		Accessories = {
			{ Kind = "Goggles", Color = rgb(176, 255, 40), Trim = rgb(20, 20, 24) },
		},
	},
	{
		Key = "O27", Number = 27, Name = "Urbano Cultural", Rarity = "Rara", Icon = "🧡",
		Description = "Cazadora de estampado étnico naranja y marrón, camiseta negra, vaqueros oscuros, gorra, gafas y cadena. La calle con raíces.",
		Top = { Kind = "Bomber", Color = rgb(206, 124, 40), Inner = rgb(20, 20, 24), Sleeves = "Long", Open = true, Zip = true, Trim = rgb(60, 36, 20),
			Pattern = { Kind = "Ethnic", Colors = { rgb(206, 124, 40), rgb(90, 50, 24), rgb(240, 210, 150), rgb(20, 20, 24) } } },
		Bottom = { Kind = "Jeans", Color = rgb(34, 38, 52), Length = "Long", Pockets = true },
		Shoes = { Kind = "Sneaker", Color = WHITE, Sole = WHITE, Trim = rgb(206, 124, 40) },
		Accessories = {
			{ Kind = "Cap", Color = rgb(20, 20, 24), Trim = rgb(206, 124, 40) },
			{ Kind = "Sunglasses", Style = "Square", Color = rgb(30, 24, 18), Frame = GOLD },
			{ Kind = "Chain", Color = GOLD },
		},
	},
	{
		Key = "O28", Number = 28, Name = "Tennis", Rarity = "Epica", Icon = "🎾",
		Description = "Polo blanco con ribete azul, falda plisada, zapatillas, gorra, muñequeras y raqueta. Set, partido y estilo.",
		Top = { Kind = "Polo", Color = rgb(246, 246, 246), Trim = rgb(40, 70, 160), Sleeves = "None", Collar = "Shirt" },
		Bottom = { Kind = "Skirt", Color = rgb(246, 246, 246), Length = "Mini", Trim = rgb(40, 70, 160) },
		Shoes = { Kind = "Sneaker", Color = WHITE, Sole = WHITE, Trim = rgb(40, 70, 160) },
		Hair = { Style = "Ponytail", Color = rgb(214, 180, 110) },
		Accessories = {
			{ Kind = "Cap", Color = WHITE, Trim = rgb(40, 70, 160) },
			{ Kind = "Skirt", Color = rgb(246, 246, 246), Pleats = true, Trim = rgb(40, 70, 160) },
			{ Kind = "Wristbands", Color = WHITE },
			{ Kind = "Racket", Color = rgb(40, 70, 160), Trim = rgb(214, 240, 60) },
		},
	},
	{
		Key = "O29", Number = 29, Name = "Future", Rarity = "Legendaria", Icon = "🛰️",
		Description = "Chaqueta técnica negra con detalles dorados luminosos, cargo negro, botas, gorra y cadenas doradas. Así se viste en 2099.",
		Top = { Kind = "Jacket", Color = rgb(16, 16, 18), Panel = rgb(232, 160, 40), Trim = rgb(232, 160, 40), Sleeves = "Long", Zip = true, Hood = true, Collar = "High", Neon = rgb(255, 180, 50), Print = { Text = "◆", Color = rgb(255, 190, 60) } },
		Bottom = { Kind = "Cargo", Color = rgb(18, 18, 20), Length = "Long", Pockets = true, Straps = rgb(232, 160, 40) },
		Shoes = { Kind = "Combat", Color = rgb(16, 16, 18), Sole = rgb(232, 160, 40) },
		Accessories = {
			{ Kind = "Cap", Color = rgb(16, 16, 18), Trim = rgb(232, 160, 40) },
			{ Kind = "Visor", Color = rgb(255, 180, 50) },
			{ Kind = "Chain", Color = GOLD, Double = true },
		},
	},
	{
		Key = "O30", Number = 30, Name = "Ángel", Rarity = "Legendaria", Icon = "😇",
		Description = "Corsé y pantalón vaporoso blancos, alas de plumas con un brillo suave, aureola dorada y melena rubia. La joya de la temporada.",
		Top = { Kind = "Corset", Color = rgb(250, 248, 244), Trim = rgb(232, 206, 140), Sleeves = "None", Collar = "Round" },
		Bottom = { Kind = "Gown", Color = rgb(250, 248, 244), Length = "Long", Trim = rgb(232, 206, 140) },
		Shoes = { Kind = "Heel", Color = rgb(250, 248, 244), Sole = rgb(232, 206, 140) },
		Hair = { Style = "Wavy", Color = rgb(236, 210, 150) },
		Accessories = {
			{ Kind = "Wings", Color = rgb(252, 252, 250), Glow = rgb(255, 244, 214) },
			{ Kind = "Halo", Color = rgb(255, 214, 120) },
			{ Kind = "Gown", Color = rgb(250, 248, 244), Sheer = true },
			{ Kind = "Necklace", Color = GOLD },
		},
	},
}

-- Colores «de resumen» (muestras de la interfaz y el modo de colores del aspecto de siempre)
local byKey: { [string]: { [string]: any } } = {}
for _, def in list do
	def.Colors = {
		Hoodie = def.Top.Color,
		HoodLining = def.Top.Trim or def.Top.Color,
		Tee = def.Top.Inner or def.Top.Color,
		Pants = def.Bottom.Color,
		Shoes = def.Shoes.Color,
	}
	byKey[def.Key] = def
end

Outfits.List = list

function Outfits.get(key: any): { [string]: any }?
	return if type(key) == "string" then byKey[key] else nil
end

-- ¿Está el conjunto del pase guardado ahora (de servicio con uniforme o en prisión)?
function Outfits.suspended(player: any): boolean
	if not player then
		return false
	end
	local ok, result = pcall(function()
		local job = player:GetAttribute("Job")
		return (type(job) == "string" and Outfits.SuspendJobs[job] == true) or player:GetAttribute("JailUntil") ~= nil
	end)
	return ok and result == true
end

return Outfits
