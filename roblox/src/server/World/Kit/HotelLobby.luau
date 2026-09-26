-- HotelLobby: pabellón de recepción acristalado junto a cada hotel (oficio de recepcionista,
-- HotelService). Los hoteles son edificios macizos; la recepción se juega aquí.
--
--   HotelLobby.build(parent, cf, name)   cf = centro a ras de suelo, -Z = hacia la calle
--
-- Mostrador (HotelDesk) con casillero de llaves, timbre y ordenador; vestíbulo con sofás, mesa,
-- alfombra, plantas y carrito de maletas; ascensores (HotelElevator) que suben a las habitaciones.
-- Puntos (atributos Vector3): Outside, Door, Queue1..3, Staff y Elevator. Etiqueta HotelLobby.

local Builder = require(script.Parent.Parent.Builder)

local HotelLobby = {}

local rgb = Color3.fromRGB
local GOLD = rgb(210, 175, 90)
local CREAM = rgb(244, 238, 226)
local WOOD = rgb(110, 70, 45)
local DARK = rgb(34, 34, 40)
local GLASS = rgb(170, 210, 225)

local W, D, H = 24, 30, 12

function HotelLobby.build(parent: Instance, cf: CFrame, name: string): Model
	local m = Builder.model("RecepcionHotel", parent)
	m:SetAttribute("HotelName", name)
	local function at(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x, y, z)
	end
	local function solid(pname: string, size: Vector3, c: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
		local props = { Name = pname, Size = size, CFrame = c, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = m }
		for k, v in extra or {} do
			props[k] = v
		end
		return Builder.part(props)
	end
	local function bit(pname: string, size: Vector3, c: CFrame, color: Color3, material: Enum.Material?, transparency: number?): BasePart
		return Builder.decor({ Name = pname, Size = size, CFrame = c, Color = color, Material = material or Enum.Material.SmoothPlastic, Transparency = transparency or 0, Parent = m })
	end

	-- Suelo de mármol, techo y paredes (delante y a los lados, cristal; detrás, pared)
	solid("Floor", Vector3.new(W, 1, D), at(0, 0.5, 0), rgb(230, 226, 218), Enum.Material.Marble)
	bit("Rug", Vector3.new(10, 0.05, 12), at(5, 1.03, -5), rgb(120, 30, 40), Enum.Material.Carpet)
	solid("Roof", Vector3.new(W + 1, 0.8, D + 1), at(0, H + 0.4, 0), CREAM, Enum.Material.Concrete)
	solid("BackWall", Vector3.new(W, H, 0.6), at(0, H / 2 + 0.5, D / 2 - 0.3), CREAM, Enum.Material.Plaster)
	for _, sx in { -1, 1 } do
		solid("SideGlass", Vector3.new(0.3, H - 1, D - 1), at(sx * (W / 2 - 0.15), H / 2 + 0.5, 0), GLASS, Enum.Material.Glass, { Transparency = 0.5 })
		solid("FrontGlass", Vector3.new(W / 2 - 3, H - 1, 0.3), at(sx * (W / 4 + 1.5), H / 2 + 0.5, -D / 2 + 0.15), GLASS, Enum.Material.Glass, { Transparency = 0.5 })
		bit("Mullion", Vector3.new(0.4, H, 0.4), at(sx * (W / 2 - 0.2), H / 2 + 0.5, -D / 2 + 0.2), GOLD, Enum.Material.Metal)
		bit("DoorPost", Vector3.new(0.4, H, 0.4), at(sx * 3, H / 2 + 0.5, -D / 2 + 0.2), GOLD, Enum.Material.Metal)
	end
	bit("DoorLintel", Vector3.new(6, H - 8, 0.3), at(0, 8.5 + (H - 8) / 2, -D / 2 + 0.15), GLASS, Enum.Material.Glass, 0.5)
	local sign = bit("Sign", Vector3.new(16, 2.4, 0.4), at(0, H + 2, -D / 2 + 0.3), DARK)
	Builder.sign(sign, "🛎️ RECEPCIÓN · " .. string.upper(name), Enum.NormalId.Front, GOLD)
	-- Toldo y alfombra de entrada
	bit("Canopy", Vector3.new(8, 0.4, 5), at(0, 9.5, -D / 2 - 2.4), GOLD, Enum.Material.Metal)
	bit("EntranceRug", Vector3.new(5, 0.05, 6), at(0, 0.05, -D / 2 - 3), rgb(120, 30, 40), Enum.Material.Carpet)
	for _, sx in { -1, 1 } do
		Builder.decor({ Name = "Pot", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 1.8, 1.8), CFrame = at(sx * 4.5, 0.8, -D / 2 - 1.5) * CFrame.Angles(0, 0, math.rad(90)), Color = GOLD, Material = Enum.Material.Metal, Parent = m })
		Builder.decor({ Name = "Topiary", Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), CFrame = at(sx * 4.5, 2.6, -D / 2 - 1.5), Color = rgb(60, 120, 60), Material = Enum.Material.LeafyGrass, Parent = m })
	end

	-- Mostrador de recepción con casillero de llaves detrás
	local dz = 5
	solid("Desk", Vector3.new(12, 3.6, 2.4), at(-3, 2.8, dz), WOOD, Enum.Material.Wood, { Tags = { "HotelDesk" } })
	bit("DeskTop", Vector3.new(12.4, 0.2, 2.8), at(-3, 4.7, dz), rgb(40, 40, 44), Enum.Material.Marble)
	bit("DeskGold", Vector3.new(12, 0.3, 0.1), at(-3, 3.6, dz - 1.25), GOLD, Enum.Material.Metal)
	bit("Bell", Vector3.new(0.6, 0.35, 0.6), at(-5, 4.95, dz - 0.6), GOLD, Enum.Material.Metal)
	bit("PC", Vector3.new(1.6, 1.1, 0.15), at(-1, 5.5, dz + 0.6), DARK)
	bit("PCScreen", Vector3.new(1.4, 0.9, 0.05), at(-1, 5.5, dz + 0.52), rgb(90, 160, 230), Enum.Material.Neon)
	bit("Brochures", Vector3.new(1, 0.6, 0.4), at(1.8, 5.1, dz - 0.6), rgb(60, 140, 200))
	local rack = at(-3, 0, D / 2 - 0.9)
	bit("KeyRack", Vector3.new(9, 5, 0.6), rack * CFrame.new(0, 6, 0), WOOD, Enum.Material.Wood)
	for row = 0, 2 do
		for col = 0, 3 do
			local c = rack * CFrame.new(-3.3 + col * 2.2, 4.4 + row * 1.6, -0.35)
			bit("Cubby", Vector3.new(1.8, 1.3, 0.1), c, rgb(80, 50, 30), Enum.Material.Wood)
			bit("Key", Vector3.new(0.3, 0.6, 0.08), c * CFrame.new(0, -0.1, -0.1), GOLD, Enum.Material.Metal)
		end
	end
	local clocks = { "MADRID", "LONDRES", "NUEVA YORK" }
	for k, city in clocks do
		local clock = at(-9 + (k - 1) * 3, 9.8, D / 2 - 0.65)
		Builder.decor({ Name = "Clock", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 1.6, 1.6), CFrame = clock * CFrame.Angles(0, math.rad(90), 0), Color = CREAM, Parent = m })
		local label = bit("ClockLabel", Vector3.new(2.6, 0.5, 0.05), clock * CFrame.new(0, -1.2, 0), DARK)
		Builder.sign(label, city, Enum.NormalId.Front, GOLD)
	end

	-- Vestíbulo: sofás, mesa baja, lámpara, plantas y carrito de maletas
	for _, sz in { -1, 1 } do
		local sofa = at(6, 1, -5 + sz * 4) * CFrame.Angles(0, if sz > 0 then math.pi else 0, 0)
		bit("SofaSeat", Vector3.new(7, 1.4, 2.6), sofa * CFrame.new(0, 0.9, 0), rgb(40, 60, 90), Enum.Material.Fabric)
		bit("SofaBack", Vector3.new(7, 2.4, 0.8), sofa * CFrame.new(0, 1.9, 1.2), rgb(40, 60, 90), Enum.Material.Fabric)
		for _, x in { -3.7, 3.7 } do
			bit("SofaArm", Vector3.new(0.6, 1.8, 2.6), sofa * CFrame.new(x, 1.3, 0), rgb(40, 60, 90), Enum.Material.Fabric)
		end
	end
	bit("CoffeeTable", Vector3.new(4, 0.3, 2), at(6, 2.2, -5), rgb(40, 40, 44), Enum.Material.Glass)
	bit("TableLegs", Vector3.new(3.6, 1.2, 1.6), at(6, 1.6, -5), GOLD, Enum.Material.Metal, 0.6)
	bit("Magazine", Vector3.new(1, 0.06, 1.3), at(5.4, 2.4, -5), rgb(200, 60, 80))
	bit("LampPole", Vector3.new(0.2, 6, 0.2), at(10.5, 4, -9.5), GOLD, Enum.Material.Metal)
	local shade = bit("LampShade", Vector3.new(1.6, 1.2, 1.6), at(10.5, 7.2, -9.5), rgb(250, 240, 210), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Range = 18
	light.Brightness = 0.9
	light.Color = rgb(255, 220, 170)
	light.Parent = shade
	local chandelier = bit("Chandelier", Vector3.new(3, 1.2, 3), at(0, H - 1.2, -2), rgb(255, 240, 200), Enum.Material.Neon)
	local glow = Instance.new("PointLight")
	glow.Range = 26
	glow.Brightness = 1.2
	glow.Color = rgb(255, 225, 180)
	glow.Parent = chandelier
	for _, p in { { -10.5, -13 }, { 10.5, -13 }, { 10.5, 3 } } do
		Builder.decor({ Name = "Pot", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.8, 1.8, 1.8), CFrame = at(p[1], 1.9, p[2]) * CFrame.Angles(0, 0, math.rad(90)), Color = CREAM, Material = Enum.Material.Plaster, Parent = m })
		Builder.decor({ Name = "Plant", Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 3.6, 2.4), CFrame = at(p[1], 4.4, p[2]), Color = rgb(60, 130, 70), Material = Enum.Material.LeafyGrass, Parent = m })
	end
	local cart = at(-8, 1, -9)
	bit("CartBase", Vector3.new(3, 0.3, 2), cart * CFrame.new(0, 0.6, 0), rgb(120, 30, 40), Enum.Material.Carpet)
	for _, sx in { -1, 1 } do
		bit("CartPole", Vector3.new(0.15, 5, 0.15), cart * CFrame.new(sx * 1.4, 3, 0), GOLD, Enum.Material.Metal)
	end
	bit("CartBar", Vector3.new(3, 0.15, 0.15), cart * CFrame.new(0, 5.5, 0), GOLD, Enum.Material.Metal)
	for k, color in { rgb(40, 60, 120), rgb(150, 40, 40), rgb(60, 60, 64) } do
		bit("Suitcase", Vector3.new(1.6, 1.8 - k * 0.2, 0.7), cart * CFrame.new(-0.8 + (k - 1) * 0.8, 1.7, (k % 2) * 0.5 - 0.2), color, Enum.Material.Fabric)
	end

	-- Ascensores a las habitaciones (pared de la derecha, al fondo)
	for k = 0, 1 do
		local door = at(W / 2 - 0.5, 0, 6 + k * 5) * CFrame.Angles(0, math.rad(-90), 0)
		bit("ElevatorFrame", Vector3.new(4, 8, 0.3), door * CFrame.new(0, 4.5, 0.1), GOLD, Enum.Material.Metal)
		bit("ElevatorDoor", Vector3.new(3.4, 7.2, 0.2), door * CFrame.new(0, 4.3, -0.05), rgb(190, 194, 200), Enum.Material.Metal)
		bit("ElevatorSeam", Vector3.new(0.06, 7.2, 0.22), door * CFrame.new(0, 4.3, -0.06), DARK)
		bit("FloorIndicator", Vector3.new(1.2, 0.5, 0.1), door * CFrame.new(0, 8.9, -0.1), rgb(255, 120, 40), Enum.Material.Neon)
		bit("CallButton", Vector3.new(0.3, 0.5, 0.1), door * CFrame.new(2.3, 4, -0.1), GOLD, Enum.Material.Neon)
	end
	Builder.part({ Name = "HotelElevator", Size = Vector3.new(2, 6, 9), CFrame = at(W / 2 - 2, 4, 8.5), Transparency = 1, CanCollide = false, Tags = { "HotelElevator" }, Parent = m })

	-- Puntos
	local function point(x: number, z: number): Vector3
		return at(x, 1, z).Position
	end
	m:SetAttribute("Outside", point(0, -D / 2 - 7))
	m:SetAttribute("Door", point(0, -D / 2 + 2))
	for i = 1, 3 do
		m:SetAttribute("Queue" .. i, point(-3, dz - 3 - (i - 1) * 3))
	end
	m:SetAttribute("Staff", point(-3, dz + 3))
	m:SetAttribute("Elevator", point(W / 2 - 3, 8.5))
	m:AddTag("HotelLobby")
	return m
end

return HotelLobby
