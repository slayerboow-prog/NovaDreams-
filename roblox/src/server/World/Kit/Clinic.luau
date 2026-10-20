-- Clinic: la planta baja de un hospital o centro de salud (oficio de médico/a, MedicalService).
--
--   Clinic.build(model, at, W, D)   (at(x, y, z): y = 0 suelo, -Z = fachada con la puerta en x = 0)
--
-- Admisión (ClinicReception), sala de espera con sillas (ClinicSeat), consultas con escritorio
-- (ClinicDesk), camilla (ClinicBed) y botiquín (ClinicMeds), todas con RoomId; control de
-- enfermería, máquina de agua, expendedora y señalización. El centro de la planta queda libre
-- (ahí la historia coloca a sus personajes). El modelo lleva la etiqueta Clinic y los puntos
-- Outside, Door y Reception (atributos Vector3).

local Builder = require(script.Parent.Parent.Builder)

local Clinic = {}

local rgb = Color3.fromRGB
local WHITE = rgb(246, 247, 248)
local MINT = rgb(170, 220, 205)
local BLUE = rgb(40, 110, 180)
local STEEL = rgb(190, 194, 200)
local DARK = rgb(44, 46, 52)
local WOOD = rgb(170, 130, 90)

function Clinic.build(model: Model, at: (number, number, number) -> CFrame, W: number, D: number)
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
	local function sign(part: BasePart, text: string, color: Color3?)
		Builder.sign(part, text, Enum.NormalId.Front, color or WHITE)
	end
	local function chair(cf: CFrame, color: Color3, tag: string?)
		solid("Seat", Vector3.new(1.8, 0.3, 1.8), cf * CFrame.new(0, 1.6, 0), color, Enum.Material.Plastic, { Tags = if tag then { tag } else nil })
		bit("ChairBack", Vector3.new(1.8, 1.8, 0.2), cf * CFrame.new(0, 2.6, 0.85), color, Enum.Material.Plastic)
		bit("ChairLegs", Vector3.new(1.6, 1.45, 1.6), cf * CFrame.new(0, 0.73, 0), STEEL, Enum.Material.Metal, 0.7)
	end

	local front, back = -D / 2, D / 2
	local HALL = 9 -- altura de los tabiques

	---------------------------------------------------------------------
	-- Admisión (a la izquierda de la entrada)
	---------------------------------------------------------------------
	local rx, rz = -W / 4, front + 9
	solid("ReceptionDesk", Vector3.new(12, 3.6, 2.4), at(rx, 1.8, rz), WHITE, Enum.Material.SmoothPlastic, { Tags = { "ClinicReception" } })
	bit("DeskTop", Vector3.new(12.4, 0.2, 3), at(rx, 3.7, rz), WOOD, Enum.Material.Wood)
	bit("DeskStripe", Vector3.new(12, 0.6, 0.1), at(rx, 2.6, rz - 1.22), MINT)
	for _, dx in { -3, 3 } do
		bit("Monitor", Vector3.new(1.8, 1.2, 0.15), at(rx + dx, 4.6, rz + 0.5), DARK)
		bit("MonitorScreen", Vector3.new(1.6, 1, 0.05), at(rx + dx, 4.6, rz + 0.42), rgb(90, 170, 230), Enum.Material.Neon)
	end
	bit("TicketMachine", Vector3.new(1, 1.4, 0.8), at(rx - 7.5, 2.6, rz - 1), BLUE, Enum.Material.Metal)
	bit("TicketScreen", Vector3.new(0.7, 0.5, 0.05), at(rx - 7.5, 3, rz - 1.42), rgb(250, 60, 60), Enum.Material.Neon)
	local admision = bit("AdmissionSign", Vector3.new(8, 1.4, 0.2), at(rx, 7.5, rz + 1.3), BLUE)
	sign(admision, "ADMISIÓN")

	---------------------------------------------------------------------
	-- Sala de espera (a la derecha de la entrada)
	---------------------------------------------------------------------
	local wx0 = 10
	local seatColors = { rgb(60, 140, 200), rgb(70, 170, 150) }
	for row = 0, 2 do
		for k = 0, 4 do
			local x = wx0 + k * 2.2
			if x < W / 2 - 3 then
				chair(at(x, 0, front + 7 + row * 4.2) * CFrame.Angles(0, math.pi, 0), seatColors[row % 2 + 1], "ClinicSeat")
			end
		end
	end
	bit("WaitingRug", Vector3.new(12, 0.05, 13), at(wx0 + 4.4, 0.03, front + 11), rgb(220, 232, 236))
	-- Tele, máquina de agua, expendedora y plantas
	local tv = bit("TV", Vector3.new(6, 3.4, 0.3), at(wx0 + 4.4, 7, front + 0.8), DARK)
	sign(tv, "Turno: 07", rgb(250, 200, 60))
	bit("WaterCooler", Vector3.new(1.2, 3, 1.2), at(W / 2 - 2, 1.5, front + 18), rgb(236, 236, 236))
	Builder.decor({ Name = "WaterBottle", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 1.1, 1.1), CFrame = at(W / 2 - 2, 3.7, front + 18) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(150, 200, 240), Material = Enum.Material.Glass, Transparency = 0.3, Parent = model })
	bit("Vending", Vector3.new(3, 6, 2), at(W / 2 - 2, 3, front + 22), rgb(200, 40, 50), Enum.Material.Metal)
	bit("VendingGlass", Vector3.new(0.1, 4, 1.6), at(W / 2 - 3.05, 3.6, front + 22), rgb(200, 230, 240), Enum.Material.Glass, 0.3)
	for _, p in { { W / 2 - 2, front + 2 }, { -W / 2 + 2, front + 2 } } do
		Builder.decor({ Name = "PlantPot", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 1.8, 1.8), CFrame = at(p[1], 0.8, p[2]) * CFrame.Angles(0, 0, math.rad(90)), Color = WHITE, Material = Enum.Material.Plaster, Parent = model })
		Builder.decor({ Name = "Plant", Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 3.6, 2.6), CFrame = at(p[1], 3.2, p[2]), Color = rgb(60, 130, 70), Material = Enum.Material.LeafyGrass, Parent = model })
	end
	-- Líneas de colores en el suelo que guían a las consultas
	bit("FloorLine", Vector3.new(0.6, 0.04, D - 16), at(-4, 0.03, 0), BLUE)
	bit("FloorLine", Vector3.new(0.6, 0.04, D - 16), at(-5, 0.03, 0), MINT)

	---------------------------------------------------------------------
	-- Consultas (a los lados, dejando libre el centro)
	---------------------------------------------------------------------
	local roomW, roomD = 13, 13
	local rooms = {}
	table.insert(rooms, -W / 2 + 1 + roomW / 2)
	if W >= 80 then
		table.insert(rooms, -W / 2 + 2 + roomW * 1.5)
	end
	table.insert(rooms, W / 2 - 1 - roomW / 2)
	for id, cx in rooms do
		local cz = back - 1 - roomD / 2
		local room = at(cx, 0, cz)
		-- Tabiques (con hueco de puerta delante)
		for _, sx in { -1, 1 } do
			solid("RoomWall", Vector3.new(0.4, HALL, roomD), room * CFrame.new(sx * roomW / 2, HALL / 2, 0), WHITE, Enum.Material.Plaster)
			solid("RoomFront", Vector3.new(roomW / 2 - 2.5, HALL, 0.4), room * CFrame.new(sx * (roomW / 4 + 1.25), HALL / 2, -roomD / 2), WHITE, Enum.Material.Plaster)
		end
		bit("RoomLintel", Vector3.new(5, HALL - 7.5, 0.4), room * CFrame.new(0, 7.5 + (HALL - 7.5) / 2, -roomD / 2), WHITE, Enum.Material.Plaster)
		bit("RoomStripe", Vector3.new(roomW, 0.5, 0.1), room * CFrame.new(0, 3, -roomD / 2 - 0.22), MINT)
		local door = bit("RoomSign", Vector3.new(4, 1, 0.1), room * CFrame.new(0, 8.3, -roomD / 2 - 0.25), BLUE)
		sign(door, "CONSULTA " .. id)
		bit("RoomLight", Vector3.new(0.5, 0.3, 0.1), room * CFrame.new(2.7, 8.3, -roomD / 2 - 0.25), rgb(80, 220, 120), Enum.Material.Neon)
		-- Escritorio con ordenador y sillas
		local desk = room * CFrame.new(-roomW / 2 + 3, 0, 1)
		solid("Desk", Vector3.new(3.6, 3, 2.2), desk * CFrame.new(0, 1.5, 0), WOOD, Enum.Material.Wood, { Tags = { "ClinicDesk" }, Attributes = { RoomId = id } })
		bit("PC", Vector3.new(1.6, 1.1, 0.15), desk * CFrame.new(0, 3.7, 0.6), DARK)
		bit("PCScreen", Vector3.new(1.4, 0.9, 0.05), desk * CFrame.new(0, 3.7, 0.52), rgb(90, 170, 230), Enum.Material.Neon)
		bit("Keyboard", Vector3.new(1.2, 0.08, 0.5), desk * CFrame.new(0, 3.05, -0.3), DARK)
		chair(desk * CFrame.new(0, 0, 2) * CFrame.Angles(0, math.pi, 0), DARK, nil)
		chair(desk * CFrame.new(0, 0, -2), rgb(60, 140, 200), nil)
		-- Camilla con papel, lámpara y monitor
		local bed = room * CFrame.new(roomW / 2 - 2.6, 0, 1.5)
		bit("BedFrame", Vector3.new(2.6, 2.2, 6.4), bed * CFrame.new(0, 1.1, 0), STEEL, Enum.Material.Metal)
		solid("Bed", Vector3.new(2.6, 0.5, 6.4), bed * CFrame.new(0, 2.45, 0), MINT, Enum.Material.Fabric, { Tags = { "ClinicBed" }, Attributes = { RoomId = id } })
		bit("BedPaper", Vector3.new(1.8, 0.05, 6.2), bed * CFrame.new(0, 2.72, 0), rgb(250, 250, 250))
		bit("Pillow", Vector3.new(2, 0.4, 1.2), bed * CFrame.new(0, 2.9, 2.5), WHITE, Enum.Material.Fabric)
		bit("LampPole", Vector3.new(0.15, 6, 0.15), bed * CFrame.new(-1.8, 3, -2.8), STEEL, Enum.Material.Metal)
		bit("ExamLamp", Vector3.new(1.2, 0.5, 1.2), bed * CFrame.new(-1.2, 6, -2.2), rgb(255, 250, 235), Enum.Material.Neon)
		bit("VitalMonitor", Vector3.new(1.6, 1.2, 0.6), bed * CFrame.new(-1.6, 4.5, 3), DARK)
		bit("VitalScreen", Vector3.new(1.4, 1, 0.05), bed * CFrame.new(-1.6, 4.5, 2.68), rgb(60, 220, 120), Enum.Material.Neon)
		-- Botiquín / vitrina de medicinas con lavabo
		local meds = room * CFrame.new(0.5, 0, roomD / 2 - 1)
		solid("MedCabinet", Vector3.new(4, 7, 1.4), meds * CFrame.new(0, 3.5, 0), WHITE, Enum.Material.Metal, { Tags = { "ClinicMeds" }, Attributes = { RoomId = id } })
		bit("CabinetGlass", Vector3.new(3.6, 3, 0.1), meds * CFrame.new(0, 5, -0.72), rgb(200, 230, 240), Enum.Material.Glass, 0.4)
		for k = 0, 5 do
			bit("MedBox", Vector3.new(0.5, 0.6, 0.4), meds * CFrame.new(-1.3 + (k % 3) * 1.3, 4.4 + (k // 3) * 1.2, -0.3), ({ rgb(240, 80, 80), rgb(80, 150, 240), rgb(250, 200, 60) })[k % 3 + 1])
		end
		bit("RedCross", Vector3.new(0.9, 0.3, 0.05), meds * CFrame.new(0, 2.5, -0.72), rgb(220, 40, 40), Enum.Material.Neon)
		bit("RedCross", Vector3.new(0.3, 0.9, 0.05), meds * CFrame.new(0, 2.5, -0.72), rgb(220, 40, 40), Enum.Material.Neon)
		bit("Sink", Vector3.new(2, 0.6, 1.4), room * CFrame.new(-roomW / 2 + 2, 3, roomD / 2 - 1), WHITE)
		bit("Tap", Vector3.new(0.2, 0.8, 0.2), room * CFrame.new(-roomW / 2 + 2, 3.7, roomD / 2 - 0.5), STEEL, Enum.Material.Metal)
		local chart = bit("EyeChart", Vector3.new(2, 3, 0.1), room * CFrame.new(-roomW / 2 + 0.3, 5.5, -2) * CFrame.Angles(0, math.rad(90), 0), WHITE)
		sign(chart, "E\nF P\nT O Z", DARK)
		-- Dónde se pone el paciente (tumbado en la camilla) y dónde espera el médico
		model:SetAttribute("Room" .. id .. "Door", at(cx, 0, cz - roomD / 2 - 1.5).Position)
	end
	model:SetAttribute("Rooms", #rooms)

	---------------------------------------------------------------------
	-- Control de enfermería (a la derecha, delante de la última consulta)
	---------------------------------------------------------------------
	local nx, nz = W / 2 - 8, back - roomD - 6
	solid("NurseDesk", Vector3.new(8, 3.6, 2.4), at(nx, 1.8, nz), WHITE, Enum.Material.SmoothPlastic)
	bit("NurseTop", Vector3.new(8.4, 0.2, 3), at(nx, 3.7, nz), MINT)
	local nurse = bit("NurseSign", Vector3.new(6, 1.2, 0.2), at(nx, 7.2, nz), BLUE)
	sign(nurse, "ENFERMERÍA")
	bit("Clipboards", Vector3.new(1.4, 0.2, 1), at(nx - 2, 3.9, nz), rgb(250, 245, 230))
	bit("Wheelchair", Vector3.new(2, 2.6, 2.4), at(nx - 6, 1.3, nz + 3), DARK, Enum.Material.Metal, 0.2)

	---------------------------------------------------------------------
	-- Puntos para los pacientes NPC
	---------------------------------------------------------------------
	model:SetAttribute("Outside", at(0, 0, front - 8).Position)
	model:SetAttribute("Door", at(0, 0, front + 2).Position)
	model:SetAttribute("Reception", at(rx, 0, rz - 3).Position)
	model:AddTag("Clinic")
end

return Clinic
