-- Cast: el reparto de la historia. Cada personaje que aparece en una escena, habla en un diálogo o
-- se recuerda está aquí: nombre, voz (Config.Audio.Voices.Speakers), aspecto y personalidad.
--
--   Name      nombre que se ve (o clave de Strings)
--   NameAttr  (opcional) atributo del jugador con la clave de su nombre (la familia cambia en cada casa)
--   Voice     perfil de voz sintetizada
--   Kid       tamaño de niño (escala 0.65); Teen = 0.85; si no, adulto
--   Old       persona mayor: anda encorvada y con pasos cortos (Controllers/AgeMotion)
--   Skin, Shirt, Pants  colores (el aspecto sin necesitar ropa de catálogo)
--   Bio       personalidad en una línea (la primera frase sale en la ficha «¿Quién es?» de StoryContext)
--
-- Campos nuevos (opcionales; paquete P9 · Reparto). Se rellenan más abajo, en PERFILES, para no
-- ensuciar la tabla de aspecto. La biblia de voces para guionistas: docs/historia/reparto.md
--   Perfil    ficha de guion: Personalidad, Habla (Vocabulario, Ritmo, Muletillas), Emociones (registro),
--             Relaciones ({ [idDelReparto] = "cómo es con él" }), Motivacion y Arco ({ [etapa] = "…" })
--   Actuar    cómo se mueve por defecto (lo puede leer el motor; mismos nombres que ActorMoods):
--             Mood (emoción de base: «Calm», «Nervous», «Joy»…), Tempo, Head, Open, Gaze, Fidget,
--             y Gestos = { gestos de Emotion que le salen solos: «ThinkChin», «Shrug»… }
--   Edades    aspecto por etapa del JUGADOR para quien crece contigo (montajes de P7):
--             { [etapa] = { Scale, Age, y colores o Backpack = false para quitarla } }
--             Lo resuelven Cast.atStage(id, etapa) y Cast.scaleAt(id, etapa).
--
-- Ids especiales en diálogos: "Yo" = el jugador, "Narrador" = texto en cursiva sin personaje.

local rgb = Color3.fromRGB

export type Perfil = {
	Personalidad: string,
	Habla: { Vocabulario: string, Ritmo: string, Muletillas: { string } },
	Emociones: string,
	Relaciones: { [string]: string },
	Motivacion: string,
	Arco: { [string]: string },
}

export type Actuar = {
	Mood: string?,
	Tempo: number?,
	Head: number?,
	Open: number?,
	Gaze: string?,
	Fidget: number?,
	Gestos: { string }?,
}

-- Aspecto en una etapa: escala, edad para AgeMotion y lo que cambia de ropa (false = quitar)
export type Edad = { [string]: any }

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
	Perfil: Perfil?,
	Actuar: Actuar?,
	Edades: { [string]: Edad }?,
}

local People: { [string]: Person } = {
	-- Familia (en la casa donde naciste; el nombre depende de la casa: Mamá/Papá, Abu Rosa/Abu Tomás)
	Familia = {
		Name = "NPC.MAMA", NameAttr = "FamilyKey", Voice = "Familia",
		Skin = rgb(198, 150, 112), Shirt = rgb(70, 120, 170), Pants = rgb(50, 50, 60),
		Hair = rgb(70, 45, 25),
		Bio = "Cariño con prisas. Pregunta cinco cosas seguidas y no espera la respuesta de ninguna; bromea para que no estés nervioso y todo lo bueno acaba en la nevera, con un imán.",
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


-- PERFILES (P9 · Reparto) ----------------------------------------------------------------------------
-- La ficha de guion de cada personaje importante, cómo se mueve por defecto y cómo crece contigo.
-- Biblia de voces con frases de ejemplo: docs/historia/reparto.md

local CANAS = rgb(185, 185, 190)

local function merge(base: { [string]: any }, extra: { [string]: any }?): { [string]: any }
	local out = table.clone(base)
	for k, v in extra or {} do
		out[k] = v
	end
	return out
end

-- Los compañeros de clase crecen contigo (misma escala que SceneService: 0,65 niño · 0,85 adolescente · 1)
local function companero(adolescente: { [string]: any }?, joven: { [string]: any }?, adulto: { [string]: any }?): { [string]: Edad }
	local adultoLook = merge({ Scale = 1, Backpack = false }, adulto)
	return {
		Bebe = { Scale = 0.65, Age = "Nino" },
		Nino = { Scale = 0.65, Age = "Nino" },
		Adolescente = merge({ Scale = 0.85, Age = "Adolescente" }, adolescente),
		AdultoJoven = merge({ Scale = 1, Backpack = false }, joven),
		Adulto = adultoLook,
		Mayor = merge(adultoLook, { Age = "Mayor", Old = true, Hair = CANAS, LongSleeves = true }),
	}
end

local PERFILES: { [string]: { Perfil: Perfil?, Actuar: Actuar?, Edades: { [string]: Edad }? } } = {
	-- LA FAMILIA ---------------------------------------------------------------------------------------
	Familia = {
		Perfil = {
			Personalidad = "Mamá o Papá (según la casa). Quiere muchísimo y lo demuestra con preguntas, comida y fotos. Va siempre con prisa, pero nunca tanta como para no pararse a mirarte. Tiene miedo de que crezcas demasiado rápido y lo disimula con bromas.",
			Habla = {
				Vocabulario = "De casa: «cariño», «a ver», «venga», «¿has comido?». Diminutivos cuando se pone tierno («un trabajito», «un ratito»). Nada técnico: si no sabe algo, lo dice.",
				Ritmo = "Ráfagas de tres o cuatro preguntas seguidas sin esperar respuesta; luego una frase corta y sincera. Se corrige a sí mismo: «Ni un paso más. …Bueno, hasta la esquina.»",
				Muletillas = { "Cuéntamelo todo. Bueno, lo que quieras.", "¿Has comido?", "Esta va a la nevera.", "Qué rápido pasa todo.", "Ven aquí. Abrazo. No te escapes." },
			},
			Emociones = "Del orgullo exagerado (fotos, abrazos, contarlo a los vecinos) a la preocupación callada. Cuando se enfada no grita: se queda quieto y dice «No sé qué me duele más». Llora poco y a escondidas, casi siempre en las despedidas.",
			Relaciones = {
				Abu = "Su madre o su padre. Se pican con cariño («Déjale respirar»). Le pide consejo sin admitirlo.",
				Lucia = "La respeta muchísimo; en las tutorías se sienta muy derecho, como si le fueran a poner nota.",
				Cosme = "El vecino raro del garaje. Le da miedo y le cae bien a partes iguales; le lleva táperes.",
				Omar = "Le adora porque come de todo. Le llama «ese niño tan educado».",
			},
			Motivacion = "Que seas feliz y que no te falte de nada. En el fondo, que sigas volviendo a casa a contarle las cosas.",
			Arco = {
				Bebe = "Agotamiento feliz. Habla bajito, todo el rato pendiente de ti.",
				Nino = "Te lleva, te espera en la puerta, pregunta «¿qué tal el día?» cada tarde. Se sabe los nombres de toda tu clase.",
				Adolescente = "Aprende a soltar. Pregunta menos (le cuesta) y negocia hasta dónde te acompaña. Si mientes, le duele más que el problema.",
				AdultoJoven = "Mensajes largos llenos de preguntas, táperes con nombre. Te ayuda con el dinero sin hacerte sentir pequeño.",
				Adulto = "Canas y calma. Ya no pregunta «¿has comido?»: lo cocina. Empieza a contarte cosas de su vida que nunca te había contado.",
				Mayor = "Se le olvidan nombres; no se le olvida ninguna foto de la nevera.",
			},
		},
		Actuar = { Mood = "Calm", Tempo = 1.15, Open = 0.4, Gestos = { "WaveLite", "Ask", "Clap", "HandsOnHips" } },
		Edades = {
			Adulto = { Hair = rgb(150, 140, 135) },
			Mayor = { Hair = rgb(200, 200, 205), Old = true, Age = "Mayor", LongSleeves = true },
		},
	},
	Abu = {
		Perfil = {
			Personalidad = "Abu Rosa o Abu Tomás. Tranquilidad absoluta y una picardía escondida. Se sabe la historia de Valmar desde que era un pueblo y la cuenta adornada. Ganó el Gran Torneo de Tirachinas de 1962 y no se le olvida.",
			Habla = {
				Vocabulario = "Refranes (algunos inventados), «cariño», «en mis tiempos», «los de antes». Fechas exactas de cosas absurdas.",
				Ritmo = "Lento. Frases cortas con una pausa antes del remate. Repite la palabra importante: «Nunca, nunca, NUNCA».",
				Muletillas = { "Un consejo de los de antes:", "En mis tiempos a eso lo llamábamos…", "Se sale. Siempre se sale.", "Solo latas." },
			},
			Emociones = "Casi siempre en calma. La alegría le sale en forma de travesura; la tristeza, en silencio y mirando por la ventana. Nunca se enfada contigo: se decepciona, y eso es peor.",
			Relaciones = {
				Familia = "Su hijo o su hija. Le protege de ti («Déjale respirar») y de sí mismo.",
				Cosme = "Se conocen de toda la vida. Sabe más de la noche de la Grieta de lo que dice.",
				Ramon = "Compañeros de dominó y de rivalidad deportiva desde 1960.",
			},
			Motivacion = "Dejarte algo que dure: una regla, una historia, el tirachinas. Que la familia siga unida cuando ya no esté.",
			Arco = {
				Bebe = "Te arropa y te cuenta cuentos de Valmar aunque no entiendas nada.",
				Nino = "Cómplice: secretos de familia, el tirachinas, la regla de oro.",
				Adolescente = "Te entiende cuando nadie lo hace. «Yo también tuve malas compañías.»",
				AdultoJoven = "Se va haciendo mayor de verdad. Las visitas cuentan más que nunca: el hospital, la promesa, el atardecer.",
				Adulto = "Recuerdo y presencia: su refrán en tu boca, su sitio en el banco.",
			},
		},
		Actuar = { Mood = "Calm", Tempo = 0.75, Head = 0.03, Open = 0.3, Gaze = "Hold", Gestos = { "Nod", "ThinkChin", "Calm" } },
	},

	-- EL COLEGIO ---------------------------------------------------------------------------------------
	Lucia = {
		Perfil = {
			Personalidad = "Tutora de 1.º A. Exigente porque cree en vosotros. Estudió en ese mismo colegio (la foto de 1998, las coletas). Humor seco que suelta sin cambiar la cara.",
			Habla = {
				Vocabulario = "Claro y de aula: «silencio», «sin acusar a nadie sin pruebas», «los deberes». Os llama por el nombre.",
				Ritmo = "Frases muy cortas. Una orden, un punto. La ternura llega en una sola frase, al final.",
				Muletillas = { "Silencio.", "No me contestes. Tu cara ya me ha contestado.", "Y ahora: los deberes.", "Ni una palabra de las coletas." },
			},
			Emociones = "Contenida en clase; se le escapa la emoción con lo que tiene que ver con el pasado (la foto, el reencuentro). Cuando se enfada baja la voz en vez de subirla.",
			Relaciones = {
				Ramon = "Ya era conserje cuando ella era alumna. Él todavía la llama «la de las coletas».",
				Bruno = "Ve lo que le pasa en casa. Le exige igual que a todos, pero le da segundas oportunidades.",
				Omar = "Él le quitaba el bocadillo de la mesa y ella hacía como que no lo veía.",
				Sara = "Su alumna más rápida; le pide que vaya despacio.",
			},
			Motivacion = "Que nadie de su clase se sienta como ella se sintió algún día en ese patio.",
			Arco = {
				Nino = "La tutora: firme, justa, con una foto escondida.",
				Adulto = "Directora del colegio, con la foto de 1998 en la pared. Llora en la puerta y lo niega.",
			},
		},
		Actuar = { Mood = "Calm", Tempo = 0.95, Head = 0.03, Open = 0.1, Gaze = "Hold", Gestos = { "ArmsCrossed", "Nod", "Point" } },
		Edades = { Adulto = { Hair = rgb(140, 105, 70) }, Mayor = { Hair = CANAS, Old = true, Age = "Mayor" } },
	},
	Nico = {
		Perfil = {
			Personalidad = "Deportista, impulsivo, competitivo y generoso. Todo es un reto y todo lo dice en voz alta. Mete la pata rápido y pide perdón rápido (y aprende a pedirlo bien).",
			Habla = {
				Vocabulario = "De patio y de equipo: «entreno», «chiripa», «golazo», «revancha». Récords con cifras.",
				Ritmo = "Exclamaciones; frases que empiezan con tu nombre gritado. Cuando algo le duele, se le acaban los signos de exclamación.",
				Muletillas = { "¡{nombre}!", "¿Una carrera?", "¡Vamos, vamos, vamos!", "…Me pasé." },
			},
			Emociones = "Alegría desbordada y enfado que dura un minuto. La vergüenza le dura más: no te mira y da patadas a una piedra.",
			Relaciones = {
				Omar = "Su mejor amigo desde los seis años. La pelea del rumor (instituto) es lo peor que le ha pasado.",
				Sara = "Discuten por todo; se respetan muchísimo.",
				Bruno = "Rival desde el primer día; acaban jugando en el mismo partido.",
				Alex = "Su rival favorita en el campo: ella para todo lo que él tira.",
			},
			Motivacion = "Ser futbolista profesional. Y que el grupo esté siempre en la grada.",
			Arco = {
				Nino = "El capitán del patio. Mucha energía, poca paciencia.",
				Adolescente = "Primeros entrenos serios; el rumor y la pelea con Omar. Aprende que pedir perdón también es de equipo.",
				AdultoJoven = "Cantera, lesiones, constancia.",
				Adulto = "Jugador profesional de Altamar. Tiene enmarcada tu predicción de la cápsula del tiempo.",
			},
		},
		Actuar = { Mood = "Joy", Tempo = 1.3, Head = 0.04, Open = 0.6, Fidget = 0.3, Gestos = { "Cheer", "Point", "HandsOnHips" } },
		Edades = companero({ Shirt = rgb(200, 40, 40), Backpack = rgb(40, 40, 50) }, { Shirt = rgb(240, 240, 240), Pants = rgb(200, 40, 40) }, { Shirt = rgb(30, 90, 170), Pants = rgb(250, 250, 250) }),
	},
	Sara = {
		Perfil = {
			Personalidad = "Curiosa, científica, perfeccionista. Necesita saber el porqué de todo y lo explica aunque no se lo pidas. Le encantan los hongos (de verdad).",
			Habla = {
				Vocabulario = "Palabras largas y exactas: «técnicamente», «hipótesis», «estadísticamente». Datos y nombres en latín.",
				Ritmo = "Rapidísimo; encadena ideas con «y además». Para en seco cuando se da cuenta de que nadie la sigue.",
				Muletillas = { "Técnicamente…", "Tengo una hipótesis.", "Yo quería hablar de hongos.", "Esto lleva ahí muchos años." },
			},
			Emociones = "Entusiasmo que se le sale por los ojos; los nervios de examen la bloquean. Cuando algo es injusto se pone muy seria y muy lógica.",
			Relaciones = {
				Nico = "Le corrige todo; le defiende la primera.",
				Omar = "Su compañero de investigación: ella pregunta, él dibuja.",
				Iker = "Rivalidad de sabelotodos. Se pasan datos como quien juega al ping-pong.",
				Lucia = "La admira. Descubrir la foto de 1998 fue su mejor investigación.",
			},
			Motivacion = "Descubrir algo que nadie haya visto antes.",
			Arco = {
				Nino = "La investigadora del grupo: lupa, cuaderno, teorías.",
				Adolescente = "Presión por las notas; aprende que no hace falta ser perfecta.",
				Adulto = "Micóloga. Hay un hongo con su nombre: «Mycena sarae». Lo lleva a las fiestas en un tarro.",
			},
		},
		Actuar = { Mood = "Calm", Tempo = 1.35, Head = 0.05, Open = 0.3, Fidget = 0.25, Gestos = { "ThinkChin", "Point", "Ask" } },
		Edades = companero({ Backpack = rgb(40, 120, 70) }, { Shirt = rgb(250, 250, 250) }, { Shirt = rgb(250, 250, 250), Pants = rgb(60, 90, 60) }),
	},
	Omar = {
		Perfil = {
			Personalidad = "Artista tranquilo, siempre con hambre y un lápiz. Observa más que habla, y lo que dibuja acaba siendo una pista. Gracia involuntaria. Cuando algo le duele, se esconde (el banco del verano).",
			Habla = {
				Vocabulario = "Sencillo y visual: colores, formas, comida. Mucha comida: bocadillos, tortilla, «una sala entera de bocadillos».",
				Ritmo = "Pausado. Dice algo serio y lo remata con una tontería sobre comida. Se habla a sí mismo en voz alta.",
				Muletillas = { "Buscando… un bocadillo.", "Me lo digo a mí mismo.", "No lloro. Es la cebolla.", "Ya está." },
			},
			Emociones = "Calma de fondo. La alegría le sale torpe y enorme; la tristeza, callada. Casi nunca se enfada: se va.",
			Relaciones = {
				Nico = "Su mejor amigo desde los seis años. El rumor del instituto le rompe; el perdón le cuesta, pero llega.",
				Sara = "Hacen equipo: ella pregunta, él dibuja la respuesta.",
				Lola = "Su maestra de cocina y, al final, quien le deja la cafetería.",
				Lucia = "Le quitaba el bocadillo de la mesa. Ella lo sabe.",
			},
			Motivacion = "Tener un sitio donde quepan todos y se coma bien.",
			Arco = {
				Nino = "El que dibuja las pistas del misterio y tiene hambre a todas horas.",
				Adolescente = "Crece de golpe (se choca con el marco de la puerta). El rumor le hace dudar de todos.",
				AdultoJoven = "Trabaja con Lola en la cafetería.",
				Adulto = "«La Cafetería de Omar». Reúne al grupo entero. No llora: es la cebolla.",
			},
		},
		Actuar = { Mood = "Calm", Tempo = 0.8, Head = -0.02, Open = 0.2, Gestos = { "Shrug", "ThinkChin", "Nod" } },
		Edades = companero({ Scale = 0.9 }, nil, { Shirt = rgb(250, 250, 250), Pants = rgb(60, 50, 40) }),
	},
	Mateo = {
		Perfil = {
			Personalidad = "Tímido, nuevo en el barrio, colecciona cromos. Se le caen las cosas. Lo ve todo y casi nunca lo dice. Cuando confía, es el más leal de todos.",
			Habla = {
				Vocabulario = "Comparaciones con «mi otro cole». Cromos, puentes, cómo funcionan las cosas.",
				Ritmo = "Frases que empiezan con tu nombre y puntos suspensivos. Bajito. Se corrige solo.",
				Muletillas = { "{nombre}… yo lo vi.", "En mi otro cole…", "Es mi récord.", "Perdón. Perdón." },
			},
			Emociones = "Nervios casi siempre (manos ocupadas, mirada al suelo). La alegría se le nota en que sonríe sin parar y no dice nada.",
			Relaciones = {
				Dani = "Su hermano pequeño. Le protege y le da vergüenza a la vez.",
				Nico = "Le admira y le da un poco de miedo.",
				Bruno = "Le tenía miedo. Al final es quien le perdona.",
			},
			Motivacion = "Encajar sin tener que hacerse notar. Construir cosas que no se caigan.",
			Arco = {
				Nino = "El nuevo: los libros por el suelo, el primer amigo (tú).",
				Adolescente = "Se atreve a opinar; descubre que se le dan bien las estructuras.",
				Adulto = "Ingeniero en TecnoVal: la pasarela del río. «El fontanero más caro de la historia.»",
			},
		},
		Actuar = { Mood = "Nervous", Tempo = 0.9, Head = -0.06, Open = -0.3, Gaze = "Avoid", Fidget = 0.7, Gestos = { "Nervous", "Ashamed", "Nod" } },
		Edades = companero(nil, nil, { Shirt = rgb(240, 240, 245), Pants = rgb(70, 70, 90) }),
	},
	Dani = {
		Perfil = {
			Personalidad = "Hermano pequeño de Mateo (cinco años cuando le conoces). Todo lo pregunta, todo lo toca. Adora su balón.",
			Habla = {
				Vocabulario = "De niño pequeño: «¿y por qué?», «mío», «¡otra vez!».",
				Ritmo = "Preguntas en cadena. Frases de tres palabras.",
				Muletillas = { "¿Y por qué?", "¡Mi balón!", "¡Otra vez!" },
			},
			Emociones = "Alegría total o llanto total; nada en medio.",
			Relaciones = { Mateo = "Su héroe, aunque le haga rabiar.", Nico = "Quiere ser como él." },
			Motivacion = "Que alguien juegue con él. Ya.",
			Arco = { Nino = "El pequeño que siempre está en medio.", Adulto = "Ya es más alto que Mateo y se lo recuerda." },
		},
		Actuar = { Mood = "Joy", Tempo = 1.4, Head = 0.06, Open = 0.6, Fidget = 0.5, Gestos = { "Ask", "Cheer", "Point" } },
		-- Es más pequeño: va una etapa por detrás
		Edades = merge(companero(), {
			Adolescente = { Scale = 0.65, Age = "Nino" },
			AdultoJoven = { Scale = 0.85, Age = "Adolescente" },
		}),
	},
	Bruno = {
		Perfil = {
			Personalidad = "Líder de «los malotes». Fanfarrón porque necesita que le miren; su hermano mayor le presiona en casa. Le culpan de todo, y a veces no ha sido él. Su arco es empezar de cero.",
			Habla = {
				Vocabulario = "Retos y amenazas de patio: «os vais a enterar», «de chiripa», «pringado». De mayor, formal de uniforme: «para servirle».",
				Ritmo = "Frases cortas y con fuerza. Cuando se rompe, un «Ya.» y silencio.",
				Muletillas = { "Siempre soy yo, ¿no?", "…Hugo habla demasiado.", "Empezamos de cero, ¿no?", "Gracias. De verdad." },
			},
			Emociones = "Enfado defensivo por fuera (brazos cruzados, barbilla arriba); vergüenza y miedo por dentro. Cuando alguien no le culpa, no sabe qué hacer con las manos.",
			Relaciones = {
				Ruben = "Su bufón: le hace reír y le obedece.",
				Hugo = "Va con él sin querer. Bruno lo sabe y le duele.",
				Nico = "Rival en todo. Un respeto que nunca dice en voz alta.",
				Lucia = "La única adulta que no le mira como «el problema».",
				Ines = "De mayor, su maestra en la policía.",
			},
			Motivacion = "Que alguien le vea por lo que es y no por lo que hizo.",
			Arco = {
				Nino = "El malote: la mochila, el almacén, el enfrentamiento. Y la primera vez que alguien no le culpa.",
				Adolescente = "Intenta cambiar y nadie le cree. Elige bando.",
				Adulto = "Agente Bruno: ayuda a cruzar a los mayores y busca gatos. «Esto es el diez.»",
			},
		},
		Actuar = { Mood = "Calm", Tempo = 1.1, Head = 0.05, Open = 0.1, Gaze = "Hold", Gestos = { "ArmsCrossed", "HandsOnHips", "No" } },
		Edades = companero({ Shirt = rgb(25, 25, 25) }, nil, { Shirt = rgb(30, 50, 110), Pants = rgb(30, 40, 70) }),
	},
	Ruben = {
		Perfil = {
			Personalidad = "El bromista de Bruno. Hace las cosas para que Bruno se ría; en el fondo quiere caer bien a todos. No es malo: no piensa antes.",
			Habla = {
				Vocabulario = "Chistes malos, «rarísimo», «no es mi estilo». Se queja a los profes con voz aguda.",
				Ritmo = "Rápido; se ríe de sus propias frases. El pánico, en tres palabras: «¡No! ¡Espera!».",
				Muletillas = { "¿Buscas esto?", "Bruno me va a matar. Bueno, a matar no.", "¡Me ha gritado, profe!" },
			},
			Emociones = "Risa nerviosa casi siempre; cuando le pillan, pánico cómico. La disculpa le sale sincera y torpe.",
			Relaciones = { Bruno = "Le sigue a todas partes.", Hugo = "Le toma el pelo; en secreto le pide prestados los libros de piratas." },
			Motivacion = "Que se rían con él, no de él.",
			Arco = { Nino = "El que esconde la mochila.", Adulto = "«Lo de la mochila fue hace mil años.» Y se alegra de verte." },
		},
		Actuar = { Mood = "Joy", Tempo = 1.25, Open = 0.3, Fidget = 0.5, Gaze = "Around", Gestos = { "Laugh", "Shrug", "Point" } },
		Edades = companero(),
	},
	Hugo = {
		Perfil = {
			Personalidad = "Va con Bruno pero no quiere. Lector de libros de piratas, observador, honrado. Encuentra su voz como periodista y, al final, como escritor.",
			Habla = {
				Vocabulario = "Referencias a libros («en un libro que leí…»), aventuras, islas, llaves. De mayor, de periodista: «fuentes», «reportaje».",
				Ritmo = "Poco y bajito. Frases que se cortan con «…». Cuando habla de libros, se le acelera.",
				Muletillas = { "En un libro que leí…", "Lo he leído.", "…Nadie se fija en eso.", "Ya. Me emociono yo solo." },
			},
			Emociones = "Retraído, mirada al suelo. La ilusión se le ve en las manos (gesticula al hablar de piratas).",
			Relaciones = {
				Bruno = "Le sigue por miedo a quedarse solo. Acaba siendo el primero en hablar.",
				Leire = "Su compañera de periódico en el instituto.",
			},
			Motivacion = "Que alguien lea lo que escribe.",
			Arco = {
				Nino = "El de la pista del libro («La isla de las mil llaves»).",
				Adolescente = "Periodista del instituto: los murales, proteger a sus fuentes.",
				Adulto = "Novelista. Su primera novela te la dedica.",
			},
		},
		Actuar = { Mood = "Calm", Tempo = 0.85, Head = -0.08, Open = -0.3, Gaze = "Down", Fidget = 0.3, Gestos = { "Shrug", "ThinkChin" } },
		Edades = companero(nil, nil, { Shirt = rgb(110, 90, 70), LongSleeves = true }),
	},
	Alex = {
		Perfil = {
			Personalidad = "Portera del equipo, directa y justa. Todo lo convierte en apuesta (sin dinero). Sabe cosas y las cobra en favores.",
			Habla = {
				Vocabulario = "Deporte y tratos: «la información es cara», «¿apostamos?», «decidid».",
				Ritmo = "Seco, al grano. Dos frases y se cruza de brazos.",
				Muletillas = { "Puede. Puede que sí.", "¿Apostamos?", "Decidid." },
			},
			Emociones = "Segura. El enfado le dura lo que tarda en decirlo.",
			Relaciones = { Nico = "Su rival preferido en el campo.", Vega = "Su mejor amiga; polos opuestos." },
			Motivacion = "Ganar limpio.",
			Arco = { Nino = "La portera que sabe dónde está todo.", AdultoJoven = "En el equipo de la universidad." },
		},
		Actuar = { Mood = "Calm", Tempo = 1.1, Open = 0.3, Gaze = "Hold", Gestos = { "ArmsCrossed", "HandsOnHips" } },
		Edades = companero(),
	},
	Vega = {
		Perfil = {
			Personalidad = "Artista y soñadora, colecciona pegatinas que brillan. Ve el mundo en colores. Se ofende con gracia.",
			Habla = {
				Vocabulario = "Colores, brillos, olores («esta huele a fresa»).",
				Ritmo = "Cantarín; ironía dramática cuando algo le sale mal.",
				Muletillas = { "¿Te gustan las pegatinas?", "Gracias por nada.", "Esta brilla en la oscuridad." },
			},
			Emociones = "Ilusión fácil, drama corto.",
			Relaciones = { Alex = "Su mejor amiga.", Omar = "Comparten rotuladores y silencios." },
			Motivacion = "Que alguien mire lo que brilla de verdad.",
			Arco = { Nino = "La de las pegatinas robadas.", Adulto = "Ilustradora; sigue llevando una pegatina en la funda del móvil." },
		},
		Actuar = { Mood = "Joy", Tempo = 1.1, Head = 0.04, Open = 0.4, Gestos = { "WaveLite", "Happy" } },
		Edades = companero(),
	},
	Iker = {
		Perfil = {
			Personalidad = "El que se lo sabe todo: gafas, datos curiosos, un poco sabelotodo pero buena gente. Guarda un secreto que le pesa (dejó que culparan a Bruno).",
			Habla = {
				Vocabulario = "«Dato curioso», «según mis datos», cifras exactas.",
				Ritmo = "Ordenado, como una ficha. Cuando confiesa, se le cortan las frases.",
				Muletillas = { "Dato curioso:", "Según mis datos…", "Lo he leído." },
			},
			Emociones = "Calma de biblioteca; la culpa le hace callar.",
			Relaciones = { Sara = "Rivalidad de sabelotodos.", Marisa = "Su aliada en la biblioteca.", Bruno = "Le debe una disculpa." },
			Motivacion = "Tener razón… y aprender que no siempre basta.",
			Arco = { Nino = "Los datos del grupo; la confesión.", Adulto = "Profesor de ciencias. Sigue empezando las clases con un dato curioso." },
		},
		Actuar = { Mood = "Calm", Tempo = 1.05, Head = 0.04, Open = 0, Gestos = { "ThinkChin", "Point" } },
		Edades = companero(),
	},

	-- EL INSTITUTO ---------------------------------------------------------------------------------------
	Leire = {
		Perfil = {
			Personalidad = "Llega del norte a Valmar con la cámara de su abuelo al cuello. Seca al principio, leal para siempre. Mira el mundo por el visor y ve lo que nadie ve.",
			Habla = {
				Vocabulario = "De foto: «encuadre», «teleobjetivo», «montaje», «la original». Habla de su abuelo.",
				Ritmo = "Monosílabos al principio («No.»). Frases cortas, cortantes; la ternura, una vez y sin adornos.",
				Muletillas = { "No.", "Mi abuelo decía que…", "Lo siento. Bueno, no lo siento.", "Eso no se me va a olvidar." },
			},
			Emociones = "Guardada. Se protege con ironía; cuando se emociona, levanta la cámara para no tener que mirarte.",
			Relaciones = {
				Toni = "Su tío, el de los documentales.",
				Hugo = "Equipo en el periódico del instituto.",
				Nerea = "Se reconocen: las dos miran desde fuera.",
			},
			Motivacion = "Encontrar su sitio sin dejar de ser rara.",
			Arco = {
				Adolescente = "La nueva del primer día; tú te acercas. El club de foto, el montaje del rumor.",
				Adulto = "Documentalista. Estrena una película sobre Valmar en la que salís todos sin permiso.",
			},
		},
		Actuar = { Mood = "Calm", Tempo = 0.9, Head = 0, Open = -0.2, Gaze = "Avoid", Gestos = { "ArmsCrossed", "Shrug" } },
		Edades = companero(nil, nil, { Shirt = rgb(40, 40, 45), LongSleeves = true }),
	},
	Rayo = {
		Perfil = {
			Personalidad = "De 4.º, manda en el muelle. Gracioso, valiente, peligroso. En casa casi nunca hay nadie. Te ofrece «negocios» porque es lo único que sabe ofrecer.",
			Habla = {
				Vocabulario = "Calle y trato: «socio», «me piro», «negocios», «a diez».",
				Ritmo = "Rápido y seguro; cuando habla de su casa, frases sueltas sin mirar.",
				Muletillas = { "Socio.", "Si ves a un policía, silba.", "Me piro.", "Ya me lo imaginaba." },
			},
			Emociones = "Chulería de fachada; detrás, abandono. No llora: se ríe más alto.",
			Relaciones = { Nerea = "Su segunda; la pierde cuando ella se va.", Tomas = "El mecánico que le da una oportunidad (si le llevas)." },
			Motivacion = "Que alguien se quede.",
			Arco = { Adolescente = "La pandilla, la noche del súper, la expulsión.", Adulto = "Sigue con sus «negocios». Según lo que hiciste, legales o no." },
		},
		Actuar = { Mood = "Calm", Tempo = 1.15, Head = 0.06, Open = 0.4, Gaze = "Hold", Fidget = 0.2, Gestos = { "HandsOnHips", "Shrug", "Point" } },
		Edades = companero({ Scale = 0.9 }),
	},
	Nerea = {
		Perfil = {
			Personalidad = "De la pandilla de Rayo. Lista y sarcástica; va con ellos porque no sabe con quién ir. Dibuja cómics que no enseña. Irse es lo más valiente que hace.",
			Habla = {
				Vocabulario = "Sarcasmo seco, «supongo», «ya está». Mensajes cortos.",
				Ritmo = "Bajito y sin mirar. Pausas largas antes de decir lo que de verdad piensa.",
				Muletillas = { "Supongo.", "Ya está.", "En serio." },
			},
			Emociones = "Apagada, a la defensiva. Se ilumina (un poco) cuando alguien ve sus dibujos.",
			Relaciones = { Rayo = "Le es leal y le tiene miedo.", Leire = "Alguien que también mira desde fuera.", Familia = "Su madre llama a tu casa para darte las gracias." },
			Motivacion = "Que alguien la elija sin que ella tenga que hacer nada.",
			Arco = { Adolescente = "Salir de la pandilla. Volver a dibujar.", Adulto = "Publica cómics. El primero va de un muelle." },
		},
		Actuar = { Mood = "Calm", Tempo = 0.85, Head = -0.06, Open = -0.4, Gaze = "Avoid", Fidget = 0.3, Gestos = { "Shrug", "ArmsCrossed" } },
		Edades = companero(),
	},
	Javier = {
		Perfil = {
			Personalidad = "Tutor de 1.º C, profe de Historia. Tranquilo e irónico; cita a filósofos cuando nadie se lo pide. Su puerta siempre está abierta.",
			Habla = {
				Vocabulario = "Culto con guiño: citas, «charlas que no me habéis pedido».",
				Ritmo = "Pausado, con remate irónico.",
				Muletillas = { "Mi puerta está abierta. Siempre.", "Nadie es su nota.", "Como decía alguien más listo que yo…" },
			},
			Emociones = "Ironía tranquila; se pone serio de verdad pocas veces, y entonces se nota.",
			Relaciones = { Carmen = "Hacen equipo con los alumnos difíciles." },
			Motivacion = "Que penséis por vuestra cuenta.",
			Arco = { Adolescente = "El tutor que te deja equivocarte." },
		},
		Actuar = { Mood = "Calm", Tempo = 0.85, Open = 0.3, Gestos = { "ThinkChin", "Shrug" } },
	},
	Carmen = {
		Perfil = {
			Personalidad = "Orientadora. Escucha más que habla. Te ayuda a decidir sin decidir por ti.",
			Habla = {
				Vocabulario = "Cálido y preciso: «veo que…», «tranquilidad», «hay tiempo».",
				Ritmo = "Lento, con silencios que deja para que hables tú.",
				Muletillas = { "No tienes que saberlo hoy.", "Veo que…", "Tranquilidad: hay tiempo." },
			},
			Emociones = "Serena. Su sonrisa es la recompensa.",
			Relaciones = { Javier = "Compañeros y aliados.", Lola = "Le manda alumnos con «cabeza de cocina»." },
			Motivacion = "Que nadie elija su vida por miedo.",
			Arco = { Adolescente = "La semana de las profesiones; la gran decisión." },
		},
		Actuar = { Mood = "Calm", Tempo = 0.8, Head = 0.02, Open = 0.4, Gaze = "Hold", Gestos = { "Nod", "Calm" } },
	},

	-- COSME Y LA SAGA ---------------------------------------------------------------------------------
	Cosme = {
		Perfil = {
			Personalidad = "El vecino inventor del garaje. Genio caótico, cariñoso a su manera. Dice que no le importa nada y siempre vuelve a por ti. Carga con la culpa de la noche de la Grieta.",
			Habla = {
				Vocabulario = "Pseudociencia brillante: «potasio cuántico», «técnicamente», «ciencia». Te llama «criatura». Desprecia la «ciencia aburrida».",
				Ritmo = "Deprisa, enumeraciones de tres, frases que se interrumpen por otra idea. Cuando habla del pasado, se para en seco.",
				Muletillas = { "Criatura.", "Ciencia.", "Normal. Todo normal.", "Tú entras, miras, sales. Yo apunto." },
			},
			Emociones = "Euforia inventora y fastidio teatral. La culpa y la ternura le salen de golpe y las tapa con un invento.",
			Relaciones = {
				Pip = "Su robot y, aunque no lo diga, su familia.",
				Cosimo = "Su antiguo socio. Le soltó la mano la noche de la Grieta.",
				Abu = "Se conocen de siempre; Abu sabe más de lo que cuenta.",
				DonEscamas = "El pez que no quería y que ahora vive en su pecera buena.",
			},
			Motivacion = "Arreglar lo que rompió. Que tú (el Ancla) estés a salvo.",
			Arco = {
				Nino = "El vecino raro que te usa de ayudante: palomas robot, gallina gigante.",
				Adolescente = "Los inventos se vuelven peligrosos; empieza a protegerte en serio.",
				AdultoJoven = "Desaparece; tú vas a buscarle. «Allí nadie me necesitaba.»",
				Adulto = "La verdad de la Grieta y el reencuentro con Cósimo.",
			},
		},
		Actuar = { Mood = "Joy", Tempo = 1.35, Head = 0.03, Open = 0.5, Fidget = 0.6, Gaze = "Around", Gestos = { "Point", "ThinkChin", "Facepalm" } },
	},
	Pip = {
		Perfil = {
			Personalidad = "El robot mayordomo de Cosme. Educadísimo, dramático, en plena crisis existencial: quiere saber para qué sirve. Más sensato que su jefe.",
			Habla = {
				Vocabulario = "Formal de mayordomo: «señor», «le prepararé», «permítame». Siempre de usted.",
				Ritmo = "Correcto y medido hasta que entra en bucle: «Mejor que lo vea. Mejor que no lo vea.»",
				Muletillas = { "Señor.", "Tengo un conflicto de programación.", "Oh, no. Oh, no, no, no.", "Le prepararé la habitación de invitados." },
			},
			Emociones = "Ansiedad educada (manos juntas, cabeza ladeada). Alegría desproporcionada cuando alguien le da las gracias.",
			Relaciones = { Cosme = "Le cuida, le regaña y le cubre.", DonEscamas = "Se pelean por la pecera." },
			Motivacion = "Encontrar un propósito propio.",
			Arco = { Nino = "Mayordomo asustadizo.", AdultoJoven = "Guarda los secretos de Cosme. «Tiene que contárselo. Algún día.»", Adulto = "Decide quedarse por elección, no por programa." },
		},
		Actuar = { Mood = "Nervous", Tempo = 1.1, Head = 0.02, Open = -0.1, Fidget = 0.6, Gestos = { "Nervous", "Nod", "Facepalm" } },
	},
	Cosimo = {
		Perfil = {
			Personalidad = "El villano: antiguo socio de Cosme, caído por la Grieta a la dimensión 66-B la noche en que naciste. Elegante, rencoroso, con perilla reglamentaria. Detrás del espectáculo, alguien a quien soltaron la mano.",
			Habla = {
				Vocabulario = "De presentador de concursos: «bravo», «precioso trabajo», «nuestro concursante». Te llama «Ancla».",
				Ritmo = "Teatral, con pausas para el aplauso. Cuando habla de los veinte años solo, se le cae el tono de plató.",
				Muletillas = { "Bravo.", "Hola, Ancla.", "Siempre fuiste el de las manualidades.", "Me gustan los retos grandes." },
			},
			Emociones = "Sorna, rencor, y una pena muy honda que asoma pocas veces.",
			Relaciones = { Cosme = "Su socio y su herida.", TuMalvado = "Su aliado de la 66-B." },
			Motivacion = "Volver a casa. Que alguien admita lo que pasó.",
			Arco = { AdultoJoven = "La amenaza que te ha visto.", Adulto = "Fusión o perdón; puede acabar arreglando la 66-B." },
		},
		Actuar = { Mood = "Calm", Tempo = 0.9, Head = 0.08, Open = 0.6, Gaze = "Hold", Gestos = { "Clap", "Point", "WaveLite" } },
	},

	-- LA UNIVERSIDAD -----------------------------------------------------------------------------------
	Ivan = {
		Perfil = {
			Personalidad = "Compañero de cuarto, de Villaverde, nieto de granjeros. Caótico, generoso, optimista sin motivo. Guarda el zumo de mora de su abuela como si fuera oro.",
			Habla = {
				Vocabulario = "De pueblo y de fiesta: «¡hombre!», «mi abuela dice», moras, el monte.",
				Ritmo = "Mayúsculas; lo celebra todo y encadena planes. Fe ciega en métodos que no funcionan.",
				Muletillas = { "¡Hombre!", "Mi abuela dice que…", "Nunca ha funcionado. Pero tengo fe.", "¡Zumo de mora para todos!" },
			},
			Emociones = "Alegría constante; cuando algo va mal, se queda muy quieto, y en él eso asusta.",
			Relaciones = { Candela = "Su opuesta. Se pelean por la nevera y se defienden a muerte.", Tito = "No recuerda haberle conocido y le da igual." },
			Motivacion = "Que nadie de la residencia se sienta solo.",
			Arco = { AdultoJoven = "Primer año caótico; aprende a estudiar (más o menos)." },
		},
		Actuar = { Mood = "Joy", Tempo = 1.3, Head = 0.04, Open = 0.7, Fidget = 0.3, Gestos = { "Cheer", "Laugh", "WaveLite" } },
	},
	Candela = {
		Perfil = {
			Personalidad = "Compañera de cuarto organizadísima: etiquetas de colores, horarios plastificados, una lista para cada lista. Por dentro, un volcán. Nadie toca sus táperes.",
			Habla = {
				Vocabulario = "Cálculos y planificación: «lo he calculado», «resumen para mi hoja de cálculo», horas y minutos exactos.",
				Ritmo = "Cifras rápidas y frases cerradas. Cuando explota, una sola frase demoledora.",
				Muletillas = { "Lo he calculado.", "Resumen:", "Nadie toca mis táperes." },
			},
			Emociones = "Control. El enfado es frío; la risa, rara y contagiosa.",
			Relaciones = { Ivan = "Su caos favorito.", Tito = "Sospecha de él desde el primer día." },
			Motivacion = "Que nada se le escape. Y aprender que no pasa nada si algo se escapa.",
			Arco = { AdultoJoven = "Horarios para todos; el día que se le cae el horario, descubre que tiene amigos." },
		},
		Actuar = { Mood = "Calm", Tempo = 1.15, Head = 0.03, Open = -0.1, Gaze = "Hold", Fidget = 0.2, Gestos = { "ArmsCrossed", "Point", "No" } },
	},
}

for id, extra in PERFILES do
	local person = People[id]
	if person then
		person.Perfil = extra.Perfil
		person.Actuar = extra.Actuar
		person.Edades = extra.Edades
	end
end

-- Más gente con forma de moverse propia (sin ficha completa)
local ACTUAR_EXTRA: { [string]: Actuar } = {
	Ramon = { Mood = "Joy", Tempo = 0.8, Open = 0.4, Gestos = { "Laugh", "Point" } },
	Marisa = { Mood = "Calm", Tempo = 0.7, Head = -0.02, Gestos = { "Nod" } },
	Marta = { Mood = "Joy", Tempo = 1.1, Open = 0.5, Gestos = { "Clap", "Happy" } },
	Andres = { Mood = "Joy", Tempo = 1.3, Open = 0.6, Gestos = { "Cheer", "Clap", "Point" } },
	Lola = { Mood = "Calm", Tempo = 1.25, Open = 0.5, Gestos = { "HandsOnHips", "Point" } },
	Beltran = { Mood = "Calm", Tempo = 0.8, Gaze = "Hold", Gestos = { "ArmsCrossed" } },
	Julia = { Mood = "Nervous", Tempo = 1.2, Fidget = 0.7, Gaze = "Around", Gestos = { "Nervous" } },
	Adrian = { Mood = "Nervous", Tempo = 1.1, Fidget = 0.4, Gestos = { "HandsOnHips", "Point" } },
	DonEscamas = { Mood = "Nervous", Tempo = 1.3, Fidget = 0.8, Gaze = "Around", Gestos = { "Nervous" } },
	Tito = { Mood = "Joy", Tempo = 0.9, Gaze = "Hold", Gestos = { "WaveLite" } },
	Rex = { Mood = "Calm", Tempo = 0.9, Open = 0.2, Gestos = { "Nod" } },
	Bigotes = { Mood = "Calm", Tempo = 0.7, Head = 0.1, Open = 0.5, Gaze = "Hold" },
	Alba = { Mood = "Joy", Tempo = 1.3, Fidget = 0.5, Gestos = { "Ask" } },
}
for id, actuar in ACTUAR_EXTRA do
	if People[id] and not People[id].Actuar then
		People[id].Actuar = actuar
	end
end

local Cast = { People = People }

-- El reparto principal: los que tienen ficha completa (Perfil). scripts/test-cast lo comprueba.
Cast.Principales = {
	"Familia", "Abu", "Lucia", "Nico", "Sara", "Omar", "Mateo", "Dani", "Bruno", "Ruben", "Hugo", "Alex", "Vega", "Iker",
	"Leire", "Rayo", "Nerea", "Javier", "Carmen", "Cosme", "Pip", "Cosimo", "Ivan", "Candela",
}

-- La ficha de guion de un personaje (o nil)
function Cast.perfil(id: string): Perfil?
	local person = People[id]
	return person and person.Perfil
end

-- Cómo se mueve por defecto: emoción de base (nombre de ActorMoods) y ajustes de actuación.
-- Siempre devuelve una tabla (vacía si el personaje no tiene nada especial).
function Cast.acting(id: string): Actuar
	local person = People[id]
	return (person and person.Actuar) or {}
end

-- La emoción de base de un personaje (nil = la normal)
function Cast.defaultMood(id: string): string?
	local person = People[id]
	return person and person.Actuar and person.Actuar.Mood
end

-- Escala del cuerpo de un personaje cuando el JUGADOR está en una etapa (misma regla que SceneService:
-- los compañeros Kid crecen contigo; Teen = 0,85; adultos = 1). Edades[etapa].Scale manda si existe.
function Cast.scaleAt(id: string, stage: string?): number
	local person = People[id]
	if not person then
		return 1
	end
	local edad = person.Edades and stage and person.Edades[stage]
	if edad and type(edad.Scale) == "number" then
		return edad.Scale
	end
	if person.Kid then
		if stage == "Adolescente" then
			return 0.85
		elseif stage == nil or stage == "Bebe" or stage == "Nino" then
			return 0.65
		end
		return 1
	end
	return if person.Teen then 0.85 else 1
end

-- El aspecto de un personaje en una etapa del jugador (para los montajes de P7): una copia de su ficha
-- con la ropa de esa etapa, más Scale (escala) y Age (atributo de AgeMotion: «Nino», «Adolescente», «Mayor» o nil).
-- Backpack = false en Edades quita la mochila. Nunca cambia la tabla original.
function Cast.atStage(id: string, stage: string?): { [string]: any }?
	local person = People[id]
	if not person then
		return nil
	end
	local look: { [string]: any } = table.clone(person :: any)
	local edad = person.Edades and stage and person.Edades[stage]
	-- Edad por defecto (la misma que pone SceneService)
	local age: string? = nil
	if person.Kid then
		age = if stage == "Adolescente" then "Adolescente" elseif stage == nil or stage == "Bebe" or stage == "Nino" then "Nino" else nil
	elseif person.Teen then
		age = "Adolescente"
	elseif person.Old then
		age = "Mayor"
	end
	if edad then
		for key, value in edad do
			if key ~= "Scale" and key ~= "Age" then
				look[key] = if value == false then nil else value
			end
		end
		if edad.Age ~= nil then
			age = edad.Age
		end
	end
	look.Scale = Cast.scaleAt(id, stage)
	look.Age = age
	return look
end

-- La ficha entera en texto (para herramientas de guion y auditorías)
function Cast.bioText(id: string): string
	local person = People[id]
	if not person then
		return ""
	end
	local p = person.Perfil
	if not p then
		return person.Bio
	end
	local parts = { p.Personalidad, "Habla: " .. p.Habla.Vocabulario .. " " .. p.Habla.Ritmo }
	if #p.Habla.Muletillas > 0 then
		table.insert(parts, "Muletillas: «" .. table.concat(p.Habla.Muletillas, "», «") .. "»")
	end
	table.insert(parts, "Emociones: " .. p.Emociones)
	table.insert(parts, "Quiere: " .. p.Motivacion)
	return table.concat(parts, "\n")
end

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
