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
				{ S = "CazadorTiempo", T = "Pequeño humano.", To = "Yo", Pause = 0.9 },
				{ S = "CazadorTiempo", T = "Bueno… ya no tan pequeñ{o/a}.", To = "Yo", Pause = 0.9 },
				{ S = "CazadorTiempo", T = "Usted sobrevivió a tres ventanillas en un solo día.", To = "Yo", If = { Memories = { "VentanillaAduana" } } },
				{ S = "CazadorTiempo", T = "Hoy le pido algo más difícil.", To = "Yo", If = { Memories = { "VentanillaAduana" } } },
				{ S = "Yo", T = "¿Qué?", If = { Memories = { "VentanillaAduana" } } },
				{ S = "CazadorTiempo", T = "Alguien está metiendo formularios falsos en la Aduana.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Permisos de Fusión dimensional.", To = "Yo", Pause = 0.9 },
				{ S = "CazadorTiempo", T = "Sellados con MI sello.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Yo no los he sellado.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Mi sello tiene un arañazo.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Estos no.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Si la Aduana aprueba esos permisos…", To = "Yo" },
				{ S = "CazadorTiempo", T = "Y contra algo legal…", To = "Yo", Pause = 1.8 },
				{ S = "CazadorTiempo", T = "Ni yo puedo hacer nada.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Necesito pruebas.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Y alguien rápido.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Confirmado.", To = "Yo", Pause = 0.9 },
				{ S = "CazadorTiempo", T = "Corro poco.", To = "Yo", Pause = 0.9 },
			},
		},
		Formularios = {
			Lines = {
				{ S = "CazadorTiempo", T = "Ahí está.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Y aun así pretenden falsificar mi sello.", To = "Yo", Pause = 0.9 },
				{ S = "CazadorTiempo", T = "Esto es peor de lo que pensaba.", To = "Yo" },
			},
		},
		Pillada = {
			Effects = { Flags = { "CronosAliado", "GrisArrepentida" } },
			Lines = {
				{ S = "AgenteGris2", T = "¡Vale! ¡Vale! ¡Me rindo!", To = "Yo" },
				{ S = "AgenteGris2", T = "Solo soy de atención al cliente.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Falsificación de formulario temporal.", To = "Yo", Pause = 0.9 },
				{ S = "CazadorTiempo", T = "Treinta años de papeleo en la Aduana.", To = "Yo", Pause = 0.9 },
				{ S = "CazadorTiempo", T = "Sin sello propio.", To = "Yo" },
				{ S = "Yo", T = "Que ayude a pararlo todo." },
				{ S = "AgenteGris2", T = "¿Sin multa?", To = "Yo", Pause = 0.9 },
				{ S = "CazadorTiempo", T = "No he dicho eso.", To = "Yo" },
				{ S = "CazadorTiempo", T = "He dicho que tendrás una segunda oportunidad.", To = "Yo" },
				{ S = "AgenteGris2", T = "Nadie me había ofrecido algo sin letra pequeña.", To = "Yo" },
				{ S = "AgenteGris2", T = "Vale.", To = "Yo", Pause = 0.9 },
				{ S = "Yo", T = "Que cumpla su castigo." },
				{ S = "CazadorTiempo", T = "Una respuesta perfectamente burocrática.", To = "Yo", Pause = 0.9 },
				{ S = "CazadorTiempo", T = "Me gusta.", To = "Yo" },
				{ S = "AgenteGris2", T = "¿Cuánto papeleo?", To = "Yo" },
				{ S = "CazadorTiempo", T = "Bastante.", To = "Yo", Pause = 0.9 },
				{ S = "CazadorTiempo", T = "Durante cuatrocientos años he perseguido a quien se salta el tiempo.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Hoy me doy cuenta de algo.", To = "Yo", Pause = 0.9 },
				{ S = "CazadorTiempo", T = "Es el Consorcio.", To = "Yo" },
				{ S = "CazadorTiempo", T = "A partir de hoy…", To = "Yo", Pause = 0.9 },
				{ S = "CazadorTiempo", T = "Estoy de tu lado.", To = "Yo", Pause = 0.9 },
				{ S = "CazadorTiempo", T = "Con formulario.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Cuando las cosas se pongan feas…", To = "Yo" },
				{ S = "CazadorTiempo", T = "Y llegaré.", To = "Yo", Pause = 0.9 },
				{ S = "CazadorTiempo", T = "Pero llegaré.", To = "Yo" },
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
				{ S = "Funcionaria", T = "¿Formularios falsos?", To = "Yo" },
				{ S = "Funcionaria", T = "Hij{o/a}…", To = "Yo", Pause = 0.9 },
				{ S = "Funcionaria", T = "Llevo trescientos años en ventanillas.", To = "Yo" },
				{ S = "Funcionaria", T = "Huelen a colonia cara.", To = "Yo", Pause = 0.9 },
				{ S = "CazadorTiempo", T = "Interesante.", To = "Yo" },
				{ S = "Funcionaria", T = "Esta mañana una señora de gris dejó una carpeta.", To = "Yo" },
				{ S = "Funcionaria", T = "Ahí la tienes.", To = "Yo", Pause = 0.9 },
				{ S = "CazadorTiempo", T = "Esa.", To = "Yo" },
			},
		},
	},
	Scenes = {
		Saga_11_G4_Entra = {
			Light = true,
			Duration = 15.1,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "CazadorTiempo", Npc = "CazadorTiempo" } } },
				Dialogue = {
					{ At = 0.4, S = "CazadorTiempo", T = "¡Alto!", To = "Yo" },
					{ At = 2.4, S = "CazadorTiempo", T = "¡Recordad que yo corro poco!", To = "Yo" },
					{ At = 5.1, S = "Narrador", T = "Otro NPC señala: «¡Van corriendo!»" },
					{ At = 9.1, S = "CazadorTiempo", T = "No volveré a hacer eso.", To = "Yo" },
					{ At = 12.4, S = "CazadorTiempo", T = "Nunca.", To = "Yo" },
				},
			},
		},
	},
	Steps = { ["3"] = { Effects = { Scene = "Saga_11_G4_Entra" } } },
}
