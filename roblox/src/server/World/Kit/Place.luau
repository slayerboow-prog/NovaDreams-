-- Place: utilidades para colocar, escalar y limpiar modelos importados.
-- Se implementan a mano (sin PivotTo/ScaleTo) para que funcionen igual en Roblox
-- y en Lune, que es la herramienta que mete la ciudad dentro del archivo del juego.

local Place = {}

local function parts(model: Instance): { BasePart }
	local list = {}
	if model:IsA("BasePart") then
		table.insert(list, model)
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(list, d)
		end
	end
	return list
end

-- Caja envolvente alineada con los ejes del mundo: devuelve mínimo y máximo
function Place.bounds(model: Instance): (Vector3, Vector3)
	local minV = Vector3.new(math.huge, math.huge, math.huge)
	local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, p in parts(model) do
		local cf, half = p.CFrame, p.Size / 2
		for _, sx in { -1, 1 } do
			for _, sy in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local corner = (cf * CFrame.new(half.X * sx, half.Y * sy, half.Z * sz)).Position
					minV = Vector3.new(math.min(minV.X, corner.X), math.min(minV.Y, corner.Y), math.min(minV.Z, corner.Z))
					maxV = Vector3.new(math.max(maxV.X, corner.X), math.max(maxV.Y, corner.Y), math.max(maxV.Z, corner.Z))
				end
			end
		end
	end
	return minV, maxV
end

-- Quita scripts (seguridad), ancla todo y desactiva colisiones costosas en detalles pequeños
function Place.sanitize(model: Instance)
	for _, d in model:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanTouch = false
			if d.Size.Magnitude < 2 then
				d.CanCollide = false
				d.CanQuery = false
			end
		end
	end
end

-- Escala un modelo alrededor de un punto
function Place.scale(model: Instance, factor: number, around: Vector3)
	if math.abs(factor - 1) < 1e-3 then
		return
	end
	for _, p in parts(model) do
		local cf = p.CFrame
		local offset = cf.Position - around
		p.Size *= factor
		p.CFrame = CFrame.new(around + offset * factor) * (cf - cf.Position)
	end
	for _, d in model:GetDescendants() do
		if d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
			d.Range *= factor
		elseif d:IsA("SpecialMesh") then
			-- En las piezas con malla especial el tamaño visible lo da Scale, no Size
			d.Scale *= factor
			d.Offset *= factor
		end
	end
end

-- Mueve el modelo para que el centro de su base quede en "target" (orientado como target).
-- yaw: giro extra (radianes) para corregir modelos cuyo "frente" no mira a -Z.
function Place.put(model: Instance, target: CFrame, yaw: number?)
	local minV, maxV = Place.bounds(model)
	local base = CFrame.new((minV.X + maxV.X) / 2, minV.Y, (minV.Z + maxV.Z) / 2)
	local transform = target * CFrame.Angles(0, yaw or 0, 0) * base:Inverse()
	for _, p in parts(model) do
		p.CFrame = transform * p.CFrame
	end
end

-- Tamaño del modelo (ancho X, alto Y, fondo Z) según su caja envolvente
function Place.size(model: Instance): Vector3
	local minV, maxV = Place.bounds(model)
	return maxV - minV
end

return Place
