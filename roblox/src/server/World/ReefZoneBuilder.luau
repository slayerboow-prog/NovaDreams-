-- ReefZoneBuilder: construye la zona de referencia del mar, el Cañón de Dorada (shared/Sea/ReefZone;
-- encargo v2 del dueño, docs/mar/diseno-v2.md). Lo llama World/OceanBuilder al acabar el mar hondo (el
-- lecho del cañón ya lo ha puesto OceanBuilder: sale de Ocean.sample → ReefZone.carve).
--
--   1. Terreno: las operaciones de ReefZone.ops en orden (los colores del fondo —arena dorada clara,
--      ondas de arenisca, caliza— son los de World/TerrainBuilder.Colors): paredes, mesetas, repisas, columnas, agujas, el arco, la cueva con sus
--      claraboyas (huecos de AGUA, no de aire), los montículos del jardín y las manchas del lecho.
--   2. Piezas del kit (ReefZone.placements): la malla de Blender si World/MarMeshes la ha cargado
--      (ReplicatedStorage.MarMallas) o el respaldo de piezas (shared/Sea/MarKit.fallback), en un modelo
--      Atomic por grupo (StreamingEnabled: llega por trozos). Nada choca, nada se toca ni se consulta
--      (CanCollide/CanTouch/CanQuery = false), todo anclado y sin sombra. Lo que se mece lleva la etiqueta
--      «ReefSway» (lo mueve el cliente: Controllers/ReefZoneFx, solo lo cercano).
--   3. Luz: 3 PointLight de verdad (la pirámide y la cueva), haces de luz (columnas Neon muy
--      transparentes) y 5 emisores de partículas con su fuente (plancton, motas, burbujas de una
--      fumarola, esporas y nieve marina).
--   Cuando llegan las mallas (MarMeshes, más tarde), se rehacen las piezas con ellas.
--
--   ReefZoneBuilder.build(yield)   ReefZoneBuilder.Stats

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ocean = require(ReplicatedStorage.Shared.Sea.Ocean)
local ReefZone = require(ReplicatedStorage.Shared.Sea.ReefZone)
local MarKit = require(ReplicatedStorage.Shared.Sea.MarKit)

local ReefZoneBuilder = {}
ReefZoneBuilder.Stats = { Fills = 0, Pieces = 0, Meshes = 0, Lights = 0, Emitters = 0 }
ReefZoneBuilder.State = "None"

local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles

local function rgb(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

local MATERIAL: { [string]: Enum.Material } = {
	Rock = Enum.Material.Rock,
	Limestone = Enum.Material.Limestone,
	Sandstone = Enum.Material.Sandstone,
	Salt = Enum.Material.Salt,
	Ground = Enum.Material.Ground,
	Mud = Enum.Material.Mud,
	Water = Enum.Material.Water,
}

local function folder(): Folder
	local mar = workspace:FindFirstChild("Mar")
	if not mar then
		mar = Instance.new("Folder")
		mar.Name = "Mar"
		mar.Parent = workspace
	end
	local f = mar:FindFirstChild("CanonDorada")
	if not f then
		f = Instance.new("Folder")
		f.Name = "CanonDorada"
		f.Parent = mar
	end
	return f :: Folder
end

local function model(name: string, parent: Instance): Model
	local m = Instance.new("Model")
	m.Name = name
	pcall(function()
		(m :: any).ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	pcall(function()
		(m :: any).LevelOfDetail = Enum.ModelLevelOfDetail.StreamingMesh
	end)
	m.Parent = parent
	return m
end

local function decorFlags(p: BasePart)
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
end

---------------------------------------------------------------------
-- 1. Terreno
---------------------------------------------------------------------
function ReefZoneBuilder.terrain(terrain: Terrain, yield: (() -> ())?)
	-- (los colores del fondo —arena dorada clara, arenisca, caliza— los pone World/TerrainBuilder.Colors)
	for _, op in ReefZone.ops() do
		local material = MATERIAL[op.Material] or Enum.Material.Rock
		if op.Kind == "Ball" then
			terrain:FillBall(V(op.X, op.Y, op.Z), op.R :: number, material)
		elseif op.Kind == "Cylinder" then
			terrain:FillCylinder(CF(op.X, op.Y, op.Z), op.H :: number, op.R :: number, material)
		else
			terrain:FillBlock(CF(op.X, op.Y, op.Z) * ANG(0, op.Yaw or 0, 0), V(op.SX :: number, op.SY :: number, op.SZ :: number), material)
		end
		ReefZoneBuilder.Stats.Fills += 1
		if yield then
			yield()
		end
	end
end

---------------------------------------------------------------------
-- 2. Piezas del kit
---------------------------------------------------------------------
local MATERIAL_BY_NAME: { [string]: Enum.Material } = {}
local function materialOf(name: string): Enum.Material
	local m = MATERIAL_BY_NAME[name]
	if not m then
		local ok, value = pcall(function()
			return (Enum.Material :: any)[name]
		end)
		m = if ok and value then value else Enum.Material.SmoothPlastic
		MATERIAL_BY_NAME[name] = m
	end
	return m :: Enum.Material
end

local SHAPES = { Ball = Enum.PartType.Ball, Cylinder = Enum.PartType.Cylinder }

-- El sitio de la pieza (pie en el suelo, girada y, en la pared, inclinada)
local function baseFrame(p: ReefZone.Placement): CFrame
	local cf = CF(p.X, p.Y, p.Z) * ANG(0, p.Yaw, 0)
	if p.Tilt then
		cf *= ANG(0, 0, p.Tilt)
	end
	return cf
end

-- Para la prueba: cuántas piezas de respaldo hace una pieza del kit
function ReefZoneBuilder.fallbackCount(p: ReefZone.Placement): number
	return #MarKit.fallback(p.Kind, p.Scale, rgb(p.Color), p.X + p.Z)
end

function ReefZoneBuilder.makePiece(p: ReefZone.Placement, parent: Instance, meshes: Folder?, budget: { Left: number }): Instance?
	local info = MarKit.Pieces[p.Kind]
	if not info then
		return nil
	end
	local base = baseFrame(p)
	local color = rgb(p.Color)
	local template = meshes and meshes:FindFirstChild(p.Kind)
	if template and template:IsA("MeshPart") then
		local k = p.Scale / info.Size[2]
		local m = template:Clone()
		m.Size = V(info.Size[1], info.Size[2], info.Size[3]) * k
		m.CFrame = base * CF(0, m.Size.Y / 2, 0)
		if info.Tint then
			m.Color = color
			m.Material = if p.Glow then Enum.Material.Neon else (if info.Group == "Coral" then Enum.Material.Salt else Enum.Material.SmoothPlastic)
		end
		decorFlags(m)
		m:SetAttribute("Pieza", p.Kind)
		if p.Sway then
			m:AddTag("ReefSway")
		end
		m.Parent = parent
		ReefZoneBuilder.Stats.Meshes += 1
		-- (las ruinas con textura: sus vetas que brillan van aparte, en Neon, como en el respaldo)
		if not info.Tint and info.Glow then
			for _, s in MarKit.fallback(p.Kind, p.Scale, color, 0) do
				if s.Glow then
					local g = Instance.new("Part")
					g.Name = "Veta"
					g.Size = s.Size
					g.CFrame = base * s.CFrame
					g.Color = s.Color
					g.Material = materialOf(s.Material)
					g.Transparency = s.Transparency or 0
					if s.Shape and SHAPES[s.Shape] then
						g.Shape = SHAPES[s.Shape]
					end
					decorFlags(g)
					g.Parent = m
				end
			end
		end
		return m
	end
	-- Respaldo de piezas (con tope: el móvil también carga esto)
	local specs = MarKit.fallback(p.Kind, p.Scale, color, p.X * 0.37 + p.Z * 0.11)
	if #specs > budget.Left then
		return nil
	end
	budget.Left -= #specs
	local holder = Instance.new("Model")
	holder.Name = p.Kind
	for _, s in specs do
		local part = Instance.new("Part")
		part.Size = s.Size
		part.CFrame = base * s.CFrame
		part.Color = s.Color
		part.Material = materialOf(s.Material)
		if s.Shape and SHAPES[s.Shape] then
			part.Shape = SHAPES[s.Shape]
		end
		if s.Mesh == "Sphere" then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = part
		end
		part.Transparency = s.Transparency or 0
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		decorFlags(part)
		part.Parent = holder
		ReefZoneBuilder.Stats.Pieces += 1
	end
	holder:SetAttribute("Pieza", p.Kind)
	if p.Sway then
		holder:AddTag("ReefSway")
	end
	holder.Parent = parent
	return holder
end

local decorRoot: Folder? = nil

function ReefZoneBuilder.decor(meshes: Folder?)
	if decorRoot then
		decorRoot:Destroy()
	end
	local root = Instance.new("Folder")
	root.Name = "Piezas"
	root.Parent = folder()
	decorRoot = root
	ReefZoneBuilder.Stats.Pieces = 0
	ReefZoneBuilder.Stats.Meshes = 0
	local groups: { [string]: Model } = {}
	-- (las piezas las ve todo el mundo, también el móvil: el tope es el del móvil)
	local budget = { Left = MarKit.PieceCap.Mobile }
	local floorFn = Ocean.floorY
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	params.IgnoreWater = true
	for _, p in ReefZone.placements(floorFn) do
		local g = groups[p.Group]
		if not g then
			g = model(p.Group, root)
			g:SetAttribute("Region", p.Region)
			groups[p.Group] = g
		end
		-- (en el terreno de verdad: se baja o se sube al suelo que hay, si está cerca)
		if not p.Tilt then
			local hit = workspace:Raycast(V(p.X, p.Y + 4, p.Z), V(0, -9, 0), params)
			if hit then
				p = table.clone(p)
				p.Y = hit.Position.Y - 0.25
			end
		end
		ReefZoneBuilder.makePiece(p, g, meshes, budget)
	end
end

---------------------------------------------------------------------
-- 3. Luz, haces y partículas
---------------------------------------------------------------------
local function anchorPart(name: string, cf: CFrame, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = V(0.4, 0.4, 0.4)
	p.CFrame = cf
	p.Transparency = 1
	decorFlags(p)
	p.Parent = parent
	return p
end

local EMITTERS = {
	-- (textura de Roblox de serie; tamaño, cuántas por segundo, velocidad, vida, color, transparencia)
	Plancton = { Rate = 6, Size = 0.18, Speed = 0.4, Life = 14, Color = Color3.fromRGB(220, 245, 255), Light = 0.3 },
	Motas = { Rate = 3, Size = 0.5, Speed = 0.25, Life = 10, Color = Color3.fromRGB(255, 250, 220), Light = 0.6 },
	Burbujas = { Rate = 5, Size = 0.35, Speed = 6, Life = 6, Color = Color3.fromRGB(230, 250, 255), Light = 0.4, Up = true },
	Esporas = { Rate = 4, Size = 0.25, Speed = 0.5, Life = 9, Color = Color3.fromRGB(150, 255, 210), Light = 1 },
	Nieve = { Rate = 8, Size = 0.22, Speed = 0.8, Life = 16, Color = Color3.fromRGB(200, 215, 230), Light = 0.1, Down = true },
}

function ReefZoneBuilder.light()
	local f = folder()
	local old = f:FindFirstChild("Luz")
	if old then
		old:Destroy()
	end
	local m = model("Luz", f)
	for _, l in ReefZone.Lights do
		local x, z = ReefZone.where(l)
		local y = l.Y or ((Ocean.floorY(x, z) or -40) + (l.Lift or 0))
		local holder = anchorPart("Luz" .. l.Name, CF(x, y, z), m)
		local light = Instance.new("PointLight")
		light.Color = rgb(l.Color)
		light.Range = l.Range
		light.Brightness = l.Brightness
		light.Shadows = false
		light.Parent = holder
		ReefZoneBuilder.Stats.Lights += 1
	end
	for i, s in ReefZone.Shafts do
		local x, z = ReefZone.where(s)
		local h = s.Top - s.Bottom
		local shaft = Instance.new("Part")
		shaft.Name = "Haz" .. i
		shaft.Shape = Enum.PartType.Cylinder
		shaft.Size = V(h, s.R * 2, s.R * 2)
		shaft.CFrame = CF(x, (s.Top + s.Bottom) / 2, z) * ANG(s.Tilt or 0, 0, 0) * ANG(0, 0, math.pi / 2)
		shaft.Material = Enum.Material.Neon
		shaft.Color = Color3.fromRGB(190, 240, 255)
		shaft.Transparency = 0.92
		decorFlags(shaft)
		shaft:SetAttribute("Haz", true) -- (ReefZoneFx lo atenúa de noche)
		shaft.Parent = m
	end
	for _, e in ReefZone.Emitters do
		local x, z = ReefZone.where(e)
		local spec = EMITTERS[e.Kind]
		if spec then
			local box = Instance.new("Part")
			box.Name = "Emisor" .. e.Kind
			box.Size = V(e.Size, if spec.Up then 1 else e.Size * 0.5, e.Size)
			box.CFrame = CF(x, e.Y, z)
			box.Transparency = 1
			decorFlags(box)
			local pe = Instance.new("ParticleEmitter")
			pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			pe.Rate = spec.Rate
			pe.Lifetime = NumberRange.new(spec.Life * 0.7, spec.Life)
			pe.Speed = NumberRange.new(spec.Speed * 0.5, spec.Speed)
			pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, spec.Size * 0.6), NumberSequenceKeypoint.new(0.5, spec.Size), NumberSequenceKeypoint.new(1, spec.Size * 0.3) })
			pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.35), NumberSequenceKeypoint.new(0.8, 0.45), NumberSequenceKeypoint.new(1, 1) })
			pe.Color = ColorSequence.new(spec.Color)
			pe.LightEmission = spec.Light
			pe.SpreadAngle = Vector2.new(180, 180)
			pe.Acceleration = if spec.Up then V(0, 3, 0) elseif spec.Down then V(0, -0.3, 0) else V(0, 0.05, 0)
			if spec.Up then
				pe.SpreadAngle = Vector2.new(8, 8)
				pe.EmissionDirection = Enum.NormalId.Top
			end
			pe.Parent = box
			box.Parent = m
			ReefZoneBuilder.Stats.Emitters += 1
		end
	end
end

---------------------------------------------------------------------

function ReefZoneBuilder.build(yield: (() -> ())?)
	if ReefZoneBuilder.State ~= "None" then
		return
	end
	ReefZoneBuilder.State = "Building"
	local started = os.clock()
	ReefZoneBuilder.terrain(require(script.Parent.TerrainCarve).wrap(workspace.Terrain), yield) -- (el agua de las cuevas abre con aire antes)
	local MarMeshes = require(script.Parent.MarMeshes)
	ReefZoneBuilder.decor(MarMeshes.folder())
	ReefZoneBuilder.light()
	-- Si las mallas llegan después, las piezas se rehacen con ellas
	MarMeshes.start(function()
		local ok, err = pcall(ReefZoneBuilder.decor, MarMeshes.folder())
		if not ok then
			warn("[ReefZone] mallas: " .. tostring(err))
		end
	end)
	ReefZoneBuilder.State = "Ready"
	workspace:SetAttribute("ReefZoneReady", true)
	local s = ReefZoneBuilder.Stats
	print(("[ReefZone] Cañón de Dorada: %d rellenos, %d piezas de respaldo, %d mallas, %d luces, %d emisores (%.1f s)"):format(s.Fills, s.Pieces, s.Meshes, s.Lights, s.Emitters, os.clock() - started))
end

return ReefZoneBuilder
