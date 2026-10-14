-- SeaBeastService: el megalodón y el kraken del mar hondo (reglas en shared/Sea/SeaBeasts). El
-- servidor los mueve (8 veces por segundo), decide a quién atacan y el daño. docs/mar/diseno.md.
--
--   * Estado para todos en workspace.SeaBeasts (carpetas: no se las lleva el streaming): Configuration
--     «Megalodon» (Pos, Look, Mode) y «Kraken» (Mode, At = dónde golpea el tentáculo). El cliente
--     (Controllers/SeaLife) dibuja los animales y los suaviza.
--   * Un golpe (mordisco o tentáculo): vida, aire (atributo Oxygen) y un empujón (el remote «Sea»
--     «Knock»: el cliente mueve su personaje, que es suyo). Sin sangre.
--   * «Strike» (Atacar bajo el agua): si le das en el morro o al tentáculo, se va.
--   * «Photo» (Fotografiar): la criatura tiene que estar cerca (Diving.Photo.Range); se apunta en tu
--     partida (OceanService.photo) para la misión «Fotografía al megalodón».
--   * La pesca del monstruo (FishingService.onBoss): mientras dura, el animal está «enganchado» y no
--     ataca; si lo sacáis, desaparece un rato (SeaBeasts.Respawn) y luego vuelve otro ejemplar. Las
--     reglas de la pesca (alta mar, varios pescadores expertos) no cambian.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeaBeasts = require(ReplicatedStorage.Shared.Sea.SeaBeasts)
local SeaDiving = require(ReplicatedStorage.Shared.Sea.Diving)
local Ocean = require(ReplicatedStorage.Shared.Sea.Ocean)
local DivingService = require(script.Parent.DivingService)
local OceanService = require(script.Parent.OceanService)
local FishingService = require(script.Parent.FishingService)

local SeaBeastService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local function remote(): RemoteEvent?
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	return remotes and remotes:FindFirstChild("Sea") :: RemoteEvent?
end

SeaBeastService.Tick = 0.125
local mega = SeaBeasts.newMegalodon()
local kraken = SeaBeasts.newKraken()
local goneUntil: { [string]: number } = {}
local lastStrike: { [Player]: number } = {}
local lastPhoto: { [Player]: number } = {}
local configs: { [string]: Configuration } = {}
SeaBeastService._mega = function()
	return mega
end
SeaBeastService._kraken = function()
	return kraken
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function folder(): Folder
	local f = workspace:FindFirstChild("SeaBeasts")
	if not f then
		f = Instance.new("Folder")
		f.Name = "SeaBeasts"
		f.Parent = workspace
	end
	return f :: Folder
end

local function config(id: string): Configuration
	local c = configs[id]
	if not c or not c.Parent then
		c = Instance.new("Configuration")
		c.Name = id
		c.Parent = folder()
		configs[id] = c
	end
	return c :: Configuration
end

-- Los jugadores a los que puede atacar cada uno (con su UserId)
local function targetsFor(id: string): ({ SeaBeasts.Target }, { [number]: Player })
	local list, byId = {}, {}
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if root and humanoid then
			local info = {
				Pos = root.Position,
				Alive = humanoid.Health > 0,
				Underwater = root.Position.Y < Ocean.Surface - 3 and DivingService.underwater(player),
				Stage = player:GetAttribute("LifeStage"),
				Riding = player:GetAttribute("Riding") ~= nil or player:GetAttribute("Passenger") ~= nil or humanoid.SeatPart ~= nil,
			}
			if SeaBeasts.canTarget(id, info) then
				table.insert(list, { Id = player.UserId, Pos = root.Position })
				byId[player.UserId] = player
			end
		end
	end
	return list, byId
end

-- Un golpe a un jugador: vida, aire y empujón (sin sangre)
function SeaBeastService.hurt(player: Player, id: string, from: Vector3)
	local hit = SeaBeasts.hit(id)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local root = rootOf(player)
	if not humanoid or not root or humanoid.Health <= 0 then
		return
	end
	humanoid.Health = math.max(0, humanoid.Health - hit.Damage)
	local oxygen = player:GetAttribute("Oxygen")
	if type(oxygen) == "number" then
		player:SetAttribute("Oxygen", math.max(0, oxygen - hit.Oxygen))
	end
	local away = root.Position - from
	away = if away.Magnitude > 0.1 then away.Unit else Vector3.new(0, 1, 0)
	local r = remote()
	if r then
		r:FireClient(player, "Knock", { Velocity = away * hit.Knock + Vector3.new(0, 12, 0), Beast = id })
	end
	Notify:FireClient(player, "Error", if id == "Kraken" then "🦑 ¡Un tentáculo del Kraken te ha golpeado! (-aire)" else "🦈 ¡El megalodón te ha embestido! Aléjate o dale en el morro (Atacar).")
end

local function publish()
	local m = config("Megalodon")
	m:SetAttribute("Pos", mega.Pos)
	m:SetAttribute("Look", mega.Look)
	m:SetAttribute("Mode", mega.Mode)
	m:SetAttribute("Target", mega.Target)
	local k = config("Kraken")
	local L = Ocean.Lair
	k:SetAttribute("Pos", Vector3.new(L.X, L.Y, L.Z))
	k:SetAttribute("Mode", kraken.Mode)
	k:SetAttribute("At", kraken.At)
	k:SetAttribute("Target", kraken.Target)
end

function SeaBeastService.step(dt: number)
	local now = os.clock()
	for id, untilAt in goneUntil do
		if now >= untilAt then
			goneUntil[id] = nil
			if id == "Megalodon" then
				mega = SeaBeasts.newMegalodon() -- otro ejemplar
			else
				kraken = SeaBeasts.newKraken()
			end
		end
	end
	local megaTargets, megaById = targetsFor("Megalodon")
	local events
	mega, events = SeaBeasts.stepMegalodon(mega, dt, megaTargets)
	if events.Bite and megaById[events.Bite] then
		SeaBeastService.hurt(megaById[events.Bite], "Megalodon", SeaBeasts.mouth(mega))
	end
	local krakenTargets, krakenById = targetsFor("Kraken")
	kraken, events = SeaBeasts.stepKraken(kraken, dt, krakenTargets)
	if events.Warn and krakenById[events.Warn] then
		Notify:FireClient(krakenById[events.Warn], "Error", "🌋 ¡La sima tiembla! ¡Apártate!")
	end
	if events.Hit and krakenById[events.Hit] then
		SeaBeastService.hurt(krakenById[events.Hit], "Kraken", events.Strike or Vector3.new(Ocean.Lair.X, Ocean.Lair.Y, Ocean.Lair.Z))
	end
	publish()
end

-- Atacar bajo el agua: espanta al que tengas delante
local function onStrike(player: Player)
	local root = rootOf(player)
	local now = os.clock()
	if not root or now - (lastStrike[player] or 0) < 0.8 or not DivingService.underwater(player) then
		return
	end
	lastStrike[player] = now
	if SeaBeasts.strikeMegalodon(mega, root.Position) then
		Notify:FireClient(player, "Success", "🦈 ¡Le has dado en el morro! El megalodón se aleja.")
	elseif SeaBeasts.strikeKraken(kraken, root.Position) then
		Notify:FireClient(player, "Success", "🦑 ¡El tentáculo se retira!")
	end
end

-- Fotografiar: la criatura tiene que estar cerca
local function onPhoto(player: Player, beast: any)
	local root = rootOf(player)
	local now = os.clock()
	if type(beast) ~= "string" or not root or now - (lastPhoto[player] or 0) < SeaDiving.Photo.Gap then
		return
	end
	lastPhoto[player] = now
	local at: Vector3?
	if beast == "Megalodon" and mega.Mode ~= "Gone" then
		at = mega.Pos
	elseif beast == "Kraken" and kraken.Mode ~= "Gone" then
		at = kraken.At or Vector3.new(Ocean.Lair.X, Ocean.Lair.Y, Ocean.Lair.Z)
	end
	if not at or not DivingService.underwater(player) then
		return
	end
	if (at - root.Position).Magnitude > SeaDiving.Photo.Range then
		Notify:FireClient(player, "Info", "📷 Está demasiado lejos para la foto. Acércate (con cuidado).")
		return
	end
	OceanService.photo(player, beast)
end

-- La pesca del monstruo (FishingService): enganchado mientras dura; si lo sacáis, se va un rato
local function onBoss(kind: string, id: string, won: boolean?)
	if kind == "Start" then
		if id == "Megalodon" and mega.Mode ~= "Gone" then
			mega.Mode = "Hooked"
		elseif id == "Kraken" and kraken.Mode ~= "Gone" then
			kraken.Mode = "Hooked"
		end
	elseif kind == "End" then
		if won then
			if id == "Megalodon" then
				mega.Mode = "Gone"
			else
				kraken.Mode = "Gone"
			end
			goneUntil[id] = os.clock() + SeaBeasts.Respawn
		else
			if id == "Megalodon" and mega.Mode == "Hooked" then
				mega.Mode, mega.Timer = "Retreat", SeaBeasts.Megalodon.Retreat
			elseif id == "Kraken" and kraken.Mode == "Hooked" then
				kraken.Mode, kraken.Timer = "Rest", SeaBeasts.Kraken.Rest
			end
		end
	end
end
SeaBeastService._onBoss = onBoss
SeaBeastService._onStrike = onStrike
SeaBeastService._onPhoto = onPhoto

function SeaBeastService.init()
	FishingService.onBoss = onBoss
	local r = remote()
	if r then
		r.OnServerEvent:Connect(function(player, action, a)
			if action == "Strike" then
				onStrike(player)
			elseif action == "Photo" then
				onPhoto(player, if type(a) == "table" then a.Beast else a)
			end
		end)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastStrike[player] = nil
		lastPhoto[player] = nil
	end)
	publish()
	task.spawn(function()
		while true do
			local dt = task.wait(SeaBeastService.Tick)
			local ok, err = pcall(SeaBeastService.step, math.min(dt or SeaBeastService.Tick, 0.5))
			if not ok then
				warn("[SeaBeastService] " .. tostring(err))
			end
		end
	end)
end

return SeaBeastService
