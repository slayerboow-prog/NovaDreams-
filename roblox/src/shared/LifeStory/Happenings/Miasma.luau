-- Escenas de MIASMA · Anclaje Siete (Saga 2; docs/planetas/marco-planetas.md). Formato:
-- shared/LifeStory/Sequencer.luau. Las lanzan las misiones de Misiones/Miasma_Episodio con un paso
-- { Type = "Cinematic", Id = … }. Anclas: lugares «Miasma_…» (shared/Cosmos/MiasmaCity.StorySpots) y "Player".
-- 13+: sin sangre; las explosiones son humo y fogonazos lejos de la gente.

local V = Vector3.new

return {
	---------------------------------------------------------------------
	-- Miasma_01 · LLEGADA. Te posas en el Muelle de Vientos en mitad del asedio.
	--   ¿Qué está pasando? La batería antiaérea dispara contra la flota del Dominio Talar.
	--   ¿Por qué? El Dominio quiere el gas pesado de Miasma y bloquea el cielo.
	--   ¿Qué siente el personaje? Mara: prisa y un poco de gracia por el forastero.
	--   ¿Qué ve el jugador? Los discos sobre la niebla verde, fogonazos arriba, Mara haciendo señas.
	--   ¿Qué quiero que sienta el jugador? Vértigo: una ciudad colgada del aire, y en guerra.
	---------------------------------------------------------------------
	Miasma_Llegada = {
		Duration = 17,
		Skippable = true,
		FadeIn = true,
		Sting = "Momento",
		Anchors = {
			Pista = "Place:Miasma_Plataforma",
			Yo = "Player",
			Bateria = { Place = "Miasma_Bateria", Offset = V(0, 8, 0) },
			Cielo = { Place = "Miasma_Plataforma", Offset = V(80, 220, -260) },
			Niebla = { Place = "Miasma_BordeLastre", Offset = V(-60, -120, 80) },
		},
		Tracks = {
			Camera = {
				{ At = 0, Duration = 4, From = { "Pista", V(-90, 60, 120) }, To = { "Pista", V(-40, 30, 70) }, Look = { "Pista" }, Fov = { 62, 55 }, Cut = "Fade" },
				{ At = 4, Duration = 3, Fixed = { "Pista", V(10, 4, 20) }, Look = { "Niebla" }, Fov = 58, Cut = "Cut" },
				{ At = 7, Duration = 3.4, Fixed = { "Bateria", V(-8, 2, 12) }, Look = { "Cielo" }, Fov = 50, Shake = 0.3, Cut = "Cut" },
				{ At = 10.4, Duration = 4.6, Shot = "Medio:MaraSolis", Cut = "Cut" },
			},
			Fx = {
				{ At = 7.4, Play = "Flash", Anchor = "Cielo" },
				{ At = 8.6, Play = "Explosion", Anchor = "Cielo", Offset = V(-120, 30, 40) },
			},
			Shake = {
				{ At = 7.5, Strength = 0.3, Seconds = 0.8 },
				{ At = 8.7, Strength = 0.4, Seconds = 1 },
			},
			Sound = {
				{ At = 0.4, Play = "Hum", Pitch = 0.6, Volume = 0.6 },
				{ At = 7.4, Play = "Boom" },
				{ At = 8.6, Play = "Thunder" },
			},
			Music = {
				{ At = 0, Intensity = "Descubrimiento" },
				{ At = 7, Intensity = "Tension" },
			},
			Actors = {
				{ At = 0, Use = { Key = "MaraSolis", Npc = "MaraSolis", Anchor = "Pista", Offset = V(3, 0, 2) } },
				{ At = 0.4, Look = { Key = "MaraSolis", At = "Cielo" } },
				{ At = 10.4, Look = { Key = "MaraSolis", At = "Yo" } },
				{ At = 10.6, Mood = { Key = "MaraSolis", Mood = "Joy" } },
			},
			Dialogue = {
				{ At = 4.4, S = "Narrador", T = "Debajo de los discos, la niebla. Verde, lenta, sin fondo." },
				{ At = 10.8, S = "MaraSolis", T = "¡Bienvenido al último Anclaje, forastero! Agáchate, que pica.", To = "Yo" },
			},
			Titles = {
				{ At = 0.8, Text = "🌫 Miasma · Anclaje Siete", Sub = "Saga 2 · Episodio 6: «Guerra en el cielo»", Duration = 3 },
			},
		},
	},

	---------------------------------------------------------------------
	-- Miasma_04 · EL ATAQUE. Suena la sirena larga y una cápsula del Dominio cae sobre las Góndolas.
	--   ¿Qué está pasando? El Dominio desembarca soldados para cortar los cables de las góndolas.
	--   ¿Por qué? Quiere que la ciudad se rinda antes de destruirla.
	--   ¿Qué siente el personaje? Andrés: frialdad de comandante; Leo: ganas de demostrar.
	--   ¿Qué ve el jugador? La sirena, cazas que pasan, la cápsula cayendo y humo en las Góndolas.
	--   ¿Qué quiero que sienta el jugador? Urgencia: hay que correr YA.
	---------------------------------------------------------------------
	Miasma_Ataque = {
		Duration = 15,
		Skippable = true,
		FadeIn = true,
		Anchors = {
			Hangar = "Place:Miasma_Hangar",
			Yo = "Player",
			Gondolas = { Place = "Miasma_Gondolas", Offset = V(0, 20, -10) },
			Cielo = { Place = "Miasma_Gondolas", Offset = V(60, 160, -120) },
		},
		Tracks = {
			Camera = {
				{ At = 0, Duration = 3.2, Shot = "DosPlanos:ComandanteAndres,LeoSolis", Cut = "Fade" },
				{ At = 3.2, Duration = 3.8, From = { "Hangar", V(10, 6, -20) }, To = { "Hangar", V(4, 14, -40) }, Look = { "Cielo" }, LookTo = { "Gondolas" }, Fov = { 55, 48 } },
				{ At = 7, Duration = 2.6, Fixed = { "Gondolas", V(30, 14, 30) }, Look = { "Gondolas" }, Fov = 56, Shake = 0.5, Cut = "Cut" },
				{ At = 9.6, Duration = 2.4, Shot = "Reaccion:LeoSolis", Cut = "Cut" },
			},
			Fx = {
				{ At = 4, Play = "MysticOrb", Anchor = "Cielo", Seconds = 3, Params = { Scale = 1.2 } },
				{ At = 7.1, Play = "Explosion", Anchor = "Gondolas" },
			},
			Shake = {
				{ At = 7.2, Strength = 0.8, Seconds = 1.2 },
			},
			Sound = {
				{ At = 0.2, Play = "Hum", Pitch = 0.45, Volume = 0.9 },
				{ At = 1.8, Play = "Hum", Pitch = 0.45, Volume = 0.9 },
				{ At = 7.1, Play = "Boom" },
			},
			Music = {
				{ At = 0, Intensity = "Tension" },
			},
			Actors = {
				{ At = 0, Use = { Key = "ComandanteAndres", Npc = "ComandanteAndres", Anchor = "Hangar", Offset = V(2, 0, 2) } },
				{ At = 0, Use = { Key = "LeoSolis", Npc = "LeoSolis", Anchor = "Hangar", Offset = V(-2, 0, 3) } },
				{ At = 3.3, Look = { Key = "ComandanteAndres", At = "Cielo" } },
				{ At = 3.4, Look = { Key = "LeoSolis", At = "Cielo" } },
				{ At = 7.3, Mood = { Key = "LeoSolis", Mood = "Fear" } },
			},
			Dialogue = {
				{ At = 0.6, S = "ComandanteAndres", T = "Sirena larga. Es un desembarco." },
				{ At = 9.8, S = "LeoSolis", T = "¡Están en las Góndolas! ¡Van a por los cables!", To = "Yo" },
			},
		},
	},

	---------------------------------------------------------------------
	-- Miasma_05 · LA SEÑAL. Giras la antena hacia la niebla y una voz de niño canta desde abajo.
	--   ¿Qué está pasando? Desde el Anclaje Seis, caído hace 40 años, alguien emite una canción.
	--   ¿Por qué? Hay gente viva allí abajo, en una burbuja de aire (aún nadie lo sabe).
	--   ¿Qué siente el personaje? La Abuela Niebla: una esperanza que le da miedo.
	--   ¿Qué ve el jugador? La cámara que baja hacia la niebla y, muy hondo, una luz.
	--   ¿Qué quiero que sienta el jugador? Misterio: el fin del mundo podría tener un después.
	---------------------------------------------------------------------
	Miasma_Senal = {
		Duration = 17,
		Skippable = true,
		FadeIn = true,
		Sting = "Momento",
		Anchors = {
			Antena = "Place:Miasma_Antena",
			Yo = "Player",
			Abajo = { Place = "Miasma_Antena", Offset = V(140, -160, 60) },
		},
		Tracks = {
			Camera = {
				{ At = 0, Duration = 3.4, Shot = "Medio:AbuelaNiebla", Cut = "Fade" },
				{ At = 3.4, Duration = 5.6, From = { "Antena", V(12, 4, 10) }, To = { "Antena", V(60, -60, 40) }, Look = { "Abajo" }, Fov = { 56, 40 }, Cut = "Cut" },
				{ At = 9, Duration = 5, Shot = "Reaccion:AbuelaNiebla", Cut = "Fade" },
			},
			Fx = {
				{ At = 6, Play = "MysticOrb", Anchor = "Abajo", Seconds = 3.4, Params = { Scale = 0.8 } },
			},
			Sound = {
				{ At = 1, Play = "Hum", Pitch = 1.2, Volume = 0.5 },
			},
			Music = {
				{ At = 0, Intensity = "Intima" },
			},
			Actors = {
				{ At = 0, Use = { Key = "AbuelaNiebla", Npc = "AbuelaNiebla", Anchor = "Antena", Offset = V(-3, 0, 2) } },
				{ At = 0.3, Look = { Key = "AbuelaNiebla", At = "Abajo" } },
				{ At = 9.2, Mood = { Key = "AbuelaNiebla", Mood = "Sad" } },
			},
			Dialogue = {
				{ At = 3.8, S = "Narrador", T = "«Duerme, medusa, duerme en la bruma, que la niebla te mece…»" },
				{ At = 9.4, S = "AbuelaNiebla", T = "Es la canción del Seis. Alguien la está cantando ahora mismo.", To = "Yo" },
				{ At = 12, S = "AbuelaNiebla", T = "Cuarenta años diciendo que no había nadie…", Pause = 0.8 },
			},
		},
	},
}
