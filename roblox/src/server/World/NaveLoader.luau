-- NaveLoader: carga la nave realista «HX-7 Halcón» (las MeshPart hechas en Blender y subidas con
-- scripts/upload-nave.sh: shared/AirCombat/NaveAssetIds) y se la da a shared/AirCombat/ShipModel.
-- Documentación: docs/espacio-aaa/nave-realista.md.
--
-- Cómo se cargan (en el SERVIDOR, al arrancar, en un hilo aparte):
--   * Con World/AssetLoader.download (AssetService:LoadAssetAsync y, si falla, InsertService:LoadAsset,
--     con reintentos y cola): un juego puede cargar así los Model de SU dueño (el mismo usuario o grupo
--     que sube los assets con la clave de Open Cloud). Un script no puede crear una MeshPart a partir de un
--     archivo, y AssetService:CreateMeshPartAsync necesita el id de la MALLA (que Open Cloud no devuelve al
--     subir un FBX): por eso se sube cada pieza como Model y se saca su MeshPart.
--   * Primero "Completa" (un Model con todas las piezas y su SurfaceAppearance, hecho por la fase 2 del
--     script); si no está o le faltan piezas, cada pieza de "Piezas" por separado.
--   * Texturas: si la pieza ya trae SurfaceAppearance, se queda; si no, se intenta crear una (en un juego
--     publicado los scripts no pueden poner sus mapas: por eso la fase 2 la mete dentro del Model) y, si
--     no se puede, MeshPart.TextureID = el mapa de color (eso sí se puede siempre).
--   * Si faltan ids, falla la carga o falta alguna pieza imprescindible (Required), NO se cambia nada: la
--     nave sigue siendo la de piezas (el respaldo de ShipModel). Nunca lanza error.
--   * Si carga, las naves que ya estaban hechas con piezas (la de exposición del puerto, la de la arena…)
--     se cambian por la de malla (ShipModel.upgrade), sin tocar a quien va sentado.
--
--   NaveLoader.hasIds(ids) -> boolean
--   NaveLoader.prepare(ids, download) -> (Folder?, string)   (puro salvo download: lo prueban los tests)
--   NaveLoader.start() -> boolean

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NaveLoader = {}

NaveLoader.Required = { "Fuselaje", "Alas", "Motores", "Cabina" }
NaveLoader.Status = "sin empezar"

local function shipModel()
	return require(ReplicatedStorage.Shared.AirCombat.ShipModel)
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

function NaveLoader.hasIds(ids: any): boolean
	if type(ids) ~= "table" then
		return false
	end
	if idOf(ids.Completa) then
		return true
	end
	for _ in ids.Piezas or {} do
		return true
	end
	return false
end

local function firstMeshPart(inst: Instance?, name: string?): BasePart?
	if not inst then
		return nil
	end
	if name then
		local named = inst:FindFirstChild(name, true)
		if named and named:IsA("MeshPart") then
			return named
		end
		return nil
	end
	if inst:IsA("MeshPart") then
		return inst
	end
	return inst:FindFirstChildWhichIsA("MeshPart", true)
end

local function enumMaterial(name: string): Enum.Material
	local ok, m = pcall(function()
		return (Enum.Material :: any)[name]
	end)
	return if ok and m then m else Enum.Material.Metal
end

-- Material, color y texturas de una pieza
local function dress(part: BasePart, piece: any, textures: { [string]: string })
	part.Material = enumMaterial(piece.Material)
	if piece.Color then
		part.Color = piece.Color
	end
	if piece.Material == "Glass" then
		part.Transparency = 0.35
		part.Reflectance = 0.12
	end
	pcall(function()
		(part :: any).RenderFidelity = Enum.RenderFidelity.Automatic
	end)
	local set = piece.Set
	if not set or part:FindFirstChildOfClass("SurfaceAppearance") then
		return
	end
	local color = textures[set .. "_color"]
	if not color then
		return
	end
	local okSA = pcall(function()
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
	if not okSA then
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

-- Prepara la plantilla (una Folder con una MeshPart por pieza, con su nombre, material y texturas).
-- download(id) -> Instance? (World/AssetLoader.download en el juego; un doble en las pruebas).
function NaveLoader.prepare(ids: any, download: (number) -> Instance?): (Folder?, string)
	if not NaveLoader.hasIds(ids) then
		return nil, "sin ids (scripts/upload-nave.sh no se ha lanzado todavía)"
	end
	local plan = shipModel().meshPlan()
	local folder = Instance.new("Folder")
	folder.Name = "NaveMallaPlantilla"
	local found: { [string]: boolean } = {}
	local full = idOf(ids.Completa)
	if full then
		local ok, model = pcall(download, full)
		if ok and model then
			for _, piece in plan do
				local mp = firstMeshPart(model, piece.Name)
				if mp then
					local c = mp:Clone()
					c.Name = piece.Name
					c.Parent = folder
					found[piece.Name] = true
				end
			end
		end
	end
	for _, piece in plan do
		-- (por el nombre con que se subió: Asset —«Fuselaje2», la generación sin cápsulas lisas,
		-- docs/bugs/moderacion/— así un id viejo nunca se monta con la geometría nueva)
		local id = idOf((ids.Piezas or {})[piece.Asset or piece.Name])
		if not found[piece.Name] and id then
			local ok, model = pcall(download, id)
			local mp = ok and firstMeshPart(model) or nil
			if mp then
				local c = mp:Clone()
				c.Name = piece.Name
				for _, d in c:GetChildren() do
					if not d:IsA("SurfaceAppearance") then
						d:Destroy()
					end
				end
				c.Parent = folder
				found[piece.Name] = true
			end
		end
	end
	local missing = {}
	for _, name in NaveLoader.Required do
		if not found[name] then
			table.insert(missing, name)
		end
	end
	if #missing > 0 then
		folder:Destroy()
		return nil, "faltan piezas: " .. table.concat(missing, ", ")
	end
	for _, piece in plan do
		local part = folder:FindFirstChild(piece.Name)
		if part and part:IsA("BasePart") then
			dress(part, piece, ids.Texturas or {})
		end
	end
	return folder, "ok"
end

function NaveLoader.start(): boolean
	local ok, result = pcall(function()
		local ids = require(ReplicatedStorage.Shared.AirCombat.NaveAssetIds)
		if not NaveLoader.hasIds(ids) then
			NaveLoader.Status = "respaldo: sin ids"
			return false
		end
		local AssetLoader = require(script.Parent.AssetLoader)
		local folder, why = NaveLoader.prepare(ids, AssetLoader.download)
		if not folder then
			NaveLoader.Status = "respaldo: " .. why
			warn("[Nave] la nave realista no se ha podido cargar (" .. why .. "): sigue la de piezas")
			return false
		end
		folder.Parent = game:GetService("ServerStorage")
		local ShipModel = shipModel()
		ShipModel.setMeshTemplate(folder)
		NaveLoader.Status = "malla"
		local n = 0
		for _, m in game:GetService("CollectionService"):GetTagged("NavePiezas") do
			if m:IsA("Model") and m.Parent and ShipModel.upgrade(m) then
				n += 1
			end
		end
		print(("[Nave] nave realista cargada (%d naves cambiadas)"):format(n))
		return true
	end)
	if not ok then
		NaveLoader.Status = "respaldo: " .. tostring(result)
		warn("[Nave] " .. tostring(result))
		return false
	end
	return result == true
end

return NaveLoader
