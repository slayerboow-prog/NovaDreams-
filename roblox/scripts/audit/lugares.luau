-- Prueba de LUGARES contra el MAPA REAL (M-03 de la auditoría narrativo-cinematográfica).
--
-- Los arneses de la historia (StoryHarness) usan un LocationService falso que «encuentra» cualquier
-- lugar. Esta prueba construye el mapa de verdad (el mismo TownBuilder que usa el servidor) y comprueba
-- que cada lugar de src/shared/LifeStory/Locations.luau existe en él, como lo buscaría
-- LocationService.resolve: por modelo, por etiqueta y atributos, por pieza hija, entre dos lugares,
-- en su zona, y si no, por su Fallback.
--
-- Uso (desde roblox/):
--   lune run scripts/audit/lugares.luau                 (construye el mapa en un archivo temporal: ~3 min)
--   lune run scripts/audit/lugares.luau X.rbxl          (usa un mapa ya construido con:
--        rojo build default.project.json -o X.rbxl && lune run scripts/build-place.luau X.rbxl)
--
-- Resultado por lugar:
--   ✔ está                   · lo encuentra en el mapa (y en su zona, si la pide)
--   ↪ plan B                 · no está, pero su Fallback sí (la misión pasa en otro sitio: aviso)
--   ⏱ en partida             · lo crea el juego al jugar (la casa del jugador, «delante de ti», o una
--                              etiqueta que pone un servicio al arrancar): no se puede ver en el mapa
--   ❌ falta                  · ni él ni su plan B: el vigilante daría el paso por hecho en silencio
--   ⚠ zona                   · existe, pero no en la zona que pide (LocationService usa otro sitio)
-- Falla (código 1) si algún lugar que usan las misiones falta, o si su zona no existe.

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local H = require("../lib/StoryHarness")
local ROOT, loadModule = H.ROOT, H.loadModule
local Locations = loadModule(ROOT .. "/shared/LifeStory/Locations")
local CityPlan = loadModule(ROOT .. "/shared/CityPlan")
local Quests = H.Quests

local check = H.check

---------------------------------------------------------------------
-- 1. El mapa
---------------------------------------------------------------------
local placePath = process.args[1]
if not placePath then
	local dir = (process.env.TMPDIR or "/tmp") .. "/lugares-" .. tostring(os.time())
	fs.writeDir(dir)
	placePath = dir .. "/mapa.rbxl"
	print("▶ Construyendo el mapa (rojo build + build-place) en " .. placePath)
	local build = process.exec("rojo", { "build", "default.project.json", "-o", placePath })
	if not build.ok then
		print(build.stderr)
		process.exit(1)
	end
	local town = process.exec("lune", { "run", "scripts/build-place.luau", placePath })
	print("  " .. (town.stdout:gsub("%s+$", "")))
	if not town.ok then
		print(town.stderr)
		process.exit(1)
	end
end
print("▶ Leyendo " .. placePath)
local game = roblox.deserializePlace(fs.readFile(placePath))
local workspace = game:GetService("Workspace")
local town = workspace:FindFirstChild("Town")
check(town ~= nil, "El mapa tiene la ciudad (workspace.Town)")
if not town then
	process.exit(1)
end

-- Lo que el servidor construye FUERA de TownBuilder al arrancar y siempre (Main.server.luau, paso 3b):
-- la isla del sueño del prólogo. Se construye aquí igual, con las Instance de Lune.
do
	local luau = require("@lune/luau")
	local cache = {}
	local function nodeFor(path: string)
		return setmetatable({ __path = path }, {
			__index = function(self, key)
				if key == "Parent" then
					return nodeFor((path:match("^(.*)/[^/]+$")))
				end
				return nodeFor(path .. "/" .. key)
			end,
		})
	end
	local function requireModule(target)
		local path = rawget(target, "__path")
		if cache[path] ~= nil then
			return cache[path]
		end
		local env = setmetatable({
			script = target,
			require = requireModule,
			workspace = workspace,
			game = game,
			Instance = roblox.Instance,
			Vector3 = roblox.Vector3,
			Vector2 = roblox.Vector2,
			CFrame = roblox.CFrame,
			Color3 = roblox.Color3,
			Enum = roblox.Enum,
			UDim = roblox.UDim,
			UDim2 = roblox.UDim2,
			Font = roblox.Font,
			NumberRange = roblox.NumberRange,
			NumberSequence = roblox.NumberSequence,
			ColorSequence = roblox.ColorSequence,
		}, { __index = getfenv(1) })
		local chunk = luau.load(fs.readFile(path .. ".luau"), { debugName = path, environment = env })
		cache[path] = chunk()
		return cache[path]
	end
	local ok, err = pcall(function()
		requireModule(nodeFor(ROOT .. "/server/World/Kit/DreamIsland")).build()
	end)
	check(ok and workspace:FindFirstChild("DreamIsland") ~= nil, "La isla del sueño (prólogo) se construye como en el servidor" .. (if ok then "" else ": " .. tostring(err)))
end

-- Zonas: Valmar Centro en el origen y las ciudades del plano (como LocationService.zoneAt)
local zones = {}
for name, at in CityPlan.Towns do
	table.insert(zones, { Name = name, Center = roblox.Vector3.new(at[1], 0, at[2]) })
end
local function zoneAt(position)
	local best, bestDistance = "Valmar Centro", math.huge
	for _, zone in zones do
		local offset = position - zone.Center
		local distance = roblox.Vector3.new(offset.X, 0, offset.Z).Magnitude
		if distance < bestDistance then
			best, bestDistance = zone.Name, distance
		end
	end
	return best
end

-- Posición aproximada de un modelo o pieza (para la zona: las ciudades están a cientos de studs)
local function positionOf(instance): any
	if instance:IsA("BasePart") then
		return instance.CFrame.Position
	end
	if instance:IsA("Model") then
		local primary = instance.PrimaryPart
		if primary then
			return primary.CFrame.Position
		end
		local ok, pivot = pcall(function()
			return instance.WorldPivot
		end)
		if ok and pivot and pivot.Position.Magnitude > 0 then
			return pivot.Position
		end
		for _, d in instance:GetDescendants() do
			if d:IsA("BasePart") then
				return d.CFrame.Position
			end
		end
	end
	return nil
end

-- Índices: modelos por nombre y piezas por etiqueta (una sola pasada)
local wantedModels, wantedTags = {}, {}
for _, place in Locations.Places do
	if place.Model then
		wantedModels[place.Model] = true
	end
	if place.Tag then
		wantedTags[place.Tag] = true
	end
end
local byModel: { [string]: { any } } = {}
local byTag: { [string]: { any } } = {}
local plots = 0
local function index(root)
	for _, d in root:GetDescendants() do
		if d:IsA("Model") and wantedModels[d.Name] then
			byModel[d.Name] = byModel[d.Name] or {}
			table.insert(byModel[d.Name], d)
		end
		if d.Name:sub(1, 5) == "Plot_" then
			plots += 1
		end
		local ok, tags = pcall(function()
			return d:GetTags()
		end)
		if ok and tags then
			for _, tag in tags do
				if wantedTags[tag] then
					byTag[tag] = byTag[tag] or {}
					table.insert(byTag[tag], d)
				end
			end
		end
	end
end
index(workspace)
local familyHomeIds = {}
for _, home in byTag.FamilyHome or {} do
	local id = home:GetAttribute("HomeId")
	if id ~= nil then
		familyHomeIds[id] = true
	end
end

-- Etiquetas y marcas (StoryMarks) que pone el juego AL JUGAR (los servicios, y los pliegues de la Grieta
-- que construye UserArsenal con los paquetes de modelos), y no el constructor del mapa
local runtimeTags: { [string]: boolean } = {}
local runtimeMarks: { [string]: string } = {} -- id de la marca -> archivo que la crea
local function scanRuntimeFile(path: string)
	local source = fs.readFile(path)
	for tag in source:gmatch('AddTag%([^"]-"([%w_]+)"%)') do
		runtimeTags[tag] = true
	end
	for id in source:gmatch('StoryMarks%.%a+%([^,]+,%s*"([%w_]+)"') do
		runtimeMarks[id] = (path:gsub("^" .. ROOT .. "/", ""))
	end
end
local function scanRuntime(dir: string)
	for _, name in fs.readDir(dir) do
		local path = dir .. "/" .. name
		if fs.isDir(path) then
			if name ~= "World" then
				scanRuntime(path)
			end
		elseif name:match("%.luau$") then
			scanRuntimeFile(path)
		end
	end
end
scanRuntime(ROOT .. "/server")
scanRuntimeFile(ROOT .. "/server/World/Kit/Pliegues.luau")

---------------------------------------------------------------------
-- 2. Resolver cada lugar como LocationService (pero sin jugador)
---------------------------------------------------------------------
type Result = { Status: string, Detail: string? }
local results: { [string]: Result } = {}

local function attributesMatch(instance, wanted): boolean
	for name, value in wanted or {} do
		if instance:GetAttribute(name) ~= value then
			return false
		end
	end
	return true
end

local resolve
local function direct(id: string, place): Result
	if place.Special == "NearPlayer" then
		return { Status = "Partida", Detail = "delante del jugador" }
	end
	if place.Special == "Home" then
		return { Status = "Partida", Detail = if plots > 0 then ("parcela del jugador (%d en el mapa)"):format(plots) else "parcela del jugador (se crean al jugar)" }
	end
	if place.Between then
		local a, b = resolve(place.Between[1]), resolve(place.Between[2])
		local okA = a.Status ~= "Falta"
		local okB = b.Status ~= "Falta"
		if okA and okB then
			return { Status = "Ok", Detail = "entre " .. place.Between[1] .. " y " .. place.Between[2] }
		end
		return { Status = "Falta", Detail = "falta " .. (if okA then place.Between[2] else place.Between[1]) }
	end
	local list = {}
	local source = ""
	if place.Model then
		source = "modelo " .. place.Model
		for _, model in byModel[place.Model] or {} do
			if attributesMatch(model, place.Attribute) then
				table.insert(list, model)
			end
		end
	elseif place.Tag then
		source = "etiqueta " .. place.Tag
		for _, instance in byTag[place.Tag] or {} do
			if attributesMatch(instance, place.Attribute) then
				table.insert(list, instance)
			end
		end
		if #list == 0 and runtimeTags[place.Tag] then
			return { Status = "Partida", Detail = "la etiqueta " .. place.Tag .. " la pone un servicio al jugar" }
		end
		local markId = place.Attribute and (place.Attribute.SpotId or place.Attribute.AreaId or place.Attribute.PropId)
		if #list == 0 and markId and runtimeMarks[markId] then
			return { Status = "Partida", Detail = ("la marca %s la crea %s al jugar"):format(markId, runtimeMarks[markId]) }
		end
	else
		return { Status = "Falta", Detail = "no dice cómo encontrarlo (Model, Tag, Special o Between)" }
	end
	if place.Attribute then
		local parts = {}
		for k, v in place.Attribute do
			table.insert(parts, k .. "=" .. tostring(v))
		end
		table.sort(parts)
		source ..= " [" .. table.concat(parts, ", ") .. "]"
	end
	if #list == 0 then
		return { Status = "Falta", Detail = "no hay " .. source }
	end
	-- Zona
	local zone = place.Zone
	if zone == "FamilyHome" then
		local mine = {}
		for _, instance in list do
			if familyHomeIds[instance:GetAttribute("HomeId")] then
				table.insert(mine, instance)
			end
		end
		if #mine == 0 then
			return { Status = "Falta", Detail = source .. " sin HomeId de una casa familiar" }
		end
		list = mine
	elseif zone and zone ~= "Home" and zone ~= "Nearest" then
		local known = false
		for _, z in zones do
			known = known or z.Name == zone
		end
		if not known then
			return { Status = "Falta", Detail = "la zona «" .. zone .. "» no existe" }
		end
		local inZone = {}
		for _, instance in list do
			local position = positionOf(instance)
			if position and zoneAt(position) == zone then
				table.insert(inZone, instance)
			end
		end
		if #inZone == 0 then
			return { Status = "Zona", Detail = ("%s: %d en el mapa, ninguno en %s"):format(source, #list, zone) }
		end
		list = inZone
	end
	-- Pieza hija
	if place.Child then
		local with = 0
		for _, instance in list do
			if instance:FindFirstChild(place.Child, true) then
				with += 1
			end
		end
		if with == 0 then
			return { Status = "Falta", Detail = ("%s sin la pieza %s"):format(source, place.Child) }
		elseif with < #list then
			return { Status = "Ok", Detail = ("%s: %d de %d con %s (los demás usan el plan B)"):format(source, with, #list, place.Child) }
		end
	end
	return { Status = "Ok", Detail = ("%s (%d)"):format(source, #list) }
end

local resolving = {}
function resolve(id: string): Result
	if results[id] then
		return results[id]
	end
	local place = Locations.Places[id]
	if not place then
		return { Status = "Falta", Detail = "no está en Locations" }
	end
	if resolving[id] then
		return { Status = "Falta", Detail = "Fallback en bucle" }
	end
	resolving[id] = true
	local result = direct(id, place)
	if result.Status == "Falta" and place.Fallback then
		local fallback = resolve(place.Fallback)
		if fallback.Status ~= "Falta" then
			result = { Status = "PlanB", Detail = result.Detail .. " → " .. place.Fallback }
		else
			result.Detail = result.Detail .. " → " .. place.Fallback .. " tampoco"
		end
	end
	resolving[id] = nil
	results[id] = result
	return result
end

---------------------------------------------------------------------
-- 3. Qué lugares usan las misiones (cualquier texto de sus datos que sea un lugar)
---------------------------------------------------------------------
local usedBy: { [string]: { [string]: boolean } } = {}
local function scanData(questId: string, value: any, seen: { [any]: boolean })
	if type(value) == "string" then
		if Locations.Places[value] then
			usedBy[value] = usedBy[value] or {}
			usedBy[value][questId] = true
		elseif value:sub(1, 9) == "$Carrera." then
			-- Lugar según tu carrera (Subjects.resolve): cuentan los de TODAS las carreras
			for degreeId in H.Subjects.Degrees do
				local resolved = H.Subjects.resolve(value, degreeId)
				if type(resolved) == "string" and Locations.Places[resolved] then
					usedBy[resolved] = usedBy[resolved] or {}
					usedBy[resolved][questId] = true
				end
			end
		end
	elseif type(value) == "table" and not seen[value] then
		seen[value] = true
		for k, v in value do
			scanData(questId, k, seen)
			scanData(questId, v, seen)
		end
	end
end
for questId, quest in Quests do
	scanData(questId, quest, {})
end
-- Lugares que piden los Fallback de lugares usados también cuentan
local function questsOf(id: string): string
	local list = {}
	for questId in usedBy[id] or {} do
		table.insert(list, questId)
	end
	table.sort(list)
	if #list > 4 then
		return table.concat(list, ", ", 1, 4) .. (" y %d más"):format(#list - 4)
	end
	return table.concat(list, ", ")
end

---------------------------------------------------------------------
-- 4. Informe
---------------------------------------------------------------------
local ids = {}
for id in Locations.Places do
	table.insert(ids, id)
end
table.sort(ids)
local counts = { Ok = 0, PlanB = 0, Partida = 0, Falta = 0, Zona = 0 }
local icon = { Ok = "✔", PlanB = "↪", Partida = "⏱", Falta = "❌", Zona = "⚠" }
local missingUsed, wrongZoneUsed, fallbackUsed = {}, {}, {}
print(("\n▶ %d lugares de Locations contra el mapa (%d modelos y %d etiquetas indexados)"):format(#ids, (function()
	local n = 0
	for _ in byModel do
		n += 1
	end
	return n
end)(), (function()
	local n = 0
	for _ in byTag do
		n += 1
	end
	return n
end)()))
for _, id in ids do
	local result = resolve(id)
	counts[result.Status] += 1
	local used = usedBy[id] ~= nil
	if result.Status ~= "Ok" or (result.Detail or ""):find("los demás", 1, true) then
		print(("  %s %-26s %s%s"):format(icon[result.Status], id, result.Detail or "", if used then "   · usan: " .. questsOf(id) else "   · (ninguna misión)"))
	end
	if used and result.Status == "Falta" then
		table.insert(missingUsed, id)
	elseif used and result.Status == "Zona" then
		table.insert(wrongZoneUsed, id)
	elseif used and result.Status == "PlanB" then
		table.insert(fallbackUsed, id)
	end
end
print(("  Resumen: %d ✔ · %d ↪ plan B · %d ⏱ en partida · %d ⚠ zona · %d ❌ faltan"):format(counts.Ok, counts.PlanB, counts.Partida, counts.Zona, counts.Falta))

-- Lugares que nombran las misiones pero NO están en Locations (los detecta también el validador)
local unknown = {}
for questId, quest in Quests do
	local function stepPlaces(steps)
		for _, step in steps or {} do
			if type(step) == "table" then
				for _, key in { "Place" } do
					local value = step[key]
					if type(value) == "string" and value:sub(1, 9) == "$Carrera." then
						-- Tiene que ser un lugar con CADA carrera
						for degreeId in H.Subjects.Degrees do
							local resolved = H.Subjects.resolve(value, degreeId)
							if type(resolved) ~= "string" or not Locations.Places[resolved] then
								table.insert(unknown, ("%s: %s con %s = %s"):format(questId, value, degreeId, tostring(resolved)))
							end
						end
					elseif type(value) == "string" and not Locations.Places[value] and not value:find("{", 1, true) then
						table.insert(unknown, questId .. ": " .. value)
					end
				end
				stepPlaces(step.Steps)
			end
		end
	end
	stepPlaces(quest.Steps)
end

print("\n▶ Comprobaciones")
check(#missingUsed == 0, ("Cada lugar que usan las misiones existe en el mapa o en su plan B%s"):format(if #missingUsed > 0 then " (faltan: " .. table.concat(missingUsed, ", ") .. ")" else ""))
check(#wrongZoneUsed == 0, ("Cada lugar con zona está en su zona%s"):format(if #wrongZoneUsed > 0 then " (fuera de zona: " .. table.concat(wrongZoneUsed, ", ") .. ")" else ""))
check(counts.Falta == 0, ("Ningún lugar de Locations falta del todo (%d)"):format(counts.Falta))
check(#unknown == 0, "Los pasos solo nombran lugares de Locations" .. (if #unknown > 0 then " (" .. table.concat(unknown, ", ") .. ")" else ""))
if #fallbackUsed > 0 then
	print(("  ℹ %d lugares usados funcionan solo por su plan B: %s"):format(#fallbackUsed, table.concat(fallbackUsed, ", ")))
end

print(("\n%s"):format(if H.failures == 0 then "✅ Todo correcto" else ("❌ %d fallos"):format(H.failures)))
process.exit(if H.failures == 0 then 0 else 1)
