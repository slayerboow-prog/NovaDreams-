-- GUION REESCRITO de Cole07_Excursion (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Cole07_Excursion.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Cole07_Excursion
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Cole07_Excursion.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Cole07_Excursion.md",
	Dialogues = {
		Act_Caballos = {
			Lines = {
				{ S = "Yo", T = "¡Hace cosquillas!", Shot = "General" },
				{ S = "Omar", T = "Lo voy a dibujar. Tiene cara de llamarse Galleta.", To = "Yo" },
				{ S = "Yo", T = "¿Por qué Galleta?" },
				{ S = "Omar", T = "No sé. Pero míralo.", To = "Yo" },
			},
		},
		Act_Gallinas = {
			Lines = {
				{ S = "Paula", T = "Estas son Clotilde, Remedios y la Señora Bigotes.", To = "Yo", Shot = "General" },
				{ S = "Yo", T = "¿Tiene bigotes?", Pause = 0.9 },
				{ S = "Paula", T = "No. Se lo pusimos por fastidiar. Échalo cerca. No encima.", To = "Yo" },
				{ S = "Yo", T = "¡Eh!", Shot = "Reaccion:Yo" },
				{ S = "Paula", T = "Te ha elegido.", To = "Yo" },
			},
		},
		Act_Huerto = {
			Lines = {
				{ S = "Nico", T = "¡Eso es gigante!", To = "Yo", Shot = "Reaccion:Yo", Pause = 0.9 },
				{ S = "Sara", T = "Técnicamente, es una raíz.", To = "Yo" },
				{ S = "Sara", T = "Pero es una raíz impresionante.", To = "Yo", Pause = 0.9 },
				{ S = "Omar", T = "Eso da para cuatro bocadillos.", To = "Yo" },
			},
		},
		Act_Tractor = {
			Lines = {
				{ S = "Julian", T = "¿Quieres subir?", To = "Yo", Shot = "General" },
				{ S = "Yo", T = "Sí." },
				{ S = "Julian", T = "Arriba. Manos en el volante. ¡Brrrrum! Sin arrancar.", To = "Yo" },
				{ S = "Nico", T = "¡Hazme una foto!", To = "Yo" },
				{ S = "Nico", T = "¡Hazme una foto!", To = "Yo", Shot = "Reaccion:Nico" },
			},
		},
		Bus_Hugo = {
			Lines = {
				{ S = "Hugo", T = "¿Conmigo?", To = "Yo" },
				{ S = "Yo", T = "Sí." },
				{ S = "Hugo", T = "Antes siempre me sentaba donde decía Bruno. Esto está mejor.", To = "Yo" },
				{ S = "Hugo", T = "¿Quieres que te enseñe una parte?", To = "Yo" },
			},
		},
		Bus_Mateo = {
			Lines = {
				{ S = "Mateo", T = "Nunca he ido de excursión.", To = "Yo" },
				{ S = "Mateo", T = "En mi otro cole no íbamos. Estoy contento.", To = "Yo", Pause = 0.9 },
				{ S = "Mateo", T = "Y un poco nervios{o/a}.", To = "Yo", Pause = 0.9 },
				{ S = "Yo", T = "Yo también." },
			},
		},
		Bus_Nico = {
			Lines = {
				{ S = "Nico", T = "¡Bien! Tengo un juego.", To = "Yo" },
				{ S = "Yo", T = "¿Cuál?" },
				{ S = "Nico", T = "El que vea más vacas gana. ¡Una! ¡Dos!", To = "Yo" },
				{ S = "Yo", T = "Llevamos diez segundos." },
				{ S = "Nico", T = "Por eso voy ganando.", To = "Yo" },
			},
		},
		Bus_Omar = {
			Lines = {
				{ S = "Omar", T = "Te he guardado medio bocadillo. Bueno… Un cuarto.", To = "Yo" },
				{ S = "Yo", T = "¿Qué ha pasado con el otro cuarto?" },
				{ S = "Omar", T = "Ha sido una emergencia.", To = "Yo" },
			},
		},
		Bus_Sara = {
			Lines = {
				{ S = "Sara", T = "He preparad{o/a} una lista de las plantas que podemos encontrar.", To = "Yo" },
				{ S = "Yo", T = "¿Has traído una lupa?" },
				{ S = "Sara", T = "Dos. Por si una falla.", To = "Yo" },
			},
		},
		Encontrado = {
			Lines = {
				{
					S = "Mateo",
					T = "¡{nombre}! Se había escapado y… Lo seguí.",
					To = "Yo",
					Shot = "General",
					If = { Flags = { "AyudasteAMateo" } },
					Effects = { Scene = "Cole07_G13_Musica" },
				},
				{ S = "Mateo", T = "Y luego no sabía volver. Todo se parece.", To = "Yo", Pause = 0.9, If = { Flags = { "AyudasteAMateo" } } },
				{ S = "Omar", T = "¡{nombre}! Lo estaba dibujando. Se movió.", To = "Yo", If = { NotFlags = { "AyudasteAMateo" } } },
				{
					S = "Omar",
					T = "Y lo seguí para terminar el dibujo. Y luego… No sabía volver.",
					To = "Yo",
					Pause = 0.9,
					If = { NotFlags = { "AyudasteAMateo" } },
				},
				{ S = "Narrador", T = "El susto empieza a convertirse en alivio.", Shot = "PrimerPlano:Yo" },
				{
					Ask = "¿Qué haces?",
					Options = {
						{
							T = "«Le das la mano y volvéis juntos»",
							Effects = { Choice = { Rescate = "Juntos" }, Rel = { Mateo = 8, Omar = 8 }, Traits = { Empatia = 1 } },
							Then = {
								{ S = "Yo", T = "Venga. Volvemos juntos.", Shot = "Medio:Yo" },
								{ S = "Narrador", T = "Volvéis por el camino." },
								{ S = "Yo", T = "Creo que él también sabe volver.", Shot = "General" },
							},
						},
						{
							T = "«Te quedas con él y mandas a Nico a avisar a Lucía»",
							Effects = { Choice = { Rescate = "Avisar" }, Rel = { Lucia = 3, Mateo = 5, Omar = 5 }, Traits = { Responsabilidad = 1 } },
							Then = {
								{ S = "Yo", T = "Quédate aquí. Nico, avisa a Lucía." },
								{ S = "Nico", T = "¡Voy! ¡Soy el más rápido! ¡Bueno! ¡Casi!", To = "Yo" },
								{ S = "Mateo", T = "Gracias por quedarte.", To = "Yo", Shot = "PrimerPlano:Mateo", If = { Flags = { "AyudasteAMateo" } } },
								{ S = "Omar", T = "Gracias por quedarte.", To = "Yo", If = { NotFlags = { "AyudasteAMateo" } } },
								{ S = "Yo", T = "No iba a dejarte solo." },
								{ S = "Mateo", T = "Gracias.", To = "Yo", Pause = 0.9, If = { Flags = { "AyudasteAMateo" } } },
								{ S = "Omar", T = "Gracias.", To = "Yo", If = { NotFlags = { "AyudasteAMateo" } } },
							},
						},
					},
				},
			},
		},
		Falta = {
			Lines = {
				{ S = "Lucia", T = "A ver… Uno. Dos.", To = "Yo", Shot = "General", Effects = { Scene = "Cole07_G10_Musica" } },
				{ S = "Lucia", T = "Un momento.", To = "Yo", Shot = "PrimerPlano:Lucia", Pause = 0.9 },
				{ S = "Lucia", T = "Falta Mateo.", To = "Yo", If = { Flags = { "AyudasteAMateo" } } },
				{ S = "Lucia", T = "Falta Omar.", To = "Yo", Shot = "Reaccion:Yo", If = { NotFlags = { "AyudasteAMateo" } } },
				{ S = "Paula", T = "Tranquilidad. Suele pasar.", To = "Yo", Shot = "Reaccion:Yo" },
				{ S = "Paula", T = "Alguien ve algo bonito y se despista.", To = "Yo" },
				{ S = "Lucia", T = "{nombre}.", To = "Yo" },
				{ S = "Lucia", T = "Tú y tus amigos, mirad por la zona del granero y el silo.", To = "Yo", Shot = "Hombro:Yo>Lucia" },
				{ S = "Lucia", T = "Sin alejaros de la granja.", To = "Yo", Pause = 0.9 },
				{ S = "Yo", T = "Vale." },
			},
		},
		Julian = {
			Lines = {
				{ S = "Yo", T = "¿Has visto a alguien?" },
				{ S = "Julian", T = "¿Un chaval? Sí. Iba detrás de Copito.", To = "Yo" },
				{ S = "Yo", T = "¿Copito?" },
				{ S = "Julian", T = "El corderito que siempre se escapa.", To = "Yo" },
				{ S = "Julian", T = "Siempre acaba detrás del granero.", To = "Yo" },
				{ S = "Julian", T = "Allí crece la hierba buena.", To = "Yo" },
				{ S = "Yo", T = "Gracias." },
				{ S = "Julian", T = "Y esta vez intentad que Copito no os lleve de excursión a vosotros.", To = "Yo" },
			},
		},
		Llegada = {
			Lines = {
				{ S = "Paula", T = "¡Bienvenidos a la Granja Escuela!", To = "Yo", Effects = { Scene = "Cole07_G7_Musica" } },
				{ S = "Paula", T = "Soy Paula.", To = "Yo", Shot = "Medio:Paula" },
				{ S = "Paula", T = "Aquí tenemos gallinas, caballos, un huerto y un tractor. Y una norma de oro.", To = "Yo", Shot = "General" },
				{ S = "Paula", T = "Nadie se separa del grupo.", To = "Yo" },
				{ S = "Paula", T = "El campo es grande y algunas zonas se parecen mucho.", To = "Yo", Shot = "PrimerPlano:Paula" },
				{ S = "Lucia", T = "Así que siempre a la vista.", To = "Yo" },
				{ S = "Paula", T = "Exactamente. Podéis explorar. Pero juntos.", To = "Yo" },
				{ S = "Bruno", T = "Huele a caca de vaca.", To = "Yo" },
				{ S = "Paula", T = "Huele a campo, jovencito. Y son caballos.", To = "Yo" },
				{ S = "Bruno", T = "Eso explica muchas cosas.", To = "Yo", Shot = "Reaccion:Bruno" },
			},
		},
		Pista_Botella = {
			Lines = {
				{ S = "Narrador", T = "Una botella medio vacía.", Shot = "General" },
				{ S = "Narrador", T = "Huellas pequeñas. Y otras todavía más pequeñas. De pezuñas.", Shot = "General" },
			},
		},
		Pista_Mapa = { Lines = { { S = "Narrador", T = "«¡Le sigo!»", Shot = "General" }, { S = "Yo", T = "Creo que sé dónde ha ido.", Shot = "PrimerPlano:Yo" } } },
		Pista_Mochila = {
			Lines = {
				{ S = "Narrador", T = "Una mochila llena de cromos. Es la de Mateo.", Shot = "General", If = { Flags = { "AyudasteAMateo" } } },
				{ S = "Narrador", T = "Un cuaderno de dibujo.", If = { NotFlags = { "AyudasteAMateo" } } },
				{ S = "Narrador", T = "Y unas migas de bocadillo.", If = { NotFlags = { "AyudasteAMateo" } } },
				{ S = "Narrador", T = "Es la mochila de Omar.", If = { NotFlags = { "AyudasteAMateo" } } },
			},
		},
		Reunion = {
			Lines = {
				{ S = "Lucia", T = "¡Aquí estáis!", To = "Yo", Shot = "Seguir:Lucia", Effects = { Scene = "Cole07_G14_Musica" } },
				{ S = "Lucia", T = "Menudo susto. Pero estáis bien. Buen trabajo, equipo.", To = "Yo", Shot = "PrimerPlano:Lucia" },
				{ S = "Lucia", T = "Buen trabajo de verdad.", To = "Yo" },
				{ S = "Paula", T = "Y tú… A tu corral. Eres un fugitivo profesional.", To = "Yo" },
				{ S = "Nico", T = "Yo le contrataría. Como mascota.", To = "Yo", Shot = "Reaccion:Nico" },
				{ S = "Lucia", T = "Antes de volver. Foto de grupo. Bruno.", To = "Yo" },
				{ S = "Lucia", T = "Sin cuernos con los dedos.", To = "Yo" },
				{ S = "Bruno", T = "¡Pero si todavía no los estaba haciendo!", To = "Yo" },
				{ S = "Lucia", T = "Precisamente.", To = "Yo" },
			},
		},
		Salida = {
			Lines = {
				{
					S = "Lucia",
					T = "¡Todos arriba! Y contad cuántos sois en vuestra fila.",
					To = "Yo",
					Shot = "General",
					Effects = { Scene = "Cole07_G3_Musica" },
				},
				{ S = "Lucia", T = "Y nadie se deja nada en el autobús. ¿De acuerdo?", To = "Yo", Shot = "Medio:Lucia" },
				{ S = "Narrador", T = "Todos: «¡Sí!»" },
				{ S = "Nico", T = "¡{nombre}! ¡Aquí hay sitio!", To = "Yo", Shot = "Reaccion:Nico" },
				{ S = "Nico", T = "¡Rápido antes de que alguien me lo quite!", To = "Yo", Shot = "DosPlanos:Yo,Nico" },
				{ S = "Sara", T = "Yo tengo la ventana. Puedo compartirla. A ratos.", To = "Yo" },
				{ S = "Nico", T = "Eso no es compartir.", To = "Yo" },
				{ S = "Sara", T = "Es compartir científicamente.", To = "Yo" },
				{ S = "Narrador", T = "Busca con quién sentarte." },
			},
		},
		Viaje = {
			Lines = {
				{ S = "Narrador", T = "El autobús salió de Valmar.", Shot = "General", Effects = { Scene = "Cole07_G5_Musica" } },
				{ S = "Omar", T = "Ya me he comido el bocadillo.", To = "Yo", Shot = "General" },
				{ S = "Omar", T = "Estamos en el primer kilómetro.", To = "Yo", Pause = 0.9 },
				{ S = "Sara", T = "Técnicamente, en el kilómetro cero coma ocho.", To = "Yo" },
				{ S = "Omar", T = "No me estropees la emoción.", To = "Yo" },
				{ S = "Nico", T = "¡VACA! ¡Siete! ¡Voy ganando!", To = "Yo" },
				{ S = "Lucia", T = "¡Ya llegamos! Villaverde. La Granja Escuela.", To = "Yo", Shot = "General" },
				{ S = "Lucia", T = "Recordad: los animales no son juguetes.", To = "Yo", Pause = 0.9 },
			},
		},
		Vuelta = {
			Lines = {
				{ S = "Yo", T = "¿Qué haces?", Shot = "Reaccion:Sara", Effects = { Scene = "Cole07_G16_Musica" } },
				{ S = "Sara", T = "Registro de observación.", To = "Yo" },
				{ S = "Yo", T = "¿De qué?" },
				{ S = "Sara", T = "Ronquido nivel tres.", To = "Yo" },
				{ S = "Andres", T = "¡Atención, deportistas!", To = "Yo" },
				{ S = "Nico", T = "¿Qué?", To = "Yo" },
				{ S = "Andres", T = "Cuando volvamos… ¡Empieza el torneo del colegio!", To = "Yo" },
				{ S = "Nico", T = "¿TORNEO?", To = "Yo" },
				{ S = "Nico", T = "¡ESTOY DESPIERTO!", To = "Yo", Shot = "PrimerPlano:Nico" },
				{ S = "Omar", T = "Yo también. Creo.", To = "Yo" },
				{ S = "Narrador", T = "Aquel día aprendiste que una excursión podía ser muchas cosas.", Shot = "General" },
				{ S = "Narrador", T = "Un viaje.", Shot = "General" },
				{ S = "Narrador", T = "Un susto.", Shot = "General" },
				{ S = "Narrador", T = "Y un recuerdo que se quedaría contigo mucho después de volver a casa.", Shot = "General" },
				{ S = "Nico", T = "¡TORNEO!", To = "Yo" },
			},
		},
	},
	Scenes = {
		Cole07_G10_Musica = { Light = true, Duration = 30.4, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Cole07_G12_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = { Dialogue = { { At = 0.4, S = "Yo", T = "¿Hola? ¿Mateo?" } }, Music = { { At = 0, Intensity = "Tension" } } },
		},
		Cole07_G13_Musica = {
			Light = true,
			Duration = 21.8,
			Anchors = { Yo = "Player" },
			Tracks = { Music = { { At = 0, Intensity = "Tension" }, { At = 10.9, Intensity = "Intima" } } },
		},
		Cole07_G14_Musica = { Light = true, Duration = 31.6, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
		Cole07_G15 = {
			Skippable = true,
			Duration = 22.4,
			Anchors = { Sitio = "Place:GranjaGranero", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Lucia", Npc = "Lucia" } } },
				Camera = {
					{ At = 0.4, Duration = 2, Shot = "General:Sitio" },
					{ At = 2.4, Duration = 2, Shot = "Medio:Yo" },
					{ At = 4.4, Duration = 2.7, Shot = "General:Sitio" },
					{ At = 7.15, Duration = 14.6, Shot = "PrimerPlano:Yo" },
				},
				Dialogue = {
					{ At = 4.4, S = "Lucia", T = "¡Todos juntos! ¡A la de tres!", To = "Yo" },
					{ At = 7.1, S = "Lucia", T = "¡Una! ¡Dos! ¡Tres!", To = "Yo" },
					{ At = 12.7, S = "Narrador", T = "Años después quizá no recordarías todas las cosas que viste aquel día." },
					{ At = 18.6, S = "Narrador", T = "Pero sí recordarías cómo te sentías." },
				},
				Music = { { At = 0, Intensity = "Intima" } },
				Titles = { { At = 9.3, Duration = 3.2, Text = "La excursión a Villaverde" } },
			},
			Sting = "Momento",
		},
		Cole07_G16_Musica = {
			Light = true,
			Duration = 46.2,
			Anchors = { Yo = "Player" },
			Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" }, { At = 23.1, Intensity = "Tema" } } },
		},
		Cole07_G1_Fin = {
			Light = true,
			Duration = 22.9,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Ruben", Npc = "Ruben" } }, { At = 0, Use = { Key = "Bruno", Npc = "Bruno" } } },
				Dialogue = {
					{ At = 0.4, S = "Narrador", T = "En el colegio había días normales." },
					{ At = 4.3, S = "Narrador", T = "Y luego estaban los días de excursión." },
					{ At = 7.6, S = "Narrador", T = "Este era de los segundos." },
					{ At = 13.5, S = "Bruno", T = "¡Yo me pido la última fila!", To = "Yo" },
					{ At = 16.1, S = "Ruben", T = "¡Yo voy contigo!", To = "Yo" },
					{ At = 18.2, S = "Bruno", T = "No he dicho eso.", To = "Yo" },
					{ At = 20.2, S = "Ruben", T = "Demasiado tarde.", To = "Yo" },
				},
				Music = { { At = 0, Intensity = "Descubrimiento" }, { At = 11.1, Intensity = "Intima" } },
				Titles = { { At = 10.1, Duration = 3.2, Text = "Semanas después…" } },
			},
		},
		Cole07_G3_Musica = { Light = true, Duration = 32.4, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
		Cole07_G5_Musica = { Light = true, Duration = 28.9, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
		Cole07_G6 = {
			Skippable = true,
			Duration = 17.4,
			FadeIn = true,
			Anchors = { L_AutobusCole = "Place:AutobusCole", L_Granja = "Place:Granja", Sitio = "Place:AutobusCole", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Nico", Npc = "Nico" } },
					{ At = 0, Use = { Key = "Omar", Npc = "Omar" } },
					{ At = 0, Use = { Key = "Sara", Npc = "Sara" } },
				},
				Camera = {
					{ At = 0.4, Duration = 2, Shot = "General:L_AutobusCole" },
					{ At = 2.4, Duration = 2, Shot = "Dolly:L_Granja" },
					{ At = 4.4, Duration = 2, Shot = "General:Sitio" },
					{ At = 6.4, Duration = 10.3, Shot = "General:L_AutobusCole" },
				},
				Dialogue = {
					{ At = 6.4, S = "Nico", T = "¡CABALLOS!", To = "Yo" },
					{ At = 8.5, S = "Omar", T = "Primero el bocadillo.", To = "Yo" },
					{ At = 10.8, S = "Sara", T = "Primero las normas.", To = "Yo" },
					{ At = 13, S = "Omar", T = "Tú eres el motivo por el que existen las normas.", To = "Yo" },
				},
				Music = { { At = 0, Intensity = "Intima" } },
			},
		},
		Cole07_G7_Musica = { Light = true, Duration = 36.8, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Cole07_G9_Entra = {
			Light = true,
			Duration = 14.2,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Omar", Npc = "Omar" } },
					{ At = 0, Use = { Key = "Nico", Npc = "Nico" } },
					{ At = 0, Use = { Key = "Paula", Npc = "Paula" } },
				},
				Dialogue = {
					{ At = 0.4, S = "Paula", T = "¡Perfecto!", To = "Yo" },
					{ At = 2.4, S = "Nico", T = "¡Eso ha sido un lanzamiento profesional!", To = "Yo" },
					{ At = 5.8, S = "Paula", T = "Bien hecho.", To = "Yo" },
					{ At = 7.9, S = "Omar", T = "Creo que esa no confía en ti.", To = "Yo" },
					{ At = 11.5, S = "Paula", T = "Dale tiempo.", To = "Yo" },
				},
				Music = { { At = 0, Intensity = "Descubrimiento" } },
			},
		},
	},
	Steps = {
		["1"] = { Effects = { Scene = "Cole07_G1_Fin" } },
		["11"] = { Effects = { Scene = "Cole07_G12_Entra" } },
		["15"] = { Set = { Id = "Cole07_G15" } },
		["6"] = { Set = { Id = "Cole07_G6" } },
		["8"] = { Effects = { Scene = "Cole07_G9_Entra" } },
	},
}
