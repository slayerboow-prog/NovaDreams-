-- PostOffice: la oficina de Correos por dentro (oficio de repartidor, PostService).
--
--   PostOffice.build(model, at, W, D)   (at(x, y, z): y = 0 suelo, -Z = fachada)
--
-- Mostrador con tres ventanillas, báscula y sellos; detrás, la zona de clasificación con
-- estanterías de paquetes, jaulas con cajas y la mesa del escáner (PostSort: cargar la ruta y
-- cerrarla). Fuera, junto a la puerta, el punto de la moto y la bici de reparto (PostVehicle)
-- y un buzón amarillo de Correos.

local Builder = require(script.Parent.Parent.Builder)

local PostOffice = {}

local rgb = Color3.fromRGB
local YELLOW = rgb(250, 200, 30)
local BLUE = rgb(30, 60, 140)
local CARDBOARD = { rgb(190, 150, 100), rgb(170, 130, 85), rgb(205, 170, 120), rgb(150, 115, 75) }

function PostOffice.build(model: Model, at: (number, number, number) -> CFrame, W: number, D: number)
	local function solid(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
		local props = { Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = model }
		for k, v in extra or {} do
			props[k] = v
		end
		return Builder.part(props)
	end
	local function bit(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, transparency: number?): BasePart
		return Builder.decor({ Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Transparency = transparency or 0, Parent = model })
	end
	local function box(cf: CFrame, size: Vector3)
		bit("Parcel", size, cf, CARDBOARD[math.random(1, #CARDBOARD)], Enum.Material.Cardboard)
		bit("Tape", Vector3.new(size.X + 0.02, 0.1, size.Z * 0.2), cf * CFrame.new(0, size.Y / 2, 0), rgb(200, 170, 110), Enum.Material.SmoothPlastic)
		if math.random() < 0.5 then
			bit("Label", Vector3.new(size.X * 0.4, size.Y * 0.3, 0.03), cf * CFrame.new(0, 0, -size.Z / 2 - 0.02), rgb(250, 250, 250))
		end
	end

	---------------------------------------------------------------------
	-- Mostrador de atención con ventanillas
	---------------------------------------------------------------------
	local cz = 2
	solid("Counter", Vector3.new(24, 3.6, 3), at(0, 1.8, cz), BLUE, Enum.Material.SmoothPlastic)
	solid("CounterTop", Vector3.new(24.4, 0.3, 3.4), at(0, 3.75, cz), rgb(236, 234, 228), Enum.Material.Marble)
	bit("CounterStripe", Vector3.new(24, 0.5, 0.1), at(0, 2.8, cz - 1.52), YELLOW)
	for i, x in { -8, 0, 8 } do
		-- Mampara de cristal, número de ventanilla, báscula y sellos
		bit("Screen", Vector3.new(6, 3, 0.15), at(x, 5.4, cz - 0.4), rgb(200, 225, 240), Enum.Material.Glass, 0.6)
		bit("Slot", Vector3.new(2, 0.4, 0.2), at(x, 4.1, cz - 0.4), rgb(40, 40, 44))
		local number = bit("Window", Vector3.new(1.2, 0.9, 0.1), at(x, 7.4, cz - 0.4), BLUE)
		Builder.sign(number, tostring(i), Enum.NormalId.Front, YELLOW)
		bit("Scale", Vector3.new(1.4, 0.25, 1.2), at(x + 1.8, 4.05, cz), rgb(200, 202, 208), Enum.Material.Metal)
		bit("Stamp", Vector3.new(0.4, 0.6, 0.4), at(x - 1.8, 4.2, cz + 0.4), rgb(120, 70, 40), Enum.Material.Wood)
		bit("Envelopes", Vector3.new(1, 0.3, 0.7), at(x - 1, 4.05, cz + 0.6), rgb(250, 245, 230))
	end
	-- Cintas para hacer cola
	for k = 0, 3 do
		local x = -9 + k * 6
		bit("QueuePost", Vector3.new(0.3, 3, 0.3), at(x, 1.5, -6), rgb(200, 202, 208), Enum.Material.Metal)
		if k < 3 then
			bit("QueueBelt", Vector3.new(6, 0.25, 0.08), at(x + 3, 2.8, -6), BLUE)
		end
	end
	-- Máquina de turnos y expositor de cajas
	bit("TicketMachine", Vector3.new(1.4, 4.2, 1), at(-16, 2.1, -8), YELLOW, Enum.Material.Metal)
	bit("TicketScreen", Vector3.new(1, 0.8, 0.05), at(-16, 3.6, -8.52), rgb(60, 170, 220), Enum.Material.Neon)
	bit("BoxRack", Vector3.new(4, 5, 1.2), at(16, 2.5, -8), rgb(220, 220, 224), Enum.Material.Metal)
	for row = 0, 2 do
		box(at(15, 1.2 + row * 1.6, -8), Vector3.new(1.4, 1, 1))
		box(at(17, 1.2 + row * 1.6, -8), Vector3.new(1.6, 1.2, 1))
	end

	---------------------------------------------------------------------
	-- Zona de clasificación (detrás del mostrador)
	---------------------------------------------------------------------
	local backZ = D / 2 - 1.5
	for _, x in { -12, -4, 4, 12 } do
		-- Estanterías con paquetes por zonas (etiqueta de color)
		for _, px in { -3.1, 3.1 } do
			for _, pz in { -0.8, 0.8 } do
				bit("RackPost", Vector3.new(0.2, 7, 0.2), at(x + px, 3.5, backZ + pz), rgb(150, 154, 160), Enum.Material.Metal)
			end
		end
		bit("RackZone", Vector3.new(6.4, 0.6, 0.1), at(x, 7.3, backZ - 0.95), ({ rgb(220, 60, 60), rgb(60, 140, 220), rgb(60, 170, 90), YELLOW })[(x + 12) // 8 + 1])
		for shelf = 0, 2 do
			bit("RackShelf", Vector3.new(6.2, 0.15, 1.8), at(x, 0.5 + shelf * 2.2, backZ), rgb(120, 124, 130), Enum.Material.Metal)
			local bx = x - 2.4
			while bx < x + 2.4 do
				local w = 0.9 + math.random() * 0.8
				box(at(bx + w / 2, 0.58 + shelf * 2.2 + 0.5, backZ), Vector3.new(w, 0.8 + math.random() * 0.8, 1.2))
				bx += w + 0.15
			end
		end
	end
	-- Jaulas con cajas listas para repartir
	for k, x in { -16, 16 } do
		local cage = at(x, 0, 8)
		bit("CageBase", Vector3.new(3, 0.3, 3), cage * CFrame.new(0, 0.5, 0), rgb(120, 124, 130), Enum.Material.Metal)
		for _, side in { { 1.5, 0 }, { -1.5, 0 } } do
			bit("CageSide", Vector3.new(0.1, 4.5, 3), cage * CFrame.new(side[1], 2.8, side[2]), rgb(170, 174, 180), Enum.Material.DiamondPlate, 0.4)
		end
		for n = 0, 4 do
			box(cage * CFrame.new((n % 2) * 1.2 - 0.6, 1.2 + (n // 2) * 1.1, (n % 3) * 0.6 - 0.6) * CFrame.Angles(0, math.rad(n * 17 + k), 0), Vector3.new(1.1, 1, 1.1))
		end
	end
	-- Mesa de clasificación con escáner, pantalla y bolsa de cartas
	local tableCf = at(0, 0, 9)
	solid("SortTable", Vector3.new(10, 3.4, 3.4), tableCf * CFrame.new(0, 1.7, 0), rgb(200, 202, 208), Enum.Material.Metal)
	bit("SortTop", Vector3.new(10.2, 0.2, 3.6), tableCf * CFrame.new(0, 3.5, 0), rgb(236, 234, 228))
	bit("Scanner", Vector3.new(0.4, 0.3, 1.2), tableCf * CFrame.new(-3, 3.8, -0.6) * CFrame.Angles(0, math.rad(20), 0), rgb(40, 40, 44))
	bit("ScannerLight", Vector3.new(0.3, 0.05, 0.2), tableCf * CFrame.new(-3.2, 3.9, -1.1), rgb(255, 60, 60), Enum.Material.Neon)
	bit("Monitor", Vector3.new(2, 1.4, 0.15), tableCf * CFrame.new(3, 4.6, 0.8), rgb(30, 30, 34))
	bit("MonitorScreen", Vector3.new(1.8, 1.2, 0.05), tableCf * CFrame.new(3, 4.6, 0.7), rgb(60, 140, 220), Enum.Material.Neon)
	bit("MailBag", Vector3.new(1.6, 1.4, 1), tableCf * CFrame.new(0.5, 4.3, 0.4), YELLOW, Enum.Material.Fabric)
	for n = 0, 3 do
		box(tableCf * CFrame.new(-1 - n * 0.3, 4 + n * 0.1, 0.8) * CFrame.Angles(0, math.rad(n * 25), 0), Vector3.new(1.2, 0.8, 1))
	end
	-- Puesto: cargar y cerrar la ruta (pieza invisible delante de la mesa)
	Builder.part({ Name = "PostSort", Size = Vector3.new(8, 3, 1.4), CFrame = tableCf * CFrame.new(0, 2.5, -2.4), Transparency = 1, CanCollide = false, Tags = { "PostSort" }, Parent = model })

	-- Carteles de la pared
	local poster = bit("Poster", Vector3.new(8, 3, 0.1), at(0, 9.2, backZ - 1), YELLOW)
	Builder.sign(poster, "📦 CORREOS · REPARTO", Enum.NormalId.Front, BLUE)

	---------------------------------------------------------------------
	-- Fuera: buzón amarillo y punto de la moto / bici de reparto
	---------------------------------------------------------------------
	local front = -D / 2
	local mail = at(W / 2 - 4, 0, front - 3)
	bit("PostBoxLeg", Vector3.new(0.6, 2.4, 0.6), mail * CFrame.new(0, 1.2, 0), YELLOW, Enum.Material.Metal)
	bit("PostBox", Vector3.new(1.8, 2.2, 1.4), mail * CFrame.new(0, 3.4, 0), YELLOW, Enum.Material.Metal)
	bit("PostBoxTop", Vector3.new(2, 0.3, 1.6), mail * CFrame.new(0, 4.6, 0), YELLOW, Enum.Material.Metal)
	bit("PostBoxSlot", Vector3.new(1.2, 0.2, 0.1), mail * CFrame.new(0, 3.9, -0.72), rgb(30, 30, 34))
	local vehicle = at(-W / 2 + 4, 0, front - 5)
	bit("ParkingMark", Vector3.new(6, 0.05, 8), vehicle * CFrame.new(0, 0.03, 0), YELLOW, Enum.Material.SmoothPlastic)
	bit("SignPost", Vector3.new(0.3, 5, 0.3), vehicle * CFrame.new(3.4, 2.5, 3.6), rgb(60, 60, 64), Enum.Material.Metal)
	local sign = bit("Sign", Vector3.new(3, 1.2, 0.1), vehicle * CFrame.new(3.4, 5, 3.6), BLUE)
	Builder.sign(sign, "REPARTO", Enum.NormalId.Front, YELLOW)
	Builder.part({ Name = "PostVehicle", Size = Vector3.new(4, 3, 4), CFrame = vehicle * CFrame.new(0, 1.5, 0), Transparency = 1, CanCollide = false, Tags = { "PostVehicle" }, Parent = model })
	model:AddTag("PostOffice")
end

return PostOffice
