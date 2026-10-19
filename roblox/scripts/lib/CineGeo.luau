-- CineGeo: el mapa real (un .rbxl ya construido) como cajas para hacer cuentas de CÁMARA fuera de
-- Roblox: rayos (¿se ve la cabeza?, ¿atraviesa una pared el travelling?), «¿este punto está dentro de
-- algo?» y el suelo bajo un punto. Lo usan scripts/audit/cine-planos.luau y scripts/test-cineplanos.luau.
--
-- Cada pieza (BasePart) es una caja orientada (CFrame + Size); las bolas son esferas y las cuñas cuñas.
-- Las MeshPart se toman como su caja algo encogida (no se puede leer la malla): una copa de árbol es
-- más pequeña que su caja. Rejilla 3D de celdas de 16 studs para no mirar las ~cientos de miles de
-- piezas en cada rayo.
--
-- RÁPIDO: las cuentas van con números sueltos (no con Vector3/CFrame de Lune, que son userdata y cada
-- operación crea uno nuevo: era el 95 % del tiempo de la auditoría, ~1 ms por rayo) y los filtros
-- conocidos (Solid, Collide, Floor, Blocks, Opaque, Glassy) se calculan una vez al cargar la pieza.
--
--   local Geo = require("../lib/CineGeo")
--   local world = Geo.load(workspace)                    (workspace de roblox.deserializePlace)
--   world:raycast(origin, direction, filter)  -> { T = studs, Part = info } | nil
--   world:inside(point, filter)               -> info | nil  (la pieza que contiene el punto)
--   world:groundAt(point)                     -> Vector3 | nil (como SceneService.groundAt)
--   world:disable(info)                       la pieza deja de contar (el coche de mentira se va)
-- info = { Name, Class, Path, Transparency, CanCollide, Hidden, Vehicle, NotFloor, Size, CFrame }
-- filter(info) -> true si la pieza cuenta. Filtros hechos: Geo.Solid (lo que se ve: tapa y no deja
-- poner la cámara dentro), Geo.Collide (lo que para la cámara de CineCamera.clamp: CanCollide),
-- Geo.Floor (suelo para estar de pie), Geo.Blocks (lo que se ve y no es diminuto: tapa una cara),
-- Geo.Opaque (Blocks sin cristales: CineCamera.castGlass), Geo.Glassy (cristal o ventana).

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

-- Los filtros: miran el campo calculado al cargar (rápido) — el rayo los reconoce y ni los llama
function Geo.Solid(info: Info): boolean
	return info.fSolid == true
end
function Geo.Collide(info: Info): boolean
	return info.fCollide == true
end
function Geo.Floor(info: Info): boolean
	return info.fFloor == true
end
function Geo.Blocks(info: Info): boolean
	return info.fBlocks == true
end
function Geo.Opaque(info: Info): boolean
	return info.fOpaque == true
end
function Geo.Glassy(info: Info): boolean
	return info.fGlassy == true
end
-- Lo que ve un workspace:Raycast del juego (CineCamera.castVisible): Blocks, pero solo las piezas con
-- CanQuery (las de decoración —copas, tejas, toldos, balcones, muebles— no salen en los rayos)
function Geo.QueryBlocks(info: Info): boolean
	return info.fQBlocks == true
end
function Geo.QueryOpaque(info: Info): boolean
	return info.fQOpaque == true
end
-- Lo que ve SafeSpot.free del juego (GetPartsInPart, RespectCanCollide): choca y tiene CanQuery
function Geo.QueryCollide(info: Info): boolean
	return info.fQCollide == true
end
-- Lo que mira SafeSpot.freeForActor (dónde se pone a un actor): lo que choca y sale en las consultas, y
-- la decoración sin CanQuery que se ve (SafeSpot.decorAt, CameraShots.occluder)
function Geo.ActorBlocks(info: Info): boolean
	return info.fActor == true
end
-- Lo que ve la cámara del juego con Controllers/CineOccluders: las piezas con CanQuery y las de
-- decoración sin CanQuery que tapan (CameraShots.occluder)
function Geo.GameBlocks(info: Info): boolean
	return info.fGBlocks == true
end
function Geo.GameOpaque(info: Info): boolean
	return info.fGOpaque == true
end
local FILTER_KEYS = {
	[Geo.Solid] = "fSolid",
	[Geo.Collide] = "fCollide",
	[Geo.Floor] = "fFloor",
	[Geo.Blocks] = "fBlocks",
	[Geo.Opaque] = "fOpaque",
	[Geo.Glassy] = "fGlassy",
	[Geo.QueryBlocks] = "fQBlocks",
	[Geo.QueryOpaque] = "fQOpaque",
	[Geo.GameBlocks] = "fGBlocks",
	[Geo.QueryCollide] = "fQCollide",
	[Geo.ActorBlocks] = "fActor",
	[Geo.GameOpaque] = "fGOpaque",
}

-- (re)calcula los filtros de una pieza a partir de Transparency / CanCollide / Hidden…
local function computeFlags(info: Info)
	local solid = info.Transparency < 0.6 and not info.Hidden
	info.fSolid = solid
	info.fCollide = info.CanCollide == true
	info.fFloor = info.CanCollide == true and not info.Hidden and not info.NotFloor and not info.Vehicle
	local s = info.Size
	-- (lo que tapa: lo que se ve y no es un hilo ni una mota; la misma medida que CameraShots.occluderSize)
	info.fBlocks = solid and (if Geo.occluderSize then Geo.occluderSize(info.RawSize or s) else (s.X >= 1 or s.Y >= 1 or s.Z >= 1))
	local name = string.lower(info.Name)
	local glass = name:find("glass", 1, true) ~= nil or name:find("window", 1, true) ~= nil or name:find("ventan", 1, true) ~= nil
	info.fGlassy = info.Transparency >= 0.2 or glass
	info.fOpaque = info.fBlocks and not info.fGlassy
	info.fQBlocks = info.fBlocks and info.CanQuery ~= false
	info.fQOpaque = info.fOpaque and info.CanQuery ~= false
	local seen = info.CanQuery ~= false or (Geo.occluder ~= nil and Geo.occluder(info.Transparency, info.RawSize or s, false, info.Collider))
	info.fGBlocks = info.fBlocks and seen
	info.fQCollide = info.CanCollide == true and info.CanQuery ~= false
	info.fActor = info.fQCollide or (info.CanQuery == false and not info.Hidden and Geo.occluder ~= nil and Geo.occluder(info.Transparency, info.RawSize or s, false, info.Collider))
	info.fGOpaque = info.fOpaque and seen
end
Geo.computeFlags = computeFlags

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
Geo.World = World

local function key(x: number, y: number, z: number): number
	-- (celdas de -2048..2047 en cada eje; las salas de interior están a Y > 3000: 13 bits en Y)
	return ((x + 2048) * 8192 + (y + 4096)) * 4096 + (z + 2048)
end

function Geo.load(workspace: any): any
	local self = setmetatable({ Parts = {}, Grid = {}, Coarse = {}, Big = {}, Count = 0, Stamp = 0 }, World)
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

-- Un mundo vacío (para las pruebas: se le añaden piezas con :add)
function Geo.empty(): any
	return setmetatable({ Parts = {}, Grid = {}, Coarse = {}, Big = {}, Count = 0, Stamp = 0 }, World)
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
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
	local info: Info = {
		Name = part.Name,
		Class = class,
		Shape = shape,
		Path = path,
		Transparency = transparency,
		CanCollide = part.CanCollide == true,
		CanQuery = part.CanQuery ~= false,
		Hidden = transparency >= 0.95 or collider or hasTag(part, SHELL_TAGS),
		Collider = collider,
		RawSize = part.Size,
		Vehicle = vehicle,
		NotFloor = NOT_FLOOR[part.Name] == true,
		CFrame = cf,
		Size = size,
		Half = size / 2,
		Center = cf.Position,
		Radius = (size / 2).Magnitude,
		-- (números sueltos para las cuentas rápidas: centro, ejes del CFrame —columnas— y medio tamaño)
		cx = x,
		cy = y,
		cz = z,
		ax = r00,
		ay = r10,
		az = r20, -- RightVector
		bx = r01,
		by = r11,
		bz = r21, -- UpVector
		zx = r02,
		zy = r12,
		zz = r22, -- -LookVector
		hx = size.X / 2,
		hy = size.Y / 2,
		hz = size.Z / 2,
		shape = if shape == "Ball" then 1 elseif shape == "Wedge" then 2 else 0,
		Stamp = 0,
		Cells = nil,
	}
	info.r2 = info.Radius * info.Radius
	computeFlags(info)
	self.Count += 1
	self.Parts[self.Count] = info
	if info.Radius * 2 > BIG then
		table.insert(self.Big, info)
		return
	end
	-- Celdas que toca su esfera envolvente (en la rejilla fina o en la gruesa)
	local fine = info.Radius * 2 <= FINE_MAX
	local cell = if fine then CELL else COARSE
	local grid = if fine then self.Grid else self.Coarse
	local r = info.Radius
	for gx = math.floor((x - r) / cell), math.floor((x + r) / cell) do
		for gy = math.floor((y - r) / cell), math.floor((y + r) / cell) do
			for gz = math.floor((z - r) / cell), math.floor((z + r) / cell) do
				local k = key(gx, gy, gz)
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

-- La pieza deja de contar para todo (como si no estuviera)
function World:disable(info: Info)
	info.Hidden = true
	info.CanCollide = false
	info.Transparency = 1
	info.Disabled = true
	computeFlags(info)
	info.fGlassy = false
end

-- Las piezas cerca de un segmento (o de un punto, si a == b), sin repetir: (lista, n). La lista es un
-- búfer que se reutiliza (vale hasta la siguiente llamada del mismo nivel).
local pool: { { Info } } = {}
local depth = 0
local function nearXYZ(self, ax: number, ay: number, az: number, bx: number, by: number, bz: number, p: number): ({ Info }, number)
	self.Stamp += 1
	local stamp = self.Stamp
	depth += 1
	local out = pool[depth]
	if not out then
		out = {}
		pool[depth] = out
	end
	local n = 0
	local dx, dy, dz = bx - ax, by - ay, bz - az
	local length = math.sqrt(dx * dx + dy * dy + dz * dz)
	local ux, uy, uz = 0, 0, 0
	if length > 1e-6 then
		ux, uy, uz = dx / length, dy / length, dz / length
	end
	local minX, maxX = math.min(ax, bx) - p, math.max(ax, bx) + p
	local minY, maxY = math.min(ay, by) - p, math.max(ay, by) + p
	local minZ, maxZ = math.min(az, bz) - p, math.max(az, bz) + p
	for pass = 1, 2 do
		local size = if pass == 1 then CELL else COARSE
		local grid = if pass == 1 then self.Grid else self.Coarse
		local long = length > size * 2
		local reach = size * 0.9 + p
		local reach2 = reach * reach
		for x = math.floor(minX / size), math.floor(maxX / size) do
			local cxc = (x + 0.5) * size
			for y = math.floor(minY / size), math.floor(maxY / size) do
				local cyc = (y + 0.5) * size
				for z = math.floor(minZ / size), math.floor(maxZ / size) do
					local list = grid[key(x, y, z)]
					if not list then
						continue
					end
					-- (un rayo largo en diagonal: solo las celdas cerca de la recta)
					if long then
						local czc = (z + 0.5) * size
						local ox, oy, oz = cxc - ax, cyc - ay, czc - az
						local t = ox * ux + oy * uy + oz * uz
						if t < 0 then
							t = 0
						elseif t > length then
							t = length
						end
						local ex, ey, ez = ux * t - ox, uy * t - oy, uz * t - oz
						if ex * ex + ey * ey + ez * ez > reach2 then
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
	return out, n
end

-- (versión con Vector3, como antes: una lista nueva)
function World:near(a: Vector3, b: Vector3, pad: number?): { Info }
	local buf, n = nearXYZ(self, a.X, a.Y, a.Z, b.X, b.Y, b.Z, pad or 0)
	depth -= 1
	local out = table.create(n)
	table.move(buf, 1, n, 1, out)
	return out
end

-- Rayo contra una pieza en sus ejes: distancia de entrada (o nil). Caja por planos (slabs); bola como
-- esfera; cuña como caja cortada por su rampa. Como en Roblox, la pieza donde empieza el rayo no cuenta.
-- (origen relativo al centro y dirección unitaria, en números)
local function hitPart(info: Info, rx: number, ry: number, rz: number, ux: number, uy: number, uz: number, maxT: number): number?
	-- a los ejes de la pieza
	local ox = rx * info.ax + ry * info.ay + rz * info.az
	local oy = rx * info.bx + ry * info.by + rz * info.bz
	local oz = rx * info.zx + ry * info.zy + rz * info.zz
	local dx = ux * info.ax + uy * info.ay + uz * info.az
	local dy = ux * info.bx + uy * info.by + uz * info.bz
	local dz = ux * info.zx + uy * info.zy + uz * info.zz
	local hx, hy, hz = info.hx, info.hy, info.hz
	local shape = info.shape
	if shape == 1 then
		local r = math.min(hx, hy, hz)
		local b = ox * dx + oy * dy + oz * dz
		local c = ox * ox + oy * oy + oz * oz - r * r
		local disc = b * b - c
		if disc < 0 then
			return nil
		end
		local t = -b - math.sqrt(disc)
		if t < 0 then
			return nil -- (el rayo sale de dentro: Roblox no lo cuenta)
		end
		return if t <= maxT then t else nil
	end
	-- (un rayo que sale de DENTRO de una pieza no la toca, como workspace:Raycast)
	if math.abs(ox) < hx and math.abs(oy) < hy and math.abs(oz) < hz then
		if shape ~= 2 or oy / hy <= oz / hz then
			return nil
		end
	end
	local tmin, tmax = 0, maxT
	-- X
	if math.abs(dx) < 1e-9 then
		if ox < -hx or ox > hx then
			return nil
		end
	else
		local t1, t2 = (-hx - ox) / dx, (hx - ox) / dx
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
	-- Y
	if math.abs(dy) < 1e-9 then
		if oy < -hy or oy > hy then
			return nil
		end
	else
		local t1, t2 = (-hy - oy) / dy, (hy - oy) / dy
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
	-- Z
	if math.abs(dz) < 1e-9 then
		if oz < -hz or oz > hz then
			return nil
		end
	else
		local t1, t2 = (-hz - oz) / dz, (hz - oz) / dz
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
	if shape == 2 then
		-- Rampa: dentro si y/hy <= z/hz (sube hacia +Z). Se recorta el tramo [tmin, tmax] con ese plano.
		local fa = (oy + dy * tmin) / hy - (oz + dz * tmin) / hz
		local fb = (oy + dy * tmax) / hy - (oz + dz * tmax) / hz
		if fa <= 0 then
			return tmin
		elseif fb <= 0 then
			return tmin + (tmax - tmin) * fa / (fa - fb)
		end
		return nil
	end
	return tmin
end

---------------------------------------------------------------------
-- El TERRENO (TerrainBuilder: la isla a Y = -1, las colinas del relieve y las montañas), que Lune no
-- puede leer del .rbxl: se le da al mundo como una función de altura (CinePlanos.open, con
-- shared/Relief y CityPlan). Cuenta en los rayos como una pieza más («Terreno»), salvo para los
-- cristales (Geo.Glassy), y en el suelo bajo un punto (groundAt).
--   world:setTerrain(heightAt, boundAt)   heightAt(x, z) -> Y de la superficie | nil (mar)
--                                         boundAt(x0, z0, x1, z1) -> Y máxima posible en ese rectángulo
---------------------------------------------------------------------
local TERRAIN_INFO: Info = {
	Name = "Terreno",
	Class = "Terrain",
	Shape = "Block",
	Path = "/Terrain",
	Transparency = 0,
	CanCollide = true,
	CanQuery = true,
	Hidden = false,
	Vehicle = false,
	NotFloor = false,
	Size = Vector3.new(4, 4, 4),
	Radius = 3.5,
	Terrain = true,
}
Geo.TerrainInfo = TERRAIN_INFO
local NO_TERRAIN = { fGlassy = true }
function World:setTerrain(heightAt: (number, number) -> number?, boundAt: (number, number, number, number) -> number)
	self.TerrainY = heightAt
	self.TerrainBound = boundAt
	-- (por debajo del suelo del campo, Y = -1, está lo excavado: metro, túneles, sótanos)
	self.TerrainFloor = -1.5
end

-- Primer punto del segmento por debajo de la superficie del terreno (t) o nil. Pasos de 2 studs y
-- bisección; si el origen ya está bajo tierra, no cuenta (como la pieza donde empieza un rayo).
local function terrainCast(self, px: number, py: number, pz: number, ux: number, uy: number, uz: number, maxT: number): number?
	local heightAt = self.TerrainY
	if not heightAt then
		return nil
	end
	local ex, ey, ez = px + ux * maxT, py + uy * maxT, pz + uz * maxT
	local top = self.TerrainBound(math.min(px, ex), math.min(pz, ez), math.max(px, ex), math.max(pz, ez))
	if math.min(py, ey) > top then
		return nil
	end
	local function below(t: number): boolean
		local y = heightAt(px + ux * t, pz + uz * t)
		return y ~= nil and py + uy * t < y
	end
	if below(0) or py < self.TerrainFloor then
		return nil -- (bajo tierra de verdad —metro, alcantarillas, sótanos—: ahí el terreno está vaciado)
	end
	local step = 2
	local prev = 0
	local t = math.min(step, maxT)
	while true do
		if below(t) then
			local lo, hi = prev, t
			for _ = 1, 6 do
				local mid = (lo + hi) / 2
				if below(mid) then
					hi = mid
				else
					lo = mid
				end
			end
			return hi
		end
		if t >= maxT then
			return nil
		end
		prev = t
		t = math.min(t + step, maxT)
	end
end

-- Primer impacto, en números: (t, info) o nil
local function castXYZ(self, px: number, py: number, pz: number, dx: number, dy: number, dz: number, filter: any, ignore: any): (number?, Info?)
	local length = math.sqrt(dx * dx + dy * dy + dz * dz)
	if length < 1e-6 then
		return nil, nil
	end
	local ux, uy, uz = dx / length, dy / length, dz / length
	local fkey = if filter ~= nil then FILTER_KEYS[filter] else nil
	local generic = filter ~= nil and fkey == nil
	local list, n = nearXYZ(self, px, py, pz, px + dx, py + dy, pz + dz, 0)
	local bestT, bestInfo = length, nil
	for i = 1, n do
		local info = list[i]
		if fkey then
			if not info[fkey] then
				continue
			end
		elseif generic then
			if info.Disabled or not filter(info) then
				continue
			end
		elseif info.Disabled then
			continue
		end
		-- (descarte rápido por la esfera envolvente)
		local rx, ry, rz = px - info.cx, py - info.cy, pz - info.cz
		local t = -(rx * ux + ry * uy + rz * uz)
		if t < 0 then
			t = 0
		elseif t > length then
			t = length
		end
		local ex, ey, ez = rx + ux * t, ry + uy * t, rz + uz * t
		if ex * ex + ey * ey + ez * ez > info.r2 then
			continue
		end
		if ignore and ignore(info) then
			continue
		end
		local hit = hitPart(info, rx, ry, rz, ux, uy, uz, bestT)
		if hit and (bestInfo == nil or hit < bestT) then
			bestT, bestInfo = hit, info
		end
	end
	depth -= 1
	if self.TerrainY and not generic and not (fkey and NO_TERRAIN[fkey]) then
		local tt = terrainCast(self, px, py, pz, ux, uy, uz, bestT)
		if tt and (bestInfo == nil or tt < bestT) then
			return tt, TERRAIN_INFO
		end
	end
	if bestInfo then
		return bestT, bestInfo
	end
	return nil, nil
end

-- ¿Está el punto por debajo de la superficie del terreno? (cuánto) o nil
function World:underTerrain(point: Vector3, margin: number?): number?
	if not self.TerrainY then
		return nil
	end
	local y = self.TerrainY(point.X, point.Z)
	if y and point.Y >= self.TerrainFloor and point.Y < y - (margin or 0) then
		return y - point.Y
	end
	return nil
end

-- La superficie del terreno en (x, z) o nil (mar / sin terreno)
function World:terrainAt(x: number, z: number): number?
	return if self.TerrainY then self.TerrainY(x, z) else nil
end

-- Primer impacto del rayo (direction con su longitud) con piezas que pasan el filtro
function World:raycast(origin: Vector3, direction: Vector3, filter: ((Info) -> boolean)?, ignore: ((Info) -> boolean)?): { T: number, Part: Info }?
	local t, info = castXYZ(self, origin.X, origin.Y, origin.Z, direction.X, direction.Y, direction.Z, filter, ignore)
	if t then
		return { T = t, Part = info }
	end
	return nil
end

-- Solo la distancia (sin crear la tabla del impacto): para la sonda de CameraShots.fit
function World:castT(origin: Vector3, direction: Vector3, filter: ((Info) -> boolean)?): number?
	local t = castXYZ(self, origin.X, origin.Y, origin.Z, direction.X, direction.Y, direction.Z, filter, nil)
	return t
end

-- ¿Está el punto dentro de una pieza? (margin: cuánto hay que estar metido para que cuente)
function World:inside(point: Vector3, filter: ((Info) -> boolean)?, margin: number?): Info?
	local m = margin or 0.05
	local px, py, pz = point.X, point.Y, point.Z
	local fkey = if filter ~= nil then FILTER_KEYS[filter] else nil
	local generic = filter ~= nil and fkey == nil
	local list, n = nearXYZ(self, px, py, pz, px, py, pz, 0)
	local found = nil
	for i = 1, n do
		local info = list[i]
		if fkey then
			if not info[fkey] then
				continue
			end
		elseif info.Disabled then
			continue
		end
		local rx, ry, rz = px - info.cx, py - info.cy, pz - info.cz
		if rx * rx + ry * ry + rz * rz > info.r2 then
			continue
		end
		if generic and not filter(info) then
			continue
		end
		local ox = rx * info.ax + ry * info.ay + rz * info.az
		local oy = rx * info.bx + ry * info.by + rz * info.bz
		local oz = rx * info.zx + ry * info.zy + rz * info.zz
		local hx, hy, hz = info.hx, info.hy, info.hz
		if info.shape == 1 then
			if math.sqrt(ox * ox + oy * oy + oz * oz) < math.min(hx, hy, hz) - m then
				found = info
				break
			end
		elseif math.abs(ox) < hx - m and math.abs(oy) < hy - m and math.abs(oz) < hz - m then
			if info.shape ~= 2 or oy / hy <= oz / hz then
				found = info
				break
			end
		end
	end
	depth -= 1
	return found
end

-- El suelo bajo un punto, como SceneService.groundAt: desde 3,5 por encima, 14 hacia abajo, solo
-- suelo que se ve (ni cajas invisibles, ni coches, ni copas de árbol)
function World:groundAt(position: Vector3, from: number?, down: number?): Vector3?
	local up = from or 3.5
	local t = castXYZ(self, position.X, position.Y + up, position.Z, 0, -(down or 14), 0, Geo.Floor, nil)
	return if t then Vector3.new(position.X, position.Y + up - t, position.Z) else nil
end

-- Piezas que se ven cerca de un punto (para dibujar): { { CFrame, Size, Shape, Name, Transparency } }
function World:around(center: Vector3, radius: number, filter: ((Info) -> boolean)?): { Info }
	local out = {}
	for _, info in self:near(center, center, radius) do
		if not info.Disabled and (filter == nil or filter(info)) and (info.Center - center).Magnitude <= radius + info.Radius and info.Radius < 400 then
			table.insert(out, info)
		end
	end
	return out
end

return Geo
