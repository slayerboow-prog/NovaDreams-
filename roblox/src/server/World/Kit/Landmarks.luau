-- Landmarks: los lugares especiales del mapa ilustrado de Valmar que no son manzanas de ciudad.
--   * Puerto de Valmar  (costa sur, Distrito Sur): lo construye Kit/Puerto (shared/Port/PuertoPlan):
--                       dársena, muelles, grúas, contenedores, lonja, estación marítima y la barca al faro
--   * Isla del Faro     (en el mar): faro de rayas rojas y blancas con luz giratoria de noche
--   * Mirador           (colina al norte de Valmar Norte): plataforma con barandilla, bancos y catalejos
-- El terreno de la isla y de la colina lo pone TerrainBuilder al arrancar (Landmarks.terrain).
-- La luz del faro y la barca las maneja WorldService (etiquetas "FaroLuz" y "Ferry").

local Builder = require(script.Parent.Parent.Builder)
local Palette = require(script.Parent.Palette)
local Props = require(script.Parent.Props)
local FishingKit = require(script.Parent.FishingKit)

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
-- (el Puerto de Valmar: Kit/Puerto, con el plano de shared/Port/PuertoPlan)
Landmarks.Port = place("PuertoMercancias")
local PuertoPlan = require(game:GetService("ReplicatedStorage").Shared.Port.PuertoPlan)
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
-- Barcos de adorno (isla y puerto deportivo). El Puerto de Valmar está en Kit/Puerto.
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
	ferryPrompt(dock, "Volver al puerto", PuertoPlan.FerryArrival)
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

---------------------------------------------------------------------
-- Puerto deportivo (costa oeste): pantalanes con yates y club náutico
---------------------------------------------------------------------

-- Barcos propios (BoatService): la oficina «⚓ Barcos» en la esquina del muelle (tag BoatMarina, con
-- el cartel «Barcos» para sacar, guardar y comprar), el pantalán de amarres hacia el norte y sus
-- amarres (tag BoatSlip: a la altura del mar, mirando a mar abierto; Slip = orden). Al lado, una
-- lancha en venta sobre su remolque.
Landmarks.BoatSlips = 8
local function boatBerths(m: Instance, shore: number, c: Vector3)
	local SEA = require(game:GetService("ReplicatedStorage").Shared.Boats).SeaLevel
	local px = shore - 6 -- eje del pantalán (6 de ancho: x de shore - 9 a shore - 3)
	local z0, z1 = c.Z - 60, c.Z - 140 -- del borde norte del muelle hacia el norte
	-- Oficina (mira al muelle, al este)
	local office = Builder.part({
		Name = "OficinaBarcos",
		Size = Vector3.new(6, 6, 6),
		CFrame = Builder.facing(Vector3.new(px, 4, c.Z - 50), Vector3.new(1, 0, 0)),
		Color = WHITE,
		Tags = { "BoatMarina" },
		Parent = m,
	})
	Builder.decor({ Name = "OfficeRoof", Size = Vector3.new(7.4, 0.6, 7.4), CFrame = CFrame.new(px, 7.3, c.Z - 50), Color = rgb(40, 90, 150), Parent = m })
	Builder.decor({ Name = "OfficeWindow", Size = Vector3.new(0.1, 2, 3.6), CFrame = CFrame.new(px + 3.02, 4.5, c.Z - 50), Color = rgb(60, 100, 140), Material = Enum.Material.Glass, Parent = m })
	board(m, CFrame.new(px, 9.2, c.Z - 50) * CFrame.Angles(0, math.rad(90), 0), 7, 1.8, "⚓ BARCOS", rgb(20, 70, 130))
	-- Pantalán de amarres, con postes, bolardos y un cartel al principio
	Builder.part({ Name = "BoatPier", Size = Vector3.new(6, 1, z0 - z1), CFrame = CFrame.new(px, 0.5, (z0 + z1) / 2), Color = WOOD, Material = Enum.Material.WoodPlanks, Parent = m })
	for z = z1 + 2, z0 - 2, 13 do
		for _, dx in { -3.3, 3.3 } do
			Builder.decor({ Name = "Post", Size = Vector3.new(0.9, 9, 0.9), CFrame = CFrame.new(px + dx, -3.5, z), Color = DARK_WOOD, Material = Enum.Material.Wood, Parent = m })
		end
		Builder.decor({ Name = "Cleat", Size = Vector3.new(0.4, 0.3, 1.2), CFrame = CFrame.new(px - 2.6, 1.15, z + 6), Color = rgb(40, 44, 50), Material = Enum.Material.Metal, Parent = m })
	end
	-- (en el borde este del pantalán: no estorba al pasar)
	board(m, CFrame.new(px + 2.75, 3.4, z0 - 4) * CFrame.Angles(0, math.rad(90), 0), 5, 1.2, "AMARRES · BARCOS PROPIOS", rgb(20, 70, 130))
	for _, dz in { -2.4, 2.4 } do
		Builder.part({ Name = "SignPost", Size = Vector3.new(0.3, 2.8, 0.3), CFrame = CFrame.new(px + 2.75, 1.4, z0 - 4 + dz), Color = DARK_WOOD, Parent = m })
	end
	-- Amarres: primero los que tocan al pantalán (se baja a él), luego una segunda fila
	local n = 0
	for _, x in { px - 3 - 1.5 - 10, px - 3 - 1.5 - 10 - 23.5 } do
		for i = 0, 3 do
			n += 1
			Builder.part({
				Name = "BoatSlip",
				Size = Vector3.new(7, 0.2, 20),
				CFrame = Builder.facing(Vector3.new(x, SEA, z0 - 15 - i * 20), Vector3.new(-1, 0, 0)),
				Transparency = 1,
				CanCollide = false,
				CanQuery = false,
				CanTouch = false,
				Tags = { "BoatSlip" },
				Attributes = { Slip = n },
				Parent = m,
			})
		end
	end
	-- Boyas que marcan la salida
	for i = 0, 3 do
		local buoy = Builder.decor({ Name = "Buoy", Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.6, 1.6), CFrame = CFrame.new(px - 62, SEA + 0.3, z0 - 5 - i * 22), Color = if i % 2 == 0 then RED else rgb(40, 150, 70), Parent = m })
		buoy.CanCollide = false
	end
	-- Lancha en venta sobre su remolque, en el muelle
	local Rides = require(script.Parent.Rides)
	local trailer = CFrame.new(shore + 16, 1, c.Z - 44) * CFrame.Angles(0, math.rad(90), 0)
	for _, dx in { -1.6, 1.6 } do
		Builder.decor({ Name = "TrailerRail", Size = Vector3.new(0.4, 0.4, 15), CFrame = trailer * CFrame.new(dx, 0.9, 0), Color = rgb(60, 62, 66), Material = Enum.Material.Metal, Parent = m })
		Builder.decor({ Name = "TrailerWheel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 1.4, 1.4), CFrame = trailer * CFrame.new(dx * 1.9, 0.7, 1.5), Color = rgb(26, 26, 28), Material = Enum.Material.Rubber, Parent = m })
	end
	local display = Rides.build("Lancha", m, trailer * CFrame.new(0, 2.3, 0), rgb(30, 90, 170))
	display.Name = "LanchaEnVenta"
	board(m, Builder.facing(Vector3.new(shore + 16, 2, c.Z - 34), Vector3.new(1, 0, 0)), 4, 1.4, "EN VENTA · 7.500 €", rgb(20, 70, 130))
	return office
end
local function buildMarina(world: Instance)
	local m = Builder.model("Marina", world)
	local c = place("Marina")
	local shore = c.X - 200 -- aquí empieza el agua
	-- Muelle principal hacia el mar (oeste) y tres pantalanes
	Builder.part({ Name = "Quay", Size = Vector3.new(70, 3, 120), CFrame = CFrame.new(shore + 20, -0.5, c.Z), Color = rgb(206, 200, 190), Material = Enum.Material.Limestone, Parent = m })
	Builder.part({ Name = "Pier", Size = Vector3.new(220, 1, 10), CFrame = CFrame.new(shore - 110, 0.5, c.Z), Color = WOOD, Material = Enum.Material.WoodPlanks, Parent = m })
	local yachts = { rgb(250, 250, 250), rgb(240, 240, 236), rgb(30, 40, 70), rgb(250, 250, 250) }
	for i, x in { shore - 50, shore - 110, shore - 170 } do
		Builder.part({ Name = "Finger", Size = Vector3.new(6, 1, 90), CFrame = CFrame.new(x, 0.5, c.Z), Color = WOOD, Material = Enum.Material.WoodPlanks, Parent = m })
		for _, dz in { -30, 30 } do
			for _, dx in { -11, 11 } do
				boat(m, CFrame.new(x + dx, 0, c.Z + dz), yachts[(i + (if dx > 0 then 1 else 0)) % #yachts + 1])
			end
		end
	end
	-- Club náutico y cartel
	Builder.part({ Name = "Club", Size = Vector3.new(30, 12, 40), CFrame = CFrame.new(shore + 60, 6, c.Z - 60), Color = WHITE, Material = Enum.Material.Plaster, Parent = m })
	Builder.part({ Name = "ClubRoof", Size = Vector3.new(34, 1, 44), CFrame = CFrame.new(shore + 60, 12.5, c.Z - 60), Color = rgb(40, 90, 150), Material = Enum.Material.Metal, Parent = m })
	board(m, Builder.facing(Vector3.new(shore + 44.6, 8, c.Z - 60), Vector3.new(-1, 0, 0)), 20, 3, "PUERTO DEPORTIVO", rgb(20, 70, 130))
	for _, z in { c.Z - 40, c.Z + 40 } do
		Props.lamp(m, Builder.facing(Vector3.new(shore - 60, 1, z / 2 + c.Z / 2), Vector3.new(0, 0, 1)))
	end
	boatBerths(m, shore, c)
	return m
end

-- Pantalanes de pesca en los lagos y en el río
local function buildFishingZones(world: Instance)
	local lakes = CityPlan.Lakes
	-- Lago del Parque Natural: orilla que mira a la ciudad (este)
	local park = lakes[1]
	FishingKit.jetty(world, Builder.facing(Vector3.new(park.X + park.R + 5, 0, park.Z), Vector3.new(-1, 0, 0)), "Lago", "Pesca · " .. park.Name)
	-- Lago de Montaña: orilla sur
	local mountain = lakes[2]
	FishingKit.jetty(world, Builder.facing(Vector3.new(mountain.X, 0, mountain.Z + mountain.R + 5), Vector3.new(0, 0, -1)), "Lago", "Pesca · " .. mountain.Name)
	-- Río: dos pantalanes en la orilla oeste
	local half = CityPlan.River.Width / 2
	for _, p in { { 1513, -400 }, { 1514, 1000 } } do
		FishingKit.jetty(world, Builder.facing(Vector3.new(p[1] - half - 5, 0, p[2]), Vector3.new(1, 0, 0)), "Rio", "Pesca · Río Valmar")
	end
end

function Landmarks.build(world: Instance)
	require(script.Parent.Puerto).build(world, Landmarks.Island + Vector3.new(-ISLAND_RADIUS + 14, 5, 0))
	buildFishingZones(world)
	buildIsland(world)
	buildLookout(world)
	buildMarina(world)
	editOnly(world)
end

-- Terreno de la isla y de la colina (lo llama TerrainBuilder al arrancar el servidor)
function Landmarks.terrain(terrain: Terrain)
	-- La isla del faro la pone TerrainBuilder (CityPlan.Islands); aquí solo la colina del mirador
	local h = Landmarks.Hill
	terrain:FillBall(Vector3.new(h.X, Landmarks.HillTop - 1 - HILL_RADIUS, h.Z), HILL_RADIUS, Enum.Material.LeafyGrass) -- (sin briznas 3D junto al mirador: TerrainBuilder.Flat)
end

-- Zonas donde no se plantan árboles del campo
function Landmarks.blocked(x: number, z: number): boolean
	local h = Landmarks.Hill
	if math.abs(x - h.X) < 90 and z > h.Z - 90 and z < h.Z + 200 then
		return true -- colina y camino del mirador
	end
	local marina = place("Marina")
	if math.abs(x - marina.X) < 260 and math.abs(z - marina.Z) < 140 then
		return true
	end
	-- (todo el recinto del Puerto de Valmar)
	return PuertoPlan.inRect(PuertoPlan.Area, x, z, 10)
end

return Landmarks
