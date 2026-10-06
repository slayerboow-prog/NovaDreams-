-- Images: del id de un Decal subido al id de su imagen.
--
--   Los scripts de subida (upload-textures.sh, upload-outfits.sh) suben las imágenes como Decal. Si la
--   clave de Open Cloud no puede leer assets, solo saben el id del Decal, y con ese id ni un
--   MaterialVariant ni una camiseta (ShirtTemplate) muestran nada: necesitan el de la imagen.
--   Este módulo lo arregla dentro del juego:
--
--   * Images.resolve(ids) (servidor, espera): carga cada Decal con InsertService (funciona con los
--     assets del dueño del juego, sin permisos de Open Cloud), lee su Texture y guarda la pareja en
--     ReplicatedStorage.ImageIds (atributos, así la ven también los clientes). Si el id ya era de
--     una imagen, LoadAsset falla y se deja como está.
--   * Images.of(id) (servidor y cliente): el id de la imagen si se conoce; si no, el mismo id.
--   * Images.map(ids): la misma tabla con cada valor pasado por Images.of.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Images = {}

local FOLDER = "ImageIds"
local PARALLEL = 6

-- Parejas ya conocidas (shared/TextureImageIds, generado en la nube): así el archivo del juego trae
-- las texturas puestas y el servidor no tiene que escribirlas (no puede, pide la capacidad Plugin)
local cache: { [string]: string } = {}
do
	local ok, known = pcall(function()
		local module = script.Parent:FindFirstChild("TextureImageIds")
		return if module then require(module :: any) else nil
	end)
	if ok and type(known) == "table" then
		for decal, image in known do
			cache[tostring(decal)] = image
		end
	end
end

local function numberOf(content: any): string?
	if type(content) ~= "string" then
		return nil
	end
	return content:match("(%d+)%s*$") or content:match("id=(%d+)")
end

local function folder(create: boolean): Instance?
	local ok, found = pcall(function()
		return ReplicatedStorage:FindFirstChild(FOLDER)
	end)
	if not ok then
		return nil
	end
	if not found and create then
		found = Instance.new("Folder")
		found.Name = FOLDER
		found.Parent = ReplicatedStorage
	end
	return found
end

function Images.of(content: string): string
	local n = numberOf(content)
	if not n then
		return content
	end
	if cache[n] then
		return cache[n]
	end
	local f = folder(false)
	local known = f and f:GetAttribute("i" .. n)
	if type(known) == "string" and known ~= "" then
		cache[n] = known
		return known
	end
	return content
end

function Images.map(ids: { [string]: string }): { [string]: string }
	local out = {}
	for key, value in ids do
		out[key] = Images.of(value)
	end
	return out
end

-- La imagen de un Decal (nil si no es un Decal o no se puede cargar)
local function imageOfDecal(insert: any, n: string): string?
	local ok, model = pcall(function()
		return insert:LoadAsset(tonumber(n))
	end)
	if not ok or not model then
		return nil
	end
	local image
	for _, item in model:GetDescendants() do
		if item:IsA("Decal") or item:IsA("Texture") then
			local m = numberOf((item :: any).Texture)
			if m and m ~= n then
				image = "rbxassetid://" .. m
				break
			end
		end
	end
	model:Destroy()
	return image
end

-- Servidor: resuelve todos los ids (espera hasta acabar). Devuelve cuántos se han convertido.
function Images.resolve(ids: { [string]: string }): number
	local okService, insert = pcall(function()
		return game:GetService("InsertService")
	end)
	if not okService or not insert then
		return 0
	end
	local pending: { string } = {}
	local seen = {}
	for _, value in ids do
		local n = numberOf(value)
		if n and not seen[n] and not cache[n] then
			seen[n] = true
			table.insert(pending, n)
		end
	end
	if #pending == 0 then
		return 0
	end
	local f = folder(true)
	if not f then
		return 0
	end
	local converted, running, nextIndex = 0, 0, 1
	local finished = Instance.new("BindableEvent")
	local done = false
	local function worker()
		while nextIndex <= #pending do
			local n = pending[nextIndex]
			nextIndex += 1
			local image = imageOfDecal(insert, n)
			if image then
				cache[n] = image
				local target = f :: Instance
				target:SetAttribute("i" .. n, image)
				converted += 1
			end
		end
		running -= 1
		if running == 0 then
			done = true
			finished:Fire()
		end
	end
	running = math.min(PARALLEL, #pending)
	for _ = 1, running do
		task.spawn(worker)
	end
	if not done then
		finished.Event:Wait()
	end
	finished:Destroy()
	return converted
end

return Images
