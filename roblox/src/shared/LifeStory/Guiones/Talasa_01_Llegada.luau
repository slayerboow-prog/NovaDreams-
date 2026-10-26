-- GUION REESCRITO de Talasa_01_Llegada (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Talasa_01_Llegada.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Talasa_01_Llegada
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Talasa_01_Llegada.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Talasa_01_Llegada.md",
	Dialogues = {
		Cuarentena = {
			Lines = {
				{
					S = "AlmiranteCoria",
					T = "Forasteros. Llegáis en mal momento. Abisalia está en cuarentena.",
					To = "Yo",
					Shot = "Medio:AlmiranteCoria",
					Effects = { Scene = "Talasa1_G2_Musica" },
				},
				{ S = "AlmiranteCoria", T = "Hay un coral negro en el fondo que se come el metal. Pilotes, barcos, cascos. Todo.", To = "Yo", G = "Point" },
				{ S = "Cosme", T = "¿Un coral que come metal? Eso no lo hace ningún coral que yo conozca.", To = "Yo", A = "Ask" },
				{ S = "AlmiranteCoria", T = "Este no es de nadie que conozcas. La Cúpula Honda está cerrada. Mil personas dentro.", To = "Yo", A = "No" },
				{
					S = "AlmiranteCoria",
					T = "Si vais a quedaros, trabajad. Tomad: un traje de presión, tres cargas de oxígeno y un permiso.",
					To = "Yo",
					A = "Nod",
				},
				{ S = "AlmiranteCoria", T = "Hasta cuarenta metros. Ni uno más. Y si veis a la Dra. Noa Ferrán, me avisáis.", To = "Yo" },
			},
		},
		Llegada = {
			Lines = {
				{
					S = "Cosme",
					T = "Tálasa, criatura. El planeta más rico de la galaxia. Aquí el agua es más barata que el aire.",
					To = "Yo",
					Shot = "Medio:Cosme",
					A = "Happy",
					Effects = { Scene = "Talasa1_G1_Musica" },
				},
				{ S = "Cosme", T = "Mira esas torres blancas. Y las balsas de abajo, de tablas y lona. Eso antes no estaba.", To = "Yo", G = "Point" },
				{ S = "Cosme", T = "Huele a sal, a algas… y a miedo. Conozco ese olor. Vamos a ver qué pasa.", To = "Yo", A = "ThinkChin" },
			},
		},
	},
	Scenes = {
		Talasa1_G1_Musica = { Light = true, Duration = 22.3, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Talasa1_G2_Musica = { Light = true, Duration = 40.5, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
	},
	Steps = {},
}
