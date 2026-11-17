-- GUION REESCRITO de Saga_11_Cronos (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_11_Cronos.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_11_Cronos
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_11_Cronos.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_11_Cronos.md",
	Dialogues = {
		Cronos = {
			Lines = {
				{ S = "CazadorTiempo", T = "Guerrero. Necesito su ayuda. No es algo que la Aduana pida a menudo.", To = "Yo" },
				{
					S = "CazadorTiempo",
					T = "Usted completó el registro de Valmar en un solo día. Hoy le pido algo más difícil.",
					To = "Yo",
					If = { Memories = { "VentanillaAduana" } },
				},
				{
					S = "CazadorTiempo",
					T = "Alguien está presentando permisos de Fusión con mi sello. Yo no los he firmado.",
					To = "Yo",
					If = { Memories = { "VentanillaAduana" } },
				},
				{ S = "CazadorTiempo", T = "Mi sello tiene una muesca en el borde. Estos no.", To = "Yo", If = { Memories = { "VentanillaAduana" } } },
				{
					S = "CazadorTiempo",
					T = "Si la Aduana los aprueba, la Fusión será legal. Y contra algo legal, ni siquiera yo puedo hacer nada.",
					To = "Yo",
					If = { Memories = { "VentanillaAduana" } },
				},
			},
		},
		Formularios = {
			Lines = { { S = "Narrador", T = "Doce permisos de Fusión, todos sellados. Al sello le falta la muesca. La firma pone «Crono», sin la ese." } },
		},
		Pillada = {
			Lines = {
				{ S = "AgenteGris2", T = "Está bien. Me rindo. Yo solo los entregaba. El doctor Cósimo dijo que era un trámite.", To = "Yo" },
				{ S = "AgenteGris2", T = "En el Consorcio no preguntamos. Los que preguntan dejan de trabajar allí. Y de estar en ningún sitio.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Durante cuatrocientos años he registrado daños sin preguntar quién los causaba.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Hoy sé quién los causa. Y no puedo seguir siendo neutral.", To = "Yo" },
				{ S = "CazadorTiempo", T = "A partir de hoy, la Aduana está de su lado. Al menos esta parte de la Aduana.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Tome. Un reloj de arena de la Aduana. Si la situación se vuelve imposible, gírelo. Vendré.", To = "Yo" },
				{
					Ask = "Cronos te mira: «¿Qué opinas tú?»",
					Options = {
						{
							T = "«Que ayude a pararlo todo. Una segunda oportunidad.»",
							Effects = { Flags = { "CronosAliado", "GrisArrepentida" }, Traits = { Empatia = 1 } },
							Then = { { S = "AgenteGris2", T = "¿Ayudar? …Nadie me había ofrecido nada sin condiciones. Acepto." } },
						},
						{
							T = "«Que cumpla su castigo. Las normas son las normas.»",
							Effects = { Flags = { "CronosAliado" }, Traits = { Responsabilidad = 1 } },
							Then = { { S = "CazadorTiempo", T = "Las normas son las normas. Responderá ante la Aduana." } },
						},
					},
				},
			},
		},
		Ventanilla = {
			Lines = {
				{ S = "Funcionaria", T = "Permisos falsos. Sí. Los he notado. Están demasiado limpios.", To = "Yo" },
				{ S = "Funcionaria", T = "Los trajo esta mañana una mujer de gris. Sonreía sin parpadear.", To = "Yo" },
				{ S = "Funcionaria", T = "Sigue ahí fuera. Esperando a que se aprueben.", To = "Yo" },
			},
		},
	},
	Scenes = {
		Saga_11_G4_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "CazadorTiempo", Npc = "CazadorTiempo" } } },
				Dialogue = { { At = 0.4, S = "CazadorTiempo", T = "¡Es ella! ¡Que no llegue a la Grieta!", To = "Yo" } },
			},
		},
	},
	Steps = { ["3"] = { Effects = { Scene = "Saga_11_G4_Entra" } } },
}
