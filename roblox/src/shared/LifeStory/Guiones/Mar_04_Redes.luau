-- GUION REESCRITO de Mar_04_Redes (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Mar_04_Redes.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Mar_04_Redes
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Mar_04_Redes.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Mar_04_Redes.md",
	Dialogues = {
		Sargo = {
			Lines = {
				{
					S = "Sargo",
					T = "¡Vale, vale! Me has pillado. ¿Contento? No eres tan lento para tener piernas.",
					To = "Yo",
					A = "HandsOnHips",
					Effects = { Scene = "Mar04_G4_Musica" },
				},
				{
					S = "Sargo",
					T = "Sí, corto las redes. Porque si los secos se quedan sin peces, se van. Y si se van, nadie nos hace daño.",
					To = "Yo",
					A = "No",
				},
				{ S = "Sargo", T = "Mi padre dice que hace cien años nos dejaron solos en un temporal. Que se olvidaron. Que lo harán otra vez.", To = "Yo" },
				{ S = "Sargo", T = "Tú… tú no pareces de los que olvidan. Pero eso no lo decido yo.", To = "Yo", A = "ThinkChin" },
			},
		},
		Tome = {
			Lines = {
				{
					S = "Tome",
					T = "Otra vez. Tres redes de los pescadores de arriba, cortadas como quien corta algas.",
					To = "Yo",
					A = "No",
					Effects = { Scene = "Mar04_G1_Musica" },
				},
				{
					S = "Tome",
					T = "Los de la Marea Callada dicen que así los secos se irán del mar. Yo digo que así se irán los peces. A las redes.",
					To = "Yo",
				},
				{ S = "Tome", T = "Anoche vi una sombra en el kelp del norte. Joven. Rápida. Con una cola gris.", To = "Yo", G = "Point" },
				{ S = "Tome", T = "Tú nadas deprisa para ser seco. Ve a mirar. Y si es quien creo, tráemelo entero, ¿eh?", To = "Yo" },
			},
		},
	},
	Scenes = {
		Mar04_G1_Musica = { Light = true, Duration = 30.6, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Mar04_G4_Musica = { Light = true, Duration = 30.2, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
	},
	Steps = { ["2"] = { Set = { Text = "Ve al bosque de kelp del norte" } }, ["3"] = { Set = { Text = "¡Persíguele por el kelp y alcánzale!" } } },
}
