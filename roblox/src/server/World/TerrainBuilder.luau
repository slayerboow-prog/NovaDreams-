-- TerrainBuilder: sustituye el suelo de piezas por terreno real de Roblox
-- (hierba con textura y colinas en el horizonte). Se ejecuta al arrancar el servidor,
-- porque el terreno no se puede guardar desde el script que genera el archivo.

local TerrainBuilder = {}

local CityPlan = require(game:GetService("ReplicatedStorage").Shared.CityPlan)

local BEACH = 70 -- ancho de la playa en la costa

-- Colores del terreno (los tiñe también el MaterialVariant de cada material si lo hay: World/UserMaterials)
TerrainBuilder.Colors = {
	Grass = Color3.fromRGB(92, 138, 58), -- lomas (con briznas 3D en los niveles Medio y Alto)
	LeafyGrass = Color3.fromRGB(82, 124, 52), -- el llano de la isla, junto a lo construido (sin briznas)
	Rock = Color3.fromRGB(124, 117, 106),
	Slate = Color3.fromRGB(100, 98, 94),
	Sand = Color3.fromRGB(232, 214, 172),
	Ground = Color3.fromRGB(130, 110, 80),
	-- Fondo del mar (v122): la arena «Sand» lleva la textura de playa del dueño (World/UserMaterials),
	-- que bajo el agua se veía marrón y plana (captura de la orilla). El fondo es «Salt» (grano blanco,
	-- sin textura de la tienda) con manchas de caliza clara: arena blanca bajo agua turquesa.
	Salt = Color3.fromRGB(236, 232, 214),
	Limestone = Color3.fromRGB(226, 220, 198),
}
-- El llano va en LeafyGrass: las briznas 3D (Terrain.Decoration) solo salen en «Grass», y así no
-- asoman por calles, aceras ni suelos (v77). En las lomas del relieve (lejos de todo) sí hay Grass.
TerrainBuilder.Flat = Enum.Material.LeafyGrass

-- Rellena un rectángulo grande en trozos (el terreno prefiere regiones no gigantes)
local function tiles(terrain: Terrain, x0: number, x1: number, z0: number, z1: number, y0: number, y1: number, material: Enum.Material)
	local step = 1024
	for x = x0, x1 - 1, step do
		for z = z0, z1 - 1, step do
			local w, d = math.min(step, x1 - x), math.min(step, z1 - z)
			terrain:FillBlock(CFrame.new(x + w / 2, (y0 + y1) / 2, z + d / 2), Vector3.new(w, y1 - y0, d), material)
		end
	end
end

-- Banda recta entre dos puntos (para el cauce del río)
local function band(terrain: Terrain, a: { number }, b: { number }, width: number, y0: number, y1: number, material: Enum.Material)
	local pa, pb = Vector3.new(a[1], 0, a[2]), Vector3.new(b[1], 0, b[2])
	local mid, dir = (pa + pb) / 2, (pb - pa)
	local cf = CFrame.lookAt(Vector3.new(mid.X, (y0 + y1) / 2, mid.Z), Vector3.new(pb.X, (y0 + y1) / 2, pb.Z) + Vector3.new(0.001, 0, 0.001))
	terrain:FillBlock(cf, Vector3.new(width, y1 - y0, dir.Magnitude + width), material)
end

local function cylinder(terrain: Terrain, x: number, z: number, radius: number, y0: number, y1: number, material: Enum.Material)
	terrain:FillCylinder(CFrame.new(x, (y0 + y1) / 2, z), y1 - y0, radius, material)
end

function TerrainBuilder.build()
	local terrain = workspace.Terrain
	-- Sin briznas de hierba: asoman por las calles y las aceras (probado en el juego, v77).
	-- (Desde un script no siempre se puede cambiar: por eso también va en default.project.json.)
	pcall(function()
		terrain.Decoration = false
	end)
	-- Colores de campo mediterráneo: verdes apagados, tierra seca y arena clara
	-- (algo más vivos que antes: de noche y con el etalonaje se veían grises)
	-- (paisaje v118, docs/paisaje/paisaje.md: verdes más vivos y profundos, como la referencia del dueño;
	-- roca gris cálida y pizarra más oscura para las laderas y los acantilados del relieve)
	for name, color in TerrainBuilder.Colors do
		terrain:SetMaterialColor((Enum.Material :: any)[name], color)
	end
	local b = CityPlan.Bounds

	-- 1) Mar alrededor de toda la isla (fondo de arena blanca: Salt, ver Colors)
	tiles(terrain, b.MinX - 800, b.MaxX + 800, b.MinZ - 800, b.MaxZ + 800, -24, -14, Enum.Material.Salt)
	tiles(terrain, b.MinX - 800, b.MaxX + 800, b.MinZ - 800, b.MaxZ + 800, -14, -2, Enum.Material.Water)

	-- 2) La isla: arena en la orilla y hierba dentro. La superficie queda en Y = -1, un poco por DEBAJO
	--    de las calles (que empiezan en Y = 0): si quedara en 0, el césped asomaría entre las piezas.
	local stripe = 16
	for z = b.MinZ, b.MaxZ, stripe do
		for _, span in CityPlan.spans(CityPlan.Coast, z + stripe / 2) do
			local x0, x1 = span[1], span[2]
			terrain:FillBlock(CFrame.new((x0 + x1) / 2, -9, z + stripe / 2), Vector3.new(x1 - x0, 16, stripe), Enum.Material.Sand)
			if x1 - x0 > BEACH * 2 then
				terrain:FillBlock(CFrame.new((x0 + x1) / 2, -5, z + stripe / 2), Vector3.new(x1 - x0 - BEACH * 2, 8, stripe), TerrainBuilder.Flat)
			end
		end
	end
	-- Islas pequeñas (la del faro, el islote y la de las gaviotas)
	for _, island in CityPlan.Islands do
		cylinder(terrain, island.X, island.Z, island.R, -16, -1, Enum.Material.Sand)
		cylinder(terrain, island.X, island.Z, island.R - 30, -9, -1, TerrainBuilder.Flat)
	end

	-- 3) Montañas y colinas (con roca en las cumbres altas)
	for _, m in CityPlan.Mountains do
		terrain:FillBall(Vector3.new(m.X, m.H - m.R, m.Z), m.R, TerrainBuilder.Flat)
		if m.Rock then
			local r = m.R * 0.42
			terrain:FillBall(Vector3.new(m.X, m.H - r * 0.9, m.Z), r, Enum.Material.Rock)
		end
	end

	-- 3b) Debajo de TODAS las calles (las de los barrios y las carreteras principales) el terreno baja
	--     a Y = -4, igual que bajo las manzanas: si no, sus cubos de 4 studs asoman por encima del
	--     asfalto. Las calzadas y aceras bajan hasta -4, así que no queda hueco. (Antes del río, para
	--     que el agua de debajo de los puentes se vuelva a poner después.)
	local Region = require(script.Parent.Region)
	local Street = require(script.Parent.Kit.Street)
	local half = Street.HALF - 0.5
	for _, road in Region.roads() do
		local length, mid = road.To - road.From, (road.From + road.To) / 2
		local size = if road.Axis == "X" then Vector3.new(length, 16, half * 2) else Vector3.new(half * 2, 16, length)
		local center = if road.Axis == "X" then Vector3.new(mid, 4, road.At) else Vector3.new(road.At, 4, mid)
		terrain:FillBlock(CFrame.new(center), size, Enum.Material.Air)
	end
	local strips, circles = require(script.Parent.Kit.Roads).footprints()
	for _, strip in strips do
		local a, c = strip.A, strip.B
		local mid = (a + c) / 2
		local dir = c - a
		local cf = CFrame.lookAt(Vector3.new(mid.X, 4, mid.Z), Vector3.new(c.X, 4, c.Z) + Vector3.new(0.001, 0, 0.001))
		terrain:FillBlock(cf, Vector3.new(strip.Width - 1, 16, dir.Magnitude), Enum.Material.Air)
	end
	for _, circle in circles do
		cylinder(terrain, circle.Position.X, circle.Position.Z, circle.Radius - 0.5, -4, 12, Enum.Material.Air)
	end

	-- 3c) Aeropuerto: tierra ganada al mar y hueco bajo sus pistas (y bajo el aeródromo de la isla)
	require(script.Parent.Kit.Airport).terrain(terrain)

	-- 4) Río: orillas de arena, cauce y agua (queda a Y = -2, dos studs bajo la orilla)
	local river = CityPlan.River
	local pts = river.Points
	for i = 1, #pts - 1 do
		band(terrain, pts[i], pts[i + 1], river.Width + 40, -9, -1, Enum.Material.Sand)
	end
	for i = 1, #pts - 1 do
		band(terrain, pts[i], pts[i + 1], river.Width, -16, 30, Enum.Material.Air)
	end
	for i = 1, #pts - 1 do
		band(terrain, pts[i], pts[i + 1], river.Width, -24, -16, Enum.Material.Sand)
		band(terrain, pts[i], pts[i + 1], river.Width, -16, -2, Enum.Material.Water)
	end

	-- 5) Lagos
	for _, lake in CityPlan.Lakes do
		cylinder(terrain, lake.X, lake.Z, lake.R + 24, -9, -1, Enum.Material.Sand)
		cylinder(terrain, lake.X, lake.Z, lake.R, -16, 20, Enum.Material.Air)
		cylinder(terrain, lake.X, lake.Z, lake.R, -24, -16, Enum.Material.Sand)
		cylinder(terrain, lake.X, lake.Z, lake.R, -16, -2, Enum.Material.Water)
	end

	-- 5b) Manchas en el campo: hierba más densa y trozos de tierra seca, para que el suelo no sea
	--     una alfombra verde lisa. ReplaceMaterial solo cambia la hierba (no toca calles, arena ni agua)
	--     y conserva la forma del terreno.
	local rng = Random.new(20240)
	for _ = 1, 700 do
		local x = rng:NextInteger(b.MinX, b.MaxX)
		local z = rng:NextInteger(b.MinZ, b.MaxZ)
		if CityPlan.inside(CityPlan.Coast, x, z) then
			local w, d = rng:NextInteger(6, 22) * 4, rng:NextInteger(6, 22) * 4
			local top = 8
			for _, m in CityPlan.Mountains do
				if (x - m.X) ^ 2 + (z - m.Z) ^ 2 < (m.R + d) ^ 2 then
					top = math.max(top, math.ceil((m.H + 8) / 4) * 4)
				end
			end
			local x0, z0 = math.floor(x / 4) * 4, math.floor(z / 4) * 4
			local region = Region3.new(Vector3.new(x0, -8, z0), Vector3.new(x0 + w, top, z0 + d))
			-- (el llano ya es LeafyGrass: las manchas son de tierra seca; con el mismo azar que antes)
			if rng:NextNumber() >= 0.65 then
				terrain:ReplaceMaterial(region, 4, TerrainBuilder.Flat, Enum.Material.Ground)
			end
		end
	end

	-- 6) Colina del mirador (Landmarks)
	require(script.Parent.Kit.Landmarks).terrain(terrain)

	-- 7) Debajo de cada manzana (casas, colegios, tiendas…) el terreno se hunde hasta Y = -4.
	-- El terreno de Roblox va en cubos de 4 studs y su superficie no es exacta: con la cara de arriba
	-- en -1, sus triángulos llegaban a asomar por los suelos (césped dentro de casa).
	-- Con -4 (borde exacto de un cubo) queda plano y 4 studs por debajo; las losas de césped lo tapan.
	local sunken = Region.blockRects()
	table.insert(sunken, { X0 = -360, X1 = 360, Z0 = -198, Z1 = -20 }) -- Valmar Centro (norte de la avenida)
	table.insert(sunken, { X0 = -360, X1 = 360, Z0 = 20, Z1 = 240 }) -- Valmar Centro (sur: parcelas de casas)
	for _, r in sunken do
		local size = Vector3.new(r.X1 - r.X0, 16, r.Z1 - r.Z0)
		terrain:FillBlock(CFrame.new((r.X0 + r.X1) / 2, 4, (r.Z0 + r.Z1) / 2), size, Enum.Material.Air)
	end

	-- 8) Bocas de metro: se vacía la roca por donde bajan las escaleras, el vestíbulo y el pozo de las
	--    escaleras mecánicas (lo último, para que nada lo vuelva a rellenar)
	require(script.Parent.Kit.MetroKit).terrain(terrain)

	-- 9) El sótano de la casa de Cosme (laboratorio, sala de portales…): sin terreno dentro
	local cosme = Region.cosmeSite()
	if cosme then
		require(script.Parent.CosmeHouse.Exterior).terrain(terrain, cosme.CFrame)
	end
end

---------------------------------------------------------------------
-- Relieve natural (paisaje v118, shared/Relief y docs/paisaje/paisaje.md)
---------------------------------------------------------------------

TerrainBuilder.ChunkStuds = 256 -- se escribe el relieve en trozos de 256 × 256 studs (64 × 64 vóxeles)
local VOXEL = 4

-- Rellena un trozo del relieve. Lee lo que hay y solo AÑADE (la superficie es la más alta de las dos):
-- las montañas de siempre, el agua, la arena, los huecos del metro… se quedan como están. Lee y escribe
-- sin soltar el hilo, para que nadie (OceanBuilder, MissionZones) cambie el trozo entremedias.
-- Devuelve los vóxeles que cambió.
function TerrainBuilder.reliefChunk(terrain: Terrain, field: any, cx: number, cz: number): number
	local Relief = require(game:GetService("ReplicatedStorage").Shared.Relief)
	local N = TerrainBuilder.ChunkStuds // VOXEL
	-- Alturas del relieve en el centro de cada columna (con un borde de 1 para la pendiente)
	local heights = table.create((N + 2) * (N + 2), 0)
	local top = 0
	for j = 0, N + 1 do
		for i = 0, N + 1 do
			local h = Relief.height(field, cx + (i - 1) * VOXEL + VOXEL / 2, cz + (j - 1) * VOXEL + VOXEL / 2)
			heights[j * (N + 2) + i + 1] = h
			top = math.max(top, h)
		end
	end
	if top < 0.5 then
		return 0
	end
	-- (sobre una montaña de siempre la superficie más alta manda: solo se escribe donde el relieve sube más)
	local y0 = -2 * VOXEL -- (desde Y = -8: la capa de la superficie de -1 y la de debajo)
	local layers = math.ceil((Relief.Base + top - y0) / VOXEL) + 1
	local region = Region3.new(Vector3.new(cx, y0, cz), Vector3.new(cx + N * VOXEL, y0 + layers * VOXEL, cz + N * VOXEL))
	local materials, occupancy = terrain:ReadVoxels(region, VOXEL)
	local changed = 0
	local Air, Water = Enum.Material.Air, Enum.Material.Water
	local cache: { [string]: Enum.Material } = {}
	local function mat(name: string): Enum.Material
		local m = cache[name]
		if not m then
			m = (Enum.Material :: any)[name]
			cache[name] = m
		end
		return m
	end
	for i = 1, N do
		local matX, occX = materials[i], occupancy[i]
		for k = 1, N do
			local h = heights[k * (N + 2) + i + 1]
			if h > 0.05 then
				local x, z = cx + (i - 1) * VOXEL + VOXEL / 2, cz + (k - 1) * VOXEL + VOXEL / 2
				local dx = heights[k * (N + 2) + i + 2] - heights[k * (N + 2) + i]
				local dz = heights[(k + 1) * (N + 2) + i + 1] - heights[(k - 1) * (N + 2) + i + 1]
				local slope = math.sqrt(dx * dx + dz * dz) / (2 * VOXEL)
				local surface = Relief.Base + h
				local skin = mat(Relief.material(h, slope, x, z))
				local under = if slope > 0.8 then Enum.Material.Rock else Enum.Material.Ground
				for y = 1, layers do
					local bottom = y0 + (y - 1) * VOXEL
					local want = math.clamp((surface - bottom) / VOXEL, 0, 1)
					if want > 0 then
						local old = occX[y][k]
						local oldMat = matX[y][k]
						if oldMat ~= Water and want > old + 0.01 then
							occX[y][k] = want
							-- la capa de arriba (y la de debajo, que asoma en las cuestas) con la piel; dentro, tierra o roca
							matX[y][k] = if surface - bottom < VOXEL * 2.2 then skin else under
							changed += 1
						elseif oldMat ~= Air and oldMat ~= Water and surface - bottom < VOXEL * 2.2 and bottom + VOXEL > Relief.Base then
							-- superficie que ya había (el pie de una montaña de siempre): mismo material del relieve
							matX[y][k] = skin
						end
					end
				end
			end
		end
	end
	if changed > 0 then
		terrain:WriteVoxels(region, VOXEL, materials, occupancy)
	end
	return changed
end

-- Escribe todo el relieve (en su hilo, trozo a trozo: no frena el arranque). field: Relief.Field.
-- Devuelve vóxeles cambiados y segundos.
function TerrainBuilder.relief(field: any, yieldEach: boolean?): (number, number)
	if not field then
		return 0, 0
	end
	local terrain = workspace.Terrain
	local started = os.clock()
	local total = 0
	local step = TerrainBuilder.ChunkStuds
	local x1 = field.MinX + (field.NX - 1) * field.Cell
	local z1 = field.MinZ + (field.NZ - 1) * field.Cell
	for cz = field.MinZ, z1 - 1, step do
		for cx = field.MinX, x1 - 1, step do
			-- (rápido: si ningún nudo del trozo tiene relieve, se salta)
			local any = false
			local i0, j0 = (cx - field.MinX) // field.Cell, (cz - field.MinZ) // field.Cell
			local span = step // field.Cell
			for j = j0, math.min(field.NZ - 1, j0 + span) do
				for i = i0, math.min(field.NX - 1, i0 + span) do
					if field.Amp[j * field.NX + i + 1] > 0 then
						any = true
						break
					end
				end
				if any then
					break
				end
			end
			if any then
				total += TerrainBuilder.reliefChunk(terrain, field, cx, cz)
				if yieldEach ~= false then
					task.wait()
				end
			end
		end
	end
	return total, os.clock() - started
end

-- Quita el suelo y el mar de piezas (solo servían para verlo en Studio)
function TerrainBuilder.removeGroundPart()
	local CollectionService = game:GetService("CollectionService")
	for _, part in CollectionService:GetTagged("EditOnly") do
		part:Destroy()
	end
end

return TerrainBuilder
