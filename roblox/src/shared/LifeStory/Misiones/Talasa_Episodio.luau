-- SAGA 2 «RAGNAROCK» · TÁLASA · «MAREA NEGRA», la primera parte jugable (≈ 30 min; docs/planetas/
-- talasa-vertice.md, diseño en docs/planetas/diseno-mundos.md §3.3.16). Misiones CANÓNICAS: su marca dorada
-- sale en Abisalia y empiezan solas al llegar al sitio. Solo en Tálasa (Requires.Planet).
--
--   1 Talasa_01_Llegada  «Agua por todas partes»  llegas, las tres lunas, la cuarentena de la Almirante Coria
--   2 Talasa_02_Marea    «La marea»               un turno de técnico/a de presión y la tormenta: Bruma
--   3 Talasa_03_Muestras «Muestras»               la voluntaria Noa, bucear a por tres muestras de coral negro
--   4 Talasa_04_Bruma    «Bruma»                  ¿ayudas a Bruma a llevarse una barca o avisas a la patrulla?
--                                                 los cangrejos de coral atacan el Muelle
--   5 Talasa_05_Senal    «La señal de la Cúpula»  el sónar oye a Elio; el cuaderno de Noa; el gancho del episodio
--
-- Las frases son del guion (docs/historia/reescritura/Talasa_0*.md → Guiones/, nunca a mano): aquí solo
-- queda una frase de respaldo por conversación. 13+: sin sangre; el coral negro «se deshace en arena».

local V = Vector3.new

local TIPO = "Saga 2 · Tálasa · «Marea negra»"

local function after(id: string?): { [string]: any }
	local req: { [string]: any } = { Stage = { Min = "Adulto" }, Planet = "Talasa" }
	if id then
		req.Completed = { id }
	end
	return req
end

local function at(npc: string, place: string, x: number, z: number, mode: string?): { [string]: any }
	return { Npc = npc, Place = place, Offset = V(x, 0, z), Mode = mode }
end
local COSME_SIGUE = { Npc = "Cosme", Mode = "Follow" }

local function respaldo(s: string, t: string): { [string]: any }
	return { Lines = { { S = s, T = t } } }
end

return {
	---------------------------------------------------------------------
	-- 1 · Agua por todas partes
	---------------------------------------------------------------------
	{
		Id = "Talasa_01_Llegada",
		Kind = "Side",
		Canon = true,
		Title = "Agua por todas partes",
		Description = "Has llegado a Tálasa, el planeta océano. Su capital, Abisalia, flota sobre pilotes en mitad del mar. Desde la nave ya se ve que algo va mal: hay cintas de cuarentena hasta en el faro.",
		Type = TIPO .. " (1/5)",
		Duration = { 5, 8 },
		Npcs = { "Cosme", "AlmiranteCoria" },
		Offer = { Place = "Talasa_Plataforma" },
		OfferKey = "Abisalia, sobre el mar. Hay cintas de cuarentena hasta en el faro",
		Requires = after(nil),
		Moment = "Llegaste a Abisalia, la ciudad sobre el mar de Tálasa",
		Memory = "LlegadaTalasa",
		Rewards = { Money = 60, Flags = { "TalasaLlegado" }, Items = { Talasa_TrajePresion1 = 1, Talasa_CargaOxigeno = 3, Talasa_PermisoBuceo = 1 } },
		Steps = {
			{ Type = "Cinematic", Id = "Talasa_Llegada", Actors = { at("Cosme", "Talasa_Plataforma", 3, 2) } },
			{ Type = "Talk", Npc = "Cosme", Dialogue = "Llegada", Text = "Habla con Cosme en la plataforma", Actors = { at("Cosme", "Talasa_Plataforma", 3, 2) } },
			{ Type = "Reach", Place = "Talasa_Plaza", Text = "Cruza la pasarela hasta la Plaza de las Pecas", Actors = { COSME_SIGUE } },
			{ Type = "Talk", Npc = "AlmiranteCoria", Dialogue = "Cuarentena", Text = "La Almirante Coria te espera a los pies del Faro de Mareas",
				Actors = { at("AlmiranteCoria", "Talasa_Faro", 0, -3), at("Cosme", "Talasa_Faro", 4, 2), at("PatrullaConsejo1", "Talasa_Faro", -5, 1) } },
		},
		Dialogues = {
			Llegada = respaldo("Cosme", "Tálasa. El planeta más rico de la galaxia. Y huele a miedo."),
			Cuarentena = respaldo("AlmiranteCoria", "Abisalia está en cuarentena. Tomad: traje, oxígeno y un permiso hasta −40 metros."),
		},
	},

	---------------------------------------------------------------------
	-- 2 · La marea
	---------------------------------------------------------------------
	{
		Id = "Talasa_02_Marea",
		Kind = "Side",
		Canon = true,
		Title = "La marea",
		Description = "En Abisalia la marea sube y baja cada pocos minutos y las compuertas aguantan la ciudad. Faltan manos: casi todos los técnicos están atrapados abajo, en la Cúpula Honda.",
		Type = TIPO .. " (2/5)",
		Duration = { 6, 9 },
		Npcs = { "Cosme", "Bruma" },
		Offer = { Place = "Talasa_Fuente" },
		OfferKey = "Cosme mira la tabla de mareas. Faltan técnicos en las compuertas",
		Requires = after("Talasa_01_Llegada"),
		Moment = "Ajustaste las válvulas de Abisalia y conociste a Bruma en plena tormenta",
		Memory = "MareaTalasa",
		Rewards = { Money = 70, Flags = { "TalasaConoceBruma" } },
		Steps = {
			{ Type = "Talk", Npc = "Cosme", Dialogue = "Tabla", Text = "Cosme te espera junto a la Fuente de las Perlas", Actors = { at("Cosme", "Talasa_Fuente", 0, 3) } },
			{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "TalasaTecnicoPresion" }, Place = "Talasa_Faro",
				Text = "Haz un turno de 🔧 técnico/a de presión (tablón junto al Faro): ajusta dos válvulas antes de que cambie la marea" },
			{ Type = "Reach", Place = "Talasa_CompuertaFaro", Text = "⛈ ¡Viene la tormenta eléctrica! Métete en la Compuerta del Faro", Actors = { COSME_SIGUE } },
			{ Type = "Scene", Dialogue = "Tormenta",
				Actors = { at("Bruma", "Talasa_CompuertaFaro", -1, 3), at("Cosme", "Talasa_CompuertaFaro", -3, -2) } },
		},
		Dialogues = {
			Tabla = respaldo("Cosme", "Faltan técnicos en las compuertas. Echa una mano, criatura."),
			Tormenta = respaldo("Bruma", "Bruma. Buceadora. Bueno, era buceadora. Ahora espero."),
		},
	},

	---------------------------------------------------------------------
	-- 3 · Muestras
	---------------------------------------------------------------------
	{
		Id = "Talasa_03_Muestras",
		Kind = "Side",
		Canon = true,
		Title = "Muestras",
		Description = "En la Estación Meridiana una voluntaria trabaja sola de noche. Necesita muestras frescas del coral negro, y el coral negro empieza justo debajo de la ciudad.",
		Type = TIPO .. " (3/5)",
		Duration = { 8, 12 },
		Npcs = { "NoaFerran", "Cosme" },
		Offer = { Place = "Talasa_Estacion" },
		OfferKey = "En la puerta de la Estación, una voluntaria con la bata llena de manchas negras",
		Requires = after("Talasa_02_Marea"),
		Moment = "Buceaste en las Praderas de Luz a por el coral negro",
		Memory = "MuestrasTalasa",
		Rewards = { Money = 110, Items = { Talasa_Nacar = 2, Talasa_MuestraCoral = 3 } },
		Steps = {
			{ Type = "Talk", Npc = "NoaFerran", Dialogue = "Voluntaria", Text = "Habla con la voluntaria en la puerta de la Estación Meridiana",
				Actors = { at("NoaFerran", "Talasa_Estacion", 0, 3), at("Cosme", "Talasa_Estacion", 4, 4) } },
			{ Type = "Reach", Place = "Talasa_Escalerilla", Text = "Ve a la escalerilla de buceo, al final del Muelle flotante" },
			{ Type = "Group", Text = "Bucea en las Praderas de Luz y toma tres muestras del coral negro (las boyas amarillas marcan dónde)",
				Steps = {
					{ Type = "Event", Event = "PoiDiscovered", Match = { Id = "Talasa_Muestra1" }, Text = "La muestra junto a la primera boya" },
					{ Type = "Event", Event = "PoiDiscovered", Match = { Id = "Talasa_Muestra2" }, Text = "La muestra de la barca hundida" },
					{ Type = "Event", Event = "PoiDiscovered", Match = { Id = "Talasa_Muestra3" }, Text = "La muestra que se encoge con la luz" },
				} },
			{ Type = "Event", Event = "HazardCountered", Match = { Planet = "Talasa" },
				Text = "🌊 La presión aprieta: usa una 🫧 carga de oxígeno de la mochila antes de subir" },
			{ Type = "Talk", Npc = "NoaFerran", Dialogue = "Microscopio", Text = "Lleva las muestras al laboratorio de la Estación",
				Actors = { at("NoaFerran", "Talasa_EstacionDentro", 0, -3), at("Cosme", "Talasa_EstacionDentro", 4, 0) } },
			{ Type = "MiniGame", Game = "Timing", Title = "El microscopio", Icon = "🔬", Hint = "Enfoca la muestra: pulsa cuando la aguja pase por el verde",
				Rounds = 3, Need = 2, Zone = 0.26, Speed = 1,
				Win = { Flags = { "TalasaMuestrasBien" } }, Lose = { Flags = { "TalasaMuestrasRegular" } },
				Actors = { at("NoaFerran", "Talasa_EstacionDentro", 0, -3) } },
			{ Type = "Scene", Dialogue = "Resultado",
				Actors = { at("NoaFerran", "Talasa_EstacionDentro", 0, -3), at("Cosme", "Talasa_EstacionDentro", 4, 0) } },
		},
		Dialogues = {
			Voluntaria = respaldo("NoaFerran", "Necesito tres muestras frescas del coral negro. ¿Sabes bucear?"),
			Microscopio = respaldo("NoaFerran", "Déjalas aquí. Con cuidado."),
			Resultado = respaldo("NoaFerran", "Come metal. Y crece hacia la ciudad."),
		},
	},

	---------------------------------------------------------------------
	-- 4 · Bruma
	---------------------------------------------------------------------
	{
		Id = "Talasa_04_Bruma",
		Kind = "Side",
		Canon = true,
		Title = "Bruma",
		Description = "Bruma ha decidido sacar de Abisalia a seis familias de Las Balsas, aunque sea en una barca robada al Consejo. Te pide ayuda. La patrulla también.",
		Type = TIPO .. " (4/5)",
		Duration = { 6, 9 },
		Npcs = { "Bruma", "AlmiranteCoria" },
		Offer = { Place = "Talasa_CasaBruma" },
		OfferKey = "En la balsa de Bruma, una cuerda de perlas y dos bolsas hechas",
		Requires = after("Talasa_03_Muestras"),
		Moment = "Elegiste entre Bruma y el Consejo con los cangrejos de coral subiendo al Muelle",
		Memory = "BrumaTalasa",
		Rewards = { Money = 90 },
		Steps = {
			{ Type = "Talk", Npc = "Bruma", Dialogue = "Plan", Text = "Bruma te espera en su balsa, al norte de Las Balsas", Actors = { at("Bruma", "Talasa_CasaBruma", 0, 3) } },
			{ Type = "Choice", Key = "TalasaBruma", Text = "Bruma quiere llevarse una barca del Consejo para sacar a seis familias de Las Balsas. Si la pillan, la encierran. ¿Qué haces?",
				Options = {
					{ Id = "Ayudar", Text = "Ayudarla: distraer a la patrulla en el Muelle", Effects = { Flags = { "BrumaAyudada" }, Rel = { Bruma = 15 }, Items = { Talasa_PerlaBruma = 1 }, Traits = { Empatia = 1 } } },
					{ Id = "Patrulla", Text = "Avisar a la patrulla: una barca robada no salva a nadie", Effects = { Flags = { "BrumaDelatada" }, Rel = { Bruma = -15, AlmiranteCoria = 10 }, Traits = { Responsabilidad = 1 } } },
				},
				Actors = { at("Bruma", "Talasa_CasaBruma", 0, 3) } },
			{ Type = "Fight", Place = "Talasa_Muelle", Respawn = "Talasa_Muelle", Action = "Apartar 💥", HP = 4,
				Text = "¡Cangrejos de coral negro suben por los pilotes del Muelle! Apártalos ({count}/{total})",
				CaughtLine = "(Un cangrejo te tira de la cubierta. Te subes por la escalerilla, empapado.)",
				Actors = { at("Bruma", "Talasa_Muelle", -6, 4, "Point") },
				Enemies = {
					{ Npc = "CangrejoCoral1", Offset = V(14, 0, -4), Speed = 8, HP = 3, Bye = "(Se deshace en arena negra.)" },
					{ Npc = "CangrejoCoral2", Offset = V(20, 0, 6), Speed = 9, HP = 3, Bye = "(Se deshace en arena negra.)" },
				} },
			{ Type = "Escape", Place = "Talasa_Balsas", Respawn = "Talasa_Muelle", Catch = 4, If = { Choices = { TalasaBruma = "Ayudar" } },
				Text = "Bruma ya tiene la barca: llévate a la patrulla lejos, hasta Las Balsas, sin que te pillen",
				CaughtLine = "¡Alto! ¿Tú otra vez? Al Muelle, y quietecito. (Vuelves al Muelle.)",
				Actors = {
					{ Npc = "PatrullaConsejo1", Place = "Talasa_Muelle", Offset = V(10, 0, -6), Mode = "Hunt", Speed = 10, Prompt = false },
					{ Npc = "PatrullaConsejo2", Place = "Talasa_Plaza", Offset = V(-12, 0, 8), Mode = "Hunt", Speed = 9, Prompt = false },
				} },
			{ Type = "Talk", Npc = "AlmiranteCoria", Dialogue = "Coria", Text = "La Almirante Coria quiere hablar contigo en el Muelle", If = { Choices = { TalasaBruma = "Patrulla" } },
				Actors = { at("AlmiranteCoria", "Talasa_Muelle", 4, -3), at("PatrullaConsejo1", "Talasa_Muelle", 8, 2) } },
			{ Type = "Scene", Dialogue = "Despues",
				Actors = { at("Bruma", "Talasa_Balsas", 0, 3), at("Cosme", "Talasa_Balsas", 3, 1) } },
		},
		Dialogues = {
			Plan = respaldo("Bruma", "Esta noche me llevo una barca. ¿Me ayudas o me miras?"),
			Coria = respaldo("AlmiranteCoria", "Has hecho lo correcto. No lo parece. Casi nunca lo parece."),
			Despues = respaldo("Bruma", "El coral sube ya por los pilotes. No queda tiempo."),
		},
	},

	---------------------------------------------------------------------
	-- 5 · La señal de la Cúpula
	---------------------------------------------------------------------
	{
		Id = "Talasa_05_Senal",
		Kind = "Side",
		Canon = true,
		Title = "La señal de la Cúpula",
		Description = "El sónar de la Estación Meridiana ha captado algo desde la Cúpula Honda, el barrio en cuarentena a −150 metros: alguien sigue vivo ahí abajo. La voluntaria no ha dormido.",
		Type = TIPO .. " (5/5)",
		Duration = { 6, 9 },
		Npcs = { "NoaFerran", "Cosme", "AlmiranteCoria" },
		Offer = { Place = "Talasa_EstacionDentro" },
		OfferKey = "El sónar de la Estación pita. La voluntaria no ha dormido",
		Requires = after("Talasa_04_Bruma"),
		Moment = "Oíste la voz de Elio desde la Cúpula Honda y supiste quién era la voluntaria",
		Memory = "SenalTalasa",
		Rewards = { Money = 140, Flags = { "TalasaPrologoHecho" }, Items = { Talasa_TrajePresion2 = 1, Talasa_CargaOxigeno = 2 } },
		Props = {
			Cuaderno = { Kind = "Papel", Name = "Un cuaderno con manchas negras", Prompt = "Leer el cuaderno", Place = "Talasa_EstacionDentro", Offset = V(-6, 0, 2), Dialogue = "Cuaderno", Once = true,
				Effects = { Items = { Talasa_CuadernoNoa = 1 } } },
		},
		Steps = {
			{ Type = "Talk", Npc = "NoaFerran", Dialogue = "Sonar", Text = "Escucha el sónar con la voluntaria", Actors = { at("NoaFerran", "Talasa_EstacionDentro", 0, -3), at("Cosme", "Talasa_EstacionDentro", 4, 0) } },
			{ Type = "Use", Prop = "Cuaderno", Text = "La voluntaria ha salido corriendo. Ha dejado su cuaderno en la mesa" },
			{ Type = "Choice", Key = "TalasaNoa", Text = "El cuaderno lo firma «Dra. Noa Ferrán», la creadora del coral vivo, la mujer que busca el Consejo. Y Elio es su hijo. ¿Qué haces?",
				Options = {
					{ Id = "Callar", Text = "Guardar su secreto: primero hay que sacar a Elio", Effects = { Flags = { "NoaProtegida" }, Rel = { NoaFerran = 15 }, Traits = { Empatia = 1 } } },
					{ Id = "Contar", Text = "Contárselo a la Almirante Coria: la ciudad tiene derecho a saberlo", Effects = { Flags = { "NoaDelatada" }, Rel = { NoaFerran = -10, AlmiranteCoria = 10 }, Traits = { Responsabilidad = 1 } } },
				},
				Actors = { at("Cosme", "Talasa_EstacionDentro", 4, 0) } },
			{ Type = "Cinematic", Id = "Talasa_Cierre", Actors = { at("NoaFerran", "Talasa_Faro", 3, 2), at("AlmiranteCoria", "Talasa_Faro", -3, 2), at("Cosme", "Talasa_Faro", 0, 5) } },
		},
		Dialogues = {
			Sonar = respaldo("NoaFerran", "Escucha. Eso no es el coral. Es una voz."),
			Cuaderno = respaldo("Narrador", "Un cuaderno de laboratorio con manchas negras. En la primera página, una firma."),
		},
	},
}
