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
	local darken = 0.22 * wet * (1 - 0.5 * snow)
	local reflect = wet * shiny * (if floor then 0.32 else 0.08)
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

-- Coches de la ciudad (tráfico): van más despacio con lluvia y más aún con nieve
function Wetness.trafficSpeed(wet: number, snow: number): number
	return math.clamp(1 - 0.2 * wet - 0.35 * snow, 0.5, 1)
end

return Wetness
