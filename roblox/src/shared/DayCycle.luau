-- DayCycle: el horario del día y la noche de Valmar (un verano de España) y cómo se mueve el sol.
-- Cuentas puras, sin require (se prueban fuera de Roblox: scripts/test-daylight.luau).
--
-- Queja del dueño (v120): a las 18:02 ya era noche cerrada y oscurecía desde las 17:30. En Roblox el
-- sol de verdad lo mueve Lighting.ClockTime y se pone hacia las 18:00. Ahora:
--
--   06:30  primera luz (azul de antes del alba)
--   07:00  amanece (cielo rosado; el sol sale hacia las 07:30)
--   08:00  pleno día
--   ~14:25 mediodía solar (el sol en lo más alto, como en España en verano)
--   20:30  hora dorada
--   21:30  EMPIEZA el atardecer (puesta de sol, luego hora azul): poco a poco, media hora entera
--   22:00  noche cerrada (y no antes)
--
-- Cómo: la HORA DEL JUEGO (la del HUD, las tiendas, el colegio, la historia) no es la del sol. El
-- servidor (WorldService) pone en Lighting.ClockTime la HORA DEL SOL, sunTime(hora del juego): un
-- tramo lineal por partes (Knots) que estira el día y comprime el atardecer. Lighting lleva el atributo
-- SunMapped = true; GameClock.hour() deshace la cuenta (gameTime) para saber la hora del juego.
--   * Lo que es «del sol» (posición del sol y la luna, luz y color de DayGrade, cielo de fotos, cuánto
--     se ve la Grieta) lee Lighting.ClockTime tal cual: va con el sol por construcción.
--   * Lo que es «de la noche» (farolas, ventanas, faros, grillos, estrellas fugaces, linterna, NPC de
--     noche…) usa darkness(hora del juego): la MISMA curva para todo, así nada se enciende antes.

local DayCycle = {}

-- Horas del juego (decimales: 21.5 = 21:30)
DayCycle.FirstLight = 6.5
DayCycle.DawnFrom = 7 -- empieza a clarear de verdad
DayCycle.Sunrise = 7.5
DayCycle.DayFrom = 8 -- pleno día
DayCycle.GoldenFrom = 20.5 -- hora dorada
DayCycle.DuskFrom = 21.5 -- empieza el atardecer
DayCycle.NightFrom = 22 -- noche cerrada

-- Oscuridad a partir de la que se encienden farolas, faros y ventanas (0..1): ~21:41 y se apagan ~07:38
DayCycle.LampsAt = 0.3
-- «Es de noche» (avisos, linterna, pájaros…): oscuridad >= 0,5 (21:45 a 07:30)
DayCycle.NightAt = 0.5

-- Hora del juego -> hora del sol (Lighting.ClockTime). Pares { juego, sol } crecientes; de 22:00 a
-- 05:00 (del día siguiente) se pasa en línea recta (la noche de luna, siempre la misma luz). Las horas
-- del sol son las de shared/DayGrade (amanecer 6,0, mañana dorada 6,9, mañana 8,5, mediodía 12,5,
-- hora dorada 17,2, puesta 18,0, hora azul 18,8, noche 19,9).
DayCycle.Knots = {
	{ 5.0, 0.0 }, -- (de 22:00 a 05:00, la noche de luna tal cual; luego va azulando)
	{ 6.5, 4.9 }, -- antes del alba (azul)
	{ 7.0, 5.6 }, -- clarea, cielo rosado
	{ 7.5, 6.3 }, -- sale el sol
	{ 8.0, 7.0 }, -- mañana dorada: ya es de día
	{ 9.0, 8.5 }, -- mañana
	{ 20.5, 17.0 }, -- hora dorada (el sol va despacio todo el día: mediodía solar ~14:25)
	{ 21.5, 17.45 }, -- aún de día, luz dorada: aquí EMPIEZA el atardecer
	{ 21.75, 18.3 }, -- puesta de sol (el sol se esconde hacia las 21:40)
	{ 22.0, 19.9 }, -- noche cerrada
}

local function interp(h: number, from: number, to: number): number
	local K = DayCycle.Knots
	local n = #K
	h %= 24
	if h < K[1][from] then
		h += 24
	end
	for i = 1, n - 1 do
		local a, b = K[i], K[i + 1]
		if h >= a[from] and h <= b[from] then
			return (a[to] + (b[to] - a[to]) * (h - a[from]) / (b[from] - a[from])) % 24
		end
	end
	-- La noche: del último par al primero del día siguiente
	local a, b = K[n], K[1]
	local t = (h - a[from]) / (b[from] + 24 - a[from])
	return (a[to] + (b[to] + 24 - a[to]) * t) % 24
end

-- La hora del sol para una hora del juego (lo que se escribe en Lighting.ClockTime)
function DayCycle.sunTime(gameHour: number): number
	return interp(gameHour, 1, 2)
end

-- La hora del juego para una hora del sol (lo que se lee de Lighting.ClockTime)
function DayCycle.gameTime(sunHour: number): number
	return interp(sunHour, 2, 1)
end

local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- Lo oscuro que es (0 = día, 1 = noche cerrada) a esta hora del juego. Al anochecer, suave de 21:30 a
-- 22:00; al amanecer, de 07:00 (aún de noche) a 08:00 (de día).
function DayCycle.darkness(gameHour: number): number
	local h = gameHour % 24
	if h >= DayCycle.NightFrom or h < DayCycle.DawnFrom then
		return 1
	elseif h >= DayCycle.DuskFrom then
		return smooth((h - DayCycle.DuskFrom) / (DayCycle.NightFrom - DayCycle.DuskFrom))
	elseif h < DayCycle.DayFrom then
		return 1 - smooth((h - DayCycle.DawnFrom) / (DayCycle.DayFrom - DayCycle.DawnFrom))
	end
	return 0
end

-- ¿Farolas, faros y luces de la calle encendidos?
function DayCycle.lampsOn(gameHour: number): boolean
	return DayCycle.darkness(gameHour) >= DayCycle.LampsAt
end

-- ¿Es de noche (para avisos, linterna, animales…)?
function DayCycle.isNight(gameHour: number): boolean
	return DayCycle.darkness(gameHour) >= DayCycle.NightAt
end

-- Las ventanas de los edificios traen su horario (OnAt / OffAt, shared/Kit) pensado para cuando
-- anochecía a las 18:00 (OnAt 17,5..20: unas antes, otras al volver del trabajo). Ahora cada una se
-- enciende cuando la oscuridad llega a su umbral (17,5 -> en cuanto empieza el atardecer; 20 o más ->
-- casi de noche) y se apaga WindowsLater horas más tarde de lo que decía (en verano se cena y se
-- acuesta más tarde), como mucho a las 07:00.
DayCycle.WindowsLater = 1.5
function DayCycle.windowThreshold(onAt: number): number
	return math.clamp((onAt - 17.5) / 3, 0.05, 0.95)
end
function DayCycle.windowLit(onAt: number, offAt: number, gameHour: number): boolean
	local h = gameHour % 24
	local t = if h < 12 then h + 24 else h -- horas de la noche seguidas (1:00 = 25)
	if t >= math.min(offAt + DayCycle.WindowsLater, 24 + DayCycle.DawnFrom) then
		return false
	end
	return DayCycle.darkness(h) >= DayCycle.windowThreshold(onAt)
end

return DayCycle
