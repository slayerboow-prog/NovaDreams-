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

return Polish
