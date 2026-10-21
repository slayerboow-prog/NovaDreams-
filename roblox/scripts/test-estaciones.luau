-- Prueba de las ESTACIONES y el TIEMPO de Valmar (v126, docs/clima/estaciones.md) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-estaciones.luau
--
-- Comprueba:
--   1. Calendario -> estación (dic-feb invierno… como dice la fecha del HUD) y el modo rápido de antes
--   2. Cambios de estación sin saltos (los días del cambio se mezclan: colores, sol, temperatura)
--   3. El servidor decide y publica (WeatherService -> atributos de workspace que ven todos), y quién
--      manda: un evento > el modo pruebas > el calendario
--   4. Probabilidad del tiempo por estación (verano seco, otoño lluvioso, nieve rara solo en invierno)
--   5. Relámpagos: nunca más de la cuenta (sin parpadeos), un destello suave, el ajuste «Destellos: no»
--   6. Mojado y secado en horas de juego, charcos que crecen y se secan después, vapor tras el verano
--   7. Solo en Valmar: nada en el espacio, los planetas ni bajo el mar; el fondo del mar no se toca
--   8. Topes de rendimiento por nivel gráfico
--   9. Escenas y la Grieta mandan sobre el tiempo; la playa, la ropa y las hojas con la estación
--  10. Sonidos nuevos (archivos, licencias, subida con --clima, reserva) y la guía para el dueño

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local task = require("@lune/task")

local ROOT = "src"
local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

---------------------------------------------------------------------
-- Roblox de mentira (workspace con atributos, Lighting, Players) y cargador script.Parent / require
---------------------------------------------------------------------
local function signal()
	local handlers = {}
	return {
		Connect = function(_, fn)
			table.insert(handlers, fn)
			return { Disconnect = function() end }
		end,
		Fire = function(_, ...)
			for _, fn in handlers do
				fn(...)
			end
		end,
	}
end

local function attributed(base: { [string]: any }): any
	local attrs, changed = {}, {}
	function base:SetAttribute(k, v)
		local before = attrs[k]
		attrs[k] = v
		if before ~= v and changed[k] then
			changed[k]:Fire()
		end
	end
	function base:GetAttribute(k)
		return attrs[k]
	end
	function base:GetAttributeChangedSignal(k)
		changed[k] = changed[k] or signal()
		return changed[k]
	end
	return base
end

local fakeWorkspace = attributed({})
local lighting = attributed({ ClockTime = 12 })
local playerList = {}
local players = { PlayerAdded = signal(), PlayerRemoving = signal() }
function players:GetPlayers()
	return playerList
end
local services = { Lighting = lighting, Players = players, Workspace = fakeWorkspace }

local nodeMeta = {}
local function node(path: string)
	return setmetatable({ __path = path }, nodeMeta)
end
nodeMeta.__index = function(self, key)
	local path = rawget(self, "__path")
	if key == "Parent" then
		return node((path:match("^(.*)/[^/]+$")))
	end
	return node(path .. "/" .. key)
end
local replicated = { Shared = node(ROOT .. "/shared") }
services.ReplicatedStorage = replicated
local fakeGame = {}
function fakeGame:GetService(name)
	return services[name] or {}
end

local emitted = {}
local mocks: { [string]: any } = {
	[ROOT .. "/server/LifeStory/StoryEvents"] = { emit = function(_, kind, data)
		table.insert(emitted, { Kind = kind, Data = data })
	end },
}
local cache: { [string]: any } = {}
local function load(path: string): any
	if mocks[path] ~= nil then
		return mocks[path]
	end
	if cache[path] ~= nil then
		return cache[path]
	end
	local env = setmetatable({
		script = node(path),
		require = function(target)
			return load(rawget(target, "__path"))
		end,
		game = fakeGame,
		workspace = fakeWorkspace,
		task = task,
		Vector3 = roblox.Vector3,
		Color3 = roblox.Color3,
		CFrame = roblox.CFrame,
		Enum = roblox.Enum,
		warn = function(...)
			print("[warn]", ...)
		end,
	}, { __index = _G })
	local file = path .. ".luau"
	local result = luau.load(fs.readFile(file), { debugName = file, environment = env })()
	cache[path] = result
	return result
end

local Config = load(ROOT .. "/shared/Config")
local Seasons = load(ROOT .. "/shared/Seasons")
local Storm = load(ROOT .. "/shared/Storm")
local Wetness = load(ROOT .. "/shared/Wetness")
local RainLook = load(ROOT .. "/shared/RainLook")
local TerrainPalette = load(ROOT .. "/shared/TerrainPalette")
local PlaceLife = load(ROOT .. "/shared/PlaceLife")
local src = function(path: string): string
	return fs.readFile(path)
end

---------------------------------------------------------------------
print("1. Calendario -> estación")
---------------------------------------------------------------------
local DPM = Config.Calendar.DaysPerMonth
local EXPECT = { "Invierno", "Invierno", "Primavera", "Primavera", "Primavera", "Verano", "Verano", "Verano", "Otono", "Otono", "Otono", "Invierno" }
local allMonths = true
for month = 1, 12 do
	local day = (month - 1) * DPM + 14
	local m = Seasons.monthOf(day)
	if m ~= month or Seasons.seasonOf(day) ~= EXPECT[month] then
		allMonths = false
		print(("    mes %d: %s (esperaba %s)"):format(month, Seasons.seasonOf(day), EXPECT[month]))
	end
end
check(Config.Seasons.Mode == "Calendario" and Seasons.calendarMode(), "por defecto las estaciones van con el calendario (Config.Seasons.Mode)")
check(allMonths, "dic, ene y feb invierno; mar-may primavera; jun-ago verano; sep-nov otoño (mediterráneo)")
check(Seasons.seasonOf(6) == "Invierno" and select(1, Seasons.monthOf(6)) == 1, "«sáb 6 ene» (día 6, lo que enseña el HUD): invierno")
check(Seasons.seasonOf(12 * DPM + 1) == "Invierno" and Seasons.seasonOf(12 * DPM + 5 * DPM + 3) == Seasons.seasonOf(5 * DPM + 3), "el segundo año se repite igual")
check(Seasons.festive(6) and not Seasons.festive(7) and Seasons.festive(11 * DPM + 1) and not Seasons.festive(10 * DPM + 27), "luces de fiesta del 1 de diciembre al 6 de enero")
check(Seasons.daysLeft(56) == 1 and Seasons.daysLeft(57) == 3 * DPM, "el invierno acaba el último día de febrero; la primavera dura tres meses")
do
	local saved = Config.Seasons.Mode
	Config.Seasons.Mode = "Rapido"
	check(Seasons.seasonOf(1) == "Primavera" and Seasons.seasonOf(8) == "Verano" and Seasons.seasonOf(15) == "Otono" and Seasons.seasonOf(22) == "Invierno" and Seasons.seasonOf(29) == "Primavera", "modo «Rapido»: el ciclo de antes, una estación por semana de juego")
	check(Seasons.festive(22) and not Seasons.festive(1), "(en el rápido, las luces van con el invierno)")
	Config.Seasons.Mode = saved
end
check(src(ROOT .. "/shared/Config.luau"):find("Config.DayLengthMinutes = 20", 1, true) ~= nil, "la duración del día no cambia (Config.DayLengthMinutes = 20)")

---------------------------------------------------------------------
print("2. Cambios de estación sin saltos")
---------------------------------------------------------------------
local function seen(day: number, hour: number, key: string): number
	local a, b, t = Seasons.blendAt(day, hour)
	return Seasons.mixValue(a, b, t, key)
end
local worstLat, worstTemp = 0, 0
local prevLat, prevTemp = seen(1, 0, "Latitude"), nil
for day = 1, 12 * DPM do
	for hour = 0, 23 do
		if not (day == 1 and hour == 0) then
			local lat = seen(day, hour, "Latitude")
			worstLat = math.max(worstLat, math.abs(lat - prevLat))
			prevLat = lat
		end
	end
	local a, b, t = Seasons.blendAt(day, 15)
	local temp = Seasons.temperature(a, "Despejado", 15, b, t)
	if prevTemp then
		worstTemp = math.max(worstTemp, math.abs(temp - prevTemp))
	end
	prevTemp = temp
end
check(worstLat < 0.2, ("la altura del sol cambia poco a poco (como mucho %.3f° por hora)"):format(worstLat))
check(worstTemp <= 1, ("la máxima del día cambia como mucho %d °C de un día al siguiente (sin saltos al cambiar de estación)"):format(worstTemp))
local a1, b1, t1 = Seasons.blendAt(56, 23.9)
local a2, b2, t2 = Seasons.blendAt(57, 0)
check(a1 == "Invierno" and b1 == "Primavera" and t1 > 0.48 and a2 == "Primavera" and b2 == "Invierno" and t2 > 0.48, "el último día de febrero y el primero de marzo se ven igual (mitad y mitad)")
local am, _, tm = Seasons.blendAt(4 * DPM + 14, 12)
check(am == "Primavera" and tm == 0, "en medio de la estación, la estación entera")
local _, _, tEdge = Seasons.blendAt(57 + Seasons.blendDays(84) + 1, 12)
check(tEdge == 0 and Seasons.blendDays(84) >= 5, ("la mezcla dura %d días a cada lado del cambio"):format(Seasons.blendDays(84)))

---------------------------------------------------------------------
print("3. El servidor decide y lo publica para todos (WeatherService -> workspace)")
---------------------------------------------------------------------
local Weather = load(ROOT .. "/server/Services/WeatherService")
fakeWorkspace:SetAttribute("Day", 6)
lighting.ClockTime = 12
Weather.step()
check(fakeWorkspace:GetAttribute("Season") == "Invierno" and fakeWorkspace:GetAttribute("Festive") == true, "6 de enero: publica «Invierno» y las luces de fiesta")
check(type(fakeWorkspace:GetAttribute("SeasonBlend")) == "number" and Seasons.Info[fakeWorkspace:GetAttribute("SeasonNext")] ~= nil, "publica la estación vecina y cuánto se mezcla (SeasonNext / SeasonBlend)")
check(Seasons.Weather[fakeWorkspace:GetAttribute("Weather")] ~= nil, "publica un tiempo que existe: " .. tostring(fakeWorkspace:GetAttribute("Weather")))
fakeWorkspace:SetAttribute("Day", 5 * DPM + 14)
Weather.step()
check(fakeWorkspace:GetAttribute("Season") == "Verano" and fakeWorkspace:GetAttribute("Festive") == false, "en junio, verano (y sin luces)")
local seasonEvents = 0
for _, e in emitted do
	if e.Kind == "SeasonChanged" then
		seasonEvents += 1
	end
end
check(seasonEvents == 0, "(sin jugadores no se avisa a nadie)")
Weather.force("Lluvia", "Tester")
check(fakeWorkspace:GetAttribute("Weather") == "Lluvia" and tostring(fakeWorkspace:GetAttribute("ClimaForzado")):find("pruebas", 1, true) ~= nil, "modo pruebas: fuerza la lluvia para todos (y se ve que está forzada)")
Weather.force("Tormenta")
check(fakeWorkspace:GetAttribute("Weather") == "Tormenta", "un evento del mundo (la tormenta del mar) manda sobre el modo pruebas")
Weather.force(nil)
check(fakeWorkspace:GetAttribute("Weather") == "Lluvia", "al acabar el evento vuelve lo del modo pruebas")
Weather.force(nil, "Tester")
check(fakeWorkspace:GetAttribute("ClimaForzado") == nil, "«Auto»: vuelve el tiempo del calendario")
Weather.forceSeason("Otono")
check(fakeWorkspace:GetAttribute("Season") == "Otono" and fakeWorkspace:GetAttribute("SeasonBlend") == 0, "forzar el otoño en junio (para probar)")
Weather.forceSeason("Verano")
local snowy = false
for day = 1, 60 do
	for hour = 0, 23, 6 do
		local _, w = Weather.decide(day, hour + 0.5)
		snowy = snowy or w == "Nieve"
	end
end
check(not snowy, "con el verano forzado no nieva nunca")
Weather.forceSeason(nil)
-- El cliente lo lee de esos atributos (y el HUD también)
local weatherClient = src(ROOT .. "/client/Controllers/Weather.luau")
check(weatherClient:find('{ "Season", "Weather", "Snow", "SeasonNext", "SeasonBlend", "Wet" }', 1, true) ~= nil, "el cliente pinta lo que publica el servidor (Season, SeasonNext, SeasonBlend, Weather, Snow, Wet)")
check(src(ROOT .. "/client/UI/Hud.luau"):find('Seasons.temperature(season, weather, clock, workspace:GetAttribute("SeasonNext"), workspace:GetAttribute("SeasonBlend"))', 1, true) ~= nil, "la temperatura del HUD sigue la estación (mezclada)")
check(src(ROOT .. "/client/Controllers/Relampagos.luau"):find('GetAttributeChangedSignal("Rayo")', 1, true) ~= nil, "los rayos llegan del servidor (atributo Rayo): todos ven el mismo")

---------------------------------------------------------------------
print("4. El tiempo de cada estación")
---------------------------------------------------------------------
local counts: { [string]: { [string]: number } } = {}
local totals: { [string]: number } = {}
for day = 1, 3 * 12 * DPM do
	for hour = 0, 23, 6 do
		local season = Seasons.seasonOf(day)
		local _, w = Weather.decide(day, hour + 0.5)
		counts[season] = counts[season] or {}
		counts[season][w] = (counts[season][w] or 0) + 1
		totals[season] = (totals[season] or 0) + 1
	end
end
local function share(season: string, ...: string): number
	local n = 0
	for _, w in { ... } do
		n += counts[season][w] or 0
	end
	return n / totals[season]
end
check(share("Verano", "Despejado", "Intervalos") >= 0.7, ("verano: casi siempre sol (%.0f %%)"):format(share("Verano", "Despejado", "Intervalos") * 100))
check(share("Verano", "Tormenta") > share("Verano", "Lluvia"), "verano: más tormentas de tarde que lluvia")
check(share("Otono", "Lluvia", "Tormenta", "Nublado") >= 0.4, ("otoño: nubes y lluvia (%.0f %%)"):format(share("Otono", "Lluvia", "Tormenta", "Nublado") * 100))
check(share("Otono", "Lluvia") > share("Verano", "Lluvia") * 3, "en otoño llueve mucho más que en verano")
local snowShare = share("Invierno", "Nieve")
check(snowShare > 0 and snowShare <= 0.06, ("invierno: nieve rara (%.1f %% de los ratos), la isla es mediterránea"):format(snowShare * 100))
check(share("Invierno", "Lluvia") > snowShare * 3, "invierno: llueve mucho más que nieva")
check((counts.Primavera.Nieve or 0) + (counts.Verano.Nieve or 0) + (counts.Otono.Nieve or 0) == 0, "fuera del invierno no nieva nunca")
check(Seasons.weatherAt(40, 13) == Seasons.weatherAt(40, 13), "el mismo tiempo para todos los servidores (no es al azar en cada uno)")
local hot = Seasons.temperature("Verano", "Despejado", 15)
local cold = Seasons.temperature("Invierno", "Despejado", 5)
check(hot >= 30 and cold <= 6 and Seasons.temperature("Invierno", "Nieve", 15) <= 1, ("temperaturas: verano %d °C por la tarde, invierno %d °C de madrugada; si nieva, ≤ 1 °C"):format(hot, cold))
check(Seasons.temperature("Verano", "Tormenta", 15) < hot and Seasons.temperature("Primavera", "Despejado", 15) < hot, "la lluvia refresca y la primavera es más suave")

---------------------------------------------------------------------
print("5. Relámpagos sin parpadeos")
---------------------------------------------------------------------
Storm.configure(Config.Seasons.Lightning)
local history, strikes = {}, {}
for i = 0, 6000 do
	local now = i * 0.1
	if Storm.allow(history, now) then
		Storm.record(history, now)
		table.insert(strikes, now)
	end
end
local minGap, perMinute = math.huge, 0
for i = 2, #strikes do
	minGap = math.min(minGap, strikes[i] - strikes[i - 1])
end
for _, at in strikes do
	local n = 0
	for _, other in strikes do
		if other >= at and other < at + 60 then
			n += 1
		end
	end
	perMinute = math.max(perMinute, n)
end
check(minGap >= Storm.MinGap - 1e-6 and perMinute <= Storm.MaxPerMinute, ("aunque se pidan sin parar: nunca dos rayos a menos de %d s ni más de %d por minuto"):format(Storm.MinGap, Storm.MaxPerMinute))
Storm.configure({ MinGap = 1, MaxPerMinute = 50 })
check(Storm.MinGap >= 4 and Storm.MaxPerMinute <= 8, "aunque se configure mal, nunca menos de 4 s entre rayos ni más de 8 por minuto")
Storm.configure(Config.Seasons.Lightning)
check(Storm.pulses(true) <= 2 and Storm.pulses(false) == 1, ("cada fogonazo: un destello (cerca, como mucho %d)"):format(Storm.pulses(true)))
check(Storm.flash(0.04, true, false) == 0 and Storm.flash(0.04, true, true) > 0.9 and Storm.flash(Storm.FlashSeconds + 0.01, true, true) == 0, "con «Destellos de relámpago: no» no hay fogonazo; con sí, se apaga en menos de medio segundo")
check(Storm.flash(0.04, false, true) < Storm.flash(0.04, true, true), "un rayo lejano ilumina menos que uno cerca")
check(math.abs(Storm.thunderDelay(1225) - 1) < 1e-6 and Storm.thunderDelay(4900) > 3.9, "el trueno llega más tarde cuanto más lejos (343 m/s: 1.225 studs por segundo)")
check(select(1, Storm.thunder(400)) == "Near" and select(1, Storm.thunder(4000)) == "Far" and select(2, Storm.thunder(400)) > select(2, Storm.thunder(4000)), "cerca, el «crac» fuerte; lejos, el retumbar flojo")
local near, far, nearMax, farMin = 0, 0, 0, math.huge
for i = 1, 1000 do
	local s = Storm.strike(((i * 0.6180339) % 1), ((i * 0.41421) % 1), ((i * 0.7320508) % 1))
	if s.Near then
		near += 1
		nearMax = math.max(nearMax, s.Distance)
	else
		far += 1
		farMin = math.min(farMin, s.Distance)
	end
end
check(near > 50 and near < 300 and far > near and nearMax <= 900 and farMin >= 2000, ("la mayoría caen lejos (≥ 2.000 studs) y algunos cerca (≤ 900): %d de 1.000"):format(near))
local decoded = Storm.decode(Storm.encode(7, -1234.6, 88.2, true, 4242))
check(decoded and decoded.N == 7 and decoded.X == -1235 and decoded.Near == true and decoded.Seed == 4242 and Storm.decode("hola") == nil, "el atributo Rayo se lee bien (y lo raro se ignora)")
-- El servidor con una tormenta de 10 minutos
Weather.force("Tormenta", "Tester")
local rayos, lastRayo, gaps = 0, nil, math.huge
local times = {}
for i = 0, 1200 do
	local now = 1000 + i * 0.5
	local before = fakeWorkspace:GetAttribute("Rayo")
	Weather._lightningTick("Tormenta", 15, now)
	local after = fakeWorkspace:GetAttribute("Rayo")
	if after ~= before then
		rayos += 1
		table.insert(times, now)
		if lastRayo then
			gaps = math.min(gaps, now - lastRayo)
		end
		lastRayo = now
	end
end
check(rayos >= 20 and rayos <= 60 and gaps >= Storm.MinGap, ("tormenta de 10 minutos: %d rayos, el más seguido a %.1f s del anterior"):format(rayos, gaps))
Weather._lightningTick("Despejado", 15, 2000)
local quiet = fakeWorkspace:GetAttribute("Rayo")
Weather._lightningTick("Despejado", 15, 2100)
check(fakeWorkspace:GetAttribute("Rayo") == quiet, "sin tormenta, ningún rayo")
Weather.force(nil, "Tester")
-- El ajuste en el menú
local mainSrc = src(ROOT .. "/client/Main.client.luau")
local settingsSrc = src(ROOT .. "/server/Services/SettingsService.luau")
check(mainSrc:find("⚡ Destellos de relámpago: sí", 1, true) ~= nil and mainSrc:find('remote:FireServer("Set", "Flashes", nextValue)', 1, true) ~= nil, "Ajustes: «⚡ Destellos de relámpago: Sí/No» (se guarda con los ajustes)")
check(src(ROOT .. "/client/Commands/SettingsRows.luau"):find('["Destellos de relámpago"]', 1, true) ~= nil, "sale como interruptor en la app Ajustes (Pantalla)")
check(settingsSrc:find("SettingsService.setFlashes", 1, true) ~= nil and settingsSrc:find('type(value) ~= "boolean"', 1, true) ~= nil, "el servidor solo acepta sí o no")
check(src(ROOT .. "/client/Controllers/Relampagos.luau"):find('player:GetAttribute("LightningFlashes") ~= false', 1, true) ~= nil, "los rayos miran el ajuste")

---------------------------------------------------------------------
print("6. Mojarse y secarse en horas de juego")
---------------------------------------------------------------------
local wet, pud = 0, 0
for _ = 1, 35 do
	wet, pud = Wetness.water(wet, pud, 1, 0.01, 2)
end
check(wet >= 0.99 and pud < 0.4, ("con lluvia fuerte todo está empapado en ~%.2f h de juego; los charcos aún pequeños (%.2f)"):format(Wetness.WetHours, pud))
for _ = 1, 130 do
	wet, pud = Wetness.water(wet, pud, 1, 0.01, 2)
end
check(pud >= 0.99, "tras mucho llover los charcos llegan a su tamaño (crecen poco a poco)")
local function hoursToDry(season: string, weather: string, clock: number): (number, number)
	local w, p, h, dryAt = 1, 1, 0, nil
	while (w > 0 or p > 0) and h < 30 do
		w, p = Wetness.water(w, p, 0, 0.05, Wetness.dryHours(season, weather, clock))
		h += 0.05
		if w <= 0 and not dryAt then
			dryAt = h
		end
	end
	return dryAt or h, h
end
local summerDry, summerPuddles = hoursToDry("Verano", "Despejado", 13)
local winterDry = hoursToDry("Invierno", "Despejado", 13)
local nightDry = hoursToDry("Verano", "Despejado", 2)
check(summerDry > 1 and summerDry < 2, ("verano con sol: el suelo se seca en %.1f h de juego (~%d s reales)"):format(summerDry, math.floor(summerDry * Config.DayLengthMinutes * 60 / 24)))
check(winterDry > summerDry * 2.5, ("invierno: tarda mucho más (%.1f h)"):format(winterDry))
check(nightDry > summerDry and hoursToDry("Verano", "Nublado", 13) > summerDry, "de noche o nublado se seca más despacio")
check(summerPuddles > summerDry, ("los charcos se secan después que el suelo (%.1f h)"):format(summerPuddles))
check(Wetness.puddleScale(0) < Wetness.puddleScale(1) and Wetness.puddleScale(1) <= 1.35, "los charcos crecen con el agua (sin pasarse)")
check(Wetness.steam("Verano", "Despejado", 0.7, 14) > 0.5 and Wetness.steam("Invierno", "Despejado", 0.7, 14) == 0 and Wetness.steam("Verano", "Lluvia", 0.7, 14) == 0 and Wetness.steam("Verano", "Despejado", 0.7, 23) == 0, "vapor tras la lluvia de verano: de día, con sol y el suelo mojado")
-- El servidor, con el reloj de verdad: se moja con la lluvia y se seca al salir el sol
fakeWorkspace:SetAttribute("Wet", 0)
fakeWorkspace:SetAttribute("Puddles", 0)
fakeWorkspace:SetAttribute("Day", 5 * DPM + 14)
lighting.ClockTime = 12
Weather.force("Lluvia", "Tester")
Weather._waterTick()
for _ = 1, 40 do
	lighting.ClockTime += 0.02
	Weather._waterTick()
end
local wetAfterRain = fakeWorkspace:GetAttribute("Wet")
check(wetAfterRain > 0.5, ("WeatherService: con 0,8 h de lluvia el suelo se moja (Wet %.2f)"):format(wetAfterRain))
Weather.force("Despejado", "Tester")
Weather.step()
for _ = 1, 20 do
	lighting.ClockTime += 0.02
	Weather._waterTick()
end
local wetLater = fakeWorkspace:GetAttribute("Wet")
check(wetLater < wetAfterRain and wetLater > 0, ("y al salir el sol se va secando poco a poco (Wet %.2f)"):format(wetLater))
lighting.ClockTime = 6 -- (un salto del reloj hacia atrás: no se seca ni se moja de golpe)
Weather._waterTick()
check(math.abs(fakeWorkspace:GetAttribute("Wet") - wetLater) < 0.001, "un salto del reloj hacia atrás no cambia nada")
Weather.force(nil, "Tester")
local wetSrc = src(ROOT .. "/client/Controllers/WetWorld.luau")
check(wetSrc:find('workspace:GetAttribute("Puddles")', 1, true) ~= nil and wetSrc:find("Wetness.puddleScale(water)", 1, true) ~= nil, "WetWorld: los charcos crecen y se secan con el agua de los charcos")

---------------------------------------------------------------------
print("7. Solo en Valmar (ni espacio, ni planetas, ni bajo el mar) y el fondo del mar intacto")
---------------------------------------------------------------------
local touched = {}
for name in TerrainPalette.Seasonal do
	touched[name] = true
end
for name in TerrainPalette.Wettable do
	touched[name] = true
end
local seaOk = true
for name in TerrainPalette.Sea do
	if touched[name] or TerrainPalette.weatherMay(name) then
		seaOk = false
	end
end
check(seaOk and not TerrainPalette.weatherMay("Water") and not TerrainPalette.weatherMay("Rock"), "el tiempo nunca toca los materiales del fondo del mar (Salt, Sandstone, Limestone, Mud, Basalt) ni el agua")
check(TerrainPalette.weatherMay("Grass") and TerrainPalette.weatherMay("LeafyGrass") and TerrainPalette.weatherMay("Ground"), "solo la hierba y la tierra de Valmar cambian con la estación y la lluvia")
check(weatherClient:find("if not TerrainPalette.weatherMay(material.Name) then", 1, true) ~= nil and weatherClient:find("local function terrainHere(): boolean", 1, true) ~= nil and weatherClient:find('zone ~= "Valmar"', 1, true) ~= nil, "Weather pinta el terreno solo con la cámara en Valmar y solo esos materiales")
local calls = 0
for _ in weatherClient:gmatch("SetMaterialColor") do
	calls += 1
end
check(calls == 1, "(una sola llamada a SetMaterialColor en Weather, la vigilada)")
check(not TerrainPalette.inValmar(roblox.Vector3.new(-25000, 0, 25000)) and TerrainPalette.inValmar(roblox.Vector3.new(0, 10, 0)), "Tefra y los planetas quedan fuera de Valmar")
check(weatherClient:find('or not envAllows("Weather")', 1, true) ~= nil, "la lluvia y la nieve preguntan a EnvDirector (espacio, planetas, bajo el mar: nada)")
check(weatherClient:find('if envAllows("Weather") then', 1, true) ~= nil, "la altura del sol de la estación, solo en Valmar")
local relSrc = src(ROOT .. "/client/Controllers/Relampagos.luau")
check(relSrc:find('allows("Weather")', 1, true) ~= nil and relSrc:find("at.Y < Metro.Underground", 1, true) ~= nil, "rayos: solo en Valmar; en el metro solo el trueno apagado")
local decorSrc = src(ROOT .. "/client/Controllers/SeasonDecor.luau")
check(decorSrc:find('allows("Weather")', 1, true) ~= nil and decorSrc:find("TerrainPalette.inValmar(at)", 1, true) ~= nil and decorSrc:find("at.Y > Metro.Underground", 1, true) ~= nil, "goteo, vapor y luces de fiesta: solo en Valmar, nunca en el metro")
do
	local EnvZones = load(ROOT .. "/shared/Cosmos/EnvZones")
	local okSpace, spaceFlags = pcall(EnvZones.flags, { Zone = "Espacio", Space = 1, PlanetMix = 0, Under = 0 })
	local okSea, seaFlags = pcall(EnvZones.flags, { Zone = "Submarino", Space = 0, PlanetMix = 0, Under = 1 })
	check(okSpace and spaceFlags.Weather == false, "EnvZones: en el espacio, sin tiempo de Valmar")
	check(okSea and seaFlags.Weather == false, "EnvZones: bajo el mar, sin lluvia ni rayos")
end
check(src(ROOT .. "/server/Services/WeatherService.luau"):find('player:GetAttribute("Planeta") == nil', 1, true) ~= nil, "los rayos «cerca» caen junto a alguien que esté en Valmar (no en un planeta)")

---------------------------------------------------------------------
print("8. Topes de rendimiento (móvil)")
---------------------------------------------------------------------
local B = Wetness.Budget
check(B.Low.Drips <= B.Medium.Drips and B.Medium.Drips <= B.High.Drips and B.High.Drips <= 5, ("goteo: %d / %d / %d líneas (Bajo / Medio / Alto)"):format(B.Low.Drips, B.Medium.Drips, B.High.Drips))
check(decorSrc:find("local MAX_DRIPS = " .. B.High.Drips, 1, true) ~= nil, "las piezas del goteo se crean una vez (tantas como el tope de Alto) y se reutilizan")
check(B.Low.Steam <= B.High.Steam and B.High.Steam <= 15 and B.High.Bulbs <= 128 and B.Low.Bulbs <= 48, "vapor y bombillas: pocos en Bajo, con tope en Alto")
check(relSrc:find("local POOL = 24", 1, true) ~= nil and relSrc:find('if tier == "Low" then 0', 1, true) ~= nil, "rayo: como mucho 24 piezas reutilizadas; en Bajo sin ramas")
check(weatherClient:find("n % 1500 == 0", 1, true) ~= nil, "las copas se repintan en trozos (sin congelar la pantalla)")
local mixOk = true
for _, where in { "Fuera", "Toldo", "Coche", "Metro" } do
	for level = 0, 1.7, 0.1 do
		local m = RainLook.rainMix(level, where)
		if m.Bed + m.Heavy + m.Roof + m.Car > 1.0001 then
			mixOk = false
		end
	end
end
check(mixOk, "el sonido de la lluvia nunca suena más que la lluvia de siempre (las partes suman ≤ 1)")
local inCar, out = RainLook.rainMix(1, "Coche"), RainLook.rainMix(1.5, "Fuera")
check(inCar.Car > inCar.Bed and out.Heavy > 0 and RainLook.rainMix(1, "Metro").Bed == 0 and RainLook.rainMix(1, "Toldo").Roof > 0, "en el coche, el techo; en la calle con aguacero, el chaparrón; bajo un toldo, el tamborileo; en el metro, nada")

---------------------------------------------------------------------
print("9. Escenas y Grieta mandan; playa, ropa y hojas con la estación")
---------------------------------------------------------------------
check(RainLook.storyHold({}) == 0 and RainLook.storyHold({ StoryClock = 1 }) == 1, "una escena con su cielo aparta el tiempo de Valmar")
check(RainLook.storyHold({ GrietaCielo = 0.5 }) == 0 and RainLook.storyHold({ GrietaCielo = 1 }) == 1, "la Grieta solo cuando está muy abierta (la de todo el día no quita la lluvia)")
check(RainLook.storyHold({ AirArena = 1 }) == 0, "(la arena de combate no cuenta: allí no hay tiempo de Valmar)")
check(weatherClient:find("DayGrade.mix(out, k, hold)", 1, true) ~= nil and relSrc:find('player:GetAttribute("InScene") == true', 1, true) ~= nil, "con una escena el cielo vuelve al de la escena y no caen rayos")
check(src(ROOT .. "/server/Services/SeaEventService.luau"):find('WeatherService.force("Tormenta")', 1, true) ~= nil, "la tormenta del mar (evento) sigue forzando el tiempo y manda sobre el modo pruebas")
local summerBeach = PlaceLife.amount("Playa", 13, "Despejado", 3, nil, Seasons.beach("Verano"))
local winterBeach = PlaceLife.amount("Playa", 13, "Despejado", 3, nil, Seasons.beach("Invierno"))
check(summerBeach > winterBeach * 3 and winterBeach <= 2, ("playa: %d personas en verano, %d en invierno"):format(summerBeach, winterBeach))
check(PlaceLife.amount("Parque", 13, "Despejado", 3, nil, Seasons.beach("Invierno")) == PlaceLife.amount("Parque", 13, "Despejado", 3), "el parque no cambia con la estación (solo la playa)")
local coats, shorts, summerCoats = 0, 0, 0
for i = 1, 100 do
	local w = Seasons.dress("Invierno", (i - 0.5) / 100)
	local s = Seasons.dress("Verano", (i - 0.5) / 100)
	coats += if w.Coat then 1 else 0
	shorts += if s.ShortSleeves then 1 else 0
	summerCoats += if s.Coat then 1 else 0
end
check(summerCoats == 0, "en verano nadie lleva abrigo")
check(coats >= 70 and shorts >= 70, ("ropa: %d de 100 con abrigo en invierno, %d en manga corta en verano"):format(coats, shorts))
check(src(ROOT .. "/client/Controllers/Ambient.luau"):find("seasonWear(agent)", 1, true) ~= nil, "los peatones se visten con la estación al salir a la calle")
local autumn = {}
local blossoms = 0
for i = 1, 40 do
	local f = Seasons.foliage("Otono", nil, 0, (i - 0.5) / 40)
	autumn[tostring(f.Color)] = true
	if Seasons.foliage("Primavera", nil, 0, (i - 0.5) / 40).Blossom then
		blossoms += 1
	end
end
local kinds = 0
for _ in autumn do
	kinds += 1
end
check(kinds >= 3, ("otoño: cada árbol de su color (%d tonos: amarillo, naranja, rojo…)"):format(kinds))
check(blossoms > 5 and blossoms < 30, ("primavera: algunos árboles en flor (%d de 40)"):format(blossoms))
check(Seasons.foliage("Invierno", nil, 0, 0.5).Bare > 0.3 and Seasons.foliage("Verano", nil, 0, 0.5).Bare == 0, "invierno: copas apagadas y peladas")
local mid = Seasons.foliage("Verano", "Otono", 0.25, 0.3)
check(mid.Mix > Seasons.foliage("Verano", nil, 0, 0.3).Mix, "llegando el otoño las copas empiezan a cambiar poco a poco")
check(Seasons.latitude("Verano") < Seasons.latitude("Invierno"), "el sol va más alto en verano que en invierno")
check(weatherClient:find("seasonBlend >= 0.35", 1, true) ~= nil and weatherClient:find("nearTrees", 1, true) ~= nil, "hojas que caen cerca de los árboles (y ya llegando el otoño)")

---------------------------------------------------------------------
print("10. Sonidos nuevos y la guía")
---------------------------------------------------------------------
local files = Config.Seasons.SoundFiles
local licencias = src("audio/LICENCIAS.md")
local upload = src("scripts/upload-audio.sh")
local missing = {}
for _, key in { "RainLight", "RainHeavy", "RainRoof", "RainCar", "ThunderNear", "ThunderFar", "WindStorm" } do
	local file = files[key]
	local path = "audio/sfx/" .. tostring(file) .. ".ogg"
	if not file or not fs.isFile(path) or #fs.readFile(path) > 150 * 1024 or not licencias:find(file .. ".ogg", 1, true) or not upload:find(file, 1, true) then
		table.insert(missing, key)
	end
	local fallback = Config.Seasons.SoundFallback[key]
	if not fallback or not files[fallback] or not fs.isFile("audio/sfx/" .. files[fallback] .. ".ogg") then
		table.insert(missing, key .. " (reserva)")
	end
end
check(#missing == 0, "lluvia suave/fuerte, tejado, coche, trueno cerca/lejos y viento de tormenta: archivo pequeño, licencia, subida y reserva " .. table.concat(missing, ", "))
check(upload:find("--clima) CLIMA=1", 1, true) ~= nil, "upload-audio.sh --clima sube solo estos")
check(fs.isFile("scripts/audio/clima.py"), "hechos por código (scripts/audio/clima.py)")
check(weatherClient:find('SoundFx.group("Ambience")', 1, true) ~= nil, "todo en el control 🌳 Ambiente")
local doc = if fs.isFile("docs/clima/estaciones.md") then src("docs/clima/estaciones.md") else ""
check(doc:find("/estacion", 1, true) ~= nil and doc:find("/clima", 1, true) ~= nil and doc:find("captura", 1, true) ~= nil, "docs/clima/estaciones.md: cómo forzar cada estación y tiempo y qué capturas hacer")

print()
if failures == 0 then
	print("✅ Todo correcto")
	process.exit(0)
else
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
