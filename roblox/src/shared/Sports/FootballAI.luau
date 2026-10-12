-- FootballAI (compartido): lo que deciden los jugadores que no son personas (compañeros, rivales y
-- porteros) en Sports/FootballSim. Sin nada de Roblox: se prueba en scripts/test-futbol.luau.
--
--   Formaciones (3 contra 3, 5 contra 5…) y sitio de cada uno según dónde está el balón.
--   Sin balón: el más cercano de cada equipo va a por él (a donde VA a estar), los demás se colocan.
--   Defendiendo: uno presiona al que lleva el balón e intenta entrarle; otro cubre.
--   Con balón: tira si está cerca y tiene ángulo, pasa si le aprietan y hay un compañero libre (a
--   las personas se les pasa más: es más divertido), y si no, conduce hacia la portería esquivando.
--   Portero: se coloca entre el balón y el centro de la portería, sale a por balones sueltos en su
--   área y, cuando le chutan, se estira hacia donde cree que va (reacción y error según su nivel y
--   la fuerza y colocación del tiro: puede parar o no).

local Pitch = require(script.Parent.Pitch)
local Ball = require(script.Parent.Ball)

local FootballAI = {}

-- Formaciones (x: fracción de la mitad del campo hacia la portería rival, z: fracción del ancho)
FootballAI.Formations = {
	[1] = { { "GK", -0.93, 0 } },
	[2] = { { "GK", -0.93, 0 }, { "FW", 0.05, 0 } },
	[3] = { { "GK", -0.93, 0 }, { "DF", -0.45, 0.1 }, { "FW", 0.2, -0.1 } },
	[4] = { { "GK", -0.93, 0 }, { "DF", -0.5, 0 }, { "MF", -0.05, -0.4 }, { "FW", 0.25, 0.3 } },
	[5] = { { "GK", -0.93, 0 }, { "DF", -0.55, -0.4 }, { "DF", -0.55, 0.4 }, { "MF", -0.1, 0 }, { "FW", 0.3, 0 } },
	[6] = { { "GK", -0.93, 0 }, { "DF", -0.55, -0.4 }, { "DF", -0.55, 0.4 }, { "MF", -0.1, -0.2 }, { "FW", 0.3, 0.35 }, { "FW", 0.3, -0.45 } },
}

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end
local function dist2(a: Vector3, b: Vector3): number
	local dx, dz = a.X - b.X, a.Z - b.Z
	return math.sqrt(dx * dx + dz * dz)
end
FootballAI.flatDistance = dist2

-- Dirección de ataque del equipo (el 1 ataca hacia +X)
function FootballAI.attack(team: number): number
	return if team == 2 then -1 else 1
end

-- Sitio de la formación en el campo (local)
function FootballAI.slotPosition(pitch: Pitch.Pitch, team: number, slot: { any }): Vector3
	local a = FootballAI.attack(team)
	return Vector3.new(slot[2] * pitch.GoalLine * a, 0, slot[3] * pitch.Width / 2)
end

-- Sitio para el saque de centro (cada uno en su campo)
function FootballAI.kickoffPosition(pitch: Pitch.Pitch, team: number, slot: { any }): Vector3
	local a = FootballAI.attack(team)
	local x = math.min(slot[2], -0.08) * pitch.GoalLine
	if slot[1] == "FW" then
		x = math.min(x, -0.12 * pitch.GoalLine)
	end
	return Vector3.new(x * a, 0, slot[3] * pitch.Width / 2 * 0.8)
end

-- Dónde estaría bien estar ahora (sin ir a por el balón): la formación desplazada con el balón
function FootballAI.homeSpot(sim: any, p: any): Vector3
	local pitch = sim.Pitch
	local a = FootballAI.attack(p.Team)
	local base = FootballAI.slotPosition(pitch, p.Team, p.Slot)
	local ball = sim.Ball.P
	local owner = sim.Owner and sim.Players[sim.Owner]
	local ours = owner ~= nil and owner.Team == p.Team
	local theirs = owner ~= nil and owner.Team ~= p.Team
	local shiftX = math.clamp(ball.X * 0.55, -pitch.GoalLine * 0.45, pitch.GoalLine * 0.45)
	local push = if ours then pitch.GoalLine * 0.18 * a elseif theirs then -pitch.GoalLine * 0.12 * a else 0
	local x = base.X + shiftX + push
	local z = base.Z + (ball.Z - base.Z) * 0.3
	-- Los defensas no pasan mucho del centro; los delanteros no bajan a su área
	if p.Role == "DF" then
		x = if a > 0 then math.min(x, pitch.GoalLine * 0.15) else math.max(x, -pitch.GoalLine * 0.15)
	elseif p.Role == "FW" then
		x = if a > 0 then math.max(x, -pitch.GoalLine * 0.35) else math.min(x, pitch.GoalLine * 0.35)
	end
	return Pitch.clampInside(pitch, Vector3.new(x, 0, z), 2)
end

-- Tiempo que tarda en llegar a un punto (para decidir quién va a por el balón)
local function reachTime(p: any, point: Vector3): number
	return dist2(p.P, point) / math.max(p.MaxSpeed, 1)
end

-- Dónde cortar un balón suelto: el primer punto de su trayectoria al que llega a tiempo
function FootballAI.interceptPoint(sim: any, p: any): Vector3
	local path = sim.Path
	if path and #path > 0 then
		for i, point in path do
			local t = i / 30
			if point.Y < 2.6 and reachTime(p, point) <= t + 0.15 then
				return point
			end
		end
		return path[#path]
	end
	return sim.Ball.P
end

-- ¿Quién de cada equipo va a por el balón suelto? (el que antes llega; las personas cuentan: si el
-- más cercano de tu equipo eres tú, los compañeros no te lo quitan)
function FootballAI.chasers(sim: any): { [number]: string }
	local best: { [number]: { Id: string, T: number } } = {}
	for _, id in sim.Order do
		local p = sim.Players[id]
		if p.Role == "GK" and not Pitch.inArea(sim.Pitch, sim.Ball.P, -FootballAI.attack(p.Team)) then
			continue
		end
		if sim.T < p.Stun then
			continue
		end
		local t = reachTime(p, FootballAI.interceptPoint(sim, p))
		if p.Human then
			t -= 0.3 -- (ventaja: el compañero no te quita el balón por un pelo)
		end
		local cur = best[p.Team]
		if not cur or t < cur.T then
			best[p.Team] = { Id = id, T = t }
		end
	end
	local out = {}
	for team, b in best do
		out[team] = b.Id
	end
	return out
end

---------------------------------------------------------------------
-- Con el balón
---------------------------------------------------------------------

-- Rival más cercano a un punto (y a qué distancia)
function FootballAI.nearestOpponent(sim: any, team: number, point: Vector3): (any, number)
	local best, bestD = nil, math.huge
	for _, id in sim.Order do
		local q = sim.Players[id]
		if q.Team ~= team and q.Team ~= 0 then
			local d = dist2(q.P, point)
			if d < bestD then
				best, bestD = q, d
			end
		end
	end
	return best, bestD
end

-- Distancia de un punto al segmento a→b (en plano)
local function laneDistance(a: Vector3, b: Vector3, q: Vector3): number
	local c = Ball.closestOnSegment(flat(a), flat(b), flat(q))
	return (flat(q) - c).Magnitude
end

-- Lo libre que está el pase de p a mate (la menor distancia de un rival a la línea o al compañero)
function FootballAI.passOpenness(sim: any, p: any, mate: any): number
	local open = math.huge
	for _, id in sim.Order do
		local q = sim.Players[id]
		if q.Team ~= p.Team and q.Team ~= 0 then
			open = math.min(open, laneDistance(p.P, mate.P, q.P) + 0.5, dist2(q.P, mate.P))
		end
	end
	return open
end

-- El mejor compañero para pasar (o nil): adelantado, libre, a buena distancia; a las personas, más
function FootballAI.bestPass(sim: any, p: any): (any, number)
	local a = FootballAI.attack(p.Team)
	local best, bestScore = nil, -math.huge
	for _, id in sim.Order do
		local mate = sim.Players[id]
		if mate == p or mate.Team ~= p.Team or sim.T < mate.Stun then
			continue
		end
		local d = dist2(p.P, mate.P)
		if d < 5 or d > 48 then
			continue
		end
		local open = FootballAI.passOpenness(sim, p, mate)
		if open < 2.4 then
			continue
		end
		local forward = (mate.P.X - p.P.X) * a
		local score = forward * 0.35 + math.min(open, 10) * 1.2 - d * 0.12
		if mate.Human then
			score += 5
		end
		if mate.Role == "GK" then
			score -= 8
		end
		if score > bestScore then
			best, bestScore = mate, score
		end
	end
	return best, bestScore
end

-- Lo que hace quien lleva el balón. Devuelve una acción:
--   { Kind = "Shoot", Dir, Power, Curl } | { Kind = "Pass", To, Dir, Dist } | { Kind = "Dribble", Target }
function FootballAI.carrierDecision(sim: any, p: any, rng: any): { [string]: any }
	local pitch = sim.Pitch
	local a = FootballAI.attack(p.Team)
	local goal = Pitch.goalCenter(pitch, a)
	local toGoal = flat(goal - p.P)
	local dist = toGoal.Magnitude
	local _, press = FootballAI.nearestOpponent(sim, p.Team, p.P)
	local shootRange = math.min(30, pitch.GoalLine * 0.72)
	local inArea = Pitch.inArea(pitch, p.P, a)
	-- Tirar
	local shootChance = if inArea then 0.55 + 0.3 * p.Skill else 0.06 + 0.22 * (1 - dist / shootRange)
	if p.Role ~= "GK" and dist < shootRange and rng:NextNumber() < shootChance then
		local keeper = sim.Keepers and sim.Keepers[-a] and sim.Players[sim.Keepers[-a]]
		local keeperZ = if keeper then keeper.P.Z else 0
		local postSide = if keeperZ > 0.3 then -1 elseif keeperZ < -0.3 then 1 else (if rng:NextNumber() < 0.5 then -1 else 1)
		local aimZ = postSide * (pitch.GoalWidth / 2 - 1.1) * (0.55 + 0.45 * rng:NextNumber())
		-- Error según el nivel (y algo más de lejos)
		local spread = (1.3 - p.Skill) * (1.6 + dist / 11)
		aimZ += (rng:NextNumber() * 2 - 1) * spread
		local target = Vector3.new(goal.X, 0, aimZ)
		local power = math.clamp(0.38 + dist / 70 + rng:NextNumber() * 0.2, 0.4, 0.85)
		return { Kind = "Shoot", Dir = flat(target - p.P), Power = power, Curl = 0 }
	end
	-- Pasar
	local mate, score = FootballAI.bestPass(sim, p)
	local pressured = press < 4.5
	if mate and (pressured and rng:NextNumber() < 0.85 or score > 6 and rng:NextNumber() < 0.18 or p.Role == "GK") then
		local lead = mate.P + flat(mate.V) * 0.35
		local d = dist2(p.P, lead)
		return { Kind = "Pass", To = mate.Id, Dir = flat(lead - p.P), Dist = d }
	end
	if p.Role == "GK" then
		-- Sin nadie libre: patadón hacia arriba
		return { Kind = "Shoot", Dir = Vector3.new(a, 0, (rng:NextNumber() * 2 - 1) * 0.4), Power = 0.7, Loft = 0.6, Curl = 0 }
	end
	-- Conducir: hacia la portería, apartándose del rival que aprieta
	local dir = if dist > 1e-3 then toGoal.Unit else Vector3.new(a, 0, 0)
	local opp, d = FootballAI.nearestOpponent(sim, p.Team, p.P + dir * 3)
	if opp and d < 7 then
		local away = flat(p.P - opp.P)
		local side = Vector3.new(-dir.Z, 0, dir.X)
		local sign = if away:Dot(side) >= 0 then 1 else -1
		dir = (dir + side * sign * 0.9)
		dir = if dir.Magnitude > 1e-3 then dir.Unit else side
	end
	-- Cerca de la banda: hacia dentro
	if math.abs(p.P.Z) > pitch.Width / 2 - 4 then
		dir = (dir + Vector3.new(0, 0, -math.sign(p.P.Z) * 0.8)).Unit
	end
	return { Kind = "Dribble", Target = Pitch.clampInside(pitch, p.P + dir * 7, 1.5) }
end

---------------------------------------------------------------------
-- Portero
---------------------------------------------------------------------

-- Dónde se pone: entre el balón y el centro de su portería
function FootballAI.keeperSpot(sim: any, p: any): Vector3
	local pitch = sim.Pitch
	local side = -FootballAI.attack(p.Team)
	local goal = Pitch.goalCenter(pitch, side)
	local toBall = flat(sim.Ball.P - goal)
	local d = toBall.Magnitude
	local out = math.clamp(d * 0.14, 1.2, 4.5)
	local spot = if d > 1e-3 then goal + toBall.Unit * out else goal + Vector3.new(-side * out, 0, 0)
	local hw = pitch.GoalWidth / 2 - 0.8
	return Vector3.new(
		if side > 0 then math.min(spot.X, pitch.GoalLine - 0.6) else math.max(spot.X, -pitch.GoalLine + 0.6),
		0,
		math.clamp(spot.Z, -hw, hw)
	)
end

-- Estirada ante un tiro. Devuelve el plan { Start, Dur, From, Target, Seq } o nil si no hace falta.
--   react: tiempo de reacción; el error crece con la fuerza del tiro y baja con el nivel.
--   penalty: en un penalti el portero adivina el lado al golpeo (acierta más con más nivel).
function FootballAI.keeperDive(sim: any, p: any, rng: any, penalty: boolean?): { [string]: any }?
	local pitch = sim.Pitch
	local side = -FootballAI.attack(p.Team)
	local ball = sim.Ball
	local towards = ball.V.X * side
	if towards < 6 then
		return nil
	end
	-- Dónde cruzará por delante de él (si ya está bajo palos, en la línea)
	local lineX = side * (pitch.GoalLine - 0.3)
	local planeX = if penalty then lineX else (if side > 0 then math.min(p.P.X, lineX) else math.max(p.P.X, lineX))
	local t, cross = Ball.crossX(ball, pitch, planeX, 2.2)
	if not t or not cross then
		return nil
	end
	local hw, gh = pitch.GoalWidth / 2, pitch.GoalHeight
	if math.abs(cross.Z) > hw + 2.2 or cross.Y > gh + 1.6 then
		return nil -- (va fuera: lo deja ir)
	end
	local speed = ball.V.Magnitude
	local skill = p.Skill
	local target: Vector3
	local react: number
	if penalty then
		-- Adivina al golpeo: con más nivel acierta el lado más a menudo
		-- (el portero se mueve un instante antes del golpeo: empieza con ventaja)
		react = -0.12 + (1 - skill) * 0.05
		local guessRight = rng:NextNumber() < 0.3 + 0.3 * skill
		local z = cross.Z
		if not guessRight then
			if math.abs(z) < 1.4 and rng:NextNumber() < 0.5 then
				-- (se queda en el centro: el tiro flojo al medio le da en el cuerpo)
				z = 0
			elseif math.abs(z) < 1.4 then
				z = (if rng:NextNumber() < 0.5 then -1 else 1) * hw * 0.7 -- se tira y el balón va al centro
			else
				z = -z * (0.5 + 0.4 * rng:NextNumber()) -- se tira al otro lado
			end
		end
		target = Vector3.new(lineX, math.clamp(cross.Y + (rng:NextNumber() - 0.5) * 1.2, 0.8, gh - 0.4), z)
	else
		-- (lee el cuerpo del que chuta: un buen portero ya se está moviendo al golpeo)
		react = -0.06 + (1 - skill) * 0.12 + math.clamp((speed - 60) / 300, 0, 0.05) + rng:NextNumber() * 0.08
		local err = (rng:NextNumber() * 2 - 1) * (0.6 + speed / 60) * (1.3 - skill)
		target = Vector3.new(planeX, math.clamp(cross.Y + (rng:NextNumber() - 0.5) * 0.8, 0.8, gh - 0.4), cross.Z + err)
	end
	-- Un balón que le llega casi al cuerpo: no se tira, da un paso
	local dz = math.abs(target.Z - p.P.Z)
	local dur = if dz < 1.3 and target.Y < 3.4 then 0.22 elseif penalty then 0.4 else 0.2
	return { Start = sim.T + react, Dur = dur, From = Vector3.new(p.P.X, 0, p.P.Z), Target = target, Seq = sim.KickSeq, Arrive = sim.T + t }
end

-- Las manos del portero en una estirada (para los choques del balón): segmento y radio
function FootballAI.diveBody(p: any, T: number): (Vector3?, Vector3?, number)
	local dive = p.Dive
	if not dive then
		return nil, nil, 0
	end
	local scale = p.Scale or 1
	local f = math.clamp((T - dive.Start) / dive.Dur, 0, 1)
	f = f * f * (3 - 2 * f)
	local chest = dive.From + Vector3.new(0, 2.3 * scale, 0)
	local reach = (3.6 + 1.6 * p.Skill) * scale
	local toTarget = dive.Target - chest
	if toTarget.Magnitude > reach then
		toTarget = toTarget.Unit * reach
	end
	local hands = chest + toTarget * f
	local feet = dive.From + Vector3.new(0, 0.4, 0) + flat(toTarget) * f * 0.45
	return feet, hands, 1.0 * scale
end

return FootballAI
