-- GUION REESCRITO de Uni01b_Residencia (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Uni01b_Residencia.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Uni01b_Residencia
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Uni01b_Residencia.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Uni01b_Residencia.md",
	Dialogues = {
		Cena = {
			Lines = {
				{ S = "Ivan", T = "Tengo una pregunta importante.", To = "Yo" },
				{ S = "Ivan", T = "¿Qué comida de aquí es segura?", To = "Yo", Pause = 0.9 },
				{ S = "Ivan", T = "Bueno.", To = "Yo" },
				{ S = "Ivan", T = "Ya es tarde para averiguarlo.", To = "Yo", Pause = 0.9 },
				{ S = "Ivan", T = "Buenas noches.", To = "Yo" },
				{ S = "Ivan", T = "Supongo.", To = "Yo", Pause = 0.9 },
				{ S = "Ivan", T = "¿Sabes qué es lo raro?", To = "Yo" },
				{ S = "Ivan", T = "Hoy conocíamos a un montón de gente.", To = "Yo", Pause = 0.9 },
				{ S = "Ivan", T = "Y aun así…", To = "Yo" },
				{ S = "Ivan", T = "Estamos aquí los dos.", To = "Yo", Pause = 0.9 },
				{ S = "Ivan", T = "Supongo que esto es independizarse.", To = "Yo", Pause = 0.9 },
				{ S = "Ivan", T = "Buenas noches.", To = "Yo" },
				{ S = "Pip", T = "Perdona la hora.", To = "Yo" },
				{ S = "Pip", T = "Necesito que vengas al garaje.", To = "Yo", Pause = 0.9 },
				{ S = "Pip", T = "He encontrado la caja de Cosme.", To = "Yo" },
				{ S = "Pip", T = "Y no estaba vacía.", To = "Yo", Pause = 0.9 },
				{ S = "Pip", T = "No vengas solo si no quieres.", To = "Yo", Pause = 0.9 },
				{ S = "Pip", T = "Pero ven.", To = "Yo", Pause = 0.9 },
				{
					Ask = "¿Qué aportas a la cena?",
					Options = {
						{
							T = "La tortilla que te enseñó tu familia",
							Effects = { Flags = { "SabeCocinar" }, Rel = { Candela = 4, Ivan = 4 } },
							Then = {
								{ S = "Ivan", T = "…¿Esto lo has hecho TÚ?", Shot = "PrimerPlano:Ivan", Pause = 1, Beat = "Piensa" },
								{ S = "Ivan", T = "Me caso con esta tortilla. Bueno, no. Pero casi." },
							},
						},
						{
							T = "Tu último táper de casa, para compartir",
							Effects = { Rel = { Candela = 3, Ivan = 3 }, Traits = { Empatia = 1 } },
							Then = {
								{ S = "Candela", T = "Sabe a casa.", Shot = "PrimerPlano:Candela", Pause = 0.8 },
								{ S = "Candela", T = "…Perdón. Me he emocionado con unas lentejas. Es el primer día.", Beat = "Baja" },
							},
						},
						{
							T = "Pan con pan. Es lo que hay",
							Effects = { Traits = { Humor = 1 } },
							Then = { { S = "Ivan", T = "El famoso bocadillo de pan. Clásico de primero. El año que viene serás un chef. O no." } },
						},
					},
				},
			},
		},
		Compis = {
			Lines = {
				{ S = "Ivan", T = "Ah.", To = "Yo" },
				{ S = "Ivan", T = "Soy Iván.", To = "Yo", Pause = 0.9 },
				{ S = "Ivan", T = "No ronco.", To = "Yo", Pause = 0.9 },
				{ S = "Ivan", T = "¿Tú has vivido siempre por aquí?", To = "Yo" },
				{ S = "Ivan", T = "¿Quién es Cosme?", To = "Yo" },
				{ S = "Ivan", T = "Vale.", To = "Yo" },
				{ S = "Ivan", T = "Cada uno tiene sus cosas.", To = "Yo", Pause = 0.9 },
			},
		},
	},
	Scenes = {},
	Steps = {},
}
