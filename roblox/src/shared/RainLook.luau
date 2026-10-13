-- RainLook: cómo se VE la lluvia. Cuentas puras (se prueban fuera de Roblox: scripts/test-weather.luau).
--
-- v108 (queja del dueño en el móvil: el HUD decía «Lluvia» y el cielo estaba azul, el suelo seco y
-- apenas se veía caer agua). Aquí está todo lo que decide el aspecto, para que el HUD y la pantalla
-- digan siempre lo mismo (las dos cosas salen del atributo workspace "Weather"):
--   * Intensidad: «Lluvia» no es siempre igual: va de llovizna a chaparrón a lo largo del rato (igual
--     para todos, sale de la hora del juego); «Tormenta» es aguacero. Entra y sale poco a poco.
--   * El tiempo que se mezcla con la luz (DayGrade.weather) pasa de uno a otro sin saltos (blend).
--   * La lluvia que cae: cuántas gotas, de qué tamaño, lo largas, lo inclinadas con el viento, según
--     la intensidad y el nivel gráfico (el móvil en Bajo: menos gotas pero más gruesas, que se vean).
--   * Qué tapa la lluvia (un tejado de verdad; las copas de los árboles y lo transparente no) y cuándo
--     se está DENTRO (tejado y paredes alrededor; bajo un balcón en la calle sigue lloviendo delante).
--   * Gotas en la «lente» de la cámara: cuándo salen, cuántas y cuánto según hacia dónde se mira.

local RainLook = {}

RainLook.Fade = 12 -- segundos que tarda la lluvia (y el cielo) en entrar o en irse del todo

-- Intensidad que toca (0 = nada; 1 = lluvia fuerte; 1,7 = aguacero de tormenta).
-- clock: hora del juego (Lighting.ClockTime): la lluvia sube y baja despacio, llovizna <-> chaparrón.
function RainLook.intensity(weather: string?, clock: number): number
	if weather == "Lluvia" then
		-- Dos ondas lentas (en horas de juego): nunca menos de llovizna (0,4) ni más de 1
		local wave = 0.5 + 0.3 * math.sin(clock * 1.7) + 0.2 * math.sin(clock * 4.1 + 1.3)
		return 0.4 + 0.6 * math.clamp(wave, 0, 1)
	elseif weather == "Tormenta" then
		return 1.45 + 0.25 * (0.5 + 0.5 * math.sin(clock * 3.3))
	end
	return 0
end

-- Llovizna / Lluvia / Aguacero (para textos y pruebas)
function RainLook.kind(intensity: number): string
	if intensity <= 0.02 then
		return "Seco"
	elseif intensity < 0.6 then
		return "Llovizna"
	elseif intensity <= 1.05 then
		return "Lluvia"
	end
	return "Aguacero"
end

-- Acercarse a un valor sin saltos: recorre como mucho `full / fade` por segundo
function RainLook.approach(current: number, target: number, dt: number, fade: number?, full: number?): number
	local step = dt * (full or 1) / math.max(fade or RainLook.Fade, 0.01)
	if current < target then
		return math.min(target, current + step)
	end
	return math.max(target, current - step)
end

-- Mezcla de dos tiempos de Seasons.Weather (a = el de antes, b = el nuevo, t = 0..1): los números se
-- mezclan; lo que es sí/no (relámpagos, suelo que se moja) es del nuevo a partir de la mitad.
-- rain (opcional): la intensidad de lluvia de ahora (sustituye a la de la tabla).
local NUMBERS = { "Brightness", "Saturation", "Density", "Rain", "Snow" }
function RainLook.blend(a: { [string]: any }, b: { [string]: any }, t: number, rain: number?): { [string]: any }
	t = math.clamp(t, 0, 1)
	local out: { [string]: any } = {}
	for _, key in NUMBERS do
		local x, y = a[key] or (if key == "Brightness" then 1 else 0), b[key] or (if key == "Brightness" then 1 else 0)
		local v = x + (y - x) * t
		out[key] = if (key == "Rain" or key == "Snow") and v <= 0.001 then nil else v
	end
	-- Nubes: el cielo despejado no tiene cobertura propia (nil); al mezclar, cuenta como 0,5 (lo normal)
	local ca, cb = a.Cover, b.Cover
	if ca or cb then
		local x, y = ca or 0.5, cb or 0.5
		out.Cover = x + (y - x) * t
	end
	local main = if t >= 0.5 then b else a
	out.Lightning = main.Lightning
	out.Wet = main.Wet
	out.Name, out.Icon = b.Name, b.Icon
	if rain ~= nil then
		out.Rain = if rain > 0.001 then rain else nil
	end
	return out
end

---------------------------------------------------------------------
-- La lluvia que cae (partículas alrededor de la cámara)
---------------------------------------------------------------------

export type Falling = {
	Rate: number, -- gotas por segundo cerca (alrededor de la cámara)
	Size: number, -- grosor de la gota
	Squash: number, -- lo estirada (con VelocityParallel: positivo = larga en la dirección en que cae)
	Transparency: number,
	FarRate: number, -- cortina lejana (gotas más grandes y tenues que dan «volumen»); 0 en Bajo
	SplashRate: number, -- salpicaduras en el suelo alrededor
	RippleRate: number, -- ondas en los charcos
	Tilt: Vector3, -- aceleración de lado por el viento (studs/s²)
}

-- Por nivel gráfico: gotas cerca / lejos, grosor (el móvil en Bajo dibuja a poca resolución: gota
-- más gruesa para que se vea), salpicaduras
local TIER = {
	Low = { Near = 520, Far = 0, Size = 0.2, Splash = 120, Ripple = 0 },
	Medium = { Near = 850, Far = 160, Size = 0.16, Splash = 200, Ripple = 18 },
	High = { Near = 1250, Far = 300, Size = 0.14, Splash = 280, Ripple = 30 },
}

function RainLook.falling(intensity: number, tier: string?, wind: Vector3?): Falling
	local cfg = TIER[tier or "Medium"] or TIER.Medium
	local i = math.clamp(intensity, 0, 1.7)
	local w = wind or Vector3.new(0, 0, 0)
	return {
		Rate = math.floor(cfg.Near * i),
		Size = cfg.Size * (0.85 + 0.15 * math.min(i, 1)),
		Squash = 2.6,
		-- Llovizna más tenue; chaparrón más denso y blanco
		Transparency = math.clamp(0.55 - 0.25 * math.min(i, 1), 0.2, 0.6),
		FarRate = math.floor(cfg.Far * i),
		SplashRate = math.floor(cfg.Splash * i),
		RippleRate = math.floor(cfg.Ripple * i),
		Tilt = Vector3.new(w.X * 1.8, 0, w.Z * 1.8),
	}
end

---------------------------------------------------------------------
-- Techo, dentro y fuera (las mismas reglas para la lluvia, las gotas en pantalla y la gente mojada)
---------------------------------------------------------------------

-- ¿Lo que hay encima tapa la lluvia? Lo transparente (cristal de una marquesina muy fina, zonas
-- invisibles) y las copas de los árboles no.
local LEAVES = { LeafyGrass = true, Grass = true }
function RainLook.blocksRain(transparency: number, materialName: string): boolean
	return transparency < 0.5 and not LEAVES[materialName]
end

-- ¿Está DENTRO? Tejado encima y, además, tejado también un poco más allá de donde mira (una nave o
-- un salón grande) o paredes en al menos 3 de las 4 direcciones (una habitación). Bajo un balcón o un
-- saliente de la fachada, mirando a la calle, se sigue viendo llover.
function RainLook.enclosed(roof: boolean, walls: number, roofAhead: boolean?): boolean
	return roof and (roofAhead == true or walls >= 3)
end

---------------------------------------------------------------------
-- Gotas en la lente de la cámara
---------------------------------------------------------------------

export type LensState = {
	Intensity: number,
	Roof: boolean, -- algo tapa la lluvia justo encima de la cámara
	Enclosed: boolean?,
	Vehicle: string?, -- RideState.vehicleOf (nil = a pie)
	Cinematic: boolean?, -- cámara de cine (Scriptable)
	Underground: boolean?,
}

-- Vehículos sin techo (te mojas): en los demás no salen gotas en la pantalla
RainLook.OpenVehicles = { Bici = true, Moto = true, Monopatin = true, Patinete = true, Caballo = true, Barca = true, Kayak = true }

function RainLook.lensAllowed(s: LensState): boolean
	if s.Intensity < 0.05 or s.Roof or s.Enclosed or s.Cinematic or s.Underground then
		return false
	end
	if s.Vehicle ~= nil and not RainLook.OpenVehicles[s.Vehicle] then
		return false
	end
	return true
end

-- Hacia dónde mira la cámara (LookVector.Y): mirando arriba o al frente le caen gotas; mirando al
-- suelo, casi ninguna.
function RainLook.lensFacing(lookY: number): number
	return math.clamp(0.7 + lookY * 0.9, 0.08, 1)
end

-- Cuántas gotas a la vez como mucho (sutil: nunca tapan el juego) y cuántas nuevas por segundo
local LENS_MAX = { Low = 4, Medium = 7, High = 10 }
function RainLook.lensBudget(intensity: number, tier: string?, facing: number): (number, number)
	local max = LENS_MAX[tier or "Medium"] or 7
	local i = math.clamp(intensity, 0, 1.7)
	local count = math.floor(max * math.min(1, 0.35 + 0.5 * i) + 0.5)
	return count, 1.4 * i * facing
end

-- Una gota en la lente: aparece, se queda un poco, resbala hacia abajo dejando un rastro y se va.
-- age en segundos; life = lo que dura. Devuelve: opacidad (0..1), cuánto ha bajado (0..1 de su
-- recorrido) y lo estirada (1 = redonda).
function RainLook.lensDrop(age: number, life: number): (number, number, number)
	local t = math.clamp(age / math.max(life, 0.01), 0, 1)
	local appear = math.clamp(t / 0.08, 0, 1)
	local fade = math.clamp((1 - t) / 0.3, 0, 1)
	local alpha = appear * fade
	-- Quieta el primer 40 % y luego resbala, cada vez más deprisa
	local slide = if t < 0.4 then 0 else ((t - 0.4) / 0.6) ^ 2
	local stretch = 1 + 1.6 * math.clamp((t - 0.4) / 0.3, 0, 1) * (1 - 0.4 * slide)
	return alpha, slide, stretch
end

---------------------------------------------------------------------
-- Charcos (v109)
---------------------------------------------------------------------

-- Suelos donde se queda el agua (calzada, acera, plaza). No en hierba, tierra, tejados ni muebles.
RainLook.PuddleGround = { Asphalt = true, Concrete = true, Pavement = true, Cobblestone = true, Granite = true }

-- ¿Vale este sitio para un charco? Llano, de calle, a la altura del suelo donde estás (dy = diferencia
-- de altura; así no salen en tejados ni en el techo de un coche) y, mejor, junto al bordillo o una pared
-- (edge). En medio de la calle, solo a veces (roll 0..1 al azar): nunca un patrón regular.
function RainLook.puddleSpot(materialName: string, normalY: number, dy: number, edge: boolean, roll: number): boolean
	if not RainLook.PuddleGround[materialName] or normalY < 0.985 or math.abs(dy) > 1.5 then
		return false
	end
	return edge or roll < 0.3
end

-- Cuánto se ven los charcos con lo mojado que está todo: nada hasta 0,35; del todo empapado
function RainLook.puddleOpacity(wet: number): number
	return math.clamp((wet - 0.35) / 0.5, 0, 1)
end

return RainLook
