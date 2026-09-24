-- Blocks: rellena manzanas completas (entre calles) según su uso:
-- edificios en hilera, casas con jardín o equipamientos públicos (Civic).

local Builder = require(script.Parent.Parent.Builder)
local Palette = require(script.Parent.Palette)
local Building = require(script.Parent.Building)
local Nature = require(script.Parent.Nature)
local Civic = require(script.Parent.Civic)

local Blocks = {}

local rgb = Color3.fromRGB

export type Rect = { X0: number, X1: number, Z0: number, Z1: number }

-- Convierte un rectángulo + el lado que da a la calle en un "lote" con coordenadas u (a lo largo) y v (hacia dentro)
function Blocks.lot(rect: Rect, side: string): Civic.Lot
	local cx, cz = (rect.X0 + rect.X1) / 2, (rect.Z0 + rect.Z1) / 2
	local out: Vector3
	local length, depth
	local point: (number, number, number) -> Vector3
	if side == "S" then
		out, length, depth = Vector3.new(0, 0, 1), rect.X1 - rect.X0, rect.Z1 - rect.Z0
		point = function(u, v, y)
			return Vector3.new(cx + u, y, rect.Z1 - v)
		end
	elseif side == "N" then
		out, length, depth = Vector3.new(0, 0, -1), rect.X1 - rect.X0, rect.Z1 - rect.Z0
		point = function(u, v, y)
			return Vector3.new(cx + u, y, rect.Z0 + v)
		end
	elseif side == "E" then
		out, length, depth = Vector3.new(1, 0, 0), rect.Z1 - rect.Z0, rect.X1 - rect.X0
		point = function(u, v, y)
			return Vector3.new(rect.X1 - v, y, cz + u)
		end
	else
		out, length, depth = Vector3.new(-1, 0, 0), rect.Z1 - rect.Z0, rect.X1 - rect.X0
		point = function(u, v, y)
			return Vector3.new(rect.X0 + v, y, cz + u)
		end
	end
	return {
		Length = length,
		Depth = depth,
		point = point,
		facing = function(u, v, y)
			return Builder.facing(point(u, v, y or 0), out)
		end,
		along = function(u, v, y)
			local p = point(u, v, y or 0)
			return Builder.facing(p, point(u + 1, v, 0) - point(u, v, 0))
		end,
	}
end

local SHOP_NAMES = { "FARMACIA", "PANADERÍA", "ZAPATERÍA", "BANCO", "INMOBILIARIA", "FLORISTERÍA", "LIBRERÍA", "PELUQUERÍA", "FERRETERÍA", "ÓPTICA", "BAR", "PIZZERÍA", "HELADERÍA", "GIMNASIO", "FRUTERÍA", "ROPA" }
local AWNINGS = { rgb(170, 40, 40), rgb(40, 90, 150), rgb(40, 120, 70), rgb(200, 150, 40), rgb(90, 60, 110), rgb(220, 110, 40) }

-- Tramo de edificios en hilera a lo largo de un lado (u0..u1)
local function row(parent: Instance, lot: Civic.Lot, u0: number, u1: number, styles: { string }, floors: { number })
	local u = u0
	while u1 - u >= 18 do
		local width = math.min(math.random(24, 38), u1 - u)
		if u1 - (u + width) < 18 then
			width = u1 - u
		end
		local isShop = math.random() < 0.6
		Building.build({
			Name = "Edificio",
			Parent = parent,
			CFrame = lot.facing(u + width / 2, 14, 0),
			Width = width,
			Depth = 28,
			Floors = math.random(floors[1], floors[2]),
			Style = styles[math.random(1, #styles)],
			GroundFloor = if isShop then "Shop" else "Closed",
			Interior = false,
			WindowFaces = { Front = true },
			Sign = if isShop then SHOP_NAMES[math.random(1, #SHOP_NAMES)] else nil,
			Awning = if isShop then Palette.pick(AWNINGS) else nil,
		})
		u += width
	end
end

-- Manzana urbana: edificios alineados en los lados indicados y patio interior con árboles
function Blocks.downtown(parent: Instance, rect: Rect, sides: { string }, styles: { string }, floors: { number })
	local m = Builder.model("Manzana", parent)
	local has = {}
	for _, s in sides do
		has[s] = true
	end
	for _, side in sides do
		local lot = Blocks.lot(rect, side)
		local u0, u1 = -lot.Length / 2, lot.Length / 2
		-- Los lados E/O se acortan si ya hay edificios en N/S (esquinas)
		if side == "E" or side == "W" then
			if has.N then
				u0 += 28
			end
			if has.S then
				u1 -= 28
			end
		end
		row(m, lot, u0, u1, styles, floors)
	end
	-- Patio interior arbolado
	local cx, cz = (rect.X0 + rect.X1) / 2, (rect.Z0 + rect.Z1) / 2
	local w, d = rect.X1 - rect.X0, rect.Z1 - rect.Z0
	if w > 90 and d > 90 then
		for _ = 1, 4 do
			Nature.tree(m, Vector3.new(cx + math.random(-15, 15), 0, cz + math.random(-15, 15)))
		end
	end
	return m
end

-- Casa con jardín en un lote de "width" a lo largo de la calle
local HOUSE_SIZES = { Vector3.new(24, 1, 20), Vector3.new(28, 1, 22), Vector3.new(32, 2, 26), Vector3.new(26, 2, 22) }
local function houseLot(parent: Instance, lot: Civic.Lot, u: number, width: number, depth: number)
	local m = Builder.model("Vivienda", parent)
	local size = HOUSE_SIZES[math.random(1, #HOUSE_SIZES)]
	local setback = 12
	Building.build({
		Name = "Casa", Parent = m, CFrame = lot.facing(u, setback + size.Z / 2, 0),
		Width = math.min(size.X, width - 8), Depth = size.Z, Floors = size.Y, Style = "Casa",
		GroundFloor = "House", Interior = false,
	})
	-- Camino, setos y jardín
	local path = lot.facing(u, setback / 2, 0.2)
	Builder.part({ Name = "Path", Size = Vector3.new(4, 0.4, setback), CFrame = path, Color = rgb(206, 196, 178), Material = Enum.Material.Pavement, Parent = m })
	for _, side in { -1, 1 } do
		local a = lot.point(u + side * (width / 2 - 1), 2, 0)
		local b = lot.point(u + side * (width / 2 - 1), depth - 2, 0)
		Nature.hedge(m, a, b, 2.6)
	end
	Nature.bush(m, lot.point(u - width / 4, 4, 0))
	Nature.bush(m, lot.point(u + width / 4, 4, 0))
	if depth > setback + size.Z + 10 then
		Nature.tree(m, lot.point(u + (math.random() - 0.5) * (width - 12), depth - 7, 0))
		-- Algunas casas tienen piscina
		if math.random() < 0.35 then
			local pool = lot.facing(u - width / 5, setback + size.Z + 7, 0)
			Builder.part({ Name = "PoolRim", Size = Vector3.new(12, 0.6, 7), CFrame = pool * CFrame.new(0, 0.3, 0), Color = rgb(236, 232, 224), Material = Enum.Material.Limestone, Parent = m })
			Builder.decor({ Name = "PoolWater", Size = Vector3.new(11, 0.1, 6), CFrame = pool * CFrame.new(0, 0.62, 0), Color = rgb(70, 170, 220), Material = Enum.Material.Glass, Transparency = 0.1, Parent = m })
		end
	end
	return m
end

-- Barrio de casas: lotes de ~48 studs a lo largo de los lados indicados
function Blocks.houses(parent: Instance, rect: Rect, sides: { string })
	local m = Builder.model("Viviendas", parent)
	local has = {}
	for _, s in sides do
		has[s] = true
	end
	for _, side in sides do
		local lot = Blocks.lot(rect, side)
		local depth = math.min(lot.Depth / (if (side == "N" and has.S) or (side == "S" and has.N) or (side == "E" and has.W) or (side == "W" and has.E) then 2 else 1), 56)
		local u0, u1 = -lot.Length / 2, lot.Length / 2
		if side == "E" or side == "W" then
			if has.N then
				u0 += 56
			end
			if has.S then
				u1 -= 56
			end
		end
		local count = math.floor((u1 - u0) / 46)
		if count >= 1 and depth >= 36 then
			local width = (u1 - u0) / count
			for i = 0, count - 1 do
				houseLot(m, lot, u0 + width * (i + 0.5), width, depth)
			end
		end
	end
	return m
end

-- Rellena una manzana según su tipo
function Blocks.fill(parent: Instance, rect: Rect, kind: string, opts: { [string]: any })
	local side = opts.Side or opts.Sides[1]
	local lot = Blocks.lot(rect, side)
	if kind == "Downtown" then
		-- Manzana cerrada: edificios en todos los lados que dan a la calle, patio interior oculto
		return Blocks.downtown(parent, rect, opts.Sides, opts.Styles, opts.Floors)
	elseif kind == "Houses" then
		local sides = opts.Sides
		if #sides >= 3 then
			sides = if rect.X1 - rect.X0 >= rect.Z1 - rect.Z0 then { "N", "S" } else { "E", "W" }
			local filtered = {}
			for _, s in sides do
				if table.find(opts.Sides, s) then
					table.insert(filtered, s)
				end
			end
			sides = filtered
		end
		return Blocks.houses(parent, rect, sides)
	elseif kind == "Hospital" then
		return Civic.hospital(parent, lot, opts.TownName, false)
	elseif kind == "Clinic" then
		return Civic.hospital(parent, lot, opts.TownName, true)
	elseif kind == "School" then
		return Civic.school(parent, lot, opts.TownName)
	elseif kind == "FirePolice" then
		return Civic.firePolice(parent, lot)
	elseif kind == "Mall" then
		return Civic.mall(parent, lot, opts.TownName)
	elseif kind == "Gas" then
		return Civic.gasStation(parent, lot)
	elseif kind == "Park" then
		return Civic.park(parent, lot)
	elseif kind == "Farm" then
		return Civic.farm(parent, lot)
	elseif kind == "Beach" then
		return Civic.beach(parent, lot)
	end
	warn("[Blocks] Tipo de manzana desconocido:", kind)
	return nil
end

return Blocks
