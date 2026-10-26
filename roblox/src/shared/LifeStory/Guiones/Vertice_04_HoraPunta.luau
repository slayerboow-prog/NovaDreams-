-- GUION REESCRITO de Vertice_04_HoraPunta (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Vertice_04_HoraPunta.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Vertice_04_HoraPunta
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Vertice_04_HoraPunta.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Vertice_04_HoraPunta.md",
	Dialogues = {
		Aviso = {
			Lines = {
				{
					S = "Gil",
					T = "Os han visto salir del Museo. No sé quién ha avisado. Yo no. Yo no he sido.",
					To = "Yo",
					Shot = "Medio:Gil",
					A = "Nervous",
					Effects = { Scene = "Vertice4_G1_Musica" },
				},
				{ S = "Gil", T = "Vienen los drones de cobro. Si os tocan, os embargan hasta los zapatos. ¡Corred al Rastro!", To = "Yo", G = "Point" },
				{
					S = "Gil",
					T = "(susurrando) Y hay más. La Contable ha visto el dinero que falta. Va a mandar algo más que drones.",
					To = "Yo",
					If = { Flags = { "VerticeDineroCuenta" } },
				},
			},
		},
		Rastro = {
			Lines = {
				{
					S = "AbrilCruz",
					T = "Aquí abajo no entran las cámaras. Respira. Nadie te va a multar por respirar. Todavía.",
					To = "Yo",
					Shot = "Medio:AbrilCruz",
					A = "Nod",
					Effects = { Scene = "Vertice4_G2_Musica" },
				},
				{ S = "AbrilCruz", T = "Alguien avisó a MegaVerso. Solo seis personas sabían lo del Museo.", To = "Yo" },
				{ S = "AbrilCruz", T = "Mi hermano Simón es jefe de seguridad. No quiero pensar que ha sido él. No quiero.", To = "Yo", A = "Sad" },
			},
		},
	},
	Scenes = {
		Vertice4_G1_Musica = { Light = true, Duration = 23.2, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Vertice4_G2_Musica = { Light = true, Duration = 21.1, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
	},
	Steps = {},
}
