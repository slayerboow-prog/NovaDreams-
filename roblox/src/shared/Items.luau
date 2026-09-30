-- Items: todo lo que puede aparecer en la mochila (inventario al estilo Minecraft).
-- Junta en una sola lista cosas que guardan distintos sistemas:
--   * Comida y objetos comprados en las tiendas (ShopItems.luau)   -> data.Items = { Pan = 3, ... }
--   * Productos de los supermercados (Groceries.luau)             -> data.Items
--   * Vehículos (Gameplay.Vehicles)                                -> data.Vehicles
--   * Premios de los recreativos (Gameplay.Prizes)                 -> data.Prizes
--   * Carnets de conducir (Gameplay.Licenses)                      -> data.Licenses
--   * Títulos de la universidad (Subjects.Degrees)                 -> data.Education.Degrees
--
-- Kind dice qué pasa al usarlo:
--   Food     se come (quita hambre o da energía) y se gasta uno
--   Vehicle  te montas o te bajas
--   Wear     te lo pones o te lo quitas
--   Weapon   se empuña al elegir su casilla de la barra rápida (WeaponService / WeaponController)
--   Ammo     munición de un arma (se gasta al recargar)
--   Thing / Prize / Document   solo se guarda (recados, recuerdos, papeles)
--   Keepsake  objeto de la historia (la mochila del cole, la foto del grupo…): no se tira
--   Gadget    invento exclusivo de las misiones locas de Cosme (pistola de rayos, mando de dimensiones…):
--             se usa desde la barra rápida y hace su efecto (server/Services/GadgetService); no se gasta

local Gameplay = require(script.Parent.Gameplay)
local ShopItems = require(script.Parent.LifeStory.ShopItems)
local Subjects = require(script.Parent.LifeStory.Subjects)
local Strings = require(script.Parent.LifeStory.Strings)
local Groceries = require(script.Parent.Groceries)
local CafeMenu = require(script.Parent.CafeMenu)
local Cinema = require(script.Parent.Cinema)
local Hotel = require(script.Parent.Hotel)
local Fishing = require(script.Parent.Fishing)
local Metro = require(script.Parent.Metro)
local Rail = require(script.Parent.Rail)
local Weapons = require(script.Parent.Weapons)
local Farming = require(script.Parent.Farming)
local Format = require(script.Parent.Format)

local Items = {}

Items.Slots = 36 -- como en Minecraft: 27 de mochila + 9 de barra rápida
Items.Hotbar = 9 -- casillas 1-9 = barra rápida (teclas 1-9)

export type Item = {
	Id: string,
	Name: string,
	Icon: string,
	Kind: string,
	Desc: string,
	Stack: number, -- cuántos caben en una casilla
	Hunger: number?,
	Energy: number?,
	Ref: string?, -- clave en su sistema (vehículo, premio, carnet…)
	Effect: string?, -- (Gadget) qué hace al usarlo
	Color: { number }?,
	Lines: string?,
	Cooldown: number?,
}

local ICONS = {
	MaterialEscolar = "✏️",
	Medicinas = "💊",
	Helado = "🍦",
	Pan = "🥖",
	Fruta = "🍎",
	Flores = "💐",
	BolsaCompra = "🛒",
}
local DESCS = {
	MaterialEscolar = "Lápices, cuadernos y una goma que huele a fresa.",
	Medicinas = "Las medicinas de casa. Guárdalas para la familia.",
	Helado = "Frío y dulce. Quita un poco de hambre y anima.",
	Pan = "Recién hecho en la panadería. Quita el hambre.",
	Fruta = "Fresca y sana. Quita el hambre.",
	Flores = "Un ramo precioso para regalar o decorar tu casa.",
	BolsaCompra = "Pasta, huevos, fruta y algo de verdura (que acabará caducando). Quita mucha hambre.",
}

local list: { [string]: Item } = {}

for _, shopItem in ShopItems do
	local food = shopItem.Hunger ~= nil or shopItem.Energy ~= nil
	list[shopItem.Id] = {
		Id = shopItem.Id,
		Name = Strings.get(shopItem.NameKey),
		Icon = ICONS[shopItem.Id] or "📦",
		Kind = if food then "Food" else "Thing",
		Desc = DESCS[shopItem.Id] or "",
		Stack = if food then 16 else 64,
		Hunger = shopItem.Hunger,
		Energy = shopItem.Energy,
	}
end

for key, vehicle in Gameplay.Vehicles do
	if vehicle.Hidden then
		continue
	end
	list["Vehiculo_" .. key] = {
		Id = "Vehiculo_" .. key,
		Name = vehicle.Name,
		Icon = vehicle.Icon,
		Kind = "Vehicle",
		Desc = ("Tu %s. Pulsa «Montar» para subirte. Velocidad %d."):format(vehicle.Name:lower(), vehicle.Speed),
		Stack = 1,
		Ref = key,
	}
end

for key, prize in Gameplay.Prizes do
	if prize.Kind ~= "Vehicle" then -- los vehículos de premio ya salen como vehículos
		list["Premio_" .. key] = {
			Id = "Premio_" .. key,
			Name = prize.Name,
			Icon = prize.Icon,
			Kind = if prize.Kind == "Wear" then "Wear" else "Prize",
			Desc = if prize.Kind == "Wear" then "Premio de los recreativos. Pulsa «Poner» o «Quitar» en la mochila." else "Premio de los recreativos. ¡Un recuerdo de tu récord!",
			Stack = 1,
			Ref = key,
		}
	end
end

for key, license in Gameplay.Licenses do
	list["Carnet_" .. key] = {
		Id = "Carnet_" .. key,
		Name = license.Name,
		Icon = "💳",
		Kind = "Document",
		Desc = "Aprobado en la autoescuela. Te deja conducir: " .. (Gameplay.Vehicles[license.Vehicle] and Gameplay.Vehicles[license.Vehicle].Name or license.Vehicle) .. ".",
		Stack = 1,
		Ref = key,
	}
end

for _, degree in Subjects.Degrees do
	list["Titulo_" .. degree.Titulo] = {
		Id = "Titulo_" .. degree.Titulo,
		Name = "Título de " .. Strings.get(degree.NameKey),
		Icon = "🎓",
		Kind = "Document",
		Desc = "Tu título universitario. ¡Años de estudio en Campus Valmar!",
		Stack = 1,
		Ref = degree.Titulo,
	}
end

-- Supermercado: productos de las estanterías y de la charcutería
for _, product in Groceries.List do
	if not list[product.Id] then
		local food = product.Hunger ~= nil
		local section = Groceries.Sections[product.Section]
		list[product.Id] = {
			Id = product.Id,
			Name = product.Name,
			Icon = product.Icon,
			Kind = if food then "Food" else "Thing",
			Desc = if food then ("Del supermercado (%s). Quita el hambre."):format(section.Name) else ("Del supermercado (%s). Para tu casa."):format(section.Name),
			Stack = if food then 16 else 32,
			Hunger = product.Hunger,
			Energy = product.Energy,
		}
	end
end
for _, deli in Groceries.Deli do
	list[deli.Id] = {
		Id = deli.Id,
		Name = deli.Name .. " (al corte)",
		Icon = deli.Icon,
		Kind = "Food",
		Desc = "Recién cortado en la charcutería del supermercado.",
		Stack = 16,
		Hunger = deli.Hunger * 2,
		Energy = 0,
	}
end

-- Cafetería: lo que se pide en la barra (lo prepara el barista)
for _, product in CafeMenu.List do
	local id = CafeMenu.itemId(product.Id)
	list[id] = {
		Id = id,
		Name = product.Name,
		Icon = product.Icon,
		Kind = "Food",
		Desc = if product.Plate then "Recién servido en la cafetería." else "Recién hecho por el barista. Quita el sueño.",
		Stack = 8,
		Hunger = product.Hunger,
		Energy = product.Energy,
	}
end

-- Cine: la entrada (se gasta al entrar a la sala) y lo de la barra
list[Cinema.TicketItem] = {
	Id = Cinema.TicketItem,
	Name = "Entrada de cine",
	Icon = "🎟️",
	Kind = "Thing",
	Desc = "Una entrada para la próxima sesión del cine. Enséñala en la puerta de la sala.",
	Stack = 8,
}
for _, snack in Cinema.Snacks do
	list[snack.Id] = list[snack.Id] or {
		Id = snack.Id,
		Name = snack.Name,
		Icon = snack.Icon,
		Kind = "Food",
		Desc = "De la barra del cine. Mejor durante la película.",
		Stack = 8,
		Hunger = snack.Hunger,
		Energy = snack.Energy,
	}
end

-- Hotel: la llave de tu habitación (se gasta al descansar una noche)
list[Hotel.KeyItem] = {
	Id = Hotel.KeyItem,
	Name = "Llave de hotel",
	Icon = "🗝️",
	Kind = "Thing",
	Desc = "La llave de tu habitación. Úsala en el ascensor del hotel para subir a descansar.",
	Stack = 4,
}

-- Pesca: cañas, cebo y lo que pescas (se vende en la pescadería del supermercado)
for _, rod in Fishing.Rods do
	list[rod.Id] = { Id = rod.Id, Name = rod.Name, Icon = rod.Icon, Kind = "Thing", Desc = rod.Desc, Stack = 1 }
end
for _, tool in Fishing.Tools do
	list[tool.Id] = { Id = tool.Id, Name = tool.Name, Icon = tool.Icon, Kind = "Thing", Desc = tool.Desc .. " (herramienta de pesca)", Stack = 1 }
end
for _, boss in Fishing.Bosses do
	list[boss.Item] = {
		Id = boss.Item,
		Name = boss.Name,
		Icon = boss.Icon,
		Kind = "Thing",
		Desc = ("¡Un trofeo legendario! La lonja de la pescadería lo compra por %s."):format(Format.money(boss.Price)),
		Stack = 5,
	}
end
list[Fishing.Bait.Id] = { Id = Fishing.Bait.Id, Name = Fishing.Bait.Name, Icon = Fishing.Bait.Icon, Kind = "Thing", Desc = Fishing.Bait.Desc, Stack = 50 }
for _, s in Fishing.Species do
	list[s.Item] = {
		Id = s.Item,
		Name = s.Name,
		Icon = s.Icon,
		Kind = "Thing",
		Desc = ("%s · pescado fresco. Véndelo en la pescadería del supermercado (%s cada uno)."):format(s.Rarity, Format.money(s.Price)),
		Stack = 64, -- como los demás objetos: caben muchos antes de tener que venderlos
	}
end

-- Campo de Villaverde: cosechas, lo de los animales, lo del obrador y la cocina, semillas y pienso
for _, id in Farming.ProductOrder do
	local p = Farming.Products[id]
	local food = p.Hunger ~= nil
	list[id] = {
		Id = id,
		Name = p.Name,
		Icon = p.Icon,
		Kind = if food then "Food" else "Thing",
		Desc = ("%s La cooperativa lo paga a %s; el supermercado, a %s."):format(p.Desc, Format.money(Farming.sellPrice(id, "Coop")), Format.money(Farming.sellPrice(id, "Super"))),
		Stack = 99,
		Hunger = p.Hunger,
		Energy = p.Energy,
	}
end
for _, c in Farming.Crops do
	local id = Farming.seedItem(c.Id)
	list[id] = {
		Id = id,
		Name = if c.Tree then "Plantón de " .. c.Name:lower() else "Semillas de " .. c.Name:lower(),
		Icon = "🌱",
		Kind = "Thing",
		Desc = ("Para plantar en un bancal de tu finca de Villaverde. Da %s %s."):format(c.Icon, Farming.Products[c.Product].Name:lower()),
		Stack = 99,
	}
end
list[Farming.Feed] = { Id = Farming.Feed, Name = "Saco de pienso", Icon = "🥣", Kind = "Thing", Desc = "Comida para tus animales de la granja (también comen trigo y maíz).", Stack = 99 }

-- Metro: el billete y lo que venden las tiendas subterráneas
list[Metro.TicketItem] = { Id = Metro.TicketItem, Name = "Billete de metro", Icon = "🎫", Kind = "Thing", Desc = "Un viaje en metro. Se gasta al pasar el torno.", Stack = 50 }
-- Cercanías: el billete del tren (Shared/Rail)
list[Rail.TicketItem] = { Id = Rail.TicketItem, Name = "Billete de Cercanías", Icon = "🎫", Kind = "Thing", Desc = "Un viaje en el tren de Cercanías. Se gasta al subir al tren.", Stack = 50 }
for id, p in Metro.Products do
	list[id] = list[id] or {
		Id = id,
		Name = p.Name,
		Icon = p.Icon,
		Kind = p.Kind,
		Desc = p.Desc,
		Stack = if p.Kind == "Food" then 8 else 4,
		Hunger = p.Hunger,
		Energy = p.Energy,
	}
end

-- Armas (de verdad, de la policía y de juguete), su munición y la licencia de armas
for id, w in Weapons.List do
	local itemId = Weapons.itemId(id)
	local desc = if w.Kind == "Toy" then "De juguete: no hace daño. Elígelo en la barra rápida para empuñarlo."
		elseif w.Duty then "Arma de servicio de la policía. Se devuelve al acabar el turno."
		else "Arma de fuego (necesita licencia). Elígela en la barra rápida para empuñarla; botón Apuntar (clic derecho) para apuntar."
	list[itemId] = { Id = itemId, Name = w.Name, Icon = w.Icon, Kind = "Weapon", Desc = desc, Stack = 1, Ref = id }
end
for id, ammo in Weapons.AmmoTypes do
	list[id] = { Id = id, Name = ammo.Name, Icon = ammo.Icon, Kind = "Ammo", Desc = ("Munición. Se gasta al recargar (caja de %d)."):format(ammo.Box), Stack = ammo.Stack }
end
list[Weapons.Licence.Item] = {
	Id = Weapons.Licence.Item,
	Name = "Licencia de armas",
	Icon = "💳",
	Kind = "Document",
	Desc = "Te permite comprar y llevar armas de fuego. Se retira si te condenan.",
	Stack = 1,
}

-- Objetos de la historia (las misiones los dan y los quitan con Effects.Items / Effects.Take)
local KEEPSAKES = {
	{ "MochilaCole", "Mochila del cole", "🎒", "Tu mochila azul del colegio, con tu nombre bordado." },
	{ "CromoSuerte", "Cromo de la suerte", "🃏", "Un cromo brillante de un portero legendario. Da suerte (eso dices tú)." },
	{ "DibujoMateo", "Dibujo de Mateo", "🖼️", "Mateo te dibujó pasándole el balón a Dani. Pone: «Para mi primer amigo»." },
	{ "FotoGrupo", "Foto del grupo", "📸", "Todos en el parque, haciendo muecas. La primera foto de tu grupo." },
	{ "CuadernoOmar", "Dibujo de Omar", "✏️", "Omar dibujó el partido. Tú sales marcando (aunque no fuera exactamente así)." },
	{ "LibroPiratas", "Libro de piratas de Hugo", "☠️", "«La isla de las mil llaves». Hugo lo ha leído seis veces. Dice que ahora te toca a ti." },
	{ "ApuntesBiblioteca", "Apuntes de la biblioteca", "📒", "Los apuntes de Matemáticas de la biblioteca. Hay que devolverlos después del examen." },
	{ "Lupa", "Lupa de detective", "🔍", "Lucía te la dio por resolver el misterio de las bromas." },
	{ "FotoExcursion", "Foto de la excursión", "🐄", "Toda la clase delante del granero de Villaverde. Hay una gallina en primer plano." },
	{ "MedallaOro", "Medalla de oro del torneo", "🥇", "Campeones del torneo del colegio. Pesa más de lo que parece." },
	{ "MedallaPlata", "Medalla de plata del torneo", "🥈", "Subcampeones. Andrés dijo que la plata se gana con el mismo sudor." },
	{ "FotoLucia", "Foto de la clase de 1998", "🖼️", "Una niña con jersey amarillo en primera fila. Detrás pone: «Algún día seré profe aquí»." },
	{ "FotoFestival", "Foto del festival de primavera", "🎉", "Tu familia con todo tu grupo, delante del cartel lleno de purpurina." },
	{ "Maqueta", "Maqueta del proyecto final", "🔬", "Un poco torcida, llena de pegamento… y con mucha historia." },
	{ "DiplomaPrimaria", "Diploma de primaria", "🎓", "Firmado por Lucía. Con una carita sonriente al lado de la firma." },
	{ "Llavero13", "Llavero con el número 13", "🗝️", "Regalo de Ramón: las puertas cerradas a veces esconden cosas bonitas." },
	{ "CarnetInstituto", "Carnet del instituto", "💳", "Tu foto de carnet del primer día. Nadie sale bien en las fotos de carnet." },
	{ "FotoDeLeire", "Foto de Leire", "📷", "Blanco y negro. Tú, el primer día de instituto, con cara de «¿dónde me he metido?»." },
	{ "InsigniaClub", "Insignia del club", "📌", "La insignia de tu primer club del instituto." },
	{ "PrimerSobre", "Sobre de tu primer sueldo", "✉️", "Vacío. Pero lo guardas en un cajón y no sabes muy bien por qué." },
	{ "PulseraGrupo", "Pulsera del grupo", "🧶", "La hizo Omar para todos. «Por si se nos olvida quiénes somos.»" },
	{ "OrlaInstituto", "Orla del instituto", "🖼️", "Omar con los ojos cerrados, Nico saltando, Sara en su sitio exacto. Y tú, en medio." },
	{ "CartaRecomendacion", "Carta de recomendación", "📄", "De tu jefe del primer verano. «Puntual, con palabra y con ganas de aprender.»" },
	{ "CarnetUniversitario", "Carnet universitario", "🎫", "Tu foto de carnet de la universidad. Sales igual de mal que en la del instituto." },
	{ "RelojAbu", "El reloj de tu abuelo o abuela", "⌚", "Viejo, con la correa gastada. Todavía hace tic-tac muy bajito." },
	{ "FotoEquipoUni", "Foto del grupo cuatro", "📸", "Julia, Adrián, Carla, Pablo con su guitarra… y tú." },
	{ "ContratoTrabajo", "Tu primer contrato", "📝", "Con tu nombre, tus horas y hasta impuestos. Te hizo sentir adulto o adulta." },
	{ "InformePracticas", "Informe de prácticas", "📋", "Firmado por tu tutor. Con una nota al margen: «Buen trabajo»." },
	{ "LlavesPiso", "Las llaves de tu primer piso", "🔑", "Con un llavero del número 13 al lado, si lo guardaste." },
	{ "OrlaUniversidad", "Orla de la universidad", "🎓", "Birretes al aire. Todos a la vez. La foto que más vas a enseñar." },
	{ "PrimeraNomina", "Tu primera nómina completa", "💶", "Con tu nombre, tu puesto y, ay, las retenciones." },
	{ "ConchaAbu", "Una concha de Playa Dorada", "🐚", "«Para que vuelvas aquí. Con quien tú quieras.»" },
	{ "FotoReencuentro", "Foto del reencuentro", "📸", "Todo el grupo en la cafetería de Omar. Más altos, igual de ruidosos." },
	{ "CuadernoProfesiones", "Cuaderno de profesiones", "📓", "Lo que viste en la semana de las profesiones. «Dentro de unos años lo leerás y te reirás. O no.»" },	-- Universidad de verdad
	{ "LlaveResidencia", "Llave de la habitación 214", "🗝️", "La de la puerta que chirría. Tercer piso, al fondo. Tu primera casa sin tu familia." },
	{ "TFG", "Tu trabajo de fin de grado", "📘", "Encuadernado en azul. Cuatro años de carrera caben en noventa páginas (y una bibliografía muy larga)." },
	{ "ZumoMora", "Botella de zumo de mora", "🍇", "De la abuela de Iván. Moras del Monte del Silencio. No beber de madrugada (da sonambulismo)." },
	{ "TazaCampamento", "Taza de campamento del grupo", "⛺", "Cuatro nombres y un dibujo de un alienígena, hecho por Julia. Nadie os creyó." },
	{ "PinzaDeOro", "Pinza de oro de Don Pinzas", "🦀", "Se le cayó al cangrejo abogado. Según el tratado de 1734, ahora un metro de playa es tuyo." },
	{ "FotoCosmeCosimo", "Foto de Cosme y Cósimo, jóvenes", "📸", "«La noche antes de la prueba». Dos jóvenes con bata delante de una máquina. Uno de ellos, con una sonrisa de anuncio." },
	-- Saga de la Grieta
	{ "MonedaPerilla", "Moneda de la 66-B", "🪙", "Caliente, como recién salida de un horno. En una cara, la cara de Cosme… con perilla." },
	{ "EscamaBrillante", "Escama brillante", "✨", "Regalo de Don Escamas: «Por si necesitas un contable. O un amigo. Soy las dos cosas»." },
	{ "SelloAduana", "Sello de la Aduana del Tiempo", "📄", "De repuesto. «Nunca se sabe cuándo hay que sellar algo.» — Agente Cronos." },
	{ "CalcetinSolitario", "Calcetín solitario", "🧦", "Verde. Sin pareja. Del Monstruo de los Calcetines Desparejados. Te mira." },
	{ "CredencialAyudante", "Credencial de ayudante oficial", "💳", "«Laboratorio Cosme. Nivel: casi de confianza». Sales fatal en la foto." },
	{ "FolletoMegaVerso", "Folleto de MegaVerso", "📄", "«¡Cambia de vida sin cambiar de casa!». Letra pequeña: la dimensión pasa a ser de ellos." },
	{ "CintaArchivo", "La cinta de «La noche»", "📼", "La noche en que naciste. La noche en que se abrió la Grieta. Tu historia." },
	{ "RelojArena", "Reloj de arena de Cronos", "⏳", "Gíralo cuando la cosa se ponga fea. Llegará. Tarde, pero llegará." },
	{ "BataChamuscada", "La bata chamuscada de Cosme", "🥼", "La recogió Omar del suelo del patio. Todavía huele a batido de apio." },
	{ "CuadernoCosme", "El cuaderno de Cosme", "📓", "Fórmulas, dibujos de gallinas y, en la última página: «Si me pasa algo, que lo lea la criatura». Eres tú." },
	{ "CollarDiplomatico", "Collar diplomático de Gatonia", "📿", "Regalo del Presidente Bigotes. Con él, cualquier gato te trata de usted." },
	{ "PaseVIP", "Pase VIP del reality", "🎟️", "«Abducidos: edición especial». Temporada 3, capítulo 8. Sales en los créditos." },
	{ "MapaMalvado", "Mapa de la 66-B", "🗺️", "Dibujado por tu versión malvada. Las calles son las mismas; los carteles, no." },
	{ "FotoSinMemoria", "Foto de Cosme sin memoria", "📷", "Cosme, con una manta, preguntando quién eres. Detrás, a boli: «Pero se quedó a cenar»." },
	{ "AlbumRecuerdos", "Álbum de recuerdos", "📔", "El microondas, las gallinas, el anclaje del parque. Todo lo que le devolviste a Cosme." },
	{ "AgujaDeOro", "La aguja de oro", "🪡", "La que cerró la Grieta para siempre. En la punta pone, muy pequeñito: «Gracias, Ancla»." },
	{ "AgujaCuantica", "Aguja cuántica", "🪡", "Con ella cosiste el cielo de Valmar. Todavía brilla un poco cuando hay luna llena." },
	-- Restos de la Grieta (colección de las rarezas)
	{ "SelloDelAyer", "Sello del ayer", "📮", "Resto de la Grieta. Un sello con matasellos de ayer. Siempre de ayer, lo mires cuando lo mires." },
	{ "BombillaTenor", "Bombilla tenor", "💡", "Resto de la Grieta. Si la acercas al oído, tararea «Fígaro». Bajito, por fin." },
	{ "ChapaBinaria", "Chapa binaria de Pip", "🏷️", "Resto de la Grieta. 01010000 01001001 01010000. Pone «PIP». Era suya, de cuando quería ser perro." },
	{ "TenedorCosmico", "Tenedor cósmico", "🍴", "Resto de la Grieta. Objeto sagrado en la dimensión de la pasta. Aquí, un tenedor de bolsillo." },
	{ "BotonPiso13", "Botón del piso 13", "🔘", "Resto de la Grieta. Está calentito. No lo pulses. Hay lista de espera de trescientos años." },
	{ "EngranajeAlReves", "Engranaje al revés", "⚙️", "Resto de la Grieta. Gira hacia atrás. Dicen que, si lo giras, te olvidas de los malos ratos." },
	{ "LuzAmbar", "Luz ámbar", "🟠", "Resto de la Grieta. Regalo de un semáforo con opiniones. Significa «gracias». O «precaución»." },
	{ "GotaNube", "Gota de nube", "💧", "Resto de la Grieta. No se seca nunca. En los días tristes, dicen, sale el sol." },
	{ "CadenaColumpio", "Cadena del columpio viejo", "⛓️", "Resto de la Grieta. Del columpio donde tu abu grabó sus iniciales. Todavía chirría un poco." },
	{ "TizaSombra", "Tiza de sombra", "🖍️", "Resto de la Grieta. Para dibujar el contorno de tu sombra y que sepa dónde vive." },
	{ "EsquirlaEspejo", "Esquirla de espejo", "🪞", "Resto de la Grieta. Tu reflejo siempre sonríe en ella. Aunque tú no." },
	{ "PlumaCartero", "Pluma de paloma cartera", "🪶", "Resto de la Grieta. Regalo de la paloma 37. Cuenta como sello en la dimensión del pan infinito." },
	{ "VasoConsejos", "Vaso de los consejos", "🥤", "Resto de la Grieta. Dentro hay un papel: «Buena decisión». O «no le hagas caso a todo lo que dice una máquina»." },
	{ "SilbatoEco", "Silbato del eco", "📯", "Resto de la Grieta. Si soplas, no suena. Se oye un segundo después." },
	{ "CintaContestador", "Cinta del contestador", "📼", "Resto de la Grieta. Un mensaje de 1999: «que sepas que eres lo mejor que nos ha pasado»." },
	{ "CascabelCuantico", "Cascabel cuántico", "🔔", "Resto de la Grieta. A veces suena y a veces no, aunque no lo muevas. Es cuántico. O está roto." },
	{ "CucuruchoRecuerdos", "Cucurucho de los recuerdos", "🍦", "Resto de la Grieta. Vacío. Si lo hueles, sabe a tu primer día de colegio." },
	{ "PatitoDosLunas", "Patito de las dos lunas", "🦆", "Resto de la Grieta. Un patito de goma de un cielo con dos lunas. Flota hacia arriba si te descuidas." },
	{ "PartituraSinFin", "Partitura sin final", "🎼", "Resto de la Grieta. La canción más pegadiza del multiverso. Ahora, por fin, con final." },
	{ "NotaTaquilla", "Nota de la taquilla 66", "✉️", "Resto de la Grieta. De alguien de otra dimensión que va a tu mismo curso. Firma: «Tú, pero de otra parte»." },
	{ "TonerVerde", "Cartucho de tóner verde", "🖨️", "Resto de la Grieta. Imprime en verde Grieta. No lo metas en la fotocopiadora. En serio." },
	{ "ModemPitido", "Módem que pita", "📟", "Resto de la Grieta. Si lo enchufas, suena «piiii-krrrr» y se conecta a 1987." },
	{ "PinzaMultiversal", "Pinza de tender multiversal", "🧷", "Resto de la Grieta. Lo que tiendes con ella se seca en tres dimensiones a la vez." },
	{ "BilleteMinutos", "Billete de diez minutos", "💵", "Resto de la Grieta. No compra nada. Pero si lo gastas, tienes diez minutos más. Úsalo con cabeza." },
	-- Recuerdos exclusivos de las misiones locas
	{ "CoronaBigotes", "Corona del emperador Bigotes", "👑", "Mide dos centímetros. En Gatonia es enorme. Huele un poco a jamón." },
	{ "FotoClones", "Foto con tus clones", "📸", "Cuatro como tú haciendo el signo de la victoria. Uno tiene plastilina en la boca." },
	{ "MonedaPerez", "Moneda del Ratón Pérez", "🪙", "Oro de verdad, del año 1702. Un pirata la cambió por su último diente." },
	{ "LapizDimensional", "Lápiz de la Dimensión Examen", "✏️", "Escribe solo respuestas correctas… de preguntas que nadie ha hecho." },
	{ "FichaDorada", "Ficha dorada de Zoltán", "🟡", "La última ficha de la máquina de los deseos. Mejor no gastarla. Nunca." },
	{ "DienteRex", "Diente de Rex", "🦖", "Rex te lo regaló al mudarse. «Me salen nuevos cada martes.»" },
	{ "DiplomaUniverso", "Diploma del Universo", "📜", "Firmado por El Evaluador: «La Tierra aprueba. Por los pelos. Gracias a este humano.»" },
	{ "TarjetaGalactica", "Tarjeta del Banco Galáctico", "💳", "Sin límite. En ninguna tienda de la Tierra la aceptan. En Plutón, sí." },
	{ "GnomoAliado", "Rigoberto, gnomo aliado", "🧙", "Firmó la paz contigo. Ahora vigila tu jardín. Por la noche se mueve un poco." },
	{ "PerillaMalvada", "La perilla de tu yo malvado", "🥸", "Postiza. Se la quitaste en el duelo. Sin ella, tu yo malvado es solo un yo triste." },
	-- Misiones de aliados
	{ "BandaCanciller", "Banda de Canciller de Gatonia", "🎗️", "Regalo del presidente Bigotes. Sueldo: una siesta al sol por semana. Huele a atún." },
	{ "TarjetaRex", "Tarjeta de Rex, abogado", "📇", "«Rex. Abogado. Especialista en Anclas y jamón.» Tiene un mordisco en una esquina: es su firma." },
	{ "CarnetSindical", "Carnet del Sindicato de Roedores", "💳", "Miembro de honor. Firmado por el Ratón Pérez y por la rata, que ahora es jefa de turno." },
	{ "Formulario42B", "Formulario 42-B (sellado)", "📋", "El expediente del agente Cronos, archivado. Por detrás pone «Gracias». Con sello." },
	{ "ClaquetaAlien", "Claqueta alienígena", "🎬", "«Terrícolas en apuros · Final de temporada · Toma 1 de 1»." },
	{ "GorroGnomo", "Gorro de gnomo honorario", "🔺", "Te queda un poco pequeño. A todos los gnomos les queda un poco pequeño. Es la tradición." },
	{ "DiplomaBondad", "Diploma de bondad (con faltas)", "🎖️", "«Aprobado en bondad». Lo hizo tu yo malvado. Las faltas son a propósito." },
}
for _, entry in KEEPSAKES do
	list[entry[1]] = { Id = entry[1], Name = entry[2], Icon = entry[3], Kind = "Keepsake", Desc = entry[4], Stack = 99 }
end

-- Gadgets: recompensas exclusivas de las misiones secundarias locas (una por misión, no se venden)
--   Effect = Sling (bellota en arco) | Beam (rayo) | Bubbles (burbujas) | Teleport (salto de dimensión) | Message (dice algo) | Sparkle (brillo)
local GADGETS = {
	{ "Tirachinas", "El tirachinas de tu abu", "🪃", "El de verdad, el del Gran Torneo de 1962. Dispara bellotas que vuelan en arco y hacen «¡plof!». Regla de oro: nunca a personas ni a animales de verdad.", { Effect = "Sling", Cooldown = 0.8 } },
	{ "PistolaBurbujas", "Pistola de burbujas cuánticas", "🔵", "Invento de Cosme. Las burbujas existen en tres dimensiones a la vez. Explotan en las tres.", { Effect = "Bubbles" } },
	{ "RayoEncogedor", "Rayo encogedor", "🔬", "El rayo que convirtió un pollo de 6 metros en un pollo normal. Ahora solo hace «bzzzt» y da cosquillas.", { Effect = "Beam", Color = { 190, 90, 255 }, Cooldown = 1 } },
	{ "MovilFuturo", "Móvil del futuro", "📱", "Recibe mensajes de ti dentro de 10 años. Casi todos son sobre qué no comer.", { Effect = "Message", Lines = "Futuro", Cooldown = 4 } },
	{ "CascosAntiHipnosis", "Cascos anti-hipnosis", "🎧", "Suena una canción tan pegadiza que anula cualquier otra. Incluidas las de los alienígenas.", { Effect = "Sparkle", Color = { 255, 120, 220 }, Cooldown = 2 } },
	{ "PipBolsillo", "Pip de bolsillo", "🤖", "Una copia pequeñita de Pip, el robot de Cosme. Ya ha encontrado su propósito: hablarte.", { Effect = "Message", Lines = "Pip", Cooldown = 4 } },
	{ "PistolaRayos", "Pistola de rayos alienígena", "🔫", "Te la quedaste en el Monte del Silencio. Dispara un rayo verde que hace «piuuu». Los de la nave la echan de menos.", { Effect = "Beam", Color = { 90, 255, 120 }, Cooldown = 0.6 } },
	{ "MandoDimensiones", "Mando de dimensiones", "🌀", "Abre un portal y te lleva a otro sitio de la región. Cosme dice que «casi nunca» te lleva a una dimensión de gatos.", { Effect = "Teleport", Cooldown = 45 } },
	{ "GafasImpostores", "Gafas de ver impostores", "🕶️", "Todo el que las mira se siente observado. Los cambiaformas, mucho más.", { Effect = "Sparkle", Color = { 120, 255, 255 }, Cooldown = 2 } },
	{ "TazaTiempo", "Taza del tiempo", "☕", "El café nunca se enfría porque siempre es el mismo segundo dentro de la taza.", { Effect = "Message", Lines = "Taza", Cooldown = 4 } },
	{ "TostadoraCosme", "La tostadora de Cosme", "🍞", "Un trozo de la mente de Cosme vive aquí. Opina de todo. Tuesta regular.", { Effect = "Message", Lines = "Tostadora", Cooldown = 4 } },
}
for _, entry in GADGETS do
	local item = { Id = entry[1], Name = entry[2], Icon = entry[3], Kind = "Gadget", Desc = entry[4], Stack = 1 }
	for key, value in entry[5] do
		item[key] = value
	end
	list[entry[1]] = item
end

Items.List = list

function Items.get(id: string?): Item?
	return if id then list[id] else nil
end

-- Qué objetos tiene alguien y cuántos, a partir de sus datos guardados
function Items.owned(data: { [string]: any }): { [string]: number }
	local owned = {}
	for id, count in data.Items or {} do
		if list[id] and type(count) == "number" and count > 0 then
			owned[id] = count
		end
	end
	for key, has in data.Vehicles or {} do
		if has and list["Vehiculo_" .. key] then
			owned["Vehiculo_" .. key] = 1
		end
	end
	for key, has in data.Prizes or {} do
		if has and list["Premio_" .. key] then
			owned["Premio_" .. key] = 1
		end
	end
	for key, has in data.Licenses or {} do
		if has and list["Carnet_" .. key] then
			owned["Carnet_" .. key] = 1
		end
	end
	for title in (data.Education and data.Education.Degrees) or {} do
		if list["Titulo_" .. title] then
			owned["Titulo_" .. title] = 1
		end
	end
	return owned
end

return Items
