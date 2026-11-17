-- GUION REESCRITO de Saga_07_Costuras (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_07_Costuras.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_07_Costuras
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_07_Costuras.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_07_Costuras.md",
	Dialogues = {
		Credencial = {
			Lines = {
				{ S = "Cosme", T = "Toma. Lo he hecho yo.", To = "Yo" },
				{ S = "Narrador", T = "Una credencial: «Laboratorio Cosme. Colaborador de campo». Debajo, tu foto y tu rango de la Academia." },
				{ S = "Cosme", T = "Si alguien de la Academia pregunta, es un carné de biblioteca.", To = "Yo" },
				{ S = "Cosme", T = "La costura está cediendo. Un punto cada noche. A este ritmo, en un mes la Grieta vuelve a estar abierta.", To = "Yo" },
				{ S = "Pip", T = "El detector marca tres puntos de fuga. El doctor no puede ir: tiene que vigilar la lectura en directo.", To = "Yo" },
			},
		},
		Informe = {
			Lines = {
				{ S = "Cosme", T = "Hilachas, una costura que cede y una campaña que solo ven los que han tocado la Grieta.", To = "Yo" },
				{ S = "Cosme", T = "Es su forma de trabajar. Primero preparan el terreno. Luego llegan con la solución.", To = "Yo" },
				{ S = "Yo", T = "¿Cósimo?" },
				{ S = "Cosme", T = "Sí. Cósimo.", To = "Yo" },
				{ S = "Cosme", T = "Duermo con un ojo abierto.", To = "Yo", If = { Flags = { "CosimoTeHaVisto" } } },
				{ S = "Cosme", T = "Te prometí contártelo todo. Pip tiene un archivo con lo que sé. Pronto lo abriremos.", To = "Yo" },
			},
		},
		Punto1 = {
			Lines = {
				{ S = "Narrador", T = "Del cielo caen hilos de luz verde, finos como cabellos. Donde tocan el suelo, la hierba se seca." },
				{ S = "Narrador", T = "Y algo pequeñ{o/a} se mueve entre los hilos." },
			},
		},
		Punto2 = {
			Lines = {
				{ S = "Narrador", T = "Una pantalla nueva en la plaza: «Consorcio MegaVerso. ¿Tu mundo se rompe? Te ofrecemos otro»." },
				{ S = "Narrador", T = "«Próximamente: la Gran Fusión»." },
				{ S = "Narrador", T = "La gente pasa por delante sin mirarla. Solo la ves tú." },
			},
		},
		Punto3 = {
			Lines = {
				{ S = "Narrador", T = "En el patio de la Academia, el anclaje de la aguja zumba. Tiene una grieta de arriba abajo." },
				{ S = "Narrador", T = "Lo clavaste tú. Todavía tienes el barro de aquella noche en la memoria.", If = { Memories = { "CoserElCielo" } } },
			},
		},
	},
	Scenes = {
		Saga_07_G3_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Pip", Npc = "Pip" } } },
				Dialogue = {
					{
						At = 0.4,
						S = "Pip",
						T = "Hilachas. Energía de la Grieta que se escapa por la costura y toma forma. Débiles solas. Peligrosas juntas.",
						To = "Yo",
					},
				},
			},
		},
	},
	Steps = { ["2"] = { Effects = { Scene = "Saga_07_G3_Entra" } } },
}
