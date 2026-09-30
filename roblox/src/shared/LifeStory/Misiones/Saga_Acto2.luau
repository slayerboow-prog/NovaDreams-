-- SAGA DE LA GRIETA · ACTO II «Los Visitantes» (adolescencia). Misiones CANÓNICAS: siempre en el mapa.
-- Plan completo: docs/historia/13-saga-de-la-grieta.md
--
--    7 Saga_07_Costuras   «Las costuras se sueltan»     ayudante oficial de Cosme; las hilachas del cielo
--    8 Saga_08_MegaVerso  «MegaVerso S.A.»              te infiltras en la oficina del Consorcio: «Proyecto Fusión»
--    9 Saga_09_Archivo    «El archivo de Pip»           la verdad: la noche en que naciste eres el Ancla
--   10 Saga_10_Fiesta     «La fiesta del fin del mundo» el Consorcio vende entradas para la Fusión; sabotaje
--   11 Saga_11_Cronos     «Cronos cambia de bando»      los formularios falsos del Consorcio
--   12 Saga_12_Graduacion «Graduación interdimensional» final del acto: Cósimo aparece y se lleva a Cosme

local V = Vector3.new

local function after(id: string, extra: { [string]: any }?): { [string]: any }
	local req = { Stage = { Min = "Adolescente" }, Completed = { id } }
	for key, value in extra or {} do
		req[key] = value
	end
	return req
end

local COSME = { Npc = "Cosme", Place = "GarajeCosme", Offset = V(0, 0, 3) }
local PIP = { Npc = "Pip", Place = "GarajeCosme", Offset = V(3, 0, 2) }
local ESCAMAS = { Npc = "DonEscamas", Place = "GarajeCosme", Offset = V(-3, 0, 1), Scale = 0.35 }
local OFICINA = "OficinasFinanciero"

return {
	---------------------------------------------------------------------
	-- 7 · Las costuras se sueltan
	---------------------------------------------------------------------
	{
		Id = "Saga_07_Costuras",
		Kind = "Side",
		Canon = true,
		Title = "Las costuras se sueltan",
		Description = "Años después de coser el cielo, el medidor de rarezas vuelve a pitar. Cosme te espera con una credencial plastificada y cara de preocupación.",
		Type = "Saga de la Grieta · Acto II (1/6)",
		Duration = { 25, 35 },
		Npcs = { "Cosme", "Pip", "DonEscamas", "Hilacha1", "Hilacha2" },
		Offer = { Place = "GarajeCosme" },
		OfferKey = "El medidor de rarezas de Cosme pita como hace años. La costura del cielo…",
		Requires = after("Saga_06_Coser"),
		Moment = "Te hiciste ayudante oficial de Cosme",
		Memory = "AyudanteCosme",
		Rewards = { Items = { CredencialAyudante = 1 }, Flags = { "AyudanteOficial" } },
		Props = {
			Punto1 = { Kind = "Moco", Name = "Hilos verdes que caen del cielo", Prompt = "Medir con el medidor", Place = "Parque", Offset = V(4, 0, 6), Dialogue = "Punto1", Once = true },
			Punto2 = { Kind = "Pantalla", Name = "Una pantalla publicitaria que no estaba", Prompt = "Mirar el anuncio", Place = "PlazaCentro", Offset = V(0, 0, 8), Color = Color3.fromRGB(150, 150, 160), Dialogue = "Punto2", Once = true },
			Punto3 = { Kind = "Cristal", Name = "Un cristal que zumba", Prompt = "Medir con el medidor", Place = "PatioInstituto", Offset = V(4, 0, 4), Dialogue = "Punto3", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Cosme", Dialogue = "Credencial", Text = "Habla con Cosme en el garaje", Actors = { COSME, PIP, ESCAMAS } },
			{ Type = "Group", Text = "Patrulla con el medidor de rarezas: tres sitios pitan",
				Steps = {
					{ Type = "Use", Prop = "Punto1", Text = "El parque" },
					{ Type = "Use", Prop = "Punto2", Text = "La plaza del centro" },
					{ Type = "Use", Prop = "Punto3", Text = "El patio del instituto" },
				} },
			{ Type = "Fight", Place = "Parque", Respawn = "Parque", Action = "Enrollarla en la aguja 🪡", HP = 2, BeamColor = Color3.fromRGB(120, 255, 160),
				Text = "¡Hilachas sueltas por el parque! Enróllalas antes de que lo enreden todo ({count}/{total})",
				CaughtLine = "¡Cosquillas de hilo! (Te enredan los cordones. Te desenredas junto a la fuente.)",
				Enemies = {
					{ Npc = "Hilacha1", Offset = V(-8, 0, 4), Speed = 13, Bye = "¡Ovillo! (Se enrolla sola y cae al suelo, dormida.)" },
					{ Npc = "Hilacha2", Offset = V(8, 0, 6), Speed = 12, HP = 4, Hurt = "¡Soy una madeja, no una hilacha!", Bye = "¡Me rindo! ¡Pero hay muchas más ahí arriba!" },
				} },
			{ Type = "Scene", Dialogue = "Informe", Actors = { COSME, PIP, ESCAMAS } },
		},
		Dialogues = {
			Credencial = { Lines = {
				{ S = "Cosme", T = "Criatura. Ya no eres tan criatura. Pero te lo sigo llamando. Te he hecho esto." },
				{ S = "Narrador", T = "Una credencial plastificada: «AYUDANTE OFICIAL DEL LABORATORIO COSME. Nivel: casi de confianza». Tiene tu foto del instituto. Sales fatal." },
				{ S = "Cosme", T = "La costura del cielo se está soltando. Punto a punto. Lo dije: las costuras siempre se sueltan. Lo dijo… otro. Bah." },
				{ S = "DonEscamas", T = "(Desde la pecera) Y hay más: MegaVerso ha pedido permiso para abrir una oficina en el Distrito Financiero. Lo sé porque todavía me llegan sus boletines. Soy de los que no se dan de baja." },
				{ S = "Pip", T = "El medidor marca tres puntos. El señor Cosme no puede ir: le duele la espalda. Y el orgullo. Sobre todo el orgullo." },
			} },
			Punto1 = { Lines = {
				{ S = "Narrador", T = "Del cielo caen hilos verdes, finísimos, como si alguien deshiciera un jersey allá arriba. Donde tocan el suelo, algo se mueve." },
			} },
			Punto2 = { Lines = {
				{ S = "Narrador", T = "Una pantalla nueva en la plaza: «MegaVerso S.A. — ¿Cansado de tu dimensión? ¡Prueba otra! Próximamente, la GRAN FUSIÓN. Compra ya tu entrada»." },
				{ S = "Narrador", T = "Nadie más parece verla. La gente pasa por delante como si fuera una pared." },
			} },
			Punto3 = { Lines = {
				{ S = "Narrador", T = "En el patio del instituto, un cristal clavado en el suelo zumba. Es uno de tus anclajes de hace años… agrietado." },
			} },
			Informe = { Lines = {
				{ S = "Cosme", T = "Hilachas. La costura se deshace y se escapan los hilos. Y un anuncio de MegaVerso que solo ven los que han visto la Grieta. Muy listos. Muy malvados. Muy de él." },
				{ S = "Yo", T = "¿De Cósimo?" },
				{ S = "Cosme", T = "…Sí. De Cósimo. Te prometí contártelo cuando fueras mayor. Aún no eres tan mayor. Pero Pip tiene un archivo. Algún día." },
				{ S = "Narrador", T = "Recibes 💳 la Credencial de ayudante oficial. Es oficial: trabajas para un inventor loco. Sin sueldo." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 8 · MegaVerso S.A.
	---------------------------------------------------------------------
	{
		Id = "Saga_08_MegaVerso",
		Kind = "Side",
		Canon = true,
		Title = "MegaVerso S.A.",
		Description = "El Consorcio ha abierto oficina en el Distrito Financiero. Moqueta gris, plantas de plástico y una recepcionista que sonríe sin parpadear. Hay que entrar.",
		Type = "Saga de la Grieta · Acto II (2/6)",
		Duration = { 25, 35 },
		Npcs = { "AgenteGris2", "AgenteGris1", "RobotSeguridad" },
		Offer = { Place = OFICINA },
		OfferKey = "La oficina de MegaVerso S.A. ya está abierta. Nadie más la ve. Tú sí",
		Requires = after("Saga_07_Costuras"),
		Moment = "Descubriste el Proyecto Fusión",
		Memory = "ProyectoFusion",
		Rewards = { Items = { FolletoMegaVerso = 1 }, Flags = { "SabeFusion" } },
		Props = {
			Folletos = { Kind = "Papel", Name = "Folletos de colores", Prompt = "Coger un folleto", Place = OFICINA, Offset = V(-4, 0, 3), Dialogue = "Folleto", Once = true },
			Ordenador = { Kind = "Pantalla", Name = "Un ordenador encendido", Prompt = "Mirar la pantalla", Place = OFICINA, Offset = V(4, 0, 5), Dialogue = "Ordenador", Once = true },
			Mapa = { Kind = "Mural", Name = "Un mapa de Valmar en la pared", Prompt = "Mirar el mapa", Place = OFICINA, Offset = V(0, 0, 8), Color = Color3.fromRGB(230, 230, 220), Dialogue = "Mapa", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "AgenteGris2", Dialogue = "Recepcion", Text = "Entra en la oficina. La recepcionista sonríe",
				Actors = { { Npc = "AgenteGris2", Place = OFICINA, Offset = V(0, 0, 3) } } },
			{ Type = "Group", Text = "Mientras nadie mira, busca información",
				Actors = { { Npc = "AgenteGris2", Place = OFICINA, Offset = V(0, 0, 3), Mode = "Chat" }, { Npc = "AgenteGris1", Place = OFICINA, Offset = V(2, 0, 4), Mode = "Chat" } },
				Steps = {
					{ Type = "Use", Prop = "Folletos", Text = "Los folletos" },
					{ Type = "Use", Prop = "Ordenador", Text = "El ordenador" },
					{ Type = "Use", Prop = "Mapa", Text = "El mapa de la pared" },
				} },
			{ Type = "Escape", Place = "PlazaFinanciera", Respawn = OFICINA, Catch = 4,
				Text = "¡Te han visto! Sal de la oficina hasta la plaza del Distrito Financiero",
				CaughtLine = "Tiene usted una llamada de ventas. Tiene usted una llamada de ventas. (Te zafas y vuelves a intentarlo.)",
				Actors = {
					{ Npc = "RobotSeguridad", Place = OFICINA, Offset = V(-6, 0, 8), Mode = "Hunt", Speed = 11, Prompt = false },
					{ Npc = "AgenteGris1", Place = OFICINA, Offset = V(6, 0, 8), Mode = "Hunt", Speed = 12, Prompt = false },
				} },
			{ Type = "Scene", Dialogue = "Fuera" },
		},
		Dialogues = {
			Recepcion = { Lines = {
				{ S = "AgenteGris2", T = "¡Bienvenido o bienvenida a MegaVerso S.A.! ¿Viene por las vacaciones dimensionales? ¿Por la tarjeta de fidelización? ¿O por la Gran Fusión?" },
				{ Ask = "¿Qué le dices?", Options = {
					{ T = "«Vengo a informarme. Soy de un colegio. Trabajo de clase.»", Effects = { Traits = { Humor = 1 } }, Then = {
						{ S = "AgenteGris2", T = "¡Qué adorable! Sírvase usted mismo. Las cámaras solo graban a los adultos. Es nuestra política de privacidad." },
					} },
					{ T = "Enseñas la credencial de ayudante de Cosme", Effects = { Traits = { Valentia = 1 }, Flags = { "EnseñasteCredencial" } }, Then = {
						{ S = "AgenteGris2", T = "¿Laboratorio… Cosme? …Un momento, por favor. Voy a consultar con mi… con la máquina de café. Sírvase usted mismo." },
					} },
				} },
			} },
			Folleto = { Lines = {
				{ S = "Narrador", T = "«¡Cambia de vida sin cambiar de casa! MegaVerso fusiona tu dimensión con otra mejor. Más luz, más ofertas, más perilla»." },
				{ S = "Narrador", T = "Letra pequeña: «La dimensión fusionada pasa a ser propiedad de MegaVerso S.A. y de su socio científico, el Dr. C.»." },
			} },
			Ordenador = { Lines = {
				{ S = "Narrador", T = "Una hoja de cálculo: «PROYECTO FUSIÓN — Valmar (dim. principal) + Valmar (dim. 66-B)». Estado: «bloqueado». Motivo: «el Ancla»." },
				{ S = "Narrador", T = "Fecha prevista de desbloqueo: «Graduación del Ancla (instituto). La costura estará suficientemente débil»." },
				{ S = "Narrador", T = "Tu graduación. Hablan de TU graduación." },
			} },
			Mapa = { Lines = {
				{ S = "Narrador", T = "Un mapa de Valmar con chinchetas rojas en tres sitios: el parque, el patio del cole y la plaza. Tus anclajes de hace años. Todos tachados." },
				{ S = "Narrador", T = "Y una chincheta dorada en una casa de Los Pinos. La tuya. Con una etiqueta: «ANCLA»." },
				{ S = "RobotSeguridad", T = "Detectado visitante no autorizado. Tiene usted una llamada de ventas. Tiene usted una llamada de ventas." },
			} },
			Fuera = { Lines = {
				{ S = "Narrador", T = "Llegas a la plaza sin aliento. Detrás de ti, la puerta de MegaVerso se cierra sola. En el cristal, el reflejo de un hombre con perilla sonríe un segundo y desaparece." },
				{ S = "Narrador", T = "Te llevas un folleto arrugado. Recibes 📄 el Folleto de MegaVerso. Hay que contárselo a Cosme. Y hay que saber qué es eso del Ancla. Ya." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 9 · El archivo de Pip
	---------------------------------------------------------------------
	{
		Id = "Saga_09_Archivo",
		Kind = "Side",
		Canon = true,
		Title = "El archivo de Pip",
		Description = "Pip guarda un archivo secreto que Cosme le prohibió abrir. Esta noche, con Cosme dormido, Pip ha decidido que ya es hora.",
		Type = "Saga de la Grieta · Acto II (3/6)",
		Duration = { 25, 35 },
		Npcs = { "Pip", "Cosme", "DonEscamas" },
		Offer = { Place = "GarajeCosme" },
		OfferKey = "Pip te espera en la puerta del garaje, de noche, con una caja y cara de estar desobedeciendo",
		Requires = after("Saga_08_MegaVerso", { Hours = { From = 20, To = 6 } }),
		Moment = "Supiste que eres el Ancla",
		Memory = "EresElAncla",
		Rewards = { Items = { CintaArchivo = 1 }, Flags = { "SabeQueEsAncla" } },
		Props = {
			Caja = { Kind = "Caja", Name = "El archivo de Pip", Prompt = "Abrir el archivo", Place = "GarajeCosme", Offset = V(-2, 0, 2), Color = Color3.fromRGB(120, 120, 140), Dialogue = "Caja", Once = true },
			Proyector = { Kind = "Maquina", Name = "Un proyector antiguo", Prompt = "Poner la cinta", Place = "GarajeCosme", Offset = V(2, 0, 2), Dialogue = "Proyector", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Pip", Dialogue = "Pip", Text = "Habla con Pip", Actors = { PIP, ESCAMAS } },
			{ Type = "Use", Prop = "Caja", Text = "Abre el archivo", Actors = { PIP } },
			{ Type = "Use", Prop = "Proyector", Text = "Pon la cinta en el proyector", Actors = { PIP } },
			{ Type = "Talk", Npc = "Cosme", Dialogue = "Cosme", Text = "Cosme se ha despertado. Te está mirando desde la puerta",
				Actors = { { Npc = "Cosme", Place = "GarajeCosme", Offset = V(0, 0, 5) }, PIP } },
		},
		Dialogues = {
			Pip = { Lines = {
				{ S = "Pip", T = "Buenas noches. Estoy a punto de desobedecer una orden directa del señor Cosme. Es la primera vez en veintitrés años. Me tiemblan los tornillos." },
				{ S = "Pip", T = "El señor Cosme cree que le protege no contándoselo. Yo creo que ya no le protege. Solo le deja a oscuras. Y a oscuras se tropieza." },
				{ S = "DonEscamas", T = "(Desde la pecera) Yo voto por contarlo todo. Aunque yo siempre voto por contarlo todo. Es mi problema." },
			} },
			Caja = { Lines = {
				{ S = "Narrador", T = "Dentro de la caja: planos del «Proyecto Costura», una bata chamuscada, una foto de dos jóvenes iguales delante de una máquina… y una cinta de vídeo con una etiqueta: «LA NOCHE»." },
				{ S = "Narrador", T = "Esa foto ya la has visto. Estaba en el suelo del Pabellón 0 de la universidad.", If = { Flags = { "VioPabellon0" } } },
			} },
			Proyector = { Lines = {
				{ S = "Narrador", T = "La cinta. Un laboratorio escondido en el campus. Dos jóvenes con bata, Cosme y Cósimo, delante de la Cosedora Dimensional. Ríen. Brindan con batido de apio." },
				{ S = "Cosme", T = "(En la cinta, joven) Prueba número uno. Vamos a coser dos dimensiones un milímetro. Solo un milímetro. Para ver qué pasa." },
				{ S = "Cosimo", T = "(En la cinta, joven, sin perilla) Un milímetro hoy. Un universo mañana. Imagínatelo, Cosme: dos Valmar en una. Todo lo mejor de las dos." },
				{ S = "Narrador", T = "La máquina se enciende. Algo sale mal: un chispazo verde abre una línea en el aire. La línea crece, tira de todo hacia ella. Cósimo resbala. Cosme le agarra de la mano. Se sueltan." },
				{ S = "Narrador", T = "Cósimo cae al otro lado. La línea se hace enorme… y de repente se frena. Algo la sujeta. Algo pequeño, a pocas calles, en una casa de Los Pinos." },
				{ S = "Narrador", T = "En esa casa, a esa misma hora, acaba de nacer un bebé. La Grieta se ha agarrado a lo único que había cerca: a ti." },
				{ S = "Cosme", T = "(En la cinta, solo, llorando) Mientras ese bebé esté en esta Valmar, la grieta no se abrirá del todo. Es… un ancla. Le vigilaré. Toda la vida. Sin que lo sepa. Se lo debo." },
			} },
			Cosme = { Lines = {
				{ S = "Cosme", T = "…Pip. Te dije que nunca." },
				{ S = "Pip", T = "Lo sé, señor. Y usted me dijo que el día que tuviera que elegir entre obedecerle y cuidarle, le cuidara. También me lo dijo." },
				{ Ask = "Cosme te mira. ¿Qué le dices?", Options = {
					{ T = "«Llevas toda mi vida cuidándome. Gracias.»", Effects = { Rel = { Cosme = 12 }, Traits = { Empatia = 2 }, Flags = { "PerdonaACosme" } }, Then = {
						{ S = "Cosme", T = "No me des las gracias. La grieta es culpa mía. Tú… tú eres lo único bueno que salió de aquella noche. Aunque no fuera a propósito." },
					} },
					{ T = "«¿Por qué no me lo dijiste antes?»", Effects = { Rel = { Cosme = 4 }, Traits = { Valentia = 1 }, Flags = { "EnfadoConCosme" } }, Then = {
						{ S = "Cosme", T = "Porque tenías seis años y te gustaban las burbujas. ¿Cómo le dices a alguien de seis años que sujeta el universo con una mano?" },
						{ S = "Cosme", T = "…Tienes razón. Debí hacerlo antes. Perdón. No se me dan bien los perdones. Se me dan bien las explosiones." },
					} },
				} },
				{ S = "Cosme", T = "Cósimo quiere la Fusión. Para eso necesita que sueltes el ancla. Que te vayas de esta Valmar, o que la costura se rompa del todo. Y MegaVerso le paga el laboratorio." },
				{ S = "Narrador", T = "Pip te da la cinta. «Es suya. Es su historia». Recibes 📼 la Cinta de «La noche»." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 10 · La fiesta del fin del mundo
	---------------------------------------------------------------------
	{
		Id = "Saga_10_Fiesta",
		Kind = "Side",
		Canon = true,
		Title = "La fiesta del fin del mundo",
		Description = "MegaVerso organiza una fiesta en la plaza para vender entradas para la Gran Fusión. Música, confeti… y una cuenta atrás gigante.",
		Type = "Saga de la Grieta · Acto II (4/6)",
		Duration = { 25, 35 },
		Npcs = { "AgenteGris1", "AgenteGris2", "RobotSeguridad", "Nico", "Omar", "Sara" },
		Offer = { Place = "PlazaCentro" },
		OfferKey = "Fiesta de MegaVerso en la plaza. Hay una cuenta atrás gigante en el cielo que solo tú ves",
		Requires = after("Saga_09_Archivo", { Hours = { From = 18, To = 2 } }),
		Moment = "Saboteaste la fiesta de MegaVerso",
		Memory = "FiestaFinDelMundo",
		Rewards = { Flags = { "FiestaSaboteada" }, Money = 30 },
		Props = {
			Cabina = { Kind = "Maquina", Name = "La cabina del DJ de MegaVerso", Prompt = "Cambiar la música", Place = "PlazaCentro", Offset = V(-6, 0, -6), Color = Color3.fromRGB(110, 110, 120), Dialogue = "Cabina", Once = true },
			Taquilla = { Kind = "Kiosco", Name = "La taquilla de entradas para la Fusión", Prompt = "Atascar la máquina de entradas", Place = "PlazaCentro", Offset = V(6, 0, -6), Dialogue = "Taquilla", Once = true },
			Cuenta = { Kind = "Pantalla", Name = "La cuenta atrás", Prompt = "Desenchufar la cuenta atrás", Place = "PlazaCentro", Offset = V(0, 0, -10), Color = Color3.fromRGB(255, 80, 80), Dialogue = "Cuenta", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Omar", Dialogue = "Amigos", Text = "Tus amigos están en la fiesta. Habla con Omar",
				Actors = {
					{ Npc = "Omar", Place = "PlazaCentro", Offset = V(6, 0, 6) },
					{ Npc = "Nico", Place = "PlazaCentro", Offset = V(4, 0, 8), Mode = "Dance" },
					{ Npc = "Sara", Place = "PlazaCentro", Offset = V(8, 0, 8), Mode = "Chat" },
				} },
			{ Type = "Group", Text = "Sabotea la fiesta sin que te vean",
				Actors = {
					{ Npc = "AgenteGris1", Place = "PlazaCentro", Offset = V(-8, 0, 2), Mode = "Wander", Prompt = false },
					{ Npc = "Omar", Mode = "Follow" },
				},
				Steps = {
					{ Type = "Use", Prop = "Cabina", Text = "La cabina del DJ" },
					{ Type = "Use", Prop = "Taquilla", Text = "La taquilla de entradas" },
					{ Type = "Use", Prop = "Cuenta", Text = "La cuenta atrás" },
				} },
			{ Type = "Fight", Place = "PlazaCentro", Respawn = "PlazaCentro", Action = "Quitarle el comunicador 📡", HP = 3, BeamColor = Color3.fromRGB(120, 255, 160),
				Text = "¡Te han descubierto! Deshazte de los de MegaVerso ({count}/{total})",
				CaughtLine = "¡Oferta de fin del mundo! ¡Firme aquí! (Omar te saca de ahí a empujones.)",
				Actors = { { Npc = "Omar", Place = "PlazaCentro", Offset = V(6, 0, 6), Mode = "Cheer" } },
				Enemies = {
					{ Npc = "AgenteGris1", Offset = V(-8, 0, 2), Speed = 12, Bye = "¡Esto no quedará así! ¡Llamaré a atención al cliente!" },
					{ Npc = "AgenteGris2", Offset = V(8, 0, 2), Speed = 12, Bye = "¡Su satisfacción es nuestra prioridad! …Me voy." },
					{ Npc = "RobotSeguridad", Offset = V(0, 0, -8), Speed = 10, HP = 5, Hurt = "Tiene usted una… llamada… de…", Bye = "Llamada… finalizada. (Se apaga.)" },
				} },
			{ Type = "Scene", Dialogue = "Final",
				Actors = {
					{ Npc = "Omar", Place = "PlazaCentro", Offset = V(6, 0, 6) },
					{ Npc = "Nico", Place = "PlazaCentro", Offset = V(4, 0, 8) },
					{ Npc = "Sara", Place = "PlazaCentro", Offset = V(8, 0, 8) },
				} },
		},
		Dialogues = {
			Amigos = { Lines = {
				{ S = "Omar", T = "¡Fiesta gratis! Confeti, refrescos, música… Y una pantalla que dice «Fusión: faltan 90 días». ¿Fusión de qué? ¿De sabores de helado?" },
				{ S = "Omar", T = "Espera. …¿Tú ves algo en el cielo? Porque yo estoy viendo unos números enormes que antes no veía. Desde que me contaste lo de la Grieta, veo cosas raras. Gracias, supongo." },
				{ S = "Omar", T = "¿Qué hacemos? ¿Plan? ¿Tienes un plan? Dime que tienes un plan. Yo te cubro." },
			} },
			Cabina = { Lines = {
				{ S = "Narrador", T = "Cambias la playlist de MegaVerso («Éxitos para fusionarse») por la música del camión de los helados. La gente deja de bailar como hipnotizada y empieza a bailar como personas normales." },
			} },
			Taquilla = { Lines = {
				{ S = "Narrador", T = "Metes el folleto de MegaVerso por la ranura de las monedas. La máquina tose, pita y empieza a imprimir entradas que ponen «NO». Cientos. Miles." },
			} },
			Cuenta = { Lines = {
				{ S = "Narrador", T = "Desenchufas la cuenta atrás. La pantalla parpadea y, antes de apagarse, muestra un segundo una cara con perilla: «Qué maleducado»." },
			} },
			Final = { Lines = {
				{ S = "Nico", T = "¿Qué ha pasado? La fiesta estaba genial y de repente… ¿por qué todo el mundo tiene una entrada que pone «NO»?" },
				{ S = "Sara", T = "Estadísticamente, hoy ha pasado algo muy raro. Y tú estabas en medio. Como siempre. Te lo apunto." },
				{ S = "Omar", T = "Hemos salvado una fiesta. O el mundo. No lo sé. Pero ha sido lo mejor del curso. …Oye. Tu graduación es dentro de poco. ¿Eso tiene algo que ver con los números del cielo?" },
				{ S = "Narrador", T = "No le contestas. En el cielo, antes de apagarse, los números marcaban exactamente el día de tu graduación." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 11 · Cronos cambia de bando
	---------------------------------------------------------------------
	{
		Id = "Saga_11_Cronos",
		Kind = "Side",
		Canon = true,
		Title = "Cronos cambia de bando",
		Description = "El agente Cronos, el de la Aduana del Tiempo, te busca. Esta vez no trae una multa. Trae un problema: alguien falsifica formularios.",
		Type = "Saga de la Grieta · Acto II (5/6)",
		Duration = { 20, 30 },
		Npcs = { "CazadorTiempo", "AgenteGris2", "Funcionaria" },
		Offer = { Place = "PatioInstituto" },
		OfferKey = "Un señor con traje y cuarenta formularios te espera en el patio del instituto. Te suena",
		Requires = after("Saga_10_Fiesta"),
		Moment = "Cronos se unió a tu bando",
		Memory = "CronosAliado",
		Rewards = { Items = { RelojArena = 1 } },
		Props = {
			Formularios = { Kind = "Papel", Name = "Una carpeta de formularios", Prompt = "Revisar los formularios", Place = "Correos", Offset = V(3, 0, 3), Dialogue = "Formularios", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "CazadorTiempo", Dialogue = "Cronos", Text = "Habla con el agente Cronos",
				Actors = { { Npc = "CazadorTiempo", Place = "PatioInstituto", Offset = V(0, 0, 4) } } },
			{ Type = "Talk", Npc = "Funcionaria", Dialogue = "Ventanilla", Text = "La funcionaria de las ventanillas sabe quién entrega formularios (Correos)",
				Actors = { { Npc = "Funcionaria", Place = "Correos", Offset = V(0, 0, 3) } } },
			{ Type = "Use", Prop = "Formularios", Text = "Revisa los formularios del Consorcio", Actors = { { Npc = "Funcionaria", Place = "Correos", Offset = V(0, 0, 3) } } },
			{ Type = "Chase", Npc = "AgenteGris2", Catch = 6, Text = "¡La agente gris que los entrega está ahí mismo! ¡Atrápala!",
				Actors = {
					{ Npc = "AgenteGris2", Place = "Correos", Offset = V(6, 0, 6), Mode = "Flee", Speed = 14, Prompt = false,
						Route = { "Correos", "PlazaCentro", "CafeteriaCentral", "Parque" } },
					{ Npc = "CazadorTiempo", Mode = "Follow" },
				} },
			{ Type = "Scene", Dialogue = "Pillada",
				Actors = { { Npc = "AgenteGris2", Place = "Parque", Offset = V(0, 0, 3) }, { Npc = "CazadorTiempo", Place = "Parque", Offset = V(3, 0, 3) } } },
		},
		Dialogues = {
			Cronos = { Lines = {
				{ S = "CazadorTiempo", T = "Pequeño humano. Bueno, ya no tan pequeño. Mi agenda del futuro decía que hoy hablaríamos. Mi agenda nunca falla. Casi nunca." },
				{ S = "CazadorTiempo", T = "Alguien está metiendo formularios falsos en la Aduana: permisos de Fusión dimensional, sellados con MI sello. Yo no los he sellado. Mi sello tiene un arañazo. Estos no." },
				{ S = "CazadorTiempo", T = "Si la Aduana aprueba esos permisos, la Fusión será legal. Y contra algo legal, ni yo puedo hacer nada. Necesito pruebas. Y alguien rápido. Yo corro poco." },
			} },
			Ventanilla = { Lines = {
				{ S = "Funcionaria", T = "¿Formularios falsos? Hija, hijo, llevo trescientos años en ventanillas. Los formularios falsos huelen diferente. Huelen a colonia cara." },
				{ S = "Funcionaria", T = "Esta mañana una señora de gris dejó una carpeta. Sonreía sin parpadear. Ahí la tienes. Y ahí está ella, en la puerta. Mírala qué tranquila." },
			} },
			Formularios = { Lines = {
				{ S = "Narrador", T = "Permisos de Fusión dimensional, todos sellados. Pero al sello le falta el arañazo. Y la firma pone «Crono». Sin s. Muy mal falsificado." },
			} },
			Pillada = { Lines = {
				{ S = "AgenteGris2", T = "¡Vale! ¡Vale! ¡Me rindo! Solo soy de atención al cliente. El Dr. Cósimo me dijo que era un trámite normal. «Sonríe y entrega», dijo." },
				{ S = "CazadorTiempo", T = "Falsificación de formulario temporal. Treinta años de papeleo en la Aduana. Sin sello propio." },
				{ Ask = "Cronos te mira: «¿Qué opinas tú?»", Options = {
					{ T = "«Que ayude a pararlo todo. Una segunda oportunidad.»", Effects = { Flags = { "CronosAliado", "GrisArrepentida" }, Traits = { Empatia = 1 } }, Then = {
						{ S = "AgenteGris2", T = "¿Yo? ¿Ayudar? …Nunca nadie me había ofrecido algo sin letra pequeña. Acepto. De verdad. Sin sonreír." },
					} },
					{ T = "«Que cumpla su castigo. Las normas son las normas.»", Effects = { Flags = { "CronosAliado" }, Traits = { Responsabilidad = 1 } }, Then = {
						{ S = "CazadorTiempo", T = "Las normas son las normas. Lo diré en el tribunal. Y lo pondré en un póster." },
					} },
				} },
				{ S = "CazadorTiempo", T = "Durante cuatrocientos años he perseguido a quien se salta el tiempo. Hoy me doy cuenta de que el que se salta todo es el Consorcio. A partir de hoy, estoy de tu lado. Oficialmente. Con formulario." },
				{ S = "CazadorTiempo", T = "Toma: un reloj de arena de la Aduana. Cuando la cosa se ponga fea, gíralo. Llegaré. Tarde, pero llegaré." },
				{ S = "Narrador", T = "Recibes ⏳ el Reloj de arena de Cronos." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 12 · Graduación interdimensional (final del Acto II)
	---------------------------------------------------------------------
	{
		Id = "Saga_12_Graduacion",
		Kind = "Side",
		Canon = true,
		Title = "Graduación interdimensional",
		Description = "El día de tu graduación del instituto. La fecha que marcaba la cuenta atrás. Cosme ha venido «por casualidad». Con una aguja nueva en el bolsillo.",
		Type = "Saga de la Grieta · Acto II (6/6) · Final del acto",
		Duration = { 30, 40 },
		Npcs = { "Cosme", "Pip", "Cosimo", "DronCosimo1", "DronCosimo2", "DronCosimo3", "Omar", "Sara", "Nico" },
		Offer = { Place = "PatioInstituto" },
		OfferKey = "Día de graduación. En el cielo, sobre el instituto, la costura brilla más que nunca",
		Requires = { Stage = { Min = "Adolescente" }, Completed = { "Saga_11_Cronos" } },
		Moment = "El día que Cósimo se llevó a Cosme",
		Memory = "GraduacionInterdimensional",
		Rewards = { Items = { BataChamuscada = 1 }, Flags = { "SagaActo2", "CosmeSecuestrado" } },
		Steps = {
			{ Type = "Talk", Npc = "Cosme", Dialogue = "Casualidad", Text = "Cosme ha venido a tu graduación. «Por casualidad»",
				Actors = {
					{ Npc = "Cosme", Place = "PatioInstituto", Offset = V(0, 0, 5) },
					{ Npc = "Omar", Place = "PatioInstituto", Offset = V(-5, 0, 6), Mode = "Chat" },
					{ Npc = "Sara", Place = "PatioInstituto", Offset = V(-3, 0, 8), Mode = "Chat" },
					{ Npc = "Nico", Place = "PatioInstituto", Offset = V(5, 0, 7), Mode = "Cheer" },
				} },
			{ Type = "Cinematic", Id = "Saga_Grieta2" },
			{ Type = "Scene", Dialogue = "Cosimo",
				Actors = {
					{ Npc = "Cosimo", Place = "PatioInstituto", Offset = V(0, 0, -8) },
					{ Npc = "Cosme", Place = "PatioInstituto", Offset = V(2, 0, 3) },
				} },
			{ Type = "Fight", Place = "PatioInstituto", Respawn = "PatioInstituto", Action = "Pinchar con la aguja 🪡", HP = 3, BeamColor = Color3.fromRGB(120, 255, 160),
				Text = "¡Los drones de Cósimo! Protege a tus amigos ({count}/{total})",
				CaughtLine = "¡Aplausos para el concursante! (Te llevan en volandas y te sueltan en la otra punta del patio.)",
				Actors = {
					{ Npc = "Cosme", Place = "PatioInstituto", Offset = V(2, 0, 3) },
					{ Npc = "Omar", Place = "PatioInstituto", Offset = V(-5, 0, 6), Mode = "Point" },
				},
				Enemies = {
					{ Npc = "DronCosimo1", Offset = V(-8, 0, -4), Speed = 13, Bye = "¡Bzzt! ¡Eliminado del concurso!" },
					{ Npc = "DronCosimo2", Offset = V(8, 0, -4), Speed = 13, Bye = "¡Bzzt! ¡Vuelvo al plató!" },
					{ Npc = "DronCosimo3", Offset = V(0, 0, -10), Speed = 14, HP = 5, Hurt = "¡Mi pajarita! ¡Es de estreno!", Bye = "¡Nos vemos… después de la publicidad!" },
				} },
			{ Type = "Scene", Dialogue = "Secuestro",
				Actors = {
					{ Npc = "Cosimo", Place = "PatioInstituto", Offset = V(0, 0, -8) },
					{ Npc = "Cosme", Place = "PatioInstituto", Offset = V(0, 0, -6) },
					{ Npc = "Omar", Place = "PatioInstituto", Offset = V(-5, 0, 6) },
					{ Npc = "Sara", Place = "PatioInstituto", Offset = V(-3, 0, 8) },
				} },
		},
		Dialogues = {
			Casualidad = { Lines = {
				{ S = "Cosme", T = "¡Qué casualidad! Pasaba por aquí. Con mi mejor bata. Y una aguja nueva. Y veinte chicles, por si acaso. Casualidad total." },
				{ S = "Cosme", T = "…Vale. He venido porque hoy es el día que marcaba la cuenta atrás. Y porque es tu graduación. Por las dos cosas. Más por la segunda." },
				{ S = "Omar", T = "¿Ese es el vecino? ¿El de la gallina gigante? ¡Qué honor! ¿Me firma la bata?" },
			} },
			Cosimo = { Lines = {
				{ S = "Narrador", T = "La costura del cielo se rompe con un sonido de cremallera gigante. Del agujero baja, flotando en una plataforma dorada, un hombre de pelo blanco muy peinado. Con perilla." },
				{ S = "Cosimo", T = "¡{Saludo}, Valmar! ¡Y enhorabuena a los graduados! Qué emocionante. Me encantan las graduaciones. Hay tantos finales." },
				{ S = "Cosimo", T = "Hola, Cosme. Hola, Ancla. Qué grande estás. La última vez que te vi en persona eras un bebé que no sabía que sujetaba el universo." },
				{ S = "Cosme", T = "Cósimo. Vete. Esto no es tuyo." },
				{ S = "Cosimo", T = "Todo es mío, Cosme. Lo será. Solo necesito que la costura ceda un poco más. Y tengo ayudantes. ¡Chicos!" },
			} },
			Secuestro = { Lines = {
				{ S = "Cosimo", T = "Bravo. Bravísimo. Sabes pelear. Te lo enseñó él, ¿no? Siempre fue un buen profesor. Por eso me lo llevo." },
				{ S = "Narrador", T = "Un rayo dorado envuelve a Cosme. Intentas agarrarle de la mano. Como en la cinta. Como aquella noche. Se te escurre." },
				{ S = "Cosme", T = "¡Criatura! ¡No sueltes el ancla! ¡Pase lo que pase, quédate en esta Valmar! ¡Pip sabe qué hacer! …¡Y aliméntale el pez!" },
				{ S = "Cosimo", T = "Nos vemos en la universidad, Ancla. Estudia mucho. Los finales siempre son lo más difícil.", If = { Flags = { "VaALaUniversidad" } } },
				{ S = "Cosimo", T = "Nos vemos pronto, Ancla. Los finales siempre son lo más difícil.", If = { NotFlags = { "VaALaUniversidad" } } },
				{ S = "Narrador", T = "El agujero se cierra con otro sonido de cremallera. Silencio. Tus compañeros te miran. Omar recoge del suelo la bata de Cosme, chamuscada." },
				{ S = "Omar", T = "…Vale. Ahora sí que me lo tienes que contar todo. Todo. Desde el principio." },
				{ S = "Narrador", T = "Recibes 🥼 la Bata chamuscada de Cosme. FIN DEL ACTO II. Cosme ha desaparecido." },
			} },
		},
	},
}
