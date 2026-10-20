-- Wetness: cómo afecta la lluvia y la nieve a las cosas (cuentas puras, se prueban fuera de Roblox:
-- scripts/test-weather.luau).
--   * Superficies: mojadas se ven más oscuras y brillan (reflejos en el asfalto, en los coches…);
--     con nieve, lo que está al aire se cubre de blanco.
--   * Vehículos: con el suelo mojado o nevado agarran menos: aceleran y frenan peor, giran menos y
--     derrapan en las curvas. Motos, bicis y patinetes, más.
-- El servidor publica cuánto está mojado todo (workspace "Wet", 0..1) y cuánta nieve hay ("Snow").

local Wetness = {}

-- Materiales que brillan mucho cuando se mojan (el agua forma una capa lisa encima)
-- (por nombre del material: así funciona igual en Roblox y en las pruebas)
local SHINY: { [string]: number } = {
	Asphalt = 1,
	Concrete = 0.8,
	Pavement = 0.8,
	Cobblestone = 0.7,
	Slate = 0.8,
	Granite = 0.8,
	Marble = 0.9,
	Limestone = 0.6,
	Brick = 0.4,
	SmoothPlastic = 0.9,
	Plastic = 0.8,
	Metal = 0.9,
	DiamondPlate = 0.8,
	CorrodedMetal = 0.5,
	Wood = 0.4,
	WoodPlanks = 0.5,
	Rock = 0.5,
	Pebble = 0.5,
	Ground = 0.25,
	Mud = 0.4,
	Sand = 0.15,
	Grass = 0.1,
	LeafyGrass = 0.1,
	Fabric = 0.05,
	Cardboard = 0.1,
	Plaster = 0.25,
}

-- Lo que no se toca: ya brilla, es transparente o es agua
local SKIP: { [string]: boolean } = {
	Glass = true,
	Neon = true,
	ForceField = true,
	Water = true,
	Ice = true,
	Snow = true,
}

function Wetness.canGetWet(material: Enum.Material, transparency: number): boolean
	return not SKIP[material.Name] and transparency < 0.3
end

-- Qué cambia en una superficie al aire libre. floor = es suelo o la parte de arriba de algo (ahí se
-- queda el agua y brilla más). Devuelve: cuánto oscurecer (0..1), reflejo y cuánto blanquear por nieve.
function Wetness.surface(material: Enum.Material, wet: number, snow: number, floor: boolean): (number, number, number)
	local shiny = SHINY[material.Name] or 0.3
	-- (el suelo empapado oscurece más que una pared: v108, en el móvil no se notaba la calle mojada)
	local darken = (if floor then 0.3 else 0.2) * wet * (1 - 0.5 * snow)
	-- (el suelo mojado hace de espejo oscuro: con Future refleja el cielo, las fachadas y las farolas)
	-- (v109: 0,25 en el suelo; con 0,38 el asfalto reflejaba el cielo de FOTO, azul, bajo un cielo gris de
	-- lluvia y parecía falso. El brillo mojado de cerca lo da la rugosidad mojada, Textures.roughnessFor)
	local reflect = wet * shiny * (if floor then 0.25 else 0.06)
	-- La nieve se queda encima de las cosas (no en las paredes); en la calzada casi no cuaja
	local whiten = 0
	if floor and material.Name ~= "Asphalt" then
		whiten = snow * 0.7
	elseif floor then
		whiten = snow * 0.25
	end
	return darken, reflect, whiten
end

-- Nivel en pasos (para no repintar miles de piezas por un cambio mínimo)
function Wetness.level(value: number): number
	return math.floor(math.clamp(value, 0, 1) * 5 + 0.5) / 5
end

-- Agarre del suelo para un vehículo (1 = seco; menos = resbala)
local LIGHT = { Bici = true, Moto = true, Monopatin = true, Patinete = true }
function Wetness.grip(kind: string, wet: number, snow: number): number
	local grip = 1 - 0.3 * math.clamp(wet, 0, 1) - 0.55 * math.clamp(snow, 0, 1)
	if LIGHT[kind] then
		-- Dos ruedas (o ruedas pequeñas): resbalan más
		grip = 1 - (1 - grip) * 1.3
	end
	return math.clamp(grip, 0.2, 1)
end

export type Drive = {
	Accel: number, -- multiplica la aceleración
	Brake: number, -- multiplica la frenada
	Turn: number, -- multiplica el giro
	MaxSpeed: number, -- multiplica la velocidad máxima
	Traction: number, -- lo rápido que el coche va hacia donde apunta (menos = derrapa)
}

-- Cómo se conduce con ese agarre
function Wetness.drive(grip: number): Drive
	return {
		Accel = 0.55 + 0.45 * grip,
		Brake = grip,
		Turn = 0.55 + 0.45 * grip,
		MaxSpeed = 0.75 + 0.25 * grip,
		Traction = 1.5 + 14.5 * grip ^ 2,
	}
end

-- Hacia dónde va de verdad el vehículo: se acerca a donde apunta según la tracción (con poca, derrapa)
function Wetness.slide(travelYaw: number, yaw: number, traction: number, dt: number): number
	local diff = (yaw - travelYaw + math.pi) % (2 * math.pi) - math.pi
	return travelYaw + diff * (1 - math.exp(-traction * dt))
end

-- Lo mojada que está una persona: se moja rápido bajo la lluvia y se seca despacio a cubierto
function Wetness.person(current: number, raining: number, sheltered: boolean, dt: number): number
	if raining > 0 and not sheltered then
		return math.min(1, current + dt * raining / 20)
	end
	return math.max(0, current - dt / (if sheltered then 45 else 90))
end

-- Cómo se ve una persona mojada (level 0..1): cuánto se oscurecen la ropa, el pelo y la piel, y el
-- brillo de agua encima (Reflectance de las piezas: con Future refleja el cielo, como tela empapada).
-- Sutil: empapado del todo, un 30 % más oscuro y un brillo pequeño.
function Wetness.look(level: number): (number, number)
	local l = math.clamp(level, 0, 1)
	return 0.3 * l, 0.1 * l
end

-- Goteo (gotas por segundo que caen de la cabeza y la ropa): solo cuando ya está bastante mojado
function Wetness.drips(level: number): number
	return if level > 0.2 then 14 * math.clamp(level, 0, 1) else 0
end

-- Coches de la ciudad (tráfico): van más despacio con lluvia y más aún con nieve
function Wetness.trafficSpeed(wet: number, snow: number): number
	return math.clamp(1 - 0.2 * wet - 0.35 * snow, 0.5, 1)
end

---------------------------------------------------------------------
-- v126 (docs/clima/estaciones.md): mojarse y secarse en HORAS DE JUEGO
-- (WeatherService lo publica: workspace "Wet" = lo mojado del suelo y las cosas, "Puddles" = el agua
-- de los charcos, que se llenan más despacio y tardan más en secarse)
---------------------------------------------------------------------

-- Horas de juego que tarda en secarse del todo el suelo empapado con sol, por estación
-- (un día de juego dura Config.DayLengthMinutes: 1 hora de juego ≈ 50 s reales)
Wetness.DryHours = { Primavera = 2.5, Verano = 1.4, Otono = 3, Invierno = 4.5 }
Wetness.WetHours = 0.35 -- horas de lluvia fuerte para que todo esté empapado
Wetness.PuddleHours = 1.6 -- horas de lluvia fuerte para que los charcos crezcan del todo
Wetness.PuddleDry = 1.5 -- los charcos tardan esto más que el suelo en secarse

-- Horas en secarse con este tiempo y a esta hora (nublado o de noche se seca más despacio)
function Wetness.dryHours(season: string?, weather: string?, clock: number?): number
	local hours = Wetness.DryHours[season or ""] or 2.5
	if weather == "Nublado" then
		hours *= 1.3
	elseif weather == "Niebla" then
		hours *= 1.8
	elseif weather == "Intervalos" then
		hours *= 1.1
	end
	local h = clock or 12
	if h < 7.5 or h >= 21 then
		hours *= 1.6 -- (de noche, sin sol)
	end
	return hours
end

-- Un paso: lo mojado y los charcos tras `hours` horas de juego con esta lluvia (0..1,7) y este secado
function Wetness.water(wet: number, puddles: number, rain: number, hours: number, dry: number): (number, number)
	local h = math.max(0, hours)
	if rain > 0.02 then
		local r = math.min(rain, 1.7)
		wet += h * r / Wetness.WetHours
		puddles += h * r / Wetness.PuddleHours
	else
		wet -= h / math.max(dry, 0.1)
		puddles -= h / math.max(dry * Wetness.PuddleDry, 0.1)
	end
	return math.clamp(wet, 0, 1), math.clamp(puddles, 0, 1)
end

-- El tamaño de un charco con el agua que hay (0..1): pequeño al empezar, grande tras mucho llover
function Wetness.puddleScale(puddles: number): number
	return 0.55 + 0.75 * math.clamp(puddles, 0, 1)
end

-- Vapor que sube del suelo caliente tras la lluvia (0..1): verano (algo en primavera), de día, con
-- sol y el suelo aún mojado
function Wetness.steam(season: string?, weather: string?, wet: number, clock: number): number
	local amount = if season == "Verano" then 1 elseif season == "Primavera" then 0.4 else 0
	if amount <= 0 or (weather ~= "Despejado" and weather ~= "Intervalos") then
		return 0
	end
	if clock < 9 or clock >= 19.5 then
		return 0
	end
	return amount * math.clamp((wet - 0.15) / 0.5, 0, 1)
end

-- Lo que cuesta como mucho en cada nivel gráfico (Controllers/SeasonDecor; todo cerca de la cámara y
-- reutilizado): líneas de goteo de tejados y toldos, vapor por segundo, bombillas de la plaza en fiestas
Wetness.Budget = {
	Low = { Drips = 1, DripRate = 10, Steam = 3, Bulbs = 48 },
	Medium = { Drips = 3, DripRate = 18, Steam = 8, Bulbs = 96 },
	High = { Drips = 5, DripRate = 26, Steam = 14, Bulbs = 128 },
}
function Wetness.budget(tier: string?): { [string]: number }
	return Wetness.Budget[tier or "Medium"] or Wetness.Budget.Medium
end

-- Gotas por segundo que caen del borde de un toldo o un tejado: mientras llueve (más cuanto más
-- llueve y más largo es el borde) y un rato después, mientras sigue mojado (pocas)
function Wetness.dripRate(rain: number, wet: number, edge: number, perEdge: number): number
	local length = math.clamp(edge / 10, 0.3, 2.4)
	if rain > 0.02 then
		return math.floor(perEdge * math.min(rain, 1.4) * length + 0.5)
	end
	if wet > 0.3 then
		return math.floor(perEdge * 0.25 * (wet - 0.3) / 0.7 * length + 0.5)
	end
	return 0
end

-- El borde de un toldo (una pieza de tamaño size) por el que gotea hacia donde estás: dir = hacia la
-- cámara, en el espacio de la pieza. Devuelve el centro del borde (en la pieza, abajo), su largo y si
-- va a lo largo de X (true) o de Z.
function Wetness.dripEdge(size: Vector3, dir: Vector3): (Vector3, number, boolean)
	local hx, hz = size.X / 2, size.Z / 2
	local useX = math.abs(dir.X) / math.max(hx, 0.1) >= math.abs(dir.Z) / math.max(hz, 0.1)
	if useX then
		local sign = if dir.X >= 0 then 1 else -1
		return Vector3.new(sign * hx, -size.Y / 2, 0), size.Z, false
	end
	local sign = if dir.Z >= 0 then 1 else -1
	return Vector3.new(0, -size.Y / 2, sign * hz), size.X, true
end

-- Cuánto se oscurece el terreno de Valmar mojado (hierba, tierra: Terrain:SetMaterialColor, solo los
-- materiales de shared/TerrainPalette.Wettable, nunca los del fondo del mar)
function Wetness.terrainDarken(wet: number): number
	return 0.22 * math.clamp(wet, 0, 1)
end

return Wetness
