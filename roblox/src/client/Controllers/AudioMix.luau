-- AudioMix (cliente): los cuatro volúmenes del menú Ajustes, de 0 a 10 (shared/AudioSettings):
--   🎵 Música   -> grupo Music (SoundFx.setGroupLevel) y, con 0, la música apagada (StoryAudio.setMusicOn).
--                 El agache bajo las voces y las fanfarrias sigue funcionando encima del nivel elegido.
--   🗣️ Voces    -> StoryAudio.setVoiceVolume (Speech: la voz sintetizada y las frases grabadas, grupo Voice).
--   🔔 Efectos  -> grupo SFX (interfaz, acciones, vehículos, deportes, armas, la grieta del cielo…).
--   🌳 Ambiente -> grupo Ambience (ciudad, pájaros, grillos, olas, viento, lluvia, salas).
-- Cada nivel pasa por la curva perceptiva (AudioSettings.gain: (v/10)^2).
--
-- Se guardan con la partida (servidor: Services/SettingsService, data.Audio, remoto AudioVolume). Al
-- entrar, lo guardado llega en los atributos VolMusic / VolVoice / VolSfx / VolAmbience y se pone en
-- cuanto llega. Lo que el jugador acaba de tocar no lo pisa un atributo que llegue tarde.
--
--   AudioMix.init()                   pone los de por defecto (o lo guardado) y escucha los atributos
--   AudioMix.set("Music", 4)          cambia uno (y lo manda guardar, poco a poco)
--   AudioMix.step("Music", -1)        − / + del menú (nunca sale de 0 … 10); devuelve el texto nuevo
--   AudioMix.level("Music") / gain    lo de ahora
--   AudioMix.label("Music")           «🎵 Música: 6»

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AudioSettings = require(ReplicatedStorage.Shared.AudioSettings)
local SoundFx = require(script.Parent.SoundFx)
local StoryAudio = require(script.Parent.StoryAudio)

local AudioMix = {}

local SAVE_DELAY = 0.6 -- (pulsar − − − seguido manda un solo guardado, con el último valor)

local levels: { [string]: number } = table.clone(AudioSettings.Defaults)
local touched: { [string]: boolean } = {} -- el jugador ya lo cambió en esta partida
local saveSerial: { [string]: number } = {}

local function apply(key: string)
	local level = levels[key]
	local gain = AudioSettings.gain(level)
	if key == "Music" then
		SoundFx.setGroupLevel("Music", gain)
		if StoryAudio.isMusicOn() ~= (level > 0) then
			StoryAudio.setMusicOn(level > 0)
		end
	elseif key == "Voice" then
		StoryAudio.setVoiceVolume(gain)
	elseif key == "Sfx" then
		SoundFx.setGroupLevel("SFX", gain)
	elseif key == "Ambience" then
		SoundFx.setGroupLevel("Ambience", gain)
	end
end

local function remote(): RemoteEvent?
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local found = remotes and remotes:FindFirstChild("AudioVolume")
	return if found and found:IsA("RemoteEvent") then found else nil
end

local function save(key: string)
	saveSerial[key] = (saveSerial[key] or 0) + 1
	local serial = saveSerial[key]
	task.delay(SAVE_DELAY, function()
		if saveSerial[key] ~= serial then
			return
		end
		local r = remote()
		if r then
			r:FireServer("Set", key, levels[key])
		end
	end)
end

function AudioMix.level(key: string): number
	return levels[key] or 0
end

function AudioMix.gain(key: string): number
	return AudioSettings.gain(levels[key])
end

function AudioMix.label(key: string): string
	return AudioSettings.label(key, levels[key] or 0)
end

-- Cambia un volumen (0 … 10). fromSave = viene de la partida guardada (no se vuelve a mandar)
function AudioMix.set(key: string, value: any, fromSave: boolean?)
	if not AudioSettings.isKey(key) then
		return
	end
	local level = AudioSettings.clamp(value, key)
	if not fromSave then
		touched[key] = true
	end
	local changed = levels[key] ~= level
	levels[key] = level
	apply(key)
	if changed and not fromSave then
		save(key)
	end
end

-- − / + del menú: un paso, sin salir de 0 … 10. Devuelve el texto de la fila («🎵 Música: 5»)
function AudioMix.step(key: string, delta: number): string
	AudioMix.set(key, AudioSettings.step(levels[key], delta))
	return AudioMix.label(key)
end

-- Lo guardado que llega en los atributos (al entrar). No pisa lo que el jugador ya tocó.
local function fromAttributes(player: Player, key: string)
	if touched[key] then
		return
	end
	local value = player:GetAttribute(AudioSettings.attribute(key))
	if AudioSettings.isLevel(value) then
		AudioMix.set(key, value, true)
	end
end

function AudioMix.init()
	local player = Players.LocalPlayer
	for _, key in AudioSettings.Keys do
		apply(key) -- (los de por defecto ya desde el principio: la música a 6, las voces a 9…)
		if player then
			fromAttributes(player, key)
			player:GetAttributeChangedSignal(AudioSettings.attribute(key)):Connect(function()
				fromAttributes(player, key)
			end)
		end
	end
end

-- (pruebas)
function AudioMix._reset()
	levels = table.clone(AudioSettings.Defaults)
	table.clear(touched)
	table.clear(saveSerial)
end

return AudioMix
