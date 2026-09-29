-- CityErrands: los «Encargos de la ciudad». Gente de Valmar con un ❗ encima de la cabeza que te pide
-- un favor pequeño: reponer yogures, bajar un balón de un árbol, llevar una receta a la farmacia,
-- acompañar a un turista perdido… Se pueden repetir y los hay por toda la ciudad, así que vayas donde
-- vayas hay algo que hacer. Aquí solo hay datos y cuentas (se pueden probar fuera de Roblox); quien
-- los pone en el mapa es CityErrandService (servidor) y quien los enseña, Controllers/CityErrands.
-- (Los encargos de los vecinos dentro de los edificios de pisos son otra cosa: shared/Errands.)
--
-- Sitios (Sites): dónde aparece quien pide el encargo y adónde te manda. Cada uno dice cómo encontrarlo
-- en el mapa (Models = nombres de modelos dentro de workspace.Town; Tag = etiqueta, con Attr si hace
-- falta), su horario (Hours = { abre, cierra }; nada = 24 horas) y si es un sitio al aire libre
-- (Outdoor: quien pide el encargo está dentro, no en la acera de delante).
--
-- Encargos (Templates):
--   Id, Title, Site (dónde está quien lo pide), Giver = { Name, Look?, Kid? (un crío: más bajito) },
--   Min/Max (etapas de la vida),
--   Hours? (además del horario del sitio), Lines (lo que te cuenta), Thanks (lo que dice al acabar),
--   Reward = { Money, Xp } (la base: se suma más cuanto más lejos te manda),
--   Give? (lo que te da al aceptar: «La receta»), Steps (1–3 pasos):
--     { Do = "Collect", Item = { Kind, Name, Prompt, Color? }, Count, At? (sitio; si no, junto a quien
--       lo pide), Min, Max (a qué distancia aparecen), Time? (segundos), Text }
--     { Do = "Deliver", To, Npc, Kid?, Prompt?, Line?, Text }   entregar lo que llevas a alguien
--     { Do = "Talk", To, Npc, Line?, Text }                hablar con alguien
--     { Do = "Reach", To, Text }                            ir a un sitio
--     { Do = "Escort", To, Text }                           ir con quien lo pide hasta un sitio (te sigue)
--   To = "Giver" (volver con quien lo pide), "Near" (alguien por aquí cerca, entre Min y Max) o el
--   nombre de un sitio (o una lista: el más cercano de ellos).
--   Time = número de segundos o "Trip" (según lo lejos que esté: los cafés se enfrían).
-- Los objetos (Item.Kind) son los tipos que ya existen en SceneService (Caja, Balon, Animal, Gato…).

local Stages = require(script.Parent.LifeStory.Stages)

local CityErrands = {}

local rgb = Color3.fromRGB

CityErrands.Config = {
	ScanEvery = 3, -- segundos entre repasos de quién aparece y quién se va
	TickEvery = 0.5, -- segundos entre repasos de los encargos en marcha
	SpawnRange = 170, -- solo aparece gente en los sitios a menos de esto de algún jugador
	DespawnRange = 280, -- y se va si no queda ningún jugador a menos de esto
	MinPlayerGap = 5, -- nunca aparece a menos de esto de un jugador (no te sale nadie encima)
	MaxPerArea = 3, -- como mucho tantos con ❗ en una zona…
	AreaRadius = 220, -- …de este radio
	MaxTotal = 30, -- y en todo el servidor
	SpawnsPerScan = 2, -- los que pueden aparecer en cada repaso alrededor de un jugador
	GiverCooldown = 600, -- segundos hasta que la misma persona (encargo + sitio) te vuelve a pedir algo
	DeclineCooldown = 180, -- si le dices que no, tarda esto en volver a preguntarte
	SiteRest = 60, -- después de un encargo, ese sitio descansa este rato
	MinTrip = 40, -- un «ve a otro sitio» es a más de esto (si no, no es un viaje)
	MaxTrip = 1400, -- ni más lejos que esto
	ReachRadius = 12, -- a esta distancia ya has llegado
	PromptDistance = 10,
	MarkRange = 400, -- los ❗ del mapa: los que están a menos de esto
	EscortLost = 70, -- si quien te sigue se queda más lejos que esto, te alcanza (aparece a tu lado)
	PerStud = 0.05, -- dinero por cada stud de viaje
	XpPerStud = 0.03, -- experiencia por cada stud de viaje
	RewardDistanceCap = 1500, -- (más lejos no paga más)
	TripSeconds = { Base = 45, PerStud = 0.12 }, -- Time = "Trip": 45 s + 0,12 s por stud
}

CityErrands.Sites = {
	Super = { Name = "el supermercado", Models = { "Supermercado" }, Hours = { 9, 22 } },
	Tienda = { Name = "la tienda", Tag = "Shop", Attr = { ShopId = { "Panaderia", "Fruteria", "Libreria", "Floristeria", "Heladeria", "Quiosco" } }, Hours = { 9, 21 } },
	Farmacia = { Name = "la farmacia", Tag = "Shop", Attr = { ShopId = { "Farmacia" } }, Hours = { 9, 22 } },
	Mercado = { Name = "el mercadillo de la plaza", Models = { "Plaza" }, Outdoor = true, Hours = { 8, 15 } },
	Plaza = { Name = "la plaza", Models = { "Plaza", "PlazaFinanciera" }, Outdoor = true },
	Parque = { Name = "el parque", Models = { "Parque", "ParqueNatural" }, Outdoor = true, Hours = { 7, 22 } },
	Playa = { Name = "la playa", Models = { "Playa" }, Outdoor = true, Hours = { 8, 21 } },
	Hospital = { Name = "el hospital", Models = { "Hospital", "CentroSalud" } },
	Estacion = { Name = "la estación", Models = { "EstacionCentral", "EstacionAutobuses", "BocaMetro", "ParadaBus" }, Hours = { 6, 24 } },
	Colegio = { Name = "el colegio", Models = { "Colegio" }, Hours = { 8, 18.5 } },
	Puerto = { Name = "el puerto", Models = { "Puerto", "Marina" }, Outdoor = true, Hours = { 6, 21 } },
	Campus = { Name = "la universidad", Models = { "Facultad" }, Hours = { 8, 21 } },
	Biblioteca = { Name = "la biblioteca", Tag = "Library", Hours = { 9, 21 } },
	Gasolinera = { Name = "la gasolinera", Models = { "Gasolinera" } },
	Cafeteria = { Name = "la cafetería", Tag = "Cafe", Models = { "Cafeteria" }, Hours = { 7, 22.5 } },
	Oficinas = { Name = "las oficinas", Models = { "Torres", "Oficinas", "TorreValmar" }, Hours = { 8, 20 } },
	Correos = { Name = "Correos", Tag = "PostOffice", Hours = { 8.5, 20.5 } },
	CentroComercial = { Name = "el centro comercial", Models = { "CentroComercial", "GranCentroComercial" }, Hours = { 10, 22 } },
	Policia = { Name = "la comisaría", Models = { "Policia" } },
	Bomberos = { Name = "el parque de bomberos", Models = { "Bomberos" } },
	Barrio = { Name = "una casa del barrio", Tag = "FamilyHome", Models = { "Vivienda", "Villa" }, Hours = { 8, 22 } },
} :: { [string]: { [string]: any } }

-- Tipos de pasos que existen (el validador de las pruebas los comprueba)
CityErrands.StepKinds = { Collect = true, Deliver = true, Talk = true, Reach = true, Escort = true }

local BROWN, WHITE = rgb(150, 100, 60), rgb(245, 245, 240)

CityErrands.Templates = {
	---------------------------------------------------------------- Supermercado
	{
		Id = "Super_Yogures", Site = "Super", Title = "Reponer los yogures",
		Giver = { Name = "Reponedora Lola", Look = { Shirt = rgb(40, 140, 80) } }, Min = "Adolescente",
		Lines = { "¡Ay, qué agobio! Ha llegado el camión y tengo las cajas de yogures tiradas por el muelle de carga.", "Si me traes tres cajas antes de que se calienten, te invito a algo. Bueno, te pago, que es mejor." },
		Thanks = "¡Yogures a salvo! Los de fresa te lo agradecen.",
		Reward = { Money = 30, Xp = 15 },
		Steps = {
			{ Do = "Collect", Item = { Kind = "Caja", Name = "Caja de yogures", Prompt = "Coger la caja", Color = rgb(220, 230, 250) }, Count = 3, Min = 10, Max = 22, Time = 120, Text = "Recoge las cajas de yogures del muelle" },
			{ Do = "Deliver", To = "Giver", Text = "Lleva las cajas a Lola" },
		},
	},
	{
		Id = "Super_CompraRosario", Site = "Super", Title = "La compra de la señora Rosario",
		Giver = { Name = "Cajero Toni", Look = { Shirt = rgb(40, 140, 80) } }, Min = "Nino",
		Lines = { "La señora Rosario se ha dejado aquí la compra otra vez. Lleva un mes haciéndolo.", "¿Se la acercas a su casa? Vive aquí al lado. Bueno, «al lado»." },
		Thanks = "¡Gracias! A ver si mañana se acuerda… (no se va a acordar).",
		Reward = { Money = 20, Xp = 12 }, Give = "Bolsas de la compra",
		Steps = {
			{ Do = "Deliver", To = "Barrio", Npc = "Señora Rosario", Line = "¡Mis garbanzos! Ay, qué despiste tengo. ¡Gracias, cielo!", Text = "Lleva la compra a casa de la señora Rosario" },
		},
	},
	---------------------------------------------------------------- Tiendas y mercado
	{
		Id = "Tienda_Pan", Site = "Tienda", Title = "Pan recién hecho para el bar",
		Giver = { Name = "Panadera Maribel" }, Min = "Nino",
		Lines = { "El bar de la esquina me ha pedido pan y yo no puedo dejar el mostrador.", "Llévaselo calentito, que si llega frío me echan la bronca a mí." },
		Thanks = "¡Llegó calentito! Eres más rápido que mi repartidor.",
		Reward = { Money = 18, Xp = 10 }, Give = "Bolsa de barras de pan",
		Steps = {
			{ Do = "Deliver", To = "Cafeteria", Npc = "Camarero Julián", Line = "¡Por fin! Sin pan no hay bocatas, y sin bocatas no hay vida.", Time = "Trip", Text = "Lleva el pan a la cafetería antes de que se enfríe" },
		},
	},
	{
		Id = "Mercado_Naranjas", Site = "Mercado", Title = "Una caja de naranjas",
		Giver = { Name = "Frutero Ramón" }, Min = "Nino",
		Lines = { "¡Naranjas de Valmar, dulces como la miel! Oye, tú, que tienes cara de buena gente.", "Llévale esta caja a la cafetería, que hacen los zumos con mis naranjas." },
		Thanks = "¡Gracias! Toma, y una naranja para el camino. Bueno, mejor el dinero.",
		Reward = { Money = 18, Xp = 10 }, Give = "Caja de naranjas",
		Steps = {
			{ Do = "Deliver", To = "Cafeteria", Npc = "Camarera Sonia", Line = "¡Las naranjas de Ramón! Hoy hay zumo para todos.", Text = "Lleva las naranjas a la cafetería" },
		},
	},
	{
		Id = "Mercado_Gallinas", Site = "Mercado", Title = "¡Se escapan las gallinas!",
		Giver = { Name = "Granjera Pepa" }, Min = "Nino",
		Lines = { "¡Que se me han escapado las gallinas del puesto! ¡Tres! ¡Corriendo por la plaza!", "Tráemelas antes de que alguien las confunda con palomas." },
		Thanks = "¡Todas en su caja! Ya decía yo que esa se llamaba Fugitiva por algo.",
		Reward = { Money = 25, Xp = 14 },
		Steps = {
			{ Do = "Collect", Item = { Kind = "Animal", Name = "Gallina escapada", Prompt = "Atrapar la gallina", Color = WHITE }, Count = 3, Min = 12, Max = 35, Time = 120, Text = "Atrapa las gallinas que corretean por la plaza" },
			{ Do = "Deliver", To = "Giver", Text = "Devuélvele las gallinas a Pepa" },
		},
	},
	---------------------------------------------------------------- Parque
	{
		Id = "Parque_Perro", Site = "Parque", Title = "¡Se ha escapado Trufa!",
		Giver = { Name = "Doña Amparo" }, Min = "Nino",
		Lines = { "¡Trufa! ¡Trufaaa! Se me ha soltado la correa y se ha ido detrás de una ardilla.", "Es marrón, pequeñita y cree que es un león. ¿Me ayudas a buscarla?" },
		Thanks = "¡Mi Trufa! Ya te dije que las ardillas no se dejan cazar, bonita.",
		Reward = { Money = 22, Xp = 14 },
		Steps = {
			{ Do = "Collect", Item = { Kind = "Animal", Name = "Trufa, la perrita", Prompt = "Coger a Trufa", Color = BROWN }, Count = 1, Min = 25, Max = 50, Text = "Busca a Trufa por el parque" },
			{ Do = "Deliver", To = "Giver", Text = "Devuélvele a Trufa a Doña Amparo" },
		},
	},
	{
		Id = "Parque_Balon", Site = "Parque", Title = "El balón en el árbol",
		Giver = { Name = "Hugo (8 años)", Kid = true, Look = { Shirt = rgb(230, 120, 40) } }, Min = "Nino", Max = "Adolescente",
		Lines = { "He chutado superfuerte y el balón se ha quedado colgado en un árbol.", "Tú llegas más alto que yo… ¿Me lo bajas? Te doy mis ahorros." },
		Thanks = "¡Gracias! La próxima vez chuto flojito. O no.",
		Reward = { Money = 10, Xp = 12 },
		Steps = {
			{ Do = "Collect", Item = { Kind = "Balon", Name = "Balón de Hugo", Prompt = "Bajar el balón", Color = rgb(250, 250, 250) }, Count = 1, Min = 15, Max = 30, Text = "Busca el balón en los árboles del parque" },
			{ Do = "Deliver", To = "Giver", Text = "Devuélvele el balón a Hugo" },
		},
	},
	{
		Id = "Parque_Basura", Site = "Parque", Title = "Parque limpio",
		Giver = { Name = "Jardinero Aurelio", Look = { Shirt = rgb(60, 120, 60) } }, Min = "Nino",
		Lines = { "Mira qué desastre: envoltorios por todas partes. Luego dicen que las palomas son las guarras.", "Si recoges cinco antes de que vuelva el viento, te pago la mañana." },
		Thanks = "¡Qué limpito! Hasta las palomas te miran con respeto.",
		Reward = { Money = 20, Xp = 12 },
		Steps = {
			{ Do = "Collect", Item = { Kind = "Envoltorio", Name = "Basura", Prompt = "Recoger" }, Count = 5, Min = 8, Max = 30, Time = 100, Text = "Recoge la basura del parque" },
			{ Do = "Deliver", To = "Giver", Text = "Dale la bolsa a Aurelio" },
		},
	},
	---------------------------------------------------------------- Playa
	{
		Id = "Playa_Sombrilla", Site = "Playa", Title = "La sombrilla voladora",
		Giver = { Name = "Turista Brigitte", Look = { Shirt = rgb(250, 200, 220) } }, Min = "Nino",
		Lines = { "Mon dieu! ¡El viento se ha llevado mi sombrilla! Ha salido volando como una gaviota.", "Sin sombrilla me pongo como una gamba. ¿Me la traes?" },
		Thanks = "Merci beaucoup! Sigo blanca como la leche, gracias a ti.",
		Reward = { Money = 18, Xp = 12 },
		Steps = {
			{ Do = "Collect", Item = { Kind = "Perchero", Name = "Sombrilla de Brigitte", Prompt = "Coger la sombrilla" }, Count = 1, Min = 25, Max = 50, Text = "Busca la sombrilla por la playa" },
			{ Do = "Deliver", To = "Giver", Text = "Devuélvele la sombrilla a Brigitte" },
		},
	},
	{
		Id = "Playa_Banista", Site = "Playa", Title = "¡Socorro! (o casi)",
		Giver = { Name = "Socorrista Iker", Look = { Shirt = rgb(220, 40, 40) } }, Min = "Adolescente",
		Lines = { "Ese señor de allí lleva un rato moviendo los brazos. Puede que se esté ahogando…", "…o puede que esté saludando a sus amigos. ¿Vas a ver? Yo vigilo al resto." },
		Thanks = "¿Saludando? Todos los veranos igual. Gracias por ir, de verdad.",
		Reward = { Money = 20, Xp = 15 },
		Steps = {
			{ Do = "Talk", To = "Near", Min = 25, Max = 45, Npc = "Bañista Fermín", Line = "¿Ahogarme yo? ¡Qué va! Saludaba a mi cuñado. ¡Hola, Paco!", Text = "Ve a ver qué le pasa al bañista" },
			{ Do = "Talk", To = "Giver", Text = "Cuéntale a Iker que era una falsa alarma" },
		},
	},
	{
		Id = "Playa_Crema", Site = "Playa", Title = "Crema, por favor",
		Giver = { Name = "Abuelo Evaristo" }, Min = "Nino",
		Lines = { "Se me ha acabado la crema y ya noto que me estoy tostando por la calva.", "¿Me compras un bote en la farmacia? Yo no me muevo de la toalla ni aunque me paguen." },
		Thanks = "¡Salvado! La calva te lo agradece.",
		Reward = { Money = 20, Xp = 12 },
		Steps = {
			{ Do = "Collect", At = "Farmacia", Item = { Kind = "Caja", Name = "Bote de crema solar", Prompt = "Coger la crema", Color = rgb(250, 220, 90) }, Count = 1, Min = 3, Max = 6, Text = "Ve a la farmacia a por crema solar" },
			{ Do = "Deliver", To = "Giver", Text = "Llévale la crema a Evaristo" },
		},
	},
	---------------------------------------------------------------- Hospital y farmacia
	{
		Id = "Hospital_Receta", Site = "Hospital", Title = "La receta del abuelo",
		Giver = { Name = "Enfermera Carmen", Look = { Shirt = rgb(120, 190, 220) } }, Min = "Nino",
		Lines = { "El señor Paco se ha ido a casa sin su receta. Si no se la lleva, no le dan las pastillas.", "Llévasela a la farmacia, que ya les he llamado. ¡Gracias, eres un sol!" },
		Thanks = "¡Gracias! El señor Paco ya puede tomarse sus pastillas… y quejarse de su sabor.",
		Reward = { Money = 20, Xp = 12 }, Give = "Receta del señor Paco",
		Steps = {
			{ Do = "Deliver", To = "Farmacia", Npc = "Farmacéutica Nuria", Line = "¡La receta de Paco! Ya le tengo las pastillas preparadas. Gracias.", Text = "Lleva la receta a la farmacia" },
		},
	},
	{
		Id = "Hospital_Flores", Site = "Hospital", Title = "Flores para la planta 3",
		Giver = { Name = "Celador Andrés", Look = { Shirt = rgb(120, 190, 220) } }, Min = "Nino",
		Lines = { "A la señora de la 312 hoy le dan el alta y quería darle una sorpresa.", "¿Me traes unas flores de la tienda? Si las compro yo, se nota que las he elegido yo." },
		Thanks = "¡Qué bonitas! Le van a encantar. Y a mí me van a subir el sueldo. O no.",
		Reward = { Money = 22, Xp = 12 },
		Steps = {
			{ Do = "Collect", At = "Tienda", Item = { Kind = "Caja", Name = "Ramo de flores", Prompt = "Coger el ramo", Color = rgb(240, 110, 160) }, Count = 1, Min = 3, Max = 6, Text = "Ve a la tienda a por un ramo de flores" },
			{ Do = "Deliver", To = "Giver", Text = "Llévale las flores a Andrés" },
		},
	},
	{
		Id = "Farmacia_Recado", Site = "Farmacia", Title = "Jarabe a domicilio",
		Giver = { Name = "Farmacéutico Julio", Look = { Shirt = rgb(240, 240, 240) } }, Min = "Nino",
		Lines = { "A la vecina del barrio se le ha puesto el crío malo y no puede salir.", "Llévale este jarabe, porfa. Sabe a fresa, dice el bote. Mentira, sabe a jarabe." },
		Thanks = "¡Gracias! Así da gusto.",
		Reward = { Money = 18, Xp = 10 }, Give = "Jarabe para la tos",
		Steps = {
			{ Do = "Deliver", To = "Barrio", Npc = "Vecina Lucía", Line = "¡Qué rápido! Mi peque ya está mejor solo de verte llegar.", Text = "Lleva el jarabe a casa de Lucía" },
		},
	},
	---------------------------------------------------------------- Estaciones
	{
		Id = "Estacion_Turista", Site = "Estacion", Title = "Turista perdido",
		Giver = { Name = "Turista Hans", Look = { Shirt = rgb(250, 240, 120) } }, Min = "Adolescente",
		Lines = { "Hallo! Perdón, mi español es… regular. Busco la plaza. O el parque. O algo bonito.", "Mi mapa está al revés y el móvil sin batería. ¿Me acompañas?" },
		Thanks = "Danke! ¡Valmar es preciosa! Y tú, un guía de cinco estrellas.",
		Reward = { Money = 25, Xp = 16 },
		Steps = {
			{ Do = "Escort", To = { "Plaza", "Parque", "Playa" }, Text = "Acompaña a Hans hasta un sitio bonito (te sigue)" },
		},
	},
	{
		Id = "Estacion_Cartera", Site = "Estacion", Title = "La cartera perdida",
		Giver = { Name = "Revisora Maite", Look = { Shirt = rgb(40, 60, 120) } }, Min = "Nino",
		Lines = { "Un pasajero dice que se le ha caído la cartera por aquí cerca y ha perdido el tren.", "Si la encuentras, llévala a la comisaría: allí la recoge. ¡Y sin mirar lo que hay dentro!" },
		Thanks = "¡Gracias! Y sin cotillear lo que había dentro, ¿eh? Así me gusta.",
		Reward = { Money = 22, Xp = 14 },
		Steps = {
			{ Do = "Collect", Item = { Kind = "Libro", Name = "Cartera perdida", Prompt = "Coger la cartera", Color = BROWN }, Count = 1, Min = 15, Max = 35, Text = "Busca la cartera por la estación" },
			{ Do = "Deliver", To = "Policia", Npc = "Agente Robles", Line = "¡Hombre, la cartera! El dueño ya ha llamado tres veces. Buen trabajo.", Text = "Lleva la cartera a la comisaría" },
		},
	},
	---------------------------------------------------------------- Colegio
	{
		Id = "Colegio_Mochila", Site = "Colegio", Title = "La mochila olvidada",
		Giver = { Name = "Conserje Benito" }, Min = "Nino", Max = "Adolescente",
		Lines = { "Algún despistado se ha dejado la mochila en el patio. Otra vez.", "Es de Lucas, vive por el barrio. ¿Se la llevas? Mañana tiene examen y los apuntes van dentro." },
		Thanks = "¡Gracias! Lucas no pierde la cabeza porque la lleva pegada.",
		Reward = { Money = 12, Xp = 12 },
		Steps = {
			{ Do = "Collect", Item = { Kind = "Mochila", Name = "Mochila de Lucas", Prompt = "Coger la mochila" }, Count = 1, Min = 10, Max = 25, Text = "Busca la mochila olvidada junto al colegio" },
			{ Do = "Deliver", To = "Barrio", Npc = "Lucas", Kid = true, Line = "¡Mi mochila! Me has salvado el examen. Bueno, ahora tengo que estudiar…", Text = "Lleva la mochila a casa de Lucas" },
		},
	},
	{
		Id = "Colegio_Deberes", Site = "Colegio", Title = "Los deberes de Paula",
		Giver = { Name = "Profe Marisa", Look = { Shirt = rgb(150, 80, 170) } }, Min = "Nino", Max = "Adolescente",
		Lines = { "Paula está en casa con fiebre y no quiero que se quede atrás con los deberes.", "¿Le llevas el cuaderno? Dile que no hace falta que los haga hoy. Mañana, sí." },
		Thanks = "¡Gracias! Eres un compañero de diez.",
		Reward = { Money = 10, Xp = 12 }, Give = "Cuaderno de deberes",
		Steps = {
			{ Do = "Deliver", To = "Barrio", Npc = "Paula", Kid = true, Line = "¿Deberes? ¡Qué ilusión! …Es broma. Pero gracias por venir.", Text = "Lleva los deberes a casa de Paula" },
		},
	},
	---------------------------------------------------------------- Puerto
	{
		Id = "Puerto_Cajas", Site = "Puerto", Title = "Descargar el barco",
		Giver = { Name = "Capitana Rocío", Look = { Shirt = rgb(30, 50, 90) } }, Min = "AdultoJoven",
		Lines = { "Mi marinero se ha mareado. Sí, un marinero que se marea. No preguntes.", "Hay que bajar cuatro cajas del muelle antes de que suba la marea. ¿Te animas?" },
		Thanks = "¡Buen trabajo, grumete! Si algún día quieres enrolarte, avísame.",
		Reward = { Money = 40, Xp = 20 },
		Steps = {
			{ Do = "Collect", Item = { Kind = "Caja", Name = "Caja del barco", Prompt = "Cargar la caja" }, Count = 4, Min = 10, Max = 28, Time = 150, Text = "Descarga las cajas del muelle" },
			{ Do = "Deliver", To = "Giver", Text = "Avisa a la capitana de que ya está" },
		},
	},
	{
		Id = "Puerto_Pescado", Site = "Puerto", Title = "Pescado fresco para el bar",
		Giver = { Name = "Pescador Chema" }, Min = "Adolescente",
		Lines = { "La cafetería me ha pedido boquerones para las tapas y yo huelo demasiado a pescado para entrar.", "Llévaselos rápido, que el pescado fresco es fresco un rato." },
		Thanks = "¡Gracias, marinero de tierra! Hueles un poquito a boquerón, pero vale la pena.",
		Reward = { Money = 22, Xp = 12 }, Give = "Caja de boquerones",
		Steps = {
			{ Do = "Deliver", To = "Cafeteria", Npc = "Cocinera Adela", Line = "¡Boquerones! Hoy la tapa del día es gratis… para ti no, lo siento.", Time = "Trip", Text = "Lleva el pescado a la cafetería antes de que deje de ser fresco" },
		},
	},
	---------------------------------------------------------------- Universidad
	{
		Id = "Campus_Apuntes", Site = "Campus", Title = "Fotocopias al viento",
		Giver = { Name = "Estudiante Nerea", Look = { Shirt = rgb(90, 90, 200) } }, Min = "Adolescente",
		Lines = { "¡Mis fotocopias! Un golpe de viento y los apuntes de todo el cuatrimestre por el campus.", "El examen es mañana. ¡Ayúdame a recoger tres hojas, que sin ellas suspendo seguro!" },
		Thanks = "¡Salvada! Te debo un café. O dos. Del de máquina.",
		Reward = { Money = 18, Xp = 14 },
		Steps = {
			{ Do = "Collect", Item = { Kind = "Papel", Name = "Hoja de apuntes", Prompt = "Coger la hoja" }, Count = 3, Min = 10, Max = 30, Time = 90, Text = "Recoge las fotocopias que se ha llevado el viento" },
			{ Do = "Deliver", To = "Giver", Text = "Devuélvele los apuntes a Nerea" },
		},
	},
	{
		Id = "Campus_Libro", Site = "Campus", Title = "Devolver el libro",
		Giver = { Name = "Profesor Anselmo", Look = { Shirt = rgb(110, 90, 70) } }, Min = "Adolescente",
		Lines = { "Tengo este libro de la biblioteca desde hace… ejem… tres años. La multa ya da miedo.", "Devuélvelo tú, que a mí la bibliotecaria me mira mal." },
		Thanks = "¡Gracias! Me has ahorrado la mirada asesina de la bibliotecaria.",
		Reward = { Money = 18, Xp = 12 }, Give = "Libro muy atrasado",
		Steps = {
			{ Do = "Deliver", To = { "Biblioteca", "Campus" }, Npc = "Bibliotecaria Elvira", Line = "¿Tres años? Dile a Anselmo que ya hablaremos. Gracias a ti, majo.", Text = "Devuelve el libro en la biblioteca" },
		},
	},
	---------------------------------------------------------------- Gasolinera
	{
		Id = "Gasolinera_Bidon", Site = "Gasolinera", Title = "Tirado sin gasolina",
		Giver = { Name = "Gasolinero Fede", Look = { Shirt = rgb(230, 160, 40) } }, Min = "AdultoJoven",
		Lines = { "Ha llamado un cliente: se ha quedado sin gasolina a unas calles de aquí. Por listo.", "Llévale este bidón, que yo no puedo dejar el surtidor." },
		Thanks = "¡Gracias! Otro que aprende a mirar el indicador.",
		Reward = { Money = 30, Xp = 15 }, Give = "Bidón de gasolina",
		Steps = {
			{ Do = "Deliver", To = "Near", Min = 60, Max = 110, Npc = "Conductor Paco", Line = "¡Mi héroe! Juro que la aguja marcaba medio depósito. Bueno, no lo juro.", Text = "Lleva el bidón al conductor que se ha quedado tirado" },
		},
	},
	{
		Id = "Gasolinera_Hielo", Site = "Gasolinera", Title = "Hielo para la tienda",
		Giver = { Name = "Dependienta Vero" }, Min = "Adolescente",
		Lines = { "Se ha roto la máquina del hielo y hoy hace un calor de muerte.", "¿Me traes unas bolsas del supermercado? Aquí sin hielo no hay refrescos fríos." },
		Thanks = "¡Hielo! Eres mi persona favorita del día.",
		Reward = { Money = 22, Xp = 12 },
		Steps = {
			{ Do = "Collect", At = "Super", Item = { Kind = "Caja", Name = "Bolsas de hielo", Prompt = "Coger el hielo", Color = rgb(200, 235, 255) }, Count = 1, Min = 3, Max = 6, Text = "Ve al supermercado a por hielo" },
			{ Do = "Deliver", To = "Giver", Time = "Trip", Text = "Lleva el hielo a la gasolinera antes de que se derrita" },
		},
	},
	---------------------------------------------------------------- Cafetería
	{
		Id = "Cafe_Oficina", Site = "Cafeteria", Title = "Cafés para la oficina",
		Giver = { Name = "Barista Dani", Look = { Shirt = rgb(96, 60, 38) } }, Min = "Adolescente",
		Lines = { "Una oficina me ha pedido seis cafés y mi repartidor se ha ido de vacaciones. A Tailandia.", "Llévalos rápido, que un café frío es un crimen." },
		Thanks = "¡Gracias! Ni una gota derramada. Contratado. Bueno, casi.",
		Reward = { Money = 25, Xp = 14 }, Give = "Bandeja de cafés",
		Steps = {
			{ Do = "Deliver", To = { "Oficinas", "CentroComercial" }, Npc = "Oficinista Marta", Line = "¡Cafés calentitos! Hoy la reunión va a ser hasta agradable.", Time = "Trip", Text = "Lleva los cafés a las oficinas antes de que se enfríen" },
		},
	},
	{
		Id = "Cafe_Bizcocho", Site = "Cafeteria", Title = "Bizcocho para la abuela",
		Giver = { Name = "Pastelera Inés" }, Min = "Nino",
		Lines = { "La abuela Mercedes cumple noventa años y le he hecho su bizcocho favorito.", "¿Se lo llevas? Con cuidado, que como se caiga me echa la culpa a mí." },
		Thanks = "¡Gracias! Y ni un pellizco al bizcocho… ¿verdad?",
		Reward = { Money = 18, Xp = 12 }, Give = "Bizcocho de cumpleaños",
		Steps = {
			{ Do = "Deliver", To = "Barrio", Npc = "Abuela Mercedes", Line = "¡Noventa añazos y mi bizcocho! Toma, cielo, que eres un encanto.", Text = "Lleva el bizcocho a casa de la abuela Mercedes" },
		},
	},
	---------------------------------------------------------------- Oficinas y correos
	{
		Id = "Oficina_Sobre", Site = "Oficinas", Title = "Un sobre muy urgente",
		Giver = { Name = "Ejecutivo Borja", Look = { Shirt = rgb(40, 40, 46) } }, Min = "Adolescente",
		Lines = { "¡Este sobre tiene que salir HOY! Y yo tengo reunión, y otra reunión, y una reunión sobre las reuniones.", "Llévalo a Correos, porfa. Es importantísimo. Creo." },
		Thanks = "¡Gracias! Ahora a por la siguiente reunión. Qué ilusión.",
		Reward = { Money = 25, Xp = 14 }, Give = "Sobre urgente",
		Steps = {
			{ Do = "Deliver", To = { "Correos", "Oficinas" }, Npc = "Cartera Susana", Line = "¿Urgente? Aquí todo es urgente. Pero lo mando ya, tranquilo.", Text = "Lleva el sobre a Correos" },
		},
	},
	---------------------------------------------------------------- Comisaría y bomberos
	{
		Id = "Policia_Testigo", Site = "Policia", Title = "El testigo despistado",
		Giver = { Name = "Inspectora Vidal", Look = { Shirt = rgb(30, 40, 80) } }, Min = "Adolescente",
		Lines = { "Tengo un testigo de un robo de bicicletas que se ha ido a por un bocadillo… y no ha vuelto.", "Está por aquí cerca. Pregúntale de qué color era la bici y vuelve a contármelo." },
		Thanks = "¿Una bici rosa con cestita? Caso resuelto. Buen trabajo, detective.",
		Reward = { Money = 25, Xp = 16 },
		Steps = {
			{ Do = "Talk", To = "Near", Min = 35, Max = 70, Npc = "Testigo Anselmo", Line = "¿La bici? Rosa, con cestita y un timbre de pato. ¡Cua, cua! Así sonaba.", Text = "Busca al testigo y pregúntale por la bici" },
			{ Do = "Talk", To = "Giver", Text = "Vuelve y cuéntaselo a la inspectora Vidal" },
		},
	},
	{
		Id = "Bomberos_Gato", Site = "Bomberos", Title = "Michi en apuros",
		Giver = { Name = "Bombero Nacho", Look = { Shirt = rgb(200, 40, 40) } }, Min = "Nino",
		Lines = { "Hay un gato subido a un sitio muy alto y los camiones están todos ocupados.", "Tú eres ágil. Bájalo y llévaselo a su dueña, que está muy preocupada." },
		Thanks = "¡Gracias, compañero! Ya puedes decir que has hecho un rescate de bombero.",
		Reward = { Money = 22, Xp = 16 },
		Steps = {
			{ Do = "Collect", Item = { Kind = "Gato", Name = "Michi", Prompt = "Bajar al gato" }, Count = 1, Min = 25, Max = 50, Text = "Encuentra al gato y bájalo con cuidado" },
			{ Do = "Deliver", To = "Barrio", Npc = "Doña Encarna", Line = "¡Michi! ¿Otra vez subido por ahí? Qué haría yo sin ti… y sin ti también, cariño.", Text = "Lleva a Michi a casa de Doña Encarna" },
		},
	},
	---------------------------------------------------------------- Barrio
	{
		Id = "Barrio_Paquete", Site = "Barrio", Title = "El paquete del vecino",
		Giver = { Name = "Vecino Genaro" }, Min = "Nino",
		Lines = { "El repartidor me ha dejado un paquete que no es mío. Otra vez. Ya somos amigos.", "Es para una casa de un poco más allá. ¿Se lo llevas? A mí me duelen las rodillas." },
		Thanks = "¡Gracias! Si mañana llega otro, ya sabes dónde vivo.",
		Reward = { Money = 18, Xp = 10 }, Give = "Paquete misterioso",
		Steps = {
			{ Do = "Deliver", To = "Barrio", Npc = "Vecina Chelo", Line = "¡Mis macetas nuevas! Llevaba una semana esperándolas. Gracias, guapo.", Text = "Lleva el paquete a casa de Chelo" },
		},
	},
	{
		Id = "Barrio_Coco", Site = "Barrio", Title = "Pasear a Coco",
		Giver = { Name = "Vecina Pilar" }, Min = "Nino",
		Lines = { "Coco no ha salido en todo el día y me está mirando con esos ojitos.", "¿Le das un paseo hasta el parque y me lo traes? No tira mucho de la correa. Bueno, un poco." },
		Thanks = "¡Qué contento viene! Mañana otra vez, ¿eh?",
		Reward = { Money = 18, Xp = 12 }, Give = "Coco (con su correa)",
		Steps = {
			{ Do = "Reach", To = "Parque", Text = "Pasea a Coco hasta el parque" },
			{ Do = "Deliver", To = "Giver", Text = "Devuélvele a Coco a Pilar" },
		},
	},
	---------------------------------------------------------------- Centro comercial
	{
		Id = "Centro_Mama", Site = "CentroComercial", Title = "¿Dónde está mamá?",
		Giver = { Name = "Dani (6 años)", Kid = true, Look = { Shirt = rgb(60, 110, 200) } }, Min = "Adolescente",
		Lines = { "(snif) Estaba mirando los juguetes y mamá ha desaparecido. Lleva un abrigo rojo.", "¿Me ayudas a encontrarla? Yo me quedo aquí quieto, como me dijo." },
		Thanks = "¡Mamá dice que ya viene! Gracias… ¡y no le digas que estaba en la sección de juguetes!",
		Reward = { Money = 22, Xp = 16 },
		Steps = {
			{ Do = "Talk", To = "Near", Min = 30, Max = 60, Npc = "Mamá de Dani", Line = "¡¿Dani?! ¡Gracias al cielo! ¿Dónde está? Voy corriendo.", Text = "Busca a la mamá de Dani (lleva un abrigo rojo)" },
			{ Do = "Talk", To = "Giver", Text = "Vuelve con Dani y dile que su madre viene" },
		},
	},
} :: { { [string]: any } }

CityErrands.ById = {} :: { [string]: { [string]: any } }
for _, template in CityErrands.Templates do
	CityErrands.ById[template.Id] = template
end

---------------------------------------------------------------------
-- Cuentas (sin Roblox: las usan el servicio y las pruebas)
---------------------------------------------------------------------

-- ¿Está abierto a esta hora? (nil = siempre; admite horarios que pasan la medianoche)
function CityErrands.isOpen(hours: { number }?, clock: number): boolean
	if not hours then
		return true
	end
	local from, to = hours[1], hours[2]
	if to >= 24 and from <= 0 then
		return true
	end
	if from <= to then
		return clock >= from and clock < to
	end
	return clock >= from or clock < to
end

-- ¿Puede alguien de esta etapa hacer este encargo? (los bebés, ninguno)
function CityErrands.fitsStage(template: { [string]: any }, stage: string?): boolean
	if stage == nil or stage == "Bebe" then
		return false
	end
	return Stages.inRange(stage, template.Min or "Nino", template.Max)
end

-- ¿Se puede pedir ahora? (el sitio abierto y la hora del encargo)
function CityErrands.openNow(template: { [string]: any }, clock: number): boolean
	local site = CityErrands.Sites[template.Site]
	return site ~= nil and CityErrands.isOpen(site.Hours, clock) and CityErrands.isOpen(template.Hours, clock)
end

-- Los encargos que puede pedir alguien en este tipo de sitio, a esta hora, a alguien de esta etapa
function CityErrands.forSite(siteKind: string, stage: string?, clock: number): { { [string]: any } }
	local list = {}
	for _, template in CityErrands.Templates do
		if template.Site == siteKind and CityErrands.fitsStage(template, stage) and CityErrands.openNow(template, clock) then
			table.insert(list, template)
		end
	end
	return list
end

-- Los sitios adonde manda un paso (To o At): lista de tipos de sitio (nil si es "Giver"/"Near")
function CityErrands.targetKinds(value: any): { string }?
	if type(value) == "string" then
		if value == "Giver" or value == "Near" then
			return nil
		end
		return { value }
	elseif type(value) == "table" then
		return value
	end
	return nil
end

-- La paga según lo que hay que andar (studs de ida y vuelta de todos los pasos)
function CityErrands.reward(template: { [string]: any }, distance: number): { Money: number, Xp: number }
	local cfg = CityErrands.Config
	local d = math.clamp(distance, 0, cfg.RewardDistanceCap)
	local base = template.Reward or {}
	return {
		Money = math.floor((base.Money or 0) + d * cfg.PerStud + 0.5),
		Xp = math.floor((base.Xp or 0) + d * cfg.XpPerStud + 0.5),
	}
end

-- Segundos de un paso con tiempo (Time = número o "Trip": según lo lejos que está)
function CityErrands.stepSeconds(step: { [string]: any }, distance: number): number?
	if type(step.Time) == "number" then
		return step.Time
	elseif step.Time == "Trip" then
		local trip = CityErrands.Config.TripSeconds
		return math.floor(trip.Base + distance * trip.PerStud + 0.5)
	end
	return nil
end

-- La clave de quien pide un encargo en un sitio (las esperas son por persona: encargo + sitio)
function CityErrands.giverKey(templateId: string, siteKey: string): string
	return templateId .. "@" .. siteKey
end

-- ¿Aún te está esperando? (cooldowns = { [clave] = hora a la que se puede volver a pedir })
function CityErrands.onCooldown(cooldowns: { [string]: number }?, key: string, now: number): boolean
	local until_ = cooldowns and cooldowns[key]
	return until_ ~= nil and now < until_
end

-- Revisa que los datos estén bien (lo usan las pruebas): devuelve la lista de problemas
function CityErrands.validate(): { string }
	local problems = {}
	local seen = {}
	for _, t in CityErrands.Templates do
		local function bad(text: string)
			table.insert(problems, ("%s: %s"):format(tostring(t.Id), text))
		end
		if seen[t.Id] then
			bad("Id repetido")
		end
		seen[t.Id] = true
		if not CityErrands.Sites[t.Site] then
			bad("sitio desconocido " .. tostring(t.Site))
		end
		if type(t.Title) ~= "string" or type(t.Giver) ~= "table" or type(t.Giver.Name) ~= "string" then
			bad("falta el título o quién lo pide")
		end
		if type(t.Lines) ~= "table" or #t.Lines == 0 then
			bad("sin frases")
		end
		if type(t.Steps) ~= "table" or #t.Steps < 1 or #t.Steps > 3 then
			bad("tiene que tener de 1 a 3 pasos")
		end
		if (t.Min and not Stages.isValid(t.Min)) or (t.Max and not Stages.isValid(t.Max)) then
			bad("etapa desconocida")
		end
		local carrying = t.Give ~= nil
		for i, step in t.Steps or {} do
			if not CityErrands.StepKinds[step.Do] then
				bad(("paso %d: tipo desconocido %s"):format(i, tostring(step.Do)))
			end
			if type(step.Text) ~= "string" then
				bad(("paso %d: sin texto"):format(i))
			end
			for _, kind in CityErrands.targetKinds(step.To or step.At) or {} do
				if not CityErrands.Sites[kind] then
					bad(("paso %d: sitio desconocido %s"):format(i, kind))
				end
			end
			if step.Do == "Collect" then
				if type(step.Item) ~= "table" or type(step.Item.Kind) ~= "string" or (step.Count or 0) < 1 then
					bad(("paso %d: objeto sin tipo o sin cantidad"):format(i))
				end
				carrying = true
			elseif step.Do == "Deliver" then
				if not carrying then
					bad(("paso %d: entregar sin llevar nada"):format(i))
				end
				carrying = false
			end
			if (step.Do == "Deliver" or step.Do == "Talk") and step.To ~= "Giver" and type(step.Npc) ~= "string" then
				bad(("paso %d: falta a quién (Npc)"):format(i))
			end
			if (step.Do == "Reach" or step.Do == "Escort") and CityErrands.targetKinds(step.To) == nil then
				bad(("paso %d: falta adónde (To)"):format(i))
			end
		end
	end
	return problems
end

return CityErrands
