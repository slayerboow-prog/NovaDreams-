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
--   * Las de cristal (Crystal: los Vórtidos) en Glass cian pálido algo transparente, sin textura.
--   * Los ids se buscan por el Asset del modelo si lo tiene (VortidosCristal2_*) y si no por su id.
--   * Modelos con esqueleto (Skinned: los Vórtidos de cristal desde la v125): Cuerpo, CuerpoCristal y
--     CuerpoBrillo con sus Bone (se guardan al copiar; si Roblox los dejó en otra pieza, se pasan al Cuerpo).
--   * Mallas retiradas por la moderación (World/MallasRetiradas, docs/bugs/moderacion/): si una pieza
--     principal usa una, ESE modelo sigue con el de piezas; nunca una criatura sin brazo.
--   * Las de brillo van en Neon del color Glow de la raza; RenderFidelity Automatic (Roblox baja el detalle
--     de lejos) y además la versión LOD que pone el cliente (Controllers/AlienAnim).
--
--   AlienMeshLoader.hasIds(ids) -> boolean
--   AlienMeshLoader.prepare(ids, download, mallas, races, verify?) -> ({ [id]: Folder }, { [id]: string })
--                                                  (puro salvo download y verify)
--   AlienMeshLoader.template(id) -> Folder?        (la plantilla cargada, o nil = respaldo de piezas)
--   AlienMeshLoader.start() -> number              (cuántos modelos de malla hay)
--   AlienMeshLoader.loading() -> boolean           (¿sigue descargando? InvasionService espera a que acabe
--                                                   antes de empezar una invasión sola: si no, las tropas
--                                                   de las primeras oleadas salían con el respaldo de piezas)
--   AlienMeshLoader.glowColor(c) -> Color3         (el Neon un poco más apagado: de noche no deslumbra)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Retiradas = require(script.Parent.MallasRetiradas)

local AlienMeshLoader = {}

AlienMeshLoader.Status = "sin empezar"
local templates: { [string]: Folder } = {}
local busy = false

function AlienMeshLoader.loading(): boolean
	return busy
end

-- El brillo (Neon) de la raza, más apagado: un Neon casi blanco (Lumínidos) se comía la silueta de noche
-- (captura del dueño). Los colores muy claros bajan más.
function AlienMeshLoader.glowColor(c: Color3): Color3
	local lum = 0.2126 * c.R + 0.7152 * c.G + 0.0722 * c.B
	local k = if lum > 0.8 then 0.62 elseif lum > 0.6 then 0.72 else 0.82
	return Color3.new(c.R * k, c.G * k, c.B * k)
end

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

-- El cristal de los Vórtidos (vortidos_blender.py): Glass cian pálido, algo transparente (dentro lleva
-- sus núcleos de Neon, que se ven a través: de noche brilla y no se pierde la silueta)
AlienMeshLoader.CrystalTransparency = 0.18
function AlienMeshLoader.crystalColor(model: any): Color3
	local c = type(model) == "table" and model.CrystalColor
	if type(c) == "table" and #c == 3 then
		return Color3.fromRGB(c[1], c[2], c[3])
	end
	return Color3.fromRGB(142, 230, 255)
end

local function dress(part: MeshPart, spec: any, model: any, glow: Color3?, textures: { [string]: string })
	pcall(function()
		(part :: any).RenderFidelity = Enum.RenderFidelity.Automatic
	end)
	if spec.Crystal then
		for _, d in part:GetChildren() do
			if d:IsA("SurfaceAppearance") then
				d:Destroy()
			end
		end
		part.Material = Enum.Material.Glass
		part.Color = AlienMeshLoader.crystalColor(model)
		part.Transparency = AlienMeshLoader.CrystalTransparency
		part.Reflectance = 0.05
		part.CastShadow = false
		return
	end
	if spec.Glow then
		part.Material = Enum.Material.Neon
		if glow then
			part.Color = AlienMeshLoader.glowColor(glow)
		end
		part.CastShadow = false
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

-- Los huesos (Bone) de un modelo con esqueleto (shared/Invasion/AlienMallas: Skinned): Roblox los pone
-- dentro de alguna de sus MeshPart (o de otra pieza del Model); aquí van todos dentro de la principal
-- (Cuerpo), en su sitio respecto a ella, para que se muevan con ella y el cliente los anime.
local function adoptBones(dst: BasePart, srcPart: BasePart, sources: { Instance? })
	if dst:FindFirstChildWhichIsA("Bone", true) then
		return
	end
	for _, src in sources do
		if not src then
			continue
		end
		for _, b in src:GetDescendants() do
			if b:IsA("Bone") and not (b.Parent and b.Parent:IsA("Bone")) then
				local holder = b.Parent
				local world = if holder and holder:IsA("BasePart") then holder.CFrame * b.CFrame else b.CFrame
				local c = b:Clone()
				c.CFrame = srcPart.CFrame:ToObjectSpace(world)
				c.Parent = dst
			end
		end
		if dst:FindFirstChildWhichIsA("Bone", true) then
			return
		end
	end
end

-- Prepara las plantillas: { [id del modelo] = Folder con una MeshPart por pieza } y por qué falló cada
-- uno que no se pudo (los demás siguen con el respaldo de piezas).
-- download(id) -> Instance? (World/AssetLoader.download en el juego; un doble en las pruebas).
-- races: shared/Invasion/Races (para el color del brillo).
-- verify(parts, probe) -> { [id de malla]: true } (opcional): las mallas que no valen (World/MallasRetiradas:
-- las retiradas por la moderación y, en el servidor, las que de verdad no cargan). Sin verify, la lista de
-- retiradas. Si una pieza principal usa una malla que no vale, ESE modelo sigue con el de piezas; si es de
-- brillo o de LOD, solo se quita esa pieza.
function AlienMeshLoader.prepare(ids: any, download: (number) -> Instance?, mallas: any, races: any, verify: any?): ({ [string]: Folder }, { [string]: string })
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
	-- 1) descargar y encontrar las piezas de cada modelo
	type Found = { Model: any, Sources: { Instance? }, Parts: { [string]: MeshPart } }
	local found: { [string]: Found } = {}
	local all: { Instance } = {}
	local probe: { Instance } = {}
	for modelId, model in (mallas and mallas.Models) or {} do
		-- (los ids van por el nombre con que se subió: el del modelo o, si lo tiene, su Asset; los Vórtidos
		-- de cristal se suben como «VortidosCristal2_*»: los «VortidosCristal_*» de la v124 —segmentos
		-- sueltos, dos retirados por la moderación— y los viejos «Vortidos_*» ya no valen)
		local key = if type(model.Asset) == "string" then model.Asset else modelId
		local sources = { get(idOf((ids.Completos or {})[key])), get(idOf((ids.Modelos or {})[key])) }
		if not sources[1] and not sources[2] then
			why[modelId] = "sin id"
			continue
		end
		local parts: { [string]: MeshPart } = {}
		for _, spec in model.Parts do
			local mp = findPart(sources[1], spec.Name) or findPart(sources[2], spec.Name)
			if mp then
				parts[spec.Name] = mp
				table.insert(all, mp)
				if model.Skinned and not spec.Lod then
					table.insert(probe, mp) -- (pocas mallas por modelo: se pueden probar de verdad)
				end
			end
		end
		found[modelId] = { Model = model, Sources = sources, Parts = parts }
	end
	-- 2) las mallas que no valen (retiradas por la moderación o que no cargan)
	local bad: { [number]: boolean } = {}
	local okV, res = pcall(function()
		if verify then
			return verify(all, probe)
		end
		return Retiradas.bad(all)
	end)
	if okV and type(res) == "table" then
		bad = res
	end
	-- 3) montar las plantillas
	for modelId, f in found do
		local model = f.Model
		local race = races and races.get and races.get(model.Race)
		local glow = race and Color3.fromRGB(race.Palette.Glow[1], race.Palette.Glow[2], race.Palette.Glow[3]) or nil
		local folder = Instance.new("Folder")
		folder.Name = modelId
		local missing = {}
		local retired = {}
		for _, spec in model.Parts do
			local mp = f.Parts[spec.Name]
			local meshId = if mp then Retiradas.meshIdOf(mp) else nil
			if mp and meshId and bad[meshId] then
				table.insert(retired, spec.Name)
				mp = nil
			end
			if mp then
				local c = mp:Clone()
				c.Name = spec.Name
				for _, d in c:GetChildren() do
					if not d:IsA("SurfaceAppearance") and not d:IsA("Bone") then
						d:Destroy()
					end
				end
				if spec.Skinned and not spec.Glow and not spec.Crystal then
					adoptBones(c, mp, f.Sources)
				end
				dress(c, spec, model, glow, textures)
				c.Parent = folder
			elseif not spec.Glow and not spec.Lod then
				table.insert(missing, spec.Name)
			end
		end
		if #missing > 0 then
			folder:Destroy()
			why[modelId] = (if #retired > 0 then "malla retirada o que no carga: " else "faltan piezas: ") .. table.concat(missing, ", ")
		else
			out[modelId] = folder
			if #retired > 0 then
				why[modelId .. " (aviso)"] = "sin estas piezas de brillo o LOD (malla retirada): " .. table.concat(retired, ", ")
			end
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
	busy = true
	AlienMeshLoader.Status = "cargando"
	pcall(function()
		workspace:SetAttribute("AlienVisual", "cargando")
	end)
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
		-- (las mallas retiradas por la moderación —y, en los de esqueleto, las que de verdad no cargan— no se
		-- usan: ese modelo sigue con el de piezas; World/MallasRetiradas)
		local create = Retiradas.realCreate(5)
		local verify = function(all, probe)
			return Retiradas.bad(all, create, probe)
		end
		local map, why = AlienMeshLoader.prepare(ids, AssetLoader.download, require(Shared.Invasion.AlienMallas), require(Shared.Invasion.Races), verify)
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
		local list = {}
		for id, reason in why do
			if not string.find(id, "(aviso)", 1, true) then
				bad += 1
			end
			if #list < 6 then
				table.insert(list, id .. " (" .. tostring(reason) .. ")")
			end
		end
		if bad > 0 then
			warn("[Aliens] con el respaldo de piezas: " .. table.concat(list, ", "))
		end
		AlienMeshLoader.Status = ("malla: %d modelos (%d con el respaldo de piezas)"):format(n, bad)
		print("[Aliens] " .. AlienMeshLoader.Status)
		return n
	end)
	busy = false
	if not ok then
		AlienMeshLoader.Status = "respaldo: " .. tostring(result)
		warn("[Aliens] " .. tostring(result))
	end
	-- (para /debug y cloud-test: qué se está usando en este servidor)
	pcall(function()
		workspace:SetAttribute("AlienVisual", AlienMeshLoader.Status)
	end)
	return if ok then result else 0
end

return AlienMeshLoader
