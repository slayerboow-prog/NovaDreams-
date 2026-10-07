-- MenuLogic: las reglas del menú de comandos que no dibujan nada (funciones puras, se prueban con Lune:
-- scripts/test-commands.luau).
--
--   * orderTargets: el orden de las cosas que tienes delante. Van de la más cercana a la más lejana,
--     PERO sin bailar: lo que ya estaba en la lista conserva su puesto mientras no haya otra cosa
--     claramente más cerca (más de `gap` studs). Antes se reordenaba cada 0,4 s al andar o cuando los
--     compañeros se movían, y el elegido saltaba de sitio.
--   * pickIndex: qué fila queda elegida cuando cambia la lista. Se queda lo que habías elegido si sigue
--     ahí; solo si llevas un rato sin tocar el menú y aparece algo NUEVO delante de ti, pasa a eso.
--   * usable: si un cartel del mapa se puede usar desde el menú ahora (existe, está encendido, está a
--     su distancia y no hay una conversación o una escena en marcha).
--   * bigButton: en el móvil, si el botón grande (el del Atacar) pasa a ser la acción del cartel de
--     delante («Hablar», «Comer», «Coger»…), como en los shooters móviles.
--   * armed: el botón contextual solo hace la acción del cartel si lleva un momento enseñándola. Al
--     pasar junto a algo, el botón grande cambia de «Atacar» a «Comer», «Sentarse»… justo debajo del
--     dedo: un toque que iba para el Atacar (o el que ya estabas dando) no puede usar lo que acaba de
--     aparecer. Nada se usa solo al acercarse: hace falta pulsar el botón cuando ya dice qué hace.

local MenuLogic = {}

MenuLogic.Gap = 4 -- studs: hace falta estar así de más cerca para adelantar a otro en la lista
MenuLogic.IdleReset = 4 -- segundos sin tocar el menú para que lo nuevo de delante pase a elegido
MenuLogic.Slack = 2.5 -- studs de margen sobre la distancia del cartel (se sale de su alcance un poco después)

-- list: cosas con .Distance; keyOf(cosa) -> clave estable; previous: claves en el orden de la última vez.
-- Devuelve la lista ordenada y las claves en ese orden (para la próxima vez).
function MenuLogic.orderTargets<T>(previous: { any }, list: { T }, keyOf: (T) -> any, gap: number?): ({ T }, { any })
	local margin = gap or MenuLogic.Gap
	local byKey = {}
	for _, item in list do
		byKey[keyOf(item)] = item
	end
	local out = {}
	-- 1) Los que ya estaban, en el orden de antes
	for _, key in previous do
		local item = byKey[key]
		if item then
			table.insert(out, item)
			byKey[key] = nil
		end
	end
	-- 2) Los nuevos, por distancia, cada uno en su hueco
	local fresh = {}
	for _, item in list do
		if byKey[keyOf(item)] then
			table.insert(fresh, item)
		end
	end
	table.sort(fresh, function(a: any, b: any)
		return a.Distance < b.Distance
	end)
	for _, item in fresh do
		local at = #out + 1
		for i, other in out do
			if (item :: any).Distance < (other :: any).Distance then
				at = i
				break
			end
		end
		table.insert(out, at, item)
	end
	-- 3) Adelanta a quien esté CLARAMENTE más cerca que el de delante (con margen: no baila)
	for _ = 1, #out do
		local swapped = false
		for i = 1, #out - 1 do
			if (out[i + 1] :: any).Distance < (out[i] :: any).Distance - margin then
				out[i], out[i + 1] = out[i + 1], out[i]
				swapped = true
			end
		end
		if not swapped then
			break
		end
	end
	local keys = {}
	for _, item in out do
		table.insert(keys, keyOf(item))
	end
	return out, keys
end

-- Prioridad de los carteles (atributo PromptPriority del ProximityPrompt; 0 si no tiene): los de más
-- prioridad van delante SIEMPRE (tornos y "Subir al metro" antes que una rata o el interfono que pasen
-- por al lado); dentro de la misma prioridad se respeta el orden que venía (orderTargets). Estable.
function MenuLogic.byPriority<T>(list: { T }, priorityOf: (T) -> number): { T }
	local indexed = {}
	for i, item in list do
		table.insert(indexed, { Item = item, Index = i, Priority = priorityOf(item) })
	end
	table.sort(indexed, function(a, b)
		if a.Priority ~= b.Priority then
			return a.Priority > b.Priority
		end
		return a.Index < b.Index
	end)
	local out = {}
	for _, entry in indexed do
		table.insert(out, entry.Item)
	end
	return out
end

local function isTarget(command: any): boolean
	return command ~= nil and (command.Prompt ~= nil or command.Target == true)
end

-- oldItems/oldIndex: la lista de antes y la fila elegida; newItems: la lista nueva (comandos con .Id);
-- idle: segundos desde la última vez que tocaste el menú. Devuelve la fila elegida en la lista nueva.
function MenuLogic.pickIndex(oldItems: { any }, oldIndex: number, newItems: { any }, idle: number, idleReset: number?): number
	local reset = idleReset or MenuLogic.IdleReset
	if #newItems == 0 then
		return 1
	end
	local keep = oldItems[oldIndex]
	local found: number? = nil
	if keep then
		for i, command in newItems do
			if command.Id == keep.Id then
				found = i
				break
			end
		end
	end
	-- ¿Ha aparecido delante algo que antes no estaba? (y hace rato que no tocas el menú)
	local top = newItems[1]
	local fresh = isTarget(top)
	if fresh then
		for _, command in oldItems do
			if command.Id == top.Id then
				fresh = false
				break
			end
		end
	end
	if idle >= reset and fresh then
		return 1
	end
	if found then
		return found
	end
	-- Lo elegido ya no está: si hace rato que no tocas nada, lo de delante; si no, la misma fila
	if idle >= reset then
		return 1
	end
	return math.clamp(oldIndex, 1, #newItems)
end

-- ¿Se puede usar este cartel ahora? (state: { Exists, Enabled, ServiceEnabled, Busy, Distance, Max })
function MenuLogic.usable(state: { [string]: any }): boolean
	if not state.Exists or not state.Enabled or state.ServiceEnabled == false or state.Busy then
		return false
	end
	if type(state.Distance) == "number" and type(state.Max) == "number" and state.Distance > state.Max + MenuLogic.Slack then
		return false
	end
	return true
end

-- Móvil: ¿el botón grande hace la acción del cartel de delante en lugar de atacar?
-- state: { Touch, Prompt (hay cartel usable), Armed (arma en la mano), Fighting (enemigo fijado o
-- golpes hace nada, o un enemigo de misión a tiro), Busy }. Con un arma sigue siendo «Disparar» (no se
-- deja de disparar por pasar junto a alguien) y en una pelea sigue siendo «Atacar»: en esos casos el
-- cartel va en el botón pequeño de contexto.
function MenuLogic.bigButton(state: { [string]: any }): boolean
	return state.Touch == true and state.Prompt == true and not state.Armed and not state.Fighting and not state.Busy
end

MenuLogic.ArmDelay = 0.4 -- segundos que el botón tiene que llevar enseñando ese cartel

-- ¿Cuenta un toque en el botón contextual? shownAt = cuándo pasó a enseñar este cartel (nil = nunca)
function MenuLogic.armed(shownAt: number?, now: number): boolean
	return type(shownAt) == "number" and now - shownAt >= MenuLogic.ArmDelay
end

-- El texto del botón para un cartel: su ActionText si cabe; si no (o vacío), «Interactuar»
function MenuLogic.promptCaption(actionText: string?): string
	if type(actionText) == "string" and actionText ~= "" and (utf8.len(actionText) or #actionText) <= 12 then
		return actionText
	end
	return "Interactuar"
end

return MenuLogic
