-- Cast: el reparto de la historia. Cada personaje que aparece en una escena, habla en un diálogo o
-- se recuerda está aquí: nombre, voz (Config.Audio.Voices.Speakers), aspecto y personalidad.
--
--   Name      nombre que se ve (o clave de Strings)
--   NameAttr  (opcional) atributo del jugador con la clave de su nombre (la familia cambia en cada casa)
--   Voice     perfil de voz sintetizada
--   Kid       tamaño de niño (escala 0.65); Teen = 0.85; si no, adulto
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
	Skin: Color3,
	Shirt: Color3,
	Pants: Color3,
	Shoes: Color3?,
	Hair: Color3?,
	LongHair: boolean?,
	LongSleeves: boolean?,
	Backpack: Color3?, -- mochila a la espalda (los niños del cole)
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
		Name = "NPC.ABU_ROSA", NameAttr = "AbuKey", Voice = "Abu",
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
		Name = "Ramón", Voice = "Abu",
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
		Name = "Marisa", Voice = "Abu",
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
		Name = "Julián", Voice = "Abu",
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
	Veterano = { Name = "Alumno de 4.º", Voice = "Nino", Teen = true, Skin = rgb(215, 170, 130), Shirt = rgb(30, 30, 30), Pants = rgb(40, 40, 70), Hair = rgb(20, 20, 22), Bio = "Le encanta tomar el pelo a los de primero." },
	Delegada = { Name = "Delegada de 4.º", Voice = "Nino", Teen = true, Skin = rgb(185, 135, 100), Shirt = rgb(230, 170, 60), Pants = rgb(30, 30, 30), Hair = rgb(30, 20, 15), LongHair = true, Bio = "Organizada, amable, siempre con una carpeta." },

	-- La semana de las profesiones
	Nuria = { Name = "Doctora Nuria", Voice = "Profe", Skin = rgb(230, 190, 160), Shirt = rgb(245, 245, 245), Pants = rgb(80, 150, 170), Hair = rgb(60, 40, 30), LongHair = true, Bio = "Médica de urgencias. Rápida, cálida, habla con las manos." },
	Tomas = { Name = "Tomás", Voice = "Abu", Skin = rgb(190, 140, 100), Shirt = rgb(40, 70, 130), Pants = rgb(40, 70, 130), Hair = rgb(120, 120, 120), Bio = "Mecánico de toda la vida. Manos negras de grasa y paciencia infinita." },
	Ines = { Name = "Agente Inés", Voice = "Profe", Skin = rgb(210, 165, 125), Shirt = rgb(30, 50, 110), Pants = rgb(30, 40, 70), Hair = rgb(30, 25, 20), Bio = "Policía de barrio. Conoce a todo el mundo por su nombre." },
	Marcos = { Name = "Marcos", Voice = "Profe", Skin = rgb(240, 205, 175), Shirt = rgb(250, 250, 250), Pants = rgb(40, 40, 60), Hair = rgb(200, 170, 110), Bio = "Dirige una pequeña empresa de bicicletas. Todo lo convierte en un plan." },
	Lola = { Name = "Chef Lola", Voice = "Familia", Skin = rgb(180, 125, 90), Shirt = rgb(250, 250, 250), Pants = rgb(30, 30, 30), Hair = rgb(20, 20, 22), LongHair = true, Bio = "Cocinera. Grita en la cocina y abraza fuera de ella." },
	Sofia = { Name = "Sofía", Voice = "Profe", Skin = rgb(235, 200, 170), Shirt = rgb(250, 250, 250), Pants = rgb(60, 60, 80), Hair = rgb(20, 20, 22), LongHair = true, Bio = "Ingeniera de laboratorio en la facultad. Le brillan los ojos con cualquier motor." },
	Irene = { Name = "Irene", Voice = "Profe", Skin = rgb(160, 110, 80), Shirt = rgb(240, 120, 40), Pants = rgb(30, 30, 30), Hair = rgb(20, 20, 22), Bio = "Entrenadora y fisioterapeuta. Cronómetro en una mano, bolsa de hielo en la otra." },
	Toni = { Name = "Toni", Voice = "Profe", Skin = rgb(225, 180, 140), Shirt = rgb(20, 20, 20), Pants = rgb(20, 20, 20), Hair = rgb(90, 60, 40), Bio = "Hace vídeos y documentales. Tío de Leire. Habla en planos: «esto, en primer plano, sería precioso»." },

	-- Gente de fondo (entrada del colegio, calle)
	Alumno1 = { Name = "Alumno", Voice = "Nino", Kid = true, Skin = rgb(236, 196, 160), Shirt = rgb(250, 200, 70), Pants = rgb(40, 50, 90), Bio = "" },
	Alumno2 = { Name = "Alumna", Voice = "Nino", Kid = true, Skin = rgb(180, 130, 95), Shirt = rgb(90, 180, 220), Pants = rgb(60, 40, 70), Bio = "" },
	Alumno3 = { Name = "Alumno", Voice = "Nino", Kid = true, Skin = rgb(240, 210, 180), Shirt = rgb(120, 200, 120), Pants = rgb(50, 50, 50), Bio = "" },
	Alumno4 = { Name = "Alumna", Voice = "Nino", Kid = true, Skin = rgb(210, 160, 120), Shirt = rgb(240, 120, 150), Pants = rgb(40, 60, 100), Bio = "" },
	Mayor1 = { Name = "Alumno de 6.º", Voice = "Nino", Teen = true, Skin = rgb(220, 180, 140), Shirt = rgb(40, 40, 40), Pants = rgb(30, 30, 60), Bio = "" },
	Mayor2 = { Name = "Alumna de 6.º", Voice = "Nino", Teen = true, Skin = rgb(190, 140, 100), Shirt = rgb(200, 60, 60), Pants = rgb(30, 30, 30), Bio = "" },
	Madre = { Name = "Una madre", Voice = "Familia", Skin = rgb(230, 190, 150), Shirt = rgb(180, 80, 80), Pants = rgb(50, 50, 70), Bio = "" },
	Padre = { Name = "Un padre", Voice = "Familia", Skin = rgb(170, 120, 86), Shirt = rgb(80, 120, 80), Pants = rgb(40, 40, 50), Bio = "" },
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
