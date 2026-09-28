-- StoryState: lo que se sabe de la vida del jugador, en un solo sitio y solo para leer.
-- Encima de los datos guardados (data.Life, data.Story, data.Education, data.Items…), para que
-- las frases sueltas, los saludos y las condiciones de los diálogos pregunten siempre igual y
-- nunca den por hecho algo que no pasó ("¡qué final el del torneo!" sin haber jugado el torneo).
--
--   local s = StoryState.of(data)
--   s.stage(), s.age(), s.chapter()
--   s.completed("Cole08_Torneo"), s.active("Cole02_Mochila"), s.activeMissions(), s.completedCount()
--   s.flag("AyudasteAMateo"), s.flags(), s.decision("Club"), s.decisions()
--   s.rel("Mateo"), s.relationships(), s.knows("Nico"), s.fact("Nico", "SeConocen")
--   s.memory("PrimerAmigo"), s.trait("Empatia"), s.item("MochilaCole"), s.unlocked("Playa")
--   s.job(), s.studies(), s.degrees()
--   s.check(condición)  -> lo mismo que Conditions.check (Flags, Completed, Choices, Rel, Memories…)
-- No cambia nada: para cambiar la historia están los efectos de LifeStoryService.

local Conditions = require(script.Parent.Conditions)

local StoryState = {}

export type View = { [string]: any }

local EMPTY = table.freeze({})

function StoryState.of(data: { [string]: any }?): View
	local life = (data and data.Life) or EMPTY
	local story = (data and data.Story) or EMPTY
	local education = (data and data.Education) or EMPTY
	local items = (data and data.Items) or EMPTY
	local completed = story.Completed or EMPTY
	local active = story.Active or EMPTY
	local flags = story.Flags or EMPTY
	local choices = story.Choices or EMPTY
	local memory = story.NpcMemory or EMPTY
	local memories = story.Memories or EMPTY
	local traits = story.Traits or EMPTY
	local discovered = story.Discovered or EMPTY
	local skipped = story.Skipped or EMPTY

	local s = {}
	function s.stage(): string?
		return life.Stage
	end
	function s.age(): number?
		return life.AgeYears
	end
	function s.chapter(): string?
		return story.Chapter
	end
	-- Terminada DE VERDAD (una misión saltada por datos rotos no cuenta como vivida)
	function s.completed(questId: string): boolean
		return completed[questId] ~= nil and skipped[questId] == nil
	end
	function s.active(questId: string): boolean
		return active[questId] ~= nil
	end
	function s.activeMissions(): { string }
		local list = {}
		for id in active do
			table.insert(list, id)
		end
		table.sort(list)
		return list
	end
	function s.completedCount(): number
		local n = 0
		for _ in completed do
			n += 1
		end
		return n
	end
	function s.flag(name: string): boolean
		return flags[name] == true
	end
	function s.flags(): { string }
		local list = {}
		for name, on in flags do
			if on then
				table.insert(list, name)
			end
		end
		return list
	end
	function s.decision(key: string): any
		local choice = choices[key]
		return choice and choice.V
	end
	function s.decisions(): { [string]: any }
		local out = {}
		for key, choice in choices do
			out[key] = type(choice) == "table" and choice.V or choice
		end
		return out
	end
	function s.rel(npc: string): number
		local entry = memory[npc]
		return (entry and entry.Rel) or 0
	end
	function s.relationships(): { [string]: number }
		local out = {}
		for npc, entry in memory do
			if entry.Rel and entry.Rel ~= 0 then
				out[npc] = entry.Rel
			end
		end
		return out
	end
	function s.fact(npc: string, fact: string): boolean
		local entry = memory[npc]
		return entry ~= nil and entry.Facts ~= nil and entry.Facts[fact] ~= nil
	end
	-- ¿Os conocéis? (habéis hablado, tenéis relación o recuerda algo de ti)
	function s.knows(npc: string): boolean
		local entry = memory[npc]
		if not entry then
			return false
		end
		return (entry.Rel or 0) ~= 0 or (entry.Affinity or 0) > 0 or (entry.Facts ~= nil and next(entry.Facts) ~= nil)
	end
	function s.memory(key: string): boolean
		return memories[key] ~= nil
	end
	function s.trait(name: string): number
		return traits[name] or 0
	end
	function s.item(id: string): number
		return items[id] or 0
	end
	function s.unlocked(placeId: string): boolean
		return discovered[placeId] == true
	end
	function s.studies(): string?
		return s.decision("Estudios")
	end
	function s.degrees(): { string }
		local list = {}
		for id in education.Degrees or EMPTY do
			table.insert(list, id)
		end
		table.sort(list)
		return list
	end
	function s.job(): string?
		-- La carrera con más puntos (data.Careers, CareerService)
		local best, bestPoints = nil, 0
		for id, entry in (data and data.Careers) or EMPTY do
			local points = if type(entry) == "number" then entry elseif type(entry) == "table" then (entry.Points or entry.Xp or 0) else 0
			if type(points) == "number" and points > bestPoints then
				best, bestPoints = id, points
			end
		end
		return best
	end
	function s.check(condition: { [string]: any }?): boolean
		if not condition then
			return true
		end
		local rel = {}
		for npc, entry in memory do
			rel[npc] = entry.Rel or 0
		end
		-- Completed sin las saltadas
		local done = {}
		for id, value in completed do
			if not skipped[id] then
				done[id] = value
			end
		end
		return (Conditions.check(condition, {
			Rel = rel,
			Traits = traits,
			Memories = memories,
			Stage = life.Stage,
			ClockTime = 12,
			Weekday = 1,
			Completed = done,
			Flags = flags,
			Choices = choices,
			Discovered = discovered,
			StageProgress = 1,
		}))
	end
	return table.freeze(s)
end

return StoryState
