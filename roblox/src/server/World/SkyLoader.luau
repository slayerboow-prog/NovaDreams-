-- SkyLoader: carga los cielos de fotos (skybox) elegidos en shared/SkyChoice y los deja listos para que
-- cada cliente los ponga según la hora (Controllers/DayLight).
--
--   * Al arrancar el servidor (Main, en un hilo aparte), por cada id de SkyChoice (día y noche):
--     AssetService:LoadAssetAsync (InsertService:LoadAsset si falla), todo con pcall.
--   * Del asset solo se queda el primer `Sky` que tenga las 6 caras: se borra cualquier script que
--     traiga (y el resto del modelo), se llama "Day" o "Night" y va a ReplicatedStorage.SkyLibrary
--     (fuera de Lighting un Sky no pinta nada: solo guarda las caras).
--   * Sin ids, o si la carga falla, no se hace nada: se queda el cielo de siempre.

local AssetService = game:GetService("AssetService")
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SkyChoice = require(ReplicatedStorage.Shared.SkyChoice)

local SkyLoader = {}

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
	warn(("[SkyLoader] no carga el cielo %d: %s / %s"):format(id, tostring(err), tostring(result)))
	return nil
end

local function faces(sky: Instance): { [string]: string? }
	local out = {}
	for _, face in SkyChoice.Faces do
		local ok, value = pcall(function()
			return (sky :: any)[face]
		end)
		out[face] = if ok then value else nil
	end
	return out
end

-- Saca el Sky de un asset ya descargado y lo guarda en library como `slot`. Borra todo lo demás
-- (scripts incluidos). Devuelve el Sky guardado o nil si no traía uno completo.
function SkyLoader.extract(asset: Instance, slot: string, library: Instance): Instance?
	local found: Instance? = if asset:IsA("Sky") then asset else nil
	if not found then
		for _, item in asset:GetDescendants() do
			if item:IsA("Sky") and SkyChoice.complete(faces(item)) then
				found = item
				break
			end
		end
	end
	if not found or not SkyChoice.complete(faces(found)) then
		asset:Destroy()
		return nil
	end
	-- (el Sky no tiene hijos útiles: fuera cualquier cosa que lleve dentro, scripts sobre todo)
	for _, child in found:GetChildren() do
		child:Destroy()
	end
	local old = library:FindFirstChild(slot)
	if old then
		old:Destroy()
	end
	found.Parent = nil
	found.Name = slot
	found:SetAttribute("SourceSlot", slot)
	if found ~= asset then
		asset:Destroy()
	end
	found.Parent = library
	return found
end

function SkyLoader.start()
	local wanted = SkyChoice.wanted()
	if #wanted == 0 then
		return -- sin ids: el cielo de siempre
	end
	local library = ReplicatedStorage:FindFirstChild(SkyChoice.Library)
	if not library then
		library = Instance.new("Folder")
		library.Name = SkyChoice.Library
		library.Parent = ReplicatedStorage
	end
	for _, entry in wanted do
		local asset = download(entry.Id)
		if asset then
			local ok, result = pcall(SkyLoader.extract, asset, entry.Slot, library)
			if not ok or not result then
				warn(("[SkyLoader] el asset %d no trae un Sky con sus 6 caras: %s"):format(entry.Id, tostring(result)))
			end
		end
	end
end

return SkyLoader
