-- Polish: repaso final de la ciudad para quitar parpadeos ("z-fighting").
--
-- Cuando dos piezas de distinto color o material tienen una cara exactamente en el mismo plano
-- (una moldura pegada a una pared, un bordillo contra la acera, una cristalera en la fachada…),
-- Roblox no sabe cuál dibujar delante y la superficie parpadea al mover la cámara.
-- Aquí se buscan esas parejas y la pieza más pequeña crece un poquito (0,03 studs por cada lado)
-- en ese eje, para que su cara quede delante y deje de parpadear. No se nota a simple vista.

local Polish = {}

local GROW = 0.06 -- total en el eje (0,03 por cada lado)
local EPS = 0.02 -- dos caras a menos de esto se consideran el mismo plano
local CELL = 40 -- tamaño de las celdas para buscar parejas cercanas

type Face = { Part: BasePart, A: number, U0: number, U1: number, V0: number, V1: number }

-- Caja alineada con los ejes de una pieza (solo si no está girada en ángulos raros)
local function box(part: BasePart): (Vector3?, Vector3?)
	local c = { part.CFrame:GetComponents() }
	for i = 4, 12 do
		local v = math.abs(c[i])
		if v > 1e-3 and math.abs(v - 1) > 1e-3 then
			return nil, nil
		end
	end
	local s = part.Size
	local hx = (math.abs(c[4]) * s.X + math.abs(c[5]) * s.Y + math.abs(c[6]) * s.Z) / 2
	local hy = (math.abs(c[7]) * s.X + math.abs(c[8]) * s.Y + math.abs(c[9]) * s.Z) / 2
	local hz = (math.abs(c[10]) * s.X + math.abs(c[11]) * s.Y + math.abs(c[12]) * s.Z) / 2
	return Vector3.new(c[1] - hx, c[2] - hy, c[3] - hz), Vector3.new(c[1] + hx, c[2] + hy, c[3] + hz)
end

local function axisValue(v: Vector3, axis: number): number
	return if axis == 1 then v.X elseif axis == 2 then v.Y else v.Z
end

-- Eje local de la pieza que corresponde al eje del mundo "axis"
local function localAxis(part: BasePart, axis: number): number
	local c = { part.CFrame:GetComponents() }
	local row = 3 + (axis - 1) * 3
	for j = 1, 3 do
		if math.abs(c[row + j]) > 0.5 then
			return j
		end
	end
	return axis
end

local function differs(a: BasePart, b: BasePart): boolean
	return a.Material ~= b.Material or a.Color ~= b.Color or a.Transparency ~= b.Transparency
end

function Polish.fixCoplanar(root: Instance): number
	-- Agrupa las caras por plano: (eje, sentido, posición redondeada)
	local planes: { [string]: { Face } } = {}
	for _, part in root:GetDescendants() do
		if part:IsA("Part") and part.Shape == Enum.PartType.Block and part.Transparency < 0.95 then
			local lo, hi = box(part)
			if lo and hi then
				for axis = 1, 3 do
					local u = if axis == 1 then 2 else 1
					local v = if axis == 3 then 2 else 3
					for side = -1, 1, 2 do
						local at = axisValue(if side < 0 then lo else hi, axis)
						local key = axis .. ":" .. side .. ":" .. math.floor(at / EPS + 0.5)
						local list = planes[key]
						if not list then
							list = {}
							planes[key] = list
						end
						table.insert(list, {
							Part = part,
							A = axis,
							U0 = axisValue(lo, u),
							U1 = axisValue(hi, u),
							V0 = axisValue(lo, v),
							V1 = axisValue(hi, v),
						})
					end
				end
			end
		end
	end

	-- Busca parejas que se solapan y decide qué pieza crece (la de menor volumen)
	local grow: { [BasePart]: { [number]: boolean } } = {}
	for _, list in planes do
		if #list > 1 then
			local grid: { [string]: { Face } } = {}
			for _, f in list do
				for gu = math.floor(f.U0 / CELL), math.floor(f.U1 / CELL) do
					for gv = math.floor(f.V0 / CELL), math.floor(f.V1 / CELL) do
						local k = gu .. ":" .. gv
						grid[k] = grid[k] or {}
						table.insert(grid[k], f)
					end
				end
			end
			for _, cell in grid do
				for i = 1, #cell - 1 do
					local a = cell[i]
					for j = i + 1, #cell do
						local b = cell[j]
						local w = math.min(a.U1, b.U1) - math.max(a.U0, b.U0)
						local h = math.min(a.V1, b.V1) - math.max(a.V0, b.V0)
						if w > 0.05 and h > 0.05 and differs(a.Part, b.Part) then
							local sa, sb = a.Part.Size, b.Part.Size
							local small = if sa.X * sa.Y * sa.Z <= sb.X * sb.Y * sb.Z then a.Part else b.Part
							grow[small] = grow[small] or {}
							grow[small][a.A] = true
						end
					end
				end
			end
		end
	end

	local count = 0
	for part, axes in grow do
		local size = part.Size
		for axis in axes do
			local l = localAxis(part, axis)
			size += if l == 1 then Vector3.new(GROW, 0, 0) elseif l == 2 then Vector3.new(0, GROW, 0) else Vector3.new(0, 0, GROW)
		end
		part.Size = size
		count += 1
	end
	return count
end

-- Ajustes de rendimiento que no se notan a la vista:
--   * CanTouch = false en todas las piezas: ningún script usa .Touched en el mapa, y así el motor
--     no calcula contactos para 95.000 piezas.
--   * Sin sombra en las piezas diminutas (menos de 2 studs en todas sus medidas): su sombra no se aprecia.
--   * Sin sombra en lo que está plano en el suelo (carreteras, aceras, césped, pasos de cebra…):
--     solo la echarían sobre el suelo de debajo, donde no se ve. Son decenas de miles de piezas.
--   * Sin sombra en lo invisible (zonas, marcas, huecos de puertas).
--   * Los carteles con texto (SurfaceGui) solo se dibujan cerca: de lejos no se leen y cuestan
--     mucho en el móvil.
local SIGN_DISTANCE = 220
function Polish.optimize(root: Instance): (number, number)
	local touch, shadows = 0, 0
	for _, part in root:GetDescendants() do
		if part:IsA("BasePart") then
			if part.CanTouch and not part:IsA("Seat") and not part:IsA("VehicleSeat") then
				part.CanTouch = false
				touch += 1
			end
			if part.CastShadow then
				local s = part.Size
				local off = math.max(s.X, s.Y, s.Z) < 2 or part.Transparency >= 0.9
				if not off then
					local lo, hi = box(part)
					off = lo ~= nil and hi ~= nil and hi.Y - lo.Y < 1.2 and hi.Y < 1.6
				end
				if off then
					part.CastShadow = false
					shadows += 1
				end
			end
		elseif part:IsA("SurfaceGui") and part.MaxDistance == 0 then
			part.MaxDistance = SIGN_DISTANCE
		end
	end
	return touch, shadows
end

-- Tono natural: los verdes muy saturados (césped, setos, copas) se apagan un poco y tiran a oliva.
-- Así la ciudad deja de parecer de plástico sin perder color. Devuelve cuántas piezas cambió.
local NATURAL = { [Enum.Material.Grass] = true, [Enum.Material.LeafyGrass] = true }
function Polish.tone(root: Instance): number
	local changed = 0
	for _, part in root:GetDescendants() do
		if part:IsA("BasePart") and NATURAL[part.Material] then
			local h, s, v = part.Color:ToHSV()
			if h > 0.18 and h < 0.45 and s > 0.46 then
				s = 0.46 + (s - 0.46) * 0.35
				h = h - (h - 0.24) * 0.25
				part.Color = Color3.fromHSV(h, s, v * 0.96)
				changed += 1
			end
		end
	end
	return changed
end

return Polish
