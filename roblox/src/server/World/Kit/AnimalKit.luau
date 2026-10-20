-- AnimalKit: la Protectora de animales de Valmar y los cercados de los animales de granja.
--
--   PROTECTORA (modelo "Protectora", en Valmar Centro, al sur de la calle de la Ronda interior,
--   x -300..-196, z -352..-262; la fachada mira a la calle, al norte):
--     [callejón][  recepción (mostrador, bancos, carteles)  ][ pipicán ]
--     [callejón][  patio con 6 cheniles (perros y gatos)    ][ pipicán ]
--     Etiquetas: PetShelterDesk (mostrador: «Adoptar», PetService), PetShelterStaff (dónde va el
--     recepcionista), PetShelterKennel (+Kind, Breed, Coat: el animal de cada chenil, lo pinta Wildlife).
--   CAMPOS (modelo "CampoAnimales", junto a la Carretera de Villaverde): los cercados de
--     shared/FarmAnimals con vallas, puerta, comedero con heno, abrevadero, charca de barro (cerdos),
--     cobertizo (rebaño) y cuadra (caballos); poste HorseStation («Montar a caballo», PetService).
-- Sin math.random: se construye al final sin cambiar nada más del mapa.

local Builder = require(script.Parent.Parent.Builder)
local FarmAnimals = require(game:GetService("ReplicatedStorage").Shared.FarmAnimals)
local Pets = require(game:GetService("ReplicatedStorage").Shared.Pets)

local AnimalKit = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new

AnimalKit.Shelter = { X0 = -300, X1 = -196, Z0 = -352, Z1 = -262, Floor = 1.0 }

local WOOD = rgb(132, 96, 62)
local DARK_WOOD = rgb(96, 68, 44)
local WALL = rgb(236, 226, 206)
local ACCENT = rgb(60, 150, 120)
local STEEL = rgb(150, 156, 164)

local model: Instance

local function solid(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
	local props = { Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = model }
	for k, v in extra or {} do
		props[k] = v
	end
	return Builder.part(props)
end

local function bit(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, transparency: number?): BasePart
	return Builder.decor({ Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Transparency = transparency or 0, Parent = model })
end

local function spot(name: string, cf: CFrame, tags: { string }, attributes: { [string]: any }?): BasePart
	return Builder.part({ Name = name, Size = V(2, 2, 2), CFrame = cf, Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Tags = tags, Attributes = attributes, Parent = model })
end

local function sign(text: string, size: Vector3, cf: CFrame, color: Color3?, textColor: Color3?)
	local p = bit("Sign", size, cf, color or rgb(30, 60, 50))
	Builder.sign(p, text, Enum.NormalId.Front, textColor)
	return p
end

local function lamp(cf: CFrame, range: number?)
	local p = bit("Lamp", V(3, 0.25, 3), cf, rgb(255, 248, 228), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Range = range or 26
	light.Brightness = 1.1
	light.Shadows = false
	light.Parent = p
end

-- Losa de suelo entre dos esquinas (top = altura de arriba)
local function slab(name: string, x0: number, x1: number, z0: number, z1: number, top: number, bottom: number, color: Color3, material: Enum.Material)
	solid(name, V(x1 - x0, top - bottom, z1 - z0), CF((x0 + x1) / 2, (top + bottom) / 2, (z0 + z1) / 2), color, material)
end

-- Pared de a hasta b (en X o en Z), con huecos { desde, hasta } a lo largo
local function wall(name: string, ax: number, az: number, bx: number, bz: number, y0: number, h: number, t: number, color: Color3, material: Enum.Material, gaps: { { number } }?)
	local alongX = math.abs(bx - ax) > math.abs(bz - az)
	local from, to = if alongX then math.min(ax, bx) else math.min(az, bz), if alongX then math.max(ax, bx) else math.max(az, bz)
	local cuts = table.clone(gaps or {})
	table.sort(cuts, function(a, b)
		return a[1] < b[1]
	end)
	local pieces = {}
	local cursor = from
	for _, g in cuts do
		if g[1] > cursor then
			table.insert(pieces, { cursor, g[1] })
		end
		cursor = math.max(cursor, g[2])
	end
	if cursor < to then
		table.insert(pieces, { cursor, to })
	end
	for _, seg in pieces do
		local len = seg[2] - seg[1]
		if len < 0.05 then
			continue
		end
		local mid = (seg[1] + seg[2]) / 2
		local cf = if alongX then CF(mid, y0 + h / 2, az) else CF(ax, y0 + h / 2, mid)
		solid(name, if alongX then V(len, h, t) else V(t, h, len), cf, color, material)
	end
end

-- Valla de tela metálica (se ve a través): postes y malla
local function mesh(ax: number, az: number, bx: number, bz: number, y0: number, h: number, gaps: { { number } }?)
	wall("Malla", ax, az, bx, bz, y0, h, 0.15, rgb(170, 176, 182), Enum.Material.DiamondPlate, gaps)
	for _, d in model:GetChildren() do
		if d.Name == "Malla" and d:IsA("BasePart") and d.Transparency == 0 then
			d.Transparency = 0.55
		end
	end
	local alongX = math.abs(bx - ax) > math.abs(bz - az)
	local len = if alongX then math.abs(bx - ax) else math.abs(bz - az)
	local n = math.max(1, math.floor(len / 6))
	for i = 0, n do
		local k = i / n
		local x, z = ax + (bx - ax) * k, az + (bz - az) * k
		bit("PostePie", V(0.3, h + 0.3, 0.3), CF(x, y0 + (h + 0.3) / 2, z), STEEL, Enum.Material.Metal)
	end
end

---------------------------------------------------------------------
-- Protectora
---------------------------------------------------------------------
local function doghouse(x: number, z: number, y: number, color: Color3)
	solid("Caseta", V(4, 3, 3.6), CF(x, y + 1.5, z), color, Enum.Material.WoodPlanks)
	bit("CasetaTecho", V(4.6, 0.4, 2.4), CF(x, y + 3.35, z - 0.85) * CFrame.Angles(math.rad(-28), 0, 0), DARK_WOOD, Enum.Material.Wood)
	bit("CasetaTecho", V(4.6, 0.4, 2.4), CF(x, y + 3.35, z + 0.85) * CFrame.Angles(math.rad(28), 0, 0), DARK_WOOD, Enum.Material.Wood)
	bit("CasetaPuerta", V(1.6, 1.8, 0.1), CF(x, y + 0.95, z - 1.82), rgb(30, 26, 22))
end

local function bowl(x: number, z: number, y: number, color: Color3)
	bit("Cuenco", V(1.2, 0.35, 1.2), CF(x, y + 0.18, z), color, Enum.Material.Metal)
	bit("Pienso", V(0.9, 0.05, 0.9), CF(x, y + 0.36, z), rgb(150, 100, 60))
end

local function buildShelter(world: Instance)
	local S = AnimalKit.Shelter
	local m = Builder.model("Protectora", world)
	model = m
	local Y = S.Floor
	-- Suelos: explanada, callejón, recepción, patio y pipicán
	slab("Explanada", S.X0, S.X1, S.Z0, -338, Y, -1.4, rgb(196, 192, 184), Enum.Material.Pavement)
	slab("Callejon", S.X0, -284, -338, S.Z1, Y - 0.05, -1.4, rgb(110, 108, 106), Enum.Material.Asphalt)
	slab("SueloRecepcion", -284, -228, -338, -312, Y, -1.4, rgb(214, 206, 190), Enum.Material.Slate)
	slab("Patio", -284, -228, -312, S.Z1, Y - 0.05, -1.4, rgb(150, 132, 100), Enum.Material.Ground)
	slab("Pipican", -228, S.X1, -338, S.Z1, Y - 0.05, -1.4, rgb(98, 142, 70), Enum.Material.Grass)

	-- Recepción: x -280..-232, z -338..-312, paredes de 12 con puerta delante y detrás
	local x0, x1, zf, zb = -280, -232, -338, -312
	local H = 12
	wall("Pared", x0, zf, x1, zf, Y, H, 1, WALL, Enum.Material.Plaster, { { -259, -253 }, { -276, -266 }, { -246, -236 } })
	-- Escaparates (cristal) en los huecos de los lados de la puerta
	for _, g in { { -276, -266 }, { -246, -236 } } do
		local cx = (g[1] + g[2]) / 2
		solid("Zocalo", V(g[2] - g[1], 3, 1), CF(cx, Y + 1.5, zf), WALL, Enum.Material.Plaster)
		solid("Cristal", V(g[2] - g[1], 6, 0.3), CF(cx, Y + 6, zf), rgb(170, 200, 215), Enum.Material.Glass, { Transparency = 0.55 })
		solid("Dintel", V(g[2] - g[1], H - 9, 1), CF(cx, Y + 9 + (H - 9) / 2, zf), WALL, Enum.Material.Plaster)
	end
	solid("DintelPuerta", V(6, H - 8.5, 1), CF(-256, Y + 8.5 + (H - 8.5) / 2, zf), WALL, Enum.Material.Plaster)
	wall("Pared", x0, zb, x1, zb, Y, H, 1, WALL, Enum.Material.Plaster, { { -259, -253 } })
	solid("DintelPuerta", V(6, H - 8.5, 1), CF(-256, Y + 8.5 + (H - 8.5) / 2, zb), WALL, Enum.Material.Plaster)
	wall("Pared", x0, zf, x0, zb, Y, H, 1, WALL, Enum.Material.Plaster)
	wall("Pared", x1, zf, x1, zb, Y, H, 1, WALL, Enum.Material.Plaster)
	solid("Tejado", V(x1 - x0 + 3, 1, zb - zf + 3), CF((x0 + x1) / 2, Y + H + 0.5, (zf + zb) / 2), rgb(120, 70, 50), Enum.Material.Slate)
	solid("Cornisa", V(x1 - x0 + 3.4, 0.6, 1), CF((x0 + x1) / 2, Y + H + 0.2, zf - 1.5), ACCENT)
	-- Cartel de la fachada y el de la acera
	sign("🐾 PROTECTORA DE ANIMALES DE VALMAR", V(30, 3, 0.3), CF(-256, Y + 10.3, zf - 0.7), ACCENT)
	sign("ADOPTA, NO COMPRES ❤", V(10, 2, 0.2), CF(-271, Y + 10.3, zf - 0.7) * CF(0, -0.0, 0), rgb(200, 90, 70))
	for _, x in { -212, -205 } do
		bit("PosteCartel", V(0.4, 7, 0.4), CF(x, Y + 3.5, -349), STEEL, Enum.Material.Metal)
	end
	sign("🐶 🐱 ADOPCIÓN GRATUITA\nProtectora de Valmar", V(8, 3.4, 0.3), CF(-208.5, Y + 6.2, -349), rgb(240, 236, 226), rgb(40, 90, 70))
	-- Dentro: mostrador, recepcionista, bancos, carteles y luz
	solid("Mostrador", V(20, 3.4, 2.2), CF(-256, Y + 1.7, -324), rgb(240, 236, 226), Enum.Material.SmoothPlastic)
	local top = solid("MostradorTapa", V(20.6, 0.3, 2.8), CF(-256, Y + 3.55, -324), WOOD, Enum.Material.Wood)
	solid("MostradorFrente", V(20, 1.2, 0.1), CF(-256, Y + 2.4, -325.15), ACCENT)
	spot("PetShelterDesk", CF(-256, Y + 4.4, -325.2), { "PetShelterDesk" })
	spot("PetShelterStaff", CF(-256, Y, -321) * CFrame.Angles(0, math.pi, 0), { "PetShelterStaff" })
	bit("Ordenador", V(1.6, 1.1, 0.2), CF(-252, Y + 4.3, -323.6), rgb(30, 30, 34))
	bit("Hucha", V(1.2, 1.4, 1.2), CF(-262, Y + 4.4, -324), rgb(230, 170, 60))
	sign("DONATIVOS 🐾", V(2.2, 0.6, 0.1), CF(-262, Y + 5.4, -324.62), rgb(230, 170, 60), rgb(40, 30, 20))
	local _ = top
	for _, x in { -276, -238 } do
		solid("Banco", V(7, 0.5, 2), CF(x + (if x < -256 then 3.5 else -3.5), Y + 1.6, -335.6), WOOD, Enum.Material.Wood)
		bit("BancoPata", V(6.4, 1.3, 1.6), CF(x + (if x < -256 then 3.5 else -3.5), Y + 0.65, -335.6), DARK_WOOD, Enum.Material.Wood)
	end
	sign("🐶 PERROS\nen el patio", V(6, 3, 0.2), CF(-270, Y + 7, zb + 0.65) * CFrame.Angles(0, math.pi, 0), rgb(250, 246, 236), rgb(40, 90, 70))
	sign("🐱 GATOS\nen la gatera", V(6, 3, 0.2), CF(-242, Y + 7, zb + 0.65) * CFrame.Angles(0, math.pi, 0), rgb(250, 246, 236), rgb(40, 90, 70))
	sign("Adopta gratis.\nDonación voluntaria.\n¡Gracias!", V(5, 3.2, 0.2), CF(x0 + 0.65, Y + 7, -325) * CFrame.Angles(0, -math.pi / 2, 0), rgb(250, 246, 236), rgb(40, 90, 70))
	-- Rascador para gatos y cesta
	bit("Rascador", V(0.8, 5, 0.8), CF(-236, Y + 2.5, -316), rgb(200, 180, 140), Enum.Material.Fabric)
	bit("RascadorBase", V(3, 0.4, 3), CF(-236, Y + 0.2, -316), rgb(170, 140, 110), Enum.Material.Fabric)
	bit("RascadorPiso", V(2.6, 0.4, 2.6), CF(-236, Y + 3.2, -316), rgb(170, 140, 110), Enum.Material.Fabric)
	bit("RascadorPiso", V(2.6, 0.4, 2.6), CF(-236, Y + 5.2, -316), rgb(170, 140, 110), Enum.Material.Fabric)
	for _, x in { -268, -244 } do
		lamp(CF(x, Y + H - 0.3, -325))
	end

	-- Patio: valla de malla y 6 cheniles al fondo
	local yz0, yz1 = -312, -266
	mesh(-283.5, yz0, -283.5, yz1, Y, 7)
	mesh(-228.5, yz0, -228.5, yz1, Y, 7)
	mesh(-283.5, yz1, -228.5, yz1, Y, 7)
	local kennelZ0 = -281 -- frente de los cheniles
	for i = 0, 6 do
		local x = -282 + i * 8.6
		mesh(x, kennelZ0, x, yz1, Y, 6)
	end
	for i = 0, 5 do
		local cx = -282 + (i + 0.5) * 8.6
		-- Frente de cada chenil con su puertecita (cerrada)
		mesh(cx - 4.3, kennelZ0, cx + 4.3, kennelZ0, Y, 6, { { cx - 1.2, cx + 1.2 } })
		bit("PuertaChenil", V(2.4, 5.6, 0.15), CF(cx, Y + 2.8, kennelZ0), rgb(110, 116, 124), Enum.Material.DiamondPlate)
		local resident = Pets.ShelterResidents[i + 1]
		if resident then
			local kind = resident[1]
			if kind == "Perro" then
				doghouse(cx + 1.6, yz1 + 3, Y, ({ rgb(196, 90, 70), rgb(70, 120, 170), rgb(90, 150, 90) })[i % 3 + 1])
			else
				bit("Cesta", V(3, 0.8, 2.4), CF(cx + 1.8, Y + 0.4, yz1 + 3), rgb(190, 150, 100), Enum.Material.Fabric)
				bit("RascadorChenil", V(0.6, 3.6, 0.6), CF(cx - 2.6, Y + 1.8, yz1 + 2.5), rgb(200, 180, 140), Enum.Material.Fabric)
			end
			bowl(cx - 2, kennelZ0 + 2.2, Y, rgb(70, 130, 200))
			spot("PetShelterKennel", CF(cx - 0.6, Y, -276.5) * CFrame.Angles(0, math.pi, 0), { "PetShelterKennel" }, { Kind = kind, Breed = resident[2], Coat = resident[3] })
			local b = Pets.breed(kind, resident[2])
			sign(b and b.Name or kind, V(3.4, 0.9, 0.12), CF(cx + 2.4, Y + 4.8, kennelZ0 - 0.15), rgb(250, 246, 236), rgb(40, 60, 50))
		end
	end
	-- Mesa de la cuidadora, manguera y sacos de pienso en el patio
	solid("SacoPienso", V(2, 2.6, 1.2), CF(-279, Y + 1.3, -306), rgb(200, 170, 90), Enum.Material.Fabric)
	solid("SacoPienso", V(2, 2.6, 1.2), CF(-276.5, Y + 1.3, -306.2), rgb(200, 170, 90), Enum.Material.Fabric)
	bit("Manguera", V(1.6, 1.6, 0.5), CF(-283, Y + 2.5, -300), rgb(40, 140, 70))
	solid("Banco", V(6, 0.5, 2), CF(-246, Y + 1.6, -297), WOOD, Enum.Material.Wood)
	bit("BancoPata", V(5.4, 1.3, 1.6), CF(-246, Y + 0.65, -297), DARK_WOOD, Enum.Material.Wood)

	-- Callejón (oeste): tapia de ladrillo, contenedores, cajas de cartón y un charco
	wall("Tapia", S.X0, -350, S.X0, S.Z1, Y - 1, 10, 1, rgb(150, 80, 64), Enum.Material.Brick)
	wall("Tapia", S.X0, S.Z1, -284, S.Z1, Y - 1, 10, 1, rgb(150, 80, 64), Enum.Material.Brick)
	wall("Tapia", -284, -338, -284, -312, Y - 1, 10, 1, rgb(150, 80, 64), Enum.Material.Brick)
	for _, z in { -330, -300 } do
		solid("Contenedor", V(4, 4, 6), CF(-296.6, Y + 2, z), rgb(40, 110, 60), Enum.Material.Metal)
		bit("ContenedorTapa", V(4.2, 0.3, 6.2), CF(-296.6, Y + 4.15, z), rgb(30, 80, 45), Enum.Material.Metal)
	end
	bit("CajaCarton", V(2.6, 1.6, 2), CF(-297.2, Y + 0.8, -318), rgb(180, 140, 90), Enum.Material.Cardboard)
	bit("CajaCarton", V(1.8, 1.2, 1.6), CF(-297.6, Y + 2.2, -318.2), rgb(170, 130, 85), Enum.Material.Cardboard)
	bit("Charco", V(5, 0.05, 3), CF(-290, Y - 0.02, -344), rgb(80, 90, 100), Enum.Material.Glass, 0.4)
	lamp(CF(-299.2, Y + 8, -322), 18)

	-- Pipicán (este): valla baja, bancos, árbol y vallas de saltar
	wall("VallaBaja", -228, -338, S.X1, -338, Y, 2.4, 0.3, WOOD, Enum.Material.Wood, { { -216, -210 } })
	wall("VallaBaja", S.X1, -338, S.X1, S.Z1, Y, 2.4, 0.3, WOOD, Enum.Material.Wood)
	wall("VallaBaja", -228, S.Z1, S.X1, S.Z1, Y, 2.4, 0.3, WOOD, Enum.Material.Wood)
	for _, z in { -320, -300, -282 } do
		bit("ObstaculoPoste", V(0.3, 2, 0.3), CF(-216, Y + 1, z - 2), rgb(240, 240, 240))
		bit("ObstaculoPoste", V(0.3, 2, 0.3), CF(-216, Y + 1, z + 2), rgb(240, 240, 240))
		bit("ObstaculoBarra", V(0.25, 0.25, 4), CF(-216, Y + 1.4, z), rgb(230, 70, 60))
	end
	solid("Banco", V(6, 0.5, 2), CF(-200, Y + 1.6, -310) * CFrame.Angles(0, math.pi / 2, 0), WOOD, Enum.Material.Wood)
	bit("BancoPata", V(5.4, 1.3, 1.6), CF(-200, Y + 0.65, -310) * CFrame.Angles(0, math.pi / 2, 0), DARK_WOOD, Enum.Material.Wood)
	solid("Tronco", V(1.4, 9, 1.4), CF(-204, Y + 4.5, -272), rgb(100, 72, 50), Enum.Material.Wood)
	bit("Copa", V(9, 7, 9), CF(-204, Y + 11, -272), rgb(70, 130, 60), Enum.Material.Grass)
	bit("Papelera", V(1.4, 2.4, 1.4), CF(-226, Y + 1.2, -334), rgb(40, 130, 90), Enum.Material.Metal)
	sign("PIPICÁN\nRecoge lo de tu perro 🐶", V(4.4, 2, 0.2), CF(-213, Y + 4.2, -338.3), rgb(250, 246, 236), rgb(40, 90, 70))
	bit("SignPost", V(0.25, 3.4, 0.25), CF(-213, Y + 1.7, -338.2), STEEL, Enum.Material.Metal)
	m:SetAttribute("Strays", #Pets.Strays)
	return m
end

---------------------------------------------------------------------
-- Cercados de los animales de granja
---------------------------------------------------------------------
local G = FarmAnimals.GROUND_Y

local function post(x: number, z: number, h: number, w: number)
	solid("Poste", V(w, h, w), CF(x, G + h / 2, z), DARK_WOOD, Enum.Material.Wood)
end

local function rails(ax: number, az: number, bx: number, bz: number, heights: { number }, thick: number, gap: { number }?)
	for _, y in heights do
		wall("Travesano", ax, az, bx, bz, G + y - thick / 2, thick, thick * 0.6, WOOD, Enum.Material.Wood, if gap then { gap } else nil)
	end
end

local function fenceSide(ax: number, az: number, bx: number, bz: number, strong: boolean, gap: { number }?)
	local h = if strong then 5 else FarmAnimals.FENCE_H
	local heights = if strong then { 1.4, 2.8, 4.2 } else { 1.5, 3.1 }
	local thick = if strong then 0.5 else 0.35
	rails(ax, az, bx, bz, heights, thick, gap)
	local alongX = math.abs(bx - ax) > math.abs(bz - az)
	local len = if alongX then math.abs(bx - ax) else math.abs(bz - az)
	local n = math.max(1, math.floor(len / 6))
	for i = 0, n do
		local k = i / n
		post(ax + (bx - ax) * k, az + (bz - az) * k, h + 0.2, if strong then 0.7 else 0.5)
	end
end

local function feeder(x: number, z: number)
	solid("Comedero", V(6, 1.6, 2), CF(x, G + 0.8, z), DARK_WOOD, Enum.Material.WoodPlanks)
	bit("Heno", V(5.4, 0.6, 1.5), CF(x, G + 1.7, z), rgb(214, 186, 96), Enum.Material.Grass)
end

local function trough(x: number, z: number)
	solid("Abrevadero", V(6, 1.8, 2.2), CF(x, G + 0.9, z), rgb(150, 150, 150), Enum.Material.Concrete)
	bit("Agua", V(5.4, 0.1, 1.6), CF(x, G + 1.62, z), rgb(70, 130, 170), Enum.Material.Glass, 0.25)
end

local function bale(x: number, z: number, yaw: number)
	solid("Paca", V(4, 2.2, 2.4), CF(x, G + 1.1, z) * CFrame.Angles(0, yaw, 0), rgb(220, 190, 100), Enum.Material.Grass)
end

local function buildPens(world: Instance)
	local m = Builder.model("CampoAnimales", world)
	model = m
	for _, pen in FarmAnimals.Pens do
		local strong = pen.Fence == "Fuerte"
		local midX = (pen.X0 + pen.X1) / 2
		local gate = { midX - 3, midX + 3 }
		fenceSide(pen.X0, pen.Z0, pen.X1, pen.Z0, strong, gate)
		fenceSide(pen.X0, pen.Z1, pen.X1, pen.Z1, strong)
		fenceSide(pen.X0, pen.Z0, pen.X0, pen.Z1, strong)
		fenceSide(pen.X1, pen.Z0, pen.X1, pen.Z1, strong)
		-- Puerta (cerrada) y su cartel
		solid("Puerta", V(6, if strong then 4.6 else 3.6, 0.3), CF(midX, G + (if strong then 2.6 else 2.1), pen.Z0), rgb(160, 120, 80), Enum.Material.WoodPlanks)
		bit("PuertaAspa", V(0.3, 6.6, 0.32), CF(midX, G + 2.1, pen.Z0) * CFrame.Angles(0, 0, math.rad(58)), DARK_WOOD, Enum.Material.Wood)
		post(midX - 3.2, pen.Z0 - 1.2, 6.5, 0.4)
		sign(pen.Name, V(9, 1.6, 0.25), CF(midX - 3.2, G + 7.2, pen.Z0 - 1.2), rgb(120, 86, 56), rgb(250, 240, 210))
		feeder(pen.Feeder[1], pen.Feeder[2])
		trough(pen.Trough[1], pen.Trough[2])
		if pen.Mud then
			local mud = pen.Mud :: { number }
			solid("Barro", V(0.4, mud[3] * 2, mud[3] * 2), CF(mud[1], G + 0.05, mud[2]) * CFrame.Angles(0, 0, math.pi / 2), rgb(96, 70, 48), Enum.Material.Mud, { Shape = Enum.PartType.Cylinder, CanCollide = false })
		end
		if pen.Shelter then
			-- Cobertizo del rebaño (esquina del fondo, al oeste): techo a un agua sobre postes
			local sx, sz = pen.X0 + 9, pen.Z1 - 7
			for _, dx in { -7, 7 } do
				for _, dz in { -5, 5 } do
					post(sx + dx, sz + dz, if dz > 0 then 7 else 8.5, 0.6)
				end
			end
			solid("TechoCobertizo", V(16, 0.5, 12), CF(sx, G + 8, sz) * CFrame.Angles(math.rad(7), 0, 0), rgb(150, 70, 50), Enum.Material.CorrodedMetal)
			wall("ParedCobertizo", sx - 8, sz + 5.8, sx + 8, sz + 5.8, G, 7, 0.4, WOOD, Enum.Material.WoodPlanks)
			bale(sx - 3, sz + 2, 0)
		end
		if pen.Stable then
			-- Cuadra (esquina del fondo, al este): tres boxes con media puerta
			local cx, cz = pen.X1 - 11, pen.Z1 - 8
			solid("CuadraFondo", V(22, 9, 0.6), CF(cx, G + 4.5, cz + 7.7), rgb(150, 60, 45), Enum.Material.WoodPlanks)
			solid("CuadraLado", V(0.6, 9, 16), CF(cx - 11, G + 4.5, cz), rgb(150, 60, 45), Enum.Material.WoodPlanks)
			solid("CuadraLado", V(0.6, 9, 16), CF(cx + 11, G + 4.5, cz), rgb(150, 60, 45), Enum.Material.WoodPlanks)
			solid("CuadraTejado", V(24, 0.6, 18), CF(cx, G + 9.4, cz) * CFrame.Angles(math.rad(-6), 0, 0), rgb(90, 60, 50), Enum.Material.Slate)
			for i = -1, 1 do
				solid("MediaPuerta", V(6.4, 3.4, 0.4), CF(cx + i * 7.3, G + 1.7, cz - 7.6), rgb(170, 80, 60), Enum.Material.WoodPlanks)
				if i < 1 then
					solid("Separador", V(0.4, 9, 15), CF(cx + i * 7.3 + 3.65, G + 4.5, cz), rgb(150, 60, 45), Enum.Material.WoodPlanks)
				end
			end
			bit("Herradura", V(1.4, 1.4, 0.15), CF(cx, G + 7.3, cz - 7.9), rgb(160, 160, 166), Enum.Material.Metal)
		end
	end
	-- Pajar y pacas entre los cercados; camino de tierra desde la acera
	for i, p in { { -2062, -1720 }, { -2058, -1712 }, { -2068, -1704 }, { -2052, -1696 } } do
		bale(p[1], p[2], (i % 2) * 0.6)
	end
	-- (en dos trozos: en medio está la boca de metro de Villaverde)
	solid("Camino", V(140, 0.3, 28), CF(-2165, G + 0.1, -1809), rgb(150, 124, 86), Enum.Material.Ground, { CanCollide = false })
	solid("Camino", V(56, 0.3, 28), CF(-2001, G + 0.1, -1809), rgb(150, 124, 86), Enum.Material.Ground, { CanCollide = false })
	-- Poste para montar a caballo
	local hx, hz = FarmAnimals.HorseStation[1], FarmAnimals.HorseStation[2]
	post(hx - 2, hz, 7.5, 0.5)
	post(hx + 2, hz, 7.5, 0.5)
	sign("🐴 MONTAR A CABALLO\nGratis · paseo libre", V(6, 2.6, 0.3), CF(hx, G + 6.2, hz - 0.2), rgb(120, 86, 56), rgb(250, 240, 210))
	solid("HorseStation", V(4, 1, 1), CF(hx, G + 2, hz), WOOD, Enum.Material.Wood, { Tags = { "HorseStation" } })
	bit("Silla", V(1.8, 0.8, 2), CF(hx, G + 2.8, hz), rgb(90, 50, 30), Enum.Material.Leather)
	-- Cartel en la carretera
	post(-2140, -1823, 8, 0.5)
	post(-2128, -1823, 8, 0.5)
	sign("🐄 CAMPOS DE VALMAR 🐴\nVacas · toro · ovejas · cabras · cerdos · caballos", V(14, 3.4, 0.3), CF(-2134, G + 7, -1823.3), rgb(70, 110, 60), rgb(250, 246, 226))
	return m
end

-- Quita los árboles del campo que hayan caído dentro de los cercados o de la protectora
local function clearTrees(world: Instance)
	local rects = { { AnimalKit.Shelter.X0 - 4, AnimalKit.Shelter.X1 + 4, AnimalKit.Shelter.Z0 - 4, AnimalKit.Shelter.Z1 + 4 } }
	for _, pen in FarmAnimals.Pens do
		table.insert(rects, { pen.X0 - 6, pen.X1 + 6, pen.Z0 - 30, pen.Z1 + 6 })
	end
	local campo = world:FindFirstChild("Campo")
	if not campo then
		return
	end
	for _, tree in campo:GetChildren() do
		-- (sin GetPivot: el constructor de Lune no lo tiene) dónde está su primera pieza
		local part = if tree:IsA("BasePart") then tree else tree:FindFirstChildWhichIsA("BasePart", true)
		local cf = if part then (part :: BasePart).CFrame else nil
		if cf then
			for _, r in rects do
				if cf.X > r[1] and cf.X < r[2] and cf.Z > r[3] and cf.Z < r[4] then
					tree:Destroy()
					break
				end
			end
		end
	end
end

function AnimalKit.build(world: Instance)
	clearTrees(world)
	buildShelter(world)
	buildPens(world)
end

return AnimalKit
