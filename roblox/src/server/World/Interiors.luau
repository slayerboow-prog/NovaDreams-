-- Interiors: las salas por dentro de los edificios del mapa (las usa InteriorService).
--
-- Los edificios de la ciudad son, por fuera, bloques ligeros (para que el móvil vaya fluido).
-- Al pulsar "Entrar" en su puerta, InteriorService crea la sala de ese tipo en una zona oculta
-- y te lleva allí; al salir vuelves a la calle. Cada sala:
--   * se construye alrededor de cf: suelo en y = 0, la puerta de salida en el lado -Z (local)
--   * tiene una pieza "InteriorEntry" (donde apareces) y una "InteriorExit" (puerta para salir)
--   * puede tener "InteriorElevator" (ascensor a otras plantas)
-- Tipos: Casa, Villa, Portal, Piso, OficinaLobby, Oficina, Local, Nave, Taller, Ocio, Aula,
--        Ayuntamiento, Museo, Teatro, Estacion, CentroComercial, Juzgado, Hacienda, Cuartel.

local Builder = require(script.Parent.Builder)

local Interiors = {}

local rgb = Color3.fromRGB
local V = Vector3.new

local WOOD = rgb(150, 110, 76)
local DARKWOOD = rgb(96, 64, 40)
local WHITE = rgb(240, 240, 236)
local DARK = rgb(44, 46, 52)
local STEEL = rgb(160, 166, 172)
local FABRIC = { rgb(70, 90, 140), rgb(150, 60, 60), rgb(80, 120, 90), rgb(190, 170, 130) }

export type Room = { Model: Model, W: number, D: number, H: number, at: (number, number, number) -> CFrame }

---------------------------------------------------------------------
-- Piezas
---------------------------------------------------------------------
local function solid(room: Room, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
	local props = { Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = room.Model }
	for k, v in extra or {} do
		props[k] = v
	end
	return Builder.part(props)
end

local function bit(room: Room, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, transparency: number?): BasePart
	return Builder.decor({ Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Transparency = transparency or 0, Parent = room.Model })
end

local function spot(room: Room, name: string, cf: CFrame, tags: { string }?, attributes: { [string]: any }?): BasePart
	return Builder.part({ Name = name, Size = V(2, 2, 2), CFrame = cf, Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Tags = tags, Attributes = attributes, Parent = room.Model })
end

local function sign(room: Room, text: string, size: Vector3, cf: CFrame, color: Color3?, textColor: Color3?)
	local p = bit(room, "Sign", size, cf, color or DARK)
	Builder.sign(p, text, Enum.NormalId.Front, textColor)
end

local function seat(room: Room, cf: CFrame, color: Color3?)
	local s = Instance.new("Seat")
	s.Name = "Seat"
	s.Anchored = true
	s.Size = V(2, 1, 2)
	s.CFrame = cf * CFrame.new(0, 1.5, 0)
	s.Color = color or DARK
	s.Material = Enum.Material.Fabric
	s.TopSurface = Enum.SurfaceType.Smooth
	s.Parent = room.Model
	bit(room, "SeatBack", V(2, 2, 0.3), cf * CFrame.new(0, 2.6, 0.9), color or DARK, Enum.Material.Fabric)
end

local function lamp(room: Room, cf: CFrame, color: Color3?, range: number?)
	local p = bit(room, "Lamp", V(4, 0.3, 4), cf, color or rgb(255, 245, 220), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Range = range or 26
	light.Brightness = 1.4
	light.Color = color or rgb(255, 240, 215)
	light.Shadows = false
	light.Parent = p
end

-- Sala vacía: suelo, techo, paredes (puerta de salida en la pared -Z) y luces
local function room(parent: Instance, name: string, cf: CFrame, W: number, D: number, H: number, style: { [string]: any }?): Room
	local m = Instance.new("Model")
	m.Name = "Interior_" .. name
	local r: Room = {
		Model = m,
		W = W,
		D = D,
		H = H,
		at = function(x: number, y: number, z: number): CFrame
			return cf * CFrame.new(x, y, z)
		end,
	}
	local s = style or {}
	local wall = s.Wall or rgb(232, 226, 214)
	solid(r, "Floor", V(W, 1, D), r.at(0, -0.5, 0), s.Floor or rgb(190, 170, 140), s.FloorMaterial or Enum.Material.WoodPlanks)
	solid(r, "Ceiling", V(W, 1, D), r.at(0, H + 0.5, 0), s.Ceiling or WHITE)
	solid(r, "WallBack", V(W, H, 1), r.at(0, H / 2, D / 2 + 0.5), wall)
	solid(r, "WallLeft", V(1, H, D), r.at(-W / 2 - 0.5, H / 2, 0), wall)
	solid(r, "WallRight", V(1, H, D), r.at(W / 2 + 0.5, H / 2, 0), wall)
	local gap = 6
	local side = (W - gap) / 2
	solid(r, "WallFront", V(side, H, 1), r.at(-(gap / 2 + side / 2), H / 2, -D / 2 - 0.5), wall)
	solid(r, "WallFront", V(side, H, 1), r.at(gap / 2 + side / 2, H / 2, -D / 2 - 0.5), wall)
	solid(r, "WallFront", V(gap, H - 9, 1), r.at(0, 9 + (H - 9) / 2, -D / 2 - 0.5), wall)
	-- Puerta (cerrada: pulsar "Salir")
	local door = solid(r, "InteriorExit", V(gap, 9, 0.6), r.at(0, 4.5, -D / 2 - 0.3), s.Door or DARKWOOD, Enum.Material.Wood)
	door:AddTag("InteriorExit")
	bit(r, "DoorHandle", V(0.3, 0.3, 0.4), r.at(2, 4.5, -D / 2 + 0.1), rgb(220, 190, 90), Enum.Material.Metal)
	spot(r, "InteriorEntry", r.at(0, 3, -D / 2 + 4), { "InteriorEntry" })
	-- Luces del techo
	local nx, nz = math.max(1, math.floor(W / 20)), math.max(1, math.floor(D / 20))
	for i = 1, nx do
		for k = 1, nz do
			lamp(r, r.at(-W / 2 + (i - 0.5) * W / nx, H - 0.2, -D / 2 + (k - 0.5) * D / nz), s.Light)
		end
	end
	-- Ventanas falsas (luz de día) en las paredes laterales
	if s.Windows ~= false then
		for k = 1, math.max(1, math.floor(D / 16)) do
			local z = -D / 2 + (k - 0.5) * D / math.max(1, math.floor(D / 16))
			bit(r, "Window", V(0.2, H * 0.4, 6), r.at(-W / 2 + 0.05, H * 0.55, z), rgb(170, 210, 240), Enum.Material.Neon, 0.3)
			bit(r, "Window", V(0.2, H * 0.4, 6), r.at(W / 2 - 0.05, H * 0.55, z), rgb(170, 210, 240), Enum.Material.Neon, 0.3)
		end
	end
	m.Parent = parent
	return r
end

local function elevator(r: Room, x: number, z: number, facing: number?)
	local cf = r.at(x, 0, z) * CFrame.Angles(0, facing or 0, 0)
	bit(r, "ElevatorFrame", V(7, 10, 0.6), cf * CFrame.new(0, 5, 0), STEEL, Enum.Material.Metal)
	bit(r, "ElevatorDoors", V(5, 8.5, 0.2), cf * CFrame.new(0, 4.25, -0.35), rgb(190, 196, 204), Enum.Material.Metal)
	bit(r, "ElevatorLight", V(1.2, 0.6, 0.1), cf * CFrame.new(0, 9.2, -0.4), rgb(120, 220, 255), Enum.Material.Neon)
	Builder.part({ Name = "InteriorElevator", Size = V(6, 8, 2), CFrame = cf * CFrame.new(0, 4, -1.6), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Tags = { "InteriorElevator" }, Parent = r.Model })
end

local function sofa(r: Room, cf: CFrame, color: Color3, width: number?)
	local w = width or 7
	bit(r, "SofaBase", V(w, 1.4, 3), cf * CFrame.new(0, 0.7, 0), color, Enum.Material.Fabric)
	bit(r, "SofaBack", V(w, 2.2, 0.8), cf * CFrame.new(0, 2.2, 1.1), color, Enum.Material.Fabric)
	for x = -w / 2 + 1, w / 2 - 1, 2 do
		local s = Instance.new("Seat")
		s.Name = "SofaSeat"
		s.Anchored = true
		s.Transparency = 1
		s.Size = V(2, 0.4, 2)
		s.CFrame = cf * CFrame.new(x, 1.6, -0.2)
		s.Parent = r.Model
	end
end

local function tableWithChairs(r: Room, cf: CFrame, seats: number?)
	bit(r, "Table", V(5, 0.3, 3), cf * CFrame.new(0, 3, 0), WOOD, Enum.Material.Wood)
	bit(r, "TableLeg", V(0.4, 3, 0.4), cf * CFrame.new(0, 1.5, 0), DARKWOOD, Enum.Material.Wood)
	local n = seats or 4
	for i = 1, n do
		local side = if i % 2 == 0 then 1 else -1
		local x = (math.ceil(i / 2) - (n / 4 + 0.5)) * 2.2
		seat(r, cf * CFrame.new(x, 0, side * 2.6) * CFrame.Angles(0, if side > 0 then 0 else math.pi, 0), DARKWOOD)
	end
end

local function desk(r: Room, cf: CFrame, color: Color3?): BasePart
	local top = bit(r, "Desk", V(5, 3, 2.6), cf * CFrame.new(0, 1.5, 0), color or WOOD, Enum.Material.Wood)
	bit(r, "PC", V(1.6, 1.1, 0.15), cf * CFrame.new(0.8, 3.6, 0.8), DARK)
	bit(r, "PCScreen", V(1.4, 0.9, 0.05), cf * CFrame.new(0.8, 3.6, 0.72), rgb(90, 160, 230), Enum.Material.Neon)
	bit(r, "Papers", V(1.2, 0.15, 0.9), cf * CFrame.new(-1.3, 3.05, 0), WHITE)
	seat(r, cf * CFrame.new(0, 0, -2.2) * CFrame.Angles(0, math.pi, 0), DARK)
	return top
end

local function shelf(r: Room, cf: CFrame, colors: { Color3 }?)
	bit(r, "Shelf", V(8, 7, 2), cf * CFrame.new(0, 3.5, 0), WOOD, Enum.Material.Wood)
	local list = colors or FABRIC
	for row = 0, 2 do
		for k = 0, 5 do
			bit(r, "Item", V(1, 1.4, 1.2), cf * CFrame.new(-3.2 + k * 1.3, 1.4 + row * 2.2, -0.2), list[(row + k) % #list + 1])
		end
	end
end

local function plant(r: Room, cf: CFrame)
	bit(r, "Pot", V(1.6, 1.6, 1.6), cf * CFrame.new(0, 0.8, 0), rgb(170, 90, 60), Enum.Material.Slate)
	local leaves = bit(r, "Leaves", V(3, 3, 3), cf * CFrame.new(0, 3, 0), rgb(70, 130, 60), Enum.Material.Grass)
	leaves.Shape = Enum.PartType.Ball
end

local function rug(r: Room, cf: CFrame, size: Vector3, color: Color3)
	bit(r, "Rug", V(size.X, 0.1, size.Z), cf * CFrame.new(0, 0.06, 0), color, Enum.Material.Fabric)
end

local function counter(r: Room, cf: CFrame, width: number, color: Color3?): BasePart
	local c = solid(r, "Counter", V(width, 3.6, 2.4), cf * CFrame.new(0, 1.8, 0), color or WOOD, Enum.Material.Wood)
	bit(r, "CounterTop", V(width + 0.4, 0.2, 2.8), cf * CFrame.new(0, 3.7, 0), WHITE, Enum.Material.Marble)
	return c
end

local function prompt(part: BasePart, action: string, object: string, hold: number?): ProximityPrompt
	local p = Builder.prompt(part, action, object, hold)
	p.Name = "InteriorPrompt"
	return p
end

---------------------------------------------------------------------
-- Viviendas
---------------------------------------------------------------------
local function homeRooms(r: Room, rich: boolean?)
	local W, D = r.W, r.D
	-- Tabiques: dormitorio y baño al fondo
	solid(r, "Partition", V(W * 0.55, r.H, 0.6), r.at(-W / 2 + W * 0.275, r.H / 2, D * 0.12), r.Model:FindFirstChild("WallBack").Color)
	solid(r, "Partition", V(0.6, r.H, D * 0.38 - 6), r.at(-W * 0.02, r.H / 2, D * 0.12 + (D * 0.38 - 6) / 2 + 6), r.Model:FindFirstChild("WallBack").Color)
	-- Salón
	rug(r, r.at(W * 0.2, 0, -D * 0.15), V(14, 0, 10), rgb(170, 60, 60))
	sofa(r, r.at(W * 0.2, 0, -D * 0.02) * CFrame.Angles(0, math.pi, 0), FABRIC[1])
	bit(r, "TVStand", V(8, 2, 2), r.at(W * 0.2, 1, -D * 0.34), DARKWOOD, Enum.Material.Wood)
	bit(r, "TV", V(7, 4, 0.3), r.at(W * 0.2, 4.2, -D * 0.34), DARK)
	bit(r, "TVScreen", V(6.6, 3.6, 0.1), r.at(W * 0.2, 4.2, -D * 0.34 + 0.2), rgb(40, 90, 140), Enum.Material.Neon)
	shelf(r, r.at(W / 2 - 1.5, 0, 0) * CFrame.Angles(0, math.rad(-90), 0))
	plant(r, r.at(W / 2 - 3, 0, -D / 2 + 3))
	-- Cocina
	local fridge = solid(r, "Fridge", V(3.2, 7, 3), r.at(-W / 2 + 2.2, 3.5, -D / 2 + 4), WHITE, Enum.Material.Metal)
	prompt(fridge, "Picar algo", "🍎 Nevera", 0.8):SetAttribute("Action", "Snack")
	counter(r, r.at(-W / 2 + 1.6, 0, -D / 2 + 11) * CFrame.Angles(0, math.rad(90), 0), 10, rgb(220, 220, 214))
	bit(r, "Stove", V(2.6, 0.2, 2.2), r.at(-W / 2 + 1.6, 3.85, -D / 2 + 13), DARK)
	tableWithChairs(r, r.at(-W * 0.22, 0, -D * 0.2))
	-- Dormitorio
	local bed = solid(r, "Bed", V(6, 2, 8), r.at(-W / 2 + 5, 1, D / 2 - 5), rgb(230, 230, 236), Enum.Material.Fabric)
	bit(r, "Pillow", V(5, 0.8, 1.6), r.at(-W / 2 + 5, 2.4, D / 2 - 1.6), WHITE, Enum.Material.Fabric)
	bit(r, "Blanket", V(6.1, 0.3, 5), r.at(-W / 2 + 5, 2.1, D / 2 - 6.2), FABRIC[2], Enum.Material.Fabric)
	prompt(bed, "Descansar", "🛏 Cama", 1):SetAttribute("Action", "Rest")
	bit(r, "Wardrobe", V(6, 8, 2.4), r.at(-W * 0.18, 4, D / 2 - 1.4), DARKWOOD, Enum.Material.Wood)
	-- Baño
	bit(r, "Shower", V(4, 7, 4), r.at(W / 2 - 3, 3.5, D / 2 - 3), rgb(200, 225, 240), Enum.Material.Glass, 0.5)
	bit(r, "Toilet", V(1.8, 2, 2.4), r.at(W * 0.12, 1, D / 2 - 1.6), WHITE)
	bit(r, "Sink", V(3, 3, 1.6), r.at(W * 0.25, 1.5, D / 2 - 1), WHITE)
	if rich then
		bit(r, "Piano", V(6, 4, 3), r.at(W * 0.36, 2, -D * 0.25), rgb(20, 20, 22))
		plant(r, r.at(-W / 2 + 3, 0, -D * 0.05))
		bit(r, "Chandelier", V(3, 2, 3), r.at(W * 0.2, r.H - 1.5, -D * 0.15), rgb(250, 230, 160), Enum.Material.Neon)
	end
end

function Interiors.Casa(parent: Instance, cf: CFrame): Room
	local r = room(parent, "Casa", cf, 48, 36, 12, { Floor = rgb(176, 140, 100) })
	homeRooms(r)
	return r
end

function Interiors.Villa(parent: Instance, cf: CFrame): Room
	local r = room(parent, "Villa", cf, 64, 44, 14, { Floor = rgb(230, 226, 214), FloorMaterial = Enum.Material.Marble })
	homeRooms(r, true)
	return r
end

function Interiors.Piso(parent: Instance, cf: CFrame): Room
	local r = room(parent, "Piso", cf, 44, 32, 11, { Floor = rgb(186, 150, 110) })
	homeRooms(r)
	-- En los pisos se entra y se sale por el ascensor (no hay puerta a la calle)
	local exit = r.Model:FindFirstChild("InteriorExit") :: BasePart
	exit:RemoveTag("InteriorExit")
	elevator(r, 8, -r.D / 2 + 0.4)
	return r
end

function Interiors.Portal(parent: Instance, cf: CFrame): Room
	local r = room(parent, "Portal", cf, 30, 24, 12, { Floor = rgb(210, 206, 196), FloorMaterial = Enum.Material.Marble, Windows = false })
	for k = 0, 5 do
		bit(r, "Mailbox", V(1.6, 1.2, 0.6), r.at(-r.W / 2 + 2, 4 + (k % 3) * 1.4, -4 + math.floor(k / 3) * 1.8) * CFrame.Angles(0, math.rad(90), 0), rgb(170, 150, 90), Enum.Material.Metal)
	end
	plant(r, r.at(r.W / 2 - 3, 0, -r.D / 2 + 3))
	sofa(r, r.at(r.W / 2 - 2.5, 0, 2) * CFrame.Angles(0, math.rad(-90), 0), FABRIC[4], 6)
	counter(r, r.at(-6, 0, 4), 6, DARKWOOD)
	elevator(r, 0, r.D / 2 - 0.4, math.pi)
	sign(r, "PORTAL · ASCENSOR", V(8, 1.2, 0.2), r.at(0, 10.5, r.D / 2 - 0.2))
	return r
end

---------------------------------------------------------------------
-- Trabajo y ocio
---------------------------------------------------------------------
function Interiors.OficinaLobby(parent: Instance, cf: CFrame): Room
	local r = room(parent, "OficinaLobby", cf, 40, 30, 14, { Floor = rgb(200, 204, 210), FloorMaterial = Enum.Material.Marble })
	counter(r, r.at(0, 0, 0), 12, rgb(60, 70, 90))
	desk(r, r.at(0, 0, 2.5) * CFrame.Angles(0, math.pi, 0))
	sofa(r, r.at(-r.W / 2 + 3, 0, -4) * CFrame.Angles(0, math.rad(90), 0), FABRIC[1])
	plant(r, r.at(r.W / 2 - 3, 0, -r.D / 2 + 3))
	elevator(r, -8, r.D / 2 - 0.4, math.pi)
	elevator(r, 8, r.D / 2 - 0.4, math.pi)
	sign(r, "RECEPCIÓN", V(8, 1.4, 0.2), r.at(0, 8, -1.3), rgb(60, 70, 90))
	return r
end

function Interiors.Oficina(parent: Instance, cf: CFrame): Room
	local r = room(parent, "Oficina", cf, 52, 40, 12, { Floor = rgb(120, 126, 140), FloorMaterial = Enum.Material.Carpet })
	local exit = r.Model:FindFirstChild("InteriorExit") :: BasePart
	exit:RemoveTag("InteriorExit")
	elevator(r, 8, -r.D / 2 + 0.4)
	for row = 0, 1 do
		for k = 0, 3 do
			desk(r, r.at(-18 + k * 10, 0, -6 + row * 10))
		end
	end
	-- Sala de reuniones
	bit(r, "GlassWall", V(18, 11, 0.3), r.at(r.W / 2 - 9, 5.5, r.D / 2 - 10), rgb(200, 225, 240), Enum.Material.Glass, 0.6)
	tableWithChairs(r, r.at(r.W / 2 - 9, 0, r.D / 2 - 5), 6)
	bit(r, "Whiteboard", V(8, 4, 0.2), r.at(-r.W / 2 + 10, 6, r.D / 2 - 0.2), WHITE)
	bit(r, "WaterCooler", V(1.6, 4.4, 1.6), r.at(-r.W / 2 + 2, 2.2, -r.D / 2 + 3), rgb(180, 210, 240))
	plant(r, r.at(r.W / 2 - 3, 0, -r.D / 2 + 3))
	return r
end

function Interiors.Local(parent: Instance, cf: CFrame): Room
	local r = room(parent, "Local", cf, 40, 30, 12, { Floor = rgb(220, 220, 214), FloorMaterial = Enum.Material.Marble })
	for k = 0, 2 do
		shelf(r, r.at(-12 + k * 12, 0, 4))
	end
	counter(r, r.at(r.W / 2 - 6, 0, -r.D / 2 + 7), 8, rgb(170, 60, 60))
	bit(r, "Register", V(1.6, 1, 1.4), r.at(r.W / 2 - 6, 4.3, -r.D / 2 + 7), DARK)
	elevator(r, -r.W / 2 + 5, r.D / 2 - 0.4, math.pi)
	plant(r, r.at(-r.W / 2 + 3, 0, -r.D / 2 + 3))
	return r
end

function Interiors.Nave(parent: Instance, cf: CFrame): Room
	local r = room(parent, "Nave", cf, 70, 50, 22, { Floor = rgb(140, 140, 136), FloorMaterial = Enum.Material.Concrete, Wall = rgb(180, 176, 166), Windows = false })
	for row = 0, 2 do
		local z = -8 + row * 14
		bit(r, "Rack", V(40, 12, 3), r.at(-6, 6, z), rgb(60, 90, 150), Enum.Material.Metal)
		for k = 0, 7 do
			bit(r, "Box", V(3.6, 3, 2.4), r.at(-24 + k * 5, 3.5 + (k % 2) * 4, z), rgb(190, 150, 90), Enum.Material.Cardboard)
		end
	end
	bit(r, "Forklift", V(4, 5, 7), r.at(r.W / 2 - 8, 2.5, -r.D / 2 + 10), rgb(230, 180, 30), Enum.Material.Metal)
	bit(r, "Workbench", V(10, 3, 3), r.at(r.W / 2 - 8, 1.5, r.D / 2 - 4), WOOD, Enum.Material.Wood)
	return r
end

function Interiors.Taller(parent: Instance, cf: CFrame): Room
	local r = room(parent, "Taller", cf, 50, 40, 16, { Floor = rgb(120, 120, 118), FloorMaterial = Enum.Material.Concrete, Windows = false })
	bit(r, "Lift", V(8, 0.6, 14), r.at(-10, 4, 4), rgb(200, 60, 40), Enum.Material.Metal)
	bit(r, "LiftPost", V(1, 5, 1), r.at(-15, 2.5, 4), rgb(200, 60, 40), Enum.Material.Metal)
	bit(r, "Car", V(6, 3, 12), r.at(-10, 5.8, 4), rgb(40, 90, 170), Enum.Material.Metal)
	bit(r, "ToolWall", V(0.3, 8, 16), r.at(r.W / 2 - 0.2, 5, 0), rgb(90, 90, 96), Enum.Material.DiamondPlate)
	bit(r, "Workbench", V(3, 3, 12), r.at(r.W / 2 - 2, 1.5, 0), WOOD, Enum.Material.Wood)
	bit(r, "Tires", V(3, 4, 3), r.at(r.W / 2 - 3, 2, r.D / 2 - 4), DARK)
	return r
end

function Interiors.Ocio(parent: Instance, cf: CFrame): Room
	local r = room(parent, "Ocio", cf, 50, 40, 14, { Floor = rgb(50, 40, 50), Wall = rgb(60, 40, 70), Light = rgb(200, 120, 255), Windows = false })
	counter(r, r.at(-r.W / 2 + 2, 0, 4) * CFrame.Angles(0, math.rad(90), 0), 18, DARKWOOD)
	for k = 0, 4 do
		seat(r, r.at(-r.W / 2 + 5.5, 0, -4 + k * 3.6) * CFrame.Angles(0, math.rad(-90), 0), rgb(160, 40, 60))
	end
	bit(r, "Bottles", V(0.6, 6, 16), r.at(-r.W / 2 + 0.4, 6, 4), rgb(120, 200, 160), Enum.Material.Glass, 0.3)
	for x = 0, 3 do
		for z = 0, 3 do
			bit(r, "DanceTile", V(4, 0.1, 4), r.at(6 + x * 4, 0.06, -2 + z * 4), ({ rgb(255, 60, 120), rgb(60, 160, 255), rgb(255, 220, 60), rgb(120, 255, 120) })[(x + z) % 4 + 1], Enum.Material.Neon)
		end
	end
	bit(r, "DJBooth", V(8, 4, 3), r.at(14, 2, r.D / 2 - 3), DARK)
	for k = 0, 2 do
		tableWithChairs(r, r.at(-6, 0, -r.D / 2 + 8 + k * 9), 2)
	end
	return r
end

function Interiors.Aula(parent: Instance, cf: CFrame): Room
	local r = room(parent, "Aula", cf, 50, 40, 14, { Floor = rgb(170, 150, 120) })
	bit(r, "Board", V(20, 6, 0.3), r.at(0, 7, r.D / 2 - 0.2), rgb(40, 70, 50))
	desk(r, r.at(0, 0, r.D / 2 - 6) * CFrame.Angles(0, math.pi, 0))
	for row = 0, 4 do
		for k = 0, 5 do
			seat(r, r.at(-15 + k * 6, 0, -12 + row * 5) * CFrame.Angles(0, math.pi, 0), rgb(60, 90, 150))
		end
	end
	elevator(r, -r.W / 2 + 5, -r.D / 2 + 0.4)
	return r
end

---------------------------------------------------------------------
-- Monumentos
---------------------------------------------------------------------
function Interiors.Ayuntamiento(parent: Instance, cf: CFrame): Room
	local r = room(parent, "Ayuntamiento", cf, 80, 56, 20, { Floor = rgb(210, 200, 180), FloorMaterial = Enum.Material.Marble })
	for k = 0, 2 do
		counter(r, r.at(-24 + k * 12, 0, -8), 8, DARKWOOD)
	end
	sign(r, "REGISTRO · PADRÓN · LICENCIAS", V(30, 2, 0.2), r.at(-12, 10, -6.6), rgb(90, 40, 40))
	-- Salón de plenos
	bit(r, "Dais", V(24, 2, 8), r.at(0, 1, r.D / 2 - 6), DARKWOOD, Enum.Material.Wood)
	for k = 0, 4 do
		seat(r, r.at(-8 + k * 4, 2, r.D / 2 - 5) * CFrame.Angles(0, math.pi, 0), rgb(120, 30, 40))
	end
	for row = 0, 2 do
		for k = 0, 7 do
			seat(r, r.at(-14 + k * 4, 0, 6 + row * 4) * CFrame.Angles(0, math.pi, 0), rgb(120, 30, 40))
		end
	end
	sign(r, "SALÓN DE PLENOS", V(14, 2, 0.2), r.at(0, 14, r.D / 2 - 0.2), rgb(120, 30, 40))
	return r
end

function Interiors.Museo(parent: Instance, cf: CFrame): Room
	local r = room(parent, "Museo", cf, 90, 60, 20, { Floor = rgb(200, 190, 170), FloorMaterial = Enum.Material.Marble, Wall = rgb(240, 236, 228) })
	local art = { rgb(200, 80, 60), rgb(60, 120, 200), rgb(230, 190, 60), rgb(90, 160, 90), rgb(150, 80, 160) }
	for k = 0, 5 do
		local z = -r.D / 2 + 8 + k * 9
		for _, x in { -r.W / 2 + 0.4, r.W / 2 - 0.4 } do
			bit(r, "Frame", V(0.4, 8, 6), r.at(x, 8, z), rgb(200, 170, 90), Enum.Material.Wood)
			bit(r, "Painting", V(0.5, 7, 5), r.at(x, 8, z), art[k % #art + 1])
		end
	end
	for k = 0, 2 do
		bit(r, "Pedestal", V(4, 4, 4), r.at(-16 + k * 16, 2, 4), WHITE, Enum.Material.Marble)
		local statue = bit(r, "Statue", V(2.4, 6, 2.4), r.at(-16 + k * 16, 7, 4), rgb(220, 216, 206), Enum.Material.Marble)
		statue.Shape = Enum.PartType.Cylinder
		statue.CFrame = r.at(-16 + k * 16, 7, 4) * CFrame.Angles(0, 0, math.rad(90))
	end
	sign(r, "MUSEO DE VALMAR", V(20, 2.6, 0.2), r.at(0, 14, r.D / 2 - 0.2), rgb(40, 40, 44), rgb(240, 210, 130))
	return r
end

function Interiors.Teatro(parent: Instance, cf: CFrame): Room
	local r = room(parent, "Teatro", cf, 80, 70, 26, { Floor = rgb(120, 30, 40), FloorMaterial = Enum.Material.Carpet, Wall = rgb(90, 30, 40), Light = rgb(255, 220, 170), Windows = false })
	bit(r, "Stage", V(56, 4, 18), r.at(0, 2, r.D / 2 - 9), DARKWOOD, Enum.Material.WoodPlanks)
	bit(r, "Curtain", V(56, 20, 1), r.at(0, 14, r.D / 2 - 1), rgb(170, 20, 30), Enum.Material.Fabric)
	for _, x in { -30, 30 } do
		bit(r, "SideCurtain", V(6, 22, 1.4), r.at(x, 11, r.D / 2 - 18), rgb(170, 20, 30), Enum.Material.Fabric)
	end
	for row = 0, 6 do
		for k = 0, 11 do
			seat(r, r.at(-24 + k * 4.4, 0, -r.D / 2 + 10 + row * 4.6) * CFrame.Angles(0, math.pi, 0), rgb(170, 20, 30))
		end
	end
	return r
end

function Interiors.Estacion(parent: Instance, cf: CFrame): Room
	local r = room(parent, "Estacion", cf, 90, 60, 24, { Floor = rgb(200, 196, 188), FloorMaterial = Enum.Material.Marble })
	sign(r, "SALIDAS · 10:15 Norte · 10:30 Playa Dorada · 10:45 Campus", V(34, 5, 0.3), r.at(0, 16, r.D / 2 - 0.3), rgb(20, 20, 24), rgb(255, 200, 60))
	for k = 0, 3 do
		counter(r, r.at(-30 + k * 10, 0, r.D / 2 - 10), 7, rgb(40, 70, 130))
	end
	for row = 0, 2 do
		for k = 0, 5 do
			seat(r, r.at(-15 + k * 6, 0, -12 + row * 8), rgb(60, 90, 150))
		end
	end
	plant(r, r.at(r.W / 2 - 4, 0, -r.D / 2 + 4))
	return r
end

function Interiors.CentroComercial(parent: Instance, cf: CFrame): Room
	local r = room(parent, "CentroComercial", cf, 110, 70, 24, { Floor = rgb(226, 222, 214), FloorMaterial = Enum.Material.Marble })
	local names = { "MODA", "DEPORTES", "JUGUETES", "TECNOLOGÍA", "LIBRERÍA", "PERFUMERÍA" }
	for i, name in names do
		local x = -45 + ((i - 1) % 3) * 45
		local z = if i <= 3 then -r.D / 2 + 8 else r.D / 2 - 8
		local face = if i <= 3 then 0 else math.pi
		local base = r.at(x, 0, z) * CFrame.Angles(0, face, 0)
		bit(r, "ShopFront", V(30, 12, 0.4), base * CFrame.new(0, 6, 4), rgb(200, 225, 240), Enum.Material.Glass, 0.6)
		shelf(r, base * CFrame.new(-6, 0, -2))
		shelf(r, base * CFrame.new(6, 0, -2))
		sign(r, name, V(14, 2, 0.3), base * CFrame.new(0, 13, 4.2), rgb(30, 60, 110))
	end
	bit(r, "Fountain", V(12, 2, 12), r.at(0, 1, 0), rgb(200, 200, 196), Enum.Material.Marble)
	bit(r, "FountainWater", V(10, 0.3, 10), r.at(0, 2.1, 0), rgb(90, 170, 230), Enum.Material.Glass, 0.3)
	elevator(r, r.W / 2 - 6, 0, math.rad(-90))
	return r
end

---------------------------------------------------------------------
-- Instituciones del Estado (siempre montadas: sus oficios y servicios usan sus etiquetas)
---------------------------------------------------------------------
local function cabinet(r: Room, cf: CFrame): BasePart
	local c = solid(r, "Archivo", V(3, 6, 2), cf * CFrame.new(0, 3, 0), STEEL, Enum.Material.Metal)
	for k = 0, 2 do
		bit(r, "Drawer", V(2.6, 1.4, 0.1), cf * CFrame.new(0, 1.2 + k * 1.8, -1.02), rgb(170, 176, 184), Enum.Material.Metal)
	end
	return c
end

local function jobBoard(r: Room, cf: CFrame, jobId: string, title: string)
	for _, x in { -1.9, 1.9 } do
		bit(r, "Post", V(0.3, 6.5, 0.3), cf * CFrame.new(x, 3.25, 0), STEEL, Enum.Material.Metal)
	end
	local board = Builder.part({ Name = "Board", Size = V(4.4, 3, 0.3), CFrame = cf * CFrame.new(0, 4.8, 0), Color = rgb(34, 108, 196), Tags = { "JobBoard" }, Attributes = { JobId = jobId }, Parent = r.Model })
	Builder.sign(board, "SE BUSCA\n" .. title, Enum.NormalId.Front)
	Builder.sign(board, "SE BUSCA\n" .. title, Enum.NormalId.Back)
end

local function flag(r: Room, cf: CFrame)
	bit(r, "FlagPole", V(0.4, 12, 0.4), cf * CFrame.new(0, 6, 0), STEEL, Enum.Material.Metal)
	for i, color in { rgb(200, 40, 40), rgb(240, 200, 40), rgb(200, 40, 40) } do
		bit(r, "Flag", V(4, 0.9, 0.1), cf * CFrame.new(2.2, 11.4 - i * 0.9, 0), color, Enum.Material.Fabric)
	end
end

function Interiors.Juzgado(parent: Instance, cf: CFrame): Room
	local r = room(parent, "Juzgado", cf, 64, 56, 20, { Floor = rgb(150, 110, 80), FloorMaterial = Enum.Material.WoodPlanks, Wall = rgb(214, 204, 186) })
	local back = r.D / 2
	solid(r, "Estrado", V(22, 2, 8), r.at(0, 1, back - 6), DARKWOOD, Enum.Material.Wood)
	solid(r, "JudgeBench", V(16, 3.6, 2.4), r.at(0, 3.8, back - 8.5), rgb(96, 60, 38), Enum.Material.Wood, { Tags = { "Dropoff_Juez" } })
	spot(r, "JudgeSpot", r.at(0, 4, back - 5) * CFrame.Angles(0, math.pi, 0), { "CourtJudge" })
	bit(r, "JudgeChair", V(2.4, 5, 2.2), r.at(0, 4.5, back - 4.2), rgb(90, 30, 40), Enum.Material.Fabric)
	sign(r, "⚖\nJUSTICIA", V(8, 5, 0.2), r.at(0, 12, back - 0.4), rgb(90, 30, 40), rgb(240, 210, 120))
	flag(r, r.at(-9, 2, back - 2))
	solid(r, "Banquillo", V(5, 2.2, 2), r.at(0, 1.1, 2), DARKWOOD, Enum.Material.Wood)
	spot(r, "DockSpot", r.at(0, 3, 0.5), { "CourtDock" })
	for _, x in { -12, 12 } do
		bit(r, "PartyTable", V(8, 3, 3), r.at(x, 1.5, 4), WOOD, Enum.Material.Wood)
		seat(r, r.at(x, 0, 1.5) * CFrame.Angles(0, math.pi, 0), DARK)
	end
	for row = 0, 2 do
		for _, x in { -14, 14 } do
			for k = -2, 2 do
				seat(r, r.at(x + k * 2.6, 0, -r.D / 2 + 7 + row * 4) * CFrame.Angles(0, math.pi, 0), DARKWOOD)
			end
		end
	end
	for k = 0, 2 do
		cabinet(r, r.at(-r.W / 2 + 2, 0, -4 + k * 4) * CFrame.Angles(0, math.rad(90), 0)):AddTag("Pickup_Juez")
	end
	jobBoard(r, r.at(r.W / 2 - 6, 0, -r.D / 2 + 5), "Juez", "JUZGADOS")
	return r
end

function Interiors.Hacienda(parent: Instance, cf: CFrame): Room
	local r = room(parent, "Hacienda", cf, 60, 44, 14, { Floor = rgb(200, 204, 210), FloorMaterial = Enum.Material.Marble })
	local front, back = -r.D / 2, r.D / 2
	solid(r, "TaxWindow", V(16, 3.6, 2.4), r.at(0, 1.8, front + 10), rgb(30, 90, 110), nil, { Tags = { "TaxWindow" } })
	bit(r, "WindowGlass", V(16, 3, 0.12), r.at(0, 5.2, front + 9.4), rgb(200, 225, 240), Enum.Material.Glass, 0.6)
	sign(r, "DECLARACIÓN DE LA RENTA", V(12, 1.4, 0.2), r.at(0, 8, front + 10.6), rgb(30, 90, 110))
	-- Sala de espera (a los lados de la entrada)
	for row = 0, 1 do
		for k = 0, 3 do
			seat(r, r.at(-r.W / 2 + 4 + k * 3, 0, front + 3 + row * 4) * CFrame.Angles(0, math.pi, 0), rgb(30, 90, 110))
		end
	end
	for k = 0, 2 do
		desk(r, r.at(-r.W / 2 + 12 + k * 16, 0, back - 8)):AddTag("Dropoff_Hacienda")
	end
	for k = 0, 2 do
		cabinet(r, r.at(r.W / 2 - 2, 0, front + 18 + k * 4) * CFrame.Angles(0, math.rad(-90), 0)):AddTag("Pickup_Hacienda")
	end
	local board = solid(r, "TreasuryBoard", V(12, 4, 0.3), r.at(-r.W / 4, 8, back - 0.4), rgb(20, 30, 40), nil, { Tags = { "TreasuryBoard" } })
	Builder.sign(board, "TESORO PÚBLICO\n$0 recaudados", Enum.NormalId.Front, rgb(120, 230, 160))
	jobBoard(r, r.at(r.W / 2 - 6, 0, front + 5), "Hacienda", "AGENCIA TRIBUTARIA")
	return r
end

function Interiors.Cuartel(parent: Instance, cf: CFrame): Room
	local r = room(parent, "Cuartel", cf, 90, 70, 18, { Floor = rgb(150, 140, 110), FloorMaterial = Enum.Material.Concrete, Wall = rgb(200, 196, 170), Windows = false })
	local front, back = -r.D / 2, r.D / 2
	-- Armería
	solid(r, "Armeria", V(14, 3.6, 3), r.at(-r.W / 2 + 10, 1.8, front + 8), rgb(70, 76, 60), Enum.Material.Metal, { Tags = { "Pickup_Militar" } })
	sign(r, "ARMERÍA", V(8, 1.2, 0.2), r.at(-r.W / 2 + 10, 6, front + 6.4), rgb(70, 90, 50))
	-- Puestos de guardia e instrucción (circuito cubierto)
	for k, p in { { -25, 0 }, { -25, 20 }, { 25, 20 }, { 25, 0 } } do
		bit(r, "Pad", V(8, 0.2, 8), r.at(p[1], 0.1, p[2]), rgb(200, 180, 60))
		spot(r, "TrainingPost", r.at(p[1], 3, p[2]), { "Dropoff_Militar" }, { Step = k })
		bit(r, "Hurdle", V(6, 2.4, 0.5), r.at(p[1], 1.2, p[2] + 6), rgb(150, 110, 70), Enum.Material.Wood)
	end
	spot(r, "GuardPost", r.at(-6, 3, front + 5), { "Dropoff_Militar" })
	spot(r, "GuardPost", r.at(6, 3, front + 5), { "Dropoff_Militar" })
	-- Galería de tiro
	for k = 0, 3 do
		bit(r, "Target", V(3, 4, 0.3), r.at(r.W / 2 - 4, 4, -12 + k * 6) * CFrame.Angles(0, math.rad(90), 0), rgb(240, 240, 240))
		bit(r, "Bullseye", V(1.2, 1.2, 0.35), r.at(r.W / 2 - 4, 4.4, -12 + k * 6) * CFrame.Angles(0, math.rad(90), 0), rgb(220, 40, 40))
	end
	-- Dormitorio de tropa
	for k = 0, 5 do
		bit(r, "Bunk", V(4, 5, 8), r.at(-30 + k * 7, 2.5, back - 5), rgb(86, 100, 62), Enum.Material.Fabric)
	end
	-- Sala de mando
	bit(r, "MapTable", V(12, 3, 8), r.at(0, 1.5, back - 18), rgb(70, 90, 50))
	bit(r, "Map", V(11, 0.1, 7), r.at(0, 3.06, back - 18), rgb(120, 170, 110))
	flag(r, r.at(0, 0, back - 1.5))
	sign(r, "CUARTEL DEL EJÉRCITO DE VALMAR", V(30, 2.6, 0.2), r.at(0, 14, back - 0.2), rgb(70, 90, 50))
	jobBoard(r, r.at(r.W / 2 - 8, 0, front + 5), "Militar", "EJÉRCITO")
	return r
end

-- Tipos de interior de las plantas de arriba según la sala de la planta baja
Interiors.UpperFloor = {
	Portal = "Piso",
	Local = "Piso",
	OficinaLobby = "Oficina",
	Aula = "Aula",
	CentroComercial = "Local",
}

return Interiors
