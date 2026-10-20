-- AsteroidBuild: monta un asteroide en piezas de Roblox con la forma de shared/Cosmos/Asteroids
-- (docs/espacio-aaa/asteroides.md). Lo usan el servidor (World/SpaceWorld: los asteroides del campo) y
-- el cliente (Controllers/AsteroidFx: los trozos al romperse), así son iguales.
--
--   AsteroidBuild.make(id, radio, mineral, campo, cf, opts) -> Model
--       opts.Meshes  carpeta con las mallas de Blender (ReplicatedStorage.AsteroideMallas: una MeshPart
--                    por variante, con atributo "Variante" y "Medida" = tamaño de la caja en radios). Si
--                    no hay malla para esa variante, el núcleo se hace con bloques y cuñas (el respaldo).
--       opts.Shadows las piezas grandes del núcleo proyectan sombra
--   AsteroidBuild.setDamage(model, nivel 0..3)   grietas que brillan (y una luz cálida desde el nivel 2)
--   AsteroidBuild.setDetail(model, visible)      LOD: de lejos sin vetas, cráteres ni piedrecitas
--
-- Todo es decorado: sin colisión ni consultas (los choques y disparos van con esferas: Zone).

local Asteroids = require(script.Parent.Asteroids)

local AsteroidBuild = {}

local CLASS = { Block = "Part", Wedge = "WedgePart", CornerWedge = "CornerWedgePart", Cylinder = "Part" }

local function newPart(class: string, props: { [string]: any }, parent: Instance): BasePart
	local p = Instance.new(class) :: BasePart
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

-- La malla de una variante (si se han subido y cargado)
local function meshFor(meshes: Instance?, variant: number): BasePart?
	if not meshes then
		return nil
	end
	for _, m in meshes:GetChildren() do
		if m:IsA("BasePart") and m:GetAttribute("Variante") == variant then
			return m
		end
	end
	return nil
end

export type Opts = { Meshes: Instance?, Shadows: boolean? }

function AsteroidBuild.make(id: string, radius: number, ore: string?, field: string?, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local shape = Asteroids.shape(id, radius, ore, field)
	local model = Instance.new("Model")
	model.Name = "Asteroide"
	local detail = Instance.new("Folder")
	detail.Name = "Detalle"
	detail.Parent = model
	local mesh = meshFor(o.Meshes, shape.Variant)
	local semi = Vector3.one * radius
	local primary: BasePart? = nil
	if mesh then
		-- Núcleo de malla (Blender): una sola MeshPart del tamaño de su caja (en radios)
		local size = mesh:GetAttribute("Medida")
		local box = if typeof(size) == "Vector3" then size * radius else Vector3.one * radius * 2
		semi = box / 2
		local core = mesh:Clone()
		core.Name = "Core"
		core.Anchored = true
		core.CanCollide = false
		core.CanQuery = false
		core.CanTouch = false
		core.CastShadow = o.Shadows == true
		core.Size = box
		core.CFrame = cf
		core:SetAttribute("Role", "Core")
		core.Parent = model
		primary = core
	end
	for _, piece in shape.Pieces do
		local role = piece.Role
		if mesh and (role == "Core" or role == "Facet" or role == "Crater" or role == "Rim") then
			continue
		end
		local rel = piece.CFrame
		if mesh and (role == "Vein" or role == "Crack" or role == "Shard") then
			-- (con malla: la veta o la grieta se pone sobre la superficie del elipsoide de la malla)
			local p = rel.Position
			if p.Magnitude > 1e-3 then
				local d = p.Unit
				local k = 1 / math.sqrt((d.X / semi.X) ^ 2 + (d.Y / semi.Y) ^ 2 + (d.Z / semi.Z) ^ 2)
				rel = CFrame.new(d * k * 0.9) * CFrame.new(-p) * rel
			end
		end
		local props: { [string]: any } = {
			Name = role,
			Size = piece.Size,
			CFrame = cf * rel,
			Color = piece.Color,
			Material = piece.Material,
			Transparency = piece.Transparency,
			CastShadow = o.Shadows == true and (role == "Core" or role == "Facet") and radius >= 30,
		}
		if piece.Kind == "Cylinder" then
			props.Shape = Enum.PartType.Cylinder
		end
		local part = newPart(CLASS[piece.Kind] or "Part", props, if piece.Detail then detail else model)
		part:SetAttribute("Role", role)
		if piece.Stage then
			part:SetAttribute("Stage", piece.Stage)
		end
		if role == "Vein" then
			part:SetAttribute("Vein", id)
			part:SetAttribute("BaseTransparency", piece.Transparency)
		end
		if role == "Core" and not primary then
			primary = part
		end
	end
	model.PrimaryPart = primary
	model:SetAttribute("Variante", shape.VariantName)
	return model
end

-- Polvo fino que flota alrededor (los grandes): un emisor lento y barato
function AsteroidBuild.dust(model: Model, radius: number, color: Color3)
	local core = model.PrimaryPart
	if not core then
		return
	end
	local a = Instance.new("Attachment")
	a.Name = "Polvo"
	a.Parent = core
	local e = Instance.new("ParticleEmitter")
	e.Name = "Polvo"
	e.Rate = 1.2
	e.Lifetime = NumberRange.new(7, 11)
	e.Speed = NumberRange.new(0.6, 2.2)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new(radius * 0.18, radius * 0.32)
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.86), NumberSequenceKeypoint.new(1, 1) })
	e.Color = ColorSequence.new(color)
	e.LightEmission = 0
	e.LightInfluence = 1
	e.RotSpeed = NumberRange.new(-8, 8)
	e.Rotation = NumberRange.new(0, 360)
	e.Parent = a
end

function AsteroidBuild.setDamage(model: Model, stage: number)
	local hot = false
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("Role") == "Crack" then
			local s = d:GetAttribute("Stage")
			local on = type(s) == "number" and s <= stage
			d.Transparency = if on then 0.1 else 1
			hot = hot or on
		end
	end
	model:SetAttribute("Dano", stage)
	local core = model.PrimaryPart
	if core then
		local light = core:FindFirstChild("Brasa")
		if stage >= 2 and not light then
			local l = Instance.new("PointLight")
			l.Name = "Brasa"
			l.Color = Asteroids.CrackColor
			l.Brightness = 0.8
			l.Range = math.clamp(core.Size.Magnitude * 0.5, 8, 50)
			l.Shadows = false
			l.Parent = core
		elseif stage < 2 and light then
			light:Destroy()
		end
	end
end

function AsteroidBuild.setDetail(model: Model, visible: boolean)
	local folder = model:FindFirstChild("Detalle")
	if not folder then
		return
	end
	local k = if visible then 0 else 1
	for _, d in folder:GetChildren() do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = k
		end
	end
end

return AsteroidBuild
