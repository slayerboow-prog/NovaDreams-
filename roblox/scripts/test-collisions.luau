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
check(string.find(project, "\"Crash\"", 1, true) ~= nil, "el remoto Crash está en el proyecto")

print("")
if failures > 0 then
	print(("❌ %d comprobaciones fallan"):format(failures))
	process.exit(1)
end
print("✅ Choques entre vehículos: todo correcto")
