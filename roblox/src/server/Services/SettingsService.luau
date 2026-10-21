-- SettingsService: los ajustes del jugador que se guardan con su partida (gráficos y volúmenes).
--
--   * Gráficos (menú «✨ Gráficos» / Ajustes): Auto, Bajo, Medio o Alto. Se guarda en data.Graphics
--     y vuelve al entrar en el atributo GraphicsChoice; el cliente (UI/Perf) lo pone ANTES de que el
--     «Auto» empiece a medir, así quien lo deja en Alto entra en Alto (antes, al entrar con el móvil,
--     siempre empezaba en Bajo).
--   * El consejo de subir también la calidad de Roblox (móvil) sale una sola vez: data.GraphicsTipSeen
--     -> atributo GraphicsTipSeen.
--   * Volúmenes (menú Ajustes: 🎵 Música, 🗣️ Voces, 🔔 Efectos, 🌳 Ambiente), de 0 a 10: data.Audio =
--     { Music, Voice, Sfx, Ambience } (shared/AudioSettings). Vuelven al entrar en los atributos
--     VolMusic / VolVoice / VolSfx / VolAmbience (el cliente, Controllers/AudioMix, los pone al llegar).
--   * 💬 Velocidad del texto (Lento / Normal / Rápido / Instantáneo, shared/LifeStory/TextSpeed): sin
--     campo nuevo, va DENTRO de los ajustes de sonido, data.Audio.TextSpeed (sigue al empezar una vida
--     nueva, como los volúmenes), y vuelve al entrar en el atributo TextSpeed. Se cambia con el remoto de
--     los volúmenes: AudioVolume ("Set", "TextSpeed", valor).
--   * Disparar a pie (menú: 🎯 Ayuda al apuntar, 🔫 Disparo automático, 🔢 Números de daño):
--     data.Shooter (shared/ShooterPrefs) -> atributos ShooterAssist / ShooterAutoFire / ShooterNumbers.
--     Remoto ShooterPrefs: ("Set", "Assist" | "AutoFire" | "Numbers", valor).
-- Remoto GraphicsChoice: ("Choice", "Auto" | "Low" | "Medium" | "High") o ("TipSeen").
-- Remoto AudioVolume: ("Set", "Music" | "Voice" | "Sfx" | "Ambience", entero 0 … 10). Lo que no vale se
-- ignora; como mucho AUDIO_BURST cambios seguidos y luego AUDIO_RATE por segundo (el cliente ya los junta).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Graphics = require(ReplicatedStorage.Shared.Graphics)
local AudioSettings = require(ReplicatedStorage.Shared.AudioSettings)
local ShooterPrefs = require(ReplicatedStorage.Shared.ShooterPrefs)
local TextSpeed = require(ReplicatedStorage.Shared.LifeStory.TextSpeed)
local DataService = require(script.Parent.DataService)

local SettingsService = {}

-- Lo guardado (o «Auto» si no hay nada o no vale)
function SettingsService.graphicsOf(data: { [string]: any }?): string
	local value = data and data.Graphics
	return if Graphics.isChoice(value) then value else "Auto"
end

function SettingsService.handle(player: Player, action: any, value: any)
	local data = DataService.get(player)
	if action == "Choice" then
		if not Graphics.isChoice(value) then
			return
		end
		if data then
			data.Graphics = value
		end
		player:SetAttribute("GraphicsChoice", value)
	elseif action == "TipSeen" then
		if data then
			data.GraphicsTipSeen = true
		end
		player:SetAttribute("GraphicsTipSeen", true)
	end
end

-- Volúmenes guardados (los cuatro; lo que falte o no valga, el de por defecto)
function SettingsService.audioOf(data: { [string]: any }?): { [string]: number }
	return AudioSettings.sanitize(data and data.Audio)
end

-- La velocidad del texto guardada (data.Audio.TextSpeed; si no hay o no vale, Normal)
function SettingsService.textSpeedOf(data: { [string]: any }?): string
	local audio = data and data.Audio
	return TextSpeed.sanitize(if type(audio) == "table" then audio[TextSpeed.Field] else nil)
end

-- ⚡ Destellos de relámpago (sí / no, v126, docs/clima/estaciones.md): como la velocidad del texto, sin
-- campo nuevo, dentro de data.Audio.Flashes (true por defecto). Atributo LightningFlashes. Remoto
-- AudioVolume ("Set", "Flashes", true | false).
SettingsService.FlashesKey = "Flashes"
SettingsService.FlashesAttribute = "LightningFlashes"
function SettingsService.flashesOf(data: { [string]: any }?): boolean
	local audio = data and data.Audio
	return not (type(audio) == "table" and audio.Flashes == false)
end

-- data.Audio limpio: los cuatro volúmenes, la velocidad del texto y los destellos (nada raro que el DataStore rechace)
local function cleanAudio(data: { [string]: any }): { [string]: any }
	local audio: { [string]: any } = SettingsService.audioOf(data)
	audio[TextSpeed.Field] = SettingsService.textSpeedOf(data)
	-- (solo se guarda si es «no»: por defecto, sí, y data.Audio no cambia)
	audio.Flashes = if SettingsService.flashesOf(data) then nil else false
	return audio
end

function SettingsService.setFlashes(player: Player, value: any): boolean
	if type(value) ~= "boolean" then
		return false
	end
	local data = DataService.get(player)
	if data then
		local audio = cleanAudio(data)
		audio.Flashes = if value then nil else false
		data.Audio = audio
	end
	player:SetAttribute(SettingsService.FlashesAttribute, value)
	return true
end

-- Una velocidad del texto nueva: solo las de TextSpeed.Values
function SettingsService.setTextSpeed(player: Player, value: any): boolean
	if not TextSpeed.valid(value) then
		return false
	end
	local data = DataService.get(player)
	if data then
		local audio = cleanAudio(data)
		audio[TextSpeed.Field] = value
		data.Audio = audio
	end
	player:SetAttribute(TextSpeed.Attribute, value)
	return true
end

-- Un volumen nuevo: solo una de las cuatro claves y un entero de 0 a 10
function SettingsService.setAudio(player: Player, key: any, value: any): boolean
	if not AudioSettings.isKey(key) or not AudioSettings.isLevel(value) then
		return false
	end
	local data = DataService.get(player)
	if data then
		local audio = cleanAudio(data) -- (una tabla limpia; la velocidad del texto se queda)
		audio[key] = value
		data.Audio = audio
	end
	player:SetAttribute(AudioSettings.attribute(key), value)
	return true
end

-- Un ajuste de disparar: solo las claves y valores de ShooterPrefs
function SettingsService.setShooter(player: Player, key: any, value: any): boolean
	if not ShooterPrefs.valid(key, value) then
		return false
	end
	local data = DataService.get(player)
	if data then
		local prefs = ShooterPrefs.sanitize(data.Shooter)
		;(prefs :: any)[key] = value
		data.Shooter = prefs
	end
	player:SetAttribute(ShooterPrefs.Attributes[key], value)
	return true
end

function SettingsService.loaded(player: Player, data: { [string]: any })
	local shooter = ShooterPrefs.sanitize(data.Shooter)
	data.Shooter = shooter
	for _, key in ShooterPrefs.Keys do
		player:SetAttribute(ShooterPrefs.Attributes[key], (shooter :: any)[key])
	end
	player:SetAttribute("GraphicsTipSeen", data.GraphicsTipSeen == true)
	player:SetAttribute("GraphicsChoice", SettingsService.graphicsOf(data))
	local audio = cleanAudio(data)
	data.Audio = audio
	for _, key in AudioSettings.Keys do
		player:SetAttribute(AudioSettings.attribute(key), audio[key])
	end
	player:SetAttribute(TextSpeed.Attribute, audio[TextSpeed.Field])
	player:SetAttribute(SettingsService.FlashesAttribute, audio.Flashes ~= false)
end

-- Límite de los volúmenes: un cubo de fichas por jugador (AUDIO_BURST seguidos, AUDIO_RATE por segundo)
local AUDIO_BURST, AUDIO_RATE = 8, 4
local audioTokens: { [Player]: { Tokens: number, At: number } } = {}
function SettingsService.audioAllowed(player: Player, now: number): boolean
	local bucket = audioTokens[player]
	if not bucket then
		bucket = { Tokens = AUDIO_BURST, At = now }
		audioTokens[player] = bucket
	end
	bucket.Tokens = math.min(AUDIO_BURST, bucket.Tokens + math.max(0, now - bucket.At) * AUDIO_RATE)
	bucket.At = now
	if bucket.Tokens < 1 then
		return false
	end
	bucket.Tokens -= 1
	return true
end

local function remoteNamed(remotes: Instance, name: string): RemoteEvent
	local remote = remotes:FindFirstChild(name) :: RemoteEvent?
	if not remote then
		local created = Instance.new("RemoteEvent")
		created.Name = name
		created.Parent = remotes
		remote = created
	end
	return remote :: RemoteEvent
end

local lastCall: { [Player]: number } = {}
function SettingsService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local remote = remoteNamed(remotes, "GraphicsChoice")
	remote.OnServerEvent:Connect(function(player, action, value)
		-- (sin abusar: como mucho unas cuantas veces por segundo)
		local now = os.clock()
		if now - (lastCall[player] or -1) < 0.2 then
			return
		end
		lastCall[player] = now
		SettingsService.handle(player, action, value)
	end)
	remoteNamed(remotes, "AudioVolume").OnServerEvent:Connect(function(player, action, key, value)
		if action ~= "Set" or not SettingsService.audioAllowed(player, os.clock()) then
			return
		end
		if key == TextSpeed.Key then
			SettingsService.setTextSpeed(player, value)
			return
		elseif key == SettingsService.FlashesKey then
			SettingsService.setFlashes(player, value)
			return
		end
		SettingsService.setAudio(player, key, value)
	end)
	remoteNamed(remotes, "ShooterPrefs").OnServerEvent:Connect(function(player, action, key, value)
		if action ~= "Set" or not SettingsService.audioAllowed(player, os.clock()) then
			return
		end
		SettingsService.setShooter(player, key, value)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastCall[player] = nil
		audioTokens[player] = nil
	end)
	DataService.onLoaded(SettingsService.loaded)
end

return SettingsService
