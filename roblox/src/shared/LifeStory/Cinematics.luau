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
