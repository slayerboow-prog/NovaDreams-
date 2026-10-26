-- GUION REESCRITO de Vertice_03_Museo (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Vertice_03_Museo.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Vertice_03_Museo
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Vertice_03_Museo.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Vertice_03_Museo.md",
	Dialogues = {
		Archivo = {
			Lines = {
				{ S = "Narrador", T = "Anuncios viejos, de hace cuarenta años. En el fondo de todos, un sol amarillo de verdad.", Shot = "General" },
				{ S = "Narrador", T = "Los de después ya no tienen sol. Solo la Cúpula, el logo y la palabra «LUZ» en letras enormes." },
				{ S = "Cosme", T = "Le quitaron el sol a los anuncios, criatura. O se lo quitaron al cielo.", To = "Yo", A = "Nervous" },
			},
		},
		Placa = {
			Lines = {
				{ S = "Narrador", T = "«El Primer Cliente. Firmó la venta de Vértice a MegaVerso hace 150 años. Gracias por elegirnos».", Shot = "General" },
				{ S = "Cosme", T = "¿Firmó la venta? Entonces no era un cliente. Era el alcalde.", To = "Yo", A = "Ask" },
			},
		},
		Plan = {
			Lines = {
				{
					S = "AbrilCruz",
					T = "El Museo de la Luz. «La historia oficial de Vértice». Entrada gratis, salida pagando.",
					To = "Yo",
					Shot = "Medio:AbrilCruz",
					G = "Point",
					Effects = { Scene = "Vertice3_G1_Musica" },
				},
				{ S = "AbrilCruz", T = "(susurrando) El archivo está en la sala del fondo. Entra, mira y sal. La seguridad vigila la puerta.", To = "Yo" },
				{ S = "Cosme", T = "Colarse en un museo. Esto me recuerda a mi juventud. Bueno, a toda mi vida.", To = "Yo", A = "Happy" },
			},
		},
		Salida = {
			Lines = {
				{
					S = "AbrilCruz",
					T = "Antes de la Cúpula había sol. Y lo borraron de los anuncios. Como si nunca hubiera estado.",
					To = "Yo",
					Shot = "Medio:AbrilCruz",
					A = "Nervous",
					Effects = { Scene = "Vertice3_G5_Musica" },
				},
				{ S = "Cosme", T = "Nadie tapa un cielo bonito, Abril. Se tapa lo que no se quiere ver.", To = "Yo", A = "Nod" },
				{
					S = "AbrilCruz",
					T = "Y no has tocado la cuenta. Ni un euro de la cuenta. Eso aquí abajo vale más que la puntuación.",
					To = "Yo",
					A = "Happy",
					If = { Flags = { "VerticeCuentaLimpia" } },
				},
				{
					S = "AbrilCruz",
					T = "Y te has llevado el dinero. Lo entiendo. Pero la Contable lo cuenta todo, hasta lo que falta.",
					To = "Yo",
					If = { Flags = { "VerticeDineroCuenta" } },
				},
			},
		},
		Terminal = {
			Lines = {
				{
					S = "Narrador",
					T = "El terminal de la Contable está encendido. Una cuenta de MegaVerso, abierta. Trescientos euros a un toque.",
					Shot = "General",
				},
				{ S = "Cosme", T = "Una máquina que deja las cuentas abiertas. O se le ha olvidado… o quiere ver qué haces.", To = "Yo", A = "ThinkChin" },
			},
		},
	},
	Scenes = {
		Vertice3_G1_Musica = { Light = true, Duration = 23, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Vertice3_G5_Musica = { Light = true, Duration = 29.8, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
	},
	Steps = {},
}
