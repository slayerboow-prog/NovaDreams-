-- Layers: las capas de altura del cielo de Valmar (cuentas puras; docs/espacio.md).
--
--   Y (studs)
--   9000 ┬ techo del espacio (la nave vuelve sola hacia abajo)
--        │  ESPACIO: estaciones, campos de asteroides, patrullas enemigas, los 7 planetas al fondo
--   3400 ┼ empieza el espacio (cielo negro, estrellas; solo desde aquí hay enemigos: AIMinY = 3700)
--   2800 ┼ la nave pasa de «Atmos» a «Space» (ShipFlight: sin gravedad desde aquí)
--        │  TRANSICIÓN: el cielo se oscurece poco a poco y salen las estrellas
--   1800 ┼ fin del cielo de los aviones (reservado: nada del espacio por debajo)
--   1400 ┼ techo de los aviones (shared/Flight.Bounds.Ceiling; AviationService corta en 1700)
--        │  CIELO DE LOS AVIONES: combate aéreo con aviones sobre la ciudad. Las naves lo cruzan, pero
--        │  aquí no sale ningún enemigo del espacio ni nada que estorbe.
--    260 ┼ suelo de las naves (más abajo solo junto al puerto espacial, para despegar y aterrizar)
--      0 ┴ el suelo de Valmar
--
-- En planta, el espacio ocupa la columna de ±7000 studs alrededor de Valmar (14 000 de lado; la ciudad
-- y el aeroclub acaban en ±5600). La arena de pruebas del combate aéreo (shared/AirCombat/Arena) sigue
-- aparte, en X = Z = 24 000.

local Flight = require(script.Parent.Parent.Flight)

local Layers = {}

Layers.GroundY = 0
Layers.PlaneCeiling = Flight.Bounds.Ceiling -- 1400: techo de los aviones
Layers.PlaneBandTop = 1800 -- hasta aquí, el cielo es de los aviones
Layers.TransitionY = 1800 -- desde aquí se oscurece el cielo
Layers.ModeY = 2800 -- la nave pasa a modo espacio (sin gravedad)
Layers.SpaceY = 3400 -- empieza el espacio
Layers.AIMinY = 3700 -- (enemigos solo desde aquí: nunca bajan al cielo de los aviones)
Layers.TopY = 9000 -- techo del espacio
Layers.FloorY = 260 -- suelo de las naves (lejos del puerto espacial)
Layers.LandY = 900 -- por debajo de esto puedes aterrizar (bajarte de la nave)
Layers.Half = 7000 -- medio lado de la columna del espacio (X y Z, alrededor de Valmar)
Layers.Center = Vector3.new(0, 0, 0)
-- Durante una «Invasión de la Grieta» (docs/invasion.md) las naves pueden bajar al cielo de la ciudad
-- hasta CityFloorY (por encima de los tejados) para pelear; el resto del tiempo, su suelo es FloorY.
-- Lo enciende InvasionService (servidor) y Controllers/InvasionClient (cliente, con el atributo
-- InvasionActive de workspace): así la predicción del vuelo y la comprobación del servidor coinciden.
Layers.CityFloorY = 140
local cityOpen = false

function Layers.setCityOpen(on: boolean)
	cityOpen = on == true
end

function Layers.cityOpen(): boolean
	return cityOpen
end

-- El suelo de las naves ahora (lejos del puerto espacial)
function Layers.floorAt(_pos: Vector3?): number
	return if cityOpen then Layers.CityFloorY else Layers.FloorY
end

-- Nombre de la capa en esa altura
function Layers.layerAt(y: number): string
	if y < Layers.PlaneBandTop then
		return "Aviones"
	elseif y < Layers.SpaceY then
		return "Transicion"
	end
	return "Espacio"
end

-- Nombre para el panel
Layers.Names = { Aviones = "Cielo de Valmar", Transicion = "Alta atmósfera", Espacio = "Espacio" }

-- Modo de vuelo de la nave (ShipFlight)
function Layers.mode(y: number): string
	return if y >= Layers.ModeY then "Space" else "Atmos"
end

-- Cuánto espacio hay en el cielo (0 = cielo de Valmar, 1 = negro con estrellas): suave entre
-- TransitionY y SpaceY
function Layers.skyBlend(y: number): number
	local t = math.clamp((y - Layers.TransitionY) / (Layers.SpaceY - Layers.TransitionY), 0, 1)
	return t * t * (3 - 2 * t)
end

-- ¿Dentro de la columna del espacio de Valmar (en planta)?
function Layers.inColumn(pos: Vector3, margin: number?): boolean
	local m = margin or 0
	local d = pos - Layers.Center
	return math.abs(d.X) <= Layers.Half + m and math.abs(d.Z) <= Layers.Half + m
end

-- ¿Está en la zona del espacio (para guardar el sitio de Valmar al desconectarse, etc.)?
function Layers.inSpace(pos: Vector3): boolean
	return pos.Y >= Layers.TransitionY and Layers.inColumn(pos, 600)
end

-- ¿Pueden salir enemigos aquí? (nunca en el cielo de los aviones ni en la transición)
function Layers.aiAllowed(pos: Vector3): boolean
	return pos.Y >= Layers.AIMinY and pos.Y <= Layers.TopY and Layers.inColumn(pos)
end

-- ¿Se puede aterrizar (bajarse de la nave) aquí?
function Layers.canLand(pos: Vector3): boolean
	return pos.Y <= Layers.LandY
end

-- Altura para el panel (como el avión: shared/Flight.METERS metros por stud)
function Layers.meters(y: number): number
	return math.floor(math.max(0, y) * Flight.METERS + 0.5)
end

return Layers
