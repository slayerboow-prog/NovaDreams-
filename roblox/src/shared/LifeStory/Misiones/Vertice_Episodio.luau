-- SAGA 2 «RAGNAROCK» · VÉRTICE · «LIQUIDACIÓN TOTAL», la primera parte jugable (≈ 30 min; docs/planetas/
-- talasa-vertice.md, diseño en docs/planetas/diseno-mundos.md §3.7.16). Misiones CANÓNICAS: su marca dorada
-- sale en Distrito Cero y empiezan solas al llegar al sitio. Solo en Vértice (Requires.Planet).
--
--   1 Vertice_01_Llegada  «Gracias por su compra»   llegas, Gil (empleado del mes) y las cámaras
--   2 Vertice_02_Abril    «La técnica de la cúpula» el Rastro, Abril Cruz y un turno de técnico/a de cúpula
--   3 Vertice_03_Museo    «La historia oficial»     colarte en el Museo de la Luz, el archivo y la cuenta
--   4 Vertice_04_HoraPunta «Hora punta»             los drones de cobro y la carrera hasta el Rastro
--   5 Vertice_05_Luz      «Luz embotellada»         «Proveedor: V.» y Ofelia Brum anuncia la Liquidación Total
--
-- Las frases son del guion (docs/historia/reescritura/Vertice_0*.md → Guiones/, nunca a mano). Ofelia Brum
-- se queda en Vértice; su luz la compra a «un tal V.» (solo un guiño a Varkun: docs/universo/diseno-espacio.md).
-- 13+: sin sangre; los drones y la seguridad «se apagan» o se rinden.

local V = Vector3.new

local TIPO = "Saga 2 · Vértice · «Liquidación total»"

local function after(id: string?): { [string]: any }
	local req: { [string]: any } = { Stage = { Min = "Adulto" }, Planet = "Vertice" }
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
	-- 1 · Gracias por su compra
	---------------------------------------------------------------------
	{
		Id = "Vertice_01_Llegada",
		Kind = "Side",
		Canon = true,
		Title = "Gracias por su compra",
		Description = "Has llegado a Vértice, el planeta que es una sola ciudad y una sola empresa. En Distrito Cero todo brilla, todo tiene precio y las cámaras te multan solas.",
		Type = TIPO .. " (1/5)",
		Duration = { 6, 9 },
		Npcs = { "Cosme", "Gil" },
		Offer = { Place = "Vertice_Plataforma" },
		OfferKey = "Distrito Cero. Un holograma te da la bienvenida antes de bajar de la nave",
		Requires = after(nil),
		Moment = "Llegaste a Distrito Cero, la ciudad de MegaVerso",
		Memory = "LlegadaVertice",
		Rewards = { Money = 60, Flags = { "VerticeLlegado" }, Items = { Vertice_GorraAnti = 1, Vertice_Inhibidor = 3 } },
		Steps = {
			{ Type = "Cinematic", Id = "Vertice_Llegada", Actors = { at("Cosme", "Vertice_Plataforma", 3, 2) } },
			{ Type = "Talk", Npc = "Cosme", Dialogue = "Llegada", Text = "Habla con Cosme en la plataforma", Actors = { at("Cosme", "Vertice_Plataforma", 3, 2) } },
			{ Type = "Reach", Place = "Vertice_Plaza", Text = "Baja a la Plaza del Primer Cliente", Actors = { COSME_SIGUE } },
			{ Type = "Talk", Npc = "Gil", Dialogue = "Bienvenida", Text = "Un empleado de MegaVerso te saluda junto a la estatua",
				Actors = { at("Gil", "Vertice_Estatua", 0, -3), at("Cosme", "Vertice_Estatua", 4, 2) } },
			{ Type = "Event", Event = "HazardChanged", Match = { Planet = "Vertice", Phase = "Aviso" }, Place = "Vertice_Avenida",
				Text = "Pasea por la Avenida Rebajas, delante de las cámaras (mira tu medidor de 👁 vigilancia)" },
			{ Type = "Event", Event = "HazardChanged", Match = { Planet = "Vertice", Phase = "Normal" },
				Text = "¡Te están mirando! Usa un 📵 inhibidor de la mochila o métete en el Arcade de neón hasta que baje" },
		},
		Dialogues = {
			Llegada = respaldo("Cosme", "Vértice. Aquí hasta el aire tiene precio, criatura."),
			Bienvenida = respaldo("Gil", "¡Gracias por su compra! Bienvenidos a Distrito Cero."),
		},
	},

	---------------------------------------------------------------------
	-- 2 · La técnica de la cúpula
	---------------------------------------------------------------------
	{
		Id = "Vertice_02_Abril",
		Kind = "Side",
		Canon = true,
		Title = "La técnica de la cúpula",
		Description = "Gil ha dicho, muy bajito, que si alguien de fuera quiere saber la verdad de Distrito Cero, pregunte en el ascensor de mantenimiento del Rastro por una tal Abril.",
		Type = TIPO .. " (2/5)",
		Duration = { 6, 9 },
		Npcs = { "AbrilCruz", "Cosme" },
		Offer = { Place = "Vertice_Rastro" },
		OfferKey = "En la entrada del Rastro, una mujer con chaleco amarillo y una llave inglesa",
		Requires = after("Vertice_01_Llegada"),
		Moment = "Conociste a Abril Cruz y arreglaste los paneles de Distrito Cero",
		Memory = "AbrilVertice",
		Rewards = { Money = 80, Flags = { "VerticeConoceAbril" }, Items = { Vertice_ChapaAbril = 1 } },
		Steps = {
			{ Type = "Talk", Npc = "AbrilCruz", Dialogue = "Abril", Text = "Busca a Abril en la entrada del Rastro", Actors = { at("AbrilCruz", "Vertice_Rastro", 0, 3), at("Cosme", "Vertice_Rastro", 4, 2) } },
			{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "VerticeTecnicoCupula" }, Place = "Vertice_Plaza",
				Text = "Haz un turno de 💡 técnico/a de cúpula (tablón de la plaza): arregla dos paneles antes del apagón" },
			{ Type = "Reach", Place = "Vertice_AscensorDentro", Text = "Vuelve con Abril: te espera dentro del ascensor de mantenimiento", Actors = { COSME_SIGUE } },
			{ Type = "Scene", Dialogue = "Prueba", Actors = { at("AbrilCruz", "Vertice_AscensorDentro", 1, 2), at("Cosme", "Vertice_AscensorDentro", -2, 1) } },
		},
		Dialogues = {
			Abril = respaldo("AbrilCruz", "¿Gil te manda? Entonces necesitas trabajo. Toma."),
			Prueba = respaldo("AbrilCruz", "Buen trabajo. Bienvenida al Rastro."),
		},
	},

	---------------------------------------------------------------------
	-- 3 · La historia oficial
	---------------------------------------------------------------------
	{
		Id = "Vertice_03_Museo",
		Kind = "Side",
		Canon = true,
		Title = "La historia oficial",
		Description = "Abril cree que el Museo de la Luz esconde algo en su archivo: los anuncios de los primeros años de Vértice, antes de que MegaVerso tapara el cielo con la Cúpula.",
		Type = TIPO .. " (3/5)",
		Duration = { 8, 11 },
		Npcs = { "AbrilCruz", "Cosme" },
		Offer = { Place = "Vertice_Museo" },
		OfferKey = "Abril señala el Museo de la Luz: «La historia oficial. Vamos a leer la otra»",
		Requires = after("Vertice_02_Abril"),
		Moment = "Te colaste en el Museo de la Luz y viste lo que tapa la Cúpula",
		Memory = "MuseoVertice",
		Rewards = { Money = 110, Items = { Vertice_ArchivoMuseo = 1 } },
		Props = {
			Placa = { Kind = "Marcador", Name = "La placa del Primer Cliente", Prompt = "Leer la placa", Place = "Vertice_MuseoDentro", Offset = V(3, 0, -3), Dialogue = "Placa", Once = true },
			Archivo = { Kind = "Caja", Name = "El archivo de anuncios", Prompt = "Abrir el archivo", Place = "Vertice_MuseoDentro", Offset = V(-3, 0, -2), Dialogue = "Archivo", Once = true },
			Terminal = { Kind = "Papel", Name = "El terminal de la Contable", Prompt = "Mirar el terminal", Place = "Vertice_MuseoDentro", Offset = V(0, 0, 3), Dialogue = "Terminal", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "AbrilCruz", Dialogue = "Plan", Text = "Abril te espera junto a la puerta del Museo de la Luz", Actors = { at("AbrilCruz", "Vertice_Museo", 3, 2), at("Cosme", "Vertice_Museo", 5, 4) } },
			{ Type = "Escape", Place = "Vertice_MuseoDentro", Respawn = "Vertice_Oficinas", Catch = 4,
				Text = "Entra en el Museo sin que te pare la seguridad de MegaVerso",
				CaughtLine = "«Cliente sin cita. Gracias por su comprensión». (Te devuelven a los pies de la Torre.)",
				Actors = {
					{ Npc = "SeguridadMV1", Place = "Vertice_Oficinas", Offset = V(-10, 0, -6), Mode = "Hunt", Speed = 9, Prompt = false },
					{ Npc = "SeguridadMV2", Place = "Vertice_Museo", Offset = V(8, 0, 6), Mode = "Hunt", Speed = 8, Prompt = false },
				} },
			{ Type = "Group", Text = "Busca en el Museo lo que no cuenta la historia oficial",
				Steps = {
					{ Type = "Use", Prop = "Placa", Text = "La placa del Primer Cliente" },
					{ Type = "Use", Prop = "Archivo", Text = "El archivo de anuncios" },
					{ Type = "Use", Prop = "Terminal", Text = "El terminal de la Contable" },
				} },
			{ Type = "MiniGame", Game = "Timing", Title = "Copiar el archivo", Icon = "💾", Hint = "Copia los datos cuando la aguja pase por el verde, sin que salte la alarma",
				Rounds = 3, Need = 2, Zone = 0.26, Speed = 1.05,
				Win = { Flags = { "VerticeArchivoLimpio" } }, Lose = { Flags = { "VerticeArchivoRuidoso" } } },
			{ Type = "Choice", Key = "VerticeCuenta", Text = "En el terminal hay una cuenta de MegaVerso abierta: 300 € a un toque, y nadie lo notaría… de momento. ¿Qué haces?",
				Options = {
					{ Id = "Dejar", Text = "No tocarla: vienes a por la verdad, no a robar", Effects = { Flags = { "VerticeCuentaLimpia" }, Rel = { AbrilCruz = 10 }, Traits = { Responsabilidad = 1 } } },
					{ Id = "Quedarse", Text = "Quedarte el dinero: MegaVerso le debe eso y más a la ciudad", Effects = { Flags = { "VerticeDineroCuenta" }, Money = 300, Rel = { AbrilCruz = -5 }, Traits = { Valentia = 1 } } },
				} },
			{ Type = "Scene", Dialogue = "Salida", Actors = { at("AbrilCruz", "Vertice_Museo", 3, 2), at("Cosme", "Vertice_Museo", 5, 4) } },
		},
		Dialogues = {
			Plan = respaldo("AbrilCruz", "El archivo está en la sala del fondo. Entra, mira y sal."),
			Placa = respaldo("Narrador", "«El Primer Cliente, 150 años de confianza»."),
			Archivo = respaldo("Narrador", "Anuncios viejos. En el fondo de todos, un sol."),
			Terminal = respaldo("Narrador", "Un terminal encendido. Una cuenta abierta."),
			Salida = respaldo("AbrilCruz", "Antes de la Cúpula había sol. Y lo borraron."),
		},
	},

	---------------------------------------------------------------------
	-- 4 · Hora punta
	---------------------------------------------------------------------
	{
		Id = "Vertice_04_HoraPunta",
		Kind = "Side",
		Canon = true,
		Title = "Hora punta",
		Description = "Alguien ha avisado a MegaVerso de que hubo visita en el Museo. Gil te busca en la plaza con mala cara, y los drones de cobro ya han despegado.",
		Type = TIPO .. " (4/5)",
		Duration = { 6, 9 },
		Npcs = { "Gil", "AbrilCruz" },
		Offer = { Place = "Vertice_Plaza" },
		OfferKey = "Gil te hace señas desde la estatua. Suda",
		Requires = after("Vertice_03_Museo"),
		Moment = "Escapaste de los drones de cobro en plena hora punta",
		Memory = "HoraPuntaVertice",
		Rewards = { Money = 90 },
		Steps = {
			{ Type = "Talk", Npc = "Gil", Dialogue = "Aviso", Text = "Gil te hace señas junto a la estatua", Actors = { at("Gil", "Vertice_Estatua", 0, -3) } },
			{ Type = "Fight", Place = "Vertice_Plaza", Respawn = "Vertice_Plaza", Action = "Apagar 💥", HP = 4,
				Text = "¡Drones de cobro! Apágalos antes de que te embarguen ({count}/{total})",
				CaughtLine = "(Un dron te sella la mano: «Multa provisional». Te sacudes y vuelves a la plaza.)",
				Actors = { at("Gil", "Vertice_Estatua", -4, -6) },
				Enemies = {
					{ Npc = "DronSeguridad1", Offset = V(14, 0, -4), Speed = 9, HP = 3, Bye = "(Se apaga con un «gracias por su paciencia».)" },
					{ Npc = "DronSeguridad2", Offset = V(-14, 0, 6), Speed = 10, HP = 3, Bye = "(Chisporrotea y se posa en el suelo, apagado.)" },
				} },
			{ Type = "Fight", Place = "Vertice_Plaza", Respawn = "Vertice_Plaza", Action = "Apagar 💥", HP = 4, If = { Choices = { VerticeCuenta = "Quedarse" } },
				Text = "La Contable ha visto el dinero que falta: ¡un dron dorado viene a por ti! ({count}/{total})",
				CaughtLine = "(El dron dorado te enseña tu saldo en grande. Te escabulles.)",
				Enemies = {
					{ Npc = "DronSeguridad3", Offset = V(0, 0, 16), Speed = 11, HP = 4, Bye = "(Se apaga. En su pantalla: «Cuenta cuadrada… casi».)" },
				} },
			{ Type = "Escape", Place = "Vertice_AscensorDentro", Respawn = "Vertice_Plaza", Catch = 4,
				Text = "🚦 ¡Hora punta! Corre hasta el ascensor del Rastro entre la gente, sin que te pille la seguridad",
				CaughtLine = "«Cliente detenido por correr en zona peatonal». (Te sueltan en la plaza con una multa archivada.)",
				Actors = {
					{ Npc = "SeguridadMV1", Place = "Vertice_Plaza", Offset = V(18, 0, 10), Mode = "Hunt", Speed = 10, Prompt = false },
					{ Npc = "SeguridadMV2", Place = "Vertice_Rastro", Offset = V(10, 0, 8), Mode = "Hunt", Speed = 9, Prompt = false },
				} },
			{ Type = "Scene", Dialogue = "Rastro", Actors = { at("AbrilCruz", "Vertice_AscensorDentro", 1, 2) } },
		},
		Dialogues = {
			Aviso = respaldo("Gil", "Te han visto. Vienen los drones. ¡Corre!"),
			Rastro = respaldo("AbrilCruz", "Aquí abajo no entran las cámaras. Respira."),
		},
	},

	---------------------------------------------------------------------
	-- 5 · Luz embotellada
	---------------------------------------------------------------------
	{
		Id = "Vertice_05_Luz",
		Kind = "Side",
		Canon = true,
		Title = "Luz embotellada",
		Description = "Abril quiere saber de dónde sale la luz embotellada que MegaVerso vende tan cara. Las cajas llegan cada noche al andén del mag-lev.",
		Type = TIPO .. " (5/5)",
		Duration = { 6, 9 },
		Npcs = { "AbrilCruz", "Cosme", "OfeliaBrum" },
		Offer = { Place = "Vertice_Maglev" },
		OfferKey = "Cajas de luz embotellada en el andén del mag-lev. Abril vigila",
		Requires = after("Vertice_04_HoraPunta"),
		Moment = "Leíste «Proveedor: V.» en una caja de luz y oíste a Ofelia Brum anunciar la Liquidación Total",
		Memory = "LuzVertice",
		Rewards = { Money = 140, Flags = { "VerticePrologoHecho" }, Items = { Vertice_TrajeCamaleon = 1, Vertice_LuzEmbotellada = 2 } },
		Props = {
			Caja = { Kind = "Caja", Name = "Una caja de luz embotellada", Prompt = "Leer la etiqueta", Place = "Vertice_Maglev", Offset = V(6, 0, 2), Dialogue = "Caja", Once = true,
				Effects = { Items = { Vertice_EtiquetaV = 1 } } },
		},
		Steps = {
			{ Type = "Talk", Npc = "AbrilCruz", Dialogue = "Anden", Text = "Abril te espera en el andén del mag-lev", Actors = { at("AbrilCruz", "Vertice_Maglev", 0, 3), at("Cosme", "Vertice_Maglev", 4, 4) } },
			{ Type = "Use", Prop = "Caja", Text = "Mira la etiqueta de una caja mientras nadie vigila" },
			{ Type = "Choice", Key = "VerticeVerdad", Text = "La etiqueta dice «Proveedor: V. · Pagado por: O. Brum». Abril se ha ido a vigilar la vía. ¿Qué haces con la etiqueta?",
				Options = {
					{ Id = "Contar", Text = "Enseñársela a Abril ya: la resistencia tiene que saberlo", Effects = { Flags = { "VerticeAbrilSabe" }, Rel = { AbrilCruz = 10 }, Traits = { Empatia = 1 } } },
					{ Id = "Guardar", Text = "Guardarla hasta saber quién es «V.»", Effects = { Flags = { "VerticeEtiquetaGuardada" }, Traits = { Responsabilidad = 1 } } },
				},
				Actors = { at("Cosme", "Vertice_Maglev", 4, 4) } },
			{ Type = "Cinematic", Id = "Vertice_Cierre", Actors = { at("AbrilCruz", "Vertice_Plaza", 3, 2), at("Cosme", "Vertice_Plaza", -3, 3) } },
		},
		Dialogues = {
			Anden = respaldo("AbrilCruz", "Cada noche llegan cien cajas. Nadie sabe de dónde."),
			Caja = respaldo("Narrador", "«Luz embotellada · Proveedor: V. · Pagado por: O. Brum»."),
		},
	},
}
