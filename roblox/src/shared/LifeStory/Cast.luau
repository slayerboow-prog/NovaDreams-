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
	Bio: string,
}

local People: { [string]: Person } = {
	-- Familia (en la casa donde naciste; el nombre depende de la casa: Mamá/Papá, Abu Rosa/Abu Tomás)
	Familia = {
		Name = "NPC.MAMA", NameAttr = "FamilyKey", Voice = "Familia",
		Skin = rgb(198, 150, 112), Shirt = rgb(70, 120, 170), Pants = rgb(50, 50, 60),
		Bio = "Cariño con prisas. Bromea para que no estés nervioso. Siempre pregunta qué tal el día.",
	},
	Abu = {
		Name = "NPC.ABU_ROSA", NameAttr = "AbuKey", Voice = "Abu",
		Skin = rgb(234, 196, 160), Shirt = rgb(150, 90, 120), Pants = rgb(90, 80, 70),
		Bio = "Calma y refranes. Cuenta historias de cuando Valmar era un pueblo.",
	},

	-- Colegio: adultos
	Lucia = {
		Name = "NPC.PROFE_LUCIA", Voice = "Profe",
		Skin = rgb(226, 186, 150), Shirt = rgb(240, 196, 60), Pants = rgb(60, 70, 100),
		Bio = "Tutora de 1.º A. Cariñosa y exigente, frases cortas, humor seco. Estudió en este mismo colegio.",
	},
	Ramon = {
		Name = "Ramón", Voice = "Abu",
		Skin = rgb(200, 150, 110), Shirt = rgb(60, 90, 150), Pants = rgb(40, 50, 70),
		Bio = "Conserje. Bromista, lo sabe todo del colegio, lleva un manojo enorme de llaves.",
	},
	Marta = {
		Name = "Marta", Voice = "Profe",
		Skin = rgb(236, 200, 170), Shirt = rgb(70, 160, 90), Pants = rgb(60, 50, 50),
		Bio = "Profe de música. Dulce, habla cantando, siempre tararea algo.",
	},
	Andres = {
		Name = "Andrés", Voice = "Profe",
		Skin = rgb(170, 120, 86), Shirt = rgb(220, 60, 60), Pants = rgb(30, 30, 40),
		Bio = "Profe de Educación Física. Silbato, entusiasmo, frases de entrenador.",
	},

	-- Colegio: la clase de 1.º A
	Nico = {
		Name = "NPC.NICO", Voice = "Nino", Kid = true,
		Skin = rgb(236, 196, 160), Shirt = rgb(220, 60, 50), Pants = rgb(40, 60, 120),
		Bio = "Deportista, impulsivo, competitivo pero generoso. Todo es un reto. Habla con exclamaciones.",
	},
	Sara = {
		Name = "NPC.SARA", Voice = "Nino", Kid = true,
		Skin = rgb(242, 214, 180), Shirt = rgb(120, 190, 90), Pants = rgb(70, 70, 90),
		Bio = "Curiosa y científica, habla rapidísimo y usa palabras largas. Perfeccionista con los deberes.",
	},
	Omar = {
		Name = "NPC.OMAR", Voice = "Nino", Kid = true,
		Skin = rgb(170, 120, 86), Shirt = rgb(250, 170, 60), Pants = rgb(60, 60, 60),
		Bio = "Artista tranquilo, siempre tiene hambre y un lápiz. Dibuja lo que pasa (sus dibujos son pistas).",
	},
	Mateo = {
		Name = "Mateo", Voice = "Nino", Kid = true,
		Skin = rgb(230, 190, 150), Shirt = rgb(140, 140, 200), Pants = rgb(80, 70, 60),
		Bio = "Tímido, nuevo en el barrio, colecciona cromos. Se le caen las cosas. Leal cuando confía.",
	},
	Dani = {
		Name = "Dani", Voice = "Nino", Kid = true,
		Skin = rgb(230, 190, 150), Shirt = rgb(60, 200, 200), Pants = rgb(60, 60, 120),
		Bio = "Hermano pequeño de Mateo (5 años). Todo lo pregunta. Adora su balón.",
	},
	Bruno = {
		Name = "Bruno", Voice = "Nino", Kid = true,
		Skin = rgb(220, 180, 140), Shirt = rgb(30, 30, 30), Pants = rgb(40, 40, 60),
		Bio = "Líder de 'los malotes'. Fanfarrón, necesita que le miren. Su hermano mayor le presiona.",
	},
	Ruben = {
		Name = "Rubén", Voice = "Nino", Kid = true,
		Skin = rgb(236, 200, 170), Shirt = rgb(110, 60, 150), Pants = rgb(40, 40, 50),
		Bio = "El bromista de Bruno. Hace cosas para que Bruno se ría; en el fondo quiere caer bien.",
	},
	Hugo = {
		Name = "Hugo", Voice = "Nino", Kid = true,
		Skin = rgb(190, 140, 100), Shirt = rgb(90, 100, 110), Pants = rgb(50, 50, 50),
		Bio = "Va con Bruno pero no quiere. Le encantan los libros de piratas. Habla poco y bajito.",
	},
	Alex = {
		Name = "Álex", Voice = "Nino", Kid = true,
		Skin = rgb(240, 205, 175), Shirt = rgb(250, 250, 250), Pants = rgb(30, 90, 60),
		Bio = "Deportista, portera del equipo, directa y justa. Todo lo convierte en apuesta (sin dinero).",
	},
	Vega = {
		Name = "Vega", Voice = "Nino", Kid = true,
		Skin = rgb(200, 150, 120), Shirt = rgb(200, 120, 200), Pants = rgb(70, 50, 90),
		Bio = "Artista, soñadora, colecciona pegatinas brillantes. Habla de colores.",
	},
	Iker = {
		Name = "Iker", Voice = "Nino", Kid = true,
		Skin = rgb(236, 200, 170), Shirt = rgb(60, 110, 200), Pants = rgb(90, 90, 90),
		Bio = "El que se lo sabe todo. Gafas, datos curiosos, un poco sabelotodo pero buena gente.",
	},

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
