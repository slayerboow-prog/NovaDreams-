-- Escenas de la INFANCIA: el bebé y el colegio (paquete P8a, auditoría §6.2, filas «Bebé» y «Niño»).
-- Formato: shared/LifeStory/Sequencer.luau (CINEMATIC_SCENE). Cada escena empieza con un comentario que
-- responde a las cinco preguntas de la regla de oro del encargo:
--   ¿Qué pasa? · ¿Por qué? · ¿Qué siente el personaje? · ¿Qué ve el jugador? · ¿Qué quiero que sienta?
--
-- Cómo las lanzan las misiones: un paso { Type = "Cinematic", Id = "<escena>", Actors = { … } }. Los
-- actores de la misión se toman PRESTADOS con Use (no desaparecen al acabar la escena; si no están, se
-- crean en su marca). Los Use de quien depende de una decisión llevan el mismo If que en la misión, para
-- que nunca aparezca alguien que no toca.
--
-- Recuerdos y decisiones (continuidad, W-05): las frases con If leen Flags, Choices, Memories, Rel… del
-- jugador. El nombre del grupo (Choices.NombreGrupo, misión 03) sale con una frase por nombre posible:
-- las escenas del motor solo rellenan {nombre}.
--
-- Interiores (casa, aula, sala cerrada): planos cortos (PrimerPlano, PPP, Reaccion, Hombro, Inserto) o
-- puntos a mano a pocos studs. Los planos largos (General, Medio, DosPlanos) solo en el patio, la pista y
-- el campo, donde caben.
--
-- Las del bebé (Bebe_*) se lanzan desde fuera de este paquete; ver «Interfaces» en el informe de P8a:
--   Bebe_NacimientoCuna   en vez de la cinemática Bebe_Nacimiento (Chapters: IntroCinematic)
--   Bebe_PrimerosPasosAbu en vez de Bebe_PrimerosPasos (Quests: Bebe_AprendeACaminar, paso 4)
--   Bebe_VentanalFamilia  en vez de Bebe_Ventanal (BabyService, al mirar por el ventanal)

local V = Vector3.new

-- Condiciones que se repiten
local TARDE = { Flags = { "LlegasTarde" } }
local AMIGO_MATEO = { Flags = { "AyudasteAMateo" } }
local CON_HUGO = { Flags = { "HugoConElGrupo" } }
local CON_IKER = { Flags = { "IkerEnElGrupo" } }
local FUTBOL = { Choices = { Deporte = "Futbol" } }
local BALONCESTO = { Choices = { Deporte = "Baloncesto" } }
local ATLETISMO = { Choices = { Deporte = "Atletismo" } }
local GANADO = { Flags = { "TorneoGanado" } }
local PERDIDO = { Flags = { "TorneoPerdido" } }

local function grupo(nombre: string): { [string]: any }
	return { Choices = { NombreGrupo = nombre } }
end
-- Los cuatro nombres posibles del grupo (Cole03_Grupo, diálogo NombreGrupo)
local NOMBRES_GRUPO = { "Los Imparables", "La Patrulla Valmar", "Los del Banco Azul", "Los Dinosaurios" }

-- Una frase por cada nombre del grupo: texto(nombre) -> frase. Solo sale la del nombre que elegiste.
local function porNombreDeGrupo(speaker: string, texto: (string) -> string, extra: { [string]: any }?): { any }
	local out = {}
	for i, nombre in NOMBRES_GRUPO do
		local line: { [string]: any } = { S = speaker, T = texto(nombre), If = grupo(nombre), Alt = i > 1 }
		for k, v in extra or {} do
			line[k] = v
		end
		table.insert(out, line)
	end
	return out
end

-- Junta listas de frases (las de porNombreDeGrupo en medio de un diálogo)
local function frases(...): { any }
	local out = {}
	for _, item in { ... } do
		if type(item) == "table" and item.S == nil and item[1] ~= nil then
			for _, line in item do
				table.insert(out, line)
			end
		else
			table.insert(out, item)
		end
	end
	return out
end

-- Prestar a un actor de la misión (si no está, aparece en su marca)
local function use(at: number, key: string, cond: { [string]: any }?, anchor: string?, offset: Vector3?): { [string]: any }
	return { At = at, If = cond, Use = { Key = key, Npc = key, Anchor = anchor, Offset = offset } }
end
local function look(at: number, key: string, target: string, cond: { [string]: any }?): { [string]: any }
	return { At = at, If = cond, Look = { Key = key, At = target } }
end
local function mood(at: number, key: string, m: string, cond: { [string]: any }?): { [string]: any }
	return { At = at, If = cond, Mood = { Key = key, Mood = m } }
end
local function gesture(at: number, key: string, play: string, cond: { [string]: any }?): { [string]: any }
	return { At = at, If = cond, Gesture = { Key = key, Play = play } }
end

return {
	---------------------------------------------------------------------
	-- BEBÉ · El nacimiento: la familia alrededor de la cuna (prioridad 1)
	-- ¿Qué pasa? Acabas de nacer. Tu familia y Abu se asoman a la cuna por primera vez.
	-- ¿Por qué? Es el primer momento de tu vida y de la historia: lo que viene después empieza aquí.
	-- ¿Qué siente el personaje? Ellos, una emoción contenida (no saben qué decir); tú, curiosidad.
	-- ¿Qué ve el jugador? Valmar desde el cielo → tu casa → la cuna con dos caras enormes y felices.
	-- ¿Qué quiero que sienta? Ternura y pertenencia: «aquí me quieren; esta es mi gente».
	---------------------------------------------------------------------
	Bebe_NacimientoCuna = {
		Skippable = true,
		FadeIn = true,
		Music = "Nacimiento",
		Center = "Cuna",
		Anchors = {
			Casa = "Place:CasaFamiliar",
			Cuna = "Place:Cuna",
			AbuSitio = "Place:FamiliaAbu",
			FamiliaSitio = "Place:FamiliaPadre",
		},
		Tracks = {
			Camera = {
				-- Situación: Valmar y Los Pinos desde el cielo, bajando hacia tu casa
				{ At = 0, Duration = 6.5, From = { "Casa", V(160, 130, 160) }, To = { "Casa", V(55, 38, 55) }, Look = { "Casa", V(0, 0, 0) }, Shake = 0.2, Fov = 60 },
				-- Dentro: la cuna desde arriba, despacio (lo primero que ves es lo que ven ellos)
				{ At = 6.5, Duration = 3.4, From = { "Cuna", V(3, 8, 4) }, To = { "Cuna", V(1.5, 5, 2.5) }, Look = { "Cuna", V(0, 0.6, 0) }, Fov = { 60, 50 }, Cut = "Dip" },
				-- Cierre: la cámara sube y deja a la familia alrededor de la cuna
				{ At = 31, Duration = 5, From = { "Cuna", V(1.5, 4.5, 2.5) }, To = { "Cuna", V(4, 9, 6) }, Look = { "Cuna", V(0, 0.6, 0) }, Fov = { 50, 58 }, Easing = "InOut" },
			},
			Actors = {
				{ At = 0, Spawn = { Key = "Familia", Npc = "Familia", Anchor = "Cuna", Offset = V(-2.3, 0, 1.2), Face = { "Cuna" }, Mood = "Joy" } },
				{ At = 0, Spawn = { Key = "Abu", Npc = "Abu", Anchor = "Cuna", Offset = V(2.3, 0, 1.2), Face = { "Cuna" }, Mood = "Calm" } },
				look(6.6, "Familia", "Cuna"),
				look(6.6, "Abu", "Cuna"),
				-- Cuando empiezan a hablar, se miran (y a ti)
				look(9.5, "Familia", "Speaker"),
				look(9.5, "Abu", "Speaker"),
				-- Te dejan dormir: vuelven a su sitio de la casa andando
				{ At = 32, Exit = { Key = "Familia", To = "FamiliaSitio", Walk = true } },
				{ At = 33, Exit = { Key = "Abu", To = "AbuSitio", Walk = true } },
			},
			Dialogue = {
				{ S = "Familia", T = "Mira… No llora. Solo mira.", To = "Abu", Pause = 9.6, Shot = "PrimerPlano:Familia", A = "Happy" },
				{ S = "Abu", T = "Te damos la bienvenida al mundo, {nombre}. Valmar te estaba esperando.", To = "Yo", Shot = "PrimerPlano:Abu", Pause = 0.4 },
				{ S = "Familia", T = "Hola. Soy yo. Llevaba meses ensayando qué decirte… y ahora no me sale nada.", To = "Yo", Beat = "Respirar", Shot = "Reaccion:Familia" },
				-- (quien jugó el prólogo soñó con la Grieta: Abu lo nota)
				{ S = "Abu", T = "Mira qué manitas… y cómo sonríe. Algo bonito habrá soñado esta noche.", To = "Familia", Shot = "Inserto:Cuna", Pause = 0.3, If = { Memories = { "SuenoGrieta" } } },
				{ S = "Abu", T = "Mira qué manitas tan pequeñas… y qué ganas de explorar.", To = "Yo", Shot = "Inserto:Cuna", Pause = 0.3, IfNot = { Memories = { "SuenoGrieta" } }, Alt = true },
				{ S = "Familia", T = "Ya estás en casa.", To = "Yo", At = 29.2, Shot = "PPP:Familia" },
			},
			Ambience = {
				{ At = 0, Kind = "Calle" },
				{ At = 6.5, Kind = "Casa", Fade = 1.5 },
			},
			Light = {
				{ At = 6.5, Preset = "InteriorCalido", Fade = 1.5 },
			},
			Titles = {
				{ At = 0.8, Text = "CINE.NACIMIENTO.LUGAR", Sub = "CINE.NACIMIENTO.CUANDO", Duration = 4.5 },
				{ At = 31.5, Text = "CHAPTER.BEBE.TITLE", Sub = "CHAPTER.BEBE.INTRO", Duration = 4 },
			},
		},
	},

	---------------------------------------------------------------------
	-- BEBÉ · Primeros pasos: Abu te espera con los brazos abiertos (prioridad 1)
	-- ¿Qué pasa? Acabas de cruzar el salón andando, solo, hasta Abu. Tu familia llega corriendo.
	-- ¿Por qué? Es tu primer logro: el tutorial de moverse termina en una persona, no en un cartel.
	-- ¿Qué siente el personaje? Abu, orgullo tranquilo; Familia, euforia (y pena por casi perdérselo).
	-- ¿Qué ve el jugador? Desde tu altura: Abu enorme y agachada hacia ti; luego tu familia entrando.
	-- ¿Qué quiero que sienta? Logro y calidez: «lo he hecho yo, y les importa».
	---------------------------------------------------------------------
	Bebe_PrimerosPasosAbu = {
		Skippable = true,
		Sting = "PrimerosPasos",
		Anchors = {
			Bebe = "Player",
			Abu = "Place:FamiliaAbu",
			Cocina = "Place:HomeCocina",
			FamiliaSitio = "Place:FamiliaPadre",
		},
		Tracks = {
			Camera = {
				-- A tu altura, desde detrás de ti: Abu delante, grande, esperándote
				{ At = 0, Duration = 3.2, From = { "Bebe", V(0.9, 1.1, 3.2), true }, To = { "Bebe", V(0.6, 1, 2.2), true }, Look = { "Abu", V(0, 2.6, 0) }, Fov = { 62, 54 } },
			},
			Actors = {
				-- Tu familia entra corriendo desde la cocina y se para a tu lado
				{ At = 6.2, Enter = { Key = "Familia", Npc = "Familia", From = "Cocina", To = { "Bebe", V(-2.5, 0, 1.5), true }, Walk = true, Run = true, Mood = "Surprise" } },
				mood(10.5, "Familia", "Joy"),
				gesture(13.4, "Familia", "Cheer"),
				gesture(23.2, "Familia", "Cheer"),
				{ At = 25.2, Exit = { Key = "Familia", To = "FamiliaSitio", Walk = true } },
			},
			Dialogue = {
				{ S = "Abu", T = "Eso es… Un pasito más. Otro. Mírame a mí, no a los pies.", To = "Yo", Pause = 1, Shot = "Hombro:Yo>Abu" },
				{ S = "Abu", T = "¡Has llegado hasta aquí sin ayuda!", To = "Yo", Pause = 0.6, Shot = "Hombro:Abu>Yo", A = "Happy" },
				{ S = "Familia", T = "¿Qué ha pasado? ¿Ha andado? ¿¡Ha andado y me lo he perdido!?", To = "Abu", Shot = "Seguir:Familia" },
				{ S = "Abu", T = "Ha andado. Y ha venido derechito a su abu. Que conste.", To = "Familia", Shot = "Hombro:Familia>Abu" },
				{ S = "Familia", T = "Pues esto hay que celebrarlo con una foto. ¡Que no se mueva nadie! …Bueno, tú sí, que ahora ya no hay quien te pare.", To = "Yo", Shot = "Reaccion:Familia" },
			},
			Music = {
				{ At = 3.4, Intensity = "Resolucion" },
			},
			Ambience = {
				{ At = 0, Kind = "Casa" },
			},
			Light = {
				{ At = 0, Preset = "InteriorCalido", Fade = 1 },
			},
			Titles = {
				{ At = 24.4, Text = "MOMENT.PRIMEROS_PASOS", Duration = 3 },
			},
		},
	},

	---------------------------------------------------------------------
	-- BEBÉ · El ventanal: tu familia detrás de ti, Valmar delante (prioridad 2)
	-- ¿Qué pasa? Te asomas al ventanal; Abu y tu familia se ponen detrás y te enseñan la ciudad.
	-- ¿Por qué? Es el final de la etapa de bebé: el mundo de fuera te espera.
	-- ¿Qué siente el personaje? Ellos, nostalgia anticipada («crecerá»); tú, asombro.
	-- ¿Qué ve el jugador? Tres siluetas contra la ventana → la cámara sale y vuela sobre Valmar → vuelve.
	-- ¿Qué quiero que sienta? Ganas de salir ahí fuera, sin dejar de sentirse en casa.
	---------------------------------------------------------------------
	Bebe_VentanalFamilia = {
		Skippable = true,
		Music = "TemaValmar",
		Anchors = {
			Ventana = "Place:Ventanal",
			Ciudad = "Zone:Valmar Centro",
			Casa = "Place:CasaFamiliar",
			Bebe = "Player",
			AbuSitio = "Place:FamiliaAbu",
			FamiliaSitio = "Place:FamiliaPadre",
		},
		Tracks = {
			Camera = {
				-- Desde detrás: tú en la ventana; ellos llegan y se ponen a tu espalda
				{ At = 0, Duration = 5.5, From = { "Bebe", V(0.5, 3.2, 6.5), true }, To = { "Bebe", V(0.3, 2.6, 4.8), true }, Look = { "Ventana", V(0, 1.2, 0) }, Fov = 55 },
				-- Lo que miras: la cámara cruza el cristal y sale sobre Valmar
				{ At = 5.5, Duration = 2.5, From = { "Ventana", V(0, 0.5, 3), true }, To = { "Ventana", V(0, 1, -2), true }, Look = { "Ventana", V(0, 0.5, -30), true } },
				{ At = 8, Duration = 3.5, From = { "Ventana", V(0, 1, -2), true }, To = { "Ventana", V(0, 30, -45), true }, Look = { "Ventana", V(0, 0.5, -30), true }, LookTo = { "Ciudad", V(0, 20, 0) } },
				{ At = 11.5, Duration = 4, From = { "Ventana", V(0, 30, -45), true }, To = { "Casa", V(0, 170, 0) }, Look = { "Ciudad", V(0, 20, 0) } },
				-- Vuelta a casa: la familia detrás del bebé, mirando lo mismo que tú
				{ At = 15.5, Duration = 12, From = { "Ventana", V(1.5, 1.6, -2.5), true }, To = { "Ventana", V(1, 1.8, -1.8), true }, Look = { "Bebe", V(0, 1.6, 1.5), true }, Cut = "Dip" },
			},
			Actors = {
				{ At = 0.2, Enter = { Key = "Abu", Npc = "Abu", From = "AbuSitio", To = { "Bebe", V(1.4, 0, 2.2), true }, Walk = true } },
				{ At = 0.8, Enter = { Key = "Familia", Npc = "Familia", From = "FamiliaSitio", To = { "Bebe", V(-1.4, 0, 2.2), true }, Walk = true } },
				look(5.4, "Abu", "Ventana"),
				look(5.4, "Familia", "Ventana"),
				look(16, "Abu", "Yo"),
				look(17.5, "Familia", "Abu"),
				{ At = 27, Exit = { Key = "Familia", To = "FamiliaSitio", Walk = true } },
				{ At = 27.6, Exit = { Key = "Abu", To = "AbuSitio", Walk = true } },
			},
			Dialogue = {
				{ S = "Abu", T = "Eso de ahí es Valmar. Algún día lo recorrerás entero.", At = 3, To = "Yo" },
				{ S = "Familia", T = "Ahí está el cole. Y el parque. Y el mar, al fondo, ¿lo ves?", At = 8.6 },
				{ S = "Abu", T = "Cuando yo tenía tu edad, todo eso era campo. El mar ya estaba. El mar siempre está.", At = 16.2, To = "Yo" },
				{ S = "Familia", T = "Despacio, ¿eh? Primero aprende a no comerte los bloques.", To = "Abu", Pause = 0.6, A = "Happy" },
			},
			Ambience = {
				{ At = 0, Kind = "Casa" },
				{ At = 5.5, Kind = "Calle", Fade = 1.2 },
				{ At = 15.5, Kind = "Casa", Fade = 1 },
			},
			Light = {
				{ At = 15.5, Preset = "InteriorCalido", Fade = 1 },
			},
			Titles = {
				{ At = 12, Text = "CINE.VALMAR.TITULO", Sub = "CINE.VALMAR.LEMA", Duration = 3.5 },
			},
		},
	},

	---------------------------------------------------------------------
	-- COLE01 · La bienvenida: Lucía te presenta a la clase (prioridad 2)
	-- ¿Qué pasa? Entras en 1.º A el primer día. Lucía te presenta; la clase reacciona.
	-- ¿Por qué? Es el primer contacto con los que serán tus amigos… y con Bruno.
	-- ¿Qué siente el personaje? Tú, vergüenza de ser «el nuevo»; Nico, ganas; Sara, orden; Bruno, celos.
	-- ¿Qué ve el jugador? Diez cabezas que se giran a la vez hacia ti; luego cada cara, una a una.
	-- ¿Qué quiero que sienta? El vértigo del primer día… y que aquí hay sitio para ti.
	---------------------------------------------------------------------
	Cole01_Bienvenida = {
		Skippable = true,
		Anchors = { Yo = "Player", Pizarra = "Place:PizarraA" },
		Tracks = {
			Camera = {
				-- Desde la puerta, sobre tu hombro: Lucía y la clase delante
				{ At = 0, Duration = 1.5, Shot = "Hombro:Yo>Lucia" },
				-- Mateo no dice nada: baja la mirada (nadie más se fija)
				{ At = 29.2, Duration = 1.8, Shot = "Reaccion:Mateo" },
				{ At = 31, Duration = 5.4, Shot = "Hombro:Lucia>Yo" },
			},
			Actors = {
				use(0, "Lucia"),
				use(0, "Nico"),
				use(0, "Sara"),
				use(0, "Bruno"),
				use(0, "Ruben"),
				use(0, "Mateo"),
				use(0, "Omar"),
				use(0, "Iker"),
				use(0, "Hugo"),
				use(0, "Vega"),
				use(0, "Alex"),
				-- Todos se giran a mirar al nuevo
				look(0.3, "Nico", "Yo"),
				look(0.4, "Sara", "Yo"),
				look(0.5, "Omar", "Yo"),
				look(0.5, "Iker", "Yo"),
				look(0.6, "Vega", "Yo"),
				look(0.6, "Alex", "Yo"),
				look(0.7, "Bruno", "Yo"),
				look(0.8, "Ruben", "Yo"),
				look(0.9, "Hugo", "Yo"),
				look(1.2, "Mateo", "Yo"),
				mood(1.3, "Mateo", "Nervous"),
				-- …y luego siguen la conversación
				look(7, "Nico", "Speaker"),
				look(7, "Sara", "Speaker"),
				look(7, "Omar", "Speaker"),
				look(7, "Iker", "Speaker"),
				look(7, "Vega", "Speaker"),
				look(7, "Alex", "Speaker"),
				look(7, "Bruno", "Speaker"),
				look(7, "Ruben", "Speaker"),
				look(7, "Hugo", "Speaker"),
				look(7, "Mateo", "Speaker"),
				mood(22.4, "Bruno", "Angry"),
				gesture(26.2, "Ruben", "Laugh"),
				mood(29, "Bruno", "Calm"),
				look(29.2, "Mateo", "Suelo"),
				look(31, "Mateo", "Speaker"),
			},
			Dialogue = {
				{ S = "Lucia", T = "¡Mirad quién ha encontrado el aula!", To = "Yo", Pause = 1.5, Shot = "Medio:Lucia", IfNot = TARDE },
				{ S = "Lucia", T = "¡Mirad quién ha encontrado el aula! Un poquito tarde… pero la ha encontrado.", To = "Yo", Pause = 1.5, Shot = "Medio:Lucia", If = TARDE, Alt = true },
				-- (si llegaste a tiempo, aquí hay un silencio: toda la clase te mira)
				{ S = "Lucia", T = "Chicos, chicas: hoy tenemos a alguien nuevo en clase. Se llama {nombre}.", At = 7, Shot = "Lateral:Sara" },
				{ S = "Nico", T = "¿Juegas al fútbol? Necesitamos uno para el recreo.", To = "Yo", Shot = "PrimerPlano:Nico", A = "Happy" },
				{ S = "Sara", T = "Nico, déjale llegar.", To = "Nico", Shot = "Reaccion:Sara" },
				{ S = "Sara", T = "Hola. Soy Sara. Ya tengo hechos los deberes de mañana.", To = "Yo", Shot = "PrimerPlano:Sara" },
				{ S = "Bruno", T = "Otro más… Como si no fuéramos ya muchos.", Pause = 0.6, Beat = "Apartar", Shot = "Reaccion:Bruno", A = "ArmsCrossed" },
				{ S = "Lucia", T = "Bruno. Eso no se dice.", To = "Bruno", Pause = 0.5, Beat = "Mirar", Shot = "PrimerPlano:Lucia" },
				{ S = "Lucia", T = "{nombre}, busca sitio. Hay tres libres: elige bien, que es para todo el curso.", To = "Yo", At = 31 },
			},
			Ambience = {
				{ At = 0, Kind = "Colegio" },
			},
		},
	},

	---------------------------------------------------------------------
	-- COLE01 · Los libros de Mateo (prioridad 2)
	-- ¿Qué pasa? En el recreo, Mateo tropieza y todo lo que lleva sale volando. Rubén se ríe.
	-- ¿Por qué? Es la primera decisión moral del juego: ayudar o seguir con lo tuyo.
	-- ¿Qué siente el personaje? Mateo, vergüenza (no levanta la vista); Rubén, superioridad.
	-- ¿Qué ve el jugador? El golpe → la risa → la cara de Mateo → sus cosas por el suelo → te mira.
	-- ¿Qué quiero que sienta? Incomodidad y la pregunta: «¿y yo qué hago?».
	---------------------------------------------------------------------
	Cole01_LibrosCaen = {
		Skippable = true,
		Anchors = {
			Yo = "Player",
			Libros = { Place = "Patio", Offset = V(3.5, 0, -11.5), Ground = true },
			Album = { Place = "Patio", Offset = V(1, 0, -13.5), Ground = true },
		},
		Tracks = {
			Camera = {
				-- Plano de situación: el patio, Mateo en medio
				{ At = 0, Duration = 1.6, Shot = "General:Mateo" },
				-- Sus cosas por el suelo (y el álbum de cromos)
				{ At = 7.6, Duration = 4.4, Shot = "Inserto:Album" },
			},
			Fx = {
				{ At = 0.7, Play = "Poof", Anchor = "Libros" },
			},
			Shake = {
				{ At = 0.7, Strength = 0.15, Seconds = 0.4 },
			},
			Sound = {
				{ At = 0.7, Play = "Crack", Anchor = "Libros" },
			},
			Actors = {
				use(0, "Mateo"),
				use(0, "Ruben"),
				use(0, "Bruno"),
				use(0, "Hugo"),
				use(0, "Nico"),
				use(0, "Sara"),
				use(0, "Omar"),
				look(0.8, "Ruben", "Mateo"),
				look(0.8, "Bruno", "Mateo"),
				look(0.9, "Hugo", "Mateo"),
				look(0.9, "Nico", "Mateo"),
				look(1, "Sara", "Mateo"),
				look(1, "Omar", "Mateo"),
				mood(0.8, "Mateo", "Shame"),
				look(0.9, "Mateo", "Suelo"),
				gesture(2.2, "Bruno", "Laugh"),
				mood(2, "Hugo", "Shame"),
				look(2.4, "Hugo", "Suelo"),
				-- Mateo levanta la vista: te mira a ti
				look(11.9, "Mateo", "Yo"),
			},
			Dialogue = {
				{ S = "Ruben", T = "¡Jajajaja! ¡Mirad al nuevo número dos!", Pause = 1.4, Shot = "Reaccion:Ruben", Beat = "Laugh" },
				{ S = "Mateo", T = "…", Pause = 0.4, Shot = "PPP:Mateo", Duration = 2.2 },
				-- Lo que piensas al ver sus cosas (si esta mañana conociste a Dani, si llevas tu cromo)
				{ S = "Yo", T = "El hermano de Dani… y su álbum de cromos. Como el mío.", At = 7.8, If = { Flags = { "PaseADani", "LlevaCromo" } } },
				{ S = "Yo", T = "Es Mateo… el hermano de Dani. El del balón.", At = 7.8, If = { Flags = { "PaseADani" }, NotFlags = { "LlevaCromo" } }, Alt = true },
				{ S = "Yo", T = "Ese álbum… es de cromos. Como el mío.", At = 7.8, If = { Flags = { "LlevaCromo" }, NotFlags = { "PaseADani" } }, Alt = true },
				{ S = "Mateo", T = "…", At = 12, Shot = "PrimerPlano:Mateo", Duration = 2.2 },
			},
			Ambience = {
				{ At = 0, Kind = "Colegio" },
			},
			Titles = {
				{ At = 12.2, Text = "¿Le ayudas a recoger sus cosas?", Duration = 2.2 },
			},
		},
	},

	---------------------------------------------------------------------
	-- COLE04 · Los ves: Bruno con lo que es tuyo (prioridad 2, el enfrentamiento)
	-- ¿Qué pasa? En el pasillo pillas a Bruno enseñando tu objeto. Le plantas cara; salen corriendo.
	-- ¿Por qué? Es el arranque del conflicto con Bruno: la persecución empieza aquí.
	-- ¿Qué siente el personaje? Tú, rabia; Bruno, chulería y luego pánico; Hugo, culpa.
	-- ¿Qué ve el jugador? Sobre tu hombro, los tres → tu objeto en su mano → Hugo mirando al suelo → ¡corred!
	-- ¿Qué quiero que sienta? Indignación y ganas de correr detrás.
	---------------------------------------------------------------------
	Cole04_LosVes = {
		Skippable = true,
		Anchors = { Yo = "Player" },
		Tracks = {
			Camera = {
				{ At = 0, Duration = 1.4, Shot = "Hombro:Yo>Bruno" },
			},
			Actors = {
				use(0, "Bruno"),
				use(0, "Ruben"),
				use(0, "Hugo"),
				mood(0, "Hugo", "Shame"),
			},
			-- (sin miradas fijas: todos miran a quien habla, y al gritar tú, se giran hacia ti)
			Dialogue = {
				{ S = "Bruno", T = "…y ni se ha dado cuenta. Mira qué brillo: el portero legendario.", To = "Ruben", Pause = 1.4, Shot = "Inserto:Bruno", If = { Flags = { "ObjetoCromo" } } },
				{ S = "Bruno", T = "…y ni se ha dado cuenta. Mira: la foto del grupito. Qué monos todos.", To = "Ruben", Pause = 1.4, Shot = "Inserto:Bruno", IfNot = { Flags = { "ObjetoCromo" } }, Alt = true },
				{ S = "Hugo", T = "…Bruno. Vámonos.", To = "Bruno", Beat = "Suelo", Shot = "PrimerPlano:Hugo" },
				-- Rubén: el de la mochila (si os enfadasteis, se crece; si le perdonaste, duda)
				{ S = "Ruben", T = "Jejeje. Como lo de la mochila. Igualito.", To = "Bruno", Shot = "Reaccion:Ruben", If = { Flags = { "Ruben_Rival" } } },
				{ S = "Ruben", T = "Bruno… Que es suyo. Devuélveselo y ya está.", To = "Bruno", Beat = "Suelo", Shot = "Reaccion:Ruben", If = { Flags = { "Ruben_Perdonado" } }, Alt = true },
				{ S = "Yo", T = "¡Eh! ¡Eso es mío!", Pause = 0.4, Shot = "Hombro:Bruno>Yo", Mood = "Angry" },
				{ S = "Bruno", T = "¡Corred!", Pause = 0.7, Shot = "Reaccion:Bruno", Beat = "Point", Mood = "Fear" },
				{ S = "Narrador", T = "¡Corre tras ellos! Mantén Shift para correr (y vigila tu estamina).", Pause = 0.2 },
			},
			Music = {
				{ At = 0, Intensity = "Tension" },
			},
			Ambience = {
				{ At = 0, Kind = "Colegio" },
			},
		},
	},

	---------------------------------------------------------------------
	-- COLE06 · La nota (prioridad 2)
	-- ¿Qué pasa? Lucía reparte los exámenes corregidos. Has aprobado (o sacado un sobresaliente).
	-- ¿Por qué? Es el primer examen de verdad: el esfuerzo de la víspera tiene recompensa.
	-- ¿Qué siente el personaje? Nervios hasta el último segundo; luego alivio y orgullo.
	-- ¿Qué ve el jugador? Lucía con los folios → su cara al decir tu nombre → tu hoja → quien estudió contigo.
	-- ¿Qué quiero que sienta? Alivio y la sensación de «me lo he ganado (y no solo)».
	---------------------------------------------------------------------
	Cole06_LaNota = {
		Skippable = true,
		Anchors = { Yo = "Player" },
		Tracks = {
			Camera = {
				{ At = 0, Duration = 1.2, Shot = "Hombro:Yo>Lucia" },
			},
			Actors = {
				use(0, "Lucia"),
				use(0, "Sara", { Choices = { CompaneroEstudio = "Sara" } }),
				use(0, "Iker", { Choices = { CompaneroEstudio = "Iker" } }),
				use(0, "Mateo", { Choices = { CompaneroEstudio = "Mateo" } }),
				mood(0, "Mateo", "Nervous", { Choices = { CompaneroEstudio = "Mateo" } }),
				mood(9, "Mateo", "Joy", { Choices = { CompaneroEstudio = "Mateo" } }),
			},
			Dialogue = {
				{ S = "Lucia", T = "Ya tengo las notas. Silencio, que muerdo.", Pause = 1.2, Shot = "Medio:Lucia" },
				{ S = "Lucia", T = "{nombre}…", To = "Yo", Pause = 0.6, Beat = "Mirar", Shot = "PrimerPlano:Lucia", Duration = 2 },
				-- La hoja (inserto) mientras lo dice
				{ S = "Lucia", T = "Aprobado. Y se nota el trabajo.", To = "Yo", Pause = 0.8, Shot = "Inserto:Yo", IfNot = { LastGradeAtLeast = 9 } },
				{ S = "Lucia", T = "Un sobresaliente. Estoy muy impresionada. De verdad.", To = "Yo", Pause = 0.8, Shot = "Inserto:Yo", If = { LastGradeAtLeast = 9 }, Alt = true },
				{ S = "Lucia", T = "Y anoche repasaste, ¿a que sí? Se nota en los problemas.", To = "Yo", Shot = "Reaccion:Lucia", If = { Flags = { "EstudiasteMas" } }, A = "Happy" },
				-- Quien estudió contigo (está en clase contigo)
				{ S = "Sara", T = "¡Lo sabía! El plan de los veinte minutos funciona.", To = "Yo", If = { Choices = { CompaneroEstudio = "Sara" } }, Shot = "PrimerPlano:Sara", Beat = "Cheer" },
				{ S = "Mateo", T = "¡He aprobado yo también! ¡Por los pelos, pero aprobado!", To = "Yo", If = { Choices = { CompaneroEstudio = "Mateo" } }, Shot = "PrimerPlano:Mateo", Beat = "Cheer", Alt = true },
				{ S = "Iker", T = "Dato curioso: estudiar acompañado mejora la nota. Acabamos de demostrarlo.", To = "Yo", If = { Choices = { CompaneroEstudio = "Iker" } }, Shot = "PrimerPlano:Iker", Alt = true },
				{ S = "Yo", T = "Sin nadie. Solo yo y los números. Y esta vez… he ganado yo.", If = { Choices = { CompaneroEstudio = "Solo" } }, Alt = true },
			},
			Music = {
				{ At = 6.6, Intensity = "Resolucion" },
			},
			Ambience = {
				{ At = 0, Kind = "Colegio" },
			},
		},
	},

	---------------------------------------------------------------------
	-- COLE08 · La final: el pitido inicial, con tu familia en la grada (prioridad 2)
	-- ¿Qué pasa? Empieza la final contra el equipo de Bruno. Tu familia grita desde la banda.
	-- ¿Por qué? Es el momento al que lleva todo el torneo (deporte, capitán, plan, entrenamiento).
	-- ¿Qué siente el personaje? Nervios y piña; Bruno, orgullo (y lo que le dijiste antes).
	-- ¿Qué ve el jugador? El campo entero → tu familia gritando → Bruno → tu equipo → el capitán habla.
	-- ¿Qué quiero que sienta? «Todo lo que he hecho cuenta»: la piña del equipo y el público de casa.
	---------------------------------------------------------------------
	Cole08_Final = {
		Skippable = true,
		Center = "Yo",
		Anchors = { Yo = "Player" },
		Tracks = {
			Camera = {
				{ At = 0, Duration = 1.6, Shot = "General:Andres" },
			},
			Actors = {
				use(0, "Andres"),
				use(0, "Familia"),
				use(0, "Abu"),
				use(0, "Bruno"),
				use(0, "Ruben"),
				use(0, "Omar"),
				use(0, "Nico", FUTBOL),
				use(0, "Alex", BALONCESTO),
				use(0, "Sara", ATLETISMO),
				use(0, "Mateo", AMIGO_MATEO),
				use(0, "Hugo", CON_HUGO),
				mood(6.9, "Familia", "Joy"),
				gesture(7.4, "Abu", "Wave"),
			},
			Dialogue = frases(
				{ S = "Andres", T = "¡LA FINAL! 4.º A contra… 4.º A. El equipo de {nombre} contra el equipo de Bruno.", Pause = 1.6, Shot = "Medio:Andres" },
				{ S = "Familia", T = "¡VAMOS, {nombre}!", To = "Yo", Shot = "Reaccion:Familia", Beat = "Cheer" },
				-- Bruno se acuerda de lo que le contestaste en el descanso
				{ S = "Bruno", T = "Que sea divertido, dijiste. Vale. Pero que gane yo.", To = "Yo", Shot = "Hombro:Yo>Bruno", If = { Choices = { PreFinal = "Deportivo" } } },
				{ S = "Bruno", T = "«Ya veremos en el campo». Pues ya estamos en el campo.", To = "Yo", Shot = "Hombro:Yo>Bruno", If = { Choices = { PreFinal = "Reto" } }, Alt = true },
				{ S = "Bruno", T = "¿Tampoco me vas a contestar ahora? Vale. Ya hablará el marcador.", To = "Yo", Shot = "Hombro:Yo>Bruno", If = { Choices = { PreFinal = "Nada" } }, Alt = true },
				-- Tu puesto en el campo, el del primer partido (misión 03)
				{ S = "Nico", T = "Tú arriba, de delantero, como en el primer partido. Yo te la paso. Esta vez sí.", To = "Yo", Shot = "PrimerPlano:Nico", If = { Choices = { Deporte = "Futbol", Posicion = "Delantero" } } },
				{ S = "Nico", T = "Tú atrás, de defensa, como en el primer partido. Que no pase ni el aire.", To = "Yo", Shot = "PrimerPlano:Nico", If = { Choices = { Deporte = "Futbol", Posicion = "Defensa" } }, Alt = true },
				{ S = "Nico", T = "Tú en la portería, como en el primer partido. Eres un muro. Un muro con guantes.", To = "Yo", Shot = "PrimerPlano:Nico", If = { Choices = { Deporte = "Futbol", Posicion = "Portero" } }, Alt = true },
				-- El capitán que elegisteis
				{ S = "Omar", T = "Capitán, unas palabras.", To = "Yo", Shot = "Reaccion:Omar", If = { Choices = { Capitan = "Yo" } } },
				{ S = "Omar", T = "Soy el capitán. Unas palabras: ¡a por ellos! Con cariño.", Shot = "PrimerPlano:Omar", If = { Choices = { Capitan = "Omar" } }, Alt = true },
				{ S = "Nico", T = "¡Equipo! ¡No os voy a fallar! ¡Voy a llorar! ¡No voy a llorar!", Shot = "PrimerPlano:Nico", If = { Choices = { Capitan = "Otro", Deporte = "Futbol" } }, Alt = true },
				{ S = "Alex", T = "Primera orden de la capitana: nadie se agobia. Segunda: nadie se agobia.", Shot = "PrimerPlano:Alex", If = { Choices = { Capitan = "Otro", Deporte = "Baloncesto" } }, Alt = true },
				{ S = "Sara", T = "Plan: salir rápido, pasar el testigo y no tropezar. Técnicamente, fácil.", Shot = "PrimerPlano:Sara", If = { Choices = { Capitan = "Otro", Deporte = "Atletismo" } }, Alt = true },
				{ S = "Yo", T = "Jugad como sabemos. Y pasadlo bien. Lo demás… ya vendrá.", If = { Choices = { Capitan = "Yo" } } },
				-- El entrenamiento y el plan
				{ S = "Andres", T = "Habéis entrenado bien. Se va a notar.", Shot = "Medio:Andres", If = { Flags = { "BuenEntreno" } } },
				{ S = "Andres", T = "Recordad el plan: a por todas… pero guardad aire para el final.", Shot = "Medio:Andres", If = { Choices = { Estrategia = "Ataque" } } },
				{ S = "Andres", T = "Recordad el plan: paciencia. Los partidos se ganan en el último minuto.", Shot = "Medio:Andres", If = { Choices = { Estrategia = "Paciencia" } }, Alt = true },
				{ S = "Andres", T = "Recordad el plan: aquí juega todo el mundo. Así da gusto.", Shot = "Medio:Andres", If = { Choices = { Estrategia = "Todos" } }, Alt = true },
				-- El grito del grupo, con su nombre
				porNombreDeGrupo("Omar", function(nombre)
					return "¡Por " .. nombre .. "!"
				end, { Shot = "General:Omar", Beat = "Cheer" }),
				{ S = "Andres", T = "¡Y a disfrutar!", Shot = "General:Andres", Beat = "Point" }
			),
			Music = {
				{ At = 0, Intensity = "Tension" },
			},
			Ambience = {
				{ At = 0, Kind = "Colegio" },
			},
		},
	},

	---------------------------------------------------------------------
	-- COLE08 · Las medallas, con tu familia delante (prioridad 2)
	-- ¿Qué pasa? Andrés cuelga las medallas; tu familia y Abu lo ven desde primera fila.
	-- ¿Por qué? Es el cierre del torneo: gane quien gane, lo vivido se premia y alguien te mira.
	-- ¿Qué siente el personaje? Orgullo (o una pena dulce); tu familia, un orgullo que no les cabe.
	-- ¿Qué ve el jugador? La pista → la medalla en tu cuello → tu familia → Abu, emocionada → Bruno.
	-- ¿Qué quiero que sienta? Que el resultado importa menos que quién estaba allí.
	---------------------------------------------------------------------
	Cole08_Medallas = {
		Skippable = true,
		Center = "Yo",
		Anchors = { Yo = "Player" },
		Tracks = {
			Camera = {
				{ At = 0, Duration = 1.4, Shot = "General:Andres" },
				-- La medalla en tu cuello
				{ At = 9.4, Duration = 2.2, Shot = "Inserto:Yo" },
			},
			Actors = {
				use(0, "Andres"),
				use(0, "Familia"),
				use(0, "Abu"),
				use(0, "Bruno"),
				use(0, "Ruben"),
				use(0, "Omar"),
				use(0, "Nico"),
				use(0, "Alex"),
				use(0, "Sara"),
				use(0, "Mateo", AMIGO_MATEO),
				use(0, "Hugo", CON_HUGO),
				mood(11.8, "Familia", "Joy"),
				mood(14.5, "Abu", "Joy"),
				-- Al fondo, el equipo celebra (o Bruno lo celebra)
				gesture(16.5, "Omar", "Cheer", GANADO),
				gesture(16.7, "Nico", "Cheer", GANADO),
				mood(17, "Bruno", "Sad", GANADO),
				gesture(17, "Bruno", "Cheer", PERDIDO),
			},
			Dialogue = {
				{ S = "Andres", T = "Y ahora… ¡las medallas! Primero, los subcampeones.", Pause = 1.4, Shot = "Medio:Andres" },
				{ S = "Andres", T = "Plata para el equipo de {nombre}. Y brilla más que muchas de oro, te lo digo yo.", To = "Yo", Pause = 0.6, Shot = "Hombro:Yo>Andres", If = PERDIDO },
				{ S = "Andres", T = "Y el oro… para el equipo de {nombre}. Pesa, ¿eh? Es la emoción.", To = "Yo", Pause = 0.6, Shot = "Hombro:Yo>Andres", If = GANADO, Alt = true },
				{ S = "Familia", T = "¡Mirad! ¡Es {nombre}! ¡Es de mi familia!", At = 11.8, Shot = "Reaccion:Familia", Beat = "Cheer" },
				{ S = "Abu", T = "Ay… que se me ha metido algo en el ojo. En los dos. Qué cosas.", Pause = 0.8, Beat = "Respirar", Shot = "PPP:Abu", G = "Clap" },
				-- Lo que hiciste al acabar la final
				{ S = "Bruno", T = "Lo de darme la mano… ha estado bien. No te acostumbres.", To = "Yo", Shot = "Reaccion:Bruno", If = { Choices = { TrasFinal = "Mano" } } },
				{ S = "Omar", T = "¿Estás mejor? Te he guardado agua. Y medio bocadillo, que es lo que más quiero.", To = "Yo", Shot = "Reaccion:Omar", If = { Choices = { TrasFinal = "Rincon" } }, Alt = true },
				{ S = "Omar", T = "¡Otra foto de equipo! ¡Esta para la nevera de cada uno!", Shot = "General:Omar", If = { Choices = { TrasFinal = "Equipo" } }, Alt = true, Beat = "Cheer" },
				{ S = "Andres", T = "Un último premio: el de deportividad del torneo. Es para… {nombre}. Por cómo has jugado. Y por cómo has tratado a todos.", To = "Yo", Shot = "Medio:Andres", If = { Traits = { Deportividad = 4 } } },
			},
			Music = {
				{ At = 9.4, Intensity = "Resolucion" },
			},
			Ambience = {
				{ At = 0, Kind = "Colegio" },
			},
		},
	},

	---------------------------------------------------------------------
	-- COLE09 · La foto de 1998: un descubrimiento (prioridad 2)
	-- ¿Qué pasa? En la sala cerrada encontráis la foto de la clase de 1998. La niña del jersey amarillo es Lucía.
	-- ¿Por qué? Es la respuesta al misterio («L.», la nota, la llave 13) y une a tu profe con tu historia.
	-- ¿Qué siente el personaje? Asombro y ternura; Sara, la emoción de quien ha resuelto un caso.
	-- ¿Qué ve el jugador? General de la sala → reacción de Sara → tu mirada a la pared → la foto → reacciones.
	-- ¿Qué quiero que sienta? El «¡ahhh!» del misterio resuelto y que el colegio tiene memoria.
	---------------------------------------------------------------------
	Cole09_LaFoto = {
		Skippable = true,
		Anchors = {
			Yo = "Player",
			Sala = "Place:SalaCerrada",
			Foto = { Place = "SalaCerrada", Offset = V(5.2, 0, -0.3), Ground = true },
		},
		Tracks = {
			Camera = {
				-- 1. General: la sala polvorienta, todos delante de la pared
				{ At = 0, Duration = 2.6, From = { "Sala", V(-4.5, 4.2, 2.4) }, To = { "Sala", V(-3.8, 3.8, 2) }, Look = { "Foto", V(0, 1.4, 0) }, Fov = 62 },
				-- 2. Reacción: Sara ve algo (su plano lo pide su frase)
				-- 3-4. Tu mirada: sobre tu hombro, hacia la pared
				{ At = 5.2, Duration = 1.4, Shot = "Hombro:Yo>Foto" },
				-- 5. El objeto: la foto, con la luz del recuerdo, acercándose despacio
				{ At = 6.6, Duration = 8.8, From = { "Foto", V(1.4, 1.8, 1.6) }, To = { "Foto", V(0.8, 1.6, 1) }, Look = { "Foto", V(0, 1.4, 0) }, Fov = { 42, 32 }, Cut = "Dip" },
				-- 6. Reacción: sus frases piden sus planos
			},
			Actors = {
				use(0, "Sara"),
				use(0, "Omar"),
				use(0, "Nico"),
				use(0, "Iker", CON_IKER),
				use(0, "Ramon", { Choices = { Entrar = "Permiso" } }),
				look(0.2, "Sara", "Foto"),
				mood(2.6, "Sara", "Surprise"),
				look(3.4, "Omar", "Foto"),
				look(3.6, "Nico", "Foto"),
				look(3.6, "Iker", "Foto", CON_IKER),
				look(3.8, "Ramon", "Foto", { Choices = { Entrar = "Permiso" } }),
				-- Se miran entre ellos
				look(15.4, "Sara", "Speaker"),
				look(15.4, "Omar", "Speaker"),
				look(15.4, "Nico", "Speaker"),
				look(15.4, "Iker", "Speaker", CON_IKER),
				mood(15.5, "Nico", "Joy"),
				mood(15.5, "Ramon", "Sad", { Choices = { Entrar = "Permiso" } }),
			},
			Dialogue = {
				{ S = "Sara", T = "Esperad. Esa foto…", Pause = 2.7, Shot = "Reaccion:Sara", Duration = 1.9 },
				{ S = "Narrador", T = "4.º A, 1998. Delante de esta misma pizarra.", At = 7 },
				{ S = "Narrador", T = "En la primera fila, una niña con jersey amarillo y coletas…", Pause = 0.4 },
				{ S = "Sara", T = "Es… ¡es LUCÍA! ¡Nuestra Lucía! ¡Fue a NUESTRO colegio!", At = 15.6, Shot = "Reaccion:Sara", A = "Surprised" },
				{ S = "Omar", T = "Lucía con coletas. Esto hay que dibujarlo. Ya.", Shot = "Reaccion:Omar" },
				{ S = "Nico", T = "¡«L.»! ¡L de Lucía! ¡Lo sabía! …Vale, no lo sabía.", Shot = "Reaccion:Nico", Beat = "Cheer" },
				{ S = "Iker", T = "Dato curioso: acabamos de resolver un caso de hace más de veinte años.", If = CON_IKER, Shot = "Reaccion:Iker" },
			},
			Light = {
				{ At = 6.6, Preset = "Recuerdo", Fade = 0.8 },
				{ At = 15.4, Preset = false, Fade = 0.8 },
			},
			Music = {
				{ At = 2.6, Intensity = "Descubrimiento" },
			},
			Ambience = {
				{ At = 0, Kind = "Colegio" },
			},
		},
	},

	---------------------------------------------------------------------
	-- COLE12 · La cápsula del tiempo (prioridad 1, final de episodio)
	-- ¿Qué pasa? El último día se abre la cápsula que dejasteis en la sala del fondo (misión 09).
	-- ¿Por qué? Lucía lo prometió, y lo que metiste hace dos años te habla hoy.
	-- ¿Qué siente el personaje? Nostalgia, risa nerviosa; Lucía, el círculo que se cierra (1998 → hoy).
	-- ¿Qué ve el jugador? La sala llena → Ramón abriendo el candado → lo tuyo en manos de Lucía → caras.
	-- ¿Qué quiero que sienta? Que el tiempo ha pasado de verdad y que lo que elegiste importaba.
	---------------------------------------------------------------------
	Cole12_Capsula = {
		Skippable = true,
		Anchors = {
			Yo = "Player",
			Sala = "Place:SalaCerrada",
			Caja = { Place = "SalaCerrada", Offset = V(4, 0, -2), Ground = true },
		},
		Tracks = {
			Camera = {
				{ At = 0, Duration = 1.6, From = { "Sala", V(-5, 4.2, 2.6) }, To = { "Sala", V(-4.6, 4, 2.4) }, Look = { "Caja", V(0, 1, 0) }, Fov = 62 },
			},
			Sound = {
				{ At = 11.2, Play = "Ping", Anchor = "Caja" },
			},
			Actors = {
				use(0, "Lucia"),
				use(0, "Ramon"),
				use(0, "Nico"),
				use(0, "Sara"),
				use(0, "Omar"),
				use(0, "Mateo", AMIGO_MATEO),
				use(0, "Hugo", CON_HUGO),
				use(0, "Iker", CON_IKER),
				-- Todos miran el candado mientras Ramón lo abre
				look(7.8, "Nico", "Caja"),
				look(7.8, "Sara", "Caja"),
				look(7.8, "Omar", "Caja"),
				look(7.8, "Mateo", "Caja", AMIGO_MATEO),
				look(7.8, "Hugo", "Caja", CON_HUGO),
				look(7.8, "Iker", "Caja", CON_IKER),
				look(7.8, "Lucia", "Caja"),
				gesture(11.3, "Nico", "Cheer"),
				look(11.4, "Nico", "Speaker"),
				look(11.4, "Sara", "Speaker"),
				look(11.4, "Omar", "Speaker"),
				look(11.4, "Mateo", "Speaker", AMIGO_MATEO),
				look(11.4, "Hugo", "Speaker", CON_HUGO),
				look(11.4, "Iker", "Speaker", CON_IKER),
				look(11.4, "Lucia", "Speaker"),
				mood(12, "Lucia", "Joy"),
			},
			Dialogue = frases(
				{ S = "Lucia", T = "Lo prometí: la cápsula se abre el último día de colegio. Y esta vez no se me olvida.", Pause = 1.6, Shot = "PrimerPlano:Lucia" },
				{ S = "Ramon", T = "Código secreto…", At = 7.8, Shot = "Inserto:Caja", Duration = 3 },
				{ S = "Ramon", T = "Clac. Abierta. Treinta años guardando llaves y esta es la que más me ha gustado abrir.", At = 11.2, Shot = "Reaccion:Ramon" },
				{ S = "Omar", T = "¿Y si se nos hubiera olvidado?", Shot = "Reaccion:Omar" },
				{ S = "Sara", T = "Lo apunté en tres sitios. Cuatro, contando la mano.", To = "Omar", Shot = "Reaccion:Sara" },
				{ S = "Lucia", T = "A ver qué dejó aquí {nombre}…", To = "Yo", Pause = 0.6, Shot = "Hombro:Yo>Lucia" },
				-- Lo que metiste en la cápsula (misión 09)
				{ S = "Lucia", T = "«Hola, yo del último día: ¿has sido valiente? ¿Sigues con tus amigos?»", If = { Choices = { Capsula = "Carta" } }, Shot = "PrimerPlano:Lucia" },
				{ S = "Omar", T = "¡Tu dibujo del grupo! Salgo con un bocadillo. Es el retrato más realista de mi vida.", If = { Choices = { Capsula = "Dibujo" } }, Shot = "Reaccion:Omar", Beat = "Laugh", Alt = true },
				{ S = "Lucia", T = "«Nico será futbolista». Firmado: {nombre}.", If = { Choices = { Capsula = "Prediccion" } }, Shot = "PrimerPlano:Lucia", Alt = true },
				{ S = "Lucia", T = "«¿Seguimos siendo amigos?»", If = { Choices = { Capsula = "Pregunta" } }, Shot = "PrimerPlano:Lucia", Alt = true },
				{ S = "Yo", T = "…Sí. A las dos cosas.", If = { Choices = { Capsula = "Carta" } }, Pause = 0.8 },
				{ S = "Nico", T = "…Me lo guardo. Por si acaso.", If = { Choices = { Capsula = "Prediccion" } }, Beat = "Suelo", Shot = "PPP:Nico", Alt = true },
				{ S = "Omar", T = "Qué pregunta más tonta. Ven aquí.", If = { Choices = { Capsula = "Pregunta" } }, Pause = 1, Shot = "Reaccion:Omar", Alt = true },
				-- El nombre del grupo (misión 03)
				porNombreDeGrupo("Nico", function(nombre)
					return nombre .. ". Desde aquel banco del parque. Y aquí seguimos."
				end, { Shot = "Reaccion:Nico", Pause = 0.4 }),
				{ S = "Lucia", T = "Mi clase de 1998 hizo esto mismo. Y aquí estoy, en la misma sala. Las cosas importantes vuelven.", Pause = 1, Beat = "Pensar", Shot = "PPP:Lucia" }
			),
			Light = {
				{ At = 0, Preset = "Intima", Fade = 1.5 },
			},
			Music = {
				{ At = 0, Intensity = "Intima" },
			},
			Ambience = {
				{ At = 0, Kind = "Colegio" },
			},
		},
	},

	---------------------------------------------------------------------
	-- COLE12 · La última foto de clase (prioridad 1, final de episodio)
	-- ¿Qué pasa? Antes de la ceremonia, tu familia hace la foto de toda la clase en el patio.
	-- ¿Por qué? Es la imagen que cierra la infancia (la que irá a la nevera y al álbum).
	-- ¿Qué siente el personaje? Alegría ruidosa, empujones para salir en la foto; un poco de pena.
	-- ¿Qué ve el jugador? El patio lleno → tu familia con la cámara → su encuadre → ¡flash! → la foto.
	-- ¿Qué quiero que sienta? Una sonrisa con nudo en la garganta.
	---------------------------------------------------------------------
	Cole12_FotoClase = {
		Skippable = true,
		Sting = "Momento",
		Center = "Yo",
		Anchors = { Yo = "Player" },
		Tracks = {
			Camera = {
				{ At = 0, Duration = 2.2, Shot = "General:Yo" },
				-- El encuadre de tu familia (su cámara)… ¡flash! Y la foto se queda quieta un momento
				{ At = 16, Duration = 3.4, Shot = "Hombro:Familia>Yo", Cut = "Flash", Fov = 46 },
			},
			Fx = {
				{ At = 16, Play = "Flash" },
			},
			Actors = {
				use(0, "Familia"),
				use(0, "Abu"),
				use(0, "Lucia"),
				use(0, "Nico"),
				use(0, "Sara"),
				use(0, "Omar"),
				use(0, "Mateo", AMIGO_MATEO),
				use(0, "Hugo", CON_HUGO),
				use(0, "Iker", CON_IKER),
				use(0, "Vega"),
				use(0, "Alex"),
				-- Todos miran a la cámara de tu familia
				look(0.4, "Nico", "Familia"),
				look(0.4, "Sara", "Familia"),
				look(0.4, "Omar", "Familia"),
				look(0.4, "Mateo", "Familia", AMIGO_MATEO),
				look(0.4, "Hugo", "Familia", CON_HUGO),
				look(0.4, "Iker", "Familia", CON_IKER),
				look(0.4, "Vega", "Familia"),
				look(0.4, "Alex", "Familia"),
				look(0.4, "Lucia", "Familia"),
				-- ¡Patata!
				gesture(15.7, "Nico", "Cheer"),
				gesture(15.7, "Sara", "Cheer"),
				gesture(15.7, "Omar", "Cheer"),
				gesture(15.7, "Mateo", "Cheer", AMIGO_MATEO),
				gesture(15.7, "Hugo", "Cheer", CON_HUGO),
				gesture(15.7, "Iker", "Cheer", CON_IKER),
				gesture(15.7, "Vega", "Cheer"),
				gesture(15.7, "Alex", "Cheer"),
				gesture(15.9, "Lucia", "Wave"),
				mood(19.4, "Abu", "Joy"),
			},
			Dialogue = {
				{ S = "Familia", T = "¡Todos juntos, que no cabéis! Lucía, usted también. Nico, agáchate un poco.", Pause = 2.2, Shot = "Medio:Familia" },
				{ S = "Nico", T = "¡Si soy el más bajito!", To = "Familia", Shot = "Reaccion:Nico" },
				{ S = "Omar", T = "Yo me pongo detrás. Por razones de altura. Y de timidez.", Shot = "Reaccion:Omar" },
				{ S = "Familia", T = "Tres, dos, uno… ¡patata!", Pause = 0.3, Shot = "Hombro:Familia>Yo", Duration = 1.8 },
				{ S = "Abu", T = "Esa va a la nevera. Al lado de la del festival. Esa nevera ya es un museo.", At = 19.6, Shot = "Reaccion:Abu" },
			},
			Titles = {
				{ At = 16.4, Text = "📸 La última foto de clase", Sub = "Último día de primaria", Duration = 3 },
			},
			Music = {
				{ At = 16, Intensity = "Resolucion" },
			},
			Ambience = {
				{ At = 0, Kind = "Colegio" },
			},
		},
	},

	---------------------------------------------------------------------
	-- COLE12 · Nadie quiere irse (prioridad 1, final de episodio, 1.ª parte)
	-- ¿Qué pasa? Tras la promesa, el grupo se queda en el patio. Uno a uno dicen lo que no habían dicho.
	-- ¿Por qué? Es el final de la infancia; cada amigo recuerda lo que vivisteis juntos.
	-- ¿Qué siente el personaje? Pena dulce, gratitud, un poco de miedo al instituto.
	-- ¿Qué ve el jugador? El grupo en corro → cada amigo de cerca → tu familia esperando, sin prisa.
	-- ¿Qué quiero que sienta? «Esto se acaba, pero ha sido mío».
	---------------------------------------------------------------------
	Cole12_Despedida = {
		Skippable = true,
		Center = "Yo",
		Anchors = { Yo = "Player" },
		Tracks = {
			Camera = {
				{ At = 0, Duration = 2.2, Shot = "General:Yo" },
			},
			Actors = {
				use(0, "Nico"),
				use(0, "Sara"),
				use(0, "Omar"),
				use(0, "Mateo", AMIGO_MATEO),
				use(0, "Hugo", CON_HUGO),
				use(0, "Iker", CON_IKER),
				use(0, "Familia"),
				use(0, "Abu"),
				mood(0, "Omar", "Sad"),
			},
			Dialogue = {
				{ S = "Nico", T = "Bueno. ¿Quién se va primero?", Pause = 2.2, Shot = "Medio:Nico" },
				{ S = "Sara", T = "Técnicamente, si no se va nadie, no se acaba.", To = "Nico", Shot = "Reaccion:Sara" },
				{ S = "Omar", T = "Pues yo me quedo. Tengo bocadillo para tres horas.", Shot = "PrimerPlano:Omar" },
				-- Mateo: el primer día (o el comedor, si le diste una segunda oportunidad)
				{ S = "Mateo", T = "El primer día se me cayeron los libros y tú te agachaste. No te lo he dicho bastante: gracias.", To = "Yo", Beat = "Suelo", Shot = "PrimerPlano:Mateo", If = { Memories = { "PrimerAmigo" } } },
				{ S = "Mateo", T = "Aquel día que te sentaste conmigo en el comedor… lo cambió todo. Gracias.", To = "Yo", Beat = "Suelo", Shot = "PrimerPlano:Mateo", If = { Memories = { "SegundaOportunidad" }, NotMemories = { "PrimerAmigo" } } },
				{ S = "Hugo", T = "Si en el instituto alguien me dice «cógelo tú, que a ti no te vigilan», diré que no. Lo he practicado.", To = "Yo", Shot = "PrimerPlano:Hugo", If = CON_HUGO },
				{ S = "Iker", T = "Dato curioso: hemos pasado juntos unos mil recreos. No es suficiente.", Shot = "PrimerPlano:Iker", If = CON_IKER },
				-- La promesa que acabáis de hacer
				{ S = "Omar", T = "Oye… lo del puré iba en serio, ¿eh? Juntos. No se me olvida.", Shot = "Reaccion:Omar", If = { Choices = { Promesa = "Juntos" } } },
				{ S = "Sara", T = "Gente nueva, sin olvidar a la de siempre. Hecho. Es un plan.", Shot = "Reaccion:Sara", If = { Choices = { Promesa = "Nuevos" } }, Alt = true },
				{ S = "Nico", T = "Primer verano, primer día: banco del parque. Yo llevo el balón.", Shot = "Reaccion:Nico", If = { Choices = { Promesa = "Banco" } }, Alt = true },
				{ S = "Abu", T = "Los últimos días se recuerdan tanto como los primeros. Te lo dije esta mañana.", To = "Yo", Pause = 1, Shot = "Medio:Abu" },
				{ S = "Familia", T = "{nombre}… cuando quieras. Sin prisa.", To = "Yo", Shot = "Reaccion:Familia", Pause = 0.4 },
			},
			Music = {
				{ At = 0, Intensity = "Intima" },
			},
			Light = {
				{ At = 0, Preset = "Atardecer", Fade = 2 },
			},
			Ambience = {
				{ At = 0, Kind = "Colegio" },
			},
		},
	},

	---------------------------------------------------------------------
	-- COLE12 · Fin de episodio: el grito del grupo y la grúa (prioridad 1, final de episodio, 2.ª parte)
	-- ¿Qué pasa? A la de tres, el grupo grita su nombre por última vez en el patio. La cámara se aleja.
	-- ¿Por qué? Es el cierre de la etapa de niño, como el final de un capítulo de serie.
	-- ¿Qué siente el personaje? Euforia y nudo en la garganta a la vez.
	-- ¿Qué ve el jugador? El corro → el grito → la cámara sube hasta dejar el patio pequeño → rótulo → negro.
	-- ¿Qué quiero que sienta? «Qué bonito ha sido»: ganas de ver el siguiente capítulo.
	---------------------------------------------------------------------
	Cole12_FinDeEpisodio = {
		Skippable = true,
		FadeOut = true,
		Center = "Yo",
		Anchors = { Yo = "Player" },
		Tracks = {
			Camera = {
				{ At = 0, Duration = 1.4, Shot = "DosPlanos:Nico,Omar" },
				{ At = 3.2, Duration = 2.6, Shot = "General:Yo", Cut = "Cut" },
				-- Grúa: la cámara se aleja hasta dejar el patio pequeño
				{ At = 5.8, Duration = 9, From = { "Yo", V(0, 3, 9), true }, To = { "Yo", V(0, 36, 48), true }, Look = { "Yo", V(0, 1.5, 0) }, Easing = "InOut" },
			},
			Actors = {
				use(0, "Nico"),
				use(0, "Sara"),
				use(0, "Omar"),
				use(0, "Mateo", AMIGO_MATEO),
				use(0, "Hugo", CON_HUGO),
				use(0, "Iker", CON_IKER),
				use(0, "Familia"),
				use(0, "Abu"),
				-- El grito del grupo
				gesture(3.2, "Nico", "Cheer"),
				gesture(3.2, "Sara", "Cheer"),
				gesture(3.2, "Omar", "Cheer"),
				gesture(3.3, "Mateo", "Cheer", AMIGO_MATEO),
				gesture(3.3, "Hugo", "Cheer", CON_HUGO),
				gesture(3.3, "Iker", "Cheer", CON_IKER),
				mood(3.2, "Omar", "Joy"),
				mood(3.2, "Nico", "Joy"),
				gesture(6.5, "Familia", "Wave"),
				gesture(7, "Abu", "Wave"),
			},
			Dialogue = frases(
				{ S = "Nico", T = "Venga. A la de tres. Todos.", Pause = 0.4, Duration = 2.4 },
				porNombreDeGrupo("Yo", function(nombre)
					return "¡" .. nombre:upper() .. "!"
				end, { At = 3.2, Duration = 2.2 })
			),
			Music = {
				{ At = 0, Intensity = "Intima" },
				{ At = 3.2, Intensity = "Tema" },
			},
			Light = {
				{ At = 0, Preset = "Atardecer", Fade = 0.5 },
			},
			Ambience = {
				{ At = 0, Kind = "Colegio" },
			},
			Titles = {
				{ At = 9, Text = "CINE.FIN_PRIMARIA.TITULO", Sub = "Así termina el colegio. Lo que empieza ahora… es otra historia.", Duration = 5.6 },
			},
		},
	},
}
