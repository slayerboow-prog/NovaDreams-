-- LA RECONQUISTA (17-11-2026, el dueño: «las misiones, muchas de ellas serán en terreno hostil, objetivo recuperar
-- el planeta»). Después de «Guerrero espacial» (Misiones/Guerrero): el capítulo Reconquista_Valmar de
-- shared/LifeStory/Chapters. El asentamiento (el Distrito Central, con su empalizada: World/Kit/Settlement) sale a
-- recuperar la tierra perdida, zona a zona. Cada misión se juega FUERA de la empalizada: las bestias cuentan solo
-- en su zona (Match = { Region = … }: BeastService manda la zona de la guarida en «BeastKilled») y lo que hay que
-- hacer está EN la zona, junto a su guarida (lugares Guarida…: la marca StoryLair de Services/BeastService).
--   1. La primera baliza: el Oeste; montar la baliza con tus manos y calibrarla mientras la manada ataca.
--   2. Agua para el asentamiento: el Sur; abrir las tres válvulas de la depuradora y decidir a quién va el agua.
--   3. El paso del pantano: el Este y el Pantano Maldito; poner las cargas, sincronizarlas y volar el paso.
--   4. El campus de los caídos: el último refugio; la pared de nombres, el diario, y lo que haces con él.
--   5. La primera bandera: derribar al Guardián Ancestral del Bosque Etéreo y plantar la bandera allí mismo.
-- (18-11-2026, el dueño: «muy interactivo, nada de solo mensajes».) Tono: público de 15+/17+, maduro y sin gore.

local V = Vector3.new

local PISTA = {
	{ Npc = "Kael", Place = "Pista", Offset = V(0, 0, -6) },
	{ Npc = "Sorel", Place = "Pista", Offset = V(6, 0, -2), Mode = "Chat" },
	{ Npc = "Brenn", Place = "Pista", Offset = V(-4, 0, -4) },
}

local COMUN = {
	Kind = "Main",
	Chapter = "Reconquista_Valmar",
	AgeRange = { 17, 30 },
	Difficulty = 3,
	Npcs = { "Kael", "Brenn", "Sorel" },
	Locations = { "Pista" },
}
local function mision(t: { [string]: any }): { [string]: any }
	for k, v in COMUN do
		if t[k] == nil then
			t[k] = v
		end
	end
	return t
end

return {
	mision({
		Id = "Rec01_Baliza",
		Title = "La primera baliza",
		Description = "Para recuperar la tierra hay que verla. La vieja torre de radio del Oeste puede volver a vigilar, si alguien limpia lo que vive a sus pies y monta la baliza.",
		Duration = { 14, 18 },
		Type = "Reconquista · Oeste",
		Next = { "Rec02_Agua" },
		Rewards = { Money = 1500 },
		Props = {
			Generador = { Kind = "Maquina", Name = "Generador de la torre, oxidado", Prompt = "Arrancar el generador", Place = "GuaridaOeste", Offset = V(-10, 0, 8), Dialogue = "Generador", Once = true },
			Antena = { Kind = "Maquina", Name = "La antena caída", Prompt = "Levantar y atornillar la antena", Place = "GuaridaOeste", Offset = V(8, 0, 10), Dialogue = "Antena", Once = true },
			Baliza = { Kind = "Pantalla", Name = "La baliza de Brenn", Prompt = "Encender la baliza", Place = "GuaridaOeste", Offset = V(0, 0, 16), Dialogue = "Encender", Once = true },
		},
		Steps = {
			{ Type = "Scene", Dialogue = "Plan", Actors = PISTA },
			{ Type = "Event", Event = "BeastKilled", Count = 12, Match = { Region = "Farm_Oeste" },
				Text = "Sal por la puerta oeste de la empalizada y limpia la Caza del Oeste: 12 bestias ({count}/{total})" },
			{ Type = "Reach", Place = "GuaridaOeste", Text = "Ve a los pies de la torre de radio, junto a la guarida del Oeste" },
			{ Type = "Group", Text = "Monta la baliza en la torre",
				Steps = {
					{ Type = "Use", Prop = "Generador", Text = "Arranca el generador" },
					{ Type = "Use", Prop = "Antena", Text = "Levanta la antena caída" },
				} },
			{ Type = "MiniGame", Game = "Timing", Title = "Calibrar la baliza", Icon = "📡", Hint = "Ajusta la frecuencia: pulsa cuando la aguja pase por el verde",
				Rounds = 4, Need = 3, Zone = 0.24, Speed = 1.1,
				Win = { Flags = { "BalizaFina" } }, Lose = { Flags = { "BalizaRuidosa" } } },
			{ Type = "Use", Prop = "Baliza", Text = "Enciende la baliza" },
			{ Type = "Event", Event = "BeastKilled", Count = 5, Match = { Region = "Farm_Oeste" },
				Text = "La luz atrae a la manada: defiende la torre hasta que la baliza termine de arrancar ({count}/{total})" },
			{ Type = "Talk", Npc = "Brenn", Dialogue = "Baliza", Text = "Vuelve a la Academia: Brenn ya recibe la señal", Actors = PISTA },
		},
		Dialogues = {
			Plan = { Lines = {
				{ S = "Kael", T = "Dos años encerrados detrás de una empalizada de chatarra. Se acabó esconderse." },
				{ S = "Kael", T = "El consejo del asentamiento ha aprobado la Reconquista. Zona a zona. Sin prisa y sin muertos tontos." },
				{ S = "Brenn", T = "La torre de radio del Oeste sigue en pie. Te doy la baliza: la montas tú. Generador, antena, calibrado. Si la enciendes con la manada cerca, prepárate: la luz las atrae." },
				{ S = "Sorel", T = "Las casas de esa zona siguen ahí. Medio caídas. Algunas con la mesa puesta. Nadie volvió a recoger nada." },
			} },
			Generador = { Lines = {
				{ S = "Narrador", T = "Tiras de la cuerda de arranque. Una vez. Dos. A la tercera el generador tose, escupe humo negro y empieza a temblar." },
				{ S = "Narrador", T = "El ruido se oye a dos calles. Algo, al fondo, deja de comer y levanta la cabeza." },
			} },
			Antena = { Lines = {
				{ S = "Narrador", T = "La antena pesa como un coche pequeño. La levantas apoyándola en el hombro y aprietas los tornillos con los dientes apretados." },
			} },
			Encender = { Lines = {
				{ S = "Narrador", T = "Pulsas el interruptor. Una luz blanca barre el barrio en círculos lentos, por primera vez en dos años." },
				{ S = "Narrador", T = "De las ruinas sale un aullido. Luego otro. Vienen." },
			} },
			Baliza = { Lines = {
				{ S = "Brenn", T = "Señal limpia. Desde aquí se ve hasta la costa. Y se ve otra cosa: rastros. Muchos. Vienen del sur." },
				{ S = "Kael", T = "Primera zona vigilada en dos años. Apúntalo, guerrero. Es el primer metro que le quitamos a la Caída." },
			}, Effects = { Rel = { Brenn = 3, Kael = 2 } } },
		},
	}),

	mision({
		Id = "Rec02_Agua",
		Title = "Agua para el asentamiento",
		Description = "Los depósitos del asentamiento bajan cada semana. La depuradora del puerto viejo está en el Sur, en mitad de las manadas.",
		Duration = { 15, 20 },
		Type = "Reconquista · Sur",
		Next = { "Rec03_Pantano" },
		Rewards = { Money = 2000 },
		Props = {
			Valvula1 = { Kind = "Maquina", Name = "Válvula de entrada", Prompt = "Girar la válvula", Place = "GuaridaSur", Offset = V(-12, 0, 6), Dialogue = "Valvula", Once = true },
			Valvula2 = { Kind = "Maquina", Name = "Válvula del filtro", Prompt = "Girar la válvula", Place = "GuaridaSur", Offset = V(0, 0, 14), Dialogue = "Valvula", Once = true },
			Valvula3 = { Kind = "Maquina", Name = "Válvula de salida al asentamiento", Prompt = "Girar la válvula", Place = "GuaridaSur", Offset = V(12, 0, 6), Dialogue = "Salida", Once = true },
		},
		Steps = {
			{ Type = "Scene", Dialogue = "Sed", Actors = PISTA },
			{ Type = "Event", Event = "BeastKilled", Count = 18, Match = { Region = "Farm_Sur" },
				Text = "Despeja la Caza del Sur hasta el puerto viejo: 18 bestias ({count}/{total})" },
			{ Type = "Reach", Place = "GuaridaSur", Text = "Llega a la depuradora del puerto viejo, junto a la guarida del Sur" },
			{ Type = "Group", Text = "Abre las tres válvulas de la depuradora en orden",
				Steps = {
					{ Type = "Use", Prop = "Valvula1", Text = "La válvula de entrada" },
					{ Type = "Use", Prop = "Valvula2", Text = "La válvula del filtro" },
					{ Type = "Use", Prop = "Valvula3", Text = "La válvula de salida" },
				} },
			{ Type = "MiniGame", Game = "Timing", Title = "Presión de la bomba", Icon = "💧", Hint = "Que no reviente la tubería: suelta presión justo en el verde",
				Rounds = 3, Need = 2, Zone = 0.26, Speed = 1,
				Win = { Flags = { "DepuradoraEntera" } }, Lose = { Flags = { "DepuradoraTocada" } } },
			{ Type = "Choice", Key = "RecAgua", Text = "La depuradora da agua, pero poca. El consejo pregunta por radio adónde va primero. ¿Qué dices?",
				Options = {
					{ Id = "Hospital", Text = "Al hospital y a las familias con niños", Effects = { Flags = { "AguaHospital" }, Rel = { Sorel = 5 }, Traits = { Empatia = 1 } } },
					{ Id = "Todos", Text = "A todo el asentamiento por igual, aunque sea menos para cada uno", Effects = { Flags = { "AguaReparto" }, Traits = { Responsabilidad = 1 } } },
					{ Id = "Guardias", Text = "A la guardia de la empalizada: si caen ellos, caemos todos", Effects = { Flags = { "AguaGuardia" }, Rel = { Kael = 3, Sorel = -3 } } },
				} },
			{ Type = "Talk", Npc = "Sorel", Dialogue = "Depuradora", Text = "Vuelve con Sorel a la Academia", Actors = PISTA },
		},
		Dialogues = {
			Sed = { Lines = {
				{ S = "Narrador", T = "En el patio del asentamiento la cola del pozo da la vuelta a la manzana. La gente lleva cubos de pintura, bidones, cazuelas." },
				{ S = "Sorel", T = "Racionan el agua a dos litros por persona. Hay críos que no se han lavado en una semana." },
				{ S = "Kael", T = "La depuradora del puerto funciona si alguien llega hasta ella y la arranca a mano. Los rastros que vio Brenn van justo hacia allí." },
			} },
			Valvula = { Lines = {
				{ S = "Narrador", T = "La rueda está agarrotada por el óxido. Apoyas el pie en la tubería y tiras con todo el cuerpo. Cede con un chirrido que hace eco en todo el puerto." },
			} },
			Salida = { Lines = {
				{ S = "Narrador", T = "La última válvula gira. Las tuberías vibran, gorgotean y, muy lejos, hacia el asentamiento, algo empieza a correr por dentro." },
			} },
			Depuradora = { Lines = {
				{ S = "Sorel", T = "Los ingenieros dicen que la depuradora aguanta. Agua, si mantenemos el Sur limpio." },
				{ S = "Sorel", T = "Una señora me ha dado las gracias llorando. Por agua. Por algo que antes salía del grifo." },
				{ S = "Kael", T = "Dos zonas. El asentamiento ya no es una jaula: es una base." },
			}, Effects = { Rel = { Sorel = 4, Kael = 2 } } },
		},
	}),

	mision({
		Id = "Rec03_Pantano",
		Title = "El paso del pantano",
		Description = "Al este, el paso de tierra lleva a las Tierras Exteriores. Al otro lado espera el Pantano Maldito, y lo que baja de él cada noche.",
		Duration = { 18, 24 },
		Difficulty = 4,
		Type = "Reconquista · Este",
		Next = { "Rec04_Campus" },
		Rewards = { Money = 2800 },
		Props = {
			Carga1 = { Kind = "Caja", Name = "Grieta en la roca del paso (norte)", Prompt = "Colocar la carga", Place = "GuaridaPantano", Offset = V(-10, 0, 8), Dialogue = "Carga", Once = true },
			Carga2 = { Kind = "Caja", Name = "Grieta en la roca del paso (sur)", Prompt = "Colocar la carga", Place = "GuaridaPantano", Offset = V(10, 0, 8), Dialogue = "Carga", Once = true },
			Nido = { Kind = "Huella", Name = "Algo vive bajo el barro", Prompt = "Mirar de cerca", Place = "GuaridaPantano", Offset = V(0, 0, 18), Dialogue = "Nido", Once = true },
		},
		Steps = {
			{ Type = "Scene", Dialogue = "Paso", Actors = PISTA },
			{ Type = "Event", Event = "BeastKilled", Count = 15, Match = { Region = "Farm_Este" },
				Text = "Abre camino por la Caza del Este hasta el paso de tierra: 15 bestias ({count}/{total})" },
			{ Type = "Event", Event = "BeastKilled", Count = 10, Match = { Region = "PantanoMaldito" },
				Text = "Cruza el paso y caza 10 bestias en el Pantano Maldito ({count}/{total})" },
			{ Type = "Reach", Place = "GuaridaPantano", Text = "Busca de dónde suben las bestias cada noche, en el corazón del pantano" },
			{ Type = "Use", Prop = "Nido", Text = "Algo se mueve bajo el barro: míralo de cerca" },
			{ Type = "Group", Text = "Pon las cargas para hundir la entrada del nido",
				Steps = {
					{ Type = "Use", Prop = "Carga1", Text = "La grieta norte" },
					{ Type = "Use", Prop = "Carga2", Text = "La grieta sur" },
				} },
			{ Type = "MiniGame", Game = "Timing", Title = "Sincronizar las cargas", Icon = "⏱", Hint = "Las dos a la vez: pulsa cuando la aguja pase por el verde",
				Rounds = 3, Need = 2, Zone = 0.24, Speed = 1.15,
				Win = { Flags = { "PasoVolado" } }, Lose = { Flags = { "PasoAMedias" } } },
			{ Type = "Event", Event = "BeastKilled", Count = 6, Match = { Region = "PantanoMaldito" },
				Text = "La explosión despierta al pantano entero: abre paso de vuelta ({count}/{total})" },
			{ Type = "Talk", Npc = "Kael", Dialogue = "Vuelta", Text = "Vuelve a la Academia a dar el parte", Actors = PISTA },
		},
		Dialogues = {
			Paso = { Lines = {
				{ S = "Kael", T = "Antes había un mar entre la isla y las tierras de fuera. La Caída lo secó en una noche. Ahora hay barro, y caminos de tierra que nadie ha pisado." },
				{ S = "Brenn", T = "Cada noche algo sube del pantano por el paso del este. Te doy dos cargas. Encuentra de dónde salen y tápalo." },
				{ S = "Kael", T = "Esto ya no son los distritos. Son las Tierras Exteriores. Si ves algo con más nivel que tú, vuelve. Es una orden." },
			} },
			Nido = { Lines = {
				{ S = "Narrador", T = "El barro respira. Debajo, una cavidad enorme, caliente, de donde suben burbujas y un zumbido grave. Decenas de huevos pegados a la roca." },
				{ S = "Narrador", T = "Si esto sigue aquí, el paso no se cerrará nunca." },
			} },
			Carga = { Lines = {
				{ S = "Narrador", T = "Encajas la carga en la grieta, aprietas el detonador contra la roca y tiras del seguro. Una luz roja empieza a parpadear." },
			} },
			Vuelta = { Lines = {
				{ S = "Narrador", T = "Vuelves con barro hasta las rodillas y el olor del pantano pegado a la ropa." },
				{ S = "Kael", T = "El paso del este, vigilado. Hemos puesto un campamento al otro lado. El primer campamento fuera de la isla desde la Caída." },
				{ S = "Brenn", T = "Mi hermano murió en ese paso. Hoy lo hemos cruzado y hemos vuelto todos." },
			}, Effects = { Rel = { Kael = 3, Brenn = 5 } } },
		},
	}),

	mision({
		Id = "Rec04_Campus",
		Title = "El campus de los caídos",
		Description = "El campus fue el último refugio de la Caída. Aguantó tres días. Lo que quedó dentro lleva dos años esperando a que alguien vuelva.",
		Duration = { 18, 24 },
		Difficulty = 4,
		Type = "Reconquista · Campus",
		Next = { "Rec05_Bandera" },
		Rewards = { Money = 3200 },
		Props = {
			Pared = { Kind = "Mural", Name = "La pared del gimnasio, llena de nombres", Prompt = "Buscar los nombres", Place = "GuaridaCampus", Offset = V(-10, 0, 10), Dialogue = "Pared", Once = true },
			Diario = { Kind = "Libro", Name = "Un cuaderno bajo un catre", Prompt = "Leer el cuaderno", Place = "GuaridaCampus", Offset = V(8, 0, 12), Dialogue = "Diario", Once = true },
			Radio = { Kind = "Maquina", Name = "La radio del refugio", Prompt = "Escuchar la última grabación", Place = "GuaridaCampus", Offset = V(0, 0, 20), Dialogue = "Grabacion", Once = true },
		},
		Steps = {
			{ Type = "Scene", Dialogue = "Refugio", Actors = PISTA },
			{ Type = "Event", Event = "BeastKilled", Count = 22, Match = { Region = "Farm_Universitario" },
				Text = "Limpia la Caza del Campus: 22 bestias ({count}/{total})" },
			{ Type = "Reach", Place = "GuaridaCampus", Text = "Entra en el último refugio del campus, junto a la guarida",
				Actors = { { Npc = "Sorel", Mode = "Follow" } } },
			{ Type = "Group", Text = "Recorre el refugio con Sorel",
				Actors = { { Npc = "Sorel", Mode = "Follow" } },
				Steps = {
					{ Type = "Use", Prop = "Pared", Text = "La pared de los nombres" },
					{ Type = "Use", Prop = "Diario", Text = "El cuaderno bajo el catre" },
					{ Type = "Use", Prop = "Radio", Text = "La radio del refugio" },
				} },
			{ Type = "Choice", Key = "RecDiario", Text = "El cuaderno es del padre de Sorel. Cuenta cómo cayó el refugio, y no es fácil de leer. Sorel no lo ha visto aún. ¿Qué haces?",
				Options = {
					{ Id = "Darselo", Text = "Dárselo: tiene derecho a saberlo", Effects = { Flags = { "DiarioSorel" }, Rel = { Sorel = 8 }, Traits = { Empatia = 1 } } },
					{ Id = "Guardar", Text = "Guardarlo y dárselo más adelante, cuando esté preparada", Effects = { Flags = { "DiarioGuardado" }, Rel = { Sorel = 2 }, Traits = { Responsabilidad = 1 } } },
				},
				Actors = { { Npc = "Sorel", Place = "GuaridaCampus", Offset = V(-6, 0, 8) } } },
			{ Type = "Talk", Npc = "Sorel", Dialogue = "Nombres", Text = "Vuelve con Sorel a la Academia", Actors = PISTA },
		},
		Dialogues = {
			Refugio = { Lines = {
				{ S = "Sorel", T = "Mis padres estaban en el campus aquella noche. No sé si llegaron. Nunca lo he querido saber." },
				{ S = "Kael", T = "No tienes que ir." },
				{ S = "Sorel", T = "Sí tengo. Si no voy ahora, no iré nunca. Pero no quiero entrar sola." },
			} },
			Pared = { Lines = {
				{ S = "Narrador", T = "En la pared del gimnasio hay nombres escritos a mano. Cientos. Los que esperaban dentro los fueron apuntando, día a día." },
				{ S = "Sorel", T = "Están. Los dos. Escribieron su nombre y debajo el mío. Me estaban esperando." },
			} },
			Diario = { Lines = {
				{ S = "Narrador", T = "Un cuaderno de tapas azules. En la primera página: «Para Sorel, si alguien lo encuentra»." },
				{ S = "Narrador", T = "Lees solo la última entrada: «Día 3. La puerta norte no aguanta. Hemos decidido salir por el túnel con los críos. Si no llegamos, que sepa que salimos a buscarla»." },
			} },
			Grabacion = { Lines = {
				{ S = "Narrador", T = "La radio funciona con una manivela. Al girarla, una voz de hombre, cansada: «…refugio del campus, tercera noche. Seguimos ciento doce. Si alguien en la Academia oye esto, que no venga. Que espere al día»." },
				{ S = "Narrador", T = "Nadie vino. La Academia no existía todavía." },
			} },
			Nombres = { Lines = {
				{ S = "Sorel", T = "Salieron por el túnel. Puede que alguien llegara a algún sitio. Puede que no." },
				{ S = "Sorel", T = "Vamos a recuperar todo esto. Por ellos. Por todos los que escribieron su nombre en una pared." },
			}, Effects = { Rel = { Sorel = 8 } } },
		},
	}),

	mision({
		Id = "Rec05_Bandera",
		Title = "La primera bandera",
		Description = "En el Bosque Etéreo vive lo que manda sobre las manadas del norte. Si cae, el norte es nuestro.",
		Duration = { 18, 28 },
		Difficulty = 5,
		Type = "Reconquista · Jefe",
		Moment = "Plantaste la primera bandera de la Reconquista",
		Rewards = { Money = 6000, Flags = { "Reconquista1" } },
		Props = {
			Bandera = { Kind = "Marcador", Name = "El mástil para la bandera", Prompt = "Plantar la bandera", Place = "GuaridaBosque", Offset = V(0, 0, 14), Dialogue = "Plantar", Once = true },
		},
		Steps = {
			{ Type = "Scene", Dialogue = "Norte", Actors = PISTA },
			{ Type = "Event", Event = "BeastKilled", Count = 15, Match = { Region = "BosqueEtereo" },
				Text = "Entra en el Bosque Etéreo (al norte, por el paso) y abre camino: 15 bestias ({count}/{total})" },
			{ Type = "Event", Event = "BeastKilled", Count = 1, Match = { Species = "GuardianAncestral" },
				Text = "Derriba al Guardián Ancestral, el jefe del Bosque Etéreo" },
			{ Type = "Use", Prop = "Bandera", Text = "Planta la bandera de Valmar donde cayó el Guardián" },
			{ Type = "Talk", Npc = "Kael", Dialogue = "Bandera", Text = "Vuelve a la Academia", Actors = PISTA },
		},
		Dialogues = {
			Norte = { Lines = {
				{ S = "Kael", T = "Las balizas lo confirman: las manadas del norte se mueven juntas. Algo las dirige desde el bosque." },
				{ S = "Brenn", T = "Los viejos lo llaman el Guardián. Es más antiguo que la Caída. La Grieta solo lo despertó." },
				{ S = "Kael", T = "Necesito a alguien que llegue hasta él y vuelva. Llévate esto: una bandera. Si cae, la plantas allí mismo." },
			} },
			Plantar = { Lines = {
				{ S = "Narrador", T = "Clavas el mástil en la tierra blanda, todavía caliente donde cayó el Guardián. La tela se despliega con el viento: una estrella partida atravesada por una espada." },
				{ S = "Narrador", T = "En el bosque, por primera vez en dos años, no se oye nada. Ni un aullido." },
			} },
			Bandera = { Lines = {
				{ S = "Kael", T = "Desde la torre del Oeste se ve tu bandera. El norte es nuestro. La primera tierra recuperada desde la Caída." },
				{ S = "Sorel", T = "Queda todo lo demás. Siete regiones más. Y el cielo." },
				{ S = "Brenn", T = "Pues una a una. Como hasta ahora." },
				{ S = "Narrador", T = "La Reconquista ha empezado. Valmar ya no se esconde: avanza." },
			}, Effects = { Rel = { Kael = 6, Sorel = 4, Brenn = 4 } } },
		},
	}),
}
