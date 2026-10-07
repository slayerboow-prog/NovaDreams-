-- GuionOverlay: el GUION REESCRITO de las misiones encima de sus datos de siempre.
--
-- Las misiones reescritas (docs/historia/reescritura/<IdMision>.md) se convierten con
--   lune run scripts/audit/aplicar-reescritura.luau <IdMision>
-- en un módulo de datos generado, Guiones/<IdMision>.luau (no se edita a mano), con:
--   Steps     = { ["n"] | ["n.m"] = { Set = { campo = valor }, Effects = { … } } }
--               cambios de un paso (n.m = el hijo m de un Group): Set sustituye campos (el Id de su
--               cinemática, el texto del objetivo…) y Effects se suma a los efectos del paso (la escena
--               ligera que suena al cumplirlo: Effects.Scene). La MECÁNICA del paso (tipo, lugar,
--               evento, objeto…) no se toca nunca.
--   Dialogues = { [Nombre] = { Lines = { … } } }  las frases nuevas de una conversación (se cambian las
--               líneas; lo demás del diálogo, como sus Effects, se queda)
--   Mission   = { Set = { … } }   campos de la misión (el texto del momento de la biografía…)
--   Scenes    = { [Id] = escena del motor }   las cinemáticas y escenas ligeras nuevas (Sequencer);
--               las publica Happenings/Guion
-- Quests.luau lo aplica al cargar (GuionOverlay.apply). Sin módulo para una misión, no cambia nada.

local GuionOverlay = {}

-- BEGIN GUIONES (lo rellena scripts/audit/aplicar-reescritura.luau: no lo cambies a mano)
GuionOverlay.List = {
	"Prologo_Sueno",
}
-- END GUIONES

local loaded: { [string]: { [string]: any } }? = nil

function GuionOverlay.all(): { [string]: { [string]: any } }
	if loaded then
		return loaded
	end
	local out: { [string]: { [string]: any } } = {}
	local folder = (script.Parent :: any).Guiones
	for _, id in GuionOverlay.List do
		local ok, def = pcall(function()
			return require(folder[id])
		end)
		if ok and type(def) == "table" then
			out[id] = def
		else
			warn(("[GuionOverlay] No se pudo cargar el guion de '%s': %s"):format(id, tostring(def)))
		end
	end
	loaded = out
	return out
end

-- Todas las escenas nuevas de los guiones (Happenings/Guion)
function GuionOverlay.scenes(): { [string]: { [string]: any } }
	local out = {}
	for _, def in GuionOverlay.all() do
		for id, scene in def.Scenes or {} do
			out[id] = scene
		end
	end
	return out
end

local function merged(base: { [string]: any }?, extra: { [string]: any }): { [string]: any }
	local out = if base then table.clone(base) else {}
	for key, value in extra do
		if type(value) == "table" and type(out[key]) == "table" and #value > 0 and #out[key] > 0 then
			-- (listas: Flags, Memory… se suman sin repetir)
			local list = table.clone(out[key])
			for _, item in value do
				if not table.find(list, item) then
					table.insert(list, item)
				end
			end
			out[key] = list
		elseif type(value) == "table" and type(out[key]) == "table" and #value == 0 and #out[key] == 0 then
			out[key] = merged(out[key], value)
		else
			out[key] = value
		end
	end
	return out
end

-- El paso "n" o "n.m" de una lista de pasos (y la lista donde está, para cambiarlo por su copia)
local function stepSlot(steps: { any }, path: string): ({ any }?, number?)
	local list, index = steps, nil
	for part in path:gmatch("[^%.]+") do
		local n = tonumber(part)
		if not n or type(list) ~= "table" then
			return nil, nil
		end
		if index then
			local parent = list[index]
			list = parent and parent.Steps
			if type(list) ~= "table" then
				return nil, nil
			end
		end
		index = n
	end
	if list and index and type(list[index]) == "table" then
		return list, index
	end
	return nil, nil
end

-- Aplica el guion de una misión (devuelve la lista de lo que no pudo aplicar)
function GuionOverlay.applyTo(quest: { [string]: any }, def: { [string]: any }): { string }
	local problems = {}
	for path, patch in def.Steps or {} do
		local list, index = stepSlot(quest.Steps or {}, tostring(path))
		if not list or not index then
			table.insert(problems, ("paso %s: no existe"):format(tostring(path)))
			continue
		end
		local step = table.clone(list[index]) -- (copia: hay pasos compartidos entre misiones)
		for key, value in patch.Set or {} do
			step[key] = value
		end
		if patch.Effects then
			step.Effects = merged(step.Effects, patch.Effects)
		end
		list[index] = step
	end
	if def.Dialogues then
		quest.Dialogues = if quest.Dialogues then table.clone(quest.Dialogues) else {}
		for name, patch in def.Dialogues do
			local base = quest.Dialogues[name]
			local dialogue = if type(base) == "table" then table.clone(base) else {}
			if type(base) == "table" and base.Lines == nil and #base > 0 then
				dialogue = {} -- (diálogo escrito como lista de líneas)
			end
			for key, value in patch do
				dialogue[key] = value
			end
			quest.Dialogues[name] = dialogue
		end
	end
	if def.Mission then
		for key, value in def.Mission.Set or {} do
			quest[key] = value
		end
	end
	return problems
end

function GuionOverlay.apply(quests: { [string]: any })
	for id, def in GuionOverlay.all() do
		local quest = quests[id]
		if not quest then
			warn(("[GuionOverlay] El guion '%s' es de una misión que no existe"):format(id))
			continue
		end
		quest.Steps = table.clone(quest.Steps or {})
		for i, step in quest.Steps do
			if type(step) == "table" and type(step.Steps) == "table" then
				local copy = table.clone(step)
				copy.Steps = table.clone(step.Steps)
				quest.Steps[i] = copy
			end
		end
		for _, problem in GuionOverlay.applyTo(quest, def) do
			warn(("[GuionOverlay] %s: %s"):format(id, problem))
		end
		quest.Guion = def.Source or true
	end
end

return GuionOverlay
