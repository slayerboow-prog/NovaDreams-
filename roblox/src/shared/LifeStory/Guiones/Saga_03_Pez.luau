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
				{ S = "DonEscamas", T = "Usted lleva el uniforme de la Academia. Bien. No tengo mucho tiempo.", To = "Yo" },
				{ S = "DonEscamas", T = "Me llamo Escamas. En mi mundo vivíamos en el agua. Ya no queda mundo.", To = "Yo" },
				{ S = "DonEscamas", T = "Crucé la Grieta hace tres noches. Trabajaba para el Consorcio: llevaba sus cuentas.", To = "Yo" },
				{ S = "DonEscamas", T = "Venden mundos. Abren grietas, dejan que las bestias limpien lo que haya y luego cobran por lo que queda.", To = "Yo" },
				{ S = "DonEscamas", T = "Vi lo que había detrás de los números. Por eso me buscan.", To = "Yo" },
				{ S = "DonEscamas", T = "Dos agentes de gris. Llevan días peinando el parque. No duermen y no se cansan.", To = "Yo" },
				{
					Ask = "¿Qué haces?",
					Options = {
						{
							T = "«Te saco de aquí. Conozco a alguien.»",
							Effects = { Rel = { DonEscamas = 8 }, Traits = { Valentia = 1 } },
							Then = { { S = "DonEscamas", T = "Gracias. No sabe en lo que se mete. Yo tampoco lo sabía." } },
						},
						{
							T = "«¿Qué viste en las cuentas?»",
							Effects = { Traits = { Curiosidad = 2 } },
							Then = {
								{
									S = "DonEscamas",
									T = "Un proyecto enorme: «Fusión». Juntar mundos a la fuerza. Aquí no puedo decir más: los agentes oyen a mucha distancia.",
								},
							},
						},
					},
				},
			},
		},
		Cubo = { Lines = { { S = "Narrador", T = "Un cubo con agua del estanque. Escamas no aguanta mucho fuera del agua. Se mete dentro sin decir nada." } } },
		Pecera = {
			Lines = {
				{ S = "Cosme", T = "¿Quién es? Pip, el tanque de agua salada. Rápido.", To = "Yo" },
				{ S = "DonEscamas", T = "Doctor Cosme. En el Consorcio su nombre aparece en muchos documentos. Bueno: el de su otra versión.", To = "Yo" },
				{ S = "Yo", T = "¿Cósimo?", If = { Flags = { "SabeDeCosimo" } } },
				{
					S = "DonEscamas",
					T = "Cósimo dirige el laboratorio de la dimensión 66-B. El Consorcio lo financia. Él abrió la grieta de la Caída.",
					To = "Yo",
					If = { Flags = { "SabeDeCosimo" } },
				},
				{
					S = "DonEscamas",
					T = "Y busca algo aquí. Lo llaman el Ancla. Mientras el Ancla esté en este mundo, la Grieta no puede abrirse del todo.",
					To = "Yo",
					If = { Flags = { "SabeDeCosimo" } },
				},
				{ S = "Yo", T = "¿Qué es el Ancla?", If = { Flags = { "SabeDeCosimo" } } },
				{
					S = "DonEscamas",
					T = "No lo sé. Solo vi el nombre en una partida de gastos. Una partida enorme.",
					To = "Yo",
					If = { Flags = { "SabeDeCosimo" } },
				},
				{ S = "Cosme", T = "Escamas se queda aquí. Tú vete a descansar.", To = "Yo", If = { Flags = { "SabeDeCosimo" } } },
				{ S = "Cosme", T = "Y si ves a alguien de gris, no te enfrentes. Vete. Siempre.", To = "Yo", If = { Flags = { "SabeDeCosimo" } } },
				{
					S = "DonEscamas",
					T = "Tome. Una escama. Si alguna vez necesita a alguien que sepa leer las cuentas del Consorcio, ya sabe dónde estoy.",
					To = "Yo",
					If = { Flags = { "SabeDeCosimo" } },
				},
			},
		},
		Tarjeta = {
			Lines = {
				{ S = "Narrador", T = "En el suelo, una tarjeta gris: «Consorcio MegaVerso. Delegación Valmar: en apertura»." },
				{ S = "Narrador", T = "Por detrás, a mano: «Localizar al Ancla»." },
				{ S = "Narrador", T = "Dos hombres de traje gris salen de entre los árboles. Sonríen a la vez. Exactamente a la vez." },
				{ S = "AgenteGris1", T = "Buenas tardes, guerrero. Buscamos a un fugitivo. Peligroso. Nos lo puede entregar o se lo podemos quitar.", To = "Yo" },
				{ S = "AgenteGris1", T = "La segunda opción es más rápida. Para nosotros.", To = "Yo" },
			},
		},
	},
	Scenes = {},
	Steps = { ["3"] = { Set = { Text = "Lleva a Escamas al garaje de Cosme sin que te atrapen" } } },
}
