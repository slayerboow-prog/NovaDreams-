-- AlienAI: cómo piensan las tropas alienígenas de TIERRA (cuentas puras: las usa InvasionService
-- en el servidor y las prueba scripts/test-invasion.luau). Las naves usan shared/AirCombat/EnemyAI.
--
-- Prioridades de cada alienígena (de más a menos):
--   1. Un jugador a tiro de alerta (o el que le acaba de disparar, aunque esté algo más lejos):
--      va a por él y le ataca (cuerpo a cuerpo los soldados y pesados; de lejos los tiradores y la
--      élite). Los tiradores mantienen la distancia y se apartan si te les echas encima.
--   2. Un alienígena de una raza RIVAL cerca (si vinieron varias razas que se odian): a veces se pegan.
--   3. Un vecino de Valmar cerca (los soldados y pesados): lo «alcanzan» y se TRANSFORMA (Transform).
--   4. Su zona: va hacia ella por las calles (shared/Invasion/Nav) y, al llegar, la toma (se queda
--      cerca) y, si ya es suya, ataca los objetos del sitio (farolas, bancos, quioscos: se rompen con
--      trozos y chispas y se arreglan solos al acabar).
-- Estilos de cada raza (Races.Behaviour): Swarm (más rápidos al perseguir), Siege (despacio y en
-- grupo), Snipe (los tiradores, más lejos), Blink (saltos cortos de teletransporte).

local Nav = require(script.Parent.Nav)
local Rules = require(script.Parent.Rules)

local AlienAI = {}

export type Alien = {
	Id: string,
	Race: string,
	Kind: string,
	Stats: { [string]: number },
	Style: string,
	Pos: Vector3,
	Look: Vector3,
	Hp: number,
	MaxHp: number,
	Zone: string?,
	Target: string?,
	TargetKind: string?,
	Path: { Vector3 }?,
	PathAt: number,
	PathGoal: Vector3?,
	NextAttack: number,
	NextBlink: number,
	LastHitBy: string?,
	LastHitAt: number,
	Brawler: boolean,
	Mode: string,
}

export type Target = { Id: string, Pos: Vector3, Alive: boolean?, Race: string? }
export type Context = {
	Players: { Target },
	Npcs: { Target }?,
	Rivals: { Target }?,
	Props: { Target }?,
	ZonePos: Vector3?,
	ZoneConquered: boolean?,
	Graph: Nav.Graph?,
}
export type Decision = { Goal: Vector3?, Speed: number, Attack: Target?, AttackKind: string?, Blink: Vector3?, Mode: string }

function AlienAI.new(id: string, race: { [string]: any }, kind: string, pos: Vector3, zone: string?, seed: number?): Alien
	local stats = Rules.groundStats(kind, race)
	local k = seed or 0
	return {
		Id = id,
		Race = race.Id,
		Kind = kind,
		Stats = stats,
		Style = race.Behaviour or "Swarm",
		Pos = pos,
		Look = Vector3.new(0, 0, -1),
		Hp = stats.Hp,
		MaxHp = stats.Hp,
		Zone = zone,
		Target = nil,
		TargetKind = nil,
		Path = nil,
		PathAt = -math.huge,
		PathGoal = nil,
		NextAttack = 1 + (k % 7) * 0.2,
		NextBlink = 3 + (k % 5),
		LastHitBy = nil,
		LastHitAt = -math.huge,
		Brawler = (k % 3) == 0,
		Mode = "Advance",
	}
end

local function flat(a: Vector3, b: Vector3): number
	return math.sqrt((a.X - b.X) ^ 2 + (a.Z - b.Z) ^ 2)
end
AlienAI.flat = flat

local function closest(list: { Target }?, pos: Vector3, radius: number): (Target?, number)
	local best, bestD = nil, math.huge
	for _, t in list or {} do
		if t.Alive ~= false then
			local d = flat(t.Pos, pos)
			if d < bestD and d <= radius then
				best, bestD = t, d
			end
		end
	end
	return best, bestD
end

function AlienAI.hit(a: Alien, by: string?, now: number)
	a.LastHitBy = by
	a.LastHitAt = now
end

-- ¿Es de los que pegan de lejos?
function AlienAI.ranged(a: Alien): boolean
	return a.Kind == "Ranged" or a.Kind == "Elite"
end

-- El siguiente punto del camino hacia `goal` (por las calles si está lejos)
function AlienAI.waypoint(a: Alien, goal: Vector3, now: number, g: Nav.Graph?): Vector3
	local stale = a.Path == nil or a.PathGoal == nil or flat(a.PathGoal :: Vector3, goal) > 60 or now - a.PathAt > 12
	if stale then
		a.Path = Nav.path(a.Pos, goal, g)
		a.PathGoal = goal
		a.PathAt = now
	end
	local path = a.Path :: { Vector3 }
	while #path > 1 and flat(path[1], a.Pos) < 10 do
		table.remove(path, 1)
	end
	return path[1] or goal
end

-- Decide adónde va, a qué velocidad y si ataca (a quién)
function AlienAI.think(a: Alien, ctx: Context, now: number): Decision
	local st = a.Stats
	local speed = st.Speed
	local ranged = AlienAI.ranged(a)
	-- 1. Jugadores
	local attacker: Target? = nil
	if a.LastHitBy and now - a.LastHitAt < 6 then
		for _, p in ctx.Players do
			if p.Id == a.LastHitBy and p.Alive ~= false and flat(p.Pos, a.Pos) <= st.Aggro * 1.8 then
				attacker = p
			end
		end
	end
	local target, dist = attacker, if attacker then flat(attacker.Pos, a.Pos) else math.huge
	if not target then
		target, dist = closest(ctx.Players, a.Pos, st.Aggro)
	end
	local kind = "Player"
	-- 2. Rivales (solo los peleones, y si no hay jugadores)
	if not target and a.Brawler then
		target, dist = closest(ctx.Rivals, a.Pos, 45)
		kind = "Alien"
	end
	-- 3. Vecinos (los de cuerpo a cuerpo)
	if not target and not ranged then
		target, dist = closest(ctx.Npcs, a.Pos, 34)
		kind = "Npc"
	end
	if target then
		a.Target, a.TargetKind = target.Id, kind
		local range = st.Range
		local attack = if dist <= range and now >= a.NextAttack then target else nil
		local goal: Vector3? = target.Pos
		if ranged then
			-- Los de lejos: se quedan a una distancia cómoda (Snipe: más lejos) y se apartan si te acercas
			local keep = range * (if a.Style == "Snipe" then 0.7 else 0.5)
			if dist < 18 then
				local away = a.Pos - target.Pos
				away = Vector3.new(away.X, 0, away.Z)
				goal = a.Pos + (if away.Magnitude > 0.1 then away.Unit else Vector3.new(1, 0, 0)) * 20
				speed *= 1.1
			elseif dist <= keep then
				goal = nil -- (quieto, disparando)
			end
		elseif a.Style == "Swarm" then
			speed *= 1.15
		end
		-- Blink: un salto corto hacia el blanco (de lado), de vez en cuando
		local blink = nil
		if a.Style == "Blink" and now >= a.NextBlink and dist > 25 then
			a.NextBlink = now + 4.5
			local to = target.Pos - a.Pos
			to = Vector3.new(to.X, 0, to.Z)
			if to.Magnitude > 1 then
				local side = Vector3.new(-to.Unit.Z, 0, to.Unit.X) * (if (a.Id:len() % 2) == 0 then 8 else -8)
				blink = a.Pos + to.Unit * math.min(22, dist - 12) + side
			end
		end
		a.Mode = if attack then "Attack" else "Chase"
		return { Goal = goal, Speed = speed, Attack = attack, AttackKind = kind, Blink = blink, Mode = a.Mode }
	end
	a.Target, a.TargetKind = nil, nil
	-- 4. Su zona
	local zone = ctx.ZonePos
	if zone then
		local d = flat(zone, a.Pos)
		if d > Rules.ZoneRadius * 0.55 then
			a.Mode = "Advance"
			return { Goal = AlienAI.waypoint(a, zone, now, ctx.Graph), Speed = speed, Mode = a.Mode }
		end
		if ctx.ZoneConquered then
			local prop, pd = closest(ctx.Props, a.Pos, Rules.ZoneRadius)
			if prop then
				a.Mode = "Siege"
				local attack = if pd <= math.max(st.Range, 8) and now >= a.NextAttack then prop else nil
				return { Goal = if pd > st.Range * 0.8 then prop.Pos else nil, Speed = speed * 0.7, Attack = attack, AttackKind = "Prop", Mode = a.Mode }
			end
		end
		a.Mode = "Hold"
		-- (dando vueltas despacio dentro de la zona)
		local ang = now * 0.15 + (#a.Id) * 1.3
		return { Goal = zone + Vector3.new(math.cos(ang), 0, math.sin(ang)) * Rules.ZoneRadius * 0.35, Speed = speed * 0.4, Mode = a.Mode }
	end
	a.Mode = "Idle"
	return { Goal = nil, Speed = 0, Mode = a.Mode }
end

-- Ya ha atacado: siguiente ataque
function AlienAI.attacked(a: Alien, now: number)
	a.NextAttack = now + a.Stats.Cooldown
end

-- Se mueve hacia `goal` (en planta) como mucho speed*dt; Y la pone el servidor (suelo)
function AlienAI.step(a: Alien, goal: Vector3?, speed: number, dt: number)
	if not goal then
		return
	end
	local to = Vector3.new(goal.X - a.Pos.X, 0, goal.Z - a.Pos.Z)
	local d = to.Magnitude
	if d < 0.5 then
		return
	end
	local step = math.min(d, speed * dt)
	local dir = to / d
	a.Look = dir
	a.Pos += dir * step
end

-- ¿Le da un disparo de lejos? (puntería que baja con la distancia; r = 0..1)
function AlienAI.accuracy(dist: number, range: number): number
	return math.clamp(0.85 - 0.5 * (dist / math.max(range, 1)), 0.25, 0.85)
end

return AlienAI
