-- GUION REESCRITO de Adu02_Atardecer (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Adu02_Atardecer.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Adu02_Atardecer
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Adu02_Atardecer.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Adu02_Atardecer.md",
	Dialogues = {
		Autobus = {
			Lines = {
				{ S = "Abu", T = "Pensaba que llegarías tarde.", To = "Yo" },
				{ S = "Yo", T = "Llevo cinco minutos aquí." },
				{ S = "Abu", T = "Entonces has aprendido.", To = "Yo" },
				{ S = "Abu", T = "Yo cogía este cuando tenía tu edad.", To = "Yo" },
				{ S = "Yo", T = "¿El mismo?" },
				{ S = "Abu", T = "No creo.", To = "Yo" },
				{ S = "Abu", T = "Pero espero que tenga los mismos recuerdos.", To = "Yo", Pause = 0.9 },
			},
		},
		Coche = { Lines = { { S = "Yo", T = "¿Son las del coche?" } } },
		Concha = {
			Lines = {
				{ S = "Yo", T = "Toma." },
				{ S = "Abu", T = "No.", To = "Yo" },
				{ S = "Abu", T = "Es para ti.", To = "Yo" },
				{ S = "Yo", T = "¿Por qué?" },
				{ S = "Abu", T = "Para que vuelvas.", To = "Yo" },
				{ S = "Abu", T = "Siempre hace falta un motivo para volver.", To = "Yo", Pause = 0.9 },
			},
		},
		Hospital = {
			Lines = {
				{ S = "Abu", T = "Así que ya tienes trabajo.", To = "Yo" },
				{ S = "Yo", T = "Sí." },
				{ S = "Abu", T = "Y casa.", To = "Yo" },
				{ S = "Yo", T = "Más o menos." },
				{ S = "Abu", T = "Ya no eres {un niño/una niña}.", To = "Yo" },
				{ S = "Abu", T = "Aunque para mí…", To = "Yo", Pause = 0.9 },
				{ S = "Abu", T = "Siempre tendrás un poco de eso.", To = "Yo" },
				{ S = "Abu", T = "¿Y tú querías acabar como Nuria?", To = "Yo", If = { Choices = { Estudios = "Medicina" } } },
				{ S = "Abu", T = "¿Así que finalmente encontraste tu camino?", To = "Yo", If = { NotChoices = { Estudios = "Medicina" } } },
				{ S = "Abu", T = "¿Sigues llevando el reloj?", To = "Yo", If = { Memories = { "PrimerDiaUni" } } },
				{ S = "Abu", T = "Hace mucho que no veo el mar.", To = "Yo" },
				{ S = "Abu", T = "Quiero volver.", To = "Yo", Pause = 0.9 },
				{ S = "Abu", T = "Contigo.", To = "Yo" },
				{
					Ask = "¿Qué le dices?",
					Options = {
						{
							T = "«En cuanto salgas de aquí, vamos. Te lo prometo.»",
							Effects = { Rel = { Abu = 8 } },
							Then = { { S = "Abu", T = "Trato hecho. Y no me lleves corriendo, que ya no estoy para sustos." } },
						},
						{
							T = "Le coges la mano sin decir nada",
							Effects = { Rel = { Abu = 10 }, Traits = { Empatia = 1 } },
							Then = { { S = "Abu", T = "Ya. Ya lo sé. Tú siempre has dicho las cosas así.", A = "Happy", Beat = "Mira" } },
						},
					},
				},
			},
		},
		Llamada = {
			Lines = {
				{ S = "Yo", T = "Sí. ¿Qué pasa?" },
				{ S = "Yo", T = "¿Qué le ha pasado?" },
				{ S = "Yo", T = "¿Dónde está?", Pause = 0.9 },
				{ S = "Yo", T = "Voy para allá." },
				{ S = "Yo", T = "¿Su planta?" },
				{ S = "Yo", T = "Voy." },
			},
		},
		Mar = {
			Lines = {
				{ S = "Abu", T = "Aquí conocí a la persona más importante de mi vida.", To = "Yo" },
				{ S = "Yo", T = "¿Mamá/Papá?" },
				{ S = "Abu", T = "No.", To = "Yo" },
				{ S = "Abu", T = "Tú.", To = "Yo", Pause = 0.9 },
				{ S = "Abu", T = "Cuando naciste vine aquí.", To = "Yo" },
				{ S = "Abu", T = "Necesitaba pensar.", To = "Yo" },
				{ S = "Abu", T = "Y pensé que algún día te traería.", To = "Yo", Pause = 0.9 },
				{ S = "Abu", T = "Mira.", To = "Yo" },
				{ S = "Abu", T = "Ya has llegado.", To = "Yo" },
			},
		},
		Promesa = {
			Effects = { Choice = { PromesaAbu = "Familia" } },
			Lines = {
				{ S = "Abu", T = "Prométeme una cosa.", To = "Yo" },
				{ S = "Yo", T = "La que quieras." },
				{ S = "Abu", T = "No.", To = "Yo" },
				{ S = "Abu", T = "Una que puedas cumplir.", To = "Yo" },
				{ S = "Abu", T = "Aparecen las tres opciones.", To = "Yo" },
				{ S = "Yo", T = "Volver cada año." },
				{ S = "Abu", T = "Entonces aquí te esperaré.", To = "Yo" },
				{ S = "Yo", T = "Hacer cosas bonitas con tu vida." },
				{ S = "Abu", T = "Eso es mucho más difícil.", To = "Yo" },
				{ S = "Abu", T = "Por eso me gusta.", To = "Yo", Pause = 0.9 },
				{ S = "Yo", T = "Cuidar de la familia." },
				{ S = "Abu", T = "Eso nunca pasa de moda.", To = "Yo" },
				{
					Ask = "¿Qué le prometes?",
					Options = {
						{
							T = "«Volveré aquí cada año. Contigo o por ti.»",
							Effects = { Choice = { PromesaAbu = "Volver" }, Rel = { Abu = 6 } },
							Then = { { S = "Abu", T = "Cada año. Me vale. Y si un año no puedo venir, tráeme una foto." } },
						},
						{
							T = "«Haré cosas bonitas. Como dijiste.»",
							Effects = { Choice = { PromesaAbu = "CosasBonitas" }, Traits = { Valentia = 1 } },
							Then = { { S = "Abu", T = "Ya las haces. Pero haz más. Muchas. Y que se note que eres feliz haciéndolas." } },
						},
						{
							T = "«Cuidaré de la familia como tú cuidaste de mí.»",
							Effects = { Choice = { PromesaAbu = "Familia" }, Rel = { Familia = 5 }, Traits = { Responsabilidad = 1 } },
							Then = { { S = "Abu", T = "Eso ya lo sé. Lo sé desde que me diste la mitad de tu bocadillo con cinco años." } },
						},
					},
				},
			},
		},
	},
	Scenes = {
		Adu02_G11_Entra = {
			Light = true,
			Duration = 10.6,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Abu", Npc = "Abu" } } },
				Dialogue = {
					{ At = 0.4, S = "Abu", T = "Ahí conocí a tu madre/padre.", To = "Yo" },
					{ At = 3.1, S = "Abu", T = "Dependiendo de los datos de la historia.", To = "Yo" },
					{ At = 7.3, S = "Abu", T = "Pero eso es otra historia.", To = "Yo" },
				},
			},
		},
		Adu02_G17 = {
			Skippable = true,
			Duration = 18,
			Anchors = { Sitio = "Place:Playa", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Abu", Npc = "Abu" } } },
				Camera = { { At = 0, Duration = 18, To = { "Sitio", V(-14, 12, 18) }, Fov = 60, From = { "Sitio", V(-26, 18, 30) }, Look = { "Sitio", V(0, 2, 0) } } },
				Dialogue = {
					{ At = 0.4, S = "Abu", T = "¿Sabes qué es lo malo de hacerse mayor?", To = "Yo" },
					{ At = 4.6, S = "Yo", T = "¿Qué?" },
					{ At = 6.6, S = "Abu", T = "Que uno empieza a entender lo rápido que pasa todo.", To = "Yo" },
					{ At = 11.5, S = "Abu", T = "Por eso hay que estar presente.", To = "Yo" },
					{ At = 15.3, S = "Abu", T = "Mientras estás.", To = "Yo" },
				},
			},
			Music = "TemaValmar",
			Sting = "Momento",
		},
		Adu02_Hospital = {
			Skippable = true,
			Duration = 43.2,
			FadeIn = true,
			Anchors = { Sitio = "Place:Hospital", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Anchor = "Yo", Key = "Abu", Npc = "Abu", Offset = V(0, 0, -5) } },
					{ At = 0, Use = { Anchor = "Yo", Key = "Nuria", Npc = "Nuria", Offset = V(3, 0, -4) } },
					{ At = 0, Use = { Anchor = "Yo", Key = "Familia", Npc = "Familia", Offset = V(-3, 0, -4) } },
					{ At = 0.1, Look = { At = "Away", Key = "Abu" } },
					{ At = 0.1, Look = { At = "Suelo", Key = "Nuria" } },
					{ At = 0.2, Mood = { Mood = "Sad", Key = "Abu" } },
					{ At = 1.4, Look = { At = "Yo", Key = "Familia" } },
					{ At = 1.6, Mood = { Mood = "Nervous", Key = "Familia" } },
					{ At = 2.2, Gesture = { Key = "Familia", Play = "Wave" } },
					{ At = 9, Look = { At = "Yo", Key = "Abu" } },
					{ At = 9.3, Mood = { Mood = "Joy", Key = "Abu" } },
				},
				Ambience = { { At = 0, Fade = 1.5, Kind = "Hospital" } },
				Camera = { { At = 0, Duration = 2.8, Shot = "General" } },
				Dialogue = {
					{ At = 0.4, S = "Nuria", T = "Llegas rápido.", To = "Yo" },
					{ At = 2.4, S = "Yo", T = "¿Cómo está?" },
					{ At = 4.5, S = "Nuria", T = "Asustad{o/a}. Pero entero.", To = "Yo" },
					{ At = 7.1, S = "Nuria", T = "Y preocupado por una planta.", To = "Yo" },
					{ At = 9.8, S = "Abu", T = "Mira quién ha venido.", To = "Yo" },
					{ At = 12.1, S = "Yo", T = "¿Estás bien?" },
					{ At = 14.1, S = "Abu", T = "Mejor que la planta.", To = "Yo" },
					{ At = 17.3, S = "Abu", T = "Ella sí que no sabe defenderse sola.", To = "Yo" },
					{ At = 20.4, S = "Nuria", T = "No hay nada roto.", To = "Yo" },
					{ At = 22.5, S = "Abu", T = "Te lo dije.", To = "Yo" },
					{ At = 24.5, S = "Nuria", T = "Te has caído por las escaleras.", To = "Yo" },
					{ At = 27.4, S = "Abu", T = "Las escaleras también tienen la culpa.", To = "Yo" },
					{ At = 30.6, S = "Nuria", T = "Necesita descansar.", To = "Yo" },
					{ At = 32.8, S = "Abu", T = "Eso llevo haciendo toda la mañana.", To = "Yo" },
					{ At = 35.9, S = "Nuria", T = "Llevas intentando levantarte tres veces.", To = "Yo" },
					{ At = 40.1, S = "Abu", T = "Bueno… descansaré mejor.", To = "Yo" },
				},
				Music = { { At = 0, Intensity = "Intima" } },
			},
		},
		Adu02_Orilla = {
			Skippable = true,
			Duration = 12.7,
			FadeIn = true,
			Anchors = { Sitio = "Place:Playa", Yo = "Player" },
			Tracks = {
				Light = { { At = 0, Fade = 4, Preset = "Atardecer", Weight = 0.6 } },
				Actors = {
					{ At = 0, Use = { Anchor = "Yo", Key = "Abu", Npc = "Abu", Offset = V(0, 0, -3) } },
					{ At = 0.1, Look = { At = "Away", Key = "Abu" } },
					{ At = 0.2, Mood = { Mood = "Calm", Key = "Abu" } },
				},
				Ambience = { { At = 0, Fade = 2.5, Kind = "Playa" } },
				Camera = { { At = 0, Duration = 3.2, Shot = "Pan:Abu" } },
				Dialogue = {
					{ At = 0.4, S = "Abu", T = "Huele igual.", To = "Yo" },
					{ At = 2.4, S = "Abu", T = "Aunque supongo que soy yo el que ha cambiado.", To = "Yo" },
					{ At = 6.1, S = "Abu", T = "Gracias.", To = "Yo" },
					{ At = 9, S = "Abu", T = "Ahora eres tú quien me ayuda a mí.", To = "Yo" },
				},
				Music = { { At = 0, Intensity = "Intima" } },
			},
		},
	},
	Steps = { ["10"] = { Effects = { Scene = "Adu02_G11_Entra" } }, ["17"] = { Effects = { Scene = "Adu02_G17" } } },
}
