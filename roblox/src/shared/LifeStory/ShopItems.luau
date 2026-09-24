-- ShopItems: lo que se puede comprar en las tiendas del mapa (tag Shop, atributo ShopId).
-- Lo usan los recados de la historia ("compra el material del colegio", "las medicinas de casa").
-- Hunger/Energy: lo que llena si se come en el momento.

export type Item = { Id: string, NameKey: string, Price: number, Hunger: number?, Energy: number? }

local ShopItems: { [string]: Item } = {
	Libreria = { Id = "MaterialEscolar", NameKey = "ITEM.MATERIAL_ESCOLAR", Price = 12 },
	Farmacia = { Id = "Medicinas", NameKey = "ITEM.MEDICINAS", Price = 10 },
	Heladeria = { Id = "Helado", NameKey = "ITEM.HELADO", Price = 4, Hunger = 10, Energy = 5 },
	Panaderia = { Id = "Pan", NameKey = "ITEM.PAN", Price = 3, Hunger = 15 },
	Fruteria = { Id = "Fruta", NameKey = "ITEM.FRUTA", Price = 3, Hunger = 15 },
	Floristeria = { Id = "Flores", NameKey = "ITEM.FLORES", Price = 8 },
}

return ShopItems
