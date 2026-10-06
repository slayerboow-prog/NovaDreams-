-- imagenes-texturas: saca el id de imagen de cada Decal de shared/TextureIds (para shared/TextureImageIds)
--
-- Los ids de shared/TextureIds son de Decal (los sube scripts/upload-textures.sh). Un MaterialVariant
-- necesita el de la imagen, y en un servidor de verdad no se puede escribir ColorMap… (pide la
-- capacidad Plugin), así que scripts/build-place.luau los deja puestos en el archivo con
-- shared/TextureImageIds. Esta prueba carga cada Decal con InsertService:LoadAsset (como
-- Images.resolve), lee su Texture e imprime una línea por Decal:
--     [img] <decal>=<imagen>
--
-- Uso: bash scripts/cloud-test.sh imagenes-texturas
--   y luego, con el registro (${TMPDIR:-/tmp}/cloud-test/imagenes-texturas.log), regenerar el módulo:
--   bash scripts/textures/image-ids.sh

local Cloud = Cloud :: any
local InsertService = game:GetService("InsertService")

local TextureIds = require(Cloud.Shared:WaitForChild("TextureIds")) :: { [string]: string }

local function numberOf(content: any): string?
	if type(content) ~= "string" then
		return nil
	end
	return content:match("(%d+)%s*$") or content:match("id=(%d+)")
end

local pending: { string } = {}
local seen = {}
for _, value in TextureIds do
	local n = numberOf(value)
	if n and not seen[n] then
		seen[n] = true
		table.insert(pending, n)
	end
end
table.sort(pending)

local found: { [string]: string } = {}
local fallan: { string } = {}
local nextIndex, running = 1, 0
local function worker()
	while nextIndex <= #pending and Cloud.quedan() > 10 do
		local n = pending[nextIndex]
		nextIndex += 1
		local ok, model = pcall(function()
			return InsertService:LoadAsset(tonumber(n))
		end)
		local image
		if ok and model then
			for _, item in model:GetDescendants() do
				if item:IsA("Decal") or item:IsA("Texture") then
					local m = numberOf((item :: any).Texture)
					if m and m ~= n then
						image = m
						break
					end
				end
			end
			model:Destroy()
		end
		if image then
			found[n] = image
		else
			table.insert(fallan, n .. (if ok then " (sin imagen)" else ": " .. tostring(model)))
		end
	end
	running -= 1
end
running = math.min(6, #pending)
for _ = 1, running do
	task.spawn(worker)
end
while running > 0 do
	task.wait(0.2)
end

local total = 0
for _, n in pending do
	if found[n] then
		total += 1
		print(("[img] %s=%s"):format(n, found[n]))
	end
end
Cloud.info("decals", #pending)
Cloud.info("imagenes", total)
Cloud.check(("Decals con imagen (%d de %d)"):format(total, #pending), #fallan == 0,
	if #fallan == 0 then "todos" else Cloud.lista(fallan, 10))

return Cloud.resultado()
