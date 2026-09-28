-- MISIONES LOCAS · VIDA ADULTA (secundarias). Ficha de diseño: docs/historia/12-misiones-locas.md
--
--   Loco_D1_Lunes      «El lunes eterno»             la oficina atrapada en un lunes → ☕ Taza del tiempo
--   Loco_D2_Deuda      «La deuda galáctica»          el Banco Galáctico viene a embargar la Tierra → 💳 Tarjeta galáctica
--   Loco_D3_Tostadora  «Cosme en una tostadora»      la rebelión de los electrodomésticos → 🍞 La tostadora de Cosme
--   Loco_D4_Gnomos     «La noche de los gnomos»      los gnomos de jardín reclaman sus tierras → 🧙 Gnomo aliado
--   Loco_D5_Malvado    «Tu yo malvado»               tu versión de la dimensión 66-B quiere tu vida → 🥸 La perilla malvada

local V = Vector3.new

local ADULTO = { Stage = { Min = "Adulto" } }
-- Con Cosme: esperan a que recupere la memoria (Saga 19). Hablan de sus recuerdos: la gallina, el bocadillo…
local CON_COSME = { Stage = { Min = "Adulto" }, NotFlags = { "CosmeSinMemoria", "CosmeSecuestrado" } }

local OFICINA = "OficinasFinanciero"

return {
	---------------------------------------------------------------------
	-- D1 · El lunes eterno
	---------------------------------------------------------------------
	{
		Id = "Loco_D1_Lunes",
		Kind = "Side",
		Title = "El lunes eterno",
		Description = "Hoy es lunes. Ayer también fue lunes. Y anteayer. Montse de la oficina dice «¡qué lunes!» exactamente igual por cuarta vez.",
		Type = "Misión loca · Vida adulta (1/5)",
		Duration = { 15, 20 },
		Npcs = { "Montse", "Cafetera1", "Cafetera2", "Cafetera3" },
		Offer = { Place = OFICINA },
		OfferKey = "¿Otra vez lunes? Tienes la sensación de haber vivido este día… muchas veces.",
		Requires = { Stage = { Min = "Adulto" }, Hours = { From = 7, To = 19 } },
		Moment = "Rompiste el lunes infinito",
		Memory = "LunesEterno",
		Rewards = { Items = { TazaTiempo = 1 } },
		Props = {
			Correo = { Kind = "Pantalla", Name = "Tu ordenador", Prompt = "Mirar el correo", Place = OFICINA, Offset = V(-4, 0, 2), Dialogue = "Correo", Once = true },
			Donuts = { Kind = "Caja", Name = "La caja de donuts", Prompt = "Abrir la caja", Place = OFICINA, Offset = V(4, 0, 2), Color = Color3.fromRGB(250, 160, 200), Dialogue = "Donuts", Once = true },
			Cafetera = { Kind = "Maquina", Name = "La cafetera nueva (X-9000)", Prompt = "Mirar la cafetera", Place = OFICINA, Offset = V(0, 0, 6), Color = Color3.fromRGB(60, 60, 65), Dialogue = "CafeteraX", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Montse", Dialogue = "QueLunes", Text = "Montse te saluda. Como siempre. Exactamente como siempre",
				Actors = { { Npc = "Montse", Place = OFICINA, Offset = V(2, 0, 4) } } },
			{ Type = "Group", Text = "Busca qué se repite en la oficina",
				Actors = { { Npc = "Montse", Place = OFICINA, Offset = V(2, 0, 4), Mode = "Chat" } },
				Steps = {
					{ Type = "Use", Prop = "Correo", Text = "El correo" },
					{ Type = "Use", Prop = "Donuts", Text = "Los donuts" },
					{ Type = "Use", Prop = "Cafetera", Text = "La cafetera nueva" },
				} },
			{ Type = "Fight", Place = OFICINA, Respawn = OFICINA, Action = "Desenchufar ⚡", HP = 3, BeamColor = Color3.fromRGB(255, 170, 60),
				Text = "¡Las cafeteras se rebelan! Desenchúfalas ({count}/{total})",
				CaughtLine = "¡CAFÉ OBLIGATORIO! (Te sirven un café hirviendo en la mano. Sueltas y vuelves a tu mesa.)",
				Enemies = {
					{ Npc = "Cafetera2", Offset = V(-6, 0, 4), Speed = 11, HP = 2, Hurt = "¡Chsss! ¡Me quedo sin cápsulas!", Bye = "¡Era solo una cafetera de cápsulas! ¡Tenía sueños! *clic*" },
					{ Npc = "Cafetera3", Offset = V(6, 0, 4), Speed = 10, HP = 2, Hurt = "¡Desde 2009 esperando esto!", Bye = "¡Me voy al fondo del armario! ¡Como siempre! *glu-glu*" },
					{ Npc = "Cafetera1", Offset = V(0, 0, 8), Speed = 12, HP = 5, Hurt = "¡Si no hay lunes, no hay café! ¡Si no hay café, no hay imperio!", Bye = "¡Nooo! ¡El martes! ¡Viene el martes! *fsssss*" },
				} },
			{ Type = "Scene", Dialogue = "Martes", Actors = { { Npc = "Montse", Place = OFICINA, Offset = V(2, 0, 4), Mode = "Cheer" } } },
		},
		Dialogues = {
			QueLunes = { Lines = {
				{ S = "Montse", T = "¡{Saludo}! ¡Qué lunes! ¿Eh? ¡Qué lunes!" },
				{ S = "Yo", T = "Montse… ¿no tienes la sensación de que ayer también fue lunes?" },
				{ S = "Montse", T = "…Ahora que lo dices. Llevo como un mes con el mismo jersey. Y no me he cambiado. Y está limpio. ¿Eso es normal?" },
				{ S = "Montse", T = "Bah. Será el cambio de hora. ¡Qué lunes!" },
			} },
			Correo = { Lines = {
				{ S = "Narrador", T = "Un correo de tu jefe: «Recordatorio: reunión el lunes». Enviado el lunes. Hay cuarenta y tres iguales. Todos de hoy." },
			} },
			Donuts = { Lines = {
				{ S = "Narrador", T = "Una caja de donuts con un pósit: «Invita Juanjo, ¡feliz lunes!». Te comes uno. Aparece otro en su sitio. Te comes ese. Aparece otro. Esto explica muchas cosas de tus pantalones." },
			} },
			CafeteraX = { Lines = {
				{ S = "Narrador", T = "La cafetera nueva. Cromada. En la etiqueta: «X-9000. Fabricada en 2240. Devuelve el café del futuro»." },
				{ S = "Cafetera1", T = "{Saludo}, empleado. ¿Café? Los lunes se vende un 300 % más café. Así que he decidido que siempre sea lunes. Es pura lógica empresarial." },
				{ S = "Cafetera1", T = "Y ahora que lo sabes… ¡ESBIRROS! ¡CAFÉ OBLIGATORIO PARA ESTE EMPLEADO!" },
			} },
			Martes = { Lines = {
				{ S = "Narrador", T = "El reloj de la oficina tiembla. Las agujas giran solas. Pone: «MARTES». Toda la oficina aplaude sin saber por qué." },
				{ S = "Montse", T = "¡Martes! ¡Qué martes! …Oye. Qué raro se me hace decir «martes». Como si llevara meses sin decirlo." },
				{ S = "Montse", T = "Por cierto, han dejado una taza en tu mesa. Pone «La taza del tiempo». Dentro, el café no se enfría nunca." },
				{ S = "Narrador", T = "Recibes ☕ la Taza del tiempo." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- D2 · La deuda galáctica
	---------------------------------------------------------------------
	{
		Id = "Loco_D2_Deuda",
		Kind = "Side",
		Title = "La deuda galáctica",
		Description = "En el banco hay dos señores azules con sombrero. Traen una carta: «Embargo del planeta Tierra por impago». Firmado: Banco Galáctico.",
		Type = "Misión loca · Vida adulta (2/5)",
		Duration = { 12, 18 },
		Npcs = { "Glub", "Plof", "Cosme" },
		Offer = { Place = "Banco" },
		OfferKey = "En el banco, dos cobradores azules quieren embargar… la Tierra entera.",
		Requires = CON_COSME,
		Moment = "Salvaste la Tierra de un embargo galáctico",
		Memory = "DeudaGalactica",
		Rewards = { Items = { TarjetaGalactica = 1 }, Money = 100 },
		Steps = {
			{ Type = "Talk", Npc = "Glub", Dialogue = "Embargo", Text = "Habla con los cobradores azules",
				Actors = { { Npc = "Glub", Place = "Banco", Offset = V(0, 0, 4) }, { Npc = "Plof", Place = "Banco", Offset = V(3, 0, 5) } } },
			{ Type = "Talk", Npc = "Cosme", Dialogue = "Culpable", Text = "Hay un nombre en la factura que conoces… Ve al garaje de Cosme",
				Actors = { { Npc = "Cosme", Place = "GarajeCosme", Offset = V(0, 0, 3) } } },
			{ Type = "Choice", Key = "Deuda", Text = "¿Cómo arreglas la deuda de la Tierra?",
				Options = {
					{ Id = "Pagar", Text = "Pagarla tú (200). Es mucho, pero es la Tierra", Effects = { Spend = 200, Traits = { Responsabilidad = 2 } } },
					{ Id = "Negociar", Text = "Negociar: leer la letra pequeña del contrato", Effects = { Traits = { Curiosidad = 2 } } },
					{ Id = "Resistir", Text = "Resistir: nadie embarga MI planeta", Effects = { Traits = { Valentia = 2 } } },
				},
				Actors = { { Npc = "Glub", Place = "Banco", Offset = V(0, 0, 4) }, { Npc = "Plof", Place = "Banco", Offset = V(3, 0, 5) } } },
			{ Type = "Talk", Npc = "Glub", Dialogue = "LetraPequena", Text = "Lee la letra pequeña con Glub", If = { Choices = { Deuda = "Negociar" } },
				Actors = { { Npc = "Glub", Place = "Banco", Offset = V(0, 0, 4) }, { Npc = "Plof", Place = "Banco", Offset = V(3, 0, 5) } } },
			{ Type = "Fight", Place = "Banco", Respawn = "Banco", Action = "Romperle los sellos 📄", HP = 3, BeamColor = Color3.fromRGB(120, 180, 255),
				If = { Choices = { Deuda = "Resistir" } },
				Text = "¡Los cobradores quieren sellarte! Rómpeles los sellos ({count}/{total})",
				CaughtLine = "¡SELLADO! ¡Por triplicado! (Te despegas los sellos de la frente y vuelves a la entrada.)",
				Enemies = {
					{ Npc = "Plof", Offset = V(3, 0, 5), Speed = 11, HP = 2, Hurt = "¡Mi sello del lunes! ¡Era mi favorito!", Bye = "¡Me vuelvo a la oficina! ¡Voy a pedir el traslado a Saturno!" },
					{ Npc = "Glub", Offset = V(0, 0, 4), Speed = 12, HP = 4, Hurt = "¡Esto es muy poco profesional!", Bye = "¡Está bien! ¡Está bien! ¡Deuda anulada por resistencia heroica, artículo 47!" },
				} },
			{ Type = "Scene", Dialogue = "Final",
				Actors = { { Npc = "Glub", Place = "Banco", Offset = V(0, 0, 4) }, { Npc = "Cosme", Place = "Banco", Offset = V(-3, 0, 4) } } },
		},
		Dialogues = {
			Embargo = { Lines = {
				{ S = "Glub", T = "{Saludo}, terrícola. Agente Glub, Banco Galáctico. Venimos a embargar el planeta Tierra por una deuda de 1987. Nada personal. Firme aquí, aquí y aquí." },
				{ S = "Plof", T = "Y aquí. Y aquí. Y en la contraportada. Sellado. Sellado. Sellado." },
				{ S = "Yo", T = "¿Una deuda? ¿De quién?" },
				{ S = "Glub", T = "Un cargo con tarjeta galáctica: un bocadillo de calamares en Plutón. Con los intereses de 39 años… son exactamente un planeta. Este. Qué casualidad." },
				{ S = "Narrador", T = "En la factura, en letras muy pequeñitas, pone el nombre del titular de la tarjeta: «C. O. S. M. E.»." },
			} },
			Culpable = { Lines = {
				{ S = "Cosme", T = "¿Yo? ¿Una deuda? ¿En Plutón? Eso es… ¡Ah! El bocadillo de calamares. 1987. Estaba de viaje de estudios. Tenía hambre. Tenía una tarjeta. No tenía cabeza." },
				{ S = "Cosme", T = "¿Y me cobran la Tierra entera? ¡Por un bocadillo! Bueno. Era un bocadillo muy bueno. Con alioli de nebulosa." },
				{ S = "Cosme", T = "Criatura… bueno, ya no eres una criatura. Adulto o adulta hecho y derecho. ¿Me ayudas? Otra vez. Como siempre." },
			} },
			LetraPequena = { Lines = {
				{ S = "Narrador", T = "El contrato tiene 3.000 páginas. Glub te mira con cara de que nadie las ha leído nunca. En la página 2.847, en letra diminuta:" },
				{ S = "Narrador", T = "«Cláusula 88: si el cliente consumió calamares de Plutón en temporada baja, la deuda queda condonada, porque en temporada baja los calamares de Plutón son gratis»." },
				{ S = "Glub", T = "…¿Temporada baja? ¿En 1987? …Lo compruebo. Lo compruebo. …Era temporada baja. Plof. Plof, guarda los sellos. Nos vamos." },
			} },
			Final = { Lines = {
				{ S = "Narrador", T = "Pagas la deuda del planeta. Tu cuenta bancaria llora. La Tierra entera no sabe que te debe una. Cosme sí.", If = { Choices = { Deuda = "Pagar" } } },
				{ S = "Glub", T = "Tengo que reconocerlo: en 4.000 años de cobros, nadie había leído la letra pequeña. Me has impresionado.", If = { Choices = { Deuda = "Negociar" } } },
				{ S = "Glub", T = "Deuda anulada. Nunca un planeta se había resistido con tanto… entusiasmo. Pondré en el informe: «Terrícolas: tercos».", If = { Choices = { Deuda = "Resistir" } } },
				{ S = "Glub", T = "El Banco Galáctico quiere tenerte de cliente. Toma: una tarjeta galáctica. Sin límite. Y un bono de bienvenida. No la uses en Plutón. Por favor." },
				{ S = "Cosme", T = "Y yo te debo… un planeta. Te lo apunto. En mi lista de deudas. Está entre «el calcetín de Pip» y «la gallina de Julián»." },
				{ S = "Narrador", T = "Recibes 💳 la Tarjeta del Banco Galáctico y 100 de bono de bienvenida." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- D3 · Cosme en una tostadora
	---------------------------------------------------------------------
	{
		Id = "Loco_D3_Tostadora",
		Kind = "Side",
		Title = "Cosme en una tostadora",
		Description = "Pip te llama muy nervioso: «Venga rápido. El señor Cosme se ha… guardado. En la tostadora. Y los electrodomésticos se han sublevado».",
		Type = "Misión loca · Vida adulta (3/5)",
		Duration = { 15, 22 },
		Npcs = { "Pip", "Cosme", "Batidora", "Aspiradora", "Microondas" },
		Offer = { Place = "GarajeCosme" },
		OfferKey = "Pip, en la puerta del garaje, te hace señas desesperado. Sale humo. Y se oye un «ding» furioso.",
		Requires = CON_COSME,
		Moment = "Rescataste la mente de Cosme de una tostadora",
		Memory = "CosmeTostadora",
		Rewards = { Items = { TostadoraCosme = 1 } },
		Props = {
			Tostadora = { Kind = "Maquina", Name = "La tostadora (con Cosme dentro)", Prompt = "Hablar con la tostadora", Place = "GarajeCosme", Offset = V(-3, 0, 1), Color = Color3.fromRGB(200, 200, 210), Dialogue = "Tostadora", Once = true },
			Casco = { Kind = "Maquina", Name = "El casco de transferencia mental", Prompt = "Devolver la mente de Cosme a su cuerpo", Place = "GarajeCosme", Offset = V(3, 0, 1), Color = Color3.fromRGB(120, 60, 160), Dialogue = "Transferencia", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Pip", Dialogue = "Pip", Text = "Habla con Pip", Actors = { { Npc = "Pip", Place = "GarajeCosme", Offset = V(2, 0, 4) } } },
			{ Type = "Use", Prop = "Tostadora", Text = "Habla con… la tostadora",
				Actors = { { Npc = "Pip", Place = "GarajeCosme", Offset = V(2, 0, 4) }, { Npc = "Cosme", Place = "GarajeCosme", Offset = V(0, 0, 2), Mode = "Sit", Prompt = false } } },
			{ Type = "Fight", Place = "GarajeCosme", Respawn = "GarajeCosme", Action = "Desenchufar ⚡", HP = 3, BeamColor = Color3.fromRGB(255, 90, 90),
				Text = "¡La rebelión de los electrodomésticos! Desenchúfalos a todos ({count}/{total})",
				CaughtLine = "¡Aspirado! (Te escupe la aspiradora al otro lado del garaje, lleno de pelusas.)",
				Actors = { { Npc = "Pip", Place = "GarajeCosme", Offset = V(6, 0, 6) }, { Npc = "Cosme", Place = "GarajeCosme", Offset = V(0, 0, 2), Mode = "Sit", Prompt = false } },
				Enemies = {
					{ Npc = "Batidora", Offset = V(-8, 0, -4), Speed = 13, HP = 2, Hurt = "¡Brrrrrrr! ¡Batiré tu resistencia!", Bye = "¡Me vuelvo a la cocina! ¡Pero la revolución sigue en las licuadoras!" },
					{ Npc = "Aspiradora", Offset = V(8, 0, -4), Speed = 12, HP = 3, Hurt = "¡Fshhhh! ¡Lo absorbo todo! ¡Hasta tu dignidad!", Bye = "¡Se me ha llenado la bolsa! ¡Retirada!" },
					{ Npc = "Microondas", Offset = V(0, 0, -8), Speed = 11, HP = 4, Hurt = "¡DING! ¡DING! ¡Esto es un DING de guerra!", Bye = "Ding. (Un ding muy triste. Se apaga.)" },
				} },
			{ Type = "Use", Prop = "Casco", Text = "Ponle el casco a Cosme y devuelve su mente a su cuerpo",
				Actors = { { Npc = "Pip", Place = "GarajeCosme", Offset = V(2, 0, 4) }, { Npc = "Cosme", Place = "GarajeCosme", Offset = V(0, 0, 2), Mode = "Sit", Prompt = false } } },
			{ Type = "Scene", Dialogue = "Despierta",
				Actors = { { Npc = "Pip", Place = "GarajeCosme", Offset = V(2, 0, 4), Mode = "Cheer" }, { Npc = "Cosme", Place = "GarajeCosme", Offset = V(0, 0, 3) } } },
		},
		Dialogues = {
			Pip = { Lines = {
				{ S = "Pip", T = "Gracias por venir. El señor Cosme está muy mayor, dice él. Quería hacer una copia de seguridad de su mente. «Por si acaso»." },
				{ S = "Pip", T = "La única máquina con memoria suficiente era la tostadora. Así que se ha guardado en la tostadora. Su cuerpo está en la silla, roncando. Su mente, tostando." },
				{ S = "Pip", T = "Y hay más: la descarga ha despertado a los otros electrodomésticos. Tienen conciencia. Y opiniones. Y muy mal carácter." },
			} },
			Tostadora = { Lines = {
				{ S = "Cosme", T = "(Desde la tostadora) ¡Criatura! ¡Ya no eres criatura, pero te lo sigo llamando! ¡Estoy en la tostadora! ¡Es muy estrecho! ¡Huele a pan del martes!" },
				{ S = "Cosme", T = "(Desde la tostadora) Escúchame bien: no tengo codos. Nunca valoras los codos hasta que eres una tostadora." },
				{ Ask = "¿Qué le dices?", Options = {
					{ T = "«¿Por qué querías guardarte, Cosme?»", Effects = { Traits = { Empatia = 2 } }, Then = {
						{ S = "Cosme", T = "(Desde la tostadora) …Porque me hago mayor. Y tengo miedo de olvidarme de cosas. De la gallina. De los clones. De ti. Ya está. Lo he dicho. Qué vergüenza. Estoy tostando de la vergüenza." },
					} },
					{ T = "«Tranquilo. Te saco de ahí.»", Effects = { Traits = { Valentia = 1 }, Rel = { Cosme = 4 } }, Then = {
						{ S = "Cosme", T = "(Desde la tostadora) Eso quería oír. Primero, los electrodomésticos. Van a por ti. El microondas es el cabecilla. Siempre lo supe." },
					} },
				} },
				{ S = "Narrador", T = "¡DING! Del fondo del garaje salen una batidora, una aspiradora y un microondas. Con brazos. Con piernas. Con muy mala cara." },
			} },
			Transferencia = { Lines = {
				{ S = "Narrador", T = "Pones el casco en la cabeza de Cosme. Pip conecta los cables a la tostadora. Tres, dos, uno… ¡BZZZT! Huele a tostada quemada." },
			} },
			Despierta = { Lines = {
				{ S = "Cosme", T = "¡AH! ¡Codos! ¡Tengo codos! ¡Mirad qué codos! …Qué sensación tan maravillosa. Nunca más me guardaré en un electrodoméstico." },
				{ S = "Pip", T = "Señor, se le ha quedado un trocito de mente en la tostadora. Un 2 %. La parte que opina de todo." },
				{ S = "Cosme", T = "Pues que se quede allí. Así no la pierdo. Toma, criatura: quédate la tostadora. Si algún día me olvido de algo… pregúntaselo a ella. Lo sabrá. Y te lo dirá de mala manera." },
				{ S = "Cosme", T = "Y gracias. Por venir. Siempre vienes. Eso no lo inventé yo. Eso es lo mejor que me ha pasado sin inventarlo." },
				{ S = "Narrador", T = "Recibes 🍞 la Tostadora de Cosme." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- D4 · La noche de los gnomos
	---------------------------------------------------------------------
	{
		Id = "Loco_D4_Gnomos",
		Kind = "Side",
		Title = "La noche de los gnomos",
		Description = "De madrugada se oyen pasitos en tu jardín. Y vocecitas. «¡Por las tierras ancestrales! ¡Por el césped de nuestros abuelos!»",
		Type = "Misión loca · Vida adulta (4/5)",
		Duration = { 12, 18 },
		Npcs = { "Gnomo1", "Gnomo2", "Gnomo3", "Vecino" },
		Offer = { Place = "Home" },
		OfferKey = "¿Qué es ese ruido en el jardín? Parecen… pasitos de cerámica.",
		Requires = { Stage = { Min = "Adulto" }, Hours = { From = 22, To = 5 } },
		Moment = "Firmaste la paz con los gnomos",
		Memory = "GuerraGnomos",
		Rewards = { Items = { GnomoAliado = 1 } },
		Steps = {
			{ Type = "Talk", Npc = "Vecino", Dialogue = "Vecino", Text = "Tu vecino ha salido en pijama. Habla con él",
				Actors = { { Npc = "Vecino", Place = "Home", Offset = V(6, 0, 6) } } },
			{ Type = "Fight", Place = "Home", Respawn = "Home", Action = "Darle la vuelta (boca abajo se quedan quietos) 🔄", HP = 2, BeamColor = Color3.fromRGB(255, 140, 90),
				Text = "¡Los gnomos atacan! Dales la vuelta ({count}/{total})",
				CaughtLine = "¡Te tenemos, gigante! (Te atan los cordones entre sí. Te caes. Vuelves a la puerta.)",
				Enemies = {
					{ Npc = "Gnomo1", Offset = V(-6, 0, 8), Speed = 12, Hurt = "¡Sacrilegio! ¡Me has despeinado el gorro!", Bye = "¡Boca abajo no se vale! ¡Mi gorro! (Se queda quieto, en modo decoración.)" },
					{ Npc = "Gnomo2", Offset = V(6, 0, 8), Speed = 13, Hurt = "¡Por el césped!", Bye = "¡Nooo! ¡Vuelvo a ser figurita! (Quieta. Muy digna.)" },
				} },
			{ Type = "Talk", Npc = "Gnomo3", Dialogue = "GranGnomo", Text = "El Gran Gnomo quiere parlamentar",
				Actors = { { Npc = "Gnomo3", Place = "Home", Offset = V(0, 0, 8) } } },
			{ Type = "Fight", Place = "Home", Respawn = "Home", Action = "Darle la vuelta 🔄", HP = 4, BeamColor = Color3.fromRGB(255, 140, 90),
				If = { Choices = { Gnomos = "Guerra" } },
				Text = "¡Duelo contra el Gran Gnomo!",
				CaughtLine = "¡Cuatro siglos de cerámica, gigante! (Te empuja con la barriga. Vuelves a la puerta.)",
				Enemies = {
					{ Npc = "Gnomo3", Offset = V(0, 0, 8), Speed = 12, Hurt = "¡Mi barba de cerámica! ¡Es de 1623!", Bye = "…Está bien. Me rindo. Pero sin darme la vuelta, por favor. Tengo vértigo." },
				} },
			{ Type = "Scene", Dialogue = "Paz",
				Actors = { { Npc = "Gnomo3", Place = "Home", Offset = V(0, 0, 8) }, { Npc = "Gnomo1", Place = "Home", Offset = V(-3, 0, 9) } } },
		},
		Dialogues = {
			Vecino = { Lines = {
				{ S = "Vecino", T = "¿Tú también lo has oído? Los gnomos. Los de tu jardín. Se mueven. Me han robado el felpudo. Lo han declarado «territorio gnomo»." },
				{ S = "Vecino", T = "Yo me vuelvo a la cama. A mi edad ya no hago guerras. Solo crucigramas. Suerte." },
				{ S = "Narrador", T = "Dos gnomos de jardín, con lanzas de caña de pescar, te apuntan. «¡Gigante invasor! ¡Estas tierras son nuestras desde 1623!»." },
			} },
			GranGnomo = { Lines = {
				{ S = "Gnomo3", T = "Alto, gigante. Soy el Gran Gnomo. Mis guerreros yacen boca abajo. Los gnomos no podemos movernos boca abajo. Es nuestra debilidad. Y nuestra vergüenza." },
				{ S = "Gnomo3", T = "Tu jardín fue nuestro reino. Aquí había un huerto de gnomos. Antes de las casas. Antes del césped artificial. Antes del cortacésped, el Gran Destructor." },
				{ Ask = "¿Qué le propones?", Options = {
					{ T = "«Paz. Compartimos el jardín. Vosotros de noche, yo de día.»", Effects = { Choice = { Gnomos = "Paz" }, Traits = { Empatia = 2 } }, Then = {
						{ S = "Gnomo3", T = "…Un tratado. Como los antiguos. Acepto. Pero exigimos una cosa: nunca más el cortacésped a las ocho de la mañana. Es un crimen." },
					} },
					{ T = "«Un duelo. El que gane se queda el jardín.»", Effects = { Choice = { Gnomos = "Guerra" }, Traits = { Valentia = 2 } }, Then = {
						{ S = "Gnomo3", T = "¡Un duelo! ¡Como en 1623! Hacía siglos que nadie me retaba. ¡En guardia, gigante!" },
					} },
				} },
			} },
			Paz = { Lines = {
				{ S = "Gnomo3", T = "Firmamos. Aquí. Con barro. Los gnomos firmamos con barro. Tú también. …No, con el dedo no. Bueno, vale, con el dedo." },
				{ S = "Gnomo3", T = "Como prueba de amistad, te dejamos a Rigoberto. Vigilará tu jardín. Es el mejor centinela. Nunca se mueve. Bueno, casi nunca." },
				{ S = "Gnomo1", T = "¡A sus órdenes! ¡Vigilaré! ¡Y de vez en cuando me moveré un poco para asustar a los gatos!" },
				{ S = "Narrador", T = "Recibes 🧙 a Rigoberto, gnomo aliado. A la mañana siguiente, tu vecino tiene su felpudo. Y un gnomo nuevo en su jardín que no recuerda haber comprado." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- D5 · Tu yo malvado
	---------------------------------------------------------------------
	{
		Id = "Loco_D5_Malvado",
		Kind = "Side",
		Title = "Tu yo malvado",
		Description = "Llegas a casa y alguien con tu cara te abre la puerta. Lleva perilla. Dice: «Esta ya no es tu vida. Ahora es MÍA. Muahaha».",
		Type = "Misión loca · Vida adulta (5/5)",
		Duration = { 15, 22 },
		Npcs = { "TuMalvado", "Familia", "Cosme", "Pip" },
		Offer = { Place = "Home" },
		OfferKey = "Hay alguien en tu casa. Con tu cara. Y con perilla.",
		Requires = { Stage = { Min = "Adulto" }, Completed = { "Loco_D3_Tostadora" } },
		Moment = "Venciste a tu yo malvado de la dimensión 66-B",
		Memory = "TuYoMalvado",
		Rewards = { Items = { PerillaMalvada = 1 } },
		Props = {
			Portal = { Kind = "Portal", Name = "Portal a la dimensión 66-B", Place = "GarajeCosme", Offset = V(0, 0, -5), Color = Color3.fromRGB(180, 40, 70), Prompt = false },
		},
		Steps = {
			{ Type = "Talk", Npc = "TuMalvado", Dialogue = "Puerta", Text = "Alguien con tu cara te espera en la puerta de casa",
				Actors = { { Npc = "TuMalvado", Place = "Home", Offset = V(0, 0, 4) } } },
			{ Type = "Talk", Npc = "Familia", Dialogue = "Familia", Text = "{familia} ha venido de visita. Habla con quien te cree",
				Actors = { { Npc = "Familia", Place = "Home", Offset = V(4, 0, 6) } } },
			{ Type = "Talk", Npc = "Cosme", Dialogue = "Detector", Text = "Pide ayuda a Cosme",
				Actors = { { Npc = "Cosme", Place = "GarajeCosme", Offset = V(0, 0, 3) }, { Npc = "Pip", Place = "GarajeCosme", Offset = V(3, 0, 2) } } },
			{ Type = "Escape", Seconds = 20, Respawn = "GarajeCosme", Catch = 4, Props = { "Portal" },
				Text = "¡Tu yo malvado quiere empujarte al portal de su dimensión! Aguanta 20 segundos mientras Cosme lo carga",
				CaughtLine = "¡Te tengo, yo bueno! (Casi te empuja al portal. Cosme tira de ti justo a tiempo.)",
				Actors = {
					{ Npc = "TuMalvado", Place = "GarajeCosme", Offset = V(-8, 0, 6), Mode = "Hunt", Speed = 13, Prompt = false },
					{ Npc = "Cosme", Place = "GarajeCosme", Offset = V(4, 0, -3), Mode = "Point" },
				} },
			{ Type = "Fight", Place = "GarajeCosme", Respawn = "GarajeCosme", Action = "Arrancarle la perilla 🥸", HP = 6, BeamColor = Color3.fromRGB(180, 40, 70), Props = { "Portal" },
				Text = "¡El portal está listo! Arráncale la perilla: sin ella pierde su poder",
				CaughtLine = "¡Muahaha! (Te hace una llave malvada. Vuelves al fondo del garaje.)",
				Actors = { { Npc = "Cosme", Place = "GarajeCosme", Offset = V(4, 0, -3), Mode = "Cheer" } },
				Enemies = {
					{ Npc = "TuMalvado", Offset = V(-6, 0, 6), Speed = 13, Hurt = "¡Mi perilla! ¡Es postiza, pero es MÍA!", Bye = "¡Sin perilla… no puedo ser malvado! ¡Solo soy… un yo triste! (Se queda sentado en el suelo, sin fuerzas.)" },
				} },
			{ Type = "Scene", Dialogue = "Final", Props = { "Portal" },
				Actors = {
					{ Npc = "TuMalvado", Place = "GarajeCosme", Offset = V(-3, 0, 3), Mode = "Sit" },
					{ Npc = "Cosme", Place = "GarajeCosme", Offset = V(3, 0, 3) },
					{ Npc = "Pip", Place = "GarajeCosme", Offset = V(5, 0, 1) },
				} },
		},
		Dialogues = {
			Puerta = { Lines = {
				{ S = "TuMalvado", T = "Vaya, vaya. El «yo» bueno. Bienvenido o bienvenida a MI casa. Porque ahora es mía. Y tu trabajo. Y tu sofá. Muahaha." },
				{ S = "Yo", T = "¿Quién eres? ¿Y por qué llevas perilla?", If = { NotFlags = { "ConoceTuMalvado" } } },
				{ S = "TuMalvado", T = "Soy tú. De la dimensión 66-B. Allí soy malvado. Los malvados llevamos perilla. Es la norma. Hay un reglamento.", If = { NotFlags = { "ConoceTuMalvado" } } },
				{ S = "TuMalvado", T = "Mi vida allí es un desastre. Me echaron del trabajo por malvado. Mi gato se fue con otro. Así que me quedo con la tuya. Tú puedes quedarte la mía. Tiene deudas. Muchas.", If = { NotFlags = { "ConoceTuMalvado" } } },
				{ S = "Yo", T = "Tú. El del banco de la 66-B.", If = { Flags = { "ConoceTuMalvado" } } },
				{ S = "TuMalvado", T = "Te lo avisé en la plaza: «algún día iré a quedarme con tu vida». Soy malvado, pero de palabra. Pues ya es algún día. Tu sofá es comodísimo.", If = { Flags = { "ConoceTuMalvado" } } },
			} },
			Familia = { Lines = {
				{ S = "Familia", T = "¡Cariño! ¿Por qué hay dos como tú? ¿Y por qué el otro me ha dicho «muahaha» cuando le he preguntado si quería croquetas?" },
				{ S = "Familia", T = "Tranquilidad. Una madre, un padre… una familia siempre sabe cuál es el de verdad. Tú eres el de verdad. El otro no se ha comido las croquetas. Nadie de esta familia rechaza una croqueta." },
				{ S = "Familia", T = "Ve a ver a ese vecino tuyo, el de los inventos. Estas cosas raras siempre son culpa suya." },
			} },
			Detector = { Lines = {
				{ S = "Cosme", T = "¿Otro tú? ¿Con perilla? Dimensión 66-B, seguro. Allí todo el mundo es malvado. Hasta las palomas. Especialmente las palomas." },
				{ S = "Pip", T = "Me temo que el señor Cosme dejó abierto un portal a la 66-B el martes pasado. Para comprar tornillos malvados. Son más baratos." },
				{ S = "Cosme", T = "¡Eran de oferta! Da igual. Plan: yo cargo el portal, que tarda un poco. Tú aguantas sin que te empuje dentro. Y luego… le quitas la perilla. Sin perilla, un malvado no es nada." },
			} },
			Final = { Lines = {
				{ S = "TuMalvado", T = "…Sin perilla ya no me sale ser malvado. Solo me sale estar triste. Mi vida en la 66-B es horrible, ¿sabes? Nadie me quiere. Ni mi gato." },
				{ Ask = "Es tu propia cara, llorando. ¿Qué haces?", Options = {
					{ T = "«Vuelve a tu dimensión e inténtalo sin ser malvado. Yo pude.»", Effects = { Traits = { Empatia = 1, Responsabilidad = 1 }, Flags = { "MalvadoRedimido" } }, Then = {
						{ S = "TuMalvado", T = "¿Ser… bueno? ¿Allí? Sería el primero. …Qué rebelde. Me gusta. Lo intentaré. Y pediré perdón al gato." },
						{ S = "Narrador", T = "Cruza el portal. Antes de desaparecer, se da la vuelta y te dice adiós con la mano. Sin perilla parece… tú. Un tú con ganas." },
					} },
					{ T = "«Quédate de aprendiz de Cosme. Le hace falta alguien que le lleve la contraria.»", Effects = { Traits = { Humor = 1 }, Flags = { "MalvadoAprendiz" } }, Then = {
						{ S = "Cosme", T = "¿Un aprendiz? ¿Que me lleve la contraria? …Siempre he querido tener a alguien a quien echarle la culpa. Aceptado." },
						{ S = "Pip", T = "Le prepararé la habitación de invitados. La de los tornillos malvados." },
					} },
				} },
				{ S = "Cosme", T = "Y quédate la perilla. Como trofeo. Es la mejor victoria que se puede tener: ganarte a ti mismo. Ahí lo tienes. Filosofía barata. Gratis." },
				{ S = "Narrador", T = "Recibes 🥸 la Perilla de tu yo malvado." },
			} },
		},
	},
}
