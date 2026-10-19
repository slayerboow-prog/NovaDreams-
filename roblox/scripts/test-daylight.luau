-- Prueba del horario del día y la noche (shared/DayCycle, GameClock, DayGrade) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-daylight.luau
--
-- Queja del dueño (v120): a las 18:02 ya era noche cerrada y oscurecía desde las 17:30. Ahora es un
-- verano de España. Comprueba que:
--   * a las 18:00 y a las 21:00 es pleno día (el sol arriba, la luz de DayGrade de día);
--   * de 21:30 a 22:00 atardece poco a poco (la media hora entera, sin saltos);
--   * a las 22:00 (y no antes) y a las 03:00 es noche cerrada;
--   * amanece de 7:00 a 8:00 (a las 8:00 es pleno día);
--   * las farolas, las ventanas, los faros, los grillos y los avisos de noche siguen la MISMA curva y
--     no se encienden antes del atardecer;
--   * GameClock: Lighting.ClockTime es la hora del sol y GameClock.hour() la del juego (el HUD);
--   * ningún sistema lee Lighting.ClockTime como si fuera la hora del juego;
--   * la Grieta del cielo tiñe de violeta pero de día sigue siendo de día.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")

local check = L.check

local DayCycle = L.load("src/shared/DayCycle")
local GameClock = L.load("src/shared/GameClock")
local DayGrade = L.load("src/shared/DayGrade")
local SkyMoods = L.load("src/shared/SkyMoods")
local Config = L.load("src/shared/Config")

local function hm(h: number): string
	h %= 24
	return ("%02d:%02d"):format(math.floor(h), math.floor((h % 1) * 60 + 0.5) % 60)
end
local function look(gameHour: number)
	return DayGrade.sample(DayCycle.sunTime(gameHour))
end
local NIGHT = DayGrade.Keys[1].Key

---------------------------------------------------------------------
print("El reloj: hora del juego -> hora del sol")
---------------------------------------------------------------------
check(Config.DayLengthMinutes == 20, "el día sigue durando 20 minutos reales")
local monotone, inverse = true, true
local prev = DayCycle.sunTime(DayCycle.FirstLight)
for minute = 1, 24 * 60 do
	local h = (DayCycle.FirstLight + minute / 60) % 24
	local s = DayCycle.sunTime(h)
	local step = (s - prev) % 24
	if step <= 0 or step > 0.2 then
		monotone = false
		print("    " .. hm(h) .. " salto " .. step)
	end
	prev = s
	local back = DayCycle.gameTime(s)
	local d = math.abs(back - h) % 24
	if math.min(d, 24 - d) > 1e-6 then
		inverse = false
		print("    " .. hm(h) .. " -> " .. s .. " -> " .. back)
	end
end
check(monotone, "el sol siempre avanza, sin saltos (ni para atrás)")
check(inverse, "gameTime deshace sunTime minuto a minuto (el HUD enseña la hora del juego)")
check(math.abs(DayCycle.sunTime(22) - 19.9) < 1e-9 and math.abs(DayCycle.sunTime(21.5) - 17.45) < 1e-9, "21:30 del juego = el sol aún dorado (17,45); 22:00 = noche (19,9)")
local noon = DayCycle.gameTime(12.5)
check(noon > 14 and noon < 14.6, "el sol está en lo más alto hacia las " .. hm(noon) .. " (como en España en verano)")

do
	local row = {}
	for _, h in { 5, 6.5, 7, 7.5, 8, 12, 14.5, 18, 20.5, 21, 21.5, 21.75, 21.9, 22, 3 } do
		table.insert(row, ("%s→%s %.2f/%.2f"):format(hm(h), hm(DayCycle.sunTime(h)), look(h).Brightness, DayCycle.darkness(h)))
	end
	check(true, "juego→sol luz/oscuridad: " .. table.concat(row, " · "))
end

---------------------------------------------------------------------
print("Pleno día hasta las 21:30")
---------------------------------------------------------------------
for _, h in { 9, 12, 15, 18, 18.04, 20, 21 } do
	local k = look(h)
	check(DayCycle.darkness(h) == 0 and DayGrade.nightness(k) == 0 and k.Brightness >= 2.6 and DayCycle.sunTime(h) < 17.5, ("%s: de día (luz %.2f, sol a las %s)"):format(hm(h), k.Brightness, hm(DayCycle.sunTime(h))))
end
local golden = look(20.75)
check(golden.Glare >= 0.5 and golden.Tint.B < golden.Tint.R - 0.2 and DayGrade.nightness(golden) == 0, "20:30-21:30: hora dorada (luz cálida, todavía de día)")

---------------------------------------------------------------------
print("El atardecer: de 21:30 a 22:00, poco a poco")
---------------------------------------------------------------------
local lastDark, lastBright, smoothOk = -1, math.huge, true
local maxStep = 0
for minute = 0, 30 do
	local h = 21.5 + minute / 60
	local d = DayCycle.darkness(h)
	if d < lastDark then
		smoothOk = false
	end
	maxStep = math.max(maxStep, d - math.max(lastDark, 0))
	lastDark = d
end
check(smoothOk and maxStep < 0.1, ("la oscuridad sube sin saltos (como mucho %.3f por minuto de juego)"):format(maxStep))
check(DayCycle.darkness(21.5) == 0 and DayCycle.darkness(21.5 + 1 / 60) > 0, "empieza a las 21:30 (no antes)")
check(DayCycle.darkness(21 + 50 / 60) < 1 and DayCycle.darkness(21 + 59 / 60) < 1 and DayCycle.darkness(21.75) > 0.4 and DayCycle.darkness(21.75) < 0.6, "a las 21:45 va por la mitad; a las 21:59 todavía no es noche cerrada")
local mid = look(21.75)
check(DayCycle.sunTime(21.75) > 18 and DayCycle.sunTime(21.75) < 19.9, "a las 21:45 el sol ya se ha puesto: puesta de sol / hora azul (sol a las " .. hm(DayCycle.sunTime(21.75)) .. ")")
local differs = false
for name, v in look(21 + 55 / 60) do
	if NIGHT[name] ~= nil and v ~= NIGHT[name] then
		differs = true
	end
end
check(differs, "a las 21:55 la luz aún no es la de la noche")
-- La luz va cambiando todo el rato (no se queda quieta 20 minutos y luego salta)
local changes = 0
local before = look(21.5).AtmColor
for minute = 1, 30 do
	local now = look(21.5 + minute / 60).AtmColor
	if math.abs(now.R - before.R) + math.abs(now.G - before.G) + math.abs(now.B - before.B) > 0.004 then
		changes += 1
	end
	before = now
end
check(changes >= 25, ("el color del cielo cambia casi cada minuto de la media hora (%d de 30)"):format(changes))
-- Antes de las 21:30 nada cambiaba hacia la noche: de 21:00 a 21:30 la luz de golpe no baja
check(look(21.5).Brightness > 2.5, ("a las 21:30 todavía hay sol (luz %.2f)"):format(look(21.5).Brightness))

---------------------------------------------------------------------
print("Noche cerrada desde las 22:00")
---------------------------------------------------------------------
for _, h in { 22, 23, 0, 3, 5, 6.5, 6.99 } do
	local k = look(h)
	local same = h ~= 6.5 and h ~= 6.99
	if same then
		for name, v in NIGHT do
			if k[name] ~= v then
				same = false
			end
		end
	end
	check(DayCycle.darkness(h) == 1 and (same or h >= 6.5) and DayCycle.lampsOn(h), hm(h) .. ": noche cerrada (la luz de la luna, farolas encendidas)")
end

---------------------------------------------------------------------
print("El amanecer: de 7:00 a 8:00")
---------------------------------------------------------------------
check(DayCycle.sunTime(5) == 0 and DayCycle.sunTime(6.5) == 4.9, "de 05:00 a 06:30 la noche va azulando: primera luz (antes del alba)")
check(DayCycle.sunTime(7) > 5.4 and DayCycle.sunTime(7) < 6, "07:00: clarea, el sol aún no ha salido")
check(math.abs(DayCycle.sunTime(7.5) - 6.3) < 1e-9, "07:30: sale el sol")
check(DayCycle.darkness(8) == 0 and DayGrade.nightness(look(8)) == 0, "08:00: pleno día")
check(DayCycle.darkness(7.25) > 0.5 and DayCycle.darkness(7.75) < 0.5, "la oscuridad baja poco a poco de 7:00 a 8:00")

---------------------------------------------------------------------
print("Farolas, ventanas, faros y grillos: la misma curva")
---------------------------------------------------------------------
check(not DayCycle.lampsOn(12) and not DayCycle.lampsOn(18) and not DayCycle.lampsOn(21) and not DayCycle.lampsOn(21.5), "farolas apagadas de día (también a las 18:00 y a las 21:30)")
check(DayCycle.lampsOn(21.75) and DayCycle.lampsOn(22) and DayCycle.lampsOn(3) and DayCycle.lampsOn(7.25), "encendidas al atardecer (21:45), de noche y al amanecer (7:15)")
check(not DayCycle.lampsOn(7.75) and not DayCycle.lampsOn(8), "apagadas a las 7:45")
local onAt, offAt
for minute = 0, 24 * 60 - 1 do
	local h = minute / 60
	local on, before2 = DayCycle.lampsOn(h), DayCycle.lampsOn(h - 1 / 60)
	if on and not before2 then
		onAt = h
	elseif before2 and not on then
		offAt = h
	end
end
check(onAt and onAt > 21.5 and onAt < 22 and offAt and offAt > 7 and offAt < 8, ("se encienden a las %s (atardeciendo) y se apagan a las %s"):format(hm(onAt or 0), hm(offAt or 0)))

-- Ventanas (OnAt / OffAt de shared/Kit, pensados para cuando anochecía a las 18:00)
local earlyWindow, nightWindows, lateOk = false, 0, true
local total = 0
for onAtW = 17.5, 20, 0.25 do
	for offAtW = 22.5, 30, 0.5 do
		total += 1
		for minute = 8 * 60, 21 * 60 + 30 do
			if DayCycle.windowLit(onAtW, offAtW, minute / 60) then
				earlyWindow = true
			end
		end
		if DayCycle.windowLit(onAtW, offAtW, 22.1) then
			nightWindows += 1
		end
		if DayCycle.windowLit(onAtW, offAtW, (offAtW + DayCycle.WindowsLater + 0.01) % 24) then
			lateOk = false
		end
	end
end
check(not earlyWindow, "ninguna ventana se enciende antes de las 21:30")
check(nightWindows == total, "a las 22:06 están todas encendidas (" .. nightWindows .. " de " .. total .. ")")
check(lateOk, "y se apagan a su hora (" .. DayCycle.WindowsLater .. " h más tarde que antes: en verano se cena tarde)")
check(DayCycle.windowLit(18, 30, 6.9) and not DayCycle.windowLit(18, 30, 7.05), "las que duran toda la noche se apagan a las 7:00")
local some, all = 0, 0
for onAtW = 17.5, 20, 0.25 do
	all += 1
	if DayCycle.windowLit(onAtW, 25, 21.7) then
		some += 1
	end
end
check(some > 0 and some < all, "al atardecer la ciudad se va encendiendo poco a poco (" .. some .. " de " .. all .. " a las 21:42)")

-- Faros (shared/VehicleControls): mismas horas que las farolas
local env = setmetatable({ Vector3 = roblox.Vector3, Enum = roblox.Enum }, { __index = getfenv(1) })
local VehicleControls = luau.load(fs.readFile("src/shared/VehicleControls.luau"), { debugName = "VehicleControls", environment = env })()
local agree = true
for minute = 0, 24 * 60 - 1 do
	local h = minute / 60
	if VehicleControls.isDark(h) ~= DayCycle.lampsOn(h) or VehicleControls.isDark(h, DayCycle.darkness(h)) ~= DayCycle.lampsOn(h) then
		agree = false
		print("    faros " .. hm(h))
	end
end
check(agree, "faros: el aviso de encender las luces va con las farolas (minuto a minuto)")
check(not VehicleControls.shouldHint(18, 0, false, "Coche") and VehicleControls.shouldHint(22, 0, false, "Coche"), "a las 18:00 no se avisa de los faros; a las 22:00 sí")

-- La Grieta: el aviso «de noche»
local Rift = L.load("src/shared/SkyRift")
local riftAgree = true
for minute = 0, 24 * 60 - 1 do
	local h = minute / 60
	if Rift.isNight(h) ~= DayCycle.isNight(h) then
		riftAgree = false
	end
end
check(riftAgree, "la Grieta llama noche a lo mismo que DayCycle (21:45 a 07:30)")

---------------------------------------------------------------------
print("GameClock: la hora del sol en Lighting, la del juego en el HUD")
---------------------------------------------------------------------
local attrs = {}
local lighting = { ClockTime = 14 }
function lighting:GetAttribute(name)
	return attrs[name]
end
check(GameClock.hour(lighting) == 14, "sin SunMapped (Studio, dobles), Lighting.ClockTime es la hora del juego")
attrs.SunMapped = true
GameClock.setHour(21.5, lighting)
check(math.abs(lighting.ClockTime - 17.45) < 1e-9 and math.abs(GameClock.hour(lighting) - 21.5) < 1e-9, "con SunMapped: setHour(21:30) pone el sol a las 17:27 y hour() dice 21:30")
GameClock.setHour(18 + 2 / 60, lighting)
check(lighting.ClockTime < 16 and DayGrade.nightness(DayGrade.sample(lighting.ClockTime)) == 0, "a las 18:02 del juego el sol está alto (" .. hm(lighting.ClockTime) .. "): de día, no de noche")
lighting.ClockTime = math.floor(DayCycle.sunTime(9.25) * 3600 + 0.5) / 3600 -- (Roblox lo guarda al segundo)
check(math.abs(GameClock.hour(lighting) - 9.25) < 0.001, "aunque Roblox redondee la hora del sol al segundo, la del juego no se mueve")

local worldSrc = fs.readFile("src/server/Services/WorldService.luau")
check(worldSrc:find("GameClock.lampsOn(clock)", 1, true) ~= nil and worldSrc:find("DayCycle.windowLit", 1, true) ~= nil, "WorldService: farolas y ventanas con la curva de DayCycle")
check(worldSrc:find('SetAttribute("SunMapped", true)', 1, true) ~= nil and worldSrc:find("GameClock.setHour(clock)", 1, true) ~= nil, "WorldService escribe la hora del sol (y marca SunMapped)")
check(worldSrc:find("schoolSpeed", 1, true) ~= nil and worldSrc:find("previous >= SCHOOL.Start and previous < SCHOOL.End", 1, true) ~= nil and worldSrc:find("local exact = GameClock.hour()", 1, true) ~= nil, "el reloj lento del cole (0,4 de 9 a 17) va con la hora del juego")

-- Nadie usa Lighting.ClockTime como hora del juego: solo lo «del sol» (luz de DayGrade, cielo de
-- fotos, luna, viento, cuánto se ve la Grieta) y GameClock
local ALLOWED = {
	["src/shared/GameClock.luau"] = true,
	["src/client/Controllers/DayLight.luau"] = true, -- luz y cielo de la hora del sol
	["src/client/Controllers/SkyExtras.luau"] = true, -- cielo de fotos y luna, con el sol
	["src/client/Controllers/SkyRift.luau"] = true, -- skyFactor, con el sol
	["src/client/Controllers/Weather.luau"] = true, -- viento
	["src/client/Controllers/WetWorld.luau"] = true, -- viento
	["src/shared/OpeningHours.luau"] = true, -- (solo si no hay GameClock)
	["src/shared/LifeStory/TimeContext.luau"] = true, -- (solo si no hay GameClock)
}
local bad = {}
local function scan(dir: string)
	for _, name in fs.readDir(dir) do
		local path = dir .. "/" .. name
		if fs.isDir(path) then
			scan(path)
		elseif name:match("%.luau$") then
			local src = fs.readFile(path)
			for line in src:gmatch("[^\n]+") do
				local code = line:gsub("%-%-.*$", "")
				if code:find("Lighting%.ClockTime") or code:find('GetService%("Lighting"%)%.ClockTime') then
					if not ALLOWED[path] then
						table.insert(bad, path .. ": " .. code)
					end
				end
			end
		end
	end
end
scan("src")
for _, line in bad do
	print("    " .. line)
end
check(#bad == 0, "nadie más lee ni escribe Lighting.ClockTime (la hora del juego es GameClock.hour())")
local skyExtrasSrc = fs.readFile("src/client/Controllers/SkyExtras.luau")
check(skyExtrasSrc:find("meteorNight(day, GameClock.hour())", 1, true) ~= nil, "las lluvias de estrellas, con la hora del juego (de 22:00 a 1:30)")
local trafficSrc = fs.readFile("src/client/Controllers/Traffic.luau")
check(trafficSrc:find("GameClock.lampsOn()", 1, true) ~= nil, "los faros del tráfico se encienden con las farolas")
local shadowsSrc = fs.readFile("src/client/Controllers/NearShadows.luau")
check(shadowsSrc:find("GameClock.lampsOn()", 1, true) ~= nil, "las luces cercanas y los carteles, con las farolas")
local sfxSrc = fs.readFile("src/client/Controllers/GameSfx.luau")
check(sfxSrc:find("DayCycle.darkness(clock)", 1, true) ~= nil, "los grillos, con la oscuridad de DayCycle")

---------------------------------------------------------------------
print("La Grieta del cielo de día: violeta, pero de día")
---------------------------------------------------------------------
for _, mood in { "GrietaAzul", "GrietaFinal" } do
	for _, h in { 12, 18, 21 } do
		local base = look(h)
		local k = SkyMoods.apply(base, SkyMoods.List[mood], 1, DayGrade.mix)
		check(k.Brightness >= base.Brightness * 0.79 and DayGrade.nightness(k) == 0, ("%s a las %s: sigue siendo de día (luz %.2f de %.2f)"):format(mood, hm(h), k.Brightness, base.Brightness))
	end
end
local finalDay = SkyMoods.apply(look(18), SkyMoods.List.GrietaFinal, 1, DayGrade.mix)
check(finalDay.Tint.B > finalDay.Tint.G and finalDay.Outdoor.B > finalDay.Outdoor.G, "la etapa 7 tiñe de violeta también de día")
local finalNight = SkyMoods.apply(look(23), SkyMoods.List.GrietaFinal, 1, DayGrade.mix)
check(math.abs(finalNight.Brightness - SkyMoods.List.GrietaFinal.Brightness) < 1e-9, "de noche entra entera")
local storm = SkyMoods.apply(look(12), SkyMoods.List.Apagon, 1, DayGrade.mix)
check(math.abs(storm.Brightness - SkyMoods.List.Apagon.Brightness) < 1e-9, "el apagón de la historia sí oscurece de día (es otra cosa)")

---------------------------------------------------------------------
print("En la nave a 1,2 km (captura de v120): el espacio negro manda tras cada vuelta del día y del tiempo")
---------------------------------------------------------------------
do
	local Vector3, CFrame = roblox.Vector3, roblox.CFrame
	local EnvZones = L.load("src/shared/Cosmos/EnvZones")
	local NavInfo = L.load("src/shared/Cosmos/NavInfo")
	local Stations = L.load("src/shared/Cosmos/Stations")
	local Ids = L.load("src/shared/Cosmos/EspacioTextureIds")
	-- Imágenes: al principio el servidor aún no ha pasado los Decal a imagen
	local imageOf: { [string]: string } = {}
	L.mock("src/shared/Images", {
		map = function(ids)
			local out = {}
			for k, v in ids do
				out[k] = imageOf[v] or v
			end
			return out
		end,
		of = function(v)
			return imageOf[v] or v
		end,
	})
	local dm = roblox.Instance.new("DataModel")
	local lighting = dm:GetService("Lighting")
	lighting.ClockTime = 12
	lighting.GlobalShadows = true
	local atm = roblox.Instance.new("Atmosphere")
	atm.Parent = lighting
	-- (el Sky del archivo del juego no trae caras: las vacías son el cielo AZUL de serie de Roblox)
	local sky = roblox.Instance.new("Sky")
	sky.StarCount = 3000
	sky.CelestialBodiesShown = true
	sky.SkyboxBk, sky.SkyboxDn, sky.SkyboxFt, sky.SkyboxLf, sky.SkyboxRt, sky.SkyboxUp = "", "", "", "", "", ""
	sky.Parent = lighting
	local cc = roblox.Instance.new("ColorCorrectionEffect")
	cc.Enabled = true
	cc.Parent = lighting
	roblox.Instance.new("BloomEffect").Parent = lighting
	roblox.Instance.new("SunRaysEffect").Parent = lighting
	local terrain = roblox.Instance.new("Folder")
	local clouds = roblox.Instance.new("Clouds")
	clouds.Enabled = true
	clouds.Parent = terrain
	-- SkyLibrary como en vivo en v120: el cielo de día y un «EspacioProfundo» con ids de DECAL (sin Night)
	local library = roblox.Instance.new("Folder")
	library.Name = "SkyLibrary"
	local day = roblox.Instance.new("Sky")
	day.Name = "Day"
	day.SkyboxBk, day.SkyboxDn, day.SkyboxFt, day.SkyboxLf, day.SkyboxRt, day.SkyboxUp = "rbxassetid://31", "rbxassetid://32", "rbxassetid://33", "rbxassetid://34", "rbxassetid://35", "rbxassetid://36"
	day.Parent = library
	local stale = roblox.Instance.new("Sky")
	stale.Name = "EspacioProfundo"
	stale.SkyboxBk, stale.SkyboxDn, stale.SkyboxFt = Ids.cielo_espacio_bk, Ids.cielo_espacio_dn, Ids.cielo_espacio_ft
	stale.SkyboxLf, stale.SkyboxRt, stale.SkyboxUp = Ids.cielo_espacio_lf, Ids.cielo_espacio_rt, Ids.cielo_espacio_up
	stale.Parent = library
	local cam = Stations.ById.Alba.Center + Vector3.new(-600, 0, 0)
	local fakeWorkspace = setmetatable({
		Terrain = terrain,
		GlobalWind = Vector3.zero,
		GetAttribute = function()
			return nil
		end,
		Raycast = function()
			return nil
		end,
	}, { __index = function(_, key)
		if key == "CurrentCamera" then
			return { CFrame = CFrame.new(cam), FieldOfView = 70 }
		end
		return nil
	end })
	local old = { W = L.workspace, Run = L.services.RunService, Players = L.services.Players, Lighting = L.services.Lighting }
	local renders: { (number) -> () } = {}
	L.workspace = fakeWorkspace
	L.services.Lighting = lighting
	L.services.RunService = { RenderStepped = { Connect = function(_, fn)
		table.insert(renders, fn)
	end }, IsStudio = function()
		return false
	end }
	local me = L.player("Piloto", 78)
	L.services.Players = { LocalPlayer = me }
	rawset(L.services.ReplicatedStorage, "SkyLibrary", library)
	L.mock("src/client/UI/Perf", {
		tier = function()
			return { GlobalShadows = true, Haze = 1, Bloom = 1, Clouds = 1, SunRays = true, FarRange = true, Specular = 1, ShadowSharp = 1, Saturation = 0, Contrast = 0 }
		end,
		tierName = function()
			return "Medium"
		end,
	})
	L.mock("src/client/Controllers/RainVeil", { update = function() end })
	L.mock("src/client/Controllers/SkyRift", { setSuppressed = function() end })
	L.mock("src/client/Controllers/PlanetClient", { envEntry = function()
		return nil
	end })
	L.mock("src/client/UI/FlightFocus", { setZone = function() end })
	L.reset("src/client/Controllers/DayLight")
	L.reset("src/client/Controllers/EnvDirector")
	local oldRay = L.globals.RaycastParams
	L.globals.RaycastParams = { new = function()
		return {}
	end }
	local DayLight = L.load("src/client/Controllers/DayLight")
	L.globals.RaycastParams = oldRay
	local Director = L.load("src/client/Controllers/EnvDirector")
	DayLight.init()
	local function tick(n: number?)
		for _ = 1, n or 3 do
			Director.update(0.2, cam)
			for _, fn in renders do
				fn(0.2)
			end
		end
	end
	tick(12)
	local env = Director.current()
	local function black(): (boolean, string)
		local o = lighting.OutdoorAmbient
		local a = lighting.Ambient
		local ok = lighting:FindFirstChildOfClass("Atmosphere") == nil and not cc.Enabled and not clouds.Enabled
			and o.R < 0.2 and o.G < 0.2 and o.B < 0.25 and a.B < 0.15 and sky.StarCount == EnvZones.starCount("Medium")
		return ok, ("bruma %s, etalonaje %s, nubes %s, OutdoorAmbient %.2f/%.2f/%.2f, estrellas %d"):format(tostring(lighting:FindFirstChildOfClass("Atmosphere") ~= nil), tostring(cc.Enabled), tostring(clouds.Enabled), o.R, o.G, o.B, sky.StarCount)
	end
	local okBlack, what = black()
	check(env and env.Zone == "Espacio" and okBlack, ("a 1,2 km (%s): Lighting del espacio (%s)"):format(env and env.Zone or "?", what))
	check(sky.SkyboxFt ~= "" and sky.SkyboxFt ~= day.SkyboxFt and DayLight._skyShown() == "EspacioProfundo", ("el cielo es el del espacio (%s), nunca el azul de serie ni el de día"):format(sky.SkyboxFt))
	check(NavInfo.place("Cosmos", cam, nil, env and env.Zone).Zone == "Espacio" and NavInfo.place("Cosmos", cam).Zone == "Espacio", "el HUD (zona de EnvDirector) y el entorno dicen «Espacio» a la vez")
	-- Una vuelta del tiempo (tormenta) y del día (otra hora) y la Grieta encima: nada lo pisa
	DayLight.setModifier(function(k)
		return DayGrade.weather(k, { Brightness = 0.7, Saturation = -0.2, Density = 0.5, Cover = 0.9, Rain = 1 }, nil, 0, 1)
	end)
	DayLight.pushLayer("Grieta", SkyMoods.List.GrietaFinal, 0.01, 1)
	for _, h in { 9, 15, 21.7, 23 } do
		lighting.ClockTime = h
		tick(3)
		local ok2, what2 = black()
		check(ok2 and sky.SkyboxFt ~= day.SkyboxFt and sky.SkyboxFt ~= "", ("con tormenta y la Grieta a las %.1f (hora del sol): sigue negro (%s)"):format(h, what2))
	end
	-- El servidor pasa los Decal a imagen: el cielo del espacio se repinta con las imágenes (sin cambiar de hueco)
	for _, v in Ids do
		imageOf[v] = "rbxassetid://7000" .. string.sub(v, 14)
	end
	tick(2)
	check(sky.SkyboxFt == imageOf[Ids.cielo_espacio_ft] and sky.SkyboxUp == imageOf[Ids.cielo_espacio_up], ("al llegar las imágenes, las caras se cambian solas (%s)"):format(sky.SkyboxFt))
	-- Y de vuelta a Valmar: su cielo de día
	DayLight.setModifier(nil)
	DayLight.popLayer("Grieta", 0.01)
	lighting.ClockTime = 12
	cam = Vector3.new(0, 40, 0)
	tick(20)
	check(sky.SkyboxFt == day.SkyboxFt and lighting:FindFirstChildOfClass("Atmosphere") == atm and cc.Enabled and clouds.Enabled, "al bajar a Valmar: su cielo de día, su bruma, nubes y etalonaje")
	-- (el mismo hueco con caras nuevas también se repinta: antes solo miraba el nombre del hueco)
	day.SkyboxFt = "rbxassetid://99"
	tick(1)
	check(sky.SkyboxFt == "rbxassetid://99", "el cielo de día cambia de caras y se repinta")

	L.workspace, L.services.RunService, L.services.Players, L.services.Lighting = old.W, old.Run, old.Players, old.Lighting
	rawset(L.services.ReplicatedStorage, "SkyLibrary", nil)
	for _, path in { "src/shared/Images", "src/client/UI/Perf", "src/client/Controllers/RainVeil", "src/client/Controllers/SkyRift", "src/client/Controllers/PlanetClient", "src/client/UI/FlightFocus" } do
		L.mock(path, nil)
	end
	L.reset("src/client/Controllers/DayLight")
	L.reset("src/client/Controllers/EnvDirector")
end

L.finish("Día y noche")
