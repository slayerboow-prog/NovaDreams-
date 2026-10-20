-- Speech (cliente): el motor de las voces sintetizadas (AudioTextToSpeech de Roblox).
-- Lo usan StoryAudio (la historia: conversaciones, escenas, cinemáticas) y SoundFx (la gente de la calle,
-- los NPC que hablan, los avisos por megafonía). Cada voz la decide shared/LifeStory/CastVoices.
--
--   * 2D o con posición: sin `At` (la historia), la voz va directa a los altavoces, como diálogo cercano.
--     Con `At` (los NPC de la calle) suena desde su cabeza: AudioEmitter → un AudioListener propio en tu
--     cabeza (grupo "Voces", no se mezcla con el chat de voz). Todo pasa por un bus: AudioFader (Gain) →
--     AudioLimiter (LimitDb, para que no sature) → AudioDeviceOutput.
--   * Límite de Roblox: 1 + 6 × jugadores frases NUEVAS por minuto en todo el juego (solo: 7) y 4 por
--     segundo por jugador. Pasarse no avisa: LoadAsync devuelve Failure. Por eso aquí se cuenta: como
--     mucho PerPlayer frases nuevas por minuto (+1 si juegas solo). Lo ya dicho se repite gratis (Cache).
--   * La historia manda («de Cosme solo se oía la primera frase», v108): se pasaba del límite (se
--     adelantaban seis frases de golpe y la calle también gastaba), Roblox fallaba, y tras el fallo se
--     esperaba y se tiraba lo que venía. Ahora:
--       - una frase de la historia NUNCA se tira por falta de cupo ni por un fallo: espera su turno (en
--         orden) y suena en cuanto se puede, mientras siga en pantalla (Cancelled); si ya se pasó, no;
--       - la calle y los bocadillos de NPC no piden nada mientras hay historia (conversación, escena,
--         cinemática, una frase esperando) ni StoryQuiet s después;
--       - el adelanto (prefetch) es corto: las 1–2 frases siguientes, y cede el turno a la que se dice;
--       - si Roblox falla y el minuto ya va lleno, se espera a que se libere (no hay castigo creciente);
--         un fallo suelto, 2 s y se vuelve a probar la misma frase.
--     Se avisa UNA vez en la consola si hay que esperar por el límite.
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
	Kind: string?, -- "Story" (por defecto: espera su turno), "Announce" (si hay cupo) o "Street" (solo si
	-- sobra y no hay historia)
	Range: number?, -- studs hasta donde se oye (con At)
	Cancelled: (() -> boolean)?, -- true = ya no hace falta (la frase ya no está en pantalla)
	MaxDelay: number?, -- (opcional) segundos: si está lista más tarde, no se dice
}

local volumeScale = 1
local requests: { number } = {} -- cuándo se pidió cada frase nueva (último minuto)
local lastRequest = -math.huge
local backoffUntil = 0
local failures = 0
local warnedFail = false
local warnedThrottle = false
local unavailable = false
local storyWaiting = 0 -- frases de la historia esperando turno (tienen preferencia sobre todo)
local lastStory = -math.huge -- última vez que la historia pidió o dijo algo
local stats = {
	Requested = 0,
	Loaded = 0,
	Failed = 0,
	Cached = 0,
	Played = 0,
	Skipped = 0,
	Late = 0,
	Prefetched = 0,
	LastDelay = 0,
	Throttled = 0,
	Cancelled = 0,
	StreetBlocked = 0,
}
local pending: { [string]: boolean } = {} -- frases que se están generando ahora mismo

type Entry = { Tts: any, Used: number, Busy: boolean }
local cache: { [string]: Entry } = {}
local cacheCount = 0
local active: { [any]: Handle } = {}

local folder: Instance? = nil
local output: Instance? = nil
local listener: Instance? = nil
local bus: Instance? = nil

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

-- El bus de las voces: ganancia (AudioFader) → limitador (AudioLimiter) → altavoces. La voz sintetizada
-- sale bastante más baja que la música: con AudioTextToSpeech.Volume al máximo (3) aún no bastaba.
local function mixBus(): Instance
	if bus and bus.Parent then
		return bus
	end
	local ok = pcall(function()
		local fader = Instance.new("AudioFader")
		fader.Name = "VocesGanancia"
		fader.Volume = math.clamp(VOICES.Gain or 2, 0, 3)
		fader.Parent = holder()
		local nextStage: Instance = speakers()
		pcall(function()
			local limiter = Instance.new("AudioLimiter")
			limiter.Name = "VocesLimitador"
			limiter.MaxLevel = math.clamp(VOICES.LimitDb or -1, -12, 0)
			limiter.Parent = holder()
			local toOut = Instance.new("Wire")
			toOut.SourceInstance = limiter
			toOut.TargetInstance = speakers()
			toOut.Parent = limiter
			nextStage = limiter
		end)
		local toNext = Instance.new("Wire")
		toNext.SourceInstance = fader
		toNext.TargetInstance = nextStage
		toNext.Parent = fader
		bus = fader
	end)
	return if ok and bus then bus else speakers()
end

-- El oyente de las voces con posición: en la cabeza de tu personaje (te alejas y oyes menos; te
-- acercas y más), o en la cámara si no hay personaje. Se vuelve a poner si cambia (reaparecer).
local function ear(): Instance?
	local character = Players.LocalPlayer and Players.LocalPlayer.Character
	local head = character and character:FindFirstChild("Head")
	local place: Instance? = head or workspace.CurrentCamera
	if not place then
		return nil
	end
	if listener and listener.Parent == place then
		return listener
	end
	local ok = pcall(function()
		if listener then
			listener.Parent = place
		else
			local l = Instance.new("AudioListener")
			l.Name = "OidoVoces"
			l.AudioInteractionGroup = GROUP
			local wire = Instance.new("Wire")
			wire.SourceInstance = l
			wire.TargetInstance = mixBus()
			wire.Parent = l
			l.Parent = place
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

-- Frases nuevas por minuto que puede pedir este jugador (Roblox: 1 + 6 × jugadores en todo el juego)
function Speech.perMinute(): number
	local count = 1
	pcall(function()
		count = #Players:GetPlayers()
	end)
	return (VOICES.PerPlayer or 6) + (if count <= 1 then 1 else 0)
end

-- ¿Hay historia ahora? (conversación, escena, cinemática, o una frase de la historia esperando o
-- recién dicha). Mientras, la calle y los bocadillos de NPC no piden voces.
function Speech.storyBusy(): boolean
	if storyWaiting > 0 or now() - lastStory < (VOICES.StoryQuiet or 20) then
		return true
	end
	local player = Players.LocalPlayer
	if player then
		local ok, busy = pcall(function()
			return player:GetAttribute("InDialogue") == true or player:GetAttribute("InCinematic") == true or player:GetAttribute("InScene") == true
		end)
		if ok and busy then
			return true
		end
	end
	return false
end

-- ¿Se puede pedir una frase nueva ahora?
--   "Story": si queda cupo en el minuto. "Prefetch" y "Announce" (megafonía, gestos): igual, pero solo
--   si no espera ninguna frase de la historia. "Street": solo si no hay historia y sobra (StreetReserve).
function Speech.canRequest(kind: string?): boolean
	if volumeScale <= 0 or VOICES.TextToSpeech == false then
		return false
	end
	if now() < backoffUntil then
		return false
	end
	prune()
	if kind == "Street" then
		if Speech.storyBusy() then
			return false
		end
		return #requests < math.min(VOICES.StreetReserve or 3, Speech.perMinute())
	end
	if (kind == "Prefetch" or kind == "Announce") and storyWaiting > 0 then
		return false
	end
	return #requests < Speech.perMinute()
end

local function evict()
	while cacheCount > (VOICES.Cache or 80) do
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

local function throttled()
	stats.Throttled += 1
	if not warnedThrottle then
		warnedThrottle = true
		warn("[Speech] Límite de voces de Roblox (1 + 6 por jugador y minuto): las frases de la historia esperan su turno")
	end
end

local function fail(reason: string)
	stats.Failed += 1
	failures += 1
	prune()
	if #requests >= Speech.perMinute() - 1 and #requests > 0 then
		-- Casi seguro el límite de Roblox: se espera a que salga del minuto la petición más antigua
		backoffUntil = math.max(backoffUntil, requests[1] + 60)
		throttled()
	else
		backoffUntil = now() + math.min(30, 2 * 2 ^ math.min(failures - 1, 4))
	end
	if not warnedFail then
		warnedFail = true
		warn(("[Speech] Una voz no se pudo generar (%s); se vuelve a probar enseguida"):format(reason))
	end
end

local function wait(seconds: number): number
	return task.wait(seconds)
end

local function cached(key: string): (any?, Entry?)
	local entry = cache[key]
	if entry and not entry.Busy then
		local loaded = false
		pcall(function()
			loaded = entry.Tts.IsLoaded
		end)
		if loaded then
			entry.Used = now()
			return entry.Tts, entry
		end
		cache[key] = nil
		cacheCount -= 1
		pcall(function()
			entry.Tts:Destroy()
		end)
	end
	return nil, nil
end

-- Una petición a Roblox (ya con cupo). Devuelve la instancia y su entrada de la caché, o nil si falla.
local function request(key: string, text: string, voice: CastVoices.Voice): (any?, Entry?)
	pending[key] = true
	-- 4 por segundo por jugador como mucho (se deja aire)
	local gap = lastRequest + 0.3 - now()
	if gap > 0 then
		wait(gap)
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
		pending[key] = nil
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
	pending[key] = nil
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
	return tts, nil -- (otra igual se generó a la vez: esta se tira al acabar)
end

-- Consigue el audio de una frase: de la caché, esperando a la que ya se genera, o pidiéndolo.
--   Story: espera su turno (cupo, fallos) mientras no la cancelen. Street/Prefetch: si no toca, nil.
local function generate(text: string, voice: CastVoices.Voice, kind: string?, cancelled: (() -> boolean)?): (any?, Entry?)
	local key = CastVoices.key(text, voice)
	local story = kind == nil or kind == "Story"
	if story then
		storyWaiting += 1
		lastStory = now()
	end
	local waitedForTurn = false
	local result: any, entry: Entry? = nil, nil
	while true do
		if cancelled and cancelled() then
			stats.Cancelled += 1
			break
		end
		if volumeScale <= 0 then
			break
		end
		local tts, e = cached(key)
		if tts then
			stats.Cached += 1
			result, entry = tts, e
			break
		end
		if pending[key] then
			-- (ya se está generando: el adelanto la pidió) se espera a esa
			wait(0.05)
			continue
		end
		if Speech.canRequest(if story then "Story" else kind) then
			local t, en = request(key, text, voice)
			if t then
				result, entry = t, en
				break
			end
			if not story then
				break
			end
			-- (la historia lo vuelve a intentar con la misma frase en cuanto se pueda)
		elseif not story then
			if kind == "Street" then
				stats.StreetBlocked += 1 -- (la calle calla: historia o sin cupo de sobra)
			else
				stats.Skipped += 1
			end
			break
		else
			if not waitedForTurn then
				waitedForTurn = true
				prune()
				if #requests >= Speech.perMinute() then
					throttled()
				end
			end
			wait(0.2)
		end
	end
	if story then
		storyWaiting -= 1
		lastStory = now()
	end
	return result, entry
end

local function curve(range: number?, street: boolean): { [number]: number }
	local sv = Config.StreetVoices or {}
	if street then
		local near, mid, far = sv.Near or 10, sv.Mid or 25, range or sv.Far or 55
		return { [0] = 1, [near] = 1, [mid] = 0.5, [(mid + far) / 2] = 0.2, [far] = 0 }
	end
	local r = range or 90
	return { [0] = 1, [math.min(30, r * 0.4)] = 1, [r] = 0.6, [r * 1.5] = 0 }
end

-- Dice `text` con `voice`. Se queda esperando mientras se genera o espera turno (llámalo dentro de
-- task.spawn). Devuelve el Handle (Stop para cortarla) o nil si no ha sonado.
function Speech.say(text: string, voice: CastVoices.Voice, opts: Options?): Handle?
	local o: Options = opts or {}
	local speakable = CastVoices.speakable(text)
	if not speakable or volumeScale <= 0 then
		return nil
	end
	local t0 = now()
	local tts, entry = generate(speakable, voice, o.Kind, o.Cancelled)
	local delay = now() - t0
	stats.LastDelay = delay
	if not tts then
		return nil
	end
	local late = o.MaxDelay ~= nil and delay > o.MaxDelay
	if late then
		stats.Late += 1 -- (se queda guardada: si se repite, sonará a tiempo)
	end
	local cancelled = late or (o.Cancelled and o.Cancelled()) or volumeScale <= 0
	if cancelled then
		if not late then
			stats.Cancelled += 1 -- (llegó cuando su frase ya no estaba en pantalla)
		end
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
		local target: Instance = mixBus()
		local at = o.At
		if at and at.Parent and (at:IsA("BasePart") or at:IsA("Attachment")) and ear() then
			local emitter = Instance.new("AudioEmitter")
			emitter.Name = "VozEmisor"
			emitter.AudioInteractionGroup = GROUP
			pcall(function()
				emitter:SetDistanceAttenuation(curve(o.Range, o.Kind == "Street"))
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
	if o.Kind == nil or o.Kind == "Story" then
		lastStory = now()
	end
	active[handle] = handle
	pcall(function()
		tts.Ended:Once(stop)
	end)
	task.delay(math.clamp(if length > 0 then length + 0.4 else #speakable * 0.08 + 1, 1, 30), stop)
	return handle
end

-- Adelanto: genera ya las 1–2 frases que vienen (sin decirlas), en orden. Cede el turno a la frase que
-- se está diciendo y espera cupo (no tira nada por falta de cupo: espera). items = { { Text, Voice } };
-- replace = olvidar lo que quedaba en cola (lo de antes ya pasó). Como mucho Config.Audio.Voices.Prefetch.
local queue: { { Text: string, Voice: CastVoices.Voice } } = {}
local working = false
local queued: { [string]: boolean } = {}
local queueEpoch = 0
local function work()
	if working then
		return
	end
	working = true
	task.spawn(function()
		while #queue > 0 do
			local item = queue[1]
			local key = CastVoices.key(item.Text, item.Voice)
			if volumeScale <= 0 then
				break
			end
			if cache[key] or pending[key] then
				table.remove(queue, 1)
				queued[key] = nil
				continue
			end
			if not Speech.canRequest("Prefetch") then
				-- (sin cupo o con una frase de la historia esperando: el adelanto espera)
				lastStory = now()
				wait(0.25)
				continue
			end
			table.remove(queue, 1)
			queued[key] = nil
			lastStory = now()
			local epoch = queueEpoch
			local tts = request(key, item.Text, item.Voice)
			if tts then
				stats.Prefetched += 1
			end
			if epoch ~= queueEpoch then
				continue
			end
			wait(0)
		end
		working = false
	end)
end

function Speech.prefetch(items: { { Text: string, Voice: CastVoices.Voice } }, replace: boolean?)
	if volumeScale <= 0 or VOICES.TextToSpeech == false then
		return
	end
	if replace then
		table.clear(queue)
		table.clear(queued)
		queueEpoch += 1
	end
	local limit = VOICES.Prefetch or 2
	for _, item in items do
		if #queue >= limit then
			break
		end
		local text = CastVoices.speakable(item.Text)
		if text and item.Voice then
			local key = CastVoices.key(text, item.Voice)
			if not cache[key] and not pending[key] and not queued[key] then
				queued[key] = true
				table.insert(queue, { Text = text, Voice = item.Voice })
			end
		end
	end
	if #queue > 0 then
		lastStory = now()
	end
	work()
end

-- ¿Esta frase ya está lista para sonar sin esperar?
function Speech.ready(text: string, voice: CastVoices.Voice): boolean
	local speakable = CastVoices.speakable(text)
	local entry = speakable and cache[CastVoices.key(speakable, voice)]
	return entry ~= nil and not entry.Busy
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
		PerMinute = Speech.perMinute(),
		Backoff = math.max(0, backoffUntil - now()),
		Failures = failures,
		Unavailable = unavailable,
		Cached = cacheCount,
		Queued = #queue,
		StoryWaiting = storyWaiting,
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
	table.clear(queue)
	table.clear(queued)
	table.clear(pending)
	lastRequest = -math.huge
	lastStory = -math.huge
	storyWaiting = 0
	backoffUntil, failures, warnedFail, warnedThrottle, unavailable = 0, 0, false, false, false
	for k in stats do
		stats[k] = 0
	end
	volumeScale = 1
end

return Speech
