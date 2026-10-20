-- StageBuilders: cómo se DIBUJA cada decorado de la historia (shared/LifeStory/StageSets). Por código,
-- con piezas y texturas internas. Sirven en los dos lados: el cliente dibuja los decorados que son
-- solo tuyos (Controllers/StageSetsClient) y el servidor los que son de todos (WorldMemoryService).
-- Sin servicios de Roblox: se prueban fuera (scripts/test-worldmemory.luau).
--
--   StageBuilders.build(name, parent, cframe, params, tier) -> { Model, Update? (dt, t) }
--     Update (si lo hay) anima el decorado: la criatura que vive en el cráter hace su rutina.

local StoryFxBuild = require(script.Parent.StoryFxBuild)
local StoryCreatures = require(script.Parent.LifeStory.StoryCreatures)

local StageBuilders = {}

local V = Vector3.new

export type Built = { Model: Model, Update: ((dt: number, t: number) -> ())? }

local function piece(parent: Instance, props: { [string]: any }): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local Builders: { [string]: (parent: Instance, cf: CFrame, params: { [string]: any }, tier: string) -> Built } = {}

-- Cráter (el de las estrellas fugaces, explosiones…)
Builders.Crater = function(parent, cf, params, tier)
	local model = StoryFxBuild.crater(parent, cf, {
		Name = params.Name or "Crater",
		Radius = params.Radius or 4,
		Depth = params.Depth,
		Rim = params.Rim,
		Floor = params.Floor,
		Glow = if params.Glow then (params.GlowColor or Color3.fromRGB(120, 255, 170)) else nil,
		Smoke = params.Smoke == true,
		Tier = tier,
		Seed = params.Seed,
	})
	return { Model = model }
end

-- Un habitante con rutina: una criatura pequeña hecha de piezas que va de un punto a otro alrededor
-- de su sitio, se para, mira y da saltitos (Params.Creature = StoryCreatures, Params.Routine = puntos
-- { x, z } relativos, Params.Pause = segundos parado en cada uno)
Builders.Resident = function(parent, cf, params, _tier)
	local creature = StoryCreatures.get(params.Creature) or {}
	local skin = StoryCreatures.rgb(creature.Skin) or Color3.fromRGB(120, 230, 150)
	local glowColor = StoryCreatures.rgb(creature.Glow)
	local k = math.clamp((creature.Scale or 0.5) * 2.2, 0.4, 3)
	local model = Instance.new("Model")
	model.Name = creature.Name or "Habitante"
	local body = piece(model, { Name = "Cuerpo", Shape = Enum.PartType.Ball, Size = V(1.3, 1.5, 1.2) * k, Color = skin, Material = Enum.Material.SmoothPlastic })
	local head = piece(model, { Name = "Cabeza", Shape = Enum.PartType.Ball, Size = V(1.25, 1.2, 1.2) * k, Color = skin, Material = Enum.Material.SmoothPlastic })
	local parts: { { Part: BasePart, Offset: CFrame } } = {
		{ Part = body, Offset = CFrame.new(0, 0.75 * k, 0) },
		{ Part = head, Offset = CFrame.new(0, 1.85 * k, -0.05 * k) },
	}
	local function add(name: string, shape: Enum.PartType, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?)
		local p = piece(model, { Name = name, Shape = shape, Size = size * k, Color = color, Material = material or Enum.Material.SmoothPlastic })
		table.insert(parts, { Part = p, Offset = offset })
		return p
	end
	add("OjoI", Enum.PartType.Ball, V(0.42, 0.42, 0.2), CFrame.new(-0.25 * k, 1.95 * k, -0.6 * k), Color3.new(1, 1, 1))
	add("OjoD", Enum.PartType.Ball, V(0.42, 0.42, 0.2), CFrame.new(0.25 * k, 1.95 * k, -0.6 * k), Color3.new(1, 1, 1))
	add("PupilaI", Enum.PartType.Ball, V(0.2, 0.2, 0.1), CFrame.new(-0.25 * k, 1.93 * k, -0.69 * k), Color3.fromRGB(20, 30, 25))
	add("PupilaD", Enum.PartType.Ball, V(0.2, 0.2, 0.1), CFrame.new(0.25 * k, 1.93 * k, -0.69 * k), Color3.fromRGB(20, 30, 25))
	add("AntenaI", Enum.PartType.Block, V(0.1, 0.9, 0.1), CFrame.new(-0.3 * k, 2.75 * k, 0) * CFrame.Angles(0, 0, math.rad(15)), skin)
	add("AntenaD", Enum.PartType.Block, V(0.1, 0.9, 0.1), CFrame.new(0.3 * k, 2.75 * k, 0) * CFrame.Angles(0, 0, math.rad(-15)), skin)
	local tip = add("Punta", Enum.PartType.Ball, V(0.3, 0.3, 0.3), CFrame.new(0.42 * k, 3.2 * k, 0), glowColor or Color3.fromRGB(200, 255, 120), Enum.Material.Neon)
	add("PuntaI", Enum.PartType.Ball, V(0.3, 0.3, 0.3), CFrame.new(-0.42 * k, 3.2 * k, 0), glowColor or Color3.fromRGB(200, 255, 120), Enum.Material.Neon)
	if glowColor then
		local l = Instance.new("PointLight")
		l.Color = glowColor
		l.Range = 8
		l.Brightness = 1.2
		l.Shadows = false
		l.Parent = tip
	end
	model.PrimaryPart = body
	local routine = params.Routine or { { 0, 0 } }
	local pause = params.Pause or 1.5
	local speed = 3.2 * k
	local index = 1
	local here = cf.Position
	local target = (cf * CFrame.new(routine[1][1] or 0, 0, routine[1][2] or 0)).Position
	local waitLeft = 0
	local heading = cf.LookVector
	local function place(t: number)
		local hop = if waitLeft > 0 then math.abs(math.sin(t * 6)) * 0.35 * k else math.abs(math.sin(t * 12)) * 0.15 * k
		local flat = V(heading.X, 0, heading.Z)
		local root = if flat.Magnitude > 0.01 then CFrame.lookAt(here, here + flat) else CFrame.new(here)
		root *= CFrame.new(0, hop, 0)
		for _, entry in parts do
			entry.Part.CFrame = root * entry.Offset
		end
	end
	place(0)
	model.Parent = parent
	return {
		Model = model,
		Update = function(dt: number, t: number)
			if waitLeft > 0 then
				waitLeft -= dt
				-- parado: mira alrededor
				heading = CFrame.Angles(0, math.sin(t * 1.3) * 0.02, 0):VectorToWorldSpace(heading)
			else
				local to = target - here
				to = V(to.X, 0, to.Z)
				if to.Magnitude < 0.2 then
					index = index % #routine + 1
					local point = routine[index]
					target = (cf * CFrame.new(point[1] or 0, 0, point[2] or 0)).Position
					waitLeft = pause
				else
					local step = math.min(to.Magnitude, speed * dt)
					here += to.Unit * step
					heading = to.Unit
				end
			end
			place(t)
		end,
	}
end

-- Una marca sencilla (monolito con luz): placa conmemorativa, baliza, anclaje…
Builders.Marker = function(parent, cf, params, tier)
	local model = Instance.new("Model")
	model.Name = params.Name or "Marca"
	local color = params.Color or Color3.fromRGB(120, 255, 170)
	piece(model, { Name = "Base", Size = V(2.4, 0.4, 2.4), CFrame = cf * CFrame.new(0, 0.2, 0), Color = Color3.fromRGB(90, 90, 96), Material = Enum.Material.Concrete, CanCollide = true, CanQuery = true })
	piece(model, { Name = "Pilar", Size = V(1, 3, 1), CFrame = cf * CFrame.new(0, 1.9, 0), Color = Color3.fromRGB(60, 60, 66), Material = Enum.Material.Slate, CanCollide = true, CanQuery = true })
	local top = piece(model, { Name = "Luz", Shape = Enum.PartType.Ball, Size = V(0.9, 0.9, 0.9), CFrame = cf * CFrame.new(0, 3.8, 0), Color = color, Material = Enum.Material.Neon })
	if tier ~= "Low" then
		local l = Instance.new("PointLight")
		l.Color = color
		l.Range = 10
		l.Brightness = 1.5
		l.Shadows = false
		l.Parent = top
	end
	model.Parent = parent
	return { Model = model }
end

StageBuilders.Builders = Builders

function StageBuilders.names(): { [string]: boolean }
	local set = {}
	for name in Builders do
		set[name] = true
	end
	return set
end

function StageBuilders.build(name: string, parent: Instance, cf: CFrame, params: { [string]: any }?, tier: string?): Built?
	local builder = Builders[name]
	if not builder then
		return nil
	end
	return builder(parent, cf, params or {}, tier or "Medium")
end

return StageBuilders
