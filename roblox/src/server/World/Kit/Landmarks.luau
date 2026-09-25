-- Landmarks: los lugares especiales del mapa ilustrado de Valmar que no son manzanas de ciudad.
--   * Puerto de Valmar  (costa, al sur de Playa Dorada): muelle, barcos, contenedores y la barca al faro
--   * Isla del Faro     (en el mar): faro de rayas rojas y blancas con luz giratoria de noche
--   * Mirador           (colina al norte de Valmar Norte): plataforma con barandilla, bancos y catalejos
-- El terreno de la isla y de la colina lo pone TerrainBuilder al arrancar (Landmarks.terrain).
-- La luz del faro y la barca las maneja WorldService (etiquetas "FaroLuz" y "Ferry").

local Builder = require(script.Parent.Parent.Builder)
local Palette = require(script.Parent.Palette)
local Props = require(script.Parent.Props)

local Landmarks = {}

local rgb = Color3.fromRGB
local S = Palette.Street
local WOOD = rgb(128, 94, 64)
local DARK_WOOD = rgb(92, 66, 46)
local WHITE = rgb(240, 240, 236)
local RED = rgb(200, 40, 44)

-- Posiciones (X, Z) de cada sitio
-- (según el plano de la ciudad, CityPlan.Places)
local CityPlan = require(game:GetService("ReplicatedStorage").Shared.CityPlan)
local function place(name: string): Vector3
	local p = CityPlan.Places[name]
	return Vector3.new(p[1], 0, p[2])
end
-- El puerto se construye "de lado" (mar hacia +X) y luego se gira para que mire al mar del sur
Landmarks.Port = place("PuertoMercancias")
local PORT_CF = CFrame.new(Landmarks.Port) * CFrame.Angles(0, -math.pi / 2, 0)
Landmarks.Island = place("Faro")
Landmarks.Hill = place("Mirador")
Landmarks.HillTop = 29.5 -- altura del suelo de la plataforma del mirador
local HILL_RADIUS = 100 -- esfera de terreno: centro 70 studs bajo tierra
local ISLAND_RADIUS = 140 -- hasta donde llega la hierba de la isla (CityPlan.Islands)

local function board(parent: Instance, cf: CFrame, width: number, height: number, text: string, color: Color3)
	local part = Builder.part({ Name = "Sign", Size = Vector3.new(width, height, 0.4), CFrame = cf, Color = color, Parent = parent })
	Builder.sign(part, text, Enum.NormalId.Front, WHITE, color)
	Builder.sign(part, text, Enum.NormalId.Back, WHITE, color)
	return part
end

local function cylinder(parent: Instance, name: string, center: Vector3, height: number, diameter: number, color: Color3, material: Enum.Material?, decor: boolean?)
	local props = {
		Name = name,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, diameter, diameter),
		CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
		Parent = parent,
	}
	return if decor then Builder.decor(props) else Builder.part(props)
end

local function ferryPrompt(parent: BasePart, text: string, target: Vector3)
	local prompt = Builder.prompt(parent, text, "Barca", 0)
	prompt.MaxActivationDistance = 12
	prompt:AddTag("Ferry")
	prompt:SetAttribute("Target", target)
end

---------------------------------------------------------------------
-- Puerto
---------------------------------------------------------------------
local function boat(parent: Instance, cf: CFrame, color: Color3)
	local m = Builder.model("Barco", parent)
	Builder.part({ Name = "Hull", Size = Vector3.new(8, 3, 22), CFrame = cf * CFrame.new(0, -0.3, 0), Color = color, Parent = m })
	Builder.part({ Name = "Bow", ClassName = "WedgePart", Size = Vector3.new(8, 3, 6), CFrame = cf * CFrame.new(0, -0.3, -14) * CFrame.Angles(0, math.rad(180), 0), Color = color, Parent = m })
	Builder.part({ Name = "Deck", Size = Vector3.new(7.4, 0.3, 21.4), CFrame = cf * CFrame.new(0, 1.3, 0), Color = WOOD, Material = Enum.Material.WoodPlanks, Parent = m })
	Builder.part({ Name = "Cabin", Size = Vector3.new(5.6, 4, 6), CFrame = cf * CFrame.new(0, 3.4, 4), Color = WHITE, Parent = m })
	Builder.decor({ Name = "Window", Size = Vector3.new(4.6, 1.4, 0.1), CFrame = cf * CFrame.new(0, 4.2, 0.95), Color = rgb(60, 100, 140), Material = Enum.Material.Glass, Parent = m })
	Builder.decor({ Name = "Mast", Size = Vector3.new(0.4, 12, 0.4), CFrame = cf * CFrame.new(0, 7.4, -3), Color = WHITE, Parent = m })
	Builder.decor({ Name = "Stripe", Size = Vector3.new(8.1, 0.5, 22.1), CFrame = cf * CFrame.new(0, 0.6, 0), Color = WHITE, Parent = m })
	return m
end

local function container(parent: Instance, cf: CFrame, color: Color3)
	local m = Builder.part({ Name = "Container", Size = Vector3.new(8, 8.5, 20), CFrame = cf * CFrame.new(0, 4.25, 0), Color = color, Material = Enum.Material.CorrodedMetal, Parent = parent })
	for i = -4, 4 do
		Builder.decor({ Name = "Rib", Size = Vector3.new(8.1, 8.2, 0.25), CFrame = cf * CFrame.new(0, 4.25, i * 2.2), Color = color:Lerp(Color3.new(0, 0, 0), 0.2), Parent = parent })
	end
	return m
end

local function buildPort(world: Instance)
	local m = Builder.model("Puerto", world)
	local x0, z0 = 0, 0 -- se construye en el origen y al final se lleva a su sitio
	-- Muelle de piedra en la orilla y pantalán de madera hacia el mar
	Builder.part({ Name = "Quay", Size = Vector3.new(90, 3, 150), CFrame = CFrame.new(x0 - 10, -0.5, z0 + 20), Color = rgb(170, 166, 158), Material = Enum.Material.Concrete, Parent = m })
	Builder.part({ Name = "Pier", Size = Vector3.new(230, 1, 14), CFrame = CFrame.new(x0 + 150, 0.5, z0), Color = WOOD, Material = Enum.Material.WoodPlanks, Parent = m })
	for x = x0 + 45, x0 + 260, 20 do
		for _, dz in { -6.5, 6.5 } do
			Builder.decor({ Name = "Post", Size = Vector3.new(1.2, 10, 1.2), CFrame = CFrame.new(x, -4, z0 + dz), Color = DARK_WOOD, Material = Enum.Material.Wood, Parent = m })
		end
		Builder.decor({ Name = "Bollard", Size = Vector3.new(1, 1.4, 1), CFrame = CFrame.new(x, 1.7, z0 + 6.4), Color = rgb(40, 44, 50), Material = Enum.Material.Metal, Parent = m })
	end
	-- Barcos amarrados a los dos lados
	boat(m, CFrame.new(x0 + 110, 0, z0 - 14) * CFrame.Angles(0, math.rad(90), 0), rgb(40, 90, 170))
	boat(m, CFrame.new(x0 + 170, 0, z0 + 14) * CFrame.Angles(0, math.rad(-90), 0), rgb(200, 60, 50))
	boat(m, CFrame.new(x0 + 230, 0, z0 - 14) * CFrame.Angles(0, math.rad(90), 0), rgb(30, 140, 110))
	-- Zona portuaria: contenedores de colores apilados
	local colors = { rgb(200, 70, 50), rgb(40, 110, 190), rgb(230, 170, 40), rgb(60, 150, 90), rgb(150, 60, 150) }
	local n = 0
	for row = 0, 2 do
		for col = 0, 1 do
			n += 1
			local base = CFrame.new(x0 - 40 + col * 10, 1, z0 + 34 + row * 22)
			container(m, base, colors[(n % #colors) + 1])
			if (row + col) % 2 == 0 then
				container(m, base * CFrame.new(0, 8.5, 0), colors[((n + 2) % #colors) + 1])
			end
		end
	end
	-- Grúa del puerto
	for _, dx in { -6, 6 } do
		for _, dz in { -6, 6 } do
			Builder.part({ Name = "CraneLeg", Size = Vector3.new(1.2, 34, 1.2), CFrame = CFrame.new(x0 + 20 + dx, 18, z0 + 70 + dz), Color = rgb(230, 170, 30), Material = Enum.Material.Metal, Parent = m })
		end
	end
	Builder.part({ Name = "CraneTop", Size = Vector3.new(60, 3, 14), CFrame = CFrame.new(x0 + 40, 36, z0 + 70), Color = rgb(230, 170, 30), Material = Enum.Material.Metal, Parent = m })
	Builder.decor({ Name = "CraneCable", Size = Vector3.new(0.3, 18, 0.3), CFrame = CFrame.new(x0 + 62, 26, z0 + 70), Color = rgb(40, 40, 40), Parent = m })
	-- Farolas, cartel y taquilla de la barca
	for _, x in { x0 + 60, x0 + 140, x0 + 220 } do
		Props.lamp(m, Builder.facing(Vector3.new(x, 1, z0 - 6.2), Vector3.new(0, 0, 1)))
	end
	board(m, Builder.facing(Vector3.new(x0 - 20, 8, z0 - 40), Vector3.new(-1, 0, 0)), 22, 5, "PUERTO DE VALMAR", rgb(20, 70, 130))
	for _, dz in { -9, 9 } do
		Builder.part({ Name = "SignPost", Size = Vector3.new(0.6, 7, 0.6), CFrame = CFrame.new(x0 - 20, 3.5, z0 - 40 + dz), Color = S.Metal, Parent = m })
	end
	local kiosk = Builder.part({ Name = "Taquilla", Size = Vector3.new(6, 6, 6), CFrame = CFrame.new(x0 + 258, 4, z0), Color = WHITE, Parent = m })
	Builder.decor({ Name = "Roof", Size = Vector3.new(7, 0.6, 7), CFrame = CFrame.new(x0 + 258, 7.3, z0), Color = RED, Parent = m })
	board(m, Builder.facing(Vector3.new(x0 + 254.8, 5, z0), Vector3.new(-1, 0, 0)), 5.4, 1.6, "BARCA AL FARO", rgb(20, 70, 130))
	ferryPrompt(kiosk, "Ir a la Isla del Faro", Landmarks.Island + Vector3.new(-ISLAND_RADIUS + 14, 5, 0))
	-- Llevar el puerto a la costa sur, mirando al mar
	for _, part in m:GetDescendants() do
		if part:IsA("BasePart") then
			part.CFrame = PORT_CF * part.CFrame
		end
	end
	return m
end

---------------------------------------------------------------------
-- Isla del Faro
---------------------------------------------------------------------
local function buildIsland(world: Instance)
	local m = Builder.model("Faro", world)
	local c = Landmarks.Island
	-- Base de piedra (el terreno de arena y hierba lo pone TerrainBuilder)
	cylinder(m, "Plinth", Vector3.new(c.X, 0.5, c.Z), 5, 30, rgb(150, 146, 138), Enum.Material.Slate)
	-- Torre de rayas rojas y blancas, cada tramo un poco más estrecho
	local y = 3
	for i = 1, 5 do
		local h = 9
		cylinder(m, "Tower", Vector3.new(c.X, y + h / 2, c.Z), h, 17 - i, if i % 2 == 1 then WHITE else RED)
		y += h
	end
	cylinder(m, "Gallery", Vector3.new(c.X, y + 0.5, c.Z), 1, 17, rgb(40, 44, 50), Enum.Material.Metal)
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		Builder.decor({ Name = "Rail", Size = Vector3.new(0.3, 3, 0.3), CFrame = CFrame.new(c.X + math.cos(a) * 8.2, y + 2.5, c.Z + math.sin(a) * 8.2), Color = rgb(40, 44, 50), Parent = m })
	end
	cylinder(m, "Lantern", Vector3.new(c.X, y + 4.5, c.Z), 7, 9, rgb(200, 230, 255), Enum.Material.Glass, true).Transparency = 0.45
	local lamp = Builder.decor({
		Name = "Lamp",
		Size = Vector3.new(3, 3, 3),
		CFrame = CFrame.new(c.X, y + 4.5, c.Z),
		Color = rgb(255, 236, 170),
		Material = Enum.Material.Neon,
		Tags = { "FaroLuz" },
		Parent = m,
	})
	local beam = Instance.new("SpotLight")
	beam.Face = Enum.NormalId.Front
	beam.Angle = 25
	beam.Range = 60
	beam.Brightness = 8
	beam.Color = rgb(255, 236, 190)
	beam.Enabled = false
	beam.Parent = lamp
	local glow = Instance.new("PointLight")
	glow.Range = 24
	glow.Brightness = 2
	glow.Color = rgb(255, 230, 170)
	glow.Enabled = false
	glow.Parent = lamp
	Builder.part({ Name = "Dome", Shape = Enum.PartType.Ball, Size = Vector3.new(10, 10, 10), CFrame = CFrame.new(c.X, y + 8.5, c.Z), Color = RED, Parent = m })
	Builder.decor({ Name = "Door", Size = Vector3.new(4, 7, 0.4), CFrame = Builder.facing(Vector3.new(c.X - 8.1, 6.5, c.Z), Vector3.new(-1, 0, 0)), Color = DARK_WOOD, Parent = m })
	-- Casita del farero
	local hx = c.X + 22
	Builder.part({ Name = "House", Size = Vector3.new(16, 9, 12), CFrame = CFrame.new(hx, 5.5, c.Z + 14), Color = WHITE, Parent = m })
	Builder.part({ Name = "Roof", ClassName = "WedgePart", Size = Vector3.new(17, 4, 6.5), CFrame = CFrame.new(hx, 12, c.Z + 10.75), Color = RED, Parent = m })
	Builder.part({ Name = "Roof", ClassName = "WedgePart", Size = Vector3.new(17, 4, 6.5), CFrame = CFrame.new(hx, 12, c.Z + 17.25) * CFrame.Angles(0, math.rad(180), 0), Color = RED, Parent = m })
	-- Embarcadero (para volver en barca)
	local dock = Builder.part({ Name = "Dock", Size = Vector3.new(30, 1, 10), CFrame = CFrame.new(c.X - ISLAND_RADIUS + 6, 1.5, c.Z), Color = WOOD, Material = Enum.Material.WoodPlanks, Parent = m })
	boat(m, CFrame.new(c.X - ISLAND_RADIUS - 16, 0, c.Z - 12) * CFrame.Angles(0, math.rad(90), 0), rgb(40, 90, 170))
	board(m, Builder.facing(Vector3.new(c.X - 44, 6, c.Z + 6), Vector3.new(-1, 0, 0)), 14, 3, "ISLA DEL FARO", rgb(20, 70, 130))
	for _, dz in { -6, 6 } do
		Builder.part({ Name = "SignPost", Size = Vector3.new(0.5, 7, 0.5), CFrame = CFrame.new(c.X - 44, 1.5, c.Z + 6 + dz), Color = DARK_WOOD, Parent = m })
	end
	ferryPrompt(dock, "Volver al puerto", PORT_CF * Vector3.new(230, 4, 0))
	-- Unas palmeras y rocas
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2 + 0.4
		Builder.part({
			Name = "Rock",
			Size = Vector3.new(6, 4, 7),
			CFrame = CFrame.new(c.X + math.cos(a) * (ISLAND_RADIUS - 6), 0, c.Z + math.sin(a) * (ISLAND_RADIUS - 6)) * CFrame.Angles(0.3, a, 0.2),
			Color = rgb(120, 116, 108),
			Material = Enum.Material.Rock,
			Parent = m,
		})
	end
	return m
end

---------------------------------------------------------------------
-- Mirador
---------------------------------------------------------------------
local function buildLookout(world: Instance)
	local m = Builder.model("Mirador", world)
	local c = Landmarks.Hill
	local top = Landmarks.HillTop
	-- Plataforma de madera sobre la colina, con postes hasta el suelo
	Builder.part({ Name = "Deck", Size = Vector3.new(34, 1, 26), CFrame = CFrame.new(c.X, top - 0.5, c.Z + 4), Color = WOOD, Material = Enum.Material.WoodPlanks, Parent = m })
	for _, dx in { -16, 16 } do
		for _, dz in { -8, 16 } do
			Builder.decor({ Name = "Post", Size = Vector3.new(1, 10, 1), CFrame = CFrame.new(c.X + dx, top - 5.5, c.Z + dz), Color = DARK_WOOD, Parent = m })
		end
	end
	-- Barandilla hacia la ciudad (sur) y a los lados; por el norte se sube
	local function rail(from: Vector3, to: Vector3)
		local mid, len = (from + to) / 2, (to - from).Magnitude
		local dir = to - from
		Builder.part({ Name = "Rail", Size = Vector3.new(0.4, 0.4, len), CFrame = Builder.facing(mid + Vector3.new(0, 3.4, 0), dir), Color = DARK_WOOD, Parent = m })
		-- Pared invisible para no caerse por el borde
		Builder.part({ Name = "RailGuard", Size = Vector3.new(0.2, 3.4, len), CFrame = Builder.facing(mid + Vector3.new(0, 1.7, 0), dir), Transparency = 1, Parent = m })
		for t = 0, 1, 0.2 do
			local p = from:Lerp(to, t)
			Builder.decor({ Name = "Baluster", Size = Vector3.new(0.3, 3.4, 0.3), CFrame = CFrame.new(p + Vector3.new(0, 1.7, 0)), Color = DARK_WOOD, Parent = m })
		end
	end
	local y = top
	rail(Vector3.new(c.X - 16.8, y, c.Z + 16.8), Vector3.new(c.X + 16.8, y, c.Z + 16.8))
	rail(Vector3.new(c.X - 16.8, y, c.Z - 8.8), Vector3.new(c.X - 16.8, y, c.Z + 16.8))
	rail(Vector3.new(c.X + 16.8, y, c.Z - 8.8), Vector3.new(c.X + 16.8, y, c.Z + 16.8))
	-- Bancos mirando a la ciudad y catalejos
	for _, dx in { -8, 8 } do
		Props.bench(m, Builder.facing(Vector3.new(c.X + dx, top, c.Z + 6), Vector3.new(0, 0, 1)))
	end
	for _, dx in { -12, 0, 12 } do
		local base = Vector3.new(c.X + dx, top, c.Z + 14.5)
		Builder.part({ Name = "ScopePost", Size = Vector3.new(0.5, 3.6, 0.5), CFrame = CFrame.new(base + Vector3.new(0, 1.8, 0)), Color = S.Metal, Material = Enum.Material.Metal, Parent = m })
		Builder.decor({ Name = "Scope", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.4, 0.8, 0.8), CFrame = CFrame.new(base + Vector3.new(0, 4, 0)) * CFrame.Angles(0, math.rad(90), math.rad(-12)), Color = rgb(40, 110, 190), Material = Enum.Material.Metal, Parent = m })
	end
	Props.lamp(m, Builder.facing(Vector3.new(c.X - 14, top, c.Z - 6), Vector3.new(1, 0, 0)))
	-- Cartel al pie de la colina y camino de tierra desde la carretera
	board(m, Builder.facing(Vector3.new(c.X + 10, 7, c.Z + 96), Vector3.new(0, 0, 1)), 16, 3.4, "MIRADOR DE VALMAR", rgb(40, 110, 60))
	for _, dx in { -7, 7 } do
		Builder.part({ Name = "SignPost", Size = Vector3.new(0.5, 6, 0.5), CFrame = CFrame.new(c.X + 10 + dx, 3, c.Z + 96), Color = DARK_WOOD, Parent = m })
	end
	local pathStart, pathEnd = c.Z + 190, c.Z + 72 -- desde la rotonda del final de la Avenida del Norte
	Builder.decor({
		Name = "Path",
		Size = Vector3.new(9, 0.2, pathStart - pathEnd),
		CFrame = CFrame.new(c.X, -0.85, (pathStart + pathEnd) / 2),
		Color = rgb(168, 140, 100),
		Material = Enum.Material.Ground,
		Parent = m,
	})
	return m
end

-- Suelo provisional para verlo en Studio (en el juego lo sustituye el terreno)
local function editOnly(world: Instance)
	local c = Landmarks.Island
	cylinder(world, "IslandPreview", Vector3.new(c.X, -1, c.Z), 4, ISLAND_RADIUS * 2, rgb(226, 206, 160)):AddTag("EditOnly")
	Builder.part({
		Name = "HillPreview",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * HILL_RADIUS * 2,
		CFrame = CFrame.new(Landmarks.Hill.X, Landmarks.HillTop - 1 - HILL_RADIUS, Landmarks.Hill.Z),
		Color = Palette.Ground.Grass,
		Material = Enum.Material.Grass,
		Tags = { "EditOnly" },
		Parent = world,
	})
end

function Landmarks.build(world: Instance)
	buildPort(world)
	buildIsland(world)
	buildLookout(world)
	editOnly(world)
end

-- Terreno de la isla y de la colina (lo llama TerrainBuilder al arrancar el servidor)
function Landmarks.terrain(terrain: Terrain)
	-- La isla del faro la pone TerrainBuilder (CityPlan.Islands); aquí solo la colina del mirador
	local h = Landmarks.Hill
	terrain:FillBall(Vector3.new(h.X, Landmarks.HillTop - 1 - HILL_RADIUS, h.Z), HILL_RADIUS, Enum.Material.Grass)
end

-- Zonas donde no se plantan árboles del campo
function Landmarks.blocked(x: number, z: number): boolean
	local h = Landmarks.Hill
	if math.abs(x - h.X) < 90 and z > h.Z - 90 and z < h.Z + 200 then
		return true -- colina y camino del mirador
	end
	local p = Landmarks.Port
	return math.abs(x - p.X) < 160 and z > p.Z - 140
end

return Landmarks
