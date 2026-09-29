-- Prueba del suelo de las calles en el mapa construido, con Lune (Lune no sabe lanzar rayos: aquí
-- se hace a mano, con una rejilla de todas las piezas y un rayo vertical contra cada caja girada).
--
-- Uso (desde la carpeta roblox/):
--   rojo build default.project.json -o /tmp/x.rbxl && lune run scripts/build-place.luau /tmp/x.rbxl
--   lune run scripts/test-streets.luau /tmp/x.rbxl [--list]
--
-- Comprueba que:
--   * bajo cada punto de cada calzada, acera, cruce y rotonda (todo lo que se hunde en el terreno)
--     hay una pieza sólida a la altura de la calle: ningún hueco por el que caer bajo tierra
--     (solo se abre el suelo en la escalera de las bocas de metro)
--   * las rotondas son un anillo liso: asfalto entre la isla y el borde, acera alrededor y la isla
--     con bordillo, hierba y adorno; las marcas del carril siguen el círculo
--   * por la calzada no cruza ninguna acera ni bordillo: es asfalto a ras de punta a punta (también en
--     los cruces, las bocacalles y las entradas de las rotondas)
--   * los pasos de peatones están despejados: nada encima de las franjas (ni aceras, ni farolas,
--     papeleras, bancos o paradas), con las franjas a la vista y el bordillo rebajado a los dos lados

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Vector3, CFrame, Color3, Enum = roblox.Vector3, roblox.CFrame, roblox.Color3, roblox.Enum

---------------------------------------------------------------------
-- Cargador: módulos de src/shared y de src/server/World (solo datos, sin construir nada)
---------------------------------------------------------------------
local sharedProxy = setmetatable({}, {
	__index = function(_, name)
		return { __path = "src/shared/" .. name .. ".luau" }
	end,
})
local fakeGame = {
	GetService = function(_, name)
		if name == "ReplicatedStorage" then
			return { Shared = sharedProxy }
		end
		return setmetatable({}, { __index = function() return nil end })
	end,
}
local cache = {}
local requireModule
local function node(path: string, parent: any?): any
	local self = { __path = path, Parent = parent }
	if fs.isDir(path) then
		for _, name in fs.readDir(path) do
			local child = path .. "/" .. name
			if fs.isDir(child) then
				self[name] = node(child, self)
			elseif name:match("%.luau$") then
				self[(name:gsub("%.luau$", ""))] = node(child, self)
			end
		end
	end
	return self
end
function requireModule(target: any): any
	local path = rawget(target, "__path")
	if cache[path] ~= nil then
		return cache[path]
	end
	local env = setmetatable({
		script = target,
		require = requireModule,
		game = fakeGame,
		workspace = {},
		Instance = roblox.Instance,
		Vector3 = Vector3,
		Vector2 = roblox.Vector2,
		CFrame = CFrame,
		Color3 = Color3,
		Enum = roblox.Enum,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		Font = roblox.Font,
		NumberRange = roblox.NumberRange,
		NumberSequence = roblox.NumberSequence,
		ColorSequence = roblox.ColorSequence,
	}, { __index = getfenv(1) })
	local result = luau.load(fs.readFile(path), { debugName = path, environment = env })()
	cache[path] = result
	return result
end

local placePath = process.args[1]
if not placePath then
	print("Uso: lune run scripts/test-streets.luau <mapa construido .rbxl>")
	process.exit(1)
end
local LIST = table.find(process.args, "--list") ~= nil
local DETAIL = table.find(process.args, "--detail") ~= nil

local CityPlan = requireModule(sharedProxy.CityPlan)
local Metro = requireModule(sharedProxy.Metro)
local World = node("src/server/World", nil)
local Roads = requireModule(World.Kit.Roads)
local Region = requireModule(World.Region)

local failures = 0
local function check(ok: boolean, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

---------------------------------------------------------------------
-- Piezas del mapa y rayos verticales
---------------------------------------------------------------------
print("▶ Leyendo el mapa…")
local game = roblox.deserializePlace(fs.readFile(placePath))
local town = game:GetService("Workspace"):FindFirstChild("Town")
assert(town, "el mapa no tiene la ciudad construida (Workspace.Town)")

type Item = {
	Part: any,
	Kind: string, -- Block, Cylinder, Ball, Wedge
	C: { number },
	S: Vector3,
	Lo: Vector3,
	Hi: Vector3,
	Solid: boolean,
	Visible: boolean,
	Name: string,
}

local CELL = 16
local grid: { [number]: { Item } } = {}
local function cellKey(gx: number, gz: number): number
	return (gx + 2000) * 4000 + (gz + 2000)
end

local all: { Item } = {}
local zebras: { Item } = {}
local ramps: { Item } = {}
local crosswalks: { any } = {}
local roundabouts: { any } = {}
local count = 0
for _, d in town:GetDescendants() do
	if d:IsA("BasePart") then
		count += 1
		if d:HasTag("EditOnly") then
			continue -- (el suelo de previsualización se quita al arrancar el servidor)
		end
		local c = { d.CFrame:GetComponents() }
		local s = d.Size
		local hx = (math.abs(c[4]) * s.X + math.abs(c[5]) * s.Y + math.abs(c[6]) * s.Z) / 2
		local hy = (math.abs(c[7]) * s.X + math.abs(c[8]) * s.Y + math.abs(c[9]) * s.Z) / 2
		local hz = (math.abs(c[10]) * s.X + math.abs(c[11]) * s.Y + math.abs(c[12]) * s.Z) / 2
		local lo = Vector3.new(c[1] - hx, c[2] - hy, c[3] - hz)
		local hi = Vector3.new(c[1] + hx, c[2] + hy, c[3] + hz)
		if hi.Y < -1.5 or lo.Y > 10 then
			continue
		end
		local kind = "Block"
		if d:IsA("WedgePart") then
			kind = "Wedge"
		elseif d:IsA("Part") then
			if d.Shape == Enum.PartType.Cylinder then
				kind = "Cylinder"
			elseif d.Shape == Enum.PartType.Ball then
				kind = "Ball"
			end
		end
		local item: Item = {
			Part = d,
			Kind = kind,
			C = c,
			S = s,
			Lo = lo,
			Hi = hi,
			Solid = d.CanCollide,
			Visible = d.Transparency < 0.9,
			Name = d.Name,
		}
		table.insert(all, item)
		for gx = math.floor(lo.X / CELL), math.floor(hi.X / CELL) do
			for gz = math.floor(lo.Z / CELL), math.floor(hi.Z / CELL) do
				local k = cellKey(gx, gz)
				local list = grid[k]
				if not list then
					list = {}
					grid[k] = list
				end
				table.insert(list, item)
			end
		end
		if d.Name == "Zebra" then
			table.insert(zebras, item)
		elseif d.Name == "KerbRamp" then
			table.insert(ramps, item)
		end
	elseif d:IsA("Model") and d.Name == "PasoCebra" then
		table.insert(crosswalks, d)
	elseif d:IsA("Model") and d.Name == "Rotonda" then
		table.insert(roundabouts, d)
	end
end
print(("  %d piezas en el mapa; %d a la altura de la calle"):format(count, #all))

-- Tramo [lo, hi] de la vertical (x, z) dentro de la pieza (nil si no la toca)
local function span(it: Item, x: number, z: number): (number?, number?)
	if x < it.Lo.X or x > it.Hi.X or z < it.Lo.Z or z > it.Hi.Z then
		return nil
	end
	local c, s = it.C, it.S
	local dx, dz = x - c[1], z - c[3]
	-- Coordenadas locales a lo largo de la vertical: l_i(t) = a_i + b_i * t (t = altura)
	local a, b = {}, {}
	for i = 1, 3 do
		local r0, r1, r2 = c[3 + i], c[6 + i], c[9 + i] -- columna i de la rotación
		a[i] = r0 * dx + r2 * dz - r1 * c[2]
		b[i] = r1
	end
	local half = { s.X / 2, s.Y / 2, s.Z / 2 }
	local tlo, thi = -math.huge, math.huge
	local function slab(i: number)
		if math.abs(b[i]) < 1e-9 then
			if math.abs(a[i]) > half[i] + 1e-6 then
				tlo, thi = 1, 0
			end
			return
		end
		local t1, t2 = (-half[i] - a[i]) / b[i], (half[i] - a[i]) / b[i]
		if t1 > t2 then
			t1, t2 = t2, t1
		end
		tlo, thi = math.max(tlo, t1), math.min(thi, t2)
	end
	local function circle(i: number, j: number, r: number)
		-- (a_i + b_i t)^2 + (a_j + b_j t)^2 <= r^2
		local A = b[i] * b[i] + b[j] * b[j]
		local B = 2 * (a[i] * b[i] + a[j] * b[j])
		local C = a[i] * a[i] + a[j] * a[j] - r * r
		if A < 1e-12 then
			if C > 1e-6 then
				tlo, thi = 1, 0
			end
			return
		end
		local disc = B * B - 4 * A * C
		if disc < 0 then
			tlo, thi = 1, 0
			return
		end
		local q = math.sqrt(disc)
		tlo, thi = math.max(tlo, (-B - q) / (2 * A)), math.min(thi, (-B + q) / (2 * A))
	end
	if it.Kind == "Cylinder" then
		slab(1)
		circle(2, 3, math.min(s.Y, s.Z) / 2)
	elseif it.Kind == "Ball" then
		local r = math.min(s.X, s.Y, s.Z) / 2
		local A = b[1] ^ 2 + b[2] ^ 2 + b[3] ^ 2
		local B = 2 * (a[1] * b[1] + a[2] * b[2] + a[3] * b[3])
		local C = a[1] ^ 2 + a[2] ^ 2 + a[3] ^ 2 - r * r
		local disc = B * B - 4 * A * C
		if disc < 0 then
			return nil
		end
		local q = math.sqrt(disc)
		tlo, thi = (-B - q) / (2 * A), (-B + q) / (2 * A)
	else
		slab(1)
		slab(2)
		slab(3)
		if it.Kind == "Wedge" and tlo <= thi then
			-- La cuña: alta atrás (+Z), a ras delante (-Z): y/h - z/d <= 0 en coordenadas locales
			local k0 = a[2] / s.Y - a[3] / s.Z
			local k1 = b[2] / s.Y - b[3] / s.Z
			if math.abs(k1) < 1e-9 then
				if k0 > 1e-6 then
					return nil
				end
			elseif k1 > 0 then
				thi = math.min(thi, -k0 / k1)
			else
				tlo = math.max(tlo, -k0 / k1)
			end
		end
	end
	if tlo > thi then
		return nil
	end
	return tlo, thi
end

local function query(x: number, z: number): { Item }
	return grid[cellKey(math.floor(x / CELL), math.floor(z / CELL))] or {}
end

-- ¿Hay suelo sólido a la altura de la calle en (x, z)? Devuelve true/false y la cara más alta
local function floorAt(x: number, z: number): (boolean, number)
	local best = -math.huge
	for _, it in query(x, z) do
		if it.Solid then
			local lo, hi = span(it, x, z)
			if lo and hi then
				if hi >= 0.2 and hi <= 1.75 then
					return true, hi
				end
				if lo <= 0.3 and hi > 1.75 then
					return true, hi -- algo macizo (un bolardo, una pared): no es un agujero
				end
				if hi < 0.2 then
					best = math.max(best, hi)
				end
			end
		end
	end
	return false, best
end

---------------------------------------------------------------------
-- Dónde se abre el suelo a propósito: la escalera de cada boca de metro
---------------------------------------------------------------------
local openings = {}
for id in Metro.Stations do
	local S = Metro.access(id).Stair
	local dir = Vector3.new(S.Dir.X, 0, S.Dir.Z).Unit
	table.insert(openings, { Top = Vector3.new(S.Top.X, 0, S.Top.Z), Dir = dir, Length = S.Length + 1, Half = S.Width / 2 + 1.2 })
end
local function inOpening(x: number, z: number): boolean
	for _, o in openings do
		local rel = Vector3.new(x, 0, z) - o.Top
		local along = rel:Dot(o.Dir)
		local side = math.abs(rel.X * o.Dir.Z - rel.Z * o.Dir.X)
		if along > -1.2 and along < o.Length and side < o.Half then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
-- 1) Sin huecos bajo calles, aceras, cruces y rotondas
---------------------------------------------------------------------
print("▶ Suelo bajo las calles")
local gaps: { [string]: { Vector3 } } = {}
local gapKeys: { [string]: boolean } = {}
local samples = 0
local function sample(group: string, x: number, z: number)
	if inOpening(x, z) then
		return
	end
	samples += 1
	local ok = floorAt(x, z)
	if not ok then
		local k = math.floor(x) .. ":" .. math.floor(z)
		if not gapKeys[k] then
			gapKeys[k] = true
			gaps[group] = gaps[group] or {}
			table.insert(gaps[group], Vector3.new(x, 0, z))
		end
	end
end

local STEP = 2
-- Carreteras principales (todo su ancho, de nodo a nodo: lo que se hunde en el terreno)
for _, s in Roads.segments() do
	local kind = Roads.Kinds[s.Kind]
	local dir = (s.B - s.A).Unit
	local perp = Vector3.new(-dir.Z, 0, dir.X)
	local len = (s.B - s.A).Magnitude
	local w = kind.Road / 2 + kind.Walk - 0.6
	for d = 0, len, STEP do
		for v = -w, w + 0.01, STEP do
			local p = s.A + dir * d + perp * v
			sample((if math.abs(v) <= kind.Road / 2 then "Calzada principal" else "Acera principal") .. (if DETAIL then " · " .. s.Name else ""), p.X, p.Z)
		end
	end
end
-- Cruces y rotondas (los círculos donde se hunde el terreno)
local _, circles = Roads.footprints()
for _, c in circles do
	local r = c.Radius - 0.6
	for x = -r, r, STEP do
		for z = -r, r, STEP do
			if x * x + z * z <= r * r then
				sample(if c.Radius > 50 then "Rotonda" else "Cruce", c.Position.X + x, c.Position.Z + z)
			end
		end
	end
end
-- Calles de los barrios y de la cuadrícula (todo el rectángulo hundido)
for _, road in Region.roads() do
	for u = road.From + 0.3, road.To - 0.3, STEP do
		for v = -19.4, 19.41, STEP * 1.2 do
			local x, z = if road.Axis == "X" then u else road.At + v, if road.Axis == "X" then road.At + v else u
			sample(if math.abs(v) <= 12 then "Calzada de barrio" else "Acera de barrio", x, z)
		end
	end
end
local total = 0
local groups = {}
for group, list in gaps do
	total += #list
	table.insert(groups, group)
end
table.sort(groups)
print(("  %d puntos comprobados; %d huecos"):format(samples, total))
for _, group in groups do
	local list = gaps[group]
	print(("    %s: %d"):format(group, #list))
	for i = 1, math.min(#list, if LIST then 400 else 6) do
		local p = list[i]
		local _, top = floorAt(p.X, p.Z)
		print(("      (%.0f, %.0f)%s"):format(p.X, p.Z, if top > -math.huge then (" suelo a %.2f"):format(top) else ""))
	end
end
check(total == 0, "ningún hueco bajo las calles, aceras, cruces y rotondas (solo la escalera del metro)")

-- Una calle que sigue a una carretera en la misma línea empieza donde acaba la carretera: sin un trozo
-- de terreno entre las dos (pasaba en la entrada de Los Pinos y de Valmar Norte)
local cutOff: { string } = {}
for _, road in Region.roads() do
	for _, s in Roads.segments() do
		local sa = if road.Axis == "X" then s.A.Z - road.At else s.A.X - road.At
		local sb = if road.Axis == "X" then s.B.Z - road.At else s.B.X - road.At
		if math.abs(sa) < 1 and math.abs(sb) < 1 then
			local ua = if road.Axis == "X" then s.A.X else s.A.Z
			local ub = if road.Axis == "X" then s.B.X else s.B.Z
			local lo, hi = math.min(ua, ub), math.max(ua, ub)
			local gap = math.max(road.From - hi, lo - road.To)
			local mid = if road.From - hi > lo - road.To then (road.From + hi) / 2 else (lo + road.To) / 2
			local mx, mz = if road.Axis == "X" then mid else road.At, if road.Axis == "X" then road.At else mid
			local covered = false
			for _, c in select(2, Roads.footprints()) do
				if (Vector3.new(mx, 0, mz) - Vector3.new(c.Position.X, 0, c.Position.Z)).Magnitude < c.Radius then
					covered = true -- (lo tapa una rotonda o un cruce)
				end
			end
			if gap > 0.5 and gap < 80 and not covered then
				table.insert(cutOff, ("%s y la calle %s=%.0f: %.0f studs sin asfalto"):format(s.Name, if road.Axis == "X" then "Z" else "X", road.At, gap))
			end
		end
	end
end
for i = 1, math.min(#cutOff, 6) do
	print("      " .. cutOff[i])
end
check(#cutOff == 0, "cada calle empieza justo donde acaba la carretera que la continúa (sin trozos de terreno)")

-- Por la calzada no cruza ninguna acera: la cara de arriba del suelo está a la altura del asfalto
local steps: { string } = {}
local stepCount = 0
local function roadTop(group: string, x: number, z: number)
	if inOpening(x, z) then
		return
	end
	local best = -math.huge
	for _, it in query(x, z) do
		if it.Solid and it.Name ~= "KerbRamp" then
			local lo, hi = span(it, x, z)
			if lo and hi and hi < 3 and hi > best then
				best = hi
			end
		end
	end
	if best > 0.75 then
		stepCount += 1
		if #steps < (if LIST then 300 else 6) then
			table.insert(steps, ("      %s (%.0f, %.0f): suelo a %.2f"):format(group, x, z, best))
		end
	end
end
for _, s in Roads.segments() do
	local kind = Roads.Kinds[s.Kind]
	local dir = (s.B - s.A).Unit
	local perp = Vector3.new(-dir.Z, 0, dir.X)
	local len = (s.B - s.A).Magnitude
	local w = kind.Road / 2 - 2.2
	for d = 0.5, len - 0.5, 3 do
		for v = -w, w + 0.01, 3 do
			if kind.Median == 0 or math.abs(v) > kind.Median / 2 + 0.5 then
				local p = s.A + dir * d + perp * v
				-- (en la isla de las rotondas no hay calzada)
				local island = false
				for _, rb in CityPlan.Roundabouts do
					if (p - Vector3.new(rb[1], 0, rb[2])).Magnitude < (Roads.ISLAND_R or 22) + 2 then
						island = true
					end
				end
				-- (donde la carretera acaba dentro de una calle de barrio, manda la calle: su acera del otro lado)
				local street = false
				for _, road in Region.roads() do
					local u = if road.Axis == "X" then p.X else p.Z
					local w = if road.Axis == "X" then p.Z else p.X
					if u > road.From - 1 and u < road.To + 1 and math.abs(w - road.At) < 20.5 then
						street = true
						break
					end
				end
				if not island and not street then
					roadTop("Calzada principal", p.X, p.Z)
				end
			end
		end
	end
end
for _, road in Region.roads() do
	for u = road.From, road.To, 3 do
		for v = -9.9, 9.91, 3.3 do
			local x, z = if road.Axis == "X" then u else road.At + v, if road.Axis == "X" then road.At + v else u
			local island = false
			for _, rb in CityPlan.Roundabouts do
				if (Vector3.new(x, 0, z) - Vector3.new(rb[1], 0, rb[2])).Magnitude < (Roads.ISLAND_R or 22) + 2 then
					island = true
				end
			end
			-- (donde la calle se mete en una carretera principal, manda la carretera: mediana incluida)
			local main = false
			for _, seg in Roads.segments() do
				local kind = Roads.Kinds[seg.Kind]
				if CityPlan.segmentDistance(x, z, seg.A.X, seg.A.Z, seg.B.X, seg.B.Z) < kind.Road / 2 + kind.Walk then
					main = true
					break
				end
			end
			if not island and not main then
				roadTop("Calzada de barrio", x, z)
			end
		end
	end
end
for _, line in steps do
	print(line)
end
check(stepCount == 0, ("ninguna acera ni bordillo cruza la calzada (%d puntos con escalón)"):format(stepCount))

---------------------------------------------------------------------
-- 2) Rotondas: anillo liso
---------------------------------------------------------------------
print("▶ Rotondas")
check(#roundabouts == #CityPlan.Roundabouts, ("hay %d rotondas (una por punto del plano)"):format(#roundabouts))
local ringBad = 0
for _, rb in CityPlan.Roundabouts do
	local c = Vector3.new(rb[1], 0, rb[2])
	-- En el anillo (entre la isla y el borde) todo es asfalto a la misma altura
	for k = 0, 71 do
		local ang = k / 72 * math.pi * 2
		for _, r in { (Roads.ISLAND_R or 22) + 3, ((Roads.ISLAND_R or 22) + (Roads.ROUNDABOUT_R or 56)) / 2, (Roads.ROUNDABOUT_R or 56) - 2 } do
			local x, z = c.X + math.cos(ang) * r, c.Z + math.sin(ang) * r
			local ok, top = floorAt(x, z)
			if not ok or math.abs(top - 0.4) > 0.08 then
				ringBad += 1
				if ringBad <= 6 then
					print(("      anillo (%.0f, %.0f): %s"):format(x, z, if ok then ("suelo a %.2f"):format(top) else "hueco"))
				end
			end
		end
	end
end
check(ringBad == 0, "el anillo de cada rotonda es asfalto liso a ras (sin aceras ni escalones metidos)")
local rbInfo = { Marks = 0, Curb = 0, Island = 0, Walk = 0, Tree = 0 }
for _, m in roundabouts do
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Name == "RingMarking" then
				rbInfo.Marks += 1
			elseif d.Name == "IslandCurb" then
				rbInfo.Curb += 1
			elseif d.Name == "Island" then
				rbInfo.Island += 1
			elseif d.Name == "RingSidewalk" then
				rbInfo.Walk += 1
			end
		elseif d:IsA("Model") and (d.Name == "Tree" or d.Name == "Arbol" or d.Name == "Fountain" or d.Name == "Fuente") then
			rbInfo.Tree += 1
		end
	end
end
local n = math.max(#roundabouts, 1)
check(rbInfo.Marks / n >= 24, ("marcas del carril siguiendo el anillo (%.0f por rotonda)"):format(rbInfo.Marks / n))
check(rbInfo.Curb / n >= 24, ("bordillo de la isla hecho de muchos trozos (%.0f por rotonda)"):format(rbInfo.Curb / n))
check(rbInfo.Island >= #roundabouts, "cada rotonda tiene su isla de césped")
check(rbInfo.Walk / n >= 24, ("acera alrededor de la rotonda (%.0f trozos por rotonda)"):format(rbInfo.Walk / n))

---------------------------------------------------------------------
-- 3) Pasos de peatones despejados
---------------------------------------------------------------------
print("▶ Pasos de peatones")
local IGNORE = { Zebra = true, Marking = true, Road = true, Junction = true, KerbRamp = true, Manhole = true, Drain = true, RingMarking = true, StopLine = true }
local blocked, hidden = 0, 0
local blockers: { [string]: number } = {}
for _, z in zebras do
	local top = z.Hi.Y
	local c = z.C
	-- Tres puntos de la franja (centro y cerca de cada punta)
	local len = math.max(z.S.X, z.S.Z)
	local axis = if z.S.X >= z.S.Z then Vector3.new(c[4], 0, c[10]) else Vector3.new(c[6], 0, c[12])
	for _, f in { -0.4, 0, 0.4 } do
		local p = Vector3.new(c[1], 0, c[3]) + axis * (len * f)
		local bad = nil
		for _, it in query(p.X, p.Z) do
			if it ~= z and not IGNORE[it.Name] and (it.Solid or it.Visible) then
				local lo, hi = span(it, p.X, p.Z)
				if lo and hi and hi > top + 0.06 and lo < top + 6 then
					bad = it
					break
				end
			end
		end
		if bad then
			if bad.Name == "Sidewalk" or bad.Name == "Curb" then
				hidden += 1
			else
				blocked += 1
			end
			blockers[bad.Name] = (blockers[bad.Name] or 0) + 1
			if LIST or (blocked + hidden) <= 6 then
				print(("      franja en (%.0f, %.0f) tapada por %s"):format(p.X, p.Z, bad.Name))
			end
			break
		end
	end
end
local names = {}
for name, k in blockers do
	table.insert(names, ("%s ×%d"):format(name, k))
end
table.sort(names)
print(("  %d franjas de cebra; %d pasos de peatones; %d rampas de bordillo"):format(#zebras, #crosswalks, #ramps))
if #names > 0 then
	print("    encima: " .. table.concat(names, ", "))
end
check(#zebras > 500, "hay pasos de cebra por toda la ciudad")
check(hidden == 0, "ninguna acera ni bordillo cruza por encima de un paso de cebra")
check(blocked == 0, "nada (farolas, papeleras, bancos, paradas…) encima de un paso de cebra")
-- Cada paso de peatones lleva el bordillo rebajado a los dos lados (donde hay acera)
local noRamp = 0
for _, m in crosswalks do
	local k = 0
	for _, d in m:GetChildren() do
		if d.Name == "KerbRamp" then
			k += 1
		end
	end
	if k < 2 and not m:GetAttribute("NoWalk") then
		noRamp += 1
	end
end
check(#crosswalks > 200 and noRamp == 0, ("bordillo rebajado a los dos lados de cada paso de peatones (%d sin rampas)"):format(noRamp))

---------------------------------------------------------------------
-- Peatones por las aceras: esquivan farolas, papeleras, quioscos, árboles, motos aparcadas…
-- (los estorbos se calculan como World/Ambient.obstacles y cada peatón elige su hueco con
-- shared/Sidewalk.lane, igual que Controllers/Ambient)
---------------------------------------------------------------------
print("▶ Peatones por las aceras")
do
	local Sidewalk = requireModule(sharedProxy.Sidewalk)
	local walks = {}
	for _, road in Region.roads() do
		local a = if road.Axis == "X" then Vector3.new(road.From, 0, road.At) else Vector3.new(road.At, 0, road.From)
		local b = if road.Axis == "X" then Vector3.new(road.To, 0, road.At) else Vector3.new(road.At, 0, road.To)
		table.insert(walks, { A = a, B = b, In = 12, Out = 20 }) -- (lo mismo que publica World/Ambient)
	end
	for _, seg in Roads.segments() do
		local k = Roads.Kinds[seg.Kind]
		if k.Walk > 0 then
			table.insert(walks, { A = seg.A, B = seg.B, In = k.Road / 2, Out = k.Road / 2 + k.Walk })
		end
	end
	local BODY, WALK_TOP = 0.95, 1.0
	local frames, inside, turns, runs, naive = 0, 0, 0, 0, 0
	for _, r in walks do
		local len = (r.B - r.A).Magnitude
		if len > 20 then
			local dir = (r.B - r.A).Unit
			local fr = { A = Vector3.new(r.A.X, 0, r.A.Z), Dir = dir, Perp = Vector3.new(-dir.Z, 0, dir.X) }
			local obs, seen = {}, {}
			for u = -2, len + 2, 4 do
				for _, side in { -1, 1 } do
					for v = r.In, r.Out, 2 do
						local p = fr.A + dir * u + fr.Perp * (side * v)
						for _, it in grid[cellKey(math.floor(p.X / CELL), math.floor(p.Z / CELL))] or {} do
							if not seen[it] and it.Solid and it.Visible and it.Hi.Y > WALK_TOP + 0.7 and it.Lo.Y < WALK_TOP + 5.3 then
								seen[it] = true
								local u0, u1, v0, v1 = Sidewalk.project(fr, it.Part.CFrame, it.S)
								if u1 > -2 and u0 < len + 2 and ((v1 > r.In and v0 < r.Out) or (v1 > -r.Out and v0 < -r.In)) then
									table.insert(obs, { U0 = u0, U1 = u1, V0 = v0, V1 = v1, Name = it.Name })
								end
							end
						end
					end
				end
			end
			obs = Sidewalk.decode(Sidewalk.encode(obs)) -- (como viaja al cliente, redondeado)
			local walk = (r.In + r.Out) / 2
			for _, side in { -1, 1 } do
				for _, d in { 1, -1 } do
					runs += 1
					local u = if d > 0 then 20 else len - 20
					local keep, dodge = d * 0.9, 0
					local dt, speed = 1 / 30, 6
					local inner, outer = r.In + BODY + 0.15, r.Out - BODY - 0.15
					local lo, hi = if side > 0 then inner else -outer, if side > 0 then outer else -inner
					for _ = 1, 4000 do
						if (d > 0 and u > len - 20) or (d < 0 and u < 20) then
							break
						end
						local base = side * walk + keep
						local v, stuck = Sidewalk.lane(obs, u, d, math.max(4, speed * 0.9), base, lo, hi, BODY, base + dodge)
						if v == nil then
							turns += 1
							break
						end
						if not stuck then
							u += d * speed * dt
						end
						dodge += (v - base - dodge) * math.min(1, dt * 5)
						frames += 1
						for _, o in obs do
							if o.U0 > u + BODY then
								break
							end
							if o.U1 > u - BODY then
								if base + BODY * 0.8 > o.V0 and base - BODY * 0.8 < o.V1 then
									naive += 1 -- (sin esquivar: como iban antes, en línea recta)
								end
								if base + dodge + BODY * 0.8 > o.V0 and base + dodge - BODY * 0.8 < o.V1 then
									inside += 1
									break
								end
							end
						end
					end
				end
			end
		end
	end
	print(("  %d recorridos por las aceras (%d fotogramas); en línea recta habrían atravesado algo en %d"):format(runs, frames, naive))
	check(runs > 500 and inside <= frames * 0.0002,
		("los peatones esquivan lo que hay en la acera: dentro de algo en %d de %d fotogramas (%.3f %%)"):format(inside, frames, inside / math.max(1, frames) * 100))
	check(turns <= runs * 0.1, ("donde no cabe nadie, se dan la vuelta (%d de %d recorridos)"):format(turns, runs))
end

print("")
if failures == 0 then
	print("✅ Calles: todo correcto")
else
	print(("❌ Calles: %d fallos"):format(failures))
	process.exit(1)
end
