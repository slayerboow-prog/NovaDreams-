-- Fishing: peces, cañas, cebo y oficio de pescador (FishingService, FishingUI, SupermarketService).
--
-- Se pesca en cualquier orilla con agua delante ("Pescar aquí") y en los sitios de pesca
-- (tag FishingSpot): el muelle del puerto, los pantalanes de los lagos y del río, y el barco de pesca. Cada sitio tiene su agua (Water) y en cada agua
-- pican unos peces. Lo que pescas va a la mochila y se vende en la pescadería del supermercado:
-- así el supermercado tiene pescado para vender (si nadie pesca, no hay pescado).

local Fishing = {}

export type Species = {
	Id: string, -- id del pez
	Item: string, -- objeto de la mochila
	Name: string,
	Icon: string,
	Waters: { [string]: number }, -- peso (probabilidad) en cada agua
	Rare: boolean?,
	Price: number, -- lo que paga el supermercado por cada uno
	Product: string, -- producto del supermercado que repone (Groceries)
	Kg: { number }, -- peso mínimo y máximo (solo para contarlo bonito)
}

Fishing.Waters = {
	Mar = "el mar",
	AltaMar = "alta mar",
	Rio = "el río",
	Lago = "el lago",
}

Fishing.Species = {
	{ Id = "Sardina", Item = "Pez_Sardina", Name = "Sardina", Icon = "🐟", Waters = { Mar = 30, AltaMar = 20 }, Price = 3, Product = "Sardinas", Kg = { 0.05, 0.15 } },
	{ Id = "Dorada", Item = "Pez_Dorada", Name = "Dorada", Icon = "🐠", Waters = { Mar = 22, AltaMar = 8 }, Price = 6, Product = "Dorada", Kg = { 0.3, 1.2 } },
	{ Id = "Lubina", Item = "Pez_Lubina", Name = "Lubina", Icon = "🐟", Waters = { Mar = 16, AltaMar = 12 }, Price = 7, Product = "Lubina", Kg = { 0.4, 2 } },
	{ Id = "Merluza", Item = "Pez_Merluza", Name = "Merluza", Icon = "🐟", Waters = { AltaMar = 22 }, Price = 8, Product = "Merluza", Kg = { 0.8, 3 } },
	{ Id = "Gamba", Item = "Pez_Gamba", Name = "Gambas", Icon = "🦐", Waters = { AltaMar = 16 }, Price = 5, Product = "Gambas", Kg = { 0.2, 0.5 } },
	{ Id = "Pulpo", Item = "Pez_Pulpo", Name = "Pulpo", Icon = "🐙", Waters = { Mar = 4, AltaMar = 7 }, Rare = true, Price = 10, Product = "Pulpo", Kg = { 1, 4 } },
	{ Id = "Atun", Item = "Pez_Atun", Name = "Atún", Icon = "🐟", Waters = { AltaMar = 5 }, Rare = true, Price = 15, Product = "Atun", Kg = { 8, 40 } },
	{ Id = "Trucha", Item = "Pez_Trucha", Name = "Trucha", Icon = "🐟", Waters = { Rio = 45, Lago = 55 }, Price = 5, Product = "Trucha", Kg = { 0.3, 1.5 } },
	{ Id = "Salmon", Item = "Pez_Salmon", Name = "Salmón", Icon = "🐟", Waters = { Rio = 10, Lago = 4 }, Rare = true, Price = 12, Product = "Salmon", Kg = { 2, 6 } },
} :: { Species }

Fishing.byId = {} :: { [string]: Species }
Fishing.byItem = {} :: { [string]: Species }
for _, s in Fishing.Species do
	Fishing.byId[s.Id] = s
	Fishing.byItem[s.Item] = s
end

-- A veces sale algo que no es un pez (en cualquier agua)
Fishing.Junk = {
	{ Name = "una bota vieja", Icon = "🥾" },
	{ Name = "una lata oxidada", Icon = "🥫" },
	{ Name = "un montón de algas", Icon = "🌿" },
}
Fishing.JunkWeight = 6

-- Cañas y cebo (se compran en la tienda de pesca del centro)
Fishing.Rods = {
	CanaPescar = { Id = "CanaPescar", Name = "Caña de pescar", Icon = "🎣", Price = 25, Bite = 1, Rare = 1, Desc = "Para pescar en cualquier agua: mar, río, lagos, el puerto…" },
	CanaPro = { Id = "CanaPro", Name = "Caña profesional", Icon = "🎣", Price = 120, Bite = 0.7, Rare = 1.8, Desc = "Pican antes y salen más peces raros." },
}
Fishing.RodOrder = { "CanaPro", "CanaPescar" } -- se usa la mejor que tengas
Fishing.Bait = { Id = "Cebo", Name = "Cebo", Icon = "🪱", Price = 4, Pack = 5, Bite = 0.6, Desc = "Un cebo por lanzamiento: pican mucho antes." }
Fishing.BoatPrice = 15 -- alquilar el barco de pesca (los pescadores de turno van gratis)

-- Tiempos (segundos)
Fishing.BiteMin, Fishing.BiteMax = 5, 14 -- lo que tardan en picar (sin cebo y con caña normal)
Fishing.Window = 1.8 -- tiempo para tirar cuando pica
Fishing.MoveCancel = 8 -- si te alejas más del sitio, se recoge el sedal

-- Oficio de pescador
Fishing.Job = {
	Name = "Pescador",
	Icon = "🎣",
	PayBonus = 1.5, -- el supermercado paga más a los pescadores de turno
	EnergyCost = 1, -- por cada venta
	CarryGoal = 6, -- con tantos peces, la guía te lleva al supermercado
}

-- Pescador NPC del puerto: si ningún jugador pesca de turno, cada cierto tiempo trae algo de pescado
Fishing.NpcDeliveryEvery = 150
Fishing.NpcDeliveryCount = 2

-- Lo que puedes pescar en un agua, con sus pesos (la caña profesional sube los raros)
function Fishing.table(water: string, rareBoost: number): { { Species: Species?, Weight: number } }
	local list = {}
	for _, s in Fishing.Species do
		local w = s.Waters[water]
		if w then
			table.insert(list, { Species = s, Weight = if s.Rare then w * rareBoost else w })
		end
	end
	table.insert(list, { Species = nil, Weight = Fishing.JunkWeight })
	return list
end

function Fishing.roll(water: string, rareBoost: number, rng: Random): Species?
	local list = Fishing.table(water, rareBoost)
	local total = 0
	for _, e in list do
		total += e.Weight
	end
	local r = rng:NextNumber() * total
	for _, e in list do
		r -= e.Weight
		if r <= 0 then
			return e.Species
		end
	end
	return list[1].Species
end

return Fishing
