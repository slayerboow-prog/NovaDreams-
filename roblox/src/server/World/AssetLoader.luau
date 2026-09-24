-- AssetLoader: descarga al arrancar el servidor los packs gratuitos y oficiales de Synty
-- desde la Creator Store y los guarda en ServerStorage.AssetLibrary.
--
-- Usa AssetService:LoadAssetAsync (requiere AssetService.AllowInsertFreeAssets = true,
-- que ya viene activado en default.project.json). Si falla, prueba InsertService:LoadAsset.
-- Si tampoco funciona, el juego sigue con la ciudad hecha por código.

local AssetService = game:GetService("AssetService")
local InsertService = game:GetService("InsertService")
local ServerStorage = game:GetService("ServerStorage")

local AssetLibrary = require(script.Parent.Kit.AssetLibrary)

local AssetLoader = {}

AssetLoader.Packs = {
	{ Name = "SyntyCity", Id = 6933556508 }, -- Synty City Pack
	{ Name = "SyntyNature", Id = 6933438443 }, -- Synty Nature Pack
}

local function download(id: number): Instance?
	local ok, result = pcall(function()
		return (AssetService :: any):LoadAssetAsync(id)
	end)
	if ok and result then
		return result
	end
	warn(("[Assets] LoadAssetAsync(%d) falló: %s"):format(id, tostring(result)))
	ok, result = pcall(function()
		return InsertService:LoadAsset(id)
	end)
	if ok and result then
		return result
	end
	warn(("[Assets] InsertService:LoadAsset(%d) falló: %s"):format(id, tostring(result)))
	return nil
end

-- Devuelve cuántos packs hay disponibles (ya guardados en el archivo o descargados ahora)
function AssetLoader.load(): number
	local library = ServerStorage:FindFirstChild("AssetLibrary")
	if not library then
		library = Instance.new("Folder")
		library.Name = "AssetLibrary"
		library.Parent = ServerStorage
	end

	local available = 0
	for _, pack in AssetLoader.Packs do
		if library:FindFirstChild(pack.Name) then
			available += 1
		else
			local asset = download(pack.Id)
			if asset then
				asset.Name = pack.Name
				asset.Parent = library
				available += 1
			end
		end
	end

	-- Resumen en la ventana Output para saber qué modelos se están usando
	local summary = {}
	for kind in AssetLibrary.Catalog do
		table.insert(summary, ("%s=%d"):format(kind, #AssetLibrary.variants(kind)))
	end
	table.sort(summary)
	print(("[Assets] Packs disponibles: %d/%d · %s"):format(available, #AssetLoader.Packs, table.concat(summary, " ")))
	return available
end

return AssetLoader
