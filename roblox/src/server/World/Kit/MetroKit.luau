-- MetroKit: el metro subterráneo de Valmar (datos en Shared/Metro.luau; lo mueve MetroService).
--
--   * Boca de metro en la calle (modelo "BocaMetro", sale en el mapa): pabellón de cristal con la
--     gran M. Puerta: tag MetroEntrance (atributo Station).
--   * Estación subterránea por línea: andén recto (el tren para en medio), vía, túneles,
--     vestíbulo con máquinas de billetes (MetroTicketMachine), tornos (MetroGate / MetroGateExit),
--     quiosco (MetroShop + MetroDelivery), máquina expendedora, escalera a la calle (MetroExit)
--     y punto de llegada (MetroArrival). Botones de subir al tren en el borde del andén (MetroBoard).
--   * Plaza Mayor (Hub): galería comercial subterránea con tiendas (MetroShop), fotomatón
--     (MetroPhoto), escenario para músicos (MetroStage), tablón de encargos (MetroMissionBoard),
--     Objetos Perdidos (MetroLostOffice), tablón de revisor y transbordo a la Línea 2 (MetroTransfer).
--   * Detalles (MetroDetails): aseos, guardias, ratas, taquillas, puestos, fuente, piano, anuncios…
--   * Trenes: 3 coches por línea (tag MetroTrain), cada coche soldado a su Root para moverlo entero.
--
-- Marco de cada estación: X a la derecha del sentido de la línea (el andén está en +X), Z a lo largo
-- de la vía (-Z = hacia la siguiente estación), Y = 0 en el suelo del andén.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Builder = require(script.Parent.Parent.Builder)
local MetroDetails = require(script.Parent.MetroDetails)
local Metro = require(ReplicatedStorage.Shared.Metro)

local MetroKit = {}

local rgb = Color3.fromRGB
local TILE = rgb(236, 232, 222)
local DARK = rgb(34, 36, 42)
local CONCRETE = rgb(120, 118, 114)
local STEEL = rgb(170, 174, 180)
local YELLOW = rgb(245, 200, 30)
local WOOD = rgb(140, 100, 64)

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
	local props = { Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = parent }
	for k, v in extra or {} do
		props[k] = v
	end
	return Builder.part(props)
end

local function decor(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
	local props = { Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = parent }
	for k, v in extra or {} do
		props[k] = v
	end
	return Builder.decor(props)
end

-- Luz de techo: plafón de neón que ilumina hacia abajo
local function ceilingLight(parent: Instance, cf: CFrame, size: Vector3, range: number?)
	local lamp = decor(parent, "CeilingLamp", size, cf, rgb(250, 250, 255), Enum.Material.Neon)
	local light = Instance.new("SurfaceLight")
	light.Face = Enum.NormalId.Bottom
	light.Angle = 110
	light.Range = range or 18
	light.Brightness = 1.4
	light.Color = rgb(255, 248, 235)
	light.Shadows = false
	light.Parent = lamp
end

local function marker(parent: Instance, name: string, cf: CFrame, tag: string, attrs: { [string]: any }, size: Vector3?): BasePart
	return Builder.part({
		Name = name,
		Size = size or Vector3.new(4, 5, 2),
		CFrame = cf,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CastShadow = false,
		Tags = { tag },
		Attributes = attrs,
		Parent = parent,
	})
end

local function signBoard(parent: Instance, cf: CFrame, size: Vector3, text: string, color: Color3, both: boolean?): BasePart
	local board = decor(parent, "Sign", size, cf, color)
	Builder.sign(board, text, Enum.NormalId.Front)
	if both then
		Builder.sign(board, text, Enum.NormalId.Back)
	end
	return board
end

---------------------------------------------------------------------
-- Boca de metro en la calle
---------------------------------------------------------------------
function MetroKit.entrance(parent: Instance, station: Metro.Station)
	local m = Builder.model("BocaMetro", parent)
	m:SetAttribute("PlaceName", "Metro · " .. station.Name)
	local pos = Vector3.new(station.Surface[1], 0, station.Surface[2])
	local cf = Builder.facing(pos, Vector3.new(station.Facing[1], 0, station.Facing[2])) -- la puerta mira a la calle (-Z)
	local function at(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x, y, z)
	end
	local W, D, H = 9, 7, 7
	part(m, "Floor", Vector3.new(W, 0.6, D), at(0, 0.3, 0), rgb(90, 92, 98), Enum.Material.Granite)
	-- Paredes de cristal (laterales y fondo) y marco metálico
	for _, x in { -W / 2 + 0.15, W / 2 - 0.15 } do
		part(m, "Glass", Vector3.new(0.3, H - 1, D - 0.6), at(x, H / 2, 0), rgb(170, 210, 230), Enum.Material.Glass, { Transparency = 0.55 })
	end
	part(m, "GlassBack", Vector3.new(W, H - 1, 0.3), at(0, H / 2, D / 2 - 0.15), rgb(170, 210, 230), Enum.Material.Glass, { Transparency = 0.55 })
	for _, x in { -W / 2, W / 2 } do
		for _, z in { -D / 2, D / 2 } do
			part(m, "Frame", Vector3.new(0.4, H, 0.4), at(x, H / 2, z), DARK, Enum.Material.Metal)
		end
	end
	-- Tejadillo con franjas de las líneas
	part(m, "Roof", Vector3.new(W + 1.6, 0.5, D + 1.6), at(0, H + 0.25, 0), DARK, Enum.Material.Metal)
	local colors = {}
	for _, line in Metro.Lines do
		if table.find(line.Stations, station.Id) then
			table.insert(colors, line.Color)
		end
	end
	for i, color in colors do
		decor(m, "LineStripe", Vector3.new(W + 1.7, 0.35, 0.3), at(0, H - 0.1 - (i - 1) * 0.4, -D / 2 - 0.8), color, Enum.Material.Neon)
	end
	-- Escalera que baja (se ve el hueco oscuro) y barandillas
	for i = 0, 5 do
		decor(m, "Step", Vector3.new(W - 2, 0.4, 1), at(0, 0.4 - i * 0.6, D / 2 - 1.5 - i * 0.9), rgb(70, 72, 78), Enum.Material.Concrete)
	end
	decor(m, "Stairwell", Vector3.new(W - 2, 0.2, 5.5), at(0, -3, 0), rgb(10, 10, 12))
	for _, x in { -W / 2 + 1, W / 2 - 1 } do
		decor(m, "Handrail", Vector3.new(0.2, 0.2, D - 1), at(x, 2.6, 0), STEEL, Enum.Material.Metal)
	end
	-- Cartel sobre la puerta
	signBoard(m, at(0, H - 1.2, -D / 2 - 0.05), Vector3.new(W - 1, 1.3, 0.2), "METRO · " .. string.upper(station.Name), DARK)
	-- Tótem con la gran M
	local totemPos = at(-W / 2 - 1.6, 0, -D / 2 + 0.5)
	part(m, "TotemPole", Vector3.new(0.5, 8, 0.5), totemPos * CFrame.new(0, 4, 0), DARK, Enum.Material.Metal)
	local cube = part(m, "MetroSign", Vector3.new(2.4, 2.4, 2.4), totemPos * CFrame.new(0, 9.2, 0), rgb(200, 30, 40), Enum.Material.SmoothPlastic)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right } do
		Builder.sign(cube, "M", face, Color3.new(1, 1, 1), rgb(200, 30, 40))
	end
	local glow = Instance.new("PointLight")
	glow.Range = 14
	glow.Brightness = 1
	glow.Color = rgb(255, 120, 120)
	glow.Parent = cube
	-- Puerta (la usa MetroService: "Bajar al metro")
	marker(m, "MetroDoor", at(0, 2.5, -D / 2 + 1), "MetroEntrance", { Station = station.Id }, Vector3.new(5, 5, 2))
	return m
end

---------------------------------------------------------------------
-- Tren
---------------------------------------------------------------------
local function weldAll(model: Model, root: BasePart)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p ~= root then
			p.Anchored = false
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = p
			weld.Parent = p
		end
	end
end

local function car(parent: Instance, cf: CFrame, line: Metro.Line, index: number, count: number): Model
	local m = Builder.model("Car" .. index, parent)
	local L, W, H = Metro.CarLength, 9, 10
	local function at(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x, y, z)
	end
	local WHITE = rgb(235, 238, 242)
	local root = part(m, "Root", Vector3.new(W, 0.6, L), at(0, -0.3, 0), rgb(120, 124, 130), Enum.Material.DiamondPlate)
	m.PrimaryPart = root
	decor(m, "Bogie", Vector3.new(W - 2, 1.2, 6), at(0, -1.2, L / 2 - 6), DARK, Enum.Material.Metal)
	decor(m, "Bogie", Vector3.new(W - 2, 1.2, 6), at(0, -1.2, -L / 2 + 6), DARK, Enum.Material.Metal)
	-- Laterales: zócalo, ventanas y parte alta, con huecos para 2 puertas por lado
	local doorsZ = { -L / 4, L / 4 }
	for _, side in { -1, 1 } do
		local x = side * (W / 2 - 0.15)
		local z0 = -L / 2
		for _, dz in doorsZ do
			local len = (dz - 2.2) - z0
			if len > 0 then
				local zc = z0 + len / 2
				part(m, "Side", Vector3.new(0.3, 3.4, len), at(x, 1.7, zc), WHITE)
				decor(m, "Window", Vector3.new(0.25, 3.2, len - 0.6), at(x, 5.1, zc), rgb(40, 60, 80), Enum.Material.Glass, { Transparency = 0.35 })
				part(m, "Upper", Vector3.new(0.3, 2.6, len), at(x, 8, zc), WHITE)
			end
			z0 = dz + 2.2
		end
		local len = L / 2 - z0
		local zc = z0 + len / 2
		part(m, "Side", Vector3.new(0.3, 3.4, len), at(x, 1.7, zc), WHITE)
		decor(m, "Window", Vector3.new(0.25, 3.2, len - 0.6), at(x, 5.1, zc), rgb(40, 60, 80), Enum.Material.Glass, { Transparency = 0.35 })
		part(m, "Upper", Vector3.new(0.3, 2.6, len), at(x, 8, zc), WHITE)
		decor(m, "Stripe", Vector3.new(0.35, 0.7, L), at(x, 3.6, 0), line.Color, Enum.Material.SmoothPlastic)
		-- Puertas (MetroService las abre y las cierra)
		for _, dz in doorsZ do
			part(m, "Door", Vector3.new(0.25, 7.2, 4.4), at(x, 3.6, dz), rgb(210, 214, 220), Enum.Material.Metal, { Tags = { "MetroDoor" } })
			decor(m, "DoorLight", Vector3.new(0.3, 0.3, 0.6), at(x + side * 0.1, 7.6, dz - 2.6), rgb(255, 180, 40), Enum.Material.Neon)
		end
	end
	part(m, "Roof", Vector3.new(W, 0.5, L), at(0, H - 0.25, 0), WHITE)
	for _, z in { -L / 2 + 0.15, L / 2 - 0.15 } do
		part(m, "End", Vector3.new(W, H, 0.3), at(0, H / 2, z), WHITE)
	end
	-- Cabina en los extremos del tren: frente oscuro con parabrisas y faros
	if index == 1 or index == count then
		local zEnd = if index == 1 then -L / 2 - 0.25 else L / 2 + 0.25
		decor(m, "Windshield", Vector3.new(W - 1.6, 3, 0.2), at(0, 6, zEnd), rgb(30, 40, 55), Enum.Material.Glass)
		decor(m, "Nose", Vector3.new(W, 2.4, 0.3), at(0, 1.4, zEnd), line.Color)
		for _, x in { -3, 3 } do
			local lamp = decor(m, "Headlight", Vector3.new(0.9, 0.6, 0.2), at(x, 2.6, zEnd + (if index == 1 then -0.1 else 0.1)), rgb(255, 250, 220), Enum.Material.Neon)
			local _ = lamp
		end
		signBoard(m, at(0, 8.6, zEnd), Vector3.new(4, 0.9, 0.15), line.Id, DARK)
	end
	-- Interior: asientos de cara al pasillo, barras y luz
	for _, side in { -1, 1 } do
		for _, z in { -L / 2 + 3.5, -2.5, 2.5, L / 2 - 3.5 } do
			local seat = Instance.new("Seat")
			seat.Name = "Seat"
			seat.Size = Vector3.new(1.8, 0.6, 3.2)
			seat.CFrame = at(side * (W / 2 - 1.3), 1.5, z) * CFrame.Angles(0, if side > 0 then math.rad(90) else math.rad(-90), 0)
			seat.Color = line.Color
			seat.Material = Enum.Material.Fabric
			seat.Anchored = true
			seat:AddTag("MetroSeat")
			seat.Parent = m
			decor(m, "SeatBack", Vector3.new(0.4, 2.2, 3.2), at(side * (W / 2 - 0.5), 2.6, z), line.Color:Lerp(DARK, 0.3), Enum.Material.Fabric)
		end
	end
	for _, z in { -L / 4, L / 4 } do
		decor(m, "Pole", Vector3.new(0.25, H - 0.6, 0.25), at(0, (H - 0.6) / 2, z), STEEL, Enum.Material.Metal)
	end
	decor(m, "Handrail", Vector3.new(0.15, 0.15, L - 2), at(-1.4, H - 1.6, 0), STEEL, Enum.Material.Metal)
	decor(m, "Handrail", Vector3.new(0.15, 0.15, L - 2), at(1.4, H - 1.6, 0), STEEL, Enum.Material.Metal)
	local strip = decor(m, "LightStrip", Vector3.new(1.2, 0.15, L - 4), at(0, H - 0.6, 0), rgb(250, 252, 255), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Range = 16
	light.Brightness = 1.2
	light.Parent = strip
	for _, side in { -1, 1 } do
		signBoard(m, at(side * (W / 2 - 0.35), 8.2, 0) * CFrame.Angles(0, if side > 0 then math.rad(90) else math.rad(-90), 0), Vector3.new(10, 0.8, 0.1), line.Name .. " · " .. table.concat((function()
			local names = {}
			for _, id in line.Stations do
				table.insert(names, Metro.Stations[id].Name)
			end
			return names
		end)(), " – "), line.Color)
	end
	weldAll(m, root)
	return m
end

function MetroKit.train(parent: Instance, line: Metro.Line): Model
	local m = Instance.new("Model")
	m.Name = "Metro_" .. line.Id
	m:SetAttribute("Line", line.Id)
	m:AddTag("MetroTrain")
	m.Parent = parent
	local points, centers = Metro.path(line)
	local step = Metro.CarLength + Metro.CarGap
	for k = 1, Metro.Cars do
		local offset = (k - (Metro.Cars + 1) / 2) * step
		local p, t = Metro.sample(points, centers[1] - offset)
		car(m, Builder.facing(p, t), line, k, Metro.Cars)
	end
	return m
end

---------------------------------------------------------------------
-- Túnel entre dos puntos (a la altura de la vía)
---------------------------------------------------------------------
local function tunnel(parent: Instance, a: Vector3, b: Vector3, color: Color3)
	local len = (b - a).Magnitude
	if len < 1 then
		return
	end
	local cf0 = Builder.facing(a, b - a) -- (no CFrame.lookAt: en Lune sale mal hacia +Z)
	local pieces = math.ceil(len / 150)
	local piece = len / pieces
	for i = 0, pieces - 1 do
		local c = cf0 * CFrame.new(0, 0, -(i + 0.5) * piece)
		part(parent, "TunnelFloor", Vector3.new(12, 1, piece + 0.2), c * CFrame.new(0, -1.5, 0), rgb(70, 66, 60), Enum.Material.Concrete)
		for _, x in { -6.5, 6.5 } do
			part(parent, "TunnelWall", Vector3.new(1, 14, piece + 0.2), c * CFrame.new(x, 5, 0), CONCRETE, Enum.Material.Concrete)
			decor(parent, "Cable", Vector3.new(0.3, 0.3, piece), c * CFrame.new(x * 0.9, 8, 0), DARK)
		end
		part(parent, "TunnelRoof", Vector3.new(14, 1, piece + 0.2), c * CFrame.new(0, 12.5, 0), CONCRETE, Enum.Material.Concrete)
		for _, x in { -1.4, 1.4 } do
			decor(parent, "Rail", Vector3.new(0.3, 0.4, piece), c * CFrame.new(x, -0.8, 0), STEEL, Enum.Material.Metal)
		end
		decor(parent, "LineMark", Vector3.new(0.2, 0.4, piece), c * CFrame.new(-5.9, 6, 0), color, Enum.Material.Neon)
	end
	-- Luces del túnel
	for d = 40, len - 20, 90 do
		local lamp = decor(parent, "TunnelLamp", Vector3.new(0.8, 0.5, 1.4), cf0 * CFrame.new(5.8, 9, -d), rgb(255, 230, 180), Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Range = 28
		light.Brightness = 0.9
		light.Color = rgb(255, 214, 160)
		light.Parent = lamp
	end
end

---------------------------------------------------------------------
-- Estación subterránea
---------------------------------------------------------------------
local function station(parent: Instance, line: Metro.Line, index: number): (Model, CFrame)
	local id = line.Stations[index]
	local st = Metro.Stations[id]
	local m = Builder.model("Estacion_" .. line.Id .. "_" .. id, parent)
	m:SetAttribute("Station", id)
	m:SetAttribute("Line", line.Id)
	local c = Metro.center(id, line)
	local d = Metro.direction(line, index)
	local cf = Builder.facing(c, d)
	local function at(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x, y, z)
	end
	local P = Metro.PlatformLength / 2
	-- Vía (foso) y andén
	part(m, "TrackBed", Vector3.new(11, 1, P * 2), at(0, -1.5, 0), rgb(60, 56, 52), Enum.Material.Concrete)
	for _, x in { -1.4, 1.4 } do
		decor(m, "Rail", Vector3.new(0.3, 0.4, P * 2), at(x, -0.8, 0), STEEL, Enum.Material.Metal)
	end
	for z = -P + 2, P - 2, 3 do
		decor(m, "Sleeper", Vector3.new(4.4, 0.25, 0.8), at(0, -0.95, z), WOOD, Enum.Material.Wood)
	end
	part(m, "Platform", Vector3.new(12, 2, P * 2), at(11, -1, 0), rgb(150, 148, 144), Enum.Material.Granite)
	decor(m, "SafetyLine", Vector3.new(0.8, 0.05, P * 2), at(5.6, 0.02, 0), YELLOW, Enum.Material.SmoothPlastic)
	-- Pared del otro lado de la vía, con el nombre de la estación
	part(m, "FarWall", Vector3.new(1, 18, P * 2), at(-6, 7, 0), TILE, Enum.Material.Marble)
	decor(m, "FarWallBand", Vector3.new(0.2, 1.4, P * 2), at(-5.45, 8.5, 0), line.Color)
	for z = -P + 20, P - 20, 32 do
		local board = decor(m, "StationName", Vector3.new(0.2, 2.2, 12), at(-5.4, 5.6, z) * CFrame.Angles(0, math.rad(90), 0), DARK)
		local _ = board
		signBoard(m, at(-5.35, 5.6, z) * CFrame.Angles(0, math.rad(-90), 0), Vector3.new(12, 2.2, 0.1), string.upper(st.Name), line.Color)
		decor(m, "AdPanel", Vector3.new(0.2, 4, 7), at(-5.45, 5.4, z + 14), rgb(math.random(60, 220), math.random(60, 220), math.random(60, 220)), Enum.Material.Neon, { Transparency = 0.1 })
	end
	-- Techo y luces
	part(m, "Ceiling", Vector3.new(24, 1, P * 2), at(5.5, 16.5, 0), rgb(200, 198, 192), Enum.Material.Concrete)
	for z = -P + 12, P - 12, 22 do
		ceilingLight(m, at(10, 15.9, z), Vector3.new(1.2, 0.2, 8), 20)
		ceilingLight(m, at(0, 15.9, z + 11), Vector3.new(1.2, 0.2, 6), 18)
	end
	-- Pared trasera del andén (con el hueco de los tornos en medio)
	local LZ = 25 -- medio ancho del vestíbulo
	for _, zs in { { -P, -LZ }, { LZ, P } } do
		local len = zs[2] - zs[1]
		part(m, "PlatformWall", Vector3.new(1, 18, len), at(17.5, 7, (zs[1] + zs[2]) / 2), TILE, Enum.Material.Marble)
		decor(m, "WallBand", Vector3.new(0.2, 1, len), at(16.95, 8.5, (zs[1] + zs[2]) / 2), line.Color)
	end
	-- Cierres del andén en los extremos (hasta la boca del túnel)
	for _, z in { -P, P } do
		part(m, "PlatformEnd", Vector3.new(12, 18, 1), at(11, 7, z), TILE, Enum.Material.Marble)
		part(m, "TunnelHeader", Vector3.new(13, 4.5, 1), at(-0.5, 14.5, z), TILE, Enum.Material.Marble) -- cierra encima de la boca del túnel
		decor(m, "TunnelMouth", Vector3.new(11, 1.2, 0.3), at(0, 12, z - math.sign(z) * 0.6), DARK)
	end
	-- Bancos, papeleras, reloj y plano de la red en el andén
	for _, z in { -52, -30, 30, 52 } do
		part(m, "Bench", Vector3.new(1.6, 0.4, 5), at(15.6, 1.5, z), WOOD, Enum.Material.Wood)
		decor(m, "BenchLeg", Vector3.new(1.4, 1.3, 0.3), at(15.6, 0.65, z - 2), DARK)
		decor(m, "BenchLeg", Vector3.new(1.4, 1.3, 0.3), at(15.6, 0.65, z + 2), DARK)
		decor(m, "Bin", Vector3.new(1, 1.6, 1), at(16.3, 0.8, z + 4), DARK, Enum.Material.Metal)
	end
	signBoard(m, at(16.9, 6, -40) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(12, 6, 0.2), "PLANO DEL METRO\nL1 🔴 Poniente · Plaza Mayor · Levante · Playa Dorada\nL2 🔵 Norte · Plaza Mayor · San Roque · Puerto", DARK)
	local clock = decor(m, "Clock", Vector3.new(0.3, 1.6, 5), at(10, 13.6, 0), DARK)
	Builder.sign(clock, "PRÓXIMO TREN", Enum.NormalId.Right, YELLOW, DARK)
	Builder.sign(clock, "PRÓXIMO TREN", Enum.NormalId.Left, YELLOW, DARK)
	clock:AddTag("MetroDisplay")
	clock:SetAttribute("Line", line.Id)
	clock:SetAttribute("Station", id)
	-- Máquina expendedora en el andén
	local vending = part(m, "Vending", Vector3.new(2.4, 6, 3), at(15.8, 3, 40), rgb(200, 40, 50), Enum.Material.SmoothPlastic, { Tags = { "MetroShop" } })
	vending:SetAttribute("ShopId", "Maquina")
	decor(m, "VendingGlass", Vector3.new(0.1, 3.6, 2.2), at(14.55, 3.6, 40), rgb(200, 230, 240), Enum.Material.Glass, { Transparency = 0.4 })
	-- Subir al tren (uno por coche) y bajar
	local step = Metro.CarLength + Metro.CarGap
	for k = 1, Metro.Cars do
		local z = (k - (Metro.Cars + 1) / 2) * step
		marker(m, "Board", at(7, 2.5, z), "MetroBoard", { Station = id, Line = line.Id }, Vector3.new(3, 5, 6))
	end
	marker(m, "Alight", at(12, 3, 0), "MetroAlight", { Station = id, Line = line.Id })

	-- Vestíbulo (detrás del andén)
	local X0, X1, LH = 17.5, 47.5, 13
	part(m, "LobbyFloor", Vector3.new(X1 - X0, 2, LZ * 2), at((X0 + X1) / 2, -1, 0), rgb(210, 206, 198), Enum.Material.Marble)
	part(m, "LobbyCeiling", Vector3.new(X1 - X0, 1, LZ * 2), at((X0 + X1) / 2, LH + 0.5, 0), rgb(200, 198, 192), Enum.Material.Concrete)
	for _, z in { -LZ - 0.5, LZ + 0.5 } do
		part(m, "LobbyWall", Vector3.new(X1 - X0, LH + 2, 1), at((X0 + X1) / 2, LH / 2, z), TILE, Enum.Material.Marble)
	end
	if not st.Hub or line.Id ~= "L1" then
		part(m, "LobbyBack", Vector3.new(1, LH + 2, LZ * 2), at(X1 + 0.5, LH / 2, 0), TILE, Enum.Material.Marble)
	end
	-- Muro de los tornos (cristal abajo, pared arriba): solo se pasa con billete
	part(m, "GateGlass", Vector3.new(0.4, 7, LZ * 2), at(X0, 3.5, 0), rgb(170, 210, 230), Enum.Material.Glass, { Transparency = 0.6 })
	part(m, "GateWall", Vector3.new(1, 10, LZ * 2), at(X0, 12, 0), TILE, Enum.Material.Marble) -- hasta el techo del andén
	signBoard(m, at(X0 + 0.6, 9.5, 0) * CFrame.Angles(0, math.rad(-90), 0), Vector3.new(16, 2, 0.2), "🚇 " .. string.upper(st.Name) .. "   " .. line.Name, line.Color)
	for i, z in { -9, -4.5, 0, 4.5 } do
		local gate = part(m, "Turnstile", Vector3.new(1.6, 3.4, 1), at(X0 + 1.4, 1.7, z), rgb(80, 84, 92), Enum.Material.Metal, { Tags = { "MetroGate" } })
		gate:SetAttribute("Station", id)
		gate:SetAttribute("Line", line.Id)
		gate:SetAttribute("Through", (at(X0 - 3, 3, z)).Position)
		decor(m, "GateLight", Vector3.new(0.4, 0.3, 0.4), at(X0 + 2.1, 3.5, z), if i % 2 == 0 then rgb(60, 220, 90) else rgb(60, 220, 90), Enum.Material.Neon)
	end
	local exitGate = part(m, "ExitGate", Vector3.new(1.6, 3.4, 1.2), at(X0 - 1.4, 1.7, 9), rgb(80, 84, 92), Enum.Material.Metal, { Tags = { "MetroGateExit" } })
	exitGate:SetAttribute("Through", (at(X0 + 3.5, 3, 9)).Position)
	-- Máquinas de billetes
	for _, z in { -20, -16 } do
		local machine = part(m, "TicketMachine", Vector3.new(2, 5.6, 3), at(X1 - 1.4, 2.8, z), rgb(30, 90, 170), Enum.Material.SmoothPlastic, { Tags = { "MetroTicketMachine" } })
		local _ = machine
		decor(m, "TicketScreen", Vector3.new(0.1, 1.6, 2), at(X1 - 2.45, 3.8, z), rgb(120, 200, 255), Enum.Material.Neon)
	end
	-- Quiosco (y punto de entrega de paquetes)
	local kiosk = part(m, "Kiosk", Vector3.new(7, 3.4, 2.4), at(X1 - 6, 1.7, 18), rgb(40, 110, 70), Enum.Material.Wood, { Tags = { "MetroShop", "MetroDelivery" } })
	kiosk:SetAttribute("ShopId", "Quiosco")
	kiosk:SetAttribute("Station", id)
	decor(m, "KioskRoof", Vector3.new(8, 0.4, 5), at(X1 - 6, 7.5, 19.5), rgb(40, 110, 70))
	signBoard(m, at(X1 - 6, 8.6, 17.2), Vector3.new(6, 1.2, 0.2), "📰 QUIOSCO", rgb(40, 110, 70))
	for i = 0, 5 do
		decor(m, "Magazine", Vector3.new(0.9, 1.2, 0.1), at(X1 - 8.5 + i, 4.2, 20.8), rgb(math.random(80, 240), math.random(80, 240), math.random(80, 240)))
	end
	-- Escalera a la calle y punto de llegada
	for i = 0, 7 do
		decor(m, "Stair", Vector3.new(8, 0.8, 1.2), at(X0 + 12 + i * 1.2, 0.4 + i * 1.3, -LZ + 4), rgb(120, 118, 114), Enum.Material.Concrete)
	end
	marker(m, "Exit", at(X0 + 14, 3, -LZ + 4), "MetroExit", { Station = id }, Vector3.new(8, 6, 6))
	signBoard(m, at(X0 + 14, 10, -LZ + 0.2), Vector3.new(8, 1.4, 0.2), "↑ SALIDA A LA CALLE", DARK)
	marker(m, "Arrival", at(X0 + 10, 3, -LZ + 10), "MetroArrival", { Station = id, Line = line.Id })
	for x = X0 + 6, X1 - 4, 12 do
		ceilingLight(m, at(x, LH - 0.1, -12), Vector3.new(5, 0.2, 1.2), 18)
		ceilingLight(m, at(x, LH - 0.1, 12), Vector3.new(5, 0.2, 1.2), 18)
	end
	-- Transbordo en Plaza Mayor (Línea 2: subir a la galería)
	if st.Hub and line.Id ~= "L1" then
		marker(m, "Transfer", at(X1 - 3, 3, 0), "MetroTransfer", { To = "Hub", Station = id }, Vector3.new(4, 6, 8))
		signBoard(m, at(X1 - 0.1, 8, 0) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(12, 1.6, 0.2), "↑ GALERÍA · LÍNEA 1 🔴", rgb(215, 40, 50))
	end
	-- Detalles: columnas, cámaras, anuncios, grafitis, ratas, aseos, guardias, taquillas… (MetroDetails)
	local seed = index + (if line.Id == "L1" then 0 else 10)
	MetroDetails.platform(m, cf, line, id, seed)
	MetroDetails.lobby(m, cf, line, id, st.Hub == true, seed)
	return m, cf
end

---------------------------------------------------------------------
-- Galería comercial subterránea (Plaza Mayor, detrás del vestíbulo de la Línea 1)
---------------------------------------------------------------------
local function shopFront(m: Instance, at: (number, number, number) -> CFrame, x: number, side: number, width: number, shopId: string?, title: string, color: Color3, tag: string?)
	local z = side * 25
	-- Fachada con escaparate y cartel
	part(m, "ShopBack", Vector3.new(width, 13, 1), at(x, 6.5, z + side * 10), rgb(60, 58, 56), Enum.Material.Brick)
	part(m, "ShopSide", Vector3.new(0.6, 13, 10), at(x - width / 2, 6.5, z + side * 5), rgb(200, 196, 188), Enum.Material.Marble)
	part(m, "ShopSide", Vector3.new(0.6, 13, 10), at(x + width / 2, 6.5, z + side * 5), rgb(200, 196, 188), Enum.Material.Marble)
	part(m, "ShopFloor", Vector3.new(width, 1, 10), at(x, -0.48, z + side * 5), rgb(160, 130, 100), Enum.Material.WoodPlanks)
	signBoard(m, at(x, 10.6, z) * CFrame.Angles(0, if side < 0 then math.rad(180) else 0, 0), Vector3.new(width - 2, 2, 0.3), title, color)
	decor(m, "Neon", Vector3.new(width - 1, 0.25, 0.25), at(x, 9.3, z), color, Enum.Material.Neon)
	-- Estanterías de colores al fondo
	for i = 0, 2 do
		decor(m, "Shelf", Vector3.new(width - 4, 0.3, 1.4), at(x, 2 + i * 2.2, z + side * 9), WOOD, Enum.Material.Wood)
		for j = -2, 2 do
			decor(m, "Goods", Vector3.new(1.2, 1.2, 0.9), at(x + j * (width - 6) / 5, 2.8 + i * 2.2, z + side * 9), color:Lerp(Color3.new(math.random(), math.random(), math.random()), 0.5))
		end
	end
	local counter = part(m, "Counter", Vector3.new(width - 6, 3.4, 2), at(x, 1.7, z + side * 3.5), color:Lerp(Color3.new(1, 1, 1), 0.3), Enum.Material.SmoothPlastic)
	if shopId then
		counter:AddTag("MetroShop")
		counter:SetAttribute("ShopId", shopId)
	end
	if tag then
		counter:AddTag(tag)
	end
	counter:SetAttribute("StaffSpot", (at(x, 0.4, z + side * 6)).Position)
	ceilingLight(m, at(x, 12.8, z + side * 5), Vector3.new(width - 4, 0.2, 1.2), 16)
	return counter
end

local function galleria(parent: Instance, cf: CFrame)
	local m = Builder.model("GaleriaMetro", parent)
	m:SetAttribute("PlaceName", "Galería del Metro")
	local function at(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x, y, z)
	end
	local X0, X1, Z, H = 47.5, 160, 25, 14
	part(m, "MallFloor", Vector3.new(X1 - X0, 2, Z * 2 + 22), at((X0 + X1) / 2, -1, 0), rgb(226, 220, 208), Enum.Material.Marble)
	part(m, "MallCeiling", Vector3.new(X1 - X0 + 2, 1, Z * 2 + 22), at((X0 + X1) / 2, H + 0.5, 0), rgb(40, 44, 54), Enum.Material.SmoothPlastic)
	part(m, "MallEnd", Vector3.new(1, H + 2, Z * 2 + 20), at(X1 + 0.5, H / 2, 0), TILE, Enum.Material.Marble)
	-- Techo "cielo": paneles de luz
	for x = X0 + 10, X1 - 8, 16 do
		ceilingLight(m, at(x, H - 0.2, 0), Vector3.new(10, 0.2, 10), 22)
	end
	-- Columnas y jardineras
	for x = X0 + 16, X1 - 10, 24 do
		for _, z in { -12, 12 } do
			part(m, "Column", Vector3.new(2, H, 2), at(x, H / 2, z), rgb(210, 206, 198), Enum.Material.Marble)
		end
		part(m, "Planter", Vector3.new(4, 1.6, 4), at(x + 12, 0.8, 0), rgb(90, 80, 70), Enum.Material.Concrete)
		decor(m, "Plant", Vector3.new(3, 3.4, 3), at(x + 12, 3.3, 0), rgb(60, 140, 70), Enum.Material.Grass, { Shape = Enum.PartType.Ball })
	end
	-- Tiendas: lado +Z
	shopFront(m, at, 58, 1, 18, "Cafeteria", "☕ CAFÉ ANDÉN", rgb(150, 90, 50))
	shopFront(m, at, 78, 1, 18, "Bocateria", "🥪 BOCATAS EXPRESS", rgb(220, 120, 30))
	shopFront(m, at, 98, 1, 18, "Musica", "💿 VINILO SUBTERRÁNEO", rgb(140, 60, 180))
	shopFront(m, at, 118, 1, 18, "Quiosco", "📰 PRENSA Y CHUCHES", rgb(40, 110, 70))
	local photo = shopFront(m, at, 136, 1, 14, nil, "📸 FOTOMATÓN", rgb(230, 60, 120))
	photo:AddTag("MetroPhoto")
	-- Lado -Z: Objetos Perdidos, tablón de encargos, revisor
	shopFront(m, at, 58, -1, 18, nil, "👛 OBJETOS PERDIDOS", rgb(90, 100, 120), "MetroLostOffice")
	for _, x in { 75.2, 84.8 } do
		part(m, "BoardPost", Vector3.new(0.4, 8, 0.4), at(x, 4, -24), WOOD, Enum.Material.Wood)
	end
	part(m, "RevisorPost", Vector3.new(0.3, 6.5, 0.3), at(92, 3.25, -24.2), STEEL, Enum.Material.Metal)
	local board = part(m, "MissionBoard", Vector3.new(10, 6, 0.4), at(80, 5, -24), rgb(120, 80, 40), Enum.Material.Wood, { Tags = { "MetroMissionBoard" } })
	Builder.sign(board, "📌 ENCARGOS DEL METRO", Enum.NormalId.Back, Color3.new(1, 1, 1), rgb(120, 80, 40))
	for i = 0, 3 do
		decor(m, "Note", Vector3.new(1.8, 2.2, 0.1), at(76 + i * 2.6, 4.6, -23.7), rgb(250, 240, 180))
	end
	local revisor = part(m, "RevisorBoard", Vector3.new(4.4, 3, 0.3), at(92, 4.8, -24), rgb(34, 108, 196), nil, { Tags = { "JobBoard" }, Attributes = { JobId = "Revisor" } })
	Builder.sign(revisor, "SE BUSCA\nREVISORES", Enum.NormalId.Back)
	signBoard(m, at(110, 9, -24.4) * CFrame.Angles(0, math.rad(180), 0), Vector3.new(20, 5, 0.2), "PLANO DEL METRO DE VALMAR\n🔴 L1 Poniente · Plaza Mayor · Levante · Playa Dorada\n🔵 L2 Norte · Plaza Mayor · San Roque · Puerto", DARK)
	for _, z in { -35.6, 35.6 } do
		part(m, "MallWall", Vector3.new(X1 - X0, H + 2, 1), at((X0 + X1) / 2, H / 2, z), TILE, Enum.Material.Marble)
	end
	-- Escenario de los músicos
	part(m, "Stage", Vector3.new(12, 1, 8), at(128, 0.5, -16), rgb(60, 30, 30), Enum.Material.WoodPlanks)
	local mic = part(m, "Mic", Vector3.new(0.3, 5, 0.3), at(128, 3.5, -16), DARK, Enum.Material.Metal, { Tags = { "MetroStage" } })
	local _ = mic
	for _, x in { 122.5, 133.5 } do
		decor(m, "Speaker", Vector3.new(2, 4, 2), at(x, 3, -18), DARK)
	end
	signBoard(m, at(128, 8, -23.9) * CFrame.Angles(0, math.rad(180), 0), Vector3.new(10, 1.6, 0.2), "🎸 ESCENARIO LIBRE · ¡TOCA Y GANA PROPINAS!", rgb(200, 40, 60))
	for _, x in { 120, 136 } do
		part(m, "Bench", Vector3.new(4, 0.4, 1.6), at(x, 1.5, -6), WOOD, Enum.Material.Wood)
	end
	-- Bajada a la Línea 2
	for i = 0, 7 do
		decor(m, "Stair", Vector3.new(1.2, 0.8, 10), at(X1 - 8 + i * 0.9, 0.4 - i * 0.6, 12), rgb(120, 118, 114), Enum.Material.Concrete)
	end
	marker(m, "Transfer", at(X1 - 6, 3, 12), "MetroTransfer", { To = "L2", Station = "PlazaMayor" }, Vector3.new(6, 6, 10))
	signBoard(m, at(X1 - 0.1, 9, 12) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(12, 1.8, 0.2), "↓ LÍNEA 2 🔵 NORTE · SAN ROQUE · PUERTO", rgb(40, 110, 215))
	marker(m, "HubArrival", at(X1 - 12, 3, 4), "MetroHubArrival", { Station = "PlazaMayor" })
	MetroDetails.galleria(m, cf)
	return m
end

---------------------------------------------------------------------

function MetroKit.build(world: Instance)
	local root = Builder.model("Metro", world)
	-- Bocas de metro (una por estación)
	for _, st in Metro.Stations do
		MetroKit.entrance(root, st)
	end
	local under = Builder.model("MetroSubterraneo", root)
	for _, line in Metro.Lines do
		local points = Metro.path(line)
		for i = 1, #line.Stations do
			local _, cf = station(under, line, i)
			if Metro.Stations[line.Stations[i]].Hub and line.Id == "L1" then
				galleria(under, cf)
			end
		end
		-- Túneles entre la salida de un andén y la entrada del siguiente
		for i = 2, #points - 1, 2 do
			tunnel(under, points[i], points[i + 1], line.Color)
		end
		-- Fondos de saco detrás de las estaciones de los extremos
		local first, last = points[1], points[#points]
		tunnel(under, first, first + (first - points[2]).Unit * 60, line.Color)
		tunnel(under, last, last + (last - points[#points - 1]).Unit * 60, line.Color)
		MetroKit.train(under, line)
	end
	return root
end

return MetroKit
