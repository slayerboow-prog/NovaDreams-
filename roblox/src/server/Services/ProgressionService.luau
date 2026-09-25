-- ProgressionService: nivel, experiencia, estadísticas, vida y estamina del personaje.
--
--   * Experiencia (XP): la da todo lo que haces en tu vida (trabajar, jugar, viajar, sacarte el carnet…)
--     y cada misión completada de la historia. Al subir de nivel ganas puntos.
--   * Estadísticas: Salud, Resistencia, Fuerza, Destreza y Suerte (Gameplay.Progression.Stats).
--     Salud -> vida máxima. Resistencia -> estamina. Destreza -> velocidad al correr.
--     Suerte -> un poco más de sueldo, propinas y tickets. Fuerza -> daño en las misiones de combate.
--   * Estamina: mantén Shift (o el botón 🏃) para correr más rápido mientras te dure.
--
-- Datos guardados: data.Progress = { Level, Xp, Points, Stats = { Salud = 0, ... }, QuestsSeen }
-- Atributos del jugador (para la interfaz y otros sistemas): Level, Xp, XpNext, StatPoints, Stat_<Id>,
-- Stamina, MaxStamina, Sprinting.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local ProgressionService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.Progression :: RemoteEvent
local P = Gameplay.Progression
local ST = P.Stamina

type Runner = { Stamina: number, Wants: boolean, Sprinting: boolean, Rested: number, Shown: number }
local runners: { [Player]: Runner } = {}

local function ensure(data: { [string]: any }): { [string]: any }
	data.Progress = data.Progress or {}
	local progress = data.Progress
	progress.Level = progress.Level or 1
	progress.Xp = progress.Xp or 0
	progress.Points = progress.Points or 0
	progress.Stats = progress.Stats or {}
	for _, stat in P.Stats do
		progress.Stats[stat.Id] = progress.Stats[stat.Id] or 0
	end
	return progress
end

function ProgressionService.stat(player: Player, id: string): number
	local data = DataService.get(player)
	return if data then ensure(data).Stats[id] or 0 else 0
end

local function maxStamina(player: Player): number
	return ST.Base + ProgressionService.stat(player, "Resistencia") * ST.PerResistencia
end

local function applyHealth(player: Player, refill: boolean?)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local maxHealth = P.Health.Base + ProgressionService.stat(player, "Salud") * P.Health.PerSalud
	humanoid.MaxHealth = maxHealth
	humanoid.Health = if refill then maxHealth else math.min(humanoid.Health, maxHealth)
end

local function sync(player: Player)
	local data = DataService.get(player)
	if not data then
		return
	end
	local progress = ensure(data)
	player:SetAttribute("Level", progress.Level)
	player:SetAttribute("Xp", progress.Xp)
	player:SetAttribute("XpNext", Gameplay.xpToNext(progress.Level))
	player:SetAttribute("StatPoints", progress.Points)
	for _, stat in P.Stats do
		player:SetAttribute("Stat_" .. stat.Id, progress.Stats[stat.Id])
	end
	player:SetAttribute("MaxStamina", maxStamina(player))
end

function ProgressionService.addXp(player: Player, amount: number, _reason: string?)
	local data = DataService.get(player)
	if not data or amount <= 0 then
		return
	end
	local progress = ensure(data)
	progress.Xp += math.floor(amount)
	local leveled = false
	while progress.Level < P.MaxLevel and progress.Xp >= Gameplay.xpToNext(progress.Level) do
		progress.Xp -= Gameplay.xpToNext(progress.Level)
		progress.Level += 1
		progress.Points += P.PointsPerLevel
		leveled = true
	end
	sync(player)
	if leveled then
		Notify:FireClient(player, "Success", ("⭐ ¡Nivel %d! Tienes %d puntos para mejorar tu personaje."):format(progress.Level, progress.Points))
		StoryEvents.emit(player, "LevelUp", { Level = progress.Level })
		applyHealth(player, true)
	end
end

local function spend(player: Player, statId: any)
	local data = DataService.get(player)
	if not data or typeof(statId) ~= "string" then
		return
	end
	local progress = ensure(data)
	if progress.Stats[statId] == nil or progress.Points <= 0 then
		return
	end
	if progress.Stats[statId] >= P.MaxStat then
		Notify:FireClient(player, "Info", "Esa estadística ya está al máximo.")
		return
	end
	progress.Points -= 1
	progress.Stats[statId] += 1
	sync(player)
	applyHealth(player)
	NeedsService.refreshSpeed(player)
end

-- Misiones de la historia completadas (se cuentan sin tocar el sistema de la historia)
local function checkQuests(player: Player)
	local data = DataService.get(player)
	local story = data and data.Story
	if not data or type(story) ~= "table" or type(story.Completed) ~= "table" then
		return
	end
	local progress = ensure(data)
	local count = 0
	for _ in story.Completed do
		count += 1
	end
	if progress.QuestsSeen == nil then
		progress.QuestsSeen = count -- la primera vez solo se apunta (no regala XP por lo ya hecho)
	elseif count > progress.QuestsSeen then
		local new = count - progress.QuestsSeen
		progress.QuestsSeen = count
		ProgressionService.addXp(player, new * P.QuestXp, "Quest")
		Notify:FireClient(player, "Money", ("+%d XP · misión completada"):format(new * P.QuestXp))
	end
end

---------------------------------------------------------------------
-- Correr y estamina
---------------------------------------------------------------------
local function canSprint(player: Player): boolean
	local stage = player:GetAttribute("LifeStage")
	return stage ~= "Bebe" and not player:GetAttribute("Crawling") and not player:GetAttribute("Riding") and not player:GetAttribute("Sleeping")
end

local function setSprinting(player: Player, runner: Runner, on: boolean)
	if runner.Sprinting == on then
		return
	end
	runner.Sprinting = on
	player:SetAttribute("Sprinting", on or nil)
	NeedsService.refreshSpeed(player)
end

local function tickStamina(dt: number)
	for player, runner in runners do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local moving = root ~= nil and Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude > 2
		local limit = maxStamina(player)
		if runner.Sprinting then
			if not runner.Wants or not moving or not canSprint(player) or runner.Stamina <= 0 then
				setSprinting(player, runner, false)
				runner.Rested = 0
			else
				runner.Stamina = math.max(0, runner.Stamina - ST.Drain * dt)
			end
		elseif runner.Wants and moving and canSprint(player) and runner.Stamina >= ST.MinToStart then
			setSprinting(player, runner, true)
		end
		if not runner.Sprinting then
			runner.Rested += dt
			if runner.Rested >= ST.RegenDelay then
				local regen = ST.Regen * (1 + 0.02 * ProgressionService.stat(player, "Resistencia"))
				runner.Stamina = math.min(limit, runner.Stamina + regen * dt)
			end
		end
		runner.Stamina = math.min(runner.Stamina, limit)
		if math.abs(runner.Stamina - runner.Shown) >= 1 or (runner.Stamina >= limit and runner.Shown < limit) then
			runner.Shown = math.floor(runner.Stamina + 0.5)
			player:SetAttribute("Stamina", runner.Shown)
		end
	end
end

function ProgressionService.init()
	DataService.onLoaded(function(player, data)
		ensure(data)
		sync(player)
		runners[player] = { Stamina = maxStamina(player), Wants = false, Sprinting = false, Rested = 0, Shown = -1 }
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Humanoid", 10)
			task.wait(0.5) -- después de que LifeService ajuste el tamaño
			applyHealth(player, true)
		end)
		if player.Character then
			applyHealth(player, true)
		end
		checkQuests(player)
	end)

	StoryEvents.connect(function(player, name)
		local xp = P.Xp[name]
		if xp then
			ProgressionService.addXp(player, xp, name)
		end
	end)

	Remote.OnServerEvent:Connect(function(player, action, value)
		if action == "Sprint" then
			local runner = runners[player]
			if runner then
				runner.Wants = value == true
			end
		elseif action == "Spend" then
			spend(player, value)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		runners[player] = nil
	end)

	task.spawn(function()
		local elapsed = 0
		while true do
			local dt = task.wait(0.1)
			tickStamina(dt)
			elapsed += dt
			if elapsed >= 3 then
				elapsed = 0
				for _, player in Players:GetPlayers() do
					checkQuests(player)
				end
			end
		end
	end)
end

return ProgressionService
