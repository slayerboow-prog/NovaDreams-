-- Comprueba las reglas del nivel de búsqueda (src/shared/Wanted.luau).
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-wanted.luau

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local Wanted = luau.load(fs.readFile("src/shared/Wanted.luau"), { debugName = "Wanted" })()

local failures = 0
local function check(condition: any, message: string)
	if condition then
		print("  ✅ " .. message)
	else
		failures += 1
		print("  ❌ " .. message)
	end
end

print("▶ Estrellas por delito")
check(Wanted.starsAfter(0, "Agresion") == 1, "Pegar a alguien: 1 estrella")
check(Wanted.starsAfter(0, "Atraco") == 2, "Atracar una tienda: 2 estrellas")
check(Wanted.starsAfter(1, "Robo") == 2, "Los delitos se van sumando")
check(Wanted.starsAfter(4, "AgresionPolicia") == 5, "Nunca más de 5 estrellas")
check(Wanted.starsAfter(5, "Atraco") == 5, "Con 5 se queda en 5")
check(Wanted.starsAfter(2, "NoExiste") == 2, "Algo que no es delito no suma")

print("▶ Patrullas")
check(Wanted.response(1).Cars == 1 and Wanted.response(1).Helis == 0, "1★: un coche patrulla")
check(Wanted.response(3).Cars == 3 and Wanted.response(3).Helis == 0, "3★: tres coches, sin helicóptero")
check(Wanted.response(4).Helis == 1, "4★: llega el helicóptero")
check(Wanted.response(5).Cars == 4 and Wanted.response(5).Helis == 2, "5★: cuatro coches y dos helicópteros")
local growing = true
for s = 2, 5 do
	local a, b = Wanted.response(s - 1), Wanted.response(s)
	if b.Cars + b.Helis * 2 < a.Cars + a.Helis * 2 then
		growing = false
	end
end
check(growing, "Cuantas más estrellas, más policía")
check(Wanted.OfficerSpeed[1] < 16 * 1.5, "Corriendo se puede escapar de un agente a pie")

print("▶ Huida y detención")
check(Wanted.evadeSeconds(0) == 0, "Sin estrellas no hay que despistar a nadie")
check(Wanted.evadeSeconds(5) > Wanted.evadeSeconds(1), "Con más estrellas cuesta más despistarles")
check(Wanted.fine(3) == 3 * Wanted.Fine, "La multa depende de las estrellas")

print("▶ Robar a alguien")
check(Wanted.stealAmount(0) == 0, "A quien no lleva dinero no se le quita nada")
check(Wanted.stealAmount(3) == 3, "Nunca más de lo que lleva")
check(Wanted.stealAmount(100) == 15, "Se lleva una parte (15%)")
check(Wanted.stealAmount(100000) == Wanted.StealMax, "Con un máximo por robo")

print("▶ Conducir sin carnet (solo si te ve la policía)")
check(Wanted.starsAfter(0, "SinCarnet") == 1 and Wanted.starsAfter(0, "MenorVolante") == 1, "conducir sin carnet o siendo menor: 1 estrella")
check(Wanted.starsAfter(Wanted.starsAfter(0, "SinCarnet"), "Huida") == 2, "si no paras ante el «¡Alto!»: 2 estrellas")
check(Wanted.appliesTo("MenorVolante", false) and Wanted.appliesTo("Huida", false), "un niño al volante también cuenta (la policía le para)")
check(not Wanted.appliesTo("Agresion", false) and Wanted.appliesTo("Agresion", true), "los demás delitos siguen siendo solo desde adolescente")
check(Wanted.DriveSight >= 60 and Wanted.DriveSight <= 80 and Wanted.DriveSight < Wanted.PoliceSight, "una patrulla ve quién conduce a 60-80 studs")
check(Wanted.StopSeconds > 0 and Wanted.StopSpeed > 0, "tras el «¡Alto!» hay un momento para parar")
check(Wanted.Patrols.Max >= 1 and Wanted.Patrols.Spawn[1] > Wanted.DriveSight, "las patrullas de ronda no aparecen delante de tus narices")

local roblox = require("@lune/roblox")
local env = setmetatable({ Vector3 = roblox.Vector3 }, { __index = _G })
local Gameplay = luau.load(fs.readFile("src/shared/Gameplay.luau"), { debugName = "Gameplay", environment = env })()
check(Gameplay.drivingOffence("Adulto", false, "Coche") == "SinCarnet", "adulto sin carnet de coche: «Conducir sin carnet»")
check(Gameplay.drivingOffence("Adulto", true, "Coche") == nil, "con carnet, nada")
check(Gameplay.drivingOffence("Adolescente", false, "Moto") == "MenorVolante" and Gameplay.drivingOffence("Nino", false, "Coche") == "MenorVolante", "un menor con moto o coche: «Menor al volante»")
check(Gameplay.drivingOffence("Nino", false, "Bici") == nil and Gameplay.drivingOffence("Adulto", false, "Patinete") == nil, "bici, patinete y monopatín no piden carnet")
check(Gameplay.DriveMinStage == "Nino", "se conduce desde niño (los bebés no)")

print("▶ Historial de comportamiento (😇 / 😈)")
local Conduct = luau.load(fs.readFile("src/shared/Conduct.luau"), { debugName = "Conduct" })()
check(Conduct.level(0).Icon == "😇" and Conduct.level(30).Icon == "🚨", "de angelito a oveja negra")
local rising = true
for p = 1, 40 do
	if Conduct.level(p).Min < Conduct.level(p - 1).Min then
		rising = false
	end
end
check(rising, "cuantos más puntos, peor nivel")
check(Conduct.pointsOf("Homicidio") > Conduct.pointsOf("SinCarnet") and Conduct.pointsOf("Inventado") == Conduct.DefaultPoints, "lo grave suma más")
check(Conduct.isMinor("Nino") and Conduct.isMinor("Adolescente") and not Conduct.isMinor("AdultoJoven"), "menores: niños y adolescentes")
check(Conduct.groundedAfter(0) == Conduct.Family.GroundedMinutes and Conduct.groundedAfter(1000) == Conduct.Family.GroundedMax, "el castigo se suma, con un máximo")
check(Conduct.curfew(22) and Conduct.curfew(3) and not Conduct.curfew(12), "castigado: a casa de noche")
check(Conduct.calmed(5, 2) == 3 and Conduct.calmed(1, 9) == 0, "portarse bien borra puntos (sin bajar de 0)")
check(Conduct.Family.Rel < 0 and Conduct.Family.RelArrest < 0 and Conduct.Family.Allowance.Nino > 0, "la familia se enfada y la paga existe")

print("▶ Rondas de las patrullas por las calles")
local Routes = luau.load(fs.readFile("src/server/World/PatrolRoutes.luau"), { debugName = "PatrolRoutes", environment = env })()
local V = roblox.Vector3.new
-- Un cruce en T: 1 (0,0)-(100,0), 2 (100,0)-(200,0), 3 (100,0)-(100,100) y un callejón 4 (200,0)-(200,50)
local segs = {
	{ A = V(0, 0, 0), B = V(100, 0, 0) },
	{ A = V(100, 0, 0), B = V(200, 0, 0) },
	{ A = V(100, 0, 0), B = V(100, 0, 100) },
	{ A = V(200, 0, 0), B = V(200, 0, 50) },
}
local graph = Routes.graph(segs)
local nextIndex, from = Routes.next(graph, 1, "B", function()
	return 1
end)
check((nextIndex == 2 or nextIndex == 3) and from == "A", "al final de la calle sigue por otra del cruce")
local seenOptions = {}
for pick = 1, 2 do
	local i = Routes.next(graph, 1, "B", function()
		return pick
	end)
	seenOptions[i] = true
end
check(seenOptions[2] and seenOptions[3] and not seenOptions[1], "no da la vuelta si hay otro camino")
local deadIndex, deadFrom = Routes.next(graph, 4, "B")
check(deadIndex == 4 and deadFrom == "B", "en un callejón sin salida, da la vuelta")
local p0, dir = Routes.point(segs[1], "A", 0, 5)
local p1 = Routes.point(segs[1], "B", 0, 5)
check(math.abs(p0.X) < 0.01 and math.abs(p0.Z - 5) < 0.01 and dir.X > 0.99, "va por su carril (a la derecha)")
check(math.abs(p1.X - 100) < 0.01 and math.abs(p1.Z + 5) < 0.01, "en sentido contrario, por el otro carril")
check(math.abs(Routes.length(segs[3]) - 100) < 0.01, "largo de un tramo")

print("▶ Las patrullas miran hacia donde van (también tras dar la vuelta)")
-- El coche patrulla se orienta con PatrolRoutes.turnToward (PoliceUnits.stepPatrol). Antes era
-- look:Lerp(dir): en un callejón sin salida dir = -look y la mezcla nunca cambiaba de sentido,
-- así que el coche seguía mirando hacia atrás (circulaba marcha atrás) hasta el siguiente cruce.
do
	-- Simula PoliceUnits.stepPatrol: avanza por la calle, se arrima al carril poco a poco (blend) y
	-- gira con `turn`. Devuelve los segundos mirando hacia atrás (LookVector·velocidad < 0), el
	-- peor valor y cuántas medias vueltas ha dado.
	local function drive(segments, startIndex: number, seconds: number, turn): (number, number, number)
		local g = Routes.graph(segments)
		local index, fromSide, t = startIndex, "A", 0.5
		local pos, look = Routes.point(g.Segments[index], fromSide, t, 5)
		local dt, speed = 1 / 30, 24
		local backwards, worst, uTurns, streak, longest = 0, 1, 0, 0, 0
		for _ = 1, math.floor(seconds / dt) do
			t += speed * dt / Routes.length(g.Segments[index])
			if t >= 1 then
				local before = index
				local arrived = if fromSide == "A" then "B" else "A"
				index, fromSide = Routes.next(g, index, arrived, function()
					return 1
				end)
				if index == before and fromSide == arrived then
					uTurns += 1
				end
				t = Routes.entry(g.Segments[index], fromSide, pos)
			end
			local point, dir = Routes.point(g.Segments[index], fromSide, t, 5)
			local nextPos = pos:Lerp(point, math.min(1, dt * 6))
			local velocity = nextPos - pos
			pos = nextPos
			look = turn(look, dir, dt)
			if velocity.Magnitude > 0.05 then
				local dot = look:Dot(velocity.Unit)
				worst = math.min(worst, dot)
				if dot < 0 then
					backwards += dt
					streak += dt
					longest = math.max(longest, streak)
				else
					streak = 0
				end
			end
		end
		return backwards, worst, uTurns, longest
	end
	local function newTurn(look, dir, dt)
		return Routes.turnToward(look, dir, 3.5 * dt)
	end
	local function oldTurn(look, dir, dt) -- (lo de antes en PoliceUnits.stepPatrol)
		local turned = look:Lerp(dir, math.min(1, dt * 4))
		return if turned.Magnitude > 0.01 then turned.Unit else dir
	end
	-- Una calle sin salida: va y vuelve (una media vuelta en cada punta)
	local deadEnd = { { A = V(0, 0, 0), B = V(0, 0, -120) } }
	local oldBack = drive(deadEnd, 1, 20, oldTurn)
	check(oldBack > 8, ("(antes: tras la primera media vuelta iba marcha atrás: %.1f de 20 s)"):format(oldBack))
	local backwards, _, uTurns = drive(deadEnd, 1, 20, newTurn)
	check(uTurns >= 3 and backwards / uTurns < 0.7, ("en un callejón sin salida da media vuelta enseguida (%.2f s mirando atrás en cada una)"):format(backwards / math.max(uTurns, 1)))
	local turned = Routes.turnToward(V(0, 0, -1), V(0, 0, 1), 0.2)
	check(turned:Dot(V(0, 0, -1)) < 0.999 and math.abs(turned.Magnitude - 1) < 1e-3, "en media vuelta exacta empieza a girar (antes se quedaba mirando atrás)")
	local done = V(0, 0, -1)
	for _ = 1, 40 do
		done = Routes.turnToward(done, V(0, 0, 1), 0.12)
	end
	check(done:Dot(V(0, 0, 1)) > 0.999, "y acaba mirando hacia donde va")
	check(Routes.turnToward(V(1, 0, 0), V(0, 0, -1), 10):Dot(V(0, 0, -1)) > 0.999, "un giro pequeño se hace entero")
	-- Una vuelta a la manzana: cuatro calles en cuadrado
	local square = {
		{ A = V(0, 0, 0), B = V(200, 0, 0) },
		{ A = V(200, 0, 0), B = V(200, 0, 200) },
		{ A = V(200, 0, 200), B = V(0, 0, 200) },
		{ A = V(0, 0, 200), B = V(0, 0, 0) },
	}
	local _, _, _, longest = drive(square, 1, 60, newTurn)
	check(longest < 0.4, ("dando vueltas a la manzana no va marcha atrás (como mucho %.2f s seguidos mirando atrás: el giro de la esquina)"):format(longest))
	local source = fs.readFile("src/server/World/PoliceUnits.luau")
	check(source:find("PatrolRoutes.turnToward", 1, true) ~= nil and not source:find("look:Lerp(dir", 1, true), "PoliceUnits gira las patrullas con turnToward (no con Lerp)")
end


print("▶ Atropellos: ¿culpa de quien conduce? (shared/Crossing)")
local TS = luau.load(fs.readFile("src/shared/TrafficSignals.luau"), { debugName = "TrafficSignals", environment = env })()
local Crossing = luau.load(fs.readFile("src/shared/Crossing.luau"), {
	debugName = "Crossing",
	environment = setmetatable({
		Vector3 = roblox.Vector3,
		script = { Parent = { TrafficSignals = TS } },
		require = function(m)
			return m
		end,
	}, { __index = _G }),
})()
do
	local V3 = roblox.Vector3.new
	-- Un cruce con semáforo en (0, 0): calle en X (de oeste a este) y calle en Z, con aceras de 12 a 20
	local function grid(axis: string, at: number)
		local a = if axis == "X" then V3(-300, 0, at) else V3(at, 0, -300)
		local b = if axis == "X" then V3(300, 0, at) else V3(at, 0, 300)
		return { A = a, B = b, Width = 24, WalkIn = 12, WalkOut = 20, Axis = axis, At = at, From = -300, To = 300 }
	end
	local world = Crossing.world({ grid("X", 0), grid("Z", 0) })
	-- Y un cruce de dos avenidas sin semáforo en (5000, 0)
	local plain = Crossing.world({
		{ A = V3(4700, 0, 0), B = V3(5300, 0, 0), Width = 28, WalkIn = 14, WalkOut = 21, Kind = "Avenida" },
		{ A = V3(5000, 0, -300), B = V3(5000, 0, 300), Width = 28, WalkIn = 14, WalkOut = 21, Kind = "Avenida" },
	})
	local greenX = 1000 * TS.CYCLE + 5 -- X en verde (Z en rojo)
	local greenZ = 1000 * TS.CYCLE + TS.CYCLE / 2 + 5 -- Z en verde (X en rojo desde hace 7 s)
	local amberEnd = 1000 * TS.CYCLE + TS.GREEN + TS.YELLOW + 1 -- X en rojo desde hace 1 s (los dos en rojo)
	check(TS.state("X", greenX) == "Green" and TS.state("X", greenZ) == "Red" and TS.state("Z", amberEnd) == "Red", "(horas de la prueba: X en verde / Z en verde / los dos en rojo)")
	-- Sitios
	local sidewalk = V3(60, 0, 16) -- acera de la calle en X
	local zebraX = V3(-15.5, 0, 4) -- paso de cebra sobre la calle en X (lo cruza quien anda a lo largo de Z)
	local midBlock = V3(-80, 0, 3) -- calzada de la calle en X a mitad de manzana
	local box = V3(3, 0, -4) -- en medio del cruce
	local z1 = Crossing.zone(world, zebraX)
	check(Crossing.zone(world, sidewalk).Zone == "Sidewalk", "la acera es acera")
	check(z1.Zone == "Crosswalk" and z1.Signalled and z1.DriverAxis == "X" and z1.PedAxis == "Z", "el paso de cebra: lo pisan los coches en X y lo cruzan los que andan en Z, con semáforo")
	check(Crossing.zone(world, midBlock).Zone == "Road" and Crossing.zone(world, box).Zone == "Road", "a mitad de manzana o en medio del cruce es calzada (no paso de cebra)")
	check(Crossing.zone(plain, V3(4982.5, 0, 5)).Zone == "Crosswalk" and not Crossing.zone(plain, V3(4982.5, 0, 5)).Signalled, "en un cruce sin semáforo también hay paso de cebra")

	local carX = V3(1, 0, 0)
	local function judge(ped, now, speed, carPos, claim, w)
		return Crossing.judge(w or world, ped, carPos or (ped - V3(6, 0, 0)), carX * speed, now, claim)
	end
	local v = judge(V3(60, 0, 16), greenX, 30, V3(60, 0, 15))
	check(v.Fault and v.Reason == "Sidewalk", "en la acera: culpa de quien conduce (aunque tenga verde)")
	v = judge(zebraX, greenZ, 30)
	check(v.Fault and v.Reason == "Walk" and v.PedWalk, "en el paso de cebra con los peatones con paso: culpa de quien conduce")
	v = judge(zebraX, greenX, 30)
	check(not v.Fault and v.Reason == "Jaywalk" and v.Signal == "Green", "el peatón cruzaba en rojo y tú con verde a velocidad normal: accidente, sin delito")
	v = judge(midBlock, greenX, 30)
	check(not v.Fault and v.Zone == "Road", "a mitad de calle con tu verde: accidente, sin delito")
	v = judge(box, greenZ, 30)
	check(v.Fault and v.Reason == "RedLight", "te saltas el rojo (rojo desde hace rato): culpa tuya aunque el peatón no fuera por el paso")
	v = judge(box, amberEnd, 30)
	check(not v.Fault and v.Reason == "Amber", "entraste con ámbar y aún salías del cruce: accidente")
	v = judge(midBlock, greenX, 75)
	check(v.Fault and v.Reason == "Speeding", "a mitad de calle pero a 75 (límite 40): temerario, culpa tuya")
	v = judge(midBlock, greenX, 55)
	check(not v.Fault, "a 55 (menos de 1,5 veces el límite) no es temerario")
	v = judge(V3(-80, 0, 3), greenX, 30, V3(-80, 0, 15))
	check(v.Fault and v.Reason == "Sidewalk", "con el coche subido a la acera: culpa tuya")
	v = Crossing.judge(plain, V3(4982.5, 0, 5), V3(4976, 0, 5), V3(30, 0, 0), greenX, nil)
	check(v.Fault and v.Reason == "Zebra", "en un paso de cebra sin semáforo el peatón tiene preferencia: culpa tuya")
	-- Lo que dice el cliente no manda: el servidor recalcula el semáforo con su hora
	v = judge(zebraX, greenZ, 30, nil, { Ped = "Jaywalk", Signal = "Green", At = greenZ })
	check(v.Fault and v.Rejected and v.Signal == "Red", "si el cliente dice «cruzaba mal y yo en verde» pero el servidor ve paso para los peatones: rechazado y culpa tuya")
	v = judge(zebraX, greenX, 30, nil, { Ped = "Jaywalk", Signal = "Green", At = greenX })
	check(not v.Fault and not v.Rejected, "si cuadra con lo que ve el servidor: accidente")
	v = judge(zebraX, greenZ, 30, nil, { Ped = "Jaywalk", Signal = "Green", At = greenZ - 30 })
	check(v.Fault and v.At == greenZ, "la hora del golpe que dice el cliente solo vale si es de hace un momento (no se puede elegir otra fase)")
	v = judge(zebraX, greenX + 0.3, 30, nil, { At = greenX })
	check(v.At == greenX, "(un poco de retraso de la red sí se acepta)")

	-- Personajes del servidor que andan (World/RoadGuard → Crossing.mustWait): por el paso de cebra
	-- sobre la calle en X (andando a lo largo de Z) y a mitad de manzana
	local from, to = V3(-15.5, 0, -16), V3(-15.5, 0, 16)
	local leg = Crossing.legAcross(world, from, to)
	check(leg ~= nil and math.abs(leg.Entry.Z + 12) <= 2.5 and math.abs(leg.Exit.Z - 12) <= 2.5, "un tramo que cruza la calzada: dónde entra y dónde sale")
	check(Crossing.legAcross(world, V3(60, 0, 16), V3(120, 0, 16)) == nil, "un tramo por la acera no cruza nada")
	check(Crossing.mustWait(world, from, to, 6, greenX, {}), "con el verde de los coches que pasan por ahí, el personaje espera en el bordillo")
	check(not Crossing.mustWait(world, from, to, 6, greenZ, {}), "con su verde (y sin coches), cruza")
	local coming = { { Pos = V3(-150, 0, -6), Vel = V3(40, 0, 0) } }
	check(Crossing.mustWait(world, from, to, 6, greenZ, coming), "con su verde pero viene un coche que se lo salta: espera")
	local midFrom, midTo = V3(-80, 0, -16), V3(-80, 0, 16)
	check(not Crossing.mustWait(world, midFrom, midTo, 6, greenX, {}) and Crossing.mustWait(world, midFrom, midTo, 6, greenX, coming), "a mitad de calle: solo si no viene nadie")
end

-- Delitos con los servicios de verdad (scripts/lib/CrimeHarness): el modo pruebas no libra a un
-- niño de la policía, un niño normal sí se libra (solo aviso), y agredir a un agente escala.
local okRun, runError = pcall(function()
	local task = require("@lune/task")
	local H = require("./lib/CrimeHarness")
	H.boot()
	local W = H.WantedService
	local wait = H.Wanted.CallDelay + 0.6

	print("▶ Menores y modo pruebas")
	local kid = H.player("Niño", 6001, "Nino", V(0, 0, 0))
	local witness = H.npc("Testigo", V(0, 0, -10))
	local mark = #H.sent
	W.crime(kid, "Agresion")
	task.wait(wait)
	check(kid:GetAttribute("Wanted") == nil and H.dispatch[kid] == nil, "un niño normal no tiene estrellas (sin modo pruebas)")
	check(H.noticeHas(kid, "Si fueras mayor", mark), "solo el aviso «Si fueras mayor, vendría la policía»")
	local owner = H.player("Dueño", H.CREATOR, "Nino", V(500, 0, 0))
	H.npc("Testigo2", V(500, 0, -10))
	mark = #H.sent
	W.crime(owner, "Agresion")
	task.wait(wait)
	check(owner:GetAttribute("Wanted") == 1 and H.dispatch[owner] == 1, "un niño tester con «Sin requisitos»: 1 estrella y una patrulla")
	check(not H.noticeHas(owner, "Si fueras mayor", mark) and H.noticeHas(owner, "Modo pruebas", mark), "con el aviso del modo pruebas, no el de «Si fueras mayor»")
	mark = #H.sent
	W.crime(owner, "Agresion")
	task.wait(wait)
	check(#H.notices(owner, mark) == 0 or not H.noticeHas(owner, "Modo pruebas", mark), "el aviso del modo pruebas sale una sola vez")
	W.clear(owner)
	check(owner:GetAttribute("Wanted") == nil and H.dispatch[owner] == nil, "quitar la búsqueda retira las patrullas")
	H.profiles[owner].Tester = { Bypass = false }
	W.crime(owner, "Agresion")
	task.wait(wait)
	check(owner:GetAttribute("Wanted") == nil, "con «Sin requisitos» apagado vuelve a ser un niño para la policía")
	H.profiles[owner].Tester.Bypass = true
	check(witness.Parent ~= nil, "(el testigo sigue ahí)")

	print("▶ Al volante: el modo pruebas no le para por la edad ni por el carnet")
	-- (VehicleService es un doble: dice qué conduce cada uno y qué delito de «requisitos» sería;
	-- la patrulla de ronda le ve siempre. VehicleService.offenceFor de verdad: test-tester)
	local Vehicles = H.mocks["src/server/Services/VehicleService"]
	local PoliceMock = H.mocks["src/server/World/PoliceUnits"]
	local driving: { [any]: string } = {}
	local pulled: { [any]: number } = {}
	Vehicles.ridingKind = function(p)
		return driving[p]
	end
	Vehicles.drivingOffence = function(p)
		return if driving[p] then "MenorVolante" else nil
	end
	Vehicles.rideSpeed = function()
		return 30
	end
	PoliceMock.seesDriver = function()
		return true, nil
	end
	PoliceMock.pullOver = function(p)
		pulled[p] = (pulled[p] or 0) + 1
	end
	W.clear(owner)
	driving[owner] = "Coche"
	mark = #H.sent
	W.checkDrivers()
	task.wait(0.1)
	check(owner:GetAttribute("Wanted") == nil and H.dispatch[owner] == nil and pulled[owner] == nil, "un niño tester con «Sin requisitos» conduce: ni estrellas, ni patrulla, ni «¡Alto!»")
	check(not H.noticeHas(owner, "¡Alto!", mark) and not H.noticeHas(owner, "Eres menor", mark), "y ningún aviso")
	H.profiles[owner].Tester.Bypass = false
	mark = #H.sent
	W.checkDrivers()
	task.wait(0.1)
	check(owner:GetAttribute("Wanted") == H.Wanted.Crimes.MenorVolante.Stars and pulled[owner] == 1, "con «Sin requisitos» apagado: reglas normales (la patrulla le para, 1 estrella)")
	check(H.noticeHas(owner, "¡Alto!", mark), "con su «¡Alto! ¡Policía!»")
	H.profiles[owner].Tester.Bypass = true
	W.checkDrivers()
	task.wait(0.1)
	check(owner:GetAttribute("Wanted") == nil and H.dispatch[owner] == nil, "al volver a encenderlo, la búsqueda solo por conducir se le quita")
	-- Un delito de verdad (agresión) sigue contando aunque vaya al volante con «Sin requisitos»
	H.npc("Testigo3", V(500, 0, -8))
	W.crime(owner, "Agresion")
	task.wait(wait)
	W.checkDrivers()
	task.wait(0.1)
	check(owner:GetAttribute("Wanted") == H.Wanted.Crimes.Agresion.Stars, "los delitos de verdad (pegar, disparar, robar) le siguen buscando como a un adulto")
	W.clear(owner)
	local kid2 = H.player("Niño2", 6010, "Nino", V(3000, 0, 0))
	driving[kid2] = "Coche"
	W.checkDrivers()
	task.wait(0.1)
	check(kid2:GetAttribute("Wanted") == H.Wanted.Crimes.MenorVolante.Stars and pulled[kid2] == 1, "un niño normal al volante: la patrulla le para (Menor al volante)")
	driving = {}
	Vehicles.ridingKind = function()
		return nil
	end
	Vehicles.drivingOffence = function()
		return nil
	end

	print("▶ Agredir a un agente de policía")
	local adult = H.player("Adulto", 6002, "Adulto", V(1000, 0, 0))
	local officer = H.officer(V(1000, 0, -5))
	local result = H.CombatService.applyHit(adult, officer, { Amount = 25, Direction = V(0, 0, -1), Weapon = "Pistola" })
	task.wait(0.1)
	check(result.Hit and officer:GetAttribute("Hp") == 15, "el agente recibe el daño")
	check(adult:GetAttribute("Wanted") == H.Wanted.Crimes.AgresionPolicia.Stars, "al momento: estrellas por agredir a un agente (sin esperar testigos)")
	check(H.dispatch[adult] == adult:GetAttribute("Wanted"), "y salen las patrullas de esas estrellas")
	H.CombatService.applyHit(adult, officer, { Amount = 25, Direction = V(0, 0, -1), Weapon = "Pistola" })
	task.wait(0.1)
	check(adult:GetAttribute("Wanted") == 2 * H.Wanted.Crimes.AgresionPolicia.Stars, "otro disparo al agente: la búsqueda escala")
	check(officer:GetAttribute("Down") == true, "el agente cae al quedarse sin vida")

	print("▶ Disparar a un personaje de la calle (sin jugador de por medio)")
	local shooter = H.player("Tirador", 6003, "Adulto", V(1500, 0, 0))
	local passer = H.npc("Paseante", V(1500, 0, -80)) -- (lejos: ningún otro testigo cerca)
	H.CombatService.applyHit(shooter, passer, { Amount = 30, Direction = V(0, 0, -1), Weapon = "Fusil" })
	task.wait(wait)
	check(shooter:GetAttribute("Wanted") == H.Wanted.Crimes.Disparo.Stars, "la víctima llama aunque esté lejos: «Disparar a una persona»")
	local toy = H.player("Juguete", 6004, "Adulto", V(2000, 0, 0))
	local wet = H.npc("Mojado", V(2000, 0, -10))
	H.CombatService.applyHit(toy, wet, { Amount = 0, Direction = V(0, 0, -1), Weapon = "PistolaAgua", Toy = true })
	task.wait(wait)
	check(toy:GetAttribute("Wanted") == nil, "una pistola de agua no es delito")
end)
check(okRun, "las pruebas con los servicios terminan sin errores" .. (if okRun then "" else ": " .. tostring(runError)))

-- Atropellos con los servicios de verdad (KnockService → RoadGuard/Crossing → WantedService con
-- PoliceOnly): solo hay estrellas si es culpa tuya Y lo ve la policía en ese momento.
local okRun2, runError2 = pcall(function()
	local task = require("@lune/task")
	local H = require("./lib/CrimeHarness")
	local W = H.WantedService
	local V3 = roblox.Vector3.new
	local PoliceMock = H.mocks["src/server/World/PoliceUnits"]
	PoliceMock.seesDriver = function()
		return H.policeWatching, nil
	end
	-- Las calles publicadas (ReplicatedStorage.Ambient.Roads): un cruce con semáforo en (0, 0)
	local ambient = H.inst("Folder", "Ambient")
	local roadsFolder = H.inst("Folder", "Roads", ambient)
	for i, axis in { "X", "Z" } do
		local config = H.inst("Configuration", "Road" .. i, roadsFolder)
		local a = if axis == "X" then V3(-300, 0, 0) else V3(0, 0, -300)
		local b = if axis == "X" then V3(300, 0, 0) else V3(0, 0, 300)
		for k, value in { A = a, B = b, Width = 24, WalkIn = 12, WalkOut = 20, Axis = axis, At = 0, From = -300, To = 300 } do
			config:SetAttribute(k, value)
		end
	end
	H.replicatedStorage.Ambient = ambient -- (el ReplicatedStorage del arnés es una tabla: se le cuelga la carpeta)
	H.load("src/server/World/RoadGuard").reset()
	-- El coche de cada conductor según el servidor (VehicleService/CrashService de mentira)
	local cars: { [any]: { Pos: Vector3, Vel: Vector3 } } = {}
	local Vehicles = H.mocks["src/server/Services/VehicleService"]
	local current: any = nil
	Vehicles.rideModel = function(p)
		current = cars[p]
		return if current then H.inst("Model", "Coche") else nil
	end
	H.mocks["src/server/Services/CrashService"] = {
		bodyOf = function()
			return { Pos = current.Pos, Vel = current.Vel, Kind = "Coche", Length = 13, Width = 6, Mass = 1300 }
		end,
		maxSpeed = function()
			return 72
		end,
		kindOf = function()
			return "Coche"
		end,
	}
	local Knock = H.load("src/server/Services/KnockService")
	Knock.init()
	local remote = H.remotes.Knock
	local TS = H.load("src/shared/TrafficSignals")
	local clock = 2000 * TS.CYCLE
	H.workspace.GetServerTimeNow = function()
		return clock
	end
	local greenX = 2000 * TS.CYCLE + 5
	local greenZ = 2000 * TS.CYCLE + TS.CYCLE / 2 + 5
	local wait = H.Wanted.CallDelay + 2.5
	local zebraX = V3(-15.5, 0, 4)
	local userId = 7000
	local function driver(name: string, at: Vector3, vel: Vector3)
		userId += 1
		local p = H.player(name, userId, "Adulto", at + V3(0, 2, 0))
		cars[p] = { Pos = at, Vel = vel }
		return p
	end
	local function runOver(p, ped: Vector3, now: number, claim: { [string]: any }?)
		clock = now
		local info = { Pos = ped, Vel = cars[p].Vel }
		for k, value in claim or {} do
			info[k] = value
		end
		remote.OnServerEvent:Fire(p, "Ped", nil, info)
	end

	print("▶ Atropellar (KnockService): solo si es culpa tuya y lo ve la policía")
	H.policeWatching = true
	local d1 = driver("Conductor1", zebraX - V3(5, 0, 0), V3(30, 0, 0))
	runOver(d1, zebraX, greenZ, { Ped = "OnCrosswalk", Signal = "Red", At = greenZ })
	task.wait(0.1)
	check(d1:GetAttribute("Wanted") == H.Wanted.Crimes.Atropello.Stars, "culpa tuya (paso de cebra con los peatones con paso) y con la policía delante: 3 estrellas")

	H.policeWatching = false
	local d2 = driver("Conductor2", zebraX - V3(5, 0, 0), V3(30, 0, 0))
	local watcher = H.npc("Mirón", zebraX + V3(0, 0, 8)) -- (un personaje al lado: antes llamaba él)
	local mark = #H.sent
	runOver(d2, zebraX, greenZ, { Ped = "OnCrosswalk", Signal = "Red", At = greenZ })
	task.wait(wait)
	check(d2:GetAttribute("Wanted") == nil and H.dispatch[d2] == nil, "culpa tuya pero sin policía que lo vea: ni estrellas ni patrullas (tampoco al rato)")
	check(not H.saidAny(watcher, "Policía") and #H.notices(d2, mark) == 0, "nadie llama a la policía (ni testigos ni transeúntes)")

	local cop = H.player("Agente1", 7900, "Adulto", zebraX + V3(0, 0, 40))
	cop:SetAttribute("Job", "Policia")
	local d3 = driver("Conductor3", zebraX - V3(5, 0, 0), V3(30, 0, 0))
	local raycast = H.workspace.Raycast
	H.workspace.Raycast = function(_, origin)
		return { Instance = H.inst("Part", "Pared"), Position = origin, Normal = V3(0, 1, 0), Distance = 1 }
	end
	runOver(d3, zebraX, greenZ)
	task.wait(wait)
	check(d3:GetAttribute("Wanted") == nil, "un policía de servicio cerca pero con una pared en medio: no lo ve, sin estrellas")
	H.workspace.Raycast = raycast
	local d4 = driver("Conductor4", zebraX - V3(5, 0, 0), V3(30, 0, 0))
	runOver(d4, zebraX, greenZ)
	task.wait(0.1)
	check(d4:GetAttribute("Wanted") == H.Wanted.Crimes.Atropello.Stars, "el mismo policía sin nada en medio: lo ve, 3 estrellas")
	cop:SetAttribute("Job", nil)

	print("▶ Atropellar: accidente si el peatón cruzaba sin paso")
	H.policeWatching = true
	local d5 = driver("Conductor5", zebraX - V3(5, 0, 0), V3(30, 0, 0))
	mark = #H.sent
	runOver(d5, zebraX, greenX, { Ped = "Jaywalk", Signal = "Green", At = greenX })
	task.wait(0.1)
	check(d5:GetAttribute("Wanted") == nil, "el peatón cruzaba en rojo y tú con verde: sin estrellas aunque la policía lo vea")
	check(H.noticeHas(d5, "accidente", mark), "con el aviso «Ha sido un accidente»")
	local d6 = driver("Conductor6", zebraX - V3(5, 0, 0), V3(30, 0, 0))
	runOver(d6, zebraX, greenZ, { Ped = "Jaywalk", Signal = "Green", At = greenZ })
	task.wait(0.1)
	check(Knock._lastVerdict and Knock._lastVerdict.Rejected and d6:GetAttribute("Wanted") == H.Wanted.Crimes.Atropello.Stars, "si el cliente dice «cruzaba en rojo» pero el servidor ve que tenía paso: no se le cree (3 estrellas)")
	local d7 = driver("Conductor7", V3(-80, 0, 3) - V3(5, 0, 0), V3(70, 0, 0))
	runOver(d7, V3(-80, 0, 3), greenX, { Ped = "Jaywalk", Signal = "Green" })
	task.wait(0.1)
	check(d7:GetAttribute("Wanted") == H.Wanted.Crimes.Atropello.Stars, "a mitad de calle pero a 70 (temerario): culpa tuya")

	print("▶ Atropellar a un personaje del servidor o a otro jugador: la misma regla")
	local d8 = driver("Conductor8", zebraX - V3(5, 0, 0), V3(30, 0, 0))
	local npcVictim = H.npc("Peatón", zebraX + V3(0, 3, 0))
	clock = greenX
	Knock.person(d8, npcVictim, V3(30, 0, 0), 1300, { Pos = zebraX - V3(5, 0, 0), Vel = V3(30, 0, 0) })
	task.wait(0.1)
	check(d8:GetAttribute("Wanted") == nil, "un personaje que cruza en rojo con tu verde: accidente")
	clock = greenZ
	local npc2 = H.npc("Peatón2", zebraX + V3(0, 3, 0))
	Knock.person(d8, npc2, V3(30, 0, 0), 1300, { Pos = zebraX - V3(5, 0, 0), Vel = V3(30, 0, 0) })
	task.wait(0.1)
	check(d8:GetAttribute("Wanted") == H.Wanted.Crimes.Atropello.Stars, "un personaje en el paso con su verde y la policía delante: 3 estrellas")
	local d9 = driver("Conductor9", zebraX - V3(5, 0, 0), V3(30, 0, 0))
	local walker = H.player("Andarín", 7950, "Adulto", zebraX + V3(0, 3, 0))
	clock = greenX
	Knock.person(d9, walker.Character, V3(30, 0, 0), 1300, { Pos = zebraX - V3(5, 0, 0), Vel = V3(30, 0, 0) })
	task.wait(wait)
	check(d9:GetAttribute("Wanted") == nil, "otro jugador cruzando en rojo con tu verde: ni atropello ni «agresión» (el golpe del coche no es una pelea)")
	H.policeWatching = false
end)
check(okRun2, "las pruebas de atropellos terminan sin errores" .. (if okRun2 then "" else ": " .. tostring(runError2)))

print()
if failures == 0 then
	print("✅ Todo correcto")
	process.exit(0)
else
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
