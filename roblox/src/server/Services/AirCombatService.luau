-- AirCombatService: combate aéreo y espacial (núcleo de la Saga 2; ahora se prueba en la arena del
-- Modo pruebas: TesterService "AirArena"). Ver docs/combate-aereo.md.
--
-- Quién manda en qué (para que no se pueda hacer trampa, pero que vuele suave):
--   * La NAVE la mueve el ordenador del piloto (es dueño de sus piezas, SetNetworkOwner) con
--     shared/AirCombat/ShipFlight, como los aviones del aeroclub. Aquí se comprueba cada vuelta que
--     el salto sea posible (ShipFlight.plausible), que siga dentro de la arena y que no esté dentro de
--     una roca o un asteroide (shared/AirCombat/Arena: las mismas formas que usa el cliente). Si no,
--     vuelve al último sitio bueno ("Reset") o se estrella.
--   * Los DISPAROS, los MISILES, el DAÑO, los ESCUDOS, la MUNICIÓN, los ENEMIGOS y las OLEADAS son del
--     servidor: el cliente solo pide «disparo hacia aquí» (con cadencia, calor y un cono máximo
--     respecto al morro) y «misil a este blanco» (tiene que estar dentro del cono de fijación).
--   * Derribos de verdad: los drones, cazas y torretas enemigos estallan (explosión, trozos, humo y restos
--     en llamas que caen; nada de sangre). Casco a 0 o chocar = tu nave estalla y, a los pocos segundos,
--     vuelves al punto de control con una nave nueva (es un juego: no se pierde nada).
--
-- API (para la Saga 2):
--   AirCombatService.enter(player, { Section = "Atmos"|"Space", Difficulty = "Facil"|"Normal"|"Dificil",
--       MaxWaves = n?, Trusted = true? })   -> bool   (sin Trusted, solo testers: TesterService.isTester)
--   AirCombatService.exit(player, motivo?)
--   AirCombatService.inArena(player) -> bool
--   AirCombatService.onEvent(fn(player, nombre, datos))  "Kill", "WaveCleared", "Done", "Down", "Exit"
-- Remoto "AirCombat" (cliente → servidor): "Fire" (dir), "Missile" (id), "Crash" (motivo), "Exit".
-- (servidor → cliente): "Start", "End", "State", "Bolt", "Missile", "Boom", "Burst", "Hit", "HitMark",
--   "Down", "Respawn", "Reset", "Wave".
-- Mientras nadie está en la arena, este servicio no hace NADA (ni bucle ni piezas).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AC = ReplicatedStorage.Shared.AirCombat
local ShipFlight = require(AC.ShipFlight)
local Shields = require(AC.Shields)
local ShipWeapons = require(AC.ShipWeapons)
local Lock = require(AC.Lock)
local EnemyAI = require(AC.EnemyAI)
local Waves = require(AC.Waves)
local Arena = require(AC.Arena)

local AirCombatService = {}

AirCombatService.Tick = 1 / 30 -- vueltas por segundo del combate
AirCombatService.DownSeconds = 3 -- derribado: segundos antes de reaparecer
AirCombatService.StateEvery = 0.1
AirCombatService.ShipKind = "Caza"

type EnemyRec = { AI: EnemyAI.Enemy, Hp: Shields.State, Model: Model, Root: BasePart }
type Bolt = { Pos: Vector3, Dir: Vector3, Speed: number, Life: number, Damage: number, Enemy: boolean, Radius: number }
type MissileRec = { Id: string, Pos: Vector3, Dir: Vector3, Speed: number, Life: number, Target: string }
type Session = {
	Player: Player,
	Ship: Model,
	Root: BasePart,
	Seat: Seat,
	Humanoid: Humanoid,
	Section: string,
	Difficulty: string,
	Hull: Shields.State,
	Gun: ShipWeapons.Gun,
	Spawner: Waves.Spawner,
	Enemies: { [string]: EnemyRec },
	Folder: Model,
	Bolts: { Bolt },
	Missiles: { MissileRec },
	Return: CFrame?,
	LastPos: Vector3,
	LastGood: CFrame,
	LastAt: number,
	Down: boolean,
	DownUntil: number,
	DownAt: Vector3?,
	Score: number,
	Kills: number,
	NextId: number,
	StateAt: number,
	Exiting: boolean,
	Conns: { RBXScriptConnection },
	Hidden: { [Instance]: number }?,
}

local sessions: { [Player]: Session } = {}
local listeners: { (Player, string, any) -> () } = {}
local remote: RemoteEvent? = nil
local notify: RemoteEvent? = nil
local loop: RBXScriptConnection? = nil
local clock = 0

local function service(name: string): any
	return require(script.Parent[name])
end

local function emit(player: Player, name: string, data: any?)
	for _, fn in listeners do
		task.spawn(fn, player, name, data)
	end
end

function AirCombatService.onEvent(fn: (Player, string, any) -> ())
	table.insert(listeners, fn)
end

function AirCombatService.inArena(player: Player): boolean
	return sessions[player] ~= nil
end

local function send(player: Player, kind: string, payload: any?)
	if remote and player.Parent then
		remote:FireClient(player, kind, payload)
	end
end

-- A todos los que están en la arena (los disparos y estallidos se ven entre pilotos)
local function broadcast(kind: string, payload: any?, except: Player?)
	for p in sessions do
		if p ~= except then
			send(p, kind, payload)
		end
	end
end

local function toast(player: Player, kind: string, text: string)
	if notify then
		notify:FireClient(player, kind, text)
	end
end

local function humanoidOf(player: Player): (Humanoid?, BasePart?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return humanoid, root
end

local function now(): number
	return os.clock()
end

---------------------------------------------------------------------
-- Enemigos
---------------------------------------------------------------------
local function enemyCFrame(e: EnemyAI.Enemy): CFrame
	return CFrame.new(e.Pos) * ShipFlight.facing(e.Look)
end

local function spawnEnemy(s: Session, kind: string, pos: Vector3, scale: Waves.Scale)
	s.NextId += 1
	local id = ("%d_%d"):format(s.Player.UserId, s.NextId)
	local look = (Arena.center(s.Section) - pos)
	local ai = EnemyAI.new(id, kind, pos, if look.Magnitude > 1 then look.Unit else nil, { Damage = scale.Damage, Fire = scale.Fire, Speed = scale.Speed }, s.NextId * 1.7)
	local hp = Shields.new(EnemyAI.ShieldSpec[kind] or "Dron", scale.Hull)
	local model = require(script.Parent.Parent.World.AirArena).enemy(kind, enemyCFrame(ai))
	model:SetAttribute("AirEnemy", id)
	model:SetAttribute("Owner", s.Player.UserId)
	model:SetAttribute("Kind", kind)
	model.Parent = s.Folder
	s.Enemies[id] = { AI = ai, Hp = hp, Model = model, Root = model.PrimaryPart :: BasePart }
end

local function aliveCount(s: Session): number
	local n = 0
	for _ in s.Enemies do
		n += 1
	end
	return n
end

local function spawnWave(s: Session, ev: Waves.Event)
	local scale = ev.Scale :: Waves.Scale
	local center = Arena.center(s.Section)
	local turretSpots = Arena.turretSpots(s.Section)
	local nextTurret = 1
	local flying = 0
	for _, g in ev.Groups or {} do
		if g.Kind ~= "Torreta" then
			flying += g.Count
		end
	end
	local ring = Waves.ring(flying, center, 650, ev.Wave)
	local k = 0
	for _, g in ev.Groups or {} do
		for _ = 1, g.Count do
			if g.Kind == "Torreta" then
				local spot = turretSpots[nextTurret]
				nextTurret += 1
				if spot then
					spawnEnemy(s, "Torreta", spot, scale)
				end
			else
				k += 1
				spawnEnemy(s, g.Kind, ring[k] or center, scale)
			end
		end
	end
	send(s.Player, "Wave", { Wave = ev.Wave, Count = aliveCount(s), Section = s.Section })
end

local function removeEnemy(s: Session, id: string, destroyed: boolean)
	local rec = s.Enemies[id]
	if not rec then
		return
	end
	s.Enemies[id] = nil
	if destroyed then
		broadcast("Burst", { Pos = rec.AI.Pos, Kind = rec.AI.Kind, Wreck = true, Look = rec.AI.Look, Speed = rec.AI.Speed })
	end
	rec.Model:Destroy()
end

local function damageEnemy(s: Session, id: string, amount: number, kind: string, at: Vector3)
	local rec = s.Enemies[id]
	if not rec then
		return
	end
	local t = now()
	local r = Shields.apply(rec.Hp, amount, t, kind)
	EnemyAI.hit(rec.AI, tostring(s.Player.UserId), t)
	send(s.Player, "HitMark", { Pos = at, Shield = r.Shield > 0 and r.Hull == 0, Kill = r.Destroyed, Kind = kind })
	if r.Destroyed then
		s.Kills += 1
		s.Score += rec.AI.Stats.Score
		removeEnemy(s, id, true)
		emit(s.Player, "Kill", { Kind = rec.AI.Kind, Score = s.Score })
	end
end

---------------------------------------------------------------------
-- La nave del jugador: derribada o estrellada, y reaparecer
---------------------------------------------------------------------
local function setShipHidden(s: Session, hidden: boolean)
	if hidden then
		if s.Hidden then
			return
		end
		local list = {}
		local character = s.Player.Character
		local all = s.Ship:GetDescendants()
		if character then
			for _, d in character:GetDescendants() do
				table.insert(all, d)
			end
		end
		for _, d in all do
			if (d:IsA("BasePart") or d:IsA("Decal")) and (d :: any).Transparency < 1 then
				list[d] = (d :: any).Transparency
				;(d :: any).Transparency = 1
			end
		end
		s.Hidden = list
	elseif s.Hidden then
		for p, t in s.Hidden do
			if p.Parent then
				(p :: any).Transparency = t
			end
		end
		s.Hidden = nil
	end
end

local function goDown(s: Session, reason: string)
	if s.Down then
		return
	end
	s.Down = true
	s.DownUntil = now() + AirCombatService.DownSeconds
	s.DownAt = s.Root.Position
	setShipHidden(s, true)
	send(s.Player, "Down", { Pos = s.Root.Position, Reason = reason })
	broadcast("Burst", { Pos = s.Root.Position, Kind = "Nave", Wreck = true, Look = s.Root.CFrame.LookVector }, s.Player)
	emit(s.Player, "Down", { Reason = reason })
end

local function respawn(s: Session)
	local section = Arena.modeAt(s.DownAt or s.Root.Position)
	local cp = Arena.checkpoint(section)
	s.Down = false
	s.DownAt = nil
	Shields.reset(s.Hull)
	s.Gun = ShipWeapons.newGun()
	setShipHidden(s, false)
	s.Root.CFrame = cp
	s.Root.AssemblyLinearVelocity = Vector3.zero
	s.LastPos, s.LastGood = cp.Position, cp
	-- (los disparos enemigos que iban hacia ti se pierden)
	for i = #s.Bolts, 1, -1 do
		if s.Bolts[i].Enemy then
			table.remove(s.Bolts, i)
		end
	end
	send(s.Player, "Respawn", { CFrame = cp, Section = section })
end

local function damagePlayer(s: Session, amount: number, kind: string, from: Vector3)
	if s.Down then
		return
	end
	local r = Shields.apply(s.Hull, amount, now(), kind)
	send(s.Player, "Hit", { Shield = r.Shield, Hull = r.Hull, Broke = r.Broke, From = from })
	if r.Destroyed then
		goDown(s, "Te han derribado")
	end
end

---------------------------------------------------------------------
-- Una vuelta del combate
---------------------------------------------------------------------
local function pilotsOf(s: Session): { EnemyAI.Pilot }
	local root = s.Root
	return {
		{ Id = tostring(s.Player.UserId), Pos = root.Position, Vel = root.AssemblyLinearVelocity, Look = root.CFrame.LookVector, Alive = not s.Down },
	}
end

local function validateShip(s: Session, dt: number)
	if s.Down then
		return
	end
	local root = s.Root
	local pos = root.Position
	local spec = ShipFlight.Specs[AirCombatService.ShipKind]
	if not ShipFlight.plausible(spec, s.LastPos, pos, dt) or not Arena.contains(pos, 400) then
		-- Salto imposible (o fuera de la arena): al último sitio bueno, y su ordenador también
		root.CFrame = s.LastGood
		send(s.Player, "Reset", { CFrame = s.LastGood })
		s.LastPos = s.LastGood.Position
		return
	end
	local hit = Arena.collide(pos, spec.Radius * 0.7)
	if hit then
		goDown(s, "Te has estrellado contra " .. hit)
		return
	end
	s.LastPos = pos
	s.LastGood = root.CFrame
end

local function stepEnemies(s: Session, dt: number, t: number)
	local pilots = pilotsOf(s)
	local list = {}
	for _, rec in s.Enemies do
		table.insert(list, rec.AI)
	end
	for id, rec in s.Enemies do
		local e = rec.AI
		e.Target = EnemyAI.pickTarget(e, pilots, t)
		local target = nil
		for _, p in pilots do
			if p.Id == e.Target then
				target = p
			end
		end
		local desired, speed, fire = EnemyAI.think(e, target, t, list)
		local back = Arena.bounds(e.Pos)
		if back then
			desired = (desired + back * 2).Unit
		end
		local before = e.Pos
		EnemyAI.steer(e, desired, speed, dt)
		if e.Kind ~= "Torreta" and Arena.collide(e.Pos, e.Stats.Radius) then
			-- (no se meten en las rocas: vuelven atrás y suben)
			e.Pos = before
			e.Look = (e.Look + Vector3.new(0, 1.2, 0)).Unit
		end
		rec.Root.CFrame = enemyCFrame(e)
		if fire and target then
			EnemyAI.fired(e, t)
			local spread = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 0.03
			local dir = (e.Look + spread).Unit
			local origin = e.Pos + dir * (e.Stats.Radius + 1)
			local B = ShipWeapons.EnemyBolt
			table.insert(s.Bolts, { Pos = origin, Dir = dir, Speed = B.Speed, Life = B.Life, Damage = EnemyAI.damage(e), Enemy = true, Radius = B.HitRadius })
			broadcast("Bolt", { Pos = origin, Dir = dir, Speed = B.Speed, Life = B.Life, Enemy = true, Id = id })
		end
	end
end

local function stepBolts(s: Session, dt: number)
	local spec = ShipFlight.Specs[AirCombatService.ShipKind]
	for i = #s.Bolts, 1, -1 do
		local b = s.Bolts[i]
		local from = b.Pos
		local to = from + b.Dir * b.Speed * dt
		b.Pos = to
		b.Life -= dt
		local gone = b.Life <= 0
		if not gone then
			if b.Enemy then
				if not s.Down and ShipWeapons.segmentHits(from, to, s.Root.Position, spec.Radius * 0.9 + b.Radius) then
					damagePlayer(s, b.Damage, "Laser", from)
					gone = true
				end
			else
				for id, rec in s.Enemies do
					if ShipWeapons.segmentHits(from, to, rec.AI.Pos, rec.AI.Stats.Radius + b.Radius) then
						damageEnemy(s, id, b.Damage, "Laser", rec.AI.Pos)
						gone = true
						break
					end
				end
			end
			if not gone and Arena.segmentBlocked(from, to) then
				gone = true
			end
		end
		if gone then
			table.remove(s.Bolts, i)
		end
	end
end

local function stepMissiles(s: Session, dt: number)
	local M = ShipWeapons.Missile
	for i = #s.Missiles, 1, -1 do
		local m = s.Missiles[i]
		local rec = s.Enemies[m.Target]
		local from = ShipWeapons.steerMissile(m :: any, if rec then rec.AI.Pos else nil, dt)
		m.Life -= dt
		local hitId = nil
		if rec and ShipWeapons.segmentHits(from, m.Pos, rec.AI.Pos, rec.AI.Stats.Radius + M.HitRadius) then
			hitId = m.Target
		end
		if hitId or m.Life <= 0 or Arena.collide(m.Pos, 1) then
			table.remove(s.Missiles, i)
			broadcast("Boom", { Id = m.Id, Pos = m.Pos, Hit = hitId ~= nil })
			if hitId then
				damageEnemy(s, hitId, M.Damage, "Missile", m.Pos)
			end
		end
	end
end

local function stepSession(s: Session, dt: number)
	local t = now()
	local player = s.Player
	if not player.Parent or not s.Ship.Parent or not s.Root.Parent then
		AirCombatService.exit(player, "gone")
		return
	end
	local humanoid = s.Humanoid
	if not humanoid.Parent or humanoid.Health <= 0 then
		AirCombatService.exit(player, "character")
		return
	end
	validateShip(s, dt)
	if s.Down and t >= s.DownUntil then
		respawn(s)
	end
	local mode = Arena.modeAt(s.Root.Position)
	if mode ~= s.Section then
		s.Section = mode
		Waves.setSection(s.Spawner, mode)
		player:SetAttribute("AirCombat", mode)
	end
	Shields.regen(s.Hull, t, dt)
	ShipWeapons.tick(s.Gun, t, dt)
	local ev = Waves.step(s.Spawner, dt, aliveCount(s))
	if ev then
		if ev.Type == "Spawn" then
			spawnWave(s, ev)
		elseif ev.Type == "Cleared" then
			s.Score += 300 * ev.Wave
			send(player, "Wave", { Wave = ev.Wave, Cleared = true })
			emit(player, "WaveCleared", { Wave = ev.Wave, Score = s.Score })
		elseif ev.Type == "Done" then
			send(player, "Wave", { Wave = ev.Wave, Done = true })
			emit(player, "Done", { Wave = ev.Wave, Score = s.Score })
		end
	end
	stepEnemies(s, dt, t)
	stepBolts(s, dt)
	stepMissiles(s, dt)
	if t - s.StateAt >= AirCombatService.StateEvery then
		s.StateAt = t
		local alive = aliveCount(s)
		send(player, "State", {
			Hull = s.Hull.Hull,
			MaxHull = s.Hull.MaxHull,
			Shield = s.Hull.Shield,
			MaxShield = s.Hull.MaxShield,
			Missiles = s.Gun.Missiles,
			MaxMissiles = ShipWeapons.Missile.Ammo,
			Heat = s.Gun.Heat,
			Overheated = s.Gun.Overheated,
			Wave = s.Spawner.Wave,
			Alive = alive,
			Objective = Waves.objective(s.Spawner, alive),
			Score = s.Score,
			Kills = s.Kills,
			Down = s.Down,
			Section = s.Section,
		})
	end
end

local function ensureLoop()
	if loop then
		return
	end
	clock = 0
	loop = RunService.Heartbeat:Connect(function(dt)
		clock += dt
		if clock < AirCombatService.Tick then
			return
		end
		local step = math.min(clock, 0.1)
		clock = 0
		for _, s in table.clone(sessions) do
			local ok, err = pcall(stepSession, s, step)
			if not ok then
				warn("[AirCombatService] " .. tostring(err))
			end
		end
		if next(sessions) == nil and loop then
			loop:Disconnect()
			loop = nil
		end
	end)
end

---------------------------------------------------------------------
-- Disparar (lo pide el cliente; aquí se decide)
---------------------------------------------------------------------
local function onFire(s: Session, dir: any)
	if s.Down or typeof(dir) ~= "Vector3" then
		return
	end
	local look = s.Root.CFrame.LookVector
	if not ShipWeapons.aimAllowed(look, dir) or not ShipWeapons.tryLaser(s.Gun, now()) then
		return
	end
	local L = ShipWeapons.Laser
	local cf = s.Root.CFrame
	local unit = dir.Unit
	for _, side in { -1, 1 } do
		local origin = (cf * CFrame.new(side * L.Muzzle, -0.6, -7)).Position
		table.insert(s.Bolts, { Pos = origin, Dir = unit, Speed = L.Speed, Life = L.Life, Damage = L.Damage, Enemy = false, Radius = L.HitRadius })
	end
	broadcast("Bolt", { Pos = cf.Position, Dir = unit, Speed = L.Speed, Life = L.Life, Enemy = false, From = s.Player.UserId, Twin = L.Muzzle }, s.Player)
end

local function onMissile(s: Session, id: any)
	if s.Down or type(id) ~= "string" then
		return
	end
	local rec = s.Enemies[id]
	if not rec then
		return
	end
	local cf = s.Root.CFrame
	local dist = (rec.AI.Pos - cf.Position).Magnitude
	if dist > Lock.Config.Range * 1.25 or Lock.angle(cf.Position, cf.LookVector, rec.AI.Pos) > Lock.Config.Hold * 1.4 then
		return -- (no lo tenía fijado de verdad)
	end
	if not ShipWeapons.tryMissile(s.Gun, now()) then
		return
	end
	s.NextId += 1
	local mid = ("m%d_%d"):format(s.Player.UserId, s.NextId)
	local origin = (cf * CFrame.new(0, -1.4, -4)).Position
	table.insert(s.Missiles, { Id = mid, Pos = origin, Dir = cf.LookVector, Speed = 120, Life = ShipWeapons.Missile.Life, Target = id })
	broadcast("Missile", { Id = mid, Pos = origin, Dir = cf.LookVector, Target = id })
end

---------------------------------------------------------------------
-- Entrar y salir
---------------------------------------------------------------------
local function allowed(player: Player, opts: { [string]: any }): boolean
	if opts.Trusted == true then
		return true
	end
	local ok, yes = pcall(function()
		return service("TesterService").isTester(player)
	end)
	return ok and yes == true
end

function AirCombatService.enter(player: Player, options: { [string]: any }?): boolean
	local opts = options or {}
	if sessions[player] or not allowed(player, opts) then
		return false
	end
	local humanoid, root = humanoidOf(player)
	if not humanoid or not root or humanoid.Health <= 0 then
		return false
	end
	if player:GetAttribute("Piloting") ~= nil then
		toast(player, "Info", "Bájate del avión antes de ir a la arena ✈️")
		return false
	end
	if humanoid.SeatPart then
		pcall(function()
			service("VehicleService").standUp(player)
		end)
		humanoid.Sit = false
		local weld = humanoid.SeatPart and humanoid.SeatPart:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
	end
	pcall(function()
		humanoid:UnequipTools() -- (las armas de mano no se usan en la nave)
	end)
	local section = if opts.Section == "Space" then "Space" else "Atmos"
	local difficulty = if type(opts.Difficulty) == "string" and Waves.Difficulty[opts.Difficulty] then opts.Difficulty else "Normal"
	local World = script.Parent.Parent.World
	local AirArena = require(World.AirArena)
	local arena = AirArena.build()
	local cp = Arena.checkpoint(section)
	local ship = AirArena.ship(cp)
	ship.Name = "Nave_" .. player.UserId
	ship:SetAttribute("Pilot", player.UserId)
	local folder = Instance.new("Model")
	folder.Name = "AirEnemies_" .. player.UserId
	pcall(function()
		folder.ModelStreamingMode = Enum.ModelStreamingMode.PersistentPerPlayer
	end)
	ship.Parent = workspace
	folder.Parent = workspace
	for _, m in { arena, ship, folder } do
		pcall(function()
			m:AddPersistentPlayer(player)
		end)
	end
	local returnCF = root.CFrame
	player:SetAttribute("AirArenaReturn", returnCF.Position) -- (PositionService guarda esto, no la arena)
	pcall(function()
		player:RequestStreamAroundAsync(cp.Position, 5)
	end)
	local seat = ship:FindFirstChild("ShipSeat") :: Seat
	local shipRoot = ship.PrimaryPart :: BasePart
	root.CFrame = seat.CFrame * CFrame.new(0, 3, 0)
	seat:Sit(humanoid)
	shipRoot.Anchored = false
	pcall(function()
		shipRoot:SetNetworkOwner(player) -- la vuela su ordenador (sin retraso)
	end)
	local s: Session = {
		Player = player,
		Ship = ship,
		Root = shipRoot,
		Seat = seat,
		Humanoid = humanoid,
		Section = section,
		Difficulty = difficulty,
		Hull = Shields.new("Caza"),
		Gun = ShipWeapons.newGun(),
		Spawner = Waves.new({ Section = section, Difficulty = difficulty, FirstDelay = 5, MaxWaves = opts.MaxWaves }),
		Enemies = {},
		Folder = folder,
		Bolts = {},
		Missiles = {},
		Return = returnCF,
		LastPos = cp.Position,
		LastGood = cp,
		LastAt = now(),
		Down = false,
		DownUntil = 0,
		DownAt = nil,
		Score = 0,
		Kills = 0,
		NextId = 0,
		StateAt = 0,
		Exiting = false,
		Conns = {},
	}
	sessions[player] = s
	player:SetAttribute("AirCombat", section)
	-- Sentado siempre: si se suelta del asiento (saltar, otro sistema), vuelve a él
	table.insert(s.Conns, seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if s.Exiting or sessions[player] ~= s then
			return
		end
		if seat.Occupant ~= humanoid then
			task.defer(function()
				if not s.Exiting and sessions[player] == s and seat.Occupant == nil and humanoid.Parent and humanoid.Health > 0 then
					seat:Sit(humanoid)
				end
			end)
		end
	end))
	table.insert(s.Conns, player.CharacterRemoving:Connect(function()
		AirCombatService.exit(player, "character")
	end))
	send(player, "Start", { Ship = ship.Name, Section = section, Difficulty = difficulty, Checkpoint = cp })
	ensureLoop()
	return true
end

function AirCombatService.exit(player: Player, reason: string?)
	local s = sessions[player]
	if not s then
		return
	end
	s.Exiting = true
	sessions[player] = nil
	for _, c in s.Conns do
		c:Disconnect()
	end
	for id in table.clone(s.Enemies) do
		removeEnemy(s, id, false)
	end
	s.Folder:Destroy()
	local humanoid, root = humanoidOf(player)
	if humanoid and humanoid.SeatPart == s.Seat then
		humanoid.Sit = false
		local weld = s.Seat:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
	end
	s.Ship:Destroy()
	pcall(function()
		local arena = require(script.Parent.Parent.World.AirArena).get()
		if arena then
			arena:RemovePersistentPlayer(player)
		end
	end)
	-- De vuelta a donde estaba (si sigue con el mismo personaje)
	if root and s.Return and reason ~= "character" and reason ~= "gone" and player.Parent then
		pcall(function()
			player:RequestStreamAroundAsync(s.Return.Position, 5)
		end)
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = s.Return
	end
	player:SetAttribute("AirCombat", nil)
	if reason ~= "gone" then
		-- (si se va del juego, se deja: PositionService guarda ese sitio y no la arena)
		player:SetAttribute("AirArenaReturn", nil)
	end
	send(player, "End", { Reason = reason, Score = s.Score, Kills = s.Kills, Wave = s.Spawner.Wave })
	emit(player, "Exit", { Reason = reason, Score = s.Score, Kills = s.Kills, Wave = s.Spawner.Wave })
end

function AirCombatService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	notify = remotes:FindFirstChild("Notify") :: RemoteEvent?
	local existing = remotes:FindFirstChild("AirCombat") :: RemoteEvent?
	if not existing then
		local created = Instance.new("RemoteEvent")
		created.Name = "AirCombat"
		created.Parent = remotes
		existing = created
	end
	remote = existing
	;(existing :: RemoteEvent).OnServerEvent:Connect(function(player, action, a)
		local s = sessions[player]
		if not s then
			return
		end
		if action == "Fire" then
			onFire(s, a)
		elseif action == "Missile" then
			onMissile(s, a)
		elseif action == "Crash" then
			goDown(s, "Te has estrellado contra " .. (if type(a) == "string" then string.sub(a, 1, 30) else "algo"))
		elseif action == "Exit" then
			AirCombatService.exit(player, "exit")
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		AirCombatService.exit(player, "gone")
	end)
end

-- (pruebas)
AirCombatService._sessions = sessions
AirCombatService._step = stepSession
AirCombatService._fire = onFire
AirCombatService._missile = onMissile

return AirCombatService
