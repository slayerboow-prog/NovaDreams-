-- SceneErrorLog (servidor): los fallos de escena que avisan las pantallas de los jugadores
-- (Controllers/SceneReport → Remotes.Scene "Error"). Fase 3 del sistema de cine.
--
-- * Se limpia otra vez (shared/LifeStory/SceneFaults: sin nombre ni id del jugador) y se apunta en el
--   log del servidor (Log.warn "SCENE"), sin decir de quién es.
-- * Límite por jugador (cubo de fichas: Burst seguidos y luego uno cada RefillSeconds) y límite de todo
--   el servidor por minuto (ServerPerMinute). Lo que se pasa se cuenta (Dropped) pero no se escribe.
-- * Contadores: total, por escena + paso, por fuente y por tipo, y cuántos jugadores distintos han
--   avisado (sin guardar quiénes: solo el número). SceneErrorLog.summary() los da (panel del dueño).
-- * Nada se guarda en el DataStore: vive mientras dura el servidor.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Log = require(ReplicatedStorage.Shared.Log)
local SceneFaults = require(ReplicatedStorage.Shared.LifeStory.SceneFaults)

local SceneErrorLog = {}

SceneErrorLog.Burst = 6
SceneErrorLog.RefillSeconds = 15
SceneErrorLog.ServerPerMinute = 60
SceneErrorLog.MaxKeys = 300 -- claves distintas que se cuentan (las demás van a «Otros»)

type Bucket = { Tokens: number, At: number }

local buckets: { [any]: Bucket } = setmetatable({}, { __mode = "k" }) :: any
local reporters: { [any]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local serverSent: { number } = {}
local counts = {
	Total = 0,
	Logged = 0,
	Dropped = 0,
	Invalid = 0,
	Players = 0,
	ByKey = {} :: { [string]: number },
	BySource = {} :: { [string]: number },
	ByKind = {} :: { [string]: number },
	Keys = 0,
}
SceneErrorLog._clock = os.clock

local function now(): number
	return SceneErrorLog._clock()
end

local function take(player: any): boolean
	local t = now()
	local bucket = buckets[player]
	if not bucket then
		bucket = { Tokens = SceneErrorLog.Burst, At = t }
		buckets[player] = bucket
	end
	bucket.Tokens = math.min(SceneErrorLog.Burst, bucket.Tokens + (t - bucket.At) / SceneErrorLog.RefillSeconds)
	bucket.At = t
	if bucket.Tokens < 1 then
		return false
	end
	for i = #serverSent, 1, -1 do
		if t - serverSent[i] > 60 then
			table.remove(serverSent, i)
		end
	end
	if #serverSent >= SceneErrorLog.ServerPerMinute then
		return false
	end
	bucket.Tokens -= 1
	table.insert(serverSent, t)
	return true
end

local function namesOf(player: any): { string }
	local list = {}
	pcall(function()
		table.insert(list, player.Name)
		table.insert(list, player.DisplayName)
		table.insert(list, tostring(player.UserId))
	end)
	return list
end

-- Un aviso de un jugador. Devuelve el aviso limpio si se ha apuntado en el log (nil si no valía o se
-- pasaba del límite).
function SceneErrorLog.accept(player: any, payload: any): { [string]: string }?
	local report = SceneFaults.normalize(payload, namesOf(player))
	if not report then
		counts.Invalid += 1
		return nil
	end
	counts.Total += 1
	if not take(player) then
		counts.Dropped += 1
		return nil
	end
	if not reporters[player] then
		reporters[player] = true
		counts.Players += 1
	end
	local key = SceneFaults.key(report)
	if counts.ByKey[key] == nil and counts.Keys >= SceneErrorLog.MaxKeys then
		key = "Otros"
	end
	if counts.ByKey[key] == nil then
		counts.Keys += 1
	end
	counts.ByKey[key] = (counts.ByKey[key] or 0) + 1
	counts.BySource[report.Source] = (counts.BySource[report.Source] or 0) + 1
	counts.ByKind[report.Kind] = (counts.ByKind[report.Kind] or 0) + 1
	counts.Logged += 1
	Log.warn("SCENE", "fallo de cliente %s %s/%s/%s (x%d): %s", report.Kind, report.Source, report.Scene, report.Step, counts.ByKey[key], report.Message)
	return report
end

-- Los contadores (copia)
function SceneErrorLog.summary(): { [string]: any }
	return {
		Total = counts.Total,
		Logged = counts.Logged,
		Dropped = counts.Dropped,
		Invalid = counts.Invalid,
		Players = counts.Players,
		ByKey = table.clone(counts.ByKey),
		BySource = table.clone(counts.BySource),
		ByKind = table.clone(counts.ByKind),
	}
end

-- (pruebas) empezar de cero
function SceneErrorLog._reset()
	table.clear(buckets)
	table.clear(reporters)
	table.clear(serverSent)
	counts.Total, counts.Logged, counts.Dropped, counts.Invalid, counts.Players, counts.Keys = 0, 0, 0, 0, 0, 0
	table.clear(counts.ByKey)
	table.clear(counts.BySource)
	table.clear(counts.ByKind)
end

return SceneErrorLog
