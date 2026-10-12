-- RacketSim (compartido): tenis (1 contra 1) y pádel (2 contra 2) de verdad, sin nada de Roblox
-- (lo usa RacketService). Se prueba en scripts/test-raqueta.luau.
--
-- La pista en coordenadas propias: la red en x = 0; el equipo 1 juega en x < 0 y el 2 en x > 0.
--   Tenis   medio campo de Half × Width, red baja; la pelota tiene que botar dentro del campo rival.
--   Pádel   más corta y con paredes (fondo y laterales): tras botar en el suelo rival puede rebotar en
--           las paredes y seguir viva; si da en una pared rival antes de botar, es fuera.
-- Un punto se pierde si: la pelota bota dos veces en tu campo, la mandas fuera o a la red, o (pádel)
-- da en la pared del rival sin botar antes. Partido corto a Points puntos (7), saque alterno.
--
-- Golpear: «Golpe» (rápido y tenso) o «Globo» (alto, por encima del rival). Hacia donde apuntas;
-- la calidad depende de cuándo le pegas (a la altura de la cintura, al lado del cuerpo, es perfecto):
-- mal pegada se va a la red, fuera o se queda corta.

local RacketSim = {}

export type Sim = { [string]: any }

RacketSim.Kinds = {
	Tenis = { Half = 24, Width = 20, Net = 3, Walls = false, Gravity = 42, Bounce = 0.72, Reach = 3.6 },
	Padel = { Half = 18, Width = 18, Net = 2.8, Walls = true, WallHeight = 9, Gravity = 42, Bounce = 0.7, Reach = 3.3 },
}

RacketSim.Config = {
	Tick = 1 / 60,
	Radius = 0.45,
	Drag = 0.25,
	PointPause = 2,
	ServeTimeout = 10,
	BotSpeed = 15,
	IdealHeight = 2.6,
}
local CFG = RacketSim.Config

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end
local function event(sim: Sim, kind: string, data: { [string]: any }?)
	local e = data or {}
	e.Kind = kind
	e.T = sim.T
	table.insert(sim.Events, e)
end
local function side(team: number): number
	return if team == 1 then -1 else 1
end
RacketSim.side = side

function RacketSim.new(opts: { [string]: any }?): Sim
	local o = opts or {}
	local kind = RacketSim.Kinds[o.Kind or "Tenis"] or RacketSim.Kinds.Tenis
	return {
		Kind = o.Kind or "Tenis",
		Half = kind.Half,
		Width = kind.Width,
		Net = kind.Net,
		Walls = kind.Walls,
		WallHeight = kind.WallHeight or 0,
		Gravity = kind.Gravity,
		Bounce = kind.Bounce,
		Reach = kind.Reach,
		Points = o.Points or 7,
		Duration = o.Duration or 420,
		BotSpeed = o.BotSpeed or CFG.BotSpeed,
		Rng = o.Rng or Random.new(o.Seed or 1),
		T = 0,
		Phase = "Idle",
		PhaseUntil = 0,
		Score = { [1] = 0, [2] = 0 },
		Players = {},
		Order = {},
		Ball = { P = Vector3.new(0, 3, 0), V = Vector3.zero },
		Bounces = 0, -- botes en el campo de quien tiene que devolver
		BounceSide = 0,
		LastHitter = nil :: string?,
		LastTeam = 0,
		Server = nil :: string?,
		Seq = 0,
		Events = {},
		Over = false,
		Accumulator = 0,
	}
end

function RacketSim.addPlayer(sim: Sim, spec: { [string]: any })
	local p = {
		Id = spec.Id,
		Name = spec.Name or spec.Id,
		Npc = spec.Npc,
		Team = spec.Team or 1,
		Human = spec.Human == true,
		Skill = math.clamp(spec.Skill or 0.5, 0, 1),
		P = Vector3.zero,
		V = Vector3.zero,
		Cd = 0,
		Target = nil,
		Index = 0,
	}
	sim.Players[p.Id] = p
	table.insert(sim.Order, p.Id)
	local n = 0
	for _, id in sim.Order do
		if sim.Players[id].Team == p.Team then
			n += 1
		end
	end
	p.Index = n
	return p
end

function RacketSim.setHuman(sim: Sim, id: string, p: Vector3)
	local h = sim.Players[id]
	if h then
		h.P = Vector3.new(p.X, 0, p.Z)
	end
end

---------------------------------------------------------------------
-- La pelota
---------------------------------------------------------------------

local function inCourt(sim: Sim, p: Vector3, onSide: number): boolean
	return p.X * onSide >= 0 and math.abs(p.X) <= sim.Half + 0.3 and math.abs(p.Z) <= sim.Width / 2 + 0.3
end

-- Un paso de la pelota: devuelve una lista de choques { "Bounce" (lado), "Net", "Wall" (lado) }
local function stepBall(sim: Sim, dt: number): { { [string]: any } }
	local b = sim.Ball
	local hits = {}
	local before = b.P
	b.V = (b.V + Vector3.new(0, -sim.Gravity, 0) * dt) * math.exp(-CFG.Drag * dt)
	b.P = b.P + b.V * dt
	local r = CFG.Radius
	-- Red
	if math.sign(before.X) ~= math.sign(b.P.X) and math.abs(b.P.Z) <= sim.Width / 2 + 0.6 then
		local f = before.X / (before.X - b.P.X)
		local y = before.Y + (b.P.Y - before.Y) * f
		if y < sim.Net + r * 0.4 then
			b.P = Vector3.new(math.sign(before.X) * r, b.P.Y, b.P.Z)
			b.V = Vector3.new(-b.V.X * 0.15, b.V.Y * 0.4, b.V.Z * 0.4)
			table.insert(hits, { Kind = "Net" })
		end
	end
	-- Suelo
	if b.P.Y <= r and b.V.Y < 0 then
		b.P = Vector3.new(b.P.X, r, b.P.Z)
		b.V = Vector3.new(b.V.X * 0.85, -b.V.Y * sim.Bounce, b.V.Z * 0.85)
		if math.abs(b.V.Y) < 1.5 then
			b.V = Vector3.new(b.V.X, 0, b.V.Z)
		end
		table.insert(hits, { Kind = "Bounce", Side = if b.P.X < 0 then 1 else 2, In = inCourt(sim, b.P, math.sign(b.P.X)) })
	end
	-- Paredes (pádel)
	if sim.Walls and b.P.Y < sim.WallHeight then
		if math.abs(b.P.X) > sim.Half - r then
			b.P = Vector3.new(math.sign(b.P.X) * (sim.Half - r), b.P.Y, b.P.Z)
			b.V = Vector3.new(-b.V.X * 0.65, b.V.Y, b.V.Z)
			table.insert(hits, { Kind = "Wall", Side = if b.P.X < 0 then 1 else 2 })
		end
		if math.abs(b.P.Z) > sim.Width / 2 - r then
			b.P = Vector3.new(b.P.X, b.P.Y, math.sign(b.P.Z) * (sim.Width / 2 - r))
			b.V = Vector3.new(b.V.X, b.V.Y, -b.V.Z * 0.65)
			table.insert(hits, { Kind = "Wall", Side = if b.P.X < 0 then 1 else 2 })
		end
	end
	return hits
end

RacketSim.stepBall = stepBall

-- Dónde estará la pelota a la altura `height` bajando (para ir a por ella), simulando
function RacketSim.predict(sim: Sim, height: number, maxT: number?): (number?, Vector3?)
	local saved = { P = sim.Ball.P, V = sim.Ball.V }
	local t, found, at = 0, nil, nil
	local bounced = if sim.Flying == false then 1 else 0 -- (si ya ha botado, cuenta)
	local rising: { any }? = nil
	while t < (maxT or 3) do
		local before = sim.Ball.P
		for _, h in stepBall(sim, 1 / 30) do
			if h.Kind == "Bounce" then
				bounced += 1
			end
		end
		t += 1 / 30
		if bounced >= 1 and before.Y >= height and sim.Ball.P.Y < height and sim.Ball.V.Y < 0 then
			found, at = t, sim.Ball.P
			break
		end
		if bounced >= 1 and sim.Ball.V.Y > 0 and sim.Ball.P.Y >= height and before.Y < height and not rising then
			rising = { t, sim.Ball.P } -- (subiendo tras el bote: por si no vuelve a bajar a esa altura)
		end
		if bounced >= 2 then
			break
		end
	end
	if not found and rising then
		found, at = rising[1], rising[2]
	end
	sim.Ball.P, sim.Ball.V = saved.P, saved.V
	return found, at
end

local function shot(sim: Sim, from: Vector3, target: Vector3, kind: string): Vector3
	local g = sim.Gravity
	local apex = if kind == "Globo" then math.max(from.Y, sim.Net) + 9 else math.max(from.Y, sim.Net + 0.8) + 1.2
	local up = math.sqrt(2 * g * math.max(apex - from.Y, 0.05))
	local t = up / g + math.sqrt(2 * math.max(apex - CFG.Radius, 0.05) / g)
	local horizontal = flat(target - from) / t
	return horizontal * (1 + CFG.Drag * t * 0.5) + Vector3.new(0, up, 0)
end
RacketSim.shot = shot

---------------------------------------------------------------------
-- Golpes
---------------------------------------------------------------------

function RacketSim.canHit(sim: Sim, p: any): boolean
	if sim.Phase ~= "Rally" or sim.T < p.Cd then
		return false
	end
	local b = sim.Ball
	if b.P.X * side(p.Team) < -0.5 then
		return false
	end
	if sim.LastTeam == p.Team then
		return false -- (ya la ha pegado su equipo: ahora le toca al rival)
	end
	local d = flat(b.P - p.P).Magnitude
	return d <= sim.Reach and b.P.Y >= 0.5 and b.P.Y <= 6.5
end

function RacketSim.quality(sim: Sim, p: any): number
	local b = sim.Ball
	local dh = math.abs(b.P.Y - CFG.IdealHeight)
	local d = flat(b.P - p.P).Magnitude
	local dd = math.abs(d - 1.6) -- (al lado del cuerpo, ni pegada ni a punta de raqueta)
	return math.clamp(1 - math.max(0, dh - 0.6) * 0.3 - math.max(0, dd - 0.8) * 0.25, 0.15, 1)
end

-- Golpea hacia `aim` (punto del suelo del campo rival; nil = uno al azar). kind: "Golpe" | "Globo"
function RacketSim.hit(sim: Sim, id: string, aim: Vector3?, kind: string?, quality: number?): (boolean, string?)
	local p = sim.Players[id]
	if not p or not RacketSim.canHit(sim, p) then
		return false, "Far"
	end
	local k = kind or "Golpe"
	local q = quality or (if p.Human then RacketSim.quality(sim, p) else 0.5 + 0.45 * p.Skill)
	local other = -side(p.Team)
	local rng = sim.Rng
	local target = aim or Vector3.new(other * sim.Half * (0.45 + 0.4 * rng:NextNumber()), 0, (rng:NextNumber() * 2 - 1) * sim.Width * 0.38)
	target = Vector3.new(other * math.clamp(math.abs(target.X), 3, sim.Half - 1), 0, math.clamp(target.Z, -sim.Width / 2 + 1, sim.Width / 2 - 1))
	local v = shot(sim, sim.Ball.P, target, k)
	local err = 1 - q
	local long = 1 + (rng:NextNumber() * 2 - 1) * err * 0.35
	local lateral = (rng:NextNumber() * 2 - 1) * err * 0.3
	local fv = flat(v)
	local right = if fv.Magnitude > 1e-3 then Vector3.new(-fv.Z, 0, fv.X).Unit else Vector3.new(0, 0, 1)
	v = fv * long + right * fv.Magnitude * lateral + Vector3.new(0, v.Y * (1 - err * 0.25 * rng:NextNumber()), 0)
	sim.Ball.V = v
	sim.LastHitter = id
	sim.LastTeam = p.Team
	sim.Bounces = 0
	sim.BounceSide = 0
	sim.Flying = true -- (aún no ha botado en el campo rival)
	p.Cd = sim.T + 0.3
	sim.Seq += 1
	event(sim, "Hit", { Id = id, Type = k, Quality = q, P = sim.Ball.P, V = v, Seq = sim.Seq })
	return true
end

---------------------------------------------------------------------
-- Saque y puntos
---------------------------------------------------------------------

local function home(sim: Sim, p: any): Vector3
	local s = side(p.Team)
	local pair = 0
	for _, id in sim.Order do
		if sim.Players[id].Team == p.Team then
			pair += 1
		end
	end
	if pair >= 2 then
		return Vector3.new(s * sim.Half * 0.55, 0, (if p.Index == 1 then -1 else 1) * sim.Width * 0.25)
	end
	return Vector3.new(s * sim.Half * 0.92, 0, 0)
end

local function setupServe(sim: Sim)
	sim.ServeCount = (sim.ServeCount or 0) + 1
	-- Saca cada equipo dos puntos seguidos; dentro del equipo, se turnan
	local team = if math.floor((sim.ServeCount - 1) / 2) % 2 == 0 then 1 else 2
	local list = {}
	for _, id in sim.Order do
		if sim.Players[id].Team == team then
			table.insert(list, sim.Players[id])
		end
	end
	local server = list[math.floor((sim.ServeCount - 1) / 4) % #list + 1]
	sim.Server = server.Id
	sim.LastHitter, sim.LastTeam = nil, 0
	sim.Bounces, sim.BounceSide = 0, 0
	for _, id in sim.Order do
		local o = sim.Players[id]
		local at = home(sim, o)
		if o == server then
			at = Vector3.new(side(team) * (sim.Half - 0.5), 0, (if sim.ServeCount % 2 == 0 then 1 else -1) * sim.Width * 0.2)
		end
		o.Target = at
		if not o.Human then
			o.P = at
		end
		event(sim, "Teleport", { Id = id, P = at, Facing = Vector3.new(-side(o.Team), 0, 0), Bot = not o.Human })
	end
	sim.Ball.P = server.P + Vector3.new(-side(team) * 0.6, 5, 0)
	sim.Ball.V = Vector3.zero
	sim.Phase = "Serve"
	sim.PhaseUntil = sim.T + (if server.Human then CFG.ServeTimeout else 1.2)
	event(sim, "Serve", { Id = server.Id, Team = team })
end

function RacketSim.serve(sim: Sim, id: string, aim: Vector3?, quality: number?): boolean
	if sim.Phase ~= "Serve" or sim.Server ~= id then
		return false
	end
	local p = sim.Players[id]
	local other = -side(p.Team)
	local q = quality or (0.6 + 0.4 * p.Skill)
	local target = aim or Vector3.new(other * sim.Half * 0.4, 0, -math.sign(p.P.Z + 1e-3) * sim.Width * 0.22)
	target = Vector3.new(other * math.clamp(math.abs(target.X), 3, sim.Half * 0.6), 0, math.clamp(target.Z, -sim.Width / 2 + 1, sim.Width / 2 - 1))
	local v = shot(sim, sim.Ball.P, target, "Golpe")
	local err = 1 - q
	v = Vector3.new(v.X * (1 + (sim.Rng:NextNumber() * 2 - 1) * err * 0.2), v.Y, v.Z + (sim.Rng:NextNumber() * 2 - 1) * err * 3)
	sim.Ball.V = v
	sim.LastHitter, sim.LastTeam = id, p.Team
	sim.Bounces, sim.BounceSide = 0, 0
	sim.Flying = true
	p.Cd = sim.T + 0.4
	sim.Phase = "Rally"
	sim.Seq += 1
	event(sim, "Hit", { Id = id, Type = "Saque", Quality = q, P = sim.Ball.P, V = v, Seq = sim.Seq })
	return true
end

local function finish(sim: Sim)
	if sim.Over then
		return
	end
	sim.Over = true
	sim.Phase = "Over"
	event(sim, "Over", RacketSim.outcome(sim))
end

local function point(sim: Sim, team: number, why: string)
	sim.Score[team] += 1
	event(sim, "Point", { Team = team, Why = why, Score = { sim.Score[1], sim.Score[2] } })
	if sim.Score[team] >= sim.Points then
		finish(sim)
		return
	end
	sim.Phase = "Point"
	sim.PhaseUntil = sim.T + CFG.PointPause
end

function RacketSim.start(sim: Sim)
	sim.Over = false
	sim.StartT = sim.T
	setupServe(sim)
end

function RacketSim.outcome(sim: Sim): { [string]: any }
	return { Mode = sim.Kind, Goals = sim.Score[1], Against = sim.Score[2], Over = sim.Over }
end

---------------------------------------------------------------------
-- Máquinas y paso
---------------------------------------------------------------------

local function think(sim: Sim)
	local _, at = RacketSim.predict(sim, CFG.IdealHeight, 3)
	for _, id in sim.Order do
		local p = sim.Players[id]
		if p.Human then
			continue
		end
		if sim.Phase == "Serve" then
			if sim.Server == id and sim.T >= sim.PhaseUntil then
				RacketSim.serve(sim, id)
			end
			continue
		end
		if sim.Phase ~= "Rally" then
			continue
		end
		local s = side(p.Team)
		local coming = at ~= nil and at.X * s > 0 and sim.LastTeam ~= p.Team
		if coming and at then
			-- El de su equipo más cercano va a por ella (si la persona está más cerca, la deja)
			local best, bestD = nil, math.huge
			for _, oid in sim.Order do
				local o = sim.Players[oid]
				if o.Team == p.Team then
					local d = flat(o.P - at).Magnitude - (if o.Human then 1.5 else 0)
					if d < bestD then
						best, bestD = o, d
					end
				end
			end
			p.Target = if best == p then at - Vector3.new(0, 0, 1.4) else home(sim, p)
		else
			p.Target = home(sim, p)
		end
		if RacketSim.canHit(sim, p) and math.abs(sim.Ball.P.Y - CFG.IdealHeight) < 1.4 then
			local lob = sim.Walls and sim.Rng:NextNumber() < 0.15
			RacketSim.hit(sim, id, nil, if lob then "Globo" else "Golpe")
		end
	end
end

local function moveBots(sim: Sim, dt: number)
	for _, id in sim.Order do
		local p = sim.Players[id]
		if p.Human or not p.Target then
			continue
		end
		local to = flat(p.Target - p.P)
		local d = to.Magnitude
		local speed = sim.BotSpeed * (1 + 0.35 * p.Skill)
		if d > 0.15 then
			p.P = p.P + to.Unit * math.min(d, speed * dt)
		end
		local s = side(p.Team)
		p.P = Vector3.new(if s < 0 then math.min(p.P.X, -1) else math.max(p.P.X, 1), 0, p.P.Z)
	end
end

local function tick(sim: Sim, dt: number)
	sim.T += dt
	if sim.Phase == "Idle" or sim.Phase == "Over" then
		return
	end
	if sim.T - (sim.StartT or 0) > sim.Duration then
		finish(sim)
		return
	end
	think(sim)
	moveBots(sim, dt)
	if sim.Phase == "Serve" then
		local server = sim.Server and sim.Players[sim.Server]
		if server and server.Human and sim.T >= sim.PhaseUntil then
			RacketSim.serve(sim, server.Id, nil, 0.75) -- (si no sacas, el saque sale solo)
		end
		return
	end
	if sim.Phase == "Point" then
		if sim.T >= sim.PhaseUntil then
			setupServe(sim)
		end
		return
	end
	local hitterTeam = sim.LastTeam
	for _, h in stepBall(sim, dt) do
		if sim.Phase ~= "Rally" then
			break
		end
		if h.Kind == "Net" then
			event(sim, "Net", {})
		elseif h.Kind == "Bounce" then
			local onSide = h.Side
			if onSide == hitterTeam then
				-- Bota en su propio campo (la red la devolvió, o se quedó corta)
				point(sim, 3 - hitterTeam, "Red")
			elseif sim.Flying then
				sim.Flying = false
				if not h.In then
					point(sim, 3 - hitterTeam, "Fuera")
				else
					sim.Bounces = 1
					event(sim, "Bounce", { P = sim.Ball.P })
				end
			else
				sim.Bounces += 1
				if sim.Bounces >= 2 then
					point(sim, hitterTeam, "DosBotes")
				end
			end
		elseif h.Kind == "Wall" then
			if sim.Flying and h.Side ~= hitterTeam then
				point(sim, 3 - hitterTeam, "Pared") -- (pádel: a la pared rival sin botar)
			end
		end
	end
	-- Fuera del recinto sin botar (tenis): lejos y bajando
	if sim.Phase == "Rally" and not sim.Walls and (math.abs(sim.Ball.P.X) > sim.Half + 12 or math.abs(sim.Ball.P.Z) > sim.Width / 2 + 12) then
		if sim.Flying then
			point(sim, 3 - hitterTeam, "Fuera")
		else
			point(sim, hitterTeam, "Pasada")
		end
	end
end

function RacketSim.step(sim: Sim, dt: number): { { [string]: any } }
	sim.Accumulator += math.clamp(dt, 0, 0.25)
	while sim.Accumulator >= CFG.Tick do
		sim.Accumulator -= CFG.Tick
		tick(sim, CFG.Tick)
	end
	local out = sim.Events
	sim.Events = {}
	return out
end

return RacketSim
