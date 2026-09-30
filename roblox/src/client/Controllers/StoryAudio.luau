-- StoryAudio (cliente): música, efectos y voces de la historia.
--   * Música con fundidos suaves: la de cada cinemática y la de fondo de cada capítulo.
--   * Efectos cortos (sting) para los momentos de vida y los capítulos.
--   * Voces: grabadas si hay (Config.Audio.Voices.Lines) o sintetizadas por Roblox
--     (AudioTextToSpeech) si el motor lo permite. Mientras alguien habla, la música baja.
--   * Música on/off: StoryAudio.setMusicOn / isMusicOn (el interruptor está en el menú del HUD).
--     Silencia los grupos Music y Voice (SoundService), así se calla también lo que ya suena.
-- Los IDs de los audios están en Config.Audio. Con Id = 0 se busca en shared/SoundIds y en
-- ReplicatedStorage.Musica; si no hay, ese audio no suena (sin errores).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Theme = require(script.Parent.Parent.UI.Theme)
local SoundFx = require(script.Parent.SoundFx)

local AUDIO = Config.Audio
local StoryAudio = {}

local muted = false
local folder: Folder
local current: { Cue: string, Sound: Sound, Volume: number }? = nil
local ambientCue: string? = nil
local chapterCue: string? = nil -- la música que pide el capítulo (nil = ninguna)
local inCinematic = false
local speaking = 0
local ttsAvailable = AUDIO.Voices.TextToSpeech

-- ID del audio: el de Config.Audio o, si es 0, el del Sound que tenga el mismo nombre que el archivo
-- dentro de ReplicatedStorage.Musica (basta con arrastrar ahí los audios subidos desde el Asset Manager).
local function normalize(name: string): string
	return (string.gsub(string.lower(name), "[%s_%-%.]", ""))
end

local function fromFolder(file: string?): string?
	local musica = file and game:GetService("ReplicatedStorage"):FindFirstChild("Musica")
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

-- Por orden: el Id de Config.Audio, el de shared/SoundIds (scripts/upload-audio.sh --music, por el
-- nombre del archivo) y la copia de ReplicatedStorage.Musica
local function assetId(id: number?, file: string?): string?
	if id and id > 0 then
		return "rbxassetid://" .. id
	end
	return SoundFx.uploaded(file) or fromFolder(file)
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

local function fadeTo(sound: Sound, volume: number, seconds: number)
	TweenService:Create(sound, TweenInfo.new(seconds), { Volume = volume }):Play()
end

---------------------------------------------------------------------
-- Música
---------------------------------------------------------------------

-- Cambia la música con un fundido. cue = nil para quedarse en silencio.
local function playMusic(cue: string?, volumeScale: number)
	if current and current.Cue == cue then
		current.Volume = (AUDIO.Music[cue :: string].Volume or 0.4) * volumeScale
		fadeTo(current.Sound, targetVolume(current.Volume), 1.5)
		return
	end
	if current then
		local old = current.Sound
		fadeTo(old, 0, 2)
		task.delay(2.1, function()
			old:Destroy()
		end)
		current = nil
	end
	local track = cue and AUDIO.Music[cue]
	local id = track and assetId(track.Id, track.File)
	if not track or not id then
		return
	end
	local sound = Instance.new("Sound")
	sound.Name = "Music_" .. cue
	sound.SoundId = id
	sound.Looped = track.Looped == true
	sound.Volume = 0
	sound.SoundGroup = SoundFx.group("Music")
	sound.Parent = folder
	sound:Play()
	-- Si Roblox no deja cargar el audio (permisos o revisión), se prueba la copia de
	-- ReplicatedStorage.Musica; si tampoco hay, se queda en silencio (aviso solo en la ventana Salida)
	task.spawn(function()
		if waitLoaded(sound, LOAD_TIMEOUT) or not sound.Parent then
			return
		end
		-- (otra copia: la subida con scripts/upload-audio.sh --music o la de ReplicatedStorage.Musica)
		local fallback = SoundFx.uploaded(track.File) or fromFolder(track.File)
		if fallback == id then
			fallback = fromFolder(track.File)
		end
		if fallback and fallback ~= id then
			warn(("[Música] No se ha podido cargar «%s» (%s): se usa otra copia (%s)."):format(cue :: string, id, fallback))
			sound.SoundId = fallback
			sound:Play()
			if waitLoaded(sound, LOAD_TIMEOUT) or not sound.Parent then
				return
			end
		end
		warn(("[Música] No se ha podido cargar «%s» (%s). ¿Sigue en revisión o el juego no es del mismo dueño que el audio?"):format(cue :: string, sound.SoundId))
	end)
	current = { Cue = cue :: string, Sound = sound, Volume = (track.Volume or 0.4) * volumeScale }
	fadeTo(sound, targetVolume(current.Volume), 2)
	if not sound.Looped then
		-- Al acabar una pieza que no se repite, vuelve la música de fondo del capítulo
		sound.Ended:Connect(function()
			if current and current.Sound == sound then
				current = nil
				sound:Destroy()
				if not inCinematic then
					playMusic(ambientCue, AUDIO.AmbientVolume / 0.4)
				end
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

-- Música de fondo del capítulo (más baja). Se aplica cuando no hay una cinemática sonando.
-- Sin música de capítulo suena la de tu etapa: así nunca se queda en silencio.
function StoryAudio.setAmbient(cue: string?)
	chapterCue = cue
	cue = cue or defaultCue()
	if cue == ambientCue then
		return
	end
	ambientCue = cue
	if not inCinematic then
		playMusic(cue, AUDIO.AmbientVolume / 0.4)
	end
end

function StoryAudio.cinematicStart(cue: string?)
	inCinematic = true
	if cue then
		playMusic(cue, 1)
	end
end

function StoryAudio.cinematicEnd()
	inCinematic = false
	task.delay(1.5, function()
		if not inCinematic then
			playMusic(ambientCue, AUDIO.AmbientVolume / 0.4)
		end
	end)
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
	sound.Parent = folder
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
		tts.Parent = folder
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
		sound.Parent = folder
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
	folder = Instance.new("Folder")
	folder.Name = "StoryAudio"
	folder.Parent = SoundService

	SoundFx.group("Music")
	SoundFx.group("Voice")

	local player = Players.LocalPlayer
	-- El botón suelto 🔊 ya no existe: lo sustituye el interruptor del menú (un solo estado).
	-- La pantalla vacía se deja porque Main la espera para esconder cosas del HUD antiguo.
	Theme.create("ScreenGui", {
		Name = "StoryAudio",
		ResetOnSpawn = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	-- Música de fondo siempre: si la historia no ha puesto la de su capítulo, suena la de tu etapa
	task.delay(6, function()
		if not ambientCue then
			StoryAudio.setAmbient(chapterCue)
		end
	end)
	player:GetAttributeChangedSignal("LifeStage"):Connect(function()
		StoryAudio.setAmbient(chapterCue)
	end)
end

return StoryAudio
