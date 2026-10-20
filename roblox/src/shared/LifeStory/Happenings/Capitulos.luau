-- Escenas de CAPÍTULO y momentos de cámara: las 21 «cinemáticas viejas» (antes en
-- shared/LifeStory/Cinematics.luau y su reproductor propio, client/Controllers/Cinematics), pasadas al
-- MOTOR DE ESCENAS en la fase 6 del cine (docs/cine/auditoria-sistema.md, «Fase 6 · Un solo motor»).
--
-- Mismo id, mismos planos, mismos tiempos, mismos textos (las mismas claves de Strings), mismas voces y
-- los mismos gestos: las misiones, los capítulos (Chapters: IntroCinematic / OutroCinematic) y las
-- partidas guardadas no cambian nada. Lo que se gana al estar en el motor:
--   * un solo reproductor: el mismo encuadre que no atraviesa paredes (CineCamera.fit), la red de
--     seguridad de la fase 3 (cada paso en su pcall, vigilantes, aviso al servidor, vuelta final), el
--     subtítulo con su tiempo de lectura y la actuación de la fase 4;
--   * el servidor lleva el reloj (empieza, sigue y acaba la escena) y el puente entre escenas seguidas;
--   * Queue = true: si ya hay otra escena con cámara en pantalla (el montaje de cambio de etapa), esta
--     espera su turno en el SERVIDOR en vez de cortarla (antes lo hacía la cola de la pantalla).
--
-- Cómo se escribe (los ayudantes de abajo traducen el formato de siempre, para no reescribir planos):
--   planos({ … })              los planos uno detrás de otro, como antes (At se calcula; Dip = true →
--                              Cut = "Dip")
--   rotulo(At, Texto, Sub, s)   pista Titles
--   frase(At, Quién, Texto)     pista Lines (Quién = "Abu" | "Familia" | "Rectora" | "Narrador")
--   gesto(At, Quién, Gesto, s)  pista Acting: "Yo" (tú), "Todos" (tú y la gente de tu escena) o alguien
--                               del reparto; Gesto = Wave | Cheer | Laugh | Point | Dance
-- Speakers = { Rectora = { Name, Voice } }: quien habla sin ser del reparto (su nombre y su voz).

local Capitulos = {}

local V = Vector3.new

-- Planos seguidos (el formato de las cinemáticas viejas): cada uno empieza cuando acaba el anterior
local function planos(list: { { [string]: any } }): { { [string]: any } }
	local out = {}
	local at = 0
	for _, shot in list do
		local s = table.clone(shot)
		s.At = math.floor(at * 1000 + 0.5) / 1000
		if s.Dip then
			s.Dip = nil
			s.Cut = "Dip"
		end
		table.insert(out, s)
		at += shot.Duration or 0
	end
	return out
end

local function rotulo(at: number, text: string, sub: string?, seconds: number?): { [string]: any }
	return { At = at, Text = text, Sub = sub, Duration = seconds or 3 }
end

local function frase(at: number, who: string, text: string): { [string]: any }
	return { At = at, Speaker = who, Text = text }
end

local function gesto(at: number, who: string, play: string, seconds: number?): { [string]: any }
	return { At = at, Who = who, Play = play, Duration = seconds }
end

-- La rectora habla sin estar en el reparto: su nombre de siempre y la voz «Rectora»
local RECTORA = { Rectora = { Name = "NPC.AMAIA", Voice = "Rectora" } }

-- Todas: se saltan, esperan turno si hay otra escena con cámara, y vuelven al juego como antes
local function escena(def: { [string]: any }): { [string]: any }
	def.Skippable = true
	def.Queue = true
	def.Legacy = true -- (vino de Cinematics.luau: lo usa el puente de compatibilidad Controllers/Cinematics)
	return def
end

---------------------------------------------------------------------
-- El nacimiento: Los Pinos desde el cielo → la casa → la cuna. Abu da la bienvenida.
-- (La historia usa ahora Bebe_NacimientoCuna; esta se conserva por si alguna partida o prueba la pide.)
---------------------------------------------------------------------
Capitulos.Bebe_Nacimiento = escena({
	Duration = 21.3,
	FadeIn = true,
	Music = "Nacimiento",
	Anchors = { Casa = "Place:CasaFamiliar", Cuna = "Place:Cuna" },
	Tracks = {
		Camera = planos({
			{ From = { "Casa", V(160, 130, 160) }, To = { "Casa", V(55, 38, 55) }, Look = { "Casa", V(0, 0, 0) }, Duration = 6.5, Shake = 0.25 },
			{ From = { "Cuna", V(3, 9, 5) }, To = { "Cuna", V(1.5, 5, 3) }, Look = { "Cuna", V(0, 1, 0) }, Duration = 14.8, Fov = { 60, 44 }, Dip = true },
		}),
		-- (rótulo primero y frase después, nunca a la vez: shared/LifeStory/SceneTiming)
		Titles = {
			rotulo(0.8, "CINE.NACIMIENTO.LUGAR", "CINE.NACIMIENTO.CUANDO", 4.5),
			rotulo(17.7, "CHAPTER.BEBE.TITLE", "CHAPTER.BEBE.INTRO", 3),
		},
		Lines = {
			frase(7, "Abu", "DLG.ABU.NACER.01"),
			frase(12.7, "Abu", "DLG.ABU.NACER.02"), -- (la voz de antes tarda ~5 s: no se corta)
		},
	},
})

-- De niño a adulto: vuelo por la región (colegio, campus, rascacielos, centro).
Capitulos.Nino_Creces = escena({
	Duration = 18,
	FadeOut = true,
	Music = "PasanLosAnos",
	Anchors = {
		Pinos = "Zone:Los Pinos",
		Campus = "Zone:Campus Valmar",
		Financiero = "Zone:Distrito Financiero",
		Centro = "Zone:Valmar Centro",
	},
	Tracks = {
		Camera = planos({
			{ From = { "Pinos", V(-180, 90, 120) }, To = { "Pinos", V(-60, 60, 40) }, Look = { "Pinos", V(0, 0, -100) }, Duration = 4.5, Shake = 0.35 },
			{ From = { "Campus", V(-160, 110, 150) }, To = { "Campus", V(-40, 70, 60) }, Look = { "Campus", V(0, 10, 0) }, Duration = 4.5, Shake = 0.35, Dip = true },
			{ From = { "Financiero", V(200, 60, 160) }, To = { "Financiero", V(80, 160, 60) }, Look = { "Financiero", V(0, 60, 0) }, Duration = 4.5, Shake = 0.35, Dip = true },
			{ From = { "Centro", V(120, 140, 220) }, To = { "Centro", V(20, 60, 90) }, Look = { "Centro", V(0, 5, 0) }, Duration = 4.5, Shake = 0.35, Dip = true },
		}),
		Titles = {
			rotulo(0.8, "CINE.CRECES.COLEGIO", nil, 3.4),
			rotulo(5.3, "CINE.CRECES.ESTUDIOS", nil, 3.4),
			rotulo(9.8, "CINE.CRECES.SUENOS", nil, 3.4),
			rotulo(14.2, "CINE.CRECES.FINAL", nil, 3.6),
		},
	},
})

-- Primer día de cole: amanece en Los Pinos, la cámara baja hasta tu casa y entra por la ventana.
Capitulos.Cole01_Amanecer = escena({
	AfterScene = true,
	Duration = 10,
	FadeIn = true,
	Music = "TemaValmar",
	Anchors = { Casa = "Place:CasaFamiliar", Cuarto = "Place:HomeDormitorio" },
	Tracks = {
		Camera = planos({
			{ From = { "Casa", V(-140, 110, -140) }, To = { "Casa", V(-50, 35, -45) }, Look = { "Casa", V(0, 5, 0) }, Duration = 5.5 },
			{ From = { "Cuarto", V(6, 7, 6) }, To = { "Cuarto", V(3, 4.5, 3) }, Look = { "Cuarto", V(-2, 1, -2) }, Duration = 4.5 },
		}),
		Titles = {
			rotulo(1, "CHAPTER.NINO.TITLE", "CHAPTER.NINO.INTRO", 4.5),
		},
	},
})

-- La foto del grupo en el parque (misión 03)
Capitulos.Cole03_Foto = escena({
	Duration = 7,
	Sting = "Momento",
	Anchors = { Yo = "Player" },
	Tracks = {
		Camera = planos({
			{ Orbit = "Yo", Radius = 11, Height = 3, FromAngle = -40, ToAngle = 40, Duration = 7, Fov = { 68, 52 }, Shake = 0.2 },
		}),
		Titles = {
			rotulo(2.5, "📸 ¡Patata!", "Tu grupo de amigos", 4),
		},
		Acting = {
			gesto(2.3, "Todos", "Cheer"),
		},
	},
})

-- La excursión: el autobús cruza la región y llega a la granja de Villaverde (misión 07)
Capitulos.Cole07_Viaje = escena({
	Duration = 9,
	FadeIn = true,
	Music = "TemaValmar",
	Anchors = { Pueblo = "Zone:Villaverde", Granja = "Place:Granja" },
	Tracks = {
		Camera = planos({
			{ From = { "Pueblo", V(-160, 120, 160) }, To = { "Granja", V(-60, 45, 60) }, Look = { "Granja", V(0, 5, 0) }, Duration = 5 },
			{ Orbit = "Granja", Radius = 50, Height = 25, FromAngle = 20, ToAngle = 80, Duration = 4 },
		}),
		Titles = {
			rotulo(1.2, "Granja escuela de Villaverde", "¡Día de excursión!", 4.5),
		},
	},
})

-- La foto de la clase en la granja
Capitulos.Cole07_Foto = escena({
	Duration = 7,
	Sting = "Momento",
	Anchors = { Yo = "Player" },
	Tracks = {
		Camera = planos({
			{ Orbit = "Yo", Radius = 13, Height = 4, FromAngle = 30, ToAngle = -30, Duration = 7, Fov = { 68, 52 }, Shake = 0.2 },
		}),
		Titles = {
			rotulo(2.5, "📸 ¡Todos a decir «vaca»!", "La excursión a Villaverde", 4),
		},
		Acting = {
			gesto(2.3, "Todos", "Cheer"),
		},
	},
})

-- El festival de primavera (misión 10)
Capitulos.Cole10_Festival = escena({
	Duration = 8,
	Sting = "Momento",
	Anchors = { Patio = "Place:Patio", Yo = "Player" },
	Tracks = {
		Camera = planos({
			{ Orbit = "Yo", Radius = 12, Height = 4, FromAngle = -30, ToAngle = 30, Duration = 4 },
			{ From = { "Patio", V(0, 10, 28) }, To = { "Patio", V(0, 30, 50) }, Look = { "Patio", V(0, 2, 0) }, Duration = 4 },
		}),
		Titles = {
			rotulo(2, "🎉 ¡Qué festival!", "El festival de primavera", 4),
		},
		Acting = {
			gesto(0.2, "Todos", "Dance", 7.5),
		},
	},
})

-- Primer día de universidad: el campus y la rectora.
Capitulos.Uni_PrimerDia = escena({
	AfterScene = true,
	Duration = 12,
	FadeIn = true,
	Music = "VidaAdulta",
	Anchors = { Uni = "Place:Universidad", Campus = "Zone:Campus Valmar" },
	Speakers = RECTORA,
	Tracks = {
		Camera = planos({
			{ From = { "Campus", V(-220, 120, 180) }, To = { "Uni", V(-60, 30, 60) }, Look = { "Uni", V(0, 10, 0) }, Duration = 6 },
			{ Orbit = "Uni", Radius = 55, Height = 18, FromAngle = 200, ToAngle = 244, Duration = 6 },
		}),
		Titles = {
			rotulo(1, "CHAPTER.UNIVERSIDAD.TITLE", "CHAPTER.UNIVERSIDAD.INTRO", 4.4),
		},
		Lines = {
			frase(6.2, "Rectora", "DLG.AMAIA.CITA.01"), -- (cuando se ha ido el rótulo)
		},
	},
})

-- Vida adulta: el atardecer en Playa Dorada con {abu} (Adu02) y la foto del reencuentro (Adu03)
Capitulos.Adu02_Atardecer = escena({
	Duration = 11,
	Sting = "Momento",
	Music = "TemaValmar",
	Anchors = { Yo = "Player" },
	Tracks = {
		-- Abu es la de la misión (sentada en la playa): se toma prestada para su primer plano
		Actors = {
			{ At = 0, Use = { Key = "Abu", Npc = "Abu" } },
		},
		Camera = planos({
			{ Orbit = "Yo", Radius = 10, Height = 3, FromAngle = 160, ToAngle = 190, Duration = 4, Fov = { 58, 48 }, Shake = 0.15 },
			-- Primer plano de {abu} mirando el mar (fase 6: con el plano con nombre del motor, a la medida de
			-- Abu y sin cortar a quien está a su lado; antes era un travelling a mano delante de su cara)
			{ Shot = "PrimerPlano:Abu", Duration = 3, Shake = 0.12 },
			{ Orbit = "Yo", Radius = 24, Height = 8, FromAngle = 200, ToAngle = 230, Duration = 4, Dip = true },
		}),
		Titles = {
			rotulo(3, "🌅 El mar", "Con tu abu, como cuando era joven", 5),
		},
	},
})

Capitulos.Adu03_Foto = escena({
	Duration = 7,
	Sting = "Momento",
	Anchors = { Yo = "Player" },
	Tracks = {
		Camera = planos({
			{ Orbit = "Yo", Radius = 13, Height = 4, FromAngle = -30, ToAngle = 30, Duration = 7, Fov = { 68, 52 }, Shake = 0.2 },
		}),
		Titles = {
			rotulo(2.5, "📸 Todos otra vez", "La Cafetería de Omar", 4),
		},
		Acting = {
			gesto(2.3, "Todos", "Cheer"),
		},
	},
})

-- Graduación: vuelta alrededor del graduado, la rectora da el discurso.
Capitulos.Uni_Graduacion = escena({
	Duration = 13.6,
	Music = "TemaValmar",
	Anchors = { Yo = "Player", Uni = "Place:Universidad" },
	Speakers = RECTORA,
	Tracks = {
		Camera = planos({
			{ Orbit = "Yo", Radius = 7.5, Height = 3, FromAngle = 30, ToAngle = 150, Duration = 7, Fov = { 62, 48 }, Shake = 0.15 },
			{ From = { "Yo", V(8, 6, 8) }, To = { "Uni", V(40, 60, 90) }, Look = { "Yo", V(0, 2, 0) }, LookTo = { "Uni", V(0, 10, 0) }, Duration = 6.6 },
		}),
		Lines = {
			frase(0.8, "Rectora", "DLG.AMAIA.GRADUA.01"),
		},
		Titles = {
			rotulo(9.5, "CINE.GRADUACION.TITULO", "CINE.GRADUACION.SUB", 3.4), -- (después del discurso)
		},
		Acting = {
			gesto(7.3, "Todos", "Cheer"),
		},
	},
})

-- Misión loca de la universidad: la luz del Monte del Silencio. La nave aparece sobre la cima.
Capitulos.Loco_Abduccion = escena({
	Duration = 9,
	Sting = "Momento",
	Music = "TemaValmar",
	Anchors = { Cima = "Place:CimaMonte", Yo = "Player" },
	Tracks = {
		Camera = planos({
			{ From = { "Yo", V(3, 1.5, 6) }, To = { "Yo", V(2, 1, 4) }, Look = { "Yo", V(0, 2, 0) }, LookTo = { "Cima", V(0, 20, 0) }, Duration = 4, Fov = { 60, 45 }, Shake = 0.4 },
			{ Orbit = "Cima", Radius = 38, Height = 10, FromAngle = 200, ToAngle = 250, Duration = 5, LookHeight = 14, Shake = 0.6, Dip = true },
		}),
		Titles = {
			rotulo(4.5, "🛸 ¡NO ESTÁS SOLO!", "El Monte del Silencio, 3:00 de la madrugada", 4),
		},
	},
})

-- Una nueva vida en Valmar: vuelta alrededor de la Plaza Mayor.
Capitulos.Adulto_Llegada = escena({
	Duration = 11.5,
	FadeIn = true,
	Music = "VidaAdulta",
	Anchors = { Plaza = "Place:PlazaCentro" },
	Tracks = {
		Camera = planos({
			{ Orbit = "Plaza", Radius = 110, Height = 70, FromAngle = 200, ToAngle = 262, Duration = 11.5 },
		}),
		Titles = {
			rotulo(1.5, "CHAPTER.NUEVA_VIDA.TITLE", "CHAPTER.NUEVA_VIDA.INTRO", 4.6),
		},
		Lines = {
			frase(6.9, "Narrador", "CINE.LLEGADA.NARRADOR"), -- (cuando se ha ido el rótulo)
		},
	},
})

-- Final del capítulo adulto: Valmar ya es tu ciudad.
Capitulos.Adulto_TuCiudad = escena({
	Duration = 9,
	Music = "TemaValmar",
	Anchors = { Centro = "Zone:Valmar Centro", Yo = "Player" },
	Tracks = {
		Camera = planos({
			{ From = { "Yo", V(12, 6, 12) }, To = { "Yo", V(60, 90, 60) }, Look = { "Yo", V(0, 2, 0) }, LookTo = { "Centro", V(0, 20, 0) }, Duration = 9 },
		}),
		Titles = {
			rotulo(3, "CHAPTER.NUEVA_VIDA.OUTRO", nil, 5),
		},
	},
})

---------------------------------------------------------------------
-- ENTRADAS Y FINALES DE CAPÍTULO (Chapters.luau: IntroCinematic / OutroCinematic). AfterScene = true:
-- si el montaje de cambio de etapa (Happenings/Etapas) está en pantalla, esperan a que acabe (Queue).
-- Como en una serie: el final del episodio y, después, la cabecera del siguiente.
---------------------------------------------------------------------

-- Entrada · El instituto: el Campus Valmar desde el aire y bajada al patio.
Capitulos.Ins_Entrada = escena({
	AfterScene = true,
	Duration = 9,
	FadeIn = true,
	Music = "TemaValmar",
	Anchors = { Patio = "Place:PatioInstituto", Campus = "Zone:Campus Valmar" },
	Tracks = {
		Camera = planos({
			{ From = { "Campus", V(-200, 120, 160) }, To = { "Patio", V(-40, 28, 44) }, Look = { "Patio", V(0, 4, 0) }, Duration = 5 },
			{ Orbit = "Patio", Radius = 26, Height = 9, FromAngle = 40, ToAngle = 80, Duration = 4, LookHeight = 3, Dip = true },
		}),
		Titles = {
			rotulo(1, "CHAPTER.INSTITUTO.TITLE", "CHAPTER.INSTITUTO.INTRO", 5),
		},
	},
})

-- Final · La universidad: vuelta alrededor de ti en el campus y la cámara se aleja.
Capitulos.Uni_FinCapitulo = escena({
	AfterScene = true,
	Duration = 8,
	Music = "TemaValmar",
	Anchors = { Yo = "Player", Uni = "Place:Universidad" },
	Tracks = {
		Camera = planos({
			{ Orbit = "Yo", Radius = 11, Height = 3, FromAngle = 200, ToAngle = 250, Duration = 4, Fov = { 60, 50 }, Shake = 0.12 },
			{ From = { "Yo", V(8, 6, 10) }, To = { "Uni", V(50, 70, 100) }, Look = { "Yo", V(0, 2, 0) }, LookTo = { "Uni", V(0, 10, 0) }, Duration = 4 },
		}),
		Titles = {
			rotulo(1.2, "CHAPTER.UNIVERSIDAD.TITLE", "Fin del capítulo", 3.2),
			rotulo(4.6, "CHAPTER.UNIVERSIDAD.OUTRO", "Próximamente: Volar del nido", 3.2),
		},
	},
})

-- Entrada · Volar del nido: de tu casa de Los Pinos al centro, donde empieza la vida adulta.
Capitulos.Nido_Entrada = escena({
	AfterScene = true,
	Duration = 9,
	FadeIn = true,
	Music = "VidaAdulta",
	Anchors = { Casa = "Place:CasaFamiliar", Centro = "Zone:Valmar Centro" },
	Tracks = {
		Camera = planos({
			{ From = { "Casa", V(-30, 16, 34) }, To = { "Casa", V(-40, 90, 80) }, Look = { "Casa", V(0, 3, 0) }, LookTo = { "Centro", V(0, 20, 0) }, Duration = 4.5 },
			{ From = { "Centro", V(140, 110, 180) }, To = { "Centro", V(40, 45, 70) }, Look = { "Centro", V(0, 5, 0) }, Duration = 4.5, Dip = true },
		}),
		Titles = {
			rotulo(1, "Volar del nido", "Trabajo, facturas… y la gente que te importa", 5),
		},
	},
})

-- Final · Volar del nido: la cámara sube desde ti hasta el cielo de Valmar.
Capitulos.Nido_Fin = escena({
	AfterScene = true,
	Duration = 7,
	Music = "TemaValmar",
	Anchors = { Yo = "Player", Centro = "Zone:Valmar Centro" },
	Tracks = {
		Camera = planos({
			{ From = { "Yo", V(10, 5, 12) }, To = { "Yo", V(50, 80, 60) }, Look = { "Yo", V(0, 2, 0) }, LookTo = { "Centro", V(0, 20, 0) }, Duration = 7 },
		}),
		Titles = {
			rotulo(1, "Volar del nido", "Fin del capítulo", 2.6),
			rotulo(3.8, "Has volado del nido. Y el nido sigue ahí cuando vuelves.", "Próximamente: Tu vida", 3),
		},
	},
})

-- Entrada · Tu vida: Valmar entera, de la plaza al mar.
Capitulos.TuVida_Entrada = escena({
	AfterScene = true,
	Duration = 9,
	FadeIn = true,
	Music = "VidaAdulta",
	Anchors = { Plaza = "Place:PlazaCentro", Playa = "Zone:Playa Dorada" },
	Tracks = {
		Camera = planos({
			{ Orbit = "Plaza", Radius = 110, Height = 70, FromAngle = 260, ToAngle = 300, Duration = 5 },
			{ From = { "Playa", V(-120, 60, 140) }, To = { "Playa", V(-40, 25, 60) }, Look = { "Playa", V(0, 2, 0) }, Duration = 4, Dip = true },
		}),
		Titles = {
			rotulo(1, "Tu vida", "Ahora tu vida es tuya", 5),
		},
	},
})

---------------------------------------------------------------------
-- PRÓLOGO (el sueño): qué es el juego y el gancho de la saga, antes de jugar el tutorial.
-- Pasa en la isla del sueño (World/Kit/DreamIsland). La raja de luz del cielo es la Grieta (Controllers/SkyRift).
-- (La misión usa ahora las escenas de su guion reescrito, Prologo_G1 y Prologo_G9; estas se conservan
-- con su id y sus rótulos —el guion copia los de Prologo_Cierre—.)
---------------------------------------------------------------------
Capitulos.Prologo_Apertura = escena({
	Duration = 26.5,
	FadeIn = true,
	Music = "TemaValmar",
	Anchors = { Inicio = "Place:PrologoInicio", Puerta = "Place:PrologoPuerta" },
	Tracks = {
		Camera = planos({
			{ From = { "Inicio", V(-30, 45, 40) }, To = { "Inicio", V(40, 55, 34) }, Look = { "Puerta", V(-60, 70, 0) }, Duration = 10, Shake = 0.2 },
			{ From = { "Puerta", V(-40, 12, 26) }, To = { "Puerta", V(-22, 8, 16) }, Look = { "Puerta", V(0, 3, 0) }, Duration = 7, Dip = true },
			{ Orbit = "Inicio", Radius = 9, Height = 4, FromAngle = 200, ToAngle = 330, Duration = 9.5, Dip = true, LookHeight = 1.5 },
		}),
		-- Rótulo primero y frase después, nunca a la vez (shared/LifeStory/SceneTiming); cada frase se lee
		-- entera antes de la siguiente
		Titles = {
			rotulo(0.8, "CINE.PROLOGO.VALMAR", "CINE.PROLOGO.VIDA", 3.2),
			rotulo(22.9, "CINE.PROLOGO.SUENO", "CINE.PROLOGO.SUENO_SUB", 3),
		},
		Lines = {
			frase(4.7, "Narrador", "CINE.PROLOGO.ELIGES"),
			frase(10.3, "Narrador", "CINE.PROLOGO.GRIETA"),
			frase(17.1, "Narrador", "CINE.PROLOGO.COSME"),
		},
	},
})

-- Fin del prólogo: la cámara sube hacia la Grieta y el sueño se apaga. Explica los tres tipos de
-- misión y deja paso al nacimiento (primer capítulo).
Capitulos.Prologo_Cierre = escena({
	Duration = 16.4,
	FadeOut = true,
	Music = "Nacimiento",
	Anchors = { Puerta = "Place:PrologoPuerta" },
	Tracks = {
		Camera = planos({
			{ From = { "Puerta", V(-12, 4, 12) }, To = { "Puerta", V(-12, 60, 60) }, Look = { "Puerta", V(0, 3, 0) }, LookTo = { "Puerta", V(-70, 70, 0) }, Duration = 16.4, Easing = "In" },
		}),
		Lines = {
			frase(0.5, "Narrador", "CINE.PROLOGO.DESPIERTA"),
		},
		-- (los rótulos, cuando se ha leído la frase: nunca a la vez)
		Titles = {
			rotulo(5.1, "CINE.PROLOGO.T_VIDA", "CINE.PROLOGO.S_VIDA", 2.9),
			rotulo(8.7, "CINE.PROLOGO.T_LOCA", "CINE.PROLOGO.S_LOCA", 2.9),
			rotulo(12.3, "CINE.PROLOGO.T_SAGA", "CINE.PROLOGO.S_SAGA", 3.3),
		},
	},
})

return Capitulos
