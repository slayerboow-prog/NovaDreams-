-- ACTO II · LA COALICIÓN — «La Marea Gris» (Valmar) y TEFRA (18-11-2026; biblia: docs/historia/historia-principal-15h.md).
-- Después de «La Grieta: Proyecto Umbral». Capítulos Coalicion_Marea y Coalicion_Tefra (shared/LifeStory/Chapters).
--   Mar01_Senal      «La primera ola»        la Marea manda su primera señal; el asentamiento, dividido por tu decisión
--   Mar02_Coalicion  «Siete puertas»         conoces a Cosme y a ILEN; Kael funda la Coalición: cerrar siete grietas
--   Tef01_Llegada    «Tierra quemada»        Tefra: aterrizar en mitad de una guerra; Cosme busca su calle
--   Tef02_Tregua     «La tregua de ceniza»   sentar a la resistencia y al Dominio en la misma mesa; alguien lo sabotea
--   Tef03_Pozo       «El pozo de magma»      bajar al pozo, cerrar la grieta de Tefra y decidir qué pasa con Corvo
-- Para +17 (público adulto): tragedia, decisiones grises, humor seco. Todo se juega.

local V = Vector3.new

local PISTA = {
	{ Npc = "Kael", Place = "Pista", Offset = V(0, 0, -6) },
	{ Npc = "Sorel", Place = "Pista", Offset = V(6, 0, -2), Mode = "Chat" },
	{ Npc = "Brenn", Place = "Pista", Offset = V(-4, 0, -4) },
	{ Npc = "Maren", Place = "Pista", Offset = V(-8, 0, 0) },
}
local function at(npc: string, place: string, x: number, z: number, mode: string?): { [string]: any }
	return { Npc = npc, Place = place, Offset = V(x, 0, z), Mode = mode }
end
local COSME_SIGUE = { Npc = "Cosme", Mode = "Follow" }
local SOREL_SIGUE = { Npc = "Sorel", Mode = "Follow" }

local function main(chapter: string, t: { [string]: any }): { [string]: any }
	t.Kind = "Main"
	t.Chapter = chapter
	t.AgeRange = t.AgeRange or { 18, 45 }
	t.Difficulty = t.Difficulty or 4
	t.Npcs = t.Npcs or { "Kael", "Brenn", "Sorel", "Maren", "Cosme", "ILEN" }
	t.Locations = t.Locations or { "Pista" }
	return t
end

return {
	---------------------------------------------------------------------
	-- La Marea Gris · 1
	---------------------------------------------------------------------
	main("Coalicion_Marea", {
		Id = "Mar01_Senal",
		Title = "La primera ola",
		Description = "Una semana después del Umbral. El asentamiento discute tu decisión en cada esquina. Y esta noche, todas las radios de Valmar captan el mismo sonido.",
		Duration = { 15, 20 },
		Type = "La Coalición · Valmar",
		Next = { "Mar02_Coalicion" },
		Moment = "Oíste a la Marea Gris",
		Rewards = { Money = 5000 },
		Props = {
			Pintada = { Kind = "Mural", Name = "Una pintada fresca en la pared de la Academia", Prompt = "Leer la pintada", Place = "EntradaColegio", Offset = V(-6, 0, 3), Dialogue = "Pintada", Once = true },
			Radio = { Kind = "Maquina", Name = "La radio de la Academia, chillando", Prompt = "Bajar el volumen y escuchar", Place = "Pista", Offset = V(8, 0, 4), Dialogue = "Radio", Once = true },
		},
		Steps = {
			{ Type = "Scene", Dialogue = "Semana", Actors = PISTA },
			{ Type = "Use", Prop = "Pintada", Text = "Alguien ha pintado algo en la entrada de la Academia. Míralo" },
			{ Type = "Scene", Dialogue = "Cenicientos", Actors = { at("Ceniciento1", "EntradaColegio", 6, 8), at("Ceniciento2", "EntradaColegio", 9, 6) } },
			{ Type = "Fight", Place = "EntradaColegio", Respawn = "EntradaColegio", Action = "Golpe ⚔", HP = 5,
				Text = "Los Hijos de la Ceniza intentan quemar la puerta de la Academia. Detenlos ({count}/{total})",
				CaughtLine = "(Te empujan contra la pared. Huele a gasolina.) ¡Arriba!",
				Enemies = {
					{ Npc = "Ceniciento1", Offset = V(6, 0, 8), Speed = 10, HP = 3, Bye = "La Marea viene igual. Lo verás." },
					{ Npc = "Ceniciento2", Offset = V(9, 0, 6), Speed = 10, HP = 3, Bye = "(se ríe en el suelo) Varn tenía razón contigo." },
				} },
			{ Type = "Use", Prop = "Radio", Text = "La radio de la pista se ha vuelto loca. Escucha" },
			{ Type = "MiniGame", Game = "Timing", Title = "Filtrar la señal", Icon = "📡", Hint = "Separa la señal del ruido: pulsa en el verde",
				Rounds = 4, Need = 3, Zone = 0.22, Speed = 1.15,
				Win = { Flags = { "MareaSenalClara" } }, Lose = { Flags = { "MareaSenalSucia" } } },
			{ Type = "Scene", Dialogue = "Ola", Actors = PISTA },
		},
		Dialogues = {
			Semana = { Lines = {
				{ S = "Narrador", T = "Una semana después del sótano del Consejo. En el comedor, la gente se sienta según lo que piensa de ti." },
				{ S = "Sorel", T = "La mitad del comedor dice que te equivocaste. La otra mitad, que nos salvaste. Yo digo tu nombre, que es más corto." },
				{ S = "Brenn", T = "Varn ha desaparecido. Y con él, veinte personas del asentamiento. Dejaron una nota en la puerta del Consejo: «Nos vamos con la Marea»." },
				{ S = "Kael", T = "Se hacen llamar los Hijos de la Ceniza. Dicen que rendirse a lo que viene es la única forma de sobrevivir. Gente asustada siguiendo a un hombre que nunca se ha asustado de nada." },
			} },
			Pintada = { Lines = {
				{ S = "Narrador", T = "En la pared de los nombres, alguien ha pintado con ceniza mojada: «LOS QUE PELEAN, ARDEN»." },
				{ S = "Narrador", T = "Debajo, un olor dulce y químico. Hay bidones al lado de la puerta." },
			} },
			Cenicientos = { Lines = {
				{ S = "Ceniciento1", T = "No queremos hacer daño a nadie. Solo queremos que se acabe la guerra. Si no hay guerreros, la Marea no tendrá con quién pelear." },
				{ S = "Ceniciento2", T = "Apártate, guerrero. Es una puerta. Las puertas se vuelven a hacer." },
			} },
			Radio = { Lines = {
				{ S = "Narrador", T = "No es una voz. Es un sonido largo y grave, como el de un barco enorme muy lejos. Se repite cada once segundos. Todas las radios de Valmar lo están captando a la vez." },
			} },
			Ola = { Lines = {
				{ S = "Maren", T = "No viene de la Grieta de Valmar. Viene de siete sitios a la vez. Siete puntos en el cielo." },
				{ S = "Maren", T = "El Consorcio no abrió una grieta. Abrió siete, en siete mundos. Y la Marea las está oyendo todas." },
				{ S = "Kael", T = "Entonces no basta con cerrar la nuestra." },
				{ S = "Maren", T = "No. Si queda una sola abierta, la Marea entra por ella. Y desde ese mundo, salta a todos los demás." },
				{ S = "Brenn", T = "Siete mundos que no conocemos, llenos de gente que no sabe que existimos. Genial. ¿Alguna buena noticia?" },
				{ S = "Kael", T = "Una. Conozco a alguien que nació en uno de ellos." },
			} },
		},
	}),

	---------------------------------------------------------------------
	-- La Marea Gris · 2
	---------------------------------------------------------------------
	main("Coalicion_Marea", {
		Id = "Mar02_Coalicion",
		Title = "Siete puertas",
		Description = "Un anciano que llegó a Valmar por una grieta hace treinta y ocho años. Una nave con la voz de una muerta. Y una comandante que va a pedirle al universo que confíe en una ciudad de chatarra.",
		Duration = { 18, 24 },
		Type = "La Coalición · Valmar",
		Moment = "Fundaste la Coalición de los Mundos",
		Rewards = { Money = 6000, Flags = { "Coalicion" } },
		Locations = { "Pista", "TallerMaren", "PuertoEspacial" },
		Props = {
			Mapa = { Kind = "Papel", Name = "Un mapa estelar dibujado a mano, amarillento", Prompt = "Mirar el mapa", Place = "TallerMaren", Offset = V(-4, 0, 3), Dialogue = "MapaCosme", Once = true },
			Nucleo = { Kind = "Maquina", Name = "El núcleo de la IA de la nave", Prompt = "Despertar a la IA", Place = "PuertoEspacial", Offset = V(0, 0, -6), Dialogue = "Despertar", Once = true },
		},
		Steps = {
			{ Type = "Reach", Place = "TallerMaren", Text = "Kael te manda al taller de Maren: el anciano del que habló te espera allí",
				Actors = { at("Cosme", "TallerMaren", 2, 4), at("Maren", "TallerMaren", -3, 4) } },
			{ Type = "Talk", Npc = "Cosme", Dialogue = "Cosme", Text = "Habla con el anciano",
				Actors = { at("Cosme", "TallerMaren", 2, 4), at("Maren", "TallerMaren", -3, 4) } },
			{ Type = "Use", Prop = "Mapa", Text = "Cosme ha extendido un mapa estelar en la mesa. Míralo" },
			{ Type = "Reach", Place = "PuertoEspacial", Text = "Ve al puerto espacial con Cosme: tu nave necesita un navegante",
				Actors = { COSME_SIGUE } },
			{ Type = "Use", Prop = "Nucleo", Text = "Despierta la IA de tu nave", Actors = { at("Cosme", "PuertoEspacial", 4, 4), at("Kael", "PuertoEspacial", -4, 6) } },
			{ Type = "Scene", Dialogue = "Ilen", Actors = { at("Cosme", "PuertoEspacial", 4, 4), at("Kael", "PuertoEspacial", -4, 6) } },
			{ Type = "Choice", Key = "MarILEN", Text = "La IA habla con la voz de Ilen, la segunda de Kael que murió en Tefra. Kael no puede ni mirarla. ¿Qué haces?",
				Options = {
					{ Id = "Mantener", Text = "Mantener la voz: «Es la mejor IA que tenemos. Y quizá Ilen querría seguir volando.»", Effects = { Flags = { "ILENVoz" }, Rel = { Kael = -3 } } },
					{ Id = "Cambiar", Text = "Pedirle a Maren que le cambie la voz, por Kael", Effects = { Flags = { "ILENNeutra" }, Rel = { Kael = 6 } } },
				},
				Actors = { at("Kael", "PuertoEspacial", -4, 6) } },
			{ Type = "Reach", Place = "Pista", Text = "Vuelve a la Academia: Kael ha reunido a todos", Actors = PISTA },
			{ Type = "Scene", Dialogue = "Coalicion", Actors = PISTA },
		},
		Dialogues = {
			Cosme = { Lines = {
				{ S = "Cosme", T = "Así que tú eres la criatura que cerró… o abrió… o lo que sea que hiciste con la Grieta. Encantado. Cosme. Setenta y un años, cuarenta de ellos explicándole a la gente que no estoy loco." },
				{ S = "Cosme", T = "Nací en Tefra. A los nueve años se abrió un agujero en el cielo de mi barrio y me caí dentro. Aparecí en un descampado de Valmar con un zapato y sin hermana." },
				{ S = "Cosme", T = "Me pasé la vida midiendo el cielo para encontrar el camino de vuelta. Me llamaban el loco del garaje. Ahora resulta que el loco del garaje es el único con un mapa." },
				{ S = "Maren", T = "Sus mediciones coinciden con las mías. Al milímetro. Ha hecho a mano lo que el Consorcio hizo con mil millones." },
				{ S = "Cosme", T = "Con mil millones y sin escrúpulos. Yo solo tenía lo segundo… perdón, lo primero no lo tenía. Da igual. Mira el mapa." },
			} },
			MapaCosme = { Lines = {
				{ S = "Narrador", T = "Siete círculos dibujados a lápiz, unidos por líneas. Junto a cada uno, un nombre y una anotación con letra de viejo: «Tefra (casa). Miasma (no respirar). Siroco (llevar agua). Nivalis (llevar luz). Umbría (no tocar las raíces). Tálasa (aprender a nadar). Vértice (no firmar nada)»." },
				{ S = "Cosme", T = "Siete mundos, siete grietas. El Consorcio las abrió todas con el mismo método. Y lo que tú llamas la Marea… en Tefra lo llamábamos el Silencio. Mi abuela decía que se comía las estrellas." },
			} },
			Despertar = { Lines = {
				{ S = "Narrador", T = "El núcleo de la IA zumba. Las luces de la cabina se encienden una a una." },
			} },
			Ilen = { Lines = {
				{ S = "ILEN", T = "Sistemas en línea. Hola, piloto. Antes de que preguntes: no, no puedo hacer café. Sí, he visto cómo aterrizas. No, no voy a comentarlo. Todavía." },
				{ S = "Narrador", T = "Kael se queda de piedra. Esa voz." },
				{ S = "Kael", T = "Esa voz es de Ilen. Mi segunda. Murió en Tefra hace tres años." },
				{ S = "Cosme", T = "Los del puerto entrenaron la IA con las grabaciones de la caja negra. Era lo único que tenían. Lo siento, comandante." },
				{ S = "ILEN", T = "Tengo… fragmentos. Una canción que no sé de dónde sale. Y una frase que se repite: «Kael, no vuelvas a por mí». ¿Significa algo para alguien?" },
				{ S = "Narrador", T = "Kael se da la vuelta y se aleja unos pasos. No dice nada." },
			} },
			Coalicion = { Lines = {
				{ S = "Kael", T = "Siete grietas abiertas por el Consorcio. Siete mundos que no nos conocen. Y una cosa que se come mundos llamando a la puerta." },
				{ S = "Kael", T = "Valmar no puede sola. Ningún mundo puede solo. Vamos a ir uno a uno, a cerrar cada grieta y a pedirle a cada mundo que pelee con nosotros." },
				{ S = "Kael", T = "Desde hoy esto no es la Academia de Valmar. Es la Coalición. Y tú eres su primera guerrera de verdad. Su primer guerrero. Lo que seas: eres la primera persona que voy a mandar ahí fuera." },
				{ S = "Brenn", T = "Yo me quedo a defender Valmar. Si Varn vuelve, quiero ser el primero en verle." },
				{ S = "Sorel", T = "Yo voy contigo. No es una pregunta." },
				{ S = "Cosme", T = "Primera parada: Tefra. Mi casa. Llevo treinta y ocho años ensayando lo que voy a decir cuando la vea. Seguro que lo olvido todo al bajar de la nave." },
				{ S = "ILEN", T = "Ruta calculada. Duración estimada del viaje: seis minutos. Duración estimada de las discusiones sobre quién se sienta delante: indeterminada." },
			}, Effects = { Rel = { Kael = 4, Sorel = 4 } } },
		},
	}),

	---------------------------------------------------------------------
	-- Tefra · 1
	---------------------------------------------------------------------
	main("Coalicion_Tefra", {
		Id = "Tef01_Llegada",
		Title = "Tierra quemada",
		Description = "Tefra: un mundo volcánico en guerra desde hace tres generaciones. Cosme vuelve a casa después de treinta y ocho años. No sabe lo que va a encontrar.",
		Duration = { 20, 25 },
		Type = "La Coalición · Tefra",
		Next = { "Tef02_Tregua" },
		Moment = "Pisaste Tefra con Cosme",
		Npcs = { "Cosme", "Sorel", "DaliaRenn", "ILEN" },
		Locations = { "Tefra_Plataforma", "Tefra_RuinasOvillo", "Tefra_Refugio" },
		Rewards = { Money = 5000 },
		Props = {
			Calle = { Kind = "Marcador", Name = "Una placa de calle medio fundida", Prompt = "Limpiar la placa", Place = "Tefra_RuinasOvillo", Offset = V(-4, 0, 6), Dialogue = "Placa", Once = true },
			Zapato = { Kind = "Caja", Name = "Un zapato de niño, petrificado en la ceniza", Prompt = "Mirar el zapato", Place = "Tefra_RuinasOvillo", Offset = V(6, 0, 8), Dialogue = "Zapato", Once = true },
		},
		Steps = {
			{ Type = "Event", Event = "PlanetLanded", Match = { Planet = "Tefra" }, Text = "Despega desde el puerto espacial y aterriza en Tefra (el planeta rojo)" },
			{ Type = "Scene", Dialogue = "Llegada", Actors = { at("Cosme", "Tefra_Plataforma", 3, 2), at("Sorel", "Tefra_Plataforma", -3, 2) } },
			{ Type = "Event", Event = "BeastKilled", Count = 8, Match = { Planet = "Tefra" }, Text = "Las bestias de Tefra huyen hacia la ciudad: abre camino ({count}/{total})",
				Actors = { COSME_SIGUE, SOREL_SIGUE } },
			{ Type = "Reach", Place = "Tefra_RuinasOvillo", Text = "Cosme quiere ver su barrio: el Ovillo", Actors = { COSME_SIGUE, SOREL_SIGUE } },
			{ Type = "Group", Text = "Busca la calle de Cosme entre las ruinas", Actors = { COSME_SIGUE },
				Steps = {
					{ Type = "Use", Prop = "Calle", Text = "La placa de la calle" },
					{ Type = "Use", Prop = "Zapato", Text = "El zapato en la ceniza" },
				} },
			{ Type = "Scene", Dialogue = "Emboscada", Actors = { at("DaliaRenn", "Tefra_RuinasOvillo", 0, 14), at("Cosme", "Tefra_RuinasOvillo", 2, 4) } },
			{ Type = "Talk", Npc = "DaliaRenn", Dialogue = "Dalia", Text = "La mujer del rifle quiere hablar. Baja la espada",
				Actors = { at("DaliaRenn", "Tefra_RuinasOvillo", 0, 14), at("Cosme", "Tefra_RuinasOvillo", 2, 4) } },
		},
		Dialogues = {
			Llegada = { Lines = {
				{ S = "Narrador", T = "El cielo de Tefra es naranja. El aire quema la garganta. A lo lejos, una ciudad redonda bajo una cúpula agrietada, y columnas de humo que suben derechas, sin viento." },
				{ S = "Cosme", T = "Huele igual. A azufre y a pan. Siempre olió a azufre y a pan." },
				{ S = "Cosme", T = "Tenía preparado un discurso. Muy bonito. Con una metáfora sobre volver. …Lo he olvidado todo. Ya lo dije." },
				{ S = "ILEN", T = "(por la radio) Detecto artillería a dos kilómetros. Aviso por si alguien quiere seguir llorando a cubierto." },
				{ S = "Sorel", T = "ILEN." },
				{ S = "ILEN", T = "Era un comentario de apoyo emocional. Muy sutil." },
			} },
			Placa = { Lines = {
				{ S = "Narrador", T = "Frotas la ceniza con la manga. Letras redondas tefranas, medio fundidas: «Calle del Horno»." },
				{ S = "Cosme", T = "Calle del Horno. Mi madre hacía pan para todo el barrio. A las cinco de la mañana olía la calle entera." },
				{ S = "Narrador", T = "De la calle del Horno queda un muro. Uno solo, con una ventana redonda sin cristal." },
			} },
			Zapato = { Lines = {
				{ S = "Narrador", T = "Un zapato pequeño, de niño, petrificado en la ceniza endurecida. Igual que el que Cosme llevaba cuando apareció en Valmar." },
				{ S = "Cosme", T = "(en voz muy baja) No es el de mi hermana. No puede ser. Han pasado treinta y ocho años." },
				{ S = "Cosme", T = "…Pero me lo voy a llevar igual." },
			} },
			Emboscada = { Lines = {
				{ S = "Narrador", T = "Un chasquido metálico. Una mujer con un rifle os apunta desde lo alto del muro. Detrás, cinco más." },
				{ S = "DaliaRenn", T = "Manos donde las vea. Uniformes que no conozco y una nave que no es del Dominio. O sois muy valientes o muy idiotas." },
				{ S = "Cosme", T = "Un poco de cada, señora. Como todo el mundo." },
			} },
			Dalia = { Lines = {
				{ S = "DaliaRenn", T = "Dalia Renn. Resistencia del Ovillo. El Dominio bombardea este barrio cada noche porque aquí se esconden los que no quieren luchar en su guerra." },
				{ S = "DaliaRenn", T = "¿Una cosa que se come mundos? Llevamos tres generaciones matándonos entre nosotros. Si viene algo peor, por lo menos será algo nuevo." },
				{ S = "Narrador", T = "Le cuentas lo de las siete grietas, lo de la Marea, lo de las bestias que huyen. Dalia se queda callada mucho rato." },
				{ S = "DaliaRenn", T = "La grieta de Tefra está en el Pozo de Magma, en territorio del Dominio. El general Corvo la usa para alimentar su forja de guerra. Nunca la cerrará." },
				{ S = "DaliaRenn", T = "A menos que alguien le convenza de que hay algo peor que perder una guerra." },
			}, Effects = { Rel = { DaliaRenn = 6 } } },
		},
	}),

	---------------------------------------------------------------------
	-- Tefra · 2
	---------------------------------------------------------------------
	main("Coalicion_Tefra", {
		Id = "Tef02_Tregua",
		Title = "La tregua de ceniza",
		Description = "Sentar a la resistencia y al Dominio en la misma mesa. En un mundo donde la última tregua terminó con un incendio.",
		Duration = { 20, 25 },
		Type = "La Coalición · Tefra",
		Next = { "Tef03_Pozo" },
		Moment = "Intentaste la tregua de Tefra",
		Npcs = { "Cosme", "Sorel", "DaliaRenn", "GeneralCorvo", "Ceniciento1", "ILEN" },
		Locations = { "Tefra_TierraDeNadie", "Tefra_Refugio" },
		Rewards = { Money = 5500 },
		Props = {
			Bandera = { Kind = "Marcador", Name = "Un mástil en mitad de la tierra de nadie", Prompt = "Izar la bandera blanca", Place = "Tefra_TierraDeNadie", Offset = V(0, 0, 4), Dialogue = "Bandera", Once = true },
			Mesa = { Kind = "Caja", Name = "Una mesa de campaña con dos sillas", Prompt = "Preparar la mesa", Place = "Tefra_TierraDeNadie", Offset = V(4, 0, 10), Dialogue = "Mesa", Once = true },
			Detonador = { Kind = "Maquina", Name = "Un cable que sale de debajo de la mesa", Prompt = "Seguir el cable", Place = "Tefra_TierraDeNadie", Offset = V(-8, 0, 14), Dialogue = "Cable", Once = true },
		},
		Steps = {
			{ Type = "Reach", Place = "Tefra_TierraDeNadie", Text = "Ve a la tierra de nadie, entre la resistencia y el Dominio", Actors = { COSME_SIGUE, SOREL_SIGUE } },
			{ Type = "Group", Text = "Prepara el encuentro",
				Steps = {
					{ Type = "Use", Prop = "Bandera", Text = "Iza la bandera blanca" },
					{ Type = "Use", Prop = "Mesa", Text = "Prepara la mesa" },
				} },
			{ Type = "Scene", Dialogue = "Encuentro", Actors = { at("DaliaRenn", "Tefra_TierraDeNadie", -6, 10), at("GeneralCorvo", "Tefra_TierraDeNadie", 8, 10), at("Cosme", "Tefra_TierraDeNadie", 0, 2) } },
			{ Type = "Choice", Key = "TefTregua", Text = "Corvo pide que la resistencia entregue las armas antes de hablar. Dalia pide que Corvo retire la artillería del Ovillo. Ninguno cederá primero. ¿Qué propones?",
				Options = {
					{ Id = "Ambos", Text = "Que los dos cedan a la vez, a la cuenta de tres, delante de ti", Effects = { Flags = { "TreguaAmbos" }, Traits = { Responsabilidad = 1 } } },
					{ Id = "Corvo", Text = "Darle la razón a Corvo: tiene el ejército, sin él no hay tregua", Effects = { Flags = { "TreguaCorvo" }, Rel = { DaliaRenn = -8, GeneralCorvo = 6 } } },
					{ Id = "Dalia", Text = "Darle la razón a Dalia: no se negocia bajo los cañones", Effects = { Flags = { "TreguaDalia" }, Rel = { DaliaRenn = 8, GeneralCorvo = -6 } } },
				},
				Actors = { at("DaliaRenn", "Tefra_TierraDeNadie", -6, 10), at("GeneralCorvo", "Tefra_TierraDeNadie", 8, 10) } },
			{ Type = "Use", Prop = "Detonador", Text = "Sorel ha visto algo debajo de la mesa. Sigue el cable" },
			{ Type = "MiniGame", Game = "Timing", Title = "Desactivar la carga", Icon = "💣", Hint = "Corta los cables en orden: pulsa en el verde. Si fallas dos, corre",
				Rounds = 4, Need = 3, Zone = 0.22, Speed = 1.2,
				Win = { Flags = { "TreguaBombaDesactivada" } }, Lose = { Flags = { "TreguaBombaExplota" } } },
			{ Type = "Scene", Dialogue = "Sabotaje", Actors = { at("Ceniciento1", "Tefra_TierraDeNadie", -14, 18) } },
			{ Type = "Escape", Place = "Tefra_Refugio", Respawn = "Tefra_TierraDeNadie", Catch = 4,
				Text = "Persigue al saboteador hasta el refugio antes de que escape",
				CaughtLine = "(Se te escapa entre el humo. Le vuelves a ver al final de la calle.)",
				Actors = { { Npc = "Ceniciento1", Place = "Tefra_TierraDeNadie", Offset = V(-10, 0, 16), Mode = "Flee", Prompt = false } } },
			{ Type = "Scene", Dialogue = "Pacto", Actors = { at("DaliaRenn", "Tefra_Refugio", -4, 4), at("GeneralCorvo", "Tefra_Refugio", 4, 4), at("Cosme", "Tefra_Refugio", 0, 6) } },
		},
		Dialogues = {
			Bandera = { Lines = {
				{ S = "Narrador", T = "La tela blanca sube por el mástil. Al otro lado de la tierra de nadie, cientos de cañones dejan de moverse. Por primera vez en meses, no cae nada del cielo." },
			} },
			Mesa = { Lines = {
				{ S = "Cosme", T = "Dos sillas. Ponlas a la misma altura. En Tefra, la silla más alta es una declaración de guerra. Literalmente: hay una ley." },
			} },
			Encuentro = { Lines = {
				{ S = "GeneralCorvo", T = "General Bastián Corvo. Dominio de Tefra. Me han dicho que un extranjero quiere salvarnos del fin del mundo. Llevamos noventa años con el fin del mundo. Nos va bastante bien." },
				{ S = "DaliaRenn", T = "Su forja se come la grieta, general. Y la grieta está llamando a algo. Lo hemos oído en la radio. Usted también." },
				{ S = "GeneralCorvo", T = "Lo he oído. Once segundos. Mis soldados ya no duermen. …Por eso he venido." },
			} },
			Cable = { Lines = {
				{ S = "Narrador", T = "Un cable fino, cubierto de ceniza, sale de debajo de la mesa y se pierde en un cráter. En el fondo del cráter, una carga. Con un temporizador. Faltan cuarenta segundos." },
			} },
			Sabotaje = { Lines = {
				{ S = "Narrador", T = "Entre el humo, alguien echa a correr. Lleva la cara pintada de ceniza." },
				{ S = "Sorel", T = "¡Un Hijo de la Ceniza! ¿Aquí? ¡Están en todos los mundos!" },
			} },
			Pacto = { Lines = {
				{ S = "Narrador", T = "El saboteador lleva en el bolsillo una carta con un sello de ceniza y una firma: «A. Varn». Instrucciones para volar la tregua de Tefra." },
				{ S = "GeneralCorvo", T = "Alguien de su mundo ha intentado matarnos a los dos. Y su gente ha impedido que lo consiga." },
				{ S = "DaliaRenn", T = "Tres generaciones de guerra y lo que nos sienta en la misma mesa es un enemigo común que ninguno ha visto nunca." },
				{ S = "GeneralCorvo", T = "Tregua. Mientras dure lo del cielo. Le abriré el Pozo de Magma. Pero la forja de la grieta da de comer a cuarenta mil personas. Si la cierran, quiero saber qué les digo." },
				{ S = "Cosme", T = "Dígales la verdad, general. A veces funciona. Casi nunca, pero a veces." },
			}, Effects = { Rel = { DaliaRenn = 4, GeneralCorvo = 4 } } },
		},
	}),

	---------------------------------------------------------------------
	-- Tefra · 3
	---------------------------------------------------------------------
	main("Coalicion_Tefra", {
		Id = "Tef03_Pozo",
		Title = "El pozo de magma",
		Description = "La grieta de Tefra está en el fondo del Pozo de Magma, alimentando la forja de guerra del Dominio. Bajar es fácil. Volver, no tanto.",
		Duration = { 22, 28 },
		Difficulty = 5,
		Type = "La Coalición · Tefra",
		Moment = "Cerraste la grieta de Tefra",
		Npcs = { "Cosme", "Sorel", "DaliaRenn", "GeneralCorvo", "ILEN" },
		Locations = { "Tefra_PozoMagma", "Tefra_Central" },
		Rewards = { Money = 8000, Flags = { "GrietaTefraCerrada" } },
		Props = {
			Valvula = { Kind = "Maquina", Name = "La válvula principal de la forja", Prompt = "Cortar el paso de la forja", Place = "Tefra_PozoMagma", Offset = V(-8, 0, 6), Dialogue = "Valvula", Once = true },
			Ancla = { Kind = "Cristal", Name = "El ancla de la grieta, un cristal que late", Prompt = "Colocar el disruptor de Maren", Place = "Tefra_PozoMagma", Offset = V(0, 0, 14), Dialogue = "Ancla", Once = true },
			Nombre = { Kind = "Mural", Name = "Nombres grabados en la pared del pozo", Prompt = "Leer los nombres", Place = "Tefra_PozoMagma", Offset = V(8, 0, 4), Dialogue = "Nombres", Once = true },
		},
		Steps = {
			{ Type = "Reach", Place = "Tefra_Central", Text = "Ve a la central del Dominio: Corvo te abre la puerta del pozo",
				Actors = { at("GeneralCorvo", "Tefra_Central", 4, 4), COSME_SIGUE, SOREL_SIGUE } },
			{ Type = "Reach", Place = "Tefra_PozoMagma", Text = "Baja al Pozo de Magma (cuidado con el calor)", Actors = { SOREL_SIGUE } },
			{ Type = "Event", Event = "BeastKilled", Count = 10, Match = { Planet = "Tefra" }, Text = "Las bestias del pozo se apelotonan junto a la grieta. Ábrete paso ({count}/{total})", Actors = { SOREL_SIGUE } },
			{ Type = "Group", Text = "Prepara el cierre de la grieta", Actors = { SOREL_SIGUE },
				Steps = {
					{ Type = "Use", Prop = "Nombre", Text = "Los nombres de la pared" },
					{ Type = "Use", Prop = "Valvula", Text = "Corta el paso de la forja" },
					{ Type = "Use", Prop = "Ancla", Text = "Coloca el disruptor en el ancla" },
				} },
			{ Type = "MiniGame", Game = "Timing", Title = "Cerrar la grieta de Tefra", Icon = "🌀", Hint = "El disruptor tiene que vibrar con la grieta: pulsa en el verde en cada pulso",
				Rounds = 5, Need = 3, Zone = 0.22, Speed = 1.2,
				Win = { Flags = { "TefraCierreLimpio" } }, Lose = { Flags = { "TefraCierreSucio" } } },
			{ Type = "Scene", Dialogue = "Colapso", Actors = { SOREL_SIGUE } },
			{ Type = "Event", Event = "BeastKilled", Count = 6, Match = { Planet = "Tefra" }, Text = "El pozo se derrumba y lo último que salió de la grieta te corta el paso. Sal de ahí ({count}/{total})", Actors = { SOREL_SIGUE } },
			{ Type = "Choice", Key = "TefCorvo", Text = "Arriba, Corvo ha visto el apagón de la forja por la radio. Sus generales le exigen que te detenga y reabra el pozo. Te pide que hables con sus tropas. ¿Qué les dices?",
				Options = {
					{ Id = "Verdad", Text = "La verdad: la forja daba de comer a la guerra y a la Marea a la vez", Effects = { Flags = { "TefraVerdad" }, Rel = { GeneralCorvo = 6 } } },
					{ Id = "Coalicion", Text = "Que la Coalición traerá comida y energía de otros mundos si se unen", Effects = { Flags = { "TefraPromesa" }, Rel = { GeneralCorvo = 3, DaliaRenn = 3 } } },
				},
				Actors = { at("GeneralCorvo", "Tefra_Central", 4, 4), at("DaliaRenn", "Tefra_Central", -4, 4) } },
			{ Type = "Scene", Dialogue = "Paz", Actors = { at("GeneralCorvo", "Tefra_Central", 4, 4), at("DaliaRenn", "Tefra_Central", -4, 4), at("Cosme", "Tefra_Central", 0, 8) } },
		},
		Dialogues = {
			Nombres = { Lines = {
				{ S = "Narrador", T = "Cientos de nombres rayados en la roca del pozo. Los trabajadores de la forja. Junto a cada uno, una fecha. Muchos con la misma: el día que se abrió la grieta." },
				{ S = "Narrador", T = "Entre ellos, uno escrito con letra infantil: «Lía». Debajo: «esperando a Cosme»." },
				{ S = "Sorel", T = "Cosme dijo que su hermana se llamaba Lía." },
			} },
			Valvula = { Lines = {
				{ S = "Narrador", T = "Giras la rueda. El rugido de la forja se apaga como un animal que se duerme. En la ciudad, arriba, cuarenta mil luces parpadean y se apagan." },
			} },
			Ancla = { Lines = {
				{ S = "Narrador", T = "El ancla es un cristal del tamaño de una persona, hundido en la roca, que late con la misma cadencia que el sonido de las radios: once segundos." },
			} },
			Colapso = { Lines = {
				{ S = "Narrador", T = "El cristal se resquebraja. La grieta se estrecha con un chillido que se oye en todo Tefra y se cierra. Las paredes del pozo empiezan a caer." },
				{ S = "ILEN", T = "(por la radio) Os recomiendo encarecidamente salir de ahí. Tengo cálculos sobre lo que pasará si no salís. No os van a gustar." },
			} },
			Paz = { Lines = {
				{ S = "GeneralCorvo", T = "Noventa años de guerra para alimentar una herida en el cielo. Y la cerró un extranjero en una tarde." },
				{ S = "GeneralCorvo", T = "El Dominio se une a la Coalición. No por amor: por vergüenza. A veces sirve igual." },
				{ S = "DaliaRenn", T = "El Ovillo también. Y yo personalmente vigilaré que el general cumpla." },
				{ S = "Narrador", T = "Cosme está apartado, mirando el zapato de niño que encontró en su calle. Le cuentas lo del nombre en la pared del pozo." },
				{ S = "Cosme", T = "Lía. Me esperó. Bajó a trabajar a la forja y me siguió esperando." },
				{ S = "Cosme", T = "(se seca los ojos con la manga, se recompone) Bueno. Una grieta menos. Seis más. Mi hermana estaría orgullosa. Y me diría que me cambiara de camisa, que esta da pena." },
				{ S = "Narrador", T = "Esa noche, en Tefra, no cae ni una bomba. Los niños del Ovillo salen a la calle a mirar un cielo que ya no tiene herida." },
			}, Effects = { Rel = { Cosme = 10, Sorel = 4 } } },
		},
	}),
}
