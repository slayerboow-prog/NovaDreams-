-- GUION REESCRITO de Cole09_Misterio (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Cole09_Misterio.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Cole09_Misterio
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Cole09_Misterio.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Cole09_Misterio.md",
	Dialogues = {
		Capsula = {
			Lines = {
				{ S = "Lucia", T = "Abrir el último día de colegio.", To = "Yo", Effects = { Scene = "Cole09_G19_Musica" } },
				{ S = "Sara", T = "Lo he apuntado tres veces.", To = "Yo" },
				{ S = "Omar", T = "Yo lo he apuntado en mi cabeza.", To = "Yo" },
				{ S = "Omar", T = "Creo.", To = "Yo", Pause = 0.9 },
				{ S = "Lucia", T = "Algún día mirarás esta foto y te parecerá que fue ayer.", To = "Yo", Pause = 0.9 },
			},
		},
		Codigo = {
			Lines = {
				{ S = "Sara", T = "Inserto.", To = "Yo", Effects = { Scene = "Cole09_G7_Musica" } },
				{ S = "Omar", T = "Abrir.", To = "Yo" },
				{ S = "Iker", T = "Beat.", To = "Yo", If = { Flags = { "IkerEnElGrupo" } } },
			},
		},
		Dentro = {
			Lines = {
				{ S = "Sara", T = "No es un laboratorio.", To = "Yo", Effects = { Scene = "Cole09_G11_Musica" } },
				{ S = "Sara", T = "Un aula de hace muchísimos años.", To = "Yo", Pause = 0.9 },
				{ S = "Ramon", T = "Antes de la reforma.", To = "Yo", If = { Choices = { Entrar = "Permiso" } } },
				{ S = "Ramon", T = "Aquí estudiaban los niños de 1998.", To = "Yo", Pause = 0.9, If = { Choices = { Entrar = "Permiso" } } },
			},
		},
		Dentro_Caja = { Lines = { { S = "Omar", T = "Como adultos.", To = "Yo", Pause = 0.9 } } },
		Dentro_Pupitre = { Lines = { { S = "Omar", T = "Lo tenía decidido.", To = "Yo" } } },
		Dentro_Trofeos = { Lines = { { S = "Nico", T = "Este nos pega.", To = "Yo" }, { S = "Nico", T = "Solo nos falta ganar algo.", To = "Yo" } } },
		LaFoto = {
			Lines = {
				{ S = "Ramon", T = "¡Ajá!", To = "Yo", If = { Choices = { Entrar = "Colarse" } } },
				{ S = "Ramon", T = "Ah.", To = "Yo", Pause = 0.9, If = { Choices = { Entrar = "Colarse" } } },
				{ S = "Ramon", T = "Sí.", To = "Yo", If = { Choices = { Entrar = "Colarse" } } },
				{ S = "Ramon", T = "Sí.", To = "Yo", Pause = 0.9, If = { Choices = { Entrar = "Permiso" } } },
				{ If = { Choices = { Entrar = "Colarse" } }, Effects = { Rel = { Ramon = -2 } } },
			},
		},
		Lucia_Foto = {
			Lines = {
				{ S = "Lucia", T = "¿Qué traéis ahí?", To = "Yo", Effects = { Scene = "Cole09_G17_Musica" } },
				{ S = "Lucia", T = "¿De dónde habéis sacado esto?", To = "Yo", Pause = 0.9 },
				{ S = "Lucia", T = "Esa soy yo.", To = "Yo" },
				{ S = "Lucia", T = "Y ahora quiero saber cómo habéis entrado.", To = "Yo", Pause = 0.9, If = { Choices = { Entrar = "Colarse" } } },
				{ S = "Lucia", T = "¿Ramón os ha ayudado?", To = "Yo", Pause = 0.9, If = { Choices = { Entrar = "Permiso" } } },
				{ S = "Lucia", T = "Esa nota también la escribí yo.", To = "Yo", If = { Choices = { Entrar = "Permiso" } } },
				{ S = "Lucia", T = "Esa taquilla era mía.", To = "Yo", If = { Choices = { Entrar = "Permiso" } } },
				{
					S = "Lucia",
					T = "Nosotros escondimos la sala para proteger nuestra cápsula del tiempo.",
					To = "Yo",
					If = { Choices = { Entrar = "Permiso" } },
				},
				{
					S = "Lucia",
					T = "Supongo que algunas cosas esperan a que volvamos a encontrarlas.",
					To = "Yo",
					Pause = 0.9,
					If = { Choices = { Entrar = "Permiso" } },
				},
				{ S = "Lucia", T = "DECISIÓN · ¿QUÉ HACER CON LA FOTO?", To = "Yo" },
				{ S = "Lucia", T = "Tengo una idea.", To = "Yo" },
				{ S = "Lucia", T = "Mañana abriremos la cápsula de mi clase.", To = "Yo", Pause = 0.9 },
				{ S = "Lucia", T = "Y vosotros dejaréis una nueva.", To = "Yo" },
				{ S = "Omar", T = "¿De verdad?", To = "Yo" },
				{ S = "Lucia", T = "De verdad.", To = "Yo" },
				{ S = "Lucia", T = "Esta vez no se me olvida.", To = "Yo" },
				{
					Ask = "¿Qué haces con la foto?",
					Options = {
						{
							T = "Devolvérsela: «Es tuya. Te la hemos traído.»",
							Effects = { Choice = { FotoLucia = "Devolver" }, Rel = { Lucia = 10 }, Traits = { Empatia = 1 } },
							Then = { { S = "Lucia", T = "Gracias. De verdad. Os voy a hacer una copia a cada uno. Esta la pongo en mi mesa." } },
						},
						{
							T = "Enseñársela a toda la clase",
							Effects = { Choice = { FotoLucia = "Clase" }, Rel = { Lucia = 5, Nico = 3 }, Traits = { Humor = 1 } },
							Then = {
								{ S = "Nico", T = "¡ATENCIÓN TODOS! ¡LUCÍA CON COLETAS!" },
								{ S = "Lucia", T = "¡Nico! …Vale, vale. Sí. Era yo. Y era la mejor de la clase en ciencias, que conste." },
							},
						},
						{
							T = "Guardar el secreto: «No se lo diremos a nadie»",
							Effects = { Choice = { FotoLucia = "Secreto" }, Flags = { "SecretoLucia" }, Rel = { Lucia = 8 }, Traits = { Responsabilidad = 1 } },
							Then = { { S = "Lucia", T = "¿Un secreto entre nosotros? Me parece perfecto. Tomad una copia cada uno. Y ni una palabra de las coletas." } },
						},
					},
				},
			},
		},
		Nota = { Lines = { { S = "Omar", T = "Vale.", To = "Yo", Pause = 0.9 } } },
		Permiso_Ramon = {
			Lines = {
				{ S = "Ramon", T = "Por fin alguien pregunta.", To = "Yo", Pause = 0.9 },
				{ S = "Ramon", T = "Os doy permiso.", To = "Yo" },
				{ S = "Ramon", T = "Pero el código lo descubrís vosotros.", To = "Yo" },
			},
		},
		Pista_Anuario = {
			Lines = {
				{ S = "Marisa", T = "¿El anuario de 1998?", To = "Yo" },
				{ S = "Lucia", T = "¿Lucía?", To = "Yo" },
				{ S = "Lucia", T = "¿Nuestra Lucía?", To = "Yo" },
			},
		},
		Pista_Llaves = {
			Lines = {
				{ S = "Ramon", T = "Una pequeña llave oxidada.", To = "Yo" },
				{ S = "Ramon", T = "Esa no.", To = "Yo" },
				{ S = "Ramon", T = "Me la dio una niña hace muchos años.", To = "Yo", Pause = 0.9 },
				{ S = "Ramon", T = "Y me hizo prometer que la guardaría.", To = "Yo" },
				{ S = "Ramon", T = "Y yo cumplo mis promesas.", To = "Yo" },
			},
		},
		Pista_Trofeo = { Lines = { { S = "Omar", T = "¡1998!", To = "Yo" }, { S = "Omar", T = "Ese es nuestro año.", To = "Yo" } } },
		Rumores = {
			Lines = {
				{ S = "Nico", T = "Es un fantasma.", To = "Yo", Effects = { Scene = "Cole09_G3_Musica" } },
				{ S = "Yo", T = "¿Qué?" },
				{ S = "Sara", T = "Eso es físicamente absurdo.", To = "Yo" },
				{ S = "Nico", T = "¿Y cómo sabes que no?", To = "Yo" },
				{ S = "Sara", T = "Porque los fantasmas no existen.", To = "Yo" },
				{ S = "Nico", T = "¿Bocadillos?", To = "Yo" },
				{ S = "Omar", T = "Muchos.", To = "Yo" },
				{ S = "Omar", T = "Una sala entera.", To = "Yo" },
				{ S = "Mateo", T = "En mi otro cole había una sala parecida.", To = "Yo", Pause = 0.9, If = { Flags = { "AyudasteAMateo" } } },
				{ S = "Hugo", T = "En un libro que leí, detrás de una puerta así había un pasadizo.", To = "Yo", If = { Flags = { "HugoConElGrupo" } } },
				{ S = "Nico", T = "¿A dónde?", To = "Yo", If = { Flags = { "HugoConElGrupo" } } },
				{ S = "Hugo", T = "Al otro lado del mundo.", To = "Yo", If = { Flags = { "HugoConElGrupo" } } },
				{ S = "Omar", T = "Espero que haya bocadillos.", To = "Yo", If = { Flags = { "HugoConElGrupo" } } },
				{ S = "Omar", T = "Voy a por mi almuerzo.", To = "Yo", If = { Flags = { "HugoConElGrupo" } } },
				{ S = "Omar", T = "Te mira.", To = "Yo", If = { Flags = { "HugoConElGrupo" } } },
			},
		},
		TrasNota = {
			Lines = {
				{ S = "Omar", T = "¿Ya?", To = "Yo", Effects = { Scene = "Cole09_G5_Musica" } },
				{ S = "Iker", T = "Ya.", To = "Yo" },
				{ S = "Sara", T = "Tenemos tres pistas.", To = "Yo" },
				{ S = "Omar", T = "Entonces tenemos un misterio.", To = "Yo" },
				{ S = "Omar", T = "Detectives alumnos.", To = "Yo" },
				{ S = "Sara", T = "Me sirve.", To = "Yo" },
			},
		},
	},
	Scenes = {
		Cole09_G10_Entra = {
			Light = true,
			Duration = 21.7,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Omar", Npc = "Omar" } },
					{ At = 0, Use = { Key = "Nico", Npc = "Nico" } },
					{ At = 0, Use = { Key = "Sara", Npc = "Sara" } },
				},
				Dialogue = {
					{ At = 0.4, S = "Sara", T = "Primero decía el año.", To = "Yo" },
					{ At = 4.5, S = "Nico", T = "Si sale un fantasma…", To = "Yo" },
					{ At = 6.8, S = "Nico", T = "Me pongo detrás de ti.", To = "Yo" },
					{ At = 9.1, S = "Omar", T = "Yo me pongo detrás de {nombre}.", To = "Yo" },
					{ At = 12, S = "Sara", T = "Vamos.", To = "Yo" },
					{ At = 14, S = "Omar", T = "¿Qué número tenía la llave?", To = "Yo" },
					{ At = 16.7, S = "Nico", T = "¡Era una posibilidad!", To = "Yo" },
					{ At = 19, S = "Sara", T = "No.", To = "Yo" },
				},
			},
		},
		Cole09_G11_Musica = {
			Light = true,
			Duration = 13.9,
			Anchors = { Yo = "Player" },
			Tracks = { Music = { { At = 0, Intensity = "Tension" }, { At = 6.9, Intensity = "Descubrimiento" } } },
		},
		Cole09_G17_Musica = { Light = true, Duration = 52.8, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
		Cole09_G18_Entra = {
			Light = true,
			Duration = 19.3,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Omar", Npc = "Omar" } },
					{ At = 0, Use = { Key = "Nico", Npc = "Nico" } },
					{ At = 0, Use = { Key = "Sara", Npc = "Sara" } },
				},
				Dialogue = {
					{ At = 0.4, S = "Omar", T = "Para que sepamos que estuvimos aquí.", To = "Yo" },
					{ At = 3.5, S = "Omar", T = "Nico será futbolista.", To = "Yo" },
					{ At = 5.8, S = "Nico", T = "¿Lo has escrito de verdad?", To = "Yo" },
					{ At = 9.3, S = "Sara", T = "Es una buena pregunta.", To = "Yo" },
					{ At = 11.7, S = "Omar", T = "Yo espero que sí.", To = "Yo" },
					{ At = 13.8, S = "Nico", T = "Pues claro.", To = "Yo" },
					{ At = 15.8, S = "Nico", T = "¿Quién va a dejar de ser amigo?", To = "Yo" },
				},
			},
		},
		Cole09_G19_Musica = {
			Light = true,
			Duration = 18.3,
			Anchors = { Yo = "Player" },
			Tracks = { Music = { { At = 0, Intensity = "Intima" }, { At = 9.1, Intensity = "Descubrimiento" } } },
		},
		Cole09_G1_Fin = {
			Light = true,
			Duration = 5.8,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Dialogue = { { At = 0.4, S = "Narrador", T = "Unos días después del torneo, el colegio volvió a parecer normal." } },
				Music = { { At = 0, Intensity = "Descubrimiento" }, { At = 2.6, Intensity = "Tension" } },
			},
		},
		Cole09_G3_Musica = {
			Light = true,
			Duration = 44.9,
			Anchors = { Yo = "Player" },
			Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" }, { At = 22.4, Intensity = "Tension" } } },
		},
		Cole09_G5_Musica = { Light = true, Duration = 17.4, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Cole09_G7_Musica = { Light = true, Duration = 9.2, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Cole09_G8_Entra = {
			Light = true,
			Duration = 10.5,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Sara", Npc = "Sara" } }, { At = 0, Use = { Key = "Omar", Npc = "Omar" } } },
				Dialogue = {
					{ At = 0.4, S = "Omar", T = "Si nos pillan, yo solo venía a buscar mi almuerzo.", To = "Yo" },
					{ At = 4.3, S = "Sara", T = "Llevas el almuerzo en la mano.", To = "Yo" },
					{ At = 7.1, S = "Omar", T = "Entonces venía a buscar otro.", To = "Yo" },
				},
			},
		},
		Cole09_G9_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Omar", Npc = "Omar" } } },
				Dialogue = {
					{ At = 0.4, S = "Omar", T = "Si eligió permiso, Ramón llega detrás.", To = "Yo" },
					{ At = 3.6, S = "Omar", T = "Si eligió colarse, el pasillo permanece vacío.", To = "Yo" },
				},
			},
		},
		Cole09_LaFoto = {
			Skippable = true,
			Duration = 23.9,
			Anchors = {
				Foto = { Ground = true, Offset = V(5.2, 0, -0.3), Place = "SalaCerrada" },
				Sala = "Place:SalaCerrada",
				Sitio = "Place:SalaCerrada",
				Yo = "Player",
			},
			Tracks = {
				Light = { { At = 6.6, Fade = 0.8, Preset = "Recuerdo" }, { At = 15.4, Fade = 0.8, Preset = false } },
				Actors = {
					{ At = 0, Use = { Key = "Sara", Npc = "Sara" } },
					{ At = 0, Use = { Key = "Omar", Npc = "Omar" } },
					{ At = 0, Use = { Key = "Nico", Npc = "Nico" } },
					{ At = 0, If = { Flags = { "IkerEnElGrupo" } }, Use = { Key = "Iker", Npc = "Iker" } },
					{ At = 0, If = { Choices = { Entrar = "Permiso" } }, Use = { Key = "Ramon", Npc = "Ramon" } },
					{ At = 0.2, Look = { At = "Foto", Key = "Sara" } },
					{ At = 2.6, Mood = { Mood = "Surprise", Key = "Sara" } },
					{ At = 3.4, Look = { At = "Foto", Key = "Omar" } },
					{ At = 3.6, Look = { At = "Foto", Key = "Nico" } },
					{ At = 3.6, If = { Flags = { "IkerEnElGrupo" } }, Look = { At = "Foto", Key = "Iker" } },
					{ At = 3.8, If = { Choices = { Entrar = "Permiso" } }, Look = { At = "Foto", Key = "Ramon" } },
					{ At = 15.4, Look = { At = "Speaker", Key = "Sara" } },
					{ At = 15.4, Look = { At = "Speaker", Key = "Omar" } },
					{ At = 15.4, Look = { At = "Speaker", Key = "Nico" } },
					{ At = 15.4, If = { Flags = { "IkerEnElGrupo" } }, Look = { At = "Speaker", Key = "Iker" } },
					{ At = 15.5, Mood = { Mood = "Joy", Key = "Nico" } },
					{ At = 15.5, Mood = { Mood = "Sad", Key = "Ramon" }, If = { Choices = { Entrar = "Permiso" } } },
				},
				Ambience = { { At = 0, Kind = "Colegio" } },
				Camera = {
					{ At = 0, Duration = 2.6, To = { "Sala", V(-3.8, 3.8, 2) }, Fov = 62, From = { "Sala", V(-4.5, 4.2, 2.4) }, Look = { "Foto", V(0, 1.4, 0) } },
					{ At = 5.2, Duration = 1.4, Shot = "Hombro:Yo>Foto" },
					{
						At = 6.6,
						Duration = 8.8,
						To = { "Foto", V(0.8, 1.6, 1) },
						Cut = "Dip",
						Fov = { 42, 32 },
						From = { "Foto", V(1.4, 1.8, 1.6) },
						Look = { "Foto", V(0, 1.4, 0) },
					},
				},
				Dialogue = {
					{ At = 0.4, S = "Sara", T = "No habla inmediatamente.", To = "Yo" },
					{ At = 2.9, S = "Sara", T = "Esperad.", To = "Yo" },
					{ At = 5.8, S = "Sara", T = "Esa es…", To = "Yo" },
					{ At = 7.9, S = "Lucia", T = "Plano 5 — Hombro", To = "Yo" },
					{ At = 9.9, S = "Sara", T = "¡Es nuestra Lucía!", To = "Yo" },
					{ At = 12.1, S = "Omar", T = "¿Con coletas?", To = "Yo" },
					{ At = 14.1, S = "Nico", T = "¡L de Lucía!", To = "Yo" },
					{ At = 17.1, S = "Nico", T = "¡Lo sabía!", To = "Yo" },
					{ At = 19.1, S = "Nico", T = "Bueno…", To = "Yo" },
					{ At = 21.2, S = "Iker", T = "Dato curioso.", To = "Yo", If = { Flags = { "IkerEnElGrupo" } } },
				},
				Music = { { At = 0, Intensity = "Intima" } },
			},
		},
	},
	Steps = {
		["1"] = { Effects = { Scene = "Cole09_G1_Fin" }, Set = { Text = "Unos días después del torneo…" } },
		["10"] = { Set = { Text = "¿Qué código pruebas?" } },
		["12"] = { Set = { Text = "Explora la sala" } },
		["13"] = { Set = { Text = "En la pared hay una foto enmarcada" } },
		["16"] = { Set = { Text = "Busca a Lucía en clase" } },
		["17"] = { Effects = { Scene = "Cole09_G18_Entra" } },
		["18"] = { Set = { Text = "¿Qué metes en la cápsula del tiempo?" } },
		["2"] = { Set = { Text = "Sal al recreo: tus amigos no hablan de otra cosa" } },
		["4"] = { Set = { Text = "Vuelve a tu taquilla a por el almuerzo" } },
		["6"] = { Set = { Text = "Investiga el misterio" } },
		["7"] = { Effects = { Scene = "Cole09_G8_Entra" } },
		["8"] = { Effects = { Scene = "Cole09_G9_Entra" }, Set = { Text = "¿Pides permiso o te cuelas?" } },
		["9"] = { Effects = { Scene = "Cole09_G10_Entra" }, Set = { Text = "Ve a la puerta del fondo del pasillo" } },
	},
}
