-- Storm: las cuentas de los relámpagos y los truenos (puras: se prueban fuera de Roblox,
-- scripts/test-estaciones.luau). docs/clima/estaciones.md.
--
--   * El servidor (WeatherService) decide CUÁNDO cae un rayo y DÓNDE (igual para todos: atributo
--     workspace "Rayo"); cada jugador lo dibuja lejos en el cielo o cerca (Controllers/Relampagos),
--     con el fogonazo y el trueno, que llega más tarde cuanto más lejos cae (el sonido va a 343 m/s).
--   * SIN PARPADEOS (seguridad para la vista): nunca dos rayos con menos de MinGap segundos ni más de
--     MaxPerMinute en un minuto; cada fogonazo es UN destello que se apaga suave (y como mucho un
--     rebote más flojo), muy lejos de los 3 destellos por segundo que no se deben pasar.
--   * Ajuste «⚡ Destellos de relámpago: no»: el cielo no se ilumina de golpe (el rayo se ve tenue y
--     el trueno suena igual).

local Storm = {}

Storm.MinGap = 6 -- segundos mínimos entre dos rayos
Storm.MaxPerMinute = 5 -- rayos como mucho en 60 s
Storm.NearShare = 0.15 -- parte de los rayos que caen cerca de alguien
Storm.StudsPerSecond = 1225 -- velocidad del sonido (343 m/s; 1 stud = 0,28 m)
Storm.FlashSeconds = 0.45 -- lo que dura un fogonazo (subida rápida y bajada suave)
Storm.MaxFlash = 1 -- el fogonazo más fuerte (rayo cerca); uno lejano, menos

-- Lee los ajustes de Config.Seasons.Lightning (si los hay)
function Storm.configure(cfg: { [string]: number }?)
	if type(cfg) ~= "table" then
		return
	end
	Storm.MinGap = math.max(4, tonumber(cfg.MinGap) or Storm.MinGap) -- (nunca menos de 4 s)
	Storm.MaxPerMinute = math.clamp(tonumber(cfg.MaxPerMinute) or Storm.MaxPerMinute, 1, 8)
	Storm.NearShare = math.clamp(tonumber(cfg.NearShare) or Storm.NearShare, 0, 0.5)
end

-- ¿Puede caer otro rayo ahora? history: los instantes (os.clock) de los últimos rayos
function Storm.allow(history: { number }, now: number): boolean
	local last = history[#history]
	if last and now - last < Storm.MinGap then
		return false
	end
	local inMinute = 0
	for _, at in history do
		if now - at < 60 then
			inMinute += 1
		end
	end
	return inMinute < Storm.MaxPerMinute
end

-- Apunta un rayo (y olvida los de hace más de un minuto)
function Storm.record(history: { number }, now: number)
	table.insert(history, now)
	while history[1] and now - history[1] >= 60 do
		table.remove(history, 1)
	end
end

-- Cuánto falta para el próximo rayo (segundos), según lo fuerte que es la tormenta (0..1,7) y un
-- número al azar 0..1. Una tormenta en su punto, uno cada ~8-18 s; nunca menos de MinGap.
function Storm.nextGap(intensity: number, roll: number): number
	local i = math.clamp(intensity, 0, 1.7)
	if i <= 0.05 then
		return math.huge
	end
	local base = 8 + (1.7 - i) * 10
	return math.max(Storm.MinGap, base + roll * 10)
end

export type Strike = { Near: boolean, Distance: number, Angle: number, Branches: number }

-- Cómo es un rayo (rolls: tres números 0..1). Lejos: 2.000-6.000 studs (0,6-1,7 km), el trueno
-- tarda unos segundos; cerca: 250-900 studs, casi a la vez.
function Storm.strike(r1: number, r2: number, r3: number): Strike
	local near = r1 < Storm.NearShare
	local distance = if near then 250 + r2 * 650 else 2000 + r2 * 4000
	return { Near = near, Distance = distance, Angle = r3 * math.pi * 2, Branches = if near then 3 else 1 + math.floor(r2 * 2) }
end

-- Cuánto tarda el trueno en llegar (segundos) a esa distancia (studs)
function Storm.thunderDelay(distance: number): number
	return math.max(0, distance) / Storm.StudsPerSecond
end

-- Qué trueno y a qué volumen (0..1): cerca, el «crac» fuerte; lejos, el retumbar flojo
function Storm.thunder(distance: number): (string, number)
	if distance < 1200 then
		return "Near", math.clamp(1 - distance / 2400, 0.55, 1)
	end
	return "Far", math.clamp(0.75 - (distance - 1200) / 9000, 0.25, 0.7)
end

-- El fogonazo a los `age` segundos de caer (0..1): sube en 0,04 s y se apaga suave; si es cerca, un
-- rebote más flojo a los 0,14 s (el rayo de verdad titila). safe = el jugador quiere destellos.
function Storm.flash(age: number, near: boolean, safe: boolean): number
	if not safe or age < 0 or age > Storm.FlashSeconds then
		return 0
	end
	local peak = if near then Storm.MaxFlash else 0.55
	local main = if age < 0.04 then age / 0.04 else math.exp(-(age - 0.04) / 0.09)
	local bounce = 0
	if near and age > 0.14 then
		local b = age - 0.14
		bounce = 0.45 * (if b < 0.03 then b / 0.03 else math.exp(-(b - 0.03) / 0.07))
	end
	return math.clamp(peak * math.max(main, bounce), 0, 1)
end

-- Cuántos destellos (subidas) hace un fogonazo: para la prueba de seguridad (≤ 2 por rayo)
function Storm.pulses(near: boolean): number
	local count, prev, rising = 0, 0, false
	for i = 0, math.floor(Storm.FlashSeconds / 0.005) do
		local v = Storm.flash(i * 0.005, near, true)
		if v > prev + 1e-6 then
			if not rising then
				count += 1
			end
			rising = true
		elseif v < prev - 1e-6 then
			rising = false
		end
		prev = v
	end
	return count
end

-- La línea quebrada de un rayo: puntos de arriba (nube) abajo (suelo), con quiebros al azar (rand()
-- da números 0..1). top y bottom en studs; jitter = lo que se tuerce cada tramo.
function Storm.bolt(top: Vector3, bottom: Vector3, segments: number, jitter: number, rand: () -> number): { Vector3 }
	local points = { top }
	local n = math.clamp(math.floor(segments), 2, 16)
	for i = 1, n - 1 do
		local p = top:Lerp(bottom, i / n)
		local spread = jitter * (1 - 0.4 * i / n)
		table.insert(points, p + Vector3.new((rand() - 0.5) * 2 * spread, (rand() - 0.5) * spread * 0.3, (rand() - 0.5) * 2 * spread))
	end
	table.insert(points, bottom)
	return points
end

-- El atributo "Rayo" de workspace: «n|x|z|cerca|semilla» (n sube con cada rayo: así cambia siempre)
function Storm.encode(n: number, x: number, z: number, near: boolean, seed: number): string
	return ("%d|%d|%d|%d|%d"):format(n, math.floor(x), math.floor(z), if near then 1 else 0, seed)
end
function Storm.decode(text: any): { N: number, X: number, Z: number, Near: boolean, Seed: number }?
	if type(text) ~= "string" then
		return nil
	end
	local n, x, z, near, seed = text:match("^(%-?%d+)|(%-?%d+)|(%-?%d+)|([01])|(%-?%d+)$")
	if not n then
		return nil
	end
	return { N = tonumber(n) :: number, X = tonumber(x) :: number, Z = tonumber(z) :: number, Near = near == "1", Seed = tonumber(seed) :: number }
end

return Storm
