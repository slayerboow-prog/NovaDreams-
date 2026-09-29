-- MetroKit: el metro subterráneo de Valmar (datos en Shared/Metro.luau; lo mueve MetroService).
--
--   * Bocas de metro que se bajan andando (Kit/MetroAccess): escaleras desde la acera, vestíbulo bajo
--     la calle y escaleras mecánicas hasta el vestíbulo de andenes. Ascensor en la boca (MetroEntrance)
--     y en el vestíbulo de andenes (MetroExit), que baja/sube directo (MetroArrival).
--   * Estación subterránea por línea: andén recto (el tren para en medio), vía, túneles en curva,
--     vestíbulo con máquinas de billetes (MetroTicketMachine), tornos (MetroGate / MetroGateExit),
--     quiosco (MetroShop + MetroDelivery) y máquina expendedora. Botones de subir al tren en el
--     borde del andén (MetroBoard).
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
local MetroAccess = require(script.Parent.MetroAccess)
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
	lamp:AddTag("MetroLamp") -- (de noche los clientes bajan la luz: MetroTrains)
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

-- Texto del plano de la red (todas las líneas y estaciones, sale de Shared/Metro)
local function planText(title: string): string
	local lines = { title }
	for _, line in Metro.Lines do
		local names = {}
		for _, id in line.Stations do
			table.insert(names, Metro.Stations[id].Name)
		end
		table.insert(lines, ("%s %s · %s"):format(if line.Id == "L1" then "🔴" elseif line.Id == "L2" then "🔵" else "🟢", line.Name, table.concat(names, " · ")))
	end
	table.insert(lines, "(Pulsa para ver el plano y calcular tu ruta)")
	return table.concat(lines, "\n")
end

local function signBoard(parent: Instance, cf: CFrame, size: Vector3, text: string, color: Color3, both: boolean?): (BasePart, TextLabel)
	local board = decor(parent, "Sign", size, cf, color)
	local label = Builder.sign(board, text, Enum.NormalId.Front)
	if both then
		Builder.sign(board, text, Enum.NormalId.Back)
	end
	return board, label
end

---------------------------------------------------------------------
-- Tren
---------------------------------------------------------------------
-- Las soldaduras se hacen al arrancar el servidor (MetroService.weldCar), no al construir el mapa:
-- las que se guardaban en el archivo salían mal y, al cargar, todas las piezas del coche se amontonaban
-- en el centro del suelo (el «tren» parecía un panel blanco sobre una plancha). Aquí solo se marca.
local function weldAll(model: Model, root: BasePart)
	model:SetAttribute("NeedsWeld", true)
	local _ = root
end

-- (lo usa MetroService al arrancar)
function MetroKit.weldCar(model: Model, root: BasePart)
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
	-- Testeros: en las cabinas, cerrados; entre coches, con paso (puerta de intercomunicación abierta)
	local GW = 3.4 -- ancho del paso entre coches
	for _, z in { -L / 2 + 0.15, L / 2 - 0.15 } do
		local cab = (z < 0 and index == 1) or (z > 0 and index == count)
		if cab then
			part(m, "End", Vector3.new(W, H, 0.3), at(0, H / 2, z), WHITE)
		else
			local side = (W - GW) / 2
			part(m, "End", Vector3.new(side, H, 0.3), at(-(GW + side) / 2, H / 2, z), WHITE)
			part(m, "End", Vector3.new(side, H, 0.3), at((GW + side) / 2, H / 2, z), WHITE)
			part(m, "EndTop", Vector3.new(GW, 2.4, 0.3), at(0, H - 1.2, z), WHITE)
			decor(m, "GangwaySign", Vector3.new(GW - 0.4, 0.5, 0.1), at(0, H - 2.7, z - math.sign(z) * 0.2), rgb(30, 150, 70), Enum.Material.Neon, { Transparency = 0.2 })
			-- Fuelle y suelo del paso (hasta la mitad del hueco con el coche de al lado)
			local reach = Metro.CarGap / 2 + 0.3
			local zc = z + math.sign(z) * reach / 2
			part(m, "GangwayFloor", Vector3.new(GW, 0.6, reach), at(0, -0.3, zc), rgb(80, 82, 88), Enum.Material.DiamondPlate)
			for _, x in { -GW / 2 - 0.15, GW / 2 + 0.15 } do
				part(m, "Bellows", Vector3.new(0.3, H - 2.4, reach), at(x, (H - 2.4) / 2, zc), DARK, Enum.Material.Fabric)
			end
			part(m, "BellowsTop", Vector3.new(GW + 0.6, 0.3, reach), at(0, H - 2.4, zc), DARK, Enum.Material.Fabric)
		end
	end
	-- Pantallas de información, publicidad, cámara, papeleras y panel de emergencia
	for _, z in { -L / 4, L / 4 } do
		local screen = decor(m, "InfoScreen", Vector3.new(2.6, 0.9, 0.12), at(0, H - 1.3, z + 3.2), DARK)
		Builder.sign(screen, "🚇 " .. line.Name .. " · próxima estación en pantalla", Enum.NormalId.Front, rgb(255, 210, 60), DARK)
		Builder.sign(screen, "🚇 " .. line.Name, Enum.NormalId.Back, rgb(255, 210, 60), DARK)
	end
	local ADS = { "¡Ven a la galería de Plaza Mayor!", "Cursos en el Campus Valmar", "Playa Dorada: tu verano", "Abono mensual: viaja sin límites", "Hospital de Valmar: cuídate" }
	for _, side in { -1, 1 } do
		local ad = decor(m, "AdPanel", Vector3.new(0.1, 1.1, 5), at(side * (W / 2 - 0.35), H - 2.2, -L / 2 + 6) * CFrame.Angles(0, if side > 0 then math.rad(90) else math.rad(-90), 0), rgb(245, 245, 245))
		Builder.sign(ad, ADS[(index + side + 5) % #ADS + 1], Enum.NormalId.Front, DARK, rgb(245, 245, 245))
		decor(m, "Bin", Vector3.new(0.8, 1.4, 0.8), at(side * (W / 2 - 0.9), 0.7, 0), DARK, Enum.Material.Metal)
	end
	decor(m, "Camera", Vector3.new(0.5, 0.5, 0.7), at(W / 2 - 0.6, H - 0.9, L / 2 - 1.5), DARK, Enum.Material.Metal)
	decor(m, "CameraLed", Vector3.new(0.12, 0.12, 0.12), at(W / 2 - 0.6, H - 0.9, L / 2 - 1.9), rgb(255, 40, 40), Enum.Material.Neon)
	local sos = decor(m, "EmergencyPanel", Vector3.new(0.12, 1.2, 0.9), at(-W / 2 + 0.35, 4.6, -L / 4 + 3.4), rgb(210, 40, 40))
	Builder.sign(sos, "🆘 SOS", Enum.NormalId.Right, Color3.new(1, 1, 1), rgb(210, 40, 40))
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
	-- Siempre cargado y entero en cada ordenador: si no, al moverse se cargaba a trozos (un panel
	-- blanco o el suelo sueltos en vez de un tren). Son dos trenes: no pesa.
	pcall(function()
		(m :: any).ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	end)
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
-- (extA / extB: cuánto se alarga por cada punta, para cerrar el hueco de las curvas)
local function tunnel(parent: Instance, a: Vector3, b: Vector3, color: Color3, extA: number?, extB: number?)
	local len = (b - a).Magnitude
	if len < 1 then
		return
	end
	local cf0 = Builder.facing(a, b - a) -- (no CFrame.lookAt: en Lune sale mal hacia +Z)
	local pieces = math.ceil(len / 150)
	local piece = len / pieces
	for i = 0, pieces - 1 do
		local ea = if i == 0 then extA or 0 else 0.1
		local eb = if i == pieces - 1 then extB or 0 else 0.1
		local c = cf0 * CFrame.new(0, 0, -(i + 0.5) * piece - (eb - ea) / 2)
		local long = piece + ea + eb
		part(parent, "TunnelFloor", Vector3.new(12, 1, long), c * CFrame.new(0, -1.5, 0), rgb(70, 66, 60), Enum.Material.Concrete)
		for _, x in { -6.5, 6.5 } do
			part(parent, "TunnelWall", Vector3.new(1, 14, long), c * CFrame.new(x, 5, 0), CONCRETE, Enum.Material.Concrete)
			decor(parent, "Cable", Vector3.new(0.3, 0.3, piece), c * CFrame.new(x * 0.9, 8, 0), DARK)
		end
		part(parent, "TunnelRoof", Vector3.new(14, 1, long), c * CFrame.new(0, 12.5, 0), CONCRETE, Enum.Material.Concrete)
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

-- Fondo del túnel: pared de hormigón que lo cierra (debajo de la ciudad no hay terreno: sin ella se
-- veía el cielo al final de la vía) y un tope de vía con sus luces rojas
local function deadEnd(parent: Instance, at: Vector3, dir: Vector3)
	local cf = Builder.facing(at, dir)
	part(parent, "TunnelEnd", Vector3.new(15, 15, 1.5), cf * CFrame.new(0, 5.5, -0.75), CONCRETE, Enum.Material.Concrete)
	part(parent, "BufferStop", Vector3.new(5, 1.6, 1.2), cf * CFrame.new(0, 0.3, 2.5), rgb(200, 40, 40), Enum.Material.Metal)
	for _, x in { -1.4, 1.4 } do
		decor(parent, "BufferPost", Vector3.new(0.5, 1.6, 2), cf * CFrame.new(x, -0.5, 3.4), DARK, Enum.Material.Metal)
		decor(parent, "BufferLight", Vector3.new(0.5, 0.5, 0.2), cf * CFrame.new(x * 1.5, 1.6, 1.8), rgb(255, 40, 40), Enum.Material.Neon)
	end
end

---------------------------------------------------------------------
-- Estación subterránea
---------------------------------------------------------------------
-- Personalidad de cada estación (según su barrio, Metro.StationInfo): color del azulejo, mural en lo
-- alto de la pared de enfrente, cartel del vestíbulo y letra y colores del nombre. Plaza Mayor ya
-- tiene su galería y se queda con el azulejo blanco de siempre.
--   Tile = azulejo, Accent = franjas del mural, Mural = fondo del mural, NameBg / Name = cartel del
--   nombre (fondo y letra), Font = tipo de letra del nombre, Motifs = dibujos del mural, Motto = lema
local THEMES: { [string]: { [string]: any } } = {
	PlayaDorada = { Tile = rgb(246, 232, 196), Accent = rgb(40, 160, 200), Mural = rgb(96, 190, 222), NameBg = rgb(20, 120, 170), Name = rgb(255, 230, 150), Font = Enum.Font.FredokaOne, Motifs = { "🌊", "☀️", "🐚", "⛱️" }, Motto = "El mar, a un paso" },
	Campus = { Tile = rgb(222, 208, 186), Accent = rgb(120, 30, 40), Mural = rgb(56, 66, 108), NameBg = rgb(110, 30, 40), Name = rgb(240, 214, 150), Font = Enum.Font.Merriweather, Motifs = { "🎓", "📚", "🔬", "✏️" }, Motto = "Saber es viajar" },
	Villaverde = { Tile = rgb(214, 232, 200), Accent = rgb(70, 140, 60), Mural = rgb(128, 184, 96), NameBg = rgb(60, 110, 50), Name = rgb(250, 240, 200), Font = Enum.Font.Cartoon, Motifs = { "🌾", "🐄", "🌻", "🚜" }, Motto = "Del campo a la ciudad" },
	Puerto = { Tile = rgb(200, 214, 226), Accent = rgb(30, 60, 110), Mural = rgb(44, 82, 132), NameBg = rgb(25, 45, 85), Name = rgb(245, 110, 90), Font = Enum.Font.Oswald, Motifs = { "⚓", "🚢", "🦀", "🧭" }, Motto = "Barcos, grúas y gaviotas" },
	Financiero = { Tile = rgb(206, 212, 220), Accent = rgb(90, 100, 115), Mural = rgb(58, 68, 84), NameBg = rgb(28, 32, 38), Name = rgb(120, 220, 255), Font = Enum.Font.SciFi, Motifs = { "🏙️", "📈", "💼", "🏦" }, Motto = "Cristal, acero y prisas" },
	Norte = { Tile = rgb(240, 226, 212), Accent = rgb(200, 110, 60), Mural = rgb(112, 150, 100), NameBg = rgb(170, 90, 50), Name = rgb(255, 250, 240), Font = Enum.Font.Highway, Motifs = { "🏡", "🌲", "🎒", "🚲" }, Motto = "Tu barrio, tu casa" },
	SanRoque = { Tile = rgb(238, 232, 214), Accent = rgb(30, 80, 170), Mural = rgb(44, 92, 172), NameBg = rgb(245, 240, 225), Name = rgb(30, 70, 160), Font = Enum.Font.Antique, Motifs = { "💐", "🍅", "⛪", "🧺" }, Motto = "Mercado, plaza y azulejo" },
	Poniente = { Tile = rgb(248, 222, 200), Accent = rgb(230, 110, 60), Mural = rgb(236, 138, 82), NameBg = rgb(120, 50, 90), Name = rgb(255, 196, 120), Font = Enum.Font.Bangers, Motifs = { "🌅", "⛵", "🌴", "🍹" }, Motto = "Donde se pone el sol" },
	Levante = { Tile = rgb(252, 242, 212), Accent = rgb(240, 170, 40), Mural = rgb(250, 200, 110), NameBg = rgb(240, 170, 40), Name = rgb(70, 36, 20), Font = Enum.Font.FredokaOne, Motifs = { "🌄", "🛍️", "🍕", "🎡" }, Motto = "Donde sale el sol" },
}
MetroKit.Themes = THEMES

-- Mural de la estación: una franja con el lema y los dibujos del barrio en lo alto de la pared de
-- enfrente (se ve desde todo el andén) y un cartel con lo que hay cerca en el vestíbulo
local function mural(m: Instance, at: (number, number, number) -> CFrame, theme: { [string]: any }, st: Metro.Station, P: number, LZ: number)
	local face = CFrame.Angles(0, math.rad(-90), 0) -- (mirando al andén)
	decor(m, "Mural", Vector3.new(0.15, 4.6, P * 2 - 8), at(-5.42, 12.2, 0), theme.Mural)
	for _, y in { 9.75, 14.65 } do
		decor(m, "MuralTrim", Vector3.new(0.2, 0.3, P * 2 - 8), at(-5.4, y, 0), theme.Accent)
	end
	local n = #theme.Motifs
	for i, z in { -54, -18, 18, 54 } do
		local panel = decor(m, "MuralArt", Vector3.new(0.1, 3.6, 3.6), at(-5.36, 12.2, z) * face, theme.Accent)
		Builder.sign(panel, theme.Motifs[(i - 1) % n + 1], Enum.NormalId.Front, Color3.new(1, 1, 1), theme.Accent)
	end
	for _, z in { -36, 36 } do
		local motto = decor(m, "MuralMotto", Vector3.new(0.1, 2.4, 20), at(-5.36, 12.2, z) * face, theme.Mural)
		local label = Builder.sign(motto, string.upper(theme.Motto), Enum.NormalId.Front, theme.Name, theme.Mural)
		label.FontFace = Font.fromEnum(theme.Font)
	end
	-- Vestíbulo: cartel grande sobre la pared de las taquillas con el barrio y lo que hay cerca
	local info = Metro.StationInfo[st.Id]
	local serves = if info then table.concat(info.Serves, " · ") else ""
	local banner = decor(m, "LobbyMural", Vector3.new(26, 2.8, 0.15), at(33, 11, LZ - 0.1), theme.NameBg)
	local label = Builder.sign(banner, ("%s  %s\n%s"):format(theme.Motifs[1], string.upper(st.Name), serves), Enum.NormalId.Front, theme.Name, theme.NameBg)
	label.FontFace = Font.fromEnum(theme.Font)
	decor(m, "LobbyMuralTrim", Vector3.new(26.6, 0.3, 0.2), at(33, 9.45, LZ - 0.1), theme.Accent)
end

local function station(parent: Instance, line: Metro.Line, index: number): (Model, CFrame)
	local id = line.Stations[index]
	local st = Metro.Stations[id]
	local m = Builder.model("Estacion_" .. line.Id .. "_" .. id, parent)
	m:SetAttribute("Station", id)
	m:SetAttribute("Line", line.Id)
	local theme = if st.Hub then nil else THEMES[id]
	local WALL = if theme then theme.Tile else TILE
	if theme then
		m:SetAttribute("Theme", id)
	end
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
	part(m, "FarWall", Vector3.new(1, 18, P * 2), at(-6, 7, 0), WALL, Enum.Material.Marble)
	decor(m, "FarWallBand", Vector3.new(0.2, 1.4, P * 2), at(-5.45, 8.5, 0), line.Color)
	for z = -P + 20, P - 20, 32 do
		local board = decor(m, "StationName", Vector3.new(0.2, 2.2, 12), at(-5.4, 5.6, z) * CFrame.Angles(0, math.rad(90), 0), DARK)
		local _ = board
		local _, nameLabel = signBoard(m, at(-5.35, 5.6, z) * CFrame.Angles(0, math.rad(-90), 0), Vector3.new(12, 2.2, 0.1), string.upper(st.Name), if theme then theme.NameBg else line.Color)
		if theme then
			-- (cada estación con su letra y sus colores)
			nameLabel.TextColor3 = theme.Name
			nameLabel.FontFace = Font.fromEnum(theme.Font)
		end
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
		part(m, "PlatformWall", Vector3.new(1, 18, len), at(17.5, 7, (zs[1] + zs[2]) / 2), WALL, Enum.Material.Marble)
		decor(m, "WallBand", Vector3.new(0.2, 1, len), at(16.95, 8.5, (zs[1] + zs[2]) / 2), line.Color)
	end
	-- Cierres del andén en los extremos (hasta la boca del túnel)
	for _, z in { -P, P } do
		part(m, "PlatformEnd", Vector3.new(12, 18, 1), at(11, 7, z), WALL, Enum.Material.Marble)
		part(m, "TunnelHeader", Vector3.new(13, 4.5, 1), at(-0.5, 14.5, z), WALL, Enum.Material.Marble) -- cierra encima de la boca del túnel
		decor(m, "TunnelMouth", Vector3.new(11, 1.2, 0.3), at(0, 12, z - math.sign(z) * 0.6), DARK)
	end
	-- Bancos, papeleras, reloj y plano de la red en el andén
	for _, z in { -52, -30, 30, 52 } do
		part(m, "Bench", Vector3.new(1.6, 0.4, 5), at(15.6, 1.5, z), WOOD, Enum.Material.Wood)
		decor(m, "BenchLeg", Vector3.new(1.4, 1.3, 0.3), at(15.6, 0.65, z - 2), DARK)
		decor(m, "BenchLeg", Vector3.new(1.4, 1.3, 0.3), at(15.6, 0.65, z + 2), DARK)
		decor(m, "Bin", Vector3.new(1, 1.6, 1), at(16.3, 0.8, z + 4), DARK, Enum.Material.Metal)
	end
	signBoard(m, at(16.9, 6, -40) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(12, 6, 0.2), planText("PLANO DEL METRO"), DARK):AddTag("MetroMapSign")
	-- Salidas de emergencia (verdes, en las dos puntas del andén)
	for _, z in { -P + 3, P - 3 } do
		signBoard(m, at(16.9, 9.5, z) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(5, 1.2, 0.15), "🏃 SALIDA DE EMERGENCIA", rgb(30, 150, 70))
		decor(m, "EmergencyLight", Vector3.new(0.3, 0.3, 1.2), at(16.8, 10.6, z), rgb(80, 255, 120), Enum.Material.Neon)
	end
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
	-- (uno delante de cada puerta: en el móvil sale el botón de la puerta que tienes más cerca)
	for k = 1, Metro.Cars do
		local z = (k - (Metro.Cars + 1) / 2) * step
		for _, dz in { -Metro.CarLength / 4, Metro.CarLength / 4 } do
			marker(m, "Board", at(7, 2.5, z + dz), "MetroBoard", { Station = id, Line = line.Id }, Vector3.new(3, 5, 4))
		end
	end
	marker(m, "Alight", at(12, 3, 0), "MetroAlight", { Station = id, Line = line.Id })

	-- Vestíbulo (detrás del andén)
	local X0, X1, LH = 17.5, 47.5, 13
	part(m, "LobbyFloor", Vector3.new(X1 - X0, 2, LZ * 2), at((X0 + X1) / 2, -1, 0), rgb(210, 206, 198), Enum.Material.Marble)
	-- Por dónde llegan las escaleras mecánicas de la boca: por una pared lateral o, en Plaza Mayor,
	-- bajando del techo
	local access = Metro.access(id)
	local shaftIn = access.Line == line
	local q = cf:PointToObjectSpace(access.Shaft.Bottom)
	local SW = access.Shaft.Width / 2
	local ceilingHole: { number }? = nil
	if shaftIn and access.Shaft.Ceiling then
		local tan = access.Shaft.Rise / access.Shaft.Run
		local z0 = q.Z - (LH + 3.1) / tan
		local z1 = q.Z - (LH - Metro.Shaft.Headroom - 0.9) / tan
		ceilingHole = { q.X - SW - 0.2, X1, z0, z1 }
	end
	local function ceilingPiece(xa: number, xb: number, za: number, zb: number)
		if xb - xa > 0.05 and zb - za > 0.05 then
			part(m, "LobbyCeiling", Vector3.new(xb - xa, 1, zb - za), at((xa + xb) / 2, LH + 0.5, (za + zb) / 2), rgb(200, 198, 192), Enum.Material.Concrete)
		end
	end
	if ceilingHole then
		local h = ceilingHole
		ceilingPiece(X0, h[1], -LZ, LZ)
		ceilingPiece(h[1], X1, -LZ, h[3])
		ceilingPiece(h[1], X1, h[4], LZ)
		-- Borde del hueco del techo, rematado
		decor(m, "HoleTrim", Vector3.new(0.3, 1.2, h[4] - h[3]), at(h[1] - 0.15, LH + 0.4, (h[3] + h[4]) / 2), STEEL, Enum.Material.Metal)
	else
		ceilingPiece(X0, X1, -LZ, LZ)
	end
	for _, z in { -LZ - 0.5, LZ + 0.5 } do
		if shaftIn and not access.Shaft.Ceiling and math.sign(q.Z) == math.sign(z) then
			-- Hueco para las escaleras mecánicas (con un dintel por encima)
			local a, b = q.X - SW, q.X + SW
			part(m, "LobbyWall", Vector3.new(a - X0, LH + 2, 1), at((X0 + a) / 2, LH / 2, z), WALL, Enum.Material.Marble)
			part(m, "LobbyWall", Vector3.new(X1 - b, LH + 2, 1), at((b + X1) / 2, LH / 2, z), WALL, Enum.Material.Marble)
			local hv = Metro.Shaft.Headroom
			part(m, "LobbyWallTop", Vector3.new(b - a, LH + 1 - hv, 1), at((a + b) / 2, (hv + LH + 1) / 2, z), WALL, Enum.Material.Marble)
		else
			part(m, "LobbyWall", Vector3.new(X1 - X0, LH + 2, 1), at((X0 + X1) / 2, LH / 2, z), WALL, Enum.Material.Marble)
		end
	end
	if not st.Hub or line.Id ~= "L1" then
		part(m, "LobbyBack", Vector3.new(1, LH + 2, LZ * 2), at(X1 + 0.5, LH / 2, 0), WALL, Enum.Material.Marble)
	end
	-- Muro de los tornos (cristal abajo, pared arriba): solo se pasa con billete
	part(m, "GateGlass", Vector3.new(0.4, 7, LZ * 2), at(X0, 3.5, 0), rgb(170, 210, 230), Enum.Material.Glass, { Transparency = 0.6 })
	part(m, "GateWall", Vector3.new(1, 10, LZ * 2), at(X0, 12, 0), WALL, Enum.Material.Marble) -- hasta el techo del andén
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
	-- Quiosco (y punto de entrega de paquetes). En Plaza Mayor, al otro lado: por el +Z bajan las
	-- escaleras mecánicas
	local kz = if st.Hub and line.Id == "L1" then -1 else 1
	local kiosk = part(m, "Kiosk", Vector3.new(7, 3.4, 2.4), at(X1 - 6, 1.7, kz * 18), rgb(40, 110, 70), Enum.Material.Wood, { Tags = { "MetroShop", "MetroDelivery" } })
	kiosk:SetAttribute("ShopId", "Quiosco")
	kiosk:SetAttribute("Station", id)
	decor(m, "KioskRoof", Vector3.new(8, 0.4, 5), at(X1 - 6, 7.5, kz * 19.5), rgb(40, 110, 70))
	signBoard(m, at(X1 - 6, 8.6, kz * 17.2) * CFrame.Angles(0, if kz < 0 then math.pi else 0, 0), Vector3.new(6, 1.2, 0.2), "📰 QUIOSCO", rgb(40, 110, 70))
	for i = 0, 5 do
		decor(m, "Magazine", Vector3.new(0.9, 1.2, 0.1), at(X1 - 8.5 + i, 4.2, kz * 20.8), rgb(math.random(80, 240), math.random(80, 240), math.random(80, 240)))
	end
	-- Ascensor a la calle (MetroExit) y dónde deja el de la calle al bajar (MetroArrival)
	local liftAt = if st.Hub then at(26, 0, -LZ + 0.1) * CFrame.Angles(0, math.pi, 0) else at(X1 - 0.1, 0, 11) * CFrame.Angles(0, math.rad(90), 0)
	if not (st.Hub and line.Id ~= "L1") then
		part(m, "LiftDoor", Vector3.new(4, 7, 0.3), liftAt * CFrame.new(0, 3.5, 0), STEEL, Enum.Material.Metal)
		decor(m, "LiftSeam", Vector3.new(0.08, 6.8, 0.35), liftAt * CFrame.new(0, 3.5, 0), DARK)
		decor(m, "LiftFrame", Vector3.new(5, 8, 0.2), liftAt * CFrame.new(0, 4, 0.1), rgb(90, 94, 102), Enum.Material.Metal)
		signBoard(m, liftAt * CFrame.new(0, 8.8, -0.2), Vector3.new(4.6, 1, 0.15), "♿ ASCENSOR · CALLE", rgb(30, 90, 170))
		marker(m, "Exit", liftAt * CFrame.new(0, 3, -2.5), "MetroExit", { Station = id }, Vector3.new(5, 6, 3))
	end
	marker(m, "Arrival", liftAt * CFrame.new(0, 3, -4.5), "MetroArrival", { Station = id, Line = line.Id })
	for x = X0 + 6, X1 - 4, 12 do
		for _, z in { -12, 12 } do
			local h = ceilingHole
			if not (h and x + 2.5 > h[1] and z + 0.6 > h[3] and z - 0.6 < h[4]) then
				ceilingLight(m, at(x, LH - 0.1, z), Vector3.new(5, 0.2, 1.2), 18)
			end
		end
	end
	-- Transbordo en Plaza Mayor (Línea 2: ascensor a la galería)
	if st.Hub and line.Id ~= "L1" then
		marker(m, "Transfer", at(X1 - 3, 3, 0), "MetroTransfer", { To = "Hub", Station = id }, Vector3.new(4, 6, 8))
		local door = at(X1 - 0.1, 0, 0) * CFrame.Angles(0, math.rad(90), 0)
		part(m, "LiftDoor", Vector3.new(4, 7, 0.3), door * CFrame.new(0, 3.5, 0), STEEL, Enum.Material.Metal)
		decor(m, "LiftSeam", Vector3.new(0.08, 6.8, 0.35), door * CFrame.new(0, 3.5, 0), DARK)
		signBoard(m, at(X1 - 0.1, 8, 0) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(12, 1.6, 0.2), "♿ ASCENSOR · GALERÍA · LÍNEA 1", rgb(215, 40, 50))
	end
	-- Personalidad de la estación: mural del barrio y cartel en el vestíbulo
	if theme then
		mural(m, at, theme, st, P, LZ)
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
	signBoard(m, at(110, 9, -24.4) * CFrame.Angles(0, math.rad(180), 0), Vector3.new(20, 5, 0.2), planText("PLANO DEL METRO DE VALMAR"), DARK):AddTag("MetroMapSign")
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
	-- Transbordo a la Línea 2: ascensor en el fondo de la galería (la Línea 2 va por debajo)
	local liftDoor = at(X1 - 0.1, 0, 12) * CFrame.Angles(0, math.rad(90), 0)
	part(m, "LiftDoor", Vector3.new(5, 7, 0.3), liftDoor * CFrame.new(0, 3.5, 0), STEEL, Enum.Material.Metal)
	decor(m, "LiftSeam", Vector3.new(0.08, 6.8, 0.35), liftDoor * CFrame.new(0, 3.5, 0), DARK)
	decor(m, "LiftFrame", Vector3.new(6, 8, 0.2), liftDoor * CFrame.new(0, 4, 0.1), rgb(90, 94, 102), Enum.Material.Metal)
	marker(m, "Transfer", at(X1 - 6, 3, 12), "MetroTransfer", { To = "L2", Station = "PlazaMayor" }, Vector3.new(6, 6, 10))
	signBoard(m, at(X1 - 0.1, 9, 12) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(12, 1.8, 0.2), "♿ ASCENSOR · LÍNEA 2 🔵 NORTE · SAN ROQUE · PUERTO", rgb(40, 110, 215))
	marker(m, "HubArrival", at(X1 - 12, 3, 4), "MetroHubArrival", { Station = "PlazaMayor" })
	MetroDetails.galleria(m, cf)
	return m
end

---------------------------------------------------------------------

function MetroKit.build(world: Instance)
	local root = Builder.model("Metro", world)
	-- Bocas de metro que se bajan andando: escaleras, vestíbulo y escaleras mecánicas (Kit/MetroAccess)
	MetroAccess.build(root, world, root)
	local under = Builder.model("MetroSubterraneo", root)
	for _, line in Metro.Lines do
		local points, _, platform = Metro.path(line)
		for i = 1, #line.Stations do
			local _, cf = station(under, line, i)
			if Metro.Stations[line.Stations[i]].Hub and line.Id == "L1" then
				galleria(under, cf)
			end
		end
		-- Túneles: de la salida de un andén a la entrada del siguiente, en curva (trozos rectos que se
		-- solapan un poco en cada codo)
		for k = 1, #points - 1 do
			if not platform[k] then
				tunnel(under, points[k], points[k + 1], line.Color, if platform[k - 1] then 0.8 else 1.5, if platform[k + 1] then 0.8 else 1.5) -- (junto al andén, un poco metido: sin rendijas)
			end
		end
		-- Fondos de saco detrás de las estaciones de los extremos
		local first, last = points[1], points[#points]
		for _, e in { { first, (first - points[2]).Unit }, { last, (last - points[#points - 1]).Unit } } do
			local stop = e[1] + e[2] * 60
			tunnel(under, e[1], stop, line.Color)
			deadEnd(under, stop, e[2])
		end
		MetroKit.train(under, line)
	end
	return root
end

-- Vacía la roca del terreno por donde pasan las bocas (lo llama TerrainBuilder al arrancar)
function MetroKit.terrain(terrain: Terrain)
	for id in Metro.Stations do
		for _, box in MetroAccess.carveBoxes(id) do
			terrain:FillBlock(box[1], box[2], Enum.Material.Air)
		end
	end
end

-- ¿Hay una boca de metro aquí? (para no plantar árboles encima)
function MetroKit.blocked(x: number, z: number): boolean
	return MetroAccess.blocked(x, z)
end

return MetroKit
