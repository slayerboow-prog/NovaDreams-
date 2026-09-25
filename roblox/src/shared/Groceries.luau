-- Groceries: todo lo que se vende en los supermercados de Valmar.
--
-- Cada producto está en una sección del supermercado (frutería, lácteos, bebidas…).
-- Price en euros de juego. Hunger/Energy = lo que quita el hambre o da de energía al comerlo
-- (si no tiene, no se come: limpieza, higiene… se guarda en la mochila).
-- La charcutería vende al corte: precio por cada 100 g.

local Groceries = {}

export type Product = {
	Id: string,
	Name: string,
	Icon: string,
	Price: number,
	Section: string,
	Color: Color3,
	Hunger: number?,
	Energy: number?,
	Shape: string?, -- "Box" | "Bottle" | "Can" | "Bag" | "Round" (cómo se ve en la estantería)
}

local rgb = Color3.fromRGB

-- Secciones (orden = cómo se reparten por la tienda)
Groceries.Sections = {
	Fruta = { Name = "Frutería", Icon = "🍎", Color = rgb(220, 70, 60), Where = "Produce" },
	Verdura = { Name = "Verduras", Icon = "🥬", Color = rgb(80, 160, 70), Where = "Produce" },
	Panaderia = { Name = "Panadería", Icon = "🥖", Color = rgb(200, 150, 80), Where = "Wall" },
	Lacteos = { Name = "Lácteos y huevos", Icon = "🥛", Color = rgb(90, 150, 220), Where = "Fridge" },
	Carne = { Name = "Carne", Icon = "🥩", Color = rgb(190, 60, 60), Where = "Fridge" },
	Pescado = { Name = "Pescado", Icon = "🐟", Color = rgb(70, 140, 190), Where = "Fridge" },
	Congelados = { Name = "Congelados", Icon = "🧊", Color = rgb(140, 200, 240), Where = "Freezer" },
	Bebidas = { Name = "Bebidas", Icon = "🥤", Color = rgb(40, 110, 200), Where = "Aisle" },
	Desayuno = { Name = "Desayuno", Icon = "🥣", Color = rgb(230, 170, 60), Where = "Aisle" },
	Despensa = { Name = "Despensa", Icon = "🍝", Color = rgb(210, 120, 50), Where = "Aisle" },
	Snacks = { Name = "Dulces y snacks", Icon = "🍫", Color = rgb(170, 70, 150), Where = "Aisle" },
	Limpieza = { Name = "Limpieza", Icon = "🧽", Color = rgb(60, 170, 170), Where = "Aisle" },
	Higiene = { Name = "Higiene", Icon = "🧴", Color = rgb(150, 120, 210), Where = "Aisle" },
}
Groceries.AisleOrder = { "Bebidas", "Desayuno", "Despensa", "Snacks", "Limpieza", "Higiene" }

local function p(id: string, name: string, icon: string, price: number, section: string, color: Color3, hunger: number?, energy: number?, shape: string?): Product
	return { Id = id, Name = name, Icon = icon, Price = price, Section = section, Color = color, Hunger = hunger, Energy = energy, Shape = shape }
end

Groceries.List = {
	-- Frutería y verduras
	p("Manzana", "Manzanas", "🍎", 2, "Fruta", rgb(200, 40, 40), 12, 0, "Round"),
	p("Platano", "Plátanos", "🍌", 2, "Fruta", rgb(240, 210, 60), 14, 2, "Round"),
	p("Naranja", "Naranjas", "🍊", 2, "Fruta", rgb(245, 140, 30), 12, 2, "Round"),
	p("Uvas", "Uvas", "🍇", 3, "Fruta", rgb(120, 50, 140), 12, 0, "Round"),
	p("Sandia", "Sandía", "🍉", 5, "Fruta", rgb(60, 140, 60), 25, 0, "Round"),
	p("Tomate", "Tomates", "🍅", 2, "Verdura", rgb(220, 50, 40), 8, 0, "Round"),
	p("Lechuga", "Lechuga", "🥬", 2, "Verdura", rgb(110, 180, 80), 8, 0, "Round"),
	p("Zanahoria", "Zanahorias", "🥕", 1, "Verdura", rgb(240, 120, 30), 8, 0, "Round"),
	p("Patatas", "Patatas", "🥔", 3, "Verdura", rgb(190, 150, 90), 15, 0, "Bag"),
	-- Panadería
	p("Barra", "Barra de pan", "🥖", 1, "Panaderia", rgb(220, 170, 100), 18, 0, "Bag"),
	p("PanMolde", "Pan de molde", "🍞", 2, "Panaderia", rgb(230, 190, 130), 20, 0, "Box"),
	p("Magdalenas", "Magdalenas", "🧁", 3, "Panaderia", rgb(230, 170, 70), 15, 5, "Box"),
	p("Croissants", "Croissants", "🥐", 3, "Panaderia", rgb(215, 150, 70), 18, 3, "Bag"),
	-- Lácteos y huevos (nevera)
	p("Leche", "Leche", "🥛", 1, "Lacteos", rgb(245, 245, 250), 10, 5, "Box"),
	p("Yogur", "Yogures", "🍶", 2, "Lacteos", rgb(240, 240, 255), 10, 3, "Box"),
	p("Queso", "Queso", "🧀", 4, "Lacteos", rgb(250, 210, 80), 18, 0, "Box"),
	p("Huevos", "Huevos", "🥚", 2, "Lacteos", rgb(240, 225, 190), 18, 0, "Box"),
	p("Mantequilla", "Mantequilla", "🧈", 2, "Lacteos", rgb(250, 230, 150), 10, 0, "Box"),
	-- Carne y pescado (nevera)
	p("Pollo", "Pechuga de pollo", "🍗", 5, "Carne", rgb(240, 200, 170), 30, 0, "Box"),
	p("Filetes", "Filetes de ternera", "🥩", 7, "Carne", rgb(180, 50, 50), 35, 0, "Box"),
	p("Hamburguesas", "Hamburguesas", "🍔", 5, "Carne", rgb(150, 70, 50), 30, 0, "Box"),
	p("Salmon", "Salmón", "🐟", 8, "Pescado", rgb(245, 140, 110), 30, 5, "Box"),
	p("Gambas", "Gambas", "🦐", 7, "Pescado", rgb(240, 120, 90), 22, 0, "Box"),
	-- Congelados
	p("Pizza", "Pizza congelada", "🍕", 4, "Congelados", rgb(220, 60, 40), 40, 0, "Box"),
	p("HeladoTarrina", "Tarrina de helado", "🍨", 4, "Congelados", rgb(250, 220, 230), 15, 8, "Box"),
	p("Croquetas", "Croquetas", "🧆", 3, "Congelados", rgb(200, 140, 70), 25, 0, "Bag"),
	-- Bebidas
	p("Agua", "Agua", "💧", 1, "Bebidas", rgb(120, 190, 240), 2, 5, "Bottle"),
	p("Zumo", "Zumo de naranja", "🧃", 2, "Bebidas", rgb(250, 160, 40), 6, 8, "Box"),
	p("Refresco", "Refresco", "🥤", 2, "Bebidas", rgb(200, 30, 40), 3, 12, "Can"),
	p("Batido", "Batido de chocolate", "🍫", 2, "Bebidas", rgb(120, 70, 40), 8, 8, "Bottle"),
	p("CafeMolido", "Café molido", "☕", 4, "Bebidas", rgb(80, 50, 30), 2, 25, "Bag"),
	-- Desayuno
	p("Cereales", "Cereales", "🥣", 3, "Desayuno", rgb(240, 180, 40), 20, 5, "Box"),
	p("Galletas", "Galletas", "🍪", 2, "Desayuno", rgb(200, 140, 70), 12, 5, "Box"),
	p("Mermelada", "Mermelada", "🍓", 3, "Desayuno", rgb(190, 30, 60), 8, 3, "Bottle"),
	p("CacaoPolvo", "Cacao en polvo", "🍫", 3, "Desayuno", rgb(110, 60, 30), 5, 10, "Box"),
	-- Despensa
	p("Pasta", "Macarrones", "🍝", 1, "Despensa", rgb(240, 200, 90), 30, 0, "Bag"),
	p("Arroz", "Arroz", "🍚", 1, "Despensa", rgb(245, 245, 235), 30, 0, "Bag"),
	p("Aceite", "Aceite de oliva", "🫒", 5, "Despensa", rgb(170, 170, 40), 5, 0, "Bottle"),
	p("Atun", "Latas de atún", "🥫", 3, "Despensa", rgb(60, 120, 180), 18, 0, "Can"),
	p("Tomatico", "Tomate frito", "🥫", 1, "Despensa", rgb(200, 40, 30), 6, 0, "Can"),
	p("Legumbres", "Garbanzos", "🫘", 1, "Despensa", rgb(220, 190, 120), 25, 0, "Bottle"),
	-- Dulces y snacks
	p("Chocolate", "Tableta de chocolate", "🍫", 2, "Snacks", rgb(90, 50, 30), 10, 10, "Box"),
	p("Patatillas", "Patatas fritas", "🥔", 2, "Snacks", rgb(240, 200, 50), 10, 3, "Bag"),
	p("Gominolas", "Gominolas", "🍬", 1, "Snacks", rgb(240, 90, 160), 5, 8, "Bag"),
	p("FrutosSecos", "Frutos secos", "🥜", 3, "Snacks", rgb(180, 130, 80), 14, 6, "Bag"),
	-- Limpieza e higiene (no se comen)
	p("Detergente", "Detergente", "🧺", 5, "Limpieza", rgb(40, 120, 220), nil, nil, "Bottle"),
	p("Lavavajillas", "Lavavajillas", "🧽", 2, "Limpieza", rgb(80, 200, 120), nil, nil, "Bottle"),
	p("Lejia", "Lejía", "🧴", 1, "Limpieza", rgb(230, 230, 240), nil, nil, "Bottle"),
	p("PapelHigienico", "Papel higiénico", "🧻", 3, "Higiene", rgb(245, 245, 245), nil, nil, "Bag"),
	p("Champu", "Champú", "🧴", 3, "Higiene", rgb(200, 120, 220), nil, nil, "Bottle"),
	p("PastaDientes", "Pasta de dientes", "🪥", 2, "Higiene", rgb(80, 160, 230), nil, nil, "Box"),
	p("Gel", "Gel de ducha", "🛁", 3, "Higiene", rgb(90, 200, 200), nil, nil, "Bottle"),
}

-- Charcutería / carnicería (se pide al corte: gramos)
Groceries.Deli = {
	{ Id = "JamonSerrano", Name = "Jamón serrano", Icon = "🍖", Per100 = 3, Hunger = 8 },
	{ Id = "QuesoCurado", Name = "Queso curado", Icon = "🧀", Per100 = 2, Hunger = 7 },
	{ Id = "Pavo", Name = "Pechuga de pavo", Icon = "🦃", Per100 = 1, Hunger = 6 },
	{ Id = "Chorizo", Name = "Chorizo", Icon = "🌭", Per100 = 2, Hunger = 7 },
	{ Id = "PolloAsado", Name = "Pollo asado", Icon = "🍗", Per100 = 1, Hunger = 9 },
}
Groceries.DeliGrams = { 100, 150, 200, 250, 300 }

Groceries.byId = {} :: { [string]: Product }
Groceries.bySection = {} :: { [string]: { Product } }
for _, product in Groceries.List do
	Groceries.byId[product.Id] = product
	Groceries.bySection[product.Section] = Groceries.bySection[product.Section] or {}
	table.insert(Groceries.bySection[product.Section], product)
end
Groceries.deliById = {}
for _, d in Groceries.Deli do
	Groceries.deliById[d.Id] = d
end

-- Precio de una compra al corte (redondeado hacia arriba, mínimo 1)
function Groceries.deliPrice(id: string, grams: number): number
	local d = Groceries.deliById[id]
	if not d then
		return 0
	end
	return math.max(1, math.ceil(d.Per100 * grams / 100))
end

-- Supermercado: cuánto se tarda en reponer una sección vacía si no hay reponedor (segundos)
Groceries.StockMax = 12
Groceries.NpcRestockEvery = 45

-- Sueldos de los oficios del supermercado
Groceries.Jobs = {
	Cajero = { Name = "Cajero/a", Icon = "🧾", PerItem = 1, PerCustomer = 6, Text = "Cobra a los clientes en tu caja: pasa los productos y da bien el cambio." },
	Charcutero = { Name = "Charcutero/a", Icon = "🔪", PerOrder = 8, Text = "Atiende el mostrador: corta y pesa lo que te piden." },
	Reponedor = { Name = "Reponedor/a", Icon = "📦", Text = "Coge cajas del almacén y rellena los huecos de las estanterías." },
}

return Groceries
