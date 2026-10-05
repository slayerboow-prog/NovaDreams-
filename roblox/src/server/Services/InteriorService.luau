-- InteriorService: todos los edificios del mapa se pueden visitar por dentro.
--
--   * Al arrancar busca cada edificio de la ciudad (casas, villas, bloques de pisos, oficinas,
--     comercios, naves, talleres, locales de ocio, facultades y los monumentos) y le pone en la
--     puerta un cartel "Entrar" con lo que hay dentro.
--   * Al entrar se monta su interior (World/Interiors) en una zona oculta, lejos de la ciudad, y
--     te lleva allí; "Salir" te devuelve a la calle, delante de la puerta. Las salas se quitan
--     solas cuando se quedan vacías (así el móvil no carga 900 interiores a la vez).
--   * Los edificios de varias plantas (bloques de pisos, oficinas, facultades, comercios con pisos,
--     la residencia) son un edificio de verdad por dentro (World/Tower, shared/Floors): portal con la
--     puerta a la calle, escalera que se sube andando (dos tramos por planta, con descansillo y el
--     número de la planta) y ascensor. En cada planta, un pasillo con puertas numeradas (3ºA, 3ºB…,
--     Oficina 301, Hab. 204): cada puerta lleva a su vivienda, oficina, aula o local, que se monta
--     al entrar (y al salir vuelves al pasillo, delante de su puerta). Solo están montadas las
--     plantas a ±2 de algún jugador; las demás se montan al subir o bajar y se quitan al alejarse.
--     Clave de la sala (atributo InteriorKey): "id:T" la escalera y los pasillos, "id:3B" una puerta.
--   * Quién vive detrás de cada puerta: un jugador (PropertyService), vecinos ("Llamar": contestan y
--     a veces te dejan pasar), en venta ("Visitar"), una empresa (abierta de 8:00 a 20:00), "SE
--     ALQUILA", la tienda de la calle o las aulas.
--   * El ascensor lleva a cualquier planta (panel del cliente, InteriorUI).
--     En la Torre de Valmar se puede subir a la azotea (la de verdad, con vistas).
--   * Las casas de dos plantas tienen su escalera por dentro y arriba un pasillo con habitaciones.
--   * Los edificios que ya tienen planta baja de verdad (tiendas, colegio, hospital, comisaría…)
--     solo ganan el ascensor a sus plantas de arriba.
--   * Cada sala sale amueblada y decorada a su manera (World/Interiors con World/Furniture), con un
--     número fijo por edificio y planta: cada casa es distinta, pero siempre la misma. Sus muebles se
--     usan (sentarse, camas, tele, luces, nevera, grifos, ducha, puertas…): InteractService.
--   * Instituciones del Estado dentro de edificios que ya existen (con su cartel en la fachada):
--     Palacio de Justicia y Agencia Tributaria en Valmar Centro, y el Cuartel del Ejército en una
--     nave industrial. Sus salas están siempre montadas (los oficios y servicios usan sus etiquetas).
-- Mientras estás dentro, el atributo InteriorDoor dice dónde está la puerta (PositionService lo
-- usa para que al volver a entrar al juego aparezcas en la calle, no en una sala que ya no existe).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Floors = require(ReplicatedStorage.Shared.Floors)
local Ground = require(ReplicatedStorage.Shared.Ground)
local MapInfo = require(ReplicatedStorage.Shared.MapInfo)
local Interiors = require(script.Parent.Parent.World.Interiors)
local Tower = require(script.Parent.Parent.World.Tower)
local Lift = require(script.Parent.Parent.World.Lift)
local Builder = require(script.Parent.Parent.World.Builder)
local Entrances = require(script.Parent.Parent.World.Entrances)
local StoryMarks = require(script.Parent.Parent.World.Kit.StoryMarks)
local SceneService = require(script.Parent.SceneService)

local InteriorService = {}

export type Building = {
	Id: number,
	Key: string, -- nombre fijo (por su posición): sirve para guardar a quién pertenece
	Model: Model,
	Kind: string, -- tipo de la sala de la planta baja (Interiors.X)
	Upper: string?, -- tipo de las plantas de arriba
	Floors: number,
	Title: string,
	Door: Vector3, -- en la calle, delante de la puerta
	Out: Vector3, -- hacia fuera
	Walkable: boolean, -- la planta baja de verdad se puede recorrer (solo ascensor)
	Shop: string?, -- comercios: lo que pone su cartel (el interior va a juego: farmacia, banco, bar…)
	Roof: Vector3?, -- azotea de verdad (Torre de Valmar)
	Persistent: boolean?,
	Residence: boolean?, -- residencia universitaria (bloque del campus con habitaciones)
	District: string?, -- Id del distrito ("" fuera de ellos; se calcula la primera vez: districtOf)
}
-- Edificio de varias plantas montado: sus plantas (solo las que están cerca de alguien)
-- Ascensor de verdad (World/Lift): la cabina, en qué planta está, si se mueve y las llamadas pendientes
export type LiftState = { Cabin: Lift.Cabin, Floor: number, Moving: boolean, DoorsOpen: boolean, Queue: { number }, OpenedAt: number, Busy: boolean }
export type TowerState = { Plan: Tower.Plan, Origin: CFrame, Built: { [number]: Tower.Built }, Lift: LiftState? }
export type Instance_ = {
	Room: Interiors.Room,
	Slot: number,
	Building: Building,
	Floor: number,
	Unit: string?, -- letra de la puerta ("A", "B"…; "T" = escalera y pasillos)
	EmptySince: number?,
	Tower: TowerState?,
}

-- Enganches para las viviendas (PropertyService)
export type Hooks = {
	Gate: ((Player, Building, number, string?) -> (boolean, string?))?, -- ¿puede entrar en esa planta o puerta?
	Occupant: ((Building, Floors.Unit) -> { Type: string, Name: string?, UserId: number? })?, -- quién vive detrás de una puerta
	Decorate: ((Instance_) -> ())?, -- al montar una sala (vecinos, cartel de se vende…)
	Enter: ((Player, Instance_) -> ())?, -- al entrar alguien
	Labels: ((Building) -> { [number]: string })?, -- qué pone en el ascensor junto a cada planta
	Doorbell: ((Player, Building, number, string?) -> boolean)?, -- timbre de la casa de otro jugador (true = lo atiende)
	NeighborAnswer: ((Building, Floors.Unit, number) -> (boolean, string?))?, -- ¿contesta el vecino a esa hora?
}
InteriorService.Hooks = {} :: Hooks

local SKY_Y = 6000 -- las salas están aquí arriba, lejos de todo
local SLOT = 220
local EMPTY_SECONDS = 30

local buildings: { [number]: Building } = {}
local instances: { [string]: Instance_ } = {}
local elevatorOpen: { [Player]: { At: number, Position: Vector3? } } = {} -- ascensor abierto por cada jugador (dónde y cuándo)
local freeSlots: { number } = {}
local nextSlot = 0
local folder: Folder
local Remote: RemoteEvent
local Notify: RemoteEvent
local GRID = 100
local roadGrid: { [string]: { BasePart } } = {}
local boxGrid: { [string]: { { CFrame: CFrame, Size: Vector3, Model: Model } } } = {}

local function cellKey(x: number, z: number): string
	return math.floor(x / GRID) .. "," .. math.floor(z / GRID)
end

-- Mete algo en todas las celdas que ocupa (en planta)
local function addToGrid(grid: { [string]: { any } }, item: any, center: Vector3, halfX: number, halfZ: number)
	for x = math.floor((center.X - halfX) / GRID), math.floor((center.X + halfX) / GRID) do
		for z = math.floor((center.Z - halfZ) / GRID), math.floor((center.Z + halfZ) / GRID) do
			local key = x .. "," .. z
			local list = grid[key]
			if not list then
				list = {}
				grid[key] = list
			end
			table.insert(list, item)
		end
	end
end

---------------------------------------------------------------------
-- Qué hay dentro de cada edificio
---------------------------------------------------------------------
-- (la regla es de World/Entrances: la misma que usan las pruebas con el mapa construido)
local signText = Entrances.signText
local classify = Entrances.classify

local function boundingBox(model: Model): (CFrame?, Vector3?)
	local ok, cf, size = pcall(function()
		return model:GetBoundingBox()
	end)
	if ok then
		return cf, size
	end
	return nil, nil
end

-- Distancia (en planta) a la calzada más cercana (piezas Road/Junction/Rotonda del mapa)
local function roadDistance(point: Vector3): number
	local best = math.huge
	local cx, cz = math.floor(point.X / GRID), math.floor(point.Z / GRID)
	for x = cx - 2, cx + 2 do
		for z = cz - 2, cz + 2 do
			for _, road in roadGrid[x .. "," .. z] or {} do
				local l = road.CFrame:PointToObjectSpace(Vector3.new(point.X, road.Position.Y, point.Z))
				local dx = math.max(0, math.abs(l.X) - road.Size.X / 2)
				local dz = math.max(0, math.abs(l.Z) - road.Size.Z / 2)
				best = math.min(best, math.sqrt(dx * dx + dz * dz))
			end
		end
	end
	return best
end

-- ¿Ese punto cae dentro de otro edificio? (una puerta no puede dar contra la pared del vecino)
local function insideOther(point: Vector3, own: Model): boolean
	for _, box in boxGrid[cellKey(point.X, point.Z)] or {} do
		if box.Model ~= own then
			local l = box.CFrame:PointToObjectSpace(Vector3.new(point.X, box.CFrame.Position.Y, point.Z))
			if math.abs(l.X) < box.Size.X / 2 and math.abs(l.Z) < box.Size.Z / 2 then
				return true
			end
		end
	end
	return false
end

local function groundAt(position: Vector3): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { folder }
	-- (desde poco más arriba de la puerta: desde muy alto daría con toldos y balcones)
	local hit = Ground.cast(position + Vector3.new(0, 6, 0), Vector3.new(0, -40, 0), params)
	return if hit then hit.Position else position
end

-- Dónde está la puerta: la pieza "Door" si la hay; si no, la fachada que da a la calle más cercana
local function findDoor(model: Model, cf: CFrame, size: Vector3): (Vector3, Vector3)
	local center = cf.Position
	local doorPart = Entrances.doorPart(model)
	if doorPart then
		-- (hacia fuera: el atributo DoorOut del kit, o del centro hacia la puerta)
		local out = Entrances.doorOut(doorPart, center) or cf.LookVector
		return Vector3.new(doorPart.Position.X, center.Y - size.Y / 2, doorPart.Position.Z), out
	end
	local faces = {
		{ cf.LookVector, size.Z / 2 },
		{ -cf.LookVector, size.Z / 2 },
		{ cf.RightVector, size.X / 2 },
		{ -cf.RightVector, size.X / 2 },
	}
	local bestPoint, bestOut, bestDistance = center, cf.LookVector, math.huge
	for _, face in faces do
		local out = Vector3.new(face[1].X, 0, face[1].Z)
		if out.Magnitude > 0.1 then
			out = out.Unit
			local point = center + out * face[2]
			local distance = roadDistance(point)
			if insideOther(point + out * 4, model) then
				distance += 10000 -- pegada a otro edificio: solo si no hay otra
			end
			if distance < bestDistance then
				bestPoint, bestOut, bestDistance = point, out, distance
			end
		end
	end
	return Vector3.new(bestPoint.X, center.Y - size.Y / 2, bestPoint.Z), bestOut
end

---------------------------------------------------------------------
-- Salas (montar, entrar, salir, quitar)
---------------------------------------------------------------------
local function slotPosition(slot: number): Vector3
	local perRow = 24
	return Vector3.new(((slot % perRow) - perRow / 2) * SLOT, SKY_Y, (math.floor(slot / perRow) - 6) * SLOT)
end

local function takeSlot(): number
	local slot = table.remove(freeSlots)
	if slot then
		return slot
	end
	nextSlot += 1
	return nextSlot
end

local connectRoom -- se define más abajo
local builtListeners: { (Instance_) -> () } = {}

local function notifyBuilt(inst: Instance_)
	for _, listener in builtListeners do
		local ok, err = pcall(listener, inst)
		if not ok then
			warn("[Interiores] " .. tostring(err))
		end
	end
end

-- ¿Se sube por dentro (escalera, pasillo y puertas)? Los bloques, oficinas, facultades y comercios
-- de varias plantas. (Las casas de dos plantas llevan su escalera dentro de la casa.)
local function isTower(building: Building): boolean
	return Floors.isTower(building.Upper, building.Floors) and not building.Persistent
end
InteriorService.isTower = isTower

-- La puerta (unidad) de ese edificio: planta y letra
function InteriorService.unitOf(building: Building, floor: number, letter: string?): Floors.Unit?
	return Floors.unit(building.Key, building.Kind, building.Upper, floor, letter)
end

-- Sala de una unidad (vivienda, oficina, aula, tienda) o de la planta de un edificio de una sala
local function unitInstance(building: Building, floor: number, letter: string?): Instance_?
	local unitId = Floors.unitId(floor, letter)
	local key = building.Id .. ":" .. unitId
	local existing = instances[key]
	if existing and existing.Room.Model.Parent then
		return existing
	end
	local kind
	if isTower(building) then
		local unit = InteriorService.unitOf(building, floor, letter)
		kind = unit and unit.Kind
	else
		kind = if floor == 0 then building.Kind else (building.Upper or "Piso")
	end
	local builder = kind and (Interiors :: any)[kind]
	if not builder then
		return nil
	end
	local slot = takeSlot()
	-- (la semilla de los muebles: el mismo edificio y la misma puerta, siempre igual)
	local r = builder(folder, CFrame.new(slotPosition(slot)), {
		Seed = building.Key .. ":" .. unitId,
		Floor = floor,
		Floors = building.Floors,
		Single = kind == "Dorm" and Floors.dormSingle(building.Key, unitId),
		Shop = if floor == 0 then building.Shop else nil, -- (comercios: el interior va con su cartel)
	})
	r.Model:SetAttribute("Key", key)
	local inst: Instance_ = { Room = r, Slot = slot, Building = building, Floor = floor, Unit = letter or "A", EmptySince = nil }
	instances[key] = inst
	connectRoom(inst)
	local decorate = InteriorService.Hooks.Decorate
	if decorate then
		local ok, err = pcall(decorate, inst)
		if not ok then
			warn("[Interiores] " .. tostring(err))
		end
	end
	notifyBuilt(inst)
	return inst
end

local function instanceOf(building: Building, floor: number): Instance_?
	return unitInstance(building, floor, nil)
end

-- Avisa cada vez que se monta una sala o una planta de un edificio (y ahora mismo, de las que ya
-- están montadas)
function InteriorService.onBuilt(listener: (Instance_) -> ())
	table.insert(builtListeners, listener)
	for _, inst in instances do
		if inst.Room.Model.Parent then
			if inst.Tower then
				for floor, built in inst.Tower.Built do
					task.spawn(listener, { Room = { Model = built.Model, Kind = "Tower" } :: any, Slot = inst.Slot, Building = inst.Building, Floor = floor, Unit = "T" })
				end
			else
				task.spawn(listener, inst)
			end
		end
	end
end

-- La sala montada con esa clave ("id:planta", "id:3B" o "id:T" para la escalera y los pasillos)
function InteriorService.fromKey(key: string): Instance_?
	local inst = instances[key]
	return if inst and inst.Room.Model.Parent then inst else nil
end

local function entryOf(inst: Instance_): Vector3
	local entry = inst.Room.Model:FindFirstChild("InteriorEntry", true) :: BasePart?
	if entry then
		return entry.Position
	end
	local elevator = inst.Room.Model:FindFirstChild("InteriorElevator") :: BasePart?
	return if elevator then elevator.Position + elevator.CFrame.LookVector * -3 else slotPosition(inst.Slot) + Vector3.new(0, 3, 0)
end

-- inLift = true: vale ir dentro del ascensor (el panel de la cabina se usa en marcha)
local function busy(player: Player, inLift: boolean?): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid == nil or humanoid.Health <= 0 or humanoid.SeatPart ~= nil or player:GetAttribute("OnTrial") == true or player:GetAttribute("JailUntil") ~= nil
		-- (en pleno viaje de ascensor no se salta a otro sitio: la cabina te volvería a meter)
		or (not inLift and player:GetAttribute("LiftTower") ~= nil)
end

-- Jugadores a mitad de un salto (mientras teleportTo espera a que cargue el sitio nuevo)
local teleporting: { [Player]: number } = {}

-- Lleva al jugador a un punto. Deja de ir en el ascensor (si no, la cabina lo recogería al llegar)
-- y, mientras dura el salto, stepTowers no mira su altura (aún está en la sala de antes).
local function teleport(player: Player, target: Vector3)
	player:SetAttribute("LiftTower", nil)
	teleporting[player] = (teleporting[player] or 0) + 1
	player:SetAttribute("Teleporting", true)
	-- Fundido a negro en su pantalla un momento antes del salto (sin él, es un corte en seco)
	if Notify then
		Notify:FireClient(player, "Travel", "")
		task.wait(0.35)
	end
	pcall(SceneService.teleportTo, player, target)
	local left = (teleporting[player] or 1) - 1
	teleporting[player] = if left > 0 then left else nil
	if left <= 0 and player.Parent then
		player:SetAttribute("Teleporting", nil)
	end
end

---------------------------------------------------------------------
-- Edificios de varias plantas: escalera, pasillos y puertas (World/Tower)
---------------------------------------------------------------------
local connectFloor -- se define más abajo

-- Quién hay detrás de una puerta: { Type, Name } (Owner/Neighbor/ForSale de PropertyService;
-- Company/ForRent en las oficinas; Business la tienda de la calle; Shop los locales de arriba;
-- Public las aulas)
function InteriorService.occupant(building: Building, unit: Floors.Unit): { Type: string, Name: string?, UserId: number? }
	if unit.Kind == "Dorm" then
		return { Type = "Dorm", Name = if Floors.dormSingle(building.Key, unit.Id) then "Individual" else "Compartida" }
	elseif unit.Kind == "Piso" then
		local hook = InteriorService.Hooks.Occupant
		if hook then
			local ok, result = pcall(hook, building, unit)
			if ok and type(result) == "table" then
				return result
			end
		end
		return { Type = "ForSale" }
	elseif unit.Kind == "Oficina" then
		local company = Floors.company(building.Key, unit.Id)
		return if company then { Type = "Company", Name = company } else { Type = "ForRent" }
	elseif unit.Ground then
		return { Type = "Business", Name = if unit.Kind == "Aula" then "Facultad" else building.Title }
	elseif unit.Kind == "Local" then
		local shops = Interiors.Shops
		local shop = shops[Floors.hash(building.Key .. unit.Id) % #shops + 1]
		return { Type = "Shop", Name = shop.Title }
	end
	return { Type = "Public", Name = if unit.Kind == "Aula" then "Facultad" else nil }
end

local function plateNames(building: Building, floor: number): { [string]: string }
	local names = {}
	for _, unit in Floors.units(building.Key, building.Kind, building.Upper, floor) do
		local occ = InteriorService.occupant(building, unit)
		names[unit.Id] = if occ.Type == "ForSale" then "SE VENDE" elseif occ.Type == "ForRent" then "SE ALQUILA" else (occ.Name or "")
	end
	return names
end

-- El distrito del edificio (Id de CityPlan.Districts: Centro, Norte, Oeste…; nil fuera de ellos).
-- Da el estilo del portal y los pasillos (World/Tower.Themes).
function InteriorService.districtOf(building: Building): string?
	if building.District == nil then
		local ok, d = pcall(MapInfo.districtAt, building.Door.X, building.Door.Z)
		building.District = if ok and d then d.Id else ""
	end
	return if building.District ~= "" then building.District else nil
end

local function towerOf(building: Building, create: boolean): Instance_?
	local key = building.Id .. ":T"
	local existing = instances[key]
	if existing and existing.Room.Model.Parent then
		return existing
	end
	if not create then
		return nil
	end
	local plan = Tower.plan(building.Key, building.Title, building.Kind, building.Upper :: string, building.Floors, InteriorService.districtOf(building))
	local slot = takeSlot()
	local origin = CFrame.new(slotPosition(slot))
	local model = Instance.new("Model")
	model.Name = "Interior_Tower"
	model:SetAttribute("Key", key)
	model:SetAttribute("Floors", building.Floors)
	model.Parent = folder
	local room = {
		Model = model,
		W = plan.W,
		D = Floors.Depth,
		H = Floors.Height * building.Floors,
		at = function(x: number, y: number, z: number): CFrame
			return origin * CFrame.new(x, y, z)
		end,
		Kind = "Tower",
		Spots = {},
	}
	local inst: Instance_ = {
		Room = room :: any,
		Slot = slot,
		Building = building,
		Floor = 0,
		Unit = "T",
		EmptySince = nil,
		Tower = { Plan = plan, Origin = origin, Built = {} },
	}
	-- La cabina del ascensor (en la planta baja, con las puertas cerradas)
	local okLift, cabin = pcall(Lift.build, model, origin * Tower.shaftBase(plan))
	if okLift then
		(inst.Tower :: TowerState).Lift = { Cabin = cabin, Floor = 0, Moving = false, DoorsOpen = false, Queue = {}, OpenedAt = 0, Busy = false }
		-- Botonera de dentro: el panel de plantas (InteriorUI, con quién vive en cada una)
		local panel = Builder.prompt(cabin.Panel, "Elegir planta", "🛗 Ascensor", 0)
		panel.MaxActivationDistance = 6
		panel.Triggered:Connect(function(player)
			InteriorService.openElevator(player, building)
		end)
	else
		warn("[Interiores] ascensor: " .. tostring(cabin))
	end
	instances[key] = inst
	return inst
end

-- Monta una planta (y la conecta: ascensor, puertas, calle)
local function buildFloor(inst: Instance_, floor: number)
	local t = inst.Tower :: TowerState
	if t.Built[floor] then
		return
	end
	local built = Tower.buildFloor(inst.Room.Model, t.Origin, t.Plan, floor, plateNames(inst.Building, floor))
	t.Built[floor] = built
	connectFloor(inst, floor, built)
	if InteriorService.afterFloor then
		InteriorService.afterFloor(inst, floor)
	end
	notifyBuilt({ Room = { Model = built.Model, Kind = "Tower" } :: any, Slot = inst.Slot, Building = inst.Building, Floor = floor, Unit = "T" })
end

local function dropFloor(inst: Instance_, floor: number)
	local t = inst.Tower :: TowerState
	local built = t.Built[floor]
	if built then
		built.Model:Destroy()
		t.Built[floor] = nil
	end
end

-- Deja montadas las plantas que hacen falta para quien está en esas plantas (y quita las lejanas)
local function streamFloors(inst: Instance_, playerFloors: { number })
	local t = inst.Tower :: TowerState
	local build, keep = Floors.wanted(playerFloors, t.Plan.Top)
	for floor in build do
		buildFloor(inst, floor)
	end
	for floor in t.Built do
		if not keep[floor] then
			dropFloor(inst, floor)
		end
	end
end
InteriorService.streamFloors = streamFloors

---------------------------------------------------------------------
-- Ascensor de verdad: se llama desde el rellano, se entra, se elige planta y sube o baja con quien
-- vaya dentro (el cliente lo mueve fluido con las mismas cuentas: Controllers/LiftRide)
---------------------------------------------------------------------
local TweenService = game:GetService("TweenService")

local function tweenPart(part: BasePart, goal: CFrame)
	local ok = pcall(function()
		TweenService:Create(part, TweenInfo.new(Lift.DoorSeconds * 0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { CFrame = goal }):Play()
	end)
	if not ok then
		part.CFrame = goal
	end
end

local function landingDoors(inst: Instance_, floor: number): { BasePart }
	local t = inst.Tower :: TowerState
	local built = t.Built[floor]
	local left, right = nil, nil
	if built then
		for _, d in built.Model:GetDescendants() do
			if d:IsA("BasePart") and d:HasTag("LiftLandingDoor") then
				if d:GetAttribute("Side") == -1 then
					left = d
				else
					right = d
				end
			end
		end
	end
	return if left and right then { left, right } else {}
end

-- Lo que dice la pantalla: "PB" en la planta baja, el número en las demás (con flecha si se mueve)
local function liftLabel(floor: number, dir: number?): string
	local text = if floor == 0 then "PB" else tostring(floor)
	if dir and dir > 0 then
		return "▲ " .. text
	elseif dir and dir < 0 then
		return "▼ " .. text
	end
	return text
end

local function textOf(part: Instance?): TextLabel?
	for _, d in (part and part:GetDescendants()) or {} do
		if d:IsA("TextLabel") then
			return d
		end
	end
	return nil
end

local function liftDisplays(inst: Instance_, text: string)
	local t = inst.Tower :: TowerState
	local lift = t.Lift :: LiftState
	if lift.Cabin.Display then
		lift.Cabin.Display.Text = text
	end
	for _, built in t.Built do
		local label = textOf(built.Model:FindFirstChild("ElevatorFloor"))
		if label then
			label.Text = text
		end
	end
end

-- Quién va dentro de la cabina ahora (y a qué altura sobre su suelo)
local function liftRiders(inst: Instance_): { { Player: Player, Offset: Vector3, Character: Model? } }
	local t = inst.Tower :: TowerState
	local lift = t.Lift :: LiftState
	local floorCf = lift.Cabin.Base * CFrame.new(0, lift.Cabin.Model:GetAttribute("Height") or 0, 0)
	local out = {}
	local key = inst.Building.Id .. ":T"
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("InteriorKey") ~= key then
			continue
		end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			local rel = floorCf:PointToObjectSpace(root.Position)
			if Lift.inside(rel) then
				-- (se apunta el personaje: si muere o reaparece en el viaje, ya no se le coloca)
				table.insert(out, { Player = player, Offset = root.Position - floorCf.Position, Character = player.Character })
			end
		end
	end
	return out
end

-- ¿Hay alguien en la puerta? (no se cierra encima de nadie)
local function doorwayBlocked(inst: Instance_): boolean
	local t = inst.Tower :: TowerState
	local lift = t.Lift :: LiftState
	local floorCf = lift.Cabin.Base * CFrame.new(0, lift.Cabin.Model:GetAttribute("Height") or 0, 0)
	local key = inst.Building.Id .. ":T"
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("InteriorKey") == key then
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				local rel = floorCf:PointToObjectSpace(root.Position)
				if math.abs(rel.X) < 2.6 and rel.Y > -1 and rel.Y < 8 and rel.Z < -Lift.Depth / 2 + 1 and rel.Z > -Lift.Depth / 2 - 1.4 then
					return true
				end
			end
		end
	end
	return false
end

local function setLiftDoors(inst: Instance_, open: boolean)
	local t = inst.Tower :: TowerState
	local lift = t.Lift :: LiftState
	Lift.setDoors(lift.Cabin.Doors, open, tweenPart)
	Lift.setDoors(landingDoors(inst, lift.Floor), open, tweenPart)
	lift.DoorsOpen = open
	lift.Cabin.Model:SetAttribute("Doors", if open then "Open" else "Closed")
	if open then
		lift.OpenedAt = os.clock()
	end
end

local function serverNow(): number
	local ok, now = pcall(function()
		return (workspace :: any):GetServerTimeNow()
	end)
	return if ok and type(now) == "number" then now else os.clock()
end

local liftTravel: (Instance_, number) -> ()

-- Pide el ascensor a una planta (desde el rellano o desde dentro). Si ya está ahí, abre.
local function callLift(inst: Instance_, floor: number)
	local t = inst.Tower :: TowerState
	local lift = t.Lift
	if not lift then
		return
	end
	if lift.Busy then
		if not table.find(lift.Queue, floor) and floor ~= lift.Floor then
			table.insert(lift.Queue, floor)
		end
		return
	end
	if lift.Floor == floor then
		if not lift.DoorsOpen then
			setLiftDoors(inst, true)
		else
			lift.OpenedAt = os.clock()
		end
		return
	end
	task.spawn(liftTravel, inst, floor)
end
InteriorService.callLift = callLift

liftTravel = function(inst: Instance_, target: number)
	local t = inst.Tower :: TowerState
	local lift = t.Lift :: LiftState
	lift.Busy = true
	-- Cerrar (si hay alguien en la puerta, se espera un poco)
	if lift.DoorsOpen then
		local waited = 0
		while doorwayBlocked(inst) and waited < 6 do
			waited += task.wait(0.5)
		end
		setLiftDoors(inst, false)
		task.wait(Lift.DoorSeconds)
	end
	local from = lift.Floor
	local duration = Lift.duration(from, target)
	local riders = liftRiders(inst)
	local model = lift.Cabin.Model
	model:SetAttribute("LiftFrom", from)
	model:SetAttribute("LiftTo", target)
	model:SetAttribute("LiftDuration", duration)
	model:SetAttribute("LiftStart", serverNow())
	model:SetAttribute("Moving", true)
	for _, r in riders do
		r.Player:SetAttribute("LiftTower", inst.Building.Id .. ":T")
	end
	local start = os.clock()
	local dir = if target > from then 1 else -1
	while true do
		local elapsed = os.clock() - start
		local h = Lift.heightAt(from, target, elapsed, duration)
		Lift.place(lift.Cabin, h)
		liftDisplays(inst, liftLabel(math.floor(h / Floors.Height + 0.5), dir))
		if elapsed >= duration or not model.Parent then
			break
		end
		task.wait()
	end
	local towerKey = inst.Building.Id .. ":T"
	if not model.Parent then
		-- La cabina ya no existe (se quitó el edificio): nadie sigue "dentro" y el ascensor queda libre
		for _, r in riders do
			if r.Player:GetAttribute("LiftTower") == towerKey then
				r.Player:SetAttribute("LiftTower", nil)
			end
		end
		lift.Busy = false
		return
	end
	Lift.place(lift.Cabin, target * Floors.Height)
	lift.Floor = target
	model:SetAttribute("Floor", target)
	model:SetAttribute("Moving", false)
	-- La planta de llegada, montada (si va alguien dentro: un viaje solo con vecinos NPC no monta
	-- plantas); y quien iba dentro, en su sitio (el cliente ya lo ha llevado; si no, se le coloca)
	if #riders > 0 then
		buildFloor(inst, target)
	end
	local floorCf = lift.Cabin.Base * CFrame.new(0, target * Floors.Height, 0)
	for _, r in riders do
		-- Solo quien sigue en el viaje: si murió, reapareció o lo llevaron a otro sitio, se le deja
		local still = r.Player.Character == r.Character and r.Player:GetAttribute("InteriorKey") == towerKey and r.Player:GetAttribute("LiftTower") == towerKey
		local root = if still and r.Character then r.Character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if root then
			local want = floorCf.Position + r.Offset
			if (root.Position - want).Magnitude > 2 then
				root.CFrame = CFrame.new(want) * (root.CFrame - root.CFrame.Position)
			end
		end
		if r.Player:GetAttribute("LiftTower") == towerKey then
			r.Player:SetAttribute("LiftTower", nil)
		end
		if still then
			r.Player:SetAttribute("TowerFloor", target)
		end
	end
	liftDisplays(inst, liftLabel(target))
	setLiftDoors(inst, true)
	lift.Busy = false
	-- Siguiente llamada pendiente
	local nextFloor = table.remove(lift.Queue, 1)
	if nextFloor then
		task.delay(2.5, function()
			if model.Parent then
				callLift(inst, nextFloor)
			end
		end)
	end
end

-- Puertas que llevan mucho abiertas: se cierran solas (si no hay nadie en medio)
local function stepLifts()
	for _, inst in instances do
		local lift = inst.Tower and inst.Tower.Lift
		if lift and lift.DoorsOpen and not lift.Busy and os.clock() - lift.OpenedAt > Lift.DwellSeconds and not doorwayBlocked(inst) then
			setLiftDoors(inst, false)
		end
	end
end
InteriorService.stepLifts = stepLifts

-- Una planta que se acaba de montar: sus puertas de rellano y su pantalla, como esté el ascensor
function InteriorService.afterFloor(inst: Instance_, floor: number)
	local lift = inst.Tower and inst.Tower.Lift
	if not lift then
		return
	end
	if lift.Floor == floor and lift.DoorsOpen and not lift.Busy then
		Lift.setDoors(landingDoors(inst, floor), true)
	end
	local built = inst.Tower.Built[floor]
	local label = textOf(built and built.Model:FindFirstChild("ElevatorFloor"))
	if label then
		label.Text = liftLabel(lift.Floor)
	end
end

-- (para las pruebas) el estado del ascensor de un edificio
function InteriorService.lift(building: Building): LiftState?
	local inst = towerOf(building, false)
	return inst and inst.Tower and inst.Tower.Lift
end

-- ¿Va algún jugador dentro de la cabina? (los vecinos NPC no mandan el ascensor con alguien dentro)
function InteriorService.liftHasRiders(building: Building): boolean
	local inst = towerOf(building, false)
	return inst ~= nil and inst.Tower ~= nil and inst.Tower.Lift ~= nil and #liftRiders(inst) > 0
end

-- Plantas montadas ahora (para las pruebas y el rendimiento)
function InteriorService.builtFloors(building: Building): ({ number }, number)
	local inst = towerOf(building, false)
	local list, parts = {}, 0
	if inst and inst.Tower then
		for floor, built in inst.Tower.Built do
			table.insert(list, floor)
			parts += built.Parts
		end
	end
	table.sort(list)
	return list, parts
end

function InteriorService.tower(building: Building): Instance_?
	return towerOf(building, false)
end

-- A una planta de un edificio de varias plantas (rellano; en la planta baja, junto a la calle)
local function goToLanding(player: Player, building: Building, floor: number, at: CFrame?)
	local inst = towerOf(building, true) :: Instance_
	local t = inst.Tower :: TowerState
	floor = math.clamp(floor, 0, t.Plan.Top)
	-- Las plantas en las que están los demás no se quitan (se caerían al vacío)
	local wanted = { floor }
	local towerKey = building.Id .. ":T"
	for _, other in Players:GetPlayers() do
		local at = other:GetAttribute("TowerFloor")
		if other ~= player and other:GetAttribute("InteriorKey") == towerKey and type(at) == "number" then
			table.insert(wanted, at)
		end
	end
	streamFloors(inst, wanted)
	inst.EmptySince = nil
	player:SetAttribute("InteriorKey", building.Id .. ":T")
	player:SetAttribute("InteriorDoor", building.Door + building.Out * 3)
	player:SetAttribute("TowerFloor", floor)
	local target: Vector3
	if at then
		target = (t.Origin * at).Position
	elseif floor == 0 then
		target = entryOf({ Room = { Model = t.Built[0].Model } } :: any)
	else
		target = (t.Origin * Tower.landing(t.Plan, floor)).Position
	end
	teleport(player, target)
end

-- Entrar por una puerta del pasillo (a su vivienda, oficina, aula o tienda)
local function goToUnit(player: Player, building: Building, floor: number, letter: string)
	local unit = InteriorService.unitOf(building, floor, letter)
	if not unit then
		return
	end
	local gate = InteriorService.Hooks.Gate
	if gate then
		local ok, allowed, why = pcall(gate, player, building, floor, letter)
		if not ok then
			-- (si falla la comprobación, mejor no dejar entrar: antes se entraba en cualquier casa)
			warn("[Interiores] gate: " .. tostring(allowed))
			Notify:FireClient(player, "Error", "🔒 Ahora no se puede entrar. Prueba otra vez en un momento.")
			return
		elseif allowed == false then
			Notify:FireClient(player, "Error", why or "🔒 No puedes entrar.")
			return
		end
	end
	local inst = unitInstance(building, floor, letter)
	if not inst then
		return
	end
	inst.EmptySince = nil
	player:SetAttribute("InteriorKey", building.Id .. ":" .. unit.Id)
	player:SetAttribute("InteriorDoor", building.Door + building.Out * 3)
	player:SetAttribute("TowerFloor", nil)
	teleport(player, entryOf(inst))
	local enter = InteriorService.Hooks.Enter
	if enter then
		task.spawn(enter, player, inst)
	end
end

-- force = true: sin mirar si está ocupado (p. ej. justo después de rehacer la sala en la que estaba,
-- PropertyService.buy: si no, podría quedarse colgado en el pasillo o sentado en un sofá que ya no existe)
function InteriorService.goToUnit(player: Player, building: Building, floor: number, letter: string?, force: boolean?)
	if not force and busy(player) then
		return
	end
	if isTower(building) then
		goToUnit(player, building, floor, letter or "A")
	else
		InteriorService.goTo(player, building, floor)
	end
end

local function goTo(player: Player, building: Building, floor: number, byElevator: boolean?)
	if floor == -1 and building.Roof then
		-- Azotea de la Torre de Valmar: la de verdad
		player:SetAttribute("InteriorKey", nil)
		player:SetAttribute("InteriorDoor", nil)
		player:SetAttribute("TowerFloor", nil) -- (ya no estás en ninguna planta de la torre)
		teleport(player, building.Roof)
		return
	end
	if floor == 0 and building.Walkable then
		-- Planta baja de verdad: vuelves junto al ascensor
		player:SetAttribute("InteriorKey", nil)
		player:SetAttribute("InteriorDoor", nil)
		player:SetAttribute("TowerFloor", nil) -- (ya no estás en ninguna planta de la torre)
		teleport(player, building.Door - building.Out * 6)
		return
	end
	if isTower(building) then
		local ground = InteriorService.unitOf(building, 0, "A")
		if floor == 0 and not byElevator and ground and ground.Ground and building.Kind ~= "Aula" then
			-- La tienda de la planta baja da a la calle: se entra directamente
			goToUnit(player, building, 0, "A")
		else
			goToLanding(player, building, floor)
		end
		return
	end
	local gate = InteriorService.Hooks.Gate
	if gate then
		local ok, allowed, why = pcall(gate, player, building, floor, nil)
		if not ok then
			-- (si falla la comprobación, mejor no dejar entrar)
			warn("[Interiores] gate: " .. tostring(allowed))
			Notify:FireClient(player, "Error", "🔒 Ahora no se puede entrar. Prueba otra vez en un momento.")
			return
		elseif allowed == false then
			-- Casa de otro jugador: suena el timbre (el dueño decide); si no, puerta cerrada
			local bell = InteriorService.Hooks.Doorbell
			local okBell, handled = false, false
			if bell then
				okBell, handled = pcall(bell, player, building, floor, nil)
			end
			if not (okBell and handled) then
				Notify:FireClient(player, "Error", why or "🔒 No puedes entrar.")
			end
			return
		end
	end
	local inst = instanceOf(building, floor)
	if not inst then
		return
	end
	inst.EmptySince = nil
	player:SetAttribute("InteriorKey", building.Id .. ":" .. floor)
	player:SetAttribute("InteriorDoor", building.Door + building.Out * 3)
	teleport(player, entryOf(inst))
	local enter = InteriorService.Hooks.Enter
	if enter then
		task.spawn(enter, player, inst)
	end
end

-- Llevar a alguien a una planta de un edificio (p. ej. "Ir a casa")
function InteriorService.goTo(player: Player, building: Building, floor: number)
	if busy(player) then
		return
	end
	goTo(player, building, floor)
end

-- La sala montada de esa planta o puerta (nil si ahora no hay nadie dentro)
function InteriorService.instance(building: Building, floor: number, letter: string?): Instance_?
	local inst = instances[building.Id .. ":" .. Floors.unitId(floor, letter)]
	return if inst and inst.Room.Model.Parent then inst else nil
end

-- Quita la sala de esa planta o puerta (se vuelve a montar al entrar: p. ej. al cambiar de dueño)
-- y pone al día la placa de su puerta en el pasillo
function InteriorService.reset(building: Building, floor: number, letter: string?)
	local key = building.Id .. ":" .. Floors.unitId(floor, letter)
	-- Quien esté dentro sale antes (al rellano o a la calle): si no, se caería al vacío
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("InteriorKey") == key then
			InteriorService.leave(player)
		end
	end
	local inst = instances[key]
	if inst then
		inst.Room.Model:Destroy()
		instances[key] = nil
		table.insert(freeSlots, inst.Slot)
	end
	local tower = towerOf(building, false)
	if tower and tower.Tower and tower.Tower.Built[floor] then
		-- La planta se rehace con las placas y los carteles nuevos
		dropFloor(tower, floor)
		buildFloor(tower, floor)
	end
end

function InteriorService.all(): { Building }
	local list = {}
	for _, building in buildings do
		table.insert(list, building)
	end
	table.sort(list, function(a, b)
		return a.Id < b.Id
	end)
	return list
end

function InteriorService.byKey(key: string): Building?
	for _, building in buildings do
		if building.Key == key then
			return building
		end
	end
	return nil
end

function InteriorService.enter(player: Player, building: Building)
	if busy(player) then
		return
	end
	goTo(player, building, 0)
end

-- Pone al jugador en un sitio concreto de una sala montada (p. ej. el banquillo del juzgado:
-- JusticeService), con su llave y su puerta: así "Salir" funciona y no se queda la de otro edificio.
-- Si esa pieza no está en ninguna sala, solo lo lleva allí.
function InteriorService.placeAt(player: Player, part: BasePart): Instance_?
	local node: Instance? = part
	local inst: Instance_?, roomKey: string? = nil, nil
	while node and node ~= folder do
		local key = node:GetAttribute("Key")
		if type(key) == "string" and instances[key] and instances[key].Room.Model == node then
			inst, roomKey = instances[key], key
			break
		end
		node = node.Parent
	end
	if inst and roomKey then
		local building = inst.Building
		inst.EmptySince = nil
		player:SetAttribute("InteriorKey", roomKey)
		player:SetAttribute("InteriorDoor", building.Door + building.Out * 3)
		player:SetAttribute("TowerFloor", nil)
	end
	teleport(player, part.Position)
	return inst
end

function InteriorService.leave(player: Player)
	if player:GetAttribute("OnTrial") then
		return -- (en pleno juicio no se sale del banquillo: sale al acabar, JusticeService)
	end
	local key = player:GetAttribute("InteriorKey")
	local id, unitId = string.match(type(key) == "string" and key or "", "^(%d+):(%w+)$")
	local building = id and buildings[tonumber(id) :: number]
	if building and unitId and unitId ~= "T" and isTower(building) then
		local floor, letter = Floors.parseUnit(unitId)
		local unit = floor and InteriorService.unitOf(building, floor, letter)
		-- De una vivienda u oficina se sale al pasillo, delante de su puerta (la tienda de la calle,
		-- a la calle)
		if floor and letter and unit and not (unit.Ground and building.Kind ~= "Aula") then
			local plan = (towerOf(building, true) :: Instance_).Tower.Plan
			goToLanding(player, building, floor, Tower.doorFront(plan, floor, letter))
			return
		end
	end
	local door = player:GetAttribute("InteriorDoor")
	player:SetAttribute("InteriorKey", nil)
	player:SetAttribute("InteriorDoor", nil)
	player:SetAttribute("TowerFloor", nil)
	if typeof(door) == "Vector3" then
		teleport(player, door)
	end
end

-- ¿Sigue delante de esa puerta? (en el rellano de esa planta, a unos pasos; en una casa, en la calle
-- junto a su puerta). Para abrir a quien llamó hace un rato (timbre, vecinos).
function InteriorService.atDoor(player: Player, building: Building, floor: number, letter: string?): boolean
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or busy(player) then
		return false
	end
	if not isTower(building) then
		return player:GetAttribute("InteriorKey") == nil and (root.Position - building.Door).Magnitude <= 12
	end
	local inst = towerOf(building, false)
	local t = inst and inst.Tower
	if not t or player:GetAttribute("InteriorKey") ~= building.Id .. ":T" or player:GetAttribute("TowerFloor") ~= floor then
		return false
	end
	local front = Tower.doorFront(t.Plan, floor, letter or "A")
	return front ~= nil and (root.Position - (t.Origin * front).Position).Magnitude <= 12
end

-- Panel del ascensor (el cliente elige planta)
local function openElevator(player: Player, building: Building)
	if busy(player, true) then
		return
	end
	player:SetAttribute("ElevatorBuilding", building.Id)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	elevatorOpen[player] = { At = os.clock(), Position = if root then root.Position else nil }
	local labels = {}
	local getLabels = InteriorService.Hooks.Labels
	if getLabels then
		local ok, result = pcall(getLabels, building)
		if ok and type(result) == "table" then
			for floor, text in result do
				labels[tostring(floor)] = text
			end
		end
	end
	local current = player:GetAttribute("TowerFloor")
	if type(current) ~= "number" then
		current = tonumber(string.match(player:GetAttribute("InteriorKey") or "", ":(%d+)%a?$")) or 0
	end
	Remote:FireClient(player, "Elevator", {
		Labels = labels,
		Title = building.Title,
		Floors = building.Floors,
		Roof = building.Roof ~= nil,
		Current = current,
	})
end

InteriorService.openElevator = openElevator

-- La función de abrir puertas con bisagra (InteractService; se pide al usarla para no depender de él)
local function InteractSwing(): ((BasePart, boolean, number?) -> ())?
	local ok, service = pcall(function()
		return require(script.Parent.InteractService) :: any
	end)
	return if ok and service and service.swing then service.swing else nil
end

local function onUnitDoor(player: Player, building: Building, panel: BasePart, knock: boolean)
	if busy(player) or player:GetAttribute("InDialogue") then
		return
	end
	local floor, letter = panel:GetAttribute("Floor"), panel:GetAttribute("Letter")
	local unit = type(floor) == "number" and InteriorService.unitOf(building, floor, letter)
	if not unit then
		return
	end
	local occ = InteriorService.occupant(building, unit)
	local function open()
		local swing = InteractSwing()
		if swing then
			swing(panel, true, 0.35)
			task.delay(2, function()
				if panel.Parent then
					swing(panel, false, 0.4)
				end
			end)
		end
		goToUnit(player, building, floor :: number, letter)
	end
	local mine = occ.UserId ~= nil and occ.UserId == player.UserId
	if occ.Type == "Dorm" then
		-- Residencia: entras en la tuya; en las demás llamas y contesta quien viva
		if player:GetAttribute("DormUnit") == building.Key .. "#" .. unit.Id then
			open()
		else
			Notify:FireClient(player, "Info", "🚪 Toc, toc… «¿Sí? Ahora estoy estudiando, ¡luego hablamos!»")
		end
		return
	elseif occ.Type == "Owner" and not mine then
		-- Casa de otro jugador: si es de tu grupo, entras; si no, llamas
		local gate = InteriorService.Hooks.Gate
		local ok, allowed = true, true
		if gate then
			ok, allowed = pcall(gate, player, building, floor :: number, letter)
		end
		if ok and allowed then
			-- (de tu grupo: te abren aunque llames)
			if knock then
				Notify:FireClient(player, "Success", ("🚪 Toc, toc… %s te abre la puerta."):format(occ.Name or "Tu amigo"))
			end
			open()
			return
		end
		-- El timbre: el dueño decide si abre (HousingService)
		local bell = InteriorService.Hooks.Doorbell
		if bell then
			local okBell, handled = pcall(bell, player, building, floor :: number, letter)
			if okBell and handled then
				return
			end
		end
		Notify:FireClient(player, "Info", ("🚪 Toc, toc… Es la casa de %s. Nadie te abre."):format(occ.Name or "otra persona"))
		return
	elseif occ.Type == "Neighbor" then
		-- Los vecinos contestan si están en casa (cada uno tiene su horario: shared/Residents)
		local answer = InteriorService.Hooks.NeighborAnswer
		if answer then
			local okAnswer, home, text = pcall(answer, building, unit, game:GetService("Lighting").ClockTime)
			if okAnswer and home == false then
				Notify:FireClient(player, "Info", "🚪 Toc, toc…")
				task.delay(0.8, function()
					Notify:FireClient(player, "Info", "🚪 " .. tostring(text or "No contesta nadie."))
				end)
				return
			end
		end
		Notify:FireClient(player, "Info", "🚪 Toc, toc…")
		local friendly = (Floors.hash(("%s:%s:%d"):format(building.Key, unit.Id, player.UserId)) + math.floor(os.time() / 600)) % 3 == 0
		task.delay(0.8, function()
			local name = occ.Name or "Vecino"
			if friendly then
				-- (solo si sigues en la puerta: en ese rato te has podido ir a otra planta o a la calle)
				if not InteriorService.atDoor(player, building, floor :: number, letter) then
					return
				end
				Notify:FireClient(player, "Success", ("🙂 %s: «¡Hola! Pasa, pasa, estás en tu casa.»"):format(name))
				open()
			else
				local lines = { "Ahora no puedo, perdona.", "¿Quién es? No compro nada, gracias.", "Estoy con la comida, vuelve luego.", "Hoy no es buen momento." }
				Notify:FireClient(player, "Info", ("🚪 %s: «%s»"):format(name, lines[math.random(1, #lines)]))
			end
		end)
		return
	elseif occ.Type == "Company" or occ.Type == "Shop" then
		local clock = game:GetService("Lighting").ClockTime
		if not Floors.isOpen(clock) then
			Notify:FireClient(player, "Info", ("🕘 %s está cerrado. Abre de %d:00 a %d:00."):format(occ.Name or unit.Label, Floors.OpenFrom, Floors.OpenTo))
			return
		end
	end
	open()
end

function connectFloor(inst: Instance_, floor: number, built: Tower.Built)
	local building = inst.Building
	for _, part in built.Model:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end
		if part:HasTag("InteriorExit") then
			local prompt = Builder.prompt(part, "Salir", "🚪 A la calle", 0.2)
			prompt.MaxActivationDistance = 9
			prompt.Triggered:Connect(function(player)
				InteriorService.leave(player)
			end)
		elseif part:HasTag("InteriorElevator") then
			-- Botón de llamada: la cabina viene a esta planta y abre (sin ascensor, el panel de antes)
			local lift = inst.Tower and inst.Tower.Lift
			local prompt = Builder.prompt(part, if lift then "Llamar al ascensor" else "Ascensor", if lift then "🛗 Botón de llamada" else "🏢 Elegir planta", 0.1)
			prompt.MaxActivationDistance = 8
			prompt.Triggered:Connect(function(player)
				if lift then
					callLift(inst, floor)
				else
					openElevator(player, building)
				end
			end)
		elseif part:HasTag("UnitDoor") then
			local unit = InteriorService.unitOf(building, floor, part:GetAttribute("Letter"))
			if not unit then
				continue
			end
			local occ = InteriorService.occupant(building, unit)
			local action = if occ.Type == "Neighbor" or occ.Type == "Owner" then "Llamar" elseif occ.Type == "ForSale" or occ.Type == "ForRent" then "Visitar" else "Entrar"
			if occ.Type == "Dorm" then
				-- (cada uno entra en la suya; en las demás, llama: onUnitDoor)
				action = "Entrar"
			end
			local object = ("🚪 %s"):format(unit.Label) .. (if occ.Name and occ.Name ~= "" then " · " .. occ.Name else "")
			local prompt = Builder.prompt(part, action, object, 0.3)
			prompt.Name = "DoorPrompt"
			prompt.MaxActivationDistance = 6
			prompt:SetAttribute("NoGesture", true)
			prompt.Triggered:Connect(function(player)
				onUnitDoor(player, building, part, action == "Llamar")
			end)
			if occ.Type == "Owner" and occ.UserId then
				-- El dueño (y solo él) ve además "Entrar" (JobPrompts: OwnerUserId)
				local mine = Builder.prompt(part, "Entrar", ("🏠 %s · tu casa"):format(unit.Label), 0.3)
				mine.Name = "DoorPromptOwner"
				mine.MaxActivationDistance = 6
				mine:SetAttribute("OwnerUserId", occ.UserId)
				mine:SetAttribute("NoGesture", true)
				mine.Triggered:Connect(function(player)
					onUnitDoor(player, building, part, false)
				end)
			end
		end
	end
end

function connectRoom(inst: Instance_)
	local toCorridor = isTower(inst.Building) and not (inst.Floor == 0 and inst.Building.Kind ~= "Aula" and (inst.Building.Kind == "Local" or inst.Building.Kind == "CentroComercial"))
	for _, part in inst.Room.Model:GetDescendants() do
		if part:IsA("BasePart") and part:HasTag("InteriorExit") then
			local prompt = Builder.prompt(part, "Salir", if toCorridor then "🚪 Al rellano" else "🚪 A la calle", 0.2)
			prompt.MaxActivationDistance = 9
			prompt.Triggered:Connect(function(player)
				InteriorService.leave(player)
			end)
		elseif part:IsA("BasePart") and part:HasTag("InteriorElevator") then
			local prompt = Builder.prompt(part, "Ascensor", "🏢 Elegir planta", 0.2)
			prompt.MaxActivationDistance = 9
			prompt.Triggered:Connect(function(player)
				openElevator(player, inst.Building)
			end)
		elseif part:IsA("BasePart") and part:HasTag("TowerStairs") and isTower(inst.Building) then
			-- De la tienda de la calle al portal del edificio (escalera y ascensor)
			local prompt = Builder.prompt(part, "Ir al portal", "🪜 Escalera y viviendas", 0.2)
			prompt.MaxActivationDistance = 8
			prompt.Triggered:Connect(function(player)
				if not busy(player) then
					goToLanding(player, inst.Building, 0)
				end
			end)
		end
	end
	-- (los muebles que se usan: InteractService, con onBuilt)
end

---------------------------------------------------------------------
-- Puertas en la ciudad
---------------------------------------------------------------------
local function addDoor(building: Building)
	local part = Builder.part({
		Name = "Door_" .. building.Id,
		Size = Vector3.new(4, 6, 1),
		CFrame = CFrame.lookAt(building.Door + Vector3.new(0, 3, 0), building.Door + Vector3.new(0, 3, 0) + building.Out),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Tags = { "BuildingDoor" },
		Attributes = { BuildingId = building.Id, Kind = building.Kind },
		Parent = folder,
	})
	if building.Roof then
		-- En la azotea, el ascensor para volver a bajar
		local roof = Builder.part({ Name = "RoofElevator", Size = Vector3.new(4, 6, 4), CFrame = CFrame.new(building.Roof), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = folder })
		local down = Builder.prompt(roof, "Ascensor", "🏢 Bajar", 0.2)
		down.MaxActivationDistance = 10
		down.Triggered:Connect(function(player)
			openElevator(player, building)
		end)
	end
	if building.Walkable then
		-- Ya se entra andando: el ascensor, dentro, al fondo de la planta baja
		if building.Floors >= 2 then
			part.CFrame = CFrame.new(groundAt(building.Door - building.Out * 8) + Vector3.new(0, 3, 0))
			local prompt = Builder.prompt(part, "Ascensor", "🏢 " .. building.Title, 0.2)
			prompt.MaxActivationDistance = 7
			prompt.Triggered:Connect(function(player)
				openElevator(player, building)
			end)
		end
		return
	end
	local prompt = Builder.prompt(part, "Entrar", building.Title, 0.2)
	prompt.MaxActivationDistance = 8
	prompt.Triggered:Connect(function(player)
		InteriorService.enter(player, building)
	end)
end

-- Cartel de la institución en la fachada
local function facadeSign(building: Building, text: string, color: Color3)
	local cf = CFrame.lookAt(building.Door + Vector3.new(0, 12, 0) + building.Out * 0.8, building.Door + Vector3.new(0, 12, 0) + building.Out * 2)
	local board = Builder.part({ Name = "InstitutionSign", Size = Vector3.new(22, 3.2, 0.5), CFrame = cf, Color = color, CanCollide = false, CanQuery = false, CanTouch = false, Parent = folder })
	Builder.sign(board, text, Enum.NormalId.Front, Color3.fromRGB(245, 235, 200))
end

local function publishLandmark(kind: string, position: Vector3)
	local landmarks = ReplicatedStorage:FindFirstChild("MapLandmarks")
	if landmarks then
		local config = Instance.new("Configuration")
		config.Name = kind .. "_Host"
		config:SetAttribute("Kind", kind)
		config:SetAttribute("Position", Vector3.new(position.X, 0, position.Z))
		config:SetAttribute("District", "")
		config.Parent = landmarks
	end
end

-- Comercios de la calle en el mapa, según lo que pone su cartel (shared/MapLegend los agrupa:
-- «Tiendas de ropa», «Restaurantes y bares», «Gimnasios»…). Dos del mismo tipo pegados, uno solo.
local SHOP_LANDMARKS = {
	Moda = "LocalRopa", Zapateria = "LocalRopa",
	Bar = "LocalComida", Cafeteria = "LocalComida", Pizzeria = "LocalComida", Heladeria = "LocalComida",
	Sushi = "LocalComida", Hamburgueseria = "LocalComida", Kebab = "LocalComida",
	Estudio = "LocalGimnasio",
	Ultramarinos = "LocalSuper", Fruteria = "LocalSuper", Panaderia = "LocalSuper",
	Farmacia = "LocalFarmacia",
}
local function publishShops(list: { Building })
	local placed: { { Kind: string, Position: Vector3 } } = {}
	for _, b in list do
		local profile = b.Kind == "Local" and b.Shop and Interiors.profileFor(b.Shop)
		local kind = profile and SHOP_LANDMARKS[profile.Id]
		if kind then
			local near = false
			for _, other in placed do
				if other.Kind == kind and (other.Position - b.Door).Magnitude < 60 then
					near = true
					break
				end
			end
			if not near then
				table.insert(placed, { Kind = kind, Position = b.Door })
				publishLandmark(kind, b.Door)
			end
		end
	end
end

-- Instituciones dentro de edificios que ya existen (siempre los mismos: el mapa no cambia)
local function hostInstitutions(list: { Building })
	local center: { Building } = {}
	local naves: { Building } = {}
	for _, b in list do
		if b.Model.Name:match("^Edificio_%d+$") and b.Kind == "Portal" then
			table.insert(center, b)
		elseif b.Model.Name == "Nave" then
			table.insert(naves, b)
		end
	end
	table.sort(center, function(a, b)
		return a.Door.Magnitude < b.Door.Magnitude
	end)
	table.sort(naves, function(a, b)
		return a.Door.X > b.Door.X
	end)
	local hosts = {
		{ Building = center[1], Kind = "Juzgado", Title = "⚖️ Palacio de Justicia", Sign = "PALACIO DE JUSTICIA", Color = Color3.fromRGB(90, 30, 40), Map = "PalacioJusticia" },
		{ Building = center[2], Kind = "Hacienda", Title = "🏛 Agencia Tributaria", Sign = "AGENCIA TRIBUTARIA", Color = Color3.fromRGB(30, 90, 110), Map = "AgenciaTributaria" },
		{ Building = naves[1], Kind = "Cuartel", Title = "🎖 Cuartel del Ejército", Sign = "CUARTEL DEL EJÉRCITO", Color = Color3.fromRGB(70, 90, 50), Map = "CuartelEjercito" },
	}
	for _, host in hosts do
		local b = host.Building
		if b then
			b.Kind = host.Kind
			b.Upper = nil
			b.Floors = 1
			b.Title = host.Title
			b.Persistent = true
			facadeSign(b, host.Sign, host.Color)
			publishLandmark(host.Map, b.Door)
		else
			warn("[Interiores] No hay edificio para " .. host.Kind)
		end
	end
end

-- Residencias universitarias: algunos bloques del campus (siempre los mismos) tienen habitaciones
-- para los estudiantes (ResidenceService les da una)
local function hostResidences(list: { Building })
	local campus: { Building } = {}
	for _, b in list do
		if b.Model.Parent and b.Model.Parent.Name == "Manzana_Campus" and b.Kind == "Aula" and b.Floors >= 2 then
			table.insert(campus, b)
		end
	end
	table.sort(campus, function(a, b)
		return a.Key < b.Key
	end)
	local chosen = 0
	for i, b in campus do
		if Floors.hash("residencia:" .. b.Key) % 3 == 0 or (i == #campus and chosen == 0) then
			chosen += 1
			b.Kind = "Portal"
			b.Upper = "Dorm"
			b.Title = "🛏 Residencia universitaria"
			b.Residence = true
			publishLandmark("Residencia", b.Door)
			-- Marca de la historia en su puerta (antes no había: las misiones de la residencia pasaban
			-- en la acera entre la facultad y el estadio)
			pcall(function()
				local out = if typeof(b.Out) == "Vector3" and b.Out.Magnitude > 0.1 then b.Out.Unit else Vector3.new(0, 0, 1)
				local at = b.Door + out * 5 + Vector3.new(0, 2.5, 0)
				StoryMarks.spot(b.Model, "Residencia", CFrame.lookAt(at, at + out))
			end)
		end
	end
end

function InteriorService.residences(): { Building }
	local list = {}
	for _, b in buildings do
		if b.Residence then
			table.insert(list, b)
		end
	end
	table.sort(list, function(a, b)
		return a.Key < b.Key
	end)
	return list
end

local function scan()
	local town = workspace:FindFirstChild("Town")
	if not town then
		return {}
	end
	local list: { Building } = {}
	local id = 0
	-- Primero: las calzadas y el contorno de cada edificio (para elegir bien la fachada de la puerta)
	local found: { { Model: Model, Kind: string, Title: string, Upper: string?, CFrame: CFrame, Size: Vector3 } } = {}
	for _, part in town:GetDescendants() do
		if part:IsA("BasePart") and (part.Name == "Road" or part.Name == "Junction" or part.Name == "Rotonda") then
			addToGrid(roadGrid, part, part.Position, part.Size.Magnitude / 2, part.Size.Magnitude / 2)
		end
	end
	for _, model in town:GetDescendants() do
		if model:IsA("Model") then
			local kind, title, upper = classify(model)
			if kind then
				local cf, size = boundingBox(model)
				if cf and size and size.Y > 6 then
					table.insert(found, { Model = model, Kind = kind, Title = title :: string, Upper = upper, CFrame = cf, Size = size })
					local half = math.max(size.X, size.Z) / 2
					addToGrid(boxGrid, { CFrame = cf, Size = size, Model = model }, cf.Position, half, half)
				end
			end
		end
	end
	for _, entry in found do
		local model, cf, size = entry.Model, entry.CFrame, entry.Size
		local door, out = findDoor(model, cf, size)
		id += 1
		local building: Building = {
			Id = id,
			Key = ("%s_%d_%d"):format(entry.Kind, math.floor(cf.Position.X + 0.5), math.floor(cf.Position.Z + 0.5)),
			Model = model,
			Kind = entry.Kind,
			Upper = entry.Upper,
			Floors = math.clamp(math.floor((size.Y - 2) / 12), 1, 40),
			Title = entry.Title,
			Door = groundAt(door + out * 2.5),
			Out = out,
			Walkable = entry.Kind == "Walk",
			Shop = if entry.Kind == "Local" then signText(model) else nil,
		}
		if model.Name == "TorreValmar" then
			-- Azotea: encima del bloque de cristal más alto, apartado de la aguja del centro
			local top: BasePart? = nil
			for _, part in model:GetDescendants() do
				if part:IsA("BasePart") and part.Name == "Core" and (not top or part.Position.Y > top.Position.Y) then
					top = part
				end
			end
			if top then
				building.Roof = top.Position + Vector3.new(top.Size.X * 0.3, top.Size.Y / 2 + 3, 0)
			end
		end
		buildings[id] = building
		table.insert(list, building)
	end
	return list
end

-- Planta de cada jugador dentro de los edificios de varias plantas (por su altura)
function InteriorService.stepTowers()
	local byTower: { [string]: { number } } = {}
	for _, player in Players:GetPlayers() do
		local key = player:GetAttribute("InteriorKey")
		local inst = type(key) == "string" and instances[key]
		if inst and inst.Tower then
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			-- A mitad de un salto (o aún en la sala de antes, fuera de la torre) su altura no vale:
			-- se le pondría en la planta 0 y se quitaría la planta a la que va
			local rel = root and inst.Tower.Origin:PointToObjectSpace(root.Position)
			local outside = rel == nil or math.abs(rel.X) > inst.Tower.Plan.W / 2 + 16 or math.abs(rel.Z) > Floors.Depth / 2 + 16
			if root and not teleporting[player] and not outside then
				local y = root.Position.Y - inst.Tower.Origin.Position.Y - 3
				local floor = Floors.floorAt(y, inst.Tower.Plan.Top)
				if player:GetAttribute("TowerFloor") ~= floor then
					player:SetAttribute("TowerFloor", floor)
				end
				byTower[key] = byTower[key] or {}
				table.insert(byTower[key], floor)
			elseif type(player:GetAttribute("TowerFloor")) == "number" then
				-- (su planta de llegada se deja montada mientras llega)
				byTower[key] = byTower[key] or {}
				table.insert(byTower[key], player:GetAttribute("TowerFloor"))
			end
		end
	end
	for key, list in byTower do
		streamFloors(instances[key], list)
	end
end

-- Intrusos: alguien que se ha teletransportado dentro de la casa de otro jugador (sin pasar por la
-- puerta) tiene el cuerpo en esa sala pero no su llave. Solo se mira en las viviendas de jugadores
-- (Hooks.Gate dice que no puede entrar); pasillos, escaleras, tiendas y salas públicas no. Tampoco a
-- quien está a mitad de un salto (Teleporting) o en el ascensor. Se le saca a la calle, a la puerta.
function InteriorService.checkIntruders()
	local gate = InteriorService.Hooks.Gate
	if not gate then
		return
	end
	local half = SLOT / 2
	-- (sobre una copia: gate puede esperar y mientras tanto se pueden montar o quitar salas)
	for key, inst in table.clone(instances) do
		if inst.Tower or inst.Building.Persistent or not inst.Room.Model.Parent then
			continue
		end
		local center = slotPosition(inst.Slot)
		for _, player in Players:GetPlayers() do
			if player:GetAttribute("InteriorKey") == key or player:GetAttribute("Teleporting") or teleporting[player] or player:GetAttribute("LiftTower") then
				continue
			end
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not root then
				continue
			end
			local rel = root.Position - center
			if math.abs(rel.X) > half or math.abs(rel.Z) > half or rel.Y < -40 or rel.Y > 120 then
				continue
			end
			local building = inst.Building
			local ok, allowed = pcall(gate, player, building, inst.Floor, if isTower(building) then inst.Unit else nil)
			-- (si falla la comprobación, no se echa a nadie; y si mientras tanto se ha ido o ha
			-- entrado por la puerta, tampoco)
			if ok and allowed == false and player.Parent and player:GetAttribute("InteriorKey") ~= key then
				player:SetAttribute("InteriorKey", nil)
				player:SetAttribute("InteriorDoor", nil)
				player:SetAttribute("TowerFloor", nil)
				Notify:FireClient(player, "Error", "🔒 No puedes estar en casa de otro.")
				task.spawn(teleport, player, building.Door + building.Out * 3)
			end
		end
	end
end

function InteriorService.buildingOf(player: Player): Building?
	local key = player:GetAttribute("InteriorKey")
	local id = tonumber(string.match(key or "", "^(%d+):"))
	return id and buildings[id]
end

function InteriorService.init()
	Notify = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify") :: RemoteEvent
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:FindFirstChild("Interior") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "Interior"
		Remote.Parent = remotes
	end
	folder = Instance.new("Folder")
	folder.Name = "Interiores"
	folder.Parent = workspace

	local list = scan()
	hostInstitutions(list)
	hostResidences(list)
	pcall(publishShops, list)
	for _, building in list do
		addDoor(building)
		if building.Persistent then
			instanceOf(building, 0)
		end
	end
	print(("[Interiores] %d edificios visitables"):format(#list))
	-- Ya están las claves (salen de la caja de cada edificio): World/Buildings3D puede cambiar fachadas
	workspace:SetAttribute("InteriorsScanned", true)

	Remote.OnServerEvent:Connect(function(player: Player, kind: any, value: any)
		if kind == "Floor" and type(value) == "number" then
			if value ~= value or math.abs(value) > 1000 then
				return
			end
			local building = buildings[player:GetAttribute("ElevatorBuilding") or 0]
			-- Solo desde el ascensor que acabas de abrir (no desde cualquier sitio ni mucho después)
			local opened = elevatorOpen[player]
			elevatorOpen[player] = nil
			player:SetAttribute("ElevatorBuilding", nil)
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not opened or os.clock() - opened.At > 60 or not root or not opened.Position or (root.Position - opened.Position).Magnitude > 25 then
				return
			end
			if not building or busy(player, true) then
				return
			end
			local floor = math.floor(value)
			if floor == -1 and not building.Roof then
				return
			end
			if floor < -1 or floor >= building.Floors then
				return
			end
			-- Con ascensor de verdad: sube o baja con la cabina (tienes que estar dentro). La azotea
			-- (Torre de Valmar) sigue siendo un salto aparte. Desde la calle (planta baja de verdad) o
			-- desde la azotea no estás en la torre: se va directo al rellano. Y en los edificios con
			-- planta baja de verdad, la planta 0 es la calle (no un portal de mentira en el cielo).
			local inst = towerOf(building, false)
			local lift = inst and inst.Tower and inst.Tower.Lift
			local inTower = player:GetAttribute("InteriorKey") == building.Id .. ":T"
			if lift and floor >= 0 and inTower and not (floor == 0 and building.Walkable) then
				local inside = false
				for _, r in liftRiders(inst :: Instance_) do
					inside = inside or r.Player == player
				end
				if not inside then
					Notify:FireClient(player, "Info", "🛗 Entra en el ascensor y elige la planta dentro.")
					return
				end
				callLift(inst :: Instance_, floor)
				return
			end
			goTo(player, building, floor, true)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		elevatorOpen[player] = nil
		teleporting[player] = nil
	end)

	-- Al morir o reaparecer ya no estás dentro de ninguna sala
	local function watch(player: Player)
		-- (siempre, también antes de SpawnReady: PositionService te deja en la calle, delante de la
		-- puerta, nunca dentro de una sala; una llave vieja haría creer que sigues dentro)
		player.CharacterAdded:Connect(function()
			player:SetAttribute("InteriorKey", nil)
			player:SetAttribute("InteriorDoor", nil)
			player:SetAttribute("TowerFloor", nil)
			player:SetAttribute("LiftTower", nil)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end

	-- Edificios de varias plantas: solo están montadas las plantas cerca de alguien (±2); al subir
	-- o bajar por la escalera se montan las siguientes y se quitan las lejanas
	task.spawn(function()
		while true do
			task.wait(0.5)
			-- Protegido: un error en una torre no debe parar las plantas de todo el servidor
			local ok, err = pcall(InteriorService.stepTowers)
			if not ok then
				warn("[InteriorService] " .. tostring(err))
			end
			pcall(stepLifts)
		end
	end)

	-- Cada segundo: nadie dentro de la casa de otro jugador sin haber pasado por la puerta
	task.spawn(function()
		while true do
			task.wait(1)
			local ok, err = pcall(InteriorService.checkIntruders)
			if not ok then
				warn("[Interiores] " .. tostring(err))
			end
		end
	end)

	-- Salas vacías: se quitan al rato
	task.spawn(function()
		while true do
			task.wait(5)
			local occupied: { [string]: boolean } = {}
			for _, player in Players:GetPlayers() do
				local key = player:GetAttribute("InteriorKey")
				if key then
					occupied[key] = true
				end
			end
			for key, inst in instances do
				if inst.Building.Persistent then
					continue
				end
				if occupied[key] then
					inst.EmptySince = nil
				else
					inst.EmptySince = inst.EmptySince or os.clock()
					if os.clock() - inst.EmptySince > EMPTY_SECONDS then
						inst.Room.Model:Destroy()
						instances[key] = nil
						table.insert(freeSlots, inst.Slot)
					end
				end
			end
		end
	end)
end

return InteriorService
