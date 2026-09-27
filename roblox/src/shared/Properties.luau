-- Properties: reglas de las viviendas en venta (PropertyService en el servidor).
--
--   * Cada casa y villa del mapa, y cada planta de los bloques de pisos, es una vivienda.
--   * Parte de ellas son de vecinos (personajes del juego: los de la historia y otros vecinos);
--     el resto están en venta. La que compra un jugador es suya en todos los servidores.
--   * Precio según el tipo y la planta (con una variación fija por vivienda).
--   * Se puede vender por una parte de lo que costó.

local Properties = {}

Properties.MinStage = "AdultoJoven" -- para comprar hace falta esta edad
Properties.MaxOwned = 3
Properties.SellShare = 0.7
Properties.NeighborShare = 0.5 -- parte de las viviendas en las que ya viven vecinos

Properties.Base = {
	Casa = 3200,
	Villa = 12000,
	Piso = 1500,
}

-- Número fijo a partir de un texto (la misma vivienda siempre da lo mismo)
function Properties.hash(text: string): number
	local h = 5381
	for i = 1, #text do
		h = (h * 33 + string.byte(text, i)) % 2147483647
	end
	return h
end

-- Nombre único de una vivienda: edificio + planta
function Properties.unitKey(buildingKey: string, floor: number | string): string
	return buildingKey .. "#" .. floor
end

function Properties.price(kind: string, floor: number, unitKey: string): number
	local base = Properties.Base[kind] or Properties.Base.Piso
	local variation = 0.85 + (Properties.hash(unitKey) % 31) / 100 -- 0.85 .. 1.15
	local height = if kind == "Piso" then 1 + math.min(floor, 20) * 0.02 else 1 -- más arriba, algo más cara
	return math.floor(base * variation * height / 10 + 0.5) * 10
end

function Properties.sellPrice(price: number): number
	return math.floor(price * Properties.SellShare / 10 + 0.5) * 10
end

-- ¿Viven vecinos (personajes del juego) en esta vivienda?
function Properties.isNeighborHome(unitKey: string): boolean
	return (Properties.hash("vecinos:" .. unitKey) % 1000) < Properties.NeighborShare * 1000
end

-- Vecinos genéricos: nombres fijos por vivienda
local NAMES = {
	"Carmen", "Antonio", "María", "José", "Lucía", "Manuel", "Elena", "Francisco", "Laura", "David",
	"Ana", "Javier", "Isabel", "Pedro", "Marta", "Luis", "Rosa", "Miguel", "Pilar", "Sergio",
	"Cristina", "Raúl", "Beatriz", "Alberto", "Silvia", "Fernando", "Nerea", "Óscar", "Patricia", "Hugo",
}
local SURNAMES = { "García", "Martínez", "López", "Sánchez", "Pérez", "Gómez", "Ruiz", "Díaz", "Moreno", "Álvarez", "Romero", "Navarro", "Torres", "Ramos", "Gil", "Serrano" }

-- Los vecinos de una vivienda: 1 a 3 personas con su nombre (la misma vivienda, los mismos vecinos)
function Properties.neighbors(unitKey: string): { string }
	local h = Properties.hash("gente:" .. unitKey)
	local count = 1 + h % 3
	local surname = SURNAMES[(h // 7) % #SURNAMES + 1]
	local list = {}
	for i = 1, count do
		local name = NAMES[(h // (13 * i)) % #NAMES + 1]
		if not table.find(list, name) then
			table.insert(list, name)
		end
	end
	for i, name in list do
		list[i] = if i == 1 then name .. " " .. surname else name
	end
	return list
end

return Properties
