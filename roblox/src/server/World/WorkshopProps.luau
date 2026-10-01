-- WorkshopProps: el «Realistic Autoservice Props Pack» (130967743753364, NyrexBLX) dentro de los
-- talleres mecánicos. Es de la 4ª tanda de Sebastián y salió limpio en la revisión
-- (docs/assets-usuario-4.md): 103 MeshPart, casi todas con SurfaceAppearance (PBR), sin scripts.
--
--   * Al arrancar el servidor (Main, en un hilo aparte) carga el pack una vez con
--     AssetService:LoadAssetAsync. Por seguridad SOLO se copian MeshPart y SurfaceAppearance (todo lo
--     demás se tira) y, si el pack trajera alguna marca de los virus de la 4ª tanda (scripts,
--     NumberPose, PlaneConstraint, atributos), no se usa nada.
--   * El pack viene con las piezas sueltas («Autoservice Props Pack-Engine Crane.006»…): se agrupan
--     por nombre (sin el número final ni «_chunkN») y por cercanía, y cada grupo es un objeto. Las
--     plantillas quedan en ServerStorage.WorkshopProps (no se replica).
--   * Cada vez que se monta la sala de un taller (World/Interiors.Taller, Model «Interior_Taller» en
--     workspace.Interiores) se le ponen copias en sitios fijos que la sala deja libres: grúa de motor,
--     gato de caja de cambios, desmontadora de ruedas, caballetes, foco con trípode, recogedor de
--     aceite y camilla. No se quita nada de lo que ya hay.
--   * Si la carga falla, los talleres se quedan como estaban.

local WorkshopProps = {}

WorkshopProps.AssetId = 130967743753364
WorkshopProps.Prefix = "Autoservice Props Pack-"

-- Dónde va cada cosa en la sala del taller (50 × 40; x de -25 a 25, z de -20 a 20, la puerta en
-- z = -20). Huecos libres según World/Interiors.Taller: el elevador con el coche ocupa x -15..-5,
-- la pared de herramientas x > 21, los bidones y el compresor el fondo (z > 16), el mostrador z < -12.
-- Kind: nombre del objeto en el pack (sin número); Pick: el n-ésimo más grande de ese nombre.
WorkshopProps.Slots = {
	{ Kind = "Engine Crane", X = 12, Z = 6, Yaw = -90 },
	{ Kind = "Transmission Jack", X = 14, Z = -6, Yaw = 0 },
	{ Kind = "...r Machine", X = 16, Z = 15, Yaw = 180 }, -- desmontadora de ruedas (nombre cortado en el pack)
	{ Kind = "Steel Jack Stand", Pick = 1, X = -17, Z = 13, Yaw = 0 },
	{ Kind = "Steel Jack Stand", Pick = 2, X = -14.5, Z = 13, Yaw = 20 },
	{ Kind = "Work Light Stand", X = -19.5, Z = -0.5, Yaw = 45 },
	{ Kind = "Oil Collector", X = -3.5, Z = -6, Yaw = 0 },
	{ Kind = "Car Creeper", X = -10, Z = -8, Yaw = 10 },
}

-- Nombre del objeto sin el prefijo del pack ni los números/trozos del final:
-- "Autoservice Props Pack-Steel Jack Stand001.001" -> "Steel Jack Stand"
-- "Autoservice Props Pack-Generator_chunk1_1"       -> "Generator"
function WorkshopProps.baseName(name: string): string
	local s = name
	if string.sub(s, 1, #WorkshopProps.Prefix) == WorkshopProps.Prefix then
		s = string.sub(s, #WorkshopProps.Prefix + 1)
	end
	-- (de uno en uno y vuelta a empezar: "Generator_chunk1_1" -> "Generator_chunk1" -> "Generator")
	local patterns = { { "%.%d+$", "" }, { "_chunk%d+$", "" }, { "_%d+$", "" }, { "(%a)%d+$", "%1" } }
	local changed = true
	while changed do
		changed = false
		for _, p in patterns do
			local after, n = string.gsub(s, p[1], p[2])
			if n > 0 then
				s = after
				changed = true
				break
			end
		end
	end
	return s
end

-- Lo que hace sospechar de un pack (marcas de los virus de la 4ª tanda)
local SUSPICIOUS = { Script = true, LocalScript = true, ModuleScript = true, NumberPose = true, PlaneConstraint = true }

function WorkshopProps.isSuspicious(root: Instance): (boolean, string?)
	for _, d in root:GetDescendants() do
		if SUSPICIOUS[d.ClassName] then
			return true, d.ClassName .. " " .. d:GetFullName()
		end
		local ok, attributes = pcall(d.GetAttributes, d)
		if ok and next(attributes) ~= nil then
			return true, "atributos en " .. d:GetFullName()
		end
	end
	return false, nil
end

-- Caja alineada con los ejes de unas piezas (teniendo en cuenta su giro)
local function bounds(list: { BasePart }): (Vector3, Vector3)
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	for _, p in list do
		local cf, s = p.CFrame, p.Size / 2
		local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
		local e = Vector3.new(
			math.abs(r.X) * s.X + math.abs(u.X) * s.Y + math.abs(l.X) * s.Z,
			math.abs(r.Y) * s.X + math.abs(u.Y) * s.Y + math.abs(l.Y) * s.Z,
			math.abs(r.Z) * s.X + math.abs(u.Z) * s.Y + math.abs(l.Z) * s.Z
		)
		local c = cf.Position
		lo = Vector3.new(math.min(lo.X, c.X - e.X), math.min(lo.Y, c.Y - e.Y), math.min(lo.Z, c.Z - e.Z))
		hi = Vector3.new(math.max(hi.X, c.X + e.X), math.max(hi.Y, c.Y + e.Y), math.max(hi.Z, c.Z + e.Z))
	end
	return lo, hi
end

local TOUCH = 0.3 -- dos piezas del mismo nombre a menos de esto son el mismo objeto

local function near(aLo: Vector3, aHi: Vector3, bLo: Vector3, bHi: Vector3): boolean
	return aLo.X - TOUCH <= bHi.X and bLo.X - TOUCH <= aHi.X
		and aLo.Y - TOUCH <= bHi.Y and bLo.Y - TOUCH <= aHi.Y
		and aLo.Z - TOUCH <= bHi.Z and bLo.Z - TOUCH <= aHi.Z
end

-- Agrupa las MeshPart del pack en objetos: { [nombre] = { {piezas}, ... } } (de mayor a menor)
local function cluster(meshes: { MeshPart }): { [string]: { { MeshPart } } }
	local byName: { [string]: { MeshPart } } = {}
	for _, m in meshes do
		local base = WorkshopProps.baseName(m.Name)
		byName[base] = byName[base] or {}
		table.insert(byName[base], m)
	end
	local result = {}
	for base, list in byName do
		local groups: { { MeshPart } } = {}
		local boxes: { { Vector3 } } = {}
		for _, m in list do
			local lo, hi = bounds({ m })
			-- se une a todos los grupos que toca (y esos grupos entre sí)
			local merged: { MeshPart } = { m }
			local mLo, mHi = lo, hi
			for i = #groups, 1, -1 do
				if near(mLo, mHi, boxes[i][1], boxes[i][2]) then
					for _, p in groups[i] do
						table.insert(merged, p)
					end
					mLo = mLo:Min(boxes[i][1])
					mHi = mHi:Max(boxes[i][2])
					table.remove(groups, i)
					table.remove(boxes, i)
				end
			end
			table.insert(groups, merged)
			table.insert(boxes, { mLo, mHi })
		end
		local volume = {}
		for i, g in groups do
			local s = boxes[i][2] - boxes[i][1]
			volume[g] = s.X * s.Y * s.Z
		end
		table.sort(groups, function(a, b)
			return volume[a] > volume[b]
		end)
		result[base] = groups
	end
	return result
end

-- Copia limpia de un objeto: solo MeshPart (con su SurfaceAppearance), anclado y con el pivote en el
-- centro de la base (así PivotTo lo deja apoyado en el suelo)
local function template(name: string, group: { MeshPart }): Model
	local model = Instance.new("Model")
	model.Name = name
	local lo, hi = bounds(group)
	for _, m in group do
		-- (MeshId no se puede escribir desde un script: se clona y se quitan los hijos que no valen)
		local clone = m:Clone()
		for _, child in clone:GetChildren() do
			if not child:IsA("SurfaceAppearance") then
				child:Destroy()
			end
		end
		clone.Anchored = true
		local big = math.max(clone.Size.X, clone.Size.Y, clone.Size.Z) >= 2
		clone.CanCollide = big
		clone.CanQuery = big
		clone.CanTouch = false
		clone.CastShadow = big
		clone.Parent = model
	end
	model.WorldPivot = CFrame.new((lo.X + hi.X) / 2, lo.Y, (lo.Z + hi.Z) / 2)
	return model
end

-- Plantillas: { [nombre] = { Model, ... } } (de mayor a menor)
function WorkshopProps.templates(pack: Instance): { [string]: { Model } }
	local meshes: { MeshPart } = {}
	for _, d in pack:GetDescendants() do
		if d:IsA("MeshPart") then
			table.insert(meshes, d)
		end
	end
	local out = {}
	for base, groups in cluster(meshes) do
		out[base] = {}
		for i, g in groups do
			table.insert(out[base], template(base .. (if i > 1 then " " .. i else ""), g))
		end
	end
	return out
end

-- Pone los objetos en una sala de taller (Model «Interior_Taller»). Devuelve cuántos.
function WorkshopProps.dress(room: Model, library: { [string]: { Model } }): number
	local floor = room:FindFirstChild("Floor")
	if not (floor and floor:IsA("BasePart")) or room:FindFirstChild("WorkshopProps") then
		return 0
	end
	-- (el suelo de la sala está en r.at(0, -0.5, 0): su cara de arriba es el y = 0 de la sala)
	local origin = floor.CFrame * CFrame.new(0, floor.Size.Y / 2, 0)
	local folder = Instance.new("Model")
	folder.Name = "WorkshopProps"
	local n = 0
	for _, slot in WorkshopProps.Slots do
		local list = library[slot.Kind]
		local source = list and list[slot.Pick or 1]
		if source then
			local copy = source:Clone()
			copy:PivotTo(origin * CFrame.new(slot.X, 0, slot.Z) * CFrame.Angles(0, math.rad(slot.Yaw), 0))
			copy.Parent = folder
			n += 1
		end
	end
	folder.Parent = room
	return n
end

local function download(id: number): Instance?
	local ok, result = pcall(function()
		return (game:GetService("AssetService") :: any):LoadAssetAsync(id)
	end)
	if ok and result then
		return result
	end
	warn(("[WorkshopProps] no carga %d: %s"):format(id, tostring(result)))
	return nil
end

function WorkshopProps.start()
	local pack = download(WorkshopProps.AssetId)
	if not pack then
		return
	end
	local bad, why = WorkshopProps.isSuspicious(pack)
	if bad then
		warn("[WorkshopProps] el pack trae algo raro, no se usa: " .. tostring(why))
		pack:Destroy()
		return
	end
	local library = WorkshopProps.templates(pack)
	pack:Destroy()
	-- Guardadas en ServerStorage (solo para verlas en Studio; se usan desde «library»)
	local store = Instance.new("Folder")
	store.Name = "WorkshopProps"
	local kinds = 0
	for _, list in library do
		kinds += 1
		for _, model in list do
			model.Parent = store
		end
	end
	store.Parent = game:GetService("ServerStorage")

	local rooms = workspace:WaitForChild("Interiores", 300)
	if not rooms then
		warn("[WorkshopProps] no hay workspace.Interiores")
		return
	end
	local function onRoom(child: Instance)
		if child.Name == "Interior_Taller" and child:IsA("Model") then
			-- (la sala se mete en la carpeta antes de amueblarla: se espera a que termine)
			task.defer(function()
				local ok, err = pcall(WorkshopProps.dress, child, library)
				if not ok then
					warn("[WorkshopProps] " .. tostring(err))
				end
			end)
		end
	end
	rooms.ChildAdded:Connect(onRoom)
	for _, child in rooms:GetChildren() do
		onRoom(child)
	end
	print(("[WorkshopProps] %d tipos de objeto del taller listos"):format(kinds))
end

return WorkshopProps
