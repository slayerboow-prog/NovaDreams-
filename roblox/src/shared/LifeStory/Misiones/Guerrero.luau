-- GUERRERO ESPACIAL · «PRIMERAS MISIONES» (17-11-2026, el dueño: «modifica las misiones de la historia y ambiéntalas
-- a la nueva historia»). Después del juramento de la Academia (Misiones/Academia, marca GuerreroEspacial): el
-- capítulo Guerrero_Primeras de shared/LifeStory/Chapters. Cinco misiones:
--   1. Patrulla: limpiar los distritos de caza cerca del Distrito Central.
--   2. Más lejos: el Campus abandonado y el Este, bestias más duras.
--   3. Despegue: ir al puerto espacial y salir al espacio en tu nave (aterrizar en un planeta: PlanetLanded).
--   4. Otro mundo: recoger material de un planeta (PlanetGather) para la Academia.
--   5. El ascenso: Kael te nombra guerrero de primera; la Saga de la Grieta y los planetas siguen en el mapa.

local V = Vector3.new

local PISTA = {
	{ Npc = "Kael", Place = "Pista", Offset = V(0, 0, -6) },
	{ Npc = "Sorel", Place = "Pista", Offset = V(6, 0, -2), Mode = "Chat" },
	{ Npc = "Brenn", Place = "Pista", Offset = V(-4, 0, -4) },
}
local PUERTO = {
	{ Npc = "Kael", Place = "PuertoEspacial", Offset = V(0, 0, 8) },
	{ Npc = "Sorel", Place = "PuertoEspacial", Offset = V(5, 0, 6), Mode = "Cheer" },
}

local COMUN = {
	Kind = "Main",
	Chapter = "Guerrero_Primeras",
	AgeRange = { 16, 18 },
	Difficulty = 2,
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
		Id = "Gue01_Patrulla",
		Title = "Primera patrulla",
		Description = "Cada noche las manadas llegan más cerca de la muralla. Anoche cruzaron la Ronda y una familia del centro no llegó a casa.",
		Duration = { 8, 12 },
		Type = "Guerrero · Patrulla",
		Next = { "Gue02_MasLejos" },
		Rewards = { Money = 600 },
		Steps = {
			{ Type = "Scene", Dialogue = "Orden", Actors = PISTA },
			{ Type = "Event", Event = "BeastKilled", Count = 8,
				Text = "Patrulla los distritos de caza (Oeste y Sur, los más cercanos) y caza 8 bestias ({count}/{total})" },
			{ Type = "Talk", Npc = "Kael", Dialogue = "Parte", Text = "Da el parte a Kael en la Academia", Actors = PISTA },
		},
		Dialogues = {
			Orden = { Lines = {
				{ S = "Kael", T = "Guerrero {nombre}. Se acabaron las prácticas." },
				{ S = "Kael", T = "Anoche una manada cruzó la Ronda. Tres muertos en la calle de las Torres. Quiero el Oeste y el Sur limpios antes de que anochezca." },
				{ S = "Brenn", T = "Yo cubro la muralla norte. Si encuentras algo que no puedes con ello, retírate y avisa. Morir no ayuda a nadie." },
			} },
			Parte = { Lines = {
				{ S = "Kael", T = "Ocho bestias. Esta noche nadie del centro va a tener que correr." },
				{ S = "Sorel", T = "En el Sur he encontrado mochilas de niños en una parada de autobús. De la noche de la Caída. Las he traído." },
				{ S = "Kael", T = "Déjalas en la pared de la entrada. Mañana, más lejos: el Este y el campus. Ahí las manadas son más grandes y más listas." },
			}, Effects = { Rel = { Kael = 3 } } },
		},
	}),

	mision({
		Id = "Gue02_MasLejos",
		Title = "Más allá de la Ronda",
		Description = "El campus abandonado y las playas del Este: manadas grandes, bestias que aprenden. Sorel va contigo hasta donde pueda.",
		Duration = { 10, 15 },
		Difficulty = 3,
		Type = "Guerrero · Caza",
		Next = { "Gue03_Despegue" },
		Rewards = { Money = 900 },
		Steps = {
			{ Type = "Scene", Dialogue = "Lejos", Actors = PISTA },
			{ Type = "Event", Event = "BeastKilled", Count = 15,
				Text = "Caza 15 bestias en los distritos del Este y del Campus (mira el mapa) ({count}/{total})" },
			{ Type = "Talk", Npc = "Kael", Dialogue = "Vuelta", Text = "Vuelve a la Academia: Kael quiere hablar contigo", Actors = PISTA },
		},
		Dialogues = {
			Lejos = { Lines = {
				{ S = "Kael", T = "El campus fue un refugio durante la Caída. Aguantó tres días. Lo que hay dentro ahora vive de lo que encontró allí." },
				{ S = "Kael", T = "Furia antes de entrar. Coraza cuando te rodeen. Si te quedas sin espíritu, sal de ahí con la Embestida y no mires atrás." },
				{ S = "Sorel", T = "Voy contigo. No me mires así: si me pasa algo, que sea haciendo esto." },
			} },
			Vuelta = { Lines = {
				{ S = "Narrador", T = "Sorel vuelve con el brazo vendado y la cara gris. Una bestia del campus la arrastró diez metros antes de que llegaras." },
				{ S = "Sorel", T = "Estoy bien. Estoy viva. Gracias a ti." },
				{ S = "Kael", T = "Quince bestias y una compañera de vuelta. Eso es lo que significa el juramento." },
				{ S = "Brenn", T = "Hay guerreros con diez años de servicio que no han hecho lo que tú hoy." },
				{ S = "Kael", T = "Ve al puerto espacial. Tu nave está lista. La Grieta no se abrió aquí por casualidad: la respuesta está ahí arriba." },
			}, Effects = { Rel = { Kael = 4, Brenn = 3, Sorel = 6 } } },
		},
	}),

	mision({
		Id = "Gue03_Despegue",
		Title = "El primer despegue",
		Description = "La Grieta no nació en Valmar. Hay que saber de dónde vienen las bestias, y para eso hay que subir.",
		Duration = { 6, 10 },
		Type = "Guerrero · Espacio",
		Locations = { "PuertoEspacial" },
		Next = { "Gue04_OtroMundo" },
		Moment = "Tu primer despegue",
		Rewards = { Money = 500 },
		Steps = {
			{ Type = "Reach", Place = "PuertoEspacial", Text = "Ve al puerto espacial (el islote de la costa oeste)", Actors = PUERTO },
			{ Type = "Scene", Dialogue = "Nave", Actors = PUERTO },
			{ Type = "Event", Event = "PlanetLanded", Text = "Despega con tu nave y aterriza en cualquier planeta" },
		},
		Dialogues = {
			Nave = { Lines = {
				{ S = "Narrador", T = "En la plataforma espera una nave de patrulla. Tiene arañazos de garras en el casco: perteneció a la escuadra de Kael." },
				{ S = "Kael", T = "Era de Ilen, mi segunda al mando. No volvió de Tefra. La nave sí. Ahora es tuya." },
				{ S = "Sorel", T = "Ojalá pudiera ir contigo. En cuanto me quiten la venda, te sigo." },
				{ S = "Kael", T = "Despega, sal de la atmósfera y elige un planeta. Aterriza, mira, aprende y vuelve. Y si algo te dice que te vayas, hazle caso." },
			} },
		},
	}),

	mision({
		Id = "Gue04_OtroMundo",
		Title = "Otro mundo",
		Description = "Un mundo desconocido, con su propio aire y sus propias bestias. La Academia necesita muestras para entender la Grieta.",
		Duration = { 8, 12 },
		Difficulty = 3,
		Type = "Guerrero · Planetas",
		Next = { "Gue05_Ascenso" },
		Rewards = { Money = 1200 },
		Steps = {
			{ Type = "Event", Event = "PlanetGather", Count = 3,
				Text = "Recoge 3 materiales del planeta (mira el panel de la nave) ({count}/{total})" },
			{ Type = "Event", Event = "BeastKilled", Count = 5,
				Text = "Caza 5 bestias (en un planeta o en Valmar) ({count}/{total})" },
		},
		Dialogues = {},
	}),

	mision({
		Id = "Gue05_Ascenso",
		Title = "Guerrero de primera",
		Description = "Vuelves de otro mundo con muestras, heridas y más preguntas que respuestas. En la Academia te están esperando.",
		Duration = { 4, 6 },
		Type = "Guerrero · Rango",
		Moment = "Te nombraron guerrero de primera",
		Rewards = { Money = 2500, Flags = { "GuerreroDePrimera" }, Unflags = { "CadeteAcademia" } }, -- (ya no eres cadete: Cosme y la Saga de la Grieta te buscan)
		Steps = {
			{ Type = "Reach", Place = "Pista", Text = "Vuelve a la Academia", Actors = PISTA },
			{ Type = "Scene", Dialogue = "Ascenso", Actors = PISTA },
		},
		Dialogues = {
			Ascenso = { Lines = {
				{ S = "Kael", T = "Las muestras que trajiste tienen el mismo rastro que la Grieta. Lo que atacó Valmar viene de fuera. Y no ha terminado." },
				{ S = "Kael", T = "Desde hoy eres guerrero de primera. Puedes aceptar misiones en cualquier planeta y en la Grieta. También puedes morir en cualquiera de ellos." },
				{ S = "Brenn", T = "Mi hermano quería este rango. Llévalo bien." },
				{ S = "Sorel", T = "Ya me han quitado la venda. La próxima vez, subo contigo." },
				{ S = "Kael", T = "Hay un tipo en un garaje del centro, Cosme. Lleva meses midiendo cosas en el cielo que nadie más ve. Ve a hablar con él." },
				{ S = "Narrador", T = "Soñabas con ser guerrero espacial. Ahora sabes lo que cuesta. Y aun así, sigues aquí." },
			}, Effects = { Rel = { Kael = 6, Sorel = 4, Brenn = 3 } } },
		},
	}),
}
