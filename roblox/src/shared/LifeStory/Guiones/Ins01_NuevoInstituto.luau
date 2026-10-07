-- GUION REESCRITO de Ins01_NuevoInstituto (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Ins01_NuevoInstituto.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Ins01_NuevoInstituto
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Ins01_NuevoInstituto.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Ins01_NuevoInstituto.md",
	Dialogues = {
		Cena = {
			Lines = {
				{ S = "Familia", T = "¡Cuéntalo todo!", To = "Yo" },
				{ S = "Familia", T = "¿Cómo es?", To = "Yo", Pause = 0.9 },
				{ S = "Familia", T = "Otra.", To = "Yo" },
				{ S = "Familia", T = "¿Es grande?", To = "Yo" },
				{ S = "Familia", T = "Otra.", To = "Yo" },
				{ S = "Familia", T = "¿Te has perdido?", To = "Yo" },
				{ S = "Familia", T = "Otra.", To = "Yo" },
				{ S = "Familia", T = "¿Has comido?", To = "Yo" },
				{ S = "Familia", T = "¡Eso es lo importante!", To = "Yo", Pause = 0.9 },
				{ S = "Familia", T = "¿El ascensor de alumnos?", To = "Yo", If = { Choices = { Veterano = "Creer" } } },
				{ S = "Familia", T = "¡A mí también me lo hicieron!", To = "Yo", If = { Choices = { Veterano = "Creer" } } },
				{ S = "Familia", T = "Hay cosas que no cambian nunca.", To = "Yo", If = { Choices = { Veterano = "Creer" } } },
				{ S = "Abu", T = "Y algunas bromas duran más que las personas.", To = "Yo", If = { Choices = { Veterano = "Creer" } } },
				{ S = "Familia", T = "¿Una compañera nueva?", To = "Yo", If = { Flags = { "ConocesALeire" } } },
				{ S = "Familia", T = "¿Leire?", To = "Yo", Pause = 0.9, If = { Flags = { "ConocesALeire" } } },
				{ S = "Familia", T = "Qué bien que te hayas acercado.", To = "Yo", If = { Flags = { "ConocesALeire" } } },
				{ S = "Familia", T = "Empezar en una ciudad nueva es difícil.", To = "Yo", Pause = 0.9, If = { Flags = { "ConocesALeire" } } },
				{ S = "Abu", T = "Y dime…", To = "Yo" },
				{ S = "Abu", T = "¿A quién le sonreíste?", To = "Yo", Pause = 0.9 },
				{ S = "Abu", T = "Ah.", To = "Yo" },
				{ S = "Abu", T = "Es una extensión cinematográfica del paso 19.", To = "Yo", Pause = 0.9 },
				{ S = "Narrador", T = "El instituto da un poco de miedo." },
				{ S = "Narrador", T = "Pero también parece divertido.", Pause = 0.9 },
			},
		},
		Delegada = {
			Lines = {
				{ S = "Delegada", T = "¿El ascensor de alumnos?", To = "Yo" },
				{ S = "Delegada", T = "No existe.", To = "Yo", Pause = 0.9 },
				{ S = "Delegada", T = "Primero C está abajo.", To = "Yo" },
				{ S = "Delegada", T = "Y si necesitáis algo, buscadme.", To = "Yo" },
			},
		},
		Entrada = {
			Lines = {
				{ S = "Veterano", T = "¿Los de primero?", To = "Yo" },
				{ S = "Veterano", T = "Aunque…", To = "Yo", Pause = 0.9 },
				{ S = "Veterano", T = "También podéis coger el ascensor de alumnos.", To = "Yo" },
				{ S = "Omar", T = "¿Hay ascensor de alumnos?", To = "Yo" },
			},
		},
		Leire_Recreo = {
			Lines = {
				{ S = "Leire", T = "¿Qué?", To = "Yo" },
				{ S = "Leire", T = "Estoy bien sola.", To = "Yo", Pause = 0.9 },
				{ S = "Leire", T = "…", To = "Yo", Pause = 0.9 },
				{ S = "Leire", T = "Vale.", To = "Yo", Pause = 0.9 },
				{ S = "Leire", T = "No mucho.", To = "Yo" },
				{ S = "Leire", T = "En mi otra ciudad tenía un grupo.", To = "Yo" },
				{ S = "Leire", T = "El bocadillo es buena compañía.", To = "Yo", Pause = 0.9 },
				{ S = "Leire", T = "Pero no habla.", To = "Yo", Pause = 0.9 },
				{ S = "Omar", T = "¡Es verdad!", To = "Yo", Pause = 0.9 },
				{ S = "Omar", T = "¡Traigo de todo!", To = "Yo" },
				{ S = "Omar", T = "¡Hasta aceitunas!", To = "Yo", Pause = 0.9 },
				{ S = "Leire", T = "Vale.", To = "Yo" },
				{ S = "Leire", T = "Pero si son pesados, me vuelvo al banco.", To = "Yo", Pause = 0.9 },
				{ S = "Leire", T = "¿Las fotos?", To = "Yo" },
				{ S = "Leire", T = "Nadie me pregunta por las fotos.", To = "Yo", Pause = 0.9 },
				{ S = "Leire", T = "Esta es mi antigua calle.", To = "Yo" },
				{ S = "Leire", T = "Otra.", To = "Yo" },
				{ S = "Leire", T = "Y esta…", To = "Yo" },
				{ S = "Leire", T = "Es el mar.", To = "Yo", Pause = 0.9 },
				{
					Ask = "¿Qué le dices?",
					Options = {
						{
							T = "«Vente con nosotros. Omar trae comida para todos.»",
							Effects = { Flags = { "ConocesALeire" }, Rel = { Leire = 10, Omar = 2 }, Traits = { Empatia = 2 } },
							Then = {
								{ S = "Omar", T = "(desde lejos) ¡Es verdad! ¡Traigo de todo! ¡Hasta aceitunas!" },
								{ S = "Leire", T = "…Vale. Pero si son pesados, me vuelvo al banco." },
							},
						},
						{
							T = "«¿Me enseñas qué fotos haces?»",
							Effects = { Flags = { "ConocesALeire" }, Rel = { Leire = 8 }, Traits = { Curiosidad = 1 } },
							Then = { { S = "Leire", T = "Nadie me pregunta por las fotos. Solo por la cámara. …Mira. Esta es mi antigua calle. Y esta, el mar." } },
						},
					},
				},
			},
		},
		Manana = {
			Lines = {
				{ S = "Familia", T = "¡{nombre}!", To = "Yo" },
				{ S = "Familia", T = "¡Primer día de instituto!", To = "Yo", Pause = 0.9 },
				{ S = "Familia", T = "¿Libros?", To = "Yo" },
				{ S = "Abu", T = "Lo único que falta es respirar.", To = "Yo", Pause = 0.9 },
				{ S = "Familia", T = "Eso también.", To = "Yo" },
				{ S = "Yo", T = "Acompáñame hasta la puerta, porfa." },
				{ S = "Familia", T = "Claro.", To = "Yo" },
				{ S = "Familia", T = "Hasta la puerta.", To = "Yo", Pause = 0.9 },
				{ S = "Familia", T = "Ni un paso más.", To = "Yo" },
				{ S = "Familia", T = "Bueno…", To = "Yo", Pause = 0.9 },
				{ S = "Familia", T = "Hasta la esquina.", To = "Yo" },
				{ S = "Yo", T = "Puedo ir por mi cuenta. Pero gracias." },
				{ S = "Familia", T = "Vale.", To = "Yo" },
				{ S = "Familia", T = "Qué rápido pasa todo.", To = "Yo", Pause = 0.9 },
				{ S = "Familia", T = "Ayer la mochila era más grande que tú.", To = "Yo" },
				{ S = "Abu", T = "El personaje se gira.", To = "Yo" },
				{ S = "Abu", T = "El primer día, sonríe a alguien que no conozcas.", To = "Yo" },
				{ S = "Abu", T = "Solo a una persona.", To = "Yo", Pause = 0.9 },
				{ S = "Abu", T = "Ya verás.", To = "Yo" },
				{
					Ask = "¿Qué le dices?",
					Options = {
						{
							T = "«Acompáñame hasta la puerta, porfa»",
							Effects = { Choice = { PrimerDiaIns = "Acompanado" }, Rel = { Familia = 4 } },
							Then = { { S = "Familia", T = "¡Hasta la puerta de casa! Ni un paso más, prometido. …Bueno, hasta la esquina." } },
						},
						{
							T = "«Puedo ir por mi cuenta. Pero gracias.»",
							Effects = { Choice = { PrimerDiaIns = "Solo" }, Traits = { Valentia = 1 } },
							Then = { { S = "Familia", T = "Vale, vale. Qué rápido pasa todo. Ayer tenías la mochila más grande que tú." } },
						},
					},
				},
			},
		},
		Recreo = {
			Lines = {
				{ S = "Sara", T = "¡Os he encontrado!", To = "Yo" },
				{ S = "Sara", T = "En mi clase hablan de cosas rarísimas.", To = "Yo", Pause = 0.9 },
				{ S = "Sara", T = "Yo quería hablar de hongos.", To = "Yo", Pause = 0.9 },
				{ S = "Nico", T = "¡Eh!", To = "Yo" },
				{ S = "Omar", T = "Está bien.", To = "Yo", Pause = 0.9 },
				{ S = "Omar", T = "¿No?", To = "Yo" },
				{
					Ask = "¿Qué haces?",
					Options = {
						{
							T = "«Esto es nuestro rincón desde hoy.» Te sientas con Omar y Sara",
							Effects = { Choice = { RecreoIns = "Rincon" }, Rel = { Omar = 3, Sara = 3 } },
							Then = { { S = "Sara", T = "Declaramos este banco territorio del grupo. Con sus derechos y sus bocadillos." } },
						},
						{
							T = "Vas a jugar con Nico y los de segundo",
							Effects = { Choice = { RecreoIns = "Nico" }, Rel = { Nico = 5 }, Traits = { Deportividad = 1 } },
							Then = { { S = "Nico", T = "¡{nombre}! ¡Menos mal! Estos de segundo son buenos, pero no se saben nuestras jugadas." } },
						},
						{
							T = "Das una vuelta para conocer el instituto",
							Effects = { Choice = { RecreoIns = "Explorar" }, Traits = { Curiosidad = 1 } },
							Then = {
								{
									S = "Narrador",
									T = "Laboratorios, un gimnasio con gradas, una biblioteca con sillones… y, en un banco apartado, Leire comiendo sola.",
									If = { NotFlags = { "ConocesALeire" } },
								},
								{
									S = "Narrador",
									T = "Laboratorios, un gimnasio con gradas, una biblioteca con sillones. Leire te saluda desde lejos con la cámara.",
									If = { Flags = { "ConocesALeire" } },
								},
							},
						},
					},
				},
			},
		},
		Sit_Bruno = {
			Lines = {
				{ S = "Bruno", T = "¿En serio?", To = "Yo" },
				{ S = "Bruno", T = "Vale.", To = "Yo" },
				{ S = "Bruno", T = "Normas.", To = "Yo", Pause = 0.9 },
				{ S = "Bruno", T = "No me copies en los exámenes.", To = "Yo" },
				{ S = "Bruno", T = "Y yo tampoco a ti.", To = "Yo" },
				{ S = "Bruno", T = "Eso lo añado ahora.", To = "Yo", Pause = 0.9 },
				{ S = "Bruno", T = "Oye.", To = "Yo" },
				{ S = "Bruno", T = "Yo tampoco conozco a nadie aquí.", To = "Yo", Pause = 0.9 },
				{ S = "Bruno", T = "Está bien tener a alguien conocido.", To = "Yo" },
			},
		},
		Sit_Leire = {
			Lines = {
				{ S = "Leire", T = "Vale.", To = "Yo" },
				{ S = "Leire", T = "Es de mi abuelo.", To = "Yo", Pause = 0.9 },
				{ S = "Leire", T = "Es de carrete.", To = "Yo", Pause = 0.9 },
				{ S = "Leire", T = "Bueno.", To = "Yo" },
				{ S = "Leire", T = "Ya te lo he contado.", To = "Yo" },
				{ S = "Leire", T = "Qué rabia.", To = "Yo" },
			},
		},
		Sit_Omar = {
			Lines = {
				{ S = "Omar", T = "Lo sabía.", To = "Yo" },
				{ S = "Omar", T = "Te he guardado el sitio desde las ocho menos cuarto.", To = "Yo", Pause = 0.9 },
				{ S = "Omar", T = "Sabía que vendrías.", To = "Yo" },
			},
		},
		Tablon = {
			Lines = {
				{ S = "Narrador", T = "1.º A." },
				{ S = "Omar", T = "¿Bruno?", To = "Yo", Pause = 0.9 },
				{ S = "Omar", T = "Esto ya es el destino.", To = "Yo" },
				{ S = "Iker", T = "También estoy en primero C.", To = "Yo", If = { Flags = { "IkerEnElGrupo" } } },
			},
		},
		Tutor = {
			Lines = {
				{ S = "Javier", T = "Buenos días, 1.º C.", To = "Yo" },
				{ S = "Javier", T = "Soy Javier.", To = "Yo" },
				{ S = "Javier", T = "Os daré Historia.", To = "Yo", Pause = 0.9 },
				{ S = "Javier", T = "Y alguna charla que no me habéis pedido.", To = "Yo" },
				{ S = "Javier", T = "Algunos alumnos ríen.", To = "Yo" },
				{ S = "Javier", T = "Aquí nadie os va a llevar de la mano.", To = "Yo" },
				{ S = "Javier", T = "Pero si os perdéis…", To = "Yo", Pause = 0.9 },
				{ S = "Javier", T = "Preguntar no es de pequeños.", To = "Yo" },
				{ S = "Javier", T = "Es de listos.", To = "Yo" },
				{ S = "Javier", T = "Tenemos una alumna nueva.", To = "Yo" },
				{ S = "Javier", T = "¿Quieres decir algo?", To = "Yo" },
				{ S = "Leire", T = "No.", To = "Yo", Pause = 0.9 },
				{ S = "Javier", T = "Me gusta.", To = "Yo", Pause = 1.8 },
				{ S = "Bruno", T = "Eh.", To = "Yo", If = { Choices = { AdiosBruno = "DeCero" } } },
				{ S = "Bruno", T = "Aquí hay sitio.", To = "Yo", If = { Choices = { AdiosBruno = "DeCero" } } },
				{ S = "Bruno", T = "Si quieres.", To = "Yo", Pause = 0.9, If = { Choices = { AdiosBruno = "DeCero" } } },
				{ S = "Bruno", T = "De cero, ¿no?", To = "Yo", If = { Choices = { AdiosBruno = "DeCero" } } },
			},
		},
	},
	Scenes = {
		Ins01_G13_Entra = {
			Light = true,
			Duration = 10.2,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Javier", Npc = "Javier" } } },
				Dialogue = {
					{ At = 0.4, S = "Javier", T = "[Nombre].", To = "Yo" },
					{ At = 2.4, S = "Javier", T = "¿Estás conmigo?", To = "Yo" },
					{ At = 4.5, S = "Javier", T = "Bien.", To = "Yo" },
					{ At = 6.6, S = "Javier", T = "No afecta al resultado académico.", To = "Yo" },
				},
			},
		},
		Ins01_G17_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Javier", Npc = "Javier" } } },
				Dialogue = {
					{ At = 0.4, S = "Javier", T = "No busquéis solamente el resultado.", To = "Yo" },
					{ At = 4.4, S = "Javier", T = "Quiero saber cómo habéis llegado hasta él.", To = "Yo" },
				},
			},
		},
		Ins01_G3_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Mateo", Npc = "Mateo" } }, { At = 0, Use = { Key = "Hugo", Npc = "Hugo" } } },
				Dialogue = {
					{ At = 0.4, S = "Mateo", T = "Me he apuntado el aula.", To = "Yo", If = { Flags = { "AyudasteAMateo" } } },
					{ At = 2.8, S = "Hugo", T = "He traído esto por si nadie me habla.", To = "Yo", If = { Flags = { "HugoConElGrupo" } } },
				},
			},
		},
		Ins01_G8_Entra = {
			Light = true,
			Duration = 17.8,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Veterano", Npc = "Veterano" } }, { At = 0, Use = { Key = "Omar", Npc = "Omar" } } },
				Dialogue = {
					{ At = 1.3, S = "Omar", T = "Esto no parece un ascensor.", To = "Yo" },
					{ At = 4.8, S = "Veterano", T = "¡Todos los años alguien cae!", To = "Yo" },
					{ At = 7.5, S = "Veterano", T = "Tranquilos.", To = "Yo" },
					{ At = 9.6, S = "Veterano", T = "A mí me lo hicieron también.", To = "Yo" },
					{ At = 12.3, S = "Veterano", T = "Primero C está abajo.", To = "Yo" },
					{ At = 14.6, S = "Omar", T = "Esto lo cuento en la cena.", To = "Yo" },
				},
			},
		},
	},
	Steps = {
		["12"] = { Effects = { Scene = "Ins01_G13_Entra" } },
		["16"] = { Effects = { Scene = "Ins01_G17_Entra" } },
		["2"] = { Effects = { Scene = "Ins01_G3_Entra" } },
		["7"] = { Effects = { Scene = "Ins01_G8_Entra" } },
	},
}
