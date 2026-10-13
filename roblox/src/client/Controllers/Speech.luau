-- Speech (cliente): el motor de las voces sintetizadas (AudioTextToSpeech de Roblox).
-- Lo usan StoryAudio (la historia: conversaciones, escenas, cinemáticas) y SoundFx (la gente de la calle,
-- los avisos por megafonía). Cada voz la decide shared/LifeStory/CastVoices.
--
--   * 2D o con posición: sin `At`, la voz va directa a los altavoces (AudioDeviceOutput). Con `At` (la
--     cabeza de quien habla) suena desde ahí: AudioEmitter en esa pieza → un AudioListener propio en la
--     cámara (grupo "Voces", así no se mezcla con el chat de voz) → los altavoces.
--   * Límite de Roblox: 1 + 6 × jugadores frases nuevas por minuto en todo el juego y 4 por segundo por
--     jugador. Aquí: como mucho Config.Audio.Voices.PerMinute frases nuevas por minuto; la gente de la
--     calle solo habla si sobra (StreetReserve). Lo ya dicho se repite sin pedirlo otra vez (Cache).
--   * Si una frase no se puede generar (LoadAsync ≠ Success, límite, red…), se avisa UNA vez en la
--     consola y se espera un poco (4 s, 8 s, 16 s… hasta 60 s) antes de volver a probar. Nunca se apaga
--     para siempre: la siguiente frase después de la espera lo intenta otra vez.
--   * Volumen de las voces (menú: 🗣️ Voces): Speech.setVolume(0 … 1). Con 0 no se pide nada.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage.Shared.Config)
local CastVoices = require(ReplicatedStorage.Shared.LifeStory.CastVoices)

local VOICES = Config.Audio.Voices
local GROUP = "Voces" -- AudioInteractionGroup de los emisores y el oyente de las voces

local Speech = {}

export type Handle = { Stop: () -> (), Done: () -> boolean, Length: number, Spatial: boolean }
export type Options = {
	At: Instance?, -- pieza o Attachment desde donde suena (nil = 2D)
	Volume: number?, -- multiplicador (1 = normal)
	Kind: string?, -- "Story" (por defecto) o "Street" (solo si sobra cupo)
	Range: number?, -- studs hasta donde se oye (con At)
	Cancelled: (() -> boolean)?, -- se mira al acabar de generar: true = ya no hace falta
}

local volumeScale = 1
local requests: { number } = {} -- cuándo se pidió cada frase nueva (último minuto)
local lastRequest = -math.huge
local backoffUntil = 0
local failures = 0
local warned = false
local unavailable = false -- (el motor no tiene la clase: se vuelve a probar tras la espera)
local stats = { Requested = 0, Loaded = 0, Failed = 0, Cached = 0, Played = 0, Skipped = 0 }

type Entry = { Tts: any, Used: number, Busy: boolean }
local cache: { [string]: Entry } = {}
local cacheCount = 0
local active: { [any]: Handle } = {}

local folder: Instance? = nil
local output: Instance? = nil
local listener: Instance? = nil

local function now(): number
	local clock = (Speech :: any)._clock -- (las pruebas cambian el reloj)
	return if clock then clock() else os.clock()
end

local function holder(): Instance
	if folder and folder.Parent then
		return folder
	end
	local f = SoundService:FindFirstChild("Voces")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Voces"
		f.Parent = SoundService
	end
	folder = f
	return f :: Instance
end

local function speakers(): Instance
	if output and output.Parent then
		return output
	end
	local out = Instance.new("AudioDeviceOutput")
	out.Name = "Altavoces"
	out.Parent = holder()
	output = out
	return out
end

-- El oyente de las voces con posición, en la cámara (se mueve con ella; se vuelve a poner si cambia)
local function ear(): Instance?
	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end
	if listener and listener.Parent == camera then
		return listener
	end
	local ok = pcall(function()
		if listener then
			listener.Parent = camera
		else
			local l = Instance.new("AudioListener")
			l.Name = "OidoVoces"
			l.AudioInteractionGroup = GROUP
			local wire = Instance.new("Wire")
			wire.SourceInstance = l
			wire.TargetInstance = speakers()
			wire.Parent = l
			l.Parent = camera
			listener = l
		end
	end)
	return if ok then listener else nil
end

local function prune()
	local cutoff = now() - 60
	local i = 1
	while i <= #requests do
		if requests[i] < cutoff then
			table.remove(requests, i)
		else
			i += 1
		end
	end
end

-- ¿Se puede pedir una frase nueva ahora?
function Speech.canRequest(kind: string?): boolean
	if volumeScale <= 0 or VOICES.TextToSpeech == false then
		return false
	end
	if now() < backoffUntil then
		return false
	end
	prune()
	local limit = if kind == "Street" then (VOICES.StreetReserve or 3) else (VOICES.PerMinute or 10)
	return #requests < limit
end

local function evict()
	while cacheCount > (VOICES.Cache or 40) do
		local oldestKey, oldest = nil, math.huge
		for key, entry in cache do
			if not entry.Busy and entry.Used < oldest then
				oldestKey, oldest = key, entry.Used
			end
		end
		if not oldestKey then
			return
		end
		local entry = cache[oldestKey]
		cache[oldestKey] = nil
		cacheCount -= 1
		pcall(function()
			entry.Tts:Destroy()
		end)
	end
end

local function fail(reason: string)
	stats.Failed += 1
	failures += 1
	backoffUntil = now() + math.min(60, 4 * 2 ^ (failures - 1))
	if not warned then
		warned = true
		warn(("[Speech] Voz sintetizada no disponible ahora (%s); se ven los subtítulos y se vuelve a probar en unos segundos"):format(reason))
	end
end

-- Genera (o reutiliza) el audio de una frase. Devuelve la instancia y si es de la caché.
local function generate(text: string, voice: CastVoices.Voice, kind: string?): (any?, Entry?)
	local key = CastVoices.key(text, voice)
	local entry = cache[key]
	if entry and not entry.Busy then
		local loaded = false
		pcall(function()
			loaded = entry.Tts.IsLoaded
		end)
		if loaded then
			stats.Cached += 1
			entry.Used = now()
			return entry.Tts, entry
		end
		cache[key] = nil
		cacheCount -= 1
		pcall(function()
			entry.Tts:Destroy()
		end)
	end
	if not Speech.canRequest(kind) then
		stats.Skipped += 1
		return nil, nil
	end
	-- 4 por segundo por jugador como mucho (se deja aire)
	local gap = lastRequest + 0.3 - now()
	if gap > 0 then
		task.wait(gap)
	end
	lastRequest = now()
	table.insert(requests, now())
	stats.Requested += 1
	local tts: any = nil
	local okCreate, createErr = pcall(function()
		tts = Instance.new("AudioTextToSpeech")
		tts.Text = text
		tts.VoiceId = voice.VoiceId
		tts.Pitch = voice.Pitch
		tts.Speed = voice.Speed
		pcall(function()
			tts.AutoLocalize = VOICES.AutoLocalize == true
		end)
		tts.Parent = holder()
	end)
	if not okCreate then
		unavailable = true
		if tts then
			pcall(function()
				tts:Destroy()
			end)
		end
		fail("AudioTextToSpeech: " .. tostring(createErr))
		return nil, nil
	end
	local status: any = nil
	local okLoad, loadErr = pcall(function()
		status = tts:LoadAsync()
	end)
	local loaded = false
	pcall(function()
		loaded = tts.IsLoaded
	end)
	if not okLoad or (status ~= Enum.AssetFetchStatus.Success and not loaded) then
		pcall(function()
			tts:Destroy()
		end)
		fail(if okLoad then "LoadAsync: " .. tostring(status) else tostring(loadErr))
		return nil, nil
	end
	unavailable = false
	failures = 0
	stats.Loaded += 1
	local fresh: Entry = { Tts = tts, Used = now(), Busy = false }
	if not cache[key] then
		cache[key] = fresh
		cacheCount += 1
		evict()
		return tts, fresh
	end
	return tts, nil -- (otra igual se estaba generando a la vez: esta se tira al acabar)
end

local function curve(range: number, street: boolean): { [number]: number }
	if street then
		return { [0] = 1, [10] = 0.85, [range] = 0.4, [range * 1.6] = 0 }
	end
	return { [0] = 1, [math.min(30, range * 0.4)] = 1, [range] = 0.6, [range * 1.5] = 0 }
end

-- Dice `text` con `voice`. Se queda esperando mientras se genera (llámalo dentro de task.spawn).
-- Devuelve el Handle (Stop para cortarla) o nil si no ha sonado.
function Speech.say(text: string, voice: CastVoices.Voice, opts: Options?): Handle?
	local o: Options = opts or {}
	local speakable = CastVoices.speakable(text)
	if not speakable or volumeScale <= 0 then
		return nil
	end
	local tts, entry = generate(speakable, voice, o.Kind)
	if not tts then
		return nil
	end
	local cancelled = (o.Cancelled and o.Cancelled()) or volumeScale <= 0
	if cancelled then
		if not entry then
			pcall(function()
				tts:Destroy()
			end)
		end
		return nil
	end
	if entry then
		entry.Busy = true
	end
	local pieces: { Instance } = {}
	local spatial = false
	local okPlay = pcall(function()
		tts.Volume = math.clamp((VOICES.Volume or 1) * volumeScale * (o.Volume or 1), 0, 3)
		tts.TimePosition = 0
		local target: Instance = speakers()
		local at = o.At
		if at and at.Parent and (at:IsA("BasePart") or at:IsA("Attachment")) and ear() then
			local emitter = Instance.new("AudioEmitter")
			emitter.Name = "VozEmisor"
			emitter.AudioInteractionGroup = GROUP
			local range = o.Range or VOICES.Range or 90
			pcall(function()
				emitter:SetDistanceAttenuation(curve(range, o.Kind == "Street"))
			end)
			emitter.Parent = at
			table.insert(pieces, emitter)
			target = emitter
			spatial = true
		end
		local wire = Instance.new("Wire")
		wire.SourceInstance = tts
		wire.TargetInstance = target
		wire.Parent = tts
		table.insert(pieces, wire)
		tts:Play()
	end)
	local finished = false
	local length = 0
	pcall(function()
		length = tts.TimeLength
	end)
	local handle: Handle
	local function stop()
		if finished then
			return
		end
		finished = true
		active[handle] = nil
		pcall(function()
			tts:Pause()
		end)
		for _, piece in pieces do
			pcall(function()
				piece:Destroy()
			end)
		end
		if entry then
			entry.Busy = false
		else
			pcall(function()
				tts:Destroy()
			end)
		end
	end
	handle = {
		Stop = stop,
		Done = function()
			return finished
		end,
		Length = length,
		Spatial = spatial,
	}
	if not okPlay then
		stop()
		fail("Play")
		return nil
	end
	stats.Played += 1
	active[handle] = handle
	pcall(function()
		tts.Ended:Once(stop)
	end)
	task.delay(math.clamp(if length > 0 then length + 0.4 else #speakable * 0.08 + 1, 1, 30), stop)
	return handle
end

-- Corta todas las voces que suenen
function Speech.stopAll()
	for handle in active do
		pcall(handle.Stop)
	end
end

-- Volumen de las voces (0 … 1; 0 = sin voces y no se pide nada)
function Speech.setVolume(value: number)
	volumeScale = math.clamp(tonumber(value) or 1, 0, 1)
	if volumeScale <= 0 then
		Speech.stopAll()
	end
end

function Speech.getVolume(): number
	return volumeScale
end

-- ¿Suena alguna voz ahora? (la gente de la calle no habla encima de la historia)
function Speech.busy(): boolean
	return next(active) ~= nil
end

-- Lo que ha pasado (para pruebas y DebugHud)
function Speech.state(): { [string]: any }
	prune()
	return {
		Requests = #requests,
		Backoff = math.max(0, backoffUntil - now()),
		Failures = failures,
		Unavailable = unavailable,
		Cached = cacheCount,
		Volume = volumeScale,
		Stats = table.clone(stats),
	}
end

-- La voz del jugador local para un personaje (con la familia de su casa y su género)
function Speech.voiceFor(who: string?): CastVoices.Voice
	local player = Players.LocalPlayer
	local attrs = if player
		then {
			FamilyKey = player:GetAttribute("FamilyKey"),
			AbuKey = player:GetAttribute("AbuKey"),
			Gender = player:GetAttribute("Gender"),
			LifeStage = player:GetAttribute("LifeStage"),
		}
		else nil
	return CastVoices.resolve(who, attrs)
end

-- (para las pruebas: empezar de cero)
function Speech._reset()
	Speech.stopAll()
	for _, entry in cache do
		pcall(function()
			entry.Tts:Destroy()
		end)
	end
	table.clear(cache)
	cacheCount = 0
	table.clear(requests)
	lastRequest = -math.huge
	backoffUntil, failures, warned, unavailable = 0, 0, false, false
	for k in stats do
		stats[k] = 0
	end
	volumeScale = 1
end

return Speech
