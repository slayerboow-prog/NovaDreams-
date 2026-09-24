-- AssetLibrary: usa modelos importados (por ejemplo, los packs gratuitos de Synty
-- de la Creator Store) cuando existen, y si no, deja que el kit use su versión por código.
--
-- Los modelos viven en ServerStorage.AssetLibrary. En el repositorio, cada archivo
-- roblox/assets/*.rbxm se convierte en una carpeta dentro de AssetLibrary (lo hace Rojo).
--
-- Cada tipo de elemento ("Tree", "Car"…) tiene:
--   Patterns: trozos del nombre del modelo que lo identifican (sin mayúsculas)
--   Height:   altura objetivo en studs (se escala el modelo para encajar), opcional
--   Yaw:      giro extra si el "frente" del modelo no mira a -Z
-- También se puede forzar poniendo al modelo el atributo Asset = "Tree".

local Place = require(script.Parent.Place)

local AssetLibrary = {}

type Entry = { Patterns: { string }, Exclude: { string }?, Height: number?, Yaw: number? }

AssetLibrary.Catalog = {
	Tree = { Patterns = { "env_tree", "tree_" }, Exclude = { "palm", "pine", "dead", "stump", "log" }, Height = 16 },
	Pine = { Patterns = { "pine" }, Exclude = { "cone" }, Height = 18 },
	Palm = { Patterns = { "palm" }, Height = 20 },
	Bush = { Patterns = { "bush", "shrub" }, Height = 3.5 },
	Lamp = { Patterns = { "streetlight", "street_light", "lamppost", "lamp_post" }, Height = 15 },
	Bench = { Patterns = { "bench" }, Height = 3.4 },
	Bin = { Patterns = { "bin_", "trashcan", "trash_can", "rubbish" }, Height = 3 },
	Car = { Patterns = { "veh_car", "car_sedan", "car_hatch", "car_suv", "sedan", "hatchback" }, Exclude = { "wheel", "door", "police", "taxi" }, Height = 5.2 },
	TrafficLight = { Patterns = { "trafficlight", "traffic_light" }, Height = 15 },
	BusStop = { Patterns = { "busstop", "bus_stop", "bus_shelter" }, Height = 8.5 },
	Hydrant = { Patterns = { "hydrant" }, Height = 2.6 },
	Planter = { Patterns = { "planter", "flowerbed", "flower_bed" }, Height = 2.5 },
} :: { [string]: Entry }

local cache: { [string]: { Instance } } = {}

local function root(): Instance?
	local ok, storage = pcall(function()
		return game:GetService("ServerStorage")
	end)
	if not ok or not storage then
		return nil
	end
	return storage:FindFirstChild("AssetLibrary")
end

local function matches(name: string, entry: Entry): boolean
	local lower = string.lower(name)
	for _, bad in entry.Exclude or {} do
		if string.find(lower, bad, 1, true) then
			return false
		end
	end
	for _, pattern in entry.Patterns do
		if string.find(lower, pattern, 1, true) then
			return true
		end
	end
	return false
end

local function hasParts(instance: Instance): boolean
	if instance:IsA("BasePart") then
		return true
	end
	for _, d in instance:GetDescendants() do
		if d:IsA("BasePart") then
			return true
		end
	end
	return false
end

-- Plantillas disponibles para un tipo (se buscan una vez y se guardan)
function AssetLibrary.variants(kind: string): { Instance }
	if cache[kind] then
		return cache[kind]
	end
	local list = {}
	local entry = AssetLibrary.Catalog[kind]
	local library = root()
	if library and entry then
		for _, d in library:GetDescendants() do
			if (d:IsA("Model") or d:IsA("BasePart")) and hasParts(d) then
				local forced = d:GetAttribute("Asset")
				if forced == kind or (forced == nil and matches(d.Name, entry)) then
					-- Evitamos piezas sueltas que forman parte de un modelo ya elegido
					local parentChosen = false
					for _, chosen in list do
						if d:IsDescendantOf(chosen) then
							parentChosen = true
							break
						end
					end
					if not parentChosen then
						table.insert(list, d)
					end
				end
			end
		end
	end
	cache[kind] = list
	return list
end

function AssetLibrary.has(kind: string): boolean
	return #AssetLibrary.variants(kind) > 0
end

-- Crea una copia de un modelo del tipo pedido en "target" (base del modelo).
-- Devuelve nil si no hay ninguno: el que llama usa entonces su versión por código.
function AssetLibrary.spawn(kind: string, parent: Instance, target: CFrame, scale: number?): Instance?
	local variants = AssetLibrary.variants(kind)
	if #variants == 0 then
		return nil
	end
	local entry = AssetLibrary.Catalog[kind]
	local copy = variants[math.random(1, #variants)]:Clone()
	Place.sanitize(copy)
	local minV, maxV = Place.bounds(copy)
	local factor = scale or 1
	if entry.Height and maxV.Y > minV.Y then
		factor *= entry.Height / (maxV.Y - minV.Y)
	end
	Place.scale(copy, factor, Vector3.new((minV.X + maxV.X) / 2, minV.Y, (minV.Z + maxV.Z) / 2))
	Place.put(copy, target, entry.Yaw)
	copy.Parent = parent
	return copy
end

return AssetLibrary
