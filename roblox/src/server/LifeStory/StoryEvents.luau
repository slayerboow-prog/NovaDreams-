-- StoryEvents: el "tablón de anuncios" entre los sistemas y la historia de vida.
-- Cualquier sistema avisa de lo que hace un jugador sin saber nada de misiones:
--   StoryEvents.emit(player, "JobTaskDone", { JobId = "Barista" })
-- y LifeStoryService decide si eso hace avanzar algo de su vida.
-- Así la historia es una capa encima de los demás sistemas y no los duplica.
--
-- Eventos que existen hoy: JobTaskDone, Ate, Slept, HomeClaimed, Traveled.
-- Eventos previstos: Talk (NPC), LessonCompleted, ExamGraded, RecessStarted, RoomVisited...

local StoryEvents = {}

type Listener = (Player, string, { [string]: any }) -> ()
local listeners: { Listener } = {}

function StoryEvents.emit(player: Player, name: string, payload: { [string]: any }?)
	for _, listener in listeners do
		task.spawn(listener, player, name, payload or {})
	end
end

function StoryEvents.connect(listener: Listener)
	table.insert(listeners, listener)
end

return StoryEvents
