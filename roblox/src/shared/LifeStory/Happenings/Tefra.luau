-- Escenas de TEFRA (Saga 2, episodio 1 «Ceniza en Bastión»: docs/planetas/tefra-misiones.md).
-- Formato: shared/LifeStory/Sequencer.luau. Las lanzan las misiones de Misiones/Tefra_Episodio con un
-- paso { Type = "Cinematic", Id = … } o como escena ligera (Effects.Scene).
--
-- Anclas: lugares «Tefra_…» (shared/LifeStory/Locations, marcas StorySpot de Bastión Ceniza) y "Player".
-- Si la ciudad no está construida, el motor usa al jugador como ancla: nunca mira al vacío.
-- 13+: sin sangre; las explosiones son humo, fuego y cascotes, lejos de la gente.

local V = Vector3.new

return {
	---------------------------------------------------------------------
	-- Tefra_01 · LLEGADA. Bajas de la nave en el Muelle y Cosme ve por primera vez en 38 años lo que
	-- queda de su planeta.
	--   ¿Qué está pasando? Suenan las sirenas: Ovilla dispara sobre el Ovillo.
	--   ¿Por qué? La guerra entre Tefra y su luna dura ya seis años.
	--   ¿Qué siente el personaje? Cosme: que no reconoce su casa.
	--   ¿Qué ve el jugador? La plataforma, la Lanza a lo lejos, Cosme, y una bomba que cae en las cúpulas.
	--   ¿Qué quiero que sienta el jugador? Que ha llegado a un sitio en guerra, y que a Cosme le duele.
	---------------------------------------------------------------------
	Tefra_Llegada = {
		Duration = 17,
		Skippable = true,
		FadeIn = true,
		Sting = "Momento",
		Anchors = {
			Plataforma = "Place:Tefra_Plataforma",
			Yo = "Player",
			Lanza = { Place = "Tefra_Lanza", Offset = V(0, 60, 0) },
			Ovillo = { Place = "Tefra_RuinasOvillo", Offset = V(0, 0, -20), Ground = true },
		},
		Tracks = {
			Camera = {
				{ At = 0, Duration = 3.4, Shot = "General:Plataforma", Cut = "Fade" },
				-- Inserto: la Lanza, lejos, entre el humo
				{ At = 3.4, Duration = 3, Fixed = { "Yo", V(3, 2, 5) }, Look = { "Lanza" }, Fov = { 55, 40 }, Cut = "Cut" },
				{ At = 6.4, Duration = 3.2, Shot = "Reaccion:Cosme", Cut = "Cut" },
				{ At = 9.6, Duration = 3.4, Fixed = { "Plataforma", V(-20, 14, 30) }, Look = { "Ovillo" }, Fov = 58, Shake = 0.3, Cut = "Cut" },
				{ At = 13, Duration = 4, Shot = "Medio:Cosme", Cut = "Cut" },
			},
			Fx = {
				{ At = 9.9, Play = "Explosion", Anchor = "Ovillo" },
			},
			Shake = {
				{ At = 10, Strength = 0.5, Seconds = 1 },
			},
			Sound = {
				{ At = 0.5, Play = "Hum", Pitch = 0.5, Volume = 0.7 },
				{ At = 2.5, Play = "Hum", Pitch = 0.45, Volume = 0.7 },
				{ At = 9.9, Play = "Boom" },
			},
			Music = {
				{ At = 0, Intensity = "Tension" },
				{ At = 13, Intensity = "Intima" },
			},
			Actors = {
				{ At = 0, Use = { Key = "Cosme", Npc = "Cosme", Anchor = "Plataforma", Offset = V(3, 0, 2) } },
				{ At = 0.4, Look = { Key = "Cosme", At = "Lanza" } },
				{ At = 0.6, Mood = { Key = "Cosme", Mood = "Surprise" } },
				{ At = 10, Look = { Key = "Cosme", At = "Ovillo" } },
				{ At = 10.2, Mood = { Key = "Cosme", Mood = "Fear" } },
				{ At = 13, Look = { Key = "Cosme", At = "Yo" } },
				{ At = 13.2, Mood = { Key = "Cosme", Mood = "Sad" } },
			},
			Dialogue = {
				{ At = 6.6, S = "Cosme", T = "…Tefra. Aquí nada tenía esquinas, criatura. Nada.", To = "Yo" },
				{ At = 13.4, S = "Cosme", T = "Esto no es mi casa. Esto es un cuartel.", Pause = 0.6, To = "Yo" },
			},
			Titles = {
				{ At = 0.6, Text = "🌋 Tefra · Bastión Ceniza", Sub = "Saga 2 · Episodio 1: «Ceniza en Bastión»", Duration = 3 },
			},
		},
	},

	---------------------------------------------------------------------
	-- Tefra_01 · LAS SIRENAS (ligera): mientras corres al refugio, retumba la artillería de Ovilla.
	--   ¿Qué está pasando? Cae fuego sobre la Muralla.  ¿Por qué? El bombardeo de la tarde.
	--   ¿Qué siente el personaje? Prisa.  ¿Qué ve el jugador? Un fogonazo lejos y el suelo temblando.
	--   ¿Qué quiero que sienta el jugador? Que aquí las sirenas van en serio.
	---------------------------------------------------------------------
	Tefra_Sirenas = {
		Duration = 6,
		Light = true,
		Anchors = { Yo = "Player" },
		Tracks = {
			Fx = {
				{ At = 1.2, Play = "Explosion", Anchor = "Yo", Offset = V(40, 0, -70) },
				{ At = 3.4, Play = "Explosion", Anchor = "Yo", Offset = V(-55, 0, -60) },
			},
			Shake = {
				{ At = 1.3, Strength = 0.35, Seconds = 0.8 },
				{ At = 3.5, Strength = 0.3, Seconds = 0.8 },
			},
			Sound = {
				{ At = 0, Play = "Hum", Pitch = 0.5, Volume = 0.8 },
				{ At = 1.2, Play = "Boom" },
				{ At = 3.4, Play = "Boom" },
			},
		},
	},

	---------------------------------------------------------------------
	-- Tefra_06 · LA LANZA DISPARA. Corvo dispara la primera descarga: la lente se enciende y el rayo
	-- cae al Este. La tierra se agrieta y los volcanes dormidos despiertan.
	--   ¿Qué está pasando? La Lanza dispara sobre Ovilla y agrieta la corteza del Este.
	--   ¿Por qué? Corvo quiere ganar la guerra cueste lo que cueste.
	--   ¿Qué siente el personaje? Dalia, horror; Cosme, que el planeta se rompe bajo sus pies.
	--   ¿Qué ve el jugador? La lente cargándose, el destello, el temblor y humo en el horizonte.
	--   ¿Qué quiero que sienta el jugador? Que si dispara otra vez, se acaba todo.
	---------------------------------------------------------------------
	Tefra_LanzaDispara = {
		Duration = 16,
		Skippable = true,
		FadeIn = true,
		Anchors = {
			Base = "Place:Tefra_Lanza",
			Yo = "Player",
			Lente = { Place = "Tefra_Lanza", Offset = V(0, 116, 22) },
			Este = { Place = "Tefra_TierraDeNadie", Offset = V(120, 0, 0), Ground = true },
		},
		Tracks = {
			Camera = {
				{ At = 0, Duration = 3, Shot = "General:Base", Cut = "Fade" },
				-- La cámara sube por la torre hasta la lente
				{ At = 3, Duration = 3.4, From = { "Base", V(0, 4, 40) }, To = { "Base", V(0, 30, 46) }, Look = { "Base", V(0, 20, 0) }, LookTo = { "Lente" }, Fov = { 60, 42 } },
				{ At = 6.4, Duration = 2.6, Fixed = { "Base", V(-30, 10, 60) }, Look = { "Este" }, Fov = 50, Shake = 0.5, Cut = "Flash" },
				{ At = 9, Duration = 3.2, Shot = "Reaccion:DaliaRenn", Cut = "Cut" },
				{ At = 12.2, Duration = 3.8, Shot = "DosPlanos:DaliaRenn,Cosme", Cut = "Cut" },
			},
			Fx = {
				{ At = 3.2, Play = "MysticOrb", Anchor = "Lente", Seconds = 3.4, Params = { Scale = 2.2 } },
				{ At = 6.5, Play = "Flash", Anchor = "Lente" },
				{ At = 7, Play = "Explosion", Anchor = "Este" },
			},
			Shake = {
				{ At = 6.6, Strength = 1.2, Seconds = 1.6 },
				{ At = 9.4, Strength = 0.5, Seconds = 2.4 },
			},
			Sound = {
				{ At = 3.2, Play = "Hum", Pitch = 0.3, Volume = 0.8 },
				{ At = 6.5, Play = "Thunder" },
				{ At = 7.2, Play = "Rumble" },
			},
			Music = {
				{ At = 0, Intensity = "Tension" },
			},
			Actors = {
				{ At = 0, Use = { Key = "DaliaRenn", Npc = "DaliaRenn", Anchor = "Base", Offset = V(-4, 0, 22) } },
				{ At = 0, Use = { Key = "Cosme", Npc = "Cosme", Anchor = "Base", Offset = V(4, 0, 22) } },
				{ At = 3.1, Look = { Key = "DaliaRenn", At = "Lente" } },
				{ At = 3.2, Look = { Key = "Cosme", At = "Lente" } },
				{ At = 6.8, Mood = { Key = "DaliaRenn", Mood = "Fear" } },
				{ At = 7, Look = { Key = "DaliaRenn", At = "Este" } },
				{ At = 7.1, Look = { Key = "Cosme", At = "Este" } },
				{ At = 9.2, Mood = { Key = "Cosme", Mood = "Sad" } },
			},
			Dialogue = {
				{ At = 9.2, S = "DaliaRenn", T = "No… Ha disparado. Corvo ha disparado de verdad." },
				{ At = 12.4, S = "Cosme", T = "Ha roto la tierra. Al Este. Lo noto en los pies.", To = "DaliaRenn" },
			},
		},
	},

	---------------------------------------------------------------------
	-- Tefra_06 · LA LANZA CAE. El núcleo revienta y la lente se parte. Lo ves desde la puerta del refugio.
	--   ¿Qué está pasando? La Lanza se derrumba antes del segundo disparo.
	--   ¿Por qué? Habéis sobrecargado su núcleo.
	--   ¿Qué siente el personaje? Alivio y miedo a la vez.
	--   ¿Qué ve el jugador? La torre partiéndose entre humo y chispas; tu cara.
	--   ¿Qué quiero que sienta el jugador? Que lo ha conseguido, pero que algo se ha roto para siempre.
	---------------------------------------------------------------------
	Tefra_LanzaCae = {
		Duration = 12,
		Skippable = true,
		FadeIn = true,
		Sting = "Momento",
		Anchors = {
			Base = "Place:Tefra_Lanza",
			Yo = "Player",
			Cima = { Place = "Tefra_Lanza", Offset = V(0, 100, 22) },
		},
		Tracks = {
			Camera = {
				{ At = 0, Duration = 3.6, Fixed = { "Base", V(-50, 20, 90) }, Look = { "Cima" }, Fov = 55, Cut = "Fade" },
				{ At = 3.6, Duration = 3.2, Fixed = { "Base", V(-50, 20, 90) }, Look = { "Base", V(0, 30, 0) }, Fov = 62, Shake = 0.4 },
				{ At = 6.8, Duration = 2.6, Shot = "Reaccion:Yo", Cut = "Cut" },
				{ At = 9.4, Duration = 2.6, Shot = "General:Base", Cut = "Cut" },
			},
			Fx = {
				{ At = 1, Play = "Explosion", Anchor = "Cima" },
				{ At = 3.8, Play = "Explosion", Anchor = "Base", Offset = V(0, 30, 22) },
			},
			Shake = {
				{ At = 1.1, Strength = 0.8, Seconds = 1.2 },
				{ At = 3.9, Strength = 1, Seconds = 1.6 },
			},
			Sound = {
				{ At = 1, Play = "Boom" },
				{ At = 3.8, Play = "Rumble" },
			},
			Music = {
				{ At = 0, Intensity = "Tension" },
				{ At = 6.8, Intensity = "Resolucion" },
			},
			Titles = {
				{ At = 9.6, Text = "📍 La Lanza ha caído", Sub = "No habrá segundo disparo", Duration = 2.4 },
			},
		},
	},

	---------------------------------------------------------------------
	-- Tefra_07 · MOMENTO DE SILENCIO. Cosme, solo, delante de la estatua de su abuela Nilda.
	--   ¿Qué está pasando? Se ha acabado la guerra (por ahora) y Cosme acaba de saber lo de Ada.
	--   ¿Por qué? Fermina le ha contado cómo murió su hermana hace dos años.
	--   ¿Qué siente el personaje? Pena, y una culpa muy vieja: se fue y no volvió.
	--   ¿Qué ve el jugador? La estatua con su bufanda de piedra, ceniza cayendo y la espalda de Cosme.
	--   ¿Qué quiero que sienta el jugador? Silencio. Sin música ni chistes.
	---------------------------------------------------------------------
	Tefra_Silencio = {
		Duration = 15,
		Skippable = true,
		FadeIn = true,
		Anchors = {
			Estatua = { Place = "Tefra_Estatua", Offset = V(0, 0, -20) },
			Sitio = "Place:Tefra_Estatua",
			Yo = "Player",
		},
		Tracks = {
			Camera = {
				{ At = 0, Duration = 4, Fixed = { "Sitio", V(10, 4, 14) }, Look = { "Estatua", V(0, 6, 0) }, Fov = 50, Cut = "Fade" },
				{ At = 4, Duration = 5, Shot = "Medio:Cosme", Cut = "Cut" },
				{ At = 9, Duration = 6, From = { "Sitio", V(0, 3, 10) }, To = { "Sitio", V(0, 8, 22) }, Look = { "Estatua", V(0, 5, 0) }, Fov = { 50, 58 } },
			},
			Music = {
				{ At = 0, Intensity = "Nada" },
			},
			Actors = {
				{ At = 0, Use = { Key = "Cosme", Npc = "Cosme", Anchor = "Sitio", Offset = V(0, 0, -3) } },
				{ At = 0.2, Look = { Key = "Cosme", At = "Estatua" } },
				{ At = 0.3, Mood = { Key = "Cosme", Mood = "Sad" } },
			},
			Dialogue = {
				{ At = 4.6, S = "Cosme", T = "Hola, abuela.", To = "Yo" },
				{ At = 8.2, S = "Cosme", T = "He vuelto tarde.", Pause = 1.2, To = "Yo" },
			},
		},
	},
}
