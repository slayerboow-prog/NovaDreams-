-- CityDetail: el detalle fino de la ciudad (gráficos fase 2, manteniendo el estilo Roblox).
--
--   * Tejados: hiladas de teja con relieve sobre los faldones inclinados (piezas finas solapadas y un
--     poco levantadas por abajo, como las tejas de verdad), cumbrera redonda, tablas de remate en los
--     hastiales y canalones con bajante.
--   * Fachadas: zócalo de piedra, alféizares corridos, cornisa bajo el tejado y portal con marco,
--     dintel y escalón.
--   * Calle: desgaste del asfalto (parches, manchas de aceite y grietas finas) y rejillas en los
--     alcorques de los árboles.
--   * Farolas: base con pie de fundición y tornapuntas bajo el brazo.
--
-- Rendimiento: todo es decorativo (Builder.decor: sin colisiones ni consultas; los planos y pequeños
-- sin sombra) y casi todo lleva la etiqueta CityDetail: con el nivel gráfico Bajo el cliente lo
-- esconde (Controllers/MaterialDetail), y queda la ciudad de antes. El azar sale de la posición (no
-- de math.random), así el resto del mapa no cambia al añadir o quitar detalles.

local Builder = require(script.Parent.Parent.Builder)

local CityDetail = {}

local rgb = Color3.fromRGB
local V3 = Vector3.new
local TAG = "CityDetail"
CityDetail.Tag = TAG

-- Medidas de las tejas (las pruebas las usan)
CityDetail.TILE_ROW = 1.9 -- separación entre hiladas a lo largo del faldón
CityDetail.TILE_TILT = math.rad(7) -- cuánto se levanta el borde de abajo de cada hilada

CityDetail.Count = 0 -- piezas puestas (para las pruebas y el informe)

-- Azar fijo según el sitio: 0..1 (cada "salt" da un número distinto e independiente)
function CityDetail.hash(x: number, z: number, salt: number): number
	local v = math.sin(x * 12.9898 + z * 78.233 + salt * 37.719) * 43758.5453
	v -= math.floor(v)
	local w = math.sin(v * 91.345 + salt * 3.117 + x * 0.013) * 24634.6345
	return w - math.floor(w)
end
local hash = CityDetail.hash

-- Pieza de adorno con la etiqueta de detalle (el nivel Bajo la esconde)
local function bit(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
	local props = { Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = parent, Tags = { TAG } }
	for k, v in extra or {} do
		props[k] = v
	end
	CityDetail.Count += 1
	return Builder.decor(props)
end
CityDetail.bit = bit

-- Cilindro tumbado a lo largo de X local
local function rod(parent: Instance, name: string, length: number, diameter: number, cf: CFrame, color: Color3, material: Enum.Material?): BasePart
	return bit(parent, name, V3(length, diameter, diameter), cf, color, material, { Shape = Enum.PartType.Cylinder })
end

---------------------------------------------------------------------
-- Tejados
---------------------------------------------------------------------

-- Marco del faldón de una WedgePart: Y = normal hacia fuera, Z = sube por la pendiente (de alero a
-- cumbrera), origen en el centro del faldón. Devuelve también su largo inclinado.
function CityDetail.slopeFrame(wedgeCf: CFrame, size: Vector3): (CFrame, number)
	local theta = math.atan2(size.Y, size.Z)
	return wedgeCf * CFrame.Angles(-theta, 0, 0), math.sqrt(size.Y * size.Y + size.Z * size.Z)
end

-- Hiladas de teja sobre el faldón de una WedgePart (la del tejado sigue debajo: colisiona y arde).
-- Cada hilada es una lámina fina, más larga que la separación (se solapan) y girada un poco para
-- que su borde de abajo sobresalga: de lejos, rayas de sombra; de cerca, el escalón de cada fila.
function CityDetail.tiles(parent: Instance, wedgeCf: CFrame, size: Vector3, color: Color3, material: Enum.Material): number
	local frame, length = CityDetail.slopeFrame(wedgeCf, size)
	local rows = math.max(2, math.floor(length / CityDetail.TILE_ROW + 0.5))
	local step = length / rows
	local p = wedgeCf.Position
	for i = 0, rows - 1 do
		local z = -length / 2 + step * (i + 0.5)
		-- Cada hilada con su tono (unas más tostadas que otras, como la teja vieja)
		local r = hash(p.X + i * 3.1, p.Z - i * 1.7, 31)
		local tone = if r < 0.35 then color:Lerp(Color3.new(0, 0, 0), 0.08) elseif r > 0.8 then color:Lerp(rgb(230, 200, 170), 0.07) else color
		bit(parent, "RoofTiles", V3(size.X, 0.24, step + 0.4), frame * CFrame.new(0, 0.16, z) * CFrame.Angles(CityDetail.TILE_TILT, 0, 0), tone, material, { CastShadow = true })
	end
	return rows
end

-- Tablas de remate de un faldón en sus dos extremos (tapan el canto de las hiladas)
function CityDetail.verges(parent: Instance, wedgeCf: CFrame, size: Vector3, color: Color3)
	local frame, length = CityDetail.slopeFrame(wedgeCf, size)
	for _, sx in { -1, 1 } do
		bit(parent, "Verge", V3(0.35, 0.75, length + 0.3), frame * CFrame.new(sx * (size.X / 2 + 0.02), 0.12, 0), color, Enum.Material.Wood)
	end
end

-- Hastial: triángulo del color de la pared en un extremo del faldón (x = desplazamiento lateral)
function CityDetail.gable(parent: Instance, wedgeCf: CFrame, size: Vector3, x: number, color: Color3, material: Enum.Material)
	bit(parent, "GableWall", V3(0.12, size.Y, size.Z), wedgeCf * CFrame.new(x, 0, 0), color, material)
end

-- Cumbrera de tejas redondas (a lo largo de X local de cf)
function CityDetail.ridge(parent: Instance, cf: CFrame, length: number, color: Color3, material: Enum.Material)
	rod(parent, "RidgeTiles", length, 0.95, cf, color:Lerp(Color3.new(0, 0, 0), 0.18), material)
end

-- Canalón a lo largo del alero (cf en el borde del alero, X a lo largo) y bajantes hasta el suelo
-- (drop = altura del canalón) en las esquinas del muro: pipeX a cada lado y pipeZ hacia el muro
function CityDetail.gutter(parent: Instance, cf: CFrame, length: number, drop: number, pipeX: number, pipeZ: number, color: Color3?)
	local c = color or rgb(196, 198, 202)
	rod(parent, "Gutter", length, 0.45, cf, c, Enum.Material.Metal)
	if drop > 2 then
		for _, sx in { -1, 1 } do
			local top = cf * CFrame.new(sx * pipeX, 0, pipeZ)
			bit(parent, "Downpipe", V3(drop, 0.32, 0.32), top * CFrame.new(0, -drop / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), c, Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
		end
	end
end

-- Tejado a dos aguas completo para un bloque de tejado plano (Kit/Lite): faldones de teja (los que
-- chocan se llaman Roof, como los demás tejados), hastiales, tejas con relieve, remates, cumbrera y
-- canalones. cf = centro de la azotea (y = arriba de la cornisa), cumbrera a lo largo de X.
-- wallTop = altura del alero sobre el suelo (para las bajantes). Devuelve la altura de la cumbrera.
function CityDetail.pitchedRoof(parent: Instance, cf: CFrame, w: number, d: number, wallTop: number, roofColor: Color3, wallColor: Color3, wallMaterial: Enum.Material, trimColor: Color3): number
	local rh = math.clamp(d * 0.22, 4, 9)
	local size = V3(w + 0.6, rh, d / 2 + 0.6) -- (vuela un poco más que la cornisa)
	for _, side in { -1, 1 } do
		local wedgeCf = cf * CFrame.new(0, rh / 2, side * size.Z / 2) * (if side > 0 then CFrame.Angles(0, math.pi, 0) else CFrame.identity)
		Builder.part({ ClassName = "WedgePart", Name = "Roof", Size = size, CFrame = wedgeCf, Color = roofColor, Material = Enum.Material.ClayRoofTiles, Parent = parent })
		CityDetail.Count += 1
		for _, sx in { -1, 1 } do
			CityDetail.gable(parent, wedgeCf, size, sx * (size.X / 2 + 0.06), wallColor, wallMaterial)
		end
		CityDetail.tiles(parent, wedgeCf, size, roofColor, Enum.Material.ClayRoofTiles)
		CityDetail.verges(parent, wedgeCf, size, trimColor)
		CityDetail.gutter(parent, cf * CFrame.new(0, -0.1, side * (size.Z + 0.2)), size.X, wallTop, size.X / 2 - 0.6, 0)
	end
	CityDetail.ridge(parent, cf * CFrame.new(0, rh + 0.05, 0), size.X + 0.2, roofColor, Enum.Material.ClayRoofTiles)
	return rh
end

---------------------------------------------------------------------
-- Fachadas (face = marco de la fachada a ras de suelo, mirando hacia fuera en -Z)
---------------------------------------------------------------------

local STONE = { rgb(150, 144, 134), rgb(128, 124, 118), rgb(170, 160, 142), rgb(112, 108, 104) }
function CityDetail.stoneColor(x: number, z: number): Color3
	return STONE[math.floor(hash(x, z, 41) * #STONE) % #STONE + 1]
end

-- Zócalo de piedra a lo largo de una fachada (de x0 a x1), de alto h
function CityDetail.plinth(parent: Instance, face: CFrame, x0: number, x1: number, h: number, color: Color3)
	if x1 - x0 < 0.4 then
		return
	end
	bit(parent, "StonePlinth", V3(x1 - x0, h, 0.35), face * CFrame.new((x0 + x1) / 2, h / 2, -0.17), color, Enum.Material.Cobblestone)
	bit(parent, "PlinthCap", V3(x1 - x0, 0.22, 0.5), face * CFrame.new((x0 + x1) / 2, h + 0.11, -0.22), color:Lerp(rgb(230, 226, 216), 0.35), Enum.Material.Limestone)
end

-- Cornisa bajo el tejado a la altura y, de largo length (una pieza que vuela sobre el muro)
function CityDetail.cornice(parent: Instance, face: CFrame, length: number, y: number, color: Color3, material: Enum.Material?)
	bit(parent, "Cornice", V3(length + 0.3, 0.7, 0.7), face * CFrame.new(0, y, -0.35), color, material or Enum.Material.Limestone)
end

-- Portal: marco, dintel y escalón delante de una puerta (x = centro, w y h = hueco de la puerta).
-- El escalón es fino y no choca: se pasa por encima sin tropezar (las puertas y los interiores
-- siguen igual).
function CityDetail.portal(parent: Instance, face: CFrame, x: number, w: number, h: number, frameColor: Color3, stone: Color3)
	for _, sx in { -1, 1 } do
		bit(parent, "DoorJamb", V3(0.6, h + 0.3, 0.5), face * CFrame.new(x + sx * (w / 2 + 0.3), (h + 0.3) / 2, -0.25), frameColor, Enum.Material.Limestone)
	end
	bit(parent, "DoorLintel", V3(w + 1.8, 0.8, 0.6), face * CFrame.new(x, h + 0.55, -0.3), frameColor, Enum.Material.Limestone)
	bit(parent, "DoorStep", V3(w + 1.6, 0.18, 1.6), face * CFrame.new(x, 0.09, -0.8), stone, Enum.Material.Slate)
end

---------------------------------------------------------------------
-- Calle
---------------------------------------------------------------------

-- Desgaste del asfalto en un tramo de calle (lo llama Kit/Street). point(u, v, y) → posición;
-- free(u) → ¿se puede pintar aquí? (fuera de bocacalles y pasos de cebra). Piezas planísimas por
-- debajo de las marcas viales: parches de asfalto nuevo, manchas de aceite donde aparcan los coches
-- y grietas finas en zigzag.
function CityDetail.roadWear(parent: Instance, axis: string, u0: number, u1: number, point: (number, number, number) -> Vector3, RW: number, roadTop: number, free: (number) -> boolean)
	local yaw0 = if axis == "X" then 0 else math.pi / 2 -- X local a lo largo de la calle
	local function flat(u: number, v: number, yaw: number): CFrame
		return CFrame.new(point(u, v, roadTop)) * CFrame.Angles(0, yaw0 + yaw, 0)
	end
	local u = u0 + 44
	while u <= u1 - 12 do
		local p = point(u, 0, 0)
		local r1, r2, r3 = hash(p.X, p.Z, 51), hash(p.X, p.Z, 52), hash(p.X, p.Z, 53)
		if free(u) then
			-- Parche (asfalto más nuevo y oscuro, o más viejo y gris)
			if r1 < 0.6 then
				local v = (r2 - 0.5) * (RW - 8)
				local color = if r3 < 0.5 then rgb(44, 45, 48) else rgb(86, 86, 86)
				bit(parent, "AsphaltPatch", V3(4 + r3 * 6, 0.02, 2.6 + r2 * 3), flat(u + (r2 - 0.5) * 10, v, (r1 - 0.3) * 0.12) * CFrame.new(0, 0.017, 0), color, Enum.Material.Asphalt)
			end
			-- Mancha de aceite en el carril de aparcamiento (donde se paran los coches)
			if r2 < 0.65 then
				local s = if r3 < 0.5 then 1 else -1
				local d = 1.6 + r1 * 1.6
				bit(parent, "OilStain", V3(0.02, d, d * (0.7 + r3 * 0.4)), flat(u + 12 + r3 * 8, s * (RW / 2 - 3.1 + (r1 - 0.5)), r2 * 3) * CFrame.new(0, 0.019, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(24, 24, 26), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder, Transparency = 0.35 })
			end
			-- Grieta fina en zigzag (dos o tres tramos)
			if r3 < 0.5 then
				local at = point(u - 14 + r1 * 6, (r3 * 2 - 0.5) * (RW / 2 - 3), roadTop)
				local yaw = yaw0 + (r2 - 0.5) * 1.4
				for i = 1, 2 + math.floor(r1 * 2) do
					local len = 1.6 + hash(at.X, at.Z, 54 + i) * 2.2
					local c = CFrame.new(at) * CFrame.Angles(0, yaw, 0)
					bit(parent, "Crack", V3(len, 0.02, 0.1), c * CFrame.new(len / 2, 0.021, 0), rgb(28, 28, 30), Enum.Material.SmoothPlastic)
					at = (c * CFrame.new(len, 0, 0)).Position
					yaw += (if i % 2 == 1 then 0.7 else -0.7) * (0.6 + hash(at.X, at.Z, 60 + i))
				end
			end
		end
		u += 72
	end
end

-- Rejilla de hierro de un alcorque (pit = la tierra del alcorque, a ras de la acera)
function CityDetail.treeGrate(parent: Instance, center: Vector3, side: number): BasePart
	local frame = bit(parent, "TreeGrate", V3(side - 0.3, 0.06, side - 0.3), CFrame.new(center + V3(0, 0.08, 0)), rgb(52, 54, 56), Enum.Material.DiamondPlate)
	return frame
end

---------------------------------------------------------------------
-- Farolas (cf = el de la farola, en la acera)
---------------------------------------------------------------------
function CityDetail.lamp(parent: Instance, cf: CFrame, metal: Color3)
	-- Pie de fundición (más ancho abajo) y tornapuntas bajo el brazo
	bit(parent, "LampFoot", V3(0.5, 1.7, 1.7), cf * CFrame.new(0, 0.25, 0) * CFrame.Angles(0, 0, math.rad(90)), metal:Lerp(Color3.new(0, 0, 0), 0.15), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
	bit(parent, "LampBrace", V3(0.2, 0.2, 2.4), cf * CFrame.new(0, 13.35, -0.85) * CFrame.Angles(math.rad(45), 0, 0), metal, Enum.Material.Metal)
end

return CityDetail
