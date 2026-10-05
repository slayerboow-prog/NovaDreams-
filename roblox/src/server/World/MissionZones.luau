-- MissionZones: los sitios FUERA de la ciudad para las misiones cooperativas que vendrán, vestidos con
-- los materiales «exóticos» del Mega Pack del dueño que no pegan en una ciudad (lava, asfaltos «Lab» de
-- colores, metales de ciencia ficción, rocas de cueva y de otros planetas, textura orgánica).
--
--   * Mina de los Montes (en la montaña de -800, -3250, con la boca mirando a la Carretera de los Montes):
--     boca con marco de madera y letrero, galería con vías, traviesas, entibado y lámparas, una CÁMARA
--     DE LAVA honda (dos pozas que brillan, con luz, rocas volcánicas, vetas de mineral y una valla de
--     aviso SIN daño por ahora), otra galería y la CUEVA ALIENÍGENA (cristales con luz, rocas lunares,
--     restos de nave de metal sci-fi y un laboratorio abandonado con el suelo de los asfaltos «Lab»), y
--     al fondo de todo el MURO ORGÁNICO (la textura de carne del pack, teñida de morado: algo alienígena,
--     nada de sangre ni calaveras).
--   * Cráter de lava en la cumbre de la montaña de -2600, -3150 (poza, rocas volcánicas, valla de aviso).
--   * Cráter del meteorito en el campo de -3100, -2900 (rocas agujereadas, restos metálicos).
--   * Riscos en las laderas de las montañas de roca (estratos, acantilados, roca ígnea).
-- Nada en la ciudad (CityPlan.districtAt = nil en todos los sitios).
--
-- El terreno solo admite un variant por material: por eso todo esto son PIEZAS, con su variant pieza a
-- pieza. Las piezas nacen con el material de Roblox del variant (si el Mega Pack no carga, se ven igual de
-- bien con el material de Roblox) y, cuando World/UserMaterials ha cargado el Mega Pack en
-- ServerStorage.UserMaterials.Mega, se les pone el variant (una COPIA en MaterialService, «U_Zona_…»).
-- El terreno de la montaña se vacía (Air) donde van la galería y las cámaras.
--
-- Cada sitio es un Model con la etiqueta «ZonaMision» y los atributos Zona (id), Nombre (para enseñar),
-- Peligro («Lava» o nada) y Danio (false: las valla avisa pero aún no hace daño). Lo decorativo lleva
-- la etiqueta CityDetail (gráficos Bajo: se esconde); suelos, paredes y techos no.

local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

local MissionZones = {}

-- (CityPlan: los riscos van en las montañas de roca; en las pruebas se pone a mano)
do
	local ok, plan = pcall(function()
		return require(game:GetService("ReplicatedStorage").Shared.CityPlan)
	end)
	MissionZones.CityPlan = if ok then plan else nil
end

MissionZones.Tag = "ZonaMision"
MissionZones.Prefix = "U_Zona_"
MissionZones.MaxLights = 24

-- Variant del Mega Pack -> su BaseMaterial (docs/assets-usuario.md). Sin rotos («Lava», «Obsidian»,
-- «Skulls In Ground»…) y sin sangre, calaveras, huesos ni piel humana.
MissionZones.Variants = {
	-- Lava y roca volcánica
	["Hot Lava"] = "CrackedLava",
	["Flowing Lava"] = "CrackedLava",
	["Lava And Rock"] = "CrackedLava",
	["Columned Lava Rock"] = "CrackedLava",
	["Volcanic Rock"] = "Rock",
	["Sharp Volcanic Rock"] = "Rock",
	["Lava Rock"] = "Rock",
	-- Cueva y mina
	["Cavern Walls"] = "Rock",
	["Wet Cave Wall"] = "Rock",
	["Cavefloor Rock"] = "Rock",
	["Cavefloor"] = "Rock",
	["Cavern Deposits"] = "Rock",
	["Rough Rockface"] = "Rock",
	["Rough Rockface 2"] = "Rock",
	["Dark Rough Rock"] = "Rock",
	["Ore"] = "Rock",
	["Peacock Ore"] = "Rock",
	["Slimy Slippery Rock"] = "Rock",
	["Dusty Ground Gravel"] = "Ground",
	["Gravel Path"] = "Ground",
	["Rough Wood"] = "Wood",
	["Old Planks"] = "WoodPlanks",
	["Rusted Iron"] = "CorrodedMetal",
	["Rust Panel"] = "CorrodedMetal",
	-- Otros planetas
	["Lunar Rock"] = "Rock",
	["Lunar Rock 2"] = "Rock",
	["Layered Planetary"] = "Rock",
	["Planet Surface"] = "Ground",
	["Cratered Rock"] = "Rock",
	["Holey Rock"] = "Rock",
	["Sulfuric Rock"] = "Rock",
	["Geyser Rock"] = "Rock",
	["Windswept Wasteland"] = "Ground",
	["Glass - fractalized"] = "Ice",
	["Ice Field"] = "Ice",
	["Stylized Ice Cave Walls"] = "Ice",
	-- Metal de ciencia ficción
	["Spaceship Panels"] = "Metal",
	["Sci-fi Panel"] = "Metal",
	["Red Sci-fi Metal"] = "Metal",
	["Futuristic Panels"] = "Metal",
	["Space Cruiser Panels"] = "Metal",
	["Space Cruiser Panels 2"] = "Metal",
	["Filthy Space Panels"] = "Metal",
	["Military Panels"] = "Metal",
	["Ship Corridor"] = "Metal",
	["Space Crate"] = "Metal",
	["Solar Panels"] = "Metal",
	["Microchip 2"] = "Metal",
	["Warped Sheet Metal"] = "Metal",
	["Worn Military Siding"] = "Metal",
	-- Asfaltos «Lab» de colores: el suelo del laboratorio abandonado
	["Blue Lab"] = "Asphalt",
	["Brown Lab"] = "Asphalt",
	["Camp Lab"] = "Asphalt",
	["Clown Lab"] = "Asphalt",
	["Cyan Lab"] = "Asphalt",
	["Funhouse Lab"] = "Asphalt",
	["Green Lab"] = "Asphalt",
	["Orange Lab"] = "Asphalt",
	["Pink Lab"] = "Asphalt",
	["Pizza Lab"] = "Asphalt",
	["Purple Lab"] = "Asphalt",
	["Red Lab"] = "Asphalt",
	["White Lab"] = "Asphalt",
	["Yellow Lab"] = "Asphalt",
	-- Orgánico (solo el muro alienígena)
	["Meat"] = "Plastic",
	["Layered Fungus"] = "Plastic",
	["Melted Wax"] = "Plastic",
	["Bog"] = "Mud",
	["Tidal Pool"] = "Mud",
	["Mud With Vegetation"] = "Mud",
	-- Riscos de las montañas
	["Strata Rock"] = "Rock",
	["Strata Rock 2"] = "Rock",
	["Eroded Layered Rockface"] = "Rock",
	["Jagged Cliff"] = "Rock",
	["Layered Cliff"] = "Rock",
	["Stacked Rock Cliff"] = "Rock",
	["Desert Cliff"] = "Rock",
	["Ravine Rock"] = "Rock",
	["Rock Sliced"] = "Rock",
	["Rock Vstreaks"] = "Rock",
	["Rough Igneous  Rock"] = "Rock",
} :: { [string]: string }

MissionZones.LabFloors = { "Blue Lab", "Cyan Lab", "Green Lab", "Yellow Lab", "Orange Lab", "Red Lab", "Pink Lab", "Purple Lab", "White Lab", "Brown Lab", "Camp Lab", "Clown Lab", "Funhouse Lab", "Pizza Lab" }

-- Sitios (centro en planta). Mina: boca a 316 del centro de la montaña, donde el suelo está a Y = 12.
-- (las mismas montañas que CityPlan.Mountains)
MissionZones.Mountain = { X = -800, Z = -3250, R = 360, H = 200, Rock = true }
MissionZones.MineDepth = 316
MissionZones.Crater = { X = -2600, Z = -3150, R = 380, H = 180, Rock = true }
MissionZones.Meteor = { X = -3100, Z = -2900, Y = -1 }

-- Altura del suelo de una montaña a una distancia d del centro: la bola de hierba de TerrainBuilder y,
-- en las de roca, la bola de roca de la cumbre (radio 0,42 R, centro a H - 0,9 r)
function MissionZones.groundAt(m: { R: number, H: number, Rock: boolean? }, d: number): number
	local y = -1
	if d < m.R then
		y = (m.H - m.R) + math.sqrt(m.R * m.R - d * d)
	end
	if m.Rock then
		local r = m.R * 0.42
		if d < r then
			y = math.max(y, (m.H - r * 0.9) + math.sqrt(r * r - d * d))
		end
	end
	return y
end

---------------------------------------------------------------------
-- Piezas
---------------------------------------------------------------------

local lights = 0

local function piece(parent: Instance, name: string, size: Vector3, cf: CFrame, variant: string?, color: Color3, decor: boolean?, shape: Enum.PartType?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	if shape then
		p.Shape = shape
	end
	local base = variant and MissionZones.Variants[variant]
	p.Material = if base then (Enum.Material :: any)[base] else Enum.Material.Rock
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if variant then
		p:SetAttribute("ZonaVariant", variant)
	end
	p:SetAttribute("ZonaColor", color) -- (por si algo la aclara antes de ponerle su variant)
	if decor then
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		CollectionService:AddTag(p, "CityDetail")
	end
	p.Parent = parent
	return p
end

local function light(part: BasePart, color: Color3, range: number, brightness: number)
	if lights >= MissionZones.MaxLights then
		return
	end
	lights += 1
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = part
end

local function zone(parent: Instance, id: string, nombre: string, peligro: string?): Model
	local m = Instance.new("Model")
	m.Name = id
	m:SetAttribute("Zona", id)
	m:SetAttribute("Nombre", nombre)
	m:SetAttribute("Peligro", peligro)
	m:SetAttribute("Danio", false)
	CollectionService:AddTag(m, MissionZones.Tag)
	m.Parent = parent
	return m
end

local function sign(part: BasePart, text: string, face: Enum.NormalId, bg: Color3, fg: Color3)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = bg
	label.TextColor3 = fg
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Text = text
	label.Parent = gui
	gui.Parent = part
end

local rgb = Color3.fromRGB
local V = Vector3.new

-- Sala de roca (suelo con la cara de arriba en y = 0 del marco, paredes, techo). Huecos de gap studs en
-- la pared de delante (+Z) y de detrás (-Z) si se piden.
local function room(m: Model, frame: CFrame, w: number, d: number, h: number, look: { Floor: string, Walls: { string }, Ceil: string, Color: Color3, FloorColor: Color3 }, gapFront: number?, gapBack: number?)
	local t = 2
	piece(m, "SueloZona", V(w + 2 * t, t, d + 2 * t), frame * CFrame.new(0, -t / 2, 0), look.Floor, look.FloorColor)
	piece(m, "TechoZona", V(w + 2 * t, t, d + 2 * t), frame * CFrame.new(0, h + t / 2, 0), look.Ceil, look.Color)
	local walls = look.Walls
	piece(m, "ParedZona", V(t, h, d), frame * CFrame.new(-w / 2 - t / 2, h / 2, 0), walls[1], look.Color)
	piece(m, "ParedZona", V(t, h, d), frame * CFrame.new(w / 2 + t / 2, h / 2, 0), walls[2 % #walls + 1], look.Color)
	for i, side in { { z = d / 2 + t / 2, gap = gapFront }, { z = -d / 2 - t / 2, gap = gapBack } } do
		local gap = side.gap or 0
		local variant = walls[(i + 1) % #walls + 1]
		if gap <= 0 then
			piece(m, "ParedZona", V(w + 2 * t, h, t), frame * CFrame.new(0, h / 2, side.z), variant, look.Color)
		else
			local seg = (w + 2 * t - gap) / 2
			piece(m, "ParedZona", V(seg, h, t), frame * CFrame.new(-(gap / 2 + seg / 2), h / 2, side.z), variant, look.Color)
			piece(m, "ParedZona", V(seg, h, t), frame * CFrame.new(gap / 2 + seg / 2, h / 2, side.z), variant, look.Color)
		end
	end
end

-- Valla de aviso alrededor de un rectángulo (sin daño): postes amarillos, barra y letreros
local function fence(m: Model, frame: CFrame, w: number, d: number)
	local yellow, black = rgb(235, 190, 40), rgb(30, 30, 30)
	local corners = { { -w / 2, -d / 2 }, { w / 2, -d / 2 }, { w / 2, d / 2 }, { -w / 2, d / 2 } }
	for i, a in corners do
		local b = corners[i % 4 + 1]
		local mid = Vector3.new((a[1] + b[1]) / 2, 0, (a[2] + b[2]) / 2)
		local len = math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2)
		local along = if a[2] == b[2] then V(len, 0.3, 0.3) else V(0.3, 0.3, len)
		piece(m, "VallaAviso", along, frame * CFrame.new(mid.X, 2.6, mid.Z), nil, yellow).Material = Enum.Material.SmoothPlastic
		piece(m, "VallaAviso", along, frame * CFrame.new(mid.X, 1.4, mid.Z), nil, black).Material = Enum.Material.SmoothPlastic
		local post = piece(m, "PosteAviso", V(0.4, 3.2, 0.4), frame * CFrame.new(a[1], 1.6, a[2]), nil, yellow)
		post.Material = Enum.Material.SmoothPlastic
	end
	local plate = piece(m, "LetreroAviso", V(4, 1.6, 0.2), frame * CFrame.new(0, 3.6, d / 2), nil, yellow)
	plate.Material = Enum.Material.SmoothPlastic
	sign(plate, "⚠ PELIGRO · LAVA", Enum.NormalId.Front, yellow, black)
	sign(plate, "⚠ PELIGRO · LAVA", Enum.NormalId.Back, yellow, black)
end

local function lavaPool(m: Model, frame: CFrame, w: number, d: number, variant: string, seed: number)
	local pool = piece(m, "PozaLava", V(w, 0.6, d), frame * CFrame.new(0, 0.3, 0), variant, rgb(255, 120, 40))
	pool.CanCollide = false
	light(pool, rgb(255, 120, 40), 34, 3)
	local glow = Instance.new("SurfaceLight")
	glow.Face = Enum.NormalId.Top
	glow.Color = rgb(255, 110, 30)
	glow.Range = 16
	glow.Brightness = 2
	glow.Parent = pool
	local rocks = { "Lava Rock", "Sharp Volcanic Rock", "Volcanic Rock", "Columned Lava Rock" }
	local rng = Random.new(seed)
	local n = math.floor((w + d) / 3)
	for i = 1, n do
		local a = i / n * math.pi * 2
		local x, z = math.cos(a) * (w / 2 + 0.8), math.sin(a) * (d / 2 + 0.8)
		local s = rng:NextNumber(1.6, 3)
		piece(m, "RocaVolcanica", V(s, s * 0.8, s), frame * CFrame.new(x, s * 0.3, z) * CFrame.Angles(rng:NextNumber(0, 1), rng:NextNumber(0, 6), 0), rocks[i % #rocks + 1], rgb(70, 60, 58), true)
	end
	fence(m, frame, w + 6, d + 6)
end

---------------------------------------------------------------------
-- Sitios
---------------------------------------------------------------------

-- Mina de los Montes: devuelve el modelo y los huecos que hay que vaciar en el terreno
function MissionZones.buildMine(parent: Instance): (Model, { { CFrame: CFrame, Size: Vector3 } })
	local mt = MissionZones.Mountain
	local y0 = math.floor(MissionZones.groundAt(mt, MissionZones.MineDepth) + 0.5)
	local origin = CFrame.new(mt.X, y0, mt.Z + MissionZones.MineDepth) -- (mirando a -Z: hacia dentro)
	local mine = zone(parent, "Mina", "Mina de los Montes")
	mine:SetAttribute("Entrada", origin.Position)
	local carve = {}
	local function hole(cf: CFrame, size: Vector3)
		table.insert(carve, { CFrame = cf, Size = size + V(8, 8, 8) })
	end
	local caveLook = { Floor = "Dusty Ground Gravel", Walls = { "Cavern Walls", "Rough Rockface", "Wet Cave Wall" }, Ceil = "Rough Rockface 2", Color = rgb(120, 108, 96), FloorColor = rgb(130, 118, 100) }
	-- Boca: marco de madera y letrero
	local wood = rgb(110, 80, 52)
	for _, x in { -6.5, 6.5 } do
		piece(mine, "PosteBoca", V(1.4, 13, 1.4), origin * CFrame.new(x, 6.5, 2), "Rough Wood", wood)
	end
	local lintel = piece(mine, "DinteBoca", V(15, 1.6, 1.6), origin * CFrame.new(0, 13.2, 2), "Old Planks", wood)
	local board = piece(mine, "LetreroMina", V(10, 2.2, 0.3), origin * CFrame.new(0, 15.2, 2.6), "Old Planks", wood)
	sign(board, "MINA DE LOS MONTES", Enum.NormalId.Back, rgb(60, 42, 28), rgb(240, 220, 180))
	light(lintel, rgb(255, 200, 140), 18, 1.4)
	-- Galería 1 (70 de largo)
	local g1 = origin * CFrame.new(0, 0, -35)
	room(mine, g1, 12, 70, 12, caveLook, 12, 12)
	hole(g1 * CFrame.new(0, 6, 0), V(16, 16, 74))
	-- Vías, traviesas, entibado y lámparas
	for _, x in { -2.2, 2.2 } do
		piece(mine, "Carril", V(0.3, 0.35, 118), origin * CFrame.new(x, 0.55, -59), "Rusted Iron", rgb(90, 70, 60), true)
	end
	for z = -2, -118, -3 do
		piece(mine, "Traviesa", V(6.4, 0.35, 0.9), origin * CFrame.new(0, 0.2, z), "Old Planks", wood, true)
	end
	for z = -8, -66, -10 do
		for _, x in { -5.4, 5.4 } do
			piece(mine, "Entibado", V(1, 11.6, 1), origin * CFrame.new(x, 5.8, z), "Rough Wood", wood, true)
		end
		piece(mine, "Entibado", V(12, 1, 1), origin * CFrame.new(0, 11.4, z), "Old Planks", wood, true)
		if z % 20 == -8 % 20 then
			local bulb = piece(mine, "Lampara", V(0.6, 0.8, 0.6), origin * CFrame.new(0, 10.5, z), nil, rgb(255, 214, 150), true)
			bulb.Material = Enum.Material.Neon
			light(bulb, rgb(255, 196, 130), 20, 1.2)
		end
	end
	-- Cámara de lava (más alta y honda: 50 de fondo)
	local lavaZone = zone(mine, "CamaraLava", "Cámara de lava", "Lava")
	local c1 = origin * CFrame.new(0, 0, -95)
	room(lavaZone, c1, 44, 50, 26, { Floor = "Cavefloor Rock", Walls = { "Wet Cave Wall", "Cavern Deposits", "Dark Rough Rock" }, Ceil = "Cavern Deposits", Color = rgb(96, 84, 78), FloorColor = rgb(92, 80, 74) }, 12, 10)
	hole(c1 * CFrame.new(0, 13, 0), V(48, 30, 54))
	lavaPool(lavaZone, c1 * CFrame.new(-9, 0, -6), 14, 12, "Hot Lava", 11)
	lavaPool(lavaZone, c1 * CFrame.new(11, 0, 8), 10, 9, "Flowing Lava", 12)
	piece(lavaZone, "SueloLavaRoca", V(8, 0.4, 6), c1 * CFrame.new(12, 0.2, -14), "Lava And Rock", rgb(180, 110, 70), true)
	-- Vetas de mineral en las paredes y una vagoneta
	for i, v in { { -21.6, 6, -12, "Ore" }, { 21.6, 9, 4, "Peacock Ore" }, { -21.6, 12, 14, "Peacock Ore" }, { 21.6, 5, -18, "Ore" } } do
		piece(lavaZone, "VetaMineral", V(1.2, 3 + i % 2, 6), c1 * CFrame.new(v[1], v[2], v[3]), v[4], rgb(150, 140, 150), true)
	end
	piece(lavaZone, "Vagoneta", V(4, 2.6, 6), c1 * CFrame.new(0, 2.1, 20), "Rust Panel", rgb(120, 90, 70), true)
	-- Galería 2 (de la cámara de lava a la cueva alienígena)
	local g2 = origin * CFrame.new(0, 0, -140)
	room(mine, g2, 10, 40, 11, { Floor = "Cavefloor", Walls = { "Rough Rockface 2", "Dark Rough Rock" }, Ceil = "Slimy Slippery Rock", Color = rgb(100, 96, 104), FloorColor = rgb(110, 104, 100) }, 10, 10)
	hole(g2 * CFrame.new(0, 5.5, 0), V(14, 15, 44))
	-- Cueva alienígena
	local alien = zone(mine, "CuevaAlien", "Cueva alienígena")
	local c2 = origin * CFrame.new(0, 0, -190)
	room(alien, c2, 56, 60, 30, { Floor = "Planet Surface", Walls = { "Lunar Rock", "Layered Planetary", "Cratered Rock" }, Ceil = "Lunar Rock 2", Color = rgb(120, 116, 140), FloorColor = rgb(130, 122, 140) }, 10, 0)
	hole(c2 * CFrame.new(0, 15, 0), V(60, 34, 64))
	local rng = Random.new(42)
	local crystals = { "Glass - fractalized", "Ice Field", "Stylized Ice Cave Walls" }
	local tones = { rgb(110, 220, 255), rgb(190, 120, 255), rgb(120, 255, 200) }
	for i = 1, 12 do
		local x, z = rng:NextNumber(-24, 24), rng:NextNumber(-26, 20)
		if math.abs(x) > 7 or z < -8 then
			local h = rng:NextNumber(3, 9)
			local c = piece(alien, "Cristal", V(1.4, h, 1.4), c2 * CFrame.new(x, h / 2 - 0.4, z) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6), rng:NextNumber(-0.4, 0.4)), crystals[i % 3 + 1], tones[i % 3 + 1], true)
			c.Transparency = 0.15
			c.Reflectance = 0.1
			if i % 4 == 0 then
				light(c, tones[i % 3 + 1], 22, 1.6)
			end
		end
	end
	for i, v in { "Sulfuric Rock", "Geyser Rock", "Holey Rock", "Lunar Rock 2" } do
		local s = 4 + i
		piece(alien, "RocaAlien", V(s, s * 0.7, s * 0.9), c2 * CFrame.new(-22 + i * 9, s * 0.3, -22 + (i % 2) * 6) * CFrame.Angles(0, i, 0.2), v, rgb(150, 140, 160), true)
	end
	-- Restos de nave (metal sci-fi)
	local scifi = { "Spaceship Panels", "Sci-fi Panel", "Red Sci-fi Metal", "Futuristic Panels", "Space Cruiser Panels", "Space Cruiser Panels 2", "Filthy Space Panels", "Military Panels", "Ship Corridor", "Solar Panels" }
	for i, v in scifi do
		local a = i / #scifi * math.pi * 1.4 + 0.3
		piece(alien, "RestoNave", V(rng:NextNumber(4, 8), 0.5, rng:NextNumber(3, 6)), c2 * CFrame.new(math.cos(a) * 18, 1.4, math.sin(a) * 14 - 4) * CFrame.Angles(rng:NextNumber(-0.7, 0.7), a, rng:NextNumber(-0.5, 0.5)), v, rgb(190, 192, 200), true)
	end
	piece(alien, "CajaNave", V(3, 3, 3), c2 * CFrame.new(16, 1.5, 18), "Space Crate", rgb(200, 200, 205), true)
	piece(alien, "Chip", V(1.6, 0.3, 1.6), c2 * CFrame.new(15, 3.15, 18), "Microchip 2", rgb(170, 200, 170), true)
	-- Laboratorio abandonado: suelo de los 14 asfaltos «Lab» de colores
	local lab = zone(alien, "Laboratorio", "Laboratorio abandonado")
	local labFrame = c2 * CFrame.new(-14, 0, 14)
	for i, v in MissionZones.LabFloors do
		local col, row = (i - 1) % 5, (i - 1) // 5
		piece(lab, "BaldosaLab", V(3.9, 0.2, 3.9), labFrame * CFrame.new((col - 2) * 4, 0.1, (row - 1) * 4), v, rgb(255, 255, 255))
	end
	piece(lab, "MesaLab", V(6, 3, 2), labFrame * CFrame.new(0, 1.5, -7), "Worn Military Siding", rgb(170, 175, 180), true)
	local screen = piece(lab, "PantallaLab", V(3, 2, 0.2), labFrame * CFrame.new(0, 4, -7.6), nil, rgb(80, 255, 200), true)
	screen.Material = Enum.Material.Neon
	light(screen, rgb(80, 255, 200), 14, 1)
	-- Muro orgánico (lo más hondo: la pared del fondo de la cueva)
	local organic = zone(mine, "MuroOrganico", "Muro orgánico alienígena")
	local wallFrame = c2 * CFrame.new(0, 0, -29)
	piece(organic, "MuroOrganico", V(40, 26, 1.5), wallFrame * CFrame.new(0, 13, 0), "Meat", rgb(150, 90, 180))
	for i, v in { "Layered Fungus", "Melted Wax", "Layered Fungus", "Melted Wax", "Layered Fungus" } do
		local s = 3 + (i % 3)
		piece(organic, "BultoOrganico", V(s, s, s), wallFrame * CFrame.new(-16 + i * 6, 3 + (i % 3) * 6, 1), v, rgb(120, 170, 110), true, Enum.PartType.Ball)
	end
	for i, v in { "Bog", "Tidal Pool", "Mud With Vegetation" } do
		piece(organic, "CharcoOrganico", V(8, 0.3, 5), wallFrame * CFrame.new(-12 + i * 6, 0.15, 5), v, rgb(110, 150, 120), true)
	end
	local glow = piece(organic, "LuzOrganica", V(1, 1, 1), wallFrame * CFrame.new(0, 10, 4), nil, rgb(150, 255, 150), true)
	glow.Transparency = 1
	light(glow, rgb(150, 255, 150), 26, 1.2)
	return mine, carve
end

-- Cráter de lava en una cumbre
function MissionZones.buildCrater(parent: Instance): Model
	local c = MissionZones.Crater
	local m = zone(parent, "CraterLava", "Cráter de lava", "Lava")
	local frame = CFrame.new(c.X, MissionZones.groundAt(c, 20), c.Z) -- (la cumbre, un poco hundido)
	piece(m, "AnilloCrater", V(2, 46, 46), frame * CFrame.new(0, -0.6, 0) * CFrame.Angles(0, 0, math.rad(90)), "Lava And Rock", rgb(90, 70, 60), false, Enum.PartType.Cylinder)
	local pool = piece(m, "PozaLava", V(1, 30, 30), frame * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)), "Flowing Lava", rgb(255, 120, 40), false, Enum.PartType.Cylinder)
	pool.CanCollide = false
	light(pool, rgb(255, 120, 40), 50, 4)
	local rocks = { "Volcanic Rock", "Sharp Volcanic Rock", "Lava Rock", "Columned Lava Rock" }
	for i = 1, 14 do
		local a = i / 14 * math.pi * 2
		local s = 3 + (i % 3) * 1.5
		piece(m, "RocaVolcanica", V(s, s, s * 1.2), frame * CFrame.new(math.cos(a) * 18, s * 0.35, math.sin(a) * 18) * CFrame.Angles(0.3, a, 0.2), rocks[i % 4 + 1], rgb(70, 60, 58), true)
	end
	fence(m, frame * CFrame.new(0, 0.2, 0), 50, 50)
	return m
end

-- Cráter del meteorito en el campo
function MissionZones.buildMeteor(parent: Instance): Model
	local c = MissionZones.Meteor
	local m = zone(parent, "Meteorito", "Cráter del meteorito")
	local frame = CFrame.new(c.X, c.Y, c.Z)
	piece(m, "SueloCrater", V(0.6, 44, 44), frame * CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)), "Windswept Wasteland", rgb(120, 110, 100), false, Enum.PartType.Cylinder)
	local rim = { "Cratered Rock", "Holey Rock", "Lunar Rock 2", "Cratered Rock" }
	for i = 1, 16 do
		local a = i / 16 * math.pi * 2
		local s = 4 + (i % 4)
		piece(m, "BordeCrater", V(s * 1.4, s * 0.8, s), frame * CFrame.new(math.cos(a) * 22, s * 0.25, math.sin(a) * 22) * CFrame.Angles(0.2, a, 0.1), rim[i % 4 + 1], rgb(110, 100, 96), true)
	end
	local rock = piece(m, "Meteorito", V(7, 7, 7), frame * CFrame.new(0, 2.4, 0), "Peacock Ore", rgb(90, 80, 110), false, Enum.PartType.Ball)
	light(rock, rgb(170, 120, 255), 24, 1.5)
	for i, v in { "Warped Sheet Metal", "Worn Military Siding", "Filthy Space Panels" } do
		piece(m, "RestoMetal", V(5, 0.4, 3), frame * CFrame.new(-10 + i * 6, 0.9, 8 - i * 3) * CFrame.Angles(0.5, i, 0.3), v, rgb(180, 180, 186), true)
	end
	return m
end

-- Riscos en las laderas de las montañas de roca (fuera de la de la mina)
function MissionZones.cliffSpots(): { { Position: Vector3, Index: number } }
	local CityPlan = MissionZones.CityPlan
	local out = {}
	if not CityPlan then
		return out
	end
	local n = 0
	for _, m in CityPlan.Mountains do
		if m.Rock and not (m.X == MissionZones.Mountain.X and m.Z == MissionZones.Mountain.Z) then
			for k = 0, 3 do
				local a = k * math.pi / 2 + 0.6
				local d = m.R * 0.62
				local x, z = m.X + math.cos(a) * d, m.Z + math.sin(a) * d
				if not CityPlan.districtAt(x, z) then
					n += 1
					table.insert(out, { Position = Vector3.new(x, MissionZones.groundAt(m, d), z), Index = n })
				end
			end
		end
	end
	return out
end

function MissionZones.buildCliffs(parent: Instance): Model
	local m = zone(parent, "RiscosMontes", "Riscos de los montes")
	local names = { "Strata Rock", "Strata Rock 2", "Eroded Layered Rockface", "Jagged Cliff", "Layered Cliff", "Stacked Rock Cliff", "Desert Cliff", "Ravine Rock", "Rock Sliced", "Rock Vstreaks", "Rough Igneous  Rock" }
	for _, spot in MissionZones.cliffSpots() do
		local v = names[(spot.Index - 1) % #names + 1]
		local s = 14 + (spot.Index % 3) * 4
		piece(m, "Risco", V(s * 1.4, s, s), CFrame.new(spot.Position + Vector3.new(0, s * 0.25, 0)) * CFrame.Angles(0.15, spot.Index, 0.1), v, rgb(130, 122, 112))
	end
	return m
end

---------------------------------------------------------------------
-- Variants (cuando el Mega Pack ya está en la biblioteca)
---------------------------------------------------------------------

-- Pone a cada pieza su variant (copia en MaterialService). mega: carpeta de la biblioteca (variants con
-- atributo SourceName). Devuelve cuántas piezas vistió y cuántos variants usó.
function MissionZones.dress(root: Instance, mega: Instance, service: Instance): (number, number)
	local byName: { [string]: Instance } = {}
	for _, v in mega:GetChildren() do
		local name = v:GetAttribute("SourceName")
		if v:IsA("MaterialVariant") and type(name) == "string" and byName[name] == nil then
			byName[name] = v
		end
	end
	local copies: { [string]: any } = {}
	local count, used = 0, 0
	for _, part in root:GetDescendants() do
		local want = part:IsA("BasePart") and part:GetAttribute("ZonaVariant")
		if type(want) == "string" and part.MaterialVariant == "" then
			local copy = copies[want]
			if copy == nil then
				copy = false
				local source: any = byName[want]
				if source and source.BaseMaterial.Name == MissionZones.Variants[want] then
					local name = MissionZones.Prefix .. want:gsub("[^%w]", "")
					local existing = service:FindFirstChild(name)
					if existing then
						copy = existing
					else
						local ok, c = pcall(function()
							local v = source:Clone()
							v.Name = name
							v:SetAttribute("SourcePack", nil)
							v:SetAttribute("SourceName", nil)
							v.Parent = service
							return v
						end)
						if ok and c then
							copy = c
							used += 1
						end
					end
				end
				copies[want] = copy
			end
			if copy then
				local ok = pcall(function()
					(part :: any).Material = copy.BaseMaterial
					;(part :: any).MaterialVariant = copy.Name
					local color = part:GetAttribute("ZonaColor")
					if typeof(color) == "Color3" then
						(part :: any).Color = color
					end
				end)
				if ok then
					count += 1
				end
			end
		end
	end
	return count, used
end

---------------------------------------------------------------------
-- Arranque
---------------------------------------------------------------------

-- parent: dónde se montan (workspace por defecto); terrain: para vaciar la montaña; library: la
-- biblioteca de World/UserMaterials (se espera a que tenga el Mega Pack).
function MissionZones.start(parent: Instance?, terrain: any?, library: Instance?, service: Instance?, wait: number?)
	local folder = Instance.new("Folder")
	folder.Name = "ZonasMision"
	lights = 0
	local ok, err = pcall(function()
		local _, carve = MissionZones.buildMine(folder)
		local land = terrain or workspace.Terrain
		for _, h in carve do
			pcall(function()
				land:FillBlock(h.CFrame, h.Size, Enum.Material.Air)
			end)
		end
		MissionZones.buildCrater(folder)
		MissionZones.buildMeteor(folder)
		MissionZones.buildCliffs(folder)
	end)
	if not ok then
		warn("[MissionZones] " .. tostring(err))
	end
	folder.Parent = parent or workspace
	-- Variants del Mega Pack (World/UserMaterials lo carga en otro hilo: se espera hasta 3 min)
	local lib = library or ServerStorage:FindFirstChild("UserMaterials")
	local limit = wait or 180
	local waited = 0
	while not (lib and lib:FindFirstChild("Mega")) and waited < limit do
		task.wait(2)
		waited += 2
		lib = library or ServerStorage:FindFirstChild("UserMaterials")
	end
	local mega = lib and lib:FindFirstChild("Mega")
	if mega then
		task.wait(1) -- (que termine de desempaquetar)
		local okDress, n, used = pcall(MissionZones.dress, folder, mega, service or game:GetService("MaterialService"))
		if okDress then
			print(("[MissionZones] %d piezas con %d variants del Mega Pack (mina, lava, cueva alienígena, cráteres, riscos)"):format(n, used))
		else
			warn("[MissionZones] " .. tostring(n))
		end
	else
		print("[MissionZones] sin el Mega Pack: las zonas se quedan con los materiales de Roblox")
	end
	return folder
end

return MissionZones
