-- Skatepark de la Ribera (zona 10, Ribera del Puerto; shared/OcioSitios «Skate»).
--
--   * Losa de hormigón con rampas de salto (tag SkateRamp + Launch: al pasar el borde alto con
--     velocidad, el monopatín sale volando: Controllers/OcioClient), una caja con dos rampas, un bowl
--     (rampas hacia dentro con esquinas), barandillas y un bordillo para hacer grind (tag SkateRail) y
--     una línea de baches (pump track) para monopatín y bici.
--   * Punto de monopatines gratis (tag RentalStation: VehicleService), panel del «Reto de trucos» (tag
--     OcioSkateChallenge: Services/SkateService), focos para la noche, bancos y muro de grafitis.
-- Las rampas tienen como mucho ~25° de pendiente: el monopatín sube cuestas de hasta 28°
-- (Controllers/Driving), así que se suben todas.
-- Coordenadas del sitio: X hacia el este, Z hacia el sur (la calle queda al norte).

local Builder = require(script.Parent.Parent.Parent.Builder)
local Kit = require(script.Parent.OcioKit)
local Sitios = require(game:GetService("ReplicatedStorage").Shared.OcioSitios)

local Skatepark = {}

local rgb = Color3.fromRGB
local NORTH, SOUTH, EAST, WEST = Vector3.new(0, 0, -1), Vector3.new(0, 0, 1), Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0)
local CONCRETE = rgb(178, 178, 172)
local RAMP = rgb(196, 194, 186)

Skatepark.FLOOR_TOP = -0.5

-- Rampa (cuña): sube hacia `up` (el borde alto queda en esa dirección). w = ancho, h = alto, l = largo
local function ramp(parent: Instance, cf: CFrame, up: Vector3, w: number, h: number, l: number, launch: boolean, name: string?): BasePart
	-- WedgePart: la cara inclinada mira a -Z local (frente) y el borde alto está en +Z local. Con
	-- Builder.facing(p, -up), +Z local = up.
	local wedge = Kit.part(parent, name or "Ramp", Vector3.new(w, h, l), Builder.facing(cf.Position + Vector3.new(0, h / 2, 0), -up), RAMP, Enum.Material.Concrete, { ClassName = "WedgePart", Tags = { "SkateRamp" } })
	wedge:SetAttribute("Launch", launch)
	return wedge
end

local function rail(parent: Instance, cf: CFrame, length: number, along: Vector3)
	local p = cf.Position
	local bar = Kit.part(parent, "Rail", Vector3.new(0.5, 0.35, length), Kit.along(p + Vector3.new(0, 1.2, 0), along), rgb(200, 205, 210), Enum.Material.Metal, { Tags = { "SkateRail" } })
	for _, s in { -1, 1 } do
		Kit.decor(parent, "RailLeg", Vector3.new(0.3, 1.0, 0.3), bar.CFrame * CFrame.new(0, -0.65, s * (length / 2 - 1)), rgb(60, 60, 64), Enum.Material.Metal)
	end
end

function Skatepark.build(parent: Instance): Model
	local site = Sitios.get("Skate") :: any
	local root = Builder.model("Ocio_Skate", parent)
	root:SetAttribute("Zone", site.Zone)
	local base = Sitios.cframe("Skate")
	local F = Skatepark.FLOOR_TOP
	local function at(x: number, z: number, dir: Vector3?): CFrame
		local p = base * CFrame.new(x, 1 + F, z) -- (a ras de la losa)
		return if dir then Builder.facing(p.Position, dir) else p
	end

	Kit.slab(root, "Losa", base, site.Size[1] - 4, site.Size[2] - 4, CONCRETE, Enum.Material.Concrete, F)

	-- Rampas de salto (dos líneas: de oeste a este y de vuelta)
	local jumps = Builder.model("Rampas", root)
	for _, z in { -30, 30 } do
		ramp(jumps, at(-38, z), EAST, 10, 2.8, 8, true, "Kicker")
		ramp(jumps, at(14, z), WEST, 10, 2.8, 8, true, "Kicker")
	end

	-- Caja con rampa a cada lado (funbox) en el centro: se sube, se cruza y se baja
	local box = Builder.model("Funbox", root)
	Kit.part(box, "FunboxTop", Vector3.new(12, 2.4, 12), at(-12, 0) * CFrame.new(0, 1.2, 0), RAMP, Enum.Material.Concrete, { Tags = { "SkateRamp" } })
	ramp(box, at(-22, 0), EAST, 12, 2.4, 8, false, "FunboxRamp")
	ramp(box, at(-2, 0), WEST, 12, 2.4, 8, true, "FunboxRamp")
	Kit.decor(box, "Coping", Vector3.new(0.3, 0.3, 12), at(-6.05, 0) * CFrame.new(0, 2.45, 0), rgb(200, 205, 210), Enum.Material.Metal)

	-- Bowl al oeste: suelo hundido rodeado de rampas que suben hacia fuera (y esquinas)
	local bowl = Builder.model("Bowl", root)
	local bx, bz, inner, deep, h = -56, 0, 20, 7, 3
	Kit.decor(bowl, "BowlFloor", Vector3.new(inner, 0.06, inner), at(bx, bz) * CFrame.new(0, 0.03, 0), rgb(120, 160, 190), Enum.Material.Concrete)
	for _, d in { { NORTH, 0, -1 }, { SOUTH, 0, 1 }, { WEST, -1, 0 }, { EAST, 1, 0 } } do
		local off = inner / 2 + deep / 2
		local dir = d[1] :: Vector3
		local wedge = ramp(bowl, at(bx + d[2] * off, bz + d[3] * off), dir, inner, h, deep, true, "BowlWall")
		wedge.Color = rgb(150, 180, 205)
		Kit.decor(bowl, "BowlCoping", Vector3.new(inner, 0.3, 0.3), Builder.facing((at(bx + d[2] * (off + deep / 2), bz + d[3] * (off + deep / 2)) * CFrame.new(0, h + 0.1, 0)).Position, dir), rgb(200, 205, 210), Enum.Material.Metal)
	end
	for _, c in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		local off = inner / 2 + deep / 2
		-- Esquinas macizas a la altura del borde (se patina por los cuatro lados, no por las esquinas)
		Kit.part(bowl, "BowlCorner", Vector3.new(deep, h, deep), at(bx + c[1] * off, bz + c[2] * off) * CFrame.new(0, h / 2, 0), rgb(150, 180, 205), Enum.Material.Concrete)
	end

	-- Barandillas y bordillo para hacer grind
	local rails = Builder.model("Barandillas", root)
	rail(rails, at(-12, -40), 20, EAST)
	rail(rails, at(-12, 40), 20, EAST)
	Kit.part(rails, "Ledge", Vector3.new(2.2, 1.3, 18), Kit.along((at(30, 0) * CFrame.new(0, 0.65, 0)).Position, NORTH), rgb(150, 150, 146), Enum.Material.Concrete, { Tags = { "SkateRail" } })

	-- Línea de baches (pump track) al este, de norte a sur
	local pump = Builder.model("PumpTrack", root)
	for k = 0, 5 do
		local z = -36 + k * 13
		ramp(pump, at(56, z - 2.6), SOUTH, 8, 1.2, 5.2, false, "Roller")
		ramp(pump, at(56, z + 2.6), NORTH, 8, 1.2, 5.2, false, "Roller")
	end

	-- Monopatines gratis (VehicleService: «Coger monopatín»), reto de trucos, focos, bancos y grafitis
	local rental = Kit.model("PuntoMonopatines", root)
	Kit.part(rental, "Totem", Vector3.new(1.4, 5, 0.8), at(-30, -50) * CFrame.new(0, 2.5, 0), rgb(30, 150, 80), Enum.Material.SmoothPlastic)
	Kit.decor(rental, "BoardRack", Vector3.new(5, 1.2, 0.6), at(-26, -50) * CFrame.new(0, 0.6, 0), Kit.METAL, Enum.Material.Metal)
	Kit.decor(rental, "Board", Vector3.new(1.2, 0.2, 3.2), at(-26, -50) * CFrame.new(0, 1.4, 0) * CFrame.Angles(0, math.rad(90), 0), rgb(220, 70, 60), Enum.Material.Wood)
	Kit.part(rental, "RentalPoint", Vector3.new(2, 2, 2), at(-27, -50) * CFrame.new(0, 2.5, 0), Kit.WHITE, nil, { Transparency = 1, CanCollide = false, CanQuery = false, Tags = { "RentalStation" } })
	local totemSign = rental:FindFirstChild("Totem") :: BasePart
	Builder.sign(totemSign, "MONOPATÍN\nGRATIS", Enum.NormalId.Front)
	Builder.sign(totemSign, "MONOPATÍN\nGRATIS", Enum.NormalId.Back)

	local challenge = Kit.sign(root, at(6, -50, NORTH), "🛹 RETO DE TRUCOS\n2500 puntos en 60 s", 9, 4, rgb(40, 30, 60))
	challenge.Name = "SkateChallenge"
	challenge:AddTag("OcioSkateChallenge")

	for _, p in { { -70, -50 }, { 70, -50 }, { -70, 50 }, { 70, 50 } } do
		Kit.floodlight(root, at(p[1], p[2]), 16)
	end
	Kit.bench(root, at(40, -50, SOUTH))
	Kit.bench(root, at(40, 50, NORTH))
	local wall = Kit.part(root, "GraffitiWall", Vector3.new(30, 6, 1), at(-40, 51) * CFrame.new(0, 3, 0), rgb(80, 160, 200), Enum.Material.Brick)
	Builder.sign(wall, "SKATEPARK DE LA RIBERA", Enum.NormalId.Back, rgb(250, 220, 60))
	Builder.sign(wall, "SKATEPARK DE LA RIBERA", Enum.NormalId.Front, rgb(250, 90, 160))
	return root
end

return Skatepark
