-- diag-carga: ¿cargan los assets de la comunidad en un servidor de verdad? Grieta (Images.resolve) y casa de Cosme
--
-- Diagnóstico de la v89 (docs/diagnostico-v89.md). No arranca los módulos: prueba la descarga a pelo.
--   1. Para unos pocos ids de cada módulo: AssetService:LoadAssetAsync(id) e InsertService:LoadAsset(id),
--      con el error exacto, y de quién es cada asset (GetProductInfo) frente al dueño del juego.
--   2. Grieta del cielo: Images.resolve(RiftTextureIds) y, para cada id, decal -> imagen.
--   3. Casa de Cosme: ¿está en workspace (etiqueta CosmeHouse), dónde? ¿Tiene marcador en MapInfo/MapLegend?
--
-- Uso: bash scripts/cloud-test.sh -v diag-carga   (o --version 89 -v diag-carga)

local Cloud = Cloud :: any
local AssetService = game:GetService("AssetService")
local InsertService = game:GetService("InsertService")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function line(s: string)
	print("[diag] " .. s)
end

---------------------------------------------------------------------
-- 0) El juego y AllowInsertFreeAssets
---------------------------------------------------------------------
local okAllow, allow = pcall(function()
	return (AssetService :: any).AllowInsertFreeAssets
end)
line(("AssetService.AllowInsertFreeAssets = %s (%s)"):format(tostring(allow), if okAllow then "leído" else "no se puede leer"))
line(("game.CreatorType = %s, game.CreatorId = %d, PlaceId = %d, PlaceVersion = %d, GameId = %d"):format(
	tostring(game.CreatorType), game.CreatorId, game.PlaceId, game.PlaceVersion, game.GameId))
Cloud.info("AllowInsertFreeAssets", tostring(allow))
Cloud.info("PlaceVersion", game.PlaceVersion)
Cloud.info("Creator", ("%s %d"):format(tostring(game.CreatorType), game.CreatorId))

---------------------------------------------------------------------
-- 1) Descarga a pelo
---------------------------------------------------------------------
local IDS = {
	{ "MeshLibrary", 6432306802 }, { "MeshLibrary", 10840661513 },
	{ "NatureAssets", 96924659951632 }, { "NatureAssets", 8553512581 }, { "NatureAssets", 16879341926 }, { "NatureAssets", 9262569938 },
	{ "CityAssets", 5411055653 }, { "CityAssets", 113264079562085 }, { "CityAssets", 99479110531330 },
	{ "InteriorProps", 8236576991 }, { "InteriorProps", 13395313510 }, { "InteriorProps", 5674029686 },
	{ "UserMaterials", 11392874817 }, { "UserMaterials", 15221806045 }, { "UserMaterials", 124901321113776 }, { "UserMaterials", 92927007790601 },
	{ "MaterialExtras", 12433695725 }, { "MaterialExtras", 3778526307 }, { "MaterialExtras", 12152263865 },
	{ "CarBodies", 6418239833 }, { "CarBodies", 9432856072 }, { "CarBodies", 97902046131324 }, { "CarBodies", 16358361587 },
	{ "SkyAssets", 102765136165948 }, { "SkyAssets", 8159177542 }, { "SkyAssets", 11365590395 },
	{ "UserArsenal", 117850698505269 }, { "UserArsenal", 9700798278 }, { "UserArsenal", 266515007 },
}

local function short(err: any): string
	return (tostring(err):gsub("\n", " ")):sub(1, 160)
end

local stats = { async = 0, insert = 0, total = 0, communityAsync = 0, communityInsert = 0, community = 0 }
local fails: { string } = {}
for _, row in IDS do
	if Cloud.quedan() < 120 then
		line("(sin tiempo: se dejan de probar ids)")
		break
	end
	local module, id = row[1], row[2]
	stats.total += 1
	local creator, ctype = "?", "?"
	pcall(function()
		local info = MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset)
		creator = tostring(info.Creator and info.Creator.Name)
		ctype = tostring(info.Creator and info.Creator.CreatorType)
	end)
	local official = creator == "Roblox"
	if not official then
		stats.community += 1
	end
	local t = os.clock()
	local okA, a = pcall(function()
		return (AssetService :: any):LoadAssetAsync(id)
	end)
	local ta = os.clock() - t
	local resA = if okA and typeof(a) == "Instance" then ("OK (%s, %d descendientes, %.1f s)"):format(a.ClassName, #a:GetDescendants(), ta) else ("FALLA: %s"):format(short(a))
	if okA and typeof(a) == "Instance" then
		stats.async += 1
		if not official then
			stats.communityAsync += 1
		end
		a:Destroy()
	end
	t = os.clock()
	local okI, b = pcall(function()
		return InsertService:LoadAsset(id)
	end)
	local resI = if okI and typeof(b) == "Instance" then ("OK (%d descendientes, %.1f s)"):format(#b:GetDescendants(), os.clock() - t) else ("FALLA: %s"):format(short(b))
	if okI and typeof(b) == "Instance" then
		stats.insert += 1
		if not official then
			stats.communityInsert += 1
		end
		b:Destroy()
	end
	line(("%s %d [%s %s] LoadAssetAsync: %s | InsertService:LoadAsset: %s"):format(module, id, ctype, creator, resA, resI))
	if not (okA and typeof(a) == "Instance") then
		table.insert(fails, ("%s %d: %s"):format(module, id, short(a)))
	end
end
Cloud.check(("LoadAssetAsync carga %d/%d (comunidad %d/%d)"):format(stats.async, stats.total, stats.communityAsync, stats.community),
	stats.async == stats.total, Cloud.lista(fails, 40))
Cloud.info("InsertService_LoadAsset", ("%d/%d (comunidad %d/%d)"):format(stats.insert, stats.total, stats.communityInsert, stats.community))

---------------------------------------------------------------------
-- 2) Grieta: Images.resolve
---------------------------------------------------------------------
local Shared = ReplicatedStorage:WaitForChild("Shared")
local okR, err = pcall(function()
	local Images = require(Shared:WaitForChild("Images")) :: any
	local ids = require(Shared:WaitForChild("RiftTextureIds")) :: any
	local t = os.clock()
	local converted = Images.resolve(ids)
	line(("Images.resolve(RiftTextureIds): %d convertidos en %.1f s"):format(converted, os.clock() - t))
	local names = {}
	for k in ids do
		table.insert(names, k)
	end
	table.sort(names)
	local same, changed = 0, 0
	for _, k in names do
		local decal = ids[k]
		local image = Images.of(decal)
		local n = tonumber(decal:match("(%d+)$"))
		-- ¿Qué tipo de asset es el id que hay en el archivo?
		local kind = "?"
		pcall(function()
			local info = MarketplaceService:GetProductInfo(n, Enum.InfoType.Asset)
			kind = ("AssetTypeId=%s creador=%s"):format(tostring(info.AssetTypeId), tostring(info.Creator and info.Creator.Name))
		end)
		-- Directo: InsertService:LoadAsset del id (lo que hace Images por dentro)
		local direct = "?"
		local okL, m = pcall(function()
			return InsertService:LoadAsset(n)
		end)
		if okL and m then
			local tex = {}
			for _, d in m:GetDescendants() do
				if d:IsA("Decal") or d:IsA("Texture") then
					table.insert(tex, d.ClassName .. "=" .. tostring((d :: any).Texture))
				end
			end
			direct = "OK " .. table.concat(tex, ",")
			m:Destroy()
		else
			direct = "FALLA " .. short(m)
		end
		if image == decal then
			same += 1
		else
			changed += 1
		end
		line(("Grieta %s: %s -> %s [%s] LoadAsset: %s"):format(k, decal, image, kind, direct))
	end
	Cloud.check(("Grieta: %d ids pasados a imagen, %d se quedan igual"):format(changed, same), same == 0)
	local f = ReplicatedStorage:FindFirstChild("ImageIds")
	local attrs = 0
	if f then
		for _ in f:GetAttributes() do
			attrs += 1
		end
	end
	Cloud.info("ImageIds_atributos", attrs)
end)
if not okR then
	Cloud.check("Grieta: Images.resolve", false, short(err))
end

---------------------------------------------------------------------
-- 3) Casa de Cosme y el mapa
---------------------------------------------------------------------
local tagged = CollectionService:GetTagged("CosmeHouse")
local where = {}
for _, m in tagged do
	local p = Cloud.posicion(m)
	table.insert(where, ("%s en %s (%d descendientes)"):format(m:GetFullName(), if p then Cloud.v3(p) else "?", #m:GetDescendants()))
end
line("Etiqueta CosmeHouse: " .. #tagged .. " -> " .. table.concat(where, " | "))
local byName = {}
for _, d in workspace:GetDescendants() do
	if d:IsA("Model") and string.find(string.lower(d.Name), "cosme") then
		table.insert(byName, d:GetFullName())
		if #byName >= 10 then
			break
		end
	end
end
line("Modelos con 'cosme' en el nombre: " .. #byName .. " -> " .. table.concat(byName, " | "))
local town = workspace:FindFirstChild("Town")
line(("workspace.Town: %s; atributos: %s"):format(tostring(town ~= nil), if town then (function()
	local a = {}
	for k, v in town:GetAttributes() do
		table.insert(a, k .. "=" .. tostring(v))
	end
	table.sort(a)
	return table.concat(a, ", ")
end)() else "-"))
pcall(function()
	local Region = require(Cloud.Server.World.Region) :: any
	local site = Region.cosmeSite()
	line(("Region.cosmeSite(): %s"):format(if site then ("%s celda %d,%d centro %s"):format(site.Town, site.Cell[1], site.Cell[2], Cloud.v3(site.CFrame.Position)) else "nil"))
	if site then
		-- ¿Qué hay en la manzana?
		local found = {}
		local params = OverlapParams.new()
		params.MaxParts = 2000
		local parts = workspace:GetPartBoundsInBox(site.CFrame + Vector3.new(0, 20, 0), Vector3.new(site.Half * 2, 60, site.Half * 2), params)
		for _, p in parts do
			local top = p
			while top.Parent and top.Parent ~= workspace and top.Parent ~= town do
				top = top.Parent :: any
			end
			found[top:GetFullName()] = (found[top:GetFullName()] or 0) + 1
		end
		local list = {}
		for k, v in found do
			table.insert(list, k .. "×" .. v)
		end
		table.sort(list)
		line(("En la manzana de Cosme hay %d piezas: %s"):format(#parts, table.concat(list, " | "):sub(1, 1500)))
	end
end)
Cloud.check(("Casa de Cosme en workspace (etiqueta CosmeHouse): %d"):format(#tagged), #tagged > 0)

local mapHits = {}
pcall(function()
	local MapInfo = require(Shared.MapInfo) :: any
	for _, k in MapInfo.Kinds do
		if string.find(string.lower(k.Model .. " " .. k.Name), "cosme") then
			table.insert(mapHits, "MapInfo " .. k.Model)
		end
	end
	local MapLegend = require(Shared.MapLegend) :: any
	for _, c in MapLegend.Categories do
		for _, m in c.Models do
			if string.find(string.lower(m), "cosme") then
				table.insert(mapHits, "MapLegend " .. m)
			end
		end
	end
end)
line("Marcadores de Cosme en MapInfo/MapLegend: " .. #mapHits .. " " .. table.concat(mapHits, ", "))
Cloud.aviso(("Marcador de Cosme en el mapa: %d"):format(#mapHits), #mapHits > 0)

return Cloud.resultado()
