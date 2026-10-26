-- GUION REESCRITO de Vertice_05_Luz (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Vertice_05_Luz.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Vertice_05_Luz
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Vertice_05_Luz.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Vertice_05_Luz.md",
	Dialogues = {
		Anden = {
			Lines = {
				{
					S = "AbrilCruz",
					T = "Cada noche llegan cien cajas de luz embotellada. Las descargan robots y se van sin facturas.",
					To = "Yo",
					Shot = "Medio:AbrilCruz",
					G = "Point",
					Effects = { Scene = "Vertice5_G1_Musica" },
				},
				{ S = "AbrilCruz", T = "(susurrando) Nadie sabe de dónde salen. MegaVerso dice que la fabrica. Pero no hay fábrica tan grande.", To = "Yo" },
				{
					S = "Cosme",
					T = "Una ciudad que compra su propia luz a escondidas. Esto huele a lo de siempre, criatura: a alguien que gana.",
					To = "Yo",
					A = "ThinkChin",
				},
				{ S = "AbrilCruz", T = "Mira una etiqueta mientras vigilo la vía. Rápido, que el tren vuelve en dos minutos.", To = "Yo", A = "Nod" },
			},
		},
		Caja = {
			Lines = {
				{ S = "Narrador", T = "«Luz embotellada · Lote 0001 · Proveedor: V. · Pagado por: O. Brum».", Shot = "General" },
				{
					S = "Cosme",
					T = "O. Brum es Ofelia Brum, la directora. Pero ¿quién es V.? En esta ciudad todo tiene nombre. Menos eso.",
					To = "Yo",
					A = "Nervous",
				},
			},
		},
	},
	Scenes = { Vertice5_G1_Musica = { Light = true, Duration = 32.7, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } } },
	Steps = {},
}
