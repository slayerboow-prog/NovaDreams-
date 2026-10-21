-- Escenas de UMBRÍA · Raíz Honda (Saga 2, episodio 5; docs/planetas/nivalis-umbria.md). Formato:
-- shared/LifeStory/Sequencer.luau. Las lanzan las misiones de Misiones/Umbria_Episodio con un paso
-- { Type = "Cinematic", Id = … }. Anclas: lugares «Umbria_…» (shared/Cosmos/UmbriaCity.StorySpots) y "Player".
-- 13+: las máquinas son amenaza, nunca horror; nada de sangre.

local V = Vector3.new

return {
	---------------------------------------------------------------------
	-- Umbria_01 · LLEGADA. Te posas en el Claro del Ascensor, al pie del Árbol Madre.
	--   ¿Qué está pasando? Raíz Honda se prepara: empalizada nueva, cuernos, gente mirando al bosque.
	--   ¿Por qué? Un enjambre de máquinas se come la madera del planeta.
	--   ¿Qué siente el personaje? Garza: vuelve a casa y no la reconoce.
	--   ¿Qué ve el jugador? El tronco que se pierde en la niebla, las setas que brillan, Garza esperando.
	--   ¿Qué quiero que sienta el jugador? Que es pequeño, que esto es precioso y que está en peligro.
	---------------------------------------------------------------------
	Umbria_Llegada = {
		Duration = 21,
		Skippable = true,
		FadeIn = true,
		Sting = "Momento",
		Anchors = {
			Claro = "Place:Umbria_Plataforma",
			Yo = "Player",
			Plaza = "Place:Umbria_Raices",
			Tronco = { Place = "Umbria_ArbolMadre", Offset = V(0, 220, -90) },
			Base = { Place = "Umbria_ArbolMadre", Offset = V(0, 20, -80) },
		},
		Tracks = {
			Camera = {
				{ At = 0, Duration = 5, From = { "Base", V(0, 10, 120) }, To = { "Base", V(0, 30, 160) }, Look = { "Tronco" }, Fov = { 70, 58 }, Cut = "Fade" },
				{ At = 5, Duration = 4, From = { "Plaza", V(-24, 12, 0) }, To = { "Plaza", V(-10, 6, 10) }, Look = { "Plaza" }, Fov = 50, Cut = "Cut" },
				{ At = 9, Duration = 3.6, Shot = "Reaccion:Garza", Cut = "Cut" },
				{ At = 12.6, Duration = 8.4, Shot = "Medio:Garza", Cut = "Cut" },
			},
			Sound = {
				{ At = 0.4, Play = "Hum", Pitch = 0.6, Volume = 0.4 },
				{ At = 6, Play = "Hum", Pitch = 1.6, Volume = 0.25 },
			},
			Music = {
				{ At = 0, Intensity = "Descubrimiento" },
				{ At = 9, Intensity = "Tension" },
			},
			Actors = {
				{ At = 0, Use = { Key = "Garza", Npc = "Garza", Anchor = "Claro", Offset = V(3, 0, 2) } },
				{ At = 0.4, Look = { Key = "Garza", At = "Tronco" } },
				{ At = 9.2, Mood = { Key = "Garza", Mood = "Sad" } },
				{ At = 12.6, Look = { Key = "Garza", At = "Yo" } },
			},
			Dialogue = {
				{ At = 1, S = "Narrador", T = "Un árbol tan alto que la copa se pierde en la niebla. Lo llaman el Árbol Madre." },
				{ At = 5.4, S = "Narrador", T = "A sus pies, una ciudad tallada en las raíces. Setas que brillan. Y, lejos, un zumbido." },
				{ At = 13, S = "Garza", T = "Veinte años. Y lo primero que oigo al volver es eso. El zumbido.", To = "Yo" },
			},
			Titles = {
				{ At = 0.8, Text = "🌳 Umbría · Raíz Honda", Sub = "Saga 2 · Episodio 5: «El Enjambre»", Duration = 3 },
			},
		},
	},

	---------------------------------------------------------------------
	-- Umbria_05 · VESNA. La pieza de la baliza se enciende y aparece una voz que Garza conoce.
	--   ¿Qué está pasando? Vesna, jefa de la Compañía Torca, le ofrece a Garza la mitad del negocio.
	--   ¿Por qué? Sabe que Garza es lo único que puede pararla.
	--   ¿Qué siente el personaje? Garza: tentación y vergüenza.
	--   ¿Qué ve el jugador? Un holograma rojo sobre la plaza, las setas apagándose de miedo, Garza quieto.
	--   ¿Qué quiero que sienta el jugador? Que la decisión de Garza pesa, y que tú vas a influir.
	---------------------------------------------------------------------
	Umbria_Vesna = {
		Duration = 24,
		Skippable = true,
		FadeIn = true,
		Anchors = {
			Plaza = "Place:Umbria_Raices",
			Yo = "Player",
			Holo = { Place = "Umbria_Raices", Offset = V(-4, 5, -4) },
		},
		Tracks = {
			Camera = {
				{ At = 0, Duration = 4, Fixed = { "Plaza", V(10, 6, 14) }, Look = { "Holo" }, Fov = 52, Cut = "Fade" },
				{ At = 4, Duration = 4.4, Fixed = { "Holo", V(2, 1, 8) }, Look = { "Holo" }, Fov = 40, Cut = "Cut" },
				{ At = 8.4, Duration = 3.6, Shot = "Reaccion:Garza", Cut = "Cut" },
				{ At = 12, Duration = 12, Fixed = { "Holo", V(-3, 1, 7) }, Look = { "Holo" }, Fov = 44, Cut = "Cut" },
			},
			Fx = {
				{ At = 0.6, Play = "Flash", Anchor = "Holo" },
			},
			Sound = {
				{ At = 0.6, Play = "Ping", Pitch = 0.7, Volume = 0.6 },
			},
			Music = {
				{ At = 0, Intensity = "Tension" },
			},
			Actors = {
				{ At = 0, Use = { Key = "Garza", Npc = "Garza", Anchor = "Plaza", Offset = V(2, 0, 2) } },
				-- (Vesna es un holograma de la baliza: su figura, roja, sobre la plaza)
				{ At = 0.6, Use = { Key = "VesnaTorca", Npc = "VesnaTorca", Anchor = "Plaza", Offset = V(-4, 0, -4) } },
				{ At = 0.4, Look = { Key = "Garza", At = "Holo" } },
				{ At = 1, Look = { Key = "VesnaTorca", At = "Garza" } },
				{ At = 8.6, Mood = { Key = "Garza", Mood = "Fear" } },
			},
			Dialogue = {
				{ At = 1, S = "Narrador", T = "La pieza de la baliza se enciende. Sobre la plaza, en rojo, la cara de una mujer." },
				{ At = 4.4, S = "VesnaTorca", T = "Garza. Viejo socio. Has abierto mi baliza: ahora sé dónde estás.", To = "Garza" },
				{ At = 8.8, S = "Garza", T = "Vesna. Sigues mandando máquinas a hacer tu trabajo.", To = "VesnaTorca" },
				{ At = 12.4, S = "VesnaTorca", T = "Te ofrezco la mitad del negocio. Vete esta noche y no estés aquí cuando llegue la Reina.", To = "Garza" },
				{ At = 17, S = "Narrador", T = "El holograma se apaga. Las setas de la plaza tardan un rato en volver a brillar." },
			},
		},
	},
}
