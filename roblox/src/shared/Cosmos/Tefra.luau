-- Tefra: la SUPERFICIE del planeta Tefra (Saga 2, episodio 1; docs/planetas.md). Cuentas puras:
-- lo usan el servidor (World/PlanetWorld construye el terreno y lo de encima; Services/PlanetService
-- comprueba minar, bajar y subir), el cliente (Controllers/PlanetClient y AirCombatClient: choques y
-- aterrizar sin rayos) y las pruebas (scripts/test-planetas.luau).
--
-- Es una zona de terreno de 3072 × 3072 studs en el MISMO place, muy lejos de Valmar y del espacio
-- (centro en X = −25 000, Z = 25 000). El terreno sale de una semilla (math.noise: igual en el servidor,
-- en cada cliente y en las pruebas): colinas suaves («nada tiene esquinas»), valles, el Lago de las
-- Lunas y otro más pequeño, peñascos, cumbres con ceniza y manchas quemadas de la guerra.
--
-- Mismas funciones que shared/Cosmos/Zone y shared/AirCombat/Arena (AirCombatService vuela aquí con
-- World = "Planet"): modeAt, checkpoint, center, contains, bounds, enemyBounds, collide,
-- segmentBlocked, turretSpots, safeAt. Además: heightAt, groundAt, slopeAt, materialAt, Nodes (mineral
-- que se extrae a pie), POIs (puntos de interés), decor (flora y rocas) y el sitio de aterrizaje (Pad).
--
-- Alturas (Y del mundo): agua a WaterY; la nave llega a ArriveY; por encima de ClimbY empieza la
-- salida (nubes) y en CeilingY se vuelve al espacio (shared/Cosmos/PlanetEntry).

local Tefra = {}

Tefra.Id = "Tefra"
Tefra.Name = "Tefra"
Tefra.Origin = Vector3.new(-25000, 0, 25000)
Tefra.Half = 1536
Tefra.Seed = 66
Tefra.WaterY = 34
Tefra.ArriveY = 1400
Tefra.ClimbY = 1700
Tefra.CeilingY = 2300
Tefra.Floor = -40 -- fondo del terreno (lo de debajo, macizo)
Tefra.PadRadius = 46

-- Colores del terreno (materiales que el terreno de Valmar no usa: se pueden teñir sin tocar la ciudad)
local rgb = Color3.fromRGB
-- (Tefra es un mundo VOLCÁNICO de ceniza: tierra de ceniza malva oscura, roca basáltica, cumbres de
-- ceniza clara, coladas de lava y agua turbia de ceniza)
Tefra.TerrainColors = {
	Limestone = rgb(132, 110, 118), -- tierra de ceniza malva de las colinas
	Sandstone = rgb(104, 90, 92), -- orilla de ceniza
	Slate = rgb(78, 70, 80), -- laderas de toba
	Basalt = rgb(52, 46, 54), -- peñascos de basalto
	Salt = rgb(186, 178, 182), -- ceniza clara en las cumbres
	CrackedLava = rgb(70, 40, 34), -- coladas de lava enfriada (brasas en las grietas)
}
Tefra.WaterColor = rgb(70, 66, 76)

-- Lagos de lava y fumarolas (local x, z, radio): solo se ven y dan calor de ambiente (no hacen daño)
Tefra.LavaPools = {
	{ X = 820, Z = -760, R = 46 },
	{ X = -980, Z = -240, R = 34 },
	{ X = 160, Z = 880, R = 40 },
	{ X = -260, Z = 1040, R = 28 },
}
Tefra.Vents = {
	{ X = 760, Z = -690 },
	{ X = -1020, Z = -180 },
	{ X = 260, Z = 960 },
}

-- Puntos de interés (local x, z): ganchos para la historia de la Saga 2
Tefra.POIs = {
	{ Id = "Plataforma", Name = "Plataforma de aterrizaje", X = 0, Z = 0, Flat = 46, Text = "🛬 Plataforma de Bastión Ceniza, abandonada. Las luces aún funcionan con la batería de emergencia." },
	{ Id = "Baliza", Name = "Baliza de señal", X = -420, Z = -470, Flat = 26, Text = "📡 Una señal en bucle, en la frecuencia del ejército de Tefra: «…aquí Bastión Ceniza… el Muelle está tomado… no aterricéis en…». Se corta. Alguien sigue mandándola." },
	{ Id = "Ruinas", Name = "Ruinas de cúpulas", X = 560, Z = 330, Flat = 60, Text = "🏚 Casas de cúpula partidas, una torre en espiral sin terminar y una bufanda de lana enganchada en una viga. Esto era un barrio." },
	{ Id = "Restos", Name = "Restos de una nave", X = -720, Z = 560, Flat = 40, Text = "🛩 Restos de una nave militar. En una placa: «Escuadrilla de Ovilla». La caja negra no está: alguien se la llevó." },
}
Tefra.PoiById = {}
for _, p in Tefra.POIs do
	Tefra.PoiById[p.Id] = p
end

-- Lagos (local x, z, radio)
Tefra.Lakes = {
	{ X = 380, Z = -300, R = 230, Name = "Lago de Ceniza" },
	{ X = -650, Z = 120, R = 150, Name = "Charca Gris" },
}

---------------------------------------------------------------------
-- Coordenadas
---------------------------------------------------------------------
function Tefra.toLocal(pos: Vector3): (number, number)
	return pos.X - Tefra.Origin.X, pos.Z - Tefra.Origin.Z
end

function Tefra.toWorld(lx: number, lz: number, y: number): Vector3
	return Vector3.new(Tefra.Origin.X + lx, y, Tefra.Origin.Z + lz)
end

-- ¿Dentro de la zona del planeta? (en planta y de altura)
function Tefra.inRegion(pos: Vector3, margin: number?): boolean
	local m = margin or 0
	local lx, lz = Tefra.toLocal(pos)
	return math.abs(lx) <= Tefra.Half + m and math.abs(lz) <= Tefra.Half + m and pos.Y >= Tefra.Floor - 200 - m and pos.Y <= Tefra.CeilingY + 600 + m
end

---------------------------------------------------------------------
-- El terreno (igual en todas partes: math.noise)
---------------------------------------------------------------------
local function fbm(x: number, z: number, octaves: number, freq: number, seed: number): number
	local s, amp, norm = 0, 1, 0
	for i = 1, octaves do
		s += amp * math.noise(x * freq, z * freq, seed + i * 7.31)
		norm += amp
		amp *= 0.5
		freq *= 2.03
	end
	return s / norm
end

local function smooth(e0: number, e1: number, x: number): number
	local t = math.clamp((x - e0) / (e1 - e0), 0, 1)
	return t * t * (3 - 2 * t)
end

-- Sin aplanar (colinas, valles, lagos y el borde)
function Tefra.rawHeight(lx: number, lz: number): number
	local seed = Tefra.Seed * 0.173
	local h = 92 + 170 * fbm(lx, lz, 5, 1 / 950, seed)
	h += 70 * math.max(0, fbm(lx, lz, 4, 1 / 430, seed + 3.1) + 0.08)
	-- valles suaves (como cauces secos)
	local v = math.abs(fbm(lx, lz, 3, 1 / 1200, seed + 8.7))
	h -= 64 * smooth(0.11, 0.0, v)
	-- peñascos (redondeados) en lo alto
	local rock = fbm(lx, lz, 3, 1 / 140, seed + 5.5)
	h += 26 * smooth(0.18, 0.4, rock) * smooth(90, 160, h)
	-- lagos: un cuenco suave
	for _, lake in Tefra.Lakes do
		local d = math.sqrt((lx - lake.X) ^ 2 + (lz - lake.Z) ^ 2)
		local k = smooth(lake.R * 1.5, lake.R * 0.55, d)
		h = h + (Tefra.WaterY - 20 - h) * k
	end
	-- el borde: colinas grandes que cierran la zona (y la niebla tapa lo de detrás)
	local edge = math.max(math.abs(lx), math.abs(lz)) / Tefra.Half
	h += 300 * smooth(0.8, 1.0, edge)
	return h
end

local padY: number? = nil
function Tefra.padY(): number
	if not padY then
		padY = math.max(Tefra.rawHeight(0, 0), Tefra.WaterY + 14)
	end
	return padY :: number
end

local poiY: { [string]: number } = {}
function Tefra.poiY(id: string): number
	local p = Tefra.PoiById[id]
	if not p then
		return 0
	end
	if not poiY[id] then
		poiY[id] = if id == "Plataforma" then Tefra.padY() else math.max(Tefra.rawHeight(p.X, p.Z), Tefra.WaterY + 8)
	end
	return poiY[id]
end

-- Altura del suelo en (x, z) del MUNDO (con la plataforma y los puntos de interés aplanados)
function Tefra.heightAt(x: number, z: number): number
	local lx, lz = x - Tefra.Origin.X, z - Tefra.Origin.Z
	local h = Tefra.rawHeight(lx, lz)
	for _, p in Tefra.POIs do
		local d = math.sqrt((lx - p.X) ^ 2 + (lz - p.Z) ^ 2)
		if d < p.Flat * 2.6 then
			local k = smooth(p.Flat * 2.6, p.Flat, d)
			h = h + (Tefra.poiY(p.Id) - h) * k
		end
	end
	return Tefra.Origin.Y + h
end

-- (suelo, ¿agua?): sobre un lago, el suelo es el agua
function Tefra.groundAt(x: number, z: number): (number, boolean)
	local h = Tefra.heightAt(x, z)
	if h < Tefra.Origin.Y + Tefra.WaterY then
		return Tefra.Origin.Y + Tefra.WaterY, true
	end
	return h, false
end

-- Pendiente (0 = llano; 1 = 45°)
function Tefra.slopeAt(x: number, z: number): number
	local e = 4
	local dx = (Tefra.heightAt(x + e, z) - Tefra.heightAt(x - e, z)) / (2 * e)
	local dz = (Tefra.heightAt(x, z + e) - Tefra.heightAt(x, z - e)) / (2 * e)
	return math.sqrt(dx * dx + dz * dz)
end

-- Material del terreno (nombre de Enum.Material) para una altura y una pendiente
function Tefra.materialAt(x: number, z: number, h: number?, slope: number?): string
	local y = (h or Tefra.heightAt(x, z)) - Tefra.Origin.Y
	local s = slope or Tefra.slopeAt(x, z)
	local lx, lz = x - Tefra.Origin.X, z - Tefra.Origin.Z
	if y < Tefra.WaterY + 4 then
		return "Sandstone"
	elseif s > 1.25 then
		return "Slate"
	elseif s > 0.78 then
		return "Basalt"
	end
	local ash = fbm(lx, lz, 3, 1 / 260, 17.3)
	if y > 205 or (y > 135 and ash > 0.06) then
		return "Salt"
	end
	local burn = fbm(lx, lz, 3, 1 / 180, 29.1)
	if burn > 0.22 then
		return "CrackedLava"
	end
	return "Limestone"
end

---------------------------------------------------------------------
-- Mineral (se extrae a pie: ProximityPrompt «Extraer»; lo decide Services/PlanetService)
---------------------------------------------------------------------
export type Node = { Id: string, Pos: Vector3, Ore: string, Radius: number }

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
Tefra.rng = rng

Tefra.NodeCount = 30
Tefra.NodeOres = { Obsidiana = 0.5, Hierro = 0.32, Cobalto = 0.18 }
Tefra.Reach = 14 -- studs del personaje al mineral para extraer

local function farFromPois(lx: number, lz: number, gap: number): boolean
	for _, p in Tefra.POIs do
		if math.sqrt((lx - p.X) ^ 2 + (lz - p.Z) ^ 2) < p.Flat + gap then
			return false
		end
	end
	return true
end

-- ¿Sitio bueno para poner algo? (en tierra, poco empinado, dentro de la zona jugable)
function Tefra.goodSpot(lx: number, lz: number, maxSlope: number, gap: number): boolean
	if math.max(math.abs(lx), math.abs(lz)) > Tefra.Half * 0.78 then
		return false
	end
	local x, z = Tefra.Origin.X + lx, Tefra.Origin.Z + lz
	local h, water = Tefra.groundAt(x, z)
	if water or h - Tefra.Origin.Y < Tefra.WaterY + 3 then
		return false
	end
	return Tefra.slopeAt(x, z) <= maxSlope and farFromPois(lx, lz, gap)
end

local nodesCache: { Node }? = nil
local nodesById: { [string]: Node } = {}
function Tefra.nodes(): { Node }
	if nodesCache then
		return nodesCache
	end
	local r = rng(Tefra.Seed * 977 + 13)
	local out: { Node } = {}
	local tries = 0
	while #out < Tefra.NodeCount and tries < 2000 do
		tries += 1
		local lx = (r() * 2 - 1) * Tefra.Half * 0.75
		local lz = (r() * 2 - 1) * Tefra.Half * 0.75
		if Tefra.goodSpot(lx, lz, 0.5, 30) then
			local ok = true
			for _, n in out do
				if math.sqrt((n.Pos.X - Tefra.Origin.X - lx) ^ 2 + (n.Pos.Z - Tefra.Origin.Z - lz) ^ 2) < 70 then
					ok = false
					break
				end
			end
			if ok then
				local roll = r()
				local ore = "Obsidiana"
				local acc = 0
				for _, id in { "Obsidiana", "Hierro", "Cobalto" } do
					acc += Tefra.NodeOres[id]
					if roll <= acc then
						ore = id
						break
					end
				end
				local x, z = Tefra.Origin.X + lx, Tefra.Origin.Z + lz
				local node = { Id = ("L%d"):format(#out + 1), Pos = Vector3.new(x, Tefra.heightAt(x, z), z), Ore = ore, Radius = 4 + r() * 3 }
				table.insert(out, node)
			end
		end
	end
	for _, n in out do
		nodesById[n.Id] = n
	end
	nodesCache = out
	return out
end

function Tefra.node(id: string): Node?
	Tefra.nodes()
	return nodesById[id]
end

-- Flora y rocas: { { Kind, Pos, Size, Turn } } (repetible). kind: "Pelusa" (plantas de semillas
-- blandas: la «lluvia de pelusa»), "Arbusto" (redondo), "Roca" (peñasco con la textura de roca)
Tefra.DecorCounts = { Pelusa = 110, Arbusto = 70, Roca = 80 }
function Tefra.decor(kind: string, count: number?): { { [string]: any } }
	local n = count or Tefra.DecorCounts[kind] or 0
	local seed = ({ Pelusa = 101, Arbusto = 202, Roca = 303 })[kind] or 404
	local r = rng(Tefra.Seed * 1009 + seed)
	local out = {}
	local tries = 0
	while #out < n and tries < n * 12 do
		tries += 1
		local lx = (r() * 2 - 1) * Tefra.Half * 0.8
		local lz = (r() * 2 - 1) * Tefra.Half * 0.8
		local maxSlope = if kind == "Roca" then 0.9 else 0.55
		if Tefra.goodSpot(lx, lz, maxSlope, if kind == "Roca" then 12 else 18) then
			local x, z = Tefra.Origin.X + lx, Tefra.Origin.Z + lz
			local size = if kind == "Roca" then 5 + r() ^ 2 * 22 elseif kind == "Arbusto" then 4 + r() * 6 else 3 + r() * 4
			table.insert(out, { Kind = kind, Pos = Vector3.new(x, Tefra.heightAt(x, z), z), Size = size, Turn = r() * math.pi * 2, Roll = r() })
		end
	end
	return out
end

---------------------------------------------------------------------
-- Para la nave (AirCombatService / AirCombatClient con World = "Planet")
---------------------------------------------------------------------
function Tefra.modeAt(_pos: Vector3): string
	return "Atmos"
end

-- Reaparecer (si te estrellas): encima de la plataforma, a media altura, mirando al lago
function Tefra.checkpoint(_section: string?, _near: Vector3?): CFrame
	local p = Tefra.toWorld(-200, 260, Tefra.padY() + 420)
	local target = Tefra.toWorld(380, -300, Tefra.padY() + 300)
	local look = (target - p).Unit
	local right = look:Cross(Vector3.new(0, 1, 0)).Unit
	return CFrame.fromMatrix(p, right, right:Cross(look).Unit, -look)
end

function Tefra.center(_section: string?): Vector3
	return Tefra.toWorld(0, 0, Tefra.padY() + 300)
end

function Tefra.contains(pos: Vector3, margin: number?): boolean
	return Tefra.inRegion(pos, margin)
end

-- Fuera del borde jugable: hacia dentro. (Arriba no hay techo: subir es volver al espacio.)
function Tefra.bounds(pos: Vector3): Vector3?
	local lx, lz = Tefra.toLocal(pos)
	local lim = Tefra.Half - 220
	local back = Vector3.zero
	if lx > lim then
		back += Vector3.new(-1, 0, 0)
	elseif lx < -lim then
		back += Vector3.new(1, 0, 0)
	end
	if lz > lim then
		back += Vector3.new(0, 0, -1)
	elseif lz < -lim then
		back += Vector3.new(0, 0, 1)
	end
	return if back.Magnitude > 0 then back.Unit else nil
end
Tefra.enemyBounds = Tefra.bounds

function Tefra.collide(pos: Vector3, radius: number): string?
	if not Tefra.inRegion(pos, 400) then
		return nil
	end
	local g, water = Tefra.groundAt(pos.X, pos.Z)
	if pos.Y - radius <= g then
		return if water then "el lago" else "el suelo"
	end
	return nil
end

function Tefra.segmentBlocked(a: Vector3, b: Vector3): boolean
	for i = 1, 4 do
		local p = a:Lerp(b, i / 4)
		if p.Y <= Tefra.heightAt(p.X, p.Z) then
			return true
		end
	end
	return false
end

function Tefra.turretSpots(_section: string?): { Vector3 }
	return {}
end

function Tefra.safeAt(_pos: Vector3): boolean
	return false
end

-- Para PlanetEntry (la superficie)
Tefra.Surface = {
	Id = Tefra.Id,
	Origin = Tefra.Origin,
	Half = Tefra.Half,
	ArriveY = Tefra.ArriveY,
	ClimbY = Tefra.ClimbY,
	CeilingY = Tefra.CeilingY,
}

return Tefra
