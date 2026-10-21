-- NacaraDecor (servidor): lo que hace que Nácara se vea de lejos y no sea «cutre» (queja del dueño en la
-- v125.5: «sin una ciudad bajo el mar, sin textura, sin nada, sin animaciones»; docs/mar/civilizacion-marina.md).
-- Solo la ciudad y sus alrededores inmediatos: el fondo del resto del mar es del arte de la orilla (SeaBiome,
-- ReefZone, ShoreDecor), aquí no se duplica.
--
--   * Jardines de coral del KIT DEL MAR alrededor de la plaza y de los barrios (MarKit: corales, abanicos,
--     esponjas, kelp gigante, setas y anémonas que brillan, rocas): con su malla de Blender con textura si
--     está subida (ReplicatedStorage.MarMallas, World/MarMeshes) y, si no, con su respaldo de piezas. Los
--     que se mecen llevan la etiqueta NacaraSway (los mueve el cliente: Controllers/NacaraLife).
--   * El FARO DE NÁCARA: una columna de luz desde la plaza hasta cerca de la superficie, con un anillo de
--     perlas arriba: se ve desde lejos bajo el agua.
--   * Desde la orilla: una LÍNEA DE BOYAS que brillan en la superficie, del jardín de coral del sur hasta
--     encima de Nácara (la ruta de las perlas de guía), y una boya grande con el cartel «NÁCARA ↓ 37 m».
--     Sin choques: los barcos pasan por encima.
--   * Columnas de burbujas (ParticleEmitter) en la plaza y los barrios.
-- Presupuesto propio: NacaraDecor.Budget piezas de respaldo (las mallas cuentan una cada una).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ocean = require(ReplicatedStorage.Shared.Sea.Ocean)
local Nacara = require(ReplicatedStorage.Shared.Sea.Nacara)
local Civ = require(ReplicatedStorage.Shared.Sea.Civ)
local MarKit = require(ReplicatedStorage.Shared.Sea.MarKit)

local NacaraDecor = {}

NacaraDecor.Budget = 650 -- piezas de respaldo (sin mallas)
NacaraDecor.BuoyStep = 150 -- una boya cada tantos studs
NacaraDecor.Stats = { Meshes = 0, Pieces = 0, Buoys = 0, Bubbles = 0, Kit = 0 }
NacaraDecor.State = "None"

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local cos, sin, pi = math.cos, math.sin, math.pi

local CORAL_COLORS = { rgb(255, 120, 150), rgb(255, 170, 90), rgb(190, 120, 255), rgb(120, 220, 255), rgb(255, 220, 120), rgb(140, 240, 180) }

local function folder(): Folder
	local f = workspace:FindFirstChild("NacaraDecor")
	if not f then
		f = Instance.new("Folder")
		f.Name = "NacaraDecor"
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
	m.Parent = folder()
	return m
end

local function decorFlags(p: BasePart)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
end

local SHAPES = { Ball = Enum.PartType.Ball, Cylinder = Enum.PartType.Cylinder }
local function materialOf(name: string): Enum.Material
	local ok, m = pcall(function()
		return (Enum.Material :: any)[name]
	end)
	return if ok and m then m else Enum.Material.SmoothPlastic
end

-- Una pieza del kit en (x, y del suelo, z), con alto h. Devuelve la instancia o nil (sin presupuesto)
function NacaraDecor.piece(kind: string, at: Vector3, h: number, yaw: number, color: Color3, parent: Instance, meshes: Instance?): Instance?
	local info = MarKit.Pieces[kind]
	if not info then
		return nil
	end
	local base = CF(at) * ANG(0, yaw, 0)
	local template = meshes and meshes:FindFirstChild(kind)
	if template and template:IsA("MeshPart") then
		local k = h / info.Size[2]
		local m = template:Clone()
		m.Size = V(info.Size[1], info.Size[2], info.Size[3]) * k
		m.CFrame = base * CF(0, m.Size.Y / 2, 0)
		if info.Tint then
			m.Color = color
			m.Material = if info.Glow then Enum.Material.Neon else Enum.Material.SmoothPlastic
		end
		decorFlags(m)
		if info.Sway then
			CollectionService:AddTag(m, "NacaraSway")
		end
		m.Parent = parent
		NacaraDecor.Stats.Meshes += 1
		NacaraDecor.Stats.Kit += 1
		return m
	end
	local specs = MarKit.fallback(kind, h, color, at.X * 0.37 + at.Z * 0.11)
	if NacaraDecor.Stats.Pieces + #specs > NacaraDecor.Budget then
		return nil
	end
	local holder = Instance.new("Model")
	holder.Name = kind
	for _, s in specs do
		local p = Instance.new("Part")
		p.Size = s.Size
		p.CFrame = base * s.CFrame
		p.Color = s.Color
		p.Material = materialOf(s.Material)
		if s.Shape and SHAPES[s.Shape] then
			p.Shape = SHAPES[s.Shape]
		end
		if s.Mesh == "Sphere" then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = p
		end
		p.Transparency = s.Transparency or 0
		decorFlags(p)
		p.Parent = holder
		NacaraDecor.Stats.Pieces += 1
	end
	if info.Sway then
		CollectionService:AddTag(holder, "NacaraSway")
	end
	holder.Parent = parent
	NacaraDecor.Stats.Kit += 1
	return holder
end

-- ¿Se puede plantar aquí? (no encima de la plaza, de un edificio, de la ruta ni de la persecución)
function NacaraDecor.free(x: number, z: number): boolean
	if x * x + z * z < (Nacara.Radius + 3) ^ 2 then
		return false
	end
	for _, a in Civ.Areas do
		if a.Id ~= "Plaza" and (x - a.X) ^ 2 + (z - a.Z) ^ 2 < (a.R - 4) ^ 2 then
			return false
		end
	end
	for _, l in Civ.Lamps do
		if (x - l.X) ^ 2 + (z - l.Z) ^ 2 < 36 then
			return false
		end
	end
	return true
end

-- Dónde va cada cosa del jardín (siempre los mismos sitios: semilla fija). { Kind, X, Z, H, Yaw, Color }
function NacaraDecor.plan(): { { [string]: any } }
	local list = {}
	local seed = 7
	local function rnd(): number
		seed = (seed * 1103515245 + 12345) % 2147483648
		return seed / 2147483648
	end
	-- 1. Anillo de coral alrededor de la plaza (el borde del anfiteatro)
	local ring = { "CoralCuerno", "Abanico", "CoralCerebro", "Esponjas", "CoralBlando", "AnemonaLuz", "CoralMesa", "SetaLuz" }
	for i = 0, 27 do
		local a = i / 28 * pi * 2 + 0.07
		local r = Nacara.Clear + 6 + rnd() * 10
		local x, z = cos(a) * r, sin(a) * r
		local dz, dx = sin(a), cos(a)
		-- (las entradas del norte y del este quedan libres)
		if not (dz < -0.9 or dx > 0.93) and NacaraDecor.free(x, z) then
			local kind = ring[i % #ring + 1]
			table.insert(list, { Kind = kind, X = x, Z = z, H = (MarKit.Pieces[kind].Size[2]) * (1.4 + rnd() * 0.9), Yaw = rnd() * pi * 2, Color = CORAL_COLORS[i % #CORAL_COLORS + 1] })
		end
	end
	-- 2. Kelp gigante alrededor de la ciudad (silueta de lejos) y rocas
	for i = 0, 13 do
		local a = i / 14 * pi * 2 + 0.3
		local r = 205 + rnd() * 25
		local x, z = cos(a) * r, sin(a) * r * 0.9
		if NacaraDecor.free(x, z) and z < 210 then
			table.insert(list, { Kind = if i % 3 == 2 then "RocaPorosa" else "KelpGigante", X = x, Z = z, H = if i % 3 == 2 then 6 else 34 + rnd() * 12, Yaw = rnd() * pi * 2, Color = rgb(80, 140, 70) })
		end
	end
	-- 3. Un jardincito en cada barrio (en su borde) y luces que brillan en los caminos
	for _, area in Civ.Areas do
		if area.Id ~= "Plaza" then
			for k = 0, 5 do
				local a = k / 6 * pi * 2 + area.X * 0.01
				local x, z = area.X + cos(a) * (area.R + 6), area.Z + sin(a) * (area.R + 6)
				if NacaraDecor.free(x, z) then
					local kind = ({ "AnemonaLuz", "CoralCuerno", "SetaLuz", "Abanico", "CoralCerebro", "Esponjas" })[k + 1]
					table.insert(list, { Kind = kind, X = x, Z = z, H = MarKit.Pieces[kind].Size[2] * (1.3 + rnd() * 0.6), Yaw = rnd() * pi * 2, Color = CORAL_COLORS[(k + #area.Id) % #CORAL_COLORS + 1] })
				end
			end
		end
	end
	return list
end

-- La línea de boyas: de la ruta de buceo (Nacara.Route) en la superficie, cada BuoyStep studs
function NacaraDecor.buoyPoints(): { Vector3 }
	local pts = {}
	local carry = 0
	local route = Nacara.Route
	for i = 1, #route - 1 do
		local a, b = route[i], route[i + 1]
		local dx, dz = b.X - a.X, b.Z - a.Z
		local len = math.sqrt(dx * dx + dz * dz)
		local d = carry
		while d < len do
			local x, z = a.X + dx * d / len, a.Z + dz * d / len
			table.insert(pts, V(x, Ocean.Surface, z))
			d += NacaraDecor.BuoyStep
		end
		carry = d - len
	end
	table.insert(pts, V(Nacara.Center.X, Ocean.Surface, Nacara.Center.Z))
	return pts
end

local function part(parent: Instance, props: { [string]: any }): BasePart
	local p = Instance.new("Part")
	for k, v in props do
		(p :: any)[k] = v
	end
	decorFlags(p)
	p.Parent = parent
	return p
end

local function buoys(m: Model)
	local pts = NacaraDecor.buoyPoints()
	for i, at in pts do
		local last = i == #pts
		local s = if last then 2.2 else 1
		part(m, { Name = "Boya", Shape = Enum.PartType.Ball, Size = V(2.2, 2.2, 2.2) * s, CFrame = CF(at + V(0, 0.4 * s, 0)), Color = rgb(255, 140, 60), Material = Enum.Material.SmoothPlastic })
		local light = part(m, { Name = "LuzBoya", Shape = Enum.PartType.Ball, Size = V(0.9, 0.9, 0.9) * s, CFrame = CF(at + V(0, 2.6 * s, 0)), Color = rgb(120, 245, 255), Material = Enum.Material.Neon })
		light:SetAttribute("Pulse", i * 0.4)
		CollectionService:AddTag(light, "NacaraPulse")
		part(m, { Name = "PaloBoya", Shape = Enum.PartType.Cylinder, Size = V(2.2 * s, 0.25 * s, 0.25 * s), CFrame = CF(at + V(0, 1.4 * s, 0)) * ANG(0, 0, pi / 2), Color = rgb(240, 240, 240) })
		NacaraDecor.Stats.Buoys += 1
		if last then
			local board = part(m, { Name = "CartelBoya", Size = V(9, 3, 0.3), CFrame = CF(at + V(0, 9, 0)), Color = rgb(18, 34, 62) })
			local post = part(m, { Name = "PosteCartelBoya", Shape = Enum.PartType.Cylinder, Size = V(6, 0.5, 0.5), CFrame = CF(at + V(0, 5.5, 0)) * ANG(0, 0, pi / 2), Color = rgb(240, 240, 240) })
			local _ = post
			for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
				local gui = Instance.new("SurfaceGui")
				gui.Face = face
				gui.PixelsPerStud = 40
				gui.LightInfluence = 0
				gui.Parent = board
				local t = Instance.new("TextLabel")
				t.Size = UDim2.fromScale(1, 1)
				t.BackgroundTransparency = 1
				t.Text = "🐚 NÁCARA ↓ 37 m"
				t.TextScaled = true
				t.Font = Enum.Font.GothamBold
				t.TextColor3 = rgb(160, 245, 255)
				t.Parent = gui
			end
			local pl = Instance.new("PointLight")
			pl.Color = rgb(150, 240, 255)
			pl.Range = 40
			pl.Brightness = 1.5
			pl.Shadows = false
			pl.Parent = light
		end
	end
end

-- El faro de Nácara: columna de luz de la plaza casi hasta la superficie (se ve de lejos bajo el agua)
local function beacon(m: Model)
	local c = Nacara.centerPosition()
	local top = Ocean.Surface - 14
	local bottom = c.Y + 52
	local h = top - bottom
	part(m, { Name = "FaroColumna", Shape = Enum.PartType.Cylinder, Size = V(h, 3.2, 3.2), CFrame = CF(c.X, (top + bottom) / 2, c.Z) * ANG(0, 0, pi / 2), Color = rgb(120, 240, 255), Material = Enum.Material.Neon, Transparency = 0.6 })
	part(m, { Name = "FaroNucleo", Shape = Enum.PartType.Cylinder, Size = V(h, 0.7, 0.7), CFrame = CF(c.X, (top + bottom) / 2, c.Z) * ANG(0, 0, pi / 2), Color = rgb(220, 255, 255), Material = Enum.Material.Neon, Transparency = 0.45 })
	for k = 0, 5 do
		local a = k / 6 * pi * 2
		local p = part(m, { Name = "PerlaFaro", Shape = Enum.PartType.Ball, Size = V(2.6, 2.6, 2.6), CFrame = CF(c.X + cos(a) * 7, top - 2, c.Z + sin(a) * 7), Color = rgb(236, 244, 255), Material = Enum.Material.Neon })
		p:SetAttribute("Pulse", k * 0.5)
		CollectionService:AddTag(p, "NacaraPulse")
	end
end

local function bubbles(m: Model)
	local spots = { { 30, 50 }, { -45, -30 } }
	for _, a in Civ.Areas do
		if a.Id ~= "Plaza" then
			table.insert(spots, { a.X, a.Z + a.R * 0.6 })
		end
	end
	for _, s in spots do
		local base = part(m, { Name = "FuenteBurbujas", Shape = Enum.PartType.Ball, Size = V(1.6, 0.6, 1.6), CFrame = CF(Nacara.toWorld(s[1], s[2], 0.3)), Color = rgb(150, 160, 186) })
		local e = Instance.new("ParticleEmitter")
		e.Name = "Burbujas"
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Rate = 6
		e.Lifetime = NumberRange.new(5, 8)
		e.Speed = NumberRange.new(4, 7)
		e.SpreadAngle = Vector2.new(6, 6)
		e.Size = NumberSequence.new(0.3, 0.6)
		e.LightEmission = 0.5
		e.Color = ColorSequence.new(rgb(200, 250, 255))
		e.EmissionDirection = Enum.NormalId.Top
		e.Parent = base
		NacaraDecor.Stats.Bubbles += 1
	end
end

-- Construye todo (una vez). meshes = ReplicatedStorage.MarMallas o nil (respaldo de piezas)
function NacaraDecor.build(meshes: Instance?)
	if NacaraDecor.State ~= "None" then
		return
	end
	NacaraDecor.State = "Building"
	local steps = {
		function()
			local gardens = model("Nacara_JardinesDeCoral")
			for _, p in NacaraDecor.plan() do
				local floor = Nacara.FloorY
				local wx, wz = Nacara.Center.X + p.X, Nacara.Center.Z + p.Z
				if p.X * p.X + p.Z * p.Z > (Nacara.Clear + 30) ^ 2 then
					local f = Ocean.floorY(wx, wz)
					floor = if f then f else floor
				end
				NacaraDecor.piece(p.Kind, V(wx, floor, wz), p.H, p.Yaw, p.Color, gardens, meshes)
			end
		end,
		function()
			beacon(model("Nacara_Faro"))
		end,
		function()
			buoys(model("Nacara_Boyas"))
		end,
		function()
			bubbles(model("Nacara_Burbujas"))
		end,
	}
	for _, fn in steps do
		local ok, err = pcall(fn)
		if not ok then
			warn("[NacaraDecor] " .. tostring(err))
		end
	end
	NacaraDecor.State = "Ready"
	print(("[NacaraDecor] %d piezas del kit (%d mallas, %d piezas de respaldo), %d boyas, %d columnas de burbujas"):format(NacaraDecor.Stats.Kit, NacaraDecor.Stats.Meshes, NacaraDecor.Stats.Pieces, NacaraDecor.Stats.Buoys, NacaraDecor.Stats.Bubbles))
end

function NacaraDecor._reset()
	NacaraDecor.State = "None"
	NacaraDecor.Stats = { Meshes = 0, Pieces = 0, Buoys = 0, Bubbles = 0, Kit = 0 }
end

return NacaraDecor
