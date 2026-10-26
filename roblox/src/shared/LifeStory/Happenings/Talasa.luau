-- Escenas de TÁLASA · Abisalia (Saga 2, «Marea negra»; docs/planetas/talasa-vertice.md). Formato:
-- shared/LifeStory/Sequencer.luau. Las lanzan las misiones de Misiones/Talasa_Episodio con un paso
-- { Type = "Cinematic", Id = … }. Anclas: lugares «Talasa_…» (shared/Cosmos/TalasaCity.StorySpots) y "Player".
-- Si el barrio no está construido, el motor usa al jugador como ancla. 13+: el miedo es el mar y el
-- silencio; nada de sangre.

local V = Vector3.new

return {
	---------------------------------------------------------------------
	-- Talasa_01 · LLEGADA. Te posas en la plataforma de Abisalia, en mitad del mar.
	--   ¿Qué está pasando? Una ciudad blanca sobre pilotes, tres lunas en el cielo verde y cintas de
	--   cuarentena en el Faro.  ¿Por qué? El coral negro sube desde el fondo y se come el metal.
	--   ¿Qué siente el personaje? Cosme: asombro, y luego inquietud.
	--   ¿Qué ve el jugador? El Faro de Mareas, las Balsas, las lunas y algo oscuro bajo el agua turquesa.
	--   ¿Qué quiero que sienta el jugador? «Qué bonito»… y un escalofrío.
	---------------------------------------------------------------------
	Talasa_Llegada = {
		Duration = 21,
		Skippable = true,
		FadeIn = true,
		Sting = "Momento",
		Anchors = {
			Plataforma = "Place:Talasa_Plataforma",
			Yo = "Player",
			Faro = { Place = "Talasa_Faro", Offset = V(0, 50, 26) },
			Balsas = { Place = "Talasa_Balsas", Offset = V(0, 4, 0) },
			Lunas = { Place = "Talasa_Plataforma", Offset = V(300, 520, -760) },
			Agua = { Place = "Talasa_Muelle", Offset = V(60, -14, 10) },
		},
		Tracks = {
			Camera = {
				{ At = 0, Duration = 4.8, From = { "Plataforma", V(-120, 70, 200) }, To = { "Plataforma", V(-60, 36, 110) }, Look = { "Faro" }, Fov = { 64, 52 }, Cut = "Fade" },
				{ At = 4.8, Duration = 3.6, Fixed = { "Plataforma", V(-10, 6, 20) }, Look = { "Lunas" }, Fov = 46, Cut = "Cut" },
				{ At = 8.4, Duration = 3.8, From = { "Balsas", V(30, 16, -30) }, To = { "Balsas", V(10, 10, -10) }, Look = { "Balsas" }, Fov = 50, Cut = "Cut" },
				{ At = 12.2, Duration = 2.8, Fixed = { "Agua", V(-20, 22, -24) }, Look = { "Agua" }, Fov = 40, Cut = "Cut" },
				{ At = 15, Duration = 4, Shot = "Medio:Cosme", Cut = "Cut" },
			},
			Sound = {
				{ At = 0.3, Play = "Hum", Pitch = 0.4, Volume = 0.5 },
				{ At = 12.4, Play = "Hum", Pitch = 0.3, Volume = 0.6 },
			},
			Music = {
				{ At = 0, Intensity = "Descubrimiento" },
				{ At = 12.2, Intensity = "Tension" },
			},
			Actors = {
				{ At = 0, Use = { Key = "Cosme", Npc = "Cosme", Anchor = "Plataforma", Offset = V(3, 0, 2) } },
				{ At = 0.4, Look = { Key = "Cosme", At = "Faro" } },
				{ At = 0.6, Mood = { Key = "Cosme", Mood = "Surprise" } },
				{ At = 15, Look = { Key = "Cosme", At = "Yo" } },
				{ At = 15.2, Mood = { Key = "Cosme", Mood = "Nervous" } },
			},
			Dialogue = {
				{ At = 5, S = "Narrador", T = "Tres lunas pequeñas sobre un cielo verde. Debajo, solo mar." },
				{ At = 8.8, S = "Narrador", T = "Las Balsas: casas de tablas y lona. Llegan de abajo con lo puesto." },
				{ At = 12.6, S = "Narrador", T = "Bajo el agua turquesa, junto a los pilotes, algo negro late despacio." },
				{ At = 15.4, S = "Cosme", T = "La ciudad más bonita de la galaxia, criatura. Y nadie sonríe.", To = "Yo" },
			},
			Titles = {
				{ At = 0.8, Text = "🌊 Tálasa · Abisalia", Sub = "Saga 2 · Episodio 3: «Marea negra»", Duration = 3 },
			},
		},
	},

	---------------------------------------------------------------------
	-- Talasa_05 · CIERRE. La Almirante Coria habla a la ciudad desde el Faro; Noa mira el mar.
	--   ¿Qué está pasando? El Consejo cierra el Tubo; abajo, la Cúpula Honda aguanta con aire para días.
	--   ¿Por qué? El coral negro ha llegado al tramo del metro.
	--   ¿Qué siente el personaje? Noa: culpa y prisa. Coria: el peso de decidir.
	--   ¿Qué ve el jugador? El anillo del Faro en rojo, las pecas de la gente apagándose, Noa sola en la cubierta.
	--   ¿Qué quiero que sienta el jugador? Que esto acaba de empezar.
	---------------------------------------------------------------------
	Talasa_Cierre = {
		Duration = 23,
		Skippable = true,
		FadeIn = true,
		FadeOut = true,
		Sting = "Momento",
		Anchors = {
			Faro = "Place:Talasa_Faro",
			Yo = "Player",
			Torre = { Place = "Talasa_Faro", Offset = V(0, 62, 26) },
			Mar = { Place = "Talasa_Faro", Offset = V(80, -14, -40) },
		},
		Tracks = {
			Camera = {
				{ At = 0, Duration = 4.6, From = { "Faro", V(-40, 20, -60) }, To = { "Faro", V(-20, 40, -30) }, Look = { "Torre" }, Fov = { 58, 46 }, Cut = "Fade" },
				{ At = 4.6, Duration = 4.6, Shot = "Medio:AlmiranteCoria", Cut = "Cut" },
				{ At = 9.2, Duration = 4.4, Shot = "PrimerPlano:NoaFerran", Cut = "Cut" },
				{ At = 13.6, Duration = 3.4, Fixed = { "Faro", V(30, 8, -50) }, Look = { "Mar" }, Fov = 42, Cut = "Cut" },
				{ At = 17, Duration = 4, Shot = "Medio:Cosme", Cut = "Cut" },
			},
			Sound = {
				{ At = 0.4, Play = "Hum", Pitch = 0.3, Volume = 0.6 },
				{ At = 13.8, Play = "Ping", Pitch = 0.4, Volume = 0.6 },
			},
			Music = {
				{ At = 0, Intensity = "Tension" },
				{ At = 9.2, Intensity = "Intima" },
			},
			Actors = {
				{ At = 0, Use = { Key = "AlmiranteCoria", Npc = "AlmiranteCoria", Anchor = "Faro", Offset = V(-3, 0, 2) } },
				{ At = 0, Use = { Key = "NoaFerran", Npc = "NoaFerran", Anchor = "Faro", Offset = V(3, 0, 2) } },
				{ At = 0, Use = { Key = "Cosme", Npc = "Cosme", Anchor = "Faro", Offset = V(0, 0, 5) } },
				{ At = 4.8, Mood = { Key = "AlmiranteCoria", Mood = "Angry" } },
				{ At = 9.4, Mood = { Key = "NoaFerran", Mood = "Sad" } },
				{ At = 9.4, Look = { Key = "NoaFerran", At = "Mar" } },
				{ At = 17.2, Look = { Key = "Cosme", At = "Yo" } },
			},
			Dialogue = {
				{ At = 5, S = "AlmiranteCoria", T = "Abisalia: el Tubo queda cerrado. Nadie baja a la Cúpula Honda. Es una orden." },
				{ At = 9.6, S = "NoaFerran", T = "Aguanta, Elio. Voy a bajar a por ti. Aunque tenga que deshacer todo lo que hice." },
				{ At = 13.8, S = "Narrador", T = "Debajo de la ciudad, el coral negro late. Más rápido que ayer." },
				{ At = 17.3, S = "Cosme", T = "Vamos a necesitar un traje mejor, criatura. Y una bajada muy larga.", To = "Yo" },
			},
			Titles = {
				{ At = 18.4, Text = "Continuará: «La Cúpula Honda»", Sub = "Tálasa · «Marea negra»", Duration = 2.6 },
			},
		},
	},
}
