-- Farming: el campo de Villaverde. Agricultura, ganadería y el obrador donde se fabrican alimentos
-- (FarmService en el servidor, EconomyUI en el cliente, Items, Business).
--
-- CÓMO SE JUEGA
--   * En las granjas de Villaverde hay FINCAS libres. Coges una ("Quedarme esta finca") y es tuya
--     mientras juegas en ese servidor. Lo que tienes plantado y tus animales se guardan contigo: si
--     cambias de servidor, te tocará otra finca con lo mismo.
--   * Cada finca tiene 4 BANCALES y un CORRAL.
--       - Bancal vacío: "Plantar" (eliges semilla). Crece aunque no estés conectado.
--       - Regarlo una vez lo acelera (tarda un 30 % menos de lo que le quede). Si llueve, se riega solo.
--       - Cuando está listo: "Cosechar". Los árboles (manzano, naranjo, vid, olivo) vuelven a dar
--         fruto sin replantar.
--       - Corral: compras animales en la cooperativa. "Atender" les da de comer (pienso, trigo o maíz)
--         y recoge lo que dan (huevos, leche, lana, miel…) cuando está listo.
--   * COOPERATIVA (junto al granero de cada granja): semillas, árboles, animales y pienso; compra
--     todo lo del campo a precio de cooperativa. El OBRADOR, allí mismo, convierte lo que produces
--     en alimentos: harina, pan, queso, yogur, aceite, mermelada, zumos, jerséis de lana…
--   * VENDER: a la cooperativa (siempre), a los supermercados (pagan más y ponen tus productos en
--     sus estanterías: se entrega en el almacén) o en tu propia tienda (Business.luau).
--   * NIVEL DE AGRICULTOR: todo da experiencia; con más nivel se desbloquean cultivos, animales,
--     recetas y más sitio en el corral.
--
-- Todo lo que sale del campo es un objeto de la mochila con id "Agro_<Id>" (Farming.Products).

local Farming = {}

Farming.MaxLevel = 40
Farming.Plots = 4 -- bancales por finca
Farming.PlotsPerFinca = 5 -- filas de cultivo de la granja que ocupa una finca (4 bancales + corral)
Farming.WaterFactor = 0.7 -- al regar, lo que le queda de crecer se queda en un 70 %
Farming.CoopShare = 1 -- la cooperativa paga el precio base
Farming.SuperShare = 1.3 -- el supermercado paga un 30 % más
Farming.MinStage = "Nino" -- los bebés no trabajan el campo

---------------------------------------------------------------------
-- Nivel
---------------------------------------------------------------------
function Farming.xpFor(level: number): number
	return math.floor(8 * (math.max(level, 1) - 1) ^ 1.7)
end

function Farming.levelFor(xp: number): number
	local level = 1
	while level < Farming.MaxLevel and xp >= Farming.xpFor(level + 1) do
		level += 1
	end
	return level
end

-- Sitio en el corral según el nivel
function Farming.corralSize(level: number): number
	return math.min(10, 4 + level // 3)
end

---------------------------------------------------------------------
-- Productos (todo lo que sale del campo y del obrador)
---------------------------------------------------------------------
export type Product = {
	Id: string, -- objeto de la mochila: "Agro_" .. clave
	Key: string,
	Name: string,
	Icon: string,
	Price: number, -- lo que paga la cooperativa por cada uno
	Category: string, -- Business.Categories: qué negocios lo pueden vender
	Hunger: number?,
	Energy: number?,
	Grocery: string?, -- producto del supermercado que repone (Groceries)
	Desc: string,
}

Farming.Products = {} :: { [string]: Product }
Farming.ProductOrder = {} :: { string }

local function product(key: string, name: string, icon: string, price: number, category: string, hunger: number?, energy: number?, grocery: string?, desc: string)
	local id = "Agro_" .. key
	Farming.Products[id] = {
		Id = id,
		Key = key,
		Name = name,
		Icon = icon,
		Price = price,
		Category = category,
		Hunger = hunger,
		Energy = energy,
		Grocery = grocery,
		Desc = desc,
	}
	table.insert(Farming.ProductOrder, id)
end

-- Cosechas
product("Trigo", "Trigo", "🌾", 2, "Despensa", nil, nil, nil, "Recién segado. En el molino se hace harina; también es pienso.")
product("Lechuga", "Lechuga", "🥬", 4, "Verdura", 8, 0, "Lechuga", "Fresca de tu huerta.")
product("Zanahoria", "Zanahoria", "🥕", 2, "Verdura", 8, 0, "Zanahoria", "Crujiente y dulce.")
product("Tomate", "Tomate", "🍅", 3, "Verdura", 8, 0, "Tomate", "Tomate de huerta, del que sabe a tomate.")
product("Patata", "Patata", "🥔", 2, "Verdura", 10, 0, "Patatas", "Para freír, cocer o hacer tortilla.")
product("Maiz", "Mazorca de maíz", "🌽", 4, "Verdura", 10, 2, nil, "Dulce. También es pienso y hace palomitas.")
product("Pimiento", "Pimiento", "🌶️", 4, "Verdura", 6, 0, nil, "Verde y brillante.")
product("Fresa", "Fresas", "🍓", 5, "Fruta", 8, 2, nil, "Rojas y dulces. En el obrador se hace mermelada.")
product("Calabaza", "Calabaza", "🎃", 14, "Verdura", 20, 0, nil, "Enorme. Para cremas y tartas.")
product("Girasol", "Pipas de girasol", "🌻", 5, "Despensa", 6, 2, nil, "En la almazara se hace aceite de girasol.")
product("Sandia", "Sandía", "🍉", 18, "Fruta", 25, 0, "Sandia", "Para el verano.")
product("Manzana", "Manzana", "🍎", 3, "Fruta", 12, 0, "Manzana", "De tu manzano.")
product("Naranja", "Naranja", "🍊", 3, "Fruta", 12, 2, "Naranja", "De tu naranjo. Se exprime en el obrador.")
product("Uvas", "Uvas", "🍇", 5, "Fruta", 12, 0, "Uvas", "De tu viña.")
product("Aceitunas", "Aceitunas", "🍈", 4, "Despensa", 4, 0, nil, "En la almazara se hace aceite de oliva.")
-- Animales
product("Huevos", "Huevos", "🥚", 2, "Lacteo", 10, 0, "Huevos", "De tus gallinas.")
product("Leche", "Leche fresca", "🥛", 3, "Lacteo", 8, 4, "Leche", "De tus vacas. En la quesería se hace queso, yogur y mantequilla.")
product("Lana", "Lana", "🧶", 6, "Textil", nil, nil, nil, "De tus ovejas. En el telar se hacen jerséis y bufandas.")
product("LecheCabra", "Leche de cabra", "🥛", 4, "Lacteo", 8, 4, nil, "De tus cabras. Hace un queso buenísimo.")
product("Miel", "Tarro de miel", "🍯", 8, "Despensa", 10, 6, nil, "De tus colmenas.")
product("Trufa", "Trufa negra", "🍄", 40, "Despensa", 6, 0, nil, "Tus cerdos la encuentran bajo las encinas. Carísima.")
-- Obrador
product("Harina", "Saco de harina", "🌾", 8, "Despensa", nil, nil, nil, "Del molino. Para pan, magdalenas, pizza…")
product("Pan", "Pan de pueblo", "🥖", 6, "Panaderia", 20, 0, "Barra", "Recién salido del horno.")
product("Magdalenas", "Magdalenas caseras", "🧁", 8, "Panaderia", 16, 5, "Magdalenas", "Esponjosas, con huevo y mantequilla.")
product("TartaManzana", "Tarta de manzana", "🥧", 22, "Panaderia", 35, 5, nil, "Como la de la abuela.")
product("Queso", "Queso de vaca", "🧀", 12, "Lacteo", 18, 0, "Queso", "Curado en la quesería de la cooperativa.")
product("QuesoCabra", "Queso de cabra", "🧀", 16, "Lacteo", 18, 0, nil, "Suave y cremoso.")
product("Yogur", "Yogur natural", "🍶", 4, "Lacteo", 10, 3, "Yogur", "Hecho con tu leche.")
product("Mantequilla", "Mantequilla", "🧈", 7, "Lacteo", 10, 0, "Mantequilla", "Para untar y para hornear.")
product("Aceite", "Aceite de oliva", "🍈", 20, "Despensa", 5, 0, "Aceite", "Virgen extra, de tus olivos.")
product("AceiteGirasol", "Aceite de girasol", "🌻", 17, "Despensa", 5, 0, nil, "Para freír.")
product("Mermelada", "Mermelada de fresa", "🍓", 24, "Despensa", 8, 3, "Mermelada", "Casera, con tus fresas y tu miel.")
product("TomateFrito", "Tomate frito casero", "🥫", 14, "Despensa", 6, 0, "Tomatico", "Para la pizza y los macarrones.")
product("Palomitas", "Palomitas", "🍿", 5, "Despensa", 8, 2, nil, "Del maíz de tu finca.")
product("ZumoNaranja", "Zumo de naranja natural", "🧃", 11, "Bebida", 6, 8, "Zumo", "Recién exprimido.")
product("Mosto", "Mosto de uva", "🍇", 16, "Bebida", 6, 8, nil, "Zumo de tus uvas.")
product("Jersey", "Jersey de lana", "🧥", 24, "Textil", nil, nil, nil, "Tejido con la lana de tus ovejas.")
product("Bufanda", "Bufanda de lana", "🧣", 9, "Textil", nil, nil, nil, "Calentita.")
-- Cocina (restaurantes y cafeterías)
product("Ensalada", "Ensalada de la huerta", "🥗", 14, "Plato", 30, 2, nil, "Lechuga, tomate y aceite de la casa.")
product("Tortilla", "Tortilla de patatas", "🍳", 14, "Plato", 45, 4, nil, "Con cebolla o sin cebolla: con tus huevos.")
product("Pizza", "Pizza casera", "🍕", 22, "Plato", 50, 4, nil, "Masa, tomate frito y queso.")
product("Gazpacho", "Gazpacho", "🍅", 12, "Plato", 25, 6, nil, "Fresquito.")
product("CremaCalabaza", "Crema de calabaza", "🥣", 11, "Plato", 35, 4, nil, "Suave y calentita.")
product("PatatasFritas", "Patatas fritas caseras", "🍟", 8, "Plato", 25, 2, nil, "Crujientes.")
product("TartaQueso", "Tarta de queso", "🍰", 18, "Plato", 30, 6, nil, "La especialidad de la casa.")
product("Tostada", "Tostada con tomate", "🍞", 9, "Plato", 25, 3, nil, "Pan, tomate y aceite.")
product("CafeLeche", "Café con leche", "☕", 4, "Bebida", 4, 20, nil, "Con leche de la granja.")

Farming.Feed = "Agro_Pienso" -- el pienso no se vende: es de la cooperativa
Farming.FeedPrice = 2
Farming.FeedAlso = { "Agro_Maiz", "Agro_Trigo" } -- también se les puede dar grano de tu finca

---------------------------------------------------------------------
-- Cultivos
---------------------------------------------------------------------
export type Crop = {
	Id: string,
	Name: string,
	Icon: string,
	Level: number,
	Seed: number, -- precio de la semilla (o del arbolito)
	Grow: number, -- segundos hasta la primera cosecha
	Regrow: number?, -- árboles: segundos hasta volver a dar fruto
	Yield: { number }, -- mínimo y máximo que da
	Product: string, -- objeto que da
	Color: Color3, -- color de la planta madura
	Tree: boolean?,
}

local rgb = Color3.fromRGB
local function crop(id: string, name: string, icon: string, level: number, seed: number, grow: number, yield: { number }, productKey: string, color: Color3, regrow: number?): Crop
	return {
		Id = id,
		Name = name,
		Icon = icon,
		Level = level,
		Seed = seed,
		Grow = grow,
		Regrow = regrow,
		Yield = yield,
		Product = "Agro_" .. productKey,
		Color = color,
		Tree = regrow ~= nil,
	}
end

Farming.Crops = {
	crop("Trigo", "Trigo", "🌾", 1, 3, 180, { 6, 9 }, "Trigo", rgb(222, 190, 90)),
	crop("Lechuga", "Lechuga", "🥬", 1, 3, 150, { 3, 5 }, "Lechuga", rgb(120, 200, 80)),
	crop("Zanahoria", "Zanahoria", "🥕", 1, 2, 200, { 5, 8 }, "Zanahoria", rgb(240, 130, 40)),
	crop("Tomate", "Tomatera", "🍅", 2, 4, 240, { 6, 10 }, "Tomate", rgb(220, 50, 40)),
	crop("Patata", "Patatas", "🥔", 3, 4, 300, { 8, 12 }, "Patata", rgb(110, 150, 70)),
	crop("Maiz", "Maíz", "🌽", 4, 5, 300, { 5, 8 }, "Maiz", rgb(240, 210, 70)),
	crop("Pimiento", "Pimientos", "🌶️", 5, 5, 270, { 5, 8 }, "Pimiento", rgb(60, 160, 60)),
	crop("Fresa", "Fresas", "🍓", 6, 8, 360, { 6, 10 }, "Fresa", rgb(230, 40, 70)),
	crop("Manzano", "Manzano", "🍎", 7, 60, 600, { 6, 9 }, "Manzana", rgb(200, 40, 40), 300),
	crop("Calabaza", "Calabazas", "🎃", 8, 10, 480, { 2, 4 }, "Calabaza", rgb(240, 140, 30)),
	crop("Girasol", "Girasoles", "🌻", 9, 6, 420, { 4, 6 }, "Girasol", rgb(250, 210, 40)),
	crop("Sandia", "Sandías", "🍉", 10, 12, 540, { 2, 3 }, "Sandia", rgb(60, 140, 60)),
	crop("Naranjo", "Naranjo", "🍊", 11, 70, 600, { 6, 9 }, "Naranja", rgb(245, 150, 30), 300),
	crop("Vid", "Viña", "🍇", 12, 80, 720, { 5, 8 }, "Uvas", rgb(120, 50, 140), 360),
	crop("Olivo", "Olivo", "🍈", 14, 120, 900, { 8, 12 }, "Aceitunas", rgb(110, 130, 50), 420),
} :: { Crop }

Farming.cropById = {} :: { [string]: Crop }
for _, c in Farming.Crops do
	Farming.cropById[c.Id] = c
end

-- Semillas (objetos de la mochila): "Semilla_<cultivo>"
function Farming.seedItem(cropId: string): string
	return "Semilla_" .. cropId
end
function Farming.cropOfSeed(itemId: string): Crop?
	local id = itemId:match("^Semilla_(.+)$")
	return if id then Farming.cropById[id] else nil
end

---------------------------------------------------------------------
-- Animales
---------------------------------------------------------------------
export type Animal = {
	Id: string,
	Name: string,
	Icon: string,
	Level: number,
	Price: number,
	Period: number, -- segundos desde que come hasta que da su producto
	Product: string,
	Yield: number,
	Color: Color3,
	Size: Vector3,
}

Farming.Animals = {
	{ Id = "Gallina", Name = "Gallina", Icon = "🐔", Level = 1, Price = 60, Period = 150, Product = "Agro_Huevos", Yield = 2, Color = rgb(245, 240, 230), Size = Vector3.new(1.2, 1.2, 1.4) },
	{ Id = "Vaca", Name = "Vaca", Icon = "🐄", Level = 3, Price = 400, Period = 240, Product = "Agro_Leche", Yield = 3, Color = rgb(250, 250, 250), Size = Vector3.new(2.4, 2.6, 4.6) },
	{ Id = "Oveja", Name = "Oveja", Icon = "🐑", Level = 5, Price = 250, Period = 300, Product = "Agro_Lana", Yield = 2, Color = rgb(235, 232, 220), Size = Vector3.new(1.8, 1.8, 2.8) },
	{ Id = "Cabra", Name = "Cabra", Icon = "🐐", Level = 7, Price = 300, Period = 240, Product = "Agro_LecheCabra", Yield = 2, Color = rgb(180, 150, 110), Size = Vector3.new(1.6, 1.9, 2.6) },
	{ Id = "Colmena", Name = "Colmena", Icon = "🐝", Level = 9, Price = 350, Period = 360, Product = "Agro_Miel", Yield = 2, Color = rgb(230, 180, 40), Size = Vector3.new(1.8, 2.2, 1.8) },
	{ Id = "Cerdo", Name = "Cerdo trufero", Icon = "🐖", Level = 11, Price = 500, Period = 420, Product = "Agro_Trufa", Yield = 1, Color = rgb(240, 170, 170), Size = Vector3.new(1.8, 1.8, 3) },
} :: { Animal }

Farming.animalById = {} :: { [string]: Animal }
for _, a in Farming.Animals do
	Farming.animalById[a.Id] = a
end

---------------------------------------------------------------------
-- Obrador (cooperativa) y cocina (restaurantes y cafeterías)
---------------------------------------------------------------------
export type Recipe = {
	Id: string,
	Station: string,
	Inputs: { [string]: number },
	Output: string,
	Count: number,
	Level: number,
}

Farming.Stations = {
	Molino = { Name = "Molino", Icon = "⚙️" },
	Horno = { Name = "Horno", Icon = "🔥" },
	Queseria = { Name = "Quesería", Icon = "🧀" },
	Almazara = { Name = "Almazara", Icon = "🍈" },
	Conservas = { Name = "Conservas", Icon = "🥫" },
	Exprimidor = { Name = "Exprimidor", Icon = "🧃" },
	Telar = { Name = "Telar", Icon = "🧵" },
	Cocina = { Name = "Cocina", Icon = "🍳" },
}
Farming.StationOrder = { "Molino", "Horno", "Queseria", "Almazara", "Conservas", "Exprimidor", "Telar", "Cocina" }
Farming.Obrador = { "Molino", "Horno", "Queseria", "Almazara", "Conservas", "Exprimidor", "Telar" } -- en la cooperativa

local function recipe(station: string, output: string, count: number, level: number, inputs: { [string]: number }): Recipe
	local full = {}
	for key, n in inputs do
		full[if Farming.Products["Agro_" .. key] then "Agro_" .. key else key] = n -- (CafeMolido es del supermercado)
	end
	return { Id = output, Station = station, Inputs = full, Output = "Agro_" .. output, Count = count, Level = level }
end

Farming.Recipes = {
	recipe("Molino", "Harina", 1, 1, { Trigo = 3 }),
	recipe("Horno", "Pan", 2, 2, { Harina = 1 }),
	recipe("Horno", "Magdalenas", 3, 4, { Harina = 1, Huevos = 2, Mantequilla = 1 }),
	recipe("Horno", "TartaManzana", 1, 8, { Harina = 1, Manzana = 3, Huevos = 1 }),
	recipe("Queseria", "Yogur", 2, 3, { Leche = 2 }),
	recipe("Queseria", "Mantequilla", 1, 3, { Leche = 2 }),
	recipe("Queseria", "Queso", 1, 4, { Leche = 3 }),
	recipe("Queseria", "QuesoCabra", 1, 7, { LecheCabra = 3 }),
	recipe("Almazara", "AceiteGirasol", 1, 9, { Girasol = 3 }),
	recipe("Almazara", "Aceite", 1, 14, { Aceitunas = 4 }),
	recipe("Conservas", "TomateFrito", 1, 2, { Tomate = 4 }),
	recipe("Conservas", "Palomitas", 2, 4, { Maiz = 2 }),
	recipe("Conservas", "Mermelada", 1, 9, { Fresa = 3, Miel = 1 }),
	recipe("Exprimidor", "ZumoNaranja", 1, 11, { Naranja = 3 }),
	recipe("Exprimidor", "Mosto", 1, 12, { Uvas = 3 }),
	recipe("Telar", "Bufanda", 1, 5, { Lana = 1 }),
	recipe("Telar", "Jersey", 1, 6, { Lana = 3 }),
	-- Cocina: en tu restaurante o tu cafetería
	recipe("Cocina", "Ensalada", 3, 1, { Lechuga = 1, Tomate = 2, AceiteGirasol = 1 }),
	recipe("Cocina", "Tortilla", 3, 1, { Patata = 3, Huevos = 3, AceiteGirasol = 1 }),
	recipe("Cocina", "PatatasFritas", 4, 1, { Patata = 3, AceiteGirasol = 1 }),
	recipe("Cocina", "Pizza", 2, 1, { Harina = 1, TomateFrito = 1, Queso = 1 }),
	recipe("Cocina", "Gazpacho", 3, 1, { Tomate = 3, Pimiento = 1, Aceite = 1 }),
	recipe("Cocina", "CremaCalabaza", 3, 1, { Calabaza = 1, Leche = 1 }),
	recipe("Cocina", "TartaQueso", 2, 1, { Queso = 1, Huevos = 2, Harina = 1 }),
	recipe("Cocina", "Tostada", 3, 1, { Pan = 1, TomateFrito = 1 }),
	recipe("Cocina", "CafeLeche", 4, 1, { CafeMolido = 1, Leche = 1 }),
} :: { Recipe }

Farming.recipeById = {} :: { [string]: Recipe }
for _, r in Farming.Recipes do
	Farming.recipeById[r.Id] = r
end

-- Cuántas veces se puede hacer una receta con lo que tienes (have(id) -> cuántos tienes)
function Farming.canMake(r: Recipe, have: (string) -> number): number
	local times = math.huge
	for id, n in r.Inputs do
		times = math.min(times, have(id) // n)
	end
	return if times == math.huge then 0 else times
end

---------------------------------------------------------------------
-- Bancales y animales (estado guardado y cálculos de tiempo)
---------------------------------------------------------------------
-- Bancal guardado: { Crop = "Tomate", ReadyAt = os.time(), Watered = true?, Planted = os.time() }
-- Animal guardado: { Kind = "Vaca", ReadyAt = os.time()? }  (sin ReadyAt = tiene hambre)

export type PlotState = { Crop: string, Planted: number, ReadyAt: number, Watered: boolean?, Harvests: number? }
export type AnimalState = { Kind: string, ReadyAt: number? }

-- Fase del bancal: "Empty" | "Growing" | "Ready"
function Farming.plotPhase(plot: PlotState?, now: number): string
	if not plot or not Farming.cropById[plot.Crop] then
		return "Empty"
	end
	return if now >= plot.ReadyAt then "Ready" else "Growing"
end

-- 0..1: lo que ha crecido
function Farming.growth(plot: PlotState?, now: number): number
	if not plot or not Farming.cropById[plot.Crop] then
		return 0
	end
	local total = math.max(1, plot.ReadyAt - plot.Planted)
	return math.clamp((now - plot.Planted) / total, 0, 1)
end

function Farming.plant(cropId: string, now: number): PlotState
	local c = Farming.cropById[cropId]
	return { Crop = cropId, Planted = now, ReadyAt = now + c.Grow }
end

-- Regar: lo que le queda de crecer baja al 70 % (una vez por cosecha)
function Farming.water(plot: PlotState, now: number): boolean
	if plot.Watered or now >= plot.ReadyAt then
		return false
	end
	plot.Watered = true
	local left = plot.ReadyAt - now
	plot.ReadyAt = now + math.ceil(left * Farming.WaterFactor)
	return true
end

-- Cosechar: cuánto da (con un número al azar 0..1) y qué queda en el bancal (nil = vacío)
function Farming.harvest(plot: PlotState, now: number, roll: number): (number, PlotState?)
	local c = Farming.cropById[plot.Crop]
	local amount = c.Yield[1] + math.floor(roll * (c.Yield[2] - c.Yield[1] + 1))
	amount = math.clamp(amount, c.Yield[1], c.Yield[2])
	if plot.Watered then
		amount += 1 -- regado da un poco más
	end
	if c.Regrow then
		return amount, { Crop = c.Id, Planted = now, ReadyAt = now + c.Regrow, Harvests = (plot.Harvests or 0) + 1 }
	end
	return amount, nil
end

-- Experiencia por cosecha, por animal atendido y por receta
function Farming.harvestXp(c: Crop, amount: number): number
	return 2 + c.Level + amount // 2
end
function Farming.animalXp(a: Animal): number
	return 2 + a.Level
end
function Farming.recipeXp(r: Recipe, times: number): number
	return (1 + r.Level // 2) * times
end

-- Precio de venta de un producto: "Coop" (cooperativa) o "Super" (supermercado)
function Farming.sellPrice(id: string, where: string): number
	local p = Farming.Products[id]
	if not p then
		return 0
	end
	local share = if where == "Super" then Farming.SuperShare else Farming.CoopShare
	return math.max(1, math.floor(p.Price * share + 0.5))
end

-- Lo que falta para algo que pide nivel ("" = nada)
function Farming.lockedText(level: number, need: number): string
	return if level >= need then "" else ("🔒 Nivel %d"):format(need)
end

return Farming
