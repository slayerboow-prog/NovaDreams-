-- AlienMeshLoader: carga los alienígenas v2 (las MeshPart hechas en Blender con
-- scripts/invasion/alien_blender.py y subidas con scripts/upload-invasion.sh: shared/Invasion/AlienAssetIds)
-- y se las da a World/Kit/AlienModels. Documentación: docs/invasion.md («Alienígenas v2»).
--
-- Igual que World/NaveLoader (la nave realista):
--   * En el SERVIDOR, al arrancar, en un hilo aparte, con World/AssetLoader.download (los Model del
--     dueño del juego). Por cada modelo: primero el "Completo" (con SurfaceAppearance, fase 3 del script)
--     y, si no está o le falta algo, el Model del FBX con las piezas sueltas.
--   * Cada pieza se busca por su NOMBRE (Body, Head, ArmL, HeadBrillo, LOD…: shared/Invasion/AlienMallas).
--     Si falta una pieza principal (no de brillo ni LOD), ESE modelo no se usa: sigue el de piezas
--     (el respaldo de AlienModels). Nunca lanza error y nunca deja un modelo a medias.
--   * Texturas: si la pieza trae SurfaceAppearance, se queda; si no, se intenta crear y, si no se puede
--     (en un juego publicado los scripts no pueden poner sus mapas), MeshPart.TextureID = el mapa de color.
--   * Las de brillo van en Neon del color Glow de la raza; RenderFidelity Automatic (Roblox baja el detalle
--     de lejos) y además la versión LOD que pone el cliente (Controllers/AlienAnim).
--
--   AlienMeshLoader.hasIds(ids) -> boolean
--   AlienMeshLoader.prepare(ids, download, mallas, races) -> ({ [id]: Folder }, { [id]: string })   (puro salvo download)
--   AlienMeshLoader.template(id) -> Folder?        (la plantilla cargada, o nil = respaldo de piezas)
--   AlienMeshLoader.start() -> number              (cuántos modelos de malla hay)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AlienMeshLoader = {}

AlienMeshLoader.Status = "sin empezar"
local templates: { [string]: Folder } = {}

local function idOf(value: any): number?
	if type(value) == "number" then
		return value
	end
	if type(value) ~= "string" then
		return nil
	end
	local n = tonumber(string.match(value, "(%d+)%s*$") or "")
	return if n and n > 0 then n else nil
end
AlienMeshLoader.idOf = idOf

function AlienMeshLoader.hasIds(ids: any): boolean
	if type(ids) ~= "table" then
		return false
	end
	for _, section in { ids.Completos, ids.Modelos } do
		if type(section) == "table" then
			for _, v in section do
				if idOf(v) then
					return true
				end
			end
		end
	end
	return false
end

local function findPart(inst: Instance?, name: string): MeshPart?
	if not inst then
		return nil
	end
	if inst:IsA("MeshPart") and inst.Name == name then
		return inst
	end
	local found = inst:FindFirstChild(name, true)
	return if found and found:IsA("MeshPart") then found else nil
end

local function enumMaterial(name: string?): Enum.Material
	local ok, m = pcall(function()
		return (Enum.Material :: any)[name or "SmoothPlastic"]
	end)
	return if ok and m then m else Enum.Material.SmoothPlastic
end

local function dress(part: MeshPart, spec: any, model: any, glow: Color3?, textures: { [string]: string })
	pcall(function()
		(part :: any).RenderFidelity = Enum.RenderFidelity.Automatic
	end)
	if spec.Glow then
		part.Material = Enum.Material.Neon
		if glow then
			part.Color = glow
		end
		for _, d in part:GetChildren() do
			if d:IsA("SurfaceAppearance") then
				d:Destroy()
			end
		end
		return
	end
	part.Material = enumMaterial(model.Material)
	part.Color = Color3.new(1, 1, 1)
	if part:FindFirstChildOfClass("SurfaceAppearance") then
		return
	end
	local set = model.Set
	local color = set and textures[set .. "_color"]
	if not color then
		return
	end
	local ok = pcall(function()
		local sa = Instance.new("SurfaceAppearance")
		sa.ColorMap = color
		if textures[set .. "_normal"] then
			sa.NormalMap = textures[set .. "_normal"]
		end
		if textures[set .. "_rugosidad"] then
			sa.RoughnessMap = textures[set .. "_rugosidad"]
		end
		if textures[set .. "_metal"] then
			sa.MetalnessMap = textures[set .. "_metal"]
		end
		sa.Parent = part
	end)
	if not ok then
		for _, d in part:GetChildren() do
			if d:IsA("SurfaceAppearance") then
				d:Destroy()
			end
		end
		pcall(function()
			(part :: any).TextureID = color
		end)
	end
end

-- Prepara las plantillas: { [id del modelo] = Folder con una MeshPart por pieza } y por qué falló cada
-- uno que no se pudo (los demás siguen con el respaldo de piezas).
-- download(id) -> Instance? (World/AssetLoader.download en el juego; un doble en las pruebas).
-- races: shared/Invasion/Races (para el color del brillo).
function AlienMeshLoader.prepare(ids: any, download: (number) -> Instance?, mallas: any, races: any): ({ [string]: Folder }, { [string]: string })
	local out: { [string]: Folder } = {}
	local why: { [string]: string } = {}
	if not AlienMeshLoader.hasIds(ids) then
		return out, { ["*"] = "sin ids (scripts/upload-invasion.sh no se ha lanzado todavía)" }
	end
	local textures = ids.Texturas or {}
	local cache: { [number]: Instance | false } = {}
	local function get(id: number?): Instance?
		if not id then
			return nil
		end
		if cache[id] == nil then
			local ok, model = pcall(download, id)
			cache[id] = if ok and typeof(model) == "Instance" then model else false
		end
		return cache[id] or nil
	end
	for modelId, model in (mallas and mallas.Models) or {} do
		local sources = { get(idOf((ids.Completos or {})[modelId])), get(idOf((ids.Modelos or {})[modelId])) }
		if not sources[1] and not sources[2] then
			why[modelId] = "sin id"
			continue
		end
		local race = races and races.get and races.get(model.Race)
		local glow = race and Color3.fromRGB(race.Palette.Glow[1], race.Palette.Glow[2], race.Palette.Glow[3]) or nil
		local folder = Instance.new("Folder")
		folder.Name = modelId
		local missing = {}
		for _, spec in model.Parts do
			local mp = findPart(sources[1], spec.Name) or findPart(sources[2], spec.Name)
			if mp then
				local c = mp:Clone()
				c.Name = spec.Name
				for _, d in c:GetChildren() do
					if not d:IsA("SurfaceAppearance") then
						d:Destroy()
					end
				end
				dress(c, spec, model, glow, textures)
				c.Parent = folder
			elseif not spec.Glow and not spec.Lod then
				table.insert(missing, spec.Name)
			end
		end
		if #missing > 0 then
			folder:Destroy()
			why[modelId] = "faltan piezas: " .. table.concat(missing, ", ")
		else
			out[modelId] = folder
		end
	end
	return out, why
end

function AlienMeshLoader.template(id: string): Folder?
	return templates[id]
end

-- (las pruebas) poner o quitar plantillas a mano
function AlienMeshLoader._set(map: { [string]: Folder }?)
	templates = map or {}
end

function AlienMeshLoader.start(): number
	local ok, result = pcall(function()
		local Shared = ReplicatedStorage.Shared
		local ids = require(Shared.Invasion.AlienAssetIds)
		if not AlienMeshLoader.hasIds(ids) then
			AlienMeshLoader.Status = "respaldo: sin ids"
			return 0
		end
		-- Las texturas se suben como Decal: antes se pasan a su imagen (shared/Images, con InsertService)
		local Images = require(Shared.Images)
		if ids.Texturas then
			pcall(Images.resolve, ids.Texturas)
			ids = { Completos = ids.Completos, Modelos = ids.Modelos, Texturas = Images.map(ids.Texturas) }
		end
		local AssetLoader = require(script.Parent.AssetLoader)
		local map, why = AlienMeshLoader.prepare(ids, AssetLoader.download, require(Shared.Invasion.AlienMallas), require(Shared.Invasion.Races))
		local holder = Instance.new("Folder")
		holder.Name = "AlienMallas"
		local n = 0
		for id, f in map do
			f.Parent = holder
			n += 1
		end
		holder.Parent = game:GetService("ServerStorage")
		templates = map
		local bad = 0
		for _ in why do
			bad += 1
		end
		AlienMeshLoader.Status = ("malla: %d modelos (%d con el respaldo de piezas)"):format(n, bad)
		print("[Aliens] " .. AlienMeshLoader.Status)
		return n
	end)
	if not ok then
		AlienMeshLoader.Status = "respaldo: " .. tostring(result)
		warn("[Aliens] " .. tostring(result))
		return 0
	end
	return result
end

return AlienMeshLoader
