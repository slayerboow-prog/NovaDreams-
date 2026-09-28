-- Fridge: reglas de las neveras de las casas (FridgeService en el servidor, FridgeUI en el cliente).
--
--   * Mientras vas al colegio o al instituto (etapas Bebe, Nino y Adolescente) vives con tus padres:
--     la nevera de la casa familiar es gratis y sin límite (un momento entre bocado y bocado).
--   * Desde la universidad (AdultoJoven en adelante) hay que comprar la comida en el supermercado y
--     guardarla en la nevera de tu casa, de tu piso o de tu habitación de la residencia. Lo que hay
--     dentro se guarda con tu partida (data.Fridges) y se gasta al comer o al cogerlo.
--   * En casa de otro, solo si estás invitado (su grupo): comes de lo que tenga guardado él.

local Fridge = {}

Fridge.SchoolStages = { Bebe = true, Nino = true, Adolescente = true }
Fridge.MaxStock = 40 -- cosas que caben en una nevera
Fridge.EmptyText = "🧊 La nevera está vacía: compra comida en el supermercado."

-- ¿Come gratis de la nevera de la casa de sus padres? (solo en la etapa del colegio)
function Fridge.freeAtFamily(stage: any): boolean
	return type(stage) == "string" and Fridge.SchoolStages[stage] == true
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
