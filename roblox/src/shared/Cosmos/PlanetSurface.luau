-- PlanetSurface: la SUPERFICIE de un planeta hecha con DATOS (marco común de los planetas,
-- docs/planetas/marco-planetas.md). Cuentas puras, como shared/Cosmos/Tefra (que es el primero y va a
-- mano): PlanetSurface.new(def) devuelve un módulo con las MISMAS funciones que Tefra, así lo usan igual
-- el servidor (Services/PlanetService, World/PlanetWorld), el cliente (Controllers/PlanetClient,
-- AirCombatClient: choques y aterrizar) y las pruebas (scripts/test-planetas.luau).
--
--   def = {
--     Id, Name, Origin (Vector3: hueco reservado en PlanetRegistry.Slots), Half (media zona, studs),
--     Seed, WaterY, ArriveY, ClimbY, CeilingY, Floor, PadRadius,
--     City        = el plano de la ciudad (shared/Cosmos/PlanetCity.new): aplana la meseta, choques…
--     Terrain     = { Base, Amp, Hills, Valleys, Rocks, Edge } (colinas por defecto) o
--     rawHeight   = function(lx, lz, S) → altura local sin la ciudad (para cañones, picos, dunas…)
--     Materials   = { Shore, Steep, Rock, High, Patch, Ground, HighY, PatchFreq } (nombres de Enum.Material)
--     materialAt  = function(lx, lz, y, slope, S) → nombre (opcional: manda sobre Materials)
--     TerrainColors = { [material] = Color3 } (los pinta el CLIENTE solo mientras estás en el planeta:
--                    Controllers/PlanetClient; el terreno de Roblox comparte colores en todo el place)
--     WaterColor, Lakes = { { X, Z, R, Name } }, POIs = { { Id, Name, X, Z, Flat, Text } },
--     NodeCount, NodeOres = { { Id, Weight } } (minerales de shared/Cosmos/Mining), Reach,
--     DecorCounts = { [kind] = n }, DecorSlope = { [kind] = pendiente máxima },
--   }
-- Ids de mineral y de puntos llevan el prefijo del planeta («Miasma_L1», «Siroco_Baliza»): el servidor
-- encuentra de qué planeta es cada aviso sin mirar dónde estás.

local PlanetSurface = {}

local function smooth(e0: number, e1: number, x: number): number
	local t = math.clamp((x - e0) / (e1 - e0), 0, 1)
	return t * t * (3 - 2 * t)
end
PlanetSurface.smooth = smooth

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
PlanetSurface.fbm = fbm

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
PlanetSurface.rng = rng

export type Node = { Id: string, Pos: Vector3, Ore: string, Radius: number }

function PlanetSurface.new(def: { [string]: any }): { [string]: any }
	local S: { [string]: any } = {}
	for k, v in def do
		S[k] = v
	end
	S.Origin = def.Origin
	S.Half = def.Half or 1024
	S.Seed = def.Seed or 7
	S.WaterY = def.WaterY or 20
	S.ArriveY = def.ArriveY or 1100
	S.ClimbY = def.ClimbY or 1400
	S.CeilingY = def.CeilingY or 2000
	S.Floor = def.Floor or -40
	S.PadRadius = def.PadRadius or 40
	S.Reach = def.Reach or 14
	S.Lakes = def.Lakes or {}
	S.POIs = def.POIs or {}
	S.NodeCount = def.NodeCount or 0
	S.NodeOres = def.NodeOres or { { Id = "Hierro", Weight = 1 } }
	S.DecorCounts = def.DecorCounts or {}
	S.DecorSlope = def.DecorSlope or {}
	S.TerrainColors = def.TerrainColors or {}
	S.Prefix = def.Prefix or (def.Id .. "_")
	S.rng = rng
	local City = def.City
	local O = S.Origin

	S.PoiById = {}
	for _, p in S.POIs do
		S.PoiById[p.Id] = p
	end

	-- Coordenadas
	function S.toLocal(pos: Vector3): (number, number)
		return pos.X - O.X, pos.Z - O.Z
	end
	function S.toWorld(lx: number, lz: number, y: number): Vector3
		return Vector3.new(O.X + lx, y, O.Z + lz)
	end
	function S.inRegion(pos: Vector3, margin: number?): boolean
		local m = margin or 0
		local lx, lz = pos.X - O.X, pos.Z - O.Z
		return math.abs(lx) <= S.Half + m and math.abs(lz) <= S.Half + m and pos.Y >= S.Floor - 200 - m and pos.Y <= S.CeilingY + 600 + m
	end

	-- El terreno (colinas por defecto; el planeta puede traer el suyo: def.rawHeight)
	local T = def.Terrain or {}
	local seed = S.Seed * 0.173
	local function hills(lx: number, lz: number): number
		local h = (T.Base or 80) + (T.Amp or 140) * fbm(lx, lz, 5, 1 / (T.Scale or 900), seed)
		h += (T.Hills or 60) * math.max(0, fbm(lx, lz, 4, 1 / 430, seed + 3.1) + 0.08)
		local v = math.abs(fbm(lx, lz, 3, 1 / 1200, seed + 8.7))
		h -= (T.Valleys or 50) * smooth(0.11, 0.0, v)
		local rock = fbm(lx, lz, 3, 1 / 140, seed + 5.5)
		h += (T.Rocks or 20) * smooth(0.18, 0.4, rock) * smooth(80, 150, h)
		return h
	end
	S.hills = hills
	function S.rawHeight(lx: number, lz: number): number
		local h = if def.rawHeight then def.rawHeight(lx, lz, S) else hills(lx, lz)
		for _, lake in S.Lakes do
			local d = math.sqrt((lx - lake.X) ^ 2 + (lz - lake.Z) ^ 2)
			local k = smooth(lake.R * 1.5, lake.R * 0.55, d)
			h = h + (S.WaterY - 20 - h) * k
		end
		-- el borde: colinas grandes que cierran la zona (la niebla tapa lo de detrás)
		local edge = math.max(math.abs(lx), math.abs(lz)) / S.Half
		h += (T.Edge or 260) * smooth(0.8, 1.0, edge)
		return h
	end

	local padY: number? = nil
	function S.padY(): number
		if not padY then
			padY = if def.PadY then def.PadY else math.max(S.rawHeight(0, 0), S.WaterY + 14)
		end
		return padY :: number
	end

	local poiY: { [string]: number } = {}
	function S.poiY(id: string): number
		local p = S.PoiById[id]
		if not p then
			return 0
		end
		if not poiY[id] then
			poiY[id] = if p.Pad then S.padY() else math.max(S.rawHeight(p.X, p.Z), S.WaterY + 8)
		end
		return poiY[id]
	end

	function S.heightAt(x: number, z: number): number
		local lx, lz = x - O.X, z - O.Z
		local h = S.rawHeight(lx, lz)
		if City then
			h = City.shape(lx, lz, h, S.padY())
		end
		for _, p in S.POIs do
			if not p.Pad then
				local d = math.sqrt((lx - p.X) ^ 2 + (lz - p.Z) ^ 2)
				if d < p.Flat * 2.6 then
					local k = smooth(p.Flat * 2.6, p.Flat, d)
					h = h + (S.poiY(p.Id) - h) * k
				end
			end
		end
		return O.Y + h
	end

	function S.groundAt(x: number, z: number): (number, boolean)
		local h = S.heightAt(x, z)
		if h < O.Y + S.WaterY then
			return O.Y + S.WaterY, true
		end
		return h, false
	end

	function S.slopeAt(x: number, z: number): number
		local e = 4
		local dx = (S.heightAt(x + e, z) - S.heightAt(x - e, z)) / (2 * e)
		local dz = (S.heightAt(x, z + e) - S.heightAt(x, z - e)) / (2 * e)
		return math.sqrt(dx * dx + dz * dz)
	end

	local M = def.Materials or {}
	function S.materialAt(x: number, z: number, h: number?, slope: number?): string
		local y = (h or S.heightAt(x, z)) - O.Y
		local s = slope or S.slopeAt(x, z)
		local lx, lz = x - O.X, z - O.Z
		if def.materialAt then
			return def.materialAt(lx, lz, y, s, S)
		end
		if y < S.WaterY + 4 then
			return M.Shore or "Sand"
		elseif s > 1.25 then
			return M.Steep or "Slate"
		elseif s > 0.78 then
			return M.Rock or "Rock"
		end
		if M.High and y > (M.HighY or 200) then
			return M.High
		end
		if M.Patch and fbm(lx, lz, 3, 1 / (M.PatchFreq or 200), 29.1 + S.Seed) > 0.2 then
			return M.Patch
		end
		return M.Ground or "Ground"
	end

	-- Mineral (se extrae a pie: el mismo aviso «Extraer» que en Tefra)
	local function farFromPois(lx: number, lz: number, gap: number): boolean
		for _, p in S.POIs do
			if math.sqrt((lx - p.X) ^ 2 + (lz - p.Z) ^ 2) < p.Flat + gap then
				return false
			end
		end
		return true
	end
	function S.goodSpot(lx: number, lz: number, maxSlope: number, gap: number): boolean
		if math.max(math.abs(lx), math.abs(lz)) > S.Half * 0.78 then
			return false
		end
		if City and City.inside(lx, lz, City.Blend) then
			return false
		end
		local x, z = O.X + lx, O.Z + lz
		local h, water = S.groundAt(x, z)
		if water or h - O.Y < S.WaterY + 3 then
			return false
		end
		return S.slopeAt(x, z) <= maxSlope and farFromPois(lx, lz, gap)
	end

	local nodesCache: { Node }? = nil
	local nodesById: { [string]: Node } = {}
	function S.nodes(): { Node }
		if nodesCache then
			return nodesCache
		end
		local r = rng(S.Seed * 977 + 13)
		local out: { Node } = {}
		local tries = 0
		local total = 0
		for _, o in S.NodeOres do
			total += o.Weight
		end
		while #out < S.NodeCount and tries < 2000 do
			tries += 1
			local lx = (r() * 2 - 1) * S.Half * 0.75
			local lz = (r() * 2 - 1) * S.Half * 0.75
			if S.goodSpot(lx, lz, 0.5, 30) then
				local ok = true
				for _, n in out do
					if math.sqrt((n.Pos.X - O.X - lx) ^ 2 + (n.Pos.Z - O.Z - lz) ^ 2) < 70 then
						ok = false
						break
					end
				end
				if ok then
					local roll = r() * total
					local ore = S.NodeOres[1].Id
					local acc = 0
					for _, o in S.NodeOres do
						acc += o.Weight
						if roll <= acc then
							ore = o.Id
							break
						end
					end
					local x, z = O.X + lx, O.Z + lz
					table.insert(out, { Id = ("%sL%d"):format(S.Prefix, #out + 1), Pos = Vector3.new(x, S.heightAt(x, z), z), Ore = ore, Radius = 4 + r() * 3 })
				end
			end
		end
		for _, n in out do
			nodesById[n.Id] = n
		end
		nodesCache = out
		return out
	end
	function S.node(id: string): Node?
		S.nodes()
		return nodesById[id]
	end

	-- Flora y rocas: { { Kind, Pos, Size, Turn, Roll } } (repetible)
	function S.decor(kind: string, count: number?): { { [string]: any } }
		local n = count or S.DecorCounts[kind] or 0
		local h = 0
		for i = 1, #kind do
			h = (h * 31 + string.byte(kind, i)) % 100000
		end
		local r = rng(S.Seed * 1009 + h)
		local out = {}
		local tries = 0
		local maxSlope = S.DecorSlope[kind] or 0.6
		while #out < n and tries < n * 12 do
			tries += 1
			local lx = (r() * 2 - 1) * S.Half * 0.8
			local lz = (r() * 2 - 1) * S.Half * 0.8
			if S.goodSpot(lx, lz, maxSlope, 14) then
				local x, z = O.X + lx, O.Z + lz
				table.insert(out, { Kind = kind, Pos = Vector3.new(x, S.heightAt(x, z), z), Size = 3 + r() ^ 2 * 16, Turn = r() * math.pi * 2, Roll = r() })
			end
		end
		return out
	end

	-- Para la nave (AirCombatService / AirCombatClient con World = "Planet")
	function S.modeAt(_pos: Vector3): string
		return "Atmos"
	end
	function S.checkpoint(_section: string?, _near: Vector3?): CFrame
		local p = S.toWorld(-160, 220, S.padY() + 380)
		local target = S.toWorld(0, 0, S.padY() + 60)
		local look = (target - p).Unit
		local right = look:Cross(Vector3.new(0, 1, 0)).Unit
		return CFrame.fromMatrix(p, right, right:Cross(look).Unit, -look)
	end
	function S.center(_section: string?): Vector3
		return S.toWorld(0, 0, S.padY() + 300)
	end
	function S.contains(pos: Vector3, margin: number?): boolean
		return S.inRegion(pos, margin)
	end
	function S.bounds(pos: Vector3): Vector3?
		local lx, lz = S.toLocal(pos)
		local lim = S.Half - 200
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
	S.enemyBounds = S.bounds
	function S.collide(pos: Vector3, radius: number): string?
		if not S.inRegion(pos, 400) then
			return nil
		end
		local g, water = S.groundAt(pos.X, pos.Z)
		if pos.Y - radius <= g then
			return if water then "el agua" else "el suelo"
		end
		local lx, lz = S.toLocal(pos)
		if City and City.inside(lx, lz, radius + 10) then
			local top = City.solidTop(lx, lz, radius * 0.6)
			if top and pos.Y - radius * 0.6 <= O.Y + S.padY() + top then
				return "un edificio"
			end
		end
		return nil
	end
	function S.landSlopeAt(x: number, z: number): number
		if City then
			local lx, lz = x - O.X, z - O.Z
			if City.landingBlocked(lx, lz) then
				return 9
			end
		end
		return S.slopeAt(x, z)
	end
	function S.segmentBlocked(a: Vector3, b: Vector3): boolean
		for i = 1, 4 do
			local p = a:Lerp(b, i / 4)
			if p.Y <= S.heightAt(p.X, p.Z) then
				return true
			end
		end
		return false
	end
	function S.turretSpots(_section: string?): { Vector3 }
		return {}
	end
	function S.safeAt(_pos: Vector3): boolean
		return false
	end

	S.Surface = { Id = S.Id, Origin = O, Half = S.Half, ArriveY = S.ArriveY, ClimbY = S.ClimbY, CeilingY = S.CeilingY }
	return S
end

return PlanetSurface
