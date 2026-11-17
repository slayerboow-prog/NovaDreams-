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
				{ S = "Cosme", T = "No me mires así. He venido a tu ceremonia. Es lo normal.", To = "Yo" },
				{ S = "Cosme", T = "…Y porque hoy es el día que marcaba la cuenta atrás. Traigo una aguja nueva en el bolsillo, por si acaso.", To = "Yo" },
				{ S = "Cosme", T = "Sabes lo que eres. Así que sabes por qué hoy no me separo de ti.", To = "Yo" },
				{ S = "Sorel", T = "¿Ese es Cosme? ¿El del garaje? Kael dice que es el hombre más list{o/a} de Valmar. Y el más cabezota.", To = "Yo" },
				{ S = "Sorel", T = "Oye. Hoy es el día de los números de la feria, ¿verdad? Dime que no.", To = "Yo" },
			},
		},
		Cosimo = {
			Lines = {
				{ S = "Cosimo", T = "Buenas tardes, Valmar. Enhorabuena a los nuevos guerreros. Qué día tan bonito para un final.", To = "Yo" },
				{ S = "Cosimo", T = "Hola, Cosme. Hola, Ancla.", To = "Yo" },
				{ S = "Cosimo", T = "La última vez que nos vimos, tú corrías por el laboratorio de Lía y ella te empujaba hacia la puerta.", To = "Yo" },
				{ S = "Cosimo", T = "Ella eligió salvarte a ti. Yo habría elegido distinto. Siempre elijo distinto.", To = "Yo" },
				{ S = "Cosme", T = "Vete, Cósimo. Esto no es tuyo.", To = "Yo" },
				{ S = "Cosimo", T = "Todavía no. Solo necesito que la costura ceda un poco más. Y he traído ayuda.", To = "Yo" },
			},
		},
		Secuestro = {
			Lines = {
				{ S = "Cosimo", T = "Sabes pelear. Te enseñó la Academia. Y él te enseñó a hacer preguntas. Mala combinación para mí.", To = "Yo" },
				{ S = "Cosimo", T = "Por eso me lo llevo. Sin él, nadie sabrá cerrar lo que voy a abrir.", To = "Yo" },
				{ S = "Narrador", T = "Un haz dorado envuelve a Cosme. Intentas agarrarle de la mano. Igual que Lía intentó agarrar la tuya." },
				{ S = "Narrador", T = "Se te escapa." },
				{ S = "Cosme", T = "¡No sueltes el ancla! ¡Pase lo que pase, quédate en este mundo! ¡Pip sabe qué hacer!", To = "Yo" },
				{ S = "Cosimo", T = "Nos veremos pronto, Ancla. Los finales siempre son lo más difícil.", To = "Yo" },
				{ S = "Narrador", T = "La grieta se cierra detrás de ellos. Silencio en el patio." },
				{ S = "Sorel", T = "Ahora me lo tienes que contar todo. Desde el principio.", To = "Yo" },
				{ S = "Narrador", T = "FIN DEL ACTO II. Cosme ha desaparecido al otro lado de la Grieta." },
			},
		},
	},
	Scenes = {
		Saga_12_G4_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Pip", Npc = "Pip" } } },
				Dialogue = { { At = 0.4, S = "Pip", T = "Drones de combate del Consorcio. Proteja a los cadetes. Apunte al núcleo rojo.", To = "Yo" } },
			},
		},
	},
	Steps = { ["3"] = { Effects = { Scene = "Saga_12_G4_Entra" } } },
}
