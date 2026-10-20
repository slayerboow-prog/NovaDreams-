-- PuertoMeshes: pone las mallas de Blender del Puerto de Valmar (grúa pórtico, contenedores, tetrápodo y
-- bolardo; shared/Port/PuertoAssetIds, subidas con scripts/upload-puerto.sh) en lugar de las piezas.
--
-- Cada objeto «estrella» del puerto lleva la etiqueta PuertoMalla y su Kind (Kit/PuertoKit). Si hay id
-- para ese Kind, se descarga la malla una vez, se copia ajustada a la caja del objeto y se esconden las
-- piezas que hacía de respaldo (las colisiones se quedan: se sigue pisando y chocando igual). Sin ids,
-- o si algo falla, NO cambia nada (el puerto de piezas se ve bien igual).
--
--   PuertoMeshes.hasIds(ids)                    ¿hay alguna malla subida?
--   PuertoMeshes.placement(target, info)        dónde va la malla de un objeto (puro: lo usan las pruebas)
--   PuertoMeshes.apply(target, template, info)  pone una malla en un objeto
--   PuertoMeshes.start()                        en un hilo: descarga y aplica a todo el puerto

local CollectionService = game:GetService("CollectionService")

local PuertoMeshes = {}
PuertoMeshes.Status = "sin empezar"

-- Lo que NO se esconde de la grúa (lo que se mueve o brilla: no va en la malla)
local KEEP = { Foco = true, Baliza = true, Contenedor = true, ContenedorMarco = true, ContenedorCodigo = true, Cable = true, Spreader = true, Cabina = true, Carro = true }

local function idOf(value: any): number?
	if type(value) ~= "string" and type(value) ~= "number" then
		return nil
	end
	local n = tonumber(string.match(tostring(value), "(%d+)%s*$") or "")
	return if n and n > 0 then n else nil
end
PuertoMeshes.idOf = idOf

function PuertoMeshes.hasIds(ids: any): boolean
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

-- La caja del objeto (Model o pieza)
local function boxOf(target: Instance): (CFrame?, Vector3?)
	if target:IsA("Model") then
		local ok, cf, size = pcall(function()
			return (target :: Model):GetBoundingBox()
		end)
		if ok then
			return cf, size
		end
	elseif target:IsA("BasePart") then
		return target.CFrame, target.Size
	end
	return nil, nil
end

-- Dónde va la malla de cada objeto: (CFrame, tamaño). info = shared/Port/PuertoMalla[Kind] (centro y tamaño
-- de la malla respecto a su pivote, lo escribe scripts/puerto/puerto_blender.py); sin info, la caja del objeto.
function PuertoMeshes.placement(target: Instance, info: any?): (CFrame?, Vector3?)
	local kind = target:GetAttribute("Kind")
	if info then
		if kind == "GruaSTS" then
			local pivot = target:GetAttribute("Pivot")
			if typeof(pivot) == "Vector3" then
				return CFrame.new(pivot + info.Center), info.Size
			end
		elseif kind == "Tetrapodo" then
			local center, turn, size = target:GetAttribute("Centro"), target:GetAttribute("Giro"), target:GetAttribute("Size")
			if typeof(center) == "Vector3" and typeof(turn) == "Vector3" and type(size) == "number" then
				local k = size / 7
				return CFrame.new(center) * CFrame.Angles(turn.X, turn.Y, turn.Z) * CFrame.new(info.Center * k), info.Size * k
			end
		elseif kind == "Bolardo" and target:IsA("BasePart") then
			local foot = target.Position - Vector3.new(0, target.Size.X / 2, 0) -- (cilindro de pie: su eje X es la altura)
			return CFrame.new(foot + info.Center), info.Size
		elseif target:IsA("BasePart") then
			return target.CFrame, info.Size -- contenedor: centrado en la pieza
		end
	end
	return boxOf(target)
end

-- Pone la malla (una MeshPart de plantilla) sobre el objeto y esconde las piezas de respaldo
function PuertoMeshes.apply(target: Instance, template: MeshPart, info: any?): MeshPart?
	local cf, size = PuertoMeshes.placement(target, info)
	if not cf or not size then
		return nil
	end
	local mesh = template:Clone()
	mesh.Name = "Malla"
	mesh.Anchored = true
	mesh.CanCollide = false
	mesh.CanQuery = false
	mesh.CanTouch = false
	mesh.Size = size
	mesh.CFrame = cf
	local kind = target:GetAttribute("Kind")
	if target:IsA("BasePart") then
		-- Contenedor o bolardo: la pieza manda en el color
		mesh.Color = target.Color
		mesh.Parent = target.Parent
		target.Transparency = 1
	else
		mesh.Parent = target
		for _, d in target:GetDescendants() do
			if d:IsA("BasePart") and d ~= mesh and not (kind == "GruaSTS" and KEEP[d.Name]) then
				d.Transparency = 1
			end
		end
	end
	return mesh
end

function PuertoMeshes.start()
	local ok, ids = pcall(function()
		return require(game:GetService("ReplicatedStorage").Shared.Port.PuertoAssetIds)
	end)
	if not ok or not PuertoMeshes.hasIds(ids) then
		PuertoMeshes.Status = "sin ids (scripts/upload-puerto.sh no se ha lanzado todavía): puerto de piezas"
		return
	end
	local InsertService = game:GetService("InsertService")
	local templates: { [string]: MeshPart } = {}
	for kind, value in ids.Mallas do
		local id = idOf(value)
		if id then
			local got, model = pcall(function()
				return InsertService:LoadAsset(id)
			end)
			local mp = got and model and model:FindFirstChildWhichIsA("MeshPart", true)
			if mp then
				templates[kind] = mp
			else
				warn("[PuertoMeshes] no se pudo cargar la malla " .. kind)
			end
		end
	end
	local okInfo, infos = pcall(function()
		return require(game:GetService("ReplicatedStorage").Shared.Port.PuertoMalla)
	end)
	local n = 0
	for _, target in CollectionService:GetTagged("PuertoMalla") do
		local kind = target:GetAttribute("Kind") or ""
		local template = templates[kind]
		if template and PuertoMeshes.apply(target, template, if okInfo then infos[kind] else nil) then
			n += 1
		end
	end
	PuertoMeshes.Status = ("%d objetos con malla"):format(n)
end

return PuertoMeshes
