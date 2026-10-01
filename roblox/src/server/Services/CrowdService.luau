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
--   Las salas siguen su horario (ROOM_HOURS): cerradas no se llenan y, al cerrar, su gente se va por
--   la puerta. Aparecen y se van fundiéndose (atributos FadeIn / FadeOut, Controllers/ActorLife).
--   En los móviles y ordenadores modestos (Perf.lite) el cliente quita la mitad (atributo CrowdLite).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Npc = require(script.Parent.Parent.World.Npc)
local Space = require(script.Parent.Parent.World.Space)
local TimeContext = require(game:GetService("ReplicatedStorage").Shared.LifeStory.TimeContext)
local OpeningHours = require(game:GetService("ReplicatedStorage").Shared.OpeningHours)
local Floors = require(game:GetService("ReplicatedStorage").Shared.Floors)
local Ground = require(game:GetService("ReplicatedStorage").Shared.Ground)
local Pets = require(game:GetService("ReplicatedStorage").Shared.Pets)

local CrowdService = {}

CrowdService.CITY_RADIUS = 110
CrowdService.CITY_CAP = 36
CrowdService.GROUP_CAP = 6
CrowdService.PARK_RADIUS = 160
CrowdService.PARK_CAP = 24
CrowdService.ROOM_CAP = 90
CrowdService.TICK = 2
CrowdService.LEAVE_SEEN = 20 -- al cerrar, cada uno se va cuando no hay ningún jugador a menos de esto

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
	Hours: { number }?, -- horario de la sala (nil = siempre abierta)
	StaffAlways: boolean?, -- su personal está también cerrada (el vigilante de la recepción)
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

-- Horario de cada sala (hora del juego). Antes no había ninguno: a las 3 de la mañana el museo o las
-- oficinas estaban llenos. Las tiendas y bares del tipo Local usan el de su tienda (OpeningHours).
local ROOM_HOURS: { [string]: { number } } = {
	Local = { 9.5, 21.5 },
	OficinaLobby = { 7.5, 21 },
	Oficina = { Floors.OpenFrom, Floors.OpenTo },
	Nave = { 7, 20 },
	Taller = { 8, 20 },
	Ocio = { 12, 3 }, -- (pubs y discotecas: hasta las 3)
	Aula = { 8, 21 },
	Ayuntamiento = { 8.5, 20 },
	Museo = { 10, 20 },
	Teatro = { 11, 24 },
	Estacion = { 5.5, 1 },
	CentroComercial = { 10, 22 },
	Juzgado = { 8.5, 20 },
	Hacienda = { 8.5, 20 },
	-- Cuartel: siempre
}
local EATERY_HOURS = { 7.5, 1.5 } -- bares, cafeterías y restaurantes (Local)
PLANS.OficinaLobby.StaffAlways = true
for kind, hours in ROOM_HOURS do
	if PLANS[kind] then
		PLANS[kind].Hours = hours
	end
end

---------------------------------------------------------------------
-- Estado
---------------------------------------------------------------------
-- Kind: "Room" | "City" | "Park". En las salas: Hours (su horario), Exit (la puerta), Floor (altura del
-- suelo) y Stay (se queda aunque cierre: el vigilante)
type Person = { Model: Model, Context: string, Kind: string, Hours: { number }?, Exit: Vector3?, Floor: number?, Stay: boolean? }
local people: { Person } = {}
local byModel: { [Model]: Person } = setmetatable({}, { __mode = "k" }) :: any
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
	pcall(Npc.vary, npc) -- (unos más altos y otros más bajos)
	npc:SetAttribute("Crowd", kind)
	npc:SetAttribute("FadeIn", true) -- (el cliente lo funde al llegar: no aparece de golpe)
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
	local record: Person = { Model = npc, Context = context, Kind = kind }
	table.insert(people, record)
	byModel[npc] = record
	counts[kind] = (counts[kind] or 0) + 1
	return npc
end

-- Deja de contar (ya se está yendo): fuera de la lista y de los topes
local function forget(npc: Model)
	local record = byModel[npc]
	byModel[npc] = nil
	local i = record and table.find(people, record)
	if i then
		table.remove(people, i)
		counts[record.Kind] -= 1
	end
end

-- Se va: anda unos pasos (hacia `to`, o lejos del jugador más cercano) y se desvanece. Antes se
-- borraba de golpe a 21 studs del jugador, a la vista.
local function fadeAway(npc: Model, to: Vector3?)
	forget(npc)
	if not npc.Parent then
		return
	end
	npc:SetAttribute("Leaving", true)
	pcall(Npc.work, npc, nil)
	local root = npc.PrimaryPart
	local goal = to
	if root and not goal then
		local away = Vector3.zero
		local best = math.huge
		for _, player in Players:GetPlayers() do
			local proot = rootOf(player)
			if proot and (proot.Position - root.Position).Magnitude < best then
				best = (proot.Position - root.Position).Magnitude
				away = root.Position - proot.Position
			end
		end
		away = Vector3.new(away.X, 0, away.Z)
		local dir = if away.Magnitude > 0.1 then away.Unit else root.CFrame.LookVector * Vector3.new(1, 0, 1)
		local humanoid = npc:FindFirstChildOfClass("Humanoid")
		local height = (if humanoid then humanoid.HipHeight else 2) + root.Size.Y / 2
		goal = root.Position - Vector3.new(0, height, 0) + (if dir.Magnitude > 0.1 then dir.Unit else Vector3.new(1, 0, 0)) * 6
	end
	if root and goal and not npc:GetAttribute("Seated") then
		task.spawn(function()
			pcall(Npc.walkTo, npc, { goal :: Vector3 }, 5)
		end)
	end
	task.delay(if goal then 0.9 else 0, function()
		if npc.Parent then
			npc:SetAttribute("FadeOut", true)
		end
	end)
	task.delay(if goal then 1.6 else 0.7, function()
		if npc.Parent then
			npc:Destroy()
		end
	end)
end

-- Anda entre sus puntos de vez en cuando (mientras exista). Cada uno a su paso (±15 %; los que corren,
-- solo algo más rápido, para que no pasen de correr a andar: Controllers/ActorLife)
local function wander(npc: Model, points: { Vector3 }, speed: number, pause: NumberRange?)
	speed *= if speed >= 10 then 1 + math.random() * 0.12 else 0.85 + math.random() * 0.3
	task.spawn(function()
		local i = 1
		local work = npc:GetAttribute("Work")
		while npc.Parent do
			task.wait(if pause then pause.Min + math.random() * (pause.Max - pause.Min) else 4 + math.random() * 6)
			if not npc.Parent or npc:GetAttribute("Leaving") then
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
			byModel[p.Model] = nil
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

-- Cuánta gente de aquí hay a menos de radius de un punto (PlaceLifeService lo suma a su presupuesto)
function CrowdService.nearCount(position: Vector3, radius: number): number
	local n = 0
	for _, p in people do
		local root = p.Model.PrimaryPart
		if root and p.Model.Parent and (root.Position - position).Magnitude <= radius then
			n += 1
		end
	end
	return n
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
	local shopId = model:GetAttribute("Shop")
	local eatery = shopId == "Bar" or shopId == "Cafeteria" or shopId == "Pizzeria" or shopId == "Heladeria" or shopId == "Sushi" or shopId == "Hamburgueseria" or shopId == "Kebab"
	-- Su horario: cerrada, sin clientes (solo el personal de guardia, si lo hay)
	local hours = plan.Hours
	if room.Kind == "Local" then
		hours = if eatery then (OpeningHours.forShop(shopId) or EATERY_HOURS) else (OpeningHours.forShop(shopId) or plan.Hours)
	end
	local isOpen = OpeningHours.isOpen(hours, clock())
	if not isOpen and not plan.StaffAlways then
		return 0
	end
	local cap = if isOpen then plan.Cap else #(plan.Staff or {})
	local placed = 0
	local function room_(): boolean
		return placed < cap and (counts.Room or 0) < CrowdService.ROOM_CAP
	end
	-- Lo que se apunta de cada persona de la sala (para irse por la puerta al cerrar)
	local frame0 = room.at(0, 0, 0)
	local exitPart = partsNamed(model, { "InteriorEntry" })[1]
	local exit = if exitPart then Vector3.new(exitPart.Position.X, frame0.Position.Y, exitPart.Position.Z) else nil
	local function note(npc: Model, staff: boolean)
		local record = byModel[npc]
		if record then
			record.Hours = hours
			record.Exit = exit
			record.Floor = frame0.Position.Y
			record.Stay = staff and plan.StaffAlways == true
		end
	end
	-- Ropa sin repetir (o el uniforme de la sala con el tono un poco cambiado)
	local outfits = Npc.outfits(plan.Cap + 2)
	local dealt = 0
	local function lookFor(): Npc.Look?
		dealt += 1
		return if plan.Look then Npc.tint(plan.Look) else outfits[dealt]
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
			local npc = person("Room", model, cf, "Work", s.Work, Npc.tint(s.Look, 0.05))
			if npc then
				npc.Name = s.Name
				note(npc, true)
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
	local sitters = if isOpen then (plan.Sit or 0) + (if eatery then 2 else 0) else 0
	for i = 1, math.min(sitters, #seats) do
		if not room_() then
			break
		end
		local seat = seats[i]
		local npc = person("Room", model, seat.CFrame * CFrame.new(0, 0, -2), context, if eatery then "Coffee" else pick(plan.SitWork), lookFor(), seat)
		if npc then
			note(npc, false)
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
	for _ = 1, if isOpen then plan.Stand or 0 else 0 do
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
			local npc = person("Room", model, cf, context, pick(plan.Works), lookFor())
			if npc then
				note(npc, false)
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

-- Al cerrar, la gente de las salas se levanta y se va por la puerta (alguno lo dice); el personal de
-- guardia (Stay) se queda. Antes seguían ahí toda la noche.
function CrowdService.tickRooms()
	local t = clock()
	local said: { [Instance]: boolean } = {}
	for i = #people, 1, -1 do
		local p = people[i]
		if p and p.Kind == "Room" and p.Hours and not p.Stay and p.Model.Parent and not OpeningHours.isOpen(p.Hours, t) then
			local npc = p.Model
			local room = npc.Parent
			if room and not said[room] then
				said[room] = true
				pcall(Npc.say, npc, "Uy, que cierran. ¡Me voy!", 3)
			end
			if npc:GetAttribute("Seated") then
				local root = npc.PrimaryPart
				if root then
					pcall(Npc.stand, npc, Vector3.new(root.Position.X, p.Floor or root.Position.Y, root.Position.Z))
				end
				npc:SetAttribute("Seated", nil)
			end
			fadeAway(npc, p.Exit)
		end
	end
end

---------------------------------------------------------------------
-- Plantas bajas de la ciudad (marcas CrowdSpot)
---------------------------------------------------------------------
type Group = { Key: string, Kind: string, Spots: { BasePart }, Center: Vector3, Npcs: { Model }, Context: string, Closing: boolean? }
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
		g = { Key = key, Kind = kind, Spots = {}, Center = spot.Position, Npcs = {}, Context = GROUP_CONTEXT[kind] or "Generic" }
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
	for i = #g.Spots, 1, -1 do
		if not g.Spots[i].Parent then
			table.remove(g.Spots, i) -- (marca quitada del mapa: ya no hay sitio ahí)
		end
	end
	local outfits = Npc.outfits(CrowdService.GROUP_CAP) -- (ropa sin repetir en el grupo)
	for _, spot in g.Spots do
		if n >= CrowdService.GROUP_CAP or (counts.City or 0) >= CrowdService.CITY_CAP then
			break
		end
		-- (no siempre están todos: unos sitios vacíos y otros no)
		if n == 0 or math.random() < 0.8 then
			local sit = spot:GetAttribute("Pose") == "Sit"
			local work = spot:GetAttribute("Work")
			local cf = spot.CFrame * CFrame.new(0, -spot.Size.Y / 2, 0)
			local npc = person("City", folder or workspace, if sit then spot.CFrame * CFrame.new(0, 0, -2) else cf, g.Context, if type(work) == "string" then work else nil, outfits[n + 1], if sit then spot else nil)
			if npc then
				table.insert(g.Npcs, npc)
				n += 1
			end
		end
	end
end

-- Cierra (o se hace de noche) con jugadores cerca: dejan lo que hacían, alguno lo dice, y cada uno
-- se va cuando no tiene a ningún jugador al lado: echa a andar y se desvanece (fadeAway)
local function closing(list: { Model }, first: boolean, line: string)
	for i = #list, 1, -1 do
		local npc = list[i]
		local root = npc.PrimaryPart
		if first then
			pcall(Npc.work, npc, nil)
			if i == 1 and root then
				pcall(Npc.say, npc, line, 4)
			end
		end
		if not root or not playerNear(root.Position, CrowdService.LEAVE_SEEN) then
			if root then
				fadeAway(npc)
			else
				npc:Destroy()
			end
			table.remove(list, i)
		end
	end
end

-- ¿Hay gente ahora en ese sitio? Su horario (shared/OpeningHours: sin dependiente no hay clientes);
-- los de 24 horas, de noche (23:00-7:00) casi vacíos como siempre
local function groupOpen(g: Group, t: number): boolean
	local hours = OpeningHours.forPlace(g.Kind)
	if hours then
		return OpeningHours.isOpen(hours, t)
	end
	return not (t < 7 or t >= 23)
end
CrowdService._groupOpen = groupOpen

function CrowdService.tickCity()
	local t = clock()
	for _, g in groups do
		for i = #g.Npcs, 1, -1 do
			if not g.Npcs[i].Parent then
				table.remove(g.Npcs, i)
			end
		end
		local open = groupOpen(g, t)
		local near = playerNear(g.Center, CrowdService.CITY_RADIUS)
		if not open then
			if #g.Npcs > 0 then
				if near then
					closing(g.Npcs, not g.Closing, "Uy, que cierran. ¡Me voy!")
					g.Closing = true
				else
					clearGroup(g)
				end
			end
		elseif near and #g.Npcs == 0 then
			g.Closing = nil
			fillGroup(g)
		elseif not near and #g.Npcs > 0 and not playerNear(g.Center, CrowdService.CITY_RADIUS + 40) then
			clearGroup(g)
		end
	end
end

---------------------------------------------------------------------
-- Parques y plazas
---------------------------------------------------------------------
type Feature = { Kind: string, Part: BasePart?, Model: Instance, Center: Vector3, Size: Vector3?, Npcs: { Model }, Closing: boolean? }

-- Horas con gente en cada sitio del parque (fuera de ellas se van: nadie en los columpios de madrugada;
-- los niños, a casa a las 19:30)
local FEATURE_HOURS = { Bench = { 8, 22.5 }, Playground = { 9, 19.5 }, Park = { 7, 22 } }

-- ¿Con este tiempo hay gente? Con tormenta nadie; con lluvia o nieve, ni en los columpios ni en los bancos
local function weatherOk(kind: string): boolean
	local _, weather = TimeContext.now()
	if weather == "Tormenta" or weather == "Storm" then
		return false
	end
	local wet = weather == "Lluvia" or weather == "Rain" or weather == "Nieve" or weather == "Snow"
	return not (wet and (kind == "Playground" or kind == "Bench"))
end
CrowdService._weatherOk = weatherOk
local features: { Feature } = {}

local PARK_LOOKS = {
	{ Shirt = rgb(230, 80, 60), Pants = rgb(40, 40, 46) },
	{ Shirt = rgb(60, 150, 220), Pants = rgb(30, 30, 34) },
	{ Shirt = rgb(250, 200, 60), Pants = rgb(60, 70, 110) },
}

-- Dónde está el suelo bajo un punto (sin chocar con la gente). Solo vale suelo de verdad: el terreno
-- o una superficie plana y sólida cerca de la altura del parque; las copas de los árboles, farolas,
-- toldos o piezas sin colisión se atraviesan (si no, el corredor iba flotando por encima de un árbol).
local function groundAt(p: Vector3, fallback: number): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip: { Instance } = { folder :: any }
	params.FilterDescendantsInstances = skip
	local from = Vector3.new(p.X, fallback + 20, p.Z)
	for _ = 1, 8 do
		local ok, hit = pcall(function()
			return workspace:Raycast(from, Vector3.new(0, -40, 0), params)
		end)
		if not ok or not hit then
			break
		end
		local part = hit.Instance
		local solid = part:IsA("Terrain") or (part:IsA("BasePart") and part.CanCollide and Ground.skipOf(part) == nil) -- (ni coches ni personas)
		if solid and hit.Normal.Y > 0.8 and hit.Position.Y < fallback + 4 then
			return hit.Position
		end
		table.insert(skip, part)
		params.FilterDescendantsInstances = skip
	end
	return Vector3.new(p.X, fallback, p.Z)
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
	if not OpeningHours.isOpen(FEATURE_HOURS[f.Kind], t) or not weatherOk(f.Kind) then
		return
	end
	if f.Kind == "Bench" and f.Part then
		local seat = f.Part
		-- Se sienta en un lado del banco (el otro queda libre para el jugador)
		local side = { CFrame = seat.CFrame * CFrame.new(seat.Size.X / 2 - 1.1, 0, 0), Size = seat.Size }
		local npc = person("Park", parent, seat.CFrame * CFrame.new(0, 0, -2), "Park", pick({ "Book", "Phone", "Knit" }), nil, side)
		if npc then
			table.insert(f.Npcs, npc)
		end
	elseif f.Kind == "Playground" then
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
				-- (corren: con su tamaño, bien por encima de lo que ActorLife cuenta como correr)
				wander(npc, { a, b }, 10, NumberRange.new(1.5, 4))
			end
		end
		-- Un adulto (madre o padre) vigilando a los niños desde un lado
		local watch = Vector3.new(f.Center.X - 9, f.Center.Y, f.Center.Z + 7)
		local parentNpc = person("Park", parent, CFrame.lookAt(watch, Vector3.new(f.Center.X, watch.Y, f.Center.Z)), "Park", pick({ "Phone", "Watch", "Coffee" }), nil)
		if parentNpc then
			table.insert(f.Npcs, parentNpc)
		end
	elseif f.Kind == "Park" and f.Size then
		local hx, hz = math.max(6, f.Size.X / 2 - 8), math.max(6, f.Size.Z / 2 - 8)
		local c = f.Center
		local loop = {}
		for _, q in { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } } do
			table.insert(loop, groundAt(Vector3.new(c.X + q[1] * hx, 0, c.Z + q[2] * hz), c.Y))
		end
		-- Alguien corriendo alrededor del parque
		local jogger = person("Park", parent, CFrame.new(loop[1]), "Jog", nil, Npc.tint(pick(PARK_LOOKS)))
		if jogger then
			table.insert(f.Npcs, jogger)
			-- (15: lejos del límite andar/correr de ActorLife, 13, para que no parpadee entre los dos)
			wander(jogger, loop, 15, NumberRange.new(0.05, 0.2))
		end
		-- Alguien paseando al perro de un lado a otro
		local a, b = loop[1]:Lerp(loop[2], 0.3), loop[3]:Lerp(loop[4], 0.7)
		local walker = person("Park", parent, CFrame.new(a), "Dog", nil, nil)
		if walker then
			table.insert(f.Npcs, walker)
			local body = dog(walker, CFrame.new(a + Vector3.new(2, 0, 0)))
			-- Con correa: de su mano al collar (shared/Pets.leash). Ningún perro va suelto
			local head = body.Parent and body.Parent:FindFirstChild("DogHead") :: BasePart?
			local hand = (walker:FindFirstChild("RightHand") or walker:FindFirstChild("Right Arm")) :: BasePart?
			if head and hand then
				pcall(Pets.leash, hand, CFrame.new(0, if hand.Name == "RightHand" then -0.2 else -0.9, 0), head, CFrame.new(0, -0.3, 0.45))
			end
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
						-- El perro va a su lado, un poco por delante: se desliza seguido (antes iba a
						-- saltos de 1,5 studs)
						local from = body.Position
						local target = goal + side + Vector3.new(0, 1.3, 0)
						local flat = (target - from) * Vector3.new(1, 0, 1)
						local turn = if flat.Magnitude > 0.1 then CFrame.lookAt(from, from + flat).Rotation else body.CFrame.Rotation
						body.CFrame = CFrame.new(from) * turn
						local time = (target - from).Magnitude / 4.5
						local ok = pcall(function()
							TweenService:Create(body, TweenInfo.new(math.max(time, 0.05), Enum.EasingStyle.Linear), { CFrame = CFrame.new(target) * turn }):Play()
						end)
						if not ok then
							body.CFrame = CFrame.new(target) * turn
						end
						task.wait(time)
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
	local t = clock()
	for _, f in features do
		for i = #f.Npcs, 1, -1 do
			if not f.Npcs[i].Parent then
				table.remove(f.Npcs, i)
			end
		end
		local near = playerNear(f.Center, CrowdService.PARK_RADIUS)
		local late = not OpeningHours.isOpen(FEATURE_HOURS[f.Kind], t)
		if #f.Npcs > 0 and (late or not weatherOk(f.Kind)) then
			-- Se hace tarde (o llega la tormenta): se van a casa (sin esfumarse delante de nadie)
			if near then
				closing(f.Npcs, not f.Closing, if not late then "¡Que llueve! ¡A casa!" elseif f.Kind == "Playground" then "¡Mamá, ya voy!" else "Uy, qué tarde. ¡A casa!")
				f.Closing = true
			else
				clearFeature(f)
			end
		elseif near and #f.Npcs == 0 and (counts.Park or 0) < CrowdService.PARK_CAP then
			f.Closing = nil
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

-- Los que están de pie miran al jugador que se les acerca y, cuando se va, vuelven a lo suyo (antes
-- se quedaban mirando a la nada, o a la pared)
local homeLook: { [Model]: Vector3 } = setmetatable({}, { __mode = "k" }) :: any
local function lookAtPlayers()
	for _, p in people do
		local npc = p.Model
		local root = npc.PrimaryPart
		if not root or npc:GetAttribute("Seated") or npc:GetAttribute("Leaving") then
			continue
		end
		if Npc.isWalking(npc) then
			homeLook[npc] = nil -- (andando ya mira hacia donde va)
			continue
		end
		local seen = nil
		for _, player in Players:GetPlayers() do
			local proot = rootOf(player)
			if proot and (proot.Position - root.Position).Magnitude < (if homeLook[npc] then 9 else 7) then
				seen = proot.Position
				break
			end
		end
		if seen then
			if not homeLook[npc] then
				local look = root.CFrame.LookVector
				homeLook[npc] = Vector3.new(look.X, 0, look.Z)
			end
			pcall(Npc.face, npc, seen)
		elseif homeLook[npc] then
			local look = homeLook[npc]
			homeLook[npc] = nil
			pcall(Npc.face, npc, root.Position + look * 4)
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
			local okRooms, err3 = pcall(CrowdService.tickRooms)
			if not okRooms then
				warn("[CrowdService] " .. tostring(err3))
			end
			pcall(lookAtPlayers)
			if beat % 3 == 0 then
				pcall(CrowdService.bark)
			end
		end
	end)
end

return CrowdService
