-- UserMaterials: los materiales PBR realistas que eligió Sebastián en la Tienda de creadores, en toda
-- la ciudad (qué variant va a cada material: shared/UserMaterialChoice; contenido real de los packs:
-- docs/assets-usuario.md).
--
--   * Al arrancar el servidor (Main, en un hilo aparte) carga los packs con
--     AssetService:LoadAssetAsync (InsertService:LoadAsset si falla; con los de la comunidad solo
--     funciona el primero), borra cualquier script que traigan, borra los variants rotos y renombra
--     cada MaterialVariant a "U_<pack>_<nombre>" (los nombres originales chocan entre sí y con los
--     nuestros). Todos quedan en ServerStorage.UserMaterials (no se replica: no gasta en el cliente).
--   * Los elegidos pasan a MaterialService (se replica) y sustituyen a su material de Roblox en TODO
--     el juego, piezas y terreno: SetBaseMaterialOverride. Si el variant venía sobre otro material
--     (el asfalto de Tyler viene sobre Concrete) se le cambia el BaseMaterial; las texturas no se
--     tocan (no se pueden leer ni escribir desde un script).
--   * MaterialService guarda el atributo "UserOverride_<Material>": Kit/MaterialLook no pone el
--     nuestro en esos materiales aunque arranque después (y si arrancó antes, este lo pisa).
--   * Estas texturas traen su color y Roblox lo multiplica por el de la pieza: las piezas y el
--     terreno de esos materiales se aclaran (Whiten de la tabla), también las que aparezcan luego.
--   * Lo nuestro pieza a pieza (pintura vial, bordillo, laca de coche, acero cepillado, madera con
--     veta) no se toca: una pieza con MaterialVariant propio no usa el override.
--   * Suelo mojado: lo sigue haciendo el cliente (Controllers/WetWorld oscurece y da reflejo a las
--     piezas al aire, con cualquier material, y pone charcos). La rugosidad mojada de nuestras texturas
--     (Controllers/MaterialDetail) queda en el bordillo de granito, que sigue siendo nuestro.
--   * Después de las calles (World/StreetDress) viste las casas, el colegio, los edificios públicos y
--     las naves pieza a pieza (World/HouseDress, shared/HouseLook): los overrides de Plaster y
--     ClayRoofTiles no se pueden poner en un servidor real (sus variants vienen sobre otro material).
--   * Y después, los interiores (suelos, paredes, techos…): World/InteriorDress, shared/InteriorLook.
--   * Si no carga ningún pack (o falla todo), no se cambia nada: siguen nuestras texturas.

local AssetService = game:GetService("AssetService")
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Choice = require(ReplicatedStorage.Shared.UserMaterialChoice)

local UserMaterials = {}

local LIBRARY = "UserMaterials"
local TERRAIN = { Grass = true, LeafyGrass = true, Rock = true, Sand = true, Ground = true }

local function download(id: number): Instance?
	local ok, result = pcall(function()
		return (AssetService :: any):LoadAssetAsync(id)
	end)
	if ok and result then
		return result
	end
	local err = result
	ok, result = pcall(function()
		return InsertService:LoadAsset(id)
	end)
	if ok and result then
		return result
	end
	warn(("[UserMaterials] no carga %d: %s / %s"):format(id, tostring(err), tostring(result)))
	return nil
end

-- Un pack ya descargado: fuera scripts y variants rotos, renombra y guarda en library/<short>.
-- Devuelve { [nombre original] = true } de los variants guardados.
function UserMaterials.unpack(asset: Instance, short: string, library: Instance): { [string]: boolean }
	for _, item in asset:GetDescendants() do
		if item:IsA("LuaSourceContainer") then
			item:Destroy()
		end
	end
	local folder = library:FindFirstChild(short)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = short
		folder.Parent = library
	end
	local names: { [string]: boolean } = {}
	local used: { [string]: boolean } = {}
	for _, existing in folder:GetChildren() do
		used[existing.Name] = true
	end
	for _, item in asset:GetDescendants() do
		if item:IsA("MaterialVariant") and item.Parent then
			local original = item.Name
			if Choice.isBroken(short, original) then
				item:Destroy()
			else -- (nombres repetidos en el Mega Pack: el segundo lleva "_2"; la tabla no elige repetidos)
				local name = Choice.variantName(short, original)
				local n = 1
				while used[name] do
					n += 1
					name = Choice.variantName(short, original) .. "_" .. n
				end
				used[name] = true
				names[original] = true
				item:SetAttribute("SourcePack", short)
				item:SetAttribute("SourceName", original)
				item.Name = name
				item.Parent = folder
			end
		end
	end
	asset:Destroy()
	return names
end

local function findVariant(library: Instance, pack: string, name: string): Instance?
	local folder = library:FindFirstChild(pack)
	if not folder then
		return nil
	end
	for _, item in folder:GetChildren() do
		if item:GetAttribute("SourceName") == name then
			return item
		end
	end
	return nil
end

local function setOverride(service: any, material: string, name: string): boolean
	local base = (Enum.Material :: any)[material]
	local ok = pcall(function()
		service:SetBaseMaterialOverride(base, name)
	end)
	if not ok then
		ok = pcall(function()
			service[material .. "Name"] = name
		end)
	end
	return ok
end

-- Pone los elegidos en MaterialService. loaded: lo que devolvió unpack por pack.
-- Devuelve lo que se ha puesto (Pick de shared/UserMaterialChoice con VariantName).
-- En un servidor real, cambiar BaseMaterial a un variant cargado de la Tienda FALLA (probado en v80:
-- por eso no se puso ninguno). Así que cada paso va en su propio pcall, primero se prueban los
-- candidatos que ya vienen sobre el material bueno (From == Material) y, si uno no se puede poner,
-- se pasa al siguiente.
local function tryPick(service: any, library: Instance, choice: any, cand: any): any?
	local variant: any = findVariant(library, cand.Pack, cand.Name)
	if not variant then
		-- (ya movido a MaterialService por otra elección: se clona para este material)
		for _, item in service:GetChildren() do
			if item:GetAttribute("SourcePack") == cand.Pack and item:GetAttribute("SourceName") == cand.Name then
				variant = item:Clone()
				variant.Name = item.Name .. "_" .. choice.Material
				break
			end
		end
	end
	if not variant then
		return nil
	end
	local base = (Enum.Material :: any)[choice.Material]
	if variant.BaseMaterial ~= base then
		local ok = pcall(function()
			variant.BaseMaterial = base
		end)
		if not ok or variant.BaseMaterial ~= base then
			return nil
		end
	end
	if choice.Studs then
		pcall(function()
			variant.StudsPerTile = choice.Studs
		end)
	end
	if choice.Pattern then
		pcall(function()
			variant.MaterialPattern = (Enum.MaterialPattern :: any)[choice.Pattern]
		end)
	end
	local parented = pcall(function()
		variant.Parent = service
	end)
	if not parented or variant.Parent ~= service then
		return nil
	end
	if not setOverride(service, choice.Material, variant.Name) then
		return nil
	end
	return variant
end

function UserMaterials.apply(service: Instance, library: Instance, loaded: { [string]: { [string]: boolean } }): { any }
	local applied = {}
	for _, choice in Choice.Table do
		-- primero los que ya vienen sobre este material
		local ordered = {}
		for _, cand in choice.Candidates do
			if cand.From == choice.Material then
				table.insert(ordered, cand)
			end
		end
		for _, cand in choice.Candidates do
			if cand.From ~= choice.Material then
				table.insert(ordered, cand)
			end
		end
		for _, cand in ordered do
			local pack = loaded[cand.Pack]
			if pack and pack[cand.Name] then
				local variant = tryPick(service, library, choice, cand)
				if variant then
					service:SetAttribute(Choice.attribute(choice.Material), variant.Name)
					table.insert(applied, {
						Material = choice.Material,
						Pack = cand.Pack,
						Name = cand.Name,
						From = cand.From,
						Studs = choice.Studs,
						Pattern = choice.Pattern,
						Whiten = choice.Whiten,
						VariantName = variant.Name,
					})
					break
				end
			end
		end
	end
	return applied
end

-- Aclara (Whiten) las piezas de los materiales sustituidos que no llevan variant propio.
-- seen: piezas ya aclaradas (para no aclarar dos veces si una pieza cambia de sitio).
local function tintPart(part: BasePart, amounts: { [string]: number }, seen: { [Instance]: boolean }): boolean
	if seen[part] or part.MaterialVariant ~= "" then
		return false
	end
	local amount = amounts[part.Material.Name]
	if not amount or amount <= 0 or part:FindFirstChildWhichIsA("SurfaceAppearance") then
		return false
	end
	if part:IsA("MeshPart") and (part :: any).TextureID ~= "" then
		return false -- (malla con su propia textura)
	end
	seen[part] = true
	part.Color = Choice.whiten(part.Color, amount)
	return true
end

function UserMaterials.amounts(applied: { any }): { [string]: number }
	local amounts = {}
	for _, pick in applied do
		amounts[pick.Material] = pick.Whiten
	end
	return amounts
end

-- Repasa root (la ciudad, workspace…). Devuelve cuántas piezas aclaró.
function UserMaterials.tint(root: Instance, amounts: { [string]: number }, seen: { [Instance]: boolean }?, terrain: any?): number
	local mark = seen or setmetatable({}, { __mode = "k" }) :: any
	local count = 0
	for i, part in root:GetDescendants() do
		if part:IsA("BasePart") and tintPart(part, amounts, mark) then
			count += 1
		end
		if i % 20000 == 0 and task then
			task.wait() -- (la ciudad entera son ~100.000 piezas)
		end
	end
	if terrain then
		for material in TERRAIN do
			local amount = amounts[material]
			if amount and amount > 0 then
				pcall(function()
					local base = (Enum.Material :: any)[material]
					terrain:SetMaterialColor(base, Choice.whiten(terrain:GetMaterialColor(base), amount))
				end)
			end
		end
	end
	return count
end

-- Arranque (servidor, espera: llamar en un hilo aparte). load(id) se puede cambiar en las pruebas.
-- dress (opcional): lo que se hace con los packs ya cargados ANTES de aclarar (World/StreetDress: cada
-- calle con su aspecto; lo que lleva variant propio no se aclara aquí).
function UserMaterials.start(load: ((number) -> Instance?)?, dress: ((Instance, Instance, (number) -> Instance?, any) -> ())?)
	local library = ServerStorage:FindFirstChild(LIBRARY)
	if not library then
		library = Instance.new("Folder")
		library.Name = LIBRARY
		library.Parent = ServerStorage
	end
	local loaded: { [string]: { [string]: boolean } } = {}
	local count = 0
	for _, pack in Choice.Packs do
		local asset = (load or download)(pack.Id)
		if asset then
			local ok, names = pcall(UserMaterials.unpack, asset, pack.Short, library)
			if ok then
				loaded[pack.Short] = names
				count += 1
			else
				warn(("[UserMaterials] %s: %s"):format(pack.Short, tostring(names)))
			end
		end
	end
	if count == 0 then
		print("[UserMaterials] no ha cargado ningún pack: se quedan nuestras texturas")
		return
	end
	local applied = UserMaterials.apply(game:GetService("MaterialService"), library, loaded)
	local list = {}
	for _, pick in applied do
		table.insert(list, ("%s=%s"):format(pick.Material, pick.VariantName))
	end
	print(("[UserMaterials] %d/%d packs, %d materiales sustituidos: %s"):format(count, #Choice.Packs, #applied, table.concat(list, ", ")))
	if dress then
		local ok, err = pcall(dress, game:GetService("MaterialService"), library, load or download, UserMaterials.unpack)
		if not ok then
			warn("[UserMaterials] calles: " .. tostring(err))
		end
	end
	-- Casas, colegio, edificios públicos y naves: cada parte con su textura realista, pieza a pieza
	-- (World/HouseDress, tabla en shared/HouseLook). También antes de aclarar.
	local houses = script and script.Parent and script.Parent:FindFirstChild("HouseDress")
	if houses then
		local ok, err = pcall(function()
			require(houses :: any).start(game:GetService("MaterialService"), library)
		end)
		if not ok then
			warn("[UserMaterials] edificios: " .. tostring(err))
		end
	end
	-- Interiores (casas, pisos, tiendas, bares, oficinas, hospital, colegio, hotel…): suelos, paredes,
	-- techos, encimeras y rodapiés pieza a pieza (World/InteriorDress, tabla en shared/InteriorLook),
	-- también las salas que se monten luego. Carga además Duvall Drive y Modern City Materials.
	local interiors = script and script.Parent and script.Parent:FindFirstChild("InteriorDress")
	if interiors then
		local ok, err = pcall(function()
			require(interiors :: any).start(game:GetService("MaterialService"), library, load or download, UserMaterials.unpack)
		end)
		if not ok then
			warn("[UserMaterials] interiores: " .. tostring(err))
		end
	end
	if #applied == 0 then
		return
	end
	-- Aclarar piezas y terreno; y lo que aparezca luego (interiores, coches, modelos…)
	local amounts = UserMaterials.amounts(applied)
	local seen = setmetatable({}, { __mode = "k" }) :: any
	workspace.DescendantAdded:Connect(function(part)
		if part:IsA("BasePart") and amounts[part.Material.Name] then
			task.defer(function()
				if part.Parent then
					tintPart(part, amounts, seen)
				end
			end)
		end
	end)
	local tinted = UserMaterials.tint(workspace, amounts, seen, workspace.Terrain)
	print(("[UserMaterials] %d piezas aclaradas para las texturas con color"):format(tinted))
end

return UserMaterials
