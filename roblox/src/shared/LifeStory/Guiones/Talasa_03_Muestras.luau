-- GUION REESCRITO de Talasa_03_Muestras (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Talasa_03_Muestras.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Talasa_03_Muestras
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Talasa_03_Muestras.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Talasa_03_Muestras.md",
	Dialogues = {
		Microscopio = {
			Lines = {
				{
					S = "NoaFerran",
					T = "Tres. Perfectas. Y siguen latiendo dentro del tubo. Dejadlas aquí, con cuidado.",
					To = "Yo",
					Shot = "Medio:NoaFerran",
					A = "Nod",
					Effects = { Scene = "Talasa3_G2_Musica" },
				},
				{ S = "NoaFerran", T = "Ahora mira por el microscopio. Enfoca despacio. No es lo que parece.", To = "Yo", A = "Lean" },
			},
		},
		Resultado = {
			Lines = {
				{
					S = "Cosme",
					T = "Eso no es coral, criatura. Son máquinas. Máquinas diminutas, cogidas de la mano.",
					To = "Yo",
					Shot = "PrimerPlano:NoaFerran",
					A = "Nervous",
					Effects = { Scene = "Talasa3_G3_Musica" },
				},
				{ S = "NoaFerran", T = "Comen metal y hacen más máquinas. Y crecen hacia la ciudad. Hacia la luz.", To = "Yo", A = "Sad" },
				{ S = "NoaFerran", T = "(susurrando) Alguien las hizo para salvar el arrecife. Y funcionó. Hasta que dejó de funcionar.", To = "Yo" },
				{ S = "Cosme", T = "Hablas como si conocieras a ese alguien.", To = "Yo", A = "ThinkChin" },
				{ S = "NoaFerran", T = "Hablo como alguien que no duerme. Gracias por bajar. De verdad.", To = "Yo", A = "No" },
			},
		},
		Voluntaria = {
			Lines = {
				{
					S = "NoaFerran",
					T = "¿Vosotros sois los de la nave? Bien. Necesito manos. Las mías tiemblan desde hace días.",
					To = "Yo",
					Shot = "Medio:NoaFerran",
					A = "Nod",
					Effects = { Scene = "Talasa3_G1_Musica" },
				},
				{
					S = "NoaFerran",
					T = "Necesito tres muestras frescas del coral negro. Está en las Praderas de Luz, junto a las boyas amarillas.",
					To = "Yo",
					G = "Point",
				},
				{ S = "Cosme", T = "¿Y tú quién eres, si se puede saber?", To = "Yo", A = "Ask" },
				{ S = "NoaFerran", T = "Noa. Voluntaria. Limpio tubos y miro por el microscopio. Nadie más quiere hacerlo.", To = "Yo", A = "Shrug" },
				{ S = "NoaFerran", T = "Bajad por la escalerilla del Muelle. La presión sube rápido: usad una carga de oxígeno antes de subir.", To = "Yo" },
			},
		},
	},
	Scenes = {
		Talasa3_G1_Musica = { Light = true, Duration = 35.4, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Talasa3_G2_Musica = { Light = true, Duration = 14.1, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Talasa3_G3_Musica = { Light = true, Duration = 31.1, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
	},
	Steps = {},
}
