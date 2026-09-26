-- CafeMenu: la carta de las cafeterías y cómo se prepara cada cosa (oficio de barista).
--
-- Cada producto tiene sus pasos (Steps): el barista va de puesto en puesto y los hace en orden.
-- Los puestos (Stations) son piezas del mapa con la etiqueta CafeStation y el atributo Station.

local CafeMenu = {}

export type Product = {
	Id: string,
	Name: string,
	Icon: string,
	Price: number,
	Hunger: number,
	Energy: number,
	Steps: { string },
	Color: Color3, -- color de lo que se ve en la taza o el plato
	Plate: boolean?, -- va en plato (bollería) en vez de en taza
}

CafeMenu.Stations = {
	Cup = { Name = "Coger taza", Object = "Tazas", Icon = "☕", Hold = 0.3 },
	Grind = { Name = "Moler café", Object = "Molinillo", Icon = "⚙️", Hold = 1.2 },
	Brew = { Name = "Sacar el espresso", Object = "Cafetera", Icon = "☕", Hold = 1.8 },
	Milk = { Name = "Echar leche", Object = "Nevera de la leche", Icon = "🥛", Hold = 0.8 },
	Foam = { Name = "Espumar la leche", Object = "Vaporizador", Icon = "💨", Hold = 1.6 },
	Chocolate = { Name = "Servir chocolate", Object = "Olla de chocolate", Icon = "🍫", Hold = 1.2 },
	Juice = { Name = "Exprimir naranjas", Object = "Exprimidor", Icon = "🍊", Hold = 1.8 },
	Tea = { Name = "Echar agua caliente", Object = "Hervidor", Icon = "🫖", Hold = 1 },
	Pastry = { Name = "Coger del mostrador", Object = "Vitrina de bollería", Icon = "🥐", Hold = 0.5 },
}

local rgb = Color3.fromRGB
CafeMenu.List = {
	{ Id = "Espresso", Name = "Café solo", Icon = "☕", Price = 2, Hunger = 2, Energy = 22, Steps = { "Cup", "Grind", "Brew" }, Color = rgb(60, 36, 22) },
	{ Id = "Cortado", Name = "Cortado", Icon = "☕", Price = 2, Hunger = 4, Energy = 20, Steps = { "Cup", "Grind", "Brew", "Milk" }, Color = rgb(150, 100, 60) },
	{ Id = "ConLeche", Name = "Café con leche", Icon = "☕", Price = 3, Hunger = 6, Energy = 18, Steps = { "Cup", "Grind", "Brew", "Milk", "Foam" }, Color = rgb(196, 150, 104) },
	{ Id = "Capuchino", Name = "Capuchino", Icon = "☕", Price = 3, Hunger = 6, Energy = 18, Steps = { "Cup", "Grind", "Brew", "Foam" }, Color = rgb(226, 204, 170) },
	{ Id = "Chocolate", Name = "Chocolate caliente", Icon = "🍫", Price = 3, Hunger = 14, Energy = 8, Steps = { "Cup", "Chocolate" }, Color = rgb(90, 50, 30) },
	{ Id = "Te", Name = "Té", Icon = "🫖", Price = 2, Hunger = 2, Energy = 10, Steps = { "Cup", "Tea" }, Color = rgb(170, 110, 50) },
	{ Id = "Zumo", Name = "Zumo de naranja", Icon = "🍊", Price = 3, Hunger = 8, Energy = 6, Steps = { "Cup", "Juice" }, Color = rgb(250, 160, 30) },
	{ Id = "Croissant", Name = "Croissant", Icon = "🥐", Price = 2, Hunger = 22, Energy = 2, Steps = { "Pastry" }, Color = rgb(222, 170, 90), Plate = true },
	{ Id = "Magdalena", Name = "Magdalena", Icon = "🧁", Price = 2, Hunger = 16, Energy = 2, Steps = { "Pastry" }, Color = rgb(230, 180, 90), Plate = true },
	{ Id = "Tarta", Name = "Trozo de tarta", Icon = "🍰", Price = 4, Hunger = 28, Energy = 4, Steps = { "Pastry" }, Color = rgb(250, 230, 220), Plate = true },
	{ Id = "Tostada", Name = "Tostada con tomate", Icon = "🍞", Price = 3, Hunger = 30, Energy = 2, Steps = { "Pastry" }, Color = rgb(210, 90, 60), Plate = true },
} :: { Product }

CafeMenu.byId = {} :: { [string]: Product }
for _, product in CafeMenu.List do
	CafeMenu.byId[product.Id] = product
end

-- Cada producto se guarda en la mochila como "Cafe_<Id>" (Items.luau)
function CafeMenu.itemId(productId: string): string
	return "Cafe_" .. productId
end

-- Sueldo del barista y paciencia de los clientes
CafeMenu.Job = {
	Name = "Barista",
	Icon = "☕",
	PerOrder = 10, -- por cada pedido entregado
	PerStep = 2, -- y un poco más por cada paso (los pedidos largos pagan más)
	TipFast = 5, -- propina si se entrega rápido
	FastSeconds = 45,
	EnergyCost = 2,
	Text = "Atiende la barra: prepara los pedidos paso a paso y entrégalos en la recogida.",
}
CafeMenu.Patience = 150 -- segundos que espera un cliente NPC antes de irse enfadado
CafeMenu.MaxNpc = 4 -- clientes NPC a la vez en cada cafetería
CafeMenu.NpcBaristaSeconds = 4 -- lo que tarda el barista NPC por paso

return CafeMenu
