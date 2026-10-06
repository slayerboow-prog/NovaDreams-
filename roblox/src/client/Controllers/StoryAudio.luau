-- StoryAudio (cliente): música, ambiente, efectos y voces de la historia.
--   * Música con fundidos suaves: la de cada cinemática y la de fondo de cada capítulo.
--   * Música por intensidad (Config.Audio.Intensity): Nada, Descubrimiento, Intima, Tension,
--     Resolucion, Tema. Las escenas la piden con StoryAudio.setIntensity y se cruza con la que suene.
--   * Ambiente por tipo de lugar (Config.Audio.Ambience): capas en bucle que suben y bajan con fundido
--     y golpes sueltos (reloj, pitido del monitor, puertas). Si ninguna escena lo pide
--     (StoryAudio.setAmbience), se elige solo según dónde estás: tu casa, una sala de un edificio
--     (workspace.Interiores), cerca del colegio, del hospital, de la facultad, de un parque, o la calle.
--     Nunca silencio absoluto: cada tipo tiene una capa base.
--   * Efectos cortos (sting) para los momentos de vida y los capítulos.
--   * Voces: grabadas si hay (Config.Audio.Voices.Lines) o sintetizadas por Roblox
--     (AudioTextToSpeech) si el motor lo permite. Mientras alguien habla, la música baja.
--   * Música on/off: StoryAudio.setMusicOn / isMusicOn (el interruptor está en el menú del HUD).
--     Silencia los grupos Music y Voice (SoundService), así se calla también lo que ya suena.
--     El ambiente va en el grupo Ambience (lo calla «Sonidos: no», como la lluvia).
-- Los IDs de los audios están en Config.Audio. Con Id = 0 se busca en shared/SoundIds y en
-- ReplicatedStorage.Musica; si no hay, suena su Fallback o nada (sin errores).
--
-- Para las escenas (HappeningClient, pistas Music y Ambience):
--   StoryAudio.setIntensity("Tension")        cruza a la música de esa intensidad ("Nada" = sin música)
--   StoryAudio.setIntensity({ Intensity = "Intima" })   (también vale la tabla de la pista)
--   StoryAudio.setAmbience("hospital")        ambiente de ese tipo (nil o "Auto" = según dónde estás)
--   StoryAudio.clear()                        la escena acaba: vuelve la música del capítulo y el ambiente
--                                             del sitio (también al acabar la cinemática, al morir o si
--                                             la escena se corta: no se queda nada sonando)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Theme = require(script.Parent.Parent.UI.Theme)
local SoundFx = require(script.Parent.SoundFx)

local AUDIO = Config.Audio
local INTENSITY = AUDIO.Intensity or {}
local AMB = AUDIO.Ambience or { Kinds = {} }
local StoryAudio = {}

local muted = false
local folder: Folder? = nil
local current: { Cue: string, Sound: Sound, Volume: number }? = nil
local ambientCue: string? = nil
local chapterCue: string? = nil -- la música que pide el capítulo (nil = ninguna)
local inCinematic = false
local speaking = 0
local ttsAvailable = AUDIO.Voices.TextToSpeech

-- Lo que ha pedido la escena (nil = nada): intensidad de la música y tipo de ambiente
local intensity: string? = nil
local ambOverride: string? = nil
local sceneSet = false -- (lo pidió una escena: se deshace solo si la escena se corta sin avisar)

-- La carpeta de los sonidos (se crea al primer uso: las escenas pueden llamar antes de init)
local function holder(): Instance
	if folder and folder.Parent then
		return folder
	end
	local f = SoundService:FindFirstChild("StoryAudio")
	if not f then
		f = Instance.new("Folder")
		f.Name = "StoryAudio"
		f.Parent = SoundService
	end
	folder = f :: Folder
	return f
end

-- Sin mayúsculas, tildes, espacios, guiones ni puntos ("Íntima" = "intima", "Centro de salud" = "centrodesalud")
local ACCENTS = { ["á"] = "a", ["é"] = "e", ["í"] = "i", ["ó"] = "o", ["ú"] = "u", ["ü"] = "u", ["ñ"] = "n", ["Á"] = "a", ["É"] = "e", ["Í"] = "i", ["Ó"] = "o", ["Ú"] = "u", ["Ñ"] = "n" }
local function simple(text: string): string
	for from, to in ACCENTS do
		text = string.gsub(text, from, to)
	end
	return (string.gsub(string.lower(text), "[%s_%-%.]", ""))
end

-- ID del audio: el de Config.Audio o, si es 0, el del Sound que tenga el mismo nombre que el archivo
-- dentro de ReplicatedStorage.Musica (basta con arrastrar ahí los audios subidos desde el Asset Manager).
local function normalize(name: string): string
	return (string.gsub(string.lower(name), "[%s_%-%.]", ""))
end

local function fromFolder(file: string?): string?
	local musica = file and ReplicatedStorage:FindFirstChild("Musica")
	if not musica or not file then
		return nil
	end
	local wanted = normalize((string.gsub(file, "%.%w+$", "")))
	for _, sound in musica:GetDescendants() do
		if sound:IsA("Sound") and sound.SoundId ~= "" and normalize(sound.Name) == wanted then
			return sound.SoundId
		end
	end
	return nil
end

-- Audios que en esta partida no han cargado (privados, de otro dueño, en revisión, borrados…):
-- no se vuelven a pedir y se usa la copia siguiente o la pieza de reserva (Fallback)
local broken: { [string]: boolean } = {}

-- Las copias de un audio que se pueden probar, por orden: el Id de Config.Audio, el de shared/SoundIds
-- (scripts/upload-audio.sh, por el nombre del archivo) y la de ReplicatedStorage.Musica. Sin repetir y
-- sin las que ya han fallado.
local function copiesOf(id: number?, file: string?): { string }
	local list = {}
	local function add(candidate: string?)
		if type(candidate) == "string" and candidate ~= "" and not broken[candidate] and not table.find(list, candidate) then
			table.insert(list, candidate)
		end
	end
	if type(id) == "number" and id > 0 then
		add("rbxassetid://" .. string.format("%d", id))
	end
	add(SoundFx.uploaded(file))
	add(fromFolder(file))
	return list
end

local function assetId(id: number?, file: string?): string?
	return copiesOf(id, file)[1]
end

local function targetVolume(base: number): number
	if muted then
		return 0
	end
	return if speaking > 0 then base * AUDIO.DuckVolume else base
end

-- Espera a que el audio cargue (como mucho `seconds`). true = cargado
local LOAD_TIMEOUT = 15
local function waitLoaded(sound: Sound, seconds: number): boolean
	if sound.IsLoaded then
		return true
	end
	local loaded = false
	local connection = sound.Loaded:Connect(function()
		loaded = true
	end)
	for _ = 1, seconds * 4 do
		if loaded or sound.IsLoaded or not sound.Parent then
			break
		end
		task.wait(0.25)
	end
	connection:Disconnect()
	return loaded or sound.IsLoaded
end

-- ¿Se puede descargar este audio? true / false (no: privado, de otro dueño, rechazado…) / nil (no se
-- sabe). Lo pregunta a ContentProvider, que contesta en cuanto Roblox lo sabe (sin esperar 15 s).
local function fetchStatus(id: string): boolean?
	local result: boolean? = nil
	pcall(function()
		local provider = game:GetService("ContentProvider")
		provider:PreloadAsync({ id }, function(_, status)
			local name = tostring(status)
			if string.find(name, "Success", 1, true) then
				result = true
			elseif string.find(name, "Failure", 1, true) then
				result = false
			end
		end)
	end)
	return result
end

-- ¿Suena este Sound con este audio? (false = no carga: hay que probar otra copia)
local function loads(sound: Sound, id: string): boolean
	if fetchStatus(id) == false then
		return false
	end
	return waitLoaded(sound, LOAD_TIMEOUT)
end

local function fadeTo(sound: Sound, volume: number, seconds: number)
	TweenService:Create(sound, TweenInfo.new(seconds), { Volume = volume }):Play()
end

---------------------------------------------------------------------
-- Música
---------------------------------------------------------------------

-- La pieza que suena de verdad para una pieza pedida: ella si tiene alguna copia que no haya fallado;
-- si no, su Fallback (otra pieza de Config.Audio.Music), y así. Devuelve también sus copias, por orden.
-- nil = ninguna tiene audio (silencio).
local function resolveTrack(cue: string?): (string?, { [string]: any }?, { string }?)
	local seen = {}
	while cue and not seen[cue] do
		seen[cue] = true
		local track = AUDIO.Music[cue]
		if not track then
			return nil, nil, nil
		end
		local ids = copiesOf(track.Id, track.File)
		if #ids > 0 then
			return cue, track, ids
		end
		cue = track.Fallback
	end
	return nil, nil, nil
end

local playMusic: (cue: string?, volumeScale: number, fade: number?) -> ()

-- La música que toca cuando acaba una pieza que no se repite (o al limpiar la escena)
local function backToBackground()
	if not inCinematic and not intensity then
		playMusic(ambientCue, AUDIO.AmbientVolume / 0.4)
	end
end

-- Cambia la música con un fundido cruzado. cue = nil para quedarse sin música.
function playMusic(cue: string?, volumeScale: number, fade: number?)
	local seconds = fade or 2
	local playing, track, ids = resolveTrack(cue)
	if current and playing and current.Cue == playing then
		-- (la misma pieza: solo cambia el volumen; p. ej. una intensidad cuyo Fallback ya suena)
		current.Volume = ((track :: any).Volume or 0.4) * volumeScale
		fadeTo(current.Sound, targetVolume(current.Volume), math.min(seconds, 1.5))
		return
	end
	if current then
		local old = current.Sound
		fadeTo(old, 0, seconds)
		task.delay(seconds + 0.1, function()
			old:Destroy()
		end)
		current = nil
	end
	if not playing or not track or not ids then
		return
	end
	local sound = Instance.new("Sound")
	sound.Name = "Music_" .. playing
	sound.SoundId = ids[1]
	sound.Looped = track.Looped == true
	sound.Volume = 0
	sound.SoundGroup = SoundFx.group("Music")
	sound.Parent = holder()
	sound:Play()
	-- Si Roblox no deja cargar el audio (privado, de otro dueño, en revisión), se prueba la copia
	-- siguiente (SoundIds, ReplicatedStorage.Musica); si ninguna carga, la pieza de reserva (Fallback).
	-- Antes se quedaba en silencio para siempre. El aviso sale en la ventana Salida (F9).
	-- (task.defer: la comprobación empieza cuando esta pieza ya es la que suena)
	task.defer(function()
		for i, id in ids do
			if not sound.Parent then
				return
			end
			if i > 1 then
				warn(("[Música] No se ha podido cargar «%s» (%s): se prueba otra copia (%s)."):format(playing :: string, ids[i - 1], id))
				sound.SoundId = id
				sound:Play()
			end
			if loads(sound, id) then
				return
			end
			if not sound.Parent then
				return -- (la escena ya ha cambiado de música: no es que falle)
			end
			broken[id] = true
		end
		warn(("[Música] No se ha podido cargar «%s» (%s). ¿Sigue en revisión o el audio no es del dueño del juego? Se usa la pieza de reserva."):format(playing :: string, table.concat(ids, ", ")))
		if current and current.Sound == sound then
			current = nil
			sound:Destroy()
			playMusic(cue, volumeScale, 1) -- (ya sin las copias rotas: su Fallback, o nada)
		end
	end)
	current = { Cue = playing :: string, Sound = sound, Volume = (track.Volume or 0.4) * volumeScale }
	fadeTo(sound, targetVolume(current.Volume), seconds)
	if not sound.Looped then
		-- Al acabar una pieza que no se repite, vuelve la música de fondo del capítulo (si la escena no
		-- ha pedido otra cosa: entonces se queda el ambiente)
		sound.Ended:Connect(function()
			if current and current.Sound == sound then
				current = nil
				sound:Destroy()
				backToBackground()
			end
		end)
	end
end

-- Música de fondo cuando el capítulo no pide ninguna: según tu etapa de vida
local function defaultCue(): string
	local stage = Players.LocalPlayer:GetAttribute("LifeStage")
	if stage == "Bebe" then
		return "Nacimiento"
	elseif stage == "Nino" or stage == "Adolescente" then
		return "TemaValmar"
	end
	return "VidaAdulta"
end

-- Música de fondo del capítulo (más baja). Se aplica cuando no hay una cinemática ni una intensidad
-- de escena sonando. Sin música de capítulo suena la de tu etapa: así nunca se queda en silencio.
function StoryAudio.setAmbient(cue: string?)
	chapterCue = cue
	cue = cue or defaultCue()
	if cue == ambientCue then
		return
	end
	ambientCue = cue
	backToBackground()
end

function StoryAudio.cinematicStart(cue: string?)
	inCinematic = true
	if cue then
		intensity = nil -- (la pieza que pide la escena manda sobre la intensidad pedida antes)
		playMusic(cue, 1)
	end
end

local clearScene: (fade: number?) -> ()

function StoryAudio.cinematicEnd()
	inCinematic = false
	-- La escena se acaba: su intensidad y su ambiente también (nada sigue sonando después)
	if sceneSet then
		clearScene()
	end
	task.delay(1.5, function()
		backToBackground()
	end)
end

-- Nombre de una intensidad ("tensión", "Tension", "TEMA"…) -> la clave de Config.Audio.Intensity
function StoryAudio.resolveIntensity(level: any): string?
	if type(level) ~= "string" or level == "" then
		return nil
	end
	local wanted = simple(level)
	if wanted == "normal" or wanted == "ninguna" or wanted == "silencio" then
		wanted = "nada"
	elseif wanted == "final" or wanted == "temafinal" or wanted == "finaldecapitulo" then
		wanted = "tema"
	elseif wanted == "exito" then
		wanted = "resolucion"
	elseif wanted == "peligro" then
		wanted = "tension"
	elseif wanted == "emocion" or wanted == "emocional" then
		wanted = "intima"
	end
	for name in INTENSITY do
		if simple(name) == wanted then
			return name
		end
	end
	return nil
end

-- La escena pide una intensidad: la música cruza a esa pieza (Config.Audio.Intensity).
-- level: "Nada" | "Descubrimiento" | "Intima" | "Tension" | "Resolucion" | "Tema" (o la tabla de la
-- pista: { Intensity = "…" }). nil = quitar la intensidad (vuelve la música de antes).
-- Devuelve false si no conoce esa intensidad (y no cambia nada).
function StoryAudio.setIntensity(level: any): boolean
	if type(level) == "table" then
		level = level.Intensity or level.Level
	end
	if level == nil then
		intensity = nil
		backToBackground()
		return true
	end
	local name = StoryAudio.resolveIntensity(level)
	if not name then
		warn(("[StoryAudio] Intensidad desconocida: %s"):format(tostring(level)))
		return false
	end
	local def = INTENSITY[name]
	intensity = name
	sceneSet = true
	playMusic(def.Cue, def.Scale or 1, def.Fade)
	return true
end

---------------------------------------------------------------------
-- Ambiente por tipo de lugar
---------------------------------------------------------------------

type Layer = { Sound: Sound, Target: number, Def: { [string]: any }, Scale: number }
local layers: { [string]: Layer } = {}
local ambKind: string? = nil -- el tipo que suena
local autoKind = "Calle" -- el del sitio donde estás
local ambSerial = 0 -- cambia con cada tipo (los golpes sueltos del anterior se paran)

local function clock(): number
	local ok, hour = pcall(function()
		return game:GetService("Lighting").ClockTime
	end)
	return if ok and type(hour) == "number" then hour else 12
end

local function inHours(hours: { number }?, hour: number): boolean
	if not hours then
		return true
	end
	local from, to = hours[1], hours[2]
	if from <= to then
		return hour >= from and hour < to
	end
	return hour >= from or hour < to
end

-- Nombre de un tipo de ambiente ("hospital", "Escuela", "centro de salud"…) -> la clave de Kinds
function StoryAudio.resolveKind(kind: any): string?
	if type(kind) ~= "string" or kind == "" then
		return nil
	end
	local wanted = simple(kind)
	for name in AMB.Kinds do
		if simple(name) == wanted then
			return name
		end
	end
	local alias = (AMB.Aliases or {})[wanted]
	return if alias and AMB.Kinds[alias] then alias else nil
end

-- La primera opción de una capa que tiene audio: nombre (de Config.Sounds), id, volumen y tono
local function pickOption(layer: { [string]: any }): (string?, string?, number, number)
	for _, option in layer.Sounds or {} do
		local name, scale, pitch = option, 1, 1
		if type(option) == "table" then
			name, scale, pitch = option.Sound, option.Scale or 1, option.Pitch or 1
		end
		local id = type(name) == "string" and SoundFx.id(name) or nil
		if id and not broken[id] then
			return name, id, scale, pitch
		end
	end
	return nil, nil, 1, 1
end

local function layerTarget(entry: Layer, hour: number): number
	local def = entry.Def
	local volume = (def.Volume or 0.1) * entry.Scale
	if not inHours(def.Hours, hour) then
		volume *= def.OffHours or 0
	end
	return volume
end

-- Sube o baja cada capa a lo que toca ahora (las de horario: los niños del colegio solo de día)
local function updateLayers(fade: number)
	local hour = clock()
	for _, entry in layers do
		local target = layerTarget(entry, hour)
		if math.abs(target - entry.Target) > 1e-4 then
			entry.Target = target
			fadeTo(entry.Sound, target, fade)
		end
	end
end

local applyAmbience: (kind: string, fade: number?) -> ()

local function newLayer(name: string, id: string, pitch: number): Sound
	local sound = Instance.new("Sound")
	sound.Name = "Ambience_" .. name
	sound.SoundId = id
	sound.Looped = true
	sound.Volume = 0
	sound.PlaybackSpeed = pitch
	sound.SoundGroup = SoundFx.group("Ambience")
	local entry = Config.Sounds[name]
	if entry and entry.Muffle then
		-- Apagado (sin agudos): el viento de fuera suena a "aire" de una sala
		local eq = Instance.new("EqualizerSoundEffect")
		eq.HighGain = -24
		eq.MidGain = -10
		eq.LowGain = 0
		eq.Parent = sound
	end
	sound.Parent = holder()
	sound:Play()
	-- Si este audio no carga, la capa pasa a su opción siguiente (p. ej. el murmullo en vez de la calle).
	-- (task.defer: cuando la capa ya está puesta)
	task.defer(function()
		if loads(sound, id) or not sound.Parent then
			return
		end
		broken[id] = true
		warn(("[Ambiente] No se ha podido cargar «%s» (%s): se usa otro sonido."):format(name, id))
		local kind = ambKind
		if kind then
			ambKind = nil
			pcall(applyAmbience, kind, 1)
		end
	end)
	return sound
end

-- Golpes sueltos del tipo (mientras sea el mismo): reloj, pitido del monitor, puertas, teclas…
local function runSpot(spot: { [string]: any }, serial: number)
	local every = spot.Every or { 10, 20 }
	local beat = 0
	while ambSerial == serial do
		task.wait(every[1] + math.random() * math.max(0, (every[2] or every[1]) - every[1]))
		if ambSerial ~= serial then
			break
		end
		if inHours(spot.Hours, clock()) then
			local burst = spot.Burst
			local count = if burst then math.random(burst[1], burst[2]) else 1
			for i = 1, count do
				if ambSerial ~= serial then
					break
				end
				beat += 1
				-- (tic-tac: un golpe de cada dos un poco más grave)
				local pitch = if spot.Alternate and beat % 2 == 0 then spot.Alternate else 1
				pcall(SoundFx.ambient, spot.Sound, spot.Volume or 1, pitch)
				if i < count then
					task.wait((spot.Gap or 0.15) * (0.8 + math.random() * 0.4))
				end
			end
		end
	end
end

-- Pone el ambiente de un tipo con un fundido cruzado. Las capas que siguen (p. ej. el aire de sala de
-- un interior a otro) no se cortan: solo cambian de volumen.
function applyAmbience(kind: string, fade: number?)
	if kind == ambKind then
		return
	end
	local seconds = fade or AMB.Fade or 2.5
	ambKind = kind
	ambSerial += 1
	local serial = ambSerial
	local def = AMB.Kinds[kind] or AMB.Kinds.Interior or { Layers = {} }
	local keep: { [string]: Layer } = {}
	for _, layer in def.Layers or {} do
		local name, id, scale, pitch = pickOption(layer)
		if name and id and not keep[name .. "@" .. pitch] then
			local key = name .. "@" .. pitch
			local entry = layers[key]
			if not entry or not entry.Sound.Parent then
				entry = { Sound = newLayer(name, id, pitch), Target = 0, Def = layer, Scale = scale }
			end
			entry.Def, entry.Scale = layer, scale
			keep[key] = entry
		end
	end
	for key, entry in layers do
		if not keep[key] then
			local sound = entry.Sound
			fadeTo(sound, 0, seconds)
			task.delay(seconds + 0.1, function()
				sound:Destroy()
			end)
		end
	end
	layers = keep
	updateLayers(seconds)
	for _, spot in def.Spots or {} do
		task.spawn(function()
			task.wait(seconds * 0.5) -- (entran cuando el ambiente nuevo ya se oye)
			runSpot(spot, serial)
		end)
	end
end

-- La escena pide un tipo de ambiente (colegio, casa, universidad, hospital, calle o uno de los
-- interiores de Config.Audio.Ambience.Kinds). nil o "Auto" = el del sitio donde estás.
-- Devuelve false si no conoce ese tipo (y deja el ambiente como estaba).
function StoryAudio.setAmbience(kind: any, fade: number?): boolean
	if type(kind) == "table" then
		fade = fade or kind.Fade
		kind = kind.Kind or kind.Place or kind.Play
	end
	if kind == nil or kind == "" or (type(kind) == "string" and simple(kind) == "auto") then
		ambOverride = nil
		applyAmbience(autoKind, fade)
		return true
	end
	local name = StoryAudio.resolveKind(kind)
	if not name then
		warn(("[StoryAudio] Ambiente desconocido: %s"):format(tostring(kind)))
		return false
	end
	ambOverride = name
	sceneSet = true
	applyAmbience(name, fade)
	return true
end

-- Deshace lo que pidió la escena: vuelve la música de fondo (si no hay cinemática) y el ambiente
-- del sitio donde estás
function clearScene(fade: number?)
	sceneSet = false
	local hadIntensity = intensity ~= nil
	intensity = nil
	ambOverride = nil
	applyAmbience(autoKind, fade)
	if hadIntensity then
		backToBackground()
	end
end

-- La escena acaba (o se salta, o se corta): nada de lo que pidió sigue sonando
function StoryAudio.clear()
	clearScene()
end

---------------------------------------------------------------------
-- ¿Dónde estás? (ambiente automático)
---------------------------------------------------------------------

export type ZoneInfo = {
	Position: Vector3?, -- donde estás
	Interior: string?, -- sala de un edificio ("Casa", "Aula", "Oficina"…; "Interior" si no se sabe)
	Door: Vector3?, -- (en una sala) la puerta del edificio, en la calle
	AtHome: boolean?, -- dentro de una casa familiar (la del bebé, la de tu familia)
	Roof: boolean?, -- hay techo encima
	Underground: boolean?, -- en el metro
}
export type Landmark = { Kind: string, Position: Vector3 }

-- El tipo de ambiente para un sitio (sin tocar el mundo: se puede probar fuera de Roblox)
function StoryAudio.kindFor(info: ZoneInfo, landmarks: { Landmark }?): string
	if info.Underground then
		return "Metro"
	end
	local at = info.Door or info.Position
	local place: { [string]: any }? = nil
	if at then
		local best = math.huge
		for _, mark in landmarks or {} do
			local def = (AMB.Places or {})[mark.Kind]
			if def and (not info.Interior or def.Kind ~= "Parque") then
				local d = Vector2.new(mark.Position.X - at.X, mark.Position.Z - at.Z).Magnitude
				if d <= (def.Radius or 80) and d < best then
					best, place = d, def
				end
			end
		end
	end
	if info.Interior then
		local room = (AMB.Rooms or {})[info.Interior] or "Interior"
		-- Un aula, un pasillo o una oficina del colegio, del hospital o de la facultad son de ese sitio
		if place and (room == "Universidad" or room == "Portal" or room == "Oficina" or room == "Interior") then
			return place.Kind
		end
		return room
	end
	if info.AtHome then
		return "Casa"
	end
	if place then
		return if info.Roof then place.Kind else (place.Outdoor or place.Kind)
	end
	return "Calle"
end

-- Lugares del mapa (los publica el servidor en ReplicatedStorage.MapLandmarks)
local landmarkCache: { Landmark } = {}
local landmarkCount = -1
local function landmarks(): { Landmark }
	local folder = ReplicatedStorage:FindFirstChild("MapLandmarks")
	local children = if folder then folder:GetChildren() else {}
	if #children ~= landmarkCount then
		landmarkCount = #children
		table.clear(landmarkCache)
		for _, config in children do
			local kind, position = config:GetAttribute("Kind"), config:GetAttribute("Position")
			if type(kind) == "string" and typeof(position) == "Vector3" and (AMB.Places or {})[kind] then
				table.insert(landmarkCache, { Kind = kind, Position = position })
			end
		end
	end
	return landmarkCache
end

-- Cajas de las casas familiares (no se mueven: se calculan una vez)
local homeBoxes: { [Instance]: { CFrame: CFrame, Size: Vector3 } | false } = setmetatable({}, { __mode = "k" }) :: any
local function atHome(position: Vector3): boolean
	local CollectionService = game:GetService("CollectionService")
	for _, home in CollectionService:GetTagged("FamilyHome") do
		local box = homeBoxes[home]
		if box == nil and home:IsA("Model") then
			local ok, cf, size = pcall(function()
				return (home :: Model):GetBoundingBox()
			end)
			box = if ok and size.Magnitude > 1 then { CFrame = cf, Size = size } else false
			homeBoxes[home] = box
		end
		if box then
			local p = box.CFrame:PointToObjectSpace(position)
			local half = box.Size / 2
			if math.abs(p.X) <= half.X and math.abs(p.Z) <= half.Z and math.abs(p.Y) <= half.Y + 2 then
				return true
			end
		end
	end
	return false
end

local rayParams: RaycastParams? = nil
local function params(exclude: { Instance }, include: boolean): RaycastParams
	local p = rayParams or RaycastParams.new()
	rayParams = p
	p.FilterType = if include then Enum.RaycastFilterType.Include else Enum.RaycastFilterType.Exclude
	p.FilterDescendantsInstances = exclude
	p.RespectCanCollide = not include
	return p
end

-- La sala de un edificio en la que estás: el Model "Interior_<Nombre>" que tienes debajo
local function interiorRoom(root: BasePart): string
	local interiores = workspace:FindFirstChild("Interiores")
	if not interiores then
		return "Interior"
	end
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -40, 0), params({ interiores }, true))
	local node: Instance? = hit and hit.Instance
	while node and node ~= interiores do
		if node:IsA("Model") and string.sub(node.Name, 1, 9) == "Interior_" then
			return string.sub(node.Name, 10)
		end
		node = node.Parent
	end
	return "Interior"
end

local function gatherInfo(): ZoneInfo
	local player = Players.LocalPlayer
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or not character then
		return {}
	end
	local info: ZoneInfo = { Position = root.Position }
	local underground = -10
	pcall(function()
		underground = require(ReplicatedStorage.Shared.Metro).Underground or underground
	end)
	if root.Position.Y < underground then
		info.Underground = true
		return info
	end
	if player:GetAttribute("InteriorKey") then
		info.Interior = interiorRoom(root)
		local door = player:GetAttribute("InteriorDoor")
		if typeof(door) == "Vector3" then
			info.Door = door
		end
		return info
	end
	info.AtHome = atHome(root.Position)
	local hit = workspace:Raycast(root.Position + Vector3.new(0, 2, 0), Vector3.new(0, 70, 0), params({ character, workspace.CurrentCamera }, false))
	info.Roof = hit ~= nil and hit.Instance.Transparency < 0.5 and hit.Material ~= Enum.Material.LeafyGrass
	return info
end

-- El tipo del sitio donde estás ahora (sin escena: el que suena)
function StoryAudio.zoneKind(): string
	return autoKind
end

-- Lo que suena ahora (para pruebas y para depurar en la consola)
function StoryAudio.state(): { [string]: any }
	local names = {}
	for key in layers do
		table.insert(names, key)
	end
	table.sort(names)
	return {
		Intensity = intensity,
		Music = current and current.Cue,
		Ambience = ambKind,
		AmbienceOverride = ambOverride,
		Zone = autoKind,
		Layers = names,
		InCinematic = inCinematic,
	}
end

-- Cada segundo: mira dónde estás y, si la escena no ha pedido otro ambiente, pone el de ese sitio
local function ambienceLoop()
	while true do
		task.wait(AMB.Every or 1)
		local ok, kind = pcall(function()
			return StoryAudio.kindFor(gatherInfo(), landmarks())
		end)
		if ok and type(kind) == "string" and AMB.Kinds[kind] then
			autoKind = kind
		end
		if not ambOverride then
			pcall(applyAmbience, autoKind)
		end
		pcall(updateLayers, 1.5)
	end
end

---------------------------------------------------------------------
-- Efectos
---------------------------------------------------------------------

function StoryAudio.sting(name: string?)
	local sting = name and AUDIO.Stings[name]
	local id = sting and assetId(sting.Id, sting.File)
	if muted or not id then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = sting.Volume or 0.5
	sound.SoundGroup = SoundFx.group("Music") -- (los efectos de la historia van con la música)
	sound.Parent = holder()
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	task.delay(15, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

---------------------------------------------------------------------
-- Voces
---------------------------------------------------------------------

local function duck(on: boolean)
	speaking = math.max(0, speaking + (if on then 1 else -1))
	if current then
		fadeTo(current.Sound, targetVolume(current.Volume), 0.4)
	end
end

-- La voz que suena ahora (solo una a la vez: una frase nueva o pasar de línea corta la anterior)
local currentVoice: { Stop: () -> () }? = nil
local voiceSerial = 0

-- Corta la voz que esté sonando (al pasar de línea, cerrar la conversación o saltar una escena)
function StoryAudio.stopVoice()
	voiceSerial += 1
	local voice = currentVoice
	currentVoice = nil
	if voice then
		pcall(voice.Stop)
	end
end

-- Voz sintetizada de Roblox. Si el motor no la tiene (o falla), se desactiva y quedan los subtítulos.
local function textToSpeech(text: string, profile: { [string]: any }, serial: number): boolean
	local tts: any = nil
	local ducked = false
	local ok, err = pcall(function()
		tts = Instance.new("AudioTextToSpeech")
		tts.Text = text
		if profile.VoiceId and profile.VoiceId ~= "" then
			tts.VoiceId = profile.VoiceId
		end
		pcall(function()
			tts.Pitch = profile.Pitch or 1
		end)
		pcall(function()
			tts.Speed = profile.Speed or 1
		end)
		pcall(function()
			tts.Volume = AUDIO.Voices.Volume or 1
		end)
		local output = Instance.new("AudioDeviceOutput")
		output.Parent = tts
		local wire = Instance.new("Wire")
		wire.SourceInstance = tts
		wire.TargetInstance = output
		wire.Parent = tts
		tts.Parent = holder()
		pcall(function()
			tts:LoadAsync()
		end)
		if serial ~= voiceSerial then
			-- Mientras cargaba ya se pasó a otra frase: esta no suena
			tts:Destroy()
			return
		end
		duck(true)
		ducked = true
		tts:Play()
		local length = 0
		pcall(function()
			length = tts.TimeLength
		end)
		local finished = false
		local function done()
			if not finished then
				finished = true
				duck(false)
				tts:Destroy()
			end
		end
		currentVoice = { Stop = done }
		task.delay(math.clamp(if length > 0 then length + 0.3 else #text * 0.07, 1, 15), done)
	end)
	if not ok then
		warn("[StoryAudio] Voz sintetizada no disponible; se muestran solo los subtítulos:", err)
		-- Si falló después de bajar la música, se vuelve a subir (si no, se queda baja para siempre)
		if ducked then
			duck(false)
		end
		-- (y la instancia a medias no se queda colgada)
		if tts then
			pcall(function()
				tts:Destroy()
			end)
		end
	end
	return ok
end

-- Dice una frase con la voz de ese personaje (role: "Abu", "Familia", "Narrador")
function StoryAudio.speak(role: string?, textKey: string, args: { [string]: any }?)
	StoryAudio.stopVoice() -- nunca dos voces a la vez
	if muted then
		return
	end
	local serial = voiceSerial
	local recorded = assetId(AUDIO.Voices.Lines[textKey])
	if recorded then
		local sound = Instance.new("Sound")
		sound.SoundId = recorded
		sound.Volume = AUDIO.Voices.Volume or 1
		sound.SoundGroup = SoundFx.group("Voice")
		sound.Parent = holder()
		duck(true)
		sound:Play()
		local finished = false
		local function done()
			if not finished then
				finished = true
				duck(false)
				sound:Destroy()
			end
		end
		sound.Ended:Connect(done)
		task.delay(15, done)
		currentVoice = { Stop = done }
		return
	end
	if ttsAvailable then
		local profile = AUDIO.Voices.Speakers[role or "Narrador"] or AUDIO.Voices.Speakers.Narrador
		task.spawn(function()
			if not textToSpeech(Strings.get(textKey, args), profile, serial) then
				ttsAvailable = false
			end
		end)
	end
end

---------------------------------------------------------------------
-- Silenciar
---------------------------------------------------------------------

-- Un solo sitio guarda si la música suena: el interruptor del menú lee y cambia esto
function StoryAudio.setMusicOn(on: boolean)
	muted = not on
	if muted then
		StoryAudio.stopVoice()
	end
	-- Los grupos callan también lo que ya suena (música, efectos de la historia y voces grabadas)
	SoundFx.setGroupOn("Music", on)
	SoundFx.setGroupOn("Voice", on)
	if current then
		fadeTo(current.Sound, targetVolume(current.Volume), 0.5)
	end
end

function StoryAudio.isMusicOn(): boolean
	return not muted
end

-- (nombre antiguo, por si alguien lo usa)
function StoryAudio.setMuted(value: boolean)
	StoryAudio.setMusicOn(not value)
end

function StoryAudio.init()
	holder()
	SoundFx.group("Music")
	SoundFx.group("Voice")
	SoundFx.group("Ambience")

	local player = Players.LocalPlayer
	-- El botón suelto 🔊 ya no existe: lo sustituye el interruptor del menú (un solo estado).
	-- La pantalla vacía se deja porque Main la espera para esconder cosas del HUD antiguo.
	Theme.create("ScreenGui", {
		Name = "StoryAudio",
		ResetOnSpawn = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	-- Música de fondo siempre, desde que apareces (Música: sí por defecto): si la historia no ha puesto
	-- la de su capítulo, suena la de tu etapa
	task.delay(AUDIO.BootDelay or 2, function()
		if not ambientCue then
			StoryAudio.setAmbient(chapterCue)
		end
	end)
	player:GetAttributeChangedSignal("LifeStage"):Connect(function()
		StoryAudio.setAmbient(chapterCue)
	end)

	-- Red de seguridad: si una escena pidió música o ambiente y se corta sin llamar a clear (falla,
	-- mueres, te vas lejos), al no estar ya en ninguna escena se deshace solo, a los 2 s
	local function outOfScene(): boolean
		return not player:GetAttribute("InCinematic") and not player:GetAttribute("InScene")
	end
	local function check()
		if sceneSet and outOfScene() then
			task.delay(2, function()
				if sceneSet and outOfScene() and not inCinematic then
					clearScene()
				end
			end)
		end
	end
	player:GetAttributeChangedSignal("InCinematic"):Connect(check)
	player:GetAttributeChangedSignal("InScene"):Connect(check)
	player.CharacterAdded:Connect(check)

	-- Ambiente del sitio donde estás (empieza ya con la calle; se ajusta en un segundo)
	applyAmbience(autoKind)
	task.spawn(ambienceLoop)
end

return StoryAudio
