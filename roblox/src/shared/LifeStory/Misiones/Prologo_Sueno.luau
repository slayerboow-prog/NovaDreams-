-- PRÓLOGO · «El sueño» (2-4 min, solo la primera vez; se puede volver a ver desde «Mi historia»).
-- Es el tutorial de los controles contado como historia. La noche en que naces, sueñas con lo que
-- está por venir: ya eres un poco mayor, hay una línea verde en el cielo (la Grieta) y un inventor
-- con bata te espera junto a un garaje. Cada paso enseña un control con una tarjeta de ayuda (Hint):
--   moverse → correr → saltar → hablar (con una decisión) → coger algo → seguir la línea → abrir el mapa
-- Pasa en el «sueño» (una isla pequeña y segura en el cielo, World/Kit/DreamIsland) y después empieza
-- el primer capítulo de verdad (el nacimiento). Lo lanza y lo cierra LifeStoryService (startPrologue).
--
-- Coherencia con la saga (docs/historia/13): Cosme aún no te conoce en la vida real; en el sueño solo
-- dice que «os conoceréis». La Grieta se abrió la noche en que naciste (no se cuenta aún por qué).
--
-- Campos propios de los pasos del prólogo (el resto de misiones no los usa):
--   Beat = "Move" | "Run" | "Jump" | "Talk" | "Use" | "Follow" | "Map"  qué control enseña (atributo PrologueBeat)
--   Hint = { Pc = "…", Touch = "…" }  la tarjeta de ayuda en pantalla (teclado o móvil)

local V = Vector3.new

return {
	Id = "Prologo_Sueno",
	Kind = "Main",
	Prologue = true, -- no está en ningún capítulo: lo lanza LifeStoryService antes del primero
	Title = "Prólogo: el sueño",
	Description = "La noche en que naces, sueñas con lo que está por venir. Aprende a moverte por Valmar… y conoce a alguien que te estaba esperando.",
	Type = "Prólogo",
	Duration = { 2, 4 },
	Npcs = { "Cosme" },
	Memory = "SuenoGrieta",
	Actors = {
		{ Npc = "Cosme", Place = "PrologoCosme" },
	},
	Props = {
		Tornillo = { Kind = "Cristal", Name = "Un tornillo que brilla", Prompt = "Recoger", Place = "PrologoTornillo", Color = Color3.fromRGB(120, 255, 160), Dialogue = "Tornillo", Once = true },
	},
	Steps = {
		{ Type = "Cinematic", Id = "Prologo_Apertura", Teleport = "PrologoInicio" },
		{ Type = "Reach", Place = "PrologoCamino", Beat = "Move", Text = "Camina hasta el círculo de luz",
			Hint = { Pc = "Muévete con W A S D (o con las flechas)", Touch = "Mueve el joystick de abajo a la izquierda" } },
		{ Type = "Event", Event = "Sprinted", Beat = "Run", Text = "¡Corre! Algo brilla al fondo",
			Hint = { Pc = "Mantén pulsado Mayús (Shift) mientras te mueves para correr", Touch = "Empuja el joystick hasta el borde (o pulsa el botón Correr)" } },
		{ Type = "Reach", Place = "PrologoSalto", Beat = "Jump", Text = "Salta la valla de flores",
			Hint = { Pc = "Pulsa Espacio para saltar", Touch = "Pulsa el botón de saltar (abajo a la derecha)" } },
		{ Type = "Talk", Npc = "Cosme", Dialogue = "Sueno", Beat = "Talk", Text = "Habla con el señor de la bata",
			Hint = { Pc = "Acércate a él y pulsa E", Touch = "Acércate a él y toca el botón que aparece" } },
		-- (el tornillo sale al acabar de hablar con Cosme: antes se podía coger antes y el paso se quedaba sin objeto)
		{ Type = "Use", Prop = "Tornillo", Beat = "Use", Text = "Recoge el tornillo que brilla",
			Hint = { Pc = "Acércate y pulsa E", Touch = "Acércate y toca el botón «Recoger»" } },
		{ Type = "Reach", Place = "PrologoPuerta", Beat = "Follow", Text = "Sigue las flechas azules del suelo hasta la puerta del garaje",
			Hint = { Pc = "Las flechas azules del suelo te llevan siempre a donde tienes que ir", Touch = "Las flechas azules del suelo te llevan siempre a donde tienes que ir" } },
		{ Type = "Event", Event = "MapOpened", Beat = "Map", Text = "Abre el mapa de Valmar",
			Hint = { Pc = "Pulsa M para abrir el mapa", Touch = "Toca el mapa redondo de arriba a la derecha (o el botón Mapa)" } },
		{ Type = "Cinematic", Id = "Prologo_Cierre" },
	},
	Dialogues = {
		Sueno = { Lines = {
			{ S = "Narrador", T = "Es un sueño. En el sueño ya no eres un bebé: eres un poco mayor. Y alguien te está esperando." },
			{ S = "Cosme", T = "¡Ah, criatura! Llegas pronto. O tarde. En los sueños nunca se sabe." },
			{ S = "Cosme", T = "Soy Cosme. Inventor. Genio. Vecino. Todavía no nos conocemos… pero nos conoceremos." },
			{ S = "Cosme", T = "¿Ves esa línea verde en el cielo? Se llama la Grieta. No debería estar ahí. Es… culpa mía. Un poco. Bastante.", A = "Sad" },
			{ Ask = "¿Qué le dices?", Options = {
				{ T = "«¡Yo te ayudo a arreglarla!»", Effects = { Traits = { Valentia = 1 }, Choice = { Prologo = "Ayudar" } }, Then = {
					{ S = "Cosme", T = "¿Ayudar? ¿Tú? Qué valiente. Me gusta. Ya verás: en Valmar, lo que eliges cambia tu historia." },
				} },
				{ T = "«¿Y eso es peligroso?»", Effects = { Traits = { Curiosidad = 1 }, Choice = { Prologo = "Preguntar" } }, Then = {
					{ S = "Cosme", T = "Un poco. Buena pregunta. En Valmar, lo que preguntas y lo que eliges cambia tu historia… y cómo te recuerda la gente." },
				} },
			} },
			{ S = "Cosme", T = "Antes de despertar, coge ese tornillo que brilla. Es importante. Creo. Mañana no te acordarás de nada. Bueno, de casi nada." },
		} },
		Tornillo = { Lines = {
			{ S = "Narrador", T = "El tornillo está calentito y zumba como un moscardón feliz. Por un segundo, el cielo parpadea en verde." },
		} },
	},
}
