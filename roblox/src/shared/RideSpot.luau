-- RideSpot: dónde se saca un vehículo y cómo se desatasca (lo usan VehicleService al sacar tu
-- vehículo y Driving cuando no avanza). Aquí solo está la cuenta: el mundo entra como funciones, así
-- se prueba fuera de Roblox (scripts/test-ride.luau) con calles, bordillos, muros, farolas y
-- personas de mentira.
--
--   world.ground(x, z, top, bottom) -> (y?, roadAxis?, water?)
--       Altura del suelo de verdad en (x, z) buscando de top hacia abajo hasta bottom. nil = no hay
--       (agua: water = true). roadAxis = hacia dónde va la calle si es calzada (para aparcar a lo largo).
--   world.blocked(cf, size) -> boolean
--       ¿Hay algo sólido (pared, bordillo alto, farola, papelera, coche) o una persona dentro de la
--       caja del vehículo? cf = centro a ras de suelo; la caja empieza RideSpot.Lift por encima.
--   world.clear(from, to) -> boolean   (opcional)
--       ¿Se puede ir en línea recta de from a to sin atravesar una pared?
--
-- Un sitio vale si el suelo bajo todo el vehículo es un plano (una cuesta suave sí; un bordillo, un
-- escalón o un murete dentro de la huella no), no se inclina más de MaxTilt y la caja está libre.
-- Se prefiere la calzada y, en ella, mirando a lo largo de la calle.

local RideSpot = {}

RideSpot.MaxTilt = math.rad(17) -- lo más inclinado que sale (UpVector.Y > 0.95)
RideSpot.Step = 0.25 -- lo que puede apartarse del plano un punto del suelo (más = bordillo o escalón)
RideSpot.Lift = 0.35 -- la caja de choques empieza aquí (una raya o una tapa de alcantarilla no cuenta)
RideSpot.Height = 4.5 -- alto de la caja de choques

export type World = {
	ground: (x: number, z: number, top: number, bottom: number) -> (number?, Vector3?, boolean?),
	blocked: (cf: CFrame, size: Vector3) -> boolean,
	clear: ((from: Vector3, to: Vector3) -> boolean)?,
}

local function flat(v: Vector3): Vector3?
	local f = Vector3.new(v.X, 0, v.Z)
	return if f.Magnitude > 1e-3 then f.Unit else nil
end

-- CFrame en base mirando hacia look con el techo hacia up (sin CFrame.lookAt: igual en todas partes)
function RideSpot.frame(base: Vector3, look: Vector3, up: Vector3?): CFrame
	local u = up or Vector3.yAxis
	local right = look:Cross(u)
	if right.Magnitude < 1e-4 then
		right = Vector3.xAxis
	end
	right = right.Unit
	local realUp = right:Cross(look).Unit
	return CFrame.fromMatrix(base, right, realUp)
end

-- Postura sobre el suelo en center mirando hacia look: el plano del suelo (a lo largo: la cuesta;
-- de lado debe ser llano). Devuelve el CFrame (centro a ras de suelo) o nil y por qué no vale.
function RideSpot.fit(world: World, center: Vector3, look: Vector3, size: Vector3, top: number, bottom: number, step: number?): (CFrame?, string?)
	local tolerance = step or RideSpot.Step
	local right = Vector3.new(-look.Z, 0, look.X)
	local hx, hz = size.X * 0.45, size.Z * 0.45
	local rows = {}
	for i, fz in { -1, 0, 1 } do -- -1 = cola, 1 = morro
		local row = {}
		for j, fx in { -1, 0, 1 } do
			local p = center + look * (fz * hz) + right * (fx * hx)
			local y, _, water = world.ground(p.X, p.Z, top, bottom)
			if not y then
				return nil, if water then "agua" else "vacio"
			end
			row[j] = y
		end
		rows[i] = row
	end
	local function mean(row: { number }): number
		return (row[1] + row[2] + row[3]) / 3
	end
	local back, mid, front = mean(rows[1]), mean(rows[2]), mean(rows[3])
	local slope = if hz > 0 then (front - back) / (2 * hz) else 0
	local c = (back + mid + front) / 3
	for i, fz in { -1, 0, 1 } do
		local expected = c + slope * fz * hz
		for j = 1, 3 do
			if math.abs(rows[i][j] - expected) > tolerance then
				return nil, "escalon"
			end
		end
	end
	if math.abs(math.atan(slope)) > RideSpot.MaxTilt then
		return nil, "cuesta"
	end
	local base = Vector3.new(center.X, c, center.Z)
	local forward = (look + Vector3.new(0, slope, 0)).Unit
	return RideSpot.frame(base, forward), nil
end

-- Sitios donde probar, en orden: delante, a los lados, detrás y un poco más lejos
function RideSpot.candidates(look: Vector3, size: Vector3): { Vector3 }
	local right = Vector3.new(-look.Z, 0, look.X)
	local w, l = size.X / 2, size.Z / 2
	return {
		look * 2,
		right * (w + 2),
		-right * (w + 2),
		look * (l + 2),
		-look * (l + 1.5),
		right * (w + 5),
		-right * (w + 5),
		look * (l + 5),
		-look * (l + 4.5),
		right * (w + 2) + look * (l + 2),
		-right * (w + 2) + look * (l + 2),
		right * (w + 8),
		-right * (w + 8),
		look * (l + 9),
	}
end

-- El mejor sitio para sacar un vehículo de este tamaño junto a alguien que está en origin (sus pies
-- a la altura feet) mirando hacia look. nil = no cabe en ningún sitio cerca.
-- Si no hay ningún suelo en ninguna parte (el mundo aún no está), sale delante a la altura de los pies.
function RideSpot.choose(world: World, origin: Vector3, feet: number, look: Vector3, size: Vector3): CFrame?
	local top, bottom = feet + 3, feet - 10
	local anyGround = false
	local best: CFrame?, bestScore = nil, math.huge
	for pass = 1, 2 do
		local tolerance = if pass == 1 then RideSpot.Step else RideSpot.Step * 2
		for i, offset in RideSpot.candidates(look, size) do
			local center = Vector3.new(origin.X, feet, origin.Z) + offset
			local y, axis = world.ground(center.X, center.Z, top, bottom)
			if not y then
				continue
			end
			anyGround = true
			-- A lo largo de la calle (hacia el lado al que mira quien lo saca); fuera de la calzada, hacia donde mira
			local dir = look
			local road = axis ~= nil and flat(axis) ~= nil
			if road then
				local a = flat(axis :: Vector3) :: Vector3
				dir = if a:Dot(look) >= 0 then a else -a
			end
			local cf = RideSpot.fit(world, center, dir, size, top, bottom, tolerance)
			if not cf then
				continue
			end
			if world.clear and not world.clear(Vector3.new(origin.X, feet + 1.6, origin.Z), cf.Position + Vector3.new(0, 1.6, 0)) then
				continue -- (al otro lado de una pared)
			end
			if world.blocked(cf, size) then
				continue
			end
			local score = i + (if road then 0 else 8) + (pass - 1) * 100
			if score < bestScore then
				best, bestScore = cf, score
			end
		end
		if best then
			return best
		end
	end
	if not anyGround then
		local at = Vector3.new(origin.X, feet, origin.Z) + look * 2
		return RideSpot.frame(at, look)
	end
	return nil
end

-- Un sitio libre muy cerca para un vehículo atascado (metido en un murete, una farola o una
-- persona): a los lados primero, luego detrás y delante. Sin atravesar paredes. nil = ninguno.
function RideSpot.unstick(world: World, base: CFrame, size: Vector3): CFrame?
	local look = flat(base.LookVector) or Vector3.new(0, 0, -1)
	local right = Vector3.new(-look.Z, 0, look.X)
	local at = base.Position
	local tries = {}
	for _, d in { 1.5, 3, 4.5 } do
		table.insert(tries, right * d)
		table.insert(tries, -right * d)
	end
	for _, d in { 2.5, 5 } do
		table.insert(tries, -look * d)
		table.insert(tries, look * d)
	end
	for _, d in { 3, 5 } do
		table.insert(tries, right * d - look * d)
		table.insert(tries, -right * d - look * d)
	end
	local top, bottom = at.Y + 3.5, at.Y - 6
	for _, offset in tries do
		local center = at + offset
		local cf = RideSpot.fit(world, center, look, size, top, bottom, RideSpot.Step * 2)
		if cf and not world.blocked(cf, size) then
			if not world.clear or world.clear(at + Vector3.new(0, 1.6, 0), cf.Position + Vector3.new(0, 1.6, 0)) then
				return cf
			end
		end
	end
	return nil
end

-- ¿Se tocan dos cajas vistas desde arriba? (centro, hacia dónde mira, largo y ancho). Separación
-- de ejes con las 4 direcciones de las dos cajas.
function RideSpot.boxesOverlap(aPos: Vector3, aDir: Vector3, aLength: number, aWidth: number, bPos: Vector3, bDir: Vector3, bLength: number, bWidth: number): boolean
	local af = flat(aDir) or Vector3.new(0, 0, -1)
	local bf = flat(bDir) or Vector3.new(0, 0, -1)
	local ar = Vector3.new(-af.Z, 0, af.X)
	local br = Vector3.new(-bf.Z, 0, bf.X)
	local d = Vector3.new(bPos.X - aPos.X, 0, bPos.Z - aPos.Z)
	for _, axis in { af, ar, bf, br } do
		local ra = math.abs(axis:Dot(af)) * aLength / 2 + math.abs(axis:Dot(ar)) * aWidth / 2
		local rb = math.abs(axis:Dot(bf)) * bLength / 2 + math.abs(axis:Dot(br)) * bWidth / 2
		if math.abs(d:Dot(axis)) > ra + rb then
			return false
		end
	end
	return true
end

-- Vigilancia del conductor (Driving, en tu ordenador): el servidor dice que conduces (Riding) pero
-- tu personaje no está sentado al volante. Pasa si la soldadura del asiento llega sin que el
-- personaje se siente: entonces andabas arrastrando el coche medio hundido, con los pedales en
-- pantalla y la velocidad del coche. w = { Since: number?, Asked: string? }.
-- Devuelve "Reseat" (que el servidor te vuelva a sentar), "Dismount" (bajarse del todo) o nil.
RideSpot.ReseatAfter = 1.5
RideSpot.GiveUpAfter = 3.5
function RideSpot.watchSeat(w: { Since: number?, Asked: string? }, now: number, riding: boolean, seated: boolean): string?
	if not riding or seated then
		w.Since, w.Asked = nil, nil
		return nil
	end
	w.Since = w.Since or now
	local waited = now - (w.Since :: number)
	if waited >= RideSpot.GiveUpAfter and w.Asked ~= "Dismount" then
		w.Asked = "Dismount"
		return "Dismount"
	elseif waited >= RideSpot.ReseatAfter and w.Asked == nil then
		w.Asked = "Reseat"
		return "Reseat"
	end
	return nil
end

-- Atasco: pisando el acelerador (o la marcha atrás) sin moverse. speed = lo que se ha movido de
-- verdad (studs/s). Devuelve true cuando toca desatascar. s = { Stuck: number }
RideSpot.StuckAfter = 1.8
function RideSpot.stuckStep(s: { Stuck: number }, wantThrottle: number, speed: number, dt: number): boolean
	if math.abs(wantThrottle) > 0.3 and speed < 0.8 then
		s.Stuck += dt
	else
		s.Stuck = math.max(0, s.Stuck - dt * 2)
	end
	if s.Stuck >= RideSpot.StuckAfter then
		s.Stuck = 0
		return true
	end
	return false
end

return RideSpot
