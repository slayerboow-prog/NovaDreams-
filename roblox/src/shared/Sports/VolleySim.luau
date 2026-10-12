-- VolleySim (compartido): vóley playa 2 contra 2 de verdad, sin nada de Roblox (lo usa VolleyService).
-- Se prueba en scripts/test-voley.luau.
--
-- La pista en coordenadas propias: la red en x = 0 (de z = -Width/2 a Width/2, de alto NetHeight); el
-- equipo 1 juega en x < 0 y el 2 en x > 0; cada medio campo mide Half de largo.
--
-- El balón vuela (gravedad suave), choca con la red y, cuando toca la arena, el punto es para quien no
-- tenía que dejarlo caer. Cada equipo da como mucho 3 toques. El que golpea elige solo el golpe según
-- dónde está: recibir (bajo), colocar (al compañero, alto junto a la red) o rematar (en el aire, cerca
-- de la red y por encima de ella). Las personas golpean con un botón y la calidad depende de cuándo:
-- a la altura buena del golpe sale perfecto; tarde o pronto, el balón se va torcido (a la red o fuera).
-- Saque: desde detrás de la línea, hacia donde apuntas. Partido a Points puntos (por defecto, 7).

local VolleySim = {}

export type Sim = { [string]: any }

VolleySim.Config = {
	Tick = 1 / 30,
	Gravity = 46,
	Drag = 0.05,
	Radius = 0.9,
	Reach = 3.4, -- alcance horizontal para tocar el balón
	ReachHigh = 9.5, -- altura máxima del balón para tocarlo (saltando)
	SpikeHeight = 6.5, -- por encima, junto a la red, se remata
	NetGap = 6, -- a menos de esto de la red se coloca/remata
	PointPause = 2.2,
	ServeToss = 1.3, -- segundos que tarda el saque si nadie saca (la máquina, o la persona: sale solo)
	ServeTimeout = 12,
	BotSpeed = 15,
}
local CFG = VolleySim.Config

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
end

function VolleySim.new(opts: { [string]: any }?): Sim
	local o = opts or {}
	return {
		Half = o.Half or 16,
		Width = o.Width or 16,
		NetHeight = o.NetHeight or 7.5,
		Points = o.Points or 7,
		Duration = o.Duration or 360,
		Scale = o.Scale or 1,
		BotSpeed = o.BotSpeed or CFG.BotSpeed,
		Rng = o.Rng or Random.new(o.Seed or 1),
		T = 0,
		Phase = "Idle",
		PhaseUntil = 0,
		Score = { [1] = 0, [2] = 0 },
		Players = {},
		Order = {},
		Ball = { P = Vector3.new(0, 5, 0), V = Vector3.zero },
		Touches = 0,
		TouchTeam = 0,
		LastTouch = nil :: string?,
		Server = nil :: string?,
		ServeTeam = 1,
		Events = {},
		Over = false,
		Accumulator = 0,
		Seq = 0,
	}
end

function VolleySim.addPlayer(sim: Sim, spec: { [string]: any })
	local p = {
		Id = spec.Id,
		Name = spec.Name or spec.Id,
		Npc = spec.Npc,
		Team = spec.Team or 1,
		Human = spec.Human == true,
		Skill = math.clamp(spec.Skill or 0.5, 0, 1),
		P = spec.P or Vector3.zero,
		V = Vector3.zero,
		Facing = Vector3.new(if (spec.Team or 1) == 1 then 1 else -1, 0, 0),
		Jump = 0,
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

local function side(team: number): number
	return if team == 1 then -1 else 1
end
VolleySim.side = side

function VolleySim.setHuman(sim: Sim, id: string, p: Vector3, v: Vector3?, facing: Vector3?)
	local h = sim.Players[id]
	if not h then
		return
	end
	h.P = Vector3.new(p.X, 0, p.Z)
	h.V = flat(v or Vector3.zero)
	if facing and flat(facing).Magnitude > 0.1 then
		h.Facing = flat(facing).Unit
	end
end

---------------------------------------------------------------------
-- El balón
---------------------------------------------------------------------

-- Un paso del balón. Devuelve "Ground" si toca la arena, "Net" si da en la red.
local function stepBall(sim: Sim, dt: number): string?
	local b = sim.Ball
	local before = b.P
	b.V = (b.V + Vector3.new(0, -CFG.Gravity, 0) * dt) * math.exp(-CFG.Drag * dt)
	b.P = b.P + b.V * dt
	local hit: string? = nil
	-- La red: un plano en x = 0 hasta NetHeight (y la cinta de arriba)
	if math.sign(before.X) ~= math.sign(b.P.X) and math.abs(b.P.Z) <= sim.Width / 2 + 1 then
		local f = before.X / (before.X - b.P.X)
		local y = before.Y + (b.P.Y - before.Y) * f
		if y < sim.NetHeight + CFG.Radius * 0.5 then
			b.P = Vector3.new(math.sign(before.X) * CFG.Radius, b.P.Y, b.P.Z)
			b.V = Vector3.new(-b.V.X * 0.25, b.V.Y * 0.6, b.V.Z * 0.6)
			hit = "Net"
		end
	end
	if b.P.Y <= CFG.Radius then
		b.P = Vector3.new(b.P.X, CFG.Radius, b.P.Z)
		b.V = Vector3.zero
		return "Ground"
	end
	return hit
end

-- Dónde cae (a la altura `height`) y cuándo, simulando
function VolleySim.landing(sim: Sim, height: number, maxT: number?): (number?, Vector3?)
	local b = sim.Ball
	local p, v = b.P, b.V
	local t, h = 0, 1 / 30
	while t < (maxT or 4) do
		local before = p
		v = (v + Vector3.new(0, -CFG.Gravity, 0) * h) * math.exp(-CFG.Drag * h)
		p = p + v * h
		t += h
		if before.Y >= height and p.Y < height and v.Y < 0 then
			return t, p
		end
	end
	return nil, nil
end

-- La velocidad para llevar el balón de `from` a `to` con el punto más alto `apex` (sin rozamiento:
-- se compensa un poco aparte)
local function lob(from: Vector3, to: Vector3, apex: number): Vector3
	local g = CFG.Gravity
	local top = math.max(apex, from.Y + 0.5, to.Y + 0.5)
	local up = math.sqrt(2 * g * (top - from.Y))
	local t = up / g + math.sqrt(2 * (top - to.Y) / g)
	local horizontal = flat(to - from) / t
	return (horizontal * (1 + CFG.Drag * t * 0.5)) + Vector3.new(0, up * (1 + CFG.Drag * t * 0.12), 0)
end
VolleySim.lob = lob

---------------------------------------------------------------------
-- Golpes
---------------------------------------------------------------------

-- ¿Puede tocarlo ahora este jugador? (y a qué distancia)
function VolleySim.canHit(sim: Sim, p: any): (boolean, number)
	local b = sim.Ball
	if sim.Phase ~= "Rally" or sim.T < p.Cd then
		return false, math.huge
	end
	if side(p.Team) * b.P.X < -1 then
		return false, math.huge -- (está en el otro campo)
	end
	if sim.TouchTeam == p.Team and sim.Touches >= 3 then
		return false, math.huge
	end
	if sim.LastTouch == p.Id and sim.TouchTeam == p.Team then
		return false, math.huge -- (no se toca dos veces seguidas)
	end
	local s = sim.Scale
	local d = fdist(b.P, p.P)
	local high = b.P.Y <= CFG.ReachHigh * s and b.P.Y >= 0.8
	return d <= CFG.Reach * s and high, d
end

-- Qué golpe toca ahora: "Remate", "Colocar" o "Recibir"
function VolleySim.shotKind(sim: Sim, p: any): string
	local b = sim.Ball
	local nearNet = math.abs(p.P.X) < CFG.NetGap * math.max(sim.Scale, 0.8)
	-- (solo se remata por encima de la red: desde abajo iría a la red)
	if nearNet and b.P.Y >= math.max(CFG.SpikeHeight * sim.Scale, sim.NetHeight - 0.3) and (sim.TouchTeam ~= p.Team or sim.Touches >= 1) then
		return "Remate"
	end
	if sim.TouchTeam == p.Team and sim.Touches == 1 then
		return "Colocar"
	end
	return "Recibir"
end

-- La calidad del toque según la altura del balón (la persona: 1 = en su punto)
function VolleySim.quality(sim: Sim, p: any, kind: string): number
	local ideal = if kind == "Remate" then sim.NetHeight / math.max(sim.Scale, 0.6) + 1 elseif kind == "Colocar" then 4.5 else 3
	local y = sim.Ball.P.Y / math.max(sim.Scale, 0.6)
	local miss = math.abs(y - ideal)
	return math.clamp(1 - math.max(0, miss - 0.8) * 0.28, 0.1, 1)
end

-- Golpea. aim: punto (en el suelo, coordenadas de la pista) adonde quiere mandarlo (opcional)
function VolleySim.hit(sim: Sim, id: string, aim: Vector3?, quality: number?): (boolean, string?)
	local p = sim.Players[id]
	if not p then
		return false, "NoPlayer"
	end
	local can = VolleySim.canHit(sim, p)
	if not can then
		return false, "Far"
	end
	local kind = VolleySim.shotKind(sim, p)
	local q = quality or (if p.Human then VolleySim.quality(sim, p, kind) else 0.55 + 0.45 * p.Skill)
	local b = sim.Ball
	local s = side(p.Team)
	local other = -s
	local rng = sim.Rng
	local target: Vector3
	local v: Vector3
	if kind == "Remate" then
		-- Hacia el campo rival, fuerte y hacia abajo
		target = aim or Vector3.new(other * (sim.Half * (0.35 + 0.5 * rng:NextNumber())), 0, (rng:NextNumber() * 2 - 1) * sim.Width * 0.4)
		if math.sign(target.X) ~= other then
			target = Vector3.new(other * math.abs(target.X), 0, target.Z)
		end
		local dir = flat(target - b.P)
		local d = dir.Magnitude
		local speed = 34 + 10 * q
		local t = d / speed
		local vy = (target.Y + CFG.Radius - b.P.Y + 0.5 * CFG.Gravity * t * t) / math.max(t, 0.05)
		local unit = if d > 1e-3 then dir.Unit else Vector3.new(other, 0, 0)
		local horizontal = unit * speed
		-- Que pase por encima de la red: si la línea recta no la salva, la parábola que pasa justo por
		-- encima de la cinta y cae en el mismo sitio (más bombeada y algo más lenta)
		if math.abs(unit.X) > 1e-3 then
			local xn = math.abs(b.P.X) / math.abs(unit.X)
			local tn = xn / speed
			local need = sim.NetHeight + CFG.Radius + 0.7
			local atNet = b.P.Y + vy * tn - 0.5 * CFG.Gravity * tn * tn
			if atNet < need and d > xn + 0.5 then
				local y0 = b.P.Y
				-- y(x) = y0 + a x - c x²  con y(xn) = need, y(d) = radio
				local det = xn * (-d * d) - d * (-xn * xn)
				local a = ((need - y0) * (-d * d) - (CFG.Radius - y0) * (-xn * xn)) / det
				local c = -(xn * (CFG.Radius - y0) - d * (need - y0)) / det
				if c > 1e-4 then
					local vh = math.sqrt(CFG.Gravity / (2 * c))
					horizontal = unit * vh
					vy = a * vh
				end
			end
		end
		v = horizontal + Vector3.new(0, vy, 0)
		p.Jump = sim.T + 0.5
	elseif kind == "Colocar" then
		-- Alto, junto a la red, para el compañero (o para sí si no hay)
		local mate = nil
		for _, oid in sim.Order do
			local o = sim.Players[oid]
			if o.Team == p.Team and o ~= p then
				mate = o
			end
		end
		local z = if mate then math.clamp(mate.P.Z, -sim.Width * 0.35, sim.Width * 0.35) else 0
		target = Vector3.new(s * 2.2, 0, z)
		v = lob(b.P, target + Vector3.new(0, sim.NetHeight + 1.2, 0), sim.NetHeight + 5)
		sim.SetFor = if mate then mate.Id else nil
	else
		-- Recibir: hacia la zona del colocador (o pasar al otro lado si es el tercer toque)
		if sim.TouchTeam == p.Team and sim.Touches >= 2 then
			target = aim or Vector3.new(other * sim.Half * 0.6, 0, (rng:NextNumber() * 2 - 1) * sim.Width * 0.3)
			v = lob(b.P, target, sim.NetHeight + 4)
		else
			target = Vector3.new(s * 3.5, 0, 0)
			v = lob(b.P, target + Vector3.new(0, 4 * sim.Scale, 0), (CFG.SpikeHeight + 3) * sim.Scale)
		end
	end
	-- Error según la calidad: dirección y fuerza
	local err = (1 - q)
	local lateral = (rng:NextNumber() * 2 - 1) * err * 0.45
	local power = 1 + (rng:NextNumber() * 2 - 1) * err * 0.35
	local fv = flat(v)
	local right = if fv.Magnitude > 1e-3 then Vector3.new(-fv.Z, 0, fv.X).Unit else Vector3.new(0, 0, 1)
	v = fv * power + right * fv.Magnitude * lateral + Vector3.new(0, v.Y * (1 + (power - 1) * 0.5), 0)
	b.V = v
	if sim.TouchTeam == p.Team then
		sim.Touches += 1
	else
		sim.TouchTeam = p.Team
		sim.Touches = 1
	end
	sim.LastTouch = id
	p.Cd = sim.T + 0.35
	sim.Seq += 1
	event(sim, "Hit", { Id = id, Type = kind, Quality = q, P = b.P, V = v, Seq = sim.Seq })
	return true
end

---------------------------------------------------------------------
-- Saque, puntos
---------------------------------------------------------------------

local function serverOf(sim: Sim, team: number): any
	-- Se turnan los dos del equipo
	sim.ServeCount = sim.ServeCount or { [1] = 0, [2] = 0 }
	sim.ServeCount[team] += 1
	local list = {}
	for _, id in sim.Order do
		if sim.Players[id].Team == team then
			table.insert(list, sim.Players[id])
		end
	end
	if #list == 0 then
		return nil
	end
	return list[(sim.ServeCount[team] - 1) % #list + 1]
end

local function setupServe(sim: Sim, team: number)
	local p = serverOf(sim, team)
	sim.ServeTeam = team
	sim.Server = p and p.Id
	sim.Touches = 0
	sim.TouchTeam = 0
	sim.LastTouch = nil
	sim.SetFor = nil
	local s = side(team)
	for _, id in sim.Order do
		local o = sim.Players[id]
		local home = Vector3.new(side(o.Team) * sim.Half * (if o.Index == 1 then 0.35 else 0.65), 0, (if o.Index == 1 then -1 else 1) * sim.Width * 0.22)
		o.Target = home
		if not o.Human then
			o.P = home
		end
		event(sim, "Teleport", { Id = id, P = home, Facing = Vector3.new(-side(o.Team), 0, 0), Bot = not o.Human })
	end
	if p then
		local spot = Vector3.new(s * (sim.Half + 1.5), 0, 0)
		p.P = spot
		p.Target = spot
		event(sim, "Teleport", { Id = p.Id, P = spot, Facing = Vector3.new(-s, 0, 0), Bot = not p.Human })
		sim.Ball.P = spot + Vector3.new(-s * 0.8, 4 * sim.Scale, 0)
		sim.Ball.V = Vector3.zero
	end
	sim.Phase = "Serve"
	sim.PhaseUntil = sim.T + (if p and p.Human then CFG.ServeTimeout else CFG.ServeToss)
	event(sim, "Serve", { Id = sim.Server, Team = team })
end

-- Sacar (persona o máquina): hacia aim (suelo del campo rival) o al centro del campo rival
function VolleySim.serve(sim: Sim, id: string, aim: Vector3?, quality: number?): boolean
	if sim.Phase ~= "Serve" or sim.Server ~= id then
		return false
	end
	local p = sim.Players[id]
	local other = -side(p.Team)
	local q = quality or (0.6 + 0.4 * p.Skill)
	local target = aim or Vector3.new(other * sim.Half * (0.4 + 0.4 * sim.Rng:NextNumber()), 0, (sim.Rng:NextNumber() * 2 - 1) * sim.Width * 0.35)
	if math.sign(target.X) ~= other then
		target = Vector3.new(other * math.abs(target.X), 0, target.Z)
	end
	local b = sim.Ball
	local v = lob(b.P, target, sim.NetHeight + 5)
	local err = 1 - q
	v = Vector3.new(v.X * (1 + (sim.Rng:NextNumber() * 2 - 1) * err * 0.3), v.Y, v.Z + (sim.Rng:NextNumber() * 2 - 1) * err * 6)
	b.V = v
	sim.TouchTeam = p.Team
	sim.Touches = 3 -- (el saque cuenta como todos los toques: lo siguiente es del rival)
	sim.LastTouch = id
	p.Cd = sim.T + 0.4
	sim.Seq += 1
	sim.Phase = "Rally"
	event(sim, "Hit", { Id = id, Type = "Saque", Quality = q, P = b.P, V = v, Seq = sim.Seq })
	return true
end

local function finish(sim: Sim)
	if sim.Over then
		return
	end
	sim.Over = true
	sim.Phase = "Over"
	event(sim, "Over", VolleySim.outcome(sim))
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
	sim.NextServe = team
end

function VolleySim.start(sim: Sim)
	sim.Over = false
	setupServe(sim, 1)
end

function VolleySim.outcome(sim: Sim): { [string]: any }
	return { Mode = "Voley", Goals = sim.Score[1], Against = sim.Score[2], Over = sim.Over }
end

---------------------------------------------------------------------
-- Máquinas
---------------------------------------------------------------------

local function think(sim: Sim)
	local b = sim.Ball
	local _, land = VolleySim.landing(sim, 2.5 * sim.Scale, 4)
	for _, id in sim.Order do
		local p = sim.Players[id]
		if p.Human then
			continue
		end
		local s = side(p.Team)
		if sim.Phase == "Serve" then
			if sim.Server == id and sim.T >= sim.PhaseUntil then
				VolleySim.serve(sim, id)
			end
			continue
		end
		if sim.Phase ~= "Rally" then
			continue
		end
		-- ¿Viene a nuestro campo? El más cercano a donde cae va (si la persona está más cerca, la deja)
		local ours = land ~= nil and s * land.X > 0
		if ours and land then
			local mine, best = nil, math.huge
			for _, oid in sim.Order do
				local o = sim.Players[oid]
				if o.Team == p.Team and not (sim.LastTouch == oid and sim.TouchTeam == p.Team) then
					local d = fdist(o.P, land) - (if o.Human then 1.5 else 0)
					if sim.SetFor == oid and sim.TouchTeam == p.Team then
						d -= 4
					end
					if d < best then
						mine, best = o, d
					end
				end
			end
			if mine == p then
				p.Target = land
			else
				p.Target = Vector3.new(s * sim.Half * 0.5, 0, -land.Z * 0.5)
			end
		else
			-- Defensa: uno delante, otro atrás
			p.Target = Vector3.new(s * sim.Half * (if p.Index == 1 then 0.3 else 0.65), 0, (if p.Index == 1 then -1 else 1) * sim.Width * 0.2)
		end
		-- Golpear si le llega (a la altura buena, con su nivel)
		local can = VolleySim.canHit(sim, p)
		if can and b.V.Y < 3 then
			local kind = VolleySim.shotKind(sim, p)
			local ideal = if kind == "Remate" then sim.NetHeight + 1 else 3.2 * sim.Scale
			if b.P.Y <= ideal + 1 or kind == "Remate" then
				VolleySim.hit(sim, id)
			end
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
		local speed = sim.BotSpeed * (0.85 + 0.3 * p.Skill)
		if d > 0.2 then
			local step = math.min(d, speed * dt)
			p.P = p.P + to.Unit * step
			p.V = to.Unit * (step / dt)
		else
			p.V = Vector3.zero
		end
		local s = side(p.Team)
		-- Cada uno en su campo
		p.P = Vector3.new(if s < 0 then math.min(p.P.X, -0.8) else math.max(p.P.X, 0.8), 0, p.P.Z)
		p.Facing = Vector3.new(-s, 0, 0)
	end
end

local function tick(sim: Sim, dt: number)
	sim.T += dt
	if sim.Phase == "Idle" or sim.Phase == "Over" then
		return
	end
	if sim.T - (sim.StartT or 0) > sim.Duration and not sim.Over then
		finish(sim)
		return
	end
	think(sim)
	moveBots(sim, dt)
	if sim.Phase == "Serve" then
		-- La persona que no saca: al rato, sale solo (la historia nunca se para)
		if sim.T >= sim.PhaseUntil and sim.Server and sim.Players[sim.Server] and sim.Players[sim.Server].Human then
			VolleySim.serve(sim, sim.Server, nil, 0.7)
		end
		return
	end
	if sim.Phase == "Point" then
		if sim.T >= sim.PhaseUntil then
			setupServe(sim, sim.NextServe or 1)
		end
		return
	end
	local b = sim.Ball
	local hit = stepBall(sim, dt)
	if hit == "Net" then
		event(sim, "Net", {})
	elseif hit == "Ground" then
		-- ¿Dentro o fuera? Dentro: punto para el otro campo; fuera: punto contra quien lo tocó
		local inside = math.abs(b.P.X) <= sim.Half + 0.5 and math.abs(b.P.Z) <= sim.Width / 2 + 0.5
		local landedSide = if b.P.X < 0 then 1 else 2
		local last = sim.LastTouch and sim.Players[sim.LastTouch]
		if inside then
			point(sim, 3 - landedSide, "Suelo")
		else
			point(sim, if last then 3 - last.Team else 3 - landedSide, "Fuera")
		end
		event(sim, "Land", { P = b.P, Inside = inside })
	end
	-- Cuatro toques: falta
	if sim.Phase == "Rally" and sim.Touches > 3 and sim.TouchTeam ~= 0 then
		point(sim, 3 - sim.TouchTeam, "Toques")
	end
end

function VolleySim.step(sim: Sim, dt: number): { { [string]: any } }
	if sim.StartT == nil then
		sim.StartT = sim.T
	end
	sim.Accumulator += math.clamp(dt, 0, 0.25)
	while sim.Accumulator >= CFG.Tick do
		sim.Accumulator -= CFG.Tick
		tick(sim, CFG.Tick)
	end
	local out = sim.Events
	sim.Events = {}
	return out
end

return VolleySim
