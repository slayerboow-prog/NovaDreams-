-- CombatService: golpes entre jugadores (y a los personajes de tus misiones), siempre decidido aquí.
--
-- El cliente solo avisa: "Attack" (he pulsado golpear), "Block" (me defiendo / dejo de defenderme) y
-- "Dodge" (esquivo: un instante en que los golpes no me dan, con su pausa).
-- El servidor comprueba todo (pausas entre golpes, distancia, que esté delante, quién puede recibir),
-- calcula el daño (shared/Combat) y avisa a todos para que se vea y se oiga el golpe.
--
-- K.O.: al quedarte sin vida caes Combat.KOSeconds segundos (sin poder pegar) y te levantas con
-- parte de la vida. Si alguien te golpea mientras estás K.O., te remata: mueres y reapareces en el
-- hospital (HospitalService). HitSomeone lleva Killed = true (homicidio para WantedService).
-- Para las misiones y la policía: StoryEvents "HitSomeone" (Target/Npc/Model/KO), "GotHit" y
-- "KnockedOut". Los agentes de policía (Officer) sí reciben daño y caen (WantedService lo castiga).
-- Las armas (WeaponService) usan el mismo camino con CombatService.applyHit: mismo K.O., misma
-- muerte y hospital, mismos avisos (HitSomeone lleva Weapon = id del arma).

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

type State = { Combo: number, LastAt: number, Blocking: boolean, KOUntil: number, SpawnedAt: number, DodgeAt: number?, Stunned: boolean? }

local states: { [Player]: State } = {}
local Remote: RemoteEvent

local function stateOf(player: Player): State
	local state = states[player]
	if not state then
		state = { Combo = 0, LastAt = 0, Blocking = false, KOUntil = 0, SpawnedAt = -math.huge } -- (al aparecer se pone la hora: CharacterAdded)
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
	if player:GetAttribute("InDialogue") or player:GetAttribute("Training") then
		return false -- (en una conversación o entrenando en el gimnasio no se pelea)
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

local function knockOut(victim: Player, humanoid: Humanoid, seconds: number?)
	local state = stateOf(victim)
	local duration = seconds or Combat.KOSeconds
	state.KOUntil = os.clock() + duration
	-- En el suelo por el táser (con vida) no es lo mismo que K.O. sin vida: a ese no se le remata
	state.Stunned = seconds ~= nil
	state.Blocking = false
	victim:SetAttribute("Blocking", nil)
	victim:SetAttribute("KO", true)
	StoryEvents.emit(victim, "KnockedOut", {})
	task.delay(duration, function()
		if victim.Parent and os.clock() >= state.KOUntil - 0.05 then
			victim:SetAttribute("KO", nil)
		end
		if humanoid.Parent and humanoid.Health > 0 then
			humanoid.Health = math.max(humanoid.Health, humanoid.MaxHealth * Combat.KOHealth)
		end
	end)
end

-- ¿Se le puede rematar? Solo si está K.O. por quedarse sin vida (o, aturdido, ya casi sin ella).
-- Antes un táser y un puñetazo mataban a alguien con la vida entera.
local function canFinish(victim: Player, humanoid: Humanoid): boolean
	if not (os.clock() < stateOf(victim).KOUntil) then
		return false
	end
	return not stateOf(victim).Stunned or humanoid.Health <= humanoid.MaxHealth * Combat.KOHealth
end

-- Aturdido por el táser pero con vida: no se le remata, los golpes le quitan vida como siempre
local function stunnedOnly(victim: Player, humanoid: Humanoid): boolean
	return os.clock() < stateOf(victim).KOUntil and not canFinish(victim, humanoid)
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

	-- Zonas seguras (hospital, colegio, casas…): ni se pega desde ellas ni a quien está dentro.
	-- (WeaponService requiere este módulo: se pide aquí, no arriba)
	local WeaponService = require(script.Parent.WeaponService) :: any
	local attackerSafe = WeaponService.safeSpot(root.Position) ~= nil
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
		-- A otro jugador solo si estáis en el mismo sitio (mismo interior o los dos fuera) y fuera de
		-- zonas seguras: teletransportarse a su lado dentro de su casa no vale
		if victim and (attackerSafe or victim:GetAttribute("InteriorKey") ~= player:GetAttribute("InteriorKey") or WeaponService.safeSpot(targetRoot.Position)) then
			continue
		end
		local direction = Vector3.new(targetRoot.Position.X - root.Position.X, 0, targetRoot.Position.Z - root.Position.Z)
		direction = if direction.Magnitude > 0.01 then direction.Unit else root.CFrame.LookVector
		if victim and canFinish(victim, targetHumanoid) and not isProtected(victim) then
			-- Rematar a alguien que está K.O.: muere
			hits += 1
			targetHumanoid.Health = 0
			Remote:FireAllClients("Hit", { Victim = model, Attacker = player, Amount = Combat.damage(combo, ProgressionService.stat(player, "Fuerza")), Blocked = false, Combo = combo, Direction = direction, Knockback = Combat.Knockback[3], KO = true })
			StoryEvents.emit(player, "HitSomeone", { Target = victim.UserId, Model = model, KO = true, Killed = true })
			StoryEvents.emit(victim, "GotHit", { By = player.UserId })
		elseif victim then
			if (not canFight(victim) and not stunnedOnly(victim, targetHumanoid)) or isProtected(victim) then
				continue
			end
			local victimState = stateOf(victim)
			-- Esquivando: el golpe no le da
			if Combat.dodging(victimState.DodgeAt, now) then
				continue
			end
			-- Defenderse solo sirve si miras hacia quien te pega
			local facing = targetRoot.CFrame.LookVector:Dot(-direction) > 0.2
			local blocked = victimState.Blocking and facing
			local amount = Combat.damage(combo, ProgressionService.stat(player, "Fuerza"), blocked, player:GetAttribute("GymStrength"))
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
			local amount = Combat.damage(combo, ProgressionService.stat(player, "Fuerza"), false, player:GetAttribute("GymStrength"))
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

export type HitInfo = {
	Amount: number,
	Direction: Vector3,
	Weapon: string?,
	Heavy: boolean?,
	Stun: number?, -- táser: segundos en el suelo sin quitar vida
	Toy: boolean?, -- de juguete: solo reacciona
	At: Vector3?, -- dónde ha dado (para el número de daño)
	Zone: string?,
}
export type HitResult = { Hit: boolean, Amount: number, KO: boolean, Killed: boolean, Player: Player? }

-- Daño que llega de un arma (o de otra cosa que no es un puñetazo), con las mismas reglas que un golpe:
-- K.O. al quedarse sin vida, rematar a alguien K.O. lo mata, protección al aparecer y en vehículos,
-- agentes de policía que caen y personajes de misión que solo reaccionan.
function CombatService.applyHit(attacker: Player, model: Model, info: HitInfo): HitResult
	local none = { Hit = false, Amount = 0, KO = false, Killed = false, Player = nil }
	local targetHumanoid, targetRoot = parts(model)
	if not targetHumanoid or targetHumanoid.Health <= 0 or not targetRoot or model == attacker.Character then
		return none
	end
	local victim = Players:GetPlayerFromCharacter(model)
	local heavy = info.Heavy == true
	local function show(amount: number, ko: boolean)
		Remote:FireAllClients("Hit", {
			Victim = model, Attacker = attacker, Amount = amount, Blocked = false, Combo = if heavy then 3 else 1,
			Direction = info.Direction, Knockback = 0, KO = ko, Weapon = info.Weapon, At = info.At, Zone = info.Zone, Toy = info.Toy,
		})
	end
	if victim then
		if isProtected(victim) then
			return none
		end
		if info.Toy then
			if not canFight(victim) then
				return none
			end
			show(0, false)
			return { Hit = true, Amount = 0, KO = false, Killed = false, Player = victim }
		end
		if not CombatService.isKnockedOut(victim) and not canFight(victim) then
			return none -- (bebés, en una conversación, en clase…)
		end
		if CombatService.isKnockedOut(victim) and (info.Stun or 0) > 0 then
			return none -- (el táser no remata ni alarga el K.O.)
		end
		if canFinish(victim, targetHumanoid) then
			-- Rematar a alguien que está K.O.: muere
			targetHumanoid.Health = 0
			show(info.Amount, true)
			StoryEvents.emit(attacker, "HitSomeone", { Target = victim.UserId, Model = model, KO = true, Killed = true, Weapon = info.Weapon })
			StoryEvents.emit(victim, "GotHit", { By = attacker.UserId })
			return { Hit = true, Amount = info.Amount, KO = true, Killed = true, Player = victim }
		end
		local amount = math.max(0, math.floor(info.Amount + 0.5))
		local health, ko = Combat.apply(targetHumanoid.Health, amount)
		if amount <= 0 then
			health, ko = targetHumanoid.Health, false
		end
		targetHumanoid.Health = health
		local stunned = (info.Stun or 0) > 0
		if stunned then
			ko = true
		end
		show(amount, ko)
		StoryEvents.emit(attacker, "HitSomeone", { Target = victim.UserId, Model = model, KO = ko, Weapon = info.Weapon })
		StoryEvents.emit(victim, "GotHit", { By = attacker.UserId })
		if ko then
			knockOut(victim, targetHumanoid, if stunned then info.Stun else nil)
		end
		return { Hit = true, Amount = amount, KO = ko, Killed = false, Player = victim }
	elseif model:GetAttribute("Officer") then
		if model:GetAttribute("Down") or info.Toy then
			return none
		end
		local hp = (model:GetAttribute("Hp") or 0) - info.Amount
		if (info.Stun or 0) > 0 then
			hp = 0
		end
		model:SetAttribute("Hp", hp)
		show(info.Amount, hp <= 0)
		if hp <= 0 then
			PoliceUnits.knockDown(model)
		end
		StoryEvents.emit(attacker, "HitSomeone", { Model = model, KO = hp <= 0, Weapon = info.Weapon })
		return { Hit = true, Amount = info.Amount, KO = hp <= 0, Killed = false, Player = nil }
	elseif npcBelongsTo(model, attacker) then
		-- Personajes (de misión, del cole…): reaccionan pero no se hacen daño
		show(0, false)
		if not info.Toy then
			StoryEvents.emit(attacker, "HitSomeone", { Npc = model:GetAttribute("NpcId") or model.Name, Model = model, Weapon = info.Weapon })
		end
		return { Hit = true, Amount = 0, KO = false, Killed = false, Player = nil }
	end
	return none
end

-- ¿Puede pelear o recibir? (para las armas: mismas condiciones que los golpes)
function CombatService.canFight(player: Player): boolean
	return canFight(player)
end

-- ¿Recién aparecido o sentado? (tampoco se le puede robar: WantedService)
function CombatService.isProtected(player: Player): boolean
	return isProtected(player)
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
		elseif kind == "Dodge" then
			-- Esquivar (con su pausa: no se puede estar esquivando siempre)
			local state = stateOf(player)
			local now = os.clock()
			if canFight(player) and (state.DodgeAt == nil or now - state.DodgeAt >= Combat.DodgeCooldown * 0.8) then
				state.DodgeAt = now
				state.Blocking = false
				player:SetAttribute("Blocking", nil)
			end
		end
	end)

	local function watch(player: Player)
		player.CharacterAdded:Connect(function()
			local state = stateOf(player)
			state.SpawnedAt = os.clock()
			state.KOUntil = 0
			state.Stunned = nil
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
