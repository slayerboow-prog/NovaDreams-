-- Driving (cliente): conducir coches, motos, bicis, monopatines y patinetes.
--
-- Cuando te sientas en el asiento de conductor ("DriverSeat") de un vehículo con el atributo
-- Drivable, este script lo mueve cada fotograma:
--   * W/S o ↑/↓: acelerar, frenar y marcha atrás · A/D o ←/→: girar · Ctrl: freno de mano
--   * Mando: gatillo derecho acelera, gatillo izquierdo frena (los dos a medias, poco a poco),
--     joystick izquierdo gira y LB es el freno de mano
--   * Móvil: el joystick de Roblox es el volante y, a la derecha, pedales en pantalla (acelerador,
--     freno / marcha atrás y freno de mano) en el arco del botón de saltar (UI/TouchLayout)
--   * Todo entra suave: el acelerador y el volante no saltan de 0 a 1, van subiendo y bajando
--     (y el volante vuelve solo al centro). Cuanto más rápido vas, menos y más despacio gira.
--   * Freno de mano: frena en seco; en coche, si giras a la vez, la trasera derrapa un poco
--   * Sigue el suelo con rayos: sube bordillos pequeños y cuestas, y se inclina con ellas (nunca
--     más de lo que toca: no vuelca)
--   * Choca con paredes, farolas y árboles (se para en seco) y no entra en el agua
--   * Motos y bicis se inclinan en las curvas; en el monopatín y el patinete vas de pie
--   * Cuadro de mandos (VehicleHud): velocímetro de aguja, marcha, combustible y kilómetros.
--     Sin gasolina (o batería) el vehículo apenas avanza
--   * Barcos (lancha, «Gaviota»): los mismos mandos. Flotan a la altura del mar con un balanceo
--     suave, escoran en las curvas y solo avanzan por agua honda: se paran en la orilla, la arena,
--     los pantalanes y contra otros barcos (shared/Boats + un rayo hacia abajo sin contar el agua)
--   * Lluvia y nieve (shared/Wetness): con el suelo mojado o nevado agarra menos. Acelera y frena
--     peor, gira menos y derrapa en las curvas (va un poco hacia donde iba, no hacia donde apunta).
--     Las motos, bicis y patinetes resbalan más.
--   * Nunca a medias: si el servidor dice que conduces (Riding) y tu personaje no está sentado al
--     volante, al momento se pide que te vuelva a sentar y, si tampoco, te bajas del todo (RideSpot.
--     watchSeat). Los pedales solo salen conduciendo de verdad.
--   * Atascado (pisando sin moverte, metido en un murete, una farola o alguien): te saca a un sitio
--     libre al lado (RideSpot.unstick). Con el tráfico se choca (Traffic.blocking): no se atraviesa.
-- Saltar (Espacio) o F para bajarse (en el móvil, el botón "Bajarse"; lo hace Controllers/Vehicles
-- y funciona siempre a la primera). El servidor
-- (VehicleService) le da el control a tu ordenador, así que se mueve sin retraso y los demás
-- (también tus pasajeros) lo ven igual. La cámara la lleva RideCamera.luau.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Boats = require(ReplicatedStorage.Shared.Boats)
local Wetness = require(ReplicatedStorage.Shared.Wetness)
local RideSpot = require(ReplicatedStorage.Shared.RideSpot)
local Traffic = require(script.Parent.Traffic)
local SoundFx = require(script.Parent.SoundFx)
local Hud = require(script.Parent.Parent.UI.Hud)
local Theme = require(script.Parent.Parent.UI.Theme)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local VehicleHud = require(script.Parent.VehicleHud)
local CameraShake = require(script.Parent.CameraShake)

local Driving = {}

local player = Players.LocalPlayer
local IDLE = { R15 = 507766388, R6 = 180435571 } -- postura de pie (monopatín, patinete)
local MAX_TILT = math.rad(28) -- lo más que se inclina con la cuesta (así nunca vuelca)

type State = {
	Model: Model,
	Chassis: BasePart,
	Seat: VehicleSeat,
	Kind: string,
	Speed: number,
	Yaw: number,
	Travel: number, -- hacia dónde se mueve de verdad (con poco agarre, se queda atrás: derrapa)
	Up: Vector3,
	Lean: number,
	Base: Vector3, -- dónde está (a ras de suelo) según este script, no según la física
	Pose: AnimationTrack?,
	Throttle: number, -- acelerador suave (-1 freno / marcha atrás .. 1)
	Steer: number, -- volante suave (-1 izquierda .. 1 derecha)
	Stuck: number, -- segundos pisando sin moverse (RideSpot.stuckStep)
	Start: Vector3, -- dónde se subió (si no se ha movido de ahí, un atasco es de salida)
	Blocker: string?, -- con qué chocó en el último fotograma ("Persona", "Trafico", "Pared")
	WarnedAt: number?,
}
local state: State? = nil
local warnRoad: () -> ()
local unstick: (State, Vector3) -> ()

-- Pedales en pantalla (móvil): qué dedo pisa cada uno
local touch = { Gas = nil :: InputObject?, Brake = nil :: InputObject?, Handbrake = nil :: InputObject? }
local pedalUpdates: { () -> () } = {} -- (se vuelven a mirar al empezar y dejar de conducir)
local function refreshPedals()
	for _, update in pedalUpdates do
		pcall(update)
	end
end

local function yawOf(cf: CFrame): number
	local look = cf.LookVector
	return math.atan2(-look.X, -look.Z)
end

-- Acerca `current` a `target` como mucho `rate` por segundo
local function approach(current: number, target: number, rate: number, dt: number): number
	local step = rate * dt
	if target > current then
		return math.min(target, current + step)
	end
	return math.max(target, current - step)
end
Driving.approach = approach

---------------------------------------------------------------------
-- Mandos: teclado, mando y pantalla
---------------------------------------------------------------------

local function held(input: InputObject?): boolean
	return input ~= nil and input.UserInputState ~= Enum.UserInputState.End and input.UserInputState ~= Enum.UserInputState.Cancel
end

local function keyDown(...: Enum.KeyCode): boolean
	for _, key in { ... } do
		if UserInputService:IsKeyDown(key) then
			return true
		end
	end
	return false
end

-- Lo que pide el jugador ahora mismo (sin suavizar): acelerador, volante y freno de mano
local function readInput(seat: VehicleSeat): (number, number, boolean)
	local throttle, steer, handbrake = 0, 0, false
	-- Teclado (no mientras escribe en el chat)
	if UserInputService.KeyboardEnabled and not UserInputService:GetFocusedTextBox() then
		if keyDown(Enum.KeyCode.W, Enum.KeyCode.Up) then
			throttle += 1
		end
		if keyDown(Enum.KeyCode.S, Enum.KeyCode.Down) then
			throttle -= 1
		end
		if keyDown(Enum.KeyCode.D, Enum.KeyCode.Right) then
			steer += 1
		end
		if keyDown(Enum.KeyCode.A, Enum.KeyCode.Left) then
			steer -= 1
		end
		handbrake = keyDown(Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl)
	end
	-- Mando: gatillos analógicos y joystick (con zona muerta)
	if UserInputService.GamepadEnabled then
		local ok, states = pcall(function()
			return UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)
		end)
		if ok and states then
			for _, input in states do
				if input.KeyCode == Enum.KeyCode.ButtonR2 then
					throttle += math.clamp(input.Position.Z, 0, 1)
				elseif input.KeyCode == Enum.KeyCode.ButtonL2 then
					throttle -= math.clamp(input.Position.Z, 0, 1)
				elseif input.KeyCode == Enum.KeyCode.Thumbstick1 then
					local x = input.Position.X
					if math.abs(x) > 0.15 then
						steer += math.sign(x) * (math.abs(x) - 0.15) / 0.85
					end
				end
			end
		end
		handbrake = handbrake or UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonL1)
	end
	-- Pantalla (móvil)
	if held(touch.Gas) then
		throttle += 1
	end
	if held(touch.Brake) then
		throttle -= 1
	end
	handbrake = handbrake or held(touch.Handbrake)
	-- Si nada de lo anterior, lo que diga Roblox (el joystick del móvil gira y, hacia delante o
	-- atrás, también acelera y frena)
	if math.abs(throttle) < 0.05 then
		throttle = seat.ThrottleFloat
	end
	if math.abs(steer) < 0.05 then
		steer = seat.SteerFloat
	end
	return math.clamp(throttle, -1, 1), math.clamp(steer, -1, 1), handbrake
end

-- Suaviza el acelerador y el volante. fast = 0..1 (lo rápido que vas respecto a su máximo)
function Driving.smoothInputs(throttle: number, steer: number, wantThrottle: number, wantSteer: number, fast: number, dt: number): (number, number)
	-- Pisar sube poco a poco; soltar (o cambiar de pedal) baja más rápido
	local releasing = math.abs(wantThrottle) < math.abs(throttle) or wantThrottle * throttle < 0
	throttle = approach(throttle, wantThrottle, if releasing then 6 else 3.2, dt)
	-- El volante: más lento cuanto más rápido vas, y vuelve solo al centro
	local centring = math.abs(wantSteer) < math.abs(steer) or wantSteer * steer < 0
	local rate = if centring then 5.5 else 4.2 - 2 * fast
	steer = approach(steer, wantSteer, rate, dt)
	return throttle, steer
end

-- Nunca se inclina más de MAX_TILT (ni con un rayo que da en algo raro): no vuelca
function Driving.limitTilt(up: Vector3): Vector3
	if up.Y <= 0 then
		return Vector3.yAxis
	end
	local flat = Vector3.new(up.X, 0, up.Z)
	local limit = math.sin(MAX_TILT)
	if flat.Magnitude > limit then
		return (flat.Unit * limit + Vector3.new(0, math.cos(MAX_TILT), 0)).Unit
	end
	return up.Unit
end

---------------------------------------------------------------------
-- Pedales en pantalla (móvil)
---------------------------------------------------------------------

-- Botón redondo que se mantiene pulsado (con varios dedos a la vez: acelerar y girar con el joystick)
local function pedal(parent: Instance, name: string, text: string, color: Color3, slot: string, id: string)
	local button = Theme.button({
		Name = name,
		Text = text,
		TextSize = 24,
		TextWrapped = true,
		BackgroundColor3 = color,
		BackgroundTransparency = 0.25,
		AutoButtonColor = false,
		Parent = parent,
	})
	local corner = button:FindFirstChildOfClass("UICorner")
	if corner then
		corner.CornerRadius = UDim.new(0.5, 0)
	end
	TouchLayout.place(button, id)
	-- Solo conduciendo de verdad (sentado al volante), no solo porque el servidor diga «montado»
	table.insert(pedalUpdates, TouchLayout.showWhen(button, "Vehiculo", function()
		return state ~= nil
	end))
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			(touch :: any)[slot] = input
			button.BackgroundTransparency = 0
		end
	end)
	-- (se suelta cuando ese dedo se levanta: lo mira readInput con held)
	RunService.RenderStepped:Connect(function()
		if (touch :: any)[slot] ~= nil and not held((touch :: any)[slot]) then
			(touch :: any)[slot] = nil
			button.BackgroundTransparency = 0.25
		end
	end)
	return button
end

-- Acelerador, freno / marcha atrás y freno de mano en el arco del botón de saltar (TouchLayout);
-- el volante es el joystick de Roblox. Solo se ven conduciendo.
local function buildTouch()
	if not UserInputService.TouchEnabled then
		return
	end
	local gui = Theme.create("ScreenGui", { Name = "DrivingControls", ResetOnSpawn = false, DisplayOrder = 4, Parent = player:WaitForChild("PlayerGui") })
	local rgb = Color3.fromRGB
	pedal(gui, "Gas", "⬆", rgb(0, 140, 80), "Gas", "Acelerar")
	pedal(gui, "Brake", "🛑", rgb(170, 60, 50), "Brake", "Frenar")
	local hand = pedal(gui, "Handbrake", "🅿", rgb(90, 90, 100), "Handbrake", "FrenoMano")
	hand.TextSize = 20
end

local function releasePedals()
	for slot in touch do
		(touch :: any)[slot] = nil
	end
end

---------------------------------------------------------------------
-- Subir y bajar
---------------------------------------------------------------------

local function start(seat: VehicleSeat, humanoid: Humanoid)
	local model = seat.Parent
	if not model or not model:IsA("Model") or not model:GetAttribute("Drivable") or not model.PrimaryPart then
		return
	end
	local kind = model:GetAttribute("Kind")
	if typeof(kind) ~= "string" or not Gameplay.Driving[kind] then
		return
	end
	local chassis = model.PrimaryPart :: BasePart
	local s: State = {
		Model = model,
		Chassis = chassis,
		Seat = seat,
		Kind = kind,
		Speed = 0,
		Yaw = yawOf(chassis.CFrame),
		Travel = yawOf(chassis.CFrame),
		Up = Vector3.yAxis,
		Lean = 0,
		Base = chassis.Position - chassis.CFrame.UpVector * (chassis.Size.Y / 2),
		Throttle = 0,
		Steer = 0,
		Stuck = 0,
		Start = chassis.Position,
	}
	-- De pie: se tapa la postura de sentado con la de estar de pie
	if Gameplay.Driving[kind].Standing then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			local animation = Instance.new("Animation")
			local r15 = humanoid.RigType == Enum.HumanoidRigType.R15
			animation.AnimationId = "rbxassetid://" .. (if r15 then IDLE.R15 else IDLE.R6)
			local ok, track = pcall(function()
				return animator:LoadAnimation(animation)
			end)
			if ok and track then
				track.Priority = Enum.AnimationPriority.Action
				track.Looped = true
				track:Play(0.3)
				s.Pose = track
			end
		end
	end
	state = s
	VehicleHud.show(kind)
	SoundFx.vehicleStart(kind, chassis)
	releasePedals()
	refreshPedals()
	if not Gameplay.Driving[kind].Boat then
		warnRoad() -- (en el mar da igual que llueva)
	end
end

-- Aviso al subir si el suelo está mojado o nevado (una vez por cada cosa)
local warned: { [string]: boolean } = {}
function warnRoad()
	local snow = workspace:GetAttribute("Snow") or 0
	local wet = workspace:GetAttribute("Wet") or 0
	local key = if snow > 0.3 then "Nieve" elseif wet > 0.4 then "Lluvia" else nil
	if key and not warned[key] then
		warned[key] = true
		Hud.toast("Info", if key == "Nieve" then "❄️ Carretera con nieve: ve despacio, frena antes y gira con cuidado." else "🌧️ Suelo mojado: frenas peor y puedes derrapar en las curvas.")
	end
end

local function stop()
	if not state then
		return
	end
	if state.Pose then
		-- Se para y luego se destruye: cada vez que te subes se carga una nueva (si no, se acumulan)
		local pose = state.Pose
		pose:Stop(0.3)
		task.delay(0.35, function()
			pcall(pose.Destroy, pose)
		end)
	end
	-- Al bajarse, el vehículo se queda quieto (aunque fuera lanzado: frena en seco y lo aparca el servidor)
	local chassis = state.Chassis
	if chassis.Parent and not chassis.Anchored then
		pcall(function()
			chassis.AssemblyLinearVelocity = Vector3.zero
			chassis.AssemblyAngularVelocity = Vector3.zero
		end)
	end
	state = nil
	VehicleHud.hide()
	SoundFx.vehicleStop()
	releasePedals()
	refreshPedals()
end

-- Suelo bajo un punto (ignora el vehículo, las personas y lo que no choca). nil = agua o vacío
-- ¿Es parte de una persona (jugador o personaje: la abuela, un compañero, un peatón…)?
local function personOf(part: Instance): Model?
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		if model:FindFirstChildOfClass("Humanoid") then
			return model
		end
		model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
	end
	return nil
end

local function ground(params: RaycastParams, point: Vector3, top: number): RaycastResult?
	local from, dir = Vector3.new(point.X, top, point.Z), Vector3.new(0, -(top - point.Y) - 14, 0)
	local hit = workspace:Raycast(from, dir, params)
	-- Una persona no es suelo: si no, el coche se subía encima de quien estuviera delante y se ponía
	-- de pie (con los personajes de la historia que te acompañan pasaba mucho)
	for _ = 1, 4 do
		local person = hit and personOf(hit.Instance)
		if not person then
			break
		end
		local ignore = params.FilterDescendantsInstances
		table.insert(ignore, person)
		params.FilterDescendantsInstances = ignore
		hit = workspace:Raycast(from, dir, params)
	end
	if hit and hit.Material == Enum.Material.Water then
		return nil
	end
	return hit
end

---------------------------------------------------------------------
-- Barcos
---------------------------------------------------------------------
-- En el agua: sin lluvia ni nieve que valgan, pero derrapa un poco (va hacia donde iba)
local BOAT_ROAD = { Accel = 1, Brake = 1, Turn = 1, MaxSpeed = 1, Traction = 3.5 }

-- ¿Hay agua honda aquí? Rayo hacia abajo SIN contar el agua: si da en el fondo muy abajo (o en nada),
-- sí; si da en arena, tierra, un pantalán o un barco amarrado a flor de agua, no
local deepParams = RaycastParams.new()
deepParams.FilterType = Enum.RaycastFilterType.Exclude
deepParams.RespectCanCollide = true
deepParams.IgnoreWater = true
local function deepEnough(ignore: { Instance }, point: Vector3): boolean
	deepParams.FilterDescendantsInstances = ignore
	local top = Boats.SeaLevel + 3.2
	local hit = workspace:Raycast(Vector3.new(point.X, top, point.Z), Vector3.new(0, -30, 0), deepParams)
	return hit == nil or hit.Position.Y < Boats.SeaLevel - Boats.Draft
end

-- ¿Puede el barco ir de base a target? (el plano de la costa y el fondo, en el centro y en la proa)
-- Si ya está en un sitio malo (lo han dejado así), puede moverse para salir.
local function boatCanGo(ignore: { Instance }, base: Vector3, target: Vector3, forward: Vector3, sign: number, size: Vector3): boolean
	local right = Vector3.new(-forward.Z, 0, forward.X)
	local function clear(at: Vector3): boolean
		if not Boats.hullAtSea(at, forward, size) then
			return false
		end
		local nose = at + forward * sign * (size.Z / 2)
		for _, p in { at, nose, nose + right * size.X * 0.4, nose - right * size.X * 0.4 } do
			if not deepEnough(ignore, p) then
				return false
			end
		end
		return true
	end
	if not clear(base) then
		return true
	end
	return Boats.canMove(base, target, forward, size) and clear(target)
end

-- Coloca el barco: a la altura del mar con su balanceo, escorando en las curvas
local function boatStep(s: State, ignore: { Instance }, forward: Vector3, heading: Vector3, move: Vector3, steer: number, maxSpeed: number, tuning: { [string]: any }, dt: number)
	local size = s.Chassis.Size
	local base = Vector3.new(s.Base.X, Boats.SeaLevel, s.Base.Z)
	local target = base + Vector3.new(move.X, 0, move.Z)
	if move.Magnitude > 0.001 then
		local sign = if s.Speed >= 0 then 1 else -1
		if not boatCanGo(ignore, base, target, forward, sign, size) then
			if math.abs(s.Speed) > 10 then
				SoundFx.crash(math.abs(s.Speed), s.Chassis)
				CameraShake.shake(math.clamp(math.abs(s.Speed) / 45, 0.2, 1), 0.3)
			end
			s.Speed = 0
			s.Throttle = 0
			target = base
		end
	end
	local leanTarget = -steer * math.rad(tuning.Lean or 0) * math.clamp(math.abs(s.Speed) / (maxSpeed * 0.6), 0, 1)
	s.Lean += (leanTarget - s.Lean) * math.min(1, dt * 3)
	local heave, pitch, roll = Boats.bob(os.clock(), s.Speed)
	s.Base = target
	s.Up = Vector3.yAxis
	local position = target + Vector3.new(0, heave, 0)
	local oriented = CFrame.lookAt(position, position + forward) * CFrame.Angles(-pitch, 0, roll + s.Lean)
	s.Chassis.CFrame = oriented * CFrame.new(0, size.Y / 2, 0)
	s.Chassis.AssemblyLinearVelocity = heading * s.Speed
	s.Chassis.AssemblyAngularVelocity = Vector3.zero
end

---------------------------------------------------------------------
-- Atascos
---------------------------------------------------------------------
-- El mundo de tu pantalla para RideSpot: suelo con rayos (sin personas ni agua), ocupado = algo que
-- choca, una persona o un vehículo del tráfico; sin atravesar paredes
local function clientWorld(s: State): RideSpot.World
	local ignore: { Instance } = { s.Model }
	for _, other in Players:GetPlayers() do
		if other.Character then
			table.insert(ignore, other.Character)
		end
	end
	local function params(): RaycastParams
		local p = RaycastParams.new()
		p.FilterType = Enum.RaycastFilterType.Exclude
		p.FilterDescendantsInstances = table.clone(ignore)
		p.RespectCanCollide = true
		p.IgnoreWater = false
		return p
	end
	local mine: { Instance } = { s.Model }
	if player.Character then
		table.insert(mine, player.Character)
	end
	return {
		ground = function(x: number, z: number, top: number, bottom: number): (number?, Vector3?, boolean?)
			local hit = ground(params(), Vector3.new(x, bottom + 14, z), top)
			if hit and hit.Instance == workspace.Terrain and hit.Position.Y < bottom then
				return nil, nil, false
			end
			return if hit then hit.Position.Y else nil, nil, false
		end,
		blocked = function(cf: CFrame, size: Vector3): boolean
			local box = Vector3.new(size.X + 0.2, RideSpot.Height, size.Z + 0.2)
			local overlap = OverlapParams.new()
			overlap.FilterType = Enum.RaycastFilterType.Exclude
			overlap.FilterDescendantsInstances = mine
			overlap.RespectCanCollide = false
			overlap.MaxParts = 40
			local ok, parts = pcall(function()
				return workspace:GetPartBoundsInBox(cf * CFrame.new(0, RideSpot.Lift + box.Y / 2, 0), box, overlap)
			end)
			if ok and type(parts) == "table" then
				for _, part in parts do
					if part ~= workspace.Terrain and (part.CanCollide or personOf(part)) then
						return true
					end
				end
			end
			local okTraffic, hitAt = pcall(Traffic.blocking, cf.Position, cf.LookVector, size.Z, size.X)
			return okTraffic and hitAt ~= nil
		end,
		clear = function(from: Vector3, to: Vector3): boolean
			local hit = workspace:Raycast(from, to - from, params())
			return hit == nil or hit.Normal.Y >= 0.6 or personOf(hit.Instance) ~= nil
		end,
	}
end

-- Pisando sin moverse: si está metido en algo (o acaba de salir y no ha podido ni arrancar, o lo
-- que tiene delante es una persona o el tráfico), se le pone en un sitio libre al lado. Contra una
-- pared, solo se le dice que dé marcha atrás.
function unstick(s: State, forward: Vector3)
	local size = s.Chassis.Size
	local here = RideSpot.frame(s.Base, forward)
	local world = clientWorld(s)
	local fresh = Vector3.new(s.Base.X - s.Start.X, 0, s.Base.Z - s.Start.Z).Magnitude < 1.5
	local ok, inside = pcall(world.blocked, here, size)
	inside = ok and inside
	local now = os.clock()
	if not (inside or fresh or s.Blocker == "Persona" or s.Blocker == "Trafico") then
		if now - (s.WarnedAt or -math.huge) > 10 then
			s.WarnedAt = now
			Hud.toast("Info", "🧱 Hay algo delante: da marcha atrás (freno) para salir.")
		end
		return
	end
	local okSpot, spot = pcall(RideSpot.unstick, world, here, size)
	if not okSpot or not spot then
		if now - (s.WarnedAt or -math.huge) > 10 then
			s.WarnedAt = now
			Hud.toast("Info", "🚧 No hay sitio para moverlo: bájate y sácalo en otro sitio.")
		end
		return
	end
	s.Base = spot.Position
	s.Up = spot.UpVector
	s.Speed = 0
	s.Throttle = 0
	s.Start = spot.Position
	s.Chassis.CFrame = spot * CFrame.new(0, size.Y / 2, 0)
	s.Chassis.AssemblyLinearVelocity = Vector3.zero
	s.Chassis.AssemblyAngularVelocity = Vector3.zero
	Hud.toast("Info", "🔧 Estabas atascado: te hemos movido a un sitio libre al lado.")
end

local function step(dt: number)
	local s = state
	if not s then
		return
	end
	if not s.Chassis.Parent or s.Chassis.Anchored then
		return -- el servidor aún no lo ha soltado (o ya lo ha aparcado)
	end
	dt = math.min(dt, 1 / 15) -- (un tirón del ordenador no lanza el coche)
	local tuning = Gameplay.Driving[s.Kind]
	-- Lluvia y nieve: menos agarre
	local grip = Wetness.grip(s.Kind, workspace:GetAttribute("Wet") or 0, workspace:GetAttribute("Snow") or 0)
	local road = if tuning.Boat then BOAT_ROAD else Wetness.drive(grip)
	local maxSpeed = Gameplay.Vehicles[s.Kind].Speed * road.MaxSpeed
	if player:GetAttribute("OutOfFuel") then
		maxSpeed = 4 -- sin gasolina (o batería) apenas avanza: hay que llegar a una gasolinera
	end
	local wantThrottle, wantSteer, handbrake = readInput(s.Seat)
	local fast = math.clamp(math.abs(s.Speed) / math.max(maxSpeed, 1), 0, 1)
	s.Throttle, s.Steer = Driving.smoothInputs(s.Throttle, s.Steer, wantThrottle, wantSteer, fast, dt)
	local throttle, steer = s.Throttle, s.Steer

	-- Acelerar / frenar / marcha atrás (todo en proporción a lo que pisas)
	if handbrake then
		local drag = tuning.Brake * road.Brake * 1.1
		s.Speed = if s.Speed > 0 then math.max(0, s.Speed - drag * dt) else math.min(0, s.Speed + drag * dt)
	elseif throttle > 0.02 then
		if s.Speed < 0 then
			s.Speed = math.min(0, s.Speed + tuning.Brake * road.Brake * math.max(0.35, throttle) * dt)
		else
			-- (acelera menos cuanto más cerca de su velocidad máxima: sin tirón al llegar)
			local push = tuning.Accel * road.Accel * throttle * (1 - 0.5 * fast * fast)
			if s.Speed < maxSpeed then
				s.Speed = math.min(maxSpeed, s.Speed + push * dt)
			end
		end
	elseif throttle < -0.02 then
		if s.Speed > 0 then
			s.Speed = math.max(0, s.Speed - tuning.Brake * road.Brake * math.max(0.35, -throttle) * dt)
		else
			s.Speed = math.max(-tuning.Reverse, s.Speed + tuning.Accel * road.Accel * 0.6 * throttle * dt)
		end
	else
		-- Sin pisar nada se va parando poco a poco
		local drag = 6 + math.abs(s.Speed) * 0.12
		s.Speed = if s.Speed > 0 then math.max(0, s.Speed - drag * dt) else math.min(0, s.Speed + drag * dt)
	end
	-- Por encima de su máximo (se ha quedado sin gasolina, llueve…): baja poco a poco, sin frenazo
	if s.Speed > maxSpeed then
		s.Speed = math.max(maxSpeed, s.Speed - 25 * dt)
	end

	-- Girar: más fácil despacio, más suave rápido (y al revés en marcha atrás)
	local moving = math.clamp(math.abs(s.Speed) / 6, 0, 1)
	local gentle = 1 - 0.45 * fast
	local direction = if s.Speed >= 0 then 1 else -1
	local fourWheels = tuning.Lean == 0 and not tuning.Standing
	-- Con el freno de mano, el coche gira más (la trasera se va) y derrapa un poco
	local drift = handbrake and fourWheels and math.abs(s.Speed) > 8
	local turn = tuning.Turn * road.Turn * moving * gentle * (if drift then 1.5 else 1)
	s.Yaw -= steer * turn * direction * dt
	-- Hacia dónde va de verdad: con buen agarre, hacia donde apunta; si resbala, se queda atrás
	s.Travel = Wetness.slide(s.Travel, s.Yaw, road.Traction * (if drift then 0.3 else 1), dt)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = { s.Model }
	for _, other in Players:GetPlayers() do
		if other.Character then
			table.insert(ignore, other.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	params.RespectCanCollide = true
	params.IgnoreWater = false

	local size = s.Chassis.Size
	local base = s.Base -- punto a ras de suelo
	local forward = Vector3.new(-math.sin(s.Yaw), 0, -math.cos(s.Yaw))
	local heading = Vector3.new(-math.sin(s.Travel), 0, -math.cos(s.Travel))
	local move = heading * s.Speed * dt

	-- Choques: un rayo por delante (o por detrás) a media altura, desde las dos esquinas, y otro
	-- desde el centro de la base hasta el morro (lo fino que pase entre las esquinas, o algo que ya
	-- esté metido en el morro, también para)
	s.Blocker = nil
	if math.abs(s.Speed) > 0.1 then
		local sign = if s.Speed > 0 then 1 else -1
		local right = Vector3.new(-forward.Z, 0, forward.X)
		local reach = math.abs(s.Speed) * dt + 0.8
		for _, side in { -0.4, 0.4, 0 } do
			local nose = if side == 0 then 0 else size.Z / 2 - 0.5
			local length = if side == 0 then size.Z / 2 - 0.5 + reach else reach
			local origin = base + Vector3.new(0, 1.6, 0) + right * size.X * side + forward * sign * nose
			local hit = workspace:Raycast(origin, heading * sign * length, params)
			if hit and hit.Normal.Y < 0.6 then
				s.Blocker = if personOf(hit.Instance) then "Persona" else "Pared"
				SoundFx.crash(math.abs(s.Speed), s.Chassis)
				-- Golpe en la cámara (y en el mando) según lo rápido que ibas; un roce lento, nada
				if math.abs(s.Speed) > 6 then
					CameraShake.shake(math.clamp(math.abs(s.Speed) / 35, 0.2, 1.4), 0.35)
				end
				s.Speed = -s.Speed * 0.15 -- rebote suave
				s.Throttle = 0
				move = Vector3.zero
				break
			end
		end
	end

	-- El tráfico (lo mueve cada ordenador y sus piezas no chocan): si el siguiente paso se mete en un
	-- coche, una moto o una bici del tráfico, choca como con una pared. (Si ya estabais tocándoos,
	-- se puede salir: solo para lo que te acerca más a él.)
	if not tuning.Boat and move.Magnitude > 1e-4 then
		local nextBase = base + move
		local ok, hitAt = pcall(Traffic.blocking, nextBase, forward, size.Z, size.X)
		if ok and hitAt and (hitAt - nextBase).Magnitude < (hitAt - base).Magnitude + 1e-3 then
			s.Blocker = "Trafico"
			SoundFx.crash(math.abs(s.Speed), s.Chassis)
			if math.abs(s.Speed) > 6 then
				CameraShake.shake(math.clamp(math.abs(s.Speed) / 35, 0.2, 1.4), 0.35)
			end
			s.Speed = -s.Speed * 0.15
			s.Throttle = 0
			move = Vector3.zero
		end
	end

	if tuning.Boat then
		boatStep(s, ignore, forward, heading, move, steer, maxSpeed, tuning, dt)
		SoundFx.vehicleSpeed(math.clamp(math.abs(s.Speed) / maxSpeed, 0, 1))
		VehicleHud.update(s.Speed, dt)
		return
	end

	-- Suelo: delante y detrás (para la cuesta) y en el centro
	local target = base + move
	local top = target.Y + 3.2 -- sube escalones de hasta ~3 studs
	local centre = ground(params, target, top)
	if not centre then
		s.Speed = 0 -- agua o el borde del mapa: no se puede seguir
		move = Vector3.zero
		target = base
		centre = ground(params, base, base.Y + 3.2)
	end
	-- Bajo las calles el terreno está vaciado: si el rayo atraviesa la calzada (aún sin cargar, un
	-- hueco…) y da con el terreno muy por debajo, no se baja ahí (así nunca se queda bajo el suelo)
	if centre and centre.Instance == workspace.Terrain and centre.Position.Y < base.Y - 2.5 then
		centre = nil
	end
	local y = if centre then centre.Position.Y else target.Y
	local front = ground(params, target + forward * (size.Z * 0.4), top)
	local back = ground(params, target - forward * (size.Z * 0.4), top)
	local up = Vector3.yAxis
	if front and back then
		local slope = (front.Position - back.Position)
		if slope.Magnitude > 0.1 then
			local side = slope.Unit:Cross(Vector3.yAxis)
			if side.Magnitude > 0.1 then
				up = side.Unit:Cross(slope.Unit)
				if up.Y < 0 then
					up = -up
				end
			end
		end
	end
	up = Driving.limitTilt(up)
	-- Si el suelo baja mucho (un escalón hacia abajo), cae suave en vez de pegarse de golpe;
	-- al subir un bordillo también sube suave (sin saltito)
	if y < target.Y - 0.5 then
		y = math.max(y, target.Y - 60 * dt)
	elseif y > target.Y + 0.05 then
		y = math.min(y, target.Y + math.max(12, math.abs(s.Speed) * 0.8) * dt)
	end
	s.Up = Driving.limitTilt(s.Up:Lerp(up, math.min(1, dt * 8)))

	-- Inclinarse en las curvas (motos, bicis, patinetes)
	local leanTarget = -steer * math.rad(tuning.Lean) * math.clamp(math.abs(s.Speed) / (maxSpeed * 0.6), 0, 1)
	s.Lean += (leanTarget - s.Lean) * math.min(1, dt * 6)

	local position = Vector3.new(target.X, y, target.Z)
	s.Base = position
	local look = (forward - s.Up * forward:Dot(s.Up)).Unit
	local oriented = CFrame.lookAt(position, position + look, s.Up) * CFrame.Angles(0, 0, s.Lean)
	s.Chassis.CFrame = oriented * CFrame.new(0, size.Y / 2, 0)
	s.Chassis.AssemblyLinearVelocity = heading * s.Speed
	s.Chassis.AssemblyAngularVelocity = Vector3.zero

	-- Pisando y sin moverse un rato: atascado (se saca a un sitio libre al lado)
	local moved = Vector3.new(position.X - base.X, 0, position.Z - base.Z).Magnitude
	if RideSpot.stuckStep(s, wantThrottle, if dt > 0 then moved / dt else 0, dt) then
		unstick(s, forward)
	end

	SoundFx.vehicleSpeed(math.clamp(math.abs(s.Speed) / maxSpeed, 0, 1))
	VehicleHud.update(s.Speed, dt)
end

-- Deja de conducir ya (al bajarse: Controllers/Vehicles no espera al servidor)
function Driving.release()
	stop()
end

-- Para la cámara y las posturas: el volante (-1..1) y la velocidad del vehículo que conduces
function Driving.current(): (Model?, number, number)
	local s = state
	if not s then
		return nil, 0, 0
	end
	return s.Model, s.Steer, s.Speed
end

function Driving.init()
	VehicleHud.init(player:WaitForChild("PlayerGui"))
	buildTouch()

	local function watch(character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if not humanoid then
			return
		end
		humanoid.Seated:Connect(function(active, seat)
			if active and seat and seat:IsA("VehicleSeat") and seat.Name == "DriverSeat" then
				stop()
				start(seat, humanoid)
			else
				stop()
			end
		end)
		humanoid.Died:Connect(stop)
	end
	if player.Character then
		task.spawn(watch, player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		stop()
		watch(character)
	end)

	-- Antes de la física de cada fotograma: así el movimiento sale suave para todos
	RunService.PreSimulation:Connect(step)

	-- Vigilancia (4 veces por segundo): sentado al volante sin conducir (la base del vehículo llegó
	-- después que el asiento) -> se empieza; «montado» para el servidor sin estar sentado al volante
	-- -> se pide que te vuelva a sentar y, si tampoco, bajarse del todo (nada de ir a pie con los
	-- pedales en pantalla, la velocidad del coche y el coche medio hundido pegado a ti)
	local watch = {}
	local every = 0
	RunService.Heartbeat:Connect(function(dt)
		every += dt
		if every < 0.25 then
			return
		end
		every = 0
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local seat = humanoid and humanoid.SeatPart
		local model = seat and seat.Parent
		local atWheel = seat ~= nil and seat:IsA("VehicleSeat") and seat.Name == "DriverSeat" and model ~= nil and model:GetAttribute("Drivable") == true
		if atWheel and humanoid and humanoid.Health > 0 and (not state or state.Seat ~= seat) then
			stop()
			start(seat :: VehicleSeat, humanoid)
		end
		local alive = humanoid ~= nil and humanoid.Health > 0
		local action = RideSpot.watchSeat(watch, os.clock(), alive and player:GetAttribute("Riding") ~= nil, atWheel)
		if action then
			local remotes = ReplicatedStorage:FindFirstChild("Remotes")
			local remote = remotes and remotes:FindFirstChild("Vehicle")
			if remote and remote:IsA("RemoteEvent") then
				remote:FireServer(action)
			end
			if action == "Dismount" then
				stop()
			end
		end
	end)
end

return Driving
