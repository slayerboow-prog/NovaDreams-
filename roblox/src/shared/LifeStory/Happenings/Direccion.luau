-- ESCENAS DIRIGIDAS A MANO (v130, «con las skills, historia y cinemáticas»; docs/cine/plan-historia-cine.md).
--
-- Las escenas clave de la historia, con dirección de verdad: un gancho en los primeros segundos, planos
-- variados (situación, hombro, primer plano, inserto, reacción), movimientos de cámara (dolly, órbita,
-- acercamientos, cámara en mano en los golpes), actuación (gestos, miradas, emociones), luz, efectos,
-- sonido y música, y ritmo (cortar en la acción, aguantar en las reacciones).
--
-- Van en su propio grupo, el ÚLTIMO de HappeningIndex: una escena de aquí con la misma id que otra (del
-- guion generado de docs/historia/reescritura o de otro grupo) la sustituye. Así el guion se puede volver a
-- generar sin perder la dirección, las misiones no cambian y las partidas guardadas tampoco.
-- Mismas reglas que todas: nunca más de 35° por encima de una cara (CameraShots.sane), los rótulos sobre
-- la banda oscura y solo en planos sin caras de cerca, y test-cineplanos / test-scenes en verde.

local V = Vector3.new

local function look(at: number, key: string, target: any): { [string]: any }
	return { At = at, Look = { Key = key, At = target } }
end
local function mood(at: number, key: string, m: string): { [string]: any }
	return { At = at, Mood = { Key = key, Mood = m } }
end
local function gesture(at: number, key: string, play: string): { [string]: any }
	return { At = at, Gesture = { Key = key, Play = play } }
end

local scenes = {
	---------------------------------------------------------------------
	-- PRÓLOGO · 1 · Lo PRIMERO que ve un jugador nuevo (Prologo_Sueno, paso 1).
	-- Antes: 10 s de vuelos sin nada, 8 fundidos a negro y los mismos dos planos aéreos tres veces.
	-- Ahora: GANCHO en el primer segundo (el cielo se raja con un trueno, cámara en mano desde tus ojos),
	-- y después el sueño: situación, tú en él, la Grieta de lejos y de cerca, la luz del garaje y Cosme.
	---------------------------------------------------------------------
	Prologo_G1 = {
		Skippable = true,
		Duration = 38,
		FadeIn = true,
		Sting = "Momento",
		Anchors = {
			A_Cosme = "Place:PrologoCosme",
			Grieta = "Rift",
			L_PrologoInicio = "Place:PrologoInicio",
			L_PrologoPuerta = "Place:PrologoPuerta",
			Sitio = "Place:PrologoInicio",
			Yo = "Player",
		},
		Tracks = {
			Camera = {
				-- 0 · GANCHO: desde tus ojos, el cielo se abre (zoom hacia fuera mientras tiembla)
				{ At = 0, Duration = 3.2, Fixed = { "Yo", V(1.6, 0.9, 3.4), true }, Look = { "Grieta" }, Fov = { 44, 60 }, Shake = 0.35 },
				-- 3,2 · Situación: el sueño desde el aire, acercándose (corte en seco tras el trueno)
				{ At = 3.2, Duration = 4.6, From = { "L_PrologoInicio", V(-70, 70, 70) }, To = { "L_PrologoInicio", V(-28, 34, 34) }, Look = { "L_PrologoInicio", V(0, 2, 0) }, Fov = 60, Cut = "Cut" },
				-- 7,8 · Tú, en el sueño: órbita lenta a tu alrededor
				{ At = 7.8, Duration = 4.4, Orbit = "Yo", Radius = 10, Height = 3, FromAngle = 200, ToAngle = 250, LookHeight = 1.5, Fov = 55 },
				-- 12,2 · Dolly hacia tu cara (los días fáciles y los que hay que pelear)
				{ At = 12.2, Duration = 4.4, Shot = "Dolly:Yo", Cut = "Cut" },
				-- 16,6 · La Grieta de lejos, con teleobjetivo (se aplasta contra el cielo)
				{ At = 16.6, Duration = 3.6, Fixed = { "Yo", V(-2.5, 2.4, 6), true }, Look = { "Grieta" }, Fov = { 34, 28 }, Cut = "Cut" },
				-- 20,2 · «La Grieta.»: plano cerrado, la luz vibra y la cámara con ella
				{ At = 20.2, Duration = 2.8, Fixed = { "Yo", V(1.2, 2, 3), true }, Look = { "Grieta" }, Fov = { 26, 22 }, Shake = 0.25, Cut = "Whip" },
				-- 23 · Una luz encendida en un garaje (situación de la puerta)
				{ At = 23, Duration = 2.8, Shot = "General:L_PrologoPuerta", Cut = "Cut" },
				-- 25,8 · Cosme, de espaldas a ti, mira al cielo
				-- (cambio de foco: de la nuca de Cosme a ti)
				{ At = 25.8, Duration = 2.7, Shot = "Hombro:Cosme>Yo", Rack = { "Actor:Cosme" }, Cut = "Cut" },
				-- 28,5 · Su cara (se aguanta la reacción)
				{ At = 28.5, Duration = 3, Shot = "Reaccion:Cosme", Cut = "Cut" },
				-- 31,5 · Despedida: de ti al cielo, la cámara sube sin prisa
				{ At = 31.5, Duration = 6.5, From = { "Yo", V(3, 2.5, 7), true }, To = { "Yo", V(14, 26, 30), true }, Look = { "Yo", V(0, 1.5, 0) }, LookTo = { "Yo", V(-30, 12, -40), true }, Easing = "In", Cut = "Dip" },
			},
			Shake = {
				{ At = 0.3, Strength = 0.55, Seconds = 1.1 },
				{ At = 20.4, Strength = 0.25, Seconds = 0.8 },
			},
			Sky = {
				{ At = 0.25, Rift = "Flare", Seconds = 2.6, Strength = 1.5 },
				{ At = 16.8, Rift = "Flare", Seconds = 2.2, Strength = 0.8 },
				{ At = 20.3, Rift = "Flare", Seconds = 2.4, Strength = 1.2 },
				{ At = 34, Rift = "Flare", Seconds = 2.4, Strength = 1 },
			},
			Sound = {
				{ At = 0.2, Play = "Crack" },
				{ At = 0.45, Play = "Thunder", Volume = 0.8 },
				{ At = 20.3, Play = "Hum", Pitch = 0.7, Volume = 0.6 },
				{ At = 3.2, Play = "Whoosh", Volume = 0.5 },
				{ At = 23.1, Play = "Clic", Volume = 0.5 },
				{ At = 31.6, Play = "Whoosh", Volume = 0.4, Pitch = 0.8 },
			},
			-- Gradación por momento: la raja (frío y duro), el sueño (azul suave), otra vez la raja, el garaje
			Light = {
				{ At = 0, Preset = "Grieta", Fade = 0.3, Weight = 0.8 },
				{ At = 3.2, Preset = "Sueno", Fade = 1.2, Weight = 0.75 },
				{ At = 16.6, Preset = "Grieta", Fade = 0.8, Weight = 0.7 },
				{ At = 20.3, Preset = "Impacto", Fade = 0.05, Weight = 0.8 },
				{ At = 20.8, Preset = "Grieta", Fade = 0.5, Weight = 0.7 },
				{ At = 23, Preset = "Sueno", Fade = 1, Weight = 0.7 },
			},
			-- Capas: luciérnagas del sueño todo el rato, pájaros que cruzan el plano aéreo, la luz de la raja
			-- recortándote, fogonazos con los truenos y la luz cálida del garaje sobre Cosme
			Fx = {
				{ At = 0, Play = "Fireflies", Anchor = "Sitio", Seconds = 38 },
				{ At = 0.3, Play = "ImpactLight", Anchor = "Yo", Params = { Color = Color3.fromRGB(170, 255, 230) } },
				{ At = 0, Play = "RiftLight", Anchor = "Yo", Seconds = 3.6 },
				{ At = 3.6, Play = "Birds", Anchor = "Sitio", Seconds = 5 },
				{ At = 16.4, Play = "RiftLight", Anchor = "Yo", Seconds = 6.8 },
				{ At = 20.3, Play = "ImpactLight", Anchor = "Yo", Params = { Color = Color3.fromRGB(170, 255, 230), Brightness = 6 } },
				{ At = 23, Play = "KeyLight", Anchor = "Actor:Cosme", Seconds = 8.5 },
				{ At = 25.6, Play = "RimLight", Anchor = "Actor:Cosme", Seconds = 6 },
			},
			Ambience = {
				{ At = 0, Kind = false, Fade = 0.2 },
				{ At = 3.2, Kind = "Exterior", Fade = 2 },
			},
			Music = {
				{ At = 0, Intensity = "Tension" },
				{ At = 3.4, Intensity = "Descubrimiento" },
			},
			Actors = {
				{ At = 0, Use = { Anchor = "A_Cosme", Key = "Cosme", Npc = "Cosme" } },
				look(0.4, "Cosme", "Grieta"),
				look(26, "Cosme", "Grieta"),
				mood(25.9, "Cosme", "Surprise"),
				mood(28.4, "Cosme", "Nervous"),
			},
			Dialogue = {
				{ At = 1.1, S = "Narrador", T = "Esa luz no debería estar ahí." },
				{ At = 4.4, S = "Narrador", T = "Bienvenid{o/a} a Valmar." },
				{ At = 8.2, S = "Narrador", T = "Aquí vas a vivir una vida entera." },
				{ At = 12.5, S = "Narrador", T = "Habrá días fáciles. Y otros en los que tendrás que pelear." },
				{ At = 17, S = "Narrador", T = "Y hay algo que nadie debería haber visto." },
				{ At = 20.6, S = "Narrador", T = "La Grieta." },
				{ At = 26, S = "Cosme", T = "Otra vez no…", To = "Yo", A = "Facepalm" },
				{ At = 28.6, S = "Cosme", T = "Esta vez sí que la he liado.", To = "Yo", A = "Nervous", Mood = "Nervous" },
				{ At = 31.8, S = "Narrador", T = "Pero antes de que empiece tu vida…" },
				{ At = 34.8, S = "Narrador", T = "alguien lleva tiempo esperándote." },
			},
		},
	},

	---------------------------------------------------------------------
	-- PRÓLOGO · 9 · El sueño se acaba (Prologo_Sueno, último paso). Antes: los mismos vuelos del principio.
	-- Ahora: el tornillo que te llevas (inserto), tu cara, la isla que se aleja girando, la Grieta que te
	-- mira, y la subida al cielo con los tres rótulos de lo que es el juego (sin caras: nunca tapan a nadie).
	---------------------------------------------------------------------
	Prologo_G9 = {
		Skippable = true,
		Duration = 39,
		FadeOut = true,
		Anchors = {
			Grieta = "Rift",
			L_PrologoInicio = "Place:PrologoInicio",
			L_PrologoTornillo = "Place:PrologoTornillo",
			Sitio = "Place:PrologoPuerta",
			Yo = "Player",
		},
		Tracks = {
			Camera = {
				-- 0 · El tornillo brilla en tu mano (inserto que se acerca)
				{ At = 0, Duration = 3, Shot = "Inserto:L_PrologoTornillo", Fov = { 50, 38 } },
				-- 3 · Tu cara (lo has entendido… o no)
				-- (cambio de foco: de tu cara al tornillo)
				{ At = 3, Duration = 2.8, Shot = "Medio:Yo", Rack = { "L_PrologoTornillo" }, Cut = "Cut" },
				-- 5,8 · La isla del sueño se aleja, girando
				{ At = 5.8, Duration = 8.2, Orbit = "L_PrologoInicio", Radius = 46, Height = 30, FromAngle = 120, ToAngle = 165, LookHeight = 2, Cut = "Cut" },
				-- 14 · De vuelta a ti, de cerca: la Grieta en el cielo, detrás
				{ At = 14, Duration = 4.6, Orbit = "Yo", Radius = 8, Height = 2.6, FromAngle = 60, ToAngle = 95, LookHeight = 1.6, Cut = "Cut" },
				-- 18,6 · El tornillo otra vez: «algunas cosas las recordarás»
				{ At = 18.6, Duration = 3.6, Shot = "PrimerPlano:L_PrologoTornillo", Cut = "Cut" },
				-- 22,2 · La Grieta te mira (teleobjetivo, tiembla al destello)
				{ At = 22.2, Duration = 4.9, Fixed = { "Yo", V(-1.6, 2.2, 5), true }, Look = { "Grieta" }, Fov = { 40, 30 }, Shake = 0.15, Cut = "Cut" },
				-- 27,1 · Subida al cielo (los rótulos, sin caras)
				{ At = 27.1, Duration = 11.9, From = { "Yo", V(4, 3, 8) }, To = { "Yo", V(30, 70, 70) }, Look = { "Yo", V(0, 1.5, 0) }, LookTo = { "Yo", V(0, -1, 0) }, Easing = "In", Cut = "Dip" },
			},
			Sky = {
				{ At = 22.6, Rift = "Flare", Seconds = 2.4, Strength = 1.1 },
				{ At = 36, Rift = "Flare", Seconds = 2.6, Strength = 0.9 },
			},
			Sound = {
				{ At = 0.3, Play = "Ping", Volume = 0.45 },
				{ At = 18.8, Play = "Ping", Volume = 0.35 },
				{ At = 22.6, Play = "Hum", Pitch = 0.6, Volume = 0.6 },
				{ At = 5.8, Play = "Whoosh", Volume = 0.4 },
				{ At = 27.3, Play = "Whoosh", Volume = 0.6 },
			},
			Fx = {
				{ At = 0.2, Play = "GreenSparks", Anchor = "L_PrologoTornillo" },
				{ At = 0, Play = "Fireflies", Anchor = "Sitio", Seconds = 39 },
				{ At = 0, Play = "KeyLight", Anchor = "L_PrologoTornillo", Params = { Color = Color3.fromRGB(170, 255, 200), Brightness = 2.4, Range = 8 }, Seconds = 6 },
				{ At = 5.8, Play = "Birds", Anchor = "L_PrologoInicio", Seconds = 6 },
				{ At = 18.6, Play = "KeyLight", Anchor = "L_PrologoTornillo", Params = { Color = Color3.fromRGB(170, 255, 200), Brightness = 2.4, Range = 8 }, Seconds = 3.8 },
				{ At = 22.2, Play = "RiftLight", Anchor = "Yo", Seconds = 5 },
				{ At = 22.6, Play = "ImpactLight", Anchor = "Yo", Params = { Color = Color3.fromRGB(170, 255, 230), Brightness = 5 } },
			},
			Light = {
				{ At = 0, Preset = "Recuerdo", Fade = 1, Weight = 0.6 },
				{ At = 22.2, Preset = "Grieta", Fade = 0.6, Weight = 0.6 },
				{ At = 27.1, Preset = "Sueno", Fade = 2, Weight = 0.7 },
			},
			Music = { { At = 0, Intensity = "Intima" } },
			Dialogue = {
				{ At = 6.2, S = "Narrador", T = "Aquí empieza tu vida." },
				{ At = 9.4, S = "Narrador", T = "Crecerás. Aprenderás. Te equivocarás." },
				{ At = 14.4, S = "Narrador", T = "Y conocerás personas que cambiarán tu historia." },
				{ At = 18.8, S = "Narrador", T = "Algunas cosas las recordarás. Otras no." },
				{ At = 22.4, S = "Narrador", T = "Pero alguien recordará por ti." },
				{ At = 27.3, S = "Narrador", T = "El sueño termina. Tu vida comienza." },
			},
			Titles = {
				{ At = 30.6, Duration = 2.6, Text = "CINE.PROLOGO.T_VIDA", Sub = "CINE.PROLOGO.S_VIDA" },
				{ At = 33.4, Duration = 2.6, Text = "CINE.PROLOGO.T_LOCA", Sub = "CINE.PROLOGO.S_LOCA" },
				{ At = 36.1, Duration = 2.6, Text = "CINE.PROLOGO.T_SAGA", Sub = "CINE.PROLOGO.S_SAGA" },
			},
		},
	},

	---------------------------------------------------------------------
	-- SAGA 1 · Misión 1 · El vecino del garaje (Loco_N1_Cosme). ESCENA NUEVA al terminar: el momento en
	-- que empieza la saga no se veía (la Grieta solo era un destello del cielo mientras Cosme hablaba).
	--   ¿Qué pasa? Al salir del garaje, el cielo se raja sobre Los Pinos. «Eso antes no estaba ahí.»
	--   ¿Qué siente Cosme? Miedo y culpa (lo sabe, aunque no lo dice). ¿Y el jugador? Curiosidad: un
	--   misterio que se queda abierto (el gancho de la misión 2).
	---------------------------------------------------------------------
	Loco_N1_Grieta = {
		Skippable = true,
		Duration = 15,
		Sting = "Momento",
		Center = "Garaje",
		Anchors = {
			Garaje = "Place:GarajeCosme",
			Yo = "Player",
			Grieta = "Rift",
		},
		Tracks = {
			Camera = {
				-- 0 · Corte en la acción: el chasquido, Cosme se queda helado
				{ At = 0, Duration = 2, Shot = "Medio:Cosme", Cut = "Cut" },
				-- 2 · Tú, mirando arriba
				{ At = 2, Duration = 1.8, Shot = "Reaccion:Yo", Cut = "Cut" },
				-- 3,8 · El cielo se raja (desde tu altura, cámara en mano, zoom hacia dentro)
				-- (a tu lado, del lado contrario a la raja: mires hacia donde mires al llegar)
				{ At = 3.8, Duration = 3.6, Fixed = { "Yo", V(1.8, 0.2, 1.8) }, Look = { "Grieta" }, Fov = { 55, 36 }, Shake = 0.3, Cut = "Whip" },
				-- 7,4 · Por encima del hombro de Cosme: los dos mirando lo mismo
				{ At = 7.4, Duration = 3, Shot = "Hombro:Cosme>Yo", Rack = { "Actor:Cosme" }, Cut = "Cut" },
				-- 10,4 · Su cara: lo sabe (se aguanta)
				{ At = 10.4, Duration = 2.4, Shot = "PrimerPlano:Cosme", Cut = "Cut" },
				-- 12,8 · La cámara sube desde ti: el barrio con la raja encima
				{ At = 12.8, Duration = 2.2, From = { "Yo", V(5, 3, -2) }, To = { "Yo", V(19, 14, -6) }, Look = { "Yo", V(0, 1.5, 0) }, LookTo = { "Yo", V(-40, 25, -40) }, Easing = "In", Cut = "Cut" },
			},
			Shake = {
				{ At = 3.9, Strength = 0.45, Seconds = 1 },
			},
			Sky = {
				{ At = 3.8, Rift = "Flare", Seconds = 3, Strength = 1.4 },
				{ At = 3.8, Mood = "GrietaAzul", Fade = 0.8 },
				{ At = 14.4, Mood = false, Fade = 2 },
			},
			Sound = {
				{ At = 0.1, Play = "Crack" },
				{ At = 3.9, Play = "Thunder", Volume = 0.7 },
				{ At = 7.6, Play = "Hum", Pitch = 0.6, Volume = 0.5 },
			},
			Music = {
				{ At = 0, Intensity = "Tension" },
				{ At = 12.8, Intensity = "Descubrimiento" },
			},
			-- Gradación: tarde normal → la raja (frío) con un fogonazo en el trueno
			Light = {
				{ At = 3.8, Preset = "Impacto", Fade = 0.05, Weight = 0.7 },
				{ At = 4.3, Preset = "Grieta", Fade = 0.6, Weight = 0.7 },
			},
			-- Capas: hojas con viento, la luz del garaje sobre Cosme, los pájaros que salen espantados con el
			-- trueno, el fogonazo y la luz de la raja recortando a los dos
			Fx = {
				{ At = 0, Play = "Leaves", Anchor = "Garaje", Seconds = 15 },
				{ At = 0, Play = "KeyLight", Anchor = "Actor:Cosme", Seconds = 4 },
				{ At = 3.9, Play = "Birds", Anchor = "Garaje", Seconds = 4 },
				{ At = 3.9, Play = "ImpactLight", Anchor = "Yo", Params = { Color = Color3.fromRGB(170, 255, 230), Brightness = 4 } },
				{ At = 4.2, Play = "RiftLight", Anchor = "Actor:Cosme", Seconds = 10.8 },
				{ At = 4.2, Play = "RiftLight", Anchor = "Yo", Seconds = 10.8 },
			},
			Actors = {
				{ At = 0, Use = { Key = "Cosme", Npc = "Cosme" } },
				-- Vecinos: salen a la acera con el trueno, se paran y señalan arriba
				{ At = 0, Spawn = { Key = "VecinoGrieta", Npc = "Vecino", Anchor = "Garaje", Offset = V(-12, 0, 10), Face = { "Garaje" } } },
				{ At = 0, Spawn = { Key = "MadreGrieta", Npc = "Madre", Anchor = "Garaje", Offset = V(10, 0, 12), Face = { "Garaje" } } },
				{ At = 4, Move = { Key = "VecinoGrieta", To = { "Garaje", V(-8, 0, 7) } } },
				{ At = 4.2, Move = { Key = "MadreGrieta", To = { "Garaje", V(7, 0, 9) } } },
				look(4.1, "VecinoGrieta", "Grieta"),
				look(4.3, "MadreGrieta", "Grieta"),
				mood(4.2, "VecinoGrieta", "Surprise"),
				mood(4.4, "MadreGrieta", "Fear"),
				gesture(6, "VecinoGrieta", "Point"),
				look(0.2, "Cosme", "Grieta"),
				mood(0.3, "Cosme", "Surprise"),
				gesture(4.2, "Cosme", "Point"),
				mood(10.3, "Cosme", "Fear"),
				look(10.4, "Cosme", "Yo"),
			},
			Dialogue = {
				{ At = 0.4, S = "Cosme", T = "¿Has oído eso?", To = "Yo" },
				{ At = 7.6, S = "Cosme", T = "Eso… antes no estaba ahí.", To = "Yo" },
				{ At = 10.6, S = "Cosme", T = "A casa, criatura. Y ni una palabra.", To = "Yo", Mood = "Fear" },
			},
		},
	},

	---------------------------------------------------------------------
	-- SAGA 2 · Episodio 1 · Llegada a Tefra (Tefra_01_Caida). Antes: 3,4 s de plano general quieto con el
	-- rótulo encima y la explosión a los 10 s. Ahora: GANCHO en el primer segundo (una bomba cae sobre las
	-- cúpulas, cámara en mano), el rótulo sobre el plano general (sin caras), la Lanza, Cosme, otra
	-- explosión cortando en la acción y su cara, que se aguanta.
	---------------------------------------------------------------------
	Tefra_Llegada = {
		Duration = 19,
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
				-- 0 · GANCHO: el impacto en las ruinas del Ovillo, desde lejos, temblando
				{ At = 0, Duration = 2.4, Fixed = { "Plataforma", V(-20, 14, 30) }, Look = { "Ovillo" }, Fov = { 30, 46 }, Shake = 0.35 },
				-- 2,4 · Situación: la plataforma (con el rótulo, sin caras de cerca)
				{ At = 2.4, Duration = 3.6, Shot = "General:Plataforma", Cut = "Cut" },
				-- 6 · La Lanza, desde lo alto de la plataforma (acercamiento)
				{ At = 6, Duration = 3, Fixed = { "Plataforma", V(0, 26, 0) }, Look = { "Lanza" }, Fov = { 50, 34 }, Cut = "Cut" },
				-- 9 · Cosme no reconoce su casa
				{ At = 9, Duration = 3.4, Shot = "Reaccion:Cosme", Cut = "Cut" },
				-- 12,4 · Otra bomba: corte en la acción
				{ At = 12.4, Duration = 2.2, Fixed = { "Plataforma", V(-10, 6, 18) }, Look = { "Ovillo" }, Fov = 32, Shake = 0.4, Cut = "Flash" },
				-- 14,6 · Su cara, despacio
				{ At = 14.6, Duration = 4.4, Shot = "Medio:Cosme", Cut = "Cut" },
			},
			-- Capas: brasas y polvo en el aire todo el rato, el fuego del Ovillo iluminando, cascotes que caen
			-- y fogonazo en cada bomba, y la luz fría de recorte sobre Cosme cuando habla
			Fx = {
				{ At = 0.3, Play = "Explosion", Anchor = "Ovillo", Params = { Scale = 2.2 } },
				{ At = 0.35, Play = "ImpactLight", Anchor = "Ovillo" },
				{ At = 0.5, Play = "Debris", Anchor = "Ovillo", Seconds = 2.5 },
				{ At = 0, Play = "Embers", Anchor = "Plataforma", Seconds = 19 },
				{ At = 0, Play = "Dust", Anchor = "Plataforma", Seconds = 19 },
				{ At = 0.4, Play = "FireLight", Anchor = "Ovillo", Seconds = 18.6 },
				{ At = 9, Play = "RimLight", Anchor = "Actor:Cosme", Seconds = 10 },
				{ At = 12.5, Play = "Explosion", Anchor = "Ovillo", Params = { Scale = 2.2 } },
				{ At = 12.55, Play = "ImpactLight", Anchor = "Ovillo" },
				{ At = 12.7, Play = "Debris", Anchor = "Ovillo", Seconds = 2.5 },
			},
			Shake = {
				{ At = 0.4, Strength = 0.6, Seconds = 1 },
				{ At = 12.6, Strength = 0.5, Seconds = 1 },
			},
			Sound = {
				{ At = 0.3, Play = "Boom" },
				{ At = 2.6, Play = "Aviso", Volume = 0.6 },
				{ At = 6.2, Play = "Hum", Pitch = 0.45, Volume = 0.7 },
				{ At = 12.5, Play = "Boom" },
			},
			-- Gradación: ceniza (naranja quemado) con un instante sobreexpuesto en cada bomba
			Light = {
				{ At = 0.3, Preset = "Impacto", Fade = 0.05, Weight = 0.8 },
				{ At = 0.8, Preset = "Ceniza", Fade = 0.6, Weight = 0.8 },
				{ At = 12.5, Preset = "Impacto", Fade = 0.05, Weight = 0.8 },
				{ At = 13, Preset = "Ceniza", Fade = 0.6, Weight = 0.8 },
			},
			Music = {
				{ At = 0, Intensity = "Tension" },
				{ At = 14.6, Intensity = "Intima" },
			},
			Actors = {
				{ At = 0, Use = { Key = "Cosme", Npc = "Cosme", Anchor = "Plataforma", Offset = V(3, 0, 2) } },
				-- Dos obreros cruzan la plataforma corriendo hacia el refugio (el fondo en movimiento)
				{ At = 0, Spawn = { Key = "ObreroA", Npc = "Vecino", Anchor = "Plataforma", Offset = V(-14, 0, -6) } },
				{ At = 0, Spawn = { Key = "ObreroB", Npc = "Madre", Anchor = "Plataforma", Offset = V(-16, 0, -2) } },
				{ At = 1, Move = { Key = "ObreroA", To = { "Plataforma", V(14, 0, -8) }, Run = true } },
				{ At = 1.3, Move = { Key = "ObreroB", To = { "Plataforma", V(12, 0, -4) }, Run = true } },
				mood(1, "ObreroA", "Fear"),
				mood(1.3, "ObreroB", "Fear"),
				look(0.4, "Cosme", "Ovillo"),
				mood(0.6, "Cosme", "Fear"),
				look(6, "Cosme", "Lanza"),
				mood(8.8, "Cosme", "Surprise"),
				look(12.5, "Cosme", "Ovillo"),
				look(14.6, "Cosme", "Yo"),
				mood(14.8, "Cosme", "Sad"),
			},
			Dialogue = {
				{ At = 9.2, S = "Cosme", T = "…Tefra. Aquí nada tenía esquinas, criatura. Nada.", To = "Yo" },
				{ At = 15, S = "Cosme", T = "Esto no es mi casa. Esto es un cuartel.", Pause = 0.6, To = "Yo" },
			},
			Titles = {
				{ At = 2.7, Text = "🌋 Tefra · Bastión Ceniza", Sub = "Saga 2 · Episodio 1: «Ceniza en Bastión»", Duration = 3 },
			},
		},
	},
}

---------------------------------------------------------------------
-- CAPAS sobre escenas que ya estaban bien escritas (el nacimiento, los primeros pasos, la Gran Fusión):
-- se copian (del guion si lo hay, si no de su grupo) y se les añaden luces de cine, ambiente en
-- movimiento, gradación por momento, sonido y retoques de cámara, sin reescribirlas.
---------------------------------------------------------------------
local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in value do
		out[k] = deepCopy(v)
	end
	return out
end

local function base(id: string, group: string): { [string]: any }?
	local ok, guion = pcall(function()
		return require(script.Parent.Parent.GuionOverlay).scenes()
	end)
	if ok and type(guion) == "table" and guion[id] then
		return deepCopy(guion[id])
	end
	local okGroup, list = pcall(function()
		return require((script.Parent :: any)[group])
	end)
	return if okGroup and type(list) == "table" and list[id] then deepCopy(list[id]) else nil
end

-- Añade las pistas de `extra` (al final de cada lista) y aplica `shots` (retoques de planos por su At)
local function layered(id: string, group: string, extra: { [string]: { any } }, shots: { [number]: { [string]: any } }?)
	local def = base(id, group)
	if not def then
		return
	end
	def.Tracks = def.Tracks or {}
	for track, list in extra do
		def.Tracks[track] = def.Tracks[track] or {}
		for _, entry in list do
			table.insert(def.Tracks[track], entry)
		end
		table.sort(def.Tracks[track], function(a, b)
			return (a.At or 0) < (b.At or 0)
		end)
	end
	for _, shot in def.Tracks.Camera or {} do
		local change = shots and shots[shot.At]
		for k, v in change or {} do
			shot[k] = v
		end
	end
	scenes[id] = def
end

-- BEBÉ · El nacimiento: el amanecer fuera (pájaros, luz dorada), dentro motas de polvo en la luz, la
-- lámpara cálida sobre la familia y Abu, y un recorte suave sobre la cuna
layered("Bebe_NacimientoCuna", "Colegio", {
	Fx = {
		{ At = 0.5, Play = "Birds", Anchor = "Casa", Seconds = 5 },
		{ At = 6.5, Play = "Dust", Anchor = "Cuna", Params = { Size = V(8, 5, 8) }, Seconds = 30 },
		{ At = 6.5, Play = "KeyLight", Anchor = "Cuna", Params = { Offset = V(-3, 5, 3), Brightness = 1.4 }, Seconds = 30 },
		{ At = 6.5, Play = "RimLight", Anchor = "Cuna", Params = { Offset = V(2, 4, -3), Color = Color3.fromRGB(255, 236, 200), Brightness = 1.2 }, Seconds = 30 },
	},
	Light = {
		{ At = 0, Preset = "Atardecer", Fade = 1, Weight = 0.5 },
		{ At = 29, Preset = "Intima", Fade = 1.5, Weight = 0.6 },
	},
	Sound = {
		{ At = 6.4, Play = "Whoosh", Volume = 0.35, Pitch = 1.2 },
	},
})

-- BEBÉ · Primeros pasos: luz cálida que te sigue, motas en el salón, la familia con su luz principal y
-- el momento de llegar a Abu más íntimo
layered("Bebe_PrimerosPasosAbu", "Colegio", {
	Fx = {
		{ At = 0, Play = "Dust", Anchor = "Sitio", Params = { Size = V(14, 6, 14) }, Seconds = 79 },
		{ At = 0, Play = "KeyLight", Anchor = "Yo", Params = { Offset = V(2, 4, 3), Brightness = 1.2 }, Seconds = 79 },
		{ At = 2.4, Play = "KeyLight", Anchor = "Actor:Familia", Seconds = 40 },
		{ At = 2.4, Play = "RimLight", Anchor = "Actor:Familia", Params = { Color = Color3.fromRGB(255, 230, 190), Brightness = 1.4 }, Seconds = 40 },
	},
	Light = {
		{ At = 44, Preset = "Intima", Fade = 2, Weight = 0.6 },
	},
	Sound = {
		{ At = 0.4, Play = "Whoosh", Volume = 0.3, Pitch = 1.2 },
	},
})

-- SAGA 1 · La Gran Fusión: viento y polvo en la cima, fogonazo con el trueno, cascotes que caen de la
-- raja, la luz de la Grieta recortando a Cosme y a ti, chispas en la máquina y la llegada de Cósimo con
-- portal, destello y barrido rápido de cámara; gradación fría que se rompe en cada golpe
layered("Grieta_Fusion", "Cielo", {
	Fx = {
		{ At = 0, Play = "Dust", Anchor = "Cima", Params = { Size = V(50, 6, 50) }, Seconds = 30 },
		{ At = 4.4, Play = "ImpactLight", Anchor = "Yo", Params = { Color = Color3.fromRGB(170, 255, 230), Brightness = 5 } },
		{ At = 4.5, Play = "Debris", Anchor = "Cima", Seconds = 2.5 },
		{ At = 4.6, Play = "RiftLight", Anchor = "Actor:Cosme", Seconds = 25 },
		{ At = 4.6, Play = "RiftLight", Anchor = "Yo", Seconds = 25 },
		{ At = 17, Play = "SparkShower", Anchor = "Maquina" },
		{ At = 18.5, Play = "Portal", Anchor = "Entrada", Seconds = 2.5 },
		{ At = 18.9, Play = "ImpactLight", Anchor = "Entrada", Params = { Color = Color3.fromRGB(190, 140, 255), Brightness = 5 } },
		{ At = 19.1, Play = "RimLight", Anchor = "Actor:Cosimo", Params = { Color = Color3.fromRGB(190, 140, 255), Brightness = 2.6 }, Seconds = 10 },
	},
	Light = {
		{ At = 4.4, Preset = "Impacto", Fade = 0.05, Weight = 0.7 },
		-- (cada entrada sustituye a la anterior: después de cada fogonazo se vuelve a la noche)
		{ At = 4.9, Preset = "Noche", Fade = 0.6 },
		{ At = 18.9, Preset = "Impacto", Fade = 0.05, Weight = 0.7 },
		{ At = 19.4, Preset = "Noche", Fade = 0.6 },
	},
	Shake = {
		{ At = 18.9, Strength = 0.4, Seconds = 0.8 },
	},
	Sound = {
		{ At = 16.9, Play = "Whoosh", Volume = 0.5 },
		{ At = 18.9, Play = "Thunder", Volume = 0.7 },
	},
}, {
	[19.1] = { Cut = "Whip" },
	[23.1] = { Rack = { "Actor:Cosimo" } },
})

return scenes
