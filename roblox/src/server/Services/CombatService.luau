-- CombatService: la pelea, siempre decidida aquí (jugadores contra jugadores, contra los rivales de
-- FighterService y contra los personajes de tus misiones).
--
-- ESTILO (shared/Combat; parecido a los juegos de lucha en 3D con combos y poderes):
--   * Ligero ("Light", y "Attack" de antes): combo de hasta 6 golpes; el sexto empuja.
--   * Fuerte ("Heavy"): solo o como final del combo (lanzador, empujón lejano, golpe al suelo, remate
--     aéreo). Mantenerlo ("HeavyHold" al pulsar, "Heavy", true al soltar) = golpe cargado que rompe la guardia.
--   * Guardia ("Block"): quita casi todo el daño pero gasta la barra de guardia; vacía = aturdido.
--   * Esquivar ("Dodge"): voltereta (con un instante sin recibir golpes) o, con aguante, DESVANECERSE
--     ("Dodge", "Vanish"): apareces detrás o a un lado del rival. Justo después de recibir un golpe
--     sirve para escapar del combo (cuesta más aguante).
--   * Golpes con impacto: aturden (Stun), derriban (Down: en el suelo y te levantas), lanzan al aire
--     (Air) y empujan (Knockback/Lift). El cliente congela el impacto (Hitstop), tiembla la cámara,
--     salen partículas y el empujón manda a volar (puede chocar con una pared).
--   * Poderes (shared/Powers): Energía ("Charge" mantener), habilidades ("PowerHold"/"Power") y la
--     definitiva ("Ultimate"). Bloqueados hasta que la Saga de la Grieta los despierta; en Modo pruebas
--     (TesterService.bypass) están todos. Impulso aéreo ("AirDash"): gasta aguante.
--   * Fijar objetivo ("Lock", modelo): alcanzas un poco más y los poderes van hacia él.
-- Atributos para el cliente (jugador; en los rivales, en su modelo): Aguante, Energia, Guardia,
-- Powers ("Energia,Esferas,…"), Charging, Blocking, KO, Roll, StunUntil/DownUntil (hora del servidor).
--
-- K.O.: al quedarte sin vida caes Combat.KOSeconds segundos (sin poder pegar, «HAS CAÍDO EN COMBATE»)
-- y luego SIEMPRE despiertas en el hospital (HospitalService); si alguien te golpea mientras estás
-- K.O., te remata antes (homicidio). Si te detiene la policía estando K.O., vas detenido (no al
-- hospital). El táser solo te tumba unos segundos con tu vida (parte de una detención). HitSomeone lleva Killed = true (homicidio para WantedService).
-- Para las misiones y la policía: StoryEvents "HitSomeone" (Target/Npc/Model/KO, Melee, Street, Rival,
-- Power), "GotHit" y "KnockedOut". Los agentes de policía (Officer) sí reciben daño y caen
-- (WantedService lo castiga). Pegar a un paseante (Crowd) es agresión (WantedService); a un rival de
-- entrenamiento (FighterService), no.
-- Las armas (WeaponService) usan el mismo camino con CombatService.applyHit: mismo K.O., misma
-- muerte y hospital, mismos avisos (HitSomeone lleva Weapon = id del arma).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Combat = require(ReplicatedStorage.Shared.Combat)
local Powers = require(ReplicatedStorage.Shared.Powers)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local ProgressionService = require(script.Parent.ProgressionService)
local ClassService = require(script.Parent.ClassService)
local MiniGameService = require(script.Parent.MiniGameService)
local DataService = require(script.Parent.DataService)
local TesterService = require(script.Parent.TesterService)
local PoliceUnits = require(script.Parent.Parent.World.PoliceUnits)
local DamageService = require(script.Parent.DamageService) -- el daño por puntos (enemigos de misión)
local EnemyStats = require(ReplicatedStorage.Shared.EnemyStats)

local CombatService = {}

export type State = {
	Combo: number,
	LastAt: number,
	Blocking: boolean,
	KOUntil: number,
	SpawnedAt: number,
	DodgeAt: number?,
	Stunned: boolean?,
	-- estilo de lucha
	Chain: Combat.Chain,
	LastMove: string?,
	BlockSince: number,
	Guard: number,
	GuardAt: number,
	Stamina: number,
	StaminaAt: number,
	Energy: number,
	StunUntil: number,
	DownUntil: number,
	AirUntil: number,
	InvulnUntil: number,
	BusyUntil: number,
	Charging: boolean,
	HeavyHoldAt: number?,
	PowerHoldAt: number?,
	PowerHoldId: string?,
	Cooldowns: { [string]: number },
	LastHitAt: number,
	LastHitBy: Model?,
	LastVanish: number,
	SwingAt: number,
	Lock: Model?,
	Powers: { [string]: boolean },
	PowersText: string?,
	Published: { [string]: any },
	-- quién es
	Player: Player?,
	Model: Model?, -- (rivales: su modelo; jugadores: su personaje del momento)
	Npc: boolean?,
	DamageMul: number,
	Defeated: boolean?,
	OwnerId: number?, -- (rivales: el jugador con el que pelean)
	WallAt: number?, -- (último aviso de «contra la pared»: no se repite enseguida)
	ArrestedInKO: boolean?, -- (te han detenido estando K.O.: no vas al hospital)
}

local states: { [Player]: State } = {}
local npcStates: { [Model]: State } = {}
local Remote: RemoteEvent
local Notify: RemoteEvent? = nil

-- Lo que hace FighterService con sus rivales (los mueve él: están anclados y van por CFrame)
CombatService.npcHooks = {
	knock = nil :: ((Model, Vector3, number, { [string]: any }) -> ())?,
	defeat = nil :: ((Model, Player?) -> ())?,
	vanish = nil :: ((Model, Vector3, Vector3) -> ())?,
	roll = nil :: ((Model, Vector3) -> ())?,
}

local function newState(player: Player?, model: Model?): State
	return {
		Combo = 0,
		LastAt = 0,
		Blocking = false,
		KOUntil = 0,
		SpawnedAt = -math.huge,
		Chain = Combat.newChain(),
		BlockSince = 0,
		Guard = Combat.GuardMax,
		GuardAt = -math.huge,
		Stamina = Combat.StaminaMax,
		StaminaAt = -math.huge,
		Energy = 0,
		StunUntil = 0,
		DownUntil = 0,
		AirUntil = 0,
		InvulnUntil = 0,
		BusyUntil = 0,
		Charging = false,
		Cooldowns = {},
		LastHitAt = -math.huge,
		LastVanish = -math.huge,
		SwingAt = -math.huge,
		Powers = {},
		Published = {},
		Player = player,
		Model = model,
		DamageMul = 1,
	}
end

local function stateOf(player: Player): State
	local state = states[player]
	if not state then
		state = newState(player, nil) -- (al aparecer se pone la hora: CharacterAdded)
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

local function modelOf(state: State): Model?
	if state.Player then
		return state.Player.Character
	end
	return state.Model
end

-- Quién pega, tal y como lo ven los clientes: el jugador (Player) o el modelo del rival
local function refOf(state: State): Instance?
	return state.Player or state.Model
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
	if player:GetAttribute("InDialogue") or player:GetAttribute("Training") or player:GetAttribute("Fallen") == "Mission" then
		return false -- (en una conversación, entrenando en el gimnasio o caído en un combate de misión no se pelea)
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

-- Enemigos de un combate de misión (SceneService les pone MissionEnemy): un disparo (también la
-- pistola de agua contra los «de juguete»), un golpe o un poder les quita VIDA por puntos con
-- DamageService (la función central del daño; la vida la lleva la misión: LifeStoryService).
-- Devuelve nil si no es un enemigo de misión, true si el daño cuenta y false si no (es de otro
-- jugador, ya ha caído o ya no está en combate); y el resultado de DamageService.
local function missionTarget(attacker: Player?, model: Model, kind: string?, amount: number?, info: { [string]: any }?): (boolean?, { [string]: any }?)
	if model:GetAttribute("MissionEnemy") == nil then
		return nil, nil
	end
	if not attacker or not npcBelongsTo(model, attacker) then
		return false, nil
	end
	local ok, result = pcall(DamageService.apply, attacker, model, amount or 0, kind or "Attack", nil, info)
	if not ok then
		warn("[Combate] " .. tostring(result))
		return false, nil
	end
	return result.Hit == true, result
end
CombatService.missionTarget = missionTarget

-- Atributos para el cliente (solo si cambian, redondeados: no se manda nada cada fotograma)
local function publish(state: State, key: string, value: any)
	if state.Published[key] == value then
		return
	end
	state.Published[key] = value
	local holder: Instance? = state.Player or state.Model
	if holder then
		holder:SetAttribute(key, value)
	end
end

local function publishBars(state: State)
	publish(state, "Aguante", math.floor(state.Stamina + 0.5))
	publish(state, "Guardia", math.floor(state.Guard + 0.5))
	publish(state, "Energia", if state.Powers.Energia or state.Npc then math.floor(state.Energy + 0.5) else nil)
end

local function serverTime(seconds: number): number
	return workspace:GetServerTimeNow() + seconds
end

local function setBlocking(state: State, value: boolean)
	if state.Blocking == value then
		return
	end
	state.Blocking = value
	if value then
		state.BlockSince = os.clock()
	end
	local holder: Instance? = state.Player or state.Model
	if holder then
		holder:SetAttribute("Blocking", if value then true else nil)
	end
	if state.Npc and Remote then
		Remote:FireAllClients("Guard", state.Model, value)
	end
end

local function setCharging(state: State, value: boolean)
	if state.Charging == value then
		return
	end
	state.Charging = value
	local holder: Instance? = state.Player or state.Model
	if holder then
		holder:SetAttribute("Charging", if value then true else nil)
	end
end

local function knockOut(victim: Player, humanoid: Humanoid, seconds: number?, soft: boolean?)
	local state = stateOf(victim)
	local duration = seconds or Combat.KOSeconds
	state.KOUntil = os.clock() + duration
	-- En el suelo por el táser (con vida) no es lo mismo que K.O. sin vida: a ese no se le remata
	state.Stunned = seconds ~= nil
	state.ArrestedInKO = nil
	victim:SetAttribute("ArrestedInKO", nil)
	setBlocking(state, false)
	setCharging(state, false)
	-- Sin vida (no el táser): «HAS CAÍDO EN COMBATE» (Controllers/DeathUI). En una pelea con otro
	-- jugador, a los KOSeconds en el suelo (o antes, si alguien te remata) mueres y despiertas en el
	-- hospital (HospitalService). Si mientras estás K.O. te detiene la policía, la detención manda: vas
	-- a comisaría, no al hospital.
	-- soft: un atropello o perder contra el rival de entrenamiento (FighterService): K.O. sin hospital,
	-- te levantas con KOHealth (Fallen = "Down").
	-- El táser (seconds) solo te tumba unos segundos con tu vida: es parte de una detención.
	if seconds == nil then
		victim:SetAttribute("Fallen", if soft then "Down" else "Combat")
	end
	victim:SetAttribute("KO", true)
	StoryEvents.emit(victim, "KnockedOut", {})
	task.delay(duration, function()
		if not (victim.Parent and os.clock() >= state.KOUntil - 0.05) then
			return -- (otro K.O. más reciente manda)
		end
		local how = victim:GetAttribute("Fallen")
		local fallen = how == "Combat"
		if how == "Combat" or how == "Down" then
			victim:SetAttribute("Fallen", nil)
		end
		victim:SetAttribute("KO", nil)
		victim:SetAttribute("ArrestedInKO", nil)
		if not humanoid.Parent or humanoid.Health <= 0 then
			return
		end
		if fallen and not state.Stunned and not state.ArrestedInKO then
			humanoid.Health = 0 -- (al hospital: HospitalService)
		else
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

local function flatLook(root: BasePart): Vector3
	local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	return if look.Magnitude > 0.01 then look.Unit else Vector3.new(0, 0, -1)
end

-- A quién alcanza un golpe: humanoides delante del atacante, los más cercanos primero
local function victimsOf(attacker: Model, root: BasePart, reach: number?): { Model }
	local range = Combat.Range + (reach or 0)
	local look = flatLook(root)
	local center = root.Position + look * (range / 2)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { attacker :: Instance }
	local found: { [Model]: number } = {}
	for _, part in workspace:GetPartBoundsInRadius(center, range / 2 + Combat.HitRadius / 2, params) do
		local model = humanoidModel(part)
		if model and model ~= attacker and not found[model] then
			local _, targetRoot = parts(model)
			local at = if targetRoot then targetRoot.Position else part.Position
			local offset = Vector3.new(at.X - root.Position.X, 0, at.Z - root.Position.Z)
			local distance = offset.Magnitude
			if distance <= range + 1 and (distance < 1 or offset.Unit:Dot(look) >= Combat.FacingDot) then
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

-- Personajes alrededor de un punto (poderes), los más cercanos primero
local function modelsNear(attacker: Model, center: Vector3, radius: number): { Model }
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { attacker :: Instance }
	local found: { [Model]: number } = {}
	local ok, list = pcall(function()
		return workspace:GetPartBoundsInRadius(center, radius, params)
	end)
	if not ok then
		return {}
	end
	for _, part in list do
		local model = humanoidModel(part)
		if model and model ~= attacker and not found[model] then
			local _, r = parts(model)
			found[model] = ((if r then r.Position else part.Position) - center).Magnitude
		end
	end
	local out = {}
	for model in found do
		table.insert(out, model)
	end
	table.sort(out, function(a, b)
		return found[a] < found[b]
	end)
	return out
end

local function weaponService(): any
	-- (WeaponService requiere este módulo: se pide aquí, no arriba)
	return require(script.Parent.WeaponService) :: any
end

local function safeSpot(position: Vector3): boolean
	local ok, spot = pcall(function()
		return weaponService().safeSpot(position)
	end)
	return ok and spot ~= nil
end

---------------------------------------------------------------------
-- Un golpe (o un poder) que llega a un personaje
---------------------------------------------------------------------
type HitOpts = { Amount: number?, At: Vector3?, Power: string?, Name: string? }

local function fireHit(data: { [string]: any })
	if Remote then
		Remote:FireAllClients("Hit", data)
	end
end

local function hitModel(att: State, attModel: Model, attRoot: BasePart, model: Model, name: string, move: Combat.Move, direction: Vector3, opts: HitOpts?): boolean
	local o = opts or {}
	local targetHumanoid, targetRoot = parts(model)
	if not targetHumanoid or targetHumanoid.Health <= 0 or not targetRoot or model == attModel then
		return false
	end
	if model:GetAttribute("MissionEnemy") ~= nil then
		-- Un enemigo de misión: le quita vida por puntos (cuerpo a cuerpo: EnemyStats.Sources; un
		-- poder: su daño). DamageService decide; el número y la barra los pinta el cliente que pega.
		local heavyMove = move.Heavy == true or move.Energy == true
		local kind = if o.Power then "Power" elseif heavyMove then "MeleeHeavy" else "Melee"
		local amount = if o.Power then (o.Amount or EnemyStats.Sources.MeleeHeavy) * att.DamageMul else nil
		local counted = missionTarget(att.Player, model, kind, amount, { At = o.At, Direction = direction })
		return counted == true
	end
	local attPlayer = att.Player
	local ref = refOf(att)
	local victim = Players:GetPlayerFromCharacter(model)
	local now = os.clock()
	local heavy = move.Heavy == true or move.Energy == true
	local fuerza = if attPlayer then ProgressionService.stat(attPlayer, "Fuerza") else 0
	local muscle = if attPlayer then attPlayer:GetAttribute("GymStrength") else nil
	local function amountFor(blocked: boolean): number
		if o.Amount then
			local a = o.Amount * att.DamageMul
			if blocked then
				a *= Combat.BlockFactor
			end
			return math.max(1, math.floor(a + 0.5))
		end
		return Combat.moveDamage(name, fuerza, muscle, blocked, att.DamageMul)
	end
	local base = {
		Victim = model,
		Attacker = ref,
		AttackerModel = attModel,
		Combo = if heavy then 3 else 1,
		Move = name,
		Direction = direction,
		At = o.At,
		Power = o.Power,
		Energy = move.Energy,
	}
	local function send(extra: { [string]: any })
		for k, v in extra do
			base[k] = v
		end
		fireHit(base)
	end

	local vstate: State? = nil
	if not attPlayer and (not victim or (att.OwnerId ~= nil and victim.UserId ~= att.OwnerId)) then
		return false -- (un rival solo pelea con quien lo ha sacado)
	end
	if victim then
		-- Zonas seguras (hospital, colegio, casas…): ni se pega desde ellas ni a quien está dentro. Y a
		-- otro jugador solo si estáis en el mismo sitio (mismo interior o los dos fuera)
		if safeSpot(targetRoot.Position) or (attPlayer and (safeSpot(attRoot.Position) or victim:GetAttribute("InteriorKey") ~= attPlayer:GetAttribute("InteriorKey"))) then
			return false
		end
		if attPlayer and canFinish(victim, targetHumanoid) and not isProtected(victim) then
			-- Rematar a alguien que está K.O.: muere
			targetHumanoid.Health = 0
			send({ Amount = amountFor(false), Blocked = false, Knockback = Combat.Knockback[3], Lift = 0, KO = true, Hitstop = move.Hitstop })
			StoryEvents.emit(attPlayer, "HitSomeone", { Target = victim.UserId, Model = model, KO = true, Killed = true, Melee = o.Power == nil, Power = o.Power })
			StoryEvents.emit(victim, "GotHit", { By = attPlayer.UserId })
			return true
		end
		if (not canFight(victim) and not stunnedOnly(victim, targetHumanoid)) or isProtected(victim) then
			return false
		end
		if not attPlayer and CombatService.isKnockedOut(victim) then
			return false -- (un rival no remata)
		end
		vstate = stateOf(victim)
	elseif npcStates[model] then
		vstate = npcStates[model]
		if attPlayer and not npcBelongsTo(model, attPlayer) then
			return false
		end
		if (vstate :: State).Defeated then
			return false
		end
	elseif model:GetAttribute("Officer") then
		-- Agentes de policía (WantedService): se les puede tumbar, pero es un delito grave
		if not attPlayer or model:GetAttribute("Down") or safeSpot(attRoot.Position) then
			return false
		end
		local amount = amountFor(false)
		local hp = (model:GetAttribute("Hp") or 0) - amount
		model:SetAttribute("Hp", hp)
		send({ Amount = amount, Blocked = false, Knockback = 0, Lift = 0, KO = hp <= 0, Hitstop = move.Hitstop })
		if hp <= 0 then
			PoliceUnits.knockDown(model)
		end
		StoryEvents.emit(attPlayer, "HitSomeone", { Model = model, KO = hp <= 0, Melee = o.Power == nil, Power = o.Power })
		return true
	elseif attPlayer and npcBelongsTo(model, attPlayer) then
		-- Personajes (de misión, del cole, paseantes…): reaccionan pero no se hacen daño
		if safeSpot(attRoot.Position) then
			return false
		end
		local npcId = model:GetAttribute("NpcId")
		send({ Amount = 0, Blocked = false, Knockback = 0, Lift = 0, KO = false, Hitstop = move.Hitstop })
		StoryEvents.emit(attPlayer, "HitSomeone", { Npc = npcId or model.Name, Model = model, Melee = o.Power == nil, Power = o.Power, Street = model:GetAttribute("Crowd") ~= nil })
		return true
	else
		return false
	end

	local vs = vstate :: State
	-- Esquivando (voltereta o desvanecerse) o levantándose del suelo: no le da
	if Combat.dodging(vs.DodgeAt, now) or now < vs.InvulnUntil then
		if Remote then
			Remote:FireAllClients("Miss", model)
		end
		return false
	end
	-- En el suelo (derribado) no se le pega: hay que esperar a que se levante
	if now < vs.DownUntil then
		return false
	end
	-- Defenderse solo sirve si miras hacia quien te pega (y no estás aturdido)
	local facing = targetRoot.CFrame.LookVector:Dot(-direction) > 0.2
	local blocked = vs.Blocking and facing and Combat.canAct(now, vs.StunUntil, vs.DownUntil)
	local guardBroken = false
	if blocked then
		local guard, broken = Combat.guardHit(vs.Guard, move)
		vs.Guard = guard
		vs.GuardAt = now
		if broken then
			guardBroken = true
			setBlocking(vs, false)
			vs.StunUntil = now + Combat.GuardBreakStun
			publish(vs, "StunUntil", serverTime(Combat.GuardBreakStun))
			-- (un golpe que rompe guardias entra entero; uno normal que la vacía, solo el roce)
			blocked = not move.GuardBreak
			task.delay(Combat.GuardBreakStun, function()
				if vs.Guard < Combat.GuardAfterBreak then
					vs.Guard = Combat.GuardAfterBreak
				end
			end)
		end
	end
	local amount = amountFor(blocked)
	local stun, down, air = 0, nil, nil
	if not blocked then
		stun = Combat.stunFor(move)
		vs.StunUntil = math.max(vs.StunUntil, now + stun)
		publish(vs, "StunUntil", serverTime(vs.StunUntil - now))
		if move.Down then
			down = move.Down
			vs.DownUntil = now + move.Down
			vs.InvulnUntil = vs.DownUntil + Combat.GetUpInvulnerable
			vs.AirUntil = 0
			publish(vs, "DownUntil", serverTime(move.Down))
		elseif move.Air then
			air = move.Air
			vs.AirUntil = now + move.Air
			-- El que pega sube detrás (lanzador) o sigue en el aire (golpes aéreos)
			if move.Launch or now < att.AirUntil then
				att.AirUntil = now + move.Air
			end
		end
		vs.Chain = Combat.newChain()
		setCharging(vs, false)
	end
	vs.LastHitAt = now
	vs.LastHitBy = attModel
	-- Energía: sube al pegar (más si entra) y un poco al recibir
	if att.Powers.Energia or att.Npc then
		att.Energy = math.min(Combat.EnergyMax, att.Energy + (if blocked then Combat.EnergyPerHit / 2 else Combat.EnergyPerHit))
	end
	if vs.Powers.Energia or vs.Npc then
		vs.Energy = math.min(Combat.EnergyMax, vs.Energy + Combat.EnergyWhenHit)
	end
	publishBars(att)
	publishBars(vs)

	local ko = false
	if victim then
		local health
		health, ko = Combat.apply(targetHumanoid.Health, amount)
		targetHumanoid.Health = health
	else
		local hp = targetHumanoid.Health - amount
		if hp <= 0 then
			ko = true
			vs.Defeated = true
			targetHumanoid.Health = math.max(1, hp) -- (no muere: cae derrotado; FighterService lo quita)
		else
			targetHumanoid.Health = hp
		end
	end
	local knockback = if blocked then move.Knockback * 0.15 else move.Knockback
	local lift = if blocked then 0 else move.Lift
	send({
		Amount = amount,
		Blocked = blocked,
		GuardBroken = guardBroken,
		Knockback = knockback,
		Lift = lift,
		Stun = stun,
		Down = down,
		Air = air,
		Launch = move.Launch and not blocked,
		Wall = move.Wall and not blocked,
		Hitstop = move.Hitstop,
		Label = if blocked then nil else (if guardBroken then "¡Guardia rota!" else move.Label),
		KO = ko,
	})
	if victim then
		if attPlayer then
			StoryEvents.emit(attPlayer, "HitSomeone", { Target = victim.UserId, Model = model, KO = ko, Melee = o.Power == nil, Power = o.Power })
			StoryEvents.emit(victim, "GotHit", { By = attPlayer.UserId })
		else
			StoryEvents.emit(victim, "GotHit", { By = 0, Rival = true })
		end
		if ko then
			-- (perder contra el rival de entrenamiento no te manda al hospital: te levantas)
			knockOut(victim, targetHumanoid, nil, attPlayer == nil)
		end
	else
		-- Rival (FighterService): se mueve en el servidor
		if attPlayer then
			StoryEvents.emit(attPlayer, "HitSomeone", { Npc = model:GetAttribute("NpcId") or model.Name, Model = model, KO = ko, Rival = true, Melee = o.Power == nil, Power = o.Power })
		end
		local hooks = CombatService.npcHooks
		if hooks.knock then
			pcall(hooks.knock, model, direction * knockback, lift, { Down = down, Air = air, Wall = move.Wall and not blocked, Hitstop = move.Hitstop })
		end
		if ko and hooks.defeat then
			pcall(hooks.defeat, model, attPlayer)
		end
	end
	return true
end

---------------------------------------------------------------------
-- Golpes cuerpo a cuerpo
---------------------------------------------------------------------
local function canAct(state: State, now: number): boolean
	local model = modelOf(state)
	local humanoid, root = parts(model)
	if not humanoid or not root or humanoid.Health <= 0 or humanoid.SeatPart then
		return false
	end
	if state.Player and not canFight(state.Player) then
		return false
	end
	if state.Defeated or now < state.KOUntil or now < state.BusyUntil then
		return false
	end
	return Combat.canAct(now, state.StunUntil, state.DownUntil)
end

local function strike(state: State, kind: string, charged: boolean?): string?
	local now = os.clock()
	if not canAct(state, now) or not Combat.readyMove(state.LastMove, state.LastAt, now, Combat.ReadySlack) then
		return nil
	end
	local model = modelOf(state) :: Model
	local _, root = parts(model)
	if not root then
		return nil
	end
	local airborne = now < state.AirUntil
	local name, chain = Combat.nextMove(state.Chain, kind, now, charged, airborne)
	local move = Combat.Moves[name]
	state.Chain = chain
	state.LastMove = name
	state.LastAt = now
	state.SwingAt = now
	state.Combo = if move.Heavy then 3 else math.clamp(chain.Lights, 1, 2)
	setBlocking(state, false)
	setCharging(state, false)
	-- Todos ven el golpe (el que pega ya lo está animando en su pantalla)
	Remote:FireAllClients("Swing", refOf(state), name)

	local reach = if state.Lock then Combat.LockReach else 0
	local look = flatLook(root)
	local list = victimsOf(model, root, reach)
	local hits = 0
	for _, target in list do
		if hits >= Combat.MaxTargets then
			break
		end
		local _, targetRoot = parts(target)
		if not targetRoot then
			continue
		end
		local direction = Vector3.new(targetRoot.Position.X - root.Position.X, 0, targetRoot.Position.Z - root.Position.Z)
		direction = if direction.Magnitude > 0.01 then direction.Unit else look
		if hitModel(state, model, root, target, name, move, direction) then
			hits += 1
		end
	end
	-- Sin nadie delante: ¿un cristal o una puerta? (patadas a la puerta; el golpe fuerte rompe cristales)
	local player = state.Player
	if hits == 0 and player and not safeSpot(root.Position) then
		local BreakService = require(script.Parent.BreakService) :: any
		if BreakService.meleeHit then
			for _, up in { 0, 1.6 } do
				local ok, what = pcall(BreakService.meleeHit, player, root.Position + Vector3.new(0, up, 0), look, Combat.Range + 1.5, move.Heavy == true)
				if ok and what then
					break
				end
			end
		end
	end
	return name
end

local function setBlockingFor(state: State, value: boolean)
	local now = os.clock()
	setBlocking(state, value and canAct(state, now))
	if state.Blocking then
		setCharging(state, false)
	end
end

---------------------------------------------------------------------
-- Esquivar: voltereta o desvanecerse
---------------------------------------------------------------------
local function vanish(state: State, wish: Vector3?): boolean
	local now = os.clock()
	local model = modelOf(state)
	local humanoid, root = parts(model)
	if not model or not humanoid or not root or humanoid.Health <= 0 or humanoid.SeatPart or state.Defeated then
		return false
	end
	if state.Player and not canFight(state.Player) then
		return false
	end
	if now < state.KOUntil or now < state.DownUntil or now - state.LastVanish < Combat.VanishCooldown then
		return false
	end
	local kind, cost = Combat.dodgeKind(state.Stamina, state.Lock ~= nil, now - state.LastHitAt, now < state.AirUntil)
	if kind ~= "Vanish" then
		return false
	end
	local escaping = now - state.LastHitAt <= Combat.VanishWindow
	state.Stamina -= cost
	state.StaminaAt = now
	state.LastVanish = now
	state.InvulnUntil = now + Combat.VanishInvulnerable
	state.StunUntil = 0
	state.Chain = Combat.newChain()
	publish(state, "StunUntil", nil)
	setBlocking(state, false)
	setCharging(state, false)
	-- ¿Dónde aparece? Detrás de quien le pegaba (escapar), o detrás / a un lado del fijado
	local foe: Model? = if escaping and state.LastHitBy then state.LastHitBy else state.Lock
	local _, foeRoot = parts(foe)
	local from = root.Position
	local dest: Vector3
	local face: Vector3
	if foeRoot and (foeRoot.Position - from).Magnitude < 60 then
		local foeLook = flatLook(foeRoot)
		local side = Vector3.new(-foeLook.Z, 0, foeLook.X)
		local w = if wish and typeof(wish) == "Vector3" and wish.Magnitude > 0.1 then Vector3.new(wish.X, 0, wish.Z).Unit else nil
		local offset: Vector3
		if w and math.abs(w:Dot(side)) > 0.6 then
			offset = side * (if w:Dot(side) > 0 then 1 else -1) * Combat.VanishDistance -- a un lado
		else
			offset = -foeLook * Combat.VanishDistance -- detrás
		end
		dest = Vector3.new(foeRoot.Position.X, from.Y, foeRoot.Position.Z) + offset
		face = foeRoot.Position
	else
		local w = if wish and typeof(wish) == "Vector3" and wish.Magnitude > 0.1 then Vector3.new(wish.X, 0, wish.Z).Unit else flatLook(root)
		dest = from + w * Combat.VanishDistance * 1.6
		face = dest + w
	end
	-- (sin atravesar paredes: si hay algo en medio, se queda antes)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model :: Instance, foe :: any }
	local ok, hit = pcall(function()
		return workspace:Raycast(from, dest - from, params)
	end)
	if ok and hit then
		dest = hit.Position - (dest - from).Unit * 1.5
	end
	if state.Npc then
		local hooks = CombatService.npcHooks
		if hooks.vanish then
			pcall(hooks.vanish, model, dest, face)
		end
	else
		pcall(function()
			model:PivotTo(CFrame.lookAt(dest, Vector3.new(face.X, dest.Y, face.Z)))
		end)
	end
	publishBars(state)
	Remote:FireAllClients("Vanish", refOf(state), from, dest)
	return true
end

local function roll(state: State, wish: Vector3?): boolean
	local now = os.clock()
	if not canAct(state, now) then
		return false
	end
	if state.DodgeAt ~= nil and now - state.DodgeAt < Combat.DodgeCooldown * 0.8 then
		return false
	end
	state.DodgeAt = now
	setBlocking(state, false)
	setCharging(state, false)
	if state.Player then
		-- La voltereta la ven todos (Controllers/RollMotion la dibuja con esta hora del servidor)
		state.Player:SetAttribute("Roll", workspace:GetServerTimeNow())
	else
		local model = state.Model :: Model
		model:SetAttribute("Roll", workspace:GetServerTimeNow())
		local hooks = CombatService.npcHooks
		if hooks.roll then
			pcall(hooks.roll, model, if wish and typeof(wish) == "Vector3" then wish else Vector3.zero)
		end
	end
	return true
end

---------------------------------------------------------------------
-- Poderes (shared/Powers)
---------------------------------------------------------------------
local function powerMove(p: Powers.Power, charge: number?): Combat.Move
	return {
		Damage = Powers.damage(p, charge),
		Knockback = p.Knockback,
		Lift = p.Lift,
		Stun = p.Stun,
		Recovery = 0.4,
		GuardDamage = if p.GuardBreak then 999 else 20,
		Hitstop = p.Hitstop,
		Anim = "Blast",
		Label = p.Name,
		Heavy = true,
		Down = p.Down,
		Wall = p.Wall,
		GuardBreak = p.GuardBreak,
		Energy = true,
	}
end

-- Hacia dónde va un poder: al fijado (si está cerca), o hacia donde apunta el cliente, o de frente
local function aimOf(state: State, root: BasePart, wish: any, range: number): Vector3
	local lockRoot: BasePart? = nil
	if state.Lock and state.Lock.Parent then
		local _, r = parts(state.Lock)
		lockRoot = r
	end
	if lockRoot and (lockRoot.Position - root.Position).Magnitude <= range + 10 then
		local d = lockRoot.Position - root.Position
		if d.Magnitude > 0.1 then
			return d.Unit
		end
	end
	if typeof(wish) == "Vector3" and wish.Magnitude > 0.1 and wish.Magnitude < 1e4 then
		local w = wish.Unit
		-- (no hacia el cielo ni contra el suelo)
		return Vector3.new(w.X, math.clamp(w.Y, -0.35, 0.5), w.Z).Unit
	end
	return flatLook(root)
end

local function hitAll(state: State, model: Model, root: BasePart, targets: { Model }, p: Powers.Power, move: Combat.Move, at: Vector3?, maxCount: number?): number
	local n = 0
	for _, target in targets do
		if maxCount and n >= maxCount then
			break
		end
		local _, tr = parts(target)
		if tr then
			local d = Vector3.new(tr.Position.X - root.Position.X, 0, tr.Position.Z - root.Position.Z)
			local dir = if d.Magnitude > 0.01 then d.Unit else flatLook(root)
			if hitModel(state, model, root, target, p.Id, move, dir, { Amount = move.Damage, At = at or tr.Position, Power = p.Id }) then
				n += 1
			end
		end
	end
	return n
end

-- Personajes en una línea (Onda, Embestida, definitiva)
local function modelsInLine(model: Model, origin: Vector3, dir: Vector3, length: number, width: number): { Model }
	local out = {}
	local seen = {}
	local step = math.max(width, 4)
	local along = 0
	while along <= length do
		for _, m in modelsNear(model, origin + dir * along, step) do
			if not seen[m] then
				local _, r = parts(m)
				if r then
					local inside = Powers.inLine(r.Position.X, r.Position.Y, r.Position.Z, origin.X, origin.Y, origin.Z, dir.X, dir.Y, dir.Z, length, width + 1)
					if inside then
						seen[m] = true
						table.insert(out, m)
					end
				end
			end
		end
		along += step
	end
	table.sort(out, function(a, b)
		local _, ra = parts(a)
		local _, rb = parts(b)
		return ((ra :: BasePart).Position - origin).Magnitude < ((rb :: BasePart).Position - origin).Magnitude
	end)
	return out
end

local function usePower(state: State, id: any, wish: any): boolean
	local now = os.clock()
	local p = Powers.get(id)
	if not p or p.Id == Powers.Ultimate.Id then
		return false
	end
	if not canAct(state, now) then
		return false
	end
	local ok = Powers.canUse(p, state.Powers, state.Energy, state.Cooldowns[p.Id], now)
	if not ok then
		return false
	end
	local model = modelOf(state) :: Model
	local _, root = parts(model)
	if not root then
		return false
	end
	local charge = 0
	if p.MaxCharge and state.PowerHoldId == p.Id and state.PowerHoldAt then
		charge = math.clamp(now - state.PowerHoldAt, 0, p.MaxCharge)
	end
	state.PowerHoldId, state.PowerHoldAt = nil, nil
	state.Energy -= p.Cost
	state.Cooldowns[p.Id] = now + p.Cooldown
	state.BusyUntil = now + 0.35
	state.LastMove, state.LastAt = nil, now
	setBlocking(state, false)
	setCharging(state, false)
	publishBars(state)
	local aim = aimOf(state, root, wish, p.Range)
	local origin = root.Position + Vector3.new(0, 0.6, 0)
	Remote:FireAllClients("Power", refOf(state), p.Id, { Origin = origin, Dir = aim, Charge = charge, Target = state.Lock })
	local move = powerMove(p, charge)
	if p.Id == "Esferas" then
		-- Esferas seguidas: cada una vuela y da al primero que encuentra
		task.spawn(function()
			for i = 1, p.Count or 1 do
				local lock = state.Lock
				task.spawn(function()
					local pos = root.Position + Vector3.new(0, 0.6, 0) + aim * 2
					local dir = aim
					local travelled = 0
					local dt = 1 / 30
					while travelled < p.Range and model.Parent do
						-- (va un poco hacia el fijado)
						local _, lr = parts(lock)
						if lr then
							local want = lr.Position - pos
							if want.Magnitude > 0.5 then
								dir = (dir + want.Unit * 0.18).Unit
							end
						end
						pos += dir * (p.Speed or 100) * dt
						travelled += (p.Speed or 100) * dt
						local near = modelsNear(model, pos, p.Radius or 2.5)
						if #near > 0 then
							hitAll(state, model, root, { near[1] }, p, move, pos, 1)
							return
						end
						task.wait(dt)
					end
				end)
				if i < (p.Count or 1) then
					task.wait(0.12)
				end
			end
		end)
	elseif p.Id == "Embestida" then
		local targets = modelsInLine(model, root.Position, Vector3.new(aim.X, 0, aim.Z).Unit, p.Range, p.Width or 3.5)
		local first = targets[1]
		local _, fr = parts(first)
		local distance = if fr then (fr.Position - root.Position).Magnitude else p.Range
		if state.Npc then
			local hooks = CombatService.npcHooks
			local flat = Vector3.new(aim.X, 0, aim.Z).Unit
			local stop = root.Position + flat * math.max(0, distance - 3)
			if hooks.vanish then
				pcall(hooks.vanish, model, stop, stop + flat)
			end
		end
		if first then
			task.delay(math.min(0.35, distance / (p.Speed or 90)), function()
				hitAll(state, model, root, { first }, p, move, nil, 1)
			end)
		end
	elseif p.Id == "Onda" then
		task.delay(0.15, function()
			if model.Parent then
				hitAll(state, model, root, modelsInLine(model, origin, aim, p.Range, p.Width or 4), p, move)
			end
		end)
	elseif p.Id == "Explosivo" then
		task.delay(0.18, function()
			if model.Parent then
				local center = root.Position + Vector3.new(aim.X, 0, aim.Z).Unit * 4
				hitAll(state, model, root, modelsNear(model, center, p.Radius or 8), p, move, center)
			end
		end)
	end
	return true
end

-- La definitiva: mini-cinemática (los clientes mueven la cámara) y un estallido enorme
local function useUltimate(state: State, wish: any): boolean
	local now = os.clock()
	local p = Powers.Ultimate
	if not canAct(state, now) then
		return false
	end
	if not Powers.canUse(p, state.Powers, state.Energy, state.Cooldowns[p.Id], now) then
		return false
	end
	local model = modelOf(state) :: Model
	local _, root = parts(model)
	if not root then
		return false
	end
	local windUp = p.WindUp or 1.2
	state.Energy = 0
	state.Cooldowns[p.Id] = now + p.Cooldown
	state.InvulnUntil = now + windUp + 0.3
	state.BusyUntil = now + windUp + 0.6
	setBlocking(state, false)
	setCharging(state, false)
	publishBars(state)
	Remote:FireAllClients("Ultimate", refOf(state), "Start", { WindUp = windUp, Target = state.Lock })
	task.delay(windUp, function()
		local humanoid = parts(model)
		if not model.Parent or not humanoid or humanoid.Health <= 0 or os.clock() < state.KOUntil or state.Defeated then
			Remote:FireAllClients("Ultimate", refOf(state), "Cancel", {})
			return
		end
		local aim = aimOf(state, root, wish, p.Range)
		local origin = root.Position + Vector3.new(0, 0.8, 0)
		Remote:FireAllClients("Ultimate", refOf(state), "Fire", { Origin = origin, Dir = aim })
		local move = powerMove(p, nil)
		local targets = modelsInLine(model, origin, aim, p.Range, p.Width or 8)
		local seen = {}
		for _, m in targets do
			seen[m] = true
		end
		for _, m in modelsNear(model, origin + aim * 12, p.Radius or 14) do
			if not seen[m] then
				table.insert(targets, m)
			end
		end
		hitAll(state, model, root, targets, p, move)
	end)
	return true
end

-- Impulso aéreo (salta otra vez en el aire): gasta aguante; el impulso lo da el cliente
local function airDash(state: State): boolean
	local now = os.clock()
	if not state.Powers.AirDash or state.Stamina < Combat.AirDashCost or not canAct(state, now) then
		return false
	end
	state.Stamina -= Combat.AirDashCost
	state.StaminaAt = now
	publishBars(state)
	return true
end

-- Cargar energía (mantener): quieto, sube la barra (Combat.ChargeRate)
local function setChargingFor(state: State, value: boolean)
	if value and (not state.Powers.Energia or not canAct(state, os.clock())) then
		value = false
	end
	if value then
		setBlocking(state, false)
	end
	setCharging(state, value)
end

---------------------------------------------------------------------
-- Poderes despiertos (la historia o el Modo pruebas)
---------------------------------------------------------------------
local function refreshPowers(player: Player)
	local state = stateOf(player)
	local data = DataService.get(player)
	if not data then
		return
	end
	local okTester, tester = pcall(TesterService.bypass, player)
	local set = Powers.unlocked(data, okTester and tester == true)
	local text = Powers.encode(set)
	if text == state.PowersText then
		return
	end
	local before = state.Powers
	local first = state.PowersText == nil
	state.Powers = set
	state.PowersText = text
	player:SetAttribute("Powers", if text ~= "" then text else nil)
	if not set.Energia then
		state.Energy = 0
		setCharging(state, false)
	end
	publishBars(state)
	-- Recién despertado (no al entrar en la partida): aviso
	if not first and Notify then
		for _, id in Powers.newOnes(before, set) do
			Notify:FireClient(player, "Success", "✨ La Grieta ha despertado algo en ti: " .. Powers.label(id))
		end
	end
end

-- Barras (aguante, guardia y energía): se recuperan solas; cargar sube la energía
local function tick(dt: number)
	local now = os.clock()
	local function step(state: State)
		state.Stamina = Combat.regen(state.Stamina, Combat.StaminaMax, Combat.StaminaRegen, now - state.StaminaAt, Combat.StaminaRegenDelay, dt)
		state.Guard = Combat.regen(state.Guard, Combat.GuardMax, Combat.GuardRegen, now - state.GuardAt, Combat.GuardRegenDelay, dt)
		if state.Charging then
			if not canAct(state, now) then
				setCharging(state, false)
			else
				state.Energy = math.min(Combat.EnergyMax, state.Energy + Combat.ChargeRate * dt)
			end
		end
		if state.Blocking and not canAct(state, now) then
			setBlocking(state, false)
		end
		publishBars(state)
	end
	for _, state in states do
		step(state)
	end
	for model, state in npcStates do
		if model.Parent then
			step(state)
		else
			npcStates[model] = nil
		end
	end
end

---------------------------------------------------------------------
-- API
---------------------------------------------------------------------
export type HitInfo = {
	Amount: number,
	Direction: Vector3,
	Weapon: string?,
	Heavy: boolean?,
	Stun: number?, -- táser: segundos en el suelo sin quitar vida
	Toy: boolean?, -- de juguete: solo reacciona
	At: Vector3?, -- dónde ha dado (para el número de daño)
	Zone: string?,
	Vehicle: boolean?, -- atropello (KnockService): el delito lo decide KnockService (culpa + policía delante)
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
	if model:GetAttribute("MissionEnemy") ~= nil then
		-- Un enemigo de misión (las cucarachas, Petra…): cada bala le quita su daño (cabeza, miembros y
		-- distancia ya van en info.Amount); las de juguete, solo a los enemigos «de juguete»
		local kind = if info.Toy then "Toy" else "Bullet"
		local counted, result = missionTarget(attacker, model, kind, info.Amount, { Zone = info.Zone, At = info.At, Weapon = info.Weapon, Direction = info.Direction })
		if counted and result then
			return { Hit = true, Amount = result.Amount or 0, KO = result.Down == true, Killed = false, Player = nil }
		end
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
			StoryEvents.emit(attacker, "HitSomeone", { Target = victim.UserId, Model = model, KO = true, Killed = true, Weapon = info.Weapon, Vehicle = info.Vehicle })
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
		StoryEvents.emit(attacker, "HitSomeone", { Target = victim.UserId, Model = model, KO = ko, Weapon = info.Weapon, Vehicle = info.Vehicle })
		StoryEvents.emit(victim, "GotHit", { By = attacker.UserId })
		if ko then
			-- (un atropello te tumba, pero te levantas: el hospital es para las peleas)
			knockOut(victim, targetHumanoid, if stunned then info.Stun else nil, info.Vehicle == true)
		end
		return { Hit = true, Amount = amount, KO = ko, Killed = false, Player = victim }
	elseif npcStates[model] and npcBelongsTo(model, attacker) then
		-- Rival de entrenamiento (FighterService): las armas también le quitan vida
		local vs = npcStates[model]
		if vs.Defeated or info.Toy then
			show(0, false)
			return { Hit = true, Amount = 0, KO = false, Killed = false, Player = nil }
		end
		local amount = math.max(0, math.floor(info.Amount + 0.5))
		local hp = targetHumanoid.Health - amount
		local ko = hp <= 0 or (info.Stun or 0) > 0
		targetHumanoid.Health = math.max(1, hp)
		show(amount, ko)
		StoryEvents.emit(attacker, "HitSomeone", { Npc = model:GetAttribute("NpcId") or model.Name, Model = model, KO = ko, Rival = true, Weapon = info.Weapon })
		if ko then
			vs.Defeated = true
			local hooks = CombatService.npcHooks
			if hooks.defeat then
				pcall(hooks.defeat, model, attacker)
			end
		end
		return { Hit = true, Amount = amount, KO = ko, Killed = false, Player = nil }
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
		StoryEvents.emit(attacker, "HitSomeone", { Model = model, KO = hp <= 0, Weapon = info.Weapon, Vehicle = info.Vehicle })
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

-- Estado de pelea de un jugador o de un rival (para FighterService y las pruebas). No cambiarlo desde fuera.
function CombatService.state(who: Player | Model): State?
	if typeof(who) == "Instance" and (who :: any):IsA("Player") then
		return stateOf(who :: Player)
	end
	if type(who) == "table" and rawget(who :: any, "IsPlayer") then
		return stateOf(who :: any)
	end
	return npcStates[who :: Model]
end

-- Poderes del jugador (se vuelven a mirar ahora: la historia o el Modo pruebas pueden haber cambiado)
function CombatService.powers(player: Player): { [string]: boolean }
	refreshPowers(player)
	return stateOf(player).Powers
end

-- Energía llena (Modo pruebas)
function CombatService.fillEnergy(player: Player)
	local state = stateOf(player)
	refreshPowers(player)
	if state.Powers.Energia then
		state.Energy = Combat.EnergyMax
	end
	state.Stamina = Combat.StaminaMax
	state.Guard = Combat.GuardMax
	publishBars(state)
end

-- Rivales (FighterService): se apuntan aquí para pelear con las mismas reglas
function CombatService.registerFighter(model: Model, opts: { DamageMul: number?, Owner: Player? }?): State
	local state = newState(nil, model)
	state.Npc = true
	state.OwnerId = if opts and opts.Owner then opts.Owner.UserId else nil
	state.SpawnedAt = os.clock()
	state.DamageMul = (opts and opts.DamageMul) or 1
	npcStates[model] = state
	publishBars(state)
	-- Su barra de vida (Controllers/HealthBars) la ve solo quien pelea con él
	pcall(function()
		model:SetAttribute("CombatOwner", state.OwnerId)
		model:AddTag("HostileNpc")
	end)
	return state
end

function CombatService.unregisterFighter(model: Model)
	npcStates[model] = nil
end

-- Lo que decide la IA de un rival (FighterService): "Light", "Heavy", "Charged", "Block", "Unblock",
-- "Roll", "Vanish", "Lock". Devuelve si lo ha hecho.
function CombatService.fighterAction(model: Model, action: string, arg: any): boolean
	local state = npcStates[model]
	if not state then
		return false
	end
	if action == "Light" then
		return strike(state, "Light", false) ~= nil
	elseif action == "Heavy" then
		return strike(state, "Heavy", false) ~= nil
	elseif action == "Charged" then
		return strike(state, "Heavy", true) ~= nil
	elseif action == "Block" then
		setBlockingFor(state, true)
		return state.Blocking
	elseif action == "Unblock" then
		setBlockingFor(state, false)
		return true
	elseif action == "Roll" then
		return roll(state, arg)
	elseif action == "Vanish" then
		return vanish(state, arg)
	elseif action == "Lock" then
		state.Lock = if typeof(arg) == "Instance" then arg else nil
		return true
	end
	return false
end

-- Un jugador hace algo (lo mismo que el remoto; para las pruebas y los comandos)
function CombatService.handle(player: Player, kind: any, value: any, extra: any): any
	local state = stateOf(player)
	if kind == "Attack" or kind == "Light" then
		return strike(state, "Light", false)
	elseif kind == "HeavyHold" then
		state.HeavyHoldAt = os.clock()
	elseif kind == "Heavy" then
		-- Cargado solo si de verdad lo ha mantenido (el servidor apuntó cuándo empezó)
		local held = state.HeavyHoldAt and os.clock() - state.HeavyHoldAt or 0
		state.HeavyHoldAt = nil
		local charged = value == true and held >= Combat.ChargeTime * 0.8
		return strike(state, "Heavy", charged)
	elseif kind == "Block" then
		setBlockingFor(state, value == true)
	elseif kind == "Dodge" then
		if value == "Vanish" then
			if vanish(state, extra) then
				return "Vanish"
			end
			return nil
		end
		-- Esquivar (con su pausa: no se puede estar esquivando siempre)
		if roll(state, extra) then
			return "Roll"
		end
	elseif kind == "Charge" then
		setChargingFor(state, value == true)
	elseif kind == "PowerHold" then
		local p = Powers.get(value)
		if p and p.MaxCharge and state.Powers[p.Id] then
			state.PowerHoldId, state.PowerHoldAt = p.Id, os.clock()
		end
	elseif kind == "Power" then
		return usePower(state, value, extra)
	elseif kind == "Ultimate" then
		return useUltimate(state, value)
	elseif kind == "AirDash" then
		return airDash(state)
	elseif kind == "Lock" then
		local target = if typeof(value) == "Instance" and value:IsA("Model") and value:FindFirstChildOfClass("Humanoid") then value else nil
		local _, root = parts(player.Character)
		local _, tr = parts(target)
		if target and root and tr and (tr.Position - root.Position).Magnitude > 80 then
			target = nil
		end
		state.Lock = target
	elseif kind == "Wall" then
		-- Tu personaje se ha estampado contra una pared (lo mueve tu dispositivo): los demás lo ven
		local now = os.clock()
		if typeof(value) == "Vector3" and now - state.LastHitAt < 2 and now - (state.WallAt or -math.huge) > 0.5 then
			state.WallAt = now
			Remote:FireAllClients("Wall", player.Character, value)
		end
	end
	return nil
end

function CombatService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:FindFirstChild("Combat") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "Combat"
		Remote.Parent = remotes
	end
	Notify = remotes:FindFirstChild("Notify") :: RemoteEvent?
	-- Detenido estando K.O.: a comisaría, no al hospital
	StoryEvents.connect(function(player: Player, name: string)
		if name == "Arrested" and states[player] and os.clock() < states[player].KOUntil then
			states[player].ArrestedInKO = true
			player:SetAttribute("ArrestedInKO", true) -- (DeathUI: ya no dice «Despertarás en el hospital»)
		end
	end)
	Remote.OnServerEvent:Connect(function(player: Player, kind: any, value: any, extra: any)
		local ok, err = pcall(CombatService.handle, player, kind, value, extra)
		if not ok then
			warn("[Combate] " .. tostring(err))
		end
	end)

	local function watch(player: Player)
		player.CharacterAdded:Connect(function()
			local state = stateOf(player)
			state.SpawnedAt = os.clock()
			state.KOUntil = 0
			state.Stunned = nil
			state.Combo = 0
			state.Chain = Combat.newChain()
			state.StunUntil, state.DownUntil, state.AirUntil, state.InvulnUntil, state.BusyUntil = 0, 0, 0, 0, 0
			state.Guard, state.Stamina = Combat.GuardMax, Combat.StaminaMax
			state.Lock = nil
			setBlocking(state, false)
			setCharging(state, false)
			player:SetAttribute("KO", nil)
			player:SetAttribute("Fallen", nil)
			player:SetAttribute("ArrestedInKO", nil)
			player:SetAttribute("Blocking", nil)
			publishBars(state)
		end)
		task.defer(refreshPowers, player)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
	-- Las barras se recuperan (y la energía sube cargando); los poderes se vuelven a mirar de vez en
	-- cuando (la historia avanza y el Modo pruebas se enciende y se apaga)
	task.spawn(function()
		local last = os.clock()
		local sincePowers = 0
		while true do
			task.wait(0.2)
			local now = os.clock()
			local dt = math.min(now - last, 1)
			last = now
			local ok, err = pcall(tick, dt)
			if not ok then
				warn("[Combate] " .. tostring(err))
			end
			sincePowers += dt
			if sincePowers >= 2 then
				sincePowers = 0
				for _, player in Players:GetPlayers() do
					pcall(refreshPowers, player)
				end
			end
		end
	end)
end

return CombatService
