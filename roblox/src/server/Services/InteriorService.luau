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
local Interiors = require(script.Parent.Parent.World.Interiors)
local Tower = require(script.Parent.Parent.World.Tower)
local Builder = require(script.Parent.Parent.World.Builder)
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
}
-- Edificio de varias plantas montado: sus plantas (solo las que están cerca de alguien)
export type TowerState = { Plan: Tower.Plan, Origin: CFrame, Built: { [number]: Tower.Built } }
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
local function hasChild(model: Model, name: string): BasePart?
	local child = model:FindFirstChild(name)
	return if child and child:IsA("BasePart") then child else nil
end

-- Lo que pone el cartel del edificio (tiendas: su interior va a juego)
local function signText(model: Instance): string?
	local sign = model:FindFirstChild("Sign")
	local gui = sign and sign:FindFirstChildOfClass("SurfaceGui")
	local label = gui and gui:FindFirstChildOfClass("TextLabel")
	return if label and label:IsA("TextLabel") then label.Text else nil
end

-- Tipo de interior, título y plantas de arriba (nil = este modelo no es un edificio visitable)
local function classify(model: Model): (string?, string?, string?)
	local name, parent = model.Name, (model.Parent and model.Parent.Name or "")
	if name == "Casa" and (parent == "Manzana_Casas" or parent == "Vivienda") then
		return "Casa", "🏠 Casa", nil
	elseif name == "Villa" then
		return "Villa", "🏡 Villa", nil
	elseif name == "Bloque" then
		if parent == "Manzana_Comercio" then
			return "Local", "🏬 Comercio y viviendas", "Piso"
		elseif parent == "Manzana_Campus" then
			return "Aula", "🎓 Facultad", "Aula"
		elseif parent == "Manzana_Towers" then
			return "OficinaLobby", "🏢 Oficinas", "Oficina"
		elseif parent == "Manzana_Downtown" then
			return "Portal", "🏢 Viviendas y oficinas", "Piso"
		elseif parent == "Manzana_Residencia" or parent == "Manzana_Pisos" then
			return "Portal", "🏢 Edificio de viviendas", "Piso"
		end
	elseif name == "Rascacielos" or name == "Oficinas" then
		return "OficinaLobby", "🏙 Oficinas", "Oficina"
	elseif name == "Nave" then
		return "Nave", "🏭 Nave industrial", nil
	elseif name == "Taller" then
		return "Taller", "🔧 Taller mecánico", nil
	elseif name == "Ocio_Local" then
		return "Ocio", "🎶 Local de ocio", nil
	elseif name == "TorreValmar" then
		return "OficinaLobby", "🏙 Torre de Valmar", "Oficina"
	elseif name == "Ayuntamiento" then
		return "Ayuntamiento", "🏛 Ayuntamiento", nil
	elseif name == "Museo" then
		return "Museo", "🖼 Museo de Valmar", nil
	elseif name == "Teatro" then
		return "Teatro", "🎭 Teatro Principal", nil
	elseif name == "EstacionCentral" then
		return "Estacion", "🚆 Estación Central", nil
	elseif name == "GranCentroComercial" then
		return "CentroComercial", "🛍 Centro Comercial Valmar", "Local"
	elseif name == "Edificio" or name:match("^Edificio_%d+$") then
		if hasChild(model, "ShopDoor") then
			-- Tienda de la calle con su puerta de cristal (Kit/Decor): se entra a su interior
			local shop = signText(model)
			return "Local", "🏬 " .. (if shop and shop ~= "" then shop else "Comercio"), "Piso"
		end
		if hasChild(model, "GarageDoor") and not hasChild(model, "DoorPanel") then
			return "Nave", "🚒 Cocheras", nil
		elseif hasChild(model, "DoorPanel") then
			return "Portal", "🏢 Edificio de viviendas", "Piso"
		end
		-- Planta baja de verdad (tienda, colegio, hospital…): solo el ascensor
		local civic = parent == "Colegio" or parent == "Hospital" or parent == "CentroSalud" or parent == "Policia" or parent == "Facultad" or parent == "CentroComercial"
		return "Walk", "🏢 Edificio", if parent == "Facultad" or parent == "Colegio" then "Aula" elseif civic then "Oficina" else "Piso"
	end
	return nil, nil, nil
end

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
	local hit = workspace:Raycast(position + Vector3.new(0, 6, 0), Vector3.new(0, -40, 0), params)
	return if hit then hit.Position else position
end

-- Dónde está la puerta: la pieza "Door" si la hay; si no, la fachada que da a la calle más cercana
local function findDoor(model: Model, cf: CFrame, size: Vector3): (Vector3, Vector3)
	local center = cf.Position
	local doorPart = hasChild(model, "ShopDoor") or hasChild(model, "Door") or hasChild(model, "DoorPanel") or hasChild(model, "FakeDoor")
	if doorPart then
		local offset = Vector3.new(doorPart.Position.X - center.X, 0, doorPart.Position.Z - center.Z)
		local out = if offset.Magnitude > 0.5 then offset.Unit else cf.LookVector
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

local function busy(player: Player): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid == nil or humanoid.Health <= 0 or humanoid.SeatPart ~= nil or player:GetAttribute("OnTrial") == true or player:GetAttribute("JailUntil") ~= nil
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

local function towerOf(building: Building, create: boolean): Instance_?
	local key = building.Id .. ":T"
	local existing = instances[key]
	if existing and existing.Room.Model.Parent then
		return existing
	end
	if not create then
		return nil
	end
	local plan = Tower.plan(building.Key, building.Title, building.Kind, building.Upper :: string, building.Floors)
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
	SceneService.teleportTo(player, target)
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
		if ok and allowed == false then
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
	SceneService.teleportTo(player, entryOf(inst))
	local enter = InteriorService.Hooks.Enter
	if enter then
		task.spawn(enter, player, inst)
	end
end

function InteriorService.goToUnit(player: Player, building: Building, floor: number, letter: string?)
	if busy(player) then
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
		SceneService.teleportTo(player, building.Roof)
		return
	end
	if floor == 0 and building.Walkable then
		-- Planta baja de verdad: vuelves junto al ascensor
		player:SetAttribute("InteriorKey", nil)
		player:SetAttribute("InteriorDoor", nil)
		SceneService.teleportTo(player, building.Door - building.Out * 6)
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
		if ok and allowed == false then
			Notify:FireClient(player, "Error", why or "🔒 No puedes entrar.")
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
	SceneService.teleportTo(player, entryOf(inst))
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

function InteriorService.leave(player: Player)
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
		SceneService.teleportTo(player, door)
	end
end

-- Panel del ascensor (el cliente elige planta)
local function openElevator(player: Player, building: Building)
	if busy(player) then
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
		local owner = Players:GetPlayerByUserId(occ.UserId or 0)
		if owner and owner:GetAttribute("InteriorKey") == building.Id .. ":" .. unit.Id then
			Notify:FireClient(owner, "Info", ("🚪 %s llama a tu puerta (%s)."):format(player.DisplayName, unit.Label))
		end
		Notify:FireClient(player, "Info", ("🚪 Toc, toc… Es la casa de %s. Nadie te abre."):format(occ.Name or "otra persona"))
		return
	elseif occ.Type == "Neighbor" then
		-- Los vecinos contestan; a veces te dejan pasar
		Notify:FireClient(player, "Info", "🚪 Toc, toc…")
		local friendly = (Floors.hash(("%s:%s:%d"):format(building.Key, unit.Id, player.UserId)) + math.floor(os.time() / 600)) % 3 == 0
		task.delay(0.8, function()
			local name = occ.Name or "Vecino"
			if friendly then
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
			local prompt = Builder.prompt(part, "Ascensor", "🏢 Elegir planta", 0.2)
			prompt.MaxActivationDistance = 8
			prompt.Triggered:Connect(function(player)
				openElevator(player, building)
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
			if root then
				local y = root.Position.Y - inst.Tower.Origin.Position.Y - 3
				local floor = Floors.floorAt(y, inst.Tower.Plan.Top)
				if player:GetAttribute("TowerFloor") ~= floor then
					player:SetAttribute("TowerFloor", floor)
				end
				byTower[key] = byTower[key] or {}
				table.insert(byTower[key], floor)
			end
		end
	end
	for key, list in byTower do
		streamFloors(instances[key], list)
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
	for _, building in list do
		addDoor(building)
		if building.Persistent then
			instanceOf(building, 0)
		end
	end
	print(("[Interiores] %d edificios visitables"):format(#list))

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
			if not building or busy(player) then
				return
			end
			local floor = math.floor(value)
			if floor == -1 and not building.Roof then
				return
			end
			if floor < -1 or floor >= building.Floors then
				return
			end
			goTo(player, building, floor, true)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		elevatorOpen[player] = nil
	end)

	-- Al morir o reaparecer ya no estás dentro de ninguna sala
	local function watch(player: Player)
		player.CharacterAdded:Connect(function()
			if player:GetAttribute("InteriorKey") and player:GetAttribute("SpawnReady") then
				player:SetAttribute("InteriorKey", nil)
				player:SetAttribute("InteriorDoor", nil)
				player:SetAttribute("TowerFloor", nil)
			end
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
			InteriorService.stepTowers()
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
