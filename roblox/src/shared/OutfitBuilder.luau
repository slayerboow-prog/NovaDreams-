-- OutfitBuilder: viste a un personaje (R15 o R6) con un conjunto de shared/Outfits.
-- Lo usan el servidor (AvatarService, al vestir de verdad) y el cliente (BattlePassPreview, en el
-- clon de la vista previa): así lo que ves en el pase es exactamente lo que llevas.
--
--   OutfitBuilder.dress(character, def, opts) -> Folder
--     opts.Folder    carpeta donde van las piezas (si no, una "ValmarLook" nueva dentro del personaje)
--     opts.Stage     etapa de vida ("Nino" = talla de niño: sin ombligo al aire, sin tacones ni rejilla)
--     opts.Skin      color de piel; opts.HairColor color de pelo por defecto (canas de mayor)
--     opts.Ids       { Shirt, Pants } plantillas subidas (por defecto, las de shared/OutfitIds)
--   OutfitBuilder.hair(folder, character, style, color, rng, baby)   peinados (el de siempre: "Messy")
--   OutfitBuilder.clearClothes(character, all)  quita la ropa clásica que puso el aspecto de Valmar
--   OutfitBuilder.idsFor(key) -> (shirtId?, pantsId?)
--   OutfitBuilder.anchor(character, "LeftFoot") -> (pieza real, CFrame dentro de ella, tamaño)
--
-- Dos modos, con el mismo aspecto 3D:
--   * Con plantillas (OutfitIds tiene o01_shirt y o01_pants): ropa clásica Shirt/Pants de 585×559
--     (estampados, rayas, cremalleras, bolsillos…) + accesorios 3D.
--   * Sin plantillas (hasta que se suban): colores en cada pieza del cuerpo + detalles hechos con
--     piezas finas (estampados de texto, rayas, cremallera, bolsillos…) + los mismos accesorios 3D.
-- Todas las piezas: sin colisión, sin masa, sin consultas, soldadas (WeldConstraint) a su parte del
-- cuerpo. En R6 se usan «partes virtuales» (la parte de arriba del brazo, el pie dentro de la pierna…).

local OutfitBuilder = {}

local OutfitIds = require(script.Parent.OutfitIds)
local Images = require(script.Parent.Images)

local FABRIC = Enum.Material.Fabric
local SMOOTH = Enum.Material.SmoothPlastic
local METAL = Enum.Material.Metal
local NEON = Enum.Material.Neon
local GLASS = Enum.Material.Glass
local RUBBER = Enum.Material.Rubber

local function shade(c: Color3, k: number): Color3
	return if k >= 0 then c:Lerp(Color3.new(1, 1, 1), k) else c:Lerp(Color3.new(0, 0, 0), -k)
end
OutfitBuilder.shade = shade

---------------------------------------------------------------------
-- Partes del cuerpo (R15 y, si no, R6 con partes virtuales)
---------------------------------------------------------------------
-- R6: parte real, centro (fracción de su alto) y alto (fracción)
local R6 = {
	UpperTorso = { "Torso", 0.1, 0.8 },
	LowerTorso = { "Torso", -0.4, 0.2 },
	LeftUpperArm = { "Left Arm", 0.275, 0.45 },
	LeftLowerArm = { "Left Arm", -0.15, 0.4 },
	LeftHand = { "Left Arm", -0.425, 0.15 },
	RightUpperArm = { "Right Arm", 0.275, 0.45 },
	RightLowerArm = { "Right Arm", -0.15, 0.4 },
	RightHand = { "Right Arm", -0.425, 0.15 },
	LeftUpperLeg = { "Left Leg", 0.275, 0.45 },
	LeftLowerLeg = { "Left Leg", -0.175, 0.45 },
	LeftFoot = { "Left Leg", -0.45, 0.1 },
	RightUpperLeg = { "Right Leg", 0.275, 0.45 },
	RightLowerLeg = { "Right Leg", -0.175, 0.45 },
	RightFoot = { "Right Leg", -0.45, 0.1 },
}

function OutfitBuilder.isR6(character: Instance): boolean
	return character:FindFirstChild("UpperTorso") == nil and character:FindFirstChild("Torso") ~= nil
end

function OutfitBuilder.anchor(character: Instance, name: string): (BasePart?, CFrame, Vector3)
	local part = character:FindFirstChild(name)
	if part and part:IsA("BasePart") then
		local s = part.Size
		if name == "Head" and s.X > s.Y * 1.5 then
			-- Cabeza con malla (R6 / cabeza clásica): lo que se ve es un poco más que su alto
			s = Vector3.new(s.Y * 1.25, s.Y * 1.25, s.Y * 1.25)
		end
		return part, CFrame.new(), s
	end
	local r6 = R6[name]
	if r6 then
		local real = character:FindFirstChild(r6[1])
		if real and real:IsA("BasePart") then
			local s = real.Size
			return real, CFrame.new(0, s.Y * r6[2], 0), Vector3.new(s.X, s.Y * r6[3], s.Z)
		end
	end
	return nil, CFrame.new(), Vector3.new(1, 1, 1)
end

local function sizeOf(character: Instance, name: string): Vector3
	local _, _, s = OutfitBuilder.anchor(character, name)
	return s
end

-- Pieza soldada a una parte (real o virtual) del cuerpo. props: Shape, Mesh ("Sphere"|"Cylinder"),
-- Transparency, Reflectance, Class ("WedgePart"), Shadow
local function attach(ctx: { [string]: any }, at: string, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?, props: { [string]: any }?): BasePart?
	local part0, base = OutfitBuilder.anchor(ctx.Character, at)
	if not part0 then
		return nil
	end
	local p = Instance.new(if props and props.Class then props.Class else "Part") :: BasePart
	p.Name = name
	p.Size = Vector3.new(math.max(size.X, 0.05), math.max(size.Y, 0.05), math.max(size.Z, 0.05))
	p.Color = color
	p.Material = material or SMOOTH
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.Anchored = false
	p.CastShadow = if props and props.Shadow ~= nil then props.Shadow else size.Magnitude > 1
	if props then
		if props.Shape then
			(p :: any).Shape = props.Shape
		end
		if props.Transparency then
			p.Transparency = props.Transparency
		end
		if props.Reflectance then
			p.Reflectance = props.Reflectance
		end
		if props.Mesh then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = if props.Mesh == "Sphere" then Enum.MeshType.Sphere else Enum.MeshType.Cylinder
			mesh.Parent = p
		end
	end
	p.CFrame = part0.CFrame * base * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part0
	weld.Part1 = p
	weld.Parent = p
	p:SetAttribute("OutfitPiece", true)
	p.Parent = ctx.Folder
	return p
end
OutfitBuilder.attach = attach

local SPHERE = { Mesh = "Sphere" }
local CYL = { Mesh = "Cylinder" } -- (cilindro de malla: eje Y, sección del tamaño de la pieza)

-- Texto pintado en una cara de una pieza (estampados del modo sin plantillas, espaldas de chalecos)
local function print3d(part: BasePart?, face: Enum.NormalId, text: string, color: Color3)
	if not part then
		return
	end
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.CanvasSize = Vector2.new(240, 120)
	gui.LightInfluence = 1
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = color
	label.Parent = gui
	gui.Parent = part
end

local function paint(ctx: { [string]: any }, names: { string }, color: Color3, material: Enum.Material?)
	for _, name in names do
		local part = ctx.Character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.Color = color
			if material then
				part.Material = material
			end
		end
	end
end

---------------------------------------------------------------------
-- Peinados
---------------------------------------------------------------------
local function hairBase(ctx, s: Vector3, color: Color3, fringe: boolean)
	attach(ctx, "Head", "Hair", Vector3.new(s.X * 1.07, s.Y * 0.4, s.Z * 1.09), CFrame.new(0, s.Y * 0.33, 0.02 * s.Z), color, FABRIC)
	attach(ctx, "Head", "HairBack", Vector3.new(s.X * 1.05, s.Y * 0.58, s.Z * 0.3), CFrame.new(0, s.Y * 0.08, s.Z * 0.42), color, FABRIC)
	for _, sx in { -1, 1 } do
		attach(ctx, "Head", "HairSide", Vector3.new(s.X * 0.13, s.Y * 0.4, s.Z * 0.72), CFrame.new(sx * s.X * 0.5, s.Y * 0.14, s.Z * 0.08), color, FABRIC)
	end
	if fringe then
		attach(ctx, "Head", "Fringe", Vector3.new(s.X * 0.92, s.Y * 0.14, s.Z * 0.14), CFrame.new(0, s.Y * 0.38, -s.Z * 0.5) * CFrame.Angles(math.rad(-12), 0, 0), color, FABRIC)
	end
end

local HAIR = {}
function HAIR.Short(ctx, s, color)
	hairBase(ctx, s, color, true)
end
function HAIR.Long(ctx, s, color)
	hairBase(ctx, s, color, true)
	-- Melena por la espalda y a los lados de la cara
	attach(ctx, "Head", "HairLong", Vector3.new(s.X * 1.1, s.Y * 1.45, s.Z * 0.34), CFrame.new(0, -s.Y * 0.33, s.Z * 0.5), color, FABRIC)
	for _, sx in { -1, 1 } do
		attach(ctx, "Head", "HairLock", Vector3.new(s.X * 0.14, s.Y * 1.05, s.Z * 0.62), CFrame.new(sx * s.X * 0.53, -s.Y * 0.17, s.Z * 0.12), color, FABRIC)
	end
end
function HAIR.Wavy(ctx, s, color)
	HAIR.Long(ctx, s, color)
	for i, x in { -0.42, -0.14, 0.14, 0.42 } do
		attach(ctx, "Head", "Curl", Vector3.new(s.X * 0.32, s.Y * 0.3, s.Z * 0.34), CFrame.new(x * s.X, -s.Y * (1.02 + (i % 2) * 0.06), s.Z * 0.52), shade(color, if i % 2 == 0 then 0.06 else -0.04), FABRIC, SPHERE)
	end
	for _, sx in { -1, 1 } do
		attach(ctx, "Head", "Curl", Vector3.new(s.X * 0.22, s.Y * 0.34, s.Z * 0.5), CFrame.new(sx * s.X * 0.55, -s.Y * 0.7, s.Z * 0.14), shade(color, 0.05), FABRIC, SPHERE)
		attach(ctx, "Head", "Wave", Vector3.new(s.X * 0.26, s.Y * 0.5, s.Z * 0.4), CFrame.new(sx * s.X * 0.4, s.Y * 0.28, -s.Z * 0.28) * CFrame.Angles(0, 0, sx * math.rad(25)), color, FABRIC, SPHERE)
	end
end
function HAIR.Ponytail(ctx, s, color)
	hairBase(ctx, s, color, false)
	attach(ctx, "Head", "HairTie", Vector3.new(s.X * 0.22, s.Y * 0.12, s.Z * 0.22), CFrame.new(0, s.Y * 0.3, s.Z * 0.58) * CFrame.Angles(math.rad(70), 0, 0), shade(color, -0.5), FABRIC, CYL)
	attach(ctx, "Head", "Ponytail", Vector3.new(s.X * 0.32, s.Y * 0.95, s.Z * 0.32), CFrame.new(0, -s.Y * 0.12, s.Z * 0.7) * CFrame.Angles(math.rad(14), 0, 0), color, FABRIC, SPHERE)
end
function HAIR.Twin(ctx, s, color)
	hairBase(ctx, s, color, true)
	for _, sx in { -1, 1 } do
		attach(ctx, "Head", "HairTie", Vector3.new(s.X * 0.18, s.Y * 0.12, s.Z * 0.18), CFrame.new(sx * s.X * 0.56, s.Y * 0.28, s.Z * 0.12), Color3.fromRGB(20, 20, 24), FABRIC, CYL)
		attach(ctx, "Head", "Twintail", Vector3.new(s.X * 0.34, s.Y * 1.15, s.Z * 0.36), CFrame.new(sx * s.X * 0.66, -s.Y * 0.3, s.Z * 0.14) * CFrame.Angles(0, 0, sx * math.rad(10)), color, FABRIC, SPHERE)
	end
end
function HAIR.Messy(ctx, s, color, rng: Random)
	hairBase(ctx, s, color, false)
	-- Flequillo despeinado: mechones que caen sobre la frente
	for i, x in { -0.32, -0.12, 0.08, 0.28 } do
		local tilt = CFrame.Angles(math.rad(-15 - rng:NextNumber() * 20), 0, math.rad((rng:NextNumber() - 0.5) * 40))
		local h = s.Y * (0.26 + (i % 2) * 0.08)
		attach(ctx, "Head", "Fringe", Vector3.new(s.X * 0.26, h, s.Z * 0.16), CFrame.new(x * s.X, s.Y * 0.3, -s.Z * 0.5) * tilt * CFrame.new(0, -h * 0.35, 0), color, FABRIC)
	end
	-- Puntas de arriba y de atrás (el toque "recién levantado")
	for _ = 1, 7 do
		local x = (rng:NextNumber() - 0.5) * s.X * 0.9
		local z = (rng:NextNumber() - 0.3) * s.Z * 0.9
		local tilt = CFrame.Angles(math.rad((rng:NextNumber() - 0.5) * 70), math.rad(rng:NextNumber() * 90), math.rad((rng:NextNumber() - 0.5) * 70))
		attach(ctx, "Head", "HairTuft", Vector3.new(s.X * 0.22, s.Y * 0.28, s.Z * 0.22), CFrame.new(x, s.Y * 0.52, z) * tilt, color, FABRIC)
	end
	for _, sx in { -1, 1 } do
		attach(ctx, "Head", "HairTuft", Vector3.new(s.X * 0.24, s.Y * 0.3, s.Z * 0.2), CFrame.new(sx * s.X * 0.3, -s.Y * 0.12, s.Z * 0.5) * CFrame.Angles(math.rad(20), 0, math.rad(sx * 25)), color, FABRIC)
	end
end

-- Pelo. style: Messy (el de siempre), Short, Long, Wavy, Ponytail, Twin. baby: un mechón.
function OutfitBuilder.hair(folder: Instance, character: Instance, style: string?, color: Color3, rng: Random?, baby: boolean?)
	local ctx = { Character = character, Folder = folder }
	local s = sizeOf(character, "Head")
	if baby then
		attach(ctx, "Head", "Hair", Vector3.new(s.X * 0.5, s.Y * 0.16, s.Z * 0.5), CFrame.new(0, s.Y * 0.47, 0), color, FABRIC)
		attach(ctx, "Head", "HairCurl", Vector3.new(s.X * 0.2, s.Y * 0.2, s.Z * 0.12), CFrame.new(0, s.Y * 0.52, -s.Z * 0.22) * CFrame.Angles(math.rad(-30), 0, 0), color, FABRIC)
		return
	end
	local build = HAIR[style or "Messy"] or HAIR.Messy
	build(ctx, s, color, rng or Random.new(1))
end

---------------------------------------------------------------------
-- Accesorios 3D (OutfitBuilder.Accessories[Kind](ctx, spec))
---------------------------------------------------------------------
local A = {}
OutfitBuilder.Accessories = A

-- Cabeza ------------------------------------------------------------
function A.Cap(ctx, a)
	local h = sizeOf(ctx.Character, "Head")
	local root = if a.Back then CFrame.Angles(0, math.pi, 0) else CFrame.new()
	local color, trim = a.Color, a.Trim or a.Color
	attach(ctx, "Head", "CapCrown", Vector3.new(h.X * 1.1, h.Y * 0.72, h.Z * 1.12), root * CFrame.new(0, h.Y * 0.3, 0.02 * h.Z), color, FABRIC, SPHERE)
	attach(ctx, "Head", "CapPeak", Vector3.new(h.X * 0.88, h.Y * 0.06, h.Z * 0.78), root * CFrame.new(0, h.Y * 0.22, -h.Z * 0.5) * CFrame.Angles(math.rad(-9), 0, 0), shade(color, -0.12), FABRIC, CYL)
	attach(ctx, "Head", "CapButton", Vector3.new(h.X * 0.12, h.Y * 0.07, h.Z * 0.12), root * CFrame.new(0, h.Y * 0.66, 0.02 * h.Z), trim, FABRIC, CYL)
	if a.Style == "Patrol" then
		attach(ctx, "Head", "CapBand", Vector3.new(h.X * 1.13, h.Y * 0.09, h.Z * 1.15), root * CFrame.new(0, h.Y * 0.2, 0.02 * h.Z), trim, METAL, CYL)
	else
		attach(ctx, "Head", "CapLogo", Vector3.new(h.X * 0.24, h.Y * 0.15, 0.04), root * CFrame.new(0, h.Y * 0.43, -h.Z * 0.53) * CFrame.Angles(math.rad(20), 0, 0), trim, SMOOTH)
	end
end

function A.CowboyHat(ctx, a)
	local h = sizeOf(ctx.Character, "Head")
	local trim = a.Trim or shade(a.Color, -0.4)
	local tilt = CFrame.Angles(math.rad(-5), 0, 0)
	attach(ctx, "Head", "HatBrim", Vector3.new(h.X * 2.1, h.Y * 0.06, h.Z * 1.85), tilt * CFrame.new(0, h.Y * 0.42, 0.02), a.Color, FABRIC, CYL)
	for _, sx in { -1, 1 } do
		-- Ala levantada a los lados
		attach(ctx, "Head", "HatBrimCurl", Vector3.new(h.X * 0.32, h.Y * 0.06, h.Z * 1.5), tilt * CFrame.new(sx * h.X * 0.95, h.Y * 0.52, 0.02) * CFrame.Angles(0, 0, sx * math.rad(35)), a.Color, FABRIC, CYL)
	end
	attach(ctx, "Head", "HatCrown", Vector3.new(h.X * 0.96, h.Y * 0.56, h.Z * 0.92), tilt * CFrame.new(0, h.Y * 0.71, 0.02), a.Color, FABRIC, CYL)
	attach(ctx, "Head", "HatDent", Vector3.new(h.X * 0.5, h.Y * 0.12, h.Z * 0.34), tilt * CFrame.new(0, h.Y * 0.97, -h.Z * 0.08), shade(a.Color, -0.18), FABRIC, SPHERE)
	attach(ctx, "Head", "HatBand", Vector3.new(h.X * 0.98, h.Y * 0.1, h.Z * 0.94), tilt * CFrame.new(0, h.Y * 0.5, 0.02), trim, FABRIC, CYL)
end

function A.SunHat(ctx, a)
	local h = sizeOf(ctx.Character, "Head")
	local tilt = CFrame.Angles(math.rad(-6), 0, math.rad(4))
	attach(ctx, "Head", "HatBrim", Vector3.new(h.X * 2.35, h.Y * 0.05, h.Z * 2.3), tilt * CFrame.new(0, h.Y * 0.4, 0.02), a.Color, FABRIC, CYL)
	attach(ctx, "Head", "HatCrown", Vector3.new(h.X * 1.1, h.Y * 0.66, h.Z * 1.12), tilt * CFrame.new(0, h.Y * 0.48, 0.02), a.Color, FABRIC, SPHERE)
	attach(ctx, "Head", "HatBand", Vector3.new(h.X * 1.04, h.Y * 0.09, h.Z * 1.06), tilt * CFrame.new(0, h.Y * 0.45, 0.02), a.Trim or shade(a.Color, -0.4), FABRIC, CYL)
end

function A.FireHelmet(ctx, a)
	local h = sizeOf(ctx.Character, "Head")
	local trim = a.Trim or Color3.new(1, 1, 0)
	attach(ctx, "Head", "HelmetDome", Vector3.new(h.X * 1.24, h.Y * 0.92, h.Z * 1.3), CFrame.new(0, h.Y * 0.32, 0.02), a.Color, SMOOTH, SPHERE)
	attach(ctx, "Head", "HelmetBrim", Vector3.new(h.X * 1.5, h.Y * 0.06, h.Z * 1.8), CFrame.new(0, h.Y * 0.12, h.Z * 0.14) * CFrame.Angles(math.rad(9), 0, 0), a.Color, SMOOTH, CYL)
	attach(ctx, "Head", "HelmetCrest", Vector3.new(h.X * 0.12, h.Y * 0.14, h.Z * 1.12), CFrame.new(0, h.Y * 0.74, 0.02), shade(a.Color, 0.12), SMOOTH)
	attach(ctx, "Head", "HelmetShield", Vector3.new(h.X * 0.44, h.Y * 0.34, 0.06), CFrame.new(0, h.Y * 0.5, -h.Z * 0.66) * CFrame.Angles(math.rad(14), 0, 0), trim, SMOOTH)
	attach(ctx, "Head", "HelmetBand", Vector3.new(h.X * 1.27, h.Y * 0.08, h.Z * 1.33), CFrame.new(0, h.Y * 0.2, 0.02), trim, NEON, { Mesh = "Cylinder", Transparency = 0.15 })
end

function A.Headphones(ctx, a)
	local h = sizeOf(ctx.Character, "Head")
	local trim = a.Trim or shade(a.Color, -0.6)
	attach(ctx, "Head", "PhonesBand", Vector3.new(h.X * 0.62, h.Y * 0.09, h.Z * 0.18), CFrame.new(0, h.Y * 0.66, 0), a.Color, SMOOTH)
	for _, sx in { -1, 1 } do
		attach(ctx, "Head", "PhonesBand", Vector3.new(h.X * 0.09, h.Y * 0.42, h.Z * 0.18), CFrame.new(sx * h.X * 0.47, h.Y * 0.43, 0) * CFrame.Angles(0, 0, sx * math.rad(-28)), a.Color, SMOOTH)
		attach(ctx, "Head", "EarCup", Vector3.new(h.X * 0.16, h.Y * 0.42, h.Y * 0.42), CFrame.new(sx * h.X * 0.57, h.Y * 0.04, 0.02), a.Color, SMOOTH, { Shape = Enum.PartType.Cylinder })
		attach(ctx, "Head", "EarPad", Vector3.new(h.X * 0.06, h.Y * 0.3, h.Y * 0.3), CFrame.new(sx * h.X * 0.66, h.Y * 0.04, 0.02), trim, FABRIC, { Shape = Enum.PartType.Cylinder })
	end
end

function A.Goggles(ctx, a)
	local h = sizeOf(ctx.Character, "Head")
	local trim = a.Trim or Color3.new(0.1, 0.1, 0.1)
	attach(ctx, "Head", "GoggleStrap", Vector3.new(h.X * 1.08, h.Y * 0.12, h.Z * 1.1), CFrame.new(0, h.Y * 0.34, 0.02), trim, FABRIC, CYL)
	for _, sx in { -1, 1 } do
		local at = CFrame.new(sx * h.X * 0.2, h.Y * 0.36, -h.Z * 0.55) * CFrame.Angles(0, math.pi / 2, 0)
		attach(ctx, "Head", "GoggleFrame", Vector3.new(0.12, h.Y * 0.34, h.Y * 0.34), at * CFrame.new(-0.02, 0, 0), trim, SMOOTH, { Shape = Enum.PartType.Cylinder })
		attach(ctx, "Head", "GoggleLens", Vector3.new(0.08, h.Y * 0.27, h.Y * 0.27), at * CFrame.new(0.04, 0, 0), a.Color, NEON, { Shape = Enum.PartType.Cylinder, Transparency = 0.2 })
	end
end

function A.Halo(ctx, a)
	local h = sizeOf(ctx.Character, "Head")
	local n, r = 18, h.X * 0.42
	local center = CFrame.new(0, h.Y * 0.98, h.Z * 0.06) * CFrame.Angles(math.rad(-12), 0, 0)
	for i = 1, n do
		local ang = (i / n) * math.pi * 2
		local seg = attach(ctx, "Head", "Halo", Vector3.new(2 * math.pi * r / n * 1.15, 0.07, 0.09), center * CFrame.Angles(0, ang, 0) * CFrame.new(0, 0, -r), a.Color, NEON, { Shadow = false })
		if i == 1 and seg then
			local light = Instance.new("PointLight")
			light.Color = a.Color
			light.Range = 6
			light.Brightness = 0.7
			light.Parent = seg
		end
	end
end

-- Cara --------------------------------------------------------------
function A.Sunglasses(ctx, a)
	local h = sizeOf(ctx.Character, "Head")
	local frame = a.Frame or shade(a.Color, -0.3)
	local y, z = h.Y * 0.1, -h.Z * 0.5 - 0.035
	local lens = { Reflectance = 0.25, Transparency = 0.05 }
	local style = a.Style or "Square"
	if style == "Sport" then
		attach(ctx, "Head", "Lens", Vector3.new(h.X * 0.84, h.Y * 0.17, 0.05), CFrame.new(0, y, z), a.Color, GLASS, lens)
		attach(ctx, "Head", "GlassesFrame", Vector3.new(h.X * 0.86, 0.045, 0.06), CFrame.new(0, y + h.Y * 0.09, z), frame, SMOOTH)
	else
		for _, sx in { -1, 1 } do
			if style == "Round" then
				attach(ctx, "Head", "Lens", Vector3.new(0.05, h.Y * 0.21, h.Y * 0.21), CFrame.new(sx * h.X * 0.2, y, z) * CFrame.Angles(0, math.pi / 2, 0), a.Color, GLASS, { Shape = Enum.PartType.Cylinder, Reflectance = 0.25, Transparency = 0.05 })
				attach(ctx, "Head", "GlassesFrame", Vector3.new(0.04, h.Y * 0.24, h.Y * 0.24), CFrame.new(sx * h.X * 0.2, y, z + 0.015) * CFrame.Angles(0, math.pi / 2, 0), frame, METAL, { Shape = Enum.PartType.Cylinder })
			else
				local tilt = if style == "Cat" then CFrame.Angles(0, 0, sx * math.rad(-10)) else CFrame.new()
				local w = if style == "Cat" then 0.33 else 0.3
				attach(ctx, "Head", "Lens", Vector3.new(h.X * w, h.Y * 0.16, 0.05), CFrame.new(sx * h.X * 0.2, y, z) * tilt, a.Color, GLASS, lens)
				attach(ctx, "Head", "GlassesFrame", Vector3.new(h.X * (w + 0.02), 0.045, 0.06), CFrame.new(sx * h.X * 0.2, y + h.Y * 0.085, z) * tilt, frame, SMOOTH)
			end
		end
		attach(ctx, "Head", "GlassesBridge", Vector3.new(h.X * 0.1, 0.04, 0.05), CFrame.new(0, y + h.Y * 0.04, z), frame, METAL)
	end
	for _, sx in { -1, 1 } do
		attach(ctx, "Head", "GlassesArm", Vector3.new(0.04, 0.04, h.Z * 0.55), CFrame.new(sx * h.X * 0.51, y + h.Y * 0.05, -h.Z * 0.22), frame, SMOOTH)
	end
end

function A.Visor(ctx, a)
	local h = sizeOf(ctx.Character, "Head")
	attach(ctx, "Head", "Visor", Vector3.new(h.X * 1.02, h.Y * 0.2, 0.06), CFrame.new(0, h.Y * 0.1, -h.Z * 0.53), a.Color, NEON, { Transparency = 0.3, Shadow = false })
	attach(ctx, "Head", "VisorFrame", Vector3.new(h.X * 1.04, 0.05, 0.08), CFrame.new(0, h.Y * 0.21, -h.Z * 0.53), Color3.fromRGB(20, 20, 24), SMOOTH)
	for _, sx in { -1, 1 } do
		attach(ctx, "Head", "VisorArm", Vector3.new(0.06, h.Y * 0.12, h.Z * 0.6), CFrame.new(sx * h.X * 0.52, h.Y * 0.12, -h.Z * 0.22), Color3.fromRGB(20, 20, 24), SMOOTH)
	end
end

function A.Mask(ctx, a)
	local h = sizeOf(ctx.Character, "Head")
	attach(ctx, "Head", "FaceMask", Vector3.new(h.X * 1.06, h.Y * 0.6, h.Z * 1.08), CFrame.new(0, -h.Y * 0.22, 0), a.Color, FABRIC, SPHERE)
end

-- Cuello y pecho ------------------------------------------------------
local function chestCurve(ctx, name: string, color: Color3, material: Enum.Material, top: number, bottom: number, n: number, size: Vector3, shapeProps: { [string]: any }?, colors: { Color3 }?)
	local t = sizeOf(ctx.Character, "UpperTorso")
	local front = -t.Z / 2 - 0.04
	for i = -n, n do
		local u = i / n
		local x = u * t.X * 0.17
		local y = t.Y * (top - (top - bottom) * (1 - u * u))
		local c = if colors then colors[(i + n) % #colors + 1] else color
		attach(ctx, "UpperTorso", name, size, CFrame.new(x, y, front), c, material, shapeProps)
	end
	return t, front
end

function A.Chain(ctx, a)
	local t, front = chestCurve(ctx, "Chain", a.Color, METAL, 0.48, 0.12, 4, Vector3.new(0.1, 0.1, 0.05), nil)
	attach(ctx, "UpperTorso", "Pendant", Vector3.new(t.X * 0.09, t.X * 0.11, 0.05), CFrame.new(0, t.Y * 0.06, front - 0.01), a.Color, METAL, { Reflectance = 0.2 })
	if a.Double then
		chestCurve(ctx, "Chain", a.Color, METAL, 0.48, 0.24, 4, Vector3.new(0.08, 0.08, 0.05), nil)
	end
end

function A.Necklace(ctx, a)
	local t, front = chestCurve(ctx, "Necklace", a.Color, METAL, 0.48, 0.3, 4, Vector3.new(0.07, 0.07, 0.04), nil)
	attach(ctx, "UpperTorso", "Pendant", Vector3.new(0.1, 0.12, 0.04), CFrame.new(0, t.Y * 0.25, front - 0.01) * CFrame.Angles(0, 0, math.rad(45)), a.Color, METAL, { Reflectance = 0.3 })
end

function A.Beads(ctx, a)
	local colors = a.Colors or { a.Color }
	chestCurve(ctx, "Bead", colors[1], SMOOTH, 0.48, 0.24, 6, Vector3.new(0.11, 0.11, 0.11), { Shape = Enum.PartType.Ball }, colors)
	chestCurve(ctx, "Bead", colors[1], SMOOTH, 0.48, 0.08, 7, Vector3.new(0.1, 0.1, 0.1), { Shape = Enum.PartType.Ball }, { colors[#colors], colors[1], colors[2] or colors[1] })
end

function A.Choker(ctx, a)
	local t = sizeOf(ctx.Character, "UpperTorso")
	attach(ctx, "UpperTorso", "Choker", Vector3.new(t.X * 0.34, 0.12, t.Z * 0.52), CFrame.new(0, t.Y * 0.5 + 0.03, 0), a.Color, FABRIC, CYL)
	attach(ctx, "UpperTorso", "ChokerRing", Vector3.new(0.05, 0.12, 0.12), CFrame.new(0, t.Y * 0.47, -t.Z * 0.27) * CFrame.Angles(0, math.pi / 2, 0), a.Trim or a.Color, METAL, { Shape = Enum.PartType.Cylinder })
end

function A.BowTie(ctx, a)
	local t = sizeOf(ctx.Character, "UpperTorso")
	local front = -t.Z / 2 - 0.05
	for _, sx in { -1, 1 } do
		attach(ctx, "UpperTorso", "BowTie", Vector3.new(t.X * 0.1, t.Y * 0.09, 0.06), CFrame.new(sx * t.X * 0.055, t.Y * 0.43, front) * CFrame.Angles(0, 0, sx * math.rad(12)), a.Color, SMOOTH)
	end
	attach(ctx, "UpperTorso", "BowKnot", Vector3.new(t.X * 0.04, t.Y * 0.06, 0.08), CFrame.new(0, t.Y * 0.43, front - 0.01), shade(a.Color, 0.1), SMOOTH)
end

function A.Scarf(ctx, a)
	local t = sizeOf(ctx.Character, "UpperTorso")
	attach(ctx, "UpperTorso", "Scarf", Vector3.new(t.X * 0.58, t.Y * 0.17, t.Z * 1.12), CFrame.new(0, t.Y * 0.5, 0), a.Color, FABRIC, CYL)
	attach(ctx, "UpperTorso", "ScarfTail", Vector3.new(t.X * 0.15, t.Y * 0.55, 0.09), CFrame.new(t.X * 0.15, t.Y * 0.16, -t.Z / 2 - 0.06) * CFrame.Angles(0, 0, math.rad(4)), a.Color, FABRIC)
	attach(ctx, "UpperTorso", "ScarfFringe", Vector3.new(t.X * 0.15, t.Y * 0.05, 0.1), CFrame.new(t.X * 0.17, -t.Y * 0.13, -t.Z / 2 - 0.06), shade(a.Color, 0.15), FABRIC)
end

function A.CollarPuffer(ctx, a)
	local t = sizeOf(ctx.Character, "UpperTorso")
	attach(ctx, "UpperTorso", "PufferCollar", Vector3.new(t.X * 0.62, t.Y * 0.2, t.Z * 1.18), CFrame.new(0, t.Y * 0.5, 0.02), a.Color, FABRIC, CYL)
end

function A.Stethoscope(ctx, a)
	local t = sizeOf(ctx.Character, "UpperTorso")
	local front = -t.Z / 2 - 0.05
	attach(ctx, "UpperTorso", "Stetho", Vector3.new(t.X * 0.32, 0.06, 0.06), CFrame.new(0, t.Y * 0.5, t.Z * 0.1), a.Color, RUBBER)
	for _, sx in { -1, 1 } do
		attach(ctx, "UpperTorso", "Stetho", Vector3.new(0.06, t.Y * 0.44, 0.06), CFrame.new(sx * t.X * 0.13, t.Y * 0.27, front) * CFrame.Angles(0, 0, sx * math.rad(10)), a.Color, RUBBER)
	end
	attach(ctx, "UpperTorso", "Stetho", Vector3.new(0.06, t.Y * 0.2, 0.06), CFrame.new(t.X * 0.16, -t.Y * 0.02, front), a.Color, RUBBER)
	attach(ctx, "UpperTorso", "StethoChest", Vector3.new(0.06, 0.2, 0.2), CFrame.new(t.X * 0.16, -t.Y * 0.14, front - 0.02) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(200, 204, 212), METAL, { Shape = Enum.PartType.Cylinder })
end

function A.IdBadge(ctx, a)
	local t = sizeOf(ctx.Character, "UpperTorso")
	local front = -t.Z / 2 - 0.035
	attach(ctx, "UpperTorso", "IdCard", Vector3.new(t.X * 0.13, t.Y * 0.17, 0.03), CFrame.new(-t.X * 0.3, t.Y * 0.06, front), a.Color, SMOOTH)
	attach(ctx, "UpperTorso", "IdStripe", Vector3.new(t.X * 0.13, t.Y * 0.04, 0.035), CFrame.new(-t.X * 0.3, t.Y * 0.125, front - 0.005), a.Trim or a.Color, SMOOTH)
	attach(ctx, "UpperTorso", "IdClip", Vector3.new(0.06, 0.08, 0.04), CFrame.new(-t.X * 0.3, t.Y * 0.16, front - 0.01), Color3.fromRGB(200, 204, 212), METAL)
end

function A.TacticalVest(ctx, a)
	local t = sizeOf(ctx.Character, "UpperTorso")
	local trim = a.Trim or shade(a.Color, 0.15)
	local front = -t.Z * 0.58
	attach(ctx, "UpperTorso", "Vest", Vector3.new(t.X * 1.07, t.Y * 0.82, t.Z * 1.16), CFrame.new(0, t.Y * 0.03, 0), a.Color, FABRIC)
	for _, sx in { -1, 1 } do
		attach(ctx, "UpperTorso", "VestStrap", Vector3.new(t.X * 0.2, 0.1, t.Z * 1.17), CFrame.new(sx * t.X * 0.3, t.Y * 0.46, 0), a.Color, FABRIC)
	end
	for _, x in { -0.3, 0, 0.3 } do
		attach(ctx, "UpperTorso", "VestPouch", Vector3.new(t.X * 0.2, t.Y * 0.22, 0.12), CFrame.new(x * t.X, -t.Y * 0.17, front - 0.05), trim, FABRIC)
		attach(ctx, "UpperTorso", "PouchFlap", Vector3.new(t.X * 0.21, t.Y * 0.05, 0.13), CFrame.new(x * t.X, -t.Y * 0.07, front - 0.05), shade(trim, -0.15), FABRIC)
	end
	attach(ctx, "UpperTorso", "VestPouch", Vector3.new(t.X * 0.24, t.Y * 0.14, 0.1), CFrame.new(-t.X * 0.24, t.Y * 0.2, front - 0.04), trim, FABRIC)
	if type(a.Back) == "string" then
		local back = attach(ctx, "UpperTorso", "VestBack", Vector3.new(t.X * 0.74, t.Y * 0.22, 0.04), CFrame.new(0, t.Y * 0.2, t.Z * 0.6), a.Color, FABRIC)
		print3d(back, Enum.NormalId.Back, a.Back, Color3.fromRGB(235, 235, 240))
	end
end

-- Cintura -------------------------------------------------------------
function A.Belt(ctx, a)
	local w = sizeOf(ctx.Character, "LowerTorso")
	attach(ctx, "LowerTorso", "Belt", Vector3.new(w.X * 1.05, w.Y * 0.3, w.Z * 1.08), CFrame.new(0, w.Y * 0.32, 0), a.Color, if a.Pouches then FABRIC else SMOOTH)
	local big = a.Big == true
	attach(ctx, "LowerTorso", "Buckle", Vector3.new(w.X * (if big then 0.22 else 0.13), w.Y * (if big then 0.42 else 0.28), 0.05), CFrame.new(0, w.Y * 0.32, -w.Z * 0.54 - 0.02), a.Buckle or Color3.fromRGB(200, 204, 212), METAL, { Reflectance = 0.2 })
	if a.Pouches then
		for _, sx in { -1, 1 } do
			attach(ctx, "LowerTorso", "BeltPouch", Vector3.new(0.14, w.Y * 0.7, w.Z * 0.42), CFrame.new(sx * (w.X * 0.53 + 0.05), w.Y * 0.1, -w.Z * 0.1), a.Color, FABRIC)
		end
	end
end

function A.WaistChain(ctx, a)
	local w = sizeOf(ctx.Character, "LowerTorso")
	for i = 0, 7 do
		local u = i / 7
		local x = w.X * (0.12 + 0.4 * u)
		local y = w.Y * 0.3 - w.Y * 1.3 * math.sin(math.pi * u)
		local z = -w.Z * 0.53 - 0.03 + (w.Z * 0.5) * u * u
		attach(ctx, "LowerTorso", "WaistChain", Vector3.new(0.09, 0.09, 0.05), CFrame.new(x, y, z), a.Color, METAL)
	end
end

-- Faldas y faldones: un anillo de paneles alrededor de la cintura que se abre hacia abajo
-- (band: solo la franja de abajo, de ese alto: ribetes)
local function skirtRing(ctx, name: string, length: number, flare: number, n: number, color: Color3, material: Enum.Material, props: { [string]: any }?, skip: ((number) -> boolean)?, pleats: boolean?, band: number?)
	local w = sizeOf(ctx.Character, "LowerTorso")
	local rx, rz = w.X * 0.53, w.Z * 0.56
	for i = 0, n - 1 do
		local ang = (i / n) * math.pi * 2
		if not (skip and skip(ang)) then
			-- (radio de la elipse en esa dirección)
			local sa, ca = math.sin(ang), math.cos(ang)
			local r = 1 / math.sqrt((sa / rx) ^ 2 + (ca / rz) ^ 2)
			local rBottom = r * flare
			local tilt = math.atan((rBottom - r) / length)
			local width = 2 * math.pi * ((r + rBottom) / 2) / n * 1.18
			local c = if pleats and i % 2 == 1 then shade(color, -0.1) else color
			local h = band or length
			attach(ctx, "LowerTorso", name, Vector3.new(width, h, if band then 0.075 else 0.07), CFrame.new(0, w.Y * 0.5, 0) * CFrame.Angles(0, ang, 0) * CFrame.new(0, 0, -r) * CFrame.Angles(tilt, 0, 0) * CFrame.new(0, -length + h / 2, if band then -0.006 else 0), c, material, props)
		end
	end
end

function A.Skirt(ctx, a)
	local leg = sizeOf(ctx.Character, "LeftUpperLeg")
	local w = sizeOf(ctx.Character, "LowerTorso")
	local length = w.Y * 0.5 + leg.Y * 0.6
	skirtRing(ctx, "Skirt", length, 1.3, 14, a.Color, FABRIC, nil, nil, a.Pleats)
	if a.Trim then
		skirtRing(ctx, "SkirtHem", length, 1.3, 14, a.Trim, FABRIC, nil, nil, false, 0.08)
	end
end

function A.Gown(ctx, a)
	local upper = sizeOf(ctx.Character, "LeftUpperLeg")
	local lower = sizeOf(ctx.Character, "LeftLowerLeg")
	local foot = sizeOf(ctx.Character, "LeftFoot")
	local w = sizeOf(ctx.Character, "LowerTorso")
	local length = w.Y * 0.5 + upper.Y + lower.Y + foot.Y * 0.3
	local props = { Reflectance = if a.Satin then 0.08 else nil, Transparency = if a.Sheer then 0.12 else nil }
	local slit = a.Slit and not ctx.Kid
	skirtRing(ctx, "Gown", length, 1.75, 16, a.Color, SMOOTH, props, if slit then function(ang)
		return ang > math.rad(300) and ang < math.rad(340)
	end else nil)
end

function A.CoatTails(ctx, a)
	local upper = sizeOf(ctx.Character, "LeftUpperLeg")
	local lower = sizeOf(ctx.Character, "LeftLowerLeg")
	local w = sizeOf(ctx.Character, "LowerTorso")
	local length = w.Y * 0.6 + upper.Y + lower.Y * 0.45
	skirtRing(ctx, "CoatTail", length, 1.2, 12, a.Color, FABRIC, nil, function(ang)
		return ang < math.rad(20) or ang > math.rad(340) -- (abierto por delante)
	end)
	local t = sizeOf(ctx.Character, "UpperTorso")
	for _, sx in { -1, 1 } do
		attach(ctx, "UpperTorso", "Lapel", Vector3.new(t.X * 0.12, t.Y * 0.5, 0.06), CFrame.new(sx * t.X * 0.2, t.Y * 0.22, -t.Z / 2 - 0.04) * CFrame.Angles(0, 0, sx * math.rad(-18)), shade(a.Color, 0.08), FABRIC)
	end
end

-- Brazos y manos --------------------------------------------------------
local function eachSide(fn: (string, number) -> ())
	fn("Left", -1)
	fn("Right", 1)
end

function A.Wristbands(ctx, a)
	eachSide(function(side, _)
		if a.Left and side == "Right" then
			return
		end
		local arm = sizeOf(ctx.Character, side .. "LowerArm")
		attach(ctx, side .. "LowerArm", "Wristband", Vector3.new(arm.X * 1.14, arm.Y * 0.18, arm.Z * 1.14), CFrame.new(0, -arm.Y * 0.36, 0), a.Color, FABRIC)
	end)
end

function A.Watch(ctx, a)
	local arm = sizeOf(ctx.Character, "LeftLowerArm")
	attach(ctx, "LeftLowerArm", "WatchStrap", Vector3.new(arm.X * 1.08, arm.Y * 0.1, arm.Z * 1.08), CFrame.new(0, -arm.Y * 0.36, 0), a.Color, SMOOTH)
	attach(ctx, "LeftLowerArm", "WatchFace", Vector3.new(0.06, arm.Z * 0.42, arm.Z * 0.42), CFrame.new(-arm.X * 0.56, -arm.Y * 0.36, 0), Color3.fromRGB(30, 30, 34), GLASS, { Shape = Enum.PartType.Cylinder, Reflectance = 0.3 })
end

function A.Armband(ctx, a)
	local arm = sizeOf(ctx.Character, "LeftUpperArm")
	attach(ctx, "LeftUpperArm", "Armband", Vector3.new(arm.X * 1.1, arm.Y * 0.26, arm.Z * 1.1), CFrame.new(0, -arm.Y * 0.05, 0), a.Color, FABRIC)
	attach(ctx, "LeftUpperArm", "ArmPhone", Vector3.new(0.06, arm.Y * 0.34, arm.Z * 0.56), CFrame.new(-arm.X * 0.58, -arm.Y * 0.05, 0), Color3.fromRGB(14, 14, 18), GLASS, { Reflectance = 0.3 })
end

function A.Gloves(ctx, a)
	eachSide(function(side, _)
		local hand = sizeOf(ctx.Character, side .. "Hand")
		local arm = sizeOf(ctx.Character, side .. "LowerArm")
		attach(ctx, side .. "Hand", "Glove", hand * 1.12, CFrame.new(), a.Color, FABRIC)
		attach(ctx, side .. "LowerArm", "GloveCuff", Vector3.new(arm.X * 1.14, arm.Y * 0.14, arm.Z * 1.14), CFrame.new(0, -arm.Y * 0.44, 0), shade(a.Color, 0.06), FABRIC)
	end)
end

function A.Fringe(ctx, a)
	local strand = shade(a.Color, 0.05)
	if a.Chest then
		local t = sizeOf(ctx.Character, "UpperTorso")
		for i = -5, 5 do
			attach(ctx, "UpperTorso", "Fringe", Vector3.new(0.05, t.Y * 0.2, 0.05), CFrame.new(i * t.X * 0.085, -t.Y * 0.2, -t.Z / 2 - 0.04), strand, FABRIC, { Shadow = false })
		end
		return
	end
	eachSide(function(side, sx)
		for _, part in { side .. "UpperArm", side .. "LowerArm" } do
			local arm = sizeOf(ctx.Character, part)
			for k = -2, 2 do
				attach(ctx, part, "Fringe", Vector3.new(0.05, arm.Y * 0.45, 0.05), CFrame.new(sx * (arm.X / 2 + 0.04), -arm.Y * 0.12, k * arm.Z * 0.18), strand, FABRIC, { Shadow = false })
			end
		end
	end)
	local t = sizeOf(ctx.Character, "UpperTorso")
	for i = -5, 5 do
		attach(ctx, "UpperTorso", "Fringe", Vector3.new(0.05, t.Y * 0.28, 0.05), CFrame.new(i * t.X * 0.085, t.Y * 0.06, t.Z / 2 + 0.04), strand, FABRIC, { Shadow = false })
	end
end

-- Bolsos, mochilas y cosas en la mano --------------------------------------
function A.Handbag(ctx, a)
	local t = sizeOf(ctx.Character, "UpperTorso")
	local trim = a.Trim or Color3.fromRGB(230, 190, 80)
	attach(ctx, "LeftHand", "Handbag", Vector3.new(t.Z * 0.28, t.Y * 0.3, t.X * 0.42), CFrame.new(0, -t.Y * 0.3, 0), a.Color, SMOOTH, { Reflectance = 0.05 })
	attach(ctx, "LeftHand", "BagFlap", Vector3.new(t.Z * 0.3, t.Y * 0.12, t.X * 0.43), CFrame.new(0, -t.Y * 0.2, 0), shade(a.Color, 0.06), SMOOTH)
	attach(ctx, "LeftHand", "BagClasp", Vector3.new(t.Z * 0.31, 0.08, 0.1), CFrame.new(0, -t.Y * 0.25, 0), trim, METAL, { Reflectance = 0.3 })
	for _, sz in { -1, 1 } do
		attach(ctx, "LeftHand", "BagHandle", Vector3.new(0.05, t.Y * 0.2, 0.05), CFrame.new(0, -t.Y * 0.06, sz * t.X * 0.08), a.Color, SMOOTH)
	end
end

function A.ShoulderBag(ctx, a)
	local t = sizeOf(ctx.Character, "UpperTorso")
	local strap = a.Trim or shade(a.Color, -0.3)
	attach(ctx, "UpperTorso", "BagStrap", Vector3.new(0.08, t.Y * 1.3, 0.05), CFrame.new(-t.X * 0.02, -t.Y * 0.02, -t.Z / 2 - 0.04) * CFrame.Angles(0, 0, math.rad(-38)), strap, FABRIC)
	attach(ctx, "UpperTorso", "BagStrap", Vector3.new(0.08, t.Y * 1.3, 0.05), CFrame.new(-t.X * 0.02, -t.Y * 0.02, t.Z / 2 + 0.04) * CFrame.Angles(0, 0, math.rad(-38)), strap, FABRIC)
	attach(ctx, "UpperTorso", "ShoulderBag", Vector3.new(t.Z * 0.3, t.Y * 0.32, t.X * 0.36), CFrame.new(-t.X * 0.6, -t.Y * 0.6, 0), a.Color, FABRIC)
	attach(ctx, "UpperTorso", "BagFlap", Vector3.new(t.Z * 0.32, t.Y * 0.12, t.X * 0.37), CFrame.new(-t.X * 0.6, -t.Y * 0.48, 0), shade(a.Color, -0.12), FABRIC)
end

function A.Backpack(ctx, a)
	local t = sizeOf(ctx.Character, "UpperTorso")
	local trim = a.Trim or shade(a.Color, 0.3)
	local bag = CFrame.new(0, -t.Y * 0.06, t.Z * 0.5 + t.Z * 0.36)
	attach(ctx, "UpperTorso", "Backpack", Vector3.new(t.X * 0.8, t.Y * 1.05, t.Z * 0.7), bag, a.Color, FABRIC)
	attach(ctx, "UpperTorso", "BackpackPocket", Vector3.new(t.X * 0.58, t.Y * 0.42, t.Z * 0.22), bag * CFrame.new(0, -t.Y * 0.2, t.Z * 0.44), shade(a.Color, 0.06), FABRIC)
	attach(ctx, "UpperTorso", "BackpackZip", Vector3.new(t.X * 0.6, 0.05, 0.05), bag * CFrame.new(0, 0.02, t.Z * 0.56), trim, METAL)
	for _, sx in { -1, 1 } do
		attach(ctx, "UpperTorso", "BackpackBuckle", Vector3.new(t.X * 0.08, t.Y * 0.1, 0.06), bag * CFrame.new(sx * t.X * 0.2, -t.Y * 0.1, t.Z * 0.56), trim, METAL)
		attach(ctx, "UpperTorso", "Strap", Vector3.new(t.X * 0.1, t.Y * 1.0, 0.08), CFrame.new(sx * t.X * 0.38, 0, -t.Z / 2 - 0.05), shade(a.Color, -0.2), FABRIC)
		attach(ctx, "UpperTorso", "StrapTop", Vector3.new(t.X * 0.1, 0.08, t.Z * 1.1), CFrame.new(sx * t.X * 0.38, t.Y / 2 + 0.03, 0), shade(a.Color, -0.2), FABRIC)
	end
	attach(ctx, "UpperTorso", "ChestStrap", Vector3.new(t.X * 0.86, 0.07, 0.06), CFrame.new(0, t.Y * 0.12, -t.Z / 2 - 0.07), trim, FABRIC)
end

function A.Skateboard(ctx, a)
	local t = sizeOf(ctx.Character, "UpperTorso")
	local trim = a.Trim or Color3.new(1, 1, 1)
	local deck = CFrame.new(0, -t.Y * 0.08, t.Z * 0.5 + 0.12) * CFrame.Angles(0, 0, math.rad(14))
	local length, width = t.Y * 1.6, t.X * 0.5
	attach(ctx, "UpperTorso", "Deck", Vector3.new(width, length - width, 0.07), deck, a.Color, SMOOTH)
	for _, sy in { -1, 1 } do
		attach(ctx, "UpperTorso", "DeckTip", Vector3.new(width, 0.07, width), deck * CFrame.new(0, sy * (length - width) / 2, 0) * CFrame.Angles(math.pi / 2, 0, 0), a.Color, SMOOTH, CYL)
		local truck = deck * CFrame.new(0, sy * length * 0.32, 0.09)
		attach(ctx, "UpperTorso", "Truck", Vector3.new(width * 0.8, 0.08, 0.08), truck, Color3.fromRGB(190, 194, 200), METAL)
		for _, sx in { -1, 1 } do
			attach(ctx, "UpperTorso", "Wheel", Vector3.new(0.1, 0.16, 0.16), truck * CFrame.new(sx * width * 0.42, 0, 0.06), trim, SMOOTH, { Shape = Enum.PartType.Cylinder })
		end
	end
	attach(ctx, "UpperTorso", "DeckArt", Vector3.new(width * 0.5, length * 0.5, 0.075), deck * CFrame.new(0, 0, 0.004), trim, SMOOTH)
end

function A.HelmetInHand(ctx, a)
	local h = sizeOf(ctx.Character, "Head")
	local hand = sizeOf(ctx.Character, "RightHand")
	local size = h.Y * 1.3
	local at = CFrame.new(hand.X * 0.5 + size * 0.36, -size * 0.18, 0)
	attach(ctx, "RightHand", "Helmet", Vector3.new(size, size * 1.02, size * 1.08), at, a.Color, SMOOTH, { Mesh = "Sphere", Reflectance = 0.1 })
	attach(ctx, "RightHand", "HelmetVisor", Vector3.new(size * 0.74, size * 0.26, size * 0.2), at * CFrame.new(0, size * 0.04, -size * 0.45), Color3.fromRGB(16, 16, 20), GLASS, { Mesh = "Sphere", Reflectance = 0.35 })
	attach(ctx, "RightHand", "HelmetStripe", Vector3.new(size * 0.2, size * 1.04, size * 1.1), at, a.Trim or Color3.new(1, 0, 0), SMOOTH, SPHERE)
end

function A.Racket(ctx, a)
	local t = sizeOf(ctx.Character, "UpperTorso")
	local trim = a.Trim or Color3.new(1, 1, 1)
	attach(ctx, "RightHand", "RacketGrip", Vector3.new(0.12, t.Y * 0.36, 0.12), CFrame.new(0, -t.Y * 0.1, 0), Color3.fromRGB(30, 30, 34), FABRIC, CYL)
	local center = CFrame.new(0.05, -t.Y * 0.62, 0)
	local ry, rz, n = t.Y * 0.26, t.Y * 0.2, 16
	for i = 1, n do
		local ang = (i / n) * math.pi * 2
		local y, z = math.cos(ang) * ry, math.sin(ang) * rz
		local tangent = math.atan2(math.sin(ang) * ry, math.cos(ang) * rz)
		attach(ctx, "RightHand", "RacketFrame", Vector3.new(0.06, 0.06, 2 * math.pi * math.max(ry, rz) / n * 1.1), center * CFrame.new(0, y, z) * CFrame.Angles(tangent, 0, 0), a.Color, SMOOTH, { Shadow = false })
	end
	attach(ctx, "RightHand", "RacketStrings", Vector3.new(0.02, ry * 1.85, rz * 1.85), center, Color3.fromRGB(245, 245, 245), SMOOTH, { Mesh = "Sphere", Transparency = 0.45, Shadow = false })
	attach(ctx, "RightHand", "RacketThroat", Vector3.new(0.06, t.Y * 0.12, 0.06), CFrame.new(0.03, -t.Y * 0.3, 0), trim, SMOOTH)
end

function A.Basketball(ctx, a)
	local t = sizeOf(ctx.Character, "UpperTorso")
	local d = t.X * 0.42
	local at = CFrame.new(-d * 0.42, -d * 0.3, 0)
	attach(ctx, "LeftHand", "Basketball", Vector3.new(d, d, d), at, a.Color, SMOOTH, { Shape = Enum.PartType.Ball })
	attach(ctx, "LeftHand", "BallSeam", Vector3.new(d * 1.01, 0.03, d * 1.01), at, Color3.fromRGB(20, 20, 20), SMOOTH, CYL)
	attach(ctx, "LeftHand", "BallSeam", Vector3.new(d * 1.01, 0.03, d * 1.01), at * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(20, 20, 20), SMOOTH, CYL)
end

function A.Wings(ctx, a)
	local t = sizeOf(ctx.Character, "UpperTorso")
	local glow = a.Glow or Color3.fromRGB(255, 245, 220)
	local base = CFrame.new(0, t.Y * 0.2, t.Z * 0.5 + 0.1)
	local rows = {
		{ N = 8, Len = 1.0, Width = 0.17, Z = 0, Color = a.Color },
		{ N = 6, Len = 0.62, Width = 0.19, Z = 0.05, Color = shade(a.Color, -0.03) },
		{ N = 4, Len = 0.34, Width = 0.22, Z = 0.1, Color = shade(a.Color, -0.06) },
	}
	for _, sx in { -1, 1 } do
		local root = base * CFrame.new(sx * t.X * 0.16, 0, 0) * CFrame.Angles(0, sx * math.rad(-16), 0)
		for r, row in rows do
			for i = 0, row.N - 1 do
				local u = i / (row.N - 1)
				local ang = math.rad(68 - 140 * u)
				local len = t.Y * row.Len * (0.85 + 0.9 * math.sin(math.pi * (0.15 + u * 0.75)))
				local dirX, dirY = sx * math.cos(ang), math.sin(ang)
				local phi = math.atan2(-dirX, dirY)
				local cf = root * CFrame.new(0, 0, row.Z) * CFrame.Angles(0, 0, phi) * CFrame.new(0, len / 2, 0)
				attach(ctx, "UpperTorso", "Feather", Vector3.new(t.X * row.Width, len, 0.06), cf, row.Color, SMOOTH, { Shadow = false })
				if r == 1 then
					-- Brillo suave alrededor de las plumas largas
					attach(ctx, "UpperTorso", "WingGlow", Vector3.new(t.X * row.Width * 1.5, len * 1.08, 0.04), root * CFrame.new(0, 0, -0.03) * CFrame.Angles(0, 0, phi) * CFrame.new(0, len * 0.54, 0), glow, NEON, { Transparency = 0.82, Shadow = false })
				end
			end
		end
		local joint = attach(ctx, "UpperTorso", "WingRoot", Vector3.new(t.X * 0.22, t.Y * 0.3, 0.14), root, a.Color, SMOOTH, { Mesh = "Sphere", Shadow = false })
		if joint and sx == 1 then
			local light = Instance.new("PointLight")
			light.Color = glow
			light.Range = 9
			light.Brightness = 0.55
			light.Parent = joint
		end
	end
end

---------------------------------------------------------------------
-- Zapatos (siempre 3D)
---------------------------------------------------------------------
local SHOES = {}
local function sole(ctx, side, f, color, height)
	attach(ctx, side .. "Foot", "Sole", Vector3.new(f.X * 1.2, f.Y * height, f.Z * 1.24), CFrame.new(0, -f.Y * (0.5 - height / 2) - 0.02, -f.Z * 0.05), color, RUBBER)
end
function SHOES.Sneaker(ctx, side, sx, s, f, l)
	attach(ctx, side .. "Foot", "Sneaker", Vector3.new(f.X * 1.14, f.Y * 1.05, f.Z * 1.18), CFrame.new(0, 0, -f.Z * 0.05), s.Color, SMOOTH)
	sole(ctx, side, f, s.Sole or Color3.fromRGB(230, 230, 232), 0.32)
	attach(ctx, side .. "Foot", "ToeCap", Vector3.new(f.X * 1.16, f.Y * 0.5, f.Z * 0.24), CFrame.new(0, -f.Y * 0.18, -f.Z * 0.6), s.Sole or s.Color, SMOOTH)
	attach(ctx, side .. "Foot", "Laces", Vector3.new(f.X * 0.45, 0.05, f.Z * 0.4), CFrame.new(0, f.Y * 0.55, -f.Z * 0.2), shade(s.Color, -0.12), SMOOTH)
	if s.Trim then
		attach(ctx, side .. "Foot", "ShoeStripe", Vector3.new(0.03, f.Y * 0.4, f.Z * 0.62), CFrame.new(sx * f.X * 0.58, 0, -f.Z * 0.05) * CFrame.Angles(math.rad(-18), 0, 0), s.Trim, SMOOTH)
		attach(ctx, side .. "Foot", "HeelTab", Vector3.new(f.X * 0.3, f.Y * 0.7, 0.05), CFrame.new(0, f.Y * 0.2, f.Z * 0.56), s.Trim, SMOOTH)
	end
end
function SHOES.HighTop(ctx, side, sx, s, f, l)
	SHOES.Sneaker(ctx, side, sx, s, f, l)
	attach(ctx, side .. "LowerLeg", "ShoeCollar", Vector3.new(l.X * 1.13, l.Y * 0.24, l.Z * 1.13), CFrame.new(0, -l.Y * 0.39, 0), s.Color, SMOOTH)
	if s.Trim then
		attach(ctx, side .. "LowerLeg", "ShoeCollarTrim", Vector3.new(l.X * 1.15, l.Y * 0.05, l.Z * 1.15), CFrame.new(0, -l.Y * 0.28, 0), s.Trim, SMOOTH)
	end
end
function SHOES.Dress(ctx, side, sx, s, f, l)
	attach(ctx, side .. "Foot", "DressShoe", Vector3.new(f.X * 1.08, f.Y * 0.95, f.Z * 1.16), CFrame.new(0, 0, -f.Z * 0.06), s.Color, SMOOTH, { Reflectance = 0.18 })
	sole(ctx, side, f, s.Sole or s.Color, 0.18)
end
function SHOES.Flat(ctx, side, sx, s, f, l)
	attach(ctx, side .. "Foot", "Flat", Vector3.new(f.X * 1.06, f.Y * 0.8, f.Z * 1.12), CFrame.new(0, -f.Y * 0.08, -f.Z * 0.05), s.Color, SMOOTH)
	sole(ctx, side, f, s.Sole or s.Color, 0.16)
end
function SHOES.Boot(ctx, side, sx, s, f, l)
	attach(ctx, side .. "Foot", "Boot", Vector3.new(f.X * 1.14, f.Y * 1.08, f.Z * 1.2), CFrame.new(0, 0, -f.Z * 0.05), s.Color, SMOOTH)
	attach(ctx, side .. "LowerLeg", "BootShaft", Vector3.new(l.X * 1.14, l.Y * 0.42, l.Z * 1.14), CFrame.new(0, -l.Y * 0.3, 0), s.Color, SMOOTH)
	sole(ctx, side, f, s.Sole or Color3.fromRGB(30, 30, 32), 0.4)
	attach(ctx, side .. "LowerLeg", "BootLaces", Vector3.new(l.X * 0.3, l.Y * 0.38, 0.04), CFrame.new(0, -l.Y * 0.3, -l.Z * 0.58), s.Trim or shade(s.Color, 0.2), FABRIC)
end
function SHOES.Combat(ctx, side, sx, s, f, l)
	SHOES.Boot(ctx, side, sx, s, f, l)
	for _, y in { -0.18, -0.36 } do
		attach(ctx, side .. "LowerLeg", "BootStrap", Vector3.new(l.X * 1.16, l.Y * 0.05, l.Z * 1.16), CFrame.new(0, l.Y * y, 0), shade(s.Color, 0.15), FABRIC)
	end
end
function SHOES.Heel(ctx, side, sx, s, f, l)
	attach(ctx, side .. "Foot", "HeelShoe", Vector3.new(f.X * 1.02, f.Y * 0.62, f.Z * 1.06), CFrame.new(0, f.Y * 0.12, -f.Z * 0.04), s.Color, SMOOTH, { Reflectance = 0.1 })
	attach(ctx, side .. "Foot", "HeelSole", Vector3.new(f.X * 1.02, f.Y * 0.22, f.Z * 0.5), CFrame.new(0, -f.Y * 0.38, -f.Z * 0.28), s.Sole or s.Color, SMOOTH)
	attach(ctx, side .. "Foot", "HeelPost", Vector3.new(f.X * 0.2, f.Y * 0.9, f.Z * 0.14), CFrame.new(0, -f.Y * 0.08, f.Z * 0.43), s.Sole or s.Color, SMOOTH)
	attach(ctx, side .. "LowerLeg", "AnkleStrap", Vector3.new(l.X * 1.06, l.Y * 0.06, l.Z * 1.06), CFrame.new(0, -l.Y * 0.46, 0), s.Color, SMOOTH)
end
function SHOES.Platform(ctx, side, sx, s, f, l)
	attach(ctx, side .. "Foot", "Boot", Vector3.new(f.X * 1.14, f.Y * 1.05, f.Z * 1.2), CFrame.new(0, 0, -f.Z * 0.05), s.Color, SMOOTH)
	sole(ctx, side, f, s.Sole or Color3.fromRGB(30, 30, 32), 0.6)
	local tall = s.Tall == true
	local shaft = if tall then 0.98 else 0.45
	attach(ctx, side .. "LowerLeg", "BootShaft", Vector3.new(l.X * 1.14, l.Y * shaft, l.Z * 1.14), CFrame.new(0, -l.Y * (0.5 - shaft / 2), 0), s.Color, SMOOTH, { Reflectance = 0.08 })
	if s.Trim then
		for k = 1, if tall then 3 else 1 do
			attach(ctx, side .. "LowerLeg", "BootBuckle", Vector3.new(l.X * 1.16, l.Y * 0.05, l.Z * 1.16), CFrame.new(0, -l.Y * (0.45 - k * 0.22), 0), s.Trim, METAL)
		end
	end
end
function SHOES.Cowboy(ctx, side, sx, s, f, l)
	attach(ctx, side .. "Foot", "CowboyBoot", Vector3.new(f.X * 1.1, f.Y * 1.05, f.Z * 1.12), CFrame.new(0, 0, 0), s.Color, SMOOTH)
	attach(ctx, side .. "Foot", "BootToe", Vector3.new(f.X * 0.8, f.Y * 0.7, f.Z * 0.4), CFrame.new(0, -f.Y * 0.12, -f.Z * 0.7) * CFrame.Angles(0, math.pi, 0), s.Color, SMOOTH, { Class = "WedgePart" })
	attach(ctx, side .. "Foot", "BootHeel", Vector3.new(f.X * 0.6, f.Y * 0.5, f.Z * 0.26), CFrame.new(0, -f.Y * 0.35, f.Z * 0.45), s.Sole or shade(s.Color, -0.4), SMOOTH)
	attach(ctx, side .. "LowerLeg", "BootShaft", Vector3.new(l.X * 1.16, l.Y * 0.58, l.Z * 1.16), CFrame.new(0, -l.Y * 0.21, 0), s.Color, SMOOTH)
	attach(ctx, side .. "LowerLeg", "BootStitch", Vector3.new(l.X * 1.18, l.Y * 0.05, l.Z * 1.18), CFrame.new(0, l.Y * 0.04, 0), s.Trim or shade(s.Color, 0.3), FABRIC)
end
function SHOES.Sandal(ctx, side, sx, s, f, l)
	sole(ctx, side, f, s.Sole or s.Color, 0.28)
	for _, z in { -0.32, 0.05 } do
		attach(ctx, side .. "Foot", "SandalStrap", Vector3.new(f.X * 1.08, f.Y * 0.2, f.Z * 0.14), CFrame.new(0, f.Y * 0.32, f.Z * z), s.Color, SMOOTH)
	end
	attach(ctx, side .. "LowerLeg", "AnkleStrap", Vector3.new(l.X * 1.06, l.Y * 0.06, l.Z * 1.06), CFrame.new(0, -l.Y * 0.46, 0), s.Color, SMOOTH)
end
OutfitBuilder.Shoes = SHOES

---------------------------------------------------------------------
-- Ropa clásica (plantillas) e ids
---------------------------------------------------------------------
function OutfitBuilder.idsFor(key: string?): (string?, string?)
	if type(key) ~= "string" then
		return nil, nil
	end
	local base = string.lower(key)
	local shirt, pants = (OutfitIds :: any)[base .. "_shirt"], (OutfitIds :: any)[base .. "_pants"]
	-- (Images.of: del id del Decal al de su imagen, si el servidor ya lo ha resuelto)
	return (if type(shirt) == "string" and shirt ~= "" then Images.of(shirt) else nil), (if type(pants) == "string" and pants ~= "" then Images.of(pants) else nil)
end

-- Quita la ropa clásica que puso el aspecto de Valmar (all = cualquier Shirt/Pants del personaje)
function OutfitBuilder.clearClothes(character: Instance, all: boolean?)
	for _, child in character:GetChildren() do
		if child.Name == "ValmarShirt" or child.Name == "ValmarPants" or (all and (child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic"))) then
			child:Destroy()
		end
	end
end

---------------------------------------------------------------------
-- Colores del cuerpo y detalles del modo sin plantillas
---------------------------------------------------------------------
local R15_PARTS = {
	UpperTorso = true, LowerTorso = true, LeftUpperArm = true, LeftLowerArm = true, LeftHand = true, RightUpperArm = true,
	RightLowerArm = true, RightHand = true, LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true, RightUpperLeg = true,
	RightLowerLeg = true, RightFoot = true,
}
OutfitBuilder.BodyParts = R15_PARTS

-- Ropa con forma: una funda un poco más grande que la parte del cuerpo (en R6 también sobre las
-- partes virtuales; así unos pantalones cortos acaban en el muslo)
local function shell(ctx, at: string, name: string, scale: Vector3, yFrac: number, hFrac: number, color: Color3, material: Enum.Material?)
	local s = sizeOf(ctx.Character, at)
	return attach(ctx, at, name, Vector3.new(s.X * scale.X, s.Y * hFrac, s.Z * scale.Z), CFrame.new(0, s.Y * yFrac, 0), color, material or FABRIC)
end

local function paintBody(ctx, def)
	local top, bottom, shoes = def.Top, def.Bottom, def.Shoes
	local skin, kid, r6 = ctx.Skin, ctx.Kid, ctx.R6
	local fabric = FABRIC
	-- Todo piel para empezar (cara, manos, lo que no tapa la ropa)
	for name in R15_PARTS do
		paint(ctx, { name }, skin)
	end
	paint(ctx, { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }, skin)
	local sleeve = top.Sleeve or top.Color
	local midriff = top.Midriff and not kid
	local sheer = if bottom.Fishnet then (if kid then bottom.Color else skin:Lerp(Color3.new(0.05, 0.05, 0.06), 0.55)) else nil

	if ctx.Textured then
		-- La plantilla pinta la ropa; debajo, piel (y en talla de niño, la tripa tapada)
		if top.Midriff and kid then
			paint(ctx, { "UpperTorso" }, top.Inner or top.Color)
		end
		if sheer then
			paint(ctx, { "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "Left Leg", "Right Leg" }, sheer)
		end
		return
	end

	-- Torso (con el ombligo al aire: un top corto encima de la piel; si es una chaqueta abierta sobre
	-- un top corto, los dos lados de la chaqueta llegan hasta abajo)
	if midriff then
		shell(ctx, "UpperTorso", "Crop", Vector3.new(1.02, 1, 1.05), 0.2, 0.62, if top.Open and top.Inner then top.Inner else top.Color)
		if top.Open and top.Inner then
			for _, sx in { -1, 1 } do
				local t = sizeOf(ctx.Character, "UpperTorso")
				attach(ctx, "UpperTorso", "JacketSide", Vector3.new(t.X * 0.31, t.Y * 0.99, t.Z * 1.07), CFrame.new(sx * t.X * 0.355, 0, 0), top.Color, fabric)
			end
		end
	else
		paint(ctx, { "UpperTorso", "Torso" }, top.Color, fabric)
	end
	if r6 then
		shell(ctx, "LowerTorso", "Waist", Vector3.new(1.02, 1, 1.04), 0, 1, bottom.Color)
	end
	paint(ctx, { "LowerTorso" }, bottom.Color, fabric)
	-- Brazos
	local function arm(side: string)
		if top.Sleeves == "Long" then
			paint(ctx, { side .. "UpperArm", side .. "LowerArm" }, sleeve, fabric)
			if r6 then
				paint(ctx, { side .. " Arm" }, sleeve, fabric)
				shell(ctx, side .. "Hand", "Hand", Vector3.new(1.02, 1, 1.02), 0, 1, skin, SMOOTH)
			end
		elseif top.Sleeves == "Short" then
			paint(ctx, { side .. "UpperArm" }, sleeve, fabric)
			if r6 then
				shell(ctx, side .. "UpperArm", "Sleeve", Vector3.new(1.06, 1, 1.06), 0.12, 0.8, sleeve)
			end
		end
	end
	arm("Left")
	arm("Right")
	-- Piernas
	local legColor = sheer or bottom.Color
	local function leg(side: string)
		local len = bottom.Length
		if len == "Mini" then
			if sheer then
				paint(ctx, { side .. "UpperLeg", side .. "LowerLeg", side .. " Leg" }, sheer)
			end
		elseif len == "Short" or len == "Knee" then
			paint(ctx, { side .. "UpperLeg" }, bottom.Color, fabric)
			if r6 then
				shell(ctx, side .. "UpperLeg", "Shorts", Vector3.new(1.06, 1, 1.06), if len == "Knee" then -0.05 else 0.1, if len == "Knee" then 1.08 else 0.8, bottom.Color)
			end
		else
			paint(ctx, { side .. "UpperLeg", side .. "LowerLeg" }, legColor, fabric)
			if r6 then
				paint(ctx, { side .. " Leg" }, legColor, fabric)
			end
		end
	end
	leg("Left")
	leg("Right")
	if shoes.Kind ~= "Sandal" then
		paint(ctx, { "LeftFoot", "RightFoot" }, shoes.Color)
	end
end

-- Estampados y costuras hechos con piezas finas (solo sin plantillas)
local function fallbackDetails(ctx, def)
	local top, bottom = def.Top, def.Bottom
	local t = sizeOf(ctx.Character, "UpperTorso")
	local front, back = -t.Z / 2 - 0.025, t.Z / 2 + 0.025
	local kid = ctx.Kid
	local covered = top.Midriff and not kid
	local height = if covered then 0.62 else 0.98
	local yMid = if covered then t.Y * 0.2 else 0
	local rng = Random.new(def.Number or 1)

	-- Prenda abierta: la camiseta de dentro, cremallera y estampado de la camiseta
	if top.Open and top.Inner then
		local strip = attach(ctx, "UpperTorso", "InnerTee", Vector3.new(t.X * 0.38, t.Y * height, 0.05), CFrame.new(0, yMid, front), top.Inner, FABRIC)
		if top.InnerPrint then
			print3d(strip, Enum.NormalId.Front, top.InnerPrint.Text, top.InnerPrint.Color)
		end
		for _, sx in { -1, 1 } do
			attach(ctx, "UpperTorso", "JacketEdge", Vector3.new(t.X * 0.05, t.Y * (if top.Midriff then 0.98 else height), 0.06), CFrame.new(sx * t.X * 0.21, 0, front - 0.01), top.Trim or shade(top.Color, -0.2), FABRIC)
		end
	elseif top.Zip then
		attach(ctx, "UpperTorso", "Zip", Vector3.new(t.X * 0.03, t.Y * height, 0.05), CFrame.new(0, yMid, front - 0.005), Color3.fromRGB(120, 122, 128), METAL)
	end
	if top.Buttons and not top.Open then
		for k = 0, 3 do
			attach(ctx, "UpperTorso", "Button", Vector3.new(0.07, 0.07, 0.04), CFrame.new(0, t.Y * (0.32 - k * 0.22), front - 0.01), shade(top.Color, 0.35), SMOOTH)
		end
	end
	-- Colores en bloque (canesú)
	if top.Panel then
		attach(ctx, "UpperTorso", "Panel", Vector3.new(t.X * 1.02, t.Y * 0.32, t.Z * 1.04), CFrame.new(0, t.Y * 0.34, 0), top.Panel, FABRIC)
	end
	-- Bolsillos
	if top.Pocket == "Kangaroo" then
		attach(ctx, "UpperTorso", "Pocket", Vector3.new(t.X * 0.56, t.Y * 0.24, 0.05), CFrame.new(0, -t.Y * 0.28, front), shade(top.Color, -0.08), FABRIC)
	elseif top.Pocket == "Chest" then
		attach(ctx, "UpperTorso", "Pocket", Vector3.new(t.X * 0.18, t.Y * 0.18, 0.05), CFrame.new(-t.X * 0.26, t.Y * 0.16, front), shade(top.Color, -0.1), FABRIC)
	end
	-- Acolchado
	if top.Quilt then
		for _, y in { 0.28, 0.02, -0.24 } do
			if not covered or y > -0.1 then
				attach(ctx, "UpperTorso", "Quilt", Vector3.new(t.X * 1.03, 0.04, t.Z * 1.05), CFrame.new(0, t.Y * y, 0), shade(top.Color, -0.18), FABRIC)
			end
		end
	end
	-- Estampado de flores, grafiti, étnico…
	if top.Pattern then
		local colors = top.Pattern.Colors or { top.Color }
		for _ = 1, 14 do
			local z = if rng:NextNumber() < 0.5 then front - 0.005 else back + 0.005
			local w, hgt = t.X * (0.08 + rng:NextNumber() * 0.14), t.Y * (0.05 + rng:NextNumber() * 0.12)
			local x, y = (rng:NextNumber() - 0.5) * t.X * 0.8, yMid + (rng:NextNumber() - 0.5) * t.Y * height * 0.8
			attach(ctx, "UpperTorso", "Print", Vector3.new(w, hgt, 0.03), CFrame.new(x, y, z) * CFrame.Angles(0, 0, rng:NextNumber() * math.pi), colors[rng:NextInteger(2, math.max(2, #colors))] or colors[1], FABRIC, { Shadow = false })
		end
	end
	if top.SleeveStripes and top.Sleeves == "Long" then
		eachSide(function(side, _)
			for _, part in { side .. "UpperArm", side .. "LowerArm" } do
				local a = sizeOf(ctx.Character, part)
				for k = -1, 1 do
					attach(ctx, part, "SleeveStripe", Vector3.new(a.X * 1.03, a.Y * 0.1, a.Z * 1.03), CFrame.new(0, a.Y * k * 0.3, 0), top.SleeveStripes[2], FABRIC, { Shadow = false })
				end
			end
		end)
	end
	-- Rayas de las mangas y de las perneras
	if top.Stripe and top.Sleeves ~= "None" then
		eachSide(function(side, sx)
			for _, part in (if top.Sleeves == "Long" then { side .. "UpperArm", side .. "LowerArm" } else { side .. "UpperArm" }) do
				local a = sizeOf(ctx.Character, part)
				attach(ctx, part, "SleeveStripe", Vector3.new(0.04, a.Y * 0.98, a.Z * 0.18), CFrame.new(sx * (a.X / 2 + 0.02), 0, 0), top.Stripe, FABRIC, { Shadow = false })
			end
		end)
	end
	if bottom.Stripe then
		eachSide(function(side, sx)
			for _, part in (if bottom.Length == "Long" then { side .. "UpperLeg", side .. "LowerLeg" } else { side .. "UpperLeg" }) do
				local l = sizeOf(ctx.Character, part)
				attach(ctx, part, "LegStripe", Vector3.new(0.04, l.Y * 0.98, l.Z * 0.16), CFrame.new(sx * (l.X / 2 + 0.02), 0, 0), bottom.Stripe, FABRIC, { Shadow = false })
			end
		end)
	end
	-- Bolsillos de cargo y rotos
	if bottom.Pockets and bottom.Length ~= "Mini" then
		eachSide(function(side, sx)
			local l = sizeOf(ctx.Character, side .. "UpperLeg")
			if bottom.Kind == "Cargo" then
				attach(ctx, side .. "UpperLeg", "CargoPocket", Vector3.new(0.12, l.Y * 0.42, l.Z * 0.62), CFrame.new(sx * (l.X / 2 + 0.05), -l.Y * 0.1, 0), shade(bottom.Color, 0.06), FABRIC)
				attach(ctx, side .. "UpperLeg", "PocketFlap", Vector3.new(0.14, l.Y * 0.1, l.Z * 0.66), CFrame.new(sx * (l.X / 2 + 0.07), l.Y * 0.12, 0), shade(bottom.Color, -0.25), FABRIC)
			else
				attach(ctx, side .. "UpperLeg", "PocketSeam", Vector3.new(l.X * 0.36, 0.04, 0.04), CFrame.new(sx * l.X * 0.22, l.Y * 0.38, -l.Z / 2 - 0.02) * CFrame.Angles(0, 0, sx * math.rad(30)), shade(bottom.Color, -0.25), FABRIC)
			end
		end)
	end
	if bottom.Rips then
		for _, part in { "LeftUpperLeg", "RightUpperLeg" } do
			local l = sizeOf(ctx.Character, part)
			attach(ctx, part, "Rip", Vector3.new(l.X * 0.4, l.Y * 0.06, 0.03), CFrame.new(0, -l.Y * 0.1, -l.Z / 2 - 0.015), shade(bottom.Color, 0.45), FABRIC, { Shadow = false })
		end
	end
	if bottom.Pattern then
		local colors = bottom.Pattern.Colors or { bottom.Color }
		for _, part in { "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg" } do
			local l = sizeOf(ctx.Character, part)
			for _ = 1, 4 do
				local z = if rng:NextNumber() < 0.5 then -l.Z / 2 - 0.02 else l.Z / 2 + 0.02
				attach(ctx, part, "Print", Vector3.new(l.X * 0.32, l.Y * 0.18, 0.03), CFrame.new((rng:NextNumber() - 0.5) * l.X * 0.5, (rng:NextNumber() - 0.5) * l.Y * 0.7, z) * CFrame.Angles(0, 0, rng:NextNumber() * math.pi), colors[rng:NextInteger(2, math.max(2, #colors))] or colors[1], FABRIC, { Shadow = false })
			end
		end
	end
	-- Estampados de texto: pecho, dorsal y espalda
	if top.Print and not top.Open then
		local big = top.Number ~= nil
		local p = attach(ctx, "UpperTorso", "ChestPrint", Vector3.new(t.X * (if big then 0.7 else 0.36), t.Y * (if big then 0.16 else 0.2), 0.03), CFrame.new(if big then 0 else -t.X * 0.02, t.Y * (if big then 0.3 else 0.18), front - 0.01), top.Color, FABRIC, { Transparency = 1, Shadow = false })
		print3d(p, Enum.NormalId.Front, top.Print.Text, top.Print.Color)
	elseif top.Print and top.Open then
		local p = attach(ctx, "UpperTorso", "ChestPrint", Vector3.new(t.X * 0.2, t.Y * 0.12, 0.03), CFrame.new(-t.X * 0.34, t.Y * 0.26, front - 0.02), top.Color, FABRIC, { Transparency = 1, Shadow = false })
		print3d(p, Enum.NormalId.Front, top.Print.Text, top.Print.Color)
	end
	if top.Number then
		local p = attach(ctx, "UpperTorso", "Number", Vector3.new(t.X * 0.5, t.Y * 0.42, 0.03), CFrame.new(0, -t.Y * 0.06, front - 0.01), top.Color, FABRIC, { Transparency = 1, Shadow = false })
		print3d(p, Enum.NormalId.Front, top.Number, top.Print and top.Print.Color or Color3.new(1, 1, 1))
	end
	if top.Back then
		local p = attach(ctx, "UpperTorso", "BackPrint", Vector3.new(t.X * 0.8, t.Y * (if #top.Back.Text <= 3 then 0.45 else 0.22), 0.03), CFrame.new(0, t.Y * 0.08, back + 0.01), top.Color, FABRIC, { Transparency = 1, Shadow = false })
		print3d(p, Enum.NormalId.Back, top.Back.Text, top.Back.Color)
	end
end

-- Lo 3D de la ropa que sale en los dos modos (silueta, brillos, cuellos, capuchas…)
local function shapeDetails(ctx, def)
	local top, bottom = def.Top, def.Bottom
	local t = sizeOf(ctx.Character, "UpperTorso")
	local front = -t.Z / 2 - 0.03
	-- Capucha caída en la espalda
	if top.Hood then
		attach(ctx, "UpperTorso", "HoodLining", Vector3.new(t.X * 0.72, t.Y * 0.3, t.Z * 0.55), CFrame.new(0, t.Y * 0.52, t.Z * 0.2), top.Trim or shade(top.Color, 0.2), FABRIC)
		attach(ctx, "UpperTorso", "Hood", Vector3.new(t.X * 0.78, t.Y * 0.42, t.Z * 0.3), CFrame.new(0, t.Y * 0.42, t.Z * 0.55), top.Color, FABRIC)
	end
	-- Cuellos
	if top.Collar == "Shirt" then
		for _, sx in { -1, 1 } do
			attach(ctx, "UpperTorso", "Collar", Vector3.new(t.X * 0.18, t.Y * 0.14, 0.06), CFrame.new(sx * t.X * 0.11, t.Y * 0.44, front) * CFrame.Angles(0, 0, sx * math.rad(-30)), if top.Inner and (top.Kind == "Tuxedo" or top.Kind == "Coat") then top.Inner else shade(top.Color, 0.06), FABRIC)
		end
	elseif top.Collar == "High" then
		attach(ctx, "UpperTorso", "HighCollar", Vector3.new(t.X * 0.5, t.Y * 0.13, t.Z * 0.92), CFrame.new(0, t.Y * 0.52, 0), top.Trim or top.Color, FABRIC, CYL)
	end
	-- Bandas reflectantes y líneas de neón (brillan: en los dos modos)
	if top.Bands then
		for _, y in { -0.26, 0.12 } do
			attach(ctx, "UpperTorso", "Band", Vector3.new(t.X * 1.04, t.Y * 0.08, t.Z * 1.07), CFrame.new(0, t.Y * y, 0), top.Bands, NEON, { Transparency = 0.15, Shadow = false })
		end
		eachSide(function(side, _)
			local a = sizeOf(ctx.Character, side .. "LowerArm")
			attach(ctx, side .. "LowerArm", "Band", Vector3.new(a.X * 1.08, a.Y * 0.1, a.Z * 1.08), CFrame.new(0, -a.Y * 0.1, 0), top.Bands, NEON, { Transparency = 0.15, Shadow = false })
		end)
	end
	if bottom.Bands then
		eachSide(function(side, _)
			local l = sizeOf(ctx.Character, side .. "LowerLeg")
			for _, y in { -0.1, 0.12 } do
				attach(ctx, side .. "LowerLeg", "Band", Vector3.new(l.X * 1.24, l.Y * 0.07, l.Z * 1.24), CFrame.new(0, l.Y * y, 0), bottom.Bands, NEON, { Transparency = 0.15, Shadow = false })
			end
		end)
	end
	if top.Neon then
		for _, sx in { -1, 1 } do
			attach(ctx, "UpperTorso", "NeonLine", Vector3.new(0.05, t.Y * 0.9, 0.05), CFrame.new(sx * t.X * 0.24, 0, front - 0.02), top.Neon, NEON, { Shadow = false })
		end
		eachSide(function(side, sx)
			local a = sizeOf(ctx.Character, side .. "UpperArm")
			attach(ctx, side .. "UpperArm", "NeonLine", Vector3.new(0.05, a.Y * 0.9, 0.05), CFrame.new(sx * (a.X / 2 + 0.03), 0, 0), top.Neon, NEON, { Shadow = false })
		end)
	end
	if bottom.Neon then
		eachSide(function(side, sx)
			local l = sizeOf(ctx.Character, side .. "UpperLeg")
			attach(ctx, side .. "UpperLeg", "NeonLine", Vector3.new(0.05, l.Y * 0.8, 0.05), CFrame.new(sx * (l.X / 2 + 0.03), 0, 0), bottom.Neon, NEON, { Shadow = false })
		end)
	end
	-- Correas (techwear)
	if top.Straps then
		attach(ctx, "UpperTorso", "Strap", Vector3.new(0.09, t.Y * 1.25, 0.05), CFrame.new(0, 0, front - 0.02) * CFrame.Angles(0, 0, math.rad(34)), top.Straps, FABRIC)
	end
	if bottom.Straps then
		eachSide(function(side, _)
			local l = sizeOf(ctx.Character, side .. "UpperLeg")
			attach(ctx, side .. "UpperLeg", "LegStrap", Vector3.new(l.X * 1.08, l.Y * 0.07, l.Z * 1.08), CFrame.new(0, -l.Y * 0.18, 0), bottom.Straps, FABRIC)
		end)
	end
	if bottom.Belt then
		A.Belt(ctx, { Color = bottom.Belt, Buckle = Color3.fromRGB(210, 190, 120) })
	end
	-- Perneras anchas y de campana
	if bottom.Length == "Long" and bottom.Kind ~= "Gown" then
		eachSide(function(side, _)
			local l = sizeOf(ctx.Character, side .. "LowerLeg")
			if bottom.Kind == "Flare" then
				attach(ctx, side .. "LowerLeg", "BellBottom", Vector3.new(l.X * 1.42, l.Y * 0.5, l.Z * 1.42), CFrame.new(0, -l.Y * 0.28, 0), bottom.Color, FABRIC, CYL)
			elseif bottom.Wide then
				attach(ctx, side .. "LowerLeg", "BaggyLeg", Vector3.new(l.X * 1.2, l.Y * 0.95, l.Z * 1.2), CFrame.new(0, -l.Y * 0.04, 0), if bottom.Pattern then shade(bottom.Color, -0.04) else bottom.Color, FABRIC)
			end
		end)
	end
	-- Guantes
	if def.Gloves then
		A.Gloves(ctx, { Color = def.Gloves })
	end
end

-- Zapatos de esta etapa (niños: sin tacones)
local function shoeKind(def, kid: boolean): string
	local kind = def.Shoes.Kind
	if kid and kind == "Heel" then
		return "Flat"
	elseif kid and kind == "Platform" then
		return "Boot"
	end
	return kind
end

local HEADWEAR = { Cap = true, CowboyHat = true, SunHat = true, FireHelmet = true }

---------------------------------------------------------------------
-- Vestir
---------------------------------------------------------------------
function OutfitBuilder.dress(character: Model, def: { [string]: any }, opts: { [string]: any }?): Folder
	local o = opts or {}
	local folder = o.Folder
	if not folder then
		local old = character:FindFirstChild("ValmarLook")
		if old then
			old:Destroy()
		end
		folder = Instance.new("Folder")
		folder.Name = "ValmarLook"
	end
	local shirtId, pantsId = OutfitBuilder.idsFor(def.Key)
	if o.Ids then
		shirtId, pantsId = o.Ids.Shirt, o.Ids.Pants
	end
	local ctx = {
		Character = character,
		Folder = folder,
		Def = def,
		Kid = o.Stage == "Nino",
		Old = o.Stage == "Mayor",
		R6 = OutfitBuilder.isR6(character),
		Skin = o.Skin or Color3.fromRGB(234, 190, 150),
		Textured = shirtId ~= nil and pantsId ~= nil,
	}
	folder:SetAttribute("Outfit", def.Key)
	folder:SetAttribute("Textured", ctx.Textured)

	-- Ropa clásica (o quitarla)
	OutfitBuilder.clearClothes(character, true)
	if ctx.Textured then
		local shirt = Instance.new("Shirt")
		shirt.Name = "ValmarShirt"
		shirt.ShirtTemplate = shirtId :: string
		shirt.Parent = character
		local pants = Instance.new("Pants")
		pants.Name = "ValmarPants"
		pants.PantsTemplate = pantsId :: string
		pants.Parent = character
	end

	paintBody(ctx, def)
	if not ctx.Textured then
		fallbackDetails(ctx, def)
	end
	shapeDetails(ctx, def)

	-- Pelo: el del conjunto o el de siempre (recogido si lleva sombrero o gorra)
	local hasHat = false
	for _, a in def.Accessories or {} do
		hasHat = hasHat or HEADWEAR[a.Kind] == true
	end
	local hairStyle = if def.Hair then def.Hair.Style else (if hasHat then "Short" else "Messy")
	local hairColor = (def.Hair and def.Hair.Color) or o.HairColor or Color3.fromRGB(74, 46, 30)
	OutfitBuilder.hair(folder, character, hairStyle, hairColor, Random.new(o.Seed or 1), false)

	-- Zapatos
	local kind = shoeKind(def, ctx.Kid)
	local build = SHOES[kind] or SHOES.Sneaker
	eachSide(function(side, sx)
		local f = sizeOf(character, side .. "Foot")
		local l = sizeOf(character, side .. "LowerLeg")
		build(ctx, side, sx, def.Shoes, f, l)
	end)

	-- Accesorios
	for _, a in def.Accessories or {} do
		local fn = A[a.Kind]
		if fn then
			local ok, err = pcall(fn, ctx, a)
			if not ok then
				warn("[OutfitBuilder] " .. tostring(def.Key) .. " " .. tostring(a.Kind) .. ": " .. tostring(err))
			end
		end
	end
	folder.Parent = character
	return folder
end

return OutfitBuilder
