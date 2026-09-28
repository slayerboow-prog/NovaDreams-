-- DreamIsland: el sueño del prólogo (Misiones/Prologo_Sueno.luau). Una isla pequeña y segura, muy
-- lejos de la ciudad y en el cielo, donde un personaje nuevo aprende los controles jugando:
--   inicio → círculo de luz (moverse) → pradera (correr) → valla de flores (saltar) → Cosme (hablar)
--   → tornillo que brilla (coger) → cajas y árboles hasta la puerta del garaje (seguir la línea).
-- Arriba, la Grieta: una línea verde que cruza el cielo.
-- Muros invisibles alrededor (no se puede caer) y la valla ocupa todo el ancho (solo se pasa saltando).
-- Deja las marcas StorySpot (Prologo_*) que usan Locations y las cinemáticas del prólogo.
-- Se construye al arrancar el servidor (Main.server.luau); no está dentro del archivo del mapa.

local Builder = require(script.Parent.Parent.Builder)
local StoryMarks = require(script.Parent.StoryMarks)

local DreamIsland = {}

-- Dónde está: lejos de todo y alto (por debajo de las salas de los edificios, que empiezan en Y = 3000)
DreamIsland.Origin = Vector3.new(-3400, 700, -3400)
DreamIsland.Length = 164 -- a lo largo del eje X
DreamIsland.Width = 48 -- a lo ancho (eje Z)

local rgb = Color3.fromRGB
local V = Vector3.new

-- Posiciones (en studs desde el origen; y = 0 es el suelo). Las usa también la prueba del prólogo.
DreamIsland.Spots = {
	Prologo_Inicio = V(6, 0, 0),
	Prologo_Camino = V(30, 0, 0),
	Prologo_Salto = V(64, 0, 0),
	Prologo_Cosme = V(80, 0, -8),
	Prologo_Tornillo = V(88, 0, 10),
	Prologo_Puerta = V(146, 0, -12),
}
DreamIsland.HedgeX = 52 -- la valla de flores (hay que saltarla)

function DreamIsland.build(): Model?
	local existing = workspace:FindFirstChild("DreamIsland")
	if existing then
		return existing :: Model
	end
	local O = DreamIsland.Origin
	local L, W = DreamIsland.Length, DreamIsland.Width
	local model = Builder.model("DreamIsland", workspace)
	pcall(function()
		(model :: any).ModelStreamingMode = Enum.ModelStreamingMode.Persistent -- la isla entera, siempre (es pequeña)
	end)

	local function at(x: number, y: number, z: number): Vector3
		return O + V(x, y, z)
	end

	-- Suelo: césped de sueño (un poco lila) y una tierra que cuelga por debajo
	Builder.part({ Name = "Suelo", Size = V(L, 6, W), CFrame = CFrame.new(at(L / 2 - 2, -3, 0)), Color = rgb(150, 205, 160), Material = Enum.Material.Grass, Parent = model })
	Builder.decor({ Name = "Tierra", Size = V(L - 12, 14, W - 10), CFrame = CFrame.new(at(L / 2 - 2, -13, 0)), Color = rgb(150, 120, 160), Material = Enum.Material.Slate, Parent = model })
	-- Camino claro hasta el garaje
	Builder.decor({ Name = "Camino", Size = V(L - 8, 0.2, 6), CFrame = CFrame.new(at(L / 2 - 2, 0.1, 0)), Color = rgb(240, 225, 200), Material = Enum.Material.Sand, Parent = model })

	-- Muros invisibles: no se puede caer (altos: no se saltan)
	local wallHeight = 18
	for _, spec in {
		{ Size = V(L + 4, wallHeight, 2), Pos = V(L / 2 - 2, wallHeight / 2, W / 2 + 1) },
		{ Size = V(L + 4, wallHeight, 2), Pos = V(L / 2 - 2, wallHeight / 2, -W / 2 - 1) },
		{ Size = V(2, wallHeight, W + 4), Pos = V(-3, wallHeight / 2, 0) },
		{ Size = V(2, wallHeight, W + 4), Pos = V(L - 1, wallHeight / 2, 0) },
	} do
		Builder.part({ Name = "MuroInvisible", Size = spec.Size, CFrame = CFrame.new(O + spec.Pos), Transparency = 1, CastShadow = false, Parent = model })
	end
	-- Borde visible: setos bajos de flores (el muro invisible está justo detrás)
	for _, z in { W / 2 - 0.5, -W / 2 + 0.5 } do
		Builder.decor({ Name = "Borde", Size = V(L, 1.2, 1), CFrame = CFrame.new(at(L / 2 - 2, 0.6, z)), Color = rgb(120, 180, 120), Material = Enum.Material.Grass, Parent = model })
	end

	-- Círculo de luz (moverse)
	local ring = DreamIsland.Spots.Prologo_Camino
	Builder.decor({ Name = "CirculoDeLuz", Shape = Enum.PartType.Cylinder, Size = V(0.3, 9, 9), CFrame = CFrame.new(at(ring.X, 0.2, ring.Z)) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(120, 220, 255), Material = Enum.Material.Neon, Transparency = 0.35, Parent = model })

	-- La valla de flores (saltar): de muro a muro, baja
	local hedge = Builder.part({ Name = "VallaDeFlores", Size = V(2, 2.4, W), CFrame = CFrame.new(at(DreamIsland.HedgeX, 1.2, 0)), Color = rgb(90, 160, 90), Material = Enum.Material.Grass, Parent = model })
	for i = -W / 2 + 3, W / 2 - 3, 4 do
		Builder.decor({ Name = "Flor", Shape = Enum.PartType.Ball, Size = V(1.2, 1.2, 1.2), CFrame = CFrame.new(at(DreamIsland.HedgeX, 2.6, i)), Color = if (i // 4) % 2 == 0 then rgb(255, 150, 200) else rgb(255, 230, 120), Material = Enum.Material.SmoothPlastic, Parent = model })
	end
	hedge:SetAttribute("Prologue", "Jump")

	-- Obstáculos entre el tornillo y la puerta (para seguir la línea de luz)
	for _, spec in {
		{ Pos = V(104, 3, -2), Size = V(6, 6, 10), Color = rgb(200, 160, 110) },
		{ Pos = V(116, 3, 10), Size = V(8, 6, 8), Color = rgb(180, 140, 200) },
		{ Pos = V(124, 3, -8), Size = V(5, 6, 14), Color = rgb(160, 200, 230) },
		{ Pos = V(134, 3, 6), Size = V(6, 6, 6), Color = rgb(230, 190, 120) },
	} do
		Builder.part({ Name = "Caja", Size = spec.Size, CFrame = CFrame.new(O + spec.Pos), Color = spec.Color, Material = Enum.Material.WoodPlanks, Parent = model })
	end
	-- Árboles de sueño (copa redonda que brilla un poco)
	for _, pos in { V(20, 0, 16), V(40, 0, -16), V(72, 0, 16), V(96, 0, -18), V(112, 0, -16), V(140, 0, 16) } do
		Builder.part({ Name = "Tronco", Size = V(1.6, 8, 1.6), CFrame = CFrame.new(O + pos + V(0, 4, 0)), Color = rgb(120, 90, 70), Material = Enum.Material.Wood, Parent = model })
		Builder.decor({ Name = "Copa", Shape = Enum.PartType.Ball, Size = V(8, 8, 8), CFrame = CFrame.new(O + pos + V(0, 10, 0)), Color = rgb(170, 140, 230), Material = Enum.Material.SmoothPlastic, Parent = model })
	end
	-- Farolas de luz suave
	for x = 12, L - 12, 24 do
		local lamp = Builder.decor({ Name = "Farola", Size = V(0.6, 7, 0.6), CFrame = CFrame.new(at(x, 3.5, 4)), Color = rgb(60, 60, 80), Material = Enum.Material.Metal, Parent = model })
		local bulb = Builder.decor({ Name = "Luz", Shape = Enum.PartType.Ball, Size = V(1.4, 1.4, 1.4), CFrame = CFrame.new(at(x, 7.4, 4)), Color = rgb(255, 240, 200), Material = Enum.Material.Neon, Parent = model })
		local light = Instance.new("PointLight")
		light.Range = 18
		light.Brightness = 1.2
		light.Color = rgb(255, 235, 200)
		light.Parent = bulb
		lamp:SetAttribute("Decor", true)
	end

	-- El garaje (al fondo): paredes, tejado y una puerta con luz verde
	local door = DreamIsland.Spots.Prologo_Puerta
	local gx, gz = door.X + 8, door.Z
	Builder.part({ Name = "Garaje", Size = V(12, 10, 14), CFrame = CFrame.new(at(gx, 5, gz)), Color = rgb(210, 205, 195), Material = Enum.Material.Concrete, Parent = model })
	Builder.decor({ Name = "Tejado", Size = V(13, 1, 15), CFrame = CFrame.new(at(gx, 10.5, gz)), Color = rgb(90, 70, 70), Material = Enum.Material.Slate, Parent = model })
	Builder.decor({ Name = "Puerta", Size = V(0.4, 7, 8), CFrame = CFrame.new(at(gx - 6.2, 3.5, gz)), Color = rgb(90, 255, 150), Material = Enum.Material.Neon, Transparency = 0.2, Parent = model })

	-- La Grieta: una costura verde que cruza el cielo, encima de toda la isla
	local crack = Builder.decor({ Name = "Grieta", Size = V(L + 60, 0.8, 1.6), CFrame = CFrame.new(at(L / 2, 70, 0)) * CFrame.Angles(0, math.rad(12), math.rad(4)), Color = rgb(90, 255, 140), Material = Enum.Material.Neon, Parent = model })
	local glow = Instance.new("PointLight")
	glow.Range = 60
	glow.Brightness = 2
	glow.Color = rgb(90, 255, 140)
	glow.Parent = crack

	-- Nubes por debajo (se ve que es un sueño en el cielo)
	for _, pos in { V(-30, -30, 40), V(60, -40, -60), V(150, -34, 50), V(200, -28, -20), V(20, -50, -30) } do
		Builder.decor({ Name = "Nube", Shape = Enum.PartType.Ball, Size = V(40, 16, 30), CFrame = CFrame.new(O + pos), Color = rgb(250, 250, 255), Material = Enum.Material.SmoothPlastic, Transparency = 0.25, Parent = model })
	end

	-- Marcas para la historia (a la altura de los pies + 2.5; LookVector = hacia dónde se mira)
	local facing = {
		Prologo_Inicio = V(1, 0, 0),
		Prologo_Camino = V(1, 0, 0),
		Prologo_Salto = V(1, 0, 0),
		Prologo_Cosme = V(-1, 0, 0.3),
		Prologo_Tornillo = V(1, 0, 0),
		Prologo_Puerta = V(1, 0, 0),
	}
	for id, pos in DreamIsland.Spots do
		StoryMarks.spot(model, id, Builder.facing(O + pos + V(0, 2.5, 0), facing[id] or V(1, 0, 0)), { Dream = true })
	end
	return model
end

return DreamIsland
