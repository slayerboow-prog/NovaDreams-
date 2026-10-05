-- diag-modulos: arranca a la vez (como Main.server.luau) los módulos de assets y cuenta lo que cargan y colocan
--
-- Diagnóstico de la v89 (docs/diagnostico-v89.md). Cada módulo va en su hilo y con su pcall, igual que en
-- el juego; se espera hasta ~4 min y se cuenta: plantillas por tipo, piezas colocadas, MaterialVariant,
-- SetBaseMaterialOverride, carrocerías, cielos… y los avisos de cada módulo (ids que no cargan).
-- PARTE = "a" o "b" (abajo) para repartir el trabajo si no da tiempo: a = vegetación, coches, cielo y armas;
-- b = materiales, zonas de misión, calle e interiores. "todo" = todo a la vez.
--
-- Uso: bash scripts/cloud-test.sh --version 89 -v diag-modulos

local Cloud = Cloud :: any
local PARTE = "todo" -- @@PARTE@@
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local LogService = game:GetService("LogService")
local World = Cloud.Server:WaitForChild("World")

local function line(s: string)
	print("[diag] " .. s)
end

-- Lo que dicen los módulos por la consola (prints y avisos con su etiqueta)
local TAGS = { "MeshLibrary", "NatureAssets", "CityAssets", "InteriorProps", "UserMaterials", "MaterialExtras", "CarBodies",
	"SkyAssets", "UserArsenal", "MissionZones", "Assets", "Buildings3D", "StreetDress", "HouseDress", "InteriorDress", "Pliegues" }
local said: { [string]: { string } } = {}
LogService.MessageOut:Connect(function(message, kind)
	for _, tag in TAGS do
		if string.find(message, "[" .. tag .. "]", 1, true) then
			said[tag] = said[tag] or {}
			if #said[tag] < 80 then
				local k = if kind == Enum.MessageType.MessageWarning then "⚠ " elseif kind == Enum.MessageType.MessageError then "✖ " else ""
				table.insert(said[tag], k .. string.sub(message, 1, 300))
			end
			return
		end
	end
end)

local done: { [string]: { ok: boolean, err: string?, s: number } } = {}
local running = 0
local function run(name: string, fn: () -> ())
	running += 1
	task.spawn(function()
		local t = os.clock()
		local ok, err = pcall(fn)
		done[name] = { ok = ok, err = if ok then nil else tostring(err), s = math.floor((os.clock() - t) * 10) / 10 }
		running -= 1
		line(("%s terminó en %.1f s%s"):format(name, os.clock() - t, if ok then "" else (": ERROR " .. tostring(err))))
	end)
end

local results: { [string]: any } = {}
local function kindsOf(lib: { [string]: { any } }?): string
	local list = {}
	local total = 0
	for kind, l in lib or {} do
		table.insert(list, ("%s=%d"):format(kind, #l))
		total += #l
	end
	table.sort(list)
	return ("%d plantillas: %s"):format(total, table.concat(list, " "))
end

-- CityAssets espera a que InteriorService haya mirado los edificios (aquí no arranca): se le da ya
workspace:SetAttribute("InteriorsScanned", true)

local A = PARTE == "a" or PARTE == "todo"
local B = PARTE == "b" or PARTE == "todo"

if A then
	run("MeshLibrary.load", function()
		local MeshLibrary = require(World.MeshLibrary) :: any
		local lib = MeshLibrary.load()
		results.MeshLibrary = kindsOf(lib)
	end)
	run("NatureAssets.load", function()
		local NatureAssets = require(World.NatureAssets) :: any
		local lib = NatureAssets.load()
		results.NatureAssets = kindsOf(lib)
		local log = {}
		for _, e in NatureAssets.Log do
			table.insert(log, tostring(e.Id))
		end
		local missing = {}
		for _, p in NatureAssets.Packs do
			if not table.find(log, tostring(p.Id)) and not NatureAssets.Blocked[p.Id] then
				table.insert(missing, ("%s %d"):format(p.Name, p.Id))
			end
		end
		results.NatureAssets_packs = ("%d de %d packs cargados; no cargan: %s"):format(#log, #NatureAssets.Packs, table.concat(missing, ", "))
	end)
	run("CarBodies.start", function()
		local CarBodies = require(World.Kit.CarBodies) :: any
		-- Qué ids fallan (con el mismo orden que CarBodies.start: el primero y sus Fallback)
		local failed = {}
		local function loader(id: number): Instance?
			local inst = CarBodies.download(id)
			if not inst then
				table.insert(failed, tostring(id))
			end
			return inst
		end
		CarBodies.start(loader)
		local store = ServerStorage:FindFirstChild("CarBodies")
		local names = {}
		if store then
			for _, c in store:GetChildren() do
				table.insert(names, c.Name)
			end
		end
		results.CarBodies = ("estado %s, %d carrocerías (%s); ids que fallan: %s"):format(tostring(CarBodies.State), #names,
			table.concat(names, ", "), if #failed > 0 then table.concat(failed, ", ") else "ninguno")
	end)
	run("SkyAssets.start", function()
		require(World.SkyAssets).start()
		local SkyExtras = require(ReplicatedStorage.Shared.SkyExtras) :: any
		local lib = ReplicatedStorage:FindFirstChild(SkyExtras.Library)
		local fx = ReplicatedStorage:FindFirstChild(SkyExtras.FxLibrary)
		local skies, fxs, attrs = {}, {}, 0
		for _, c in (if lib then lib:GetChildren() else {}) do
			table.insert(skies, c.Name)
		end
		for _, c in (if fx then fx:GetChildren() else {}) do
			table.insert(fxs, c.Name)
		end
		if fx then
			for _ in fx:GetAttributes() do
				attrs += 1
			end
		end
		results.SkyAssets = ("%d cielos (%s); FxLibrary: %d objetos (%s) y %d atributos"):format(#skies, table.concat(skies, ", "), #fxs, table.concat(fxs, ", "), attrs)
	end)
	run("UserArsenal.load", function()
		local UserArsenal = require(World.UserArsenal) :: any
		local lib = UserArsenal.load()
		local props = {}
		for k in lib.Props do
			table.insert(props, k)
		end
		table.sort(props)
		local rep = {}
		for id, what in lib.Report do
			table.insert(rep, ("%d: %s"):format(id, what))
		end
		table.sort(rep)
		results.UserArsenal = ("armas %s; props %d (%s); informe: %s"):format(kindsOf(lib.Weapons), #props, table.concat(props, ", "), table.concat(rep, " | "))
	end)
end

if B then
	run("UserMaterials.start (+StreetDress, HouseDress, InteriorDress, MaterialExtras)", function()
		require(World.UserMaterials).start(nil, function(service, library, load, unpack)
			require(World.StreetDress).start(service, library, load, unpack, nil, require(World.Region).Highways)
		end)
		local ME = require(World.MaterialExtras) :: any
		results.MaterialExtras = ("láminas puestas %d, bronce %d"):format(ME.used or -1, ME.bronzed or -1)
	end)
	run("MissionZones.start", function()
		local folder = require(World.MissionZones).start(nil, nil, nil, nil, 200)
		local n = 0
		for _, d in folder:GetDescendants() do
			if d:IsA("BasePart") then
				n += 1
			end
		end
		local mv = 0
		for _, d in folder:GetDescendants() do
			if d:IsA("BasePart") and d.MaterialVariant ~= "" then
				mv += 1
			end
		end
		results.MissionZones = ("%d piezas, %d con MaterialVariant"):format(n, mv)
	end)
	run("CityAssets.start", function()
		require(World.CityAssets).start()
	end)
	run("InteriorProps.start", function()
		require(World.InteriorProps).start()
		local stored = ReplicatedStorage:FindFirstChild("MueblesValmar") or ReplicatedStorage:FindFirstChild(require(World.InteriorProps).Folder)
		local n = 0
		local town = workspace:FindFirstChild("Town")
		if town then
			for _, d in town:GetDescendants() do
				if d.Name == "MueblesValmar" then
					n += #d:GetChildren()
				end
			end
		end
		results.InteriorProps = ("%d objetos de la Tienda colocados en la ciudad (carpetas MueblesValmar); almacén en ReplicatedStorage: %s"):format(n, tostring(stored ~= nil))
	end)
end

-- Esperar (hasta ~4 min). CityAssets e InteriorProps se quedan escuchando: «terminó» = su start volvió.
local t0 = os.clock()
while running > 0 and Cloud.quedan() > 25 do
	task.wait(2)
end
line(("Espera: %.0f s; siguen en marcha %d"):format(os.clock() - t0, running))

-- Recuento final
local MaterialService = game:GetService("MaterialService")
local variants = 0
for _, d in MaterialService:GetDescendants() do
	if d:IsA("MaterialVariant") then
		variants += 1
	end
end
local overrides = {}
for _, m in Enum.Material:GetEnumItems() do
	local ok, v = pcall(function()
		return MaterialService:GetBaseMaterialOverride(m)
	end)
	if ok and v and v ~= "" then
		table.insert(overrides, m.Name .. "=" .. v)
	end
end
results.MaterialService = ("%d MaterialVariant; %d SetBaseMaterialOverride: %s"):format(variants, #overrides, table.concat(overrides, ", "))
local um = ServerStorage:FindFirstChild("UserMaterials")
if um then
	local packs = {}
	for _, c in um:GetChildren() do
		table.insert(packs, ("%s(%d)"):format(c.Name, #c:GetChildren()))
	end
	results.UserMaterials_biblioteca = table.concat(packs, ", ")
end
local town = workspace:FindFirstChild("Town")
local placed = town and town:FindFirstChild("ActivosCiudad")
if placed then
	local parts, models = 0, 0
	for _, d in placed:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
		elseif d:IsA("Model") and d.Parent == placed then
			models += 1
		end
	end
	results.CityAssets_colocado = ("Town.ActivosCiudad: %d hijos, %d piezas"):format(#placed:GetChildren(), parts)
end

for _, name in { "MeshLibrary.load", "NatureAssets.load", "CarBodies.start", "SkyAssets.start", "UserArsenal.load",
	"UserMaterials.start (+StreetDress, HouseDress, InteriorDress, MaterialExtras)", "MissionZones.start", "CityAssets.start", "InteriorProps.start" } do
	local d = done[name]
	local selected = (A and (name:find("MeshLibrary") or name:find("NatureAssets") or name:find("CarBodies") or name:find("SkyAssets") or name:find("UserArsenal")))
		or (B and not (name:find("MeshLibrary") or name:find("NatureAssets") or name:find("CarBodies") or name:find("SkyAssets") or name:find("UserArsenal")))
	if selected then
		if d then
			Cloud.check(("%s (%.1f s)"):format(name, d.s), d.ok, d.err)
		else
			Cloud.aviso(name .. ": no terminó a tiempo", false, "")
		end
	end
end
local keys = {}
for k in results do
	table.insert(keys, k)
end
table.sort(keys)
for _, k in keys do
	line(("RESULTADO %s: %s"):format(k, tostring(results[k])))
	Cloud.check("Resultado " .. k, true, string.sub(tostring(results[k]), 1, 1500))
end
for tag, lines in said do
	for _, l in lines do
		line(("CONSOLA %s: %s"):format(tag, l))
	end
end
return Cloud.resultado()
