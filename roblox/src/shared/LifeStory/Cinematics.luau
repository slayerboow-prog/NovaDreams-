-- Cinematics: las escenas de cámara de los momentos clave de la vida, escritas como datos.
--
--   Anchors  puntos del mundo que usa la escena. El servidor los busca para cada jugador:
--              "Player"            el personaje
--              "Place:Cuna"        un lugar de Locations (su casa, su ventanal, su colegio…)
--              "Zone:Los Pinos"    el centro de una zona
--   Shots    planos de cámara, uno detrás de otro:
--              { From = P, To = P, Look = P, LookTo = P?, Duration, Easing? }   la cámara viaja de From a To mirando a Look
--              { Orbit = "Ancla", Radius, Height, FromAngle, ToAngle, Duration }  gira alrededor de un punto
--            P = { "Ancla", Vector3 offset, Local? }   (Local = el offset va girado con el ancla, p. ej. "delante del ventanal")
--   Lines    subtítulos (con voz): { At = segundo, Speaker = "Abu" | "Familia" | "Narrador" | nil, TextKey }
--   Titles   rótulos grandes: { At, TextKey, SubKey?, Duration? }
--   Music    pieza de Config.Audio.Music que suena durante la escena; Sting = efecto al empezar
--   FadeIn / FadeOut   empieza o acaba en negro
-- Toda escena se puede saltar (botón "Saltar"). La historia avanza igual.

local V = Vector3.new

export type Cinematic = { [string]: any }

local Cinematics: { [string]: Cinematic } = {
	-- El nacimiento: Los Pinos desde el cielo → la casa → la cuna. Abu da la bienvenida.
	Bebe_Nacimiento = {
		Duration = 16,
		FadeIn = true,
		Music = "Nacimiento",
		Anchors = { Casa = "Place:CasaFamiliar", Cuna = "Place:Cuna" },
		Shots = {
			{ From = { "Casa", V(160, 130, 160) }, To = { "Casa", V(55, 38, 55) }, Look = { "Casa", V(0, 0, 0) }, Duration = 6.5 },
			{ From = { "Cuna", V(3, 9, 5) }, To = { "Cuna", V(1.5, 5, 3) }, Look = { "Cuna", V(0, 1, 0) }, Duration = 9.5 },
		},
		Titles = {
			{ At = 0.8, TextKey = "CINE.NACIMIENTO.LUGAR", SubKey = "CINE.NACIMIENTO.CUANDO", Duration = 4.5 },
			{ At = 12.5, TextKey = "CHAPTER.BEBE.TITLE", SubKey = "CHAPTER.BEBE.INTRO", Duration = 3.2 },
		},
		Lines = {
			{ At = 7, Speaker = "Abu", TextKey = "DLG.ABU.NACER.01" },
			{ At = 10, Speaker = "Abu", TextKey = "DLG.ABU.NACER.02" },
		},
	},

	-- ¡Primeros pasos! La cámara da una vuelta alrededor del bebé.
	Bebe_PrimerosPasos = {
		Duration = 6,
		Sting = "PrimerosPasos",
		Anchors = { Bebe = "Player" },
		Shots = {
			{ Orbit = "Bebe", Radius = 7, Height = 2.5, FromAngle = 0, ToAngle = 140, Duration = 6 },
		},
		Lines = {
			{ At = 0.6, Speaker = "Abu", TextKey = "DLG.ABU.BEBE.PASOS" },
		},
		Titles = {
			{ At = 3, TextKey = "MOMENT.PRIMEROS_PASOS", Duration = 2.6 },
		},
	},

	-- Mirar por el ventanal: la cámara sale por la ventana y enseña Valmar.
	Bebe_Ventanal = {
		Duration = 10,
		Music = "TemaValmar",
		Anchors = { Ventana = "Place:Ventanal", Ciudad = "Zone:Valmar Centro", Casa = "Place:CasaFamiliar" },
		Shots = {
			-- (en coordenadas "Local" de Roblox, delante del ventanal es -Z)
			{ From = { "Ventana", V(0, 0.5, 3), true }, To = { "Ventana", V(0, 1, -2), true }, Look = { "Ventana", V(0, 0.5, -30), true }, Duration = 2.5 },
			{ From = { "Ventana", V(0, 1, -2), true }, To = { "Ventana", V(0, 30, -45), true }, Look = { "Ventana", V(0, 0.5, -30), true }, LookTo = { "Ciudad", V(0, 20, 0) }, Duration = 3.5 },
			{ From = { "Ventana", V(0, 30, -45), true }, To = { "Casa", V(0, 170, 0) }, Look = { "Ciudad", V(0, 20, 0) }, Duration = 4 },
		},
		Lines = {
			{ At = 1, Speaker = "Abu", TextKey = "DLG.ABU.BEBE.CIUDAD" },
		},
		Titles = {
			{ At = 6.2, TextKey = "CINE.VALMAR.TITULO", SubKey = "CINE.VALMAR.LEMA", Duration = 3.5 },
		},
	},

	-- Han pasado varios años: la cámara sube desde la casa hasta el cielo.
	Bebe_AnosDespues = {
		Duration = 9,
		FadeOut = true,
		Music = "PasanLosAnos",
		Anchors = { Casa = "Place:CasaFamiliar" },
		Shots = {
			{ From = { "Casa", V(30, 18, 30) }, To = { "Casa", V(10, 260, 60) }, Look = { "Casa", V(0, 0, 0) }, Duration = 9, Easing = "In" },
		},
		Titles = {
			{ At = 1, TextKey = "TRANSITION.ANOS_DESPUES", Duration = 3.5 },
			{ At = 5, TextKey = "CINE.ANOS.RECUERDOS", Duration = 3.5 },
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
			{ From = { "Pinos", V(-180, 90, 120) }, To = { "Pinos", V(-60, 60, 40) }, Look = { "Pinos", V(0, 0, -100) }, Duration = 4.5 },
			{ From = { "Campus", V(-160, 110, 150) }, To = { "Campus", V(-40, 70, 60) }, Look = { "Campus", V(0, 10, 0) }, Duration = 4.5 },
			{ From = { "Financiero", V(200, 60, 160) }, To = { "Financiero", V(80, 160, 60) }, Look = { "Financiero", V(0, 60, 0) }, Duration = 4.5 },
			{ From = { "Centro", V(120, 140, 220) }, To = { "Centro", V(20, 60, 90) }, Look = { "Centro", V(0, 5, 0) }, Duration = 4.5 },
		},
		Titles = {
			{ At = 0.8, TextKey = "CINE.CRECES.COLEGIO", Duration = 3.4 },
			{ At = 5.3, TextKey = "CINE.CRECES.ESTUDIOS", Duration = 3.4 },
			{ At = 9.8, TextKey = "CINE.CRECES.SUENOS", Duration = 3.4 },
			{ At = 14.2, TextKey = "CINE.CRECES.FINAL", Duration = 3.6 },
		},
	},

	-- Primer día de colegio: el colegio desde el cielo y bajada hasta la entrada.
	Nino_PrimerDia = {
		Duration = 10,
		FadeIn = true,
		Music = "TemaValmar",
		Anchors = { Colegio = "Place:Colegio", Entrada = "Place:EntradaColegio" },
		Shots = {
			{ From = { "Colegio", V(-120, 90, 120) }, To = { "Colegio", V(-40, 35, 60) }, Look = { "Colegio", V(0, 5, 0) }, Duration = 5.5 },
			{ Orbit = "Entrada", Radius = 22, Height = 8, FromAngle = 60, ToAngle = 110, Duration = 4.5 },
		},
		Titles = {
			{ At = 1, TextKey = "CHAPTER.NINO.TITLE", SubKey = "CHAPTER.NINO.INTRO", Duration = 4.5 },
		},
		Lines = {
			{ At = 6, Speaker = "Profe", TextKey = "DLG.LUCIA.COLE1.01" },
		},
	},

	-- Primer día de cole: amanece en Los Pinos, la cámara baja hasta tu casa y entra por la ventana.
	Cole01_Amanecer = {
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
			{ Orbit = "Yo", Radius = 11, Height = 3, FromAngle = -40, ToAngle = 40, Duration = 7 },
		},
		Titles = {
			{ At = 2.5, TextKey = "📸 ¡Patata!", SubKey = "Tu grupo de amigos", Duration = 4 },
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
			{ Orbit = "Yo", Radius = 13, Height = 4, FromAngle = 30, ToAngle = -30, Duration = 7 },
		},
		Titles = {
			{ At = 2.5, TextKey = "📸 ¡Todos a decir «vaca»!", SubKey = "La excursión a Villaverde", Duration = 4 },
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
	},

	-- El último día: una foto con tu grupo antes de la ceremonia (misión 12)
	Cole12_Foto = {
		Duration = 7,
		Sting = "Momento",
		Anchors = { Yo = "Player" },
		Shots = {
			{ Orbit = "Yo", Radius = 14, Height = 4, FromAngle = -35, ToAngle = 35, Duration = 7 },
		},
		Titles = {
			{ At = 2.5, TextKey = "📸 Una última foto con tu grupo", SubKey = "Último día de primaria", Duration = 4 },
		},
	},

	-- Fin de primaria: fiesta en el patio, foto de clase.
	Nino_FinPrimaria = {
		Duration = 10,
		Music = "TemaValmar",
		Anchors = { Patio = "Place:Patio", Yo = "Player" },
		Shots = {
			{ Orbit = "Yo", Radius = 12, Height = 5, FromAngle = 0, ToAngle = 90, Duration = 5 },
			{ From = { "Patio", V(0, 12, 30) }, To = { "Patio", V(0, 40, 60) }, Look = { "Patio", V(0, 2, 0) }, Duration = 5 },
		},
		Lines = {
			{ At = 0.8, Speaker = "Profe", TextKey = "DLG.LUCIA.GRADUA.01" },
		},
		Titles = {
			{ At = 5.5, TextKey = "CINE.FIN_PRIMARIA.TITULO", SubKey = "CINE.FIN_PRIMARIA.FOTO", Duration = 4 },
		},
	},

	-- De niño a adolescente: vuelo de Los Pinos al Campus Valmar (el instituto).
	Nino_AInstituto = {
		Duration = 10,
		FadeOut = true,
		Music = "PasanLosAnos",
		Anchors = { Pinos = "Zone:Los Pinos", Campus = "Zone:Campus Valmar" },
		Shots = {
			{ From = { "Pinos", V(-150, 80, 60) }, To = { "Pinos", V(0, 180, -300) }, Look = { "Pinos", V(0, 0, -150) }, Duration = 5 },
			{ From = { "Campus", V(-200, 150, 150) }, To = { "Campus", V(-60, 60, 60) }, Look = { "Campus", V(0, 10, 0) }, Duration = 5 },
		},
		Titles = {
			{ At = 0.8, TextKey = "TRANSITION.INSTITUTO", Duration = 4 },
			{ At = 5.3, TextKey = "CINE.INSTITUTO.LLEGA", Duration = 4 },
		},
	},

	-- Del instituto a los 18: elegir camino.
	Adol_Selectividad = {
		Duration = 10,
		FadeOut = true,
		Music = "PasanLosAnos",
		Anchors = { Campus = "Zone:Campus Valmar", Centro = "Zone:Valmar Centro" },
		Shots = {
			{ Orbit = "Campus", Radius = 180, Height = 90, FromAngle = 120, ToAngle = 170, Duration = 5 },
			{ From = { "Centro", V(150, 120, 200) }, To = { "Centro", V(40, 50, 80) }, Look = { "Centro", V(0, 5, 0) }, Duration = 5 },
		},
		Titles = {
			{ At = 0.8, TextKey = "CINE.SELECTIVIDAD.ANOS", Duration = 4 },
			{ At = 5.3, TextKey = "TRANSITION.MAYOR_EDAD", Duration = 4 },
		},
	},

	-- Primer día de universidad: el campus y la rectora.
	Uni_PrimerDia = {
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
		Duration = 9,
		Sting = "Momento",
		Music = "TemaValmar",
		Anchors = { Yo = "Player" },
		Shots = {
			{ Orbit = "Yo", Radius = 10, Height = 3, FromAngle = 160, ToAngle = 200, Duration = 5 },
			{ Orbit = "Yo", Radius = 24, Height = 8, FromAngle = 200, ToAngle = 230, Duration = 4 },
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
			{ Orbit = "Yo", Radius = 13, Height = 4, FromAngle = -30, ToAngle = 30, Duration = 7 },
		},
		Titles = {
			{ At = 2.5, TextKey = "📸 Todos otra vez", SubKey = "La Cafetería de Omar", Duration = 4 },
		},
	},

	Uni_Graduacion = {
		Duration = 13,
		Music = "TemaValmar",
		Anchors = { Yo = "Player", Uni = "Place:Universidad" },
		Shots = {
			{ Orbit = "Yo", Radius = 10, Height = 3, FromAngle = 30, ToAngle = 150, Duration = 7 },
			{ From = { "Yo", V(8, 6, 8) }, To = { "Uni", V(40, 60, 90) }, Look = { "Yo", V(0, 2, 0) }, LookTo = { "Uni", V(0, 10, 0) }, Duration = 6 },
		},
		Lines = {
			{ At = 0.8, Speaker = "Rectora", TextKey = "DLG.AMAIA.GRADUA.01" },
		},
		Titles = {
			{ At = 7.5, TextKey = "CINE.GRADUACION.TITULO", SubKey = "CINE.GRADUACION.SUB", Duration = 5 },
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
			{ At = 7.8, Speaker = "Narrador", TextKey = "CINE.LLEGADA.NARRADOR" },
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
}

return Cinematics
