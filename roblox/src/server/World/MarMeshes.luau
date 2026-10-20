-- MarMeshes: carga las mallas del kit del mar hechas en Blender (scripts/map/mar_kit_blender.py, subidas con
-- scripts/upload-mar.sh: shared/Sea/MarAssetIds) y las deja en ReplicatedStorage.MarMallas (una MeshPart
-- por pieza de shared/Sea/MarKit, con el atributo "Pieza") para el servidor (World/ReefZoneBuilder) y el
-- cliente (Controllers/SeaBiome: el fondo de la orilla). Sin ids o si falla, NO cambia nada: siguen las
-- piezas de respaldo (MarKit.fallback). Documentación: docs/mar/diseno-v2.md
--
--   MarMeshes.prepare(ids, kit, download) -> (Folder?, string)   (puro salvo download: pruebas)
--   MarMeshes.start(onReady)    en un hilo aparte
--   MarMeshes.folder()          la carpeta si ya está cargada, o nil

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MarMeshes = {}
MarMeshes.Status = "sin empezar"

local loaded: Folder? = nil
local started = false

local function idOf(value: any): number?
	if type(value) ~= "string" and type(value) ~= "number" then
		return nil
	end
	local n = tonumber(string.match(tostring(value), "(%d+)%s*$") or "")
	return if n and n > 0 then n else nil
end
MarMeshes.idOf = idOf

function MarMeshes.hasIds(ids: any): boolean
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

-- kit: shared/Sea/MarKit (Pieces: Size, Tint…). Las piezas «Tint» (corales, plantas, luz) llevan el
-- color de la paleta de la zona (MeshPart.Color con material) y no la textura; las demás, su textura
-- horneada de color (y de normales si Roblox deja ponerla desde un script).
function MarMeshes.prepare(ids: any, kit: any, download: (number) -> Instance?): (Folder?, string)
	if not MarMeshes.hasIds(ids) then
		return nil, "sin ids (scripts/upload-mar.sh no se ha lanzado todavía)"
	end
	local folder = Instance.new("Folder")
	folder.Name = "MarMallas"
	local n = 0
	local tex = ids.Texturas or {}
	for name, info in kit.Pieces do
		local id = idOf(ids.Mallas[name])
		if id then
			local ok, model = pcall(download, id)
			local mp = nil
			if ok and model then
				mp = if model:IsA("MeshPart") then model else model:FindFirstChildWhichIsA("MeshPart", true)
			end
			if mp then
				local c = mp:Clone()
				c.Name = name
				for _, d in c:GetChildren() do
					if not d:IsA("SurfaceAppearance") then
						d:Destroy()
					end
				end
				c.Anchored = true
				c.CanCollide = false
				c.CanQuery = false
				c.CanTouch = false
				c.CastShadow = false
				c:SetAttribute("Pieza", name)
				pcall(function()
					local any = c :: any
					any.RenderFidelity = Enum.RenderFidelity.Automatic -- (LOD de Roblox: de lejos, menos triángulos)
					any.CollisionFidelity = Enum.CollisionFidelity.Box
				end)
				local lower = string.lower(name)
				local color = tex[lower .. "_color"]
				local normal = tex[lower .. "_normal"]
				if info.Tint then
					c.Material = Enum.Material.SmoothPlastic
					pcall(function()
						c.TextureID = ""
					end)
				elseif color and not c:FindFirstChildOfClass("SurfaceAppearance") then
					local okSA = pcall(function()
						local sa = Instance.new("SurfaceAppearance")
						sa.ColorMap = color
						if normal then
							sa.NormalMap = normal
						end
						sa.Parent = c
					end)
					if not okSA then
						for _, d in c:GetChildren() do
							if d:IsA("SurfaceAppearance") then
								d:Destroy()
							end
						end
						pcall(function()
							c.TextureID = color
						end)
					end
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
	return folder, ("ok (%d piezas)"):format(n)
end

function MarMeshes.folder(): Folder?
	return if loaded and loaded.Parent then loaded else nil
end

function MarMeshes.start(onReady: (() -> ())?)
	if started then
		return
	end
	started = true
	task.spawn(function()
		local ok, err = pcall(function()
			local ids = require(ReplicatedStorage.Shared.Sea.MarAssetIds)
			if not MarMeshes.hasIds(ids) then
				MarMeshes.Status = "respaldo: sin ids"
				return
			end
			-- Las texturas se suben como Decal: hay que pasarlas a id de imagen o no se ven
			if type(ids.Texturas) == "table" then
				local Images = require(ReplicatedStorage.Shared.Images)
				pcall(Images.resolve, ids.Texturas)
				ids = table.clone(ids)
				ids.Texturas = Images.map(ids.Texturas)
			end
			local kit = require(ReplicatedStorage.Shared.Sea.MarKit)
			local AssetLoader = require(script.Parent.AssetLoader)
			local folder, why = MarMeshes.prepare(ids, kit, AssetLoader.download)
			MarMeshes.Status = if folder then "malla" else "respaldo: " .. why
			if folder then
				folder.Parent = ReplicatedStorage
				loaded = folder
				if onReady then
					onReady()
				end
			else
				warn("[MarMeshes] mallas no cargadas (" .. why .. "): siguen las de piezas")
			end
		end)
		if not ok then
			MarMeshes.Status = "respaldo: " .. tostring(err)
			warn("[MarMeshes] " .. tostring(err))
		end
	end)
end

return MarMeshes
