-- OceanBuilder: construye el mar hondo de Valmar al arrancar (después de TerrainBuilder, en su hilo y
-- poco a poco para no trabar el servidor). docs/mar/diseno.md.
--
--   1. Terreno: el fondo de shared/Sea/Ocean (plataforma, talud, llanura, Abismo Silente, Sima del
--      Kraken y Garganta Negra). Por bandas de 8 filas de 16 studs: primero el agua de la banda en
--      baldosas (Ocean.planWater) y luego el fondo de cada fila (Ocean.planRow). Solo toca el mar
--      a más de 60 studs de tierra y fuera de puertos e islas: la ciudad no cambia.
--   2. Relieve: rocas sueltas y crestas por el talud y el abismo, el Arco de Coral, el Puente de Piedra
--      sobre la garganta, la cueva de la Bolsa de Aire y la Guarida del Kraken (excavada en una mole de
--      roca en la pared de la sima).
--   3. Piezas de los sitios (POI): pecio, ruinas, batiscafo, esqueleto de ballena, jardines, cofres y
--      la bolsa de aire. Cada sitio es un modelo Atomic (StreamingEnabled: llega entero cuando te
--      acercas) dentro de workspace.Mar. Presupuesto: OceanBuilder.Budget piezas en total.
--
-- Etiquetas para Services/OceanService: SeaChest (cofre: atributos PoiId y ChestId), SeaAirPocket
-- (bolsa de aire: atributo Radius). OceanBuilder.State: "None" | "Building" | "Ready" (atributo
-- OceanReady de workspace cuando acaba). Para un planeta: OceanBuilder.build(worldId) (hoy solo Valmar).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ocean = require(ReplicatedStorage.Shared.Sea.Ocean)

local OceanBuilder = {}

OceanBuilder.State = "None"
OceanBuilder.Budget = 900 -- piezas como mucho en todos los sitios
OceanBuilder.Band = 8 -- filas por banda (una espera entre bandas)
OceanBuilder.WaterTile = 128
OceanBuilder.Stats = { Fills = 0, Parts = 0, Seconds = 0 }

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local rad = math.rad

local MATERIALS = {
	Sand = Enum.Material.Sand,
	Mud = Enum.Material.Mud,
	Rock = Enum.Material.Rock,
	Basalt = Enum.Material.Basalt,
	Water = Enum.Material.Water,
}

local parts = 0

local function folder(): Folder
	local f = workspace:FindFirstChild("Mar")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Mar"
		f.Parent = workspace
	end
	return f :: Folder
end

local function model(name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	pcall(function()
		(m :: any).ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	pcall(function()
		(m :: any).LevelOfDetail = Enum.ModelLevelOfDetail.StreamingMesh
	end)
	m.Parent = folder()
	return m
end

type PartSpec = { Size: Vector3, CFrame: CFrame, Color: Color3, Material: Enum.Material?, Shape: Enum.PartType?, Collide: boolean?, Transparency: number?, Name: string?, Class: string? }
local function part(parent: Instance, s: PartSpec): BasePart?
	if parts >= OceanBuilder.Budget then
		return nil
	end
	parts += 1
	local p = Instance.new(s.Class or "Part") :: Part
	p.Name = s.Name or "Pieza"
	p.Anchored = true
	p.Size = s.Size
	p.CFrame = s.CFrame
	p.Color = s.Color
	p.Material = s.Material or Enum.Material.SmoothPlastic
	if s.Shape and p:IsA("Part") then
		p.Shape = s.Shape
	end
	p.CanCollide = s.Collide == true
	p.CanTouch = false
	p.CanQuery = s.Collide == true
	p.CastShadow = false
	p.Transparency = s.Transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function floorAt(x: number, z: number): number
	return Ocean.floorY(x, z) or Ocean.CoastY
end

---------------------------------------------------------------------
-- 1. Terreno
---------------------------------------------------------------------
local function fill(terrain: Terrain, b: { [string]: any }, z0: number, z1: number)
	local h = b.Y1 - b.Y0
	if h <= 0.05 then
		return
	end
	terrain:FillBlock(CF((b.X0 + b.X1) / 2, (b.Y0 + b.Y1) / 2, (z0 + z1) / 2), V(b.X1 - b.X0, h, z1 - z0), MATERIALS[b.Material] or Enum.Material.Sand)
	OceanBuilder.Stats.Fills += 1
end

function OceanBuilder.terrain(terrain: Terrain, yield: (() -> ())?)
	pcall(function()
		terrain:SetMaterialColor(Enum.Material.Mud, rgb(74, 70, 58)) -- fango del kelp y del abismo
	end)
	local cell = Ocean.Cell
	local rows = Ocean.rows(cell)
	local minZ = Ocean.Area.MinZ
	local cache: { [number]: any } = {}
	local function row(r: number): any
		if r < 0 or r >= rows then
			return nil
		end
		local got = cache[r]
		if not got then
			got = Ocean.rowFloors(minZ + r * cell, cell)
			cache[r] = got
		end
		return got
	end
	local band = OceanBuilder.Band
	for r0 = 0, rows - 1, band do
		local list = {}
		local last = math.min(rows - 1, r0 + band - 1)
		for r = r0, last do
			table.insert(list, row(r))
		end
		local z0 = minZ + r0 * cell
		local z1 = minZ + (last + 1) * cell
		for _, b in Ocean.planWater(z0, z1, list, cell, OceanBuilder.WaterTile) do
			fill(terrain, b, b.Z0, b.Z1)
		end
		for r = r0, last do
			local zr = minZ + r * cell
			for _, b in Ocean.planRow(zr, cell, row(r - 1), row(r), row(r + 1)) do
				fill(terrain, b, zr, zr + cell)
			end
		end
		-- (las filas que ya no hacen falta)
		for r in cache do
			if r < r0 - 1 then
				cache[r] = nil
			end
		end
		if yield then
			yield()
		end
	end
end

---------------------------------------------------------------------
-- 2. Relieve
---------------------------------------------------------------------
-- Arco de roca: segmentos de un semicírculo (centro en el suelo, mirando a `facing`)
local function arch(terrain: Terrain, base: Vector3, facing: Vector3, radius: number, thick: number, material: Enum.Material)
	local right = V(-facing.Z, 0, facing.X).Unit
	local n = 11
	for i = 0, n do
		local a = math.pi * i / n
		local p = base + right * math.cos(a) * radius + V(0, math.sin(a) * radius, 0)
		terrain:FillBall(p, thick, material)
		OceanBuilder.Stats.Fills += 1
	end
	-- patas
	terrain:FillBall(base + right * radius - V(0, thick * 0.6, 0), thick * 1.3, material)
	terrain:FillBall(base - right * radius - V(0, thick * 0.6, 0), thick * 1.3, material)
end

local function rocks(terrain: Terrain, yield: (() -> ())?)
	-- Rocas sueltas y peñascos en el talud, la llanura y el abismo (siempre en el mismo sitio)
	local a = Ocean.Area
	local n = 0
	for i = 1, 420 do
		local x = a.MinX + Ocean.hash(i, 3, 11) * (a.MaxX - a.MinX)
		local z = a.MinZ + Ocean.hash(i, 5, 12) * (a.MaxZ - a.MinZ)
		local s = Ocean.sample(x, z)
		if s.Floor and s.Floor < -40 and s.Keep < 0.05 and s.Trench < 0.05 then
			local r = 4 + Ocean.hash(i, 7, 13) * (if s.Zone == "Talud" then 14 else 9)
			local mat = if s.Zone == "Abismo" or s.Zone == "Garganta" then Enum.Material.Basalt else Enum.Material.Rock
			terrain:FillBall(V(x, s.Floor + r * 0.25, z), r, mat)
			if r > 10 then
				terrain:FillBall(V(x + r * 0.8, s.Floor + r * 0.1, z - r * 0.4), r * 0.6, mat)
			end
			n += 1
			OceanBuilder.Stats.Fills += 2
			if n % 40 == 0 and yield then
				yield()
			end
		end
	end
	-- Chimeneas (fumarolas) en la sima: columnas de basalto
	local tr = Ocean.Trench
	for i = 1, 14 do
		local k = (i - 0.5) / 14
		local seg = math.clamp(math.floor(k * (#tr.Points - 1)) + 1, 1, #tr.Points - 1)
		local p0, p1 = tr.Points[seg], tr.Points[seg + 1]
		local t = k * (#tr.Points - 1) - (seg - 1)
		local x = p0[1] + (p1[1] - p0[1]) * t + (Ocean.hash(i, 1, 14) - 0.5) * 50
		local z = p0[2] + (p1[2] - p0[2]) * t + (Ocean.hash(i, 2, 14) - 0.5) * 50
		local y = floorAt(x, z)
		local h = 12 + Ocean.hash(i, 3, 14) * 26
		terrain:FillCylinder(CF(x, y + h / 2, z), h, 3 + Ocean.hash(i, 4, 14) * 3, Enum.Material.Basalt)
		OceanBuilder.Stats.Fills += 1
	end
end

-- La Guarida del Kraken: mole de roca en la pared norte de la sima y la cueva excavada dentro
function OceanBuilder.lairCave(terrain: Terrain)
	local L = Ocean.Lair
	local center = V(L.X, L.Y, L.Z)
	terrain:FillBall(center + V(0, 10, -40), 100, Enum.Material.Basalt)
	terrain:FillBall(center, L.Radius, Enum.Material.Water)
	-- túnel hacia el centro de la sima (al sur)
	local mouth = V(L.X, L.Y - 6, L.Z + 95)
	local mid = (center + mouth) / 2
	terrain:FillCylinder(CFrame.lookAt(mid, mouth) * ANG(rad(90), 0, 0), (mouth - center).Magnitude, 16, Enum.Material.Water)
	OceanBuilder.Stats.Fills += 3
end

-- La cueva de la Bolsa de Aire: un montículo con una sala dentro y dos bocas
local function airCave(terrain: Terrain): Vector3
	local poi = Ocean.PoiById.BolsaAire
	local y = floorAt(poi.X, poi.Z)
	local c = V(poi.X, y + 8, poi.Z)
	terrain:FillBall(c + V(0, 4, 0), 34, Enum.Material.Rock)
	terrain:FillBall(c, 19, Enum.Material.Water)
	for _, dir in { V(1, 0, 0.2), V(-0.6, 0, -1) } do
		local mouth = c + dir.Unit * 40 - V(0, 3, 0)
		terrain:FillCylinder(CFrame.lookAt((c + mouth) / 2, mouth) * ANG(rad(90), 0, 0), 40, 7, Enum.Material.Water)
	end
	OceanBuilder.Stats.Fills += 5
	return c
end

local function relief(terrain: Terrain, yield: (() -> ())?)
	rocks(terrain, yield)
	-- Arco de Coral (arrecife)
	local arco = Ocean.PoiById.ArcoCoral
	arch(terrain, V(arco.X, floorAt(arco.X, arco.Z) - 2, arco.Z), V(1, 0, 0.3).Unit, 18, 5, Enum.Material.Rock)
	-- Puente de Piedra sobre la Garganta Negra (de una pared a la otra)
	local puente = Ocean.PoiById.PuenteGarganta
	local _, _, seg = Ocean.along(Ocean.Canyon, puente.X, puente.Z)
	local a, b = Ocean.Canyon.Points[seg], Ocean.Canyon.Points[seg + 1]
	local along = V(b[1] - a[1], 0, b[2] - a[2]).Unit
	arch(terrain, V(puente.X, floorAt(puente.X, puente.Z) + 4, puente.Z), along, 58, 7, Enum.Material.Basalt)
	if yield then
		yield()
	end
	OceanBuilder.lairCave(terrain)
	airCave(terrain)
end

---------------------------------------------------------------------
-- 3. Piezas de los sitios
---------------------------------------------------------------------
local WOOD, DARK_WOOD = rgb(92, 70, 52), rgb(58, 44, 34)
local RUST = rgb(120, 70, 46)
local STONE, STONE_DARK = rgb(196, 188, 168), rgb(140, 134, 120)
local BONE = rgb(222, 214, 192)

-- Cofre del tesoro (con su cartel lo abre OceanService)
local function chest(parent: Instance, cf: CFrame, poiId: string)
	local base = part(parent, { Name = "Cofre", Size = V(4, 2.4, 2.6), CFrame = cf * CF(0, 1.2, 0), Color = rgb(110, 72, 40), Material = Enum.Material.Wood, Collide = true })
	part(parent, { Name = "Tapa", Size = V(4.1, 1, 2.7), CFrame = cf * CF(0, 2.9, -0.2) * ANG(rad(-12), 0, 0), Color = rgb(124, 82, 46), Material = Enum.Material.Wood })
	for _, x in { -1.6, 0, 1.6 } do
		part(parent, { Name = "Fleje", Size = V(0.3, 2.6, 2.75), CFrame = cf * CF(x, 1.3, 0), Color = rgb(196, 160, 60), Material = Enum.Material.Metal })
	end
	part(parent, { Name = "Brillo", Size = V(3.4, 0.4, 2), CFrame = cf * CF(0, 2.5, 0), Color = rgb(255, 214, 90), Material = Enum.Material.Neon, Transparency = 0.2 })
	if base then
		base:AddTag("SeaChest")
		base:SetAttribute("PoiId", poiId)
		base:SetAttribute("ChestId", poiId)
		local light = Instance.new("PointLight")
		light.Color = rgb(255, 210, 120)
		light.Range = 14
		light.Brightness = 1.2
		light.Parent = base
	end
end

local function ground(poi: any): Vector3
	return V(poi.X, floorAt(poi.X, poi.Z), poi.Z)
end

-- Pecio del Albatros: casco partido en dos, escorado, con la bodega abierta (se entra) y el cofre dentro
local function pecio()
	local poi = Ocean.PoiById.Pecio
	local m = model("PecioAlbatros")
	local g = ground(poi)
	local cf = CF(g + V(0, 5, 0)) * ANG(0, rad(25), rad(14)) -- escorado a estribor
	local L, W, H = 64, 16, 11
	-- quilla y fondo de la bodega
	part(m, { Name = "Quilla", Size = V(W - 2, 1.2, L), CFrame = cf * CF(0, -H / 2, 0), Color = DARK_WOOD, Material = Enum.Material.WoodPlanks, Collide = true })
	-- costados (con un boquete por el que se entra)
	for side = -1, 1, 2 do
		for i = 0, 7 do
			local z = -L / 2 + 4 + i * 8
			local broken = side == 1 and (i == 3 or i == 4)
			if not broken then
				part(m, { Name = "Costado", Size = V(1, H, 8.2), CFrame = cf * CF(side * W / 2, 0, z) * ANG(0, 0, rad(side * -8)), Color = WOOD:Lerp(DARK_WOOD, (i % 3) / 3), Material = Enum.Material.WoodPlanks, Collide = true })
			else
				part(m, { Name = "CostadoRoto", Size = V(1, H * 0.35, 8.2), CFrame = cf * CF(side * W / 2, -H * 0.32, z), Color = DARK_WOOD, Material = Enum.Material.WoodPlanks, Collide = true })
			end
		end
	end
	-- proa (cuña) y popa
	part(m, { Name = "Proa", Class = "WedgePart", Size = V(W, H, 10), CFrame = cf * CF(0, 0, -L / 2 - 5) * ANG(0, math.pi, 0), Color = WOOD, Material = Enum.Material.WoodPlanks, Collide = true })
	part(m, { Name = "Popa", Size = V(W, H + 4, 1.2), CFrame = cf * CF(0, 2, L / 2), Color = DARK_WOOD, Material = Enum.Material.WoodPlanks, Collide = true })
	part(m, { Name = "Castillo", Size = V(W, 1, 12), CFrame = cf * CF(0, H / 2 + 3.5, L / 2 - 6), Color = WOOD, Material = Enum.Material.WoodPlanks, Collide = true })
	-- cubierta a medias (la mitad se ha hundido: se ve la bodega)
	for i = 0, 7 do
		if i ~= 3 and i ~= 4 then
			part(m, { Name = "Cubierta", Size = V(W - 1, 0.6, 7.6), CFrame = cf * CF(0, H / 2, -L / 2 + 4 + i * 8), Color = WOOD, Material = Enum.Material.WoodPlanks, Collide = true })
		end
	end
	-- mástil caído y un cañón
	part(m, { Name = "Mastil", Shape = Enum.PartType.Cylinder, Size = V(46, 1.6, 1.6), CFrame = CF(g + V(18, 2, 6)) * ANG(0, rad(70), rad(6)), Color = DARK_WOOD, Material = Enum.Material.Wood, Collide = true })
	part(m, { Name = "Verga", Shape = Enum.PartType.Cylinder, Size = V(20, 0.9, 0.9), CFrame = CF(g + V(26, 3, -6)) * ANG(0, rad(-20), 0), Color = DARK_WOOD, Material = Enum.Material.Wood })
	for i = 1, 3 do
		part(m, { Name = "Canon", Shape = Enum.PartType.Cylinder, Size = V(5, 1.3, 1.3), CFrame = cf * CF(-W / 2 + 2, -H / 2 + 1.5, -12 + i * 7) * ANG(0, rad(90), 0), Color = rgb(44, 44, 48), Material = Enum.Material.CorrodedMetal })
	end
	-- barriles y cajas en la bodega
	for i = 1, 6 do
		part(m, { Name = "Barril", Shape = Enum.PartType.Cylinder, Size = V(3, 2.4, 2.4), CFrame = cf * CF(-3 + (i % 3) * 3, -H / 2 + 1.8, 8 + math.floor(i / 3) * 3) * ANG(0, 0, rad(90)), Color = rgb(96, 66, 40), Material = Enum.Material.Wood })
	end
	-- ancla y cadena
	part(m, { Name = "Ancla", Size = V(1, 9, 1), CFrame = CF(g + V(-24, 4, -30)) * ANG(rad(20), 0, rad(10)), Color = RUST, Material = Enum.Material.CorrodedMetal })
	part(m, { Name = "AnclaBrazo", Size = V(7, 1, 1), CFrame = CF(g + V(-24, 0.5, -31)) * ANG(0, 0, rad(10)), Color = RUST, Material = Enum.Material.CorrodedMetal })
	-- nombre en la popa
	local plate = part(m, { Name = "Nombre", Size = V(10, 1.6, 0.3), CFrame = cf * CF(0, 6, L / 2 + 0.8), Color = rgb(60, 50, 40), Material = Enum.Material.Wood })
	if plate then
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Back
		gui.LightInfluence = 0.4
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Text = "ALBATROS"
		t.TextScaled = true
		t.Font = Enum.Font.Antique
		t.TextColor3 = rgb(210, 180, 110)
		t.Parent = gui
		gui.Parent = plate
	end
	chest(m, cf * CF(2, -H / 2 + 0.6, -2), "Pecio")
end

-- Ruinas de Valmar la Vieja: plataforma, columnas (unas caídas), puerta en arco, cabeza de estatua y
-- una cámara con el cofre
local function ruinas()
	local poi = Ocean.PoiById.Ruinas
	local m = model("RuinasValmarVieja")
	local g = ground(poi)
	local cf = CF(g) * ANG(0, rad(12), 0)
	part(m, { Name = "Plataforma", Size = V(54, 4, 40), CFrame = cf * CF(0, 1, 0), Color = STONE_DARK, Material = Enum.Material.Slate, Collide = true })
	for i = 0, 2 do
		part(m, { Name = "Escalon", Size = V(24, 1.4, 3), CFrame = cf * CF(0, 0.7 + i * 1.2, -21.5 - (2 - i) * 2.6), Color = STONE, Material = Enum.Material.Slate, Collide = true })
	end
	-- columnas
	for i = 0, 5 do
		for side = -1, 1, 2 do
			local x, z = -20 + i * 8, side * 15
			local fallen = (i + side) % 4 == 0
			if fallen then
				part(m, { Name = "ColumnaCaida", Shape = Enum.PartType.Cylinder, Size = V(14, 3, 3), CFrame = cf * CF(x + 3, 4.5, z + side * 6) * ANG(0, rad(30 * side), 0), Color = STONE, Material = Enum.Material.Marble, Collide = true })
				part(m, { Name = "Basa", Shape = Enum.PartType.Cylinder, Size = V(2.5, 3.4, 3.4), CFrame = cf * CF(x, 4.2, z) * ANG(0, 0, rad(90)), Color = STONE, Material = Enum.Material.Marble })
			else
				local h = 13 - ((i * 3 + side) % 3) * 2.5
				part(m, { Name = "Columna", Shape = Enum.PartType.Cylinder, Size = V(h, 3, 3), CFrame = cf * CF(x, 3 + h / 2, z) * ANG(0, 0, rad(90)), Color = STONE, Material = Enum.Material.Marble, Collide = true })
				part(m, { Name = "Capitel", Size = V(4, 1, 4), CFrame = cf * CF(x, 3 + h + 0.5, z), Color = STONE_DARK, Material = Enum.Material.Marble })
			end
		end
	end
	-- la cámara (se entra por la puerta)
	local cam = cf * CF(0, 3, 6)
	part(m, { Name = "MuroFondo", Size = V(18, 12, 1.5), CFrame = cam * CF(0, 6, 8), Color = STONE_DARK, Material = Enum.Material.Slate, Collide = true })
	for side = -1, 1, 2 do
		part(m, { Name = "MuroLado", Size = V(1.5, 12, 16), CFrame = cam * CF(side * 9, 6, 0), Color = STONE_DARK, Material = Enum.Material.Slate, Collide = true })
		part(m, { Name = "MuroFrente", Size = V(6, 12, 1.5), CFrame = cam * CF(side * 6, 6, -8), Color = STONE_DARK, Material = Enum.Material.Slate, Collide = true })
	end
	part(m, { Name = "Dintel", Size = V(18, 3, 1.5), CFrame = cam * CF(0, 10.5, -8), Color = STONE, Material = Enum.Material.Slate, Collide = true })
	part(m, { Name = "Techo", Size = V(19, 1.4, 17), CFrame = cam * CF(0, 12.6, 0) * ANG(0, 0, rad(4)), Color = STONE, Material = Enum.Material.Slate, Collide = true })
	part(m, { Name = "Friso", Size = V(16, 1.2, 0.4), CFrame = cam * CF(0, 8, 7.1), Color = rgb(60, 140, 140), Material = Enum.Material.Glass, Transparency = 0.2 })
	chest(m, cam * CF(0, 0, 4) * ANG(0, math.pi, 0), "Ruinas")
	-- arco de entrada (puerta) y la cabeza de estatua caída
	for side = -1, 1, 2 do
		part(m, { Name = "Jamba", Size = V(3, 16, 3), CFrame = cf * CF(side * 9, 11, -26), Color = STONE, Material = Enum.Material.Marble, Collide = true })
	end
	part(m, { Name = "ArcoPuerta", Size = V(22, 3, 3), CFrame = cf * CF(0, 20, -26), Color = STONE, Material = Enum.Material.Marble, Collide = true })
	local head = cf * CF(-26, 3, -18) * ANG(rad(-20), rad(40), rad(25))
	part(m, { Name = "Cabeza", Shape = Enum.PartType.Ball, Size = V(9, 9, 9), CFrame = head, Color = STONE, Material = Enum.Material.Marble, Collide = true })
	part(m, { Name = "Nariz", Size = V(1.6, 3, 2), CFrame = head * CF(0, 0, -4.6), Color = STONE, Material = Enum.Material.Marble })
	part(m, { Name = "Corona", Size = V(8, 1.6, 8), CFrame = head * CF(0, 4.6, 0), Color = rgb(170, 150, 90), Material = Enum.Material.Metal })
	-- ánforas
	for i = 1, 5 do
		part(m, { Name = "Anfora", Shape = Enum.PartType.Ball, Size = V(2, 2.6, 2), CFrame = cf * CF(18 + (i % 3) * 3, 3.6, -8 + i * 2.5) * ANG(rad(i * 30), 0, rad(70 * (i % 2))), Color = rgb(170, 96, 60), Material = Enum.Material.Sand })
	end
end

-- Batiscafo perdido: esfera de acero con ventanas que aún brillan, flotadores y el cable roto
local function batiscafo()
	local poi = Ocean.PoiById.Batiscafo
	local m = model("BatiscafoPerdido")
	local g = ground(poi)
	local cf = CF(g + V(0, 4, 0)) * ANG(rad(8), rad(-30), rad(18))
	part(m, { Name = "Flotador", Size = V(10, 8, 30), CFrame = cf * CF(0, 7, 0), Color = rgb(214, 160, 40), Material = Enum.Material.Metal, Collide = true })
	part(m, { Name = "Esfera", Shape = Enum.PartType.Ball, Size = V(9, 9, 9), CFrame = cf * CF(0, 0, 0), Color = rgb(70, 80, 90), Material = Enum.Material.DiamondPlate, Collide = true })
	for i = 0, 2 do
		part(m, { Name = "Ventana", Shape = Enum.PartType.Cylinder, Size = V(0.4, 1.6, 1.6), CFrame = cf * ANG(0, rad(120 * i), 0) * CF(0, 0.6, -4.4) * ANG(0, rad(90), 0), Color = rgb(255, 210, 120), Material = Enum.Material.Neon })
	end
	part(m, { Name = "Cable", Size = V(0.5, 24, 0.5), CFrame = cf * CF(0, 21, 4) * ANG(rad(25), 0, 0), Color = rgb(40, 40, 40), Material = Enum.Material.Metal })
	local lamp = part(m, { Name = "Foco", Size = V(1.4, 1.4, 1.4), CFrame = cf * CF(0, -3, -4), Color = rgb(200, 240, 255), Material = Enum.Material.Neon })
	if lamp then
		local s = Instance.new("SpotLight")
		s.Range = 40
		s.Angle = 50
		s.Brightness = 3
		s.Face = Enum.NormalId.Front
		s.Color = rgb(190, 230, 255)
		s.Parent = lamp
	end
	chest(m, CF(g + V(9, 0, 4)) * ANG(0, rad(60), 0), "Batiscafo")
end

-- Caída de ballena: el esqueleto de una ballena en el fango del abismo
local function ballena()
	local poi = Ocean.PoiById.Ballena
	local m = model("CaidaBallena")
	local g = ground(poi)
	local cf = CF(g + V(0, 1.5, 0)) * ANG(0, rad(35), 0)
	local n = 22
	for i = 0, n - 1 do
		local z = -40 + i * 3.8
		local y = math.sin(i / n * math.pi) * 2
		local s = 2.6 - math.abs(i - 7) * 0.08
		part(m, { Name = "Vertebra", Size = V(s, s, 2.2), CFrame = cf * CF(0, y, z), Color = BONE, Material = Enum.Material.Limestone })
		if i >= 3 and i <= 15 and i % 2 == 1 then
			local len = 11 - math.abs(i - 9) * 0.6
			for side = -1, 1, 2 do
				part(m, { Name = "Costilla", Size = V(0.8, len, 0.8), CFrame = cf * CF(side * len * 0.35, y + len * 0.35, z) * ANG(0, 0, rad(side * -35)), Color = BONE, Material = Enum.Material.Limestone })
				part(m, { Name = "Costilla2", Size = V(0.7, len * 0.6, 0.7), CFrame = cf * CF(side * len * 0.72, y + len * 0.62, z) * ANG(0, 0, rad(side * -75)), Color = BONE, Material = Enum.Material.Limestone })
			end
		end
	end
	part(m, { Name = "Craneo", Size = V(9, 5, 14), CFrame = cf * CF(0, 2, -48) * ANG(rad(-6), 0, 0), Color = BONE, Material = Enum.Material.Limestone, Collide = true })
	part(m, { Name = "Mandibula", Size = V(1.2, 1.2, 16), CFrame = cf * CF(3.4, 0.2, -50) * ANG(0, rad(6), 0), Color = BONE, Material = Enum.Material.Limestone })
	part(m, { Name = "Mandibula", Size = V(1.2, 1.2, 16), CFrame = cf * CF(-3.4, 0.2, -50) * ANG(0, rad(-6), 0), Color = BONE, Material = Enum.Material.Limestone })
	-- gusanos y almejas que viven del esqueleto (brillan un poco)
	for i = 1, 10 do
		part(m, { Name = "Gusano", Size = V(0.4, 1.4, 0.4), CFrame = cf * CF((Ocean.hash(i, 1, 30) - 0.5) * 8, 0.6, -36 + i * 6), Color = rgb(255, 120, 150), Material = Enum.Material.Neon, Transparency = 0.2 })
	end
end

-- Jardín de Luz: tubos y cristales bioluminiscentes (con poca luz de verdad: 3 luces)
local function jardinLuz()
	local poi = Ocean.PoiById.JardinLuz
	local m = model("JardinDeLuz")
	local g = ground(poi)
	local colors = { rgb(60, 240, 255), rgb(140, 90, 255), rgb(60, 255, 170), rgb(255, 90, 210) }
	for i = 1, 26 do
		local a = Ocean.hash(i, 1, 31) * math.pi * 2
		local d = 4 + Ocean.hash(i, 2, 31) * 38
		local x, z = g.X + math.cos(a) * d, g.Z + math.sin(a) * d
		local y = floorAt(x, z)
		local h = 2 + Ocean.hash(i, 3, 31) * 7
		local c = colors[1 + (i % #colors)]
		local p = part(m, { Name = "TuboLuz", Size = V(0.8, h, 0.8), CFrame = CF(x, y + h / 2, z) * ANG(Ocean.hash(i, 4, 31) * 0.3, a, 0), Color = c, Material = Enum.Material.Neon, Transparency = 0.1 })
		part(m, { Name = "Base", Shape = Enum.PartType.Ball, Size = V(2, 1.2, 2), CFrame = CF(x, y + 0.3, z), Color = rgb(30, 30, 50), Material = Enum.Material.Basalt })
		if p and i % 9 == 0 then
			local l = Instance.new("PointLight")
			l.Color = c
			l.Range = 26
			l.Brightness = 1.6
			l.Parent = p
		end
	end
end

-- Jardín Escarlata: árboles de coral gigantes y abanicos (con color de verdad: se ve de lejos)
local function jardinEscarlata()
	local poi = Ocean.PoiById.JardinEscarlata
	local m = model("JardinEscarlata")
	local g = ground(poi)
	local colors = { rgb(232, 56, 70), rgb(250, 120, 60), rgb(240, 80, 140), rgb(255, 190, 80) }
	for i = 1, 9 do
		local a = Ocean.hash(i, 1, 32) * math.pi * 2
		local d = 6 + Ocean.hash(i, 2, 32) * 34
		local x, z = g.X + math.cos(a) * d, g.Z + math.sin(a) * d
		local y = floorAt(x, z)
		local c = colors[1 + (i % #colors)]
		local trunkH = 4 + Ocean.hash(i, 3, 32) * 4
		local base = CF(x, y, z) * ANG(0, a, 0)
		part(m, { Name = "Tronco", Shape = Enum.PartType.Cylinder, Size = V(trunkH, 1.4, 1.4), CFrame = base * CF(0, trunkH / 2, 0) * ANG(0, 0, rad(90)), Color = c, Material = Enum.Material.Pebble })
		for b = 1, 4 do
			local ang = b * math.pi / 2 + a
			local len = 3 + Ocean.hash(i, b, 33) * 3
			part(m, { Name = "Rama", Shape = Enum.PartType.Cylinder, Size = V(len, 0.8, 0.8), CFrame = base * CF(0, trunkH, 0) * ANG(0, ang, rad(55)) * CF(len / 2, 0, 0), Color = c, Material = Enum.Material.Pebble })
		end
	end
	for i = 1, 6 do
		local a = i * 1.1
		part(m, { Name = "Abanico", Size = V(7, 6, 0.3), CFrame = CF(g + V(math.cos(a) * 22, 3, math.sin(a) * 22)) * ANG(0, a, 0), Color = rgb(220, 60, 110), Material = Enum.Material.Fabric, Transparency = 0.1 })
	end
	for i = 1, 4 do
		part(m, { Name = "Cerebro", Shape = Enum.PartType.Ball, Size = V(6, 4.5, 6), CFrame = CF(g + V(-14 + i * 7, 1.2, -12 + (i % 2) * 20)), Color = rgb(250, 170, 90), Material = Enum.Material.Pebble })
	end
end

-- Catedral de Kelp: un círculo de pilares de piedra en un claro del bosque de kelp
local function catedral()
	local poi = Ocean.PoiById.CatedralKelp
	local m = model("CatedralKelp")
	local g = ground(poi)
	for i = 0, 9 do
		local a = i * math.pi * 2 / 10
		local x, z = g.X + math.cos(a) * 26, g.Z + math.sin(a) * 26
		local y = floorAt(x, z)
		local h = 10 + (i % 3) * 3
		part(m, { Name = "Pilar", Size = V(3, h, 3), CFrame = CF(x, y + h / 2, z) * ANG(0, a, rad((i % 2) * 6)), Color = rgb(120, 130, 110), Material = Enum.Material.Slate, Collide = true })
		if i % 2 == 0 then
			local a2 = a + math.pi / 10
			part(m, { Name = "Dintel", Size = V(3, 2, 17), CFrame = CF(g.X + math.cos(a2) * 26, y + h + 1, g.Z + math.sin(a2) * 26) * ANG(0, -a2, 0), Color = rgb(110, 120, 100), Material = Enum.Material.Slate })
		end
	end
	part(m, { Name = "Altar", Size = V(8, 3, 5), CFrame = CF(g + V(0, 1.5, 0)), Color = rgb(100, 110, 96), Material = Enum.Material.Slate, Collide = true })
end

-- La bolsa de aire: una burbuja de aire atrapada en el techo de la cueva (respirar aquí rellena el aire)
local function bolsaAire()
	local poi = Ocean.PoiById.BolsaAire
	local m = model("BolsaDeAire")
	local y = floorAt(poi.X, poi.Z)
	local c = V(poi.X, y + 8, poi.Z)
	local dome = part(m, { Name = "Burbuja", Shape = Enum.PartType.Ball, Size = V(16, 10, 16), CFrame = CF(c + V(0, 9, 0)), Color = rgb(200, 240, 255), Material = Enum.Material.Glass, Transparency = 0.6 })
	if dome then
		dome:AddTag("SeaAirPocket")
		dome:SetAttribute("Radius", 14)
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Rate = 6
		e.Lifetime = NumberRange.new(2, 3)
		e.Speed = NumberRange.new(2, 4)
		e.Size = NumberSequence.new(0.3)
		e.EmissionDirection = Enum.NormalId.Top
		e.Parent = dome
		local l = Instance.new("PointLight")
		l.Range = 18
		l.Color = rgb(180, 230, 255)
		l.Parent = dome
	end
	part(m, { Name = "Cartel", Size = V(5, 2.6, 0.4), CFrame = CF(c + V(0, -4, 12)), Color = rgb(30, 60, 90), Material = Enum.Material.Metal })
end

-- La guarida: huesos, huevos que brillan y el cofre al fondo de la cueva
local function guarida()
	local L = Ocean.Lair
	local m = model("GuaridaKraken")
	local floorY = L.Y - L.Radius + 6
	for i = 1, 7 do
		local a = i * 0.9
		part(m, { Name = "Huevo", Shape = Enum.PartType.Ball, Size = V(2.4, 3.2, 2.4), CFrame = CF(L.X + math.cos(a) * 12, floorY + 1.4, L.Z - 6 + math.sin(a) * 9), Color = rgb(150, 60, 220), Material = Enum.Material.Neon, Transparency = 0.25 })
	end
	for i = 1, 6 do
		part(m, { Name = "Hueso", Size = V(0.8, 0.8, 6 + i % 3 * 2), CFrame = CF(L.X - 10 + i * 3, floorY + 0.4, L.Z + 4) * ANG(0, i, 0), Color = BONE, Material = Enum.Material.Limestone })
	end
	part(m, { Name = "Ancla", Size = V(1, 8, 1), CFrame = CF(L.X + 14, floorY + 3, L.Z - 10) * ANG(0, 0, rad(30)), Color = RUST, Material = Enum.Material.CorrodedMetal })
	local glow = part(m, { Name = "Brillo", Shape = Enum.PartType.Ball, Size = V(1, 1, 1), CFrame = CF(L.X, L.Y + 4, L.Z), Color = rgb(150, 60, 220), Material = Enum.Material.Neon, Transparency = 0.6 })
	if glow then
		local l = Instance.new("PointLight")
		l.Range = 40
		l.Color = rgb(170, 80, 255)
		l.Brightness = 1.4
		l.Parent = glow
	end
	chest(m, CF(L.X, floorY, L.Z - 16), "Guarida")
end

-- Arco de Coral: costra de coral sobre el arco de roca y un cofre pequeño debajo
local function arcoCoral()
	local poi = Ocean.PoiById.ArcoCoral
	local m = model("ArcoCoral")
	local g = ground(poi)
	local colors = { rgb(240, 70, 90), rgb(255, 150, 60), rgb(180, 80, 210), rgb(255, 210, 90) }
	local facing = V(1, 0, 0.3).Unit
	local right = V(-facing.Z, 0, facing.X)
	for i = 0, 10 do
		local a = math.pi * i / 10
		local p = g + right * math.cos(a) * 18 + V(0, math.sin(a) * 18 + 2, 0)
		part(m, { Name = "Coral", Shape = Enum.PartType.Ball, Size = V(3, 2.4, 3), CFrame = CF(p + V(0, 3, 0)), Color = colors[1 + i % #colors], Material = Enum.Material.Pebble })
	end
	chest(m, CF(g + V(0, 0.2, 0)) * ANG(0, rad(20), 0), "ArcoCoral")
end

function OceanBuilder.sites()
	for _, fn in { pecio, ruinas, batiscafo, ballena, jardinLuz, jardinEscarlata, catedral, bolsaAire, guarida, arcoCoral } do
		local ok, err = pcall(fn)
		if not ok then
			warn("[OceanBuilder] sitio: " .. tostring(err))
		end
	end
	OceanBuilder.Stats.Parts = parts
end

---------------------------------------------------------------------

function OceanBuilder.build(worldId: string?)
	if worldId and worldId ~= "Valmar" then
		warn("[OceanBuilder] mundo sin construir todavía: " .. tostring(worldId))
		return
	end
	if OceanBuilder.State ~= "None" then
		return
	end
	OceanBuilder.State = "Building"
	local started = os.clock()
	local terrain = workspace.Terrain
	local lastYield = os.clock()
	local function yield()
		if os.clock() - lastYield > 0.03 then
			task.wait()
			lastYield = os.clock()
		end
	end
	OceanBuilder.terrain(terrain, yield)
	relief(terrain, yield)
	OceanBuilder.sites()
	OceanBuilder.State = "Ready"
	OceanBuilder.Stats.Seconds = os.clock() - started
	workspace:SetAttribute("OceanReady", true)
	print(("[OceanBuilder] mar hondo listo: %d rellenos de terreno, %d piezas, %.1f s"):format(OceanBuilder.Stats.Fills, OceanBuilder.Stats.Parts, OceanBuilder.Stats.Seconds))
end

return OceanBuilder
