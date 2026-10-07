-- GUION REESCRITO de Saga_10_Fiesta (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_10_Fiesta.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_10_Fiesta
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_10_Fiesta.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_10_Fiesta.md",
	Dialogues = {
		Amigos = {
			Lines = {
				{ S = "Narrador", T = "Los números están ahí. Gigantes.", Pause = 1.8 },
				{ S = "Narrador", T = "Pero nadie parece verlos.", Pause = 0.9 },
				{ S = "Omar", T = "¡Fiesta gratis! Confeti, refrescos, música…", To = "Yo" },
				{ S = "Omar", T = "Y una pantalla que dice «Fusión». ¿Fusión de qué?", To = "Yo" },
				{ S = "Omar", T = "¿De sabores de helado? Espera.", To = "Yo" },
				{ S = "Omar", T = "¿Tú ves algo en el cielo?", To = "Yo", Pause = 0.9 },
				{ S = "Omar", T = "Porque yo estoy viendo unos números enormes que antes no veía.", To = "Yo" },
				{ S = "Omar", T = "Desde que me contaste lo de la Grieta… Veo cosas raras. Gracias, supongo.", To = "Yo", Pause = 0.9 },
				{ S = "Yo", T = "Es la Fusión de las dos Valmar.", If = { Flags = { "SabeFusion" } } },
				{ S = "Omar", T = "Ya no está bromeando. Entonces sí es verdad. ¿Y esos números?", To = "Yo", Pause = 0.9 },
				{ S = "Yo", T = "Es una cuenta atrás." },
				{ S = "Omar", T = "¿Hasta cuándo?", To = "Yo" },
				{ S = "Yo", T = "Mi graduación.", Pause = 0.9 },
				{ S = "Omar", T = "Vale. Entonces tenemos un problema.", To = "Yo" },
				{ S = "Nico", T = "¿Qué problema?", To = "Yo" },
				{ S = "Omar", T = "Uno grande.", To = "Yo" },
				{ S = "Sara", T = "¿Otra cosa de la Grieta?", To = "Yo" },
				{ S = "Omar", T = "{Él/Ella} dice que sí.", To = "Yo" },
				{ S = "Sara", T = "No puede verlo. No veo nada.", To = "Yo" },
				{ S = "Sara", T = "Eso no significa que no exista.", To = "Yo", Pause = 0.9 },
				{ S = "Sara", T = "Y eso es lo que me preocupa.", To = "Yo" },
				{ S = "Omar", T = "¿Qué hacemos? ¿Plan? ¿Tienes un plan?", To = "Yo" },
				{ S = "Omar", T = "Dime que tienes un plan. Yo te cubro.", To = "Yo" },
			},
		},
		Cabina = {
			Lines = {
				{ S = "Omar", T = "Esto es un poco raro. Y eso que yo bailo fatal. Mucho mejor.", To = "Yo" },
				{ S = "Omar", T = "Ahora parecen personas.", To = "Yo", Pause = 0.9 },
				{ S = "Narrador", T = "Durante unos segundos, la plaza vuelve a sentirse normal." },
			},
		},
		Cuenta = {
			Lines = {
				{ S = "Omar", T = "¿Seguro que esto no explota? Vale. No preguntes.", To = "Yo" },
				{ S = "Narrador", T = "No era una fecha aproximada." },
				{ S = "Cosimo", T = "Qué maleducado.", To = "Yo", Pause = 1.8 },
				{ S = "Omar", T = "¿Has visto eso?", To = "Yo" },
				{ S = "Yo", T = "Sí." },
				{ S = "Omar", T = "Vale. Definitivamente tenemos un problema.", To = "Yo" },
			},
		},
		Final = {
			Lines = {
				{ S = "Nico", T = "¿Qué ha pasado?", To = "Yo" },
				{ S = "Sara", T = "Estadísticamente… Hoy han pasado demasiadas cosas raras.", To = "Yo", Pause = 0.9 },
				{ S = "Sara", T = "Y tú estabas en medio. Como siempre. Te lo apunto.", To = "Yo" },
				{ S = "Omar", T = "Está agotado. Hemos salvado una fiesta. O el mundo. No lo sé.", To = "Yo" },
				{ S = "Omar", T = "Pero ha sido lo mejor del curso. Oye.", To = "Yo" },
				{ S = "Omar", T = "Tu graduación es dentro de poco.", To = "Yo", Pause = 0.9 },
				{ S = "Omar", T = "¿Eso tiene algo que ver con los números del cielo?", To = "Yo" },
				{ S = "Nico", T = "¿Qué números?", To = "Yo", Pause = 0.9 },
				{ S = "Omar", T = "Los que tú no puedes ver.", To = "Yo" },
				{ S = "Nico", T = "Eso no me tranquiliza.", To = "Yo" },
				{ S = "Narrador", T = "No era una cuenta atrás para una fiesta. Ni para una venta." },
				{ S = "Narrador", T = "Ni siquiera para la Fusión." },
				{ S = "Narrador", T = "MegaVerso estaba contando los días hasta ti.", Pause = 0.9 },
			},
		},
		Taquilla = {
			Lines = {
				{ S = "Omar", T = "¿Noventa y nueve? Por fusionar universos.", To = "Yo" },
				{ S = "Omar", T = "Espero que al menos den comida.", To = "Yo" },
				{ S = "Omar", T = "Creo que la máquina ha tomado una decisión.", To = "Yo" },
				{ S = "Narrador", T = "Las entradas salen por toda la plaza." },
			},
		},
	},
	Scenes = {
		Saga_10_G3_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Omar", Npc = "Omar" } } },
				Dialogue = {
					{
						At = 1.3,
						S = "Omar",
						T = "Corre. ¡Yo sabía que esto acabaría así! ¡NO FIRMES NADA! ¡Eh! ¡Por aquí! ¿Se han ido? ¡CORRE!",
						To = "Yo",
					},
				},
			},
		},
	},
	Steps = { ["2"] = { Effects = { Scene = "Saga_10_G3_Entra" } } },
}
