-- Prueba de los sitios de ocio de las zonas verdes (docs/zonas-verdes/plan.md) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-ocio.luau
--
--   1. Construye los 5 sitios (World/Kit/ZonasVerdes) con Instance de verdad de Lune: cada uno cabe en su
--      tope de piezas, no se sale de su rectángulo y ninguna pieza cae encima de una calle, acera,
--      manzana, edificio, agua o playa (máscara de huellas docs/zonas-verdes/huellas-ocio.json, hecha con
--      scripts/map/zonas-verdes/6_huellas_ocio.py sobre la ciudad construida).
--   2. Lógica sin Roblox: horario del mercadillo y de la fiesta del sábado, premios de la feria, precios
--      y ventas de los puestos (OcioFeria); trazado, cronómetro por puertas, vueltas, mejor vuelta y
--      clasificación del karting (KartTrack); puntos, combos y caídas del skatepark (SkateTricks).
--   3. Servicios con dobles: cada cartel nuevo empieza su actividad (alquilar puesto y vender, minijuegos de
--      la feria solo el día de fiesta, escenario, karts con su cronómetro, vóley libre, tenis/pádel,
--      carrera, reto de trucos) y lo que dan (diversión con la API que haya, dinero, tickets).

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local L = require("./lib/ModuleLoader")

local check = L.check
local Vector3, CFrame = roblox.Vector3, roblox.CFrame

---------------------------------------------------------------------
-- CollectionService de verdad sobre el workspace de la prueba
---------------------------------------------------------------------
local tagAdded: { [string]: { (any) -> () } } = {}
L.services.CollectionService = {
	GetTagged = function(_, tag)
		local out = {}
		for _, d in L.workspace:GetDescendants() do
			if d:HasTag(tag) then
				table.insert(out, d)
			end
		end
		return out
	end,
	AddTag = function(_, inst, tag)
		if type(inst) == "table" then
			inst.__tags = inst.__tags or {}
			inst.__tags[tag] = true
			return
		end
		inst:AddTag(tag)
	end,
	HasTag = function(_, inst, tag)
		return inst:HasTag(tag)
	end,
	GetInstanceAddedSignal = function(_, tag)
		return {
			Connect = function(_, fn)
				tagAdded[tag] = tagAdded[tag] or {}
				table.insert(tagAdded[tag], fn)
				return { Disconnect = function() end }
			end,
		}
	end,
}

local Sitios = L.load("src/shared/OcioSitios")
local Feria = L.load("src/shared/OcioFeria")
local KartTrack = L.load("src/shared/KartTrack")
local SkateTricks = L.load("src/shared/SkateTricks")

---------------------------------------------------------------------
print("\n▶ 1. Los sitios: piezas, rectángulo y máscara de huellas")
---------------------------------------------------------------------
local Ocio = L.load("src/server/World/Kit/ZonasVerdes/Ocio")
local town = roblox.Instance.new("Folder")
town.Name = "Town"
town.Parent = L.workspace
local folder = Ocio.build(town)
local masks = serde.decode("json", fs.readFile("docs/zonas-verdes/huellas-ocio.json"))
local S = masks.S
local total = 0
local siteModels: { [string]: any } = {}
for _, site in Sitios.List do
	local model
	for _, m in folder:GetChildren() do
		if m:GetAttribute("OcioSite") == site.Id then
			model = m
		end
	end
	siteModels[site.Id] = model
	check(model ~= nil, ("%s: se construye"):format(site.Id))
	if not model then
		for _, w in L.warnings do
			print("     " .. w)
		end
	end
	if not model then
		continue
	end
	local parts, outside, hits, hitNames = 0, 0, 0, {}
	local mask = masks.Sites[site.Id]
	local function occupied(x: number, z: number): boolean
		local col = math.floor((x - mask.X0) / S) + 1
		local row = math.floor((z - mask.Z0) / S) + 1
		local r = mask.Rows[row]
		if not r or col < 1 or col > #r then
			return true -- (fuera del recorte: no debería pasar)
		end
		return string.sub(r, col, col) == "1"
	end
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			parts += 1
			-- La huella de la pieza en el suelo: puntos cada 2 studs por su caja
			local size = p.Size
			local nx, nz = math.max(1, math.ceil(size.X / 2)), math.max(1, math.ceil(size.Z / 2))
			local bad = false
			for i = 0, nx do
				for k = 0, nz do
					local loc = Vector3.new(-size.X / 2 + size.X * i / nx, 0, -size.Z / 2 + size.Z * k / nz)
					local w = p.CFrame * loc
					if not Sitios.inside(site.Id, w, 0.5) then
						outside += 1
						bad = true
						break
					end
					if occupied(w.X, w.Z) then
						hits += 1
						bad = true
						break
					end
				end
				if bad then
					break
				end
			end
			if bad and #hitNames < 6 then
				table.insert(hitNames, p.Name)
			end
		end
	end
	total += parts
	print(("     %s (zona %d): %d piezas (tope %d)"):format(site.Id, site.Zone, parts, site.Budget))
	check(parts <= site.Budget, ("%s: %d piezas, dentro del tope de %d"):format(site.Id, parts, site.Budget))
	check(outside == 0, ("%s: ninguna pieza se sale de su sitio%s"):format(site.Id, if outside > 0 then " (" .. table.concat(hitNames, ", ") .. ")" else ""))
	check(hits == 0, ("%s: nada encima de calles, edificios, agua o playa%s"):format(site.Id, if hits > 0 then " (" .. table.concat(hitNames, ", ") .. ")" else ""))
end
print(("     total: %d piezas"):format(total))
check(total <= 1570, "Los 5 sitios juntos, dentro de lo que suman sus topes (1570)")
-- Lo que necesita el juego de cada sitio
local function tagged(tag: string, root: any?): { any }
	local out = {}
	for _, d in (root or folder):GetDescendants() do
		if d:HasTag(tag) then
			table.insert(out, d)
		end
	end
	return out
end
check(#tagged("OcioStall") == 12, "Feria: 12 puestos de mercadillo (OcioStall)")
check(#tagged("OcioFairGame") == 3, "Feria: 3 casetas de la feria (aros, tiro, patitos)")
check(#tagged("OcioStage") == 1, "Feria: escenario")
check(#tagged("Pickup_FoodTruck") == 4 and #tagged("Dropoff_FoodTruck") == 6, "Feria: oficio de food truck (4 ventanillas, 6 mesas)")
local foodIds = {}
for _, stand in tagged("FoodStand") do
	local id = stand:GetAttribute("FoodId")
	foodIds[id] = true
	local Config = L.load("src/shared/Config")
	check(Config.Foods[id] ~= nil and Config.Foods[id].Hunger ~= nil, ("Comida «%s» en Config.Foods (FoodService)"):format(tostring(id)))
end
check(#tagged("StreetLamp", siteModels.Feria) >= 30, "Feria: luces que se encienden de noche (StreetLamp)")
check(#tagged("OcioVolleyCourt") == 2, "Playa: 2 pistas de vóley")
check(#tagged("FoodStand", siteModels.Playa) == 6, "Playa: chiringuitos con 6 mostradores de bebida y comida")
local pitch = siteModels.Campus and siteModels.Campus:FindFirstChild("Pitch", true)
check(pitch ~= nil and pitch.Material == roblox.Enum.Material.Grass, "Campus: campo de fútbol 7 («Pitch» de césped)")
local Pitch = L.load("src/shared/Sports/Pitch")
local fields = Pitch.scanMap(siteModels.Campus:GetDescendants())
check(#fields == 1 and fields[1].HasGoals and #fields[1].Toys == 1, "Campus: FootballService encuentra el campo con porterías y balón")
check(#tagged("OcioRacketCourt") == 2, "Campus: 2 pistas de tenis/pádel («Court»)")
check(#tagged("PEArea", siteModels.Campus) == 1, "Campus: recta de atletismo (PEArea)")
check(#tagged("OcioKartDesk") == 1 and #tagged("OcioKartBoard") == 1 and #tagged("OcioKartLight") == 3, "Karting: taquilla, clasificación y semáforo")
check(#tagged("Pickup_Boxes") == 2 and #tagged("Dropoff_Boxes") == 3, "Karting: oficio de boxes (estantes y karts)")
check(#tagged("SkateRamp") >= 8 and #tagged("SkateRail") >= 3, "Skate: rampas, bowl, pirámide y barandillas")
check(#tagged("RentalStation", siteModels.Skate) == 1, "Skate: monopatines gratis")
check(#tagged("OcioSkateChallenge") == 1, "Skate: panel del reto de trucos")
local steepest = 0
for _, r in tagged("SkateRamp") do
	if r:IsA("WedgePart") then
		steepest = math.max(steepest, math.deg(math.atan(r.Size.Y / r.Size.Z)))
	end
end
check(steepest <= 27, ("Skate: todas las rampas se pueden subir (la más empinada, %.0f°)"):format(steepest))
for _, r in tagged("SkateRail") do
	local top = r.CFrame.Position.Y + r.Size.Y / 2 - (Sitios.GROUND + 1 + (-0.5))
	check(top < 1.6 and top > 0.8, ("Skate: %s a %.2f del suelo (se sube con el monopatín sin chocar)"):format(r.Name, top))
end

---------------------------------------------------------------------
print("\n▶ 2a. Feria: horario fijo, premios y puestos")
---------------------------------------------------------------------
check(Feria.fairOpen(6, 17) and Feria.fairOpen(6, 23.9) and Feria.fairOpen(7, 1.5), "La fiesta es el sábado de 17:00 a 2:00 del domingo")
check(not Feria.fairOpen(6, 16.9) and not Feria.fairOpen(7, 2) and not Feria.fairOpen(5, 20) and not Feria.fairOpen(1, 1), "Fuera de esa franja no hay fiesta")
check(Feria.marketOpen(3, 9) and not Feria.marketOpen(3, 15) and Feria.marketOpen(6, 20) and not Feria.marketOpen(6, 7), "Mercadillo: 8-14 entre semana y 8-22 el sábado")
check(Feria.hoursToFair(6, 10) == 7 and Feria.hoursToFair(5, 17) == 24 and Feria.hoursToFair(7, 3) == 6 * 24 + 14 and Feria.hoursToFair(6, 18) == 0, "Cuánto falta para la fiesta")
check(string.find(Feria.status(6, 18).Text, "Fiesta del sábado", 1, true) ~= nil and Feria.status(6, 18).Fair, "El panel dice que hay fiesta")
local p0 = Feria.prize("Tiro", 6, true)
local p1 = Feria.prize("Tiro", 1, false)
check(p0.Tickets == 34 and p0.Money == 12 and p0.Fun == 14, "Tiro perfecto: 34 tickets, 12 € y +14 de diversión")
check(p1.Tickets == 4 and p1.Money == 0 and p1.Fun == 6, "Tiro malo: 4 tickets y algo de diversión")
check(Feria.prize("Aros", 99, true).Tickets == 30 and Feria.prize("Nada", 3, true).Tickets == 0, "Los aciertos no pasan de las rondas; un juego que no existe no da nada")
check(Feria.priceFor("Agro_Fresa", 10, nil) == 14 and Feria.priceFor("Pez", nil, 20) == 24 and Feria.priceFor("Pan", nil, nil) == 0, "Precio de puesto: granja ×1,35, pescado ×1,2; lo demás no se vende")
check(Feria.pickSale({ A = 0, B = 3 }, 0.5) == "B" and Feria.pickSale({}, 0.5) == nil and Feria.pickSale({ A = 1, B = 1 }, 0.1) == "A" and Feria.pickSale({ A = 1, B = 1 }, 0.9) == "B", "Un cliente elige de lo que hay en el puesto")

---------------------------------------------------------------------
print("\n▶ 2b. Karting: trazado, puertas, vueltas y clasificación")
---------------------------------------------------------------------
local pts = KartTrack.centerline(4)
local lap = KartTrack.length(pts)
check(lap > 700 and lap < 1300, ("La vuelta mide %d studs"):format(math.floor(lap)))
local minGap = math.huge
for i = 1, #pts do
	for j = i + 7, #pts do
		if (i - j) % #pts > 6 and (j - i) % #pts > 6 then
			minGap = math.min(minGap, KartTrack.dist(pts[i], pts[j]))
		end
	end
end
check(minGap > KartTrack.WIDTH + 30, ("El trazado no se cruza ni se toca (%.0f studs entre tramos)"):format(minGap))
local karting = Sitios.get("Karting")
local fits = true
for _, p in pts do
	if math.abs(p[1]) + KartTrack.WIDTH / 2 > karting.Size[1] / 2 - 8 or math.abs(p[2]) + KartTrack.WIDTH / 2 > karting.Size[2] / 2 - 8 then
		fits = false
	end
end
check(fits, "El circuito cabe en su sitio con margen")
local gates = KartTrack.gates(pts)
check(#gates == 8 and gates[1][2] > 80, "8 puertas; la 1 es la línea de meta (recta sur)")
-- Simula una carrera: 3 vueltas siguiendo la línea central a 40 studs/s, empezando 10 studs detrás de la meta
local function drive(timer, speed: number, skip: number?): { any }
	local events = {}
	local t = 0
	local startIdx = gates[1][3]
	for lapN = 1, 3 do
		for step = 0, #pts - 1 do
			local i = (startIdx - 1 + step) % #pts + 1
			local a, b = pts[i], pts[i % #pts + 1]
			local d = KartTrack.dist(a, b)
			local n = math.max(1, math.floor(d / 4))
			for k = 0, n - 1 do
				local x = a[1] + (b[1] - a[1]) * k / n
				local z = a[2] + (b[2] - a[2]) * k / n
				t += d / n / speed
				if skip and lapN == 2 and KartTrack.dist({ x, z }, gates[skip]) < 25 then
					continue -- (atajo: no pasa por esa puerta)
				end
				for _, e in KartTrack.feed(timer, t, x, z) do
					table.insert(events, e)
				end
			end
		end
	end
	-- y pasa la meta
	for _, e in KartTrack.feed(timer, t + 0.1, gates[1][1], gates[1][2]) do
		table.insert(events, e)
	end
	return events
end
local timer = KartTrack.newTimer(gates, 3, 0)
local events = drive(timer, 40)
local laps, finish = {}, nil
for _, e in events do
	if e.Kind == "Lap" then
		table.insert(laps, e)
	elseif e.Kind == "Finish" then
		finish = e
	end
end
check(#laps == 3 and finish ~= nil and timer.Done, "3 vueltas y bandera a cuadros")
check(math.abs(laps[2].Time - lap / 40) < 1, ("Una vuelta a 40 studs/s dura lo que mide (%.1f s)"):format(laps[2].Time))
check(finish ~= nil and math.abs(finish.Best - math.min(laps[1].Time, laps[2].Time, laps[3].Time)) < 1e-6, "La mejor vuelta es la más rápida")
check(KartTrack.progress(timer) == 3000, "Progreso de carrera al acabar")
local cheat = KartTrack.newTimer(gates, 3, 0)
local cheatEvents = drive(cheat, 40, 4)
local cheatLaps = 0
for _, e in cheatEvents do
	if e.Kind == "Lap" then
		cheatLaps += 1
	end
end
check(cheatLaps < 3 and not cheat.Done, "Saltarse una puerta (atajo) no cierra la vuelta")
local board = {}
KartTrack.insertBoard(board, "Ana", 1, 21.5)
KartTrack.insertBoard(board, "Luis", 2, 19.2)
local pos = KartTrack.insertBoard(board, "Ana", 1, 18.9)
check(pos == 1 and #board == 2 and board[1].Name == "Ana" and board[2].Name == "Luis", "Clasificación: una fila por persona, la mejor vuelta arriba")
check(KartTrack.insertBoard(board, "Luis", 2, 25) == nil and board[2].Time == 19.2, "Una vuelta peor no cambia tu fila")
check(KartTrack.formatTime(71.234) == "1:11.23" and KartTrack.formatTime(nil) == "--:--.--", "Tiempos con minutos y centésimas")
local slowest, fastest = math.huge, 0
for i = 1, #pts do
	local v = KartTrack.botSpeed(pts, i, 0.5)
	slowest, fastest = math.min(slowest, v), math.max(fastest, v)
end
check(slowest < fastest * 0.85 and fastest <= KartTrack.KART_SPEED, "Las máquinas frenan en las curvas y no pasan de la velocidad del kart")

---------------------------------------------------------------------
print("\n▶ 2c. Skatepark: trucos, combos y caídas")
---------------------------------------------------------------------
local air = SkateTricks.airTricks(1.0, 1, 370)
check(#air == 3 and air[1].Id == "GranSalto" and air[2].Id == "Kickflip" and air[3].Id == "Giro360", "Un salto de 1 s con kickflip y giro de 370°: gran salto + kickflip + 360")
check(#SkateTricks.airTricks(0.2, 1, 400) == 0, "Un saltito de nada no cuenta")
check(SkateTricks.airTricks(0.5, 2, 160)[2].Id == "DobleKickflip" and SkateTricks.airTricks(0.5, 2, 160)[3].Id == "Giro180", "Doble kickflip y giro 180")
local sum, mult, tot = SkateTricks.score({ { Id = "Salto", S = 0.5 }, { Id = "Kickflip" }, { Id = "Grind", S = 2 } })
check(sum == 90 + 150 + 170 and mult == 3 and tot == sum * 3, ("Combo de 3 trucos: %d × %d = %d"):format(sum, mult, tot))
local _, m6 = SkateTricks.score(table.create(10, { Id = "Kickflip" }))
check(m6 == SkateTricks.MAX_MULT, "El multiplicador tiene tope (×6)")
check(SkateTricks.points({ Id = "Salto", S = 99 }) == SkateTricks.points({ Id = "Salto", S = SkateTricks.MAX_AIR }) and SkateTricks.points({ Id = "Nada" }) == 0, "Los segundos tienen tope y los trucos inventados no dan puntos")
local clean = SkateTricks.sanitize({ { Id = "Salto", S = 2 }, { Id = "Grind", S = 5 }, { Id = "Hack" }, "x", { Id = "Kickflip" } }, 3)
local airSum = 0
for _, t in clean do
	airSum += t.S or 0
end
check(#clean == 3 and airSum <= 3.5, "El servidor limpia el combo: fuera lo inventado y no más tiempo del que ha pasado")
local combo = SkateTricks.newCombo()
SkateTricks.add(combo, air, 10)
check(SkateTricks.expire(combo, 11) == nil, "El combo sigue abierto si vuelves a hacer algo antes de 2 s")
SkateTricks.add(combo, { { Id = "Grind", S = 1 } }, 11.5)
local done = SkateTricks.expire(combo, 13.6)
check(done ~= nil and #done == 4 and #combo.Tricks == 0, "Al pasar 2 s en el suelo se cobra el combo entero")
SkateTricks.add(combo, air, 20)
check(SkateTricks.badLanding(19.9, 20) and not SkateTricks.badLanding(19, 20) and not SkateTricks.badLanding(nil, 20), "Aterrizar a mitad de kickflip es caída")
check(SkateTricks.bail(combo) == 3 and #combo.Tricks == 0, "Al caer se pierde el combo")

---------------------------------------------------------------------
local tests = require("./lib/OcioServicesTest")
tests.run(L, folder)

print()
if L.failures > 0 then
	print(("❌ %d fallo(s)"):format(L.failures))
	process.exit(1)
end
print("✅ Todo correcto")
process.exit(0) -- (los servicios dejan bucles en marcha)
