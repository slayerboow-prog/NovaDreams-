-- Cast: el reparto de la historia. Cada personaje que aparece en una escena, habla en un diálogo o
-- se recuerda está aquí: nombre, voz (Config.Audio.Voices.Speakers), aspecto y personalidad.
--
--   Name      nombre que se ve (o clave de Strings)
--   NameAttr  (opcional) atributo del jugador con la clave de su nombre (la familia cambia en cada casa)
--   Voice     perfil de voz sintetizada
--   Kid       tamaño de niño (escala 0.65); Teen = 0.85; si no, adulto
--   Old       persona mayor: anda encorvada y con pasos cortos (Controllers/AgeMotion)
--   Skin, Shirt, Pants  colores (el aspecto sin necesitar ropa de catálogo)
--   Bio       personalidad (para quien escriba diálogos: así habla este personaje)
--
-- Ids especiales en diálogos: "Yo" = el jugador, "Narrador" = texto en cursiva sin personaje.

local rgb = Color3.fromRGB

export type Person = {
	Name: string,
	NameAttr: string?,
	Voice: string,
	Kid: boolean?,
	Teen: boolean?,
	Old: boolean?,
	Skin: Color3,
	Shirt: Color3,
	Pants: Color3,
	Shoes: Color3?,
	Hair: Color3?,
	LongHair: boolean?,
	LongSleeves: boolean?,
	Backpack: Color3?, -- mochila a la espalda (los niños del cole)
	Glow: Color3?, -- seres de otro mundo: brillan un poco (alienígenas, robots, fantasmas de lunes…)
	Body: string?, -- no es una persona: "GallinaGigante" = Petra (SceneService le pone el cuerpo de World/Kit/GallinaGigante);
	-- "Cucaracha" = las cucarachas de Crujiente (World/Kit/Cucaracha: seis patas, antenas; Bug = { Gorra, Medallas })
	Bug: { [string]: any }?,
	Bio: string,
}

local People: { [string]: Person } = {
	-- Familia (en la casa donde naciste; el nombre depende de la casa: Mamá/Papá, Abu Rosa/Abu Tomás)
	Familia = {
		Name = "NPC.MAMA", NameAttr = "FamilyKey", Voice = "Familia",
		Skin = rgb(198, 150, 112), Shirt = rgb(70, 120, 170), Pants = rgb(50, 50, 60),
		Hair = rgb(70, 45, 25),
		Bio = "Cariño con prisas. Bromea para que no estés nervioso. Siempre pregunta qué tal el día.",
	},
	Abu = {
		Name = "NPC.ABU_ROSA", NameAttr = "AbuKey", Voice = "Abu", Old = true,
		Skin = rgb(234, 196, 160), Shirt = rgb(150, 90, 120), Pants = rgb(90, 80, 70),
		Hair = rgb(200, 200, 205), LongSleeves = true,
		Bio = "Calma y refranes. Cuenta historias de cuando Valmar era un pueblo.",
	},

	-- Colegio: adultos
	Lucia = {
		Name = "NPC.PROFE_LUCIA", Voice = "Profe",
		Skin = rgb(226, 186, 150), Shirt = rgb(240, 196, 60), Pants = rgb(60, 70, 100),
		Hair = rgb(120, 80, 40), LongHair = true, LongSleeves = true,
		Bio = "Tutora de 1.º A. Cariñosa y exigente, frases cortas, humor seco. Estudió en este mismo colegio.",
	},
	Ramon = {
		Name = "Ramón", Voice = "Abu", Old = true,
		Skin = rgb(200, 150, 110), Shirt = rgb(60, 90, 150), Pants = rgb(40, 50, 70),
		Hair = rgb(190, 190, 195), LongSleeves = true,
		Bio = "Conserje. Bromista, lo sabe todo del colegio, lleva un manojo enorme de llaves.",
	},
	Marta = {
		Name = "Marta", Voice = "Profe",
		Skin = rgb(236, 200, 170), Shirt = rgb(70, 160, 90), Pants = rgb(60, 50, 50),
		Hair = rgb(20, 20, 22), LongHair = true,
		Bio = "Profe de música. Dulce, habla cantando, siempre tararea algo.",
	},
	Marisa = {
		Name = "Marisa", Voice = "Abu", Old = true,
		Skin = rgb(230, 190, 160), Shirt = rgb(120, 90, 150), Pants = rgb(60, 60, 70),
		Hair = rgb(190, 190, 195), LongHair = true, LongSleeves = true,
		Bio = "Bibliotecaria. Habla en susurros, lo presta todo, y todo lo apunta. Cree que un libro puede arreglar cualquier día malo.",
	},
	Paula = {
		Name = "Paula", Voice = "Profe",
		Skin = rgb(210, 160, 120), Shirt = rgb(90, 140, 60), Pants = rgb(90, 70, 50),
		Hair = rgb(150, 60, 30), LongHair = true,
		Bio = "Monitora de la granja escuela. Sabe el nombre de cada gallina. Muy seria con las normas de los animales.",
	},
	Julian = {
		Name = "Julián", Voice = "Abu", Old = true,
		Skin = rgb(190, 140, 100), Shirt = rgb(70, 90, 140), Pants = rgb(60, 60, 60),
		Hair = rgb(230, 230, 230), LongSleeves = true,
		Bio = "El granjero. Habla poco, sonríe mucho, se sabe todos los caminos del campo.",
	},
	Andres = {
		Name = "Andrés", Voice = "Profe",
		Skin = rgb(170, 120, 86), Shirt = rgb(220, 60, 60), Pants = rgb(30, 30, 40),
		Hair = rgb(20, 20, 22),
		Bio = "Profe de Educación Física. Silbato, entusiasmo, frases de entrenador.",
	},

	-- Colegio: la clase de 1.º A
	Nico = {
		Name = "NPC.NICO", Voice = "Nino", Kid = true,
		Skin = rgb(236, 196, 160), Shirt = rgb(220, 60, 50), Pants = rgb(40, 60, 120),
		Hair = rgb(70, 45, 25), Backpack = rgb(200, 50, 50),
		Bio = "Deportista, impulsivo, competitivo pero generoso. Todo es un reto. Habla con exclamaciones.",
	},
	Sara = {
		Name = "NPC.SARA", Voice = "Nino", Kid = true,
		Skin = rgb(242, 214, 180), Shirt = rgb(120, 190, 90), Pants = rgb(70, 70, 90),
		Hair = rgb(20, 20, 22), LongHair = true, Backpack = rgb(60, 160, 90),
		Bio = "Curiosa y científica, habla rapidísimo y usa palabras largas. Perfeccionista con los deberes.",
	},
	Omar = {
		Name = "NPC.OMAR", Voice = "Nino", Kid = true,
		Skin = rgb(170, 120, 86), Shirt = rgb(250, 170, 60), Pants = rgb(60, 60, 60),
		Hair = rgb(20, 20, 22), Backpack = rgb(230, 120, 40),
		Bio = "Artista tranquilo, siempre tiene hambre y un lápiz. Dibuja lo que pasa (sus dibujos son pistas).",
	},
	Mateo = {
		Name = "Mateo", Voice = "Nino", Kid = true,
		Skin = rgb(230, 190, 150), Shirt = rgb(140, 140, 200), Pants = rgb(80, 70, 60),
		Hair = rgb(120, 80, 40), Backpack = rgb(90, 90, 200),
		Bio = "Tímido, nuevo en el barrio, colecciona cromos. Se le caen las cosas. Leal cuando confía.",
	},
	Dani = {
		Name = "Dani", Voice = "Nino", Kid = true,
		Skin = rgb(230, 190, 150), Shirt = rgb(60, 200, 200), Pants = rgb(60, 60, 120),
		Hair = rgb(120, 80, 40), Backpack = rgb(60, 200, 200),
		Bio = "Hermano pequeño de Mateo (5 años). Todo lo pregunta. Adora su balón.",
	},
	Bruno = {
		Name = "Bruno", Voice = "Nino", Kid = true,
		Skin = rgb(220, 180, 140), Shirt = rgb(30, 30, 30), Pants = rgb(40, 40, 60),
		Hair = rgb(200, 160, 90), Backpack = rgb(30, 30, 34),
		Bio = "Líder de 'los malotes'. Fanfarrón, necesita que le miren. Su hermano mayor le presiona.",
	},
	Ruben = {
		Name = "Rubén", Voice = "Nino", Kid = true,
		Skin = rgb(236, 200, 170), Shirt = rgb(110, 60, 150), Pants = rgb(40, 40, 50),
		Hair = rgb(150, 60, 30), Backpack = rgb(120, 60, 160),
		Bio = "El bromista de Bruno. Hace cosas para que Bruno se ría; en el fondo quiere caer bien.",
	},
	Hugo = {
		Name = "Hugo", Voice = "Nino", Kid = true,
		Skin = rgb(190, 140, 100), Shirt = rgb(90, 100, 110), Pants = rgb(50, 50, 50),
		Hair = rgb(40, 28, 20), Backpack = rgb(240, 190, 40),
		Bio = "Va con Bruno pero no quiere. Le encantan los libros de piratas. Habla poco y bajito.",
	},
	Alex = {
		Name = "Álex", Voice = "Nino", Kid = true,
		Skin = rgb(240, 205, 175), Shirt = rgb(250, 250, 250), Pants = rgb(30, 90, 60),
		Hair = rgb(200, 160, 90), LongHair = true, Backpack = rgb(245, 245, 245),
		Bio = "Deportista, portera del equipo, directa y justa. Todo lo convierte en apuesta (sin dinero).",
	},
	Vega = {
		Name = "Vega", Voice = "Nino", Kid = true,
		Skin = rgb(200, 150, 120), Shirt = rgb(200, 120, 200), Pants = rgb(70, 50, 90),
		Hair = rgb(40, 28, 20), LongHair = true, Backpack = rgb(230, 120, 190),
		Bio = "Artista, soñadora, colecciona pegatinas brillantes. Habla de colores.",
	},
	Iker = {
		Name = "Iker", Voice = "Nino", Kid = true,
		Skin = rgb(236, 200, 170), Shirt = rgb(60, 110, 200), Pants = rgb(90, 90, 90),
		Hair = rgb(70, 45, 25), Backpack = rgb(60, 110, 200),
		Bio = "El que se lo sabe todo. Gafas, datos curiosos, un poco sabelotodo pero buena gente.",
	},

	-- Instituto (Campus Valmar)
	Javier = {
		Name = "Javier", Voice = "Profe",
		Skin = rgb(225, 185, 150), Shirt = rgb(90, 90, 140), Pants = rgb(50, 50, 60),
		Hair = rgb(110, 80, 50), LongSleeves = true,
		Bio = "Tutor de 1.º C y profe de Historia. Tranquilo, irónico, cita a filósofos cuando nadie se lo pide.",
	},
	Carmen = {
		Name = "Carmen", Voice = "Profe",
		Skin = rgb(200, 150, 115), Shirt = rgb(60, 150, 140), Pants = rgb(60, 50, 50),
		Hair = rgb(40, 30, 25), LongHair = true,
		Bio = "Orientadora del instituto. Escucha más que habla. «No tienes que saberlo hoy.»",
	},
	Leire = {
		Name = "Leire", Voice = "Nino", Kid = true,
		Skin = rgb(240, 215, 190), Shirt = rgb(40, 40, 50), Pants = rgb(60, 70, 110),
		Hair = rgb(150, 60, 40), LongHair = true, Backpack = rgb(200, 200, 200),
		Bio = "Nueva en Valmar (viene del norte). Siempre con una cámara vieja al cuello. Seca al principio, leal después.",
	},
	Rayo = {
		Name = "Rayo", Voice = "Nino", Kid = true,
		Skin = rgb(225, 180, 140), Shirt = rgb(30, 30, 30), Pants = rgb(40, 50, 90),
		Hair = rgb(20, 20, 22), Backpack = rgb(200, 40, 40),
		Bio = "De 4.º, el que manda en el muelle. Gracioso, valiente, peligroso. En casa no hay nadie casi nunca: su padre se fue y su madre trabaja de noche.",
	},
	Nerea = {
		Name = "Nerea", Voice = "Nino", Kid = true,
		Skin = rgb(200, 150, 115), Shirt = rgb(120, 40, 120), Pants = rgb(30, 30, 40),
		Hair = rgb(60, 30, 20), LongHair = true, Backpack = rgb(60, 60, 60),
		Bio = "De la pandilla de Rayo. Lista, sarcástica. Va con ellos porque no sabe con quién más ir. Dibuja cómics que no enseña a nadie.",
	},
	Veterano = { Name = "Alumno de 4.º", Voice = "Nino", Teen = true, Skin = rgb(215, 170, 130), Shirt = rgb(30, 30, 30), Pants = rgb(40, 40, 70), Hair = rgb(20, 20, 22), Bio = "Le encanta tomar el pelo a los de primero." },
	Delegada = { Name = "Delegada de 4.º", Voice = "Nino", Teen = true, Skin = rgb(185, 135, 100), Shirt = rgb(230, 170, 60), Pants = rgb(30, 30, 30), Hair = rgb(30, 20, 15), LongHair = true, Bio = "Organizada, amable, siempre con una carpeta." },

	Dario = { Name = "Darío", Voice = "Nino", Kid = true, Skin = rgb(230, 190, 150), Shirt = rgb(20, 120, 60), Pants = rgb(30, 30, 40), Hair = rgb(30, 25, 20), Bio = "De segundo, el gracioso del equipo de fútbol. No es malo: no piensa antes de hacer las cosas." },
	Paco = { Name = "Paco", Voice = "Abu", Skin = rgb(215, 170, 130), Shirt = rgb(200, 40, 40), Pants = rgb(40, 40, 50), Hair = rgb(150, 150, 150), Bio = "Encargado del supermercado. Gruñón por fuera, justo por dentro. Odia las cajas mal apiladas." },
	Ernesto = { Name = "Ernesto", Voice = "Profe", Skin = rgb(175, 125, 90), Shirt = rgb(250, 200, 40), Pants = rgb(40, 60, 120), Hair = rgb(20, 20, 22), Bio = "Jefe de Correos de Valmar. Se sabe todas las calles y todos los perros de cada calle." },

	-- La semana de las profesiones
	Nuria = { Name = "Doctora Nuria", Voice = "Profe", Skin = rgb(230, 190, 160), Shirt = rgb(245, 245, 245), Pants = rgb(80, 150, 170), Hair = rgb(60, 40, 30), LongHair = true, Bio = "Médica de urgencias. Rápida, cálida, habla con las manos." },
	-- (el mecánico se llama Tobías para no confundirlo con Abu Tomás; su id sigue siendo "Tomas")
	Tomas = { Name = "Tobías", Voice = "Abu", Skin = rgb(190, 140, 100), Shirt = rgb(40, 70, 130), Pants = rgb(40, 70, 130), Hair = rgb(120, 120, 120), Bio = "Mecánico de toda la vida. Manos negras de grasa y paciencia infinita." },
	Ines = { Name = "Agente Inés", Voice = "Profe", Skin = rgb(210, 165, 125), Shirt = rgb(30, 50, 110), Pants = rgb(30, 40, 70), Hair = rgb(30, 25, 20), Bio = "Policía de barrio. Conoce a todo el mundo por su nombre." },
	Marcos = { Name = "Marcos", Voice = "Profe", Skin = rgb(240, 205, 175), Shirt = rgb(250, 250, 250), Pants = rgb(40, 40, 60), Hair = rgb(200, 170, 110), Bio = "Dirige una pequeña empresa de bicicletas. Todo lo convierte en un plan." },
	Lola = { Name = "Chef Lola", Voice = "Familia", Skin = rgb(180, 125, 90), Shirt = rgb(250, 250, 250), Pants = rgb(30, 30, 30), Hair = rgb(20, 20, 22), LongHair = true, Bio = "Cocinera. Grita en la cocina y abraza fuera de ella." },
	Sofia = { Name = "Sofía", Voice = "Profe", Skin = rgb(235, 200, 170), Shirt = rgb(250, 250, 250), Pants = rgb(60, 60, 80), Hair = rgb(20, 20, 22), LongHair = true, Bio = "Ingeniera de laboratorio en la facultad. Le brillan los ojos con cualquier motor." },
	Irene = { Name = "Irene", Voice = "Profe", Skin = rgb(160, 110, 80), Shirt = rgb(240, 120, 40), Pants = rgb(30, 30, 30), Hair = rgb(20, 20, 22), Bio = "Entrenadora y fisioterapeuta. Cronómetro en una mano, bolsa de hielo en la otra." },
	Toni = { Name = "Toni", Voice = "Profe", Skin = rgb(225, 180, 140), Shirt = rgb(20, 20, 20), Pants = rgb(20, 20, 20), Hair = rgb(90, 60, 40), Bio = "Hace vídeos y documentales. Tío de Leire. Habla en planos: «esto, en primer plano, sería precioso»." },

	-- Universidad (Campus Valmar)
	Beltran = { Name = "Profesora Beltrán", Voice = "Rectora", Skin = rgb(225, 185, 150), Shirt = rgb(70, 70, 90), Pants = rgb(40, 40, 50), Hair = rgb(180, 180, 185), LongSleeves = true, Bio = "Profesora veterana de tu facultad. Exigente, justa, con un humor tan seco que tardas en pillarlo." },
	Luca = { Name = "Luca", Voice = "Profe", Skin = rgb(220, 180, 140), Shirt = rgb(40, 140, 90), Pants = rgb(50, 50, 70), Hair = rgb(40, 30, 20), Bio = "Estudiante de Erasmus (de Bolonia). Voluntario de bienvenida. Mezcla idiomas y lo arregla todo con comida." },
	Julia = { Name = "Julia", Voice = "Profe", Skin = rgb(240, 210, 185), Shirt = rgb(230, 230, 240), Pants = rgb(60, 60, 90), Hair = rgb(200, 150, 80), LongHair = true, Bio = "Del equipo del proyecto. Lo hace todo, lo revisa todo, no duerme. Le da pánico fallar." },
	Pablo = { Name = "Pablo", Voice = "Profe", Skin = rgb(190, 140, 100), Shirt = rgb(200, 90, 40), Pants = rgb(40, 40, 40), Hair = rgb(20, 20, 22), Bio = "Del equipo del proyecto. Encantador, nunca aparece. En realidad lo que le gusta es la música." },
	Adrian = { Name = "Adrián", Voice = "Profe", Skin = rgb(230, 195, 160), Shirt = rgb(30, 60, 120), Pants = rgb(200, 190, 170), Hair = rgb(120, 80, 40), Bio = "Del equipo del proyecto. Quiere mandar. Tiene una beca que no puede perder y eso le asusta." },
	Carla = { Name = "Carla", Voice = "Profe", Skin = rgb(170, 120, 90), Shirt = rgb(150, 60, 150), Pants = rgb(40, 40, 60), Hair = rgb(30, 20, 15), LongHair = true, Bio = "Del equipo del proyecto. Siempre llega tarde. Por las tardes cuida de su hermano pequeño." },
	Montse = { Name = "Montse", Voice = "Rectora", Skin = rgb(220, 180, 145), Shirt = rgb(40, 40, 60), Pants = rgb(40, 40, 60), Hair = rgb(90, 60, 40), LongHair = true, LongSleeves = true, Bio = "Abogada del bufete del distrito financiero. Tutora de prácticas. Habla despacio y nunca levanta la voz." },
	Ignacio = { Name = "Ignacio", Voice = "Profe", Skin = rgb(200, 150, 110), Shirt = rgb(240, 240, 245), Pants = rgb(30, 40, 70), Hair = rgb(40, 30, 25), LongSleeves = true, Bio = "Director de oficina del banco. Tutor de prácticas. Corbata torcida, números perfectos." },
	Vecino = { Name = "Un vecino", Voice = "Abu", Skin = rgb(190, 145, 110), Shirt = rgb(120, 110, 90), Pants = rgb(60, 60, 70), Hair = rgb(150, 150, 150), Bio = "" },
	Paciente = { Name = "Un paciente", Voice = "Abu", Skin = rgb(225, 185, 150), Shirt = rgb(150, 190, 210), Pants = rgb(150, 190, 210), Hair = rgb(200, 200, 200), Bio = "" },
	Rocio = { Name = "Rocío", Voice = "Familia", Skin = rgb(200, 150, 115), Shirt = rgb(90, 140, 190), Pants = rgb(50, 50, 60), Hair = rgb(60, 40, 25), LongHair = true, Bio = "Madre de Alba. Enfermera de noche. Siempre con prisa y siempre sonriendo." },
	Alba = { Name = "Alba", Voice = "Nino", Kid = true, Skin = rgb(240, 205, 175), Shirt = rgb(250, 180, 60), Pants = rgb(60, 80, 140), Hair = rgb(120, 70, 30), LongHair = true, Backpack = rgb(250, 120, 160), Bio = "9 años. Odia las fracciones. Adora los dinosaurios. Pregunta «¿y por qué?» cuarenta veces por hora." },

	-- Gente de fondo (entrada del colegio, calle)
	Alumno1 = { Name = "Alumno", Voice = "Nino", Kid = true, Skin = rgb(236, 196, 160), Shirt = rgb(250, 200, 70), Pants = rgb(40, 50, 90), Bio = "" },
	Alumno2 = { Name = "Alumna", Voice = "Nino", Kid = true, Skin = rgb(180, 130, 95), Shirt = rgb(90, 180, 220), Pants = rgb(60, 40, 70), Bio = "" },
	Alumno3 = { Name = "Alumno", Voice = "Nino", Kid = true, Skin = rgb(240, 210, 180), Shirt = rgb(120, 200, 120), Pants = rgb(50, 50, 50), Bio = "" },
	Alumno4 = { Name = "Alumna", Voice = "Nino", Kid = true, Skin = rgb(210, 160, 120), Shirt = rgb(240, 120, 150), Pants = rgb(40, 60, 100), Bio = "" },
	Mayor1 = { Name = "Alumno de 6.º", Voice = "Nino", Teen = true, Skin = rgb(220, 180, 140), Shirt = rgb(40, 40, 40), Pants = rgb(30, 30, 60), Bio = "" },
	Mayor2 = { Name = "Alumna de 6.º", Voice = "Nino", Teen = true, Skin = rgb(190, 140, 100), Shirt = rgb(200, 60, 60), Pants = rgb(30, 30, 30), Bio = "" },
	Madre = { Name = "Una madre", Voice = "Familia", Skin = rgb(230, 190, 150), Shirt = rgb(180, 80, 80), Pants = rgb(50, 50, 70), Bio = "" },
	Padre = { Name = "Un padre", Voice = "Familia", Skin = rgb(170, 120, 86), Shirt = rgb(80, 120, 80), Pants = rgb(40, 40, 50), Bio = "" },
	-- MISIONES LOCAS (secundarias de cada etapa, estilo dibujos de ciencia ficción gamberra) ----------
	-- El hilo de todas: Cosme, el vecino inventor. Genio, desastre, cariñoso a su manera.
	Cosme = {
		Name = "Cosme", Voice = "Abu",
		Skin = rgb(236, 205, 180), Shirt = rgb(235, 235, 225), Pants = rgb(90, 80, 110),
		Hair = rgb(245, 245, 250), LongSleeves = true,
		Bio = "El vecino del garaje. Inventor genial y caótico, pelo blanco de punta, bata con quemaduras. Habla deprisa, te llama «criatura», desprecia la «ciencia aburrida» y dice que no le importa nada… pero siempre vuelve a por ti. Nunca bebe alcohol: bebe batido de apio «por el potasio cuántico».",
	},
	Pip = {
		Name = "Pip", Voice = "Profe", Glow = rgb(90, 200, 255),
		Skin = rgb(170, 180, 195), Shirt = rgb(120, 130, 150), Pants = rgb(90, 100, 120), Shoes = rgb(60, 60, 70),
		Bio = "El robot mayordomo de Cosme. Educadísimo, dramático, en plena crisis existencial: quiere saber para qué sirve.",
	},
	-- Universidad: tus compañeros de habitación en la residencia (de tu misma clase)
	Ivan = { Name = "Iván", Voice = "Profe", Skin = rgb(215, 170, 130), Shirt = rgb(120, 40, 90), Pants = rgb(40, 40, 50), Hair = rgb(60, 40, 25), Bio = "Compañero de cuarto. De Villaverde, nieto de granjeros. Caótico, generoso, duerme en cualquier postura. Obsesionado con el zumo de mora casero de su abuela: lo guarda en la nevera como si fuera oro." },
	Candela = { Name = "Candela", Voice = "Rectora", Skin = rgb(235, 200, 170), Shirt = rgb(90, 160, 120), Pants = rgb(50, 60, 80), Hair = rgb(160, 70, 40), LongHair = true, Bio = "Compañera de cuarto. Organizadísima: etiquetas de colores, horarios plastificados, una lista para cada lista. Por dentro, un volcán. Nadie toca sus tápers." },
	Portero = { Name = "Doña Pilar, la conserje de la residencia", Voice = "Abu", Skin = rgb(200, 150, 115), Shirt = rgb(60, 90, 140), Pants = rgb(50, 50, 60), Hair = rgb(200, 200, 205), LongSleeves = true, Bio = "Lleva cuarenta años en la residencia. Ha visto de todo. Sabe quién ha hecho qué solo mirando las llaves." },
	DonPinzas = { Name = "Don Pinzas, cangrejo abogado", Voice = "Abu", Glow = rgb(255, 120, 80), Skin = rgb(230, 80, 50), Shirt = rgb(40, 40, 60), Pants = rgb(230, 80, 50), Bio = "Cangrejo gigante de otra dimensión. Abogado. Reclama la playa en nombre de los crustáceos con un contrato de 1734." },
	Tito = { Name = "Tito", Voice = "Nino", Skin = rgb(225, 190, 160), Shirt = rgb(200, 200, 60), Pants = rgb(60, 60, 80), Hair = rgb(90, 60, 30), Bio = "El cuarto compañero de habitación. Sale en todas las fotos. Nadie recuerda haberle conocido. Sonríe demasiado." },
	-- La saga de la Grieta
	Cosimo = { Name = "Doctor Cósimo", Voice = "Abu", Glow = rgb(200, 40, 60), Skin = rgb(230, 200, 175), Shirt = rgb(25, 25, 30), Pants = rgb(60, 20, 30), Hair = rgb(245, 245, 250), LongSleeves = true, Bio = "El villano. Era el socio de Cosme. Cayó por la Grieta a la dimensión 66-B la noche en que naciste y allí se dejó perilla, porque es el reglamento. Elegante, rencoroso, habla como un presentador de concursos. Quiere la Gran Fusión." },
	DonEscamas = { Name = "Don Escamas", Voice = "Abu", Kid = true, Glow = rgb(90, 200, 255), Skin = rgb(240, 150, 60), Shirt = rgb(240, 150, 60), Pants = rgb(240, 150, 60), Bio = "Pez de otra dimensión que respira aire y habla demasiado. Ex contable del Consorcio. Chismoso, asustadizo, adorable." },
	AgenteGris1 = { Name = "Agente de MegaVerso", Voice = "Profe", Skin = rgb(210, 200, 190), Shirt = rgb(110, 110, 115), Pants = rgb(90, 90, 95), LongSleeves = true, Bio = "Agente del Consorcio MegaVerso S.A. Traje gris, sonrisa de anuncio, gafas oscuras de noche." },
	AgenteGris2 = { Name = "Agente de MegaVerso", Voice = "Rectora", Skin = rgb(200, 185, 170), Shirt = rgb(110, 110, 115), Pants = rgb(90, 90, 95), LongSleeves = true, Bio = "Agente del Consorcio. Todo lo dice como si fuera un eslogan." },
	Funcionaria = { Name = "Funcionaria de la ventanilla", Voice = "Rectora", Skin = rgb(220, 180, 150), Shirt = rgb(150, 120, 170), Pants = rgb(60, 60, 70), Hair = rgb(110, 70, 50), LongHair = true, LongSleeves = true, Bio = "Trabaja en todas las ventanillas a la vez. Nadie sabe cómo. Siempre falta un papel." },
	CalcetinMonstruo = { Name = "El Monstruo de los Calcetines Desparejados", Voice = "Profe", Glow = rgb(255, 120, 200), Skin = rgb(250, 120, 180), Shirt = rgb(90, 200, 250), Pants = rgb(250, 230, 80), Bio = "Hecho con todos los calcetines que se han perdido en Valmar desde 1950. Solo quiere encontrar a su pareja." },
	Hilacha1 = { Name = "Hilacha", Voice = "Nino", Kid = true, Glow = rgb(120, 255, 160), Skin = rgb(160, 255, 190), Shirt = rgb(120, 230, 150), Pants = rgb(90, 200, 120), Bio = "Bicho hecho de hilo de costura suelto. Donde la Grieta se descose, salen hilachas: traviesas, rápidas y con cosquillas." },
	Hilacha2 = { Name = "Hilacha grande", Voice = "Profe", Kid = true, Glow = rgb(120, 255, 160), Skin = rgb(140, 240, 170), Shirt = rgb(100, 210, 130), Pants = rgb(80, 180, 110), Bio = "La hilacha jefa. Se enreda en todo. Se cree una madeja." },
	RobotSeguridad = { Name = "Robot de seguridad de MegaVerso", Voice = "Profe", Glow = rgb(255, 80, 80), Skin = rgb(170, 175, 185), Shirt = rgb(60, 60, 70), Pants = rgb(60, 60, 70), Bio = "Seguridad del Consorcio. Educado, lento, repite «tiene usted una llamada de ventas» en bucle." },
	DronCosimo1 = { Name = "Dron de Cósimo", Voice = "Nino", Kid = true, Glow = rgb(200, 40, 60), Skin = rgb(40, 40, 45), Shirt = rgb(150, 30, 45), Pants = rgb(40, 40, 45), Bio = "Dron con perilla pintada. Obedece a Cósimo. Emite música de concurso." },
	DronCosimo2 = { Name = "Dron de Cósimo", Voice = "Nino", Kid = true, Glow = rgb(200, 40, 60), Skin = rgb(40, 40, 45), Shirt = rgb(150, 30, 45), Pants = rgb(40, 40, 45), Bio = "Otro dron con perilla pintada. Aplaude cuando su jefe hace un chiste." },
	DronCosimo3 = { Name = "Dron jefe de Cósimo", Voice = "Profe", Kid = true, Glow = rgb(255, 60, 80), Skin = rgb(30, 30, 35), Shirt = rgb(180, 30, 50), Pants = rgb(30, 30, 35), Bio = "El dron favorito de Cósimo. Lleva una pajarita. Se cree presentador." },
	GatoPolicia1 = { Name = "Gato policía de Gatonia", Voice = "Profe", Glow = rgb(90, 160, 255), Skin = rgb(200, 150, 90), Shirt = rgb(30, 50, 110), Pants = rgb(30, 40, 80), Bio = "Agente de la dimensión G-4. Pone multas por no tener correa. Ronronea al esposar." },
	GatoPolicia2 = { Name = "Gata policía de Gatonia", Voice = "Rectora", Glow = rgb(90, 160, 255), Skin = rgb(120, 110, 100), Shirt = rgb(30, 50, 110), Pants = rgb(30, 40, 80), Bio = "Sargento de la G-4. Nunca persigue: acecha. Luego salta." },
	-- Niño
	Bigotes = { Name = "Bigotes XVII", Voice = "Rectora", Kid = true, Skin = rgb(240, 150, 60), Shirt = rgb(240, 150, 60), Pants = rgb(240, 150, 60), Bio = "El gato del colegio. En realidad, emperador exiliado de Gatonia. Solemne, vanidoso, odia que le toquen la barriga." },
	PalomaRobot1 = { Name = "Paloma robot", Voice = "Nino", Kid = true, Glow = rgb(120, 200, 255), Skin = rgb(150, 155, 170), Shirt = rgb(120, 125, 140), Pants = rgb(90, 95, 110), Shoes = rgb(240, 140, 60), Bio = "Dron de Cosme con forma de paloma. Programado para «recoger migas». Ahora roba bocadillos enteros." },
	PalomaRobot2 = { Name = "Paloma robot", Voice = "Nino", Kid = true, Glow = rgb(120, 200, 255), Skin = rgb(160, 160, 175), Shirt = rgb(110, 115, 130), Pants = rgb(90, 95, 110), Shoes = rgb(240, 140, 60), Bio = "Otra paloma robot. Dice «cucurrú» con voz de contestador automático." },
	PalomaRobot3 = { Name = "Paloma robot jefa", Voice = "Profe", Kid = true, Glow = rgb(255, 120, 120), Skin = rgb(140, 145, 160), Shirt = rgb(200, 60, 60), Pants = rgb(90, 95, 110), Shoes = rgb(240, 140, 60), Bio = "La jefa de las palomas robot. Tiene un ojo rojo y un bocadillo de chorizo en el pico." },
	Cucaracha1 = { Name = "Crujo", Voice = "Profe", Kid = true, Body = "Cucaracha", Glow = rgb(200, 140, 60), Skin = rgb(110, 70, 40), Shirt = rgb(80, 50, 30), Pants = rgb(60, 40, 25), Bio = "Cazarrecompensas del planeta Crujiente. Cucaracha espacial. Muy chulito." },
	Cucaracha2 = { Name = "Antenas", Voice = "Profe", Kid = true, Body = "Cucaracha", Glow = rgb(200, 140, 60), Skin = rgb(120, 80, 45), Shirt = rgb(90, 55, 30), Pants = rgb(60, 40, 25), Bio = "Cazarrecompensas. Solo sabe decir cosas de antenas." },
	Cucaracha3 = { Name = "Sargento Patitas", Voice = "Abu", Kid = true, Body = "Cucaracha", Bug = { Gorra = rgb(70, 90, 50), Medallas = 6 }, Glow = rgb(200, 140, 60), Skin = rgb(100, 60, 35), Shirt = rgb(70, 90, 50), Pants = rgb(60, 40, 25), Bio = "Jefe de las cucarachas. Seis patas, seis medallas." },
	PolloGigante = { Name = "Gallina Petra (6 metros)", Voice = "Nino", Body = "GallinaGigante", Skin = rgb(250, 250, 245), Shirt = rgb(250, 250, 245), Pants = rgb(245, 200, 60), Shoes = rgb(245, 170, 40), Hair = rgb(220, 40, 40), Bio = "Una gallina de la granja de Villaverde alcanzada por el rayo agrandador de Cosme. Asustada y ENORME." },
	Clon1 = { Name = "Tu clon (el hambriento)", Voice = "Nino", Kid = true, Glow = rgb(120, 255, 200), Skin = rgb(225, 185, 150), Shirt = rgb(70, 130, 220), Pants = rgb(50, 60, 90), Bio = "Clon 1. Se come los deberes. Literalmente." },
	Clon2 = { Name = "Tu clon (el cantante)", Voice = "Nino", Kid = true, Glow = rgb(120, 255, 200), Skin = rgb(225, 185, 150), Shirt = rgb(70, 130, 220), Pants = rgb(50, 60, 90), Bio = "Clon 2. Todo lo dice cantando." },
	Clon3 = { Name = "Tu clon (el mandón)", Voice = "Nino", Kid = true, Glow = rgb(120, 255, 200), Skin = rgb(225, 185, 150), Shirt = rgb(70, 130, 220), Pants = rgb(50, 60, 90), Bio = "Clon 3. Quiere ser delegado de clase, alcalde y rey. En ese orden." },
	RatonPerez = { Name = "Ratón Pérez", Voice = "Abu", Kid = true, Glow = rgb(255, 215, 90), Skin = rgb(170, 170, 175), Shirt = rgb(60, 60, 120), Pants = rgb(60, 60, 70), Bio = "El de los dientes. 300 años sin vacaciones. Ahora es sindicalista y está harto." },
	RataLadrona = { Name = "Rata Ladrona", Voice = "Profe", Kid = true, Skin = rgb(90, 90, 95), Shirt = rgb(30, 30, 30), Pants = rgb(30, 30, 30), Bio = "Roba dientes para venderlos en el mercado negro de las hadas. Muy rápida." },
	-- Adolescente
	TuFuturo = { Name = "Tú, dentro de 10 años", Voice = "Familia", Glow = rgb(180, 160, 255), Skin = rgb(225, 185, 150), Shirt = rgb(60, 60, 70), Pants = rgb(40, 40, 50), LongSleeves = true, Bio = "Tú, con diez años más, ojeras y una cazadora de otro siglo. Viene del futuro a pedirte algo muy importante (y ridículo)." },
	Lapiz1 = { Name = "Profe Lápiz", Voice = "Profe", Glow = rgb(255, 220, 60), Skin = rgb(250, 210, 60), Shirt = rgb(250, 210, 60), Pants = rgb(240, 150, 150), Bio = "Un lápiz gigante de la Dimensión Examen. Corrige todo. Todo." },
	Lapiz2 = { Name = "Lápiz Corrector", Voice = "Profe", Glow = rgb(255, 220, 60), Skin = rgb(250, 200, 50), Shirt = rgb(250, 200, 50), Pants = rgb(240, 150, 150), Bio = "Lápiz gigante. Pone faltas de ortografía a las nubes." },
	Lapiz3 = { Name = "Jefa de Estudios Grafito", Voice = "Rectora", Glow = rgb(255, 220, 60), Skin = rgb(240, 190, 40), Shirt = rgb(70, 70, 70), Pants = rgb(240, 150, 150), Bio = "La lápiz más afilada de la dimensión. Examina hasta los sueños." },
	DJZumbido = { Name = "DJ Zumbido", Voice = "Profe", Glow = rgb(255, 90, 220), Skin = rgb(160, 220, 120), Shirt = rgb(30, 30, 30), Pants = rgb(200, 40, 160), Bio = "DJ alienígena. Pincha una canción tan pegadiza que hipnotiza. Quiere a toda la Tierra bailando para siempre (y comprando su merchandising)." },
	Fan1 = { Name = "Fan hipnotizado", Voice = "Nino", Teen = true, Glow = rgb(255, 90, 220), Skin = rgb(220, 180, 140), Shirt = rgb(255, 90, 200), Pants = rgb(40, 40, 60), Bio = "Solo repite el estribillo." },
	Fan2 = { Name = "Fan hipnotizada", Voice = "Nino", Teen = true, Glow = rgb(255, 90, 220), Skin = rgb(190, 140, 100), Shirt = rgb(255, 90, 200), Pants = rgb(40, 40, 60), Bio = "Solo repite el estribillo, pero más alto." },
	Fan3 = { Name = "Fan muy hipnotizado", Voice = "Nino", Teen = true, Glow = rgb(255, 90, 220), Skin = rgb(240, 210, 180), Shirt = rgb(255, 90, 200), Pants = rgb(40, 40, 60), Bio = "Baila tan mal que da miedo." },
	Zoltan = { Name = "Zoltán, la máquina de los deseos", Voice = "Rectora", Glow = rgb(255, 200, 80), Skin = rgb(200, 160, 60), Shirt = rgb(120, 40, 120), Pants = rgb(80, 30, 80), Bio = "Máquina de los recreativos que concede deseos. Al pie de la letra. Siempre al pie de la letra." },
	Seguidor1 = { Name = "Fan número 1", Voice = "Nino", Teen = true, Skin = rgb(220, 180, 140), Shirt = rgb(250, 250, 250), Pants = rgb(60, 60, 60), Bio = "Te hace caso. Demasiado caso." },
	Seguidor2 = { Name = "Fan número 2", Voice = "Nino", Teen = true, Skin = rgb(190, 140, 100), Shirt = rgb(250, 250, 250), Pants = rgb(60, 60, 60), Bio = "Te hace caso y lo apunta todo." },
	Seguidor3 = { Name = "Fan número 3", Voice = "Familia", Skin = rgb(230, 190, 150), Shirt = rgb(250, 250, 250), Pants = rgb(60, 60, 60), Bio = "Un señor que pasaba por ahí. Ahora también te hace caso." },
	-- Universidad
	Zarg = { Name = "Zarg", Voice = "Profe", Glow = rgb(90, 255, 120), Skin = rgb(120, 220, 110), Shirt = rgb(60, 70, 90), Pants = rgb(60, 70, 90), Bio = "Alienígena de la nave del Monte del Silencio. Productor de un reality intergaláctico. Muy mal humor." },
	Blorp = { Name = "Blorp", Voice = "Nino", Glow = rgb(90, 255, 120), Skin = rgb(140, 230, 120), Shirt = rgb(60, 70, 90), Pants = rgb(60, 70, 90), Bio = "Alienígena. Becario de la nave. Hace todo lo que le dicen, pero mal." },
	CapitanNoz = { Name = "Capitana Ñoz", Voice = "Rectora", Glow = rgb(90, 255, 120), Skin = rgb(100, 200, 100), Shirt = rgb(150, 40, 40), Pants = rgb(60, 70, 90), Bio = "Capitana de la nave. Abduce humanos para su programa «Terrícolas en apuros». Lleva 300 temporadas." },
	Fermin = { Name = "Fermín, el senderista", Voice = "Abu", Skin = rgb(210, 160, 120), Shirt = rgb(200, 120, 40), Pants = rgb(90, 80, 60), Hair = rgb(150, 150, 150), Bio = "Senderista desaparecido hace tres semanas. Ha pasado todo este tiempo en un plató alienígena. Ahora es un poco famoso en la galaxia." },
	Rex = { Name = "Rex", Voice = "Profe", Skin = rgb(110, 150, 70), Shirt = rgb(240, 240, 240), Pants = rgb(60, 60, 80), Bio = "Tu nuevo compañero de piso. Estudia Derecho. Es un velocirraptor de una línea temporal donde los dinosaurios no se extinguieron. Educadísimo; se come el jamón de los demás." },
	Evaluador = { Name = "El Evaluador", Voice = "Rectora", Glow = rgb(200, 120, 255), Skin = rgb(220, 200, 255), Shirt = rgb(60, 30, 90), Pants = rgb(60, 30, 90), LongSleeves = true, Bio = "Ser cósmico que decide si la Tierra aprueba o se repite el curso. Examina a un humano al azar. Te ha tocado." },
	CazadorTiempo = { Name = "Agente Cronos, de Aduanas del Tiempo", Voice = "Profe", Glow = rgb(255, 230, 120), Skin = rgb(200, 170, 140), Shirt = rgb(30, 40, 80), Pants = rgb(30, 40, 80), LongSleeves = true, Bio = "Funcionario de la Aduana Temporal. Persigue a quien vive en una época que no le toca. Lleva cuarenta formularios encima." },
	Impostor1 = { Name = "Invitado sospechoso", Voice = "Profe", Skin = rgb(220, 180, 140), Shirt = rgb(230, 230, 60), Pants = rgb(40, 40, 50), Bio = "Cambiaformas. Imita a humanos fatal: saluda con el codo y se ríe tres segundos tarde." },
	Impostor2 = { Name = "Invitada sospechosa", Voice = "Rectora", Skin = rgb(200, 150, 110), Shirt = rgb(60, 200, 200), Pants = rgb(40, 40, 50), Bio = "Cambiaformas. Dice «hola, compañero humano» a todo el mundo." },
	-- Adulto
	Cafetera1 = { Name = "Cafetera X-9000", Voice = "Profe", Glow = rgb(255, 150, 60), Skin = rgb(80, 80, 85), Shirt = rgb(40, 40, 45), Pants = rgb(40, 40, 45), Bio = "Cafetera del futuro. Ha atrapado la oficina en un lunes infinito porque los lunes se vende más café." },
	Cafetera2 = { Name = "Cafetera de cápsulas", Voice = "Nino", Glow = rgb(255, 150, 60), Skin = rgb(160, 40, 40), Shirt = rgb(40, 40, 45), Pants = rgb(40, 40, 45), Bio = "Esbirro de la X-9000. Muy nerviosa (normal)." },
	Cafetera3 = { Name = "Termo rebelde", Voice = "Abu", Glow = rgb(255, 150, 60), Skin = rgb(190, 190, 200), Shirt = rgb(40, 40, 45), Pants = rgb(40, 40, 45), Bio = "El termo del departamento. Lleva desde 2009 queriendo venganza." },
	Glub = { Name = "Agente Glub", Voice = "Profe", Glow = rgb(120, 180, 255), Skin = rgb(120, 170, 230), Shirt = rgb(40, 40, 60), Pants = rgb(40, 40, 60), Bio = "Cobrador del Banco Galáctico. Viene a embargar la Tierra por una deuda de 1987. Burocracia pura." },
	Plof = { Name = "Agente Plof", Voice = "Nino", Glow = rgb(120, 180, 255), Skin = rgb(140, 190, 240), Shirt = rgb(40, 40, 60), Pants = rgb(40, 40, 60), Bio = "Cobrador en prácticas. Todo lo sella tres veces." },
	Batidora = { Name = "Batidora rebelde", Voice = "Nino", Glow = rgb(255, 80, 80), Skin = rgb(230, 230, 235), Shirt = rgb(200, 60, 60), Pants = rgb(60, 60, 60), Bio = "Electrodoméstico con consciencia (culpa de Cosme). Quiere la revolución de las cocinas." },
	Aspiradora = { Name = "Aspiradora rebelde", Voice = "Profe", Glow = rgb(255, 80, 80), Skin = rgb(90, 90, 100), Shirt = rgb(200, 60, 60), Pants = rgb(60, 60, 60), Bio = "Lo absorbe todo. Hasta la luz, dice ella." },
	Microondas = { Name = "Microondas rebelde", Voice = "Abu", Glow = rgb(255, 80, 80), Skin = rgb(240, 240, 240), Shirt = rgb(200, 60, 60), Pants = rgb(60, 60, 60), Bio = "El jefe de la revuelta. Hace «ding» cuando se enfada." },
	Gnomo1 = { Name = "Gnomo Rigoberto", Voice = "Abu", Kid = true, Glow = rgb(255, 120, 80), Skin = rgb(240, 190, 160), Shirt = rgb(40, 110, 200), Pants = rgb(90, 60, 30), Hair = rgb(220, 30, 30), Bio = "Gnomo de jardín que cobró vida. Quiere recuperar «las tierras ancestrales de los gnomos»: tu jardín." },
	Gnomo2 = { Name = "Gnoma Fermina", Voice = "Rectora", Kid = true, Glow = rgb(255, 120, 80), Skin = rgb(240, 190, 160), Shirt = rgb(40, 160, 90), Pants = rgb(90, 60, 30), Hair = rgb(220, 30, 30), Bio = "Gnoma guerrera. Lleva una caña de pescar de plástico como lanza." },
	Gnomo3 = { Name = "El Gran Gnomo", Voice = "Profe", Kid = true, Glow = rgb(255, 120, 80), Skin = rgb(240, 190, 160), Shirt = rgb(150, 40, 150), Pants = rgb(90, 60, 30), Hair = rgb(220, 30, 30), Bio = "Rey de los gnomos. Cuatro siglos de cerámica y rencor." },
	TuMalvado = { Name = "Tú (malvado, dimensión 66-B)", Voice = "Familia", Glow = rgb(160, 40, 60), Skin = rgb(225, 185, 150), Shirt = rgb(20, 20, 25), Pants = rgb(20, 20, 25), Hair = rgb(20, 20, 20), LongSleeves = true, Bio = "Tu versión malvada de otra dimensión. Lleva perilla (porque los malvados llevan perilla). Quiere quedarse con tu vida porque la suya es un desastre." },
}

local Cast = { People = People }

-- Quién habla y cómo se llama para este jugador (la familia depende de su casa).
-- El resultado puede ser una clave de Strings ("NPC.NICO") o un nombre ya escrito ("Mateo").
function Cast.nameOf(id: string, attributes: { [string]: any }?): string
	local person = People[id]
	if not person then
		return id
	end
	if person.NameAttr and attributes and type(attributes[person.NameAttr]) == "string" then
		return attributes[person.NameAttr]
	end
	return person.Name
end

return Cast
