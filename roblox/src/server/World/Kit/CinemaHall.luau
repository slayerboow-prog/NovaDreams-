-- CinemaHall: el cine por dentro (oficio de taquillero/a y sesiones de cine, CinemaService).
--
--   CinemaHall.build(model, at, W, D)   (at(x, y, z): y = 0 suelo, -Z = fachada; puerta en x = 0)
--
-- VESTÍBULO: mostrador con taquilla (CinemaRegister: aquí se compra) y detrás la barra con la
--   máquina de palomitas, el surtidor de refrescos y los nachos (CinemaStation + Station),
--   carteles de las películas, pantalla con los horarios (CinemaSchedule), moqueta y bancos.
-- SALA: tabique con la puerta (CinemaDoor: se entra con entrada), pantalla gigante (CinemaScreen)
--   y butacas en gradas (Seat de verdad, CinemaSeat), luces de pasillo.
-- Puntos (atributos Vector3): Outside, Door, Queue1..4, Staff, Inside (dentro de la sala) y Lobby.

local Builder = require(script.Parent.Parent.Builder)

local CinemaHall = {}

local rgb = Color3.fromRGB
local RED = rgb(150, 24, 36)
local DARK = rgb(24, 22, 30)
local GOLD = rgb(220, 180, 80)
local STEEL = rgb(190, 194, 200)

function CinemaHall.build(model: Model, at: (number, number, number) -> CFrame, W: number, D: number)
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
	local front = -D / 2
	local wallZ = -4 -- tabique entre el vestíbulo y la sala
	local H = 20

	---------------------------------------------------------------------
	-- Vestíbulo
	---------------------------------------------------------------------
	bit("Carpet", Vector3.new(W - 2, 0.05, wallZ - front - 1), at(0, 0.03, (front + wallZ) / 2), RED, Enum.Material.Carpet)
	-- Mostrador (taquilla + barra)
	local cz = front + 10
	solid("Counter", Vector3.new(20, 3.6, 2.4), at(12, 1.8, cz), DARK, Enum.Material.SmoothPlastic)
	bit("CounterTop", Vector3.new(20.4, 0.2, 2.8), at(12, 3.7, cz), GOLD, Enum.Material.Metal)
	bit("CounterLights", Vector3.new(20, 0.2, 0.1), at(12, 0.5, cz - 1.25), rgb(255, 200, 80), Enum.Material.Neon)
	-- Taquilla con cristal, ranura y pantalla
	local reg = at(5.5, 3.8, cz)
	solid("TicketWindow", Vector3.new(4, 0.6, 1.6), reg * CFrame.new(0, 0.3, 0.2), rgb(40, 40, 46), Enum.Material.SmoothPlastic, { Tags = { "CinemaRegister" } })
	bit("TicketGlass", Vector3.new(5, 4, 0.12), reg * CFrame.new(0, 2.4, -0.6), rgb(200, 225, 240), Enum.Material.Glass, 0.6)
	bit("TicketSlot", Vector3.new(1.6, 0.3, 0.2), reg * CFrame.new(0, 0.6, -0.62), DARK)
	bit("TicketPrinter", Vector3.new(1, 0.6, 0.8), reg * CFrame.new(1.4, 0.9, 0.3), rgb(230, 230, 230))
	local taquilla = bit("TaquillaSign", Vector3.new(5, 1.2, 0.2), reg * CFrame.new(0, 5.2, -0.6), RED)
	Builder.sign(taquilla, "🎟️ TAQUILLA", Enum.NormalId.Front, GOLD)
	-- Barra: palomitas, refrescos y nachos (detrás del mostrador)
	local bz = cz + 3.4
	solid("BackCounter", Vector3.new(14, 3.6, 2), at(15, 1.8, bz), DARK, Enum.Material.SmoothPlastic)
	bit("BackTop", Vector3.new(14.2, 0.2, 2.2), at(15, 3.7, bz), rgb(60, 60, 66), Enum.Material.Granite)
	local function station(id: string, x: number)
		Builder.part({ Name = "Station_" .. id, Size = Vector3.new(3, 3, 1.6), CFrame = at(x, 4.5, bz - 1.6), Transparency = 1, CanCollide = false, Tags = { "CinemaStation" }, Attributes = { Station = id }, Parent = model })
	end
	-- Máquina de palomitas con cristal y palomitas dentro
	bit("PopcornBase", Vector3.new(3, 1, 2), at(11, 4.3, bz), RED)
	bit("PopcornGlass", Vector3.new(2.8, 2.4, 1.8), at(11, 6, bz), rgb(250, 240, 200), Enum.Material.Glass, 0.4)
	bit("Popcorn", Vector3.new(2.6, 1, 1.6), at(11, 5.3, bz), rgb(250, 235, 170), Enum.Material.Sand)
	bit("PopcornTop", Vector3.new(3.1, 0.5, 2.1), at(11, 7.4, bz), RED)
	local pop = bit("PopcornSign", Vector3.new(2.6, 0.5, 0.05), at(11, 7.4, bz - 1.07), RED)
	Builder.sign(pop, "POPCORN", Enum.NormalId.Front, GOLD)
	station("Palomitas", 11)
	-- Surtidor de refrescos
	bit("SodaMachine", Vector3.new(3, 3, 1.6), at(15.5, 5.3, bz + 0.1), rgb(30, 90, 170), Enum.Material.Metal)
	for k = -1, 1 do
		bit("SodaTap", Vector3.new(0.3, 0.5, 0.3), at(15.5 + k * 0.9, 4.4, bz - 0.8), STEEL, Enum.Material.Metal)
		bit("SodaLabel", Vector3.new(0.7, 0.9, 0.05), at(15.5 + k * 0.9, 5.8, bz - 0.72), ({ rgb(200, 30, 30), rgb(250, 160, 30), rgb(60, 180, 80) })[k + 2], Enum.Material.Neon)
	end
	station("Refresco", 15.5)
	-- Calentador de nachos
	bit("NachoWarmer", Vector3.new(2.6, 1.6, 1.6), at(19.5, 4.6, bz), STEEL, Enum.Material.Metal)
	bit("NachoGlass", Vector3.new(2.4, 1.2, 0.1), at(19.5, 4.7, bz - 0.82), rgb(255, 230, 160), Enum.Material.Glass, 0.3)
	bit("Nachos", Vector3.new(2.2, 0.6, 1.2), at(19.5, 4.2, bz), rgb(240, 190, 80), Enum.Material.Sand)
	station("Nachos", 19.5)
	-- Vasos y cubos de palomitas apilados sobre el mostrador
	for k = 0, 2 do
		Builder.decor({ Name = "Cup", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.9, 0.7, 0.7), CFrame = at(9 + k * 0.8, 4.3, cz + 0.6) * CFrame.Angles(0, 0, math.rad(90)), Color = RED, Parent = model })
	end
	-- Carteles de las películas en la pared de la izquierda y pantalla con los horarios
	for i = 1, 3 do
		local poster = bit("FilmPoster", Vector3.new(0.2, 7, 5), at(-W / 2 + 1.2, 6.5, front + 4 + (i - 1) * 6), rgb(40, 40, 50))
		poster:SetAttribute("FilmIndex", i)
		poster:AddTag("CinemaPoster")
		bit("PosterFrame", Vector3.new(0.15, 7.6, 5.6), at(-W / 2 + 1.1, 6.5, front + 4 + (i - 1) * 6), GOLD, Enum.Material.Metal)
	end
	local schedule = bit("ScheduleBoard", Vector3.new(10, 4, 0.3), at(-4, 12, wallZ - 0.4), DARK)
	schedule:AddTag("CinemaSchedule")
	for k = 0, 1 do
		local bench = at(-12 + k * 7, 0, front + 12)
		bit("Bench", Vector3.new(5, 0.5, 1.6), bench * CFrame.new(0, 1.8, 0), RED, Enum.Material.Fabric)
		bit("BenchLegs", Vector3.new(4.6, 1.6, 1.2), bench * CFrame.new(0, 0.8, 0), GOLD, Enum.Material.Metal, 0.5)
	end
	-- Postes con cinta para la cola de la taquilla
	for k = 0, 2 do
		bit("QueuePost", Vector3.new(0.3, 3, 0.3), at(2, 1.5, front + 3 + k * 2.5), GOLD, Enum.Material.Metal)
	end
	bit("QueueRope", Vector3.new(0.1, 0.25, 5), at(2, 2.8, front + 4.25), RED, Enum.Material.Fabric)

	---------------------------------------------------------------------
	-- Tabique con la puerta de la sala
	---------------------------------------------------------------------
	local doorX, doorW = -W / 2 + 6, 6
	local leftW = doorX - doorW / 2 - (-W / 2)
	local rightW = W / 2 - (doorX + doorW / 2)
	solid("SalaWall", Vector3.new(leftW, H, 0.8), at(-W / 2 + leftW / 2, H / 2, wallZ), rgb(60, 40, 60), Enum.Material.Plaster)
	solid("SalaWall", Vector3.new(rightW, H, 0.8), at(W / 2 - rightW / 2, H / 2, wallZ), rgb(60, 40, 60), Enum.Material.Plaster)
	solid("SalaWall", Vector3.new(doorW, H - 9, 0.8), at(doorX, 9 + (H - 9) / 2, wallZ), rgb(60, 40, 60), Enum.Material.Plaster)
	-- Puerta: cortina roja que solo se cruza con entrada (CinemaService teletransporta)
	solid("SalaDoor", Vector3.new(doorW, 9, 0.6), at(doorX, 4.5, wallZ), RED, Enum.Material.Fabric, { Tags = { "CinemaDoor" } })
	local salaSign = bit("SalaSign", Vector3.new(5, 1.2, 0.2), at(doorX, 10.3, wallZ - 0.5), DARK)
	Builder.sign(salaSign, "SALA 1", Enum.NormalId.Front, GOLD)
	bit("ExitSign", Vector3.new(2, 0.6, 0.1), at(doorX, 10, wallZ + 0.45), rgb(40, 200, 90), Enum.Material.Neon)

	---------------------------------------------------------------------
	-- Sala: pantalla y butacas en gradas mirando a la pantalla (+Z)
	---------------------------------------------------------------------
	local back = D / 2
	bit("SalaFloor", Vector3.new(W - 2, 0.05, back - wallZ - 1.4), at(0, 0.03, (wallZ + back) / 2), rgb(40, 20, 30), Enum.Material.Carpet)
	local screen = solid("Screen", Vector3.new(W - 12, 11, 0.3), at(2, 9, back - 1.4), rgb(235, 235, 240), Enum.Material.SmoothPlastic, { Tags = { "CinemaScreen" } })
	screen:SetAttribute("Face", "Front")
	bit("ScreenFrame", Vector3.new(W - 10, 12.4, 0.2), at(2, 9, back - 1.2), DARK)
	for _, sx in { -1, 1 } do
		bit("Curtain", Vector3.new(2.4, 13, 0.4), at(2 + sx * ((W - 12) / 2 + 1.4), 8.5, back - 1.6), RED, Enum.Material.Fabric)
	end
	-- Gradas: cada fila un escalón más alto hacia el fondo de la sala (hacia la puerta)
	local rows = 5
	for r = 0, rows - 1 do
		local z = back - 10 - r * 3
		local y = r * 0.9
		if r > 0 then
			solid("Tier", Vector3.new(W - 8, y, 3), at(2, y / 2, z), rgb(50, 26, 36), Enum.Material.Carpet)
		end
		for k = 0, 8 do
			local x = -13 + k * 3.2
			local seat = at(x, y, z) * CFrame.Angles(0, math.pi, 0)
			Builder.part({ ClassName = "Seat", Name = "CinemaSeat", Size = Vector3.new(2.2, 0.6, 2), CFrame = seat * CFrame.new(0, 1.7, 0), Color = RED, Material = Enum.Material.Fabric, Tags = { "CinemaSeat" }, Parent = model })
			bit("SeatBack", Vector3.new(2.2, 2.6, 0.4), seat * CFrame.new(0, 2.9, 1), RED, Enum.Material.Fabric)
			bit("SeatArm", Vector3.new(0.3, 1, 2), seat * CFrame.new(1.25, 2.2, 0), DARK)
		end
	end
	-- Luces de pasillo
	for r = 0, rows - 1 do
		bit("AisleLight", Vector3.new(0.4, 0.2, 0.4), at(-16.5, r * 0.9 + 0.2, back - 10 - r * 3), rgb(255, 200, 100), Enum.Material.Neon)
	end
	for _, z in { 2, 10 } do
		for _, sx in { -1, 1 } do
			bit("Sconce", Vector3.new(0.3, 1, 0.8), at(sx * (W / 2 - 1.2), 9, z), rgb(255, 214, 150), Enum.Material.Neon)
		end
	end

	---------------------------------------------------------------------
	-- Puntos
	---------------------------------------------------------------------
	local function point(x: number, z: number): Vector3
		return at(x, 0, z).Position
	end
	model:SetAttribute("Outside", point(0, front - 7))
	model:SetAttribute("Door", point(0, front + 2))
	for i = 1, 4 do
		model:SetAttribute("Queue" .. i, point(5.5, cz - 3 - (i - 1) * 2.8))
	end
	model:SetAttribute("Staff", point(5.5, cz + 2))
	model:SetAttribute("Lobby", point(doorX, wallZ - 3))
	model:SetAttribute("Inside", point(doorX, wallZ + 3))
	model:AddTag("Cinema")
end

return CinemaHall
