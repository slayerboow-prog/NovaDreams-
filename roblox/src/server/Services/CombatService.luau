-- CombatService: golpes entre jugadores (y a los personajes de tus misiones), siempre decidido aquí.
--
-- El cliente solo avisa: "Attack" (he pulsado golpear) y "Block" (me defiendo / dejo de defenderme).
-- El servidor comprueba todo (pausas entre golpes, distancia, que esté delante, quién puede recibir),
-- calcula el daño (shared/Combat) y avisa a todos para que se vea y se oiga el golpe.
--
-- K.O.: al quedarte sin vida caes Combat.KOSeconds segundos (sin poder pegar) y te levantas con
-- parte de la vida. Si alguien te golpea mientras estás K.O., te remata: mueres y reapareces en el
-- hospital (HospitalService). HitSomeone lleva Killed = true (homicidio para WantedService).
-- Para las misiones y la policía: StoryEvents "HitSomeone" (Target/Npc/Model/KO), "GotHit" y
-- "KnockedOut". Los agentes de policía (Officer) sí reciben daño y caen (WantedService lo castiga).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Combat = require(ReplicatedStorage.Shared.Combat)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local ProgressionService = require(script.Parent.ProgressionService)
local ClassService = require(script.Parent.ClassService)
local MiniGameService = require(script.Parent.MiniGameService)
local PoliceUnits = require(script.Parent.Parent.World.PoliceUnits)

local CombatService = {}

type State = { Combo: number, LastAt: number, Blocking: boolean, KOUntil: number, SpawnedAt: number }

local states: { [Player]: State } = {}
local Remote: RemoteEvent

local function stateOf(player: Player): State
	local state = states[player]
	if not state then
		state = { Combo = 0, LastAt = 0, Blocking = false, KOUntil = 0, SpawnedAt = os.clock() }
		states[player] = state
	end
	return state
end

local function parts(model: Model?): (Humanoid?, BasePart?)
	if not model then
		return nil, nil
	end
	return model:FindFirstChildOfClass("Humanoid"), model:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- ¿Puede este jugador pegar o recibir ahora mismo?
local function canFight(player: Player): boolean
	local state = stateOf(player)
	local humanoid = parts(player.Character)
	if not humanoid or humanoid.Health <= 0 or os.clock() < state.KOUntil then
		return false
	end
	local stage = player:GetAttribute("LifeStage")
	if stage and not Stages.inRange(stage, Combat.MinStage, nil) then
		return false
	end
	if player:GetAttribute("InDialogue") then
		return false
	end
	local okClass, inClass = pcall(ClassService.isRunning, player)
	local okGame, inGame = pcall(MiniGameService.isRunning, player)
	return not (okClass and inClass) and not (okGame and inGame)
end

local function isProtected(player: Player): boolean
	local state = stateOf(player)
	local humanoid = parts(player.Character)
	return os.clock() - state.SpawnedAt < Combat.SpawnProtection or (humanoid ~= nil and humanoid.SeatPart ~= nil)
end

-- Un personaje de misión solo lo puede golpear el jugador de esa misión (los demás ni lo ven)
local function npcBelongsTo(model: Model, player: Player): boolean
	local node: Instance? = model.Parent
	while node and node ~= workspace do
		local owner = node:GetAttribute("Owner")
		if owner ~= nil then
			return owner == player.UserId
		end
		node = node.Parent
	end
	return true
end

local function knockOut(victim: Player, humanoid: Humanoid)
	local state = stateOf(victim)
	state.KOUntil = os.clock() + Combat.KOSeconds
	state.Blocking = false
	victim:SetAttribute("Blocking", nil)
	victim:SetAttribute("KO", true)
	StoryEvents.emit(victim, "KnockedOut", {})
	task.delay(Combat.KOSeconds, function()
		if victim.Parent then
			victim:SetAttribute("KO", nil)
		end
		if humanoid.Parent and humanoid.Health > 0 then
			humanoid.Health = math.max(humanoid.Health, humanoid.MaxHealth * Combat.KOHealth)
		end
	end)
end

-- El personaje (modelo con Humanoid) al que pertenece una pieza
local function humanoidModel(part: BasePart): Model?
	local node: Instance? = part.Parent
	while node and node ~= workspace do
		if node:IsA("Model") and node:FindFirstChildOfClass("Humanoid") then
			return node
		end
		node = node.Parent
	end
	return nil
end

-- A quién alcanza un golpe: humanoides delante del atacante, los más cercanos primero
local function victimsOf(player: Player, root: BasePart): { Model }
	local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	look = if look.Magnitude > 0.01 then look.Unit else Vector3.new(0, 0, -1)
	local center = root.Position + look * (Combat.Range / 2)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	local found: { [Model]: number } = {}
	for _, part in workspace:GetPartBoundsInRadius(center, Combat.Range / 2 + Combat.HitRadius / 2, params) do
		local model = humanoidModel(part)
		if model and not found[model] then
			local _, targetRoot = parts(model)
			local at = if targetRoot then targetRoot.Position else part.Position
			local offset = Vector3.new(at.X - root.Position.X, 0, at.Z - root.Position.Z)
			local distance = offset.Magnitude
			if distance <= Combat.Range + 1 and (distance < 1 or offset.Unit:Dot(look) >= Combat.FacingDot) then
				found[model] = distance
			end
		end
	end
	local list = {}
	for model in found do
		table.insert(list, model)
	end
	table.sort(list, function(a, b)
		return found[a] < found[b]
	end)
	return list
end

local function attack(player: Player)
	local state = stateOf(player)
	local now = os.clock()
	if not Combat.ready(state.Combo, state.LastAt, now) or not canFight(player) then
		return
	end
	local humanoid, root = parts(player.Character)
	if not humanoid or not root or humanoid.SeatPart then
		return
	end
	local combo = Combat.nextCombo(state.Combo, state.LastAt, now)
	state.Combo = combo
	state.LastAt = now
	state.Blocking = false
	player:SetAttribute("Blocking", nil)
	-- Todos ven el golpe (el que pega ya lo está animando en su pantalla)
	Remote:FireAllClients("Swing", player, combo)

	local hits = 0
	for _, model in victimsOf(player, root) do
		if hits >= Combat.MaxTargets then
			break
		end
		local targetHumanoid, targetRoot = parts(model)
		if not targetHumanoid or targetHumanoid.Health <= 0 or not targetRoot then
			continue
		end
		local victim = Players:GetPlayerFromCharacter(model)
		local direction = Vector3.new(targetRoot.Position.X - root.Position.X, 0, targetRoot.Position.Z - root.Position.Z)
		direction = if direction.Magnitude > 0.01 then direction.Unit else root.CFrame.LookVector
		if victim and CombatService.isKnockedOut(victim) and not isProtected(victim) then
			-- Rematar a alguien que está K.O.: muere
			hits += 1
			targetHumanoid.Health = 0
			Remote:FireAllClients("Hit", { Victim = model, Attacker = player, Amount = Combat.damage(combo, ProgressionService.stat(player, "Fuerza")), Blocked = false, Combo = combo, Direction = direction, Knockback = Combat.Knockback[3], KO = true })
			StoryEvents.emit(player, "HitSomeone", { Target = victim.UserId, Model = model, KO = true, Killed = true })
			StoryEvents.emit(victim, "GotHit", { By = player.UserId })
		elseif victim then
			if not canFight(victim) or isProtected(victim) then
				continue
			end
			local victimState = stateOf(victim)
			-- Defenderse solo sirve si miras hacia quien te pega
			local facing = targetRoot.CFrame.LookVector:Dot(-direction) > 0.2
			local blocked = victimState.Blocking and facing
			local amount = Combat.damage(combo, ProgressionService.stat(player, "Fuerza"), blocked)
			local health, ko = Combat.apply(targetHumanoid.Health, amount)
			targetHumanoid.Health = health
			hits += 1
			Remote:FireAllClients("Hit", {
				Victim = model,
				Attacker = player,
				Amount = amount,
				Blocked = blocked,
				Combo = combo,
				Direction = direction,
				Knockback = if blocked then 0 else Combat.Knockback[combo],
				KO = ko,
			})
			StoryEvents.emit(player, "HitSomeone", { Target = victim.UserId, Model = model, KO = ko })
			StoryEvents.emit(victim, "GotHit", { By = player.UserId })
			if ko then
				knockOut(victim, targetHumanoid)
			end
		elseif model:GetAttribute("Officer") then
			-- Agentes de policía (WantedService): se les puede tumbar, pero es un delito grave
			if model:GetAttribute("Down") then
				continue
			end
			hits += 1
			local amount = Combat.damage(combo, ProgressionService.stat(player, "Fuerza"), false)
			local hp = (model:GetAttribute("Hp") or 0) - amount
			model:SetAttribute("Hp", hp)
			Remote:FireAllClients("Hit", { Victim = model, Attacker = player, Amount = amount, Blocked = false, Combo = combo, Direction = direction, Knockback = 0, KO = hp <= 0 })
			if hp <= 0 then
				PoliceUnits.knockDown(model)
			end
			StoryEvents.emit(player, "HitSomeone", { Model = model, KO = hp <= 0 })
		elseif npcBelongsTo(model, player) then
			-- Personajes (de misión, del cole…): reaccionan pero no se hacen daño
			hits += 1
			local npcId = model:GetAttribute("NpcId")
			Remote:FireAllClients("Hit", { Victim = model, Attacker = player, Amount = 0, Blocked = false, Combo = combo, Direction = direction, Knockback = 0, KO = false })
			StoryEvents.emit(player, "HitSomeone", { Npc = npcId or model.Name, Model = model })
		end
	end
end

local function setBlocking(player: Player, value: boolean)
	local state = stateOf(player)
	local blocking = value and canFight(player)
	if state.Blocking == blocking then
		return
	end
	state.Blocking = blocking
	player:SetAttribute("Blocking", if blocking then true else nil)
end

function CombatService.isKnockedOut(player: Player): boolean
	return os.clock() < stateOf(player).KOUntil
end

function CombatService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:FindFirstChild("Combat") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "Combat"
		Remote.Parent = remotes
	end
	Remote.OnServerEvent:Connect(function(player: Player, kind: any, value: any)
		if kind == "Attack" then
			attack(player)
		elseif kind == "Block" then
			setBlocking(player, value == true)
		end
	end)

	local function watch(player: Player)
		player.CharacterAdded:Connect(function()
			local state = stateOf(player)
			state.SpawnedAt = os.clock()
			state.KOUntil = 0
			state.Blocking = false
			state.Combo = 0
			player:SetAttribute("KO", nil)
			player:SetAttribute("Blocking", nil)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
end

return CombatService
