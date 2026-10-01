-- StoryFxBuild: CONSTRUYE los efectos del catálogo (shared/StoryFxCatalog) con piezas, partículas,
-- estelas y luces hechas por código. No usa servicios de Roblox (ni TweenService ni RunService): cada
-- efecto devuelve un «handle» que se anima llamando a Update(dt, t) en cada fotograma. Así lo mueve
-- Controllers/StoryFx en el juego y lo prueba scripts/test-vfx.luau fuera de Roblox.
--
--   local h = StoryFxBuild.build(name, ctx)
--     ctx = { CFrame, To?, Seconds?, Params?, Tier = "Low"|"Medium"|"High", Parent, Model?,
--             Squeeze? (0..1, tope global de partículas), Emit = function(kind, ...) }
--   h.Update(dt, t) -> boolean   (false = ha terminado: el que lo mueve llama a h.Destroy())
--   h.Stop()                     (empieza a terminar: el portal se cierra, el humo se apaga…)
--   h.Destroy()                  (quita todo ya)
--   h.Position() -> Vector3?     (dónde está ahora: la cámara puede seguir al meteorito)
--   h.Rate                       (partículas por segundo que gasta, para el tope global)
--
-- Lo que no puede hacer él solo lo pide con ctx.Emit (lo hace el cliente):
--   "Sound", nombreDeSonido, posición          "Shake", fuerza, segundos, posición, radio
--   "Flash", cantidad, color, segundos          "Sky", ánimo, fundido   /   "SkyPop", fundido
--   "Chain", receta, cframe                     (otro efecto: el impacto del meteorito)
--
-- StoryFxBuild.crater(parent, cframe, opts) también lo usan los decorados (cráter que se queda).

local Catalog = require(script.Parent.StoryFxCatalog)

local StoryFxBuild = {}

local V = Vector3.new
local TEX = Catalog.Textures

export type Handle = {
	Name: string,
	Update: (dt: number, t: number) -> boolean,
	Stop: () -> (),
	Destroy: () -> (),
	Position: () -> Vector3?,
	Rate: number,
	Root: Instance,
}

---------------------------------------------------------------------
-- Piezas
---------------------------------------------------------------------
local function new(className: string, props: { [string]: any }, parent: Instance?): any
	local obj = Instance.new(className)
	for k, v in props do
		(obj :: any)[k] = v
	end
	if parent then
		obj.Parent = parent
	end
	return obj
end

-- Pieza de adorno: anclada, sin choques, sin sombra, sin que la toquen los rayos ni los botones
local function piece(parent: Instance, props: { [string]: any }): BasePart
	local p = new("Part", {
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		TopSurface = Enum.SurfaceType.Smooth,
		BottomSurface = Enum.SurfaceType.Smooth,
	}, nil)
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local function seq(a: number, b: number?, c: number?): NumberSequence
	if b == nil then
		return NumberSequence.new(a)
	end
	if c == nil then
		return NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b) })
	end
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(0.5, b), NumberSequenceKeypoint.new(1, c) })
end

local function colors(a: Color3, b: Color3?): ColorSequence
	return if b then ColorSequence.new(a, b) else ColorSequence.new(a)
end

-- Emisor de partículas con presupuesto (rate ya multiplicado por el nivel y el tope)
local function emitter(parent: Instance, props: { [string]: any }): ParticleEmitter
	local e = new("ParticleEmitter", {
		LightEmission = 0.5,
		LockedToPart = false,
		Enabled = true,
	}, nil)
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = parent
	return e
end

local function light(parent: Instance, spec: { [string]: any }?, shadows: boolean): PointLight?
	if not spec then
		return nil
	end
	return new("PointLight", {
		Color = spec.Color or Color3.new(1, 1, 1),
		Range = spec.Range or 16,
		Brightness = spec.Brightness or 2,
		Shadows = shadows,
	}, parent)
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function clamp01(x: number): number
	return math.clamp(x, 0, 1)
end

-- Contexto común de un efecto: carpeta, presupuesto y cuenta de partículas
type Build = {
	Name: string,
	Recipe: { [string]: any },
	Ctx: { [string]: any },
	Folder: Instance,
	Budget: Catalog.Budget,
	Scale: number,
	Rate: number,
	Rng: Random,
}

local function begin(name: string, recipe: { [string]: any }, ctx: { [string]: any }): Build
	local folder = new("Folder", { Name = "Fx_" .. name }, ctx.Parent)
	local params = ctx.Params or {}
	return {
		Name = name,
		Recipe = recipe,
		Ctx = ctx,
		Folder = folder,
		Budget = Catalog.budget(ctx.Tier),
		Scale = math.clamp(tonumber(params.Scale) or 1, 0.2, 6),
		Rate = 0,
		Rng = Random.new(tonumber(params.Seed) or 7),
	}
end

-- Partículas por segundo de una capa con el presupuesto (y apuntadas en el total del efecto)
local function rate(b: Build, base: number?): number
	local r = Catalog.rate(base, b.Ctx.Tier, b.Scale) * (b.Ctx.Squeeze or 1)
	r = math.floor(r + 0.5)
	b.Rate += r
	return r
end

local function emit(b: Build, ...)
	local fn = b.Ctx.Emit
	if fn then
		fn(...)
	end
end

local function handle(b: Build, update: (dt: number, t: number) -> boolean, stop: (() -> ())?, position: (() -> Vector3?)?): Handle
	local destroyed = false
	local h: Handle
	h = {
		Name = b.Name,
		Rate = b.Rate,
		Root = b.Folder,
		Update = function(dt: number, t: number): boolean
			if destroyed then
				return false
			end
			return update(dt, t)
		end,
		Stop = function()
			if stop and not destroyed then
				stop()
			end
		end,
		Destroy = function()
			if not destroyed then
				destroyed = true
				b.Folder:Destroy()
			end
		end,
		Position = function(): Vector3?
			if position then
				return position()
			end
			return (b.Ctx.CFrame :: CFrame).Position
		end,
	}
	return h
end

---------------------------------------------------------------------
-- Cráter (también para los decorados que se quedan: StageSets)
---------------------------------------------------------------------
-- opts: Radius, Depth, Rim, Floor, Glow (Color3 o nil), Smoke (bool), Tier, Seed, Name
function StoryFxBuild.crater(parent: Instance, cf: CFrame, opts: { [string]: any }?): Model
	local o = opts or {}
	local radius = o.Radius or 5
	local tier = Catalog.tierName(o.Tier)
	local rng = Random.new(o.Seed or 11)
	local model = new("Model", { Name = o.Name or "Crater" }, nil)
	local base = cf * CFrame.new(0, 0.04, 0)
	-- Suelo quemado (disco aplastado) y el fondo, algo más oscuro
	local flat = CFrame.Angles(0, 0, math.rad(90))
	piece(model, {
		Name = "Quemado",
		Shape = Enum.PartType.Cylinder,
		Size = V(0.08, radius * 2.6, radius * 2.6),
		CFrame = base * flat,
		Color = (o.Floor or Color3.fromRGB(34, 30, 28)):Lerp(Color3.fromRGB(70, 64, 56), 0.4),
		Material = Enum.Material.Slate,
		Transparency = 0.15,
	})
	local floor = piece(model, {
		Name = "Fondo",
		Shape = Enum.PartType.Cylinder,
		Size = V(0.12, radius * 1.7, radius * 1.7),
		CFrame = base * CFrame.new(0, 0.05, 0) * flat,
		Color = o.Floor or Color3.fromRGB(34, 30, 28),
		Material = Enum.Material.Basalt,
	})
	-- Borde: rocas levantadas en anillo, inclinadas hacia fuera (menos en gráficos Bajo)
	local rocks = if tier == "Low" then 8 elseif tier == "Medium" then 12 else 16
	for i = 1, rocks do
		local a = (i / rocks) * math.pi * 2 + rng:NextNumber(-0.12, 0.12)
		local r = radius * rng:NextNumber(0.85, 1.05)
		local size = V(rng:NextNumber(1.2, 2.2), rng:NextNumber(0.6, 1.3) * (o.Depth or 1.2), rng:NextNumber(1.6, 2.8)) * math.clamp(radius / 5, 0.4, 3)
		local pos = base * CFrame.new(math.cos(a) * r, size.Y * 0.3, math.sin(a) * r)
		local rock = piece(model, {
			Name = "Roca",
			Size = size,
			CFrame = CFrame.new(pos.Position) * base.Rotation * CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(18, 34))),
			Color = (o.Rim or Color3.fromRGB(96, 86, 74)):Lerp(Color3.new(0, 0, 0), rng:NextNumber(0, 0.25)),
			Material = Enum.Material.Rock,
			CanCollide = true,
			CanQuery = true,
		})
		rock.CastShadow = tier ~= "Low"
	end
	-- Lo que brilla en el fondo (lo que cayó aún está caliente)
	if o.Glow then
		local core = piece(model, {
			Name = "Brillo",
			Shape = Enum.PartType.Ball,
			Size = V(1, 0.45, 1) * math.clamp(radius / 4, 0.5, 3),
			CFrame = base * CFrame.new(0, 0.15, 0),
			Color = o.Glow,
			Material = Enum.Material.Neon,
			Transparency = 0.15,
		})
		new("PointLight", { Color = o.Glow, Range = radius * 3, Brightness = 1.6, Shadows = false }, core)
		if tier ~= "Low" then
			emitter(core, {
				Name = "Chispas",
				Texture = TEX.Sparkles,
				Rate = if tier == "High" then 8 else 4,
				Lifetime = NumberRange.new(0.8, 1.6),
				Speed = NumberRange.new(1, 3),
				SpreadAngle = Vector2.new(25, 25),
				EmissionDirection = Enum.NormalId.Top,
				Size = seq(0.25, 0),
				Color = colors(o.Glow),
				LightEmission = 1,
			})
		end
	end
	if o.Smoke then
		emitter(floor, {
			Name = "Humo",
			Texture = TEX.Smoke,
			Rate = if tier == "Low" then 2 elseif tier == "Medium" then 5 else 8,
			Lifetime = NumberRange.new(3, 5),
			Speed = NumberRange.new(1.5, 3),
			SpreadAngle = Vector2.new(12, 12),
			EmissionDirection = Enum.NormalId.Right, -- (el cilindro está tumbado: su eje X apunta arriba)
			Size = seq(1.5 * radius / 5, 5 * radius / 5),
			Transparency = seq(0.55, 1),
			Color = colors(Color3.fromRGB(110, 112, 108)),
			LightEmission = 0,
			Acceleration = V(0.6, 0.8, 0),
			RotSpeed = NumberRange.new(-20, 20),
			Rotation = NumberRange.new(0, 360),
		})
	end
	model.Parent = parent
	return model
end

---------------------------------------------------------------------
-- Los tipos de efecto
---------------------------------------------------------------------
local Kinds: { [string]: (Build) -> Handle } = {}

-- Meteorito: cae del punto de salida al destino con estela, fuego, humo y chispas; al llegar, impacto
Kinds.Meteor = function(b: Build): Handle
	local r, ctx = b.Recipe, b.Ctx
	local start = (ctx.CFrame :: CFrame).Position
	local finish = if ctx.To then (ctx.To :: CFrame).Position else start + V(0, -120, 0)
	local seconds = math.max(ctx.Seconds or r.Seconds or 2.5, 0.2)
	local size = (r.Size or 2) * b.Scale
	-- Curva: el punto de control se levanta y se aparta un poco (no cae en línea recta)
	local mid = start:Lerp(finish, 0.5)
	local control = mid + V(0, (start - finish).Magnitude * (r.Arc or 0.1), 0)
	local core = piece(b.Folder, {
		Name = "Nucleo",
		Shape = Enum.PartType.Ball,
		Size = V(size, size, size),
		CFrame = CFrame.new(start),
		Color = r.Core,
		Material = Enum.Material.Neon,
	})
	local a0 = new("Attachment", { Position = V(0, size * 0.35, 0) }, core)
	local a1 = new("Attachment", { Position = V(0, -size * 0.35, 0) }, core)
	new("Trail", {
		Attachment0 = a0,
		Attachment1 = a1,
		Lifetime = if b.Budget.Extras then 0.9 else 0.5,
		Color = colors(r.Trail, r.Fire[2]),
		Transparency = seq(0.05, 1),
		WidthScale = seq(1, 0.1),
		LightEmission = 1,
		FaceCamera = true,
	}, core)
	local fire = new("Attachment", {}, core)
	emitter(fire, {
		Name = "Fuego",
		Texture = TEX.Fire,
		Rate = rate(b, r.Rate.Fire),
		Lifetime = NumberRange.new(0.25, 0.5),
		Speed = NumberRange.new(1, 3),
		SpreadAngle = Vector2.new(25, 25),
		Size = seq(size * 1.4, size * 0.4),
		Color = colors(r.Fire[1], r.Fire[2]),
		Transparency = seq(0.1, 1),
		LightEmission = 1,
	})
	emitter(fire, {
		Name = "Humo",
		Texture = TEX.Smoke,
		Rate = rate(b, r.Rate.Smoke),
		Lifetime = NumberRange.new(1.2, 2.2),
		Speed = NumberRange.new(0.5, 1.5),
		Size = seq(size * 0.8, size * 2.6),
		Color = colors(r.SmokeColor),
		Transparency = seq(0.45, 1),
		LightEmission = 0,
		RotSpeed = NumberRange.new(-30, 30),
	})
	if b.Budget.Extras then
		emitter(fire, {
			Name = "Chispas",
			Texture = TEX.Sparkles,
			Rate = rate(b, r.Rate.Sparks),
			Lifetime = NumberRange.new(0.4, 0.9),
			Speed = NumberRange.new(4, 9),
			SpreadAngle = Vector2.new(60, 60),
			Size = seq(0.4, 0),
			Color = colors(r.Trail),
			LightEmission = 1,
		})
	end
	light(core, r.Light, b.Budget.Shadows)
	emit(b, "Sound", r.Sound, start)
	local position = start
	local landed = false
	return handle(b, function(_dt: number, t: number): boolean
		local u = clamp01(t / seconds)
		local k = u * u -- acelera al caer
		local p = start:Lerp(control, k):Lerp(control:Lerp(finish, k), k)
		local ahead = start:Lerp(control, math.min(1, k + 0.02)):Lerp(control:Lerp(finish, math.min(1, k + 0.02)), math.min(1, k + 0.02))
		position = p
		if (ahead - p).Magnitude > 0.01 then
			core.CFrame = CFrame.lookAt(p, ahead) * CFrame.Angles(math.rad(90), 0, 0)
		else
			core.CFrame = CFrame.new(p)
		end
		if u >= 1 and not landed then
			landed = true
			if r.Impact then
				emit(b, "Chain", r.Impact, CFrame.new(finish))
			end
			return false
		end
		return true
	end, nil, function()
		return position
	end)
end

-- Impacto / explosión: destello, onda, bola de fuego, humo, fuego, chispas, escombros, mancha quemada
Kinds.Impact = function(b: Build): Handle
	local r, ctx = b.Recipe, b.Ctx
	local cf: CFrame = ctx.CFrame
	local origin = cf.Position
	local s = b.Scale
	local seconds = ctx.Seconds or r.Seconds or 6
	local flash = piece(b.Folder, {
		Name = "Destello",
		Shape = Enum.PartType.Ball,
		Size = V(2, 2, 2),
		CFrame = CFrame.new(origin + V(0, 1, 0)),
		Color = r.Flash.Color,
		Material = Enum.Material.Neon,
		Transparency = 0,
	})
	local flashLight = light(flash, { Color = r.Flash.Color, Range = r.Flash.Range * math.min(s, 2), Brightness = r.Flash.Brightness }, b.Budget.Shadows) :: PointLight
	local shock = piece(b.Folder, {
		Name = "Onda",
		Shape = Enum.PartType.Cylinder,
		Size = V(0.3, r.Shock.From * s, r.Shock.From * s),
		CFrame = CFrame.new(origin + V(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = r.Shock.Color,
		Material = Enum.Material.Neon,
		Transparency = 0.2,
	})
	local fireball = piece(b.Folder, {
		Name = "BolaDeFuego",
		Shape = Enum.PartType.Ball,
		Size = V(1, 1, 1),
		CFrame = CFrame.new(origin + V(0, 1.5, 0)),
		Color = r.Fireball.Color,
		Material = Enum.Material.Neon,
		Transparency = 0.1,
	})
	-- Emisores (un soporte invisible en el suelo)
	local base = piece(b.Folder, { Name = "Base", Size = V(r.Radius * s, 0.2, r.Radius * s), CFrame = CFrame.new(origin + V(0, 0.3, 0)), Transparency = 1 })
	local smoke = emitter(base, {
		Name = "Humo",
		Texture = TEX.Smoke,
		Rate = rate(b, r.Smoke.Rate),
		Lifetime = NumberRange.new(2.5, 4.5),
		Speed = NumberRange.new(4, 9),
		SpreadAngle = Vector2.new(35, 35),
		EmissionDirection = Enum.NormalId.Top,
		Size = seq(r.Smoke.Size * s * 0.5, r.Smoke.Size * s * 1.6),
		Color = colors(r.Smoke.Color),
		Transparency = seq(0.3, 1),
		LightEmission = 0,
		Acceleration = V(0, 1.5, 0),
		Drag = 1.2,
		RotSpeed = NumberRange.new(-25, 25),
		Rotation = NumberRange.new(0, 360),
	})
	local fire = emitter(base, {
		Name = "Fuego",
		Texture = TEX.Fire,
		Rate = rate(b, r.Fire.Rate),
		Lifetime = NumberRange.new(0.5, 1.1),
		Speed = NumberRange.new(2, 5),
		SpreadAngle = Vector2.new(30, 30),
		EmissionDirection = Enum.NormalId.Top,
		Size = seq(2.5 * s, 0.5),
		Color = colors(r.Fire.Color, Color3.fromRGB(255, 60, 20)),
		Transparency = seq(0.15, 1),
		LightEmission = 1,
	})
	local sparks = emitter(base, {
		Name = "Chispas",
		Texture = TEX.Sparkles,
		Rate = rate(b, r.Sparks.Rate),
		Lifetime = NumberRange.new(0.6, 1.4),
		Speed = NumberRange.new(18, 40),
		SpreadAngle = Vector2.new(70, 70),
		EmissionDirection = Enum.NormalId.Top,
		Size = seq(0.5, 0),
		Color = colors(r.Sparks.Color),
		Acceleration = V(0, -40, 0),
		LightEmission = 1,
	})
	-- Mancha quemada (temporal)
	local scorch = piece(b.Folder, {
		Name = "Quemado",
		Shape = Enum.PartType.Cylinder,
		Size = V(0.06, r.Scorch.Size * s, r.Scorch.Size * s),
		CFrame = CFrame.new(origin + V(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = r.Scorch.Color,
		Material = Enum.Material.Slate,
		Transparency = 0.2,
	})
	-- Escombros con física: salen despedidos y ruedan (se quitan solos)
	local debris = {}
	for i = 1, Catalog.debris(r.Debris.Count, ctx.Tier) do
		local size = V(b.Rng:NextNumber(0.5, 1.4), b.Rng:NextNumber(0.4, 1), b.Rng:NextNumber(0.5, 1.4)) * math.clamp(s, 0.5, 2)
		local a = b.Rng:NextNumber(0, math.pi * 2)
		local rock = piece(b.Folder, {
			Name = "Escombro",
			Size = size,
			CFrame = CFrame.new(origin + V(math.cos(a) * 1.5, 1.5, math.sin(a) * 1.5)) * CFrame.Angles(b.Rng:NextNumber(0, 3), b.Rng:NextNumber(0, 3), 0),
			Color = r.Debris.Color:Lerp(Color3.new(0, 0, 0), b.Rng:NextNumber(0, 0.3)),
			Material = Enum.Material.Rock,
			Anchored = false,
			CanCollide = true,
		})
		local speed = r.Debris.Speed * b.Rng:NextNumber(0.5, 1)
		pcall(function()
			rock.AssemblyLinearVelocity = V(math.cos(a) * speed * 0.45, speed * b.Rng:NextNumber(0.6, 1), math.sin(a) * speed * 0.45)
			rock.AssemblyAngularVelocity = V(b.Rng:NextNumber(-8, 8), b.Rng:NextNumber(-8, 8), b.Rng:NextNumber(-8, 8))
		end)
		table.insert(debris, rock)
	end
	emit(b, "Sound", r.Sound, origin)
	emit(b, "Shake", r.Shake.Strength * math.min(s, 1.5), r.Shake.Seconds, origin, r.Shake.Radius)
	emit(b, "Flash", 0.35, r.Flash.Color, r.Flash.Seconds + 0.25, origin)
	return handle(b, function(_dt: number, t: number): boolean
		-- Destello
		local f = clamp01(t / r.Flash.Seconds)
		flash.Size = V(2, 2, 2) * lerp(1, 5 * s, f)
		flash.Transparency = f
		flashLight.Brightness = r.Flash.Brightness * (1 - f) * (1 - f)
		-- Onda expansiva
		local w = clamp01(t / r.Shock.Seconds)
		local d = lerp(r.Shock.From, r.Shock.To, 1 - (1 - w) * (1 - w)) * s
		shock.Size = V(0.3, d, d)
		shock.Transparency = lerp(0.2, 1, w)
		-- Bola de fuego
		local g = clamp01(t / r.Fireball.Seconds)
		fireball.Size = V(1, 1, 1) * lerp(1, r.Fireball.Size * s, math.sqrt(g))
		fireball.Transparency = lerp(0.1, 1, g * g)
		-- Humo, fuego y chispas se apagan cada uno a su tiempo
		smoke.Enabled = t < r.Smoke.Seconds
		fire.Enabled = t < r.Fire.Seconds
		sparks.Enabled = t < r.Sparks.Seconds
		-- La mancha y los escombros se desvanecen al final
		local tail = clamp01((t - (seconds - 1.2)) / 1.2)
		scorch.Transparency = lerp(0.2, 1, tail)
		for _, rock in debris do
			if t > r.Debris.Life then
				rock.Transparency = clamp01((t - r.Debris.Life) / 0.8)
			end
		end
		return t < seconds
	end, nil, function()
		return origin
	end)
end

-- Cráter como efecto (el que se queda lo pone la memoria del mundo con StoryFxBuild.crater)
Kinds.Crater = function(b: Build): Handle
	local r, ctx = b.Recipe, b.Ctx
	local params = ctx.Params or {}
	StoryFxBuild.crater(b.Folder, ctx.CFrame, {
		Radius = (params.Radius or r.Radius) * b.Scale,
		Depth = r.Depth,
		Rim = r.Rim,
		Floor = r.Floor,
		Glow = if params.Glow == false then nil else r.Glow,
		Smoke = if params.Smoke == nil then r.Smoke else params.Smoke,
		Tier = ctx.Tier,
	})
	local seconds = ctx.Seconds or r.Seconds or 0
	local stopping = false
	return handle(b, function(_dt: number, t: number): boolean
		if stopping then
			return false
		end
		return seconds <= 0 or t < seconds
	end, function()
		stopping = true
	end)
end

-- Portal: anillo que se abre girando, remolino dentro; se cierra al pararlo
Kinds.Portal = function(b: Build): Handle
	local r, ctx = b.Recipe, b.Ctx
	local params = ctx.Params or {}
	local cf: CFrame = ctx.CFrame * CFrame.new(0, (params.Radius or r.Radius) * b.Scale + 0.3, 0)
	local radius = (params.Radius or r.Radius) * b.Scale
	local segments = if b.Budget.Extras then 20 else 12
	local ring = {}
	for i = 1, segments do
		ring[i] = piece(b.Folder, {
			Name = "Anillo",
			Size = V(0.5, 0.5, (2 * math.pi * radius / segments) * 1.08),
			CFrame = cf,
			Color = r.Ring,
			Material = Enum.Material.Neon,
		})
	end
	local disc = piece(b.Folder, {
		Name = "Interior",
		Shape = Enum.PartType.Cylinder,
		Size = V(0.15, 0.1, 0.1),
		CFrame = cf * CFrame.Angles(0, math.rad(90), 0),
		Color = r.Inner,
		Material = Enum.Material.Neon,
		Transparency = 0.25,
	})
	local spokes = {}
	for i = 1, (if b.Budget.Extras then 4 else 2) do
		spokes[i] = piece(b.Folder, {
			Name = "Remolino",
			Size = V(0.18, 0.1, 0.1),
			CFrame = cf,
			Color = r.Swirl,
			Material = Enum.Material.Neon,
			Transparency = 0.35,
		})
	end
	local swirl = emitter(disc, {
		Name = "Remolino",
		Texture = TEX.Vortex,
		Rate = rate(b, r.Rate.Swirl),
		Lifetime = NumberRange.new(0.6, 1.2),
		Speed = NumberRange.new(0.2, 1),
		Size = seq(radius * 0.4, radius * 1.4),
		Color = colors(r.Swirl, r.Ring),
		Transparency = seq(0.4, 1),
		RotSpeed = NumberRange.new(120, 260),
		Rotation = NumberRange.new(0, 360),
		LightEmission = 1,
		LockedToPart = true,
	})
	local sparks = emitter(disc, {
		Name = "Chispas",
		Texture = TEX.Sparkles,
		Rate = rate(b, r.Rate.Sparks),
		Lifetime = NumberRange.new(0.5, 1),
		Speed = NumberRange.new(-6, -3), -- hacia dentro
		Size = seq(0.35, 0),
		Color = colors(r.Swirl),
		LightEmission = 1,
	})
	local glow = light(disc, r.Light, false)
	emit(b, "Sound", r.Sound, cf.Position)
	local open = 0
	local closing = false
	local closeT = 0
	return handle(b, function(dt: number, t: number): boolean
		if closing then
			closeT += dt
			open = math.max(0, 1 - closeT / math.max(r.Close or 0.8, 0.05))
		else
			local u = clamp01(t / math.max(r.Open or 1, 0.05))
			-- se abre con un pequeño rebote
			open = 1 - (1 - u) ^ 3 + math.sin(u * math.pi) * 0.12
		end
		local rr = radius * math.max(open, 0.001)
		local spin = t * 1.6
		for i, seg in ring do
			local a = (i / segments) * math.pi * 2 + spin * 0.3
			seg.CFrame = cf * CFrame.Angles(0, 0, a) * CFrame.new(rr, 0, 0) * CFrame.Angles(0, math.rad(90), 0)
			seg.Size = V(0.5, 0.5, math.max(0.05, (2 * math.pi * rr / segments) * 1.08))
		end
		disc.Size = V(0.15, rr * 1.95 + 0.05, rr * 1.95 + 0.05)
		disc.CFrame = cf * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(spin, 0, 0)
		for i, spoke in spokes do
			spoke.Size = V(0.18, 0.12, rr * 1.7 + 0.05)
			spoke.CFrame = cf * CFrame.Angles(0, 0, spin * 2.2 + i * math.pi / #spokes) * CFrame.Angles(0, math.rad(90), 0)
		end
		swirl.Enabled = open > 0.2
		sparks.Enabled = open > 0.5
		if glow then
			glow.Brightness = (r.Light.Brightness or 3) * open * (0.85 + 0.15 * math.sin(t * 6))
		end
		if closing and open <= 0 then
			return false
		end
		local seconds = ctx.Seconds or r.Seconds or 0
		if seconds > 0 and t >= seconds and not closing then
			closing = true
		end
		return true
	end, function()
		closing = true
	end, function()
		return cf.Position
	end)
end

-- Grieta en el suelo: tramos que se abren desde el centro, con luz dentro y polvo
Kinds.Crack = function(b: Build): Handle
	local r, ctx = b.Recipe, b.Ctx
	local cf: CFrame = ctx.CFrame
	local length = (r.Length or 30) * b.Scale
	local width = (r.Width or 2) * b.Scale
	local n = math.max(3, r.Segments or 9)
	local points = {}
	for i = 0, n do
		local x = (i / n - 0.5) * length
		local jitter = if i == 0 or i == n then 0 else b.Rng:NextNumber(-1, 1) * length * 0.06
		points[i] = cf * CFrame.new(jitter, 0.05, -x)
	end
	local segs = {}
	for i = 1, n do
		local a, c = points[i - 1].Position, points[i].Position
		local mid = (a + c) / 2
		local len = (c - a).Magnitude
		local look = CFrame.lookAt(mid, c)
		local edge = piece(b.Folder, { Name = "Borde", Size = V(0.1, 0.12, len + 0.4), CFrame = look, Color = r.Edge, Material = Enum.Material.Slate })
		local glow = piece(b.Folder, { Name = "Luz", Size = V(0.1, 0.08, len + 0.2), CFrame = look * CFrame.new(0, -0.02, 0), Color = r.Glow, Material = Enum.Material.Neon })
		-- se abre antes en el centro y luego hacia las puntas
		local fromCenter = math.abs((i - 0.5) / n - 0.5) * 2
		table.insert(segs, { Edge = edge, Glow = glow, Look = look, Len = len, Delay = fromCenter * 0.6 })
	end
	local dust = piece(b.Folder, { Name = "Polvo", Size = V(width * 2, 0.2, length), CFrame = cf * CFrame.new(0, 0.2, 0), Transparency = 1 })
	local dustE = emitter(dust, {
		Name = "Polvo",
		Texture = TEX.Smoke,
		Rate = rate(b, r.Rate.Dust),
		Lifetime = NumberRange.new(1, 2),
		Speed = NumberRange.new(2, 5),
		EmissionDirection = Enum.NormalId.Top,
		Size = seq(1, 3),
		Color = colors(Color3.fromRGB(150, 140, 120)),
		Transparency = seq(0.5, 1),
		LightEmission = 0,
	})
	local glowLight = light(dust, r.Light, false)
	emit(b, "Sound", r.Sound, cf.Position)
	emit(b, "Shake", r.Shake.Strength, r.Shake.Seconds, cf.Position, r.Shake.Radius)
	local fading = false
	local fadeT = 0
	local openSeconds = math.max(r.Open or 2, 0.1)
	return handle(b, function(dt: number, t: number): boolean
		if fading then
			fadeT += dt
		end
		local fade = clamp01(fadeT / 1.5)
		for _, s in segs do
			local u = clamp01((t / openSeconds - s.Delay) / (1 - s.Delay * 0.5))
			-- a trompicones: avanza a golpes
			local stepU = math.floor(u * 4 + 0.5) / 4 * 0.6 + u * 0.4
			local w = width * stepU
			s.Edge.Size = V(w + 0.6 * stepU + 0.1, 0.12, s.Len + 0.4)
			s.Glow.Size = V(math.max(0.05, w), 0.08, s.Len + 0.2)
			s.Glow.Transparency = fade
			s.Edge.Transparency = fade
		end
		dustE.Enabled = t < openSeconds + 0.5 and not fading
		if glowLight then
			glowLight.Brightness = (r.Light.Brightness or 2) * clamp01(t / openSeconds) * (1 - fade) * (0.85 + 0.15 * math.sin(t * 5))
		end
		local seconds = ctx.Seconds or r.Seconds or 0
		if seconds > 0 and t >= seconds then
			fading = true
		end
		return not (fading and fade >= 1)
	end, function()
		fading = true
	end)
end

-- Orbe / luz misteriosa: late, flota y suelta chispas
Kinds.Orb = function(b: Build): Handle
	local r, ctx = b.Recipe, b.Ctx
	local params = ctx.Params or {}
	local cf: CFrame = ctx.CFrame
	local size = (r.Size or 1.5) * b.Scale
	local orb = piece(b.Folder, { Name = "Orbe", Shape = Enum.PartType.Ball, Size = V(size, size, size), CFrame = cf, Color = r.Color, Material = Enum.Material.Neon })
	local halo: BasePart? = nil
	if b.Budget.Extras then
		halo = piece(b.Folder, { Name = "Halo", Shape = Enum.PartType.Ball, Size = V(size, size, size) * 2.2, CFrame = cf, Color = r.Halo, Material = Enum.Material.Neon, Transparency = 0.75 })
	end
	local sparks = emitter(orb, {
		Name = "Chispas",
		Texture = TEX.Sparkles,
		Rate = rate(b, r.Rate.Sparks),
		Lifetime = NumberRange.new(0.8, 1.6),
		Speed = NumberRange.new(1, 3),
		SpreadAngle = Vector2.new(180, 180),
		Size = seq(0.3 * b.Scale, 0),
		Color = colors(r.Color),
		LightEmission = 1,
	})
	local glow = light(orb, r.Light, b.Budget.Shadows)
	emit(b, "Sound", r.Sound, cf.Position)
	local rise = tonumber(params.Rise) or 0
	local seconds = ctx.Seconds or r.Seconds or 0
	local appear = 0
	local fading = false
	local fadeT = 0
	local pos = cf.Position
	return handle(b, function(dt: number, t: number): boolean
		appear = math.min(1, appear + dt * 2)
		if fading then
			fadeT += dt
		end
		local fade = clamp01(fadeT / 0.8)
		local pulse = 0.5 + 0.5 * math.sin(t * math.pi * 2 * (r.Pulse or 1.5))
		local up = if seconds > 0 then rise * clamp01(t / seconds) else rise * (1 - math.exp(-t * 0.5))
		pos = cf.Position + V(0, up + math.sin(t * 1.7) * 0.35 * b.Scale, 0)
		local k = appear * (1 - fade)
		orb.Size = V(size, size, size) * (0.85 + 0.25 * pulse) * math.max(k, 0.01)
		orb.CFrame = CFrame.new(pos)
		orb.Transparency = 1 - k
		if halo then
			halo.Size = orb.Size * (2 + 0.6 * pulse)
			halo.CFrame = orb.CFrame
			halo.Transparency = 1 - (0.25 + 0.1 * pulse) * k
		end
		sparks.Enabled = k > 0.3
		if glow then
			glow.Brightness = (r.Light.Brightness or 2) * (0.6 + 0.6 * pulse) * k
		end
		if seconds > 0 and t >= seconds then
			fading = true
		end
		return not (fading and fade >= 1)
	end, function()
		fading = true
	end, function()
		return pos
	end)
end

-- Aura de poder alrededor de un personaje (ctx.Model) o de un punto
Kinds.Aura = function(b: Build): Handle
	local r, ctx = b.Recipe, b.Ctx
	local model: Model? = ctx.Model
	local root: BasePart? = model and (model:FindFirstChild("HumanoidRootPart") :: BasePart?) or nil
	local holder: BasePart
	if root then
		holder = root
	else
		holder = piece(b.Folder, { Name = "Centro", Size = V(1, 1, 1), CFrame = ctx.CFrame, Transparency = 1 })
	end
	local attach = new("Attachment", { Name = "AuraFx" }, holder)
	local rise = emitter(attach, {
		Name = "Aura",
		Texture = TEX.Sparkles,
		Rate = rate(b, r.Rate.Rise),
		Lifetime = NumberRange.new(0.7, 1.4),
		Speed = NumberRange.new(2, 5),
		SpreadAngle = Vector2.new(40, 40),
		EmissionDirection = Enum.NormalId.Top,
		Size = seq(0.6, 0),
		Color = colors(r.Color),
		LightEmission = 1,
		Acceleration = V(0, 3, 0),
	})
	local glow = light(attach, r.Light, false)
	local highlight: Highlight? = nil
	if model then
		highlight = new("Highlight", {
			Name = "AuraFx",
			FillColor = r.Color,
			OutlineColor = r.Color,
			FillTransparency = 0.8,
			OutlineTransparency = 0.2,
			Adornee = model,
		}, b.Folder)
	end
	emit(b, "Sound", r.Sound, holder.Position)
	local seconds = ctx.Seconds or r.Seconds or 0
	local fading = false
	local fadeT = 0
	local function cleanupAttach()
		if attach.Parent then
			attach:Destroy()
		end
	end
	local h = handle(b, function(dt: number, t: number): boolean
		if fading then
			fadeT += dt
		end
		local fade = clamp01(fadeT / 0.6)
		local pulse = 0.5 + 0.5 * math.sin(t * math.pi * 2 * (r.Pulse or 1))
		if highlight then
			highlight.FillTransparency = 1 - (0.15 + 0.15 * pulse) * (1 - fade)
			highlight.OutlineTransparency = 0.2 + 0.8 * fade
		end
		rise.Enabled = not fading
		if glow then
			glow.Brightness = (r.Light.Brightness or 2) * (0.6 + 0.5 * pulse) * (1 - fade)
		end
		if seconds > 0 and t >= seconds then
			fading = true
		end
		if fading and fade >= 1 then
			cleanupAttach()
			return false
		end
		return true
	end, function()
		fading = true
	end, function()
		return holder.Position
	end)
	local destroy = h.Destroy
	h.Destroy = function()
		cleanupAttach()
		destroy()
	end
	return h
end

-- Tormenta local: nubes oscuras, lluvia en la zona, rayos y cielo plomizo mientras dura
Kinds.Storm = function(b: Build): Handle
	local r, ctx = b.Recipe, b.Ctx
	local params = ctx.Params or {}
	local cf: CFrame = ctx.CFrame
	local radius = (params.Radius or r.Radius) * b.Scale
	local height = r.Height or 70
	local clouds = {}
	local count = if b.Budget.Extras then r.Clouds else math.max(4, math.floor(r.Clouds / 2))
	for i = 1, count do
		local a = (i / count) * math.pi * 2 + b.Rng:NextNumber(-0.4, 0.4)
		local d = radius * b.Rng:NextNumber(0.1, 0.75)
		local size = V(b.Rng:NextNumber(0.5, 0.8), b.Rng:NextNumber(0.25, 0.35), b.Rng:NextNumber(0.5, 0.8)) * radius
		local cloud = piece(b.Folder, {
			Name = "Nube",
			Shape = Enum.PartType.Ball,
			Size = size,
			CFrame = cf * CFrame.new(math.cos(a) * d, height + b.Rng:NextNumber(-4, 6), math.sin(a) * d),
			Color = r.CloudColor:Lerp(Color3.new(0, 0, 0), b.Rng:NextNumber(0, 0.3)),
			Material = Enum.Material.SmoothPlastic,
			Transparency = 1,
		})
		table.insert(clouds, { Part = cloud, Base = cloud.CFrame, Phase = b.Rng:NextNumber(0, 6) })
	end
	local sky = piece(b.Folder, { Name = "Lluvia", Size = V(radius * 1.6, 1, radius * 1.6), CFrame = cf * CFrame.new(0, height - 6, 0), Transparency = 1 })
	local rain = emitter(sky, {
		Name = "Lluvia",
		Texture = TEX.Sparkles,
		Rate = rate(b, r.Rain.Rate),
		Lifetime = NumberRange.new(0.9, 1.3),
		Speed = NumberRange.new(60, 75),
		EmissionDirection = Enum.NormalId.Bottom,
		Size = seq(0.12),
		Color = colors(r.Rain.Color),
		Transparency = seq(0.35, 0.6),
		LightEmission = 0.2,
		Orientation = Enum.ParticleOrientation.VelocityParallel,
	})
	emit(b, "Sky", r.SkyMood, 2)
	local seconds = ctx.Seconds or r.Seconds or 0
	local nextBolt = b.Rng:NextNumber(0.6, 1.4)
	local bolts: { { Parts: { BasePart }, Until: number, Light: PointLight? } } = {}
	local stopping = false
	local stopT = 0
	local function strike(t: number)
		local a = b.Rng:NextNumber(0, math.pi * 2)
		local d = radius * b.Rng:NextNumber(0, 0.7)
		local ground = (cf * CFrame.new(math.cos(a) * d, 0, math.sin(a) * d)).Position
		local top = ground + V(b.Rng:NextNumber(-6, 6), height, b.Rng:NextNumber(-6, 6))
		local segs = r.Lightning.Segments or 6
		local parts = {}
		local prev = top
		for i = 1, segs do
			local u = i / segs
			local p = top:Lerp(ground, u)
			if i < segs then
				p += V(b.Rng:NextNumber(-3, 3), 0, b.Rng:NextNumber(-3, 3))
			end
			local len = (p - prev).Magnitude
			table.insert(parts, piece(b.Folder, {
				Name = "Rayo",
				Size = V(0.35, 0.35, len),
				CFrame = CFrame.lookAt((p + prev) / 2, p),
				Color = r.Lightning.Color,
				Material = Enum.Material.Neon,
			}))
			prev = p
		end
		local flashPart = parts[#parts]
		local l = light(flashPart, { Color = r.Lightning.Color, Range = 60, Brightness = 8 }, false)
		table.insert(bolts, { Parts = parts, Until = t + 0.22, Light = l })
		emit(b, "Sound", r.Sound, ground)
		emit(b, "Flash", 0.25, r.Lightning.Color, 0.25, ground)
	end
	return handle(b, function(dt: number, t: number): boolean
		if stopping then
			stopT += dt
		end
		local appear = clamp01(t / 2) * (1 - clamp01(stopT / 2))
		for _, c in clouds do
			c.Part.Transparency = 1 - 0.85 * appear
			c.Part.CFrame = c.Base * CFrame.new(math.sin(t * 0.1 + c.Phase) * 3, 0, math.cos(t * 0.08 + c.Phase) * 3)
		end
		rain.Enabled = appear > 0.5
		if not stopping and t >= nextBolt then
			strike(t)
			local every = r.Lightning.Every
			nextBolt = t + b.Rng:NextNumber(every[1], every[2])
		end
		for i = #bolts, 1, -1 do
			local bolt = bolts[i]
			if t >= bolt.Until then
				for _, p in bolt.Parts do
					p:Destroy()
				end
				table.remove(bolts, i)
			end
		end
		if seconds > 0 and t >= seconds and not stopping then
			stopping = true
			emit(b, "SkyPop", 2)
		end
		return not (stopping and stopT >= 2)
	end, function()
		if not stopping then
			stopping = true
			emit(b, "SkyPop", 2)
		end
	end)
end

-- Cambio de cielo puntual: una capa de SkyMoods mientras dura
Kinds.Sky = function(b: Build): Handle
	local r, ctx = b.Recipe, b.Ctx
	local params = ctx.Params or {}
	local mood = params.Mood or r.Mood
	local fade = params.Fade or r.Fade or 1
	emit(b, "Sky", mood, fade)
	local seconds = ctx.Seconds or r.Seconds or 0
	local popped = false
	local function pop()
		if not popped then
			popped = true
			emit(b, "SkyPop", fade)
		end
	end
	return handle(b, function(_dt: number, t: number): boolean
		if seconds > 0 and t >= seconds then
			pop()
		end
		return not popped
	end, pop)
end

-- Ráfaga corta: humo y chispas (aparecer, desaparecer, magia)
Kinds.Burst = function(b: Build): Handle
	local r, ctx = b.Recipe, b.Ctx
	local cf: CFrame = ctx.CFrame
	local base = piece(b.Folder, { Name = "Rafaga", Size = V(2, 2, 2) * b.Scale, CFrame = cf * CFrame.new(0, 1, 0), Transparency = 1 })
	local smoke = emitter(base, {
		Name = "Humo",
		Texture = TEX.Smoke,
		Rate = rate(b, r.Rate.Smoke),
		Lifetime = NumberRange.new(0.6, 1.2),
		Speed = NumberRange.new(3, 6),
		SpreadAngle = Vector2.new(180, 180),
		Size = seq(1.2 * b.Scale, 3 * b.Scale),
		Color = colors(r.Color),
		Transparency = seq(0.2, 1),
		LightEmission = 0.2,
		Drag = 3,
	})
	local sparks = emitter(base, {
		Name = "Chispas",
		Texture = TEX.Sparkles,
		Rate = rate(b, r.Rate.Sparks),
		Lifetime = NumberRange.new(0.5, 1),
		Speed = NumberRange.new(4, 9),
		SpreadAngle = Vector2.new(180, 180),
		Size = seq(0.45, 0),
		Color = colors(r.Sparkle),
		LightEmission = 1,
		Drag = 2,
	})
	emit(b, "Sound", r.Sound, cf.Position)
	local seconds = ctx.Seconds or r.Seconds or 1.5
	return handle(b, function(_dt: number, t: number): boolean
		smoke.Enabled = t < 0.3
		sparks.Enabled = t < 0.35
		return t < seconds
	end)
end

-- Destello de pantalla (lo dibuja el cliente)
Kinds.Flash = function(b: Build): Handle
	local r, ctx = b.Recipe, b.Ctx
	local params = ctx.Params or {}
	emit(b, "Flash", params.Amount or r.Amount or 0.8, params.Color or r.Color, ctx.Seconds or r.Seconds or 0.5, nil)
	return handle(b, function()
		return false
	end)
end

StoryFxBuild.Kinds = Kinds

-- Construye la receta `name` (devuelve nil si no existe)
function StoryFxBuild.build(name: string, ctx: { [string]: any }): Handle?
	local recipe = Catalog.get(name)
	if not recipe then
		return nil
	end
	local kind = Kinds[recipe.Kind]
	if not kind then
		return nil
	end
	local b = begin(name, recipe, ctx)
	local h = kind(b)
	h.Rate = b.Rate
	return h
end

return StoryFxBuild
