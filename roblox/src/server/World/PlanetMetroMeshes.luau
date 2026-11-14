-- PlanetMetroMeshes (servidor): pone los MONUMENTOS hechos con Blender (scripts/planetas/monumentos_blender.py,
-- subidos con scripts/upload-planetas.sh → shared/Cosmos/MetroAssetIds) en lugar de los de piezas que dibuja
-- World/PlanetMetroBuilder. Cada monumento es un Model con una MeshPart por material (<Kind>_Cuerpo, _Cristal,
-- _Luz, _Metal, _Roca, _Agua, _Hoja, _Tronco): aquí se les pone el material y el color de su planeta.
--
--   * Sin id, o si algo falla al descargar, NO cambia nada: se queda el monumento de piezas (se ve bien igual).
--   * Del de piezas se quedan la explanada (o la plataforma), el rótulo y el haz de luz hacia el cielo; lo demás
--     se quita cuando la malla ya está puesta.
--   * La malla se coloca con su centro y tamaño de shared/Cosmos/MonumentoMalla (studs desde el centro de la
--     base; el frente mira hacia el barrio) y, si Roblox la importó a otra escala, se reescala.

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlanetMetroMeshes = {}

local KEEP = { Explanada = true, Plataforma = true, Circulo = true, Circulo2 = true, Rotulo = true, PieRotulo = true, Haz = true }

local function ids(): { [string]: any }
	local ok, mod = pcall(function()
		return require(ReplicatedStorage.Shared.Cosmos.MetroAssetIds)
	end)
	return if ok and type(mod) == "table" then mod else {}
end

local function shapes(): { [string]: any }
	local ok, mod = pcall(function()
		return require(ReplicatedStorage.Shared.Cosmos.MonumentoMalla)
	end)
	return if ok and type(mod) == "table" then mod else {}
end

function PlanetMetroMeshes.idOf(value: any): number?
	if type(value) ~= "string" and type(value) ~= "number" then
		return nil
	end
	local n = tonumber(string.match(tostring(value), "(%d+)%s*$") or "")
	return if n and n > 0 then n else nil
end

function PlanetMetroMeshes.hasMesh(kind: string): boolean
	local list = ids().Mallas
	return type(list) == "table" and PlanetMetroMeshes.idOf(list[kind]) ~= nil
end

-- El material y el color de cada malla según su grupo y el planeta (L: MetroStyles.Look)
function PlanetMetroMeshes.styleOf(group: string, L: { [string]: any }): (Enum.Material, Color3, number)
	local function mat(name: string?, fallback: Enum.Material): Enum.Material
		local ok, m = pcall(function()
			return (Enum.Material :: any)[name or ""]
		end)
		return if ok and m then m else fallback
	end
	if group == "Cuerpo" then
		return mat(L.WallMaterial, Enum.Material.Concrete), L.Walls[1], 0
	elseif group == "Cristal" then
		return Enum.Material.Glass, L.Window, 0.3
	elseif group == "Luz" then
		return Enum.Material.Neon, L.Strip or L.Glow, 0
	elseif group == "Metal" then
		return Enum.Material.Metal, L.Trim, 0
	elseif group == "Roca" then
		return Enum.Material.Slate, L.Ground, 0
	elseif group == "Agua" then
		return Enum.Material.Glass, Color3.fromRGB(170, 225, 255), 0.25
	elseif group == "Hoja" then
		return Enum.Material.Grass, L.Leaf, 0
	elseif group == "Tronco" then
		return Enum.Material.Wood, L.Trunk, 0
	end
	return Enum.Material.SmoothPlastic, L.Walls[1], 0
end

-- Pone la malla del monumento `kind` en el sitio de `fallback` (el de piezas). cf: centro de la base, mirando
-- hacia el barrio. Va en un hilo: la descarga tarda.
function PlanetMetroMeshes.apply(fallback: Model, kind: string, L: { [string]: any }, cf: CFrame)
	local id = PlanetMetroMeshes.idOf((ids().Mallas or {})[kind])
	if not id then
		return false
	end
	task.spawn(function()
		local ok, asset = pcall(function()
			return InsertService:LoadAsset(id)
		end)
		if not ok or not asset then
			warn("[PlanetMetroMeshes] no se pudo cargar " .. kind .. ": " .. tostring(asset))
			return
		end
		local parts: { MeshPart } = {}
		for _, d in asset:GetDescendants() do
			if d:IsA("MeshPart") then
				table.insert(parts, d)
			end
		end
		if #parts == 0 or not fallback.Parent then
			asset:Destroy()
			return
		end
		local model = Instance.new("Model")
		model.Name = "MonumentoMalla_" .. kind
		for _, p in parts do
			p.Parent = model
		end
		asset:Destroy()
		-- escala: la de Blender (studs); si Roblox la importó a otra, se corrige con la altura
		local info = shapes()[kind]
		local _, size = model:GetBoundingBox()
		if info and info.Size and size.Y > 0.01 then
			local k = info.Size.Y / size.Y
			if math.abs(k - 1) > 0.02 then
				pcall(function()
					model:ScaleTo(k)
				end)
			end
		end
		-- sitio: el centro de su caja, donde dice el manifiesto respecto a la base (y con el giro del monumento)
		local bb = model:GetBoundingBox()
		local center = if info and info.Center then info.Center else Vector3.new(0, size.Y / 2, 0)
		local target = cf * CFrame.new(center)
		local origin = CFrame.new(bb.Position)
		for _, p in parts do
			local group = string.match(p.Name, "_(%a+)$") or p.Name
			local material, color, transp = PlanetMetroMeshes.styleOf(group, L)
			p.Anchored = true
			p.Material = material
			p.Color = color
			p.Transparency = transp
			p.CanCollide = group == "Cuerpo" or group == "Metal" or group == "Roca" or group == "Tronco"
			p.CanTouch = false
			p.CanQuery = p.CanCollide
			p.CastShadow = group ~= "Luz" and group ~= "Agua"
			p.CFrame = target * origin:ToObjectSpace(p.CFrame)
			if group == "Luz" then
				local light = Instance.new("PointLight")
				light.Color = color
				light.Range = 40
				light.Brightness = 1.5
				light.Shadows = false
				light.Parent = p
			end
		end
		pcall(function()
			(model :: any).ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		end)
		model.Parent = fallback
		-- fuera lo de piezas (menos la explanada, el rótulo y el haz de luz)
		for _, child in fallback:GetChildren() do
			if child ~= model and child:IsA("BasePart") and not KEEP[child.Name] then
				child:Destroy()
			end
		end
		fallback:SetAttribute("Malla", true)
	end)
	return true
end

return PlanetMetroMeshes
