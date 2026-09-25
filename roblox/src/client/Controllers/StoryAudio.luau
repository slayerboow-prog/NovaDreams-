-- StoryAudio (cliente): música, efectos y voces de la historia.
--   * Música con fundidos suaves: la de cada cinemática y la de fondo de cada capítulo.
--   * Efectos cortos (sting) para los momentos de vida y los capítulos.
--   * Voces: grabadas si hay (Config.Audio.Voices.Lines) o sintetizadas por Roblox
--     (AudioTextToSpeech) si el motor lo permite. Mientras alguien habla, la música baja.
--   * Botón 🔊/🔇 para silenciar la música y las voces de la historia.
-- Los IDs de los audios están en Config.Audio. Con Id = 0 ese audio no suena (sin errores).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Theme = require(script.Parent.Parent.UI.Theme)

local AUDIO = Config.Audio
local StoryAudio = {}

local muted = false
local folder: Folder
local current: { Cue: string, Sound: Sound, Volume: number }? = nil
local ambientCue: string? = nil
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

local function assetId(id: number?, file: string?): string?
	return if id and id > 0 then "rbxassetid://" .. id else fromFolder(file)
end

local function targetVolume(base: number): number
	if muted then
		return 0
	end
	return if speaking > 0 then base * AUDIO.DuckVolume else base
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
	sound.Parent = folder
	sound:Play()
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

-- Música de fondo del capítulo (más baja). Se aplica cuando no hay una cinemática sonando.
function StoryAudio.setAmbient(cue: string?)
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

-- Voz sintetizada de Roblox. Si el motor no la tiene (o falla), se desactiva y quedan los subtítulos.
local function textToSpeech(text: string, profile: { [string]: any }): boolean
	local ok, err = pcall(function()
		local tts = Instance.new("AudioTextToSpeech")
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
		duck(true)
		tts:Play()
		local length = 0
		pcall(function()
			length = tts.TimeLength
		end)
		task.delay(math.clamp(if length > 0 then length + 0.3 else #text * 0.07, 1, 15), function()
			duck(false)
			tts:Destroy()
		end)
	end)
	if not ok then
		warn("[StoryAudio] Voz sintetizada no disponible; se muestran solo los subtítulos:", err)
	end
	return ok
end

-- Dice una frase con la voz de ese personaje (role: "Abu", "Familia", "Narrador")
function StoryAudio.speak(role: string?, textKey: string, args: { [string]: any }?)
	if muted then
		return
	end
	local recorded = assetId(AUDIO.Voices.Lines[textKey])
	if recorded then
		local sound = Instance.new("Sound")
		sound.SoundId = recorded
		sound.Volume = AUDIO.Voices.Volume or 1
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
		return
	end
	if ttsAvailable then
		local profile = AUDIO.Voices.Speakers[role or "Narrador"] or AUDIO.Voices.Speakers.Narrador
		task.spawn(function()
			if not textToSpeech(Strings.get(textKey, args), profile) then
				ttsAvailable = false
			end
		end)
	end
end

---------------------------------------------------------------------
-- Silenciar
---------------------------------------------------------------------

function StoryAudio.setMuted(value: boolean)
	muted = value
	if current then
		fadeTo(current.Sound, targetVolume(current.Volume), 0.5)
	end
end

function StoryAudio.init()
	folder = Instance.new("Folder")
	folder.Name = "StoryAudio"
	folder.Parent = SoundService

	local player = Players.LocalPlayer
	local gui = Theme.create("ScreenGui", {
		Name = "StoryAudio",
		ResetOnSpawn = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local button = Theme.button({
		Name = "Mute",
		Position = UDim2.fromOffset(224, 14), -- junto al dinero (abajo a la izquierda están las necesidades)
		Size = UDim2.fromOffset(44, 44),
		Text = Strings.get("STORY.AUDIO.ON"),
		TextSize = 22,
		Parent = gui,
	})
	button.Activated:Connect(function()
		StoryAudio.setMuted(not muted)
		button.Text = Strings.get(if muted then "STORY.AUDIO.OFF" else "STORY.AUDIO.ON")
	end)
end

return StoryAudio
