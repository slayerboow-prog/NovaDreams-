-- WorldState: la MEMORIA DEL MUNDO de cada jugador (cuentas puras). Es lo que queda en el mundo por lo
-- que pasó en tu historia: un cráter donde cayó la estrella, una nave aparcada, un objeto que se quedó,
-- un personaje que ahora vive en algún sitio… Se guarda con la partida en data.Story.World
-- (server/Services/WorldMemoryService) y llega al cliente en el atributo WorldState (JSON).
--
-- Claves con prefijo de la historia o del sitio, separadas por puntos: "Cielo.Crater.Parque" = "Humeante",
-- "Granja.Petra" = "Normal", "Rex.Vive" = true… Valores: texto, número, sí/no, o una lista corta de
-- números ({ x, y, z } para una posición). false borra la clave.
--
-- Condiciones (Conditions.check y los decorados de StageSets):
--   World    = { ["Cielo.Crater.Parque"] = "Humeante", ["Rex.Vive"] = true }   (true = existe y no es false)
--   NotWorld = { "Garaje.Cerrado" }  o  { ["Granja.Petra"] = "Gigante" }       (no existe / no vale eso)

local WorldState = {}

WorldState.MAX_KEYS = 200
WorldState.MAX_KEY = 60
WorldState.MAX_TEXT = 80
WorldState.MAX_LIST = 8

-- ¿Clave válida? (texto corto, letras, números, puntos y guiones bajos)
function WorldState.validKey(key: any): boolean
	return type(key) == "string" and #key > 0 and #key <= WorldState.MAX_KEY and key:match("^[%w_%.]+$") ~= nil
end

-- El valor arreglado para guardarlo (nil = no se puede guardar)
function WorldState.clean(value: any): any
	local t = type(value)
	if t == "boolean" then
		return value
	elseif t == "number" then
		if value ~= value or value == math.huge or value == -math.huge then
			return nil
		end
		return value
	elseif t == "string" then
		return if utf8.len(value) then value:sub(1, WorldState.MAX_TEXT) else nil
	elseif t == "table" then
		local list = {}
		for i = 1, math.min(#value, WorldState.MAX_LIST) do
			local n = value[i]
			if type(n) ~= "number" or n ~= n or n == math.huge or n == -math.huge then
				return nil
			end
			list[i] = math.floor(n * 100 + 0.5) / 100
		end
		return if #list > 0 then list else nil
	elseif typeof(value) == "Vector3" then
		return { math.floor(value.X * 100 + 0.5) / 100, math.floor(value.Y * 100 + 0.5) / 100, math.floor(value.Z * 100 + 0.5) / 100 }
	end
	return nil
end

-- Cambia una clave (false o nil la borra). Devuelve true si algo ha cambiado.
function WorldState.set(world: { [string]: any }, key: string, value: any): boolean
	if not WorldState.validKey(key) then
		return false
	end
	if value == false or value == nil then
		if world[key] ~= nil then
			world[key] = nil
			return true
		end
		return false
	end
	local cleaned = WorldState.clean(value)
	if cleaned == nil then
		return false
	end
	if world[key] == nil then
		local count = 0
		for _ in world do
			count += 1
		end
		if count >= WorldState.MAX_KEYS then
			return false
		end
	end
	local before = world[key]
	if type(before) == "table" and type(cleaned) == "table" then
		local same = #before == #cleaned
		for i = 1, #cleaned do
			if before[i] ~= cleaned[i] then
				same = false
			end
		end
		if same then
			return false
		end
	elseif before == cleaned then
		return false
	end
	world[key] = cleaned
	return true
end

-- Aplica varios cambios a la vez ({ [clave] = valor }); devuelve cuántos han cambiado algo
function WorldState.apply(world: { [string]: any }, changes: { [string]: any }?): number
	local changed = 0
	for key, value in changes or {} do
		if WorldState.set(world, key, value) then
			changed += 1
		end
	end
	return changed
end

local function same(have: any, want: any): boolean
	if want == true then
		return have ~= nil and have ~= false
	end
	return have == want
end

-- ¿Se cumple la condición World / NotWorld?
function WorldState.matches(req: { [string]: any }?, world: { [string]: any }?): boolean
	if not req then
		return true
	end
	local w = world or {}
	for key, want in req.World or {} do
		if type(key) == "number" then
			-- lista de claves: { "Rex.Vive" } = que exista
			if not same(w[want], true) then
				return false
			end
		elseif not same(w[key], want) then
			return false
		end
	end
	for key, want in req.NotWorld or {} do
		if type(key) == "number" then
			if same(w[want], true) then
				return false
			end
		elseif same(w[key], want) then
			return false
		end
	end
	return true
end

-- Copia (para mandar o comparar)
function WorldState.copy(world: { [string]: any }?): { [string]: any }
	local out = {}
	for k, v in world or {} do
		out[k] = if type(v) == "table" then table.clone(v) else v
	end
	return out
end

-- Un Vector3 desde una lista guardada { x, y, z }
function WorldState.toVector(value: any): Vector3?
	if type(value) == "table" and type(value[1]) == "number" and type(value[2]) == "number" and type(value[3]) == "number" then
		return Vector3.new(value[1], value[2], value[3])
	end
	return nil
end

return WorldState
