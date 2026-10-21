-- EL MAR DE LOS HONDARIOS · «LA CANCIÓN DE LO HONDO» · Prólogo y primera parte del Acto I (fase 1,
-- docs/mar/civilizacion-marina.md §5.2, recortada a ~1 h por el dueño). Misiones CANÓNICAS: su marca sale en
-- el mapa y empiezan solas al llegar al sitio; la «vida hondaria» del modo pruebas empieza la primera sola
-- (Services/HondarioService.startStory). Las juegan los humanos (con el equipo de buceo: Nácara está a 37 m) y
-- los Hondarios.
--
--   0 Mar_00_Arrecife  «El niño del arrecife»   algo brilla en el jardín de coral: Ilun atrapado en una red
--   1 Mar_01_Concha    «La concha que canta»    sigues el canto hasta Nácara; Ilun te enseña la ciudad
--   2 Mar_02_Burbuja   «La Burbuja»             la posada de los secos, Bartolo y el primer trueque
--   3 Mar_03_Juicio    «Un seco en Nácara»      la Guardia te lleva ante el Consejo: juicio y tu primer trabajo
--   4 Mar_04_Redes     «Redes cortadas»         persecución por el kelp y una decisión (entregar o dejar ir)
-- Secundarias: Mar_S1_Perlas «Las perlas de Oriana» y Mar_S2_Farolas «La primera noche de Lía».
--
-- Los Hondarios viven en el agua y no son actores de la escena (los pone SeaCivService con su cola): los
-- pasos «Talk» no llevan Actors; «Hablar» con ellos lo lleva SeaCivService (LifeStoryService.interact) y la
-- cámara de la charla los encuentra con LifeStoryService.worldActor. Las frases son del guion:
-- docs/historia/reescritura/Mar_*.md → Guiones/ (scripts/audit/aplicar-reescritura.luau).
-- 13+: sin sangre; nadie se hace daño (la persecución acaba con un «¡te pillé!»).

local V = Vector3.new

local TIPO = "El mar · «La canción de lo hondo»"

local function after(id: string?): { [string]: any }
	local req: { [string]: any } = { Stage = { Min = "Nino" } }
	if id then
		req.Completed = { id }
	end
	return req
end

return {
	---------------------------------------------------------------------
	-- Prólogo · El niño del arrecife
	---------------------------------------------------------------------
	{
		Id = "Mar_00_Arrecife",
		Kind = "Side",
		Canon = true,
		Title = "El niño del arrecife",
		Description = "En el jardín de coral del sur, delante de la playa, algo brilla entre las algas. Y se mueve. Y parece que pide ayuda.",
		Type = TIPO .. " · Prólogo",
		Duration = { 8, 12 },
		Npcs = { "Ilun" },
		Offer = { Place = "Mar_Arrecife" },
		OfferKey = "Algo brilla en el jardín de coral del sur",
		Requires = after(nil),
		Moment = "Soltaste a Ilun de una red vieja y te regaló una concha que canta",
		Memory = "IlunArrecife",
		Rewards = { Money = 60, Flags = { "MarConchaCanta" }, Rel = { Ilun = 10 } },
		Props = {
			Nudo1 = { Kind = "Cristal", Name = "Un nudo de la red vieja", Prompt = "Soltar el nudo", Place = "Mar_Arrecife", Offset = V(-5, 0, 3), Color = Color3.fromRGB(150, 245, 255), Once = true },
			Nudo2 = { Kind = "Cristal", Name = "Otro nudo de la red", Prompt = "Soltar el nudo", Place = "Mar_Arrecife", Offset = V(4, 0, 5), Color = Color3.fromRGB(150, 245, 255), Once = true },
			Nudo3 = { Kind = "Cristal", Name = "El último nudo", Prompt = "Soltar el nudo", Place = "Mar_Arrecife", Offset = V(0, 0, -5), Color = Color3.fromRGB(150, 245, 255), Once = true },
		},
		Steps = {
			{ Type = "Reach", Place = "Mar_Arrecife", Text = "Bucea en el jardín de coral del sur, delante de la playa: algo brilla entre las algas" },
			{ Type = "Group", Text = "Alguien está atrapado en una red vieja: suelta los tres nudos",
				Steps = {
					{ Type = "Use", Prop = "Nudo1", Text = "El nudo de la izquierda" },
					{ Type = "Use", Prop = "Nudo2", Text = "El nudo de la derecha" },
					{ Type = "Use", Prop = "Nudo3", Text = "El nudo del fondo" },
				} },
			{ Type = "Talk", Npc = "Ilun", Dialogue = "Concha", Place = "Mar_Arrecife", Text = "Habla con quien has soltado (está nadando junto a la red)" },
		},
		Dialogues = {
			Concha = { Lines = { { S = "Ilun", T = "¡Gracias!", To = "Yo" } } },
		},
	},

	---------------------------------------------------------------------
	-- Acto I · 1 · La concha que canta
	---------------------------------------------------------------------
	{
		Id = "Mar_01_Concha",
		Kind = "Side",
		Canon = true,
		Title = "La concha que canta",
		Description = "La concha de Ilun canta cuando bajas. Es una llamada. Viene de lo hondo, de la Llanura Sumergida, donde nadie de Valmar ha estado nunca. (Nácara está a 37 m: hace falta el equipo de buceo de la tienda de pesca.)",
		Type = TIPO .. " · Acto I (1/4)",
		Duration = { 12, 18 },
		Npcs = { "Ilun" },
		Offer = { Place = "Mar_Arrecife" },
		OfferKey = "La concha que te dio Ilun empieza a cantar",
		Requires = after("Mar_00_Arrecife"),
		Moment = "Llegaste a Nácara, la ciudad de los Hondarios",
		Memory = "LlegadaNacara",
		Rewards = { Money = 80, Flags = { "MarConoceNacara" }, Rel = { Ilun = 10 } },
		Steps = {
			{ Type = "Reach", Place = "Mar_Ruinas", Text = "Sigue el canto de la concha: las perlas de guía cian llevan a las Ruinas de Valmar la Vieja (37 m: equipo de buceo)" },
			{ Type = "Reach", Place = "Mar_Arco", Text = "El canto sigue hacia el sur, por la Llanura Sumergida: llega al arco de kelp" },
			{ Type = "Talk", Npc = "Ilun", Dialogue = "Plaza", Place = "Mar_Plaza", Text = "Ilun te espera junto a la fuente de la Plaza de la Corriente" },
			{ Type = "Group", Text = "Ilun te enseña Nácara a escondidas",
				Steps = {
					{ Type = "Reach", Place = "Mar_Conchas", Text = "El Barrio de las Conchas (al oeste)" },
					{ Type = "Reach", Place = "Mar_Jardines", Text = "Los Jardines de Cultivo (al este)" },
				} },
			{ Type = "Talk", Npc = "Ilun", Dialogue = "Secreto", Place = "Mar_Plaza", Text = "Vuelve con Ilun a la plaza" },
		},
		Dialogues = {
			Plaza = { Lines = { { S = "Ilun", T = "¡Has venido!", To = "Yo" } } },
			Secreto = { Lines = { { S = "Ilun", T = "No se lo digas a nadie.", To = "Yo" } } },
		},
	},

	---------------------------------------------------------------------
	-- Acto I · 2 · La Burbuja
	---------------------------------------------------------------------
	{
		Id = "Mar_02_Burbuja",
		Kind = "Side",
		Canon = true,
		Title = "La Burbuja",
		Description = "Los secos no pueden quedarse mucho en Nácara sin aire. Oriana sabe de un sitio en el talud donde los humanos respiran y duermen: la posada de La Burbuja.",
		Type = TIPO .. " · Acto I (2/4)",
		Duration = { 12, 18 },
		Npcs = { "Oriana", "Bartolo" },
		Offer = { Place = "Mar_Plaza" },
		OfferKey = "Oriana te hace señas desde la Lonja Honda",
		Requires = after("Mar_01_Concha"),
		Moment = "Hiciste tu primer trueque con Bartolo en La Burbuja",
		Memory = "PrimerTrueque",
		Rewards = { Money = 120, Flags = { "MarBurbuja" }, Rel = { Bartolo = 10, Oriana = 5 } },
		Props = {
			Concha1 = { Kind = "Cristal", Name = "Una concha de nácar", Prompt = "Coger la concha", Place = "Mar_Burbuja", Offset = V(-18, 0, 14), Color = Color3.fromRGB(245, 230, 220), Once = true },
			Concha2 = { Kind = "Cristal", Name = "Una concha rosada", Prompt = "Coger la concha", Place = "Mar_Burbuja", Offset = V(22, 0, 18), Color = Color3.fromRGB(255, 190, 210), Once = true },
			Concha3 = { Kind = "Cristal", Name = "Una concha de espiral", Prompt = "Coger la concha", Place = "Mar_Burbuja", Offset = V(4, 0, -24), Color = Color3.fromRGB(220, 210, 255), Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Oriana", Dialogue = "Oriana", Place = "Mar_Plaza", Text = "Habla con Oriana en la Lonja Honda (la cúpula de aire de la plaza)" },
			{ Type = "Reach", Place = "Mar_Burbuja", Text = "Ve a La Burbuja, la posada de los secos, en el Talud del Naufragio (al este de las Ruinas, a ~20 m)" },
			{ Type = "Talk", Npc = "Bartolo", Dialogue = "Bartolo", Place = "Mar_Burbuja", Text = "Habla con Bartolo, el desguacero, junto a la posada" },
			{ Type = "Group", Text = "Bartolo quiere tres conchas bonitas a cambio de «algo especial»",
				Steps = {
					{ Type = "Use", Prop = "Concha1", Text = "Una concha de nácar" },
					{ Type = "Use", Prop = "Concha2", Text = "Una concha rosada" },
					{ Type = "Use", Prop = "Concha3", Text = "Una concha de espiral" },
				} },
			{ Type = "Talk", Npc = "Bartolo", Dialogue = "Trueque", Place = "Mar_Burbuja", Text = "Lleva las conchas a Bartolo" },
		},
		Dialogues = {
			Oriana = { Lines = { { S = "Oriana", T = "Busca La Burbuja.", To = "Yo" } } },
			Bartolo = { Lines = { { S = "Bartolo", T = "¡Un seco!", To = "Yo" } } },
			Trueque = { Lines = { { S = "Bartolo", T = "Trato hecho.", To = "Yo" } } },
		},
	},

	---------------------------------------------------------------------
	-- Acto I · 3 · Un seco en Nácara (la escena grande del juicio)
	---------------------------------------------------------------------
	{
		Id = "Mar_03_Juicio",
		Kind = "Side",
		Canon = true,
		Title = "Un seco en Nácara",
		Description = "La Guardia de la Corriente te ha visto nadando por la capital. Un seco en Nácara no pasaba desde hacía cien años. Te llevan ante el Consejo de las Corrientes.",
		Type = TIPO .. " · Acto I (3/4)",
		Duration = { 12, 20 },
		Npcs = { "Maresa", "GuardiaConsejo", "Ilun" },
		Offer = { Place = "Mar_Plaza" },
		OfferKey = "Un guardia con bastón te corta el paso: «Tú. Al Consejo.»",
		Requires = after("Mar_02_Burbuja"),
		Moment = "Te juzgó el Consejo de las Corrientes y empezaste a servir a una Corriente",
		Memory = "JuicioConsejo",
		Rewards = { Money = 150, Flags = { "MarJuicio" }, Rel = { Maresa = 10 } },
		Steps = {
			{ Type = "Talk", Npc = "GuardiaConsejo", Dialogue = "Guardia", Place = "Mar_Consejo", Text = "La Guardia del Consejo te espera en la Concha del Consejo (al norte de la plaza)" },
			{ Type = "Cinematic", Id = "Mar_Juicio" },
			{ Type = "Choice", Key = "MarJuicio", Text = "Maresa te mira: «¿Por qué ha bajado un seco a Nácara?»",
				Options = {
					{ Id = "Verdad", Text = "«Ilun me llamó con su concha. Vengo a ayudar.»", Effects = { Flags = { "MarJuicioVerdad" }, Rel = { Maresa = 10, Ilun = 5 }, Traits = { Empatia = 1 } } },
					{ Id = "Regalo", Text = "«Traigo un regalo de tierra: herramientas y vidrio.»", Effects = { Flags = { "MarJuicioRegalo" }, Rel = { Maresa = 5 }, Traits = { Responsabilidad = 1 } } },
					{ Id = "Callar", Text = "No decir nada y aguantarle la mirada", Effects = { Flags = { "MarJuicioCallar" }, Traits = { Valentia = 1 } } },
				} },
			{ Type = "Event", Event = "MarJobDone", Match = { Any = true }, Text = "Primera prueba: haz un turno para una Corriente (tablones «Trabajar»: cultivador/a de algas en los Jardines o farolero/a en el paseo)" },
			{ Type = "Talk", Npc = "Maresa", Dialogue = "Veredicto", Place = "Mar_Consejo", Text = "Vuelve a la Concha del Consejo: Maresa tiene algo que decirte" },
		},
		Dialogues = {
			Guardia = { Lines = { { S = "GuardiaConsejo", T = "Al Consejo.", To = "Yo" } } },
			Veredicto = { Lines = { { S = "Maresa", T = "Has cumplido.", To = "Yo" } } },
		},
	},

	---------------------------------------------------------------------
	-- Acto I · 4 · Redes cortadas (persecución y decisión)
	---------------------------------------------------------------------
	{
		Id = "Mar_04_Redes",
		Kind = "Side",
		Canon = true,
		Title = "Redes cortadas",
		Description = "Alguien corta las redes de los pescadores de Valmar por la noche, para que se vayan del mar. Tomé ha visto una sombra en el bosque de kelp del norte. Los secos tienen la culpa, dicen algunos. Tú no lo crees.",
		Type = TIPO .. " · Acto I (4/4)",
		Duration = { 10, 16 },
		Npcs = { "Tome", "Sargo" },
		Offer = { Place = "Mar_Consejo" },
		OfferKey = "Tomé llega nadando deprisa: «¡Han vuelto a cortar redes!»",
		Requires = after("Mar_03_Juicio"),
		Moment = "Pillaste a Sargo, de la Marea Callada, cortando redes",
		Memory = "RedesCortadas",
		Rewards = { Money = 180, Flags = { "MarRedes" } },
		Steps = {
			{ Type = "Talk", Npc = "Tome", Dialogue = "Tome", Place = "Mar_Jardines", Text = "Habla con Tomé en los Jardines de Cultivo" },
			{ Type = "Reach", Place = "Mar_KelpNorte", Text = "Ve al bosque de kelp del norte, donde Tomé vio la sombra" },
			{ Type = "Event", Event = "MarChase", Match = { Result = "Caught" }, Text = "¡Ahí está! Persíguele por el kelp y alcánzale (nada, usa Correr)" },
			{ Type = "Talk", Npc = "Sargo", Dialogue = "Sargo", Text = "Le has pillado: habla con él" },
			{ Type = "Choice", Key = "MarSargo", Text = "Sargo tiene miedo. ¿Qué haces con él?",
				Options = {
					{ Id = "Entregar", Text = "Llevarle al Consejo: «Lo que haces hace daño»", Effects = { Flags = { "MarSargoEntregado" }, Rel = { Maresa = 5, Sargo = -10 }, Traits = { Responsabilidad = 1 } } },
					{ Id = "Dejar", Text = "Dejarle ir si promete no volver a hacerlo", Effects = { Flags = { "MarSargoLibre" }, Rel = { Sargo = 15 }, Traits = { Empatia = 1 } } },
				} },
		},
		Dialogues = {
			Tome = { Lines = { { S = "Tome", T = "Una sombra en el kelp.", To = "Yo" } } },
			Sargo = { Lines = { { S = "Sargo", T = "¡Suéltame!", To = "Yo" } } },
		},
	},

	---------------------------------------------------------------------
	-- Secundaria · Las perlas de Oriana
	---------------------------------------------------------------------
	{
		Id = "Mar_S1_Perlas",
		Kind = "Side",
		Title = "Las perlas de Oriana",
		Description = "Una corriente brava se ha llevado tres perlas del puesto de Oriana. Brillan: si nadas por la ciudad, las verás.",
		Type = TIPO .. " · Secundaria",
		Duration = { 6, 10 },
		Npcs = { "Oriana" },
		Offer = { Place = "Mar_Plaza" },
		OfferKey = "Oriana: «¡Mis perlas! ¿Me ayudas a buscarlas?»",
		Requires = after("Mar_01_Concha"),
		Moment = "Devolviste a Oriana sus tres perlas",
		Rewards = { Money = 120, Rel = { Oriana = 10 } },
		Props = {
			Perla1 = { Kind = "Cristal", Name = "Una perla que brilla", Prompt = "Coger la perla", Place = "Mar_Plaza", Offset = V(28, 0, 68), Color = Color3.fromRGB(255, 210, 240), Once = true },
			Perla2 = { Kind = "Cristal", Name = "Una perla que brilla", Prompt = "Coger la perla", Place = "Mar_Plaza", Offset = V(-74, 0, 52), Color = Color3.fromRGB(200, 240, 255), Once = true },
			Perla3 = { Kind = "Cristal", Name = "Una perla que brilla", Prompt = "Coger la perla", Place = "Mar_Plaza", Offset = V(84, 0, 40), Color = Color3.fromRGB(255, 240, 200), Once = true },
		},
		Steps = {
			{ Type = "Group", Text = "Busca las tres perlas de Oriana por Nácara (brillan)",
				Steps = {
					{ Type = "Use", Prop = "Perla1", Text = "Una perla rosa" },
					{ Type = "Use", Prop = "Perla2", Text = "Una perla azul" },
					{ Type = "Use", Prop = "Perla3", Text = "Una perla dorada" },
				} },
			{ Type = "Talk", Npc = "Oriana", Dialogue = "Perlas", Place = "Mar_Plaza", Text = "Devuélvele las perlas a Oriana" },
		},
		Dialogues = {
			Perlas = { Lines = { { S = "Oriana", T = "¡Mis perlas!", To = "Yo" } } },
		},
	},

	---------------------------------------------------------------------
	-- Secundaria · La primera noche de Lía
	---------------------------------------------------------------------
	{
		Id = "Mar_S2_Farolas",
		Kind = "Side",
		Title = "La primera noche de Lía",
		Description = "Lía, la farolera, se ha quedado sin ayudantes: Ilun está castigado por bajar a la superficie. Si no se cargan las perlas-farola antes de la noche, lo hondo se acerca a Nácara.",
		Type = TIPO .. " · Secundaria",
		Duration = { 8, 12 },
		Npcs = { "Lia" },
		Offer = { Place = "Mar_Plaza" },
		OfferKey = "Lía, la farolera: «¡Necesito unas manos! Aunque sean secas»",
		Requires = after("Mar_01_Concha"),
		Moment = "Cargaste tus primeras perlas-farola con Lía",
		Rewards = { Money = 100, Rel = { Lia = 10 }, Flags = { "MarFarolera" } },
		Steps = {
			{ Type = "Talk", Npc = "Lia", Dialogue = "Lia", Place = "Mar_Plaza", Text = "Habla con Lía, la farolera (en el paseo, al noreste de la plaza)" },
			{ Type = "Event", Event = "MarJobDone", Match = { JobId = "MarFarolero" }, Text = "Haz un turno de farolero/a: tablón «Trabajar» del paseo de las perlas-farola" },
			{ Type = "Talk", Npc = "Lia", Dialogue = "Gracias", Place = "Mar_Plaza", Text = "Vuelve con Lía" },
		},
		Dialogues = {
			Lia = { Lines = { { S = "Lia", T = "¡Unas manos!", To = "Yo" } } },
			Gracias = { Lines = { { S = "Lia", T = "Gracias.", To = "Yo" } } },
		},
	},
}
