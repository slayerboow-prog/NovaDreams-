-- Escenas de VÉRTICE · Distrito Cero (Saga 2, «Liquidación total»; docs/planetas/talasa-vertice.md).
-- Formato: shared/LifeStory/Sequencer.luau. Las lanzan las misiones de Misiones/Vertice_Episodio con un
-- paso { Type = "Cinematic", Id = … }. Anclas: lugares «Vertice_…» (shared/Cosmos/VerticeCity.StorySpots) y
-- "Player". 13+: sátira de empresa; nadie se hace daño.

local V = Vector3.new

return {
	---------------------------------------------------------------------
	-- Vertice_01 · LLEGADA. Te posas en la plataforma de Distrito Cero, colgada sobre el Nivel Bajo.
	--   ¿Qué está pasando? Una ciudad entera de neón; un holograma te saluda por tu nombre de cliente.
	--   ¿Por qué? En Vértice todo es de MegaVerso, también tu llegada.
	--   ¿Qué siente el personaje? Cosme: deslumbrado y desconfiado.
	--   ¿Qué ve el jugador? La Torre de Ventas, el mag-lev, los anillos en el cielo y la estatua sonriente.
	--   ¿Qué quiero que sienta el jugador? «Qué pasada»… y que le están vendiendo algo.
	---------------------------------------------------------------------
	Vertice_Llegada = {
		Duration = 21,
		Skippable = true,
		FadeIn = true,
		Sting = "Momento",
		Anchors = {
			Plataforma = "Place:Vertice_Plataforma",
			Yo = "Player",
			Torre = { Place = "Vertice_Oficinas", Offset = V(0, 90, -40) },
			Anillos = { Place = "Vertice_Plataforma", Offset = V(-300, 900, -1400) },
			Estatua = { Place = "Vertice_Estatua", Offset = V(-14, 8, 6) },
			Maglev = { Place = "Vertice_Maglev", Offset = V(10, 4, -22) },
		},
		Tracks = {
			Camera = {
				{ At = 0, Duration = 5, From = { "Plataforma", V(60, 120, 220) }, To = { "Plataforma", V(30, 60, 110) }, Look = { "Torre" }, Fov = { 66, 52 }, Cut = "Fade" },
				{ At = 5, Duration = 3.4, Fixed = { "Plataforma", V(-6, 5, 18) }, Look = { "Anillos" }, Fov = 44, Cut = "Cut" },
				{ At = 8.4, Duration = 3.6, From = { "Maglev", V(-40, 12, 30) }, To = { "Maglev", V(-20, 8, 20) }, Look = { "Maglev" }, Fov = 50, Cut = "Cut" },
				{ At = 12, Duration = 4, Fixed = { "Estatua", V(-10, 4, 16) }, Look = { "Estatua" }, Fov = 42, Cut = "Cut" },
				{ At = 16, Duration = 5, Shot = "Medio:Cosme", Cut = "Cut" },
			},
			Sound = {
				{ At = 0.3, Play = "Hum", Pitch = 0.7, Volume = 0.5 },
				{ At = 8.6, Play = "Ping", Pitch = 1.2, Volume = 0.5 },
				{ At = 12.2, Play = "Ping", Pitch = 1.5, Volume = 0.5 },
			},
			Music = {
				{ At = 0, Intensity = "Descubrimiento" },
				{ At = 12, Intensity = "Tension" },
			},
			Actors = {
				{ At = 0, Use = { Key = "Cosme", Npc = "Cosme", Anchor = "Plataforma", Offset = V(3, 0, 2) } },
				{ At = 0.4, Look = { Key = "Cosme", At = "Torre" } },
				{ At = 0.6, Mood = { Key = "Cosme", Mood = "Surprise" } },
				{ At = 16, Look = { Key = "Cosme", At = "Yo" } },
				{ At = 16.2, Mood = { Key = "Cosme", Mood = "Nervous" } },
			},
			Dialogue = {
				{ At = 5.3, S = "Narrador", T = "Arriba, anillos de astilleros. Más arriba, una Cúpula que hace de cielo y vende cosas." },
				{ At = 8.8, S = "Narrador", T = "Un tren flota sobre su raíl. Cada vagón lleva un anuncio distinto." },
				{ At = 12.4, S = "Narrador", T = "El Primer Cliente sonríe en la plaza. Lleva ciento cincuenta años sonriendo." },
				{ At = 16.4, S = "Cosme", T = "Nunca había visto tanta luz junta, criatura. Y ni una sola estrella.", To = "Yo" },
			},
			Titles = {
				{ At = 0.8, Text = "🌃 Vértice · Distrito Cero", Sub = "Saga 2 · Episodio 7: «Liquidación total»", Duration = 3 },
			},
		},
	},

	---------------------------------------------------------------------
	-- Vertice_05 · CIERRE. La pantalla de la plaza se apaga y aparece Ofelia Brum en holograma.
	--   ¿Qué está pasando? MegaVerso anuncia la Liquidación Total: vender la deuda de los vecinos.
	--   ¿Por qué? La empresa está en quiebra y Ofelia prepara su salida.
	--   ¿Qué siente el personaje? Abril: rabia. Cosme: que ha visto esto antes.
	--   ¿Qué ve el jugador? La sonrisa de anuncio de Ofelia, gigante, y la gente de la plaza callada.
	--   ¿Qué quiero que sienta el jugador? Que la villana sonríe… y que «V.» es otra pregunta.
	---------------------------------------------------------------------
	Vertice_Cierre = {
		Duration = 24,
		Skippable = true,
		FadeIn = true,
		FadeOut = true,
		Sting = "Momento",
		Anchors = {
			Plaza = "Place:Vertice_Plaza",
			Yo = "Player",
			Pantalla = { Place = "Vertice_Plaza", Offset = V(46, 26, 54) },
			Torre = { Place = "Vertice_Oficinas", Offset = V(0, 100, -40) },
		},
		Tracks = {
			Camera = {
				{ At = 0, Duration = 4.4, From = { "Plaza", V(-30, 10, 40) }, To = { "Plaza", V(-20, 14, 20) }, Look = { "Pantalla" }, Fov = { 56, 46 }, Cut = "Fade" },
				{ At = 4.4, Duration = 5.6, Shot = "Medio:OfeliaBrum", Cut = "Cut" },
				{ At = 10, Duration = 4.6, Shot = "PrimerPlano:AbrilCruz", Cut = "Cut" },
				{ At = 14.6, Duration = 3.6, Fixed = { "Plaza", V(0, 40, 60) }, Look = { "Torre" }, Fov = 50, Cut = "Cut" },
				{ At = 18.2, Duration = 5.8, Shot = "Medio:Cosme", Cut = "Cut" },
			},
			Sound = {
				{ At = 0.4, Play = "Ping", Pitch = 1.4, Volume = 0.6 },
				{ At = 4.6, Play = "Hum", Pitch = 0.9, Volume = 0.6 },
			},
			Music = {
				{ At = 0, Intensity = "Tension" },
				{ At = 18.2, Intensity = "Intima" },
			},
			Actors = {
				{ At = 0, Use = { Key = "OfeliaBrum", Npc = "OfeliaBrum", Anchor = "Plaza", Offset = V(0, 0, 20) } },
				{ At = 0, Use = { Key = "AbrilCruz", Npc = "AbrilCruz", Anchor = "Plaza", Offset = V(3, 0, 2) } },
				{ At = 0, Use = { Key = "Cosme", Npc = "Cosme", Anchor = "Plaza", Offset = V(-3, 0, 3) } },
				{ At = 4.6, Mood = { Key = "OfeliaBrum", Mood = "Joy" } },
				{ At = 10.2, Mood = { Key = "AbrilCruz", Mood = "Angry" } },
				{ At = 18.4, Look = { Key = "Cosme", At = "Yo" } },
			},
			Dialogue = {
				{ At = 4.8, S = "OfeliaBrum", T = "Queridos clientes: empieza la Liquidación Total. ¡Todo debe irse! Empezando por el Barrio Plantilla." },
				{ At = 10.3, S = "AbrilCruz", T = "No venden tiendas. Venden nuestras deudas. Nos venden a nosotros." },
				{ At = 14.8, S = "Narrador", T = "Detrás de la sonrisa de Ofelia, la Torre sigue comprando luz. A alguien que firma solo con una «V»." },
				{ At = 18.6, S = "Cosme", T = "He visto esa firma antes, criatura. En un hilo negro. Y no me gustó nada.", To = "Yo" },
			},
			Titles = {
				{ At = 21, Text = "Continuará: «Liquidación total»", Sub = "Vértice · Distrito Cero", Duration = 2.6 },
			},
		},
	},
}
