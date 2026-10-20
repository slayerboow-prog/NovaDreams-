-- Housing: la ficha de cada vivienda y local de la ciudad (funciones puras: las usan HousingService,
-- PropertyService, la interfaz y las pruebas).
--
--   * ID único y legible: distrito, edificio, planta y puerta. «D03-E014-0402» es el distrito 3,
--     el edificio 14 de ese distrito, la 4ª planta, puerta 2 (la B). Las casas y chalets son «-0001».
--   * Tipo de vivienda (Estudio, Piso, Piso grande, Ático, Casa, Chalet) con sus habitaciones, baños,
--     metros y si tiene terraza, jardín, piscina o garaje. Sale de la planta, la puerta y el edificio,
--     así que la misma vivienda siempre es igual.
--   * Precio de compra (shared/Properties) y alquiler por día de juego.
--   * Reglas del alquiler: se paga cada día de juego; si no hay dinero se acumula deuda con avisos,
--     y solo al tercer impago seguido se pierde el contrato.

local Properties = require(script.Parent.Properties)

local Housing = {}

export type Sheet = {
	Id: string, -- D03-E014-0402
	District: number,
	DistrictName: string?,
	Building: number,
	Floor: number,
	Door: number,
	Type: string, -- Estudio, Piso, PisoGrande, Atico, Casa, Chalet
	TypeName: string,
	Rooms: number, -- dormitorios
	Baths: number,
	Meters: number,
	Extras: { string }, -- Terraza, Jardín, Piscina, Garaje, Vistas
	Price: number,
	Rent: number, -- por día de juego
}

Housing.RentShare = 1 / 40 -- alquiler de un día = precio / 40
Housing.MaxUnpaid = 3 -- impagos seguidos antes de perder el contrato
Housing.TempAccessSeconds = 120 -- al abrir la puerta desde el timbre
Housing.MaxKeys = 12 -- llaves que puede repartir un dueño

Housing.Types = {
	Estudio = { Name = "Estudio", Rooms = 1, Baths = 1, Meters = 35, Factor = 0.7 },
	Piso = { Name = "Piso", Rooms = 2, Baths = 1, Meters = 70, Factor = 1 },
	PisoGrande = { Name = "Piso grande", Rooms = 3, Baths = 2, Meters = 110, Factor = 1.45, Extras = { "Terraza" } },
	Atico = { Name = "Ático", Rooms = 3, Baths = 2, Meters = 130, Factor = 2.1, Extras = { "Terraza", "Vistas" } },
	Casa = { Name = "Casa", Rooms = 3, Baths = 2, Meters = 140, Factor = 1, Extras = { "Jardín", "Garaje" } },
	Chalet = { Name = "Chalet", Rooms = 5, Baths = 3, Meters = 260, Factor = 1, Extras = { "Jardín", "Piscina", "Garaje" } },
}

-- «B» -> 2 (A = 1)
function Housing.doorNumber(letter: string?): number
	if letter == nil or letter == "" then
		return 1
	end
	return string.byte(string.upper(letter)) - 64
end

-- El ID de siempre: «D03-E014-0402»
function Housing.id(district: number, building: number, floor: number, letter: string?): string
	return ("D%02d-E%03d-%02d%02d"):format(district, building, floor, Housing.doorNumber(letter))
end

-- Y al revés: «D03-E014-0402» -> 3, 14, 4, 2
function Housing.parseId(id: string): (number?, number?, number?, number?)
	local d, b, f, n = string.match(id, "^D(%d+)%-E(%d+)%-(%d%d)(%d%d)$")
	if not d then
		return nil, nil, nil, nil
	end
	return tonumber(d), tonumber(b), tonumber(f), tonumber(n)
end

-- Tipo de vivienda: kind = Casa / Villa / Piso (el de shared/Properties); top = última planta
function Housing.typeOf(kind: string, unitKey: string, floor: number, top: number?, doors: number?): string
	if kind == "Casa" then
		return "Casa"
	elseif kind == "Villa" then
		return "Chalet"
	end
	if top and floor >= top and floor >= 2 then
		return "Atico"
	end
	local h = Properties.hash("tipo:" .. unitKey) % 100
	-- (en plantas con muchas puertas hay más estudios; con pocas, pisos más grandes)
	local many = (doors or 4) >= 6
	if h < (if many then 30 else 12) then
		return "Estudio"
	elseif h < (if many then 85 else 70) then
		return "Piso"
	end
	return "PisoGrande"
end

-- Precio según el tipo (sobre el de Properties) y alquiler por día de juego
function Housing.price(kind: string, typeId: string, floor: number, unitKey: string): number
	local base = Properties.price(kind, floor, unitKey)
	local t = Housing.Types[typeId] or Housing.Types.Piso
	return math.floor(base * t.Factor / 10 + 0.5) * 10
end

function Housing.rent(price: number): number
	return math.max(10, math.floor(price * Housing.RentShare / 5 + 0.5) * 5)
end

-- La ficha completa
function Housing.sheet(args: { District: number, DistrictName: string?, Building: number, Floor: number, Letter: string?, Kind: string, UnitKey: string, Top: number?, Doors: number? }): Sheet
	local typeId = Housing.typeOf(args.Kind, args.UnitKey, args.Floor, args.Top, args.Doors)
	local t = Housing.Types[typeId]
	local price = Housing.price(args.Kind, typeId, args.Floor, args.UnitKey)
	local extras = table.clone(t.Extras or {})
	-- (algunos pisos grandes tienen plaza de garaje)
	if typeId == "PisoGrande" and Properties.hash("garaje:" .. args.UnitKey) % 3 == 0 then
		table.insert(extras, "Garaje")
	end
	return {
		Id = Housing.id(args.District, args.Building, args.Floor, args.Letter),
		District = args.District,
		DistrictName = args.DistrictName,
		Building = args.Building,
		Floor = args.Floor,
		Door = Housing.doorNumber(args.Letter),
		Type = typeId,
		TypeName = t.Name,
		Rooms = t.Rooms,
		Baths = t.Baths,
		Meters = t.Meters + Properties.hash("m2:" .. args.UnitKey) % 12,
		Extras = extras,
		Price = price,
		Rent = Housing.rent(price),
	}
end

-- Una línea para carteles y avisos: «Piso · 2 hab. · 1 baño · 74 m² · Terraza»
function Housing.describe(sheet: Sheet): string
	local parts = { sheet.TypeName, ("%d hab."):format(sheet.Rooms), ("%d baño%s"):format(sheet.Baths, if sheet.Baths > 1 then "s" else ""), ("%d m²"):format(sheet.Meters) }
	for _, extra in sheet.Extras do
		table.insert(parts, extra)
	end
	return table.concat(parts, " · ")
end

-- Alquiler: qué pasa al cobrar un día. Devuelve el estado nuevo y lo que hay que avisar.
--   state = { Debt, Unpaid }; paid = si se pudo cobrar
function Housing.rentStep(state: { Debt: number?, Unpaid: number? }, rent: number, paid: boolean): ({ Debt: number, Unpaid: number }, string)
	local debt = state.Debt or 0
	local unpaid = state.Unpaid or 0
	if paid then
		return { Debt = 0, Unpaid = 0 }, "Paid"
	end
	debt += rent
	unpaid += 1
	if unpaid >= Housing.MaxUnpaid then
		return { Debt = debt, Unpaid = unpaid }, "Evicted"
	end
	return { Debt = debt, Unpaid = unpaid }, "Warning"
end

return Housing
