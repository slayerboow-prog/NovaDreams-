-- LA RECONQUISTA (17-11-2026, el dueño: «las misiones, muchas de ellas serán en terreno hostil, objetivo recuperar
-- el planeta»). Después de «Guerrero espacial» (Misiones/Guerrero): el capítulo Reconquista_Valmar de
-- shared/LifeStory/Chapters. El asentamiento (el Distrito Central, con su empalizada: World/Kit/Settlement) sale a
-- recuperar la tierra perdida, zona a zona. Cada misión se juega FUERA de la empalizada: las bestias cuentan solo
-- en su zona (Match = { Region = … }: BeastService manda la zona de la guarida en «BeastKilled»).
--   1. La primera baliza: el Oeste (nv. 1-8) y una baliza de vigilancia en la torre de radio.
--   2. Agua para el asentamiento: el Sur y la depuradora del puerto viejo.
--   3. El paso del pantano: el Este y el Pantano Maldito, al otro lado del paso de tierra.
--   4. El campus de los caídos: el campus abandonado, donde aguantó el último refugio.
--   5. La primera bandera: derribar al Guardián Ancestral del Bosque Etéreo. La primera tierra recuperada.
-- Tono: público de 17+, maduro y sin gore (memoria tono-historia).

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
		Description = "Para recuperar la tierra hay que verla. La vieja torre de radio del Oeste puede volver a vigilar, si alguien limpia lo que vive a sus pies.",
		Duration = { 10, 14 },
		Type = "Reconquista · Oeste",
		Next = { "Rec02_Agua" },
		Rewards = { Money = 1500 },
		Steps = {
			{ Type = "Scene", Dialogue = "Plan", Actors = PISTA },
			{ Type = "Event", Event = "BeastKilled", Count = 12, Match = { Region = "Farm_Oeste" },
				Text = "Sal por la puerta oeste de la empalizada y limpia la Caza del Oeste: 12 bestias ({count}/{total})" },
			{ Type = "Talk", Npc = "Brenn", Dialogue = "Baliza", Text = "Vuelve a la Academia: Brenn ha encendido la baliza", Actors = PISTA },
		},
		Dialogues = {
			Plan = { Lines = {
				{ S = "Kael", T = "Dos años encerrados detrás de una empalizada de chatarra. Se acabó esconderse." },
				{ S = "Kael", T = "El consejo del asentamiento ha aprobado la Reconquista. Zona a zona. Sin prisa y sin muertos tontos." },
				{ S = "Brenn", T = "La torre de radio del Oeste sigue en pie. Si la limpiamos, puedo montar una baliza y ver venir a las manadas antes de que lleguen a la muralla." },
				{ S = "Sorel", T = "Las casas de esa zona siguen ahí. Medio caídas. Algunas con la mesa puesta. Nadie volvió a recoger nada." },
			} },
			Baliza = { Lines = {
				{ S = "Brenn", T = "Baliza encendida. Desde la torre se ve hasta la costa. Y se ve otra cosa: rastros. Muchos. Vienen del sur." },
				{ S = "Kael", T = "Primera zona vigilada en dos años. Apúntalo, guerrero. Es el primer metro que le quitamos a la Caída." },
			}, Effects = { Rel = { Brenn = 3, Kael = 2 } } },
		},
	}),

	mision({
		Id = "Rec02_Agua",
		Title = "Agua para el asentamiento",
		Description = "Los depósitos del asentamiento bajan cada semana. La depuradora del puerto viejo está en el Sur, en mitad de las manadas.",
		Duration = { 12, 16 },
		Type = "Reconquista · Sur",
		Next = { "Rec03_Pantano" },
		Rewards = { Money = 2000 },
		Steps = {
			{ Type = "Scene", Dialogue = "Sed", Actors = PISTA },
			{ Type = "Event", Event = "BeastKilled", Count = 18, Match = { Region = "Farm_Sur" },
				Text = "Despeja la Caza del Sur hasta el puerto viejo: 18 bestias ({count}/{total})" },
			{ Type = "Talk", Npc = "Sorel", Dialogue = "Depuradora", Text = "Vuelve con Sorel a la Academia", Actors = PISTA },
		},
		Dialogues = {
			Sed = { Lines = {
				{ S = "Narrador", T = "En el patio del asentamiento la cola del pozo da la vuelta a la manzana. La gente lleva cubos de pintura, bidones, cazuelas." },
				{ S = "Sorel", T = "Racionan el agua a dos litros por persona. Hay niños que no se han lavado en una semana." },
				{ S = "Kael", T = "La depuradora del puerto funciona si alguien llega hasta ella. Los rastros que vio Brenn van justo hacia allí." },
			} },
			Depuradora = { Lines = {
				{ S = "Sorel", T = "Los ingenieros dicen que la depuradora aguanta. Agua para todos, si mantenemos el Sur limpio." },
				{ S = "Sorel", T = "Una señora me ha dado las gracias llorando. Por agua. Por algo que antes salía del grifo." },
				{ S = "Kael", T = "Dos zonas. El asentamiento ya no es una jaula: es una base." },
			}, Effects = { Rel = { Sorel = 4, Kael = 2 } } },
		},
	}),

	mision({
		Id = "Rec03_Pantano",
		Title = "El paso del pantano",
		Description = "Al este, el paso de tierra lleva a las Tierras Exteriores. Al otro lado espera el Pantano Maldito, y lo que baja de él cada noche.",
		Duration = { 14, 20 },
		Difficulty = 4,
		Type = "Reconquista · Este",
		Next = { "Rec04_Campus" },
		Rewards = { Money = 2800 },
		Steps = {
			{ Type = "Scene", Dialogue = "Paso", Actors = PISTA },
			{ Type = "Event", Event = "BeastKilled", Count = 15, Match = { Region = "Farm_Este" },
				Text = "Abre camino por la Caza del Este hasta el paso de tierra: 15 bestias ({count}/{total})" },
			{ Type = "Event", Event = "BeastKilled", Count = 10, Match = { Region = "PantanoMaldito" },
				Text = "Cruza el paso y caza 10 bestias en el Pantano Maldito ({count}/{total})" },
			{ Type = "Talk", Npc = "Kael", Dialogue = "Vuelta", Text = "Vuelve a la Academia a dar el parte", Actors = PISTA },
		},
		Dialogues = {
			Paso = { Lines = {
				{ S = "Kael", T = "Antes había un mar entre la isla y las tierras de fuera. La Caída lo secó en una noche. Ahora hay barro, y caminos de tierra que nadie ha pisado." },
				{ S = "Brenn", T = "Cada noche algo sube del pantano por el paso del este. Si cerramos el paso, cerramos la puerta." },
				{ S = "Kael", T = "Esto ya no son los distritos. Son las Tierras Exteriores. Si ves algo con más nivel que tú, vuelve. Es una orden." },
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
		Duration = { 14, 20 },
		Difficulty = 4,
		Type = "Reconquista · Campus",
		Next = { "Rec05_Bandera" },
		Rewards = { Money = 3200 },
		Steps = {
			{ Type = "Scene", Dialogue = "Refugio", Actors = PISTA },
			{ Type = "Event", Event = "BeastKilled", Count = 22, Match = { Region = "Farm_Universitario" },
				Text = "Limpia la Caza del Campus: 22 bestias ({count}/{total})" },
			{ Type = "Talk", Npc = "Sorel", Dialogue = "Nombres", Text = "Vuelve con Sorel a la Academia", Actors = PISTA },
		},
		Dialogues = {
			Refugio = { Lines = {
				{ S = "Sorel", T = "Mis padres estaban en el campus aquella noche. No sé si llegaron. Nunca lo he querido saber." },
				{ S = "Kael", T = "No tienes que venir." },
				{ S = "Sorel", T = "Sí tengo. Si no voy ahora, no iré nunca." },
			} },
			Nombres = { Lines = {
				{ S = "Narrador", T = "En la pared del gimnasio del campus hay nombres escritos a mano. Cientos. Los que esperaban dentro los fueron apuntando." },
				{ S = "Sorel", T = "Estaban. Los dos. Escribieron su nombre y debajo el mío. Me estaban esperando." },
				{ S = "Sorel", T = "Vamos a recuperar todo esto. Por ellos. Por todos los que escribieron su nombre en una pared." },
			}, Effects = { Rel = { Sorel = 8 } } },
		},
	}),

	mision({
		Id = "Rec05_Bandera",
		Title = "La primera bandera",
		Description = "En el Bosque Etéreo vive lo que manda sobre las manadas del norte. Si cae, el norte es nuestro.",
		Duration = { 15, 25 },
		Difficulty = 5,
		Type = "Reconquista · Jefe",
		Moment = "Plantaste la primera bandera de la Reconquista",
		Rewards = { Money = 6000, Flags = { "Reconquista1" } },
		Steps = {
			{ Type = "Scene", Dialogue = "Norte", Actors = PISTA },
			{ Type = "Event", Event = "BeastKilled", Count = 15, Match = { Region = "BosqueEtereo" },
				Text = "Entra en el Bosque Etéreo (al norte, por el paso) y abre camino: 15 bestias ({count}/{total})" },
			{ Type = "Event", Event = "BeastKilled", Count = 1, Match = { Species = "GuardianAncestral" },
				Text = "Derriba al Guardián Ancestral, el jefe del Bosque Etéreo" },
			{ Type = "Talk", Npc = "Kael", Dialogue = "Bandera", Text = "Vuelve a la Academia", Actors = PISTA },
		},
		Dialogues = {
			Norte = { Lines = {
				{ S = "Kael", T = "Las balizas lo confirman: las manadas del norte se mueven juntas. Algo las dirige desde el bosque." },
				{ S = "Brenn", T = "Los viejos lo llaman el Guardián. Es más antiguo que la Caída. La Grieta solo lo despertó." },
				{ S = "Kael", T = "Necesito a alguien que llegue hasta él y vuelva. Te necesito a ti." },
			} },
			Bandera = { Lines = {
				{ S = "Narrador", T = "Esa noche, en lo alto de la torre de radio del Oeste, ondea una bandera nueva: una estrella partida atravesada por una espada." },
				{ S = "Kael", T = "El norte es nuestro. La primera tierra recuperada desde la Caída." },
				{ S = "Sorel", T = "Queda todo lo demás. Siete regiones más. Y el cielo." },
				{ S = "Brenn", T = "Pues una a una. Como hasta ahora." },
				{ S = "Narrador", T = "La Reconquista ha empezado. Valmar ya no se esconde: avanza." },
			}, Effects = { Rel = { Kael = 6, Sorel = 4, Brenn = 4 } } },
		},
	}),
}
