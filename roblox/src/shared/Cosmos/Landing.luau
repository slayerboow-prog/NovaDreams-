-- Landing: aterrizar y despegar la nave en un planeta (cuentas puras; docs/planetas.md). Lo usa
-- Controllers/AirCombatClient alrededor de shared/AirCombat/ShipFlight cuando vuelas en una superficie
-- (World = "Planet"). Pensado para el móvil: no hay botón de aterrizar.
--
--   "Flying"   vuelo normal (ShipFlight). Cerca del suelo (GearAGL) sale el tren de aterrizaje. Si vas
--              DESPACIO (frena o suelta el motor), BAJO (AutoAGL), sobre suelo llano (MaxSlope) y no
--              sobre el agua →
--   "Landing"  la nave se nivela y se posa sola en LandTime segundos (aterrizaje suave) →
--   "Landed"   quieta en el suelo: «BAJAR» (Salir) te baja de la nave. Para irte: palanca hacia arriba
--              (sube el morro), W / motor arriba o TURBO →
--   "TakeOff"  sube recta TakeOffTime segundos (despegue vertical) y vuelve a "Flying" con velocidad.
-- El servidor no necesita saber la fase: comprueba la posición como siempre (AirCombatService) y, para
-- bajarte, que la nave esté quieta y pegada al suelo (Services/PlanetService).

local Landing = {}

Landing.GearAGL = 70 -- (studs sobre el suelo) baja el tren
Landing.AutoAGL = 28 -- por debajo, se posa sola si va despacio
Landing.AutoSpeed = 80 -- studs/s
Landing.MaxSlope = 0.4
Landing.RestHeight = 4.6 -- el centro de la nave sobre el suelo, posada (con el tren)
Landing.LandTime = 1.3
Landing.TakeOffTime = 1.5
Landing.TakeOffRise = 26 -- studs que sube recta al despegar
Landing.TakeOffSpeed = 70 -- velocidad al acabar el despegue
Landing.Cooldown = 2.5 -- tras despegar, no vuelve a posarse en estos segundos

export type State = {
	Phase: string,
	T: number,
	Cool: number,
	FromPos: Vector3?,
	FromRot: CFrame?,
	FromSpeed: number,
	Gear: boolean,
}

-- ground(x, z) -> (altura del suelo, ¿agua?, pendiente)
export type Ground = (number, number) -> (number, boolean, number)

function Landing.new(landed: boolean?): State
	return { Phase = if landed then "Landed" else "Flying", T = 0, Cool = 0, FromPos = nil, FromRot = nil, FromSpeed = 0, Gear = landed == true }
end

local Y = Vector3.new(0, 1, 0)

-- Orientación nivelada con el mismo rumbo
function Landing.level(rot: CFrame): CFrame
	local look = rot.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 1e-3 then
		flat = Vector3.new(-rot.UpVector.X, 0, -rot.UpVector.Z)
		if flat.Magnitude < 1e-3 then
			flat = Vector3.new(0, 0, -1)
		end
	end
	flat = flat.Unit
	local right = flat:Cross(Y).Unit
	return CFrame.fromMatrix(Vector3.zero, right, Y, -flat)
end

local function ease(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

-- ¿Puede posarse aquí y así?
function Landing.canAutoLand(sim: { [string]: any }, ground: Ground): boolean
	local h, water, slope = ground(sim.Pos.X, sim.Pos.Z)
	local agl = sim.Pos.Y - h
	return agl < Landing.AutoAGL and agl > -2 and sim.Speed < Landing.AutoSpeed and not water and slope <= Landing.MaxSlope and sim.Rot.LookVector.Y > -0.6
end

-- ¿Quiere despegar? (palanca arriba, motor arriba o turbo)
function Landing.wantsTakeOff(inp: { [string]: any }): boolean
	return (inp.Pitch or 0) > 0.45 or (inp.Throttle or 0) > 0.3 or inp.Boost == true
end

-- Un fotograma. Devuelve true si la fase ya movió la nave (y no hay que llamar a ShipFlight.advance),
-- y el suceso ("Gear", "Touchdown", "TakeOff", "Airborne") si lo hay.
function Landing.step(L: State, sim: { [string]: any }, inp: { [string]: any }, dt: number, ground: Ground): (boolean, string?)
	L.T += dt
	L.Cool = math.max(0, L.Cool - dt)
	local h, water = ground(sim.Pos.X, sim.Pos.Z)
	local agl = sim.Pos.Y - h
	if L.Phase == "Flying" then
		local gear = agl < Landing.GearAGL and not water
		local ev = nil
		if gear ~= L.Gear then
			L.Gear = gear
			ev = "Gear"
		end
		if L.Cool <= 0 and Landing.canAutoLand(sim, ground) then
			L.Phase, L.T = "Landing", 0
			L.FromPos, L.FromRot, L.FromSpeed = sim.Pos, sim.Rot, sim.Speed
			L.Gear = true
			return true, "Landing"
		end
		return false, ev
	elseif L.Phase == "Landing" then
		local k = ease(L.T / Landing.LandTime)
		local from = L.FromPos :: Vector3
		local look = (L.FromRot :: CFrame).LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		local drift = if flat.Magnitude > 1e-3 then flat.Unit * L.FromSpeed * Landing.LandTime * 0.35 else Vector3.zero
		local target = from + drift * k
		local gh = ground(target.X, target.Z)
		local y = from.Y + (gh + Landing.RestHeight - from.Y) * k
		sim.Pos = Vector3.new(target.X, y, target.Z)
		local level = Landing.level(L.FromRot :: CFrame)
		sim.Rot = (L.FromRot :: CFrame):Lerp(level, k)
		sim.Speed = L.FromSpeed * (1 - k)
		sim.Sink = 0
		if L.T >= Landing.LandTime then
			L.Phase, L.T = "Landed", 0
			sim.Speed = 0
			sim.Rot = level
			sim.Pos = Vector3.new(sim.Pos.X, gh + Landing.RestHeight, sim.Pos.Z)
			return true, "Touchdown"
		end
		return true, nil
	elseif L.Phase == "Landed" then
		sim.Speed = 0
		sim.Sink = 0
		sim.Pos = Vector3.new(sim.Pos.X, h + Landing.RestHeight, sim.Pos.Z)
		if Landing.wantsTakeOff(inp) then
			L.Phase, L.T = "TakeOff", 0
			L.FromPos, L.FromRot = sim.Pos, Landing.level(sim.Rot)
			return true, "TakeOff"
		end
		-- (en tierra se puede girar despacio con la palanca)
		local yaw = math.clamp(inp.Yaw or 0, -1, 1)
		if math.abs(yaw) > 0.1 then
			sim.Rot = CFrame.Angles(0, -yaw * 0.9 * dt, 0) * sim.Rot
		end
		return true, nil
	elseif L.Phase == "TakeOff" then
		local k = ease(L.T / Landing.TakeOffTime)
		local from = L.FromPos :: Vector3
		sim.Pos = from + Vector3.new(0, Landing.TakeOffRise * k, 0)
		sim.Rot = (L.FromRot :: CFrame) * CFrame.Angles(0.12 * k, 0, 0)
		sim.Speed = Landing.TakeOffSpeed * k
		sim.Sink = 0
		if L.T >= Landing.TakeOffTime then
			L.Phase, L.T = "Flying", 0
			L.Cool = Landing.Cooldown
			sim.Speed = Landing.TakeOffSpeed + 20
			sim.Throttle = math.max(sim.Throttle or 0, 0.5)
			return true, "Airborne"
		end
		return true, nil
	end
	return false, nil
end

-- ¿Posada? (para el botón BAJAR)
function Landing.landed(L: State?): boolean
	return L ~= nil and L.Phase == "Landed"
end

return Landing
