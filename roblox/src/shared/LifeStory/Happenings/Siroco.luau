-- Escenas de SIROCO · Puerto Calcina (Saga 2; docs/planetas/marco-planetas.md). Formato:
-- shared/LifeStory/Sequencer.luau. Las lanzan las misiones de Misiones/Siroco_Episodio con un paso
-- { Type = "Cinematic", Id = … }. Anclas: lugares «Siroco_…» (shared/Cosmos/SirocoCity.StorySpots) y "Player".

local V = Vector3.new

return {
	---------------------------------------------------------------------
	-- Siroco_01 · LLEGADA. Te posas en el Muelle de Velas justo cuando empieza la hora roja.
	--   ¿Qué está pasando? El sol rojo, que crece cada año, quema la ciudad a mediodía.
	--   ¿Por qué? Siroco se muere: en pocos años no se podrá vivir aquí.
	--   ¿Qué siente el personaje? Rafa: la prisa de siempre y ganas de presumir.
	--   ¿Qué ve el jugador? El cañón rojo, el aire que tiembla, la gente bajando a los Túneles, Rafa gritando.
	--   ¿Qué quiero que sienta el jugador? Calor. Y que aquí el sol es el enemigo.
	---------------------------------------------------------------------
	Siroco_Llegada = {
		Duration = 16,
		Skippable = true,
		FadeIn = true,
		Sting = "Momento",
		Anchors = {
			Pista = "Place:Siroco_Plataforma",
			Yo = "Player",
			Arco = { Place = "Siroco_Arco", Offset = V(0, 20, 0) },
			Sol = { Place = "Siroco_Plataforma", Offset = V(300, 260, -400) },
		},
		Tracks = {
			Camera = {
				{ At = 0, Duration = 4, From = { "Arco", V(0, 60, 140) }, To = { "Arco", V(0, 30, 60) }, Look = { "Arco" }, Fov = { 60, 52 }, Cut = "Fade" },
				{ At = 4, Duration = 3.2, Fixed = { "Pista", V(-8, 5, 10) }, Look = { "Sol" }, Fov = 45, Cut = "Cut" },
				{ At = 7.2, Duration = 2.8, Shot = "Reaccion:RafaQuiroga", Cut = "Cut" },
				{ At = 10, Duration = 4, Shot = "Medio:RafaQuiroga", Cut = "Cut" },
			},
			Fx = {
				{ At = 4.2, Play = "Flash", Anchor = "Sol" },
			},
			Sound = {
				{ At = 0.4, Play = "Hum", Pitch = 0.4, Volume = 0.5 },
				{ At = 4.2, Play = "Rumble" },
			},
			Music = {
				{ At = 0, Intensity = "Descubrimiento" },
				{ At = 7, Intensity = "Tension" },
			},
			Actors = {
				{ At = 0, Use = { Key = "RafaQuiroga", Npc = "RafaQuiroga", Anchor = "Pista", Offset = V(3, 0, 2) } },
				{ At = 4.2, Look = { Key = "RafaQuiroga", At = "Sol" } },
				{ At = 7.3, Mood = { Key = "RafaQuiroga", Mood = "Surprise" } },
				{ At = 10, Look = { Key = "RafaQuiroga", At = "Yo" } },
			},
			Dialogue = {
				{ At = 6.2, S = "Narrador", T = "El sol de Siroco ocupa un cuarto del cielo. Y cada año, un poco más." },
				{ At = 10.3, S = "RafaQuiroga", T = "¡La hora roja! ¡Todo el mundo abajo! ¡Tú también, {el/la} de la nave!", To = "Yo" },
			},
			Titles = {
				{ At = 0.8, Text = "🌞 Siroco · Puerto Calcina", Sub = "Saga 2 · Episodio 2: «El último Gran Premio»", Duration = 3 },
			},
		},
	},

	---------------------------------------------------------------------
	-- Siroco_05 · EL ARCO AL ATARDECER. Rafa delante de su nombre tachado.
	--   ¿Qué está pasando? Marisa le ha dejado flores a su hijo muerto bajo el nombre de Rafa.
	--   ¿Por qué? Hace diez años, Rafa ganó la Gran Vuelta y su copiloto Cholo murió.
	--   ¿Qué siente el personaje? Culpa vieja, y unas ganas nuevas de arreglarlo.
	--   ¿Qué ve el jugador? El sol rojo que se pone detrás del Arco, Rafa tocando la piedra.
	--   ¿Qué quiero que sienta el jugador? Que esta carrera no va de ganar.
	---------------------------------------------------------------------
	Siroco_Arco = {
		Duration = 15,
		Skippable = true,
		FadeIn = true,
		Anchors = {
			Arco = "Place:Siroco_Arco",
			Yo = "Player",
			Nombre = { Place = "Siroco_Arco", Offset = V(5, 28, -4) },
		},
		Tracks = {
			Camera = {
				{ At = 0, Duration = 4, Fixed = { "Arco", V(0, 6, 60) }, Look = { "Nombre" }, Fov = 52, Cut = "Fade" },
				{ At = 4, Duration = 3.4, Fixed = { "Arco", V(6, 22, 10) }, Look = { "Nombre" }, Fov = 34, Cut = "Cut" },
				{ At = 7.4, Duration = 5.6, Shot = "PrimerPlano:RafaQuiroga", Cut = "Cut" },
			},
			Music = {
				{ At = 0, Intensity = "Intima" },
			},
			Actors = {
				{ At = 0, Use = { Key = "RafaQuiroga", Npc = "RafaQuiroga", Anchor = "Arco", Offset = V(3, 0, -4) } },
				{ At = 0.3, Look = { Key = "RafaQuiroga", At = "Nombre" } },
				{ At = 0.5, Mood = { Key = "RafaQuiroga", Mood = "Sad" } },
			},
			Dialogue = {
				{ At = 4.4, S = "Narrador", T = "«R. QUIROGA». Una raya furiosa encima. Y debajo, tres flores de noche." },
				{ At = 8, S = "RafaQuiroga", T = "Diez años sin pasar por debajo del Arco. Diez.", Pause = 0.8 },
				{ At = 10.8, S = "RafaQuiroga", T = "Cholo, si me oyes: una más. La última.", To = "Yo" },
			},
		},
	},

	---------------------------------------------------------------------
	-- Siroco_Peligro · el peligro del terreno de este planeta (Misiones/Planetas_Peligros; shared/Cosmos/TerrainPerils).
	--   Plano del sitio y del cielo, el golpe, silencio, y quien te lo va a enseñar.
	---------------------------------------------------------------------
	Siroco_Peligro = {
		Duration = 19,
		Skippable = true,
		FadeIn = true,
		Anchors = {
			Lugar = "Place:Siroco_Fuente",
			Yo = "Player",
			Cielo = { Place = "Siroco_Fuente", Offset = V(200, 30, -260) },
		},
		Tracks = {
			Camera = {
				{ At = 0, Duration = 5.6, From = { "Lugar", V(-14, 6, 16) }, To = { "Lugar", V(-8, 4, 12) }, Look = { "Cielo" }, Fov = { 62, 54 }, Cut = "Fade" },
				{ At = 5.6, Duration = 4.4, Shot = "Medio:TavoAguador", Cut = "Cut" },
				{ At = 10, Duration = 3, Shot = "Reaccion:Yo", Cut = "Cut" },
				{ At = 13, Duration = 6, Shot = "PrimerPlano:TavoAguador", Cut = "Cut" },
			},
			Fx = {
				{ At = 0.8, Play = "Dust", Anchor = "Cielo" },
			},
			Sound = {
				{ At = 0.4, Play = "Hum", Pitch = 0.5, Volume = 0.4 },
				{ At = 1.2, Play = "Whoosh", Volume = 0.5 },
			},
			Music = {
				{ At = 0, Intensity = "Tension" },
			},
			Actors = {
				{ At = 0, Use = { Key = "TavoAguador", Npc = "TavoAguador", Anchor = "Lugar", Offset = V(2, 0, 2) } },
				{ At = 0.4, Look = { Key = "TavoAguador", At = "Cielo" } },
				{ At = 5.6, Mood = { Key = "TavoAguador", Mood = "Sad" } },
				{ At = 6, Look = { Key = "TavoAguador", At = "Yo" } },
			},
			Dialogue = {
				{ At = 3.4, S = "Narrador", T = "Más allá del cañón, las dunas. Algunas manchas de arena brillan como si estuvieran mojadas." },
				{ At = 6.2, S = "TavoAguador", T = "Ahí. ¿Ves la arena oscura? Mi carro está debajo. Y no pienso ir a por él solo.", To = "Yo" },
				{ At = 13.4, S = "Narrador", T = "En Siroco no llueve nunca. Por eso, lo que parece mojado da miedo." },
			},
		},
	},
}
