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
	check(table.concat(names, ",") == "Lontana,Ocrea,Marena,Velaria,Fronda,Zéfira,Mercadia", "los 7 planetas de la Saga 2, en su orden")
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
	local p = Planets.ById.Marena
	check(Planets.aimed(p.Dir) == p and Planets.aimed(Vector3.new(0, -1, 0)) == nil, "apuntar con el morro a una estrella la elige")
	local lo, hi = 1, 0
	for t = 0, 10, 0.05 do
		local b = Planets.brightness(p, t)
		lo, hi = math.min(lo, b), math.max(hi, b)
	end
	check(lo >= 0 and hi <= 1 and hi - lo > 0.15, "titila (el brillo sube y baja)")
	check(Planets.rayAngle(Planets.ById.Zefira, 1) ~= Planets.rayAngle(Planets.ById.Zefira, 0) and Planets.rayAngle(Planets.ById.Lontana, 1) == Planets.rayAngle(Planets.ById.Lontana, 0), "unos rayos giran y otros no")
	check(Planets.status("Lontana", { SagaDone = false }) == "Locked", "sin la Saga 1: cerrado")
	check(Planets.status("Lontana", { SagaDone = true }) == "Soon" and string.find(Planets.message("Lontana", "Soon"), "próximamente", 1, true) ~= nil, "sin episodio: «Planeta Lontana — próximamente»")
	Planets.setDestination("Ocrea", { Travel = function() end })
	local st, need = Planets.status("Ocrea", { SagaDone = true, Done = {} })
	check(st == "Order" and need == "Lontana", "con episodio pero sin Lontana: antes Lontana")
	check(Planets.status("Ocrea", { SagaDone = true, Done = { Lontana = 1 } }) == "Ready", "con Lontana terminada: listo para viajar")
	check(Planets.status("Ocrea", { Tester = true, Done = {} }) == "Ready", "los testers se saltan el orden")
	Planets.setDestination("Mercadia", { Travel = function() end })
	check(select(2, Planets.status("Mercadia", { SagaDone = true, Done = { Lontana = 1 } })) == "Mercadia", "Mercadia, la última (tras los otros seis)")
	Planets.setDestination("Ocrea", nil)
	Planets.setDestination("Mercadia", nil)
	Planets.setDestination("Pluton", { Travel = function() end })
	check(Planets.destination("Pluton") == nil, "el registro solo acepta los 7 planetas")
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
	check(Space.planet(player, "Lontana") == "Soon" and Space.planet(player, "Nada") == nil, "tocar Lontana: próximamente; un planeta inventado: nada")
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

L.finish("test-space")
