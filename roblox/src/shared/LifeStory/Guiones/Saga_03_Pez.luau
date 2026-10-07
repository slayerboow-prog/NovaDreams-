-- GUION REESCRITO de Saga_03_Pez (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_03_Pez.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_03_Pez
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_03_Pez.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_03_Pez.md",
	Dialogues = {
		Auxilio = {
			Lines = {
				{
					S = "DonEscamas",
					T = "¡Tú! Sí, tú. La persona que está mirando alrededor como si no hubiera un pez hablando.",
					To = "Yo",
					Pause = 0.9,
					Effects = { Scene = "Saga_03_G1_Musica" },
				},
				{ S = "DonEscamas", T = "Gracias a Neptuno. Un humano con cara de buena persona.", To = "Yo" },
				{ S = "Yo", T = "¿Tú hablas?" },
				{ S = "DonEscamas", T = "Normalmente sí. Cuando estoy nervios{o/a}, hablo más.", To = "Yo" },
				{ S = "DonEscamas", T = "Y ahora estoy MUY nervios{o/a}. Don Escamas. Contable. Pez.", To = "Yo", Pause = 0.9 },
				{ S = "DonEscamas", T = "Refugiado dimensional. En ese orden. Crucé por la Grieta.", To = "Yo", Pause = 0.9 },
				{ S = "Yo", T = "¿Por qué?" },
				{ S = "DonEscamas", T = "Huía. De mi antiguo jefe.", To = "Yo" },
				{ S = "Yo", T = "¿Quién?" },
				{ S = "DonEscamas", T = "El Consorcio MegaVerso. Sociedad Anónima.", To = "Yo" },
				{ S = "DonEscamas", T = "Venden viajes entre dimensiones. Vacaciones. Y otras cosas.", To = "Yo" },
				{ S = "DonEscamas", T = "Cosas que no deberían venderse.", To = "Yo", Pause = 0.9 },
				{ S = "DonEscamas", T = "Yo llevaba sus cuentas. Y vi demasiado.", To = "Yo" },
				{ S = "Yo", T = "¿Qué viste?" },
				{ S = "DonEscamas", T = "Números. Informes. Pedidos.", To = "Yo" },
				{ S = "DonEscamas", T = "Y algo llamado Proyecto Fusión. Ya están aquí.", To = "Yo", Pause = 0.9 },
				{
					Ask = "¿Qué haces?",
					Options = {
						{
							T = "«Te saco de aquí. Conozco a alguien.»",
							Effects = { Flags = { "DonEscamasConfia" }, Rel = { DonEscamas = 8 }, Traits = { Valentia = 1 } },
							Then = {
								{ S = "DonEscamas", T = "¡Un humano con contactos!", To = "Yo" },
								{ S = "DonEscamas", T = "Esto es lo que yo llamo un activo.", To = "Yo", Pause = 0.9 },
								{ S = "DonEscamas", T = "¡Pero un activo con piernas!", To = "Yo" },
							},
						},
						{
							T = "«¿Qué viste en las cuentas?»",
							Effects = { Traits = { Curiosidad = 2 } },
							Then = {
								{ S = "DonEscamas", T = "Un pedido enorme. Proyecto Fusión.", To = "Yo" },
								{ S = "DonEscamas", T = "Firmado por un doctor. No. Aquí no.", To = "Yo" },
								{ S = "DonEscamas", T = "Las paredes tienen oídos.", To = "Yo" },
								{ S = "DonEscamas", T = "Y los árboles tienen agentes.", To = "Yo" },
							},
						},
					},
				},
			},
		},
		Cubo = { Lines = { { S = "DonEscamas", T = "¿Eso es un cubo? Humillante. Pero funcional. ¡Hop! Mucho mejor.", To = "Yo" } } },
		Pecera = {
			Lines = {
				{ S = "Cosme", T = "¿Un pez? ¿En mi garaje? ¿Contable?", To = "Yo", Effects = { Scene = "Saga_03_G4_Musica" } },
				{ S = "Cosme", T = "Siempre he querido un contable. Pip.", To = "Yo", Pause = 0.9 },
				{ S = "Pip", T = "Sí, señor.", To = "Yo" },
				{ S = "Cosme", T = "La pecera buena.", To = "Yo" },
				{ S = "Pip", T = "¿La que explota o la que se incendia?", To = "Yo" },
				{ S = "Cosme", T = "La tercera.", To = "Yo" },
				{ S = "Pip", T = "No existe una tercera.", To = "Yo" },
				{ S = "Cosme", T = "Esa.", To = "Yo" },
				{ S = "Pip", T = "Ah. La nueva.", To = "Yo" },
				{ S = "DonEscamas", T = "Doctor Cosme.", To = "Yo" },
				{ S = "Cosme", T = "¿Nos conocemos?", To = "Yo" },
				{ S = "DonEscamas", T = "No. Pero su nombre aparece en nuestros archivos. Bueno… El de su socio. El de la perilla.", To = "Yo" },
				{ S = "Yo", T = "¿El de la moneda? ¿Cósimo?", If = { Flags = { "SabeDeCosimo" } } },
				{ S = "Cosme", T = "No sé de qué me habla. Pez.", To = "Yo", If = { Flags = { "SabeDeCosimo" } } },
				{ S = "DonEscamas", T = "Ah. Entonces sí es él.", To = "Yo", If = { Flags = { "SabeDeCosimo" } } },
				{ S = "Cosme", T = "No.", To = "Yo", If = { Flags = { "SabeDeCosimo" } } },
				{ S = "DonEscamas", T = "No he dicho nada.", To = "Yo", If = { Flags = { "SabeDeCosimo" } } },
				{ S = "DonEscamas", T = "Su socio está en la dimensión 66-B. Cósimo.", To = "Yo" },
				{ S = "DonEscamas", T = "El Consorcio le paga el laboratorio.", To = "Yo", Pause = 0.9 },
				{ S = "DonEscamas", T = "Y están buscando algo aquí. El Ancla.", To = "Yo" },
				{ S = "Yo", T = "¿Qué es el Ancla?", Pause = 0.9 },
				{ S = "DonEscamas", T = "Uy. He hablado de más.", To = "Yo", Pause = 0.9 },
				{ S = "DonEscamas", T = "Es un tic de contable. Lo cuento todo. Me callo. Me callo muy fuerte. Glu.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "Nadie ha dicho nada de anclas. Ni de barcos. El pez se queda aquí. Tú te vas a casa. Y, criatura…", To = "Yo" },
				{ S = "Cosme", T = "Si ves a alguien de gris… Corre. Siempre.", To = "Yo", Pause = 0.9 },
				{ S = "DonEscamas", T = "Toma. Una escama. Por si algún día necesitas un contable. O un amigo. Soy las dos cosas.", To = "Yo" },
				{ S = "Cosme", T = "¿Cuánto sabe?", To = "Yo" },
				{ S = "Pip", T = "Demasiado para su edad.", To = "Yo" },
				{ S = "Cosme", T = "Eso me preocupa.", To = "Yo" },
				{ S = "Pip", T = "¿Por Cósimo?", To = "Yo" },
				{ S = "Cosme", T = "Por el Ancla.", To = "Yo" },
				{ S = "Narrador", T = "Solo una palabra: «…Ancla…»", Pause = 0.9 },
			},
		},
		Tarjeta = {
			Lines = {
				{ S = "DonEscamas", T = "Esa palabra… No me gusta.", To = "Yo", Pause = 0.9 },
				{ S = "AgenteGris2", T = "Buenos días. ¿Ha visto usted un pez?", To = "Yo" },
				{ S = "AgenteGris2", T = "Con corbata.", To = "Yo", Pause = 1.8 },
				{ S = "DonEscamas", T = "No respiréis. Ah, no. Tú tienes que respirar. No aceptes. Son muy convincentes.", To = "Yo", Pause = 0.9 },
			},
		},
	},
	Scenes = {
		Saga_03_G1_Musica = {
			Light = true,
			Duration = 62.9,
			Anchors = { Yo = "Player" },
			Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" }, { At = 31.4, Intensity = "Tension" } } },
		},
		Saga_03_G3_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "AgenteGris1", Npc = "AgenteGris1" } }, { At = 0, Use = { Key = "DonEscamas", Npc = "DonEscamas" } } },
				Dialogue = {
					{ At = 0.4, S = "AgenteGris1", T = "Buenos días. ¿Podemos revisar ese cubo?", To = "Yo" },
					{ At = 4, S = "DonEscamas", T = "No. Quiero decir… ¡Agua!", To = "Yo" },
				},
			},
		},
		Saga_03_G4_Musica = { Light = true, Duration = 107.6, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
	},
	Steps = {
		["2"] = { Effects = { Scene = "Saga_03_G3_Entra" }, Set = { Text = "Prepara la huida de Don Escamas." } },
		["2.1"] = { Set = { Text = "Consigue algo donde Don Escamas pueda viajar." } },
		["2.2"] = { Set = { Text = "Busca algo que hayan dejado los agentes." } },
		["3"] = { Set = { Text = "Lleva a Don Escamas al garaje de Cosme sin que te atrapen." } },
	},
}
