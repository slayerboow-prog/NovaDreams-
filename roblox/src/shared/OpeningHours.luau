-- OpeningHours: a qué hora abre y cierra cada sitio que atiende al público (horas de juego).
-- Las tiendas, correos, la biblioteca o la autoescuela cierran de noche: su dependiente no está y
-- sale el cartel de CERRADO con la hora a la que abren. Hospital, policía, bomberos, hoteles y
-- vigilantes: 24 horas.
--   OpeningHours.forRole("Dependiente") -> { 9.5, 21.5 } (nil = siempre abierto)
--   OpeningHours.isOpen(horas, hora)    -> ¿está abierto a esa hora?
--   OpeningHours.label(horas)           -> "abre a las 9:30"
--   OpeningHours.forPlace("Library")    -> horario de un sitio (el tipo de planta baja de Kit/Decor)
--   OpeningHours.forShop("Farmacia")    -> horario de una tienda de la calle (ShopId)
--   OpeningHours.Services.Supermercado  -> horario de los sitios con su propio servicio

local OpeningHours = {}

OpeningHours.Roles = {
	Dependiente = { 10, 22 }, -- (las tiendas del centro comercial: cierran con él)
	-- (Cajero: el de la tienda de la gasolinera, con su cartel de 24H: sin entrada = 24 horas)
	Cajera = { 11, 24 }, -- hamburguesería
	Cocinero = { 11, 24 },
	Cocinera = { 11, 24 },
	Informadora = { 10, 22 }, -- centro comercial
	["Funcionaria de Correos"] = { 8.5, 20.5 },
	["Funcionario de Correos"] = { 8.5, 20.5 },
	Bibliotecaria = { 9, 21 },
	Conserje = { 8, 21 },
	["Encargado de premios"] = { 10, 24 },
	["Profesor de autoescuela"] = { 9, 20 },
	Monitora = { 7, 23 },
	Monitor = { 7, 23 },
	-- 24 horas (sin entrada): Recepcionista, Vigilante, Agente de guardia, Bombero, Bombera…
}

-- Sitios de la ciudad (tipo de planta baja de Kit/Decor: el prefijo del Group de sus marcas) con el
-- mismo horario que su personal: sin dependiente no hay clientes dentro. Sin entrada = 24 horas.
OpeningHours.Places = {
	Mall = OpeningHours.Roles.Informadora,
	Library = OpeningHours.Roles.Bibliotecaria,
	Faculty = OpeningHours.Roles.Conserje,
	Post = OpeningHours.Roles["Funcionaria de Correos"],
	Arcade = OpeningHours.Roles["Encargado de premios"],
	DrivingSchool = OpeningHours.Roles["Profesor de autoescuela"],
	Burger = OpeningHours.Roles.Cajera,
	Gym = OpeningHours.Roles.Monitora,
	-- 24 horas: GasShop (gasolinera), Lobby (recepción de las torres), Clinic, Police
}

-- Tiendas de la calle (atributo ShopId de la entrada, ShopService)
OpeningHours.Shops = {
	Libreria = OpeningHours.Roles.Dependiente,
	Farmacia = { 9, 22 },
	Heladeria = { 11, 23.5 },
	Panaderia = { 7.5, 21 },
	Fruteria = { 8.5, 21 },
	Floristeria = OpeningHours.Roles.Dependiente,
}

-- Sitios con su propio servicio (su personal NPC y sus clientes siguen este horario)
OpeningHours.Services = {
	Supermercado = { 9, 22 },
	Cafeteria = { 7, 22.5 },
	-- Hospitales y centros de salud: 24 horas (de noche, el médico de guardia)
}
OpeningHours.Shops.Supermercado = OpeningHours.Services.Supermercado

function OpeningHours.forRole(role: string?): { number }?
	return if role then OpeningHours.Roles[role] else nil
end

function OpeningHours.forPlace(kind: string?): { number }?
	return if kind then OpeningHours.Places[kind] else nil
end

function OpeningHours.forShop(shopId: string?): { number }?
	return if shopId then OpeningHours.Shops[shopId] else nil
end

-- La hora del juego ahora mismo (Lighting.ClockTime; 12 si no se puede leer)
function OpeningHours.clock(): number
	local ok, clock = pcall(function()
		return game:GetService("Lighting").ClockTime
	end)
	return if ok and type(clock) == "number" and clock == clock then clock else 12
end

-- ¿Está abierto ahora?
function OpeningHours.openNow(hours: { number }?): boolean
	return OpeningHours.isOpen(hours, OpeningHours.clock())
end

function OpeningHours.isOpen(hours: { number }?, clock: number): boolean
	if not hours then
		return true
	end
	local from, to = hours[1], hours[2]
	if from <= to then
		return clock >= from and clock < to
	end
	return clock >= from or clock < to
end

local function hhmm(hour: number): string
	local h = math.floor(hour) % 24
	local m = math.floor((hour - math.floor(hour)) * 60 + 0.5)
	return ("%d:%02d"):format(h, m)
end

function OpeningHours.label(hours: { number }): string
	return ("abre a las %s"):format(hhmm(hours[1]))
end

return OpeningHours
