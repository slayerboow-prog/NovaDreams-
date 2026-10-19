-- SeaBiome (cliente): el mundo de debajo del agua, solo en tu pantalla y solo cuando estás en el agua.
--
-- En el mar hondo (shared/Sea/Ocean, docs/mar/diseno.md) cada zona tiene su fondo y su luz
-- (shared/Sea/OceanBiomes): el Arrecife Escarlata con corales de colores y agua clara, el Laberinto de
-- Kelp con algas gigantes que se mecen y luz verde, la Llanura Sumergida con praderas, el Talud del
-- Naufragio con rocas y esponjas, la Garganta Negra y el Abismo Silente oscuros con bioluminiscencia,
-- fumarolas y huesos, y la Sima del Kraken casi negra. La luz (zona «Submarino» de shared/Cosmos/EnvZones:
-- SeaBiome se la cuenta a Controllers/EnvDirector, el único dueño de la luz) y el color del agua cambian
-- con la zona y se oscurecen con la profundidad; los rayos de sol solo cerca de la superficie; abajo,
-- «nieve marina» y plancton que brilla. SeaBiome.state() dice dónde estás (lo lee el HUD de buceo).
-- Mar enorme (v120): árboles de coral de luz (blanco, cian y rosa) y haces de sol más largos.
--
--   * Agua: al meterte, la superficie deja de ser un espejo (menos reflejo, más transparente) para que
--     desde fuera se vea a quien nada y bucea. Al salir vuelve a ser como antes.
--   * Luz: con la cámara bajo el agua, EnvDirector → DayLight pone la bruma azul del mar de la zona.
--     Rayos de sol que entran desde la superficie (de día) y motas flotando delante de la cámara.
--   * Fondo: alrededor de ti se crea el fondo según el agua:
--       mar y alta mar  praderas de posidonia, algas largas que se mecen, rocas, corales (cerebro,
--                       ramas y gorgonias), erizos, estrellas de mar, conchas y, a veces, un ánfora o un ancla
--       río y lagos     plantas de agua, juncos, piedras, troncos hundidos y cantos rodados
--     Se hace por trozos (siempre igual en el mismo sitio) y se quita lo que queda lejos.
--   * Vida: la pone Controllers/SeaLife (bancos de peces con boids, rayas, tortugas, medusas, delfines,
--     criaturas del abismo, el megalodón y el kraken).
-- Todo es decorado: no choca, no se puede tocar y no lo ve nadie más (no gasta red).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameClock = require(ReplicatedStorage.Shared.GameClock) -- (la hora del juego: GameClock.hour())
local CityPlan = require(ReplicatedStorage.Shared.CityPlan)
local Ocean = require(ReplicatedStorage.Shared.Sea.Ocean)
local OceanBiomes = require(ReplicatedStorage.Shared.Sea.OceanBiomes)
local Perf = require(script.Parent.Parent.UI.Perf)
local EnvDirector = require(script.Parent.EnvDirector)

local SeaBiome = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB
local angles = CFrame.Angles
local sin, cos, floor = math.sin, math.cos, math.floor

local SURFACE = -2
local CELL = 14
local RADIUS = if Perf.mobile then 56 else 84
local BUILD_PER_TICK = if Perf.mobile then 4 else 8
local SWAY_DISTANCE = 45

local MAX_GLOW_LIGHTS = if Perf.mobile then 3 else 8 -- luces de verdad de la bioluminiscencia
local FAR_BELOW = 130 -- un fondo más hondo que esto bajo la cámara no se planta (no se ve)

type Sway = { Parts: { BasePart }, Heights: { number }, Base: CFrame, Phase: number, Amount: number }
type Cell = { Parts: { Instance }, Sway: { Sway }, Far: number? }

local folder: Folder? = nil
local cells: { [string]: Cell } = {}
local sways: { Sway } = {}
local active = false
local leftAt = 0
local defaults: { Reflectance: number, Transparency: number }? = nil
local waterLook = 0 -- 0 = agua normal, 1 = agua para ver bajo ella
local under = 0 -- cámara bajo el agua (suave)
local glowLights = 0
-- Dónde está la cámara en el mar (zona y profundidad) y la luz de ahora (va hacia la de la zona poco a poco)
local here = { Zone = nil :: string?, Meters = 0, Sea = false }
local look: { [string]: any }? = nil
local baseWaterColor: Color3? = nil

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------

-- Número "al azar" pero siempre el mismo para el mismo sitio (0..1)
local function hash(x: number, z: number, n: number): number
	local v = sin(x * 127.1 + z * 311.7 + n * 74.7) * 43758.5453
	return v - floor(v)
end

local waterParams = RaycastParams.new()
waterParams.FilterType = Enum.RaycastFilterType.Include
waterParams.IgnoreWater = false
local floorParams = RaycastParams.new()
floorParams.FilterType = Enum.RaycastFilterType.Include
floorParams.IgnoreWater = true

local function isWater(x: number, z: number): boolean
	waterParams.FilterDescendantsInstances = { workspace.Terrain }
	local hit = workspace:Raycast(Vector3.new(x, SURFACE + 14, z), Vector3.new(0, -30, 0), waterParams)
	return hit ~= nil and hit.Material == Enum.Material.Water
end

-- ¿Hay agua de verdad en este punto? (la celda del terreno). Muy por debajo de la superficie (el metro
-- bajo el río, a -42 y -66) solo cuenta así: el túnel está seco aunque encima haya agua.
local DEEP = 20 -- más hondo que SURFACE - DEEP, hace falta agua en ese mismo sitio
local function waterHere(p: Vector3): boolean
	local ok, wet = pcall(function()
		local lo = Vector3.new(math.floor(p.X / 4) * 4, math.floor(p.Y / 4) * 4, math.floor(p.Z / 4) * 4)
		local materials = workspace.Terrain:ReadVoxels(Region3.new(lo, lo + Vector3.new(4, 4, 4)), 4)
		return materials[1][1][1] == Enum.Material.Water
	end)
	return ok and wet == true
end

-- Agua en esta columna y a esta altura (cerca de la superficie, basta con que haya agua debajo)
local function wetAt(p: Vector3): boolean
	if not isWater(p.X, p.Z) then
		return false
	end
	return p.Y > SURFACE - DEEP or waterHere(p)
end

-- Altura del fondo (o nil si no hay agua bastante honda). Hasta la Sima del Kraken (-560).
local function floorAt(x: number, z: number): number?
	floorParams.FilterDescendantsInstances = { workspace.Terrain }
	local hit = workspace:Raycast(Vector3.new(x, SURFACE - 0.5, z), Vector3.new(0, -640, 0), floorParams)
	if not hit or hit.Position.Y > SURFACE - 3 then
		return nil
	end
	return hit.Position.Y
end

local function segmentDistance(p: Vector2, a: Vector2, b: Vector2): number
	local ab = b - a
	local t = math.clamp((p - a):Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
	return (p - (a + ab * t)).Magnitude
end

-- Agua dulce (río o lago) o mar
local function freshwater(x: number, z: number): boolean
	local p = Vector2.new(x, z)
	for _, lake in CityPlan.Lakes do
		if (p - Vector2.new(lake.X, lake.Z)).Magnitude < lake.R + 40 then
			return true
		end
	end
	local pts = CityPlan.River.Points
	for i = 1, #pts - 1 do
		if segmentDistance(p, Vector2.new(pts[i][1], pts[i][2]), Vector2.new(pts[i + 1][1], pts[i + 1][2])) < CityPlan.River.Width / 2 + 40 then
			return true
		end
	end
	return false
end

local function getFolder(): Folder
	if not folder or not folder.Parent then
		local f = Instance.new("Folder")
		f.Name = "SeaBiome"
		f.Parent = workspace
		folder = f
	end
	return folder :: Folder
end

local function piece(cell: Cell, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?, transparency: number?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.Transparency = transparency or 0
	p.Parent = getFolder()
	table.insert(cell.Parts, p)
	return p
end

-- Algo alto que se mece (alga larga, hojas de posidonia): trozos encadenados desde la base
local function swaying(cell: Cell, base: CFrame, heights: { number }, width: number, color: Color3, amount: number, seed: number)
	local parts, cur = {}, base
	for _, h in heights do
		local p = piece(cell, Vector3.new(width, h, width * 0.25), cur * CFrame.new(0, h / 2, 0), color, Enum.Material.SmoothPlastic)
		table.insert(parts, p)
		cur = cur * CFrame.new(0, h, 0)
	end
	local s: Sway = { Parts = parts, Heights = heights, Base = base, Phase = seed * 10, Amount = amount }
	table.insert(cell.Sway, s)
	table.insert(sways, s)
end

---------------------------------------------------------------------
-- Cosas del fondo
---------------------------------------------------------------------
local SEA_GREEN = { rgb(52, 110, 60), rgb(70, 128, 58), rgb(40, 96, 70) }
local CORAL = { rgb(232, 96, 110), rgb(245, 150, 70), rgb(170, 90, 200), rgb(250, 200, 90), rgb(90, 190, 200) }

local function seagrass(cell: Cell, at: Vector3, r: number)
	for i = 1, 5 + floor(r * 4) do
		local a = hash(at.X, at.Z, i) * math.pi * 2
		local off = Vector3.new(cos(a), 0, sin(a)) * hash(at.Z, at.X, i) * 1.4
		local h = 1.2 + hash(at.X + i, at.Z, 3) * 2
		local base = CFrame.new(at + off) * angles((hash(i, at.X, 4) - 0.5) * 0.4, a, (hash(at.Z, i, 5) - 0.5) * 0.4)
		swaying(cell, base, { h * 0.5, h * 0.5 }, 0.18, SEA_GREEN[1 + floor(hash(i, i, at.X) * 3) % 3], 0.18, hash(at.X, i, 6))
	end
end

local function kelp(cell: Cell, at: Vector3, r: number)
	local depth = SURFACE - 1 - at.Y
	local segs = math.clamp(floor(depth / 2.2), 2, 5)
	local heights = {}
	for i = 1, segs do
		heights[i] = 1.8 + hash(at.X, at.Z, i) * 0.6
	end
	swaying(cell, CFrame.new(at) * angles(0, r * 6, 0), heights, 0.5, rgb(96, 110, 40):Lerp(rgb(70, 90, 30), r), 0.1, r)
end

local function rock(cell: Cell, at: Vector3, r: number)
	local size = 1.5 + r * 4
	local material = if r > 0.5 then Enum.Material.Slate else Enum.Material.Basalt
	piece(cell, Vector3.new(size, size * 0.6, size * 0.8), CFrame.new(at + Vector3.new(0, size * 0.15, 0)) * angles(r, r * 5, r * 2), rgb(96, 100, 96):Lerp(rgb(70, 80, 84), r), material)
	if r > 0.6 then
		piece(cell, Vector3.new(size * 0.5, size * 0.4, size * 0.5), CFrame.new(at + Vector3.new(size * 0.5, 0.1, size * 0.2)) * angles(r * 3, r, 0), rgb(88, 92, 90), material)
	end
end

local function coral(cell: Cell, at: Vector3, r: number)
	local color = CORAL[1 + floor(r * #CORAL) % #CORAL]
	local kind = floor(hash(at.X, at.Z, 9) * 3)
	if kind == 0 then
		-- Coral cerebro
		local d = 1.2 + r * 1.6
		piece(cell, Vector3.new(d, d * 0.8, d), CFrame.new(at + Vector3.new(0, d * 0.3, 0)), color, Enum.Material.Pebble, Enum.PartType.Ball)
	elseif kind == 1 then
		-- Coral de ramas
		for i = 1, 5 + floor(r * 3) do
			local a = hash(at.X, i, 10) * math.pi * 2
			local h = 0.8 + hash(i, at.Z, 11) * 1.4
			piece(cell, Vector3.new(h, 0.22, 0.22), CFrame.new(at + Vector3.new(cos(a) * 0.3, h * 0.45, sin(a) * 0.3)) * angles(0, a, math.rad(60 + hash(i, i, 12) * 25)), color, Enum.Material.Pebble, Enum.PartType.Cylinder)
		end
	else
		-- Gorgonia (abanico)
		local w = 1.6 + r * 1.8
		swaying(cell, CFrame.new(at) * angles(0, r * 6, 0), { w * 0.9 }, w, color:Lerp(rgb(200, 40, 70), 0.4), 0.08, r)
	end
end

local function critter(cell: Cell, at: Vector3, r: number)
	local kind = floor(hash(at.Z, at.X, 13) * 3)
	if kind == 0 then
		-- Estrella de mar
		local color = if r > 0.5 then rgb(240, 120, 50) else rgb(220, 70, 60)
		for i = 0, 4 do
			piece(cell, Vector3.new(0.22, 0.12, 0.9), CFrame.new(at + Vector3.new(0, 0.08, 0)) * angles(0, i * math.pi * 2 / 5 + r, 0) * CFrame.new(0, 0, -0.4), color, Enum.Material.Pebble)
		end
	elseif kind == 1 then
		-- Erizo
		piece(cell, Vector3.new(0.7, 0.55, 0.7), CFrame.new(at + Vector3.new(0, 0.25, 0)), rgb(40, 20, 50), Enum.Material.Pebble, Enum.PartType.Ball)
	else
		-- Conchas
		for i = 1, 3 do
			piece(cell, Vector3.new(0.4, 0.12, 0.5), CFrame.new(at + Vector3.new(hash(i, at.X, 14) * 1.5, 0.06, hash(at.Z, i, 15) * 1.5)) * angles(0, hash(i, i, 16) * 6, 0), rgb(240, 225, 200):Lerp(rgb(230, 170, 150), hash(i, at.Z, 17)), Enum.Material.SmoothPlastic)
		end
	end
end

local function treasure(cell: Cell, at: Vector3, r: number)
	if r > 0.5 then
		-- Ánfora antigua medio enterrada
		local cf = CFrame.new(at + Vector3.new(0, 0.5, 0)) * angles(math.rad(70), r * 6, 0)
		piece(cell, Vector3.new(1, 1, 1), cf, rgb(180, 100, 60), Enum.Material.Sand, Enum.PartType.Ball)
		piece(cell, Vector3.new(1.2, 0.5, 0.5), cf * CFrame.new(0, 0.7, 0) * angles(0, 0, math.rad(90)), rgb(170, 95, 55), Enum.Material.Sand, Enum.PartType.Cylinder)
	else
		-- Ancla vieja
		local cf = CFrame.new(at + Vector3.new(0, 0.2, 0)) * angles(0, r * 6, math.rad(80))
		piece(cell, Vector3.new(3, 0.3, 0.3), cf, rgb(90, 70, 60), Enum.Material.CorrodedMetal)
		piece(cell, Vector3.new(0.3, 0.3, 2), cf * CFrame.new(-1.4, 0, 0), rgb(90, 70, 60), Enum.Material.CorrodedMetal)
	end
end

local function weeds(cell: Cell, at: Vector3, r: number)
	for i = 1, 4 + floor(r * 5) do
		local a = hash(at.X, i, 18) * math.pi * 2
		local h = 1 + hash(i, at.Z, 19) * 2.5
		swaying(cell, CFrame.new(at + Vector3.new(cos(a), 0, sin(a)) * hash(at.Z, i, 20) * 1.2) * angles(0, a, 0), { h }, 0.14, rgb(80, 120, 50):Lerp(rgb(60, 90, 40), hash(i, i, 21)), 0.15, hash(i, at.X, 22))
	end
end

local function log(cell: Cell, at: Vector3, r: number)
	local len = 4 + r * 5
	piece(cell, Vector3.new(len, 0.9, 0.9), CFrame.new(at + Vector3.new(0, 0.35, 0)) * angles(0, r * 6, 0.05), rgb(80, 60, 40), Enum.Material.Wood, Enum.PartType.Cylinder)
end

local function pebbles(cell: Cell, at: Vector3, _r: number)
	for i = 1, 4 do
		local s = 0.4 + hash(i, at.X, 23) * 0.6
		piece(cell, Vector3.new(s, s * 0.6, s), CFrame.new(at + Vector3.new(hash(at.Z, i, 24) * 2 - 1, s * 0.2, hash(i, at.Z, 25) * 2 - 1)), rgb(140, 130, 115):Lerp(rgb(100, 100, 100), hash(i, i, 26)), Enum.Material.Pebble, Enum.PartType.Ball)
	end
end

-- Kelp gigante (Laberinto de Kelp): tallos de hasta 30 studs, que se mecen con la corriente
local function giantKelp(cell: Cell, at: Vector3, r: number)
	local depth = SURFACE - 2 - at.Y
	local segs = math.clamp(floor(depth / 3.4), 3, if Perf.mobile then 6 else 9)
	local heights = {}
	for i = 1, segs do
		heights[i] = 3 + hash(at.X, at.Z, i) * 0.8
	end
	local color = rgb(110, 120, 40):Lerp(rgb(70, 96, 34), r)
	swaying(cell, CFrame.new(at) * angles(0, r * 6, 0), heights, 1.4, color, 0.07, r)
	-- el ancla del tallo (la «raíz»)
	piece(cell, Vector3.new(1.4, 0.6, 1.4), CFrame.new(at + Vector3.new(0, 0.3, 0)), rgb(80, 70, 40), Enum.Material.Pebble, Enum.PartType.Ball)
end

-- Esponjas de tubo (talud y arrecife)
local SPONGE = { rgb(230, 170, 60), rgb(180, 70, 160), rgb(90, 170, 200), rgb(220, 90, 60) }
local function sponge(cell: Cell, at: Vector3, r: number)
	local color = SPONGE[1 + floor(r * 4) % 4]
	for i = 1, 3 + floor(r * 3) do
		local h = 1.2 + hash(at.X, i, 40) * 2.6
		local a = hash(i, at.Z, 41) * math.pi * 2
		piece(cell, Vector3.new(h, 0.7, 0.7), CFrame.new(at + Vector3.new(cos(a) * 0.6, h / 2, sin(a) * 0.6)) * angles(0, 0, math.rad(90)) * angles(hash(i, i, 42) * 0.3, 0, 0), color, Enum.Material.Pebble, Enum.PartType.Cylinder)
	end
end

-- Bioluminiscencia (abismo, garganta y sima): anémonas que brillan (Neon); unas pocas con luz de verdad
local GLOW = { rgb(60, 240, 255), rgb(140, 90, 255), rgb(60, 255, 170), rgb(255, 90, 210) }
local function glow(cell: Cell, at: Vector3, r: number)
	local color = GLOW[1 + floor(r * #GLOW) % #GLOW]
	local stems = 3 + floor(r * 4)
	local last: Part? = nil
	for i = 1, stems do
		local h = 0.6 + hash(at.X, i, 43) * 2.2
		local a = hash(i, at.Z, 44) * math.pi * 2
		local p = at + Vector3.new(cos(a) * 0.9, 0, sin(a) * 0.9)
		piece(cell, Vector3.new(0.25, h, 0.25), CFrame.new(p + Vector3.new(0, h / 2, 0)), rgb(30, 30, 50), Enum.Material.SmoothPlastic)
		last = piece(cell, Vector3.new(0.6, 0.6, 0.6), CFrame.new(p + Vector3.new(0, h, 0)), color, Enum.Material.Neon, Enum.PartType.Ball, 0.1)
	end
	if last and glowLights < MAX_GLOW_LIGHTS and r > 0.55 then
		glowLights += 1
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 12
		light.Brightness = 1.2
		light.Parent = last
		last:SetAttribute("GlowLight", true)
	end
end

-- Árbol de coral de luz (mar enorme): tronco blanco y ramas que se abren en tres pisos, con las puntas
-- que brillan (blanco, cian o rosa). Alto (hasta 12 studs): se ve de lejos entre la bruma.
local LIGHT_TREE = { rgb(235, 250, 255), rgb(110, 235, 255), rgb(255, 130, 215), rgb(190, 140, 255) }
local function lightTree(cell: Cell, at: Vector3, r: number)
	local tip = LIGHT_TREE[1 + floor(r * #LIGHT_TREE) % #LIGHT_TREE]
	local stem = rgb(200, 220, 230):Lerp(tip, 0.25)
	local h = 4 + r * 5
	local yaw = hash(at.X, at.Z, 50) * math.pi * 2
	local base = CFrame.new(at) * angles(0, yaw, 0)
	piece(cell, Vector3.new(h, 0.7, 0.7), base * CFrame.new(0, h / 2, 0) * angles(0, 0, math.rad(90)), stem, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	local last: Part? = nil
	local levels = if Perf.mobile then 2 else 3
	for lv = 1, levels do
		local y = h * (0.45 + 0.27 * (lv - 1))
		local len = (3.4 - lv * 0.6) * (0.8 + r * 0.6)
		for b = 1, 3 do
			local a = b * math.pi * 2 / 3 + lv * 0.9
			local branch = base * CFrame.new(0, y, 0) * angles(0, a, math.rad(48 + lv * 8)) * CFrame.new(len / 2, 0, 0)
			last = piece(cell, Vector3.new(len, 0.32, 0.32), branch, tip, Enum.Material.Neon, Enum.PartType.Cylinder, 0.05)
		end
	end
	if last and glowLights < MAX_GLOW_LIGHTS and r > 0.6 then
		glowLights += 1
		local light = Instance.new("PointLight")
		light.Color = tip
		light.Range = 14
		light.Brightness = 1.1
		light.Parent = last
		last:SetAttribute("GlowLight", true)
	end
end

-- Huesos en el fango (abismo y sima)
local function bones(cell: Cell, at: Vector3, r: number)
	for i = 1, 3 do
		piece(cell, Vector3.new(0.5, 0.5, 2 + hash(i, at.X, 45) * 3), CFrame.new(at + Vector3.new(hash(at.Z, i, 46) * 2 - 1, 0.25, hash(i, at.Z, 47) * 2 - 1)) * angles(0, hash(i, i, 48) * 6, 0.1), rgb(220, 212, 190), Enum.Material.Limestone)
	end
	if r > 0.6 then
		piece(cell, Vector3.new(2, 1.4, 2.6), CFrame.new(at + Vector3.new(0, 0.6, 0)) * angles(0.3, r * 6, 0), rgb(214, 206, 186), Enum.Material.Limestone)
	end
end

-- Fumarola: chimenea con burbujas que suben (abismo y sima)
local function vent(cell: Cell, at: Vector3, r: number)
	local h = 2 + r * 4
	local chimney = piece(cell, Vector3.new(h, 1.6, 1.6), CFrame.new(at + Vector3.new(0, h / 2, 0)) * angles(0, 0, math.rad(90)), rgb(40, 36, 40), Enum.Material.Basalt, Enum.PartType.Cylinder)
	piece(cell, Vector3.new(0.3, 0.9, 0.9), CFrame.new(at + Vector3.new(0, h + 0.1, 0)) * angles(0, 0, math.rad(90)), rgb(255, 120, 40), Enum.Material.Neon, Enum.PartType.Cylinder)
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(rgb(220, 240, 255))
	e.Rate = if Perf.mobile then 3 else 6
	e.Lifetime = NumberRange.new(3, 5)
	e.Speed = NumberRange.new(3, 6)
	e.SpreadAngle = Vector2.new(8, 8)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 0.45) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	e.EmissionDirection = Enum.NormalId.Right
	e.Parent = chimney
end

-- Por zona (OceanBiomes.Zones[z].Flora): nombre -> función
local FLORA_FN = {
	Seagrass = seagrass,
	Kelp = giantKelp,
	Coral = coral,
	Rock = rock,
	Sponge = sponge,
	Glow = glow,
	LightTree = lightTree,
	Bones = bones,
	Vent = vent,
	Urchin = critter,
	Shell = critter,
	Amphora = treasure,
}
local ZONE_ITEMS: { [string]: { any } } = {}
for id, zone in OceanBiomes.Worlds.Valmar.Zones do
	local list = {}
	for name, w in zone.Flora do
		if FLORA_FN[name] and w > 0 then
			table.insert(list, { FLORA_FN[name], w })
		end
	end
	table.sort(list, function(a, b)
		return a[2] > b[2]
	end)
	ZONE_ITEMS[id] = list
end
-- Cuántas cosas por trozo en cada zona (más en el kelp y el arrecife)
local ZONE_DENSITY = { Kelp = 4, Arrecife = 4, Abismo = 3, Sima = 3, Garganta = 3, Catedrales = 4 }

local SEA_ITEMS = { { seagrass, 38 }, { kelp, 14 }, { rock, 14 }, { coral, 16 }, { critter, 16 }, { treasure, 2 } }
local FRESH_ITEMS = { { weeds, 45 }, { rock, 25 }, { pebbles, 18 }, { log, 12 } }

local function pickItem(list: { any }, r: number): any
	local total = 0
	for _, e in list do
		total += e[2]
	end
	local x = r * total
	for _, e in list do
		x -= e[2]
		if x <= 0 then
			return e[1]
		end
	end
	return list[1][1]
end

local function buildCell(ix: number, iz: number, camY: number): Cell
	local cell: Cell = { Parts = {}, Sway = {} }
	local cx, cz = (ix + 0.5) * CELL, (iz + 0.5) * CELL
	local fresh = freshwater(cx, cz)
	local zone = if fresh then nil else Ocean.zoneAt(cx, cz)
	local list = if fresh then FRESH_ITEMS elseif zone and ZONE_ITEMS[zone] then ZONE_ITEMS[zone] else SEA_ITEMS
	local count = floor(hash(ix, iz, 1) * (if zone then ZONE_DENSITY[zone] or 3.2 else 3.2))
	-- Un fondo muy por debajo de la cámara no se ve: se deja para cuando bajes
	local probe = floorAt(cx, cz)
	if probe and camY - probe > FAR_BELOW then
		cell.Far = probe
		return cell
	end
	for j = 1, count do
		local x = (ix + hash(ix, iz, j * 2)) * CELL
		local z = (iz + hash(iz, ix, j * 2 + 1)) * CELL
		local y = floorAt(x, z)
		if y and isWater(x, z) then
			local item = pickItem(list, hash(x, z, 7))
			item(cell, Vector3.new(x, y, z), hash(z, x, 8))
		end
	end
	return cell
end

local function dropCell(key: string)
	local cell = cells[key]
	cells[key] = nil
	if not cell then
		return
	end
	for _, s in cell.Sway do
		local i = table.find(sways, s)
		if i then
			table.remove(sways, i)
		end
	end
	for _, p in cell.Parts do
		if p:GetAttribute("GlowLight") then
			glowLights = math.max(0, glowLights - 1)
		end
		p:Destroy()
	end
end

local function refreshCells(center: Vector3, camY: number)
	local built = 0
	local cx, cz = floor(center.X / CELL), floor(center.Z / CELL)
	local r = math.ceil(RADIUS / CELL)
	local wanted = {}
	-- De cerca a lejos
	for d = 0, r do
		for ix = cx - d, cx + d do
			for iz = cz - d, cz + d do
				if math.max(math.abs(ix - cx), math.abs(iz - cz)) == d then
					local key = ix .. "," .. iz
					wanted[key] = true
					local old = cells[key]
					-- (un trozo que estaba demasiado hondo para verse: ahora que has bajado, se planta)
					if old and old.Far and camY - old.Far <= FAR_BELOW and built < BUILD_PER_TICK then
						dropCell(key)
						old = nil
					end
					if not old and built < BUILD_PER_TICK then
						cells[key] = buildCell(ix, iz, camY)
						built += 1
					end
				end
			end
		end
	end
	for key in cells do
		if not wanted[key] then
			dropCell(key)
		end
	end
end

local function clearAll()
	for key in cells do
		dropCell(key)
	end
	table.clear(sways)
end

---------------------------------------------------------------------
-- Luz: rayos de sol y motas
---------------------------------------------------------------------
local rays: { Beam } = {}
local rayHolder: Part? = nil
local motes: ParticleEmitter? = nil
local plankton: ParticleEmitter? = nil
local RAY_COUNT = if Perf.mobile then 4 else 8

local function lightFx()
	if rayHolder and rayHolder.Parent then
		return
	end
	local holder = Instance.new("Part")
	holder.Name = "SeaLight"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.new(1, 1, 1)
	holder.Parent = getFolder()
	rayHolder = holder
	table.clear(rays)
	for i = 1, RAY_COUNT do
		local top = Instance.new("Attachment")
		top.Parent = holder
		local bottom = Instance.new("Attachment")
		bottom.Parent = holder
		local beam = Instance.new("Beam")
		beam.Attachment0 = top
		beam.Attachment1 = bottom
		-- (haces largos y anchos: se ven bajar desde la superficie y perderse en el azul)
		beam.Width0 = 5 + (i % 3) * 2
		beam.Width1 = 10 + (i % 2) * 5
		beam.Color = ColorSequence.new(rgb(200, 245, 255))
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.82), NumberSequenceKeypoint.new(1, 1) })
		beam.FaceCamera = true
		beam.Segments = 1
		beam.Parent = holder
		beam:SetAttribute("Seed", i)
		table.insert(rays, beam)
	end
	local e = Instance.new("ParticleEmitter")
	e.Name = "SeaMotes"
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(rgb(220, 240, 230))
	e.Rate = if Perf.mobile then 8 else 16
	e.Lifetime = NumberRange.new(4, 7)
	e.Speed = NumberRange.new(0.1, 0.4)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new(0.07)
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.5), NumberSequenceKeypoint.new(1, 1) })
	e.LightEmission = 0.4
	e.Enabled = false
	e.Parent = holder
	motes = e
	-- Plancton que brilla (cian, violeta y rosa): abajo, donde manda la bioluminiscencia
	local pk = Instance.new("ParticleEmitter")
	pk.Name = "SeaPlankton"
	pk.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pk.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, rgb(90, 240, 255)),
		ColorSequenceKeypoint.new(0.5, rgb(180, 120, 255)),
		ColorSequenceKeypoint.new(1, rgb(255, 120, 210)),
	})
	pk.LightEmission = 1
	pk.LightInfluence = 0
	pk.Rate = 0
	pk.Lifetime = NumberRange.new(5, 9)
	pk.Speed = NumberRange.new(0.2, 0.8)
	pk.SpreadAngle = Vector2.new(180, 180)
	pk.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.5, 0.18), NumberSequenceKeypoint.new(1, 0.05) })
	pk.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.2), NumberSequenceKeypoint.new(1, 1) })
	pk.Enabled = false
	pk.Parent = holder
	plankton = pk
end

local function updateLight(camera: Camera, t: number)
	local holder = rayHolder
	if not holder then
		return
	end
	local cam = camera.CFrame.Position
	holder.CFrame = CFrame.new(cam + camera.CFrame.LookVector * 6)
	local day = GameClock.darkness() < 0.5 -- (shared/DayCycle)
	for _, beam in rays do
		local i = beam:GetAttribute("Seed") or 1
		local a = i * 1.9 + t * 0.03
		local x = cos(a) * (8 + i * 5)
		local z = sin(a) * (8 + i * 5)
		local top = beam.Attachment0 :: Attachment
		local bottom = beam.Attachment1 :: Attachment
		-- (inclinados como el sol y largos: hasta 40 studs bajo la superficie)
		top.WorldPosition = Vector3.new(cam.X + x, SURFACE - 0.3, cam.Z + z)
		bottom.WorldPosition = Vector3.new(cam.X + x + 9, SURFACE - 30 - (i % 3) * 5, cam.Z + z + 4)
		-- (los rayos de sol solo llegan cerca de la superficie: OceanBiomes.Depth.RaysDepth)
		local rays = if look then look.Rays or 1 else 1
		beam.Enabled = day and under > 0.5 and rays > 0.05
		local flicker = 0.76 + 0.08 * sin(t * 1.7 + i * 2)
		beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1 - (1 - flicker) * rays), NumberSequenceKeypoint.new(1, 1) })
	end
	if motes then
		motes.Enabled = under > 0.5
		-- Más hondo, «nieve marina»: más motas, blancas, que caen despacio
		local snow = if look then look.Snow or 0.3 else 0.3
		local rate = (if Perf.mobile then 8 else 16) * (0.6 + snow * 1.4)
		if math.abs(motes.Rate - rate) > 0.5 then
			motes.Rate = rate
			motes.Acceleration = Vector3.new(0, -0.15 * snow, 0)
			motes.Color = ColorSequence.new(rgb(220, 240, 230):Lerp(rgb(245, 248, 255), snow))
		end
	end
	if plankton then
		local glowAmount = if look then look.Glow or 0 else 0
		plankton.Enabled = under > 0.5 and glowAmount > 0.05
		local rate = (if Perf.mobile then 6 else 14) * glowAmount
		if math.abs(plankton.Rate - rate) > 0.5 then
			plankton.Rate = rate
		end
	end
end

-- La zona y la profundidad de la cámara, y la luz del agua yendo hacia la de la zona (shared/Sea)
local function lerpLook(a: { [string]: any }, b: { [string]: any }, k: number): { [string]: any }
	local out = {}
	for key, v in b do
		local cur = a[key]
		if typeof(v) == "Color3" and typeof(cur) == "Color3" then
			out[key] = cur:Lerp(v, k)
		elseif type(v) == "number" and type(cur) == "number" then
			out[key] = cur + (v - cur) * k
		else
			out[key] = v
		end
	end
	return out
end

local nextSample = 0
local target: { [string]: any }? = nil
local function updateSea(camPos: Vector3, t: number, dt: number)
	if t >= nextSample then
		nextSample = t + 0.4
		local fresh = freshwater(camPos.X, camPos.Z)
		local zone = if fresh then nil else Ocean.zoneAt(camPos.X, camPos.Z)
		here.Zone = zone
		here.Sea = zone ~= nil
		here.Meters = Ocean.meters(camPos.Y)
		target = if zone then OceanBiomes.look(zone, here.Meters) else nil
	end
	local want = target
	if not want then
		look = nil
		return
	end
	look = if look then lerpLook(look, want, math.min(1, dt * 1.5)) else want
	-- El color del agua del terreno (solo en tu pantalla)
	pcall(function()
		local terrain = workspace.Terrain
		if not baseWaterColor then
			baseWaterColor = terrain.WaterColor
		end
		local color = (baseWaterColor :: Color3):Lerp((look :: any).Water, math.clamp(under, 0, 1))
		if (Vector3.new(color.R, color.G, color.B) - Vector3.new(terrain.WaterColor.R, terrain.WaterColor.G, terrain.WaterColor.B)).Magnitude > 0.01 then
			terrain.WaterColor = color
		end
	end)
end

-- Dónde estás en el mar (para el HUD de buceo): zona, profundidad (m) y si es el mar
function SeaBiome.state(): { Zone: string?, Meters: number, Sea: boolean, Under: number }
	return { Zone = here.Zone, Meters = here.Meters, Sea = here.Sea, Under = under }
end

---------------------------------------------------------------------

local function swayAll(t: number, me: Vector3)
	for _, s in sways do
		local first = s.Parts[1]
		if first and (first.Position - me).Magnitude < SWAY_DISTANCE then
			local cur = s.Base
			for i, p in s.Parts do
				local h = s.Heights[i]
				cur = cur * angles(sin(t * 1.1 + s.Phase + i * 0.6) * s.Amount, 0, cos(t * 0.8 + s.Phase) * s.Amount * 0.6)
				p.CFrame = cur * CFrame.new(0, h / 2, 0)
				cur = cur * CFrame.new(0, h, 0)
			end
		end
	end
end

local function setWaterLook(k: number)
	local terrain = workspace.Terrain
	if not defaults then
		defaults = { Reflectance = terrain.WaterReflectance, Transparency = terrain.WaterTransparency }
	end
	local d = defaults :: { Reflectance: number, Transparency: number }
	-- En el agua: la superficie deja ver lo de abajo (y a quien bucea)
	terrain.WaterReflectance = d.Reflectance + (0.12 - d.Reflectance) * k
	terrain.WaterTransparency = d.Transparency + (0.72 - d.Transparency) * k
end

function SeaBiome.init()
	local lastRefresh = 0
	local waterCheck = 0
	local inWater = false
	local lastLook = 0
	RunService.RenderStepped:Connect(function(dt)
		local ok, err = pcall(function()
			local t = os.clock()
			local camera = workspace.CurrentCamera
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local camPos = camera.CFrame.Position
			-- ¿Estás en el agua? (el cuerpo bajo la superficie con agua debajo; se mira a veces)
			if t - waterCheck > 0.3 then
				waterCheck = t
				local near = root and root.Position.Y < SURFACE + 0.6 and wetAt(root.Position)
				local camUnder = camPos.Y < SURFACE - 0.2 and wetAt(camPos)
				inWater = near == true or camUnder
			end
			local camUnder = camPos.Y < SURFACE - 0.2 and inWater
			under += ((if camUnder then 1 else 0) - under) * math.min(1, dt * 4)
			-- (la luz bajo el agua la pinta la zona «Submarino»: EnvDirector es su único dueño)
			EnvDirector.setSea(under, if under > 0.01 then look else nil)
			waterLook += ((if inWater then 1 else 0) - waterLook) * math.min(1, dt * 2)
			local wl = if waterLook < 0.002 then 0 elseif waterLook > 0.998 then 1 else waterLook
			if math.abs(wl - lastLook) > 0.002 or (wl ~= lastLook and (wl == 0 or wl == 1)) then
				lastLook = wl
				setWaterLook(wl)
			end
			if inWater then
				leftAt = t
				if not active then
					active = true
					lightFx()
				end
			elseif active and t - leftAt > 8 then
				active = false
				clearAll()
				if rayHolder then
					rayHolder:Destroy()
					rayHolder = nil
				end
				motes = nil
				plankton = nil
				-- la luz y el color del agua de siempre
				look, target = nil, nil
				EnvDirector.setSea(nil)
				if baseWaterColor then
					pcall(function()
						workspace.Terrain.WaterColor = baseWaterColor :: Color3
					end)
				end
			end
			if not active then
				return
			end
			local center = if root then root.Position else camPos
			if t - lastRefresh > 0.3 then
				lastRefresh = t
				refreshCells(center, camPos.Y)
			end
			swayAll(t, camPos)
			updateSea(camPos, t, dt)
			updateLight(camera, t)
		end)
		if not ok then
			warn("[SeaBiome] " .. tostring(err))
		end
	end)
end

return SeaBiome
