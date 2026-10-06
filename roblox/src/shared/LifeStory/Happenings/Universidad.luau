-- Escenas de la UNIVERSIDAD (capítulo Joven_Universidad). Formato: shared/LifeStory/Sequencer.luau
-- (CINEMATIC_SCENE, auditoría docs/historia/auditoria-narrativa-cinematica.md §6.1 y §6.2).
--
-- Las lanzan las misiones Uni*.luau con un paso de cine: { Type = "Cinematic", Id = "Uni06_Ceremonia",
-- Actors = { … } }. El reparto de la misión ya está en su sitio (lo pone SceneService) y la escena lo
-- toma prestado con Use: no aparece nadie de golpe. Quien llega tarde (Carla, Sara, {abu}…) lo crea
-- la escena con Enter: aparece lejos y ANDA hasta su marca; si la marca es la misma que la del paso
-- siguiente de la misión, el relevo no se nota.
--
-- Cosas a tener en cuenta al escribir aquí:
--   * Los lugares "$Carrera.X" no valen como ancla (los resuelve la misión): en la facultad, las marcas
--     van referidas al jugador ("Yo") o a un actor.
--   * Los textos solo reciben {nombre}. Nada de {abu} ni {Saludo}; el token de género {o/a} sale como
--     «o/a» mientras HappeningService no mande el género (ver el informe del paquete P8c): se escribe
--     en neutro.
--   * Cada escena empieza con un comentario que responde a las cinco preguntas de la regla de oro.
--   * Continuidad (W-05): las frases con If leen lo que hiciste antes (marcas, recuerdos, decisiones,
--     objetos). scripts/test-universidad.luau comprueba que esas lecturas siguen ahí.

local V = Vector3.new

-- Condiciones que se repiten
local function choice(key: string, value: string): any
	return { Choices = { [key] = value } }
end
local function flag(name: string): any
	return { Flags = { name } }
end
local function memory(name: string): any
	return { Memories = { name } }
end

local CON_LEIRE = flag("ConocesALeire")
local CON_MATEO_FIESTA = flag("AyudasteAMateo")
local MATEO_INGENIERIA = { Flags = { "AyudasteAMateo" }, Choices = { Estudios = "Ingenieria" } }

-- La persona de la cita (UniS_Cita), si salió bien: { Npc, condición de pareja, condición de amistad }
local CITA = { "Julia", "Adrian", "Luca", "Carla" }
local function pareja(npc: string): any
	return { Flags = { "TienePareja" }, Choices = { Cita = npc } }
end
local function amistad(npc: string): any
	return { Flags = { "AmistadEspecial" }, Choices = { Cita = npc } }
end

---------------------------------------------------------------------
-- La cita: una variante por persona (la invitación)
---------------------------------------------------------------------
local INVITACION_TEXTO = {
	Julia = {
		{ S = "Julia", T = "¿Un helado? ¿Conmigo?", Shot = "PrimerPlano:Julia", Beat = "Mirar", Pause = 0.4 },
		{ S = "Julia", T = "…Vale. Pero el sabor lo elijo yo. Y a Adrián ni una palabra, que me lo pregunta todo.", Shot = "DosPlanos:Julia,Yo" },
		{ S = "Julia", T = "Lo apunto en la agenda. Con boli. El boli no se borra.", Beat = "Reir" },
	},
	Adrian = {
		{ S = "Adrian", T = "¿Un helado? ¿Tú y yo?", Shot = "PrimerPlano:Adrian", Beat = "Pensar", Pause = 0.4 },
		{ S = "Adrian", T = "Sí. O sea, sí. Claro. Tengo un hueco a las seis.", Shot = "DosPlanos:Adrian,Yo" },
		{ S = "Adrian", T = "Lo tenía libre, ¿eh? No es que lo acabe de quitar del calendario. Para nada.", Beat = "Apartar" },
	},
	Luca = {
		{ S = "Luca", T = "¿Gelato? ¿Conmigo? Mamma mia.", Shot = "PrimerPlano:Luca", Pause = 0.4 },
		{ S = "Luca", T = "En Bolonia, esto es casi un compromiso. Aquí… también un poquito.", Shot = "DosPlanos:Luca,Yo", Beat = "Pensar" },
		{ S = "Luca", T = "Sí. Sí, sí. Avanti.", Beat = "Celebrar" },
	},
	Carla = {
		{ S = "Carla", T = "¿Un helado? ¿Hoy? ¿A una hora concreta?", Shot = "PrimerPlano:Carla", Beat = "Mirar", Pause = 0.4 },
		{ S = "Carla", T = "¡Llego a tiempo! Te lo prometo. Me pongo tres alarmas. Y le pido a mi hermano que me grite.", Shot = "DosPlanos:Carla,Yo" },
		{ S = "Carla", T = "Por primera vez en mi vida, voy a llegar antes que alguien.", Beat = "Reir" },
	},
}

local function invitacion(npc: string): any
	local dialogue = {}
	for _, line in INVITACION_TEXTO[npc] do
		table.insert(dialogue, line)
	end
	-- Iván y Candela lo han visto todo desde el banco de enfrente
	table.insert(dialogue, { S = "Ivan", T = "¡HA DICHO QUE SÍ!", Shot = "Medio:Ivan", Pause = 0.6 })
	table.insert(dialogue, { S = "Candela", T = "Iván. El gráfico decía «sin gritar».", Shot = "DosPlanos:Ivan,Candela", Beat = "Suelo" })
	return {
		Name = npc,
		If = { Choices = { Cita = npc } },
		Center = npc,
		Tracks = {
			Actors = {
				{ At = 0, Use = { Key = npc, Npc = npc, Anchor = "Yo", Offset = V(0, 0, -4) } },
				{ At = 0.05, Mood = { Key = npc, Mood = "Nervous" } },
				{ At = 0.2, Look = { Key = npc, At = "Yo" } },
				-- Los «espías»: llegan andando al banco de enfrente y se esconden fatal
				{ At = 0, Enter = { Key = "Ivan", Npc = "Ivan", From = { "Yo", V(-16, 0, 14), true }, To = { "Yo", V(-9, 0, 6), true }, Walk = true } },
				{ At = 0.4, Enter = { Key = "Candela", Npc = "Candela", From = { "Yo", V(-18, 0, 15), true }, To = { "Yo", V(-10.5, 0, 6.5), true }, Walk = true } },
				{ At = 4, Mood = { Key = npc, Mood = "Joy" } },
				{ At = 9, Gesture = { Key = "Ivan", Play = "Cheer" } },
				{ At = 9.4, Look = { Key = "Candela", At = "Ivan" } },
			},
			Dialogue = dialogue,
		},
	}
end

return {
	---------------------------------------------------------------------
	-- Uni01_PrimerDia · paso 5 · LLEGADA AL CAMPUS
	-- ¿Qué pasa? Llegas por primera vez a un campus enorme; Luca, voluntario de Erasmus, te ve perdido
	--   y te da la bienvenida; Sara aparece corriendo desde Ciencias.
	-- ¿Por qué? Es el primer minuto de la universidad: nadie te conoce y todo es más grande que tú.
	-- ¿Qué siente el personaje? Tú: vértigo y emoción. Luca: ganas de que nadie se sienta solo el primer
	--   día (a él le pasó). Sara: alegría desbordada de tener a alguien de siempre cerca.
	-- ¿Qué ve el jugador? El edificio desde abajo (mira hacia arriba, como todos los de primero), a Luca
	--   saludando, a Sara cruzando la explanada a la carrera.
	-- ¿Qué quiero que sienta? Que empieza un mundo nuevo… y que no está solo en él.
	---------------------------------------------------------------------
	Uni01_Campus = {
		Skippable = true,
		Center = "Luca",
		Anchors = {
			Yo = "Player",
			Uni = "Place:Universidad",
			-- Sara termina en la misma marca que le da la misión en el paso siguiente
			SaraMarca = { Place = "Universidad", Offset = V(-6, 0, 8), Ground = true },
			SaraViene = { Place = "Universidad", Offset = V(-20, 0, 26), Ground = true },
		},
		Tracks = {
			Ambience = { { At = 0, Kind = "Universidad", Fade = 1.5 } },
			Music = { { At = 0, Intensity = "Descubrimiento" } },
			Camera = {
				-- Desde tu hombro hacia arriba: el edificio entero, como lo ves el primer día
				{ At = 0, Duration = 4.2, From = { "Yo", V(1.5, 2.2, 4) }, To = { "Yo", V(1, 1.8, 2.6) }, Look = { "Yo", V(0, 2, 0) }, LookTo = { "Uni", V(0, 22, 0) }, Fov = { 62, 72 } },
				-- Sara cruzando la explanada (antes de su primera frase)
				{ At = 32.2, Duration = 2.7, Shot = "Seguir:Sara", Cut = "Cut" },
			},
			Actors = {
				{ At = 0, Use = { Key = "Luca", Npc = "Luca" } },
				{ At = 0.3, Look = { Key = "Luca", At = "Yo" } },
				{ At = 0.05, Mood = { Key = "Luca", Mood = "Joy" } },
				-- Sara cruza la explanada corriendo y llega a su sitio
				{ At = 32, Enter = { Key = "Sara", Npc = "Sara", From = "SaraViene", To = "SaraMarca", Walk = true, Run = true } },
				{ At = 32.1, Mood = { Key = "Sara", Mood = "Joy" } },
				{ At = 32.4, Look = { Key = "Luca", At = "Sara" } },
				{ At = 36, Look = { Key = "Luca", At = "Speaker" } },
			},
			Dialogue = {
				{ S = "Narrador", T = "El campus es una ciudad dentro de la ciudad: facultades, jardines, bicis y gente hablando en cuatro idiomas.", At = 0.6 },
				{ S = "Luca", T = "Ciao! ¿Primer año? Se te nota: los de primero siempre miráis hacia arriba.", Shot = "Medio:Luca", Beat = "Saludar" },
				{ S = "Luca", T = "Soy Luca. Voluntario de bienvenida. De Bolonia. Un año aquí y ya casi no me pierdo.", Shot = "Hombro:Yo>Luca" },
				{ S = "Yo", T = "¿Tanto se nota?", Shot = "Reaccion:Yo" },
				{ S = "Luca", T = "Un poquito. Primer paso: secretaría. Allí te matriculas en tu carrera, con la nota de selectividad.", Shot = "DosPlanos:Luca,Yo", Beat = "Senalar" },
				{ S = "Luca", T = "Sin matrícula no existes. Es como la pasta sin sal: técnicamente es comida, pero da pena.", Shot = "PrimerPlano:Luca" },
				-- Sara (la escena la hace entrar corriendo un poco antes)
				{ S = "Sara", T = "¡{nombre}! ¡{nombre}! ¡Te he visto desde la facultad de Ciencias!", Shot = "Medio:Sara" },
				{ S = "Sara", T = "¡Mismo campus! Estadísticamente, nos vamos a cruzar unas cuatrocientas veces por curso.", Shot = "DosPlanos:Sara,Yo" },
				{ S = "Sara", T = "Y aquí tengo un laboratorio entero. La mochila de tercero la habría encontrado en diez minutos.", If = memory("MochilaPerdida"), Shot = "PrimerPlano:Sara" },
				{ S = "Luca", T = "¿Venís del mismo cole? Has venido en metro, ¿eh? Tienes cara de metro de las ocho.", If = memory("MetroPrimerDia"), Shot = "Medio:Luca" },
				{ S = "Luca", T = "Amigos de antes. Perfetto: ya no me necesitas. La secretaría, sí. Avanti!", Shot = "DosPlanos:Luca,Sara", Beat = "Senalar" },
			},
		},
	},

	---------------------------------------------------------------------
	-- Uni01_PrimerDia · paso 9 · LA PROFESORA BELTRÁN (primera clase)
	-- ¿Qué pasa? Primera clase en tu facultad: Beltrán se presenta, Julia te ofrece un bolígrafo, Adrián
	--   ya quiere coordinar… y Carla entra corriendo diez minutos tarde.
	-- ¿Por qué? Es la presentación del grupo con el que vas a pasar cuatro años (y del proyecto de Uni02).
	-- ¿Qué siente cada uno? Beltrán: calma de treinta años de oficio, humor seco. Julia: nervios
	--   organizados. Adrián: prisa por destacar. Carla: vergüenza (luego sabremos por qué llega tarde).
	-- ¿Qué ve el jugador? Plano general del aula, la cara de Beltrán, a Julia susurrando a su lado, la
	--   puerta: Carla cruzando la clase sin aliento mientras todos la miran.
	-- ¿Qué quiero que sienta? Que conoce a gente nueva de verdad, cada una con su manía; una sonrisa.
	---------------------------------------------------------------------
	Uni01_Beltran = {
		Skippable = true,
		Center = "Beltran",
		Anchors = { Yo = "Player" },
		Tracks = {
			Ambience = { { At = 0, Kind = "Universidad", Fade = 1 } },
			Camera = {
				{ At = 0, Duration = 3.2, Shot = "General:Beltran" },
				-- La puerta se abre: Beltrán se calla y mira
				{ At = 31.2, Duration = 2.5, Shot = "Reaccion:Beltran", Cut = "Cut" },
			},
			Actors = {
				{ At = 0, Use = { Key = "Beltran", Npc = "Beltran" } },
				{ At = 0, Use = { Key = "Julia", Npc = "Julia" } },
				{ At = 0, Use = { Key = "Adrian", Npc = "Adrian" } },
				{ At = 0, Use = { Key = "Mateo", Npc = "Mateo" }, If = MATEO_INGENIERIA },
				{ At = 0.05, Mood = { Key = "Julia", Mood = "Nervous" } },
				-- Carla: la puerta, la carrera por el pasillo de la clase, la última fila
				{ At = 31, Enter = { Key = "Carla", Npc = "Carla", From = { "Yo", V(2, 0, 16), true }, To = { "Yo", V(-5, 0, 3), true }, Walk = true, Run = true } },
				{ At = 31.1, Mood = { Key = "Carla", Mood = "Shame" } },
				{ At = 31.3, Look = { Key = "Beltran", At = "Carla" } },
				{ At = 31.5, Look = { Key = "Julia", At = "Carla" } },
				{ At = 31.5, Look = { Key = "Adrian", At = "Carla" } },
				{ At = 43.5, Look = { Key = "Carla", At = "Suelo" } },
				{ At = 46, Look = { Key = "Julia", At = "Speaker" } },
				{ At = 46, Look = { Key = "Adrian", At = "Speaker" } },
				{ At = 46, Look = { Key = "Beltran", At = "Speaker" } },
			},
			Dialogue = {
				{ S = "Beltran", T = "Buenos días. Soy la profesora Beltrán. Llevo treinta años aquí.", At = 1.2, Shot = "Medio:Beltran" },
				{ S = "Beltran", T = "He visto entrar a muchos. Y salir a casi todos.", Beat = "Pensar", Shot = "PrimerPlano:Beltran" },
				{ S = "Beltran", T = "Aquí nadie os va a perseguir para que estudiéis. La libertad es vuestra. La responsabilidad, también.", Shot = "Pan:Beltran" },
				{ S = "Julia", T = "He traído tres bolígrafos por si se me acaba la tinta. Y un cuarto por si acaso. ¿Quieres uno?", To = "Yo", Shot = "DosPlanos:Julia,Yo" },
				{ S = "Adrian", T = "Profesora, ¿habrá trabajos en grupo? Porque yo suelo coordinar.", Shot = "Medio:Adrian", Beat = "Mirar" },
				{ S = "Beltran", T = "Habrá. Y coordinará quien el grupo decida. No quien lo pida primero.", To = "Adrian", Shot = "Hombro:Adrian>Beltran" },
				-- La puerta (la escena hace entrar a Carla justo antes)
				{ S = "Carla", T = "¡Perdón! Perdón. Perdón…", Shot = "Seguir:Carla", Duration = 2.6 },
				{ S = "Beltran", T = "Buenos días también a usted. Última fila, que es la que tiene más perspectiva.", To = "Carla", Shot = "Reaccion:Beltran", Pause = 0.5 },
				{ S = "Carla", T = "…Sí. Gracias. Perdón.", Beat = "Suelo", Shot = "PrimerPlano:Carla" },
				{ S = "Julia", T = "Primer día y ya tarde. Yo me moriría.", To = "Yo", Shot = "Reaccion:Julia" },
				{ S = "Mateo", T = "¡{nombre}! ¡Lo sabía! Te dije que quería entender cómo funcionan las cosas. Pues aquí estamos. Otra vez juntos.", If = MATEO_INGENIERIA, Shot = "Medio:Mateo", Beat = "Saludar" },
				{ S = "Beltran", T = "Página uno. Empezamos.", Shot = "General:Beltran", Pause = 0.4 },
			},
		},
	},

	---------------------------------------------------------------------
	-- Uni01_PrimerDia · último paso · LA PRIMERA NOCHE (mensajes)
	-- ¿Qué pasa? Primera noche en la habitación de la residencia, con dos camas vacías. El móvil vibra:
	--   el grupo de siempre, cada uno en su vida nueva, y tu familia.
	-- ¿Por qué? Es la primera noche fuera de casa; los de siempre siguen ahí, a distancia.
	-- ¿Qué siente el personaje? Un poco de soledad que se va llenando con cada mensaje.
	-- ¿Qué ve el jugador? La habitación a oscuras, la luz del móvil en tu cara, los mensajes uno a uno;
	--   el reloj viejo antes de dormir.
	-- ¿Qué quiero que sienta? Morriña dulce: has crecido, y los tuyos te siguen.
	-- (Los que escriben no están en la habitación: es el móvil. Por eso no hay actores.)
	---------------------------------------------------------------------
	Uni01_Mensajes = {
		Skippable = true,
		Anchors = { Yo = "Player" },
		Tracks = {
			Ambience = { { At = 0, Kind = "Interior", Fade = 1.5 } },
			Light = { { At = 0, Preset = "Noche", Fade = 1.5 } },
			Music = { { At = 0, Intensity = "Intima" } },
			Camera = {
				{ At = 0, Duration = 4, Shot = "General:Yo" },
				{ At = 4, Duration = 9, Shot = "PrimerPlano:Yo", Cut = "Dip" },
				{ At = 13, Duration = 9, Shot = "Lateral:Yo" },
				{ At = 22, Duration = 12, Shot = "PPP:Yo" },
				{ At = 34, Duration = 9, Shot = "Dolly:Yo", Reverse = true },
			},
			Dialogue = {
				{ S = "Narrador", T = "Tu móvil vibra. El grupo de siempre sigue vivo.", At = 1 },
				{ S = "Omar", T = "📱 ¿QUÉ TAL EL PRIMER DÍA? Yo he pelado cuarenta kilos de patatas. Lola dice que tengo futuro." },
				{ S = "Nico", T = "📱 Entreno con el juvenil de Altamar. Me llaman «el nuevo». Tengo diecinueve años de «nuevo» por delante." },
				{ S = "Leire", T = "📱 Primer día en la escuela de cine. Aquí todos hablan en planos. Me siento en casa. Os echo de menos.", If = CON_LEIRE },
				{ S = "Hugo", T = "📱 Periodismo tiene una redacción de verdad. Ya he escrito mi primer artículo. Era sobre piratas.", If = flag("HugoConElGrupo") },
				{ S = "Luca", T = "📱 Mañana, comedor a las dos menos cinco. Croquetas. No me falles.", If = choice("ComidaUni", "Luca") },
				{ S = "Sara", T = "📱 Me han dado taquilla en el laboratorio. Tiene ESTANTES. Es lo mejor que me ha pasado desde el microscopio.", If = choice("ComidaUni", "Sara") },
				{ S = "Julia", T = "📱 Hola, soy Julia, la de los bolígrafos. Adrián ha hecho un grupo de clase. Tiene normas. Ya.", If = choice("ComidaUni", "Clase") },
				{ S = "Familia", T = "📱 ¿Qué tal ha ido? ¿Has comido? ¿Has hecho amigos? ¿Te has comido el táper del lunes?", Pause = 0.6 },
				{ S = "Familia", T = "📱 Cuéntamelo todo. Bueno, lo que quieras. Bueno, todo." },
				{ S = "Yo", T = "📱 He comido a mi aire. Y ha estado bien. Mañana os cuento.", If = choice("ComidaUni", "Sola"), Beat = "Respirar" },
				{ S = "Narrador", T = "Dos camas más, todavía vacías: una maleta con pegatinas de grupos de música y una caja con etiquetas de colores.", Pause = 0.8 },
				{ S = "Narrador", T = "Antes de dormir, das cuerda al reloj viejo. Tic-tac. Empieza algo nuevo.", Pause = 0.6 },
			},
		},
	},

	---------------------------------------------------------------------
	-- Uni02_ElProyecto · paso 6 · LA PRIMERA REUNIÓN (la pelea del grupo)
	-- ¿Qué pasa? La primera reunión del grupo cuatro en la biblioteca es un desastre: Adrián lo quiere
	--   todo a su manera, Julia se ofrece a hacerlo todo, Carla llega tarde y Pablo no viene.
	-- ¿Por qué? Beltrán hizo los grupos; cada uno esconde un problema (beca, miedo a fallar, su hermano,
	--   la música) que el jugador descubrirá después.
	-- ¿Qué siente cada uno? Adrián: ansiedad que suena a mando. Julia: agotamiento disfrazado de ganas.
	--   Carla: vergüenza. Tú: frustración.
	-- ¿Qué ve el jugador? El calendario plastificado, la silla vacía de Pablo, a Carla entrando sin aliento,
	--   el «voy luego 👍» en el móvil.
	-- ¿Qué quiero que sienta? Tensión… y ganas de arreglarlo (justo antes de decidir qué hace).
	-- Variante: si llegaste tarde (LlegasTardeReunion), Adrián también te lo apunta a ti.
	---------------------------------------------------------------------
	Uni02_Reunion = {
		Skippable = true,
		Center = "Adrian",
		Anchors = {
			Yo = "Player",
			-- Carla acaba en la misma marca que le da la misión en el paso siguiente
			CarlaMarca = { Place = "Biblioteca", Offset = V(0, 0, 5), Ground = true },
			CarlaViene = { Place = "Biblioteca", Offset = V(2, 0, 16), Ground = true },
		},
		Tracks = {
			Ambience = { { At = 0, Kind = "Interior", Fade = 1 } },
			Music = {
				{ At = 0, Intensity = "Nada" },
				{ At = 19, Intensity = "Tension" },
			},
			Camera = {
				{ At = 0, Duration = 3, Shot = "General:Adrian" },
				{ At = 29, Duration = 2.8, Shot = "Seguir:Carla", Cut = "Cut" },
			},
			Actors = {
				{ At = 0, Use = { Key = "Adrian", Npc = "Adrian" } },
				{ At = 0, Use = { Key = "Julia", Npc = "Julia" } },
				{ At = 0.05, Mood = { Key = "Adrian", Mood = "Nervous" } },
				{ At = 0.05, Mood = { Key = "Julia", Mood = "Nervous" } },
				{ At = 19, Mood = { Key = "Adrian", Mood = "Angry" } },
				-- Carla, veinte minutos tarde
				{ At = 28.8, Enter = { Key = "Carla", Npc = "Carla", From = "CarlaViene", To = "CarlaMarca", Walk = true, Run = true } },
				{ At = 28.9, Mood = { Key = "Carla", Mood = "Shame" } },
				{ At = 29.2, Look = { Key = "Adrian", At = "Carla" } },
				{ At = 29.2, Look = { Key = "Julia", At = "Carla" } },
				{ At = 33.5, Look = { Key = "Adrian", At = "Speaker" } },
				{ At = 33.5, Look = { Key = "Julia", At = "Speaker" } },
				{ At = 36, Mood = { Key = "Adrian", Mood = "Nervous" } },
			},
			Dialogue = {
				{ S = "Adrian", T = "Bien. Calendario plastificado. Cada color, una tarea. Cada tarea, un día.", At = 1.2, Shot = "Medio:Adrian" },
				{ S = "Julia", T = "Yo he traído tres carpetas: introducción, desarrollo y conclusiones. Por si acaso.", Shot = "Medio:Julia" },
				{ S = "Yo", T = "¿Y Pablo?", Shot = "Reaccion:Julia" },
				{ S = "Adrian", T = "Pablo es una leyenda. Como el aparcamiento libre.", Shot = "DosPlanos:Adrian,Julia", Beat = "Apartar" },
				{ S = "Adrian", T = "Esto se hace a mi manera o no se hace. No puedo sacar menos de un siete. No puedo.", Shot = "PrimerPlano:Adrian", Pause = 0.4 },
				{ S = "Julia", T = "No os preocupéis. Si no llegáis, lo hago yo. Esta noche. Y mañana. Duermo poco, no pasa nada.", Shot = "PrimerPlano:Julia", Beat = "Suelo" },
				-- Carla (la escena la hace entrar corriendo justo antes)
				{ S = "Carla", T = "¡Perdón, perdón! No he podido antes. De verdad.", Shot = "Medio:Carla" },
				{ S = "Carla", T = "…¿Qué me he perdido?", Beat = "Respirar", Shot = "Reaccion:Carla" },
				{ S = "Adrian", T = "Todo.", Shot = "DosPlanos:Adrian,Julia" },
				{ S = "Julia", T = "Nada.", Alt = true },
				{ S = "Adrian", T = "Y tú tampoco has llegado puntual, {nombre}. Diez minutos. Lo he apuntado.", If = flag("LlegasTardeReunion"), To = "Yo", Shot = "Hombro:Yo>Adrian" },
				{ S = "Carla", T = "¿Ves? No soy la única.", If = flag("LlegasTardeReunion"), Shot = "PrimerPlano:Carla", Beat = "Reir" },
				{ S = "Narrador", T = "Tu móvil vibra. Es Pablo: «voy luego 👍».", Shot = "PrimerPlano:Yo", Pause = 0.6 },
				{ S = "Adrian", T = "«Voy luego». Con pulgar. Eso es un no con pulgar.", Shot = "Medio:Adrian", Beat = "Pensar" },
				{ S = "Julia", T = "…Vale. Lo hago yo.", Shot = "PrimerPlano:Julia", Pause = 0.8 },
				{ S = "Narrador", T = "Nadie dice nada. Carla mira el suelo. Adrián, su calendario. Y todos te miran a ti.", Shot = "General:Adrian", Pause = 0.5 },
			},
		},
	},

	---------------------------------------------------------------------
	-- Uni05_PrimerPiso · paso 9 · LA VISITA DE {ABU} (la caja, la planta y el reloj)
	-- ¿Qué pasa? Llaman a la puerta de tu primer piso: es {abu}, con una planta, una fiambrera de
	--   croquetas y la pregunta de siempre: «¿llevas el reloj?». Ve la caja de recuerdos abierta.
	-- ¿Por qué? Es la primera visita a TU casa; para {abu}, ver que te las arreglas cierra un círculo
	--   (el reloj que te dio el primer día de universidad).
	-- ¿Qué siente cada uno? {abu}: orgullo tranquilo, un poco de nostalgia. Tú: ternura, ganas de
	--   enseñarle que lo estás haciendo bien.
	-- ¿Qué ve el jugador? A {abu} entrando despacio, mirando la casa, la planta, tu muñeca (el reloj).
	-- ¿Qué quiero que sienta? Que lo de antes sigue contigo en lo nuevo.
	-- Variantes: con o sin el reloj (objeto RelojAbu), con quién vives, si sabes cocinar, si llamaste a casa.
	---------------------------------------------------------------------
	Uni05_Visita = {
		Skippable = true,
		Center = "Abu",
		Anchors = { Yo = "Player" },
		Tracks = {
			Ambience = { { At = 0, Kind = "Casa", Fade = 1 } },
			Light = { { At = 0, Preset = "InteriorCalido", Fade = 1.5 } },
			Music = { { At = 3, Intensity = "Intima" } },
			Camera = {
				{ At = 0, Duration = 4.2, Shot = "Seguir:Abu" },
			},
			Actors = {
				-- {abu} entra por la puerta y se acerca despacio
				{ At = 0, Enter = { Key = "Abu", Npc = "Abu", From = { "Yo", V(0, 0, -14), true }, To = { "Yo", V(0, 0, -4), true }, Walk = true } },
				{ At = 0.05, Mood = { Key = "Abu", Mood = "Joy" } },
				{ At = 4.2, Gesture = { Key = "Abu", Play = "Wave" } },
				-- Quien vive contigo sale a saludar
				{ At = 0, Use = { Key = "Sara", Npc = "Sara" }, If = choice("CompiPiso", "Sara") },
				{ At = 0, Use = { Key = "Luca", Npc = "Luca" }, If = choice("CompiPiso", "Luca") },
				{ At = 0, Use = { Key = "Ivan", Npc = "Ivan" }, If = choice("CompiPiso", "Resi") },
				{ At = 0, Use = { Key = "Candela", Npc = "Candela" }, If = choice("CompiPiso", "Resi") },
			},
			Dialogue = {
				{ S = "Abu", T = "¿Se puede? Traigo una planta. Toda casa necesita algo vivo.", At = 4.6, Shot = "DosPlanos:Abu,Yo" },
				{ S = "Abu", T = "Riégala los lunes. Si no, te la regaño yo.", Beat = "Senalar", Shot = "Medio:Abu" },
				{ S = "Yo", T = "Los lunes. Prometido.", Shot = "Reaccion:Yo" },
				{ S = "Sara", T = "¡Encantada! He incluido la planta en el cuadrante de riego. Tiene color propio: verde planta.", If = choice("CompiPiso", "Sara"), Shot = "Medio:Sara" },
				{ S = "Luca", T = "Buonasera! ¿Se queda a cenar? He hecho pasta para ocho. Somos dos. Bueno, ahora tres.", If = choice("CompiPiso", "Luca"), Shot = "Medio:Luca" },
				{ S = "Candela", T = "Hola. Le he hecho sitio a la planta. Está etiquetada. Iván, no la riegues con zumo.", If = choice("CompiPiso", "Resi"), Shot = "DosPlanos:Candela,Ivan" },
				{ S = "Abu", T = "Mmm. Esto está muy recogido. Demasiado. ¿Quién ha fregado?", If = choice("Convivencia", "Hacerlo"), Shot = "PrimerPlano:Abu", Beat = "Pensar" },
				{ S = "Abu", T = "Tu familia dice que ayer llamaste. Hicieron como que no lloraban. Lloraron.", If = choice("Convivencia", "Llamar"), Shot = "PrimerPlano:Abu", Pause = 0.4 },
				-- La caja de recuerdos, abierta en el suelo
				{ S = "Abu", T = "Has abierto la caja. …La carta la escribimos entre todos. La letra bonita es mía.", Shot = "PrimerPlano:Abu", Pause = 0.8, Beat = "Suelo" },
				{ S = "Abu", T = "Tu primera mochila. Te llegaba por las rodillas. Y no la soltabas ni para dormir.", Beat = "Respirar", Shot = "Reaccion:Yo" },
				-- El reloj
				{ S = "Abu", T = "¿Llevas el reloj?", Pause = 0.8, Shot = "PPP:Abu" },
				{ S = "Yo", T = "Siempre.", If = { Items = { RelojAbu = 1 } }, Shot = "Reaccion:Yo" },
				{ S = "Abu", T = "Lo llevas. Ahora tienes tu casa y tu tiempo. Úsalos bien.", If = { Items = { RelojAbu = 1 } }, Shot = "DosPlanos:Abu,Yo", Beat = "Mirar" },
				{ S = "Yo", T = "Yo… No lo llevo.", IfNot = { Items = { RelojAbu = 1 } }, Shot = "Reaccion:Yo", Beat = "Suelo" },
				{ S = "Abu", T = "Bueno. Los relojes se pierden. Lo que te enseñé, no. Eso no se pierde.", IfNot = { Items = { RelojAbu = 1 } }, Shot = "DosPlanos:Abu,Yo", Pause = 0.8 },
				{ S = "Abu", T = "Y esto son croquetas. No son de Lola: son mías. Mejores. No se lo digas.", Shot = "Medio:Abu", Pause = 0.5 },
				{ S = "Abu", T = "Aunque me han dicho que haces una tortilla que hace llorar a la gente. Algún domingo me la enseñas.", If = flag("SabeCocinar"), Shot = "PrimerPlano:Abu", Beat = "Reir" },
			},
		},
	},

	---------------------------------------------------------------------
	-- UniS_Cita · paso 3 · LA INVITACIÓN (con la persona en escena: arregla C-09)
	-- ¿Qué pasa? Te acercas a la persona que elegiste y la invitas a un helado. Dice que sí, a su manera.
	--   Iván y Candela lo espían desde el banco de enfrente (y lo estropean un poco).
	-- ¿Por qué? Iván y Candela llevan semanas notándolo; hoy te atreves.
	-- ¿Qué siente cada uno? Tú: nervios. Quien invitas: sorpresa y alegría que intenta disimular. Iván:
	--   entusiasmo incontenible. Candela: vergüenza ajena con datos.
	-- ¿Qué ve el jugador? Un primer plano de su cara al oír la pregunta, el sí, y a los dos espías.
	-- ¿Qué quiero que sienta? Mariposas y una carcajada.
	-- Una variante por persona (decisión Cita); sin decisión (no debería pasar) solo hablan los espías.
	---------------------------------------------------------------------
	UniS_Cita_Invitacion = {
		Skippable = true,
		Center = "Yo",
		Anchors = { Yo = "Player" },
		Tracks = {
			Ambience = { { At = 0, Kind = "Universidad", Fade = 1 } },
			Music = { { At = 0, Intensity = "Intima" } },
			Camera = {
				{ At = 0, Duration = 3, Shot = "General:Yo" },
			},
			Actors = {
				{ At = 0, Enter = { Key = "Ivan", Npc = "Ivan", From = { "Yo", V(-16, 0, 14), true }, To = { "Yo", V(-9, 0, 6), true }, Walk = true } },
				{ At = 0.4, Enter = { Key = "Candela", Npc = "Candela", From = { "Yo", V(-18, 0, 15), true }, To = { "Yo", V(-10.5, 0, 6.5), true }, Walk = true } },
			},
			Dialogue = {
				{ S = "Ivan", T = "¿Y? ¿Ya? ¿Se lo has dicho?", At = 3.2, Shot = "Medio:Ivan" },
				{ S = "Candela", T = "Iván. Discreción. Lo pone en el gráfico.", Shot = "DosPlanos:Ivan,Candela" },
			},
		},
		Variants = {
			invitacion("Julia"),
			invitacion("Adrian"),
			invitacion("Luca"),
			invitacion("Carla"),
		},
	},

	---------------------------------------------------------------------
	-- Uni06_Graduacion · paso 9 · LA CEREMONIA (final de capítulo, 1/3)
	-- ¿Qué pasa? Beltrán da el discurso, dice tu nombre, subes a por el diploma (andas tú) y tu familia
	--   grita desde la grada.
	-- ¿Por qué? Cuatro años: el grupo cuatro, las prácticas, el TFG. Beltrán habla de lo que VIVISTE.
	-- ¿Qué siente cada uno? Beltrán: orgullo que no confiesa. Tú: piernas temblando. Tu familia: no cabe
	--   en sí. {abu}: calma y ojos húmedos. El grupo: complicidad.
	-- ¿Qué ve el jugador? La sala llena, la cara de Beltrán, tus ojos al oír tu nombre, el camino hasta
	--   el estrado, el diploma, la grada.
	-- ¿Qué quiero que sienta? Orgullo y el peso de los años… y una carcajada con la familia.
	-- Continuidad: el error confesado (ErrorInforme), el equipo (EquipoUnido / HacesTodo), la oferta
	-- (OfertaTrabajo), el TFG (TemaTFG / TFGRaro), lo que llevas bajo la toga (LookGraduacion).
	---------------------------------------------------------------------
	Uni06_Ceremonia = {
		Skippable = true,
		Center = "Beltran",
		Anchors = { Yo = "Player" },
		Tracks = {
			Ambience = { { At = 0, Kind = "Universidad", Fade = 1.5 } },
			Music = {
				{ At = 0, Intensity = "Nada" },
				{ At = 32.3, Intensity = "Resolucion" },
			},
			Camera = {
				{ At = 0, Duration = 4.5, Shot = "General:Beltran" },
				-- Mientras subes: detrás de ti
				{ At = 37.8, Duration = 3, Shot = "Seguir:Yo" },
			},
			Actors = {
				{ At = 0, Use = { Key = "Beltran", Npc = "Beltran" } },
				{ At = 0, Use = { Key = "Familia", Npc = "Familia" } },
				{ At = 0, Use = { Key = "Abu", Npc = "Abu" } },
				{ At = 0, Use = { Key = "Julia", Npc = "Julia" } },
				{ At = 0, Use = { Key = "Adrian", Npc = "Adrian" } },
				{ At = 0, Use = { Key = "Carla", Npc = "Carla" } },
				{ At = 0, Use = { Key = "Pablo", Npc = "Pablo" } },
				{ At = 0, Use = { Key = "Luca", Npc = "Luca" } },
				{ At = 0, Use = { Key = "Mateo", Npc = "Mateo" }, If = MATEO_INGENIERIA },
				{ At = 0, Use = { Key = "Leire", Npc = "Leire" }, If = CON_LEIRE },
				{ At = 0.05, Mood = { Key = "Familia", Mood = "Joy" } },
				{ At = 32.5, Mood = { Key = "Familia", Mood = "Surprise" } },
				-- Al recoger el diploma: la grada y el grupo
				{ At = 39, Gesture = { Key = "Familia", Play = "Cheer" } },
				{ At = 39.3, Gesture = { Key = "Pablo", Play = "Cheer" } },
				{ At = 39.5, Gesture = { Key = "Julia", Play = "Cheer" } },
				{ At = 39.8, Gesture = { Key = "Luca", Play = "Cheer" } },
			},
			Wait = {
				-- Subes tú: la cámara te sigue y el control es tuyo unos segundos
				{ At = 37.8, Near = { "Actor:Beltran", 6 }, Control = "Player", Hint = "Sube a recoger tu diploma", Timeout = 10 },
			},
			Titles = {
				{ At = 38.4, Text = "🎓 Tu diploma", Sub = "Cuatro años en una hoja de papel. Pesa más de lo que parece.", Duration = 3.5 },
			},
			Dialogue = {
				{ S = "Beltran", T = "Autoridades, familias, graduados. Me han pedido que sea breve.", At = 1.4, Shot = "Medio:Beltran" },
				{ S = "Beltran", T = "Seré breve. Es mentira. Pero lo intentaré.", Shot = "Reaccion:Familia", Beat = "Pensar" },
				{ S = "Beltran", T = "Hoy no os lleváis solo un título. Os lleváis los errores que tuvisteis el valor de confesar…", If = choice("ErrorInforme", "Decir"), Shot = "PrimerPlano:Beltran", Pause = 0.4 },
				{ S = "Beltran", T = "Hoy no os lleváis solo un título. Os lleváis los errores, los que se ven y los que no…", IfNot = choice("ErrorInforme", "Decir"), Shot = "PrimerPlano:Beltran", Pause = 0.4 },
				{ S = "Beltran", T = "…los grupos que sobrevivisteis. Alguno, hasta se convirtió en un equipo.", If = flag("EquipoUnido"), Shot = "Pan:Julia>Pablo" },
				{ S = "Beltran", T = "…los grupos que sobrevivisteis. Aunque en alguno trabajara una persona por cinco.", If = { Flags = { "HacesTodo" }, NotFlags = { "EquipoUnido" } }, Shot = "Reaccion:Yo" },
				{ S = "Beltran", T = "…los grupos que sobrevivisteis, como buenamente pudisteis.", If = { NotFlags = { "EquipoUnido", "HacesTodo" } }, Shot = "Pan:Julia>Pablo" },
				{ S = "Beltran", T = "Y lo que aprendisteis de gente muy distinta a vosotros. Eso no sale en el expediente.", Shot = "Medio:Beltran" },
				{ S = "Beltran", T = "Y ahora, los nombres.", Pause = 0.6, Shot = "General:Beltran" },
				{ S = "Beltran", T = "{nombre}.", At = 32.5, Pause = 0.2, Shot = "PPP:Yo", Duration = 2.2 },
				{ S = "Familia", T = "¡Esa es mi…! ¡Ese es…! ¡ES DE MI FAMILIA!", At = 35.1, Shot = "Medio:Familia", Duration = 2.4 },
				-- (Wait: subes al estrado)
				{ S = "Beltran", T = "Sabía que llegarías. No se lo digas a nadie: tengo una reputación.", At = 42.4, To = "Yo", Shot = "DosPlanos:Beltran,Yo" },
				{ S = "Beltran", T = "Y la empresa de tus prácticas ya me ha preguntado por ti. Tienes trabajo esperando.", If = flag("OfertaTrabajo"), To = "Yo", Shot = "PrimerPlano:Beltran" },
				{ S = "Beltran", T = "Por cierto: he recomendado tu TFG a la biblioteca. Sección de misterio. Lo de la gallina gigante sigue sin parecerme normal.", If = flag("TFGRaro"), To = "Yo", Shot = "PrimerPlano:Beltran" },
				{ S = "Beltran", T = "Tu TFG sobre Valmar ya está en la biblioteca municipal. Lo he comprobado. Dos veces.", If = choice("TemaTFG", "Valmar"), To = "Yo", Shot = "PrimerPlano:Beltran" },
				{ S = "Familia", T = "¡BRAVO, {nombre}! ¡BRAVOOO!", Shot = "Medio:Familia", Beat = "Celebrar" },
				{ S = "Abu", T = "Se le ve la sudadera de dinosaurios por debajo de la toga. Es lo más bonito que he visto en mi vida.", If = choice("LookGraduacion", "Dinosaurios"), Shot = "PrimerPlano:Abu" },
				{ S = "Abu", T = "Las cosas buenas tardan mucho. Y luego pasan rapidísimo.", IfNot = choice("LookGraduacion", "Dinosaurios"), Shot = "PrimerPlano:Abu", Beat = "Respirar" },
			},
		},
	},

	---------------------------------------------------------------------
	-- Uni06_Graduacion · paso 13 · EL BRINDIS (final de capítulo, 2/3)
	-- ¿Qué pasa? Lola cierra la Cafetería Central para vosotros; Omar propone un brindis en el que cada
	--   uno recuerda algo que VIVISTE, desde el primer día de colegio hasta ayer.
	-- ¿Por qué? Es la despedida de una etapa: la gente de tu vida junta en una sala.
	-- ¿Qué siente cada uno? Omar: emoción que esconde en chistes (y la «cebolla»). Cada uno: cariño a su
	--   manera (Sara precisa, Nico exagerado, Bruno torpe, Candela con datos, {abu} sin prisa).
	-- ¿Qué ve el jugador? Primeros planos de quien habla, tu cara escuchando, el vaso en alto.
	-- ¿Qué quiero que sienta? Que todo lo que ha jugado ha contado. Que le recuerdan.
	-- Continuidad: casi cada frase depende de lo que hiciste (ver las condiciones).
	---------------------------------------------------------------------
	Uni06_Brindis = {
		Skippable = true,
		Center = "Omar",
		Anchors = { Yo = "Player" },
		Tracks = {
			Ambience = { { At = 0, Kind = "Ocio", Fade = 1.5 } },
			Light = { { At = 0, Preset = "InteriorCalido", Fade = 2 } },
			Music = { { At = 6, Intensity = "Intima" } },
			Camera = {
				{ At = 0, Duration = 3.6, Shot = "General:Omar" },
			},
			Actors = {
				{ At = 0, Use = { Key = "Lola", Npc = "Lola" } },
				{ At = 0, Use = { Key = "Omar", Npc = "Omar" } },
				{ At = 0, Use = { Key = "Sara", Npc = "Sara" } },
				{ At = 0, Use = { Key = "Nico", Npc = "Nico" } },
				{ At = 0, Use = { Key = "Bruno", Npc = "Bruno" } },
				{ At = 0, Use = { Key = "Familia", Npc = "Familia" } },
				{ At = 0, Use = { Key = "Abu", Npc = "Abu" } },
				{ At = 0, Use = { Key = "Luca", Npc = "Luca" } },
				{ At = 0, Use = { Key = "Ivan", Npc = "Ivan" } },
				{ At = 0, Use = { Key = "Candela", Npc = "Candela" } },
				{ At = 0, Use = { Key = "Julia", Npc = "Julia" } },
				{ At = 0, Use = { Key = "Adrian", Npc = "Adrian" } },
				{ At = 0, Use = { Key = "Carla", Npc = "Carla" } },
				{ At = 0, Use = { Key = "Leire", Npc = "Leire" }, If = CON_LEIRE },
				{ At = 0, Use = { Key = "Mateo", Npc = "Mateo" }, If = CON_MATEO_FIESTA },
				{ At = 0.05, Mood = { Key = "Omar", Mood = "Joy" } },
			},
			Dialogue = {
				{ S = "Lola", T = "¡Cerrado por graduación! Hoy invita la casa. Bueno, invita Omar. La casa supervisa.", At = 1.2, Shot = "Medio:Lola" },
				{ S = "Omar", T = "Propongo un brindis. Cada uno dice algo que recuerde de {nombre}. Empiezo yo.", Shot = "Medio:Omar", Beat = "Senalar" },
				-- Cada uno, UN recuerdo: el más importante que tenga contigo (los demás quedan para otro día)
				-- La infancia y el instituto
				{ S = "Omar", T = "La foto aquella del instituto. Tú plantaste cara. Por eso llevo todavía la pulsera.", If = memory("ElRumor"), Shot = "PrimerPlano:Omar", Pause = 0.3 },
				{ S = "Omar", T = "El primer día de colegio. Tú no me conocías y ya me guardabas la mitad de todo. Bueno, eso era yo contigo.", If = { Memories = { "PrimerDiaCole" }, NotMemories = { "ElRumor" } }, Shot = "PrimerPlano:Omar", Pause = 0.3 },
				{ S = "Omar", T = "El festival. Las magdalenas. La purpurina de Vega, que sigo encontrando en mi ropa.", If = { Memories = { "ElFestival" }, NotMemories = { "ElRumor", "PrimerDiaCole" } }, Shot = "PrimerPlano:Omar", Pause = 0.3 },
				{ S = "Mateo", T = "Mis libros por el suelo del pasillo. Alguien se agachó a ayudarme. Todo empezó ahí.", If = { Memories = { "PrimerAmigo" }, Flags = { "AyudasteAMateo" } }, Shot = "PrimerPlano:Mateo" },
				{ S = "Sara", T = "La sala cerrada. La foto de Lucía con coletas. Todavía me escribe por Navidad.", If = memory("MisterioColegio"), IfNot = choice("CompiPiso", "Sara"), Shot = "PrimerPlano:Sara" },
				{ S = "Sara", T = "La mochila desaparecida. Nuestra primera investigación. Técnicamente, la primera de muchas.", If = { Memories = { "MochilaPerdida" }, NotMemories = { "MisterioColegio" } }, IfNot = choice("CompiPiso", "Sara"), Shot = "PrimerPlano:Sara" },
				{ S = "Sara", T = "El piso. El cuadrante de limpieza sigue colgado. Nadie lo cumple. Lo dejo por nostalgia.", If = choice("CompiPiso", "Sara"), Shot = "PrimerPlano:Sara", Beat = "Reir" },
				{ S = "Nico", T = "¡La final del torneo! Oro. Todavía tengo la medalla colgada. Bueno, la mía, no la tuya.", If = flag("TorneoGanado"), Shot = "Medio:Nico", Beat = "Celebrar" },
				{ S = "Nico", T = "La final del torneo. Plata. Y aun así, el mejor día de mi vida. No se lo digáis a mi entrenador.", If = { Flags = { "TorneoPerdido" }, NotFlags = { "TorneoGanado" } }, Shot = "Medio:Nico" },
				{ S = "Leire", T = "Un banco del instituto. Yo comía sola y apareció alguien. Nunca te lo agradecí bien. Gracias.", If = CON_LEIRE, Shot = "PrimerPlano:Leire", Beat = "Suelo" },
				{ S = "Bruno", T = "Yo… que empezamos de cero. Y salió bien. Ahora soy policía. ¿Quién lo iba a decir?", If = choice("AdiosBruno", "DeCero"), Shot = "Medio:Bruno", Beat = "Suelo" },
				{ S = "Bruno", T = "Que éramos rivales. Ya ni me acuerdo de por qué. Enhorabuena. De verdad.", IfNot = choice("AdiosBruno", "DeCero"), Shot = "Medio:Bruno" },
				{ S = "Lola", T = "Alguien tirando una bandeja entera en su primer turno. Mírate ahora.", If = memory("PrimerSueldo"), Shot = "PrimerPlano:Lola", Beat = "Reir" },
				{ S = "Familia", T = "Las prácticas: dijiste la verdad aunque te costara. Eso no lo enseña ninguna carrera.", If = choice("ErrorInforme", "Decir"), Shot = "Medio:Familia" },
				{ S = "Familia", T = "Aquel examen que casi suspendiste. Y cómo lo arreglaste sin que nadie te obligara.", If = memory("CasiSuspendo"), IfNot = choice("ErrorInforme", "Decir"), Shot = "Medio:Familia" },
				-- La universidad (si fue tu cita, eso gana)
				{ S = "Luca", T = "Tu primer día. Comimos juntos a las dos menos cinco. Quedaban croquetas.", If = choice("ComidaUni", "Luca"), IfNot = choice("Cita", "Luca"), Shot = "PrimerPlano:Luca" },
				{ S = "Ivan", T = "Una tortilla. Primera semana de residencia. He comido muchas desde entonces. Ninguna como esa.", If = flag("SabeCocinar"), Shot = "PrimerPlano:Ivan" },
				{ S = "Ivan", T = "La guerra del zumo de mora. Y quién la arregló. Mi abuela te manda una botella.", If = { Memories = { "ZumoDeMora" }, NotFlags = { "SabeCocinar" } }, Shot = "PrimerPlano:Ivan" },
				{ S = "Candela", T = "Un compañero de cuarto que no existía. Sigue sin estar en mi Excel. Por algo será.", If = flag("TitoDescubierto"), Shot = "PrimerPlano:Candela" },
				{ S = "Candela", T = "Tres años de horario de limpieza. Cumpliste el ochenta y siete por ciento. Es un récord.", IfNot = flag("TitoDescubierto"), Shot = "PrimerPlano:Candela" },
				{ S = "Adrian", T = "El grupo cuatro. Cinco desconocidos y, al final, un equipo. Mantuve la beca gracias a eso.", If = flag("EquipoUnido"), IfNot = choice("Cita", "Adrian"), Shot = "PrimerPlano:Adrian" },
				{ S = "Adrian", T = "La fiesta en mi casa. El rey de la pista. Mi vecino todavía pregunta por ti.", If = { Flags = { "ReyDeLaPista" }, NotFlags = { "EquipoUnido" } }, IfNot = choice("Cita", "Adrian"), Shot = "Medio:Adrian" },
				{ S = "Julia", T = "Que sacaste aquel proyecto casi sin ayuda. Ahora sé lo que es eso. No lo vuelvas a hacer, ¿vale?", If = flag("HacesTodo"), IfNot = choice("Cita", "Julia"), Shot = "PrimerPlano:Julia" },
				{ S = "Carla", T = "Que una vez llegaste más tarde que yo a una reunión. Una. Pero la tengo apuntada.", If = flag("LlegasTardeReunion"), IfNot = choice("Cita", "Carla"), Shot = "PrimerPlano:Carla", Beat = "Reir" },
				{ S = "Julia", T = "Dos helados derritiéndose en Playa Dorada. …Y lo que me dijiste.", If = pareja("Julia"), Shot = "PPP:Julia" },
				{ S = "Adrian", T = "Un atardecer en el que, por una vez, no quise mandar en nada.", If = pareja("Adrian"), Shot = "PPP:Adrian" },
				{ S = "Luca", T = "Un gelato en Playa Dorada. Mejor que la pasta de mi nonna. No se lo contéis a ella.", If = pareja("Luca"), Shot = "PPP:Luca" },
				{ S = "Carla", T = "La primera vez que llegué a tiempo a algo. Era un atardecer. Contigo.", If = pareja("Carla"), Shot = "PPP:Carla" },
				{ S = "Julia", T = "Una tarde de helado en la playa. De ahí salió una de las mejores amistades que tengo.", If = amistad("Julia"), Shot = "PrimerPlano:Julia" },
				{ S = "Adrian", T = "Una tarde de helado en la playa. Me dijiste algo bonito. Lo tengo apuntado. No en el calendario.", If = amistad("Adrian"), Shot = "PrimerPlano:Adrian" },
				{ S = "Luca", T = "El gelato en la playa. Amici per sempre. Eso no se traduce.", If = amistad("Luca"), Shot = "PrimerPlano:Luca" },
				{ S = "Carla", T = "El helado en la playa. Llegué a tiempo. Y me dijiste que era de lo mejor que tenías aquí. Igualmente.", If = amistad("Carla"), Shot = "PrimerPlano:Carla" },
				-- {abu} cierra
				{ S = "Abu", T = "Y yo me acuerdo del día que naciste. Eras así de pequeñito. Y mírate: con reloj, con casa y con una planta que sigue viva.", If = memory("PrimerPiso"), Pause = 0.8, Shot = "PrimerPlano:Abu", Beat = "Respirar" },
				{ S = "Abu", T = "Y yo me acuerdo del día que naciste. Eras así de pequeñito. Y mírate. Con reloj y todo.", IfNot = memory("PrimerPiso"), Pause = 0.8, Shot = "PrimerPlano:Abu", Beat = "Respirar" },
				{ S = "Omar", T = "¡Por {nombre}! ¡Y por todos los que vamos a seguir acordándonos!", Shot = "General:Omar", Beat = "Celebrar" },
				{ S = "Narrador", T = "Todos levantan el vaso. Omar llora. Dice que es por la cebolla de las croquetas. No hay cebolla.", Shot = "PrimerPlano:Omar" },
			},
		},
	},

	---------------------------------------------------------------------
	-- Uni06_Graduacion · último paso · EL FINAL DE LA ETAPA (final de capítulo, 3/3)
	-- ¿Qué pasa? La fiesta se vacía: los amigos se van (andando, sin prisa), Lola y Omar recogen. {abu}
	--   te sienta a su lado y te pregunta la hora. Luego, en casa, el diploma, el reloj y la foto.
	-- ¿Por qué? Se acaba la universidad; mañana empieza la vida profesional.
	-- ¿Qué siente cada uno? {abu}: paz. Tu familia: cansancio feliz. Tú: la sensación de que algo
	--   se cierra.
	-- ¿Qué ve el jugador? La cafetería a media luz, a {abu} sentado, tu muñeca; después tu casa de
	--   noche, con la luz encendida, y el rótulo del final de etapa.
	-- ¿Qué quiero que sienta? El final de un episodio de serie: emoción quieta y ganas de lo siguiente.
	-- (Antes era solo narrador: ahora la despedida se ve y el narrador cierra sobre la casa.)
	---------------------------------------------------------------------
	Uni06_Final = {
		Skippable = true,
		Center = "Abu",
		FadeOut = true,
		Anchors = {
			Yo = "Player",
			Casa = "Place:CasaFamiliar",
		},
		Tracks = {
			Ambience = {
				{ At = 0, Kind = "Ocio", Fade = 1.5 },
				{ At = 33, Kind = "Calle", Fade = 2 },
			},
			Light = {
				{ At = 0, Preset = "InteriorCalido", Fade = 1.5 },
				{ At = 33, Preset = "Noche", Fade = 0.5 },
			},
			Music = {
				{ At = 0, Intensity = "Intima" },
				{ At = 33, Intensity = "Tema" },
			},
			Camera = {
				-- La cafetería se vacía (los demás se van andando: el paso ya no los necesita)
				{ At = 0, Duration = 5, Shot = "General:Abu" },
				-- Tu casa, esa noche
				{ At = 33, Duration = 7, From = { "Casa", V(26, 10, 34) }, To = { "Casa", V(18, 7, 24) }, Look = { "Casa", V(0, 4, 0) }, Fov = { 55, 48 }, Cut = "Dip" },
				{ At = 40, Duration = 9, Orbit = "Casa", Radius = 30, Height = 12, FromAngle = 40, ToAngle = 75, LookHeight = 4 },
			},
			Actors = {
				{ At = 0, Use = { Key = "Abu", Npc = "Abu" } },
				{ At = 0, Use = { Key = "Familia", Npc = "Familia" } },
				{ At = 0, Use = { Key = "Lola", Npc = "Lola" } },
				{ At = 0, Use = { Key = "Omar", Npc = "Omar" } },
				{ At = 0.05, Mood = { Key = "Abu", Mood = "Calm" } },
			},
			Dialogue = {
				{ S = "Lola", T = "Venga, que cierro. Los graduados también friegan.", At = 1.5, Shot = "Medio:Lola" },
				{ S = "Omar", T = "Hoy no. Hoy friego yo. Vete, que me pongo sentimental con la fregona.", Shot = "DosPlanos:Omar,Lola", Beat = "Reir" },
				{ S = "Abu", T = "Ven. Siéntate un momento.", Pause = 0.6, Shot = "DosPlanos:Abu,Yo" },
				{ S = "Abu", T = "¿Qué hora es?", Shot = "PrimerPlano:Abu", Pause = 0.4 },
				{ S = "Yo", T = "Las once y diez.", If = { Items = { RelojAbu = 1 } }, Beat = "Suelo", Shot = "Reaccion:Yo" },
				{ S = "Abu", T = "Pues apúntala. Las once y diez del día que terminaste. Esas horas no vuelven. Pero se guardan.", If = { Items = { RelojAbu = 1 } }, Shot = "PrimerPlano:Abu" },
				{ S = "Yo", T = "No llevo reloj.", IfNot = { Items = { RelojAbu = 1 } }, Beat = "Suelo", Shot = "Reaccion:Yo" },
				{ S = "Abu", T = "Yo tampoco. Da igual: hoy es tarde y es pronto a la vez. Así se sabe que ha sido un buen día.", IfNot = { Items = { RelojAbu = 1 } }, Shot = "PrimerPlano:Abu" },
				{ S = "Familia", T = "Vámonos a casa. Mañana empieza todo lo demás.", Shot = "Medio:Familia", Pause = 0.5 },
				-- En casa (el plano cambia a tu casa a los 33 s)
				{ S = "Narrador", T = "Esa noche dejas el diploma encima de la mesa. Al lado, el reloj viejo. Y la foto de hoy.", At = 34 },
				{ S = "Narrador", T = "Te acuerdas de cómo empezó todo: una mochila más grande que tú, un pasillo lleno de gente, alguien que te sonrió.", Pause = 0.6 },
			},
			Titles = {
				{ At = 44.5, Text = "🎓 Fin de la etapa universitaria", Sub = "Empieza la vida profesional", Duration = 4.5 },
			},
		},
	},
}
