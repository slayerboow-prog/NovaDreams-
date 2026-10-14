-- Ambient (servidor): publica en ReplicatedStorage lo que el cliente necesita para
-- simular tráfico y peatones por su cuenta (sin coste para el servidor):
--   ReplicatedStorage.Ambient.Roads -> una Configuration por tramo de calle:
--       A, B (Vector3: principio y fin, en cualquier ángulo) y Width (ancho de la calzada).
--       Las calles rectas de los barrios llevan además Axis, At, From, To.
--       WalkIn/WalkOut: la acera va de WalkIn a WalkOut del centro de la calle; Obstacles: lo que
--       estorba en las dos aceras (farolas, papeleras, quioscos…: shared/Sidewalk) para que los
--       peatones lo esquiven en vez de atravesarlo.
--   ReplicatedStorage.Ambient.Cars  -> modelos de coche (y taxis) en el origen, mirando a -Z
--   ReplicatedStorage.Ambient.Riders -> motos, bicis y patinetes con su conductor montado
--       (atributo Kind; las piezas del conductor llevan Tint = Skin/Shirt/Pants/Helmet para que
--       el cliente cambie los colores de cada copia, y las piernas de la bici "PedalLeg" pedalean)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sidewalk = require(ReplicatedStorage.Shared.Sidewalk)

local Palette = require(script.Parent.Kit.Palette)
local CarModel = require(script.Parent.Kit.CarModel)
local Rides = require(script.Parent.Kit.Rides)

local Ambient = {}

local CAR_VARIANTS = 8
local taxi, rider

---------------------------------------------------------------------
-- Estorbos de las aceras (una vez al arrancar, con el mapa entero)
---------------------------------------------------------------------
local WALK_TOP = 1.0

function Ambient.obstacles(a: Vector3, b: Vector3, walkIn: number, walkOut: number): string
	local len = (b - a).Magnitude
	if len < 1 or walkOut <= walkIn then
		return ""
	end
	local dir = (b - a).Unit
	local frame = { A = Vector3.new(a.X, 0, a.Z), Dir = dir, Perp = Vector3.new(-dir.Z, 0, dir.X) }
	local rot = CFrame.lookAt(Vector3.zero, dir)
	local list = {}
	for _, side in { -1, 1 } do
		local center = frame.A + dir * (len / 2) + frame.Perp * (side * (walkIn + walkOut) / 2) + Vector3.new(0, WALK_TOP + 3, 0)
		local ok, parts = pcall(function()
			return workspace:GetPartBoundsInBox(CFrame.new(center) * rot, Vector3.new(walkOut - walkIn, 4.6, len + 4), OverlapParams.new())
		end)
		for _, part in if ok and parts then parts else {} do
			-- Solo lo que se ve y es sólido (la caja empieza medio stud por encima de la acera: ni el
			-- suelo ni los bordillos cuentan)
			if part.CanCollide and part.Transparency < 0.95 then
				local u0, u1, v0, v1 = Sidewalk.project(frame, part.CFrame, part.Size)
				table.insert(list, { U0 = u0, U1 = u1, V0 = v0, V1 = v1 })
			end
		end
	end
	return Sidewalk.encode(list)
end

---------------------------------------------------------------------
-- Taxis: berlina blanca con el cartel "TAXI" y la luz verde de libre en el techo
---------------------------------------------------------------------
function taxi(parent: Instance, name: string)
	local car = CarModel.build(parent, CFrame.new(), Color3.fromRGB(245, 245, 242), { Name = name, Variant = "Berlina" })
	local sign = Instance.new("Part")
	sign.Name = "TaxiSign"
	sign.Size = Vector3.new(2.6, 0.7, 0.9)
	sign.CFrame = CFrame.new(0, 5.65, 0.6)
	sign.Color = Color3.fromRGB(250, 250, 250)
	sign.Material = Enum.Material.SmoothPlastic
	sign.Anchored = true
	sign.CanCollide = false
	sign.Parent = car
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.CanvasSize = Vector2.new(260, 70)
		gui.LightInfluence = 0
		gui.Parent = sign
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = "TAXI"
		label.TextScaled = true
		label.Font = Enum.Font.GothamBlack
		label.TextColor3 = Color3.fromRGB(20, 20, 24)
		label.Parent = gui
	end
	local lamp = Instance.new("Part")
	lamp.Name = "TaxiLight"
	lamp.Size = Vector3.new(0.5, 0.35, 0.5)
	lamp.CFrame = CFrame.new(0.9, 6.15, 0.6)
	lamp.Color = Color3.fromRGB(60, 255, 120)
	lamp.Material = Enum.Material.Neon
	lamp.Anchored = true
	lamp.CanCollide = false
	lamp.Parent = car
	-- Franja roja en las puertas
	for _, sx in { -1, 1 } do
		local band = Instance.new("Part")
		band.Name = "TaxiBand"
		band.Size = Vector3.new(0.05, 0.35, 6)
		band.CFrame = CFrame.new(sx * 3.13, 3, 0)
		band.Color = Color3.fromRGB(200, 40, 40)
		band.Material = Enum.Material.SmoothPlastic
		band.Anchored = true
		band.CanCollide = false
		band.Parent = car
	end
	return car
end

---------------------------------------------------------------------
-- Conductor montado en moto, bici o patinete (postura según el vehículo)
---------------------------------------------------------------------
local POSES = {
	-- Hip/Shoulder/Head en el centro; piernas (Knee opcional) y manos a los puños del manillar
	Moto = { Hip = Vector3.new(0, 2.95, 0.7), Shoulder = Vector3.new(0, 5.0, 0.35), Head = Vector3.new(0, 5.9, 0.2), Knee = Vector3.new(0.5, 3.0, -0.7), Foot = Vector3.new(0.5, 1.25, -0.9), Grip = Vector3.new(0.95, 3.85, -1.98), Helmet = 1 },
	Bici = { Hip = Vector3.new(0, 3.55, 0.85), Shoulder = Vector3.new(0, 5.15, -0.45), Head = Vector3.new(0, 5.95, -0.95), Foot = Vector3.new(0.45, 1.2, 0.05), Grip = Vector3.new(0.85, 3.3, -1.55), Helmet = 0.7, Pedal = true },
	Patinete = { Hip = Vector3.new(0, 3.2, 0.35), Shoulder = Vector3.new(0, 5.3, 0.2), Head = Vector3.new(0, 6.2, 0.1), Foot = Vector3.new(0.35, 0.8, 0.3), Grip = Vector3.new(0.85, 4.05, -1.72), Helmet = 0.4, Stagger = true },
}

local function limb(model: Model, name: string, a: Vector3, b: Vector3, width: number, depth: number, tint: string): BasePart
	local dir = b - a
	local up = if math.abs(dir.Unit.Y) > 0.7 then Vector3.new(0, 0, -1) else Vector3.new(0, 1, 0)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(width, depth, dir.Magnitude + 0.2)
	part.CFrame = CFrame.lookAt((a + b) / 2, b, up)
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part:SetAttribute("Tint", tint)
	part.Parent = model
	return part
end

function rider(model: Model, kind: string)
	local pose = POSES[kind]
	if not pose then
		return
	end
	local body = Instance.new("Model")
	body.Name = "Rider"
	body.Parent = model
	limb(body, "Torso", pose.Hip, pose.Shoulder, 2, 1.1, "Shirt")
	for _, sx in { -1, 1 } do
		local hip = pose.Hip + Vector3.new(sx * 0.48, 0, 0)
		local foot = Vector3.new(sx * pose.Foot.X, pose.Foot.Y, pose.Foot.Z + (if pose.Stagger then sx * 0.35 else 0))
		if pose.Knee then
			local knee = Vector3.new(sx * pose.Knee.X, pose.Knee.Y, pose.Knee.Z)
			limb(body, "Thigh", hip, knee, 0.9, 0.95, "Pants")
			limb(body, "Shin", knee, foot, 0.85, 0.9, "Pants")
		else
			local leg = limb(body, if pose.Pedal then "PedalLeg" else "Leg", hip, foot, 0.9, 0.95, "Pants")
			if pose.Pedal then
				leg:SetAttribute("Pivot", hip)
				leg:SetAttribute("Side", sx)
			end
		end
		local shoulder = pose.Shoulder + Vector3.new(sx * 1.3, -0.25, 0)
		limb(body, "Arm", shoulder, Vector3.new(sx * pose.Grip.X, pose.Grip.Y, pose.Grip.Z), 0.7, 0.75, "Shirt")
	end
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.3, 1.3, 1.3)
	head.CFrame = CFrame.new(pose.Head)
	head.Anchored = true
	head.CanCollide = false
	head:SetAttribute("Tint", "Skin")
	head.Parent = body
	if math.random() < pose.Helmet then
		local helmet = Instance.new("Part")
		helmet.Name = "Helmet"
		helmet.Shape = Enum.PartType.Ball
		helmet.Size = Vector3.new(1.55, 1.55, 1.55)
		helmet.CFrame = CFrame.new(pose.Head + Vector3.new(0, 0.2, 0.08))
		helmet.Material = Enum.Material.SmoothPlastic
		helmet.Anchored = true
		helmet.CanCollide = false
		helmet:SetAttribute("Tint", "Helmet")
		helmet.Parent = body
		if kind == "Moto" then
			local visor = Instance.new("Part")
			visor.Name = "Visor"
			visor.Size = Vector3.new(1.1, 0.5, 0.2)
			visor.CFrame = CFrame.new(pose.Head + Vector3.new(0, 0.1, -0.72))
			visor.Color = Color3.fromRGB(30, 34, 40)
			visor.Material = Enum.Material.Glass
			visor.Anchored = true
			visor.CanCollide = false
			visor.Parent = body
		end
	end
end

function Ambient.publish(roads: { { [string]: any } }, segments: { { [string]: any } }?)
	local existing = ReplicatedStorage:FindFirstChild("Ambient")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Ambient"

	local roadFolder = Instance.new("Folder")
	roadFolder.Name = "Roads"
	roadFolder.Parent = folder
	local n = 0
	for _, road in roads do
		n += 1
		local config = Instance.new("Configuration")
		config.Name = "Road" .. n
		config:SetAttribute("Axis", road.Axis)
		config:SetAttribute("At", road.At)
		config:SetAttribute("From", road.From)
		config:SetAttribute("To", road.To)
		local a = if road.Axis == "X" then Vector3.new(road.From, 0, road.At) else Vector3.new(road.At, 0, road.From)
		local b = if road.Axis == "X" then Vector3.new(road.To, 0, road.At) else Vector3.new(road.At, 0, road.To)
		config:SetAttribute("A", a)
		config:SetAttribute("B", b)
		config:SetAttribute("Width", 24)
		config:SetAttribute("WalkIn", 12) -- (Kit/Street: calzada de 24 y acera de 8)
		config:SetAttribute("WalkOut", 20)
		config:SetAttribute("Obstacles", Ambient.obstacles(a, b, 12, 20))
		config.Parent = roadFolder
	end
	-- Carreteras principales del plano (Ronda, avenidas, diagonales)
	for _, segment in segments or {} do
		n += 1
		local config = Instance.new("Configuration")
		config.Name = "Road" .. n
		config:SetAttribute("A", segment.A)
		config:SetAttribute("B", segment.B)
		config:SetAttribute("Width", segment.Width or 24)
		config:SetAttribute("Kind", segment.Kind)
		local walk = segment.Walk
		if type(walk) == "number" and walk > 0 then
			local half = (segment.Width or 24) / 2
			config:SetAttribute("WalkIn", half)
			config:SetAttribute("WalkOut", half + walk)
			config:SetAttribute("Obstacles", Ambient.obstacles(segment.A, segment.B, half, half + walk))
		end
		config.Parent = roadFolder
	end

	local cars = Instance.new("Folder")
	cars.Name = "Cars"
	cars.Parent = folder
	for i = 1, CAR_VARIANTS do
		local color = Palette.CarColors[(i - 1) % #Palette.CarColors + 1]
		local variant = CarModel.Variants[(i - 1) % #CarModel.Variants + 1]
		CarModel.build(cars, CFrame.new(), color, { Name = "Car" .. i, Variant = variant })
	end
	for i = 1, 2 do
		taxi(cars, "Taxi" .. i)
	end

	local riders = Instance.new("Folder")
	riders.Name = "Riders"
	riders.Parent = folder
	for kind, count in { Moto = 3, Bici = 4, Patinete = 3 } do
		for i = 1, count do
			local model = Rides.build(kind, riders, CFrame.new())
			Rides.foldStand(model, CFrame.new()) -- (en marcha: la pata recogida)
			model.Name = kind .. i
			model:SetAttribute("Kind", kind)
			rider(model, kind)
		end
	end

	folder.Parent = ReplicatedStorage

	-- Carrocerías de malla de verdad (Kit/CarBodies): se cargan en un hilo aparte (también cambian
	-- los coches aparcados y el tuyo). Al estar listas, el tráfico tiene otras plantillas en
	-- «CarsMesh» (las mismas de Cars con la malla; el cliente las usa salvo en gráficos Bajo).
	local okBodies, CarBodies = pcall(function()
		return require(script.Parent.Kit.CarBodies)
	end)
	if okBodies and type(CarBodies) == "table" and typeof(task) == "table" then
		CarBodies.onReady(function()
			Ambient.meshCars(folder, CarBodies)
		end)
		task.spawn(function()
			local ok, err = pcall(CarBodies.start)
			if not ok then
				warn("[CarBodies] " .. tostring(err))
			end
		end)
	end
end

-- Plantillas del tráfico con carrocería de malla (ReplicatedStorage.Ambient.CarsMesh)
Ambient.MESH_CARS = 14
function Ambient.meshCars(folder: Instance, CarBodies: any): number
	local cars = folder:FindFirstChild("Cars")
	if not cars or folder:FindFirstChild("CarsMesh") then
		return 0
	end
	local boxes, taxis = {}, {}
	for _, m in cars:GetChildren() do
		if m:IsA("Model") then
			table.insert(if string.sub(m.Name, 1, 4) == "Taxi" then taxis else boxes, m)
		end
	end
	table.sort(boxes, function(a, b)
		return a.Name < b.Name
	end)
	local out = Instance.new("Folder")
	out.Name = "CarsMesh"
	local n = 0
	for i = 1, if #boxes > 0 then Ambient.MESH_CARS else 0 do
		local copy = boxes[(i - 1) % #boxes + 1]:Clone()
		copy.Name = "MeshCar" .. i
		if CarBodies.dress(copy, CFrame.new(), { Role = "Traffic", Key = "trafico" .. i }) then
			copy.Parent = out
			n += 1
		else
			copy:Destroy()
		end
	end
	for i, t in taxis do
		local copy = t:Clone()
		if CarBodies.dress(copy, CFrame.new(), { Role = "Taxi", Key = "taxi" .. i, Variant = "Berlina" }) then
			copy.Parent = out
			n += 1
		else
			copy:Destroy()
		end
	end
	if n > 0 then
		out.Parent = folder
	else
		out:Destroy()
	end
	Ambient.liteCars(folder, CarBodies, boxes)
	Ambient.heavyCars(folder, CarBodies)
	return n
end

-- Plantillas del tráfico para gráficos Bajo (ReplicatedStorage.Ambient.CarsMeshLite): también con
-- malla (nunca las cajas de antes), pero solo con las carrocerías más ligeras (CarBodies.lightest).
Ambient.LITE_CARS = 8
function Ambient.liteCars(folder: Instance, CarBodies: any, boxes: { Model }): number
	if folder:FindFirstChild("CarsMeshLite") or #boxes == 0 or type(CarBodies.lightest) ~= "function" then
		return 0
	end
	local lite = CarBodies.lightest("Traffic")
	if #lite == 0 then
		return 0
	end
	local out = Instance.new("Folder")
	out.Name = "CarsMeshLite"
	local n = 0
	for i = 1, Ambient.LITE_CARS do
		local copy = boxes[(i - 1) % #boxes + 1]:Clone()
		copy.Name = "LiteCar" .. i
		local t = lite[(i - 1) % #lite + 1]
		if CarBodies.dress(copy, CFrame.new(), { Role = "Traffic", Key = "ligero" .. i, Template = t.Name }) then
			copy.Parent = out
			n += 1
		else
			copy:Destroy()
		end
	end
	if n > 0 then
		out.Parent = folder
	else
		out:Destroy()
	end
	return n
end

-- Pesados del tráfico con malla (ReplicatedStorage.Ambient.HeavyMesh): camiones de reparto y
-- autocares (Kit/CarBodies.heavy). El cliente los pone en la calle (tipo «Pesado»), salvo en Bajo.
Ambient.HEAVY = 4
function Ambient.heavyCars(folder: Instance, CarBodies: any): number
	if folder:FindFirstChild("HeavyMesh") or type(CarBodies.heavy) ~= "function" then
		return 0
	end
	local out = Instance.new("Folder")
	out.Name = "HeavyMesh"
	local n = 0
	for i = 1, Ambient.HEAVY do
		local t = CarBodies.choose("Heavy", "pesado" .. i)
		if t then
			local ok, m = pcall(CarBodies.heavy, t, "Pesado" .. i)
			if ok and m then
				m.Parent = out
				n += 1
			end
		end
	end
	if n > 0 then
		out.Parent = folder
	else
		out:Destroy()
	end
	return n
end

return Ambient
