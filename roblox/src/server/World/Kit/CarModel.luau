-- CarModel: coches con todo detalle (los aparcados, los del tráfico y el tuyo).
--
--   Tres carrocerías: "Berlina", "Compacto" y "Todoterreno" (misma planta, distinta silueta).
--   Frontal y trasera redondeados, parabrisas y luneta inclinados, ventanillas con marcos y
--   montantes, techo, retrovisores, manillas, líneas de puertas, faros y pilotos LED,
--   intermitentes, rejilla, parachoques, matrículas, ruedas con llanta y paso de rueda,
--   taloneras y escape. Con Interior = true (tu coche): asientos, volante, salpicadero y
--   matrícula con texto.
--
-- Convención (la de todos los vehículos): cf = centro del coche a ras de suelo; el morro mira a -Z.
-- La pieza "Body" (6.2 × 2.2 × 13.5 a 2.2 de altura) y "Headlight" no cambian de sitio:
-- las usan VehicleService (coches aparcados que se conducen) y el tráfico del cliente.

local Builder = require(script.Parent.Parent.Builder)

local CarModel = {}

local rgb = Color3.fromRGB
local BLACK = rgb(24, 24, 27)
local TRIM = rgb(40, 41, 45)
local CHROME = rgb(205, 208, 214)
local GLASS = rgb(34, 46, 58)

CarModel.Variants = { "Berlina", "Compacto", "Todoterreno" }

-- Silueta de cada carrocería: dónde empieza el parabrisas, dónde acaba el techo, alturas…
local SHAPES = {
	Berlina = { WindshieldZ = -3.1, RoofZ0 = -0.9, RoofZ1 = 2.5, RearZ = 4.7, RoofY = 5.3, Belt = 3.3 },
	Compacto = { WindshieldZ = -3.3, RoofZ0 = -1.1, RoofZ1 = 4.6, RearZ = 5.4, RoofY = 5.4, Belt = 3.3 },
	Todoterreno = { WindshieldZ = -3.6, RoofZ0 = -2.0, RoofZ1 = 5.2, RearZ = 5.7, RoofY = 6.1, Belt = 3.5 },
}

-- Lite = true: versión ligera para los cientos de coches aparcados (misma silueta y luces, sin
-- los detalles pequeños). Al conducir uno, CarModel.upgrade lo cambia por la versión completa.
export type Options = { Name: string?, Variant: string?, Interior: boolean?, Plate: string?, Lite: boolean? }

function CarModel.build(parent: Instance?, cf: CFrame, paint: Color3, options: Options?): Model
	local opts = options or {}
	local full = not opts.Lite
	local variant = opts.Variant or CarModel.Variants[math.random(1, #CarModel.Variants)]
	local shape = SHAPES[variant] or SHAPES.Berlina
	local m = Instance.new("Model")
	m.Name = opts.Name or "ParkedCar"
	m:SetAttribute("Variant", variant)
	m:SetAttribute("Paint", paint)
	m:SetAttribute("Lite", opts.Lite == true)

	local W, L = 6.2, 13.5
	local HW, HL = W / 2, L / 2
	local r = 1.3 -- radio de las ruedas

	local function at(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x, y, z)
	end
	local function solid(name: string, size: Vector3, c: CFrame, color: Color3, material: Enum.Material?, transparency: number?): BasePart
		return Builder.part({ Name = name, Size = size, CFrame = c, Color = color, Material = material or Enum.Material.SmoothPlastic, Transparency = transparency or 0, Parent = m })
	end
	local function detail(name: string, size: Vector3, c: CFrame, color: Color3, material: Enum.Material?, transparency: number?): BasePart
		return Builder.decor({ Name = name, Size = size, CFrame = c, Color = color, Material = material or Enum.Material.SmoothPlastic, Transparency = transparency or 0, Parent = m })
	end
	local function cylinder(name: string, length: number, diameter: number, c: CFrame, color: Color3, material: Enum.Material?, isSolid: boolean?): BasePart
		local props = { Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(length, diameter, diameter), CFrame = c, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = m }
		return if isSolid then Builder.part(props) else Builder.decor(props)
	end
	local ALONG_X = CFrame.new() -- (los cilindros van a lo largo de X por defecto)

	---------------------------------------------------------------------
	-- Carrocería
	---------------------------------------------------------------------
	local body = solid("Body", Vector3.new(W, 2.2, L - 1.2), at(0, r + 0.9, 0), paint)
	body.Reflectance = 0.08
	-- Morro y cola redondeados (un cilindro de lado a lado en cada punta)
	for _, sz in { -1, 1 } do
		local nose = cylinder("Nose", W, 2.2, at(0, r + 0.9, sz * (HL - 1.1)) * ALONG_X, paint, Enum.Material.SmoothPlastic, true)
		nose.Reflectance = 0.08
	end
	-- Capó un poco más bajo que la cintura: franja oscura de separación
	if full then
		detail("HoodLine", Vector3.new(W - 0.6, 0.05, 0.08), at(0, shape.Belt + 0.01, shape.WindshieldZ - 2.8), TRIM)
	-- Taloneras, parachoques y rejilla
		for _, sx in { -1, 1 } do
			detail("SideSkirt", Vector3.new(0.12, 0.35, L - 6.4), at(sx * (HW + 0.02), r - 0.05, 0), BLACK, Enum.Material.Plastic)
		end
	end
	solid("BumperFront", Vector3.new(W + 0.1, 0.7, 0.6), at(0, 1.35, -HL + 0.2), BLACK, Enum.Material.Plastic)
	solid("BumperRear", Vector3.new(W + 0.1, 0.7, 0.6), at(0, 1.35, HL - 0.2), BLACK, Enum.Material.Plastic)
	detail("Grille", Vector3.new(2.8, 0.55, 0.1), at(0, 2.45, -HL - 0.05), BLACK)
	for i = 0, if full then 2 else -1 do
		detail("GrilleBar", Vector3.new(2.6, 0.06, 0.12), at(0, 2.3 + i * 0.16, -HL - 0.07), CHROME, Enum.Material.Metal)
	end
	if full then
		detail("Badge", Vector3.new(0.5, 0.35, 0.06), at(0, 2.45, -HL - 0.12), CHROME, Enum.Material.Metal)
		cylinder("Exhaust", 0.6, 0.35, at(-1.8, 1.0, HL + 0.1) * CFrame.Angles(0, math.rad(90), 0), CHROME, Enum.Material.Metal)
	end
	detail("PlateFront", Vector3.new(1.7, 0.42, 0.06), at(0, 1.4, -HL - 0.12), rgb(240, 240, 240))
	local rearPlate = detail("PlateRear", Vector3.new(1.7, 0.42, 0.06), at(0, 2.2, HL + 0.02), rgb(240, 240, 240))
	if opts.Plate then
		Builder.sign(rearPlate, opts.Plate, Enum.NormalId.Back, rgb(20, 20, 24), rgb(240, 240, 240))
	end

	---------------------------------------------------------------------
	-- Luces
	---------------------------------------------------------------------
	for _, sx in { -1, 1 } do
		local x = sx * (HW - 1)
		local head = detail("Headlight", Vector3.new(1.3, 0.45, 0.3), at(x, 2.75, -HL + 0.2), rgb(255, 250, 235), Enum.Material.Neon)
		head.Name = if sx < 0 then "Headlight" else "HeadlightRight"
		detail("Taillight", Vector3.new(1.4, 0.45, 0.3), at(x, 2.8, HL - 0.2), rgb(200, 20, 30), Enum.Material.Neon)
		if full then
			detail("DRL", Vector3.new(1.3, 0.08, 0.1), at(x, 2.45, -HL - 0.04), rgb(225, 240, 255), Enum.Material.Neon)
			detail("IndicatorFront", Vector3.new(0.35, 0.3, 0.12), at(sx * (HW - 0.15), 2.75, -HL + 0.1), rgb(255, 150, 20), Enum.Material.Neon)
			detail("IndicatorRear", Vector3.new(0.35, 0.3, 0.12), at(sx * (HW - 0.15), 2.8, HL - 0.1), rgb(255, 150, 20), Enum.Material.Neon)
			detail("Reflector", Vector3.new(0.5, 0.15, 0.08), at(x, 1.55, HL + 0.12), rgb(170, 20, 25), Enum.Material.Neon)
		end
	end
	if full then
		detail("ThirdBrake", Vector3.new(1.2, 0.12, 0.1), at(0, shape.RoofY - 0.12, shape.RoofZ1 + 0.15), rgb(200, 20, 30), Enum.Material.Neon)
	end

	---------------------------------------------------------------------
	-- Habitáculo: parabrisas, luneta, techo, ventanillas y montantes
	---------------------------------------------------------------------
	local belt, roofY = shape.Belt, shape.RoofY
	local cabinW = W - 0.8
	-- Parabrisas inclinado (de la base del capó al borde del techo)
	local rise, run = roofY - belt, shape.RoofZ0 - shape.WindshieldZ
	local windAngle = math.atan2(rise, run)
	local windLen = math.sqrt(rise * rise + run * run)
	solid("Windshield", Vector3.new(cabinW, 0.15, windLen), at(0, (belt + roofY) / 2, (shape.WindshieldZ + shape.RoofZ0) / 2) * CFrame.Angles(-windAngle, 0, 0), GLASS, Enum.Material.Glass, 0.35)
	-- Luneta (del techo a la cola)
	local rearRun = shape.RearZ - shape.RoofZ1
	local rearAngle = math.atan2(rise, rearRun)
	local rearLen = math.sqrt(rise * rise + rearRun * rearRun)
	solid("RearWindow", Vector3.new(cabinW, 0.15, rearLen), at(0, (belt + roofY) / 2, (shape.RoofZ1 + shape.RearZ) / 2) * CFrame.Angles(rearAngle, 0, 0), GLASS, Enum.Material.Glass, 0.35)
	-- Techo
	local roof = solid("Roof", Vector3.new(cabinW, 0.25, shape.RoofZ1 - shape.RoofZ0), at(0, roofY, (shape.RoofZ0 + shape.RoofZ1) / 2), paint)
	roof.Reflectance = 0.08
	if variant == "Todoterreno" then
		for _, sx in { -1, 1 } do
			detail("RoofRail", Vector3.new(0.18, 0.2, shape.RoofZ1 - shape.RoofZ0 - 0.6), at(sx * (cabinW / 2 - 0.3), roofY + 0.22, (shape.RoofZ0 + shape.RoofZ1) / 2), BLACK, Enum.Material.Metal)
		end
	end
	-- Ventanillas: rectángulo central y triángulos delante y detrás (siguen la inclinación)
	for _, sx in { -1, 1 } do
		local x = sx * (cabinW / 2)
		local h = roofY - belt - 0.15
		solid("SideWindow", Vector3.new(0.12, h, shape.RoofZ1 - shape.RoofZ0), at(x, belt + h / 2, (shape.RoofZ0 + shape.RoofZ1) / 2), GLASS, Enum.Material.Glass, 0.35)
		-- triángulo delantero (alto por detrás, como el parabrisas)
		Builder.part({
			ClassName = "WedgePart",
			Name = "SideWindowFront",
			Size = Vector3.new(0.12, h, run),
			CFrame = at(x, belt + h / 2, (shape.WindshieldZ + shape.RoofZ0) / 2),
			Color = GLASS,
			Material = Enum.Material.Glass,
			Transparency = 0.35,
			Parent = m,
		})
		Builder.part({
			ClassName = "WedgePart",
			Name = "SideWindowRear",
			Size = Vector3.new(0.12, h, rearRun),
			CFrame = at(x, belt + h / 2, (shape.RoofZ1 + shape.RearZ) / 2) * CFrame.Angles(0, math.pi, 0),
			Color = GLASS,
			Material = Enum.Material.Glass,
			Transparency = 0.35,
			Parent = m,
		})
		if not full then
			continue -- (versión ligera: sin montantes, retrovisores ni manillas)
		end
		-- Montantes: A (junto al parabrisas), B (centro) y C (junto a la luneta)
		detail("PillarA", Vector3.new(0.2, 0.22, windLen), at(x, (belt + roofY) / 2, (shape.WindshieldZ + shape.RoofZ0) / 2) * CFrame.Angles(-windAngle, 0, 0), BLACK)
		detail("PillarB", Vector3.new(0.18, h, 0.35), at(x + sx * 0.02, belt + h / 2, (shape.RoofZ0 + shape.RoofZ1) / 2 - 0.2), BLACK)
		detail("PillarC", Vector3.new(0.2, 0.3, rearLen), at(x, (belt + roofY) / 2, (shape.RoofZ1 + shape.RearZ) / 2) * CFrame.Angles(rearAngle, 0, 0), paint)
		detail("WindowTrim", Vector3.new(0.14, 0.08, shape.RoofZ1 - shape.RoofZ0), at(x, belt + 0.04, (shape.RoofZ0 + shape.RoofZ1) / 2), CHROME, Enum.Material.Metal)
		-- Retrovisor
		detail("MirrorArm", Vector3.new(0.4, 0.12, 0.2), at(sx * (HW + 0.1), belt + 0.35, shape.WindshieldZ + 0.5), BLACK)
		detail("Mirror", Vector3.new(0.35, 0.45, 0.65), at(sx * (HW + 0.35), belt + 0.45, shape.WindshieldZ + 0.55), paint)
		detail("MirrorGlass", Vector3.new(0.3, 0.38, 0.05), at(sx * (HW + 0.35), belt + 0.45, shape.WindshieldZ + 0.89), rgb(170, 190, 200), Enum.Material.Glass)
		-- Puertas: juntas y manillas
		for _, z in { shape.WindshieldZ + 0.6, (shape.RoofZ0 + shape.RoofZ1) / 2 - 0.2, shape.RoofZ1 + 0.4 } do
			detail("DoorLine", Vector3.new(0.05, 2, 0.06), at(sx * (HW + 0.01), r + 1, z), TRIM)
		end
		for _, z in { (shape.RoofZ0 + shape.RoofZ1) / 2 - 1.2, shape.RoofZ1 - 0.4 } do
			detail("Handle", Vector3.new(0.08, 0.14, 0.6), at(sx * (HW + 0.04), belt - 0.3, z), CHROME, Enum.Material.Metal)
		end
	end

	---------------------------------------------------------------------
	-- Ruedas: neumático, llanta, buje y paso de rueda oscuro
	---------------------------------------------------------------------
	for _, z in { -4.3, 4.3 } do
		for _, sx in { -1, 1 } do
			local x = sx * (HW - 0.3)
			if full then
				cylinder("WheelWell", 0.04, 3.2, at(sx * (HW + 0.01), r + 0.1, z), rgb(14, 14, 16))
				cylinder("Hub", 1.18, r * 0.45, at(sx * (HW - 0.3), r, z), rgb(80, 82, 88), Enum.Material.Metal)
			end
			cylinder("Wheel", 1.1, r * 2, at(x, r, z), rgb(26, 26, 28), Enum.Material.Rubber)
			cylinder("Rim", 1.14, r * 1.3, at(x, r, z), CHROME, Enum.Material.Metal)
			if opts.Interior then
				for k = 0, 4 do
					local a = k * math.pi * 2 / 5
					detail("Spoke", Vector3.new(1.16, 0.12, 0.7), at(x, r + math.cos(a) * 0.5, z + math.sin(a) * 0.5) * CFrame.Angles(a, 0, 0), rgb(150, 154, 160), Enum.Material.Metal)
				end
			end
		end
	end

	---------------------------------------------------------------------
	-- Interior (tu coche: se ve por las ventanillas)
	---------------------------------------------------------------------
	if opts.Interior then
		local seat = rgb(45, 45, 50)
		detail("Dashboard", Vector3.new(cabinW - 0.2, 0.7, 1.2), at(0, belt + 0.1, shape.WindshieldZ + 1.4), rgb(35, 35, 38))
		detail("DashScreen", Vector3.new(1, 0.5, 0.05), at(0, belt + 0.45, shape.WindshieldZ + 2), rgb(60, 170, 255), Enum.Material.Neon)
		detail("Steering", Vector3.new(1.3, 1.3, 0.15), at(-1.4, belt + 0.55, shape.WindshieldZ + 2.1) * CFrame.Angles(math.rad(-25), 0, 0), BLACK)
		for _, sx in { -1, 1 } do
			detail("FrontSeat", Vector3.new(1.8, 0.4, 1.8), at(sx * 1.4, belt - 0.4, (shape.RoofZ0 + shape.RoofZ1) / 2 - 1.3), seat, Enum.Material.Fabric)
			detail("FrontSeatBack", Vector3.new(1.8, 2, 0.35), at(sx * 1.4, belt + 0.6, (shape.RoofZ0 + shape.RoofZ1) / 2 - 0.35) * CFrame.Angles(math.rad(10), 0, 0), seat, Enum.Material.Fabric)
			detail("Headrest", Vector3.new(1, 0.5, 0.3), at(sx * 1.4, belt + 1.85, (shape.RoofZ0 + shape.RoofZ1) / 2 - 0.25), seat, Enum.Material.Fabric)
		end
		detail("RearBench", Vector3.new(cabinW - 0.4, 0.4, 1.6), at(0, belt - 0.4, shape.RoofZ1 - 0.6), seat, Enum.Material.Fabric)
		detail("RearBenchBack", Vector3.new(cabinW - 0.4, 1.8, 0.35), at(0, belt + 0.5, shape.RoofZ1 + 0.3) * CFrame.Angles(math.rad(12), 0, 0), seat, Enum.Material.Fabric)
	end

	m.Parent = parent
	return m
end

-- Cambia un coche ligero (aparcado) por la versión completa con interior, en el mismo sitio.
-- groundCf = centro del coche a ras de suelo. Devuelve true si lo ha cambiado.
function CarModel.upgrade(model: Model, groundCf: CFrame): boolean
	if model:GetAttribute("Lite") ~= true then
		return false
	end
	local paint = model:GetAttribute("Paint")
	local full = CarModel.build(nil, groundCf, if typeof(paint) == "Color3" then paint else Color3.fromRGB(200, 200, 205), {
		Variant = model:GetAttribute("Variant"),
		Interior = true,
		Plate = ("%04d VLM"):format(math.random(0, 9999)),
	})
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") then
			child:Destroy()
		end
	end
	for _, child in full:GetChildren() do
		child.Parent = model
	end
	full:Destroy()
	model:SetAttribute("Lite", false)
	return true
end

return CarModel
