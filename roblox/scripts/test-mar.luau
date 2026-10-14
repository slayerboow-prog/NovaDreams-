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

-- (lo de las fases siguientes: más abajo)
local extra = "scripts/test-mar-extra.luau"
if fs.isFile(extra) then
	local luau = require("@lune/luau")
	luau.load(fs.readFile(extra), { debugName = extra, environment = setmetatable({ L = L, Ocean = Ocean, check = check }, { __index = getfenv(1) }) })()
end

L.finish("Mar de Valmar")
