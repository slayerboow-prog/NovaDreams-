-- Floors: cómo son por dentro los edificios de varias plantas (funciones puras; las usan
-- World/Tower, InteriorService, PropertyService y las pruebas).
--
--   * Cada planta tiene rellano, pasillo, escalera de verdad (dos tramos con descansillo) y ascensor.
--   * En el pasillo, puertas numeradas: viviendas ("3ºA", "3ºB"…), oficinas ("Oficina 301"),
--     aulas ("Aula 204") o locales ("Local 102"). Cada puerta lleva a su piso, oficina, aula o local.
--   * La planta baja es el portal (vestíbulo con la puerta a la calle). En los edificios de comercio
--     la tienda de la planta baja da a la calle y también tiene puerta al portal.
--
-- Cada puerta es una "unidad" con un nombre fijo dentro del edificio (unitId): la planta y la
-- letra. La puerta A de cada planta se llama como la planta ("3"), así las viviendas compradas
-- antes (una por planta) siguen siendo las mismas: ahora son el 3ºA.

local Floors = {}

Floors.Height = 12 -- de suelo a suelo
Floors.StepRise = 0.75 -- altura de cada escalón (se sube andando)
Floors.StepRun = 1 -- fondo de cada escalón
Floors.StepsPerFlight = 8 -- dos tramos de 8 escalones = 12 studs
Floors.CoreWidth = 10 -- hueco de la escalera (a lo ancho)
Floors.Depth = 20 -- fondo de cada planta (pasillo, escalera y descansillo)
Floors.CorridorWidth = 6
Floors.DoorSpacing = 7
Floors.Near = 2 -- se montan las plantas a 2 o menos de algún jugador
Floors.Keep = 3 -- y se quitan las que quedan a más de 3

local LETTERS = { "A", "B", "C", "D", "E", "F", "G", "H" }

function Floors.hash(text: string): number
	local h = 5381
	for i = 1, #text do
		h = (h * 33 + string.byte(text, i)) % 2147483647
	end
	return h
end

-- ¿Se sube por dentro (escalera, pasillos y puertas) o es de una sola sala?
function Floors.isTower(upper: string?, floors: number): boolean
	return upper ~= nil and floors >= 2
end

-- Nombre fijo de una puerta dentro del edificio ("3" para la A, "3B", "3C"…)
function Floors.unitId(floor: number, letter: string?): string
	if letter == nil or letter == "" or letter == "A" then
		return tostring(floor)
	end
	return tostring(floor) .. letter
end

-- Y al revés: "3B" -> 3, "B"
function Floors.parseUnit(id: string): (number?, string?)
	local floor, letter = string.match(id, "^(%d+)(%a?)$")
	if not floor then
		return nil, nil
	end
	return tonumber(floor), if letter == "" then "A" else letter
end

export type Unit = {
	Letter: string,
	Id: string, -- unitId
	Label: string, -- lo que pone en la puerta ("3ºB", "Oficina 301")
	Kind: string, -- sala que hay detrás (Interiors: Piso, Oficina, Aula, Local, CentroComercial)
	Ground: boolean?, -- la sala de la planta baja (la tienda que da a la calle)
}

-- Cuántas puertas hay en esa planta y qué hay detrás. ground = sala de la planta baja del
-- edificio (Portal, Local, OficinaLobby, Aula, CentroComercial, Walk); upper = la de arriba.
function Floors.units(buildingKey: string, ground: string, upper: string?, floor: number): { Unit }
	local list: { Unit } = {}
	local h = Floors.hash(buildingKey .. "@" .. floor)
	local function add(i: number, label: string, kind: string, isGround: boolean?)
		local letter = LETTERS[i]
		table.insert(list, { Letter = letter, Id = Floors.unitId(floor, letter), Label = label, Kind = kind, Ground = isGround })
	end
	if floor == 0 then
		if ground == "Local" then
			add(1, "Tienda", "Local", true)
		elseif ground == "CentroComercial" then
			add(1, "Centro comercial", "CentroComercial", true)
		elseif ground == "Aula" then
			local n = 2 + h % 2
			for i = 1, n do
				add(i, ("Aula %02d"):format(i), "Aula", i == 1)
			end
		end
		return list
	end
	if upper == "Piso" then
		local n = 3 + h % 4 -- de 3 a 6 viviendas por planta
		for i = 1, n do
			add(i, ("%dº%s"):format(floor, LETTERS[i]), "Piso")
		end
	elseif upper == "Oficina" then
		local n = 2 + h % 3
		for i = 1, n do
			add(i, ("Oficina %d%02d"):format(floor, i), "Oficina")
		end
	elseif upper == "Aula" then
		local n = 2 + h % 2
		for i = 1, n do
			add(i, ("Aula %d%02d"):format(floor, i), "Aula")
		end
	elseif upper == "Dorm" then
		-- Residencia universitaria: habitaciones (compartidas o, con suerte, individuales)
		local n = 4 + h % 3
		for i = 1, n do
			add(i, ("Hab. %d%02d"):format(floor, i), "Dorm")
		end
	elseif upper == "Local" then
		local n = 3 + h % 2
		for i = 1, n do
			add(i, ("Local %d%02d"):format(floor, i), "Local")
		end
	end
	return list
end

-- La puerta de esa planta con esa letra (o nil)
function Floors.unit(buildingKey: string, ground: string, upper: string?, floor: number, letter: string?): Unit?
	for _, u in Floors.units(buildingKey, ground, upper, floor) do
		if u.Letter == (letter or "A") then
			return u
		end
	end
	return nil
end

-- Ancho de la planta para que quepan las puertas (la mitad a cada lado del pasillo)
function Floors.width(doors: number): number
	local perSide = math.max(2, math.ceil(doors / 2))
	return Floors.CoreWidth + perSide * Floors.DoorSpacing + 15 -- (y el ascensor en la pared de dentro)
end

-- Planta en la que está alguien a esa altura (desde el suelo de la planta baja)
function Floors.floorAt(y: number, top: number): number
	return math.clamp(math.floor((y + 2) / Floors.Height), 0, top)
end

-- Las plantas que hay que tener montadas con jugadores en esas plantas (y las que se pueden quitar)
function Floors.wanted(playerFloors: { number }, top: number): ({ [number]: boolean }, { [number]: boolean })
	local build, keep = {}, {}
	for _, f in playerFloors do
		for k = math.max(0, f - Floors.Near), math.min(top, f + Floors.Near) do
			build[k] = true
		end
		for k = math.max(0, f - Floors.Keep), math.min(top, f + Floors.Keep) do
			keep[k] = true
		end
	end
	return build, keep
end

-- Escalones de una planta a la siguiente: { Y (arriba del escalón), Z (centro), Lane (1 = subida
-- hacia +Z, 2 = vuelta hacia -Z) } en coordenadas de la planta (suelo en y = 0). Entre los dos
-- tramos, el descansillo a media altura.
function Floors.steps(): { { Y: number, Z: number, Lane: number } }
	local out = {}
	local n, rise, run = Floors.StepsPerFlight, Floors.StepRise, Floors.StepRun
	local z0 = -n * run / 2
	for i = 1, n do
		table.insert(out, { Y = i * rise, Z = z0 + (i - 0.5) * run, Lane = 1 })
	end
	for i = 1, n do
		table.insert(out, { Y = n * rise + i * rise, Z = -z0 - (i - 0.5) * run, Lane = 2 })
	end
	return out
end

-- Dueños posibles de una oficina (nombre en la puerta) o nil si está libre ("SE ALQUILA")
local COMPANIES = {
	"Grupo Valmar", "Nova Seguros", "Inmobiliaria Sol", "Tecnoval", "Banco del Puerto", "Consultores Atlántico",
	"Valmar Media", "Logística Norte", "Abogados Ruiz & Gil", "Estudio Faro", "Clínica Dental Sonrisa",
	"Academia Delta", "Gestoría Martínez", "Viajes Brisa", "Arquitectos Mar",
}
function Floors.company(buildingKey: string, unitId: string): string?
	local h = Floors.hash("empresa:" .. buildingKey .. "#" .. unitId)
	if h % 4 == 0 then
		return nil
	end
	return COMPANIES[(h // 7) % #COMPANIES + 1]
end

-- ¿Es individual esta habitación de la residencia? (una de cada cuatro, más o menos)
function Floors.dormSingle(buildingKey: string, unitId: string): boolean
	return Floors.hash("individual:" .. buildingKey .. "#" .. unitId) % 4 == 0
end

-- Horario de las oficinas y los locales (hora del juego)
Floors.OpenFrom, Floors.OpenTo = 8, 20
function Floors.isOpen(clockTime: number): boolean
	return clockTime >= Floors.OpenFrom and clockTime < Floors.OpenTo
end

return Floors
