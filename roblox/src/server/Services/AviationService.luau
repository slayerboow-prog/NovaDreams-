-- AviationService: los aviones que pilotan los jugadores (Shared/Airport.PilotPlanes, Shared/Flight).
--
-- Cómo se consigue volar:
--   * Aeroclub (mostrador en el hangar del Aeropuerto de Valmar, tag Aeroclub; se entra por la puerta
--     del fondo, junto a la torre). Su menú:
--       1) Curso de piloto: teórico de 5 preguntas (hay que acertar 4) por CoursePrice.
--       2) Clase práctica (gratis, con el teórico aprobado): despega en una avioneta del aeroclub, sube
--          por encima de LessonAltitude y aterriza suave en la pista de Valmar. Al aprobar: licencia de
--          piloto (data.Licenses.Piloto, como los carnets de la autoescuela).
--       3) Alquilar avioneta (RentPrice): con licencia. Es tuya hasta que la dejas en el hangar, te
--          vas del juego o la dejas sola ReturnAfter segundos (vuelve sola al hangar).
--       4) Avión de línea de prácticas (EC-VLA, en la plataforma): con licencia y JetLandings
--          aterrizajes suaves en avioneta (la «habilitación de reactor»).
--     Hay que ser mayor de edad (Gameplay.LicenseStage). El modo pruebas se lo salta todo.
--   * Los mismos aviones tienen el cartel «Pilotar» (y «Subir a bordo» para ir de pasajero, en tierra).
--   * Los aviones de los vuelos con horario (FlightService) no se pilotan nunca: son otros.
--
-- En vuelo: el ordenador del piloto mueve el avión (Controllers/Flying con Shared/Flight; es dueño de
-- sus piezas, SetNetworkOwner) y avisa aquí del tren, los flaps, si va en el aire, los aterrizajes
-- y los accidentes. El servidor vigila cada VALIDATE segundos que no salte de golpe (velocidad
-- imposible: vuelve al último sitio bueno), que no atraviese edificios (accidente) y que no se vaya
-- del mapa. Accidente: explosión y humo donde cayó, quien iba dentro se hace daño (nunca muere) y le
-- rescatan al aeroclub; el avión vuelve a su sitio y queda en revisión DownTime segundos.
-- Datos guardados: data.Licenses.Piloto (VehicleService.grantLicense) y data.Aviation
-- ({ Theory, Landings }).

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Airport = require(ReplicatedStorage.Shared.Airport)
local Flight = require(ReplicatedStorage.Shared.Flight)
local Format = require(ReplicatedStorage.Shared.Format)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Ground = require(ReplicatedStorage.Shared.Ground)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local Builder = require(script.Parent.Parent.World.Builder)
local AirportKit = require(script.Parent.Parent.World.Kit.Airport)
local DataService = require(script.Parent.DataService)
local TesterService = require(script.Parent.TesterService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local AviationService = {}

AviationService.RentPrice = 60
AviationService.CoursePrice = 150
AviationService.JetLandings = 3
AviationService.LessonAltitude = 250 -- studs sobre la pista (unos 70 m)
AviationService.ReturnAfter = 45
AviationService.DownTime = 20
AviationService.License = "Piloto"
local VALIDATE = 0.25

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes:FindFirstChild("Aviation") :: RemoteEvent?

type Plane = {
	Spec: { [string]: any },
	Model: Model,
	Root: BasePart,
	PilotSeat: Seat,
	Seats: { Seat },
	Board: BasePart?,
	Pilot: Player?,
	Renter: Player?,
	Lesson: { Climbed: boolean }?,
	Passengers: { [Player]: Seat },
	Airborne: boolean,
	Gear: boolean,
	Flaps: number,
	Speed: number,
	Health: number,
	LastPos: Vector3?,
	LastGood: CFrame?,
	LeftAt: number?, -- cuándo se quedó sin piloto lejos de su sitio
	DownUntil: number, -- en revisión tras un accidente
	Collide: { [BasePart]: boolean },
	SeatConn: RBXScriptConnection?,
	Pilots: number, -- (para saber si el piloto que se fue es el de ahora)
}

local planes: { [string]: Plane } = {}
local piloting: { [Player]: Plane } = {}
local riding: { [Player]: Plane } = {}
type Session = { Token: string, Correct: { number }?, Keys: { string }? }
local sessions: { [Player]: Session } = {}
local lastState: { [Player]: number } = {}

-- Preguntas del teórico: { pregunta, { correcta, otra, otra } }
AviationService.Questions = {
	{ "¿Qué pasa si vuelas más despacio que la velocidad de pérdida?", { "El ala deja de sostener el avión y el morro cae", "El avión sube más rápido", "No pasa nada" } },
	{ "¿Para qué sirven los flaps?", { "Para volar más despacio sin entrar en pérdida (despegar y aterrizar)", "Para ir más rápido en crucero", "Para girar en tierra" } },
	{ "¿De qué color es la luz de navegación del ala izquierda?", { "Roja", "Verde", "Blanca" } },
	{ "¿Cuándo se levanta el morro para despegar?", { "Al pasar la velocidad de rotación (Vr)", "Nada más arrancar el motor", "Cuando se acaba la pista" } },
	{ "Al aterrizar, ¿cómo hay que tocar la pista?", { "Con el tren bajado, las alas niveladas y bajando despacio", "En picado para frenar antes", "Con un ala primero" } },
	{ "Si subes con el morro muy alto y poco motor…", { "Pierdes velocidad y puedes entrar en pérdida", "Ganas velocidad", "El avión se para en el aire sin caer" } },
	{ "¿Qué hace el timón de dirección (Q / E)?", { "Gira el morro a izquierda o derecha", "Sube y baja el tren", "Cambia los flaps" } },
	{ "Al inclinar las alas a un lado, el avión…", { "Gira hacia ese lado", "Sube recto", "Frena en seco" } },
	{ "¿Qué se hace antes de entrar en la pista?", { "Mirar que no venga ningún avión aterrizando", "Poner el motor al mínimo y salir del avión", "Subir el tren" } },
}
AviationService.ToPass = 4

local function service(name: string): any
	local ok, result = pcall(function()
		return require(script.Parent[name])
	end)
	return if ok then result else nil
end

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function aviation(player: Player): { [string]: any }?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	if type(data.Aviation) ~= "table" then
		data.Aviation = { Theory = false, Landings = 0 }
	end
	local a = data.Aviation
	a.Landings = if type(a.Landings) == "number" then a.Landings else 0
	a.Theory = a.Theory == true
	return a
end

function AviationService.hasLicense(player: Player): boolean
	local data = DataService.get(player)
	return data ~= nil and type(data.Licenses) == "table" and data.Licenses[AviationService.License] == true
end

local function bypass(player: Player): boolean
	return TesterService.bypass(player)
end

local function adult(player: Player): boolean
	return Stages.allows(player:GetAttribute("LifeStage"), "Fly", { Fly = Gameplay.LicenseStage }) or bypass(player)
end

local function held(player: Player): boolean
	return player:GetAttribute("JailUntil") ~= nil or player:GetAttribute("OnTrial") ~= nil or player:GetAttribute("Dead") ~= nil
end

local function home(plane: Plane): CFrame
	return Airport.rootCFrame(plane.Spec.Kind, plane.Spec.Pose)
end

local function atHome(plane: Plane): boolean
	return (plane.Root.Position - home(plane).Position).Magnitude < 25
end

local function setActivity(player: Player, text: string?, target: Vector3?)
	player:SetAttribute("ActivityText", text)
	player:SetAttribute("TaskTarget", target)
end

---------------------------------------------------------------------
-- Aspecto: tren, hélice, choques de las piezas
---------------------------------------------------------------------
local function showGear(plane: Plane, down: boolean)
	plane.Gear = down
	plane.Model:SetAttribute("GearDown", down)
	for _, d in plane.Model:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("Gear") then
			d.Transparency = if down then 0 else 1
		end
	end
end

local function setEngine(plane: Plane, on: boolean)
	plane.Model:SetAttribute("EngineOn", on)
	for _, d in plane.Model:GetDescendants() do
		if d:IsA("BasePart") then
			local prop = d:GetAttribute("Prop")
			if prop == "Blade" then
				d.Transparency = if on then 1 else 0
			elseif prop == "Disc" then
				d.Transparency = if on then 0.72 else 1
			end
		end
	end
end

-- En vuelo ninguna pieza choca (los choques los mira Shared/Flight con rayos); aparcado, sí
local function setSolid(plane: Plane, solid: boolean)
	for part, collide in plane.Collide do
		part.CanCollide = solid and collide
	end
end

---------------------------------------------------------------------
-- Aparcar, volver al hangar
---------------------------------------------------------------------
local function anchorAt(plane: Plane, cf: CFrame)
	plane.Root.Anchored = true
	plane.Model:PivotTo(cf)
	plane.Root.AssemblyLinearVelocity = Vector3.zero
	plane.Root.AssemblyAngularVelocity = Vector3.zero
end

local function leavePassenger(player: Player, place: boolean?)
	local plane = riding[player]
	if not plane then
		return
	end
	local seat = plane.Passengers[player]
	plane.Passengers[player] = nil
	riding[player] = nil
	local humanoid = humanoidOf(player)
	if humanoid and seat and humanoid.SeatPart == seat then
		humanoid.Sit = false
	end
	if seat then
		local weld = seat:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
	end
	if place and plane.Board and player.Character then
		local spot = plane.Board.Position
		local hit = Ground.cast(spot + Vector3.new(0, 8, 0), Vector3.new(0, -30, 0))
		player.Character:PivotTo(CFrame.new(if hit then hit.Position + Vector3.new(0, 3, 0) else spot + Vector3.new(0, 2, 0)))
	end
end

local function returnHome(plane: Plane)
	for player in table.clone(plane.Passengers) do
		leavePassenger(player, true)
	end
	if plane.Renter then
		local renter = plane.Renter
		plane.Renter = nil
		if renter.Parent then
			Notify:FireClient(renter, "Info", ("🛩️ La %s ha vuelto al hangar del aeroclub."):format(string.lower(Airport.Kinds[plane.Spec.Kind].Name)))
		end
	end
	plane.Lesson = nil
	plane.LeftAt = nil
	plane.Airborne = false
	plane.Health = 100
	plane.Model:SetAttribute("Airborne", false)
	plane.Model:SetAttribute("Renter", nil)
	pcall(function()
		plane.Root:SetNetworkOwner(nil)
	end)
	anchorAt(plane, home(plane))
	showGear(plane, true)
	setEngine(plane, false)
	setSolid(plane, true)
end

-- Deja de pilotar (sea por lo que sea). place = ponerle de pie junto al avión
local function endPilot(plane: Plane, place: boolean?)
	local player = plane.Pilot
	if not player then
		return
	end
	plane.Pilot = nil
	piloting[player] = nil
	lastState[player] = nil
	plane.Model:SetAttribute("Pilot", nil)
	player:SetAttribute("Piloting", nil)
	if plane.Lesson then
		setActivity(player, nil, nil)
	end
	local humanoid = humanoidOf(player)
	local seat = plane.PilotSeat
	local weld = seat:FindFirstChild("SeatWeld")
	if weld then
		weld:Destroy()
	end
	if humanoid and humanoid.SeatPart == seat then
		humanoid.Sit = false
	end
	if player.Parent and Remote then
		Remote:FireClient(player, "Off", {})
	end
	setEngine(plane, false)
	-- Aparcado donde lo deja (quieto, sobre sus ruedas)
	local cf = plane.Root.CFrame
	pcall(function()
		plane.Root:SetNetworkOwner(nil)
	end)
	plane.Root.Anchored = true
	local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
	if look.Magnitude > 0.1 then
		local pose = CFrame.new(cf.Position - Vector3.new(0, Airport.Kinds[plane.Spec.Kind].FloorY - 0.3, 0)) * CFrame.Angles(0, math.atan2(-look.X, -look.Z), 0)
		local hit = Ground.cast(pose.Position + Vector3.new(0, 4, 0), Vector3.new(0, -20, 0))
		if hit then
			pose = pose - pose.Position + hit.Position
		end
		anchorAt(plane, Airport.rootCFrame(plane.Spec.Kind, pose * CFrame.new(0, 0, -Airport.Kinds[plane.Spec.Kind].RootZ)))
	end
	setSolid(plane, true)
	if place and player.Character and plane.Board then
		local spot = plane.Board.Position
		local hit = Ground.cast(spot + Vector3.new(0, 8, 0), Vector3.new(0, -30, 0))
		player.Character:PivotTo(CFrame.new(if hit then hit.Position + Vector3.new(0, 3, 0) else spot + Vector3.new(0, 2, 0)))
	end
	plane.Lesson = nil
	if atHome(plane) then
		returnHome(plane) -- (lo ha dejado en el hangar: alquiler terminado)
	else
		plane.LeftAt = os.clock()
	end
end

---------------------------------------------------------------------
-- Accidentes
---------------------------------------------------------------------
local function rescue(player: Player)
	local humanoid = humanoidOf(player)
	if humanoid and (humanoid.Health or 0) > 0 then
		humanoid.Health = math.max(10, humanoid.Health - 40) -- se hace daño, pero nunca muere
	end
	local desk = nil
	for _, d in CollectionService:GetTagged("Aeroclub") do
		if d:IsA("BasePart") then
			desk = d
		end
	end
	local character = player.Character
	if desk and character and not held(player) then
		pcall(function()
			player:RequestStreamAroundAsync(desk.Position, 5)
		end)
		character:PivotTo(CFrame.new(desk.Position + Vector3.new(0, 1, 4)))
	end
end

function AviationService.crash(plane: Plane, reason: string)
	local at = plane.Root.Position
	-- Explosión (sin daño ni empujón: solo se ve) y humo un rato donde ha caído
	local boom = Instance.new("Explosion")
	boom.Position = at
	boom.BlastPressure = 0
	boom.BlastRadius = 1
	boom.DestroyJointRadiusPercent = 0
	boom.ExplosionType = Enum.ExplosionType.NoCraters
	boom.Parent = workspace
	local wreck = Builder.decor({ Name = "PlaneWreckSmoke", Size = Vector3.new(4, 4, 4), CFrame = CFrame.new(at), Transparency = 1, Parent = workspace })
	local fire = Instance.new("Fire")
	fire.Size = 14
	fire.Heat = 12
	fire.Parent = wreck
	local smoke = Instance.new("Smoke")
	smoke.Size = 18
	smoke.RiseVelocity = 8
	smoke.Opacity = 0.35
	smoke.Parent = wreck
	Debris:AddItem(wreck, 10)
	local pilot = plane.Pilot
	local aboard = {}
	if pilot then
		table.insert(aboard, pilot)
	end
	for player in plane.Passengers do
		table.insert(aboard, player)
	end
	local lesson = plane.Lesson ~= nil
	if pilot then
		endPilot(plane, false)
	end
	for _, player in aboard do
		leavePassenger(player, false)
		if player.Parent then
			Notify:FireClient(player, "Error", ("💥 ¡Accidente! %s. Te rescatan y te llevan al aeroclub."):format(reason))
			if Remote then
				Remote:FireClient(player, "Crash", { At = at, Reason = reason })
			end
			rescue(player)
		end
	end
	if lesson and pilot and pilot.Parent then
		Notify:FireClient(pilot, "Info", "Clase práctica suspendida. Puedes repetirla gratis en el aeroclub.")
	end
	returnHome(plane)
	plane.DownUntil = os.clock() + AviationService.DownTime
	if pilot then
		StoryEvents.emit(pilot, "PlaneCrashed", { Plane = plane.Spec.Id })
	end
end

---------------------------------------------------------------------
-- Subir: piloto y pasajeros
---------------------------------------------------------------------
-- ¿Puede pilotar este avión? (y por qué no)
function AviationService.canPilot(player: Player, plane: Plane, lesson: boolean?): (boolean, string?)
	if not adult(player) then
		return false, "Para pilotar hay que ser mayor de edad ✈️"
	end
	if bypass(player) then
		return true, nil
	end
	if plane.Spec.Kind == "Avion" then
		local a = aviation(player)
		if not AviationService.hasLicense(player) then
			return false, "Necesitas la licencia de piloto (curso en el aeroclub del hangar)."
		elseif not a or a.Landings < AviationService.JetLandings then
			return false, ("Para el avión de línea necesitas %d aterrizajes suaves en avioneta (llevas %d)."):format(AviationService.JetLandings, if a then a.Landings else 0)
		end
		return true, nil
	end
	if AviationService.hasLicense(player) then
		return true, nil
	end
	local a = aviation(player)
	if lesson and a and a.Theory then
		return true, nil
	end
	if a and a.Theory then
		return false, "Te falta la clase práctica: pídela en el mostrador del aeroclub."
	end
	return false, "Necesitas la licencia de piloto: haz el curso en el mostrador del aeroclub (en el hangar)."
end

local function freeSeat(plane: Plane): Seat?
	local taken = {}
	for _, seat in plane.Passengers do
		taken[seat] = true
	end
	for _, seat in plane.Seats do
		if not taken[seat] and not seat.Occupant then
			return seat
		end
	end
	return nil
end

local function sitIn(player: Player, seat: Seat): boolean
	local humanoid = humanoidOf(player)
	local root = rootOf(player)
	if not humanoid or not root or (humanoid.Health or 0) <= 0 then
		return false
	end
	local vs = service("VehicleService")
	if vs then
		pcall(vs.standUp, player) -- (si iba en bici o en coche, se baja antes)
	end
	if humanoid.SeatPart and humanoid.SeatPart ~= seat then
		humanoid.Sit = false
		local weld = humanoid.SeatPart:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
	end
	pcall(function()
		player:RequestStreamAroundAsync(seat.Position, 3)
	end)
	root.CFrame = seat.CFrame * CFrame.new(0, 3, 0)
	seat:Sit(humanoid)
	return true
end

-- Sube al jugador al asiento del piloto. lesson = clase práctica (gratis); el alquiler se cobra aquí.
function AviationService.pilot(player: Player, id: string, lesson: boolean?): boolean
	local plane = planes[id]
	local humanoid = humanoidOf(player)
	if not plane or not humanoid or (humanoid.Health or 0) <= 0 or piloting[player] or held(player) then
		return false
	end
	if os.clock() < plane.DownUntil then
		Notify:FireClient(player, "Info", ("🔧 Este avión está en revisión después del accidente. Listo en %d s."):format(math.ceil(plane.DownUntil - os.clock())))
		return false
	end
	if plane.Pilot then
		Notify:FireClient(player, "Info", "Ya hay alguien a los mandos de este avión.")
		return false
	end
	if plane.Renter and plane.Renter ~= player then
		Notify:FireClient(player, "Info", "Esta avioneta está alquilada por otra persona.")
		return false
	end
	local ok, why = AviationService.canPilot(player, plane, lesson)
	if not ok then
		Notify:FireClient(player, "Info", why or "No puedes pilotar este avión.")
		return false
	end
	-- Alquiler (la avioneta, si no es tuya ya; la clase práctica y el modo pruebas no pagan)
	local rent = plane.Spec.Kind == "Avioneta" and plane.Renter ~= player and not lesson and not bypass(player)
	if rent and not DataService.spend(player, AviationService.RentPrice) then
		Notify:FireClient(player, "Info", ("Alquilar la avioneta cuesta %s: no te llega el dinero."):format(Format.money(AviationService.RentPrice)))
		return false
	end
	if riding[player] then
		leavePassenger(player, false)
	end
	if not sitIn(player, plane.PilotSeat) then
		if rent then
			DataService.addMoney(player, AviationService.RentPrice)
		end
		return false
	end
	plane.Pilots += 1
	plane.Pilot = player
	plane.LeftAt = nil
	if plane.Spec.Kind == "Avioneta" then
		plane.Renter = player
		plane.Model:SetAttribute("Renter", player.UserId)
	end
	plane.Lesson = if lesson then { Climbed = false } else nil
	piloting[player] = plane
	plane.Model:SetAttribute("Pilot", player.UserId)
	player:SetAttribute("Piloting", plane.Spec.Id)
	setSolid(plane, false)
	setEngine(plane, true)
	plane.Root.Anchored = false
	pcall(function()
		plane.Root:SetNetworkOwner(player) -- lo vuela su ordenador (sin retraso)
	end)
	plane.LastPos, plane.LastGood = plane.Root.Position, plane.Root.CFrame
	local token = plane.Pilots
	if plane.SeatConn then
		plane.SeatConn:Disconnect()
	end
	plane.SeatConn = plane.PilotSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if plane.Pilot == player and plane.Pilots == token and plane.PilotSeat.Occupant ~= humanoid then
			if plane.Airborne and player.Parent and not held(player) and not player:GetAttribute("Teleporting") then
				-- (en el aire nadie se baja: si se ha soltado, vuelve a su asiento)
				task.defer(function()
					if plane.Pilot == player and plane.PilotSeat.Occupant == nil and humanoid.Parent and (humanoid.Health or 0) > 0 then
						plane.PilotSeat:Sit(humanoid)
					end
				end)
				return
			end
			endPilot(plane, false)
		end
	end)
	if Remote then
		Remote:FireClient(player, "Pilot", { Plane = plane.Model, Id = plane.Spec.Id, Kind = plane.Spec.Kind, Lesson = lesson == true, Health = plane.Health })
	end
	if lesson then
		setActivity(player, "🛩️ Clase práctica: rueda hasta la pista, despega y sube por encima de 70 m", Vector3.new(Airport.Runway.X1 - 70, Airport.GROUND, Airport.Runway.Z))
		Notify:FireClient(player, "Info", "Clase práctica: motor (Shift / Motor +), a la pista, despega (S / tira de la palanca al pasar Vr), sube y vuelve a aterrizar suave.")
	elseif rent then
		Notify:FireClient(player, "Success", ("🛩️ Avioneta alquilada (%s). Es tuya hasta que la dejes en el hangar."):format(Format.money(AviationService.RentPrice)))
	else
		Notify:FireClient(player, "Success", ("✈️ A los mandos del %s. ¡Buen vuelo!"):format(string.lower(Airport.Kinds[plane.Spec.Kind].Name)))
	end
	StoryEvents.emit(player, "VehicleMounted", { Vehicle = if plane.Spec.Kind == "Avion" then "AvionPiloto" else "Avioneta", Rented = rent })
	return true
end

-- (los bebés no suben solos: lo mismo que para los vuelos)
local function lifeAllows(player: Player): boolean
	local life = service("LifeService")
	if life and life.allows then
		local ok, result = pcall(life.allows, player, "Travel")
		return not ok or result ~= false
	end
	return true
end

-- Subir de pasajero (en tierra)
function AviationService.board(player: Player, id: string): boolean
	local plane = planes[id]
	if not plane or piloting[player] or riding[player] or held(player) then
		return false
	end
	if plane.Airborne or plane.Speed > 3 then
		Notify:FireClient(player, "Info", "Solo se sube con el avión parado en tierra.")
		return false
	end
	if not lifeAllows(player) then
		return false
	end
	local seat = freeSeat(plane)
	if not seat then
		Notify:FireClient(player, "Info", "No quedan asientos libres.")
		return false
	end
	if not sitIn(player, seat) then
		return false
	end
	plane.Passengers[player] = seat
	riding[player] = plane
	Notify:FireClient(player, "Info", "💺 A bordo. Para bajarte, salta con el avión parado en tierra.")
	return true
end

-- El piloto pide bajarse (Bajarse / saltar con el avión parado en tierra)
local function onExit(player: Player)
	local plane = piloting[player]
	if not plane then
		return
	end
	if plane.Airborne then
		Notify:FireClient(player, "Info", "En el aire no se baja nadie: aterriza primero ✈️")
		return
	end
	endPilot(plane, true)
end

---------------------------------------------------------------------
-- Lo que cuenta el ordenador del piloto
---------------------------------------------------------------------
local function onState(player: Player, data: any)
	local plane = piloting[player]
	if not plane or type(data) ~= "table" then
		return
	end
	local now = os.clock()
	if now - (lastState[player] or 0) < 0.08 then
		return -- (como mucho ~12 por segundo)
	end
	lastState[player] = now
	local air = data.Air == true
	if air ~= plane.Airborne then
		plane.Airborne = air
		plane.Model:SetAttribute("Airborne", air)
	end
	if typeof(data.Speed) == "number" and data.Speed == data.Speed then
		plane.Speed = math.clamp(data.Speed, 0, 1000)
	end
	local fixed = Flight.Specs[plane.Spec.Kind].FixedGear
	local gear = if fixed then true else data.Gear ~= false
	if gear ~= plane.Gear then
		showGear(plane, gear)
	end
	if typeof(data.Flaps) == "number" then
		plane.Flaps = math.clamp(math.floor(data.Flaps), 0, Flight.Specs[plane.Spec.Kind].Flaps)
		plane.Model:SetAttribute("Flaps", plane.Flaps)
	end
	if typeof(data.Throttle) == "number" and data.Throttle == data.Throttle then
		plane.Model:SetAttribute("Throttle", math.floor(math.clamp(data.Throttle, 0, 1) * 20) / 20)
	end
	-- Clase práctica: ya ha subido lo bastante
	local lesson = plane.Lesson
	if lesson and not lesson.Climbed and air and plane.Root.Position.Y > Airport.GROUND + AviationService.LessonAltitude then
		lesson.Climbed = true
		local R = Airport.Runway
		setActivity(player, "🛬 Clase práctica: vuelve y aterriza suave en la pista de Valmar (tren bajado, flaps, despacio)", Vector3.new(R.X0 + 80, Airport.GROUND, R.Z))
		Notify:FireClient(player, "Success", "¡Muy bien! Ahora vuelve a la pista de Valmar y aterriza suave.")
	end
end

-- ¿Está de verdad tocando el suelo? (el ordenador del piloto dice que ha aterrizado)
local function nearGround(plane: Plane): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { plane.Model }
	local hit = Ground.cast(plane.Root.Position + Vector3.new(0, 1, 0), Vector3.new(0, -(Airport.Kinds[plane.Spec.Kind].FloorY + 8), 0), params)
	return hit ~= nil
end

local function onTouchdown(player: Player, data: any)
	local plane = piloting[player]
	if not plane or type(data) ~= "table" or typeof(data.Sink) ~= "number" or data.Sink ~= data.Sink then
		return
	end
	local spec = Flight.Specs[plane.Spec.Kind]
	local sink = math.clamp(data.Sink, 0, 200)
	if not nearGround(plane) then
		return
	end
	plane.Airborne = false
	plane.Model:SetAttribute("Airborne", false)
	local pos = plane.Root.Position
	local onRunway = Airport.paved(pos.X, pos.Z, 4)
	if sink > spec.SoftSink then
		local damage = Flight.hardDamage(spec, sink)
		plane.Health = math.max(0, plane.Health - damage)
		Notify:FireClient(player, "Info", ("💢 Aterrizaje duro: el avión tiene daños (%d %%)."):format(plane.Health))
		if plane.Health <= 0 then
			AviationService.crash(plane, "El avión no ha aguantado el aterrizaje")
		end
		return
	end
	-- Aterrizaje suave: cuenta para la habilitación (en avioneta y en una pista)
	if onRunway and plane.Spec.Kind == "Avioneta" and AviationService.hasLicense(player) then
		local a = aviation(player)
		if a then
			a.Landings += 1
			if a.Landings == AviationService.JetLandings then
				Notify:FireClient(player, "Success", "🎖️ ¡Habilitación de reactor! Ya puedes pilotar el avión de línea de prácticas.")
			end
		end
	end
	local lesson = plane.Lesson
	if lesson and lesson.Climbed and onRunway and pos.X < Airport.Runway.X1 + 10 and pos.X > Airport.Runway.X0 - 10 then
		plane.Lesson = nil
		local Vehicle = service("VehicleService")
		if Vehicle then
			Vehicle.grantLicense(player, AviationService.License)
		end
		setActivity(player, nil, nil)
		Notify:FireClient(player, "Success", "🎉 ¡APROBADO! Ya tienes la licencia de piloto. Puedes alquilar las avionetas del aeroclub.")
		StoryEvents.emit(player, "LicenseEarned", { License = AviationService.License })
	else
		Notify:FireClient(player, "Success", "🛬 ¡Buen aterrizaje!")
	end
end

local function onCrash(player: Player, data: any)
	local plane = piloting[player]
	if not plane then
		return
	end
	local reason = if type(data) == "table" and type(data.Reason) == "string" then string.sub(data.Reason, 1, 80) else "Accidente"
	AviationService.crash(plane, reason)
end

---------------------------------------------------------------------
-- Vigilancia: saltos imposibles, atravesar edificios y salirse del mapa
---------------------------------------------------------------------
local function solidHit(plane: Plane, from: Vector3, to: Vector3): RaycastResult?
	local d = to - from
	if d.Magnitude < 0.5 then
		return nil
	end
	local ignore: { Instance } = { plane.Model }
	for _, p in CollectionService:GetTagged("Plane") do
		table.insert(ignore, p)
	end
	for _, p in CollectionService:GetTagged("PilotPlane") do
		table.insert(ignore, p)
	end
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = true
	local up = Vector3.new(0, Airport.Kinds[plane.Spec.Kind].FloorY, 0) * 0.6
	for _ = 1, 6 do
		local hit = workspace:Raycast(from + up, d, params)
		if not hit then
			return nil
		end
		if hit.Instance:IsA("BasePart") and hit.Instance.CanCollide and hit.Instance ~= workspace.Terrain then
			return hit
		end
		table.insert(ignore, hit.Instance)
		params.FilterDescendantsInstances = ignore
	end
	return nil
end

function AviationService._validate(plane: Plane, dt: number)
	local player = plane.Pilot
	if not player then
		-- Sin piloto y lejos de su sitio: al rato vuelve sola al hangar (si no va nadie dentro)
		if plane.LeftAt and os.clock() - plane.LeftAt > AviationService.ReturnAfter and next(plane.Passengers) == nil then
			local renter = plane.Renter
			local near = false
			local r = renter and rootOf(renter)
			if r and (r.Position - plane.Root.Position).Magnitude < 60 then
				near = true -- (su dueño sigue al lado: se espera)
			end
			if not near then
				returnHome(plane)
			end
		end
		return
	end
	local pos = plane.Root.Position
	local last = plane.LastPos or pos
	local spec = Flight.Specs[plane.Spec.Kind]
	local moved = (pos - last).Magnitude
	if moved > spec.Vmax * 1.7 * dt + 40 then
		-- Salto imposible: vuelve al último sitio bueno (y su ordenador también)
		plane.Root.CFrame = plane.LastGood or plane.Root.CFrame
		if Remote then
			Remote:FireClient(player, "Reset", { CFrame = plane.LastGood })
		end
		plane.LastPos = (plane.LastGood or plane.Root.CFrame).Position
		return
	end
	local hit = solidHit(plane, last, pos)
	if hit and moved / dt > spec.BumpSpeed * 1.5 then
		AviationService.crash(plane, "Te has estrellado contra " .. (if hit.Instance.Parent and hit.Instance.Parent:IsA("Model") then hit.Instance.Parent.Name else hit.Instance.Name))
		return
	end
	local B = Flight.Bounds
	if pos.X < B.X0 - 600 or pos.X > B.X1 + 600 or pos.Z < B.Z0 - 600 or pos.Z > B.Z1 + 600 or pos.Y > B.Ceiling + 300 then
		AviationService.crash(plane, "Te has salido del mapa")
		return
	end
	plane.LastPos = pos
	plane.LastGood = plane.Root.CFrame
end

---------------------------------------------------------------------
-- Aeroclub: menú, curso y alquiler
---------------------------------------------------------------------
local function shuffle<T>(list: { T }): { T }
	for i = #list, 2, -1 do
		local j = math.random(1, i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

local function freePlane(kind: string, player: Player): Plane?
	-- (la suya, si ya tiene una alquilada; si no, la primera libre en su sitio)
	for _, spec in Airport.PilotPlanes do
		local plane = planes[spec.Id]
		if plane and spec.Kind == kind and plane.Renter == player and not plane.Pilot then
			return plane
		end
	end
	for _, spec in Airport.PilotPlanes do
		local plane = planes[spec.Id]
		if plane and spec.Kind == kind and not plane.Pilot and not plane.Renter and os.clock() >= plane.DownUntil and next(plane.Passengers) == nil then
			return plane
		end
	end
	return nil
end

function AviationService.menu(player: Player)
	if not Remote then
		return
	end
	local a = aviation(player)
	local licensed = AviationService.hasLicense(player)
	local options, keys = {}, {}
	local function add(label: string, key: string)
		table.insert(options, label)
		table.insert(keys, key)
	end
	if licensed then
		add("✅ Licencia de piloto (ya la tienes)", "")
	elseif a and a.Theory then
		add("🛩️ Clase práctica (gratis): despega, sube y aterriza", "Lesson")
	else
		add(("📝 Curso de piloto: examen teórico · %s"):format(Format.money(AviationService.CoursePrice)), "Course")
	end
	add(("🛩️ Alquilar avioneta · %s"):format(Format.money(AviationService.RentPrice)), "Rent")
	local landings = if a then a.Landings else 0
	add(("✈️ Avión de línea de prácticas (%s)"):format(if licensed and landings >= AviationService.JetLandings then "habilitado" else ("%d/%d aterrizajes"):format(math.min(landings, AviationService.JetLandings), AviationService.JetLandings)), "Jet")
	add("Cerrar", "")
	local token = HttpService:GenerateGUID(false)
	sessions[player] = { Token = token, Keys = keys }
	Remote:FireClient(player, "Menu", token, {
		Title = "✈ Aeroclub Valmar",
		Text = "Licencia: curso teórico y una clase práctica. Con licencia alquilas avionetas; con " .. AviationService.JetLandings .. " aterrizajes suaves, el avión de línea.",
		Options = options,
	})
end

local function startCourse(player: Player, session: Session)
	if AviationService.hasLicense(player) then
		Notify:FireClient(player, "Info", "Ya tienes la licencia de piloto.")
		return
	end
	if not adult(player) then
		Notify:FireClient(player, "Info", "El curso de piloto es para mayores de edad ✈️")
		return
	end
	if not bypass(player) and not DataService.spend(player, AviationService.CoursePrice) then
		Notify:FireClient(player, "Info", ("El curso cuesta %s: no te llega el dinero."):format(Format.money(AviationService.CoursePrice)))
		return
	end
	local pool = shuffle(table.clone(AviationService.Questions))
	local questions, correct = {}, {}
	for i = 1, math.min(5, #pool) do
		local q = pool[i]
		local order = shuffle({ 1, 2, 3 })
		local opts = {}
		for k, index in order do
			opts[k] = q[2][index]
			if index == 1 then
				correct[i] = k
			end
		end
		table.insert(questions, { Text = q[1], Options = opts })
	end
	session.Correct = correct
	if Remote then
		Remote:FireClient(player, "Theory", session.Token, { Questions = questions, ToPass = AviationService.ToPass })
	end
end

local function gradeTheory(player: Player, session: Session, answers: any)
	if type(answers) ~= "table" or not session.Correct then
		return
	end
	local right = 0
	for i, answer in session.Correct do
		if answers[i] == answer then
			right += 1
		end
	end
	sessions[player] = nil
	if right >= AviationService.ToPass then
		local a = aviation(player)
		if a then
			a.Theory = true
		end
		Notify:FireClient(player, "Success", ("📝 ¡Teórico aprobado (%d/%d)! Ahora la clase práctica: pídela en el mostrador del aeroclub."):format(right, #session.Correct))
	else
		Notify:FireClient(player, "Error", ("Teórico suspendido (%d/%d, hacen falta %d). Repasa y vuelve a intentarlo."):format(right, #session.Correct, AviationService.ToPass))
		StoryEvents.emit(player, "LicenseFailed", { License = AviationService.License })
	end
end

local function choose(player: Player, session: Session, index: any)
	local keys = session.Keys or {}
	local key = if typeof(index) == "number" then keys[index] else nil
	if key == "Course" then
		startCourse(player, session)
		return
	end
	sessions[player] = nil
	if key == "Lesson" then
		local plane = freePlane("Avioneta", player)
		if not plane then
			Notify:FireClient(player, "Info", "Ahora mismo no hay ninguna avioneta libre en el hangar. Vuelve en un rato.")
			return
		end
		AviationService.pilot(player, plane.Spec.Id, true)
	elseif key == "Rent" then
		local plane = freePlane("Avioneta", player)
		if not plane then
			Notify:FireClient(player, "Info", "Las avionetas del aeroclub están todas fuera. Vuelve en un rato.")
			return
		end
		AviationService.pilot(player, plane.Spec.Id)
	elseif key == "Jet" then
		local plane = freePlane("Avion", player)
		if not plane then
			Notify:FireClient(player, "Info", "El avión de línea de prácticas está ocupado o en revisión.")
			return
		end
		AviationService.pilot(player, plane.Spec.Id)
	end
end

---------------------------------------------------------------------
-- Montaje
---------------------------------------------------------------------
local function setupPlane(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local spec = Airport.pilotPlane(model:GetAttribute("PilotPlane") or "")
	if not spec or planes[spec.Id] then
		return
	end
	local root = model:FindFirstChild("Root")
	local pilotSeat = model:FindFirstChild("PilotSeat")
	if not root or not root:IsA("BasePart") or not pilotSeat or not pilotSeat:IsA("Seat") then
		return
	end
	if model:GetAttribute("NeedsWeld") then
		AirportKit.weldPlane(model, root)
	end
	root.Anchored = true
	local seats = {}
	local collide = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Seat") and d ~= pilotSeat then
			table.insert(seats, d)
		end
		if d:IsA("BasePart") then
			collide[d] = d.CanCollide
		end
	end
	table.sort(seats, function(a, b)
		return (a:GetAttribute("SeatIndex") or 0) < (b:GetAttribute("SeatIndex") or 0)
	end)
	pilotSeat.CanTouch = false -- (solo se sienta quien pilota: el cartel «Pilotar»)
	local plane: Plane = {
		Spec = spec,
		Model = model,
		Root = root,
		PilotSeat = pilotSeat,
		Seats = seats,
		Board = model:FindFirstChild("BoardPoint") :: BasePart?,
		Pilot = nil,
		Renter = nil,
		Lesson = nil,
		Passengers = {},
		Airborne = false,
		Gear = true,
		Flaps = 0,
		Speed = 0,
		Health = 100,
		DownUntil = 0,
		Collide = collide,
		Pilots = 0,
	}
	planes[spec.Id] = plane
	showGear(plane, true)
	setEngine(plane, false)
	local board = plane.Board
	if board then
		local jet = spec.Kind == "Avion"
		local fly = Builder.prompt(board, "Pilotar", if jet then "✈️ Avión de línea " .. spec.Id else ("🛩️ Avioneta %s · alquiler %s"):format(spec.Id, Format.money(AviationService.RentPrice)), 0.4)
		fly.Name = "PilotPrompt"
		fly.MaxActivationDistance = 12
		fly.Triggered:Connect(function(player)
			AviationService.pilot(player, spec.Id)
		end)
		local ride = Builder.prompt(board, "Subir a bordo", (if jet then "✈️ " else "🛩️ ") .. spec.Id, 0.3)
		ride.Name = "RidePrompt"
		ride.MaxActivationDistance = 12
		ride.UIOffset = Vector2.new(0, 70)
		ride.Triggered:Connect(function(player)
			AviationService.board(player, spec.Id)
		end)
		local function refresh()
			fly.Enabled = plane.Pilot == nil
			ride.Enabled = not plane.Airborne
		end
		model:GetAttributeChangedSignal("Pilot"):Connect(refresh)
		model:GetAttributeChangedSignal("Airborne"):Connect(refresh)
		refresh()
	end
end

local function setupDesk(desk: Instance)
	if not desk:IsA("BasePart") then
		return
	end
	local prompt = Builder.prompt(desk, "Aeroclub", "✈️ Curso de piloto · alquiler de avionetas", 0.3)
	prompt.MaxActivationDistance = 10
	prompt.Triggered:Connect(function(player)
		AviationService.menu(player)
	end)
end

function AviationService.init()
	for _, model in CollectionService:GetTagged("PilotPlane") do
		setupPlane(model)
	end
	CollectionService:GetInstanceAddedSignal("PilotPlane"):Connect(setupPlane)
	for _, desk in CollectionService:GetTagged("Aeroclub") do
		setupDesk(desk)
	end
	CollectionService:GetInstanceAddedSignal("Aeroclub"):Connect(setupDesk)
	if Remote then
		Remote.OnServerEvent:Connect(function(player, action, a, b)
			if action == "State" then
				onState(player, a)
			elseif action == "Touchdown" then
				onTouchdown(player, a)
			elseif action == "Crash" then
				onCrash(player, a)
			elseif action == "Exit" then
				onExit(player)
			elseif action == "Choose" or action == "Answers" then
				local session = sessions[player]
				if not session or session.Token ~= a then
					return
				end
				if action == "Choose" then
					choose(player, session, b)
				else
					gradeTheory(player, session, b)
				end
			end
		end)
	end
	Players.PlayerRemoving:Connect(function(player)
		local plane = piloting[player]
		if plane then
			endPilot(plane, false)
			returnHome(plane)
		end
		leavePassenger(player, false)
		for _, p in planes do
			if p.Renter == player and not p.Pilot then
				returnHome(p)
			end
		end
		sessions[player] = nil
		lastState[player] = nil
	end)
	local clock = 0
	RunService.Heartbeat:Connect(function(dt)
		clock += dt
		if clock < VALIDATE then
			return
		end
		local step = clock
		clock = 0
		for _, plane in planes do
			local ok, err = pcall(AviationService._validate, plane, step)
			if not ok then
				warn("[AviationService] " .. tostring(err))
			end
			-- Pasajeros: en el aire nadie se baja (si se suelta, vuelve a su asiento)
			for player, seat in table.clone(plane.Passengers) do
				local humanoid = humanoidOf(player)
				if not player.Parent or not humanoid or (humanoid.Health or 0) <= 0 or held(player) or player:GetAttribute("Teleporting") then
					leavePassenger(player, false)
				elseif humanoid.SeatPart ~= seat then
					if plane.Airborne then
						seat:Sit(humanoid)
					else
						leavePassenger(player, false)
					end
				end
			end
		end
	end)
end

-- (para las pruebas)
AviationService._planes = planes
AviationService._piloting = piloting
AviationService._riding = riding
AviationService._sessions = sessions
AviationService._choose = choose
AviationService._grade = gradeTheory
AviationService._onState = onState
AviationService._onTouchdown = onTouchdown
AviationService._onCrash = onCrash
AviationService._onExit = onExit

return AviationService
