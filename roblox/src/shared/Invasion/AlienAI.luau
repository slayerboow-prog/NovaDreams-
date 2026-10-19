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
--
-- Para que pelear sea divertido y justo (v2):
--   * Ataques AVISADOS: antes de cada golpe o disparo a un jugador se paran a cargar (Windup: el cliente
--     los hace brillar y echar el brazo atrás). El disparo va a donde estabas al empezar a cargar
--     (moverte de lado lo esquiva) y el golpe solo da si sigues a su alcance al soltarlo.
--   * Turnos: como mucho MaxAttackers alienígenas cargando contra el mismo jugador a la vez (los demás
--     se acercan, se colocan o se mueven de lado). Nadie te funde en un segundo.
--   * Encajar un disparo fuerte (o en la cabeza) los hace TAMBALEAR (Stagger): un momento quietos y,
--     si estaban cargando, se les corta el ataque (premia apuntar bien). Pesados y élite aguantan más.
--   * Los de lejos se mueven de lado (Strafe) mientras disparan y, si les dan, buscan una cobertura
--     cercana (un banco, un quiosco, una farola de la zona: Cover) y vuelven a asomarse.

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
	WindupUntil: number?,
	WindupTarget: string?,
	WindupPos: Vector3?,
	WindupKind: string?,
	StaggerUntil: number,
	StrafeSign: number,
	StrafeSwap: number,
	CoverUntil: number,
	CoverPos: Vector3?,
}

-- Lo que tardan en cargar (segundos) y cuántos pueden cargar contra el mismo jugador a la vez
AlienAI.Windup = { Grunt = 0.55, Heavy = 0.85, Ranged = 0.7, Elite = 0.6 }
AlienAI.MaxAttackers = 3
AlienAI.Stagger = { Grunt = 0.45, Ranged = 0.45, Heavy = 0.2, Elite = 0.15 }
AlienAI.StaggerShare = 0.12 -- un disparo que quita al menos esta parte de la vida los tambalea
AlienAI.MeleeGrace = 1.3 -- el golpe da si sigues a menos de Range × esto al soltarlo

export type Target = { Id: string, Pos: Vector3, Alive: boolean?, Race: string? }
export type Context = {
	Players: { Target },
	Npcs: { Target }?,
	Rivals: { Target }?,
	Props: { Target }?,
	Cover: { Vector3 }?, -- cosas tras las que esconderse (bancos, quioscos…)
	Busy: { [string]: number }?, -- cuántos alienígenas están cargando ya contra cada jugador
	ZonePos: Vector3?,
	ZoneConquered: boolean?,
	Graph: Nav.Graph?,
}
export type Decision = { Goal: Vector3?, Speed: number, Attack: Target?, AttackKind: string?, Blink: Vector3?, Mode: string, Windup: number? }

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
		WindupUntil = nil,
		WindupTarget = nil,
		WindupPos = nil,
		WindupKind = nil,
		StaggerUntil = -math.huge,
		StrafeSign = if (k % 2) == 0 then 1 else -1,
		StrafeSwap = 2 + (k % 4) * 0.5,
		CoverUntil = -math.huge,
		CoverPos = nil,
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

-- Encaja `amount` de daño (headshot: en la cabeza). ¿Se tambalea? Si estaba cargando, se le corta.
-- Devuelve (se tambalea, se le ha cortado el ataque)
function AlienAI.stagger(a: Alien, amount: number, headshot: boolean?, now: number): (boolean, boolean)
	local share = amount / math.max(a.MaxHp, 1)
	if share < AlienAI.StaggerShare and not headshot then
		return false, false
	end
	local t = AlienAI.Stagger[a.Kind] or 0.35
	if headshot and share < AlienAI.StaggerShare then
		t *= 0.6
	end
	a.StaggerUntil = math.max(a.StaggerUntil, now + t)
	local cut = a.WindupUntil ~= nil
	a.WindupUntil, a.WindupTarget, a.WindupPos, a.WindupKind = nil, nil, nil, nil
	return true, cut
end

-- Un sitio detrás de `prop` (respecto a quien dispara): para cubrirse
function AlienAI.coverSpot(threat: Vector3, prop: Vector3, gap: number?): Vector3
	local away = Vector3.new(prop.X - threat.X, 0, prop.Z - threat.Z)
	if away.Magnitude < 0.1 then
		away = Vector3.new(1, 0, 0)
	end
	return prop + away.Unit * (gap or 3.5)
end

-- La cobertura más cercana (a menos de radius) que no quede al otro lado de quien dispara
function AlienAI.pickCover(a: Alien, threat: Vector3, covers: { Vector3 }?, radius: number?): Vector3?
	local best, bestD = nil, radius or 26
	for _, c in covers or {} do
		local d = flat(c, a.Pos)
		if d < bestD and flat(c, threat) > 8 and flat(c, threat) < flat(a.Pos, threat) + 10 then
			best, bestD = c, d
		end
	end
	return if best then AlienAI.coverSpot(threat, best) else nil
end

-- Un paso de lado (strafe) alrededor de target: perpendicular a la línea que les une
function AlienAI.strafeGoal(a: Alien, target: Vector3, now: number, dist: number?): Vector3
	if now >= a.StrafeSwap then
		a.StrafeSign = -a.StrafeSign
		a.StrafeSwap = now + 1.8 + ((#a.Id + math.floor(now)) % 4) * 0.45
	end
	local to = Vector3.new(target.X - a.Pos.X, 0, target.Z - a.Pos.Z)
	if to.Magnitude < 0.1 then
		return a.Pos
	end
	local side = Vector3.new(-to.Unit.Z, 0, to.Unit.X) * a.StrafeSign
	return a.Pos + side * (dist or 7)
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
	-- Tambaleándose: quieto
	if now < a.StaggerUntil then
		a.Mode = "Stagger"
		return { Goal = nil, Speed = 0, Mode = a.Mode }
	end
	-- Cargando un ataque: quieto (o un pasito) y, al acabar, lo suelta
	if a.WindupUntil then
		local tid = a.WindupTarget
		local tgt: Target? = nil
		for _, p in ctx.Players do
			if p.Id == tid and p.Alive ~= false then
				tgt = p
			end
		end
		if not tgt then
			a.WindupUntil, a.WindupTarget, a.WindupPos, a.WindupKind = nil, nil, nil, nil
		elseif now >= (a.WindupUntil :: number) then
			local aimAt = if ranged then (a.WindupPos or tgt.Pos) else tgt.Pos
			a.WindupUntil, a.WindupTarget, a.WindupPos, a.WindupKind = nil, nil, nil, nil
			AlienAI.attacked(a, now)
			a.Mode = "Attack"
			-- (el golpe solo da si sigue a su alcance; el disparo va a donde estaba al empezar a cargar)
			local inReach = ranged or flat(tgt.Pos, a.Pos) <= st.Range * AlienAI.MeleeGrace
			return { Goal = nil, Speed = 0, Attack = if inReach then { Id = tgt.Id, Pos = aimAt, Alive = true } else nil, AttackKind = "Player", Mode = a.Mode }
		else
			a.Mode = "Windup"
			local lunge = if not ranged and flat(tgt.Pos, a.Pos) > st.Range * 0.6 then tgt.Pos else nil
			return { Goal = lunge, Speed = speed * 0.3, Mode = a.Mode }
		end
	end
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
		local windup: number? = nil
		if attack and kind == "Player" and ranged and dist < 18 then
			attack = nil -- (los de lejos, si te les echas encima, primero se apartan)
		elseif attack and kind == "Player" then
			-- Contra un jugador: primero se carga (aviso), si hay turno
			local busy = ctx.Busy and ctx.Busy[target.Id] or 0
			if busy < AlienAI.MaxAttackers then
				windup = AlienAI.Windup[a.Kind] or 0.6
				a.WindupUntil = now + windup
				a.WindupTarget = target.Id
				a.WindupPos = target.Pos
				a.WindupKind = kind
				if ctx.Busy then
					ctx.Busy[target.Id] = busy + 1
				end
			else
				a.NextAttack = now + 0.5 -- (espera su turno moviéndose)
			end
			attack = nil
		end
		local goal: Vector3? = target.Pos
		if ranged then
			-- Los de lejos: se quedan a una distancia cómoda (Snipe: más lejos) y se apartan si te acercas
			local keep = range * (if a.Style == "Snipe" then 0.7 else 0.5)
			if a.CoverPos and now < a.CoverUntil and kind == "Player" then
				goal = a.CoverPos -- (a cubrirse tras algo; luego se asoma)
				speed *= 1.15
			elseif dist < 18 then
				local away = a.Pos - target.Pos
				away = Vector3.new(away.X, 0, away.Z)
				goal = a.Pos + (if away.Magnitude > 0.1 then away.Unit else Vector3.new(1, 0, 0)) * 20
				speed *= 1.1
			elseif dist <= keep then
				-- de lado mientras dispara (no se queda quieto como un muñeco)
				goal = AlienAI.strafeGoal(a, target.Pos, now)
				speed *= 0.55
			end
			-- Le acaban de dar: busca una cobertura cerca (una vez cada poco)
			if kind == "Player" and now - a.LastHitAt < 0.6 and now >= a.CoverUntil + 4 then
				local spot = AlienAI.pickCover(a, target.Pos, ctx.Cover)
				if spot then
					a.CoverPos = spot
					a.CoverUntil = now + 2.5
				end
			end
		elseif a.Style == "Swarm" then
			speed *= 1.15
		end
		-- (los de cuerpo a cuerpo que esperan turno dan vueltas alrededor en vez de amontonarse)
		if not ranged and kind == "Player" and not windup and dist <= range * 1.6 and ctx.Busy and (ctx.Busy[target.Id] or 0) >= AlienAI.MaxAttackers then
			goal = AlienAI.strafeGoal(a, target.Pos, now, 5)
			speed *= 0.6
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
		a.Mode = if windup then "Windup" elseif attack then "Attack" else "Chase"
		if windup then
			goal = nil
		end
		return { Goal = goal, Speed = speed, Attack = attack, AttackKind = kind, Blink = if windup then nil else blink, Mode = a.Mode, Windup = windup }
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
