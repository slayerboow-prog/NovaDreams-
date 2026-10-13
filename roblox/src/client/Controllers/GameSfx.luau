-- GameSfx (cliente): los efectos que responden a lo que pasa en la partida, sin tocar cada pantalla.
--   * Dinero que entra: «ka-ching» (Dinero); dinero que sale: el lector y el cajón (Pago)
--   * XP que sube: destello (Xp); nivel nuevo: fanfarria grande que agacha la música (SubirNivel)
--   * Historia (remoto LifeStory): misión que empieza, misión cumplida, sitio descubierto, mensaje al
--     ValPhone; la música de tensión entra con un golpe (Tension, lo pide StoryAudio)
--   * Mochila: coger algo (Coger)
--   * Mundo: grillos de noche al aire libre y olas cerca de la costa (bucles en el grupo Ambience)
--   * Deporte: la grada de fondo mientras juegas un partido o corres (atributo InSport)
-- Todo pasa por SoundFx.play (Config.Sounds): si un audio no está subido, no suena y no da error.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local DayCycle = require(ReplicatedStorage.Shared.DayCycle)
local GameClock = require(ReplicatedStorage.Shared.GameClock) -- (la hora del juego: GameClock.hour())
local SoundFx = require(script.Parent.SoundFx)

local GameSfx = {}

local player = Players.LocalPlayer
local SETTLE = 6 -- s desde que llegan tus datos: lo que cambia antes es la carga, no una recompensa

---------------------------------------------------------------------
-- Reglas (puras: las prueba scripts/test-sfx.luau)
---------------------------------------------------------------------

-- Qué suena cuando cambia el dinero (nil = nada: carga de datos o sin cambio)
function GameSfx.moneyCue(before: number?, after: number?, settled: boolean): string?
	if not settled or type(before) ~= "number" or type(after) ~= "number" or before == after then
		return nil
	end
	return if after > before then "Dinero" else "Pago"
end

-- Qué suena con la experiencia y el nivel (el nivel manda: no suenan los dos a la vez)
function GameSfx.progressCue(xpBefore: number?, xpAfter: number?, levelBefore: number?, levelAfter: number?, settled: boolean): string?
	if not settled then
		return nil
	end
	if type(levelBefore) == "number" and type(levelAfter) == "number" and levelAfter > levelBefore then
		return "SubirNivel"
	end
	if type(xpBefore) == "number" and type(xpAfter) == "number" and xpAfter > xpBefore then
		return "Xp"
	end
	return nil
end

-- Qué suena con cada mensaje de la historia (remoto LifeStory)
local STORY_CUES = {
	QuestIntro = "MisionEmpieza",
	Done = "MisionCompleta",
	Discover = "Descubrimiento",
	Ping = "Aviso",
}
function GameSfx.storyCue(kind: string): string?
	return STORY_CUES[kind]
end

-- Cuántas cosas llevas en la mochila (atributo Inventory, JSON de casillas { i, n })
function GameSfx.itemCount(raw: any): number?
	if typeof(raw) ~= "string" then
		return nil
	end
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok or type(decoded) ~= "table" then
		return nil
	end
	local total = 0
	for _, entry in decoded do
		if type(entry) == "table" and type(entry.i) == "string" then
			total += tonumber(entry.n) or 1
		end
	end
	return total
end

-- Distancia (studs, en planta) de un punto a la costa (polígono CityPlan.Coast)
function GameSfx.coastDistance(x: number, z: number, coast: { { number } }): number
	local best = math.huge
	for i = 1, #coast do
		local a, b = coast[i], coast[i % #coast + 1]
		local ax, az, bx, bz = a[1], a[2], b[1], b[2]
		local dx, dz = bx - ax, bz - az
		local len2 = dx * dx + dz * dz
		local t = if len2 > 0 then math.clamp(((x - ax) * dx + (z - az) * dz) / len2, 0, 1) else 0
		local px, pz = ax + dx * t - x, az + dz * t - z
		best = math.min(best, math.sqrt(px * px + pz * pz))
	end
	return best
end

-- Volumen (0..1) de los grillos según la hora del juego: lo oscuro que es (shared/DayCycle, la misma
-- curva que las farolas): empiezan con el atardecer (21:30), del todo a las 22:00, y callan al amanecer
function GameSfx.nightAmount(clock: number): number
	return DayCycle.darkness(clock)
end

-- Volumen (0..1) de las olas según lo cerca que estás de la orilla
function GameSfx.waveAmount(distance: number): number
	return math.clamp(1 - (distance - 40) / 260, 0, 1)
end

-- Volumen (0..1) de la grada según el deporte que juegas (atributo InSport); nil o desconocido = nada
local CROWD = { Futbol = 1, Baloncesto = 0.8, Carrera = 0.75, Voley = 0.6, Raqueta = 0.45 }
function GameSfx.crowdAmount(sport: any): number
	return if type(sport) == "string" then CROWD[sport] or 0 else 0
end

---------------------------------------------------------------------
-- En la partida
---------------------------------------------------------------------
local readyAt = math.huge
local function settled(): boolean
	return os.clock() >= readyAt
end

local function watchProgress()
	local money = player:GetAttribute("Money")
	local xp = player:GetAttribute("Xp")
	local level = player:GetAttribute("Level")
	local function markReady()
		if readyAt == math.huge then
			readyAt = os.clock() + SETTLE
		end
	end
	if money ~= nil then
		markReady()
	end
	player:GetAttributeChangedSignal("Money"):Connect(function()
		local now = player:GetAttribute("Money")
		markReady()
		local cue = GameSfx.moneyCue(money, now, settled())
		money = now
		if cue then
			SoundFx.play(cue)
		end
	end)
	local function progress()
		local x, l = player:GetAttribute("Xp"), player:GetAttribute("Level")
		local cue = GameSfx.progressCue(xp, x, level, l, settled())
		xp, level = x, l
		if cue then
			SoundFx.play(cue)
		end
	end
	-- (Level y Xp cambian juntos al subir de nivel: se mira en el siguiente fotograma, una sola vez)
	local pending = false
	local function queue()
		if not pending then
			pending = true
			task.defer(function()
				pending = false
				progress()
			end)
		end
	end
	player:GetAttributeChangedSignal("Xp"):Connect(queue)
	player:GetAttributeChangedSignal("Level"):Connect(queue)
end

local function watchInventory()
	local count = GameSfx.itemCount(player:GetAttribute("Inventory"))
	player:GetAttributeChangedSignal("Inventory"):Connect(function()
		local now = GameSfx.itemCount(player:GetAttribute("Inventory"))
		if settled() and count and now and now > count then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			SoundFx.play("Coger", { At = root })
		end
		count = now or count
	end)
end

local function watchStory()
	local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("LifeStory", 60) :: RemoteEvent?
	if not remote then
		return
	end
	remote.OnClientEvent:Connect(function(kind: string)
		local cue = GameSfx.storyCue(kind)
		-- (el aviso del ValPhone no suena encima de una conversación o una escena)
		if cue and settled() and not (kind == "Ping" and SoundFx.busy()) then
			SoundFx.play(cue)
		end
	end)
end

-- Grillos y olas: dos bucles muy bajos que suben y bajan con la hora y la distancia al mar
local function worldLoops()
	local Config = require(ReplicatedStorage.Shared.Config)
	local CityPlan = require(ReplicatedStorage.Shared.CityPlan)
	local crickets = SoundFx.loop("Grillos", nil, "Ambience")
	local waves = SoundFx.loop("Olas", nil, "Ambience")
	if not crickets and not waves then
		return
	end
	local cricketBase = (Config.Sounds.Grillos and Config.Sounds.Grillos.Volume) or 0.22
	local waveBase = (Config.Sounds.Olas and Config.Sounds.Olas.Volume) or 0.35
	local current = { Grillos = 0, Olas = 0 }
	if crickets then
		crickets.Volume = 0
	end
	if waves then
		waves.Volume = 0
	end
	while true do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local night, sea = 0, 0
		if root then
			local p = root.Position
			-- fuera: no en las salas (en el cielo) ni bajo tierra (metro)
			local outdoors = p.Y < 3000 and p.Y > -30
			if outdoors then
				night = GameSfx.nightAmount(GameClock.hour())
				local weather = workspace:GetAttribute("Weather")
				if weather == "Lluvia" or weather == "Tormenta" or weather == "Nieve" then
					night *= 0.3
				end
				sea = GameSfx.waveAmount(GameSfx.coastDistance(p.X, p.Z, CityPlan.Coast))
			end
		end
		-- (cambios suaves: medio segundo por paso)
		current.Grillos += (night - current.Grillos) * 0.35
		current.Olas += (sea - current.Olas) * 0.35
		if crickets then
			crickets.Volume = cricketBase * current.Grillos
		end
		if waves then
			waves.Volume = waveBase * current.Olas
		end
		task.wait(0.5)
	end
end

-- La grada: un bucle que entra y sale con fundido mientras juegas (solo se crea al primer partido)
local function sportCrowd()
	local Config = require(ReplicatedStorage.Shared.Config)
	local base = (Config.Sounds.PublicoEstadio and Config.Sounds.PublicoEstadio.Volume) or 0.24
	local crowd: Sound? = nil
	local level = 0
	while true do
		local want = GameSfx.crowdAmount(player:GetAttribute("InSport"))
		if want > 0 and not crowd then
			crowd = SoundFx.loop("PublicoEstadio", nil, "Ambience")
			if not crowd then
				return -- (sin audio: nada)
			end
			crowd.Volume = 0
		end
		level += (want - level) * 0.3
		if crowd then
			crowd.Volume = base * level
		end
		task.wait(0.25)
	end
end

function GameSfx.init()
	watchProgress()
	watchInventory()
	task.spawn(watchStory)
	task.spawn(function()
		local ok, err = pcall(sportCrowd)
		if not ok then
			warn("[GameSfx] " .. tostring(err))
		end
	end)
	task.spawn(function()
		local ok, err = pcall(worldLoops)
		if not ok then
			warn("[GameSfx] " .. tostring(err))
		end
	end)
end

return GameSfx
