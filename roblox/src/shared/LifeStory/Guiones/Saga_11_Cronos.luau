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
				{ S = "CazadorTiempo", T = "Pequeño humano. Bueno… ya no tan pequeñ{o/a}.", To = "Yo", Pause = 0.9 },
				{ S = "CazadorTiempo", T = "Mi agenda del futuro decía que hoy hablaríamos.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Usted sobrevivió a tres ventanillas en un solo día.", To = "Yo", If = { Memories = { "VentanillaAduana" } } },
				{ S = "CazadorTiempo", T = "Hoy le pido algo más difícil.", To = "Yo", If = { Memories = { "VentanillaAduana" } } },
				{ S = "Yo", T = "¿Qué?", If = { Memories = { "VentanillaAduana" } } },
				{ S = "CazadorTiempo", T = "Alguien está metiendo formularios falsos en la Aduana.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Permisos de Fusión dimensional.", To = "Yo", Pause = 0.9 },
				{ S = "CazadorTiempo", T = "Sellados con MI sello. Yo no los he sellado.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Mi sello tiene un arañazo. Estos no.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Si la Aduana aprueba esos permisos…", To = "Yo" },
				{
					S = "CazadorTiempo",
					T = "Y contra algo legal… Ni yo puedo hacer nada. Necesito pruebas. Y alguien rápido. Confirmado.",
					To = "Yo",
					Pause = 1.8,
				},
				{ S = "CazadorTiempo", T = "Corro poco.", To = "Yo", Pause = 0.9 },
			},
		},
		Formularios = {
			Lines = {
				{ S = "CazadorTiempo", T = "Ahí está. Sin S. Ni siquiera saben escribir mi nombre.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Y aun así pretenden falsificar mi sello.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Esto es peor de lo que pensaba.", To = "Yo" },
			},
		},
		Pillada = {
			Lines = {
				{ S = "AgenteGris2", T = "¡Vale! ¡Vale! ¡Me rindo!", To = "Yo" },
				{ S = "AgenteGris2", T = "Solo soy de atención al cliente.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Falsificación de formulario temporal.", To = "Yo", Pause = 0.9 },
				{ S = "CazadorTiempo", T = "Treinta años de papeleo en la Aduana. Sin sello propio.", To = "Yo", Pause = 0.9 },
				{ S = "Yo", T = "Que ayude a pararlo todo." },
				{ S = "AgenteGris2", T = "¿Sin multa?", To = "Yo", Pause = 0.9 },
				{ S = "CazadorTiempo", T = "No he dicho eso. He dicho que tendrás una segunda oportunidad.", To = "Yo" },
				{ S = "AgenteGris2", T = "Nadie me había ofrecido algo sin letra pequeña. Vale.", To = "Yo" },
				{ S = "Yo", T = "Que cumpla su castigo." },
				{ S = "CazadorTiempo", T = "Una respuesta perfectamente burocrática. Me gusta.", To = "Yo", Pause = 0.9 },
				{ S = "AgenteGris2", T = "¿Cuánto papeleo?", To = "Yo" },
				{ S = "CazadorTiempo", T = "Bastante. Durante cuatrocientos años he perseguido a quien se salta el tiempo.", To = "Yo", Pause = 0.9 },
				{
					S = "CazadorTiempo",
					T = "Hoy me doy cuenta de algo. Es el Consorcio. A partir de hoy… Estoy de tu lado. Con formulario.",
					To = "Yo",
					Pause = 0.9,
				},
				{ S = "CazadorTiempo", T = "Cuando las cosas se pongan feas… Y llegaré. Pero llegaré.", To = "Yo" },
				{
					Ask = "Cronos te mira: «¿Qué opinas tú?»",
					Options = {
						{
							T = "«Que ayude a pararlo todo. Una segunda oportunidad.»",
							Effects = { Flags = { "CronosAliado", "GrisArrepentida" }, Traits = { Empatia = 1 } },
							Then = { { S = "AgenteGris2", T = "¿Yo? ¿Ayudar? …Nunca nadie me había ofrecido algo sin letra pequeña. Acepto. De verdad. Sin sonreír." } },
						},
						{
							T = "«Que cumpla su castigo. Las normas son las normas.»",
							Effects = { Flags = { "CronosAliado" }, Traits = { Responsabilidad = 1 } },
							Then = { { S = "CazadorTiempo", T = "Las normas son las normas. Lo diré en el tribunal. Y lo pondré en un póster." } },
						},
					},
				},
			},
		},
		Ventanilla = {
			Lines = {
				{ S = "Funcionaria", T = "Esa cola es para paquetes.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Yo tengo formularios.", To = "Yo" },
				{ S = "Funcionaria", T = "Entonces necesita la cola de formularios.", To = "Yo" },
				{ S = "CazadorTiempo", T = "¿Cuál es?", To = "Yo", Pause = 0.9 },
				{ S = "Funcionaria", T = "Esa.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Cuando finalmente llegan a la ventanilla:", To = "Yo" },
				{ S = "CazadorTiempo", T = "Necesitamos información sobre unos formularios falsos.", To = "Yo" },
				{ S = "Funcionaria", T = "¿Formularios falsos? Hij{o/a}…", To = "Yo" },
				{ S = "Funcionaria", T = "Llevo trescientos años en ventanillas.", To = "Yo" },
				{ S = "Funcionaria", T = "Los formularios falsos huelen diferente.", To = "Yo" },
				{ S = "Funcionaria", T = "Huelen a colonia cara.", To = "Yo", Pause = 0.9 },
				{ S = "CazadorTiempo", T = "Interesante.", To = "Yo" },
				{ S = "Funcionaria", T = "Esta mañana una señora de gris dejó una carpeta. Ahí la tienes.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Esa.", To = "Yo" },
			},
		},
	},
	Scenes = {
		Saga_11_G4_Entra = {
			Light = true,
			Duration = 10.8,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "CazadorTiempo", Npc = "CazadorTiempo" } } },
				Dialogue = {
					{ At = 0.4, S = "CazadorTiempo", T = "¡Alto! ¡Recordad que yo corro poco!", To = "Yo" },
					{ At = 3.5, S = "Narrador", T = "Otro NPC señala: «¡Van corriendo!»" },
					{ At = 7.4, S = "CazadorTiempo", T = "No volveré a hacer eso. Nunca.", To = "Yo" },
				},
			},
		},
	},
	Steps = { ["3"] = { Effects = { Scene = "Saga_11_G4_Entra" } } },
}
