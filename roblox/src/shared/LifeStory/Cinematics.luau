-- Cinematics: las escenas de cámara de los momentos clave de la vida, escritas como datos.
--
--   Anchors  puntos del mundo que usa la escena. El servidor los busca para cada jugador:
--              "Player"            el personaje
--              "Place:Cuna"        un lugar de Locations (su casa, su ventanal, su colegio…)
--              "Zone:Los Pinos"    el centro de una zona
--              "Actor:Nico"        un personaje de tu escena (mirando hacia donde mira él; si no está, tú)
--   Shots    planos de cámara, uno detrás de otro:
--              { From = P, To = P, Look = P, LookTo = P?, Duration, Easing? }   la cámara viaja de From a To mirando a Look
--              { Orbit = "Ancla", Radius, Height, FromAngle, ToAngle, Duration }  gira alrededor de un punto
--            P = { "Ancla", Vector3 offset, Local? }   (Local = el offset va girado con el ancla, p. ej. "delante del ventanal")
--            Extras de cada plano (como una cámara de cine):
--              Shake = 0.5          cámara en mano (0 = trípode, 1 = mucho)
--              Fov = 50 | { 60, 40 } campo de visión fijo o zoom lento (70 = el normal)
--              Roll = -4            inclinar la cámara (grados)
--              Dip = true           fundido rápido a negro al empezar el plano (corte suave)
--              Focus = false        no desenfocar el fondo (por defecto se enfoca lo que se mira)
--              LookHeight = 2       (Orbit) a qué altura del centro mira
--   Lines    subtítulos (con voz): { At = segundo, Speaker = "Abu" | "Familia" | "Narrador" | nil, TextKey }
--   Titles   rótulos grandes: { At, TextKey, SubKey?, Duration? }
--   Anims    gestos: { At, Who = "Player" | "Todos" | "Nico"…, Play = "Cheer" | "Wave" | "Laugh" | "Point" | "Dance", Duration? }
--            (quien habla en Lines también se mueve al hablar; A = "…" en la línea fija su gesto)
--   Music    pieza de Config.Audio.Music que suena durante la escena; Sting = efecto al empezar
--   FadeIn / FadeOut   empieza o acaba en negro
--   AfterScene = true  (cabeceras y finales de capítulo) si hay una escena del motor en pantalla (el
--                      montaje de cambio de etapa), espera a que acabe antes de empezar
-- Toda escena se puede saltar (botón "Saltar"). La historia avanza igual.

local V = Vector3.new

export type Cinematic = { [string]: any }

local Cinematics: { [string]: Cinematic } = {
	-- El nacimiento: Los Pinos desde el cielo → la casa → la cuna. Abu da la bienvenida.
	Bebe_Nacimiento = {
		Duration = 17,
		FadeIn = true,
		Music = "Nacimiento",
		Anchors = { Casa = "Place:CasaFamiliar", Cuna = "Place:Cuna" },
		Shots = {
			{ From = { "Casa", V(160, 130, 160) }, To = { "Casa", V(55, 38, 55) }, Look = { "Casa", V(0, 0, 0) }, Duration = 6.5, Shake = 0.25 },
			{ From = { "Cuna", V(3, 9, 5) }, To = { "Cuna", V(1.5, 5, 3) }, Look = { "Cuna", V(0, 1, 0) }, Duration = 10.5, Fov = { 60, 44 }, Dip = true },
		},
		Titles = {
			{ At = 0.8, TextKey = "CINE.NACIMIENTO.LUGAR", SubKey = "CINE.NACIMIENTO.CUANDO", Duration = 4.5 },
			{ At = 13.3, TextKey = "CHAPTER.BEBE.TITLE", SubKey = "CHAPTER.BEBE.INTRO", Duration = 3.4 },
		},
		Lines = {
			{ At = 7, Speaker = "Abu", TextKey = "DLG.ABU.NACER.01" },
			{ At = 12.2, Speaker = "Abu", TextKey = "DLG.ABU.NACER.02" }, -- (la voz de antes tarda ~5 s: no se corta)
		},
	},

	-- De niño a adulto: vuelo por la región (colegio, campus, rascacielos, centro).
	Nino_Creces = {
		Duration = 18,
		FadeOut = true,
		Music = "PasanLosAnos",
		Anchors = {
			Pinos = "Zone:Los Pinos",
			Campus = "Zone:Campus Valmar",
			Financiero = "Zone:Distrito Financiero",
			Centro = "Zone:Valmar Centro",
		},
		Shots = {
			{ From = { "Pinos", V(-180, 90, 120) }, To = { "Pinos", V(-60, 60, 40) }, Look = { "Pinos", V(0, 0, -100) }, Duration = 4.5, Shake = 0.35 },
			{ From = { "Campus", V(-160, 110, 150) }, To = { "Campus", V(-40, 70, 60) }, Look = { "Campus", V(0, 10, 0) }, Duration = 4.5, Shake = 0.35, Dip = true },
			{ From = { "Financiero", V(200, 60, 160) }, To = { "Financiero", V(80, 160, 60) }, Look = { "Financiero", V(0, 60, 0) }, Duration = 4.5, Shake = 0.35, Dip = true },
			{ From = { "Centro", V(120, 140, 220) }, To = { "Centro", V(20, 60, 90) }, Look = { "Centro", V(0, 5, 0) }, Duration = 4.5, Shake = 0.35, Dip = true },
		},
		Titles = {
			{ At = 0.8, TextKey = "CINE.CRECES.COLEGIO", Duration = 3.4 },
			{ At = 5.3, TextKey = "CINE.CRECES.ESTUDIOS", Duration = 3.4 },
			{ At = 9.8, TextKey = "CINE.CRECES.SUENOS", Duration = 3.4 },
			{ At = 14.2, TextKey = "CINE.CRECES.FINAL", Duration = 3.6 },
		},
	},

	-- Primer día de cole: amanece en Los Pinos, la cámara baja hasta tu casa y entra por la ventana.
	Cole01_Amanecer = {
		AfterScene = true,
		Duration = 10,
		FadeIn = true,
		Music = "TemaValmar",
		Anchors = { Casa = "Place:CasaFamiliar", Cuarto = "Place:HomeDormitorio" },
		Shots = {
			{ From = { "Casa", V(-140, 110, -140) }, To = { "Casa", V(-50, 35, -45) }, Look = { "Casa", V(0, 5, 0) }, Duration = 5.5 },
			{ From = { "Cuarto", V(6, 7, 6) }, To = { "Cuarto", V(3, 4.5, 3) }, Look = { "Cuarto", V(-2, 1, -2) }, Duration = 4.5 },
		},
		Titles = {
			{ At = 1, TextKey = "CHAPTER.NINO.TITLE", SubKey = "CHAPTER.NINO.INTRO", Duration = 4.5 },
		},
	},

	-- La foto del grupo en el parque (misión 03)
	Cole03_Foto = {
		Duration = 7,
		Sting = "Momento",
		Anchors = { Yo = "Player" },
		Shots = {
			{ Orbit = "Yo", Radius = 11, Height = 3, FromAngle = -40, ToAngle = 40, Duration = 7, Fov = { 68, 52 }, Shake = 0.2 },
		},
		Titles = {
			{ At = 2.5, TextKey = "📸 ¡Patata!", SubKey = "Tu grupo de amigos", Duration = 4 },
		},
		Anims = {
			{ At = 2.3, Who = "Todos", Play = "Cheer" },
		},
	},

	-- La excursión: el autobús cruza la región y llega a la granja de Villaverde (misión 07)
	Cole07_Viaje = {
		Duration = 9,
		FadeIn = true,
		Music = "TemaValmar",
		Anchors = { Pueblo = "Zone:Villaverde", Granja = "Place:Granja" },
		Shots = {
			{ From = { "Pueblo", V(-160, 120, 160) }, To = { "Granja", V(-60, 45, 60) }, Look = { "Granja", V(0, 5, 0) }, Duration = 5 },
			{ Orbit = "Granja", Radius = 50, Height = 25, FromAngle = 20, ToAngle = 80, Duration = 4 },
		},
		Titles = {
			{ At = 1.2, TextKey = "Granja escuela de Villaverde", SubKey = "¡Día de excursión!", Duration = 4.5 },
		},
	},

	-- La foto de la clase en la granja
	Cole07_Foto = {
		Duration = 7,
		Sting = "Momento",
		Anchors = { Yo = "Player" },
		Shots = {
			{ Orbit = "Yo", Radius = 13, Height = 4, FromAngle = 30, ToAngle = -30, Duration = 7, Fov = { 68, 52 }, Shake = 0.2 },
		},
		Titles = {
			{ At = 2.5, TextKey = "📸 ¡Todos a decir «vaca»!", SubKey = "La excursión a Villaverde", Duration = 4 },
		},
		Anims = {
			{ At = 2.3, Who = "Todos", Play = "Cheer" },
		},
	},

	-- El festival de primavera (misión 10)
	Cole10_Festival = {
		Duration = 8,
		Sting = "Momento",
		Anchors = { Patio = "Place:Patio", Yo = "Player" },
		Shots = {
			{ Orbit = "Yo", Radius = 12, Height = 4, FromAngle = -30, ToAngle = 30, Duration = 4 },
			{ From = { "Patio", V(0, 10, 28) }, To = { "Patio", V(0, 30, 50) }, Look = { "Patio", V(0, 2, 0) }, Duration = 4 },
		},
		Titles = {
			{ At = 2, TextKey = "🎉 ¡Qué festival!", SubKey = "El festival de primavera", Duration = 4 },
		},
		Anims = {
			{ At = 0.2, Who = "Todos", Play = "Dance", Duration = 7.5 },
		},
	},

	-- Primer día de universidad: el campus y la rectora.
	Uni_PrimerDia = {
		AfterScene = true,
		Duration = 11,
		FadeIn = true,
		Music = "VidaAdulta",
		Anchors = { Uni = "Place:Universidad", Campus = "Zone:Campus Valmar" },
		Shots = {
			{ From = { "Campus", V(-220, 120, 180) }, To = { "Uni", V(-60, 30, 60) }, Look = { "Uni", V(0, 10, 0) }, Duration = 6 },
			{ Orbit = "Uni", Radius = 55, Height = 18, FromAngle = 200, ToAngle = 240, Duration = 5 },
		},
		Titles = {
			{ At = 1, TextKey = "CHAPTER.UNIVERSIDAD.TITLE", SubKey = "CHAPTER.UNIVERSIDAD.INTRO", Duration = 5 },
		},
		Lines = {
			{ At = 6.5, Speaker = "Rectora", TextKey = "DLG.AMAIA.CITA.01" },
		},
	},

	-- Graduación: vuelta alrededor del graduado, la rectora da el discurso.
	-- Vida adulta: el atardecer en Playa Dorada con {abu} (Adu02) y la foto del reencuentro (Adu03)
	Adu02_Atardecer = {
		Duration = 11,
		Sting = "Momento",
		Music = "TemaValmar",
		Anchors = { Yo = "Player", Abu = "Actor:Abu" },
		Shots = {
			{ Orbit = "Yo", Radius = 10, Height = 3, FromAngle = 160, ToAngle = 190, Duration = 4, Fov = { 58, 48 }, Shake = 0.15 },
			-- Primer plano de {abu} mirando el mar
			{ From = { "Abu", V(1.8, 1.4, -5), true }, To = { "Abu", V(1.2, 1.3, -4), true }, Look = { "Abu", V(0, 1.2, 0) }, Duration = 3, Fov = 42, Shake = 0.12 },
			{ Orbit = "Yo", Radius = 24, Height = 8, FromAngle = 200, ToAngle = 230, Duration = 4, Dip = true },
		},
		Titles = {
			{ At = 3, TextKey = "🌅 El mar", SubKey = "Con tu abu, como cuando era joven", Duration = 5 },
		},
	},
	Adu03_Foto = {
		Duration = 7,
		Sting = "Momento",
		Anchors = { Yo = "Player" },
		Shots = {
			{ Orbit = "Yo", Radius = 13, Height = 4, FromAngle = -30, ToAngle = 30, Duration = 7, Fov = { 68, 52 }, Shake = 0.2 },
		},
		Titles = {
			{ At = 2.5, TextKey = "📸 Todos otra vez", SubKey = "La Cafetería de Omar", Duration = 4 },
		},
		Anims = {
			{ At = 2.3, Who = "Todos", Play = "Cheer" },
		},
	},

	Uni_Graduacion = {
		Duration = 13,
		Music = "TemaValmar",
		Anchors = { Yo = "Player", Uni = "Place:Universidad" },
		Shots = {
			{ Orbit = "Yo", Radius = 10, Height = 3, FromAngle = 30, ToAngle = 150, Duration = 7, Fov = { 62, 48 }, Shake = 0.15 },
			{ From = { "Yo", V(8, 6, 8) }, To = { "Uni", V(40, 60, 90) }, Look = { "Yo", V(0, 2, 0) }, LookTo = { "Uni", V(0, 10, 0) }, Duration = 6 },
		},
		Lines = {
			{ At = 0.8, Speaker = "Rectora", TextKey = "DLG.AMAIA.GRADUA.01" },
		},
		Titles = {
			{ At = 7.5, TextKey = "CINE.GRADUACION.TITULO", SubKey = "CINE.GRADUACION.SUB", Duration = 5 },
		},
		Anims = {
			{ At = 7.3, Who = "Todos", Play = "Cheer" },
		},
	},

	-- Misión loca de la universidad: la luz del Monte del Silencio. La nave aparece sobre la cima.
	Loco_Abduccion = {
		Duration = 9,
		Sting = "Momento",
		Music = "TemaValmar",
		Anchors = { Cima = "Place:CimaMonte", Yo = "Player" },
		Shots = {
			{ From = { "Yo", V(3, 1.5, 6) }, To = { "Yo", V(2, 1, 4) }, Look = { "Yo", V(0, 2, 0) }, LookTo = { "Cima", V(0, 20, 0) }, Duration = 4, Fov = { 60, 45 }, Shake = 0.4 },
			{ Orbit = "Cima", Radius = 38, Height = 10, FromAngle = 200, ToAngle = 250, Duration = 5, LookHeight = 14, Shake = 0.6, Dip = true },
		},
		Titles = {
			{ At = 4.5, TextKey = "🛸 ¡NO ESTÁS SOLO!", SubKey = "El Monte del Silencio, 3:00 de la madrugada", Duration = 4 },
		},
	},

	-- Una nueva vida en Valmar: vuelta alrededor de la Plaza Mayor.
	Adulto_Llegada = {
		Duration = 11,
		FadeIn = true,
		Music = "VidaAdulta",
		Anchors = { Plaza = "Place:PlazaCentro" },
		Shots = {
			{ Orbit = "Plaza", Radius = 110, Height = 70, FromAngle = 200, ToAngle = 260, Duration = 11 },
		},
		Titles = {
			{ At = 1.5, TextKey = "CHAPTER.NUEVA_VIDA.TITLE", SubKey = "CHAPTER.NUEVA_VIDA.INTRO", Duration = 6 },
		},
		Lines = {
			{ At = 6.6, Speaker = "Narrador", TextKey = "CINE.LLEGADA.NARRADOR" }, -- (acaba antes del final)
		},
	},

	-- Final del capítulo adulto: Valmar ya es tu ciudad.
	Adulto_TuCiudad = {
		Duration = 9,
		Music = "TemaValmar",
		Anchors = { Centro = "Zone:Valmar Centro", Yo = "Player" },
		Shots = {
			{ From = { "Yo", V(12, 6, 12) }, To = { "Yo", V(60, 90, 60) }, Look = { "Yo", V(0, 2, 0) }, LookTo = { "Centro", V(0, 20, 0) }, Duration = 9 },
		},
		Titles = {
			{ At = 3, TextKey = "CHAPTER.NUEVA_VIDA.OUTRO", Duration = 5 },
		},
	},

	-- ENTRADAS Y FINALES DE CAPÍTULO (Chapters.luau: IntroCinematic / OutroCinematic). Son escenas de cámara de
	-- las de siempre a propósito: la pantalla las pone en cola y esperan a que acabe el montaje de cambio de
	-- etapa (Happenings/Etapas), así nunca se pisan. Como en una serie: el final del episodio y, después,
	-- la cabecera del siguiente.

	-- Entrada · El instituto: el Campus Valmar desde el aire y bajada al patio.
	Ins_Entrada = {
		AfterScene = true,
		Duration = 9,
		FadeIn = true,
		Music = "TemaValmar",
		Anchors = { Patio = "Place:PatioInstituto", Campus = "Zone:Campus Valmar" },
		Shots = {
			{ From = { "Campus", V(-200, 120, 160) }, To = { "Patio", V(-40, 28, 44) }, Look = { "Patio", V(0, 4, 0) }, Duration = 5 },
			{ Orbit = "Patio", Radius = 26, Height = 9, FromAngle = 40, ToAngle = 80, Duration = 4, LookHeight = 3, Dip = true },
		},
		Titles = {
			{ At = 1, TextKey = "CHAPTER.INSTITUTO.TITLE", SubKey = "CHAPTER.INSTITUTO.INTRO", Duration = 5 },
		},
	},

	-- Final · La universidad: vuelta alrededor de ti en el campus y la cámara se aleja.
	Uni_FinCapitulo = {
		AfterScene = true,
		Duration = 8,
		Music = "TemaValmar",
		Anchors = { Yo = "Player", Uni = "Place:Universidad" },
		Shots = {
			{ Orbit = "Yo", Radius = 11, Height = 3, FromAngle = 200, ToAngle = 250, Duration = 4, Fov = { 60, 50 }, Shake = 0.12 },
			{ From = { "Yo", V(8, 6, 10) }, To = { "Uni", V(50, 70, 100) }, Look = { "Yo", V(0, 2, 0) }, LookTo = { "Uni", V(0, 10, 0) }, Duration = 4 },
		},
		Titles = {
			{ At = 1.2, TextKey = "CHAPTER.UNIVERSIDAD.TITLE", SubKey = "Fin del capítulo", Duration = 3.2 },
			{ At = 4.6, TextKey = "CHAPTER.UNIVERSIDAD.OUTRO", SubKey = "Próximamente: Volar del nido", Duration = 3.2 },
		},
	},

	-- Entrada · Volar del nido: de tu casa de Los Pinos al centro, donde empieza la vida adulta.
	Nido_Entrada = {
		AfterScene = true,
		Duration = 9,
		FadeIn = true,
		Music = "VidaAdulta",
		Anchors = { Casa = "Place:CasaFamiliar", Centro = "Zone:Valmar Centro" },
		Shots = {
			{ From = { "Casa", V(-30, 16, 34) }, To = { "Casa", V(-40, 90, 80) }, Look = { "Casa", V(0, 3, 0) }, LookTo = { "Centro", V(0, 20, 0) }, Duration = 4.5 },
			{ From = { "Centro", V(140, 110, 180) }, To = { "Centro", V(40, 45, 70) }, Look = { "Centro", V(0, 5, 0) }, Duration = 4.5, Dip = true },
		},
		Titles = {
			{ At = 1, TextKey = "Volar del nido", SubKey = "Trabajo, facturas… y la gente que te importa", Duration = 5 },
		},
	},

	-- Final · Volar del nido: la cámara sube desde ti hasta el cielo de Valmar.
	Nido_Fin = {
		AfterScene = true,
		Duration = 7,
		Music = "TemaValmar",
		Anchors = { Yo = "Player", Centro = "Zone:Valmar Centro" },
		Shots = {
			{ From = { "Yo", V(10, 5, 12) }, To = { "Yo", V(50, 80, 60) }, Look = { "Yo", V(0, 2, 0) }, LookTo = { "Centro", V(0, 20, 0) }, Duration = 7 },
		},
		Titles = {
			{ At = 1, TextKey = "Volar del nido", SubKey = "Fin del capítulo", Duration = 2.6 },
			{ At = 3.8, TextKey = "Has volado del nido. Y el nido sigue ahí cuando vuelves.", SubKey = "Próximamente: Tu vida", Duration = 3 },
		},
	},

	-- Entrada · Tu vida: Valmar entera, de la plaza al mar.
	TuVida_Entrada = {
		AfterScene = true,
		Duration = 9,
		FadeIn = true,
		Music = "VidaAdulta",
		Anchors = { Plaza = "Place:PlazaCentro", Playa = "Zone:Playa Dorada" },
		Shots = {
			{ Orbit = "Plaza", Radius = 110, Height = 70, FromAngle = 260, ToAngle = 300, Duration = 5 },
			{ From = { "Playa", V(-120, 60, 140) }, To = { "Playa", V(-40, 25, 60) }, Look = { "Playa", V(0, 2, 0) }, Duration = 4, Dip = true },
		},
		Titles = {
			{ At = 1, TextKey = "Tu vida", SubKey = "Ahora tu vida es tuya", Duration = 5 },
		},
	},

	-- PRÓLOGO (el sueño): qué es el juego y el gancho de la saga, antes de jugar el tutorial.
	-- Pasa en la isla del sueño (World/Kit/DreamIsland). La raja de luz del cielo es la Grieta (Controllers/SkyRift).
	Prologo_Apertura = {
		Duration = 19.5,
		FadeIn = true,
		Music = "TemaValmar",
		Anchors = { Inicio = "Place:PrologoInicio", Puerta = "Place:PrologoPuerta" },
		Shots = {
			{ From = { "Inicio", V(-30, 45, 40) }, To = { "Inicio", V(40, 55, 34) }, Look = { "Puerta", V(-60, 70, 0) }, Duration = 7, Shake = 0.2 },
			{ From = { "Puerta", V(-40, 12, 26) }, To = { "Puerta", V(-22, 8, 16) }, Look = { "Puerta", V(0, 3, 0) }, Duration = 5, Dip = true },
			{ Orbit = "Inicio", Radius = 9, Height = 4, FromAngle = 200, ToAngle = 320, Duration = 7.5, Dip = true, LookHeight = 1.5 },
		},
		Titles = {
			{ At = 0.8, TextKey = "CINE.PROLOGO.VALMAR", SubKey = "CINE.PROLOGO.VIDA", Duration = 4 },
			{ At = 15.9, TextKey = "CINE.PROLOGO.SUENO", SubKey = "CINE.PROLOGO.SUENO_SUB", Duration = 3.3 },
		},
		Lines = {
			-- (cada voz tarda ~5 s: separadas para que ninguna se corte a mitad de frase)
			{ At = 3.4, Speaker = "Narrador", TextKey = "CINE.PROLOGO.ELIGES" },
			{ At = 8.5, Speaker = "Narrador", TextKey = "CINE.PROLOGO.GRIETA" },
			{ At = 13.8, Speaker = "Narrador", TextKey = "CINE.PROLOGO.COSME" },
		},
	},

	-- Fin del prólogo: la cámara sube hacia la Grieta y el sueño se apaga. Explica los tres tipos de
	-- misión y deja paso al nacimiento (Bebe_Nacimiento, primer capítulo).
	Prologo_Cierre = {
		Duration = 14,
		FadeOut = true,
		Music = "Nacimiento",
		Anchors = { Puerta = "Place:PrologoPuerta" },
		Shots = {
			{ From = { "Puerta", V(-12, 4, 12) }, To = { "Puerta", V(-12, 60, 60) }, Look = { "Puerta", V(0, 3, 0) }, LookTo = { "Puerta", V(-70, 70, 0) }, Duration = 14, Easing = "In" },
		},
		Lines = {
			{ At = 0.5, Speaker = "Narrador", TextKey = "CINE.PROLOGO.DESPIERTA" },
		},
		Titles = {
			{ At = 3, TextKey = "CINE.PROLOGO.T_VIDA", SubKey = "CINE.PROLOGO.S_VIDA", Duration = 3.1 },
			{ At = 6.4, TextKey = "CINE.PROLOGO.T_LOCA", SubKey = "CINE.PROLOGO.S_LOCA", Duration = 3.1 },
			{ At = 9.8, TextKey = "CINE.PROLOGO.T_SAGA", SubKey = "CINE.PROLOGO.S_SAGA", Duration = 3.4 },
		},
	},
}

return Cinematics
