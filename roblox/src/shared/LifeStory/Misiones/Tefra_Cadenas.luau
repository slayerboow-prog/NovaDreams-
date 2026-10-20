-- SAGA 2 · TEFRA · CADENAS SECUNDARIAS (docs/planetas/diseno-mundos.md §3.1.17; docs/planetas/tefra-misiones.md).
-- Secundarias que se OFRECEN (se pueden rechazar sin castigo) en Bastión Ceniza. Solo en Tefra.
--
--   B Tefra_Brasa     «El padre de Brasa»  (se abre si ayudaste a Brasa en «La casa de Cosme»)
--                     preguntar por los barrios → colarse en los calabozos → seguir a Murria hasta las
--                     Trincheras → desactivar el campo de minas → Murria llega (decisión)
--   D Tefra_Papeles   «Papeles»            el control de la armería → los materiales del falsificador →
--                     quieto para la foto → el control de la Capitana Ferra (decisión)
--   G Tefra_Candados  «Candados»           (después del alto el fuego) el pan de sirena con Ernesto → el
--                     candado de Ada entre mil → llevar a Cosme al puente. Sin decisiones: un silencio.

local V = Vector3.new

local function req(extra: { [string]: any }): { [string]: any }
	local r: { [string]: any } = { Stage = { Min = "Adulto" }, Planet = "Tefra" }
	for key, value in extra do
		r[key] = value
	end
	return r
end

local function at(npc: string, place: string, x: number, z: number, mode: string?): { [string]: any }
	return { Npc = npc, Place = place, Offset = V(x, 0, z), Mode = mode }
end

return {
	---------------------------------------------------------------------
	-- B · El padre de Brasa
	--   Personajes: Brasa (12, lista y deslenguada), su padre Galo (desertor buscado), el Sargento Murria
	--   (cazador de desertores que perdió a su hijo en Ovilla).
	--   Trasfondo: Galo desertó para no dejar sola a Brasa cuando murió su madre.
	--   Giro: Murria no quiere detener a Galo: quiere saber cómo murió su hijo (Galo estaba allí).
	--   Lazo con el Ragnarock: la guerra separa familias; el enemigo también ha perdido a alguien.
	---------------------------------------------------------------------
	{
		Id = "Tefra_Brasa",
		Kind = "Side",
		Title = "El padre de Brasa",
		Description = "Brasa, la niña que escondiste en el Ovillo, te paga con un dibujo para que busques a su padre. Lleva meses sin saber de él.",
		Type = "Saga 2 · Tefra · Cadena secundaria",
		Duration = { 35, 45 },
		Npcs = { "Brasa", "MadreHollin", "ErnestoPanadero", "SargentoMurria", "GaloPadre" },
		Offer = { Place = "Tefra_PuestoHollin" },
		OfferKey = "Brasa te tira de la manga: «Eh, tú. Te pago con esto»",
		Requires = req({ Completed = { "Tefra_02_Casa" }, Flags = { "BrasaAyudada" } }),
		Moment = "Brasa encontró a su padre",
		Memory = "PadreDeBrasa",
		Rewards = { Money = 150, Flags = { "BrasaVendedora" }, Items = { SetaCeniza = 3 } },
		Props = {
			Registro = { Kind = "Libro", Name = "El registro de los calabozos", Prompt = "Buscar «Galo»", Place = "Tefra_CalabozosDentro", Offset = V(0, 0, 2), Dialogue = "Registro", Once = true },
			Mina1 = { Kind = "Caja", Name = "Mina sin explotar", Prompt = "Desactivar", Place = "Tefra_TierraDeNadie", Offset = V(-8, 0, 6), Dialogue = "Mina1", Once = true },
			Mina2 = { Kind = "Caja", Name = "Mina sin explotar", Prompt = "Desactivar", Place = "Tefra_TierraDeNadie", Offset = V(6, 0, 10), Dialogue = "Mina2", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Brasa", Dialogue = "Dibujo", Text = "Habla con Brasa en el Mercado Espiral", Actors = { at("Brasa", "Tefra_PuestoHollin", 2, 2), at("MadreHollin", "Tefra_PuestoHollin", -2, -1) } },
			{ Type = "Group", Text = "Pregunta por Galo en los barrios (con dos pistas basta)", Need = 2,
				Actors = { at("MadreHollin", "Tefra_PuestoHollin", -2, -1), at("ErnestoPanadero", "Tefra_Panaderia", 2, 3), at("RefugiadoMayor", "Tefra_MiradorCentro", -3, 2) },
				Steps = {
					{ Type = "Talk", Npc = "MadreHollin", Dialogue = "Hollin", Text = "Madre Hollín (el Mercado)" },
					{ Type = "Talk", Npc = "ErnestoPanadero", Dialogue = "Ernesto", Text = "Ernesto (la Panadería del Ovillo)" },
					{ Type = "Talk", Npc = "RefugiadoMayor", Dialogue = "Refugiado", Text = "Un refugiado del Mirador" },
				} },
			{ Type = "Escape", Place = "Tefra_CalabozosDentro", Respawn = "Tefra_Calabozos", Catch = 4,
				Text = "Cuélate en los calabozos del Muelle sin que te vea el guardia",
				CaughtLine = "¡Fuera de aquí, curioso! (Te echan a la calle.)",
				Actors = { { Npc = "PoliciaMilitar2", Place = "Tefra_Calabozos", Offset = V(8, 0, 6), Mode = "Hunt", Speed = 9, Prompt = false } } },
			{ Type = "Use", Prop = "Registro", Text = "Busca a Galo en el registro de detenidos" },
			{ Type = "Reach", Place = "Tefra_TierraDeNadie", Text = "Sigue al Sargento Murria hasta las Trincheras del Este sin acercarte demasiado",
				Actors = { at("SargentoMurria", "Tefra_PuertaEste", 40, 10, "Wander") } },
			{ Type = "Group", Text = "Galo está atrapado en un campo de minas: desactiva las minas del camino",
				Actors = { at("GaloPadre", "Tefra_TierraDeNadie", 0, 18) },
				Steps = {
					{ Type = "Use", Prop = "Mina1", Text = "La mina de la izquierda" },
					{ Type = "Use", Prop = "Mina2", Text = "La mina de la derecha" },
				} },
			{ Type = "MiniGame", Game = "Timing", Title = "La última mina", Icon = "💣", Hint = "Corta el cable cuando la aguja esté quieta en el verde",
				Rounds = 3, Need = 2, Zone = 0.24, Speed = 1.1,
				Actors = { at("GaloPadre", "Tefra_TierraDeNadie", 0, 18) } },
			{ Type = "Scene", Dialogue = "Murria", Actors = { at("GaloPadre", "Tefra_TierraDeNadie", 0, 12), at("SargentoMurria", "Tefra_TierraDeNadie", -6, -4) } },
			{ Type = "Choice", Key = "TefraMurria", Text = "Murria no ha venido a detener a Galo: quiere saber cómo murió su hijo en Ovilla. Galo estaba allí. ¿Qué haces?",
				Options = {
					{ Id = "Hablar", Text = "Dejar que hablen (despacio: hay tiempo)", Effects = { Flags = { "MurriaEnPaz" }, Traits = { Empatia = 1 } } },
					{ Id = "Sacar", Text = "Sacar a Galo de ahí por la fuerza antes de que llegue la escuadra", Effects = { Flags = { "MurriaSigueCazando" }, Traits = { Valentia = 1 } } },
				},
				Actors = { at("GaloPadre", "Tefra_TierraDeNadie", 0, 12), at("SargentoMurria", "Tefra_TierraDeNadie", -6, -4) } },
			{ Type = "Scene", Dialogue = "Hablan", If = { Choices = { TefraMurria = "Hablar" } },
				Actors = { at("GaloPadre", "Tefra_TierraDeNadie", 0, 12), at("SargentoMurria", "Tefra_TierraDeNadie", -2, 8) } },
			{ Type = "Fight", Place = "Tefra_TierraDeNadie", Respawn = "Tefra_PuertaEste", Action = "Derribar 💥", HP = 5, If = { Choices = { TefraMurria = "Sacar" } },
				Text = "¡La escuadra de Murria! Abre paso para Galo ({count}/{total})",
				CaughtLine = "(Te tiran a una trinchera. Galo te ayuda a salir.)",
				Actors = { at("GaloPadre", "Tefra_TierraDeNadie", 0, 12, "Point") },
				Enemies = {
					{ Npc = "PoliciaMilitar1", Offset = V(-10, 0, -8), Speed = 10, HP = 3, Bye = "¡Se escapa el desertor!" },
					{ Npc = "PoliciaMilitar3", Offset = V(10, 0, -8), Speed = 11, HP = 3, Bye = "Que se lo diga Murria a quien quiera." },
				} },
			{ Type = "Scene", Dialogue = "Abrazo", Actors = { at("Brasa", "Tefra_PuertaEste", -2, 2), at("GaloPadre", "Tefra_PuertaEste", 2, 6) } },
		},
		Dialogues = {
			Dibujo = { Lines = {
				{ S = "Brasa", T = "Eh, tú. Me escondiste en el Ovillo. Ahora te toca otra cosa. Te pago con esto.", To = "Yo" },
				{ S = "Narrador", T = "Un dibujo a carboncillo: tú, Brasa y un hombre alto con bufanda. Debajo pone «PAPÁ»." },
				{ S = "Brasa", T = "Se llama Galo. Se fue de la Muralla cuando murió mamá. Para no dejarme sola. Y luego se fue también.", Beat = "Baja" },
				{ S = "Brasa", T = "No llores, que me haces llorar a mí. Búscalo. Tú sabes colarte en sitios.", A = "Angry" },
				{ S = "MadreHollin", T = "La cría paga con dibujos. Yo cobro en dinero. Pregúntame a mí también, forastero.", To = "Yo" },
			}, Effects = { Items = { DibujoBrasa = 1 } } },
			Hollin = { Lines = {
				{ S = "MadreHollin", T = "¿Galo? Desertor. Me compraba gel térmico para ir a las Trincheras. Mucho gel.", Shot = "Medio:MadreHollin" },
				{ S = "MadreHollin", T = "Quien compra tanto gel va a un sitio muy caliente. Y no vuelve a comprar.", A = "Shrug" },
			} },
			Ernesto = { Lines = {
				{ S = "ErnestoPanadero", T = "¿El padre de Brasa? Venía a por pan al amanecer. Siempre dos barras: una para él, otra «para el camino».", To = "Yo" },
				{ S = "ErnestoPanadero", T = "La última vez preguntó por las minas de las Trincheras. Que si se veían de día. Mala señal.", Beat = "Piensa" },
			} },
			Refugiado = { Lines = {
				{ S = "RefugiadoMayor", T = "Lo vi en el control de la Puerta Este. Se lo llevaron. Pero no a la Muralla: al Muelle.", To = "Yo" },
				{ S = "RefugiadoMayor", T = "Los del Muelle apuntan a todo el mundo en un libro. Hasta a los que sueltan.", G = "Point" },
			} },
			Registro = { Lines = {
				{ S = "Narrador", T = "«Galo, desertor. Detenido en la Puerta Este. Escapó en el traslado. Visto por última vez: Trincheras.»" },
				{ S = "Narrador", T = "Debajo, con otra letra: «Asunto del Sargento Murria. Que nadie más lo toque»." },
			} },
			Mina1 = { Lines = { { S = "Narrador", T = "Cable rojo, cable azul. La pista grabada dice: «el que no es rojo». Cortas el azul. Silencio. Bien." } } },
			Mina2 = { Lines = { { S = "Narrador", T = "Esta tiene tres cables. «El del medio.» Cortas el del medio. El detector deja de pitar." } } },
			Murria = { Lines = {
				{ S = "GaloPadre", T = "¿Quién eres? ¿Te manda Brasa? …Claro que te manda Brasa. Nadie más vendría a este sitio.", Shot = "Medio:GaloPadre" },
				{ S = "SargentoMurria", T = "Galo.", Shot = "Reaccion:SargentoMurria", Pause = 0.8 },
				{ S = "GaloPadre", T = "Sargento. Ya sabía que vendría usted. Llevo meses esperándole aquí.", Beat = "Respira" },
				{ S = "SargentoMurria", T = "No vengo a detenerte. Tú estabas en Ovilla cuando cayó mi hijo. Quiero saber cómo fue.", A = "Sad" },
				{ S = "SargentoMurria", T = "Solo eso. Llevo dos años cazando desertores para no pensar en eso.", Beat = "Baja" },
			} },
			Hablan = { Lines = {
				{ S = "GaloPadre", T = "Su hijo me sacó de una trinchera. Me salvó. Él no tuvo tanta suerte. No sufrió, sargento.", Pause = 1 },
				{ S = "SargentoMurria", T = "…Siempre fue más valiente que yo.", Shot = "PrimerPlano:SargentoMurria", Pause = 1.2, A = "Sad" },
				{ S = "SargentoMurria", T = "Vete con tu hija, Galo. Yo dejo esto. Ya he cazado bastante.", To = "GaloPadre" },
			} },
			Abrazo = { Lines = {
				{ S = "Brasa", T = "¡PAPÁ!", Shot = "DosPlanos:Brasa,GaloPadre", A = "Cheer" },
				{ S = "Narrador", T = "Brasa cruza la puerta corriendo entre la ceniza. Las sirenas suenan a lo lejos. Nadie las oye." },
				{ S = "GaloPadre", T = "Has crecido. Y estás más sucia. Y más guapa.", To = "Brasa" },
				{ S = "Brasa", T = "Me quedo en el Mercado. Madre Hollín me da un puesto. Y a ti te hago descuento. Siempre.", To = "Yo", A = "Happy" },
				{ S = "SargentoMurria", T = "(Murria os mira desde lejos. Luego se da la vuelta y se va solo, despacio.)", If = { Choices = { TefraMurria = "Sacar" } } },
			} },
		},
	},

	---------------------------------------------------------------------
	-- D · Papeles
	--   Personajes: el Escribano Lumo (falsificador anciano y vanidoso) y la Capitana Ferra (policía
	--   militar honrada). Trasfondo: sin papeles no se trabaja en el Muelle ni se pasa un control.
	--   Giro: Ferra sabe que los papeles son falsos y te deja pasar a cambio de un favor.
	--   Lazo con el Ragnarock: la ley militar decide quién existe.
	---------------------------------------------------------------------
	{
		Id = "Tefra_Papeles",
		Kind = "Side",
		Title = "Papeles",
		Description = "En la armería del Muelle te han parado: sin papeles de Bastión no entras ni compras nada. Dicen que un viejo del Mercado los hace. Muy buenos. Muy falsos.",
		Type = "Saga 2 · Tefra · Cadena secundaria",
		Duration = { 25, 35 },
		Npcs = { "PoliciaMilitar1", "EscribanoLumo", "CapitanaFerra" },
		Offer = { Place = "Tefra_Armeria" },
		OfferKey = "«Papeles, por favor.» El guardia de la armería te cierra el paso",
		Requires = req({ Completed = { "Tefra_02_Casa" } }),
		Moment = "Conseguiste papeles en Bastión Ceniza",
		Memory = "PapelesDeBastion",
		Rewards = { Money = 60, Items = { PapelesTefra = 1 }, Flags = { "ArmeriaAbierta" } },
		Props = {
			Tinta = { Kind = "Caja", Name = "Tarro de tinta de azufre", Prompt = "Coger la tinta", Place = "Tefra_Forja", Offset = V(4, 0, 0), Dialogue = "Tinta", Once = true },
			Sello = { Kind = "Papel", Name = "Sello de la policía militar", Prompt = "Coger el sello (con cuidado)", Place = "Tefra_Calabozos", Offset = V(5, 0, 2), Dialogue = "Sello", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "PoliciaMilitar1", Dialogue = "Control", Text = "Habla con el guardia de la armería", Actors = { at("PoliciaMilitar1", "Tefra_Armeria", 0, 3) } },
			{ Type = "Talk", Npc = "EscribanoLumo", Dialogue = "Lumo", Text = "Busca al Escribano Lumo junto al pozo del Mercado", Actors = { at("EscribanoLumo", "Tefra_PozoMercado", 14, 6) } },
			{ Type = "Group", Text = "Consigue los materiales del falsificador",
				Steps = {
					{ Type = "Use", Prop = "Tinta", Text = "Tinta de azufre (la Forja de Bastión)" },
					{ Type = "Use", Prop = "Sello", Text = "Un sello de verdad (junto a los calabozos del Muelle)" },
				} },
			{ Type = "Talk", Npc = "EscribanoLumo", Dialogue = "Foto", Text = "Vuelve con Lumo con la tinta y el sello", Actors = { at("EscribanoLumo", "Tefra_PozoMercado", 14, 6) } },
			{ Type = "MiniGame", Game = "Timing", Title = "Quieto para la foto", Icon = "📷", Hint = "La policía registra la tienda: no te muevas. Pulsa en el verde para aguantar la respiración",
				Rounds = 4, Need = 3, Zone = 0.28, Speed = 0.9,
				Win = { Flags = { "FotoPerfecta" } },
				Actors = { at("EscribanoLumo", "Tefra_PozoMercado", 14, 6), at("PoliciaMilitar2", "Tefra_PozoMercado", 20, 0) } },
			{ Type = "Talk", Npc = "CapitanaFerra", Dialogue = "Ferra", Text = "Pasa el control de la Puerta Norte con tus papeles nuevos", Actors = { at("CapitanaFerra", "Tefra_PuertaNorte", 0, 4) } },
			{ Type = "Choice", Key = "TefraFerra", Text = "Ferra sabe que tus papeles son falsos. Te ofrece dos salidas. ¿Cuál eliges?",
				Options = {
					{ Id = "Favor", Text = "Aceptar el favor que te pide (le deberás una)", Effects = { Flags = { "FavorFerra" }, Rel = { CapitanaFerra = 10 } } },
					{ Id = "Delatar", Text = "Decirle quién los hizo: papeles legales a cambio de Lumo", Effects = { Flags = { "LumoDelatado" }, Rel = { CapitanaFerra = 5, EscribanoLumo = -30 } } },
				},
				Actors = { at("CapitanaFerra", "Tefra_PuertaNorte", 0, 4) } },
			{ Type = "Scene", Dialogue = "Final", Actors = { at("CapitanaFerra", "Tefra_PuertaNorte", 0, 4) } },
		},
		Dialogues = {
			Control = { Lines = {
				{ S = "PoliciaMilitar1", T = "Papeles. ¿No tienes? Entonces no entras. Y ese gel que llevas, ¿de dónde lo has sacado?", To = "Yo" },
				{ S = "PoliciaMilitar1", T = "Sin papeles no eres nadie en Bastión. Y a «nadie» se le requisa todo. Hoy tienes suerte. Hoy.", A = "ArmsCrossed" },
			} },
			Lumo = { Lines = {
				{ S = "EscribanoLumo", T = "¿Papeles? ¿Yo? Soy un humilde escribano. Escribo cartas de amor para los soldados.", Shot = "Medio:EscribanoLumo" },
				{ S = "EscribanoLumo", T = "…Está bien. Hago los mejores papeles de Tefra. Mejores que los de verdad. Lo sé. Lo digo.", Beat = "Sonrie" },
				{ S = "EscribanoLumo", T = "Me faltan dos cosas: tinta de azufre de la Forja y un sello de verdad. El del Muelle, por ejemplo.", To = "Yo" },
			} },
			Tinta = { Lines = { { S = "Narrador", T = "El forjador mira hacia otro lado mientras te llevas el tarro. Huele a huevos podridos. Es perfecta." } } },
			Sello = { Lines = { { S = "Narrador", T = "Un sello de goma olvidado en la ventanilla de los calabozos. Te lo guardas. Te late el corazón en las orejas." } } },
			Foto = { Lines = {
				{ S = "EscribanoLumo", T = "¡Perfecto! Siéntate. Mira a la cámara. Cara de ciudadano honrado. No tanto. Así.", To = "Yo" },
				{ S = "EscribanoLumo", T = "Ay… viene una patrulla. Quieto. Ni respires. Eres un mueble. Un mueble muy guapo.", A = "Nervous" },
			} },
			Ferra = { Lines = {
				{ S = "CapitanaFerra", T = "Papeles. …Mmm. Bonitos. Muy bonitos. ¿Dónde naciste?", Shot = "Medio:CapitanaFerra", To = "Yo" },
				{ S = "CapitanaFerra", T = "¿Y cómo se llama la calle de la Panadería? ¿Y a qué hora reparten el pan?", Beat = "Mira" },
				{ S = "Narrador", T = "La cola de refugiados os mira en silencio. Nadie respira." },
				{ S = "CapitanaFerra", T = "Son falsos. Los hace Lumo. Lo sé desde hace años. Hace los mejores.", Pause = 0.8 },
				{ S = "CapitanaFerra", T = "Te propongo algo. Te dejo pasar si me haces un favor. O me dices dónde está Lumo y te doy unos legales.", To = "Yo" },
			} },
			Final = { Lines = {
				{ S = "CapitanaFerra", T = "Bien. Alguien roba medicinas del Campus y los heridos se mueren. Cuando te llame, vienes. Trato hecho.", If = { Choices = { TefraFerra = "Favor" } } },
				{ S = "CapitanaFerra", T = "Bien. Esta tarde Lumo dormirá en los calabozos. Tú, con papeles de verdad. Así funciona Bastión.", If = { Choices = { TefraFerra = "Delatar" } }, A = "Sad" },
				{ S = "CapitanaFerra", T = "Con eso la armería del Muelle te abre y nadie te requisa nada. Bienvenido a existir.", To = "Yo" },
			} },
		},
	},

	---------------------------------------------------------------------
	-- G · Candados (tranquila, sin decisiones: un momento de silencio)
	--   Personajes: Cosme y Ernesto, el panadero del Ovillo, que conoció a Ada.
	--   Trasfondo: Ada tenía un candado en el Puente de los Mil Candados.
	--   Giro: el candado lleva grabado el nombre de Cosme. Ada nunca dejó de esperarle.
	--   Lazo con el Ragnarock: lo que queda de un mundo que se acaba son las personas que lo recuerdan.
	---------------------------------------------------------------------
	{
		Id = "Tefra_Candados",
		Kind = "Side",
		Title = "Candados",
		Description = "Después del alto el fuego, Cosme no habla de Ada. Ernesto, el panadero del Ovillo, te busca: dice que Ada dejó algo en el Puente de los Mil Candados.",
		Type = "Saga 2 · Tefra · Cadena secundaria",
		Duration = { 20, 30 },
		Npcs = { "ErnestoPanadero", "Cosme" },
		Offer = { Place = "Tefra_Panaderia" },
		OfferKey = "Ernesto sale de la panadería con harina hasta los codos: «¿Eres tú quien vino con Cosme?»",
		Requires = req({ Completed = { "Tefra_07_Tregua" } }),
		Moment = "Cosme colgó su candado junto al de Ada",
		Memory = "CandadoDeAda",
		Rewards = { Money = 50, Items = { PanSirena = 2 } },
		Props = {
			CandadoAzul = { Kind = "Marcador", Name = "Un candado azul", Prompt = "Leer el nombre", Place = "Tefra_Candados", Offset = V(-12, 0, -6), Dialogue = "Azul", Once = true },
			CandadoRojo = { Kind = "Marcador", Name = "Un candado rojo", Prompt = "Leer el nombre", Place = "Tefra_Candados", Offset = V(12, 0, -6), Dialogue = "Rojo", Once = true },
			CandadoVerde = { Kind = "Marcador", Name = "Un candado verde", Prompt = "Leer el nombre", Place = "Tefra_Candados", Offset = V(-12, 0, 6), Dialogue = "Verde", Once = true },
			CandadoAda = { Kind = "Marcador", Name = "Un candado malva, con una bufanda de lana atada", Prompt = "Leer el nombre", Place = "Tefra_Candados", Offset = V(12, 0, 6), Dialogue = "Ada", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "ErnestoPanadero", Dialogue = "Ernesto", Text = "Habla con Ernesto en la Panadería del Ovillo", Actors = { at("ErnestoPanadero", "Tefra_Panaderia", 2, 3) } },
			{ Type = "MiniGame", Game = "Timing", Title = "Pan de sirena", Icon = "🥖", Hint = "Saca el pan del horno cuando la aguja esté en el dorado",
				Rounds = 4, Need = 2, Zone = 0.3, Speed = 0.9,
				Actors = { at("ErnestoPanadero", "Tefra_Panaderia", 2, 3) } },
			{ Type = "Group", Text = "Busca el candado de Ada entre los mil del puente (lee al menos dos)", Need = 2,
				Steps = {
					{ Type = "Use", Prop = "CandadoAzul", Text = "Un candado azul" },
					{ Type = "Use", Prop = "CandadoRojo", Text = "Un candado rojo" },
					{ Type = "Use", Prop = "CandadoVerde", Text = "Un candado verde" },
				} },
			{ Type = "Use", Prop = "CandadoAda", Text = "El que dijo Ernesto: malva, con una bufanda de lana atada" },
			{ Type = "Talk", Npc = "Cosme", Dialogue = "Cosme", Text = "Busca a Cosme junto a la estatua de Nilda", Actors = { at("Cosme", "Tefra_Estatua", 0, -3) } },
			{ Type = "Reach", Place = "Tefra_Candados", Text = "Lleva a Cosme al Puente de los Mil Candados", Actors = { { Npc = "Cosme", Mode = "Follow" } } },
			{ Type = "Scene", Dialogue = "Puente", Actors = { at("Cosme", "Tefra_Candados", 10, 4) } },
		},
		Dialogues = {
			Ernesto = { Lines = {
				{ S = "ErnestoPanadero", T = "Tú viniste con Cosme. El de Nilda. El que se cayó al cielo.", To = "Yo" },
				{ S = "ErnestoPanadero", T = "Conocí a Ada desde que era así de alta. Repartía mi pan en el Campus. Cada mañana.", Beat = "Respira" },
				{ S = "ErnestoPanadero", T = "Ayúdame a hornear el pan de sirena y te cuento lo del candado. Las manos piensan mejor con masa.", G = "Point" },
			} },
			Azul = { Lines = { { S = "Narrador", T = "«Para Tomé, que se fue a la Muralla y no volvió. Te guardamos la silla.»" } } },
			Rojo = { Lines = { { S = "Narrador", T = "«Mamá y papá, desde Ovilla. Algún día subiremos a verlo.» Está oxidado." } } },
			Verde = { Lines = { { S = "Narrador", T = "«Para el gato Carbón, que sobrevivió a tres bombardeos y murió de viejo. Bien hecho.»" } } },
			Ada = { Lines = {
				{ S = "Narrador", T = "Un candado malva, con una bufanda de lana atada. Grabado con letra de niña que ya no es niña:" },
				{ S = "Narrador", T = "«COSME. Te sigo esperando. Si vuelves, la llave está en el horno. — Ada.»", Pause = 1 },
			}, Effects = { Items = { CandadoAda = 1 } } },
			Cosme = { Lines = {
				{ S = "Cosme", T = "Criatura. No quiero hablar. Llevo tres días sin inventar nada. Eso no me había pasado nunca.", Shot = "Medio:Cosme", A = "Sad" },
				{ S = "Cosme", T = "¿Un candado? ¿De Ada? …Llévame.", Pause = 0.8 },
			} },
			Puente = { Lines = {
				{ S = "Cosme", T = "«Te sigo esperando.»", Shot = "PrimerPlano:Cosme", Pause = 1.5 },
				{ S = "Cosme", T = "Me esperó treinta y ocho años en un puente sobre la lava. Y yo inventando microondas.", Beat = "Silencio", A = "Sad" },
				{ S = "Narrador", T = "Cosme saca un candado viejo del bolsillo de la bata. Escribe algo con un destornillador. Lo cuelga junto al de Ada." },
				{ S = "Narrador", T = "No dice nada más en un buen rato. Cae ceniza. Abajo, la lava hace su ruido de siempre." },
				{ S = "Cosme", T = "Ya está. Ahora ya sabe que volví.", To = "Yo", Pause = 1 },
			} },
		},
	},
}
