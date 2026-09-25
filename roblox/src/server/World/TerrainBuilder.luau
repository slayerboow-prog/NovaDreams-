-- TerrainBuilder: sustituye el suelo de piezas por terreno real de Roblox
-- (hierba con textura y colinas en el horizonte). Se ejecuta al arrancar el servidor,
-- porque el terreno no se puede guardar desde el script que genera el archivo.

local TerrainBuilder = {}

local CityPlan = require(game:GetService("ReplicatedStorage").Shared.CityPlan)

local BEACH = 70 -- ancho de la playa en la costa

-- Rellena un rectángulo grande en trozos (el terreno prefiere regiones no gigantes)
local function tiles(terrain: Terrain, x0: number, x1: number, z0: number, z1: number, y0: number, y1: number, material: Enum.Material)
	local step = 1024
	for x = x0, x1 - 1, step do
		for z = z0, z1 - 1, step do
			local w, d = math.min(step, x1 - x), math.min(step, z1 - z)
			terrain:FillBlock(CFrame.new(x + w / 2, (y0 + y1) / 2, z + d / 2), Vector3.new(w, y1 - y0, d), material)
		end
	end
end

-- Banda recta entre dos puntos (para el cauce del río)
local function band(terrain: Terrain, a: { number }, b: { number }, width: number, y0: number, y1: number, material: Enum.Material)
	local pa, pb = Vector3.new(a[1], 0, a[2]), Vector3.new(b[1], 0, b[2])
	local mid, dir = (pa + pb) / 2, (pb - pa)
	local cf = CFrame.lookAt(Vector3.new(mid.X, (y0 + y1) / 2, mid.Z), Vector3.new(pb.X, (y0 + y1) / 2, pb.Z) + Vector3.new(0.001, 0, 0.001))
	terrain:FillBlock(cf, Vector3.new(width, y1 - y0, dir.Magnitude + width), material)
end

local function cylinder(terrain: Terrain, x: number, z: number, radius: number, y0: number, y1: number, material: Enum.Material)
	terrain:FillCylinder(CFrame.new(x, (y0 + y1) / 2, z), y1 - y0, radius, material)
end

function TerrainBuilder.build()
	local terrain = workspace.Terrain
	-- Sin briznas de hierba: atravesarían las calles y los suelos.
	-- (Desde un script no siempre se puede cambiar: por eso también va en default.project.json.)
	pcall(function()
		terrain.Decoration = false
	end)
	terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(98, 146, 70))
	terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(128, 122, 112))
	terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(226, 206, 160))
	terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(96, 126, 66))
	local b = CityPlan.Bounds

	-- 1) Mar alrededor de toda la isla (fondo de arena)
	tiles(terrain, b.MinX - 800, b.MaxX + 800, b.MinZ - 800, b.MaxZ + 800, -24, -14, Enum.Material.Sand)
	tiles(terrain, b.MinX - 800, b.MaxX + 800, b.MinZ - 800, b.MaxZ + 800, -14, -2, Enum.Material.Water)

	-- 2) La isla: arena en la orilla y hierba dentro. La superficie queda en Y = -1, un poco por DEBAJO
	--    de las calles (que empiezan en Y = 0): si quedara en 0, el césped asomaría entre las piezas.
	local stripe = 16
	for z = b.MinZ, b.MaxZ, stripe do
		for _, span in CityPlan.spans(CityPlan.Coast, z + stripe / 2) do
			local x0, x1 = span[1], span[2]
			terrain:FillBlock(CFrame.new((x0 + x1) / 2, -9, z + stripe / 2), Vector3.new(x1 - x0, 16, stripe), Enum.Material.Sand)
			if x1 - x0 > BEACH * 2 then
				terrain:FillBlock(CFrame.new((x0 + x1) / 2, -5, z + stripe / 2), Vector3.new(x1 - x0 - BEACH * 2, 8, stripe), Enum.Material.Grass)
			end
		end
	end
	-- Islas pequeñas (la del faro, el islote y la de las gaviotas)
	for _, island in CityPlan.Islands do
		cylinder(terrain, island.X, island.Z, island.R, -16, -1, Enum.Material.Sand)
		cylinder(terrain, island.X, island.Z, island.R - 30, -9, -1, Enum.Material.Grass)
	end

	-- 3) Montañas y colinas (con roca en las cumbres altas)
	for _, m in CityPlan.Mountains do
		terrain:FillBall(Vector3.new(m.X, m.H - m.R, m.Z), m.R, Enum.Material.Grass)
		if m.Rock then
			local r = m.R * 0.42
			terrain:FillBall(Vector3.new(m.X, m.H - r * 0.9, m.Z), r, Enum.Material.Rock)
		end
	end

	-- 4) Río: orillas de arena, cauce y agua (queda a Y = -2, dos studs bajo la orilla)
	local river = CityPlan.River
	local pts = river.Points
	for i = 1, #pts - 1 do
		band(terrain, pts[i], pts[i + 1], river.Width + 40, -9, -1, Enum.Material.Sand)
	end
	for i = 1, #pts - 1 do
		band(terrain, pts[i], pts[i + 1], river.Width, -16, 30, Enum.Material.Air)
	end
	for i = 1, #pts - 1 do
		band(terrain, pts[i], pts[i + 1], river.Width, -24, -16, Enum.Material.Sand)
		band(terrain, pts[i], pts[i + 1], river.Width, -16, -2, Enum.Material.Water)
	end

	-- 5) Lagos
	for _, lake in CityPlan.Lakes do
		cylinder(terrain, lake.X, lake.Z, lake.R + 24, -9, -1, Enum.Material.Sand)
		cylinder(terrain, lake.X, lake.Z, lake.R, -16, 20, Enum.Material.Air)
		cylinder(terrain, lake.X, lake.Z, lake.R, -24, -16, Enum.Material.Sand)
		cylinder(terrain, lake.X, lake.Z, lake.R, -16, -2, Enum.Material.Water)
	end

	-- 6) Colina del mirador (Landmarks)
	require(script.Parent.Kit.Landmarks).terrain(terrain)

	-- 7) Debajo de cada manzana (casas, colegios, tiendas…) el terreno se hunde hasta Y = -4.
	-- El terreno de Roblox va en cubos de 4 studs y su superficie no es exacta: con la cara de arriba
	-- en -1, sus triángulos llegaban a asomar por los suelos (césped dentro de casa).
	-- Con -4 (borde exacto de un cubo) queda plano y 4 studs por debajo; las losas de césped lo tapan.
	local Region = require(script.Parent.Region)
	local sunken = Region.blockRects()
	table.insert(sunken, { X0 = -360, X1 = 360, Z0 = -198, Z1 = -20 }) -- Valmar Centro (norte de la avenida)
	table.insert(sunken, { X0 = -360, X1 = 360, Z0 = 20, Z1 = 240 }) -- Valmar Centro (sur: parcelas de casas)
	for _, r in sunken do
		local size = Vector3.new(r.X1 - r.X0, 16, r.Z1 - r.Z0)
		terrain:FillBlock(CFrame.new((r.X0 + r.X1) / 2, 4, (r.Z0 + r.Z1) / 2), size, Enum.Material.Air)
	end
end

-- Quita el suelo y el mar de piezas (solo servían para verlo en Studio)
function TerrainBuilder.removeGroundPart()
	local CollectionService = game:GetService("CollectionService")
	for _, part in CollectionService:GetTagged("EditOnly") do
		part:Destroy()
	end
end

return TerrainBuilder
