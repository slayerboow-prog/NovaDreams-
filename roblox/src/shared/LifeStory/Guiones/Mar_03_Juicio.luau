-- GUION REESCRITO de Mar_03_Juicio (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Mar_03_Juicio.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Mar_03_Juicio
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Mar_03_Juicio.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Mar_03_Juicio.md",
	Dialogues = {
		Guardia = {
			Lines = {
				{
					S = "GuardiaConsejo",
					T = "Tú. El de las burbujas. Un seco nadando por Nácara. Hacía cien años que no pasaba.",
					To = "Yo",
					A = "HandsOnHips",
					Effects = { Scene = "Mar03_G1_Musica" },
				},
				{ S = "GuardiaConsejo", T = "No te asustes. Aquí no se hace daño a nadie. Pero la Guardiana quiere verte. Ahora.", To = "Yo" },
				{ S = "GuardiaConsejo", T = "Entra por la puerta del medio. Y no toques nada.", To = "Yo", G = "Point" },
			},
		},
		Veredicto = {
			Lines = {
				{
					S = "Maresa",
					T = "Me han contado lo de tu turno. Las algas no mienten, y las perlas-farola tampoco.",
					To = "Yo",
					A = "Happy",
					Effects = { Scene = "Mar03_G5_Musica" },
				},
				{ S = "Maresa", T = "Has cumplido la primera prueba. Hay más. Siempre hay más.", To = "Yo", A = "Nod" },
				{ S = "Maresa", T = "Puedes quedarte en Nácara. Alquila una concha en el barrio, si quieres dormir con aire.", To = "Yo" },
				{ S = "Maresa", T = "Pero recuerda: la Marea Callada no te quiere aquí. Y algunos de los míos, tampoco.", To = "Yo", A = "ThinkChin" },
			},
		},
	},
	Scenes = {
		Mar03_G1_Musica = { Light = true, Duration = 19.6, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Mar03_G5_Musica = { Light = true, Duration = 27.1, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
	},
	Steps = {
		["3"] = { Set = { Text = "¿Por qué ha bajado un seco a Nácara?" } },
		["4"] = { Set = { Text = "Primera prueba: haz un turno para una Corriente" } },
	},
}
