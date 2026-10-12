-- BasketSim (compartido): baloncesto de verdad sin nada de Roblox (como Sports/FootballSim). El servidor
-- (BasketService) lo hace avanzar con las personas y sus lanzamientos; aquí se mueven el balón
-- (Sports/Hoops), las máquinas y las reglas. Se prueba en scripts/test-baloncesto.luau.
--
-- Modos:
--   Libre    tú y las canastas: botar, tirar, entrar a canasta
--   Tiros    una tanda de tiros (Rounds) desde la línea de tiros libres o desde sitios distintos
--            (Spots = "Libres" | "Variado"); Need canastas para ganar
--   Partido  N contra N con reloj (pista entera: cada equipo ataca una canasta; media pista: los
--            dos la misma); canastas de 2 y de 3, rebotes, robos, tapones, saque tras canasta y de banda
--
-- Lanzar: { Kind = "Shot", Quality = 0..1 (lo bien que soltaste: el medidor del botón), Seed } — el
-- error del tiro sale de Random.new(Seed), así el cliente puede ver su tiro igual que el servidor.
-- Cerca del aro y corriendo hacia él, el tiro es una bandeja (más fácil). { Kind = "Pass", To, Dir }.

local Court = require(script.Parent.Court)
local Hoops = require(script.Parent.Hoops)

local BasketSim = {}

export type Sim = { [string]: any }

BasketSim.Config = {
	Tick = 1 / 30,
	Think = 0.25,
	Accel = 50,
	BotSpeed = 15,
	ControlRadius = 1.7,
	HumanReach = 0.9,
	ReleaseHeight = 4.6, -- altura de la mano al soltar (adulto)
	LayupDistance = 7,
	StealReach = 3.2,
	RoundPause = 1.6,
	ShotFlight = 3.2,
	ShotTimeout = 25, -- sin tirar en este tiempo, el tiro cuenta como fallado
	BasketPause = 1.4,
	RestartPause = 0.9,
	PassSpeed = 38,
}
local CFG = BasketSim.Config

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end
local function fdist(a: Vector3, b: Vector3): number
	return flat(a - b).Magnitude
end

local function event(sim: Sim, kind: string, data: { [string]: any }?)
	local e = data or {}
	e.Kind = kind
	e.T = sim.T
	table.insert(sim.Events, e)
	return e
end

function BasketSim.new(court: Court.Court, opts: { [string]: any }?): Sim
	local o = opts or {}
	return {
		Court = court,
		Mode = o.Mode or "Libre",
		Duration = o.Duration or 180,
		Rounds = o.Rounds or 5,
		Need = o.Need or 0,
		Spots = o.Spots or "Libres",
		StopWhenDecided = o.StopWhenDecided ~= false,
		Scale = o.Scale or 1,
		BotSpeed = o.BotSpeed or CFG.BotSpeed,
		Rng = o.Rng or Random.new(o.Seed or 1),
		T = 0,
		Clock = 0,
		Phase = "Idle",
		PhaseUntil = 0,
		Score = { [1] = 0, [2] = 0 },
		Players = {},
		Order = {},
		Ball = Hoops.new(Vector3.new(0, Hoops.Config.Radius, 0)),
		Owner = nil :: string?,
		LastTouch = nil :: string?,
		Shot = nil :: { [string]: any }?,
		KickSeq = 0,
		Events = {},
		Exclusive = nil,
		Taken = 0,
		Hits = 0,
		Round = 0,
		Over = false,
		Accumulator = 0,
	}
end

-- La canasta a la que ataca un equipo (media pista: siempre la +1)
function BasketSim.targetHoop(sim: Sim, team: number): Court.Hoop?
	local hoops = sim.Court.Hoops
	if sim.Court.Half or sim.Mode ~= "Partido" then
		return hoops[1] or hoops[-1]
	end
	return hoops[if team == 2 then -1 else 1]
end

function BasketSim.addPlayer(sim: Sim, spec: { [string]: any })
	local p = {
		Id = spec.Id,
		Name = spec.Name or spec.Id,
		Npc = spec.Npc,
		Team = spec.Team or 1,
		Human = spec.Human == true,
		Skill = math.clamp(spec.Skill or 0.5, 0, 1),
		Scale = spec.Scale or sim.Scale,
		P = spec.P or Vector3.zero,
		V = Vector3.zero,
		Facing = Vector3.new(1, 0, 0),
		MaxSpeed = sim.BotSpeed * (0.9 + 0.2 * (spec.Skill or 0.5)),
		Stun = 0,
		KickCd = 0,
		StealCd = 0,
		NextThink = 0,
		Target = nil,
		Run = 0,
		HoldUntil = 0,
		Jump = 0, -- hasta cuándo está en el aire (tapón o tiro)
		Index = 0,
	}
	sim.Players[p.Id] = p
	table.insert(sim.Order, p.Id)
	return p
end

function BasketSim.removePlayer(sim: Sim, id: string)
	sim.Players[id] = nil
	local i = table.find(sim.Order, id)
	if i then
		table.remove(sim.Order, i)
	end
	if sim.Owner == id then
		sim.Owner = nil
	end
end

-- Rellena los equipos con máquinas y numera a cada uno dentro de su equipo (para emparejar defensas)
function BasketSim.fillTeams(sim: Sim, size: number, names1: { string }?, names2: { string }?, opts: { [string]: any }?)
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
		local i = 0
		while have < size do
			i += 1
			counter += 1
			BasketSim.addPlayer(sim, {
				Id = ("bot%d_%d"):format(team, counter),
				Name = names[i] or (if team == 1 then "Compañero" else "Rival"),
				Npc = names[i],
				Team = team,
				Skill = (if team == 1 then o.Skill1 else o.Skill2) or 0.5,
			})
			have += 1
		end
	end
	BasketSim.number(sim)
end

function BasketSim.number(sim: Sim)
	local count = { [1] = 0, [2] = 0 }
	for _, id in sim.Order do
		local p = sim.Players[id]
		count[p.Team] += 1
		p.Index = count[p.Team]
	end
end

function BasketSim.setHuman(sim: Sim, id: string, p: Vector3, v: Vector3?, facing: Vector3?)
	local player = sim.Players[id]
	if not player then
		return
	end
	if sim.Owner == id then
		player.Run += fdist(p, player.P)
	end
	player.P = Vector3.new(p.X, 0, p.Z)
	player.V = flat(v or Vector3.zero)
	if facing and flat(facing).Magnitude > 0.1 then
		player.Facing = flat(facing).Unit
	end
end

local function teleport(sim: Sim, p: any, at: Vector3, facing: Vector3?)
	p.P = Vector3.new(at.X, 0, at.Z)
	p.V = Vector3.zero
	if facing and flat(facing).Magnitude > 1e-3 then
		p.Facing = flat(facing).Unit
	end
	event(sim, "Teleport", { Id = p.Id, P = p.P, Facing = p.Facing, Bot = not p.Human })
end

local function setPhase(sim: Sim, phase: string, seconds: number?)
	sim.Phase = phase
	sim.PhaseUntil = sim.T + (seconds or 0)
end

local function giveBall(sim: Sim, p: any)
	sim.Owner = p.Id
	sim.LastTouch = p.Id
	sim.Ball.V = Vector3.zero
	sim.Ball.Scored = false
	p.Run = 0
	sim.Ball.P = Hoops.dribblePosition(p.P, p.Facing, 0, p.Scale)
end

---------------------------------------------------------------------
-- Lanzar, pasar, robar
---------------------------------------------------------------------

-- Lo encima que tiene a un rival (0 = solo, 1 = pegado delante)
function BasketSim.contest(sim: Sim, p: any): number
	local hoop = BasketSim.targetHoop(sim, p.Team)
	local toward = if hoop then flat(hoop.Rim - p.P) else p.Facing
	toward = if toward.Magnitude > 1e-3 then toward.Unit else p.Facing
	local best = 0
	for _, id in sim.Order do
		local q = sim.Players[id]
		if q.Team ~= p.Team then
			local to = flat(q.P - p.P)
			local d = to.Magnitude
			local front = if d > 1e-3 then to.Unit:Dot(toward) else 1
			local c = math.clamp((4.5 * (p.Scale or 1) - d) / (3 * (p.Scale or 1)), 0, 1) * math.clamp(0.4 + front, 0, 1)
			best = math.max(best, c)
		end
	end
	return best
end

local function release(sim: Sim, p: any, from: Vector3)
	sim.Owner = nil
	sim.LastTouch = p.Id
	sim.Ball.P = from
	sim.Ball.Scored = false
	sim.Ball.Ignore = p.Id
	sim.Ball.IgnoreUntil = sim.Ball.T + 0.35
	p.KickCd = sim.T + 0.4
	sim.KickSeq += 1
end

-- El tiro de `p` (también lo usa el cliente para verlo igual): punto de salida, velocidad y si es bandeja
function BasketSim.shotFor(sim: Sim, p: any, quality: number, seed: number, contest: number): (Vector3?, Vector3?, boolean, number)
	local hoop = BasketSim.targetHoop(sim, p.Team)
	if sim.Mode == "Libre" then
		-- Libre: la canasta que tengas más de frente
		local best, bestScore = nil, -math.huge
		for _, h in sim.Court.Hoops do
			local to = flat(h.Rim - p.P)
			local score = (if to.Magnitude > 1e-3 then to.Unit:Dot(p.Facing) else 1) - to.Magnitude * 0.01
			if score > bestScore then
				best, bestScore = h, score
			end
		end
		hoop = best
	end
	if not hoop then
		return nil, nil, false, 2
	end
	local s = p.Scale or 1
	local toRim = flat(hoop.Rim - p.P)
	local d = toRim.Magnitude
	local dir = if d > 1e-3 then toRim.Unit else p.Facing
	local layup = d < CFG.LayupDistance * math.max(s, 0.75)
	local from: Vector3
	local arc: number
	local q = quality
	if layup then
		-- Bandeja: un paso hacia el aro y suelta arriba, casi encima
		-- (nunca más cerca de 3 studs del aro en planta: si no, el balón subiría pegado al hierro)
		local step = math.max(0, math.min(d - 3, 2.2 * s))
		from = p.P + dir * step + Vector3.new(0, (CFG.ReleaseHeight + 1.2) * s, 0)
		arc = 1.4
		q = math.max(q, 0.78)
	else
		from = p.P + dir * 0.6 * s + Vector3.new(0, CFG.ReleaseHeight * s, 0)
		arc = Hoops.arcFor(d)
	end
	local v = Hoops.shotVelocity(from, hoop.Rim, arc)
	v = Hoops.shotError(v, q, if layup then 2 else d, if layup then math.min(1, contest * 1.4) else contest, Random.new(seed))
	local points = if layup then 2 else Court.points(sim.Court, hoop, p.P)
	return from, v, layup, points
end

-- Una persona que ya lo tiene en su pantalla (el servidor la ve con retraso): si el balón está suelto
-- y a mano, es suyo
local function claim(sim: Sim, p: any): boolean
	if sim.Owner == p.Id then
		return true
	end
	if sim.Owner or not p.Human or sim.T < p.KickCd or (sim.Mode == "Tiros" and sim.Phase ~= "ShotReady") then
		return false
	end
	local s = p.Scale or 1
	local ball = sim.Ball
	if fdist(ball.P, p.P) <= (CFG.ControlRadius + Hoops.Config.Radius) * s + CFG.HumanReach + 0.8 and ball.P.Y < 5.5 * s then
		giveBall(sim, p)
		return true
	end
	return false
end

function BasketSim.shoot(sim: Sim, id: string, quality: number, seed: number?): (boolean, string?)
	local p = sim.Players[id]
	if not p or not claim(sim, p) then
		return false, "NotYours"
	end
	if sim.T < p.KickCd or sim.Phase == "Over" or sim.Phase == "Idle" or sim.Phase == "Basket" then
		return false, "Phase"
	end
	local s = math.floor(tonumber(seed) or sim.Rng:NextInteger(1, 1e6))
	local contest = BasketSim.contest(sim, p)
	local from, v, layup, points = BasketSim.shotFor(sim, p, math.clamp(quality, 0, 1), s, contest)
	if not from or not v then
		return false, "NoHoop"
	end
	release(sim, p, from)
	sim.Ball.V = v
	p.Jump = sim.T + 0.55
	sim.Shot = { By = id, Team = p.Team, Points = points, At = sim.T, Touched = false }
	event(sim, "Shot", { Id = id, P = from, V = v, Seq = sim.KickSeq, Layup = layup, Points = points, Quality = quality })
	-- Tapón: un rival pegado delante puede taparlo (las máquinas saltan)
	for _, oid in sim.Order do
		local q = sim.Players[oid]
		if q.Team ~= p.Team and not q.Human and fdist(q.P, p.P) < 3.4 * (p.Scale or 1) then
			local front = flat(q.P - p.P)
			local hoop = BasketSim.targetHoop(sim, p.Team)
			local toward = if hoop then flat(hoop.Rim - p.P) else p.Facing
			if front.Magnitude > 1e-3 and toward.Magnitude > 1e-3 and front.Unit:Dot(toward.Unit) > 0.3 and sim.Rng:NextNumber() < 0.12 + 0.25 * q.Skill then
				q.Jump = sim.T + 0.5
				sim.Ball.V = Vector3.new(-v.X * 0.35, 6, -v.Z * 0.35) + Vector3.new(sim.Rng:NextNumber() * 8 - 4, 0, sim.Rng:NextNumber() * 8 - 4)
				sim.Shot = nil
				sim.LastTouch = q.Id
				event(sim, "Block", { Id = q.Id, Victim = id })
				break
			end
		end
	end
	if sim.Phase == "ShotReady" then
		setPhase(sim, "ShotFlight", CFG.ShotFlight)
	end
	return true
end

function BasketSim.pass(sim: Sim, id: string, to: string?, dir: Vector3?): (boolean, string?)
	local p = sim.Players[id]
	if not p or not claim(sim, p) or sim.T < p.KickCd then
		return false, "NotYours"
	end
	local mate = to and sim.Players[to]
	local s = p.Scale or 1
	local from = p.P + p.Facing * 0.8 * s + Vector3.new(0, 3.2 * s, 0)
	local v: Vector3
	if mate and mate.Team == p.Team and mate ~= p then
		local target = mate.P + flat(mate.V) * 0.35 + Vector3.new(0, 3 * (mate.Scale or 1), 0)
		local d = fdist(target, from)
		v = Hoops.shotVelocity(from, target, math.clamp(d * 0.09, 1, 3.5))
		sim.PassTo = mate.Id
		sim.PassToUntil = sim.T + 2
	else
		local d = if dir and flat(dir).Magnitude > 1e-3 then flat(dir).Unit else p.Facing
		v = d * CFG.PassSpeed * 0.7 + Vector3.new(0, 8, 0)
	end
	release(sim, p, from)
	sim.Ball.V = v
	sim.Shot = nil
	event(sim, "Pass", { Id = id, P = from, V = v, Seq = sim.KickSeq, To = to })
	return true
end

-- Robar (al que bota) o saltar a taponar (si acaban de tirar)
function BasketSim.steal(sim: Sim, id: string): (boolean, string?)
	local p = sim.Players[id]
	if not p or sim.T < p.StealCd then
		return false, "Cooldown"
	end
	p.StealCd = sim.T + 0.9
	p.Jump = sim.T + 0.45
	local owner = sim.Owner and sim.Players[sim.Owner]
	if owner and owner.Team ~= p.Team and fdist(owner.P, p.P) < CFG.StealReach * (p.Scale or 1) + (if p.Human then CFG.HumanReach else 0) then
		local chance = if p.Human then 0.42 else 0.18 + 0.25 * p.Skill
		if not owner.Human then
			chance -= 0.15 * owner.Skill
		end
		if sim.Rng:NextNumber() < chance then
			release(sim, p, sim.Ball.P)
			sim.Ball.V = flat(p.P - owner.P).Unit * 6 + Vector3.new(0, 7, 0)
			owner.KickCd = sim.T + 0.7
			event(sim, "Steal", { Id = id, Victim = owner.Id, Ok = true })
			return true
		end
		event(sim, "Steal", { Id = id, Victim = owner.Id, Ok = false })
		if not p.Human then
			p.Stun = sim.T + 0.6
		end
		return true
	end
	-- Tapón de una persona: el tiro acaba de salir y lo tiene a mano
	local shot = sim.Shot
	if shot and shot.Team ~= p.Team and sim.T - shot.At < 0.35 and fdist(sim.Ball.P, p.P) < 4 * (p.Scale or 1) and sim.Ball.P.Y < 8 * (p.Scale or 1) then
		if sim.Rng:NextNumber() < 0.55 then
			sim.Ball.V = Vector3.new(-sim.Ball.V.X * 0.3, 5, -sim.Ball.V.Z * 0.3)
			sim.Shot = nil
			sim.LastTouch = id
			event(sim, "Block", { Id = id, Victim = shot.By })
		end
	end
	event(sim, "Jump", { Id = id })
	return true
end

---------------------------------------------------------------------
-- Rondas de tiros, saques
---------------------------------------------------------------------

local function human(sim: Sim): any
	for _, id in sim.Order do
		if sim.Players[id].Human then
			return sim.Players[id]
		end
	end
	return nil
end

local function finish(sim: Sim)
	if sim.Over then
		return
	end
	sim.Over = true
	setPhase(sim, "Over", 0)
	event(sim, "Over", BasketSim.outcome(sim))
end

local function setupShot(sim: Sim)
	sim.Round += 1
	local h = human(sim)
	local hoop = BasketSim.targetHoop(sim, 1)
	if not h or not hoop then
		finish(sim)
		return
	end
	local spot = Court.freeThrowSpot(sim.Court, hoop)
	if sim.Spots == "Variado" then
		-- Cada tiro, más lejos y desde otro ángulo
		local k = (sim.Round - 1) % 4
		local dist = ({ 5, 8, 10, 12 })[k + 1] * math.max(h.Scale or 1, 0.7)
		local angle = ({ 0, -0.7, 0.7, 0 })[k + 1]
		local n = hoop.Normal
		local dir = Vector3.new(n.X * math.cos(angle) - n.Z * math.sin(angle), 0, n.X * math.sin(angle) + n.Z * math.cos(angle))
		spot = Court.clampInside(sim.Court, Vector3.new(hoop.Rim.X, 0, hoop.Rim.Z) + dir * dist, 1.5)
	end
	teleport(sim, h, spot, flat(hoop.Rim - spot))
	giveBall(sim, h)
	setPhase(sim, "ShotReady", CFG.ShotTimeout)
	event(sim, "ShotSetup", { Round = sim.Round, Rounds = sim.Rounds, Hits = sim.Hits })
end

local function roundResult(sim: Sim, ok: boolean, reason: string)
	sim.Taken += 1
	if ok then
		sim.Hits += 1
	end
	event(sim, "ShotResult", { Ok = ok, Reason = reason, Round = sim.Round, Hits = sim.Hits, Taken = sim.Taken, Rounds = sim.Rounds })
	setPhase(sim, "ShotResult", CFG.RoundPause)
end

local function decided(sim: Sim): boolean
	if sim.Taken >= sim.Rounds then
		return true
	end
	if sim.StopWhenDecided and sim.Need > 0 then
		return sim.Hits >= sim.Need or sim.Hits + (sim.Rounds - sim.Taken) < sim.Need
	end
	return false
end

-- Saque para `team` desde `spot` (tras canasta, de banda o al empezar)
local function inbound(sim: Sim, team: number, spot: Vector3, kind: string)
	Hoops.place(sim.Ball, spot + Vector3.new(0, 1, 0))
	sim.Owner = nil
	sim.Shot = nil
	local taker, best = nil, math.huge
	for _, id in sim.Order do
		local p = sim.Players[id]
		if p.Team == team then
			local d = fdist(p.P, spot) + (if p.Human then 6 else 0)
			if d < best then
				taker, best = p, d
			end
		end
	end
	if taker then
		if taker.Human and best > 14 then
			-- (la persona está lejos: saca una máquina de su equipo si hay)
			for _, id in sim.Order do
				local p = sim.Players[id]
				if p.Team == team and not p.Human then
					taker = p
					break
				end
			end
		end
		if taker.Human then
			teleport(sim, taker, spot, flat(-spot))
		else
			taker.P = Vector3.new(spot.X, 0, spot.Z)
			taker.V = Vector3.zero
			taker.HoldUntil = sim.T + 0.5
		end
		giveBall(sim, taker)
	end
	sim.Exclusive = { Team = team, Until = sim.T + 2.5 }
	setPhase(sim, "Restart", CFG.RestartPause)
	event(sim, "Restart", { Type = kind, Team = team })
end

local function startSpot(sim: Sim, team: number): Vector3
	local hoop = BasketSim.targetHoop(sim, team)
	if sim.Court.Half or not hoop then
		-- Media pista: se saca desde arriba (lejos del aro)
		local h = sim.Court.Hoops[1]
		return Vector3.new(h.Rim.X, 0, h.Rim.Z) + h.Normal * math.min(sim.Court.Length - 2, 16)
	end
	-- Pista entera: desde su campo, en el centro
	return Vector3.new(-hoop.Side * sim.Court.Length * 0.15, 0, 0)
end

function BasketSim.start(sim: Sim)
	sim.Over = false
	BasketSim.number(sim)
	if sim.Mode == "Tiros" then
		setupShot(sim)
	elseif sim.Mode == "Partido" then
		-- Todos a su sitio y saca tu equipo
		for _, id in sim.Order do
			local p = sim.Players[id]
			local hoop = BasketSim.targetHoop(sim, p.Team)
			local base = startSpot(sim, p.Team)
			local spread = Vector3.new(0, 0, (p.Index - 2) * 5)
			local at = Court.clampInside(sim.Court, base + spread - (if hoop then hoop.Normal else Vector3.zero) * (if p.Team == 1 then 0 else 4), 1.5)
			if p.Human then
				teleport(sim, p, at, if hoop then flat(hoop.Rim - at) else nil)
			else
				p.P = at
			end
		end
		inbound(sim, 1, startSpot(sim, 1), "Start")
	else
		local h = human(sim)
		if h then
			giveBall(sim, h)
		end
		setPhase(sim, "Play", 0)
	end
end

function BasketSim.outcome(sim: Sim): { [string]: any }
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
-- Máquinas
---------------------------------------------------------------------

local function moveBot(sim: Sim, p: any, dt: number)
	local target = p.Target or p.P
	local to = flat(target - p.P)
	local d = to.Magnitude
	local frozen = sim.T < p.Stun or sim.T < p.HoldUntil or sim.Phase == "Over" or sim.Phase == "Basket"
	local want = Vector3.zero
	if not frozen and d > 0.3 then
		local speed = math.min(p.MaxSpeed * (if p.Sprint then 1.1 else 1), d * 3.5)
		if sim.Owner == p.Id then
			speed *= 0.85
		end
		want = to / d * speed
	end
	for _, id in sim.Order do
		local q = sim.Players[id]
		if q ~= p then
			local away = flat(p.P - q.P)
			local m = away.Magnitude
			if m < 2 and m > 1e-3 then
				want += away / m * (2 - m) * 6
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
	local c = sim.Court
	p.P = p.P + p.V * dt
	p.P = Vector3.new(math.clamp(p.P.X, -c.Length / 2 - 1, c.Length / 2 + 1), 0, math.clamp(p.P.Z, -c.Width / 2 - 1, c.Width / 2 + 1))
	if sim.Owner == p.Id then
		p.Run += fdist(p.P, before)
	end
	if p.V.Magnitude > 1.5 then
		p.Facing = p.V.Unit
	else
		local toBall = flat(sim.Ball.P - p.P)
		if toBall.Magnitude > 0.5 then
			p.Facing = (p.Facing + toBall.Unit * math.min(1, dt * 6)).Unit
		end
	end
end

local function opponentsOf(sim: Sim, team: number): { any }
	local list = {}
	for _, id in sim.Order do
		local q = sim.Players[id]
		if q.Team ~= team then
			table.insert(list, q)
		end
	end
	return list
end

local function nearestOpp(sim: Sim, p: any): (any, number)
	local best, bestD = nil, math.huge
	for _, q in opponentsOf(sim, p.Team) do
		local d = fdist(q.P, p.P)
		if d < bestD then
			best, bestD = q, d
		end
	end
	return best, bestD
end

-- Lo que hace el que bota (máquina)
function BasketSim.carrierDecision(sim: Sim, p: any, rng: any): { [string]: any }
	local hoop = BasketSim.targetHoop(sim, p.Team)
	if not hoop then
		return { Kind = "Hold" }
	end
	local s = p.Scale or 1
	local toRim = flat(hoop.Rim - p.P)
	local d = toRim.Magnitude
	local _, press = nearestOpp(sim, p)
	local open = press > 4 * s
	-- Media pista: tras robar o coger el rebote en defensa, primero se sale fuera de la línea de 3
	if sim.MustClear == p.Team then
		if d >= Court.threeDistance(sim.Court) then
			sim.MustClear = nil
		else
			return { Kind = "Drive", Target = startSpot(sim, p.Team) }
		end
	end
	local contest = BasketSim.contest(sim, p)
	if d < CFG.LayupDistance * math.max(s, 0.75) and contest < 0.6 and rng:NextNumber() < 0.7 then
		return { Kind = "Shot", Quality = 0.6 + 0.4 * p.Skill * rng:NextNumber() }
	end
	if d < 16 * math.max(s, 0.75) and open and rng:NextNumber() < 0.25 + 0.25 * p.Skill then
		return { Kind = "Shot", Quality = math.clamp(0.35 + 0.55 * p.Skill + (rng:NextNumber() - 0.5) * 0.4, 0, 1) }
	end
	-- Pase a un compañero libre (a las personas, más)
	local best, bestScore = nil, -math.huge
	for _, id in sim.Order do
		local m = sim.Players[id]
		if m ~= p and m.Team == p.Team and fdist(m.P, p.P) < 24 * math.max(s, 0.75) and fdist(m.P, p.P) > 3 then
			local _, mo = nearestOpp(sim, m)
			local score = mo * 1.2 - fdist(m.P, hoop.Rim) * 0.25 + (if m.Human then 5 else 0)
			if mo > 3 * s and score > bestScore then
				best, bestScore = m, score
			end
		end
	end
	if best and (press < 3 * s and rng:NextNumber() < 0.7 or rng:NextNumber() < 0.12) then
		return { Kind = "Pass", To = best.Id }
	end
	-- Penetrar: hacia el aro, esquivando al defensor
	local dir = if d > 1e-3 then toRim.Unit else p.Facing
	local opp, od = nearestOpp(sim, p)
	if opp and od < 5 * s then
		local side = Vector3.new(-dir.Z, 0, dir.X)
		local sign = if flat(p.P - opp.P):Dot(side) >= 0 then 1 else -1
		dir = (dir + side * sign * 0.8).Unit
	end
	return { Kind = "Drive", Target = Court.clampInside(sim.Court, p.P + dir * 6, 1.5) }
end

-- Sitios del ataque alrededor del aro (sin balón)
local function spotFor(sim: Sim, p: any): Vector3
	local hoop = BasketSim.targetHoop(sim, p.Team)
	if not hoop then
		return p.P
	end
	local n = hoop.Normal
	local angle = ({ -1.0, 0, 1.0, -0.5, 0.5 })[((p.Index - 1) % 5) + 1]
	local r = math.clamp(sim.Court.Length * 0.22, 8, 13) * math.max(p.Scale or 1, 0.75)
	local dir = Vector3.new(n.X * math.cos(angle) - n.Z * math.sin(angle), 0, n.X * math.sin(angle) + n.Z * math.cos(angle))
	return Court.clampInside(sim.Court, Vector3.new(hoop.Rim.X, 0, hoop.Rim.Z) + dir * r, 1.5)
end

local function think(sim: Sim)
	local ball = sim.Ball
	-- Dónde caerá el balón suelto (rebote)
	local landing = ball.P
	if not sim.Owner then
		local _, at = Hoops.landing(ball, sim.Court, 4 * sim.Scale, 2)
		if at then
			landing = at
		end
	end
	-- Quién va a por el balón suelto: el más cercano de cada equipo
	local chaser: { [number]: any } = {}
	if not sim.Owner then
		for _, id in sim.Order do
			local p = sim.Players[id]
			local d = fdist(p.P, landing) - (if p.Human then 1.5 else 0)
			if not chaser[p.Team] or d < chaser[p.Team].D then
				chaser[p.Team] = { Id = id, D = d }
			end
		end
	end
	local owner = sim.Owner and sim.Players[sim.Owner]
	for _, id in sim.Order do
		local p = sim.Players[id]
		if p.Human or sim.T < p.NextThink then
			continue
		end
		p.NextThink = sim.T + CFG.Think * (0.8 + 0.4 * sim.Rng:NextNumber())
		p.Sprint = false
		if sim.Mode ~= "Partido" then
			p.Target = p.P
			continue
		end
		if sim.Owner == id then
			if sim.T < p.HoldUntil then
				p.Target = p.P
				continue
			end
			local action = BasketSim.carrierDecision(sim, p, sim.Rng)
			if action.Kind == "Shot" then
				BasketSim.shoot(sim, id, action.Quality, sim.Rng:NextInteger(1, 1e6))
			elseif action.Kind == "Pass" then
				BasketSim.pass(sim, id, action.To)
			elseif action.Kind == "Drive" then
				p.Target = action.Target
			end
		elseif not owner then
			if chaser[p.Team] and chaser[p.Team].Id == id then
				p.Target = landing
				p.Sprint = true
			elseif sim.PassTo == id and sim.T < (sim.PassToUntil or 0) then
				-- El pase es para él: va a donde el balón baja a la altura del pecho
				local _, at = Hoops.landing(ball, sim.Court, 3 * (p.Scale or 1), 1.5)
				p.Target = at or ball.P
				p.Sprint = true
				p.NextThink = sim.T + 0.08
			else
				p.Target = spotFor(sim, p)
			end
		elseif owner.Team == p.Team then
			p.Target = spotFor(sim, p)
		else
			-- Defensa al hombre: entre su par y el aro (más pegado al que bota)
			local man = nil
			for _, oid in sim.Order do
				local q = sim.Players[oid]
				if q.Team ~= p.Team and q.Index == p.Index then
					man = q
				end
			end
			man = man or owner
			local hoop = BasketSim.targetHoop(sim, man.Team)
			local rim = if hoop then Vector3.new(hoop.Rim.X, 0, hoop.Rim.Z) else Vector3.zero
			local toRim = flat(rim - man.P)
			local gap = (if man == owner then 2 else 3.2) * (p.Scale or 1)
			p.Target = man.P + (if toRim.Magnitude > 1e-3 then toRim.Unit * math.min(gap, toRim.Magnitude * 0.5) else Vector3.zero)
			if man == owner and fdist(p.P, owner.P) < CFG.StealReach * (p.Scale or 1) and sim.Rng:NextNumber() < 0.07 + 0.08 * p.Skill then
				BasketSim.steal(sim, id)
			end
		end
	end
end

---------------------------------------------------------------------
-- Paso
---------------------------------------------------------------------

local function tryControl(sim: Sim)
	if sim.Owner or sim.Phase == "Basket" or sim.Phase == "Over" or sim.Phase == "ShotResult" then
		return
	end
	if sim.Mode == "Tiros" and sim.Phase ~= "ShotReady" then
		return -- (en la tanda el balón vuelve solo: nadie lo coge)
	end
	local ball = sim.Ball
	local best, bestD = nil, math.huge
	for _, id in sim.Order do
		local p = sim.Players[id]
		if sim.T < p.KickCd or sim.T < p.Stun or (ball.Ignore == id and ball.T < ball.IgnoreUntil) then
			continue
		end
		if sim.Exclusive and sim.T < sim.Exclusive.Until and sim.Exclusive.Team ~= p.Team then
			continue
		end
		local s = p.Scale or 1
		local reach = (CFG.ControlRadius + Hoops.Config.Radius) * s + (if p.Human then CFG.HumanReach else 0)
		local d = fdist(p.P, ball.P)
		-- (un pase se coge aunque venga rápido; un balón suelto, si no va disparado)
		local catch = if sim.PassTo == id then 70 else 45
		if d > reach or ball.P.Y > 5.5 * s or flat(ball.V - p.V).Magnitude > catch then
			continue
		end
		if d < bestD then
			best, bestD = p, d
		end
	end
	if best then
		giveBall(sim, best)
		sim.Exclusive = nil
		sim.PassTo = nil
		local last = sim.LastPossession
		if sim.Court.Half and sim.Mode == "Partido" and last and last ~= best.Team then
			sim.MustClear = best.Team
		end
		sim.LastPossession = best.Team
		if sim.Shot and best.Team ~= sim.Shot.Team then
			event(sim, "Rebound", { Id = best.Id, Defensive = true })
		elseif sim.Shot then
			event(sim, "Rebound", { Id = best.Id, Defensive = false })
		end
		sim.Shot = nil
		event(sim, "Control", { Id = best.Id })
	end
end

local function onBasket(sim: Sim, side: number)
	local shot = sim.Shot
	if sim.Mode == "Tiros" then
		if sim.Phase == "ShotFlight" then
			roundResult(sim, true, "Basket")
		end
		return
	end
	local team = if shot then shot.Team elseif sim.Court.Half then 1 else (if side > 0 then 1 else 2)
	local points = if shot then shot.Points else 2
	sim.Score[team] += points
	event(sim, "Basket", { Team = team, Points = points, Scorer = if shot then shot.By else sim.LastTouch, Score = { sim.Score[1], sim.Score[2] } })
	sim.Shot = nil
	sim.ScoredTeam = team
	setPhase(sim, "Basket", CFG.BasketPause)
end

local function updatePhase(sim: Sim)
	local phase = sim.Phase
	if phase == "Basket" and sim.T >= sim.PhaseUntil then
		if sim.Mode == "Partido" then
			if sim.Clock >= sim.Duration then
				finish(sim)
				return
			end
			-- Saca el otro equipo: desde debajo de la canasta (pista entera) o desde arriba (media pista)
			local team = 3 - (sim.ScoredTeam or 1)
			local hoop = BasketSim.targetHoop(sim, sim.ScoredTeam or 1)
			local spot = if sim.Court.Half or not hoop then startSpot(sim, team) else Vector3.new(hoop.Rim.X, 0, hoop.Rim.Z) + hoop.Normal * 2.5 + Vector3.new(0, 0, 4)
			inbound(sim, team, Court.clampInside(sim.Court, spot, 1), "Basket")
		else
			setPhase(sim, "Play", 0)
		end
	elseif phase == "Restart" and sim.T >= sim.PhaseUntil then
		setPhase(sim, "Play", 0)
	elseif phase == "ShotReady" and sim.T >= sim.PhaseUntil then
		roundResult(sim, false, "Timeout")
	elseif phase == "ShotFlight" then
		if sim.T >= sim.PhaseUntil or (Hoops.resting(sim.Ball) and sim.T > sim.PhaseUntil - CFG.ShotFlight + 0.8) then
			roundResult(sim, false, sim.MissReason or "Miss")
		end
	elseif phase == "ShotResult" and sim.T >= sim.PhaseUntil then
		sim.MissReason = nil
		if decided(sim) then
			finish(sim)
		else
			setupShot(sim)
		end
	end
	if sim.Mode == "Partido" and (sim.Phase == "Play" or sim.Phase == "Restart") and sim.Clock >= sim.Duration then
		finish(sim)
	end
end

local function checkOut(sim: Sim)
	if sim.Mode ~= "Partido" or sim.Owner or sim.Phase ~= "Play" then
		if sim.Mode == "Libre" and not sim.Owner and Court.out(sim.Court, sim.Ball.P, 2) and Hoops.resting(sim.Ball) then
			Hoops.place(sim.Ball, Court.clampInside(sim.Court, sim.Ball.P, 1.5))
		end
		return
	end
	if not Court.out(sim.Court, sim.Ball.P) or sim.Ball.P.Y > 6 then
		return
	end
	local last = sim.LastTouch and sim.Players[sim.LastTouch]
	local team = 3 - (if last then last.Team else 1)
	local spot = Court.clampInside(sim.Court, sim.Ball.P, 1)
	event(sim, "Out", {})
	inbound(sim, team, spot, "Side")
end

local function tick(sim: Sim, dt: number)
	sim.T += dt
	if sim.Phase == "Idle" then
		return
	end
	if sim.Mode == "Partido" and (sim.Phase == "Play" or sim.Phase == "Restart") then
		sim.Clock += dt
	end
	if sim.Phase ~= "Over" then
		think(sim)
	end
	for _, id in sim.Order do
		local p = sim.Players[id]
		if not p.Human then
			moveBot(sim, p, dt)
		end
	end
	local ball = sim.Ball
	if sim.Owner then
		local o = sim.Players[sim.Owner]
		local speed = flat(o.V).Magnitude
		ball.P = Hoops.dribblePosition(o.P, o.Facing, o.Run * 0.55 + sim.T * 3, o.Scale)
		ball.V = flat(o.V)
		ball.T += dt
		local _ = speed
	else
		local evs = Hoops.step(ball, dt, sim.Court)
		for _, e in evs do
			if e.Kind == "Basket" then
				onBasket(sim, e.Side)
			elseif e.Kind == "Rim" or e.Kind == "Board" then
				if (e.Speed or 0) > 4 then
					event(sim, e.Kind, { Side = e.Side, Speed = e.Speed })
				end
				sim.MissReason = "Rim"
			end
		end
	end
	tryControl(sim)
	checkOut(sim)
	updatePhase(sim)
end

function BasketSim.step(sim: Sim, dt: number): { { [string]: any } }
	sim.Accumulator += math.clamp(dt, 0, 0.25)
	while sim.Accumulator >= CFG.Tick do
		sim.Accumulator -= CFG.Tick
		tick(sim, CFG.Tick)
	end
	local out = sim.Events
	sim.Events = {}
	return out
end

return BasketSim
