-- Forest: bosques en las lomas y sierras del relieve nuevo (shared/Relief; lo planta World/ReliefBake).
--
--   * Manchas de bosque (no árboles sueltos al azar): un ruido grande decide dónde hay bosque y dónde
--     pradera, otro más pequeño hace los claros. Pinos y encinas mezclados (más pinos arriba), más
--     ralos en las laderas empinadas, ninguno en la roca de las cumbres ni en lo llano junto a la ciudad.
--   * MUY pocas piezas por árbol (para el móvil): tronco (choca) + 1 o 2 copas (elipsoides, sin
--     choque ni consultas). Unos 2,6 piezas por árbol de media.
--   * Por grupos de Tile × Tile studs: cada grupo es un Model que se carga entero (ModelStreamingMode
--     Atomic) y de lejos se ve su versión simplificada (LevelOfDetail StreamingMesh, Builder.streamable):
--     desde el avión se ven los bosques aunque no estén cargados.
--   * Sin math.random: la posición decide todo (el mismo sitio, el mismo árbol; no cambia nada más).
--   * Las copas se llaman «Copa» (no «Leaves»): las estaciones y el viento no las recorren (son miles).

local Builder = require(script.Parent.Parent.Builder)
local Relief = require(game:GetService("ReplicatedStorage").Shared.Relief)

local Forest = {}

Forest.Spacing = 24 -- studs entre puntos de la rejilla (con desplazamiento al azar fijo)
Forest.Tile = 256 -- studs de cada grupo (Model)
Forest.MaxTrees = 5200 -- tope (rendimiento)
Forest.MinHeight = 4 -- no se planta en el pie llano de las lomas (junto a lo construido)
Forest.MaxSlope = 0.95 -- más empinado: roca, sin árboles
Forest.RockLine = 190 -- por encima, cumbre pelada

local rgb = Color3.fromRGB
local PINE = { rgb(38, 70, 40), rgb(44, 78, 44), rgb(34, 62, 38), rgb(52, 84, 46) }
local OAK = { rgb(62, 100, 46), rgb(74, 112, 50), rgb(56, 92, 44), rgb(86, 120, 56), rgb(70, 98, 40) }
local BARK = { rgb(84, 64, 48), rgb(96, 74, 54), rgb(72, 56, 44) }

-- Número fijo entre 0 y 1 para un punto y un canal
local function hash(x: number, z: number, k: number): number
	local v = math.sin(x * 12.9898 + z * 78.233 + k * 37.719) * 43758.5453
	return v - math.floor(v)
end
Forest.hash = hash

-- ¿Hay bosque aquí? (0..1: densidad)
function Forest.density(x: number, z: number, h: number, slope: number): number
	if h < Forest.MinHeight or slope > Forest.MaxSlope or h > Forest.RockLine then
		return 0
	end
	local patch = math.noise(x / 420, z / 420, 31.7) * 1.6 + math.noise(x / 130, z / 130, 7.3) * 0.6
	local d = math.clamp(0.55 + patch, 0, 1)
	-- más ralo en lo empinado y cerca de la línea de roca; el pie de la loma se va abriendo
	d *= 1 - Relief.smooth(0.55, Forest.MaxSlope, slope) * 0.8
	d *= 1 - Relief.smooth(Forest.RockLine - 40, Forest.RockLine, h)
	d *= Relief.smooth(Forest.MinHeight, Forest.MinHeight + 10, h)
	return d
end

local function ellipsoid(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3)
	local p = Builder.part({
		Name = name,
		Size = size,
		CFrame = cf,
		Color = color,
		Material = Enum.Material.LeafyGrass,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = true,
		Parent = parent,
	})
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

-- Un árbol (pino o encina) con el pie en `foot`. Devuelve cuántas piezas puso.
function Forest.tree(parent: Instance, foot: Vector3, pine: boolean, scale: number, seed: number): number
	local s = scale
	local bark = BARK[math.floor(hash(foot.X, foot.Z, seed + 1) * #BARK) + 1]
	local yaw = hash(foot.X, foot.Z, seed + 2) * math.pi * 2
	local base = CFrame.new(foot) * CFrame.Angles(0, yaw, 0)
	if pine then
		local trunkH = 9 * s
		Builder.part({ Name = "Trunk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(trunkH, 1.3 * s, 1.3 * s), CFrame = base * CFrame.new(0, trunkH / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = bark, Material = Enum.Material.Wood, CastShadow = false, CanTouch = false, Parent = parent })
		local green = PINE[math.floor(hash(foot.X, foot.Z, seed + 3) * #PINE) + 1]
		-- copa alta y estrecha (pino piñonero/carrasco visto de lejos): un huso y un remate
		ellipsoid(parent, "Copa", Vector3.new(9 * s, 20 * s, 9 * s), base * CFrame.new(0, trunkH + 6 * s, 0), green)
		if hash(foot.X, foot.Z, seed + 4) < 0.6 then
			ellipsoid(parent, "Copa", Vector3.new(5.5 * s, 9 * s, 5.5 * s), base * CFrame.new(0.6 * s, trunkH + 15 * s, -0.4 * s), green:Lerp(rgb(70, 100, 56), 0.25))
			return 3
		end
		return 2
	end
	local trunkH = 7 * s
	Builder.part({ Name = "Trunk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(trunkH, 1.6 * s, 1.6 * s), CFrame = base * CFrame.new(0, trunkH / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = bark, Material = Enum.Material.Wood, CastShadow = false, CanTouch = false, Parent = parent })
	local green = OAK[math.floor(hash(foot.X, foot.Z, seed + 3) * #OAK) + 1]
	-- encina: copa ancha y baja, con un segundo bulto de otro tono (luz y sombra)
	ellipsoid(parent, "Copa", Vector3.new(17 * s, 12 * s, 16 * s), base * CFrame.new(0, trunkH + 3.5 * s, 0), green)
	if hash(foot.X, foot.Z, seed + 4) < 0.65 then
		ellipsoid(parent, "Copa", Vector3.new(10 * s, 8 * s, 10 * s), base * CFrame.new(3.2 * s, trunkH + 6.5 * s, 1.5 * s), green:Lerp(rgb(140, 160, 80), 0.18))
		return 3
	end
	return 2
end

-- Planta los bosques del relieve. Devuelve (árboles, piezas).
function Forest.build(town: Instance, field: Relief.Field): (number, number)
	local folder = Instance.new("Folder")
	folder.Name = "Bosques"
	local tiles: { [string]: Model } = {}
	local trees, parts = 0, 0
	local S = Forest.Spacing
	local x0, z0 = field.MinX, field.MinZ
	local x1, z1 = field.MinX + (field.NX - 1) * field.Cell, field.MinZ + (field.NZ - 1) * field.Cell
	-- (de norte a sur y de oeste a este: si se llega al tope, se queda sin bosque lo último)
	for z = z0, z1, S do
		for x = x0, x1, S do
			if trees >= Forest.MaxTrees then
				break
			end
			-- (rápido: sin relieve aquí, nada)
			if Relief.amplitude(field, x, z) > Forest.MinHeight then
				local jx = x + (hash(x, z, 1) - 0.5) * S * 0.9
				local jz = z + (hash(x, z, 2) - 0.5) * S * 0.9
				local h = Relief.height(field, jx, jz)
				if h > Forest.MinHeight then
					local slope = Relief.slope(field, jx, jz)
					local d = Forest.density(jx, jz, h, slope)
					if d > 0 and hash(jx, jz, 3) < d then
						local key = math.floor(jx / Forest.Tile) .. ":" .. math.floor(jz / Forest.Tile)
						local tile = tiles[key]
						if not tile then
							tile = Builder.model("Bosque", folder)
							Builder.streamable(tile)
							tiles[key] = tile
						end
						-- más pinos arriba y en las laderas; encinas abajo
						local pineChance = 0.35 + Relief.smooth(30, 140, h) * 0.45 + math.noise(jx / 300, jz / 300, 5.1) * 0.3
						local pine = hash(jx, jz, 4) < pineChance
						local scale = 0.8 + hash(jx, jz, 5) * 0.55
						local foot = Vector3.new(jx, Relief.Base + h - 0.6 - math.min(1.8, slope * 2), jz)
						parts += Forest.tree(tile, foot, pine, scale, 10)
						trees += 1
					end
				end
			end
		end
	end
	-- Atributos de cada grupo (para el informe y las pruebas)
	for _, tile in tiles do
		local n = 0
		for _, c in tile:GetChildren() do
			if c.Name == "Trunk" then
				n += 1
			end
		end
		tile:SetAttribute("Trees", n)
	end
	folder.Parent = town
	return trees, parts
end

return Forest
