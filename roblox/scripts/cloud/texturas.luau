-- texturas: ¿cargan de verdad las texturas y modelos de la Tienda que usa el juego publicado?
--
-- En un servidor de Roblox, con el juego publicado:
--   * Materiales PBR (World/UserMaterials, shared/UserMaterialChoice): carga los packs y los aplica como
--     en Main.server; cuenta los variants de cada pack y mira que cada material de la tabla quede
--     sustituido en MaterialService (GetBaseMaterialOverride).
--   * Muebles y objetos (World/InteriorProps.Assets), carrocerías (World/Kit/CarBodies.Sources) y el
--     cofre del pase: que cada asset cargue con AssetService:LoadAssetAsync.
--   * Imágenes subidas por el dueño (shared/RiftTextureIds): que carguen (ContentProvider:PreloadAsync),
--     con el id de la imagen que saca shared/Images del Decal subido (como hace el juego).
-- No toca datos de jugadores.
--
-- Uso: bash scripts/cloud-test.sh -v texturas

local Cloud = Cloud :: any -- (lo pone scripts/cloud-test.sh delante: scripts/cloud/_comun.luau)

local AssetService = game:GetService("AssetService")
local ContentProvider = game:GetService("ContentProvider")
local MaterialService = game:GetService("MaterialService")
local ServerStorage = game:GetService("ServerStorage")

Cloud.escuchar()
local World = Cloud.Server:WaitForChild("World")
local Choice = require(Cloud.Shared:WaitForChild("UserMaterialChoice")) :: any

-- 1. Materiales PBR
local okStart, errStart = pcall(function()
	require(World:WaitForChild("UserMaterials")).start()
end)
Cloud.check("UserMaterials.start()", okStart, if okStart then nil else tostring(errStart))
local library = ServerStorage:FindFirstChild("UserMaterials")
local packs = table.clone(Choice.Packs)
for _, p in Choice.ExtraPacks do
	table.insert(packs, p)
end
for _, pack in packs do
	-- (los elegidos pasan de ServerStorage.UserMaterials a MaterialService: se cuentan los dos sitios)
	local n = 0
	local prefix = Choice.Prefix .. pack.Short .. "_"
	for _, root in { library, MaterialService } do
		if root then
			for _, v in root:GetDescendants() do
				if v:IsA("MaterialVariant") and string.sub(v.Name, 1, #prefix) == prefix then
					n += 1
				end
			end
		end
	end
	-- (los packs extra solo son respaldo: si no traen MaterialVariant es un aviso, no un fallo; la
	-- arena realista va como imágenes por World/MaterialExtras)
	local extra = table.find(Choice.ExtraPacks, pack) ~= nil
	local check = if extra then Cloud.aviso else Cloud.check
	check(("Pack de materiales «%s» (%d)"):format(pack.Title, pack.Id), n > 0,
		("%d MaterialVariant"):format(n) .. (if n == 0 and extra then " (respaldo: no aporta variants)" else ""))
end
-- (Plaster y ClayRoofTiles no se pueden sustituir en un servidor real: sus variants vienen sobre otro
-- material; los pone pieza a pieza World/HouseDress. Por eso no cuentan como fallo.)
local PIEZA_A_PIEZA = { Plaster = true, ClayRoofTiles = true }
local sinTextura = {}
for _, row in Choice.Table do
	if PIEZA_A_PIEZA[row.Material] then
		continue
	end
	local ok, name = pcall(function()
		return MaterialService:GetBaseMaterialOverride((Enum.Material :: any)[row.Material])
	end)
	local override = if ok then tostring(name) else ""
	local variant = override ~= "" and MaterialService:FindFirstChild(override, true)
	if override == "" or not variant then
		table.insert(sinTextura, row.Material)
	end
end
Cloud.check(("Materiales con su textura realista (%d de la tabla; Plaster y tejas van pieza a pieza)"):format(#Choice.Table), #sinTextura == 0,
	if #sinTextura == 0 then "todos sustituidos en MaterialService" else "sin textura: " .. table.concat(sinTextura, ", "))

-- 2. Assets de la Tienda (muebles, objetos, carrocerías)
local function carga(id: number): (boolean, string)
	local ok, res = pcall(AssetService.LoadAssetAsync, AssetService, id)
	if ok and res then
		local n = #res:GetDescendants()
		res:Destroy()
		return true, ("%d objetos"):format(n)
	end
	return false, tostring(res)
end
local ids: { [number]: string } = {}
local okIP, InteriorProps = pcall(require, World:WaitForChild("InteriorProps"))
if okIP then
	for name, id in InteriorProps.Assets do
		ids[id] = "Muebles: " .. name
	end
	for id in InteriorProps.Skipped or {} do
		ids[id] = nil
	end
end
local okCB, CarBodies = pcall(require, World:WaitForChild("Kit"):WaitForChild("CarBodies"))
if okCB then
	for _, src in CarBodies.Sources or {} do
		ids[src.Id] = "Carrocería: " .. tostring(src.Pack)
	end
	for _, src in CarBodies.WheelSources or {} do
		if type(src) == "table" and src.Id then
			ids[src.Id] = "Ruedas: " .. tostring(src.Pack or src.Id)
		end
	end
end
local lista = {}
for id in ids do
	table.insert(lista, id)
end
table.sort(lista)
local fallan = {}
for _, id in lista do
	if Cloud.quedan and Cloud.quedan() < 40 then
		Cloud.aviso("Assets de la Tienda", false, "sin tiempo para mirar todos")
		break
	end
	local ok, detail = carga(id)
	if not ok then
		table.insert(fallan, ("%s (%d): %s"):format(ids[id], id, detail))
	end
end
Cloud.check(("Assets de la Tienda que cargan (%d)"):format(#lista), #fallan == 0, if #fallan == 0 then "todos" else Cloud.lista(fallan, 10))

-- 3. Imágenes subidas (Grieta del cielo). Se suben como Decal: el juego saca el id de la imagen al
-- arrancar (shared/Images.resolve, como en Main.server) y es ese el que se usa.
local okR, Rift = pcall(require, Cloud.Shared:WaitForChild("RiftTextureIds"))
local okI, Images = pcall(require, Cloud.Shared:WaitForChild("Images"))
if okR and okI then
	pcall(Images.resolve, Rift)
	local malas = {}
	local total = 0
	for name, uri in Rift do
		total += 1
		local estado = "?"
		pcall(function()
			ContentProvider:PreloadAsync({ Images.of(uri) }, function(_, s)
				estado = s.Name
			end)
		end)
		if estado ~= "Success" then
			table.insert(malas, ("%s → %s (%s)"):format(name, estado, Images.of(uri)))
		end
	end
	Cloud.check(("Imágenes subidas que cargan (%d)"):format(total), #malas == 0, if #malas == 0 then "todas" else table.concat(malas, ", "))
end

return Cloud.resultado()
