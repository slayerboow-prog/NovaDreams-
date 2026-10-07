-- GUION REESCRITO de Cole11_Proyecto (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Cole11_Proyecto.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Cole11_Proyecto
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Cole11_Proyecto.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Cole11_Proyecto.md",
	Dialogues = {
		Anuncio = {
			Lines = {
				{ S = "Lucia", T = "Forma tu equipo", To = "Yo" },
				{ S = "Omar", T = "Tú y yo.", To = "Yo" },
				{ S = "Omar", T = "Si quieres.", To = "Yo", Pause = 0.9 },
				{ S = "Omar", T = "Os falta una persona.", To = "Yo" },
			},
		},
		Desastre = {
			Lines = {
				{ S = "Familia", T = "{nombre}, teléfono.", To = "Yo", Effects = { Scene = "Cole11_G14_Musica" } },
				{
					Ask = "¿Qué hacéis?",
					Options = {
						{
							T = "Llamar al equipo y arreglarla juntos (en casa de Omar)",
							Effects = { Flags = { "ArregloEnEquipo" }, Rel = { Omar = 6 }, Traits = { Responsabilidad = 1 } },
							Then = {
								{ S = "Narrador", T = "Pasáis la tarde entre pegamento y cinta. Queda un poco torcida… pero es vuestra. Y lleva una tirita de cartón." },
							},
						},
						{
							T = "Pedir ayuda a {familia}",
							Effects = { Flags = { "AyudaFamilia" }, Rel = { Familia = 6 } },
							Then = {
								{ S = "Familia", T = "¿Pegamento, tijeras y nervios? Tengo las tres cosas. Vamos." },
								{ S = "Abu", T = "Y yo sé hacer las esquinas rectas con una regla y un libro gordo. Truco de los de antes." },
							},
						},
						{
							T = "Presentarla rota… y contar lo que pasó con humor",
							Effects = { Flags = { "MaquetaRota" }, Traits = { Humor = 2 } },
							Then = { { S = "Omar", T = "¿Presentarla… así? Bueno. Diremos que ha sobrevivido a un terremoto. Un terremoto de cuatro años." } },
						},
					},
				},
			},
		},
		Discusion = {
			Lines = {
				{ S = "Sara", T = "No podemos ponerlo ahí.", To = "Yo", If = { Choices = { Companero = "Sara" } }, Effects = { Scene = "Cole11_G11_Musica" } },
				{ S = "Omar", T = "Nadie va a notar dos centímetros.", To = "Yo" },
				{ S = "Sara", T = "Yo sí.", To = "Yo", If = { Choices = { Companero = "Sara" } } },
				{ S = "Nico", T = "¡Tiene que verse desde la puerta!", To = "Yo", If = { Choices = { Companero = "Nico" } } },
				{ S = "Omar", T = "Pero ocupa media mesa.", To = "Yo" },
				{ S = "Nico", T = "Iker coloca una tabla.", To = "Yo", If = { Choices = { Companero = "Nico" } } },
				{ S = "Iker", T = "Antes de construir necesitamos una tabla.", To = "Yo", If = { Choices = { Companero = "Iker" } } },
				{ S = "Omar", T = "Ya tenemos una mesa.", To = "Yo" },
				{ S = "Iker", T = "No.", To = "Yo", If = { Choices = { Companero = "Iker" } } },
				{ S = "Mateo", T = "He pensado que…", To = "Yo", If = { Choices = { Companero = "Mateo" } } },
				{ S = "Mateo", T = "Quizá no sea suficientemente bueno.", To = "Yo", Pause = 0.9, If = { Choices = { Companero = "Mateo" } } },
				{ S = "Hugo", T = "Todo invento necesita una razón para existir.", To = "Yo", Pause = 0.9, If = { Choices = { Companero = "Hugo" } } },
				{ S = "Omar", T = "Vale.", To = "Yo" },
				{ S = "Mateo", T = "¿De verdad os gusta?", To = "Yo", Pause = 0.9, If = { Choices = { Companero = "Mateo" } } },
				{
					Ask = "¿Cómo lo resolvéis?",
					Options = {
						{
							T = "Juntar las dos ideas: un poco de cada",
							Effects = { Choice = { Discusion = "Juntar" }, Rel = { Hugo = 2, Iker = 2, Mateo = 2, Nico = 2, Omar = 3, Sara = 2 }, Traits = { Empatia = 1 } },
							Then = { { S = "Omar", T = "¡Eso! Exacto Y con luces. Con historia Y con datos. Somos unos genios de la diplomacia." } },
						},
						{
							T = "Votar, y lo que salga",
							Effects = { Choice = { Discusion = "Votar" }, Traits = { Responsabilidad = 1 } },
							Then = { { S = "Omar", T = "Votación. Dos contra uno. Bueno, uno contra uno contra uno. Otra vez. …Ya está: gana la mezcla." } },
						},
						{
							T = "Decidir tú, que para algo lo has pensado",
							Effects = { Choice = { Discusion = "Decidir" }, Rel = { Hugo = -2, Iker = -2, Nico = -2, Omar = -1, Sara = -2 }, Traits = { Valentia = 1 } },
							Then = { { S = "Omar", T = "Vale… lo hacemos como dices. Pero que conste que ha sido un poco de «porque sí»." } },
						},
					},
				},
			},
		},
		Inv_Biblioteca = { Lines = { { S = "Marisa", T = "¿Inventos?", To = "Yo" } } },
		Inv_Fuente = { Lines = { { S = "Omar", T = "Y yo llevo tres vasos.", To = "Yo" } } },
		Inv_Ramon = { Lines = { { S = "Ramon", T = "¿Una entrevista?", To = "Yo" }, { S = "Ramon", T = "Ahora sí.", To = "Yo" } } },
		Mat_Carton = {
			Lines = {
				{ S = "Andres", T = "Coged lo que necesitéis.", To = "Yo" },
				{ S = "Nico", T = "¿Y si necesitamos conos?", To = "Yo", Pause = 0.9, If = { Choices = { Companero = "Nico" } } },
				{ S = "Andres", T = "No necesitáis conos.", To = "Yo", If = { Choices = { Companero = "Nico" } } },
				{ S = "Nico", T = "Vale.", To = "Yo", If = { Choices = { Companero = "Nico" } } },
			},
		},
		Resultado = {
			Lines = {
				{
					S = "Lucia",
					T = "Voy a enviarlo al periódico de Valmar.",
					To = "Yo",
					Pause = 1.8,
					If = { LastGradeAtLeast = 8 },
					Effects = { Scene = "Cole11_G19_Musica" },
				},
				{ S = "Lucia", T = "Creo que merece que lo conozca el barrio.", To = "Yo", Pause = 0.9, If = { LastGradeAtLeast = 8 } },
				{ S = "Familia", T = "Pase lo que pase…", To = "Yo" },
				{ S = "Abu", T = "¿Sabes qué es lo mejor de un proyecto?", To = "Yo", Pause = 0.9 },
				{ S = "Abu", T = "Que mañana ya sabes más que hoy.", To = "Yo" },
				{ S = "Omar", T = "¿Ya?", To = "Yo", Pause = 0.9 },
				{ S = "Nico", T = "Pues yo todavía tengo que ganar un último partido.", To = "Yo", If = { Choices = { Companero = "Nico" } } },
				{ S = "Sara", T = "Todavía tengo aquel esquema.", To = "Yo", If = { Choices = { Companero = "Sara" } } },
				{ S = "Nico", T = "Nuestro proyecto casi podía verse desde la puerta.", To = "Yo", If = { Choices = { Companero = "Nico" } } },
				{ S = "Iker", T = "Conservé los datos.", To = "Yo", If = { Choices = { Companero = "Iker" } } },
				{ S = "Mateo", T = "Todavía tengo los dibujos.", To = "Yo", If = { Choices = { Companero = "Mateo" } } },
				{ S = "Hugo", T = "Le pusimos una historia.", To = "Yo", If = { Choices = { Companero = "Hugo" } } },
				{ S = "Omar", T = "Nunca debe quedarse mirando fijamente.", To = "Yo" },
				{ If = { LastGradeAtLeast = 8 }, Effects = { Flags = { "ProyectoPremiado" } } },
			},
		},
		TemaYRol = {
			Lines = {
				{ S = "Omar", T = "Bueno.", To = "Yo" },
				{ S = "Omar", T = "¿Qué inventamos?", To = "Yo" },
				{ S = "Omar", T = "Tomates.", To = "Yo" },
				{ S = "Omar", T = "Me gusta este invento.", To = "Yo", Pause = 1.8 },
				{ S = "Omar", T = "Un robot que recoge basura del parque.", To = "Yo" },
				{ S = "Omar", T = "Robot.", To = "Yo" },
				{ S = "Omar", T = "Como Bigotes.", To = "Yo", Pause = 0.9 },
				{ S = "Omar", T = "Solo si existe la marca de la cápsula.", To = "Yo", Pause = 0.9 },
				{ S = "Omar", T = "Un museo del colegio con la sala cerrada.", To = "Yo" },
				{ S = "Omar", T = "Tú buscas.", To = "Yo", Pause = 0.9 },
				{ S = "Omar", T = "Manos de artista.", To = "Yo", Pause = 0.9 },
				{ S = "Omar", T = "Pero no te lo comas.", To = "Yo" },
				{ S = "Omar", T = "Yo lo presento.", To = "Yo" },
				{
					Ask = "¿Cuál es vuestro invento?",
					Options = {
						{
							T = "Un huerto en el patio del cole",
							Effects = { Choice = { Tema = "Huerto" }, Traits = { Responsabilidad = 1 } },
							Then = { { S = "Omar", T = "Tomates del cole. Lechugas del cole. Ensalada del cole. Me gusta todo de esta idea." } },
						},
						{
							T = "Un robot que recoge basura del parque",
							Effects = { Choice = { Tema = "Robot" }, Traits = { Curiosidad = 1 } },
							Then = { { S = "Omar", T = "Un robot. ¿Le podemos poner nombre? Se llama Bocadillo. No hay más que hablar." } },
						},
						{
							T = "Un tablón para encontrar mascotas perdidas",
							Effects = { Choice = { Tema = "Mascotas" }, Traits = { Empatia = 1 } },
							Then = { { S = "Omar", T = "Como Bigotes, el gato del cole. Seguro que Bigotes lo aprobaría. Con un maullido." } },
						},
						{
							T = "Un museo del colegio con la sala cerrada",
							If = { Flags = { "CapsulaDelTiempo" } },
							Effects = { Choice = { Tema = "Museo" }, Rel = { Lucia = 3 }, Traits = { Creatividad = 1 } },
							Then = { { S = "Omar", T = "¡Con la foto de Lucía! Bueno… si Lucía quiere. Le preguntamos primero." } },
						},
					},
				},
				{
					Ask = "¿Qué haces tú en el equipo?",
					Options = {
						{
							T = "Organizo: alguien tiene que llevar el calendario",
							Effects = { Choice = { Rol = "Lider" }, Traits = { Responsabilidad = 1 } },
							Then = { { S = "Omar", T = "Jefe o jefa de proyecto. Te hago una chapa. De cartón, que es lo que hay." } },
						},
						{
							T = "Investigo: buscar datos es lo mío",
							Effects = { Choice = { Rol = "Investigador" }, Traits = { Curiosidad = 1 } },
							Then = { { S = "Omar", T = "Tú buscas, yo te acompaño y traigo galletas. Es un sistema perfecto." } },
						},
						{
							T = "Construyo la maqueta",
							Effects = { Choice = { Rol = "Constructor" }, Traits = { Creatividad = 1 } },
							Then = { { S = "Omar", T = "Manos de artista. Yo te paso el pegamento. Sin comérmelo." } },
						},
						{
							T = "Presento delante de todos",
							Effects = { Choice = { Rol = "Presentador" }, Traits = { Valentia = 1 } },
							Then = { { S = "Omar", T = "¿Delante de las familias? Qué valor. Yo me pongo al lado y sujeto la maqueta con cara seria." } },
						},
					},
				},
			},
		},
	},
	Scenes = {
		Cole11_G11_Musica = { Light = true, Duration = 42.8, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Cole11_G12_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = { Actors = { { At = 0, Use = { Key = "Omar", Npc = "Omar" } } }, Dialogue = { { At = 0.4, S = "Omar", T = "¡Bocadillo funciona!", To = "Yo" } } },
		},
		Cole11_G14_Musica = { Light = true, Duration = 4.5, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
		Cole11_G16_Entra = {
			Light = true,
			Duration = 14.1,
			Anchors = { A_Abu = "Place:FamiliaAbu", A_Familia = "Place:FamiliaPadre", Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Bruno", Npc = "Bruno" } },
					{ At = 0, Use = { Anchor = "A_Familia", Key = "Familia", Npc = "Familia" } },
					{ At = 0, Use = { Anchor = "A_Abu", Key = "Abu", Npc = "Abu" } },
				},
				Dialogue = {
					{ At = 0.4, S = "Familia", T = "¡Ánimo, {nombre}!", To = "Yo" },
					{ At = 2.5, S = "Abu", T = "Me tiemblan las rodillas.", To = "Yo" },
					{ At = 5.9, S = "Abu", T = "¿A ti también?", To = "Yo" },
					{ At = 8, S = "Bruno", T = "Está junto a otra maqueta.", To = "Yo" },
					{ At = 11.4, S = "Bruno", T = "Otra vez.", To = "Yo" },
				},
			},
		},
		Cole11_G18_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Omar", Npc = "Omar" } } },
				Dialogue = { { At = 1.3, S = "Omar", T = "Y sobrevivió.", To = "Yo" }, { At = 3.4, S = "Omar", T = "Esta parte no estaba en el diseño.", To = "Yo" } },
				Music = { { At = 0, Intensity = "Intima" } },
			},
		},
		Cole11_G19_Musica = {
			Light = true,
			Duration = 44.5,
			Anchors = { Yo = "Player" },
			Tracks = { Music = { { At = 0, Intensity = "Intima" }, { At = 22.2, Intensity = "Descubrimiento" } } },
		},
		Cole11_G3_Entra = {
			Light = true,
			Duration = 21.9,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Lucia", Npc = "Lucia" } },
					{ At = 0, If = { Choices = { Companero = "Nico" } }, Use = { Key = "Nico", Npc = "Nico" } },
				},
				Dialogue = {
					{ At = 0.4, S = "Lucia", T = "Antes de terminar primaria, quiero que hagáis algo que pueda mejorar Valmar.", To = "Yo" },
					{ At = 6.6, S = "Nico", T = "¿Puede explotar?", To = "Yo", If = { Choices = { Companero = "Nico" } } },
					{ At = 9.6, S = "Nico", T = "¿Puede llevar comida?", To = "Yo", If = { Choices = { Companero = "Nico" } } },
					{ At = 11.9, S = "Lucia", T = "Si ayuda a Valmar, puede llevar comida.", To = "Yo" },
					{ At = 15.2, S = "Nico", T = "¿Delante de las familias?", To = "Yo", If = { Choices = { Companero = "Nico" } } },
					{ At = 17.7, S = "Nico", T = "Mi abuela se ríe hasta cuando no pasa nada.", To = "Yo", If = { Choices = { Companero = "Nico" } } },
				},
				Music = { { At = 0, Intensity = "Descubrimiento" } },
			},
		},
		Cole11_G5_Entra = {
			Light = true,
			Duration = 26.1,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, If = { Choices = { Companero = "Hugo" } }, Use = { Key = "Hugo", Npc = "Hugo" } },
					{ At = 0, If = { Choices = { Companero = "Sara" } }, Use = { Key = "Sara", Npc = "Sara" } },
					{ At = 0, If = { Choices = { Companero = "Nico" } }, Use = { Key = "Nico", Npc = "Nico" } },
					{ At = 0, If = { Choices = { Companero = "Iker" } }, Use = { Key = "Iker", Npc = "Iker" } },
					{ At = 0, Use = { Key = "Omar", Npc = "Omar" } },
					{ At = 0, If = { Choices = { Companero = "Mateo" } }, Use = { Key = "Mateo", Npc = "Mateo" } },
				},
				Dialogue = {
					{ At = 0.4, S = "Omar", T = "¿Quién será vuestro tercer compañero?", To = "Yo" },
					{ At = 3.6, S = "Sara", T = "Acepto.", To = "Yo", If = { Choices = { Companero = "Sara" } } },
					{ At = 5.6, S = "Nico", T = "¡Sí!", To = "Yo", If = { Choices = { Companero = "Nico" } } },
					{ At = 8.6, S = "Nico", T = "Vamos a hacer algo enorme.", To = "Yo", If = { Choices = { Companero = "Nico" } } },
					{ At = 11.2, S = "Nico", T = "Muy segur{o/a}.", To = "Yo", If = { Choices = { Companero = "Nico" } } },
					{ At = 13.2, S = "Iker", T = "Acepto.", To = "Yo", If = { Choices = { Companero = "Iker" } } },
					{ At = 16.2, S = "Mateo", T = "¿Yo?", To = "Yo", If = { Choices = { Companero = "Mateo" } } },
					{ At = 19.1, S = "Mateo", T = "Vale.", To = "Yo", If = { Choices = { Companero = "Mateo" } } },
					{ At = 21.2, S = "Mateo", T = "Mi padre me enseña.", To = "Yo", If = { Choices = { Companero = "Mateo" } } },
					{ At = 23.4, S = "Hugo", T = "¡Sí!", To = "Yo", If = { Choices = { Companero = "Hugo" } } },
				},
			},
		},
		Cole11_G9_Entra = {
			Light = true,
			Duration = 12.9,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Omar", Npc = "Omar" } }, { At = 0, If = { Choices = { Companero = "Nico" } }, Use = { Key = "Nico", Npc = "Nico" } } },
				Dialogue = {
					{ At = 0.4, S = "Nico", T = "Compra las cartulinas", To = "Yo", If = { Choices = { Companero = "Nico" } } },
					{
						At = 2.7,
						S = "Nico",
						T = "Aquí el juego debe introducir una pequeña interacción económica.",
						To = "Yo",
						If = { Choices = { Companero = "Nico" } },
					},
					{ At = 7.4, S = "Nico", T = "No basta con pulsar «comprar».", To = "Yo", If = { Choices = { Companero = "Nico" } } },
					{ At = 10.2, S = "Omar", T = "Tengo dos.", To = "Yo" },
				},
			},
		},
	},
	Steps = {
		["11"] = { Effects = { Scene = "Cole11_G12_Entra" } },
		["15"] = { Effects = { Scene = "Cole11_G16_Entra" } },
		["17"] = { Effects = { Scene = "Cole11_G18_Entra" } },
		["2"] = { Effects = { Scene = "Cole11_G3_Entra" } },
		["4"] = { Effects = { Scene = "Cole11_G5_Entra" } },
		["8"] = { Effects = { Scene = "Cole11_G9_Entra" } },
	},
}
