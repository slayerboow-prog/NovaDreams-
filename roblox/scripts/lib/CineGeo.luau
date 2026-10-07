-- CineGeo: el mapa real (un .rbxl ya construido) como cajas para hacer cuentas de CÁMARA fuera de
-- Roblox: rayos (¿se ve la cabeza?, ¿atraviesa una pared el travelling?), «¿este punto está dentro de
-- algo?» y el suelo bajo un punto. Lo usan scripts/audit/cine-planos.luau y scripts/test-cineplanos.luau.
--
-- Cada pieza (BasePart) es una caja orientada (CFrame + Size); las bolas son esferas y las cuñas cuñas.
-- Las MeshPart se toman como su caja algo encogida (no se puede leer la malla): una copa de árbol es
-- más pequeña que su caja. Rejilla 3D de celdas de 16 studs para no mirar las ~cientos de miles de
-- piezas en cada rayo.
--
--   local Geo = require("../lib/CineGeo")
--   local world = Geo.load(workspace)                    (workspace de roblox.deserializePlace)
--   world:raycast(origin, direction, filter)  -> { T = studs, Part = info } | nil
--   world:inside(point, filter)               -> info | nil  (la pieza que contiene el punto)
--   world:groundAt(point)                     -> Vector3 | nil (como SceneService.groundAt)
-- info = { Name, Class, Path, Transparency, CanCollide, Hidden, Vehicle, NotFloor, Size, CFrame }
-- filter(info) -> true si la pieza cuenta. Filtros hechos: Geo.Solid (lo que se ve: tapa y no deja
-- poner la cámara dentro), Geo.Collide (lo que para la cámara de CineCamera.clamp: CanCollide).

local roblox = require("@lune/roblox")
local Vector3 = roblox.Vector3

local Geo = {}

local CELL = 16 -- rejilla fina (piezas pequeñas)
local COARSE = 128 -- rejilla gruesa (piezas grandes: calles, suelos, fachadas)
local FINE_MAX = 48 -- diámetro hasta el que una pieza va a la rejilla fina
local BIG = 1500 -- más grandes que esto (el mar): lista aparte, se miran siempre

local SHELL_TAGS = { BuildingShell = true, PropShell = true }
local NOT_FLOOR = { Leaves = true, Bush = true, Flower = true, Trunk = true, TrunkMesh = true, Branch = true }
local VEHICLE_FOLDERS = { Buses = true, Rides = true, Traffic = true, AmbientTraffic = true }
-- Lo que no es decorado: zonas, marcas de la historia, luces volumétricas…
local SKIP_FOLDERS = { StoryScenes = true, Camera = true }

export type Info = { [string]: any }

-- Lo que se VE (tapa a un personaje y no se puede tener la cámara dentro)
function Geo.Solid(info: Info): boolean
	return info.Transparency < 0.6 and not info.Hidden
end
-- Lo que para a CineCamera.clamp (RaycastParams.RespectCanCollide)
function Geo.Collide(info: Info): boolean
	return info.CanCollide
end
-- Suelo de verdad para poner de pie a la gente (Ground.castVisible)
function Geo.Floor(info: Info): boolean
	return info.CanCollide and not info.Hidden and not info.NotFloor and not info.Vehicle
end

local function hasTag(instance: any, tags: { [string]: boolean }): boolean
	local ok, list = pcall(function()
		return instance:GetTags()
	end)
	if ok and list then
		for _, tag in list do
			if tags[tag] then
				return true
			end
		end
	end
	return false
end

local World = {}
World.__index = World

local function key(x: number, y: number, z: number): number
	-- (celdas de -2048..2047 en cada eje; las salas de interior están a Y > 3000: 13 bits en Y)
	return ((x + 2048) * 8192 + (y + 4096)) * 4096 + (z + 2048)
end

function Geo.load(workspace: any): any
	local self = setmetatable({ Parts = {}, Grid = {}, Coarse = {}, Big = {}, Count = 0 }, World)
	local function walk(root: any, vehicle: boolean, path: string)
		for _, child in root:GetChildren() do
			local name = child.Name
			if root == workspace and SKIP_FOLDERS[name] then
				continue
			end
			local isVehicle = vehicle or (root == workspace and VEHICLE_FOLDERS[name] == true)
			if child:IsA("Model") then
				local ok, attr = pcall(function()
					return child:GetAttribute("Drivable") or child:GetAttribute("BusLine")
				end)
				if name == "ParkedCar" or (ok and attr) then
					isVehicle = true
				end
			end
			if child:IsA("BasePart") and child.ClassName ~= "Terrain" then
				self:add(child, isVehicle, path .. "/" .. name)
			end
			walk(child, isVehicle, if #path < 120 then path .. "/" .. name else path)
		end
	end
	walk(workspace, false, "")
	return self
end

function World:add(part: any, vehicle: boolean, path: string)
	local cf, size = part.CFrame, part.Size
	local class = part.ClassName
	local shape = "Block"
	if class == "Part" then
		local ok, s = pcall(function()
			return part.Shape.Name
		end)
		if ok and s then
			shape = s
		end
	elseif class == "WedgePart" then
		shape = "Wedge"
	elseif class == "MeshPart" or class == "UnionOperation" then
		shape = "Mesh"
		size *= 0.8 -- (la malla rara vez llena su caja)
	end
	local transparency = tonumber(part.Transparency) or 0
	local collider = false
	pcall(function()
		collider = part:GetAttribute("Collider") == true
	end)
	local info: Info = {
		Name = part.Name,
		Class = class,
		Shape = shape,
		Path = path,
		Transparency = transparency,
		CanCollide = part.CanCollide == true,
		Hidden = transparency >= 0.95 or collider or hasTag(part, SHELL_TAGS),
		Vehicle = vehicle,
		NotFloor = NOT_FLOOR[part.Name] == true,
		CFrame = cf,
		Size = size,
		Half = size / 2,
		Center = cf.Position,
		Radius = (size / 2).Magnitude,
	}
	self.Count += 1
	self.Parts[self.Count] = info
	info.Stamp = 0
	if info.Radius * 2 > BIG then
		table.insert(self.Big, info)
		return
	end
	-- Celdas que toca su esfera envolvente (en la rejilla fina o en la gruesa)
	local fine = info.Radius * 2 <= FINE_MAX
	local size = if fine then CELL else COARSE
	local grid = if fine then self.Grid else self.Coarse
	local c, r = info.Center, info.Radius
	for x = math.floor((c.X - r) / size), math.floor((c.X + r) / size) do
		for y = math.floor((c.Y - r) / size), math.floor((c.Y + r) / size) do
			for z = math.floor((c.Z - r) / size), math.floor((c.Z + r) / size) do
				local k = key(x, y, z)
				local list = grid[k]
				if not list then
					list = {}
					grid[k] = list
				end
				table.insert(list, info)
			end
		end
	end
end

-- Las piezas cerca de un segmento (o de un punto, si a == b), sin repetir
local stamp = 0
function World:near(a: Vector3, b: Vector3, pad: number?): { Info }
	local p = pad or 0
	stamp += 1
	local out = {}
	local n = 0
	local length = (b - a).Magnitude
	local dir = if length > 1e-6 then (b - a) / length else Vector3.zero
	for pass = 1, 2 do
		local size = if pass == 1 then CELL else COARSE
		local grid = if pass == 1 then self.Grid else self.Coarse
		for x = math.floor((math.min(a.X, b.X) - p) / size), math.floor((math.max(a.X, b.X) + p) / size) do
			for y = math.floor((math.min(a.Y, b.Y) - p) / size), math.floor((math.max(a.Y, b.Y) + p) / size) do
				for z = math.floor((math.min(a.Z, b.Z) - p) / size), math.floor((math.max(a.Z, b.Z) + p) / size) do
					local list = grid[key(x, y, z)]
					if not list then
						continue
					end
					-- (un rayo largo en diagonal: solo las celdas cerca de la recta)
					if length > size * 2 then
						local center = Vector3.new((x + 0.5) * size, (y + 0.5) * size, (z + 0.5) * size)
						local t = math.clamp((center - a):Dot(dir), 0, length)
						if (a + dir * t - center).Magnitude > size * 0.9 + p then
							continue
						end
					end
					for _, info in list do
						if info.Stamp ~= stamp then
							info.Stamp = stamp
							n += 1
							out[n] = info
						end
					end
				end
			end
		end
	end
	for _, info in self.Big do
		n += 1
		out[n] = info
	end
	return out
end

-- Rayo contra una pieza en sus ejes: distancia de entrada (o nil). Caja por planos (slabs); bola como
-- esfera; cuña como caja cortada por su rampa. Como en Roblox, la pieza donde empieza el rayo no cuenta.
local function hitPart(info: Info, origin: Vector3, dir: Vector3, maxT: number): number?
	local cf = info.CFrame
	local o = cf:PointToObjectSpace(origin)
	local d = cf:VectorToObjectSpace(dir)
	local h = info.Half
	if info.Shape == "Ball" then
		local r = math.min(h.X, h.Y, h.Z)
		local b = o:Dot(d)
		local c = o:Dot(o) - r * r
		local disc = b * b - c
		if disc < 0 then
			return nil
		end
		local s = math.sqrt(disc)
		local t = -b - s
		if t < 0 then
			return nil -- (el rayo sale de dentro: Roblox no lo cuenta)
		end
		return if t <= maxT then t else nil
	end
	-- (un rayo que sale de DENTRO de una pieza no la toca, como workspace:Raycast)
	if math.abs(o.X) < h.X and math.abs(o.Y) < h.Y and math.abs(o.Z) < h.Z then
		if info.Shape ~= "Wedge" or o.Y / h.Y <= o.Z / h.Z then
			return nil
		end
	end
	local tmin, tmax = 0, maxT
	local oo, dd, hh = o.X, d.X, h.X
	for axis = 1, 3 do
		if axis == 2 then
			oo, dd, hh = o.Y, d.Y, h.Y
		elseif axis == 3 then
			oo, dd, hh = o.Z, d.Z, h.Z
		end
		if math.abs(dd) < 1e-9 then
			if oo < -hh or oo > hh then
				return nil
			end
		else
			local t1, t2 = (-hh - oo) / dd, (hh - oo) / dd
			if t1 > t2 then
				t1, t2 = t2, t1
			end
			if t1 > tmin then
				tmin = t1
			end
			if t2 < tmax then
				tmax = t2
			end
			if tmin > tmax then
				return nil
			end
		end
	end
	if info.Shape == "Wedge" then
		-- Rampa: dentro si y/hy <= z/hz (sube hacia +Z). Se recorta el tramo [tmin, tmax] con ese plano.
		local function f(t: number): number
			local p = o + d * t
			return p.Y / h.Y - p.Z / h.Z
		end
		local fa, fb = f(tmin), f(tmax)
		if fa <= 0 then
			return tmin
		elseif fb <= 0 then
			return tmin + (tmax - tmin) * fa / (fa - fb)
		end
		return nil
	end
	return tmin
end

-- Primer impacto del rayo (direction con su longitud) con piezas que pasan el filtro
function World:raycast(origin: Vector3, direction: Vector3, filter: ((Info) -> boolean)?, ignore: ((Info) -> boolean)?): { T: number, Part: Info }?
	local length = direction.Magnitude
	if length < 1e-6 then
		return nil
	end
	local dir = direction / length
	local best: { T: number, Part: Info }? = nil
	for _, info in self:near(origin, origin + direction, 0) do
		if (filter == nil or filter(info)) and not (ignore and ignore(info)) then
			-- (descarte rápido por la esfera envolvente)
			local oc = info.Center - origin
			local t = math.clamp(oc:Dot(dir), 0, length)
			if (origin + dir * t - info.Center).Magnitude <= info.Radius then
				local hit = hitPart(info, origin, dir, if best then best.T else length)
				if hit and (best == nil or hit < best.T) then
					best = { T = hit, Part = info }
				end
			end
		end
	end
	return best
end

-- ¿Está el punto dentro de una pieza? (margin: cuánto hay que estar metido para que cuente)
function World:inside(point: Vector3, filter: ((Info) -> boolean)?, margin: number?): Info?
	local m = margin or 0.05
	for _, info in self:near(point, point, 0) do
		if (filter == nil or filter(info)) and (point - info.Center).Magnitude <= info.Radius then
			local p = info.CFrame:PointToObjectSpace(point)
			local h = info.Half
			if info.Shape == "Ball" then
				if p.Magnitude < math.min(h.X, h.Y, h.Z) - m then
					return info
				end
			elseif math.abs(p.X) < h.X - m and math.abs(p.Y) < h.Y - m and math.abs(p.Z) < h.Z - m then
				if info.Shape ~= "Wedge" or p.Y / h.Y <= p.Z / h.Z then
					return info
				end
			end
		end
	end
	return nil
end

-- El suelo bajo un punto, como SceneService.groundAt: desde 3,5 por encima, 14 hacia abajo, solo
-- suelo que se ve (ni cajas invisibles, ni coches, ni copas de árbol)
function World:groundAt(position: Vector3, from: number?, down: number?): Vector3?
	local origin = position + Vector3.new(0, from or 3.5, 0)
	local hit = self:raycast(origin, Vector3.new(0, -(down or 14), 0), Geo.Floor)
	return if hit then origin + Vector3.new(0, -hit.T, 0) else nil
end

-- Piezas que se ven cerca de un punto (para dibujar): { { CFrame, Size, Shape, Name, Transparency } }
function World:around(center: Vector3, radius: number, filter: ((Info) -> boolean)?): { Info }
	local out = {}
	for _, info in self:near(center, center, radius) do
		if (filter == nil or filter(info)) and (info.Center - center).Magnitude <= radius + info.Radius and info.Radius < 400 then
			table.insert(out, info)
		end
	end
	return out
end

return Geo
