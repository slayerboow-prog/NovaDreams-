-- OuterLandsBuilder: construye LAS TIERRAS EXTERIORES al arrancar (las cuentas, en shared/Cosmos/OuterLands):
-- el terreno del continente alrededor del mar de Valmar con su mar alrededor, los cuatro puentes desde la isla,
-- un campamento seguro (con Taller) donde llega cada puente, la decoración de cada región y un límite invisible
-- más allá de la costa de fuera.
--
--   * En su hilo y trozo a trozo (128 × 128 studs, una espera entre trozos): no frena el arranque. Cuando acaba
--     pone el atributo TierrasReady en workspace (World/ValmarWilds espera a eso para sacar bestias allí).
--   * Solo escribe FUERA del mar de Valmar (shared/Sea/OceanBiomes: el mar y su fondo no cambian): los trozos
--     van alineados con su borde y nunca lo cruzan.
--   * Rápido: la altura y el material se calculan cada 16 studs y en medio se interpola; los trozos que son
--     solo mar se rellenan con dos bloques.

local CityPlan = require(game:GetService("ReplicatedStorage").Shared.CityPlan)
local OuterLands = require(game:GetService("ReplicatedStorage").Shared.Cosmos.OuterLands)
local VR = require(game:GetService("ReplicatedStorage").Shared.Cosmos.ValmarRegions)
local Builder = require(script.Parent.Builder)

local OuterLandsBuilder = {}

local VOXEL = 4
local CHUNK = 128
local NODE = 16
local V3 = Vector3.new
local rgb = Color3.fromRGB

OuterLandsBuilder.State = "None"
OuterLandsBuilder.Stats = { Chunks = 0, Voxels = 0, Seconds = 0, Parts = 0 }

local matCache: { [string]: Enum.Material } = {}
local function mat(name: string): Enum.Material
	local m = matCache[name]
	if not m then
		local ok, v = pcall(function()
			return (Enum.Material :: any)[name]
		end)
		m = if ok and v then v else Enum.Material.Ground
		matCache[name] = m
	end
	return m
end

---------------------------------------------------------------------
-- Terreno
---------------------------------------------------------------------
local function chunk(terrain: Terrain, x0: number, z0: number, sx: number, sz: number): number
	local Surface, Floor = OuterLands.Surface, OuterLands.Floor
	-- nudos cada NODE studs (con un borde de uno para la pendiente)
	local nx, nz = math.ceil(sx / NODE) + 1, math.ceil(sz / NODE) + 1
	local H = table.create((nx + 2) * (nz + 2), 0)
	local top, low = -math.huge, math.huge
	for j = 0, nz + 1 do
		for i = 0, nx + 1 do
			local h = OuterLands.height(x0 + (i - 1) * NODE, z0 + (j - 1) * NODE) or Floor
			H[j * (nx + 2) + i + 1] = h
			if i >= 1 and i <= nx and j >= 1 and j <= nz then
				top = math.max(top, h)
				low = math.min(low, h)
			end
		end
	end
	local function node(i: number, j: number): number
		return H[(j + 1) * (nx + 2) + (i + 1) + 1]
	end
	local yb = Floor - 10
	yb = math.floor(yb / VOXEL) * VOXEL
	-- solo mar: el fondo de arena y el agua, en dos bloques
	if top < Surface - 3 then
		local fh = math.floor((low - yb) / VOXEL) * VOXEL
		terrain:FillBlock(CFrame.new(x0 + sx / 2, yb + fh / 2, z0 + sz / 2), V3(sx, math.max(VOXEL, fh), sz), Enum.Material.Sand)
		local wb = yb + math.max(VOXEL, fh)
		terrain:FillBlock(CFrame.new(x0 + sx / 2, (wb + Surface) / 2, z0 + sz / 2), V3(sx, Surface - wb, sz), Enum.Material.Water)
		return 2
	end
	-- materiales en cada nudo (con su pendiente)
	local M = table.create(nx * nz)
	for j = 0, nz - 1 do
		for i = 0, nx - 1 do
			local h = node(i, j)
			local slope = math.sqrt((node(i + 1, j) - node(i - 1, j)) ^ 2 + (node(i, j + 1) - node(i, j - 1)) ^ 2) / (2 * NODE)
			M[j * nx + i + 1] = { mat(OuterLands.material(x0 + i * NODE, z0 + j * NODE, h, slope)), slope }
		end
	end
	local ytop = math.ceil((math.max(top, Surface) + VOXEL * 2) / VOXEL) * VOXEL
	local layers = (ytop - yb) // VOXEL
	local cx, cz = sx // VOXEL, sz // VOXEL
	local region = Region3.new(V3(x0, yb, z0), V3(x0 + sx, ytop, z0 + sz))
	local materials = table.create(cx)
	local occupancy = table.create(cx)
	local Air, Water, Rock, Ground = Enum.Material.Air, Enum.Material.Water, Enum.Material.Rock, Enum.Material.Ground
	local per = NODE / VOXEL
	for i = 1, cx do
		local mx, ox = table.create(layers), table.create(layers)
		for y = 1, layers do
			mx[y] = table.create(cz, Air)
			ox[y] = table.create(cz, 0)
		end
		materials[i], occupancy[i] = mx, ox
		local fx = ((i - 0.5) / per)
		local i0 = math.min(math.floor(fx), nx - 2)
		local tx = fx - i0
		for k = 1, cz do
			local fz = ((k - 0.5) / per)
			local k0 = math.min(math.floor(fz), nz - 2)
			local tz = fz - k0
			local h = (node(i0, k0) * (1 - tx) + node(i0 + 1, k0) * tx) * (1 - tz) + (node(i0, k0 + 1) * (1 - tx) + node(i0 + 1, k0 + 1) * tx) * tz
			local near = M[math.clamp(math.floor(fz + 0.5), 0, nz - 1) * nx + math.clamp(math.floor(fx + 0.5), 0, nx - 1) + 1]
			local skin, slope = near[1], near[2]
			local under = if slope > 0.8 then Rock else Ground
			-- (en las cuestas la piel es más gruesa: si no, asoman franjas de lo de dentro entre escalón y escalón)
			local skinDepth = VOXEL * (2.2 + math.min(slope, 3) * 8)
			for y = 1, layers do
				local bottom = yb + (y - 1) * VOXEL
				local fill = math.clamp((h - bottom) / VOXEL, 0, 1)
				if fill > 0 then
					ox[y][k] = fill
					mx[y][k] = if h - bottom < skinDepth then skin else under
				elseif bottom < Surface then
					ox[y][k] = math.clamp((Surface - bottom) / VOXEL, 0, 1)
					mx[y][k] = Water
				end
			end
		end
	end
	terrain:WriteVoxels(region, VOXEL, materials, occupancy)
	return cx * cz * layers
end

-- Las cuatro franjas del marco (fuera del mar de Valmar, alineadas con su borde)
function OuterLandsBuilder.strips(): { { number } }
	local F = VR.Frame
	local Wt = F.Width + OuterLands.Band
	return {
		{ F.MinX - Wt, F.MinZ - Wt, F.MaxX + Wt, F.MinZ }, -- norte (con sus esquinas)
		{ F.MinX - Wt, F.MaxZ, F.MaxX + Wt, F.MaxZ + Wt }, -- sur (con sus esquinas)
		{ F.MinX - Wt, F.MinZ, F.MinX, F.MaxZ }, -- oeste
		{ F.MaxX, F.MinZ, F.MaxX + Wt, F.MaxZ }, -- este
	}
end

function OuterLandsBuilder.terrain(yieldEach: boolean?): (number, number)
	local terrain = workspace.Terrain
	local voxels, chunks = 0, 0
	local slice = os.clock()
	for _, s in OuterLandsBuilder.strips() do
		local z = s[2]
		while z < s[4] do
			local sz = math.min(CHUNK, s[4] - z)
			local x = s[1]
			while x < s[3] do
				local sx = math.min(CHUNK, s[3] - x)
				local ok, n = pcall(chunk, terrain, x, z, sx, sz)
				if ok then
					voxels += n
				else
					warn("[TierrasExteriores] trozo", x, z, n)
				end
				chunks += 1
				-- (suelta el hilo cada ~12 ms de trabajo: ni traba el servidor ni tarda un fotograma por trozo)
				if yieldEach ~= false and os.clock() - slice > 0.012 then
					task.wait()
					slice = os.clock()
				end
				x += sx
			end
			z += sz
		end
	end
	return voxels, chunks
end

---------------------------------------------------------------------
-- Puentes
---------------------------------------------------------------------
local function groundY(x: number, z: number): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {}
	local hit = workspace:Raycast(V3(x, 700, z), V3(0, -900, 0), params)
	return if hit then hit.Position.Y else 4
end

-- Una losa de A a B (tablero, con barandillas)
local function slab(parent: Instance, a: Vector3, b: Vector3, width: number)
	local len = (b - a).Magnitude
	if len < 0.5 then
		return
	end
	local cf = CFrame.lookAt((a + b) / 2, b)
	Builder.part({ Name = "Tablero", Size = V3(width, 2, len + 1), CFrame = cf * CFrame.new(0, -1, 0), Color = rgb(150, 146, 140), Material = Enum.Material.Concrete, Parent = parent })
	Builder.part({ Name = "Asfalto", Size = V3(width - 8, 0.2, len + 1), CFrame = cf * CFrame.new(0, 0.1, 0), Color = rgb(52, 52, 56), Material = Enum.Material.Asphalt, CanQuery = false, Parent = parent })
	for _, side in { -1, 1 } do
		Builder.part({ Name = "Barandilla", Size = V3(1.2, 3.6, len + 1), CFrame = cf * CFrame.new(side * (width / 2 - 0.6), 1.8, 0), Color = rgb(190, 186, 178), Material = Enum.Material.Concrete, Parent = parent })
	end
end

function OuterLandsBuilder.bridges(parent: Instance): number
	local n = 0
	local DeckY = OuterLands.DeckY
	for _, b in OuterLands.Bridges do
		local m = Builder.model("Puente" .. b.Id, parent)
		local dx, dz = b.Dir[1], b.Dir[2]
		local dir = V3(dx, 0, dz)
		-- el inicio: la costa de la isla en esa línea (y un poco tierra adentro)
		local ox = if b.X then b.X else 0
		local oz = if b.Z then b.Z else 0
		local coast = 0
		for s = 0, 7000, 20 do
			if CityPlan.inside(CityPlan.Coast, ox + dx * s, oz + dz * s) then
				coast = s
			end
		end
		local s0 = coast - 90
		local p0 = V3(ox + dx * s0, 0, oz + dz * s0)
		local y0 = groundY(p0.X, p0.Z) + 0.2
		local rampLen = math.max(140, math.abs(DeckY - y0) * 9)
		local sEdge = math.abs((b.EdgeX - ox) * dx + (b.EdgeZ - oz) * dz)
		local function at(s: number, y: number): Vector3
			return V3(ox + dx * s, y, oz + dz * s)
		end
		-- subida desde la isla, tablero sobre el mar y bajada al campamento
		slab(m, at(s0, y0), at(s0 + rampLen, DeckY), 40)
		local s = s0 + rampLen
		local sEnd = sEdge + 20
		while s < sEnd - 0.5 do
			local s2 = math.min(sEnd, s + 200)
			slab(m, at(s, DeckY), at(s2, DeckY), 40)
			s = s2
		end
		slab(m, at(sEnd, DeckY), at(sEnd + 230, OuterLands.CampY + 0.3), 40)
		-- pilares y farolas
		local k = 0
		for sp = s0 + rampLen + 60, sEnd - 30, 170 do
			local c = at(sp, 0)
			Builder.part({ Name = "Pilar", Size = V3(10, DeckY + 92, 8), CFrame = CFrame.lookAt(V3(c.X, (DeckY - 2 - 92) / 2, c.Z), V3(c.X, (DeckY - 2 - 92) / 2, c.Z) + dir), Color = rgb(128, 124, 118), Material = Enum.Material.Concrete, Parent = m })
			k += 1
			for _, side in { -1, 1 } do
				local off = V3(dz, 0, -dx) * side * 21
				local base = at(sp, DeckY) + off
				Builder.part({ Name = "Farola", Size = V3(0.7, 12, 0.7), CFrame = CFrame.new(base + V3(0, 6, 0)), Color = rgb(60, 62, 66), Material = Enum.Material.Metal, CastShadow = false, Parent = m })
				local lampHead = Builder.part({ Name = "Luz", Size = V3(2, 0.8, 2), CFrame = CFrame.new(base + V3(0, 12.4, 0)), Color = rgb(255, 226, 160), Material = Enum.Material.Neon, CastShadow = false, Parent = m })
				if k % 3 == 0 then
					local light = Instance.new("PointLight")
					light.Range = 40
					light.Brightness = 1.2
					light.Color = rgb(255, 220, 160)
					light.Shadows = false
					light.Parent = lampHead
				end
			end
		end
		m:SetAttribute("Region", b.Region)
		n += #m:GetChildren()
	end
	return n
end

---------------------------------------------------------------------
-- Campamentos
---------------------------------------------------------------------
function OuterLandsBuilder.camps(parent: Instance): number
	local okKit, BeastKit = pcall(function()
		return require(script.Parent.Kit.BeastKit)
	end)
	local n = 0
	for _, b in OuterLands.Bridges do
		local reg = VR.ById[b.Region]
		local m = Builder.model("Campamento" .. b.Id, parent)
		m:SetAttribute("Region", b.Region)
		local y = OuterLands.CampY
		local c = V3(b.CampX, y, b.CampZ)
		-- hoguera
		Builder.part({ Name = "Hoguera", Shape = Enum.PartType.Cylinder, Size = V3(1.2, 7, 7), CFrame = CFrame.new(c + V3(0, 0.6, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color = rgb(70, 66, 62), Material = Enum.Material.Slate, Parent = m })
		local fire = Builder.part({ Name = "Brasas", Size = V3(3, 2, 3), CFrame = CFrame.new(c + V3(0, 2, 0)), Color = rgb(255, 140, 40), Material = Enum.Material.Neon, CanCollide = false, CastShadow = false, Parent = m })
		local light = Instance.new("PointLight")
		light.Range = 45
		light.Brightness = 2
		light.Color = rgb(255, 170, 90)
		light.Parent = fire
		local fx = Instance.new("Fire")
		fx.Size = 6
		fx.Heat = 8
		fx.Parent = fire
		-- tiendas alrededor
		for t = 0, 3 do
			local a = t * math.pi / 2 + 0.4
			local tc = c + V3(math.cos(a) * 40, 0, math.sin(a) * 40)
			local cf = CFrame.lookAt(tc, c) * CFrame.new(0, 7, 0)
			local cloth = reg.Color:Lerp(rgb(200, 190, 170), 0.5)
			-- (tienda de dos aguas: dos cuñas espalda con espalda)
			Builder.part({ Name = "Tienda", ClassName = "WedgePart", Size = V3(18, 14, 10), CFrame = cf * CFrame.new(0, 0, -5), Color = cloth, Material = Enum.Material.Fabric, Parent = m })
			Builder.part({ Name = "Tienda", ClassName = "WedgePart", Size = V3(18, 14, 10), CFrame = cf * CFrame.new(0, 0, 5) * CFrame.Angles(0, math.pi, 0), Color = cloth, Material = Enum.Material.Fabric, Parent = m })
		end
		-- el mástil con la bandera de la región (se ve de lejos)
		Builder.part({ Name = "Mastil", Size = V3(1, 34, 1), CFrame = CFrame.new(c + V3(0, 17, 26)), Color = rgb(90, 70, 50), Material = Enum.Material.Wood, Parent = m })
		Builder.part({ Name = "Bandera", Size = V3(0.3, 7, 12), CFrame = CFrame.new(c + V3(0, 30, 32.5)), Color = reg.Color, Material = Enum.Material.Fabric, CanCollide = false, Parent = m })
		-- empalizada baja alrededor (con hueco hacia el puente)
		for t = 0, 23 do
			local a = t / 24 * math.pi * 2
			local p = c + V3(math.cos(a) * 70, 0, math.sin(a) * 70)
			local toBridge = (V3(b.EdgeX, y, b.EdgeZ) - c).Unit
			if (p - c).Unit:Dot(toBridge) < 0.9 then
				Builder.part({ Name = "Estaca", Size = V3(2, 7, 2), CFrame = CFrame.new(p + V3(0, 3, 0)), Color = rgb(100, 76, 52), Material = Enum.Material.Wood, Parent = m })
			end
		end
		-- el Taller (fabricar) y los carteles
		if okKit then
			pcall((BeastKit :: any).bench, m, CFrame.new(c + V3(0, 0, -20)) * CFrame.Angles(0, math.pi, 0), nil)
			pcall((BeastKit :: any).zoneSign, m, CFrame.new(c + V3(16, 0, 16)), ("⛺ Campamento · %s · zona segura"):format(reg.Name), 1)
			pcall((BeastKit :: any).zoneSign, m, CFrame.new(c + V3(-16, 0, 16)), ("%s %s · Nv. %d-%d"):format(reg.Icon, reg.Name, reg.MinLevel, reg.MaxLevel), 2)
		end
		n += #m:GetDescendants()
	end
	return n
end

---------------------------------------------------------------------
-- Decoración de cada región
---------------------------------------------------------------------
local RUIN_LOOK = { DesiertoDorado = "Arenisca", RuinasAntiguas = "Roca", TierrasOscuras = "Chatarra" }

local function decorOne(parent: Instance, d: { [string]: any }, BeastKit: any?)
	local s = d.Size
	local base = CFrame.new(d.X, d.Y - 0.6, d.Z) * CFrame.Angles(0, d.Turn, 0)
	local P = function(props: { [string]: any })
		props.Parent = parent
		return Builder.part(props)
	end
	local k = d.Kind
	if k == "Arbol" or k == "ArbolSolo" or k == "Pino" then
		local h = (if k == "Arbol" then 30 elseif k == "Pino" then 24 else 20) * s
		P({ Name = "Tronco", Shape = Enum.PartType.Cylinder, Size = V3(h, 2.6 * s, 2.6 * s), CFrame = base * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = rgb(90, 64, 44), Material = Enum.Material.Wood })
		if k == "Pino" then
			for i = 0, 2 do
				local w = (14 - i * 4) * s
				P({ Name = "Copa", Size = V3(w, 6 * s, w), CFrame = base * CFrame.new(0, h * 0.45 + i * 6 * s, 0) * CFrame.Angles(0, math.rad(45 * i), 0), Color = rgb(36, 74, 56), Material = Enum.Material.Grass, CastShadow = i == 0 })
				P({ Name = "Nieve", Size = V3(w * 0.7, 1, w * 0.7), CFrame = base * CFrame.new(0, h * 0.45 + i * 6 * s + 3 * s, 0) * CFrame.Angles(0, math.rad(45 * i), 0), Color = rgb(240, 245, 250), Material = Enum.Material.Snow, CastShadow = false })
			end
		else
			local green = if k == "Arbol" then rgb(54, 120, 66) else rgb(96, 140, 60)
			local w = (if k == "Arbol" then 20 else 24) * s
			P({ Name = "Copa", Shape = Enum.PartType.Ball, Size = V3(w, w * 0.8, w), CFrame = base * CFrame.new(0, h, 0), Color = green, Material = Enum.Material.Grass })
			P({ Name = "Copa", Shape = Enum.PartType.Ball, Size = V3(w * 0.7, w * 0.6, w * 0.7), CFrame = base * CFrame.new(w * 0.3, h - w * 0.2, w * 0.15), Color = green:Lerp(rgb(140, 255, 170), 0.12), Material = Enum.Material.Grass, CastShadow = false })
		end
	elseif k == "ArbolMuerto" or k == "ArbolNegro" then
		local h = 22 * s
		local col = if k == "ArbolNegro" then rgb(26, 22, 30) else rgb(78, 72, 60)
		P({ Name = "Tronco", Size = V3(2.2 * s, h, 2.2 * s), CFrame = base * CFrame.new(0, h / 2, 0) * CFrame.Angles(0.06, 0, 0.05), Color = col, Material = Enum.Material.Wood })
		for i = 0, 2 do
			local a = i * 2.1
			P({ Name = "Rama", Size = V3(1.1 * s, 9 * s, 1.1 * s), CFrame = base * CFrame.new(0, h * (0.55 + i * 0.13), 0) * CFrame.Angles(0, a, 0) * CFrame.Angles(0.9, 0, 0) * CFrame.new(0, 4 * s, 0), Color = col, Material = Enum.Material.Wood, CastShadow = false })
		end
		if k == "ArbolNegro" then
			P({ Name = "Brillo", Size = V3(1.2, 1.2, 1.2), CFrame = base * CFrame.new(0, h + 0.5, 0), Color = rgb(180, 90, 255), Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
		end
	elseif k == "Cactus" then
		local h = 14 * s
		local green = rgb(70, 120, 60)
		P({ Name = "Cactus", Shape = Enum.PartType.Cylinder, Size = V3(h, 2.4 * s, 2.4 * s), CFrame = base * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = green, Material = Enum.Material.Grass })
		for _, side in { -1, 1 } do
			P({ Name = "Brazo", Size = V3(1.6 * s, 5 * s, 1.6 * s), CFrame = base * CFrame.new(side * 2.4 * s, h * 0.55 + side * s, 0), Color = green, Material = Enum.Material.Grass, CastShadow = false })
		end
	elseif k == "Pilar" then
		local h = (18 + (d.Seed % 22)) * s
		local col = if d.Region == "DesiertoDorado" then rgb(214, 180, 120) else rgb(196, 190, 176)
		P({ Name = "Pilar", Size = V3(5 * s, h, 5 * s), CFrame = base * CFrame.new(0, h / 2 - 1, 0) * CFrame.Angles(0.05 * ((d.Seed % 5) - 2), 0, 0.04), Color = col, Material = if d.Region == "DesiertoDorado" then Enum.Material.Sandstone else Enum.Material.Limestone })
		P({ Name = "Capitel", Size = V3(7 * s, 1.6 * s, 7 * s), CFrame = base * CFrame.new(0, h - 0.4, 0), Color = col, Material = Enum.Material.Limestone, CastShadow = false })
	elseif k == "Roca" then
		local w = (8 + (d.Seed % 12)) * s
		local col = if d.Region == "TierrasVolcanicas" then rgb(46, 42, 40) elseif d.Region == "RuinasAntiguas" then rgb(150, 144, 130) else rgb(110, 108, 104)
		P({ Name = "Roca", Size = V3(w, w * 0.6, w * 0.8), CFrame = base * CFrame.new(0, w * 0.2, 0) * CFrame.Angles(0.2, 0, 0.15), Color = col, Material = Enum.Material.Rock })
	elseif k == "Hielo" or k == "Pua" then
		local h = (20 + (d.Seed % 26)) * s
		local ice = k == "Hielo"
		P({ Name = if ice then "Hielo" else "Pua", ClassName = "WedgePart", Size = V3(4 * s, h, 6 * s), CFrame = base * CFrame.new(0, h / 2 - 2, 0) * CFrame.Angles(0.12, 0, 0.1),
			Color = if ice then rgb(170, 220, 250) elseif d.Region == "TierrasOscuras" then rgb(30, 26, 38) else rgb(44, 38, 36),
			Material = if ice then Enum.Material.Ice else Enum.Material.Basalt, Transparency = if ice then 0.15 else 0 })
	elseif k == "Lava" then
		local w = (26 + (d.Seed % 26)) * s
		local pool = P({ Name = "Lava", Shape = Enum.PartType.Cylinder, Size = V3(0.8, w, w), CFrame = CFrame.new(d.X, d.Y + 0.1, d.Z) * CFrame.Angles(0, 0, math.pi / 2), Color = rgb(255, 110, 30), Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
		pool:SetAttribute("Lava", true)
		if d.Seed % 3 == 0 then
			local l = Instance.new("PointLight")
			l.Range = 30
			l.Brightness = 1.5
			l.Color = rgb(255, 120, 40)
			l.Shadows = false
			l.Parent = pool
		end
	elseif (k == "Templo" or k == "Ruina") and BeastKit then
		pcall(BeastKit.ruin, parent, base, RUIN_LOOK[d.Region] or "Roca", d.Seed)
		if k == "Templo" then
			pcall(BeastKit.ruin, parent, base * CFrame.new(18, 0, 6), "Arenisca", d.Seed + 7)
		end
	end
end

function OuterLandsBuilder.decor(parent: Instance, yieldEach: boolean?): number
	local okKit, BeastKit = pcall(function()
		return require(script.Parent.Kit.BeastKit)
	end)
	local groups: { [string]: Instance } = {}
	local n = 0
	for i, d in OuterLands.decor() do
		local g = groups[d.Region]
		if not g then
			g = Instance.new("Folder")
			g.Name = d.Region
			g.Parent = parent
			groups[d.Region] = g
		end
		local ok, err = pcall(decorOne, g, d, if okKit then BeastKit else nil)
		if not ok then
			warn("[TierrasExteriores] decoración", d.Kind, err)
		end
		n += 1
		if yieldEach ~= false and i % 40 == 0 then
			task.wait()
		end
	end
	return n
end

---------------------------------------------------------------------
-- El límite (no se puede seguir más allá del mar de fuera)
---------------------------------------------------------------------
function OuterLandsBuilder.limit(parent: Instance)
	local F = VR.Frame
	local Wt = F.Width + OuterLands.Band - 20
	local x0, x1, z0, z1 = F.MinX - Wt, F.MaxX + Wt, F.MinZ - Wt, F.MaxZ + Wt
	local function wall(a: Vector3, b: Vector3)
		local len = (b - a).Magnitude
		local s = 0
		while s < len do
			local s2 = math.min(len, s + 2000)
			local p, q = a:Lerp(b, s / len), a:Lerp(b, s2 / len)
			Builder.part({ Name = "Limite", Size = V3(4, 1400, (q - p).Magnitude), CFrame = CFrame.lookAt((p + q) / 2, q), Transparency = 1, CanQuery = false, CastShadow = false, Parent = parent })
			s = s2
		end
	end
	wall(V3(x0, 600, z0), V3(x1, 600, z0))
	wall(V3(x1, 600, z0), V3(x1, 600, z1))
	wall(V3(x1, 600, z1), V3(x0, 600, z1))
	wall(V3(x0, 600, z1), V3(x0, 600, z0))
end

---------------------------------------------------------------------
function OuterLandsBuilder.build(): Instance?
	if OuterLandsBuilder.State ~= "None" then
		return workspace:FindFirstChild("TierrasExteriores")
	end
	OuterLandsBuilder.State = "Building"
	local started = os.clock()
	local root = workspace:FindFirstChild("TierrasExteriores")
	if not root then
		root = Instance.new("Folder")
		root.Name = "TierrasExteriores"
		root.Parent = workspace
	end
	local parts = 0
	local okB, nb = pcall(OuterLandsBuilder.bridges, root)
	if okB then
		parts += nb
	else
		warn("[TierrasExteriores] puentes", nb)
	end
	local voxels, chunks = OuterLandsBuilder.terrain(true)
	local okC, nc = pcall(OuterLandsBuilder.camps, root)
	if okC then
		parts += nc
	else
		warn("[TierrasExteriores] campamentos", nc)
	end
	local decorFolder = Instance.new("Folder")
	decorFolder.Name = "Decoracion"
	decorFolder.Parent = root
	local okD, nd = pcall(OuterLandsBuilder.decor, decorFolder, true)
	if not okD then
		warn("[TierrasExteriores] decoración", nd)
	end
	pcall(OuterLandsBuilder.limit, root)
	OuterLandsBuilder.Stats = { Chunks = chunks, Voxels = voxels, Seconds = os.clock() - started, Parts = parts + #decorFolder:GetDescendants() }
	OuterLandsBuilder.State = "Ready"
	workspace:SetAttribute("TierrasReady", true)
	print(("[TierrasExteriores] %d trozos, %d vóxeles, %d piezas en %.1f s"):format(chunks, voxels, OuterLandsBuilder.Stats.Parts, OuterLandsBuilder.Stats.Seconds))
	return root
end

return OuterLandsBuilder
