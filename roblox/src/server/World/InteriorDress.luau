-- InteriorDress: suelos, paredes, techos, encimeras, rodapiés y escalones de los INTERIORES con las
-- texturas más realistas de los packs del dueño (qué va en cada estancia y pieza y por qué:
-- shared/InteriorLook). HouseDress viste las fachadas; esto, lo de dentro.
--
-- Lo llama World/UserMaterials al arrancar el servidor, con los packs ya cargados y después de
-- World/StreetDress y World/HouseDress (antes de aclarar):
--   1. Carga además los packs oficiales de Roblox «Realistic Material Variants – Duvall Drive» y
--      «Modern City Materials Pack» (InteriorLook.Packs), con la misma función de carga y de desempaquetar.
--   2. Para cada aspecto pone en MaterialService una COPIA de sus variants con la escala de interior
--      (StudsPerTile de InteriorLook; la copia se llama «U_In_<aspecto>_<n>» y no lleva SourcePack, así
--      que las fachadas y las calles siguen con el suyo). Solo variants cuyo BaseMaterial puede llevar
--      la pieza: a un variant de la Tienda no se le puede cambiar el BaseMaterial.
--   3. Viste pieza a pieza las plantas bajas de verdad de la ciudad (hospital, colegio, hotel, súper,
--      cine, tiendas…: solo suelos, techos y paredes de dentro) y las salas del cielo ya montadas.
--   4. Se engancha a InteriorService.onBuilt: cada vivienda, local o planta de un bloque que se monte
--      en vivo se viste al momento (antes de que World/UserMaterials la aclare).
--   Variedad fija por vivienda/local, color de cada pieza conservado (apenas aclarado), la física de
--   antes si la pieza cambia de material. Nunca: cristales, puertas, muebles, luces, pantallas, lo que
--   ya lleva variant. No añade piezas. Todo en pcall y por tandas; sin los packs no hace nada.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InteriorLook = require(ReplicatedStorage.Shared.InteriorLook)

local InteriorDress = {}

InteriorDress.Batch = 4000 -- piezas miradas por tanda (luego task.wait)
InteriorDress.Prefix = "U_In_"

---------------------------------------------------------------------
-- Variants
---------------------------------------------------------------------

-- Lo cargado: available[pack][nombre original] = BaseMaterial de verdad del variant
function InteriorDress.available(service: Instance, library: Instance): { [string]: { [string]: string } }
	local out: { [string]: { [string]: string } } = {}
	local function add(item: Instance)
		if item:IsA("MaterialVariant") then
			local pack, name = item:GetAttribute("SourcePack"), item:GetAttribute("SourceName")
			if type(pack) == "string" and type(name) == "string" then
				out[pack] = out[pack] or {}
				out[pack][name] = out[pack][name] or (item :: any).BaseMaterial.Name
			end
		end
	end
	for _, item in service:GetChildren() do
		add(item)
	end
	for _, folder in library:GetChildren() do
		for _, item in folder:GetChildren() do
			add(item)
		end
	end
	return out
end

local function findVariant(service: Instance, library: Instance, pack: string, name: string): (Instance?, boolean)
	for _, item in service:GetChildren() do
		if item:GetAttribute("SourcePack") == pack and item:GetAttribute("SourceName") == name then
			return item, true
		end
	end
	local folder = library:FindFirstChild(pack)
	for _, item in if folder then folder:GetChildren() else {} do
		if item:GetAttribute("SourceName") == name then
			return item, false
		end
	end
	return nil, false
end

export type Resolved = { Name: string, Base: string, Pack: string, Source: string }

-- La copia de interior de un variant (con su escala). Si no se puede copiar, el original: movido a
-- MaterialService si aún no estaba (con la escala de interior) o tal cual si ya lo usa otro.
local function interiorCopy(service: Instance, variant: any, already: boolean, look: InteriorLook.Look, name: string): any?
	local ok, copy = pcall(function()
		local v = variant:Clone()
		v.Name = name
		v:SetAttribute("SourcePack", nil)
		v:SetAttribute("SourceName", nil)
		return v
	end)
	local target = if ok and copy then copy else (if already then nil else variant)
	if target then
		pcall(function()
			target.StudsPerTile = look.Studs
		end)
		if look.Pattern then
			pcall(function()
				target.MaterialPattern = (Enum.MaterialPattern :: any)[look.Pattern]
			end)
		end
		pcall(function()
			target.Parent = service
		end)
		if target.Parent == service then
			return target
		end
	end
	return if already then variant else nil
end

-- Pone en MaterialService las copias de interior de cada aspecto. Devuelve resolved[aspecto] = lista.
function InteriorDress.resolve(service: Instance, library: Instance): { [string]: { Resolved } }
	local available = InteriorDress.available(service, library)
	local out: { [string]: { Resolved } } = {}
	local keys = {}
	for key in InteriorLook.Looks do
		table.insert(keys, key)
	end
	table.sort(keys) -- (orden fijo)
	for _, key in keys do
		local look = InteriorLook.Looks[key]
		local list: { Resolved } = {}
		for i, cand in InteriorLook.candidates(key, available) do
			local variant: any, already = findVariant(service, library, cand.Pack, cand.Name)
			if variant and variant.BaseMaterial.Name == cand.From then
				local name = ("%s%s_%d"):format(InteriorDress.Prefix, key, i)
				local existing = service:FindFirstChild(name)
				local used = existing or interiorCopy(service, variant, already, look, name)
				if used and used.Parent == service then
					if not existing then
						used:SetAttribute("InteriorLook", key)
						used:SetAttribute("InteriorSource", cand.Pack .. "/" .. cand.Name)
					end
					table.insert(list, { Name = used.Name, Base = cand.From, Pack = cand.Pack, Source = cand.Name })
				end
			end
		end
		if #list > 0 then
			out[key] = list
		end
	end
	return out
end

---------------------------------------------------------------------
-- Piezas
---------------------------------------------------------------------

-- Viste una pieza. Si algo falla, la deja como estaba.
function InteriorDress.dressPart(part: BasePart, r: Resolved, whiten: number): boolean
	local material, physics, color = part.Material, part.CustomPhysicalProperties, part.Color
	local ok = pcall(function()
		if part.Material.Name ~= r.Base then
			if not InteriorLook.canUse(part.Material.Name, r.Base) then
				error("material")
			end
			-- (misma física que antes: se pisa y se choca igual)
			if part.CustomPhysicalProperties == nil then
				part.CustomPhysicalProperties = PhysicalProperties.new(part.Material)
			end
			part.Material = (Enum.Material :: any)[r.Base]
		end
		part.MaterialVariant = r.Name
		part.Color = InteriorLook.whiten(color, whiten)
	end)
	if not ok then
		pcall(function()
			part.Material = material
			part.CustomPhysicalProperties = physics
			part.MaterialVariant = ""
			part.Color = color
		end)
	end
	return ok
end

type Holder = { Category: string?, Sky: boolean, Seed: string, Frame: CFrame?, Skip: boolean }

-- Lo que hace falta saber de la sala o del edificio de una pieza (mirando sus modelos hasta arriba)
local function holderOf(parent: Instance, first: BasePart): Holder
	local names = {}
	local sky = false
	local skip = false
	local shop: string? = nil
	local seed: string? = nil
	local room: Instance? = nil
	local outer: Instance? = nil
	local node: Instance? = parent
	while node and node ~= game do
		local name = node.Name
		table.insert(names, name)
		if name == "Interiores" or name == "Interior" then
			sky = true
		end
		if node:GetAttribute("Prefab3D") ~= nil then
			skip = true
		end
		if room == nil and string.match(name, "^Interior_") then
			room = node
			sky = true
			local s = node:GetAttribute("Shop")
			shop = if type(s) == "string" then s else nil
			local k = node:GetAttribute("Key")
			if type(k) == "string" then
				seed = k
			end
		end
		if outer == nil and node:IsA("Model") and node.Parent and (node.Parent.Name == "Town" or string.match(node.Parent.Name, "^Manzana") ~= nil) then
			outer = node -- (el edificio de la ciudad: su sitio da la variedad)
		end
		node = node.Parent
	end
	local p = first.CFrame.Position
	if p.Y > InteriorLook.SKY_Y then
		sky = true
	end
	local frame: CFrame? = nil
	local floor = room and room:FindFirstChild("Floor")
	if floor and floor:IsA("BasePart") then
		frame = floor.CFrame * CFrame.new(0, floor.Size.Y / 2, 0)
	end
	if not seed then
		local at = p
		local base = outer or (if parent:IsA("Model") then parent else nil)
		if base then
			local ok, pivot = pcall(function()
				return (base :: any):GetPivot()
			end)
			if ok and typeof(pivot) == "CFrame" then
				at = pivot.Position
			end
		end
		seed = (if room then room.Name else "") .. "@" .. InteriorLook.placeSeed(at.X, at.Z)
	end
	return { Category = InteriorLook.categoryOf(names, shop), Sky = sky, Seed = seed :: string, Frame = frame, Skip = skip }
end

-- ¿Pieza que nunca se toca? (mallas con su textura, apariencias propias, cajas escondidas)
local function untouchable(part: BasePart): boolean
	if part:HasTag("BuildingShell") or part:HasTag("BuildingMesh") or part:HasTag("PropMesh") or part:GetAttribute("Collider") then
		return true
	end
	if part:IsA("MeshPart") and (part :: any).TextureID ~= "" then
		return true
	end
	return part:FindFirstChildWhichIsA("SurfaceAppearance") ~= nil
end

-- Repasa root. Devuelve cuántas piezas vistió por aspecto y por variant.
-- noYield: sin pausas (una sala recién montada: así se viste antes de que nadie la aclare)
function InteriorDress.dress(root: Instance, resolved: { [string]: { Resolved } }, noYield: boolean?): ({ [string]: number }, { [string]: number })
	local counts: { [string]: number } = {}
	local byVariant: { [string]: number } = {}
	if next(resolved) == nil then
		return counts, byVariant
	end
	local holders: { [Instance]: Holder } = {}
	local usableCache: { [string]: { Resolved } } = {}
	local list = root:GetDescendants()
	for i, part in list do
		if not noYield and i % InteriorDress.Batch == 0 and task then
			task.wait()
		end
		if part:IsA("BasePart") and InteriorLook.Roles[part.Name] and part.MaterialVariant == "" and part.Parent then
			local parent = part.Parent :: Instance
			local holder = holders[parent]
			if not holder then
				holder = holderOf(parent, part)
				holders[parent] = holder
			end
			local localY, localZ = nil, nil
			if holder.Frame and part.Name == "FloorFinish" then
				local l = (holder.Frame :: CFrame):PointToObjectSpace(part.CFrame.Position)
				localY, localZ = l.Y, l.Z
			end
			local key = InteriorLook.classify({
				Name = part.Name,
				Material = part.Material.Name,
				Variant = part.MaterialVariant,
				Transparency = part.Transparency,
				Color = part.Color,
				Category = holder.Category,
				Sky = holder.Sky or part.CFrame.Position.Y > InteriorLook.SKY_Y,
				Seed = holder.Seed,
				LocalY = localY,
				LocalZ = localZ,
				Skip = holder.Skip or untouchable(part),
			})
			local look = key and InteriorLook.Looks[key :: string]
			local useKey = key
			if look and not resolved[key :: string] and look.Fallback then
				useKey = look.Fallback
			end
			local options = useKey and resolved[useKey :: string]
			if options then
				local cacheKey = (useKey :: string) .. "/" .. part.Material.Name
				local usable = usableCache[cacheKey]
				if not usable then
					usable = InteriorLook.usable(options, part.Material.Name)
					usableCache[cacheKey] = usable
				end
				local r = usable[InteriorLook.pick(useKey :: string, #usable, holder.Seed)]
				-- (cada pieza se aclara con su aspecto: el del respaldo si es el que lleva)
				if r and InteriorDress.dressPart(part, r, InteriorLook.Looks[useKey :: string].Whiten) then
					counts[useKey :: string] = (counts[useKey :: string] or 0) + 1
					byVariant[r.Source] = (byVariant[r.Source] or 0) + 1
				end
			end
		end
	end
	return counts, byVariant
end

---------------------------------------------------------------------
-- Arranque (lo llama World/UserMaterials, en su hilo, después de HouseDress y antes de aclarar)
---------------------------------------------------------------------

-- Carga los packs oficiales que faltan (Duvall Drive, Modern City) en la biblioteca
function InteriorDress.loadPacks(library: Instance, load: ((number) -> Instance?)?, unpack: ((Instance, string, Instance) -> any)?): number
	if not load or not unpack then
		return 0
	end
	local count = 0
	for _, pack in InteriorLook.Packs do
		if library:FindFirstChild(pack.Short) then
			count += 1
		else
			local ok, asset = pcall(load, pack.Id)
			if ok and asset then
				local unpacked = pcall(unpack, asset, pack.Short, library)
				if unpacked then
					count += 1
				end
			else
				warn(("[InteriorDress] no carga %s (%d)"):format(pack.Title, pack.Id))
			end
		end
	end
	return count
end

local function report(prefix: string, counts: { [string]: number }, byVariant: { [string]: number }?)
	local list = {}
	for key, n in counts do
		table.insert(list, ("%s %d"):format(key, n))
	end
	table.sort(list)
	print(("[InteriorDress] %s: %s"):format(prefix, if #list > 0 then table.concat(list, ", ") else "ninguno"))
	if byVariant and next(byVariant) then
		local variants = {}
		for name, n in byVariant do
			table.insert(variants, ("%s %d"):format(name, n))
		end
		table.sort(variants)
		print("[InteriorDress] variants: " .. table.concat(variants, ", "))
	end
end

-- onBuilt: InteriorService.onBuilt (o el de las pruebas). roots: dónde mirar al arrancar.
function InteriorDress.start(service: Instance, library: Instance, load: ((number) -> Instance?)?, unpack: ((Instance, string, Instance) -> any)?, onBuilt: ((((any) -> ())) -> ())?, roots: { Instance }?): { [string]: { Resolved } }?
	local ok, resolved = pcall(function()
		InteriorDress.loadPacks(library, load, unpack)
		return InteriorDress.resolve(service, library)
	end)
	if not ok then
		warn("[InteriorDress] " .. tostring(resolved))
		return nil
	end
	if next(resolved) == nil then
		print("[InteriorDress] sin variants de interior: se quedan como estaban")
		return resolved
	end
	-- Las plantas bajas de la ciudad y las salas ya montadas
	local where = roots
	if not where then
		where = {}
		for _, name in { "Town", "Interiores" } do
			local folder = workspace:FindFirstChild(name)
			if folder then
				table.insert(where, folder)
			end
		end
	end
	local total: { [string]: number } = {}
	local totalVariants: { [string]: number } = {}
	for _, root in where :: { Instance } do
		local okDress, counts, byVariant = pcall(InteriorDress.dress, root, resolved)
		if okDress then
			for k, n in counts do
				total[k] = (total[k] or 0) + n
			end
			for k, n in byVariant do
				totalVariants[k] = (totalVariants[k] or 0) + n
			end
		else
			warn("[InteriorDress] " .. root.Name .. ": " .. tostring(counts))
		end
	end
	report("al arrancar", total, totalVariants)
	-- Las salas que se monten luego (cada vivienda, local y planta de bloque, al entrar alguien)
	local hook = onBuilt
	if not hook then
		local services = script and script.Parent and script.Parent.Parent and script.Parent.Parent:FindFirstChild("Services")
		local module = services and services:FindFirstChild("InteriorService")
		if module then
			local okReq, InteriorService = pcall(require, module :: any)
			if okReq and type(InteriorService) == "table" and type(InteriorService.onBuilt) == "function" then
				hook = InteriorService.onBuilt
			end
		end
	end
	if hook then
		local okHook, err = pcall(hook, function(inst: any)
			local model = inst and inst.Room and inst.Room.Model
			if model and model.Parent then
				local okDress, counts = pcall(InteriorDress.dress, model, resolved, true)
				if not okDress then
					warn("[InteriorDress] sala: " .. tostring(counts))
				end
			end
		end)
		if not okHook then
			warn("[InteriorDress] onBuilt: " .. tostring(err))
		end
	end
	return resolved
end

return InteriorDress
