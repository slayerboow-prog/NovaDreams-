-- Airport (Kit): construye el Aeropuerto de Valmar y el Aeródromo de la Isla de las Gaviotas.
-- El plano (dónde va cada cosa) está en Shared/Airport; FlightService mueve los aviones.
--
--   AEROPUERTO DE VALMAR (tierra ganada al mar, al suroeste de la isla)
--     carretera de acceso ─┐
--     [torre]  [carril de llegadas · parada de bus · taxis]        [aparcamiento]
--              [TERMINAL: mostradores · cafetería | control de seguridad | puertas 1 y 2 · sala de espera]
--     [hangar] [plataforma con los aviones]
--     ══════════ calle de rodaje ══════════
--     ████████████████ PISTA (con marcas y luces) ████████████████
--
-- Etiquetas: FlightCheckIn (+Route, Place), FlightGate (+Plane, Place), FlightArrival (+Place),
--   FlightBoard (paneles de salidas), Plane (+PlaneId, Kind) en los modelos de los aviones.
-- Los aviones se sueldan al arrancar el servidor (Airport.weldPlane): las soldaduras guardadas en el
-- archivo salían mal al cargar (como las del metro). Aquí solo se marcan con NeedsWeld.
-- Se construye al final del mapa: lo que use el azar (coches aparcados) no cambia nada más.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Builder = require(script.Parent.Parent.Builder)
local Palette = require(script.Parent.Palette)
local Props = require(script.Parent.Props)
local Plan = require(ReplicatedStorage.Shared.Airport)

local AirportKit = {}

local rgb = Color3.fromRGB
local G = Plan.GROUND
local WALK = 1.0 -- aceras y suelo de la terminal (como las aceras de la calle)
local ASPHALT = Palette.Ground.Asphalt
local RUNWAY = rgb(62, 64, 68)
local CONCRETE = rgb(176, 174, 168)
local WHITE = rgb(240, 240, 236)
local YELLOW = Palette.Ground.MarkingYellow
local DARK = rgb(34, 36, 42)
local GLASS = rgb(150, 190, 214)
local METAL = Palette.Street.Metal
local BLUE = rgb(24, 70, 140)

---------------------------------------------------------------------
-- Piezas
---------------------------------------------------------------------
local function box(parent: Instance, name: string, x0: number, x1: number, y0: number, y1: number, z0: number, z1: number, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
	local props: { [string]: any } = {
		Name = name,
		Size = Vector3.new(x1 - x0, y1 - y0, z1 - z0),
		CFrame = CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2),
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
		Parent = parent,
	}
	local decor = false
	for k, value in extra or {} do
		if k == "Decor" then
			decor = value
		else
			props[k] = value
		end
	end
	return if decor then Builder.decor(props) else Builder.part(props)
end

-- Marca pintada en el suelo (sin choque)
local function paint(parent: Instance, x0: number, x1: number, z0: number, z1: number, color: Color3, y: number?)
	local top = y or G
	return box(parent, "Marking", x0, x1, top, top + 0.05, z0, z1, color, Enum.Material.SmoothPlastic, { Decor = true })
end

-- Cartel con texto por las dos caras
local function board(parent: Instance, cf: CFrame, width: number, height: number, text: string, color: Color3, back: boolean?): (BasePart, TextLabel)
	local part = Builder.decor({ Name = "Sign", Size = Vector3.new(width, height, 0.4), CFrame = cf, Color = color, Parent = parent })
	local label = Builder.sign(part, text, Enum.NormalId.Front, WHITE, color)
	if back ~= false then
		Builder.sign(part, text, Enum.NormalId.Back, WHITE, color)
	end
	return part, label
end

-- Punto de interacción invisible (lo usan los avisos de FlightService)
local function marker(parent: Instance, name: string, position: Vector3, tag: string, attributes: { [string]: any }, size: Vector3?): BasePart
	return Builder.part({
		Name = name,
		Size = size or Vector3.new(4, 4, 4),
		CFrame = CFrame.new(position),
		Transparency = 1,
		CanCollide = false,
		CanTouch = false,
		Tags = { tag },
		Attributes = attributes,
		Parent = parent,
	})
end

local function light(parent: BasePart, range: number, brightness: number, color: Color3?)
	local l = Instance.new("PointLight")
	l.Range = range
	l.Brightness = brightness
	l.Color = color or rgb(255, 244, 220)
	l.Parent = parent
end

-- Muro recto a lo largo de X (en z) con huecos { { x0, x1 } }
local function wallX(parent: Instance, name: string, x0: number, x1: number, z: number, y0: number, y1: number, gaps: { { number } }, color: Color3, material: Enum.Material?, extra: { [string]: any }?)
	local cursor = x0
	table.sort(gaps, function(a, b)
		return a[1] < b[1]
	end)
	for _, gap in gaps do
		if gap[1] > cursor then
			box(parent, name, cursor, gap[1], y0, y1, z - 0.5, z + 0.5, color, material, extra)
		end
		cursor = gap[2]
	end
	if x1 > cursor then
		box(parent, name, cursor, x1, y0, y1, z - 0.5, z + 0.5, color, material, extra)
	end
end

---------------------------------------------------------------------
-- Aviones de piezas (estilo de Kit/Rides): cf = a ras de suelo (las ruedas), el morro mira a -Z
---------------------------------------------------------------------
type PlaneOptions = { Static: boolean? }

local function planeParts(kind: string, color: Color3, cf: CFrame, m: Model, opts: PlaneOptions?)
	local spec = Plan.Kinds[kind]
	local static = opts and opts.Static
	local function at(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x, y, z)
	end
	local function solid(name: string, size: Vector3, c: CFrame, col: Color3, material: Enum.Material?, class: string?): BasePart
		return Builder.part({ ClassName = class, Name = name, Size = size, CFrame = c, Color = col, Material = material or Enum.Material.SmoothPlastic, Parent = m })
	end
	local function bit(name: string, size: Vector3, c: CFrame, col: Color3, material: Enum.Material?, class: string?, shape: Enum.PartType?): BasePart
		return Builder.decor({ ClassName = class, Name = name, Size = size, CFrame = c, Color = col, Material = material or Enum.Material.SmoothPlastic, Shape = shape, Parent = m })
	end
	local function wheel(x: number, z: number, r: number)
		bit("Wheel", Vector3.new(0.9, r * 2, r * 2), at(x, r, z), DARK, Enum.Material.Rubber, nil, Enum.PartType.Cylinder)
	end
	local root = solid("Root", Vector3.new(if kind == "Avion" then 8 else 3.6, 0.6, if kind == "Avion" then 44 else 9), Plan.rootCFrame(kind, cf), rgb(120, 124, 130), Enum.Material.DiamondPlate)
	m.PrimaryPart = root
	local seats = {}
	if kind == "Avion" then
		-- Fuselaje redondo, morro, cola levantada, alas en flecha con motores, estabilizadores y deriva
		local body = bit("Fuselage", Vector3.new(46, 10, 10), at(0, 8, -1) * CFrame.Angles(0, math.rad(90), 0), WHITE, Enum.Material.SmoothPlastic, nil, Enum.PartType.Cylinder)
		body.CastShadow = true
		bit("Nose", Vector3.new(10, 10, 10), at(0, 8, -24), WHITE, nil, nil, Enum.PartType.Ball)
		bit("Cockpit", Vector3.new(5.6, 1.4, 2.2), at(0, 10.6, -27.2) * CFrame.Angles(math.rad(-38), 0, 0), DARK, Enum.Material.Glass)
		bit("Tail", Vector3.new(10, 10, 14), at(0, 8, 29) * CFrame.Angles(math.pi, 0, 0), WHITE, nil, "WedgePart")
		bit("Windows", Vector3.new(10.15, 1.1, 36), at(0, 9.2, -3), DARK, Enum.Material.Glass)
		bit("Stripe", Vector3.new(10.2, 0.8, 44), at(0, 6.4, -1), color)
		bit("Door", Vector3.new(0.2, 5, 2.6), at(-5.02, 7.6, -17), rgb(190, 192, 196))
		for _, side in { -1, 1 } do
			local sweep = math.rad(15) * -side
			solid("Wing", Vector3.new(26, 0.8, 11), at(side * 17.2, 5.4, 4.5) * CFrame.Angles(0, sweep, 0), WHITE, Enum.Material.Metal)
			bit("WingTip", Vector3.new(0.6, 3, 3), at(side * 29.4, 6.8, 8.2), color)
			bit("Engine", Vector3.new(8, 3.6, 3.6), at(side * 11, 3.2, 0.5) * CFrame.Angles(0, math.rad(90), 0), rgb(214, 216, 222), Enum.Material.Metal, nil, Enum.PartType.Cylinder)
			bit("Intake", Vector3.new(0.2, 3, 3), at(side * 11, 3.2, -3.6) * CFrame.Angles(0, math.rad(90), 0), DARK, nil, nil, Enum.PartType.Cylinder)
			bit("Stabilizer", Vector3.new(9, 0.5, 5), at(side * 8.5, 11.6, 32) * CFrame.Angles(0, math.rad(20) * -side, 0), WHITE, Enum.Material.Metal)
			bit("NavLight", Vector3.new(0.6, 0.6, 0.6), at(side * 29.6, 5.4, 7.8), if side < 0 then rgb(255, 40, 40) else rgb(40, 255, 90), Enum.Material.Neon)
			-- Tren principal: pata y dos ruedas
			bit("Strut", Vector3.new(0.6, 3, 0.6), at(side * 4, 2.1, 4), METAL, Enum.Material.Metal)
			wheel(side * 3.3, 4, 0.9)
			wheel(side * 4.7, 4, 0.9)
		end
		bit("Fin", Vector3.new(0.8, 11, 9), at(0, 18, 32) * CFrame.Angles(math.rad(25), 0, 0), color)
		bit("Beacon", Vector3.new(0.7, 0.5, 0.7), at(0, 13.2, 0), rgb(255, 40, 40), Enum.Material.Neon)
		bit("NoseStrut", Vector3.new(0.5, 2.6, 0.5), at(0, 2, -20), METAL, Enum.Material.Metal)
		wheel(0, -20, 0.8)
		-- Cabina de pasajeros: 6 filas de 2 asientos mirando al morro
		for row = 0, 5 do
			for _, x in { -2.2, 2.2 } do
				local z = -14 + row * 5
				table.insert(seats, { x, z })
			end
		end
	else
		-- Avioneta de ala alta: cabina, capó con hélice, cola, ala con puntas de color
		bit("Cabin", Vector3.new(4.6, 4.2, 12), at(0, 4.6, -1), WHITE)
		bit("Windows", Vector3.new(4.7, 1.5, 6), at(0, 5.6, -2), DARK, Enum.Material.Glass)
		bit("Stripe", Vector3.new(4.7, 0.6, 12.1), at(0, 3.9, -1), color)
		bit("Cowl", Vector3.new(4, 3.4, 4), at(0, 4.4, -9), WHITE)
		bit("Spinner", Vector3.new(1.6, 1.6, 1.6), at(0, 4.4, -11.2), color, nil, nil, Enum.PartType.Ball)
		bit("Propeller", Vector3.new(0.4, 7, 0.5), at(0, 4.4, -11.5), DARK)
		bit("Boom", Vector3.new(2.8, 3.2, 11), at(0, 5.1, 10.5) * CFrame.Angles(math.pi, 0, 0), WHITE, nil, "WedgePart")
		bit("Fin", Vector3.new(0.5, 5, 4), at(0, 8.6, 14.6) * CFrame.Angles(math.rad(20), 0, 0), color)
		bit("Stabilizer", Vector3.new(11, 0.4, 3), at(0, 6.8, 15), WHITE)
		solid("Wing", Vector3.new(34, 0.6, 5), at(0, 7, -2.5), WHITE, Enum.Material.Metal)
		for _, side in { -1, 1 } do
			bit("WingTip", Vector3.new(2, 0.62, 5.02), at(side * 16, 7, -2.5), color)
			bit("NavLight", Vector3.new(0.5, 0.5, 0.5), at(side * 17.1, 7, -2.5), if side < 0 then rgb(255, 40, 40) else rgb(40, 255, 90), Enum.Material.Neon)
			bit("Strut", Vector3.new(0.4, 2, 0.4), at(side * 3, 1.6, -1), METAL, Enum.Material.Metal)
			wheel(side * 3.2, -1, 0.8)
		end
		bit("NoseStrut", Vector3.new(0.4, 1.6, 0.4), at(0, 1.6, -8.5), METAL, Enum.Material.Metal)
		wheel(0, -8.5, 0.7)
		for _, z in { -3.6, 0.4 } do
			for _, x in { -1.1, 1.1 } do
				table.insert(seats, { x, z })
			end
		end
	end
	if static then
		return root
	end
	for i, s in seats do
		local seat = solid("Seat", Vector3.new(1.8, 0.5, 1.8), at(s[1], spec.FloorY + 0.9, s[2]), rgb(40, 70, 130), Enum.Material.Fabric, "Seat")
		seat.CanTouch = false -- (solo se sienta quien embarca con billete: FlightService)
		seat:SetAttribute("SeatIndex", i)
		seat:AddTag("PlaneSeat")
		bit("SeatBack", Vector3.new(1.8, 2.4, 0.4), at(s[1], spec.FloorY + 2.2, s[2] + 1.05), rgb(34, 58, 110), Enum.Material.Fabric)
	end
	return root
end

-- Avión que vuela (FlightService lo mueve): siempre cargado entero en cada pantalla
function AirportKit.plane(parent: Instance, plane: { [string]: any }, cf: CFrame): Model
	local m = Instance.new("Model")
	m.Name = plane.Id
	m:SetAttribute("PlaneId", plane.Id)
	m:SetAttribute("Kind", plane.Kind)
	m:SetAttribute("NeedsWeld", true)
	m:AddTag("Plane")
	pcall(function()
		(m :: any).ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	end)
	m.Parent = parent
	planeParts(plane.Kind, plane.Color, cf, m)
	return m
end

-- (lo usa FlightService al arrancar: todo el avión soldado a su suelo, con las piezas ya en su sitio)
function AirportKit.weldPlane(model: Model, root: BasePart)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p ~= root then
			p.Anchored = false
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = p
			weld.Parent = p
		end
	end
	model:SetAttribute("NeedsWeld", nil)
end

---------------------------------------------------------------------
-- Aeropuerto de Valmar
---------------------------------------------------------------------
local function ground(m: Model)
	local L = Plan.Land
	-- Explanada de césped a ras de las calles, con escollera y un murete alrededor
	box(m, "Ground", L.X0, L.X1, -4, 0, L.Z0, L.Z1, Palette.Ground.Grass, Enum.Material.Grass)
	local A = Plan.Access
	local rim = rgb(150, 146, 138)
	box(m, "SeaWall", L.X0 - 2, L.X0, -8, 3, L.Z0 - 2, L.Z1 + 2, rim, Enum.Material.Slate)
	box(m, "SeaWall", L.X1, L.X1 + 2, -8, 3, L.Z0 - 2, L.Z1 + 2, rim, Enum.Material.Slate)
	box(m, "SeaWall", L.X0, L.X1, -8, 3, L.Z1, L.Z1 + 2, rim, Enum.Material.Slate)
	box(m, "SeaWall", L.X0, A.X - 20, -8, 3, L.Z0 - 2, L.Z0, rim, Enum.Material.Slate)
	box(m, "SeaWall", A.X + 20, L.X1, -8, 3, L.Z0 - 2, L.Z0, rim, Enum.Material.Slate)
end

-- Carretera de acceso (como una calle: calzada a 0,4 y aceras a 1), carril de llegadas y aparcamiento
local function roads(m: Model)
	local A, Ln, W, P = Plan.Access, Plan.Lane, Plan.Walk, Plan.Parking
	local x = A.X
	box(m, "Road", x - 12, x + 12, -4, G, A.Z0, A.Z1, ASPHALT, Enum.Material.Asphalt)
	for _, s in { -1, 1 } do
		local x0, x1 = math.min(x + s * 12, x + s * 20), math.max(x + s * 12, x + s * 20)
		box(m, "Sidewalk", x0, x1, -4, WALK, A.Z0, A.Z1, Palette.Ground.Sidewalk, Enum.Material.Pavement)
		box(m, "Curb", math.min(x + s * 11.95, x + s * 12.55), math.max(x + s * 11.95, x + s * 12.55), G, WALK + 0.05, A.Z0, A.Z1, Palette.Ground.Curb, Enum.Material.Concrete, { Decor = true })
	end
	local z = A.Z0 + 6
	while z + 6 < A.Z1 - 4 do
		paint(m, x - 0.25, x + 0.25, z, z + 6, WHITE)
		z += 14
	end
	for i, lz in { A.Z0 + 40, A.Z0 + 130, A.Z0 + 220, A.Z0 + 310 } do
		local s = if i % 2 == 0 then 1 else -1
		Props.lamp(m, Builder.facing(Vector3.new(x + s * 13.8, WALK, lz), Vector3.new(-s, 0, 0)))
	end
	-- Carril de llegadas delante de la terminal
	box(m, "Road", Ln.X0, Ln.X1, -1, G, Ln.Z0, Ln.Z1, ASPHALT, Enum.Material.Asphalt)
	paint(m, Ln.X0 + 4, x - 14, (Ln.Z0 + Ln.Z1) / 2 - 0.25, (Ln.Z0 + Ln.Z1) / 2 + 0.25, WHITE)
	-- Acera de la terminal (con la parada del autobús y los taxis)
	box(m, "Sidewalk", W.X0, P.X0, -1, WALK, W.Z0, W.Z1, Palette.Ground.Sidewalk, Enum.Material.Pavement)
	box(m, "Curb", W.X0, P.X0, G, WALK + 0.05, W.Z0, W.Z0 + 0.6, Palette.Ground.Curb, Enum.Material.Concrete, { Decor = true })
	-- Aparcamiento: asfalto con plazas pintadas y coches
	box(m, "Parking", P.X0, P.X1, -1, G, P.Z0, P.Z1, ASPHALT, Enum.Material.Asphalt)
	local sign = board(m, Builder.facing(Vector3.new(P.X0 + 30, 9, P.Z0 + 2), Vector3.new(0, 0, -1)), 16, 3, "🅿 APARCAMIENTO", BLUE)
	local _ = sign
	for _, dx in { 23, 37 } do
		box(m, "SignPost", P.X0 + dx - 0.25, P.X0 + dx + 0.25, G, 7.5, P.Z0 + 1.75, P.Z0 + 2.25, METAL, Enum.Material.Metal)
	end
	local n = 0
	for _, row in { { Z = P.Z0 + 40, Dir = 1 }, { Z = P.Z1 - 22, Dir = -1 } } do
		local bx = P.X0 + 14
		while bx + 12 < P.X1 - 6 do
			paint(m, bx - 0.2, bx + 0.2, row.Z - 9, row.Z + 9, WHITE)
			n += 1
			if n % 4 == 1 then
				Props.car(m, Builder.facing(Vector3.new(bx + 6, G, row.Z), Vector3.new(0, 0, row.Dir)))
			end
			bx += 12
		end
		paint(m, bx - 0.2, bx + 0.2, row.Z - 9, row.Z + 9, WHITE)
	end
	for _, lx in { P.X0 + 60, P.X1 - 60 } do
		Props.lamp(m, Builder.facing(Vector3.new(lx, G, (P.Z0 + P.Z1) / 2 + 12), Vector3.new(0, 0, -1)))
	end
	for _, lx in { W.X0 + 20, -2880, W.X1 - 30 } do
		Props.lamp(m, Builder.facing(Vector3.new(lx, WALK, W.Z0 + 1.8), Vector3.new(0, 0, -1)))
	end
end

-- Pista, calle de rodaje, plataforma, luces y marcas
local function airfield(m: Model)
	local R, T, Ap = Plan.Runway, Plan.Taxiway, Plan.Apron
	local rz0, rz1 = R.Z - R.Width / 2, R.Z + R.Width / 2
	box(m, "Runway", R.X0, R.X1, -1, G, rz0, rz1, RUNWAY, Enum.Material.Asphalt)
	-- Bordes, eje discontinuo, cebreado de las cabeceras, zona de contacto y números
	paint(m, R.X0 + 2, R.X1 - 2, rz0 + 1.5, rz0 + 2.5, WHITE)
	paint(m, R.X0 + 2, R.X1 - 2, rz1 - 2.5, rz1 - 1.5, WHITE)
	local x = R.X0 + 70
	while x + 24 < R.X1 - 70 do
		paint(m, x, x + 24, R.Z - 0.6, R.Z + 0.6, WHITE)
		x += 44
	end
	for _, e in { { X = R.X0 + 6, Dir = 1 }, { X = R.X1 - 6, Dir = -1 } } do
		for k = 0, 7 do
			local zc = rz0 + 5 + k * 5.7 + (if k >= 4 then 3 else 0)
			local x0, x1 = e.X, e.X + e.Dir * 32
			paint(m, math.min(x0, x1), math.max(x0, x1), zc - 1.2, zc + 1.2, WHITE)
		end
		for _, dz in { -9, 9 } do
			local x0, x1 = e.X + e.Dir * 130, e.X + e.Dir * 175
			paint(m, math.min(x0, x1), math.max(x0, x1), R.Z + dz - 2.5, R.Z + dz + 2.5, WHITE)
		end
		-- Número de la pista (rumbo): se lee al llegar a la cabecera
		local num = Builder.decor({ Name = "RunwayNumber", Size = Vector3.new(16, 0.05, 12), CFrame = CFrame.new(e.X + e.Dir * 55, G + 0.03, R.Z) * CFrame.Angles(0, if e.Dir > 0 then math.rad(-90) else math.rad(90), 0), Color = RUNWAY, Parent = m })
		Builder.sign(num, if e.Dir > 0 then "09" else "27", Enum.NormalId.Top, WHITE, nil)
		-- Luces de cabecera (verdes) y de fin de pista (rojas)
		box(m, "ThresholdLight", math.min(e.X - e.Dir * 3, e.X - e.Dir * 4), math.max(e.X - e.Dir * 3, e.X - e.Dir * 4), 0, 0.8, rz0 + 2, rz1 - 2, rgb(60, 255, 110), Enum.Material.Neon, { Decor = true })
	end
	-- Luces de borde de pista cada 60 studs
	local lx = R.X0 + 10
	while lx <= R.X1 - 10 do
		for _, z in { rz0 - 1.2, rz1 + 1.2 } do
			box(m, "EdgeLight", lx - 0.4, lx + 0.4, 0, 1, z - 0.4, z + 0.4, rgb(255, 248, 225), Enum.Material.Neon, { Decor = true })
		end
		lx += 60
	end
	-- Luces de aproximación (en el lado del mar, al oeste)
	for k = 1, 3 do
		local ax = R.X0 - 30 * k
		box(m, "ApproachLight", ax - 0.4, ax + 0.4, 0, 1, R.Z - 10, R.Z + 10, rgb(255, 248, 225), Enum.Material.Neon, { Decor = true })
	end
	-- Calle de rodaje con eje amarillo y sus salidas a la pista
	local tz0, tz1 = T.Z - T.Width / 2, T.Z + T.Width / 2
	box(m, "Taxiway", T.X0 - T.Width / 2, T.X1 + T.Width / 2, -1, G, tz0, tz1, ASPHALT, Enum.Material.Asphalt)
	paint(m, T.X0, T.X1, T.Z - 0.3, T.Z + 0.3, YELLOW)
	for _, ex in T.Exits do
		-- (salida ancha: los aviones giran sin salirse del asfalto)
		box(m, "Taxiway", ex - T.ExitWidth / 2, ex + T.ExitWidth / 2, -1, G, tz1, rz0, ASPHALT, Enum.Material.Asphalt)
		paint(m, ex - 0.3, ex + 0.3, tz1, rz0, YELLOW)
		-- Línea de espera antes de entrar en la pista
		paint(m, ex - T.Width / 2 + 1, ex + T.Width / 2 - 1, rz0 - 14, rz0 - 13, YELLOW)
		paint(m, ex - T.Width / 2 + 1, ex + T.Width / 2 - 1, rz0 - 11.5, rz0 - 10.5, YELLOW)
	end
	-- Luces azules del borde de la calle de rodaje
	local bx = T.X0 + 40
	while bx < T.X1 - 20 do
		for _, z in { tz0 - 1, tz1 + 1 } do
			box(m, "TaxiLight", bx - 0.3, bx + 0.3, 0, 0.8, z - 0.3, z + 0.3, rgb(60, 110, 255), Enum.Material.Neon, { Decor = true })
		end
		bx += 110
	end
	-- Plataforma de hormigón (desde la fachada de la terminal hasta la calle de rodaje)
	box(m, "Apron", Ap.X0, Ap.X1, -1, G, Plan.Terminal.Z1, tz0, CONCRETE, Enum.Material.Concrete)
	for id, gate in Plan.Gates do
		local stand = Plan.Stands[id]
		-- Línea de guiado hasta el puesto, barra de parada y número de puerta pintado
		paint(m, gate.X - 0.3, gate.X + 0.3, stand.Z - Plan.Kinds[id].Length / 2 - 4, tz0, YELLOW)
		paint(m, gate.X - 5, gate.X + 5, stand.Z - Plan.Kinds[id].Length / 2 - 5, stand.Z - Plan.Kinds[id].Length / 2 - 4, YELLOW)
		local num = Builder.decor({ Name = "StandNumber", Size = Vector3.new(8, 0.05, 8), CFrame = CFrame.new(gate.X + 10, G + 0.03, tz0 - 12), Color = CONCRETE, Parent = m })
		Builder.sign(num, tostring(gate.Number), Enum.NormalId.Top, YELLOW, nil)
	end
	-- Manga de viento junto a la pista
	local wx, wz = -3170, R.Z + R.Width / 2 + 40
	box(m, "WindsockPole", wx - 0.3, wx + 0.3, 0, 14, wz - 0.3, wz + 0.3, METAL, Enum.Material.Metal)
	for k = 0, 2 do
		Builder.decor({
			Name = "Windsock",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2.2, 2 - k * 0.45, 2 - k * 0.45),
			CFrame = CFrame.new(wx + 1.4 + k * 2.2, 13.2 - k * 0.3, wz),
			Color = if k % 2 == 0 then rgb(240, 110, 30) else WHITE,
			Material = Enum.Material.Fabric,
			Parent = m,
		})
	end
end

-- Torre de control
local function tower(m: Model)
	local t = Plan.Tower
	local x, z = t.X, t.Z
	box(m, "TowerBase", x - 11, x + 11, 0, 10, z - 11, z + 11, rgb(222, 220, 214), Enum.Material.Concrete)
	box(m, "TowerShaft", x - 5, x + 5, 10, 44, z - 5, z + 5, rgb(232, 230, 226), Enum.Material.Concrete)
	box(m, "TowerDeck", x - 10, x + 10, 44, 45, z - 10, z + 10, METAL, Enum.Material.Metal)
	box(m, "TowerCab", x - 9, x + 9, 45, 52, z - 9, z + 9, rgb(120, 170, 200), Enum.Material.Glass, { Transparency = 0.35 })
	box(m, "TowerRoof", x - 11, x + 11, 52, 53.5, z - 11, z + 11, DARK, Enum.Material.Metal)
	box(m, "Antenna", x - 0.2, x + 0.2, 53.5, 62, z - 0.2, z + 0.2, METAL, Enum.Material.Metal, { Decor = true })
	local beacon = box(m, "Beacon", x - 0.6, x + 0.6, 62, 63, z - 0.6, z + 0.6, rgb(255, 50, 50), Enum.Material.Neon, { Decor = true })
	light(beacon, 16, 1.5, rgb(255, 60, 60))
	box(m, "TowerDoor", x - 2, x + 2, 0, 7, z - 11.2, z - 11, DARK, Enum.Material.Metal, { Decor = true })
	board(m, Builder.facing(Vector3.new(x, 7.5, z - 11.4), Vector3.new(0, 0, -1)), 14, 2.4, "TORRE DE CONTROL", BLUE)
end

-- Hangar con una avioneta dentro
local function hangar(m: Model)
	local h = Plan.Hangar
	local H = 26
	box(m, "HangarFloor", h.X0, h.X1, -1, G, h.Z0, Plan.Taxiway.Z - Plan.Taxiway.Width / 2, CONCRETE, Enum.Material.Concrete)
	local wall = rgb(196, 204, 210)
	box(m, "HangarWall", h.X0, h.X0 + 1.5, G, H, h.Z0, h.Z1, wall, Enum.Material.CorrodedMetal)
	box(m, "HangarWall", h.X1 - 1.5, h.X1, G, H, h.Z0, h.Z1, wall, Enum.Material.CorrodedMetal)
	box(m, "HangarWall", h.X0, h.X1, G, H, h.Z0, h.Z0 + 1.5, wall, Enum.Material.CorrodedMetal)
	box(m, "HangarFascia", h.X0, h.X1, H - 5, H, h.Z1 - 1.5, h.Z1, wall, Enum.Material.CorrodedMetal)
	box(m, "HangarRoof", h.X0 - 1, h.X1 + 1, H, H + 1.5, h.Z0 - 1, h.Z1 + 1, rgb(120, 126, 134), Enum.Material.CorrodedMetal)
	board(m, Builder.facing(Vector3.new((h.X0 + h.X1) / 2, H - 2.5, h.Z1 + 0.3), Vector3.new(0, 0, 1)), 30, 3.4, "HANGAR · AEROCLUB VALMAR", BLUE, false)
	local lamp = box(m, "HangarLamp", (h.X0 + h.X1) / 2 - 6, (h.X0 + h.X1) / 2 + 6, H - 1, H - 0.6, (h.Z0 + h.Z1) / 2 - 0.5, (h.Z0 + h.Z1) / 2 + 0.5, rgb(250, 250, 240), Enum.Material.Neon, { Decor = true })
	light(lamp, 40, 1)
	local parked = Builder.model("AvionetaHangar", m)
	planeParts("Avioneta", rgb(40, 140, 90), Builder.facing(Vector3.new((h.X0 + h.X1) / 2, G, (h.Z0 + h.Z1) / 2), Vector3.new(0, 0, 1)), parked, { Static = true })
end

-- Terminal: zona pública (mostradores, cafetería), control de seguridad y puertas de embarque
local function terminal(m: Model)
	local T = Plan.Terminal
	local F, H, S = T.Floor, T.Height, T.Split
	local x0, x1, z0, z1 = T.X0, T.X1, T.Z0, T.Z1
	local b = Builder.model("Terminal", m)
	box(b, "Floor", x0, x1, -1, F, z0, z1, rgb(226, 222, 214), Enum.Material.Marble)
	-- Fachada de cristal con dos puertas al norte, cristalera a la plataforma al sur, muros a los lados
	local doors = { { -2926, -2914 }, { -2786, -2774 } }
	wallX(b, "Glass", x0, x1, z0, F, 12, table.clone(doors), GLASS, Enum.Material.Glass, { Transparency = 0.45 })
	wallX(b, "Facade", x0, x1, z0, 12, H, {}, rgb(236, 236, 232), Enum.Material.Concrete)
	wallX(b, "Glass", x0, x1, z1, F, 12, {}, GLASS, Enum.Material.Glass, { Transparency = 0.45 })
	wallX(b, "Facade", x0, x1, z1, 12, H, {}, rgb(236, 236, 232), Enum.Material.Concrete)
	box(b, "Wall", x0 - 1, x0, F, H, z0 - 0.5, z1 + 0.5, rgb(236, 236, 232), Enum.Material.Concrete)
	box(b, "Wall", x1, x1 + 1, F, H, z0 - 0.5, z1 + 0.5, rgb(236, 236, 232), Enum.Material.Concrete)
	for _, d in doors do
		box(b, "DoorFrame", d[1] - 0.6, d[2] + 0.6, 11.4, 12, z0 - 0.7, z0 + 0.7, METAL, Enum.Material.Metal, { Decor = true })
	end
	-- Tejado con voladizo sobre la acera y columnas en las esquinas
	box(b, "Roof", x0 - 5, x1 + 5, H, H + 1.5, Plan.Walk.Z0 + 3, z1 + 5, rgb(200, 204, 210), Enum.Material.Metal)
	for _, cx in { x0 - 3, x1 + 3 } do
		box(b, "Column", cx - 0.6, cx + 0.6, WALK, H, Plan.Walk.Z0 + 4, Plan.Walk.Z0 + 5.2, rgb(220, 222, 226), Enum.Material.Metal)
	end
	board(b, Builder.facing(Vector3.new((x0 + x1) / 2, 17, z0 - 0.7), Vector3.new(0, 0, -1)), 70, 7, "✈ AEROPUERTO DE VALMAR", BLUE, false)
	board(b, Builder.facing(Vector3.new((x0 + x1) / 2, 17, z1 + 0.7), Vector3.new(0, 0, 1)), 70, 7, "AEROPUERTO DE VALMAR", BLUE, false)
	-- Luz del techo
	for _, lz in { z0 + 25, z1 - 25 } do
		local strip = box(b, "CeilingLight", x0 + 20, x1 - 20, H - 0.6, H - 0.3, lz - 0.6, lz + 0.6, rgb(250, 250, 244), Enum.Material.Neon, { Decor = true })
		light(strip, 60, 1.2)
	end

	-- Control de seguridad: mampara de cristal con el arco detector y la salida de llegadas
	local arch, exit = { -2856, -2844 }, { -2736, -2724 }
	wallX(b, "Partition", x0, x1, S, F, 12, { arch, exit }, GLASS, Enum.Material.Glass, { Transparency = 0.6 })
	for _, px in { arch[1] + 0.5, arch[2] - 0.5 } do
		box(b, "ArchPost", px - 0.5, px + 0.5, F, F + 9, S - 0.6, S + 0.6, rgb(200, 204, 210), Enum.Material.Metal)
	end
	box(b, "ArchTop", arch[1], arch[2], F + 9, F + 10.2, S - 0.6, S + 0.6, rgb(200, 204, 210), Enum.Material.Metal)
	box(b, "ArchLight", arch[1] + 1, arch[1] + 2, F + 9.1, F + 9.9, S - 0.7, S - 0.6, rgb(60, 255, 110), Enum.Material.Neon, { Decor = true })
	box(b, "Scanner", -2876, -2861, F, F + 3.4, S - 8, S - 3, rgb(90, 96, 106), Enum.Material.Metal)
	box(b, "ScannerTunnel", -2872, -2865, F + 3.4, F + 6, S - 8, S - 3, rgb(170, 176, 186), Enum.Material.Metal)
	box(b, "Tray", -2874, -2872, F + 3.4, F + 3.8, S - 6.5, S - 4.5, rgb(60, 60, 64), Enum.Material.Plastic, { Decor = true })
	board(b, Builder.facing(Vector3.new(-2850, 14, S - 0.8), Vector3.new(0, 0, -1)), 18, 2.4, "CONTROL DE SEGURIDAD", rgb(40, 44, 52))
	board(b, Builder.facing(Vector3.new(-2730, 14, S + 0.8), Vector3.new(0, 0, 1)), 14, 2.4, "SALIDA · LLEGADAS", rgb(40, 120, 70))

	-- Mostradores de facturación (se compra el billete) y de información
	local desks = {
		{ X = -2966, Text = "1 · VUELTA A LA ISLA", Route = "Vuelta" },
		{ X = -2948, Text = "2 · ISLA DE LAS GAVIOTAS", Route = "IdaGaviotas" },
		{ X = -2930, Text = "INFORMACIÓN", Route = nil },
	}
	for _, d in desks do
		box(b, "CheckInDesk", d.X - 6, d.X + 6, F, F + 3.6, 3082, 3085, rgb(230, 232, 236), Enum.Material.SmoothPlastic)
		box(b, "DeskTop", d.X - 6.2, d.X + 6.2, F + 3.6, F + 3.9, 3081.8, 3085.2, BLUE, Enum.Material.SmoothPlastic, { Decor = true })
		box(b, "Belt", d.X - 5, d.X + 5, F, F + 1.8, 3088, 3091, DARK, Enum.Material.Rubber, { Decor = true })
		board(b, Builder.facing(Vector3.new(d.X, 9, 3083.5), Vector3.new(0, 0, -1)), 11, 1.8, d.Text, BLUE)
		if d.Route then
			marker(b, "CheckIn", Vector3.new(d.X, F + 3, 3081), "FlightCheckIn", { Route = d.Route, Place = "Valmar" })
		end
	end
	board(b, Builder.facing(Vector3.new(-2948, 15, 3090), Vector3.new(0, 0, -1)), 30, 3, "FACTURACIÓN · BILLETES", BLUE)
	-- Paneles de salidas (FlightService escribe los vuelos)
	local function flightBoard(position: Vector3, look: Vector3)
		local part = Builder.part({
			Name = "DeparturesBoard",
			Size = Vector3.new(22, 6, 0.4),
			CFrame = Builder.facing(position, look),
			Color = DARK,
			CanCollide = false,
			Tags = { "FlightBoard" },
			Parent = b,
		})
		local label = Builder.sign(part, "SALIDAS", Enum.NormalId.Front, rgb(255, 210, 60), DARK)
		label.Name = "Text"
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.FontFace = Font.fromEnum(Enum.Font.Code)
	end
	flightBoard(Vector3.new(-2890, 10, S - 1), Vector3.new(0, 0, -1))
	flightBoard(Vector3.new(-2800, 10, S + 1), Vector3.new(0, 0, 1))

	-- Cafetería (zona pública): barra con café, croissants y bocadillos, y dos mesas
	local cx = x1 - 12
	box(b, "CafeCounter", cx - 1.5, cx + 1.5, F, F + 3.6, z0 + 12, z0 + 30, rgb(120, 78, 50), Enum.Material.Wood)
	box(b, "CafeTop", cx - 1.7, cx + 1.7, F + 3.6, F + 3.9, z0 + 11.8, z0 + 30.2, rgb(236, 234, 228), Enum.Material.Marble, { Decor = true })
	for i, food in { { "Cafe", rgb(96, 60, 38) }, { "Croissant", rgb(222, 170, 90) }, { "Bocadillo", rgb(200, 150, 90) } } do
		Builder.part({
			Name = "Food_" .. food[1],
			Size = Vector3.new(1.6, 1.2, 1.6),
			CFrame = CFrame.new(cx, F + 4.5, z0 + 14 + i * 4),
			Color = food[2],
			Tags = { "FoodStand" },
			Attributes = { FoodId = food[1] },
			Parent = b,
		})
	end
	box(b, "CafeShelf", x1 - 3, x1 - 1, F, F + 8, z0 + 10, z0 + 32, rgb(120, 78, 50), Enum.Material.Wood, { Decor = true })
	board(b, Builder.facing(Vector3.new(x1 - 1.2, 11, z0 + 21), Vector3.new(-1, 0, 0)), 16, 2.4, "☕ CAFETERÍA", rgb(110, 66, 40), false)
	for _, tz in { z0 + 15, z0 + 27 } do
		local tx = x1 - 32
		box(b, "CafeTable", tx - 2, tx + 2, F + 2.8, F + 3.1, tz - 2, tz + 2, rgb(236, 232, 224), Enum.Material.Marble)
		box(b, "TableLeg", tx - 0.2, tx + 0.2, F, F + 2.8, tz - 0.2, tz + 0.2, METAL, Enum.Material.Metal, { Decor = true })
		for _, s in { -1, 1 } do
			local seat = Builder.part({ ClassName = "Seat", Name = "Seat", Size = Vector3.new(2, 0.3, 2), CFrame = Builder.facing(Vector3.new(tx + s * 3.4, F + 1.9, tz), Vector3.new(-s, 0, 0)), Color = rgb(150, 100, 64), Material = Enum.Material.Wood, Parent = b })
			local _ = seat
		end
	end

	-- Zona de embarque: puertas 1 y 2, sala de espera con bancos mirando a los aviones y quiosco
	for id, gate in Plan.Gates do
		local plane = nil
		for _, p in Plan.Planes do
			if p.Kind == id then
				plane = p
			end
		end
		box(b, "GateDesk", gate.X - 4, gate.X + 4, F, F + 3.6, z1 - 12, z1 - 9, rgb(230, 232, 236), Enum.Material.SmoothPlastic)
		box(b, "GateTop", gate.X - 4.2, gate.X + 4.2, F + 3.6, F + 3.9, z1 - 12.2, z1 - 8.8, rgb(40, 120, 70), Enum.Material.SmoothPlastic, { Decor = true })
		local title = ("PUERTA %d · %s"):format(gate.Number, if id == "Avion" then "VUELTA A LA ISLA" else "AVIONETA")
		board(b, Builder.facing(Vector3.new(gate.X, 10, z1 - 10.5), Vector3.new(0, 0, -1)), 14, 2, title, rgb(40, 120, 70))
		if plane then
			marker(b, "Gate", Vector3.new(gate.X, F + 3, z1 - 13), "FlightGate", { Plane = plane.Id, Place = "Valmar", Gate = gate.Number })
		end
		-- Pasarela (finger) hasta la puerta del avión
		local fx = gate.X - (if id == "Avion" then 17 else 12)
		box(b, "JetBridge", fx - 3, fx + 3, if id == "Avion" then 6 else 3.5, if id == "Avion" then 13 else 9, z1 + 0.5, z1 + (if id == "Avion" then 30 else 18), rgb(200, 204, 210), Enum.Material.Metal)
		box(b, "JetBridgeLeg", fx - 0.5, fx + 0.5, G, if id == "Avion" then 6 else 3.5, z1 + (if id == "Avion" then 26 else 15), z1 + (if id == "Avion" then 27 else 16), METAL, Enum.Material.Metal)
	end
	for _, row in { S + 22, S + 32 } do
		for _, bx in { -2962, -2946, -2826, -2810 } do
			Props.bench(b, Builder.facing(Vector3.new(bx, F, row), Vector3.new(0, 0, 1)))
		end
	end
	box(b, "KioskCounter", x0 + 4, x0 + 7, F, F + 3.6, S + 8, S + 24, rgb(40, 120, 150), Enum.Material.SmoothPlastic)
	Builder.part({ Name = "Food_Fruta", Size = Vector3.new(1.6, 1.2, 1.6), CFrame = CFrame.new(x0 + 5.5, F + 4.2, S + 16), Color = rgb(230, 170, 60), Tags = { "FoodStand" }, Attributes = { FoodId = "Fruta" }, Parent = b })
	box(b, "KioskShelf", x0, x0 + 2, F, F + 8, S + 6, S + 26, rgb(200, 200, 204), Enum.Material.Metal, { Decor = true })
	board(b, Builder.facing(Vector3.new(x0 + 0.4, 11, S + 16), Vector3.new(1, 0, 0)), 16, 2.4, "📰 PRENSA · REGALOS", rgb(40, 120, 150), false)
	-- Llegadas: aquí aparecen los pasajeros al bajar del avión
	marker(b, "Arrival", Vector3.new(-2745, F + 3, 3088), "FlightArrival", { Place = "Valmar" })
	return b
end

-- Parada del autobús interurbano y parada de taxis
local function stops(m: Model)
	local W = Plan.Walk
	require(script.Parent.Parent.Region).travelStop(m, Builder.facing(Vector3.new(-2850, WALK, W.Z1 - 5), Vector3.new(0, 0, -1)), Plan.Name)
	local tz = Plan.Lane.Z1 - 7
	for _, tx in { -2982, -2964 } do
		local car = Props.car(m, Builder.facing(Vector3.new(tx, G, tz), Vector3.new(1, 0, 0)), rgb(245, 245, 245), "Berlina")
		if car and car:IsA("Model") then
			local roof = Builder.decor({ Name = "TaxiSign", Size = Vector3.new(0.8, 0.9, 2.2), CFrame = CFrame.new(tx, G + 6.1, tz), Color = rgb(60, 200, 90), Material = Enum.Material.Neon, Parent = car })
			local _ = roof
			Builder.decor({ Name = "TaxiStripe", Size = Vector3.new(13.6, 0.5, 6.3), CFrame = CFrame.new(tx, G + 2.6, tz), Color = rgb(200, 30, 40), Parent = car })
		end
	end
	box(m, "TaxiPost", -2973.25, -2972.75, WALK, WALK + 7, W.Z0 + 2.75, W.Z0 + 3.25, METAL, Enum.Material.Metal)
	board(m, Builder.facing(Vector3.new(-2973, WALK + 7.5, W.Z0 + 3), Vector3.new(0, 0, -1)), 5, 2, "🚕 TAXI", rgb(220, 170, 30))
end

function AirportKit.buildValmar(world: Instance): Model
	local m = Builder.model(Plan.Places.Valmar.Model, world)
	ground(m)
	roads(m)
	airfield(m)
	tower(m)
	hangar(m)
	terminal(m)
	stops(m)
	return m
end

---------------------------------------------------------------------
-- Aeródromo de la Isla de las Gaviotas
---------------------------------------------------------------------
-- Explanada del aeródromo (pista, plataforma y caseta): cabe en la hierba de la isla
function AirportKit.gaviotasRect(): { X0: number, X1: number, Z0: number, Z1: number }
	local S, h = Plan.Strip, Plan.StripHut
	return { X0 = S.X0 - 4, X1 = S.X1 + 4, Z0 = h.Z - 16, Z1 = S.Z + S.Width / 2 + 4 }
end

function AirportKit.buildGaviotas(world: Instance): Model
	local m = Builder.model(Plan.Places.Gaviotas.Model, world)
	local S, A, h = Plan.Strip, Plan.StripApron, Plan.StripHut
	local sz0, sz1 = S.Z - S.Width / 2, S.Z + S.Width / 2
	-- Explanada de césped a ras de las calles (el terreno de la isla queda debajo)
	local r = AirportKit.gaviotasRect()
	box(m, "Ground", r.X0, r.X1, -4, 0, r.Z0, r.Z1, Palette.Ground.Grass, Enum.Material.Grass)
	box(m, "Runway", S.X0, S.X1, -1, G, sz0, sz1, RUNWAY, Enum.Material.Asphalt)
	local x = S.X0 + 30
	while x + 14 < S.X1 - 30 do
		paint(m, x, x + 14, S.Z - 0.4, S.Z + 0.4, WHITE)
		x += 28
	end
	for _, e in { { X = S.X0 + 4, Dir = 1 }, { X = S.X1 - 4, Dir = -1 } } do
		for k = 0, 3 do
			local zc = sz0 + 4 + k * 5.2
			local x0, x1 = e.X, e.X + e.Dir * 18
			paint(m, math.min(x0, x1), math.max(x0, x1), zc - 1, zc + 1, WHITE)
		end
	end
	local lx = S.X0 + 8
	while lx <= S.X1 - 8 do
		for _, z in { sz0 - 1, sz1 + 1 } do
			box(m, "EdgeLight", lx - 0.3, lx + 0.3, 0, 0.8, z - 0.3, z + 0.3, rgb(255, 248, 225), Enum.Material.Neon, { Decor = true })
		end
		lx += 64
	end
	box(m, "Apron", A.X0, A.X1, -1, G, A.Z0, A.Z1, CONCRETE, Enum.Material.Concrete)
	-- Explanada de la caseta (a la altura de la plataforma) y la caseta con el mostrador
	local px0, px1, pz0, pz1 = h.X - 20, A.X0, h.Z - 14, A.Z1
	box(m, "Plaza", px0, px1, -1, G, pz0, pz1, rgb(206, 200, 188), Enum.Material.Pavement)
	local hx0, hx1, hz0, hz1 = h.X - 10, h.X + 10, h.Z - 6, h.Z + 6
	box(m, "HutFloor", hx0, hx1, G, WALK, hz0, hz1, rgb(190, 170, 140), Enum.Material.WoodPlanks)
	box(m, "HutWall", hx0, hx1, WALK, 10, hz0, hz0 + 0.8, WHITE, Enum.Material.Plaster)
	box(m, "HutWall", hx0, hx0 + 0.8, WALK, 10, hz0, hz1, WHITE, Enum.Material.Plaster)
	box(m, "HutWall", hx1 - 0.8, hx1, WALK, 10, hz0, hz1, WHITE, Enum.Material.Plaster)
	box(m, "HutRoof", hx0 - 2, hx1 + 2, 10, 11, hz0 - 1, hz1 + 3, rgb(40, 110, 150), Enum.Material.Metal)
	box(m, "HutDesk", h.X - 5, h.X + 5, WALK, WALK + 3.6, hz0 + 3, hz0 + 5.5, rgb(230, 232, 236), Enum.Material.SmoothPlastic)
	marker(m, "CheckIn", Vector3.new(h.X, WALK + 3, hz0 + 7), "FlightCheckIn", { Route = "VueltaGaviotas", Place = "Gaviotas" })
	local part = Builder.part({ Name = "DeparturesBoard", Size = Vector3.new(12, 3.4, 0.3), CFrame = Builder.facing(Vector3.new(h.X, 7.2, hz0 + 1), Vector3.new(0, 0, 1)), Color = DARK, CanCollide = false, Tags = { "FlightBoard" }, Parent = m })
	local label = Builder.sign(part, "SALIDAS", Enum.NormalId.Front, rgb(255, 210, 60), DARK)
	label.Name = "Text"
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.FontFace = Font.fromEnum(Enum.Font.Code)
	board(m, Builder.facing(Vector3.new(h.X, 12.8, hz1 + 3.2), Vector3.new(0, 0, 1)), 22, 2.4, "AERÓDROMO DE LAS GAVIOTAS", rgb(40, 110, 150))
	local puerta = Plan.Planes[2]
	marker(m, "Gate", Vector3.new(A.X0 - 4, G + 3, A.Z1 - 12), "FlightGate", { Plane = puerta.Id, Place = "Gaviotas", Gate = 1 })
	board(m, Builder.facing(Vector3.new(A.X0 - 6, 7, A.Z1 - 12), Vector3.new(0, 0, 1)), 8, 1.6, "EMBARQUE", rgb(40, 120, 70))
	box(m, "GatePost", A.X0 - 6.25, A.X0 - 5.75, G, 6.2, A.Z1 - 12.25, A.Z1 - 11.75, METAL, Enum.Material.Metal)
	marker(m, "Arrival", Vector3.new(h.X + 4, G + 3, h.Z + 16), "FlightArrival", { Place = "Gaviotas" })
	for _, bx in { h.X - 12, h.X + 12 } do
		Props.bench(m, Builder.facing(Vector3.new(bx, G, h.Z + 10), Vector3.new(0, 0, 1)))
	end
	Props.lamp(m, Builder.facing(Vector3.new(px0 + 2, G, pz1 - 2), Vector3.new(1, 0, 0)))
	-- Manga de viento
	local wx, wz = 2800, S.Z - 40
	box(m, "WindsockPole", wx - 0.3, wx + 0.3, 0, 12, wz - 0.3, wz + 0.3, METAL, Enum.Material.Metal)
	for k = 0, 2 do
		Builder.decor({
			Name = "Windsock",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2, 1.8 - k * 0.4, 1.8 - k * 0.4),
			CFrame = CFrame.new(wx + 1.3 + k * 2, 11.3 - k * 0.3, wz),
			Color = if k % 2 == 0 then rgb(240, 110, 30) else WHITE,
			Material = Enum.Material.Fabric,
			Parent = m,
		})
	end
	return m
end

---------------------------------------------------------------------
-- Aviones: esperan en su puerta al empezar
---------------------------------------------------------------------
function AirportKit.buildPlanes(world: Instance): Folder
	local folder = Instance.new("Folder")
	folder.Name = "Aviones"
	folder.Parent = world
	for _, plane in Plan.Planes do
		local route = Plan.Routes[plane.Routes[1]]
		AirportKit.plane(folder, plane, Plan.parkPose(route))
	end
	return folder
end

---------------------------------------------------------------------
-- Terreno (lo llama TerrainBuilder) y limpieza del campo
---------------------------------------------------------------------
local function rects(): { { X0: number, X1: number, Z0: number, Z1: number } }
	local A = Plan.Access
	return {
		Plan.Land,
		{ X0 = A.X - 19.5, X1 = A.X + 19.5, Z0 = A.Z0, Z1 = Plan.Land.Z0 + 2 },
		AirportKit.gaviotasRect(),
	}
end
AirportKit.rects = rects

-- Tierra ganada al mar bajo el aeropuerto y hueco bajo las piezas (su suelo baja hasta Y = -4:
-- así el terreno nunca asoma por el asfalto)
function AirportKit.terrain(terrain: Terrain)
	for i, r in rects() do
		local size = Vector3.new(r.X1 - r.X0, 0, r.Z1 - r.Z0)
		local cx, cz = (r.X0 + r.X1) / 2, (r.Z0 + r.Z1) / 2
		if i <= 2 then
			terrain:FillBlock(CFrame.new(cx, -12, cz), size + Vector3.new(0, 16, 0), Enum.Material.Sand)
		end
		terrain:FillBlock(CFrame.new(cx, 12, cz), size + Vector3.new(0, 32, 0), Enum.Material.Air)
	end
end

-- ¿Este punto es del aeropuerto? (para no plantar árboles encima)
function AirportKit.blocked(x: number, z: number): boolean
	for _, r in rects() do
		if x > r.X0 - 12 and x < r.X1 + 12 and z > r.Z0 - 12 and z < r.Z1 + 12 then
			return true
		end
	end
	return false
end

-- Quita los árboles y matas del campo que caigan encima (se construye al final del mapa)
function AirportKit.clear(world: Instance)
	for _, folderName in { "Naturaleza", "Campo" } do
		local folder = world:FindFirstChild(folderName)
		for _, d in (if folder then folder:GetDescendants() else {}) do
			local alive = pcall(function()
				return d.Parent
			end)
			if alive and d:IsA("BasePart") and d.Parent then
				local p = d.CFrame.Position
				if AirportKit.blocked(p.X, p.Z) then
					local mdl = d:FindFirstAncestorOfClass("Model")
					if mdl and mdl ~= folder and mdl.Parent == folder then
						mdl:Destroy()
					else
						d:Destroy()
					end
				end
			end
		end
	end
end

function AirportKit.build(world: Instance)
	AirportKit.clear(world)
	AirportKit.buildValmar(world)
	AirportKit.buildGaviotas(world)
	AirportKit.buildPlanes(world)
end

return AirportKit
