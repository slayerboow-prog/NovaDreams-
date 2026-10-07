-- Escenas del CIELO (Saga de la Grieta). Formato: shared/LifeStory/Sequencer.luau y
-- docs/historia/escenarios-5-diseno-implementacion.md §4.1.
--
-- Anclas: "Player" (tú, donde estés al empezar), "Place:Lugar", "Zone:Zona", "Actor:Npc" (un personaje
-- de tu misión), "Rift" (la Grieta del cielo, donde la ve tu pantalla) o { Place, Offset, Ground }
-- (un lugar desplazado, apoyado en el suelo: así coincide con los objetos de la misión).
-- Dentro de la escena también valen "Actor:<Key>" (un actor de la escena) y "Fx:<Key>" (un efecto).

local V = Vector3.new

-- La Grieta del cielo crece en 7 ETAPAS a lo largo de la Saga (shared/SkyRift: Rasguno 2 → Crece 3 →
-- Grande 4 → Abierta 5 → Cosida/Hilachas → Rota 5 → Inminente 6 → Fusion 7 → Ultima 4 → Cerrada 1).
-- Cada momento clave de ese arco tiene aquí su escena, con la misma gramática de descubrimiento:
-- plano de situación → reacción → inserto (lo que se mira) → reacción. Las escenas LIGERAS (sin cámara)
-- solo encienden la Grieta mientras la conversación de la misión sigue en pantalla.
--   Grieta_Rasguno   (ligera) Loco_N1_Cosme: el primer rasguño de luz sobre Los Pinos
--   Grieta_Caen      Saga_02_Grieta: caen tres estrellas verdes
--   Grieta_Grande    (ligera) Saga_05_Perdidas: la noche de las cosas perdidas, el cielo se oscurece
--   Grieta_Coser     Saga_06_Coser: la aguja cuántica cose el portal abierto (fin del Acto I)
--   Grieta_Rota      Saga_12_Graduacion: la costura se rompe sobre tu graduación y baja Cósimo
--   Grieta_Inminente (ligera) Saga_18_Precio: el anuncio de la Gran Fusión hace temblar el cielo
--   Grieta_Fusion    Saga_23_Fusion: medianoche en el Monte del Silencio, el cielo se rompe (etapa 7)
--   Grieta_Final     Saga_24_Final: la última costura, en el patio donde empezó todo

-- Restos de la Grieta (la colección de las Rarezas): con 4 o más, brillan alrededor del Ancla
local RESTOS = { "BuzonPasado", "FarolaOpera", "PerroBinario", "LluviaEspaguetis", "Piso13", "RelojAtras", "SemaforoOpina", "NubePerdida",
	"ColumpioPasado", "SombraEscapada", "EspejoContesta", "PalomasCola", "CafeConsejos", "EcoFuturo", "Contestador1999", "GatoCuantico",
	"HeladoRecuerdos", "CharcoSinFondo", "CancionPegadiza", "TaquillaDimensional", "FotocopiasVivas", "Wifi1987", "LavadoraMultiversal", "CajeroDeTiempo" }

-- Diálogo de Grieta_Coser (la frase de Pip cambia si el barrio ya vio las rarezas)
local function coserDialogue(pip: { [string]: any }): { { [string]: any } }
	return {
		{ At = 3.3, S = "Cosme", T = "Tres anclajes. Una aguja. Un cielo entero.", Shot = "Medio:Cosme", Mood = "Nervous" },
		{ At = 6.9, S = "Cosme", T = "…Allá vamos.", Pause = 0.4, To = "Yo" },
		pip,
		{ At = 17, S = "Cosme", T = "…Se ha cerrado. Pip. Pip, mira. Se ha cerrado.", Mood = "Surprise", To = "Pip" },
	}
end

-- Diálogo de Grieta_Final (lo que dice Cósimo depende de lo que decidiste en el monte)
local function finalDialogue(cosimo: string): { { [string]: any } }
	return {
		{ At = 3.6, S = "Cosme", T = "Aquí clavaste el primer anclaje. Tenías barro hasta las rodillas.", If = { Memories = { "CoserElCielo" } }, To = "Yo" },
		{ At = 3.6, S = "Cosme", T = "Aquí empezó todo. Aquí lo cerramos.", IfNot = { Memories = { "CoserElCielo" } }, To = "Yo" },
		{ At = 8.4, S = "Cosimo", T = cosimo, To = "Cosme" },
		{ At = 13.7, S = "Cosme", T = "No te suelto. Esta vez, no.", Pause = 0.5, To = "Cosimo" },
		{ At = 19.9, S = "Candela", T = "Punto uno. Punto dos. Punto tres…" },
	}
end

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
	-- Loco_N1_Cosme · el primer RASGUÑO (etapa 2). Escena LIGERA: la conversación de Cosme sigue en
	-- pantalla («¿eso estaba ahí antes?») y, encima de Los Pinos, la raja de luz parpadea dos veces.
	--   ¿Qué está pasando? Al salir del garaje aparece en el cielo una raja de luz finísima.
	--   ¿Por qué? El microondas temporal ha removido algo; la Grieta empieza a despertar.
	--   ¿Qué siente el personaje? Cosme, miedo que disimula; tú, curiosidad.
	--   ¿Qué ve el jugador? Un destello violeta pequeño en el cielo, mientras Cosme habla.
	--   ¿Qué quiero que sienta el jugador? Un escalofrío: esto no ha hecho más que empezar.
	---------------------------------------------------------------------
	Grieta_Rasguno = {
		Duration = 8,
		Light = true,
		Anchors = { Yo = "Player", Grieta = "Rift" },
		Tracks = {
			Sky = {
				{ At = 2.5, Rift = "Flare", Strength = 0.7, Seconds = 2.5 },
				{ At = 5.6, Rift = "Flare", Strength = 0.45, Seconds = 2 },
			},
			Sound = {
				{ At = 2.5, Play = "Hum", Volume = 0.6 },
			},
		},
	},

	---------------------------------------------------------------------
	-- Saga_05_Perdidas · la Grieta GRANDE (etapa 4). Escena LIGERA al terminar de hablar con Ramón: el
	-- cielo se oscurece sobre el cole, la Grieta late y retumba (de ahí sale todo lo perdido).
	--   ¿Qué está pasando? La Grieta ha escupido en el gimnasio todo lo perdido de Valmar.
	--   ¿Por qué? Ha crecido: ya es una fractura enorme y tira de todo.
	--   ¿Qué siente el personaje? Ramón, desconcierto; Pip, nervios de robot.
	--   ¿Qué ve el jugador? El cielo que se apaga un poco y un latido de luz.
	--   ¿Qué quiero que sienta el jugador? Que la amenaza ya es grande y está aquí, en su cole.
	---------------------------------------------------------------------
	Grieta_Grande = {
		Duration = 10,
		Light = true,
		Anchors = { Yo = "Player", Grieta = "Rift" },
		Tracks = {
			Sky = {
				{ At = 0, Mood = "Ominoso", Fade = 2 },
				{ At = 1.5, Rift = "Flare", Strength = 1.2, Seconds = 3 },
				{ At = 8, Mood = false, Fade = 2 },
			},
			Sound = {
				{ At = 1.5, Play = "Rumble", Volume = 0.8 },
			},
		},
	},

	---------------------------------------------------------------------
	-- Saga_06_Coser · COSER EL CIELO (etapa 5, el portal abierto, fin del Acto I). Sustituye a la vieja
	-- cinemática Saga_Coser (un vuelo de cámara): ahora se ve el patio, la cara de Cosme, la aguja, la
	-- Grieta y cada puntada, y el apagón de un segundo antes de que vuelva la luz.
	--   ¿Qué está pasando? La aguja cuántica sube desde el patio del cole y cose la Grieta abierta.
	--   ¿Por qué? Los tres anclajes están clavados y los agentes grises se han ido.
	--   ¿Qué siente el personaje? Cosme, miedo y orgullo a la vez; Pip, nervios.
	--   ¿Qué ve el jugador? El patio de noche, la aguja, el cielo roto, tres puntadas de luz y el apagón.
	--   ¿Qué quiero que sienta el jugador? Asombro y la emoción de «lo hemos hecho juntos».
	---------------------------------------------------------------------
	Grieta_Coser = {
		Duration = 26,
		Skippable = true,
		FadeIn = true,
		Sting = "Momento",
		Anchors = {
			Patio = "Place:Patio",
			Aguja = { Place = "Patio", Offset = V(0, 0, -6), Ground = true },
			Yo = "Player",
			Grieta = "Rift",
		},
		Tracks = {
			Camera = {
				-- Situación: el patio de noche, los tres, la aguja en medio
				{ At = 0, Duration = 3.3, Shot = "General:Aguja", Cut = "Fade" },
				-- (3,3–7: Medio de Cosme y su «allá vamos», en el diálogo)
				-- Inserto: la aguja se enciende y sale disparada
				{ At = 7.9, Duration = 1.6, Shot = "Inserto:Aguja", Cut = "Cut" },
				-- Tu mirada sube con ella hasta la Grieta
				{ At = 9.5, Duration = 3, From = { "Yo", V(2, 1.6, 4) }, To = { "Yo", V(1.5, 1.2, 3) }, Look = { "Yo", V(0, 2, 0) }, LookTo = { "Grieta" }, Fov = { 60, 48 } },
				-- Las puntadas, desde el patio
				{ At = 12.5, Duration = 3.4, Fixed = { "Patio", V(-10, 3, 14) }, Look = { "Grieta" }, Fov = 55, Cut = "Cut" },
				-- Vuelve la luz: la cara de Cosme
				{ At = 16.7, Duration = 3, Shot = "Reaccion:Cosme", Cut = "Cut" },
				{ At = 19.7, Duration = 2.2, Shot = "DosPlanos:Cosme,Pip" },
				-- Te alejas: el patio, el cielo cosido
				{ At = 21.9, Duration = 4.1, Shot = "Dolly:Yo", Reverse = true },
			},
			Shake = {
				{ At = 9.9, Strength = 0.3, Seconds = 0.8 },
			},
			Sky = {
				{ At = 0, Mood = "GrietaAzul", Fade = 1.5 },
				{ At = 9.9, Rift = "Flare", Strength = 1.4, Seconds = 2.5 },
				{ At = 12.8, Rift = "Flare", Strength = 0.9, Seconds = 0.8 },
				{ At = 13.8, Rift = "Flare", Strength = 0.7, Seconds = 0.8 },
				{ At = 14.8, Rift = "Flare", Strength = 0.5, Seconds = 0.8 },
				{ At = 16.1, Mood = false, Fade = 0.5 },
			},
			Fx = {
				{ At = 8, Play = "MysticOrb", Anchor = "Aguja", Offset = V(0, 1, 0), Seconds = 3, Params = { Rise = 40, Scale = 0.8 } },
				{ At = 16.9, Play = "GreenSparks", Anchor = "Aguja", Offset = V(0, 2, 0) },
			},
			Sound = {
				{ At = 8, Play = "Whoosh" },
				{ At = 12.8, Play = "Ping" },
				{ At = 13.8, Play = "Ping" },
				{ At = 14.8, Play = "Ping" },
				{ At = 16, Play = "Boom", Volume = 0.6 },
			},
			-- El apagón: «Valmar entera se queda a oscuras un segundo… y vuelve la luz»
			Fade = {
				{ At = 15.9, To = 1, Seconds = 0.3 },
				{ At = 16.7, To = 0, Seconds = 1.1 },
			},
			Light = {
				{ At = 0, Preset = "Noche", Fade = 1.5 },
			},
			Ambience = {
				{ At = 0, Kind = "Exterior", Fade = 1.5 },
			},
			Music = {
				{ At = 0, Intensity = "Tension" },
				{ At = 9.5, Intensity = "Descubrimiento" },
				{ At = 16.7, Intensity = "Tema" },
			},
			Actors = {
				-- Cosme y Pip son los de la misión (si no están, aparecen junto a la aguja)
				{ At = 0, Use = { Key = "Cosme", Npc = "Cosme", Anchor = "Patio", Offset = V(4, 0, -3) } },
				{ At = 0, Use = { Key = "Pip", Npc = "Pip", Anchor = "Patio", Offset = V(6, 0, -1) } },
				{ At = 0.2, Look = { Key = "Cosme", At = "Aguja" } },
				{ At = 0.3, Look = { Key = "Pip", At = "Aguja" } },
				{ At = 0.5, Mood = { Key = "Pip", Mood = "Nervous" } },
				{ At = 6.8, Look = { Key = "Cosme", At = "Speaker" } },
				{ At = 8.2, Look = { Key = "Cosme", At = "Grieta" } },
				{ At = 8.3, Look = { Key = "Pip", At = "Grieta" } },
				{ At = 8.5, Gesture = { Key = "Cosme", Play = "Point" } },
				{ At = 15.9, Mood = { Key = "Pip", Mood = "Fear" } },
				{ At = 16.9, Mood = { Key = "Cosme", Mood = "Joy" } },
				{ At = 17.2, Look = { Key = "Pip", At = "Speaker" } },
				{ At = 19.9, Mood = { Key = "Pip", Mood = "Joy" } },
				{ At = 20.2, Gesture = { Key = "Cosme", Play = "Cheer" } },
				{ At = 20.5, Gesture = { Key = "Pip", Play = "Cheer" } },
			},
			Dialogue = coserDialogue({ At = 12.7, S = "Pip", T = "Puntada… puntada… puntada. Mis sensores lloran aceite.", Duration = 3.1 }),
			Titles = {
				{ At = 22.3, Text = "🪡 El cielo está cosido", Sub = "Fin del Acto I · La Grieta", Duration = 3.4 },
			},
		},
		-- Si el barrio ya vio las rarezas (la noche de las cosas perdidas), Pip lo nota
		Variants = {
			{ Name = "Barrio", If = { Flags = { "VecinosNotanRarezas" } }, Tracks = {
				Dialogue = coserDialogue({ At = 12.7, S = "Pip", T = "Medio barrio está en la ventana. Ramón, con sus llaves de 1994.", Duration = 3.1 }),
			} },
		},
	},

	---------------------------------------------------------------------
	-- Saga_12_Graduacion · la costura se ROMPE (vuelve la etapa 5) sobre tu graduación del instituto y
	-- baja Cósimo. Sustituye a la vieja cinemática Saga_Grieta2.
	--   ¿Qué está pasando? En plena graduación, la costura del cielo se abre como una cremallera.
	--   ¿Por qué? Era la fecha de la cuenta atrás de MegaVerso: Cósimo viene a por Cosme y a por ti.
	--   ¿Qué siente el personaje? Nico, euforia que se corta; Cosme, terror; tus amigos, no entienden.
	--   ¿Qué ve el jugador? La fiesta, el cielo que se rasga, caras que miran arriba y un hombre con perilla.
	--   ¿Qué quiero que sienta el jugador? Que le roban el día más feliz: tensión y rabia.
	---------------------------------------------------------------------
	Grieta_Rota = {
		Duration = 24.5,
		Skippable = true,
		FadeIn = true,
		Sting = "Momento",
		Anchors = {
			Patio = "Place:PatioInstituto",
			Yo = "Player",
			Grieta = "Rift",
			Bajada = { Place = "PatioInstituto", Offset = V(0, 0, -8), Ground = true },
		},
		Tracks = {
			Camera = {
				{ At = 0, Duration = 3.6, Shot = "General:Patio", Cut = "Fade" },
				-- Cremallera: tu mirada sube al cielo
				{ At = 3.6, Duration = 3, From = { "Yo", V(3, 2, 6) }, To = { "Yo", V(2, 1.5, 4) }, Look = { "Yo", V(0, 2, 0) }, LookTo = { "Grieta" }, Fov = { 60, 46 }, Shake = 0.4 },
				-- (6,6–12,6: Cosme y tus amigos, en el diálogo)
				-- Del cielo a donde aterriza
				{ At = 14, Duration = 2.8, Shot = "Pan:Grieta>Bajada" },
				{ At = 16.8, Duration = 2.6, Shot = "Tilt:Cosimo" },
				{ At = 19.4, Duration = 2.6, Shot = "Hombro:Cosme>Cosimo", Cut = "Cut" },
				{ At = 22, Duration = 2.2, Shot = "Reaccion:Yo", Cut = "Dip" },
			},
			Shake = {
				{ At = 3.4, Strength = 0.5, Seconds = 0.9 },
			},
			Sky = {
				{ At = 3.3, Rift = "Flare", Strength = 1.6, Seconds = 3 },
				{ At = 3.3, Mood = "GrietaAzul", Fade = 1 },
				{ At = 14.2, Rift = "Flare", Strength = 1, Seconds = 2 },
			},
			Fx = {
				{ At = 14.1, Play = "Portal", Anchor = "Bajada", Seconds = 4 },
				{ At = 15.7, Play = "Poof", Anchor = "Bajada" },
			},
			Sound = {
				{ At = 3.2, Play = "Crack" },
				{ At = 3.5, Play = "Thunder", Volume = 0.7 },
				{ At = 14.2, Play = "Hum" },
			},
			Ambience = {
				{ At = 0, Kind = "Instituto", Fade = 1 },
			},
			Music = {
				{ At = 0, Intensity = "Descubrimiento" },
				{ At = 3.3, Intensity = "Tension" },
			},
			Actors = {
				{ At = 0, Use = { Key = "Cosme", Npc = "Cosme", Anchor = "Patio", Offset = V(2, 0, 3) } },
				{ At = 0, Use = { Key = "Omar", Npc = "Omar", Anchor = "Patio", Offset = V(-5, 0, 6) } },
				{ At = 0, Use = { Key = "Sara", Npc = "Sara", Anchor = "Patio", Offset = V(-3, 0, 8) } },
				{ At = 0, Use = { Key = "Nico", Npc = "Nico", Anchor = "Patio", Offset = V(5, 0, 7) } },
				{ At = 0.4, Gesture = { Key = "Nico", Play = "Cheer" } },
				{ At = 3.5, Look = { Key = "Cosme", At = "Grieta" } },
				{ At = 3.6, Look = { Key = "Nico", At = "Grieta" } },
				{ At = 3.7, Look = { Key = "Omar", At = "Grieta" } },
				{ At = 3.8, Look = { Key = "Sara", At = "Grieta" } },
				{ At = 3.9, Mood = { Key = "Nico", Mood = "Surprise" } },
				{ At = 4, Mood = { Key = "Cosme", Mood = "Fear" } },
				{ At = 4.1, Mood = { Key = "Omar", Mood = "Surprise" } },
				{ At = 4.2, Mood = { Key = "Sara", Mood = "Nervous" } },
				{ At = 4.6, Gesture = { Key = "Omar", Play = "Point" } },
				{ At = 6.6, Look = { Key = "Cosme", At = "Speaker" } },
				{ At = 14.1, Look = { Key = "Cosme", At = "Bajada" } },
				{ At = 14.2, Look = { Key = "Omar", At = "Bajada" } },
				{ At = 14.2, Look = { Key = "Sara", At = "Bajada" } },
				{ At = 14.3, Look = { Key = "Nico", At = "Bajada" } },
				-- Baja Cósimo
				{ At = 15.7, Spawn = { Key = "Cosimo", Npc = "Cosimo", Anchor = "Bajada" } },
				{ At = 16.4, Look = { Key = "Cosimo", At = "Yo" } },
				{ At = 17.6, Gesture = { Key = "Cosimo", Play = "Wave" } },
				{ At = 19.4, Look = { Key = "Cosme", At = "Cosimo" } },
				{ At = 19.5, Mood = { Key = "Cosme", Mood = "Angry" } },
			},
			Dialogue = {
				{ At = 0.6, S = "Nico", T = "¡Graduados! ¡GRA-DUA-DOS! ¡Que alguien me pellizque!", Mood = "Joy" },
				{ At = 6.8, S = "Cosme", T = "No. Hoy no. Hoy es su día.", Shot = "Reaccion:Cosme", Mood = "Fear" },
				-- Si saboteaste la fiesta de MegaVerso, Omar ata cabos: la cuenta atrás era por hoy
				{ At = 9.5, S = "Omar", T = "Los números del cielo de la fiesta… marcaban hoy. Marcaban ESTO.", Shot = "DosPlanos:Omar,Sara", If = { Memories = { "FiestaFinDelMundo" } } },
				{ At = 9.5, S = "Sara", T = "Eso no es un fenómeno meteorológico. Eso es una cremallera.", Shot = "DosPlanos:Omar,Sara", IfNot = { Memories = { "FiestaFinDelMundo" } } },
			},
			Titles = {
				{ At = 19.8, Text = "🌀 La costura se rompe", Sub = "Tu graduación del instituto", Duration = 3 },
			},
		},
	},

	---------------------------------------------------------------------
	-- Saga_18_Precio · INMINENTE (antesala de la etapa 6). Escena LIGERA al acabar el anuncio de Cósimo
	-- en todas las pantallas: el cielo se encapota y la Grieta truena, como si lo hubiera oído.
	--   ¿Qué está pasando? Cósimo acaba de anunciar la fecha de la Gran Fusión.
	--   ¿Por qué? Sin Cosme (sin memoria), el Ancla parece sola: es su momento.
	--   ¿Qué siente el personaje? Pip, miedo contenido; Cosme, no entiende nada.
	--   ¿Qué ve el jugador? Por la puerta del garaje, el cielo que se oscurece y un relámpago violeta.
	--   ¿Qué quiero que sienta el jugador? Que el final ya tiene fecha.
	---------------------------------------------------------------------
	Grieta_Inminente = {
		Duration = 9,
		Light = true,
		Anchors = { Yo = "Player", Grieta = "Rift" },
		Tracks = {
			Sky = {
				{ At = 0, Mood = "Ominoso", Fade = 1.5 },
				{ At = 1.2, Rift = "Flare", Strength = 1.5, Seconds = 2.5 },
				{ At = 7, Mood = false, Fade = 2 },
			},
			Sound = {
				{ At = 1.2, Play = "Thunder", Volume = 0.8 },
			},
		},
	},

	---------------------------------------------------------------------
	-- Saga_23_Fusion · LA GRAN FUSIÓN (etapa 7: el cielo se rompe y todo se ve violeta). Sustituye a la
	-- vieja cinemática Saga_Fusion. Después, la conversación «Llegada» (Cósimo y Cosme, cara a cara).
	--   ¿Qué está pasando? Medianoche en la cima del Monte del Silencio: el cielo se abre del todo.
	--   ¿Por qué? Cósimo pone en marcha la Fusión: quiere las dos Valmar y necesita soltar el Ancla.
	--   ¿Qué siente el personaje? Cosme, miedo y ternura (te ha visto crecer con esa Grieta encima).
	--   ¿Qué ve el jugador? El monte desde lejos, el cielo roto, la cara de Cosme, la máquina y a Cósimo
	--   subiendo hacia vosotros con su sonrisa de anuncio.
	--   ¿Qué quiero que sienta el jugador? Vértigo de final de temporada: esto es el final.
	---------------------------------------------------------------------
	Grieta_Fusion = {
		Duration = 30,
		Skippable = true,
		FadeIn = true,
		Sting = "Momento",
		Anchors = {
			Cima = "Place:CimaMonte",
			Yo = "Player",
			Grieta = "Rift",
			Maquina = { Place = "CimaMonte", Offset = V(0, 0, -12), Ground = true },
			Entrada = { Place = "CimaMonte", Offset = V(-16, 0, -14), Ground = true },
			Marca = { Place = "CimaMonte", Offset = V(0, 0, -6), Ground = true },
		},
		Tracks = {
			Camera = {
				-- Situación: la cima de noche, lejos y alto
				{ At = 0, Duration = 4.2, From = { "Cima", V(46, 24, 52) }, To = { "Cima", V(30, 15, 36) }, Look = { "Cima", V(0, 6, -6) }, Fov = { 55, 50 }, Cut = "Fade" },
				-- El cielo se abre: tu mirada sube
				{ At = 4.2, Duration = 3.2, From = { "Yo", V(3, 2, 6) }, To = { "Yo", V(2, 1.5, 4) }, Look = { "Yo", V(0, 2, 0) }, LookTo = { "Grieta" }, Fov = { 62, 46 }, Shake = 0.5 },
				-- (7,4–15,6: Cosme, en el diálogo)
				-- Inserto: la máquina de la Fusión se enciende
				{ At = 16.9, Duration = 2.2, Shot = "Inserto:Maquina", Cut = "Cut" },
				-- Llega Cósimo andando
				{ At = 19.1, Duration = 4, Shot = "Seguir:Cosimo" },
				{ At = 23.1, Duration = 2.6, Shot = "Hombro:Cosme>Cosimo", Cut = "Cut" },
				-- Plano final: los dos frente a la Grieta
				{ At = 25.7, Duration = 4.1, Fixed = { "Cima", V(0, 8, 26) }, Look = { "Cima", V(0, 10, -12) }, Fov = 58, Cut = "Dip" },
			},
			Shake = {
				{ At = 4.5, Strength = 0.6, Seconds = 1 },
			},
			Sky = {
				{ At = 0, Mood = "GrietaFinal", Fade = 3 },
				{ At = 4.4, Rift = "Flare", Strength = 2, Seconds = 3 },
				{ At = 17, Rift = "Flare", Strength = 1.2, Seconds = 2 },
				{ At = 27.8, Mood = false, Fade = 2 },
			},
			Fx = {
				{ At = 17, Play = "MysticOrb", Anchor = "Maquina", Offset = V(0, 2, 0), Seconds = 3, Params = { Rise = 12, Scale = 1.2 } },
			},
			Sound = {
				{ At = 4.3, Play = "Thunder" },
				{ At = 17, Play = "Hum" },
				{ At = 19.1, Play = "Whoosh", Volume = 0.6 },
			},
			Light = {
				{ At = 0, Preset = "Noche", Fade = 2 },
			},
			Ambience = {
				{ At = 0, Kind = "Exterior", Fade = 1.5 },
				{ At = 4.4, Kind = "Portal", Fade = 2 },
			},
			Music = {
				{ At = 0, Intensity = "Tension" },
				{ At = 25.7, Intensity = "Tema" },
			},
			Actors = {
				{ At = 0, Use = { Key = "Cosme", Npc = "Cosme", Anchor = "Cima", Offset = V(3, 0, 6) } },
				{ At = 4.4, Look = { Key = "Cosme", At = "Grieta" } },
				{ At = 4.7, Mood = { Key = "Cosme", Mood = "Fear" } },
				{ At = 7.4, Look = { Key = "Cosme", At = "Yo" } },
				{ At = 11.5, Mood = { Key = "Cosme", Mood = "Calm" } },
				{ At = 17, Look = { Key = "Cosme", At = "Maquina" } },
				-- Cósimo entra andando desde el borde de la cima hasta delante de la máquina
				{ At = 18.9, Enter = { Key = "Cosimo", Npc = "Cosimo", From = "Entrada", Anchor = "Marca", Walk = true } },
				{ At = 19.3, Look = { Key = "Cosme", At = "Cosimo" } },
				{ At = 22.9, Look = { Key = "Cosimo", At = "Yo" } },
				{ At = 23.5, Gesture = { Key = "Cosimo", Play = "Wave" } },
				{ At = 23.7, Mood = { Key = "Cosme", Mood = "Angry" } },
			},
			Dialogue = {
				{ At = 7.6, S = "Cosme", T = "Medianoche. En punto. Siempre fue puntual para lo malo.", Shot = "Reaccion:Cosme" },
				-- Te ha visto crecer con esa Grieta encima (recuerdo de «La grieta en el cielo»)
				{ At = 11.8, S = "Cosme", T = "La primera vez era un rasguño. Tenías que ponerte de puntillas para verlo.", Shot = "DosPlanos:Cosme,Yo", To = "Yo", If = { Memories = { "GrietaEnElCielo" } } },
				{ At = 11.8, S = "Cosme", T = "Toda la vida sujetándola sin saberlo. Hoy no la sujetas sin ayuda.", Shot = "DosPlanos:Cosme,Yo", To = "Yo", IfNot = { Memories = { "GrietaEnElCielo" } } },
				-- ¿Le tendiste una trampa (Saga_22_Ancla)?
				{ At = 19.7, S = "Cosme", T = "Ha picado. Viene sonriendo… Se ha creído que vienes a rendirte.", If = { Flags = { "TrampaCosimo" } } },
				{ At = 19.7, S = "Cosme", T = "Ahí está. Con perilla y todo. Quédate a mi lado.", IfNot = { Flags = { "TrampaCosimo" } } },
			},
			Titles = {
				{ At = 26.1, Text = "🌀 LA GRAN FUSIÓN", Sub = "Todas las dimensiones, a la vez", Duration = 3.4 },
			},
		},
		-- Con 4 o más Restos de la Grieta (las Rarezas), la colección ya brilla a tu alrededor
		Variants = {
			{ Name = "Restos", If = { MemoriesAtLeast = { N = 4, Of = RESTOS } }, Tracks = {
				Fx = {
					{ At = 13.5, Play = "EnergyAura", Anchor = "Player", Seconds = 3.5 },
					{ At = 17, Play = "MysticOrb", Anchor = "Maquina", Offset = V(0, 2, 0), Seconds = 3, Params = { Rise = 12, Scale = 1.2 } },
				},
			} },
		},
	},

	---------------------------------------------------------------------
	-- Saga_24_Final · la ÚLTIMA COSTURA (de la etapa 4 a cerrada para siempre), en el patio del cole
	-- donde clavaste el primer anclaje. Sustituye a la vieja cinemática Saga_Final y escenifica lo que
	-- antes contaba el narrador («la aguja sube…», «como un botón que encaja»).
	--   ¿Qué está pasando? Cosme y Cósimo cosen el cielo desde los dos lados; tú sujetas el hilo.
	--   ¿Por qué? Solo cosiéndola a la vez desde las dos dimensiones se cierra para siempre.
	--   ¿Qué siente el personaje? Cosme, paz; Cósimo, vergüenza y ganas de volver; tus amigos, nervios.
	--   ¿Qué ve el jugador? El patio, los dos hermanos de taller juntos, la aguja, tres puntadas y el
	--   amanecer limpio.
	--   ¿Qué quiero que sienta el jugador? Que se cierra una vida entera: emoción y alivio.
	---------------------------------------------------------------------
	Grieta_Final = {
		Duration = 32.8,
		Skippable = true,
		FadeIn = true,
		Sting = "Momento",
		Anchors = {
			Patio = "Place:Patio",
			Yo = "Player",
			Grieta = "Rift",
			Anclaje = { Place = "Patio", Offset = V(0, 0, 8), Ground = true },
		},
		Tracks = {
			Camera = {
				{ At = 0, Duration = 3.4, Shot = "General:Anclaje", Cut = "Fade" },
				{ At = 3.4, Duration = 4.2, Shot = "DosPlanos:Cosme,Cosimo" },
				{ At = 8.2, Duration = 4.1, Shot = "Medio:Cosimo", Cut = "Cut" },
				{ At = 13.5, Duration = 2.9, Shot = "Reaccion:Cosme", Cut = "Cut" },
				-- La aguja sube: tu mirada con ella
				{ At = 16.4, Duration = 3.2, From = { "Yo", V(2, 1.6, 4) }, To = { "Yo", V(1.5, 1.2, 3) }, Look = { "Yo", V(0, 2, 0) }, LookTo = { "Grieta" }, Fov = { 60, 46 } },
				-- Las tres últimas puntadas, desde el patio
				{ At = 19.6, Duration = 2.8, Fixed = { "Patio", V(-12, 3, 16) }, Look = { "Grieta" }, Fov = 55, Cut = "Cut" },
				-- «Como un botón que encaja»: tu cara cuando vuelve la luz
				{ At = 22.4, Duration = 2.6, Shot = "Reaccion:Yo", Cut = "Cut" },
				{ At = 25, Duration = 2.6, Shot = "DosPlanos:Ivan,Candela" },
				{ At = 27.6, Duration = 5.2, Shot = "Dolly:Yo", Reverse = true },
			},
			Sky = {
				{ At = 0, Mood = "GrietaAzul", Fade = 2 },
				{ At = 17, Rift = "Flare", Strength = 1.2, Seconds = 2 },
				{ At = 19.8, Rift = "Flare", Strength = 0.8, Seconds = 0.7 },
				{ At = 20.6, Rift = "Flare", Strength = 0.6, Seconds = 0.7 },
				{ At = 21.4, Rift = "Flare", Strength = 0.4, Seconds = 0.7 },
				{ At = 22.4, Mood = false, Fade = 2.5 },
			},
			Fx = {
				{ At = 16.6, Play = "MysticOrb", Anchor = "Anclaje", Offset = V(0, 1, 0), Seconds = 3.5, Params = { Rise = 40, Scale = 0.8 } },
				{ At = 22.5, Play = "GreenSparks", Anchor = "Anclaje", Offset = V(0, 2, 0) },
			},
			Sound = {
				{ At = 16.6, Play = "Whoosh" },
				{ At = 19.8, Play = "Ping" },
				{ At = 20.6, Play = "Ping" },
				{ At = 21.4, Play = "Ping" },
				{ At = 22.4, Play = "Ping", Pitch = 0.6 },
			},
			Light = {
				{ At = 0, Preset = "Noche", Fade = 1.5 },
				{ At = 22.4, Preset = "Atardecer", Fade = 3 },
			},
			Ambience = {
				{ At = 0, Kind = "Exterior", Fade = 1.5 },
			},
			Music = {
				{ At = 0, Intensity = "Intima" },
				{ At = 16.4, Intensity = "Descubrimiento" },
				{ At = 22.4, Intensity = "Tema" },
			},
			Actors = {
				-- Todos son los de la misión (los mismos que la conversación de después)
				{ At = 0, Use = { Key = "Cosme", Npc = "Cosme", Anchor = "Patio", Offset = V(2, 0, 3) } },
				{ At = 0, Use = { Key = "Cosimo", Npc = "Cosimo", Anchor = "Patio", Offset = V(-2, 0, 3) } },
				{ At = 0, Use = { Key = "Ivan", Npc = "Ivan", Anchor = "Patio", Offset = V(-5, 0, 6) } },
				{ At = 0, Use = { Key = "Candela", Npc = "Candela", Anchor = "Patio", Offset = V(5, 0, 6) } },
				{ At = 0, Use = { Key = "Pip", Npc = "Pip", Anchor = "Patio", Offset = V(0, 0, 8) } },
				{ At = 0.3, Look = { Key = "Cosme", At = "Anclaje" } },
				{ At = 0.4, Look = { Key = "Cosimo", At = "Anclaje" } },
				{ At = 3.4, Look = { Key = "Cosme", At = "Speaker" } },
				{ At = 3.4, Look = { Key = "Cosimo", At = "Speaker" } },
				{ At = 8.4, Mood = { Key = "Cosimo", Mood = "Shame" } },
				{ At = 13.8, Mood = { Key = "Cosimo", Mood = "Calm" } },
				{ At = 16.5, Look = { Key = "Cosme", At = "Grieta" } },
				{ At = 16.5, Look = { Key = "Cosimo", At = "Grieta" } },
				{ At = 16.6, Look = { Key = "Ivan", At = "Grieta" } },
				{ At = 16.6, Look = { Key = "Candela", At = "Grieta" } },
				{ At = 16.7, Look = { Key = "Pip", At = "Grieta" } },
				{ At = 16.8, Mood = { Key = "Ivan", Mood = "Surprise" } },
				{ At = 16.9, Mood = { Key = "Candela", Mood = "Nervous" } },
				{ At = 22.6, Mood = { Key = "Cosme", Mood = "Joy" } },
				{ At = 25.2, Gesture = { Key = "Ivan", Play = "Cheer" } },
				{ At = 25.4, Mood = { Key = "Candela", Mood = "Joy" } },
				{ At = 25.6, Gesture = { Key = "Pip", Play = "Cheer" } },
				{ At = 27.6, Look = { Key = "Cosme", At = "Yo" } },
				{ At = 27.7, Look = { Key = "Cosimo", At = "Yo" } },
			},
			Dialogue = finalDialogue("Yo cojo mi lado. Como aquella noche. Esta vez no me sueltes."),
			Titles = {
				{ At = 28, Text = "🌅 La Grieta se cierra", Sub = "Fin de la Saga de la Grieta", Duration = 4.5 },
			},
		},
		-- Lo que decidiste con Cósimo en el monte (Saga_23_Fusion) cambia lo que dice
		Variants = {
			{ Name = "Perdonado", If = { Flags = { "CosimoPerdonado" } }, Tracks = {
				Dialogue = finalDialogue("Me he afeitado la perilla. Ni una palabra. …Cojo mi lado."),
			} },
			{ Name = "Arregla66B", If = { Flags = { "CosimoArregla66B" } }, Tracks = {
				Dialogue = finalDialogue("Mañana vuelvo a la 66-B a arreglarla. Hoy, una última costura juntos."),
			} },
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
				{ At = 8.2, Play = "Portal", Key = "Portal", Anchor = "Yo", Offset = V(0, 0, -24), Seconds = 13.5, Params = { Teleport = { "Yo", V(0, 0, 40) } } },
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
