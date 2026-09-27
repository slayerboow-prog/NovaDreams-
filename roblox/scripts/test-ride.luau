-- Prueba de la cámara y las posturas en los vehículos FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-ride.luau
--
-- Comprueba que:
--   * la cámara de viaje (Controllers/RideCamera) guarda distancias con sentido (nada de primera
--     persona dentro del coche), sigue al vehículo sin quedarse atrás ni temblar, salta si hay un
--     teletransporte y solo se coloca detrás cuando vas en marcha y no la mueves tú
--   * cada asiento pone su postura (Controllers/RidePose): volante, manillar, pasajero, detrás en la moto
--   * los asientos de pasajero (World/Kit/Rides) caben dentro de cada vehículo y se bajan por su lado

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local CFrame, Vector3, Color3, Enum = roblox.CFrame, roblox.Vector3, roblox.Color3, roblox.Enum

local failures = 0
local function check(ok: boolean, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local fakeGame = {
	GetService = function(_, name)
		if name == "Players" then
			return { LocalPlayer = {} }
		end
		return {}
	end,
}
local baseEnv = { CFrame = CFrame, Vector3 = Vector3, Color3 = Color3, Enum = Enum, game = fakeGame }
local function load(path: string, extra: { [string]: any }?)
	local env = setmetatable(table.clone(baseEnv), { __index = getfenv(1) })
	for k, v in extra or {} do
		env[k] = v
	end
	return luau.load(fs.readFile(path), { debugName = path, environment = env })()
end

local RideCamera = load("src/client/Controllers/RideCamera.luau")
local WorkAnim = load("src/client/Controllers/WorkAnim.luau")
local RidePose = load("src/client/Controllers/RidePose.luau", {
	script = { Parent = { WorkAnim = "WorkAnim" } },
	require = function()
		return WorkAnim
	end,
})

print("Cámara de viaje")
local car = RideCamera.view(Vector3.new(6.4, 5.5, 13.6), false)
local bus = RideCamera.view(Vector3.new(11.4, 10.5, 34.2), false)
local moto = RideCamera.view(Vector3.new(2.6, 4.7, 5.8), false)
local metro = RideCamera.view(Vector3.zero, true)
check(car.Mode == "Fuera" and car.Min >= 10 and car.Start > car.Min and car.Max > car.Start, "coche: la cámara nunca entra en el coche (mínimo " .. car.Min .. ")")
check(car.Height > 5.5, "coche: el foco va por encima del techo")
check(bus.Min > car.Min and bus.Height > car.Height, "autobús: más lejos y más alto que el coche")
check(moto.Min >= 7 and moto.Min < car.Min, "moto: cerca, pero sin primera persona")
check(metro.Mode == "Dentro" and metro.Max <= 14, "metro: la cámara se queda dentro del vagón (distancia corta)")

check(math.abs(RideCamera.yawBetween(Vector3.new(0, 0, -1), Vector3.new(-1, 0, 0)) - math.pi / 2) < 1e-6, "ángulo entre direcciones: izquierda = +90°")
check(math.abs(RideCamera.yawBetween(Vector3.new(0, 0, -1), Vector3.new(1, 0, 0)) + math.pi / 2) < 1e-6, "ángulo entre direcciones: derecha = -90°")
check(math.abs(math.abs(RideCamera.yawBetween(Vector3.new(0, 0, -1), Vector3.new(0, 0, 1))) - math.pi) < 1e-6, "ángulo entre direcciones: detrás = 180°")

-- Siguiendo un coche a 60 studs/s: no se queda atrás y no tiembla aunque lleguen saltos (red)
local focus = Vector3.new(0, 6, 0)
local velocity = Vector3.new(0, 0, -60)
local maxGap, maxJerk, lastStep = 0, 0, nil
for i = 1, 240 do
	local dt = 1 / 60
	local t = i * dt
	-- el vehículo que mueve otro ordenador llega a saltitos (±0.4 studs) y con baches
	local noise = (i % 3 == 0) and 0.4 or -0.2
	local target = Vector3.new(noise, 6 + math.sin(t * 20) * 0.3, -60 * t)
	local before = focus
	focus = RideCamera.follow(focus, velocity, target, dt)
	local stepLength = (focus - before).Magnitude
	if lastStep then
		maxJerk = math.max(maxJerk, math.abs(stepLength - lastStep))
	end
	lastStep = stepLength
	if i > 60 then
		maxGap = math.max(maxGap, (focus - Vector3.new(0, 6, -60 * t)).Magnitude)
	end
end
check(maxGap < 1, ("sigue al coche a 60 studs/s sin quedarse atrás (%.2f)"):format(maxGap))
check(maxJerk < 0.35, ("sin tirones aunque el coche llegue a saltitos (%.2f)"):format(maxJerk))
local jumped = RideCamera.follow(Vector3.zero, Vector3.zero, Vector3.new(500, 0, 0), 1 / 60)
check(jumped == Vector3.new(500, 0, 0), "si el vehículo se teletransporta, el foco va directo")

check(RideCamera.autoTurn(1, 30, 5, 1 / 60) > 0, "en marcha y sin tocar la cámara, se coloca detrás")
check(RideCamera.autoTurn(1, 30, 0.5, 1 / 60) == 0, "si acabas de mover la cámara, no te la quita")
check(RideCamera.autoTurn(1, 2, 5, 1 / 60) == 0, "parado no se mueve sola")
check(math.abs(RideCamera.autoTurn(1, 30, 5, 1 / 60)) < 0.05, "se coloca poco a poco, sin saltos")
check(RideCamera.fov(0) == RideCamera.BASE_FOV and RideCamera.fov(80) > RideCamera.fov(30), "campo de visión: se abre un poco con la velocidad")

print("Posturas en los vehículos")
check(RidePose.seatPoseFor("DriverSeat", "VehicleSeat", "Coche", nil, false) == "Drive", "conductor de coche: manos al volante")
check(RidePose.seatPoseFor("DriverSeat", "VehicleSeat", "Autobus", nil, false) == "Drive", "conductor de autobús: manos al volante")
check(RidePose.seatPoseFor("DriverSeat", "VehicleSeat", "Moto", nil, false) == "Handlebar", "moto: manos al manillar")
local name, standing = RidePose.seatPoseFor("DriverSeat", "VehicleSeat", "Patinete", nil, false)
check(name == "Handlebar" and standing == true, "patinete: al manillar y de pie (piernas libres)")
check(RidePose.seatPoseFor("DriverSeat", "VehicleSeat", "Monopatin", nil, false) == nil, "monopatín: sin postura de sentado")
check(RidePose.seatPoseFor("RideSeat", "Seat", "Coche", "Passenger", false) == "Passenger", "copiloto: manos en las piernas")
check(RidePose.seatPoseFor("RideSeat", "Seat", "Moto", "Pillion", false) == "Pillion", "detrás en la moto: agarrado a la cintura")
check(RidePose.seatPoseFor("PassengerSeat", "Seat", "Autobus", nil, false) == "Passenger", "autobús: de pasajero")
check(RidePose.seatPoseFor("Seat", "Seat", nil, nil, true) == "Passenger", "metro: de pasajero")
check(RidePose.seatPoseFor("Seat", "Seat", nil, nil, false) == nil, "un banco: la postura de sentarse de siempre")
for _, pose in { "Drive", "Handlebar", "Passenger", "Pillion" } do
	check(WorkAnim.get(pose) ~= nil, pose .. " existe en WorkAnim")
end
check(RidePose.steerFor(nil, 1, 1 / 60) == 0 and RidePose.steerFor(0.5, 0.5, 1 / 60) == 0, "sin girar, volante recto")
check(RidePose.steerFor(0.5, 0.49, 1 / 60) > 0.3, "girando a la derecha, el volante gira a la derecha")
check(RidePose.steerFor(0.5, 0.51, 1 / 60) < -0.3, "girando a la izquierda, el volante gira a la izquierda")
check(math.abs(RidePose.steerFor(math.pi - 0.005, -math.pi + 0.005, 1 / 60)) < 1, "al dar la vuelta al ángulo (±180°) no pega un volantazo")

print("Asientos de pasajero")
-- Rides necesita el Builder del mundo: basta con leer la tabla de asientos (sin construir nada)
local Rides = load("src/server/World/Kit/Rides.luau", {
	script = { Parent = { Parent = { Builder = "Builder" }, Palette = "Palette", CarModel = "CarModel" } },
	require = function()
		return {}
	end,
})
for _, kind in { "Coche", "Patrulla", "Moto", "Camion", "Bomberos" } do
	local spec = Rides.Spec[kind]
	local seats = Rides.passengerSeats(kind, nil)
	local inside, sides, apart = true, true, true
	for i, seat in seats do
		local p = seat.Seat.Position
		if math.abs(p.X) > spec.Size.X / 2 or math.abs(p.Z) > spec.Size.Z / 2 then
			inside = false
		end
		if seat.Side ~= 1 and seat.Side ~= -1 then
			sides = false
		end
		if (seat.Side > 0) ~= (p.X > 0) and math.abs(p.X) > 0.1 then
			sides = false -- se baja por el lado donde va sentado
		end
		if (p - spec.Seat.Position).Magnitude < 1.1 then
			apart = false -- no encima del conductor
		end
		for j, other in seats do
			if j ~= i and (p - other.Seat.Position).Magnitude < 1.1 then
				apart = false
			end
		end
	end
	check(#seats > 0 and inside and sides and apart, kind .. ": " .. #seats .. " asiento(s) de pasajero dentro del vehículo, cada uno en su sitio y bajando por su lado")
end
for _, variant in { "Berlina", "Compacto", "Todoterreno" } do
	local back = Rides.passengerSeats("Coche", variant)[2].Seat.Position
	check(back.Z > 2 and back.Z < 4, variant .. ": los asientos de atrás caben detrás de los delanteros")
end
check(#Rides.passengerSeats("Bici", nil) == 0 and #Rides.passengerSeats("Monopatin", nil) == 0 and #Rides.passengerSeats("Patinete", nil) == 0, "bici, monopatín y patinete: solo una persona")

print("")
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d comprobaciones fallidas"):format(failures))
	process.exit(1)
end
