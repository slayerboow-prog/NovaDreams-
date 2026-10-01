-- HouseDress: casas, colegio, edificios públicos y naves con las texturas más realistas de los packs
-- de la Tienda que eligió el dueño (qué va en cada parte y por qué: shared/HouseLook).
--
-- Lo llama World/UserMaterials al arrancar el servidor, con los packs ya cargados (y las calles ya
-- vestidas por World/StreetDress) y ANTES de aclarar las piezas:
--   1. Pone en MaterialService los variants de cada aspecto (solo los que vienen sobre el material
--      que dice el doc: a un variant de la Tienda no se le puede cambiar el BaseMaterial).
--   2. Viste pieza a pieza las paredes, zócalos, tejados (y las hiladas de teja de Kit/CityDetail),
--      contraventanas y maderas de cada edificio (part.MaterialVariant), con variedad fija por
--      edificio y su color de siempre (apenas aclarado). Si la pieza tiene que cambiar de material
--      (estuco Plaster -> Concrete…), guarda su física de antes. Si algo falla, la pieza se queda como
--      estaba.
--   Nunca: cristales, puertas, lo que ya lleva variant, lo invisible, los edificios cambiados por
--   prefabs 3D (World/Buildings3D: atributo Prefab3D, etiquetas BuildingShell/BuildingMesh) ni las
--   salas de los interiores. No añade piezas (gráficos Bajo: igual que antes).
-- Todo va en pcall y por tandas. Sin los packs no se hace nada.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HouseLook = require(ReplicatedStorage.Shared.HouseLook)

local HouseDress = {}

HouseDress.Batch = 4000 -- piezas miradas por tanda (luego task.wait)

---------------------------------------------------------------------
-- Variants
---------------------------------------------------------------------

-- Lo cargado: available[pack][nombre original] = BaseMaterial de verdad del variant
function HouseDress.available(service: Instance, library: Instance): { [string]: { [string]: string } }
	local out: { [string]: { [string]: string } } = {}
	local function add(item: Instance)
		if item:IsA("MaterialVariant") then
			local pack, name = item:GetAttribute("SourcePack"), item:GetAttribute("SourceName")
			if type(pack) == "string" and type(name) == "string" then
				out[pack] = out[pack] or {}
				-- (nombres repetidos en el Mega Pack: vale el primero)
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

-- Pone en MaterialService los variants de cada aspecto. Devuelve resolved[aspecto] = lista (variedad).
function HouseDress.resolve(service: Instance, library: Instance): { [string]: { Resolved } }
	local available = HouseDress.available(service, library)
	local out: { [string]: { Resolved } } = {}
	local keys = {}
	for key in HouseLook.Looks do
		table.insert(keys, key)
	end
	table.sort(keys) -- (orden fijo)
	for _, key in keys do
		local look = HouseLook.Looks[key]
		local list: { Resolved } = {}
		for _, cand in HouseLook.candidates(key, available) do
			local variant: any, already = findVariant(service, library, cand.Pack, cand.Name)
			if variant and variant.BaseMaterial.Name == cand.From then
				if not already then
					local moved = pcall(function()
						variant.Parent = service
					end)
					-- (solo es de los edificios: se le puede cambiar el patrón)
					if moved and variant.Parent == service and look.Pattern then
						pcall(function()
							variant.MaterialPattern = (Enum.MaterialPattern :: any)[look.Pattern]
						end)
					end
				end
				if variant.Parent == service then
					table.insert(list, { Name = variant.Name, Base = cand.From, Pack = cand.Pack, Source = cand.Name })
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
function HouseDress.dressPart(part: BasePart, r: Resolved, whiten: number): boolean
	local material, physics, color = part.Material, part.CustomPhysicalProperties, part.Color
	local ok = pcall(function()
		if part.Material.Name ~= r.Base then
			if not HouseLook.canUse(part.Material.Name, r.Base) then
				error("material")
			end
			-- (misma física que antes: se pisa y se choca igual)
			if part.CustomPhysicalProperties == nil then
				part.CustomPhysicalProperties = PhysicalProperties.new(part.Material)
			end
			part.Material = (Enum.Material :: any)[r.Base]
		end
		part.MaterialVariant = r.Name
		part.Color = HouseLook.whiten(color, whiten)
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

type Holder = { Kind: string?, Style: string?, Skip: boolean, X: number, Z: number }

-- Lo que hace falta saber del edificio de una pieza (su modelo): clase, estilo, si se salta y dónde está
local function holderOf(model: Instance, root: Instance, first: BasePart): Holder
	local names = {}
	local skip = false
	local style = nil
	local node: Instance? = model
	while node and node ~= root do
		table.insert(names, node.Name)
		if HouseLook.SkipAncestors[node.Name] or node:GetAttribute("Prefab3D") ~= nil then
			skip = true
		end
		if style == nil then
			local s = node:GetAttribute("Style")
			if type(s) == "string" then
				style = s
			end
		end
		node = node.Parent
	end
	-- Sitio del edificio (para la variedad): su centro; si no se puede, la primera pieza vista
	local p = first.CFrame.Position
	if model:IsA("Model") then
		local ok, pivot = pcall(function()
			return (model :: any):GetPivot()
		end)
		if ok and typeof(pivot) == "CFrame" then
			p = pivot.Position
		end
	end
	return { Kind = HouseLook.kindOf(names), Style = style, Skip = skip, X = p.X, Z = p.Z }
end

-- ¿Pieza que nunca se toca? (prefabs 3D y sus cajas, mallas con textura, apariencias propias)
local function untouchable(part: BasePart): boolean
	if part:HasTag("BuildingShell") or part:HasTag("BuildingMesh") or part:GetAttribute("Collider") then
		return true
	end
	if part:IsA("MeshPart") and (part :: any).TextureID ~= "" then
		return true
	end
	return part:FindFirstChildWhichIsA("SurfaceAppearance") ~= nil
end

-- Repasa root. Devuelve cuántas piezas vistió por aspecto y por variant.
function HouseDress.dress(root: Instance, resolved: { [string]: { Resolved } }): ({ [string]: number }, { [string]: number })
	local counts: { [string]: number } = {}
	local byVariant: { [string]: number } = {}
	if next(resolved) == nil then
		return counts, byVariant
	end
	local holders: { [Instance]: Holder } = {}
	local usableCache: { [string]: { Resolved } } = {}
	for i, part in root:GetDescendants() do
		if i % HouseDress.Batch == 0 and task then
			task.wait()
		end
		if part:IsA("BasePart") and HouseLook.Roles[part.Name] and part.MaterialVariant == "" and part.Parent then
			local model = part.Parent :: Instance
			local holder = holders[model]
			if not holder then
				holder = holderOf(model, root, part)
				holders[model] = holder
			end
			local key = HouseLook.classify({
				Name = part.Name,
				Material = part.Material.Name,
				Variant = part.MaterialVariant,
				Kind = holder.Kind,
				Style = holder.Style,
				Transparency = part.Transparency,
				Y = part.CFrame.Position.Y,
				Skip = holder.Skip or untouchable(part),
			})
			local list = key and resolved[key]
			if list then
				-- (solo los que puede llevar este material; casi siempre todos)
				local cacheKey = (key :: string) .. "/" .. part.Material.Name
				local usable = usableCache[cacheKey]
				if not usable then
					usable = HouseLook.usable(list, part.Material.Name)
					usableCache[cacheKey] = usable
				end
				local r = usable[HouseLook.pick(key :: string, #usable, holder.X, holder.Z)]
				if r and HouseDress.dressPart(part, r, HouseLook.Looks[key :: string].Whiten) then
					counts[key :: string] = (counts[key :: string] or 0) + 1
					byVariant[r.Source] = (byVariant[r.Source] or 0) + 1
				end
			end
		end
	end
	return counts, byVariant
end

---------------------------------------------------------------------
-- Arranque (lo llama World/UserMaterials, en su hilo, antes de aclarar)
---------------------------------------------------------------------

function HouseDress.start(service: Instance, library: Instance, root: Instance?)
	local town = root or workspace:FindFirstChild("Town")
	if not town then
		return
	end
	local ok, result = pcall(function()
		local resolved = HouseDress.resolve(service, library)
		local counts, byVariant = HouseDress.dress(town, resolved)
		return { resolved, counts, byVariant }
	end)
	if not ok then
		warn("[HouseDress] " .. tostring(result))
		return
	end
	local list = {}
	for key, n in result[2] do
		table.insert(list, ("%s %d"):format(key, n))
	end
	table.sort(list)
	local variants = {}
	for name, n in result[3] do
		table.insert(variants, ("%s %d"):format(name, n))
	end
	table.sort(variants)
	print("[HouseDress] edificios: " .. (if #list > 0 then table.concat(list, ", ") else "ninguno"))
	if #variants > 0 then
		print("[HouseDress] variants: " .. table.concat(variants, ", "))
	end
end

return HouseDress
