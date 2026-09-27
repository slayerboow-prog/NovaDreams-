-- InteriorService: todos los edificios del mapa se pueden visitar por dentro.
--
--   * Al arrancar busca cada edificio de la ciudad (casas, villas, bloques de pisos, oficinas,
--     comercios, naves, talleres, locales de ocio, facultades y los monumentos) y le pone en la
--     puerta un cartel "Entrar" con lo que hay dentro.
--   * Al entrar se monta su interior (World/Interiors) en una zona oculta, lejos de la ciudad, y
--     te lleva allí; "Salir" te devuelve a la calle, delante de la puerta. Las salas se quitan
--     solas cuando se quedan vacías (así el móvil no carga 900 interiores a la vez).
--   * Los edificios de varias plantas tienen ascensor: eliges planta (panel del cliente, InteriorUI).
--     En la Torre de Valmar se puede subir a la azotea (la de verdad, con vistas).
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

local Interiors = require(script.Parent.Parent.World.Interiors)
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
}
export type Instance_ = { Room: Interiors.Room, Slot: number, Building: Building, Floor: number, EmptySince: number? }

-- Enganches para las viviendas (PropertyService)
export type Hooks = {
	Gate: ((Player, Building, number) -> (boolean, string?))?, -- ¿puede entrar en esa planta?
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

local function instanceOf(building: Building, floor: number): Instance_?
	local key = building.Id .. ":" .. floor
	local existing = instances[key]
	if existing and existing.Room.Model.Parent then
		return existing
	end
	local kind = if floor == 0 then building.Kind else (building.Upper or "Piso")
	local builder = (Interiors :: any)[kind]
	if not builder then
		return nil
	end
	local slot = takeSlot()
	-- (la semilla de los muebles: el mismo edificio y la misma planta, siempre igual)
	local r = builder(folder, CFrame.new(slotPosition(slot)), { Seed = building.Key .. ":" .. floor, Floor = floor, Shop = if floor == 0 then building.Shop else nil })
	r.Model:SetAttribute("Key", key)
	local inst: Instance_ = { Room = r, Slot = slot, Building = building, Floor = floor, EmptySince = nil }
	instances[key] = inst
	connectRoom(inst)
	local decorate = InteriorService.Hooks.Decorate
	if decorate then
		local ok, err = pcall(decorate, inst)
		if not ok then
			warn("[Interiores] " .. tostring(err))
		end
	end
	for _, listener in builtListeners do
		local ok, err = pcall(listener, inst)
		if not ok then
			warn("[Interiores] " .. tostring(err))
		end
	end
	return inst
end

-- Avisa cada vez que se monta una sala (y ahora mismo, de las que ya están montadas)
function InteriorService.onBuilt(listener: (Instance_) -> ())
	table.insert(builtListeners, listener)
	for _, inst in instances do
		if inst.Room.Model.Parent then
			task.spawn(listener, inst)
		end
	end
end

-- La sala montada con esa clave ("id:planta", el atributo Key de su modelo)
function InteriorService.fromKey(key: string): Instance_?
	local inst = instances[key]
	return if inst and inst.Room.Model.Parent then inst else nil
end

local function entryOf(inst: Instance_): Vector3
	local entry = inst.Room.Model:FindFirstChild("InteriorEntry") :: BasePart?
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

local function goTo(player: Player, building: Building, floor: number)
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
	local gate = InteriorService.Hooks.Gate
	if gate then
		local ok, allowed, why = pcall(gate, player, building, floor)
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

-- La sala montada de esa planta (nil si ahora no hay nadie dentro)
function InteriorService.instance(building: Building, floor: number): Instance_?
	local inst = instances[building.Id .. ":" .. floor]
	return if inst and inst.Room.Model.Parent then inst else nil
end

-- Quita la sala de esa planta (se vuelve a montar al entrar: p. ej. al cambiar de dueño)
function InteriorService.reset(building: Building, floor: number)
	local key = building.Id .. ":" .. floor
	local inst = instances[key]
	if inst then
		inst.Room.Model:Destroy()
		instances[key] = nil
		table.insert(freeSlots, inst.Slot)
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
	local door = player:GetAttribute("InteriorDoor")
	player:SetAttribute("InteriorKey", nil)
	player:SetAttribute("InteriorDoor", nil)
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
	Remote:FireClient(player, "Elevator", {
		Labels = labels,
		Title = building.Title,
		Floors = building.Floors,
		Roof = building.Roof ~= nil,
		Current = tonumber(string.match(player:GetAttribute("InteriorKey") or "", ":(%d+)$")) or 0,
	})
end

function connectRoom(inst: Instance_)
	for _, part in inst.Room.Model:GetDescendants() do
		if part:IsA("BasePart") and part:HasTag("InteriorExit") then
			local prompt = Builder.prompt(part, "Salir", "🚪 A la calle", 0.2)
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
	for _, building in list do
		addDoor(building)
		if building.Persistent then
			instanceOf(building, 0)
		end
	end
	print(("[Interiores] %d edificios visitables"):format(#list))

	Remote.OnServerEvent:Connect(function(player: Player, kind: any, value: any)
		if kind == "Floor" and type(value) == "number" then
			local building = buildings[player:GetAttribute("ElevatorBuilding") or 0]
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
			goTo(player, building, floor)
		end
	end)

	-- Al morir o reaparecer ya no estás dentro de ninguna sala
	local function watch(player: Player)
		player.CharacterAdded:Connect(function()
			if player:GetAttribute("InteriorKey") and player:GetAttribute("SpawnReady") then
				player:SetAttribute("InteriorKey", nil)
				player:SetAttribute("InteriorDoor", nil)
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end

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
