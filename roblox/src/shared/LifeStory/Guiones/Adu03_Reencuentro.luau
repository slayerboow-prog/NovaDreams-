-- GUION REESCRITO de Adu03_Reencuentro (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Adu03_Reencuentro.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Adu03_Reencuentro
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Adu03_Reencuentro.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Adu03_Reencuentro.md",
	Dialogues = {
		Banco = {
			Lines = {
				{ S = "Nico", T = "Y lo del trabajo… Que te den otro. Uno mejor.", To = "Yo", A = "ThinkChin", If = { Flags = { "Despedido" } } },
				{ S = "Omar", T = "Y con ascenso. Hoy invitas tú.", To = "Yo", A = "Shrug", If = { Flags = { "Ascendido" } } },
				{ S = "Sara", T = "¿Y tu abu? ¿Fuisteis al mar?", To = "Yo", A = "Ask", If = { Memories = { "AtardecerConAbu" } } },
				{ S = "Yo", T = "Sí. Le prometí volver.", A = "Nod", If = { Memories = { "AtardecerConAbu" } } },
				{ S = "Nico", T = "Entonces volverás.", To = "Yo", A = "Happy", If = { Memories = { "AtardecerConAbu" } } },
				{ S = "Nico", T = "¿Os acordáis del nombre que nos pusimos?", To = "Yo", If = { Memories = { "PrimerGrupo" } } },
				{ S = "Narrador", T = "TODOS: «¡{grupo}!»", If = { Memories = { "PrimerGrupo" } } },
				{ S = "Sara", T = "Lo hemos dicho todos a la vez. Estadísticamente…", To = "Yo", A = "Happy", If = { Memories = { "PrimerGrupo" } } },
				{ S = "Nico", T = "No.", To = "Yo", A = "No", If = { Memories = { "PrimerGrupo" } } },
				{ S = "Sara", T = "Amistad.", To = "Yo", A = "Nod", If = { Memories = { "PrimerGrupo" } } },
				{ S = "Omar", T = "Deberíamos prometer otra cosa.", To = "Yo", A = "HandsOnHips" },
				{ S = "Nico", T = "¿Otra?", To = "Yo", A = "Ask" },
				{ S = "Omar", T = "Una última.", To = "Yo", A = "Shrug" },
				{
					Ask = "¿Qué promesa nueva hacéis?",
					Options = {
						{
							T = "«Cuando tengamos hijos, que sean amigos como nosotros.»",
							Effects = { Choice = { PromesaAdulta = "Hijos" } },
							Then = { { S = "Omar", T = "Y que se sienten en este banco. Y que tampoco quepan." } },
						},
						{
							T = "«Un viaje juntos, todos, antes de los treinta.»",
							Effects = { Choice = { PromesaAdulta = "Viaje" } },
							Then = { { S = "Sara", T = "Propongo Villaverde. La granja. Donde se perdió Mateo. Por nostalgia científica." } },
						},
						{
							T = "«Nada de promesas: esto ya es para siempre.»",
							Effects = { Choice = { PromesaAdulta = "Siempre" }, Traits = { Empatia = 1 } },
							Then = { { S = "Nico", T = "…Eso ha sido muy bonito. Que nadie diga nada. Que nadie diga NADA." } },
						},
					},
				},
			},
		},
		Bruno = {
			Lines = {
				{ S = "Bruno", T = "Agente Bruno. Para servirle.", To = "Yo", A = "ArmsCrossed" },
				{ S = "Yo", T = "Nunca pensé verte aquí.", A = "No", Pause = 0.9 },
				{ S = "Bruno", T = "Yo tampoco. Ahora paso el día ayudando a gente y buscando gatos.", To = "Yo", A = "ArmsCrossed" },
				{ S = "Bruno", T = "Hace un tiempo te puse las esposas.", To = "Yo", If = { Flags = { "Detenido" } } },
				{ S = "Bruno", T = "Y ahora me invitas a una fiesta. La vida es rara.", To = "Yo", Pause = 0.9, If = { Flags = { "Detenido" } } },
				{ S = "Bruno", T = "Después de todo lo del colegio…", To = "Yo", If = { Flags = { "Detenido" } } },
				{ S = "Bruno", T = "Gracias por invitarme.", To = "Yo", Pause = 0.9, If = { Flags = { "Detenido" } } },
				{ S = "Bruno", T = "Empezamos de cero, ¿no? Pues esto es el diez.", To = "Yo", If = { Choices = { AdiosBruno = "DeCero" } } },
			},
		},
		Hugo = { Lines = { { S = "Hugo", T = "Mira. Mi primera novela. Piratas. Obviamente. Ya. Me emociono yo solo. Voy.", To = "Yo", G = "Point" } } },
		Inauguracion = {
			Lines = {
				{ S = "Lola", T = "Mirad esto. Llena. Todos. Cuarenta años aquí.", To = "Yo", G = "Point" },
				{ S = "Lola", T = "He visto crecer a medio Valmar.", To = "Yo", Pause = 0.9 },
				{ S = "Lola", T = "Y a vosotros, enteros. Cuida la cafetería. Y cuida a esta gente.", To = "Yo" },
				{ S = "Lola", T = "La gente es lo único que no se puede comprar con una caja registradora.", To = "Yo" },
				{ S = "Omar", T = "La tortilla de hoy la ha hecho {nombre}. Perfecta.", To = "Yo", A = "Shrug", If = { Flags = { "TortillaPerfecta" } } },
				{ S = "Omar", T = "La tortilla de hoy la ha hecho {nombre}.", To = "Yo", If = { NotFlags = { "TortillaPerfecta" } } },
				{ S = "Omar", T = "Se le ha roto un poco. Nadie lo va a notar. Vale.", To = "Yo", If = { NotFlags = { "TortillaPerfecta" } } },
				{ S = "Omar", T = "Todos lo vais a notar.", To = "Yo", If = { NotFlags = { "TortillaPerfecta" } } },
				{ S = "Omar", T = "Y yo… Sin vosotros no habría abierto nada. Ni la cafetería.", To = "Yo" },
				{ S = "Omar", T = "Ni aquel bocadillo del primer día. Gracias. Ya está. No lloro.", To = "Yo" },
				{ S = "Sara", T = "No hay cebolla.", To = "Yo", A = "No" },
				{ S = "Omar", T = "Sara.", To = "Yo", A = "Happy" },
			},
		},
		Leire = {
			Lines = {
				{ S = "Leire", T = "¡Quietos! No puede ser. Tú.", To = "Yo", A = "Happy", If = { Flags = { "ConocesALeire" } } },
				{ S = "Leire", T = "Mi primer documental se estrena el mes que viene. Estáis todos dentro.", To = "Yo", If = { Flags = { "ConocesALeire" } } },
				{ S = "Yo", T = "¿Sin permiso?" },
				{ S = "Leire", T = "Sí. Lo siento. Bueno… No lo siento.", To = "Yo", A = "Nod", If = { Flags = { "ConocesALeire" } } },
				{ S = "Leire", T = "Entonces llevaré esto.", To = "Yo", A = "Happy", If = { Flags = { "ConocesALeire" } } },
			},
		},
		Lucia = {
			Lines = {
				{ S = "Lucia", T = "¡{nombre}! Madre mía. Ahora soy directora.", To = "Yo", A = "Happy" },
				{ S = "Lucia", T = "Tengo despacho y todo.", To = "Yo" },
				{ S = "Lucia", T = "Hay una fotografía antigua. Cuéntame.", To = "Yo" },
				{ S = "Lucia", T = "¿Qué ha sido de tu vida?", To = "Yo", Pause = 0.9 },
				{
					S = "Lucia",
					T = "Querías salvar vidas. Y ahora trabajas en un hospital.",
					To = "Yo",
					If = { Choices = { Estudios = "Medicina", SuenoInfancia = "Medicina" } },
				},
				{
					S = "Lucia",
					T = "Querías inventar cosas que no existían. Y ahora las diseñas.",
					To = "Yo",
					If = { Choices = { Estudios = "Ingenieria", SuenoInfancia = "Ingenieria" } },
				},
				{
					S = "Lucia",
					T = "Querías defender a quien no podía hacerlo.",
					To = "Yo",
					If = { Choices = { Estudios = "Derecho", SuenoInfancia = "Derecho" } },
				},
				{ S = "Lucia", T = "Querías tener tu propio negocio.", To = "Yo", If = { Choices = { Estudios = "Economia", SuenoInfancia = "Economia" } } },
				{ S = "Lucia", T = "Pero te voy a decir una cosa.", To = "Yo" },
				{ S = "Lucia", T = "No pasa nada si algún día cambias de idea.", To = "Yo" },
				{ S = "Lucia", T = "Lo importante es que la vida que tengas sea tuya.", To = "Yo", Pause = 0.9 },
				{
					Ask = "¿Qué le dices?",
					Options = {
						{
							T = "«Gracias por aquel primer día. Y por todos los demás.»",
							Effects = { Rel = { Lucia = 10 } },
							Then = { { S = "Lucia", T = "Venga. Que me haces llorar delante de los alumnos.", To = "Yo" } },
						},
						{
							T = "«¿Puedo venir a contarle a tus alumnos lo que hago?»",
							Effects = { Flags = { "CharlaColegio" }, Rel = { Lucia = 8 } },
							Then = {
								{ S = "Lucia", T = "Me encantaría. Aunque prepárate.", To = "Yo" },
								{
									S = "Lucia",
									T = "Los niños preguntan “¿por qué?” cada treinta segundos. Y la fiesta de Omar… No me la pierdo.",
									To = "Yo",
									Pause = 0.9,
								},
							},
						},
					},
				},
			},
		},
		Mateo = {
			Lines = {
				{ S = "Mateo", T = "Hola. Me alegro de verte.", To = "Yo", G = "Wave", If = { Flags = { "AyudasteAMateo" } } },
				{
					S = "Mateo",
					T = "Estoy en el proyecto de la pasarela del río.",
					To = "Yo",
					If = { Choices = { Estudios = "Ingenieria" }, Flags = { "AyudasteAMateo" } },
				},
				{
					S = "Mateo",
					T = "¿Te acuerdas de tu idea de los amortiguadores? Funciona.",
					To = "Yo",
					If = { Choices = { Estudios = "Ingenieria" }, Flags = { "AyudasteAMateo" } },
				},
				{
					S = "Mateo",
					T = "Diseño puentes. Mi padre dice que soy el fontanero más caro de la historia. La fiesta de Omar…",
					To = "Yo",
					If = { Flags = { "AyudasteAMateo" }, NotChoices = { Estudios = "Ingenieria" } },
				},
				{
					S = "Mateo",
					T = "Claro que voy. Todo empezó aquel primer día.",
					To = "Yo",
					If = { Flags = { "AyudasteAMateo" }, NotChoices = { Estudios = "Ingenieria" } },
				},
			},
		},
		Nico = {
			Lines = {
				{ S = "Nico", T = "¡{nombre}! Mira esto. Primer equipo. Firmé el mes pasado.", To = "Yo", A = "Happy" },
				{ S = "Nico", T = "¿Te acuerdas de la cápsula? La tengo enmarcada.", To = "Yo", If = { Choices = { Capsula = "Prediccion" } } },
				{ S = "Yo", T = "¿En serio?", A = "Surprised", If = { Choices = { Capsula = "Prediccion" } } },
				{ S = "Nico", T = "Decía que sería futbolista. Y mira. ¿Omar?", To = "Yo", A = "Shrug", If = { Choices = { Capsula = "Prediccion" } } },
				{ S = "Nico", T = "Tengo como diez bocadillos pendientes. Voy.", To = "Yo", If = { Choices = { Capsula = "Prediccion" } } },
			},
		},
		Noticia = {
			Lines = {
				{ S = "Lola", T = "Me jubilo.", To = "Yo", A = "Nod" },
				{ S = "Yo", T = "¿Qué?", A = "Surprised", Pause = 0.9 },
				{ S = "Lola", T = "Cuarenta años detrás de esta barra.", To = "Yo", A = "ThinkChin" },
				{ S = "Lola", T = "Creo que ya me toca ver la playa sin tener que servirle una tortilla a nadie.", To = "Yo" },
				{ S = "Omar", T = "Y me la deja a mí. A mí. La cafetería.", To = "Yo", A = "HandsOnHips" },
				{ S = "Lola", T = "Sí, Omar.", To = "Yo", A = "Nod" },
				{ S = "Omar", T = "Todavía no me acostumbro.", To = "Yo", A = "HandsOnHips" },
				{ S = "Lola", T = "Yo tampoco.", To = "Yo", A = "Nod" },
				{ S = "Lola", T = "Primero fuiste mi mejor ayuda de verano.", To = "Yo", If = { Choices = { Empleo = "Barista" } } },
				{ S = "Lola", T = "Ahora él es quien se queda.", To = "Yo", Pause = 0.9, If = { Choices = { Empleo = "Barista" } } },
				{ S = "Lola", T = "Supongo que algo hice bien.", To = "Yo", If = { Choices = { Empleo = "Barista" } } },
				{ S = "Lola", T = "¿Te acuerdas?", To = "Yo" },
				{ S = "Lola", T = "Entonces erais niños. Ahora sois adultos. No sé cuándo ocurrió.", To = "Yo", If = { Memories = { "PrimerDiaCole" } } },
			},
		},
		Sara = {
			Lines = {
				{ S = "Sara", T = "¡{nombre}! Espera. No toques eso. Ahora sí.", To = "Yo", A = "Happy" },
				{ S = "Sara", T = "He descubierto una especie nueva de hongo.", To = "Yo" },
				{ S = "Sara", T = "Le han puesto mi nombre. Es diminuto. Pero precioso. ¿Todos?", To = "Yo", Pause = 0.9 },
				{ S = "Yo", T = "Todos los que podamos reunir." },
				{ S = "Sara", T = "Entonces iré. Y él también.", To = "Yo", A = "Nod" },
			},
		},
	},
	Scenes = {
		Adu03_Banco = {
			Skippable = true,
			Duration = 20.2,
			FadeIn = true,
			Anchors = { Sitio = "Place:Parque", Yo = "Player" },
			Tracks = {
				Light = { { At = 0, Fade = 2, Preset = "Noche" } },
				Actors = {
					{ At = 0, Use = { Anchor = "Yo", Key = "Omar", Npc = "Omar", Offset = V(-2, 0, -4) } },
					{ At = 0, Use = { Anchor = "Yo", Key = "Nico", Npc = "Nico", Offset = V(0, 0, -4) } },
					{ At = 0, Use = { Anchor = "Yo", Key = "Sara", Npc = "Sara", Offset = V(2, 0, -4) } },
					{ At = 0, If = { Flags = { "ConocesALeire" } }, Use = { Anchor = "Yo", Key = "Leire", Npc = "Leire", Offset = V(4, 0, -5) } },
					{ At = 0, If = { Flags = { "AyudasteAMateo" } }, Use = { Anchor = "Yo", Key = "Mateo", Npc = "Mateo", Offset = V(-4, 0, -5) } },
					{ At = 0, If = { Flags = { "HugoConElGrupo" } }, Use = { Anchor = "Yo", Key = "Hugo", Npc = "Hugo", Offset = V(5, 0, -3) } },
					{ At = 2.4, Look = { At = "Yo", Key = "Nico" } },
					{ At = 2.6, Gesture = { Key = "Nico", Play = "Wave" } },
					{ At = 2.8, Mood = { Mood = "Joy", Key = "Omar" } },
				},
				Ambience = { { At = 0, Fade = 2, Kind = "Parque" } },
				Camera = { { At = 0, Duration = 3, Shot = "General" } },
				Dialogue = {
					{ At = 0.4, S = "Omar", T = "Apretaos. A los diez años cabíamos todos. Y sobraba bocadillo.", To = "Yo", A = "Shrug" },
					{ At = 5.6, S = "Sara", T = "Técnicamente hemos crecido un cuarenta por ciento. El banco, cero.", To = "Yo", A = "Nod" },
					{ At = 11.1, S = "Leire", T = "Quietos. Esta toma es buena.", To = "Yo", A = "ThinkChin", If = { Flags = { "ConocesALeire" } } },
					{ At = 13.9, S = "Mateo", T = "Yo aquí. Como el primer día.", To = "Yo", A = "ThinkChin", If = { Flags = { "AyudasteAMateo" } } },
					{ At = 16.7, S = "Mateo", T = "Así no se me caen las cosas.", To = "Yo", If = { Flags = { "AyudasteAMateo" } } },
				},
				Music = { { At = 0, Intensity = "Intima" } },
			},
		},
		Adu03_G10 = {
			Skippable = true,
			Duration = 3.5,
			Anchors = { Sitio = "Place:CafeteriaCentral", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Leire", Npc = "Leire" } } },
				Camera = { { At = 0, Duration = 3.5, To = { "Sitio", V(-14, 12, 18) }, Fov = 60, From = { "Sitio", V(-26, 18, 30) }, Look = { "Sitio", V(0, 2, 0) } } },
				Dialogue = { { At = 0.4, S = "Leire", T = "Quietos. Flash.", To = "Yo", A = "ThinkChin", If = { Flags = { "ConocesALeire" } } } },
			},
			Sting = "Momento",
		},
		Adu03_G11_Fin = {
			Light = true,
			Duration = 13.2,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Nico", Npc = "Nico" } },
					{ At = 0, Use = { Key = "Omar", Npc = "Omar" } },
					{ At = 0, Use = { Key = "Sara", Npc = "Sara" } },
				},
				Dialogue = {
					{ At = 0.4, S = "Nico", T = "Parque.", To = "Yo", G = "Point" },
					{ At = 2.9, S = "Omar", T = "Banco.", To = "Yo", A = "HandsOnHips" },
					{ At = 5.4, S = "Sara", T = "Ven.", To = "Yo", A = "Happy", Mood = "Joy" },
					{ At = 7.9, S = "Nico", T = "¡Por fin! Te hemos guardado sitio. Bueno. Medio sitio.", To = "Yo", A = "Happy", Mood = "Joy" },
				},
			},
		},
		Adu03_G1_Fin = {
			Light = true,
			Duration = 12.9,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Omar", Npc = "Omar" } } },
				Dialogue = {
					{ At = 0.4, S = "Omar", T = "Otro mensaje inmediatamente después:", To = "Yo", A = "HandsOnHips" },
					{ At = 3.8, S = "Omar", T = "¿Dónde estás? Esto es importante.", To = "Yo", A = "Ask" },
					{ At = 6.9, S = "Omar", T = "Bueno, para mí es importante.", To = "Yo" },
					{ At = 9.8, S = "Narrador", T = "«OMAR: VEN.»" },
				},
			},
		},
		Adu03_G7_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Omar", Npc = "Omar" } } },
				Dialogue = { { At = 0.4, S = "Omar", T = "¡Has vuelto! Perfecto. No perfecto. Caos. Necesito ayuda.", To = "Yo", A = "Shrug" } },
			},
		},
		Adu03_G8_Entra = {
			Light = true,
			Duration = 10.4,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Omar", Npc = "Omar" } } },
				Dialogue = {
					{ At = 0.4, S = "Omar", T = "Perfecta. Casi me haces sentir inútil. Está bien. Bueno. Está viva. No pasa nada.", To = "Yo", A = "Shrug" },
					{ At = 7, S = "Omar", T = "Nadie tiene por qué saberlo.", To = "Yo" },
				},
			},
		},
	},
	Steps = {
		["1"] = { Effects = { Scene = "Adu03_G1_Fin" } },
		["10"] = { Effects = { Scene = "Adu03_G10" } },
		["11"] = { Effects = { Scene = "Adu03_G11_Fin" } },
		["6"] = { Effects = { Scene = "Adu03_G7_Entra" } },
		["7"] = { Effects = { Scene = "Adu03_G8_Entra" } },
	},
}
