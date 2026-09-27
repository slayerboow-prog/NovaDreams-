-- Prison: el Centro Penitenciario de Valmar, al este de la ciudad (junto a la carretera de la
-- rotonda este). Es grande a propósito: quien se porta mal pasa aquí su condena y tiene mucho que
-- hacer (PrisonService: trabajos, deporte, estudios, comedor, economato, enfermería, teléfono, túnel…).
--
--   Fuera: explanada, parada de autobús, garita, tablón de funcionarios y la mitad de la sala de visitas.
--   Dentro (muros de 22 studs con torres):
--     [Módulo A: 14 celdas]   [Aislamiento]   [Módulo B: 14 celdas]            (al fondo)
--     [Campo de fútbol]  [Canasta] [Pesas]    [Lavandería][Cocina][Carpintería][Huerto]
--     [TV][Capilla][Teléfonos]  (patio)  [Comedor][Biblioteca][Gimnasio][Enfermería·Economato]
--     [Oficina de funcionarios]      — puerta —      [Sala de visitas (mitad de dentro)]
--
-- Etiquetas: PrisonArea (zona), PrisonCell (+Cell), PrisonIsolation, PrisonExit, PrisonTunnelExit,
--   PrisonActivity (+Activity, +Label), PrisonVisit, Pickup_Funcionario, Dropoff_Funcionario, JobBoard.
-- Sin math.random: se construye al final sin cambiar nada más del mapa.

local Builder = require(script.Parent.Parent.Builder)
local Building = require(script.Parent.Building)
local Blocks = require(script.Parent.Blocks)
local Props = require(script.Parent.Props)

local Prison = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local FT = Building.FLOOR_TOP

Prison.Rect = { X0 = 2560, X1 = 3340, Z0 = 40, Z1 = 300 }
Prison.StopName = "Centro Penitenciario"

local WALL = rgb(190, 184, 172)
local DARK = rgb(44, 46, 52)
local STEEL = rgb(150, 156, 164)
local WOOD = rgb(140, 100, 68)
local LIGHT = rgb(236, 238, 242)
local ORANGE = rgb(230, 120, 40)

local model: Model
local center: CFrame -- centro del recinto; -Z local = hacia la carretera (la entrada)

local function at(x: number, y: number, z: number): CFrame
	return center * CFrame.new(x, y, z)
end

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

local function spot(name: string, cf: CFrame, tags: { string }, attributes: { [string]: any }?): BasePart
	return Builder.part({ Name = name, Size = V(2, 2, 2), CFrame = cf, Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Tags = tags, Attributes = attributes, Parent = model })
end

local function sign(text: string, size: Vector3, cf: CFrame, color: Color3?)
	local p = bit("Sign", size, cf, color or DARK)
	Builder.sign(p, text, Enum.NormalId.Front)
end

-- Actividad (PrisonService pone el cartel de interacción)
local function activity(kind: string, label: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): BasePart
	return solid("Activity_" .. kind, size, cf, color, material, { Tags = { "PrisonActivity" }, Attributes = { Activity = kind, Label = label } })
end

local function seatAt(cf: CFrame, color: Color3?)
	local s = Instance.new("Seat")
	s.Anchored = true
	s.Size = V(2, 1, 2)
	s.CFrame = cf * CFrame.new(0, 1.5, 0)
	s.Color = color or STEEL
	s.Material = Enum.Material.Metal
	s.TopSurface = Enum.SurfaceType.Smooth
	s.Parent = model
end

local function lamp(cf: CFrame)
	local p = bit("Lamp", V(4, 0.3, 4), cf, rgb(255, 250, 230), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Range = 30
	light.Brightness = 1.2
	light.Shadows = false
	light.Parent = p
end

-- Pabellón abierto por delante (se entra andando): paredes, techo, luz y cartel
local function hall(title: string, x: number, z: number, W: number, D: number, color: Color3?, facing: number?): (number, number, number) -> CFrame
	local base = at(x, 0, z) * CFrame.Angles(0, facing or 0, 0)
	local function h(px: number, py: number, pz: number): CFrame
		return base * CFrame.new(px, py, pz)
	end
	local H = 13
	local c = color or rgb(214, 208, 196)
	solid("HallFloor", V(W, 0.4, D), h(0, 0.7, 0), rgb(200, 198, 190), Enum.Material.Concrete)
	solid("HallWall", V(W, H, 1), h(0, H / 2, D / 2), c, Enum.Material.Concrete)
	solid("HallWall", V(1, H, D), h(-W / 2, H / 2, 0), c, Enum.Material.Concrete)
	solid("HallWall", V(1, H, D), h(W / 2, H / 2, 0), c, Enum.Material.Concrete)
	local gap = W * 0.5
	solid("HallFront", V((W - gap) / 2, H, 1), h(-(gap / 2 + (W - gap) / 4), H / 2, -D / 2), c, Enum.Material.Concrete)
	solid("HallFront", V((W - gap) / 2, H, 1), h(gap / 2 + (W - gap) / 4, H / 2, -D / 2), c, Enum.Material.Concrete)
	solid("HallRoof", V(W + 2, 1, D + 2), h(0, H + 0.5, 0), rgb(120, 116, 110), Enum.Material.Concrete)
	sign(title, V(math.min(W - 4, 24), 2.6, 0.3), h(0, H - 2, -D / 2 - 0.7))
	for k = -1, 1, 2 do
		lamp(h(k * W / 4, H - 0.3, 0))
	end
	return h
end

---------------------------------------------------------------------
-- Partes del recinto
---------------------------------------------------------------------
local W, D, H = 760, 224, 22

local function walls()
	solid("PrisonFloor", V(W, 1, D), at(0, 0, 0), rgb(160, 158, 150), Enum.Material.Concrete)
	local gate = 18
	solid("WallBack", V(W, H, 2), at(0, H / 2, D / 2), WALL, Enum.Material.Concrete)
	solid("WallLeft", V(2, H, D), at(-W / 2, H / 2, 0), WALL, Enum.Material.Concrete)
	solid("WallRight", V(2, H, D), at(W / 2, H / 2, 0), WALL, Enum.Material.Concrete)
	-- Fachada: puerta en el centro y hueco para la sala de visitas (x = 150..190)
	local segments = { { -W / 2, -gate / 2 }, { gate / 2, 150 }, { 190, W / 2 } }
	for _, s in segments do
		local len = s[2] - s[1]
		solid("WallFront", V(len, H, 2), at((s[1] + s[2]) / 2, H / 2, -D / 2), WALL, Enum.Material.Concrete)
	end
	bit("GateBeam", V(gate + 4, 3, 2.4), at(0, H - 1.5, -D / 2), DARK, Enum.Material.Metal)
	for x = -gate / 2 + 1, gate / 2 - 1, 2 do
		bit("GateBar", V(0.3, H - 4, 0.3), at(x, (H - 4) / 2 + 2, -D / 2 - 1.2), STEEL, Enum.Material.Metal)
	end
	sign("CENTRO PENITENCIARIO DE VALMAR", V(46, 3.6, 0.4), at(-60, H - 4, -D / 2 - 1.3), rgb(60, 70, 60))
	for _, piece in { { V(W, 1, 1), at(0, H + 0.6, D / 2) }, { V(1, 1, D), at(-W / 2, H + 0.6, 0) }, { V(1, 1, D), at(W / 2, H + 0.6, 0) }, { V(W, 1, 1), at(0, H + 0.6, -D / 2) } } do
		bit("Wire", piece[1], piece[2], rgb(120, 124, 130), Enum.Material.DiamondPlate)
	end
	-- Torres de vigilancia (esquinas y mitad de los lados largos)
	for _, p in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 }, { 0, 1 }, { -0.5, -1 }, { 0.5, -1 } } do
		local base = at(p[1] * (W / 2 - 6), 0, p[2] * (D / 2 - 6))
		solid("TowerLeg", V(4, H + 8, 4), base * CFrame.new(0, (H + 8) / 2, 0), WALL, Enum.Material.Concrete)
		bit("TowerCabin", V(10, 5, 10), base * CFrame.new(0, H + 10, 0), rgb(80, 84, 90), Enum.Material.Metal)
		bit("TowerRoof", V(12, 0.6, 12), base * CFrame.new(0, H + 12.8, 0), DARK)
		local light = Instance.new("SpotLight")
		light.Face = Enum.NormalId.Bottom
		light.Range = 60
		light.Angle = 70
		light.Brightness = 3
		light.Parent = bit("Searchlight", V(1.4, 1, 1.4), base * CFrame.new(0, H + 7.2, 0), rgb(255, 250, 220), Enum.Material.Neon)
		spot("TowerPost", base * CFrame.new(-math.sign(p[1] ~= 0 and p[1] or 1) * 7, 3, -p[2] * 7), { "Dropoff_Funcionario" })
	end
	spot("PrisonArea", at(0, 12, 0), { "PrisonArea" }).Size = V(W - 2, 44, D - 2)
	spot("PrisonExit", at(0, 3, -D / 2 - 14) * CFrame.Angles(0, math.pi, 0), { "PrisonExit" })
	-- Salida del túnel (fuga): fuera, detrás del muro del fondo
	spot("TunnelExit", at(-W / 4, 3, D / 2 + 14), { "PrisonTunnelExit" })
	bit("TunnelHole", V(4, 0.2, 4), at(-W / 4, 0.6, D / 2 + 14), rgb(60, 45, 30), Enum.Material.Ground)
end

local function cellBlock(title: string, x0: number, x1: number, first: number): number
	local n = 0
	local cellW, cellD = 15, 14
	local z = D / 2 - 1 - cellD / 2
	sign(title, V(20, 2.6, 0.3), at((x0 + x1) / 2, 17, z - cellD / 2 - 6), rgb(60, 70, 60))
	solid("BlockRoof", V(x1 - x0 + 2, 1, cellD + 10), at((x0 + x1) / 2, 14.5, z - 3), rgb(150, 146, 138), Enum.Material.Concrete)
	for x = x0 + cellW / 2, x1 - cellW / 2 + 0.1, cellW do
		n += 1
		local number = first + n - 1
		local cell = at(x, 0, z)
		solid("CellWall", V(0.8, 14, cellD), cell * CFrame.new(-cellW / 2, 7, 0), WALL, Enum.Material.Concrete)
		solid("CellWall", V(0.8, 14, cellD), cell * CFrame.new(cellW / 2, 7, 0), WALL, Enum.Material.Concrete)
		for k = -6, 6 do
			if math.abs(k) > 1 then
				bit("Bar", V(0.25, 12, 0.25), cell * CFrame.new(k, 6, -cellD / 2), STEEL, Enum.Material.Metal)
			end
		end
		local bed = activity("Dormir", "🛏 Litera", V(3, 1.4, 7), cell * CFrame.new(-cellW / 2 + 2.4, 0.9, 1.5), rgb(200, 200, 205), Enum.Material.Fabric)
		bed:SetAttribute("Cell", number)
		bit("TopBunk", V(3, 0.6, 7), cell * CFrame.new(-cellW / 2 + 2.4, 5, 1.5), rgb(190, 190, 196), Enum.Material.Fabric)
		bit("Toilet", V(1.6, 1.6, 1.6), cell * CFrame.new(cellW / 2 - 1.6, 0.8, cellD / 2 - 1.6), LIGHT)
		bit("Sink", V(1.8, 1.2, 1), cell * CFrame.new(cellW / 2 - 1.4, 3, cellD / 2 - 4), LIGHT)
		-- Rincón donde se puede cavar (fuga)
		local corner = activity("Cavar", "🕳 Suelo suelto", V(3, 0.3, 3), cell * CFrame.new(cellW / 2 - 2.2, 0.66, -cellD / 2 + 3), rgb(120, 110, 96), Enum.Material.Concrete)
		corner:SetAttribute("Cell", number)
		sign("CELDA " .. number, V(3.6, 1.2, 0.2), cell * CFrame.new(0, 12.6, -cellD / 2 - 0.3))
		spot("CellSpot", cell * CFrame.new(0, 3, 1), { "PrisonCell" }, { Cell = number })
		if n % 3 == 1 then
			spot("CellCheck", cell * CFrame.new(0, 3, -cellD / 2 - 3), { "Dropoff_Funcionario" })
		end
	end
	return n
end

local function isolation()
	local x0, x1 = -45, 45
	local z = D / 2 - 8
	solid("IsoBlock", V(x1 - x0, 1, 14), at(0, 12.5, z), rgb(90, 90, 96), Enum.Material.Concrete)
	sign("AISLAMIENTO", V(16, 2.4, 0.3), at(0, 14.5, z - 7.6), rgb(120, 30, 30))
	for i = 0, 3 do
		local x = x0 + 11.25 + i * 22.5
		local cell = at(x, 0, z)
		solid("IsoWall", V(0.8, 12, 14), cell * CFrame.new(-11, 6, 0), rgb(110, 110, 116), Enum.Material.Concrete)
		solid("IsoWall", V(0.8, 12, 14), cell * CFrame.new(11, 6, 0), rgb(110, 110, 116), Enum.Material.Concrete)
		solid("IsoDoor", V(22, 12, 0.6), cell * CFrame.new(0, 6, -7), rgb(80, 80, 86), Enum.Material.Metal)
		bit("IsoWindow", V(2, 1, 0.7), cell * CFrame.new(0, 8, -7), rgb(160, 200, 230), Enum.Material.Glass, 0.3)
		spot("IsoSpot", cell * CFrame.new(0, 3, 1), { "PrisonIsolation" })
	end
end

local function yard()
	-- Campo de fútbol
	local fx, fz = -250, -10
	bit("Pitch", V(190, 0.2, 96), at(fx, 0.62, fz), rgb(80, 140, 70), Enum.Material.Grass)
	bit("PitchLine", V(0.4, 0.22, 96), at(fx, 0.64, fz), LIGHT)
	for _, side in { -1, 1 } do
		bit("GoalPost", V(0.5, 8, 0.5), at(fx + side * 93, 4, fz - 10), LIGHT, Enum.Material.Metal)
		bit("GoalPost", V(0.5, 8, 0.5), at(fx + side * 93, 4, fz + 10), LIGHT, Enum.Material.Metal)
		bit("GoalBar", V(0.5, 0.5, 20), at(fx + side * 93, 8, fz), LIGHT, Enum.Material.Metal)
		bit("GoalNet", V(4, 7.5, 20), at(fx + side * 95, 3.8, fz), LIGHT, Enum.Material.ForceField, 0.5)
	end
	activity("Futbol", "⚽ Partido de fútbol", V(3, 3, 3), at(fx, 1.5, fz - 44), rgb(240, 240, 240), Enum.Material.SmoothPlastic).Shape = Enum.PartType.Ball
	-- Baloncesto
	local bx, bz = -80, -20
	bit("Court", V(56, 0.2, 34), at(bx, 0.62, bz), rgb(170, 90, 60), Enum.Material.Concrete)
	for _, side in { -1, 1 } do
		bit("HoopPost", V(0.6, 10, 0.6), at(bx + side * 27, 5, bz), STEEL, Enum.Material.Metal)
		bit("Backboard", V(0.3, 3.5, 6), at(bx + side * 26.4, 10, bz), LIGHT)
		bit("Rim", V(2.4, 0.2, 2.4), at(bx + side * 25, 9, bz), rgb(230, 80, 30), Enum.Material.Metal)
	end
	activity("Canasta", "🏀 Tirar a canasta", V(2, 2, 2), at(bx + 18, 1, bz), ORANGE, Enum.Material.SmoothPlastic).Shape = Enum.PartType.Ball
	-- Pesas al aire libre
	local wx, wz = -12, -30
	for k = 0, 2 do
		bit("WeightBench", V(2, 1.6, 6), at(wx + k * 7, 0.8, wz), DARK, Enum.Material.Metal)
		bit("Barbell", V(7, 0.4, 0.4), at(wx + k * 7, 3.6, wz - 1), STEEL, Enum.Material.Metal)
	end
	bit("PullUpBar", V(10, 0.4, 0.4), at(wx + 7, 9, wz + 6), STEEL, Enum.Material.Metal)
	activity("Pesas", "🏋 Pesas del patio", V(3, 1.4, 3), at(wx + 7, 0.7, wz + 4), DARK, Enum.Material.Metal)
	-- Bancos y papeleras por el patio
	for k = 0, 5 do
		bit("YardBench", V(8, 0.5, 2), at(-150 + k * 30, 1.8, -D / 2 + 20), STEEL, Enum.Material.Metal)
	end
	for k = 0, 3 do
		activity("Limpiar", "🧹 Limpiar el patio", V(1.6, 3, 1.6), at(-140 + k * 70, 1.5, 38), rgb(60, 110, 60), Enum.Material.Metal)
	end
end

local function services()
	-- Fila delantera derecha: comedor, biblioteca, gimnasio, enfermería/economato
	local z1 = -D / 2 + 32
	local h = hall("COMEDOR", 170, z1, 60, 40)
	for row = 0, 2 do
		for k = -1, 1 do
			bit("Table", V(10, 0.4, 3.4), h(k * 16, 3, -6 + row * 9), STEEL, Enum.Material.Metal)
			for side = -1, 1, 2 do
				seatAt(h(k * 16, 0, -6 + row * 9 + side * 2.6) * CFrame.Angles(0, if side > 0 then 0 else math.pi, 0))
			end
		end
	end
	activity("Comer", "🍲 Bandeja de comida", V(18, 3.6, 2.4), h(0, 1.8, 16), LIGHT, Enum.Material.Metal)
	h = hall("BIBLIOTECA", 240, z1, 48, 40, rgb(214, 200, 176))
	for k = 0, 3 do
		bit("Bookshelf", V(10, 8, 2), h(-15 + k * 10, 4, 17), WOOD, Enum.Material.Wood)
		for row = 0, 2 do
			bit("Books", V(9, 1.6, 1.4), h(-15 + k * 10, 1.6 + row * 2.4, 16.6), ({ rgb(170, 60, 50), rgb(60, 90, 150), rgb(60, 130, 80) })[row + 1])
		end
	end
	activity("Leer", "📖 Leer un libro", V(8, 3, 3), h(-8, 1.5, 2), WOOD, Enum.Material.Wood)
	activity("Estudiar", "🎓 Estudiar (graduado en prisión)", V(8, 3, 3), h(8, 1.5, 2), WOOD, Enum.Material.Wood)
	for k = -1, 1, 2 do
		seatAt(h(-8 + k * 2.4, 0, -1) * CFrame.Angles(0, math.pi, 0), WOOD)
		seatAt(h(8 + k * 2.4, 0, -1) * CFrame.Angles(0, math.pi, 0), WOOD)
	end
	h = hall("GIMNASIO", 305, z1, 48, 40, rgb(200, 206, 214))
	activity("Gimnasio", "🏋 Máquina de pesas", V(4, 5, 6), h(-12, 2.5, 6), DARK, Enum.Material.Metal)
	activity("Cinta", "🏃 Cinta de correr", V(3, 2, 7), h(0, 1, 6), DARK, Enum.Material.Metal)
	activity("Saco", "🥊 Saco de boxeo", V(2, 5, 2), h(12, 6, 6), rgb(150, 30, 30), Enum.Material.Fabric)
	bit("GymMat", V(40, 0.2, 14), h(0, 0.95, 8), rgb(60, 80, 140), Enum.Material.Fabric)
	h = hall("ENFERMERÍA · ECONOMATO", 360, z1, 36, 40, rgb(230, 234, 236))
	activity("Curarse", "🩺 Camilla de la enfermería", V(4, 2, 8), h(-9, 1, 8), LIGHT, Enum.Material.Fabric)
	bit("RedCross", V(3, 3, 0.2), h(-9, 9, 19.3), rgb(220, 40, 40))
	activity("Economato", "🛒 Economato", V(12, 3.6, 2.4), h(8, 1.8, 8), rgb(60, 110, 160), Enum.Material.Wood)
	-- Fila de en medio: talleres (de trabajo)
	local z2 = 26
	h = hall("LAVANDERÍA", 170, z2, 44, 34, rgb(220, 226, 232))
	for k = 0, 3 do
		bit("Washer", V(4, 5, 4), h(-15 + k * 10, 2.5, 13), LIGHT, Enum.Material.Metal)
	end
	activity("Lavanderia", "🧺 Doblar ropa", V(14, 3, 3), h(0, 1.5, 2), rgb(200, 210, 220), Enum.Material.Metal)
	h = hall("COCINA", 222, z2, 44, 34, rgb(226, 222, 214))
	bit("Oven", V(10, 5, 3), h(-10, 2.5, 13), STEEL, Enum.Material.Metal)
	bit("Pot", V(3, 3, 3), h(6, 5, 13), STEEL, Enum.Material.Metal)
	activity("Cocina", "🍳 Preparar la comida", V(14, 3.6, 3), h(0, 1.8, 2), STEEL, Enum.Material.Metal)
	h = hall("CARPINTERÍA", 274, z2, 44, 34, rgb(214, 200, 176))
	bit("Planks", V(10, 2, 3), h(-10, 1, 12), WOOD, Enum.Material.WoodPlanks)
	activity("Carpinteria", "🪚 Banco de carpintería", V(12, 3, 4), h(0, 1.5, 2), WOOD, Enum.Material.Wood)
	-- Huerto (al aire libre)
	for k = 0, 3 do
		bit("GardenBed", V(36, 1, 5), at(345, 0.9, z2 - 8 + k * 8), rgb(90, 60, 40), Enum.Material.Ground)
		bit("Plants", V(34, 1.4, 3), at(345, 2, z2 - 8 + k * 8), rgb(80, 140, 60), Enum.Material.Grass)
	end
	sign("HUERTO", V(10, 2, 0.3), at(345, 5, z2 - 14), rgb(70, 110, 50))
	activity("Huerto", "🌱 Cuidar el huerto", V(3, 2, 3), at(345, 1, z2 - 14), rgb(110, 80, 50), Enum.Material.Wood)
	-- Fila delantera izquierda: TV, capilla, teléfonos
	h = hall("SALA DE TV", -200, -D / 2 + 30, 48, 36, rgb(200, 196, 214))
	bit("TV", V(12, 7, 0.4), h(0, 7, 16.5), DARK)
	bit("TVScreen", V(11, 6, 0.1), h(0, 7, 16.2), rgb(80, 140, 210), Enum.Material.Neon)
	for row = 0, 2 do
		for k = -3, 3 do
			seatAt(h(k * 3.4, 0, -2 + row * 4) * CFrame.Angles(0, math.pi, 0), rgb(90, 90, 120))
		end
	end
	activity("TV", "📺 Ver la tele", V(3, 1, 3), h(-18, 0.5, 12), rgb(90, 90, 120), Enum.Material.Fabric)
	h = hall("CAPILLA", -260, -D / 2 + 30, 36, 36, rgb(226, 214, 190))
	bit("Altar", V(10, 4, 3), h(0, 2, 15), rgb(230, 220, 200), Enum.Material.Marble)
	for row = 0, 3 do
		bit("Pew", V(12, 1.6, 2), h(0, 1.6, -6 + row * 5), WOOD, Enum.Material.Wood)
	end
	activity("Reflexionar", "🕯 Reflexionar", V(3, 1, 3), h(0, 0.5, 11), rgb(240, 220, 150), Enum.Material.Neon)
	h = hall("TELÉFONOS", -320, -D / 2 + 30, 36, 36, rgb(200, 210, 214))
	for k = -1, 1 do
		bit("Booth", V(4, 8, 3), h(k * 8, 4, 15), rgb(40, 100, 160), Enum.Material.Metal)
	end
	activity("Telefono", "📞 Llamar a casa", V(4, 3, 2), h(0, 1.5, 12), rgb(40, 100, 160), Enum.Material.Metal)
	-- Oficina de funcionarios (dentro, junto a la puerta): llaves y parte del turno
	h = hall("FUNCIONARIOS", -60, -D / 2 + 22, 40, 26, rgb(170, 186, 200))
	local desk = solid("OfficeDesk", V(8, 3, 3), h(0, 1.5, 4), rgb(60, 70, 80), Enum.Material.Metal)
	desk:AddTag("Pickup_Funcionario")
	bit("Monitors", V(6, 3, 0.3), h(0, 4.5, 5), rgb(90, 160, 230), Enum.Material.Neon)
end

-- Sala de visitas: mitad fuera (visitantes) y mitad dentro (presos), separadas por un cristal
local function visits()
	local x = 170
	local len, depth = 40, 16
	-- Paredes laterales que cierran la sala por los dos lados del muro
	for _, dz in { -depth, depth } do
		solid("VisitWall", V(1, 12, depth * 2), at(x - len / 2, 6, dz / 2 - D / 2), WALL, Enum.Material.Concrete)
		solid("VisitWall", V(1, 12, depth * 2), at(x + len / 2, 6, dz / 2 - D / 2), WALL, Enum.Material.Concrete)
	end
	solid("VisitRoof", V(len + 2, 1, depth * 2 + 2), at(x, 12.5, -D / 2), rgb(150, 146, 138), Enum.Material.Concrete)
	solid("VisitGlass", V(len, 12, 0.4), at(x, 6, -D / 2), rgb(200, 225, 240), Enum.Material.Glass, { Transparency = 0.6 })
	for k = -3, 3 do
		bit("VisitCounter", V(4, 3, 3), at(x + k * 5, 1.5, -D / 2), rgb(90, 90, 96))
		seatAt(at(x + k * 5, 0, -D / 2 - 4))
		seatAt(at(x + k * 5, 0, -D / 2 + 4) * CFrame.Angles(0, math.pi, 0))
	end
	sign("SALA DE VISITAS", V(18, 2.4, 0.3), at(x, 14.5, -D / 2 - depth - 1.2), rgb(60, 70, 60))
	spot("VisitSide", at(x, 3, -D / 2 - 8), { "PrisonVisit" })
	lamp(at(x, 12, -D / 2 - 8))
	lamp(at(x, 12, -D / 2 + 8))
end

local function outside(lot: any)
	-- Explanada, garita y tablón de los funcionarios, parada de autobús
	local r = Prison.Rect
	Builder.part({
		Name = "Explanada",
		Size = V(r.X1 - r.X0, 1, r.Z1 - r.Z0),
		CFrame = CFrame.new((r.X0 + r.X1) / 2, -0.5, (r.Z0 + r.Z1) / 2),
		Color = rgb(196, 192, 184),
		Material = Enum.Material.Pavement,
		CastShadow = false,
		Parent = model,
	})
	local booth = at(20, 0, -D / 2 - 12)
	solid("Garita", V(8, 9, 7), booth * CFrame.new(0, 4.5, 0), rgb(80, 90, 80), Enum.Material.Concrete)
	Props.jobBoard(model, lot.facing(-40, 12, FT), "Funcionario", "PRISIONES")
	local Region = require(script.Parent.Parent.Region)
	Region.travelStop(model, lot.facing(-120, 8, 0), Prison.StopName)
end

function Prison.clear(world: Instance)
	local r = Prison.Rect
	local margin = 10
	for _, folderName in { "Naturaleza", "Campo" } do
		local folder = world:FindFirstChild(folderName)
		for _, d in (if folder then folder:GetDescendants() else {}) do
			-- (lo que ya se ha borrado con su modelo se salta; con Lune, mirar su Parent da error)
			local alive = pcall(function()
				return d.Parent
			end)
			if alive and d:IsA("BasePart") and d.Parent then
				local p = d.CFrame.Position -- (CFrame: así también funciona al construir el archivo con Lune)
				if p.X > r.X0 - margin and p.X < r.X1 + margin and p.Z > r.Z0 - margin and p.Z < r.Z1 + margin then
					local m = d:FindFirstAncestorOfClass("Model")
					if m and m ~= folder and m.Parent == folder then
						m:Destroy()
					else
						d:Destroy()
					end
				end
			end
		end
	end
end

function Prison.build(world: Instance)
	Prison.clear(world)
	model = Builder.model("CentroPenitenciario", world)
	local lot = Blocks.lot(Prison.Rect, "N")
	center = lot.facing(0, 30 + D / 2, 0)
	outside(lot)
	walls()
	local a = cellBlock("MÓDULO A", -W / 2 + 12, -60, 1)
	cellBlock("MÓDULO B", 60, W / 2 - 12, a + 1)
	isolation()
	yard()
	services()
	visits()
	return model
end

return Prison
