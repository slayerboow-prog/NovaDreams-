-- AsteroidMeshes: carga las mallas de asteroide de Blender (scripts/espacio/asteroides_blender.py, subidas
-- con scripts/upload-asteroides.sh: shared/Cosmos/AsteroidAssetIds) y las deja en
-- ReplicatedStorage.AsteroideMallas (una MeshPart por variante, con sus atributos "Variante" y "Medida")
-- para el servidor (World/SpaceWorld) y el cliente (Controllers/AsteroidFx: los trozos).
-- Documentación: docs/espacio-aaa/asteroides.md
--
--   AsteroidMeshes.prepare(ids, malla, download) -> (Folder?, string)   (puro salvo download: pruebas)
--   AsteroidMeshes.start(onReady)    en un hilo aparte; sin ids o si falla, NO cambia nada (respaldo de piezas)
--   AsteroidMeshes.folder()          la carpeta si ya está cargada, o nil

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AsteroidMeshes = {}
AsteroidMeshes.Status = "sin empezar"

local loaded: Folder? = nil
local started = false

local function idOf(value: any): number?
	if type(value) ~= "string" and type(value) ~= "number" then
		return nil
	end
	local n = tonumber(string.match(tostring(value), "(%d+)%s*$") or "")
	return if n and n > 0 then n else nil
end

function AsteroidMeshes.hasIds(ids: any): boolean
	if type(ids) ~= "table" or type(ids.Mallas) ~= "table" then
		return false
	end
	for _, v in ids.Mallas do
		if idOf(v) then
			return true
		end
	end
	return false
end

-- malla: shared/Cosmos/AsteroidMalla (la lista de variantes con su "Medida" en radios)
function AsteroidMeshes.prepare(ids: any, malla: any, download: (number) -> Instance?): (Folder?, string)
	if not AsteroidMeshes.hasIds(ids) then
		return nil, "sin ids (scripts/upload-asteroides.sh no se ha lanzado todavía)"
	end
	local folder = Instance.new("Folder")
	folder.Name = "AsteroideMallas"
	local n = 0
	local color = (ids.Texturas or {}).asteroide_color
	for _, v in (malla and malla.Variantes) or {} do
		local id = idOf(ids.Mallas[v.Name])
		if id then
			local ok, model = pcall(download, id)
			local mp = nil
			if ok and model then
				mp = if model:IsA("MeshPart") then model else model:FindFirstChildWhichIsA("MeshPart", true)
			end
			if mp then
				local c = mp:Clone()
				c.Name = v.Name
				for _, d in c:GetChildren() do
					if not d:IsA("SurfaceAppearance") then
						d:Destroy()
					end
				end
				c.Anchored = true
				c.CanCollide = false
				c.CanQuery = false
				c.CanTouch = false
				c.Material = Enum.Material.Slate
				c.Color = Color3.fromRGB(150, 144, 138)
				c:SetAttribute("Variante", v.Variant)
				c:SetAttribute("Medida", v.Medida)
				pcall(function()
					(c :: any).RenderFidelity = Enum.RenderFidelity.Automatic -- (LOD de Roblox: de lejos, menos triángulos)
				end)
				if color and not c:FindFirstChildOfClass("SurfaceAppearance") then
					pcall(function()
						(c :: any).TextureID = color
					end)
				end
				c.Parent = folder
				n += 1
			end
		end
	end
	if n == 0 then
		folder:Destroy()
		return nil, "no se pudo cargar ninguna malla"
	end
	return folder, ("ok (%d variantes)"):format(n)
end

function AsteroidMeshes.folder(): Folder?
	return if loaded and loaded.Parent then loaded else nil
end

function AsteroidMeshes.start(onReady: (() -> ())?)
	if started then
		return
	end
	started = true
	task.spawn(function()
		local ok, err = pcall(function()
			local ids = require(ReplicatedStorage.Shared.Cosmos.AsteroidAssetIds)
			if not AsteroidMeshes.hasIds(ids) then
				AsteroidMeshes.Status = "respaldo: sin ids"
				return
			end
			local malla = require(ReplicatedStorage.Shared.Cosmos.AsteroidMalla)
			local AssetLoader = require(script.Parent.AssetLoader)
			local folder, why = AsteroidMeshes.prepare(ids, malla, AssetLoader.download)
			AsteroidMeshes.Status = if folder then "malla" else "respaldo: " .. why
			if folder then
				folder.Parent = ReplicatedStorage
				loaded = folder
				if onReady then
					onReady()
				end
			else
				warn("[Asteroides] mallas no cargadas (" .. why .. "): siguen los de piezas")
			end
		end)
		if not ok then
			AsteroidMeshes.Status = "respaldo: " .. tostring(err)
			warn("[Asteroides] " .. tostring(err))
		end
	end)
end

return AsteroidMeshes
