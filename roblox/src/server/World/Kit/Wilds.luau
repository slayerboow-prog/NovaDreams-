-- Wilds: la naturaleza de Valmar (fase 9 del plano).
--   * Bosques en las laderas de las montañas (los árboles se apoyan en la ladera: se calcula su altura)
--   * Árboles en las dos orillas del río
--   * Parque natural alrededor del lago: sendero de tierra, mesas de pícnic, bancos y bosque
--   * Playas: palmeras, sombrillas y toallas a lo largo de la costa
-- Nada se pone encima de calles, manzanas ni barrios.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Builder = require(script.Parent.Parent.Builder)
local Nature = require(script.Parent.Nature)
local Props = require(script.Parent.Props)
local CityPlan = require(ReplicatedStorage.Shared.CityPlan)

local Wilds = {}

local rgb = Color3.fromRGB

-- ¿Hay algo construido aquí? (calles, manzanas, barrios, puerto…) Lo decide quien llama (TownBuilder)
export type Blocked = (x: number, z: number) -> boolean

-- Altura del terreno sobre una montaña (esfera de CityPlan.Mountains) o -1 en el llano
local function groundY(x: number, z: number): number
	local y = -1
	for _, m in CityPlan.Mountains do
		local d2 = (x - m.X) ^ 2 + (z - m.Z) ^ 2
		if d2 < m.R * m.R then
			y = math.max(y, (m.H - m.R) + math.sqrt(m.R * m.R - d2))
		end
	end
	return y
end

local function onMountainRock(x: number, z: number): boolean
	for _, m in CityPlan.Mountains do
		if m.Rock then
			local r = m.R * 0.42
			local ground = math.sqrt(math.max(0, r * r - (r * 0.9) ^ 2)) + 20
			if math.sqrt((x - m.X) ^ 2 + (z - m.Z) ^ 2) < ground + 60 then
				return true -- cumbre de roca: sin árboles
			end
		end
	end
	return false
end

local function water(x: number, z: number, margin: number): boolean
	if CityPlan.riverDistance(x, z) < CityPlan.River.Width / 2 + margin then
		return true
	end
	for _, lake in CityPlan.Lakes do
		if math.sqrt((x - lake.X) ^ 2 + (z - lake.Z) ^ 2) < lake.R + margin then
			return true
		end
	end
	return false
end

local function tree(parent: Instance, x: number, z: number, y: number)
	local r = math.random()
	if r < 0.35 then
		Nature.cypress(parent, Vector3.new(x, y, z))
	else
		Nature.tree(parent, Vector3.new(x, y, z), 0.9 + math.random() * 0.8)
	end
end

-- Bosques de montaña
local function mountainForests(folder: Instance, blocked: Blocked)
	for _, m in CityPlan.Mountains do
		local ground = math.sqrt(math.max(0, m.R * m.R - (m.R - m.H) ^ 2))
		local count = math.floor(ground / 4.5)
		for _ = 1, count do
			local a = math.random() * math.pi * 2
			local r = math.sqrt(math.random()) * ground * 0.92
			local x, z = m.X + math.cos(a) * r, m.Z + math.sin(a) * r
			if CityPlan.inside(CityPlan.Coast, x, z) and not onMountainRock(x, z) and not water(x, z, 20) and not blocked(x, z) then
				tree(folder, x, z, groundY(x, z) - 1.5)
			end
		end
	end
end

-- Orillas del río
local function riverBanks(folder: Instance, blocked: Blocked)
	local pts = CityPlan.River.Points
	local W = CityPlan.River.Width
	for i = 1, #pts - 1 do
		local a, b = Vector3.new(pts[i][1], 0, pts[i][2]), Vector3.new(pts[i + 1][1], 0, pts[i + 1][2])
		local dir = (b - a).Unit
		local perp = Vector3.new(-dir.Z, 0, dir.X)
		local len = (b - a).Magnitude
		for d = 20, len, 38 do
			for _, side in { -1, 1 } do
				local p = a + dir * (d + math.random(-8, 8)) + perp * side * (W / 2 + 34 + math.random(0, 20))
				if CityPlan.inside(CityPlan.Coast, p.X, p.Z) and not water(p.X, p.Z, 10) and not blocked(p.X, p.Z) and groundY(p.X, p.Z) < 0 then
					tree(folder, p.X, p.Z, -1)
				end
			end
		end
	end
end

-- Parque natural del lago: sendero, pícnic y bosque
local function lakePark(folder: Instance, blocked: Blocked)
	local m = Builder.model("ParqueNatural", folder)
	for _, lake in CityPlan.Lakes do
		local ring = lake.R + 55
		local segments = 28
		for i = 0, segments - 1 do
			local a0, a1 = i / segments * math.pi * 2, (i + 1) / segments * math.pi * 2
			local p0 = Vector3.new(lake.X + math.cos(a0) * ring, -0.9, lake.Z + math.sin(a0) * ring)
			local p1 = Vector3.new(lake.X + math.cos(a1) * ring, -0.9, lake.Z + math.sin(a1) * ring)
			local mid = (p0 + p1) / 2
			if not blocked(mid.X, mid.Z) and groundY(mid.X, mid.Z) < 2 then
				Builder.decor({ Name = "Trail", Size = Vector3.new(6, 0.3, (p1 - p0).Magnitude + 2), CFrame = Builder.facing(mid, p1 - p0), Color = rgb(170, 140, 100), Material = Enum.Material.Ground, Parent = m })
				if i % 3 == 0 then
					-- Mesa de pícnic junto al sendero (hacia fuera)
					local out = (mid - Vector3.new(lake.X, -0.9, lake.Z)).Unit
					local t = mid + out * 12 + Vector3.new(0, 0.9, 0)
					local cf = Builder.facing(t, p1 - p0)
					Builder.part({ Name = "PicnicTable", Size = Vector3.new(8, 0.5, 3.2), CFrame = cf * CFrame.new(0, 2.6, 0), Color = rgb(150, 110, 76), Material = Enum.Material.WoodPlanks, Parent = m })
					for _, z in { -2.6, 2.6 } do
						Builder.part({ Name = "PicnicBench", Size = Vector3.new(8, 0.4, 1.2), CFrame = cf * CFrame.new(0, 1.6, z), Color = rgb(150, 110, 76), Material = Enum.Material.WoodPlanks, Parent = m })
					end
				elseif i % 3 == 1 then
					Props.bench(m, Builder.facing(mid + Vector3.new(0, 0.9, 0) + (Vector3.new(lake.X, 0, lake.Z) - Vector3.new(mid.X, 0, mid.Z)).Unit * 5, Vector3.new(lake.X, 0, lake.Z) - Vector3.new(mid.X, 0, mid.Z)))
				end
			end
		end
		-- Bosque alrededor
		for _ = 1, math.floor(lake.R / 2) do
			local a = math.random() * math.pi * 2
			local r = ring + 20 + math.random() * 140
			local x, z = lake.X + math.cos(a) * r, lake.Z + math.sin(a) * r
			if CityPlan.inside(CityPlan.Coast, x, z) and not blocked(x, z) and not water(x, z, 20) then
				tree(folder, x, z, groundY(x, z) - 1.5)
			end
		end
	end
end

-- Playas: palmeras, sombrillas y toallas en la franja de arena
local UMBRELLAS = { rgb(230, 70, 70), rgb(250, 200, 60), rgb(60, 140, 220), rgb(90, 190, 120), rgb(250, 250, 250) }
local function beaches(folder: Instance, blocked: Blocked)
	local m = Builder.model("Playas", folder)
	local b = CityPlan.Bounds
	local cliffs = {}
	for _, c in CityPlan.Cliffs do
		for k = c[1], c[2] do
			cliffs[k] = true
		end
	end
	for z = b.MinZ, b.MaxZ, 90 do
		for _, span in CityPlan.spans(CityPlan.Coast, z) do
			for _, edge in { { span[1], 1 }, { span[2], -1 } } do
				local x = edge[1] + edge[2] * 32
				if not blocked(x, z) and groundY(x, z) < 0 and z > -2600 then
					if math.random() < 0.5 then
						Nature.palm(m, Vector3.new(x + edge[2] * 18, -1, z + math.random(-20, 20)))
					end
					if math.random() < 0.6 then
						local cf = CFrame.new(x, -1, z + math.random(-25, 25))
						Builder.decor({ Name = "UmbrellaPole", Size = Vector3.new(0.3, 8, 0.3), CFrame = cf * CFrame.new(0, 4, 0), Color = rgb(240, 240, 240), Parent = m })
						Builder.decor({ Name = "Umbrella", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 9, 9), CFrame = cf * CFrame.new(0, 8, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = UMBRELLAS[math.random(1, #UMBRELLAS)], Material = Enum.Material.Fabric, Parent = m })
						Builder.decor({ Name = "Towel", Size = Vector3.new(3, 0.1, 6), CFrame = cf * CFrame.new(3, 0.1, 1), Color = UMBRELLAS[math.random(1, #UMBRELLAS)], Material = Enum.Material.Fabric, Parent = m })
					end
				end
			end
		end
	end
end

function Wilds.build(world: Instance, blocked: Blocked)
	local folder = Builder.model("Naturaleza", world)
	mountainForests(folder, blocked)
	riverBanks(folder, blocked)
	lakePark(folder, blocked)
	beaches(folder, blocked)
	return folder
end

return Wilds
