-- RegionLandmarks: los LUGARES de cada región, construidos de verdad (17-11-2026, el dueño con sus dibujos del
-- Bosque Etéreo: santuario, árbol ancestral, cueva, cascada, campamento, portal, pradera y ruinas). Datos en
-- shared/Cosmos/RegionGuide; lo llama World/OuterLandsBuilder cuando el terreno de las Tierras Exteriores está
-- escrito (cada lugar se apoya en OuterLands.height).
--
--   Santuario  plataforma de piedra con columnas, cristal de luz, Taller y cartel de zona segura
--   Arbol      el árbol ancestral gigante de fantasía (World/Kit/AncientTree): raíces, ramas, copa, lianas y luces
--   Cueva      un monte de roca con la boca de la cueva y un remolino de luz dentro (la entrada de una mazmorra)
--   Cascada    una pared de roca con el agua cayendo, niebla y la poza
--   Campamento tiendas oscuras, hoguera, estacas y un tótem (enemigos)
--   Territorio huesos, tótems de calavera y troncos arañados (las manadas ya las ponen las guaridas)
--   Portal     un arco de piedra en círculo con un remolino morado
--   Ruinas     muros y columnas caídas (World/Kit/BeastKit.ruin)
-- Encima de cada uno, su cartel (como en el dibujo): icono, nombre y «Nv. 15+» (o «Zona segura»).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Builder = require(script.Parent.Builder)
local RegionGuide = require(ReplicatedStorage.Shared.Cosmos.RegionGuide)
local OuterLands = require(ReplicatedStorage.Shared.Cosmos.OuterLands)
local VR = require(ReplicatedStorage.Shared.Cosmos.ValmarRegions)

local RegionLandmarks = {}

local rgb = Color3.fromRGB
local V3 = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local M = Enum.Material

local function rng(seed: number): () -> number
	local s = math.max(1, math.floor(seed) % 2147483646)
	return function(): number
		s = (s * 16807) % 2147483647
		return s / 2147483647
	end
end

local function P(parent: Instance, props: { [string]: any }): BasePart
	props.Parent = parent
	return Builder.part(props)
end

local function light(part: Instance, color: Color3, range: number, brightness: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = part
end

local function sparkles(part: Instance, color: Color3, rate: number)
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(color)
	e.LightEmission = 1
	e.Size = NumberSequence.new(0.8, 0)
	e.Lifetime = NumberRange.new(1, 2)
	e.Speed = NumberRange.new(1, 3)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = rate
	e.Parent = part
end

-- El cartel de encima: icono, nombre y nivel
local function label(part: BasePart, place: { [string]: any }, height: number)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Cartel"
	gui.Size = UDim2.fromOffset(230, 56)
	gui.StudsOffsetWorldSpace = V3(0, height, 0)
	gui.MaxDistance = 520
	gui.LightInfluence = 0
	gui.Parent = part
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = rgb(16, 20, 32)
	bg.BackgroundTransparency = 0.2
	bg.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = bg
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.fromOffset(50, 50)
	icon.Position = UDim2.fromOffset(3, 3)
	icon.BackgroundTransparency = 1
	icon.Text = RegionGuide.Icons[place.Kind] or "📍"
	icon.TextScaled = true
	icon.Parent = bg
	local name = Instance.new("TextLabel")
	name.Position = UDim2.fromOffset(56, 4)
	name.Size = UDim2.new(1, -60, 0, 26)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextScaled = true
	name.TextColor3 = rgb(255, 255, 255)
	name.Text = place.Name
	name.Parent = bg
	local lv = Instance.new("TextLabel")
	lv.Position = UDim2.fromOffset(56, 30)
	lv.Size = UDim2.new(1, -60, 0, 22)
	lv.BackgroundTransparency = 1
	lv.Font = Enum.Font.GothamBold
	lv.TextScaled = true
	lv.TextColor3 = if place.Level then rgb(255, 214, 80) else rgb(110, 255, 140)
	lv.Text = if place.Level then ("Nv. %d+"):format(place.Level) else "Zona segura"
	lv.Parent = bg
end

---------------------------------------------------------------------
-- Cada tipo de lugar (base: CFrame en el suelo)
---------------------------------------------------------------------
local BUILD: { [string]: (Model, CFrame, () -> number, { [string]: any }) -> number } = {}

BUILD.Santuario = function(m, base, r, place)
	local stone = rgb(176, 170, 156)
	P(m, { Name = "Plataforma", Shape = Enum.PartType.Cylinder, Size = V3(2, 50, 50), CFrame = base * CF(0, 0.6, 0) * ANG(0, 0, math.rad(90)), Color = stone, Material = M.Cobblestone })
	P(m, { Name = "Escalon", Shape = Enum.PartType.Cylinder, Size = V3(1.4, 56, 56), CFrame = base * CF(0, 0.1, 0) * ANG(0, 0, math.rad(90)), Color = stone:Lerp(rgb(0, 0, 0), 0.15), Material = M.Cobblestone })
	for k = 0, 5 do
		local a = k * math.pi / 3
		local c = base * CF(math.cos(a) * 21, 0, math.sin(a) * 21)
		P(m, { Name = "Columna", Size = V3(3, 16, 3), CFrame = c * CF(0, 9, 0), Color = rgb(196, 190, 176), Material = M.Marble })
		P(m, { Name = "Capitel", Size = V3(4.4, 1.2, 4.4), CFrame = c * CF(0, 17.6, 0), Color = rgb(206, 200, 186), Material = M.Marble })
	end
	local crystal = P(m, { Name = "Cristal", ClassName = "Part", Size = V3(3, 8, 3), CFrame = base * CF(0, 7, 0) * ANG(0, math.rad(45), math.rad(8)), Color = rgb(110, 200, 255), Material = M.Neon, CanCollide = false })
	P(m, { Name = "Pedestal", Size = V3(6, 2, 6), CFrame = base * CF(0, 2, 0), Color = rgb(140, 136, 126), Material = M.Slate })
	light(crystal, rgb(130, 200, 255), 40, 2)
	sparkles(crystal, rgb(160, 220, 255), 6)
	local okKit, BeastKit = pcall(function()
		return require(script.Parent.Kit.BeastKit) :: any
	end)
	if okKit then
		pcall(BeastKit.bench, m, base * CF(0, 1.2, 14), nil)
		pcall(BeastKit.zoneSign, m, base * CF(12, 1.2, -16), ("🏛 %s · zona segura"):format(place.Name), 1)
	end
	return 22
end

-- (el árbol gigante de fantasía: World/Kit/AncientTree)
BUILD.Arbol = function(m, base, r)
	-- (18-11-2026) el Santuario del Bosque entero: la terraza con su arquitectura (World/Kit/ForestSanctuary) y,
	-- encima, el Árbol Ancestral de mallas (World/Kit/AncientTree). El guardián y la misión: Services/SanctuaryService
	local Sanctuary = require(script.Parent.Kit.ForestSanctuary) :: any
	local AncientTree = require(script.Parent.Kit.AncientTree) :: any
	local _, points = Sanctuary.build(m, base, math.floor(r() * 100000))
	AncientTree.build(m, base * CFrame.new(0, Sanctuary.Elevation, 0), math.floor(r() * 100000), 1)
	m:SetAttribute("SantuarioBosque", true)
	m:SetAttribute("Guardian", points.Guardian)
	m:AddTag("SantuarioBosque")
	-- (el cartel, a media altura del árbol, debajo de la copa: se ve desde la escalinata, como en la imagen del dueño)
	return 150
end

BUILD.Cueva = function(m, base, r)
	local rock = rgb(104, 100, 96)
	for k = 0, 6 do
		local a = math.pi + (k - 3) * 0.42
		local size = 22 + r() * 12
		P(m, { Name = "Roca", Shape = Enum.PartType.Ball, Size = V3(size, size * 0.9, size), CFrame = base * CF(math.cos(a) * 16, size * 0.3, math.sin(a) * 16 + 10), Color = rock:Lerp(rgb(70, 66, 64), r() * 0.5), Material = M.Rock })
	end
	P(m, { Name = "Monte", Shape = Enum.PartType.Ball, Size = V3(44, 34, 40), CFrame = base * CF(0, 8, 20), Color = rock, Material = M.Rock })
	-- la boca: arco de roca y dentro un remolino de luz
	P(m, { Name = "Dintel", Size = V3(18, 4, 6), CFrame = base * CF(0, 16, 2), Color = rgb(86, 82, 78), Material = M.Slate })
	for _, sx in { -8, 8 } do
		P(m, { Name = "Jamba", Size = V3(4, 16, 6), CFrame = base * CF(sx, 8, 2), Color = rgb(86, 82, 78), Material = M.Slate })
	end
	local hole = P(m, { Name = "Boca", Size = V3(12, 14, 1), CFrame = base * CF(0, 7, 4), Color = rgb(10, 10, 16), Material = M.SmoothPlastic, CanCollide = false })
	local swirl = P(m, { Name = "Remolino", Shape = Enum.PartType.Cylinder, Size = V3(0.4, 10, 10), CFrame = base * CF(0, 7, 3.2) * ANG(0, math.rad(90), 0), Color = rgb(90, 140, 255), Material = M.Neon, Transparency = 0.35, CanCollide = false })
	light(swirl, rgb(100, 140, 255), 30, 2)
	sparkles(swirl, rgb(150, 180, 255), 10)
	local _ = hole
	return 30
end

BUILD.Cascada = function(m, base, r)
	local rock = rgb(110, 108, 104)
	P(m, { Name = "Pared", Size = V3(44, 46, 14), CFrame = base * CF(0, 23, 12), Color = rock, Material = M.Rock })
	for k = 1, 4 do
		P(m, { Name = "Roca", Shape = Enum.PartType.Ball, Size = V3(16, 16, 16), CFrame = base * CF((k - 2.5) * 12, 42 + r() * 6, 12), Color = rock:Lerp(rgb(60, 70, 60), 0.2), Material = M.Rock })
	end
	local fall = P(m, { Name = "Agua", Size = V3(12, 44, 1), CFrame = base * CF(0, 22, 4.6), Color = rgb(160, 220, 255), Material = M.Glass, Transparency = 0.25, CanCollide = false })
	local mist = Instance.new("ParticleEmitter")
	mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
	mist.Color = ColorSequence.new(rgb(230, 245, 255))
	mist.Size = NumberSequence.new(4, 10)
	mist.Transparency = NumberSequence.new(0.5, 1)
	mist.Lifetime = NumberRange.new(1.5, 2.5)
	mist.Speed = NumberRange.new(2, 5)
	mist.SpreadAngle = Vector2.new(60, 60)
	mist.Rate = 12
	mist.Parent = fall
	P(m, { Name = "Poza", Shape = Enum.PartType.Cylinder, Size = V3(1, 30, 30), CFrame = base * CF(0, 0.6, -8) * ANG(0, 0, math.rad(90)), Color = rgb(70, 150, 210), Material = M.Glass, Transparency = 0.2, CanCollide = false })
	for k = 0, 7 do
		local a = k * math.pi / 4
		P(m, { Name = "Borde", Size = V3(5, 2.4, 4), CFrame = base * CF(math.cos(a) * 15, 1, -8 + math.sin(a) * 15) * ANG(0, a, 0), Color = rgb(120, 116, 110), Material = M.Rock })
	end
	return 52
end

BUILD.Campamento = function(m, base, r)
	local cloth = rgb(92, 60, 48)
	for k = 0, 3 do
		local a = k * math.pi / 2 + 0.5
		local c = base * CF(math.cos(a) * 16, 0, math.sin(a) * 16) * ANG(0, -a + math.pi / 2, 0)
		P(m, { Name = "Tienda", ClassName = "WedgePart", Size = V3(14, 10, 7), CFrame = c * CF(0, 5, -3.5), Color = cloth, Material = M.Fabric })
		P(m, { Name = "Tienda", ClassName = "WedgePart", Size = V3(14, 10, 7), CFrame = c * CF(0, 5, 3.5) * ANG(0, math.pi, 0), Color = cloth, Material = M.Fabric })
	end
	local fire = P(m, { Name = "Brasas", Size = V3(3, 1.6, 3), CFrame = base * CF(0, 1, 0), Color = rgb(255, 130, 40), Material = M.Neon, CanCollide = false })
	local fx = Instance.new("Fire")
	fx.Size = 7
	fx.Heat = 9
	fx.Parent = fire
	light(fire, rgb(255, 150, 70), 34, 2)
	for k = 0, 17 do
		local a = k / 18 * math.pi * 2
		P(m, { Name = "Estaca", Size = V3(1.6, 8, 1.6), CFrame = base * CF(math.cos(a) * 28, 3.6, math.sin(a) * 28) * ANG(math.rad(-12), a, 0), Color = rgb(86, 64, 44), Material = M.Wood })
	end
	P(m, { Name = "Totem", Size = V3(2.4, 14, 2.4), CFrame = base * CF(8, 7, -8), Color = rgb(110, 80, 56), Material = M.Wood })
	P(m, { Name = "Calavera", Shape = Enum.PartType.Ball, Size = V3(3, 3, 3), CFrame = base * CF(8, 15, -8), Color = rgb(236, 230, 214), Material = M.SmoothPlastic })
	return 20
end

BUILD.Territorio = function(m, base, r)
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2 + r()
		local c = base * CF(math.cos(a) * 18, 0, math.sin(a) * 18)
		if k % 2 == 0 then
			P(m, { Name = "Totem", Size = V3(2, 10, 2), CFrame = c * CF(0, 5, 0), Color = rgb(100, 78, 56), Material = M.Wood })
			P(m, { Name = "Calavera", Shape = Enum.PartType.Ball, Size = V3(2.6, 2.6, 2.6), CFrame = c * CF(0, 10.8, 0), Color = rgb(230, 224, 206), Material = M.SmoothPlastic })
		else
			P(m, { Name = "Tronco", Shape = Enum.PartType.Cylinder, Size = V3(12, 2.4, 2.4), CFrame = c * CF(0, 1.2, 0) * ANG(0, a, 0), Color = rgb(96, 72, 50), Material = M.Wood })
		end
	end
	for k = 1, 6 do
		Builder.decor({ Name = "Hueso", Size = V3(0.6, 0.6, 3 + r() * 2), CFrame = base * CF((r() - 0.5) * 30, 0.4, (r() - 0.5) * 30) * ANG(0, r() * 3, 0), Color = rgb(230, 224, 208), Material = M.SmoothPlastic, Parent = m })
	end
	return 14
end

BUILD.Portal = function(m, base, r)
	local stone = rgb(120, 112, 124)
	local R = 11
	for k = 0, 13 do
		local a = k / 14 * math.pi * 2
		P(m, { Name = "Piedra", Size = V3(3.4, 5, 4), CFrame = base * CF(0, R + 2, 0) * ANG(0, 0, a) * CF(0, R, 0), Color = stone, Material = M.Slate })
	end
	local disc = P(m, { Name = "Remolino", Shape = Enum.PartType.Cylinder, Size = V3(0.5, R * 1.7, R * 1.7), CFrame = base * CF(0, R + 2, 0), Color = rgb(170, 90, 255), Material = M.Neon, Transparency = 0.3, CanCollide = false })
	light(disc, rgb(180, 110, 255), 40, 2.2)
	sparkles(disc, rgb(210, 160, 255), 14)
	P(m, { Name = "Base", Size = V3(10, 2, 6), CFrame = base * CF(0, 1, 0), Color = stone, Material = M.Cobblestone })
	return R * 2 + 8
end

BUILD.Ruinas = function(m, base, r, place)
	local okKit, BeastKit = pcall(function()
		return require(script.Parent.Kit.BeastKit) :: any
	end)
	for k = 0, 3 do
		local a = k * math.pi / 2 + r()
		local c = base * CF(math.cos(a) * 16, 0, math.sin(a) * 16) * ANG(0, r() * 6, 0)
		if okKit then
			pcall(BeastKit.ruin, m, c, "Roca", (place.Level or 1) * 13 + k)
		end
	end
	for k = 0, 5 do
		local hgt = 8 + r() * 14
		P(m, { Name = "Columna", Size = V3(3, hgt, 3), CFrame = base * CF((r() - 0.5) * 30, hgt / 2, (r() - 0.5) * 30) * ANG(r() * 0.2, 0, r() * 0.2), Color = rgb(170, 164, 150), Material = M.Limestone })
	end
	return 24
end
BUILD.Jefe = BUILD.Ruinas

function RegionLandmarks.build(parent: Instance): number
	local folder = Instance.new("Folder")
	folder.Name = "LugaresRegiones"
	folder.Parent = parent
	local n = 0
	for i, e in RegionGuide.all() do
		local place = e.Place
		local fn = BUILD[place.Kind]
		local h = OuterLands.height(e.X, e.Z)
		if fn and h then
			local m = Builder.model("Lugar_" .. e.Region .. "_" .. place.Id, folder)
			m:SetAttribute("Region", e.Region)
			m:SetAttribute("Lugar", place.Name)
			-- (mirando hacia el centro de la isla: la entrada da hacia donde viene la gente)
			local yaw = math.atan2(e.X, e.Z)
			local base = CF(e.X, h, e.Z) * ANG(0, yaw, 0)
			local ok, top = pcall(fn, m, base, rng(i * 7717 + 5), place)
			if ok then
				local anchor = m:FindFirstChildWhichIsA("BasePart")
				if anchor then
					label(anchor, place, (top :: number) + 6 - (anchor.Position.Y - h))
				end
				n += 1
			else
				warn("[RegionLandmarks] " .. place.Name .. ": " .. tostring(top))
			end
		end
	end
	return n
end

local _ = VR
return RegionLandmarks
