-- GUION REESCRITO de Saga_17_Rescate (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_17_Rescate.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_17_Rescate
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_17_Rescate.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_17_Rescate.md",
	Dialogues = {
		Capsula = {
			Lines = {
				{ S = "Narrador", T = "Una sala enorme llena de cápsulas vacías. En la última, dormido, está Cosme." },
				{ S = "Narrador", T = "La cápsula se abre con un silbido. Cosme abre los ojos. Te mira mucho rato." },
				{ S = "Cosme", T = "…Te conozco. Eres…", To = "Yo" },
				{ S = "Narrador", T = "En una pantalla de la pared: «Recuerdos extraídos: 87 %»." },
				{ S = "Sorel", T = "Le ha estado vaciando la memoria. Para saber cómo soltar el Ancla.", To = "Yo" },
				{ S = "Cosimo", T = "Bienvenidos. Llegáis tarde. Ya sé casi todo lo que él sabía.", To = "Yo" },
				{ S = "Cosimo", T = "Lo que queda de él os lo podéis llevar. No me hace falta.", To = "Yo" },
			},
		},
	},
	Scenes = {
		Saga_17_G1_2_Fin = {
			Light = true,
			Duration = 24.8,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Brenn", Npc = "Brenn" } },
					{ At = 0, Use = { Key = "Sorel", Npc = "Sorel" } },
					{ At = 0, Use = { Key = "Pip", Npc = "Pip" } },
				},
				Dialogue = {
					{
						At = 0.4,
						S = "Pip",
						T = "Plan: entramos por la rejilla, neutralizamos la seguridad del pasillo, abrimos la cápsula y volvemos al portal.",
						To = "Yo",
					},
					{ At = 9.1, S = "Brenn", T = "Cuatro pasos. Lo difícil es que todos salgan bien.", To = "Yo" },
					{ At = 13.5, S = "Narrador", T = "El pasillo es largo y blanco. Guardias robóticos y drones patrullan sin descanso." },
					{ At = 20.1, S = "Sorel", T = "Cuando entremos, no hay vuelta atrás. ¿Listos?", To = "Yo" },
				},
			},
		},
		Saga_17_G4_5_Entra = {
			Light = true,
			Duration = 27.6,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Cosme", Npc = "Cosme" } }, { At = 0, Use = { Key = "Pip", Npc = "Pip" } } },
				Dialogue = {
					{ At = 0.4, S = "Narrador", T = "Las puertas se cierran. Las alarmas pintan la sala de rojo." },
					{ At = 5.4, S = "Cosme", T = "Tengo la sensación de que la última vez eras más joven. ¿Cuánto tiempo ha pasado?", To = "Yo" },
					{ At = 12, S = "Pip", T = "Señor, no hable. Corra.", To = "Yo" },
					{ At = 14.5, S = "Narrador", T = "Cruzáis el portal de vuelta al garaje. Al otro lado, Cosme se tambalea y se sienta en el suelo." },
					{ At = 22.1, S = "Narrador", T = "Mira a su alrededor como si no hubiera estado nunca allí." },
				},
			},
		},
	},
	Steps = { ["1"] = { Effects = { Scene = "Saga_17_G1_2_Fin" } }, ["2"] = { Effects = { Scene = "Saga_17_G4_5_Entra" } } },
}
