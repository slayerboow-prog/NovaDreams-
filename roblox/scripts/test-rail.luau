-- Prueba del tren de Cercanías en el mapa construido (Kit/RailKit + Shared/Rail), con Lune.
--
-- Uso (desde la carpeta roblox/):
--   rojo build default.project.json -o /tmp/x.rbxl && lune run scripts/build-place.luau /tmp/x.rbxl
--   lune run scripts/test-rail.luau /tmp/x.rbxl
--
-- Comprueba que:
--   * la vía es continua: los dos carriles de punta a punta (también por los pasos a nivel y el puente),
--     con traviesas, y sobre el río hay puente
--   * cada calle que cruza tiene su paso a nivel (cuatro barreras y luces) y el asfalto sigue entero
--   * nada del resto de la ciudad (casas, farolas, árboles…) está encima de la vía, de los andenes,
--     de las rampas ni de los caminos
--   * a cada estación se llega andando desde una acera (suelo en cada paso y nada en medio) y tiene
--     andén a la altura del tren, botones de subir, sitio para bajar, máquina de billetes y panel
--   * el tren tiene sus tres coches (asientos, puertas a los dos lados) y espera en la primera estación

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Vector3, CFrame, Color3 = roblox.Vector3, roblox.CFrame, roblox.Color3

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
	print("Uso: lune run scripts/test-rail.luau <mapa construido .rbxl>")
	process.exit(1)
end

local CityPlan = requireModule(sharedProxy.CityPlan)
local Rail = requireModule(sharedProxy.Rail)
local World = node("src/server/World", nil)
local RailKit = requireModule(World.Kit.RailKit)

local failures = 0
local function check(ok: boolean, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

print("▶ Leyendo el mapa…")
local game = roblox.deserializePlace(fs.readFile(placePath))
local town = game:GetService("Workspace"):FindFirstChild("Town")
assert(town, "el mapa no tiene la ciudad construida (Workspace.Town)")
local root = town:FindFirstChild("Cercanias")
check(root ~= nil, "la ciudad tiene el tren de Cercanías (Town.Cercanias)")
if not root then
	process.exit(1)
end

local points, centers, length = Rail.path()

-- Rejilla de piezas (en horizontal) para buscar deprisa
local CELL = 16
local function key(gx: number, gz: number): number
	return (gx + 2000) * 4000 + (gz + 2000)
end
type Item = { Part: any, Lo: Vector3, Hi: Vector3, Rail: boolean }
local function index(list: { any }, isRail: boolean, grid: { [number]: { Item } }, filter: ((Vector3, Vector3) -> boolean)?)
	for _, p in list do
		if p:IsA("BasePart") and not p:HasTag("EditOnly") then
			local lo, hi = RailKit.bounds(p)
			if not filter or filter(lo, hi) then
				local item = { Part = p, Lo = lo, Hi = hi, Rail = isRail }
				for gx = math.floor(lo.X / CELL), math.floor(hi.X / CELL) do
					for gz = math.floor(lo.Z / CELL), math.floor(hi.Z / CELL) do
						local k = key(gx, gz)
						grid[k] = grid[k] or {}
						table.insert(grid[k], item)
					end
				end
			end
		end
	end
end
local railGrid: { [number]: { Item } } = {}
index(root:GetDescendants(), true, railGrid)
local function query(grid: { [number]: { Item } }, x: number, z: number): { Item }
	return grid[key(math.floor(x / CELL), math.floor(z / CELL))] or {}
end
-- ¿El punto está dentro de la pieza (en su caja girada)? pad = margen
-- (en una cuña solo cuenta lo que queda debajo de la rampa: alta atrás, +Z, y a ras delante, -Z)
local function inside(p: any, q: Vector3, pad: number): boolean
	local rel = p.CFrame:PointToObjectSpace(q)
	local h = p.Size / 2
	if not (math.abs(rel.X) <= h.X + pad and math.abs(rel.Y) <= h.Y + pad and math.abs(rel.Z) <= h.Z + pad) then
		return false
	end
	if p:IsA("WedgePart") then
		return rel.Y / p.Size.Y - rel.Z / p.Size.Z <= pad / math.min(p.Size.Y, p.Size.Z)
	end
	return true
end

---------------------------------------------------------------------
-- 1) Vía continua
---------------------------------------------------------------------
print("▶ Vía")
local gaps, water, bridge = 0, 0, 0
local sleepers = 0
for _, d in root:GetDescendants() do
	if d:IsA("BasePart") and d.Name == "Sleeper" then
		sleepers += 1
	end
end
local s = 0.5
while s < length - 0.5 do
	local p, t = Rail.sample(points, s)
	local n = Vector3.new(-t.Z, 0, t.X)
	for _, side in { -1, 1 } do
		local q = p + n * side * Rail.Gauge / 2
		local found = false
		for _, it in query(railGrid, q.X, q.Z) do
			if it.Part.Name == "Rail" and it.Hi.Y > 0.3 and it.Hi.Y < 1.3 and inside(it.Part, Vector3.new(q.X, (it.Lo.Y + it.Hi.Y) / 2, q.Z), 0.15) then
				found = true
				break
			end
		end
		if not found then
			gaps += 1
			if gaps <= 4 then
				print(("      sin carril en (%.1f, %.1f) · s = %.0f"):format(q.X, q.Z, s))
			end
		end
	end
	-- Sobre el río, puente
	if CityPlan.riverDistance(p.X, p.Z) < CityPlan.River.Width / 2 then
		water += 1
		for _, it in query(railGrid, p.X, p.Z) do
			if it.Part.Name == "Deck" and inside(it.Part, Vector3.new(p.X, (it.Lo.Y + it.Hi.Y) / 2, p.Z), 0.2) then
				bridge += 1
				break
			end
		end
	end
	s += 2
end
check(gaps == 0, ("los dos carriles van de punta a punta sin cortes (%d studs de vía)"):format(math.floor(length)))
check(sleepers >= length / 5 * 0.8, ("traviesas a lo largo de la vía (%d)"):format(sleepers))
check(water > 0 and bridge == water, ("sobre el río, un puente con tablero (%d de %d puntos)"):format(bridge, water))

---------------------------------------------------------------------
-- 2) Pasos a nivel
---------------------------------------------------------------------
print("▶ Pasos a nivel")
local crossings = RailKit.crossings()
local models = {}
for _, d in root:GetDescendants() do
	if d:IsA("Model") and d.Name == "PasoANivel" then
		table.insert(models, d)
	end
end
check(#crossings >= 3 and #models == #crossings, ("un paso a nivel por cada calle que cruza la vía (%d)"):format(#crossings))
local partsOk = true
for _, c in crossings do
	local model = nil
	for _, m in models do
		if math.abs((m:GetAttribute("S") or -1) - c.S) < 0.5 then
			model = m
		end
	end
	local posts, arms, lights = 0, 0, 0
	if model then
		for _, d in model:GetDescendants() do
			if d:IsA("Model") and d.Name == "PostePasoNivel" then
				posts += 1
			elseif d:IsA("Model") and d.Name == "Barrera" and typeof(d:GetAttribute("Hinge")) == "CFrame" then
				arms += 1
			elseif d:IsA("BasePart") and d.Name == "CrossingLight" then
				lights += 1
			end
		end
	end
	if not model or posts ~= 4 or arms ~= 4 or lights ~= 8 or typeof(model:GetAttribute("Center")) ~= "Vector3" then
		partsOk = false
		print(("      %s: %d postes, %d barreras, %d luces"):format(c.Name, posts, arms, lights))
	else
		print(("      %s (s = %.0f): 4 barreras y 8 luces"):format(c.Name, c.S))
	end
end
check(partsOk, "cada paso a nivel tiene cuatro postes con barrera, cruz y dos luces")

---------------------------------------------------------------------
-- 3) Nada encima de la vía ni de las estaciones
---------------------------------------------------------------------
print("▶ La vía y las estaciones, despejadas")
local boxes = RailKit.keepOut()
local bx0, bx1, bz0, bz1 = math.huge, -math.huge, math.huge, -math.huge
for _, b in boxes do
	local r = b.HU + b.HV
	bx0, bx1 = math.min(bx0, b.C.X - r), math.max(bx1, b.C.X + r)
	bz0, bz1 = math.min(bz0, b.C.Z - r), math.max(bz1, b.C.Z + r)
end
local cityGrid: { [number]: { Item } } = {}
local others = {}
for _, d in town:GetDescendants() do
	if d:IsA("BasePart") and not d:IsDescendantOf(root) then
		table.insert(others, d)
	end
end
index(others, false, cityGrid, function(lo, hi)
	return hi.X > bx0 and lo.X < bx1 and hi.Z > bz0 and lo.Z < bz1 and hi.Y > -2 and lo.Y < 16
end)
local overlaps = 0
local seen = {}
for _, b in boxes do
	local r = b.HU + b.HV
	for gx = math.floor((b.C.X - r) / CELL), math.floor((b.C.X + r) / CELL) do
		for gz = math.floor((b.C.Z - r) / CELL), math.floor((b.C.Z + r) / CELL) do
			for _, it in cityGrid[key(gx, gz)] or {} do
				if not seen[it] and it.Hi.Y > 1.3 and it.Lo.Y < 16 and RailKit.touches(it.Lo, it.Hi, b) then
					seen[it] = true
					overlaps += 1
					if overlaps <= 8 then
						print(("      %s encima de la vía (%.0f, %.0f)"):format(it.Part:GetFullName(), (it.Lo.X + it.Hi.X) / 2, (it.Lo.Z + it.Hi.Z) / 2))
					end
				end
			end
		end
	end
end
check(overlaps == 0, "ningún edificio, farola ni árbol encima de la vía, los andenes, las rampas o los caminos")
-- La vía no pasa por las manzanas ni por las montañas
local blocks = requireModule(World.Region).blockRects()
local inBlock, onMountain = 0, 0
s = 0
while s < length do
	local p = Rail.sample(points, s)
	for _, r in blocks do
		if p.X > r.X0 - 6 and p.X < r.X1 + 6 and p.Z > r.Z0 - 6 and p.Z < r.Z1 + 6 then
			inBlock += 1
		end
	end
	for _, m in CityPlan.Mountains do
		local ground = math.sqrt(math.max(0, m.R * m.R - (m.R - m.H) ^ 2))
		if math.sqrt((p.X - m.X) ^ 2 + (p.Z - m.Z) ^ 2) < ground + 8 then
			onMountain += 1
		end
	end
	s += 10
end
check(inBlock == 0 and onMountain == 0, ("la vía va por el campo: sin cruzar manzanas (%d) ni montañas (%d)"):format(inBlock, onMountain))

---------------------------------------------------------------------
-- 4) Estaciones: se llega andando desde la acera
---------------------------------------------------------------------
print("▶ Estaciones")
local function tagged(tag: string, attrs: { [string]: any }): number
	local n = 0
	for _, d in root:GetDescendants() do
		if d:HasTag(tag) then
			local ok = true
			for k, v in attrs do
				if d:GetAttribute(k) ~= v then
					ok = false
				end
			end
			if ok then
				n += 1
			end
		end
	end
	return n
end
-- Todo lo sólido cerca de los caminos (de la ciudad y de la estación)
local solidGrid: { [number]: { Item } } = {}
local solids = {}
for _, d in town:GetDescendants() do
	if d:IsA("BasePart") and d.CanCollide then
		table.insert(solids, d)
	end
end
local routes = {}
for id in Rail.Stations do
	routes[id] = Rail.access(id)
end
index(solids, false, solidGrid, function(lo, hi)
	for _, a in routes do
		for _, q in a.Route do
			if hi.X > q.X - 80 and lo.X < q.X + 80 and hi.Z > q.Z - 80 and lo.Z < q.Z + 80 then
				return true
			end
		end
	end
	return false
end)
for _, id in Rail.Line.Stations do
	local A = routes[id]
	local model = root:FindFirstChild("Estacion_" .. id)
	local entranceModel = model and model:FindFirstChild("EstacionCercanias")
	local platform = model and model:FindFirstChild("Platform")
	local deckOk = platform ~= nil and math.abs(platform.CFrame.Position.Y + platform.Size.Y / 2 - Rail.Deck) < 0.05
	check(model ~= nil and deckOk, ("%s: andén a la altura del suelo del tren"):format(Rail.Stations[id].Name))
	check(tagged("RailBoard", { Station = id }) == Rail.Cars and tagged("RailAlight", { Station = id }) == 1 and tagged("RailTicketMachine", { Station = id }) == 1 and tagged("RailDisplay", { Station = id }) == 1,
		("%s: botones de subir, sitio para bajar, máquina de billetes y panel de salidas"):format(Rail.Stations[id].Name))
	-- La entrada (modelo "EstacionCercanias": sale en el mapa y en el GPS) está en la calle, junto a la acera
	local totem = entranceModel and entranceModel:FindFirstChild("Totem")
	local street = Rail.entrance(id)
	check(totem ~= nil and (Vector3.new(totem.CFrame.Position.X, 0, totem.CFrame.Position.Z) - Vector3.new(street.X, 0, street.Z)).Magnitude < 12,
		("%s: la entrada con su tótem está junto a la acera (para el mapa y el GPS)"):format(Rail.Stations[id].Name))
	local gapsHere, blockedHere = 0, 0
	for k = 2, #A.Route do
		local a, b = A.Route[k - 1], A.Route[k]
		local n = math.max(1, math.ceil((b - a).Magnitude / 0.8))
		for i = 0, n do
			local q = a:Lerp(b, i / n)
			local floor, blocked = false, nil
			for _, it in query(solidGrid, q.X, q.Z) do
				if not floor and inside(it.Part, q - Vector3.new(0, 0.25, 0), 0.02) then
					floor = true
				end
				if not blocked and inside(it.Part, q + Vector3.new(0, 2.6, 0), 0) and inside(it.Part, q + Vector3.new(0, 1.2, 0), 0) then
					blocked = it.Part
				end
			end
			if not floor then
				gapsHere += 1
				if gapsHere <= 3 then
					print(("      sin suelo en (%.1f, %.1f, %.1f)"):format(q.X, q.Y, q.Z))
				end
			end
			if blocked then
				blockedHere += 1
				if blockedHere <= 3 then
					print(("      %s estorba en (%.1f, %.1f, %.1f)"):format(blocked:GetFullName(), q.X, q.Y, q.Z))
				end
			end
		end
	end
	-- El primer paso es una acera de verdad (de una calle de la ciudad)
	local start = A.Route[1]
	local onWalk = false
	for _, it in query(solidGrid, start.X, start.Z) do
		local name = it.Part.Name
		if (name == "Sidewalk" or name == "Pavement" or name == "Walk" or name == "RingSidewalk") and inside(it.Part, start - Vector3.new(0, 0.25, 0), 0.05) then
			onWalk = true
		end
	end
	check(onWalk and gapsHere == 0 and blockedHere == 0, ("%s: de la acera al andén andando, sin huecos ni nada en medio"):format(Rail.Stations[id].Name))
end

---------------------------------------------------------------------
-- 5) El tren
---------------------------------------------------------------------
print("▶ Tren")
local train = root:FindFirstChild("Cercanias_" .. Rail.Line.Id)
local carsOk = train ~= nil and train:HasTag("RailTrain") and train:GetAttribute("Line") == Rail.Line.Id
local seats, doorsL, doorsR = 0, 0, 0
if train then
	for k = 1, Rail.Cars do
		local car = train:FindFirstChild("Car" .. k)
		local carRoot = car and car:FindFirstChild("Root")
		if not car or not carRoot or car:GetAttribute("NeedsWeld") ~= true then
			carsOk = false
		else
			for _, d in car:GetDescendants() do
				if d:IsA("Seat") and d:HasTag("RailSeat") then
					seats += 1
				elseif d:IsA("BasePart") and d:HasTag("RailDoor") then
					if carRoot.CFrame:PointToObjectSpace(d.CFrame.Position).X > 0 then
						doorsR += 1
					else
						doorsL += 1
					end
				end
			end
		end
	end
	local mid = train:FindFirstChild("Car" .. math.ceil(Rail.Cars / 2))
	local midRoot = mid and mid:FindFirstChild("Root")
	local first = Rail.sample(points, centers[1])
	carsOk = carsOk and midRoot ~= nil and (midRoot.CFrame.Position - first).Magnitude < 2
end
check(carsOk, ("el tren tiene %d coches (se sueldan al arrancar) y espera en %s"):format(Rail.Cars, Rail.Stations[Rail.Line.Stations[1]].Name))
check(seats >= Rail.Cars * 8 and doorsL >= Rail.Cars * 2 and doorsR >= Rail.Cars * 2, ("asientos (%d) y puertas a los dos lados (%d y %d)"):format(seats, doorsL, doorsR))

do
	local svc = fs.readFile("src/server/Services/RailService.luau")
	check(svc:find("Vector3.new(q.X, 3.5, q.Z)", 1, true) == nil and svc:find("groundBelow(to,", 1, true) ~= nil and svc:find("ground + 3", 1, true) ~= nil,
		"quien se aparta de la vía queda de pie en el suelo que haya (encima del andén), no a una altura fija metido dentro")
	-- (la prueba: al apartarse se cae dentro del andén, que está más alto que la altura fija de antes)
	check(Rail.Clearance + 2 > Rail.PlatformGap and Rail.Deck > 3.5 - 3, "apartarse junto a una estación cae encima del andén (por eso hay que buscar el suelo)")
	check(svc:find("RideState.downed(player)", 1, true) ~= nil, "K.O., caído o muerto no se sube al tren")
end

print("")
if failures == 0 then
	print("✅ Cercanías: todo correcto")
else
	print(("❌ Cercanías: %d fallos"):format(failures))
	process.exit(1)
end
