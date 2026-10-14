-- Prueba del mar hondo de Valmar (docs/mar/diseno.md), FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-mar.luau
--
-- Comprueba:
--   * el perfil de profundidad: plataforma, talud, llanura, Abismo Silente ≥ 50 m y la Sima del Kraken
--     mucho más honda; la escala (1 m = 3,57 studs)
--   * que no se inunda nada: ciudad, playas, puertos, marina, islas, aeropuerto, puerto espacial del
--     islote y la desembocadura del río quedan como estaban (fondo de -14 junto a la costa)
--   * que los barcos siguen navegando (todo el mar navegable tiene agua de sobra) y sus muelles
--   * las zonas («Vida marina»): cada sitio (POI) está en su zona, y la tabla de cada zona está completa
--   * el plan del terreno: sin huecos al vacío, sin agua encima de la superficie, y su presupuesto
--   * el presupuesto de piezas de los sitios (World/OceanBuilder)
--   * aire, presión y equipo (shared/Sea/Diving); recursos y cofres con comprobaciones del servidor
--     (Services/OceanService); misiones del mar
--   * las criaturas (shared/Sea/SeaBeasts): el megalodón no sale del abismo, el kraken no sale de la sima,
--     reglas del daño (sin sangre: daño, empujón y aire), a quién no atacan
--   * el HUD de buceo: sus huecos (HudLayout.DivePanel / DiveObjective) no pisan nada en 932x430,
--     844x390, 640x360 y 1920x1080

local fs = require("@lune/fs")
local L = require("./lib/ModuleLoader")
local roblox = require("@lune/roblox")

local Vector3 = roblox.Vector3
local check = L.check

local Ocean = L.load("src/shared/Sea/Ocean")
local OceanBiomes = L.load("src/shared/Sea/OceanBiomes")
local CityPlan = L.load("src/shared/CityPlan")
local Boats = L.load("src/shared/Boats")
local Airport = L.load("src/shared/Airport")
local Swim = L.load("src/shared/Swim")
local Fishing = L.load("src/shared/Fishing")

local SPM = Ocean.StudsPerMeter
local function meters(y: number): number
	return (Ocean.Surface - y) / SPM
end

---------------------------------------------------------------------
print("▶ La escala y la superficie")
check(math.abs(SPM - 3.57) < 0.01, "1 m = 3,57 studs (un avatar de ~5 studs mide ~1,8 m)")
check(Ocean.Surface == Swim.Surface and Ocean.Surface == Boats.SeaLevel and Ocean.Surface == Fishing.Dive.Surface, "La superficie del mar es la de siempre (Y = -2): nadar, barcos y pesca de acuerdo")

---------------------------------------------------------------------
print("\n▶ El perfil de profundidad")
do
	-- Puntos del abismo (núcleo de la elipse) y de la sima
	local B = Ocean.Basin
	local minAbyss, n = math.huge, 0
	for i = 0, 40 do
		for j = 0, 20 do
			local u, v = (i / 40 - 0.5) * 2 * B.Core * 0.95, (j / 20 - 0.5) * 2 * B.Core * 0.95
			if u * u + v * v <= (B.Core * 0.95) ^ 2 then
				local x, z = B.X + u * B.RX, B.Z + v * B.RZ
				local s = Ocean.sample(x, z)
				if s.Floor then
					n += 1
					minAbyss = math.min(minAbyss, meters(s.Floor))
				end
			end
		end
	end
	check(n > 300 and minAbyss >= 50, ("Abismo Silente: en todo su centro hay al menos 50 m (el menos hondo, %.1f m; %d puntos)"):format(minAbyss, n))
	local areaCore = math.pi * B.RX * B.Core * B.RZ * B.Core
	check(areaCore > 2e6, ("El abismo es grande: su centro mide %.1f millones de studs² (≈ %.2f km²)"):format(areaCore / 1e6, areaCore / SPM ^ 2 / 1e6))
	local deepest, at = 0, nil
	local tr = Ocean.Trench
	for i = 1, #tr.Points - 1 do
		for k = 0, 20 do
			local a, b = tr.Points[i], tr.Points[i + 1]
			local x, z = a[1] + (b[1] - a[1]) * k / 20, a[2] + (b[2] - a[2]) * k / 20
			local f = Ocean.floorY(x, z)
			if f and meters(f) > deepest then
				deepest, at = meters(f), Vector3.new(x, f, z)
			end
		end
	end
	check(deepest >= 120 and deepest <= 200, ("Sima del Kraken: mucho más honda (%.0f m en su punto más hondo)"):format(deepest))
	check(Ocean.zoneAt(at.X, at.Z) == "Sima", "…y ahí la zona es la Sima del Kraken")
	-- La plataforma, el talud y la llanura
	local P = Ocean.World.Profile
	local shelf, slope, plain = {}, {}, {}
	for i = 1, 600 do
		local x = -5600 + Ocean.hash(i, 1, 99) * 11200
		local z = -5000 + Ocean.hash(i, 2, 99) * 10600
		local s = Ocean.sample(x, z)
		if s.Floor and s.Keep < 0.01 and s.Basin < 0.01 and s.Canyon < 0.01 and s.Trench < 0.01 then
			local m = meters(s.Floor)
			if s.D > P.Coast + 40 and s.D < P.ShelfEnd - 40 then
				table.insert(shelf, m)
			elseif s.D > P.ShelfEnd + 60 and s.D < P.SlopeEnd - 60 then
				table.insert(slope, m)
			elseif s.D > P.SlopeEnd + 80 then
				table.insert(plain, m)
			end
		end
	end
	local function range(list)
		local lo, hi = math.huge, -math.huge
		for _, v in list do
			lo, hi = math.min(lo, v), math.max(hi, v)
		end
		return lo, hi
	end
	local s0, s1 = range(shelf)
	local t0, t1 = range(slope)
	local p0, p1 = range(plain)
	check(#shelf > 5 and s0 >= 3 and s1 <= 18, ("Plataforma (arrecife, kelp, pradera): de %.0f a %.0f m"):format(s0, s1))
	check(#slope > 5 and t0 >= 10 and t1 <= 40, ("Talud: de %.0f a %.0f m"):format(t0, t1))
	check(#plain > 20 and p0 >= 30 and p1 <= 45, ("Llanura profunda: de %.0f a %.0f m"):format(p0, p1))
	-- La garganta
	local c = Ocean.Canyon
	local last = c.Points[#c.Points]
	local mid = c.Points[2]
	check(meters(Ocean.floorY(mid[1], mid[2]) or 0) > 30 and meters(Ocean.floorY(last[1] - 30, last[2] - 60) or 0) > 55, "Garganta Negra: un cañón que baja hasta el abismo")
end

---------------------------------------------------------------------
print("\n▶ No se inunda nada (ciudad, playas, puertos, islas, aeropuerto, puerto espacial)")
do
	-- Dentro de la isla: tierra
	local inland = 0
	for i = 1, 400 do
		local x = -4000 + Ocean.hash(i, 3, 98) * 8000
		local z = -3800 + Ocean.hash(i, 4, 98) * 7400
		if CityPlan.inside(CityPlan.Coast, x, z) and Ocean.floorY(x, z) ~= nil then
			inland += 1
		end
	end
	check(inland == 0, "Dentro de la isla no hay mar (la ciudad, los barrios y el campo no se tocan)")
	-- Islas pequeñas, aeropuerto y río
	local islandsOk = true
	for _, island in CityPlan.Islands do
		if Ocean.floorY(island.X, island.Z) ~= nil or Ocean.floorY(island.X + island.R * 0.8, island.Z) ~= nil then
			islandsOk = false
		end
	end
	check(islandsOk, "Las islas pequeñas (faro, gaviotas e islote del puerto espacial) siguen siendo tierra")
	local land = Airport.Land
	check(Ocean.floorY((land.X0 + land.X1) / 2, (land.Z0 + land.Z1) / 2) == nil and Ocean.floorY(land.X0 + 20, land.Z1 - 20) == nil, "El aeropuerto (tierra ganada al mar) sigue en tierra")
	local mouth = CityPlan.River.Points[#CityPlan.River.Points]
	check(Ocean.floorY(mouth[1], mouth[2]) == nil, "La desembocadura del río (sus orillas de arena) no se toca")
	-- Junto a la costa: el fondo de siempre (-14)
	local coastOk, coastN = true, 0
	for i = 1, #CityPlan.Coast do
		local a, b = CityPlan.Coast[i], CityPlan.Coast[i % #CityPlan.Coast + 1]
		for k = 1, 4 do
			local x, z = a[1] + (b[1] - a[1]) * k / 5, a[2] + (b[2] - a[2]) * k / 5
			-- 30 studs hacia fuera (la normal del tramo)
			local dx, dz = b[1] - a[1], b[2] - a[2]
			local len = math.sqrt(dx * dx + dz * dz)
			for _, sgn in { 1, -1 } do
				local px, pz = x + sgn * dz / len * 30, z - sgn * dx / len * 30
				if not CityPlan.inside(CityPlan.Coast, px, pz) then
					local f = Ocean.floorY(px, pz)
					if f then
						coastN += 1
						if math.abs(f - Ocean.CoastY) > 0.01 then
							coastOk = false
						end
					end
				end
			end
		end
	end
	check(coastOk and coastN > 50, ("Playas y orilla: a 30 studs de la costa el fondo sigue a -14 (%d puntos)"):format(coastN))
	-- Puertos, marina e islas: dentro de su radio, -14
	local keepOk = true
	for _, k in Ocean.Keep do
		for a = 0, 7 do
			local x, z = k.X + math.cos(a) * k.R * 0.9, k.Z + math.sin(a) * k.R * 0.9
			local f = Ocean.floorY(x, z)
			if f and math.abs(f - Ocean.CoastY) > 0.6 then
				keepOk = false
				print(("    %s: %.1f en (%d, %d)"):format(k.Name, f, x, z))
			end
		end
	end
	check(keepOk, "Puerto, puerto deportivo, isla del faro, islote y gaviotas: sus muelles y pantalanes con el fondo de siempre")
	-- Puerto espacial y portal de la playa
	local Access = L.load("src/shared/Cosmos/Access")
	local islote = CityPlan.Islands[2]
	check(islote.Name == "Islote" and Ocean.landDistance(islote.X, islote.Z) < 0, "El islote del puerto espacial es tierra")
	local spots = Access.BeachSpots
	if type(spots) == "table" and #spots > 0 then
		local ok = true
		for _, sp in spots do
			local x, z = sp[1] or sp.X, sp[2] or sp.Z
			if x and z and Ocean.floorY(x, z) ~= nil and Ocean.floorY(x, z) < Ocean.CoastY - 0.01 then
				ok = false
			end
		end
		check(ok, "Los sitios del portal de la playa no caen en el mar hondo")
	end
end

---------------------------------------------------------------------
print("\n▶ Los barcos siguen navegando")
do
	local ok, n, deep = true, 0, 0
	for i = 1, 3000 do
		local x = -5700 + Ocean.hash(i, 5, 97) * 11400
		local z = -5100 + Ocean.hash(i, 6, 97) * 10100
		if Boats.isSea(x, z) then
			n += 1
			local f = Ocean.floorY(x, z)
			-- (el agua del terreno: Ocean donde lo hay; si no, la losa de siempre de -14)
			local floorY = f or Ocean.CoastY
			if floorY > Boats.SeaLevel - Boats.Draft - 4 then
				ok = false
			end
			if f and f < -60 then
				deep += 1
			end
		end
	end
	check(ok and n > 1000, ("Todo el mar navegable tiene agua de sobra bajo el casco (%d puntos)"):format(n))
	check(deep > n * 0.3, ("…y buena parte es mar hondo (%d de %d puntos con más de 16 m)"):format(deep, n))
	-- El barco de pesca y el puerto deportivo: siguen en el agua y en zona tranquila
	local boatX, boatZ = 640, 3720
	check(Boats.isSea(boatX, boatZ) and Ocean.zoneAt(boatX, boatZ) == "Orilla", "El barco de pesca (alta mar) sigue en el agua, en el puerto")
	local marina = CityPlan.Places.Marina
	check(Boats.isSea(marina[1] - 300, marina[2]) and math.abs((Ocean.floorY(marina[1] - 300, marina[2]) or 0) - Ocean.CoastY) < 0.01, "Los pantalanes del puerto deportivo: mar con el fondo de siempre")
	-- La barca del faro: del puerto a la isla, todo es mar (o muelle)
	local fine = true
	for k = 0, 20 do
		local x = 700 + (4450 - 170 - 700) * k / 20
		local z = 3400 + (2650 - 3400) * k / 20
		if Boats.isSea(x, z) and Ocean.floorY(x, z) == nil then
			fine = false
		end
	end
	check(fine, "La ruta de la barca al faro sigue siendo mar")
end

---------------------------------------------------------------------
print("\n▶ Zonas y sitios")
do
	local world = OceanBiomes.world()
	local complete = true
	for _, id in world.ZoneOrder do
		local z = world.Zones[id]
		if not (z and z.Name and z.Materials and z.Flora and z.Fauna and z.Look and z.TempSurface and z.TempDeep and z.Hazards and z.Loot) then
			complete = false
			print("    zona incompleta: " .. id)
		end
	end
	check(complete and #world.ZoneOrder == 8, "Las 8 zonas (7 del dueño y la orilla) tienen paleta, materiales, flora, fauna, luz, temperatura, peligros y recursos")
	local names = {}
	for _, id in world.ZoneOrder do
		names[world.Zones[id].Name] = true
	end
	check(names["Arrecife Escarlata"] and names["Laberinto de Kelp"] and names["Llanura Sumergida"] and names["Talud del Naufragio"] and names["Garganta Negra"] and names["Abismo Silente"] and names["Sima del Kraken"], "Con los nombres del dueño")
	local allIn = true
	for _, poi in Ocean.Pois do
		local zone = if poi.Fixed then (if Ocean.sample(poi.X, poi.Z).Trench > 0.2 then "Sima" else Ocean.zoneAt(poi.X, poi.Z)) else Ocean.zoneAt(poi.X, poi.Z)
		if zone ~= poi.Zone then
			allIn = false
			print(("    %s está en %s (debería: %s)"):format(poi.Id, tostring(zone), poi.Zone))
		end
	end
	check(allIn, ("Cada sitio está en su zona (%d sitios)"):format(#Ocean.Pois))
	local seen = {}
	for _, poi in Ocean.Pois do
		seen[poi.Zone] = true
	end
	check(seen.Arrecife and seen.Kelp and seen.Llanura and seen.Talud and seen.Garganta and seen.Abismo and seen.Sima, "Hay algo que descubrir en cada una de las 7 zonas")
	-- La luz cambia con la zona y la profundidad
	local reef = OceanBiomes.look("Arrecife", 5)
	local abyss = OceanBiomes.look("Abismo", 65)
	check(reef.Visibility > abyss.Visibility * 2 and reef.Exposure > abyss.Exposure and reef.Rays > 0.5 and abyss.Rays == 0 and abyss.Glow > 0.5, "La luz: arrecife claro con rayos de sol; abismo oscuro, sin sol y con bioluminiscencia")
	check(OceanBiomes.temperature("Arrecife", 3) > OceanBiomes.temperature("Abismo", 66) + 10 and OceanBiomes.temperature("Sima", 150) >= 3.5, "La temperatura baja con la profundidad (y nunca de 4 °C)")
	-- Corrientes
	local c = Ocean.Canyon
	local p = c.Points[2]
	local v = Ocean.currentAt(Vector3.new(p[1], -150, p[2]))
	check(v.Magnitude > 1 and v.Magnitude < 4, ("En la Garganta Negra la corriente empuja suave hacia el abismo (%.1f studs/s)"):format(v.Magnitude))
	check(Ocean.currentAt(Vector3.new(p[1], 0, p[2])).Magnitude == 0, "Fuera del agua no hay corriente")
end

---------------------------------------------------------------------
print("\n▶ El plan del terreno (World/OceanBuilder)")
do
	local cell = Ocean.Cell
	local rows = Ocean.rows(cell)
	local all = {}
	for r = 0, rows - 1 do
		all[r] = Ocean.rowFloors(Ocean.Area.MinZ + r * cell, cell)
	end
	local fills, vox = 0, 0
	local aboveSurface, inLand, holes = 0, 0, 0
	local BAND = 8
	for r0 = 0, rows - 1, BAND do
		local band = {}
		for r = r0, math.min(rows - 1, r0 + BAND - 1) do
			table.insert(band, all[r])
		end
		local z0 = Ocean.Area.MinZ + r0 * cell
		for _, b in Ocean.planWater(z0, z0 + #band * cell, band, cell, 128) do
			fills += 1
			if b.Y1 > Ocean.Surface + 0.01 then
				aboveSurface += 1
			end
		end
		for r = r0, math.min(rows - 1, r0 + BAND - 1) do
			local zr = Ocean.Area.MinZ + r * cell
			for _, b in Ocean.planRow(zr, cell, all[r - 1], all[r], all[r + 1]) do
				fills += 1
				vox += (b.X1 - b.X0) * cell * (b.Y1 - b.Y0) / 64
				-- (el centro del bloque, nunca dentro de la isla)
				local x = (b.X0 + b.X1) / 2
				if CityPlan.inside(CityPlan.Coast, x, zr + cell / 2) then
					inLand += 1
				end
				if b.Y1 > Ocean.CoastY + 0.01 and b.Kind == "Floor" and zr + cell <= Ocean.World.SlabMaxZ then
					aboveSurface += 1
				end
			end
		end
	end
	-- Paredes: entre dos celdas vecinas, el sólido de la honda tapa el hueco de la alta
	for r = 1, rows - 2, 7 do
		for i, info in all[r] do
			for _, nb in { all[r][i + 1], all[r + 1][i] } do
				if nb and math.abs(nb.F - info.F) > 30 then
					-- la menos honda tiene que bajar su fondo hasta la más honda - 10 (planRow lo hace)
					local blocks = Ocean.planRow(Ocean.Area.MinZ + r * cell, cell, all[r - 1], all[r], all[r + 1])
					local x0 = Ocean.Area.MinX + i * cell
					local covered = false
					for _, b in blocks do
						if b.Kind == "Floor" and b.X0 <= x0 and b.X1 >= x0 + cell and b.Y0 <= math.min(nb.F, info.F) - 9 then
							covered = true
						end
					end
					if not covered and info.F < Ocean.CoastY - 0.5 then
						holes += 1
					end
				end
			end
		end
	end
	check(aboveSurface == 0, "Nada de agua ni fondo por encima de donde toca (no se inunda la costa ni sube el mar)")
	check(inLand == 0, "Ningún bloque dentro de la isla")
	check(holes == 0, "Las paredes altas (sima, garganta, borde del abismo) no dejan ver el vacío de debajo")
	check(fills < 100000, ("Presupuesto: %d rellenos de terreno (< 100 000; se hacen poco a poco en su hilo)"):format(fills))
	check(vox < 200e6, ("…y %.0f millones de vóxeles de fondo (< 200)"):format(vox / 1e6))
end

---------------------------------------------------------------------
print("\n▶ Las piezas de los sitios (World/OceanBuilder)")
do
	local filled = { FillBlock = 0, FillBall = 0, FillCylinder = 0 }
	local fakeTerrain = {}
	for name in filled do
		fakeTerrain[name] = function()
			filled[name] += 1
		end
	end
	function fakeTerrain.SetMaterialColor() end
	local OceanBuilder = L.load("src/server/World/OceanBuilder")
	OceanBuilder.sites()
	local mar = L.workspace:FindFirstChild("Mar")
	local parts, models, atomic, chests, air = 0, 0, 0, 0, 0
	for _, m in (if mar then mar:GetChildren() else {}) do
		models += 1
		local okMode, mode = pcall(function()
			return (m :: any).ModelStreamingMode
		end)
		if okMode and mode == roblox.Enum.ModelStreamingMode.Atomic then
			atomic += 1
		end
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				parts += 1
				if d:HasTag("SeaChest") then
					chests += 1
				end
				if d:HasTag("SeaAirPocket") then
					air += 1
				end
			end
		end
	end
	check(models >= 9 and parts > 200 and parts <= OceanBuilder.Budget, ("%d sitios con %d piezas (presupuesto %d)"):format(models, parts, OceanBuilder.Budget))
	check(atomic == models, "Cada sitio es un modelo Atomic (StreamingEnabled: llega entero)")
	local wanted = 0
	for _, poi in Ocean.Pois do
		if poi.Chest then
			wanted += 1
		end
	end
	check(chests == wanted, ("Un cofre por cada sitio con tesoro (%d)"):format(chests))
	check(air == 1, "La bolsa de aire de la cueva")
	OceanBuilder.lairCave(fakeTerrain :: any)
	check(filled.FillBall >= 2 and filled.FillCylinder >= 1, "La Guarida del Kraken se excava en una mole de roca (no deja ver el vacío)")
end

---------------------------------------------------------------------
print("\n▶ Aire, presión y equipo (shared/Sea/Diving)")
local SeaDiving = L.load("src/shared/Sea/Diving")
do
	local base, gafas, botella, traje = SeaDiving.info(nil), SeaDiving.info("Gafas"), SeaDiving.info("Botella"), SeaDiving.info("TrajeAbisal")
	check(base.Oxygen >= 30 and gafas.Oxygen > base.Oxygen and botella.Oxygen > gafas.Oxygen and traje.Oxygen > botella.Oxygen, ("Aire mucho más largo que 10 s: %d s, %d s, %d s y %d s"):format(base.Oxygen, gafas.Oxygen, botella.Oxygen, traje.Oxygen))
	check(Fishing.Tools.TrajeAbisal ~= nil and table.find(Fishing.ToolOrder, "TrajeAbisal") ~= nil, "El traje abisal se compra en la tienda de pesca (como las gafas y la botella)")
	local Items = L.load("src/shared/Items")
	local itemList = Items.list or Items.Items or Items
	local function item(id)
		return (type(itemList) == "table" and itemList[id]) or (Items.get and Items.get(id))
	end
	check(item("TrajeAbisal") ~= nil and item("Mar_Perla") ~= nil and item("Mar_Doblon") ~= nil, "El traje y lo que se recoge son objetos de la mochila")
	-- Límites de profundidad y lo que hace falta para cada zona
	check(SeaDiving.gearFor(10) == "Base" and SeaDiving.gearFor(20) == "Gafas" and SeaDiving.gearFor(67) == "Botella" and SeaDiving.gearFor(157) == "TrajeAbisal", "Cada profundidad pide su equipo: arrecife sin nada, pecio con gafas, abismo con botella y la sima con traje abisal")
	local deepest = 0
	for _, poi in Ocean.Pois do
		deepest = math.max(deepest, Ocean.meters(Ocean.poiPosition(poi).Y))
	end
	check(deepest <= traje.Depth, ("Con el mejor equipo se llega a todos los sitios (el más hondo a %.0f m)"):format(deepest))
	local reef = Ocean.poiPosition(Ocean.PoiById.ArcoCoral)
	check(Ocean.meters(reef.Y) <= base.Depth, "El Arco de Coral se visita sin comprar nada")
	check(SeaDiving.pressure(20, "Gafas") == "Ok" and SeaDiving.pressure(23, "Gafas") == "Warn" and SeaDiving.pressure(30, "Gafas") == "Over", "Presión: bien, aviso cerca del límite y pasado")
	local text = SeaDiving.overText("Gafas", 40)
	check(string.find(text, "25 m", 1, true) ~= nil and string.find(text, "equipo de buceo", 1, true) ~= nil and string.find(text, "tienda de pesca", 1, true) ~= nil, "El aviso dice hasta dónde llegas, qué te falta y dónde se compra")
	-- Un minuto bajo el agua
	local o, dmg, over = 60, 0, 0
	for _ = 1, 10 do
		local d
		o, d, over = SeaDiving.tick({ Oxygen = o, Max = 60, Under = true, Meters = 10, Gear = "Gafas", Over = over })
		dmg += d
	end
	check(o == 50 and dmg == 0, "Con gafas a 10 m: un segundo de aire por segundo, sin daño")
	o, over, dmg = 60, 0, 0
	for _ = 1, 8 do
		local d
		o, d, over = SeaDiving.tick({ Oxygen = o, Max = 60, Under = true, Meters = 40, Gear = "Gafas", Over = over })
		dmg += d
	end
	check(o == 60 - 8 * SeaDiving.OverDrain and dmg > 0 and dmg <= (8 - SeaDiving.OverGrace) * SeaDiving.OverDamage, "Pasado el límite: el aire se gasta el triple y, tras un margen, la presión hace daño")
	local o2 = SeaDiving.tick({ Oxygen = 5, Max = 240, Under = true, Meters = 30, Gear = "Botella", Pocket = true })
	check(o2 == 5 + SeaDiving.PocketRefill, "En una bolsa de aire (o junto al barco de pesca) se recupera aire bajo el agua")
	local o3 = SeaDiving.tick({ Oxygen = 5, Max = 60, Under = false, Meters = 0 })
	check(o3 == 5 + SeaDiving.Refill, "En la superficie se recupera")
end

---------------------------------------------------------------------
print("\n▶ Recursos, cofres y misiones (Services/OceanService: comprueba el servidor)")
do
	local roblox2 = require("@lune/roblox")
	local notes = {}
	local profiles = {}
	local inventory = {}
	local money = {}
	local underwater = {}
	local function remoteDouble()
		return { FireClient = function(_, p, kind, text)
			table.insert(notes, { P = p, Kind = kind, Text = text })
		end, FireServer = function() end, OnServerEvent = { Connect = function() end } }
	end
	local remotes = { Notify = remoteDouble(), Sea = remoteDouble() }
	function remotes:FindFirstChild(name)
		return rawget(self, name)
	end
	rawset(L.services.ReplicatedStorage, "Remotes", remotes)
	L.services.Players = { GetPlayers = function()
		return {}
	end, PlayerAdded = { Connect = function() end }, PlayerRemoving = { Connect = function() end } }
	L.mock("src/server/Services/DataService", {
		get = function(p)
			return profiles[p]
		end,
		addMoney = function(p, n)
			money[p] = (money[p] or 0) + n
			return true
		end,
	})
	L.mock("src/server/Services/InventoryService", {
		count = function(p, id)
			return (inventory[p] or {})[id] or 0
		end,
		add = function(p, id, n)
			inventory[p] = inventory[p] or {}
			inventory[p][id] = (inventory[p][id] or 0) + (n or 1)
			return true
		end,
	})
	L.mock("src/server/Services/DivingService", {
		underwater = function(p)
			return underwater[p] == true
		end,
	})
	L.mock("src/server/LifeStory/StoryEvents", { emit = function() end })
	local OceanService = L.load("src/server/Services/OceanService")
	-- Dónde salen
	local plan = OceanService.plan()
	local quota = 0
	for _, n in OceanService.Quota do
		quota += n
	end
	local wrongZone, wrongLoot, perZone = 0, 0, {}
	for _, spec in plan do
		perZone[spec.Zone] = (perZone[spec.Zone] or 0) + 1
		if Ocean.zoneAt(spec.Position.X, spec.Position.Z) ~= spec.Zone then
			wrongZone += 1
		end
		if (OceanBiomes.zone(spec.Zone).Loot[spec.Loot] or 0) <= 0 then
			wrongLoot += 1
		end
	end
	check(#plan == quota and wrongZone == 0 and wrongLoot == 0, ("%d recursos repartidos por las zonas, cada uno en la suya y de lo que da esa zona"):format(#plan))
	check((perZone.Sima or 0) > 0 and (perZone.Abismo or 0) > 0 and (perZone.Arrecife or 0) > 0, "Hay recursos desde el arrecife hasta la sima")
	-- Un buceador de mentira
	local function diver(name, pos)
		local p = L.player(name, #notes + 100 + math.random(1, 1e6))
		local root = { Position = pos }
		local humanoid = { Health = 100 }
		p.Character = {
			FindFirstChild = function(_, n)
				return if n == "HumanoidRootPart" then root else nil
			end,
			FindFirstChildOfClass = function(_, c)
				return if c == "Humanoid" then humanoid else nil
			end,
		}
		profiles[p] = { Sea = { Found = {}, Done = {}, Chests = {}, Photos = {}, Loot = {} } }
		return p, root
	end
	local spot = Ocean.poiPosition(Ocean.PoiById.ArcoCoral)
	local ana, anaRoot = diver("Ana", spot + roblox2.Vector3.new(0, 2, 0))
	local function node(loot, pos)
		return { Id = 1, Loot = loot, Zone = "Arrecife", Position = pos, Active = true, BackAt = 0 }
	end
	local n1 = node("Concha", spot + roblox2.Vector3.new(30, 0, 0))
	underwater[ana] = true
	local ok, why = OceanService.collect(ana, n1)
	check(not ok and why == "lejos" and (inventory[ana] or {}).Mar_Concha == nil, "Lejos (30 studs) no se recoge")
	n1.Position = spot + roblox2.Vector3.new(4, 0, 0)
	underwater[ana] = false
	ok, why = OceanService.collect(ana, n1)
	check(not ok and why == "fuera del agua", "Fuera del agua no se recoge")
	underwater[ana] = true
	ok = OceanService.collect(ana, n1)
	check(ok and inventory[ana].Mar_Concha == 1 and not n1.Active and profiles[ana].Sea.Loot.Concha == 1, "Bajo el agua y cerca: a la mochila, se apunta y el recurso desaparece un rato")
	ok, why = OceanService.collect(ana, n1)
	check(not ok and why == "ya recogido", "El mismo no se puede coger dos veces")
	local n2 = node("Perla", spot + roblox2.Vector3.new(3, 0, 2))
	ok, why = OceanService.collect(ana, n2)
	check(not ok and why == "demasiado rápido", "Ni muchos seguidos (ritmo contra trampas)")
	-- Presión: sin equipo en el abismo
	local deep = Ocean.poiPosition(Ocean.PoiById.JardinLuz)
	local leo, leoRoot = diver("Leo", deep + roblox2.Vector3.new(0, 2, 0))
	underwater[leo] = true
	ok, why = OceanService.collect(leo, node("Bio", deep + roblox2.Vector3.new(2, 0, 0)))
	check(not ok and why == "presión", "Sin el equipo que toca para esa profundidad, no (y se avisa de qué falta)")
	inventory[leo] = { Botella = 1 }
	ok = OceanService.collect(leo, node("Bio", deep + roblox2.Vector3.new(2, 0, 0)))
	check(ok and inventory[leo].Mar_Bio == 1, "Con el equipo de buceo, sí")
	-- Cofres
	local chestPart = { Position = Ocean.poiPosition(Ocean.PoiById.Pecio), GetAttribute = function(_, k)
		return if k == "ChestId" then "Pecio" else nil
	end }
	local eva, evaRoot = diver("Eva", chestPart.Position + roblox2.Vector3.new(0, 1, 3))
	underwater[eva] = true
	ok = OceanService.openChest(eva, chestPart)
	check(ok and money[eva] == SeaDiving.Chests.Pecio.Money and inventory[eva].Mar_Doblon == 2 and type(profiles[eva].Sea.Chests.Pecio) == "number", "El cofre del pecio da dinero, doblones y perla, y se apunta cuándo")
	ok, why = OceanService.openChest(eva, chestPart)
	check(not ok and why == "pronto", "No se vuelve a abrir hasta el día siguiente")
	evaRoot.Position = chestPart.Position + roblox2.Vector3.new(0, 0, 40)
	local opened = profiles[eva].Sea.Chests.Pecio
	profiles[eva].Sea.Chests.Pecio = nil
	ok, why = OceanService.openChest(eva, chestPart)
	check(not ok and why == "lejos", "De lejos no se abre")
	profiles[eva].Sea.Chests.Pecio = opened
	-- Misiones
	local before = money[ana] or 0
	OceanService.discover(ana, "ArcoCoral")
	OceanService.discover(ana, "JardinEscarlata")
	check(profiles[ana].Sea.Done.Arrecife == true and (money[ana] or 0) >= before + SeaDiving.MissionById.Arrecife.Reward, "«Explora el arrecife»: al descubrir los dos sitios se cobra la misión")
	check(ana:GetAttribute("SeaMission") == "Conchas" and ana:GetAttribute("SeaMissionProgress") == "1/6", "El HUD ya enseña la siguiente: recolectar (1 de 6)")
	check(not OceanService.discover(ana, "ArcoCoral"), "Un sitio solo se descubre una vez")
	OceanService.photo(ana, "Megalodon")
	check(profiles[ana].Sea.Photos.Megalodon == true and profiles[ana].Sea.Done.Megalodon == true, "La foto del megalodón cuenta para su misión (aunque se haga antes)")
	local done, total = SeaDiving.progress(SeaDiving.MissionById.Pecio, profiles[eva].Sea)
	check(done == 1 and total == 2, "«Encuentra el pecio»: abrir el cofre cuenta, falta descubrirlo")
	local _ = leoRoot
	local _2 = anaRoot
end

---------------------------------------------------------------------
print("\n▶ Las criaturas (shared/Sea/SeaBeasts)")
do
	local roblox2 = require("@lune/roblox")
	local V3 = roblox2.Vector3.new
	local SeaBeasts = L.load("src/shared/Sea/SeaBeasts")
	local m = SeaBeasts.newMegalodon()
	local inside, belowTop = true, true
	for i = 1, 4000 do
		m = SeaBeasts.stepMegalodon(m, 0.125, {})
		if not SeaBeasts.inTerritory("Megalodon", m.Pos) then
			inside = false
		end
		if m.Pos.Y > SeaBeasts.Megalodon.TopY + 0.01 then
			belowTop = false
		end
		local f = Ocean.floorY(m.Pos.X, m.Pos.Z)
		if f and m.Pos.Y < f then
			belowTop = false
		end
		local _ = i
	end
	check(inside and belowTop, "El megalodón patrulla 8 minutos sin salir del Abismo Silente, sin subir de 26 m y sin meterse en el fondo")
	-- Un buceador quieto en el abismo: le ronda, embiste y muerde
	local spot = Ocean.poiPosition(Ocean.PoiById.JardinLuz) + V3(0, 30, 0)
	m = SeaBeasts.newMegalodon()
	m.Pos = SeaBeasts.clampMegalodon(spot + V3(80, 0, 0))
	local modes, bit, chasingInside = {}, false, true
	for _ = 1, 400 do
		local ev
		m, ev = SeaBeasts.stepMegalodon(m, 0.125, { { Id = 7, Pos = spot } })
		modes[m.Mode] = true
		if ev.Bite == 7 then
			bit = true
			break
		end
		if not SeaBeasts.inTerritory("Megalodon", m.Pos) then
			chasingInside = false
		end
	end
	check(modes.Stalk and bit and chasingInside, "Un buceador en su territorio: lo ronda, embiste y muerde (sin salir de él)")
	check(m.Mode == "Retreat", "Después de morder se aleja")
	local hit = SeaBeasts.hit("Megalodon")
	check(hit.Damage > 0 and hit.Damage < 100 and hit.Oxygen > 0 and hit.Knock > 0, "El mordisco: daño (no te mata de un golpe), aire y empujón; sin sangre")
	-- A quién no ataca
	local base = { Pos = spot, Alive = true, Underwater = true, Stage = "Adulto", Riding = false }
	local function with(k, v)
		local t = table.clone(base)
		t[k] = v
		return t
	end
	check(SeaBeasts.canTarget("Megalodon", base), "Ataca a un adulto que bucea en el abismo")
	check(not SeaBeasts.canTarget("Megalodon", with("Stage", "Nino")) and not SeaBeasts.canTarget("Megalodon", with("Stage", "Bebe")), "Nunca a niños ni bebés")
	check(not SeaBeasts.canTarget("Megalodon", with("Riding", true)) and not SeaBeasts.canTarget("Megalodon", with("Underwater", false)), "Ni a quien va en barco o está fuera del agua")
	check(not SeaBeasts.canTarget("Megalodon", with("Pos", V3(spot.X, -20, spot.Z))) and not SeaBeasts.canTarget("Megalodon", with("Pos", V3(0, -40, 4200))), "Ni cerca de la superficie ni fuera de su abismo")
	-- Atacar en el morro lo espanta; enganchado (pesca) no ataca
	m = SeaBeasts.newMegalodon()
	m.Mode = "Charge"
	check(SeaBeasts.strikeMegalodon(m, SeaBeasts.mouth(m)) and m.Mode == "Retreat", "Un golpe en el morro (Atacar) lo espanta")
	m.Mode = "Hooked"
	local _, ev = SeaBeasts.stepMegalodon(m, 0.125, { { Id = 1, Pos = m.Pos } })
	check(ev.Bite == nil and m.Mode == "Hooked", "Enganchado a un sedal (la pesca del monstruo) no ataca")
	-- Kraken
	local L2 = Ocean.Lair
	local diverPos = V3(L2.X, L2.Y - 20, L2.Z + 80)
	check(SeaBeasts.canTarget("Kraken", with("Pos", diverPos)) and not SeaBeasts.canTarget("Kraken", with("Pos", V3(L2.X, -200, L2.Z))) and not SeaBeasts.canTarget("Kraken", with("Pos", V3(L2.X + 600, L2.Y, L2.Z))), "El kraken solo embosca dentro de la sima, cerca de su guarida")
	local k = SeaBeasts.newKraken()
	local e
	k, e = SeaBeasts.stepKraken(k, 0.1, { { Id = 3, Pos = diverPos } })
	check(e.Warn == 3 and k.Mode == "Warn", "Primero avisa (tiembla y suelta tinta)")
	local hitIt = false
	for _ = 1, 20 do
		k, e = SeaBeasts.stepKraken(k, 0.1, { { Id = 3, Pos = diverPos } })
		if e.Hit == 3 then
			hitIt = true
		end
	end
	check(hitIt, "Si te quedas quieto, el tentáculo te da")
	k = SeaBeasts.newKraken()
	k, e = SeaBeasts.stepKraken(k, 0.1, { { Id = 3, Pos = diverPos } })
	local dodged = true
	for _ = 1, 20 do
		k, e = SeaBeasts.stepKraken(k, 0.1, { { Id = 3, Pos = diverPos + V3(30, 0, 0) } })
		if e.Hit then
			dodged = false
		end
	end
	check(dodged, "Si te apartas a tiempo, falla")
	k = SeaBeasts.newKraken()
	k = SeaBeasts.stepKraken(k, 0.1, { { Id = 3, Pos = diverPos } })
	check(SeaBeasts.strikeKraken(k, (k.At :: any) + V3(5, 0, 0)) and k.Mode == "Rest", "Atacar el tentáculo durante el aviso lo hace retirarse")
	local far = SeaBeasts.reachable(V3(L2.X + 1000, L2.Y, L2.Z))
	check((far - V3(L2.X, L2.Y, L2.Z)).Magnitude <= SeaBeasts.Kraken.Reach + 0.01, "El tentáculo no llega más allá de su alcance")
	-- La pesca de los monstruos sigue igual
	check(Fishing.Bosses.Megalodon.MinPlayers >= 3 and Fishing.Bosses.Kraken.MinPlayers >= 4 and Fishing.BossOrder[1] == "Megalodon", "La pesca del megalodón y del kraken no cambia (alta mar, varios pescadores expertos)")
	local fishingSrc = fs.readFile("src/server/Services/FishingService.luau")
	local beastSrc = fs.readFile("src/server/Services/SeaBeastService.luau")
	check(string.find(fishingSrc, "FishingService.onBoss", 1, true) ~= nil and string.find(beastSrc, "FishingService.onBoss = onBoss", 1, true) ~= nil, "Cuando empieza su pesca, el animal de verdad queda enganchado; si lo sacáis, vuelve otro ejemplar más tarde")
end

---------------------------------------------------------------------
print("\n▶ Piezas de la vida del mar (Controllers/SeaLife)")
do
	local src = fs.readFile("src/client/Controllers/SeaLife.luau")
	local mobile = tonumber(string.match(src, "Budget = { Mobile = (%d+)"))
	local desktop = tonumber(string.match(src, "Desktop = (%d+) }"))
	check(mobile ~= nil and mobile <= 160 and desktop ~= nil and desktop <= 260, ("Presupuesto de piezas animadas: %s en el móvil, %s en el ordenador"):format(tostring(mobile), tostring(desktop)))
	-- Lo más que pide la zona más llena (con el banco de peces más grande)
	local worst = 0
	for _, z in OceanBiomes.world().Zones do
		local f = z.Fauna
		local n = math.ceil(f.Schools * 0.6) * 10 + math.floor(f.Rays * 0.6 + 0.4) * 3 + math.floor(f.Turtles * 0.6 + 0.4) * 6 + math.ceil(f.Jellies * 0.6) * 5 + math.min(1, f.Dolphins) * 12 + math.ceil(f.Abyssal * 0.6) * 4
		worst = math.max(worst, n)
	end
	check(worst + 25 + 20 <= (mobile or 0), ("En el móvil, la zona más llena (%d) más el megalodón y el kraken caben en el presupuesto"):format(worst))
	check(string.find(src, "cullFar", 1, true) ~= nil and string.find(src, "SeaLife.Radius", 1, true) ~= nil, "Lo lejano se quita (radio) y se mueve a la mitad de fotogramas")
end

---------------------------------------------------------------------
print("\n▶ El HUD de buceo (HudLayout.DivePanel y DiveObjective)")
do
	local HudLayout = L.load("src/client/UI/HudLayout")
	local Vector2 = roblox.Vector2
	for _, vp in { { 932, 430, true }, { 844, 390, true }, { 640, 360, true }, { 1920, 1080, false } } do
		local layout = HudLayout.compute(Vector2.new(vp[1], vp[2]), { Touch = vp[3] })
		local canvas = layout.Canvas
		local dive = HudLayout.rect(layout.Items.DivePanel, canvas)
		local goal = HudLayout.rect(layout.Items.DiveObjective, canvas)
		local inside = dive.X >= 0 and dive.Y >= 0 and dive.X + dive.W <= canvas.X and dive.Y + dive.H <= canvas.Y and goal.X >= 0 and goal.X + goal.W <= canvas.X
		-- Lo que se queda a la vista mientras buceas (el GPS y las notas se esconden: UI/DiveFocus)
		local others = {}
		for _, name in { "Status", "Clock", "Minimap", "Mission", "Help", "Hotbar", "Joystick", "Wanted", "Ammo" } do
			if layout.Items[name] then
				others[name] = HudLayout.rect(layout.Items[name], canvas)
			end
		end
		if vp[3] then
			for name, slot in layout.Slots do
				others["slot " .. name] = HudLayout.rect(slot, canvas)
			end
		else
			others.Hints = HudLayout.rect(layout.Items.Hints, canvas)
			others.Phone = HudLayout.rect(layout.Items.Phone, canvas)
		end
		local clash = {}
		for name, r in others do
			if HudLayout.overlaps(dive, r) then
				table.insert(clash, "panel/" .. name)
			end
			if HudLayout.overlaps(goal, r) then
				table.insert(clash, "objetivo/" .. name)
			end
		end
		check(inside and #clash == 0 and not HudLayout.overlaps(dive, goal), ("%dx%d: el panel y el objetivo caben y no pisan nada%s"):format(vp[1], vp[2], if #clash > 0 then " (" .. table.concat(clash, ", ") .. ")" else ""))
		-- Se leen: el panel a escala real no queda diminuto
		-- (el móvil del dueño, 932x430: ≥ 14 pt como el resto del HUD compacto; el de 640x360 va a la
		-- escala mínima del HUD, 0,36, como todo)
		local k = layout.Scale * math.min(1, dive.H / HudLayout.Sizes.DivePanel.Y)
		local need = if vp[1] == 640 then 11 elseif vp[1] == 844 then 13 else 14
		local hudSrc = fs.readFile("src/client/Controllers/DiveHud.luau")
		local size = tonumber(string.match(hudSrc, 'Name = "Value".-TextSize = (%d+)')) or 0
		check(size * k >= need, ("%dx%d: la profundidad se lee (%.1f pt)"):format(vp[1], vp[2], size * k))
	end
	local hud = fs.readFile("src/client/Controllers/DiveHud.luau")
	check(string.find(hud, 'Label = "Atacar", Slot = "Agacharse"', 1, true) ~= nil and string.find(hud, 'Label = "Cambiar", Slot = "Esquivar"', 1, true) ~= nil, "Botones de buceo en los huecos que deja libres nadar: Atacar y Cambiar (Bucear y Subir: DivingUI)")
	local swim = L.load("src/shared/Swim")
	check(swim.HiddenButtons.Agacharse and swim.HiddenButtons.Esquivar, "…esos huecos están libres nadando (Agacharse y Esquivar se esconden)")
	local focus = fs.readFile("src/client/UI/DiveFocus.luau")
	check(string.find(focus, '"GpsGui"', 1, true) ~= nil and string.find(focus, '"GuideGui"', 1, true) ~= nil, "Buceando se esconden el GPS y las notas (DiveFocus)")
	local actions = fs.readFile("src/client/Controllers/Actions.luau")
	check(string.find(actions, "DiveDepth", 1, true) ~= nil, "La Linterna sale buceando en lo hondo")
end

L.finish("Mar de Valmar")
