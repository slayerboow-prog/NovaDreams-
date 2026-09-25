-- Props: mobiliario urbano y coches aparcados.
-- Todos reciben un CFrame a nivel del suelo que mira (LookVector) hacia donde "mira" el objeto.

local Builder = require(script.Parent.Parent.Builder)
local Palette = require(script.Parent.Palette)
local AssetLibrary = require(script.Parent.AssetLibrary)
local Place = require(script.Parent.Place)

-- Luz invisible en lo alto de una farola importada (la enciende WorldService de noche)
local function addLampLight(model: Instance)
	local minV, maxV = Place.bounds(model)
	local lens = Builder.decor({
		Name = "Lens",
		Size = Vector3.new(0.4, 0.1, 0.4),
		CFrame = CFrame.new((minV.X + maxV.X) / 2, maxV.Y - 0.8, (minV.Z + maxV.Z) / 2),
		Transparency = 1,
		Tags = { "StreetLamp" },
		Parent = model,
	})
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Bottom
	light.Angle = 110
	light.Range = 40
	light.Brightness = 3
	light.Color = Palette.Street.LampLight
	light.Shadows = false -- sin sombras: cientos de farolas con sombra hunden el rendimiento
	light.Enabled = false
	light.Parent = lens
end

local Props = {}

local lampCount = 0

local S = Palette.Street

-- Farola con brazo. El CFrame mira hacia la calzada (el brazo sale hacia delante).
function Props.lamp(parent: Instance, cf: CFrame)
	local asset = AssetLibrary.spawn("Lamp", parent, cf)
	if asset then
		addLampLight(asset)
		return asset
	end
	local m = Builder.model("StreetLamp", parent)
	Builder.part({ Name = "Base", Size = Vector3.new(1.2, 1, 1.2), CFrame = cf * CFrame.new(0, 0.5, 0), Color = S.Metal, Material = Enum.Material.Metal, Parent = m })
	Builder.part({
		Name = "Pole",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(14, 0.5, 0.5),
		CFrame = cf * CFrame.new(0, 7.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = S.Metal,
		Material = Enum.Material.Metal,
		Parent = m,
	})
	Builder.decor({ Name = "Arm", Size = Vector3.new(0.3, 0.3, 3.4), CFrame = cf * CFrame.new(0, 14.2, -1.5), Color = S.Metal, Material = Enum.Material.Metal, Parent = m })
	Builder.decor({ Name = "Head", Size = Vector3.new(1.4, 0.5, 2.4), CFrame = cf * CFrame.new(0, 14.2, -3.4), Color = S.Metal, Material = Enum.Material.Metal, Parent = m })
	local lens = Builder.decor({
		Name = "Lens",
		Size = Vector3.new(1.1, 0.12, 2),
		CFrame = cf * CFrame.new(0, 13.9, -3.4),
		Color = S.LampLight,
		Material = Enum.Material.SmoothPlastic,
		Tags = { "StreetLamp" },
		Parent = m,
	})
	-- Solo 1 de cada 2 farolas lleva luz real (las demás brillan): la mitad de coste de iluminación
	lampCount += 1
	if lampCount % 2 == 0 then
		local light = Instance.new("SpotLight")
		light.Face = Enum.NormalId.Bottom
		light.Angle = 120
		light.Range = 46
		light.Brightness = 3
		light.Color = S.LampLight
		light.Shadows = false -- sin sombras: cientos de farolas con sombra hunden el rendimiento
		light.Enabled = false
		light.Parent = lens
	end
	return m
end

-- Semáforo: poste en la esquina con brazo sobre la calzada (hacia delante)
function Props.trafficLight(parent: Instance, cf: CFrame, armLength: number)
	local asset = AssetLibrary.spawn("TrafficLight", parent, cf)
	if asset then
		return asset
	end
	local m = Builder.model("TrafficLight", parent)
	Builder.part({
		Name = "Pole",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(15, 0.6, 0.6),
		CFrame = cf * CFrame.new(0, 7.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = S.Metal,
		Material = Enum.Material.Metal,
		Parent = m,
	})
	Builder.decor({ Name = "Arm", Size = Vector3.new(0.4, 0.4, armLength), CFrame = cf * CFrame.new(0, 14.6, -armLength / 2), Color = S.Metal, Material = Enum.Material.Metal, Parent = m })
	local box = cf * CFrame.new(0, 13, -armLength + 1)
	Builder.decor({ Name = "Box", Size = Vector3.new(1.4, 3.6, 1.2), CFrame = box, Color = Color3.fromRGB(28, 30, 32), Parent = m })
	local lights = {
		{ 1.1, Color3.fromRGB(90, 20, 20), Enum.Material.SmoothPlastic },
		{ 0, Color3.fromRGB(90, 70, 20), Enum.Material.SmoothPlastic },
		{ -1.1, Color3.fromRGB(60, 255, 120), Enum.Material.Neon },
	}
	for _, l in lights do
		-- Luces a ambos lados de la caja, mirando a lo largo de la calzada
		for _, side in { -1, 1 } do
			Builder.decor({
				Name = "Light",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.2, 0.9, 0.9),
				CFrame = box * CFrame.new(side * 0.72, l[1], 0),
				Color = l[2],
				Material = l[3],
				Parent = m,
			})
		end
	end
	return m
end

function Props.bench(parent: Instance, cf: CFrame)
	local asset = AssetLibrary.spawn("Bench", parent, cf)
	if asset then
		return asset
	end
	local m = Builder.model("Bench", parent)
	m:AddTag("Bench") -- el jugador se puede sentar (client/Controllers/Actions.luau)
	Builder.part({ ClassName = "Seat", Name = "Seat", Size = Vector3.new(6, 0.4, 1.8), CFrame = cf * CFrame.new(0, 1.9, 0), Color = S.Wood, Material = Enum.Material.Wood, CanTouch = false, Parent = m })
	Builder.decor({ Name = "Back", Size = Vector3.new(6, 1.6, 0.3), CFrame = cf * CFrame.new(0, 3, 0.95) * CFrame.Angles(math.rad(-10), 0, 0), Color = S.Wood, Material = Enum.Material.Wood, Parent = m })
	for _, x in { -2.6, 2.6 } do
		Builder.decor({ Name = "Leg", Size = Vector3.new(0.3, 1.8, 1.8), CFrame = cf * CFrame.new(x, 0.9, 0.1), Color = S.Metal, Material = Enum.Material.Metal, Parent = m })
	end
	return m
end

function Props.bin(parent: Instance, cf: CFrame)
	if AssetLibrary.spawn("Bin", parent, cf) then
		return
	end
	Builder.part({
		Name = "Bin",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2.6, 1.4, 1.4),
		CFrame = cf * CFrame.new(0, 1.3, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(56, 96, 70),
		Material = Enum.Material.Metal,
		Parent = parent,
	})
end

-- Marquesina de autobús (la parte abierta mira hacia la calzada)
function Props.busStop(parent: Instance, cf: CFrame)
	local asset = AssetLibrary.spawn("BusStop", parent, cf)
	if asset then
		return asset
	end
	local m = Builder.model("BusStop", parent)
	m:AddTag("Bench")
	Builder.decor({ Name = "Roof", Size = Vector3.new(10, 0.3, 4), CFrame = cf * CFrame.new(0, 8.2, 0), Color = S.Metal, Material = Enum.Material.Metal, Parent = m })
	Builder.part({ Name = "BackGlass", Size = Vector3.new(10, 6.5, 0.2), CFrame = cf * CFrame.new(0, 4.6, 1.8), Color = S.Glass, Material = Enum.Material.Glass, Transparency = 0.5, Parent = m })
	for _, x in { -4.9, 4.9 } do
		Builder.decor({ Name = "Post", Size = Vector3.new(0.3, 8, 0.3), CFrame = cf * CFrame.new(x, 4.1, 1.8), Color = S.Metal, Material = Enum.Material.Metal, Parent = m })
	end
	Builder.part({ ClassName = "Seat", Name = "Seat", Size = Vector3.new(6, 0.3, 1.2), CFrame = cf * CFrame.new(0, 2, 1.1), Color = S.Metal, Material = Enum.Material.Metal, CanTouch = false, Parent = m })
	local sign = Builder.decor({ Name = "Sign", Size = Vector3.new(2.4, 2.4, 0.2), CFrame = cf * CFrame.new(-6, 8, 0), Color = Color3.fromRGB(30, 110, 200), Parent = m })
	Builder.sign(sign, "BUS", Enum.NormalId.Front)
	Builder.sign(sign, "BUS", Enum.NormalId.Back)
	Builder.decor({ Name = "SignPost", Size = Vector3.new(0.25, 7, 0.25), CFrame = cf * CFrame.new(-6, 3.5, 0), Color = S.Metal, Material = Enum.Material.Metal, Parent = m })
	return m
end

-- Coche aparcado decorativo. El CFrame es el centro del coche a nivel de la calzada;
-- LookVector = morro.
function Props.car(parent: Instance, cf: CFrame, color: Color3?)
	local asset = AssetLibrary.spawn("Car", parent, cf)
	if asset then
		return asset
	end
	local m = Builder.model("ParkedCar", parent)
	local paint = color or Palette.pick(Palette.CarColors)
	local r = 1.3 -- radio de rueda
	Builder.part({ Name = "Body", Size = Vector3.new(6.2, 2.2, 13.5), CFrame = cf * CFrame.new(0, r + 0.9, 0), Color = paint, Material = Enum.Material.SmoothPlastic, Reflectance = 0.08, Parent = m })
	Builder.part({ Name = "Cabin", Size = Vector3.new(5.6, 2.1, 7), CFrame = cf * CFrame.new(0, r + 3, 0.6), Color = paint, Material = Enum.Material.SmoothPlastic, Reflectance = 0.08, Parent = m })
	local glassColor = Color3.fromRGB(40, 52, 62)
	Builder.decor({ Name = "SideWindows", Size = Vector3.new(5.7, 1.4, 6.2), CFrame = cf * CFrame.new(0, r + 3.1, 0.6), Color = glassColor, Material = Enum.Material.Glass, Parent = m })
	Builder.decor({ Name = "Windshield", Size = Vector3.new(5, 1.4, 7.1), CFrame = cf * CFrame.new(0, r + 3.1, 0.6), Color = glassColor, Material = Enum.Material.Glass, Parent = m })
	for _, z in { -4.3, 4.3 } do
		for _, x in { -2.9, 2.9 } do
			Builder.decor({
				Name = "Wheel",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(1.1, r * 2, r * 2),
				CFrame = cf * CFrame.new(x, r, z),
				Color = Color3.fromRGB(26, 26, 28),
				Material = Enum.Material.Rubber,
				Parent = m,
			})
		end
	end
	for _, x in { -2.2, 2.2 } do
		Builder.decor({ Name = "Headlight", Size = Vector3.new(1.2, 0.5, 0.2), CFrame = cf * CFrame.new(x, r + 1.4, -6.8), Color = Color3.fromRGB(255, 250, 230), Material = Enum.Material.Neon, Parent = m })
		Builder.decor({ Name = "Taillight", Size = Vector3.new(1.2, 0.5, 0.2), CFrame = cf * CFrame.new(x, r + 1.4, 6.8), Color = Color3.fromRGB(200, 30, 30), Material = Enum.Material.Neon, Parent = m })
	end
	return m
end

-- Tablón de empleo "SE BUSCA" (JobId debe existir en Config.Jobs)
function Props.jobBoard(parent: Instance, cf: CFrame, jobId: string, title: string)
	local m = Builder.model("JobBoard_" .. jobId, parent)
	for _, x in { -1.9, 1.9 } do
		Builder.part({ Name = "Post", Size = Vector3.new(0.3, 6.5, 0.3), CFrame = cf * CFrame.new(x, 3.25, 0), Color = S.Metal, Material = Enum.Material.Metal, Parent = m })
	end
	local board = Builder.part({
		Name = "Board",
		Size = Vector3.new(4.4, 3, 0.3),
		CFrame = cf * CFrame.new(0, 4.8, 0),
		Color = Color3.fromRGB(34, 108, 196),
		Tags = { "JobBoard" },
		Attributes = { JobId = jobId },
		Parent = m,
	})
	Builder.sign(board, "SE BUSCA\n" .. title, Enum.NormalId.Front)
	Builder.sign(board, "SE BUSCA\n" .. title, Enum.NormalId.Back)
	return m
end

-- Vehículos de servicio (decorativos, aparcados). kind: "Police" | "Ambulance" | "FireTruck" | "Bus"
function Props.vehicle(parent: Instance, cf: CFrame, kind: string)
	if kind == "Police" then
		local car = Props.car(parent, cf, Color3.fromRGB(240, 242, 246))
		if car and car:IsA("Model") and car.Name == "ParkedCar" then
			Builder.decor({ Name = "Stripe", Size = Vector3.new(6.3, 0.7, 13.6), CFrame = cf * CFrame.new(0, 2.2, 0), Color = Color3.fromRGB(30, 70, 170), Parent = car })
			Builder.decor({ Name = "LightBarRed", Size = Vector3.new(1.6, 0.5, 1), CFrame = cf * CFrame.new(-0.9, 5.6, 0.6), Color = Color3.fromRGB(230, 40, 40), Material = Enum.Material.Neon, Parent = car })
			Builder.decor({ Name = "LightBarBlue", Size = Vector3.new(1.6, 0.5, 1), CFrame = cf * CFrame.new(0.9, 5.6, 0.6), Color = Color3.fromRGB(40, 90, 255), Material = Enum.Material.Neon, Parent = car })
			car.Name = "PoliceCar"
		end
		return car
	end

	local m = Builder.model(kind, parent)
	local specs = {
		Ambulance = { Length = 16, Height = 7.5, Color = Color3.fromRGB(244, 244, 240), Stripe = Color3.fromRGB(210, 40, 40) },
		FireTruck = { Length = 26, Height = 8, Color = Color3.fromRGB(196, 30, 30), Stripe = Color3.fromRGB(240, 240, 240) },
		Bus = { Length = 34, Height = 9, Color = Color3.fromRGB(40, 110, 200), Stripe = Color3.fromRGB(240, 240, 240) },
		SchoolBus = { Length = 30, Height = 8.5, Color = Color3.fromRGB(245, 190, 30), Stripe = Color3.fromRGB(30, 30, 34) },
	}
	local spec = specs[kind] or specs.Ambulance
	local L, Hh = spec.Length, spec.Height
	local r = 1.5
	Builder.part({ Name = "Body", Size = Vector3.new(7, Hh - r, L - 4), CFrame = cf * CFrame.new(0, r + (Hh - r) / 2 + 0.3, 2), Color = spec.Color, Parent = m })
	Builder.part({ Name = "Cab", Size = Vector3.new(7, Hh - r - 1, 4), CFrame = cf * CFrame.new(0, r + (Hh - r - 1) / 2 + 0.3, -L / 2 + 2), Color = spec.Color, Parent = m })
	Builder.decor({ Name = "Windshield", Size = Vector3.new(6.2, 2, 0.2), CFrame = cf * CFrame.new(0, Hh - 2.2, -L / 2 - 0.05), Color = Color3.fromRGB(40, 52, 62), Material = Enum.Material.Glass, Parent = m })
	Builder.decor({ Name = "Stripe", Size = Vector3.new(7.1, 0.8, L - 4), CFrame = cf * CFrame.new(0, r + 2.2, 2), Color = spec.Stripe, Parent = m })
	if kind == "Bus" or kind == "SchoolBus" then
		Builder.decor({ Name = "Windows", Size = Vector3.new(7.1, 2.4, L - 8), CFrame = cf * CFrame.new(0, Hh - 2.4, 3), Color = Color3.fromRGB(40, 52, 62), Material = Enum.Material.Glass, Parent = m })
	end
	if kind == "FireTruck" then
		Builder.decor({ Name = "Ladder", Size = Vector3.new(2.4, 0.6, L - 6), CFrame = cf * CFrame.new(0, Hh + 0.6, 3), Color = Color3.fromRGB(200, 202, 206), Material = Enum.Material.Metal, Parent = m })
	end
	if kind == "Ambulance" then
		for _, side in { -1, 1 } do
			local crossCf = cf * CFrame.new(side * 3.56, r + 4.4, 3)
			Builder.decor({ Name = "Cross", Size = Vector3.new(0.1, 2.4, 0.8), CFrame = crossCf, Color = spec.Stripe, Parent = m })
			Builder.decor({ Name = "Cross", Size = Vector3.new(0.1, 0.8, 2.4), CFrame = crossCf, Color = spec.Stripe, Parent = m })
		end
	end
	if kind ~= "Bus" and kind ~= "SchoolBus" then
		Builder.decor({ Name = "LightBar", Size = Vector3.new(4, 0.5, 1), CFrame = cf * CFrame.new(0, Hh - 0.45, -L / 2 + 2), Color = if kind == "FireTruck" then Color3.fromRGB(255, 60, 40) else Color3.fromRGB(60, 110, 255), Material = Enum.Material.Neon, Parent = m })
	end
	for _, z in { -L / 2 + 3, L / 2 - 4 } do
		for _, x in { -3.2, 3.2 } do
			Builder.decor({
				Name = "Wheel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, r * 2, r * 2),
				CFrame = cf * CFrame.new(x, r, z), Color = Color3.fromRGB(26, 26, 28), Material = Enum.Material.Rubber, Parent = m,
			})
		end
	end
	return m
end

return Props
