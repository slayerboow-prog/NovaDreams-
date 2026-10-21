-- GUION REESCRITO de Mar_01_Concha (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Mar_01_Concha.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Mar_01_Concha
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Mar_01_Concha.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Mar_01_Concha.md",
	Dialogues = {
		Plaza = {
			Lines = {
				{
					S = "Ilun",
					T = "¡Has venido! Sabía que la concha funcionaría. Mi abuela decía que era una tontería.",
					To = "Yo",
					A = "Happy",
					Effects = { Scene = "Mar01_G3_Musica" },
				},
				{
					S = "Ilun",
					T = "Bienvenid{o/a} a Nácara. Esto es la Plaza de la Corriente. El agua sube por esa columna y se lleva los cantos hasta arriba.",
					To = "Yo",
					G = "Point",
				},
				{
					S = "Ilun",
					T = "Pero no grites, ¿vale? Si la Guardia ve a un seco nadando por aquí, se monta un lío de los de cien años.",
					To = "Yo",
					A = "ThinkChin",
				},
				{ S = "Ilun", T = "Ven. Te enseño lo bonito. Rápido y sin hacer burbujas de más.", To = "Yo" },
			},
		},
		Secreto = {
			Lines = {
				{
					S = "Ilun",
					T = "¿Has visto las conchas? Dentro tienen aire. Los secos podéis dormir ahí. Bueno, si alguien os alquila una.",
					To = "Yo",
					A = "Ask",
					Effects = { Scene = "Mar01_G5_Musica" },
				},
				{ S = "Ilun", T = "Y los jardines son de Tomé. Si tocas un caracol, que sea para quitarlo. Odia a los caracoles.", To = "Yo", A = "Nod" },
				{ S = "Ilun", T = "Antes de que el faro se apagara, la gente de arriba bajaba a comerciar. Mi abuela se acuerda.", To = "Yo", A = "ThinkChin" },
				{ S = "Ilun", T = "Luego dejaron de venir. Y los mayores dijeron: «Nos han olvidado.»", To = "Yo" },
				{ S = "Ilun", T = "Pero aquí estás. Así que no nos han olvidado. Del todo.", To = "Yo", A = "Happy" },
			},
		},
	},
	Scenes = {
		Mar01_G3_Musica = { Light = true, Duration = 31.7, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Mar01_G5_Musica = { Light = true, Duration = 35.5, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
	},
	Steps = {
		["1"] = { Set = { Text = "Sigue el canto de la concha hasta las Ruinas de Valmar la Vieja" } },
		["2"] = { Set = { Text = "Llega al arco de kelp" } },
		["4"] = { Set = { Text = "Ilun te enseña Nácara a escondidas" } },
	},
}
