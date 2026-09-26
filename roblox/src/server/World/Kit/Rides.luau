-- Rides: modelos de los vehículos que se pueden montar (monopatín, bici, moto y coche).
-- Se usan igual para los que están aparcados en las estaciones públicas (anclados)
-- y para el que lleva el jugador (VehicleService los suelda a su personaje).
--
-- Convención: el CFrame es el centro del vehículo a ras de suelo y su LookVector es el morro.

local Builder = require(script.Parent.Parent.Builder)
local Palette = require(script.Parent.Palette)
local CarModel = require(script.Parent.CarModel)

local Rides = {}

local rgb = Color3.fromRGB
local TIRE = rgb(26, 26, 28)
local METAL = rgb(170, 174, 180)

-- Asiento del conductor (respecto al centro del vehículo a ras de suelo) y tamaño de la base.
-- Standing = se va de pie (el personaje se coloca de pie encima en vez de sentado)
Rides.Spec = {
	Monopatin = { Seat = CFrame.new(0, 0.7, 0), Size = Vector3.new(1.4, 1, 4.2), Standing = true },
	Patinete = { Seat = CFrame.new(0, 0.75, 0.4), Size = Vector3.new(1.4, 1, 3.8), Standing = true },
	Bici = { Seat = CFrame.new(0, 3.2, 1), Size = Vector3.new(1.2, 1, 4.8) },
	Moto = { Seat = CFrame.new(0, 2.55, 0.8), Size = Vector3.new(1.6, 1, 5.8) },
	Coche = { Seat = CFrame.new(-1.4, 1.6, -0.6), Size = Vector3.new(6.2, 1, 13.5) },
	Autobus = { Seat = CFrame.new(-2.4, 3.75, -13), Size = Vector3.new(8.6, 1, 34) },
	Camion = { Seat = CFrame.new(-1.8, 4.2, -9.2), Size = Vector3.new(8, 1, 27) },
	Patrulla = { Seat = CFrame.new(-1.4, 1.6, -0.6), Size = Vector3.new(6.2, 1, 13.5) },
}

local function wheel(m: Model, cf: CFrame, radius: number, width: number)
	return Builder.part({
		Name = "Wheel",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(width, radius * 2, radius * 2),
		CFrame = cf,
		Color = TIRE,
		Material = Enum.Material.Rubber,
		Parent = m,
	})
end

local function box(m: Model, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, transparency: number?)
	return Builder.part({
		Name = name,
		Size = size,
		CFrame = cf,
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
		Transparency = transparency or 0,
		Parent = m,
	})
end

-- Piezas finas (no chocan) y tubos entre dos puntos del plano del vehículo (x fija)
local function bit(m: Model, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, transparency: number?): BasePart
	return Builder.decor({ Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Transparency = transparency or 0, Parent = m })
end
local function cyl(m: Model, name: string, length: number, diameter: number, cf: CFrame, color: Color3, material: Enum.Material?): BasePart
	return Builder.decor({ Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(length, diameter, diameter), CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = m })
end
-- Tubo de a hasta b (puntos en coordenadas del vehículo: x, y, z)
local function tube(m: Model, cf: CFrame, name: string, a: Vector3, b: Vector3, thickness: number, color: Color3, material: Enum.Material?)
	local d = b - a
	local len = d.Magnitude
	local angle = math.atan2(-d.Y, d.Z)
	local yaw = math.atan2(d.X, math.sqrt(d.Y * d.Y + d.Z * d.Z))
	return bit(m, name, Vector3.new(thickness, thickness, len), cf * CFrame.new((a + b) / 2) * CFrame.Angles(angle, 0, 0) * CFrame.Angles(0, yaw, 0), color, material or Enum.Material.Metal)
end
-- Rueda con radios (bici): neumático, llanta, buje y radios
local function spokedWheel(m: Model, cf: CFrame, radius: number, width: number, rimColor: Color3, spokes: number)
	wheel(m, cf, radius, width)
	cyl(m, "Rim", width + 0.04, radius * 1.75, cf, rimColor, Enum.Material.Metal)
	cyl(m, "RimInner", width + 0.06, radius * 1.6, cf, rgb(40, 40, 44), Enum.Material.SmoothPlastic)
	for k = 0, spokes - 1 do
		local a = k * math.pi / spokes
		bit(m, "Spoke", Vector3.new(0.05, 0.05, radius * 1.6), cf * CFrame.Angles(a, 0, 0), rgb(200, 200, 205), Enum.Material.Metal)
	end
	cyl(m, "Hub", width + 0.1, 0.35, cf, METAL, Enum.Material.Metal)
end

local function monopatin(m: Model, cf: CFrame, color: Color3)
	-- Tabla con morro y cola levantados, lija arriba y dibujo abajo
	box(m, "Deck", Vector3.new(1.3, 0.16, 3.2), cf * CFrame.new(0, 0.55, 0), color, Enum.Material.Wood)
	for _, sz in { -1, 1 } do
		-- morro y cola levantados (el extremo de fuera sube)
		local kick = cf * CFrame.new(0, 0.55, sz * 1.6) * CFrame.Angles(math.rad(-sz * 20), 0, 0) * CFrame.new(0, 0, sz * 0.42)
		bit(m, "Kick", Vector3.new(1.3, 0.16, 0.9), kick, color, Enum.Material.Wood)
		bit(m, "KickGrip", Vector3.new(1.22, 0.03, 0.85), kick * CFrame.new(0, 0.09, 0), rgb(25, 25, 28), Enum.Material.Sand)
	end
	bit(m, "Grip", Vector3.new(1.22, 0.03, 3.1), cf * CFrame.new(0, 0.645, 0), rgb(25, 25, 28), Enum.Material.Sand)
	bit(m, "Graphic", Vector3.new(1.1, 0.02, 2.4), cf * CFrame.new(0, 0.46, 0), rgb(250, 250, 250))
	for _, z in { -1.3, 1.3 } do
		bit(m, "Baseplate", Vector3.new(0.6, 0.08, 0.6), cf * CFrame.new(0, 0.44, z), METAL, Enum.Material.Metal)
		bit(m, "Bushing", Vector3.new(0.3, 0.12, 0.3), cf * CFrame.new(0, 0.36, z), rgb(240, 200, 40))
		bit(m, "Hanger", Vector3.new(1.1, 0.14, 0.22), cf * CFrame.new(0, 0.27, z), METAL, Enum.Material.Metal)
		for _, x in { -0.55, 0.55 } do
			wheel(m, cf * CFrame.new(x, 0.22, z), 0.22, 0.22)
			cyl(m, "Bearing", 0.24, 0.16, cf * CFrame.new(x, 0.22, z), METAL, Enum.Material.Metal)
		end
		for _, x in { -0.18, 0.18 } do
			bit(m, "Bolt", Vector3.new(0.06, 0.03, 0.06), cf * CFrame.new(x, 0.665, z + 0.15), METAL, Enum.Material.Metal)
		end
	end
end

local function bici(m: Model, cf: CFrame, color: Color3)
	local r = 1.3
	local rear, front = Vector3.new(0, r, 1.8), Vector3.new(0, r, -1.8)
	local bb = Vector3.new(0, 1.05, 0.15) -- eje de los pedales
	local seatTop = Vector3.new(0, 2.85, 0.75)
	local headTop, headBottom = Vector3.new(0, 3.0, -1.3), Vector3.new(0, 2.25, -1.48)
	for _, p in { rear, front } do
		spokedWheel(m, cf * CFrame.new(p), r, 0.22, rgb(210, 212, 216), 8)
	end
	-- Cuadro (tubos entre sus puntos)
	tube(m, cf, "TopTube", seatTop - Vector3.new(0, 0.2, 0), headTop - Vector3.new(0, 0.1, 0), 0.22, color)
	tube(m, cf, "DownTube", bb, headBottom, 0.26, color)
	tube(m, cf, "SeatTube", bb, seatTop, 0.24, color)
	tube(m, cf, "HeadTube", headBottom, headTop, 0.3, color)
	for _, x in { -0.14, 0.14 } do
		tube(m, cf, "ChainStay", bb + Vector3.new(x, 0, 0), rear + Vector3.new(x, 0, 0), 0.14, color)
		tube(m, cf, "SeatStay", seatTop - Vector3.new(-x, 0.35, 0), rear + Vector3.new(x, 0, 0), 0.12, color)
		tube(m, cf, "Fork", headBottom + Vector3.new(x, 0, 0), front + Vector3.new(x, 0, 0.05), 0.14, METAL)
	end
	-- Manillar, potencia y puños
	tube(m, cf, "Stem", headTop, headTop + Vector3.new(0, 0.3, -0.25), 0.14, rgb(30, 30, 34))
	local bar = headTop + Vector3.new(0, 0.3, -0.25)
	bit(m, "Handlebar", Vector3.new(2, 0.14, 0.14), cf * CFrame.new(bar), rgb(30, 30, 34), Enum.Material.Metal)
	for _, x in { -0.85, 0.85 } do
		cyl(m, "Grip", 0.5, 0.2, cf * CFrame.new(bar + Vector3.new(x, 0, 0)), rgb(20, 20, 22), Enum.Material.Rubber)
		bit(m, "BrakeLever", Vector3.new(0.5, 0.06, 0.08), cf * CFrame.new(bar + Vector3.new(x * 0.8, -0.05, -0.2)), rgb(30, 30, 34), Enum.Material.Metal)
	end
	cyl(m, "Bell", 0.12, 0.3, cf * CFrame.new(bar + Vector3.new(-0.45, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90)), rgb(220, 220, 225), Enum.Material.Metal)
	-- Sillín y tija
	tube(m, cf, "SeatPost", seatTop, seatTop + Vector3.new(0, 0.3, 0.06), 0.12, METAL)
	box(m, "Seat", Vector3.new(0.7, 0.22, 1.1), cf * CFrame.new(seatTop + Vector3.new(0, 0.38, 0.1)), rgb(28, 28, 32), Enum.Material.Fabric)
	-- Transmisión: plato, bielas, pedales, cadena y cambio
	cyl(m, "Chainring", 0.08, 0.95, cf * CFrame.new(bb + Vector3.new(0.22, 0, 0)), rgb(170, 172, 178), Enum.Material.Metal)
	cyl(m, "Cog", 0.08, 0.45, cf * CFrame.new(rear + Vector3.new(0.22, 0, 0)), rgb(170, 172, 178), Enum.Material.Metal)
	for _, dy in { 0.44, -0.44 } do
		tube(m, cf, "Chain", bb + Vector3.new(0.24, dy, 0), rear + Vector3.new(0.24, dy * 0.5, 0), 0.07, rgb(50, 50, 54))
	end
	bit(m, "Derailleur", Vector3.new(0.12, 0.45, 0.3), cf * CFrame.new(rear + Vector3.new(0.3, -0.35, 0.05)), rgb(40, 40, 44), Enum.Material.Metal)
	for _, sx in { -1, 1 } do
		local foot = bb + Vector3.new(sx * 0.35, sx * 0.55, sx * 0.25)
		tube(m, cf, "Crank", bb + Vector3.new(sx * 0.3, 0, 0), foot, 0.1, rgb(160, 162, 168))
		bit(m, "Pedal", Vector3.new(0.5, 0.1, 0.35), cf * CFrame.new(foot + Vector3.new(sx * 0.25, 0, 0)), rgb(30, 30, 34))
	end
	-- Guardabarros y luces
	bit(m, "FenderRear", Vector3.new(0.3, 0.06, 1.4), cf * CFrame.new(rear + Vector3.new(0, r + 0.1, -0.1)) * CFrame.Angles(math.rad(-12), 0, 0), color)
	bit(m, "FenderFront", Vector3.new(0.3, 0.06, 1.2), cf * CFrame.new(front + Vector3.new(0, r + 0.1, 0.1)) * CFrame.Angles(math.rad(12), 0, 0), color)
	bit(m, "Headlight", Vector3.new(0.3, 0.25, 0.15), cf * CFrame.new(bar + Vector3.new(0, -0.25, -0.12)), rgb(255, 250, 230), Enum.Material.Neon)
	bit(m, "Taillight", Vector3.new(0.25, 0.18, 0.08), cf * CFrame.new(seatTop + Vector3.new(0, -0.1, 0.25)), rgb(220, 30, 30), Enum.Material.Neon)
	bit(m, "Reflector", Vector3.new(0.05, 0.3, 0.3), cf * CFrame.new(front + Vector3.new(0.14, 0.6, 0)), rgb(255, 150, 20), Enum.Material.Neon)
	-- Bidón
	cyl(m, "Bottle", 0.6, 0.28, cf * CFrame.new((bb + headBottom) / 2 + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(math.rad(55), 0, 0), rgb(60, 160, 220))
end

local function moto(m: Model, cf: CFrame, color: Color3)
	local CH = rgb(210, 212, 218)
	local DARK = rgb(28, 28, 32)
	-- Ruedas con llanta, buje y disco de freno
	for _, z in { -2.3, 2.3 } do
		local c = cf * CFrame.new(0, 1, z)
		wheel(m, c, 1, 0.6)
		cyl(m, "Rim", 0.64, 1.3, c, CH, Enum.Material.Metal)
		cyl(m, "Hub", 0.7, 0.4, c, rgb(90, 92, 98), Enum.Material.Metal)
		cyl(m, "BrakeDisc", 0.06, 1.05, c * CFrame.new(-0.38, 0, 0), rgb(160, 162, 168), Enum.Material.Metal)
		bit(m, "Caliper", Vector3.new(0.14, 0.4, 0.3), c * CFrame.new(-0.42, 0.35, 0.3), rgb(200, 40, 40), Enum.Material.Metal)
	end
	-- Horquilla y guardabarros delantero
	for _, x in { -0.28, 0.28 } do
		tube(m, cf, "Fork", Vector3.new(x, 1, -2.3), Vector3.new(x, 3.2, -2.0), 0.18, CH)
	end
	bit(m, "FenderFront", Vector3.new(0.75, 0.12, 1.5), cf * CFrame.new(0, 2.15, -2.3) * CFrame.Angles(math.rad(8), 0, 0), color)
	-- Escudo delantero, plataforma y carrocería trasera redondeada
	box(m, "Shield", Vector3.new(1.5, 2.4, 0.35), cf * CFrame.new(0, 2.05, -1.75) * CFrame.Angles(math.rad(-15), 0, 0), color)
	bit(m, "ShieldTrim", Vector3.new(1.55, 0.1, 0.4), cf * CFrame.new(0, 3.25, -2.05) * CFrame.Angles(math.rad(-15), 0, 0), CH, Enum.Material.Metal)
	box(m, "Floor", Vector3.new(1.3, 0.25, 1.7), cf * CFrame.new(0, 1.05, -0.75), DARK, Enum.Material.Rubber)
	for _, x in { -0.62, 0.62 } do
		bit(m, "FloorTrim", Vector3.new(0.08, 0.28, 1.7), cf * CFrame.new(x, 1.08, -0.75), CH, Enum.Material.Metal)
	end
	box(m, "Body", Vector3.new(1.4, 1.1, 2.4), cf * CFrame.new(0, 1.65, 0.9), color)
	cyl(m, "Tail", 1.4, 1.1, cf * CFrame.new(0, 1.65, 2.1), color)
	bit(m, "SidePanelLine", Vector3.new(1.44, 0.06, 2.2), cf * CFrame.new(0, 1.55, 0.9), DARK)
	-- Sillín con asidero cromado
	box(m, "Seat", Vector3.new(1.2, 0.4, 2), cf * CFrame.new(0, 2.35, 0.8), DARK, Enum.Material.Fabric)
	bit(m, "SeatPiping", Vector3.new(1.22, 0.06, 2.02), cf * CFrame.new(0, 2.2, 0.8), rgb(150, 30, 30))
	tube(m, cf, "GrabRail", Vector3.new(-0.55, 2.35, 1.8), Vector3.new(0.55, 2.35, 1.8), 0.12, CH)
	-- Dirección: columna, manillar, puños, maneta y cuadro de mandos
	tube(m, cf, "Stem", Vector3.new(0, 3.1, -2.05), Vector3.new(0, 3.75, -2.0), 0.3, color)
	bit(m, "Handlebar", Vector3.new(2.2, 0.18, 0.18), cf * CFrame.new(0, 3.85, -1.98), DARK, Enum.Material.Metal)
	for _, x in { -1, 1 } do
		cyl(m, "Grip", 0.45, 0.24, cf * CFrame.new(x * 0.95, 3.85, -1.98), rgb(20, 20, 22), Enum.Material.Rubber)
		bit(m, "Lever", Vector3.new(0.6, 0.06, 0.1), cf * CFrame.new(x * 0.8, 3.8, -2.2), CH, Enum.Material.Metal)
		-- Retrovisores
		tube(m, cf, "MirrorStalk", Vector3.new(x * 0.6, 3.9, -1.98), Vector3.new(x * 0.85, 4.6, -1.9), 0.07, CH)
		bit(m, "Mirror", Vector3.new(0.45, 0.3, 0.1), cf * CFrame.new(x * 0.87, 4.68, -1.9), DARK)
		-- Intermitentes delante y detrás
		bit(m, "Indicator", Vector3.new(0.2, 0.15, 0.2), cf * CFrame.new(x * 0.6, 3.35, -2.25), rgb(255, 150, 20), Enum.Material.Neon)
		bit(m, "Indicator", Vector3.new(0.2, 0.15, 0.2), cf * CFrame.new(x * 0.5, 1.9, 2.65), rgb(255, 150, 20), Enum.Material.Neon)
	end
	bit(m, "Dash", Vector3.new(0.7, 0.35, 0.1), cf * CFrame.new(0, 3.95, -1.85) * CFrame.Angles(math.rad(-30), 0, 0), rgb(60, 180, 255), Enum.Material.Neon)
	-- Faro redondo (la luz sale del bloque "Headlight") y piloto
	box(m, "Headlight", Vector3.new(0.55, 0.45, 0.2), cf * CFrame.new(0, 3.4, -2.28), rgb(255, 250, 230), Enum.Material.Neon)
	cyl(m, "HeadlightRing", 0.12, 0.8, cf * CFrame.new(0, 3.4, -2.24) * CFrame.Angles(0, math.rad(90), 0), CH, Enum.Material.Metal)
	box(m, "Taillight", Vector3.new(0.6, 0.3, 0.2), cf * CFrame.new(0, 2.1, 2.65), rgb(200, 30, 30), Enum.Material.Neon)
	bit(m, "Plate", Vector3.new(0.9, 0.5, 0.06), cf * CFrame.new(0, 1.55, 2.68) * CFrame.Angles(math.rad(10), 0, 0), rgb(240, 240, 240))
	-- Escape cromado y caballete
	tube(m, cf, "Exhaust", Vector3.new(0.6, 0.9, -0.2), Vector3.new(0.65, 1.2, 1.9), 0.3, CH)
	cyl(m, "ExhaustTip", 0.3, 0.35, cf * CFrame.new(0.65, 1.22, 2.05) * CFrame.Angles(0, math.rad(90), 0), rgb(60, 60, 64), Enum.Material.Metal)
	tube(m, cf, "Kickstand", Vector3.new(-0.5, 0.9, 0.2), Vector3.new(-0.9, 0.1, 0.4), 0.1, DARK)
end

local function patinete(m: Model, cf: CFrame, color: Color3)
	local DARK = rgb(28, 28, 32)
	for _, z in { -1.5, 1.5 } do
		local c = cf * CFrame.new(0, 0.38, z)
		wheel(m, c, 0.38, 0.3)
		cyl(m, "Rim", 0.34, 0.5, c, rgb(60, 60, 64), Enum.Material.Metal)
	end
	-- Plataforma con batería debajo y lija
	box(m, "Deck", Vector3.new(1, 0.2, 2.9), cf * CFrame.new(0, 0.58, 0.1), DARK)
	bit(m, "Battery", Vector3.new(0.8, 0.22, 2.4), cf * CFrame.new(0, 0.38, 0.1), color)
	bit(m, "Grip", Vector3.new(0.9, 0.04, 2.5), cf * CFrame.new(0, 0.7, 0.15), rgb(22, 22, 25), Enum.Material.Sand)
	for _, x in { -0.5, 0.5 } do
		bit(m, "DeckTrim", Vector3.new(0.06, 0.1, 2.8), cf * CFrame.new(x, 0.62, 0.1), color)
	end
	-- Guardabarros trasero con freno de pie y piloto
	bit(m, "FenderRear", Vector3.new(0.4, 0.08, 1), cf * CFrame.new(0, 0.85, 1.45) * CFrame.Angles(math.rad(-10), 0, 0), color)
	bit(m, "Taillight", Vector3.new(0.3, 0.12, 0.08), cf * CFrame.new(0, 0.8, 1.97), rgb(220, 30, 30), Enum.Material.Neon)
	-- Horquilla, bisagra plegable, barra y manillar
	for _, x in { -0.18, 0.18 } do
		tube(m, cf, "Fork", Vector3.new(x, 0.38, -1.5), Vector3.new(x, 1.2, -1.42), 0.1, rgb(60, 60, 64))
	end
	bit(m, "FenderFront", Vector3.new(0.4, 0.06, 0.8), cf * CFrame.new(0, 0.85, -1.5), color)
	bit(m, "Hinge", Vector3.new(0.4, 0.35, 0.4), cf * CFrame.new(0, 0.95, -1.35), DARK, Enum.Material.Metal)
	tube(m, cf, "Stem", Vector3.new(0, 1.1, -1.38), Vector3.new(0, 4.0, -1.72), 0.25, color)
	bit(m, "Handlebar", Vector3.new(1.9, 0.14, 0.14), cf * CFrame.new(0, 4.05, -1.72), DARK, Enum.Material.Metal)
	for _, x in { -0.85, 0.85 } do
		cyl(m, "Grip", 0.4, 0.2, cf * CFrame.new(x, 4.05, -1.72), rgb(20, 20, 22), Enum.Material.Rubber)
	end
	bit(m, "Throttle", Vector3.new(0.18, 0.1, 0.25), cf * CFrame.new(0.6, 4.05, -1.85), DARK)
	bit(m, "Bell", Vector3.new(0.2, 0.12, 0.2), cf * CFrame.new(-0.6, 4.12, -1.72), rgb(220, 220, 225), Enum.Material.Metal)
	bit(m, "Display", Vector3.new(0.4, 0.06, 0.3), cf * CFrame.new(0, 4.12, -1.72), rgb(60, 180, 255), Enum.Material.Neon)
	box(m, "Headlight", Vector3.new(0.4, 0.3, 0.2), cf * CFrame.new(0, 3.5, -1.72), rgb(255, 250, 230), Enum.Material.Neon)
	bit(m, "Logo", Vector3.new(0.05, 0.6, 0.3), cf * CFrame.new(0.13, 2.5, -1.56), rgb(250, 250, 250))
	tube(m, cf, "Kickstand", Vector3.new(-0.45, 0.5, 0.3), Vector3.new(-0.7, 0.05, 0.6), 0.08, DARK)
end

local function coche(m: Model, cf: CFrame, color: Color3)
	-- El coche del jugador: el mismo modelo detallado que los de la ciudad, con interior
	local car = CarModel.build(nil, cf, color, { Name = "Coche", Variant = "Berlina", Interior = true, Plate = ("%04d VLM"):format(math.random(0, 9999)) })
	for _, part in car:GetChildren() do
		part.Parent = m
	end
	car:Destroy()
end

-- Autobús urbano (línea L1), con todo detalle: carrocería con esquinas redondeadas, franja de
-- ventanas oscura, parabrisas con limpias, retrovisores, grupos ópticos LED, letreros luminosos
-- de línea, puertas dobles, pasos de rueda y tapacubos, aire acondicionado en el techo y, dentro,
-- barras, pulsadores de parada, asientos (Seat de verdad), zona de silla de ruedas, validadora,
-- pantalla de próxima parada y puesto del conductor.
-- Convención: cf = centro a ras de suelo; el morro mira hacia -Z; las puertas están a la derecha (+X).
local function autobus(m: Model, cf: CFrame, color: Color3)
	local L, W = 34, 8.6
	local HALF_L, HALF_W = L / 2, W / 2
	local ROOF = 9.6
	local FLOOR = 2.3
	local BLACK = rgb(24, 25, 28)
	local GLASS = rgb(30, 44, 56)
	local WHITE = rgb(240, 240, 240)
	local YELLOW = rgb(250, 196, 30)
	local GREY = rgb(120, 124, 130)
	local SEAT = rgb(40, 80, 160)

	local function at(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x, y, z)
	end
	-- Piezas grandes (chocan) y detalles (no chocan, más baratos)
	local function solid(name: string, size: Vector3, c: CFrame, col: Color3, mat: Enum.Material?, tr: number?): BasePart
		return Builder.part({ Name = name, Size = size, CFrame = c, Color = col, Material = mat or Enum.Material.SmoothPlastic, Transparency = tr or 0, Parent = m })
	end
	local function detail(name: string, size: Vector3, c: CFrame, col: Color3, mat: Enum.Material?, tr: number?): BasePart
		return Builder.decor({ Name = name, Size = size, CFrame = c, Color = col, Material = mat or Enum.Material.SmoothPlastic, Transparency = tr or 0, Parent = m })
	end
	-- Cilindro: eje a lo largo de la X local de c
	local function cylinder(name: string, length: number, diameter: number, c: CFrame, col: Color3, mat: Enum.Material?): BasePart
		return Builder.decor({ Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(length, diameter, diameter), CFrame = c, Color = col, Material = mat or Enum.Material.SmoothPlastic, Parent = m })
	end
	local UP = CFrame.Angles(0, 0, math.rad(90)) -- cilindro vertical
	local ALONG = CFrame.Angles(0, math.rad(90), 0) -- cilindro a lo largo del autobús
	local FORWARD = CFrame.Angles(0, math.rad(90), 0) -- (mirando hacia delante, igual que ALONG)

	---------------------------------------------------------------------
	-- Carrocería
	---------------------------------------------------------------------
	local R = 1.1 -- radio de las esquinas
	local lower0, lower1 = 1.1, 4.3 -- faldón (color de la línea)
	local win0, win1 = 4.3, 8.3 -- franja de ventanas
	local DOORS = { { Z = -13.4, W = 4.6 }, { Z = 4.5, W = 4.6 } }
	-- Faldones laterales (el derecho, partido por las puertas), delantero y trasero
	local function sidePanel(s: number, z0: number, z1: number)
		if z1 - z0 > 0.2 then
			solid("SidePanel", Vector3.new(0.3, lower1 - lower0, z1 - z0), at(s * (HALF_W - 0.15), (lower0 + lower1) / 2, (z0 + z1) / 2), color)
		end
	end
	local z0, z1 = -HALF_L + R, HALF_L - R
	sidePanel(-1, z0, z1)
	local cursor = z0
	for _, d in DOORS do
		sidePanel(1, cursor, d.Z - d.W / 2)
		-- bajo la puerta, solo el zócalo hasta el escalón
		solid("DoorSill", Vector3.new(0.3, FLOOR - 0.5 - lower0, d.W), at(HALF_W - 0.15, (lower0 + FLOOR - 0.5) / 2, d.Z), color)
		cursor = d.Z + d.W / 2
	end
	sidePanel(1, cursor, z1)
	for _, s in { -1, 1 } do
		solid("UpperPanel", Vector3.new(0.3, ROOF - win1, L - 2 * R), at(s * (HALF_W - 0.15), (win1 + ROOF) / 2, 0), color)
	end
	solid("FrontPanel", Vector3.new(W - 2 * R, lower1 - lower0, 0.3), at(0, (lower0 + lower1) / 2, -HALF_L + 0.15), color)
	solid("RearPanel", Vector3.new(W - 2 * R, 5.2, 0.3), at(0, lower0 + 2.6, HALF_L - 0.15), color)
	-- Esquinas redondeadas (columnas cilíndricas de arriba abajo)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local c = at(sx * (HALF_W - R), (lower0 + ROOF) / 2, sz * (HALF_L - R)) * UP
			Builder.part({ Name = "Corner", Shape = Enum.PartType.Cylinder, Size = Vector3.new(ROOF - lower0, 2 * R, 2 * R), CFrame = c, Color = color, Material = Enum.Material.SmoothPlastic, Parent = m })
		end
	end
	-- Relleno interior de las esquinas (tapa el hueco entre paneles y columnas)
	solid("Frame", Vector3.new(W - 0.6, 0.4, L - 0.6), at(0, lower0 + 0.2, 0), rgb(60, 62, 66), Enum.Material.Metal)
	-- Techo con bordes redondeados
	solid("Roof", Vector3.new(W - 1, 0.4, L - 1), at(0, ROOF - 0.2, 0), WHITE)
	for _, s in { -1, 1 } do
		cylinder("RoofEdge", L - 2 * R, 0.8, at(s * (HALF_W - 0.4), ROOF - 0.4, 0) * ALONG, WHITE)
	end
	-- Franjas: amarilla bajo las ventanas y reflectante abajo
	for _, s in { -1, 1 } do
		detail("Stripe", Vector3.new(0.06, 0.5, L - 2 * R), at(s * (HALF_W + 0.02), win0 - 0.3, 0), YELLOW)
		detail("Skirt", Vector3.new(0.08, 0.35, L - 2 * R - 1), at(s * (HALF_W + 0.02), lower0 + 0.3, 0), rgb(50, 50, 54), Enum.Material.Rubber)
	end

	---------------------------------------------------------------------
	-- Ventanas laterales (franja oscura con montantes negros)
	---------------------------------------------------------------------
	local function inDoor(z: number, halfLen: number): boolean
		for _, d in DOORS do
			if math.abs(z - d.Z) < d.W / 2 + halfLen then
				return true
			end
		end
		return false
	end
	local pane = 4.2
	for _, s in { -1, 1 } do
		local z = -HALF_L + R + 5.3
		while z + pane / 2 < HALF_L - R - 0.3 do
			if not (s > 0 and inDoor(z, pane / 2)) then
				solid("Window", Vector3.new(0.2, win1 - win0, pane - 0.3), at(s * (HALF_W - 0.1), (win0 + win1) / 2, z), GLASS, Enum.Material.Glass, 0.3)
				detail("WindowTop", Vector3.new(0.22, 0.7, pane - 0.3), at(s * (HALF_W - 0.1), win1 - 0.5, z), rgb(18, 26, 34), Enum.Material.Glass, 0.15)
			else
				-- sobre las puertas: panel del color de la línea
				solid("DoorHeader", Vector3.new(0.3, 0.8, pane), at(s * (HALF_W - 0.15), win1 - 0.4, z), color)
			end
			detail("Mullion", Vector3.new(0.26, win1 - win0, 0.3), at(s * (HALF_W - 0.1), (win0 + win1) / 2, z + pane / 2), BLACK)
			z += pane
		end
		-- el trozo que queda hasta la esquina de atrás
		local edge = z - pane / 2
		if HALF_L - R - edge > 0.3 then
			solid("Window", Vector3.new(0.2, win1 - win0, HALF_L - R - edge), at(s * (HALF_W - 0.1), (win0 + win1) / 2, (edge + HALF_L - R) / 2), GLASS, Enum.Material.Glass, 0.3)
		end
		-- ventana del conductor (a la izquierda; a la derecha está la puerta)
		if s < 0 then
			solid("Window", Vector3.new(0.2, win1 - win0, 3.2), at(s * (HALF_W - 0.1), (win0 + win1) / 2, -HALF_L + R + 1.6), GLASS, Enum.Material.Glass, 0.3)
		end
	end

	---------------------------------------------------------------------
	-- Frontal
	---------------------------------------------------------------------
	local frontZ = -HALF_L
	local tilt = CFrame.Angles(math.rad(-6), 0, 0)
	solid("Windshield", Vector3.new(W - 2 * R + 0.4, 4.4, 0.2), at(0, 6.4, frontZ + 0.35) * tilt, GLASS, Enum.Material.Glass, 0.25)
	detail("WindshieldFrame", Vector3.new(W - 2 * R + 0.6, 0.25, 0.3), at(0, 4.2, frontZ + 0.2), BLACK)
	-- Letrero de línea luminoso (naranja)
	local destination = detail("DestinationSign", Vector3.new(W - 2.6, 1, 0.25), at(0, 9, frontZ + 0.15), rgb(10, 10, 12))
	Builder.sign(destination, "L1  CIRCULAR VALMAR", Enum.NormalId.Front, rgb(255, 170, 30), rgb(10, 10, 12))
	detail("SignGlow", Vector3.new(W - 2.8, 0.8, 0.05), at(0, 9, frontZ + 0.02), rgb(255, 160, 40), Enum.Material.Neon, 0.85)
	-- Limpiaparabrisas
	for _, s in { -1, 1 } do
		detail("Wiper", Vector3.new(2.6, 0.12, 0.1), at(s * 1.2, 4.9, frontZ + 0.15) * CFrame.Angles(0, 0, math.rad(s * 18)), BLACK)
	end
	-- Retrovisores (brazo curvo + espejo)
	for _, s in { -1, 1 } do
		detail("MirrorArm", Vector3.new(1.6, 0.18, 0.18), at(s * (HALF_W + 0.6), 8.5, frontZ + 0.9) * CFrame.Angles(0, 0, math.rad(s * -25)), BLACK)
		detail("MirrorArm", Vector3.new(0.18, 1.6, 0.18), at(s * (HALF_W + 1.3), 7.6, frontZ + 0.7), BLACK)
		detail("Mirror", Vector3.new(0.9, 1.6, 0.3), at(s * (HALF_W + 1.35), 6.6, frontZ + 0.6), BLACK)
		detail("MirrorGlass", Vector3.new(0.7, 1.4, 0.05), at(s * (HALF_W + 1.35), 6.6, frontZ + 0.78), rgb(170, 190, 200), Enum.Material.Glass, 0.2)
	end
	-- Parachoques, rejilla y matrícula
	solid("Bumper", Vector3.new(W - 0.4, 1.1, 0.7), at(0, 1.6, frontZ - 0.05), BLACK, Enum.Material.Plastic)
	for i = 0, 3 do
		detail("Grille", Vector3.new(3.2, 0.12, 0.08), at(0, 2.5 + i * 0.3, frontZ - 0.02), BLACK)
	end
	local plate = detail("Plate", Vector3.new(2.2, 0.55, 0.06), at(0, 1.6, frontZ - 0.42), WHITE)
	Builder.sign(plate, "1234 VLM", Enum.NormalId.Front, rgb(20, 20, 24), WHITE)
	local logo = detail("Logo", Vector3.new(3, 0.5, 0.06), at(0, 3.7, frontZ - 0.02), color)
	Builder.sign(logo, "VALMAR BUS", Enum.NormalId.Front, WHITE, color)
	-- Grupos ópticos: carcasa negra, dos faros redondos, tira LED e intermitente
	for _, s in { -1, 1 } do
		local x = s * (HALF_W - 1.5)
		detail("LampHousing", Vector3.new(2, 1, 0.2), at(x, 2.9, frontZ - 0.02), BLACK)
		for k = 0, 1 do
			local lamp = cylinder("Headlight", 0.2, 0.7, at(x + s * (-0.45 + k * 0.9), 2.95, frontZ - 0.1) * FORWARD, rgb(255, 250, 235), Enum.Material.Neon)
			lamp.Name = if k == 0 then "Headlight" else "HeadlightSmall"
		end
		detail("LedStrip", Vector3.new(1.8, 0.12, 0.06), at(x, 3.45, frontZ - 0.12), rgb(230, 245, 255), Enum.Material.Neon)
		detail("Indicator", Vector3.new(0.5, 0.35, 0.08), at(s * (HALF_W - 0.25), 2.9, frontZ - 0.05), rgb(255, 150, 20), Enum.Material.Neon)
	end

	---------------------------------------------------------------------
	-- Trasera
	---------------------------------------------------------------------
	local backZ = HALF_L
	solid("RearWindow", Vector3.new(W - 2 * R + 0.2, 2.6, 0.2), at(0, 7, backZ - 0.2), GLASS, Enum.Material.Glass, 0.3)
	solid("RearUpper", Vector3.new(W - 2 * R + 0.2, ROOF - 8.3, 0.3), at(0, (8.3 + ROOF) / 2, backZ - 0.15), color)
	local rearSign = detail("RearSign", Vector3.new(1.6, 0.8, 0.2), at(0, 8.9, backZ - 0.15), rgb(10, 10, 12))
	Builder.sign(rearSign, "L1", Enum.NormalId.Back, rgb(255, 170, 30), rgb(10, 10, 12))
	for i = 0, 5 do
		detail("EngineGrille", Vector3.new(W - 3.4, 0.14, 0.08), at(0, 2.2 + i * 0.35, backZ + 0.02), BLACK)
	end
	solid("RearBumper", Vector3.new(W - 0.4, 1, 0.6), at(0, 1.55, backZ + 0.05), BLACK, Enum.Material.Plastic)
	local rearPlate = detail("Plate", Vector3.new(2.2, 0.55, 0.06), at(0, 1.55, backZ + 0.38), WHITE)
	Builder.sign(rearPlate, "1234 VLM", Enum.NormalId.Back, rgb(20, 20, 24), WHITE)
	for _, s in { -1, 1 } do
		detail("Taillight", Vector3.new(0.9, 2.4, 0.1), at(s * (HALF_W - 0.9), 3.4, backZ + 0.04), rgb(200, 20, 30), Enum.Material.Neon)
		detail("Indicator", Vector3.new(0.9, 0.5, 0.1), at(s * (HALF_W - 0.9), 5, backZ + 0.04), rgb(255, 150, 20), Enum.Material.Neon)
		detail("Reverse", Vector3.new(0.9, 0.4, 0.1), at(s * (HALF_W - 0.9), 2, backZ + 0.04), WHITE, Enum.Material.Neon)
	end

	---------------------------------------------------------------------
	-- Puertas dobles (a la derecha): marco, dos hojas de cristal, escalón y luz
	---------------------------------------------------------------------
	for i, d in ipairs(DOORS) do
		local x = HALF_W - 0.1
		local h = win1 - FLOOR
		detail("DoorFrame", Vector3.new(0.3, 0.3, d.W + 0.4), at(x, win1 + 0.05, d.Z), BLACK)
		for _, sz in { -1, 1 } do
			detail("DoorFrame", Vector3.new(0.3, h, 0.25), at(x, FLOOR + h / 2, d.Z + sz * (d.W / 2 + 0.1)), BLACK)
			local leaf = solid("BusDoor", Vector3.new(0.2, h - 0.3, d.W / 2 - 0.1), at(x + 0.05, FLOOR + h / 2, d.Z + sz * d.W / 4), GLASS, Enum.Material.Glass, 0.35)
			leaf:SetAttribute("DoorIndex", i)
			leaf:SetAttribute("Leaf", if sz < 0 then 1 else 2)
		end
		detail("DoorSeal", Vector3.new(0.25, h - 0.3, 0.12), at(x + 0.08, FLOOR + h / 2, d.Z), BLACK, Enum.Material.Rubber)
		detail("DoorStep", Vector3.new(1.2, 0.3, d.W), at(HALF_W - 0.7, FLOOR - 0.35, d.Z), GREY, Enum.Material.DiamondPlate)
		detail("DoorStepEdge", Vector3.new(0.15, 0.32, d.W), at(HALF_W - 0.1, FLOOR - 0.35, d.Z), YELLOW)
		detail("DoorLight", Vector3.new(0.2, 0.2, 0.8), at(HALF_W + 0.05, win1 + 0.4, d.Z), rgb(255, 170, 40), Enum.Material.Neon)
	end
	-- Letrero lateral junto a la puerta delantera
	local sideSign = detail("SideSign", Vector3.new(0.2, 0.8, 3.2), at(HALF_W - 0.08, win1 - 0.5, -9.2), rgb(10, 10, 12))
	Builder.sign(sideSign, "L1 CIRCULAR", Enum.NormalId.Right, rgb(255, 170, 30), rgb(10, 10, 12))
	-- Anuncio en el lado izquierdo
	local ad = detail("Advert", Vector3.new(0.08, 2.4, 11), at(-HALF_W - 0.02, 2.75, 5), rgb(20, 110, 190))
	Builder.sign(ad, "🏖️ PLAYA DORADA · ¡a 20 minutos en la L1!", Enum.NormalId.Left, WHITE, rgb(20, 110, 190))
	-- Luces de gálibo naranjas y tapa del depósito
	for _, s in { -1, 1 } do
		for z = -12, 12, 8 do
			detail("SideMarker", Vector3.new(0.1, 0.25, 0.5), at(s * (HALF_W + 0.05), lower0 + 0.75, z), rgb(255, 140, 20), Enum.Material.Neon)
		end
	end
	detail("FuelCap", Vector3.new(0.1, 0.8, 0.8), at(-HALF_W - 0.03, 2.4, 12.5), rgb(80, 80, 86), Enum.Material.Metal)

	---------------------------------------------------------------------
	-- Ruedas: neumático, llanta, tuercas y paso de rueda
	---------------------------------------------------------------------
	local rr = 1.6
	for _, z in { -10.5, 10 } do
		for _, s in { -1, 1 } do
			-- hueco oscuro de la rueda (disco) y la rueda un poco por fuera
			cylinder("WheelWell", 0.04, 4, at(s * (HALF_W + 0.01), rr + 0.15, z), rgb(14, 14, 16))
			local x = s * (HALF_W - 0.49)
			wheel(m, cf * CFrame.new(x, rr, z), rr, 1.1)
			cylinder("Rim", 1.14, 1.9, at(x, rr, z), rgb(200, 204, 210), Enum.Material.Metal)
			cylinder("Hub", 1.2, 0.6, at(x, rr, z), rgb(90, 92, 98), Enum.Material.Metal)
			for k = 0, 4 do
				local a = k * math.pi * 2 / 5
				detail("Nut", Vector3.new(1.22, 0.15, 0.15), at(x, rr + math.cos(a) * 0.5, z + math.sin(a) * 0.5), rgb(60, 60, 64), Enum.Material.Metal)
			end
			detail("MudFlap", Vector3.new(0.9, 0.9, 0.1), at(x, 0.7, z + 2.1), BLACK, Enum.Material.Rubber)
		end
	end

	---------------------------------------------------------------------
	-- Techo: aire acondicionado, trampillas y antena
	---------------------------------------------------------------------
	solid("RoofUnit", Vector3.new(5.4, 0.9, 7), at(0, ROOF + 0.45, 3), rgb(214, 216, 220), Enum.Material.Metal)
	for i = 0, 5 do
		detail("Vent", Vector3.new(4.6, 0.06, 0.3), at(0, ROOF + 0.93, 0.3 + i * 1), rgb(150, 152, 158))
	end
	for _, z in { -8, 11 } do
		detail("Hatch", Vector3.new(2.4, 0.25, 2.4), at(0, ROOF + 0.12, z), rgb(200, 202, 206), Enum.Material.Metal)
	end
	detail("Antenna", Vector3.new(0.1, 1.4, 0.1), at(-1.5, ROOF + 0.7, -12), BLACK)

	---------------------------------------------------------------------
	-- Interior
	---------------------------------------------------------------------
	solid("Floor", Vector3.new(W - 0.6, 0.3, L - 1), at(0, FLOOR - 0.15, 0), rgb(70, 72, 78), Enum.Material.Rubber)
	detail("Ceiling", Vector3.new(W - 0.8, 0.2, L - 1.2), at(0, ROOF - 0.5, 0), rgb(235, 235, 232))
	for _, s in { -1, 1 } do
		detail("CeilingLight", Vector3.new(0.5, 0.1, L - 6), at(s * 2.6, ROOF - 0.62, 1), rgb(245, 250, 255), Enum.Material.Neon)
		cylinder("GrabRail", L - 8, 0.2, at(s * 2.2, 7.9, 1) * ALONG, YELLOW, Enum.Material.Metal)
	end
	-- Barras verticales amarillas con pulsador rojo de parada
	for _, p in { { 1, -11 }, { -1, -6 }, { 1, 1.8 }, { 1, 7.2 }, { -1, 3 }, { -1, 10 }, { 1, 13 } } do
		cylinder("Pole", ROOF - FLOOR - 0.6, 0.25, at(p[1] * 1.3, (FLOOR + ROOF - 0.6) / 2, p[2]) * UP, YELLOW, Enum.Material.Metal)
		detail("StopButton", Vector3.new(0.35, 0.5, 0.35), at(p[1] * 1.3, 5.2, p[2]), rgb(210, 30, 40), Enum.Material.Neon)
	end
	-- Asientos (los de pasajeros son Seat de verdad; delante, prioritarios en rojo)
	for z = -8.5, 14, 3.1 do
		for _, x in { -2.55, 2.55 } do
			if not (x > 0 and z > 1.6 and z < 7.4) then
				local priority = z < -2
				local seatColor = if priority then rgb(190, 40, 50) else SEAT
				Builder.part({
					ClassName = "Seat",
					Name = "PassengerSeat",
					Size = Vector3.new(2.4, 0.45, 1.9),
					CFrame = at(x, FLOOR + 1.3, z), -- mirando hacia delante
					Color = seatColor,
					Material = Enum.Material.Fabric,
					CanTouch = false,
					Parent = m,
				})
				detail("SeatBack", Vector3.new(2.4, 2.2, 0.35), at(x, FLOOR + 2.45, z + 1.05) * CFrame.Angles(math.rad(8), 0, 0), seatColor, Enum.Material.Fabric)
				detail("SeatFrame", Vector3.new(2.2, 1.1, 0.25), at(x, FLOOR + 0.55, z), GREY, Enum.Material.Metal)
				detail("Handle", Vector3.new(0.9, 0.15, 0.15), at(x + (if x > 0 then -0.6 else 0.6), FLOOR + 3.6, z + 1.25), rgb(200, 200, 205), Enum.Material.Metal)
			end
		end
	end
	-- Zona de silla de ruedas (frente a la puerta central) con su señal
	detail("WheelchairArea", Vector3.new(2.8, 0.02, 4.2), at(-2.6, FLOOR + 0.02, 4.5), rgb(40, 110, 200))
	local wc = detail("WheelchairSign", Vector3.new(0.05, 1, 1), at(-HALF_W + 0.35, 5.6, 4.5), rgb(40, 110, 200))
	Builder.sign(wc, "♿", Enum.NormalId.Right, WHITE, rgb(40, 110, 200))
	-- Validadora de billetes junto a la puerta delantera
	detail("ValidatorPost", Vector3.new(0.25, 3.2, 0.25), at(2.9, FLOOR + 1.6, -10.4), rgb(200, 200, 205), Enum.Material.Metal)
	detail("Validator", Vector3.new(0.9, 1.2, 0.7), at(2.9, FLOOR + 3.5, -10.4), YELLOW)
	detail("ValidatorScreen", Vector3.new(0.6, 0.4, 0.05), at(2.9, FLOOR + 3.7, -10.77), rgb(80, 220, 120), Enum.Material.Neon)
	-- Pantalla de próxima parada colgada del techo
	local screen = detail("InfoScreen", Vector3.new(3, 0.8, 0.15), at(0, ROOF - 1.1, -9), BLACK)
	Builder.sign(screen, "PRÓXIMA PARADA ▸", Enum.NormalId.Back, rgb(255, 170, 30), BLACK)
	-- Puesto del conductor: mampara, salpicadero con pantallas, volante y asiento
	detail("DriverPartition", Vector3.new(0.12, 3.4, 2.4), at(-1, FLOOR + 1.7, -12.4), rgb(190, 220, 235), Enum.Material.Glass, 0.5)
	solid("Dashboard", Vector3.new(W - 1.2, 1.6, 1.4), at(0, FLOOR + 1.4, frontZ + 1.2), BLACK, Enum.Material.Plastic)
	for k, x in { -3, -2 } do
		detail("DashScreen", Vector3.new(0.8, 0.5, 0.05), at(x, FLOOR + 2.25, frontZ + 1.6) * CFrame.Angles(math.rad(-30), 0, 0), if k == 1 then rgb(60, 180, 255) else rgb(80, 220, 120), Enum.Material.Neon)
	end
	cylinder("SteeringWheel", 0.2, 1.8, at(-2.4, FLOOR + 2.6, frontZ + 2.3) * CFrame.Angles(math.rad(-55), 0, 0) * FORWARD, BLACK)
	cylinder("SteeringColumn", 1.2, 0.25, at(-2.4, FLOOR + 2.1, frontZ + 1.9) * CFrame.Angles(math.rad(-55), 0, 0) * FORWARD, rgb(60, 60, 64))
	detail("DriverSeatBack", Vector3.new(1.8, 2.3, 0.4), at(-2.4, FLOOR + 2.3, -12.1), rgb(30, 30, 34), Enum.Material.Fabric)
	detail("DriverSeatBase", Vector3.new(1.8, 0.5, 1.8), at(-2.4, FLOOR + 1.1, -13), rgb(30, 30, 34), Enum.Material.Fabric)
end

-- Coche patrulla de la Policía (oficio de policía): el coche detallado en blanco con franja azul,
-- rótulo POLICÍA, puente de luces (SirenBlue / SirenRed: parpadean con la sirena, cliente) y rejilla.
local function patrulla(m: Model, cf: CFrame, _color: Color3)
	coche(m, cf, rgb(242, 244, 248))
	local BLUE = rgb(30, 70, 170)
	for _, sx in { -1, 1 } do
		local stripe = bit(m, "PoliceStripe", Vector3.new(0.06, 0.7, 12.4), cf * CFrame.new(sx * 3.13, 2.3, 0.2), BLUE)
		Builder.sign(stripe, "POLICÍA", if sx > 0 then Enum.NormalId.Right else Enum.NormalId.Left, rgb(250, 250, 250))
		bit(m, "PoliceCheck", Vector3.new(0.06, 0.3, 12.4), cf * CFrame.new(sx * 3.13, 2.85, 0.2), rgb(250, 200, 30))
	end
	local hood = bit(m, "HoodText", Vector3.new(3.4, 0.05, 1), cf * CFrame.new(0, 3.43, -5.2), rgb(242, 244, 248))
	Builder.sign(hood, "POLICÍA", Enum.NormalId.Top, BLUE)
	-- Puente de luces sobre el techo
	bit(m, "LightBarBase", Vector3.new(3.6, 0.25, 0.9), cf * CFrame.new(0, 5.55, 0.6), rgb(30, 30, 34), Enum.Material.Metal)
	for k, x in { -1.3, -0.45, 0.45, 1.3 } do
		local blue = k % 2 == 1
		local lamp = bit(m, if blue then "SirenBlue" else "SirenRed", Vector3.new(0.8, 0.4, 0.8), cf * CFrame.new(x, 5.85, 0.6), if blue then rgb(40, 60, 140) else rgb(140, 30, 30), Enum.Material.SmoothPlastic)
		lamp:SetAttribute("On", if blue then Color3.fromRGB(60, 120, 255) else Color3.fromRGB(255, 40, 40))
	end
	-- Rejilla delantera (defensa) y antena
	bit(m, "PushBar", Vector3.new(3.2, 1.2, 0.3), cf * CFrame.new(0, 2.1, -7.1), rgb(30, 30, 34), Enum.Material.Metal)
	bit(m, "Antenna", Vector3.new(0.08, 2, 0.08), cf * CFrame.new(1.8, 6.2, 4.4), rgb(30, 30, 34))
	m:SetAttribute("Siren", false)
	m:AddTag("PoliceCar")
end

-- Camión de la basura (oficio de basurero): cabina, caja compactadora, tolva trasera con
-- elevador de contenedores, estribos para los operarios, rotativos naranjas y franjas reflectantes.
local function camion(m: Model, cf: CFrame, color: Color3)
	local W = 8
	local HW = W / 2
	local DARK = rgb(34, 35, 38)
	local GLASS = rgb(30, 44, 56)
	local ORANGE = rgb(255, 140, 20)
	local STEEL = rgb(180, 184, 190)
	local function at(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x, y, z)
	end
	-- Chasis y ruedas (tres ejes)
	box(m, "Frame", Vector3.new(W - 1.4, 1, 25), at(0, 1.9, 0.5), DARK, Enum.Material.Metal)
	for _, z in { -9.5, 5.5, 9 } do
		for _, sx in { -1, 1 } do
			local c = at(sx * (HW - 0.7), 1.7, z)
			wheel(m, c, 1.7, 1.2)
			cyl(m, "Rim", 1.26, 1.9, c, STEEL, Enum.Material.Metal)
			cyl(m, "Hub", 1.3, 0.6, c, DARK, Enum.Material.Metal)
		end
	end
	-- Cabina
	local cabZ0, cabZ1 = -13, -6.2
	local cabMid = (cabZ0 + cabZ1) / 2
	box(m, "Body", Vector3.new(W, 5.6, cabZ1 - cabZ0), at(0, 5.2, cabMid), color, Enum.Material.SmoothPlastic)
	box(m, "CabRoof", Vector3.new(W - 0.2, 0.4, cabZ1 - cabZ0 - 0.2), at(0, 8.2, cabMid), color, Enum.Material.SmoothPlastic)
	bit(m, "Windshield", Vector3.new(W - 1, 2.4, 0.15), at(0, 6.6, cabZ0 - 0.02), GLASS, Enum.Material.Glass, 0.2)
	for _, sx in { -1, 1 } do
		bit(m, "SideWindow", Vector3.new(0.12, 2.2, 3), at(sx * (HW + 0.02), 6.6, cabMid - 0.6), GLASS, Enum.Material.Glass, 0.2)
		bit(m, "DoorLine", Vector3.new(0.05, 4.8, 0.08), at(sx * (HW + 0.03), 5, cabZ1 - 0.6), DARK)
		bit(m, "Handle", Vector3.new(0.12, 0.2, 0.6), at(sx * (HW + 0.08), 5.4, cabZ1 - 1.2), DARK)
		bit(m, "Step", Vector3.new(1.2, 0.2, 1.6), at(sx * (HW - 0.2), 2.6, cabMid), DARK, Enum.Material.DiamondPlate)
		-- Retrovisores grandes
		bit(m, "MirrorArm", Vector3.new(1.2, 0.12, 0.12), at(sx * (HW + 0.6), 7, cabZ0 + 0.3), DARK)
		bit(m, "Mirror", Vector3.new(0.2, 1.6, 0.8), at(sx * (HW + 1.2), 6.6, cabZ0 + 0.3), DARK)
		-- Faros y intermitentes
		local head = bit(m, "Headlight", Vector3.new(1.4, 0.6, 0.2), at(sx * (HW - 1.2), 3.4, cabZ0 - 0.05), rgb(255, 250, 230), Enum.Material.Neon)
		head.Name = if sx < 0 then "Headlight" else "HeadlightRight"
		bit(m, "IndicatorFront", Vector3.new(0.5, 0.4, 0.15), at(sx * (HW - 0.3), 3.4, cabZ0 - 0.05), rgb(255, 150, 20), Enum.Material.Neon)
	end
	bit(m, "Grille", Vector3.new(4, 1.4, 0.15), at(0, 3.6, cabZ0 - 0.05), DARK)
	for k = 0, 3 do
		bit(m, "GrilleBar", Vector3.new(3.8, 0.1, 0.05), at(0, 3.1 + k * 0.33, cabZ0 - 0.14), STEEL, Enum.Material.Metal)
	end
	box(m, "BumperFront", Vector3.new(W, 0.8, 0.5), at(0, 2.3, cabZ0 - 0.3), DARK, Enum.Material.Metal)
	-- Rotativos naranjas en el techo de la cabina
	for _, sx in { -1, 1 } do
		cyl(m, "Beacon", 0.6, 0.6, at(sx * 2.4, 8.7, cabMid + 1) * CFrame.Angles(0, 0, math.rad(90)), ORANGE, Enum.Material.Neon)
	end
	bit(m, "LightBar", Vector3.new(5.6, 0.25, 0.4), at(0, 8.5, cabMid + 1), DARK)
	-- Interior: volante y asiento del conductor (a la izquierda)
	cyl(m, "SteeringWheel", 0.2, 1.6, at(-1.8, 5.4, cabZ0 + 1.6) * CFrame.Angles(math.rad(-50), 0, 0) * CFrame.Angles(0, math.rad(90), 0), DARK)
	bit(m, "DriverSeatBack", Vector3.new(1.8, 2.2, 0.4), at(-1.8, 5, cabMid + 1.8), DARK, Enum.Material.Fabric)

	-- Caja compactadora
	local bodyZ0, bodyZ1 = -5.8, 9.6
	local bodyMid = (bodyZ0 + bodyZ1) / 2
	box(m, "Container", Vector3.new(W - 0.2, 7.4, bodyZ1 - bodyZ0), at(0, 6.2, bodyMid), color, Enum.Material.Metal)
	box(m, "ContainerTop", Vector3.new(W - 0.6, 0.5, bodyZ1 - bodyZ0 - 0.4), at(0, 10.1, bodyMid), color, Enum.Material.Metal)
	for k = 0, 5 do
		-- Refuerzos verticales
		local z = bodyZ0 + 1 + k * (bodyZ1 - bodyZ0 - 2) / 5
		for _, sx in { -1, 1 } do
			bit(m, "Rib", Vector3.new(0.2, 7.2, 0.4), at(sx * (HW - 0.05), 6.2, z), color:Lerp(rgb(0, 0, 0), 0.15), Enum.Material.Metal)
		end
	end
	for _, sx in { -1, 1 } do
		-- Franjas reflectantes y rótulo
		bit(m, "Stripe", Vector3.new(0.08, 0.5, bodyZ1 - bodyZ0 - 0.4), at(sx * (HW + 0.02), 4, bodyMid), ORANGE, Enum.Material.Neon)
		bit(m, "Stripe", Vector3.new(0.08, 0.3, bodyZ1 - bodyZ0 - 0.4), at(sx * (HW + 0.02), 3.3, bodyMid), rgb(240, 240, 240))
		local sign = bit(m, "Logo", Vector3.new(0.06, 1.6, 9), at(sx * (HW + 0.05), 7.2, bodyMid), rgb(250, 250, 250))
		Builder.sign(sign, "♻ LIMPIEZA VALMAR", if sx > 0 then Enum.NormalId.Right else Enum.NormalId.Left, rgb(40, 110, 60))
	end
	-- Tolva trasera con el elevador de contenedores
	local hz = bodyZ1 + 1.6
	box(m, "Hopper", Vector3.new(W - 0.4, 6, 3), at(0, 5.8, hz), rgb(70, 72, 78), Enum.Material.Metal)
	Builder.part({ ClassName = "WedgePart", Name = "HopperTop", Size = Vector3.new(W - 0.4, 2.4, 3), CFrame = at(0, 10, hz) * CFrame.Angles(0, math.pi, 0), Color = rgb(70, 72, 78), Material = Enum.Material.Metal, Parent = m })
	bit(m, "HopperMouth", Vector3.new(W - 1.6, 2.4, 0.1), at(0, 4.4, hz + 1.52), rgb(20, 20, 22))
	bit(m, "Lifter", Vector3.new(W - 2, 0.4, 0.8), at(0, 2.6, hz + 1.8), STEEL, Enum.Material.DiamondPlate)
	for _, sx in { -1, 1 } do
		bit(m, "LifterArm", Vector3.new(0.3, 3, 0.3), at(sx * (HW - 1.4), 3.8, hz + 1.7), STEEL, Enum.Material.Metal)
		-- Estribos y asideros de los operarios
		bit(m, "RearStep", Vector3.new(1.4, 0.2, 1), at(sx * (HW - 0.8), 1.9, hz + 2), DARK, Enum.Material.DiamondPlate)
		bit(m, "GrabBar", Vector3.new(0.15, 2.4, 0.15), at(sx * (HW - 0.3), 5, hz + 1.6), rgb(250, 200, 30), Enum.Material.Metal)
		bit(m, "Taillight", Vector3.new(0.9, 0.5, 0.15), at(sx * (HW - 0.6), 3, hz + 1.55), rgb(200, 20, 30), Enum.Material.Neon)
		bit(m, "IndicatorRear", Vector3.new(0.5, 0.4, 0.15), at(sx * (HW - 1.5), 3, hz + 1.55), rgb(255, 150, 20), Enum.Material.Neon)
		cyl(m, "RearBeacon", 0.5, 0.5, at(sx * (HW - 0.6), 9.8, hz + 1) * CFrame.Angles(0, 0, math.rad(90)), ORANGE, Enum.Material.Neon)
	end
	-- Rayas de peligro en la tolva
	for k = -3, 3 do
		bit(m, "Hazard", Vector3.new(0.5, 1.6, 0.06), at(k * 1, 7.8, hz + 1.53) * CFrame.Angles(0, 0, math.rad(35)), if k % 2 == 0 then ORANGE else DARK)
	end
end

local BUILDERS = { Monopatin = monopatin, Patinete = patinete, Bici = bici, Moto = moto, Coche = coche, Autobus = autobus, Camion = camion, Patrulla = patrulla }
local COLORS = {
	Monopatin = { rgb(220, 70, 60), rgb(40, 140, 220), rgb(250, 200, 40), rgb(60, 170, 90) },
	Bici = { rgb(30, 110, 200), rgb(210, 50, 60), rgb(40, 160, 90), rgb(240, 240, 240) },
	Moto = { rgb(200, 30, 40), rgb(30, 30, 34), rgb(240, 240, 240), rgb(40, 90, 180) },
	Patinete = { rgb(30, 30, 34), rgb(240, 240, 240), rgb(220, 70, 60), rgb(40, 140, 220) },
	Autobus = { rgb(200, 40, 45) },
	Camion = { rgb(245, 245, 242) },
}

-- Crea el modelo del vehículo (anclado). kind: "Monopatin" | "Bici" | "Moto" | "Coche"
function Rides.build(kind: string, parent: Instance?, cf: CFrame, color: Color3?): Model
	local m = Instance.new("Model")
	m.Name = kind
	local paint = color or (if COLORS[kind] then Palette.pick(COLORS[kind]) else Palette.pick(Palette.CarColors))
	BUILDERS[kind](m, cf, paint)
	m.Parent = parent
	return m
end

-- Convierte un modelo en un vehículo que se conduce: añade la base invisible ("Chassis", la
-- pieza principal) y el asiento del conductor ("DriverSeat"), y suelda todo a la base.
-- groundCf = centro del vehículo a ras de suelo, mirando hacia el morro. Queda aparcado (anclado).
function Rides.prepare(model: Model, kind: string, groundCf: CFrame): (BasePart, VehicleSeat)
	local spec = Rides.Spec[kind]
	local chassis = Instance.new("Part")
	chassis.Name = "Chassis"
	chassis.Size = spec.Size
	chassis.CFrame = groundCf * CFrame.new(0, spec.Size.Y / 2, 0)
	chassis.Transparency = 1
	chassis.CanCollide = false
	chassis.CanTouch = false
	chassis.CanQuery = false
	chassis.Anchored = true
	chassis.Parent = model
	local seat = Instance.new("VehicleSeat")
	seat.Name = "DriverSeat"
	seat.Size = Vector3.new(1.6, 0.2, 1.6)
	seat.CFrame = groundCf * spec.Seat * CFrame.new(0, -0.1, 0)
	seat.Transparency = 1
	seat.CanCollide = false
	seat.CanTouch = false -- nadie se sube al tocarlo: se sube con el cartel
	seat.CanQuery = false
	seat.MaxSpeed = 0 -- lo mueve Driving.luau, no las ruedas de Roblox
	seat.HeadsUpDisplay = false
	seat.Parent = model
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part ~= chassis then
			part:SetAttribute("Collide", part.CanCollide)
			part.Anchored = false
			part.Massless = true
			part.CanTouch = false
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = chassis
			weld.Part1 = part
			weld.Parent = part
		end
	end
	model.PrimaryPart = chassis
	model:SetAttribute("Drivable", true)
	model:SetAttribute("Kind", kind)
	return chassis, seat
end

-- Estación pública de bicis y monopatines (tag RentalStation). La usa VehicleService.
function Rides.station(parent: Instance, cf: CFrame)
	local m = Builder.model("BiciPublica", parent)
	Builder.part({ Name = "Base", Size = Vector3.new(9, 0.2, 4), CFrame = cf * CFrame.new(0, 0.1, 0), Color = rgb(60, 64, 70), Material = Enum.Material.Metal, Parent = m })
	local post = Builder.part({ Name = "Totem", Size = Vector3.new(1.4, 5, 0.8), CFrame = cf * CFrame.new(-4, 2.5, 0), Color = rgb(30, 150, 80), Parent = m })
	Builder.sign(post, "BICI\nPÚBLICA", Enum.NormalId.Front)
	Builder.sign(post, "BICI\nPÚBLICA", Enum.NormalId.Back)
	for i, x in { -1.5, 1.5 } do
		Builder.decor({ Name = "Rack", Size = Vector3.new(0.2, 1.6, 2.6), CFrame = cf * CFrame.new(x - 0.7, 0.9, 0), Color = METAL, Material = Enum.Material.Metal, Parent = m })
		local display = Rides.build("Bici", m, cf * CFrame.new(x, 0.2, 0) * CFrame.Angles(0, math.pi / 2, 0), rgb(30, 150, 80))
		display.Name = "DisplayBici" .. i
		for _, p in display:GetChildren() do
			if p:IsA("BasePart") then
				p.CanCollide = false
				p.CanQuery = false
			end
		end
	end
	local board = Rides.build("Monopatin", m, cf * CFrame.new(3.6, 0.2, 0.8), rgb(30, 150, 80))
	board.Name = "DisplayMonopatin"
	Builder.part({
		Name = "RentalPoint",
		Size = Vector3.new(2, 2, 2),
		CFrame = cf * CFrame.new(0, 2.5, 0),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		Tags = { "RentalStation" },
		Parent = m,
	})
	return m
end

return Rides
