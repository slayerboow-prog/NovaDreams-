-- METRO DE VALMAR · SECUNDARIAS (se juegan viajando de verdad en el metro: billete o abono, torno,
-- andén, tren, transbordo y bajar en la estación buena). Sistema del metro: Shared/Metro.luau.
--
--   MetroS_PrimerDiaUni  «Primer día de universidad (en metro)»  de casa al campus antes de las 8:30
--   MetroS_Cartera       «He perdido la cartera»                  el último tren, el andén y Objetos Perdidos
--   MetroS_PrimerTrabajo «Primer trabajo, en transporte público»  ir a trabajar en metro y hacer el turno

local V = Vector3.new

return {
	---------------------------------------------------------------------
	-- Primer día de universidad (en metro)
	---------------------------------------------------------------------
	{
		Id = "MetroS_PrimerDiaUni",
		Kind = "Side",
		Title = "Primer día de universidad (en metro)",
		Description = "Clase a primera hora en el campus y el autobús va a reventar. Toca estrenarse en el metro: billete, línea, transbordo… y llegar antes de las 8:30.",
		Type = "Universidad · Transporte",
		Duration = { 8, 12 },
		Npcs = { "Familia", "Luca" },
		Offer = { Place = "CasaFamiliar" },
		OfferKey = "Mañana hay clase a las 8:30 en el campus. ¿Y si vas en metro?",
		Requires = { Stage = { Min = "AdultoJoven", Max = "AdultoJoven" }, Flags = { "VaALaUniversidad" }, Hours = { From = 6, To = 8 } },
		Schedule = false, -- empieza en casa, antes de que abra el campus (a las 8)
		Moment = "Fuiste por primera vez a la universidad en metro",
		Memory = "MetroPrimerDia",
		Rewards = { Money = 20 },
		Steps = {
			{ Type = "Scene", Dialogue = "Salir", Actors = { { Npc = "Familia", Place = "CasaFamiliar", Offset = V(2, 0, 3) } } },
			{ Type = "Reach", Place = "MetroBoca", Text = "Ve andando hasta la boca de metro más cercana (mira el plano en la app 🚇 Metro del móvil)" },
			{ Type = "Event", Event = "MetroGate", Place = "MetroBoca", Text = "Compra un billete o un abono en las máquinas y pasa el torno" },
			{ Type = "Event", Event = "RodeMetro", Match = { Station = "Campus" }, Place = "MetroCampus", Text = "Coge el metro hasta la estación Campus (Línea 1; si vienes de la Línea 2, transbordo en Plaza Mayor)" },
			{ Type = "Reach", Place = "Universidad", Text = "Sal a la calle y llega a la facultad (¡antes de las 8:30!)" },
			{ Type = "Scene", Dialogue = "Puntual", If = { Hours = { From = 5, To = 8.5 } }, Actors = { { Npc = "Luca", Place = "Universidad", Offset = V(2, 0, 4) } } },
			{ Type = "Scene", Dialogue = "Tarde", If = { Hours = { From = 8.5, To = 5 } }, Actors = { { Npc = "Luca", Place = "Universidad", Offset = V(2, 0, 4) } } },
		},
		Dialogues = {
			Salir = { Lines = {
				{ S = "Familia", T = "¿Ya te vas? ¿Mochila? ¿Llaves? ¿Móvil? ¿Bocadillo? …Vale, el bocadillo es cosa mía." },
				{ S = "Yo", T = "El autobús al campus va lleno hasta el techo. Hoy me estreno en el metro." },
				{ S = "Familia", T = "Pues mira la app 🚇 Metro del móvil: te dice la estación más cercana, la ruta y cuándo pasa el próximo tren. ¡Y escríbeme al llegar!" },
			} },
			Puntual = { Lines = {
				{ S = "Luca", T = "¡Bienvenid{o/a}! ¿En metro? Bravissimo. Los del coche siguen dando vueltas buscando aparcamiento." },
				{ S = "Yo", T = "Ni atascos ni aparcamiento. Me lo apunto para todos los días." },
			} },
			Tarde = { Lines = {
				{ S = "Luca", T = "Ehi, la clase ya ha empezado. Entra por la puerta de atrás, piano piano. Nadie se entera." },
				{ S = "Yo", T = "La próxima vez miro antes el panel del próximo tren. En hora punta pasan más a menudo." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- He perdido la cartera
	---------------------------------------------------------------------
	{
		Id = "MetroS_Cartera",
		Kind = "Side",
		Title = "He perdido la cartera",
		Description = "Al salir del metro te das cuenta: no tienes la cartera. La última vez la tenías en el andén de Levante… ¿o era en el tren?",
		Type = "Metro · Imprevistos",
		Duration = { 8, 12 },
		Npcs = { "Funcionaria" },
		Offer = { Place = "MetroBoca" },
		OfferKey = "Te palpas los bolsillos… ¿Y la cartera?",
		Requires = { Stage = { Min = "Adolescente", Max = "Mayor" } },
		Moment = "Recuperaste tu cartera en el metro",
		Memory = "MetroCartera",
		Rewards = { Money = 35 },
		Props = {
			Banco = { Kind = "Asiento", Name = "El banco del andén de Levante", Prompt = "Mirar debajo del banco", Place = "MetroAndenLevante", Offset = V(3, 0, 6), Dialogue = "Banco", Once = true },
			Panel = { Kind = "Pantalla", Name = "El panel del próximo tren", Prompt = "Mirar a qué hora pasó el último tren", Place = "MetroAndenLevante", Offset = V(-2, 0, -4), Dialogue = "Panel", Once = true },
			Ventanilla = { Kind = "Kiosco", Name = "Ventanilla de Objetos Perdidos", Prompt = "Preguntar por la cartera", Place = "MetroObjetosPerdidos", Offset = V(0, 0, 3), Dialogue = "Ventanilla", Once = true },
		},
		Steps = {
			{ Type = "Scene", Dialogue = "Sin" },
			{ Type = "Event", Event = "RodeMetro", Match = { Station = "Levante" }, Place = "MetroAndenLevante", Text = "Vuelve en metro a Levante, la estación donde la tenías" },
			{ Type = "Group", Text = "Busca pistas en el andén de Levante",
				Steps = {
					{ Type = "Use", Prop = "Banco", Text = "El banco del andén" },
					{ Type = "Use", Prop = "Panel", Text = "El panel del próximo tren" },
				} },
			{ Type = "Event", Event = "RodeMetro", Match = { Station = "PlazaMayor" }, Place = "MetroObjetosPerdidos", Text = "Ve en metro a Plaza Mayor: allí está Objetos Perdidos" },
			{ Type = "Use", Prop = "Ventanilla", Text = "Pregunta en Objetos Perdidos (galería de Plaza Mayor)",
				Actors = { { Npc = "Funcionaria", Place = "MetroObjetosPerdidos", Offset = V(1.5, 0, 3) } } },
			{ Type = "Scene", Dialogue = "Final", Actors = { { Npc = "Funcionaria", Place = "MetroObjetosPerdidos", Offset = V(1.5, 0, 3) } } },
		},
		Dialogues = {
			Sin = { Lines = {
				{ S = "Yo", T = "Bolsillo izquierdo: nada. Derecho: un chicle. Mochila: un calcetín suelto. …¿Y la cartera?" },
				{ S = "Yo", T = "A ver. En el andén de Levante la tenía: saqué el abono. Después subí al tren…" },
			} },
			Banco = { Lines = {
				{ S = "Yo", T = "Debajo del banco: un billete usado, una pinza del pelo y… la marca de algo rectangular en el polvo. Alguien la ha recogido." },
			} },
			Panel = { Lines = {
				{ S = "Yo", T = "El último tren hacia Plaza Mayor pasó justo cuando salí. Si alguien la encontró en el andén o en el vagón, estará en Objetos Perdidos." },
			} },
			Ventanilla = { Lines = {
				{ S = "Funcionaria", T = "¿Una cartera? Nos ha llegado una esta mañana. La trajo un señor muy mayor; dijo que la vio en el andén de Levante." },
				{ S = "Funcionaria", T = "Firme aquí. Y aquí. Y aquí no, que es otro impreso. …Tome. Con todo dentro. Y una nota." },
				{ S = "Yo", T = "«Para la próxima, cremallera. Buen viaje.»" },
			} },
			Final = { Lines = {
				{ S = "Yo", T = "Todo dentro. Y unas monedas de más, «por las molestias». Hay gente buena hasta en hora punta." },
				{ S = "Funcionaria", T = "Siguiente, por favor. …Ah, no, que no hay nadie. Qué día más raro." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Primer trabajo, en transporte público
	---------------------------------------------------------------------
	{
		Id = "MetroS_PrimerTrabajo",
		Kind = "Side",
		Title = "Primer trabajo, en transporte público",
		Description = "Tienes trabajo y no tienes coche. Hoy vas al curro en metro, como media Valmar: billete, torno, tren… y a trabajar.",
		Type = "Trabajo · Transporte",
		Duration = { 8, 12 },
		Npcs = {},
		Offer = { Place = "MetroBoca" },
		OfferKey = "Un cartel en la boca de metro: «Abono trabajador: viaja sin límites»",
		Requires = { Stage = { Min = "AdultoJoven", Max = "Adulto" } },
		Moment = "Fuiste a trabajar en metro por primera vez",
		Memory = "MetroTrabajo",
		Rewards = { Money = 25 },
		Steps = {
			{ Type = "Scene", Dialogue = "Cartel" },
			{ Type = "Event", Event = "MetroGate", Place = "MetroBoca", Text = "Entra en el metro (billete, bonometro o abono trabajador) y pasa el torno" },
			{ Type = "Event", Event = "RodeMetro", Place = "MetroBoca", Text = "Viaja en metro hasta la estación más cercana a tu trabajo y baja" },
			{ Type = "Event", Event = "JobTaskDone", Text = "Ya en el trabajo: empieza el turno (tablón de trabajo o app del móvil) y haz una tarea" },
			{ Type = "Scene", Dialogue = "Final" },
		},
		Dialogues = {
			Cartel = { Lines = {
				{ S = "Yo", T = "«Abono trabajador: viaja sin límites todo el mes». Más barato que el coche. Y sin aparcar." },
				{ S = "Yo", T = "La app 🚇 Metro me dice qué línea coger y cuánto tardo. Hoy, al trabajo en metro." },
			} },
			Final = { Lines = {
				{ S = "Yo", T = "Sin atascos, leyendo en el vagón y con tiempo para un café. A esto me puedo acostumbrar." },
			} },
		},
	},
}
