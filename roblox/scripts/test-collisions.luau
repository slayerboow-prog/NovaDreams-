-- Prueba de los choques entre vehículos (shared/Crash) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-collisions.luau
--
-- Simula choques fotograma a fotograma (como Driving.luau: cada uno con su velocidad, su giro y la
-- separación del choque) y comprueba que:
--   * de frente y con la misma masa, los dos se paran y rebotan igual (simétrico, sin salir volando)
--   * el pesado empuja más al ligero (autobús contra coche, coche contra bici)
--   * un golpe de lado, descentrado, hace girar; por detrás empuja hacia delante
--   * después del golpe no quedan metidos el uno en el otro (ni se atraviesan a mucha velocidad)
--   * topes: ningún cambio de velocidad pasa de MaxDeltaV ni ningún giro de MaxSpin
--   * el servidor rechaza avisos falsos (lejos, velocidad imposible, barcos, a sí mismo, spam)
--   * quien va en moto (o bici) se cae con un golpe fuerte, y no con un roce
--   * los barcos no chocan con esto (tienen su propia regla en el agua)
--   * Driving, Traffic, Collisions y CrashService usan lo que toca (lectura del código)

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Vector3 = roblox.Vector3

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local env = setmetatable({ Vector3 = Vector3 }, { __index = getfenv(1) })
local Crash = luau.load(fs.readFile("src/shared/Crash.luau"), { debugName = "Crash", environment = env })()

local V = Vector3.new
local function near(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) <= (eps or 1e-3)
end

-- Simulación sencilla de dos cuerpos: se mueven, se giran y chocan (como Driving + Collisions)
local function simulate(a, b, seconds: number)
	local dt = 1 / 60
	local maxOverlap, hits = 0, 0
	local results = {}
	for _ = 1, math.floor(seconds / dt) do
		for _, body in { a, b } do
			body.Pos += body.Vel * dt
			local yaw = body.Spin * dt
			local d = body.Dir
			local c, s = math.cos(yaw), math.sin(yaw)
			-- girar alrededor de +Y (como CFrame.Angles(0, yaw, 0))
			body.Dir = V(d.X * c + d.Z * s, 0, -d.X * s + d.Z * c).Unit
		end
		local contact = Crash.contact(a, b)
		if contact then
			local r = Crash.resolve(a, b, contact)
			if r.Impulse > 0 then
				hits += 1
				table.insert(results, r)
			end
			a.Vel, b.Vel, a.Spin, b.Spin = r.VelA, r.VelB, r.SpinA, r.SpinB
			a.Pos += r.MoveA
			b.Pos += r.MoveB
			local after = Crash.contact(a, b)
			if after then
				maxOverlap = math.max(maxOverlap, after.Depth)
			end
		end
	end
	return hits, maxOverlap, results
end

print("De frente, misma masa")
do
	local a = Crash.body(V(0, 0, 0), V(0, 0, -1), 13.5, 6.2, V(0, 0, -30), 0, "Coche")
	local b = Crash.body(V(0, 0, -30), V(0, 0, 1), 13.5, 6.2, V(0, 0, 30), 0, "Coche")
	local hits, overlap, results = simulate(a, b, 1)
	local r = results[1]
	check(hits >= 1, "chocan")
	check(r and r.Type == "Frontal", "se ve que es de frente (" .. tostring(r and r.Type) .. ")")
	check(near(a.Vel.Z, -b.Vel.Z, 1e-3) and near(a.Vel.X, -b.Vel.X, 1e-3), ("rebotan igual, simétrico (%.2f / %.2f)"):format(a.Vel.Z, b.Vel.Z))
	check(a.Vel.Z > 0 and a.Vel.Z < 12, ("se paran y rebotan un poco (%.2f studs/s)"):format(a.Vel.Z))
	check(math.abs(a.Spin) < 1e-3 and math.abs(b.Spin) < 1e-3, "de frente y centrado: sin girar")
	check(overlap <= 1e-3, ("no quedan metidos (%.4f)"):format(overlap))
	check(a.Pos.Z > b.Pos.Z + 13.4, "no se atraviesan")
end

print("Pesado contra ligero")
do
	local bus = Crash.body(V(0, 0, 0), V(0, 0, -1), 34, 8.6, V(0, 0, -20), 0, "Autobus")
	local car = Crash.body(V(0, 0, -25), V(0, 0, -1), 13.5, 6.2, V(0, 0, 0), 0, "Coche")
	simulate(bus, car, 1)
	check(car.Vel.Z < -20, ("el coche parado sale empujado hacia delante (%.1f)"):format(car.Vel.Z))
	check(bus.Vel.Z < -15, ("el autobús casi no lo nota (%.1f)"):format(bus.Vel.Z))
	local carA = Crash.body(V(0, 0, 0), V(0, 0, -1), 13.5, 6.2, V(0, 0, -25), 0, "Coche")
	local bike = Crash.body(V(0, 0, -10), V(0, 0, 1), 4.8, 1.2, V(0, 0, 10), 0, "Bici")
	local _, _, res = simulate(carA, bike, 0.5)
	local r = res[1]
	check(r ~= nil, "coche contra bici: chocan")
	if r then
		local dvCar = (r.VelA - V(0, 0, -25)).Magnitude
		local dvBike = (r.VelB - V(0, 0, 10)).Magnitude
		check(dvBike > dvCar * 5, ("la bici se lleva el golpe (Δv bici %.1f, coche %.1f)"):format(dvBike, dvCar))
		check(Crash.thrown("Bici", dvBike), "y el ciclista se cae")
		check(not Crash.thrown("Coche", dvCar), "en coche no se cae nadie")
	end
end

print("De lado: gira")
do
	-- El coche b cruza por delante y a le da en la parte de atrás (descentrado)
	local a = Crash.body(V(0, 0, 0), V(0, 0, -1), 13.5, 6.2, V(0, 0, -28), 0, "Coche")
	local b = Crash.body(V(4.5, 0, -12), V(1, 0, 0), 13.5, 6.2, V(0, 0, 0), 0, "Coche")
	local hits, overlap, results = simulate(a, b, 0.6)
	check(hits >= 1, "chocan")
	check(results[1] and results[1].Type == "Lateral", "se ve que es de lado (" .. tostring(results[1] and results[1].Type) .. ")")
	check(math.abs(b.Spin) > 0.3, ("el golpe descentrado le hace girar (%.2f rad/s)"):format(b.Spin))
	check(b.Vel.Z < -5, ("y lo empuja hacia donde iba el otro (%.1f)"):format(b.Vel.Z))
	check(overlap <= 1e-3, ("no quedan metidos (%.4f)"):format(overlap))
	-- centrado: casi sin giro
	local c = Crash.body(V(0, 0, 0), V(0, 0, -1), 13.5, 6.2, V(0, 0, -28), 0, "Coche")
	local d = Crash.body(V(0, 0, -12), V(1, 0, 0), 13.5, 6.2, V(0, 0, 0), 0, "Coche")
	simulate(c, d, 0.6)
	check(math.abs(d.Spin) < math.abs(b.Spin) / 3, ("centrado gira mucho menos (%.2f)"):format(d.Spin))
end

print("Por detrás")
do
	local a = Crash.body(V(0, 0, 0), V(0, 0, -1), 13.5, 6.2, V(0, 0, -35), 0, "Coche")
	local b = Crash.body(V(0, 0, -16), V(0, 0, -1), 13.5, 6.2, V(0, 0, -15), 0, "Coche")
	local _, overlap, results = simulate(a, b, 0.5)
	check(results[1] and results[1].Type == "Alcance", "se ve que es por detrás (" .. tostring(results[1] and results[1].Type) .. ")")
	check(b.Vel.Z < -15 - 5 and a.Vel.Z > -35 + 5, ("el de delante sale acelerado y el de atrás frena (%.1f / %.1f)"):format(b.Vel.Z, a.Vel.Z))
	check(overlap <= 1e-3, "no quedan metidos")
end

print("Contra algo anclado (aparcado, autobús del juego)")
do
	local a = Crash.body(V(0, 0, 0), V(0, 0, -1), 13.5, 6.2, V(0, 0, -30), 0, "Coche")
	local parked = Crash.body(V(1, 0, -14), V(0, 0, -1), 13.5, 6.2, V(0, 0, 0), 0, "Coche", true)
	local _, overlap = simulate(a, parked, 0.5)
	check(parked.Vel.Magnitude == 0 and parked.Pos == V(1, 0, -14), "el anclado no se mueve")
	check(a.Vel.Z >= 0 and a.Vel.Z < 12, ("el coche rebota un poco (%.1f)"):format(a.Vel.Z))
	check(overlap <= 1e-3, "no se mete dentro")
end

print("Topes (nada sale volando)")
do
	local worst, worstSpin = 0, 0
	for _, speed in { 60, 120, 400, 5000 } do
		local a = Crash.body(V(0, 0, 0), V(0, 0, -1), 34, 8.6, V(0, 0, -speed), 0, "Autobus")
		local b = Crash.body(V(2, 0, -17.5), V(1, 0, 0), 4.2, 1.4, V(0, 0, 0), 0, "Monopatin")
		local c = Crash.contact(a, b)
		check(c ~= nil, ("a %d studs/s se tocan"):format(speed))
		if c then
			local r = Crash.resolve(a, b, c)
			worst = math.max(worst, (r.VelB - b.Vel).Magnitude, (r.VelA - a.Vel).Magnitude)
			worstSpin = math.max(worstSpin, math.abs(r.SpinA), math.abs(r.SpinB))
			check(r.MoveA.Magnitude + r.MoveB.Magnitude <= Crash.MaxCorrection + 1e-6, ("a %d studs/s la separación tiene tope"):format(speed))
		end
	end
	check(worst <= Crash.MaxDeltaV + 1e-6, ("cambio de velocidad con tope (%.1f ≤ %d)"):format(worst, Crash.MaxDeltaV))
	check(worstSpin <= Crash.MaxSpin + 1e-6, ("giro con tope (%.2f ≤ %.1f)"):format(worstSpin, Crash.MaxSpin))
	-- Nada sube: todo es plano (Y = 0)
	local a = Crash.body(V(0, 0, 0), V(0, 0, -1), 13.5, 6.2, V(0, 0, -50), 0, "Coche")
	local b = Crash.body(V(0, 0.5, -13), V(0, 0, 1), 13.5, 6.2, V(0, 0, 50), 0, "Coche")
	local r = Crash.resolve(a, b, Crash.contact(a, b) :: any)
	check(r.VelA.Y == 0 and r.VelB.Y == 0 and r.MoveA.Y == 0 and r.MoveB.Y == 0, "nunca empuja hacia arriba")
	-- Un puente: uno arriba y otro abajo no chocan
	local low = Crash.body(V(0, 0, 0), V(0, 0, -1), 13.5, 6.2, V(0, 0, -30), 0, "Coche")
	local high = Crash.body(V(0, 20, -5), V(0, 0, 1), 13.5, 6.2, V(0, 0, 30), 0, "Coche")
	check(Crash.contact(low, high) == nil, "uno por un puente y otro por debajo: no chocan")
end

print("Se separan y el giro se apaga")
do
	local push, spin = V(10, 0, 0), 2
	for _ = 1, 120 do
		push, spin = Crash.settle(push, spin, 1 / 60)
	end
	check(push.Magnitude < 0.2 and math.abs(spin) < 0.1, ("en 2 s el empujón y el giro casi han desaparecido (%.2f, %.2f)"):format(push.Magnitude, spin))
	local speed, rest = Crash.split(V(3, 0, -20), V(0, 0, -1))
	check(near(speed, 20) and rest == V(3, 0, 0), "la velocidad se reparte en marcha y empujón de lado")
end

print("Moto: el conductor se cae")
do
	local moto = Crash.body(V(0, 0, 0), V(0, 0, -1), 5.8, 1.6, V(0, 0, -45), 0, "Moto")
	local car = Crash.body(V(0, 0, -5.8), V(1, 0, 0), 13.5, 6.2, V(0, 0, 0), 0, "Coche")
	local r = Crash.resolve(moto, car, Crash.contact(moto, car) :: any)
	check(Crash.thrown("Moto", (r.VelA - moto.Vel).Magnitude), ("a 45 studs/s contra un coche, se cae (Δv %.1f)"):format((r.VelA - moto.Vel).Magnitude))
	local slow = Crash.body(V(0, 0, 0), V(0, 0, -1), 5.8, 1.6, V(0, 0, -8), 0, "Moto")
	local r2 = Crash.resolve(slow, car, Crash.contact(slow, car) :: any)
	check(not Crash.thrown("Moto", (r2.VelA - slow.Vel).Magnitude), "un roce a 8 studs/s no le tira")
	check(Crash.FallSpeed.Bici < Crash.FallSpeed.Moto, "en bici te caes antes que en moto")
end

print("Barcos: no cuentan")
check(not Crash.collides("Lancha") and not Crash.collides("Gaviota"), "Lancha y Gaviota no chocan con esto")
check(Crash.collides("Coche") and Crash.collides("Autobus") and Crash.collides(nil), "coches, autobuses y vehículos sin tipo sí")
do
	local boat = Crash.body(V(0, 0, 0), V(0, 0, -1), 16, 6, V(0, 0, -30), 0, "Lancha")
	local car = Crash.body(V(0, 0, -10), V(0, 0, 1), 13.5, 6.2, V(0, 0, 0), 0, "Coche")
	local j = Crash.judge(boat, car, 50, 72, 30)
	check(not j.Ok and j.Reason == "barco", "el servidor no acepta choques de barcos")
end

print("Servidor: avisos falsos")
do
	local a = Crash.body(V(0, 0, 0), V(0, 0, -1), 13.5, 6.2, V(0, 0, -30), 0, "Coche")
	local b = Crash.body(V(0, 0, -14), V(0, 0, 1), 13.5, 6.2, V(0, 0, 20), 0, "Coche")
	local ok = Crash.judge(a, b, 72, 72, 30)
	check(ok.Ok and ok.Result ~= nil, "un choque de verdad se acepta")
	local far = Crash.body(V(0, 0, -300), V(0, 0, 1), 13.5, 6.2, V(0, 0, 20), 0, "Coche")
	local j1 = Crash.judge(a, far, 72, 72, 30)
	check(not j1.Ok and j1.Reason == "lejos", "con uno que está lejos: rechazado")
	local j2 = Crash.judge(a, b, 72, 72, 900)
	check(not j2.Ok and j2.Reason == "velocidad imposible", "diciendo ir a 900 studs/s: rechazado")
	local j2b = Crash.judge(a, b, 72, 72, 0 / 0)
	check(not j2b.Ok, "una velocidad NaN: rechazado")
	-- Aunque el chasis diga que va rapidísimo (lo mueve su ordenador), el servidor lo limita
	local cheat = Crash.body(V(0, 0, 0), V(0, 0, -1), 13.5, 6.2, V(0, 0, -5000), 0, "Coche")
	local j3 = Crash.judge(cheat, b, 72, 72, 70)
	check(j3.Ok and j3.Result and (j3.Result.VelB - b.Vel).Magnitude <= Crash.MaxDeltaV + 1e-6, "velocidad trucada: el empujón al otro sigue con tope")
	local closing = j3.Result and j3.Result.Closing or math.huge
	check(closing <= 72 * Crash.Server.SpeedSlack + 6 + 20 + 1e-6, ("y se calcula con la velocidad máxima de verdad (%.1f)"):format(closing))
	-- Separándose: no hay golpe
	local leaving = Crash.body(V(0, 0, -14), V(0, 0, -1), 13.5, 6.2, V(0, 0, -60), 0, "Coche")
	local j4 = Crash.judge(a, leaving, 72, 72, 30)
	check(not j4.Ok and j4.Reason == "no se acercan", "si se están separando: nada")
	-- Frecuencia
	local store, t = {}, 100
	check(Crash.rate(store, "a|b", t, 0.4) and not Crash.rate(store, "a|b", t + 0.1, 0.4) and Crash.rate(store, "a|b", t + 0.5, 0.4), "el mismo par, como mucho un golpe cada 0.4 s")
	local list, accepted = {}, 0
	for i = 1, 20 do
		if Crash.burst(list, 200 + i * 0.05, Crash.Server.Burst, Crash.Server.BurstWindow) then
			accepted += 1
		end
	end
	check(accepted == Crash.Server.Burst, ("spam de avisos: solo %d de 20 en 1 s"):format(accepted))
end

print("Daños y lo que se nota")
check(Crash.strength(2) == 0 and Crash.strength(20) > 0 and Crash.strength(200) == 1, "fuerza del golpe: 0 en un roce, 1 como mucho")
check(Crash.damageLevel(10) == 0 and Crash.damageLevel(25) == 1 and Crash.damageLevel(50) == 2, "daños: nada, abolladura, cristal rajado")

---------------------------------------------------------------------
-- Objetos y personas (shared/Knock)
---------------------------------------------------------------------
local Knock = luau.load(fs.readFile("src/shared/Knock.luau"), { debugName = "Knock", environment = env })()

print("Objetos: cuanto más rápido, más lejos")
do
	local bin = Knock.Catalog.Bin
	local last, monotonic = -1, true
	for speed = 22, 200, 6 do
		local vel, _, mode = Knock.launch(bin, V(0, 0, -speed), 1300)
		local r = Knock.range(vel)
		if mode ~= "launch" or r < last - 1e-3 then
			monotonic = false
		end
		last = r
	end
	check(monotonic, "la distancia crece con la velocidad (sin bajar nunca)")
	local slow, _, slowMode = Knock.launch(bin, V(0, 0, -10), 1300)
	local fast, _, fastMode = Knock.launch(bin, V(0, 0, -100), 1300)
	check(slowMode == "tip" and Knock.range(slow) < 1.5, ("a 10 km/h la papelera solo se vuelca (%.1f studs)"):format(Knock.range(slow)))
	check(fastMode == "launch" and Knock.range(fast) > 15, ("a 100 km/h sale volando (%.0f studs)"):format(Knock.range(fast)))
	local capped = Knock.launch(bin, V(0, 0, -5000), 12000)
	check(Vector3.new(capped.X, 0, capped.Z).Magnitude <= Knock.MaxLaunch + 1e-6 and capped.Y <= Knock.MaxLift + 1e-6, "con topes: nunca más de MaxLaunch de lado ni MaxLift hacia arriba")
	local nan = Knock.launch(bin, V(0 / 0, 0, 0), 1300)
	check(nan == Vector3.zero, "una velocidad rara (NaN) no lanza nada")
	local walk, _, walkMode = Knock.launch(bin, V(0, 0, -16), Knock.CharacterMass)
	check(walkMode == "tip" and walk.Magnitude < 10, "andando contra una papelera: se vuelca, no sale disparada")
	local cone = Knock.launch(Knock.Catalog.Cone, V(0, 0, -60), 1300)
	local bench = Knock.launch(Knock.Catalog.Bench, V(0, 0, -60), 1300)
	check(cone.Magnitude > bench.Magnitude, "un cono sale más lejos que un banco")
	local _, _, benchSlow = Knock.launch(Knock.Catalog.Bench, V(0, 0, -10), 1300)
	check(benchSlow == "none", "un banco a 10 studs/s ni se mueve (pesado)")
	local motoVel = Knock.launch({ Mass = Crash.Mass.Moto }, V(0, 0, -60), Crash.Mass.Coche)
	local motoSlow, _, motoSlowMode = Knock.launch({ Mass = Crash.Mass.Moto }, V(0, 0, -12), Crash.Mass.Coche)
	check(motoSlowMode == "tip" and Knock.range(motoVel) > Knock.range(motoSlow), "moto aparcada: despacio se cae; rápido sale volando")
	local up = Knock.launch(bin, V(0, 0, -80), 1300)
	check(up.Y > 0 and up.Z < 0, "sale hacia donde ibas y un poco hacia arriba")
end

print("Qué se puede tumbar y qué no")
do
	check(Knock.profile("Bin", "Part", { "Streets", "Town" }, V(2.6, 1.4, 1.4)) ~= nil, "papelera de la calle: sí")
	check(Knock.profile("Bin", "Part", { "Casa", "Manzana_Casas" }, V(1.4, 2.4, 1.4)) ~= nil, "cubo de basura de una casa: sí")
	check(Knock.profile("Cone", "Part", { "Obras", "Detalles" }, V(0.8, 1.6, 0.8)) ~= nil, "cono de obras: sí")
	check(Knock.profile("TerraceChair", "Part", { "Escaparate", "Edificio" }, V(1.3, 1.8, 1.3)) ~= nil, "silla de terraza: sí")
	check(Knock.profile("MotoAparcada", "Model", { "Detalles", "Streets" }, V(1.2, 3, 5)) ~= nil, "moto aparcada de adorno: sí (entera)")
	check(Knock.profile("MotoAparcada", "Part", { "Detalles" }, V(1, 1, 1)) == nil, "una pieza suelta llamada como un Model: no")
	check(Knock.profile("Bench", "Model", { "Jardin", "Manzana_Parque" }, V(6, 3.4, 2)) ~= nil, "banco del parque: sí (pesado)")
	check(Knock.profile("Bench", "Model", { "Decor", "Edificio" }, V(6, 3.4, 2)) == nil, "banco de dentro de un edificio: no")
	check(Knock.profile("Pot", "Part", { "Plant", "Mueble" }, V(2.4, 2.4, 2.4)) == nil, "maceta de un interior: no")
	check(Knock.profile("Chair", "Part", { "Edificio", "Colegio" }, V(1.8, 1.6, 1.8)) == nil, "silla del colegio: no")
	check(Knock.profile("Box", "Part", { "TrafficLight", "Streets" }, V(1.4, 3.6, 1.2)) == nil, "la caja de un semáforo: no")
	for _, name in { "Bollard", "StreetLamp", "TrafficLight", "Planter", "Hydrant", "KioskBody", "Tree", "Wall" } do
		check(Knock.profile(name, "Part", { "Streets", "Detalles" }, V(1, 1, 1)) == nil and Knock.profile(name, "Model", { "Streets", "Detalles" }, V(1, 1, 1)) == nil and Knock.isSolid(name), name .. ": sólido")
	end
	check(Knock.profile("Bin", "Part", { "Streets" }, V(40, 2, 2)) == nil, "algo enorme con nombre de papelera: no")
end

print("Personas")
do
	local graze = Knock.person(V(0, 0, -3), 1300)
	local slow = Knock.person(V(0, 0, -10), 1300)
	local mid = Knock.person(V(0, 0, -20), 1300)
	local fast = Knock.person(V(0, 0, -60), 1300)
	check(graze.Mode == "none", "un roce: nada")
	check(slow.Mode == "stumble" and slow.Damage == 0, "despacio: un traspiés, sin daño")
	check(mid.Mode == "fall" and mid.Down > 0 and mid.Damage > 0, "a 20: al suelo y se levanta")
	check(fast.Mode == "launch" and fast.Vel.Y > mid.Vel.Y and fast.Damage > mid.Damage, "a 60: por los aires (más daño)")
	local crazy = Knock.person(V(0, 0, -9000), 12000)
	check(Vector3.new(crazy.Vel.X, 0, crazy.Vel.Z).Magnitude <= 55 and crazy.Vel.Y <= 34 and crazy.Damage <= 60, "con topes (nadie sale al cielo)")
	check(Knock.person(V(0, 0, -30), Knock.CharacterMass).Mode == "stumble", "otra persona corriendo solo empuja")
	-- La animación de la caída: se va, se queda en el suelo y se levanta
	local tEnd = Knock.personTime(fast)
	local o1, lie1 = Knock.personPose(0.05, fast)
	local oMid, lieMid, doneMid = Knock.personPose(tEnd * 0.6, fast)
	local _, lieEnd, doneEnd = Knock.personPose(tEnd + 0.1, fast)
	check(o1.Y > 0 and lie1 > 0 and lie1 < 1, "sale por el aire girando")
	check(lieMid == 1 and not doneMid and oMid.Magnitude > 3, ("en el suelo, lejos de donde estaba (%.1f studs)"):format(oMid.Magnitude))
	check(lieEnd == 0 and doneEnd, "al final está de pie")
	local _, _, stumbleDone = Knock.personPose(0.7, slow)
	check(stumbleDone, "el traspiés dura poco")
end

print("Vuelven a su sitio")
do
	local home = V(0, 1, 0)
	local st = { Since = 0 }
	Knock.rest(st, 1, 10)
	check(st.RestSince == nil, "moviéndose: no está quieto")
	Knock.rest(st, 2, 0.1)
	check(st.RestSince == 2, "quieto desde que se para")
	check(not Knock.shouldRespawn(st, 10, V(20, 1, 0), home, false), "a los 8 s quieto: aún no vuelve")
	check(Knock.shouldRespawn(st, 2 + Knock.RestSeconds, V(20, 1, 0), home, false), ("a los %d s quieto: vuelve"):format(Knock.RestSeconds))
	check(not Knock.shouldRespawn(st, 2 + Knock.RestSeconds, V(20, 1, 0), home, true), "con alguien encima de su sitio: espera")
	local moving = { Since = 0 }
	check(Knock.shouldRespawn(moving, Knock.MaxLife, V(5, 1, 0), home, false), "aunque siga rodando, como mucho MaxLife fuera")
	check(Knock.shouldRespawn({ Since = 99 }, 100, V(0, -200, 0), home, false), "caído del mapa: vuelve ya")
	-- (vídeo de Valmar Centro: lo tirado se quedaba por el suelo mientras andabas cerca)
	check(Knock.RestSeconds <= 12 and Knock.MaxLife <= 30, ("vuelve pronto: %d s quieto o %d s como mucho"):format(Knock.RestSeconds, Knock.MaxLife))
	check(Knock.SpotClear <= 1.5, "solo espera si alguien está ENCIMA de su sitio (no por andar cerca)")
	check(not Knock.shouldHide({ Since = 0 }, Knock.HideAfter - 1) and Knock.shouldHide({ Since = 0 }, Knock.HideAfter), ("con su sitio ocupado, a los %d s se quita de la calle"):format(Knock.HideAfter))
	-- Lo que va encima de un objeto (las flores del cubo, la franja de la valla) va con él: si no, al
	-- salir despedido se quedaba flotando en el aire
	local CF = roblox.CFrame
	local bucket = { Name = "Bucket", CFrame = CF.new(0, 0.55, 0), Size = V(1.1, 1.1, 1.1) }
	local others = {
		{ Name = "Tapa", CFrame = CF.new(0, 1.2, 0), Size = V(1.2, 0.3, 1.2), Anchored = true }, -- encima
		{ Name = "Bouquet", CFrame = CF.new(0, 1.6, 0), Size = V(1.3, 1.1, 1.3), Anchored = true }, -- compañera: va por Companions
		{ Name = "Sidewalk", CFrame = CF.new(0, -0.5, 0), Size = V(40, 1, 8), Anchored = true }, -- el suelo
		{ Name = "Wall", CFrame = CF.new(0.9, 3, 0), Size = V(0.4, 6, 4), Anchored = true }, -- pared al lado, desde el suelo
		{ Name = "Cone", CFrame = CF.new(0, 1.5, 0), Size = V(0.8, 1.6, 0.8), Anchored = true }, -- otro objeto: va solo
		{ Name = "Lid", CFrame = CF.new(3, 1.6, 0), Size = V(1, 0.2, 1), Anchored = true }, -- lejos
	}
	local riders = Knock.riders(bucket, others)
	check(#riders == 1 and others[riders[1]].Name == "Tapa", "lo que va encima (una tapa) sale con el cubo; el suelo, la pared, otro objeto, una compañera y lo de lejos, no")
	check(Knock.Catalog.Bucket.Companions and table.find(Knock.Catalog.Bucket.Companions, "Bouquet") ~= nil, "Bucket lleva sus flores (Bouquet)")
	check(Knock.Catalog.WorksFence.Companions and table.find(Knock.Catalog.WorksFence.Companions, "WorksStripe") ~= nil, "la valla de obra lleva su franja blanca (WorksStripe)")
	-- Presupuesto
	local loose = {}
	for i = 1, Knock.Budget do
		loose["o" .. i] = { Since = 100 + i }
	end
	local ok, oldest = Knock.admit(loose)
	check(not ok and oldest == "o1", "con " .. Knock.Budget .. " sueltos: el más antiguo vuelve para dejar sitio")
	loose.o1 = nil
	check((Knock.admit(loose)), "con uno menos, cabe otro")
end

print("Servidor: golpes a objetos y personas")
do
	check((Knock.plausible(V(0, 0, 0), 7, V(0, 0, -9), 1, 30, 72)), "tu coche junto a la papelera: vale")
	local okFar, whyFar = Knock.plausible(V(0, 0, 0), 7, V(0, 0, -200), 1, 30, 72)
	check(not okFar and whyFar == "lejos", "una papelera a 200 studs: rechazado")
	local okFast, whyFast = Knock.plausible(V(0, 0, 0), 7, V(0, 0, -9), 1, 500, 72)
	check(not okFast and whyFast == "velocidad imposible", "diciendo ir a 500: rechazado")
	local okHigh = Knock.plausible(V(0, 0, 0), 7, V(0, 40, -5), 1, 30, 72)
	check(not okHigh, "algo en otro piso: rechazado")
	check(not (Knock.plausible(V(0, 0, 0), 7, V(0, 0, -9), 1, 0 / 0, 72)), "velocidad NaN: rechazado")
end

-- La ciudad de verdad (RealLifeSimulator.rbxl, solo lectura): qué encontraría KnockService
local okPlace, placeData = pcall(fs.readFile, "RealLifeSimulator.rbxl")
if okPlace then
	print("La ciudad del juego (lo que se puede tumbar)")
	local okGame, game = pcall(roblox.deserializePlace, placeData)
	local town = okGame and game.Workspace:FindFirstChild("Town")
	if town then
		local counts, solidHit = {}, {}
		for _, d in town:GetDescendants() do
			if (d:IsA("BasePart") or d:IsA("Model")) and (Knock.Catalog[d.Name] or Knock.isSolid(d.Name)) then
				local ancestors = {}
				local node = d.Parent
				for _ = 1, 5 do
					if not node or node == game.Workspace then
						break
					end
					table.insert(ancestors, node.Name)
					node = node.Parent
				end
				local size = if d:IsA("BasePart") then d.Size else nil
				if Knock.profile(d.Name, if d:IsA("Model") then "Model" else "BasePart", ancestors, size) then
					counts[d.Name] = (counts[d.Name] or 0) + 1
					if table.find(ancestors, "Mueble") then
						counts.Interior = (counts.Interior or 0) + 1
					end
					if Knock.isSolid(d.Name) then
						solidHit[d.Name] = true
					end
				end
			end
		end
		local summary = {}
		for name, n in counts do
			table.insert(summary, name .. "=" .. n)
		end
		table.sort(summary)
		print("    " .. table.concat(summary, ", "))
		check((counts.Bin or 0) >= 800, "papeleras y cubos: " .. tostring(counts.Bin))
		check((counts.Cone or 0) >= 100, "conos de obra: " .. tostring(counts.Cone))
		check((counts.MotoAparcada or 0) >= 100, "motos de adorno: " .. tostring(counts.MotoAparcada))
		check((counts.Bench or 0) >= 100, "bancos de parque: " .. tostring(counts.Bench))
		check((counts.TerraceChair or 0) >= 30 and (counts.TerraceTable or 0) >= 20, "terrazas (sillas y mesas)")
		check((counts.Interior or 0) == 0, "los muebles de los interiores no cuentan")
		check(next(solidHit) == nil, "nada estructural (farolas, semáforos, bolardos…) se puede tumbar")
	else
		check(false, "no se pudo leer la ciudad del archivo")
	end
end

---------------------------------------------------------------------
-- Controllers/Collisions de verdad (con un mundo de mentira): lo que hay AL LADO o DETRÁS no bloquea
-- el coche (un contenedor, una señal, un banco, un coche aparcado); solo lo que tiene DELANTE
---------------------------------------------------------------------
print("Lo que hay al lado no bloquea (Controllers/Collisions)")
do
	local task = require("@lune/task")
	local CFrame = roblox.CFrame
	local Knock = luau.load(fs.readFile("src/shared/Knock.luau"), { debugName = "Knock", environment = env })()
	local Gameplay = luau.load(fs.readFile("src/shared/Gameplay.luau"), { debugName = "Gameplay", environment = setmetatable({ Vector3 = Vector3, CFrame = CFrame, Color3 = roblox.Color3, Enum = roblox.Enum }, { __index = getfenv(1) }) })()
	local props: { any } = {}
	local parked: { any } = {}
	local fired: { string } = {}
	local function part(kind: string, id: number, pos: any, size: any)
		local attrs = { Knock = id, KnockKind = kind }
		return { Position = pos, Size = size, GetAttribute = function(_, k)
			return attrs[k]
		end }
	end
	local function car(pos: any, look: any)
		local cf = CFrame.new(pos + Vector3.new(0, 0.5, 0), pos + Vector3.new(0, 0.5, 0) + look)
		local chassis = { Size = Vector3.new(6.2, 1, 13.5), CFrame = cf, Anchored = true, AssemblyLinearVelocity = Vector3.zero, IsA = function(_, c)
			return c == "BasePart"
		end }
		local attrs = { Drivable = true, Kind = "Coche" }
		local m
		m = {
			Name = "Coche",
			Parent = true,
			PrimaryPart = chassis,
			IsA = function(_, c)
				return c == "Model"
			end,
			GetAttribute = function(_, k)
				return attrs[k]
			end,
			GetPivot = function()
				return chassis.CFrame
			end,
			FindFirstChild = function(_, name)
				return if name == "Chassis" then chassis else nil
			end,
		}
		return m
	end
	local stub
	stub = setmetatable({}, { __index = function()
		return stub
	end, __call = function()
		return stub
	end })
	local services = {
		Players = { LocalPlayer = { UserId = 1, Character = nil } },
		ReplicatedStorage = { Shared = { Crash = Crash, Knock = Knock, Gameplay = Gameplay }, FindFirstChild = function()
			return nil
		end },
		CollectionService = { GetTagged = function(_, tag)
			return if tag == "ParkedCar" then parked else {}
		end },
		PhysicsService = { IsCollisionGroupRegistered = function()
			return true
		end },
		RunService = stub,
	}
	local fakeWorkspace = {
		FindFirstChild = function()
			return nil
		end,
		GetPartBoundsInBox = function(_, cf, size)
			local out = {}
			for _, p in props do
				local l = cf:PointToObjectSpace(p.Position)
				if math.abs(l.X) <= size.X / 2 + p.Size.X / 2 and math.abs(l.Y) <= size.Y / 2 + p.Size.Y / 2 and math.abs(l.Z) <= size.Z / 2 + p.Size.Z / 2 then
					table.insert(out, p)
				end
			end
			return out
		end,
	}
	local Traffic = { near = function() end, hit = function() end }
	local Collisions = luau.load(fs.readFile("src/client/Controllers/Collisions.luau"), {
		debugName = "Collisions",
		environment = setmetatable({
			Vector3 = Vector3,
			CFrame = CFrame,
			Enum = roblox.Enum,
			game = { GetService = function(_, name)
				return services[name] or stub
			end },
			workspace = fakeWorkspace,
			OverlapParams = { new = function()
				return {}
			end },
			script = { Parent = { Traffic = Traffic, SoundFx = stub, CameraShake = stub, CrashFx = stub, Nudge = stub } },
			require = function(what)
				if what == Traffic then
					return Traffic
				end
				return if type(what) == "table" and rawget(what, "Count") ~= nil then what else what
			end,
		}, { __index = getfenv(1) }),
	})()
	local function driver(speed: number)
		local m = car(Vector3.zero, Vector3.new(0, 0, -1))
		return { Model = m, Chassis = m.PrimaryPart, Kind = "Coche", Speed = speed, Travel = 0, Yaw = 0, Push = Vector3.zero, Spin = 0 }
	end
	local forward = Vector3.new(0, 0, -1)
	-- Pesados (Knock.Catalog con MinSpeed): contenedor al lado, señal detrás, banco delante
	for _, case in {
		{ "Container", Vector3.new(3.1 + 1.1 + 0.1, 1.7, 0), 8, true, "un contenedor de reciclaje pegado al lado" },
		{ "Senal", Vector3.new(2.5, 3, 6.4), 8, true, "una señal junto a la esquina de atrás" },
		{ "Container", Vector3.new(0, 1.7, 7.2), -6, false, "marcha atrás contra un contenedor que está detrás" },
		{ "Bench", Vector3.new(0, 1, -7.4), 8, false, "un banco justo delante" },
	} do
		table.clear(props)
		table.insert(props, part(case[1], #props + 1, case[2], Vector3.new(2.2, 3.4, 2.2)))
		local s = driver(case[3])
		task.wait(0.11) -- (touchProps mira cada 0,1 s)
		Collisions.touchProps(s, Vector3.zero, forward, s.Speed)
		local free = s.Speed == case[3]
		if case[4] then
			check(free, ("%s no bloquea el coche (velocidad %.1f → %.1f)"):format(case[5], case[3], s.Speed))
		else
			check(not free and math.abs(s.Speed) < math.abs(case[3]), ("%s sí para el coche (velocidad %.1f → %.1f)"):format(case[5], case[3], s.Speed))
		end
	end
	-- Coches aparcados: uno al lado (cordón, 0,6 studs de hueco) no frena; uno delante, sí
	table.clear(props)
	parked = { car(Vector3.new(6.2 + 0.6, 0, 0), forward) }
	local s = driver(10)
	local move = forward * 10 / 60
	local out = Collisions.solve(s, Vector3.zero, move, forward, 1 / 60, 72)
	check((out - move).Magnitude < 1e-6 and s.Speed == 10, ("un coche aparcado al lado no frena ni desvía (paso %.3f, velocidad %.1f)"):format(out.Magnitude, s.Speed))
	parked = { car(Vector3.new(0, 0, -13.6), forward) }
	task.wait(0.3) -- (la búsqueda de cercanos se repite cada 0,25 s)
	s = driver(10)
	out = Collisions.solve(s, Vector3.zero, move, forward, 1 / 60, 72)
	check(out:Dot(forward) < move:Dot(forward) or s.Speed < 10, ("un coche aparcado delante sí para (paso %.3f, velocidad %.1f)"):format(out:Dot(forward), s.Speed))
end

print("El juego usa todo esto (lectura del código)")
local function read(path: string): string
	local ok, text = pcall(fs.readFile, path)
	return if ok then text else ""
end
local driving = read("src/client/Controllers/Driving.luau")
local collisions = read("src/client/Controllers/Collisions.luau")
local traffic = read("src/client/Controllers/Traffic.luau")
local service = read("src/server/Services/CrashService.luau")
local main = read("src/server/Main.server.luau")
local project = read("default.project.json")
check(string.find(driving, "Collisions.solve", 1, true) ~= nil, "Driving resuelve los choques con Collisions.solve")
check(string.find(driving, "if not tuning.Boat", 1, true) ~= nil, "Driving no aplica choques de coche a los barcos")
check(string.find(collisions, "Crash.resolve", 1, true) ~= nil and string.find(collisions, "Crash.contact", 1, true) ~= nil, "Collisions usa shared/Crash")
check(string.find(collisions, "BROAD_EVERY", 1, true) ~= nil, "Collisions busca vehículos cercanos pocas veces por segundo (no en cada fotograma)")
check(string.find(traffic, "function Traffic.hit", 1, true) ~= nil and string.find(traffic, "HitUntil", 1, true) ~= nil, "el tráfico reacciona al golpe (se para y protesta)")
check(string.find(service, "Crash.judge", 1, true) ~= nil and string.find(service, "Crash.burst", 1, true) ~= nil, "CrashService valida los avisos con Crash.judge y limita el spam")
check(string.find(service, "rideModel", 1, true) ~= nil, "CrashService usa el vehículo que conduces según el servidor (no el que diga el cliente)")
check(string.find(main, "\"CrashService\"", 1, true) ~= nil, "CrashService arranca con el servidor")
check(string.find(project, "\"Crash\"", 1, true) ~= nil and string.find(project, "\"Knock\"", 1, true) ~= nil, "los remotos Crash y Knock están en el proyecto")
local knockService = read("src/server/Services/KnockService.luau")
local ambient = read("src/client/Controllers/Ambient.luau")
local vehicles = read("src/client/Controllers/Vehicles.luau")
local vehicleService = read("src/server/Services/VehicleService.luau")
local toy = read("src/server/Services/ToyService.luau")
check(string.find(knockService, "Knock.plausible", 1, true) ~= nil and string.find(knockService, "Knock.admit", 1, true) ~= nil, "KnockService valida los golpes y respeta el presupuesto")
check(string.find(knockService, "CombatService.applyHit", 1, true) ~= nil, "atropellar a un jugador pasa por las reglas de siempre (K.O., protección, delitos)")
check(string.find(knockService, "Knock.shouldRespawn", 1, true) ~= nil and string.find(knockService, "Knock.RayGroup", 1, true) ~= nil, "los objetos vuelven a su sitio y los rayos del coche no los ven")
check(string.find(main, "\"KnockService\"", 1, true) ~= nil, "KnockService arranca con el servidor")
check(string.find(ambient, "Knock.personPose", 1, true) ~= nil, "los peatones de la calle caen y se levantan")
check(string.find(vehicles, "Collisions.exitVehicle", 1, true) ~= nil, "en moto, un golpe fuerte te baja del vehículo")
check(string.find(vehicleService, "GetAttribute(\"Knocked\")", 1, true) ~= nil, "VehicleService no aparca una moto mientras vuela")
check(string.find(toy, "function ToyService.push", 1, true) ~= nil, "los balones también salen con el coche")
check(string.find(driving, "Collisions.touchProps", 1, true) ~= nil and string.find(driving, "Collisions.rayGroup", 1, true) ~= nil, "Driving lanza lo que toca y sus rayos no frenan contra una papelera")

print("")
if failures > 0 then
	print(("❌ %d comprobaciones fallan"):format(failures))
	process.exit(1)
end
print("✅ Choques entre vehículos: todo correcto")
