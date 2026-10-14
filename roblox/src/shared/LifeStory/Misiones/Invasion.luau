-- INVASIÓN DE LA GRIETA: secundarias de la historia que nacen del evento global (docs/invasion.md).
-- Las ofrece la propia invasión (Offer.Event: InvasionStarted / InvasionEnded, que emite
-- Services/InvasionService) y avanzan con sus sucesos (InvasionKill, InvasionMission, InvasionCured,
-- InvasionRepaired). Las misiones del evento en sí (defender zonas, derribar naves, las de vuelo y
-- «Recuperar la normalidad») las lleva InvasionService (shared/Invasion/Missions); estas son lo que
-- tu historia recuerda de ellas.
--   Invasion_PrimerContacto  desde Adolescente  «Primer contacto»
--   Invasion_Alas            desde AdultoJoven  «Alas sobre Valmar» (una misión de vuelo de la invasión)
--   Invasion_LaCalma         desde Adolescente  «La calma después»

return {
	{
		Id = "Invasion_PrimerContacto",
		Kind = "Side",
		Title = "Primer contacto",
		Description = "La grieta se ha abierto y por ella bajan naves de otra galaxia. La Comisaria Robles pide a cualquiera que pueda ayudar que defienda la ciudad mientras dure.",
		Type = "Invasión de la Grieta",
		Duration = { 5, 10 },
		Offer = { Event = "InvasionStarted" },
		OfferKey = "¡Naves alienígenas sobre Valmar! La radio de la policía pide voluntarios",
		Requires = { Stage = { Min = "Adolescente" } },
		Moment = "El día que los alienígenas bajaron a Valmar (y les plantaste cara)",
		Rewards = { Money = 150 },
		Steps = {
			{ Type = "Event", Event = "InvasionKill", Count = 3, Text = "Ayuda a defender Valmar: tumba 3 alienígenas o naves" },
			{ Type = "Event", Event = "InvasionEnded", Text = "Aguanta hasta que acabe la invasión" },
		},
	},
	{
		Id = "Invasion_Alas",
		Kind = "Side",
		Title = "Alas sobre Valmar",
		Description = "Inés Vidal, la controladora de la torre del aeroclub, necesita pilotos en el aire durante la invasión: exploradores, evacuaciones y una baliza alienígena en lo alto del cielo.",
		Type = "Invasión de la Grieta · vuelo",
		Duration = { 5, 15 },
		Offer = { Event = "InvasionStarted" },
		OfferKey = "Torre del aeroclub a todos los pilotos: necesitamos alas en el cielo de Valmar",
		Requires = { Stage = { Min = "AdultoJoven" } },
		Moment = "Volaste sobre Valmar mientras la defendían desde el suelo",
		Rewards = { Money = 300 },
		Steps = {
			{ Type = "Event", Event = "InvasionMission", Match = { Chain = "Vuelo" }, Text = "Completa una misión de vuelo de la invasión (en avioneta o en nave)" },
		},
	},
	{
		Id = "Invasion_LaCalma",
		Kind = "Side",
		Title = "La calma después",
		Description = "La invasión se ha ido, pero ha dejado vecinos transformados y calles rotas. La doctora Sofía Arenas, del Laboratorio Xeno del hospital, pide ayuda para devolver Valmar a la normalidad.",
		Type = "Invasión de la Grieta · paz",
		Duration = { 10, 20 },
		Offer = { Event = "InvasionEnded" },
		OfferKey = "La doctora Arenas: «Nadie ha muerto. Pero hay mucha gente que ya no es… ella misma»",
		Requires = { Stage = { Min = "Adolescente" } },
		Moment = "Ayudaste a que Valmar volviera a ser Valmar",
		Rewards = { Money = 250 },
		Steps = {
			{ Type = "Event", Event = "InvasionCured", Text = "Devuelve su forma a un vecino transformado (inversor de fase, Laboratorio Xeno)" },
			{ Type = "Event", Event = "InvasionRepaired", Text = "Repara un destrozo de la invasión" },
		},
	},
}
