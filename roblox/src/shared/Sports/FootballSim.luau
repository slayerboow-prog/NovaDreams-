-- FootballSim (compartido): un partido (o unos penaltis, o unos pases) entero, sin nada de Roblox.
-- El servidor (FootballService) lo hace avanzar con los jugadores de verdad (sus posiciones) y los
-- golpeos que piden, y él mueve el balón (Sports/Ball), los jugadores de la máquina (Sports/FootballAI)
-- y las reglas. Se prueba en scripts/test-futbol.luau (partidos enteros entre máquinas, penaltis…).
--
-- Modos:
--   Libre     el balón y dos porteros: chutar, regatear y meter goles sin reglas (el balón vuelve)
--   Partido   N contra N con reloj, marcador, saque de centro, de banda, de puerta y córner
--   Penaltis  tú tiras (Rounds tiros) y el portero se estira; Need goles para ganar
--   Pases     un compañero se coloca (o corre al hueco) y tienes que pasárselo; Need pases buenos
--
-- Coordenadas del campo (Sports/Pitch). El equipo 1 (el tuyo) ataca hacia +X.
--
--   local sim = FootballSim.new(pitch, { Mode = "Partido", Duration = 150, Seed = 1 })
--   FootballSim.addPlayer(sim, { Id = "u1", Name = "Tú", Team = 1, Human = true, Role = "FW" })
--   FootballSim.fillTeams(sim, 5, { "Nico", "Sara" }, { "Bruno" })   -- máquinas hasta 5 por equipo
--   FootballSim.start(sim)
--   cada frame: FootballSim.setHuman(sim, "u1", pies, velocidad, mirada); FootballSim.step(sim, dt)
--   FootballSim.kick(sim, "u1", { Kind = "Shoot", Dir, Power, Curl, Loft }) / tackle(sim, "u1", dir)
--   sim.Events: lo que ha pasado (goles, golpeos, paradas, salidas, final…) para el servidor

local Pitch = require(script.Parent.Pitch)
local Ball = require(script.Parent.Ball)
local AI = require(script.Parent.FootballAI)

local FootballSim = {}

export type Player = { [string]: any }
export type Sim = { [string]: any }

FootballSim.Config = {
	Tick = 1 / 30, -- paso fijo
	Think = 0.22, -- cada cuánto deciden las máquinas (s)
	Accel = 46, -- aceleración de las máquinas (studs/s²)
	BotSpeed = 15,
	ControlRadius = 1.75, -- distancia (pies-balón) para hacerse con él
	HumanReach = 0.9, -- holgura para las personas (su posición llega con retraso al servidor)
	KickReach = 3.8, -- distancia máxima para golpear un balón que no llevas
	TackleReach = 3.4,
	GoalPause = 3.2,
	RestartPause = 1.1,
	KickoffPause = 1.4,
	PenResultPause = 2,
	PenTimeout = 30, -- sin chutar en este tiempo, el penalti cuenta como fallado (la historia no se para)
	PenFlight = 3,
	PassTimeout = 25,
	PassFlight = 4.5,
	OutsideReset = 1.6, -- (Libre) fuera del campo este tiempo: el balón vuelve dentro
}
local CFG = FootballSim.Config

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function event(sim: Sim, kind: string, data: { [string]: any }?)
	local e = data or {}
	e.Kind = kind
	e.T = sim.T
	table.insert(sim.Events, e)
	return e
end

function FootballSim.new(pitch: Pitch.Pitch, opts: { [string]: any }?): Sim
	local o = opts or {}
	local rng = if o.Rng then o.Rng else Random.new(o.Seed or 1)
	local sim: Sim = {
		Pitch = pitch,
		Mode = o.Mode or "Libre",
		Duration = o.Duration or 180,
		Rounds = o.Rounds or 5,
		Need = o.Need or 0,
		Variant = o.Variant,
		StopWhenDecided = o.StopWhenDecided ~= false,
		Scale = o.Scale or 1,
		BotSpeed = o.BotSpeed or CFG.BotSpeed,
		Rng = rng,
		T = 0,
		Clock = 0,
		Phase = "Idle",
		PhaseUntil = 0,
		Score = { [1] = 0, [2] = 0 },
		Players = {},
		Order = {},
		Keepers = {}, -- [lado] = id del portero que defiende esa portería
		Ball = Ball.new(Vector3.new(0, Ball.Config.Radius, 0)),
		Owner = nil :: string?,
		LastTouch = nil :: string?,
		KickSeq = 0,
		Events = {},
		Path = nil,
		PathAt = -1,
		Exclusive = nil,
		OutsideSince = nil,
		-- Penaltis y pases
		Taken = 0,
		Hits = 0,
		Round = 0,
		Receiver = nil :: string?,
		Over = false,
		NoCarry = o.Mode == "Penaltis",
		Accumulator = 0,
	}
	return sim
end

---------------------------------------------------------------------
-- Jugadores
---------------------------------------------------------------------

-- spec: { Id, Name, Team, Human, Role, Skill, Npc }
function FootballSim.addPlayer(sim: Sim, spec: { [string]: any }): Player
	local p: Player = {
		Id = spec.Id,
		Name = spec.Name or spec.Id,
		Npc = spec.Npc,
		Team = spec.Team or 1,
		Human = spec.Human == true,
		Role = spec.Role or "MF",
		Skill = math.clamp(spec.Skill or 0.5, 0, 1),
		Scale = spec.Scale or sim.Scale,
		Slot = { spec.Role or "MF", 0, 0 },
		P = spec.P or Vector3.zero,
		V = Vector3.zero,
		Facing = Vector3.new(AI.attack(spec.Team or 1), 0, 0),
		MaxSpeed = spec.Speed or (sim.BotSpeed * (0.9 + 0.2 * (spec.Skill or 0.5))),
		Stun = 0,
		KickCd = 0,
		TackleCd = 0,
		Slide = 0,
		SlideDir = Vector3.new(1, 0, 0),
		Dive = nil,
		DiveSeq = -1,
		NextThink = 0,
		Action = nil,
		Target = nil,
		Run = 0, -- distancia recorrida con el balón (los toques al conducir)
		HoldUntil = 0,
	}
	sim.Players[p.Id] = p
	table.insert(sim.Order, p.Id)
	return p
end

function FootballSim.removePlayer(sim: Sim, id: string)
	if not sim.Players[id] then
		return
	end
	sim.Players[id] = nil
	local i = table.find(sim.Order, id)
	if i then
		table.remove(sim.Order, i)
	end
	if sim.Owner == id then
		sim.Owner = nil
	end
	for side, kid in sim.Keepers do
		if kid == id then
			sim.Keepers[side] = nil
		end
	end
	if sim.Receiver == id then
		sim.Receiver = nil
	end
end

-- Coloca a cada uno en su sitio de la formación (los porteros, en su portería)
function FootballSim.arrange(sim: Sim)
	table.clear(sim.Keepers)
	for team = 1, 2 do
		local members = {}
		for _, id in sim.Order do
			local p = sim.Players[id]
			if p.Team == team then
				table.insert(members, p)
			end
		end
		local n = math.clamp(#members, 1, 6)
		local formation = AI.Formations[n] or AI.Formations[5]
		local free = table.clone(formation)
		local function take(p: Player, role: string?): boolean
			for i, slot in free do
				if role == nil or slot[1] == role then
					p.Slot = slot
					p.Role = slot[1]
					table.remove(free, i)
					return true
				end
			end
			return false
		end
		-- Primero quien quiere ser portero; luego las personas en su puesto; luego el resto
		local order = table.clone(members)
		table.sort(order, function(a, b)
			local ka = (if a.Role == "GK" then 0 elseif a.Human then 1 else 2)
			local kb = (if b.Role == "GK" then 0 elseif b.Human then 1 else 2)
			if ka ~= kb then
				return ka < kb
			end
			return a.Id < b.Id
		end)
		local keeperTaken = false
		for _, p in order do
			if p.Role == "GK" and not keeperTaken and take(p, "GK") then
				keeperTaken = true
			elseif p.Human and p.Role ~= "GK" and take(p, p.Role) then
				-- (su puesto)
			else
				-- Las máquinas: el portero lo pone la primera que quede si nadie lo quiso
				if not keeperTaken and not p.Human and take(p, "GK") then
					keeperTaken = true
				elseif not take(p, nil) then
					p.Slot = { p.Role, 0, 0 }
				end
			end
		end
		for _, p in members do
			if p.Role == "GK" then
				sim.Keepers[-AI.attack(team)] = p.Id
			end
		end
	end
end

-- Rellena los equipos con máquinas hasta `size`. names1/names2: nombres (Npc del reparto) en orden.
-- opts: { Skill1, Skill2, Keeper1, Keeper2 (nombre del que se pone de portero) }
function FootballSim.fillTeams(sim: Sim, size: number, names1: { string }?, names2: { string }?, opts: { [string]: any }?)
	local o = opts or {}
	local counter = 0
	for team = 1, 2 do
		local names = (if team == 1 then names1 else names2) or {}
		local have = 0
		for _, id in sim.Order do
			if sim.Players[id].Team == team then
				have += 1
			end
		end
		local keeperName = if team == 1 then o.Keeper1 else o.Keeper2
		for _, id in sim.Order do
			local q = sim.Players[id]
			if q.Team == team and q.Role == "GK" then
				keeperName = nil -- (ya hay portero: una persona que lo ha elegido)
			end
		end
		local i = 0
		while have < size do
			i += 1
			counter += 1
			local name = names[i]
			local role = if keeperName and name == keeperName then "GK" else "MF"
			FootballSim.addPlayer(sim, {
				Id = ("bot%d_%d"):format(team, counter),
				Name = name or (if team == 1 then "Compañero" else "Rival"),
				Npc = name,
				Team = team,
				Role = role,
				Skill = (if role == "GK" then (if team == 1 then o.KeeperSkill1 else o.KeeperSkill2) else nil) or (if team == 1 then o.Skill1 else o.Skill2) or 0.5,
			})
			have += 1
		end
	end
	FootballSim.arrange(sim)
end

-- La posición de una persona (pies, en local), su velocidad y hacia dónde mira (lo manda el servidor)
function FootballSim.setHuman(sim: Sim, id: string, p: Vector3, v: Vector3?, facing: Vector3?)
	local player = sim.Players[id]
	if not player then
		return
	end
	local vel = flat(v or Vector3.zero)
	if sim.Owner == id then
		player.Run += flat(p - player.P).Magnitude
	end
	player.P = Vector3.new(p.X, 0, p.Z)
	player.V = vel
	if facing and flat(facing).Magnitude > 0.1 then
		player.Facing = flat(facing).Unit
	elseif vel.Magnitude > 1 then
		player.Facing = vel.Unit
	end
end

-- Teletransporte (saques, penaltis…): se mueve y se avisa al servidor para las personas
local function teleport(sim: Sim, p: Player, at: Vector3, facing: Vector3?)
	p.P = Vector3.new(at.X, 0, at.Z)
	p.V = Vector3.zero
	if facing then
		p.Facing = Pitch.unitFlat(facing, p.Facing)
	end
	p.Dive = nil
	p.Slide = 0
	if p.Human then
		event(sim, "Teleport", { Id = p.Id, P = p.P, Facing = p.Facing })
	end
end

---------------------------------------------------------------------
-- Cuerpos (para los choques del balón)
---------------------------------------------------------------------

function FootballSim.bodies(sim: Sim): { Ball.Body }
	local list = {}
	for _, id in sim.Order do
		if id == sim.Owner then
			continue
		end
		local p = sim.Players[id]
		local s = p.Scale or 1
		if p.Dive and sim.T >= p.Dive.Start and sim.T <= p.Dive.Start + p.Dive.Dur + 0.5 then
			local a, b, r = AI.diveBody(p, sim.T)
			if a and b then
				table.insert(list, { Id = id, A = a, B = b, R = r, Save = true })
				continue
			end
		end
		if sim.T < p.Slide then
			local a = p.P + Vector3.new(0, 0.6 * s, 0)
			table.insert(list, { Id = id, A = a, B = a + p.SlideDir * 2.6 * s, R = 0.8 * s })
		else
			table.insert(list, { Id = id, A = p.P + Vector3.new(0, 0.9 * s, 0), B = p.P + Vector3.new(0, 4.1 * s, 0), R = 0.8 * s, Save = p.Role == "GK" })
		end
	end
	return list
end

---------------------------------------------------------------------
-- Golpeos
---------------------------------------------------------------------

local function release(sim: Sim, p: Player, from: Vector3?)
	local ball = sim.Ball
	if from then
		ball.P = Vector3.new(from.X, math.max(from.Y, Ball.Config.Radius), from.Z)
	end
	sim.Owner = nil
	sim.LastTouch = p.Id
	ball.InGoal = 0
	ball.Ignore = p.Id
	ball.IgnoreUntil = ball.T + 0.3
	p.KickCd = sim.T + 0.35
	sim.KickSeq += 1
	sim.Path = nil
end

-- Golpea el balón. cmd: { Kind = "Shoot" | "Pass" | "Lob", Dir (local, plano), Power (0..1),
-- Curl (-1..1), Loft (0..1), Dist (pases), To (id del compañero), BallP (dónde lo ve quien chuta) }
-- Devuelve true si vale (lleva el balón o lo tiene a mano).
function FootballSim.kick(sim: Sim, id: string, cmd: { [string]: any }): (boolean, string?)
	local p = sim.Players[id]
	if not p then
		return false, "NoPlayer"
	end
	if sim.Phase == "Goal" or sim.Phase == "Over" or sim.Phase == "PenResult" or sim.Phase == "Idle" then
		return false, "Phase"
	end
	if sim.T < p.KickCd or sim.T < p.Stun then
		return false, "Cooldown"
	end
	local ball = sim.Ball
	local own = sim.Owner == id
	if not own then
		if sim.Owner ~= nil then
			return false, "NotYours"
		end
		if sim.Exclusive and sim.Exclusive.Team ~= p.Team and sim.T < sim.Exclusive.Until then
			return false, "Exclusive"
		end
		local reach = CFG.KickReach * (p.Scale or 1) + (if p.Human then CFG.HumanReach + 1 else 0)
		if AI.flatDistance(p.P, ball.P) > reach or ball.P.Y > 3.6 * (p.Scale or 1) then
			return false, "Far"
		end
	end
	local dir = typeof(cmd.Dir) == "Vector3" and flat(cmd.Dir) or p.Facing
	if dir.Magnitude < 1e-3 then
		dir = p.Facing
	end
	dir = dir.Unit
	-- Dónde está el balón al golpearlo: el que ve quien chuta, si es razonable (sin saltos raros)
	local from: Vector3? = nil
	if typeof(cmd.BallP) == "Vector3" and (cmd.BallP - ball.P).Magnitude < 5 and AI.flatDistance(cmd.BallP, p.P) < 5 then
		from = cmd.BallP
	end
	local kind = cmd.Kind
	local power = math.clamp(tonumber(cmd.Power) or 0.6, 0, 1)
	if power ~= power then
		power = 0.6
	end
	release(sim, p, from)
	if kind == "Pass" or kind == "Lob" then
		local dist = math.clamp(tonumber(cmd.Dist) or 15, 2, 70)
		if dist ~= dist then
			dist = 15
		end
		ball.V = Ball.passVelocity(dir, dist, kind == "Lob")
		ball.Spin = 0
		if typeof(cmd.To) == "string" and sim.Players[cmd.To] then
			sim.PassTo = cmd.To
			sim.PassToUntil = sim.T + 2.5
		end
	else
		local curl = math.clamp(tonumber(cmd.Curl) or 0, -1, 1)
		local loft = math.clamp(tonumber(cmd.Loft) or 0, 0, 1)
		if curl ~= curl then
			curl = 0
		end
		if loft ~= loft then
			loft = 0
		end
		ball.V, ball.Spin = Ball.shotVelocity(dir, power, loft, curl)
		kind = "Shoot"
	end
	-- Un golpe con velocidad heredada (corriendo) va un poco más fuerte
	ball.V += flat(p.V) * 0.25
	event(sim, "Kick", { Id = id, Type = kind, Power = power, Seq = sim.KickSeq, P = ball.P, V = ball.V, Spin = ball.Spin })
	-- Penaltis y pases: el golpe empieza la jugada
	if sim.Phase == "PenSetup" then
		sim.Phase = "PenFlight"
		sim.PhaseUntil = sim.T + CFG.PenFlight
		local keeper = sim.Keepers[1] and sim.Players[sim.Keepers[1]]
		if keeper and not keeper.Human then
			keeper.Dive = AI.keeperDive(sim, keeper, sim.Rng, true)
			keeper.DiveSeq = sim.KickSeq
		end
	elseif sim.Phase == "PassReady" then
		sim.Phase = "PassFlight"
		sim.PhaseUntil = sim.T + CFG.PassFlight
	end
	return true
end

-- Entrada (o estirada si eres portero): dir local plano
function FootballSim.tackle(sim: Sim, id: string, dir: Vector3?, noDive: boolean?): (boolean, string?)
	local p = sim.Players[id]
	if not p or sim.T < p.TackleCd or sim.T < p.Stun then
		return false, "Cooldown"
	end
	if sim.Phase == "Over" or sim.Phase == "Idle" then
		return false, "Phase"
	end
	local d = if dir and flat(dir).Magnitude > 1e-3 then flat(dir).Unit else p.Facing
	p.TackleCd = sim.T + 1
	p.Facing = d
	if p.Role == "GK" and p.Human and not noDive then
		-- Estirada del portero (persona): hacia donde apunta, a media altura
		local s = p.Scale or 1
		p.Dive = { Start = sim.T, Dur = 0.35, From = p.P, Target = p.P + d * 4.5 * s + Vector3.new(0, 1.6 * s, 0), Seq = sim.KickSeq }
		event(sim, "Dive", { Id = id })
		return true
	end
	p.Slide = sim.T + 0.5
	p.SlideDir = d
	event(sim, "Slide", { Id = id })
	-- ¿Hay alguien con el balón delante?
	local owner = sim.Owner and sim.Players[sim.Owner]
	local reach = CFG.TackleReach * (p.Scale or 1) + (if p.Human then CFG.HumanReach else 0)
	if owner and owner.Team ~= p.Team then
		local to = flat(owner.P - p.P)
		if to.Magnitude < reach and (to.Magnitude < 1.2 or to.Unit:Dot(d) > 0.2) then
			local chance = if p.Human then 0.68 else (0.3 + 0.35 * p.Skill - (if owner.Human then 0.12 else 0.2 * owner.Skill))
			if sim.Rng:NextNumber() < chance then
				release(sim, p, nil)
				sim.Ball.V = d * 11 + Vector3.new(0, 1.5, 0) + flat(owner.V) * 0.3
				owner.KickCd = sim.T + 0.7
				if not owner.Human then
					owner.Stun = sim.T + 0.6
				end
				event(sim, "Tackle", { Id = id, Victim = owner.Id, Ok = true })
				return true
			end
			event(sim, "Tackle", { Id = id, Victim = owner.Id, Ok = false })
			if not p.Human then
				p.Stun = sim.T + 0.9
			end
			return true
		end
	elseif not sim.Owner then
		-- Balón suelto a mano: lo toca hacia delante
		if AI.flatDistance(p.P, sim.Ball.P) < reach and sim.Ball.P.Y < 2 then
			release(sim, p, nil)
			sim.Ball.V = d * 18 + Vector3.new(0, 2, 0)
			event(sim, "Kick", { Id = id, Type = "Poke", Power = 0.3, Seq = sim.KickSeq, P = sim.Ball.P, V = sim.Ball.V, Spin = 0 })
		end
	end
	return true
end

---------------------------------------------------------------------
-- Fases y reanudaciones
---------------------------------------------------------------------

local function setPhase(sim: Sim, phase: string, seconds: number?)
	sim.Phase = phase
	sim.PhaseUntil = sim.T + (seconds or 0)
end

local function giveBall(sim: Sim, p: Player)
	sim.Owner = p.Id
	sim.LastTouch = p.Id
	sim.Ball.InGoal = 0
	sim.Ball.V = Vector3.zero
	sim.Ball.Spin = 0
	p.Run = 0
	sim.Ball.P = Ball.carryPosition(p.P, p.Facing, 0, 0)
end

-- Saque de centro para `team`: todos a su campo, balón al centro
local function kickoff(sim: Sim, team: number)
	local pitch = sim.Pitch
	local taker: Player? = nil
	for _, id in sim.Order do
		local p = sim.Players[id]
		local at = if p.Role == "GK" then Vector3.new(-AI.attack(p.Team) * (pitch.GoalLine - 1), 0, 0) else AI.kickoffPosition(pitch, p.Team, p.Slot)
		teleport(sim, p, at, Vector3.new(AI.attack(p.Team), 0, 0))
		p.Stun = 0
		if p.Team == team and p.Role ~= "GK" then
			-- El que saca: el más adelantado (y si eres tú, tú)
			if not taker or p.Human or (not taker.Human and p.Slot[2] > taker.Slot[2]) then
				taker = p
			end
		end
	end
	Ball.place(sim.Ball, Vector3.zero)
	sim.Owner = nil
	if taker then
		teleport(sim, taker, Vector3.new(-AI.attack(team) * 1.8, 0, 0), Vector3.new(AI.attack(team), 0, 0))
		giveBall(sim, taker)
	end
	sim.Exclusive = { Team = team, Until = sim.T + CFG.KickoffPause + 2 }
	setPhase(sim, "Kickoff", CFG.KickoffPause)
	event(sim, "Kickoff", { Team = team })
end

-- Reanudación tras una salida (banda, puerta o córner) para `team`
local function restart(sim: Sim, kind: string, team: number, spot: Vector3)
	Ball.place(sim.Ball, spot)
	sim.Owner = nil
	-- Quién saca: la máquina de ese equipo más cercana (o tú si estás cerca o no hay máquinas)
	local taker: Player? = nil
	local bestD = math.huge
	for _, id in sim.Order do
		local p = sim.Players[id]
		if p.Team ~= team then
			continue
		end
		local d = AI.flatDistance(p.P, spot)
		if kind == "GoalKick" and p.Role == "GK" and not p.Human then
			d = -1
		elseif p.Human then
			d = if d < 14 then -2 else d + 1000
		elseif p.Role == "GK" then
			d += 60
		end
		if d < bestD then
			taker, bestD = p, d
		end
	end
	if taker and not taker.Human then
		local back = Pitch.unitFlat(Vector3.new(0, 0, 0) - spot, Vector3.new(AI.attack(team), 0, 0))
		taker.P = Vector3.new(spot.X, 0, spot.Z) - back * 1.8
		taker.Facing = back
		taker.V = Vector3.zero
		giveBall(sim, taker)
		taker.HoldUntil = sim.T + 0.6
	end
	-- Los rivales no pueden tocarlo hasta que se saque
	sim.Exclusive = { Team = team, Until = sim.T + 4 }
	setPhase(sim, "Restart", CFG.RestartPause)
	event(sim, "Restart", { Type = kind, Team = team, P = spot })
end

-- Penaltis: prepara el siguiente tiro
local function setupPenalty(sim: Sim)
	local pitch = sim.Pitch
	sim.Round += 1
	local spot = Pitch.penaltySpot(pitch, 1)
	Ball.place(sim.Ball, spot)
	sim.Owner = nil
	for _, id in sim.Order do
		local p = sim.Players[id]
		if p.Team == 1 then
			teleport(sim, p, spot - Vector3.new(3.2 * (p.Scale or 1), 0, 0), Vector3.new(1, 0, 0))
		elseif p.Role == "GK" then
			teleport(sim, p, Vector3.new(pitch.GoalLine - 0.6, 0, 0), Vector3.new(-1, 0, 0))
			p.Dive = nil
		end
	end
	setPhase(sim, "PenSetup", CFG.PenTimeout)
	event(sim, "PenSetup", { Round = sim.Round, Rounds = sim.Rounds, Hits = sim.Hits })
end

-- Pases: el compañero a un sitio nuevo y el balón a tus pies
local function setupPass(sim: Sim)
	local pitch = sim.Pitch
	sim.Round += 1
	local human: Player? = nil
	for _, id in sim.Order do
		if sim.Players[id].Human then
			human = sim.Players[id]
		end
	end
	local receiver = sim.Receiver and sim.Players[sim.Receiver]
	if not human or not receiver then
		return
	end
	-- Un sitio delante de ti, cada vez distinto (y dentro del campo)
	local angle = (sim.Rng:NextNumber() * 2 - 1) * math.rad(55)
	local d = 13 + sim.Rng:NextNumber() * 9
	local base = Vector3.new(1, 0, 0)
	local dir = Vector3.new(base.X * math.cos(angle), 0, math.sin(angle))
	local spot = Pitch.clampInside(pitch, human.P + dir * d, 4)
	receiver.P = spot
	receiver.V = Vector3.zero
	receiver.Facing = Pitch.unitFlat(human.P - spot)
	receiver.Target = spot
	receiver.RunTo = nil
	if sim.Variant == "Hueco" then
		-- Al hueco: echa a correr hacia delante (hay que pasar al espacio, no a los pies)
		local run = Pitch.unitFlat(Vector3.new(1, 0, (sim.Rng:NextNumber() * 2 - 1) * 0.8))
		receiver.RunTo = Pitch.clampInside(pitch, spot + run * 11, 3)
	end
	event(sim, "Teleport", { Id = receiver.Id, P = receiver.P, Facing = receiver.Facing, Bot = true })
	giveBall(sim, human)
	setPhase(sim, "PassReady", CFG.PassTimeout)
	event(sim, "PassSetup", { Round = sim.Round, Rounds = sim.Rounds, Hits = sim.Hits })
end

local function finish(sim: Sim)
	if sim.Over then
		return
	end
	sim.Over = true
	setPhase(sim, "Over", 0)
	event(sim, "Over", FootballSim.outcome(sim))
end

-- Penaltis / pases: apunta el resultado de la ronda y sigue (o acaba)
local function roundResult(sim: Sim, ok: boolean, reason: string)
	sim.Taken += 1
	if ok then
		sim.Hits += 1
	end
	local kind = if sim.Mode == "Penaltis" then "PenResult" else "PassResult"
	event(sim, kind, { Ok = ok, Reason = reason, Round = sim.Round, Hits = sim.Hits, Taken = sim.Taken, Rounds = sim.Rounds })
	setPhase(sim, if sim.Mode == "Penaltis" then "PenResult" else "PassResult", CFG.PenResultPause)
end

local function roundsDecided(sim: Sim): boolean
	if sim.Taken >= sim.Rounds then
		return true
	end
	if sim.StopWhenDecided and sim.Need > 0 then
		return sim.Hits >= sim.Need or sim.Hits + (sim.Rounds - sim.Taken) < sim.Need
	end
	return false
end

function FootballSim.start(sim: Sim)
	sim.Over = false
	if sim.Mode == "Partido" then
		FootballSim.arrange(sim)
		kickoff(sim, 1)
	elseif sim.Mode == "Penaltis" then
		for _, id in sim.Order do
			local p = sim.Players[id]
			if p.Team == 2 then
				p.Role = "GK"
				sim.Keepers[1] = id
			end
		end
		setupPenalty(sim)
	elseif sim.Mode == "Pases" then
		setupPass(sim)
	else
		-- Libre: porteros en su sitio y el balón al centro
		for _, id in sim.Order do
			local p = sim.Players[id]
			if p.Role == "GK" then
				local side = -AI.attack(p.Team)
				sim.Keepers[side] = id
				teleport(sim, p, Vector3.new(side * (sim.Pitch.GoalLine - 1), 0, 0), Vector3.new(-side, 0, 0))
			end
		end
		Ball.place(sim.Ball, Vector3.zero)
		setPhase(sim, "Play", 0)
	end
end

-- Resultado: { Goals, Against, Hits, Taken, Rounds, Over }
function FootballSim.outcome(sim: Sim): { [string]: any }
	return {
		Mode = sim.Mode,
		Goals = sim.Score[1],
		Against = sim.Score[2],
		Hits = sim.Hits,
		Taken = sim.Taken,
		Rounds = sim.Rounds,
		Over = sim.Over,
	}
end

---------------------------------------------------------------------
-- Máquinas: moverse
---------------------------------------------------------------------

local function moveBot(sim: Sim, p: Player, dt: number)
	local target = p.Target or p.P
	local to = flat(target - p.P)
	local d = to.Magnitude
	local frozen = sim.T < p.Stun or sim.T < p.HoldUntil or sim.Phase == "Kickoff" or sim.Phase == "Over" or sim.Phase == "PenSetup" or sim.Phase == "PenResult"
	local want = Vector3.zero
	if not frozen and d > 0.3 then
		local speed = math.min(p.MaxSpeed * (if p.Sprint then 1.12 else 1), d * 3.2)
		if sim.Owner == p.Id then
			speed *= 0.86 -- con el balón, algo más lento
		end
		want = to / d * speed
	end
	-- No apilarse: se apartan un poco de los demás
	for _, id in sim.Order do
		local q = sim.Players[id]
		if q ~= p then
			local away = flat(p.P - q.P)
			local m = away.Magnitude
			if m < 2.2 and m > 1e-3 then
				want += away / m * (2.2 - m) * 5
			end
		end
	end
	local dv = want - p.V
	local maxDv = CFG.Accel * dt
	if dv.Magnitude > maxDv then
		dv = dv.Unit * maxDv
	end
	p.V = flat(p.V + dv)
	local before = p.P
	p.P = p.P + p.V * dt
	-- Dentro del recinto
	local pitch = sim.Pitch
	p.P = Vector3.new(math.clamp(p.P.X, -pitch.BoardX + 1, pitch.BoardX - 1), 0, math.clamp(p.P.Z, -pitch.BoardZ + 1, pitch.BoardZ - 1))
	if sim.Owner == p.Id then
		p.Run += flat(p.P - before).Magnitude
	end
	-- Mira hacia donde va (o al balón si está casi quieto)
	if p.V.Magnitude > 1.5 then
		p.Facing = p.V.Unit
	elseif sim.Owner ~= p.Id then
		local toBall = flat(sim.Ball.P - p.P)
		if toBall.Magnitude > 0.5 then
			p.Facing = (p.Facing + toBall.Unit * math.min(1, dt * 6)).Unit
		end
	end
end

---------------------------------------------------------------------
-- Máquinas: pensar
---------------------------------------------------------------------

local function doAction(sim: Sim, p: Player, action: { [string]: any })
	if action.Kind == "Shoot" then
		FootballSim.kick(sim, p.Id, { Kind = "Shoot", Dir = action.Dir, Power = action.Power, Curl = action.Curl, Loft = action.Loft })
	elseif action.Kind == "Pass" then
		FootballSim.kick(sim, p.Id, { Kind = "Pass", Dir = action.Dir, Dist = action.Dist, To = action.To })
	elseif action.Kind == "Dribble" then
		p.Target = action.Target
	end
end

local function thinkKeeper(sim: Sim, p: Player)
	local side = -AI.attack(p.Team)
	local ball = sim.Ball
	-- Con el balón en las manos: espera un poco y lo saca
	if sim.Owner == p.Id then
		if sim.T >= p.HoldUntil then
			if sim.Mode == "Libre" then
				-- (en juego libre se lo devuelve a la persona más cercana)
				local best, bestD = nil, math.huge
				for _, id in sim.Order do
					local q = sim.Players[id]
					if q.Human then
						local d = AI.flatDistance(q.P, p.P)
						if d < bestD then
							best, bestD = q, d
						end
					end
				end
				if best then
					FootballSim.kick(sim, p.Id, { Kind = if bestD > 40 then "Lob" else "Pass", Dir = flat(best.P - p.P), Dist = bestD })
				else
					FootballSim.kick(sim, p.Id, { Kind = "Pass", Dir = Vector3.new(-side, 0, 0), Dist = 20 })
				end
			else
				doAction(sim, p, AI.carrierDecision(sim, p, sim.Rng))
			end
		end
		p.Target = p.P
		return
	end
	-- Tiro hacia su portería: estirada (una vez por golpeo)
	if not sim.Owner and p.DiveSeq ~= sim.KickSeq and sim.Mode ~= "Penaltis" then
		local plan = AI.keeperDive(sim, p, sim.Rng, false)
		if plan then
			p.Dive = plan
			p.DiveSeq = sim.KickSeq
		end
	end
	if p.Dive and sim.T < p.Dive.Start + p.Dive.Dur + 0.7 then
		p.Target = p.P
		return
	elseif p.Dive then
		-- Se levanta donde ha caído
		local _, hands = AI.diveBody(p, sim.T)
		if hands then
			p.P = Pitch.clampInside(sim.Pitch, Vector3.new(hands.X, 0, hands.Z), 0.5)
		end
		p.Dive = nil
	end
	if sim.Mode == "Penaltis" then
		p.Target = Vector3.new(side * (sim.Pitch.GoalLine - 0.6), 0, 0)
		return
	end
	-- Un rival se le planta delante con el balón: sale a taparle y le entra
	local owner = sim.Owner and sim.Players[sim.Owner]
	if owner and owner.Team ~= p.Team and Pitch.inArea(sim.Pitch, owner.P, side) then
		local d = AI.flatDistance(owner.P, p.P)
		if d < 7 then
			p.Target = owner.P
			p.Sprint = true
			if d < 2.6 * (p.Scale or 1) and sim.T >= p.TackleCd and sim.Rng:NextNumber() < 0.5 then
				FootballSim.tackle(sim, p.Id, flat(owner.P - p.P), true)
			end
			return
		end
	end
	-- Balón suelto y lento en su área: sale a por él
	if not sim.Owner and Pitch.inArea(sim.Pitch, ball.P, side) and ball.V.Magnitude < 28 then
		p.Target = ball.P
		p.Sprint = true
		return
	end
	p.Sprint = false
	p.Target = AI.keeperSpot(sim, p)
end

local function thinkField(sim: Sim, p: Player, chasers: { [number]: string })
	local owner = sim.Owner and sim.Players[sim.Owner]
	p.Sprint = false
	if sim.Mode == "Pases" then
		-- El compañero de los pases: quieto en su sitio (o corriendo al hueco); va a por el balón si le llega
		if sim.Owner == p.Id then
			p.Target = p.P
			return
		end
		if sim.Phase == "PassFlight" then
			local ball = sim.Ball
			local toward = flat(ball.V):Dot(flat(p.P - ball.P))
			if p.RunTo then
				p.Target = p.RunTo
				p.Sprint = true
			end
			if toward > 0 and AI.flatDistance(ball.P, p.P) < 9 then
				p.Target = AI.interceptPoint(sim, p)
			end
		else
			p.Target = p.Target or p.P
		end
		return
	end
	if sim.Owner == p.Id then
		if sim.T < p.HoldUntil then
			p.Target = p.P
			return
		end
		doAction(sim, p, AI.carrierDecision(sim, p, sim.Rng))
		return
	end
	if owner and owner.Team ~= p.Team then
		-- Defender: el más cercano presiona e intenta la entrada
		local nearest, bestD = nil, math.huge
		for _, id in sim.Order do
			local q = sim.Players[id]
			if q.Team == p.Team and not q.Human and q.Role ~= "GK" then
				local d = AI.flatDistance(q.P, owner.P)
				if d < bestD then
					nearest, bestD = q, d
				end
			end
		end
		if nearest == p and not (sim.Exclusive and sim.T < sim.Exclusive.Until and sim.Exclusive.Team ~= p.Team) then
			p.Target = owner.P + flat(owner.V) * 0.3
			p.Sprint = true
			if bestD < 2.6 * (p.Scale or 1) and sim.T >= p.TackleCd and sim.Rng:NextNumber() < 0.45 then
				FootballSim.tackle(sim, p.Id, flat(owner.P - p.P))
			end
			return
		end
		p.Target = AI.homeSpot(sim, p)
		return
	end
	if not owner and chasers[p.Team] == p.Id then
		-- Balón suelto: a por él (al pase que le llega, primero)
		p.Target = AI.interceptPoint(sim, p)
		p.Sprint = true
		return
	end
	if sim.PassTo == p.Id and sim.T < (sim.PassToUntil or 0) and not owner then
		p.Target = AI.interceptPoint(sim, p)
		return
	end
	p.Target = AI.homeSpot(sim, p)
	-- Respetar el saque del rival
	if sim.Exclusive and sim.T < sim.Exclusive.Until and sim.Exclusive.Team ~= p.Team then
		local away = flat(p.Target - sim.Ball.P)
		if away.Magnitude < 6 then
			p.Target = sim.Ball.P + (if away.Magnitude > 1e-3 then away.Unit else Vector3.new(1, 0, 0)) * 6
		end
	end
end

local function think(sim: Sim)
	-- La trayectoria del balón (para cortar pases y balones sueltos): cada 0,1 s o tras un golpeo
	if not sim.Owner then
		if not sim.Path or sim.T - sim.PathAt >= 0.1 or sim.PathSeq ~= sim.KickSeq then
			sim.Path = Ball.predict(sim.Ball, sim.Pitch, 1.6)
			sim.PathAt = sim.T
			sim.PathSeq = sim.KickSeq
		end
	else
		sim.Path = nil
	end
	local chasers = AI.chasers(sim)
	for _, id in sim.Order do
		local p = sim.Players[id]
		if p.Human or sim.T < p.NextThink then
			continue
		end
		p.NextThink = sim.T + (if p.Role == "GK" then 0.06 else CFG.Think * (0.8 + 0.4 * sim.Rng:NextNumber()))
		if sim.Phase == "Goal" then
			-- Gol: cada uno vuelve hacia su sitio (nadie va a por el balón de la red)
			p.Target = if p.Role == "GK" then AI.keeperSpot(sim, p) else AI.homeSpot(sim, p)
			p.Sprint = false
		elseif p.Role == "GK" then
			thinkKeeper(sim, p)
		else
			thinkField(sim, p, chasers)
		end
	end
end

---------------------------------------------------------------------
-- Posesión
---------------------------------------------------------------------

local function tryControl(sim: Sim)
	if sim.Owner then
		return
	end
	local ball = sim.Ball
	if ball.InGoal ~= 0 then
		return
	end
	local best, bestD = nil, math.huge
	for _, id in sim.Order do
		local p = sim.Players[id]
		if sim.T < p.KickCd or sim.T < p.Stun or (ball.Ignore == id and ball.T < ball.IgnoreUntil) then
			continue
		end
		if sim.NoCarry and p.Role ~= "GK" then
			continue
		end
		if sim.Phase == "PassFlight" and id ~= sim.Receiver then
			continue -- (el pase es para el compañero: si lo coges tú, no cuenta)
		end
		if sim.Exclusive and sim.T < sim.Exclusive.Until and sim.Exclusive.Team ~= p.Team then
			continue
		end
		local s = p.Scale or 1
		local keeper = p.Role == "GK" and Pitch.inArea(sim.Pitch, ball.P, -AI.attack(p.Team))
		local reach = (CFG.ControlRadius + Ball.Config.Radius) * s + (if p.Human then CFG.HumanReach else 0) + (if keeper then 0.8 else 0)
		local high = if keeper then sim.Pitch.GoalHeight else 2.3 * s
		local d = AI.flatDistance(p.P, ball.P)
		if d > reach or ball.P.Y > high then
			continue
		end
		local rel = flat(ball.V - p.V).Magnitude
		local control = if p.Human then 46 elseif keeper then 30 + 25 * p.Skill else 24 + 18 * p.Skill
		if rel > control then
			continue
		end
		if d < bestD then
			best, bestD = p, d
		end
	end
	if best then
		local fromPass = sim.LastTouch
		giveBall(sim, best)
		sim.Exclusive = nil
		if best.Role == "GK" and not best.Human then
			best.HoldUntil = sim.T + 0.9
		end
		event(sim, "Control", { Id = best.Id, From = fromPass })
		sim.PassTo = nil
	end
end

---------------------------------------------------------------------
-- Paso
---------------------------------------------------------------------

local function scoringTeam(side: number): number
	return if side > 0 then 1 else 2
end

local function onGoal(sim: Sim, side: number)
	if sim.Mode == "Penaltis" then
		if sim.Phase == "PenFlight" then
			roundResult(sim, true, "Goal")
		end
		return
	end
	if sim.Mode == "Pases" then
		return
	end
	local team = scoringTeam(side)
	sim.Score[team] += 1
	local scorer = sim.LastTouch and sim.Players[sim.LastTouch]
	event(sim, "Goal", {
		Team = team,
		Side = side,
		Scorer = sim.LastTouch,
		OwnGoal = scorer ~= nil and scorer.Team ~= team,
		Carried = sim.CarriedGoal == true,
		Score = { sim.Score[1], sim.Score[2] },
	})
	sim.Owner = nil
	setPhase(sim, "Goal", CFG.GoalPause)
	sim.GoalAgainst = 3 - team
end

local function checkOut(sim: Sim, dt: number)
	local ball = sim.Ball
	local exit = if ball.InGoal == 0 then Pitch.exit(sim.Pitch, ball.P) else nil
	if not exit then
		sim.OutsideSince = nil
		return
	end
	if sim.Mode == "Libre" then
		-- Sin reglas: si se queda fuera un momento, vuelve a la línea
		sim.OutsideSince = sim.OutsideSince or sim.T
		if sim.T - sim.OutsideSince > CFG.OutsideReset and not sim.Owner then
			Ball.place(ball, Pitch.clampInside(sim.Pitch, ball.P, 1.5))
			sim.OutsideSince = nil
			event(sim, "Reset", {})
		end
		return
	end
	if sim.Mode ~= "Partido" or (sim.Phase ~= "Play" and sim.Phase ~= "Restart") then
		return
	end
	local last = sim.LastTouch and sim.Players[sim.LastTouch]
	local lastTeam = if last then last.Team else 1
	local other = 3 - lastTeam
	sim.Owner = nil
	if exit == "Side" then
		restart(sim, "Side", other, Pitch.restartSpot(sim.Pitch, "Side", ball.P))
	else
		local side = if ball.P.X >= 0 then 1 else -1
		-- La portería de ese lado la defiende el equipo que ataca hacia el otro lado
		local defending = if side > 0 then 2 else 1
		if lastTeam == defending then
			restart(sim, "Corner", 3 - defending, Pitch.restartSpot(sim.Pitch, "Corner", ball.P, side))
		else
			restart(sim, "GoalKick", defending, Pitch.restartSpot(sim.Pitch, "GoalKick", ball.P, side))
		end
	end
	event(sim, "Out", { Type = exit })
end

local function updatePhase(sim: Sim)
	local phase = sim.Phase
	if phase == "Goal" and sim.T >= sim.PhaseUntil then
		if sim.Mode == "Partido" then
			if sim.Clock >= sim.Duration then
				finish(sim)
			else
				kickoff(sim, sim.GoalAgainst or 1)
			end
		else
			Ball.place(sim.Ball, Vector3.zero)
			sim.Owner = nil
			setPhase(sim, "Play", 0)
		end
	elseif (phase == "Kickoff" or phase == "Restart") and sim.T >= sim.PhaseUntil then
		setPhase(sim, "Play", 0)
	elseif phase == "PenSetup" and sim.T >= sim.PhaseUntil then
		roundResult(sim, false, "Timeout")
	elseif phase == "PenFlight" then
		local ball = sim.Ball
		local keeper = sim.Keepers[1]
		if sim.Owner and sim.Owner == keeper then
			roundResult(sim, false, "Save")
		elseif sim.T >= sim.PhaseUntil or (Ball.resting(ball) and sim.T > sim.PhaseUntil - CFG.PenFlight + 0.6) or (ball.P.X < Pitch.penaltySpot(sim.Pitch, 1).X - 6) then
			roundResult(sim, false, sim.PenMissReason or "Miss")
		end
	elseif phase == "PenResult" and sim.T >= sim.PhaseUntil then
		if roundsDecided(sim) then
			finish(sim)
		else
			sim.PenMissReason = nil
			setupPenalty(sim)
		end
	elseif phase == "PassReady" and sim.T >= sim.PhaseUntil then
		roundResult(sim, false, "Timeout")
	elseif phase == "PassFlight" then
		if sim.Owner and sim.Owner == sim.Receiver then
			roundResult(sim, true, "Pass")
		elseif sim.Owner or sim.T >= sim.PhaseUntil or (Ball.resting(sim.Ball) and sim.T > sim.PhaseUntil - CFG.PassFlight + 0.8) then
			roundResult(sim, false, "Miss")
		end
	elseif phase == "PassResult" then
		-- El compañero te la devuelve (si la tiene) y otra ronda
		if sim.T >= sim.PhaseUntil then
			if roundsDecided(sim) then
				finish(sim)
			else
				setupPass(sim)
			end
		elseif sim.Owner and sim.Owner == sim.Receiver and sim.T >= sim.PhaseUntil - 1.1 then
			local receiver = sim.Players[sim.Receiver]
			for _, id in sim.Order do
				local h = sim.Players[id]
				if h.Human then
					local d = AI.flatDistance(h.P, receiver.P)
					FootballSim.kick(sim, receiver.Id, { Kind = "Pass", Dir = flat(h.P - receiver.P), Dist = d })
				end
			end
		end
	end
	-- Final del partido (cuando el balón está en juego o parado por una salida)
	if sim.Mode == "Partido" and (sim.Phase == "Play" or sim.Phase == "Restart") and sim.Clock >= sim.Duration then
		finish(sim)
	end
end

local function tick(sim: Sim, dt: number)
	sim.T += dt
	if sim.Phase == "Idle" then
		return
	end
	if sim.Mode == "Partido" and (sim.Phase == "Play" or sim.Phase == "Restart") then
		sim.Clock += dt
	end
	-- Máquinas
	if sim.Phase ~= "Over" then
		think(sim)
	end
	for _, id in sim.Order do
		local p = sim.Players[id]
		if not p.Human then
			moveBot(sim, p, dt)
		end
	end
	-- Balón
	local ball = sim.Ball
	if sim.Owner then
		local o = sim.Players[sim.Owner]
		local before = ball.P
		ball.P = Ball.carryPosition(o.P, o.Facing, flat(o.V).Magnitude, o.Run)
		ball.V = flat(o.V)
		ball.T += dt
		-- Entrar conduciendo en la portería también es gol
		for _, side in { -1, 1 } do
			local line = sim.Pitch.GoalLine + Ball.Config.Radius
			if before.X * side < line and ball.P.X * side >= line and math.abs(ball.P.Z) < sim.Pitch.GoalWidth / 2 then
				ball.InGoal = side
				sim.Owner = nil
				sim.CarriedGoal = true
				onGoal(sim, side)
				sim.CarriedGoal = nil
			end
		end
	elseif sim.Phase ~= "PenSetup" then
		local evs = Ball.step(ball, dt, sim.Pitch, FootballSim.bodies(sim))
		for _, e in evs do
			if e.Kind == "Goal" then
				onGoal(sim, e.Side :: number)
			elseif e.Kind == "Post" or e.Kind == "Bar" then
				event(sim, "Post", { Type = e.Kind, Speed = e.Speed })
				sim.PenMissReason = "Post"
			elseif e.Kind == "Block" then
				local who = e.Id and sim.Players[e.Id]
				if who then
					sim.LastTouch = who.Id
					if who.Role == "GK" and (e.Speed or 0) > 18 then
						event(sim, "Save", { Id = who.Id, Speed = e.Speed })
						sim.PenMissReason = "Save"
						-- La despeja: hacia fuera de la portería y hacia el lado (a córner, muchas veces)
						local side = -AI.attack(who.Team)
						local v = ball.V
						local out = if math.abs(ball.P.Z - who.P.Z) > 0.3 then math.sign(ball.P.Z - who.P.Z) else (if sim.Rng:NextNumber() < 0.5 then -1 else 1)
						ball.V = Vector3.new(-side * math.abs(v.X) * 0.3, math.max(v.Y, 0) * 0.3 + 4, out * (math.abs(v.Z) * 0.6 + 7))
						-- Atrapa los que llegan flojos
						if not who.Human and ball.V.Magnitude < 16 and sim.Rng:NextNumber() < 0.3 + 0.5 * who.Skill and sim.Mode ~= "Penaltis" then
							giveBall(sim, who)
							who.HoldUntil = sim.T + 1
						end
					elseif (e.Speed or 0) > 12 then
						event(sim, "Block", { Id = who.Id, Speed = e.Speed })
					end
				end
			end
		end
	end
	if sim.Phase ~= "Goal" and sim.Phase ~= "Over" and sim.Phase ~= "PenSetup" and sim.Phase ~= "PenResult" and sim.Phase ~= "PassResult" then
		tryControl(sim)
	elseif sim.Phase == "PassResult" then
		tryControl(sim)
	end
	checkOut(sim, dt)
	updatePhase(sim)
end

-- Avanza dt segundos (con paso fijo)
function FootballSim.step(sim: Sim, dt: number): { { [string]: any } }
	sim.Accumulator += math.clamp(dt, 0, 0.25)
	while sim.Accumulator >= CFG.Tick do
		sim.Accumulator -= CFG.Tick
		tick(sim, CFG.Tick)
	end
	local out = sim.Events
	sim.Events = {}
	return out
end

-- Quién de las personas juega en qué equipo y qué hay que hacer ahora (para la interfaz)
function FootballSim.status(sim: Sim): { [string]: any }
	return {
		Mode = sim.Mode,
		Phase = sim.Phase,
		Clock = sim.Clock,
		Duration = sim.Duration,
		Score = { sim.Score[1], sim.Score[2] },
		Round = sim.Round,
		Rounds = sim.Rounds,
		Hits = sim.Hits,
		Taken = sim.Taken,
		Need = sim.Need,
		Owner = sim.Owner,
	}
end

return FootballSim
