-- GUION REESCRITO de Saga_04_Ventanilla (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_04_Ventanilla.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_04_Ventanilla
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_04_Ventanilla.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_04_Ventanilla.md",
	Dialogues = {
		Ventanilla1 = {
			Lines = {
				{ S = "Narrador", T = "Delante de Correos hay una ventanilla que no estaba ayer. Flota a medio metro del suelo. Detrás no hay nada." },
				{ S = "Narrador", T = "«¿Eso ha sido… una campana?», pregunta alguien." },
				{ S = "Narrador", T = "«Creo que sí», le contestan." },
				{ S = "Funcionaria", T = "Formulario 42. Registro de grieta no autorizada. Usted es la persona designada.", To = "Yo" },
				{ S = "Yo", T = "¿Designada por quién?" },
				{ S = "Funcionaria", T = "Por el agente Cronos. Y por el plazo. Quedan treinta y una horas antes del sellado.", To = "Yo" },
				{ S = "Funcionaria", T = "Necesito el registro de víctimas de la Caída. Todas. Con nombre.", To = "Yo" },
				{ S = "Narrador", T = "Te entrega una lista. Ciento doce páginas. En la página cuarenta aparece «Cosme, Lía. Desaparecida»." },
			},
		},
		Ventanilla2 = {
			Lines = {
				{
					S = "Funcionaria",
					T = "El registro está incompleto. Hay nombres que no constan en ningún lado. Personas que estaban y ya no están.",
					To = "Yo",
				},
				{
					S = "Funcionaria",
					T = "Para la Aduana, quien no consta no existió. Y un mundo con demasiada gente que no existió es un mundo dañado.",
					To = "Yo",
				},
				{ S = "Yo", T = "¿Qué pasa con un mundo dañado?" },
				{ S = "Funcionaria", T = "Se sella. Nadie entra. Nadie sale. Lo que haya dentro se queda con lo que haya dentro.", To = "Yo" },
				{ S = "Narrador", T = "La ventanilla parpadea. Por un instante, detrás de la funcionaria se ve otra calle: la misma, pero en ruinas." },
				{ S = "Narrador", T = "La funcionaria no se inmuta. Tiene la misma cara que la de Correos. Y que la de la ventanilla de al lado." },
				{ S = "Funcionaria", T = "No mire al fondo. Lo que se ve ahí es lo que pasará si no completa el formulario.", To = "Yo" },
				{ S = "Cosme", T = "No firmes nada todavía.", To = "Yo" },
				{ S = "Pip", T = "La Aduana existe, señor. La he detectado tres veces desde la Caída. Siempre después de una catástrofe.", To = "Yo" },
				{ S = "Cosme", T = "Llegan cuando ya no queda nada que salvar y ponen un sello encima.", To = "Yo" },
				{ S = "Cosme", T = "Lía sigue en esa lista como desaparecida. No como muerta. Eso es lo único que me queda.", To = "Yo" },
				{ S = "Funcionaria", T = "Falta el sello de la autoridad local. Comisaría. Ventanilla 3. Treinta horas.", To = "Yo" },
				{ S = "Narrador", T = "La ventanilla se cierra. En el suelo queda una marca quemada con forma de número: 42." },
			},
		},
	},
	Scenes = {},
	Steps = {},
}
