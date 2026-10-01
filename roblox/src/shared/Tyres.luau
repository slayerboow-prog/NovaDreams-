-- Tyres: pinchazos de las ruedas. SOLO cuentas y datos (lo usan TyreService en el servidor, Driving y
-- WheelSpin en el cliente y scripts/test-tyres.luau con Lune).
--
--   * Causas (las decide SIEMPRE el servidor): un disparo de verdad que atraviesa la rueda, un choque
--     muy fuerte (la rueda más cercana al golpe, no siempre) y, muy de vez en cuando, mala suerte en
--     un viaje largo (uno cada varias horas de conducir). Nada de pinchazos constantes.
--   * Estado: un atributo por rueda en el vehículo, Flat_<rueda> = true (lo pone el servidor y lo ven
--     todos). Rueda = eje (1 = delante) + lado ("L" izquierda, "R" derecha; nada en moto y bici):
--     "1L", "2R", "1"…
--   * Efectos: la rueda se ve chafada (Controllers/WheelSpin), el coche tira hacia ese lado, corre y
--     agarra menos y se oye el «flap-flap» (Controllers/Driving).
--   * Arreglo: «Reparar rueda» en las gasolineras (se paga), la rueda de repuesto (una vez cada vez que
--     sacas el vehículo; se tarda unos segundos) o volver a sacar el vehículo desde «Mis vehículos».
--   * Los vehículos de pago (Premium: atributo Premium del modelo o Premium = true en
--     Gameplay.Vehicles) no pinchan nunca (y gastan menos: Gameplay.Fuel.PremiumFactor).

local Tyres = {}

Tyres.PREFIX = "Flat_"
-- Los que pueden pinchar (el monopatín lleva ruedas macizas; los barcos, ninguna)
Tyres.Kinds = { Coche = true, Patrulla = true, Moto = true, Bici = true, Patinete = true, Camion = true, Bomberos = true, Autobus = true }

Tyres.CrashSpeed = 40 -- choque (velocidad de cierre, studs/s) a partir del que puede pinchar una rueda
Tyres.CrashChance = 0.5 -- y la probabilidad de que pinche
Tyres.RandomPer1000 = 0.0015 -- mala suerte: probabilidad cada 1000 studs (≈ uno cada 3 h de coche)
Tyres.RepairPrice = 60 -- € por rueda en la gasolinera
Tyres.SpareSeconds = 4 -- lo que se tarda en poner la de repuesto (mantener el cartel)

-- Con ruedas pinchadas: velocidad máxima (por número de pinchadas), giro, agarre y cuánto tira
-- hacia el lado pinchado (rad/s a toda velocidad)
Tyres.MaxSpeed = { 0.6, 0.45, 0.35 }
Tyres.Turn = 0.8
Tyres.Traction = 0.7
Tyres.Pull = 0.22
Tyres.Drop = 0.28 -- (aspecto) cuánto baja la rueda chafada, en radios

-- Nombre de cada rueda a partir de dónde están (respecto al vehículo: morro hacia −Z, izquierda −X)
function Tyres.ids(positions: { Vector3 }): { string }
	local axles: { number } = {}
	for _, p in positions do
		local found = false
		for _, z in axles do
			if math.abs(z - p.Z) < 1 then
				found = true
				break
			end
		end
		if not found then
			table.insert(axles, p.Z)
		end
	end
	table.sort(axles)
	local out = {}
	for i, p in positions do
		local axle = 1
		for k, z in axles do
			if math.abs(z - p.Z) < 1 then
				axle = k
				break
			end
		end
		local side = if math.abs(p.X) < 0.3 then "" elseif p.X < 0 then "L" else "R"
		out[i] = tostring(axle) .. side
	end
	return out
end

-- Las ruedas pinchadas de un vehículo (sus atributos: GetAttributes() o una tabla igual)
function Tyres.flats(attributes: { [string]: any }): { string }
	local out = {}
	for key, value in attributes do
		if value == true and string.sub(key, 1, #Tyres.PREFIX) == Tyres.PREFIX then
			table.insert(out, string.sub(key, #Tyres.PREFIX + 1))
		end
	end
	table.sort(out)
	return out
end

-- Cómo va con esas ruedas pinchadas: MaxSpeed/Turn/Traction (multiplicadores) y Pull (rad/s a toda
-- velocidad; positivo = tira a la izquierda)
function Tyres.effects(flats: { string }): { MaxSpeed: number, Turn: number, Traction: number, Pull: number, Count: number }
	local n = #flats
	if n == 0 then
		return { MaxSpeed = 1, Turn = 1, Traction = 1, Pull = 0, Count = 0 }
	end
	local pull = 0
	for _, id in flats do
		local side = string.sub(id, -1)
		if side == "L" then
			pull += Tyres.Pull
		elseif side == "R" then
			pull -= Tyres.Pull
		end
	end
	return {
		MaxSpeed = Tyres.MaxSpeed[math.min(n, #Tyres.MaxSpeed)],
		Turn = Tyres.Turn,
		Traction = Tyres.Traction,
		Pull = math.clamp(pull, -Tyres.Pull * 1.5, Tyres.Pull * 1.5),
		Count = n,
	}
end

-- ¿Vehículo de pago? (atributo Premium del modelo o Premium = true en su ficha de Gameplay.Vehicles)
function Tyres.isPremium(spec: { [string]: any }?, premiumAttribute: any): boolean
	return premiumAttribute == true or (spec ~= nil and spec.Premium == true)
end

function Tyres.canPuncture(kind: string?, premium: boolean): boolean
	return kind ~= nil and Tyres.Kinds[kind] == true and not premium
end

-- ¿Atraviesa el tramo de a a b la rueda (centro, eje y radio)? (un disco del ancho de la rueda)
function Tyres.segmentHits(a: Vector3, b: Vector3, center: Vector3, axis: Vector3, radius: number, width: number): boolean
	local d = b - a
	local len2 = d:Dot(d)
	local t = if len2 > 1e-9 then math.clamp((center - a):Dot(d) / len2, 0, 1) else 0
	local p = a + d * t - center
	local along = p:Dot(axis)
	local radial = (p - axis * along).Magnitude
	return math.abs(along) <= width / 2 + 0.3 and radial <= radius
end

-- La rueda más cercana a un punto (índice), o nil si no hay
function Tyres.nearest(positions: { Vector3 }, point: Vector3): number?
	local best, bestD = nil, math.huge
	for i, p in positions do
		local d = (p - point).Magnitude
		if d < bestD then
			best, bestD = i, d
		end
	end
	return best
end

-- ¿Pincha este choque? (roll: número al azar 0..1)
function Tyres.crashPunctures(closing: number, roll: number): boolean
	return closing >= Tyres.CrashSpeed and roll < Tyres.CrashChance
end

-- ¿Mala suerte en este trozo de viaje? (distance en studs, roll 0..1)
function Tyres.unlucky(distance: number, roll: number): boolean
	if distance <= 0 then
		return false
	end
	local chance = 1 - (1 - Tyres.RandomPer1000) ^ (distance / 1000)
	return roll < chance
end

return Tyres
