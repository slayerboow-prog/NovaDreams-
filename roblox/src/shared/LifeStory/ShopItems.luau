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
	-- La compra para la nevera del piso o de la residencia (la universidad: comer ya depende de ti)
	Supermercado = { Id = "BolsaCompra", NameKey = "Bolsa de la compra", Price = 15, Hunger = 35, Energy = 5 },
	-- Bastión Ceniza (Tefra, World/TefraCityBuilder): todo escasea, así que es más caro que en Valmar.
	-- Claves «Tefra…»: la historia de Valmar nunca te manda aquí a comprar.
	TefraPanaderia = { Id = "Pan", NameKey = "ITEM.PAN", Price = 8, Hunger = 15 },
	TefraSopa = { Id = "Pan", NameKey = "Sopa del Campus (con pan)", Price = 5, Hunger = 25, Energy = 5 },
	TefraMercado = { Id = "Medicinas", NameKey = "ITEM.MEDICINAS", Price = 30 },
	TefraRaciones = { Id = "BolsaCompra", NameKey = "Ración del día", Price = 20, Hunger = 35, Energy = 5 },
	-- Anclaje Siete (Miasma) y Puerto Calcina (Siroco): marco común de los planetas (World/PlanetCityBuilder)
	MiasmaRaciones = { Id = "BolsaCompra", NameKey = "Ración del asedio", Price = 18, Hunger = 30, Energy = 5 },
	MiasmaFiltros = { Id = "CapsulaAire", NameKey = "Cápsula de aire limpio", Price = 25 },
	SirocoAgua = { Id = "AguaFresca", NameKey = "Agua fresca (el agua más cara de la galaxia)", Price = 15 },
	-- Fortaleza Albor (Nivalis): la sopa caliente de Brisa (la contramedida del frío)
	-- Raíz Honda (Umbría): el ungüento de savia del herbolario (la contramedida de las esporas)
	UmbriaSavia = { Id = "UnguentoSavia", NameKey = "Ungüento de savia", Price = 12 },
	NivalisSopa = { Id = "SopaAlbor", NameKey = "Sopa caliente de Albor", Price = 12 },
	SirocoCantina = { Id = "Fruta", NameKey = "Zumo de cactus y tortas de dátil", Price = 9, Hunger = 22, Energy = 8 },
}

return ShopItems
