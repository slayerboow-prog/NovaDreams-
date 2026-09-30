-- Temporada 1 del pase: «Luces de Valmar».
-- SOLO DATOS: recompensas (50 niveles, gratis + premium), misiones, historia de temporada, eventos
-- y la tiendecita de fichas. La lógica está en server/Services/BattlePass*.
--
-- Temática: la ciudad que no se apaga. De la verbena de Playa Dorada a las torres del Distrito
-- Financiero, pasando por el puerto, el Monte del Silencio y el faro. La recompensa final (nivel 50
-- premium) es el conjunto legendario «Faro de Valmar».
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

-- Nivel 1-10 ----------------------------------------------------------------
add(1, F, { Type = "Title", Name = "Vecino/a de Valmar", Icon = "🏙️", Text = "Vecino/a de Valmar", Color = rgb(230, 230, 235),
	Description = "Tu primer título de temporada. Se ve junto a tu nombre." })
add(1, P, { Type = "Outfit", Name = "Chaqueta Luces de Valmar", Icon = "🧥", Rarity = "Rara",
	Colors = { Hoodie = rgb(28, 36, 72), HoodLining = rgb(255, 196, 64), Tee = rgb(245, 245, 250), Pants = rgb(30, 32, 40), Shoes = rgb(255, 196, 64) },
	Description = "Azul noche con forro dorado, como las farolas del paseo.", Preview = { Kind = "Outfit" } })
add(2, F, { Type = "Money", Name = "150 €", Icon = "💶", Amount = 150, Description = "Un pequeño empujón para empezar." })
add(2, P, { Type = "Emote", Name = "Saludo del faro", Icon = "🗼", Rarity = "Rara", AnimationId = 3344650532, Loop = false,
	Description = "Un saludo amplio, como la luz del faro barriendo el puerto.", Preview = { Kind = "Emote" } })
add(3, F, { Type = "Decor", Name = "Planta de Villaverde", Icon = "🪴", Shape = "Plant", Size = Vector3.new(1.4, 3, 1.4), Color = rgb(70, 140, 70),
	Description = "Una planta de la cooperativa de Villaverde para tu casa.", Preview = { Kind = "Decor" } })
add(3, P, { Type = "PhoneTheme", Name = "Neón del Centro", Icon = "📱", Rarity = "Rara", Colors = { Background = rgb(18, 14, 40), Accent = rgb(255, 64, 160), Text = rgb(240, 240, 255) },
	Description = "El teléfono y los menús con los carteles de neón de Valmar Centro." })
add(4, F, { Type = "Tickets", Name = "40 tickets", Icon = "🎟️", Amount = 40, Description = "Para los premios de los recreativos." })
add(4, P, { Type = "Money", Name = "200 €", Icon = "💶", Amount = 200, Description = "Un extra pequeño." })
add(5, F, { Type = "Wearable", Name = "Gafas de sol", Icon = "🕶️", Kind = "Gafas", Rarity = "Rara",
	Description = "Las gafas de los recreativos, gratis. Si ya las tienes, te damos 80 tickets.", Fallback = { Type = "Tickets", Amount = 80 } })
add(5, P, { Type = "VehicleSkin", Name = "Patinete Brisa Marina", Icon = "🛴", Kind = "Patinete", Rarity = "Epica", GrantsBase = true,
	Color = rgb(80, 200, 210), Material = "SmoothPlastic",
	Description = "Turquesa con detalles blancos. Mismas prestaciones que cualquier patinete: solo cambia el estilo.",
	Preview = { Kind = "Vehicle", Vehicle = "Patinete" } })
add(6, F, { Type = "CharacterXp", Name = "+150 XP de personaje", Icon = "⭐", Amount = 150, Description = "Experiencia para tu personaje." })
add(6, P, { Type = "Decor", Name = "Lámpara de pie Altamar", Icon = "💡", Shape = "Lamp", Size = Vector3.new(1.2, 5, 1.2), Color = rgb(240, 200, 120), Light = true, Rarity = "Rara",
	Description = "Luz cálida como la de las torres de noche.", Preview = { Kind = "Decor" } })
add(7, F, { Type = "Emote", Name = "Aplauso de la plaza", Icon = "👏", AnimationId = 507770677, Loop = false,
	Description = "Aplaude como en las fiestas de la Plaza del Centro.", Preview = { Kind = "Emote" } })
add(7, P, { Type = "Nameplate", Name = "Placa Atardecer", Icon = "🌅", Rarity = "Rara", Colors = { Background = rgb(255, 140, 80), Stroke = rgb(120, 40, 60), Text = rgb(255, 255, 255) },
	Description = "El marco de tu nombre con los colores del atardecer en Playa Dorada." })
add(8, F, { Type = "Money", Name = "200 €", Icon = "💶", Amount = 200, Description = "Para un café en la Cafetería Central (o unos cuantos)." })
add(8, P, { Type = "HudSkin", Name = "HUD Noche de Valmar", Icon = "🌃", Rarity = "Rara", Colors = { Panel = rgb(16, 20, 40), Accent = rgb(90, 160, 255), Text = rgb(235, 240, 255) },
	Description = "La interfaz en azul noche." })
add(9, F, { Type = "Decor", Name = "Póster del Estadio Altamar", Icon = "🖼️", Shape = "Poster", Size = Vector3.new(3, 4, 0.2), Color = rgb(200, 40, 50),
	Description = "El póster del último partido del Estadio Altamar.", Preview = { Kind = "Decor" } })
add(9, P, { Type = "Title", Name = "Alma de San Roque", Icon = "🏘️", Text = "Alma de San Roque", Color = rgb(255, 180, 90), Rarity = "Rara",
	Description = "Para quien conoce cada esquina de San Roque." })
add(10, F, { Type = "Nameplate", Name = "Placa Valmar Clásica", Icon = "🏷️", Rarity = "Rara", Colors = { Background = rgb(40, 90, 150), Stroke = rgb(255, 255, 255), Text = rgb(255, 255, 255) },
	Description = "El azul de los carteles de la ciudad." })
add(10, P, { Type = "HomeTheme", Name = "Loft del Puerto", Icon = "⚓", Rarity = "Epica",
	Floor = rgb(120, 86, 60), FloorMaterial = "WoodPlanks", Wall = rgb(70, 80, 95), WallMaterial = "Brick",
	Description = "Tu vivienda de siempre con ladrillo visto y madera de barco. Se aplica a la que tú elijas.",
	Preview = { Kind = "HomeTheme" } })

-- Nivel 11-20 ---------------------------------------------------------------
add(11, F, { Type = "Tickets", Name = "60 tickets", Icon = "🎟️", Amount = 60, Description = "Más partidas en los recreativos." })
add(11, P, { Type = "Emote", Name = "Baile de verbena", Icon = "💃", Rarity = "Rara", AnimationId = 507777268, Loop = true, Speed = 1.15,
	Description = "El baile de la verbena de Playa Dorada.", Preview = { Kind = "Emote" } })
add(12, F, { Type = "Title", Name = "Madrugador/a", Icon = "🌄", Text = "Madrugador/a", Color = rgb(255, 220, 140),
	Description = "Para quien abre Valmar antes que nadie." })
add(12, P, { Type = "Decor", Name = "Farol del muelle", Icon = "🏮", Shape = "Lamp", Size = Vector3.new(1, 4, 1), Color = rgb(40, 40, 45), Light = true, Rarity = "Rara",
	Description = "Un farol de hierro como los del puerto.", Preview = { Kind = "Decor" } })
add(13, F, { Type = "Money", Name = "250 €", Icon = "💶", Amount = 250, Description = "Un pequeño ahorro." })
add(13, P, { Type = "Outfit", Name = "Conjunto Playa Dorada", Icon = "🩳", Rarity = "Epica",
	Colors = { Hoodie = rgb(250, 250, 245), HoodLining = rgb(80, 200, 210), Tee = rgb(255, 170, 90), Pants = rgb(70, 150, 200), Shoes = rgb(250, 250, 245) },
	Description = "Blanco, turquesa y naranja: verano en la playa.", Preview = { Kind = "Outfit" } })
add(14, F, { Type = "Decor", Name = "Cojines de Los Pinos", Icon = "🛋️", Shape = "Cushion", Size = Vector3.new(1.6, 0.6, 1.6), Color = rgb(90, 130, 80),
	Description = "Cojines verdes con olor a pino.", Preview = { Kind = "Decor" } })
add(14, P, { Type = "PhoneTheme", Name = "Atardecer en Playa Dorada", Icon = "🌅", Rarity = "Rara", Colors = { Background = rgb(60, 30, 60), Accent = rgb(255, 150, 80), Text = rgb(255, 240, 230) },
	Description = "Naranja y violeta para tu teléfono." })
add(15, F, { Type = "VehicleSkin", Name = "Bici Verde Villaverde", Icon = "🚲", Kind = "Bici", Rarity = "Rara", GrantsBase = true,
	Color = rgb(60, 150, 80),
	Description = "Una bici verde campo. Mismas prestaciones que cualquier bici.", Preview = { Kind = "Vehicle", Vehicle = "Bici" } })
add(15, P, { Type = "VehicleSkin", Name = "Moto Brisa de Playa Dorada", Icon = "🛵", Kind = "Moto", Rarity = "Epica", GrantsBase = true,
	Color = rgb(250, 190, 70), Material = "SmoothPlastic",
	Description = "Una moto color arena con franja turquesa. Corre igual que las demás: es cuestión de estilo. (Para conducirla necesitas la edad y el carnet A, como siempre).",
	Preview = { Kind = "Vehicle", Vehicle = "Moto" } })
add(16, F, { Type = "CharacterXp", Name = "+200 XP de personaje", Icon = "⭐", Amount = 200, Description = "Experiencia para tu personaje." })
add(16, P, { Type = "Money", Name = "250 €", Icon = "💶", Amount = 250, Description = "Un extra pequeño." })
add(17, F, { Type = "Emote", Name = "Estiramiento del parque", Icon = "🧘", AnimationId = 3334538554, Loop = false,
	Description = "Estírate como en las mañanas del parque.", Preview = { Kind = "Emote" } })
add(17, P, { Type = "Decor", Name = "Acuario de la Isla de las Gaviotas", Icon = "🐠", Shape = "Box", Size = Vector3.new(3, 2, 1.4), Color = rgb(80, 170, 230), Material = "Glass", Rarity = "Epica",
	Description = "Peces de colores de la Isla de las Gaviotas.", Preview = { Kind = "Decor" } })
add(18, F, { Type = "Money", Name = "250 €", Icon = "💶", Amount = 250, Description = "Un pequeño ahorro." })
add(18, P, { Type = "Title", Name = "Ruta del Metro", Icon = "🚇", Text = "Ruta del Metro", Color = rgb(230, 60, 60), Rarity = "Rara",
	Description = "Para quien se sabe todas las estaciones." })
add(19, F, { Type = "PhoneTheme", Name = "Clásico de Valmar", Icon = "📱", Colors = { Background = rgb(235, 238, 245), Accent = rgb(40, 90, 150), Text = rgb(20, 25, 40) },
	Description = "Blanco y azul ciudad." })
add(19, P, { Type = "HudSkin", Name = "HUD Faro Dorado", Icon = "✨", Rarity = "Epica", Colors = { Panel = rgb(30, 24, 12), Accent = rgb(255, 200, 80), Text = rgb(255, 245, 225) },
	Description = "La interfaz en negro y oro." })
add(20, F, { Type = "Wearable", Name = "Gorra", Icon = "🧢", Kind = "Gorra", Rarity = "Rara",
	Description = "La gorra de los recreativos, gratis. Si ya la tienes, te damos 150 tickets.", Fallback = { Type = "Tickets", Amount = 150 } })
add(20, P, { Type = "Bundle", Name = "Colección Noche en el Centro", Icon = "🌆", Rarity = "Epica",
	Description = "Un conjunto para salir de noche y un título a juego.",
	Items = {
		{ Id = "S1_P20_Outfit", Type = "Outfit", Name = "Conjunto Noche en el Centro", Icon = "🧥",
			Colors = { Hoodie = rgb(20, 20, 24), HoodLining = rgb(255, 64, 160), Tee = rgb(40, 40, 48), Pants = rgb(20, 20, 24), Shoes = rgb(255, 64, 160) } },
		{ Id = "S1_P20_Title", Type = "Title", Name = "Noches del Centro", Icon = "🌆", Text = "Noches del Centro", Color = rgb(255, 90, 170) },
	},
	Preview = { Kind = "Outfit" } })

-- Nivel 21-30 ---------------------------------------------------------------
add(21, F, { Type = "Tickets", Name = "80 tickets", Icon = "🎟️", Amount = 80, Description = "Más partidas en los recreativos." })
add(21, P, { Type = "Emote", Name = "Paso del Distrito", Icon = "🕺", Rarity = "Rara", AnimationId = 507776043, Loop = true, Speed = 0.9,
	Description = "El baile tranquilo de los afterwork del Distrito Financiero.", Preview = { Kind = "Emote" } })
add(22, F, { Type = "Decor", Name = "Reloj de la estación", Icon = "🕰️", Shape = "Clock", Size = Vector3.new(2, 2, 0.3), Color = rgb(245, 240, 225),
	Description = "Como el de la estación de Cercanías.", Preview = { Kind = "Decor" } })
add(22, P, { Type = "Nameplate", Name = "Placa Neón", Icon = "💜", Rarity = "Epica", Colors = { Background = rgb(25, 10, 45), Stroke = rgb(255, 64, 200), Text = rgb(255, 230, 255) },
	Description = "Tu nombre en neón rosa." })
add(23, F, { Type = "Title", Name = "Explorador/a de distritos", Icon = "🧭", Text = "Explorador/a de distritos", Color = rgb(140, 220, 160),
	Description = "Para quien ha pisado todos los barrios." })
add(23, P, { Type = "Decor", Name = "Mesa de terraza", Icon = "☕", Shape = "Table", Size = Vector3.new(2.4, 2.4, 2.4), Color = rgb(200, 200, 205), Material = "Metal", Rarity = "Rara",
	Description = "Una mesa como las de las terrazas de la plaza.", Preview = { Kind = "Decor" } })
add(24, F, { Type = "Money", Name = "300 €", Icon = "💶", Amount = 300, Description = "Un pequeño ahorro." })
add(24, P, { Type = "CharacterXp", Name = "+300 XP de personaje", Icon = "⭐", Amount = 300, Description = "Experiencia para tu personaje." })
add(25, F, { Type = "HomeTheme", Name = "Piso luminoso de Valmar Norte", Icon = "🏠", Rarity = "Rara",
	Floor = rgb(225, 205, 170), FloorMaterial = "WoodPlanks", Wall = rgb(245, 243, 235), WallMaterial = "SmoothPlastic",
	Description = "Paredes claras y madera de roble para tu vivienda de siempre.", Preview = { Kind = "HomeTheme" } })
add(25, P, { Type = "HomeTheme", Name = "Ático Distrito Financiero", Icon = "🏙️", Rarity = "Epica",
	Floor = rgb(40, 40, 46), FloorMaterial = "Marble", Wall = rgb(210, 214, 222), WallMaterial = "SmoothPlastic",
	Description = "Mármol oscuro y paredes gris perla, como en las torres. Se aplica a tu vivienda (no es una casa nueva).",
	Preview = { Kind = "HomeTheme" } })
add(26, F, { Type = "CharacterXp", Name = "+250 XP de personaje", Icon = "⭐", Amount = 250, Description = "Experiencia para tu personaje." })
add(26, P, { Type = "Outfit", Name = "Traje de gala de Altamar", Icon = "🤵", Rarity = "Epica",
	Colors = { Hoodie = rgb(22, 24, 30), HoodLining = rgb(22, 24, 30), Tee = rgb(250, 250, 250), Pants = rgb(22, 24, 30), Shoes = rgb(10, 10, 12) },
	Description = "Elegante para la gala del Estadio Altamar.", Preview = { Kind = "Outfit" } })
add(27, F, { Type = "Emote", Name = "Foto de turista", Icon = "📸", AnimationId = 507770453, Loop = false,
	Description = "Señala el monumento y haz la foto.", Preview = { Kind = "Emote" } })
add(27, P, { Type = "Decor", Name = "Maqueta del Cercanías", Icon = "🚆", Shape = "Box", Size = Vector3.new(3, 1, 1), Color = rgb(200, 40, 45), Rarity = "Rara",
	Description = "Una maqueta del tren de Cercanías.", Preview = { Kind = "Decor" } })
add(28, F, { Type = "Decor", Name = "Estantería del Campus", Icon = "📚", Shape = "Shelf", Size = Vector3.new(3, 5, 1.2), Color = rgb(130, 90, 60),
	Description = "Llena de apuntes de la Universidad.", Preview = { Kind = "Decor" } })
add(28, P, { Type = "Money", Name = "300 €", Icon = "💶", Amount = 300, Description = "Un extra pequeño." })
add(29, F, { Type = "Tickets", Name = "100 tickets", Icon = "🎟️", Amount = 100, Description = "Más partidas en los recreativos." })
add(29, P, { Type = "PhoneTheme", Name = "Mar de Valmar", Icon = "🌊", Rarity = "Rara", Colors = { Background = rgb(10, 40, 70), Accent = rgb(80, 200, 210), Text = rgb(230, 250, 255) },
	Description = "Azul mar para tu teléfono." })
add(30, F, { Type = "Nameplate", Name = "Placa Temporada 1", Icon = "🏷️", Rarity = "Rara", Colors = { Background = rgb(28, 36, 72), Stroke = rgb(255, 196, 64), Text = rgb(255, 255, 255) },
	Description = "La placa de la primera temporada." })
add(30, P, { Type = "Perk", Name = "Cambio de misión diaria", Icon = "🔄", Rarity = "Epica", Perk = "RerollDaily",
	Description = "Una vez al día puedes cambiar una misión diaria que no te apetezca por otra. No da más XP: solo elige." })

-- Nivel 31-40 ---------------------------------------------------------------
add(31, F, { Type = "Money", Name = "300 €", Icon = "💶", Amount = 300, Description = "Un pequeño ahorro." })
add(31, P, { Type = "Emote", Name = "Celebración del estadio", Icon = "🏟️", Rarity = "Epica", AnimationId = 3338055167, Loop = false,
	Description = "Como la grada del Estadio Altamar cuando marca el equipo.", Preview = { Kind = "Emote" } })
add(32, F, { Type = "Title", Name = "Currante de Valmar", Icon = "🛠️", Text = "Currante de Valmar", Color = rgb(255, 200, 120),
	Description = "Para quien no falta a su turno." })
add(32, P, { Type = "Decor", Name = "Farola antigua", Icon = "🏮", Shape = "Lamp", Size = Vector3.new(1, 6, 1), Color = rgb(30, 60, 50), Light = true, Rarity = "Rara",
	Description = "Una farola como las del casco antiguo.", Preview = { Kind = "Decor" } })
add(33, F, { Type = "Decor", Name = "Alfombra de playa", Icon = "🏖️", Shape = "Rug", Size = Vector3.new(5, 0.1, 3), Color = rgb(80, 200, 210),
	Description = "Rayas de toalla de Playa Dorada.", Preview = { Kind = "Decor" } })
add(33, P, { Type = "Title", Name = "Noctámbulo/a", Icon = "🌙", Text = "Noctámbulo/a", Color = rgb(170, 150, 255), Rarity = "Rara",
	Description = "Valmar de noche no tiene secretos para ti." })
add(34, F, { Type = "CharacterXp", Name = "+300 XP de personaje", Icon = "⭐", Amount = 300, Description = "Experiencia para tu personaje." })
add(34, P, { Type = "HudSkin", Name = "HUD Aurora", Icon = "🌌", Rarity = "Epica", Colors = { Panel = rgb(12, 30, 36), Accent = rgb(120, 255, 200), Text = rgb(230, 255, 245) },
	Description = "Verde aurora para la interfaz." })
add(35, F, { Type = "Outfit", Name = "Sudadera Temporada 1", Icon = "👕", Rarity = "Rara",
	Colors = { Hoodie = rgb(40, 90, 150), HoodLining = rgb(245, 245, 250), Tee = rgb(245, 245, 250), Pants = rgb(34, 36, 42), Shoes = rgb(245, 245, 245) },
	Description = "La sudadera azul Valmar de la primera temporada.", Preview = { Kind = "Outfit" } })
add(35, P, { Type = "Boat", Name = "Lancha «Gaviota»", Icon = "🚤", Rarity = "Epica", Kind = "Lancha", Color = rgb(245, 245, 250),
	Description = "Una lancha blanca con tu nombre en la popa. Queda guardada para siempre y se podrá sacar en el puerto deportivo cuando abra (los barcos propios llegan en una actualización).",
	Preview = { Kind = "Boat", Model = "Lancha" } })
add(36, F, { Type = "Tickets", Name = "120 tickets", Icon = "🎟️", Amount = 120, Description = "Más partidas en los recreativos." })
add(36, P, { Type = "Decor", Name = "Barco en botella", Icon = "⛵", Shape = "Box", Size = Vector3.new(1.6, 0.8, 0.8), Color = rgb(170, 220, 230), Material = "Glass", Rarity = "Rara",
	Description = "Un velero diminuto del puerto de Valmar.", Preview = { Kind = "Decor" } })
add(37, F, { Type = "Emote", Name = "Saludo marinero", Icon = "⚓", AnimationId = 3333474484, Loop = false, Speed = 0.8,
	Description = "El saludo de la gente del puerto.", Preview = { Kind = "Emote" } })
add(37, P, { Type = "Nameplate", Name = "Placa Marina", Icon = "🌊", Rarity = "Epica", Colors = { Background = rgb(10, 50, 80), Stroke = rgb(120, 230, 240), Text = rgb(255, 255, 255) },
	Description = "Olas y espuma alrededor de tu nombre." })
add(38, F, { Type = "Money", Name = "350 €", Icon = "💶", Amount = 350, Description = "Un pequeño ahorro." })
add(38, P, { Type = "Outfit", Name = "Cortavientos del puerto", Icon = "🧥", Rarity = "Epica",
	Colors = { Hoodie = rgb(230, 70, 50), HoodLining = rgb(245, 245, 250), Tee = rgb(245, 245, 250), Pants = rgb(30, 50, 80), Shoes = rgb(245, 245, 250) },
	Description = "Rojo marinero para los días de viento.", Preview = { Kind = "Outfit" } })
add(39, F, { Type = "PhoneTheme", Name = "Mapa de Valmar", Icon = "🗺️", Rarity = "Rara", Colors = { Background = rgb(230, 225, 205), Accent = rgb(60, 120, 80), Text = rgb(40, 40, 35) },
	Description = "Tu teléfono con el plano de la ciudad." })
add(39, P, { Type = "Money", Name = "350 €", Icon = "💶", Amount = 350, Description = "Un extra pequeño." })
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
add(41, F, { Type = "Decor", Name = "Banco del parque", Icon = "🪑", Shape = "Bench", Size = Vector3.new(4, 2, 1.4), Color = rgb(120, 80, 50),
	Description = "Un banco como los del parque.", Preview = { Kind = "Decor" } })
add(41, P, { Type = "Emote", Name = "Baile del faro", Icon = "💫", Rarity = "Epica", AnimationId = 507771019, Loop = true, Speed = 1.25,
	Description = "Gira como la luz del faro.", Preview = { Kind = "Emote" } })
add(42, F, { Type = "Money", Name = "350 €", Icon = "💶", Amount = 350, Description = "Un pequeño ahorro." })
add(42, P, { Type = "Decor", Name = "Telescopio del Monte", Icon = "🔭", Shape = "Box", Size = Vector3.new(1, 3, 1), Color = rgb(60, 60, 70), Material = "Metal", Rarity = "Epica",
	Description = "Para mirar las estrellas como desde el Monte del Silencio.", Preview = { Kind = "Decor" } })
add(43, F, { Type = "Tickets", Name = "150 tickets", Icon = "🎟️", Amount = 150, Description = "Más partidas en los recreativos." })
add(43, P, { Type = "Title", Name = "Leyenda del Monte", Icon = "⛰️", Text = "Leyenda del Monte", Color = rgb(180, 230, 255), Rarity = "Epica",
	Description = "Solo quien ha subido a la cima lo entiende." })
add(44, F, { Type = "CharacterXp", Name = "+350 XP de personaje", Icon = "⭐", Amount = 350, Description = "Experiencia para tu personaje." })
add(44, P, { Type = "PhoneTheme", Name = "Oro de Valmar", Icon = "📱", Rarity = "Epica", Colors = { Background = rgb(24, 20, 12), Accent = rgb(255, 200, 80), Text = rgb(255, 245, 225) },
	Description = "Negro y oro para tu teléfono." })
add(45, F, { Type = "Nameplate", Name = "Placa Plata", Icon = "🥈", Rarity = "Epica", Colors = { Background = rgb(180, 185, 195), Stroke = rgb(80, 85, 95), Text = rgb(20, 20, 25) },
	Description = "Una placa de plata para veteranos de la temporada." })
add(45, P, { Type = "Outfit", Name = "Conjunto Faro de Valmar", Icon = "🗼", Rarity = "Epica",
	Colors = { Hoodie = rgb(245, 245, 240), HoodLining = rgb(255, 196, 64), Tee = rgb(28, 36, 72), Pants = rgb(245, 245, 240), Shoes = rgb(255, 196, 64) },
	Description = "Blanco perla y oro, como el faro al anochecer.", Preview = { Kind = "Outfit" } })
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
add(48, P, { Type = "Nameplate", Name = "Placa Oro", Icon = "🥇", Rarity = "Epica", Colors = { Background = rgb(255, 200, 80), Stroke = rgb(120, 80, 20), Text = rgb(40, 25, 5) },
	Description = "Oro de ley alrededor de tu nombre." })
add(49, F, { Type = "Tokens", Name = "3 fichas de temporada", Icon = "🪙", Amount = 3, Description = "Para la tienda de fichas (solo cosméticos)." })
add(49, P, { Type = "Money", Name = "400 €", Icon = "💶", Amount = 400, Description = "Un extra pequeño." })
add(50, F, { Type = "Bundle", Name = "Recuerdo de la Temporada 1", Icon = "🎖️", Rarity = "Epica",
	Description = "Has llegado al final: un título y una placa conmemorativa para tu casa.",
	Items = {
		{ Id = "S1_F50_Title", Type = "Title", Name = "Veterano/a · Temporada 1", Icon = "🎖️", Text = "Veterano/a · Temporada 1", Color = rgb(200, 220, 255) },
		{ Id = "S1_F50_Decor", Type = "Decor", Name = "Placa conmemorativa", Icon = "🎖️", Shape = "Poster", Size = Vector3.new(2, 1.4, 0.2), Color = rgb(200, 170, 90), Material = "Metal" },
	} })
add(50, P, { Type = "Bundle", Name = "Faro de Valmar", Icon = "🗼", Rarity = "Legendaria",
	Description = "La recompensa legendaria de la temporada: el descapotable «Faro de Valmar» (blanco perla y oro), el título «Leyenda de Valmar», su placa y un faro en miniatura para tu casa. Mismas prestaciones que cualquier coche: se nota en el estilo, no en la carrera.",
	Items = {
		{ Id = "S1_P50_Car", Type = "VehicleSkin", Name = "Descapotable «Faro de Valmar»", Icon = "🚗", Kind = "Coche", GrantsBase = true,
			Color = rgb(245, 242, 232), Material = "SmoothPlastic", Trim = rgb(255, 196, 64) },
		{ Id = "S1_P50_Title", Type = "Title", Name = "Leyenda de Valmar", Icon = "🗼", Text = "Leyenda de Valmar", Color = rgb(255, 210, 90) },
		{ Id = "S1_P50_Plate", Type = "Nameplate", Name = "Placa Faro", Icon = "🗼",
			Colors = { Background = rgb(245, 242, 232), Stroke = rgb(255, 196, 64), Text = rgb(28, 36, 72) } },
		{ Id = "S1_P50_Decor", Type = "Decor", Name = "Faro en miniatura", Icon = "🗼", Shape = "Lighthouse", Size = Vector3.new(1.2, 4, 1.2), Color = rgb(245, 245, 245), Light = true },
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
	-- Fechas en hora UTC (segundos desde 1970). 5-oct-2026 00:00 UTC → 7-dic-2026 00:00 UTC (9 semanas)
	StartsAt = 1791158400,
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
