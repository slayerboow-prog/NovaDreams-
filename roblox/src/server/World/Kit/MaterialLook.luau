-- MaterialLook: pone las texturas PBR de verdad (shared/Textures) en la ciudad.
--
--   * MaterialLook.setup(): crea en MaterialService un MaterialVariant por cada material con ids
--     (shared/TextureIds) y, en los que tienen Override, lo pone en lugar del material de Roblox en
--     todo el juego (asfalto, aceras, hormigón, estuco, ladrillo, teja, mármol, césped y arena del
--     terreno…). MaterialService se replica: los jugadores lo ven sin hacer nada más.
--   * MaterialLook.assign(root): pieza a pieza, lo que no cubre un Override (Textures.rule): pintura
--     de la calzada, bordillos de granito, acero cepillado, madera de puertas y muebles, laca de los
--     coches. Se llama al construir la ciudad (TownBuilder) y al arrancar el servidor si la ciudad del
--     archivo se construyó con otros ids (atributo TextureSet de la ciudad).
--   * MaterialLook.tuneVehicle(model): laca y cristal con reflejo en un coche (los que aparecen luego).
--   * Los materiales que sustituye un variant de los packs del dueño (World/UserMaterials: atributo
--     "UserOverride_<Material>" en MaterialService) se quedan con el suyo: aquí solo se crea el nuestro.
--   * Sin ids (aún no subidas o 0): no crea nada ni cambia ninguna pieza (solo el reflejo del cristal
--     de los coches, que no depende de las texturas).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Textures = require(ReplicatedStorage.Shared.Textures)
local TextureIds = require(ReplicatedStorage.Shared.TextureIds)
local Images = require(ReplicatedStorage.Shared.Images)
local UserMaterialChoice = require(ReplicatedStorage.Shared.UserMaterialChoice)

local MaterialLook = {}

local function idsOr(ids: { [string]: string }?): { [string]: string }
	return ids or TextureIds
end

-- Crea o actualiza los MaterialVariant. Devuelve los nombres que se han puesto.
function MaterialLook.setup(service: Instance?, ids: { [string]: string }?): { string }
	local source = idsOr(ids)
	local target: any = service or game:GetService("MaterialService")
	local made = {}
	for _, name in Textures.available(source) do
		local def = Textures.Variants[name]
		local maps = Textures.maps(name, source) :: { [string]: string }
		local existing = target:FindFirstChild(name)
		local variant: any = if existing and existing:IsA("MaterialVariant") then existing else Instance.new("MaterialVariant")
		variant.Name = name
		variant.BaseMaterial = (Enum.Material :: any)[def.Base]
		variant.StudsPerTile = def.Studs
		pcall(function()
			variant.MaterialPattern = (Enum.MaterialPattern :: any)[def.Pattern]
		end)
		for _, prop in Textures.MapProperty do
			variant[prop] = maps[prop] or ""
		end
		variant:SetAttribute("NormalMapId", maps.NormalMap or "") -- (el cliente lo quita y lo vuelve a poner según el nivel gráfico)
		-- Rugosidad seca y mojada: con lluvia el cliente pone la mojada (Controllers/MaterialDetail)
		variant:SetAttribute("DryRoughnessId", maps.RoughnessMap or "")
		variant:SetAttribute("WetRoughnessId", Textures.wetMap(name, source) or "")
		variant.Parent = target
		-- (si el material ya lo sustituye un variant del dueño, World/UserMaterials, gana el suyo)
		if def.Override and not target:GetAttribute(UserMaterialChoice.attribute(def.Base)) then
			local base = (Enum.Material :: any)[def.Base]
			local ok = pcall(function()
				target:SetBaseMaterialOverride(base, name)
			end)
			if not ok then
				pcall(function()
					target[def.Base .. "Name"] = name
				end)
			end
		end
		table.insert(made, name)
	end
	return made
end

local function paintOf(part: Instance): Color3?
	local parent = part.Parent
	if parent and parent:IsA("Model") then
		local paint = parent:GetAttribute("Paint")
		if typeof(paint) == "Color3" then
			return paint
		end
	end
	return nil
end

-- Una pieza: devuelve true si ha cambiado
local function assignPart(part: BasePart, enabled: { [string]: boolean }): boolean
	if part.MaterialVariant ~= "" then
		return false
	end
	local parent = part.Parent
	local variant, material = Textures.rule({
		Name = part.Name,
		Material = part.Material.Name,
		Color = part.Color,
		Parent = if parent then parent.Name else nil,
		Paint = paintOf(part),
	})
	if variant and enabled[variant] then
		if material then
			part.Material = (Enum.Material :: any)[material]
		end
		part.MaterialVariant = variant
		return true
	end
	return false
end

local function tuneGlass(part: BasePart): boolean
	if part.Material == Enum.Material.Glass and part.Reflectance < 0.05 and part.Transparency < 0.8 and paintOf(part) then
		part.Reflectance = Textures.VehicleGlassReflectance
		return true
	end
	return false
end

local function enabledSet(ids: { [string]: string }): { [string]: boolean }
	local set = {}
	for _, name in Textures.available(ids) do
		set[name] = true
	end
	return set
end

-- Repasa todas las piezas de root. Devuelve cuántas cambió.
function MaterialLook.assign(root: Instance, ids: { [string]: string }?): number
	local source = idsOr(ids)
	local enabled = enabledSet(source)
	local changed = 0
	for _, part in root:GetDescendants() do
		if part:IsA("BasePart") then
			if assignPart(part, enabled) then
				changed += 1
			end
			tuneGlass(part)
		end
	end
	root:SetAttribute("TextureSet", Textures.signature(source))
	return changed
end

-- Un coche (o una pieza nueva de un coche): laca y cristal
function MaterialLook.tuneVehicle(model: Instance, ids: { [string]: string }?)
	local enabled = enabledSet(idsOr(ids))
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			assignPart(part, enabled)
			tuneGlass(part)
		end
	end
end

-- Arranque del servidor: variants, la ciudad si hace falta y los coches que aparezcan luego.
-- Primero pasa los ids de Decal a ids de imagen (shared/Images): espera, así que se llama en un hilo aparte.
function MaterialLook.start(town: Instance?)
	local converted = Images.resolve(TextureIds)
	if converted > 0 then
		print(("[MaterialLook] %d texturas pasadas de Decal a imagen"):format(converted))
	end
	local made = MaterialLook.setup(nil, Images.map(TextureIds))
	if town and town:GetAttribute("TextureSet") ~= Textures.signature(TextureIds) then
		MaterialLook.assign(town)
	end
	local enabled = enabledSet(TextureIds)
	workspace.DescendantAdded:Connect(function(part)
		if part:IsA("BasePart") and paintOf(part) then
			task.defer(function()
				if part.Parent then
					assignPart(part, enabled)
					tuneGlass(part)
				end
			end)
		end
	end)
	if #made > 0 then
		print(("[MaterialLook] %d materiales con textura: %s"):format(#made, table.concat(made, ", ")))
	end
end

return MaterialLook
