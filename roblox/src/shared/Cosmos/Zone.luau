-- Zone: la geometría del cielo y el espacio encima de Valmar para la nave (cuentas puras;
-- docs/espacio.md). Tiene la misma forma que shared/AirCombat/Arena, así AirCombatService y
-- AirCombatClient vuelan aquí igual que en la arena de pruebas (World = "Cosmos"):
--   checkpoint(sección, pos?), center(sección), modeAt(pos), contains(pos, margen), bounds(pos),
--   collide(pos, radio), segmentBlocked(a, b), turretSpots(sección)
-- y además: rockHit(a, b) (qué asteroide toca un disparo), safeAt(pos) (zona segura de una
-- estación), sectorAt(pos) (sector con patrullas) y fieldAt(pos).
--
-- Contenido (todo por encima de Layers.SpaceY = 3400, nada en el cielo de los aviones):
--   * 2 estaciones (shared/Cosmos/Stations): Alba (para empezar) y Cénit.
--   * 3 campos de asteroides minables (Fields): el Cinturón de Hierro (tranquilo, junto a Alba), el
--     Campo Brasa y la Nube Escarcha (más cobalto y cristal… y patrullas).
--   * 3 sectores con patrullas enemigas (Sectors): Brasa (nivel 1), la Ruta de los Saqueadores
--     (nivel 2) y Escarcha (nivel 3). Fuera de ellos no sale nadie.
-- Los asteroides son esferas repetibles (misma semilla en el cliente, el servidor y las pruebas): para
-- chocar y disparar cuentan como esferas; se ven como rocas irregulares (shared/Cosmos/Asteroids). Los
-- rotos no cuentan y sus trozos sí (Asteroids: el registro que decide el servidor).

local Layers = require(script.Parent.Layers)
local Stations = require(script.Parent.Stations)
local Access = require(script.Parent.Access)
local Mining = require(script.Parent.Mining)
local PlanetBodies = require(script.Parent.PlanetBodies)
local Asteroids = require(script.Parent.Asteroids)

local Zone = {}

Zone.Name = "Cosmos"
Zone.Seed = 23

export type Rock = { Id: string, Field: string, Center: Vector3, Radius: number, Ore: string }
export type Field = { Id: string, Name: string, Center: Vector3, Radius: number, Count: number, Ores: { [string]: number } }
export type Sector = { Id: string, Name: string, Center: Vector3, Radius: number, Level: number, Max: number, Cazas: boolean }

Zone.Fields = {
	{ Id = "Hierro", Name = "Cinturón de Hierro", Center = Vector3.new(-3700, 4200, 3500), Radius = 950, Count = 34, Ores = { Hierro = 0.75, Cobalto = 0.22, Cristal = 0.03 } },
	{ Id = "Brasa", Name = "Campo Brasa", Center = Vector3.new(3900, 5000, 1700), Radius = 1000, Count = 34, Ores = { Hierro = 0.5, Cobalto = 0.4, Cristal = 0.1 } },
	{ Id = "Escarcha", Name = "Nube Escarcha", Center = Vector3.new(-600, 6600, -4300), Radius = 1100, Count = 36, Ores = { Hierro = 0.35, Cobalto = 0.4, Cristal = 0.25 } },
} :: { Field }

Zone.Sectors = {
	{ Id = "Brasa", Name = "Sector Brasa", Center = Vector3.new(3900, 5000, 1700), Radius = 1600, Level = 1, Max = 4, Cazas = false },
	{ Id = "Ruta", Name = "Ruta de los Saqueadores", Center = Vector3.new(1200, 7400, 2600), Radius = 1300, Level = 2, Max = 5, Cazas = true },
	{ Id = "Escarcha", Name = "Sector Escarcha", Center = Vector3.new(-600, 6600, -4300), Radius = 1700, Level = 3, Max = 6, Cazas = true },
} :: { Sector }

local function rng(seed: number): () -> number
	local s = seed % 2147483647
	if s <= 0 then
		s += 2147483646
	end
	return function()
		s = (s * 16807) % 2147483647
		return s / 2147483647
	end
end

---------------------------------------------------------------------
-- Asteroides
---------------------------------------------------------------------
local rocksCache: { Rock }? = nil
local rocksById: { [string]: Rock } = {}

function Zone.rocks(): { Rock }
	if rocksCache then
		return rocksCache
	end
	local out: { Rock } = {}
	for fi, f in Zone.Fields do
		local r = rng(Zone.Seed * 131 + fi * 7919)
		local list: { Rock } = {}
		local tries = 0
		while #list < f.Count and tries < 900 do
			tries += 1
			local radius = 12 + r() ^ 2 * 52
			-- (un disco aplastado: los campos son anchos y no muy altos)
			local a = r() * math.pi * 2
			local d = math.sqrt(r()) * f.Radius * 0.95
			local p = f.Center + Vector3.new(math.cos(a) * d, (r() * 2 - 1) * f.Radius * 0.28, math.sin(a) * d)
			local ok = p.Y - radius > Layers.SpaceY + 200 and Stations.safeAt(p) == nil
			if ok then
				for _, b in list do
					if (b.Center - p).Magnitude < b.Radius + radius + 50 then
						ok = false
						break
					end
				end
			end
			if ok then
				local ore = Mining.pick(f.Ores, r())
				local rock = { Id = ("%s_%d"):format(f.Id, #list + 1), Field = f.Id, Center = p, Radius = radius, Ore = ore }
				table.insert(list, rock)
			end
		end
		for _, rock in list do
			table.insert(out, rock)
			rocksById[rock.Id] = rock
		end
	end
	rocksCache = out
	return out
end

function Zone.rock(id: string): Rock?
	Zone.rocks()
	return rocksById[id]
end

-- Un asteroide entero o un trozo que exista AHORA (los rotos no): con su centro de ahora
function Zone.liveRock(id: string): Rock?
	Zone.rocks()
	return Asteroids.rockOf(id, rocksById[id]) :: any
end

-- Asteroides y trozos de un campo que existen ahora
local function liveRocks(field: string): { Rock }
	local out = {}
	for _, a in Zone.rocks() do
		if a.Field == field and not Asteroids.isGone(a.Id) then
			table.insert(out, a)
		end
	end
	for _, f in Asteroids.liveIn(field) do
		table.insert(out, f :: any)
	end
	return out
end
Zone.liveRocks = liveRocks

-- (sin crear tablas: se llama muchas veces por fotograma al volar) el que toca una esfera, o nil
local function touching(field: string, pos: Vector3, radius: number): Rock?
	for _, a in Zone.rocks() do
		if a.Field == field and (a.Center - pos).Magnitude <= a.Radius + radius and not Asteroids.isGone(a.Id) then
			return a
		end
	end
	if Asteroids.fragmentCount() > 0 then
		for _, fr in Asteroids.liveIn(field) do
			if (fr.Center - pos).Magnitude <= fr.Radius + radius then
				return fr :: any
			end
		end
	end
	return nil
end

-- El asteroide (o trozo) que toca una esfera en pos, o nil
function Zone.rockAt(pos: Vector3, radius: number): Rock?
	if pos.Y + radius < Layers.SpaceY then
		return nil
	end
	local f = Zone.fieldAt(pos, 120)
	if not f then
		return nil
	end
	return touching(f.Id, pos, radius)
end

function Zone.fieldAt(pos: Vector3, margin: number?): Field?
	for _, f in Zone.Fields do
		if (pos - f.Center).Magnitude <= f.Radius + (margin or 0) then
			return f
		end
	end
	return nil
end

function Zone.sectorAt(pos: Vector3): Sector?
	if not Layers.aiAllowed(pos) then
		return nil
	end
	for _, s in Zone.Sectors do
		if (pos - s.Center).Magnitude <= s.Radius then
			return s
		end
	end
	return nil
end

function Zone.safeAt(pos: Vector3): boolean
	return Stations.safeAt(pos) ~= nil
end

---------------------------------------------------------------------
-- Lo que pide AirCombatService / ShipFlight (como shared/AirCombat/Arena)
---------------------------------------------------------------------
function Zone.modeAt(pos: Vector3): string
	return Layers.mode(pos.Y)
end

-- Punto de control (reaparecer): en el espacio, el muelle de la estación más cercana; abajo, encima
-- del puerto espacial
function Zone.checkpoint(section: string?, near: Vector3?): CFrame
	if section == "Space" then
		local st = Stations.nearest(near or Stations.List[1].Center)
		return Stations.launch(st)
	end
	local p = Access.Port + Vector3.new(0, 600, 0)
	return Access.face(p, Vector3.new(-1, 0.15, 0))
end

function Zone.center(section: string?): Vector3
	if section == "Space" then
		return Stations.List[1].Center
	end
	return Access.Port + Vector3.new(0, 600, 0)
end

function Zone.contains(pos: Vector3, margin: number?): boolean
	local m = margin or 0
	-- (junto a un planeta se puede salir de la columna: su atmósfera queda fuera; docs/planetas.md)
	if PlanetBodies.approachAt(pos, m) then
		return true
	end
	return Layers.inColumn(pos, m) and pos.Y >= -60 - m and pos.Y <= Layers.TopY + m
end

local function nearPort(pos: Vector3): boolean
	local d = pos - Access.Port
	return Vector2.new(d.X, d.Z).Magnitude <= Access.CorridorRadius
end
Zone.nearPort = nearPort

-- Fuera de los límites: hacia dónde volver (unitario); dentro, nil
function Zone.bounds(pos: Vector3): Vector3?
	local d = pos - Layers.Center
	local back = Vector3.zero
	local H = Layers.Half
	if PlanetBodies.approachAt(pos) then
		-- (volando hacia un planeta: sin paredes de la columna ni techo; docs/planetas.md)
		H = math.huge
	end
	if d.X > H then
		back += Vector3.new(-1, 0, 0)
	elseif d.X < -H then
		back += Vector3.new(1, 0, 0)
	end
	if d.Z > H then
		back += Vector3.new(0, 0, -1)
	elseif d.Z < -H then
		back += Vector3.new(0, 0, 1)
	end
	if pos.Y > Layers.TopY and H ~= math.huge then
		back += Vector3.new(0, -1, 0)
	elseif pos.Y < Layers.floorAt(pos) and not nearPort(pos) then
		back += Vector3.new(0, 1, 0) -- (suelo de las naves: lejos del puerto no se baja más; en una invasión, más abajo)
	end
	-- (las estaciones no se atraviesan: la nave se aparta de su casco)
	for _, st in Stations.List do
		local off = pos - st.Center
		if off.Magnitude < Stations.HallHalf * 2.2 then
			back += if off.Magnitude > 1 then off.Unit * 2 else Vector3.new(0, 1, 0)
		end
	end
	return if back.Magnitude > 0 then back.Unit else nil
end

-- Los enemigos: además, nunca bajan del espacio (Layers.AIMinY) ni entran en la zona segura de una
-- estación ni se alejan de su sector
function Zone.enemyBounds(pos: Vector3): Vector3?
	local back = Zone.bounds(pos) or Vector3.zero
	if pos.Y < Layers.AIMinY then
		back += Vector3.new(0, 2, 0)
	end
	for _, st in Stations.List do
		local off = pos - st.Center
		if off.Magnitude < Stations.SafeRadius + 120 then
			back += if off.Magnitude > 1 then off.Unit * 2 else Vector3.new(0, 1, 0)
		end
	end
	return if back.Magnitude > 0 then back.Unit else nil
end

-- ¿Toca algo sólido una esfera en `pos`? ("el mar", "el suelo", "un asteroide") o nil
function Zone.collide(pos: Vector3, radius: number): string?
	if pos.Y - radius <= -1 then
		return if pos.Y < 4 and not nearPort(pos) then "el mar" else "el suelo"
	end
	-- (los planetas son sólidos: se baja a ellos por la entrada en la atmósfera, PlanetEntry)
	for _, b in PlanetBodies.List do
		if (pos - b.Center).Magnitude <= b.Radius + radius then
			return "un planeta"
		end
	end
	if Stations.hullHit(pos, radius) then
		return "una estación"
	end
	if pos.Y + radius >= Layers.SpaceY then
		local f = Zone.fieldAt(pos, 80)
		if f then
			if touching(f.Id, pos, radius) then
				return "un asteroide"
			end
		end
	end
	return nil
end

-- ¿Qué asteroide toca un proyectil que va de a a b? (id y punto) o nil
function Zone.rockHit(a: Vector3, b: Vector3): (Rock?, Vector3?)
	if math.max(a.Y, b.Y) < Layers.SpaceY then
		return nil, nil
	end
	local f = Zone.fieldAt(a, 200) or Zone.fieldAt(b, 200)
	if not f then
		return nil, nil
	end
	local len = (b - a).Magnitude
	local steps = math.clamp(math.ceil(len / 20), 1, 40)
	local live = liveRocks(f.Id)
	for i = 1, steps do
		local p = a:Lerp(b, i / steps)
		for _, r in live do
			if (r.Center - p).Magnitude <= r.Radius + 0.5 then
				return r, p
			end
		end
	end
	return nil, nil
end

function Zone.segmentBlocked(a: Vector3, b: Vector3): boolean
	if math.min(a.Y, b.Y) <= 0 then
		return true
	end
	if Stations.hullHit(b, 0.5) then
		return true
	end
	local rock = Zone.rockHit(a, b)
	return rock ~= nil
end

function Zone.turretSpots(_section: string?): { Vector3 }
	return {}
end

return Zone
