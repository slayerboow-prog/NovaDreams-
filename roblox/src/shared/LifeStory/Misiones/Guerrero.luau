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
		Description = "Ya llevas el uniforme. Las bestias de los distritos de caza se acercan cada noche a las calles del centro: toca empujarlas hacia fuera.",
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
				{ S = "Kael", T = "Guerrero {nombre}. Suena bien, ¿eh? Pues se acabó la ceremonia." },
				{ S = "Kael", T = "Anoche una manada llegó hasta la Ronda. Quiero los distritos del Oeste y del Sur limpios antes de que anochezca." },
				{ S = "Brenn", T = "Yo cubro el norte del centro. Si ves algo con más dientes que tú, no te hagas el héroe: llama." },
			} },
			Parte = { Lines = {
				{ S = "Kael", T = "Ocho bestias y ni un rasguño en las calles. Así se patrulla." },
				{ S = "Sorel", T = "Yo me he perdido dos veces. Pero he vuelto. Eso cuenta, ¿no?" },
				{ S = "Kael", T = "Cuenta. Mañana, más lejos: el Este y el campus abandonado. Ahí ya no son cachorros." },
			}, Effects = { Rel = { Kael = 3 } } },
		},
	}),

	mision({
		Id = "Gue02_MasLejos",
		Title = "Más allá de la Ronda",
		Description = "El campus abandonado y las playas del Este: bestias de más nivel, en grupo. Ve con todo lo que te enseñó la Academia.",
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
				{ S = "Kael", T = "En el campus abandonado hay osos que antes eran de peluche en las vitrinas. Es broma. Son peores." },
				{ S = "Kael", T = "Usa la Furia antes de entrar y guarda la Coraza para cuando te rodeen. El espíritu no es infinito." },
				{ S = "Sorel", T = "Voy contigo hasta la Ronda. Luego… luego ya veré." },
			} },
			Vuelta = { Lines = {
				{ S = "Kael", T = "Quince. En el Este. Sola o solo, sin pedir ayuda. Me han llegado tres llamadas preguntando quién eras." },
				{ S = "Brenn", T = "Dos eran mías." },
				{ S = "Kael", T = "Ha llegado el momento. Ve al puerto espacial: tu nave está lista. Hay mundos ahí arriba que necesitan guerreros." },
			}, Effects = { Rel = { Kael = 4, Brenn = 3 } } },
		},
	}),

	mision({
		Id = "Gue03_Despegue",
		Title = "El primer despegue",
		Description = "Toda la vida mirando las naves desde abajo. Hoy subes a la tuya.",
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
				{ S = "Narrador", T = "En la plataforma hay una nave con tu nombre pintado en el costado. Mal escrito. Alguien lo ha corregido con rotulador." },
				{ S = "Sorel", T = "¡Fui yo! Ponía «Guerrera». O «Guerrero». No me acordaba. Bueno, ya está bien." },
				{ S = "Kael", T = "Despega, sal de la atmósfera y elige un planeta. El que quieras. Aterriza, mira a tu alrededor y vuelve con vida." },
				{ S = "Kael", T = "La primera vez que yo vi Valmar desde arriba, lloré. No se lo digas a nadie." },
			} },
		},
	}),

	mision({
		Id = "Gue04_OtroMundo",
		Title = "Otro mundo",
		Description = "Estás en un planeta que nadie de tu barrio ha pisado. La Academia necesita muestras: recoge material y aguanta lo que te eche.",
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
		Description = "Vuelves de tu primer planeta con las botas llenas de polvo de otro mundo. En la Academia te están esperando.",
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
				{ S = "Kael", T = "Has patrullado, has cazado lejos y has pisado otro mundo. Casi nadie lo hace en su primer año." },
				{ S = "Kael", T = "Desde hoy eres guerrero de primera. Puedes aceptar misiones de cualquier planeta y de la Grieta." },
				{ S = "Brenn", T = "Y yo sigo de segunda. La vida es injusta. Enhorabuena, de verdad." },
				{ S = "Sorel", T = "Algún día iremos juntos a Tefra. O a Nivalis. ¡O a todos!" },
				{ S = "Kael", T = "Cosme, el del garaje, lleva días preguntando por ti. Dice que hay algo raro en el cielo. Escúchale: casi nunca se equivoca." },
				{ S = "Narrador", T = "Tu sueño era ser guerrero espacial. Ya lo eres. Ahora empieza lo difícil: ser uno de los buenos." },
			}, Effects = { Rel = { Kael = 6, Sorel = 4, Brenn = 3 } } },
		},
	}),
}
