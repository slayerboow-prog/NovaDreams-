-- LA GRIETA: PROYECTO UMBRAL (18-11-2026, el dueño: «un juego súper adictivo, con una historia única, pero 0 infantil»).
-- Sustituye a la Saga de la Grieta de antes (la de la infancia, con humor absurdo: retirada en MissionIndex). Capítulo
-- Grieta_Umbral de shared/LifeStory/Chapters, después de la Reconquista. Seis misiones, cada una termina en gancho:
--   1. Señal en la estática: la baliza del Oeste capta una voz humana dentro de la Grieta. Ilse Maren, la ingeniera del
--      observatorio, sabe más de lo que dice. (taller: notas, foto, llave; descifrar; ¿confías en ella?)
--   2. Los que cayeron del cielo: una cápsula de otro mundo junto a una guarida del Este. Su piloto no era humano, y
--      huía de algo. Las bestias no invadieron: huyeron. (cápsula, grabadora, defenderla; ¿a quién se la llevas?)
--   3. Proyecto Umbral: el Consorcio abrió la Grieta para sacar energía del otro lado. El Consejo lo sabía. Entras en el
--      archivo del Consejo y sales perseguido. (expedientes, huida; ¿lo cuentas a todo el asentamiento?)
--   4. La deuda de Brenn: Brenn descubre que su hermano murió por una firma del consejero Varn. Va a por él.
--      (encontrarle; ¿le paras por la fuerza, le convences o te apartas?)
--   5. Al otro lado: despegar hacia la Grieta con Maren, aterrizar en el mundo de donde vienen las bestias y traer
--      la prueba. (revisar la nave, aterrizar, recoger; lo que hay allí)
--   6. Umbral: el generador del Consorcio sigue bajo el Consejo, abierto. Cerrarlo deja al asentamiento sin energía;
--      dejarlo abierto lo deja todo como está. Varn tiene guardias. (combate, sobrecarga, LA decisión)
-- Tono: 15+/17+, maduro, sin gore (memorias tono-historia y misiones-interactivas). Todo se juega.

local V = Vector3.new

local PISTA = {
	{ Npc = "Kael", Place = "Pista", Offset = V(0, 0, -6) },
	{ Npc = "Sorel", Place = "Pista", Offset = V(6, 0, -2), Mode = "Chat" },
	{ Npc = "Brenn", Place = "Pista", Offset = V(-4, 0, -4) },
}
local TALLER = {
	{ Npc = "Maren", Place = "TallerMaren", Offset = V(0, 0, 4) },
}
local MAREN_SIGUE = { Npc = "Maren", Mode = "Follow" }
local SOREL_SIGUE = { Npc = "Sorel", Mode = "Follow" }

local COMUN = {
	Kind = "Main",
	Chapter = "Grieta_Umbral",
	AgeRange = { 17, 40 },
	Difficulty = 4,
	Npcs = { "Kael", "Brenn", "Sorel", "Maren" },
	Locations = { "Pista", "TallerMaren" },
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
	---------------------------------------------------------------------
	-- 1 · Señal en la estática
	---------------------------------------------------------------------
	mision({
		Id = "Gri01_Senal",
		Title = "Señal en la estática",
		Description = "Tres noches seguidas, a las 3:12, la baliza del Oeste capta una voz humana que sale de la Grieta. Repite números. Siempre los mismos.",
		Duration = { 14, 18 },
		Type = "La Grieta · 1",
		Next = { "Gri02_Capsula" },
		Moment = "Oíste la voz de la Grieta",
		Rewards = { Money = 3000 },
		Props = {
			Notas = { Kind = "Papel", Name = "Cuadernos llenos de cálculos", Prompt = "Leer los cuadernos", Place = "TallerMaren", Offset = V(-5, 0, 2), Dialogue = "Notas", Once = true },
			Foto = { Kind = "Marcador", Name = "Una foto enmarcada, boca abajo", Prompt = "Darle la vuelta", Place = "TallerMaren", Offset = V(5, 0, 1), Dialogue = "Foto", Once = true },
			Receptor = { Kind = "Maquina", Name = "Un receptor de onda larga, encendido", Prompt = "Ponerte los cascos", Place = "TallerMaren", Offset = V(0, 0, -4), Dialogue = "Receptor", Once = true },
		},
		Steps = {
			{ Type = "Scene", Dialogue = "Baliza", Actors = PISTA },
			{ Type = "Reach", Place = "TallerMaren", Text = "Brenn dice que la única persona que entiende esa señal es Ilse Maren. Ve a su taller", Actors = TALLER },
			{ Type = "Talk", Npc = "Maren", Dialogue = "Puerta", Text = "Llama a la puerta de Maren", Actors = TALLER },
			{ Type = "Group", Text = "Maren ha salido a por café. Mira el taller mientras tanto",
				Actors = TALLER,
				Steps = {
					{ Type = "Use", Prop = "Notas", Text = "Los cuadernos" },
					{ Type = "Use", Prop = "Foto", Text = "La foto boca abajo" },
					{ Type = "Use", Prop = "Receptor", Text = "El receptor encendido" },
				} },
			{ Type = "MiniGame", Game = "Timing", Title = "Limpiar la señal", Icon = "📻", Hint = "Filtra el ruido: pulsa cuando la aguja pase por el verde",
				Rounds = 4, Need = 3, Zone = 0.22, Speed = 1.1,
				Win = { Flags = { "SenalLimpia" } }, Lose = { Flags = { "SenalSucia" } },
				Actors = TALLER },
			{ Type = "Scene", Dialogue = "Voz", Actors = TALLER },
			{ Type = "Choice", Key = "GriMaren", Text = "Maren te pide que no le cuentes a Kael lo de la foto: «Todavía no. Dame dos días». ¿Qué haces?",
				Options = {
					{ Id = "Confiar", Text = "Guardarle el secreto: «Dos días. Ni uno más.»", Effects = { Flags = { "MarenConfia" }, Rel = { Maren = 10 } } },
					{ Id = "Kael", Text = "«Kael tiene que saberlo. Hoy.»", Effects = { Flags = { "MarenDelatada" }, Rel = { Maren = -5, Kael = 5 }, Traits = { Responsabilidad = 1 } } },
				},
				Actors = TALLER },
			{ Type = "Talk", Npc = "Kael", Dialogue = "Coordenadas", Text = "Lleva las coordenadas a Kael", Actors = PISTA },
		},
		Dialogues = {
			Baliza = { Lines = {
				{ S = "Brenn", T = "Escucha esto. Grabado anoche, a las 3:12. Antes de anoche, a las 3:12. Y antes." },
				{ S = "Narrador", T = "Estática. Y debajo, muy lejos, una voz de mujer: «…cuatro, nueve, uno… cuatro, nueve, uno… si alguien me oye…»" },
				{ S = "Kael", T = "Viene del centro de la Grieta. De donde no puede venir nada humano." },
				{ S = "Brenn", T = "La única que sabe leer esos números es Maren, la del taller de las antenas. Trabajaba en el observatorio orbital. Estaba allí la noche que se abrió." },
			} },
			Puerta = { Lines = {
				{ S = "Maren", T = "¿Academia? No. Lo que sea, no. …Espera. ¿Has dicho 3:12?" },
				{ S = "Maren", T = "Pasa. No toques nada. Voy a por café: hace dos días que no duermo. Bueno, dos años." },
			} },
			Notas = { Lines = {
				{ S = "Narrador", T = "Cientos de páginas de cálculos. En todas se repite un nombre subrayado dos veces: «UMBRAL». En la última, escrito con prisa: «La abrimos nosotros»." },
			} },
			Foto = { Lines = {
				{ S = "Narrador", T = "Doce personas con bata delante del observatorio orbital, con una pancarta: «Proyecto Umbral · Consorcio · Primera apertura». Maren está en el centro, sonriendo." },
				{ S = "Narrador", T = "Al lado de Maren, con traje y sin bata, un hombre que conoces de los carteles del asentamiento: el consejero Varn." },
			} },
			Receptor = { Lines = {
				{ S = "Narrador", T = "El receptor está sintonizado en la misma frecuencia que la baliza. Maren lleva escuchándola mucho más de tres noches." },
			} },
			Voz = { Lines = {
				{ S = "Maren", T = "(desde la puerta, con dos cafés) Ya lo has visto. Bien. Me ahorra el discurso." },
				{ S = "Narrador", T = "La voz, limpia por primera vez: «Aquí Halden, observatorio Umbral, lado B. Cuatro, nueve, uno. Seguimos vivos. Seguimos vivos. Cerradla»." },
				{ S = "Maren", T = "Halden era mi compañera de turno. La noche de la apertura cruzó al otro lado a reparar una sonda. Y entonces la Grieta se abrió del todo." },
				{ S = "Maren", T = "Llevo dos años creyendo que la maté. Y lleva dos años pidiendo ayuda." },
				{ S = "Maren", T = "Los números son coordenadas. Junto a una guarida del Este. Algo cayó allí anoche." },
			} },
			Coordenadas = { Lines = {
				{ S = "Kael", T = "¿Una voz humana al otro lado? ¿Y Maren lo sabía?" },
				{ S = "Kael", T = "Mañana vas a esas coordenadas. Si algo cayó del cielo, quiero saber qué es antes que el Consejo." },
				{ S = "Sorel", T = "¿Antes que el Consejo? ¿Por qué antes que el Consejo?" },
				{ S = "Kael", T = "Porque cuando cayó la Caída, el Consejo sabía exactamente dónde esconderse. Siempre me lo he preguntado." },
			}, Effects = { Rel = { Kael = 3 } } },
		},
	}),

	---------------------------------------------------------------------
	-- 2 · Los que cayeron del cielo
	---------------------------------------------------------------------
	mision({
		Id = "Gri02_Capsula",
		Title = "Los que cayeron del cielo",
		Description = "En las coordenadas de la voz hay un cráter reciente. Dentro, algo que no se fabricó en este mundo.",
		Duration = { 16, 22 },
		Type = "La Grieta · 2",
		Next = { "Gri03_Umbral" },
		Moment = "Descubriste de qué huían las bestias",
		Rewards = { Money = 3500 },
		Props = {
			Escotilla = { Kind = "Nave", Name = "Una cápsula hundida en el cráter", Prompt = "Forzar la escotilla", Place = "GuaridaEste", Offset = V(0, 0, 18), Dialogue = "Escotilla", Once = true },
			Piloto = { Kind = "Marcador", Name = "El piloto", Prompt = "Mirar al piloto", Place = "GuaridaEste", Offset = V(3, 0, 20), Dialogue = "Piloto", Once = true },
			Grabadora = { Kind = "Maquina", Name = "Una caja negra que parpadea", Prompt = "Arrancar la caja negra", Place = "GuaridaEste", Offset = V(-4, 0, 21), Dialogue = "Grabadora", Once = true },
		},
		Steps = {
			{ Type = "Reach", Place = "GuaridaEste", Text = "Ve a las coordenadas de la voz, junto a la guarida del Este", Actors = { SOREL_SIGUE } },
			{ Type = "Event", Event = "BeastKilled", Count = 8, Match = { Region = "Farm_Este" },
				Text = "Las bestias rodean el cráter. Abre paso ({count}/{total})", Actors = { SOREL_SIGUE } },
			{ Type = "Group", Text = "Investiga la cápsula",
				Actors = { SOREL_SIGUE },
				Steps = {
					{ Type = "Use", Prop = "Escotilla", Text = "Abre la escotilla" },
					{ Type = "Use", Prop = "Piloto", Text = "Mira al piloto" },
					{ Type = "Use", Prop = "Grabadora", Text = "La caja negra" },
				} },
			{ Type = "MiniGame", Game = "Timing", Title = "Descifrar la caja negra", Icon = "🧩", Hint = "Alinea los fragmentos de la grabación: pulsa en el verde",
				Rounds = 4, Need = 3, Zone = 0.22, Speed = 1.15,
				Win = { Flags = { "CajaNegraEntera" } }, Lose = { Flags = { "CajaNegraRota" } } },
			{ Type = "Scene", Dialogue = "Huida", Actors = { SOREL_SIGUE } },
			{ Type = "Event", Event = "BeastKilled", Count = 10, Match = { Region = "Farm_Este" },
				Text = "Algo enorme se acerca y las bestias huyen en estampida HACIA ti. Aguanta ({count}/{total})", Actors = { SOREL_SIGUE } },
			{ Type = "Choice", Key = "GriCajaNegra", Text = "La caja negra lo cambia todo. ¿A quién se la llevas?",
				Options = {
					{ Id = "Kael", Text = "A Kael, a la Academia", Effects = { Flags = { "CajaKael" }, Rel = { Kael = 6 } } },
					{ Id = "Maren", Text = "A Maren: es la única que puede entenderla del todo", Effects = { Flags = { "CajaMaren" }, Rel = { Maren = 8 } } },
				} },
			{ Type = "Talk", Npc = "Kael", Dialogue = "Informe", Text = "Vuelve a la Academia", Actors = PISTA, If = { Choices = { GriCajaNegra = "Kael" } } },
			{ Type = "Talk", Npc = "Maren", Dialogue = "InformeMaren", Text = "Lleva la caja negra al taller de Maren", Actors = TALLER, If = { Choices = { GriCajaNegra = "Maren" } } },
		},
		Dialogues = {
			Escotilla = { Lines = {
				{ S = "Narrador", T = "El metal de la cápsula está tibio y es suave como el hueso. No tiene remaches ni soldaduras: parece haber crecido así. La escotilla cede con un siseo." },
			} },
			Piloto = { Lines = {
				{ S = "Narrador", T = "Dentro, sin vida, un piloto con armadura. Dos metros y medio. Cuatro dedos en cada mano. En el pecho, grabado, un símbolo: una grieta atravesada por una línea." },
				{ S = "Sorel", T = "No es una bestia. Lleva armadura. Lleva… un anillo." },
			} },
			Grabadora = { Lines = {
				{ S = "Narrador", T = "La caja negra parpadea al tocarla. Proyecta en el aire líneas de luz rotas, como una grabación hecha pedazos." },
			} },
			Huida = { Lines = {
				{ S = "Narrador", T = "La grabación se recompone: un cielo rojo, ciudades enteras ardiendo bajo una sombra que tapa el horizonte. Millones de criaturas corriendo hacia una luz: la Grieta." },
				{ S = "Narrador", T = "Una voz traducida a trompicones por la caja: «…no son nuestras bestias… huyen como nosotros… la herida en el cielo la abrieron los de vuestro lado… cerradla antes de que lo que viene detrás encuentre el camino…»" },
				{ S = "Sorel", T = "Las bestias no vinieron a atacarnos. Vinieron huyendo." },
				{ S = "Narrador", T = "Un rugido grave hace temblar el suelo. Por el norte, las bestias del Este salen en estampida. Hacia vosotros." },
			} },
			Informe = { Lines = {
				{ S = "Kael", T = "Refugiados. Dos años matando refugiados." },
				{ S = "Kael", T = "«La abrieron los de vuestro lado». Quiero saber quién. Maren sabe quién." },
				{ S = "Brenn", T = "¿Y si da igual quién? Mi hermano está muerto igual." },
				{ S = "Kael", T = "No da igual, Brenn. Nunca da igual." },
			}, Effects = { Rel = { Kael = 3 } } },
			InformeMaren = { Lines = {
				{ S = "Maren", T = "(con la caja negra entre las manos, sin parpadear) «Los de vuestro lado». Nosotros." },
				{ S = "Maren", T = "Hay un archivo en el edificio del Consejo. Todo lo del Proyecto Umbral está allí: quién firmó, quién sabía, quién se salvó. Varn lo guarda bajo llave." },
				{ S = "Maren", T = "Si de verdad quieres saber por qué cayó tu mundo, ve a por él." },
			}, Effects = { Rel = { Maren = 4 } } },
		},
	}),

	---------------------------------------------------------------------
	-- 3 · Proyecto Umbral
	---------------------------------------------------------------------
	mision({
		Id = "Gri03_Umbral",
		Title = "Proyecto Umbral",
		Description = "El archivo del Consejo guarda la verdad sobre la Caída. Nadie de la Academia ha entrado nunca. Esta noche entras tú.",
		Duration = { 16, 22 },
		Type = "La Grieta · 3",
		Next = { "Gri04_Brenn" },
		Moment = "Supiste quién abrió la Grieta",
		Npcs = { "Kael", "Brenn", "Sorel", "Maren", "Varn", "GuardiaConsejo1", "GuardiaConsejo2" },
		Locations = { "Pista", "TallerMaren", "SalaConsejo" },
		Rewards = { Money = 4000 },
		Props = {
			Expediente = { Kind = "Papel", Name = "Expediente «Umbral · Apertura»", Prompt = "Leer el expediente", Place = "SalaConsejo", Offset = V(-6, 0, 2), Dialogue = "Expediente", Once = true },
			Lista = { Kind = "Papel", Name = "Lista «Plan de contingencia · Refugio central»", Prompt = "Leer la lista", Place = "SalaConsejo", Offset = V(0, 0, 4), Dialogue = "Lista", Once = true },
			Orden = { Kind = "Papel", Name = "Orden firmada · «Sector Sur: no evacuar»", Prompt = "Leer la orden", Place = "SalaConsejo", Offset = V(6, 0, 2), Dialogue = "Orden", Once = true },
		},
		Steps = {
			{ Type = "Scene", Dialogue = "Plan", Actors = TALLER },
			{ Type = "Escape", Place = "SalaConsejo", Respawn = "TallerMaren", Catch = 4,
				Text = "Entra en el edificio del Consejo sin que te vean los guardias",
				CaughtLine = "¡Eh! ¿Qué haces aquí a estas horas? …Fuera. Y da gracias de que no lo apunte.",
				Actors = {
					{ Npc = "GuardiaConsejo1", Place = "SalaConsejo", Offset = V(10, 0, 14), Mode = "Hunt", Speed = 9, Prompt = false },
					{ Npc = "GuardiaConsejo2", Place = "SalaConsejo", Offset = V(-12, 0, 10), Mode = "Hunt", Speed = 8, Prompt = false },
				} },
			{ Type = "Group", Text = "Busca en el archivo del Consejo",
				Steps = {
					{ Type = "Use", Prop = "Expediente", Text = "El expediente de la apertura" },
					{ Type = "Use", Prop = "Lista", Text = "La lista del refugio" },
					{ Type = "Use", Prop = "Orden", Text = "La orden firmada" },
				} },
			{ Type = "Scene", Dialogue = "Varn", Actors = { { Npc = "Varn", Place = "SalaConsejo", Offset = V(0, 0, 10) } } },
			{ Type = "Escape", Place = "TallerMaren", Respawn = "SalaConsejo", Catch = 4,
				Text = "¡Varn ha dado la alarma! Huye al taller de Maren con los papeles",
				CaughtLine = "(Te derriban contra el suelo. Consigues soltarte y correr por otra calle.)",
				Actors = {
					{ Npc = "GuardiaConsejo1", Place = "SalaConsejo", Offset = V(6, 0, 6), Mode = "Hunt", Speed = 11, Prompt = false },
					{ Npc = "GuardiaConsejo2", Place = "SalaConsejo", Offset = V(-6, 0, 6), Mode = "Hunt", Speed = 10, Prompt = false },
				} },
			{ Type = "Choice", Key = "GriVerdad", Text = "Tienes las pruebas: el Consorcio abrió la Grieta, el Consejo lo sabía, y Varn firmó que no se evacuara el Sur para que la carretera quedara libre para ellos. ¿Qué haces con esto?",
				Options = {
					{ Id = "Publicar", Text = "Pegarlo en la plaza: que todo el asentamiento lo sepa esta misma noche", Effects = { Flags = { "UmbralPublico" }, Rel = { Sorel = 6, Kael = 2 }, Traits = { Rebeldia = 1 } } },
					{ Id = "Kael", Text = "Dárselo a Kael: que la Academia decida cómo y cuándo", Effects = { Flags = { "UmbralKael" }, Rel = { Kael = 6 }, Traits = { Responsabilidad = 1 } } },
					{ Id = "Callar", Text = "Guardarlo de momento: con esto se puede presionar a Varn", Effects = { Flags = { "UmbralPresion" }, Rel = { Maren = 4, Sorel = -4 } } },
				},
				Actors = TALLER },
			{ Type = "Scene", Dialogue = "Brenn", Actors = TALLER },
		},
		Dialogues = {
			Plan = { Lines = {
				{ S = "Maren", T = "El archivo está en la planta baja del edificio del Consejo, en la plaza. Dos guardias de noche. Ninguno ha cruzado la empalizada en su vida: no corren mucho." },
				{ S = "Maren", T = "Busca tres cosas: el expediente de la apertura, la lista del refugio y cualquier orden con la firma de Varn." },
			} },
			Expediente = { Lines = {
				{ S = "Narrador", T = "«Proyecto Umbral. Objetivo: extracción de energía de un espacio adyacente mediante apertura controlada. Riesgo de pérdida de control: 31 %. Aprobado.»" },
				{ S = "Narrador", T = "Treinta y uno por ciento. Lo aprobaron igual." },
			} },
			Lista = { Lines = {
				{ S = "Narrador", T = "Una lista de doscientos nombres con acceso al refugio blindado del centro «en caso de incidente». Todos del Consejo y del Consorcio, con sus familias. Fechada tres meses ANTES de la Caída." },
			} },
			Orden = { Lines = {
				{ S = "Narrador", T = "«Ante el incidente en curso, NO se evacuará el sector Sur hasta completar el traslado del personal del Consorcio por la carretera principal. Firmado: A. Varn.» La hora: la noche de la Caída, 23:40." },
				{ S = "Narrador", T = "El hermano de Brenn murió en el Sur esa noche. Igual que la calle del mercado de Sorel." },
			} },
			Varn = { Lines = {
				{ S = "Varn", T = "(encendiendo la luz) Sabía que algún día entraría alguien. No esperaba que fuera un crío de la Academia." },
				{ S = "Varn", T = "¿Sabes cuánta gente vive hoy gracias a la energía de Umbral? Las luces de la empalizada. El agua caliente. El hospital. Todo sale de esa herida." },
				{ S = "Varn", T = "Dejé morir un barrio para salvar una ciudad. Haría lo mismo mañana. Suelta esos papeles." },
				{ S = "Narrador", T = "No los sueltas. Varn suspira y pulsa un botón de la pared. Suena una alarma." },
			} },
			Brenn = { Lines = {
				{ S = "Narrador", T = "La puerta del taller se abre de golpe. Es Brenn. Ha visto la orden por encima de tu hombro. Ha leído «sector Sur» y la hora." },
				{ S = "Brenn", T = "23:40. Mi hermano me llamó a las 23:52. Le dije que esperara a la evacuación. Que vendrían." },
				{ S = "Brenn", T = "No iban a venir. Nunca iban a venir." },
				{ S = "Narrador", T = "Se va sin cerrar la puerta. Lleva la espada." },
			} },
		},
	}),

	---------------------------------------------------------------------
	-- 4 · La deuda de Brenn
	---------------------------------------------------------------------
	mision({
		Id = "Gri04_Brenn",
		Title = "La deuda de Brenn",
		Description = "Brenn va a por el consejero Varn. Si llega, nadie podrá protegerle después. Si no llega, quizá nunca te lo perdone.",
		Duration = { 12, 18 },
		Type = "La Grieta · 4",
		Next = { "Gri05_OtroLado" },
		Moment = "Elegiste qué hacer con Brenn",
		Npcs = { "Kael", "Brenn", "Sorel", "Maren", "Varn", "GuardiaConsejo1" },
		Locations = { "Pista", "SalaConsejo" },
		Rewards = { Money = 4000 },
		Props = {
			Espada = { Kind = "Marcador", Name = "La espada de Brenn, clavada en el suelo", Prompt = "Coger la espada", Place = "SalaConsejo", Offset = V(4, 0, 16), Dialogue = "EspadaBrenn", Once = true },
		},
		Steps = {
			{ Type = "Scene", Dialogue = "Aviso", Actors = PISTA },
			{ Type = "Reach", Place = "SalaConsejo", Text = "Corre al edificio del Consejo antes de que llegue Brenn",
				Actors = { { Npc = "Sorel", Mode = "Follow" } } },
			{ Type = "Scene", Dialogue = "Frente",
				Actors = { { Npc = "Brenn", Place = "SalaConsejo", Offset = V(0, 0, 12) }, { Npc = "Varn", Place = "SalaConsejo", Offset = V(0, 0, 4) }, SOREL_SIGUE } },
			{ Type = "Choice", Key = "GriBrenn", Text = "Brenn tiene la espada a un palmo del cuello de Varn. Te mira. ¿Qué haces?",
				Options = {
					{ Id = "Pelear", Text = "Pararle por la fuerza", Effects = { Flags = { "BrennDetenido" }, Rel = { Brenn = -8, Kael = 4 } } },
					{ Id = "Hablar", Text = "Hablarle: «Si lo matas, Varn gana. Que lo juzguen todos.»", Effects = { Flags = { "BrennConvencido" }, Rel = { Brenn = 8, Sorel = 4 }, Traits = { Empatia = 1 } } },
					{ Id = "Apartarse", Text = "Bajar la espada y apartarte", Effects = { Flags = { "BrennLibre" }, Rel = { Brenn = 4, Kael = -8 }, Traits = { Rebeldia = 1 } } },
				},
				Actors = { { Npc = "Brenn", Place = "SalaConsejo", Offset = V(0, 0, 12) }, { Npc = "Varn", Place = "SalaConsejo", Offset = V(0, 0, 4) } } },
			{ Type = "Fight", Place = "SalaConsejo", Respawn = "SalaConsejo", Action = "Golpe ⚔", HP = 5, If = { Choices = { GriBrenn = "Pelear" } },
				Text = "Desarma a Brenn sin hacerle daño de verdad ({count}/{total})",
				CaughtLine = "Brenn te tira al suelo. «No te metas.» Te levantas. Otra vez.",
				Actors = { { Npc = "Varn", Place = "SalaConsejo", Offset = V(0, 0, 4) } },
				Enemies = {
					{ Npc = "Brenn", Offset = V(0, 0, 12), Speed = 12, HP = 5, Hurt = "¡Él firmó! ¡Él firmó y tú le defiendes!", Bye = "(suelta la espada) …Vale. Vale. Tú ganas." },
				} },
			{ Type = "MiniGame", Game = "Timing", Title = "Las palabras justas", Icon = "💬", If = { Choices = { GriBrenn = "Hablar" } },
				Hint = "Brenn está al límite: elige el momento para cada frase (pulsa en el verde)",
				Rounds = 3, Need = 2, Zone = 0.24, Speed = 0.9,
				Win = { Flags = { "BrennEscucha" } }, Lose = { Flags = { "BrennDuda" } } },
			{ Type = "Scene", Dialogue = "Convencido", If = { Choices = { GriBrenn = "Hablar" } },
				Actors = { { Npc = "Brenn", Place = "SalaConsejo", Offset = V(0, 0, 12) }, { Npc = "Varn", Place = "SalaConsejo", Offset = V(0, 0, 4) } } },
			{ Type = "Scene", Dialogue = "Aparte", If = { Choices = { GriBrenn = "Apartarse" } },
				Actors = { { Npc = "Brenn", Place = "SalaConsejo", Offset = V(0, 0, 12) }, { Npc = "Varn", Place = "SalaConsejo", Offset = V(0, 0, 4) } } },
			{ Type = "Use", Prop = "Espada", Text = "Recoge la espada de Brenn" },
			{ Type = "Scene", Dialogue = "Despues", Actors = PISTA },
		},
		Dialogues = {
			Aviso = { Lines = {
				{ S = "Sorel", T = "¡Brenn se ha llevado la espada y ha preguntado dónde duerme Varn! Va al edificio del Consejo." },
				{ S = "Kael", T = "Si le mata, le cuelgan. Si le paramos los guardias, le matan a él. Ve tú. Te escuchará antes que a mí." },
			} },
			Frente = { Lines = {
				{ S = "Narrador", T = "En la escalera del Consejo, Brenn tiene a Varn contra la pared. Los dos guardias están en el suelo, aturdidos." },
				{ S = "Varn", T = "Mátame si quieres, chico. Mañana se apagarán las luces del hospital y nadie sabrá encenderlas." },
				{ S = "Brenn", T = "Mi hermano tenía diecisiete años. Le dije que esperara. Que la evacuación venía. ¡Le dije que esperara!" },
			} },
			Convencido = { Lines = {
				{ S = "Narrador", T = "Le hablas despacio. Del Sur, de Tomás, de lo que pasará mañana si Varn aparece muerto en una escalera: nadie leerá la orden; solo hablarán del cadete que mató a un consejero." },
				{ S = "Brenn", T = "Quiero que lo sepan todos. Que sepan su nombre y lo que firmó." },
				{ S = "Narrador", T = "Brenn clava la espada en el escalón y se sienta, sin fuerzas. Varn resbala por la pared hasta el suelo." },
			} },
			Aparte = { Lines = {
				{ S = "Narrador", T = "Bajas la espada y te apartas. Brenn levanta la suya. Varn cierra los ojos." },
				{ S = "Narrador", T = "La hoja baja… y se clava en el escalón, a un dedo de la cabeza de Varn." },
				{ S = "Brenn", T = "No. Así no. Él quería que todos fuéramos como él. No le voy a dar ese gusto." },
			} },
			EspadaBrenn = { Lines = {
				{ S = "Narrador", T = "La espada está clavada en un escalón. En la empuñadura, grabadas a cuchillo, dos letras: «B. y T.». Brenn y Tomás." },
			} },
			Despues = { Lines = {
				{ S = "Kael", T = "Varn está bajo arresto de la Academia. El Consejo protesta. Me da igual." },
				{ S = "Brenn", T = "(con la mirada en el suelo) No sé si darte las gracias o no volver a hablarte nunca. Dame tiempo." },
				{ S = "Maren", T = "Hay una cosa más. Varn no mentía en todo: el generador de Umbral sigue abierto, bajo el Consejo. La Grieta no se cerrará sola. Y Halden sigue al otro lado." },
				{ S = "Maren", T = "Antes de decidir qué hacer con la Grieta, alguien tiene que ver lo que hay al otro lado. Con sus propios ojos." },
			}, Effects = { Rel = { Kael = 2 } } },
		},
	}),

	---------------------------------------------------------------------
	-- 5 · Al otro lado
	---------------------------------------------------------------------
	mision({
		Id = "Gri05_OtroLado",
		Title = "Al otro lado",
		Description = "Despegar hacia la Grieta, aterrizar en un mundo que nadie ha pisado y volver con la prueba de lo que viene detrás de las bestias.",
		Duration = { 15, 22 },
		Type = "La Grieta · 5",
		Next = { "Gri06_Decision" },
		Moment = "Pisaste el otro lado de la Grieta",
		Locations = { "Pista", "TallerMaren", "PuertoEspacial" },
		Rewards = { Money = 5000 },
		Props = {
			Sensor = { Kind = "Maquina", Name = "El sensor de Maren, sin instalar", Prompt = "Instalar el sensor en la nave", Place = "PuertoEspacial", Offset = V(-6, 0, 4), Dialogue = "Sensor", Once = true },
			Mensaje = { Kind = "Pantalla", Name = "El panel de comunicaciones", Prompt = "Grabar un mensaje por si no vuelves", Place = "PuertoEspacial", Offset = V(6, 0, 4), Dialogue = "Mensaje", Once = true },
		},
		Steps = {
			{ Type = "Reach", Place = "PuertoEspacial", Text = "Ve al puerto espacial con Maren", Actors = { MAREN_SIGUE } },
			{ Type = "Group", Text = "Prepara la nave para el salto",
				Actors = { { Npc = "Maren", Place = "PuertoEspacial", Offset = V(0, 0, 6) } },
				Steps = {
					{ Type = "Use", Prop = "Sensor", Text = "Instala el sensor de Maren" },
					{ Type = "Use", Prop = "Mensaje", Text = "Graba un mensaje" },
				} },
			{ Type = "Event", Event = "PlanetLanded", Text = "Despega, atraviesa la luz de la Grieta y aterriza en el planeta más cercano a ella" },
			{ Type = "Event", Event = "PlanetGather", Count = 4, Text = "Recoge 4 muestras del terreno para el sensor de Maren ({count}/{total})" },
			{ Type = "Event", Event = "BeastKilled", Count = 6, Text = "Algo te ha olido. Sobrevive ({count}/{total})" },
			{ Type = "Reach", Place = "TallerMaren", Text = "Vuelve a Valmar y lleva las muestras al taller de Maren", Actors = TALLER },
			{ Type = "Scene", Dialogue = "Analisis", Actors = TALLER },
		},
		Dialogues = {
			Sensor = { Lines = {
				{ S = "Maren", T = "Eso mide la «presión» de la Grieta. Si la aguja pasa del rojo, das la vuelta. No me mires así: no es una sugerencia." },
			} },
			Mensaje = { Lines = {
				{ S = "Narrador", T = "Una luz roja: grabando. Piensas un momento en qué decir." },
				{ Ask = "¿Para quién es el mensaje?", Options = {
					{ T = "Para Sorel", Effects = { Rel = { Sorel = 6 }, Flags = { "MensajeSorel" } }, Then = {
						{ S = "Narrador", T = "«Si oyes esto, he tardado más de la cuenta. Recupera el Sur. Tu calle. Por los dos.»" },
					} },
					{ T = "Para Kael", Effects = { Rel = { Kael = 6 }, Flags = { "MensajeKael" } }, Then = {
						{ S = "Narrador", T = "«Comandante: no he dejado a nadie atrás. Si no vuelvo, no venga a buscarme. Esa es la única orden que le doy.»" },
					} },
					{ T = "Para nadie. Borrarlo.", Effects = { Traits = { Valentia = 1 } }, Then = {
						{ S = "Narrador", T = "Borras la grabación. Vas a volver. No hace falta despedirse." },
					} },
				} },
			} },
			Analisis = { Lines = {
				{ S = "Maren", T = "(mirando las muestras al microscopio) Ceniza. Mucha. Y esto…" },
				{ S = "Maren", T = "Esto no es de una bestia. Es de algo que se come mundos enteros, despacio, y avanza hacia la luz. Hacia la Grieta. Hacia nosotros." },
				{ S = "Maren", T = "Las bestias huyen de eso. El piloto huía de eso. Halden lleva dos años escondiéndose de eso." },
				{ S = "Maren", T = "Si cerramos la Grieta, lo dejamos al otro lado. Con ella. Si la dejamos abierta, tarde o temprano encontrará el camino." },
				{ S = "Narrador", T = "En la radio, a las 3:12 en punto, la voz de Halden: «Cuatro, nueve, uno. Ya viene. Cerradla. Por favor. Cerradla»." },
			} },
		},
	}),

	---------------------------------------------------------------------
	-- 6 · Umbral
	---------------------------------------------------------------------
	mision({
		Id = "Gri06_Decision",
		Title = "Umbral",
		Description = "El generador del Proyecto Umbral sigue en marcha bajo el edificio del Consejo. Lo que hagas con él decide el futuro de Valmar.",
		Duration = { 18, 25 },
		Difficulty = 5,
		Type = "La Grieta · Final",
		Moment = "Decidiste el destino de la Grieta",
		Npcs = { "Kael", "Brenn", "Sorel", "Maren", "Varn", "GuardiaConsejo1", "GuardiaConsejo2" },
		Locations = { "Pista", "SalaConsejo" },
		Rewards = { Money = 10000, Flags = { "UmbralResuelto" } },
		Props = {
			Panel = { Kind = "Maquina", Name = "El panel del generador Umbral", Prompt = "Abrir el panel", Place = "SalaConsejo", Offset = V(0, 0, -4), Dialogue = "Panel", Once = true },
		},
		Steps = {
			{ Type = "Scene", Dialogue = "Reunion", Actors = PISTA },
			{ Type = "Reach", Place = "SalaConsejo", Text = "Baja al sótano del Consejo, al generador de Umbral",
				Actors = { MAREN_SIGUE, SOREL_SIGUE } },
			{ Type = "Scene", Dialogue = "Emboscada",
				Actors = { { Npc = "Varn", Place = "SalaConsejo", Offset = V(0, 0, 10) }, { Npc = "GuardiaConsejo1", Place = "SalaConsejo", Offset = V(-6, 0, 8) }, { Npc = "GuardiaConsejo2", Place = "SalaConsejo", Offset = V(6, 0, 8) } } },
			{ Type = "Fight", Place = "SalaConsejo", Respawn = "SalaConsejo", Action = "Golpe ⚔", HP = 6,
				Text = "Los guardias de Varn os cortan el paso. Derríbalos ({count}/{total})",
				CaughtLine = "(Te derriban. Sorel te levanta del brazo.) ¡Arriba! ¡Ya casi!",
				Actors = { { Npc = "Sorel", Place = "SalaConsejo", Offset = V(-4, 0, 2), Mode = "Point" }, { Npc = "Maren", Place = "SalaConsejo", Offset = V(4, 0, 0) } },
				Enemies = {
					{ Npc = "GuardiaConsejo1", Offset = V(-6, 0, 8), Speed = 11, HP = 3, Bye = "Vale… vale… no me pagan para esto." },
					{ Npc = "GuardiaConsejo2", Offset = V(6, 0, 8), Speed = 11, HP = 3, Bye = "Me rindo. Que alguien apague la alarma." },
				} },
			{ Type = "Use", Prop = "Panel", Text = "Abre el panel del generador" },
			{ Type = "Choice", Key = "GriFinal", Text = "Con la Grieta cerrada, lo que viene se queda fuera, con Halden, y el asentamiento pierde la energía. Abierta, todo sigue funcionando hasta que esa cosa encuentre el camino. Hay una tercera opción, la de Maren: cerrarla después de traer a Halden. Es posible que no salga bien.",
				Options = {
					{ Id = "Cerrar", Text = "Cerrarla ya. Sin energía, sin Halden, pero a salvo", Effects = { Flags = { "GrietaCerrada" }, Rel = { Kael = 6, Maren = -6 }, Traits = { Responsabilidad = 1 } } },
					{ Id = "Abierta", Text = "Dejarla abierta y controlarla: Valmar necesita esa energía para sobrevivir", Effects = { Flags = { "GrietaAbierta" }, Rel = { Sorel = -6 } } },
					{ Id = "Halden", Text = "La opción de Maren: abrirla del todo un minuto para que Halden cruce, y luego cerrarla", Effects = { Flags = { "GrietaHalden" }, Rel = { Maren = 12, Sorel = 4 }, Traits = { Valentia = 1 } } },
				},
				Actors = { { Npc = "Maren", Place = "SalaConsejo", Offset = V(4, 0, 0) }, { Npc = "Sorel", Place = "SalaConsejo", Offset = V(-4, 0, 2) } } },
			{ Type = "MiniGame", Game = "Timing", Title = "Sobrecarga del generador", Icon = "⚡", If = { Choices = { GriFinal = "Cerrar" } },
				Hint = "Sobrecarga las bobinas una a una: pulsa en el verde",
				Rounds = 5, Need = 3, Zone = 0.22, Speed = 1.15,
				Win = { Flags = { "CierreLimpio" } }, Lose = { Flags = { "CierreSucio" } } },
			{ Type = "MiniGame", Game = "Timing", Title = "Estabilizar la apertura", Icon = "🌀", If = { Choices = { GriFinal = "Abierta" } },
				Hint = "Que no se desboque: baja la presión en el verde",
				Rounds = 5, Need = 3, Zone = 0.22, Speed = 1.15,
				Win = { Flags = { "GrietaEstable" } }, Lose = { Flags = { "GrietaInestable" } } },
			{ Type = "MiniGame", Game = "Timing", Title = "Un minuto", Icon = "⏱", If = { Choices = { GriFinal = "Halden" } },
				Hint = "Abrir, aguantar y cerrar: pulsa en el verde en cada fase",
				Rounds = 6, Need = 4, Zone = 0.2, Speed = 1.2,
				Win = { Flags = { "HaldenCruza" } }, Lose = { Flags = { "HaldenPerdida" } } },
			{ Type = "Scene", Dialogue = "FinCerrar", If = { Choices = { GriFinal = "Cerrar" } }, Actors = PISTA },
			{ Type = "Scene", Dialogue = "FinAbierta", If = { Choices = { GriFinal = "Abierta" } }, Actors = PISTA },
			{ Type = "Scene", Dialogue = "FinHalden", If = { Choices = { GriFinal = "Halden" } }, Actors = PISTA },
		},
		Dialogues = {
			Reunion = { Lines = {
				{ S = "Kael", T = "El Consejo quiere el generador abierto. La Academia está dividida. Maren quiere sacar a Halden. Y lo que viene del otro lado no va a esperar a que nos pongamos de acuerdo." },
				{ S = "Kael", T = "Tú has estado allí. Tú has visto lo que hay. La decisión es tuya. Que nadie diga después que te la impusimos." },
				{ S = "Brenn", T = "(apoyado en la puerta) Varn ha escapado del arresto. Tiene a los guardias del Consejo en el sótano. Te acompaño hasta la escalera. Luego, es cosa tuya." },
			} },
			Emboscada = { Lines = {
				{ S = "Varn", T = "Esa máquina mantiene vivas a seis mil personas. Si la tocas, mañana el hospital estará a oscuras. ¿Eso es salvar Valmar?" },
				{ S = "Sorel", T = "Usted dejó morir el Sur para salvarse. No le toca a usted hablar de salvar a nadie." },
				{ S = "Varn", T = "Guardias." },
			} },
			Panel = { Lines = {
				{ S = "Narrador", T = "El generador ocupa todo el sótano: un anillo de metal negro con una luz blanca en el centro, que late como un corazón. Cada latido hace temblar el suelo." },
				{ S = "Maren", T = "Ahí está. La herida. Lleva dos años sangrando luz." },
			} },
			FinCerrar = { Lines = {
				{ S = "Narrador", T = "El anillo se apaga con un grito metálico. En el cielo, la Grieta se estrecha, parpadea y se cierra como un ojo." },
				{ S = "Narrador", T = "Las luces del asentamiento se apagan una a una. Esa noche, por primera vez en dos años, se ven las estrellas sobre Valmar." },
				{ S = "Kael", T = "Mañana empezaremos a quemar madera y a racionar baterías. Pero estaremos vivos para hacerlo." },
				{ S = "Maren", T = "(con la radio apagada en las manos) A las 3:12 ya no habrá nadie contando números. Espero que me perdone." },
				{ S = "Narrador", T = "La Grieta está cerrada. Por ahora. Las bestias que quedan de este lado ya no tienen adónde volver… ni de qué huir." },
			} },
			FinAbierta = { Lines = {
				{ S = "Narrador", T = "El anillo zumba, estable. Las luces del asentamiento siguen encendidas. En el cielo, la Grieta brilla como siempre." },
				{ S = "Kael", T = "Elegiste que la gente tenga luz esta noche. Es una decisión que alguien tenía que tomar." },
				{ S = "Sorel", T = "Y cuando esa cosa encuentre el camino, ¿qué?" },
				{ S = "Narrador", T = "A las 3:12, la radio vuelve a sonar. Esta vez no es Halden. Es un sonido grave, como una respiración, al otro lado." },
			} },
			FinHalden = { Lines = {
				{ S = "Narrador", T = "El anillo ruge. La Grieta se abre de par en par durante sesenta segundos interminables. Algo enorme se mueve en la luz." },
				{ S = "Narrador", T = "Y entonces, una figura cruza tambaleándose: una mujer con un traje roto del observatorio, cubierta de ceniza." },
				{ S = "Maren", T = "¿Halden? …Halden." },
				{ S = "Narrador", T = "Maren tira de la palanca. La Grieta se cierra con un trueno. Las luces se apagan. Halden levanta la cabeza y dice sus primeras palabras en dos años:" },
				{ S = "Narrador", T = "«No estaba sola allí dentro. Había más como yo. Y saben que existís.»" },
			} },
		},
	}),
}
