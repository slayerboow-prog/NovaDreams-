-- CrowdService: gente en los sitios para que la ciudad nunca se sienta vacía (aunque juegues solo).
--
--   * Salas por dentro (InteriorService.onBuilt): al montarse una sala se llena con su gente y se
--     va con ella (van dentro de su modelo): clientes mirando las estanterías y haciendo cola,
--     gente comiendo en los bares, oficinistas tecleando en su mesa, alumnos y profe en el aula,
--     visitantes mirando cuadros con su vigilante, público en el teatro, viajeros en la estación,
--     mecánico en el taller, camarero en el pub, soldados en el cuartel… (Plans; como mucho Cap
--     por sala y ROOM_CAP en total). Los dependientes de los mostradores los pone InteractService.
--   * Plantas bajas de la ciudad (marcas CrowdSpot de Kit/Decor): clientes, pacientes, lectores…
--     solo en los edificios con algún jugador cerca (CITY_RADIUS) y como mucho CITY_CAP a la vez.
--   * Parques y plazas: gente sentada en los bancos, niños en los columpios (de día), alguien
--     corriendo y alguien paseando al perro; solo cerca de los jugadores (PARK_RADIUS, PARK_CAP).
--   Todos son baratos: anclados, sin colisiones (Npc.create), con su tarea (Npc.work), andando a ratos
--   entre dos puntos (Npc.walkTo), mirando al jugador que se acerca y diciendo algo de vez en cuando.
--   En los móviles y ordenadores modestos (Perf.lite) el cliente quita la mitad (atributo CrowdLite).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Npc = require(script.Parent.Parent.World.Npc)
local Space = require(script.Parent.Parent.World.Space)
local TimeContext = require(game:GetService("ReplicatedStorage").Shared.LifeStory.TimeContext)

local CrowdService = {}

CrowdService.CITY_RADIUS = 110
CrowdService.CITY_CAP = 36
CrowdService.GROUP_CAP = 6
CrowdService.PARK_RADIUS = 160
CrowdService.PARK_CAP = 24
CrowdService.ROOM_CAP = 90
CrowdService.TICK = 2

local rgb = Color3.fromRGB
local PI = math.pi

---------------------------------------------------------------------
-- Frases (bocadillos de vez en cuando)
---------------------------------------------------------------------
local LINES: { [string]: { string } } = {
	Shop = { "¿Tendrán esto en azul?", "Qué precio tan bueno.", "Me lo llevo.", "Solo estoy mirando.", "¿Dónde estará la caja?" },
	Eatery = { "¡Qué rico!", "¿Me trae la cuenta?", "Otro café, por favor.", "Esto está buenísimo." },
	Office = { "Tengo una reunión a las cinco.", "¿Alguien ha visto la grapadora?", "Este informe no se acaba nunca.", "Hoy salgo pronto." },
	Waiting = { "¿Cuánto faltará?", "Voy el siguiente.", "Qué lento va esto…", "Menos mal que traje el móvil." },
	Culture = { "¡Qué bonito!", "Este cuadro es precioso.", "Shhh…", "Me encanta este sitio." },
	Park = { "¡Qué buen día hace!", "Aquí se está de maravilla.", "Me encanta este parque.", "A ver si no llueve." },
	Dog = { "¡Ven aquí, Toby!", "¡No te comas eso!", "Vamos, que es tarde.", "¡Buen chico!" },
	Jog = { "¡Una vuelta más!", "Uf… ¡qué cansancio!", "Buenos días." },
	Kid = { "¡Empújame en el columpio!", "¡Te pillé!", "¡Mira qué alto!", "¡Mamá, mira!" },
	Travel = { "El tren llega en cinco minutos.", "¿Este va a la playa?", "Llevo la maleta a rastras." },
	Work = { "¡A trabajar!", "Esto tiene que estar listo hoy.", "Pásame la llave inglesa." },
	Study = { "Mañana hay examen…", "¿Me dejas los apuntes?", "Esto entra seguro." },
	Generic = { "¡Hola!", "Qué día más bueno.", "Vaya, qué bonito." },
}

---------------------------------------------------------------------
-- Gente en las salas (por tipo de sala)
---------------------------------------------------------------------
type StaffPlan = { Near: string, Work: string?, Name: string, Look: Npc.Look? }
type Plan = {
	Cap: number,
	Context: string,
	Sit: number?,
	SitIn: { string }?, -- nombres de los muebles donde sentarse (Chair, Stool, Sofa, PublicSeat…)
	SitWork: { string }?,
	SitZ: number?, -- solo asientos con z (en la sala) menor que esto (p. ej. el público del juzgado)
	Stand: number?,
	Near: { string }?, -- de pie cerca de estas piezas o muebles
	Works: { string }?,
	Staff: { StaffPlan }?,
	Look: Npc.Look?,
	Wander: boolean?,
}
local SOLDIER = { Shirt = rgb(86, 100, 62), Pants = rgb(70, 80, 56), LongSleeves = true }
local WORKER = { Shirt = rgb(240, 150, 40), Pants = rgb(60, 60, 70) }
local SUIT = { Shirt = rgb(60, 66, 80), Pants = rgb(40, 44, 54), LongSleeves = true }
local PLANS: { [string]: Plan } = {
	Local = { Cap = 4, Context = "Shop", Sit = 1, SitIn = { "Chair", "Stool", "Bench", "Sofa" }, Stand = 2, Near = { "ShopShelf", "Display", "Vitrine", "Washer", "Aquarium", "FruitCrate", "FlowerBucket", "Mat" }, Works = { "Phone", "Carry", "Watch" }, Wander = true },
	OficinaLobby = { Cap = 4, Context = "Office", Sit = 1, SitIn = { "Sofa", "Armchair", "Bench" }, SitWork = { "Phone" }, Stand = 1, Near = { "WaterCooler", "Directory" }, Works = { "Phone", "Clipboard" }, Staff = { { Near = "Turnstile", Work = "Guard", Name = "Vigilante", Look = { Shirt = rgb(55, 55, 60), Pants = rgb(35, 35, 40), LongSleeves = true } } } },
	Oficina = { Cap = 6, Context = "Office", Sit = 4, SitIn = { "OfficeChair" }, SitWork = { "Type", "Type", "Phone" }, Stand = 1, Near = { "WaterCooler", "Printer", "Whiteboard" }, Works = { "Coffee", "Phone", "Clipboard" }, Look = SUIT, Wander = true },
	Nave = { Cap = 4, Context = "Work", Stand = 3, Near = { "Rack", "Pallet", "Workbench", "Forklift" }, Works = { "Carry", "Clipboard", "Hammer" }, Look = WORKER, Wander = true },
	Taller = { Cap = 3, Context = "Work", Sit = 1, SitIn = { "Stool" }, SitWork = { "Phone" }, Staff = { { Near = "CarLift", Work = "Hammer", Name = "Mecánico", Look = { Shirt = rgb(40, 70, 130), Pants = rgb(40, 70, 130), LongSleeves = true } }, { Near = "ToolCart", Work = "Wipe", Name = "Mecánica", Look = { Shirt = rgb(40, 70, 130), Pants = rgb(40, 70, 130), LongHair = true } } } },
	Ocio = { Cap = 6, Context = "Eatery", Sit = 2, SitIn = { "Stool", "Sofa" }, SitWork = { "Coffee" }, Stand = 2, Near = { "HighTable", "Speaker", "DJBooth" }, Works = { "Coffee", "Phone" }, Staff = { { Near = "BackBar", Work = "Wipe", Name = "Camarero", Look = { Shirt = rgb(30, 30, 34), Pants = rgb(30, 30, 34) } } } },
	Aula = { Cap = 7, Context = "Study", Sit = 5, SitIn = { "PublicSeat" }, SitWork = { "Book", "Book", "Phone" }, Staff = { { Near = "Board", Work = "Present", Name = "Profesora", Look = { Shirt = rgb(150, 60, 80), Pants = rgb(50, 50, 60), LongHair = true, LongSleeves = true } } } },
	Ayuntamiento = { Cap = 6, Context = "Waiting", Sit = 4, SitIn = { "PublicSeat" }, SitWork = { "Phone" }, SitZ = 0, Stand = 1, Near = { "TicketMachine" }, Works = { "Clipboard" } },
	Museo = { Cap = 7, Context = "Culture", Sit = 1, SitIn = { "Bench" }, Stand = 5, Near = { "Frame", "Pedestal", "Vitrine", "DinoBase" }, Works = { "Watch", "Watch", "Phone" }, Staff = { { Near = "Stanchion", Work = "Guard", Name = "Vigilante del museo", Look = { Shirt = rgb(55, 55, 60), Pants = rgb(35, 35, 40), LongSleeves = true } } }, Wander = true },
	Teatro = { Cap = 8, Context = "Culture", Sit = 7, SitIn = { "PublicSeat" } },
	Estacion = { Cap = 8, Context = "Travel", Sit = 4, SitIn = { "Bench" }, SitWork = { "Phone", "Book" }, Stand = 3, Near = { "TicketMachine", "Column", "Trolley" }, Works = { "Phone", "Carry", "Watch" }, Wander = true },
	CentroComercial = { Cap = 8, Context = "Shop", Sit = 3, SitIn = { "Bench", "Chair" }, SitWork = { "Coffee", "Phone" }, Stand = 4, Near = { "ShopShelf", "Planter", "Fountain" }, Works = { "Phone", "Carry" }, Wander = true },
	Juzgado = { Cap = 6, Context = "Waiting", Sit = 5, SitIn = { "PublicSeat" }, SitZ = -6 },
	Hacienda = { Cap = 5, Context = "Waiting", Sit = 3, SitIn = { "PublicSeat" }, SitWork = { "Phone" }, Stand = 1, Near = { "TicketMachine" }, Works = { "Clipboard" } },
	Cuartel = { Cap = 5, Context = "Work", Stand = 4, Near = { "MapTable", "Lockers", "Hurdle", "Sandbags" }, Works = { "Guard", "Clipboard", "Guard" }, Look = SOLDIER },
}
CrowdService.Plans = PLANS

---------------------------------------------------------------------
-- Estado
---------------------------------------------------------------------
type Person = { Model: Model, Context: string, Kind: string } -- Kind: "Room" | "City" | "Park"
local people: { Person } = {}
local counts = { Room = 0, City = 0, Park = 0 }
local liteToggle = false
local folder: Folder? = nil

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function playerNear(position: Vector3, radius: number): boolean
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root and (root.Position - position).Magnitude <= radius then
			return true
		end
	end
	return false
end

local function clock(): number
	local ok, t = pcall(function()
		return game:GetService("Lighting").ClockTime
	end)
	return if ok and type(t) == "number" then t else 12
end

local function pick<T>(list: { T }?): T?
	if not list or #list == 0 then
		return nil
	end
	return list[math.random(1, #list)]
end

-- Una persona (anclada, sin colisiones). cf: pies en el suelo; seat: sentarse ahí
local function person(kind: string, parent: Instance, cf: CFrame, context: string, work: string?, look: Npc.Look?, seat: any?): Model?
	local ok, npc = pcall(Npc.create, "Persona", parent, cf, look)
	if not ok or not npc then
		return nil
	end
	npc:SetAttribute("Crowd", kind)
	liteToggle = not liteToggle
	if liteToggle then
		npc:SetAttribute("CrowdLite", true) -- (en los móviles, el cliente quita la mitad)
	end
	if seat then
		pcall(Npc.sit, npc, seat)
		npc:SetAttribute("Seated", true)
	end
	if work then
		pcall(Npc.work, npc, work)
	end
	table.insert(people, { Model = npc, Context = context, Kind = kind })
	counts[kind] = (counts[kind] or 0) + 1
	return npc
end

-- Anda entre sus puntos de vez en cuando (mientras exista)
local function wander(npc: Model, points: { Vector3 }, speed: number, pause: NumberRange?)
	task.spawn(function()
		local i = 1
		local work = npc:GetAttribute("Work")
		while npc.Parent do
			task.wait(if pause then pause.Min + math.random() * (pause.Max - pause.Min) else 4 + math.random() * 6)
			if not npc.Parent then
				break
			end
			i = i % #points + 1
			pcall(Npc.work, npc, nil)
			pcall(Npc.walkTo, npc, { points[i] }, speed)
			pcall(Npc.work, npc, work)
		end
	end)
end

local function prune()
	for i = #people, 1, -1 do
		local p = people[i]
		if not p.Model.Parent then
			counts[p.Kind] -= 1
			table.remove(people, i)
		end
	end
end

function CrowdService.count(kind: string?): number
	prune()
	if kind then
		return counts[kind] or 0
	end
	return #people
end

---------------------------------------------------------------------
-- Salas
---------------------------------------------------------------------
local ROOM_KEEP = { Floor = true, Ceiling = true, WallBack = true, WallLeft = true, WallRight = true, WallFront = true, FloorFinish = true, WallFinish = true, Baseboard = true }

-- Las piezas (o la primera pieza de cada mueble) con esos nombres
local function partsNamed(model: Instance, names: { string }): { BasePart }
	local set = {}
	for _, n in names do
		set[n] = true
	end
	local list = {}
	for _, d in model:GetDescendants() do
		if set[d.Name] then
			if d:IsA("BasePart") then
				table.insert(list, d)
			elseif d:IsA("Model") then
				for _, part in d:GetDescendants() do
					if part:IsA("BasePart") then
						table.insert(list, part)
						break
					end
				end
			end
		end
	end
	return list
end

-- Un sitio libre (en la sala) para una persona de pie cerca de un punto
local function freeNear(space: Space.Space, around: Vector3, radius: number): Vector3?
	local l = space.Frame:PointToObjectSpace(around)
	for ring = 1, 6 do
		local d = ring * radius / 6
		for k = 0, 9 do
			local a = k / 10 * PI * 2 + ring * 0.7
			local x, z = l.X + math.cos(a) * d, l.Z + math.sin(a) * d
			if math.abs(x) < space.HalfX - 1.4 and math.abs(z) < space.HalfZ - 1.4 and space:free(Vector3.new(x, 2.6, z), Vector3.new(2.2, 5, 2.2)) then
				space:addBox(Vector3.new(x, 2.6, z), Vector3.new(2.2, 5, 2.2))
				return space.Frame * Vector3.new(x, 0, z)
			end
		end
	end
	return nil
end

-- Llena una sala con su gente (room: la sala de World/Interiors). Devuelve cuántos ha puesto.
function CrowdService.populate(room: { [string]: any }): number
	local plan = PLANS[room.Kind]
	local model = room.Model :: Model
	if not plan or not model or not model.Parent then
		return 0
	end
	local cap = plan.Cap
	local placed = 0
	local function room_(): boolean
		return placed < cap and (counts.Room or 0) < CrowdService.ROOM_CAP
	end
	-- Lo que ocupa sitio (para no poner a nadie dentro de un mueble)
	local frame = room.at(0, 0, 0)
	local space = Space.new(frame, room.W / 2, room.D / 2, room.H)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and not ROOM_KEEP[part.Name] and (part.Transparency or 0) < 1 then
			space:addPart(part)
		elseif part:IsA("BasePart") and (part.Name == "InteriorEntry" or part.Name == "InteriorElevator" or part.Name == "ClerkSpot") then
			space:addBox(frame:PointToObjectSpace(part.Position), Vector3.new(4, 6, 4))
		end
	end
	space:block(-3, 3, -room.D / 2 - 1, -room.D / 2 + 6)
	local shopId = model:GetAttribute("Shop")
	local eatery = shopId == "Bar" or shopId == "Cafeteria" or shopId == "Pizzeria" or shopId == "Heladeria" or shopId == "Sushi" or shopId == "Hamburgueseria" or shopId == "Kebab"
	local context = if eatery then "Eatery" else plan.Context
	-- Personal (el mecánico junto al elevador, el camarero en la barra, la profe en la pizarra…)
	for _, s in plan.Staff or {} do
		if not room_() then
			break
		end
		local target = partsNamed(model, { s.Near })[1]
		local at = target and freeNear(space, target.Position, 7)
		if at then
			local cf = CFrame.lookAt(at, Vector3.new(target.Position.X, at.Y, target.Position.Z))
			local npc = person("Room", model, cf, "Work", s.Work, s.Look)
			if npc then
				npc.Name = s.Name
				placed += 1
			end
		end
	end
	-- Sentados
	local seats = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Seat") and d.Occupant == nil and not d:GetAttribute("Taken") then
			local owner = d.Parent
			local ok = plan.SitIn == nil
			for _, name in plan.SitIn or {} do
				if owner and owner.Name == name then
					ok = true
				end
			end
			if ok and plan.SitZ then
				ok = frame:PointToObjectSpace(d.Position).Z < plan.SitZ
			end
			if ok then
				table.insert(seats, d)
			end
		end
	end
	for i = #seats, 2, -1 do
		local j = math.random(1, i)
		seats[i], seats[j] = seats[j], seats[i]
	end
	local sitters = (plan.Sit or 0) + (if eatery then 2 else 0)
	for i = 1, math.min(sitters, #seats) do
		if not room_() then
			break
		end
		local seat = seats[i]
		local npc = person("Room", model, seat.CFrame * CFrame.new(0, 0, -2), context, if eatery then "Coffee" else pick(plan.SitWork), plan.Look, seat)
		if npc then
			seat:SetAttribute("Taken", true)
			npc.Destroying:Connect(function()
				if seat.Parent then
					seat:SetAttribute("Taken", nil)
				end
			end)
			placed += 1
		end
	end
	-- De pie (mirando las estanterías, los cuadros, la máquina de turnos…)
	local targets = partsNamed(model, plan.Near or {})
	for _ = 1, plan.Stand or 0 do
		if not room_() then
			break
		end
		local target = pick(targets)
		local at = if target then freeNear(space, target.Position, 6) else nil
		if not at then
			at = freeNear(space, frame.Position + frame.LookVector * -2, math.min(room.W, room.D) / 2)
		end
		if at then
			local look = if target then Vector3.new(target.Position.X, at.Y, target.Position.Z) else at + frame.LookVector * -4
			local cf = CFrame.lookAt(at, look)
			local npc = person("Room", model, cf, context, pick(plan.Works), plan.Look)
			if npc then
				placed += 1
				if plan.Wander and math.random() < 0.5 then
					local other = pick(targets)
					local second = if other then freeNear(space, other.Position, 6) else nil
					if second then
						wander(npc, { at, second }, 5, NumberRange.new(6, 12))
					end
				end
			end
		end
	end
	return placed
end

---------------------------------------------------------------------
-- Plantas bajas de la ciudad (marcas CrowdSpot)
---------------------------------------------------------------------
type Group = { Key: string, Spots: { BasePart }, Center: Vector3, Npcs: { Model }, Context: string }
local groups: { [string]: Group } = {}

local GROUP_CONTEXT = {
	Mall = "Shop", GasShop = "Shop", Lobby = "Office", Library = "Study", Faculty = "Study", Clinic = "Waiting", Police = "Waiting",
	Post = "Waiting", Arcade = "Generic", DrivingSchool = "Study", Burger = "Eatery", Cinema = "Culture",
}

local function addSpot(spot: Instance)
	if not spot:IsA("BasePart") then
		return
	end
	local key = spot:GetAttribute("Group")
	key = if type(key) == "string" then key else "Suelto"
	local g = groups[key]
	if not g then
		local kind = string.match(key, "^(%a+)_") or ""
		g = { Key = key, Spots = {}, Center = spot.Position, Npcs = {}, Context = GROUP_CONTEXT[kind] or "Generic" }
		groups[key] = g
	end
	table.insert(g.Spots, spot)
	local sum = Vector3.zero
	for _, s in g.Spots do
		sum += s.Position
	end
	g.Center = sum / #g.Spots
end

CrowdService.addSpot = addSpot

local function clearGroup(g: Group)
	for _, npc in g.Npcs do
		npc:Destroy()
	end
	table.clear(g.Npcs)
end

local function fillGroup(g: Group)
	local n = 0
	for _, spot in g.Spots do
		if n >= CrowdService.GROUP_CAP or (counts.City or 0) >= CrowdService.CITY_CAP then
			break
		end
		-- (no siempre están todos: unos sitios vacíos y otros no)
		if n == 0 or math.random() < 0.8 then
			local sit = spot:GetAttribute("Pose") == "Sit"
			local work = spot:GetAttribute("Work")
			local cf = spot.CFrame * CFrame.new(0, -spot.Size.Y / 2, 0)
			local npc = person("City", folder or workspace, if sit then spot.CFrame * CFrame.new(0, 0, -2) else cf, g.Context, if type(work) == "string" then work else nil, nil, if sit then spot else nil)
			if npc then
				table.insert(g.Npcs, npc)
				n += 1
			end
		end
	end
end

function CrowdService.tickCity()
	local night = clock() < 7 or clock() >= 23
	for _, g in groups do
		for i = #g.Npcs, 1, -1 do
			if not g.Npcs[i].Parent then
				table.remove(g.Npcs, i)
			end
		end
		local near = not night and playerNear(g.Center, CrowdService.CITY_RADIUS)
		if near and #g.Npcs == 0 then
			fillGroup(g)
		elseif not near and #g.Npcs > 0 and not playerNear(g.Center, CrowdService.CITY_RADIUS + 40) then
			clearGroup(g)
		end
	end
end

---------------------------------------------------------------------
-- Parques y plazas
---------------------------------------------------------------------
type Feature = { Kind: string, Part: BasePart?, Model: Instance, Center: Vector3, Size: Vector3?, Npcs: { Model } }
local features: { Feature } = {}

local PARK_LOOKS = {
	{ Shirt = rgb(230, 80, 60), Pants = rgb(40, 40, 46) },
	{ Shirt = rgb(60, 150, 220), Pants = rgb(30, 30, 34) },
	{ Shirt = rgb(250, 200, 60), Pants = rgb(60, 70, 110) },
}

-- Dónde está el suelo bajo un punto (sin chocar con la gente)
local function groundAt(p: Vector3, fallback: number): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { folder :: any }
	local ok, hit = pcall(function()
		return workspace:Raycast(Vector3.new(p.X, fallback + 20, p.Z), Vector3.new(0, -40, 0), params)
	end)
	return if ok and hit then hit.Position else Vector3.new(p.X, fallback, p.Z)
end

-- Perro de bloques que sigue a su dueño (piezas soldadas a su cuerpo, que se mueve)
local function dog(parent: Instance, cf: CFrame): BasePart
	local m = Instance.new("Model")
	m.Name = "Perro"
	m.Parent = parent
	local color = pick({ rgb(150, 100, 60), rgb(40, 36, 34), rgb(230, 220, 200), rgb(200, 160, 90) }) :: Color3
	local function piece(name: string, size: Vector3, offset: CFrame, c: Color3?): BasePart
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = c or color
		p.Material = Enum.Material.SmoothPlastic
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.CFrame = cf * offset
		p.Parent = m
		return p
	end
	local body = piece("DogBody", Vector3.new(1, 1, 2.2), CFrame.new(0, 1.3, 0))
	body.Anchored = true
	for _, spec in { { "DogHead", Vector3.new(0.9, 0.9, 1), CFrame.new(0, 1.9, -1.3) }, { "DogTail", Vector3.new(0.2, 0.2, 0.9), CFrame.new(0, 1.8, 1.4) } } do
		local p = piece(spec[1], spec[2], spec[3])
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = p
		weld.Parent = p
	end
	for _, lx in { -0.3, 0.3 } do
		for _, lz in { -0.75, 0.75 } do
			local p = piece("DogLeg", Vector3.new(0.3, 0.9, 0.3), CFrame.new(lx, 0.45, lz))
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = p
			weld.Parent = p
		end
	end
	m.PrimaryPart = body
	return body
end

local function spawnFeature(f: Feature)
	local t = clock()
	local parent = folder or workspace
	if f.Kind == "Bench" and f.Part and t >= 8 and t < 22.5 then
		local seat = f.Part
		-- Se sienta en un lado del banco (el otro queda libre para el jugador)
		local side = { CFrame = seat.CFrame * CFrame.new(seat.Size.X / 2 - 1.1, 0, 0), Size = seat.Size }
		local npc = person("Park", parent, seat.CFrame * CFrame.new(0, 0, -2), "Park", pick({ "Book", "Phone", "Knit" }), nil, side)
		if npc then
			table.insert(f.Npcs, npc)
		end
	elseif f.Kind == "Playground" and t >= 9 and t < 20.5 then
		for k = 1, 2 do
			local a = Vector3.new(f.Center.X + (k * 5 - 7.5), f.Center.Y, f.Center.Z + 5)
			local b = Vector3.new(f.Center.X + (k * 4 - 6), f.Center.Y, f.Center.Z - 5)
			local npc = person("Park", parent, CFrame.new(a), "Kid", nil, { Backpack = if k == 1 then rgb(220, 60, 60) else nil })
			if npc then
				npc:SetAttribute("Age", "Nino") -- (se mueven como niños: Controllers/AgeMotion)
				pcall(function()
					npc:ScaleTo(0.62)
				end)
				pcall(Npc.placeFeet, npc, CFrame.new(a))
				table.insert(f.Npcs, npc)
				wander(npc, { a, b }, 8, NumberRange.new(1.5, 4))
			end
		end
	elseif f.Kind == "Park" and f.Size and t >= 7 and t < 22 then
		local hx, hz = math.max(6, f.Size.X / 2 - 8), math.max(6, f.Size.Z / 2 - 8)
		local c = f.Center
		local loop = {}
		for _, q in { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } } do
			table.insert(loop, groundAt(Vector3.new(c.X + q[1] * hx, 0, c.Z + q[2] * hz), c.Y))
		end
		-- Alguien corriendo alrededor del parque
		local jogger = person("Park", parent, CFrame.new(loop[1]), "Jog", nil, pick(PARK_LOOKS))
		if jogger then
			table.insert(f.Npcs, jogger)
			wander(jogger, loop, 13, NumberRange.new(0.05, 0.2))
		end
		-- Alguien paseando al perro de un lado a otro
		local a, b = loop[1]:Lerp(loop[2], 0.3), loop[3]:Lerp(loop[4], 0.7)
		local walker = person("Park", parent, CFrame.new(a), "Dog", nil, nil)
		if walker then
			table.insert(f.Npcs, walker)
			local body = dog(walker, CFrame.new(a + Vector3.new(2, 0, 0)))
			task.spawn(function()
				local points, i = { a, b }, 1
				while walker.Parent do
					task.wait(2 + math.random() * 4)
					if not walker.Parent then
						break
					end
					i = i % 2 + 1
					local goal = points[i]
					local dir = goal - (walker.PrimaryPart and walker.PrimaryPart.Position or goal)
					local side = if dir.Magnitude > 0.1 then Vector3.new(-dir.Unit.Z, 0, dir.Unit.X) * 2 else Vector3.new(2, 0, 0)
					task.spawn(function()
						pcall(Npc.walkTo, walker, { goal }, 4.5)
					end)
					if body.Parent then
						-- El perro va a su lado, un poco por delante
						local from = body.Position
						local target = goal + side + Vector3.new(0, 1.3, 0)
						local steps = math.max(1, math.floor((target - from).Magnitude / 1.5))
						for s = 1, steps do
							if not body.Parent then
								break
							end
							local p = from:Lerp(target, s / steps)
							local flat = (target - from) * Vector3.new(1, 0, 1)
							body.CFrame = if flat.Magnitude > 0.1 then CFrame.lookAt(p, p + flat) else CFrame.new(p)
							task.wait(1.5 / 4.5)
						end
					end
				end
			end)
		end
	end
end

local function clearFeature(f: Feature)
	for _, npc in f.Npcs do
		npc:Destroy()
	end
	table.clear(f.Npcs)
end

function CrowdService.tickParks()
	for _, f in features do
		for i = #f.Npcs, 1, -1 do
			if not f.Npcs[i].Parent then
				table.remove(f.Npcs, i)
			end
		end
		local near = playerNear(f.Center, CrowdService.PARK_RADIUS)
		if near and #f.Npcs == 0 and (counts.Park or 0) < CrowdService.PARK_CAP then
			-- (no en todos los bancos: uno de cada tres, más o menos, y siempre el mismo)
			if f.Kind ~= "Bench" or (math.floor(f.Center.X * 7 + f.Center.Z * 13) % 3 == 0) then
				spawnFeature(f)
			end
		elseif not near and #f.Npcs > 0 and not playerNear(f.Center, CrowdService.PARK_RADIUS + 40) then
			clearFeature(f)
		end
	end
end

local function inside(instance: Instance, names: { [string]: boolean }): boolean
	local node = instance.Parent
	while node and node ~= workspace do
		if names[node.Name] then
			return true
		end
		node = node.Parent
	end
	return false
end

local SKIP = { Interiores = true, Decor = true, StoryScenes = true }

local function addBench(bench: Instance)
	if bench.Name == "BusStop" or inside(bench, SKIP) then
		return
	end
	local seat = bench:FindFirstChild("Seat")
	if seat and seat:IsA("BasePart") then
		table.insert(features, { Kind = "Bench", Part = seat, Model = bench, Center = seat.Position, Npcs = {} })
	end
end

local function scanParks()
	local town = workspace:FindFirstChild("Town")
	if not town then
		return
	end
	for _, d in town:GetDescendants() do
		if d:IsA("Model") then
			if d.Name == "Playground" then
				local floor = d:FindFirstChild("SoftFloor")
				if floor and floor:IsA("BasePart") then
					table.insert(features, { Kind = "Playground", Part = floor, Model = d, Center = floor.Position + Vector3.new(0, floor.Size.Y / 2, 0), Npcs = {} })
				end
			elseif d.Name == "Parque" or d.Name == "Jardin" then
				local ok, cf, size = pcall(function()
					return d:GetBoundingBox()
				end)
				if ok and cf and size and size.X > 30 and size.Z > 30 then
					table.insert(features, { Kind = "Park", Model = d, Center = Vector3.new(cf.Position.X, cf.Position.Y - size.Y / 2 + 0.3, cf.Position.Z), Size = size, Npcs = {} })
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- Bocadillos y miradas
---------------------------------------------------------------------
function CrowdService.bark()
	prune()
	if #people == 0 then
		return
	end
	for _ = 1, 12 do
		local p = people[math.random(1, #people)]
		local root = p.Model.PrimaryPart
		if root and playerNear(root.Position, 45) and not p.Model:GetAttribute("Talking") then
			local lines = LINES[p.Context] or LINES.Generic
			local npc = p.Model
			npc:SetAttribute("Talking", true)
			local hour, weather = TimeContext.now()
			pcall(Npc.say, npc, TimeContext.pick(lines, hour, weather) or lines[math.random(1, #lines)])
			task.delay(3.5, function()
				if npc.Parent then
					pcall(Npc.say, npc, nil)
					npc:SetAttribute("Talking", nil)
				end
			end)
			return
		end
	end
end

-- Los que están de pie miran al jugador que se les acerca
local function lookAtPlayers()
	for _, p in people do
		local root = p.Model.PrimaryPart
		if root and not p.Model:GetAttribute("Seated") then
			for _, player in Players:GetPlayers() do
				local proot = rootOf(player)
				if proot and (proot.Position - root.Position).Magnitude < 7 then
					pcall(Npc.face, p.Model, proot.Position)
					break
				end
			end
		end
	end
end

---------------------------------------------------------------------

function CrowdService.init()
	local f = Instance.new("Folder")
	f.Name = "Gente"
	f.Parent = workspace
	folder = f
	-- Salas: se llenan al montarse (y se vacían con ellas)
	local ok, InteriorService = pcall(function()
		return require(script.Parent.InteriorService) :: any
	end)
	if ok and InteriorService and InteriorService.onBuilt then
		InteriorService.onBuilt(function(inst)
			if inst.Room then
				task.spawn(CrowdService.populate, inst.Room)
			end
		end)
	end
	for _, spot in CollectionService:GetTagged("CrowdSpot") do
		addSpot(spot)
	end
	CollectionService:GetInstanceAddedSignal("CrowdSpot"):Connect(addSpot)
	for _, bench in CollectionService:GetTagged("Bench") do
		addBench(bench)
	end
	task.defer(scanParks)
	task.spawn(function()
		local beat = 0
		while true do
			task.wait(CrowdService.TICK)
			beat += 1
			local okCity, err = pcall(CrowdService.tickCity)
			if not okCity then
				warn("[CrowdService] " .. tostring(err))
			end
			local okParks, err2 = pcall(CrowdService.tickParks)
			if not okParks then
				warn("[CrowdService] " .. tostring(err2))
			end
			pcall(lookAtPlayers)
			if beat % 3 == 0 then
				pcall(CrowdService.bark)
			end
		end
	end)
end

return CrowdService
