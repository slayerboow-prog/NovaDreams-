-- Driving (cliente): conducir coches, motos, bicis, monopatines y patinetes.
--
-- Cuando te sientas en el asiento de conductor ("DriverSeat") de un vehículo con el atributo
-- Drivable, este script lo mueve cada fotograma:
--   * W/S o ↑/↓: acelerar, frenar y marcha atrás · A/D o ←/→: girar · Espacio (o Ctrl): freno de mano
--     · L: luces (mantener: largas) · Q / E: intermitente izquierdo / derecho · X: emergencia · H: claxon
--   * Mando: gatillo derecho acelera, gatillo izquierdo frena (los dos a medias, poco a poco),
--     joystick izquierdo gira, A es el freno de mano, LB / RB los intermitentes, Y la emergencia y
--     R3 (pulsar el joystick derecho) las luces
--   * Móvil (al volante): a la izquierda dos flechas ◀ ▶ para girar (el joystick se esconde; arrastrar
--     el dedo por la pantalla sigue moviendo la cámara) y a la derecha los pedales ACELERAR y FRENO,
--     el freno de mano, las luces, los intermitentes ⬅ ➡ y la emergencia ⚠, Bajarse y el claxon
--     (UI/DriveButtons, colocados por UI/TouchLayout en HudLayout.Drive: nada se pisa)
--   * Freno: frena y, ya parado, si lo sigues pisando da marcha atrás (igual con S y con el gatillo)
--   * Freno de mano: mantenido en marcha bloquea las ruedas de atrás (derrapa); tocado parado se
--     queda echado (P) hasta que aceleras, frenas o lo vuelves a tocar (shared/VehicleControls)
--   * Luces, intermitentes (se apagan solos al acabar el giro), pilotos de freno y de marcha atrás:
--     el servidor los pone como atributos del vehículo y todos los ven (Controllers/VehicleLights).
--     De noche, con las luces apagadas, se sugiere una vez encenderlas
--   * Todo entra suave: el acelerador y el volante no saltan de 0 a 1, van subiendo y bajando
--     (y el volante vuelve solo al centro). Cuanto más rápido vas, menos y más despacio gira.
--   * Freno de mano: frena en seco; en coche, si giras a la vez, la trasera derrapa un poco
--   * Sigue el suelo con rayos: sube bordillos pequeños y cuestas, y se inclina con ellas (nunca
--     más de lo que toca: no vuelca). Al volante, el chasis no choca con la física en tu ordenador
--     (solo los rayos de este script): si no, al pisar el bordillo o el césped la física lo empujaba
--     fuera del escalón cada fotograma y el coche temblaba, rebotaba o se quedaba enganchado
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
--     libre al lado (RideSpot.unstick).
--   * Choques con otros vehículos (Controllers/Collisions + shared/Crash): el tráfico, los coches de
--     otros jugadores, los aparcados, autobuses y patrullas. Impulso según las masas y la velocidad,
--     rebote pequeño, giro si el golpe es descentrado, empujón de lado que se va apagando (Push,
--     Spin) y nunca metidos uno en otro. En moto o bici, un golpe fuerte te tira al suelo.
--   * Papeleras, conos, terrazas, motos de adorno… y personas: el coche no frena en seco contra
--     ellos; salen despedidos (Collisions.touchProps → KnockService). Los rayos no los ven (grupo
--     de choque Knock.RayGroup).
-- F (o B en el mando) para bajarse (en el móvil, el botón "Bajarse"; lo hace Controllers/Vehicles
-- y funciona siempre a la primera). El servidor
-- (VehicleService) le da el control a tu ordenador, así que se mueve sin retraso y los demás
-- (también tus pasajeros) lo ven igual. La cámara la lleva RideCamera.luau.

local ContextActionService = game:GetService("ContextActionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Boats = require(ReplicatedStorage.Shared.Boats)
local Wetness = require(ReplicatedStorage.Shared.Wetness)
local Crash = require(ReplicatedStorage.Shared.Crash)
local RideSpot = require(ReplicatedStorage.Shared.RideSpot)
local VehicleControls = require(ReplicatedStorage.Shared.VehicleControls)
local Tyres = require(ReplicatedStorage.Shared.Tyres)
local Traffic = require(script.Parent.Traffic)
local Collisions = require(script.Parent.Collisions)
local Joystick = require(script.Parent.Joystick)
local VehicleLights = require(script.Parent.VehicleLights)
local DriveButtons = require(script.Parent.Parent.UI.DriveButtons)
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
	Controls: VehicleControls.Controls, -- luces, intermitentes y freno de mano echado
	Handbrake: boolean, -- el freno de mano actúa ahora (pulsado o echado)
	Braking: boolean,
	Blink: boolean, -- el intermitente luce en este instante (para el tic-tac)
	Sent: { [string]: any }?, -- lo último mandado al servidor
	SentAt: number,
	Push: Vector3, -- empujón de lado de un choque (se apaga solo: Crash.settle)
	Spin: number, -- giro por un choque (rad/s)
	Thrown: boolean?, -- ya te has caído de la moto con este golpe
	Tyre: { MaxSpeed: number, Turn: number, Traction: number, Pull: number, Count: number }?, -- ruedas pinchadas (shared/Tyres)
	TyreAt: number?,
	Flap: number?, -- lo que ha rodado desde el último «flap» de la rueda pinchada
	Collide: boolean?, -- cómo estaba el CanCollide del chasis al subirse (se deja igual al bajarse)
}
local state: State? = nil
local warnRoad: () -> ()
local unstick: (State, Vector3) -> ()

-- Mandos en pantalla (móvil, UI/DriveButtons): lo que se mantiene pulsado ahora
local touch = { Gas = false, Brake = false, Left = false, Right = false, Handbrake = false }
local syncJoystick: () -> ()
local function refreshPedals()
	pcall(TouchLayout.refresh)
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
		handbrake = keyDown(Enum.KeyCode.Space, Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl)
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
		handbrake = handbrake or UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonA)
	end
	-- Pantalla (móvil): pedales y flechas
	throttle += VehicleControls.pedalThrottle(touch.Gas, touch.Brake)
	steer += VehicleControls.arrowSteer(touch.Left, touch.Right)
	handbrake = handbrake or touch.Handbrake
	-- El joystick del móvil (cuando está a la vista: sin flechas ni pedales en pantalla) gira y, hacia
	-- delante o atrás, acelera y frena. Se lee directamente (el asiento lo pueden pisar los controles
	-- de Roblox en cada fotograma)
	if math.abs(throttle) < 0.05 and math.abs(steer) < 0.05 then
		local ok, stick = pcall(Joystick.moveVector)
		if ok and typeof(stick) == "Vector3" and stick.Magnitude > 0.05 then
			throttle, steer = -stick.Z, stick.X
		end
	end
	-- Si nada de lo anterior, lo que diga Roblox (el asiento)
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

-- Altura del vehículo al pasar un escalón (bordillo, acera, césped, rampa): sube rápido pero en
-- varios fotogramas (sin saltito) y, si el suelo baja mucho, cae suave en vez de pegarse de golpe.
-- current: la altura de ahora; ground: la del suelo bajo el centro
function Driving.climb(current: number, ground: number, speed: number, dt: number): number
	if ground < current - 0.5 then
		return math.max(ground, current - 60 * dt)
	elseif ground > current + 0.05 then
		return math.min(ground, current + math.max(12, math.abs(speed) * 0.8) * dt)
	end
	return ground
end

-- Velocidad que se le da al chasis cada fotograma: la de la marcha y un poco hacia arriba que
-- compensa justo la gravedad de ese paso de la física (sin choques, si no, se hundiría un pelo cada
-- fotograma y temblaría)
function Driving.chassisVelocity(planar: Vector3, gravity: number, dt: number): Vector3
	return planar + Vector3.new(0, gravity * dt / 2, 0)
end

-- El chasis, mientras lo conduces: sin choques de física SOLO en tu ordenador (que es quien lo
-- mueve). Los bordillos, paredes y el suelo los resuelven los rayos; los demás jugadores siguen
-- chocando con él (para ellos CanCollide no cambia)
local function ghostChassis(s: State, on: boolean)
	pcall(function()
		if on then
			if s.Collide == nil then
				s.Collide = s.Chassis.CanCollide
			end
			s.Chassis.CanCollide = false
		elseif s.Collide ~= nil and s.Chassis.Parent then
			s.Chassis.CanCollide = s.Collide
		end
	end)
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

-- Mandos en pantalla (UI/DriveButtons): flechas, pedales, freno de mano, luces e intermitentes.
-- Los coloca TouchLayout (al volante, HudLayout.Drive) y solo se ven conduciendo de verdad.
local toggleLights: (boolean) -> ()
local toggleIndicator: (string) -> ()
local function buildTouch()
	DriveButtons.register(TouchLayout, {
		Driving = function()
			return state ~= nil
		end,
		Kind = function()
			return if state then state.Kind else nil
		end,
		Hold = function(slot: string, down: boolean)
			(touch :: any)[slot] = down
		end,
		Lights = function(long: boolean)
			toggleLights(long)
		end,
		Indicator = function(side: string)
			toggleIndicator(side)
		end,
		Status = function()
			local s = state
			if not s then
				return { Lights = 0, Indicator = "", Hazard = false, Parked = false, Reversing = false }
			end
			local c = s.Controls
			return { Lights = c.Lights, Indicator = c.Indicator, Hazard = c.Hazard, Parked = c.Parked, Reversing = s.Speed < -0.5 }
		end,
	})
end

local function releasePedals()
	for slot in touch do
		(touch :: any)[slot] = false
	end
end

-- El joystick se esconde SOLO si las flechas y los pedales se ven de verdad en pantalla. Si no han
-- salido (un fallo, una pantalla rara…), el joystick sigue ahí y conduce (readInput lo lee): nunca
-- te quedas al volante sin forma de girar ni de andar. Se revisa al subir y 4 veces por segundo.
local DRIVE_IDS = { "GiroIzq", "GiroDer", "Acelerar", "Frenar" }
function syncJoystick()
	local ok, shown = pcall(TouchLayout.shows, DRIVE_IDS)
	local hide = state ~= nil and ok and shown == true
	if not hide then
		-- (sin los botones, lo que estuviera pulsado no se puede soltar: fuera)
		touch.Gas, touch.Brake, touch.Left, touch.Right = false, false, false, false
	end
	pcall(Joystick.setDriving, hide)
end

---------------------------------------------------------------------
-- Luces, intermitentes y freno de mano (shared/VehicleControls)
---------------------------------------------------------------------
local lightsHinted = false -- «Enciende las luces»: una vez por partida

function toggleLights(long: boolean)
	local s = state
	if not s or not VehicleControls.features(s.Kind).Lights then
		return
	end
	s.Controls.Lights = VehicleControls.nextLights(s.Controls.Lights, long)
	lightsHinted = true -- (ya sabe dónde están)
	SoundFx.lightSwitch()
	refreshPedals()
end

function toggleIndicator(side: string)
	local s = state
	if not s or not VehicleControls.features(s.Kind).Indicators then
		return
	end
	VehicleControls.toggleIndicator(s.Controls, side)
	SoundFx.indicatorTick(VehicleControls.indicatorShown(s.Controls) ~= "")
	refreshPedals()
end

-- De noche y con las luces apagadas: se sugiere encenderlas (una vez por partida)
local function hintLights()
	local s = state
	if s and VehicleControls.shouldHint(Lighting.ClockTime, s.Controls.Lights, lightsHinted, s.Kind) then
		lightsHinted = true
		Hud.toast("Info", if TouchLayout.isTouch() then "💡 Es de noche: enciende las luces (botón «Luces»)." else "💡 Es de noche: enciende las luces (L).")
	end
end

-- Lo que se ve del vehículo: se pinta ya en tu pantalla (VehicleLights.setLocal) y se manda al
-- servidor (que lo pone para todos) solo cuando cambia, como mucho 10 veces por segundo
local SEND_EVERY = 0.1
local function publishLamps(s: State)
	local c = s.Controls
	local lamps = {
		Lights = c.Lights,
		Indicator = VehicleControls.indicatorShown(c),
		Braking = s.Braking,
		Reversing = s.Speed < -0.3,
		Handbrake = s.Handbrake,
	}
	VehicleLights.setLocal(s.Model, lamps)
	-- Testigos del cuadro y el tic-tac del intermitente
	local blink = lamps.Indicator ~= "" and VehicleControls.blinkOn(os.clock())
	if blink ~= s.Blink then
		s.Blink = blink
		SoundFx.indicatorTick(blink)
	end
	VehicleHud.setStatus({
		Left = blink and (lamps.Indicator == "L" or lamps.Indicator == "H"),
		Right = blink and (lamps.Indicator == "R" or lamps.Indicator == "H"),
		Lights = c.Lights,
		Parked = c.Parked,
		Handbrake = s.Handbrake,
	})
	local now = os.clock()
	if VehicleControls.same(s.Sent, lamps) or now - s.SentAt < SEND_EVERY then
		return
	end
	s.Sent = lamps
	s.SentAt = now
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local remote = remotes and remotes:FindFirstChild("Vehicle")
	if remote and remote:IsA("RemoteEvent") then
		remote:FireServer("Lamps", lamps)
	end
end

-- Teclas y botones del mando mientras conduces (por encima de agacharse, la linterna, pelear, los
-- menús…). Espacio y A ya no te bajan del asiento: son el freno de mano (bajarse es F / B).
local DRIVE_PRIORITY = 3200
local DRIVE_ACTIONS = { "DriveHandbrake", "DriveLights", "DriveIndicatorLeft", "DriveIndicatorRight", "DriveHazards" }
local lightsDownAt: number? = nil
local function bindDriveKeys()
	local function sink(fn: ((Enum.UserInputState) -> ())?)
		return function(_, inputState: Enum.UserInputState)
			if UserInputService:GetFocusedTextBox() then
				return Enum.ContextActionResult.Pass
			end
			if fn then
				fn(inputState)
			end
			return Enum.ContextActionResult.Sink
		end
	end
	-- (el freno de mano se lee en readInput: aquí solo se evita que Espacio / A salten del asiento)
	ContextActionService:BindActionAtPriority("DriveHandbrake", sink(nil), false, DRIVE_PRIORITY, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
	-- Luces: tocar = cortas / apagar; mantener = largas
	ContextActionService:BindActionAtPriority("DriveLights", sink(function(inputState)
		if inputState == Enum.UserInputState.Begin then
			local at = os.clock()
			lightsDownAt = at
			task.delay(VehicleControls.HIGH_BEAM_HOLD, function()
				if lightsDownAt == at then
					lightsDownAt = nil
					toggleLights(true)
				end
			end)
		elseif inputState == Enum.UserInputState.End and lightsDownAt then
			lightsDownAt = nil
			toggleLights(false)
		end
	end), false, DRIVE_PRIORITY, Enum.KeyCode.L, Enum.KeyCode.ButtonR3)
	local function indicatorKey(side: string)
		return sink(function(inputState)
			if inputState == Enum.UserInputState.Begin then
				toggleIndicator(side)
			end
		end)
	end
	ContextActionService:BindActionAtPriority("DriveIndicatorLeft", indicatorKey("L"), false, DRIVE_PRIORITY, Enum.KeyCode.Q, Enum.KeyCode.ButtonL1)
	ContextActionService:BindActionAtPriority("DriveIndicatorRight", indicatorKey("R"), false, DRIVE_PRIORITY, Enum.KeyCode.E, Enum.KeyCode.ButtonR1)
	ContextActionService:BindActionAtPriority("DriveHazards", indicatorKey("H"), false, DRIVE_PRIORITY, Enum.KeyCode.X, Enum.KeyCode.ButtonY)
end

local function unbindDriveKeys()
	lightsDownAt = nil
	for _, action in DRIVE_ACTIONS do
		pcall(function()
			ContextActionService:UnbindAction(action)
		end)
	end
end

---------------------------------------------------------------------
-- Subir y bajar
---------------------------------------------------------------------

local function start(seat: VehicleSeat, humanoid: Humanoid)
	local model = seat.Parent
	if not model or not model:IsA("Model") or not model:GetAttribute("Drivable") then
		return
	end
	-- La base: PrimaryPart o, si esa referencia aún no ha llegado (StreamingEnabled), la pieza "Chassis"
	local base = model.PrimaryPart or model:FindFirstChild("Chassis")
	if not base or not base:IsA("BasePart") then
		return -- (aún no ha llegado: la vigilancia de Driving.init lo vuelve a intentar enseguida)
	end
	local kind = model:GetAttribute("Kind")
	if typeof(kind) ~= "string" or not Gameplay.Driving[kind] then
		return
	end
	local chassis = base :: BasePart
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
		Controls = (function()
			local c = VehicleControls.new()
			c.Hazard = model:GetAttribute("Indicator") == "H" -- (si las dejaste puestas al bajarte, siguen)
			return c
		end)(),
		Handbrake = false,
		Braking = false,
		Blink = false,
		SentAt = -math.huge,
		Push = Vector3.zero,
		Spin = 0,
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
	ghostChassis(s, true)
	releasePedals()
	-- Lo primero, los mandos: flechas y pedales en pantalla y las teclas del coche. Lo demás (cuadro,
	-- sonido, avisos) va protegido: si algo de eso falla, nunca te quedas al volante sin mandos
	pcall(TouchLayout.setDriving, true)
	pcall(bindDriveKeys)
	for _, extra in {
		function()
			VehicleHud.show(kind)
		end,
		function()
			SoundFx.vehicleStart(kind, chassis)
		end,
		hintLights,
		function()
			if not Gameplay.Driving[kind].Boat then
				warnRoad() -- (en el mar da igual que llueva)
			end
		end,
	} do
		local ok, err = pcall(extra)
		if not ok then
			warn("[Driving] " .. tostring(err))
		end
	end
	refreshPedals()
	syncJoystick()
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
	VehicleLights.setLocal(state.Model, nil)
	ghostChassis(state, false)
	state = nil
	VehicleHud.hide()
	SoundFx.vehicleStop()
	releasePedals()
	unbindDriveKeys()
	pcall(Joystick.setDriving, false)
	pcall(TouchLayout.setDriving, false)
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
	s.Chassis.AssemblyLinearVelocity = Driving.chassisVelocity(heading * s.Speed, workspace.Gravity, dt)
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
	local simDt = dt -- (el paso de la física de verdad: para compensar la gravedad)
	dt = math.min(dt, 1 / 15) -- (un tirón del ordenador no lanza el coche)
	local tuning = Gameplay.Driving[s.Kind]
	-- Lluvia y nieve: menos agarre
	local grip = Wetness.grip(s.Kind, workspace:GetAttribute("Wet") or 0, workspace:GetAttribute("Snow") or 0)
	local road = if tuning.Boat then BOAT_ROAD else Wetness.drive(grip)
	local maxSpeed = Gameplay.Vehicles[s.Kind].Speed * road.MaxSpeed
	-- Ruedas pinchadas (atributos Flat_… que pone el servidor): corre y agarra menos y tira hacia
	-- ese lado (se mira 4 veces por segundo)
	local now = os.clock()
	if not s.Tyre or now - (s.TyreAt or 0) > 0.25 then
		s.TyreAt = now
		s.Tyre = if tuning.Boat then Tyres.effects({}) else Tyres.effects(Tyres.flats(s.Model:GetAttributes()))
	end
	local tyre = s.Tyre :: any
	local topSpeed = maxSpeed
	maxSpeed *= tyre.MaxSpeed
	if player:GetAttribute("OutOfFuel") then
		maxSpeed = 4 -- sin gasolina (o batería) apenas avanza: hay que llegar a una gasolinera
	end
	local wantThrottle, wantSteer, handbrakeDown = readInput(s.Seat)
	-- Freno de mano: mantenido actúa; tocado parado se queda echado (y se quita al pisar un pedal)
	local handbrake = handbrakeDown
	if VehicleControls.features(s.Kind).Handbrake then
		local event
		handbrake, event = VehicleControls.handbrakeStep(s.Controls, handbrakeDown, s.Speed, wantThrottle)
		if event then
			SoundFx.handbrake(event == "Echado")
			refreshPedals()
		end
		if s.Controls.Parked then
			wantThrottle = 0
		end
	end
	s.Handbrake = handbrake
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
	local turn = tuning.Turn * road.Turn * tyre.Turn * moving * gentle * (if drift then 1.5 else 1)
	local turnedRight = steer * turn * direction * dt
	s.Yaw -= turnedRight
	-- Con una rueda pinchada, tira hacia su lado (más cuanto más rápido) y suena el «flap» de la goma
	if tyre.Count > 0 then
		s.Yaw += tyre.Pull * direction * math.clamp(math.abs(s.Speed) / math.max(topSpeed, 1), 0, 1) * dt
		s.Flap = (s.Flap or 0) + math.abs(s.Speed) * dt
		if s.Flap > 8 then -- (una vuelta de rueda, más o menos)
			s.Flap = 0
			SoundFx.play("PinchazoFlap", 0.6 + 0.4 * fast, nil, s.Chassis)
		end
	end
	-- Intermitente: se apaga solo al acabar el giro (girado hacia su lado y el volante de vuelta)
	if VehicleControls.indicatorStep(s.Controls, turnedRight, steer) then
		refreshPedals()
	end
	-- Pilotos: frenando (pedal contra la marcha o el freno de mano en marcha) y marcha atrás
	s.Braking = VehicleControls.pedalMeaning(wantThrottle, s.Speed) == "Frena" or (handbrake and math.abs(s.Speed) > 0.5)
	publishLamps(s)
	-- Un choque descentrado hace girar (y se apaga con el agarre de las ruedas)
	if s.Spin ~= 0 then
		s.Yaw += s.Spin * dt
		s.Travel += s.Spin * dt
	end
	s.Push, s.Spin = Crash.settle(s.Push, s.Spin, dt)
	-- Hacia dónde va de verdad: con buen agarre, hacia donde apunta; si resbala, se queda atrás
	s.Travel = Wetness.slide(s.Travel, s.Yaw, road.Traction * tyre.Traction * (if drift then 0.3 else 1), dt)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = { s.Model }
	for _, other in Players:GetPlayers() do
		if other.Character then
			table.insert(ignore, other.Character)
		end
	end
	-- (los vehículos cercanos no son paredes: de ellos se encarga el choque de verdad, Collisions)
	for _, m in Collisions.rayIgnore() do
		table.insert(ignore, m)
	end
	params.FilterDescendantsInstances = ignore
	params.RespectCanCollide = true
	params.IgnoreWater = false
	-- Lo que se puede tumbar (papeleras, conos, terrazas…) no para el coche: sale despedido
	local rayGroup = Collisions.rayGroup()
	if rayGroup then
		params.CollisionGroup = rayGroup
	end

	local size = s.Chassis.Size
	local base = s.Base -- punto a ras de suelo
	local forward = Vector3.new(-math.sin(s.Yaw), 0, -math.cos(s.Yaw))
	local heading = Vector3.new(-math.sin(s.Travel), 0, -math.cos(s.Travel))
	local move = heading * s.Speed * dt + s.Push * dt

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
			if hit and hit.Normal.Y < 0.6 and personOf(hit.Instance) then
				-- Una persona no es una pared: sale despedida (Collisions.touchProps)
				s.Blocker = "Persona"
			elseif hit and hit.Normal.Y < 0.6 then
				s.Blocker = "Pared"
				SoundFx.crash(math.abs(s.Speed), s.Chassis)
				pcall(Collisions.wall, s, hit.Position, hit.Normal, math.abs(s.Speed))
				-- Golpe en la cámara (y en el mando) según lo rápido que ibas; un roce lento, nada
				if math.abs(s.Speed) > 6 then
					CameraShake.shake(math.clamp(math.abs(s.Speed) / 35, 0.2, 1.4), 0.35)
				end
				s.Speed = -s.Speed * 0.15 -- rebote suave
				s.Throttle = 0
				s.Push = Vector3.zero
				move = Vector3.zero
				break
			end
		end
	end

	-- Empujado de lado contra una pared: el empujón se acaba ahí (no se mete en ella)
	if s.Push.Magnitude > 1 then
		local hit = workspace:Raycast(base + Vector3.new(0, 1.6, 0), s.Push.Unit * (size.X / 2 + s.Push.Magnitude * dt + 0.3), params)
		if hit and hit.Normal.Y < 0.6 and not personOf(hit.Instance) then
			move -= s.Push * dt
			s.Push = Vector3.zero
		end
	end

	-- Otros vehículos (el tráfico, otros jugadores, aparcados, autobuses, patrullas): choque de verdad
	-- con masas, rebote, giro y sin quedar metidos (Collisions + shared/Crash). Los barcos no: tienen
	-- su propia regla en el agua.
	if not tuning.Boat then
		local okSolve, solved = pcall(Collisions.solve, s, base, move, forward, dt, maxSpeed)
		if okSolve and typeof(solved) == "Vector3" then
			move = solved
		end
		-- Papeleras, conos, terrazas, balones, personas…: salen despedidos
		pcall(Collisions.touchProps, s, base, forward, s.Speed)
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
	y = Driving.climb(target.Y, y, s.Speed, dt)
	s.Up = Driving.limitTilt(s.Up:Lerp(up, math.min(1, dt * 8)))

	-- Inclinarse en las curvas (motos, bicis, patinetes)
	local leanTarget = -steer * math.rad(tuning.Lean) * math.clamp(math.abs(s.Speed) / (maxSpeed * 0.6), 0, 1)
	s.Lean += (leanTarget - s.Lean) * math.min(1, dt * 6)

	local position = Vector3.new(target.X, y, target.Z)
	s.Base = position
	local look = (forward - s.Up * forward:Dot(s.Up)).Unit
	local oriented = CFrame.lookAt(position, position + look, s.Up) * CFrame.Angles(0, 0, s.Lean)
	if s.Chassis.CanCollide then
		ghostChassis(s, true) -- (por si el servidor lo ha vuelto a poner)
	end
	s.Chassis.CFrame = oriented * CFrame.new(0, size.Y / 2, 0)
	s.Chassis.AssemblyLinearVelocity = Driving.chassisVelocity(heading * s.Speed + s.Push, workspace.Gravity, simDt)
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

-- Para la cámara, las posturas y las ruedas (Controllers/WheelSpin): el volante (-1..1), la velocidad
-- y el freno de mano del vehículo que conduces
function Driving.current(): (Model?, number, number, boolean)
	local s = state
	if not s then
		return nil, 0, 0, false
	end
	return s.Model, s.Steer, s.Speed, s.Handbrake
end

function Driving.init()
	VehicleHud.init(player:WaitForChild("PlayerGui"))
	buildTouch()
	-- Choques: el servidor avisa de golpes de otros jugadores ("Impact") y de atropellos ("Knocked")
	Collisions.init(function()
		return state
	end)

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
	-- (si un fotograma falla, el chasis vuelve a chocar con la física: nunca se cae por el suelo)
	local warnedStep = false
	RunService.PreSimulation:Connect(function(dt: number)
		local ok, err = pcall(step, dt)
		if not ok then
			if state then
				ghostChassis(state, false)
			end
			if not warnedStep then
				warnedStep = true
				warn("[Driving] " .. tostring(err))
			end
		end
	end)

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
		if state then
			syncJoystick() -- (¿siguen a la vista las flechas y los pedales? si no, vuelve el joystick)
		end
		hintLights() -- (si se hace de noche conduciendo)
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
