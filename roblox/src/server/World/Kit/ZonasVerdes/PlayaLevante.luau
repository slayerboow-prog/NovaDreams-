-- Vóley Playa de Levante (zona 6, Costa de Levante; shared/OcioSitios «Playa»).
--
--   * Explanada de arena con 2 pistas de vóley playa (tag OcioVolleyCourt): red y postes fijos; el
--     cartel «Jugar · Vóley» (Services/ZonasDeporteService) empieza un partido libre 2 contra 2 con
--     VolleyService en esa pista (no solo en la historia).
--   * 2 chiringuitos con bebidas y algo de picar (tag FoodStand + FoodId: FoodService).
--   * Tumbonas con sombrilla (tag Bench: descansar sube la energía) y farolas para la noche.
-- Coordenadas del sitio: X hacia el este (el mar), Z hacia el sur.

local Builder = require(script.Parent.Parent.Parent.Builder)
local Kit = require(script.Parent.OcioKit)
local Sitios = require(game:GetService("ReplicatedStorage").Shared.OcioSitios)
local Feria = require(game:GetService("ReplicatedStorage").Shared.OcioFeria)

local PlayaLevante = {}

local rgb = Color3.fromRGB
local EAST, WEST = Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0)

PlayaLevante.COURT = { Half = 16, Width = 16, NetHeight = 7.5 } -- (las de Sports/VolleySim)
PlayaLevante.SAND_TOP = -0.7

local function court(parent: Instance, cf: CFrame, index: number)
	-- cf = centro de la pista a ras de arena, X a lo largo de la pista
	local m = Kit.model("PistaVoley_" .. index, parent)
	local c = PlayaLevante.COURT
	local h, w = c.Half, c.Width
	local area = Kit.decor(m, "VolleyCourt", Vector3.new(2 * h + 4, 0.05, w + 4), cf * CFrame.new(0, 0.03, 0), rgb(236, 220, 180), Enum.Material.Sand, { Tags = { "OcioVolleyCourt" }, Attributes = { Court = index } })
	area.CastShadow = false
	local blue = rgb(40, 120, 230)
	for _, l in { { 2 * h, 0.3, 0, -w / 2 }, { 2 * h, 0.3, 0, w / 2 }, { 0.3, w, -h, 0 }, { 0.3, w, h, 0 } } do
		Kit.decor(m, "Line", Vector3.new(l[1], 0.06, l[2]), cf * CFrame.new(l[3], 0.08, l[4]), blue)
	end
	for _, z in { -w / 2 - 0.6, w / 2 + 0.6 } do
		Kit.part(m, "Poste", Vector3.new(0.35, c.NetHeight + 0.6, 0.35), cf * CFrame.new(0, (c.NetHeight + 0.6) / 2, z), rgb(230, 230, 235), Enum.Material.Metal)
	end
	Kit.decor(m, "Red", Vector3.new(0.1, 3, w + 1.2), cf * CFrame.new(0, c.NetHeight - 1.5, 0), rgb(20, 20, 24), Enum.Material.Fabric, { Transparency = 0.55 })
	Kit.decor(m, "Cinta", Vector3.new(0.12, 0.25, w + 1.2), cf * CFrame.new(0, c.NetHeight, 0), rgb(245, 245, 245))
	return area
end

local function chiringuito(parent: Instance, cf: CFrame, bar: { [string]: any })
	-- cf = centro, mirando hacia los clientes
	local m = Kit.model(bar.Id, parent)
	Kit.part(m, "Deck", Vector3.new(16, 0.8, 10), cf * CFrame.new(0, 0.4, 1), rgb(170, 125, 80), Enum.Material.WoodPlanks)
	for _, x in { -7.5, 7.5 } do
		for _, z in { -3.5, 5.5 } do
			Kit.part(m, "Post", Vector3.new(0.6, 9, 0.6), cf * CFrame.new(x, 5.2, z), rgb(140, 100, 60), Enum.Material.Wood)
		end
	end
	Kit.part(m, "Roof", Vector3.new(18, 1.2, 12.5), cf * CFrame.new(0, 10, 1), rgb(210, 180, 110), Enum.Material.Fabric)
	Kit.part(m, "Bar", Vector3.new(14, 3.6, 2), cf * CFrame.new(0, 2.6, -3), rgb(120, 180, 200), Enum.Material.WoodPlanks)
	Kit.decor(m, "Shelf", Vector3.new(12, 4, 1), cf * CFrame.new(0, 3.2, 5.2), rgb(90, 70, 50), Enum.Material.Wood)
	local sign = Kit.decor(m, "Name", Vector3.new(12, 1.6, 0.3), cf * CFrame.new(0, 11.4, -5), rgb(30, 110, 150))
	Builder.sign(sign, bar.Name, Enum.NormalId.Front, Kit.WHITE)
	for i, foodId in bar.Foods do
		Kit.part(m, "Food_" .. foodId, Vector3.new(1.6, 1, 1.6), cf * CFrame.new(-4 + (i - 1) * 4, 4.9, -3), rgb(250, 250, 250), Enum.Material.SmoothPlastic, { Tags = { "FoodStand" }, Attributes = { FoodId = foodId } })
	end
	Kit.bulb(m, cf * CFrame.new(0, 9.1, -3), Kit.WARM, true, 0.6)
end

function PlayaLevante.build(parent: Instance): Model
	local site = Sitios.get("Playa") :: any
	local root = Builder.model("Ocio_Playa", parent)
	root:SetAttribute("Zone", site.Zone)
	local base = Sitios.cframe("Playa")
	local function at(x: number, z: number, dir: Vector3?): CFrame
		local p = base * CFrame.new(x, 0, z)
		return if dir then Builder.facing(p.Position, dir) else p
	end
	local top = PlayaLevante.SAND_TOP
	Kit.slab(root, "Arena", at(0, 0), site.Size[1] - 4, site.Size[2] - 4, rgb(232, 214, 172), Enum.Material.Sand, top)

	-- Pistas de vóley (a lo largo de X) al oeste
	for i, z in { -22, 22 } do
		court(root, at(-38, z) * CFrame.new(0, top + 1, 0), i)
	end

	-- Chiringuitos en el centro, mirando a las pistas
	for i, bar in Feria.BeachBars do
		chiringuito(root, at(28, if i == 1 then -24 else 24, WEST) * CFrame.new(0, top + 1, 0), bar)
	end

	-- Tumbonas y sombrillas mirando al mar (este)
	local relax = Builder.model("Tumbonas", root)
	local colors = { rgb(240, 90, 80), rgb(60, 150, 220), rgb(250, 200, 60), rgb(90, 190, 120) }
	for i = 0, 7 do
		local z = -38 + i * 10.5
		Kit.lounger(relax, at(80, z, EAST) * CFrame.new(0, top + 1, 0), colors[i % 4 + 1])
		if i % 2 == 0 then
			local u = at(80, z + 5.2) * CFrame.new(0, top + 1, 0)
			Kit.pole(relax, "UmbrellaPole", 7, 0.25, u, Kit.WHITE)
			Kit.disc(relax, "Umbrella", 7, 0.4, u * CFrame.new(0, 7, 0), colors[(i + 1) % 4 + 1], Enum.Material.Fabric)
		end
	end

	-- Farolas de la explanada
	for _, p in { { -70, -48 }, { -70, 48 }, { -4, -48 }, { -4, 48 }, { 60, -48 }, { 60, 48 } } do
		local cf = at(p[1], p[2]) * CFrame.new(0, top + 1, 0)
		Kit.pole(root, "LampPost", 9, 0.4, cf, Kit.DARK, true)
		Kit.bulb(root, cf * CFrame.new(0, 9.3, 0), Kit.WARM, true, 1)
	end
	local info = Kit.sign(root, at(-92, 0, WEST) * CFrame.new(0, top + 1, 0), "🏐 VÓLEY PLAYA · CHIRINGUITOS", 10, 2.4, rgb(30, 110, 150))
	info.Name = "PlayaInfo"
	return root
end

return PlayaLevante
