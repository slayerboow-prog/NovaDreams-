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
				{ S = "Candela", T = "Alguien sigue recordando a Cosme.", To = "Yo" },
				{ S = "Candela", T = "Eso es importante.", To = "Yo", Pause = 0.9 },
				{ S = "Candela", T = "Lo apunto.", To = "Yo" },
				{ S = "Candela", T = "¿Lo has visto?", To = "Yo" },
				{ S = "Ivan", T = "Sí.", To = "Yo" },
				{ S = "Candela", T = "Bien.", To = "Yo" },
				{ S = "Candela", T = "No estoy loca.", To = "Yo", Pause = 0.9 },
			},
		},
		Malvado = {
			Effects = { Flags = { "MalvadoAyudo" } },
			Lines = {
				{ S = "Ivan", T = "Eso… tiene que doler.", To = "Yo", Shot = "Reaccion:Candela", Pause = 3 },
				{ S = "Ivan", T = "Muchísimo.", To = "Yo" },
				{ S = "Ivan", T = "¿El gato?", To = "Yo", Pause = 0.9 },
				{ S = "Ivan", T = "No.", To = "Yo" },
				{ S = "Ivan", T = "Entiendo.", To = "Yo", Pause = 0.9 },
				{
					Ask = "¿Qué le dices a tu yo malvado?",
					Options = {
						{
							T = "«Ayúdanos a llegar al laboratorio. Te lo agradeceré.»",
							Effects = { Flags = { "MalvadoAyudo" }, Traits = { Empatia = 1 } },
							Then = {
								{
									S = "TuMalvado",
									T = "¿Agradecer? ¿A mí? …Qué sensación tan rara. Me gusta. La entrada está en la rejilla de la universidad. Y no me des las gracias, que me sale urticaria.",
								},
							},
						},
						{
							T = "«No me fío de ti. Ni de tu perilla.»",
							Effects = { Traits = { Valentia = 1 } },
							Then = {
								{
									S = "TuMalvado",
									T = "Haces bien. Yo tampoco me fío de mí. …Pero la rejilla de la universidad echa humo verde. Por si te interesa. No te lo he dicho.",
								},
							},
						},
					},
				},
			},
		},
		Rejilla = {
			Lines = {
				{ S = "Candela", T = "Es la misma.", To = "Yo" },
				{ S = "Candela", T = "La de la grabación.", To = "Yo", Pause = 0.9 },
				{ S = "Ivan", T = "No quiero saber qué clase de concurso es este.", To = "Yo", Pause = 0.9 },
				{ S = "Candela", T = "Es exactamente el de la grabación.", To = "Yo", If = { Flags = { "GrabacionLaboratorio" } } },
				{ S = "Candela", T = "Cosme está ahí abajo.", To = "Yo", Pause = 0.9, If = { Flags = { "GrabacionLaboratorio" } } },
				{ S = "Pip", T = "Coordenadas de Bigotes confirmadas.", To = "Yo", If = { Flags = { "CoordenadasCosimo" } } },
				{ S = "Pip", T = "La grabación de la Capitana Ñoz también coincide.", To = "Yo", Pause = 0.9, If = { Flags = { "CoordenadasCosimo" } } },
				{ S = "Pip", T = "El laboratorio está debajo de ustedes.", To = "Yo", If = { Flags = { "CoordenadasCosimo" } } },
				{ S = "Narrador", T = "«COSME: VIVO»" },
				{ S = "Narrador", T = "«RESCATE: MAÑANA»" },
				{ S = "Candela", T = "Hoy no entramos.", To = "Yo" },
				{ S = "Ivan", T = "¿Mañana?", To = "Yo" },
				{ S = "Candela", T = "Mañana entramos preparados.", To = "Yo" },
				{ S = "Pip", T = "Correcto.", To = "Yo" },
				{ S = "Pip", T = "Y señor Iván.", To = "Yo", Pause = 0.9 },
				{ S = "Ivan", T = "¿Sí?", To = "Yo" },
				{ S = "Pip", T = "No se coma las plantas carnívoras.", To = "Yo" },
				{ S = "Pip", T = "Otra vez.", To = "Yo", Pause = 0.9 },
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
			Duration = 46.6,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Pip", Npc = "Pip" } },
					{ At = 0, Use = { Key = "Candela", Npc = "Candela" } },
					{ At = 0, Use = { Key = "Ivan", Npc = "Ivan" } },
				},
				Dialogue = {
					{ At = 0.4, S = "Ivan", T = "He traído agua.", To = "Yo" },
					{ At = 3.4, S = "Ivan", T = "Y zumo de mora.", To = "Yo" },
					{ At = 5.4, S = "Candela", T = "¿Para qué?", To = "Yo" },
					{ At = 7.5, S = "Ivan", T = "Por si el universo tiene sed.", To = "Yo" },
					{ At = 10.2, S = "Pip", T = "Coordenadas confirmadas.", To = "Yo" },
					{ At = 13.6, S = "Pip", T = "Dimensión 66-B.", To = "Yo" },
					{ At = 15.6, S = "Candela", T = "Entramos, encontramos el laboratorio y volvemos.", To = "Yo" },
					{ At = 19.4, S = "Ivan", T = "Plan sencillo.", To = "Yo" },
					{ At = 22.4, S = "Ivan", T = "Eso siempre acaba bien.", To = "Yo" },
					{ At = 26.6, S = "Ivan", T = "No me gusta esta ciudad.", To = "Yo" },
					{ At = 29, S = "Candela", T = "Llevamos aquí diez segundos.", To = "Yo" },
					{ At = 31.7, S = "Ivan", T = "Exactamente.", To = "Yo" },
					{ At = 33.8, S = "Ivan", T = "Me ha robado.", To = "Yo" },
					{ At = 35.8, S = "Candela", T = "Apúntalo.", To = "Yo" },
					{ At = 37.9, S = "Ivan", T = "¿En serio?", To = "Yo" },
					{ At = 39.9, S = "Candela", T = "Sí.", To = "Yo" },
					{ At = 42.9, S = "Candela", T = "Las palomas pueden ser importantes.", To = "Yo" },
				},
			},
		},
		Saga_16_G4_Entra = {
			Light = true,
			Duration = 25.3,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Ivan", Npc = "Ivan" } }, { At = 0, Use = { Key = "Candela", Npc = "Candela" } } },
				Dialogue = {
					{ At = 1.3, S = "Candela", T = "Nos han detectado.", To = "Yo" },
					{ At = 3.4, S = "Ivan", T = "¿Quién?", To = "Yo" },
					{ At = 5.5, S = "Ivan", T = "Ah.", To = "Yo" },
					{ At = 8.4, S = "Ivan", T = "Eso.", To = "Yo" },
					{ At = 10.5, S = "Candela", T = "Corred.", To = "Yo" },
					{ At = 12.5, S = "Ivan", T = "¡No sé si esto cuenta como estudiar!", To = "Yo" },
					{ At = 15.7, S = "Candela", T = "Candela", To = "Yo" },
					{ At = 17.7, S = "Candela", T = "¡Corre y luego lo discutimos!", To = "Yo" },
					{ At = 20.5, S = "Candela", T = "¿Estás bien?", To = "Yo" },
					{ At = 22.5, S = "Candela", T = "Entonces otra vez.", To = "Yo" },
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
