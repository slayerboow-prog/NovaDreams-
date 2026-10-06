-- PROFESIÓN Y VIDA ADULTA · misiones de la carrera (paquete P8d). Escenas: Happenings/Adulto.
--
--   Adu_Ascenso          «Pásate por mi mesa»   tu jefe te ofrece un ascenso (2 h después de «Un atardecer
--                                               junto al mar», si no te han despedido)
--   Eco_Despido          «La carta del lunes»    recortes: te despiden (3 h después de «Mi primer contrato»
--                                               si llegaste tarde el primer día o mentiste en tu primera
--                                               entrevista) → tu familia esa noche → trabajar de lo que
--                                               salga → una puerta nueva
--   Adu_AscensoPolicia   «Una placa nueva»       Inés te la ofrece en la comisaría; cuando asciendes en la
--                                               policía (aviso Promoted de CareerService), te da tu placa
--                                               nueva (y entra Bruno, si ya es policía)
--   Adulto_LlegadaValmar · Adulto_PrimerSueldo  «Una nueva vida en Valmar» (veteranos), ahora con Ernesto y
--                                               Lola: sustituyen a las de Quests.luau (mismos pasos y textos,
--                                               más la escena de bienvenida y el reparto)
--
-- Se cargan desde Adu_Consecuencias (MissionIndex no es de este paquete). Si se prefiere, basta con
-- añadir require(Misiones.Adu_Profesion) a MissionIndex y quitar esa línea de Adu_Consecuencias.

local Comun = require(script.Parent.Adu_Escenas)

local V = Vector3.new
local JEFE = Comun.JEFE
local GRADUADO = Comun.GRADUADO

local function juntar(...: { any }): { any }
	local out = {}
	for _, list in { ... } do
		for _, x in list do
			table.insert(out, x)
		end
	end
	return out
end

-- La misma frase para tu jefe, sea quien sea (cada uno con su If)
local function jefes(texto: string): { { [string]: any } }
	local out = {}
	for _, spec in JEFE do
		table.insert(out, { S = spec.Npc, T = texto, If = spec.If })
	end
	return out
end

local INES = { { Npc = "Ines", Place = "Policia", Offset = V(0, 0, 5) } }

return {
	---------------------------------------------------------------------
	-- El ascenso
	---------------------------------------------------------------------
	{
		Id = "Adu_Ascenso",
		Kind = "Side",
		Title = "Pásate por mi mesa",
		Description = "Tu jefe quiere verte. No dice para qué. Eso nunca es buena señal… ¿o sí?",
		Type = "Profesión · Ascenso",
		Duration = { 5, 8 },
		Npcs = { "Nuria", "Sofia", "Montse", "Ignacio", "Lola", "Paco", "Ernesto" },
		Requires = { Stage = { Min = "AdultoJoven" }, Completed = { "Adu01_PrimerContrato" }, NotFlags = { "Despedido" } },
		Moment = "Te ofrecieron un ascenso",
		Memory = "ElAscenso",
		Steps = juntar(Comun.irAlTrabajo("Tu jefe quiere verte: ve a tu trabajo"), {
			Comun.paso("Adu_Ascenso", JEFE),
			{ Type = "Scene", Dialogue = "Respuesta", Actors = JEFE },
		}),
		Dialogues = {
			Respuesta = { Lines = {
				{ Ask = "¿Qué le contestas?", Options = {
					{ T = "«Acepto. Con todo.»", Effects = { Choice = { Ascenso = "Acepta" }, Flags = { "Ascendido" }, Money = 150, Traits = { Responsabilidad = 1 } },
						Then = jefes("Pues mañana empiezas. Y hoy, a celebrarlo. Eso también es una orden.") },
					{ T = "«Acepto… si me dejas los domingos para mi gente.»", Effects = { Choice = { Ascenso = "Domingos" }, Flags = { "Ascendido" }, Money = 120, Traits = { Empatia = 1 } },
						Then = juntar({
							{ S = "Yo", T = "Le prometí a mi abu volver al mar. Cada año.", If = { Choices = { PromesaAbu = "Volver" } } },
						}, jefes("¿Los domingos? Hechos. A algo así no se le dice que no.")) },
					{ T = "«Ahora no. Todavía tengo mucho que aprender.»", Effects = { Choice = { Ascenso = "Rechaza" }, Traits = { Responsabilidad = 1 } },
						Then = jefes("Lo respeto. Y me lo apunto: esta puerta sigue abierta.") },
				} },
			} },
		},
	},

	---------------------------------------------------------------------
	-- El despido
	---------------------------------------------------------------------
	{
		Id = "Eco_Despido",
		Kind = "Side",
		Title = "La carta del lunes",
		Description = "«Pásate por mi despacho a primera hora.» Un lunes. Sin emoticonos.",
		Type = "Consecuencia (meses después de «Mi primer contrato», si llegaste tarde el primer día o mentiste en tu primera entrevista)",
		Duration = { 12, 18 },
		Npcs = { "Nuria", "Sofia", "Montse", "Ignacio", "Lola", "Paco", "Ernesto", "Familia", "Beltran" },
		Requires = { Stage = { Min = "AdultoJoven" }, Completed = { "Adu01_PrimerContrato" } },
		Moment = "Te despidieron… y volviste a empezar",
		Memory = "ElDespido",
		Steps = juntar(
			{ { Type = "Transition", Text = "Un lunes, a primera hora, un mensaje: «Pásate por mi despacho».", Seconds = 3 } },
			Comun.irAlTrabajo("Tu jefe quiere verte a primera hora"),
			{
				Comun.paso("Adu_Despido", JEFE),
				{ Type = "Scene", Dialogue = "Reaccion", Actors = JEFE },
				{ Type = "Transition", Text = "Esa noche…", Seconds = 3 },
				{ Type = "Reach", Place = "Home", Text = "Vuelve a casa" },
				Comun.paso("Adu_DespidoCasa"),
				{ Type = "Event", Event = "JobTaskDone", Count = 2,
					Text = "Mientras sale algo de lo tuyo, paga el alquiler: trabaja en cualquier tablón «Trabajar» ({count}/{total})",
					Nudge = { After = 300, Every = 400, S = "Familia", T = "(mensaje) ¿Qué tal la búsqueda? Si necesitas lentejas, ya sabes." } },
				{ Type = "Scene", Dialogue = "NuevaPuerta" },
			}
		),
		Dialogues = {
			Reaccion = { Lines = {
				{ Ask = "¿Qué le dices?", Options = {
					{ T = "«Lo entiendo. Gracias por la oportunidad.»", Effects = { Choice = { Despido = "Calma" }, Flags = { "CartaRecomendacion" }, Traits = { Empatia = 1 } },
						Then = jefes("Te voy a escribir la mejor carta de recomendación que he escrito nunca. Y he escrito muchas.") },
					{ T = "«¿Y ya está? ¿Así, un lunes?»", Effects = { Choice = { Despido = "Enfado" }, Traits = { Rebeldia = 1 } },
						Then = jefes("Tienes todo el derecho a enfadarte. Yo también lo estaría.") },
					{ T = "«Pues ponme por escrito todo lo que he hecho bien.»", Effects = { Choice = { Despido = "Carta" }, Flags = { "CartaRecomendacion" }, Traits = { Valentia = 1 } },
						Then = jefes("Hecho. Va a ser una carta larga.") },
				} },
				{ S = "Yo", T = "Finiquito en la cuenta. Una caja con mis cosas. Y la puerta." },
			}, Effects = { Flags = { "Despedido" }, Money = 300 } },
			NuevaPuerta = { Lines = {
				{ S = "Beltran", T = "(al teléfono) Me han contado que estás libre. Tengo un sitio que necesita a alguien que confiese sus errores. El lunes a las nueve. Puntual, esta vez.", If = { Flags = { "Graduado", "LlegasTardeContrato" } } },
				{ S = "Beltran", T = "(al teléfono) Me han contado que estás libre. Tengo un sitio que necesita a alguien como tú. El lunes a las nueve. No me hagas quedar mal.", If = { Flags = { "Graduado" }, NotFlags = { "LlegasTardeContrato" } } },
				{ S = "Paco", T = "(al teléfono) Hmm. Me han dicho que estás libre. Mi súper necesita a alguien que sepa mandar sin gritar. Lola grita. Tú no.", If = Comun.CAFE },
				{ S = "Lola", T = "(al teléfono) ¡Me lo ha contado Paco! Ese gruñón… Ven a la cafetería. Necesito a alguien en la barra. ¡YA!", If = Comun.SUPER },
				{ S = "Lola", T = "(al teléfono) ¡Me lo ha contado Ernesto! Ven a la cafetería, que la barra te espera. ¡Y trae hambre!", If = Comun.CORREOS },
				{ S = "Yo", T = "Y con la carta en la mano. Esta vez entro por la puerta grande.", If = { Flags = { "CartaRecomendacion" } } },
				{ S = "Yo", T = "Una puerta se cierra. Otra se abre. Abu lo diría con un refrán. Yo lo digo con hambre." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Ascenso en la policía (aviso Promoted de CareerService)
	---------------------------------------------------------------------
	{
		Id = "Adu_AscensoPolicia",
		Kind = "Side",
		Title = "Una placa nueva",
		Description = "Inés dice que, si sigues así, pronto habrá que cambiarte la placa. Inés nunca exagera.",
		Type = "Profesión · Policía",
		Duration = { 10, 30 },
		Npcs = { "Ines", "Bruno" },
		Offer = { Place = "Policia", Job = "Policia" }, -- (solo si trabajas en la policía)
		OfferKey = "La agente Inés te hace una seña desde la puerta de la comisaría: «¿Te veo de uniforme? Si haces carrera aquí, hablamos».",
		Requires = { Stage = { Min = "AdultoJoven" } },
		Moment = "Ascendiste en la policía",
		Memory = "AscensoPolicia",
		Steps = {
			{ Type = "Event", Event = "Promoted", Match = { Institution = "Policia" }, Text = "Gánate un ascenso en la policía: patrulla, ayuda a los vecinos y resuelve casos" },
			{ Type = "Reach", Place = "Policia", Text = "Inés quiere verte en la comisaría", Actors = INES },
			Comun.paso("Adu_AscensoRango", INES),
		},
	},

	---------------------------------------------------------------------
	-- Una nueva vida en Valmar (veteranos): con Ernesto y Lola
	---------------------------------------------------------------------
	{
		Id = "Adulto_LlegadaValmar",
		Kind = "Main",
		TitleKey = "QUEST.LLEGADA.TITLE",
		Description = "Acabas de llegar a Valmar para empezar una vida nueva. Necesitas un sitio donde vivir y algo que comer.",
		Npcs = { "Ernesto", "Lola" },
		Steps = {
			{ Type = "Reach", Place = "PlazaCentro", TextKey = "QUEST.LLEGADA.PLAZA" },
			Comun.paso("Adulto_Bienvenida"),
			{ Type = "Event", Event = "HomeClaimed", TextKey = "QUEST.LLEGADA.CASA", If = { NotFlags = { "TieneHogar" } } }, -- si ya te independizaste en la universidad, no hace falta
			{ Type = "Event", Event = "Ate", TextKey = "QUEST.LLEGADA.COMER",
				Actors = { { Npc = "Lola", Place = "CafeteriaCentral", Offset = V(0, 0, 5), Mode = "Chat" } },
				Nudge = { After = 240, Every = 400, S = "Lola", T = "(mensaje) La primera invita la casa. Cafetería de la plaza. No me hagas ir a buscarte." } },
		},
		Rewards = { Money = 100, Flags = { "TieneHogar" } },
		MomentKey = "MOMENT.PRIMER_HOGAR",
	},
	{
		Id = "Adulto_PrimerSueldo",
		Kind = "Main",
		TitleKey = "QUEST.SUELDO.TITLE",
		Description = "Para vivir en Valmar hace falta dinero. Busca un trabajo y gánate tu primer sueldo.",
		Npcs = { "Ernesto" },
		Requires = { Completed = { "Adulto_LlegadaValmar" } },
		Steps = {
			{ Type = "Event", Event = "JobTaskDone", Count = 3, TextKey = "QUEST.SUELDO.TRABAJA",
				Actors = { { Npc = "Ernesto", Place = "Correos", Offset = V(0, 0, 5) } },
				Nudge = { After = 240, Every = 400, S = "Ernesto", T = "(mensaje) Correos siempre necesita piernas. El tablón «Trabajar» está en la puerta. Ernesto." } },
		},
		Rewards = { Money = 150 },
		MomentKey = "MOMENT.PRIMER_SUELDO",
	},
}
