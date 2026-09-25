-- Items: todo lo que puede aparecer en la mochila (inventario al estilo Minecraft).
-- Junta en una sola lista cosas que guardan distintos sistemas:
--   * Comida y objetos comprados en las tiendas (ShopItems.luau)   -> data.Items = { Pan = 3, ... }
--   * Vehículos (Gameplay.Vehicles)                                -> data.Vehicles
--   * Premios de los recreativos (Gameplay.Prizes)                 -> data.Prizes
--   * Carnets de conducir (Gameplay.Licenses)                      -> data.Licenses
--   * Títulos de la universidad (Subjects.Degrees)                 -> data.Education.Degrees
--
-- Kind dice qué pasa al usarlo:
--   Food     se come (quita hambre o da energía) y se gasta uno
--   Vehicle  te montas o te bajas
--   Wear     te lo pones o te lo quitas
--   Thing / Prize / Document   solo se guarda (recados, recuerdos, papeles)
--   Keepsake  objeto de la historia (la mochila del cole, la foto del grupo…): no se tira

local Gameplay = require(script.Parent.Gameplay)
local ShopItems = require(script.Parent.LifeStory.ShopItems)
local Subjects = require(script.Parent.LifeStory.Subjects)
local Strings = require(script.Parent.LifeStory.Strings)

local Items = {}

Items.Slots = 36 -- como en Minecraft: 27 de mochila + 9 de barra rápida
Items.Hotbar = 9 -- casillas 1-9 = barra rápida (teclas 1-9)

export type Item = {
	Id: string,
	Name: string,
	Icon: string,
	Kind: string,
	Desc: string,
	Stack: number, -- cuántos caben en una casilla
	Hunger: number?,
	Energy: number?,
	Ref: string?, -- clave en su sistema (vehículo, premio, carnet…)
}

local ICONS = {
	MaterialEscolar = "✏️",
	Medicinas = "💊",
	Helado = "🍦",
	Pan = "🥖",
	Fruta = "🍎",
	Flores = "💐",
}
local DESCS = {
	MaterialEscolar = "Lápices, cuadernos y una goma que huele a fresa.",
	Medicinas = "Las medicinas de casa. Guárdalas para la familia.",
	Helado = "Frío y dulce. Quita un poco de hambre y anima.",
	Pan = "Recién hecho en la panadería. Quita el hambre.",
	Fruta = "Fresca y sana. Quita el hambre.",
	Flores = "Un ramo precioso para regalar o decorar tu casa.",
}

local list: { [string]: Item } = {}

for _, shopItem in ShopItems do
	local food = shopItem.Hunger ~= nil or shopItem.Energy ~= nil
	list[shopItem.Id] = {
		Id = shopItem.Id,
		Name = Strings.get(shopItem.NameKey),
		Icon = ICONS[shopItem.Id] or "📦",
		Kind = if food then "Food" else "Thing",
		Desc = DESCS[shopItem.Id] or "",
		Stack = if food then 16 else 64,
		Hunger = shopItem.Hunger,
		Energy = shopItem.Energy,
	}
end

for key, vehicle in Gameplay.Vehicles do
	list["Vehiculo_" .. key] = {
		Id = "Vehiculo_" .. key,
		Name = vehicle.Name,
		Icon = vehicle.Icon,
		Kind = "Vehicle",
		Desc = ("Tu %s. Úsalo para montarte o bajarte. Velocidad %d."):format(vehicle.Name:lower(), vehicle.Speed),
		Stack = 1,
		Ref = key,
	}
end

for key, prize in Gameplay.Prizes do
	if prize.Kind ~= "Vehicle" then -- los vehículos de premio ya salen como vehículos
		list["Premio_" .. key] = {
			Id = "Premio_" .. key,
			Name = prize.Name,
			Icon = prize.Icon,
			Kind = if prize.Kind == "Wear" then "Wear" else "Prize",
			Desc = if prize.Kind == "Wear" then "Premio de los recreativos. Úsalo para ponértelo o quitártelo." else "Premio de los recreativos. ¡Un recuerdo de tu récord!",
			Stack = 1,
			Ref = key,
		}
	end
end

for key, license in Gameplay.Licenses do
	list["Carnet_" .. key] = {
		Id = "Carnet_" .. key,
		Name = license.Name,
		Icon = "🪪",
		Kind = "Document",
		Desc = "Aprobado en la autoescuela. Te deja conducir: " .. (Gameplay.Vehicles[license.Vehicle] and Gameplay.Vehicles[license.Vehicle].Name or license.Vehicle) .. ".",
		Stack = 1,
		Ref = key,
	}
end

for _, degree in Subjects.Degrees do
	list["Titulo_" .. degree.Titulo] = {
		Id = "Titulo_" .. degree.Titulo,
		Name = "Título de " .. Strings.get(degree.NameKey),
		Icon = "🎓",
		Kind = "Document",
		Desc = "Tu título universitario. ¡Años de estudio en Campus Valmar!",
		Stack = 1,
		Ref = degree.Titulo,
	}
end

-- Objetos de la historia (las misiones los dan y los quitan con Effects.Items / Effects.Take)
local KEEPSAKES = {
	{ "MochilaCole", "Mochila del cole", "🎒", "Tu mochila azul del colegio, con tu nombre bordado." },
	{ "CromoSuerte", "Cromo de la suerte", "🃏", "Un cromo brillante de un portero legendario. Da suerte (eso dices tú)." },
	{ "DibujoMateo", "Dibujo de Mateo", "🖼️", "Mateo te dibujó pasándole el balón a Dani. Pone: «Para mi primer amigo»." },
	{ "FotoGrupo", "Foto del grupo", "📸", "Todos en el parque, haciendo muecas. La primera foto de tu grupo." },
	{ "CuadernoOmar", "Dibujo de Omar", "✏️", "Omar dibujó el partido. Tú sales marcando (aunque no fuera exactamente así)." },
}
for _, entry in KEEPSAKES do
	list[entry[1]] = { Id = entry[1], Name = entry[2], Icon = entry[3], Kind = "Keepsake", Desc = entry[4], Stack = 99 }
end

Items.List = list

function Items.get(id: string?): Item?
	return if id then list[id] else nil
end

-- Qué objetos tiene alguien y cuántos, a partir de sus datos guardados
function Items.owned(data: { [string]: any }): { [string]: number }
	local owned = {}
	for id, count in data.Items or {} do
		if list[id] and type(count) == "number" and count > 0 then
			owned[id] = count
		end
	end
	for key, has in data.Vehicles or {} do
		if has and list["Vehiculo_" .. key] then
			owned["Vehiculo_" .. key] = 1
		end
	end
	for key, has in data.Prizes or {} do
		if has and list["Premio_" .. key] then
			owned["Premio_" .. key] = 1
		end
	end
	for key, has in data.Licenses or {} do
		if has and list["Carnet_" .. key] then
			owned["Carnet_" .. key] = 1
		end
	end
	for title in (data.Education and data.Education.Degrees) or {} do
		if list["Titulo_" .. title] then
			owned["Titulo_" .. title] = 1
		end
	end
	return owned
end

return Items
