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
-- Remoto GraphicsChoice: ("Choice", "Auto" | "Low" | "Medium" | "High") o ("TipSeen").
-- Remoto AudioVolume: ("Set", "Music" | "Voice" | "Sfx" | "Ambience", entero 0 … 10). Lo que no vale se
-- ignora; como mucho AUDIO_BURST cambios seguidos y luego AUDIO_RATE por segundo (el cliente ya los junta).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Graphics = require(ReplicatedStorage.Shared.Graphics)
local AudioSettings = require(ReplicatedStorage.Shared.AudioSettings)
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

-- Un volumen nuevo: solo una de las cuatro claves y un entero de 0 a 10
function SettingsService.setAudio(player: Player, key: any, value: any): boolean
	if not AudioSettings.isKey(key) or not AudioSettings.isLevel(value) then
		return false
	end
	local data = DataService.get(player)
	if data then
		local audio = SettingsService.audioOf(data) -- (una tabla limpia: nada raro que el DataStore rechace)
		audio[key] = value
		data.Audio = audio
	end
	player:SetAttribute(AudioSettings.attribute(key), value)
	return true
end

function SettingsService.loaded(player: Player, data: { [string]: any })
	player:SetAttribute("GraphicsTipSeen", data.GraphicsTipSeen == true)
	player:SetAttribute("GraphicsChoice", SettingsService.graphicsOf(data))
	local audio = SettingsService.audioOf(data)
	data.Audio = audio
	for _, key in AudioSettings.Keys do
		player:SetAttribute(AudioSettings.attribute(key), audio[key])
	end
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
		SettingsService.setAudio(player, key, value)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastCall[player] = nil
		audioTokens[player] = nil
	end)
	DataService.onLoaded(SettingsService.loaded)
end

return SettingsService
