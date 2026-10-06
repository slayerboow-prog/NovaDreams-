-- Escenas del INSTITUTO (etapa adolescente): las CINEMATIC_SCENE escritas a mano de la §6.2 de
-- docs/historia/auditoria-narrativa-cinematica.md. Formato: shared/LifeStory/Sequencer.luau.
--
-- Las lanza su misión con un paso de cine ({ Type = "Cinematic", Id = "Ins06_Noche", Actors = … }): el
-- reparto del paso son los actores de la misión, y la escena los TOMA PRESTADOS (Use): miran, cambian
-- de emoción y hacen gestos, pero los mueve su misión (sus entradas y salidas andando van en el paso:
-- Enter = { From = … } y Exit). Quien solo sale en la escena entra y se va andando aquí (Enter/Exit).
--
-- Tiempos: el diálogo corre solo (cada frase detrás de la anterior, con sus pausas) y la escena dura
-- lo que dure su diálogo (sin Duration fija): las frases que no salen (If) no dejan huecos. Los planos
-- van en cada frase (Shot) y los gestos y miradas en sus pausas (Beat), así que se mueven con ella.
-- Solo llevan At las frases de un momento con algo fijo a la vez (un sonido, un destello, alguien que
-- entra): lo de antes de ese momento siempre ocupa lo mismo (una frase por decisión: porDecision).
-- scripts/test-instituto comprueba que nada se pisa con las combinaciones más largas.
--
-- Continuidad (W-05): las frases con If recuerdan lo que hiciste: el nombre del grupo (Cole03), la
-- promesa del último día de cole (Cole12), dónde te sentaste y con quién pasaste el recreo (Ins01), tu
-- club (Ins02), tus dudas con Carmen (Ins03), tu primer sueldo (Ins04), la noche del súper y el cruce
-- (Pan1–Pan3), el rumor (Ins05) y tu sueño de cuando tenías diez años.
--
-- Los textos de las escenas no conocen tu género (HappeningService solo pasa {nombre}): se escriben en
-- neutro.

local V = Vector3.new

---------------------------------------------------------------------
-- Ayudas
---------------------------------------------------------------------

-- Junta varias listas (y frases sueltas) en una sola, en orden
local function cat(...): { any }
	local out = {}
	for _, part in { ... } do
		if type(part) == "table" and part[1] ~= nil and type(part[1]) == "table" then
			for _, item in part do
				table.insert(out, item)
			end
		elseif type(part) == "table" then
			table.insert(out, part)
		end
	end
	return out
end

-- Condiciones juntas (las dos tienen que cumplirse)
local function both(a: { [string]: any }, b: { [string]: any }?): { [string]: any }
	local out = table.clone(a)
	for k, v in b or {} do
		if type(v) == "table" and type(out[k]) == "table" then
			local merged = table.clone(out[k])
			if merged[1] ~= nil or v[1] ~= nil then
				for _, x in v do
					table.insert(merged, x)
				end
			else
				for kk, vv in v do
					merged[kk] = vv
				end
			end
			out[k] = merged
		else
			out[k] = v
		end
	end
	return out
end

-- Una frase por cada valor de una decisión (solo sale la que tomaste; ocupan el mismo hueco).
-- values = { { Valor, Texto, { campos propios }? }, … }; extra = campos de la frase (S, Shot, Beat…);
-- cond = más requisitos
local function porDecision(key: string, values: { { any } }, extra: { [string]: any }, cond: { [string]: any }?): { any }
	local out = {}
	for i, pair in values do
		local line = table.clone(extra)
		for k, v in pair[3] or {} do
			line[k] = v
		end
		line.T = pair[2]
		line.If = both({ Choices = { [key] = pair[1] } }, cond)
		line.Alt = if i > 1 then true else nil
		table.insert(out, line)
	end
	return out
end

-- El nombre que le pusisteis al grupo en el colegio (Cole03 · NombreGrupo). fmt lleva un %s.
local GRUPOS = { "Los Imparables", "La Patrulla Valmar", "Los del Banco Azul", "Los Dinosaurios" }
local function porGrupo(fmt: string, extra: { [string]: any }, cond: { [string]: any }?): { any }
	local values = {}
	for _, name in GRUPOS do
		table.insert(values, { name, fmt:format(name) })
	end
	return porDecision("NombreGrupo", values, extra, cond)
end

local CON_LEIRE = { Flags = { "ConocesALeire" } }
local CON_HUGO = { Flags = { "HugoConElGrupo" } }
local CON_MATEO = { Flags = { "AyudasteAMateo" } }
local CON_IKER = { Flags = { "IkerEnElGrupo" } }

-- Ins05 · el reparto del día después. avergonzado = os lleváis mal: Nico no levanta la vista ni al final
local function diaDespues(avergonzado: boolean): { any }
	return {
		{ At = 0, Use = { Key = "Javier", Npc = "Javier", Anchor = "Aula", Offset = V(0, 0, -6) } },
		-- Omar entra andando detrás de ti (lo hace su misión: Enter en el paso)
		{ At = 0, Use = { Key = "Omar", Npc = "Omar", Anchor = "Aula", Offset = V(3, 0, 0) } },
		{ At = 0, Use = { Key = "Nico", Npc = "Nico", Anchor = "Aula", Offset = V(-4, 0, 2) } },
		{ At = 0, Use = { Key = "Sara", Npc = "Sara", Anchor = "Aula", Offset = V(-2, 0, 2) } },
		{ At = 0, Use = { Key = "Leire", Npc = "Leire", Anchor = "Aula", Offset = V(6, 0, 3) } },
		{ At = 0, Use = { Key = "Bruno", Npc = "Bruno", Anchor = "Aula", Offset = V(-6, 0, -1) } },
		{ At = 0.2, Mood = { Key = "Omar", Mood = "Nervous" } },
		{ At = 0.2, Mood = { Key = "Nico", Mood = "Shame" } },
		{ At = 0.5, Look = { Key = "Sara", At = "Omar" } },
		{ At = 0.6, Look = { Key = "Leire", At = "Omar" } },
		{ At = 0.7, Look = { Key = "Bruno", At = "Omar" } },
		{ At = 0.8, Look = { Key = "Nico", At = "Suelo" } },
		{ At = 12, Look = { Key = "Sara", At = "Speaker" } },
		{ At = 12, Look = { Key = "Leire", At = "Speaker" } },
		{ At = 12, Look = { Key = "Bruno", At = "Speaker" } },
		-- Darío (si se lo contaste a Javier) entra por la puerta, pide perdón y se va
		{ At = 25.5, Enter = { Key = "Dario", Npc = "Dario", From = "Puerta", Anchor = "Aula", Offset = V(5, 0, -6), Mood = "Shame" }, If = { Choices = { Dario = "Javier" } } },
		{ At = 33.6, Exit = { Key = "Dario", To = "Puerta" }, If = { Choices = { Dario = "Javier" } } },
		-- Después de perdonarse
		{ At = 50, Mood = { Key = "Omar", Mood = "Joy" } },
		{ At = 52, Mood = { Key = "Nico", Mood = if avergonzado then "Shame" else "Calm" } },
		{ At = 52, Look = { Key = "Nico", At = if avergonzado then "Suelo" else "Speaker" } },
	}
end

return {
	---------------------------------------------------------------------
	-- Ins01 · LA PARADA. El primer día de instituto, tus amigos de siempre en la parada del autobús.
	--
	-- ¿Qué está pasando?  El grupo del colegio se reencuentra en la parada el primer día de instituto.
	-- ¿Por qué?           Van a coger juntos el autobús al Campus Valmar, pero ya saben que les han
	--                     repartido en clases distintas.
	-- ¿Qué siente?        Nervios y un poco de pena (el grupo se separa), tapados con bromas: Omar ha
	--                     crecido, Sara lo ha comprobado todo tres veces, Nico se agarra a la promesa.
	-- ¿Qué ve el jugador? Un plano general de la parada → los amigos mirándose («¿has crecido?») →
	--                     primeros planos de quien recuerda la promesa → todos se giran al oír el
	--                     claxon del autobús.
	-- ¿Qué debe sentir?   Que su grupo sigue ahí aunque todo cambie: lo que prometisteis y el nombre
	--                     que os pusisteis no se han olvidado.
	---------------------------------------------------------------------
	Ins01_Parada = {
		Skippable = true,
		Center = "Parada",
		Intensity = "Nada",
		Anchors = {
			Yo = "Player",
			Parada = "Place:ParadaBus",
			Calle = { Place = "ParadaBus", Offset = V(0, 0, -16), Ground = true },
		},
		Tracks = {
			Ambience = { { At = 0, Kind = "Calle", Fade = 1.5 } },
			Camera = {
				{ At = 0, Duration = 2.8, Shot = "General" },
				-- El autobús: todos miran a la calle
				{ At = 40.2, Duration = 1.6, Shot = "Pan:Omar>Calle" },
			},
			Sound = {
				{ At = 40, Play = "Claxon", Volume = 0.5, Anchor = "Calle" },
			},
			Actors = {
				{ At = 0, Use = { Key = "Nico", Npc = "Nico", Anchor = "Parada", Offset = V(-3, 0, 2) } },
				{ At = 0, Use = { Key = "Omar", Npc = "Omar", Anchor = "Parada", Offset = V(3, 0, 2) } },
				{ At = 0, Use = { Key = "Sara", Npc = "Sara", Anchor = "Parada", Offset = V(0, 0, 4) } },
				{ At = 0, Use = { Key = "Mateo", Npc = "Mateo", Anchor = "Parada", Offset = V(-5, 0, 4) }, If = CON_MATEO },
				{ At = 0, Use = { Key = "Hugo", Npc = "Hugo", Anchor = "Parada", Offset = V(5, 0, 4) }, If = CON_HUGO },
				{ At = 0.2, Mood = { Key = "Sara", Mood = "Nervous" } },
				{ At = 0.4, Mood = { Key = "Hugo", Mood = "Nervous" }, If = CON_HUGO },
				{ At = 1.2, Look = { Key = "Nico", At = "Yo" } },
				-- El claxon: todos se giran
				{ At = 40.1, Look = { Key = "Omar", At = "Calle" } },
				{ At = 40.2, Look = { Key = "Nico", At = "Calle" } },
				{ At = 40.3, Look = { Key = "Sara", At = "Calle" } },
				{ At = 40.3, Look = { Key = "Mateo", At = "Calle" }, If = CON_MATEO },
				{ At = 40.4, Look = { Key = "Hugo", At = "Calle" }, If = CON_HUGO },
				{ At = 40.6, Mood = { Key = "Sara", Mood = "Calm" } },
				{ At = 42, Look = { Key = "Nico", At = "Speaker" } },
				{ At = 42, Look = { Key = "Sara", At = "Speaker" } },
			},
			Dialogue = cat(
				-- Os miráis como si no os conocierais (antes lo contaba el narrador)
				{ At = 2.8, S = "Sara", T = "Omar. ¿Has crecido o te has subido a algo?", To = "Omar", Shot = "Hombro:Sara>Omar" },
				{ S = "Omar", T = "Me he chocado dos veces con el marco de la puerta. Mi madre dice que es la edad.", A = "Shrug", Shot = "Medio:Omar" },
				{ S = "Nico", T = "¡{nombre}! ¡Por fin! El conductor no espera a nadie.", To = "Yo", Shot = "PrimerPlano:Nico", If = { Flags = { "LlegasTardeParada" } } },
				{ S = "Nico", T = "¡{nombre}! Antes que el autobús. Eso es de cuarto, como mínimo.", To = "Yo", A = "Happy", Shot = "PrimerPlano:Nico", IfNot = { Flags = { "LlegasTardeParada" } }, Alt = true },
				{ S = "Sara", T = "Me han puesto en el bilingüe. No vamos a estar en la misma clase. Lo he comprobado tres veces.", Beat = "Suelo", A = "Sad", Shot = "PrimerPlano:Sara" },
				-- La promesa del último día de cole y el nombre del grupo
				porDecision("Promesa", {
					{ "Juntos", "Pero en el recreo sí. ¡Lo prometimos!" },
					{ "Nuevos", "Prometimos conocer gente nueva sin olvidarnos. Hoy empieza lo de «gente nueva»." },
					{ "Banco", "Y el banco del parque en verano sigue en pie. Eso no lo cambia ningún instituto." },
				}, { S = "Nico", Beat = "Mirar", To = "Sara", Shot = "PrimerPlano:Nico" }),
				porGrupo("%s: eso no lo separa ningún horario.", { S = "Omar", A = "Nod", Shot = "DosPlanos:Omar,Sara" }),
				-- Uno más: Hugo, Mateo (si se unieron al grupo) o Sara
				{ S = "Hugo", T = "He traído un libro por si nadie me habla. Ojalá no tenga que leerlo.", Shot = "Reaccion:Hugo", If = CON_HUGO },
				{ S = "Mateo", T = "Me apunté el aula en la mano. Se me ha borrado con el sudor.", A = "Nervous", Shot = "Reaccion:Mateo", If = both(CON_MATEO, { NotFlags = { "HugoConElGrupo" } }), Alt = true },
				{ S = "Sara", T = "Si alguien se pierde, tengo el plano del instituto. Impreso. Plastificado.", Shot = "Medio:Sara", If = { NotFlags = { "HugoConElGrupo", "AyudasteAMateo" } }, Alt = true },
				-- El autobús
				{ At = 41.6, S = "Omar", T = "¡El autobús! Ese que pone «Campus Valmar». Vamos, que yo me mareo si voy de pie.", Beat = "Senalar", Shot = "Medio:Omar" },
				{ S = "Nico", T = "¡El último en subir se sienta al lado del conductor!", A = "Happy", Pause = { After = 1.2 }, Shot = "General" }
			),
		},
	},

	---------------------------------------------------------------------
	-- Ins03 · CARMEN. La orientadora entra en clase el primer día de la semana de las profesiones.
	--
	-- ¿Qué está pasando?  Javier cede la clase a Carmen, que entra andando y os explica la semana.
	-- ¿Por qué?           Es la primera vez que alguien os habla del futuro como algo vuestro.
	-- ¿Qué siente?        Carmen, calma (escucha más que habla); la clase, alivio por no tener clase y
	--                     un poco de vértigo; Bruno, el orgullo de quien «ya lo sabe»; Leire, vergüenza
	--                     (el estudio audiovisual es de su tío).
	-- ¿Qué ve el jugador? General del aula → Carmen entra por la puerta → plano medio cuando habla →
	--                     reacciones de la clase entre frase y frase (no hay monólogo) → tu compañero de
	--                     pupitre te dice algo bajito → Carmen se despide con la mano.
	-- ¿Qué debe sentir?   Curiosidad sin presión: «No tienes que saberlo hoy».
	---------------------------------------------------------------------
	Ins03_Carmen = {
		Skippable = true,
		Center = "Aula",
		Intensity = "Nada",
		Anchors = {
			Yo = "Player",
			Aula = "Place:AulaInstituto",
		},
		Tracks = {
			Ambience = { { At = 0, Kind = "Instituto", Fade = 1.5 } },
			Music = { { At = 26, Intensity = "Descubrimiento" } },
			Camera = {
				{ At = 0, Duration = 3, Shot = "General" },
			},
			Actors = {
				{ At = 0, Use = { Key = "Javier", Npc = "Javier", Anchor = "Aula", Offset = V(4, 0, -6) } },
				-- Carmen entra andando por la puerta (lo hace su misión: Enter en el paso)
				{ At = 0, Use = { Key = "Carmen", Npc = "Carmen", Anchor = "Aula", Offset = V(0, 0, -6) } },
				{ At = 0, Use = { Key = "Omar", Npc = "Omar", Anchor = "Aula", Offset = V(3, 0, 0) } },
				{ At = 0, Use = { Key = "Nico", Npc = "Nico", Anchor = "Aula", Offset = V(-4, 0, 2) } },
				{ At = 0, Use = { Key = "Bruno", Npc = "Bruno", Anchor = "Aula", Offset = V(-6, 0, -1) } },
				{ At = 0, Use = { Key = "Leire", Npc = "Leire", Anchor = "Aula", Offset = V(6, 0, 3) }, If = CON_LEIRE },
				{ At = 0.5, Look = { Key = "Omar", At = "Carmen" } },
				{ At = 0.7, Look = { Key = "Nico", At = "Carmen" } },
				{ At = 0.9, Look = { Key = "Bruno", At = "Carmen" } },
				{ At = 1.1, Look = { Key = "Leire", At = "Carmen" }, If = CON_LEIRE },
				{ At = 3, Look = { Key = "Omar", At = "Speaker" } },
				{ At = 3, Look = { Key = "Nico", At = "Speaker" } },
				{ At = 3, Look = { Key = "Bruno", At = "Speaker" } },
				{ At = 3, Look = { Key = "Leire", At = "Speaker" }, If = CON_LEIRE },
			},
			Dialogue = cat(
				-- Javier cede la clase; Carmen se presenta
				{ At = 3, S = "Javier", T = "Hoy no os doy Historia. Os presento a alguien que sabe más de vuestro futuro que yo. Tampoco es difícil.", Shot = "Medio:Javier" },
				{ S = "Carmen", T = "Hola, 1.º C. Soy Carmen, la orientadora. Esta semana no hay clase normal: es la semana de las profesiones.", Pause = 0.5, Shot = "Medio:Carmen" },
				{ S = "Nico", T = "¿Sin clase? ¿Toda la semana?", A = "Surprised", Shot = "Reaccion:Nico" },
				{ S = "Carmen", T = "Hay ocho sitios de Valmar que os abren las puertas. Visitad al menos cuatro. Preguntad, probad, meted las manos.", To = "Nico", Shot = "PrimerPlano:Carmen" },
				-- Tu compañero de pupitre (Ins01 · SitioInstituto) te dice algo bajito
				porDecision("SitioInstituto", {
					{ "Omar", "Cuatro. Yo ya sé cuál es el primero. Huele a tortilla.", { S = "Omar", Shot = "Hombro:Yo>Omar" } },
					{ "Leire", "Si en la lista hay algo con cámaras, ya sé adónde voy.", { S = "Leire", Shot = "Hombro:Yo>Leire" } },
					{ "Bruno", "Oye. ¿Vamos juntos a la comisaría? Para verla. Desde el lado bueno.", { S = "Bruno", Shot = "Hombro:Yo>Bruno" } },
				}, { To = "Yo" }),
				-- Lo importante, con un silencio antes
				{ S = "Carmen", T = "Y una cosa importante: nadie tiene que decidir su futuro esta semana. Ni este año.", Pause = 1, Beat = "Respirar", Shot = "PrimerPlano:Carmen" },
				{ S = "Carmen", T = "Solo mirar. Mirar mucho.", Pause = 0.6, Shot = "PPP:Carmen" },
				{ S = "Bruno", T = "¿Y si ya sé lo que quiero ser?", A = "ArmsCrossed", Shot = "Reaccion:Bruno" },
				{ S = "Carmen", T = "Entonces visita también algo que no tenga nada que ver. A veces uno se sorprende.", To = "Bruno", Shot = "Hombro:Bruno>Carmen" },
				{ S = "Leire", T = "¿Hay algo de cine en la lista?", Shot = "Reaccion:Leire", If = CON_LEIRE },
				{ S = "Carmen", T = "Hay un estudio audiovisual. Y me parece que allí te espera alguien de tu familia.", To = "Leire", Shot = "Medio:Carmen", If = CON_LEIRE },
				{ S = "Leire", T = "…Mi tío. Claro. Qué vergüenza.", Beat = "Suelo", A = "Ashamed", Shot = "PrimerPlano:Leire", If = CON_LEIRE },
				-- Omar, el club y la despedida
				{ S = "Omar", T = "Yo voy a visitar el restaurante primero. Por investigación. Y por la hora que es.", Shot = "Medio:Omar" },
				{ S = "Carmen", T = "Y los que ya estáis en un club: eso también cuenta. Lo que hacéis por gusto dice mucho de vosotros.", To = "Yo", Shot = "PrimerPlano:Carmen", If = { Memories = { "PrimerClub" } } },
				{ S = "Carmen", T = "Os espero el viernes. Quiero saber qué habéis descubierto.", Pause = { Before = 0.4, After = 1.4 }, Beat = "Saludar", A = "Happy", Shot = "DosPlanos:Carmen,Javier" }
			),
		},
	},

	---------------------------------------------------------------------
	-- Pan2 · LA ALARMA. Has cogido las latas en el almacén del súper de Paco y salta la alarma.
	--
	-- ¿Qué está pasando?  La alarma del supermercado suena; Rayo grita que cada uno corra por su lado.
	-- ¿Por qué?           Has decidido coger algo en el almacén. La puerta «que no cerraba bien» tenía
	--                     sensor.
	-- ¿Qué siente?        Pánico. Rayo, que lo tenía todo pensado, pierde los papeles; Nerea, rabia.
	-- ¿Qué ve el jugador? Primerísimo plano de sus propios ojos al sonar la alarma → la cara de Rayo →
	--                     cámara en mano, luz fría → Rayo señala → tú, solo, con el corazón a mil.
	-- ¿Qué debe sentir?   El estómago encogido: esto ya no es un juego. Y ganas de correr.
	---------------------------------------------------------------------
	Pan2_Alarma = {
		Skippable = true,
		Center = "Almacen",
		Intensity = "Tension",
		Duration = 16,
		Anchors = {
			Yo = "Player",
			Almacen = "Place:Supermercado",
			Puerta = { Place = "Supermercado", Offset = V(-6, 0, -12), Ground = true },
		},
		Tracks = {
			Ambience = { { At = 0, Kind = "Calle", Fade = 0.5 } },
			Light = { { At = 0, Preset = "Tension", Fade = 0.4 } },
			Shake = { { At = 0.2, Strength = 0.35, Seconds = 0.7 } },
			Sound = {
				{ At = 0.1, Play = "Aviso", Pitch = 0.7, Volume = 1.4 },
				{ At = 0.8, Play = "Aviso", Pitch = 0.55, Volume = 1.4 },
				{ At = 1.5, Play = "Aviso", Pitch = 0.7, Volume = 1.4 },
				{ At = 2.2, Play = "Aviso", Pitch = 0.55, Volume = 1.4 },
				{ At = 2.9, Play = "Aviso", Pitch = 0.7, Volume = 1.3 },
				{ At = 3.6, Play = "Aviso", Pitch = 0.55, Volume = 1.3 },
				{ At = 4.3, Play = "Aviso", Pitch = 0.7, Volume = 1.2 },
				{ At = 5, Play = "Aviso", Pitch = 0.55, Volume = 1.2 },
				{ At = 5.7, Play = "Aviso", Pitch = 0.7, Volume = 1.1 },
				{ At = 6.4, Play = "Aviso", Pitch = 0.55, Volume = 1.1 },
				{ At = 7.1, Play = "Aviso", Pitch = 0.7, Volume = 1 },
				{ At = 7.8, Play = "Aviso", Pitch = 0.55, Volume = 1 },
				{ At = 8.5, Play = "Aviso", Pitch = 0.7, Volume = 0.9 },
				{ At = 9.2, Play = "Aviso", Pitch = 0.55, Volume = 0.9 },
				{ At = 9.9, Play = "Aviso", Pitch = 0.7, Volume = 0.8 },
				{ At = 10.6, Play = "Aviso", Pitch = 0.55, Volume = 0.8 },
				{ At = 11.3, Play = "Aviso", Pitch = 0.7, Volume = 0.7 },
				{ At = 12, Play = "Aviso", Pitch = 0.55, Volume = 0.7 },
				{ At = 12.7, Play = "Aviso", Pitch = 0.7, Volume = 0.6 },
				{ At = 13.4, Play = "Aviso", Pitch = 0.55, Volume = 0.5 },
			},
			Camera = {
				{ At = 0, Duration = 1.4, Shot = "PPP:Yo", Shake = 0.35 },
				{ At = 1.4, Duration = 1.6, Shot = "Reaccion:Rayo", Shake = 0.3, Cut = "Cut" },
				{ At = 13, Duration = 3, Shot = "PrimerPlano:Yo", Shake = 0.4, Cut = "Cut" },
			},
			Actors = {
				{ At = 0, Use = { Key = "Rayo", Npc = "Rayo", Anchor = "Almacen", Offset = V(-8, 0, -10) } },
				{ At = 0, Use = { Key = "Nerea", Npc = "Nerea", Anchor = "Almacen", Offset = V(-10, 0, -8) } },
				{ At = 0.2, Mood = { Key = "Rayo", Mood = "Surprise" } },
				{ At = 0.3, Mood = { Key = "Nerea", Mood = "Fear" } },
				{ At = 0.4, Look = { Key = "Rayo", At = "Puerta" } },
				{ At = 0.5, Look = { Key = "Nerea", At = "Puerta" } },
				{ At = 2.2, Mood = { Key = "Rayo", Mood = "Fear" } },
			},
			Dialogue = {
				{ At = 1.6, S = "Narrador", T = "La alarma. Luces rojas. Un perro ladra en la calle de al lado." },
				{ S = "Nerea", T = "¡Rayo! ¿«Nadie se va a enterar»? ¡¿Esto es nadie?!", A = "Angry", To = "Rayo", Shot = "Medio:Nerea" },
				{ S = "Rayo", T = "¡CORRED! ¡Cada uno por un lado! ¡Nos vemos en el parque!", Beat = "Senalar", Shot = "Medio:Rayo" },
			},
			Titles = {
				{ At = 13.2, Text = "¡Corre!", Sub = "Llega al parque antes que la policía", Duration = 2.6 },
			},
		},
	},

	---------------------------------------------------------------------
	-- Pan3 · LA OFERTA. Rayo, expulsado y solo, en el banco del parque al atardecer.
	--
	-- ¿Qué está pasando?  Rayo te ofrece vender camisetas falsas del Altamar: cincuenta por tarde.
	-- ¿Por qué?           Le han expulsado tres días por lo del súper; en casa no hay nadie y busca a
	--                     alguien que se quede con él. El dinero es la excusa.
	-- ¿Qué siente?        Rayo: soledad que disfraza de chulería (no te mira hasta que hace la oferta).
	--                     Tú: la tentación.
	-- ¿Qué ve el jugador? General del parque al atardecer → Rayo de perfil, mirando a otro lado → te mira
	--                     cuando recuerda lo que hiciste en el súper → la oferta en primer plano → tu cara
	--                     haciendo cuentas.
	-- ¿Qué debe sentir?   Que cincuenta es mucho. Y que algo no encaja.
	---------------------------------------------------------------------
	Pan3_Oferta = {
		Skippable = true,
		Center = "Banco",
		Intensity = "Nada",
		Anchors = {
			Yo = "Player",
			Banco = { Place = "Parque", Offset = V(-12, 0, 8), Ground = true },
		},
		Tracks = {
			Ambience = { { At = 0, Kind = "Parque", Fade = 2 } },
			Light = { { At = 0, Preset = "Atardecer", Fade = 2 } },
			Music = { { At = 20, Intensity = "Tension" } },
			Camera = {
				{ At = 0, Duration = 3.2, Shot = "General" },
			},
			Actors = {
				{ At = 0, Use = { Key = "Rayo", Npc = "Rayo", Anchor = "Banco" } },
				{ At = 0.3, Look = { Key = "Rayo", At = "Away" } },
				{ At = 0.3, Mood = { Key = "Rayo", Mood = "Sad" } },
				{ At = 20, Mood = { Key = "Rayo", Mood = "Calm" } },
			},
			Dialogue = {
				-- Rayo, solo (no te mira)
				{ At = 3.2, S = "Rayo", T = "Tres días de expulsión. Mi madre ni se ha enterado.", Shot = "Lateral:Rayo" },
				{ S = "Rayo", T = "Trabaja de noche. Duerme de día. Somos compañeros de piso, más o menos.", A = "Shrug", Shot = "Lateral:Rayo" },
				{ S = "Rayo", T = "Por lo del súper. Y tú… tú no dijiste nada. Eso no se me olvida.", Beat = "Mirar", To = "Yo", Shot = "PrimerPlano:Rayo", If = { Flags = { "Pillado" } } },
				{ S = "Rayo", T = "Tú corriste más que yo. Ahora ya sabes lo que es. Y no te ha ido tan mal, ¿no?", Beat = "Mirar", To = "Yo", Shot = "PrimerPlano:Rayo", If = { Flags = { "Escapaste" } }, Alt = true },
				{ S = "Rayo", T = "Tú no viniste. Da igual. Te voy a dar otra oportunidad. Porque me caes bien. No sé por qué.", Beat = "Mirar", To = "Yo", Shot = "PrimerPlano:Rayo", If = { NotFlags = { "Hurto" } }, Alt = true },
				{ S = "Rayo", T = "Nerea dice que tú le dijiste que no fuera. Y no fue. A ti te hace caso. A mí ya no.", Beat = "Apartar", A = "Sad", Shot = "Lateral:Rayo", If = { Choices = { Plan = "Frenar" } } },
				-- La oferta
				{ S = "Rayo", T = "Tengo un negocio.", Pause = 1, Beat = "Mirar", To = "Yo", Shot = "PrimerPlano:Rayo" },
				{ S = "Rayo", T = "Camisetas del Altamar. Iguales que las de verdad, a una cuarta parte del precio. Las vendemos a la salida del estadio.", Shot = "Hombro:Yo>Rayo" },
				{ S = "Rayo", T = "Cincuenta pavos por tarde. Nadie sale herido. El club tiene millones.", A = "Shrug", Shot = "Medio:Rayo" },
				{ S = "Rayo", T = "¿Qué me dices?", Pause = 0.8, Shot = "Hombro:Rayo>Yo" },
				{ S = "Narrador", T = "Cincuenta. Por una tarde. Piensas en todo lo que se puede hacer con cincuenta.", Pause = 0.6, Shot = "PPP:Yo" },
				{ S = "Narrador", T = "Y te acuerdas de Abu: «las mentiras pesan más que la mochila».", Pause = { After = 1 }, Shot = "PPP:Yo", If = { Flags = { "MentisteFamilia" } } },
				{ S = "Rayo", T = "Piénsatelo. Yo aquí estoy. Como siempre.", Pause = { Before = 0.8, After = 1.2 }, Beat = "Apartar", Shot = "DosPlanos:Rayo,Yo" },
			},
		},
		-- Si os lleváis mal, Rayo está a la defensiva desde el principio (y la tensión llega antes)
		Variants = {
			{
				Name = "Distantes",
				If = { RelBelow = { Rayo = 0 } },
				Tracks = {
					Music = { { At = 3, Intensity = "Tension" } },
					Actors = {
						{ At = 0, Use = { Key = "Rayo", Npc = "Rayo", Anchor = "Banco" } },
						{ At = 0.3, Look = { Key = "Rayo", At = "Away" } },
						{ At = 0.3, Mood = { Key = "Rayo", Mood = "Angry" } },
					},
				},
			},
		},
	},

	---------------------------------------------------------------------
	-- Ins05 · EL DÍA DESPUÉS. Omar vuelve a clase después de la foto trucada.
	--
	-- ¿Qué está pasando?  Omar entra en clase contigo; Javier habla a todos; Darío (según lo que
	--                     decidiste) pide perdón; Nico se disculpa delante de todos y Omar le perdona.
	-- ¿Por qué?           La foto «Omar el Tragón» la compartió Nico; tú le paraste los pies.
	-- ¿Qué siente?        Omar, miedo a entrar (nervios) y luego alivio; Nico, vergüenza (no mira a
	--                     nadie hasta que se atreve); la clase, silencio incómodo.
	-- ¿Qué ve el jugador? General del aula en silencio → Omar entra andando → Bruno le choca la mano →
	--                     Nico de pie, mirando al suelo → la pausa de Omar antes de contestar → las
	--                     pulseras del grupo.
	-- ¿Qué debe sentir?   Que se puede reparar algo roto. Y que el grupo (con su nombre) sigue.
	---------------------------------------------------------------------
	Ins05_DiaDespues = {
		Skippable = true,
		Center = "Aula",
		Intensity = "Nada",
		Anchors = {
			Yo = "Player",
			Aula = "Place:AulaInstituto",
			Puerta = { Place = "AulaInstituto", Offset = V(7, 0, -9), Ground = true },
		},
		Tracks = {
			Ambience = { { At = 0, Kind = "Instituto", Fade = 1.5 } },
			Music = {
				{ At = 36, Intensity = "Intima" },
				{ At = 50, Intensity = "Resolucion" },
			},
			Camera = {
				{ At = 0, Duration = 3, Shot = "General" },
				{ At = 3, Duration = 3, Shot = "Seguir:Omar" },
			},
			Actors = diaDespues(false),
			Dialogue = cat(
				-- Entráis juntos
				{ At = 1.2, S = "Narrador", T = "Pasas a buscar a Omar a la parada. Entráis juntos en clase. Nadie dice nada." },
				{ S = "Bruno", T = "Eh, Omar. Choca.", A = "WaveLite", To = "Omar", Pause = 0.6, Shot = "Reaccion:Bruno" },
				{ S = "Omar", T = "…Hola.", Beat = "Suelo", Shot = "PrimerPlano:Omar" },
				-- Javier
				{ At = 12, S = "Javier", T = "Antes de empezar: el grupo de clase es de esta clase. Lo que no diríais a la cara, no se escribe ahí.", Shot = "Medio:Javier", If = { Choices = { Dario = "Javier" } } },
				{ S = "Javier", T = "Si alguna vez os pasa algo así, contadlo a un adulto. A mí, a vuestra familia. No es chivarse: es cuidarse.", Shot = "Medio:Javier" },
				-- Darío (una de tres, según lo que decidiste)
				{ At = 28, S = "Dario", T = "Omar… lo siento. De verdad. Era una tontería y no lo pensé.", Beat = "Suelo", To = "Omar", Shot = "PrimerPlano:Dario", If = { Choices = { Dario = "Javier" } } },
				{ S = "Omar", T = "Mira. Darío me escribió anoche: «Perdón. La he borrado. Fue una idiotez.»", To = "Yo", Shot = "DosPlanos:Omar,Yo", If = { Choices = { Dario = "Perdon" } } },
				{ S = "Narrador", T = "La guerra de montajes ha terminado porque Javier ha borrado el grupo entero. Nadie sale bien parado. Tú tampoco.", Shot = "Reaccion:Yo", If = { Choices = { Dario = "Venganza" } } },
				-- Nico
				{ S = "Nico", T = "Omar. Yo… lo siento.", Pause = 1.2, Beat = "Suelo", To = "Omar", Shot = "PrimerPlano:Nico" },
				{ S = "Nico", T = "No hay excusa. Me pasé. Te echo de menos en el recreo.", Beat = "Mirar", To = "Omar", Shot = "Hombro:Omar>Nico" },
				porDecision("HablasNico", {
					{ "Privado", "{nombre} me lo dijo a la cara, sin nadie delante. Ahora te lo digo yo a ti." },
					{ "Publico", "Me lo dijeron delante de todo el equipo. Me lo merecía. Ahora te lo digo yo delante de todos." },
				}, { S = "Nico", To = "Omar", Shot = "PrimerPlano:Nico" }),
				{ S = "Omar", T = "…Vale.", Pause = 1.4, Beat = "Pensar", Shot = "PPP:Omar" },
				{ S = "Omar", T = "Pero me debes diez bocadillos. Y los eliges tú, que así sufres.", A = "Happy", To = "Nico", Shot = "DosPlanos:Omar,Nico" },
				-- Las pulseras del grupo
				{ S = "Omar", T = "He hecho pulseras para todos. Del grupo. Por si se nos olvida quiénes somos.", Pause = 0.6, Beat = "Mirar", Shot = "Medio:Omar" },
				porGrupo("Pone «%s». Con hilo de colores. Omar, son preciosas.", { S = "Sara", A = "Happy", Shot = "Reaccion:Sara" }),
				{ S = "Omar", T = "Y la primera es para ti. Te reíste, y me lo dijiste. Eso cuenta.", To = "Yo", Shot = "Hombro:Yo>Omar", If = { Flags = { "TeReiste" } } },
				{ S = "Leire", T = "La foto dejó de moverse porque alguien escribió «Borradla». Yo solo puse el +1.", To = "Yo", Shot = "Reaccion:Leire", If = { Choices = { Foto = "Frenar" }, NotFlags = { "TeReiste" } }, Alt = true },
				{ S = "Narrador", T = "Esa mañana, en 1.º C, todos llevan la misma pulsera.", Pause = { Before = 0.6, After = 1.4 }, Shot = "DosPlanos:Omar,Nico" }
			),
		},
		-- Si Nico y tú acabasteis mal, no se atreve a levantar la vista ni cuando Omar le perdona
		Variants = {
			{ Name = "NicoAvergonzado", If = { RelBelow = { Nico = 0 } }, Tracks = { Actors = diaDespues(true) } },
		},
	},

	---------------------------------------------------------------------
	-- Ins06 · LA NOCHE (final del instituto, 1/2). La noche antes de decidir, en el salón de casa.
	--
	-- ¿Qué está pasando?  No puedes dormir. Abu tampoco. Tu familia baja con leche con cacao y entre las
	--                     dos te cuentan lo que nadie te ha contado: lo que ellas quisieron ser.
	-- ¿Por qué?           Mañana hay que entregar la solicitud: universidad o trabajar.
	-- ¿Qué siente?        Tú, vértigo. Abu, ternura y una pena vieja («me quedé con las ganas»). Tu
	--                     familia, orgullo y miedo a que te vayas.
	-- ¿Qué ve el jugador? El salón a oscuras → la lámpara se enciende → tu cara → Abu en su sillón → tu
	--                     familia entra desde la cocina → Abu mira a otro lado al recordar → te mira →
	--                     primerísimo plano tuyo con el recuerdo del banco del parque.
	-- ¿Qué debe sentir?   Que decidas lo que decidas, hay un sitio al que volver. Y el peso bonito de
	--                     haber vivido todo lo anterior (te recuerdan tu primer día, tu primer sueldo,
	--                     la noche de la comisaría, tus dudas…).
	---------------------------------------------------------------------
	Ins06_Noche = {
		Skippable = true,
		FadeIn = true,
		Center = "Salon",
		Intensity = "Intima",
		Anchors = {
			Yo = "Player",
			Salon = "Place:HomeSalon",
			Cocina = "Place:HomeCocina",
		},
		Tracks = {
			Ambience = { { At = 0, Kind = "Casa", Fade = 2 } },
			Light = { { At = 0, Preset = "Noche", Fade = 1 }, { At = 2.6, Preset = "InteriorCalido", Fade = 2.5 } },
			Sound = {
				{ At = 0.4, Play = "Reloj" },
				{ At = 1.4, Play = "Reloj" },
				{ At = 2.4, Play = "Interruptor" },
				{ At = 3.4, Play = "Reloj" },
			},
			Camera = {
				{ At = 0, Duration = 3.2, Shot = "General" },
				-- Tu familia entra desde la cocina
				{ At = 15.5, Duration = 3.5, Shot = "Seguir:Familia" },
			},
			Actors = {
				{ At = 0, Use = { Key = "Abu", Npc = "Abu", Anchor = "Salon", Offset = V(10, 0, -2) } },
				-- Tu familia (la mueve su misión: entra andando desde la cocina, Enter en el paso)
				{ At = 0, Use = { Key = "Familia", Npc = "Familia", Anchor = "Salon", Offset = V(-4, 0, 0) } },
				{ At = 0.5, Look = { Key = "Abu", At = "Yo" } },
				{ At = 15.5, Look = { Key = "Abu", At = "Familia" } },
				{ At = 19, Look = { Key = "Abu", At = "Speaker" } },
			},
			Dialogue = cat(
				-- La casa duerme; tú no
				{ At = 3.2, S = "Narrador", T = "En la estantería del salón, cosas de todas las épocas: la foto del grupo, el diploma de primaria, la insignia del club…", Shot = "Lateral:Yo" },
				{ S = "Abu", T = "Tú tampoco duermes, ¿eh? A mi edad es normal. A la tuya es que algo pesa.", Pause = 0.6, Shot = "PrimerPlano:Abu" },
				-- Tu familia baja con cacao (una frase de tu primer día; luego, lo que haya pasado)
				{ At = 19, S = "Familia", T = "¿No puedes dormir? Yo tampoco dormía la noche antes de decidir. Ven, que hay leche con cacao.", To = "Yo", Shot = "Medio:Familia" },
				porDecision("PrimerDiaIns", {
					{ "Acompanado", "El primer día de instituto me pediste que te acompañara hasta la puerta. Mañana no puedo acompañarte a ningún sitio." },
					{ "Solo", "El primer día de instituto te fuiste sin mirar atrás. Ya entonces supe que esta noche iba a llegar." },
				}, { S = "Familia", Beat = "Pensar", Shot = "PrimerPlano:Familia" }),
				{ S = "Familia", T = "La última vez que salí así de noche fue para ir a buscarte a una comisaría. Prefiero esta noche. Mucho.", A = "Sad", Shot = "Hombro:Yo>Familia", If = { Flags = { "Pillado" } } },
				{ S = "Familia", T = "Y con el dinero que ahorraste en aquel verano, algo te ayudará.", A = "Happy", Shot = "Medio:Familia", If = { Choices = { Meta = "Ahorro" } } },
				{ S = "Familia", T = "Todavía me acuerdo de la cena que pagaste con tu primer sueldo. Postre incluido.", A = "Happy", Shot = "Medio:Familia", If = { Choices = { Sueldo = "Familia" } } },
				{ S = "Familia", T = "Lola me paró ayer en la calle. Dice que cuando quieras, tienes delantal.", A = "Happy", Shot = "Medio:Familia", If = { Flags = { "BuenTrabajo" }, Choices = { Empleo = "Barista" } } },
				-- Lo que Abu quiso ser
				{ S = "Abu", T = "Mira, cariño. A tu edad yo quería enseñar en una escuela, y en casa dijeron que no.", Pause = 1, Beat = "Pensar", Shot = "PrimerPlano:Abu" },
				{ S = "Abu", T = "Acabé en un taller de costura. Fui feliz.", Shot = "PrimerPlano:Abu" },
				{ S = "Abu", T = "Pero me quedé con las ganas.", Pause = 1, Beat = "Suelo", A = "Sad", Shot = "PPP:Abu" },
				{ S = "Abu", T = "Haz lo que te haga feliz. Y si no sale, vuelve a intentarlo. Aquí vamos a estar.", Pause = 0.8, Beat = "Mirar", To = "Yo", Shot = "Hombro:Yo>Abu" },
				porDecision("Orientacion", {
					{ "Claro", "Siempre has sabido lo que te gustaba. Ahora solo te falta creértelo." },
					{ "Dudas", "Carmen nos dijo una vez que las dudas son buena señal. Pues esta casa está llenísima de buenas señales." },
					{ "Muchas", "Te gustan mil cosas. No tienes que elegir una para siempre. Solo la primera." },
				}, { S = "Familia", To = "Yo", Shot = "DosPlanos:Familia,Yo" }),
				{ S = "Abu", T = "Y lo de estos años, lo sé. Lo difícil no es entrar. Es salir. Todavía estás a tiempo.", Beat = "Mirar", Shot = "PrimerPlano:Abu", If = { Flags = { "Camino_Delincuente" } } },
				{ S = "Abu", T = "Saliste de algo difícil, cariño. Eso no lo enseña ningún instituto.", Beat = "Mirar", A = "Happy", Shot = "PrimerPlano:Abu", If = { Flags = { "Redimido" }, NotFlags = { "Camino_Delincuente" } }, Alt = true },
				-- El banco del parque
				{ S = "Narrador", T = "Cuando tenías diez años, en un banco del parque, dijiste qué querías ser. Te acuerdas perfectamente.", Pause = 1, Shot = "PPP:Yo" },
				porDecision("SuenoInfancia", {
					{ "Medicina", "«Salvar vidas en un hospital». Lo dijiste muy en serio." },
					{ "Ingenieria", "«Inventar cosas que no existen». Lo dijiste muy en serio." },
					{ "Derecho", "«Defender a la gente en los juzgados». Lo dijiste muy en serio." },
					{ "Economia", "«Tener mi propia tienda». Lo dijiste muy en serio." },
					{ "Arte", "«Ser artista». Lo dijiste muy en serio." },
					{ "Deporte", "«Deportista profesional». Lo dijiste muy en serio." },
				}, { S = "Narrador", Pause = { After = 1.6 }, Shot = "PPP:Yo" })
			),
		},
	},

	---------------------------------------------------------------------
	-- Ins06 · LA GRADUACIÓN (final del instituto, 2/2). El patio, la orla, tu familia.
	--
	-- ¿Qué está pasando?  Javier despide a la promoción, Carmen os da un último consejo, el grupo se
	--                     hace la foto de la orla (Leire la dispara con la cámara de su abuelo) y luego
	--                     todos se buscan: tu grupo, tu compañero de pupitre, tu familia.
	-- ¿Por qué?           Se acaba el instituto: es el final del capítulo.
	-- ¿Qué siente?        Todos, una alegría con nudo en la garganta. Javier se hace el irónico para no
	--                     emocionarse. Tu familia, orgullo sin vergüenza ninguna.
	-- ¿Qué ve el jugador? General del patio lleno → Javier en plano medio (te mira al recordar el
	--                     ascensor) → Carmen → la foto: destello y celebración → el grupo con su nombre →
	--                     tu familia saludando → Abu, en primer plano, y la música del final.
	-- ¿Qué debe sentir?   Que ha valido la pena. Que esa gente es suya. Y ganas de ver qué viene.
	---------------------------------------------------------------------
	Ins06_Graduacion = {
		Skippable = true,
		Center = "Patio",
		Intensity = "Resolucion",
		Anchors = {
			Yo = "Player",
			Patio = "Place:PatioInstituto",
		},
		Tracks = {
			Ambience = { { At = 0, Kind = "Instituto", Fade = 1.5 } },
			Music = { { At = 38, Intensity = "Tema" } },
			Sound = {
				{ At = 1, Play = "Multitud", Volume = 0.8 },
				{ At = 38, Play = "Clic", Pitch = 0.7 },
				{ At = 38.3, Play = "Multitud", Volume = 1 },
			},
			Camera = {
				{ At = 0, Duration = 3.5, Shot = "General" },
				-- La foto de la orla: el destello de la cámara
				{ At = 38, Duration = 1.4, Shot = "General", Cut = "Flash" },
			},
			Titles = {
				{ At = 0.6, Text = "Graduación", Sub = "Instituto del Campus Valmar", Duration = 2.6 },
			},
			Actors = {
				{ At = 0, Use = { Key = "Javier", Npc = "Javier", Anchor = "Patio", Offset = V(0, 0, 10) } },
				{ At = 0, Use = { Key = "Carmen", Npc = "Carmen", Anchor = "Patio", Offset = V(4, 0, 10) } },
				{ At = 0, Use = { Key = "Familia", Npc = "Familia", Anchor = "Patio", Offset = V(-10, 0, 6) } },
				{ At = 0, Use = { Key = "Abu", Npc = "Abu", Anchor = "Patio", Offset = V(-12, 0, 8) } },
				{ At = 0, Use = { Key = "Sara", Npc = "Sara", Anchor = "Patio", Offset = V(-4, 0, 2) } },
				{ At = 0, Use = { Key = "Nico", Npc = "Nico", Anchor = "Patio", Offset = V(10, 0, -3) } },
				{ At = 0, Use = { Key = "Omar", Npc = "Omar", Anchor = "Patio", Offset = V(0, 0, 4) } },
				{ At = 0, Use = { Key = "Bruno", Npc = "Bruno", Anchor = "Patio", Offset = V(-10, 0, 6) } },
				{ At = 0, Use = { Key = "Leire", Npc = "Leire", Anchor = "Patio", Offset = V(5, 0, 2) }, If = CON_LEIRE },
				{ At = 0, Use = { Key = "Hugo", Npc = "Hugo", Anchor = "Patio", Offset = V(-6, 0, -3) }, If = CON_HUGO },
				{ At = 0, Use = { Key = "Mateo", Npc = "Mateo", Anchor = "Patio", Offset = V(3, 0, -4) }, If = CON_MATEO },
				{ At = 0, Use = { Key = "Iker", Npc = "Iker", Anchor = "Patio", Offset = V(7, 0, 6) }, If = CON_IKER },
				{ At = 0.4, Mood = { Key = "Familia", Mood = "Joy" } },
				{ At = 0.6, Mood = { Key = "Nico", Mood = "Joy" } },
				{ At = 3.5, Look = { Key = "Familia", At = "Javier" } },
				{ At = 3.5, Look = { Key = "Abu", At = "Javier" } },
				-- La foto
				{ At = 38.1, Gesture = { Key = "Nico", Play = "Cheer" } },
				{ At = 38.2, Gesture = { Key = "Sara", Play = "Cheer" } },
				{ At = 38.3, Gesture = { Key = "Omar", Play = "Cheer" } },
				{ At = 38.3, Gesture = { Key = "Mateo", Play = "Cheer" }, If = CON_MATEO },
				{ At = 38.4, Gesture = { Key = "Hugo", Play = "Cheer" }, If = CON_HUGO },
				{ At = 38.4, Gesture = { Key = "Iker", Play = "Cheer" }, If = CON_IKER },
				{ At = 39, Look = { Key = "Familia", At = "Speaker" } },
				{ At = 39, Look = { Key = "Abu", At = "Speaker" } },
				{ At = 41, Mood = { Key = "Abu", Mood = "Joy" } },
			},
			Dialogue = cat(
				-- Javier (siempre lo mismo de largo: una frase según lo que hiciste con el «ascensor»)
				{ At = 3.6, S = "Javier", T = "Promoción de este año: cuando llegasteis, no sabíais ni dónde estaba el aula.", Shot = "Medio:Javier" },
				{ S = "Javier", T = "Algunos esperasteis un ascensor que no existe.", To = "Yo", Pause = 0.4, Shot = "PrimerPlano:Javier", If = { Choices = { Veterano = "Creer" } } },
				{ S = "Javier", T = "Otros preguntasteis a la delegada. Que es lo que hay que hacer: preguntar es de listos.", To = "Yo", Pause = 0.4, Shot = "PrimerPlano:Javier", IfNot = { Choices = { Veterano = "Creer" } }, Alt = true },
				{ S = "Javier", T = "Hoy os vais sabiendo algo más importante: quiénes sois.", Pause = 0.6, Shot = "Medio:Javier" },
				{ S = "Javier", T = "Más o menos. Que ya es mucho.", Pause = 0.8, Beat = "Pensar", A = "Shrug", Shot = "PrimerPlano:Javier" },
				{ S = "Carmen", T = "Nadie tiene que tenerlo todo claro hoy. Solo hay que dar el primer paso. Y si os equivocáis, se cambia.", Shot = "Medio:Carmen" },
				-- La foto de la orla (Leire la hace con la cámara de su abuelo; si no, Javier)
				{ At = 33, S = "Leire", T = "Esta foto la hago yo. Con la cámara de mi abuelo. Nada de móviles.", Shot = "Medio:Leire", If = CON_LEIRE },
				{ At = 33, S = "Javier", T = "Todos juntos para la orla. Omar, los ojos abiertos. Nico, en el suelo.", Shot = "Medio:Javier", IfNot = CON_LEIRE, Alt = true },
				{ At = 39.6, S = "Narrador", T = "La foto de la orla: Omar con los ojos cerrados. Nico saltando. Sara en su sitio exacto. Tú, en medio.", Shot = "General" },
				-- Después: os buscáis
				porDecision("RecreoIns", {
					{ "Rincon", "Cuatro años después, el banco del rincón sigue siendo territorio del grupo. Lo he comprobado." },
					{ "Nico", "¡Desde aquel primer recreo con los de segundo juegas en mi equipo! ¡Para siempre!", { S = "Nico", Shot = "Reaccion:Nico" } },
					{ "Explorar", "El primer día te aprendiste el instituto entero. Ahora te lo sabes de memoria. Y nosotros a ti." },
				}, { S = "Sara", To = "Yo", Shot = "Reaccion:Sara" }),
				porGrupo("%s. Promoción de este año. Que lo sepa todo el mundo.", { S = "Omar", A = "Happy", Shot = "DosPlanos:Omar,Yo" }),
				{ S = "Bruno", T = "Cuatro años en el mismo pupitre y nunca te copié. Bueno. Una vez.", To = "Yo", Shot = "PrimerPlano:Bruno", If = { Choices = { SitioInstituto = "Bruno" } } },
				{ S = "Leire", T = "¿Todavía tienes la foto del primer día? Yo también me quedé una tuya. No se lo digas a nadie.", To = "Yo", Shot = "PrimerPlano:Leire", If = both(CON_LEIRE, { Items = { FotoDeLeire = 1 } }) },
				{ S = "Javier", T = "Por cierto, {nombre}: lo de llegar tarde el primer día. Perdonado. Por fin.", To = "Yo", Shot = "Medio:Javier", If = { Flags = { "LlegasTardeInstituto" } } },
				{ S = "Javier", T = "Y que un grupo de clase no es un campo de batalla. Eso lo aprendimos todos por las malas.", To = "Yo", Shot = "Medio:Javier", If = { Flags = { "MontajeDario" } } },
				-- Tu familia y el final
				{ S = "Familia", T = "¡{nombre}! ¡Mírame! ¡Una más! ¡La última! ¡Bueno, otra!", Beat = "Saludar", Shot = "Medio:Familia" },
				{ S = "Abu", T = "Mira cuánta gente te quiere, cariño. Eso no sale en la orla. Pero se nota.", Shot = "PrimerPlano:Abu" },
				{ S = "Narrador", T = "El instituto se acaba. Empieza todo lo demás.", Pause = { Before = 0.8, After = 2 }, Shot = "General" }
			),
		},
	},
}
