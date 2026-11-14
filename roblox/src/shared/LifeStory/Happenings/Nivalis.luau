-- Escenas de NIVALIS · Fortaleza Albor (Saga 2, episodio 4; docs/planetas/nivalis-umbria.md). Formato:
-- shared/LifeStory/Sequencer.luau. Las lanzan las misiones de Misiones/Nivalis_Episodio con un paso
-- { Type = "Cinematic", Id = … }. Anclas: lugares «Nivalis_…» (shared/Cosmos/NivalisCity.StorySpots) y "Player".
-- 13+: nada de miedo de verdad; el peligro es el frío y el silencio.

local V = Vector3.new

return {
	---------------------------------------------------------------------
	-- Nivalis_01 · LLEGADA. Te posas en el Patio de Armas en mitad de la noche eterna.
	--   ¿Qué está pasando? La aurora brilla sobre el Palacio de Escarcha… y no sobre el barrio.
	--   ¿Por qué? El Regente Morvan decide hacia dónde apunta la antena que atrae las auroras.
	--   ¿Qué siente el personaje? Frío, y que nadie se atreve a hablar.
	--   ¿Qué ve el jugador? La muralla nevada, los tejados-farol, la aurora lejos y una campana que suena.
	--   ¿Qué quiero que sienta el jugador? Belleza helada y miedo callado.
	---------------------------------------------------------------------
	Nivalis_Llegada = {
		Duration = 20,
		Skippable = true,
		FadeIn = true,
		Sting = "Momento",
		Anchors = {
			Patio = "Place:Nivalis_Plataforma",
			Yo = "Player",
			Plaza = "Place:Nivalis_Plaza",
			Estatua = { Place = "Nivalis_Estatua", Offset = V(0, 8, 10) },
			Palacio = { Place = "Nivalis_PuertaNorte", Offset = V(0, 160, -520) },
		},
		Tracks = {
			Camera = {
				{ At = 0, Duration = 4.6, From = { "Patio", V(0, 90, 160) }, To = { "Patio", V(0, 40, 70) }, Look = { "Palacio" }, Fov = { 62, 50 }, Cut = "Fade" },
				{ At = 4.6, Duration = 3.6, Fixed = { "Patio", V(-8, 4, 14) }, Look = { "Palacio" }, Fov = 38, Cut = "Cut" },
				{ At = 8.2, Duration = 4.4, From = { "Plaza", V(-30, 14, -10) }, To = { "Plaza", V(-10, 8, 6) }, Look = { "Estatua" }, Fov = 50, Cut = "Cut" },
				{ At = 12.6, Duration = 7.4, Fixed = { "Yo", V(4, 3, 7) }, Look = { "Yo" }, Fov = 48, Cut = "Cut" },
			},
			Sound = {
				{ At = 0.4, Play = "Hum", Pitch = 0.35, Volume = 0.5 },
				{ At = 5, Play = "Ping", Pitch = 0.5, Volume = 0.6 },
				{ At = 6.4, Play = "Ping", Pitch = 0.5, Volume = 0.5 },
			},
			Music = {
				{ At = 0, Intensity = "Descubrimiento" },
				{ At = 8.2, Intensity = "Intima" },
			},
			Dialogue = {
				{ At = 4.9, S = "Narrador", T = "Sobre el Palacio de Escarcha, la aurora baila verde y rosa. Sobre el barrio, nada." },
				{ At = 8.6, S = "Narrador", T = "Una estatua sin cabeza. Una vela a sus pies. Y nadie en la plaza que diga una palabra." },
				{ At = 13, S = "Narrador", T = "Aquí siempre es de noche. Y el frío no espera a que te acostumbres." },
			},
			Titles = {
				{ At = 0.8, Text = "❄ Nivalis · Fortaleza Albor", Sub = "Saga 2 · Episodio 4: «La noche del Regente»", Duration = 3 },
			},
		},
	},

	---------------------------------------------------------------------
	-- Nivalis_05 · LA PRINCESA. Una figura de blanco sale de la sombra del pasadizo.
	--   ¿Qué está pasando? Ilse, la heredera que «murió» en el Glaciar, viene a por Tila.
	--   ¿Por qué? Tila mandó el mensaje de los faroles; quien contestó desde las Minas fue ella.
	--   ¿Qué siente el personaje? Tila: no se lo cree. Ilse: cansancio y decisión.
	--   ¿Qué ve el jugador? La vela, la capa blanca y la aurora que, por un instante, se asoma al barrio.
	--   ¿Qué quiero que sienta el jugador? Que acaba de empezar algo grande.
	---------------------------------------------------------------------
	Nivalis_Princesa = {
		Duration = 21,
		Skippable = true,
		FadeIn = true,
		Anchors = {
			Pasadizo = "Place:Nivalis_Pasadizo",
			Yo = "Player",
			Cielo = { Place = "Nivalis_Pasadizo", Offset = V(60, 140, -300) },
		},
		Tracks = {
			Camera = {
				{ At = 0, Duration = 4, Fixed = { "Pasadizo", V(6, 3, 10) }, Look = { "Pasadizo" }, Fov = 50, Cut = "Fade" },
				{ At = 4, Duration = 3.4, Shot = "Medio:PrincesaIlse", Cut = "Cut" },
				{ At = 7.4, Duration = 3.2, Shot = "Reaccion:Tila", Cut = "Cut" },
				{ At = 10.6, Duration = 10.4, Fixed = { "Pasadizo", V(-4, 2, 8) }, Look = { "Cielo" }, Fov = 58, Cut = "Cut" },
			},
			Fx = {
				{ At = 11, Play = "Flash", Anchor = "Cielo" },
			},
			Music = {
				{ At = 0, Intensity = "Intima" },
				{ At = 10.6, Intensity = "Tema" },
			},
			Actors = {
				{ At = 0, Use = { Key = "PrincesaIlse", Npc = "PrincesaIlse", Anchor = "Pasadizo", Offset = V(-2, 0, -5) } },
				{ At = 0, Use = { Key = "Tila", Npc = "Tila", Anchor = "Pasadizo", Offset = V(2, 0, 2) } },
				{ At = 0.3, Look = { Key = "Tila", At = "PrincesaIlse" } },
				{ At = 4, Look = { Key = "PrincesaIlse", At = "Tila" } },
				{ At = 7.5, Mood = { Key = "Tila", Mood = "Surprise" } },
				{ At = 10.6, Look = { Key = "PrincesaIlse", At = "Cielo" } },
			},
			Dialogue = {
				{ At = 1, S = "Narrador", T = "Una capa blanca sale de la sombra del pasadizo. Sin farol. Sin ruido." },
				{ At = 4.4, S = "PrincesaIlse", T = "Hola, Tila. Tus faroles se ven desde las Minas.", To = "Tila" },
				{ At = 7.8, S = "Tila", T = "…Princesa Ilse. Usted está muerta. Lo dijo el Regente.", To = "PrincesaIlse" },
				{ At = 13, S = "Narrador", T = "Por un instante, la aurora se asoma sobre la Muralla Vieja. Como si alguien la hubiera llamado." },
			},
		},
	},

	---------------------------------------------------------------------
	-- Nivalis_Peligro · el peligro del terreno de este planeta (Misiones/Planetas_Peligros; shared/Cosmos/TerrainPerils).
	--   Plano del sitio y del cielo, el golpe, silencio, y quien te lo va a enseñar.
	---------------------------------------------------------------------
	Nivalis_Peligro = {
		Duration = 19,
		Skippable = true,
		FadeIn = true,
		Anchors = {
			Lugar = "Place:Nivalis_Hoguera",
			Yo = "Player",
			Cielo = { Place = "Nivalis_Hoguera", Offset = V(-60, 40, -120) },
		},
		Tracks = {
			Camera = {
				{ At = 0, Duration = 5.6, From = { "Lugar", V(-14, 6, 16) }, To = { "Lugar", V(-8, 4, 12) }, Look = { "Cielo" }, Fov = { 62, 54 }, Cut = "Fade" },
				{ At = 5.6, Duration = 4.4, Shot = "Medio:Tila", Cut = "Cut" },
				{ At = 10, Duration = 3, Shot = "Reaccion:Yo", Cut = "Cut" },
				{ At = 13, Duration = 6, Shot = "PrimerPlano:Tila", Cut = "Cut" },
			},
			Fx = {
				{ At = 1.2, Play = "Dust", Anchor = "Cielo" },
			},
			Sound = {
				{ At = 1.2, Play = "Crack", Volume = 0.6 },
			},
			Music = {
				{ At = 0, Intensity = "Intima" },
			},
			Actors = {
				{ At = 0, Use = { Key = "Tila", Npc = "Tila", Anchor = "Lugar", Offset = V(2, 0, 2) } },
				{ At = 0.4, Look = { Key = "Tila", At = "Cielo" } },
				{ At = 5.6, Mood = { Key = "Tila", Mood = "Sad" } },
				{ At = 6, Look = { Key = "Tila", At = "Yo" } },
			},
			Dialogue = {
				{ At = 3.4, S = "Narrador", T = "Más allá de la hoguera, bajo la aurora, el Lago de los Ahogados parece un espejo. Tiene manchas de hielo claro, casi transparente." },
				{ At = 6.2, S = "Tila", T = "El hielo claro aguanta al que camina. Al que se para… ya has oído el nombre del lago.", To = "Yo" },
				{ At = 13.4, S = "Narrador", T = "Dicen que en las noches sin viento todavía se oye crujir." },
			},
		},
	},
}
