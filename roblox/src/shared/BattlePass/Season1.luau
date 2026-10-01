-- Temporada 1 del pase: «Luces de Valmar».
-- SOLO DATOS: recompensas (50 niveles, gratis + premium), misiones, historia de temporada, eventos
-- y la tiendecita de fichas. La lógica está en server/Services/BattlePass*.
--
-- Temática: la ciudad que no se apaga. De la verbena de Playa Dorada a las torres del Distrito
-- Financiero, pasando por el puerto, el Monte del Silencio y el faro. La recompensa final (nivel 50
-- premium) es el conjunto legendario «Faro de Valmar» (con el superdeportivo Aurora X «Faro de Valmar»).
-- Vehículos premium (shared/PremiumVehicles): 11 en la pista premium (4, 12, 16, 24, 28, 32, 36, 39,
-- 42, 44 y 49), el Kairo S gratis en el 25 y el Aurora X dentro del conjunto del 50.
-- Conjuntos de ropa (shared/Outfits, los 30 de la hoja): 24 sueltos en la pista premium, Neon en el
-- conjunto del 20, Ángel en el del 50 y 4 en la gratis (9, 22, 35 y 41).
--
-- Para una temporada nueva: copia este archivo como Season2.luau, cambia Id, fechas, GamePassId,
-- recompensas y misiones, y añádelo a la lista Seasons de BattlePass/Config.
--
-- Campos de cada recompensa (los lee la interfaz; ver docs/pase-de-temporada.md, «Contrato»):
--   Id (único y para siempre: lo que se guarda), Level, Track (Free/Premium), Type, Name,
--   Description, Icon (emoji o nombre de icono), Rarity (Comun/Rara/Epica/Legendaria)
--   + lo propio de su tipo (Amount, Kind, Color…) y Preview (vista previa 3D).
-- NUNCA cambies el Id de una recompensa ya publicada (los jugadores la tienen guardada con ese Id).

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local rewards = {}
-- (atajo para escribir la tabla: añade una fila)
local function add(level: number, track: string, row: { [string]: any })
	row.Level = level
	row.Track = track
	row.Id = row.Id or ("S1_%s%02d"):format(if track == "Free" then "F" else "P", level)
	row.Rarity = row.Rarity or "Comun"
	table.insert(rewards, row)
end
local F, P = "Free", "Premium"

-- Los 13 vehículos premium (shared/PremiumVehicles: 5 deportivos, 5 superdeportivos y 3 motos). Son
-- un «Coche» o una «Moto» del juego con su propio diseño (Model): corren y giran igual que los que se
-- compran con dinero del juego. Uno (Kairo S) está en la pista gratis; el Aurora X va en el conjunto
-- legendario del nivel 50 con el acabado «Faro de Valmar».
local PremiumVehicles = require(script.Parent.Parent.PremiumVehicles)
local SAME_PERFORMANCE = {
	Coche = "Corre y gira igual que cualquier coche (sin pagar para ganar): se nota en el diseño, las luces y el sonido. Para conducirlo, la edad y el carnet B de siempre.",
	Moto = "Corre y gira igual que cualquier moto (sin pagar para ganar): se nota en el diseño, las luces y el sonido. Para conducirla, la edad y el carnet A de siempre.",
}
local function vehicleReward(id: string, extra: { [string]: any }?): { [string]: any }
	local v = PremiumVehicles.get(id)
	assert(v, "vehículo premium desconocido: " .. id)
	local row: { [string]: any } = {
		Type = "VehicleSkin",
		Name = v.Name,
		Icon = if v.Kind == "Moto" then "🏍️" else "🏎️",
		Kind = v.Kind,
		Model = id,
		Class = v.Class,
		Rarity = v.Rarity,
		GrantsBase = true,
		Premium = true,
		Color = rgb(v.Paint[1], v.Paint[2], v.Paint[3]),
		Material = "SmoothPlastic",
		Stats = table.clone(v.Stats),
		Description = (if extra and extra.Intro then extra.Intro else "") .. v.Blurb .. " " .. SAME_PERFORMANCE[v.Kind],
		Preview = { Kind = "Vehicle", Vehicle = v.Kind, Premium = id },
	}
	for key, value in extra or {} do
		if key ~= "Intro" then
			row[key] = value
		end
	end
	return row
end
local function vehicle(level: number, track: string, id: string, extra: { [string]: any }?)
	add(level, track, vehicleReward(id, extra))
end

-- Los 30 conjuntos de ropa de la hoja (shared/Outfits; los viste shared/OutfitBuilder). Id fijo por
-- conjunto ("S1_O05"), salga en el nivel que salga. 26 en la pista premium (uno, el Ángel, dentro del
-- conjunto legendario del 50 y otro, Neon, en el del 20) y 4 raros en la gratis (9, 22, 35 y 41).
-- Los tres «Estilo …» de oficios son solo ropa: no dan el trabajo ni sus permisos.
local Outfits = require(script.Parent.Parent.Outfits)
local function outfitReward(key: string, extra: { [string]: any }?): { [string]: any }
	local o = Outfits.get(key)
	assert(o, "conjunto desconocido: " .. key)
	local row: { [string]: any } = {
		Id = "S1_" .. key,
		Type = "Outfit",
		Name = o.Name,
		Icon = o.Icon,
		Rarity = o.Rarity,
		Outfit = key,
		Costume = o.Costume,
		Colors = table.clone(o.Colors),
		Description = o.Description,
		Preview = { Kind = "Outfit", Outfit = key },
	}
	for k, value in extra or {} do
		row[k] = value
	end
	return row
end
local function outfit(level: number, track: string, key: string)
	add(level, track, outfitReward(key))
end

-- Nivel 1-10 ----------------------------------------------------------------
add(1, F, { Type = "Title", Name = "Vecino/a de Valmar", Icon = "🏙️", Text = "Vecino/a de Valmar", Color = rgb(230, 230, 235),
	Description = "Tu primer título de temporada. Se ve junto a tu nombre." })
outfit(1, P, "O01")
add(2, F, { Type = "Money", Name = "150 €", Icon = "💶", Amount = 150, Description = "Un pequeño empujón para empezar." })
add(2, P, { Type = "Emote", Name = "Saludo del faro", Icon = "🗼", Rarity = "Rara", AnimationId = 3344650532, Loop = false,
	Description = "Un saludo amplio, como la luz del faro barriendo el puerto.", Preview = { Kind = "Emote" } })
add(3, F, { Type = "Decor", Name = "Planta de Villaverde", Icon = "🪴", Shape = "Plant", Size = Vector3.new(1.4, 3, 1.4), Color = rgb(70, 140, 70),
	Description = "Una planta de la cooperativa de Villaverde para tu casa.", Preview = { Kind = "Decor" } })
add(3, P, { Type = "PhoneTheme", Name = "Neón del Centro", Icon = "📱", Rarity = "Rara", Colors = { Background = rgb(18, 14, 40), Accent = rgb(255, 64, 160), Text = rgb(240, 240, 255) },
	Description = "El teléfono y los menús con los carteles de neón de Valmar Centro." })
add(4, F, { Type = "Tickets", Name = "40 tickets", Icon = "🎟️", Amount = 40, Description = "Para los premios de los recreativos." })
vehicle(4, P, "VoltexGTR")
add(5, F, { Type = "Wearable", Name = "Gafas de sol", Icon = "🕶️", Kind = "Gafas", Rarity = "Rara",
	Description = "Las gafas de los recreativos, gratis. Si ya las tienes, te damos 80 tickets.", Fallback = { Type = "Tickets", Amount = 80 } })
add(5, P, { Type = "VehicleSkin", Name = "Patinete Brisa Marina", Icon = "🛴", Kind = "Patinete", Rarity = "Epica", GrantsBase = true,
	Color = rgb(80, 200, 210), Material = "SmoothPlastic",
	Description = "Turquesa con detalles blancos. Mismas prestaciones que cualquier patinete: solo cambia el estilo.",
	Preview = { Kind = "Vehicle", Vehicle = "Patinete" } })
add(6, F, { Type = "CharacterXp", Name = "+150 XP de personaje", Icon = "⭐", Amount = 150, Description = "Experiencia para tu personaje." })
outfit(6, P, "O02")
add(7, F, { Type = "Emote", Name = "Aplauso de la plaza", Icon = "👏", AnimationId = 507770677, Loop = false,
	Description = "Aplaude como en las fiestas de la Plaza del Centro.", Preview = { Kind = "Emote" } })
outfit(7, P, "O04")
add(8, F, { Type = "Money", Name = "200 €", Icon = "💶", Amount = 200, Description = "Para un café en la Cafetería Central (o unos cuantos)." })
add(8, P, { Type = "HudSkin", Name = "HUD Noche de Valmar", Icon = "🌃", Rarity = "Rara", Colors = { Panel = rgb(16, 20, 40), Accent = rgb(90, 160, 255), Text = rgb(235, 240, 255) },
	Description = "La interfaz en azul noche." })
outfit(9, F, "O05")
outfit(9, P, "O11")
add(10, F, { Type = "Nameplate", Name = "Placa Valmar Clásica", Icon = "🏷️", Rarity = "Rara", Colors = { Background = rgb(40, 90, 150), Stroke = rgb(255, 255, 255), Text = rgb(255, 255, 255) },
	Description = "El azul de los carteles de la ciudad." })
outfit(10, P, "O13")

-- Nivel 11-20 ---------------------------------------------------------------
add(11, F, { Type = "Tickets", Name = "60 tickets", Icon = "🎟️", Amount = 60, Description = "Más partidas en los recreativos." })
add(11, P, { Type = "Emote", Name = "Baile de verbena", Icon = "💃", Rarity = "Rara", AnimationId = 507777268, Loop = true, Speed = 1.15,
	Description = "El baile de la verbena de Playa Dorada.", Preview = { Kind = "Emote" } })
add(12, F, { Type = "Title", Name = "Madrugador/a", Icon = "🌄", Text = "Madrugador/a", Color = rgb(255, 220, 140),
	Description = "Para quien abre Valmar antes que nadie." })
vehicle(12, P, "NexusR")
add(13, F, { Type = "Money", Name = "250 €", Icon = "💶", Amount = 250, Description = "Un pequeño ahorro." })
outfit(13, P, "O18")
add(14, F, { Type = "Decor", Name = "Cojines de Los Pinos", Icon = "🛋️", Shape = "Cushion", Size = Vector3.new(1.6, 0.6, 1.6), Color = rgb(90, 130, 80),
	Description = "Cojines verdes con olor a pino.", Preview = { Kind = "Decor" } })
outfit(14, P, "O03")
add(15, F, { Type = "VehicleSkin", Name = "Bici Verde Villaverde", Icon = "🚲", Kind = "Bici", Rarity = "Rara", GrantsBase = true,
	Color = rgb(60, 150, 80),
	Description = "Una bici verde campo. Mismas prestaciones que cualquier bici.", Preview = { Kind = "Vehicle", Vehicle = "Bici" } })
add(15, P, { Type = "VehicleSkin", Name = "Moto Brisa de Playa Dorada", Icon = "🛵", Kind = "Moto", Rarity = "Epica", GrantsBase = true,
	Color = rgb(250, 190, 70), Material = "SmoothPlastic",
	Description = "Una moto color arena con franja turquesa. Corre igual que las demás: es cuestión de estilo. (Para conducirla necesitas la edad y el carnet A, como siempre).",
	Preview = { Kind = "Vehicle", Vehicle = "Moto" } })
add(16, F, { Type = "CharacterXp", Name = "+200 XP de personaje", Icon = "⭐", Amount = 200, Description = "Experiencia para tu personaje." })
vehicle(16, P, "Zenith")
add(17, F, { Type = "Emote", Name = "Estiramiento del parque", Icon = "🧘", AnimationId = 3334538554, Loop = false,
	Description = "Estírate como en las mañanas del parque.", Preview = { Kind = "Emote" } })
outfit(17, P, "O10")
add(18, F, { Type = "Money", Name = "250 €", Icon = "💶", Amount = 250, Description = "Un pequeño ahorro." })
outfit(18, P, "O07")
add(19, F, { Type = "PhoneTheme", Name = "Clásico de Valmar", Icon = "📱", Colors = { Background = rgb(235, 238, 245), Accent = rgb(40, 90, 150), Text = rgb(20, 25, 40) },
	Description = "Blanco y azul ciudad." })
outfit(19, P, "O15")
add(20, F, { Type = "Wearable", Name = "Gorra", Icon = "🧢", Kind = "Gorra", Rarity = "Rara",
	Description = "La gorra de los recreativos, gratis. Si ya la tienes, te damos 150 tickets.", Fallback = { Type = "Tickets", Amount = 150 } })
add(20, P, { Type = "Bundle", Name = "Colección Noche en el Centro", Icon = "🌆", Rarity = "Epica",
	Description = "El conjunto Neon (chaqueta negra con paneles flúor, cargo neón y gafas de ventisca) para salir de noche y un título a juego.",
	Items = {
		outfitReward("O26"),
		{ Id = "S1_P20_Title", Type = "Title", Name = "Noches del Centro", Icon = "🌆", Text = "Noches del Centro", Color = rgb(255, 90, 170) },
	},
	Preview = { Kind = "Outfit", Outfit = "O26" } })

-- Nivel 21-30 ---------------------------------------------------------------
add(21, F, { Type = "Tickets", Name = "80 tickets", Icon = "🎟️", Amount = 80, Description = "Más partidas en los recreativos." })
outfit(21, P, "O06")
outfit(22, F, "O14")
outfit(22, P, "O08")
add(23, F, { Type = "Title", Name = "Explorador/a de distritos", Icon = "🧭", Text = "Explorador/a de distritos", Color = rgb(140, 220, 160),
	Description = "Para quien ha pisado todos los barrios." })
outfit(23, P, "O17")
add(24, F, { Type = "HomeTheme", Name = "Piso luminoso de Valmar Norte", Icon = "🏠", Rarity = "Rara",
	Floor = rgb(225, 205, 170), FloorMaterial = "WoodPlanks", Wall = rgb(245, 243, 235), WallMaterial = "SmoothPlastic",
	Description = "Paredes claras y madera de roble para tu vivienda de siempre.", Preview = { Kind = "HomeTheme" } })
vehicle(24, P, "StratoRS")
vehicle(25, F, "KairoS", { Intro = "¡Un deportivo gratis para todo el mundo! " })
add(25, P, { Type = "HomeTheme", Name = "Ático Distrito Financiero", Icon = "🏙️", Rarity = "Epica",
	Floor = rgb(40, 40, 46), FloorMaterial = "Marble", Wall = rgb(210, 214, 222), WallMaterial = "SmoothPlastic",
	Description = "Mármol oscuro y paredes gris perla, como en las torres. Se aplica a tu vivienda (no es una casa nueva).",
	Preview = { Kind = "HomeTheme" } })
add(26, F, { Type = "CharacterXp", Name = "+250 XP de personaje", Icon = "⭐", Amount = 250, Description = "Experiencia para tu personaje." })
outfit(26, P, "O12")
add(27, F, { Type = "Emote", Name = "Foto de turista", Icon = "📸", AnimationId = 507770453, Loop = false,
	Description = "Señala el monumento y haz la foto.", Preview = { Kind = "Emote" } })
outfit(27, P, "O19")
add(28, F, { Type = "Decor", Name = "Estantería del Campus", Icon = "📚", Shape = "Shelf", Size = Vector3.new(3, 5, 1.2), Color = rgb(130, 90, 60),
	Description = "Llena de apuntes de la Universidad.", Preview = { Kind = "Decor" } })
vehicle(28, P, "Blaze1000")
add(29, F, { Type = "Tickets", Name = "100 tickets", Icon = "🎟️", Amount = 100, Description = "Más partidas en los recreativos." })
outfit(29, P, "O23")
add(30, F, { Type = "Nameplate", Name = "Placa Temporada 1", Icon = "🏷️", Rarity = "Rara", Colors = { Background = rgb(28, 36, 72), Stroke = rgb(255, 196, 64), Text = rgb(255, 255, 255) },
	Description = "La placa de la primera temporada." })
add(30, P, { Type = "Perk", Name = "Cambio de misión diaria", Icon = "🔄", Rarity = "Epica", Perk = "RerollDaily",
	Description = "Una vez al día puedes cambiar una misión diaria que no te apetezca por otra. No da más XP: solo elige." })

-- Nivel 31-40 ---------------------------------------------------------------
add(31, F, { Type = "Money", Name = "300 €", Icon = "💶", Amount = 300, Description = "Un pequeño ahorro." })
outfit(31, P, "O20")
add(32, F, { Type = "Title", Name = "Currante de Valmar", Icon = "🛠️", Text = "Currante de Valmar", Color = rgb(255, 200, 120),
	Description = "Para quien no falta a su turno." })
vehicle(32, P, "RavenT7")
add(33, F, { Type = "Decor", Name = "Alfombra de playa", Icon = "🏖️", Shape = "Rug", Size = Vector3.new(5, 0.1, 3), Color = rgb(80, 200, 210),
	Description = "Rayas de toalla de Playa Dorada.", Preview = { Kind = "Decor" } })
outfit(33, P, "O28")
add(34, F, { Type = "CharacterXp", Name = "+300 XP de personaje", Icon = "⭐", Amount = 300, Description = "Experiencia para tu personaje." })
outfit(34, P, "O09")
outfit(35, F, "O27")
add(35, P, { Type = "Boat", Name = "Lancha «Gaviota»", Icon = "🚤", Rarity = "Epica", Kind = "Lancha", Boat = "Gaviota", Color = rgb(245, 245, 250),
	Description = "Una lancha blanca y oro con cabina y tu nombre en la popa. Es tuya para siempre: sácala en el puerto deportivo (costa oeste) y navega con tus amigos. Mismas prestaciones que la lancha normal.",
	Preview = { Kind = "Boat" } })
add(36, F, { Type = "Tickets", Name = "120 tickets", Icon = "🎟️", Amount = 120, Description = "Más partidas en los recreativos." })
vehicle(36, P, "Inferno")
add(37, F, { Type = "Emote", Name = "Saludo marinero", Icon = "⚓", AnimationId = 3333474484, Loop = false, Speed = 0.8,
	Description = "El saludo de la gente del puerto.", Preview = { Kind = "Emote" } })
outfit(37, P, "O16")
add(38, F, { Type = "Money", Name = "350 €", Icon = "💶", Amount = 350, Description = "Un pequeño ahorro." })
outfit(38, P, "O21")
add(39, F, { Type = "PhoneTheme", Name = "Mapa de Valmar", Icon = "🗺️", Rarity = "Rara", Colors = { Background = rgb(230, 225, 205), Accent = rgb(60, 120, 80), Text = rgb(40, 40, 35) },
	Description = "Tu teléfono con el plano de la ciudad." })
vehicle(39, P, "Obsidian")
add(40, F, { Type = "Title", Name = "Corazón de Valmar", Icon = "❤️", Text = "Corazón de Valmar", Color = rgb(255, 110, 120), Rarity = "Rara",
	Description = "Para quien hace ciudad cada día." })
add(40, P, { Type = "Bundle", Name = "Terraza del Faro", Icon = "🗼", Rarity = "Epica",
	Description = "Un tema de vivienda con vistas al mar y un farol a juego.",
	Items = {
		{ Id = "S1_P40_Theme", Type = "HomeTheme", Name = "Terraza del Faro", Icon = "🗼",
			Floor = rgb(230, 225, 215), FloorMaterial = "Slate", Wall = rgb(250, 250, 248), WallMaterial = "Plaster" },
		{ Id = "S1_P40_Decor", Type = "Decor", Name = "Farol del faro", Icon = "🏮", Shape = "Lamp", Size = Vector3.new(1.2, 4, 1.2), Color = rgb(255, 230, 150), Light = true },
	},
	Preview = { Kind = "HomeTheme" } })

-- Nivel 41-50 ---------------------------------------------------------------
outfit(41, F, "O24")
add(41, P, { Type = "Emote", Name = "Baile del faro", Icon = "💫", Rarity = "Epica", AnimationId = 507771019, Loop = true, Speed = 1.25,
	Description = "Gira como la luz del faro.", Preview = { Kind = "Emote" } })
add(42, F, { Type = "Money", Name = "350 €", Icon = "💶", Amount = 350, Description = "Un pequeño ahorro." })
vehicle(42, P, "Storm")
add(43, F, { Type = "Tickets", Name = "150 tickets", Icon = "🎟️", Amount = 150, Description = "Más partidas en los recreativos." })
outfit(43, P, "O25")
add(44, F, { Type = "CharacterXp", Name = "+350 XP de personaje", Icon = "⭐", Amount = 350, Description = "Experiencia para tu personaje." })
vehicle(44, P, "ViboraGT")
add(45, F, { Type = "Nameplate", Name = "Placa Plata", Icon = "🥈", Rarity = "Epica", Colors = { Background = rgb(180, 185, 195), Stroke = rgb(80, 85, 95), Text = rgb(20, 20, 25) },
	Description = "Una placa de plata para veteranos de la temporada." })
outfit(45, P, "O22")
add(46, F, { Type = "Emote", Name = "Reverencia", Icon = "🙇", AnimationId = 507770239, Loop = false, Speed = 0.7,
	Description = "Una reverencia para despedirte con estilo.", Preview = { Kind = "Emote" } })
add(46, P, { Type = "Story", Name = "Postal: la noche del faro", Icon = "💌", Rarity = "Rara",
	Text = "«La noche en que se fue la luz en toda Valmar, solo el faro siguió encendido. Dicen que alguien subió a arreglarlo… y que ese alguien eras tú.»",
	Description = "Un recuerdo de la temporada para tu colección." })
add(47, F, { Type = "Money", Name = "400 €", Icon = "💶", Amount = 400, Description = "Un pequeño ahorro." })
add(47, P, { Type = "HudSkin", Name = "HUD Leyenda", Icon = "🏆", Rarity = "Epica", Colors = { Panel = rgb(20, 16, 30), Accent = rgb(255, 210, 90), Text = rgb(255, 250, 235) },
	Description = "La interfaz de quien ha llegado lejos." })
add(48, F, { Type = "Decor", Name = "Trofeo de la temporada", Icon = "🏆", Shape = "Trophy", Size = Vector3.new(1, 2, 1), Color = rgb(200, 205, 215), Material = "Metal",
	Description = "Para la estantería.", Preview = { Kind = "Decor" } })
outfit(48, P, "O29")
add(49, F, { Type = "Tokens", Name = "3 fichas de temporada", Icon = "🪙", Amount = 3, Description = "Para la tienda de fichas (solo cosméticos)." })
vehicle(49, P, "ShadowF1")
add(50, F, { Type = "Bundle", Name = "Recuerdo de la Temporada 1", Icon = "🎖️", Rarity = "Epica",
	Description = "Has llegado al final: un título y una placa conmemorativa para tu casa.",
	Items = {
		{ Id = "S1_F50_Title", Type = "Title", Name = "Veterano/a · Temporada 1", Icon = "🎖️", Text = "Veterano/a · Temporada 1", Color = rgb(200, 220, 255) },
		{ Id = "S1_F50_Decor", Type = "Decor", Name = "Placa conmemorativa", Icon = "🎖️", Shape = "Poster", Size = Vector3.new(2, 1.4, 0.2), Color = rgb(200, 170, 90), Material = "Metal" },
	} })
add(50, P, { Type = "Bundle", Name = "Faro de Valmar", Icon = "🗼", Rarity = "Legendaria",
	Description = "La recompensa legendaria de la temporada: el superdeportivo Aurora X «Faro de Valmar» (blanco perla con negro y detalles en oro), el conjunto Ángel (alas con brillo suave y aureola dorada), el título «Leyenda de Valmar», su placa y un faro en miniatura para tu casa. Corre igual que cualquier coche: se nota en el estilo, no en la carrera.",
	Items = {
		vehicleReward("AuroraX", { Id = "S1_P50_Car", Name = "Aurora X «Faro de Valmar»", Color = rgb(245, 242, 232), Trim = rgb(255, 196, 64) }),
		{ Id = "S1_P50_Title", Type = "Title", Name = "Leyenda de Valmar", Icon = "🗼", Text = "Leyenda de Valmar", Color = rgb(255, 210, 90) },
		{ Id = "S1_P50_Plate", Type = "Nameplate", Name = "Placa Faro", Icon = "🗼",
			Colors = { Background = rgb(245, 242, 232), Stroke = rgb(255, 196, 64), Text = rgb(28, 36, 72) } },
		{ Id = "S1_P50_Decor", Type = "Decor", Name = "Faro en miniatura", Icon = "🗼", Shape = "Lighthouse", Size = Vector3.new(1.2, 4, 1.2), Color = rgb(245, 245, 245), Light = true },
		outfitReward("O30"),
	},
	Preview = { Kind = "Vehicle", Vehicle = "Coche", Color = rgb(245, 242, 232) } })

---------------------------------------------------------------------
-- Misiones
---------------------------------------------------------------------
-- Events: nombres de StoryEvents (lo que ya avisan los sistemas del juego) que hacen avanzar la misión.
-- Measure: Count (cada evento suma 1), Km (suma los km), Distinct (valores distintos de
-- DistinctField), DistinctEvent (tipos de evento distintos). Match: el evento tiene que traer esos campos.
-- MinStage: edad mínima para que te toque (a un niño no le tocan misiones de trabajo).
-- Place: sitio de LifeStory/Locations para el GPS (opcional).
local TRANSPORT = { "RodeMetro", "RodeTrain", "BusRide", "Flew", "Traveled" }

local daily = {
	{ Id = "D_Turno", Title = "Un turno de trabajo", Description = "Completa 8 tareas en cualquier oficio.", Icon = "💼", Events = { "JobTaskDone" }, Goal = 8, Xp = 150, MinStage = "Adolescente" },
	{ Id = "D_Metro", Title = "Viaja en metro", Description = "Haz 2 viajes en el metro de Valmar.", Icon = "🚇", Events = { "RodeMetro" }, Goal = 2, Xp = 150, MinStage = "Nino", Place = "MetroBoca" },
	{ Id = "D_Bus", Title = "Coge el autobús", Description = "Súbete al autobús urbano.", Icon = "🚌", Events = { "BusRide" }, Goal = 1, Xp = 120, MinStage = "Nino", Place = "ParadaBus" },
	{ Id = "D_Compras", Title = "De compras", Description = "Compra 2 cosas en cualquier tienda.", Icon = "🛍️", Events = { "BoughtItem", "SupermarketPurchase" }, Goal = 2, Xp = 120, MinStage = "Nino", Place = "CentroComercial" },
	{ Id = "D_Comer", Title = "Comer bien", Description = "Come 2 veces (en casa, en el comedor o fuera).", Icon = "🍽️", Events = { "Ate" }, Goal = 2, Xp = 100, MinStage = "Nino" },
	{ Id = "D_Conducir", Title = "Al volante", Description = "Recorre 2 km en un vehículo (bici, patinete, moto o coche).", Icon = "🚲", Events = { "VehicleTrip" }, Measure = "Km", Goal = 2, Xp = 150, MinStage = "Nino" },
	{ Id = "D_Encargo", Title = "Echa una mano", Description = "Termina un encargo de un vecino (los que tienen ❗).", Icon = "❗", Events = { "ErrandDone" }, Goal = 1, Xp = 150, MinStage = "Nino" },
	{ Id = "D_Gimnasio", Title = "Día de gimnasio", Description = "Haz 5 series en un gimnasio.", Icon = "🏋️", Events = { "GymSet" }, Goal = 5, Xp = 130, MinStage = "Adolescente" },
	{ Id = "D_Pesca", Title = "Día de pesca", Description = "Pesca 3 peces.", Icon = "🎣", Events = { "CaughtFish" }, Goal = 3, Xp = 130, MinStage = "Nino", Place = "Playa" },
	{ Id = "D_Estudio", Title = "A estudiar", Description = "Termina una clase, un examen o un rato de estudio.", Icon = "📘", Events = { "LessonCompleted", "ExamGraded", "Studied", "PracticeDone" }, Goal = 1, Xp = 150, MinStage = "Nino" },
	{ Id = "D_Cine", Title = "Tarde de cine", Description = "Mira una película en el cine.", Icon = "🎬", Events = { "WatchedMovie" }, Goal = 1, Xp = 120, MinStage = "Nino", Place = "Ocio" },
	{ Id = "D_Recreativos", Title = "Recreativos", Description = "Juega 2 partidas en los recreativos.", Icon = "🕹️", Events = { "ArcadePlayed" }, Goal = 2, Xp = 110, MinStage = "Nino", Place = "Ocio" },
}

local weekly = {
	{ Id = "W_Turnos", Title = "Semana de trabajo", Description = "Completa 40 tareas de trabajo (unos 5 turnos).", Icon = "💼", Events = { "JobTaskDone" }, Goal = 40, Xp = 600, MinStage = "Adolescente" },
	{ Id = "W_Historia", Title = "Tu historia sigue", Description = "Completa 3 misiones de tu historia de vida.", Icon = "📖", Events = { "QuestDone" }, Goal = 3, Xp = 600, MinStage = "Nino" },
	{ Id = "W_Distritos", Title = "Recorre Valmar", Description = "Visita 3 barrios distintos.", Icon = "🧭", Events = { "ZoneEntered" }, Measure = "Distinct", DistinctField = "Zone", Goal = 3, Xp = 500, MinStage = "Nino" },
	{ Id = "W_Transportes", Title = "Muévete en transporte", Description = "Usa 2 transportes públicos distintos (metro, bus, tren, avión…).", Icon = "🚉", Events = TRANSPORT, Measure = "DistinctEvent", Goal = 2, Xp = 500, MinStage = "Nino" },
	{ Id = "W_Estudios", Title = "Semana de estudio", Description = "Termina 3 clases, exámenes o ratos de estudio.", Icon = "🎓", Events = { "LessonCompleted", "ExamGraded", "Studied", "PracticeDone" }, Goal = 3, Xp = 500, MinStage = "Nino", Place = "Universidad" },
	{ Id = "W_Encargos", Title = "Buen vecino", Description = "Termina 3 encargos de los vecinos.", Icon = "🤝", Events = { "ErrandDone" }, Goal = 3, Xp = 500, MinStage = "Nino" },
	{ Id = "W_Kilometros", Title = "Carretera y manta", Description = "Recorre 10 km en vehículo.", Icon = "🛣️", Events = { "VehicleTrip" }, Measure = "Km", Goal = 10, Xp = 500, MinStage = "Nino" },
	{ Id = "W_Ocio", Title = "Tiempo libre", Description = "Haz 6 cosas de ocio: cine, recreativos, pesca o gimnasio.", Icon = "🎉", Events = { "WatchedMovie", "ArcadePlayed", "CaughtFish", "GymSet" }, Goal = 6, Xp = 450, MinStage = "Nino" },
}

-- Misiones de toda la temporada (se hacen a tu ritmo en las 9 semanas)
local season = {
	{ Id = "S_Barrios", Title = "Todos los barrios", Description = "Visita los 8 barrios de la región de Valmar.", Icon = "🗺️", Events = { "ZoneEntered" }, Measure = "Distinct", DistinctField = "Zone", Goal = 8, Xp = 1500, Tokens = 1 },
	{ Id = "S_Trabajo", Title = "La ciudad funciona gracias a ti", Description = "Completa 150 tareas de trabajo.", Icon = "🏗️", Events = { "JobTaskDone" }, Goal = 150, Xp = 2000, MinStage = "Adolescente", Tokens = 1 },
	{ Id = "S_Viajero", Title = "Viajero/a de Valmar", Description = "Haz 25 viajes en transporte público.", Icon = "🚉", Events = TRANSPORT, Goal = 25, Xp = 1200 },
	{ Id = "S_Gaviotas", Title = "Rumbo a las Gaviotas", Description = "Vuela a la Isla de las Gaviotas.", Icon = "✈️", Events = { "Flew" }, Goal = 1, Xp = 800, MinStage = "Nino", Place = "Aeropuerto" },
	{ Id = "S_Historia", Title = "Capítulos de tu vida", Description = "Completa 10 misiones de tu historia de vida.", Icon = "📖", Events = { "QuestDone" }, Goal = 10, Xp = 1500, Tokens = 1 },
	{ Id = "S_Pescador", Title = "Lonja llena", Description = "Pesca 25 peces.", Icon = "🐟", Events = { "CaughtFish" }, Goal = 25, Xp = 1000 },
	{ Id = "S_Kilometros", Title = "Kilómetros de Valmar", Description = "Recorre 40 km en vehículo.", Icon = "🛣️", Events = { "VehicleTrip" }, Measure = "Km", Goal = 40, Xp = 1200 },
	{ Id = "S_Vecinos", Title = "Valmar te lo agradece", Description = "Termina 15 encargos de los vecinos.", Icon = "💛", Events = { "ErrandDone" }, Goal = 15, Xp = 1200 },
}

-- Historia de temporada: «Se apaga el faro». Fases en orden; cada una usa sistemas de verdad del juego
-- (ir a un barrio, coger el metro, trabajar, hablar con alguien…). La última es una decisión.
local story = {
	Id = "H_Faro",
	Title = "Se apaga el faro",
	Icon = "🗼",
	Intro = "📨 Mensaje del Ayuntamiento de Valmar: «El faro del puerto parpadea cada noche y nadie sabe por qué. Buscamos voluntarios.»",
	Phases = {
		{ Id = "H1", Title = "El aviso", Text = "Ve a la Plaza del Centro: allí cuelgan el bando del Ayuntamiento.", Events = { "ZoneEntered" }, Match = { Zone = "Valmar Centro" }, Goal = 1, Xp = 250, Place = "PlazaCentro" },
		{ Id = "H2", Title = "Preguntar por ahí", Text = "Habla con cualquier vecino o personaje de la ciudad: alguien habrá visto algo.", Events = { "Talk", "TalkDone" }, Goal = 1, Xp = 250 },
		{ Id = "H3", Title = "El técnico del metro", Text = "Dicen que un técnico del metro sabe de cables: coge el metro.", Events = { "RodeMetro" }, Goal = 1, Xp = 300, Place = "MetroBoca" },
		{ Id = "H4", Title = "Cables y turnos", Text = "Para pagar las piezas hace falta dinero: haz 5 tareas de trabajo (o 2 encargos si aún no trabajas).", Events = { "JobTaskDone", "ErrandDone" }, Goal = 5, Xp = 350 },
		{ Id = "H5", Title = "La pista de la playa", Text = "La última persona que subió al faro vive cerca de Playa Dorada. Ve hasta allí.", Events = { "ZoneEntered" }, Match = { Zone = "Playa Dorada" }, Goal = 1, Xp = 300, Place = "Playa" },
		{ Id = "H6", Title = "Desde lo alto", Text = "Desde el Monte del Silencio se ve el faro entero: sube a mirar (o visita Los Pinos o Villaverde).", Events = { "ZoneEntered" }, Match = { Zone = { "Villaverde", "Los Pinos" } }, Goal = 1, Xp = 300, Place = "MonteSilencio" },
		{ Id = "H7", Title = "¿Qué hacemos con el faro?", Text = "Ya sabes qué le pasa al faro. Decide:", Choices = {
			{ Id = "Arreglar", Text = "Arreglarlo como siempre fue", Result = "El faro vuelve a girar como hace cien años. Los pescadores te saludan desde el muelle.", Xp = 500 },
			{ Id = "Modernizar", Text = "Ponerle luces nuevas de colores", Result = "Esta noche el faro pinta el mar de colores. Toda Valmar sale a verlo.", Xp = 500 },
		} },
	},
	Tokens = 1,
	-- Título de recuerdo por terminar la historia (es de la temporada: no está en la tabla de niveles)
	Reward = { Id = "S1_Story_Title", Type = "Title", Name = "Guardián/a del faro", Icon = "🗼", Text = "Guardián/a del faro", Color = rgb(255, 220, 120), Rarity = "Rara",
		Description = "Por devolverle la luz al faro de Valmar." },
}

-- Eventos de la temporada: mientras duran, la XP de actividad sube un poco (tope en Config) y hay
-- una misión diaria extra del evento.
local events = {
	{ Id = "E_Verbena", Name = "Verbena de Playa Dorada", Icon = "🎆", StartsAt = 1792195200, EndsAt = 1792368000, XpMultiplier = 1.25,
		Mission = { Id = "EV_Verbena", Title = "Noche de verbena", Description = "Visita Playa Dorada y baila (o come algo) en la verbena.", Icon = "🎆", Events = { "ZoneEntered" }, Match = { Zone = "Playa Dorada" }, Goal = 1, Xp = 200, Place = "Playa" } },
	{ Id = "E_Luces", Name = "Noche de las Luces", Icon = "✨", StartsAt = 1795132800, EndsAt = 1795392000, XpMultiplier = 1.25,
		Mission = { Id = "EV_Luces", Title = "Las luces del Centro", Description = "Pásate por Valmar Centro durante la Noche de las Luces.", Icon = "✨", Events = { "ZoneEntered" }, Match = { Zone = "Valmar Centro" }, Goal = 1, Xp = 200, Place = "PlazaCentro" } },
}

-- Tienda de fichas (solo cosméticos; las fichas salen de misiones de temporada y de la XP después del
-- nivel 50). Cada artículo se compra una vez.
local tokenShop = {
	{ Id = "S1_T_Title", Type = "Title", Name = "Luz de Valmar", Icon = "💡", Text = "Luz de Valmar", Color = rgb(255, 240, 160), Rarity = "Rara", Cost = 3,
		Description = "Un título para quien sigue jugando después del nivel 50." },
	{ Id = "S1_T_Plate", Type = "Nameplate", Name = "Placa Noche Estrellada", Icon = "🌠", Rarity = "Rara", Cost = 4,
		Colors = { Background = rgb(12, 14, 36), Stroke = rgb(200, 210, 255), Text = rgb(255, 255, 255) }, Description = "Estrellas alrededor de tu nombre." },
	{ Id = "S1_T_Decor", Type = "Decor", Name = "Globo terráqueo", Icon = "🌍", Shape = "Ball", Size = Vector3.new(1.4, 1.4, 1.4), Color = rgb(80, 150, 220), Rarity = "Rara", Cost = 3,
		Description = "Para soñar con viajes." },
	{ Id = "S1_T_Phone", Type = "PhoneTheme", Name = "Carbón", Icon = "📱", Rarity = "Comun", Cost = 2,
		Colors = { Background = rgb(28, 28, 30), Accent = rgb(200, 200, 205), Text = rgb(240, 240, 240) }, Description = "Sobrio y elegante." },
}

return {
	Id = "S1",
	Number = 1,
	Name = "Luces de Valmar",
	Subtitle = "Temporada 01",
	Theme = "La ciudad que no se apaga: de la verbena de Playa Dorada a las torres del Distrito Financiero.",
	-- Fechas en hora UTC (segundos desde 1970). 1-oct-2026 00:00 UTC (empieza ya, decisión del dueño) → 7-dic-2026 00:00 UTC
	StartsAt = 1790812800,
	EndsAt = 1796601600,
	MaxLevel = 50,
	-- XP para pasar del nivel n al n+1 = Base + Step × (n − 1). Total hasta el 50: 77.420 XP.
	Xp = { Base = 1100, Step = 20 },
	-- Game Pass de ESTA temporada (cada temporada tiene el suyo: un Game Pass es para siempre).
	-- 0 = compra desactivada: la interfaz enseña «Próximamente».
	GamePassId = 0,
	Colors = { Primary = rgb(28, 36, 72), Accent = rgb(255, 196, 64), Text = rgb(245, 245, 250) },
	Rewards = rewards,
	Missions = {
		Daily = daily,
		DailyCount = 3,
		Weekly = weekly,
		WeeklyCount = 5,
		Season = season,
		Story = { story },
	},
	Events = events,
	TokenShop = tokenShop,
}
