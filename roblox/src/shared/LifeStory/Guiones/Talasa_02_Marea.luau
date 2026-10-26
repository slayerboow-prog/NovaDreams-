-- GUION REESCRITO de Talasa_02_Marea (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Talasa_02_Marea.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Talasa_02_Marea
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Talasa_02_Marea.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Talasa_02_Marea.md",
	Dialogues = {
		Tabla = {
			Lines = {
				{
					S = "Cosme",
					T = "La tabla de mareas, criatura. Cada doce minutos, el mar sube varios pisos. Y baja otra vez.",
					To = "Yo",
					Shot = "Medio:Cosme",
					G = "Point",
					Effects = { Scene = "Talasa2_G1_Musica" },
				},
				{ S = "Cosme", T = "Las compuertas aguantan la ciudad. Pero alguien tiene que ajustar las válvulas a tiempo.", To = "Yo", A = "HandsOnHips" },
				{ S = "Cosme", T = "Los técnicos están abajo, en la Cúpula. Encerrados. Así que hoy el técnico eres tú.", To = "Yo", A = "Shrug" },
				{ S = "Cosme", T = "El tablón está junto al Faro. Dos válvulas, ni más ni menos. Yo vigilo el cielo.", To = "Yo", A = "Happy" },
			},
		},
		Tormenta = {
			Lines = {
				{
					S = "Bruma",
					T = "Cerrad la puerta, que entra el agua. ¿Primera tormenta? Se nota. Estáis empapados.",
					To = "Yo",
					Shot = "Medio:Bruma",
					Effects = { Scene = "Talasa2_G2_Musica" },
				},
				{ S = "Cosme", T = "Gracias por el sitio. Soy Cosme. Esta es mi ayudante de campo, la mejor de la galaxia.", To = "Yo", A = "Nod" },
				{ S = "Bruma", T = "Bruma. Buceadora. Bueno, era buceadora. Ahora espero en las Balsas.", To = "Yo", A = "Shrug" },
				{
					S = "Bruma",
					T = "Mi equipo bajó a la Cúpula Honda hace tres semanas. Una perla por cada uno. Ya no me caben en la cuerda.",
					To = "Yo",
					A = "Sad",
				},
				{ S = "Bruma", T = "(susurrando) Y todo por un coral que alguien soltó en el fondo. Alguien con nombre y apellidos.", To = "Yo" },
				{ S = "Cosme", T = "¿Sabes quién fue?", To = "Yo", A = "ThinkChin" },
				{ S = "Bruma", T = "Lo sabré. Y entonces no habrá cuarentena que la esconda.", To = "Yo", A = "No" },
			},
		},
	},
	Scenes = {
		Talasa2_G1_Musica = { Light = true, Duration = 29.6, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Talasa2_G2_Musica = { Light = true, Duration = 44.3, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
	},
	Steps = {},
}
