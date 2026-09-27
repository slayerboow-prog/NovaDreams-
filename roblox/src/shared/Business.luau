-- Business: negocios de los jugadores (BusinessService en el servidor, EconomyUI en el cliente).
--
-- CÓMO FUNCIONA
--   * LOCALES: la planta baja de los edificios de comercio de todas las ciudades, las gasolineras y
--     los hoteles. Los libres tienen un cartel "SE VENDE"; los compras y eliges qué negocio abrir
--     (tienda de alimentación, frutería, panadería, restaurante, cafetería, tienda de ropa;
--     en una gasolinera, gasolinera; en un hotel, hotel). Son tuyos en todos los servidores.
--   * EXISTENCIAS: llevas productos de tu mochila al negocio (lo que sacas del campo y del obrador,
--     los platos que cocinas en tu restaurante…) o se los compras al MAYORISTA (gasolina, noches
--     de hotel, refrescos, snacks). Cada tipo de negocio solo vende ciertas categorías.
--   * PRECIOS: los pones tú. Cuanto más caro, menos clientes. El precio de referencia es lo normal.
--   * CLIENTES: los vecinos de Valmar (NPC) compran solos cada rato, aunque no estés conectado
--     (hasta Business.MaxOfflineHours seguidas). Los jugadores compran en el mostrador. Las
--     gasolineras cobran a quien reposta y los hoteles a quien reserva habitación.
--   * CAJA: lo que se vende va a la caja del negocio. Los gastos (luz, agua, impuestos) salen de ahí.
--     "Recoger caja" te lo pasa a tu dinero.
--   * REPUTACIÓN (⭐ 0-5): sube con precios justos y estanterías llenas; baja si está vacío o caro.
--     Con más reputación vienen más clientes.
--   * Vender el local: te devuelven una parte de lo que costó (y lo que quede en la caja).
--
-- Un "producto" (good) del negocio es un objeto de la mochila (Agro_*, Refresco…) o algo que solo
-- existe en el negocio (W_Gasolina, W_Habitacion).

local Farming = require(script.Parent.Farming)
local Groceries = require(script.Parent.Groceries)

local Business = {}

Business.MinStage = "AdultoJoven"
Business.MaxOwned = 3 -- negocios distintos
Business.MaxWithBranches = 6 -- contando las sucursales de tus cadenas
Business.BranchLicense = 0.5 -- una sucursal paga la mitad de la licencia

-- Empleados
Business.MaxNpc = 2 -- dependientes contratados (personajes del juego)
Business.NpcWage = 12 -- lo que cobra cada dependiente por hora (sale de la caja)
Business.NpcBoost = 0.25 -- cada dependiente atiende a un 25 % más de clientes
Business.MaxWorkers = 3 -- jugadores contratados
Business.Wages = { 6, 9, 12 } -- sueldo por minuto de turno de un jugador (sale de la caja)
Business.ShiftBoost = 0.4 -- cada jugador de turno atiende a un 40 % más de clientes
Business.ChainStep = 0.1 -- cada sucursal abierta de la misma cadena: +10 % de clientes
Business.ChainMax = 0.3
Business.SellShare = 0.6 -- al vender el local te devuelven un 60 %
Business.MaxOfflineHours = 8 -- como mucho se simulan 8 horas seguidas sin que nadie mire
Business.StockMax = 500 -- existencias máximas de cada producto (la gasolina, en litros: x20)
Business.StartRep = 3
Business.RetailMarkup = 1.8 -- precio de referencia = lo que paga la cooperativa x 1,8

Business.Categories = {
	Fruta = { Name = "Fruta", Icon = "🍎" },
	Verdura = { Name = "Verdura", Icon = "🥬" },
	Lacteo = { Name = "Lácteos y huevos", Icon = "🥛" },
	Panaderia = { Name = "Panadería", Icon = "🥖" },
	Despensa = { Name = "Despensa", Icon = "🫙" },
	Bebida = { Name = "Bebidas", Icon = "🥤" },
	Snack = { Name = "Snacks", Icon = "🍫" },
	Plato = { Name = "Platos", Icon = "🍽️" },
	Textil = { Name = "Ropa", Icon = "🧥" },
	Combustible = { Name = "Combustible", Icon = "⛽" },
	Habitacion = { Name = "Habitaciones", Icon = "🛏️" },
}

---------------------------------------------------------------------
-- Tipos de negocio
---------------------------------------------------------------------
export type BizType = {
	Id: string,
	Name: string,
	Icon: string,
	Premise: string, -- "Local" | "Gas" | "Hotel"
	License: number, -- licencia de apertura
	Categories: { string },
	Demand: number, -- clientes por hora (con reputación 3 y precios normales)
	Capacity: number, -- unidades por hora como mucho (sin contar gasolina ni habitaciones)
	Upkeep: number, -- gastos por hora abierto
	Kitchen: boolean?, -- tiene cocina (recetas de Farming con Station "Cocina")
	Names: { string }, -- nombres para elegir (%s = nombre del dueño)
	Color: Color3,
}

local rgb = Color3.fromRGB
Business.Types = {
	Colmado = {
		Id = "Colmado", Name = "Tienda de alimentación", Icon = "🛒", Premise = "Local", License = 300,
		Categories = { "Fruta", "Verdura", "Lacteo", "Panaderia", "Despensa", "Bebida", "Snack" },
		Demand = 30, Capacity = 60, Upkeep = 12,
		Names = { "Ultramarinos %s", "La Despensa de %s", "Colmado %s", "Comestibles %s" },
		Color = rgb(40, 130, 70),
	},
	Fruteria = {
		Id = "Fruteria", Name = "Frutería", Icon = "🍎", Premise = "Local", License = 200,
		Categories = { "Fruta", "Verdura" },
		Demand = 34, Capacity = 55, Upkeep = 10,
		Names = { "Frutas %s", "La Huerta de %s", "Frutería %s", "El Vergel de %s" },
		Color = rgb(200, 60, 50),
	},
	Panaderia = {
		Id = "Panaderia", Name = "Panadería y pastelería", Icon = "🥐", Premise = "Local", License = 300,
		Categories = { "Panaderia", "Bebida" },
		Demand = 34, Capacity = 55, Upkeep = 12,
		Names = { "Horno %s", "Panadería %s", "La Espiga de %s", "Dulces %s" },
		Color = rgb(190, 130, 60),
	},
	Restaurante = {
		Id = "Restaurante", Name = "Restaurante", Icon = "🍽️", Premise = "Local", License = 800,
		Categories = { "Plato", "Bebida" },
		Demand = 24, Capacity = 40, Upkeep = 20, Kitchen = true,
		Names = { "Restaurante %s", "Casa %s", "El Rincón de %s", "Mesón %s" },
		Color = rgb(150, 40, 50),
	},
	Cafeteria = {
		Id = "Cafeteria", Name = "Cafetería", Icon = "☕", Premise = "Local", License = 500,
		Categories = { "Bebida", "Panaderia", "Snack" },
		Demand = 36, Capacity = 60, Upkeep = 14, Kitchen = true,
		Names = { "Café %s", "Cafetería %s", "El Café de %s", "La Taza de %s" },
		Color = rgb(110, 70, 40),
	},
	Ropa = {
		Id = "Ropa", Name = "Tienda de ropa", Icon = "👕", Premise = "Local", License = 400,
		Categories = { "Textil" },
		Demand = 10, Capacity = 20, Upkeep = 10,
		Names = { "Moda %s", "Boutique %s", "Lanas %s", "El Armario de %s" },
		Color = rgb(120, 60, 150),
	},
	Gasolinera = {
		Id = "Gasolinera", Name = "Gasolinera", Icon = "⛽", Premise = "Gas", License = 1000,
		Categories = { "Combustible", "Bebida", "Snack" },
		Demand = 24, Capacity = 40, Upkeep = 40,
		Names = { "Estación %s", "Gasolinera %s", "Carburantes %s", "Área de servicio %s" },
		Color = rgb(30, 150, 80),
	},
	Hotel = {
		Id = "Hotel", Name = "Hotel", Icon = "🏨", Premise = "Hotel", License = 2000,
		Categories = { "Habitacion" },
		Demand = 24, Capacity = 40, Upkeep = 90,
		Names = { "Hotel %s", "Gran Hotel %s", "Hostal %s", "Hotel Palacio %s" },
		Color = rgb(40, 70, 130),
	},
} :: { [string]: BizType }
Business.TypeOrder = { "Colmado", "Fruteria", "Panaderia", "Restaurante", "Cafeteria", "Ropa", "Gasolinera", "Hotel" }

function Business.typesFor(premise: string): { BizType }
	local list = {}
	for _, id in Business.TypeOrder do
		local t = Business.Types[id]
		if t.Premise == premise then
			table.insert(list, t)
		end
	end
	return list
end

function Business.nameFor(bizType: BizType, index: number, owner: string): string
	local pattern = bizType.Names[((index - 1) % #bizType.Names) + 1]
	return pattern:format(owner)
end

---------------------------------------------------------------------
-- Locales
---------------------------------------------------------------------
Business.Premises = {
	Local = { Name = "Local comercial", Icon = "🏬", Price = 2500 },
	Gas = { Name = "Gasolinera", Icon = "⛽", Price = 15000 },
	Hotel = { Name = "Hotel", Icon = "🏨", Price = 40000 },
}

local function hash(text: string): number
	local h = 5381
	for i = 1, #text do
		h = (h * 33 + string.byte(text, i)) % 2147483647
	end
	return h
end

-- Precio del local (con una variación fija por sitio: 0,85 a 1,15)
function Business.premisePrice(premise: string, key: string): number
	local base = Business.Premises[premise].Price
	local variation = 0.85 + (hash(key) % 31) / 100
	return math.floor(base * variation / 50 + 0.5) * 50
end

function Business.sellBack(price: number): number
	return math.floor(price * Business.SellShare / 10 + 0.5) * 10
end

---------------------------------------------------------------------
-- Productos que se pueden vender
---------------------------------------------------------------------
export type Good = {
	Id: string,
	Name: string,
	Icon: string,
	Category: string,
	Ref: number, -- precio de referencia (lo normal)
	Weight: number, -- cuánto lo piden los clientes (unidades por cliente)
	Item: string?, -- objeto de la mochila (nil = solo existe en el negocio)
	Cost: number?, -- mayorista: lo que cuesta cada unidad
	Lot: number?, -- mayorista: cuántas unidades vienen en cada pedido
	Unit: string?, -- "L" (gasolina)
	Bulk: boolean?, -- no cuenta para la capacidad de la tienda (gasolina, habitaciones)
	Step: number?, -- de cuánto en cuánto se cambia el precio
}

Business.Goods = {} :: { [string]: Good }

local WEIGHT = { Fruta = 1, Verdura = 1, Lacteo = 0.9, Panaderia = 1.1, Despensa = 0.6, Bebida = 1, Snack = 0.8, Plato = 1, Textil = 0.5 }

for id, p in Farming.Products do
	Business.Goods[id] = {
		Id = id,
		Name = p.Name,
		Icon = p.Icon,
		Category = p.Category,
		Ref = math.max(1, math.ceil(p.Price * Business.RetailMarkup)),
		Weight = WEIGHT[p.Category] or 0.6,
		Item = id,
	}
end

-- Mayorista: lo que no se produce en Valmar
local function wholesale(id: string, item: string?, name: string, icon: string, category: string, ref: number, cost: number, lot: number, weight: number, extra: { [string]: any }?)
	local good: Good = { Id = id, Name = name, Icon = icon, Category = category, Ref = ref, Weight = weight, Item = item, Cost = cost, Lot = lot }
	for k, v in extra or {} do
		(good :: any)[k] = v
	end
	Business.Goods[id] = good
end
wholesale("W_Gasolina", nil, "Gasolina", "⛽", "Combustible", 1.5, 0.9, 200, 5, { Unit = "L", Bulk = true, Step = 0.1 })
wholesale("W_Habitacion", nil, "Noche de hotel", "🛏️", "Habitacion", 60, 18, 5, 0.12, { Bulk = true, Step = 5 })
for _, id in { "Refresco", "Agua", "Batido" } do
	local g = Groceries.byId[id]
	wholesale(id, id, g.Name, g.Icon, "Bebida", g.Price + 1, math.max(1, g.Price - 1), 24, 0.7)
end
for _, id in { "Patatillas", "Chocolate", "Gominolas", "Galletas" } do
	local g = Groceries.byId[id]
	wholesale(id, id, g.Name, g.Icon, "Snack", g.Price + 1, math.max(1, g.Price - 1), 24, 0.5)
end

-- Lo que el mayorista vende a un tipo de negocio (ordenado)
function Business.wholesaleFor(bizType: BizType): { Good }
	local list = {}
	for _, good in Business.Goods do
		if good.Cost and table.find(bizType.Categories, good.Category) then
			table.insert(list, good)
		end
	end
	table.sort(list, function(a, b)
		return a.Id < b.Id
	end)
	return list
end

function Business.canSell(bizType: BizType, goodId: string): boolean
	local good = Business.Goods[goodId]
	return good ~= nil and table.find(bizType.Categories, good.Category) ~= nil
end

function Business.stockMax(good: Good): number
	return if good.Unit == "L" then Business.StockMax * 20 else Business.StockMax
end

-- Límites de precio (de 0,2 a 3 veces el de referencia) y el paso al cambiarlo
function Business.priceStep(good: Good): number
	return good.Step or math.max(1, math.floor(good.Ref / 10))
end
function Business.clampPrice(good: Good, price: number): number
	local step = Business.priceStep(good)
	local low = math.max(step, good.Ref * 0.2)
	price = math.clamp(price, low, good.Ref * 3)
	local rounded = math.floor(price / step + 0.5) * step
	return math.floor(rounded * 100 + 0.5) / 100 -- (sin decimales raros: 1.7, no 1.7000000000000002)
end

---------------------------------------------------------------------
-- Registro de un negocio (lo que se guarda)
---------------------------------------------------------------------
export type Record = {
	Key: string,
	Premise: string,
	Title: string, -- nombre del sitio (calle/ciudad)
	Owner: number,
	OwnerName: string,
	Paid: number,
	Since: number,
	Type: string?, -- nil = local comprado pero sin negocio abierto
	Name: string?,
	Open: boolean,
	Stock: { [string]: number },
	Prices: { [string]: number },
	Carry: { [string]: number },
	Till: number,
	Rep: number,
	LastSim: number,
	Sales: number, -- total vendido (dinero)
	Units: number,
	Log: { { T: number, Text: string } },
	Npc: number?, -- dependientes contratados
	Workers: { [string]: { Name: string, Wage: number } }?, -- jugadores contratados (UserId en texto)
}

function Business.newRecord(key: string, premise: string, title: string, owner: number, ownerName: string, paid: number, now: number): Record
	return {
		Key = key,
		Premise = premise,
		Title = title,
		Owner = owner,
		OwnerName = ownerName,
		Paid = paid,
		Since = now,
		Type = nil,
		Name = nil,
		Open = false,
		Stock = {},
		Prices = {},
		Carry = {},
		Till = 0,
		Rep = Business.StartRep,
		LastSim = now,
		Sales = 0,
		Units = 0,
		Log = {},
	}
end

function Business.log(rec: Record, now: number, text: string)
	table.insert(rec.Log, { T = now, Text = text })
	while #rec.Log > 12 do
		table.remove(rec.Log, 1)
	end
end

function Business.priceOf(rec: Record, goodId: string): number
	local good = Business.Goods[goodId]
	local price = rec.Prices[goodId]
	return if type(price) == "number" then price elseif good then good.Ref else 0
end

-- Clientes: cuánto compran según el precio (1 = precio de referencia)
function Business.priceFactor(ratio: number): number
	return math.clamp(2.2 - 1.2 * ratio, 0, 1.6)
end

function Business.repFactor(rep: number): number
	return 0.4 + math.clamp(rep, 0, 5) * 0.2
end

---------------------------------------------------------------------
-- Clientes NPC: lo que se vende desde la última vez (sin azar, para que sea igual en todos
-- los servidores). Devuelve unidades, dinero y el detalle por producto; actualiza el registro.
---------------------------------------------------------------------
-- Más clientes por el personal y la cadena. extra = { Shift = jugadores de turno, Chain = sucursales abiertas }
function Business.boost(rec: Record, extra: { Shift: number?, Chain: number? }?): number
	local staff = 1 + (rec.Npc or 0) * Business.NpcBoost + ((extra and extra.Shift) or 0) * Business.ShiftBoost
	local chain = 1 + math.min(Business.ChainMax, math.max(0, ((extra and extra.Chain) or 1) - 1) * Business.ChainStep)
	return staff * chain
end

-- Gastos por hora: los del local más los sueldos de los dependientes
function Business.upkeep(rec: Record): number
	local bizType = rec.Type and Business.Types[rec.Type]
	return (if bizType then bizType.Upkeep else 0) + (rec.Npc or 0) * Business.NpcWage
end

function Business.workerCount(rec: Record): number
	local n = 0
	for _ in rec.Workers or {} do
		n += 1
	end
	return n
end

function Business.simulate(rec: Record, now: number, extra: { Shift: number?, Chain: number? }?): (number, number, { [string]: number })
	local sold: { [string]: number } = {}
	local elapsed = math.clamp(now - (rec.LastSim or now), 0, Business.MaxOfflineHours * 3600)
	rec.LastSim = now
	local bizType = rec.Type and Business.Types[rec.Type]
	if not bizType or not rec.Open or elapsed <= 0 then
		return 0, 0, sold
	end
	local hours = elapsed / 3600
	local rep = Business.repFactor(rec.Rep) * Business.boost(rec, extra)

	-- Lo que pedirían los clientes de cada producto con existencias
	local wants: { [string]: number } = {}
	local normal = 0
	local ratios, stocked, empty = 0, 0, 0
	for goodId, count in rec.Stock do
		local good = Business.Goods[goodId]
		if good and table.find(bizType.Categories, good.Category) then
			if count > 0 then
				local ratio = Business.priceOf(rec, goodId) / good.Ref
				local want = bizType.Demand * good.Weight * rep * Business.priceFactor(ratio) * hours
				wants[goodId] = want
				if not good.Bulk then
					normal += want
				end
				ratios += ratio
				stocked += 1
			else
				empty += 1
			end
		end
	end
	-- La tienda no da para más de Capacity unidades por hora
	local cap = bizType.Capacity * rep * hours
	local scale = if normal > cap and normal > 0 then cap / normal else 1

	local units, money = 0, 0
	for goodId, want in wants do
		local good = Business.Goods[goodId]
		local exact = want * (if good.Bulk then 1 else scale) + (rec.Carry[goodId] or 0)
		local whole = math.floor(exact)
		local n = math.min(whole, rec.Stock[goodId] or 0)
		rec.Carry[goodId] = if n < whole then 0 else exact - whole
		if n > 0 then
			rec.Stock[goodId] -= n
			if rec.Stock[goodId] <= 0 then
				rec.Stock[goodId] = 0
			end
			local income = n * Business.priceOf(rec, goodId)
			sold[goodId] = n
			units += n
			money += income
		end
	end

	-- Gastos (luz, agua, impuestos): salen de la caja
	local upkeep = Business.upkeep(rec) * hours
	rec.Till = math.max(0, rec.Till + money - upkeep)
	rec.Sales += money
	rec.Units += units

	-- Reputación: precios justos y estanterías llenas la suben
	local target = 3
	if stocked > 0 then
		local avg = ratios / stocked
		target = 3 + (1 - avg) * 3 + math.min(stocked, 6) * 0.15 - empty * 0.4
	else
		target = 0.5
	end
	target = math.clamp(target, 0, 5)
	local speed = math.min(1, hours * 0.5)
	rec.Rep = math.clamp(rec.Rep + (target - rec.Rep) * speed, 0, 5)
	return units, money, sold
end

-- Un cliente (jugador o repostaje) paga: suma a la caja
function Business.sell(rec: Record, goodId: string, count: number): (boolean, number)
	local have = rec.Stock[goodId] or 0
	if not rec.Open or count <= 0 or have < count then
		return false, 0
	end
	local total = Business.priceOf(rec, goodId) * count
	rec.Stock[goodId] = have - count
	rec.Till += total
	rec.Sales += total
	rec.Units += count
	return true, total
end

function Business.stars(rep: number): string
	local full = math.floor(rep + 0.5)
	return string.rep("★", full) .. string.rep("☆", 5 - full)
end

return Business
