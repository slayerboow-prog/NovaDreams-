-- Fridge: reglas de las neveras de las casas (FridgeService en el servidor, FridgeUI en el cliente).
--
--   * La nevera de la casa de tus padres (casa familiar) es SIEMPRE gratis y sin límite (un momento
--     entre bocado y bocado), a cualquier edad: en casa de papá y mamá siempre se come.
--   * Desde la universidad (AdultoJoven en adelante), en tu propia casa hay que comprar la comida en el
--     supermercado y guardarla en la nevera de tu casa, de tu piso o de tu habitación de la residencia. Lo que hay
--     dentro se guarda con tu partida (data.Fridges) y se gasta al comer o al cogerlo.
--   * En casa de otro, solo si estás invitado (su grupo): comes de lo que tenga guardado él.
--   * Las neveras de tus amigos también son gratis (como en casa de tus padres: «coge lo que quieras»):
--       - la de Cosme (su cocina; atributo FridgeOwner = "Cosme" en la nevera), en cuanto le conoces
--         (Fridge.knowsCosme: ya os habéis tratado en la historia o tienes una de sus marcas);
--       - la de un personaje de la historia que es tu amigo (Fridge.isFriend: relación de al menos
--         Fridge.FriendRel, de -100 a 100, la misma Rel de las misiones): su casa de vecino o una nevera
--         con FridgeOwner = su clave;
--       - la de la casa familiar de otro jugador que es tu amigo de Roblox o de tu grupo.
--     La de un desconocido sigue igual: solo mirar.

local Fridge = {}

Fridge.SchoolStages = { Bebe = true, Nino = true, Adolescente = true }
Fridge.MaxStock = 40 -- cosas que caben en una nevera
Fridge.EmptyText = "🧊 La nevera está vacía: compra comida en el supermercado."

-- ¿Come gratis de la nevera de la casa de sus padres? (solo en la etapa del colegio)
function Fridge.freeAtFamily(stage: any): boolean
	return type(stage) == "string" and Fridge.SchoolStages[stage] == true
end

-- Amigos: desde esta relación (-100..100, la Rel de las misiones: data.Story.NpcMemory) un personaje es tu amigo
Fridge.FriendRel = 20
-- Marcas de la historia que dicen que ya conoces a Cosme (además de haberle tratado: StoryState.knows)
Fridge.CosmeFlags = { "ConociCosme", "AmigoDeCosme", "AyudanteCosme", "PrologoCosme" }

-- ¿Conoces a Cosme? view = StoryState.of(data)
function Fridge.knowsCosme(view: any): boolean
	if not view then
		return false
	end
	if view.knows("Cosme") then
		return true
	end
	for _, flag in Fridge.CosmeFlags do
		if view.flag(flag) then
			return true
		end
	end
	return false
end

-- ¿Ese personaje de la historia es tu amigo? (view = StoryState.of(data))
function Fridge.isFriend(view: any, npc: string?): boolean
	return view ~= nil and type(npc) == "string" and view.rel(npc) >= Fridge.FriendRel
end

-- ¿Comes gratis de la nevera de ese personaje? Cosme: en cuanto le conoces. Los demás: si es tu amigo.
function Fridge.freeAtNpc(view: any, npc: string?): boolean
	if npc == "Cosme" and Fridge.knowsCosme(view) then
		return true
	end
	return Fridge.isFriend(view, npc)
end

-- Cuántas cosas hay dentro
function Fridge.total(stock: { [string]: number }?): number
	local n = 0
	for _, count in stock or {} do
		n += count
	end
	return n
end

-- Guarda `count` de algo (lo que quepa). Devuelve cuántos ha guardado.
function Fridge.store(stock: { [string]: number }, id: string, count: number): number
	local room = Fridge.MaxStock - Fridge.total(stock)
	local n = math.clamp(math.floor(count), 0, math.max(room, 0))
	if n > 0 then
		stock[id] = (stock[id] or 0) + n
	end
	return n
end

-- Saca uno (para comerlo o llevárselo). false si no hay.
function Fridge.take(stock: { [string]: number }, id: string): boolean
	local have = stock[id] or 0
	if have <= 0 then
		return false
	end
	stock[id] = if have > 1 then have - 1 else nil
	return true
end

-- Lo que hay dentro, en orden (para el panel): { { Id, Count } }
function Fridge.list(stock: { [string]: number }?): { { Id: string, Count: number } }
	local out = {}
	for id, count in stock or {} do
		if count > 0 then
			table.insert(out, { Id = id, Count = count })
		end
	end
	table.sort(out, function(a, b)
		return a.Id < b.Id
	end)
	return out
end

-- ¿Se puede guardar en la nevera? (comida de la mochila)
function Fridge.isFood(item: { [string]: any }?): boolean
	return item ~= nil and item.Kind == "Food" and (item.Hunger ~= nil or item.Energy ~= nil)
end

return Fridge
