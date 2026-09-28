-- Log: avisos de desarrollo ordenados por categoría, para saber qué pasa en una partida.
--   Log.info("MISSION", "started %s (%s)", questId, player.Name)  ->  [MISSION] started Cole01 (Leo)
--   Log.warn("NPC", "stuck %s", npc)   Log.error("VALIDATE", "…")   Log.debug("SCENE", "…")
--
-- Categorías de siempre: MISSION, OBJECTIVE, NPC, DIALOGUE, SCENE, WATCHDOG, VALIDATE, DEBUG.
-- Niveles: Debug < Info < Warn < Error. En el juego publicado solo salen los Warn y Error (salvo
-- que Config.Debug.DevLogs esté activado); en Studio sale todo desde Info.
-- Cada mensaje igual (misma categoría y mismo formato) sale como mucho RateLimit veces cada
-- RateWindow segundos; los que se callan se cuentan y se dicen luego ("(+12 iguales)").
-- Los últimos mensajes se guardan (Log.recent) para el panel de depuración del dueño.

local RunService = game:GetService("RunService")

local Config = require(script.Parent.Config)

local Log = {}

Log.Levels = { Debug = 1, Info = 2, Warn = 3, Error = 4 }
Log.RateLimit = 5
Log.RateWindow = 10
Log.HistorySize = 200

local debugConfig = Config.Debug or {}

local function studio(): boolean
	local ok, result = pcall(function()
		return RunService:IsStudio()
	end)
	return ok and result == true
end

-- Nivel mínimo que se escribe
Log.level = if debugConfig.DevLogs or studio()
	then (Log.Levels[debugConfig.LogLevel or "Info"] or Log.Levels.Info)
	else Log.Levels.Warn

-- Dónde se escribe (las pruebas lo cambian para leer los avisos): sink(level, category, text)
Log.sink = nil :: ((string, string, string) -> ())?

local history: { { L: string, C: string, T: string, At: number } } = {}
local buckets: { [string]: { Start: number, Count: number, Dropped: number } } = {}

local function emit(levelName: string, category: string, fmt: string, ...)
	local level = Log.Levels[levelName]
	local ok, text = pcall(string.format, fmt, ...)
	if not ok then
		text = fmt
	end
	-- Siempre a la memoria (el panel de depuración ve también lo que no se imprime)
	table.insert(history, { L = levelName, C = category, T = text, At = os.clock() })
	if #history > Log.HistorySize then
		table.remove(history, 1)
	end
	if level < Log.level then
		return
	end
	-- Límite: el mismo mensaje no llena la consola
	local key = category .. "|" .. fmt
	local now = os.clock()
	local bucket = buckets[key]
	if not bucket or now - bucket.Start > Log.RateWindow then
		local dropped = if bucket then bucket.Dropped else 0
		bucket = { Start = now, Count = 0, Dropped = 0 }
		buckets[key] = bucket
		if dropped > 0 then
			text ..= (" (+%d iguales)"):format(dropped)
		end
	end
	bucket.Count += 1
	if bucket.Count > Log.RateLimit then
		bucket.Dropped += 1
		return
	end
	local line = ("[%s] %s"):format(category, text)
	if Log.sink then
		Log.sink(levelName, category, line)
	elseif level >= Log.Levels.Warn then
		warn(line)
	else
		print(line)
	end
end

function Log.debug(category: string, fmt: string, ...)
	emit("Debug", category, fmt, ...)
end

function Log.info(category: string, fmt: string, ...)
	emit("Info", category, fmt, ...)
end

function Log.warn(category: string, fmt: string, ...)
	emit("Warn", category, fmt, ...)
end

function Log.error(category: string, fmt: string, ...)
	emit("Error", category, fmt, ...)
end

-- Los últimos mensajes (los más nuevos al final); category opcional para filtrar
function Log.recent(count: number?, category: string?): { string }
	local out = {}
	for i = #history, 1, -1 do
		local entry = history[i]
		if not category or entry.C == category then
			table.insert(out, 1, ("[%s] %s"):format(entry.C, entry.T))
			if #out >= (count or 20) then
				break
			end
		end
	end
	return out
end

-- Vaciar el límite y la memoria (pruebas)
function Log.reset()
	table.clear(history)
	table.clear(buckets)
end

return Log
