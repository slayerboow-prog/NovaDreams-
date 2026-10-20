-- GUION REESCRITO de Nivalis_01_Oscuras (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Nivalis_01_Oscuras.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Nivalis_01_Oscuras
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Nivalis_01_Oscuras.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Nivalis_01_Oscuras.md",
	Dialogues = {
		Silencio = {
			Lines = {
				{
					S = "Tila",
					T = "Soy Tila. Farolera. Enciendo los faroles del barrio. Y nadie se fija en quien enciende los faroles.",
					To = "Yo",
					Shot = "Medio:Tila",
					A = "Nod",
					Effects = { Scene = "Nivalis1_G2_Musica" },
				},
				{ S = "Tila", T = "Mira el cielo. ¿Ves la aurora sobre el Palacio? Aquí no llega. El Regente se la quitó al barrio.", To = "Yo", G = "Point" },
				{
					S = "Tila",
					T = "Dicen que nos portamos mal. Que cantamos. Ahora cantar está prohibido. Y hablar alto en la calle, también.",
					To = "Yo",
					A = "Sad",
				},
				{ S = "Tila", T = "(susurrando) Dentro de poco empieza la hora del silencio. Si quieres saber más, sígueme. Sin hacer ruido.", To = "Yo" },
			},
		},
		Tila = {
			Lines = {
				{
					S = "Tila",
					T = "Eh. Tú. El de la nave. Ven a la hoguera antes de que se te caigan las orejas.",
					To = "Yo",
					Shot = "Medio:Tila",
					A = "Nod",
					Effects = { Scene = "Nivalis1_G1_Musica" },
				},
				{ S = "Tila", T = "Has salido de la muralla sin abrigo. Aquí eso no lo hace ni el Regente. Y el Regente no tiene corazón.", To = "Yo" },
				{ S = "Tila", T = "Mira tu medidor. Fuera, el frío sube siempre. Junto a una hoguera, en las Termas o en casa, baja.", To = "Yo", G = "Point" },
				{ S = "Tila", T = "Toma: un abrigo de lana de lanudo y dos sopas de Brisa. Bébete una ya. No me mires así: bébetela.", To = "Yo" },
				{ Effects = { Items = { AbrigoLana = 1, SopaAlbor = 2 } } },
			},
		},
	},
	Scenes = {
		Nivalis1_G1_Musica = { Light = true, Duration = 31.8, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Nivalis1_G2_Musica = { Light = true, Duration = 34.2, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
	},
	Steps = {},
}
