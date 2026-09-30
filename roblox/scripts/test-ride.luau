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

---------------------------------------------------------------------
-- Sacar el vehículo (shared/RideSpot): llano, libre y en la calzada; nunca inclinado ni hundido
---------------------------------------------------------------------
print("Sacar el vehículo (RideSpot)")
local RideSpot = load("src/shared/RideSpot.luau")
local SIZES = {}
for _, kind in { "Coche", "Moto", "Patinete", "Monopatin", "Bici" } do
	SIZES[kind] = Rides.Spec[kind].Size
end

-- Un mundo de mentira: calzada (a lo largo de Z) de x = -11 a 11 a y = 0; acera a 0.5 hasta x = 17;
-- un murete de 0.6 de ancho y 1.2 de alto en x = 17.3; césped (a 0.5) detrás. Obstáculos: cajas.
type Box = { C: Vector3, H: Vector3, Person: boolean? }
local function makeWorld(heightAt: (number, number) -> number, road: (number, number) -> boolean, obstacles: { Box })
	return {
		ground = function(x: number, z: number, top: number, bottom: number)
			local y = heightAt(x, z)
			if y > top or y < bottom then
				return nil, nil, false
			end
			return y, if road(x, z) then Vector3.new(0, 0, -1) else nil, false
		end,
		blocked = function(cf: CFrame, size: Vector3)
			local lo = cf.Position.Y + RideSpot.Lift
			local hi = lo + RideSpot.Height
			for _, o in obstacles do
				if o.C.Y + o.H.Y > lo and o.C.Y - o.H.Y < hi then
					if RideSpot.boxesOverlap(cf.Position, cf.LookVector, size.Z, size.X, o.C, Vector3.new(0, 0, -1), o.H.Z * 2, o.H.X * 2) then
						return true
					end
				end
			end
			return false
		end,
	}
end
local function street(x: number, _z: number): number
	if math.abs(x - 17.3) <= 0.3 then
		return 1.7 -- el murete
	end
	return if math.abs(x) <= 11 then 0 else 0.5
end
local function onRoad(x: number, _z: number): boolean
	return math.abs(x) <= 11
end
local WALL: Box = { C = Vector3.new(17.3, 1.1, 0), H = Vector3.new(0.3, 0.6, 200) }

-- ¿Bien puesto? derecho, apoyado en el suelo en todas sus esquinas y sin nada dentro
local function goodSpot(world, cf: CFrame?, size: Vector3, heightAt): (boolean, string)
	if not cf then
		return false, "no sale"
	end
	if cf.UpVector.Y <= 0.95 then
		return false, ("inclinado (%.2f)"):format(cf.UpVector.Y)
	end
	for _, fx in { -0.5, 0, 0.5 } do
		for _, fz in { -0.5, 0, 0.5 } do
			local p = cf * Vector3.new(fx * size.X, 0, fz * size.Z)
			local g = heightAt(p.X, p.Z)
			if math.abs(p.Y - g) > 0.35 then
				return false, ("esquina %.2f sobre un suelo a %.2f"):format(p.Y, g)
			end
		end
	end
	if world.blocked(cf, size) then
		return false, "con algo dentro"
	end
	return true, ""
end

for kind, size in SIZES do
	-- En la calzada, mirando en diagonal: sale en la calzada, a lo largo de la calle
	local flatWorld = makeWorld(street, onRoad, { WALL })
	local look = Vector3.new(1, 0, -1).Unit
	local cf = RideSpot.choose(flatWorld, Vector3.new(0, 2.5, 0), 0, look, size)
	local ok, why = goodSpot(flatWorld, cf, size, street)
	check(ok and cf ~= nil and math.abs(cf.LookVector.Z) > 0.95 and math.abs(cf.Position.X) + size.X / 2 <= 11.01, kind .. ": en la calle sale derecho, en la calzada y a lo largo de la calle " .. why)

	-- En la acera junto al murete, con una farola, una papelera y alguien delante (el vídeo de la moto)
	local stuff: { Box } = {
		WALL,
		{ C = Vector3.new(15.5, 3, -2.5), H = Vector3.new(0.3, 3, 0.3) }, -- farola
		{ C = Vector3.new(15.5, 1, 1.5), H = Vector3.new(0.5, 0.8, 0.5) }, -- papelera
		{ C = Vector3.new(14, 2.9, -2), H = Vector3.new(0.6, 2.5, 0.4), Person = true }, -- alguien delante
	}
	local kerbWorld = makeWorld(street, onRoad, stuff)
	local cf2 = RideSpot.choose(kerbWorld, Vector3.new(14, 3, 0), 0.5, Vector3.new(1, 0, 0), size)
	local ok2, why2 = goodSpot(kerbWorld, cf2, size, street)
	check(ok2, kind .. ": junto al murete, la farola y una persona, sale en un sitio llano y libre " .. why2)

	-- En una cuesta (10 %): inclinado lo justo, apoyado en el suelo
	local function slope(x: number, z: number): number
		return if math.abs(x) <= 11 then -0.1 * z else 0.5 - 0.1 * z
	end
	local hill = makeWorld(slope, onRoad, {})
	local cf3 = RideSpot.choose(hill, Vector3.new(0, 2.5, 0), 0, Vector3.new(0, 0, -1), size)
	local ok3, why3 = goodSpot(hill, cf3, size, slope)
	check(ok3, kind .. ": en una cuesta sale apoyado en el suelo, sin hundirse " .. why3)

	-- Atascado dentro de una farola: se le saca a un sitio libre al lado
	local lamp: Box = { C = Vector3.new(0, 3, -1), H = Vector3.new(0.3, 3, 0.3) }
	local stuckWorld = makeWorld(street, onRoad, { lamp })
	local here = RideSpot.frame(Vector3.new(0, 0, 0), Vector3.new(0, 0, -1))
	check(stuckWorld.blocked(here, size), kind .. ": (la farola está dentro)")
	local out = RideSpot.unstick(stuckWorld, here, size)
	local ok4, why4 = goodSpot(stuckWorld, out, size, street)
	check(ok4 and out ~= nil and (out.Position - here.Position).Magnitude < 8, kind .. ": atascado en una farola, se desatasca al lado " .. why4)
end
-- Rodeado de paredes: no sale (antes salía metido en ellas)
local boxed = makeWorld(function()
	return 0
end, function()
	return true
end, { { C = Vector3.new(0, 2, 0), H = Vector3.new(40, 2, 40) } })
check(RideSpot.choose(boxed, Vector3.new(0, 2.5, 0), 0, Vector3.new(0, 0, -1), SIZES.Coche) == nil, "sin sitio libre alrededor, no sale")
-- Sobre el agua (sin suelo en ninguna parte cercana... pero sí lejos): no sale en el agua
local sea = {
	ground = function(x: number, z: number)
		return nil, nil, true
	end,
	blocked = function()
		return false
	end,
}
check(RideSpot.choose(sea, Vector3.new(0, 2.5, 0), 0, Vector3.new(0, 0, -1), SIZES.Moto) == nil, "en el agua no sale")

print("Vigilancia del conductor (RideSpot.watchSeat)")
local w = {}
check(RideSpot.watchSeat(w, 0, true, true) == nil, "sentado al volante: nada")
check(RideSpot.watchSeat(w, 1, true, false) == nil and RideSpot.watchSeat(w, 2, true, false) == nil, "montado sin estar sentado: se espera un momento")
check(RideSpot.watchSeat(w, 2.6, true, false) == "Reseat", "…y se pide volver a sentarle")
check(RideSpot.watchSeat(w, 3.5, true, false) == nil, "(una sola vez)")
check(RideSpot.watchSeat(w, 4.6, true, false) == "Dismount" and RideSpot.watchSeat(w, 6, true, false) == nil, "si sigue sin sentarse, se baja del todo (pedales y velocidad fuera)")
check(RideSpot.watchSeat(w, 7, false, false) == nil and w.Since == nil, "ya bajado: se olvida")
local w2 = {}
RideSpot.watchSeat(w2, 0, true, false)
check(RideSpot.watchSeat(w2, 1, true, true) == nil and RideSpot.watchSeat(w2, 5, true, true) == nil, "si se sienta a tiempo, no se le baja")

print("Atascos (RideSpot.stuckStep)")
local st = { Stuck = 0 }
local fired = false
for _ = 1, 60 do
	fired = RideSpot.stuckStep(st, 1, 0, 1 / 60) or fired
end
check(not fired, "pisando 1 s sin moverse: aún no")
for _ = 1, 60 do
	fired = RideSpot.stuckStep(st, 1, 0, 1 / 60) or fired
end
check(fired, "pisando 2 s sin moverse: se desatasca")
local st2 = { Stuck = 0 }
local moving = false
for _ = 1, 240 do
	moving = RideSpot.stuckStep(st2, 1, 4, 1 / 60) or moving
end
check(not moving, "sin gasolina (a 4 studs/s) no cuenta como atasco")
local st3 = { Stuck = 0 }
local idle = false
for _ = 1, 240 do
	idle = RideSpot.stuckStep(st3, 0, 0, 1 / 60) or idle
end
check(not idle, "parado sin pisar: no es un atasco")

print("Choques con el tráfico (cajas vistas desde arriba)")
check(RideSpot.boxesOverlap(Vector3.new(0, 0, 0), Vector3.new(0, 0, -1), 5.8, 1.6, Vector3.new(0, 0, -8), Vector3.new(0, 0, 1), 13.5, 6.6), "moto contra un coche de frente: se tocan")
check(not RideSpot.boxesOverlap(Vector3.new(0, 0, 0), Vector3.new(0, 0, -1), 5.8, 1.6, Vector3.new(0, 0, -12), Vector3.new(0, 0, 1), 13.5, 6.6), "separados: no")
check(RideSpot.boxesOverlap(Vector3.new(0, 0, 0), Vector3.new(0, 0, -1), 13.5, 6.2, Vector3.new(6, 0, 0), Vector3.new(1, 0, 0), 13.5, 6.6), "coche cruzado en el costado: se tocan")
check(not RideSpot.boxesOverlap(Vector3.new(0, 0, 0), Vector3.new(0, 0, -1), 13.5, 6.2, Vector3.new(7, 0, 0), Vector3.new(0, 0, -1), 13.5, 6.6), "en el carril de al lado: no")

-- El tráfico de verdad (Controllers/Traffic): tu vehículo choca con sus coches
do
	local stub = setmetatable({}, { __index = function()
		return function() end
	end })
	local Traffic = load("src/client/Controllers/Traffic.luau", {
		game = { GetService = function(_, name)
			if name == "Players" then
				return { LocalPlayer = {} }
			end
			return { Shared = { RideSpot = "RideSpot" } }
		end },
		script = { Parent = { Parent = { UI = {} } } },
		require = function(what)
			return if what == "RideSpot" then RideSpot else stub
		end,
	})
	table.insert(Traffic._agents, { Active = true, Pos = Vector3.new(0, 0.4, -10), Dir = Vector3.new(0, 0, 1), Length = 13.5, Width = 6.6 })
	check(Traffic.blocking(Vector3.new(0, 0.4, -2), Vector3.new(0, 0, -1), 5.8, 1.6) ~= nil, "tu moto contra un coche del tráfico: choca (no lo atraviesa)")
	check(Traffic.blocking(Vector3.new(9, 0.4, -2), Vector3.new(0, 0, -1), 5.8, 1.6) == nil, "por el carril de al lado pasa")
	Traffic._agents[1].Active = false
	check(Traffic.blocking(Vector3.new(0, 0.4, -2), Vector3.new(0, 0, -1), 5.8, 1.6) == nil, "un coche retirado no cuenta")
end

print("Pata de cabra y caballete")
local function fakePart(props)
	local attrs = {}
	local obj = props
	function obj:GetAttribute(k)
		return attrs[k]
	end
	function obj:SetAttribute(k, v)
		attrs[k] = v
	end
	function obj:IsA(c)
		return c == "BasePart" and obj.ClassName ~= "Weld" or c == obj.ClassName
	end
	function obj:FindFirstChild(name)
		return if obj.Child and obj.Child.Name == name then obj.Child else nil
	end
	return obj
end
for kind, ends in {
	Moto = { Vector3.new(-0.5, 0.9, 0.2), Vector3.new(-0.9, 0.1, 0.4) },
	Patinete = { Vector3.new(-0.45, 0.5, 0.3), Vector3.new(-0.7, 0.05, 0.6) },
} do
	local a, b = ends[1], ends[2]
	local len = (b - a).Magnitude
	local folded = a + Vector3.new((b.X - a.X) * 0.25, 0.08, len)
	local down, up = Rides.tubeFrame(a, b), Rides.tubeFrame(a, folded)
	local function lowest(cf: CFrame): number
		return math.min((cf * Vector3.new(0, 0, len / 2)).Y, (cf * Vector3.new(0, 0, -len / 2)).Y)
	end
	check(lowest(down) < 0.15 and lowest(up) > 0.4, ("%s: aparcada la pata llega al suelo (%.2f); recogida queda arriba (%.2f)"):format(kind, lowest(down), lowest(up)))
	local weld = fakePart({ Name = "StandWeld", ClassName = "Weld", C0 = down })
	local stand = fakePart({ Name = "Kickstand", ClassName = "Part", Child = weld })
	stand:SetAttribute("StandDown", down)
	stand:SetAttribute("StandUp", up)
	local model = {
		GetDescendants = function()
			return { stand, weld }
		end,
	}
	Rides.setStand(model, false)
	check(weld.C0 == up and stand:GetAttribute("StandIsDown") == false, kind .. ": al subirse y arrancar, la pata se recoge")
	Rides.setStand(model, true)
	check(weld.C0 == down and stand:GetAttribute("StandIsDown") == true, kind .. ": aparcada sin nadie, la pata baja")
end

print("Cámara: postes finos")
local RideCameraThin = RideCamera.isThin
check(RideCameraThin(Vector3.new(0.6, 14, 0.6)) and RideCameraThin(Vector3.new(1.2, 3, 1.2)), "una farola o un semáforo son postes finos (se ven transparentes)")
check(not RideCameraThin(Vector3.new(1, 12, 30)) and not RideCameraThin(Vector3.new(40, 1, 40)), "una pared o un suelo no")

print("")
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d comprobaciones fallidas"):format(failures))
	process.exit(1)
end
