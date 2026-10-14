-- AirCombatService: combate aéreo y espacial (núcleo de la Saga 2; ahora se prueba en la arena del
-- Modo pruebas: TesterService "AirArena"). Ver docs/combate-aereo.md.
--
-- Quién manda en qué (para que no se pueda hacer trampa, pero que vuele suave):
--   * La NAVE la mueve el ordenador del piloto con shared/AirCombat/ShipFlight (predicción: sin
--     retraso), pero SIN física ni dueño de red: la nave (y el piloto sentado, soldado a ella) va
--     ANCLADA y el cliente pone su CFrame cada fotograma. 20 veces por segundo manda "Pose" (su CFrame)
--     y aquí se comprueba (onPose) que el salto sea posible (ShipFlight.plausible con el tiempo de
--     verdad), que siga dentro de la arena y que no esté dentro de una roca o un asteroide
--     (shared/AirCombat/Arena: las mismas formas que usa el cliente). Si vale, el servidor mueve la
--     nave ahí (los demás la ven); si no, vuelve al último sitio bueno ("Reset") o se estrella.
--     (Antes era física con SetNetworkOwner: con el streaming «MinimumRadiusPause» y las piezas a
--     24 000 studs, el móvil del dueño no movía la nave. Anclada y por CFrame no depende de nada de eso.)
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
-- Remoto "AirCombat" (cliente → servidor): "Pose" (CFrame), "Fire" (dir), "Missile" (id), "Crash" (motivo),
--   "Exit", "Diag" (texto: un problema del cliente, sale en la consola del servidor).
-- (servidor → cliente): "Start", "End", "State", "Bolt", "Missile", "Boom", "Burst", "Hit", "HitMark",
--   "Down", "Respawn", "Reset", "Wave".
-- Mientras nadie está en la arena, este servicio no hace NADA (ni bucle ni piezas).
--
-- Dos sitios para volar (opción World de enter):
--   "Arena"  (por defecto) la arena de pruebas, lejos de Valmar (shared/AirCombat/Arena), con oleadas.
--   "Cosmos" el cielo y el espacio encima de Valmar (shared/Cosmos/Zone, Services/SpaceService): vuelo
--            libre (sin oleadas; los enemigos los pone SpaceService con spawnEnemy en los sectores con
--            patrullas), zonas seguras en las estaciones (sin disparos ni daño) y los disparos que dan
--            en un asteroide avisan con el evento "Rock" (minar).
--   "Planet" la superficie de un planeta (opción Geo: shared/Cosmos/Lontana; Services/PlanetService):
--            vuelo libre con gravedad, aterrizar y bajarse (docs/planetas.md).
-- Más API: spawnEnemy(player, tipo, pos, escala) · enemyList(player) · dropEnemy(player, id) ·
--   setReturn(player, cframe) · setObjective(player, fn) · status(player) · world(player) ·
--   relocate(player, cframe, { World, Geo, Planet }) (pasar del espacio a un planeta y al revés sin
--   cortar el vuelo: el cliente sigue con su velocidad; "Relocate" al cliente)

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
local Zone = require(ReplicatedStorage.Shared.Cosmos.Zone)
local Layers = require(ReplicatedStorage.Shared.Cosmos.Layers)
local ShipSystems = require(script.Parent.ShipSystems)

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
	PoseAt: number, -- cuándo llegó el último "Pose" bueno
	Vel: Vector3, -- velocidad (de los "Pose")
	Poses: number, -- cuántos "Pose" buenos
	Rejects: number, -- y rechazados (seguidos)
	LogAt: number,
	Legs: { [Instance]: number }?, -- piernas escondidas (dentro del fuselaje)
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
	Geo: any?, -- (la geometría: Arena o Cosmos/Zone; sin ella, Arena)
	World: string?, -- "Arena" | "Cosmos" | "Planet"
	Planet: string?, -- (World = "Planet") id del planeta
	RelocatedAt: number?, -- cuándo se movió de sitio (relocate): los "Pose" viejos se ignoran
	Free: boolean?, -- vuelo libre: sin oleadas
	ObjectiveFn: (() -> string?)?,
	OnExit: ((Player) -> ())?,
	SafeToastAt: number?,
	-- (Espacio AAA: Services/ShipSystems) energía, habilidades y arma
	Abil: any?,
	Weapon: string?,
	HurtAt: number?,
	IFramesUntil: number?,
	AllowSpeed: number?,
	AllowUntil: number?,
	Hyper: any?,
	HyperGraceUntil: number?,
	Quantum: any?,
	ReqAt: number?,
	NavFn: ((Player) -> any)?,
	InfoFn: ((Player) -> any)?,
	NavAt: number?,
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

-- (Espacio AAA) Quién da los datos de navegación (destinos del salto: descubiertos, misiones, planetas) y
-- lo que sale en el HUD («Nav»: Chispas, misiones, eventos). Lo pone Services/SpaceService.
AirCombatService.NavProvider = nil :: ((Player) -> any)?
AirCombatService.InfoProvider = nil :: ((Player) -> any)?
function AirCombatService.setProviders(nav: ((Player) -> any)?, info: ((Player) -> any)?)
	AirCombatService.NavProvider = nav
	AirCombatService.InfoProvider = info
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

-- Mensajes para la consola (F9 en Roblox): «[AirCombat] …»
local function log(s: any, text: string)
	local who = if s and s.Player then s.Player.Name else "?"
	print(("[AirCombat] %s: %s"):format(tostring(who), text))
end
AirCombatService.Log = log

local function geoOf(s: Session): any
	return s.Geo or Arena
end

-- ¿Está la nave en una zona segura (una estación espacial)?
local function isSafe(s: Session, pos: Vector3?): boolean
	local g = geoOf(s)
	return g.safeAt ~= nil and g.safeAt(pos or s.Root.Position) == true
end

-- Lo que necesita Services/ShipSystems para decidir (energía, esquiva, hipervelocidad, salto)
local function systemsCtx(s: Session): { [string]: any }
	return {
		send = function(kind: string, payload: any)
			send(s.Player, kind, payload)
		end,
		toast = function(kind: string, text: string)
			toast(s.Player, kind, text)
		end,
		geo = geoOf(s),
		now = now,
		others = function(): { Vector3 }
			local out = {}
			for p, o in sessions do
				if p ~= s.Player and o.Root and o.Root.Parent and not o.Down then
					table.insert(out, o.Root.Position)
				end
			end
			return out
		end,
		enemies = function(): { Vector3 }
			local out = {}
			for _, rec in s.Enemies do
				table.insert(out, rec.AI.Pos)
			end
			return out
		end,
		relocate = function(cf: CFrame): boolean
			return AirCombatService.relocate(s.Player, cf, { World = "Cosmos" })
		end,
		nav = function(): any
			local fn = s.NavFn or AirCombatService.NavProvider
			return if fn then fn(s.Player) else nil
		end,
	}
end
AirCombatService._systemsCtx = systemsCtx

---------------------------------------------------------------------
-- Enemigos
---------------------------------------------------------------------
local function enemyCFrame(e: EnemyAI.Enemy): CFrame
	return CFrame.new(e.Pos) * ShipFlight.facing(e.Look)
end

local function spawnEnemy(s: Session, kind: string, pos: Vector3, scale: Waves.Scale)
	s.NextId += 1
	local id = ("%d_%d"):format(s.Player.UserId, s.NextId)
	local look = (geoOf(s).center(s.Section) - pos)
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
	local center = geoOf(s).center(s.Section)
	local turretSpots = geoOf(s).turretSpots(s.Section)
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
local hideLegs: (Session, boolean) -> ()

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

-- Sentado en la cabina, las piernas van dentro del fuselaje; las que asomarían por debajo (personajes
-- grandes) se esconden mientras vuela y vuelven al bajarse
local LEGS = { "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot", "Left Leg", "Right Leg" }
function hideLegs(s: Session, hidden: boolean)
	local character = s.Player.Character
	if hidden then
		if s.Legs or not character then
			return
		end
		local list = {}
		for _, name in LEGS do
			local leg = character:FindFirstChild(name)
			if leg and leg:IsA("BasePart") then
				list[leg] = leg.Transparency
				leg.Transparency = 1
			end
		end
		s.Legs = list
	elseif s.Legs then
		for leg, t in s.Legs do
			if leg.Parent then
				(leg :: BasePart).Transparency = t
			end
		end
		s.Legs = nil
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
	local g = geoOf(s)
	local section = g.modeAt(s.DownAt or s.Root.Position)
	local cp = g.checkpoint(section, s.DownAt)
	s.Down = false
	s.DownAt = nil
	Shields.reset(s.Hull)
	s.Gun = ShipWeapons.newGun()
	local weapon = s.Weapon
	ShipSystems.attach(s)
	s.Weapon = weapon
	setShipHidden(s, false)
	s.Root.CFrame = cp
	s.LastPos, s.LastGood = cp.Position, cp
	s.PoseAt, s.Vel = now(), Vector3.zero
	-- (los disparos enemigos que iban hacia ti se pierden)
	for i = #s.Bolts, 1, -1 do
		if s.Bolts[i].Enemy then
			table.remove(s.Bolts, i)
		end
	end
	send(s.Player, "Respawn", { CFrame = cp, Section = section })
end

local function damagePlayer(s: Session, amount: number, kind: string, from: Vector3)
	if s.Down or isSafe(s) then
		return
	end
	local t = now()
	if s.Abil and ShipSystems.invulnerable(s, t) then
		send(s.Player, "Evaded", { From = from }) -- (esquiva: invulnerable un instante)
		return
	end
	if s.Abil then
		ShipSystems.hurt(s, t)
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
		{ Id = tostring(s.Player.UserId), Pos = root.Position, Vel = s.Vel or Vector3.zero, Look = root.CFrame.LookVector, Alive = not s.Down and not isSafe(s) },
	}
end

-- Lo que manda el cliente 20 veces por segundo: dónde está su nave. Si el salto es posible y sigue en la
-- arena, el servidor la pone ahí (los demás la ven); si no, al último sitio bueno ("Reset").
local function onPose(s: Session, cf: any)
	if s.Down or typeof(cf) ~= "CFrame" then
		return
	end
	local pos = cf.Position
	if pos.X ~= pos.X or pos.Y ~= pos.Y or pos.Z ~= pos.Z then
		return
	end
	local t = now()
	local spec = ShipFlight.Specs[AirCombatService.ShipKind]
	local g = geoOf(s)
	-- (los paquetes pueden llegar juntos: algo de margen de tiempo)
	local dt = math.min(t - (s.PoseAt or t), 2) + 0.2
	local extra = if s.Abil then ShipSystems.allowance(s, t) else 0
	local blocked = false
	if extra > 0 or (pos - s.LastPos).Magnitude > spec.Radius * 4 then
		-- (movimiento largo, p. ej. hipervelocidad: el camino entero no puede atravesar nada)
		local from = s.LastPos
		local len = (pos - from).Magnitude
		local steps = math.clamp(math.ceil(len / 20), 1, 200)
		for i = 1, steps do
			if g.collide(from:Lerp(pos, i / steps), spec.Radius * 0.6) then
				blocked = true
				break
			end
		end
	end
	if blocked or not ShipFlight.plausible(spec, s.LastPos, pos, dt, extra) or not g.contains(pos, 400) then
		if s.RelocatedAt and t - s.RelocatedAt < 1.5 then
			return -- (un "Pose" de antes de pasar al planeta o al espacio: llega tarde, se ignora)
		end
		s.Rejects = (s.Rejects or 0) + 1
		if s.Rejects == 1 or s.Rejects % 20 == 0 then
			log(s, ("posición rechazada (%d seguidas): salto de %.0f studs en %.2f s%s"):format(
				s.Rejects, (pos - s.LastPos).Magnitude, dt, if g.contains(pos, 400) then "" else ", fuera de la arena"))
		end
		s.Root.CFrame = s.LastGood
		send(s.Player, "Reset", { CFrame = s.LastGood })
		s.PoseAt = t
		return
	end
	s.Rejects = 0
	local step = math.max(t - (s.PoseAt or t), 1 / 60)
	s.Vel = (pos - s.LastPos) / step
	s.Root.CFrame = cf
	s.LastPos = pos
	s.LastGood = cf
	s.PoseAt = t
	s.Poses = (s.Poses or 0) + 1
end

local function validateShip(s: Session, dt: number)
	if s.Down then
		return
	end
	local root = s.Root
	local pos = root.Position
	local spec = ShipFlight.Specs[AirCombatService.ShipKind]
	local g = geoOf(s)
	if not g.contains(pos, 400) then
		-- Fuera de la arena (no debería: onPose no lo deja): al último sitio bueno
		root.CFrame = s.LastGood
		send(s.Player, "Reset", { CFrame = s.LastGood })
		s.LastPos = s.LastGood.Position
		return
	end
	local hit = g.collide(pos, spec.Radius * 0.7)
	if hit then
		goDown(s, "Te has estrellado contra " .. hit)
		return
	end
	-- (si el cliente no manda dónde está, la nave no se mueve para nadie: se avisa en la consola)
	local t = now()
	if t - (s.PoseAt or t) > 4 and t - (s.LogAt or 0) > 10 then
		s.LogAt = t
		log(s, ("no llegan posiciones del cliente desde hace %.0f s (¿AirCombatClient no ha arrancado?)"):format(t - (s.PoseAt or t)))
	end
end

local function stepEnemies(s: Session, dt: number, t: number)
	local g = geoOf(s)
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
		local back = (g.enemyBounds or g.bounds)(e.Pos)
		if back then
			desired = (desired + back * 2).Unit
		end
		local before = e.Pos
		EnemyAI.steer(e, desired, speed, dt)
		if e.Kind ~= "Torreta" and g.collide(e.Pos, e.Stats.Radius) then
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
	local g = geoOf(s)
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
				if not gone and g.rockHit then
					-- (Cosmos: un láser tuyo que da en un asteroide lo mina: SpaceService lo decide)
					local rock, at = g.rockHit(from, to)
					if rock then
						gone = true
						emit(s.Player, "Rock", { Id = rock.Id, Pos = at, Ship = s.Root.Position })
					end
				end
			end
			if not gone and g.segmentBlocked(from, to) then
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
		if hitId or m.Life <= 0 or geoOf(s).collide(m.Pos, 1) then
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
	local mode = geoOf(s).modeAt(s.Root.Position)
	if mode ~= s.Section then
		s.Section = mode
		Waves.setSection(s.Spawner, mode)
		player:SetAttribute("AirCombat", mode)
	end
	Shields.regen(s.Hull, t, dt)
	ShipWeapons.tick(s.Gun, t, dt)
	if s.Abil then
		ShipSystems.tick(s, systemsCtx(s), t, dt)
	end
	local ev = if s.Free then nil else Waves.step(s.Spawner, dt, aliveCount(s))
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
		local state = {
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
			Objective = (s.ObjectiveFn and s.ObjectiveFn()) or (if s.Free then "Vuelo libre" else Waves.objective(s.Spawner, alive)),
			Safe = isSafe(s),
			Score = s.Score,
			Kills = s.Kills,
			Down = s.Down,
			Section = s.Section,
		}
		if s.Abil then
			for k, v in ShipSystems.state(s, systemsCtx(s), t) do
				state[k] = v
			end
		end
		send(player, "State", state)
		-- Navegación (1 vez por segundo): Chispas, misiones, descubiertos… (Services/SpaceService)
		local infoFn = s.InfoFn or AirCombatService.InfoProvider
		if infoFn and t - (s.NavAt or 0) >= 1 then
			s.NavAt = t
			local ok, info = pcall(infoFn, player)
			if ok and type(info) == "table" then
				send(player, "Nav", info)
			end
		end
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
	if isSafe(s) then
		-- (zona segura de una estación: aquí no se dispara)
		local t = now()
		if not s.SafeToastAt or t - s.SafeToastAt > 4 then
			s.SafeToastAt = t
			toast(s.Player, "Info", "🛡️ Zona segura de la estación: aquí no se dispara")
		end
		return
	end
	local look = s.Root.CFrame.LookVector
	local weapon = s.Weapon or "Cannons"
	if not ShipWeapons.aimAllowed(look, dir) or not ShipWeapons.tryLaser(s.Gun, now(), weapon) then
		return
	end
	local L = ShipWeapons.spec(weapon)
	local cf = s.Root.CFrame
	local unit = dir.Unit
	for _, side in (if weapon == "Laser" then { 0 } else { -1, 1 }) do
		local origin = (cf * CFrame.new(side * L.Muzzle, -0.6, -7)).Position
		table.insert(s.Bolts, { Pos = origin, Dir = unit, Speed = L.Speed, Life = L.Life, Damage = L.Damage, Enemy = false, Radius = L.HitRadius })
	end
	broadcast("Bolt", { Pos = cf.Position, Dir = unit, Speed = L.Speed, Life = L.Life, Enemy = false, From = s.Player.UserId, Twin = L.Muzzle, Weapon = weapon }, s.Player)
end

local function onMissile(s: Session, id: any)
	if s.Down or type(id) ~= "string" or isSafe(s) then
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
	local cosmos = opts.World == "Cosmos"
	local planet = opts.World == "Planet" and type(opts.Geo) == "table"
	local geo: any = if planet then opts.Geo elseif cosmos then Zone else Arena
	local section = if opts.Section == "Space" then "Space" else "Atmos"
	local difficulty = if type(opts.Difficulty) == "string" and Waves.Difficulty[opts.Difficulty] then opts.Difficulty else "Normal"
	local World = script.Parent.Parent.World
	local AirArena = require(World.AirArena)
	local arena = if cosmos or planet then nil else AirArena.build()
	local cp = if typeof(opts.Start) == "CFrame" then opts.Start else geo.checkpoint(section)
	section = geo.modeAt(cp.Position)
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
	for _, m in { arena or ship, ship, folder } do
		pcall(function()
			m:AddPersistentPlayer(player)
		end)
	end
	local returnCF = if typeof(opts.Return) == "CFrame" then opts.Return else root.CFrame
	player:SetAttribute("AirArenaReturn", returnCF.Position) -- (PositionService guarda esto, no la arena)
	pcall(function()
		player:RequestStreamAroundAsync(cp.Position, 5)
	end)
	local seat = ship:FindFirstChild("ShipSeat") :: Seat
	local shipRoot = ship.PrimaryPart :: BasePart
	root.CFrame = seat.CFrame * CFrame.new(0, 3, 0)
	seat:Sit(humanoid)
	-- (la nave sigue ANCLADA: la mueve el CFrame que pone el cliente, no la física; ver arriba)
	shipRoot.Anchored = true
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
		Geo = geo,
		World = if planet then "Planet" elseif cosmos then "Cosmos" else "Arena",
		Planet = if planet and type(opts.Planet) == "string" then opts.Planet else nil,
		Free = opts.Free == true or cosmos or planet,
		ObjectiveFn = if type(opts.Objective) == "function" then opts.Objective else nil,
		OnExit = if type(opts.OnExit) == "function" then opts.OnExit else nil,
		Enemies = {},
		Folder = folder,
		Bolts = {},
		Missiles = {},
		Return = returnCF,
		LastPos = cp.Position,
		LastGood = cp,
		LastAt = now(),
		PoseAt = now(),
		Vel = Vector3.zero,
		Poses = 0,
		Rejects = 0,
		LogAt = 0,
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
	-- (lo que traía la nave: casco y misiles de antes de atracar)
	if type(opts.Hull) == "number" then
		s.Hull.Hull = math.clamp(opts.Hull, 1, s.Hull.MaxHull)
	end
	if type(opts.Missiles) == "number" then
		s.Gun.Missiles = math.clamp(math.floor(opts.Missiles), 0, ShipWeapons.Missile.Ammo)
	end
	ShipSystems.attach(s)
	s.NavFn = if type(opts.Nav) == "function" then opts.Nav else nil
	s.InfoFn = if type(opts.Info) == "function" then opts.Info else nil
	sessions[player] = s
	hideLegs(s, true)
	log(s, ("entra en %s (%s), nave %s anclada y sentado: %s"):format(s.World or "Arena", section, ship.Name, tostring(humanoid.SeatPart == seat)))
	player:SetAttribute("AirCombatWorld", s.World)
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
					log(s, "se había levantado del asiento: vuelve a sentarse")
				end
			end)
		end
	end))
	table.insert(s.Conns, player.CharacterRemoving:Connect(function()
		AirCombatService.exit(player, "character")
	end))
	send(player, "Start", { Ship = ship.Name, Section = section, Difficulty = difficulty, Checkpoint = cp, World = s.World, Planet = s.Planet, Landed = opts.Landed == true })
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
	hideLegs(s, false)
	local humanoid, root = humanoidOf(player)
	if humanoid and humanoid.SeatPart == s.Seat then
		humanoid.Sit = false
		local weld = s.Seat:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
	end
	s.Ship:Destroy()
	if s.World == "Arena" then
		pcall(function()
			local arena = require(script.Parent.Parent.World.AirArena).get()
			if arena then
				arena:RemovePersistentPlayer(player)
			end
		end)
	end
	-- De vuelta a donde estaba (si sigue con el mismo personaje)
	if root and s.Return and reason ~= "character" and reason ~= "gone" and player.Parent then
		pcall(function()
			player:RequestStreamAroundAsync(s.Return.Position, 5)
		end)
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = s.Return
	end
	player:SetAttribute("AirCombat", nil)
	player:SetAttribute("AirCombatWorld", nil)
	if reason ~= "gone" then
		-- (si se va del juego, se deja: PositionService guarda ese sitio y no la arena)
		player:SetAttribute("AirArenaReturn", nil)
	end
	send(player, "End", { Reason = reason, Score = s.Score, Kills = s.Kills, Wave = s.Spawner.Wave, World = s.World })
	emit(player, "Exit", { Reason = reason, Score = s.Score, Kills = s.Kills, Wave = s.Spawner.Wave, World = s.World, Planet = s.Planet, Pos = s.Root.Position, Hull = s.Hull.Hull, MaxHull = s.Hull.MaxHull, Missiles = s.Gun.Missiles, Down = s.Down })
end

---------------------------------------------------------------------
-- Para SpaceService (vuelo libre encima de Valmar)
---------------------------------------------------------------------
function AirCombatService.world(player: Player): string?
	local s = sessions[player]
	return s and s.World
end

-- Un enemigo nuevo en la sesión de ese piloto (en el sitio que se diga). Devuelve su id.
function AirCombatService.spawnEnemy(player: Player, kind: string, pos: Vector3, scale: Waves.Scale?): string?
	local s = sessions[player]
	if not s or not EnemyAI.Kinds[kind] then
		return nil
	end
	if s.World ~= "Arena" and not Layers.aiAllowed(pos) then
		return nil -- (nunca en el cielo de los aviones ni en la transición)
	end
	spawnEnemy(s, kind, pos, scale or Waves.scale(1, s.Difficulty))
	return ("%d_%d"):format(s.Player.UserId, s.NextId)
end

-- Los enemigos vivos de ese piloto: { { Id, Kind, Pos } }
function AirCombatService.enemyList(player: Player): { { Id: string, Kind: string, Pos: Vector3 } }
	local out = {}
	local s = sessions[player]
	if s then
		for id, rec in s.Enemies do
			table.insert(out, { Id = id, Kind = rec.AI.Kind, Pos = rec.AI.Pos })
		end
	end
	return out
end

-- Quitar un enemigo sin que cuente como derribo (se ha quedado muy lejos)
function AirCombatService.dropEnemy(player: Player, id: string)
	local s = sessions[player]
	if s then
		removeEnemy(s, id, false)
	end
end

-- Pasar la nave a otro sitio SIN cortar el vuelo (del espacio a la superficie de un planeta y al
-- revés: Services/PlanetService). La nave sigue siendo la misma (casco, misiles, velocidad en el cliente);
-- cambia la geometría (choques, límites) y el mundo. opts = { World = "Cosmos" | "Planet", Geo, Planet }
function AirCombatService.relocate(player: Player, cf: CFrame, opts: { [string]: any }): boolean
	local s = sessions[player]
	if not s or s.Down or s.World == "Arena" then
		return false
	end
	local world = if opts.World == "Planet" then "Planet" else "Cosmos"
	local geo: any = if world == "Planet" then opts.Geo else Zone
	if type(geo) ~= "table" then
		return false
	end
	-- (los enemigos y disparos del espacio no bajan al planeta)
	for id in table.clone(s.Enemies) do
		removeEnemy(s, id, false)
	end
	table.clear(s.Bolts)
	table.clear(s.Missiles)
	s.Hyper = nil
	s.Geo = geo
	s.World = world
	s.Planet = if world == "Planet" then opts.Planet else nil
	s.Free = true
	local t = now()
	s.Root.CFrame = cf
	s.LastPos, s.LastGood = cf.Position, cf
	s.PoseAt, s.RelocatedAt = t, t
	s.Rejects = 0
	s.Section = geo.modeAt(cf.Position)
	player:SetAttribute("AirCombatWorld", world)
	player:SetAttribute("AirCombat", s.Section)
	task.spawn(function()
		pcall(function()
			player:RequestStreamAroundAsync(cf.Position, 5)
		end)
	end)
	send(player, "Relocate", { CFrame = cf, World = world, Planet = s.Planet, Section = s.Section })
	log(s, ("pasa a %s%s"):format(world, if s.Planet then " (" .. s.Planet .. ")" else ""))
	return true
end

-- A dónde vuelve al salir de la nave
function AirCombatService.setReturn(player: Player, cf: CFrame)
	local s = sessions[player]
	if s then
		s.Return = cf
		player:SetAttribute("AirArenaReturn", cf.Position)
	end
end

function AirCombatService.setObjective(player: Player, fn: (() -> string?)?)
	local s = sessions[player]
	if s then
		s.ObjectiveFn = fn
	end
end

-- Cómo está la nave: { Pos, Look, Hull, MaxHull, Shield, Missiles, Down, Safe, Section, World }
function AirCombatService.status(player: Player): { [string]: any }?
	local s = sessions[player]
	if not s then
		return nil
	end
	return {
		Pos = s.Root.Position,
		Look = s.Root.CFrame.LookVector,
		Hull = s.Hull.Hull,
		MaxHull = s.Hull.MaxHull,
		Shield = s.Hull.Shield,
		Missiles = s.Gun.Missiles,
		Down = s.Down,
		Safe = isSafe(s),
		Section = s.Section,
		World = s.World,
		Planet = s.Planet,
		Vel = s.Vel,
		CFrame = s.Root.CFrame,
	}
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
		if action == "Pose" then
			onPose(s, a)
		elseif action == "Diag" then
			if type(a) == "string" then
				log(s, "cliente: " .. string.sub(a, 1, 200))
			end
		elseif action == "Fire" then
			onFire(s, a)
		elseif action == "Missile" then
			onMissile(s, a)
		elseif action == "Dodge" or action == "Hyper" or action == "HyperStop" or action == "QuantumList" or action == "Quantum" or action == "QuantumCancel" or action == "Weapon" or action == "Reload" then
			if s.Abil then
				ShipSystems.request(s, systemsCtx(s), action, a)
			end
		elseif action == "Crash" then
			goDown(s, "Te has estrellado contra " .. (if type(a) == "string" then string.sub(a, 1, 30) else "algo"))
		elseif action == "Exit" then
			if s.OnExit then
				s.OnExit(player) -- (Cosmos: SpaceService decide si se puede bajar aquí)
			else
				AirCombatService.exit(player, "exit")
			end
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
AirCombatService._pose = onPose
AirCombatService._damagePlayer = damagePlayer

return AirCombatService
