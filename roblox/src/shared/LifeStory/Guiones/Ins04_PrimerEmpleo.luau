-- GUION REESCRITO de Ins04_PrimerEmpleo (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Ins04_PrimerEmpleo.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Ins04_PrimerEmpleo
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Ins04_PrimerEmpleo.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Ins04_PrimerEmpleo.md",
	Dialogues = {
		Cena = {
			Lines = {
				{
					S = "Familia",
					T = "¿Que nos invitas a cenar? No hacía falta… Pero ya que insistes, yo quiero postre.",
					If = { Choices = { Sueldo = "Familia" } },
				},
				{
					S = "Familia",
					T = "Y oye: lo de la entrevista… ¿dijiste la verdad? Porque las mentiras en el trabajo tienen patas muy cortas.",
					If = { Flags = { "MentisteEntrevista" } },
				},
				{ S = "Familia", T = "¿Eso es…?", To = "Yo", Effects = { Scene = "Ins04_G13_14_15_16_Musica" } },
				{ S = "Familia", T = "Tu primer sueldo.", To = "Yo", Pause = 0.9 },
				{ S = "Familia", T = "No pregunta cuánto.", To = "Yo" },
				{ S = "Abu", T = "Ahora ya sabes cuánto vale una hora.", To = "Yo" },
				{ S = "Abu", T = "Pero todavía te falta descubrir cuánto vale tu tiempo.", To = "Yo", Pause = 0.9 },
				{ S = "Yo", T = "Guardar el dinero." },
				{ S = "Yo", T = "Comprar algo que llevas tiempo queriendo." },
				{ S = "Yo", T = "Invitar a la familia a algo." },
				{ S = "Yo", T = "Ayudar con un gasto de casa." },
				{
					S = "Rayo",
					T = "Tengo otra oportunidad de ganar dinero.",
					To = "Yo",
					If = { Completed = { "Pan1_MalasCompanias" }, Flags = { "Camino_Delincuente" } },
				},
				{ S = "Nerea", T = "¿Te ha gustado trabajar?", To = "Yo", If = { Completed = { "Pan1_MalasCompanias" }, Flags = { "Camino_Trabajador" } } },
				{ S = "Rayo", T = "Tobías me ha hecho desmontar un motor.", To = "Yo", If = { Completed = { "Pan1_MalasCompanias" }, Flags = { "RayoCambia" } } },
				{ S = "Narrador", T = "Segundo mensaje: «Creo que me gusta.»", If = { Flags = { "RayoCambia" } } },
				{ S = "Leire", T = "Toni dice que tienes buen ojo.", To = "Yo", If = { Flags = { "Interes_Audiovisual", "ConocesALeire" } } },
				{ S = "Familia", T = "Quemaste tres tostadas el primer día.", To = "Yo", Shot = "PPP:Yo", If = { Choices = { Empleo = "Barista" } } },
				{ S = "Familia", T = "Estas referencias hacen que el mundo tenga memoria.", To = "Yo", If = { Choices = { Empleo = "Barista" } } },
				{ S = "Narrador", T = "Biografía desbloqueada: «Mi primer sueldo»" },
			},
		},
		Deseo = {
			Lines = {
				{ S = "Carmen", T = "¿Sigues buscando algo para este verano?", To = "Yo" },
				{ S = "Narrador", T = "Segundo mensaje: «Tobías / Lola / Marcos conocen algunos trabajos para estudiantes.»" },
				{
					Ask = "¿Qué quieres conseguir este verano?",
					Options = {
						{ T = "Una bici de verdad, para ir a todas partes", Effects = { Choice = { Meta = "Bici" } } },
						{ T = "Una cámara, como la de Leire", Effects = { Choice = { Meta = "Camara" } } },
						{
							T = "Ayudar en casa: las cosas están caras",
							Effects = { Choice = { Meta = "Casa" }, Rel = { Familia = 4 }, Traits = { Responsabilidad = 1 } },
						},
						{ T = "Ahorrar para cuando vaya a la universidad", Effects = { Choice = { Meta = "Ahorro" }, Traits = { Responsabilidad = 1 } } },
					},
				},
			},
		},
		Imprevisto = {
			Lines = {
				{ S = "Narrador", T = "¡CRASH! Se te cae una bandeja entera. Y el cliente de la mesa es… Bruno.", If = { Choices = { Empleo = "Barista" } } },
				{
					S = "Bruno",
					T = "¿Tú? ¿Aquí? Jajaja. No, espera. No me río. Bueno, un poco. ¿Te ayudo a recoger?",
					If = { Choices = { Empleo = "Barista" } },
				},
				{
					S = "Narrador",
					T = "Al colocar una caja, la torre de latas de arriba se tambalea… y cae. Treinta latas rodando por el pasillo.",
					If = { Choices = { Empleo = "Reponedor" } },
				},
				{ S = "Narrador", T = "Un paquete pone «Leire». Llamas al timbre. Abre Leire, en pijama.", If = { Choices = { Empleo = "Repartidor" } } },
				{
					S = "Leire",
					T = "…No has visto nada. No me has visto en pijama. Dame el paquete. Es una lente nueva. Gracias. Adiós.",
					If = { Choices = { Empleo = "Repartidor" } },
				},
				{ S = "Narrador", T = "Compañero: «¿Primer trabajo?»" },
				{ S = "Narrador", T = "Compañero: «Se nota.»" },
				{ S = "Narrador", T = "Compañero: «Yo también era un desastre.»", Pause = 0.9 },
				{ S = "Nerea", T = "¿Cómo va tu primer día?", To = "Yo", If = { Completed = { "Pan1_MalasCompanias" } } },
				{ S = "Nerea", T = "No te olvides de descansar.", To = "Yo", If = { Completed = { "Pan1_MalasCompanias" }, Flags = { "AmigaNerea" } } },
				{
					S = "Nerea",
					T = "Rayo dice que Tobías le ha hecho limpiar media vida.",
					To = "Yo",
					If = { Completed = { "Pan1_MalasCompanias" }, Flags = { "RayoCambia" } },
				},
				{ S = "Nerea", T = "¿Sigues con Rayo?", To = "Yo", If = { Completed = { "Pan1_MalasCompanias" }, Flags = { "Camino_Delincuente" } } },
				{
					Ask = "¿Qué haces?",
					Options = {
						{
							T = "Lo cuentas tal cual a tu jefe y lo arreglas",
							Effects = { Flags = { "BuenTrabajo" }, Traits = { Responsabilidad = 1 } },
							Then = {
								{ S = "Lola", T = "Se cae todo el mundo. Lo importante es que me lo digas. Recoge y sigue.", If = { Choices = { Empleo = "Barista" } } },
								{
									S = "Paco",
									T = "Hmm. Treinta latas. Ninguna rota. Y me lo has dicho tú. Bien. Muy bien, incluso.",
									If = { Choices = { Empleo = "Reponedor" } },
								},
								{
									S = "Ernesto",
									T = "¿Que la del paquete era una amiga? Pues entrega perfecta y discreta. Así se hace.",
									If = { Choices = { Empleo = "Repartidor" } },
								},
							},
						},
						{
							T = "Te lo tomas con humor y sigues",
							Effects = { Traits = { Humor = 1 } },
							Then = {
								{
									S = "Bruno",
									T = "Esto lo cuento en clase. Es broma. …O no. Te dejo propina. Por el espectáculo.",
									If = { Choices = { Empleo = "Barista" } },
								},
								{
									S = "Narrador",
									T = "Haces una reverencia a los clientes que miran. Alguien aplaude. Paco no.",
									If = { Choices = { Empleo = "Reponedor" } },
								},
								{
									S = "Narrador",
									T = "Le deseas a Leire un buen día «en su precioso pijama de nubes». Te cierra la puerta. Oyes cómo se ríe detrás.",
									If = { Choices = { Empleo = "Repartidor" } },
								},
							},
						},
					},
				},
			},
		},
		Perfil = {
			Lines = {
				{ S = "Carmen", T = "Pasa.", To = "Yo" },
				{ S = "Carmen", T = "¿Trabajo?", To = "Yo", Pause = 0.9 },
				{ S = "Carmen", T = "Tobías sigue preguntando por ti.", To = "Yo", If = { Flags = { "Interes_Oficio" } } },
				{ S = "Carmen", T = "Lola necesita ayuda algunas tardes.", To = "Yo", If = { Flags = { "Interes_Cocina" } } },
				{ S = "Carmen", T = "Toni busca alguien que le ayude con el material.", To = "Yo", If = { Flags = { "Interes_Audiovisual" } } },
				{ S = "Carmen", T = "Irene necesita ayuda durante algunos entrenamientos infantiles.", To = "Yo", If = { Flags = { "Interes_Deporte" } } },
				{ S = "Carmen", T = "Marcos busca ayuda con inventario.", To = "Yo", If = { Flags = { "Interes_Economia" } } },
				{
					S = "Carmen",
					T = "En el centro de salud no puedes trabajar todavía, pero hay un programa de apoyo para actividades comunitarias.",
					To = "Yo",
					If = { Flags = { "Interes_Medicina" } },
				},
				{ S = "Carmen", T = "Sofía puede enseñarte un pequeñ{o/a} proyecto de laboratorio.", To = "Yo", If = { Flags = { "Interes_Ingenieria" } } },
				{ S = "Carmen", T = "Inés conoce un programa juvenil de apoyo comunitario.", To = "Yo", If = { Flags = { "Interes_Derecho" } } },
				{ S = "Carmen", T = "Pero hay una cosa.", To = "Yo" },
				{ S = "Carmen", T = "No quiero que elijas el trabajo que parezca más importante.", To = "Yo", Pause = 0.9 },
				{ S = "Carmen", T = "Elige el que quieras probar.", To = "Yo" },
				{
					Ask = "¿Qué pones como tu punto fuerte?",
					Options = {
						{
							T = "Soy responsable: si digo que voy, voy",
							Effects = { Choice = { Perfil = "Responsable" }, Traits = { Responsabilidad = 1 } },
							Then = { { S = "Carmen", T = "Es lo que más buscan. En serio: más que saber hacer cosas." } },
						},
						{
							T = "Trato bien a la gente",
							Effects = { Choice = { Perfil = "Gente" }, Traits = { Empatia = 1 } },
							Then = { { S = "Carmen", T = "Perfecto para trabajar de cara al público." } },
						},
						{
							T = "Aprendo rápido",
							Effects = { Choice = { Perfil = "Aprendo" }, Traits = { Curiosidad = 1 } },
							Then = { { S = "Carmen", T = "Muy bien. Y ponlo con un ejemplo: tu club, un proyecto…" } },
						},
					},
				},
			},
		},
		PrimerDia = {
			Lines = {
				{
					S = "Lola",
					T = "Llegas tarde el primer día. Hmm. Que no se repita. ¡Delantal!",
					If = { Choices = { Empleo = "Barista" }, Flags = { "LlegasTardeTrabajo" } },
				},
				{
					S = "Paco",
					T = "Las nueve y cuarto. Hmm. En este súper, las nueve son las nueve.",
					If = { Choices = { Empleo = "Reponedor" }, Flags = { "LlegasTardeTrabajo" } },
				},
				{
					S = "Ernesto",
					T = "Los paquetes no esperan, y tú has llegado tarde. Venga, que aún llegamos.",
					If = { Choices = { Empleo = "Repartidor" }, Flags = { "LlegasTardeTrabajo" } },
				},
				{
					S = "Lola",
					T = "¡Puntual! Así me gusta. Mira: cafetera, bandeja, mesas. Café en la mesa que te marque. Sonrisa siempre.",
					If = { Choices = { Empleo = "Barista" }, NotFlags = { "LlegasTardeTrabajo" } },
				},
				{
					S = "Paco",
					T = "Puntual. Hmm. Bien. Almacén, cajas, estanterías. Lo pesado abajo. Ya lo sabes.",
					If = { Choices = { Empleo = "Reponedor" }, NotFlags = { "LlegasTardeTrabajo" } },
				},
				{
					S = "Ernesto",
					T = "¡Puntual! Así da gusto. Recoge los paquetes aquí y llévalos al buzón que te marque el mapa.",
					If = { Choices = { Empleo = "Repartidor" }, NotFlags = { "LlegasTardeTrabajo" } },
				},
				{
					S = "Lola",
					T = "…Y como tienes TANTA experiencia, hoy te las apañas sin explicaciones. ¿No? ¿Seguro?",
					If = { Choices = { Empleo = "Barista" }, Flags = { "MentisteEntrevista" } },
				},
				{
					S = "Paco",
					T = "El que ha trabajado en un súper enorme sabe dónde van las cajas. Adelante. Hmm.",
					If = { Choices = { Empleo = "Reponedor" }, Flags = { "MentisteEntrevista" } },
				},
				{
					S = "Ernesto",
					T = "Ruta difícil para quien tiene muchísima experiencia. Suerte con el perro del 14.",
					If = { Choices = { Empleo = "Repartidor" }, Flags = { "MentisteEntrevista" } },
				},
				{ S = "Lola", T = "Platos.", To = "Yo", If = { Choices = { Empleo = "Barista" } } },
				{ S = "Lola", T = "Pedidos.", To = "Yo", If = { Choices = { Empleo = "Barista" } } },
				{ S = "Lola", T = "Hoy aprenderás una cosa.", To = "Yo", If = { Choices = { Empleo = "Barista" } } },
				{ S = "Lola", T = "No corras.", To = "Yo", Pause = 0.9, If = { Choices = { Empleo = "Barista" } } },
				{ S = "Lola", T = "Organízate.", To = "Yo", If = { Choices = { Empleo = "Barista" } } },
				{ S = "Lola", T = "No pasa nada.", To = "Yo", If = { Choices = { Empleo = "Barista" } } },
				{ S = "Lola", T = "Ahora corrígelo.", To = "Yo", Pause = 0.9, If = { Choices = { Empleo = "Barista" } } },
			},
		},
		Sueldo = {
			Lines = {
				{
					S = "Lola",
					T = "Toma. Tu primer sobre. Te lo has ganado. Bueno, casi todo: la bandeja la descuento en abrazos.",
					If = { Choices = { Empleo = "Barista" } },
				},
				{
					S = "Paco",
					T = "Tu paga. Hmm. Has trabajado bien. Para ser la primera vez. No te acostumbres a que lo diga.",
					If = { Choices = { Empleo = "Reponedor" } },
				},
				{
					S = "Ernesto",
					T = "Tu primer sueldo de repartidor. Ni un paquete perdido. Y el perro del 14 te ha cogido cariño.",
					If = { Choices = { Empleo = "Repartidor" } },
				},
				{
					Ask = "¿Qué haces con él?",
					Options = {
						{ T = "Guardarlo para lo que querías", Effects = { Choice = { Sueldo = "Meta" }, Traits = { Responsabilidad = 1 } } },
						{
							T = "Invitar a tu familia a cenar fuera",
							Effects = { Choice = { Sueldo = "Familia" }, Rel = { Abu = 6, Familia = 8 }, Traits = { Empatia = 1 } },
						},
						{ T = "Una parte para ti, otra para ahorrar", Effects = { Choice = { Sueldo = "Mitad" }, Traits = { Responsabilidad = 1 } } },
					},
				},
			},
		},
	},
	Scenes = {
		Ins04_G13_14_15_16_Musica = { Light = true, Duration = 58, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
	},
	Steps = {},
}
