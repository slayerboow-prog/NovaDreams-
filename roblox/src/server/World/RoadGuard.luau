-- RoadGuard (servidor): las calles para shared/Crossing con lo que ve el servidor.
--   * RoadGuard.world(): las calles publicadas (ReplicatedStorage.Ambient.Roads) y sus cruces con
--     semáforo (los mismos que ven los clientes), leídas una vez.
--   * RoadGuard.judge(...): ¿atropello con culpa de quien conduce? (KnockService), con la hora del
--     servidor (la de los semáforos), la posición del peatón y el coche según el servidor.
--   * RoadGuard.mustWait(from, to, speed): un personaje del servidor que anda (Npc.walkTo, las
--     escenas) no baja a la calzada si su semáforo no le deja o viene un vehículo de un jugador.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crossing = require(ReplicatedStorage.Shared.Crossing)
local CityPlan = require(ReplicatedStorage.Shared.CityPlan)

local RoadGuard = {}

local cached: Crossing.World? = nil
local cachedFrom: Instance? = nil

-- Las calles (nil hasta que el mundo las publica)
function RoadGuard.world(): Crossing.World?
	local data = ReplicatedStorage:FindFirstChild("Ambient")
	local roads = data and data:FindFirstChild("Roads")
	if not roads then
		return nil
	end
	if cached and cachedFrom == roads then
		return cached
	end
	local rings = {}
	for _, rb in CityPlan.Roundabouts or {} do
		table.insert(rings, Vector3.new(rb[1], 0, rb[2]))
	end
	local ok, built = pcall(Crossing.fromFolder, roads, rings)
	if not ok then
		return nil
	end
	cached, cachedFrom = built, roads
	return built
end

-- Para las pruebas (o si el mapa cambia)
function RoadGuard.reset()
	cached, cachedFrom = nil, nil
end

function RoadGuard.now(): number
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	return if ok and type(t) == "number" then t else os.clock()
end

-- ¿Culpa de quien conduce? Sin calles publicadas (no debería pasar) se juzga como antes: sí.
function RoadGuard.judge(ped: Vector3, carPos: Vector3, carVel: Vector3, claim: Crossing.Claim?): Crossing.Verdict
	local world = RoadGuard.world()
	local now = RoadGuard.now()
	if not world then
		return { Fault = true, Reason = "NoRoads", Zone = "Sidewalk", Signal = "None", PedWalk = false, Rejected = false, At = now }
	end
	return Crossing.judge(world, ped, carPos, carVel, now, claim)
end

-- Vehículos de los jugadores que se mueven (lo único que circula en el servidor por las calles con
-- gente: el tráfico de ambiente es de cada pantalla)
function RoadGuard.vehicles(): { Crossing.Mover }
	local list = {}
	for _, p in Players:GetPlayers() do
		local character = p.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local seat = humanoid and humanoid.SeatPart
		if seat then
			table.insert(list, { Pos = seat.Position, Vel = seat.AssemblyLinearVelocity })
		end
	end
	return list
end

-- ¿Tiene que esperar en el bordillo antes de andar de from a to a `speed`?
function RoadGuard.mustWait(from: Vector3, to: Vector3, speed: number): boolean
	local world = RoadGuard.world()
	if not world or from.Y > 200 or to.Y > 200 then
		return false -- (sin calles, o en un interior / en lo alto: no hay calzada)
	end
	return Crossing.mustWait(world, from, to, speed, RoadGuard.now(), RoadGuard.vehicles())
end

-- Antes de un tramo de from a to: si baja a la calzada lejos de from, el punto del bordillo donde
-- parar a mirar (kerb); si la pisa ya mismo, crosses = true (hay que mirar antes de seguir).
function RoadGuard.kerb(from: Vector3, to: Vector3): (Vector3?, boolean)
	local world = RoadGuard.world()
	if not world or from.Y > 200 or to.Y > 200 then
		return nil, false
	end
	local leg = Crossing.legAcross(world, from, to)
	if not leg then
		return nil, false
	end
	local flatTo = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	local toEntry = Vector3.new(leg.Entry.X - from.X, 0, leg.Entry.Z - from.Z).Magnitude
	if toEntry > 4 and flatTo.Magnitude > 0.1 then
		local k = (toEntry - 3) / flatTo.Magnitude
		return from:Lerp(to, k), true
	end
	return nil, true
end

-- Espera (como mucho maxWait segundos) a poder cruzar. Devuelve si al final puede.
-- stillValid: si deja de valer (otro paseo manda), se deja de esperar.
function RoadGuard.waitToCross(from: Vector3, to: Vector3, speed: number, maxWait: number?, stillValid: (() -> boolean)?): boolean
	local limit = os.clock() + (maxWait or 40)
	while RoadGuard.mustWait(from, to, speed) do
		if os.clock() > limit or (stillValid and not stillValid()) then
			return false
		end
		task.wait(0.3)
	end
	return true
end

return RoadGuard
