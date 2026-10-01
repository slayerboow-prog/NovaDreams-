-- SaveCheck: deja la partida de un jugador lista para el DataStore (sin Roblox: se prueba con Lune).
--
-- Un DataStore guarda JSON y RECHAZA ENTERA la partida (UpdateAsync lanza un error) si dentro hay
-- una sola cosa que no sabe guardar. Si eso pasa, NADA de lo nuevo se guarda: al volver a entrar
-- todo está como en el último guardado bueno (la historia, el sitio, el día…). Lo que no vale:
--   * Vector3, CFrame, Color3, EnumItem, Instance, funciones…
--   * números NaN o infinitos;
--   * tablas "mezcladas": con claves numéricas que no son 1, 2, 3… seguidas (huecos, 0, negativas,
--     decimales) o con claves numéricas y de texto a la vez; claves que no son ni texto ni número;
--   * texto que no es UTF-8 válido;
--   * referencias circulares (una tabla que se contiene a sí misma);
--   * más de 4 MB (4.194.304 caracteres) en total.
--
-- SaveCheck.sanitize(data) devuelve una COPIA guardable y la lista de problemas encontrados:
--   * Vector3/CFrame -> { X, Y, Z }; Color3 -> { R, G, B }; EnumItem -> su nombre;
--   * NaN -> 0; infinito -> ±1e15;
--   * Instance, funciones, ciclos -> se quitan;
--   * tablas con claves numéricas raras -> claves de texto ("5") y la marca NUMKEYS, que
--     SaveCheck.restore deshace al cargar (vuelven a ser números: el código que lee t[5] sigue igual);
--   * texto roto -> los bytes malos se cambian por "?".
-- SaveCheck.encode(data) da el JSON (como lo mediría Roblox) para saber el tamaño.
-- SaveCheck.trim(data, maxChars) recorta historiales (los más antiguos primero) si se pasa de tamaño.

local SaveCheck = {}

SaveCheck.MAX_CHARS = 4194304 -- límite de Roblox por clave
SaveCheck.SOFT_CHARS = 3500000 -- a partir de aquí se recortan historiales (margen de seguridad)
SaveCheck.NUMKEYS = "__NumKeys" -- marca: las claves de esta tabla eran números
local BIG = 1e15

export type Problem = { Path: string, Reason: string }

local function kindOf(value: any): string
	local t = type(value)
	if t == "userdata" or t == "vector" then
		local ok, result = pcall(function()
			return (typeof :: any)(value)
		end)
		return if ok and type(result) == "string" then result else t
	end
	if t == "table" and rawget(value, "ClassName") ~= nil and type(rawget(value, "__props")) == "table" then
		return "Instance" -- (instancias de mentira de las pruebas)
	end
	return t
end

local function validUtf8(s: string): boolean
	return utf8.len(s) ~= nil
end

local function fixUtf8(s: string): string
	if validUtf8(s) then
		return s
	end
	local out = {}
	local i = 1
	local n = #s
	while i <= n do
		local len = utf8.len(s, i, i)
		-- (utf8.len(s, i, i) vale 1 si en i empieza un carácter bueno)
		if len then
			local code = utf8.codepoint(s, i)
			local ch = utf8.char(code)
			table.insert(out, ch)
			i += #ch
		else
			table.insert(out, "?")
			i += 1
		end
	end
	return table.concat(out)
end

local function keyText(key: any): string
	if type(key) == "number" then
		if key == math.floor(key) and math.abs(key) < 2 ^ 53 then
			return string.format("%d", key)
		end
		return tostring(key)
	end
	return tostring(key)
end

-- "array" (1..n seguidas), "dict" (solo texto), "empty" o "mixed"
local function tableShape(t: { [any]: any }): string
	local count, strings, others = 0, 0, 0
	local maxInt = 0
	for key in t do
		count += 1
		if type(key) == "string" then
			strings += 1
		elseif type(key) == "number" and key == math.floor(key) and key >= 1 and key < 2 ^ 31 then
			if key > maxInt then
				maxInt = key
			end
		else
			others += 1
		end
	end
	if count == 0 then
		return "empty"
	end
	if strings == count then
		return "dict"
	end
	if strings == 0 and others == 0 and maxInt == count then
		return "array"
	end
	return "mixed"
end
SaveCheck.tableShape = tableShape

local function join(path: string, key: any): string
	if type(key) == "number" then
		return path .. "[" .. keyText(key) .. "]"
	end
	return if path == "" then tostring(key) else path .. "." .. tostring(key)
end

-- Copia guardable + problemas. (Nunca lanza errores.)
function SaveCheck.sanitize(value: any): (any, { Problem })
	local problems: { Problem } = {}
	local visiting: { [any]: boolean } = {}
	local function note(path: string, reason: string)
		if #problems < 200 then
			table.insert(problems, { Path = if path == "" then "(raíz)" else path, Reason = reason })
		end
	end
	local function clean(v: any, path: string): any
		local kind = kindOf(v)
		if kind == "nil" or kind == "boolean" then
			return v
		elseif kind == "number" then
			if v ~= v then
				note(path, "NaN")
				return 0
			elseif v == math.huge or v == -math.huge then
				note(path, "infinito")
				return if v > 0 then BIG else -BIG
			end
			return v
		elseif kind == "string" then
			if not validUtf8(v) then
				note(path, "texto no UTF-8")
				return fixUtf8(v)
			end
			return v
		elseif kind == "Vector3" or kind == "CFrame" then
			note(path, kind)
			local p = if kind == "CFrame" then v.Position else v
			return { X = clean(p.X, path .. ".X"), Y = clean(p.Y, path .. ".Y"), Z = clean(p.Z, path .. ".Z") }
		elseif kind == "Vector2" then
			note(path, kind)
			return { X = clean(v.X, path .. ".X"), Y = clean(v.Y, path .. ".Y") }
		elseif kind == "Color3" then
			note(path, kind)
			return { R = v.R, G = v.G, B = v.B }
		elseif kind == "EnumItem" then
			note(path, kind)
			return v.Name
		elseif kind == "table" then
			if visiting[v] then
				note(path, "referencia circular")
				return nil
			end
			visiting[v] = true
			local shape = tableShape(v)
			local out = {}
			if shape == "array" then
				for i = 1, #v do
					local c = clean(v[i], join(path, i))
					out[i] = if c == nil then false else c -- (un hueco dejaría la lista "mezclada")
				end
			else
				if shape == "mixed" then
					note(path, "tabla mezclada (claves numéricas sueltas)")
				end
				local numeric = false
				for key, item in v do
					local keyKind = type(key)
					local newKey: string? = nil
					if keyKind == "string" then
						if not validUtf8(key) then
							note(join(path, key), "clave no UTF-8")
							newKey = fixUtf8(key)
						else
							newKey = key
						end
					elseif keyKind == "number" and key == key and math.abs(key) ~= math.huge then
						newKey = keyText(key)
						numeric = true
					else
						note(path, "clave de tipo " .. kindOf(key) .. " (quitada)")
					end
					if newKey ~= nil and newKey ~= SaveCheck.NUMKEYS then
						-- (si ya hay una clave de texto igual, se queda esa)
						if keyKind == "string" or out[newKey] == nil then
							local c = clean(item, join(path, key))
							if c ~= nil then
								out[newKey] = c
							end
						end
					end
				end
				if numeric then
					out[SaveCheck.NUMKEYS] = true
				end
			end
			visiting[v] = nil
			return out
		else
			note(path, "valor de tipo " .. kind .. " (quitado)")
			return nil
		end
	end
	return clean(value, ""), problems
end

-- Solo la lista de problemas (sin copiar)
function SaveCheck.scan(value: any): { Problem }
	local _, problems = SaveCheck.sanitize(value)
	return problems
end

-- Deshace las claves numéricas guardadas como texto (marca NUMKEYS). Modifica la tabla.
function SaveCheck.restore(value: any): any
	if type(value) ~= "table" then
		return value
	end
	if value[SaveCheck.NUMKEYS] ~= nil then
		value[SaveCheck.NUMKEYS] = nil
		local moves = {}
		for key, item in value do
			local n = if type(key) == "string" then tonumber(key) else nil
			if n ~= nil and keyText(n) == key then
				table.insert(moves, { key, n, item })
			end
		end
		for _, m in moves do
			value[m[1]] = nil
			value[m[2]] = m[3]
		end
	end
	for _, item in value do
		SaveCheck.restore(item)
	end
	return value
end

---------------------------------------------------------------------
-- JSON (para medir: el mismo tamaño que contaría Roblox, con las tablas ya limpias)
---------------------------------------------------------------------
local ESCAPES = { ['"'] = '\\"', ["\\"] = "\\\\", ["\b"] = "\\b", ["\f"] = "\\f", ["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t" }
local function encodeString(s: string): string
	return '"' .. string.gsub(s, '[%c"\\]', function(c)
		return ESCAPES[c] or string.format("\\u%04x", string.byte(c))
	end) .. '"'
end

-- JSON de una tabla YA limpia (sanitize). Lanza error si encuentra algo que no se puede guardar.
function SaveCheck.encode(value: any): string
	local parts = {}
	local function emit(v: any)
		local t = type(v)
		if t == "nil" then
			table.insert(parts, "null")
		elseif t == "boolean" then
			table.insert(parts, if v then "true" else "false")
		elseif t == "number" then
			if v ~= v or v == math.huge or v == -math.huge then
				error("número no guardable")
			end
			if v == math.floor(v) and math.abs(v) < 1e15 then
				table.insert(parts, string.format("%d", v))
			else
				table.insert(parts, string.format("%.14g", v))
			end
		elseif t == "string" then
			table.insert(parts, encodeString(v))
		elseif t == "table" then
			local shape = tableShape(v)
			if shape == "array" then
				table.insert(parts, "[")
				for i = 1, #v do
					if i > 1 then
						table.insert(parts, ",")
					end
					emit(v[i])
				end
				table.insert(parts, "]")
			elseif shape == "empty" then
				table.insert(parts, "[]")
			elseif shape == "dict" then
				table.insert(parts, "{")
				local first = true
				for key, item in v do
					if not first then
						table.insert(parts, ",")
					end
					first = false
					table.insert(parts, encodeString(key))
					table.insert(parts, ":")
					emit(item)
				end
				table.insert(parts, "}")
			else
				error("tabla mezclada")
			end
		else
			error("valor no guardable: " .. kindOf(v))
		end
	end
	emit(value)
	return table.concat(parts)
end

function SaveCheck.size(value: any): number
	return #SaveCheck.encode(value)
end

---------------------------------------------------------------------
-- Recorte por tamaño
---------------------------------------------------------------------
-- Historiales que se pueden recortar sin romper nada (los más antiguos primero, al principio de la
-- lista). Si aun así no basta, se recorta la lista más grande que haya.
SaveCheck.Histories = {
	{ "Conduct", "Log" },
	{ "Story", "Events" },
}

local function largestList(root: any): ({ any }?, number)
	local best, bestSize = nil, 0
	local function walk(t: any, depth: number)
		if depth > 12 then
			return
		end
		local shape = tableShape(t)
		if shape == "array" and #t >= 8 and t ~= root.ProcessedReceipts then
			local ok, encoded = pcall(SaveCheck.encode, t)
			local size = if ok then #encoded else 0
			if size > bestSize then
				best, bestSize = t, size
			end
		end
		for _, item in t do
			if type(item) == "table" then
				walk(item, depth + 1)
			end
		end
	end
	walk(root, 0)
	return best, bestSize
end

-- Recorta (en la tabla dada, ya limpia) hasta que quepa en maxChars. Devuelve el tamaño final y
-- cuántos elementos se quitaron.
function SaveCheck.trim(data: any, maxChars: number?): (number, number)
	local limit = maxChars or SaveCheck.SOFT_CHARS
	local size = SaveCheck.size(data)
	local removed = 0
	if size <= limit then
		return size, 0
	end
	local function halve(list: { any })
		local drop = math.max(1, math.floor(#list / 2))
		table.move(list, drop + 1, #list + drop, 1)
		removed += drop
	end
	for _, path in SaveCheck.Histories do
		local list = data
		for _, key in path do
			list = type(list) == "table" and list[key] or nil
		end
		while type(list) == "table" and tableShape(list) == "array" and #list > 10 and size > limit do
			halve(list)
			size = SaveCheck.size(data)
		end
	end
	local guard = 0
	while size > limit and guard < 60 do
		guard += 1
		local list = largestList(data)
		if not list then
			break
		end
		halve(list)
		size = SaveCheck.size(data)
	end
	return size, removed
end

return SaveCheck
