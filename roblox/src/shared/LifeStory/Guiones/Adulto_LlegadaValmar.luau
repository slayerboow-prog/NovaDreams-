-- GUION REESCRITO de Adulto_LlegadaValmar (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Adulto_LlegadaValmar.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Adulto_LlegadaValmar
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Adulto_LlegadaValmar.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Adulto_LlegadaValmar.md",
	Scenes = {
		Adulto_Bienvenida = {
			Skippable = true,
			Duration = 47.9,
			FadeIn = true,
			Anchors = { Sitio = "Place:PlazaCentro", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0.4, Enter = { To = { "Yo", V(1.8, 0, -3.6), true }, From = { "Yo", V(9, 0, -6), true }, Key = "Ernesto", Npc = "Ernesto", Walk = true } },
					{ At = 4, Look = { At = "Yo", Key = "Ernesto" } },
					{ At = 4.2, Mood = { Mood = "Joy", Key = "Ernesto" } },
					{ At = 12, Enter = { To = { "Yo", V(-1.8, 0, -3.6), true }, From = { "Yo", V(-9, 0, -5), true }, Key = "Lola", Npc = "Lola", Walk = true } },
					{ At = 15.5, Look = { At = "Yo", Key = "Lola" } },
					{ At = 33, Exit = { To = { "Yo", V(12, 0, -8), true }, Key = "Ernesto", Walk = true } },
					{ At = 34, Exit = { To = { "Yo", V(-12, 0, -8), true }, Key = "Lola", Walk = true } },
				},
				Ambience = { { At = 0, Fade = 1.5, Kind = "Calle" } },
				Camera = { { At = 0, Duration = 4.2, Shot = "General" } },
				Dialogue = {
					{ At = 0.4, S = "Ernesto", T = "¡Eh! Tú no eres de aquí.", To = "Yo" },
					{ At = 2.9, S = "Ernesto", T = "Conozco todas las caras de Valmar. Y todos los perros. A ese no lo conozco. Todavía.", To = "Yo" },
					{ At = 9.7, S = "Ernesto", T = "Entonces bienvenid{o/a}.", To = "Yo" },
					{ At = 12.2, S = "Ernesto", T = "Para recibir cartas necesitas un buzón. Y para tener buzón… Una casa.", To = "Yo" },
					{ At = 18, S = "Ernesto", T = "Busca los carteles de “SE VENDE”.", To = "Yo" },
					{ At = 21.1, S = "Lola", T = "¡Ernesto! Déjale respirar. Acaba de llegar. Soy Lola.", To = "Yo" },
					{ At = 25.7, S = "Lola", T = "Tengo una cafetería aquí mismo.", To = "Yo" },
					{ At = 29.6, S = "Lola", T = "Si tienes hambre, ven.", To = "Yo" },
					{ At = 32.1, S = "Lola", T = "La primera invita la casa.", To = "Yo" },
					{ At = 34.8, S = "Ernesto", T = "¿La primera?", To = "Yo" },
					{ At = 37.3, S = "Lola", T = "La primera.", To = "Yo" },
					{ At = 39.8, S = "Ernesto", T = "Eso es peligroso.", To = "Yo" },
					{ At = 42.3, S = "Lola", T = "Tú no eres cliente.", To = "Yo" },
					{ At = 44.8, S = "Ernesto", T = "Precisamente.", To = "Yo" },
				},
				Music = { { At = 0, Intensity = "Descubrimiento" } },
			},
		},
		Adulto_Llegada_G1_Fin = {
			Light = true,
			Duration = 3.6,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = { Dialogue = { { At = 0.4, S = "Narrador", T = "Hay ciudades que visitas." } } },
		},
		Adulto_Llegada_G3_Entra = {
			Light = true,
			Duration = 13.9,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Vecino", Npc = "Vecino" } } },
				Dialogue = {
					{ At = 2.2, S = "Vecino", T = "¿Nuev{o/a}?", To = "Yo" },
					{ At = 4.7, S = "Yo", T = "Sí." },
					{ At = 7.2, S = "Vecino", T = "Entonces todavía no sabes dónde está el supermercado. Eso cambiará pronto.", To = "Yo" },
				},
			},
		},
		Adulto_Llegada_G4_Entra = {
			Light = true,
			Duration = 57.3,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Lola", Npc = "Lola" } }, { At = 0, Use = { Key = "Ernesto", Npc = "Ernesto" } } },
				Dialogue = {
					{ At = 0.4, S = "Lola", T = "¡Ah! La cara nueva. Has tardado poco.", To = "Yo" },
					{ At = 3.8, S = "Lola", T = "¿Vienes de lejos?", To = "Yo" },
					{ At = 6.3, S = "Yo", T = "De otra ciudad." },
					{ At = 8.8, S = "Lola", T = "En esa dirección está el centro.", To = "Yo" },
					{ At = 11.9, S = "Lola", T = "El mercado está detrás de la plaza.", To = "Yo" },
					{ At = 15.2, S = "Lola", T = "Y si alguna vez te pierdes… Pregunta.", To = "Yo" },
					{ At = 18.7, S = "Lola", T = "Aquí todos creen saber dónde está todo.", To = "Yo" },
					{ At = 22.3, S = "Ernesto", T = "Porque lo sé.", To = "Yo" },
					{ At = 24.8, S = "Lola", T = "Tú sabes dónde está el correo.", To = "Yo" },
					{ At = 27.7, S = "Ernesto", T = "Es lo importante.", To = "Yo" },
					{ At = 30.2, S = "Lola", T = "¿Otra vez aquí?", To = "Yo" },
					{ At = 32.7, S = "Ernesto", T = "Esta carta tiene hambre.", To = "Yo" },
					{ At = 35.2, S = "Lola", T = "Eso no tiene sentido.", To = "Yo" },
					{ At = 37.7, S = "Narrador", T = "No sabías cuánto tiempo te quedarías." },
					{ At = 43, S = "Ernesto", T = "Si buscas trabajo, mira los tablones.", To = "Yo" },
					{ At = 46.4, S = "Lola", T = "Y come algo antes.", To = "Yo" },
					{ At = 48.9, S = "Ernesto", T = "Eso también es importante.", To = "Yo" },
					{ At = 51.6, S = "Lola", T = "No tanto como el trabajo.", To = "Yo" },
					{ At = 54.1, S = "Ernesto", T = "Depende del trabajo.", To = "Yo" },
				},
			},
		},
	},
	Steps = {
		["1"] = { Effects = { Scene = "Adulto_Llegada_G1_Fin" } },
		["2"] = { Effects = { Scene = "Adulto_Llegada_G3_Entra" } },
		["3"] = { Effects = { Scene = "Adulto_Llegada_G4_Entra" } },
	},
}
