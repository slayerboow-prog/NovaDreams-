-- FighterService: rivales de entrenamiento que pelean con las mismas reglas que un jugador
-- (CombatService + shared/Combat) y piensan con shared/CombatAI: se acercan, encadenan combos con su
-- final, se cubren, ruedan, se desvanecen detrás de ti, contraatacan después de cubrirse y cargan el
-- golpe si te cubres mucho. Tres niveles: Facil, Normal y Dificil.
--
-- Cada rival es de un jugador (carpeta con Owner = su UserId): solo pelea con él y solo él le puede
-- pegar. Pegarle no es delito (es un entrenamiento). Se saca desde el Modo pruebas (TesterService
-- "Rival") y lo puede usar la historia: FighterService.spawn(jugador, posición?, nivel?, opciones?).
--
-- Se mueven en el servidor (anclados, por CFrame, como el resto de personajes): andar, el empujón
-- de los golpes (vuela, flota en el aire tras un lanzador, se estampa contra las paredes, cae
-- derribado y se levanta), la voltereta y desvanecerse. Al quedarse sin vida se rinde y se va.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Combat = require(ReplicatedStorage.Shared.Combat)
local CombatAI = require(ReplicatedStorage.Shared.CombatAI)
local CombatService = require(script.Parent.CombatService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local Npc = require(script.Parent.Parent.World.Npc)

local FighterService = {}

FighterService.Gravity = 196.2
FighterService.AirGravity = 0.22 -- en el aire tras un lanzador cae así de despacio (se puede seguir el combo)
FighterService.ThinkEvery = 0.12
FighterService.LeashDistance = 90 -- más lejos de su jugador y se va
FighterService.IdleSeconds = 45 -- sin pelear este tiempo, se va

type Fighter = {
	Model: Model,
	Root: BasePart,
	Humanoid: Humanoid,
	Owner: Player,
	Level: CombatAI.Level,
	LevelId: string,
	Folder: Instance,
	Height: number,
	GroundY: number,
	Vel: Vector3, -- velocidad del empujón
	Flying: boolean,
	Wall: boolean,
	Move: Vector3, -- hacia dónde anda (unidad * velocidad)
	MoveUntil: number,
	ComboWant: number,
	NextThink: number,
	Pending: { Action: string, At: number }?,
	LastFight: number,
	Gone: boolean,
	Leaving: boolean?,
}

local fighters: { [Model]: Fighter } = {}
local byOwner: { [Player]: Fighter } = {}
local Remote: RemoteEvent? = nil
local started = false

local function rootOf(model: Model?): BasePart?
	return model and model:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function flat(v: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	return if f.Magnitude > 1e-3 then f.Unit else Vector3.new(0, 0, -1)
end

-- El suelo bajo un punto (o la altura de donde apareció si no hay nada)
local function groundAt(f: Fighter, at: Vector3): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { f.Folder }
	local ok, hit = pcall(function()
		return workspace:Raycast(at + Vector3.new(0, 4, 0), Vector3.new(0, -40, 0), params)
	end)
	if ok and hit and hit.Instance and not hit.Instance:IsDescendantOf(f.Owner.Character or f.Folder) then
		return hit.Position.Y
	end
	return f.GroundY
end

-- Coloca el rival: de pie (mirando a `face`) o tumbado (derribado)
local function place(f: Fighter, pos: Vector3, face: Vector3?, lying: boolean?)
	local look = if face then flat(face - pos) else flat(f.Root.CFrame.LookVector)
	local cf = CFrame.lookAt(pos, pos + look)
	if lying then
		cf = cf * CFrame.new(0, -f.Height + 0.6, 0) * CFrame.Angles(math.pi / 2, 0, 0)
	end
	f.Root.CFrame = cf
end

local function ownerRoot(f: Fighter): BasePart?
	return rootOf(f.Owner.Character)
end

local function stateOf(f: Fighter): any
	return CombatService.state(f.Model)
end

---------------------------------------------------------------------
-- Lo que hace CombatService con el rival (hooks)
---------------------------------------------------------------------
local function knock(model: Model, horizontal: Vector3, lift: number, info: { [string]: any })
	local f = fighters[model]
	if not f then
		return
	end
	f.Vel = Vector3.new(horizontal.X, lift, horizontal.Z)
	f.Flying = f.Vel.Magnitude > 2 or (info.Air ~= nil)
	f.Wall = info.Wall == true
	f.LastFight = os.clock()
	f.Pending = nil
	-- (el congelado del impacto: no sale volando hasta que acaba)
	if info.Hitstop and info.Hitstop > 0 then
		local vel = f.Vel
		f.Vel = Vector3.zero
		task.delay(info.Hitstop, function()
			if fighters[model] == f then
				f.Vel = vel
			end
		end)
	end
end

local function dismiss(f: Fighter)
	if f.Gone then
		return
	end
	f.Gone = true
	fighters[f.Model] = nil
	if byOwner[f.Owner] == f then
		byOwner[f.Owner] = nil
	end
	CombatService.unregisterFighter(f.Model)
	pcall(function()
		f.Folder:Destroy()
	end)
end

local function defeat(model: Model, by: Player?)
	local f = fighters[model]
	if not f then
		return
	end
	local state = stateOf(f)
	if state then
		state.DownUntil = os.clock() + 999
	end
	Npc.say(model, "¡Vale, vale! Me rindo… ¡Buen combate!", 3)
	if by then
		StoryEvents.emit(by, "BeatRival", { Level = f.LevelId, Model = model })
	end
	task.delay(4, function()
		dismiss(f)
	end)
end

local function vanishTo(model: Model, dest: Vector3, face: Vector3)
	local f = fighters[model]
	if not f then
		return
	end
	f.Flying = false
	f.Vel = Vector3.zero
	local y = groundAt(f, dest) + f.Height
	place(f, Vector3.new(dest.X, y, dest.Z), face)
end

local function rollAway(model: Model, wish: Vector3)
	local f = fighters[model]
	if not f then
		return
	end
	local target = ownerRoot(f)
	local away = if wish.Magnitude > 0.1 then flat(wish) elseif target then flat(f.Root.Position - target.Position) else -flat(f.Root.CFrame.LookVector)
	f.Move = away * Combat.RollSpeed
	f.MoveUntil = os.clock() + Combat.RollTime * 0.8
end

---------------------------------------------------------------------
-- Moverse (cada fotograma)
---------------------------------------------------------------------
local function physics(f: Fighter, dt: number, now: number)
	local state = stateOf(f)
	if not state then
		return
	end
	local pos = f.Root.Position
	local target = ownerRoot(f)
	local down = now < state.DownUntil
	if f.Flying then
		local inAir = now < state.AirUntil
		local g = FighterService.Gravity * (if inAir and f.Vel.Y < 8 then FighterService.AirGravity else 1)
		local vel = f.Vel - Vector3.new(0, g * dt, 0)
		if inAir then
			-- (en el aire tras el lanzador: frena para quedarse a tiro)
			vel = Vector3.new(vel.X * (1 - math.min(1, 4 * dt)), vel.Y, vel.Z * (1 - math.min(1, 4 * dt)))
		end
		local nextPos = pos + vel * dt
		-- ¿Pared?
		local horizontal = Vector3.new(vel.X, 0, vel.Z)
		if f.Wall and horizontal.Magnitude > 20 then
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { f.Folder, f.Owner.Character :: any }
			local ok, hit = pcall(function()
				return workspace:Raycast(pos, horizontal.Unit * (horizontal.Magnitude * dt + 1.5), params)
			end)
			if ok and hit and math.abs(hit.Normal.Y) < 0.5 then
				-- Se estampa: rebota un poco y cae
				nextPos = hit.Position + hit.Normal * 1.6
				vel = hit.Normal * 8 + Vector3.new(0, 4, 0)
				f.Wall = false
				if Remote then
					Remote:FireAllClients("Wall", f.Model, hit.Position)
				end
			end
		end
		local ground = groundAt(f, nextPos) + f.Height
		if nextPos.Y <= ground and vel.Y <= 0 then
			nextPos = Vector3.new(nextPos.X, ground, nextPos.Z)
			f.Flying = false
			vel = Vector3.zero
		end
		f.Vel = vel
		place(f, nextPos, if target then target.Position else nil, down and not f.Flying)
		return
	end
	if down then
		place(f, Vector3.new(pos.X, groundAt(f, pos) + f.Height, pos.Z), if target then target.Position else nil, true)
		return
	end
	-- Andar (o la voltereta)
	local step = Vector3.zero
	if now < f.MoveUntil then
		step = f.Move * dt
	end
	local nextPos = pos + step
	nextPos = Vector3.new(nextPos.X, groundAt(f, nextPos) + f.Height, nextPos.Z)
	place(f, nextPos, if target then target.Position else nil, false)
end

---------------------------------------------------------------------
-- Pensar (CombatAI)
---------------------------------------------------------------------
local function walk(f: Fighter, dir: Vector3, speed: number, seconds: number)
	f.Move = flat(dir) * speed
	f.MoveUntil = os.clock() + seconds
end

-- Lo que ve el rival (para CombatAI.decide)
function FighterService.view(f: Fighter, now: number): CombatAI.View?
	local state = stateOf(f)
	local target = ownerRoot(f)
	local enemy = CombatService.state(f.Owner)
	if not state or not target or not enemy then
		return nil
	end
	local fresh = now - state.Chain.At <= Combat.ChainWindow
	local swingAge = now - (enemy.SwingAt or -math.huge)
	return {
		Distance = (Vector3.new(target.Position.X, 0, target.Position.Z) - Vector3.new(f.Root.Position.X, 0, f.Root.Position.Z)).Magnitude,
		CanAct = not f.Flying and Combat.canAct(now, state.StunUntil, state.DownUntil) and now >= state.BusyUntil and not state.Defeated,
		Ready = Combat.readyMove(state.LastMove, state.LastAt, now),
		TargetAttacking = swingAge < 0.4,
		TargetAttackAge = swingAge,
		TargetBlocking = enemy.Blocking == true,
		TargetBlockingFor = if enemy.Blocking then now - (enemy.BlockSince or now) else 0,
		TargetDown = now < (enemy.DownUntil or 0) or now < (enemy.KOUntil or 0),
		TargetAir = now < (enemy.AirUntil or 0) and now < state.AirUntil,
		Blocking = state.Blocking == true,
		JustBlocked = state.Blocking == true and now - state.GuardAt < 0.4,
		Stamina = state.Stamina,
		ComboStep = if fresh then state.Chain.Lights else 0,
		ComboWant = f.ComboWant,
		Health = f.Humanoid.Health / math.max(1, f.Humanoid.MaxHealth),
	}
end

local function think(f: Fighter, now: number)
	local target = ownerRoot(f)
	local state = stateOf(f)
	if not target or not state or state.Defeated or f.Leaving then
		return
	end
	local owner = f.Owner
	local ownerHumanoid = owner.Character and owner.Character:FindFirstChildOfClass("Humanoid")
	if not ownerHumanoid or ownerHumanoid.Health <= 0 then
		return
	end
	if (target.Position - f.Root.Position).Magnitude > FighterService.LeashDistance or now - f.LastFight > FighterService.IdleSeconds then
		Npc.say(f.Model, "Bueno, otro día seguimos.", 2)
		f.Leaving = true
		task.delay(1, function()
			dismiss(f)
		end)
		return
	end
	-- Golpe cargado: avisa (se le ve cargar) y lo suelta un poco después
	if f.Pending then
		if now >= f.Pending.At then
			local action = f.Pending.Action
			f.Pending = nil
			CombatService.fighterAction(f.Model, action)
		end
		return
	end
	local view = FighterService.view(f, now)
	if not view then
		return
	end
	local action = CombatAI.decide(view, f.Level, math.random)
	local toTarget = target.Position - f.Root.Position
	if action == "Approach" then
		walk(f, toTarget, f.Level.Speed, 0.3)
	elseif action == "Retreat" then
		walk(f, -toTarget, f.Level.Speed * 0.8, 0.5)
	elseif action == "Strafe" then
		local side = Vector3.new(-toTarget.Z, 0, toTarget.X) * (if math.random() < 0.5 then 1 else -1)
		walk(f, side, f.Level.Speed * 0.7, 0.45)
	elseif action == "Light" then
		f.MoveUntil = 0
		if CombatService.fighterAction(f.Model, "Light") then
			f.LastFight = now
		end
	elseif action == "Heavy" then
		f.MoveUntil = 0
		if CombatService.fighterAction(f.Model, "Heavy") then
			f.LastFight = now
			f.ComboWant = CombatAI.comboLength(f.Level, math.random)
		end
	elseif action == "Charged" then
		f.MoveUntil = 0
		f.Pending = { Action = "Charged", At = now + Combat.ChargeTime }
		if Remote then
			Remote:FireAllClients("Windup", f.Model, Combat.ChargeTime)
		end
	elseif action == "Block" or action == "Unblock" or action == "Roll" or action == "Vanish" then
		CombatService.fighterAction(f.Model, action, -toTarget)
		f.LastFight = now
	end
end

---------------------------------------------------------------------
-- API
---------------------------------------------------------------------

-- Saca un rival para `owner` (quita el que tuviera). at: dónde (si no, delante de él). level: Facil,
-- Normal o Dificil. opts: Name, NpcId, Look (ropa: Npc.create).
function FighterService.spawn(owner: Player, at: Vector3?, levelId: string?, opts: { [string]: any }?): Model?
	local character = owner.Character
	local ownerRoot_ = rootOf(character)
	if not ownerRoot_ then
		return nil
	end
	local old = byOwner[owner]
	if old then
		dismiss(old)
	end
	local level = CombatAI.level(levelId)
	local id = if CombatAI.Levels[levelId :: any] then levelId :: string else "Normal"
	local o = opts or {}
	local look = flat(ownerRoot_.CFrame.LookVector)
	local where = at or (ownerRoot_.Position + look * 10)
	local folder = Instance.new("Folder")
	folder.Name = "Rival_" .. tostring(owner.UserId)
	folder:SetAttribute("Owner", owner.UserId)
	folder.Parent = workspace
	local model = Npc.create(o.Name or ("Rival (" .. level.Name .. ")"), folder, CFrame.lookAt(where, ownerRoot_.Position), o.Look)
	model:SetAttribute("Fighter", id)
	model:SetAttribute("NpcId", o.NpcId or "Rival")
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = rootOf(model) :: BasePart
	humanoid.MaxHealth = level.Health
	humanoid.Health = level.Health
	local height = humanoid.HipHeight + root.Size.Y / 2
	local f: Fighter = {
		Model = model,
		Root = root,
		Humanoid = humanoid,
		Owner = owner,
		Level = level,
		LevelId = id,
		Folder = folder,
		Height = height,
		GroundY = root.Position.Y - height,
		Vel = Vector3.zero,
		Flying = false,
		Wall = false,
		Move = Vector3.zero,
		MoveUntil = 0,
		ComboWant = CombatAI.comboLength(level, math.random),
		NextThink = os.clock() + 1.2, -- (un momento para ponerse en guardia)
		LastFight = os.clock(),
		Gone = false,
	}
	fighters[model] = f
	byOwner[owner] = f
	CombatService.registerFighter(model, { DamageMul = level.DamageMul, Owner = owner })
	CombatService.fighterAction(model, "Lock", character)
	Npc.say(model, "¿Entrenamos? ¡En guardia!", 2.5)
	FighterService.start()
	return model
end

-- Quita el rival de un jugador
function FighterService.dismiss(owner: Player)
	local f = byOwner[owner]
	if f then
		dismiss(f)
	end
end

function FighterService.rivalOf(owner: Player): Model?
	local f = byOwner[owner]
	return f and f.Model
end

-- (pruebas) un paso de la IA y del movimiento
function FighterService._think(model: Model, now: number?)
	local f = fighters[model]
	if f then
		think(f, now or os.clock())
	end
end
function FighterService._step(dt: number, now: number?)
	for _, f in fighters do
		physics(f, dt, now or os.clock())
	end
end
function FighterService._fighter(model: Model): any
	return fighters[model]
end

function FighterService.start()
	if started then
		return
	end
	started = true
	RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		for model, f in fighters do
			if not model.Parent or not f.Owner.Parent then
				dismiss(f)
				continue
			end
			local ok, err = pcall(physics, f, math.min(dt, 0.1), now)
			if not ok then
				warn("[Rivales] " .. tostring(err))
			end
			if now >= f.NextThink and not f.Gone then
				f.NextThink = now + FighterService.ThinkEvery
				local okThink, errThink = pcall(think, f, now)
				if not okThink then
					warn("[Rivales] " .. tostring(errThink))
				end
			end
		end
	end)
end

function FighterService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:FindFirstChild("Combat") :: RemoteEvent?
	CombatService.npcHooks.knock = knock
	CombatService.npcHooks.defeat = defeat
	CombatService.npcHooks.vanish = vanishTo
	CombatService.npcHooks.roll = rollAway
	Players.PlayerRemoving:Connect(function(player)
		FighterService.dismiss(player)
	end)
end

return FighterService
