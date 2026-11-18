-- ACTO II · LA COALICIÓN (3/3): UMBRÍA, TÁLASA y VÉRTICE, y ACTO III «LA ÚLTIMA NOCHE» (18-11-2026; biblia:
-- docs/historia/historia-principal-15h.md). Capítulos Coalicion_Umbria, Coalicion_Talasa, Coalicion_Vertice y
-- Universo_Final.
--   UMBRÍA   el bosque se pudre desde la raíz; la Marea ya ha tocado este mundo. Varn y los Hijos de la Ceniza aquí.
--   TÁLASA   océano; la grieta está en una fosa, bajo una estación del Consorcio inundada.
--   VÉRTICE  la sede del Consorcio (allí se llama MegaVerso). La verdad: el Consorcio quiere abrirle paso a la Marea.
--   FINAL    la Marea llega a la Grieta de Valmar. La flota de la Coalición. Kael. La decisión final. La paz.
-- Para +17: tragedia (Kael muere), humor seco, alegría al final. Todo se juega.

local V = Vector3.new

local function at(npc: string, place: string, x: number, z: number, mode: string?): { [string]: any }
	return { Npc = npc, Place = place, Offset = V(x, 0, z), Mode = mode }
end
local COSME_SIGUE = { Npc = "Cosme", Mode = "Follow" }
local SOREL_SIGUE = { Npc = "Sorel", Mode = "Follow" }
local PISTA = {
	{ Npc = "Kael", Place = "Pista", Offset = V(0, 0, -6) },
	{ Npc = "Sorel", Place = "Pista", Offset = V(6, 0, -2) },
	{ Npc = "Brenn", Place = "Pista", Offset = V(-4, 0, -4) },
	{ Npc = "Maren", Place = "Pista", Offset = V(-8, 0, 0) },
	{ Npc = "Cosme", Place = "Pista", Offset = V(8, 0, 2) },
}

local function main(chapter: string, t: { [string]: any }): { [string]: any }
	t.Kind = "Main"
	t.Chapter = chapter
	t.AgeRange = t.AgeRange or { 18, 45 }
	t.Difficulty = t.Difficulty or 5
	return t
end

return {
	---------------------------------------------------------------------
	-- UMBRÍA
	---------------------------------------------------------------------
	main("Coalicion_Umbria", {
		Id = "Umb01_Raiz",
		Title = "El bosque gris",
		Description = "Umbría era un mundo-bosque. Ahora los árboles se vuelven grises desde la raíz. La Marea ha tocado este mundo primero. Y Varn está aquí.",
		Duration = { 20, 25 },
		Type = "La Coalición · Umbría",
		Next = { "Umb02_Ceniza" },
		Moment = "Viste lo que hace la Marea",
		Npcs = { "Cosme", "Sorel", "Garza", "AlcaldesaSavia", "ILEN" },
		Locations = { "Umbria_Plataforma", "Umbria_ClaroMuerto", "Umbria_Ayuntamiento" },
		Rewards = { Money = 6000 },
		Props = {
			Arbol = { Kind = "Marcador", Name = "Un árbol convertido en ceniza, todavía de pie", Prompt = "Tocar el árbol", Place = "Umbria_ClaroMuerto", Offset = V(0, 0, 6), Dialogue = "Arbol", Once = true },
			Muestra = { Kind = "Cristal", Name = "Una raíz que brilla con un gris extraño", Prompt = "Coger una muestra", Place = "Umbria_ClaroMuerto", Offset = V(-6, 0, 10), Dialogue = "Muestra", Once = true },
		},
		Steps = {
			{ Type = "Event", Event = "PlanetLanded", Match = { Planet = "Umbria" }, Text = "Vuela a Umbría (el planeta del bosque) y aterriza" },
			{ Type = "Scene", Dialogue = "Llegada", Actors = { at("Garza", "Umbria_Plataforma", 3, 4), at("Cosme", "Umbria_Plataforma", -3, 2) } },
			{ Type = "Reach", Place = "Umbria_ClaroMuerto", Text = "Garza te lleva al Claro Muerto, donde empezó", Actors = { { Npc = "Garza", Mode = "Follow" }, SOREL_SIGUE } },
			{ Type = "Group", Text = "Examina lo que ha hecho la Marea",
				Steps = {
					{ Type = "Use", Prop = "Arbol", Text = "El árbol de ceniza" },
					{ Type = "Use", Prop = "Muestra", Text = "La raíz gris" },
				} },
			{ Type = "Event", Event = "BeastKilled", Count = 8, Match = { Planet = "Umbria" }, Text = "Las bestias del bosque, enloquecidas, huyen del gris. Protege el claro ({count}/{total})" },
			{ Type = "Reach", Place = "Umbria_Ayuntamiento", Text = "Ve al ayuntamiento: la alcaldesa Savia tiene noticias", Actors = { at("AlcaldesaSavia", "Umbria_Ayuntamiento", 2, 4) } },
			{ Type = "Talk", Npc = "AlcaldesaSavia", Dialogue = "Savia", Text = "Habla con la alcaldesa Savia", Actors = { at("AlcaldesaSavia", "Umbria_Ayuntamiento", 2, 4) } },
		},
		Dialogues = {
			Llegada = { Lines = {
				{ S = "Narrador", T = "Árboles de cien metros con ciudades colgadas de sus ramas. Y en medio del verde, manchas grises que se extienden como moho por la corteza." },
				{ S = "Garza", T = "Garza, guardabosques. Si venís a cerrar la grieta, llegáis tarde. Lo que había detrás ya ha empezado a salir." },
				{ S = "ILEN", T = "Detecto la misma frecuencia de once segundos. Pero aquí no viene del cielo. Viene del suelo." },
			} },
			Arbol = { Lines = {
				{ S = "Narrador", T = "Tocas la corteza. Se deshace en ceniza fina bajo tus dedos, y el árbol entero, cien metros, se derrumba en silencio como un castillo de arena." },
				{ S = "Narrador", T = "Dentro no hay madera. Solo gris. Y por un segundo, un sonido muy grave, como una respiración." },
			} },
			Muestra = { Lines = {
				{ S = "Narrador", T = "La raíz gris está tibia. Late. Once segundos." },
				{ S = "Cosme", T = "Mi abuela decía que el Silencio no mataba: «se acordaba» de las cosas. Que convertía el mundo en el recuerdo del mundo. Yo pensaba que era un cuento para dormir." },
				{ S = "Cosme", T = "No dormí mucho de pequeño." },
			} },
			Savia = { Lines = {
				{ S = "AlcaldesaSavia", T = "Hace un mes llegó un hombre de otro mundo. Traje negro, voz tranquila. Dijo que se llamaba Varn." },
				{ S = "AlcaldesaSavia", T = "Dijo que la Marea no se puede parar. Que quien se rinde, se convierte en parte de ella y vive para siempre. Medio pueblo le siguió al bosque gris." },
				{ S = "AlcaldesaSavia", T = "Mi hija entre ellos." },
			}, Effects = { Rel = { AlcaldesaSavia = 6 } } },
		},
	}),

	main("Coalicion_Umbria", {
		Id = "Umb02_Ceniza",
		Title = "El profeta",
		Description = "Varn espera en el corazón del bosque gris, rodeado de gente que le cree. Esta vez no hay papeles que robar. Solo personas a las que convencer.",
		Duration = { 22, 28 },
		Type = "La Coalición · Umbría",
		Next = { "Umb03_Corazon" },
		Moment = "Te enfrentaste a Varn en Umbría",
		Npcs = { "Cosme", "Sorel", "Varn", "NiaVaina", "Ceniciento1", "Ceniciento2", "ILEN" },
		Locations = { "Umbria_Raices", "Umbria_VainaNia" },
		Rewards = { Money = 6000 },
		Steps = {
			{ Type = "Reach", Place = "Umbria_Raices", Text = "Entra en el bosque gris, hasta las raíces grandes", Actors = { SOREL_SIGUE, COSME_SIGUE } },
			{ Type = "Scene", Dialogue = "Profeta", Actors = { at("Varn", "Umbria_Raices", 0, 14), at("Ceniciento1", "Umbria_Raices", -6, 12), at("Ceniciento2", "Umbria_Raices", 6, 12), at("NiaVaina", "Umbria_Raices", 4, 18) } },
			{ Type = "Choice", Key = "UmbVarn", Text = "Varn te ofrece unirte: «Ayúdame a abrirle la puerta a la Marea y Valmar vivirá dentro de ella. Para siempre». Los seguidores te miran. ¿Qué haces?",
				Options = {
					{ Id = "Hablar", Text = "Hablar a los seguidores, no a Varn: contarles lo que viste en el Claro Muerto", Effects = { Flags = { "VarnSeguidores" }, Traits = { Empatia = 1 } } },
					{ Id = "Atacar", Text = "Ir directamente a por Varn", Effects = { Flags = { "VarnAtacado" }, Traits = { Valentia = 1 } } },
				},
				Actors = { at("Varn", "Umbria_Raices", 0, 14) } },
			{ Type = "MiniGame", Game = "Timing", Title = "Llegar a ellos", Icon = "💬", If = { Choices = { UmbVarn = "Hablar" } },
				Hint = "Cada frase en su momento: pulsa en el verde",
				Rounds = 4, Need = 3, Zone = 0.22, Speed = 1,
				Win = { Flags = { "SeguidoresDudan" } }, Lose = { Flags = { "SeguidoresFirmes" } } },
			{ Type = "Fight", Place = "Umbria_Raices", Respawn = "Umbria_Raices", Action = "Golpe ⚔", HP = 6,
				Text = "Los Hijos de la Ceniza protegen a su profeta. Abre paso ({count}/{total})",
				CaughtLine = "(Te derriban sobre la ceniza. Varn mira sin moverse.) «Rendirse no duele. Ya lo verás.»",
				Actors = { at("Varn", "Umbria_Raices", 0, 18) },
				Enemies = {
					{ Npc = "Ceniciento1", Offset = V(-6, 0, 12), Speed = 11, HP = 3, Bye = "No… no quiero desaparecer. No quiero." },
					{ Npc = "Ceniciento2", Offset = V(6, 0, 12), Speed = 11, HP = 3, Bye = "¿Y si tiene razón él? …¿Y si la tienes tú?" },
				} },
			{ Type = "Scene", Dialogue = "Huida", Actors = { at("NiaVaina", "Umbria_Raices", 4, 18) } },
			{ Type = "Reach", Place = "Umbria_VainaNia", Text = "Varn ha huido. Saca a Nia del bosque gris y llévala con su madre", Actors = { { Npc = "NiaVaina", Mode = "Follow" } } },
		},
		Dialogues = {
			Profeta = { Lines = {
				{ S = "Narrador", T = "En un claro de árboles grises, doscientas personas con la cara pintada de ceniza, sentadas en silencio. En el centro, de pie, Varn." },
				{ S = "Varn", T = "Sabía que vendrías. Siempre llegas tarde y siempre llegas. Es casi entrañable." },
				{ S = "Varn", T = "He tocado a la Marea. No es un monstruo. No odia. Solo recuerda. Todo lo que toca se convierte en un recuerdo perfecto. Sin hambre, sin guerras, sin miedo." },
				{ S = "Varn", T = "Valmar va a perder. Todos los mundos van a perder. Yo solo ofrezco perder sin dolor." },
				{ S = "Sorel", T = "Eso es lo que le dijo al Sur la noche de la Caída: que esperaran sin miedo." },
			} },
			Huida = { Lines = {
				{ S = "Narrador", T = "Varn se aleja entre los árboles grises sin correr, como quien sale de una reunión aburrida. Sus seguidores se dispersan." },
				{ S = "Narrador", T = "Una chica se queda sentada en la ceniza, temblando. La hija de la alcaldesa: Nia." },
				{ S = "NiaVaina", T = "Dijo que no dolería. Dijo que mi abuela estaba dentro, esperándome. Oí su voz en la raíz. Era su voz." },
				{ S = "NiaVaina", T = "…No quiero ser un recuerdo. Quiero irme a casa." },
			} },
		},
	}),

	main("Coalicion_Umbria", {
		Id = "Umb03_Corazon",
		Title = "El corazón del árbol",
		Description = "La grieta de Umbría está dentro del Árbol Madre, el más viejo del mundo. La Marea ya está dentro. Cerrarla significa quemar el corazón del bosque.",
		Duration = { 22, 28 },
		Type = "La Coalición · Umbría",
		Moment = "Cerraste la grieta de Umbría",
		Npcs = { "Cosme", "Sorel", "Garza", "AlcaldesaSavia", "NiaVaina", "ILEN" },
		Locations = { "Umbria_SueloHondo", "Umbria_Ayuntamiento" },
		Rewards = { Money = 9000, Flags = { "GrietaUmbriaCerrada" } },
		Props = {
			Ancla = { Kind = "Cristal", Name = "El ancla de la grieta, dentro del tronco", Prompt = "Colocar el disruptor", Place = "Umbria_SueloHondo", Offset = V(0, 0, 10), Dialogue = "Ancla", Once = true },
			Semilla = { Kind = "Marcador", Name = "Una semilla verde entre las raíces grises", Prompt = "Coger la semilla", Place = "Umbria_SueloHondo", Offset = V(-6, 0, 6), Dialogue = "SemillaVerde", Once = true },
		},
		Steps = {
			{ Type = "Reach", Place = "Umbria_SueloHondo", Text = "Baja al Suelo Hondo, al corazón del Árbol Madre", Actors = { SOREL_SIGUE, { Npc = "Garza", Mode = "Follow" } } },
			{ Type = "Event", Event = "BeastKilled", Count = 12, Match = { Planet = "Umbria" }, Text = "Lo que vive dentro del árbol ya no es del todo una bestia. Sobrevive ({count}/{total})", Actors = { SOREL_SIGUE } },
			{ Type = "Use", Prop = "Semilla", Text = "Algo verde entre tanto gris" },
			{ Type = "Use", Prop = "Ancla", Text = "Coloca el disruptor en el ancla" },
			{ Type = "MiniGame", Game = "Timing", Title = "Cerrar la grieta de Umbría", Icon = "🌀", Hint = "La Marea empuja desde dentro: sincroniza el disruptor en el verde",
				Rounds = 6, Need = 4, Zone = 0.2, Speed = 1.25,
				Win = { Flags = { "UmbriaCierreLimpio" } }, Lose = { Flags = { "UmbriaCierreSucio" } } },
			{ Type = "Scene", Dialogue = "Garza", Actors = { at("Garza", "Umbria_SueloHondo", -2, 4, "Sit") } },
			{ Type = "Reach", Place = "Umbria_Ayuntamiento", Text = "Vuelve al ayuntamiento", Actors = { SOREL_SIGUE } },
			{ Type = "Scene", Dialogue = "Semilla", Actors = { at("AlcaldesaSavia", "Umbria_Ayuntamiento", 2, 4), at("NiaVaina", "Umbria_Ayuntamiento", 4, 4), at("Cosme", "Umbria_Ayuntamiento", -2, 6) } },
		},
		Dialogues = {
			SemillaVerde = { Lines = {
				{ S = "Narrador", T = "Entre las raíces grises, una semilla verde del tamaño de un puño, intacta. El árbol la ha protegido de la Marea con lo último que le quedaba." },
			} },
			Ancla = { Lines = {
				{ S = "Narrador", T = "El ancla está dentro del tronco, envuelta en vetas grises que laten. Cuando acercas el disruptor, oyes voces dentro. Muchas. Tranquilas. Te llaman por tu nombre." },
			} },
			Garza = { Lines = {
				{ S = "Narrador", T = "La grieta se cierra con un gemido de madera. El gris deja de avanzar. Pero Garza se ha sentado contra una raíz y no se levanta: tiene la mano gris hasta el codo." },
				{ S = "Garza", T = "Me tocó al proteger la semilla. No duele. Eso es lo peor: no duele nada." },
				{ S = "Garza", T = "Lleva la semilla a la alcaldesa. Plantadla en la plaza. Y no os quedéis a ver cómo me quedo gris. Por favor." },
				{ S = "Narrador", T = "Sorel se queda con él hasta el final. Tú subes con la semilla." },
			} },
			Semilla = { Lines = {
				{ S = "AlcaldesaSavia", T = "Garza la protegió treinta años. Le pondremos su nombre al árbol que crezca." },
				{ S = "NiaVaina", T = "Yo la plantaré. Yo la cuidaré. Es lo menos." },
				{ S = "AlcaldesaSavia", T = "Umbría se une a la Coalición. Lo que queda de Umbría. Y es bastante." },
				{ S = "Sorel", T = "(con los ojos rojos) Me ha pedido que le contara algo bonito. Le he contado lo de la lluvia en Siroco. Se ha reído." },
				{ S = "Cosme", T = "Cinco de siete. Ya no cuento con alegría. Solo cuento." },
			}, Effects = { Rel = { AlcaldesaSavia = 8, Sorel = 6 } } },
		},
	}),

	---------------------------------------------------------------------
	-- TÁLASA
	---------------------------------------------------------------------
	main("Coalicion_Talasa", {
		Id = "Tal01_Fosa",
		Title = "Lo que hay bajo el agua",
		Description = "Tálasa: un mundo cubierto de océano, con ciudades flotantes. La grieta está en el fondo de una fosa, bajo una estación del Consorcio que se inundó con todos dentro.",
		Duration = { 20, 25 },
		Type = "La Coalición · Tálasa",
		Next = { "Tal02_Estacion" },
		Moment = "Llegaste a Tálasa",
		Npcs = { "Cosme", "Sorel", "AlmiranteCoria", "NoaFerran", "ILEN" },
		Locations = { "Talasa_Plataforma", "Talasa_Muelle", "Talasa_Faro" },
		Rewards = { Money = 6000 },
		Props = {
			Registro = { Kind = "Libro", Name = "El registro del faro", Prompt = "Leer el registro", Place = "Talasa_Faro", Offset = V(0, 0, 4), Dialogue = "Registro", Once = true },
			Boya = { Kind = "Maquina", Name = "Una boya de emergencia del Consorcio", Prompt = "Escuchar la boya", Place = "Talasa_Muelle", Offset = V(6, 0, 4), Dialogue = "Boya", Once = true },
		},
		Steps = {
			{ Type = "Event", Event = "PlanetLanded", Match = { Planet = "Talasa" }, Text = "Vuela a Tálasa (el planeta azul) y aterriza" },
			{ Type = "Scene", Dialogue = "Llegada", Actors = { at("AlmiranteCoria", "Talasa_Plataforma", 3, 4), at("Cosme", "Talasa_Plataforma", -3, 2) } },
			{ Type = "Reach", Place = "Talasa_Muelle", Text = "Ve al muelle con la almirante", Actors = { at("NoaFerran", "Talasa_Muelle", -4, 4), COSME_SIGUE } },
			{ Type = "Use", Prop = "Boya", Text = "Una boya de emergencia del Consorcio sigue emitiendo. Escúchala" },
			{ Type = "Reach", Place = "Talasa_Faro", Text = "Sube al faro", Actors = { COSME_SIGUE } },
			{ Type = "Use", Prop = "Registro", Text = "Lee el registro del faro" },
			{ Type = "Event", Event = "BeastKilled", Count = 8, Match = { Planet = "Talasa" }, Text = "Algo sube de la fosa hacia las ciudades flotantes. Defiéndelas ({count}/{total})" },
			{ Type = "Talk", Npc = "NoaFerran", Dialogue = "Noa", Text = "Noa Ferran, la buceadora, quiere hablar contigo", Actors = { at("NoaFerran", "Talasa_Muelle", -4, 4) } },
		},
		Dialogues = {
			Llegada = { Lines = {
				{ S = "Narrador", T = "Agua hasta donde alcanza la vista. Ciudades flotantes unidas por puentes que se mueven con las olas. Sobre la superficie, un círculo de agua más oscura: la fosa." },
				{ S = "AlmiranteCoria", T = "Almirante Coria. Tálasa no tiene ejército de tierra porque no tenemos tierra. Tenemos barcos, buceadores y mucha paciencia." },
				{ S = "Cosme", T = "En mi mapa pone «aprender a nadar». Sigo sin aprender." },
				{ S = "ILEN", T = "Ofrezco cursos acelerados. Constan de una lección: no caerse." },
			} },
			Boya = { Lines = {
				{ S = "Narrador", T = "Una voz grabada, en bucle: «Estación Abisal Umbral. Inundación en curso. 140 personas a bordo. Solicitamos evacuación». Fecha: hace seis años." },
				{ S = "Narrador", T = "Nadie vino. La boya sigue pidiéndolo, cada noventa segundos, desde hace seis años." },
			} },
			Registro = { Lines = {
				{ S = "Narrador", T = "La última anotación del farero, el día de la inundación: «Llamé al Consorcio. Respondieron que la evacuación no estaba cubierta por el seguro de la estación. Cerraron las compuertas desde arriba»." },
			} },
			Noa = { Lines = {
				{ S = "NoaFerran", T = "Noa Ferran. Mi madre era ingeniera en esa estación. Bajé a la fosa cien veces buscándola. Nunca pasé de la compuerta del faro." },
				{ S = "NoaFerran", T = "Si vas a bajar a cerrar la grieta, voy contigo. No es una pregunta. Bueno, sí lo es, pero la respuesta es sí." },
			}, Effects = { Rel = { NoaFerran = 6 } } },
		},
	}),

	main("Coalicion_Talasa", {
		Id = "Tal02_Estacion",
		Title = "Estación Abisal",
		Description = "Seis años bajo el agua. Lo que queda de la estación del Consorcio, y de las 140 personas que nadie fue a buscar.",
		Duration = { 22, 28 },
		Type = "La Coalición · Tálasa",
		Next = { "Tal03_Grieta" },
		Moment = "Entraste en la Estación Abisal",
		Npcs = { "Cosme", "Sorel", "NoaFerran", "ILEN" },
		Locations = { "Talasa_CompuertaFaro", "Talasa_Estacion", "Talasa_EstacionDentro" },
		Rewards = { Money = 6000 },
		Props = {
			Compuerta = { Kind = "Maquina", Name = "La compuerta sellada del faro", Prompt = "Abrir la compuerta", Place = "Talasa_CompuertaFaro", Offset = V(0, 0, 3), Dialogue = "Compuerta", Once = true },
			Diario = { Kind = "Papel", Name = "Una tableta impermeable en una taquilla", Prompt = "Leer la tableta", Place = "Talasa_EstacionDentro", Offset = V(-4, 0, 2), Dialogue = "Diario", Once = true },
			Capsula = { Kind = "Maquina", Name = "Una cápsula de criosueño, todavía encendida", Prompt = "Mirar la cápsula", Place = "Talasa_EstacionDentro", Offset = V(6, 0, 6), Dialogue = "Capsula", Once = true },
		},
		Steps = {
			{ Type = "Reach", Place = "Talasa_CompuertaFaro", Text = "Ve a la compuerta del faro con Noa", Actors = { { Npc = "NoaFerran", Mode = "Follow" } } },
			{ Type = "Use", Prop = "Compuerta", Text = "Abre la compuerta sellada" },
			{ Type = "MiniGame", Game = "Timing", Title = "Igualar la presión", Icon = "🌊", Hint = "Si abres de golpe, el agua te aplasta: suelta presión en el verde",
				Rounds = 4, Need = 3, Zone = 0.22, Speed = 1.1,
				Win = { Flags = { "CompuertaSuave" } }, Lose = { Flags = { "CompuertaGolpe" } } },
			{ Type = "Reach", Place = "Talasa_EstacionDentro", Text = "Entra en la Estación Abisal", Actors = { { Npc = "NoaFerran", Mode = "Follow" } } },
			{ Type = "Event", Event = "BeastKilled", Count = 10, Match = { Planet = "Talasa" }, Text = "La estación está llena de lo que ha salido de la grieta. Ábrete paso ({count}/{total})" },
			{ Type = "Group", Text = "Registra la estación con Noa", Actors = { { Npc = "NoaFerran", Mode = "Follow" } },
				Steps = {
					{ Type = "Use", Prop = "Diario", Text = "La tableta de la taquilla" },
					{ Type = "Use", Prop = "Capsula", Text = "La cápsula encendida" },
				} },
			{ Type = "Choice", Key = "TalCapsula", Text = "En la cápsula, en criosueño, está la madre de Noa. Viva. Despertarla aquí abajo es arriesgado; sacarla sin despertarla puede apagar la cápsula. Noa te mira. ¿Qué haces?",
				Options = {
					{ Id = "Despertar", Text = "Despertarla aquí: Noa tiene derecho a hablar con ella ya", Effects = { Flags = { "MadreNoaDespierta" }, Rel = { NoaFerran = 10 } } },
					{ Id = "Sacar", Text = "Sacar la cápsula entera a la superficie, aunque sea más lento", Effects = { Flags = { "MadreNoaCapsula" }, Rel = { NoaFerran = 6 }, Traits = { Responsabilidad = 1 } } },
				},
				Actors = { at("NoaFerran", "Talasa_EstacionDentro", 4, 4) } },
			{ Type = "Scene", Dialogue = "Madre", Actors = { at("NoaFerran", "Talasa_EstacionDentro", 4, 4) } },
		},
		Dialogues = {
			Compuerta = { Lines = {
				{ S = "Narrador", T = "La compuerta tiene un sello del Consorcio pintado encima: «No abrir. Responsabilidad limitada»." },
				{ S = "NoaFerran", T = "Responsabilidad limitada. Mi madre está detrás de esa compuerta y alguien escribió «responsabilidad limitada»." },
			} },
			Diario = { Lines = {
				{ S = "Narrador", T = "Una tableta con anotaciones de los últimos días: «Día 4. El Consorcio no viene. Hemos metido a los niños en las cápsulas de criosueño: hay doce. Somos ciento cuarenta»." },
				{ S = "Narrador", T = "«Día 9. La doctora Ferran ha cedido su sitio a un chico de quince años. Insistimos. Dijo que su hija sabría perdonarla.»" },
			} },
			Capsula = { Lines = {
				{ S = "Narrador", T = "Una cápsula de criosueño con la luz verde aún encendida. Dentro, un chico de unos veinte años, dormido. Junto a él, otras once cápsulas. Doce supervivientes." },
				{ S = "Narrador", T = "Y en la última, con la luz parpadeando, una mujer mayor. El nombre de la placa: «Ferran»." },
				{ S = "NoaFerran", T = "Le dio su sitio a otro. Y luego alguien se lo devolvió. …Está viva." },
			} },
			Madre = { Lines = {
				{ S = "Narrador", T = "Noa apoya la frente contra el cristal de la cápsula. No dice nada durante mucho rato." },
				{ S = "NoaFerran", T = "Doce vivos. Doce de ciento cuarenta. Y la grieta debajo, que lo empezó todo." },
				{ S = "NoaFerran", T = "Ciérrala. Por los otros ciento veintiocho." },
			} },
		},
	}),

	main("Coalicion_Talasa", {
		Id = "Tal03_Grieta",
		Title = "La fosa",
		Description = "La grieta de Tálasa está en el fondo de la fosa, bajo la estación. La Marea empuja desde el otro lado. Y lo que más se acerca a la luz ya no es un refugiado.",
		Duration = { 22, 28 },
		Type = "La Coalición · Tálasa",
		Moment = "Cerraste la grieta de Tálasa",
		Npcs = { "Cosme", "Sorel", "NoaFerran", "AlmiranteCoria", "ILEN" },
		Locations = { "Talasa_Estacion", "Talasa_Plaza" },
		Rewards = { Money = 9000, Flags = { "GrietaTalasaCerrada" } },
		Props = {
			Ancla = { Kind = "Cristal", Name = "El ancla de la grieta, en el fondo de la fosa", Prompt = "Colocar el disruptor", Place = "Talasa_Estacion", Offset = V(0, 0, 12), Dialogue = "Ancla", Once = true },
		},
		Steps = {
			{ Type = "Reach", Place = "Talasa_Estacion", Text = "Baja al fondo de la fosa, bajo la estación", Actors = { { Npc = "NoaFerran", Mode = "Follow" } } },
			{ Type = "Scene", Dialogue = "Algo", Actors = { { Npc = "NoaFerran", Mode = "Follow" } } },
			{ Type = "Event", Event = "BeastKilled", Count = 14, Match = { Planet = "Talasa" }, Text = "Lo que sale de la grieta ya no huye: ataca. Aguanta ({count}/{total})" },
			{ Type = "Use", Prop = "Ancla", Text = "Coloca el disruptor en el ancla" },
			{ Type = "MiniGame", Game = "Timing", Title = "Cerrar la grieta de Tálasa", Icon = "🌀", Hint = "La corriente te arrastra: sincroniza el disruptor en el verde",
				Rounds = 6, Need = 4, Zone = 0.2, Speed = 1.3,
				Win = { Flags = { "TalasaCierreLimpio" } }, Lose = { Flags = { "TalasaCierreSucio" } } },
			{ Type = "Reach", Place = "Talasa_Plaza", Text = "Sube a la superficie, a la plaza de la ciudad flotante", Actors = { { Npc = "NoaFerran", Mode = "Follow" } } },
			{ Type = "Scene", Dialogue = "Superficie", Actors = { at("AlmiranteCoria", "Talasa_Plaza", 3, 4), at("NoaFerran", "Talasa_Plaza", -3, 4), at("Cosme", "Talasa_Plaza", 0, 8) } },
		},
		Dialogues = {
			Algo = { Lines = {
				{ S = "Narrador", T = "En el fondo de la fosa, la grieta es un ojo violeta del tamaño de un edificio. Y al otro lado, apretado contra ella, algo gris y enorme que se mueve despacio." },
				{ S = "ILEN", T = "Esa forma… no tengo datos para describirla. Solo tengo una palabra: grande. Y otra: cerca." },
				{ S = "NoaFerran", T = "Ya no son bestias que huyen. Es la Marea. Está empujando." },
			} },
			Ancla = { Lines = {
				{ S = "Narrador", T = "El ancla vibra tanto que el agua a su alrededor hierve. Al otro lado de la grieta, la forma gris se detiene. Como si te mirara." },
			} },
			Superficie = { Lines = {
				{ S = "Narrador", T = "La grieta se cierra. En la superficie, la fosa deja de ser oscura. Por primera vez en seis años, el agua sobre ella vuelve a ser azul." },
				{ S = "AlmiranteCoria", T = "Doce supervivientes en la enfermería. Una madre y una hija que no se sueltan la mano. Tálasa se une a la Coalición, con todos sus barcos." },
				{ S = "NoaFerran", T = "Mi madre dice que te dé las gracias. Yo también. Y que si alguna vez necesitas a alguien que bucee donde nadie se atreve, ya sabes." },
				{ S = "Cosme", T = "Seis de siete. Queda Vértice. «No firmar nada», ponía en mi mapa." },
				{ S = "ILEN", T = "Mensaje de Valmar. Es Kael. Por primera vez desde que la conozco… parece asustada." },
				{ S = "Kael", T = "(por la radio) Vértice es la sede del Consorcio. Varn está allí. Y han empezado a abrir grietas nuevas. Os necesito allí ya. Todos." },
			}, Effects = { Rel = { NoaFerran = 8, AlmiranteCoria = 6 } } },
		},
	}),

	---------------------------------------------------------------------
	-- VÉRTICE
	---------------------------------------------------------------------
	main("Coalicion_Vertice", {
		Id = "Ver01_MegaVerso",
		Title = "Gracias por su compra",
		Description = "Vértice: una ciudad bajo una cúpula donde todo es de una empresa. Aquí el Consorcio se llama MegaVerso. Y lo que vende es el fin del mundo.",
		Duration = { 20, 25 },
		Type = "La Coalición · Vértice",
		Next = { "Ver02_Torre" },
		Moment = "Llegaste a Vértice",
		Npcs = { "Cosme", "Sorel", "AbrilCruz", "Gil", "SeguridadMV1", "SeguridadMV2", "ILEN" },
		Locations = { "Vertice_Plataforma", "Vertice_Plaza", "Vertice_Museo", "Vertice_MuseoDentro" },
		Rewards = { Money = 6000 },
		Props = {
			Anuncio = { Kind = "Pantalla", Name = "Una pantalla gigante con un anuncio", Prompt = "Mirar el anuncio", Place = "Vertice_Plaza", Offset = V(0, 0, 8), Dialogue = "Anuncio", Once = true },
			Archivo = { Kind = "Pantalla", Name = "El terminal del archivo del museo", Prompt = "Entrar en el archivo", Place = "Vertice_MuseoDentro", Offset = V(0, 0, 4), Dialogue = "Archivo", Once = true },
		},
		Steps = {
			{ Type = "Event", Event = "PlanetLanded", Match = { Planet = "Vertice" }, Text = "Vuela a Vértice (el planeta de la cúpula) y aterriza" },
			{ Type = "Scene", Dialogue = "Llegada", Actors = { at("Gil", "Vertice_Plataforma", 3, 4), at("Cosme", "Vertice_Plataforma", -3, 2) } },
			{ Type = "Reach", Place = "Vertice_Plaza", Text = "Ve a la plaza", Actors = { COSME_SIGUE, SOREL_SIGUE } },
			{ Type = "Use", Prop = "Anuncio", Text = "Mira el anuncio de la pantalla gigante" },
			{ Type = "Talk", Npc = "AbrilCruz", Dialogue = "Abril", Text = "Una mujer te hace señas desde el museo", Actors = { at("AbrilCruz", "Vertice_Museo", 0, 4) } },
			{ Type = "Escape", Place = "Vertice_MuseoDentro", Respawn = "Vertice_Museo", Catch = 4,
				Text = "Entra en el archivo del museo sin que te vean los guardias de MegaVerso",
				CaughtLine = "Acceso no autorizado. Se ha cargado una multa en su cuenta. Gracias por su comprensión.",
				Actors = {
					{ Npc = "SeguridadMV1", Place = "Vertice_Museo", Offset = V(10, 0, 10), Mode = "Hunt", Speed = 10, Prompt = false },
					{ Npc = "SeguridadMV2", Place = "Vertice_Museo", Offset = V(-10, 0, 10), Mode = "Hunt", Speed = 10, Prompt = false },
				} },
			{ Type = "Use", Prop = "Archivo", Text = "Entra en el archivo" },
			{ Type = "MiniGame", Game = "Timing", Title = "Romper el cifrado", Icon = "🔓", Hint = "Cada capa del cifrado se abre un instante: pulsa en el verde",
				Rounds = 5, Need = 3, Zone = 0.2, Speed = 1.25,
				Win = { Flags = { "ArchivoMegaVerso" } }, Lose = { Flags = { "ArchivoAMedias" } } },
			{ Type = "Scene", Dialogue = "Plan", Actors = { at("AbrilCruz", "Vertice_MuseoDentro", 3, 3) } },
		},
		Dialogues = {
			Llegada = { Lines = {
				{ S = "Narrador", T = "Una ciudad perfecta bajo una cúpula de cristal. Calles limpias, música suave, sonrisas. En cada esquina, el mismo logotipo: MegaVerso." },
				{ S = "Gil", T = "¡Bienvenidos a Vértice! Soy Gil, de Atención al Visitante. Su estancia incluye oxígeno básico. El oxígeno premium se cobra aparte." },
				{ S = "Cosme", T = "«No firmar nada». Lo pone en mi mapa en mayúsculas. Lo escribí yo, así que me hago caso." },
				{ S = "ILEN", T = "Tres cámaras nos siguen desde que hemos aterrizado. Dos de ellas tienen publicidad." },
			} },
			Anuncio = { Lines = {
				{ S = "Narrador", T = "Una mujer sonriente en la pantalla: «MegaVerso Eternidad. ¿Miedo al futuro? Reserve su plaza en la Gran Memoria. Vivirá para siempre. Plazas limitadas»." },
				{ S = "Narrador", T = "Debajo, en letra pequeña: «Patrocinado por los Hijos de la Ceniza»." },
				{ S = "Sorel", T = "Están vendiendo la Marea. Como un seguro de vida." },
			} },
			Abril = { Lines = {
				{ S = "AbrilCruz", T = "Abril Cruz, conservadora del museo. Y lo único parecido a una resistencia que tiene esta ciudad." },
				{ S = "AbrilCruz", T = "MegaVerso es el Consorcio. Siempre lo fue. Y en el archivo hay algo que necesito que veáis antes de subir a esa torre." },
			} },
			Archivo = { Lines = {
				{ S = "Narrador", T = "El archivo se abre: el «Plan Puerta». El Consorcio no abrió las grietas solo por energía. Las abrió para negociar con la Marea." },
				{ S = "Narrador", T = "«La entidad absorbe toda la vida de un mundo, pero conserva su memoria. Propuesta: entregarle seis mundos a cambio de que preserve el séptimo. Mundo preservado: Vértice. Directivos y clientes premium»." },
				{ S = "Narrador", T = "Firmado por el consejo de MegaVerso. Una de las firmas: A. Varn." },
			} },
			Plan = { Lines = {
				{ S = "AbrilCruz", T = "Seis mundos a cambio de uno. Y los otros seis ni siquiera lo saben." },
				{ S = "AbrilCruz", T = "Están abriendo grietas nuevas desde la torre MegaVerso. Para que la Marea entre por todas partes a la vez. Tenéis que subir. Hoy." },
				{ S = "Cosme", T = "Me encanta cuando la gente dice «hoy». Nunca dice «mañana, con calma, después de comer»." },
			} },
		},
	}),

	main("Coalicion_Vertice", {
		Id = "Ver02_Torre",
		Title = "La torre MegaVerso",
		Description = "Ciento veinte plantas de oficinas, guardias y gente que no sabe para quién trabaja. Arriba, Varn y el generador que abre grietas nuevas.",
		Duration = { 25, 30 },
		Type = "La Coalición · Vértice",
		Moment = "Tomaste la torre MegaVerso",
		Npcs = { "Cosme", "Sorel", "AbrilCruz", "Varn", "SeguridadMV1", "SeguridadMV2", "ILEN" },
		Locations = { "Vertice_Oficinas", "Vertice_AscensorDentro", "Vertice_Avenida" },
		Rewards = { Money = 10000, Flags = { "GrietaVerticeCerrada" } },
		Props = {
			Generador = { Kind = "Maquina", Name = "El generador de grietas de la torre", Prompt = "Sabotear el generador", Place = "Vertice_Oficinas", Offset = V(0, 0, -6), Dialogue = "Generador", Once = true },
			Megafonia = { Kind = "Pantalla", Name = "El sistema de megafonía de la ciudad", Prompt = "Emitir el archivo a toda la ciudad", Place = "Vertice_Oficinas", Offset = V(8, 0, 2), Dialogue = "Megafonia", Once = true },
		},
		Steps = {
			{ Type = "Reach", Place = "Vertice_Oficinas", Text = "Sube a la torre MegaVerso", Actors = { SOREL_SIGUE, COSME_SIGUE } },
			{ Type = "Fight", Place = "Vertice_Oficinas", Respawn = "Vertice_Oficinas", Action = "Golpe ⚔", HP = 6,
				Text = "La seguridad de MegaVerso te corta el paso ({count}/{total})",
				CaughtLine = "(Te tiran contra una mampara de cristal.) «Su reclamación ha sido registrada.»",
				Actors = { at("Sorel", "Vertice_Oficinas", -4, 2, "Point") },
				Enemies = {
					{ Npc = "SeguridadMV1", Offset = V(-6, 0, 10), Speed = 12, HP = 3, Bye = "No me pagan lo suficiente para esto. Literalmente: miradme la nómina." },
					{ Npc = "SeguridadMV2", Offset = V(6, 0, 10), Speed = 12, HP = 3, Bye = "Me rindo. ¿Esto cuenta como baja voluntaria?" },
				} },
			{ Type = "Use", Prop = "Megafonia", Text = "Emite el archivo del Plan Puerta por toda la ciudad" },
			{ Type = "Scene", Dialogue = "Varn", Actors = { at("Varn", "Vertice_Oficinas", 0, -2) } },
			{ Type = "Choice", Key = "VerVarn", Text = "Varn está acorralado junto al generador. Toda la ciudad ha oído el archivo. Te ofrece rendirse a cambio de no ser entregado a la multitud. ¿Qué haces?",
				Options = {
					{ Id = "Juicio", Text = "Aceptar: será juzgado por la Coalición, delante de los siete mundos", Effects = { Flags = { "VarnJuzgado" }, Traits = { Responsabilidad = 1 } } },
					{ Id = "Multitud", Text = "Rechazar: que se enfrente a la gente de Vértice a la que iba a sacrificar", Effects = { Flags = { "VarnMultitud" }, Traits = { Rebeldia = 1 } } },
				},
				Actors = { at("Varn", "Vertice_Oficinas", 0, -2) } },
			{ Type = "Use", Prop = "Generador", Text = "Sabotea el generador de grietas" },
			{ Type = "MiniGame", Game = "Timing", Title = "Cerrar la grieta de Vértice", Icon = "🌀", Hint = "El generador se resiste: invierte cada fase en el verde",
				Rounds = 6, Need = 4, Zone = 0.2, Speed = 1.3,
				Win = { Flags = { "VerticeCierreLimpio" } }, Lose = { Flags = { "VerticeCierreSucio" } } },
			{ Type = "Scene", Dialogue = "Silencio", Actors = { at("AbrilCruz", "Vertice_Oficinas", 3, 3), at("Cosme", "Vertice_Oficinas", -3, 3) } },
		},
		Dialogues = {
			Megafonia = { Lines = {
				{ S = "Narrador", T = "Todas las pantallas de Vértice se apagan y se encienden con el archivo: «Seis mundos a cambio de uno. Mundo preservado: directivos y clientes premium»." },
				{ S = "Narrador", T = "En la calle, la música suave se corta. Millones de personas leyendo lo mismo a la vez. Luego, un ruido que crece: la ciudad entera gritando." },
			} },
			Varn = { Lines = {
				{ S = "Varn", T = "Muy teatral. Te habría contratado para marketing." },
				{ S = "Varn", T = "¿Crees que he hecho esto por dinero? He visto a la Marea. Nadie gana contra ella. Yo solo intentaba salvar algo. Un mundo de siete." },
				{ S = "Varn", T = "Y tú acabas de condenarlos a los siete. Enhorabuena." },
				{ S = "Sorel", T = "Usted no salvaba un mundo. Salvaba a los que podían pagar." },
				{ S = "Varn", T = "¿Y qué es un mundo, sino los que pueden pagar?" },
			} },
			Generador = { Lines = {
				{ S = "Narrador", T = "El generador ocupa la planta entera: anillos negros girando alrededor de un núcleo de luz violeta. Igual que el de Valmar, pero diez veces más grande." },
			} },
			Silencio = { Lines = {
				{ S = "Narrador", T = "El generador se detiene. La grieta de Vértice se cierra. Por primera vez desde que la Coalición existe, ILEN no detecta el sonido de once segundos." },
				{ S = "Narrador", T = "Durante un minuto entero, el universo está en silencio." },
				{ S = "AbrilCruz", T = "Vértice se une a la Coalición. Sin MegaVerso. Hoy nos toca aprender a vivir sin que nos cobren por respirar." },
				{ S = "Cosme", T = "Siete de siete. Siete. Mi abuela no se lo creería. Yo tampoco me lo creo, y estaba aquí." },
				{ S = "ILEN", T = "…Detecto el sonido otra vez. Pero no viene de las grietas cerradas." },
				{ S = "ILEN", T = "Viene de Valmar. De la primera grieta. La Marea ha encontrado la puerta que quedaba." },
			}, Effects = { Rel = { AbrilCruz = 8, Cosme = 6 } } },
		},
	}),

	---------------------------------------------------------------------
	-- ACTO III · LA ÚLTIMA NOCHE
	---------------------------------------------------------------------
	main("Universo_Final", {
		Id = "Fin01_Flota",
		Title = "La flota de los siete mundos",
		Description = "La Marea Gris empuja contra la Grieta de Valmar, la primera, la que lo empezó todo. Siete mundos mandan lo que tienen. No será suficiente. Tiene que serlo.",
		Duration = { 22, 28 },
		Type = "El Universo · Final",
		Next = { "Fin02_Kael" },
		Moment = "Reuniste a la flota de los siete mundos",
		Npcs = { "Kael", "Brenn", "Sorel", "Maren", "Cosme", "ILEN" },
		Locations = { "Pista", "PuertoEspacial" },
		Rewards = { Money = 10000 },
		Props = {
			Mapa = { Kind = "Pantalla", Name = "El mapa táctico de la Coalición", Prompt = "Estudiar el plan", Place = "Pista", Offset = V(0, 0, 4), Dialogue = "Plan", Once = true },
			Pared = { Kind = "Mural", Name = "La pared de los nombres", Prompt = "Mirar la pared antes de salir", Place = "EntradaColegio", Offset = V(-8, 0, 2), Dialogue = "Pared", Once = true },
		},
		Steps = {
			{ Type = "Reach", Place = "Pista", Text = "Vuelve a Valmar: la Coalición se reúne en la Academia", Actors = PISTA },
			{ Type = "Scene", Dialogue = "Reunion", Actors = PISTA },
			{ Type = "Use", Prop = "Mapa", Text = "Estudia el plan de batalla" },
			{ Type = "Use", Prop = "Pared", Text = "Mira la pared de los nombres antes de salir" },
			{ Type = "Event", Event = "BeastKilled", Count = 15, Text = "Lo primero que cruza la Grieta cae sobre Valmar. Defiende la ciudad ({count}/{total})" },
			{ Type = "Scene", Dialogue = "Noche", Actors = PISTA },
		},
		Dialogues = {
			Reunion = { Lines = {
				{ S = "Narrador", T = "La pista de la Academia está llena: soldados del Dominio de Tefra, filtradores de Miasma, aguadores de Siroco, faroleros de Nivalis, guardabosques de Umbría, buceadores de Tálasa, gente de Vértice sin logotipos." },
				{ S = "Kael", T = "Hace un año esto era un colegio con las ventanas tapiadas. Hoy hay siete mundos en la pista." },
				{ S = "Maren", T = "La Marea está empujando la Grieta de Valmar desde el otro lado. El generador del Umbral puede cerrarla, pero alguien tiene que llevarlo hasta el centro de la Grieta y activarlo allí. En persona." },
				{ S = "Brenn", T = "Y mientras, alguien tiene que aguantar aquí abajo todo lo que salga." },
				{ S = "Cosme", T = "Es decir: el plan es muy sencillo y casi seguro que morimos. Me gustan los planes sencillos." },
			} },
			Plan = { Lines = {
				{ S = "Narrador", T = "Flechas de siete colores sobre el mapa de Valmar. La flota de Tálasa en la costa. Los cañones del Dominio en la muralla. Los faroles de Nivalis alrededor del asentamiento para que la oscuridad no entre." },
				{ S = "Narrador", T = "En el centro, una flecha sola hacia la Grieta. Con tu nombre." },
			} },
			Pared = { Lines = {
				{ S = "Narrador", T = "La pared de los nombres. Ahora hay nombres de siete mundos. Garza, de Umbría. El padre de Mara. Los ciento veintiocho de la estación abisal. Lía, la hermana de Cosme." },
				{ S = "Narrador", T = "Debajo, mucho espacio libre. Esta noche se llenará un poco." },
			} },
			Noche = { Lines = {
				{ S = "Narrador", T = "La Grieta sobre Valmar se abre de par en par. De ella cae ceniza, como nieve gris. Y detrás, ocupando medio cielo, la Marea: una forma que no tiene forma, gris, lenta, inmensa." },
				{ S = "Kael", T = "Todos a sus puestos. Tú, a tu nave. Yo voy contigo hasta la Grieta." },
				{ S = "Sorel", T = "¿Kael va contigo? Kael nunca sale de Valmar." },
				{ S = "Kael", T = "Ilen me dijo una vez que no volviera a por ella. Esta vez no voy a por nadie. Voy delante." },
			} },
		},
	}),

	main("Universo_Final", {
		Id = "Fin02_Kael",
		Title = "No dejaré a nadie atrás",
		Description = "Atravesar la ceniza hasta el centro de la Grieta con el generador del Umbral. Kael va contigo. Solo uno de los dos puede activarlo desde dentro.",
		Duration = { 22, 28 },
		Type = "El Universo · Final",
		Next = { "Fin03_Paz" },
		Moment = "Kael",
		Npcs = { "Kael", "Brenn", "Sorel", "Maren", "Cosme", "ILEN" },
		Locations = { "Pista", "PuertoEspacial" },
		Rewards = { Money = 12000 },
		Props = {
			Generador = { Kind = "Maquina", Name = "El generador del Umbral, cargado en la nave", Prompt = "Revisar el generador", Place = "PuertoEspacial", Offset = V(0, 0, -6), Dialogue = "Generador", Once = true },
		},
		Steps = {
			{ Type = "Reach", Place = "PuertoEspacial", Text = "Ve al puerto espacial con Kael", Actors = { { Npc = "Kael", Mode = "Follow" } } },
			{ Type = "Use", Prop = "Generador", Text = "Revisa el generador antes del despegue", Actors = { at("Kael", "PuertoEspacial", -4, 4) } },
			{ Type = "Event", Event = "PlanetLanded", Text = "Despega hacia la Grieta y atraviésala: aterriza en el primer mundo al que te lleve" },
			{ Type = "Event", Event = "BeastKilled", Count = 12, Text = "Al otro lado, todo lo que queda vivo te ataca. Abre camino hasta el centro ({count}/{total})" },
			{ Type = "Scene", Dialogue = "Centro" },
			{ Type = "Choice", Key = "FinKael", Text = "El generador solo se activa desde dentro de la Grieta. Quien lo active no podrá salir a tiempo. Kael ya tiene la mano en la palanca.",
				Options = {
					{ Id = "Kael", Text = "Dejar que lo haga ella: «No dejaré a nadie atrás… pero tú me lo prohibiste.»", Effects = { Flags = { "KaelSacrificio" } } },
					{ Id = "Yo", Text = "Apartarla e intentar hacerlo tú", Effects = { Flags = { "KaelSacrificioForzado" }, Traits = { Valentia = 1 } } },
				} },
			{ Type = "MiniGame", Game = "Timing", Title = "La última palanca", Icon = "⚡", Hint = "Mantén el generador estable mientras Kael lo activa: pulsa en el verde",
				Rounds = 6, Need = 4, Zone = 0.18, Speed = 1.3,
				Win = { Flags = { "FinalLimpio" } }, Lose = { Flags = { "FinalAPelo" } } },
			{ Type = "Scene", Dialogue = "Adios" },
		},
		Dialogues = {
			Generador = { Lines = {
				{ S = "Kael", T = "¿Sabes por qué nunca salía de Valmar? Porque la última vez que salí, volví sola. Once salieron conmigo. Volví yo." },
				{ S = "Kael", T = "Hoy salgo otra vez. Y esta vez el que vuelve eres tú." },
				{ S = "ILEN", T = "Comandante… hay algo en mis fragmentos. Algo que Ilen grabó en la caja negra y nadie escuchó. ¿Quiere oírlo?" },
				{ S = "Kael", T = "…Sí." },
				{ S = "ILEN", T = "«Kael. No vuelvas a por mí. Pero si algún día alguien te necesita tanto como yo te necesité hoy, ve. Ve tú. Por las dos.»" },
				{ S = "Narrador", T = "Kael no dice nada. Se sienta en el asiento del copiloto y se abrocha el cinturón." },
			} },
			Centro = { Lines = {
				{ S = "Narrador", T = "El centro de la Grieta: un lugar sin arriba ni abajo, lleno de recuerdos de mundos enteros flotando como hojas. Ciudades que ya no existen. Gente que ya no existe. Todo gris, todo tranquilo." },
				{ S = "Narrador", T = "Y por todas partes, la Marea. No ataca. Te mira. Te recuerda." },
				{ S = "Kael", T = "Ahí. El ancla de todas las grietas. Si el generador explota aquí, se cierran todas. Para siempre." },
			} },
			Adios = { Lines = {
				{ S = "Narrador", T = "Kael te aparta de un empujón, con la misma fuerza con la que te tumbó en el examen. «Muerto. Levanta», te dice, y casi sonríe." },
				{ S = "Kael", T = "Has peleado con el cuerpo, con la espada y con el espíritu. Has unido siete mundos. Has traído a otros de vuelta. Ahora vuelve tú." },
				{ S = "Kael", T = "Dile a Brenn que la Academia es suya. Dile a Sorel que me equivoqué con ella el primer día: no iba a terminar entre los cuatro de cada diez. Iba a terminar la primera." },
				{ S = "Kael", T = "Y graba mi nombre en la pared. Arriba. Que se vea bien." },
				{ S = "Narrador", T = "Tira de la palanca. La luz lo llena todo." },
				{ S = "ILEN", T = "(muy bajito, con la voz de Ilen) Te esperábamos, comandante." },
			} },
		},
	}),

	main("Universo_Final", {
		Id = "Fin03_Paz",
		Title = "El universo recuperado",
		Description = "Despiertas en Valmar. Las grietas están cerradas. La Marea, al otro lado, para siempre. Ahora empieza lo difícil: vivir en paz.",
		Duration = { 18, 24 },
		Type = "El Universo · Epílogo",
		Moment = "Devolviste la paz al universo",
		Npcs = { "Brenn", "Sorel", "Maren", "Cosme", "ILEN" },
		Locations = { "Pista", "EntradaColegio" },
		Rewards = { Money = 25000, Flags = { "UniversoRecuperado" } },
		Props = {
			Nombre = { Kind = "Mural", Name = "La pared de los nombres", Prompt = "Grabar el nombre de Kael", Place = "EntradaColegio", Offset = V(-8, 0, 2), Dialogue = "Nombre", Once = true },
		},
		Steps = {
			{ Type = "Reach", Place = "Pista", Text = "Vuelve a la Academia", Actors = { at("Brenn", "Pista", 0, -6), at("Sorel", "Pista", 6, -2), at("Cosme", "Pista", -6, 0), at("Maren", "Pista", -8, 2) } },
			{ Type = "Scene", Dialogue = "Despertar", Actors = { at("Brenn", "Pista", 0, -6), at("Sorel", "Pista", 6, -2), at("Cosme", "Pista", -6, 0), at("Maren", "Pista", -8, 2) } },
			{ Type = "Use", Prop = "Nombre", Text = "Graba el nombre de Kael en la pared de los nombres", Actors = { at("Brenn", "EntradaColegio", 4, 4), at("Sorel", "EntradaColegio", 6, 6) } },
			{ Type = "Scene", Dialogue = "Pared", Actors = { at("Brenn", "EntradaColegio", 4, 4), at("Sorel", "EntradaColegio", 6, 6), at("Cosme", "EntradaColegio", -4, 6) } },
			{ Type = "Scene", Dialogue = "Epilogo" },
		},
		Dialogues = {
			Despertar = { Lines = {
				{ S = "Narrador", T = "Te despiertas en la enfermería de la Academia. Por la ventana entra luz. Luz normal, de sol, sin herida violeta en el cielo." },
				{ S = "Sorel", T = "Tres días durmiendo. Tres. He contado cada hora. No me mires así: tú lo habrías hecho igual." },
				{ S = "Brenn", T = "La flota trajo tu nave de vuelta. Solo venías tú dentro." },
				{ S = "Narrador", T = "Le cuentas lo de Kael. Brenn se gira hacia la ventana. Le tiemblan los hombros. Sorel le pone una mano en la espalda." },
				{ S = "Brenn", T = "…Dijo que la Academia es mía. Qué lista. Sabía que no podría decirle que no." },
			} },
			Nombre = { Lines = {
				{ S = "Narrador", T = "Con la punta de la espada de cadete, la primera que te dieron, grabas en la pared, arriba del todo, donde se vea bien: «KAEL. Comandante. No dejó a nadie atrás»." },
			} },
			Pared = { Lines = {
				{ S = "Cosme", T = "Me he pasado la vida mirando el cielo para volver a casa. Y ahora que puedo ir a casa cuando quiera, resulta que mi casa es esto también. Qué fastidio. Qué alegría." },
				{ S = "Maren", T = "Halden y yo vamos a convertir los generadores del Umbral en algo útil. Energía sin grietas. Sin cobrar a nadie por respirar." },
				{ S = "Sorel", T = "Mañana vuelvo al Sur. A mi calle. Voy a reconstruir la casa. Aunque sea de chatarra. ¿Me ayudas a cargar ladrillos?" },
				{ S = "Brenn", T = "La Academia necesita profesores. Alguien que enseñe a los nuevos que hay que saber cuándo retirarse… y cuándo no." },
				{ S = "ILEN", T = "He recalculado mi función. Ya no hay guerras que pilotar. Propongo dedicarme a llevar turistas entre los siete mundos. Con comentarios sarcásticos incluidos sin coste adicional." },
			} },
			Epilogo = { Lines = {
				{ S = "Narrador", T = "En Tefra no cae ni una bomba. En Miasma, los de arriba y los de abajo comparten las góndolas. En Siroco llueve dos veces al año y nadie paga por el agua." },
				{ S = "Narrador", T = "En Nivalis hay sol, y Tila ha convertido el último farol en un monumento. En Umbría crece un árbol que se llama Garza. En Tálasa, una madre y una hija bucean juntas. Vértice aprende a vivir sin cúpula." },
				{ S = "Narrador", T = "Y en Valmar, en una pared de un viejo colegio, hay un nombre nuevo arriba del todo." },
				{ S = "Narrador", T = "Soñabas con ser guerrero espacial. Lo fuiste. Y cuando ya no hizo falta pelear, seguiste siendo lo que te hizo serlo: alguien que no deja a nadie atrás." },
				{ S = "Narrador", T = "El universo está en paz. Por ahora. Las bestias que quedaron de este lado necesitan un hogar, los mundos tienen heridas que curar, y en el fondo del cielo, muy lejos, algo que no es la Marea acaba de abrir los ojos." },
			}, Effects = { Rel = { Sorel = 10, Brenn = 10, Cosme = 10, Maren = 10 } } },
		},
	}),
}
