-- Settlement: EL ASENTAMIENTO (17-11-2026, el dueño: «elimina edificios y pon casas rústicas, ambientadas en un
-- mundo futurista post apocalíptico, en el que los humanos hicieron un asentamiento para prosperar y el resto
-- está lleno de monstruos»). Se monta en TownBuilder.build, después de Kit/FarmDistricts.prune y antes del
-- relieve. Sin azar de verdad (semillas fijas): el mapa sale igual cada vez.
--
--   1. CASAS RÚSTICAS donde estaban los rascacielos y las manzanas de pisos del centro (Distritos/District_Centro:
--      Manzana_Downtown y Manzana_Towers). Cada manzana (210 × 210) pasa a ser una manzana del asentamiento: patio
--      de tierra, casas de madera y chapa con placa solar, depósito de agua, antena y farolillo; en medio, un pozo
--      con huerto. Lo de la historia (Academia, hospital, comisaría, tiendas, oficinas…) no se toca.
--   2. LA EMPALIZADA del asentamiento: muro de chatarra y troncos por el borde del Distrito Central (su MapPoly),
--      con torres de vigía y PUERTAS donde lo cruzan las carreteras principales. Donde hay algo construido se
--      deja hueco (nunca atraviesa un edificio); los árboles que pisa se quitan.
--   3. RUINAS en los distritos de caza: casas como las del asentamiento pero abandonadas (sin tejado o a medio
--      caer, tablas rotas, escombros), para que el terreno hostil no esté vacío.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Builder = require(script.Parent.Parent.Builder)
local CityPlan = require(ReplicatedStorage.Shared.CityPlan)

local Settlement = {}

Settlement.Replace = { Manzana_Downtown = true, Manzana_Towers = true }
Settlement.RuinsPerFarm = 28
Settlement.RuinGap = 150
Settlement.WallOffset = 14 -- la empalizada, tantos studs por fuera del borde del Distrito Central
Settlement.GateWidth = 56

local rgb = Color3.fromRGB
local V3 = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local M = Enum.Material

local WOODS = { rgb(122, 88, 60), rgb(104, 74, 50), rgb(138, 104, 72), rgb(92, 70, 52) }
local METALS = { rgb(120, 112, 104), rgb(146, 96, 64), rgb(96, 104, 110), rgb(160, 118, 80) }
local ROOFS = { rgb(150, 82, 52), rgb(110, 104, 98), rgb(126, 70, 48), rgb(90, 96, 92) }

local function rng(seed: number): () -> number
	local s = math.max(1, math.floor(seed) % 2147483646)
	return function(): number
		s = (s * 16807) % 2147483647
		return s / 2147483647
	end
end

local function pick<T>(list: { T }, r: () -> number): T
	return list[1 + math.floor(r() * #list) % #list]
end

---------------------------------------------------------------------
-- Una casa rústica (cf: el centro del suelo, mirando la puerta hacia −Z local). ruined: abandonada
---------------------------------------------------------------------
function Settlement.house(parent: Instance, cf: CFrame, w: number, d: number, seed: number, ruined: boolean?, tall: boolean?): Model
	local r = rng(seed)
	local m = Builder.model(if ruined then "Ruina" else "CasaRustica", parent)
	local wood = pick(WOODS, r)
	local metal = pick(METALS, r)
	local roof = pick(ROOFS, r)
	local h = (if tall then 17 else 9) + math.floor(r() * 3)
	local P = function(props: { [string]: any }): BasePart
		props.Parent = m
		return Builder.part(props)
	end
	local D = function(props: { [string]: any }): BasePart
		props.Parent = m
		return Builder.decor(props)
	end
	-- losa de hormigón viejo
	P({ Name = "Losa", Size = V3(w + 2, 1, d + 2), CFrame = cf * CF(0, 0.5, 0), Color = rgb(118, 114, 106), Material = M.Concrete })
	local wallH = if ruined then h * (0.45 + r() * 0.4) else h
	local t = 0.8
	-- paredes: abajo madera, arriba chapa (la de delante con hueco de puerta)
	local function wall(name: string, size: Vector3, at: CFrame, mat: Enum.Material, col: Color3)
		P({ Name = name, Size = size, CFrame = cf * at, Color = col, Material = mat })
	end
	local lowH = wallH * 0.55
	local highH = wallH - lowH
	for _, side in { -1, 1 } do
		-- laterales
		wall("Pared", V3(t, lowH, d), CF(side * (w / 2 - t / 2), 1 + lowH / 2, 0), M.WoodPlanks, wood)
		if not ruined or r() > 0.5 then
			wall("Chapa", V3(t, highH, d), CF(side * (w / 2 - t / 2), 1 + lowH + highH / 2, 0), M.CorrodedMetal, metal)
		end
	end
	-- trasera
	wall("Pared", V3(w, lowH, t), CF(0, 1 + lowH / 2, d / 2 - t / 2), M.WoodPlanks, wood)
	wall("Chapa", V3(w, highH, t), CF(0, 1 + lowH + highH / 2, d / 2 - t / 2), M.CorrodedMetal, metal)
	-- delantera: dos trozos a los lados de la puerta y el dintel
	local door = 5
	local sideW = (w - door) / 2
	for _, side in { -1, 1 } do
		wall("Pared", V3(sideW, wallH, t), CF(side * (door / 2 + sideW / 2), 1 + wallH / 2, -d / 2 + t / 2), M.WoodPlanks, wood)
	end
	if wallH > 8 then
		wall("Dintel", V3(door, wallH - 8, t), CF(0, 1 + 8 + (wallH - 8) / 2, -d / 2 + t / 2), M.CorrodedMetal, metal)
	end
	if not ruined then
		-- puerta (entreabierta) y ventanas con marco; alguna, tapiada con tablas
		D({ Name = "Puerta", Size = V3(door - 0.4, 7.6, 0.4), CFrame = cf * CF(-door / 2 + 0.2, 1 + 3.8, -d / 2 - 0.2) * ANG(0, math.rad(-25), 0) * CF((door - 0.4) / 2, 0, 0), Color = rgb(70, 50, 36), Material = M.Wood })
		for _, side in { -1, 1 } do
			local wx = side * (door / 2 + sideW / 2)
			if r() > 0.3 then
				D({ Name = "Ventana", Size = V3(3.2, 2.6, 0.2), CFrame = cf * CF(wx, 1 + 5.2, -d / 2 - 0.05), Color = rgb(255, 214, 140), Material = M.Neon, Transparency = 0.35 })
				D({ Name = "Marco", Size = V3(3.8, 0.4, 0.3), CFrame = cf * CF(wx, 1 + 6.7, -d / 2 - 0.12), Color = metal, Material = M.Metal })
			else
				for k = 0, 2 do
					D({ Name = "Tabla", Size = V3(3.8, 0.6, 0.25), CFrame = cf * CF(wx, 1 + 4.4 + k * 0.9, -d / 2 - 0.12) * ANG(0, 0, math.rad((k - 1) * 7)), Color = wood, Material = M.WoodPlanks })
				end
			end
		end
		-- (de dos plantas: ventanas arriba y una cornisa entre planta y planta)
		if tall then
			for _, wx in { -w / 4, w / 4 } do
				D({ Name = "Ventana", Size = V3(3.2, 2.6, 0.2), CFrame = cf * CF(wx, 1 + 13, -d / 2 - 0.05), Color = rgb(255, 214, 140), Material = M.Neon, Transparency = 0.35 })
			end
			P({ Name = "Cornisa", Size = V3(w + 0.6, 0.6, d + 0.6), CFrame = cf * CF(0, 1 + 9.5, 0), Color = metal, Material = M.CorrodedMetal })
		end
		-- tejado a dos aguas de chapa
		local rise = 3.2
		local half = w / 2 + 1
		local slope = math.sqrt(half * half + rise * rise)
		local ang = math.atan2(rise, half)
		for _, side in { -1, 1 } do
			P({ Name = "Tejado", Size = V3(slope, 0.5, d + 2), CFrame = cf * CF(side * half / 2, 1 + h + rise / 2, 0) * ANG(0, 0, side * -ang), Color = roof, Material = M.CorrodedMetal })
		end
		-- frontones
		for _, z in { -d / 2 + t / 2, d / 2 - t / 2 } do
			-- (cada mitad del triángulo: lo alto hacia el centro de la casa, la pendiente hacia fuera)
			P({ Name = "Fronton", ClassName = "WedgePart", Size = V3(t, rise, half - 1), CFrame = cf * CF((half - 1) / 2, 1 + h + rise / 2, z) * ANG(0, math.rad(-90), 0), Color = wood, Material = M.WoodPlanks })
			P({ Name = "Fronton", ClassName = "WedgePart", Size = V3(t, rise, half - 1), CFrame = cf * CF(-(half - 1) / 2, 1 + h + rise / 2, z) * ANG(0, math.rad(90), 0), Color = wood, Material = M.WoodPlanks })
		end
		-- placa solar sobre una de las aguas, antena y depósito de agua
		local side = if r() > 0.5 then 1 else -1
		D({ Name = "PlacaSolar", Size = V3(slope * 0.6, 0.3, d * 0.55), CFrame = cf * CF(side * half / 2, 1 + h + rise / 2 + 0.45, 0) * ANG(0, 0, side * -ang), Color = rgb(36, 58, 104), Material = M.Glass, Reflectance = 0.25 })
		if r() > 0.35 then
			D({ Name = "Antena", Size = V3(0.3, 7, 0.3), CFrame = cf * CF(-side * w / 4, 1 + h + rise + 3.5, d / 4), Color = rgb(70, 70, 74), Material = M.Metal })
			D({ Name = "Luz", Size = V3(0.6, 0.6, 0.6), CFrame = cf * CF(-side * w / 4, 1 + h + rise + 7.2, d / 4), Color = rgb(255, 70, 50), Material = M.Neon })
		end
		local tank = P({ Name = "Deposito", Shape = Enum.PartType.Cylinder, Size = V3(5, 4, 4), CFrame = cf * CF(side * (w / 2 + 2.6), 1 + 2.5, d / 4) * ANG(0, 0, math.rad(90)), Color = rgb(70, 90, 84), Material = M.Metal })
		tank.Name = "Deposito"
		-- farolillo junto a la puerta (luz cálida)
		local lamp = D({ Name = "Farolillo", Size = V3(0.8, 1, 0.8), CFrame = cf * CF(door / 2 + 0.9, 1 + 7.4, -d / 2 - 0.6), Color = rgb(255, 196, 110), Material = M.Neon })
		if r() > 0.55 then
			local light = Instance.new("PointLight")
			light.Range = 16
			light.Brightness = 0.9
			light.Color = rgb(255, 190, 120)
			light.Shadows = false
			light.Parent = lamp
		end
		-- bidones
		for k = 1, 1 + math.floor(r() * 2) do
			D({ Name = "Bidon", Shape = Enum.PartType.Cylinder, Size = V3(3, 2, 2), CFrame = cf * CF(-w / 2 - 1.6, 1 + 1.5, -d / 2 + 2 + k * 2.4) * ANG(0, 0, math.rad(90)), Color = pick(METALS, r), Material = M.CorrodedMetal })
		end
	else
		-- abandonada: vigas caídas, tablas y escombros por el suelo; algún trozo de tejado
		for k = 1, 3 do
			D({ Name = "Escombro", Size = V3(2 + r() * 3, 1 + r() * 1.5, 2 + r() * 3), CFrame = cf * CF((r() - 0.5) * w * 0.8, 1.6, (r() - 0.5) * d * 0.8) * ANG(r() * 0.5, r() * 3, r() * 0.5), Color = rgb(96, 92, 86), Material = M.Concrete })
		end
		D({ Name = "Viga", Size = V3(0.8, 0.8, d * 0.9), CFrame = cf * CF((r() - 0.5) * w * 0.4, 2.2, 0) * ANG(math.rad(12), 0, math.rad(8)), Color = wood, Material = M.Wood })
		if r() > 0.5 then
			P({ Name = "Tejado", Size = V3(w * 0.6, 0.5, d * 0.5), CFrame = cf * CF(w * 0.18, 1 + wallH * 0.7, d * 0.2) * ANG(math.rad(-20), 0, math.rad(14)), Color = roof, Material = M.CorrodedMetal })
		end
	end
	return m
end

---------------------------------------------------------------------
-- 1. Las manzanas del asentamiento
---------------------------------------------------------------------
local function yard(parent: Instance, c: Vector3, seed: number)
	local r = rng(seed)
	local m = Builder.model("Patio", parent)
	-- pozo
	Builder.part({ Name = "Pozo", Shape = Enum.PartType.Cylinder, Size = V3(3, 7, 7), CFrame = CF(c + V3(0, 1.5, 0)) * ANG(0, 0, math.rad(90)), Color = rgb(120, 116, 108), Material = M.Cobblestone, Parent = m })
	for _, side in { -1, 1 } do
		Builder.part({ Name = "Poste", Size = V3(0.6, 6, 0.6), CFrame = CF(c + V3(side * 3, 4, 0)), Color = rgb(96, 70, 46), Material = M.Wood, Parent = m })
	end
	Builder.part({ Name = "Tejadillo", Size = V3(8, 0.4, 4), CFrame = CF(c + V3(0, 7.2, 0)), Color = rgb(140, 80, 50), Material = M.CorrodedMetal, Parent = m })
	-- huerto (surcos)
	for k = -2, 2 do
		Builder.decor({ Name = "Surco", Size = V3(16, 0.6, 1.6), CFrame = CF(c + V3(0, 0.3, 14 + k * 3)), Color = rgb(84, 62, 44), Material = M.Ground, Parent = m })
		Builder.decor({ Name = "Cultivo", Size = V3(14, 1.2, 0.8), CFrame = CF(c + V3(0, 1.1, 14 + k * 3)), Color = rgb(80, 130 + math.floor(r() * 40), 60), Material = M.Grass, Parent = m })
	end
	-- puesto de mercado
	local stall = c + V3(-18, 0, -10)
	Builder.part({ Name = "Mostrador", Size = V3(8, 3, 3), CFrame = CF(stall + V3(0, 1.5, 0)), Color = rgb(110, 80, 54), Material = M.WoodPlanks, Parent = m })
	Builder.part({ Name = "Toldo", Size = V3(10, 0.3, 6), CFrame = CF(stall + V3(0, 7, 1)) * ANG(math.rad(-10), 0, 0), Color = rgb(170, 60, 50), Material = M.Fabric, Parent = m })
	for _, sx in { -4.5, 4.5 } do
		Builder.part({ Name = "Poste", Size = V3(0.4, 7, 0.4), CFrame = CF(stall + V3(sx, 3.5, -1.5)), Color = rgb(80, 60, 44), Material = M.Wood, Parent = m })
	end
end

-- Dónde hay calle o acera (las piezas Road/Sidewalk… de Streets y MainRoads y las AceraManzana), en celdas de 8:
-- cada casa tiene que tener una a menos de 30 studs (scripts/test-mapcoherence: sin_acceso)
local ROAD_NAMES = { Road = true, Junction = true, BridgeDeck = true, Sidewalk = true, Curb = true, RingSidewalk = true, RingCurb = true, RoadKerb = true, KerbRamp = true }
local function roadIndex(world: Instance): { [string]: boolean }
	local cells = {}
	local function mark(d: BasePart)
		local cf, s = d.CFrame, d.Size
		local hx, hz = s.X / 2, s.Z / 2
		local isDisc = d:IsA("Part") and (d :: Part).Shape == Enum.PartType.Cylinder
		if isDisc then
			hx, hz = math.min(s.Y, s.Z) / 2, math.min(s.Y, s.Z) / 2
		end
		local lx = -hx
		while lx <= hx do
			local lz = -hz
			while lz <= hz do
				local p = if isDisc then cf.Position + Vector3.new(lx, 0, lz) else cf * Vector3.new(lx, 0, lz)
				cells[("%d_%d"):format(math.floor(p.X / 8), math.floor(p.Z / 8))] = true
				lz += 6
			end
			lx += 6
		end
	end
	for _, rootName in { "Streets", "MainRoads" } do
		local root = world:FindFirstChild(rootName)
		if root then
			for _, d in root:GetDescendants() do
				if d:IsA("BasePart") and ROAD_NAMES[d.Name] then
					mark(d)
				end
			end
		end
	end
	for _, d in world:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "AceraManzana" then
			mark(d)
		end
	end
	return cells
end
local function roadNear(cells: { [string]: boolean }, x: number, z: number, r: number): boolean
	local c = math.ceil(r / 8)
	local gx, gz = math.floor(x / 8), math.floor(z / 8)
	for i = gx - c, gx + c do
		for j = gz - c, gz + c do
			if cells[("%d_%d"):format(i, j)] and ((i + 0.5) * 8 - x) ^ 2 + ((j + 0.5) * 8 - z) ^ 2 <= r * r then
				return true
			end
		end
	end
	return false
end

-- Un huerto (en las parcelas sin calle cerca: no necesita acceso, es verde)
local function garden(parent: Instance, c: Vector3, seed: number)
	local r = rng(seed)
	local m = Builder.model("Huerto", parent)
	for k = -3, 3 do
		Builder.decor({ Name = "Surco", Size = V3(30, 0.6, 2), CFrame = CF(c + V3(0, 0.3, k * 4)), Color = rgb(84, 62, 44), Material = M.Ground, Parent = m })
		Builder.decor({ Name = "Cultivo", Size = V3(28, 1.4, 1), CFrame = CF(c + V3(0, 1.2, k * 4)), Color = rgb(70 + math.floor(r() * 30), 130 + math.floor(r() * 50), 50), Material = M.Grass, Parent = m })
	end
	for _, sx in { -16, 16 } do
		Builder.part({ Name = "Valla", Size = V3(0.6, 3, 30), CFrame = CF(c + V3(sx, 1.5, 0)), Color = rgb(110, 82, 56), Material = M.Wood, Parent = m })
	end
end

function Settlement.blocks(world: Instance): number
	local dc = world:FindFirstChild("Distritos")
	dc = dc and dc:FindFirstChild("District_Centro")
	if not dc then
		return 0
	end
	local made = 0
	local n = 0
	local roads = roadIndex(world)
	for _, block in dc:GetChildren() do
		if not Settlement.Replace[block.Name] then
			continue
		end
		local ground = block:FindFirstChild("BlockGround") :: BasePart?
		if not ground then
			continue
		end
		n += 1
		for _, child in block:GetChildren() do
			if child ~= ground then
				child:Destroy()
			end
		end
		block.Name = "Manzana_Asentamiento"
		ground.Material = M.Ground
		ground.Color = rgb(122, 104, 80)
		local c = ground.CFrame.Position + V3(0, ground.Size.Y / 2, 0)
		local size = ground.Size
		-- 12 casas por manzana (tres por lado, mirando a la calle y pegadas a la acera; alguna de dos plantas) y,
		-- dentro, la vida del asentamiento: mercado alrededor del pozo, huertos, hoguera, chatarra y vallas
		local halfX, halfZ = size.X / 2, size.Z / 2
		local sides = { { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } }
		for si, side in sides do
			local fx, fz = side[1], side[2]
			-- (lo que mide el lado y lo que hay hasta la calle: las manzanas no son todas iguales)
			local along = if fx ~= 0 then halfZ else halfX
			local depth = if fx ~= 0 then halfX else halfZ
			local tmax = math.min(58, along - 20)
			local slots = if tmax >= 30 then { -tmax, 0, tmax } elseif along >= 20 then { 0 } else {}
			for k, t in slots do
				local r = rng(n * 1013 + si * 131 + k * 17)
				local w = math.min(22 + math.floor(r() * 4) * 2, along * 2 - 12)
				local d = math.min(18 + math.floor(r() * 3) * 2, depth - 10)
				if w < 14 or d < 12 then
					continue
				end
				local edge = depth - d / 2 - 6
				-- (a lo largo del lado: t; hacia la calle: edge)
				local hx = if fx ~= 0 then fx * edge else t
				local hz = if fz ~= 0 then fz * edge else t
				local x, z = c.X + hx, c.Z + hz
				if roadNear(roads, x, z, 26) then
					local yaw = math.atan2(-fx, -fz)
					Settlement.house(block, CF(x, c.Y, z) * ANG(0, yaw, 0), w, d, n * 7919 + si * 101 + k * 13, false, r() < 0.3)
					made += 1
				else
					garden(block, c + V3(hx * 0.85, 0, hz * 0.85), n * 31 + si * 7 + k)
				end
			end
		end
		yard(block, c, n * 97)
		local r = rng(n * 4409 + 3)
		-- huertos a los lados del patio
		local gx = math.min(40, halfX - 24)
		for _, o in { { -gx, 0 }, { gx, 0 } } do
			garden(block, c + V3(o[1], 0, o[2] + (r() - 0.5) * 10), n * 53 + o[1])
		end
		-- hoguera con troncos para sentarse
		local fire = c + V3(0, 0, -math.min(34, halfZ - 14))
		Builder.part({ Name = "Hoguera", Shape = Enum.PartType.Cylinder, Size = V3(1, 6, 6), CFrame = CF(fire + V3(0, 0.5, 0)) * ANG(0, 0, math.rad(90)), Color = rgb(70, 66, 60), Material = M.Slate, Parent = block })
		local ember = Builder.decor({ Name = "Brasas", Size = V3(2.4, 1.4, 2.4), CFrame = CF(fire + V3(0, 1.4, 0)), Color = rgb(255, 140, 50), Material = M.Neon, Parent = block })
		local fl = Instance.new("Fire")
		fl.Size = 5
		fl.Heat = 7
		fl.Parent = ember
		local light = Instance.new("PointLight")
		light.Range = 24
		light.Brightness = 1.6
		light.Color = rgb(255, 170, 90)
		light.Shadows = false
		light.Parent = ember
		for q = 0, 2 do
			local a = q * math.pi * 2 / 3 + 0.4
			Builder.part({ Name = "Tronco", Shape = Enum.PartType.Cylinder, Size = V3(6, 1.6, 1.6), CFrame = CF(fire + V3(math.cos(a) * 6, 0.8, math.sin(a) * 6)) * ANG(0, -a, 0), Color = rgb(100, 72, 48), Material = M.Wood, Parent = block })
		end
		-- chatarra y cajas en las esquinas del patio
		local cx2, cz2 = math.min(62, halfX - 12), math.min(62, halfZ - 12)
		for _, o in { { -cx2, -cz2 }, { cx2, -cz2 }, { -cx2, cz2 }, { cx2, cz2 } } do
			local base = c + V3(o[1], 0, o[2])
			for q = 1, 3 do
				Builder.part({ Name = "Caja", Size = V3(3, 3, 3), CFrame = CF(base + V3((r() - 0.5) * 8, 1.5 + (if q == 3 then 3 else 0), (r() - 0.5) * 8)) * ANG(0, r() * 3, 0), Color = rgb(120, 92, 60), Material = M.WoodPlanks, Parent = block })
			end
			Builder.part({ Name = "Chatarra", Size = V3(5, 2.2, 4), CFrame = CF(base + V3(4, 1.1, -4)) * ANG(0.2, r() * 3, 0.15), Color = pick(METALS, r), Material = M.CorrodedMetal, Parent = block })
		end
	end
	return made
end

---------------------------------------------------------------------
-- Índice de lo construido (para no pisar nada): piezas por encima del suelo en una rejilla de 32 studs
---------------------------------------------------------------------
local DECOR_ROOTS = { Bosques = true, Naturaleza = true, Campo = true }

local function index(world: Instance): { [string]: { { [string]: any } } }
	local grid = {}
	for _, d in world:GetDescendants() do
		if d:IsA("BasePart") then
			local p = d.CFrame.Position
			local top = p.Y + d.Size.Y / 2
			if top > 1.5 and d.Size.Y > 0.6 and d.Name ~= "Sea" and d.Name ~= "Ground" then
				-- (¿es decorado del campo? se busca su modelo de arriba del todo dentro de esa carpeta)
				local deco: Instance? = nil
				local a: Instance? = d
				while a and a.Parent and a.Parent ~= world do
					if DECOR_ROOTS[a.Parent.Name] then
						deco = a
						break
					end
					a = a.Parent
				end
				local key = ("%d_%d"):format(math.floor(p.X / 32), math.floor(p.Z / 32))
				local cellList = grid[key]
				if not cellList then
					cellList = {}
					grid[key] = cellList
				end
				table.insert(cellList, { X = p.X, Z = p.Z, R = math.max(d.Size.X, d.Size.Z) / 2, Deco = deco, Part = d })
			end
		end
	end
	return grid
end

-- Lo que hay a menos de radius de (x, z): (¿algo construido?, lista de decorados del campo)
local function near(grid: any, x: number, z: number, radius: number): (boolean, { Instance })
	local built, decos = false, {}
	local c = math.ceil((radius + 40) / 32)
	local gx, gz = math.floor(x / 32), math.floor(z / 32)
	for i = gx - c, gx + c do
		for j = gz - c, gz + c do
			for _, e in grid[("%d_%d"):format(i, j)] or {} do
				if e.Part.Parent and math.sqrt((e.X - x) ^ 2 + (e.Z - z) ^ 2) - math.min(e.R, 30) < radius then
					if e.Deco then
						table.insert(decos, e.Deco)
					else
						built = true
					end
				end
			end
		end
	end
	return built, decos
end

---------------------------------------------------------------------
-- 2. La empalizada
---------------------------------------------------------------------
local function wallPiece(folder: Instance, a: Vector3, b: Vector3, seed: number)
	local r = rng(seed)
	local parent = Builder.model("TramoEmpalizada", folder)
	local len = (b - a).Magnitude
	local mid = (a + b) / 2
	local cf = Builder.facing(mid, b - a)
	local h = 13 + r() * 3
	Builder.part({ Name = "Muro", Size = V3(2.4, h, len + 0.4), CFrame = cf * CF(0, h / 2, 0), Color = pick(METALS, r), Material = M.CorrodedMetal, Parent = parent })
	-- troncos afilados por delante
	for k = -1, 1 do
		Builder.part({ Name = "Tronco", Shape = Enum.PartType.Cylinder, Size = V3(h + 3, 1.8, 1.8), CFrame = cf * CF(-1.6, (h + 3) / 2, k * len / 3) * ANG(0, 0, math.rad(90)), Color = pick(WOODS, r), Material = M.Wood, Parent = parent })
	end
end

local function tower(parent: Instance, at: Vector3, seed: number)
	local r = rng(seed)
	local m = Builder.model("TorreVigia", parent)
	for _, o in { { -3, -3 }, { 3, -3 }, { -3, 3 }, { 3, 3 } } do
		Builder.part({ Name = "Pata", Size = V3(1, 22, 1), CFrame = CF(at + V3(o[1], 11, o[2])), Color = pick(WOODS, r), Material = M.Wood, Parent = m })
	end
	Builder.part({ Name = "Plataforma", Size = V3(9, 1, 9), CFrame = CF(at + V3(0, 22, 0)), Color = rgb(104, 76, 52), Material = M.WoodPlanks, Parent = m })
	Builder.part({ Name = "Techo", Size = V3(10, 0.5, 10), CFrame = CF(at + V3(0, 28, 0)), Color = rgb(130, 76, 50), Material = M.CorrodedMetal, Parent = m })
	local lamp = Builder.decor({ Name = "Foco", Size = V3(1.4, 1, 1.4), CFrame = CF(at + V3(0, 26.6, 0)), Color = rgb(255, 230, 170), Material = M.Neon, Parent = m })
	local light = Instance.new("PointLight")
	light.Range = 40
	light.Brightness = 1.4
	light.Color = rgb(255, 220, 160)
	light.Shadows = false
	light.Parent = lamp
end

function Settlement.wall(world: Instance, grid: any): (number, number)
	local Roads = require(script.Parent.Roads)
	local centro: { [string]: any }? = nil
	for _, d in CityPlan.Districts do
		if d.Id == "Centro" then
			centro = d
		end
	end
	if not centro then
		return 0, 0
	end
	local poly = centro.MapPoly or centro.Poly
	-- (una carpeta con cada tramo en su modelo: no es «un edificio» enorme que tape medio distrito)
	local folder = Instance.new("Folder")
	folder.Name = "Empalizada"
	folder.Parent = world
	-- el centro del polígono (para empujar el muro hacia fuera)
	local cx, cz = 0, 0
	for _, p in poly do
		cx += p[1]
		cz += p[2]
	end
	cx /= #poly
	cz /= #poly
	local pieces, gates = 0, 0
	local STEP = 24
	local lastGate = -1e9
	local walked = 0
	for i = 1, #poly do
		local a, b = poly[i], poly[i % #poly + 1]
		local ax, az, bx, bz = a[1], a[2], b[1], b[2]
		local len = math.sqrt((bx - ax) ^ 2 + (bz - az) ^ 2)
		local ux, uz = (bx - ax) / len, (bz - az) / len
		-- la normal hacia fuera
		local nx, nz = uz, -ux
		local mx, mz = (ax + bx) / 2, (az + bz) / 2
		if (mx + nx * 50 - cx) ^ 2 + (mz + nz * 50 - cz) ^ 2 < (mx - cx) ^ 2 + (mz - cz) ^ 2 then
			nx, nz = -nx, -nz
		end
		local off = Settlement.WallOffset
		local s = 0
		while s < len do
			local s2 = math.min(len, s + STEP)
			local x0, z0 = ax + ux * s + nx * off, az + uz * s + nz * off
			local x1, z1 = ax + ux * s2 + nx * off, az + uz * s2 + nz * off
			local xm, zm = (x0 + x1) / 2, (z0 + z1) / 2
			local onLand = CityPlan.inside(CityPlan.Coast, xm, zm) and CityPlan.riverDistance(xm, zm) > CityPlan.River.Width / 2 + 20
			if onLand then
				if Roads.near(xm, zm, 6) then
					-- una puerta: dos torres de vigía a los lados de la carretera (una vez por cruce)
					if walked + s - lastGate > Settlement.GateWidth * 2 then
						lastGate = walked + s
						gates += 1
						for _, side in { -1, 1 } do
							local tx, tz = xm + ux * side * Settlement.GateWidth / 2 * 1.4, zm + uz * side * Settlement.GateWidth / 2 * 1.4
							if not Roads.near(tx, tz, 4) and not (near(grid, tx, tz, 8)) then
								tower(folder, V3(tx, 0, tz), gates * 11 + side)
							end
						end
					end
				else
					local built, decos = near(grid, xm, zm, STEP / 2 + 3)
					if not built then
						for _, deco in decos do
							if deco.Parent then
								deco:Destroy()
							end
						end
						wallPiece(folder, V3(x0, 0, z0), V3(x1, 0, z1), i * 1000 + math.floor(s))
						pieces += 1
						-- una torre de vigía cada ~300 studs de muro
						if pieces % 13 == 0 then
							tower(folder, V3(xm - nx * 8, 0, zm - nz * 8), pieces)
						end
					end
				end
			end
			s = s2
		end
		walked += len
	end
	return pieces, gates
end

---------------------------------------------------------------------
-- 3. Ruinas en los distritos de caza
---------------------------------------------------------------------
function Settlement.ruins(world: Instance, grid: any): number
	local Roads = require(script.Parent.Roads)
	local folder = Instance.new("Folder")
	folder.Name = "Ruinas"
	folder.Parent = world
	local made = 0
	for di, d in CityPlan.Districts do
		if not d.Farm then
			continue
		end
		local r = rng(di * 4421 + 17)
		local x0, x1, z0, z1 = math.huge, -math.huge, math.huge, -math.huge
		for _, p in d.Poly do
			x0, x1 = math.min(x0, p[1]), math.max(x1, p[1])
			z0, z1 = math.min(z0, p[2]), math.max(z1, p[2])
		end
		local placed: { { number } } = {}
		for _ = 1, Settlement.RuinsPerFarm * 60 do
			if #placed >= Settlement.RuinsPerFarm then
				break
			end
			local x, z = x0 + r() * (x1 - x0), z0 + r() * (z1 - z0)
			local ok = CityPlan.inside(d.Poly, x, z) and CityPlan.inside(CityPlan.Coast, x, z) and CityPlan.riverDistance(x, z) > CityPlan.River.Width / 2 + 60
			if ok then
				for _, lake in CityPlan.Lakes do
					if (x - lake.X) ^ 2 + (z - lake.Z) ^ 2 < (lake.R + 60) ^ 2 then
						ok = false
					end
				end
			end
			if ok then
				for _, p in placed do
					if (p[1] - x) ^ 2 + (p[2] - z) ^ 2 < Settlement.RuinGap * Settlement.RuinGap then
						ok = false
						break
					end
				end
			end
			if ok and not Roads.near(x, z, 30) and not (near(grid, x, z, 30)) then
				table.insert(placed, { x, z })
				local w = 16 + math.floor(r() * 4) * 2
				local dd = 14 + math.floor(r() * 4) * 2
				Settlement.house(folder, CF(x, 0, z) * ANG(0, r() * math.pi * 2, 0), w, dd, di * 100000 + #placed * 37, true)
				made += 1
			end
		end
	end
	return made
end

function Settlement.build(world: Instance): { [string]: number }
	local houses = Settlement.blocks(world)
	local grid = index(world)
	local okW, pieces, gates = pcall(Settlement.wall, world, grid)
	if not okW then
		warn("[Settlement] empalizada: " .. tostring(pieces))
		pieces, gates = 0, 0
	end
	local okR, ruins = pcall(Settlement.ruins, world, grid)
	if not okR then
		warn("[Settlement] ruinas: " .. tostring(ruins))
		ruins = 0
	end
	return { Houses = houses, Wall = pieces :: number, Gates = gates :: number, Ruins = ruins :: number }
end

return Settlement
