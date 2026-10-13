-- OcioFeria (compartido): el Mercadillo y Recinto de Fiestas de la Explanada del Este (zona 7).
-- Sin Roblox: lo prueba scripts/test-ocio.luau.
--
--   * Horario fijo del juego (GameClock: Weekday 1 = lunes … 7 = domingo; día de 20 minutos):
--       - Mercadillo: todos los días de 8:00 a 14:00, y el sábado de 8:00 a 22:00.
--       - Fiesta del sábado: el sábado de 17:00 a 2:00 del domingo. Solo entonces abren los
--         minijuegos de la feria (aros, tiro con dianas blandas y pesca de patitos) y suena el escenario.
--     OcioFeria.status(weekday, hour) dice qué está abierto y cuánto falta para la próxima fiesta.
--   * Puestos del mercadillo (los alquila un jugador, como los locales de BusinessService): pagas el
--     alquiler y, mientras dura, la gente (NPC) y los demás jugadores te compran lo de tu mochila que se
--     puede vender en un puesto: lo de la granja (Farming) y el pescado (Fishing). Precio de puesto:
--     un poco más que el supermercado (OcioFeria.priceFor).
--   * Minijuegos de la feria: barra de precisión de MiniGameService («Timing») con premios en tickets
--     (los de los recreativos), algo de dinero al ganar y diversión (OcioFeria.prize).

local OcioFeria = {}

OcioFeria.SATURDAY = 6
OcioFeria.Market = { Open = 8, Close = 14, SaturdayClose = 22 }
OcioFeria.Fair = { Weekday = 6, Open = 17, Close = 26 } -- 26 = las 2:00 del día siguiente

-- ¿Abierto el mercadillo? (hour = hora del juego con decimales)
function OcioFeria.marketOpen(weekday: number, hour: number): boolean
	local close = if weekday == OcioFeria.SATURDAY then OcioFeria.Market.SaturdayClose else OcioFeria.Market.Close
	return hour >= OcioFeria.Market.Open and hour < close
end

-- ¿Es la fiesta del sábado? (también la madrugada del domingo hasta las 2:00)
function OcioFeria.fairOpen(weekday: number, hour: number): boolean
	local f = OcioFeria.Fair
	if weekday == f.Weekday and hour >= f.Open then
		return true
	end
	local nextDay = f.Weekday % 7 + 1
	return weekday == nextDay and hour < f.Close - 24
end

-- Horas de juego que faltan para que empiece la próxima fiesta (0 si ya ha empezado)
function OcioFeria.hoursToFair(weekday: number, hour: number): number
	if OcioFeria.fairOpen(weekday, hour) then
		return 0
	end
	local f = OcioFeria.Fair
	local days = (f.Weekday - weekday) % 7
	local h = days * 24 + f.Open - hour
	if h <= 0 then
		h += 7 * 24
	end
	return h
end

local DAYS = { "lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo" }
function OcioFeria.status(weekday: number, hour: number): { Market: boolean, Fair: boolean, HoursToFair: number, Text: string }
	local market, fair = OcioFeria.marketOpen(weekday, hour), OcioFeria.fairOpen(weekday, hour)
	local wait = OcioFeria.hoursToFair(weekday, hour)
	local text
	if fair then
		text = "🎡 ¡Fiesta del sábado! Aros, tiro y patitos hasta las 2:00"
	elseif wait < 24 then
		text = ("🎡 Fiesta del sábado: hoy a las %d:00"):format(OcioFeria.Fair.Open)
	else
		text = ("🎡 Próxima fiesta: el %s a las %d:00"):format(DAYS[OcioFeria.Fair.Weekday], OcioFeria.Fair.Open)
	end
	if market then
		text = "🧺 Mercadillo abierto · " .. text
	end
	return { Market = market, Fair = fair, HoursToFair = wait, Text = text }
end

---------------------------------------------------------------------
-- Minijuegos de la feria (MiniGameService, Game = "Timing")
---------------------------------------------------------------------
OcioFeria.Games = {
	Aros = { Name = "Lanzamiento de aros", Icon = "⭕", Price = 3, Spec = { Game = "Timing", Title = "Lanza los aros a las botellas", Icon = "⭕", Rounds = 5, Need = 2, Speed = 1.1, Zone = 0.18, Shrink = 0.01 } },
	Tiro = { Name = "Tiro con dianas blandas", Icon = "🎯", Price = 3, Spec = { Game = "Timing", Title = "Tira las dianas de espuma", Icon = "🎯", Rounds = 6, Need = 3, Speed = 1.5, Zone = 0.2, Shrink = 0.02 } },
	Patitos = { Name = "Pesca de patitos", Icon = "🦆", Price = 2, Spec = { Game = "Timing", Title = "Pesca un patito con la caña", Icon = "🦆", Rounds = 3, Need = 1, Speed = 0.8, Zone = 0.3 } },
}
OcioFeria.GameOrder = { "Aros", "Tiro", "Patitos" }

-- Premio de un minijuego: tickets por acierto, dinero al ganar y diversión (más si aciertas todo)
function OcioFeria.prize(gameId: string, hits: number, won: boolean): { Tickets: number, Money: number, Fun: number }
	local g = OcioFeria.Games[gameId]
	if not g then
		return { Tickets = 0, Money = 0, Fun = 0 }
	end
	local rounds = g.Spec.Rounds
	local h = math.clamp(math.floor(tonumber(hits) or 0), 0, rounds)
	local perfect = h >= rounds
	return {
		Tickets = h * 4 + (if perfect then 10 else 0),
		Money = if won then (if perfect then 12 else 5) else 0,
		Fun = 6 + (if won then 4 else 0) + (if perfect then 4 else 0),
	}
end

---------------------------------------------------------------------
-- Puestos del mercadillo
---------------------------------------------------------------------
OcioFeria.Stall = {
	Rent = 40, -- € por alquiler
	Seconds = 600, -- dura 10 minutos de verdad (medio día del juego)
	CustomerEvery = { 14, 26 }, -- cada cuánto llega un cliente NPC (s)
	Markup = 1.35, -- sobre el precio base (la cooperativa paga 1, el súper 1,3)
	FishMarkup = 1.2, -- sobre lo que paga la pescadería
	Max = 1, -- puestos por jugador a la vez
}

-- Precio de venta en el puesto de algo de la mochila (0 = no se vende en un puesto). farmPrice y
-- fishPrice son los precios base de Farming.Products y Fishing (los pasa quien llama: así este módulo
-- no depende de ellos y se prueba solo).
function OcioFeria.priceFor(id: string, farmPrice: number?, fishPrice: number?): number
	if farmPrice and farmPrice > 0 then
		return math.max(1, math.floor(farmPrice * OcioFeria.Stall.Markup + 0.5))
	elseif fishPrice and fishPrice > 0 then
		return math.max(1, math.floor(fishPrice * OcioFeria.Stall.FishMarkup + 0.5))
	end
	return 0
end

-- Qué compra un cliente: de lo que hay en el puesto (stock = { [id] = cantidad }) elige al azar, con
-- más probabilidad lo que más hay. rand = número de 0 a 1 (math.random() o Random:NextNumber()).
function OcioFeria.pickSale(stock: { [string]: number }, rand: number): string?
	local ids, total = {}, 0
	for id, n in stock do
		if n > 0 then
			table.insert(ids, id)
			total += n
		end
	end
	if total <= 0 then
		return nil
	end
	table.sort(ids)
	local r = math.clamp(rand, 0, 0.999999) * total
	for _, id in ids do
		r -= stock[id]
		if r < 0 then
			return id
		end
	end
	return ids[#ids]
end

---------------------------------------------------------------------
-- Comida de los food trucks y de los chiringuitos (FoodService, tag FoodStand: Config.Foods)
---------------------------------------------------------------------
OcioFeria.Trucks = {
	{ Id = "Churros", Name = "Churrería La Verbena", Foods = { "Churros", "Chocolate" }, Color = { 230, 120, 40 } },
	{ Id = "Bocatas", Name = "Bocatas El Ancla", Foods = { "BocataCalamares", "Refresco" }, Color = { 40, 120, 200 } },
	{ Id = "Pizza", Name = "Pizza al Corte Valmar", Foods = { "PizzaPorcion", "Refresco" }, Color = { 200, 50, 50 } },
	{ Id = "Helados", Name = "Heladería Polo Norte", Foods = { "Helado", "Granizado" }, Color = { 120, 200, 220 } },
}
OcioFeria.BeachBars = {
	{ Id = "Chiringuito1", Name = "Chiringuito La Ola", Foods = { "Refresco", "BocataCalamares", "Granizado" } },
	{ Id = "Chiringuito2", Name = "Chiringuito El Faro", Foods = { "Helado", "Agua", "PizzaPorcion" } },
}

return OcioFeria
