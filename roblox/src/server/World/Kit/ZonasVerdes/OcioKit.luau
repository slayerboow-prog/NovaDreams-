-- OcioKit: piezas comunes de los sitios de ocio de las zonas verdes (mercadillo, playa, polideportivo,
-- karting y skatepark). Todo con Builder (piezas ancladas); lo decorativo sin colisiones ni sombra.
-- Sin math.random: los sitios salen siempre iguales y no cambian el azar del resto del mapa.
--
-- Convención: cf = punto a ras de suelo; su LookVector es «el frente» (hacia donde mira el puesto, el
-- mostrador o el cartel).

local Builder = require(script.Parent.Parent.Parent.Builder)

local OcioKit = {}

local rgb = Color3.fromRGB
OcioKit.rgb = rgb
OcioKit.WOOD = rgb(150, 105, 65)
OcioKit.METAL = rgb(120, 124, 130)
OcioKit.WHITE = rgb(245, 245, 242)
OcioKit.DARK = rgb(40, 42, 46)
OcioKit.WARM = rgb(255, 214, 150)

function OcioKit.part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
	local props: { [string]: any } = { Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = parent }
	for k, v in extra or {} do
		props[k] = v
	end
	return Builder.part(props)
end

function OcioKit.decor(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
	local props: { [string]: any } = { Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = parent }
	for k, v in extra or {} do
		props[k] = v
	end
	return Builder.decor(props)
end

-- CFrame en p con la Z de la pieza a lo largo de dir (en horizontal; sin CFrame.lookAt, que en Lune
-- falla hacia +Z: Builder.facing)
function OcioKit.along(p: Vector3, dir: Vector3): CFrame
	return CFrame.new(p) * CFrame.Angles(0, math.atan2(-dir.X, -dir.Z), 0)
end

-- Cilindro tumbado en el suelo (disco): diámetro d, alto h
function OcioKit.disc(parent: Instance, name: string, d: number, h: number, cf: CFrame, color: Color3, material: Enum.Material?, collide: boolean?): BasePart
	local fn = if collide then OcioKit.part else OcioKit.decor
	return fn(parent, name, Vector3.new(h, d, d), cf * CFrame.Angles(0, 0, math.rad(90)), color, material, { Shape = Enum.PartType.Cylinder })
end

-- Rueda (eje a lo largo de la Z local de cf: de lado respecto a un vehículo que mira a -Z… o a X)
function OcioKit.wheel(parent: Instance, cf: CFrame, d: number, w: number): BasePart
	return OcioKit.decor(parent, "Wheel", Vector3.new(w, d, d), cf * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(25, 25, 28), Enum.Material.Rubber, { Shape = Enum.PartType.Cylinder })
end

-- Poste vertical (cilindro) de alto h
function OcioKit.pole(parent: Instance, name: string, h: number, d: number, cf: CFrame, color: Color3, collide: boolean?): BasePart
	local fn = if collide then OcioKit.part else OcioKit.decor
	return fn(parent, name, Vector3.new(h, d, d), cf * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), color, Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
end

-- Submodelo que llega entero al móvil (StreamingEnabled: ModelStreamingMode.Atomic)
function OcioKit.model(name: string, parent: Instance): Model
	local m = Builder.model(name, parent)
	Builder.streamable(m)
	return m
end

-- Suelo del sitio (una sola pieza): de Y = -1.2 a top
function OcioKit.slab(parent: Instance, name: string, cf: CFrame, w: number, d: number, color: Color3, material: Enum.Material, top: number?): BasePart
	local t = top or -0.8
	local h = t + 1.4
	return OcioKit.part(parent, name, Vector3.new(w, h, d), cf * CFrame.new(0, t - h / 2 + 1, 0), color, material)
end

-- Cartel en un poste (o colgado): texto por las dos caras
function OcioKit.sign(parent: Instance, cf: CFrame, text: string, w: number?, h: number?, color: Color3?, onPost: boolean?): BasePart
	local width, height = w or 8, h or 2.4
	local y = if onPost == false then 0 else 7
	if onPost ~= false then
		OcioKit.pole(parent, "SignPost", y - height / 2 + 0.2, 0.35, cf, OcioKit.METAL, true)
	end
	local board = OcioKit.part(parent, "Sign", Vector3.new(width, height, 0.3), cf * CFrame.new(0, y, 0), color or rgb(30, 90, 160))
	Builder.sign(board, text, Enum.NormalId.Front)
	Builder.sign(board, text, Enum.NormalId.Back)
	return board
end

-- Bombilla que se enciende de noche (tag StreetLamp: WorldService). light = con luz de verdad
function OcioKit.bulb(parent: Instance, cf: CFrame, color: Color3?, light: boolean?, size: number?): BasePart
	local s = size or 0.7
	local bulb = OcioKit.decor(parent, "Bulb", Vector3.new(s, s, s), cf, color or OcioKit.WARM, Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Ball, Tags = { "StreetLamp" } })
	if light then
		local l = Instance.new("PointLight")
		l.Range = 18
		l.Brightness = 1.4
		l.Color = color or OcioKit.WARM
		l.Shadows = false
		l.Enabled = false
		l.Parent = bulb
	end
	return bulb
end

-- Guirnalda de bombillas entre dos puntos (a la altura de a y b): un cable y n bombillas (una con luz)
function OcioKit.stringLights(parent: Instance, a: Vector3, b: Vector3, n: number, colors: { Color3 }?)
	local mid = (a + b) / 2
	local dir = b - a
	local len = dir.Magnitude
	OcioKit.decor(parent, "Cable", Vector3.new(0.08, 0.08, len), OcioKit.along(mid, dir), OcioKit.DARK)
	for i = 1, n do
		local t = i / (n + 1)
		local p = a + dir * t - Vector3.new(0, 0.6 * math.sin(t * math.pi), 0)
		local c = if colors then colors[(i - 1) % #colors + 1] else OcioKit.WARM
		OcioKit.bulb(parent, CFrame.new(p), c, i == math.ceil(n / 2))
	end
end

-- Farola de foco (polideportivo, karting, skatepark): poste y foco con luz hacia abajo
function OcioKit.floodlight(parent: Instance, cf: CFrame, height: number?)
	local h = height or 16
	OcioKit.pole(parent, "LightPole", h, 0.6, cf, OcioKit.METAL, true)
	local head = OcioKit.decor(parent, "LightHead", Vector3.new(3, 0.8, 1.6), cf * CFrame.new(0, h + 0.2, 0), rgb(235, 235, 225), Enum.Material.SmoothPlastic, { Tags = { "StreetLamp" } })
	local l = Instance.new("SpotLight")
	l.Face = Enum.NormalId.Bottom
	l.Angle = 110
	l.Range = 60
	l.Brightness = 2.5
	l.Shadows = false
	l.Enabled = false
	l.Parent = head
end

-- Banco donde se descansa (tag Bench: NeedsService sube la energía sentado)
function OcioKit.bench(parent: Instance, cf: CFrame, color: Color3?)
	local m = Builder.model("Bench", parent)
	m:AddTag("Bench")
	OcioKit.part(m, "Seat", Vector3.new(6, 0.4, 1.8), cf * CFrame.new(0, 1.9, 0), color or OcioKit.WOOD, Enum.Material.Wood, { ClassName = "Seat", CanTouch = false })
	OcioKit.decor(m, "Legs", Vector3.new(5, 1.7, 1.2), cf * CFrame.new(0, 0.85, 0), OcioKit.METAL, Enum.Material.Metal)
	return m
end

-- Tumbona (hamaca) donde se descansa: asiento inclinado
function OcioKit.lounger(parent: Instance, cf: CFrame, color: Color3)
	local m = Builder.model("Lounger", parent)
	m:AddTag("Bench")
	OcioKit.part(m, "Seat", Vector3.new(2.4, 0.3, 3.6), cf * CFrame.new(0, 0.9, 0.6), color, Enum.Material.Fabric, { ClassName = "Seat", CanTouch = false })
	OcioKit.decor(m, "Back", Vector3.new(2.4, 0.3, 2.6), cf * CFrame.new(0, 1.6, -1.9) * CFrame.Angles(math.rad(35), 0, 0), color, Enum.Material.Fabric)
	return m
end

-- Mesa de pícnic (tablero + dos bancos)
function OcioKit.picnic(parent: Instance, cf: CFrame, tags: { string }?): BasePart
	local m = Builder.model("Picnic", parent)
	m:AddTag("Bench")
	local top = OcioKit.part(m, "Table", Vector3.new(6, 0.4, 3), cf * CFrame.new(0, 2.6, 0), OcioKit.WOOD, Enum.Material.Wood, { Tags = tags })
	for _, z in { -2.6, 2.6 } do
		OcioKit.part(m, "Seat", Vector3.new(6, 0.35, 1.2), cf * CFrame.new(0, 1.6, z), OcioKit.WOOD, Enum.Material.Wood, { ClassName = "Seat", CanTouch = false })
	end
	return top
end

-- Puesto con toldo de rayas: mostrador al frente (pieza que se devuelve), dos postes y toldo.
function OcioKit.stall(parent: Instance, cf: CFrame, w: number, awning: Color3, name: string?): (Model, BasePart, BasePart)
	local m = Builder.model(name or "Stall", parent)
	local counter = OcioKit.part(m, "Counter", Vector3.new(w, 3.4, 2.2), cf * CFrame.new(0, 1.7, -1.6), OcioKit.WOOD, Enum.Material.WoodPlanks)
	for _, x in { -w / 2 + 0.3, w / 2 - 0.3 } do
		OcioKit.decor(m, "Post", Vector3.new(0.35, 8.6, 0.35), cf * CFrame.new(x, 4.3, 1.4), OcioKit.METAL, Enum.Material.Metal)
	end
	local roof = OcioKit.part(m, "Awning", Vector3.new(w + 0.8, 0.3, 5.4), cf * CFrame.new(0, 8.5, -0.6) * CFrame.Angles(math.rad(-10), 0, 0), awning, Enum.Material.Fabric)
	return m, counter, roof
end

-- Muro de neumáticos (barrera del karting): una pieza negra de goma con franjas
function OcioKit.tyreWall(parent: Instance, a: Vector3, b: Vector3, color: Color3?)
	local mid = (a + b) / 2
	local len = (b - a).Magnitude
	OcioKit.part(parent, "TyreWall", Vector3.new(2.4, 2.4, len), OcioKit.along(mid + Vector3.new(0, 1.2, 0), b - a), color or rgb(28, 28, 30), Enum.Material.Rubber)
end

-- Cuenta las piezas (BasePart) de un modelo
function OcioKit.count(root: Instance): number
	local n = 0
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			n += 1
		end
	end
	return n
end

return OcioKit
