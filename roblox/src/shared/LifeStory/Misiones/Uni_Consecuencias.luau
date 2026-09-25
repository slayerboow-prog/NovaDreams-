-- Consecuencias de la universidad: misiones pequeñas que nacen de lo que hiciste (Later), horas después.

local V = Vector3.new

return {
	{
		Id = "Eco_Concierto",
		Kind = "Side",
		Title = "El concierto de Pablo",
		Description = "Pablo te ha mandado una invitación.",
		Type = "Consecuencia (3 h después de «El proyecto», si animaste a Pablo con su música)",
		Duration = { 4, 6 },
		Npcs = { "Pablo", "Julia", "Adrian", "Carla" },
		Requires = { Stage = { Min = "AdultoJoven", Max = "Adulto" } },
		Moment = "El primer concierto de Pablo",
		Steps = {
			{ Type = "Reach", Place = "PlazaCentro", Text = "Pablo toca esta noche en la plaza del centro. Ve a verle",
				Actors = {
					{ Npc = "Pablo", Place = "PlazaCentro", Offset = V(0, 0, 6) },
					{ Npc = "Julia", Place = "PlazaCentro", Offset = V(-4, 0, 1), Mode = "Cheer" },
					{ Npc = "Adrian", Place = "PlazaCentro", Offset = V(4, 0, 1), Mode = "Cheer" },
					{ Npc = "Carla", Place = "PlazaCentro", Offset = V(-2, 0, -1), Mode = "Cheer" },
				} },
			{ Type = "Scene", Dialogue = "Concierto",
				Actors = {
					{ Npc = "Pablo", Place = "PlazaCentro", Offset = V(0, 0, 6) },
					{ Npc = "Julia", Place = "PlazaCentro", Offset = V(-4, 0, 1), Mode = "Cheer" },
					{ Npc = "Adrian", Place = "PlazaCentro", Offset = V(4, 0, 1), Mode = "Cheer" },
					{ Npc = "Carla", Place = "PlazaCentro", Offset = V(-2, 0, -1), Mode = "Cheer" },
				} },
		},
		Dialogues = {
			Concierto = { Lines = {
				{ S = "Pablo", T = "¡Gracias por venir! Esta canción empezó como la intro de un trabajo de clase. Se llama «Grupo cuatro»." },
				{ S = "Narrador", T = "La plaza se llena. Julia graba con el móvil. Adrián, por primera vez, no mira el reloj. Carla ha traído a su hermano." },
				{ S = "Pablo", T = "He hablado con mis padres. Voy a terminar la carrera… y a estudiar música a la vez. Alguien me dijo que lo mío también servía." },
				{ Ask = "¿Qué le dices al final?", Options = {
					{ T = "«La próxima vez, en un escenario de verdad.»", Effects = { Rel = { Pablo = 8 } }, Then = {
						{ S = "Pablo", T = "Trato. Y tú en primera fila." },
					} },
					{ T = "Le pides otra. Todo el grupo grita «¡OTRA!»", Effects = { Rel = { Pablo = 6, Julia = 2, Adrian = 2, Carla = 2 }, Traits = { Humor = 1 } }, Then = {
						{ S = "Pablo", T = "¿Otra? Solo me sé tres. …Vale, la primera otra vez." },
					} },
				} },
			} },
		},
	},
}
