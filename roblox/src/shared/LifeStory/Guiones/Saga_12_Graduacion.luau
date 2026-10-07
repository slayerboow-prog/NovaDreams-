-- GUION REESCRITO de Saga_12_Graduacion (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_12_Graduacion.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_12_Graduacion
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_12_Graduacion.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_12_Graduacion.md",
	Dialogues = {
		Casualidad = {
			Lines = {
				{ S = "Cosme", T = "¡Qué casualidad! Pasaba por aquí. Con mi mejor bata. Y una aguja nueva.", To = "Yo" },
				{ S = "Cosme", T = "Y veinte chicles, por si acaso. Casualidad total. …Vale.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "He venido porque hoy es el día que marcaba la cuenta atrás.", To = "Yo" },
				{ S = "Cosme", T = "Y porque es tu graduación. Por las dos cosas. Más por la segunda.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "Y como ya sabes lo que eres…", To = "Yo", If = { Flags = { "SabeQueEsAncla" } } },
				{ S = "Cosme", T = "Sabes por qué hoy no me separo de ti.", To = "Yo", Pause = 0.9, If = { Flags = { "SabeQueEsAncla" } } },
				{ S = "Omar", T = "¿Ese es el vecino? ¿El de la gallina gigante? ¡Qué honor! ¿Me firma la bata?", To = "Yo" },
				{ S = "Cosme", T = "Me cae bien.", To = "Yo" },
				{ S = "Omar", T = "Oye… ¿Hoy no es el día de los números de la fiesta?", To = "Yo", If = { Flags = { "FiestaSaboteada" } } },
			},
		},
		Cosimo = {
			Lines = {
				{ S = "Cosimo", T = "¡Buenos días, Valmar! ¡Y enhorabuena a los graduados! Qué emocionante.", To = "Yo" },
				{ S = "Cosimo", T = "Me encantan las graduaciones. Hay tantos finales. Hola, Cosme. Hola, Ancla. Qué grande estás.", To = "Yo", Pause = 0.9 },
				{ S = "Cosimo", T = "La última vez que te vi en persona…", To = "Yo" },
				{ S = "Cosimo", T = "Y la última vez que te vi por cámara…", To = "Yo", Pause = 1.8, If = { Flags = { "EnseñasteCredencial" } } },
				{ S = "Cosimo", T = "Enseñabas una credencial de ayudante en mi oficina. Qué mono.", To = "Yo", If = { Flags = { "EnseñasteCredencial" } } },
				{ S = "Cosme", T = "Cósimo. Esto no es tuyo.", To = "Yo" },
				{ S = "Cosimo", T = "Todo es mío, Cosme. Lo será. Y tengo ayudantes. ¡Chicos!", To = "Yo" },
			},
		},
		Secuestro = {
			Lines = {
				{ S = "Cosimo", T = "Bravo. Bravísimo. Sabes pelear. Te lo enseñó él, ¿no?", To = "Yo", Pause = 0.9 },
				{ S = "Cosimo", T = "Siempre fue un buen profesor. Por eso me lo llevo.", To = "Yo" },
				{ S = "Cosme", T = "No. ¡Criatura! ¡No sueltes el Ancla!", To = "Yo" },
				{ S = "Cosme", T = "¡Pase lo que pase, quédate en esta Valmar! ¡Pip sabe qué hacer!", To = "Yo" },
				{ S = "Cosimo", T = "Nos vemos en la universidad, Ancla.", To = "Yo", Pause = 0.9, If = { Flags = { "VaALaUniversidad" } } },
				{ S = "Cosimo", T = "Nos vemos pronto, Ancla.", To = "Yo", Pause = 0.9, If = { NotFlags = { "VaALaUniversidad" } } },
				{ S = "Omar", T = "Vale. Ahora sí que me lo tienes que contar todo. Todo.", To = "Yo", Pause = 0.9 },
				{ S = "Narrador", T = "Añadir: «El día que Cósimo se llevó a Cosme»" },
				{ S = "Omar", T = "Ya no puede comportarse como si todo fuera una aventura divertida.", To = "Yo" },
				{ S = "Cosimo", T = "Seguro. Eso lo hace más inquietante.", To = "Yo" },
				{ S = "Omar", T = "Este es su primer gran cambio. Vamos a buscarlo.", To = "Yo" },
			},
		},
	},
	Scenes = {
		Saga_12_G4_Entra = {
			Light = true,
			Duration = 17.2,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Nico", Npc = "Nico" } },
					{ At = 0, Use = { Key = "Cosme", Npc = "Cosme" } },
					{ At = 0, Use = { Key = "Omar", Npc = "Omar" } },
					{ At = 0, Use = { Key = "Sara", Npc = "Sara" } },
				},
				Dialogue = {
					{ At = 0.4, S = "Omar", T = "Intenta ayudar aunque no sabe qué hacer. ¡Tengo un plan! ¡No tengo plan!", To = "Yo" },
					{ At = 6.3, S = "Sara", T = "¡Tienen un patrón! ¡No sé cuál es todavía!", To = "Yo" },
					{ At = 10.1, S = "Nico", T = "¡Por aquí!", To = "Yo" },
					{ At = 12.6, S = "Cosme", T = "Pero uno de los drones lo separa. ¡Criatura!", To = "Yo" },
				},
			},
		},
	},
	Steps = { ["3"] = { Effects = { Scene = "Saga_12_G4_Entra" } } },
}
