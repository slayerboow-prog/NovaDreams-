-- Rides: modelos de los vehículos que se pueden montar (monopatín, bici, moto y coche).
-- Se usan igual para los que están aparcados en las estaciones públicas (anclados)
-- y para el que lleva el jugador (VehicleService los suelda a su personaje).
--
-- Convención: el CFrame es el centro del vehículo a ras de suelo y su LookVector es el morro.

local Builder = require(script.Parent.Parent.Builder)
local Palette = require(script.Parent.Palette)

local Rides = {}

local rgb = Color3.fromRGB
local TIRE = rgb(26, 26, 28)
local METAL = rgb(170, 174, 180)

-- Asiento del conductor (respecto al centro del vehículo a ras de suelo) y tamaño de la base.
-- Standing = se va de pie (el personaje se coloca de pie encima en vez de sentado)
Rides.Spec = {
	Monopatin = { Seat = CFrame.new(0, 0.7, 0), Size = Vector3.new(1.4, 1, 4.2), Standing = true },
	Patinete = { Seat = CFrame.new(0, 0.75, 0.4), Size = Vector3.new(1.4, 1, 3.8), Standing = true },
	Bici = { Seat = CFrame.new(0, 3.2, 1), Size = Vector3.new(1.2, 1, 4.8) },
	Moto = { Seat = CFrame.new(0, 2.55, 0.8), Size = Vector3.new(1.6, 1, 5.8) },
	Coche = { Seat = CFrame.new(-1.4, 1.6, 0.4), Size = Vector3.new(6.2, 1, 13.5) },
	Autobus = { Seat = CFrame.new(-2.4, 2.6, -13), Size = Vector3.new(8.6, 1, 34) },
}

local function wheel(m: Model, cf: CFrame, radius: number, width: number)
	return Builder.part({
		Name = "Wheel",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(width, radius * 2, radius * 2),
		CFrame = cf,
		Color = TIRE,
		Material = Enum.Material.Rubber,
		Parent = m,
	})
end

local function box(m: Model, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, transparency: number?)
	return Builder.part({
		Name = name,
		Size = size,
		CFrame = cf,
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
		Transparency = transparency or 0,
		Parent = m,
	})
end

local function monopatin(m: Model, cf: CFrame, color: Color3)
	box(m, "Deck", Vector3.new(1.3, 0.2, 4.2), cf * CFrame.new(0, 0.55, 0), color, Enum.Material.Wood)
	box(m, "Grip", Vector3.new(1.2, 0.05, 3.8), cf * CFrame.new(0, 0.67, 0), rgb(30, 30, 34), Enum.Material.Sand)
	for _, z in { -1.4, 1.4 } do
		box(m, "Truck", Vector3.new(1, 0.2, 0.3), cf * CFrame.new(0, 0.38, z), METAL, Enum.Material.Metal)
		for _, x in { -0.5, 0.5 } do
			wheel(m, cf * CFrame.new(x, 0.25, z), 0.25, 0.25)
		end
	end
end

local function bici(m: Model, cf: CFrame, color: Color3)
	local r = 1.3
	for _, z in { -1.8, 1.8 } do
		wheel(m, cf * CFrame.new(0, r, z), r, 0.25)
		box(m, "Hub", Vector3.new(0.3, 0.4, 0.4), cf * CFrame.new(0, r, z), METAL, Enum.Material.Metal)
	end
	box(m, "TopTube", Vector3.new(0.25, 0.25, 2.6), cf * CFrame.new(0, 2.7, -0.1), color)
	box(m, "DownTube", Vector3.new(0.25, 0.25, 2.6), cf * CFrame.new(0, 1.9, -0.6) * CFrame.Angles(math.rad(-30), 0, 0), color)
	box(m, "ChainStay", Vector3.new(0.2, 0.2, 1.9), cf * CFrame.new(0, r, 0.9), color)
	box(m, "SeatTube", Vector3.new(0.25, 1.8, 0.25), cf * CFrame.new(0, 2.1, 0.8) * CFrame.Angles(math.rad(-12), 0, 0), color)
	box(m, "Seat", Vector3.new(0.7, 0.25, 1.1), cf * CFrame.new(0, 3.1, 1), rgb(30, 30, 34), Enum.Material.Fabric)
	box(m, "Fork", Vector3.new(0.2, 2.2, 0.2), cf * CFrame.new(0, 2.3, -1.65) * CFrame.Angles(math.rad(10), 0, 0), METAL, Enum.Material.Metal)
	box(m, "Handlebar", Vector3.new(2, 0.2, 0.2), cf * CFrame.new(0, 3.4, -1.45), rgb(30, 30, 34))
	box(m, "Pedals", Vector3.new(1.4, 0.15, 0.4), cf * CFrame.new(0, 1.1, 0.1), rgb(40, 40, 44))
end

local function moto(m: Model, cf: CFrame, color: Color3)
	for _, z in { -2.3, 2.3 } do
		wheel(m, cf * CFrame.new(0, 1, z), 1, 0.6)
	end
	box(m, "Body", Vector3.new(1.4, 1.2, 3.4), cf * CFrame.new(0, 1.5, 0.3), color)
	box(m, "Floor", Vector3.new(1.4, 0.3, 1.6), cf * CFrame.new(0, 1.05, -0.8), rgb(40, 40, 44))
	box(m, "Seat", Vector3.new(1.2, 0.45, 2), cf * CFrame.new(0, 2.35, 0.8), rgb(30, 30, 34), Enum.Material.Fabric)
	box(m, "Shield", Vector3.new(1.5, 2.4, 0.4), cf * CFrame.new(0, 2.1, -1.8) * CFrame.Angles(math.rad(-15), 0, 0), color)
	box(m, "Stem", Vector3.new(0.3, 1.2, 0.3), cf * CFrame.new(0, 3.4, -2.05), METAL, Enum.Material.Metal)
	box(m, "Handlebar", Vector3.new(2.2, 0.25, 0.25), cf * CFrame.new(0, 3.9, -2), rgb(30, 30, 34))
	box(m, "Headlight", Vector3.new(0.7, 0.4, 0.2), cf * CFrame.new(0, 3.3, -2.2), rgb(255, 250, 230), Enum.Material.Neon)
	box(m, "Taillight", Vector3.new(0.6, 0.3, 0.2), cf * CFrame.new(0, 2.1, 2.05), rgb(200, 30, 30), Enum.Material.Neon)
end

local function patinete(m: Model, cf: CFrame, color: Color3)
	for _, z in { -1.5, 1.5 } do
		wheel(m, cf * CFrame.new(0, 0.35, z), 0.35, 0.3)
	end
	box(m, "Deck", Vector3.new(1, 0.2, 3.2), cf * CFrame.new(0, 0.55, 0.1), rgb(40, 40, 44))
	box(m, "Grip", Vector3.new(0.9, 0.05, 2.6), cf * CFrame.new(0, 0.67, 0.2), rgb(25, 25, 28), Enum.Material.Sand)
	box(m, "Stem", Vector3.new(0.25, 3.6, 0.25), cf * CFrame.new(0, 2.3, -1.45) * CFrame.Angles(math.rad(-8), 0, 0), color, Enum.Material.Metal)
	box(m, "Handlebar", Vector3.new(1.9, 0.2, 0.2), cf * CFrame.new(0, 4.05, -1.7), rgb(30, 30, 34))
	box(m, "Headlight", Vector3.new(0.4, 0.3, 0.2), cf * CFrame.new(0, 3.5, -1.72), rgb(255, 250, 230), Enum.Material.Neon)
	box(m, "Fender", Vector3.new(0.35, 0.15, 0.9), cf * CFrame.new(0, 0.8, 1.55), color)
end

local function coche(m: Model, cf: CFrame, color: Color3)
	local r = 1.3
	local glass = rgb(150, 190, 215)
	box(m, "Body", Vector3.new(6.2, 2.2, 13.5), cf * CFrame.new(0, r + 0.9, 0), color, nil).Reflectance = 0.08
	box(m, "Roof", Vector3.new(5.6, 0.3, 6.6), cf * CFrame.new(0, 5.35, 0.8), color).Reflectance = 0.08
	for _, x in { -2.65, 2.65 } do
		for _, z in { -2.4, 4 } do
			box(m, "Pillar", Vector3.new(0.3, 2.2, 0.3), cf * CFrame.new(x, 4.2, z), color)
		end
		box(m, "SideGlass", Vector3.new(0.1, 1.9, 6.1), cf * CFrame.new(x, 4.2, 0.8), glass, Enum.Material.Glass, 0.55)
	end
	box(m, "Windshield", Vector3.new(5.2, 1.9, 0.1), cf * CFrame.new(0, 4.2, -2.45), glass, Enum.Material.Glass, 0.5)
	box(m, "RearGlass", Vector3.new(5.2, 1.9, 0.1), cf * CFrame.new(0, 4.2, 4.05), glass, Enum.Material.Glass, 0.5)
	box(m, "Steering", Vector3.new(1.4, 1.4, 0.2), cf * CFrame.new(0, 3.9, -1.6) * CFrame.Angles(math.rad(-30), 0, 0), rgb(30, 30, 34))
	for _, z in { -4.3, 4.3 } do
		for _, x in { -2.9, 2.9 } do
			wheel(m, cf * CFrame.new(x, r, z), r, 1.1)
		end
	end
	for _, x in { -2.2, 2.2 } do
		box(m, "Headlight", Vector3.new(1.2, 0.5, 0.2), cf * CFrame.new(x, r + 1.4, -6.8), rgb(255, 250, 230), Enum.Material.Neon)
		box(m, "Taillight", Vector3.new(1.2, 0.5, 0.2), cf * CFrame.new(x, r + 1.4, 6.8), rgb(200, 30, 30), Enum.Material.Neon)
	end
end

-- Autobús urbano (línea L1): puertas a la derecha, asientos de pasajeros de verdad (Seat)
local function autobus(m: Model, cf: CFrame, color: Color3)
	local L, Wd, Hh = 34, 8.6, 9.4
	local glass = rgb(40, 60, 75)
	local r = 1.6
	box(m, "Body", Vector3.new(Wd, 3.2, L), cf * CFrame.new(0, r + 1.2, 0), color).Reflectance = 0.05
	box(m, "Floor", Vector3.new(Wd - 0.6, 0.3, L - 1), cf * CFrame.new(0, 2.3, 0), rgb(70, 72, 78), Enum.Material.Rubber)
	box(m, "Roof", Vector3.new(Wd, 0.5, L), cf * CFrame.new(0, Hh, 0), rgb(240, 240, 240))
	box(m, "RoofUnit", Vector3.new(5, 0.8, 8), cf * CFrame.new(0, Hh + 0.6, 4), rgb(210, 210, 214), Enum.Material.Metal)
	-- Ventanas (lado izquierdo entero; el derecho con huecos para las puertas)
	box(m, "WindowLeft", Vector3.new(0.2, 3.6, L - 2), cf * CFrame.new(-Wd / 2 + 0.1, 6.6, 0), glass, Enum.Material.Glass, 0.35)
	for _, span in { { -9.5, 1.5 }, { 7.5, 16 } } do
		local len = span[2] - span[1]
		box(m, "WindowRight", Vector3.new(0.2, 3.6, len), cf * CFrame.new(Wd / 2 - 0.1, 6.6, (span[1] + span[2]) / 2), glass, Enum.Material.Glass, 0.35)
	end
	box(m, "Windshield", Vector3.new(Wd - 0.4, 5, 0.2), cf * CFrame.new(0, 6.3, -L / 2 + 0.1), glass, Enum.Material.Glass, 0.3)
	box(m, "RearWall", Vector3.new(Wd, 5.6, 0.3), cf * CFrame.new(0, 6.3, L / 2 - 0.15), color)
	box(m, "Stripe", Vector3.new(Wd + 0.05, 0.6, L + 0.05), cf * CFrame.new(0, 4.9, 0), rgb(250, 200, 40))
	-- Montantes entre ventanas
	for z = -L / 2 + 1, L / 2 - 1, 5.5 do
		box(m, "Pillar", Vector3.new(Wd + 0.1, 3.6, 0.3), cf * CFrame.new(0, 6.6, z), color)
	end
	-- Puertas (delantera y central, a la derecha): se abren en las paradas (BusService)
	for i, z in { -14, 4.5 } do
		local door = box(m, "BusDoor", Vector3.new(0.3, 6.6, 4.6), cf * CFrame.new(Wd / 2 + 0.05, 5.4, z), glass, Enum.Material.Glass, 0.3)
		door:SetAttribute("DoorIndex", i)
	end
	-- Letrero de línea
	local sign = box(m, "LineSign", Vector3.new(Wd - 1.5, 1.2, 0.2), cf * CFrame.new(0, 8.5, -L / 2 - 0.05), rgb(20, 20, 24), Enum.Material.SmoothPlastic)
	Builder.sign(sign, "L1 · CIRCULAR VALMAR", Enum.NormalId.Front, Color3.fromRGB(255, 190, 40), Color3.fromRGB(20, 20, 24))
	-- Ruedas y luces
	for _, z in { -11, 10 } do
		for _, x in { -Wd / 2 + 0.4, Wd / 2 - 0.4 } do
			wheel(m, cf * CFrame.new(x, r, z), r, 1.2)
		end
	end
	for _, x in { -3, 3 } do
		box(m, "Headlight", Vector3.new(1.4, 0.6, 0.2), cf * CFrame.new(x, 2.8, -L / 2 - 0.1), rgb(255, 250, 230), Enum.Material.Neon)
		box(m, "Taillight", Vector3.new(1.2, 0.8, 0.2), cf * CFrame.new(x, 3, L / 2 + 0.1), rgb(200, 30, 30), Enum.Material.Neon)
	end
	-- Puesto del conductor y asientos de pasajeros (Seat de verdad; no se activan al tocarlos)
	box(m, "Dashboard", Vector3.new(Wd - 1, 1.6, 1.2), cf * CFrame.new(0, 3.2, -L / 2 + 1.2), rgb(40, 40, 44))
	box(m, "Steering", Vector3.new(1.4, 1.4, 0.2), cf * CFrame.new(-2.4, 4.4, -L / 2 + 2.2) * CFrame.Angles(math.rad(-50), 0, 0), rgb(30, 30, 34))
	for z = -8, 13, 3.4 do
		for _, x in { -2.6, 2.6 } do
			if not (x > 0 and z > 2 and z < 7) then -- hueco en la puerta central
				Builder.part({
					ClassName = "Seat",
					Name = "PassengerSeat",
					Size = Vector3.new(2.6, 0.5, 2),
					CFrame = cf * CFrame.new(x, 3.2, z), -- mirando hacia delante
					Color = rgb(30, 70, 140),
					Material = Enum.Material.Fabric,
					CanTouch = false,
					Parent = m,
				})
				box(m, "SeatBack", Vector3.new(2.6, 2.4, 0.4), cf * CFrame.new(x, 4.6, z + 1.1), rgb(30, 70, 140), Enum.Material.Fabric)
			end
		end
	end
end

local BUILDERS = { Monopatin = monopatin, Patinete = patinete, Bici = bici, Moto = moto, Coche = coche, Autobus = autobus }
local COLORS = {
	Monopatin = { rgb(220, 70, 60), rgb(40, 140, 220), rgb(250, 200, 40), rgb(60, 170, 90) },
	Bici = { rgb(30, 110, 200), rgb(210, 50, 60), rgb(40, 160, 90), rgb(240, 240, 240) },
	Moto = { rgb(200, 30, 40), rgb(30, 30, 34), rgb(240, 240, 240), rgb(40, 90, 180) },
	Patinete = { rgb(30, 30, 34), rgb(240, 240, 240), rgb(220, 70, 60), rgb(40, 140, 220) },
	Autobus = { rgb(200, 40, 45) },
}

-- Crea el modelo del vehículo (anclado). kind: "Monopatin" | "Bici" | "Moto" | "Coche"
function Rides.build(kind: string, parent: Instance?, cf: CFrame, color: Color3?): Model
	local m = Instance.new("Model")
	m.Name = kind
	local paint = color or (if COLORS[kind] then Palette.pick(COLORS[kind]) else Palette.pick(Palette.CarColors))
	BUILDERS[kind](m, cf, paint)
	m.Parent = parent
	return m
end

-- Convierte un modelo en un vehículo que se conduce: añade la base invisible ("Chassis", la
-- pieza principal) y el asiento del conductor ("DriverSeat"), y suelda todo a la base.
-- groundCf = centro del vehículo a ras de suelo, mirando hacia el morro. Queda aparcado (anclado).
function Rides.prepare(model: Model, kind: string, groundCf: CFrame): (BasePart, VehicleSeat)
	local spec = Rides.Spec[kind]
	local chassis = Instance.new("Part")
	chassis.Name = "Chassis"
	chassis.Size = spec.Size
	chassis.CFrame = groundCf * CFrame.new(0, spec.Size.Y / 2, 0)
	chassis.Transparency = 1
	chassis.CanCollide = false
	chassis.CanTouch = false
	chassis.CanQuery = false
	chassis.Anchored = true
	chassis.Parent = model
	local seat = Instance.new("VehicleSeat")
	seat.Name = "DriverSeat"
	seat.Size = Vector3.new(1.6, 0.2, 1.6)
	seat.CFrame = groundCf * spec.Seat * CFrame.new(0, -0.1, 0)
	seat.Transparency = 1
	seat.CanCollide = false
	seat.CanTouch = false -- nadie se sube al tocarlo: se sube con el cartel
	seat.CanQuery = false
	seat.MaxSpeed = 0 -- lo mueve Driving.luau, no las ruedas de Roblox
	seat.HeadsUpDisplay = false
	seat.Parent = model
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part ~= chassis then
			part:SetAttribute("Collide", part.CanCollide)
			part.Anchored = false
			part.Massless = true
			part.CanTouch = false
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = chassis
			weld.Part1 = part
			weld.Parent = part
		end
	end
	model.PrimaryPart = chassis
	model:SetAttribute("Drivable", true)
	model:SetAttribute("Kind", kind)
	return chassis, seat
end

-- Estación pública de bicis y monopatines (tag RentalStation). La usa VehicleService.
function Rides.station(parent: Instance, cf: CFrame)
	local m = Builder.model("BiciPublica", parent)
	Builder.part({ Name = "Base", Size = Vector3.new(9, 0.2, 4), CFrame = cf * CFrame.new(0, 0.1, 0), Color = rgb(60, 64, 70), Material = Enum.Material.Metal, Parent = m })
	local post = Builder.part({ Name = "Totem", Size = Vector3.new(1.4, 5, 0.8), CFrame = cf * CFrame.new(-4, 2.5, 0), Color = rgb(30, 150, 80), Parent = m })
	Builder.sign(post, "BICI\nPÚBLICA", Enum.NormalId.Front)
	Builder.sign(post, "BICI\nPÚBLICA", Enum.NormalId.Back)
	for i, x in { -1.5, 1.5 } do
		Builder.decor({ Name = "Rack", Size = Vector3.new(0.2, 1.6, 2.6), CFrame = cf * CFrame.new(x - 0.7, 0.9, 0), Color = METAL, Material = Enum.Material.Metal, Parent = m })
		local display = Rides.build("Bici", m, cf * CFrame.new(x, 0.2, 0) * CFrame.Angles(0, math.pi / 2, 0), rgb(30, 150, 80))
		display.Name = "DisplayBici" .. i
		for _, p in display:GetChildren() do
			if p:IsA("BasePart") then
				p.CanCollide = false
				p.CanQuery = false
			end
		end
	end
	local board = Rides.build("Monopatin", m, cf * CFrame.new(3.6, 0.2, 0.8), rgb(30, 150, 80))
	board.Name = "DisplayMonopatin"
	Builder.part({
		Name = "RentalPoint",
		Size = Vector3.new(2, 2, 2),
		CFrame = cf * CFrame.new(0, 2.5, 0),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		Tags = { "RentalStation" },
		Parent = m,
	})
	return m
end

return Rides
