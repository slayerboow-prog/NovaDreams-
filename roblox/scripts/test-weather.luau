-- Prueba de cómo afecta la lluvia y la nieve (shared/Wetness) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-weather.luau
--
-- Comprueba que:
--   * lo mojado se ve más oscuro y el asfalto brilla (más en el suelo que en las paredes)
--   * con nieve, lo de arriba se pone blanco y la calzada casi no
--   * con el suelo mojado o nevado, los vehículos agarran menos; las motos y bicis, aún menos
--   * con poco agarre acelera, frena y gira peor, y derrapa (tarda en ir hacia donde apunta)
--   * una persona se moja bajo la lluvia y se seca a cubierto
--   * el tráfico va más despacio con lluvia y con nieve
--   * (v108) la lluvia SE VE: el tiempo «Lluvia» da cielo gris tapado (velo, nubes, bruma) y gotas
--     visibles (trazos largos, más en Alto, más gruesas en Bajo), entra y sale sin saltos; el cielo se
--     mezcla del tiempo de antes al nuevo; reglas de techo (dentro / bajo un saliente / copas);
--     gotas en la pantalla solo cuando te mojas; personas mojadas: más oscuras y con brillo, se secan

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Enum = roblox.Enum
local env = setmetatable({ Enum = Enum, Vector3 = roblox.Vector3 }, { __index = getfenv(1) })
local Wetness = luau.load(fs.readFile("src/shared/Wetness.luau"), { debugName = "Wetness", environment = env })()

local failures = 0
local function check(ok: boolean, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

print("Superficies")
local d0, r0, w0 = Wetness.surface(Enum.Material.Asphalt, 0, 0, true)
check(d0 == 0 and r0 == 0 and w0 == 0, "seco y sin nieve: no cambia nada")
local d1, r1 = Wetness.surface(Enum.Material.Asphalt, 1, 0, true)
check(d1 > 0.1 and r1 > 0.2, "asfalto mojado: más oscuro y con reflejos")
local _, rWall = Wetness.surface(Enum.Material.Asphalt, 1, 0, false)
check(rWall < r1, "en una pared brilla menos que en el suelo")
local _, rGrass = Wetness.surface(Enum.Material.Grass, 1, 0, true)
check(rGrass < r1 * 0.5, "la hierba mojada casi no brilla")
local _, _, wRoof = Wetness.surface(Enum.Material.Slate, 0, 1, true)
local _, _, wRoad = Wetness.surface(Enum.Material.Asphalt, 0, 1, true)
local _, _, wWall = Wetness.surface(Enum.Material.Brick, 0, 1, false)
check(wRoof > 0.5 and wRoad < wRoof and wWall == 0, "nieve: tejados blancos, calzada poco, paredes nada")
check(not Wetness.canGetWet(Enum.Material.Glass, 0) and not Wetness.canGetWet(Enum.Material.Neon, 0), "el cristal y las luces no se tocan")
check(not Wetness.canGetWet(Enum.Material.Concrete, 0.8), "lo casi transparente no se toca")
check(Wetness.level(0.07) == 0 and Wetness.level(0.52) == 0.6 and Wetness.level(3) == 1, "niveles por pasos (menos repintados)")

print("Vehículos")
local dry = Wetness.grip("Coche", 0, 0)
local wet = Wetness.grip("Coche", 1, 0)
local snow = Wetness.grip("Coche", 0, 1)
check(dry == 1, "en seco, agarre completo")
check(wet < dry and snow < wet, "mojado agarra menos, y con nieve aún menos")
check(Wetness.grip("Moto", 1, 0) < wet and Wetness.grip("Bici", 0, 1) < snow, "motos y bicis resbalan más")
check(Wetness.grip("Moto", 1, 1) >= 0.2, "nunca se queda sin nada de agarre")
local roadDry, roadSnow = Wetness.drive(dry), Wetness.drive(snow)
check(roadDry.Accel == 1 and roadDry.Brake == 1 and roadDry.Turn == 1 and roadDry.MaxSpeed == 1, "en seco se conduce igual que antes")
check(roadSnow.Brake < roadSnow.Accel and roadSnow.Turn < 1 and roadSnow.MaxSpeed < 1, "con nieve: frena mucho peor, gira menos y va más despacio")
-- Derrape: gira el volante 90° de golpe y mira cuánto tarda en ir hacia allí
local function settle(grip: number): number
	local traction = Wetness.drive(grip).Traction
	local travel, yaw = 0, math.pi / 2
	local t = 0
	while math.abs(yaw - travel) > 0.1 and t < 10 do
		travel = Wetness.slide(travel, yaw, traction, 1 / 60)
		t += 1 / 60
	end
	return t
end
check(settle(1) < 0.3, ("en seco va enseguida hacia donde apunta (%.2f s)"):format(settle(1)))
check(settle(snow) > settle(1) * 3, ("con nieve derrapa (%.2f s)"):format(settle(snow)))
check(math.abs(Wetness.slide(3.1, -3.1, 10, 1 / 60) - 3.1) < 0.1, "al pasar de 180° a -180° no da la vuelta entera")

print("Personas")
local p = 0
for _ = 1, 60 do
	p = Wetness.person(p, 1, false, 0.5)
end
check(p > 0.9, "30 s bajo la lluvia: empapado")
local q = p
for _ = 1, 20 do
	q = Wetness.person(q, 1, true, 0.5)
end
check(q < p and q > 0, "a cubierto se va secando, poco a poco")
check(Wetness.person(0.5, 0, false, 1) < 0.5, "sin lluvia también se seca")

print("Personas mojadas (aspecto)")
local d0p, s0p = Wetness.look(0)
local d1p, s1p = Wetness.look(1)
check(d0p == 0 and s0p == 0, "seca: ni más oscura ni brillo")
check(d1p > 0.2 and d1p <= 0.35 and s1p > 0 and s1p <= 0.15, ("empapada: más oscura (%.2f) y un brillo sutil (%.2f)"):format(d1p, s1p))
check(select(1, Wetness.look(0.5)) < d1p, "cuanto más mojada, más oscura")
check(Wetness.drips(0.1) == 0 and Wetness.drips(0.8) > 0, "solo gotea cuando ya está bastante mojada")
-- Se moja bajo la lluvia, la llovizna moja más despacio, y se seca a cubierto y al parar
local heavy, drizzle = 0, 0
for _ = 1, 20 do
	heavy = Wetness.person(heavy, 1, false, 0.5)
	drizzle = Wetness.person(drizzle, 0.4, false, 0.5)
end
check(drizzle < heavy and drizzle > 0, ("la llovizna moja más despacio (%.2f frente a %.2f en 10 s)"):format(drizzle, heavy))
check(Wetness.person(0, 1, true, 5) == 0, "bajo techo no se moja aunque llueva")
local inside, outside = heavy, heavy
for _ = 1, 10 do
	inside = Wetness.person(inside, 1, true, 1)
	outside = Wetness.person(outside, 0, false, 1)
end
check(inside < heavy and outside < heavy and inside < outside, "dentro se seca antes que fuera al dejar de llover")

print("La lluvia se ve (v108, shared/RainLook)")
local Color3 = roblox.Color3
local function loadWith(path: string, extra: { [string]: any }): any
	local e = { Enum = Enum, Vector3 = roblox.Vector3, Color3 = Color3, UDim2 = roblox.UDim2, CFrame = roblox.CFrame }
	for k, v in extra do
		e[k] = v
	end
	return luau.load(fs.readFile(path), { debugName = path, environment = setmetatable(e, { __index = getfenv(1) }) })()
end
local RainLook = loadWith("src/shared/RainLook.luau", {})
local CONFIG = loadWith("src/shared/Config.luau", {})
local Seasons = loadWith("src/shared/Seasons.luau", {
	script = { Parent = { Config = {} } },
	require = function()
		return CONFIG
	end,
})
local DayGrade = loadWith("src/shared/DayGrade.luau", {})
local W = Seasons.Weather

-- Intensidad: «Lluvia» siempre llueve (de llovizna a chaparrón), «Tormenta» más, el resto nada
local minRain, maxRain = math.huge, 0
for h = 0, 24, 0.05 do
	local i = RainLook.intensity("Lluvia", h)
	minRain, maxRain = math.min(minRain, i), math.max(maxRain, i)
end
check(minRain >= 0.4 and maxRain <= 1 and maxRain - minRain > 0.3, ("«Lluvia»: entre llovizna y lluvia fuerte (%.2f - %.2f), nunca seco"):format(minRain, maxRain))
check(RainLook.intensity("Tormenta", 3) > 1.3, "«Tormenta»: aguacero")
local dryOk = true
for _, id in { "Despejado", "Nublado", "Nieve", "Niebla" } do
	if RainLook.intensity(id, 12) ~= 0 then
		dryOk = false
	end
end
check(dryOk, "sin lluvia en los demás tiempos: el HUD y la pantalla dicen lo mismo")
check(RainLook.kind(0) == "Seco" and RainLook.kind(0.45) == "Llovizna" and RainLook.kind(0.9) == "Lluvia" and RainLook.kind(1.6) == "Aguacero", "llovizna, lluvia y aguacero")
-- Entra y sale poco a poco
local lvl = RainLook.approach(0, 1, 1, 12)
check(lvl > 0 and lvl < 0.2, "la lluvia entra poco a poco (no de golpe)")
for _ = 1, 30 do
	lvl = RainLook.approach(lvl, 1, 0.5, 12)
end
check(lvl == 1, "y en unos segundos llueve del todo")
local leaving = RainLook.approach(1, 0, 0.5, 12)
check(leaving < 1 and leaving > 0.9, "y se va igual de suave")

-- Partículas: se ven (trazos largos, en la dirección de caída) y respetan el nivel gráfico
local low, med, high = RainLook.falling(1, "Low"), RainLook.falling(1, "Medium"), RainLook.falling(1, "High")
check(med.Squash > 0, "las gotas se estiran a lo LARGO de su caída (Squash positivo; el -3,2 de antes las aplastaba)")
check(low.Rate >= 400 and low.Rate < med.Rate and med.Rate < high.Rate, ("más gotas cuanto más nivel (%d / %d / %d)"):format(low.Rate, med.Rate, high.Rate))
check(low.Size >= high.Size and low.Size >= 0.15, ("en Bajo (móvil) las gotas son más gruesas para que se vean (%.2f)"):format(low.Size))
check(low.FarRate == 0 and high.FarRate > 0 and low.RippleRate == 0, "en Bajo sin cortina lejana ni ondas (rendimiento)")
check(RainLook.falling(1.7, "High").Rate <= 2200 and high.Rate <= 1300, "Alto: como mucho unas 1.250 gotas por segundo con lluvia fuerte")
local drizzleFall, stormFall = RainLook.falling(0.4, "Medium"), RainLook.falling(1.7, "Medium")
check(drizzleFall.Rate < med.Rate and stormFall.Rate > med.Rate and drizzleFall.Transparency > stormFall.Transparency, "llovizna: menos gotas y más tenues; aguacero: más y más densas")
check(med.Transparency <= 0.4 and med.Size >= 0.13, ("con lluvia fuerte las gotas se ven (transparencia %.2f, grosor %.2f)"):format(med.Transparency, med.Size))
local windy = RainLook.falling(1, "Medium", roblox.Vector3.new(20, 0, 0))
check(windy.Tilt.X > 20 and RainLook.falling(1, "Medium").Tilt.X == 0, "con viento la lluvia cae inclinada")
check(RainLook.falling(0, "High").Rate == 0 and RainLook.falling(0, "High").SplashRate == 0, "sin lluvia, nada")

-- El cielo con lluvia: gris y tapado (velo delante del cielo de fotos, nubes cerradas, bruma, menos luz)
local noon = DayGrade.sample(12.2)
local clear = DayGrade.weather(noon, W.Despejado, nil, 0, 0)
local rainy = DayGrade.weather(noon, RainLook.blend(W.Lluvia, W.Lluvia, 1, 1), nil, 0, 1)
local drizzly = DayGrade.weather(noon, RainLook.blend(W.Lluvia, W.Lluvia, 1, 0.4), nil, 0, 0.5)
local stormy = DayGrade.weather(noon, RainLook.blend(W.Tormenta, W.Tormenta, 1, 1.7), nil, 0, 1)
check((clear.Veil or 0) == 0 and (clear.Overcast or 0) < 0.2, "despejado: sin velo (el cielo de siempre)")
check(rainy.Veil >= 0.5 and rainy.Overcast >= 0.9, ("lluvia: cielo tapado y gris (velo %.2f)"):format(rainy.Veil))
check(drizzly.Veil > 0.15 and drizzly.Veil < rainy.Veil and stormy.Veil > rainy.Veil and stormy.Veil <= 0.85, "llovizna menos gris, tormenta más (sin tapar del todo)")
check(rainy.Cover >= 0.9 and rainy.CloudDensity > clear.CloudDensity + 0.15, ("nubes cerradas (%.2f) y gruesas"):format(rainy.Cover))
local function lum(c)
	return c.R * 0.3 + c.G * 0.59 + c.B * 0.11
end
check(lum(rainy.CloudColor) < lum(clear.CloudColor) * 0.8, "nubes de lluvia oscuras")
check(rainy.Brightness < clear.Brightness * 0.7 and rainy.Exposure < clear.Exposure, "menos sol")
check(rainy.Haze > clear.Haze + 2 and rainy.Density > clear.Density + 0.1, ("bruma y algo de niebla (Haze %.1f, Density %.2f)"):format(rainy.Haze, rainy.Density))
check(rainy.Tint.B > rainy.Tint.R and rainy.Saturation < clear.Saturation, "imagen fría y apagada")
local vc = rainy.VeilColor
check(vc ~= nil and math.abs(vc.R - vc.B) < 0.12 and lum(vc) > 0.3, "el velo es gris claro de día")
local nightRain = DayGrade.weather(DayGrade.sample(1), RainLook.blend(W.Lluvia, W.Lluvia, 1, 1), nil, 0, 1)
check(lum(nightRain.VeilColor) < lum(vc) * 0.6, "de noche el velo es oscuro (no un cielo gris brillante)")
-- Cambio de tiempo sin saltos: el cielo pasa poco a poco de despejado a lluvia
local worst, prevVeil = 0, 0
for step = 0, 20 do
	local t = step / 20
	local k = DayGrade.weather(noon, RainLook.blend(W.Despejado, W.Lluvia, t, t), nil, 0, 0)
	worst = math.max(worst, math.abs((k.Veil or 0) - prevVeil))
	prevVeil = k.Veil or 0
end
check(worst < 0.1 and prevVeil > 0.5, ("de despejado a lluvia, el cielo se cierra sin saltos (máx. %.3f por paso)"):format(worst))
check(not RainLook.blend(W.Despejado, W.Tormenta, 0.3, 0.5).Lightning and RainLook.blend(W.Despejado, W.Tormenta, 0.7, 1).Lightning, "los relámpagos llegan con la tormenta ya entrada")
check(RainLook.blend(W.Lluvia, W.Despejado, 1, 0).Rain == nil, "al acabar, sin lluvia")

-- Techo: qué tapa la lluvia y cuándo se está dentro
check(RainLook.blocksRain(0, "Concrete") and RainLook.blocksRain(0.3, "Slate"), "un tejado tapa la lluvia")
check(not RainLook.blocksRain(0, "LeafyGrass") and not RainLook.blocksRain(0, "Grass"), "las copas de los árboles no")
check(not RainLook.blocksRain(0.8, "Glass") and not RainLook.blocksRain(1, "Plastic"), "lo transparente o invisible no")
check(RainLook.enclosed(true, 4) and RainLook.enclosed(true, 3), "tejado y paredes alrededor: dentro (no llueve)")
check(RainLook.enclosed(true, 0, true), "nave o salón grande (tejado también más allá): dentro")
check(not RainLook.enclosed(true, 1, false) and not RainLook.enclosed(true, 2, false), "bajo un balcón mirando a la calle: se sigue viendo llover")
check(not RainLook.enclosed(false, 4, true), "sin tejado (patio, calle estrecha): fuera")

-- Gotas en la pantalla
check(RainLook.lensAllowed({ Intensity = 1, Roof = false }), "al aire libre con lluvia: gotas en la pantalla")
check(not RainLook.lensAllowed({ Intensity = 0, Roof = false }), "sin lluvia, ninguna")
check(not RainLook.lensAllowed({ Intensity = 1, Roof = true }), "bajo techo (o un toldo), ninguna")
check(not RainLook.lensAllowed({ Intensity = 1, Roof = false, Enclosed = true }), "dentro, ninguna")
check(not RainLook.lensAllowed({ Intensity = 1, Roof = false, Vehicle = "Coche" }) and RainLook.lensAllowed({ Intensity = 1, Roof = false, Vehicle = "Moto" }), "en coche no (tiene techo); en moto sí")
check(not RainLook.lensAllowed({ Intensity = 1, Roof = false, Cinematic = true }) and not RainLook.lensAllowed({ Intensity = 1, Roof = false, Underground = true }), "ni en las cinemáticas ni en el metro")
check(RainLook.lensFacing(0.5) > RainLook.lensFacing(0) and RainLook.lensFacing(-0.9) < 0.2, "mirando arriba más gotas; mirando al suelo casi ninguna")
local lowCount = RainLook.lensBudget(1, "Low", 1)
local highCount, highRate = RainLook.lensBudget(1.7, "High", 1)
local _, downRate = RainLook.lensBudget(1.7, "High", RainLook.lensFacing(-0.9))
check(lowCount <= 4 and highCount <= 10 and lowCount < highCount, ("sutiles: como mucho %d (Bajo) / %d (Alto) a la vez"):format(lowCount, highCount))
check(downRate < highRate * 0.3, "mirando al suelo apenas salen nuevas")
local a0 = RainLook.lensDrop(0, 3)
local aMid, sMid = RainLook.lensDrop(0.6, 3)
local aSlide, sSlide, stretch = RainLook.lensDrop(2.4, 3)
local aEnd = RainLook.lensDrop(3, 3)
check(a0 == 0 and aMid == 1 and sMid == 0, "la gota aparece y se queda quieta un momento")
check(sSlide > 0 and stretch > 1 and aSlide > 0, "luego resbala estirándose")
check(aEnd == 0, "y desaparece")

print("Charcos (v109: «son muy falsos»)")
check(RainLook.puddleSpot("Asphalt", 1, 0, true, 0.9) and RainLook.puddleSpot("Pavement", 0.999, 0.3, true, 0.9), "junto al bordillo, en calzada o acera: sí")
check(not RainLook.puddleSpot("Grass", 1, 0, true, 0) and not RainLook.puddleSpot("LeafyGrass", 1, 0, true, 0) and not RainLook.puddleSpot("Ground", 1, 0, true, 0), "nunca en la hierba ni en la tierra")
check(not RainLook.puddleSpot("Slate", 1, 0, true, 0) and not RainLook.puddleSpot("SmoothPlastic", 1, 0, true, 0), "ni en tejados ni en muebles o coches")
check(not RainLook.puddleSpot("Asphalt", 1, 6, true, 0), "ni más alto que el suelo donde estás (un tejado bajo, el techo de un coche)")
check(not RainLook.puddleSpot("Asphalt", 0.95, 0, true, 0), "ni en rampas o cuestas")
check(RainLook.puddleSpot("Asphalt", 1, 0, false, 0.1) and not RainLook.puddleSpot("Asphalt", 1, 0, false, 0.8), "en medio de la calle solo a veces (sin patrones)")
check(RainLook.puddleOpacity(0) == 0 and RainLook.puddleOpacity(0.3) == 0, "en seco o apenas mojado: sin charcos")
check(RainLook.puddleOpacity(0.6) > 0 and RainLook.puddleOpacity(0.6) < RainLook.puddleOpacity(1) and RainLook.puddleOpacity(1) == 1, "aparecen poco a poco al mojarse y se van al secarse")
local wwSrc = fs.readFile("src/client/Controllers/WetWorld.luau")
check(not wwSrc:find("PartType.Cylinder", 1, true) and not wwSrc:find("Material.Glass\n", 1, true) and wwSrc:find("Decal", 1, true) ~= nil, "charcos de borde suave (imagen difuminada), no discos de cristal")

print("Tráfico")
check(Wetness.trafficSpeed(0, 0) == 1, "en seco, a su velocidad")
check(Wetness.trafficSpeed(1, 0) < 1 and Wetness.trafficSpeed(0, 1) < Wetness.trafficSpeed(1, 0), "más despacio con lluvia y aún más con nieve")

print("")
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d comprobaciones fallidas"):format(failures))
	process.exit(1)
end
