-- WheelRig: las cuentas de las ruedas que giran (lo usan Controllers/WheelSpin y Controllers/Traffic).
-- SOLO cuentas y datos: sin servicios ni instancias (lo prueba scripts/test-wheels.luau con Lune).
--
--   * Rodar sin deslizar: lo que gira la rueda = lo que avanza / su radio (marcha atrás, al revés).
--   * Las ruedas de delante giran con el volante (coche, patrulla, autobús, camiones y la horquilla de
--     la moto). El volante sale del mando (tu vehículo) o de cuánto gira el vehículo para lo que
--     avanza (los demás: modelo de bicicleta, ángulo = atan(batalla × giro / velocidad)).
--   * Freno de mano en marcha: las de atrás se bloquean (derrapa: no giran).
--   * Solo las ruedas de verdad: piezas «Wheel» (neumático) y lo que va con ellas (llanta, buje,
--     radios, tuercas, disco de freno y las llantas y bandas del taller, Mod_…). La colisión, el
--     tamaño y los nombres no cambian nunca: solo se recoloca lo que se ve.
--
-- Convención (la de Rides/CarModel): vehículo a ras de suelo, el morro mira a −Z (LookVector),
-- las ruedas son cilindros a lo largo de X (el eje).

local WheelRig = {}

WheelRig.RANGE = 150 -- más lejos no se anima (no se nota)
WheelRig.MAX_VEHICLES = 12 -- como mucho tantos vehículos a la vez (los más cercanos)
WheelRig.LOCK_SPEED = 2 -- freno de mano por encima de esta velocidad: ruedas de atrás bloqueadas
WheelRig.TELEPORT = 60 -- un salto mayor en un fotograma no es rodar (teletransporte)

-- Tipos con ruedas (los barcos no: su «Wheel» es el timón)
WheelRig.Kinds = {
	Coche = true,
	Patrulla = true,
	Autobus = true,
	Camion = true,
	Bomberos = true,
	Moto = true,
	Bici = true,
	Patinete = true,
	Monopatin = true,
}
-- Nombres del tráfico de la ciudad (Controllers/Traffic) -> tipo
WheelRig.TrafficKind = { Car = "Coche", Moto = "Moto", Bici = "Bici", Patinete = "Patinete" }

-- Lo más que giran las ruedas de delante (radianes). Sin entrada: no giran (bici, patinete, monopatín)
WheelRig.MaxSteer = {
	Coche = math.rad(30),
	Patrulla = math.rad(30),
	Autobus = math.rad(26),
	Camion = math.rad(26),
	Bomberos = math.rad(26),
	Moto = math.rad(24),
}

-- Piezas que giran con la rueda (y las del taller, VehicleParts / VehicleBuild: llantas y bandas)
WheelRig.SpinNames = {
	Wheel = true,
	Rim = true,
	RimInner = true,
	Hub = true,
	Spoke = true,
	Nut = true,
	Bearing = true,
	BrakeDisc = true,
	Cog = true,
	Mod_Rim = true,
	Mod_RimFace = true,
	Mod_RimSpoke = true,
	Mod_RimHub = true,
	Mod_TireBand = true,
	Mod_TireBandInner = true,
}
-- Piezas que giran con el volante pero no ruedan (horquilla, guardabarros y pinza de la moto)
WheelRig.SteerNames = { Fork = true, FenderFront = true, Caliper = true }

export type PartInfo = { Name: string, CFrame: CFrame, Size: Vector3 }
export type Wheel = {
	Index: number, -- la pieza «Wheel» (en la lista de entrada)
	Hub: CFrame, -- centro y eje de la rueda (respecto al vehículo)
	Radius: number,
	Front: boolean, -- eje delantero (gira con el volante si el tipo lo tiene)
	Rear: boolean, -- detrás del centro de las ruedas (se bloquea con el freno de mano)
	Spin: { number }, -- piezas que ruedan con ella (incluida la propia rueda)
	Steer: { number }, -- piezas que solo giran con el volante
	Angle: number,
}
export type Rig = { Wheels: { Wheel }, Wheelbase: number, Steers: boolean, MaxSteer: number }

local function isWheel(info: PartInfo): boolean
	local s = info.Size
	-- un cilindro (Y = Z) con el eje en horizontal, de tamaño de rueda
	return info.Name == "Wheel" and math.abs(s.Y - s.Z) < 0.01 and s.Y > 0.1 and s.Y < 8 and math.abs(info.CFrame.RightVector.Y) < 0.3
end

-- Busca las ruedas y lo que va con cada una. parts: piezas con su CFrame RESPECTO AL VEHÍCULO.
function WheelRig.find(parts: { PartInfo }, kind: string): Rig
	local wheels: { Wheel } = {}
	for i, info in parts do
		if isWheel(info) then
			table.insert(wheels, {
				Index = i,
				Hub = info.CFrame,
				Radius = info.Size.Y / 2,
				Front = false,
				Rear = false,
				Spin = { i },
				Steer = {},
				Angle = 0,
				Width = info.Size.X,
			} :: any)
		end
	end
	if #wheels == 0 then
		return { Wheels = wheels, Wheelbase = 0, Steers = false, MaxSteer = 0 }
	end
	-- Delante / detrás respecto al centro de las ruedas (la pieza de referencia puede no estar en
	-- el centro: la cabina del camión). Eje delantero: el de más adelante.
	local minZ, maxZ, rearSum, rearCount = math.huge, -math.huge, 0, 0
	for _, w in wheels do
		minZ = math.min(minZ, w.Hub.Position.Z)
		maxZ = math.max(maxZ, w.Hub.Position.Z)
	end
	local mid = (minZ + maxZ) / 2
	for _, w in wheels do
		local z = w.Hub.Position.Z
		w.Front = minZ < mid - 0.5 and z < minZ + 1
		w.Rear = z > mid + 0.5
		if w.Rear then
			rearSum += z
			rearCount += 1
		end
	end
	local wheelbase = if rearCount > 0 and minZ < mid then rearSum / rearCount - minZ else 0
	local maxSteer = WheelRig.MaxSteer[kind] or 0
	local steers = maxSteer > 0 and wheelbase > 0
	-- Cada pieza que rueda, con la rueda en cuyo disco cae (la más cercana)
	for i, info in parts do
		local spin = WheelRig.SpinNames[info.Name] and not isWheel(info)
		local steerOnly = steers and WheelRig.SteerNames[info.Name]
		if not spin and not steerOnly then
			continue
		end
		local best, bestDist = nil, math.huge
		for _, w in wheels do
			local p = w.Hub:PointToObjectSpace(info.CFrame.Position)
			local radial = math.sqrt(p.Y * p.Y + p.Z * p.Z)
			if spin then
				if math.abs(p.X) <= (w :: any).Width / 2 + 0.9 and radial <= w.Radius * 1.05 and radial + math.abs(p.X) < bestDist then
					best, bestDist = w, radial + math.abs(p.X)
				end
			elseif w.Front then
				local d = p.Magnitude
				if d <= w.Radius * 2.5 and d < bestDist then
					best, bestDist = w, d
				end
			end
		end
		if best then
			table.insert(if spin then best.Spin else best.Steer, i)
		end
	end
	for _, w in wheels do
		(w :: any).Width = nil
	end
	return { Wheels = wheels, Wheelbase = wheelbase, Steers = steers, MaxSteer = maxSteer }
end

-- Lo que gira una rueda al avanzar distance (studs; negativo = marcha atrás). Entre 0 y 2π.
-- (Hacia delante, la parte de arriba de la rueda va hacia el morro: giro negativo en X.)
function WheelRig.advance(angle: number, distance: number, radius: number): number
	if radius <= 0 then
		return angle
	end
	return (angle - distance / radius) % (2 * math.pi)
end

-- ¿Bloqueada? (freno de mano en marcha: las de atrás no giran)
function WheelRig.locked(rear: boolean, handbrake: boolean, speed: number): boolean
	return rear and handbrake and math.abs(speed) > WheelRig.LOCK_SPEED
end

-- Ángulo de las ruedas de delante (giro en Y: positivo = a la izquierda) desde el volante (-1..1,
-- positivo = derecha, como Driving)
function WheelRig.steerFromInput(rig: Rig, steer: number): number
	if not rig.Steers then
		return 0
	end
	return -math.clamp(steer, -1, 1) * rig.MaxSteer
end

-- Desde cuánto gira el vehículo (yawRate rad/s, positivo = a la izquierda) y su velocidad (studs/s,
-- negativa marcha atrás). nil = casi parado (que se quede como estaba).
function WheelRig.steerFromYaw(rig: Rig, yawRate: number, speed: number): number?
	if not rig.Steers then
		return 0
	end
	if math.abs(speed) < 1 then
		return nil
	end
	local angle = math.atan(rig.Wheelbase * yawRate / speed)
	return math.clamp(angle, -rig.MaxSteer, rig.MaxSteer)
end

-- Giro (con signo, positivo = a la izquierda) entre dos direcciones horizontales
function WheelRig.yawBetween(a: Vector3, b: Vector3): number
	local cross = a.Z * b.X - a.X * b.Z
	local dot = a.X * b.X + a.Z * b.Z
	return math.atan2(cross, dot)
end

-- Dónde va (respecto al vehículo) una pieza que rueda con su rueda: rest = su sitio quieta
function WheelRig.pose(wheel: Wheel, steer: number, rest: CFrame): CFrame
	return WheelRig.hubPose(wheel, steer) * wheel.Hub:ToObjectSpace(rest)
end
-- El centro de la rueda girado (volante) y rodado (Angle). drop: cuánto baja (rueda pinchada, studs)
function WheelRig.hubPose(wheel: Wheel, steer: number, drop: number?): CFrame
	local hub = wheel.Hub
	local pose
	if wheel.Front and steer ~= 0 then
		local c = hub.Position
		pose = CFrame.new(c) * CFrame.Angles(0, steer, 0) * CFrame.new(-c) * hub * CFrame.Angles(wheel.Angle, 0, 0)
	else
		pose = hub * CFrame.Angles(wheel.Angle, 0, 0)
	end
	if drop and drop ~= 0 then
		pose = CFrame.new(0, -drop, 0) * pose
	end
	return pose
end
-- Pieza que solo gira con el volante (horquilla)
function WheelRig.steerPose(wheel: Wheel, steer: number, rest: CFrame): CFrame
	if steer == 0 then
		return rest
	end
	local c = wheel.Hub.Position
	return CFrame.new(c) * CFrame.Angles(0, steer, 0) * CFrame.new(-c) * rest
end

-- ¿Se ve? (delante de la cámara y dentro de su campo, con margen del tamaño del vehículo)
function WheelRig.visible(camera: CFrame, fovY: number, aspect: number, point: Vector3, margin: number): boolean
	local p = camera:PointToObjectSpace(point)
	local depth = -p.Z
	if depth < -margin then
		return false
	end
	local tanY = math.tan(fovY / 2)
	local d = math.max(depth, 0)
	return math.abs(p.Y) <= d * tanY + margin and math.abs(p.X) <= d * tanY * aspect + margin
end

-- Qué vehículos se animan: los que se ven a menos de RANGE, los más cercanos primero, como mucho
-- MAX_VEHICLES. Forced = siempre (el tuyo). candidates: { Key, Position, Visible, Forced? }
function WheelRig.pick(candidates: { { Key: any, Position: Vector3, Visible: boolean, Forced: boolean? } }, eye: Vector3, range: number?, max: number?): { any }
	local limit = range or WheelRig.RANGE
	local list = {}
	for _, c in candidates do
		local d = (c.Position - eye).Magnitude
		if c.Forced or (c.Visible and d <= limit) then
			table.insert(list, { Key = c.Key, D = if c.Forced then -1 else d })
		end
	end
	table.sort(list, function(a, b)
		return a.D < b.D
	end)
	local out = {}
	for i = 1, math.min(#list, max or WheelRig.MAX_VEHICLES) do
		table.insert(out, list[i].Key)
	end
	return out
end

return WheelRig
