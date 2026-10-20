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
local Color3 = roblox.Color3
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
		if s.Floor and s.Keep < 0.01 and s.Basin < 0.01 and s.Canyon < 0.01 and s.Trench < 0.01 and s.Cathedrals < 0.01 then
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
	-- La barca del faro: del puerto a la isla, todo es mar (o muelle). Sale del atraque de la estación
	-- marítima (shared/Port/PuertoPlan.FerryBerth, por fuera de la dársena: la dársena es agua excavada
	-- dentro de la costa, sin fondo de Ocean)
	local fine = true
	local PuertoPlan = L.load("src/shared/Port/PuertoPlan")
	local berth = PuertoPlan.FerryBerth
	for k = 0, 20 do
		local x = berth.X + (4450 - 170 - berth.X) * k / 20
		local z = berth.Z + (2650 - berth.Z) * k / 20
		if Boats.isSea(x, z) and not PuertoPlan.inBasin(x, z) and Ocean.floorY(x, z) == nil then
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
	check(complete and #world.ZoneOrder == 11, "Las 11 zonas (7 del dueño, la orilla, los jardines de coral, el Cañón de las Catedrales y el Cañón de Dorada —la zona de referencia v2—) tienen paleta, materiales, flora, fauna, luz, temperatura, peligros y recursos")
	local names = {}
	for _, id in world.ZoneOrder do
		names[world.Zones[id].Name] = true
	end
	check(names["Arrecife Escarlata"] and names["Laberinto de Kelp"] and names["Llanura Sumergida"] and names["Talud del Naufragio"] and names["Garganta Negra"] and names["Abismo Silente"] and names["Sima del Kraken"] and names["Cañón de las Catedrales"], "Con los nombres del dueño (y el cañón nuevo del mar enorme)")
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
local OLD_FILLS = 92644 -- rellenos de terreno antes del mar enorme (v117: planRow, bandas de 8 filas)
do
	local OceanBuilder = L.load("src/server/World/OceanBuilder")
	local cell = Ocean.Cell
	local rows = Ocean.rows(cell)
	local all = {}
	for r = 0, rows - 1 do
		all[r] = Ocean.rowFloors(Ocean.Area.MinZ + r * cell, cell)
	end
	local fills, vox = 0, 0
	local aboveSurface, inLand, holes = 0, 0, 0
	local BAND = OceanBuilder.Band
	-- lo que tapa cada celda: el Y0 más hondo de los bloques de fondo que la cubren
	local cover: { [number]: number } = {}
	local ncols = math.floor((Ocean.Area.MaxX - Ocean.Area.MinX) / cell)
	for r0 = 0, rows - 1, BAND do
		local n = math.min(BAND, rows - r0)
		local band, around = {}, {}
		for k = -1, n do
			around[k] = all[r0 + k]
			if k >= 0 and k < n then
				table.insert(band, all[r0 + k])
			end
		end
		local z0 = Ocean.Area.MinZ + r0 * cell
		for _, b in Ocean.planWater(z0, z0 + n * cell, band, cell, OceanBuilder.WaterTile) do
			fills += 1
			if b.Y1 > Ocean.Surface + 0.01 then
				aboveSurface += 1
			end
		end
		for _, b in Ocean.planBand(z0, cell, around, n) do
			fills += 1
			vox += (b.X1 - b.X0) * (b.Z1 - b.Z0) * (b.Y1 - b.Y0) / 64
			-- (ningún trozo del bloque dentro de la isla: se miran sus celdas)
			for z = b.Z0 + cell / 2, b.Z1, cell do
				for x = b.X0 + cell / 2, b.X1, cell do
					if CityPlan.inside(CityPlan.Coast, x, z) then
						inLand += 1
					end
					local r = math.floor((z - Ocean.Area.MinZ) / cell)
					local i = math.floor((x - Ocean.Area.MinX) / cell)
					local key = r * ncols + i
					cover[key] = math.min(cover[key] or math.huge, b.Y0)
				end
			end
			if b.Y1 > Ocean.CoastY + 0.01 and b.Kind == "Floor" and b.Z1 <= Ocean.World.SlabMaxZ then
				aboveSurface += 1
			end
		end
	end
	-- Paredes: entre dos celdas vecinas muy distintas, el sólido de la menos honda baja hasta la honda
	for r = 1, rows - 2, 3 do
		for i, info in all[r] do
			for _, nb in { all[r][i + 1], all[r + 1][i] } do
				if nb and math.abs(nb.F - info.F) > 30 and info.F < Ocean.CoastY - 0.5 then
					local y0 = cover[r * ncols + i]
					if not y0 or y0 > math.min(nb.F, info.F) - 9 then
						holes += 1
					end
				end
			end
		end
	end
	-- El relieve (agujas, arcos, cuevas, la catedral) con un terreno de mentira que cuenta
	local relief = 0
	local fake = {}
	for _, name in { "FillBlock", "FillBall", "FillCylinder", "FillWedge" } do
		fake[name] = function()
			relief += 1
		end
	end
	function fake.SetMaterialColor() end
	OceanBuilder.relief(fake :: any)
	local total = fills + relief
	check(aboveSurface == 0, "Nada de agua ni fondo por encima de donde toca (no se inunda la costa ni sube el mar)")
	check(inLand == 0, "Ningún bloque dentro de la isla")
	check(holes == 0, "Las paredes altas (sima, garganta, cañón de las catedrales, borde del abismo) no dejan ver el vacío de debajo")
	check(total < 60000 and total < OLD_FILLS * 0.65, ("Arranque más barato: %d rellenos de terreno (%d del fondo y el agua + %d del relieve); antes %d (−%d %%)"):format(total, fills, relief, OLD_FILLS, math.floor((1 - total / OLD_FILLS) * 100 + 0.5)))
	check(vox < 260e6, ("…y %.0f millones de vóxeles de fondo (< 260)"):format(vox / 1e6))

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
print("\n▶ Mar enorme (vídeo de referencia del dueño, v120)")
do
	local SeaBeasts = L.load("src/shared/Sea/SeaBeasts")
	local Diving = L.load("src/shared/Sea/Diving")
	-- El megalodón: toda su ronda sobre más de 50 m de fondo
	local m = SeaBeasts.newMegalodon()
	local shallowest = math.huge
	for _ = 1, 4000 do
		m = SeaBeasts.stepMegalodon(m, 0.125, {})
		shallowest = math.min(shallowest, meters(Ocean.floorY(m.Pos.X, m.Pos.Z) or 0))
	end
	check(shallowest >= 50, ("El megalodón patrulla siempre sobre al menos 50 m de agua (lo menos hondo bajo él: %.0f m)"):format(shallowest))
	-- El kraken: su guarida y toda la sima donde embosca, a más de 50 m
	local Lr = Ocean.Lair
	local krakenOk = meters(Lr.Y) >= 50
	for a = 0, 15 do
		local x = Lr.X + math.cos(a / 16 * math.pi * 2) * SeaBeasts.Kraken.Ambush * 0.5
		local z = Lr.Z + math.sin(a / 16 * math.pi * 2) * SeaBeasts.Kraken.Ambush * 0.5
		local f = Ocean.floorY(x, z)
		if f and Ocean.sample(x, z).Trench > 0.5 and meters(f) < 50 then
			krakenOk = false
		end
	end
	check(krakenOk and meters(SeaBeasts.Kraken.MaxY) >= 50, ("El kraken vive a %.0f m y solo embosca más hondo de %.0f m"):format(meters(Lr.Y), meters(SeaBeasts.Kraken.MaxY)))
	-- El Cañón de las Catedrales: hondo, ancho, de paredes altas y al alcance de la botella (75 m)
	local c = Ocean.Cathedrals
	local deepest, shallowFloor, wallsOk, zoneOk = 0, math.huge, true, true
	for i = 1, #c.Points - 1 do
		for k = 0, 10 do
			local a, b = c.Points[i], c.Points[i + 1]
			local x, z = a[1] + (b[1] - a[1]) * k / 10, a[2] + (b[2] - a[2]) * k / 10
			local s0 = Ocean.sample(x, z)
			local mm = meters(s0.Floor or 0)
			deepest = math.max(deepest, mm)
			shallowFloor = math.min(shallowFloor, mm)
			if s0.Zone ~= "Catedrales" and s0.Basin < 0.5 then
				zoneOk = false
			end
			-- la pared: a HalfWidth + Wall del centro el fondo está mucho más alto
			local dx, dz = b[1] - a[1], b[2] - a[2]
			local len = math.sqrt(dx * dx + dz * dz)
			local off = c.HalfWidth + c.Wall + 10
			local rim = Ocean.floorY(x - dz / len * off, z + dx / len * off)
			if s0.Basin < 0.2 and rim and (rim - (s0.Floor or 0)) < 20 then
				wallsOk = false
			end
		end
	end
	local divingBottle = Diving.Gear.Botella.Depth
	check(deepest >= 50 and deepest <= divingBottle + 1 and shallowFloor >= 35, ("Cañón de las Catedrales: de %.0f a %.0f m (con botella se llega a todo)"):format(shallowFloor, deepest))
	check(wallsOk, "…con paredes altas (más de 20 studs) a los dos lados")
	check(zoneOk, "…y todo él es la zona «Cañón de las Catedrales»")
	-- Sitios nuevos
	local vh, ca = Ocean.PoiById.ValmarHundida, Ocean.PoiById.CatedralAbisal
	check(vh and Ocean.zoneAt(vh.X, vh.Z) == "Catedrales" and meters(Ocean.poiPosition(vh).Y) >= 35 and meters(Ocean.poiPosition(vh).Y) <= 60, "Valmar Hundida (el barrio de los faroles) está en el fondo del cañón, a entre 35 y 60 m")
	local C = Ocean.Cathedral
	local fy = Ocean.floorY(C.X, C.Z) or 0
	local center = Vector3.new(C.X, fy + C.Lift, C.Z)
	check(ca and (Ocean.poiPosition(ca) - center).Magnitude < C.Hollow - 6 and fy + C.Lift + C.Radius < Ocean.Surface - 60, "La Catedral Abisal: el sitio está dentro de la nave y la mole queda muy por debajo de la superficie")
	local mission = Diving.MissionById.ValmarHundida
	check(mission ~= nil and table.find(mission.Found, "ValmarHundida") ~= nil and table.find(mission.Found, "CatedralAbisal") ~= nil and Ocean.PoiById.ValmarHundida.Chest == true, "Misión «Valmar Hundida»: descubrir el barrio y la catedral y abrir su cofre")
	-- Agujas de roca
	local spires = Ocean.spires()
	local spiresOk = true
	for _, sp in spires do
		if SeaBeasts.ellipse(sp.X, sp.Z) <= SeaBeasts.Megalodon.Territory + 0.02 or sp.Base + sp.H > Ocean.Surface - 19.9 or Ocean.sample(sp.X, sp.Z).Keep > 0.01 or not Ocean.inArea(sp.X - sp.R, sp.Z - sp.R) or not Ocean.inArea(sp.X + sp.R, sp.Z + sp.R) then
			spiresOk = false
		end
		for _, poi in Ocean.Pois do
			if math.sqrt((sp.X - poi.X) ^ 2 + (sp.Z - poi.Z) ^ 2) < poi.Radius + sp.R then
				spiresOk = false
			end
		end
	end
	check(#spires >= 25 and spiresOk, ("%d agujas de roca en el borde del abismo y del cañón: dentro del mar construido, fuera del territorio del megalodón, lejos de puertos y sitios, y los barcos pasan por encima"):format(#spires))
	-- La vida grande (shared/Sea/Ambient): topes y caminos
	local Ambient = L.load("src/shared/Sea/Ambient")
	local mobile, desktop = Ambient.Caps.Mobile, Ambient.Caps.Desktop
	local function worstGiant(n)
		local most = 0
		for _, id in Ambient.GiantOrder do
			most = math.max(most, Ambient.Giants[id].Parts)
		end
		return most * n
	end
	check(mobile.Jellies * Ambient.JellyParts + worstGiant(mobile.Giants) <= mobile.Parts and mobile.Parts <= 70, ("Móvil: %d medusas y %d gigante a la vez, como mucho %d piezas"):format(mobile.Jellies, mobile.Giants, mobile.Parts))
	check(desktop.Jellies * Ambient.JellyParts + worstGiant(desktop.Giants) <= desktop.Parts and desktop.Parts <= 160, ("Ordenador: %d medusas y %d gigantes, como mucho %d piezas"):format(desktop.Jellies, desktop.Giants, desktop.Parts))
	local slSrc = fs.readFile("src/client/Controllers/SeaLife.luau")
	local slMobile = tonumber(string.match(slSrc, "Budget = { Mobile = (%d+)")) or 0
	check(slMobile + mobile.Parts <= 240, ("En el móvil, toda la vida que se mueve (SeaLife %d + SeaAmbient %d) ≤ 240 piezas"):format(slMobile, mobile.Parts))
	-- en ningún sitio el plan de medusas se pasa del tope
	local overCap = false
	for _, f in Ocean.JellyFields do
		for _, lite in { true, false } do
			local n = 0
			for _, e in Ambient.jellyPlan(Vector3.new(f.X, -60, f.Z), lite) do
				n += e.Count
			end
			if n > Ambient.caps(lite).Jellies then
				overCap = true
			end
		end
	end
	check(not overCap, "Los campos de medusas nunca se pasan del tope (los cercanos primero)")
	-- cada medusa en su campo y en el agua
	local inWater = true
	for _, f in Ocean.JellyFields do
		for i = 1, 12 do
			local floor = Ambient.jellyFloor(f, i)
			for _, t in { 0, 7.5, 33 } do
				local pos = Ambient.jelly(f, i, t, floor)
				if pos.Y < floor + 5.9 or pos.Y > Ocean.Surface - 5.9 or math.sqrt((pos.X - f.X) ^ 2 + (pos.Z - f.Z) ^ 2) > f.R + 4 then
					inWater = false
				end
			end
		end
	end
	check(inWater and #Ocean.JellyFields >= 4, ("%d campos de medusas que brillan: cada una en su campo y siempre en el agua"):format(#Ocean.JellyFields))
	-- los gigantes: siempre en el agua, nunca encima de ti y se van
	local tries, made, wet = 0, 0, true
	local spots = { Vector3.new(-1500, -120, 5300), Vector3.new(3000, -150, 4700), Vector3.new(-2000, -60, 4500), Vector3.new(4600, -20, -640) }
	for _, cam in spots do
		for k = 1, 30 do
			local zone = Ocean.zoneAt(cam.X, cam.Z)
			local kind = Ambient.pickGiant(zone, Ocean.hash(k, 1, 500))
			if kind then
				tries += 1
				local look = Vector3.new(math.cos(k), 0, math.sin(k))
				local path = Ambient.path(kind, cam, look, Ocean.hash(k, 2, 500), Ocean.hash(k, 3, 500), Ocean.hash(k, 4, 500))
				if path then
					made += 1
					local def = Ambient.Giants[kind]
					for st = 0, 10 do
						local pos = Ambient.at(path, path.Duration * st / 10)
						local f = Ocean.floorY(pos.X, pos.Z)
						if not f or pos.Y < f + def.Height or pos.Y > Ocean.Surface - 6 - def.Height + 0.01 then
							wet = false
							print(("    %s: fuera del agua en (%.0f, %.0f, %.0f), fondo %s"):format(kind, pos.X, pos.Y, pos.Z, tostring(f)))
						end
						if (pos - cam).Magnitude < def.Distance[1] * 0.75 then
							wet = false
							print(("    %s: demasiado cerca (%.0f)"):format(kind, (pos - cam).Magnitude))
						end
					end
					if not Ambient.done(path, path.Duration + 0.1, cam) then
						wet = false
					end
				end
			end
		end
	end
	check(made > 20 and wet, ("Ballenas, mantas y el leviatán pasan a lo lejos siempre en el agua, sin acercarse a ti, y se van (%d de %d pasos posibles)"):format(made, tries))
	local ambSrc = fs.readFile("src/client/Controllers/SeaAmbient.luau")
	check(string.find(ambSrc, "BulkMoveTo", 1, true) ~= nil and string.find(ambSrc, "CanCollide = false", 1, true) ~= nil and string.find(ambSrc, "CanQuery = false", 1, true) ~= nil and string.find(ambSrc, "Ambient.done", 1, true) ~= nil, "Todo en tu pantalla, sin choques ni consultas, movido con BulkMoveTo y quitado al pasar")
	check(string.find(slSrc, "SeaAmbient", 1, true) ~= nil, "SeaLife arranca SeaAmbient")
	-- La luz del mar enorme: bruma azul que deja ver lejos; más oscura y azul abajo; rayos arriba;
	-- bioluminiscencia abajo
	local world = OceanBiomes.world()
	local farOk = true
	for _, id in world.ZoneOrder do
		local lk = OceanBiomes.look(id, 0)
		if id ~= "Sima" and (lk.Visibility < 130 or lk.Density > 0.56) then
			farOk = false
			print("    " .. id .. ": se ve poco")
		end
	end
	check(farOk, "Todas las zonas (menos la Sima) dejan ver lejos: bruma suave (≤ 0,56) y más de 130 studs")
	local up, down = OceanBiomes.look("Abismo", 3), OceanBiomes.look("Abismo", 70)
	local blue = down.Fog.B > down.Fog.R and down.Fog.B > down.Fog.G and math.max(down.Fog.R, down.Fog.G, down.Fog.B) * 255 >= 40
	check(down.Exposure < up.Exposure and blue, "Abajo más oscuro pero azul (nunca negro: la bruma se sigue viendo)")
	check(up.Rays > 0.8 and OceanBiomes.look("Llanura", 35).Rays == 0 and down.Glow > 0.9 and up.Glow == 0, "Rayos de sol cerca de la superficie que se apagan con la hondura; abajo manda la bioluminiscencia")
end

---------------------------------------------------------------------
print("\n▶ La luz bajo el agua es una zona (EnvZones «Submarino», un solo dueño: EnvDirector)")
do
	local EnvZones = L.load("src/shared/Cosmos/EnvZones")
	local function resolve(under: number?, y: number?)
		return EnvZones.resolve({ Pos = Vector3.new(-1500, y or -100, 5300), Sea = if under then { Under = under, Look = OceanBiomes.look("Catedrales", 40) } else nil })
	end
	local dry, wet = resolve(nil, 5), resolve(1)
	check(dry.Zone == "Valmar" and (dry.Under or 0) == 0, "Fuera del agua: Valmar de siempre")
	check(wet.Zone == "Submarino" and wet.Under == 1 and wet.SeaLook ~= nil, "Con la cámara bajo el agua: zona «Submarino» con la luz del mar de la zona")
	local fw = EnvZones.flags(wet)
	check(fw.Underwater and not fw.Weather and fw.Atmosphere and fw.ColorCorrection, "Bajo el agua: bruma y etalonaje puestos, sin lluvia ni nieve")
	local fd = EnvZones.flags(dry)
	check(not fd.Underwater and fd.Weather, "Al salir vuelve el tiempo de Valmar")
	-- histéresis: 0,5 no cambia lo que había
	check(EnvZones.flags(resolve(0.5), fw).Underwater and not EnvZones.flags(resolve(0.5), fd).Underwater, "Sin parpadeos en la superficie (histéresis)")
	-- el espacio manda: allí no hay mar
	local space = EnvZones.resolve({ Pos = Vector3.new(300, 20000, -200), Sea = { Under = 1, Look = OceanBiomes.look("Abismo", 60) } })
	check(space.Zone ~= "Submarino" and (space.Under or 0) == 0, "Lejos del mar (el espacio) no hay luz de agua")
	-- la luz: mezcla hacia la del mar
	local noon = { Brightness = 3, Exposure = 0, Ambient = Color3.fromRGB(120, 120, 120), Outdoor = Color3.fromRGB(140, 140, 140), Density = 0.3, Offset = 0.2, AtmColor = Color3.fromRGB(200, 210, 225), Decay = Color3.fromRGB(110, 120, 140), Glare = 0.3, Haze = 1.5, Tint = Color3.fromRGB(255, 255, 255), Saturation = 0, Contrast = 0.1, CCBright = 0, Bloom = 0.6, BloomSize = 24, Threshold = 1.5, Rays = 0.1, RaysSpread = 0.5 }
	local kDry = EnvZones.applyKey(noon, dry)
	local kShallow = EnvZones.applyKey(noon, EnvZones.resolve({ Pos = Vector3.new(4600, -10, -640), Sea = { Under = 1, Look = OceanBiomes.look("Arrecife", 3) } }))
	local kDeep = EnvZones.applyKey(noon, EnvZones.resolve({ Pos = Vector3.new(3000, -240, 4700), Sea = { Under = 1, Look = OceanBiomes.look("Abismo", 65) } }))
	check(kDry.AtmColor == noon.AtmColor and kDry.Density == noon.Density, "Fuera del agua la luz no cambia")
	check(kShallow.AtmColor.B > kShallow.AtmColor.R and kDeep.Exposure < kShallow.Exposure and kDeep.Bloom > kShallow.Bloom, "Bajo el agua: bruma azul; abajo más oscuro y la bioluminiscencia brilla más (Bloom)")
	check(kShallow.Rays > kDeep.Rays, "Los rayos de sol se apagan con la hondura")
	-- Un solo dueño: SeaBiome se lo dice a EnvDirector (no a DayLight)
	local biome = fs.readFile("src/client/Controllers/SeaBiome.luau")
	local daylight = fs.readFile("src/client/Controllers/DayLight.luau")
	local director = fs.readFile("src/client/Controllers/EnvDirector.luau")
	check(string.find(biome, "EnvDirector.setSea", 1, true) ~= nil and string.find(biome, "DayLight.", 1, true) == nil, "SeaBiome cuenta lo del agua a EnvDirector (ya no toca DayLight)")
	check(string.find(daylight, "function DayLight.setUnderwater", 1, true) == nil and string.find(director, "function EnvDirector.setSea", 1, true) ~= nil, "DayLight solo pinta la luz de la zona (sin interruptor propio del agua)")
	-- EnvDirector de verdad: setSea → la zona que recibe DayLight
	local got = nil
	L.mock("src/client/Controllers/DayLight", { setZone = function(e) got = e end })
	L.mock("src/client/Controllers/SkyRift", { setSuppressed = function() end })
	L.mock("src/client/Controllers/PlanetClient", {})
	local oldPlayers = L.services.Players
	L.services.Players = { LocalPlayer = L.player("Buzo", 5) }
	L.mock("src/client/UI/FlightFocus", { setZone = function() end })
	L.reset("src/client/Controllers/EnvDirector")
	local okDir, Director = pcall(L.load, "src/client/Controllers/EnvDirector")
	if okDir and Director then
		Director._reset()
		Director.setSea(1, OceanBiomes.look("Catedrales", 40))
		for _ = 1, 3 do
			Director.update(0.1, Vector3.new(-1500, -120, 5300))
		end
		local e1 = got
		Director.setSea(nil)
		for _ = 1, 3 do
			Director.update(0.1, Vector3.new(-1500, 5, 5300))
		end
		check(e1 and e1.Zone == "Submarino" and e1.Under == 1 and got and got.Zone == "Valmar" and (got.Under or 0) == 0 and Director.allows("Weather"), "EnvDirector: al bucear pasa a «Submarino» (sin lluvia) y al salir vuelve a Valmar")
		-- 🔊 El sonido bajo el mar (docs/audio/zonas.md): la misma zona, sin pájaros ni olas de la orilla
		local zoneSounds = {}
		L.mock("src/client/Controllers/StoryAudio", { setZone = function(s)
			table.insert(zoneSounds, s)
		end })
		L.reset("src/client/Controllers/EnvDirector")
		local Snd = L.load("src/client/Controllers/EnvDirector")
		Snd.update(0.1, Vector3.new(-1500, 5, 5300))
		check(Snd.soundscape().Key == "Valmar" and Snd.valmarAudio() == 1, "nadando en la superficie: el sonido de Valmar (olas, pájaros)")
		Snd.setSea(1, OceanBiomes.look("Catedrales", 40))
		Snd.update(0.1, Vector3.new(-1500, -120, 5300))
		local under = Snd.soundscape()
		check(under.Key == "Submarino" and under.Ambience == "Submarino" and Snd.valmarAudio() == 0 and zoneSounds[#zoneSounds].Key == "Submarino", "bajo el agua: rumor apagado, burbujas y ballenas lejos; ni pájaros ni olas ni ciudad")
		local Nacara = L.load("src/shared/Sea/Nacara")
		Snd.update(0.1, Nacara.centerPosition() + Vector3.new(30, 8, 0))
		check(Snd.soundscape().Key == "Nacara" and Snd.soundscape().Music[1] == "Nacara", "junto a Nácara: su música etérea")
		Snd.setSea(nil)
		Snd.update(0.1, Nacara.domeCenter() + Vector3.new(0, 4, 0))
		check(Snd.soundscape().Key == "Nacara" and Snd.valmarAudio() == 0, "y dentro de su cúpula de aire también (no suena la calle de Valmar)")
		Snd.update(0.1, Vector3.new(-1500, 5, 5300))
		check(Snd.soundscape().Key == "Valmar", "al salir a la superficie, Valmar otra vez")
		L.mock("src/client/Controllers/StoryAudio", nil)
	else
		check(false, "EnvDirector se carga en la prueba: " .. tostring(Director))
	end
	L.services.Players = oldPlayers
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

---------------------------------------------------------------------
print("\n▶ La orilla (v122: captura del dueño de noche, fondo marrón con cubos negros)")
do
	local ShoreDecor = L.load("src/shared/Sea/ShoreDecor")
	local function h(a: number, b: number, c: number): number
		local v = math.sin(a * 127.1 + b * 311.7 + c * 74.7) * 43758.5453
		return v - math.floor(v)
	end
	-- Las recetas del fondo: nunca un bloque sin malla, nada de basalto negro ni de grava gris, y
	-- colores vivos (no marrones)
	local blocks, banned, brown, total, made = 0, 0, 0, 0, 0
	local kindsSeen = {}
	local BANNED = { Basalt = true, Pebble = true, Slate = true, Mud = true, Ground = true }
	for kind, make in ShoreDecor.Kinds do
		for i = 1, 60 do
			for _, mobile in { false, true } do
				local at = Vector3.new(i * 13.7, -14, i * 7.3)
				local rec = make(at, h(i, 1, 2), h, { Mobile = mobile, MeshRocks = i % 2 == 0 })
				made += 1
				kindsSeen[kind] = true
				for _, piece in rec.Pieces do
					total += 1
					if piece.Shape == nil and piece.Mesh == nil then
						blocks += 1
					end
					if BANNED[piece.Material] then
						banned += 1
					end
					if ShoreDecor.isBrown(piece.Color) then
						brown += 1
					end
				end
				for _, sw in rec.Sways do
					total += 1
					if BANNED[sw.Material or "SmoothPlastic"] then
						banned += 1
					end
					if ShoreDecor.isBrown(sw.Color) then
						brown += 1
					end
				end
				if rec.MeshRock and BANNED[rec.MeshRock.Material] then
					banned += 1
				end
			end
		end
	end
	check(made > 1000 and total > 5000, ("%d cosas del fondo con %d piezas"):format(made, total))
	check(blocks == 0, ("Ninguna pieza es un bloque cuadrado: bolas, cilindros, elipsoides o la malla de roca (%d bloques)"):format(blocks))
	check(banned == 0, "Sin basalto (salía negro), grava, pizarra ni barro en el fondo de la orilla")
	check(brown / total < 0.05, ("La paleta no es marrón (%.1f %% de piezas marrones)"):format(100 * brown / total))
	check(kindsSeen.CoralHead and kindsSeen.Branch and kindsSeen.Table and kindsSeen.Fan and kindsSeen.Anemone and kindsSeen.Seagrass and kindsSeen.Rock and kindsSeen.Shell and kindsSeen.Starfish and kindsSeen.Crab and kindsSeen.Urchin, "Arrecife costero: corales cerebro, de ramas y mesa, abanicos, anémonas, praderas, rocas, conchas, estrellas, cangrejos y erizos")
	-- Las rocas: con mallas, una malla de asteroide; sin ellas, bolas (nunca un bloque)
	local rockMesh = ShoreDecor.Rock(Vector3.new(0, -14, 0), 0.5, h, { MeshRocks = true })
	local rockBalls = ShoreDecor.Rock(Vector3.new(0, -14, 0), 0.5, h, { MeshRocks = false })
	local ballsOk = true
	for _, piece in rockBalls.Pieces do
		if piece.Material == "Rock" and piece.Shape ~= "Ball" then
			ballsOk = false
		end
	end
	check(rockMesh.MeshRock ~= nil and rockMesh.MeshRock.Variant >= 1 and rockMesh.MeshRock.Variant <= 6 and ballsOk and #rockBalls.Pieces >= 4, "Rocas irregulares: la malla de asteroide (Blender) o un racimo de bolas, con musgo y percebes")
	-- La hierba: alta y tupida
	local grass = ShoreDecor.Seagrass(Vector3.new(0, -14, 0), 0.5, h, { Mobile = true })
	local tallest = 0
	for _, sw in grass.Sways do
		local hh = 0
		for _, x in sw.Heights do
			hh += x
		end
		tallest = math.max(tallest, hh)
	end
	check(#grass.Sways >= 8 and tallest >= 3.5, ("Praderas tupidas y altas (%d hojas, hasta %.1f studs; antes 5-9 de 1-3 studs)"):format(#grass.Sways, tallest))
	-- Las zonas de la orilla plantan arrecife
	local world = OceanBiomes.world()
	for _, id in { "Orilla", "Coral", "Arrecife" } do
		local f = world.Zones[id].Flora
		check((f.CoralHead or 0) > 0 and (f.Anemone or 0) > 0 and (f.Shell or 0) > 0 and (f.Starfish or 0) > 0 and (f.Crab or 0) > 0, ("%s: corales redondos, anémonas, conchas, estrellas y cangrejos"):format(world.Zones[id].Name))
	end
	-- SeaBiome usa las recetas para la roca, las conchas y la hierba; ya no hay rocas de basalto
	local biome = fs.readFile("src/client/Controllers/SeaBiome.luau")
	check(string.find(biome, 'local rock = decorFn("Rock")', 1, true) ~= nil and string.find(biome, 'Shell = decorFn("Shell")', 1, true) ~= nil and string.find(biome, "Enum.Material.Basalt else", 1, true) == nil and string.find(biome, "Enum.Material.Pebble", 1, true) == nil, "SeaBiome planta las recetas (sin los cubos de basalto ni la grava de antes)")
	local budget = tonumber(string.match(fs.readFile("src/shared/Sea/ShoreDecor.luau"), "Budget = { Mobile = (%d+)")) or math.huge
	check(budget <= 1500 and string.find(biome, "pieceCount > PIECE_BUDGET", 1, true) ~= nil, ("Móvil: tope de %d piezas del fondo en tu pantalla, por trozos que se quitan al alejarte"):format(budget))

	-- SeaBiome de verdad (con piezas de Lune): lo que planta en la orilla no tiene bloques ni basalto
	L.globals.RaycastParams = { new = function()
		return {}
	end }
	L.services.Players = { LocalPlayer = {} }
	L.mock("src/client/UI/Perf", { mobile = true })
	L.mock("src/client/Controllers/EnvDirector", { setSea = function() end })
	local okBiome, SeaBiome = pcall(L.load, "src/client/Controllers/SeaBiome")
	check(okBiome, "SeaBiome se carga" .. (if okBiome then "" else ": " .. tostring(SeaBiome)))
	if okBiome then
		local partsMade, cubes, black = 0, 0, 0
		for _, kind in { "CoralHead", "Branch", "Table", "Fan", "Anemone", "Seagrass", "Rock", "Shell", "Starfish", "Crab", "Urchin" } do
			for i = 1, 6 do
				local cell = SeaBiome._plant(kind, Vector3.new(i * 20, -14, 0), h(i, 3, 4))
				for _, p in cell.Parts do
					partsMade += 1
					local isBlade = kind == "Seagrass" -- (hojas: láminas finas)
					if p:IsA("Part") and p.Shape == roblox.Enum.PartType.Block and not p:FindFirstChildOfClass("SpecialMesh") and not isBlade then
						cubes += 1
					end
					if p.Material == roblox.Enum.Material.Basalt or p.Material == roblox.Enum.Material.Slate or p.Material == roblox.Enum.Material.Pebble then
						black += 1
					end
				end
			end
		end
		check(partsMade > 300 and cubes == 0 and black == 0, ("SeaBiome planta %d piezas del arrecife costero: ningún cubo, nada de basalto ni pizarra"):format(partsMade))
	end

	-- El fondo: arena blanca (Salt) y no la arena de playa marrón (Sand con la textura del dueño)
	for _, id in { "Orilla", "Coral", "Arrecife", "Llanura" } do
		check(world.Zones[id].Materials.Floor ~= "Sand", ("%s: fondo de arena blanca (%s), no la textura marrón de la playa"):format(world.Zones[id].Name, world.Zones[id].Materials.Floor))
	end
	local tb = fs.readFile("src/server/World/TerrainBuilder.luau")
	check(string.find(tb, "-24, -14, Enum.Material.Salt)", 1, true) ~= nil and string.find(tb, "Salt = TerrainPalette.Sea.Salt", 1, true) ~= nil, "Junto a la orilla (TerrainBuilder) el fondo también es Salt (arena clara dorada, shared/TerrainPalette)")
	local ob = fs.readFile("src/server/World/OceanBuilder.luau")
	check(string.find(ob, "Salt = Enum.Material.Salt", 1, true) ~= nil, "OceanBuilder sabe rellenar con Salt (si no, volvía a Sand)")
	local uc = fs.readFile("src/shared/UserMaterialChoice.luau")
	check(string.find(uc, 'Material = "Salt"', 1, true) == nil, "Salt no lo sustituye ninguna textura de la tienda (se ve como es)")
	-- Manchas, dunas y rocas de la orilla (OceanBuilder.shore): en el mar, fuera de puertos, bajas
	local OceanBuilder = L.load("src/server/World/OceanBuilder")
	local plan = OceanBuilder.shorePlan()
	local planOk, kinds = true, {}
	for _, sp in plan do
		kinds[sp.Kind] = (kinds[sp.Kind] or 0) + 1
		local smp = Ocean.sample(sp.X, sp.Z)
		if not smp.Floor or smp.Keep >= 0.05 or smp.D <= 6 then
			planOk = false
		end
	end
	check(#plan > 800 and planOk and (kinds.Sand or 0) > 0 and (kinds.Limestone or 0) > 0 and (kinds.Rock or 0) > 0 and (kinds.Dune or 0) > 0, ("Fondo de la orilla variado: %d manchas de arena, caliza, dunas y rocas, todas en el mar y fuera de puertos"):format(#plan))
	check(string.find(ob, "y + 2.6 - r", 1, true) ~= nil and string.find(ob, "y - r + 1.4", 1, true) ~= nil, "Las rocas suben 2,6 studs y las dunas 1,4 como mucho (nadar y barcos igual)")

	-- Jardines de coral junto a las playas
	local Diving = L.load("src/shared/Sea/Diving")
	local reefsOk = true
	for _, reef in Ocean.ShoreReefs do
		local d = Ocean.landDistance(reef.X, reef.Z)
		local f = Ocean.floorY(reef.X, reef.Z)
		if d < 60 or d > 150 or Ocean.zoneAt(reef.X, reef.Z) ~= "Coral" or not f or Ocean.meters(f) < 2.5 or not Ocean.PoiById[reef.Id] then
			reefsOk = false
			print(("    %s: a %.0f studs de tierra, zona %s"):format(reef.Id, d, tostring(Ocean.zoneAt(reef.X, reef.Z))))
		end
	end
	check(#Ocean.ShoreReefs >= 15 and reefsOk, ("%d jardines de coral, cada uno a 60-150 studs de la playa, a más de 2,5 m y descubribles"):format(#Ocean.ShoreReefs))
	-- Desde cualquier playa (fuera de puertos, kelp y arrecife), un arrecife cerca
	local coast = CityPlan.Coast
	local function isCliff(i: number): boolean
		for _, r in CityPlan.Cliffs do
			if i >= r[1] and i < r[2] then
				return true
			end
		end
		return false
	end
	local worst, n = 0, 0
	for i = 1, #coast do
		if not isCliff(i) then
			local a, b = coast[i], coast[i % #coast + 1]
			for k = 0, 8 do
				local x, z = a[1] + (b[1] - a[1]) * k / 8, a[2] + (b[2] - a[2]) * k / 8
				local smp = Ocean.sample(x + 1, z + 1)
				local inReef = false
				for _, list in { Ocean.Reefs, Ocean.Kelp } do
					for _, c in list do
						if (x - c.X) ^ 2 + (z - c.Z) ^ 2 < (c.R + 150) ^ 2 then
							inReef = true
						end
					end
				end
				if smp.Keep < 0.05 and not inReef then
					local best = math.huge
					for _, id in Diving.Reefs do
						local poi = Ocean.PoiById[id]
						best = math.min(best, math.sqrt((poi.X - x) ^ 2 + (poi.Z - z) ^ 2))
					end
					worst = math.max(worst, best)
					n += 1
				end
			end
		end
	end
	check(n > 100 and worst < 700, ("Desde cualquier playa hay un jardín de coral a menos de %.0f studs (%.0f m; antes, 2,6 km)"):format(worst, worst / Ocean.StudsPerMeter))
	local dorada = CityPlan.Places and CityPlan.Places["Playa Dorada"]
	local best = math.huge
	for _, reef in Ocean.ShoreReefs do
		local coastX = 4215 -- (la arena de Playa Dorada, a la altura del jardín)
		if reef.Id == "CoralDorada" then
			best = math.abs(reef.X - coastX)
		end
	end
	check(best <= 150, ("Playa Dorada: su jardín de coral a %d studs de la arena%s"):format(best, if dorada then "" else ""))
	-- «Explora el arrecife»: vale cualquiera (el más cercano), dos para cobrar
	local m = Diving.MissionById.Arrecife
	check(m.FoundAny and m.Need == 2 and #m.FoundAny == #Ocean.ShoreReefs + 2, "«Explora el arrecife»: dos arrecifes cualesquiera (Arco de Coral, Jardín Escarlata o un jardín de la orilla)")
	local d1, t1 = Diving.progress(m, { Found = { [Ocean.ShoreReefs[3].Id] = true } })
	local d2, t2 = Diving.progress(m, { Found = { [Ocean.ShoreReefs[3].Id] = true, CoralDorada = true, ArcoCoral = true } })
	check(d1 == 1 and t1 == 2 and d2 == 2 and t2 == 2, "Progreso 1/2 con un jardín; 2/2 (no 3/2) con tres")
	local hud = fs.readFile("src/client/Controllers/DiveHud.luau")
	check(string.find(hud, "mission.FoundAny", 1, true) ~= nil, "El HUD lleva al jardín sin descubrir más cercano")

	-- La luz bajo el agua de noche: azul de luna, no barro
	local DayGrade = L.load("src/shared/DayGrade")
	local EnvZones = L.load("src/shared/Cosmos/EnvZones")
	local function under(hour: number, zone: string, meters: number, night: number)
		local k = DayGrade.sample(hour)
		local env = EnvZones.resolve({ Pos = Vector3.new(4300, -9, -300), Sea = { Under = 1, Look = OceanBiomes.look(zone, meters, nil, night) } })
		return EnvZones.applyKey(k, env), OceanBiomes.look(zone, meters, nil, night)
	end
	local kn, ln = under(2.5, "Orilla", 2, 1)
	local function blue(c: Color3, margin: number): boolean
		return c.B * 255 > c.R * 255 + margin and c.B >= c.G
	end
	check(blue(kn.Tint, 60) and blue(kn.AtmColor, 40) and blue(kn.Decay, 20), ("De noche en la orilla: etalonaje y bruma azules (tinte %d,%d,%d)"):format(kn.Tint.R * 255, kn.Tint.G * 255, kn.Tint.B * 255))
	check(blue(kn.Ambient, 40) and blue(kn.Outdoor, 40) and kn.Outdoor.B * 255 >= 150, ("…con luz de luna azul que deja ver el fondo (ambiente de fuera %d,%d,%d)"):format(kn.Outdoor.R * 255, kn.Outdoor.G * 255, kn.Outdoor.B * 255))
	check(blue(ln.Water, 40) and not ShoreDecor.isBrown(ln.Water) and not ShoreDecor.isBrown(kn.Tint) and not ShoreDecor.isBrown(kn.AtmColor), "…y el agua del terreno azul marino (nada marrón)")
	check(kn.Exposure >= DayGrade.sample(2.5).Exposure + 0.1 and ln.Glow >= 0.5, "…algo más de exposición y bioluminiscencia también en la orilla")
	local kd, ld = under(12, "Orilla", 2, 0)
	check(kd.Tint.G > kd.Tint.R and kd.Tint.B > kd.Tint.R and ld.Water.G > ld.Water.R * 2 and ld.Water.B > ld.Water.R * 2, ("De día en la orilla: turquesa claro (agua %d,%d,%d)"):format(ld.Water.R * 255, ld.Water.G * 255, ld.Water.B * 255))
	local deep = OceanBiomes.look("Llanura", 10, nil, 0)
	check(deep.Water.B > deep.Water.G and ld.Water.G > deep.Water.G, "Más lejos y más hondo, más azul oscuro")
	-- El agua del terreno: la ponen WorldService (de siempre) y SeaBiome (bajo el agua, solo en tu pantalla)
	local ws = fs.readFile("src/server/Services/WorldService.luau")
	local transp = tonumber(string.match(ws, "terrain.WaterTransparency = ([%d.]+)")) or 0
	check(transp >= 0.5 and transp <= 0.9, ("Agua clara: WaterTransparency %.2f"):format(transp))
	check(string.find(biome, "terrain.WaterTransparency = d.Transparency + (0.72 - d.Transparency) * k", 1, true) ~= nil, "En el agua aún más clara (0,72) para ver el fondo")
	local writers = {}
	for _, dir in { "src/client/Controllers", "src/server/Services", "src/server/World" } do
		for _, name in fs.readDir(dir) do
			if string.sub(name, -5) == ".luau" then
				local src = fs.readFile(dir .. "/" .. name)
				if string.find(src, "%.WaterColor = ") then
					table.insert(writers, name)
				end
			end
		end
	end
	table.sort(writers)
	check(#writers <= 3, ("Solo pintan el color del agua: %s"):format(table.concat(writers, ", ")))

	-- La línea de guía en el agua: fina, tenue y corta
	local tm = fs.readFile("src/client/Controllers/TaskMarker.luau")
	local w0, w1, len, tr0 = string.match(tm, "TaskMarker.Water = { Width0 = ([%d.]+), Width1 = ([%d.]+), Length = ([%d.]+), Transparency0 = ([%d.]+)")
	w0, w1, len, tr0 = tonumber(w0), tonumber(w1), tonumber(len), tonumber(tr0)
	check(w0 and w0 <= 0.2 and w1 <= 0.1 and len <= 30 and tr0 >= 0.6, ("En el agua la línea del objetivo mide %s studs de ancho, %s de largo y es casi transparente (%s)"):format(tostring(w0), tostring(len), tostring(tr0)))
	check(string.find(tm, 'GetAttribute("SwimMode")', 1, true) ~= nil, "…se pone fina al nadar o bucear")

	-- Nadar a 2 m en la orilla: nadas, no andas por el fondo
	local floorY = Ocean.CoastY
	local root = Ocean.Surface - Ocean.studs(2)
	check(Swim.deepEnough(floorY, 1), "En la orilla (fondo a 3,4 m) no se hace pie: se nada")
	local mode, vy = Swim.step({ Mode = "Dive", RootY = root, FloorY = floorY, Scale = 1, Input = 0, Moving = 0 })
	check(mode == "Dive" and math.abs(vy) < 0.01, "A 2 m, quieto: flotas a esa profundidad (flotabilidad neutra)")
	check(Swim.FloorClear >= 3.4, ("Bajando al fondo el cuerpo se queda a %.1f studs: los pies no tocan la arena (de pie, la cadera queda a ~3)"):format(Swim.FloorClear))
end

-- v125: el fondo «nieve blanca» de la v124. El terreno es UNO para todo el place: World/PlanetWorld
-- pintaba Tefra (Salt ceniza clara…) en el mismo terreno después de TerrainBuilder.
print("\n▶ v125: los colores del terreno (fondo del mar dorado, no blanco; los planetas no lo pisan)")
do
	local TerrainPalette = L.load("src/shared/TerrainPalette")
	local Tefra = L.load("src/shared/Cosmos/Tefra")
	-- Un terreno de mentira con los colores por material, como Terrain.MaterialColors (8 bits)
	local function fakeTerrain()
		local colors = {}
		local t = {}
		function t.SetMaterialColor(_, material, color)
			colors[material.Name] = Color3.fromRGB(math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
		end
		function t.GetMaterialColor(_, material)
			return colors[material.Name] or Color3.fromRGB(255, 255, 255)
		end
		t.colors = colors
		return t
	end
	local sea = TerrainPalette.Sea
	check(not TerrainPalette.snowy(sea.Salt) and not TerrainPalette.snowy(sea.Sandstone) and not TerrainPalette.snowy(sea.Limestone), "La arena del fondo (Salt, Sandstone, Limestone) no es blanca")
	check(sea.Salt.R > sea.Salt.B + 0.15, "Salt del fondo es dorada (más roja que azul)")
	-- (lo que pasaba: Tefra pisaba Salt con ceniza clara)
	check(TerrainPalette.snowy(Tefra.TerrainColors.Salt), "(Comprobado: el Salt de Tefra es gris blanquecino: con él, el fondo de Valmar era «nieve»)")
	-- Ningún script del servidor pinta un material de Valmar salvo TerrainBuilder, OceanBuilder y UserMaterials
	local allowed = { ["src/server/World/TerrainBuilder.luau"] = true, ["src/server/World/OceanBuilder.luau"] = true, ["src/server/World/UserMaterials.luau"] = true }
	local offenders = {}
	local function scan(dir)
		for _, name in fs.readDir(dir) do
			local path = dir .. "/" .. name
			if fs.isDir(path) then
				scan(path)
			elseif string.match(name, "%.luau$") and not allowed[path] then
				local src = fs.readFile(path)
				for line in string.gmatch(src, "[^\n]+") do
					if string.find(line, "SetMaterialColor", 1, true) and not string.match(line, "^%s*%-%-") then
						table.insert(offenders, path)
						break
					end
				end
			end
		end
	end
	scan("src/server")
	check(#offenders == 0, "Solo TerrainBuilder, OceanBuilder y UserMaterials pintan el terreno en el servidor" .. (if #offenders > 0 then (" (y también: %s)"):format(table.concat(offenders, ", ")) else ""))
	local planetSrc = fs.readFile("src/server/World/PlanetWorld.luau")
	check(not string.find(planetSrc, ":SetMaterialColor(", 1, true), "World/PlanetWorld ya no pinta el terreno de Tefra en el servidor")
	local um = fs.readFile("src/server/World/UserMaterials.luau")
	local terrainList = string.match(um, "local TERRAIN = (%b{})") or ""
	check(not string.find(terrainList, "Salt", 1, true) and not string.find(terrainList, "Sandstone", 1, true), "UserMaterials no aclara (Whiten) los materiales del fondo del mar")
	local choice = fs.readFile("src/shared/UserMaterialChoice.luau")
	check(not string.find(choice, 'Material = "Salt"', 1, true) and not string.find(choice, 'Material = "Sandstone"', 1, true), "MaterialService: ningún MaterialVariant sustituye Salt ni Sandstone (el fondo usa su color, sin textura de la tienda)")
	local tb = fs.readFile("src/server/World/TerrainBuilder.luau")
	check(string.find(tb, "Salt = TerrainPalette.Sea.Salt", 1, true) ~= nil and string.find(tb, "terrain:SetMaterialColor", 1, true) ~= nil, "TerrainBuilder pone la paleta del mar al arrancar el servidor (runtime)")

	-- El cliente: Valmar → Tefra → Valmar, y si algo pisa el fondo, lo devuelve
	L.services.Players = L.services.Players or { LocalPlayer = { SetAttribute = function() end } }
	local Client = L.load("src/client/Controllers/TerrainPaletteClient")
	local terrain = fakeTerrain()
	local valmarSlate = Color3.fromRGB(100, 98, 94)
	terrain:SetMaterialColor(roblox.Enum.Material.Slate, valmarSlate)
	for name, color in sea do
		terrain:SetMaterialColor((roblox.Enum.Material :: any)[name], color)
	end
	-- Lo de la v124: después, alguien pinta Tefra en el mismo terreno
	for name, color in Tefra.TerrainColors do
		terrain:SetMaterialColor((roblox.Enum.Material :: any)[name], color)
	end
	check(TerrainPalette.snowy(terrain.colors.Salt), "(Comprobado: con la secuencia de la v124 el fondo queda blanco)")
	local planets = { { Id = "Tefra", contains = Tefra.contains, TerrainColors = Tefra.TerrainColors } }
	local fixes = Client.step(terrain :: any, Vector3.new(0, -10, 900), planets)
	check(fixes >= 3 and TerrainPalette.same(terrain.colors.Salt, sea.Salt), ("En Valmar el cliente devuelve el fondo dorado (%d colores corregidos)"):format(fixes))
	check(Client.step(terrain :: any, Vector3.new(0, -10, 900), planets) == 0, "…y luego no toca nada (0 correcciones)")
	terrain:SetMaterialColor(roblox.Enum.Material.Slate, valmarSlate)
	Client.step(terrain :: any, Tefra.Origin + Vector3.new(100, 200, -50), planets)
	check(Client.zone() == "Tefra" and TerrainPalette.same(terrain.colors.Salt, Tefra.TerrainColors.Salt) and TerrainPalette.same(terrain.colors.Slate, Tefra.TerrainColors.Slate), "En Tefra, tu pantalla pinta el terreno con la ceniza de Tefra")
	Client.step(terrain :: any, Vector3.new(0, -10, 900), planets)
	check(Client.zone() == "Valmar" and TerrainPalette.same(terrain.colors.Salt, sea.Salt) and TerrainPalette.same(terrain.colors.Slate, valmarSlate), "Al volver a Valmar: el fondo dorado y la pizarra de Valmar, como estaban")
	local main = fs.readFile("src/client/Main.client.luau")
	check(string.find(main, "TerrainPaletteClient).init", 1, true) ~= nil, "Main.client arranca TerrainPaletteClient")
end

L.finish("Mar de Valmar")
