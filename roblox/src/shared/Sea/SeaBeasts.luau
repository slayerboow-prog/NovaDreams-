-- SeaBeasts: el megalodón del Abismo Silente y el kraken de la Sima del Kraken, en reglas puras (sin
-- Roblox salvo Vector3). Las mueve Services/SeaBeastService (el servidor decide todo: dónde están, a
-- quién atacan y el daño); el cliente (Controllers/SeaLife) solo los dibuja. Lo prueba test-mar.
-- docs/mar/diseno.md.
--
-- Megalodón: patrulla el Abismo Silente (nunca sale de su elipse ni sube de 25 m). Si un buceador baja
--   a su territorio: le ronda unos segundos (Stalk), embiste (Charge) y, si lo alcanza, muerde: daño,
--   empujón y pierdes aire (sin sangre: 13+). Después se aleja (Retreat). Un golpe en el morro (Atacar)
--   lo espanta antes de tiempo.
-- Kraken: vive en su guarida, en la pared de la Sima. Si bajas a la sima cerca de ella: aviso (Warn: la
--   tierra tiembla y suelta tinta) y un tentáculo golpea donde estabas (Strike); si te has apartado,
--   falla. Atacar el tentáculo durante el aviso lo hace retirarse.
-- Nunca atacan a bebés ni niños, ni a quien va en un barco o vehículo, ni mientras están enganchados
--   a un sedal (la pesca del monstruo: Hooked) o fuera (Gone: lo habéis pescado; vuelve otro ejemplar).

local Shared = game:GetService("ReplicatedStorage").Shared
local Ocean = require(Shared.Sea.Ocean)

local SeaBeasts = {}

local V = Vector3.new

SeaBeasts.Megalodon = {
	Id = "Megalodon",
	Name = "Megalodón",
	Length = 56, -- studs (~16 m)
	PatrolSpeed = 14,
	ChaseSpeed = 22,
	ChargeSpeed = 50,
	Turn = 1.6, -- radianes por segundo (patrullando)
	Sight = 120, -- a esta distancia te ve
	StalkRadius = 38,
	StalkTime = 4.5,
	ChargeTime = 2.4,
	BiteRange = 11, -- de la boca a ti
	Damage = 30,
	Oxygen = 20,
	Knock = 75,
	Retreat = 10, -- segundos alejándose después de morder o de un golpe
	MinMeters = 25, -- solo caza a quien baja de esto
	TopY = -95, -- nunca sube de aquí (≈ 26 m)
	FloorClear = 14,
	Territory = 0.98, -- fracción de la elipse del abismo
}

SeaBeasts.Kraken = {
	Id = "Kraken",
	Name = "Kraken",
	Ambush = 120, -- studs (horizontal) desde la guarida
	MaxY = -280, -- solo si estás más hondo que esto (dentro de la sima)
	Warn = 1.6,
	StrikeRadius = 14,
	Reach = 140, -- un tentáculo no llega más lejos de la guarida
	Damage = 25,
	Oxygen = 20,
	Knock = 60,
	Rest = 6,
}

SeaBeasts.Respawn = 480 -- segundos hasta que vuelve otro ejemplar después de pescarlo
SeaBeasts.NoTarget = { Bebe = true, Nino = true }

---------------------------------------------------------------------
-- Territorios
---------------------------------------------------------------------
function SeaBeasts.ellipse(x: number, z: number): number
	local b = Ocean.Basin
	return math.sqrt(((x - b.X) / b.RX) ^ 2 + ((z - b.Z) / b.RZ) ^ 2)
end

function SeaBeasts.inTerritory(id: string, pos: Vector3): boolean
	if id == "Megalodon" then
		return SeaBeasts.ellipse(pos.X, pos.Z) <= SeaBeasts.Megalodon.Territory
	end
	local L = Ocean.Lair
	return math.sqrt((pos.X - L.X) ^ 2 + (pos.Z - L.Z) ^ 2) <= SeaBeasts.Kraken.Ambush and pos.Y <= SeaBeasts.Kraken.MaxY
end

-- ¿Puede atacar a este jugador? info: { Pos, Alive, Underwater, Stage, Riding }
function SeaBeasts.canTarget(id: string, info: { [string]: any }): boolean
	if not info.Alive or not info.Underwater or info.Riding or SeaBeasts.NoTarget[info.Stage or ""] then
		return false
	end
	if id == "Megalodon" then
		return SeaBeasts.inTerritory(id, info.Pos) and Ocean.meters(info.Pos.Y) >= SeaBeasts.Megalodon.MinMeters
	end
	return SeaBeasts.inTerritory(id, info.Pos)
end

-- Los puntos de la ronda del megalodón (un óvalo dentro del abismo, a media agua)
local wpCache: { Vector3 }? = nil
function SeaBeasts.waypoints(): { Vector3 }
	if wpCache then
		return wpCache
	end
	local b = Ocean.Basin
	local list = {}
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		local k = 0.45 + 0.2 * Ocean.hash(i, 1, 71)
		local x, z = b.X + math.cos(a) * b.RX * k, b.Z + math.sin(a) * b.RZ * k
		local floorY = Ocean.floorY(x, z) or -240
		table.insert(list, V(x, math.min(SeaBeasts.Megalodon.TopY - 30, floorY + 45), z))
	end
	wpCache = list
	return list
end

-- Dentro de su sitio: ni fuera de la elipse, ni por encima de TopY, ni dentro del fondo
function SeaBeasts.clampMegalodon(pos: Vector3): Vector3
	local b = Ocean.Basin
	local e = SeaBeasts.ellipse(pos.X, pos.Z)
	local limit = SeaBeasts.Megalodon.Territory
	if e > limit then
		local k = limit / e
		pos = V(b.X + (pos.X - b.X) * k, pos.Y, b.Z + (pos.Z - b.Z) * k)
	end
	local floorY = (Ocean.floorY(pos.X, pos.Z) or -240) + SeaBeasts.Megalodon.FloorClear
	return V(pos.X, math.clamp(pos.Y, math.min(floorY, SeaBeasts.Megalodon.TopY), SeaBeasts.Megalodon.TopY), pos.Z)
end

---------------------------------------------------------------------
-- Megalodón
---------------------------------------------------------------------
export type Target = { Id: number, Pos: Vector3 }
export type Mega = { Pos: Vector3, Look: Vector3, Mode: string, Timer: number, Target: number?, Wp: number, Angle: number }

function SeaBeasts.newMegalodon(): Mega
	local wp = SeaBeasts.waypoints()
	return { Pos = wp[1], Look = (wp[2] - wp[1]).Unit, Mode = "Patrol", Timer = 0, Target = nil, Wp = 2, Angle = 0 }
end

-- La boca (delante del centro)
function SeaBeasts.mouth(m: Mega): Vector3
	return m.Pos + m.Look * SeaBeasts.Megalodon.Length * 0.42
end

local function steer(look: Vector3, want: Vector3, maxTurn: number): Vector3
	if want.Magnitude < 1e-4 then
		return look
	end
	want = want.Unit
	local dot = math.clamp(look:Dot(want), -1, 1)
	local angle = math.acos(dot)
	if angle <= maxTurn or angle < 1e-4 then
		return want
	end
	local k = maxTurn / angle
	local mixed = look * (1 - k) + want * k
	return if mixed.Magnitude > 1e-4 then mixed.Unit else want
end

local function findTarget(pos: Vector3, targets: { Target }, range: number, id: number?): Target?
	local best, bestD = nil, range
	for _, t in targets do
		if id and t.Id == id then
			return t
		end
		local d = (t.Pos - pos).Magnitude
		if not id and d < bestD then
			best, bestD = t, d
		end
	end
	return best
end

-- Un paso del megalodón. targets: los que puede atacar (canTarget). Devuelve el estado y lo que ha pasado:
-- { Bite = idDelJugador }
function SeaBeasts.stepMegalodon(m: Mega, dt: number, targets: { Target }): (Mega, { [string]: any })
	local D = SeaBeasts.Megalodon
	local events = {}
	m.Timer -= dt
	if m.Mode == "Gone" then
		return m, events
	end
	if m.Mode == "Hooked" then
		-- enganchado a un sedal: se revuelve en su sitio (no ataca)
		m.Angle += dt * 2.5
		m.Look = V(math.cos(m.Angle), math.sin(m.Angle * 1.7) * 0.2, math.sin(m.Angle)).Unit
		return m, events
	end
	local speed, want = D.PatrolSpeed, m.Look
	local target = if m.Target then findTarget(m.Pos, targets, math.huge, m.Target) else nil
	if m.Mode == "Patrol" then
		local wps = SeaBeasts.waypoints()
		local wp = wps[m.Wp] or wps[1]
		if (wp - m.Pos).Magnitude < 25 then
			m.Wp = m.Wp % #wps + 1
			wp = wps[m.Wp]
		end
		want = wp - m.Pos
		local seen = findTarget(m.Pos, targets, D.Sight, nil)
		if seen then
			m.Mode, m.Timer, m.Target = "Stalk", D.StalkTime, seen.Id
			m.Angle = math.atan2(m.Pos.Z - seen.Pos.Z, m.Pos.X - seen.Pos.X)
		end
	elseif m.Mode == "Stalk" then
		if not target then
			m.Mode, m.Target = "Patrol", nil
		else
			-- da vueltas a su alrededor
			m.Angle += dt * (D.ChaseSpeed / D.StalkRadius)
			local around = target.Pos + V(math.cos(m.Angle) * D.StalkRadius, 4, math.sin(m.Angle) * D.StalkRadius)
			want = around - m.Pos
			speed = D.ChaseSpeed
			if m.Timer <= 0 then
				m.Mode, m.Timer = "Charge", D.ChargeTime
			end
		end
	elseif m.Mode == "Charge" then
		if not target then
			m.Mode, m.Target = "Patrol", nil
		else
			want = target.Pos - m.Pos
			-- (acelera cuando ya le apunta: no pasa de largo dando vueltas)
			local aim = if want.Magnitude > 1e-3 then m.Look:Dot(want.Unit) else 1
			speed = D.ChaseSpeed + (D.ChargeSpeed - D.ChaseSpeed) * math.clamp(aim, 0, 1) ^ 2
			if (SeaBeasts.mouth(m) - target.Pos).Magnitude <= D.BiteRange then
				events.Bite = target.Id
				m.Mode, m.Timer = "Retreat", D.Retreat
			elseif m.Timer <= 0 then
				m.Mode, m.Timer = "Retreat", D.Retreat * 0.5 -- ha fallado
			end
		end
	elseif m.Mode == "Retreat" then
		local b = Ocean.Basin
		local away = if target then m.Pos - target.Pos else V(b.X, m.Pos.Y, b.Z) - m.Pos
		want = V(away.X, 0, away.Z)
		speed = D.ChaseSpeed
		if m.Timer <= 0 then
			m.Mode, m.Target = "Patrol", nil
		end
	end
	local turn = (if m.Mode == "Charge" then 4.5 elseif m.Mode == "Stalk" then 2.2 else D.Turn) * dt
	m.Look = steer(m.Look, want, turn)
	m.Pos = SeaBeasts.clampMegalodon(m.Pos + m.Look * speed * dt)
	return m, events
end

-- Golpe en el morro (Atacar cerca de la cabeza): se va
function SeaBeasts.strikeMegalodon(m: Mega, from: Vector3, range: number?): boolean
	if m.Mode == "Gone" or m.Mode == "Hooked" then
		return false
	end
	if (SeaBeasts.mouth(m) - from).Magnitude <= (range or 16) or (m.Pos - from).Magnitude <= SeaBeasts.Megalodon.Length * 0.35 then
		m.Mode, m.Timer = "Retreat", SeaBeasts.Megalodon.Retreat
		return true
	end
	return false
end

---------------------------------------------------------------------
-- Kraken
---------------------------------------------------------------------
export type Kraken = { Mode: string, Timer: number, Target: number?, At: Vector3? }

function SeaBeasts.newKraken(): Kraken
	return { Mode = "Lurk", Timer = 0, Target = nil, At = nil }
end

-- Dónde puede golpear (a lo sumo Reach de la guarida)
function SeaBeasts.reachable(at: Vector3): Vector3
	local L = Ocean.Lair
	local lair = V(L.X, L.Y, L.Z)
	local d = at - lair
	if d.Magnitude > SeaBeasts.Kraken.Reach then
		return lair + d.Unit * SeaBeasts.Kraken.Reach
	end
	return at
end

-- Un paso del kraken. Devuelve el estado y { Warn = id, At } o { Strike = At, Hit = idDelJugador? }
function SeaBeasts.stepKraken(k: Kraken, dt: number, targets: { Target }): (Kraken, { [string]: any })
	local K = SeaBeasts.Kraken
	local events = {}
	k.Timer -= dt
	if k.Mode == "Gone" or k.Mode == "Hooked" then
		return k, events
	end
	if k.Mode == "Lurk" then
		local L = Ocean.Lair
		local t = findTarget(V(L.X, L.Y, L.Z), targets, math.huge, nil)
		if t then
			k.Mode, k.Timer, k.Target = "Warn", K.Warn, t.Id
			k.At = SeaBeasts.reachable(t.Pos)
			events.Warn = t.Id
			events.At = k.At
		end
	elseif k.Mode == "Warn" then
		if k.Timer <= 0 then
			local at = k.At :: Vector3
			k.Mode, k.Timer = "Strike", 0.6
			events.Strike = at
			for _, t in targets do
				if (t.Pos - at).Magnitude <= K.StrikeRadius then
					events.Hit = t.Id
					break
				end
			end
		end
	elseif k.Mode == "Strike" then
		if k.Timer <= 0 then
			k.Mode, k.Timer = "Rest", K.Rest
		end
	elseif k.Mode == "Rest" then
		if k.Timer <= 0 then
			k.Mode, k.Target, k.At = "Lurk", nil, nil
		end
	end
	return k, events
end

-- Atacar el tentáculo mientras avisa (o golpea): se retira
function SeaBeasts.strikeKraken(k: Kraken, from: Vector3, range: number?): boolean
	if (k.Mode == "Warn" or k.Mode == "Strike") and k.At and (k.At - from).Magnitude <= (range or 18) then
		k.Mode, k.Timer = "Rest", SeaBeasts.Kraken.Rest * 1.5
		return true
	end
	return false
end

-- Lo que hace un golpe (vida, aire y empujón): sin sangre
function SeaBeasts.hit(id: string): { Damage: number, Oxygen: number, Knock: number }
	local d = if id == "Kraken" then SeaBeasts.Kraken else SeaBeasts.Megalodon
	return { Damage = d.Damage, Oxygen = d.Oxygen, Knock = d.Knock }
end

return SeaBeasts
