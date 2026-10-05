-- SafeGround: que nadie se quede BAJO TIERRA, dentro de una pared o atrapado sin poder moverse.
-- Cuentas puras (sin servicios de Roblox): las prueba scripts/test-underground.luau. Lo que mira el
-- mundo de verdad (rayos, piezas, terreno) está en server/World/SafeSpot.
--
--   SafeGround.validSaved(saved, minY)   ¿Un sitio guardado { X, Y, Z } vale? (números de verdad, no
--                                        NaN ni enormes, y por encima de minY)
--   SafeGround.candidates(center)        Puntos donde probar a ponerte, del más cerca al más lejos
--   SafeGround.findSpot(center, world)   El primer sitio libre con suelo debajo (world da el suelo y si
--                                        cabes de pie) -> pies, o nil
--   SafeGround.dropPoint(from, me, dist) Dónde dejarte cuando algo te atrapa: a dist studs, lejos de él
--   SafeGround.track(state, buried, now) ¿Lleva enterrado el tiempo suficiente para rescatarle?
--   SafeGround.repairSaved(data, minY)   Arregla al cargar una partida rota (sitio NaN, bajo el mapa…)
--   SafeGround.cleanProgress(prog)       Quita de una misión guardada lo que no debe sobrevivir a un
--                                        guardado (estar en plena captura)
--   SafeGround.restoreHumanoid(h, d)     Lo que hay que devolverle a un humanoide para que ande

local SafeGround = {}

SafeGround.BuriedSeconds = 2 -- enterrado (o dentro de algo sólido) más que esto: se le saca
SafeGround.CheckEvery = 0.5 -- cada cuánto se mira a cada jugador
SafeGround.ReleaseSeconds = 2.5 -- tras una captura, a los segundos se comprueba que está libre
SafeGround.CatchCooldown = 6 -- tras atraparte, el que te persigue descansa y se aparta
SafeGround.StartGrace = 4 -- al empezar una persecución, unos segundos antes de que pueda atraparte
SafeGround.DropDistance = 12 -- a cuántos studs te deja quien te atrapa
SafeGround.SafeMinY = -150 -- más abajo no hay nada del mapa (el metro más hondo está a -66)
SafeGround.Radii = { 0, 4, 8, 12, 18, 26, 36, 50 }
SafeGround.Angles = 8
-- Desde qué altura (sobre el punto) se busca el suelo: primero justo encima en todos los puntos
-- (dentro de un edificio daría con el techo si se mira desde muy arriba), luego más arriba (si
-- estás enterrado, el suelo de verdad está por encima de ti)
SafeGround.Heights = { 4, 14, 40 }

-- Fuerzas que no pueden faltar para andar (los de Roblox por defecto)
SafeGround.Defaults = { WalkSpeed = 16, JumpPower = 50, JumpHeight = 7.2 }

local function finite(n: any): boolean
	return type(n) == "number" and n == n and math.abs(n) < 1e6
end

function SafeGround.validSaved(saved: any, minY: number?): boolean
	if type(saved) ~= "table" then
		return false
	end
	if not (finite(saved.X) and finite(saved.Y) and finite(saved.Z)) then
		return false
	end
	if saved.Yaw ~= nil and not finite(saved.Yaw) then
		return false
	end
	return saved.Y > (minY or SafeGround.SafeMinY)
end

-- Del más cercano al más lejano: el centro y luego anillos alrededor
function SafeGround.candidates(center: Vector3, radii: { number }?, angles: number?): { Vector3 }
	local list = {}
	local n = angles or SafeGround.Angles
	for ring, r in radii or SafeGround.Radii do
		if r <= 0 then
			table.insert(list, center)
		else
			local turn = (ring % 2) * math.pi / n -- (cada anillo un poco girado: no siempre la misma línea)
			for i = 0, n - 1 do
				local a = turn + i * 2 * math.pi / n
				table.insert(list, Vector3.new(center.X + math.cos(a) * r, center.Y, center.Z + math.sin(a) * r))
			end
		end
	end
	return list
end

export type World = {
	-- Altura del suelo de verdad bajo (x, z) mirando desde fromY hacia abajo (nil: no hay)
	groundAt: (x: number, z: number, fromY: number) -> number?,
	-- ¿Cabe alguien de pie con los pies en este punto? (nada sólido en el cuerpo)
	free: (feet: Vector3) -> boolean,
}

-- El primer sitio libre con suelo debajo, cerca de center -> los pies (o nil si no hay ninguno)
function SafeGround.findSpot(center: Vector3, world: World, minY: number?): Vector3?
	local floor = minY or SafeGround.SafeMinY
	local list = SafeGround.candidates(center)
	local tried: { [string]: boolean } = {}
	-- Por pasadas: primero el suelo a tu altura en todos los puntos cercanos (si el centro es el
	-- silo, mejor al lado del silo que encima de su tejado); solo si no hay, desde más arriba
	for _, h in SafeGround.Heights do
		for i, c in list do
			local y = world.groundAt(c.X, c.Z, c.Y + h)
			local key = i .. ":" .. math.floor((y or 0) * 4)
			if y and y > floor and not tried[key] then
				tried[key] = true
				local feet = Vector3.new(c.X, y, c.Z)
				if world.free(feet) then
					return feet
				end
			end
		end
	end
	return nil
end

-- Dónde dejarte cuando te atrapa algo que está en "from": a dist studs de ti, en dirección contraria
function SafeGround.dropPoint(from: Vector3, me: Vector3, dist: number?): Vector3
	local d = dist or SafeGround.DropDistance
	local away = Vector3.new(me.X - from.X, 0, me.Z - from.Z)
	if away.Magnitude < 0.1 then
		away = Vector3.new(1, 0, 0)
	end
	return me + away.Unit * d
end

-- Llevar la cuenta de cuánto rato lleva enterrado: true cuando toca rescatarle
function SafeGround.track(state: { [string]: any }, buried: boolean, now: number, seconds: number?): boolean
	if not buried then
		state.Since = nil
		return false
	end
	state.Since = state.Since or now
	return now - state.Since >= (seconds or SafeGround.BuriedSeconds)
end

-- Al cargar: un sitio guardado roto (NaN, debajo del mapa, sin números) se tira, y el jugador aparece
-- en su cama o en la entrada. Devuelve la lista de lo que se ha arreglado.
function SafeGround.repairSaved(data: { [string]: any }, minY: number?): { string }
	local fixed = {}
	if data.Position ~= nil and not SafeGround.validSaved(data.Position, minY) then
		data.Position = nil
		table.insert(fixed, "Position")
	end
	if data.SpawnPoint ~= nil and not SafeGround.validSaved(data.SpawnPoint, minY) then
		data.SpawnPoint = nil
		table.insert(fixed, "SpawnPoint")
	end
	return fixed
end

-- Campos de una misión que solo valen mientras pasa (una captura a medias): no se cargan nunca
SafeGround.TransientProgress = { "Grabbed", "GrabbedAt", "CaughtAt", "Stuck", "Frozen", "Held" }

function SafeGround.cleanProgress(prog: any): boolean
	if type(prog) ~= "table" then
		return false
	end
	local changed = false
	for _, key in SafeGround.TransientProgress do
		if prog[key] ~= nil then
			prog[key] = nil
			changed = true
		end
	end
	return changed
end

-- Qué cambiar en un humanoide atascado (quieto a la fuerza, sin saltar, tumbado, anclado) para que
-- vuelva a andar. h = { WalkSpeed, JumpPower, JumpHeight, UseJumpPower, PlatformStand, Sit,
-- Anchored }; base = la velocidad que debería tener (nil: la de Roblox). Devuelve los cambios.
function SafeGround.restoreHumanoid(h: { [string]: any }, base: { [string]: any }?): { [string]: any }
	local want = base or {}
	local changes = {}
	if type(h.WalkSpeed) ~= "number" or h.WalkSpeed < 1 then
		changes.WalkSpeed = want.WalkSpeed or SafeGround.Defaults.WalkSpeed
	end
	if h.UseJumpPower then
		if type(h.JumpPower) ~= "number" or h.JumpPower < 1 then
			changes.JumpPower = want.JumpPower or SafeGround.Defaults.JumpPower
		end
	elseif type(h.JumpHeight) ~= "number" or h.JumpHeight < 0.5 then
		changes.JumpHeight = want.JumpHeight or SafeGround.Defaults.JumpHeight
	end
	if h.PlatformStand then
		changes.PlatformStand = false
	end
	if h.Sit then
		changes.Sit = false
	end
	if h.Anchored then
		changes.Anchored = false
	end
	return changes
end

return SafeGround
