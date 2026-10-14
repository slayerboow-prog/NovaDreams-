-- Relief: el relieve natural de la isla de Valmar (colinas, sierras y acantilados) FUERA de la ciudad.
-- Cuentas puras (sin servicios de Roblox): las usan scripts/build-place.luau (hornea el mapa), el
-- servidor (World/TerrainBuilder escribe el terreno), el cliente (siluetas lejanas, shared/Horizon) y
-- las pruebas (scripts/test-paisaje.luau). Documento: docs/paisaje/paisaje.md.
--
-- Cómo funciona (por qué así):
--   * El campo era una alfombra verde plana a Y = -1 con 12 «bolas» de montaña al norte. El relieve
--     nuevo NO puede mover nada de lo construido (calles, manzanas, aeropuerto, puertos, vía del tren,
--     zonas verdes, sitios de la historia…), así que se «hornea» una MÁSCARA al construir el mapa:
--     cada pieza de workspace.Town (menos los árboles, que se recolocan encima) marca su huella; el río,
--     los lagos y las zonas de misión que se montan al arrancar también. De cada punto se mide la
--     distancia a lo construido más cercano y a la costa.
--   * La altura de un punto = Amplitud(distancia) × Forma(x, z):
--       - Amplitud: 0 junto a lo construido (franja llana de Clear studs), sube suave en Ramp studs y
--         crece con lo «salvaje» que es la zona: colinas bajas entre barrios, sierras de 150-260 studs
--         en los grandes espacios vacíos (sobre todo en la costa norte y oeste). En la costa: playa
--         llana (Beach) y, en los tramos de acantilado (CityPlan.Cliffs), roca casi desde el agua.
--       - Forma: ruido fractal con crestas (sierras con valles), siempre igual (sin azar: math.noise).
--   * El mapa horneado son las amplitudes en una rejilla de Cell studs, codificadas en texto (un
--     carácter por nudo, de Step en Step studs). Entre nudos se interpola: la altura sale continua.
--   * Las montañas de siempre (CityPlan.Mountains, bolas del terreno) se quedan: el relieve se suma
--     por fuera (la superficie es la más alta de las dos) y las une en una sierra.

local Relief = {}

Relief.Version = 1
Relief.Base = -1 -- suelo del campo (TerrainBuilder: la hierba llega a Y = -1)
Relief.Cell = 32 -- studs entre nudos del mapa horneado
Relief.Fine = 16 -- studs de la rejilla con la que se mide la distancia a lo construido
Relief.MinX, Relief.MinZ = -5024, -4416 -- esquina de la rejilla (múltiplos de Cell; CityPlan.Bounds con margen)
Relief.NX, Relief.NZ = 315, 274 -- nudos (cubren hasta X = 5024, Z = 4320)
Relief.Step = 5 -- studs de amplitud por cada carácter
Relief.Clear = 40 -- franja llana alrededor de todo lo construido (studs)
Relief.Ramp = 200 -- de llano a colina en estos studs
Relief.Beach = 70 -- ancho de la playa (TerrainBuilder.BEACH)
Relief.MinAmp, Relief.MaxAmp = 30, 270 -- amplitud de las colinas bajas y de las sierras más altas
Relief.WildFrom, Relief.WildTo = 80, 620 -- distancia a lo construido en la que se pasa de colina a sierra
Relief.Alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"
Relief.MaxCode = 63

-- Amp: amplitud de cada nudo (studs). Built (opcional): qué parte de alrededor del nudo está construida
-- (0..1; lo usan las siluetas lejanas para pintar la ciudad gris y el campo verde: shared/Horizon)
export type Field = { NX: number, NZ: number, MinX: number, MinZ: number, Cell: number, Step: number, Amp: { number }, Built: { number }? }
export type Rect = { X0: number, Z0: number, X1: number, Z1: number }
export type Disc = { X: number, Z: number, R: number }

local function smooth(a: number, b: number, x: number): number
	local t = math.clamp((x - a) / (b - a), 0, 1)
	return t * t * (3 - 2 * t)
end
Relief.smooth = smooth

---------------------------------------------------------------------
-- Forma del relieve (0..1): siempre la misma en cada punto
---------------------------------------------------------------------

local function fbm(x: number, z: number, octaves: number, seed: number): number
	local sum, amp, freq, norm = 0, 1, 1, 0
	for i = 1, octaves do
		sum += amp * math.noise(x * freq + seed, z * freq - seed, seed * 0.37 + i * 1.91)
		norm += amp
		amp *= 0.5
		freq *= 2.03
	end
	return sum / norm -- más o menos entre -0,5 y 0,5
end

-- Forma: lomas anchas (fbm suave) con crestas encima (ruido «ridged»: valles en V y cumbres afiladas)
-- y un poco de detalle fino (bultos de unos 100 studs) para que las laderas no sean lisas.
function Relief.shape(x: number, z: number): number
	local broad = math.clamp(0.5 + fbm(x / 1150, z / 1150, 3, 3.7) * 1.7, 0, 1)
	local r = 1 - math.abs(fbm(x / 640, z / 640, 4, 11.3)) * 2.4
	local ridge = math.clamp(r, 0, 1) ^ 2.2
	local detail = fbm(x / 110, z / 110, 2, 23.9)
	local s = 0.22 + 0.5 * broad + 0.42 * ridge * (0.35 + 0.65 * broad) + 0.1 * detail
	return math.clamp(s, 0, 1)
end

---------------------------------------------------------------------
-- Mapa horneado
---------------------------------------------------------------------

function Relief.index(field: Field, i: number, j: number): number
	return j * field.NX + i + 1
end

-- Amplitud (studs) en un punto: interpolada entre los 4 nudos de alrededor
function Relief.amplitude(field: Field, x: number, z: number): number
	local fx, fz = (x - field.MinX) / field.Cell, (z - field.MinZ) / field.Cell
	local i, j = math.floor(fx), math.floor(fz)
	if i < 0 or j < 0 or i >= field.NX - 1 or j >= field.NZ - 1 then
		return 0
	end
	local tx, tz = fx - i, fz - j
	local amp, nx = field.Amp, field.NX
	local k = j * nx + i + 1
	local a, b, c, d = amp[k], amp[k + 1], amp[k + nx], amp[k + nx + 1]
	if a == 0 and b == 0 and c == 0 and d == 0 then
		return 0
	end
	return (a * (1 - tx) + b * tx) * (1 - tz) + (c * (1 - tx) + d * tx) * tz
end

-- Altura del relieve SOBRE el suelo del campo (0 = llano) en un punto
function Relief.height(field: Field?, x: number, z: number): number
	if not field then
		return 0
	end
	local amp = Relief.amplitude(field, x, z)
	if amp <= 0.05 then
		return 0
	end
	return amp * Relief.shape(x, z)
end

-- Altura del suelo del relieve (Y del mundo) en un punto
function Relief.surfaceY(field: Field?, x: number, z: number): number
	return Relief.Base + Relief.height(field, x, z)
end

-- Pendiente (subida por stud) del relieve en un punto
function Relief.slope(field: Field?, x: number, z: number, step: number?): number
	local s = step or 4
	local dx = Relief.height(field, x + s, z) - Relief.height(field, x - s, z)
	local dz = Relief.height(field, x, z + s) - Relief.height(field, x, z - s)
	return math.sqrt(dx * dx + dz * dz) / (2 * s)
end

-- Las montañas de siempre (CityPlan.Mountains): bola de radio R con la cima a H y, si tienen roca,
-- otra bola de roca de radio R·0,42 (TerrainBuilder). Altura de su superficie (Y) o -math.huge.
function Relief.domeY(mountains: { any }, x: number, z: number): number
	local y = -math.huge
	for _, m in mountains do
		local d2 = (x - m.X) ^ 2 + (z - m.Z) ^ 2
		if d2 < m.R * m.R then
			y = math.max(y, (m.H - m.R) + math.sqrt(m.R * m.R - d2))
		end
		if m.Rock then
			local r = m.R * 0.42
			if d2 < r * r then
				y = math.max(y, (m.H - r * 0.9) + math.sqrt(r * r - d2))
			end
		end
	end
	return y
end

function Relief.encode(field: Field): string
	local alphabet = Relief.Alphabet
	local chars = table.create(#field.Amp)
	for k, amp in field.Amp do
		local code = math.clamp(math.floor(amp / field.Step + 0.5), 0, Relief.MaxCode)
		chars[k] = string.sub(alphabet, code + 1, code + 1)
	end
	return table.concat(chars)
end

local decodeMap: { [number]: number }? = nil
function Relief.decode(text: string, meta: { [string]: any }?): Field?
	local m = meta or {}
	local nx, nz = m.NX or Relief.NX, m.NZ or Relief.NZ
	if type(text) ~= "string" or #text ~= nx * nz then
		return nil
	end
	if not decodeMap then
		local map = {}
		for i = 1, #Relief.Alphabet do
			map[string.byte(Relief.Alphabet, i)] = i - 1
		end
		decodeMap = map
	end
	local map = decodeMap :: { [number]: number }
	local step = m.Step or Relief.Step
	local amp = table.create(nx * nz, 0)
	for k = 1, nx * nz do
		amp[k] = (map[string.byte(text, k)] or 0) * step
	end
	return { NX = nx, NZ = nz, MinX = m.MinX or Relief.MinX, MinZ = m.MinZ or Relief.MinZ, Cell = m.Cell or Relief.Cell, Step = step, Amp = amp }
end

-- Lo construido alrededor de cada nudo (0..1), en texto (un carácter por nudo)
function Relief.encodeBuilt(field: Field): string
	local alphabet = Relief.Alphabet
	local list = field.Built or {}
	local chars = table.create(field.NX * field.NZ)
	for k = 1, field.NX * field.NZ do
		local code = math.clamp(math.floor((list[k] or 0) * Relief.MaxCode + 0.5), 0, Relief.MaxCode)
		chars[k] = string.sub(alphabet, code + 1, code + 1)
	end
	return table.concat(chars)
end

function Relief.decodeBuilt(text: string?, field: Field): { number }?
	if type(text) ~= "string" or #text ~= field.NX * field.NZ then
		return nil
	end
	local out = table.create(#text, 0)
	for k = 1, #text do
		local code = string.find(Relief.Alphabet, string.sub(text, k, k), 1, true)
		out[k] = if code then (code - 1) / Relief.MaxCode else 0
	end
	return out
end

-- Lo construido en un punto (0..1, el nudo más cercano)
function Relief.builtAt(field: Field, x: number, z: number): number
	local list = field.Built
	if not list then
		return 0
	end
	local i = math.floor((x - field.MinX) / field.Cell + 0.5)
	local j = math.floor((z - field.MinZ) / field.Cell + 0.5)
	if i < 0 or j < 0 or i >= field.NX or j >= field.NZ then
		return 0
	end
	return list[j * field.NX + i + 1] or 0
end

-- Lee el mapa horneado de un StringValue (ServerStorage/ReplicatedStorage «ReliefMap»)
function Relief.fromValue(value: Instance?): Field?
	if not value or not value:IsA("StringValue") then
		return nil
	end
	local meta = {}
	for _, key in { "NX", "NZ", "MinX", "MinZ", "Cell", "Step" } do
		meta[key] = value:GetAttribute(key)
	end
	local field = Relief.decode((value :: StringValue).Value, meta)
	if field then
		local built = value:FindFirstChild("Built")
		if built and built:IsA("StringValue") then
			field.Built = Relief.decodeBuilt(built.Value, field)
		end
	end
	return field
end

---------------------------------------------------------------------
-- Horneado (al construir el mapa)
---------------------------------------------------------------------

-- Distancia (aprox. euclídea, chaflán 3-4) a las celdas marcadas, en celdas
local function chamfer(nx: number, nz: number, seed: { boolean }): { number }
	local INF = 1e9
	local d = table.create(nx * nz, INF)
	for k = 1, nx * nz do
		if seed[k] then
			d[k] = 0
		end
	end
	local A, B = 1, 1.4142
	for j = 0, nz - 1 do
		for i = 0, nx - 1 do
			local k = j * nx + i + 1
			local v = d[k]
			if v > 0 then
				if i > 0 then v = math.min(v, d[k - 1] + A) end
				if j > 0 then
					v = math.min(v, d[k - nx] + A)
					if i > 0 then v = math.min(v, d[k - nx - 1] + B) end
					if i < nx - 1 then v = math.min(v, d[k - nx + 1] + B) end
				end
				d[k] = v
			end
		end
	end
	for j = nz - 1, 0, -1 do
		for i = nx - 1, 0, -1 do
			local k = j * nx + i + 1
			local v = d[k]
			if v > 0 then
				if i < nx - 1 then v = math.min(v, d[k + 1] + A) end
				if j < nz - 1 then
					v = math.min(v, d[k + nx] + A)
					if i < nx - 1 then v = math.min(v, d[k + nx + 1] + B) end
					if i > 0 then v = math.min(v, d[k + nx - 1] + B) end
				end
				d[k] = v
			end
		end
	end
	return d
end

-- ¿Qué tramo de costa es acantilado? (CityPlan.Cliffs: tramos del contorno por índice de punto)
local function cliffSegments(plan: any): { { number } }
	local out = {}
	local coast = plan.Coast
	for _, c in plan.Cliffs or {} do
		for k = c[1], c[2] - 1 do
			local a, b = coast[k], coast[k + 1]
			if a and b then
				table.insert(out, { a[1], a[2], b[1], b[2] })
			end
		end
	end
	return out
end

-- Hornea el mapa de amplitudes.
--   plan:  shared/CityPlan (costa, acantilados, río, lagos)
--   rects: huellas de lo construido (cajas en planta, ya con su giro resuelto)
--   discs: círculos que también se dejan llanos (zonas de misión que se montan al arrancar…)
-- Devuelve el Field y unas cifras (para el informe y las pruebas).
function Relief.bake(plan: any, rects: { Rect }, discs: { Disc }?): (Field, { [string]: number })
	local F = Relief.Fine
	local nxF = (Relief.NX - 1) * (Relief.Cell // F) + 1
	local nzF = (Relief.NZ - 1) * (Relief.Cell // F) + 1
	local x0, z0 = Relief.MinX, Relief.MinZ
	local built = table.create(nxF * nzF, false)
	local sea = table.create(nxF * nzF, false)
	local riverOrDisc = table.create(nxF * nzF, false) -- (marcado por el río, un lago o un círculo, no por una pieza)
	local function cellRange(a: number, b: number, origin: number, n: number): (number, number)
		local i0 = math.max(0, math.floor((a - origin) / F + 0.5))
		local i1 = math.min(n - 1, math.floor((b - origin) / F + 0.5))
		return i0, i1
	end
	local marked = 0
	for _, r in rects do
		local i0, i1 = cellRange(math.min(r.X0, r.X1), math.max(r.X0, r.X1), x0, nxF)
		local j0, j1 = cellRange(math.min(r.Z0, r.Z1), math.max(r.Z0, r.Z1), z0, nzF)
		for j = j0, j1 do
			local row = j * nxF
			for i = i0, i1 do
				local k = row + i + 1
				if not built[k] then
					built[k] = true
					marked += 1
				end
			end
		end
	end
	local allDiscs = table.clone(discs or {})
	-- El río (con sus orillas) y los lagos: valles llanos
	for _, lake in plan.Lakes or {} do
		table.insert(allDiscs, { X = lake.X, Z = lake.Z, R = lake.R + 60 })
	end
	local riverPts = plan.River and plan.River.Points or {}
	local riverHalf = (plan.River and plan.River.Width or 0) / 2 + 50
	for j = 0, nzF - 1 do
		local z = z0 + j * F
		local spans = plan.spans(plan.Coast, z)
		for i = 0, nxF - 1 do
			local x = x0 + i * F
			local k = j * nxF + i + 1
			local inside = false
			for _, s in spans do
				if x > s[1] and x < s[2] then
					inside = true
					break
				end
			end
			if not inside then
				sea[k] = true
			elseif not built[k] then
				if #riverPts > 1 and plan.riverDistance(x, z) < riverHalf then
					built[k] = true
					riverOrDisc[k] = true
				else
					for _, d in allDiscs do
						if (x - d.X) ^ 2 + (z - d.Z) ^ 2 < d.R * d.R then
							built[k] = true
							riverOrDisc[k] = true
							break
						end
					end
				end
			end
		end
	end
	local dBuilt = chamfer(nxF, nzF, built)
	local dSea = chamfer(nxF, nzF, sea)
	local cliffs = cliffSegments(plan)
	local function nearCliff(x: number, z: number, coastDistance: number): boolean
		for _, s in cliffs do
			if plan.segmentDistance(x, z, s[1], s[2], s[3], s[4]) <= coastDistance + F * 1.5 then
				return true
			end
		end
		return false
	end
	-- Amplitud en la rejilla fina
	local ampF = table.create(nxF * nzF, 0)
	local stats = { Cells = 0, Raised = 0, Max = 0, Marked = marked }
	for j = 0, nzF - 1 do
		for i = 0, nxF - 1 do
			local k = j * nxF + i + 1
			stats.Cells += 1
			if not sea[k] and not built[k] then
				local x, z = x0 + i * F, z0 + j * F
				local d = dBuilt[k] * F
				local c = dSea[k] * F
				local inland = smooth(Relief.Clear, Relief.Clear + Relief.Ramp, d)
				local wild = smooth(Relief.WildFrom, Relief.WildTo, d)
				local coast
				if c < 420 and nearCliff(x, z, c) then
					coast = smooth(12, 120, c) -- acantilado: roca casi desde el agua
				else
					coast = smooth(Relief.Beach + 16, Relief.Beach + 230, c) -- playa llana y luego sube
				end
				local amp = (Relief.MinAmp + (Relief.MaxAmp - Relief.MinAmp) * wild) * inland * coast
				ampF[k] = amp
				if amp > 1 then
					stats.Raised += 1
				end
				stats.Max = math.max(stats.Max, amp)
			end
		end
	end
	-- A la rejilla gruesa: el MÍNIMO de las celdas finas alrededor de cada nudo (nunca sube junto a algo)
	local ratio = Relief.Cell // F
	local amp = table.create(Relief.NX * Relief.NZ, 0)
	local builtFrac = table.create(Relief.NX * Relief.NZ, 0)
	for j = 0, Relief.NZ - 1 do
		for i = 0, Relief.NX - 1 do
			local fi, fj = i * ratio, j * ratio
			local v = math.huge
			local n, b = 0, 0
			for dj = -1, 1 do
				for di = -1, 1 do
					local a, c = fi + di, fj + dj
					if a >= 0 and c >= 0 and a < nxF and c < nzF then
						local k = c * nxF + a + 1
						v = math.min(v, ampF[k])
						n += 1
						if built[k] and not sea[k] and dBuilt[k] == 0 and not riverOrDisc[k] then
							b += 1
						end
					end
				end
			end
			amp[j * Relief.NX + i + 1] = if v == math.huge then 0 else v
			builtFrac[j * Relief.NX + i + 1] = if n > 0 then b / n else 0
		end
	end
	local field: Field = { NX = Relief.NX, NZ = Relief.NZ, MinX = x0, MinZ = z0, Cell = Relief.Cell, Step = Relief.Step, Amp = amp, Built = builtFrac }
	-- (cuantizado igual que al guardarlo: lo que se usa al construir es lo mismo que leerá el servidor)
	local decoded = Relief.decode(Relief.encode(field)) :: Field
	decoded.Built = Relief.decodeBuilt(Relief.encodeBuilt(field), decoded)
	return decoded, stats
end

---------------------------------------------------------------------
-- Materiales del relieve (por pendiente, altura y manchas)
---------------------------------------------------------------------

-- Material de la superficie: «Grass» (con briznas 3D en los niveles Medio y Alto) en las lomas,
-- «LeafyGrass» en las manchas de pradera, «Ground» en los claros y caminos de tierra, «Rock» y «Slate»
-- en las laderas empinadas y en las cumbres, «Sand» en la playa.
function Relief.material(h: number, slope: number, x: number, z: number, coastNear: boolean?): string
	local n = math.noise(x / 70, z / 70, 4.2)
	local n2 = math.noise(x / 230, z / 230, 8.6)
	if coastNear and h < 5 then
		return "Sand"
	end
	if slope > 1.05 + 0.2 * n then
		return if n2 > 0.1 then "Slate" else "Rock"
	end
	if slope > 0.72 + 0.15 * n then
		return if n > 0.05 then "Rock" else "Ground"
	end
	if h > 175 + 30 * n2 and slope > 0.35 then
		return "Rock"
	end
	if h > 210 + 25 * n2 then
		return if n > 0 then "Rock" else "Ground"
	end
	if slope > 0.5 + 0.1 * n then
		return if n2 > 0 then "Ground" else "LeafyGrass"
	end
	if h < 2.5 then
		return "LeafyGrass" -- (el pie de las lomas: igual que el llano, sin briznas junto a nada)
	end
	if n2 > 0.22 then
		return "LeafyGrass"
	end
	return "Grass"
end

return Relief
