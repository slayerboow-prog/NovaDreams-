-- GymKit: los gimnasios de Valmar por dentro (lo usa GymService).
--
--   GymKit.interior(model, cf, name)   planta baja de un gimnasio de 40 × 36: recepción con su
--        recepcionista (GymReception), vestuarios con taquillas y duchas, espejos, suelo de caucho,
--        fuente de agua (GymFountain), bancos, plantas, luces, altavoces, carteles y 15 máquinas.
--        cf = centro del suelo interior, mirando a la calle (-Z = puerta).
--   GymKit.machine(parent, kind, anchor, gymId, index)   una máquina (modelo con la etiqueta
--        GymMachine y los atributos Kind, GymId, MachineId, Exit). anchor = en el suelo, donde va
--        la cadera de quien entrena y mirando hacia donde mira. La pieza "GymAnchor" lleva el cartel
--        "Entrenar" (GymService).
--   GymKit.centro(world)               el gimnasio grande de Valmar Centro, al lado de la tienda de
--        pesca. Se construye al final (TownBuilder) cambiando los edificios de ese tramo de calle,
--        así no se mueve nada más del mapa.
--
-- SIN math.random: los gimnasios de los barrios se construyen a mitad del mapa (Civic.gym) y un
-- número al azar de más cambiaría todo lo que se sortea después.
--
-- Piezas que se mueven (las anima cada cliente, GymMotion, mientras alguien entrena): atributo Anim
--   Belt    tablillas de la cinta: avanzan por Dir y vuelven a empezar (Along, Length, Start, Speed)
--   Spin    gira alrededor de Pivot por Axis (Turns vueltas por ciclo)
--   Orbit   óvalo sin girar: DirA · RadA · sin + DirB · RadB · (cos - 1)  (pedales)
--   Slide   se desliza por Dir hasta Dist según la carga del ejercicio (pesas, asiento, plataforma)
--   Swing   se balancea alrededor de Pivot por Axis hasta Angle (saco, manetas de la elíptica)
--   Hands   sigue a las manos (Hand = Both / Right / Left) con HandOffset (barras, agarres)
-- Phase desfasa medio ciclo (el pedal izquierdo) y Wave = "Sin" mueve con una onda en vez de con
-- la carga.

local Builder = require(script.Parent.Parent.Builder)
local Building = require(script.Parent.Building)
local Props = require(script.Parent.Props)
local Gym = require(game:GetService("ReplicatedStorage").Shared.Gym)

local GymKit = {}

GymKit.Width = 40
GymKit.Depth = 36

local rgb = Color3.fromRGB
local FRAME = rgb(46, 48, 54)
local CHROME = rgb(188, 192, 200)
local PAD = rgb(30, 30, 34)
local ORANGE = rgb(232, 112, 32)
local PLATE = rgb(26, 26, 28)
local RUBBER = rgb(44, 46, 52)
local WHITE = rgb(240, 240, 236)
local METAL = Enum.Material.Metal
local LEATHER = Enum.Material.Leather

---------------------------------------------------------------------
-- Piezas
---------------------------------------------------------------------
type Ctx = { Model: Model, A: CFrame }

local function P(c: Ctx, x: number, y: number, z: number): CFrame
	return c.A * CFrame.new(x, y, z)
end

local function solid(c: Ctx, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): BasePart
	return Builder.part({ Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = c.Model })
end

local function decor(c: Ctx, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): BasePart
	return Builder.decor({ Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = c.Model })
end

-- Cilindro tumbado a lo largo del eje X local de cf
local function barX(c: Ctx, name: string, length: number, thick: number, cf: CFrame, color: Color3): BasePart
	return decor(c, name, Vector3.new(length, thick, thick), cf, color, METAL)
end

local function cylinder(c: Ctx, name: string, length: number, diameter: number, cf: CFrame, color: Color3, material: Enum.Material?): BasePart
	local part = Builder.decor({ Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(length, diameter, diameter), CFrame = cf, Color = color, Material = material or METAL, Parent = c.Model })
	return part
end

local function world(c: Ctx, v: Vector3): Vector3
	return c.A:VectorToWorldSpace(v)
end

local function anim(part: BasePart, kind: string, attrs: { [string]: any })
	part:SetAttribute("Anim", kind)
	for k, v in attrs do
		part:SetAttribute(k, v)
	end
end

-- Pila de placas de una máquina de poleas: las de arriba suben con la carga
local function stack(c: Ctx, x: number, z: number, lift: number)
	for _, side in { -0.55, 0.55 } do
		decor(c, "GuideRod", Vector3.new(0.12, 5.2, 0.12), P(c, x + side, 2.8, z), CHROME, METAL)
	end
	for i = 0, 9 do
		local plate = decor(c, "StackPlate", Vector3.new(1.3, 0.22, 0.8), P(c, x, 0.5 + i * 0.26, z), if i == 9 then ORANGE else PLATE, METAL)
		if i >= 6 then
			anim(plate, "Slide", { Dir = world(c, Vector3.new(0, 1, 0)), Dist = lift })
		end
	end
	solid(c, "StackGuard", Vector3.new(1.8, 5.6, 0.12), P(c, x, 2.9, z - 0.55), rgb(60, 64, 72), Enum.Material.Glass).Transparency = 0.6
end

-- Cable entre dos piezas (Beam: sigue solo a la pieza que se mueve)
local function cable(from: BasePart, to: BasePart, offsetTo: Vector3?)
	local a0 = Instance.new("Attachment")
	a0.Parent = from
	local a1 = Instance.new("Attachment")
	a1.Position = offsetTo or Vector3.new(0, 0, 0)
	a1.Parent = to
	local beam = Instance.new("Beam")
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Width0 = 0.08
	beam.Width1 = 0.08
	pcall(function() -- (al construir el mapa fuera de Roblox no hay ColorSequence)
		beam.Color = ColorSequence.new(rgb(30, 30, 30))
	end)
	beam.FaceCamera = true
	beam.Segments = 2
	beam.Parent = from
end

-- Barra con discos que sigue a las manos
local function barbell(c: Ctx, cf: CFrame, length: number)
	local center = cf.Position
	local bar = barX(c, "Bar", length, 0.16, cf, CHROME)
	anim(bar, "Hands", { Hand = "Both", HandOffset = Vector3.new(0, 0, 0) })
	for _, side in { -1, 1 } do
		for k, d in { 1.9, 1.5 } do
			local disc = cylinder(c, "Disc", 0.22, d, cf * CFrame.new(side * (length / 2 - 0.5 - k * 0.24), 0, 0), PLATE)
			anim(disc, "Hands", { Hand = "Both", HandOffset = disc.CFrame.Position - center })
		end
	end
	return bar
end

---------------------------------------------------------------------
-- Máquinas
---------------------------------------------------------------------
local builders: { [string]: (Ctx) -> () } = {}

builders.Cinta = function(c)
	local geo = Gym.Machines.Cinta.Geo
	local L = 5.6
	solid(c, "Deck", Vector3.new(2.9, 0.6, 6.2), P(c, 0, 0.3, 0), FRAME, METAL)
	solid(c, "Belt", Vector3.new(2.2, 0.2, L), P(c, 0, geo.Belt - 0.1, 0), rgb(24, 24, 26), Enum.Material.Rubber)
	local start = P(c, 0, geo.Belt + 0.01, -L / 2).Position
	for i = 0, 5 do
		local along = i * L / 6
		local slat = decor(c, "BeltSlat", Vector3.new(2.2, 0.04, 0.12), P(c, 0, geo.Belt + 0.01, -L / 2 + along), rgb(70, 72, 78))
		anim(slat, "Belt", { Along = along, Length = L, Start = start, Dir = world(c, Vector3.new(0, 0, 1)), Speed = 8 })
	end
	decor(c, "Motor", Vector3.new(2.9, 0.9, 1.1), P(c, 0, 0.45, -3.4), rgb(60, 62, 68), METAL)
	for _, x in { -1.35, 1.35 } do
		decor(c, "Upright", Vector3.new(0.22, 4.2, 0.22), P(c, x, 2.4, -3.2) * CFrame.Angles(math.rad(-12), 0, 0), FRAME, METAL)
		decor(c, "Handrail", Vector3.new(0.18, 0.18, 2.2), P(c, x, 3.9, -2.2), CHROME, METAL)
	end
	local console = decor(c, "Console", Vector3.new(2.9, 1.3, 0.5), P(c, 0, 4.5, -3.55) * CFrame.Angles(math.rad(25), 0, 0), rgb(36, 38, 44))
	local screen = decor(c, "Screen", Vector3.new(1.8, 0.8, 0.06), P(c, 0, 4.55, -3.28) * CFrame.Angles(math.rad(25), 0, 0), rgb(20, 60, 90), Enum.Material.Neon)
	Builder.sign(screen, "10 km/h", Enum.NormalId.Back, rgb(120, 255, 200))
	local _ = console
end

builders.Bici = function(c)
	local geo = Gym.Machines.Bici.Geo
	solid(c, "Base", Vector3.new(2.4, 0.25, 0.5), P(c, 0, 0.12, 0.6), FRAME, METAL)
	solid(c, "Base", Vector3.new(2.4, 0.25, 0.5), P(c, 0, 0.12, -2.4), FRAME, METAL)
	solid(c, "Spine", Vector3.new(0.4, 0.4, 3.4), P(c, 0, 0.6, -0.9) * CFrame.Angles(math.rad(8), 0, 0), FRAME, METAL)
	decor(c, "SeatPost", Vector3.new(0.3, geo.Seat - 0.6, 0.3), P(c, 0, (geo.Seat - 0.6) / 2 + 0.4, 0.15), CHROME, METAL)
	solid(c, "Saddle", Vector3.new(1.1, 0.25, 1.3), P(c, 0, geo.Seat - 0.12, 0.1), PAD, LEATHER)
	decor(c, "Column", Vector3.new(0.35, 3.1, 0.35), P(c, 0, 1.9, -2.2) * CFrame.Angles(math.rad(-14), 0, 0), FRAME, METAL)
	barX(c, "Handlebar", 1.9, 0.2, P(c, 0, 3.35, -1.85), PAD)
	decor(c, "Console", Vector3.new(1, 0.6, 0.25), P(c, 0, 3.7, -2.45) * CFrame.Angles(math.rad(30), 0, 0), rgb(36, 38, 44))
	-- Volante de inercia y bielas
	local fly = cylinder(c, "Flywheel", 0.3, 2.1, P(c, 0, 1.35, -2.2), rgb(150, 30, 30))
	anim(fly, "Spin", { Pivot = fly.CFrame.Position, Axis = world(c, Vector3.new(1, 0, 0)), Turns = -2 })
	local hub = P(c, 0, 0.95, -1.0)
	cylinder(c, "Hub", 0.8, 0.6, hub, CHROME)
	local R = 0.75
	for _, side in { 1, -1 } do
		-- El derecho empieza arriba y el izquierdo abajo
		local up = side
		local arm = decor(c, "Crank", Vector3.new(0.14, R, 0.18), hub * CFrame.new(side * 0.45, up * R / 2, 0), CHROME, METAL)
		anim(arm, "Spin", { Pivot = hub.Position, Axis = world(c, Vector3.new(1, 0, 0)), Turns = 1 })
		local pedal = solid(c, "Pedal", Vector3.new(0.7, 0.15, 0.4), hub * CFrame.new(side * 0.75, up * R, 0), PAD)
		pedal.CanCollide = false
		anim(pedal, "Orbit", {
			Wave = "Sin",
			DirA = world(c, Vector3.new(0, 0, -side)),
			RadA = R,
			DirB = world(c, Vector3.new(0, side, 0)),
			RadB = R,
		})
	end
end

builders.Eliptica = function(c)
	local geo = Gym.Machines.Eliptica.Geo
	solid(c, "Rail", Vector3.new(1.6, 0.3, 6.4), P(c, 0, 0.15, -0.3), FRAME, METAL)
	solid(c, "Housing", Vector3.new(1.8, 2.4, 1.3), P(c, 0, 1.2, -3.2), rgb(60, 62, 70), METAL)
	local fly = cylinder(c, "Flywheel", 1.9, 1.9, P(c, 0, 1.2, -3.2), rgb(150, 30, 30))
	fly.Size = Vector3.new(1.95, 1.9, 1.9)
	anim(fly, "Spin", { Pivot = fly.CFrame.Position, Axis = world(c, Vector3.new(1, 0, 0)), Turns = -1 })
	decor(c, "Mast", Vector3.new(0.35, 3.6, 0.35), P(c, 0, 3.4, -3.0), FRAME, METAL)
	decor(c, "Console", Vector3.new(1.2, 0.7, 0.3), P(c, 0, 5.3, -2.9) * CFrame.Angles(math.rad(25), 0, 0), rgb(36, 38, 44))
	for _, side in { 1, -1 } do
		local plate = solid(c, "FootPlate", Vector3.new(0.8, 0.15, 1.6), P(c, side * 0.5, geo.Pedal - 0.08, 0), PAD, Enum.Material.Rubber)
		plate.CanCollide = false
		anim(plate, "Orbit", {
			Wave = "Sin",
			DirA = world(c, Vector3.new(0, 0, -side)),
			RadA = 0.55,
			DirB = world(c, Vector3.new(0, side, 0)),
			RadB = 0.18,
		})
		local pivot = P(c, side * 0.95, 2.2, -2.5)
		local handle = decor(c, "Handle", Vector3.new(0.18, 3.4, 0.18), pivot * CFrame.new(0, 0.9, 0.6) * CFrame.Angles(math.rad(-20), 0, 0), CHROME, METAL)
		anim(handle, "Swing", { Wave = "Sin", Pivot = pivot.Position, Axis = world(c, Vector3.new(1, 0, 0)), Angle = 0.3, Phase = if side > 0 then 0 else 0.5 })
	end
end

builders.Remo = function(c)
	local geo = Gym.Machines.Remo.Geo
	solid(c, "Rail", Vector3.new(0.8, 0.3, 7.4), P(c, 0, geo.Seat - 0.35, 0.9), CHROME, METAL)
	for _, z in { -2.6, 4.4 } do
		solid(c, "Leg", Vector3.new(1.8, geo.Seat - 0.5, 0.4), P(c, 0, (geo.Seat - 0.5) / 2, z), FRAME, METAL)
	end
	local seat = solid(c, "RowSeat", Vector3.new(1.2, 0.2, 1.1), P(c, 0, geo.Seat - 0.1, 0), PAD, LEATHER)
	seat.CanCollide = false
	anim(seat, "Slide", { Dir = world(c, Vector3.new(0, 0, 1)), Dist = 1.1 })
	for _, x in { -0.5, 0.5 } do
		decor(c, "FootRest", Vector3.new(0.6, 0.9, 0.3), P(c, x, geo.Seat + 0.15, -2.3) * CFrame.Angles(math.rad(35), 0, 0), PAD)
	end
	local housing = cylinder(c, "FanHousing", 0.9, 2.3, P(c, 0, 1.3, -3.4), rgb(60, 62, 70))
	local _ = housing
	local fan = cylinder(c, "Fan", 1.0, 1.8, P(c, 0, 1.3, -3.4), rgb(150, 30, 30))
	anim(fan, "Spin", { Pivot = fan.CFrame.Position, Axis = world(c, Vector3.new(1, 0, 0)), Turns = -3 })
	local handle = barX(c, "Handle", 1.6, 0.18, P(c, 0, 1.7, -2.9), PAD)
	anim(handle, "Hands", { Hand = "Both", HandOffset = Vector3.new(0, 0, 0) })
	cable(fan, handle)
end

builders.PressBanca = function(c)
	local geo = Gym.Machines.PressBanca.Geo
	solid(c, "BenchPad", Vector3.new(1.3, 0.35, 4.6), P(c, 0, geo.Bench - 0.17, 1.3), PAD, LEATHER)
	for _, z in { -0.6, 3.2 } do
		solid(c, "BenchLeg", Vector3.new(1.2, geo.Bench - 0.35, 0.3), P(c, 0, (geo.Bench - 0.35) / 2, z), FRAME, METAL)
	end
	for _, x in { -2.1, 2.1 } do
		solid(c, "RackPost", Vector3.new(0.3, 4.6, 0.3), P(c, x, 2.3, 2.3), FRAME, METAL)
		decor(c, "Hook", Vector3.new(0.3, 0.5, 0.5), P(c, x, 3.8, 2.05), ORANGE)
	end
	barbell(c, P(c, 0, 4.1, 2.0), 6.2)
end

builders.PressHombros = function(c)
	local geo = Gym.Machines.PressHombros.Geo
	solid(c, "Seat", Vector3.new(1.6, 0.3, 1.5), P(c, 0, geo.Seat - 0.15, 0.1), PAD, LEATHER)
	decor(c, "SeatPost", Vector3.new(0.35, geo.Seat - 0.3, 0.35), P(c, 0, (geo.Seat - 0.3) / 2, 0.1), FRAME, METAL)
	solid(c, "Backrest", Vector3.new(1.6, 3.2, 0.35), P(c, 0, geo.Seat + 1.7, 0.95), PAD, LEATHER)
	decor(c, "Frame", Vector3.new(0.35, 6.6, 0.35), P(c, 0, 3.3, 1.35), FRAME, METAL)
	stack(c, 0, 2.3, 1.3)
	decor(c, "TopBeam", Vector3.new(3, 0.35, 0.35), P(c, 0, 6.4, 1.35), FRAME, METAL)
	for _, side in { 1, -1 } do
		local grip = decor(c, "Grip", Vector3.new(0.25, 0.25, 0.9), P(c, side * 1.0, geo.Seat + 2.3, -0.2), PAD)
		anim(grip, "Hands", { Hand = if side > 0 then "Right" else "Left", HandOffset = Vector3.new(0, 0, 0) })
		local lever = decor(c, "Lever", Vector3.new(0.2, 0.2, 1.4), P(c, side * 1.0, geo.Seat + 2.3, 0.6), CHROME, METAL)
		anim(lever, "Hands", { Hand = if side > 0 then "Right" else "Left", HandOffset = lever.CFrame.Position - grip.CFrame.Position })
	end
end

builders.Jalon = function(c)
	local geo = Gym.Machines.Jalon.Geo
	solid(c, "Seat", Vector3.new(1.5, 0.3, 1.4), P(c, 0, geo.Seat - 0.15, 0), PAD, LEATHER)
	decor(c, "SeatPost", Vector3.new(0.35, geo.Seat - 0.3, 0.35), P(c, 0, (geo.Seat - 0.3) / 2, 0), FRAME, METAL)
	solid(c, "KneePad", Vector3.new(1.8, 0.45, 0.6), P(c, 0, geo.Seat + 1.3, -0.7), PAD, LEATHER)
	for _, x in { -0.9, 0.9 } do
		solid(c, "Post", Vector3.new(0.35, 8.4, 0.35), P(c, x, 4.2, -1.9), FRAME, METAL)
	end
	stack(c, 0, -1.9, 1.6)
	decor(c, "TopBeam", Vector3.new(0.4, 0.4, 2.2), P(c, 0, 8.2, -1.0), FRAME, METAL)
	local pulley = cylinder(c, "Pulley", 0.3, 0.6, P(c, 0, 7.9, -0.2), CHROME)
	local bar = barX(c, "LatBar", 4.2, 0.16, P(c, 0, 6.5, -0.35), CHROME)
	anim(bar, "Hands", { Hand = "Both", HandOffset = Vector3.new(0, 0, 0) })
	cable(pulley, bar)
end

builders.Prensa = function(c)
	local geo = Gym.Machines.Prensa.Geo
	solid(c, "Seat", Vector3.new(1.6, 0.3, 1.4), P(c, 0, geo.Seat - 0.15, 0), PAD, LEATHER)
	solid(c, "Base", Vector3.new(2.6, 0.4, 6.6), P(c, 0, 0.2, -1.4), FRAME, METAL)
	solid(c, "Backrest", Vector3.new(1.6, 3.2, 0.3), P(c, 0, geo.Seat + 1.2, 1.1) * CFrame.Angles(0.8, 0, 0), PAD, LEATHER)
	decor(c, "SeatFrame", Vector3.new(0.5, geo.Seat - 0.3, 1.2), P(c, 0, (geo.Seat - 0.3) / 2 + 0.3, 0.2), FRAME, METAL)
	local dir = Vector3.new(0, 0.63, -0.78)
	local sled = P(c, 0, 2.3, -1.25) * CFrame.Angles(math.rad(-39), 0, 0)
	for _, x in { -1.2, 1.2 } do
		decor(c, "Rail", Vector3.new(0.25, 0.25, 4.2), P(c, x, 2.1, -2.2) * CFrame.Angles(math.rad(39), 0, 0), CHROME, METAL)
		decor(c, "RailPost", Vector3.new(0.3, 2.8, 0.3), P(c, x, 1.4, -3.6), FRAME, METAL)
	end
	local platform = decor(c, "Platform", Vector3.new(2.4, 2.2, 0.3), sled, rgb(70, 74, 82), Enum.Material.DiamondPlate)
	anim(platform, "Slide", { Dir = world(c, dir.Unit), Dist = 0.75 })
	for _, x in { -1.45, 1.45 } do
		local plate = cylinder(c, "Disc", 0.25, 1.7, sled * CFrame.new(x, 0, 0.6), PLATE)
		anim(plate, "Slide", { Dir = world(c, dir.Unit), Dist = 0.75 })
	end
	for _, x in { -1, 1 } do
		decor(c, "SideGrip", Vector3.new(0.2, 0.2, 0.9), P(c, x * 1.05, geo.Seat + 0.4, -0.2), CHROME, METAL)
	end
end

builders.Sentadilla = function(c)
	decor(c, "Platform", Vector3.new(6.4, 0.08, 5), P(c, 0, 0.04, 0.3), rgb(150, 110, 70), Enum.Material.WoodPlanks)
	for _, x in { -2.5, 2.5 } do
		for _, z in { -0.8, 1.4 } do
			solid(c, "RackPost", Vector3.new(0.3, 7.6, 0.3), P(c, x, 3.8, z), FRAME, METAL)
		end
		decor(c, "Safety", Vector3.new(0.25, 0.25, 3.2), P(c, x, 2.4, 0.3), CHROME, METAL)
		decor(c, "Hook", Vector3.new(0.3, 0.5, 0.5), P(c, x, 4.1, 0.55), ORANGE)
		decor(c, "Top", Vector3.new(0.3, 0.3, 2.5), P(c, x, 7.6, 0.3), FRAME, METAL)
	end
	decor(c, "TopBar", Vector3.new(5.3, 0.3, 0.3), P(c, 0, 7.6, 1.4), FRAME, METAL)
	barbell(c, P(c, 0, 4.35, 0.45), 6.6)
end

builders.Mancuernas = function(c)
	local geo = Gym.Machines.Mancuernas.Geo
	solid(c, "BenchPad", Vector3.new(1.3, 0.35, 3.8), P(c, 0, geo.Seat - 0.17, 1.4), PAD, LEATHER)
	for _, z in { 0.1, 2.8 } do
		solid(c, "BenchLeg", Vector3.new(1.2, geo.Seat - 0.35, 0.3), P(c, 0, (geo.Seat - 0.35) / 2, z), FRAME, METAL)
	end
end

builders.Dominadas = function(c)
	local geo = Gym.Machines.Dominadas.Geo
	for _, x in { -2.0, 2.0 } do
		solid(c, "Post", Vector3.new(0.35, geo.Bar + 0.6, 0.35), P(c, x, (geo.Bar + 0.6) / 2, 0.2), FRAME, METAL)
		decor(c, "Foot", Vector3.new(0.5, 0.2, 2.2), P(c, x, 0.1, 0.2), FRAME, METAL)
	end
	barX(c, "PullBar", 4.4, 0.2, P(c, 0, geo.Bar, 0.05), CHROME)
	decor(c, "Step", Vector3.new(1.6, 0.8, 1.2), P(c, 1.2, 0.4, 1.4), ORANGE)
end

builders.Saco = function(c)
	local top = P(c, 0, 9.2, -2.4)
	decor(c, "Mount", Vector3.new(1.4, 0.3, 1.4), top * CFrame.new(0, 0.3, 0), FRAME, METAL)
	decor(c, "Beam", Vector3.new(0.3, 0.3, 4), P(c, 0, 9.5, -2.4), FRAME, METAL)
	local chain = decor(c, "Chain", Vector3.new(0.12, 2.2, 0.12), top * CFrame.new(0, -1.1, 0), CHROME, METAL)
	local bag = Builder.part({ Name = "Bag", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.8, 1.6, 1.6), CFrame = top * CFrame.new(0, -4.1, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(170, 30, 36), Material = LEATHER, CanCollide = false, Parent = c.Model })
	decor(c, "BagTop", Vector3.new(0.3, 1.62, 1.62), bag.CFrame * CFrame.new(1.75, 0, 0), PAD).Shape = Enum.PartType.Cylinder
	for _, part in { chain, bag, c.Model:FindFirstChild("BagTop") :: BasePart } do
		anim(part, "Swing", { Pivot = top.Position, Axis = world(c, Vector3.new(1, 0, 0)), Angle = 0.14 })
	end
	decor(c, "FloorMat", Vector3.new(4, 0.06, 4), P(c, 0, 0.03, -1.2), rgb(170, 30, 36), Enum.Material.Rubber)
end

local function mat(c: Ctx, z: number, color: Color3)
	decor(c, "Mat", Vector3.new(2.2, 0.12, 6), P(c, 0, 0.06, z), color, Enum.Material.Rubber)
end

builders.Abdominales = function(c)
	mat(c, 1.0, rgb(40, 110, 190))
end

builders.Yoga = function(c)
	mat(c, 0, rgb(130, 70, 170))
end

builders.Comba = function(c)
	decor(c, "Mat", Vector3.new(5, 0.06, 5), P(c, 0, 0.03, 0), rgb(60, 140, 90), Enum.Material.Rubber)
	-- Comba colgada en su gancho (la de verdad aparece en las manos al entrenar)
	decor(c, "Hook", Vector3.new(0.3, 0.3, 0.3), P(c, 2.2, 4.2, 2.4), CHROME, METAL)
	decor(c, "HangingRope", Vector3.new(0.08, 2.4, 0.08), P(c, 2.2, 3.0, 2.4), rgb(240, 170, 40))
end

-- Hacia dónde se aparta el jugador al dejar la máquina (a su derecha, o delante en las esterillas)
local EXIT: { [string]: Vector3 } = {
	Cinta = Vector3.new(2.4, 0, 1.5), Bici = Vector3.new(2, 0, 0), Eliptica = Vector3.new(2.2, 0, 1),
	Remo = Vector3.new(2, 0, 0), PressBanca = Vector3.new(2.2, 0, -1.2), PressHombros = Vector3.new(2, 0, -1.2),
	Jalon = Vector3.new(2, 0, 0.8), Prensa = Vector3.new(2.2, 0, 0.5), Sentadilla = Vector3.new(0, 0, -3),
	Mancuernas = Vector3.new(0, 0, -2.2), Dominadas = Vector3.new(0, 0, -2.2), Saco = Vector3.new(2.2, 0, 0.5),
	Abdominales = Vector3.new(2, 0, 0), Yoga = Vector3.new(2, 0, 0), Comba = Vector3.new(0, 0, -3),
}

function GymKit.machine(parent: Instance, kind: string, anchor: CFrame, gymId: string, index: number): Model
	local def = Gym.Machines[kind]
	local m = Builder.model("Maquina_" .. kind, parent)
	local id = ("%s_%d"):format(gymId, index)
	m:SetAttribute("Kind", kind)
	m:SetAttribute("GymId", gymId)
	m:SetAttribute("MachineId", id)
	m:SetAttribute("Exit", (anchor * CFrame.new(EXIT[kind] or Vector3.new(2, 0, 0))).Position)
	m:AddTag("GymMachine")
	local c: Ctx = { Model = m, A = anchor }
	builders[kind](c)
	-- Donde se coloca quien entrena (y el cartel "Entrenar")
	Builder.part({
		Name = "GymAnchor",
		Size = Vector3.new(2, 0.2, 2),
		CFrame = anchor * CFrame.new(0, 0.1, 0),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Attributes = { Kind = kind, MachineId = id, Name = def.Name },
		Parent = m,
	})
	return m
end

---------------------------------------------------------------------
-- Interior
---------------------------------------------------------------------
-- (x, z, giro en grados, tipo). Giro 0 = quien entrena mira a la calle (-Z)
local LAYOUT = {
	{ -15.8, -12, 0, "Cinta" },
	{ -12.4, -12, 0, "Cinta" },
	{ -8.6, -12.3, 0, "Eliptica" },
	{ -16.5, -3.6, 0, "Bici" },
	{ -13.5, -3.6, 0, "Bici" },
	{ -9.2, -2.4, 0, "Remo" },
	{ -3, -1.4, 0, "Jalon" },
	{ 3, -2.4, 0, "PressHombros" },
	{ 9.6, -0.6, 0, "Prensa" },
	{ 16.3, -0.8, 0, "Saco" },
	{ -4.5, 9.4, 0, "PressBanca" },
	{ 2.8, 11.2, 0, "Sentadilla" },
	{ 10.5, 10.4, 0, "Mancuernas" },
	{ 16, 12.4, 0, "Dominadas" },
	{ 12.4, 3.6, 0, "Abdominales" },
	{ 16.4, 5.2, 0, "Yoga" },
	{ 6.5, 4.6, 0, "Comba" },
}
GymKit.Layout = LAYOUT

local function sign(part: BasePart, text: string, face: Enum.NormalId?, color: Color3?)
	Builder.sign(part, text, face or Enum.NormalId.Front, color)
end

local function plant(c: Ctx, x: number, z: number)
	decor(c, "PlantPot", Vector3.new(1.4, 1.4, 1.4), P(c, x, 0.7, z), rgb(230, 230, 226), Enum.Material.Concrete)
	for k, h in { 2.2, 2.8, 2.4 } do
		local angle = k * 2.1
		decor(c, "Leaves", Vector3.new(0.9, h, 0.9), P(c, x + math.cos(angle) * 0.25, 1.4 + h / 2, z + math.sin(angle) * 0.25) * CFrame.Angles(math.cos(angle) * 0.25, 0, math.sin(angle) * 0.25), rgb(60, 120, 60), Enum.Material.LeafyGrass)
	end
end

-- Banco para descansar (el jugador se sienta y recupera energía: tag Bench)
local function restBench(c: Ctx, cf: CFrame)
	local m = Builder.model("Bench", c.Model)
	m:AddTag("Bench")
	Builder.part({ ClassName = "Seat", Name = "Seat", Size = Vector3.new(4, 0.35, 1.3), CFrame = cf * CFrame.new(0, 1.35, 0), Color = PAD, Material = LEATHER, CanTouch = false, Parent = m })
	for _, x in { -1.6, 1.6 } do
		Builder.decor({ Name = "Leg", Size = Vector3.new(0.3, 1.2, 1.1), CFrame = cf * CFrame.new(x, 0.6, 0), Color = CHROME, Material = METAL, Parent = m })
	end
end

local function lockerRoom(c: Ctx, H: number)
	local wall = rgb(236, 234, 228)
	-- Tabiques: a lo largo de z = 8 (con la puerta) y de x = -9
	solid(c, "Partition", Vector3.new(6.2, H, 0.4), P(c, -15.9, H / 2, 8), wall, Enum.Material.Plaster)
	solid(c, "Partition", Vector3.new(0.4, H, 9), P(c, -9, H / 2, 12.5), wall, Enum.Material.Plaster)
	solid(c, "Partition", Vector3.new(3.6, H - 8, 0.4), P(c, -10.9, 8 + (H - 8) / 2, 8), wall, Enum.Material.Plaster)
	local plate = decor(c, "LockerSign", Vector3.new(3.4, 0.9, 0.1), P(c, -10.9, 8.6, 7.75), rgb(30, 34, 46))
	sign(plate, "🚿 VESTUARIOS", Enum.NormalId.Front)
	decor(c, "TileFloor", Vector3.new(9.4, 0.04, 8.6), P(c, -14, 0.02, 12.6), rgb(210, 216, 222), Enum.Material.Marble)
	-- Taquillas en la pared del fondo y en la de la izquierda
	for i = 0, 5 do
		local x = -18 + i * 1.45
		decor(c, "Locker", Vector3.new(1.4, 6, 0.9), P(c, x, 3, 16.4), if i % 2 == 0 then rgb(40, 110, 170) else rgb(50, 124, 186), METAL)
		decor(c, "LockerHandle", Vector3.new(0.12, 0.5, 0.1), P(c, x + 0.45, 3.2, 15.92), CHROME, METAL)
		decor(c, "LockerVent", Vector3.new(0.9, 0.08, 0.05), P(c, x, 5.4, 15.93), rgb(20, 40, 70))
	end
	for i = 0, 2 do
		local z = 10.2 + i * 1.45
		decor(c, "Locker", Vector3.new(0.9, 6, 1.4), P(c, -18.5, 3, z), if i % 2 == 0 then rgb(50, 124, 186) else rgb(40, 110, 170), METAL)
		decor(c, "LockerHandle", Vector3.new(0.1, 0.5, 0.12), P(c, -18.02, 3.2, z + 0.45), CHROME, METAL)
	end
	-- Banco central, perchas con toallas, espejo y ducha
	solid(c, "LockerBench", Vector3.new(4.2, 0.35, 1.2), P(c, -14.2, 1.3, 12.6), rgb(170, 130, 90), Enum.Material.WoodPlanks)
	for _, x in { -15.9, -12.5 } do
		decor(c, "BenchLeg", Vector3.new(0.3, 1.1, 1), P(c, x, 0.55, 12.6), CHROME, METAL)
	end
	for i = 0, 2 do
		decor(c, "Towel", Vector3.new(0.9, 1.3, 0.12), P(c, -9.6, 4.2, 10 + i * 1.3) * CFrame.Angles(0, math.rad(90), 0), ({ WHITE, ORANGE, rgb(70, 150, 200) })[i + 1], Enum.Material.Fabric)
	end
	local mirror = decor(c, "Mirror", Vector3.new(0.1, 3, 3.2), P(c, -9.3, 4.6, 14.4), rgb(220, 232, 240), Enum.Material.Glass)
	mirror.Reflectance = 0.6
	decor(c, "ShowerWall", Vector3.new(0.3, 7, 2.4), P(c, -12.2, 3.5, 9.4), rgb(200, 210, 220), Enum.Material.Marble)
	decor(c, "ShowerHead", Vector3.new(0.6, 0.2, 0.6), P(c, -13.4, 6.4, 8.6), CHROME, METAL)
	decor(c, "ShowerPipe", Vector3.new(0.12, 1.4, 0.12), P(c, -13.4, 7.1, 8.4), CHROME, METAL)
end

local function reception(c: Ctx, gymId: string, name: string): BasePart
	-- Mostrador con el logo, ordenador y la recepcionista detrás (mirando a la puerta)
	local desk = solid(c, "ReceptionDesk", Vector3.new(8, 3.4, 1.4), P(c, 11, 1.7, -12), rgb(36, 38, 44))
	desk:AddTag("GymReception")
	desk:SetAttribute("GymId", gymId)
	desk:SetAttribute("GymName", name)
	desk:SetAttribute("StaffSpot", P(c, 11, 0, -10.2).Position)
	decor(c, "DeskTop", Vector3.new(8.4, 0.2, 1.8), P(c, 11, 3.5, -12), rgb(200, 170, 120), Enum.Material.WoodPlanks)
	local front = decor(c, "DeskFront", Vector3.new(7, 1.4, 0.1), P(c, 11, 2.2, -12.75), ORANGE)
	sign(front, "💪 RECEPCIÓN", Enum.NormalId.Front)
	decor(c, "Monitor", Vector3.new(1.4, 0.9, 0.12), P(c, 12.5, 4.2, -11.7) * CFrame.Angles(0, math.rad(180), 0), rgb(20, 22, 26))
	decor(c, "Keyboard", Vector3.new(1.2, 0.08, 0.4), P(c, 12.5, 3.65, -11.4), rgb(40, 40, 44))
	cylinder(c, "ShakeCup", 0.8, 0.4, P(c, 8.2, 4, -12.1) * CFrame.Angles(0, 0, math.pi / 2), rgb(120, 200, 120), Enum.Material.SmoothPlastic)
	-- Estante de detrás: toallas y batidos
	solid(c, "BackCounter", Vector3.new(8, 3, 1), P(c, 11, 1.5, -8.4), rgb(200, 170, 120), Enum.Material.WoodPlanks)
	for i = 0, 5 do
		decor(c, "Towel", Vector3.new(0.9, 0.4, 0.7), P(c, 8 + i * 1.2, 3.2, -8.4), if i % 2 == 0 then WHITE else ORANGE, Enum.Material.Fabric)
	end
	for i = 0, 3 do
		cylinder(c, "Shake", 0.9, 0.35, P(c, 8.5 + i * 0.8, 3.45, -8.1) * CFrame.Angles(0, 0, math.pi / 2), ({ rgb(90, 170, 240), rgb(240, 160, 60), rgb(120, 200, 120), rgb(220, 80, 120) })[i + 1], Enum.Material.SmoothPlastic)
	end
	-- Tarifas
	local prices = decor(c, "PriceBoard", Vector3.new(5.6, 3.2, 0.15), P(c, 11, 8, -7.8), rgb(24, 26, 32))
	sign(prices, ("TARIFAS\n🎟️ DÍA %d €\n💳 MES %d €\n🧒 NIÑOS ½"):format(Gym.Passes.Dia.Price, Gym.Passes.Mes.Price), Enum.NormalId.Front, rgb(255, 210, 120))
	return desk
end

function GymKit.interior(model: Model, cf: CFrame, name: string?): Model
	local W, D, H = GymKit.Width, GymKit.Depth, 13.6
	local gymName = name or "Gimnasio"
	local gymId = ("Gym_%d_%d"):format(math.floor(cf.Position.X + 0.5), math.floor(cf.Position.Z + 0.5))
	model:SetAttribute("GymId", gymId)
	model:SetAttribute("GymName", gymName)
	local folder = Builder.model("GymInterior", model)
	local c: Ctx = { Model = folder, A = cf }

	-- Suelo de caucho (zonas de colores) y zócalo
	decor(c, "CardioFloor", Vector3.new(14, 0.04, 20), P(c, -12, 0.02, -7), rgb(40, 56, 80), Enum.Material.Rubber)
	decor(c, "WeightsFloor", Vector3.new(26, 0.04, 12), P(c, 4.5, 0.02, 11), RUBBER, Enum.Material.Rubber)
	decor(c, "Stripe", Vector3.new(26, 0.05, 0.3), P(c, 4.5, 0.03, 4.9), ORANGE)

	-- Espejos en la pared del fondo
	local mirror = decor(c, "Mirror", Vector3.new(24, 7, 0.1), P(c, 5, 4.6, D / 2 - 1.15), rgb(220, 232, 240), Enum.Material.Glass)
	mirror.Reflectance = 0.6
	decor(c, "MirrorFrame", Vector3.new(24.4, 0.3, 0.2), P(c, 5, 8.2, D / 2 - 1.12), CHROME, METAL)
	decor(c, "MirrorFrame", Vector3.new(24.4, 0.3, 0.2), P(c, 5, 1.0, D / 2 - 1.12), CHROME, METAL)
	local side = decor(c, "Mirror", Vector3.new(0.1, 6, 10), P(c, W / 2 - 1.15, 4.4, 10), rgb(220, 232, 240), Enum.Material.Glass)
	side.Reflectance = 0.6

	-- Carteles
	local banner = decor(c, "Banner", Vector3.new(16, 2.2, 0.15), P(c, 5, 10.6, D / 2 - 1.2), ORANGE)
	sign(banner, "💪 " .. string.upper(gymName), Enum.NormalId.Front)
	local cardio = decor(c, "ZoneSign", Vector3.new(0.15, 1.6, 6), P(c, -W / 2 + 1.15, 9.5, -7), rgb(30, 60, 110))
	sign(cardio, "🏃 CARDIO", Enum.NormalId.Right)
	local weights = decor(c, "ZoneSign", Vector3.new(6, 1.6, 0.15), P(c, 5, 12.4, D / 2 - 1.2), rgb(30, 34, 46))
	sign(weights, "🏋️ PESAS · NO DEJES LOS DISCOS EN EL SUELO", Enum.NormalId.Front, rgb(255, 210, 120))
	local boxing = decor(c, "ZoneSign", Vector3.new(0.15, 1.4, 4), P(c, W / 2 - 1.15, 9.2, -1), rgb(140, 24, 30))
	sign(boxing, "🥊 BOXEO", Enum.NormalId.Left)
	local tv = decor(c, "TV", Vector3.new(0.2, 3, 5), P(c, -W / 2 + 1.2, 6.5, -2), rgb(14, 16, 20))
	sign(tv, "¡TÚ PUEDES! 💪\nHidrátate 💧", Enum.NormalId.Right, rgb(255, 230, 120), rgb(20, 40, 90))

	-- Luces: tres tiras en el techo y altavoces en las esquinas
	for i = -1, 1 do
		local strip = decor(c, "LightStrip", Vector3.new(W - 6, 0.2, 0.6), P(c, 0, H - 0.2, i * 10), rgb(255, 250, 240), Enum.Material.Neon)
		local light = Instance.new("SurfaceLight")
		light.Face = Enum.NormalId.Bottom
		light.Angle = 90
		light.Range = 16
		light.Brightness = 1.2
		light.Color = rgb(255, 248, 236)
		light.Shadows = false
		light.Parent = strip
	end
	for _, p in { { -W / 2 + 1.6, -D / 2 + 1.6 }, { W / 2 - 1.6, -D / 2 + 1.6 }, { -W / 2 + 1.6, D / 2 - 1.6 }, { W / 2 - 1.6, D / 2 - 1.6 } } do
		decor(c, "Speaker", Vector3.new(1, 1.6, 0.9), P(c, p[1], H - 1.6, p[2]) * CFrame.Angles(math.rad(-15), math.atan2(-p[1], -p[2]), 0), rgb(24, 24, 28))
	end

	-- Recepción, vestuarios, fuente, bancos y plantas
	local desk = reception(c, gymId, gymName)
	local _ = desk
	lockerRoom(c, H)
	local fountain = solid(c, "WaterFountain", Vector3.new(1.2, 3.2, 1), P(c, W / 2 - 1.7, 1.6, -6), rgb(200, 204, 210), METAL)
	fountain:AddTag("GymFountain")
	decor(c, "FountainBowl", Vector3.new(1.4, 0.3, 1.2), P(c, W / 2 - 1.8, 3.3, -6), CHROME, METAL)
	decor(c, "Spout", Vector3.new(0.15, 0.3, 0.15), P(c, W / 2 - 1.9, 3.6, -6), CHROME, METAL)
	local waterSign = decor(c, "FountainSign", Vector3.new(0.1, 0.8, 1.6), P(c, W / 2 - 1.15, 5, -6), rgb(30, 100, 170))
	sign(waterSign, "💧 AGUA", Enum.NormalId.Left)
	restBench(c, P(c, -5.5, 0, 5.4))
	restBench(c, P(c, W / 2 - 2, 0, -9.6) * CFrame.Angles(0, math.rad(90), 0))
	plant(c, -W / 2 + 1.8, -D / 2 + 1.8)
	plant(c, 5.6, -D / 2 + 1.8)
	plant(c, -7.6, D / 2 - 1.8)
	plant(c, W / 2 - 1.8, D / 2 - 1.8)

	-- Mancuernas en su estantería, junto al espejo
	decor(c, "DumbbellRack", Vector3.new(8, 0.3, 1.6), P(c, 10.5, 1.2, D / 2 - 2.6), FRAME, METAL)
	decor(c, "DumbbellRack", Vector3.new(8, 0.3, 1.6), P(c, 10.5, 2.4, D / 2 - 2.6), FRAME, METAL)
	for _, x in { 6.8, 14.2 } do
		decor(c, "RackLeg", Vector3.new(0.3, 2.6, 1.4), P(c, x, 1.3, D / 2 - 2.6), FRAME, METAL)
	end
	for i = 0, 5 do
		for level, y in { 1.5, 2.7 } do
			local size = 0.3 + i * 0.04 + level * 0.03
			local dumbbell = decor(c, "Dumbbell", Vector3.new(1.1, size, size), P(c, 7.4 + i * 1.25, y, D / 2 - 2.6), PLATE, METAL)
			dumbbell.Shape = Enum.PartType.Cylinder
		end
	end
	-- Discos de repuesto y balón medicinal
	for i = 0, 2 do
		cylinder(c, "SparePlate", 0.25, 1.9 - i * 0.3, P(c, -0.6, 1.05 - i * 0.15, D / 2 - 1.6 - i * 0.3) * CFrame.Angles(0, math.rad(90), 0), PLATE)
	end
	decor(c, "MedicineBall", Vector3.new(1.2, 1.2, 1.2), P(c, -1.6, 0.6, D / 2 - 2.6), rgb(200, 60, 40)).Shape = Enum.PartType.Ball

	-- Tablón de trabajo: monitor/a de gimnasio
	Props.jobBoard(folder, P(c, -5.5, 0, -7.2), "MonitorGimnasio", "MONITOR/A DE GIMNASIO")

	-- Las máquinas
	for i, spot in LAYOUT do
		GymKit.machine(folder, spot[4], P(c, spot[1], 0, spot[2]) * CFrame.Angles(0, math.rad(spot[3]), 0), gymId, i)
	end
	return folder
end

---------------------------------------------------------------------
-- Gimnasio grande de Valmar Centro (junto a la tienda de pesca)
---------------------------------------------------------------------
local function floorPosition(model: Instance): Vector3?
	local floor = model:FindFirstChild("Floor")
	if floor and floor:IsA("BasePart") then
		return floor.CFrame.Position
	end
	return nil
end

function GymKit.centro(world: Instance): Model?
	local block: Instance? = nil
	for _, d in world:GetDescendants() do
		if d.Name == "Manzana_TiendaPesca" and d:IsA("Model") then
			block = d
			break
		end
	end
	local ground = block and block:FindFirstChild("BlockGround")
	if not block or not ground or not ground:IsA("BasePart") then
		warn("[GymKit] No encuentro la manzana de la tienda de pesca: sin gimnasio en el centro")
		return nil
	end
	local p, s = ground.CFrame.Position, ground.Size
	local rect = { X0 = p.X - s.X / 2, X1 = p.X + s.X / 2, Z0 = p.Z - s.Z / 2, Z1 = p.Z + s.Z / 2 }
	local Blocks = require(script.Parent.Blocks) -- (aquí: Blocks usa Civic, que usa GymKit)
	local lot = Blocks.lot(rect, "S")
	-- Tramo de la fachada sur a la izquierda de la tienda de pesca (la tienda mide 30 de ancho)
	local u0, u1 = -lot.Length / 2 + 28, -15
	local W, D = GymKit.Width, GymKit.Depth
	if u1 - u0 < W then
		warn("[GymKit] No cabe el gimnasio del centro")
		return nil
	end
	-- Fuera los edificios de ese tramo (se vuelven a poner al lado, más estrechos)
	local toU = function(position: Vector3): number
		return position.X - (rect.X0 + rect.X1) / 2
	end
	for _, child in block:GetChildren() do
		local position = child:IsA("Model") and child.Name == "Edificio" and floorPosition(child)
		if position and position.Z > rect.Z1 - 30 then
			local u = toU(position)
			if u > u0 - 1 and u < u1 + 1 then
				child:Destroy()
			end
		end
	end
	local gymU = u1 - W / 2
	local cf = lot.facing(gymU, D / 2, 0)
	local model = Building.build({
		Name = "GimnasioValmar",
		Parent = block,
		CFrame = cf,
		Width = W,
		Depth = D,
		Floors = 3,
		Style = "Moderno",
		GroundFloor = "Shop",
		Balconies = false,
		WallColor = rgb(232, 234, 238),
		WindowFaces = { Front = true },
		Sign = "💪 GIMNASIO VALMAR",
		SignColor = ORANGE,
		Awning = ORANGE,
		ShopId = "Gimnasio",
		FloorMaterial = Enum.Material.Rubber,
		FloorColor = rgb(50, 52, 58),
		LightColor = rgb(248, 250, 255),
	})
	GymKit.interior(model, cf * CFrame.new(0, Building.FLOOR_TOP, 0), "Gimnasio Valmar Centro")
	-- El resto del tramo, con edificios como los de al lado
	if gymU - W / 2 - u0 >= 18 then
		Blocks.row(block, lot, u0, gymU - W / 2, { "Clasico", "Moderno", "Popular" }, { 3, 6 })
	end
	return model
end

return GymKit
