-- Accesos: el camino que une cada sitio de ocio de las zonas verdes (shared/OcioSitios) con la calle.
--
-- Los sitios se colocaron en solares libres del campo (la máscara de huellas), separados de la calle
-- para no pisar su acera: el mercadillo, el polideportivo del campus, el vóley playa o el karting
-- quedaban como islas en la hierba, sin nada que llegara hasta ellos. Aquí se busca la acera más
-- cercana a cada sitio y se pone un camino de baldosas hasta ella, recto o en L (Model
-- «Acceso_<Id>», atributo AccessFor = el Id del sitio).
--
-- Va FUERA del modelo del sitio (las piezas del sitio no salen de su rectángulo: test-ocio) y lo
-- llama TownBuilder después de Kit/ZonasVerdes/Ocio. Sin math.random: no cambia nada más del mapa.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Builder = require(script.Parent.Parent.Parent.Builder)
local Roads = require(script.Parent.Parent.Roads)
local CityPlan = require(ReplicatedStorage.Shared.CityPlan)
local OcioSitios = require(ReplicatedStorage.Shared.OcioSitios)

local Accesos = {}

Accesos.WIDTH = 10
Accesos.MAX = 480 -- como mucho, un camino de este largo

-- ¿El punto está ya en la acera o la calzada de alguna calle o carretera?
local function atStreet(x: number, z: number, streets: { any }): boolean
	for _, r in streets do
		local along, across = if r.Axis == "X" then x else z, if r.Axis == "X" then z else x
		if math.abs(across - r.At) <= 20 and along >= r.From - 20 and along <= r.To + 20 then
			return true
		end
	end
	for _, seg in Roads.segments() do
		local kind = Roads.Kinds[seg.Kind]
		if CityPlan.segmentDistance(x, z, seg.A.X, seg.A.Z, seg.B.X, seg.B.Z) <= kind.Road / 2 + kind.Walk then
			return true
		end
	end
	return false
end

-- El camino de un sitio: lista de tramos { A, B } (vacía si ya toca la acera; nil si no hay calle a
-- menos de MAX). Se busca el punto de acera más cercano al sitio; si queda enfrente de uno de sus
-- lados, el camino va recto; si no, en L desde la esquina más cercana.
function Accesos.route(site: OcioSitios.Sitio, streets: { any }): { { Vector3 } }?
	local cx, cz = site.Center[1], site.Center[2]
	local hx, hz = site.Size[1] / 2, site.Size[2] / 2
	local x0, x1, z0, z1 = cx - hx, cx + hx, cz - hz, cz + hz
	local best, bestD = nil, math.huge
	local STEP = 8
	for x = x0 - Accesos.MAX, x1 + Accesos.MAX, STEP do
		for z = z0 - Accesos.MAX, z1 + Accesos.MAX, STEP do
			local dx = math.max(x0 - x, 0, x - x1)
			local dz = math.max(z0 - z, 0, z - z1)
			local d = math.sqrt(dx * dx + dz * dz)
			if d > 0 and d < bestD and atStreet(x, z, streets) then
				best, bestD = Vector3.new(x, 0, z), d
			end
		end
	end
	if not best then
		return nil
	end
	if bestD <= 4 then
		return {}
	end
	local q = best :: Vector3
	-- Avanza de a hacia b (en recto) hasta pisar la acera
	local function reach(a: Vector3, dir: Vector3, limit: number): Vector3
		for d = 0, limit + STEP * 2, 1 do
			local p = a + dir * d
			if atStreet(p.X, p.Z, streets) then
				return p
			end
		end
		return a + dir * limit
	end
	if q.X >= x0 and q.X <= x1 then
		local a = Vector3.new(q.X, 0, if q.Z < z0 then z0 else z1)
		local dir = Vector3.new(0, 0, if q.Z < z0 then -1 else 1)
		return { { a, reach(a, dir, math.abs(q.Z - a.Z)) } }
	elseif q.Z >= z0 and q.Z <= z1 then
		local a = Vector3.new(if q.X < x0 then x0 else x1, 0, q.Z)
		local dir = Vector3.new(if q.X < x0 then -1 else 1, 0, 0)
		return { { a, reach(a, dir, math.abs(q.X - a.X)) } }
	end
	-- En L: de la esquina más cercana, primero en X y luego en Z
	local corner = Vector3.new(if q.X < x0 then x0 else x1, 0, if q.Z < z0 then z0 + 6 else z1 - 6)
	local bend = Vector3.new(q.X, 0, corner.Z)
	local dir = Vector3.new(0, 0, if q.Z < corner.Z then -1 else 1)
	return { { corner, bend + Vector3.new(if q.X < x0 then -Accesos.WIDTH / 2 else Accesos.WIDTH / 2, 0, 0) }, { bend, reach(bend, dir, math.abs(q.Z - bend.Z)) } }
end

function Accesos.build(world: Instance, streets: { any }): { Model }
	local out = {}
	local folder = world:FindFirstChild("ZonasOcio") or world
	for _, site in OcioSitios.List do
		local route = Accesos.route(site, streets)
		if route and #route > 0 then
			local m = Builder.model("Acceso_" .. site.Id, folder)
			m:SetAttribute("AccessFor", site.Id)
			for _, seg in route do
				local a, b = seg[1], seg[2]
				local dir = b - a
				if dir.Magnitude < 1 then
					continue
				end
				-- Camino de baldosas a ras del campo (el terreno está en Y = -1; arriba en -0.75)
				Builder.part({
					Name = "CaminoAcceso",
					Size = Vector3.new(Accesos.WIDTH, 1.1, dir.Magnitude + 2),
					CFrame = Builder.facing((a + b) / 2 + Vector3.new(0, -0.75 - 0.55, 0), dir),
					Color = Color3.fromRGB(200, 190, 170),
					Material = Enum.Material.Pavement,
					CastShadow = false,
					Parent = m,
				})
			end
			table.insert(out, m)
		end
	end
	return out
end

return Accesos
