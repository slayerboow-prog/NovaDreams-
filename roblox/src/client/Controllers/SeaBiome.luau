-- SeaBiome (cliente): el mundo de debajo del agua, solo en tu pantalla y solo cuando estás en el agua.
--
--   * Agua: al meterte, la superficie deja de ser un espejo (menos reflejo, más transparente) para que
--     desde fuera se vea a quien nada y bucea. Al salir vuelve a ser como antes.
--   * Luz: con la cámara bajo el agua, DayLight pone bruma verde azulada, colores apagados y el fondo
--     borroso. Rayos de sol que entran desde la superficie (de día) y motas flotando delante de la cámara.
--   * Fondo: alrededor de ti se crea el fondo según el agua:
--       mar y alta mar  praderas de posidonia, algas largas que se mecen, rocas, corales (cerebro,
--                       ramas y gorgonias), erizos, estrellas de mar, conchas y, a veces, un ánfora o un ancla
--       río y lagos     plantas de agua, juncos, piedras, troncos hundidos y cantos rodados
--     Se hace por trozos (siempre igual en el mismo sitio) y se quita lo que queda lejos.
--   * Vida: bancos de pececillos que dan vueltas y huyen si te acercas, y medusas que suben y bajan.
-- Todo es decorado: no choca, no se puede tocar y no lo ve nadie más (no gasta red).

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CityPlan = require(ReplicatedStorage.Shared.CityPlan)
local Perf = require(script.Parent.Parent.UI.Perf)
local DayLight = require(script.Parent.DayLight)

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

type Sway = { Parts: { BasePart }, Heights: { number }, Base: CFrame, Phase: number, Amount: number }
type Cell = { Parts: { Instance }, Sway: { Sway } }

local folder: Folder? = nil
local cells: { [string]: Cell } = {}
local sways: { Sway } = {}
local active = false
local leftAt = 0
local defaults: { Reflectance: number, Transparency: number }? = nil
local waterLook = 0 -- 0 = agua normal, 1 = agua para ver bajo ella
local under = 0 -- cámara bajo el agua (suave)

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

-- Altura del fondo (o nil si no hay agua bastante honda)
local function floorAt(x: number, z: number): number?
	floorParams.FilterDescendantsInstances = { workspace.Terrain }
	local hit = workspace:Raycast(Vector3.new(x, SURFACE - 0.5, z), Vector3.new(0, -40, 0), floorParams)
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

local function buildCell(ix: number, iz: number): Cell
	local cell: Cell = { Parts = {}, Sway = {} }
	local count = floor(hash(ix, iz, 1) * 3.2)
	for j = 1, count do
		local x = (ix + hash(ix, iz, j * 2)) * CELL
		local z = (iz + hash(iz, ix, j * 2 + 1)) * CELL
		local y = floorAt(x, z)
		if y and isWater(x, z) then
			local fresh = freshwater(x, z)
			local item = pickItem(if fresh then FRESH_ITEMS else SEA_ITEMS, hash(x, z, 7))
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
		p:Destroy()
	end
end

local function refreshCells(center: Vector3)
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
					if not cells[key] and built < BUILD_PER_TICK then
						cells[key] = buildCell(ix, iz)
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
-- Vida: bancos de pececillos y medusas
---------------------------------------------------------------------
type School = { Center: Vector3, Fish: { BasePart }, Radius: number, Speed: number, Phase: number }
local schools: { School } = {}
type Jelly = { Parts: { BasePart }, Base: Vector3, Phase: number }
local jellies: { Jelly } = {}
local FISH_COLORS = { rgb(200, 210, 220), rgb(250, 210, 80), rgb(90, 160, 230), rgb(240, 140, 60) }

local function makeSchool(at: Vector3, seed: number): School
	local fish = {}
	local color = FISH_COLORS[1 + floor(seed * #FISH_COLORS) % #FISH_COLORS]
	local cell: Cell = { Parts = {}, Sway = {} }
	for i = 1, (if Perf.mobile then 6 else 10) do
		local p = piece(cell, Vector3.new(0.18, 0.3, 0.7), CFrame.new(at), color, Enum.Material.SmoothPlastic)
		p:SetAttribute("Slot", i)
		table.insert(fish, p)
	end
	return { Center = at, Fish = fish, Radius = 2.5 + seed * 3, Speed = 0.8 + seed * 0.8, Phase = seed * 10 }
end

local function makeJelly(at: Vector3, seed: number): Jelly
	local cell: Cell = { Parts = {}, Sway = {} }
	local color = rgb(240, 160, 220):Lerp(rgb(170, 200, 255), seed)
	local bell = piece(cell, Vector3.new(1.4, 1, 1.4), CFrame.new(at), color, Enum.Material.Glass, Enum.PartType.Ball, 0.45)
	local parts = { bell }
	for i = 1, 4 do
		table.insert(parts, piece(cell, Vector3.new(0.06, 1.6, 0.06), CFrame.new(at), color, Enum.Material.Glass, nil, 0.4))
	end
	return { Parts = parts, Base = at, Phase = seed * 10 }
end

local function clearLife()
	for _, s in schools do
		for _, p in s.Fish do
			p:Destroy()
		end
	end
	for _, j in jellies do
		for _, p in j.Parts do
			p:Destroy()
		end
	end
	table.clear(schools)
	table.clear(jellies)
end

local function refreshLife(center: Vector3)
	-- Se quitan los que quedan lejos y se ponen nuevos cerca
	for i = #schools, 1, -1 do
		if (schools[i].Center - center).Magnitude > RADIUS then
			for _, p in schools[i].Fish do
				p:Destroy()
			end
			table.remove(schools, i)
		end
	end
	for i = #jellies, 1, -1 do
		if (jellies[i].Base - center).Magnitude > RADIUS then
			for _, p in jellies[i].Parts do
				p:Destroy()
			end
			table.remove(jellies, i)
		end
	end
	local want = if Perf.mobile then 2 else 4
	if #schools < want then
		local a = math.random() * math.pi * 2
		local d = 12 + math.random() * 25
		local x, z = center.X + cos(a) * d, center.Z + sin(a) * d
		local y = floorAt(x, z)
		if y and isWater(x, z) then
			table.insert(schools, makeSchool(Vector3.new(x, math.min(y + 2 + math.random() * 3, SURFACE - 1.5), z), math.random()))
		end
	end
	if #jellies < (if Perf.mobile then 1 else 2) and not freshwater(center.X, center.Z) then
		local a = math.random() * math.pi * 2
		local d = 10 + math.random() * 20
		local x, z = center.X + cos(a) * d, center.Z + sin(a) * d
		local y = floorAt(x, z)
		if y and isWater(x, z) then
			table.insert(jellies, makeJelly(Vector3.new(x, (y + SURFACE) / 2, z), math.random()))
		end
	end
end

local function animateLife(t: number, dt: number, me: Vector3?)
	for _, s in schools do
		-- Si te acercas, el banco huye
		if me and (me - s.Center).Magnitude < 7 then
			local away = s.Center - me
			away = Vector3.new(away.X, 0, away.Z)
			if away.Magnitude > 0.1 then
				s.Center += away.Unit * dt * 9
			end
		end
		for i, p in s.Fish do
			local a = t * s.Speed + s.Phase + i * (math.pi * 2 / #s.Fish)
			local r = s.Radius * (0.7 + 0.3 * sin(i * 1.7))
			local pos = s.Center + Vector3.new(cos(a) * r, sin(t * 1.3 + i) * 0.5, sin(a) * r)
			local ahead = s.Center + Vector3.new(cos(a + 0.2) * r, sin(t * 1.3 + i) * 0.5, sin(a + 0.2) * r)
			p.CFrame = CFrame.lookAt(pos, ahead) * angles(0, sin(t * 12 + i) * 0.15, 0)
		end
	end
	for _, j in jellies do
		local y = sin(t * 0.6 + j.Phase) * 1.2
		local pulse = 1 + sin(t * 2.4 + j.Phase) * 0.08
		local at = j.Base + Vector3.new(sin(t * 0.2 + j.Phase) * 0.8, y, 0)
		j.Parts[1].Size = Vector3.new(1.4 * pulse, 1 / pulse, 1.4 * pulse)
		j.Parts[1].CFrame = CFrame.new(at)
		for i = 2, #j.Parts do
			local a = (i - 2) * math.pi / 2
			j.Parts[i].CFrame = CFrame.new(at + Vector3.new(cos(a) * 0.35, -1.1, sin(a) * 0.35)) * angles(sin(t * 1.5 + i) * 0.2, 0, cos(t * 1.3 + i) * 0.2)
		end
	end
end

---------------------------------------------------------------------
-- Luz: rayos de sol y motas
---------------------------------------------------------------------
local rays: { Beam } = {}
local rayHolder: Part? = nil
local motes: ParticleEmitter? = nil

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
	for i = 1, (if Perf.mobile then 3 else 6) do
		local top = Instance.new("Attachment")
		top.Parent = holder
		local bottom = Instance.new("Attachment")
		bottom.Parent = holder
		local beam = Instance.new("Beam")
		beam.Attachment0 = top
		beam.Attachment1 = bottom
		beam.Width0 = 2.5 + (i % 3)
		beam.Width1 = 4 + (i % 2) * 2
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
end

local function updateLight(camera: Camera, t: number)
	local holder = rayHolder
	if not holder then
		return
	end
	local cam = camera.CFrame.Position
	holder.CFrame = CFrame.new(cam + camera.CFrame.LookVector * 6)
	local day = Lighting.ClockTime > 7 and Lighting.ClockTime < 19
	for _, beam in rays do
		local i = beam:GetAttribute("Seed") or 1
		local a = i * 1.9 + t * 0.03
		local x = cos(a) * (6 + i * 3)
		local z = sin(a) * (6 + i * 3)
		local top = beam.Attachment0 :: Attachment
		local bottom = beam.Attachment1 :: Attachment
		top.WorldPosition = Vector3.new(cam.X + x, SURFACE - 0.3, cam.Z + z)
		bottom.WorldPosition = Vector3.new(cam.X + x + 3, SURFACE - 13, cam.Z + z + 1.5)
		beam.Enabled = day and under > 0.5
		local flicker = 0.8 + 0.08 * sin(t * 1.7 + i * 2)
		beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, flicker), NumberSequenceKeypoint.new(1, 1) })
	end
	if motes then
		motes.Enabled = under > 0.5
	end
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
			DayLight.setUnderwater(under)
			waterLook += ((if inWater then 1 else 0) - waterLook) * math.min(1, dt * 2)
			local look = if waterLook < 0.002 then 0 elseif waterLook > 0.998 then 1 else waterLook
			if math.abs(look - lastLook) > 0.002 or (look ~= lastLook and (look == 0 or look == 1)) then
				lastLook = look
				setWaterLook(look)
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
				clearLife()
				if rayHolder then
					rayHolder:Destroy()
					rayHolder = nil
				end
				motes = nil
			end
			if not active then
				return
			end
			local center = if root then root.Position else camPos
			if t - lastRefresh > 0.3 then
				lastRefresh = t
				refreshCells(center)
				refreshLife(center)
			end
			swayAll(t, camPos)
			animateLife(t, dt, if root then root.Position else nil)
			updateLight(camera, t)
		end)
		if not ok then
			warn("[SeaBiome] " .. tostring(err))
		end
	end)
end

return SeaBiome
