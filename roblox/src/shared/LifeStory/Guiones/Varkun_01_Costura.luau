-- GUION REESCRITO de Varkun_01_Costura (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Varkun_01_Costura.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Varkun_01_Costura
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Varkun_01_Costura.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Varkun_01_Costura.md",
	Scenes = {
		Varkun1_G1_Fin = {
			Light = true,
			Duration = 50.2,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Cosme", Npc = "Cosme" } },
					{ At = 0, Use = { Key = "Pip", Npc = "Pip" } },
					{ At = 0, Use = { Key = "NILDA", Npc = "NILDA" } },
				},
				Dialogue = {
					{ At = 0.4, S = "Narrador", T = "La señal viene de un carguero del Gremio. O de lo que queda de él." },
					{
						At = 5.9,
						S = "NILDA",
						T = "Contacto visual. Tres trozos de casco. Las cápsulas de escape salieron a tiempo: no queda nadie a bordo.",
						To = "Yo",
						A = "ThinkChin",
					},
					{
						At = 14.1,
						S = "Cosme",
						T = "Esto no lo han hecho unos piratas, criatura. Los piratas rompen. Esto está… descosido.",
						To = "Yo",
						A = "HandsOnHips",
					},
					{
						At = 21.1,
						S = "Pip",
						T = "Señor, hay hilos. Hilos de verdad, uniendo los trozos. Como si alguien hubiera intentado zurcir una nave.",
						To = "Yo",
						A = "ArmsCrossed",
					},
					{ At = 29.4, S = "NILDA", T = "Aviso. Tres firmas pequeñas detrás de los restos. Rápidas. Muy rápidas.", To = "Yo", A = "Nod" },
					{
						At = 35.3,
						S = "Cosme",
						T = "¡Ja! Agujas. Así las voy a llamar. Pinchan, pasan de largo y vuelven. Como mi dentista.",
						To = "Yo",
						G = "Point",
					},
					{
						At = 42.3,
						S = "NILDA",
						T = "No llevan piloto: son tela tensada con una luz dentro. No te quedes quieto, que te pinchan.",
						To = "Yo",
						A = "No",
					},
				},
				Music = { { At = 0, Intensity = "Tension" }, { At = 24.8, Intensity = "Tension" } },
			},
		},
		Varkun1_G3_Entra = {
			Light = true,
			Duration = 24.5,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "NILDA", Npc = "NILDA" } },
					{ At = 0, Use = { Key = "Cosme", Npc = "Cosme" } },
					{ At = 0, Use = { Key = "Pip", Npc = "Pip" } },
				},
				Dialogue = {
					{
						At = 0.4,
						S = "Pip",
						T = "Hay un contenedor intacto en el centro del carguero. Dentro, un carrete. Pesa más de lo que debería.",
						To = "Yo",
						A = "Shrug",
					},
					{
						At = 8.3,
						S = "NILDA",
						T = "Mi abuela decía que lo que pesa más de la cuenta es porque lleva algo dentro. Recógelo con cuidado.",
						To = "Yo",
						A = "Nervous",
						Mood = "Fear",
					},
					{
						At = 16.2,
						S = "Cosme",
						T = "Llévalo a la Cénit. Allí tienen una caja fuerte que ni yo sé abrir. Y mira que lo he intentado.",
						To = "Yo",
						A = "Happy",
						Mood = "Joy",
					},
				},
				Music = { { At = 0, Intensity = "Descubrimiento" } },
			},
		},
		Varkun1_G4_Entra = {
			Light = true,
			Duration = 32,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Pip", Npc = "Pip" } },
					{ At = 0, Use = { Key = "NILDA", Npc = "NILDA" } },
					{ At = 0, Use = { Key = "Cosme", Npc = "Cosme" } },
				},
				Dialogue = {
					{ At = 0.4, S = "Narrador", T = "En la Cénit, el carrete descansa dentro de la caja fuerte de la Vigilancia." },
					{ At = 6.6, S = "Cosme", T = "Hilo negro. Frío al tacto. Y nadie del Gremio sabe de dónde ha salido.", To = "Yo", A = "Lean" },
					{ At = 12.4, S = "Pip", T = "Señor, ¿por qué alguien coserá naves rotas en mitad del espacio?", To = "Yo", A = "Ask" },
					{
						At = 17.7,
						S = "Cosme",
						T = "No lo sé. Pero quien sabe coser, también sabe descoser. Y eso me da más miedo que los piratas.",
						To = "Yo",
						A = "No",
					},
					{ At = 25.2, S = "NILDA", T = "Guardaré la señal original. Tiene un ritmo. Como una costura hecha a mano.", To = "Yo", A = "ThinkChin" },
				},
				Music = { { At = 0, Intensity = "Descubrimiento" } },
			},
		},
	},
	Steps = {
		["1"] = { Effects = { Scene = "Varkun1_G1_Fin" } },
		["2"] = { Effects = { Scene = "Varkun1_G3_Entra" } },
		["3"] = { Effects = { Scene = "Varkun1_G4_Entra" } },
	},
}
