-- GUION REESCRITO de Loco_N1_Cosme (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Loco_N1_Cosme.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Loco_N1_Cosme
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Loco_N1_Cosme.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Loco_N1_Cosme.md",
	Dialogues = {
		Bobina = {
			Lines = {
				{ S = "Narrador", T = "NIÑO: «Esta cosa estaba dentro.»" },
				{ S = "Narrador", T = "NIÑO: «Sabe a martes.»" },
				{ S = "Yo", T = "Te cambio la bobina por mi merienda." },
				{ S = "Narrador", T = "NIÑO: «Trato.» NIÑO: «Pero si vuelve el martes, me avisas.»" },
				{ S = "Yo", T = "Es una pieza del futuro." },
				{ S = "Narrador", T = "NIÑO: «Entonces no quiero tocarla.»" },
				{ S = "Narrador", T = "NIÑO: «¿Me das tu merienda?»", Pause = 0.9 },
				{ S = "Narrador", T = "NIÑO: «Buena decisión.»" },
				{
					Ask = "¿Cómo la consigues?",
					Options = {
						{
							T = "Le cambias la bobina por tu merienda",
							Effects = { Traits = { Empatia = 1 } },
							Then = { { S = "Narrador", T = "Trato hecho. El niño te mira muy serio y dice: «El martes vuelve». Vale." } },
						},
						{
							T = "Le dices que es un helado del futuro y que ya ha caducado",
							Effects = { Traits = { Humor = 1 } },
							Then = { { S = "Narrador", T = "Te la da con cara de asco. Técnicamente no mentías: viene del pasado. Casi." } },
						},
					},
				},
			},
		},
		Chip = {
			Lines = {
				{ S = "Bigotes", T = "Cría humana. Tenemos un problema. Tú necesitas eso.", To = "Yo" },
				{ S = "Bigotes", T = "Y yo necesito que no hagas preguntas.", To = "Yo" },
				{ S = "Yo", T = "¿Hablas?", Pause = 0.9 },
				{ S = "Bigotes", T = "No. Tú tampoco has oído nada.", To = "Yo" },
				{ S = "Bigotes", T = "Y esto nunca ha pasado.", To = "Yo" },
				{ S = "Bigotes", T = "Y no se lo cuentes a nadie.", To = "Yo" },
				{ S = "Bigotes", T = "Especialmente a los humanos.", To = "Yo", Pause = 0.9 },
			},
		},
		Presentacion = {
			Lines = {
				{ S = "Cosme", T = "¡No! ¡No, no, no! ¡He dicho que no explotes!", To = "Yo", Effects = { Scene = "Loco_N1_G1_Musica" } },
				{ S = "Cosme", T = "¡Eso iba por ti, bobina!", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "Ah. Tú. Esto no es lo que parece.", To = "Yo", Shot = "Medio:Cosme" },
				{ S = "Cosme", T = "Bueno. Es exactamente lo que parece.", To = "Yo" },
				{ S = "Cosme", T = "¡Cof! ¡Cof! Hola, criatura.", To = "Yo" },
				{ S = "Cosme", T = "No te asustes. El humo verde es normal. El morado no.", To = "Yo" },
				{ S = "Cosme", T = "Si alguna vez ves humo morado, te vas. Sin correr.", To = "Yo" },
				{ S = "Cosme", T = "Bueno. Corriendo también vale.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "Soy Cosme. Inventor. Genio. Vecino. En ese orden. ¿Qué? Nada.", To = "Yo" },
				{ S = "Yo", T = "¿Qué ha explotado?" },
				{ S = "Cosme", T = "Mi microondas temporal.", To = "Yo" },
				{ S = "Cosme", T = "Calienta la comida en el pasado.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "Así está caliente antes de que tengas hambre.", To = "Yo" },
				{ S = "Cosme", T = "Funcionaba perfectamente.", To = "Yo" },
				{ S = "Cosme", T = "Durante unos ocho segundos.", To = "Yo" },
				{ S = "Cosme", T = "Han salido volando tres piezas. El tornillo cuántico.", To = "Yo" },
				{ S = "Cosme", T = "La bobina de gominola.", To = "Yo" },
				{ S = "Cosme", T = "Y el chip de mi abuela.", To = "Yo" },
				{ S = "Cosme", T = "No preguntes por el chip. Es complicado.", To = "Yo" },
				{ S = "Cosme", T = "Y ligeramente ilegal en tres dimensiones.", To = "Yo" },
				{
					Ask = "¿Qué le dices?",
					Options = {
						{
							T = "«¡Te ayudo a buscarlas!»",
							Effects = { Rel = { Cosme = 5 }, Traits = { Valentia = 1 } },
							Then = {
								{ S = "Cosme", T = "¿Ayudar? ¿Sin pedir nada? Me caes bien.", To = "Yo" },
								{ S = "Cosme", T = "Tú buscas. Yo superviso.", To = "Yo" },
								{ S = "Cosme", T = "Desde una distancia prudente.", To = "Yo", Pause = 0.9 },
							},
						},
						{
							T = "«¿El chip de tu abuela?»",
							Effects = { Rel = { Cosme = 3 }, Traits = { Curiosidad = 1 } },
							Then = {
								{ S = "Cosme", T = "Mi abuela era especial. Muy especial.", To = "Yo" },
								{ S = "Cosme", T = "Y tenía mejores cálculos que yo. No hablemos de eso.", To = "Yo", Pause = 0.9 },
								{ S = "Cosme", T = "Busca las piezas, criatura.", To = "Yo" },
							},
						},
					},
				},
			},
		},
		Prueba = {
			Lines = {
				{ S = "Cosme", T = "Tornillo. Bobina. Chip.", To = "Yo", Effects = { Scene = "Loco_N1_G4_Musica" } },
				{ S = "Cosme", T = "Por favor, no seas el de mi abuela. ¡Ha funcionado!", To = "Yo", Pause = 0.9 },
				{ S = "Yo", T = "¿Qué pasa?" },
				{ S = "Cosme", T = "Alguien ha mordido mi bocadillo. En el pasado. Espera. Fui yo. El martes pasado.", To = "Yo" },
				{ S = "Cosme", T = "Ya decía yo que aquel día tenía hambre. Toma.", To = "Yo" },
				{ S = "Cosme", T = "Iba a ser un desintegrador de materia.", To = "Yo" },
				{ S = "Cosme", T = "Es una pistola de burbujas.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "Técnicamente, son burbujas cuánticas. Creo. Una cosa.", To = "Yo" },
				{ S = "Cosme", T = "Lo que has visto aquí…", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "No se lo cuentes a nadie.", To = "Yo" },
				{
					Ask = "Cosme te mira seriamente. ¿Qué haces?",
					Options = {
						{
							T = "«Será nuestro secreto.»",
							Effects = { Flags = { "SecretoCosme", "GrietaVista" }, Rel = { Cosme = 5 }, Scene = "Grieta_Rasguno" },
							Then = {
								{ S = "Cosme", T = "Buena criatura. Los secretos son como los tornillos.", To = "Yo" },
								{ S = "Cosme", T = "Si pierdes uno, todo empieza a temblar. Qué frase tan buena. Me la apunto.", To = "Yo", Pause = 0.9 },
							},
						},
						{
							T = "«Se lo voy a contar a mi familia. Todo.»",
							Effects = { Flags = { "GrietaVista" }, Scene = "Grieta_Rasguno", Traits = { Responsabilidad = 1 } },
							Then = { { S = "Cosme", T = "Hazlo. No te creerán. Y eso es precisamente lo que me preocupa.", To = "Yo" } },
						},
					},
				},
				{ S = "Cosme", T = "¿Dónde has encontrado eso?", To = "Yo", Pause = 1.5 },
				{ S = "Yo", T = "Estaba junto a la fuente." },
				{ S = "Cosme", T = "No. Eso no puede estar aquí.", To = "Yo" },
				{ S = "Yo", T = "Lo tenía desde antes." },
				{ S = "Cosme", T = "¿Desde cuándo? ¿Antes de conocerme? No lo pierdas. Y, pase lo que pase…", To = "Yo" },
				{ S = "Cosme", T = "No dejes que nadie te lo quite. No… Vete a casa. Mañana hablamos. Mañana… Hablamos.", To = "Yo" },
			},
		},
		Tornillo = {
			Lines = { { S = "Narrador", T = "Durante un segundo, Valmar parece otro lugar. Parpadeas." }, { S = "Narrador", T = "Y todo vuelve a ser normal." } },
		},
	},
	Scenes = {
		Loco_N1_G1_Musica = { Light = true, Duration = 69.2, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Loco_N1_G3_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Cosme", Npc = "Cosme" } } },
				Dialogue = { { At = 0.4, S = "Cosme", T = "Si el tornillo ha vuelto a aparecer… No. ¡Criatura! ¡Perfecto! Justo a tiempo.", To = "Yo" } },
			},
		},
		Loco_N1_G4_Musica = {
			Light = true,
			Duration = 61,
			Anchors = { Yo = "Player" },
			Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" }, { At = 30.5, Intensity = "Tension" } } },
		},
	},
	Steps = {
		["2"] = { Effects = { Scene = "Loco_N1_G3_Entra" } },
		["2.1"] = { Set = { Text = "Busca el tornillo cerca de la fuente del parque." } },
		["2.2"] = { Set = { Text = "Recupera la bobina en la heladería." } },
		["2.3"] = { Set = { Text = "Busca el chip. Bigotes lo tiene." } },
		["3"] = { Set = { Text = "Lleva las tres piezas a Cosme." } },
	},
}
