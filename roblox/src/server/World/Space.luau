-- Space: qué sitio de una sala está ya ocupado (para decorar y colocar gente sin meter nada dentro
-- de otra cosa). Todo en coordenadas de la sala: frame = centro del suelo (y = 0 el suelo), -Z la
-- puerta. Guarda cajas alineadas con esos ejes (una pieza girada ocupa la caja que la envuelve).
--
--   local s = Space.new(frame, halfX, halfZ, height)
--   s:addPart(part)                   -> lo que ya hay (muebles, cristales, marcas…)
--   s:addWall(part)                   -> paredes (para colgar cosas: onWall)
--   s:free(center, size)              -> ¿cabe una caja (centro y tamaño, en la sala) sin tocar nada?
--   s:claim(center, size)             -> si cabe, la reserva y devuelve true
--   s:onWall(point, normal)           -> ¿hay pared de verdad detrás de ese punto? (no hueco ni ventana)
--   s:block(x0, x1, z0, z1)           -> zona que no se toca (el paso desde la puerta)

local Space = {}
Space.__index = Space

type Box = { Min: Vector3, Max: Vector3 }

export type Space = typeof(setmetatable(
	{} :: {
		Frame: CFrame,
		HalfX: number,
		HalfZ: number,
		Height: number,
		Boxes: { Box },
		Walls: { Box },
	},
	Space
))

function Space.new(frame: CFrame, halfX: number, halfZ: number, height: number): Space
	return setmetatable({ Frame = frame, HalfX = halfX, HalfZ = halfZ, Height = height, Boxes = {}, Walls = {} }, Space)
end

-- Caja (en la sala) que envuelve una pieza del mundo
function Space.boxOf(self: Space, cf: CFrame, size: Vector3): Box
	local rel = self.Frame:ToObjectSpace(cf)
	local r, u, l = rel.RightVector, rel.UpVector, rel.LookVector
	local hx = (math.abs(r.X) * size.X + math.abs(u.X) * size.Y + math.abs(l.X) * size.Z) / 2
	local hy = (math.abs(r.Y) * size.X + math.abs(u.Y) * size.Y + math.abs(l.Y) * size.Z) / 2
	local hz = (math.abs(r.Z) * size.X + math.abs(u.Z) * size.Y + math.abs(l.Z) * size.Z) / 2
	local p = rel.Position
	return { Min = Vector3.new(p.X - hx, p.Y - hy, p.Z - hz), Max = Vector3.new(p.X + hx, p.Y + hy, p.Z + hz) }
end

function Space.addPart(self: Space, part: BasePart)
	local box = self:boxOf(part.CFrame, part.Size)
	-- Lo plano del suelo (alfombras, felpudos, marcas) no quita sitio: encima se puede poner algo
	if box.Max.Y < 0.3 then
		return
	end
	table.insert(self.Boxes, box)
end

function Space.addWall(self: Space, part: BasePart)
	table.insert(self.Walls, self:boxOf(part.CFrame, part.Size))
end

-- Una caja en la sala (centro y tamaño) que no se debe tocar
function Space.addBox(self: Space, center: Vector3, size: Vector3)
	table.insert(self.Boxes, { Min = center - size / 2, Max = center + size / 2 })
end

function Space.block(self: Space, x0: number, x1: number, z0: number, z1: number)
	table.insert(self.Boxes, { Min = Vector3.new(x0, 0, z0), Max = Vector3.new(x1, self.Height, z1) })
end

local function overlaps(a: Box, min: Vector3, max: Vector3): boolean
	return a.Min.X < max.X and a.Max.X > min.X and a.Min.Y < max.Y and a.Max.Y > min.Y and a.Min.Z < max.Z and a.Max.Z > min.Z
end

function Space.free(self: Space, center: Vector3, size: Vector3): boolean
	local min, max = center - size / 2, center + size / 2
	-- Dentro de la sala (lo colgado en la pared puede entrar hasta 0,5 studs en ella)
	if min.X < -self.HalfX - 0.5 or max.X > self.HalfX + 0.5 or min.Z < -self.HalfZ - 0.5 or max.Z > self.HalfZ + 0.5 then
		return false
	end
	if min.Y < -0.05 or max.Y > self.Height then
		return false
	end
	for _, box in self.Boxes do
		if overlaps(box, min, max) then
			return false
		end
	end
	return true
end

function Space.claim(self: Space, center: Vector3, size: Vector3): boolean
	if not self:free(center, size) then
		return false
	end
	self:addBox(center, size)
	return true
end

-- ¿Pared de verdad detrás del punto? (normal: hacia dónde mira la sala desde esa pared)
function Space.onWall(self: Space, point: Vector3, normal: Vector3): boolean
	local probe = point - normal * 0.5
	for _, box in self.Walls do
		if probe.X >= box.Min.X - 0.05 and probe.X <= box.Max.X + 0.05 and probe.Y >= box.Min.Y and probe.Y <= box.Max.Y and probe.Z >= box.Min.Z - 0.05 and probe.Z <= box.Max.Z + 0.05 then
			return true
		end
	end
	return false
end

-- CFrame del mundo para un punto de la sala mirando hacia (dx, dz)
function Space.at(self: Space, x: number, y: number, z: number, dx: number?, dz: number?): CFrame
	local cf = self.Frame * CFrame.new(x, y, z)
	if dx and dz then
		cf = cf * CFrame.Angles(0, math.atan2(-dx, -dz), 0)
	end
	return cf
end

return Space
