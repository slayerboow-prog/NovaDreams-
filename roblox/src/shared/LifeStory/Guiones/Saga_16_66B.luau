-- GUION REESCRITO de Saga_16_66B (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_16_66B.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_16_66B
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_16_66B.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_16_66B.md",
	Dialogues = {
		Cartel = {
			Lines = {
				{ S = "Candela", T = "Alguien sigue recordando a Cosme. Eso es importante. Lo apunto.", To = "Yo" },
				{ S = "Candela", T = "¿Lo has visto?", To = "Yo" },
				{ S = "Ivan", T = "Sí.", To = "Yo" },
				{ S = "Candela", T = "Bien. No estoy loca.", To = "Yo" },
			},
		},
		Malvado = {
			Lines = {
				{ S = "Ivan", T = "Eso… tiene que doler. Muchísimo. ¿El gato? No. Entiendo.", To = "Yo", Shot = "Reaccion:Candela", Pause = 3 },
				{
					Ask = "¿Qué le dices a tu yo malvado?",
					Options = {
						{ T = "«Ayúdanos a llegar al laboratorio. Te lo agradeceré.»", Effects = { Flags = { "MalvadoAyudo" }, Traits = { Empatia = 1 } } },
						{ T = "«No me fío de ti. Ni de tu perilla.»", Effects = { Traits = { Valentia = 1 } } },
					},
				},
			},
		},
		Rejilla = {
			Lines = {
				{ S = "Candela", T = "Es la misma. La de la grabación.", To = "Yo" },
				{ S = "Ivan", T = "No quiero saber qué clase de concurso es este.", To = "Yo", Pause = 0.9 },
				{ S = "Candela", T = "Es exactamente el de la grabación. Cosme está ahí abajo.", To = "Yo", If = { Flags = { "GrabacionLaboratorio" } } },
				{ S = "Pip", T = "Coordenadas de Bigotes confirmadas.", To = "Yo", If = { Flags = { "CoordenadasCosimo" } } },
				{ S = "Pip", T = "La grabación de la Capitana Ñoz también coincide.", To = "Yo", Pause = 0.9, If = { Flags = { "CoordenadasCosimo" } } },
				{ S = "Pip", T = "El laboratorio está debajo de ustedes.", To = "Yo", If = { Flags = { "CoordenadasCosimo" } } },
				{ S = "Narrador", T = "«COSME: VIVO» «RESCATE: MAÑANA»" },
				{ S = "Candela", T = "Hoy no entramos.", To = "Yo" },
				{ S = "Ivan", T = "¿Mañana?", To = "Yo" },
				{ S = "Candela", T = "Mañana entramos preparados.", To = "Yo" },
				{ S = "Pip", T = "Correcto. Y señor Iván.", To = "Yo" },
				{ S = "Ivan", T = "¿Sí?", To = "Yo" },
				{ S = "Pip", T = "No se coma las plantas carnívoras. Otra vez.", To = "Yo" },
				{ S = "Ivan", T = "Fue una investigación científica.", To = "Yo" },
				{ S = "Cosimo", T = "¿Quién anda ahí?", To = "Yo" },
				{ S = "Narrador", T = "«Entraste en la Valmar 66-B y encontraste la entrada al laboratorio donde Cósimo mantiene a Cosme.»", Pause = 0.9 },
				{ S = "Narrador", T = "«Incluso tu versión de 66-B decidió ayudarte.»", If = { Flags = { "MalvadoAyudo" } } },
				{ S = "Candela", T = "No solamente acompaña.", To = "Yo" },
				{ S = "Pip", T = "Esta vez, volvemos con él.", To = "Yo", Pause = 0.9 },
			},
		},
	},
	Scenes = {
		Saga_16_G1_Fin = {
			Light = true,
			Duration = 39.2,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Pip", Npc = "Pip" } },
					{ At = 0, Use = { Key = "Candela", Npc = "Candela" } },
					{ At = 0, Use = { Key = "Ivan", Npc = "Ivan" } },
				},
				Dialogue = {
					{ At = 0.4, S = "Ivan", T = "He traído agua. Y zumo de mora.", To = "Yo" },
					{ At = 3.4, S = "Candela", T = "¿Para qué?", To = "Yo" },
					{ At = 5.9, S = "Ivan", T = "Por si el universo tiene sed.", To = "Yo" },
					{ At = 8.8, S = "Pip", T = "Coordenadas confirmadas. Dimensión 66-B.", To = "Yo" },
					{ At = 12.4, S = "Candela", T = "Entramos, encontramos el laboratorio y volvemos.", To = "Yo" },
					{ At = 16.7, S = "Ivan", T = "Plan sencillo. Eso siempre acaba bien.", To = "Yo" },
					{ At = 22, S = "Ivan", T = "No me gusta esta ciudad.", To = "Yo" },
					{ At = 24.5, S = "Candela", T = "Llevamos aquí diez segundos.", To = "Yo" },
					{ At = 27.3, S = "Ivan", T = "Exactamente. Me ha robado.", To = "Yo" },
					{ At = 30, S = "Candela", T = "Apúntalo.", To = "Yo" },
					{ At = 32.5, S = "Ivan", T = "¿En serio?", To = "Yo" },
					{ At = 35, S = "Candela", T = "Sí. Las palomas pueden ser importantes.", To = "Yo" },
				},
			},
		},
		Saga_16_G4_Entra = {
			Light = true,
			Duration = 18,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Ivan", Npc = "Ivan" } }, { At = 0, Use = { Key = "Candela", Npc = "Candela" } } },
				Dialogue = {
					{ At = 1.3, S = "Candela", T = "Nos han detectado.", To = "Yo" },
					{ At = 3.8, S = "Ivan", T = "¿Quién? Ah. Eso.", To = "Yo" },
					{ At = 6.3, S = "Candela", T = "Corred.", To = "Yo" },
					{ At = 8.8, S = "Ivan", T = "¡No sé si esto cuenta como estudiar!", To = "Yo" },
					{ At = 12.2, S = "Candela", T = "¡Corre y luego lo discutimos! ¿Estás bien? Entonces otra vez.", To = "Yo" },
				},
			},
		},
	},
	Steps = {
		["1"] = { Effects = { Scene = "Saga_16_G1_Fin" } },
		["2"] = { Set = { Text = "investigar la Plaza Mayor." } },
		["3"] = { Effects = { Scene = "Saga_16_G4_Entra" } },
		["4"] = { Set = { Text = "llegar a la universidad 66-B." } },
	},
}
