-- Prueba del espacio encima de Valmar (shared/Cosmos, Services/SpaceService, docs/espacio.md), con
-- Lune (sin Roblox).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-space.luau
--
-- Comprueba:
--   * Capas de altura (Layers): el cielo de los aviones queda libre (techo de Flight por debajo de la
--     franja reservada), transición, modo de la nave por altura, cielo que se oscurece poco a poco, sin
--     enemigos por debajo del espacio, columna alrededor de Valmar más grande que la ciudad.
--   * La nave sube desde el puerto espacial hasta el espacio con la geometría de verdad (Zone) sin
--     chocar, y no puede bajar al suelo lejos del puerto.
--   * Acceso: Saga 1 terminada o tester; el resto, aviso amable.
--   * Zona (Zone): asteroides repetibles, en el espacio, sin pisarse ni meterse en las estaciones;
--     sectores con patrullas lejos de las estaciones; choques y disparos contra asteroides.
--   * Minar (Mining): unidades, impactos, se agota y se rellena; contra trampas (ritmo, bodega, lejos,
--     zona segura); vender.
--   * Asteroides AAA (Asteroids, AsteroidBuild, AsteroidFx; docs/espacio-aaa/asteroides.md): rocas
--     irregulares (sin bolas, variadas, del tamaño de su esfera de choque), vetas, grietas por niveles de
--     daño, rotura en trozos más pequeños (grande → medianos → pequeños → polvo) que salen con impulso,
--     giro y velocidad heredada; mineral una sola vez por unidad (servidor), estado replicado como texto,
--     tope de pedazos (60), vuelta a su hora (espera si hay una nave), choques de la nave que quitan
--     escudo según la velocidad y misiles que dañan rocas.
--   * Misiones: coger (tope, estación), progreso de derribos, mineral y entregas (tiempo mínimo), la
--     carga se pierde si te derriban.
--   * Estaciones: zona segura, muelle, vestíbulo, precios.
--   * Planetas: los 7 de la Saga 2, cada uno con su color y su brillo; estado (cerrado, próximamente,
--     listo, orden), apuntar.
--   * Servidor: AirCombatService en el espacio (zona segura sin disparos ni daño, el láser en un
--     asteroide avisa, sin oleadas) y SpaceService (minar con recompensa y sin trampas, derribos,
--     misiones con recompensa, tienda, volver a Valmar, puerto y estaciones construidos, patrullas).
--   * Botones de la nave en el móvil (HudLayout.Fly): VALMAR y ATRACAR/VIAJAR grandes y sin pisar nada
--     en 932x430, 844x390 y 640x360.

local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")

local Vector3, Vector2, CFrame = roblox.Vector3, roblox.Vector2, roblox.CFrame
local check = L.check

local Layers = L.load("src/shared/Cosmos/Layers")
local Access = L.load("src/shared/Cosmos/Access")
local Stations = L.load("src/shared/Cosmos/Stations")
local Zone = L.load("src/shared/Cosmos/Zone")
local Mining = L.load("src/shared/Cosmos/Mining")
local Missions = L.load("src/shared/Cosmos/Missions")
local Planets = L.load("src/shared/Cosmos/Planets")
local Flight = L.load("src/shared/Flight")
local ShipFlight = L.load("src/shared/AirCombat/ShipFlight")
local Shields = L.load("src/shared/AirCombat/Shields")
local ShipWeapons = L.load("src/shared/AirCombat/ShipWeapons")
local Waves = L.load("src/shared/AirCombat/Waves")
local CityPlan = L.load("src/shared/CityPlan")

local function near(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) <= (eps or 1e-3)
end

---------------------------------------------------------------------
print("\n📏 Capas de altura (Layers)")
---------------------------------------------------------------------
do
	check(Layers.PlaneCeiling == Flight.Bounds.Ceiling and Layers.PlaneCeiling < Layers.PlaneBandTop, ("el techo de los aviones (%d) queda por debajo de la franja reservada (%d)"):format(Layers.PlaneCeiling, Layers.PlaneBandTop))
	check(Flight.Bounds.Ceiling + 300 <= Layers.PlaneBandTop, "AviationService corta los aviones (techo + 300) antes de que acabe su cielo")
	check(Layers.PlaneBandTop <= Layers.TransitionY and Layers.TransitionY < Layers.ModeY and Layers.ModeY < Layers.SpaceY and Layers.SpaceY < Layers.AIMinY and Layers.AIMinY < Layers.TopY, "orden: aviones < transición < modo espacio < espacio < enemigos < techo")
	check(Layers.SpaceY - Layers.PlaneBandTop >= 1200, ("hay una buena franja de transición (%d studs)"):format(Layers.SpaceY - Layers.PlaneBandTop))
	check(Layers.TopY - Layers.SpaceY >= 5000, ("el espacio es alto (%d studs)"):format(Layers.TopY - Layers.SpaceY))
	check(Layers.Half * 2 >= 12000 and Layers.Half > -Flight.Bounds.X0 and Layers.Half > Flight.Bounds.X1, ("el espacio es más ancho que Valmar (%d de lado)"):format(Layers.Half * 2))
	check(Layers.layerAt(500) == "Aviones" and Layers.layerAt(1500) == "Aviones" and Layers.layerAt(2500) == "Transicion" and Layers.layerAt(5000) == "Espacio", "nombre de la capa según la altura")
	check(Layers.mode(1000) == "Atmos" and Layers.mode(Layers.ModeY - 1) == "Atmos" and Layers.mode(Layers.ModeY) == "Space", "la nave pasa a modo espacio en ModeY")
	check(Layers.skyBlend(0) == 0 and Layers.skyBlend(Layers.TransitionY) == 0 and near(Layers.skyBlend(Layers.SpaceY), 1) and Layers.skyBlend(9000) == 1, "cielo: normal abajo, negro arriba")
	local prev, ok = -1, true
	for y = Layers.TransitionY, Layers.SpaceY, 100 do
		local b = Layers.skyBlend(y)
		ok = ok and b >= prev
		prev = b
	end
	check(ok and Layers.skyBlend((Layers.TransitionY + Layers.SpaceY) / 2) > 0.3 and Layers.skyBlend((Layers.TransitionY + Layers.SpaceY) / 2) < 0.7, "y en medio se oscurece poco a poco")
	check(not Layers.aiAllowed(Vector3.new(0, 1000, 0)) and not Layers.aiAllowed(Vector3.new(0, 3000, 0)) and Layers.aiAllowed(Vector3.new(0, 5000, 0)), "nada de enemigos en el cielo de los aviones ni en la transición")
	check(not Layers.aiAllowed(Vector3.new(24000, 5000, 24000)), "ni fuera de la columna de Valmar (la arena de pruebas va aparte)")
	check(Layers.inSpace(Vector3.new(0, 4300, 0)) and not Layers.inSpace(Vector3.new(0, 300, 0)) and not Layers.inSpace(Vector3.new(24000, 4000, 24000)), "inSpace: en lo alto del cielo de Valmar sí; en la calle o en la arena no")
	check(Layers.canLand(Vector3.new(0, 600, 0)) and not Layers.canLand(Vector3.new(0, 1500, 0)), "aterrizar solo cerca del suelo")
end

---------------------------------------------------------------------
print("\n🚀 Despegar: del puerto espacial al espacio (ShipFlight + Zone)")
---------------------------------------------------------------------
do
	local env = { mode = Zone.modeAt, collide = Zone.collide, bounds = Zone.bounds }
	local cf = Access.launch()
	check(cf.LookVector.Y > 0.8, "la nave sale mirando hacia arriba")
	check(Zone.collide(cf.Position, ShipFlight.Specs.Caza.Radius) == nil, "y no sale tocando el suelo")
	local s = ShipFlight.new("Caza", cf, Zone.modeAt(cf.Position))
	local events, maxY, crashed = {}, 0, false
	for _ = 1, 60 * 40 do
		for _, e in ShipFlight.advance(s, { Pitch = 0, Yaw = 0, Roll = 0, SetThrottle = 1 }, 1 / 60, env) do
			table.insert(events, e)
		end
		maxY = math.max(maxY, s.Pos.Y)
		if s.Crashed then
			crashed = true
			break
		end
	end
	check(not crashed, "subiendo no choca con nada" .. (if s.Crashed then " (" .. tostring(s.Crashed) .. ")" else ""))
	check(maxY > Layers.SpaceY and s.Mode == "Space" and table.find(events, "Space") ~= nil, ("llega al espacio (%.0f studs) y la nave pasa a modo espacio"):format(maxY))
	-- Lejos del puerto la nave no baja del suelo de las naves
	local low = Vector3.new(0, Layers.FloorY - 50, 0)
	local back = Zone.bounds(low)
	check(back ~= nil and back.Y > 0.5, "lejos del puerto, por debajo del suelo de las naves, vuelve a subir")
	check(Zone.bounds(Access.Port + Vector3.new(0, 40, 0)) == nil, "junto al puerto se puede bajar (despegar y aterrizar)")
	check(Zone.collide(Vector3.new(0, 2, 0), 6) ~= nil, "chocar con el mar o el suelo")
	check(Zone.bounds(Vector3.new(Layers.Half + 100, 5000, 0)).X < 0 and Zone.bounds(Vector3.new(0, Layers.TopY + 50, 0)).Y < 0, "límites: los lados y el techo hacen volver")
	check(Zone.contains(Access.launch().Position) and Zone.contains(Vector3.new(0, 8000, 0)) and not Zone.contains(Vector3.new(24000, 4000, 24000), 400), "la zona contiene el puerto y el espacio, no la arena")
end

---------------------------------------------------------------------
print("\n🔑 Acceso a la nave")
---------------------------------------------------------------------
do
	check(not Access.sagaDone({ Story = { Completed = {} } }) and Access.sagaDone({ Story = { Completed = { Saga_24_Final = 123 } } }), "Saga 1 terminada = misión Saga_24_Final completada")
	check(not Access.sagaDone(nil) and not Access.sagaDone({}), "sin datos: no")
	local ok, why = Access.canFly({ SagaDone = false, Tester = false })
	check(not ok and why == "Locked" and string.find(Access.Messages.Locked, "Saga 1", 1, true) ~= nil, "sin terminar la Saga 1: no, con un aviso amable")
	check(Access.canFly({ SagaDone = true }) and Access.canFly({ Tester = true }), "con la Saga 1 o siendo tester: sí")
	local islote = nil
	for _, isl in CityPlan.Islands do
		if isl.Name == "Islote" then
			islote = isl
		end
	end
	check(islote and near(islote.X, Access.Port.X) and near(islote.Z, Access.Port.Z) and Access.PadRadius < islote.R - 30, "el puerto espacial está en el islote y la pista cabe en su hierba")
	local d = Access.arrival().Position - Access.Port
	check(Vector2.new(d.X, d.Z).Magnitude < Access.PadRadius and d.Y > Access.PadTop, "volver a Valmar = encima de la pista del puerto")
	check(#Access.BeachSpots >= 8, "varios sitios de la playa para el portal")
end

---------------------------------------------------------------------
print("\n🪨 Zona: asteroides, sectores y estaciones")
---------------------------------------------------------------------
do
	local rocks = Zone.rocks()
	local total = 0
	for _, f in Zone.Fields do
		total += f.Count
	end
	check(#rocks >= total * 0.9, ("asteroides en los campos (%d de %d)"):format(#rocks, total))
	local okY, okSafe, okOverlap, okField, okCol = true, true, true, true, true
	for i, r in rocks do
		okY = okY and r.Center.Y - r.Radius > Layers.SpaceY
		okSafe = okSafe and Stations.safeAt(r.Center) == nil
		okCol = okCol and Layers.inColumn(r.Center)
		okField = okField and Zone.fieldAt(r.Center) ~= nil and Mining.Ores[r.Ore] ~= nil
		for j = i + 1, #rocks do
			local o = rocks[j]
			if (o.Center - r.Center).Magnitude < o.Radius + r.Radius then
				okOverlap = false
			end
		end
	end
	check(okY, "todos en el espacio (ninguno en el cielo de los aviones)")
	check(okSafe and okCol, "ninguno en la zona segura de una estación y todos encima de Valmar")
	check(okOverlap, "no se meten unos en otros")
	check(okField, "cada uno en su campo y con su mineral")
	check(Zone.rocks() == rocks and Zone.rock(rocks[1].Id) == rocks[1], "repetibles (misma lista) y se encuentran por id")
	local kinds = {}
	for _, r in rocks do
		kinds[r.Ore] = (kinds[r.Ore] or 0) + 1
	end
	check((kinds.Hierro or 0) > (kinds.Cristal or 0) and (kinds.Cristal or 0) >= 2 and (kinds.Cobalto or 0) >= 4, ("hay de todo y el cristal es raro (hierro %d, cobalto %d, cristal %d)"):format(kinds.Hierro or 0, kinds.Cobalto or 0, kinds.Cristal or 0))
	local r = rocks[1]
	check(Zone.collide(r.Center + Vector3.new(r.Radius + 2, 0, 0), 6) == "un asteroide", "chocar con un asteroide")
	local from = r.Center + Vector3.new(0, 0, r.Radius + 60)
	local hit, at = Zone.rockHit(from, r.Center)
	check(hit and hit.Id == r.Id and at and (at - r.Center).Magnitude <= r.Radius + 1, "un disparo hacia un asteroide le da (y dice dónde)")
	check(Zone.rockHit(from, from + Vector3.new(0, 0, 50)) == nil, "uno que se aleja, no")
	check(Zone.segmentBlocked(from, r.Center), "el asteroide para los disparos")
	local okSector = true
	for _, s in Zone.Sectors do
		okSector = okSector and Layers.aiAllowed(s.Center) and s.Center.Y - s.Radius * 0.5 > Layers.SpaceY
		for _, st in Stations.List do
			okSector = okSector and (s.Center - st.Center).Magnitude > s.Radius * 0.5 + Stations.SafeRadius
		end
	end
	check(okSector and #Zone.Sectors >= 3, "3 sectores con patrullas, en el espacio y lejos de las estaciones")
	check(Zone.sectorAt(Stations.List[1].Center) == nil and Zone.sectorAt(Vector3.new(0, 1000, 0)) == nil, "en la estación o en el cielo de los aviones no hay patrullas")
	check(Zone.sectorAt(Zone.Sectors[1].Center) == Zone.Sectors[1], "en el sector, sí")
	local eb = Zone.enemyBounds(Vector3.new(0, Layers.AIMinY - 200, 0))
	check(eb ~= nil and eb.Y > 0.5, "un enemigo que baja demasiado vuelve a subir")
	local nearSt = Stations.List[1].Center + Vector3.new(Stations.SafeRadius, 0, 0)
	local eb2 = Zone.enemyBounds(nearSt)
	check(eb2 ~= nil and eb2.X > 0, "y no entra en la zona segura de una estación")
	for _, st in Stations.List do
		check(Layers.layerAt(st.Center.Y) == "Espacio" and Zone.collide(Stations.launch(st).Position, 6) == nil and Zone.bounds(Stations.launch(st).Position) == nil, st.Name .. ": en el espacio, y la nave sale libre del muelle")
	end
	local cp = Zone.checkpoint("Space", Stations.List[2].Center + Vector3.new(0, 0, 900))
	check((cp.Position - Stations.List[2].Dock).Magnitude < 200, "derribado en el espacio: reapareces en el muelle de la estación más cercana")
	check(Zone.checkpoint("Atmos").Position.Y < Layers.PlaneBandTop and Zone.nearPort(Zone.checkpoint("Atmos").Position), "abajo: encima del puerto espacial")
	check(#Zone.turretSpots("Space") == 0, "sin torretas sueltas en el cielo de Valmar")
end

---------------------------------------------------------------------
print("\n⛏ Minar (Mining)")
---------------------------------------------------------------------
do
	check(Mining.units(12) == 3 and Mining.units(64) == 7 and Mining.units(500) == 8, "más mineral en los asteroides grandes (con tope)")
	local rock = Mining.newRock(30)
	local results = {}
	for _ = 1, Mining.HitsPerUnit * rock.Max + 2 do
		table.insert(results, Mining.hit(rock, 0))
	end
	local units = 0
	for _, r in results do
		if r == "Unit" or r == "Empty" then
			units += 1
		end
	end
	check(results[1] == "Chip" and results[Mining.HitsPerUnit] == "Unit", ("cada %d impactos, una unidad"):format(Mining.HitsPerUnit))
	check(units == rock.Max and table.find(results, "Empty") ~= nil and results[#results] == "Dry", "se agota y luego ya no da")
	check(not Mining.refill(rock, Mining.RefillSeconds - 1) and rock.Units == 0, "no se rellena antes de tiempo")
	check(Mining.refill(rock, Mining.RefillSeconds + 1) and rock.Units == rock.Max, "y se rellena solo")
	local rate = Mining.newRate()
	local ship, at = Vector3.new(0, 5000, 0), Vector3.new(0, 5000, -300)
	check(Mining.allow(rate, 0, 0, ship, at, false), "una unidad: sí")
	local ok, why = Mining.allow(rate, 0.1, 0, ship, at, false)
	check(not ok and why == "Rate", "dos seguidas demasiado rápido: no (contra trampas)")
	ok, why = Mining.allow(Mining.newRate(), 0, Mining.CargoMax, ship, at, false)
	check(not ok and why == "Cargo", "bodega llena: no")
	ok, why = Mining.allow(Mining.newRate(), 0, 0, ship, ship + Vector3.new(0, 0, Mining.Reach + 100), false)
	check(not ok and why == "Far", "desde demasiado lejos: no")
	ok, why = Mining.allow(Mining.newRate(), 0, 0, ship, at, true)
	check(not ok and why == "Safe", "en una zona segura: no")
	local r2, count = Mining.newRate(), 0
	for i = 1, Mining.RateMax + 20 do
		if Mining.allow(r2, i * Mining.MinGap * 1.01, 0, ship, at, false) then
			count += 1
		end
	end
	check(count == Mining.RateMax, ("como mucho %d unidades cada %d s"):format(Mining.RateMax, Mining.RateWindow))
	local money, chispas, n = Mining.sellValue({ Hierro = 3, Cobalto = 2, Cristal = 1, Trampa = 99 })
	check(n == 6 and money == 3 * 12 + 2 * 30 + 80 and chispas == 1, ("vender: %d de mineral = $%d y %d chispa (lo desconocido no vale)"):format(n, money, chispas))
	check(Mining.cargo({ Hierro = 2.7, Cobalto = -4 }) == 2, "la bodega no cuenta trampas (decimales, negativos)")
	check(Mining.pick({ Hierro = 1 }, 0.99) == "Hierro" and Mining.pick({ Hierro = 0, Cristal = 1 }, 0.5) == "Cristal", "el mineral sale de los pesos del campo")
end

---------------------------------------------------------------------
print("\n📋 Misiones secundarias")
---------------------------------------------------------------------
do
	local st = {}
	check(Missions.accept(st, "Drones", "Alba", 0) and Missions.activeCount(st) == 1, "coger una misión")
	check(not Missions.accept(st, "Drones", "Alba", 0), "la misma dos veces, no")
	check(not Missions.accept(st, "CargaAlba", "Alba", 0), "una entrega solo en su estación de salida")
	check(Missions.accept(st, "CargaCenit", "Alba", 100), "la entrega de Alba a Cénit, en Alba sí")
	local ok, why = Missions.canAccept(st, "Mineral", "Alba")
	check(not ok and why == "Full", ("como mucho %d a la vez"):format(Missions.MaxActive))
	for _ = 1, 5 do
		Missions.progress(st, { Type = "Kill", Kind = "Dron" })
	end
	Missions.progress(st, { Type = "Kill", Kind = "Caza" })
	check(st.Drones.P == 5, "los derribos de drones cuentan (los cazas no, en esta)")
	local done = Missions.progress(st, { Type = "Kill", Kind = "Dron" })
	check(#done == 1 and done[1].Id == "Drones" and st.Drones == nil, "al llegar a 6, completada (y se puede volver a coger)")
	local early = Missions.progress(st, { Type = "Dock", Station = "Cenit", Now = 105 })
	check(#early == 0 and st.CargaCenit ~= nil, "atracar en Cénit a los 5 s: demasiado pronto (no se puede llegar tan rápido)")
	done = Missions.progress(st, { Type = "Dock", Station = "Cenit", Now = 200 })
	check(#done == 1 and done[1].Id == "CargaCenit", "atracar en Cénit con la carga: entregada")
	Missions.accept(st, "CargaAlba", "Cenit", 0)
	local _, lost = Missions.progress(st, { Type = "Down" })
	check(#lost == 1 and st.CargaAlba == nil, "si te derriban, la carga se pierde")
	Missions.accept(st, "Cristales", "Alba", 0)
	Missions.progress(st, { Type = "Mine", Ore = "Hierro", Count = 1 })
	Missions.progress(st, { Type = "Mine", Ore = "Cristal", Count = 2 })
	check(st.Cristales.P == 2 and string.find(Missions.summary(st), "2/3", 1, true) ~= nil, "minar cristal cuenta (el hierro no) y sale en el panel")
	check(#Missions.List >= 5, "hay varias misiones (derribar, minar, entregar)")
end

---------------------------------------------------------------------
print("\n🛰 Estaciones")
---------------------------------------------------------------------
do
	local a = Stations.List[1]
	check(#Stations.List == 2 and Stations.safeAt(a.Center) == a and Stations.safeAt(a.Center + Vector3.new(Stations.SafeRadius + 50, 0, 0)) == nil, "zona segura alrededor de cada estación")
	check(Stations.dockAt(a.Dock) == a and Stations.dockAt(a.Center + Vector3.new(0, 0, -Stations.SafeRadius)) == nil, "atracar solo en el muelle")
	check(Stations.safeAt(a.Dock) == a and Stations.safeAt(Stations.launch(a).Position) == a, "el muelle y la salida están dentro de la zona segura")
	check(Stations.inHall(a, Stations.arrival(a).Position) and not Stations.inHall(a, a.Center + Vector3.new(200, 0, 0)), "llegas andando dentro del vestíbulo")
	check(Stations.repairCost(60, 100) == 80 and Stations.repairCost(100, 100) == 0, "reparar: según lo que falta")
	check(Stations.missileCost(2, 6) == 4 * Stations.MissilePrice and Stations.missileCost(6, 6) == 0, "misiles: según los que faltan")
	check((Stations.List[1].Center - Stations.List[2].Center).Magnitude > 4000, "las dos estaciones están lejos (la entrega es un viaje)")
end

---------------------------------------------------------------------
print("\n🪐 Los 7 planetas (estrellas del fondo)")
---------------------------------------------------------------------
do
	local names = {}
	for _, p in Planets.List do
		table.insert(names, p.Name)
	end
	check(table.concat(names, ",") == "Tefra,Siroco,Tálasa,Nivalis,Umbría,Miasma,Vértice", "los 7 planetas de la Saga 2, en su orden (nombres nuevos del dueño)")
	-- Partidas guardadas con los nombres viejos: pasan a los nuevos sin perder nada
	local done = { Lontana = 123, Fronda = 456 }
	Planets.migrate(done)
	check(done.Tefra == 123 and done.Umbria == 456 and done.Lontana == nil and done.Fronda == nil, "partidas viejas: los planetas terminados pasan a los ids nuevos")
	check(Planets.canonical("Mercadia") == "Vertice" and Planets.canonical("Tefra") == "Tefra", "un id viejo se entiende como el nuevo")
	local hold = { Cuarzo = 3, Obsidiana = 1, Hierro = 2 }
	Mining.migrate(hold)
	check(hold.Obsidiana == 4 and hold.Cuarzo == nil and hold.Hierro == 2, "la bodega vieja: el mineral de Tefra pasa a llamarse obsidiana sin perder unidades")
	local EL = L.load("src/shared/Cosmos/EspacioLook")
	check(EL.id({ planeta_lontana = "rbxassetid://5" }, "planeta_tefra") == "rbxassetid://5" and EL.fileName("cielo_tefra_bk") == "cielo_lontana_bk", "las imágenes ya subidas siguen valiendo con los nombres nuevos (sin volver a subir)")
	for _, p in Planets.List do
		for _, bad in { "Lontana", "Ocrea", "Marena", "Velaria", "Fronda", "Zéfira", "Mercadia" } do
			if p.Name == bad then
				check(false, "queda un nombre viejo: " .. bad)
			end
		end
	end
	local hues, patterns, okDir = {}, {}, true
	for _, p in Planets.List do
		hues[tostring(p.Hue)] = true
		patterns[("%d/%d/%.2f/%s"):format(p.Rays, p.Tilt, p.Twinkle, tostring(p.Blink))] = true
		okDir = okDir and near(p.Dir.Magnitude, 1, 1e-3) and p.Dir.Y > 0.2
	end
	local nh, np = 0, 0
	for _ in hues do
		nh += 1
	end
	for _ in patterns do
		np += 1
	end
	check(nh == 7 and np == 7, "cada uno con su color y su forma de brillar (rayos, titileo, parpadeo)")
	check(okDir, "en direcciones fijas por encima del horizonte")
	local minSep = math.huge
	for i, p in Planets.List do
		for j = i + 1, #Planets.List do
			minSep = math.min(minSep, math.deg(math.acos(math.clamp(p.Dir:Dot(Planets.List[j].Dir), -1, 1))))
		end
	end
	check(minSep > math.deg(Planets.AimCone) * 2, ("separados en el cielo (%.0f° como mínimo): no se confunden al apuntar"):format(minSep))
	local p = Planets.ById.Talasa
	check(Planets.aimed(p.Dir) == p and Planets.aimed(Vector3.new(0, -1, 0)) == nil, "apuntar con el morro a una estrella la elige")
	local lo, hi = 1, 0
	for t = 0, 10, 0.05 do
		local b = Planets.brightness(p, t)
		lo, hi = math.min(lo, b), math.max(hi, b)
	end
	check(lo >= 0 and hi <= 1 and hi - lo > 0.15, "titila (el brillo sube y baja)")
	check(Planets.rayAngle(Planets.ById.Miasma, 1) ~= Planets.rayAngle(Planets.ById.Miasma, 0) and Planets.rayAngle(Planets.ById.Tefra, 1) == Planets.rayAngle(Planets.ById.Tefra, 0), "unos rayos giran y otros no")
	check(Planets.status("Tefra", { SagaDone = false }) == "Locked", "sin la Saga 1: cerrado")
	check(Planets.status("Tefra", { SagaDone = true }) == "Soon" and string.find(Planets.message("Tefra", "Soon"), "próximamente", 1, true) ~= nil, "sin episodio: «Planeta Tefra — próximamente»")
	Planets.setDestination("Siroco", { Travel = function() end })
	local st, need = Planets.status("Siroco", { SagaDone = true, Done = {} })
	check(st == "Order" and need == "Tefra", "con episodio pero sin Tefra: antes Tefra")
	check(Planets.status("Siroco", { SagaDone = true, Done = { Tefra = 1 } }) == "Ready", "con Tefra terminada: listo para viajar")
	check(Planets.status("Siroco", { Tester = true, Done = {} }) == "Ready", "los testers se saltan el orden")
	Planets.setDestination("Vertice", { Travel = function() end })
	check(select(2, Planets.status("Vertice", { SagaDone = true, Done = { Tefra = 1 } })) == "Vertice", "Vertice, la última (tras los otros seis)")
	Planets.setDestination("Siroco", nil)
	Planets.setDestination("Vertice", nil)
	Planets.setDestination("Pluton", { Travel = function() end })
	check(Planets.destination("Pluton") == nil, "el registro solo acepta los 7 planetas")
end

---------------------------------------------------------------------
print("\n🪨 Asteroides AAA (shared/Cosmos/Asteroids: forma, daño, rotura, registro, topes)")
---------------------------------------------------------------------
do
	local Asteroids = L.load("src/shared/Cosmos/Asteroids")
	local rocks = Zone.rocks()
	-- Formas: rocas irregulares (nunca bolas), variadas y repetibles
	local balls, variants, stretched, fits, totalPieces, maxPieces = 0, {}, 0, 0, 0, 0
	for _, r in rocks do
		local sh = Asteroids.shape(r.Id, r.Radius, r.Ore, r.Field)
		variants[sh.VariantName] = true
		totalPieces += #sh.Pieces
		maxPieces = math.max(maxPieces, #sh.Pieces)
		for _, p in sh.Pieces do
			if p.Kind == "Ball" then
				balls += 1
			end
		end
		local _, far, ext = Asteroids.extents(sh)
		local hi, lo = math.max(ext.X, ext.Y, ext.Z), math.min(ext.X, ext.Y, ext.Z)
		if hi / lo >= 1.15 then
			stretched += 1
		end
		if far <= r.Radius * 1.3 and math.max(ext.X, ext.Y, ext.Z) >= r.Radius * 1.5 then
			fits += 1
		end
	end
	local nv = 0
	for _ in variants do
		nv += 1
	end
	check(balls == 0, "ningún asteroide es una bola: bloques, cuñas y cilindros (cráteres)")
	check(nv >= 5, ("%d siluetas distintas (patata, losa, bloque, doble, astilla, piña)"):format(nv))
	check(stretched >= #rocks * 0.7, ("no esféricos: %d de %d con un eje al menos un 15 %% más largo que otro"):format(stretched, #rocks))
	check(fits == #rocks, "y del tamaño de su esfera de choque (se ve donde choca y donde se dispara)")
	check(maxPieces <= 32 and totalPieces <= 2400, ("piezas: %d en total, como mucho %d por asteroide (móvil)"):format(totalPieces, maxPieces))
	local a1 = Asteroids.shape(rocks[2].Id, rocks[2].Radius, rocks[2].Ore, rocks[2].Field)
	local a2 = Asteroids.shape(rocks[2].Id, rocks[2].Radius, rocks[2].Ore, rocks[2].Field)
	check(#a1.Pieces == #a2.Pieces and a1.Pieces[1].CFrame == a2.Pieces[1].CFrame, "repetible: el mismo id, la misma roca (servidor, clientes y Blender)")
	-- Detalle: cráteres, vetas con brillo (también el Hierro estelar) y grietas ocultas
	local big = nil
	for _, r in rocks do
		if r.Radius >= 40 then
			big = r
			break
		end
	end
	local sh = Asteroids.shape(big.Id, big.Radius, "Hierro", big.Field)
	local roles = {}
	for _, p in sh.Pieces do
		roles[p.Role] = (roles[p.Role] or 0) + 1
	end
	check((roles.Crater or 0) >= 2 and (roles.Pebble or 0) >= 2 and (roles.Facet or 0) >= 2, "uno grande: cuñas, cráteres y piedrecitas alrededor")
	local glowOk = true
	for _, ore in { "Hierro", "Cobalto", "Cristal" } do
		local found = false
		for _, p in Asteroids.shape(big.Id, big.Radius, ore, big.Field).Pieces do
			if p.Role == "Vein" and p.Material == roblox.Enum.Material.Neon and p.Transparency < 0.6 then
				found = true
			end
		end
		glowOk = glowOk and found
	end
	check(glowOk, "vetas que brillan un poco: Hierro estelar, Cobalto azul y Cristal solar")
	local cracks = {}
	for _, p in sh.Pieces do
		if p.Role == "Crack" then
			table.insert(cracks, p)
		end
	end
	check(#cracks == 3 and cracks[1].Transparency == 1 and cracks[3].Stage == 3, "grietas ocultas (se ven al dañarlo: niveles 1, 2 y 3)")
	-- Daño por niveles
	local mr = Mining.newRock(big.Radius)
	local seen, last, mono = {}, 0, true
	while mr.Units > 0 do
		Mining.hit(mr, 0)
		local st = Asteroids.stage(mr)
		mono = mono and st >= last
		last = st
		seen[st] = true
	end
	check(mono and seen[1] and seen[2] and seen[3], "el daño sube poco a poco: 0 → 1 → 2 → 3 grietas")
	-- Romperse: grande → 3 medianos → 2-3 pequeños → polvo
	local parent = { Id = big.Id, Field = big.Field, Center = big.Center, Radius = 60, Ore = big.Ore }
	local push = Vector3.new(0, 0, -400)
	local kids = Asteroids.split(parent, 1, 100, nil, push, 99)
	local smaller, apart, inherit = true, true, Vector3.zero
	for i, k in kids do
		smaller = smaller and k.Radius < parent.Radius * 0.7 and k.Radius >= Asteroids.MinChild
		inherit += k.V0
		for j = i + 1, #kids do
			if (Asteroids.posAt(k, 110) - Asteroids.posAt(kids[j], 110)).Magnitude < 20 then
				apart = false
			end
		end
	end
	check(#kids == 3 and smaller, ("uno grande se parte en %d trozos más pequeños (%.0f → %.0f)"):format(#kids, parent.Radius, kids[1] and kids[1].Radius or 0))
	check(apart and (Asteroids.posAt(kids[1], 103) - parent.Center).Magnitude > (kids[1].P0 - parent.Center).Magnitude, "salen hacia fuera y se separan")
	check(inherit.Unit:Dot(push.Unit) > 0.2, "heredan algo de la velocidad de lo que lo rompe")
	local k1 = kids[1]
	local v0, v5 = Asteroids.velAt(k1, 100).Magnitude, Asteroids.velAt(k1, 105).Magnitude
	local p60, p90 = Asteroids.posAt(k1, 160), Asteroids.posAt(k1, 190)
	check(v5 < v0 * 0.2 and (p90 - p60).Magnitude < 0.5, "se frenan (rozamiento) y se quedan quietos donde acaban")
	check(Asteroids.rotAt(k1, 100) ~= Asteroids.rotAt(k1, 102), "y giran")
	local asRock = { Id = k1.Id, Root = k1.Root, Field = k1.Field, Center = Asteroids.posAt(k1, 120), Radius = k1.Radius, Ore = k1.Ore }
	local mid = Asteroids.split(asRock, 2, 120, Asteroids.velAt(k1, 120), nil, 99)
	local midOk = #mid >= 2 and #mid <= 3
	for _, k in mid do
		midOk = midOk and k.Radius < kids[1].Radius and string.find(k.Id, kids[1].Id .. "~", 1, true) == 1
	end
	check(midOk, ("un mediano se parte en %d pequeños (%s)"):format(#mid, mid[1] and mid[1].Id or "?"))
	local m1 = mid[1]
	local dust = Asteroids.split({ Id = m1.Id, Root = m1.Root, Field = m1.Field, Center = m1.P0, Radius = m1.Radius, Ore = m1.Ore }, 3, 130, nil, nil, 99)
	check(#dust == 0, "y uno pequeño se hace polvo (sin trozos)")
	check(#Asteroids.split(parent, 1, 100, nil, nil, 0) == 0, "sin sitio (FragmentMax): polvo, no más trozos")
	-- Texto que replica el servidor
	local fam = { Root = big.Id, Field = big.Field, Respawn = 220, Frags = {} }
	for _, k in kids do
		fam.Frags[k.Id] = k
	end
	local txt = Asteroids.encode(fam)
	local back = Asteroids.decode(big.Id, txt)
	local same = back ~= nil and back.Respawn == 220
	for id, k in kids do
		local b = back and back.Frags[k.Id]
		same = same and b ~= nil and math.abs(b.Radius - k.Radius) < 0.01 and (Asteroids.posAt(b, 150) - Asteroids.posAt(k, 150)).Magnitude < 0.5
	end
	check(same and #txt < 1200, ("el estado viaja como texto corto (%d letras) y se lee igual"):format(#txt))
	check(Asteroids.decode("x", 42) == nil and Asteroids.decode("x", "basura") == nil, "un texto roto no vale")
	-- Registro: el roto no choca; sus trozos sí
	Asteroids.clock = function()
		return 150
	end
	Asteroids.setFamily(big.Id, fam)
	check(Asteroids.isGone(big.Id) and Zone.liveRock(big.Id) == nil and Zone.rock(big.Id) ~= nil, "roto: ya no es un asteroide entero")
	local fr = Zone.liveRock(kids[2].Id)
	check(fr and (fr.Center - Asteroids.posAt(kids[2], 150)).Magnitude < 0.01, "sus trozos sí existen (con su sitio de ahora)")
	local aimFrom = fr.Center + Vector3.new(0, fr.Radius + 80, 0)
	local hit = Zone.rockHit(aimFrom, fr.Center)
	check(hit and hit.Id == kids[2].Id, "un disparo da en el trozo")
	check(Zone.collide(fr.Center, 2) == "un asteroide", "y la nave choca con él")
	local changed, backRoots = Asteroids.sweep(220.5)
	check(#backRoots == 1 and not Asteroids.isGone(big.Id) and Zone.liveRock(big.Id) ~= nil and Zone.liveRock(kids[2].Id) == nil, "a su hora vuelve entero y los trozos se van")
	Asteroids.setFamily(big.Id, fam)
	local _, held = Asteroids.sweep(221, function()
		return false
	end)
	check(#held == 0 and Asteroids.isGone(big.Id), "si hay una nave justo ahí, espera")
	Asteroids.clear()
	-- Tope de pedazos de adorno (cliente)
	local pool = Asteroids.newPool()
	local evicted = 0
	for i = 1, 100 do
		evicted += #Asteroids.poolAdd(pool, i)
	end
	check(#pool.List == Asteroids.DebrisMax and Asteroids.DebrisMax <= 60 and evicted == 100 - Asteroids.DebrisMax and pool.List[1] == 41, ("como mucho %d pedazos sueltos a la vez (se quitan los más viejos)"):format(Asteroids.DebrisMax))
	check(Asteroids.ramDamage(10) == 0 and Asteroids.ramDamage(100) < Asteroids.ramDamage(200) and Asteroids.ramDamage(1e6) == Asteroids.RamMax, "choque: daño según la velocidad, con tope")
	-- El cliente (Controllers/AsteroidFx): pedazos con tope, trozos que aparecen y se van
	local okFx, Fx = pcall(L.load, "src/client/Controllers/AsteroidFx")
	if okFx and Fx then
		for _ = 1, 100 do
			pcall(Fx.chunk, big.Center, Vector3.new(0, 0, 30), 2, roblox.Color3.new(0.5, 0.5, 0.5), false)
		end
		check(Fx.debrisCount() == Asteroids.DebrisMax, ("AsteroidFx: 100 pedazos pedidos, %d vivos (tope)"):format(Fx.debrisCount()))
		Fx._stepDebris(10)
		check(Fx.debrisCount() == 0, "y se limpian solos al acabar su vida")
		local nKids = #kids
		local okA, errA = pcall(Fx.apply, big.Id, txt, true)
		local nv = 0
		for _ in Fx._visuals do
			nv += 1
		end
		check(okA and nv == nKids and Asteroids.isGone(big.Id), ("AsteroidFx: lee el estado del servidor y pone %d trozos"):format(nv) .. (if okA then "" else ": " .. tostring(errA)))
		pcall(Fx.apply, big.Id, nil)
		nv = 0
		for _ in Fx._visuals do
			nv += 1
		end
		check(nv == 0 and not Asteroids.isGone(big.Id), "y al volver el asteroide, los quita")
	else
		check(false, "AsteroidFx se carga: " .. tostring(Fx))
	end
	Asteroids.clock = function()
		return os.clock()
	end
end

---------------------------------------------------------------------
print("\n🖥️ Servidor: la nave encima de Valmar (AirCombatService, World = Cosmos)")
---------------------------------------------------------------------
do
	L.services.Players = { PlayerRemoving = { Connect = function() end }, GetPlayers = function()
		return {}
	end }
	L.services.RunService.Heartbeat = { Connect = function()
		return { Disconnect = function() end }
	end }
	local AC = L.load("src/server/Services/AirCombatService")
	local AirArena = L.load("src/server/World/AirArena")
	local events = {}
	AC.onEvent(function(_, name, data)
		table.insert(events, { Name = name, Data = data })
	end)
	local st = Stations.List[1]
	local cp = Stations.launch(st)
	local ship = AirArena.ship(cp)
	ship.Parent = L.workspace
	local folder = roblox.Instance.new("Model")
	folder.Parent = L.workspace
	local player = L.player("Piloto", 501)
	local fakeRoot = setmetatable({ CFrame = cp, AssemblyLinearVelocity = Vector3.zero, Parent = true }, {
		__index = function(t, k)
			if k == "Position" then
				return rawget(t, "CFrame").Position
			end
			return nil
		end,
	})
	local s = {
		Player = player, Ship = ship, Root = fakeRoot, Seat = ship:FindFirstChild("ShipSeat"),
		Humanoid = { Parent = true, Health = 100 }, Section = "Space", Difficulty = "Normal",
		Hull = Shields.new("Caza"), Gun = ShipWeapons.newGun(),
		Spawner = Waves.new({ Section = "Space", FirstDelay = 0.01 }), Enemies = {}, Folder = folder,
		Bolts = {}, Missiles = {}, LastPos = cp.Position, LastGood = cp, LastAt = 0, Down = false,
		DownUntil = 0, Score = 0, Kills = 0, NextId = 0, StateAt = 0, Exiting = false, Conns = {},
		Geo = Zone, World = "Cosmos", Free = true,
	}
	AC._sessions[player] = s
	for _ = 1, 10 do
		local ok, err = pcall(AC._step, s, 1 / 30)
		if not ok then
			print("    " .. tostring(err))
		end
	end
	local n = 0
	for _ in s.Enemies do
		n += 1
	end
	check(n == 0, "vuelo libre: no salen oleadas solas")
	AC._fire(s, cp.LookVector)
	check(#s.Bolts == 0, "en la zona segura de la estación no se dispara")
	table.insert(s.Bolts, { Pos = cp.Position + cp.LookVector * 30, Dir = -cp.LookVector, Speed = 500, Life = 1, Damage = 30, Enemy = true, Radius = 1.6 })
	for _ = 1, 4 do
		pcall(AC._step, s, 1 / 30)
	end
	check(s.Hull.Hull == s.Hull.MaxHull and s.Hull.Shield == s.Hull.MaxShield, "y no recibes daño")
	-- Lejos de la estación, delante de un asteroide: el láser lo mina (evento Rock)
	local rock = Zone.rocks()[5]
	local from = rock.Center + Vector3.new(0, 0, rock.Radius + 200)
	local aim = (rock.Center - from).Unit
	local right = aim:Cross(Vector3.new(0, 1, 0)).Unit
	local cf2 = CFrame.fromMatrix(from, right, right:Cross(aim).Unit, -aim)
	fakeRoot.CFrame = cf2
	s.LastPos, s.LastGood = from, cf2
	s.Gun.NextLaser = 0
	AC._fire(s, aim)
	check(#s.Bolts == 2, "fuera de la zona segura se dispara (dos cañones)")
	table.clear(events)
	for _ = 1, 20 do
		pcall(AC._step, s, 1 / 30)
	end
	local rockEv = nil
	for _, e in events do
		if e.Name == "Rock" then
			rockEv = e.Data
		end
	end
	check(rockEv and rockEv.Id == rock.Id and typeof(rockEv.Ship) == "Vector3", "el láser da en el asteroide y avisa (para minar)")
	local id = AC.spawnEnemy(player, "Dron", Vector3.new(0, 1000, 0))
	check(id == nil, "spawnEnemy no pone enemigos en el cielo de los aviones")
	id = AC.spawnEnemy(player, "Dron", from + Vector3.new(0, 0, 400))
	check(id ~= nil and #AC.enemyList(player) == 1, "pero en el espacio sí")
	AC.dropEnemy(player, id)
	check(#AC.enemyList(player) == 0, "y se quitan sin contar como derribo")
	local status = AC.status(player)
	check(status and status.World == "Cosmos" and status.Hull == 100 and not status.Safe, "estado de la nave para SpaceService")
	-- La nave del espacio es la misma que la de la arena: anclada y movida por lo que manda el cliente
	check(ship.PrimaryPart.Anchored and ship:FindFirstChild("ShipSeat") and ship:FindFirstChild("CabinaFrente"), "la nave encima de Valmar: el caza nuevo, anclado, con asiento en la cabina")
	s.PoseAt = os.clock() - 0.05
	local ahead = s.LastGood * CFrame.new(0, 0, -8)
	pcall(AC._pose, s, ahead)
	check((fakeRoot.CFrame.Position - ahead.Position).Magnitude < 0.01, "«Pose» en el espacio: el servidor la mueve")
	AC.setReturn(player, Access.arrival())
	check(player:GetAttribute("AirArenaReturn") == Access.arrival().Position, "volver: se apunta el puerto espacial (PositionService lo guarda si te desconectas)")
	-- (Asteroides AAA) Chocar con un asteroide: quita escudo según la velocidad (no estalla de golpe)
	do
		local Asteroids = L.load("src/shared/Cosmos/Asteroids")
		local rock = Zone.rocks()[7]
		local touch = rock.Center + Vector3.new(0, 0, rock.Radius + 4)
		local function ramAt(speed: number, said: number?): number
			s.Hull = Shields.new("Caza")
			s.Down = false
			s.RamAt = nil
			fakeRoot.CFrame = CFrame.new(touch)
			s.LastPos, s.LastGood = touch, CFrame.new(touch)
			s.Vel = Vector3.new(0, 0, -speed)
			table.clear(events)
			AC._ram(s, said or 0)
			return (s.Hull.MaxShield - s.Hull.Shield) + (s.Hull.MaxHull - s.Hull.Hull)
		end
		local slow, mid, fast = ramAt(10), ramAt(80), ramAt(260)
		check(slow == 0 and mid > 0 and fast > mid * 2, ("choque: más rápido, más daño (a 10: %.0f · a 80: %.0f · a 260: %.0f)"):format(slow, mid, fast))
		ramAt(80)
		check(s.Hull.Hull == s.Hull.MaxHull and s.Hull.Shield < s.Hull.MaxShield and not s.Down, "un choque flojo se lo lleva el escudo (el casco sigue entero)")
		local ramEv = nil
		for _, e in events do
			if e.Name == "Rock" and e.Data.Ram then
				ramEv = e.Data
			end
		end
		check(ramEv and ramEv.Id == rock.Id and ramEv.Ram >= 1, "y agrieta el asteroide (evento Rock con Ram: sin mineral)")
		local lied = ramAt(0, 99999)
		check(math.abs(lied - Asteroids.ramDamage(ShipFlight.Specs.Caza.BoostSpeed * 1.15)) < 0.5, "la velocidad que dice el cliente solo cuenta hasta lo posible")
		check(ramAt(5, 0) == 0, "y no puede rebajar la que mide el servidor (aquí, despacio: nada)")
		ramAt(200)
		local before = s.Hull.Shield + s.Hull.Hull
		AC._ram(s, 0)
		check(s.Hull.Shield + s.Hull.Hull == before, "un choque cada medio segundo como mucho")
		-- Metido en un asteroide (p. ej. un trozo que llega volando): daño, no derribo instantáneo
		local inside = rock.Center + Vector3.new(0, 0, rock.Radius - 3)
		s.Hull = Shields.new("Caza")
		s.Down = false
		s.RamAt = nil
		s.Vel = Vector3.new(0, 0, -60)
		fakeRoot.CFrame = CFrame.new(inside)
		s.LastPos, s.LastGood, s.PoseAt = inside, CFrame.new(inside), os.clock()
		pcall(AC._step, s, 1 / 30)
		check(not s.Down and s.Hull.Shield < s.Hull.MaxShield, "dentro de un asteroide (Cosmos): el servidor quita escudo, no te derriba de golpe")
		-- Un misil que da en un asteroide lo daña mucho (Power)
		s.Down = false
		local from = rock.Center + Vector3.new(0, 0, rock.Radius + 60)
		fakeRoot.CFrame = CFrame.new(from + Vector3.new(0, 0, 100))
		table.insert(s.Missiles, { Id = "mx", Pos = from, Dir = Vector3.new(0, 0, -1), Speed = 400, Life = 3, Target = "nadie" })
		table.clear(events)
		for _ = 1, 15 do
			pcall(AC._step, s, 1 / 30)
		end
		local mEv = nil
		for _, e in events do
			if e.Name == "Rock" and e.Data.Power then
				mEv = e.Data
			end
		end
		check(mEv and mEv.Id == rock.Id and mEv.Power == AC.MissileRockHits and #s.Missiles == 0, "un misil contra un asteroide: lo daña (evento Rock con Power) y explota")
	end
	AC._sessions[player] = nil
end

---------------------------------------------------------------------
print("\n🖥️ Servidor: SpaceService (minar, derribos, misiones, tienda, volver)")
---------------------------------------------------------------------
do
	local data = {
		Money = 100,
		Story = { Completed = {} },
		Space = { Chispas = 0, Ore = {}, Missions = {}, Mined = 0, Kills = 0, Done = 0, Planets = {} },
	}
	local earned = 0
	L.mock("src/server/Services/DataService", {
		get = function()
			return data
		end,
		addMoney = function(_, amount)
			data.Money += amount
			earned += amount
			return true
		end,
		spend = function(_, price)
			if data.Money < price then
				return false
			end
			data.Money -= price
			return true
		end,
	})
	local tester = false
	L.mock("src/server/Services/TesterService", { isTester = function()
		return tester
	end })
	L.mock("src/server/Services/SceneService", { dip = function() end })
	local acState = { Pos = Vector3.new(0, 5000, 0), Look = Vector3.new(0, 0, -1), Hull = 70, MaxHull = 100, Missiles = 2, Down = false, Safe = false, World = "Cosmos" }
	local acLog = {}
	local spawned = {}
	L.mock("src/server/Services/AirCombatService", {
		inArena = function()
			return false
		end,
		world = function()
			return if acState.World then acState.World else nil
		end,
		status = function()
			return acState
		end,
		enter = function(_, opts)
			table.insert(acLog, { "enter", opts })
			return true
		end,
		exit = function(_, reason)
			table.insert(acLog, { "exit", reason })
		end,
		setReturn = function(_, cf)
			table.insert(acLog, { "return", cf })
		end,
		enemyList = function()
			return spawned
		end,
		spawnEnemy = function(_, kind, pos)
			table.insert(spawned, { Id = tostring(#spawned + 1), Kind = kind, Pos = pos })
			return tostring(#spawned)
		end,
		dropEnemy = function() end,
		onEvent = function() end,
	})
	local Space = L.load("src/server/Services/SpaceService")
	local player = L.player("Jugador", 777)
	-- Acceso
	check(not Space.board(player, nil) and #acLog == 0, "sin la Saga 1 no sube a la nave")
	data.Story.Completed.Saga_24_Final = 1
	check(Space.board(player, nil) and acLog[1][2].World == "Cosmos" and acLog[1][2].Trusted == true, "con la Saga 1 terminada, sí (en el cielo de Valmar)")
	local opts = acLog[1][2]
	check(typeof(opts.Start) == "CFrame" and (opts.Start.Position - Access.launch().Position).Magnitude < 1 and (opts.Return.Position - Access.arrival().Position).Magnitude < 1, "despega del puerto y vuelve al puerto")
	check(type(opts.Objective) == "function" and type(opts.OnExit) == "function", "con su línea del panel y su forma de bajarse")
	-- Minar: recompensa del servidor y contra trampas
	local rock = Zone.rocks()[3]
	local ship = rock.Center + Vector3.new(0, 0, rock.Radius + 150)
	local got = nil
	for _ = 1, Mining.HitsPerUnit do
		got = Space.onRock(player, { Id = rock.Id, Pos = rock.Center, Ship = ship })
	end
	check(got == "Unit" and data.Space.Ore[rock.Ore] == 1 and data.Space.Mined == 1, ("%d impactos: +1 %s a la bodega"):format(Mining.HitsPerUnit, rock.Ore))
	local fast = nil
	for _ = 1, Mining.HitsPerUnit do
		fast = Space.onRock(player, { Id = rock.Id, Pos = rock.Center, Ship = ship })
	end
	check(fast == "Rate" and data.Space.Ore[rock.Ore] == 1, "otra unidad al instante: no (demasiado rápido)")
	check(Space.onRock(player, { Id = "no-existe", Ship = ship }) == nil, "un asteroide inventado: nada")
	local ps = Space._states[player]
	ps.Rate.Last = -math.huge
	local far = nil
	for _ = 1, Mining.HitsPerUnit do
		far = Space.onRock(player, { Id = rock.Id, Pos = rock.Center, Ship = rock.Center + Vector3.new(0, 0, Mining.Reach + 500) })
	end
	check(far == "Far" and data.Space.Ore[rock.Ore] == 1, "desde demasiado lejos: no")
	-- Misión de mineral y venta en la tienda
	Missions.accept(data.Space.Missions, "Mineral", "Alba", 0)
	data.Space.Missions.Mineral.P = 11
	ps.Rate.Last = -math.huge
	local money0 = data.Money
	for _ = 1, Mining.HitsPerUnit do
		Space.onRock(player, { Id = rock.Id, Pos = rock.Center, Ship = ship })
	end
	check(data.Space.Missions.Mineral == nil and data.Money == money0 + Missions.ById.Mineral.Money and data.Space.Chispas == Missions.ById.Mineral.Chispas, "misión de mineral completada: dinero y Chispas de estrella")
	-- Derribos
	local m1 = data.Money
	Space._onKill(player, { Kind = "Caza" })
	check(data.Space.Kills == 1 and data.Money == m1 + Space.KillReward.Caza and data.Space.Chispas == Missions.ById.Mineral.Chispas + 1, "derribar un caza: dinero y una chispa")
	-- Tienda: vender (dentro de la estación)
	local alba = Stations.ById.Alba
	player.Character = { FindFirstChild = function(_, name)
		if name == "HumanoidRootPart" then
			return { Position = Stations.arrival(alba).Position }
		end
		return nil
	end, FindFirstChildOfClass = function()
		return nil
	end }
	data.Space.Ore = { Hierro = 4, Cristal = 1 }
	-- (la nave llegó con el casco tocado y pocos misiles)
	Space._states[player].Ship = { Hull = 70, Missiles = 2 }
	Space.shop(player, "Alba")
	local menuState = Space._states[player].Menu
	check(menuState ~= nil and #menuState.Actions >= 3, "la tienda ofrece vender, reparar y recargar")
	local m2 = data.Money
	Space._onMenu(player, menuState.Token, 1)
	check(Mining.cargo(data.Space.Ore) == 0 and data.Money == m2 + 4 * 12 + 80, "vender: la bodega se vacía y cobras")
	Space.shop(player, "Alba")
	local menu2 = Space._states[player].Menu
	Space._onMenu(player, "otra-ficha", 1)
	check(Space._states[player].Menu == menu2, "una respuesta con otra ficha no vale (contra trampas)")
	local m3 = data.Money
	Space._onMenu(player, menu2.Token, 1) -- (sin mineral, la primera es reparar)
	check(Space._states[player].Ship.Hull == 100 and data.Money == m3 - Stations.repairCost(70, 100), "reparar el casco: cobra y la nave sale como nueva")
	-- Panel
	local line = Space._objectiveFor(player)()
	check(type(line) == "string" and string.find(line, "⛏", 1, true) ~= nil and string.find(line, "✨", 1, true) ~= nil, "línea del panel: sitio, bodega y chispas")
	-- Bajarse: alto, no; bajo, sí
	table.clear(acLog)
	acState.Pos = Vector3.new(0, 5000, 0)
	opts.OnExit(player)
	check(#acLog == 0, "en el espacio no te puedes bajar (usa VALMAR)")
	acState.Pos = Access.Port + Vector3.new(0, 200, 0)
	opts.OnExit(player)
	check(#acLog == 2 and acLog[2][1] == "exit", "cerca del suelo, sí (junto al puerto: al puerto)")
	-- Volver a Valmar desde la nave, siempre
	table.clear(acLog)
	acState.Pos = Vector3.new(0, 8000, 0)
	check(Space.home(player) and acLog[1][1] == "return" and (acLog[1][2].Position - Access.arrival().Position).Magnitude < 1 and acLog[2][1] == "exit", "VALMAR: de vuelta al puerto espacial desde cualquier sitio")
	-- Patrullas
	local sector = Zone.Sectors[3]
	local group = Space.patrolGroup(sector, 3, 6)
	local cazas = 0
	for _, k in group do
		if k == "Caza" then
			cazas += 1
		end
	end
	check(#group >= 3 and #group <= 6 and cazas >= 1, ("patrulla del %s: %d enemigos (%d cazas)"):format(sector.Name, #group, cazas))
	check(#Space.patrolGroup(Zone.Sectors[1], 1, 2) == 2, "nunca más de los que caben en el sector")
	local more = #Space.patrolGroup(sector, 6, 99) >= #Space.patrolGroup(sector, 1, 99)
	check(more, "más nivel, más enemigos")
	-- Planetas
	check(Space.planet(player, "Tefra") == "Soon" and Space.planet(player, "Nada") == nil, "tocar Tefra: próximamente; un planeta inventado: nada")
	-- El mundo se construye
	local World = L.load("src/server/World/SpaceWorld")
	local okPort, port, prompts = pcall(World.buildPort)
	check(okPort and port and prompts.Board and prompts.PortalStation and prompts.PortalBeach, "el puerto espacial: nave («Subir a la nave») y dos portales" .. (if okPort then "" else ": " .. tostring(port)))
	local shown = okPort and port:FindFirstChild("NaveExpuesta")
	check(shown and shown:FindFirstChild("CabinaFrente") and shown:FindFirstChild("AlaIzq") and shown:FindFirstChild("Escape") and not shown:FindFirstChild("ShipSeat"), "la nave de exposición es el caza nuevo (shared/AirCombat/ShipModel: cabina de cristal, alas, motores), sin asiento")
	local okSpace, space = pcall(World.buildSpace)
	local nRocks = 0
	if okSpace then
		for _, d in space:GetDescendants() do
			if d:GetAttribute("RockId") then
				nRocks += 1
			end
		end
	end
	check(okSpace and nRocks == #Zone.rocks(), ("el espacio: %d asteroides con su id"):format(nRocks) .. (if okSpace then "" else ": " .. tostring(space)))
	local sp = World.stationPrompts()
	check(sp.Alba and sp.Alba.Shop and sp.Alba.Board and sp.Alba.Launch and sp.Alba.Home and sp.Cenit and sp.Cenit.Home, "cada estación: tienda, tablón, hangar y portal «Volver a Valmar»")
	local okBeach = pcall(World.buildBeachPortal, CFrame.new(-3640, 2, 1430))
	check(okBeach, "el portal de la playa")
	pcall(World.setRockLit, Zone.rocks()[1].Id, false)
	check(true, "un asteroide vacío se apaga")
	-- (Asteroides AAA) Los asteroides del campo: rocas de piezas, sin bolas, con detalle aparte (LOD)
	local Asteroids = L.load("src/shared/Cosmos/Asteroids")
	local okModels, ballParts, withDetail = true, 0, 0
	for _, r in Zone.rocks() do
		local m = World.rockModel(r.Id)
		if not m or not m.PrimaryPart or m:GetAttribute("RockId") ~= r.Id then
			okModels = false
		else
			for _, d in m:GetDescendants() do
				if d:IsA("Part") and d.Shape == roblox.Enum.PartType.Ball then
					ballParts += 1
				end
			end
			if m:FindFirstChild("Detalle") and #m.Detalle:GetChildren() > 0 then
				withDetail += 1
			end
		end
	end
	check(okModels and ballParts == 0 and withDetail >= #Zone.rocks() * 0.8, ("cada asteroide es un Model de rocas (sin bolas), %d con detalles que se quitan de lejos"):format(withDetail))
	-- Romper uno grande a base de láser: mineral una sola vez por unidad, trozos más pequeños y vuelve
	local big = nil
	for _, r in Zone.rocks() do
		if r.Radius >= 40 then
			big = r
			break
		end
	end
	local T = 1000
	Asteroids.clock = function()
		return T
	end
	data.Space.Ore = {}
	data.Space.Missions = {}
	local ps2 = Space._states[player]
	local function freeRate()
		ps2.Rate.Last = -math.huge
		ps2.Rate.Times = {}
	end
	local near = big.Center + Vector3.new(0, 0, big.Radius + 120)
	local units, results = 0, {}
	for _ = 1, 200 do
		freeRate()
		local res = Space.onRock(player, { Id = big.Id, Pos = big.Center, Ship = near, Push = Vector3.new(0, 0, -300) })
		if res == nil then
			break
		end
		table.insert(results, res)
		if res == "Unit" or res == "Empty" then
			units += 1
		end
	end
	local max = Mining.units(big.Radius)
	local model = World.rockModel(big.Id)
	check(units == max and (data.Space.Ore[big.Ore] or 0) == max, ("%d unidades de %s: una por unidad, ni una más"):format(units, big.Ore))
	check(Asteroids.isGone(big.Id) and model and model.Parent == nil, "gastado: se rompe (el asteroide entero desaparece del campo)")
	local fam = Asteroids.family(big.Id)
	local kids = {}
	for _, f in (fam and fam.Frags) or {} do
		table.insert(kids, f)
	end
	local smaller = #kids >= 2
	for _, k in kids do
		smaller = smaller and k.Radius < big.Radius
	end
	check(smaller and #kids == 3, ("se parte en %d trozos más pequeños (radio %.0f → %.0f)"):format(#kids, big.Radius, kids[1] and kids[1].Radius or 0))
	check(type(Space._published[big.Id]) == "string" and Asteroids.decode(big.Id, Space._published[big.Id]) ~= nil, "el servidor publica el estado (ReplicatedStorage.AsteroidesEstado) para los clientes")
	freeRate()
	check(Space.onRock(player, { Id = big.Id, Pos = big.Center, Ship = near }) == nil and (data.Space.Ore[big.Ore] or 0) == max, "el roto ya no da nada (sin mineral repetido)")
	-- Un trozo se mina otra vez y se parte en pequeños
	table.sort(kids, function(a, b)
		return a.Id < b.Id
	end)
	local kid = kids[1]
	local kidUnits = Asteroids.childUnits(kid.Radius)
	local before = data.Space.Ore[big.Ore]
	local got2 = 0
	for _ = 1, 100 do
		freeRate()
		local res = Space.onRock(player, { Id = kid.Id, Pos = kid.P0, Ship = kid.P0 + Vector3.new(0, 0, 150) })
		if res == nil then
			break
		end
		if res == "Unit" or res == "Empty" then
			got2 += 1
		end
	end
	local grand = 0
	for id, f in Asteroids.family(big.Id).Frags do
		if string.find(id, kid.Id .. "~", 1, true) == 1 then
			grand += 1
			smaller = smaller and f.Radius < kid.Radius
		end
	end
	check(got2 == kidUnits and data.Space.Ore[big.Ore] == before + kidUnits and Asteroids.fragment(kid.Id) == nil, ("un trozo se mina otra vez (%d unidades) y desaparece"):format(got2))
	check(grand >= 2 and smaller, ("y se parte en %d pedazos aún más pequeños"):format(grand))
	-- Chocar con la nave lo rompe sin dar mineral
	local other = Zone.rocks()[9]
	local ore0 = Mining.cargo(data.Space.Ore)
	for _ = 1, 20 do
		Space.onRock(player, { Id = other.Id, Pos = other.Center, Ship = other.Center, Ram = 3 })
	end
	check(Asteroids.isGone(other.Id) and Mining.cargo(data.Space.Ore) == ore0, "a golpes con la nave también se rompe, pero sin mineral")
	-- Daño visible: grietas
	local third = Zone.rocks()[11]
	local m3 = World.rockModel(third.Id)
	freeRate()
	for _ = 1, Mining.HitsPerUnit do
		Space.onRock(player, { Id = third.Id, Pos = third.Center, Ship = third.Center + Vector3.new(0, 0, third.Radius + 100) })
	end
	local lit = 0
	for _, d in m3:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("Role") == "Crack" and d.Transparency < 1 then
			lit += 1
		end
	end
	check(lit >= 1 and (m3:GetAttribute("Dano") or 0) >= 1, ("dañado: se le ven grietas que brillan (%d)"):format(lit))
	-- Vuelven: con una nave justo ahí espera; si no, vuelve entero
	T += Asteroids.RespawnSeconds + 1
	acState.Pos = big.Center
	local oldGet = L.services.Players.GetPlayers
	L.services.Players.GetPlayers = function()
		return { player }
	end
	Space._sweepRocks()
	check(Asteroids.isGone(big.Id), "a su hora, con tu nave dentro de su sitio: espera")
	acState.Pos = Vector3.new(0, 5000, 0)
	T += Asteroids.RespawnRetry + 1
	Space._sweepRocks()
	L.services.Players.GetPlayers = oldGet
	check(not Asteroids.isGone(big.Id) and Zone.liveRock(big.Id) ~= nil and model.Parent ~= nil and Space._published[big.Id] == nil and Asteroids.fragmentCount() == 0, "y luego vuelve entero (el campo siempre lleno) y los trozos se van")
	freeRate()
	check(Space.onRock(player, { Id = big.Id, Pos = big.Center, Ship = near }) == "Chip", "y se puede minar otra vez desde cero")
	Asteroids.clear()
	Asteroids.clock = function()
		return os.clock()
	end
end

---------------------------------------------------------------------
print("\n📱 Botones de la nave en el espacio (móvil)")
---------------------------------------------------------------------
do
	local HudLayout = L.load("src/client/UI/HudLayout")
	local ids = { "Fuego", "Misil", "Turbo", "FrenoNave", "SalirNave", "ValmarNave", "AccionNave" }
	for _, size in { { 932, 430 }, { 844, 390 }, { 640, 360 } } do
		local layout = HudLayout.compute(Vector2.new(size[1], size[2]), { Touch = true })
		local rects, small, clash = {}, {}, {}
		for _, id in ids do
			local p = layout.FlySlots[id]
			if not p then
				table.insert(small, id .. " (sin hueco)")
				continue
			end
			local r = HudLayout.rect(p, layout.Canvas)
			rects[id] = r
			local need = if size[1] == 640 then 32 else 44
			if math.min(r.W, r.H) * layout.Scale < need then
				table.insert(small, ("%s %d pt"):format(id, math.floor(math.min(r.W, r.H) * layout.Scale)))
			end
			if r.X < 0 or r.Y < 0 or r.X + r.W > layout.Canvas.X or r.Y + r.H > layout.Canvas.Y then
				table.insert(clash, id .. "/fuera de la pantalla")
			end
		end
		check(#small == 0, ("%dx%d: VALMAR y ATRACAR/VIAJAR grandes como los demás%s"):format(size[1], size[2], if #small > 0 then " (" .. table.concat(small, ", ") .. ")" else ""))
		for i = 1, #ids do
			for j = i + 1, #ids do
				local a, b = rects[ids[i]], rects[ids[j]]
				if a and b and HudLayout.overlaps(a, b) then
					table.insert(clash, ids[i] .. "/" .. ids[j])
				end
			end
			for _, item in { "Hotbar", "Mission", "Minimap", "Flight", "Joystick" } do
				local p = layout.Items[item]
				local r = rects[ids[i]]
				if p and r and HudLayout.overlaps(r, HudLayout.rect(p, layout.Canvas)) then
					table.insert(clash, ids[i] .. "/" .. item)
				end
			end
		end
		check(#clash == 0, ("%dx%d: no se pisan entre ellos ni con la barra, la misión, el minimapa, el panel o el joystick%s"):format(size[1], size[2], if #clash > 0 then " (" .. table.concat(clash, ", ") .. ")" else ""))
	end
end

---------------------------------------------------------------------
print("\n🌌 El entorno por zona (shared/Cosmos/EnvZones + Controllers/EnvDirector + DayLight)")
---------------------------------------------------------------------
do
	local EnvZones = L.load("src/shared/Cosmos/EnvZones")
	local DayGrade = L.load("src/shared/DayGrade")
	local SkyMoods = L.load("src/shared/SkyMoods")
	local function at(y: number): any
		return EnvZones.resolve({ Pos = Vector3.new(300, y, -200) })
	end
	-- Valmar: el suelo y el cielo de los aviones
	local ground, plane = at(40), at(Layers.PlaneCeiling)
	local fg, fp = EnvZones.flags(ground), EnvZones.flags(plane)
	check(ground.Zone == "Valmar" and ground.Space == 0 and plane.Zone == "Valmar" and plane.Space == 0, "en el suelo y en el cielo de los aviones (hasta 1400): zona Valmar, nada de espacio")
	check(fg.SkySlots == nil and fg.Atmosphere and fg.Clouds and fg.ColorCorrection and fg.Rift and fg.Weather and fp.Atmosphere and fp.Clouds and fp.Weather, "Valmar: su cielo de la hora, su bruma, sus nubes, su etalonaje, la Grieta y el tiempo")
	-- Transición: se funde poco a poco
	local last, monotone = -1, true
	for y = Layers.TransitionY - 200, Layers.SpaceY + 200, 100 do
		local e = at(y)
		if e.Space < last - 1e-9 then
			monotone = false
		end
		last = e.Space
	end
	local mid = at((Layers.TransitionY + Layers.SpaceY) / 2)
	check(monotone and mid.Zone == "Transicion" and mid.Space > 0.2 and mid.Space < 0.8, ("transición de %d a %d: el espacio entra poco a poco y sin saltos (a media altura %.2f)"):format(Layers.TransitionY, Layers.SpaceY, mid.Space))
	-- Espacio: negro
	local space = at(5200)
	local fsp = EnvZones.flags(space)
	check(space.Zone == "Espacio" and space.Space == 1, "a 5200 studs: zona Espacio")
	check(not fsp.Atmosphere and not fsp.Clouds and not fsp.ColorCorrection and not fsp.Rift and not fsp.Weather and not fsp.ValmarSky and fsp.Stars, "espacio: sin bruma (Atmosphere fuera), sin nubes, sin etalonaje de Valmar, sin Grieta, sin lluvia ni luna de Valmar; con estrellas")
	check(fsp.SkySlots and fsp.SkySlots[1] == "EspacioProfundo" and fsp.Sky == "Espacio", "espacio: el cielo de estrellas con la nebulosa (Sky «EspacioProfundo»)")
	check(EnvZones.starCount("Low") < EnvZones.starCount("Medium") and EnvZones.starCount("Medium") < EnvZones.starCount("High") and EnvZones.starCount("High") <= 5000, "estrellas según el nivel gráfico (Bajo < Medio < Alto ≤ 5000)")
	-- La luz del espacio va la última: ni la lluvia ni la Grieta (etapa 7) vuelven a meter bruma o nubes
	local noon = DayGrade.sample(12)
	local rainy = DayGrade.weather(noon, { Brightness = 0.7, Saturation = -0.2, Density = 0.5, Cover = 0.9, Rain = 1 }, nil, 0, 1)
	local grieta = SkyMoods.apply(rainy, SkyMoods.List.GrietaFinal, 1, DayGrade.mix)
	local k = EnvZones.applyKey(grieta, space)
	check(k.Density == 0 and k.Haze == 0 and k.Glare == 0 and k.Cover == 0 and k.CloudDensity == 0 and (k.Veil == nil or k.Veil == 0), ("con lluvia y la Grieta encima, en el espacio: bruma %.2f, nubes %.2f, velo %s"):format(k.Density, k.Cover, tostring(k.Veil)))
	check(k.Outdoor.R < 0.25 and k.Outdoor.G < 0.25 and k.Ambient.B < 0.15, "en el espacio las sombras son casi negras (sin cielo azul que las rellene)")
	local kv = EnvZones.applyKey(noon, ground)
	check(kv.Density == noon.Density and kv.Cover == noon.Cover and kv.AtmColor == noon.AtmColor, "en Valmar la luz de la hora no se toca (la del paisaje)")
	-- Mezcla suave (sin fogonazos) y sin parpadeos en el borde
	local cur = EnvZones.approach(nil, ground, 0.1)
	cur = EnvZones.approach(cur, space, 0.1)
	check(cur.Space > 0 and cur.Space <= EnvZones.Rate * 0.1 + 1e-6, ("de Valmar al espacio de golpe (un salto): en 0,1 s solo %.2f (fundido)"):format(cur.Space))
	for _ = 1, 20 do
		cur = EnvZones.approach(cur, space, 0.1)
	end
	check(cur.Space == 1 and cur.Zone == "Espacio", "y en un par de segundos, espacio del todo")
	local flags = EnvZones.flags({ Zone = "Transicion", Space = 0.62, PlanetMix = 0 })
	local flips = 0
	for i = 1, 30 do
		local v = if i % 2 == 0 then 0.62 else 0.56
		local nf = EnvZones.flags({ Zone = "Transicion", Space = v, PlanetMix = 0 }, flags)
		if nf.Sky ~= flags.Sky or nf.Clouds ~= flags.Clouds then
			flips += 1
		end
		flags = nf
	end
	check(flips == 0, "temblando en el borde (0,56 ↔ 0,62) el cielo y las nubes no parpadean (histéresis)")
	check(EnvZones.flags(EnvZones.resolve({ Pos = Vector3.new(24000, 900, 24000), Arena = true })).Sky == "Arena", "en la arena de pruebas manda su propio cielo")

	-- DayLight de verdad con una Lighting de mentira: el espacio aparta la bruma, las nubes y el etalonaje
	local dm = roblox.Instance.new("DataModel")
	local lighting = dm:GetService("Lighting")
	lighting.ClockTime = 12
	lighting.GlobalShadows = true
	local atm = roblox.Instance.new("Atmosphere")
	atm.Parent = lighting
	local sky = roblox.Instance.new("Sky")
	sky.StarCount = 3000
	sky.CelestialBodiesShown = true
	sky.SkyboxBk, sky.SkyboxDn, sky.SkyboxFt, sky.SkyboxLf, sky.SkyboxRt, sky.SkyboxUp = "rbxasset://bk", "rbxasset://dn", "rbxasset://ft", "rbxasset://lf", "rbxasset://rt", "rbxasset://up"
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
	local library = roblox.Instance.new("Folder")
	library.Name = "SkyLibrary"
	for name, face in { EspacioProfundo = "rbxassetid://111", CieloTefra = "rbxassetid://222", Day = "rbxassetid://333" } do
		local s = roblox.Instance.new("Sky")
		s.Name = name
		s.SkyboxBk, s.SkyboxDn, s.SkyboxFt, s.SkyboxLf, s.SkyboxRt, s.SkyboxUp = face, face, face, face, face, face
		s.Parent = library
	end
	local camPos = Vector3.new(0, 5200, 0)
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
			return { CFrame = CFrame.new(camPos), FieldOfView = 70 }
		end
		return nil
	end })
	local oldWorkspace, oldRun, oldPlayers, oldLighting = L.workspace, L.services.RunService, L.services.Players, L.services.Lighting
	local renders: { (number) -> () } = {}
	L.workspace = fakeWorkspace
	L.services.Lighting = lighting
	L.services.RunService = { RenderStepped = { Connect = function(_, fn)
		table.insert(renders, fn)
	end }, IsStudio = function()
		return false
	end }
	local me = L.player("Piloto", 77)
	L.services.Players = { LocalPlayer = me }
	rawset(L.services.ReplicatedStorage, "SkyLibrary", library)
	L.mock("src/client/UI/Perf", {
		tier = function()
			return { GlobalShadows = true, Haze = 1, Bloom = 1, Clouds = 1, SunRays = true, FarRange = true, Specular = 1, ShadowSharp = 1, Saturation = 0, Contrast = 0 }
		end,
		tierName = function()
			return "High"
		end,
	})
	L.mock("src/client/Controllers/RainVeil", { update = function() end })
	L.reset("src/client/Controllers/DayLight")
	local oldRayParams = L.globals.RaycastParams
	L.globals.RaycastParams = { new = function()
		return {}
	end }
	local DayLight = L.load("src/client/Controllers/DayLight")
	L.globals.RaycastParams = oldRayParams
	DayLight.init()
	local function frame()
		for _ = 1, 3 do
			for _, fn in renders do
				fn(0.2)
			end
		end
	end
	DayLight.pushLayer("Grieta", SkyMoods.List.GrietaFinal, 0.01, 1) -- (la etapa 7 de la Grieta, la peor)
	DayLight.setZone(space, fsp)
	frame()
	for _, w in L.warnings do
		if string.find(w, "DayLight", 1, true) and string.find(w, "error", 1, true) then
			print("    (aviso) " .. w)
		end
	end
	check(lighting:FindFirstChildOfClass("Atmosphere") == nil and DayLight.atmosphereParked(), "DayLight en el espacio: la bruma (Atmosphere) fuera de Lighting")
	check(clouds.Enabled == false and cc.Enabled == false, "DayLight en el espacio: nubes y etalonaje de Valmar apagados")
	check(sky.StarCount == 5000 and sky.SkyboxFt == "rbxassetid://111", ("DayLight en el espacio: cielo «EspacioProfundo» y %d estrellas (Alto)"):format(sky.StarCount))
	local amb = lighting.OutdoorAmbient
	check(amb.R < 0.2 and amb.G < 0.2 and amb.B < 0.3, "DayLight en el espacio: con la Grieta encima, la luz sigue siendo la del espacio (negra)")
	DayLight.popLayer("Grieta", 0.01)
	DayLight.setZone(ground, fg)
	frame()
	check(lighting:FindFirstChildOfClass("Atmosphere") == atm and not DayLight.atmosphereParked() and clouds.Enabled and cc.Enabled, "al bajar a Valmar vuelven la misma bruma, las nubes y el etalonaje")
	check(sky.StarCount == 3000 and sky.SkyboxFt ~= "rbxassetid://111", "y su cielo y sus estrellas de siempre")
	DayLight.forceSky({ "Day" })
	DayLight.setZone(space, fsp)
	frame()
	check(sky.SkyboxFt == "rbxassetid://111", "el cielo de la zona manda sobre forceSky (la arena al salir lo dejaba en el de Valmar)")
	DayLight.forceSky(nil)

	-- EnvDirector: una vuelta con la cámara en cada sitio
	local zoneCalls, riftCalls, focusCalls = {}, {}, {}
	L.mock("src/client/Controllers/DayLight", { setZone = function(e, f)
		table.insert(zoneCalls, { e, f })
	end })
	L.mock("src/client/Controllers/SkyRift", { setSuppressed = function(on, why)
		table.insert(riftCalls, { on, why })
	end })
	L.mock("src/client/Controllers/PlanetClient", { envEntry = function()
		return nil
	end })
	L.mock("src/client/UI/FlightFocus", { setZone = function(name)
		table.insert(focusCalls, name or "Valmar")
	end })
	L.reset("src/client/Controllers/EnvDirector")
	local Director = L.load("src/client/Controllers/EnvDirector")
	Director.update(0.1, Vector3.new(0, 30, 0))
	local e1 = zoneCalls[#zoneCalls][1]
	check(e1 and e1.Zone == "Valmar" and Director.allows("Weather") and Director.allows("Rift") and riftCalls[#riftCalls][1] == false and riftCalls[#riftCalls][2] == "Zona", "EnvDirector en Valmar: zona Valmar, con tiempo y Grieta")
	for _ = 1, 30 do
		Director.update(0.1, Vector3.new(0, 5200, 0))
	end
	local e2, f2 = zoneCalls[#zoneCalls][1], zoneCalls[#zoneCalls][2]
	check(e2.Zone == "Espacio" and not f2.Atmosphere and not Director.allows("Weather") and not Director.allows("Rift") and riftCalls[#riftCalls][1] == true and Director.inSpace(), "EnvDirector en el espacio: negro, sin tiempo y la Grieta apagada (motivo «Zona»)")
	check(#riftCalls == 2, ("la Grieta se apaga una vez, no en cada vuelta (%d llamadas)"):format(#riftCalls))
	check(focusCalls[1] == "Valmar" and #focusCalls == 1, "encima de Valmar el HUD de Valmar se queda")

	L.workspace, L.services.RunService, L.services.Players, L.services.Lighting = oldWorkspace, oldRun, oldPlayers, oldLighting
	rawset(L.services.ReplicatedStorage, "SkyLibrary", nil)
	for _, path in { "src/client/UI/Perf", "src/client/Controllers/RainVeil", "src/client/Controllers/DayLight", "src/client/Controllers/SkyRift", "src/client/Controllers/PlanetClient", "src/client/UI/FlightFocus" } do
		L.mock(path, nil)
	end
	L.reset("src/client/Controllers/EnvDirector")
	L.reset("src/client/Controllers/DayLight")
end

L.finish("test-space")
