-- Mining: minar asteroides con el láser de la nave (cuentas puras; docs/espacio.md).
--
-- Quien decide es el SERVIDOR: el cliente solo pide «disparo hacia aquí» (AirCombatService, con
-- cadencia, calor y cono máximo) y el servidor mira si su láser da en un asteroide. Cada asteroide
-- tiene unas cuantas unidades de mineral; cada HitsPerUnit impactos suelta una. Vacío, se apaga y se
-- rellena solo a los RefillSeconds. Lo minado va a la BODEGA de la nave (data.Space.Ore, máximo
-- CargoMax) y se vende en las estaciones.
--
-- Contra trampas (Mining.allow): nunca más de una unidad cada MinGap segundos ni más de RateMax en
-- RateWindow segundos por jugador, la bodega tiene tope, hay que estar cerca del asteroide (el disparo
-- sale de la nave) y en una zona segura (estación) no se mina.

local Mining = {}

export type Ore = { Id: string, Name: string, Price: number, Color: Color3, Chispas: number }

Mining.Ores = {
	Hierro = { Id = "Hierro", Name = "Hierro estelar", Price = 12, Color = Color3.fromRGB(170, 160, 150), Chispas = 0 },
	Cobalto = { Id = "Cobalto", Name = "Cobalto azul", Price = 30, Color = Color3.fromRGB(80, 140, 255), Chispas = 0 },
	Cristal = { Id = "Cristal", Name = "Cristal solar", Price = 80, Color = Color3.fromRGB(255, 220, 90), Chispas = 1 },
} :: { [string]: Ore }
Mining.Order = { "Hierro", "Cobalto", "Cristal" }

Mining.HitsPerUnit = 4 -- impactos de láser por unidad de mineral
Mining.RefillSeconds = 120
Mining.CargoMax = 40
Mining.MinGap = 0.5 -- segundos entre dos unidades (como mucho)
Mining.RateWindow = 600
Mining.RateMax = 90 -- unidades en RateWindow
Mining.Reach = 1100 -- distancia máxima de la nave al asteroide

-- Unidades de mineral de un asteroide según su tamaño
function Mining.units(radius: number): number
	return math.clamp(2 + math.floor(radius / 12), 2, 8)
end

export type Rock = { Units: number, Max: number, Hits: number, EmptyAt: number? }

function Mining.newRock(radius: number): Rock
	local n = Mining.units(radius)
	return { Units = n, Max = n, Hits = 0, EmptyAt = nil }
end

-- Si ya pasó el tiempo, se rellena. Devuelve true si se acaba de rellenar.
function Mining.refill(r: Rock, now: number): boolean
	if r.Units <= 0 and r.EmptyAt and now - r.EmptyAt >= Mining.RefillSeconds then
		r.Units = r.Max
		r.Hits = 0
		r.EmptyAt = nil
		return true
	end
	return false
end

-- Un impacto de láser. Devuelve "Unit" (suelta una unidad), "Empty" (era la última), "Chip" (solo
-- desconcha) o "Dry" (vacío)
function Mining.hit(r: Rock, now: number): string
	Mining.refill(r, now)
	if r.Units <= 0 then
		return "Dry"
	end
	r.Hits += 1
	if r.Hits < Mining.HitsPerUnit then
		return "Chip"
	end
	r.Hits = 0
	r.Units -= 1
	if r.Units <= 0 then
		r.EmptyAt = now
		return "Empty"
	end
	return "Unit"
end

export type Rate = { Last: number, Times: { number } }

function Mining.newRate(): Rate
	return { Last = -math.huge, Times = {} }
end

-- ¿Se le puede dar esta unidad? (y la apunta). why: "Rate", "Cargo", "Far", "Safe" o nil
function Mining.allow(rate: Rate, now: number, cargo: number, shipPos: Vector3, rockPos: Vector3, safe: boolean): (boolean, string?)
	if safe then
		return false, "Safe"
	end
	if (shipPos - rockPos).Magnitude > Mining.Reach then
		return false, "Far"
	end
	if cargo >= Mining.CargoMax then
		return false, "Cargo"
	end
	if now - rate.Last < Mining.MinGap then
		return false, "Rate"
	end
	local keep = {}
	for _, t in rate.Times do
		if now - t < Mining.RateWindow then
			table.insert(keep, t)
		end
	end
	rate.Times = keep
	if #keep >= Mining.RateMax then
		return false, "Rate"
	end
	rate.Last = now
	table.insert(rate.Times, now)
	return true, nil
end

-- Cuánto mineral lleva en la bodega
function Mining.cargo(ore: { [string]: any }?): number
	local n = 0
	for id, v in ore or {} do
		if Mining.Ores[id] and type(v) == "number" and v > 0 then
			n += math.floor(v)
		end
	end
	return n
end

-- Vender todo: (dinero, chispas, unidades)
function Mining.sellValue(ore: { [string]: any }?): (number, number, number)
	local money, chispas, units = 0, 0, 0
	for id, v in ore or {} do
		local o = Mining.Ores[id]
		if o and type(v) == "number" and v > 0 then
			local n = math.floor(v)
			money += n * o.Price
			chispas += n * o.Chispas
			units += n
		end
	end
	return money, chispas, units
end

-- Mineral de un asteroide (repetible): según los pesos del campo y un número 0..1
function Mining.pick(weights: { [string]: number }, roll: number): string
	local total = 0
	for _, id in Mining.Order do
		total += weights[id] or 0
	end
	local x = roll * total
	for _, id in Mining.Order do
		x -= weights[id] or 0
		if x <= 0 then
			return id
		end
	end
	return "Hierro"
end

-- Texto de la bodega para el panel
function Mining.cargoText(ore: { [string]: any }?): string
	return ("⛏ %d/%d"):format(Mining.cargo(ore), Mining.CargoMax)
end

return Mining
