-- Escenas del CIELO (Saga de la Grieta). Formato: shared/LifeStory/Sequencer.luau y
-- docs/historia/escenarios-5-diseno-implementacion.md §4.1.
--
-- Anclas: "Player" (tú, donde estés al empezar), "Place:Lugar", "Zone:Zona", "Actor:Npc" (un personaje
-- de tu misión), "Rift" (la Grieta del cielo, donde la ve tu pantalla) o { Place, Offset, Ground }
-- (un lugar desplazado, apoyado en el suelo: así coincide con los objetos de la misión).
-- Dentro de la escena también valen "Actor:<Key>" (un actor de la escena) y "Fx:<Key>" (un efecto).

local V = Vector3.new

return {
	---------------------------------------------------------------------
	-- Saga_02_Grieta · «Esta noche han caído cosas»: tres estrellas fugaces verdes salen de la Grieta y
	-- caen en el parque, el patio del cole y el camino al cole. Pip se asusta, Cosme señala, la cámara
	-- sigue a la primera hasta el impacto; de su cráter sale algo pequeño y verde que huye. Cada caída
	-- deja un cráter humeante que se QUEDA (memoria del mundo: Cielo.Crater.*).
	-- Interacción: «¡Cúbrete!» (si reaccionas a tiempo, Pip te felicita).
	---------------------------------------------------------------------
	Grieta_Caen = {
		Duration = 16.5,
		Skippable = true,
		FadeIn = true,
		Sting = "Momento",
		Anchors = {
			Garaje = "Place:GarajeCosme",
			Yo = "Player",
			Grieta = "Rift",
			Parque = { Place = "FuenteParque", Offset = V(-3, 0, 3), Ground = true },
			Patio = { Place = "JuegosColegio", Offset = V(3, 0, 3), Ground = true },
			Camino = { Place = "CaminoAlCole", Offset = V(2, 0, 2), Ground = true },
		},
		Tracks = {
			Camera = {
				{ At = 0, Duration = 1.6, From = { "Garaje", V(6, 3, 8) }, To = { "Garaje", V(5, 2.6, 7) }, Look = { "Garaje", V(0, 3, 0) }, LookTo = { "Grieta" }, Fov = { 62, 55 } },
				{ At = 1.6, Duration = 1, Fixed = { "Yo", V(3, 2, 5) }, Look = { "Grieta" }, Fov = { 60, 45 }, Shake = 0.4, Cut = "Cut" },
				{ At = 2.6, Duration = 2, Follow = "Fx:M1", Offset = V(0, 12, 30), Fov = 60, Shake = 0.25, Cut = "Flash" },
				{ At = 4.6, Duration = 2.4, Fixed = { "Parque", V(12, 4, 14) }, Look = { "Parque", V(0, 1, 0) }, Fov = { 55, 48 }, Cut = "Cut" },
				{ At = 7, Duration = 3, Orbit = "Parque", Radius = 13, Height = 5, FromAngle = 30, ToAngle = 95, LookHeight = 1, Shake = 0.2 },
				{ At = 10, Duration = 3.5, Fixed = { "Garaje", V(-5, 3.5, 7) }, Look = { "Actor:Pip", V(0, 1.2, 0) }, Fov = 50, Cut = "Dip" },
				{ At = 13.5, Duration = 3, From = { "Yo", V(4, 2, 6) }, To = { "Yo", V(10, 14, 18) }, Look = { "Yo", V(0, 2, 0) }, LookTo = { "Grieta" }, Easing = "In" },
			},
			Shake = {
				{ At = 1.8, Strength = 0.25, Seconds = 0.6 },
			},
			Sky = {
				{ At = 0, Mood = "GrietaVerde", Fade = 1.5 },
				{ At = 2, Rift = "Flare", Strength = 1, Seconds = 2.5 },
				{ At = 14.5, Mood = false, Fade = 2 },
			},
			Fx = {
				{ At = 2.2, Play = "Meteor", Key = "M1", Anchor = "Grieta", To = { "Parque" }, Seconds = 2.6 },
				{ At = 2.8, Play = "Meteor", Key = "M2", Anchor = "Grieta", To = { "Patio" }, Seconds = 2.6 },
				{ At = 3.4, Play = "Meteor", Key = "M3", Anchor = "Grieta", To = { "Camino" }, Seconds = 2.6 },
				{ At = 8.8, Play = "Poof", Anchor = "Actor:Chispa" },
			},
			Actors = {
				-- Cosme y Pip ya están en el garaje (los de la misión); si no, aparecen allí
				{ At = 0, Use = { Key = "Cosme", Npc = "Cosme", Anchor = "Garaje", Offset = V(0, 0, 3) } },
				{ At = 0, Use = { Key = "Pip", Npc = "Pip", Anchor = "Garaje", Offset = V(3, 0, 2) } },
				{ At = 0.3, Look = { Key = "Pip", At = "Grieta" } },
				{ At = 0.4, Look = { Key = "Cosme", At = "Grieta" } },
				{ At = 0.5, Mood = { Key = "Pip", Mood = "Fear" } },
				{ At = 1, Mood = { Key = "Cosme", Mood = "Surprise" } },
				{ At = 1.3, Gesture = { Key = "Cosme", Play = "Point" } },
				-- Lo que trajo la estrella del parque: sale del cráter, mira, se asusta y huye
				{ At = 5.4, Spawn = { Key = "Chispa", Creature = "Chispa", Anchor = "Parque", Mood = "Fear" } },
				{ At = 6.2, Look = { Key = "Chispa", At = "Parque" } },
				{ At = 7.2, Move = { Key = "Chispa", To = { "Parque", V(9, 0, -7) }, Run = true } },
				{ At = 8.8, Despawn = { Key = "Chispa" } },
				{ At = 10, Mood = { Key = "Cosme", Mood = "Calm" } },
				{ At = 10, Look = { Key = "Pip", At = "Yo" } },
				{ At = 10.2, Look = { Key = "Cosme", At = "Yo" } },
				{ At = 12, Gesture = { Key = "Cosme", Play = "Point" } },
			},
			Wait = {
				-- ¡Cúbrete! (un toque a tiempo). La escena se para hasta que reaccionas o pasan 3 segundos.
				{ At = 1.6, Input = "Cubrirse", Prompt = "¡Cúbrete!", Timeout = 3 },
			},
			World = {
				{ At = 4.85, Set = { ["Cielo.Crater.Parque"] = "Humeante" } },
				{ At = 5.45, Set = { ["Cielo.Crater.Patio"] = "Humeante" } },
				{ At = 6.05, Set = { ["Cielo.Crater.Camino"] = "Humeante" } },
			},
			Lines = {
				{ At = 0.3, Speaker = "Pip", Text = "¡Señor Cosme! ¡El medidor marca… TODO! ¡La raja del cielo se está encendiendo!", Mood = "Fear" },
				{ At = 1.1, Speaker = "Cosme", Text = "¡Mira arriba! ¡Algo sale de la grieta!", Mood = "Surprise" },
				{ At = 1.7, Speaker = "Pip", Text = "¡Buenos reflejos! Aunque eso cae a varios kilómetros, ¿eh?", If = { Input = "Cubrirse" } },
				{ At = 1.7, Speaker = "Pip", Text = "¡Agáchate! …Vale, da igual. Cae lejos. Muy lejos. Creo.", IfNot = { Input = "Cubrirse" } },
				{ At = 5.2, Speaker = "Narrador", Text = "Tres estrellas verdes caen sobre Valmar: el parque, el patio del cole y el camino al colegio." },
				{ At = 7.3, Speaker = "Chispa", Text = "¡Bip! ¿Bip? ¡BIIIP!", Mood = "Fear" },
				{ At = 10.3, Speaker = "Pip", Text = "Tres impactos. Mi sensor de miedo también ha tenido tres impactos." },
				{ At = 12.1, Speaker = "Cosme", Text = "Hay que recogerlo antes de que lo encuentre alguien. O algo. ¡Rápido, criatura!" },
			},
			Titles = {
				{ At = 14, Text = "☄️ Han caído tres cosas del cielo", Sub = "Busca los cráteres humeantes", Duration = 2.4 },
			},
		},
	},

	---------------------------------------------------------------------
	-- Al recoger lo que cayó: una luz sube del cráter y te envuelve un momento (escena LIGERA: sin
	-- cámara ni bandas; puedes seguir moviéndote y la conversación del objeto sale a la vez).
	---------------------------------------------------------------------
	Grieta_Recoger = {
		Duration = 3,
		Light = true,
		Anchors = { Yo = "Player" },
		Tracks = {
			Fx = {
				{ At = 0, Play = "MysticOrb", Anchor = "Yo", Offset = V(0, 1, -2), Seconds = 2.4, Params = { Rise = 4, Scale = 0.7 } },
				{ At = 0.2, Play = "EnergyAura", Anchor = "Player", Seconds = 2.2 },
				{ At = 2.4, Play = "GreenSparks", Anchor = "Yo", Offset = V(0, 5, -2) },
			},
		},
	},

	---------------------------------------------------------------------
	-- Muestrario del motor (modo pruebas: «/escena Demo_Catalogo»): explosión, grieta en el suelo,
	-- portal que te lleva al otro lado, orbe, aura, tormenta local y un cambio de cielo; con una espera
	-- en la que vuelves a mandar tú (acércate al portal).
	---------------------------------------------------------------------
	Demo_Catalogo = {
		Duration = 22,
		Skippable = true,
		Anchors = { Yo = "Player" },
		Tracks = {
			Camera = {
				{ At = 0, Duration = 4, Orbit = "Yo", Radius = 26, Height = 9, FromAngle = 0, ToAngle = 60, LookHeight = 2 },
				{ At = 4, Duration = 4, Fixed = { "Yo", V(-18, 8, 18) }, Look = { "Yo", V(0, 0, -14) }, Cut = "Dip" },
				{ At = 8, Duration = 4, Fixed = { "Yo", V(14, 6, 6) }, Look = { "Yo", V(0, 4, -24) }, Cut = "Cut" },
				{ At = 12, Duration = 10, Orbit = "Yo", Radius = 40, Height = 22, FromAngle = 120, ToAngle = 220, LookHeight = 10, Cut = "Dip" },
			},
			Fx = {
				{ At = 1, Play = "Explosion", Anchor = "Yo", Offset = V(14, 0, -10) },
				{ At = 4.2, Play = "GroundCrack", Anchor = "Yo", Offset = V(0, 0, -14), Seconds = 7 },
				{ At = 8.2, Play = "Portal", Key = "Portal", Anchor = "Yo", Offset = V(0, 0, -24), Seconds = 14, Params = { Teleport = { "Yo", V(0, 0, 40) } } },
				{ At = 9, Play = "MysticOrb", Anchor = "Yo", Offset = V(-6, 3, -8), Seconds = 6 },
				{ At = 9.5, Play = "EnergyAura", Anchor = "Player", Seconds = 5 },
				{ At = 12, Play = "LocalStorm", Anchor = "Yo", Seconds = 9 },
			},
			Wait = {
				{ At = 11, Near = { "Yo", 6, V(0, 0, -24) }, Control = "Player", Hint = "Cruza el portal (o espera)", Timeout = 15 },
			},
			Titles = {
				{ At = 0.5, Text = "Muestrario de efectos", Sub = "Motor de escenas de la historia", Duration = 3 },
			},
		},
	},
}
