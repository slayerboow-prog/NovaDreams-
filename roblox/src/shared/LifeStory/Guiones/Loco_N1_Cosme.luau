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
				{ S = "Narrador", T = "NIÑO: «Vengo del Sur. Mis padres no salieron. Vendo lo que encuentro para comer.»" },
				{ S = "Yo", T = "Te la cambio por mi comida de hoy." },
				{ S = "Narrador", T = "NIÑO: «Vale.» NIÑO: «Si un día vais al Sur, mirad en la calle del molino. Era la mía.»" },
				{ S = "Yo", T = "Eso viene de la Grieta. Puede hacerte daño." },
				{ S = "Narrador", T = "NIÑO: «Todo hace daño.»" },
				{ S = "Narrador", T = "NIÑO: «Dame algo a cambio y es tuya.»" },
				{ S = "Narrador", T = "NIÑO: «Gracias. Supongo.»" },
				{
					Ask = "¿Cómo la consigues?",
					Options = {
						{
							T = "Le das tu comida de hoy a cambio",
							Effects = { Traits = { Empatia = 1 } },
							Then = { { S = "Narrador", T = "Te la da sin decir nada. Antes de irse: «Si vais al Sur, mirad en la calle del molino. Era la mía»." } },
						},
						{
							T = "Le avisas de que viene de la Grieta y es peligrosa",
							Effects = { Traits = { Responsabilidad = 1 } },
							Then = { { S = "Narrador", T = "«Todo es peligroso», dice. Te la cambia por lo que llevas encima." } },
						},
					},
				},
			},
		},
		Chip = {
			Lines = {
				{ S = "Bigotes", T = "No grites. Nadie más puede oírme. Hablo dentro de tu cabeza.", To = "Yo" },
				{ S = "Bigotes", T = "Este cuerpo era de un gato. Ahora es mío. Crucé la Grieta hace dos años, igual que las bestias.", To = "Yo" },
				{ S = "Yo", T = "¿Eres una de ellas?" },
				{ S = "Bigotes", T = "No. Yo huía de lo mismo que las empujó a ellas.", To = "Yo" },
				{ S = "Bigotes", T = "Llévale esto a Cosme. Y no le digas a nadie que hablo. A los que lo dijeron los encerraron.", To = "Yo" },
			},
		},
		Presentacion = {
			Lines = {
				{ S = "Cosme", T = "Tú eres la persona de Kael.", To = "Yo", Shot = "Medio:Cosme", Effects = { Scene = "Loco_N1_G1_Musica" } },
				{ S = "Cosme", T = "Llegas tarde. Hace diez minutos todavía tenía un detector.", To = "Yo" },
				{ S = "Cosme", T = "Respira por la boca. El humo verde es ozono. Molesta, pero no mata.", To = "Yo" },
				{ S = "Cosme", T = "Si alguna vez ves humo morado aquí dentro, sal y no vuelvas.", To = "Yo" },
				{
					S = "Cosme",
					T = "Soy Cosme. Antes investigaba la Grieta para la Academia. Ahora lo hago en un garaje, sin permiso y sin presupuesto.",
					To = "Yo",
				},
				{ S = "Cosme", T = "Dije que la Caída no había sido un accidente. Me echaron por decirlo en voz alta.", To = "Yo" },
				{ S = "Yo", T = "¿Qué ha explotado?" },
				{ S = "Cosme", T = "Un detector de resonancia. Mide lo que se filtra por la Grieta antes de que se abra del todo.", To = "Yo" },
				{ S = "Cosme", T = "Esta noche la lectura se ha disparado. El aparato no lo ha aguantado.", To = "Yo" },
				{ S = "Cosme", T = "Han salido despedidas tres piezas: el núcleo, la bobina de inducción y un chip que no debería tener.", To = "Yo" },
				{ S = "Cosme", T = "No preguntes por el chip. Lo saqué de los restos de un laboratorio del Sur después de la Caída.", To = "Yo" },
				{
					Ask = "¿Qué le dices?",
					Options = {
						{
							T = "«Te ayudo a recuperarlas.»",
							Effects = { Rel = { Cosme = 5 }, Traits = { Valentia = 1 } },
							Then = {
								{ S = "Cosme", T = "Kael dijo que no hacías preguntas antes de actuar. Ya veo.", To = "Yo" },
								{ S = "Cosme", T = "Toma este rastreador. Pita cerca de cualquier cosa que haya tocado la Grieta.", To = "Yo" },
							},
						},
						{
							T = "«¿De quién era ese laboratorio?»",
							Effects = { Rel = { Cosme = 3 }, Traits = { Curiosidad = 1 } },
							Then = {
								{ S = "Cosme", T = "De mi hermana. Ella midió la Grieta antes que nadie.", To = "Yo" },
								{ S = "Cosme", T = "La noche de la Caída estaba allí. No la encontraron.", To = "Yo" },
								{ S = "Cosme", T = "Busca las piezas. Luego, si quieres, hablamos de lo demás.", To = "Yo" },
							},
						},
					},
				},
			},
		},
		Prueba = {
			Lines = {
				{ S = "Cosme", T = "Núcleo. Bobina. Chip. Funciona.", To = "Yo", A = "Lean", Effects = { Scene = "Loco_N1_G4_Musica" } },
				{ S = "Narrador", T = "La pantalla se llena de líneas. Todas apuntan al mismo sitio: el cielo, sobre el Distrito Central." },
				{ S = "Yo", T = "¿Qué significa eso?" },
				{ S = "Cosme", T = "Que la Grieta no se cerró después de la Caída. Solo se calmó.", To = "Yo", A = "HandsOnHips" },
				{ S = "Cosme", T = "Y que se está despertando otra vez.", To = "Yo" },
				{ S = "Cosme", T = "Toma. Un prototipo. Lanza esferas de campo inestable.", To = "Yo" },
				{ S = "Cosme", T = "Atraviesan la materia normal. Lo que viene de la Grieta, no. Te servirá para saber qué es qué.", To = "Yo" },
				{ S = "Cosme", T = "Una cosa más.", To = "Yo" },
				{ S = "Cosme", T = "Si la Academia se entera de que trabajas conmigo, te quitarán el rango. Kael lo sabe y aun así te ha enviado.", To = "Yo" },
				{
					Ask = "Cosme te mira seriamente. ¿Qué haces?",
					Options = {
						{
							T = "«Queda entre nosotros.»",
							Effects = { Flags = { "SecretoCosme", "GrietaVista" }, Rel = { Cosme = 5 }, Scene = "Grieta_Rasguno" },
							Then = {
								{ S = "Cosme", T = "Gracias. Hace mucho que nadie confía en mí.", To = "Yo" },
								{ S = "Cosme", T = "Ven. Quiero que veas algo.", To = "Yo" },
							},
						},
						{
							T = "«Informaré a la Academia. Si tienes razón, tienen que saberlo.»",
							Effects = { Flags = { "GrietaVista" }, Scene = "Grieta_Rasguno", Traits = { Responsabilidad = 1 } },
							Then = {
								{ S = "Cosme", T = "Hazlo. Ya lo intenté yo.", To = "Yo" },
								{ S = "Cosme", T = "No te creerán. Y eso es lo que más me preocupa.", To = "Yo" },
							},
						},
					},
				},
				{ S = "Cosme", T = "El núcleo brilla en tu mano. Con la mía no lo hace. Con la de nadie lo ha hecho nunca.", To = "Yo" },
				{ S = "Cosme", T = "Eso no debería ser posible.", To = "Yo", A = "No" },
				{ S = "Cosme", T = "¿Dónde estabas la noche de la Caída?", To = "Yo", A = "Ask" },
				{ S = "Cosme", T = "No contestes ahora. Guárdalo. Y no dejes que nadie te lo quite. No…", To = "Yo" },
				{ S = "Narrador", T = "La Grieta se abre un palmo más. Un sonido grave, lejano, como algo enorme respirando al otro lado." },
				{ S = "Cosme", T = "Vete a descansar. Mañana empezamos de verdad. Mañana… Hablamos.", To = "Yo" },
				{ S = "Cosme", T = "Solo estaba esperando.", To = "Yo" },
			},
		},
		Tornillo = {
			Lines = {
				{ S = "Narrador", T = "Al tocarlo, el parque se apaga durante un segundo. Los árboles están secos. Las farolas, rotas. Huele a quemado." },
				{ S = "Narrador", T = "Es el Sur la noche de la Caída. Lo sabes sin haberlo visto nunca." },
				{ S = "Narrador", T = "Parpadeas. El parque vuelve a estar ahí." },
			},
		},
	},
	Scenes = {
		Loco_N1_G1_Musica = { Light = true, Duration = 67.1, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Loco_N1_G3_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Cosme", Npc = "Cosme" } } },
				Dialogue = { { At = 0.4, S = "Cosme", T = "Ya estás aquí. Bien. Déjalas en la mesa.", To = "Yo" } },
			},
		},
		Loco_N1_G4_Musica = {
			Light = true,
			Duration = 81.2,
			Anchors = { Yo = "Player" },
			Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" }, { At = 40.6, Intensity = "Tension" } } },
		},
	},
	Steps = {
		["2"] = { Effects = { Scene = "Loco_N1_G3_Entra" } },
		["2.1"] = { Set = { Text = "Busca el núcleo del detector cerca de la fuente del parque" } },
		["2.2"] = { Set = { Text = "La bobina ha caído en la heladería del centro. Alguien la ha cogido" } },
		["2.3"] = { Set = { Text = "Busca el chip. Lo tiene un gato callejero cerca de la Academia" } },
		["3"] = { Set = { Text = "Lleva las tres piezas a Cosme" } },
	},
}
