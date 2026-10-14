-- Flying (cliente): pilotar los aviones del aeroclub (Services/AviationService) con Shared/Flight.
--
-- Cuando el servidor te sienta en el asiento del piloto ("PilotSeat" de un modelo PilotPlane; atributo
-- Piloting), tu ordenador mueve el avión cada fotograma (es dueño de sus piezas) con el modelo de vuelo:
--   * Ordenador: W/S morro (W sube, S baja) · A/D alabeo · Q/E timón (en tierra gira la rueda de morro) ·
--     Shift/Ctrl motor · B frenos (mantener) · G tren · F flaps · C cámara (persecución / cabina) ·
--     Espacio bajarse (parado en tierra). También las flechas para el morro y el alabeo.
--   * Mando: joystick izquierdo palanca (hacia ATRÁS sube el morro, como un avión de verdad; a los lados
--     alabea), RT/LT motor, RB/LB timón, X frenos, Y tren, ↓ flaps, R3 cámara, A bajarse.
--   * Móvil: la PALANCA analógica de la nave (UI/FlightStick): el pulgar en la mitad izquierda y
--     arrastra. TIRAR HACIA ABAJO SUBE EL MORRO (Flight.stickInput): es lo que hace todo el mundo sin
--     pensar. El vídeo del dueño (docs/bugs/avion-video): con la palanca abajo todo el rato, a 120 km/h y
--     el motor a tope, la avioneta no despegaba (abajo bajaba el morro) y acabó en el agua. A los lados
--     alabea y gira (timón automático); en tierra, la rueda de morro.
--   * «Tirar hacia abajo para subir: Sí/No» (⚙️ Ajustes y la ranura PALANCA del HUD: Flying.setInverted)
--     cambia la palanca y el mando (las teclas W/S no cambian). No se guarda: por defecto, Sí.
--   * Ayuda al despegar (Shared/Flight con env.runway = Shared/Airport.runwayLeft): pasada Vr sin tirar,
--     el HUD dice «TIRA HACIA ABAJO PARA DESPEGAR» y la palanca enseña una flecha que late; cerca del
--     final de la pista, «FIN DE PISTA»; a tope y sin pista, el avión rota solo (nadie acaba en el agua
--     por no saber hacia dónde tirar).
--   * HUD: el de la nave del espacio (queja del dueño: «debe ser igual que el de las naves espaciales»):
--     UI/AirCombatHud con el vehículo "Plane" de UI/ShipHudLayout, lo llena Controllers/PlaneHudClient
--     (perfil, brújula, arco de velocidad con el MOTOR, ESTRUCTURA, ALTITUD/V-S/RUMBO, radar con pistas
--     y aviones, misiones, la PISTA que queda, ranuras FLAPS, TREN, FRENO APARC., CÁMARA, PALANCA,
--     RALENTÍ, A TOPE y BAJARSE, listas de teclas en el ordenador y «?» en el móvil). Botones grandes como los de la nave
--     (UI/FlyButtons: MOTOR +, MOTOR −, FRENOS). Al volar, UI/FlightFocus y Hud.setShipFocus apartan el
--     HUD de Valmar (como en la nave) y TopStack.setPiloting("ShipHud") deja libre el panel de arriba.
--   * El cartel «Subir a bordo» de tu propio avión no sale mientras lo pilotas (y el servidor lo apaga
--     para todos mientras rueda o vuela).
--   * Cámara de persecución más alta y más lejos, suave, y que nunca se mete en el suelo.
--   * Choques: el suelo con un rayo hacia abajo (pista, hierba, agua) y el cuerpo y las alas con cajas
--     (Blockcast) por donde se mueve: en vuelo, tocar un edificio o el monte es accidente; rodando
--     despacio solo se para. Los demás aviones no cuentan (no hay choques entre aviones).
--   * Aterrizajes y accidentes se le cuentan al servidor ("Touchdown", "Crash"), y 5 veces por
--     segundo el tren, los flaps, el motor y si va en el aire ("State": lo ven los demás).
-- Para todos los aviones (también los de los vuelos con horario): balizas y destellos que parpadean y
-- la hélice que gira (disco) cuando el motor va.

local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Airport = require(ReplicatedStorage.Shared.Airport)
local Flight = require(ReplicatedStorage.Shared.Flight)
local Joystick = require(script.Parent.Joystick)
local SoundFx = require(script.Parent.SoundFx)
local CameraShake = require(script.Parent.CameraShake)
local Hud = require(script.Parent.Parent.UI.Hud)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local SceneGuis = require(script.Parent.Parent.UI.SceneGuis)
local FlyButtons = require(script.Parent.Parent.UI.FlyButtons)
local AirCombatHud = require(script.Parent.Parent.UI.AirCombatHud)
local PlaneHudClient = require(script.Parent.PlaneHudClient)
local FlightStick = require(script.Parent.Parent.UI.FlightStick)
local FlightFocus = require(script.Parent.Parent.UI.FlightFocus)
local TopStack = require(script.Parent.Parent.UI.TopStack)
local Controls = require(script.Parent.Controls)

local Flying = {}

local player = Players.LocalPlayer
local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local HAS_TOUCH = UserInputService.TouchEnabled -- (tabletas con teclado también: la palanca sale al tocar)
local INVERT_ATTR = "PlanePushToClimb" -- (ajuste local: «Tirar hacia abajo para subir: No»)
local ACTION = "FlyingToggles"
local STEP = "FlyingStep"

type Active = {
	Model: Model,
	Root: BasePart,
	Seat: BasePart,
	Kind: string,
	Spec: Flight.Spec,
	Sim: Flight.State,
	Camera: string, -- "Persecucion" | "Cabina"
	CamPos: Vector3?,
	SentAt: number,
	Sent: string,
	Engine: Sound?,
	ExitAt: number?,
	Prompts: { [ProximityPrompt]: boolean }, -- carteles de tu avión apagados mientras lo pilotas
	Conns: { RBXScriptConnection },
	-- (para el HUD: Controllers/PlaneHudClient)
	Id: string?,
	Brake: boolean?,
	PullUp: boolean?,
	CanExit: boolean?,
	CueStick: string?,
	Parking: boolean?, -- freno de aparcamiento (ranura FRENO APARC.)
	CueText: string?,
	Crashed: boolean,
	ReadySent: boolean?, -- ya se le ha dicho al servidor que este ordenador mueve el avión ("Ready")
	Ignore: { Instance },
	Params: RaycastParams,
	BoxParams: RaycastParams,
}

local active: Active? = nil
local holds: { [string]: boolean } = {}
local pending: { [string]: any }? = nil -- lo que dijo el servidor al subirte ("Pilot")
local hud: AirCombatHud.View? = nil
local remote: RemoteEvent? = nil
local savedJump: boolean? = nil

local function humanoidOf(): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function fire(...)
	if remote then
		remote:FireServer(...)
	end
end

---------------------------------------------------------------------
-- El mundo para el modelo de vuelo: suelo y choques
---------------------------------------------------------------------
local function ignoreList(model: Model): { Instance }
	local list: { Instance } = { model }
	for _, tag in { "Plane", "PilotPlane" } do
		for _, m in CollectionService:GetTagged(tag) do
			table.insert(list, m)
		end
	end
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(list, p.Character)
		end
	end
	return list
end

local function nameOf(part: Instance): string
	if part:IsA("Terrain") then
		return "el terreno"
	end
	local model = part:FindFirstAncestorOfClass("Model")
	local name = if model and model.Parent ~= workspace then model.Name else part.Name
	return name
end

local function envFor(a: Active): Flight.Env
	local spec = a.Spec
	local wingY = if a.Kind == "Avion" then 5.4 else 8.1
	local wingZ = if a.Kind == "Avion" then 4 else -2.6
	return {
		runway = function(pos: Vector3, yaw: number): number?
			return (Airport.runwayLeft(pos, yaw))
		end,
		ground = function(pos: Vector3): (number?, string?)
			local hit = workspace:Raycast(pos + Vector3.new(0, 4, 0), Vector3.new(0, -64, 0), a.Params)
			if not hit then
				return nil, nil
			end
			local surface = if hit.Material == Enum.Material.Water then "Agua" elseif Airport.paved(hit.Position.X, hit.Position.Z, 3) then "Pista" else "Suelo"
			return hit.Position.Y, surface
		end,
		hit = function(cf: CFrame, move: Vector3): string?
			local ok, result = pcall(function()
				return workspace:Blockcast(cf * CFrame.new(0, spec.BoxY, 0), spec.Box * 0.9, move, a.BoxParams)
					or workspace:Blockcast(cf * CFrame.new(0, wingY, wingZ), Vector3.new(spec.Span * 0.92, 0.6, 3), move, a.BoxParams)
			end)
			if ok and result then
				return nameOf(result.Instance)
			end
			return nil
		end,
	}
end

---------------------------------------------------------------------
-- Mandos
---------------------------------------------------------------------
local function key(code: Enum.KeyCode): number
	return if UserInputService:IsKeyDown(code) then 1 else 0
end

local function gamepad(): { [string]: number }
	local out = { X = 0, Y = 0, RT = 0, LT = 0, RB = 0, LB = 0, Brake = 0 }
	local ok, states = pcall(function()
		return UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)
	end)
	if not ok or type(states) ~= "table" then
		return out
	end
	for _, input in states do
		local code = input.KeyCode
		if code == Enum.KeyCode.Thumbstick1 then
			out.X = if math.abs(input.Position.X) > 0.15 then input.Position.X else 0
			out.Y = if math.abs(input.Position.Y) > 0.15 then input.Position.Y else 0
		elseif code == Enum.KeyCode.ButtonR2 then
			out.RT = input.Position.Z
		elseif code == Enum.KeyCode.ButtonL2 then
			out.LT = input.Position.Z
		elseif code == Enum.KeyCode.ButtonR1 and input.UserInputState == Enum.UserInputState.Begin then
			out.RB = 1
		elseif code == Enum.KeyCode.ButtonL1 and input.UserInputState == Enum.UserInputState.Begin then
			out.LB = 1
		elseif code == Enum.KeyCode.ButtonX and input.UserInputState == Enum.UserInputState.Begin then
			out.Brake = 1
		end
	end
	return out
end

local function readInput(): Flight.Input
	local typing = false
	pcall(function()
		typing = UserInputService:GetFocusedTextBox() ~= nil
	end)
	local pitch, roll, yaw, throttle = 0, 0, 0, 0
	local brake = holds.Brake == true or (active ~= nil and active.Parking == true)
	if not typing then
		local K = Enum.KeyCode
		pitch += key(K.W) - key(K.S) + key(K.Up) - key(K.Down)
		roll += key(K.D) - key(K.A) + key(K.Right) - key(K.Left)
		yaw += key(K.E) - key(K.Q)
		throttle += math.max(key(K.LeftShift), key(K.RightShift)) - math.max(key(K.LeftControl), key(K.RightControl))
		brake = brake or key(K.B) > 0
	end
	local pad = gamepad()
	-- (el stick del mando, como la palanca: hacia atrás sube el morro; la posición Y del stick va hacia
	-- arriba, la de la palanca hacia abajo)
	local pp, pr = Flight.stickInput(Vector2.new(pad.X, -pad.Y), Flying.inverted())
	pitch += pp
	roll += pr
	yaw += pad.RB - pad.LB
	throttle += pad.RT - pad.LT
	brake = brake or pad.Brake > 0
	-- Móvil: la palanca analógica (UI/FlightStick; si no se pudo crear, el joystick de andar o el de
	-- Roblox). Tirar hacia abajo sube el morro (o al revés con el ajuste); a los lados alabeo + timón
	-- automático.
	local stick: Vector2? = nil
	if FlightStick.available() then
		stick = FlightStick.read()
	elseif Joystick.active() then
		local v = Joystick.moveVector()
		stick = Vector2.new(v.X, v.Z)
	elseif HAS_TOUCH then
		local ok, v = pcall(function()
			local scripts = player:FindFirstChild("PlayerScripts")
			local module = scripts and scripts:FindFirstChild("PlayerModule")
			return if module then (require(module :: any) :: any):GetControls():GetMoveVector() else nil
		end)
		if ok and typeof(v) == "Vector3" then
			stick = Vector2.new(v.X, v.Z)
		end
	end
	if stick then
		local p, r, y = Flight.stickInput(stick, Flying.inverted())
		pitch += p
		roll += r
		yaw += y
	end
	throttle += (if holds.ThrottleUp then 1 else 0) - (if holds.ThrottleDown then 1 else 0)
	return {
		Pitch = math.clamp(pitch, -1, 1),
		Roll = math.clamp(roll, -1, 1),
		Yaw = math.clamp(yaw, -1, 1),
		Throttle = math.clamp(throttle, -1, 1),
		Brake = brake,
	}
end

local function canExit(): boolean
	local a = active
	return a ~= nil and not a.Crashed and a.Sim.OnGround and a.Sim.Speed < 3
end

local showSelf: (boolean) -> ()

local function toggle(what: string)
	local a = active
	if not a or a.Crashed then
		return
	end
	local sim = a.Sim
	if what == "Gear" then
		if a.Spec.FixedGear then
			Hud.toast("Info", "Este avión tiene el tren fijo")
			return
		end
		if sim.OnGround and sim.Gear then
			Hud.toast("Info", "En tierra el tren no se sube 🛬")
			return
		end
		sim.Gear = not sim.Gear
		sim.AutoGear = false -- (desde ahora el tren es cosa tuya)
		SoundFx.play("Clic", 0.6)
	elseif what == "Flaps" then
		sim.Flaps = (sim.Flaps + 1) % (a.Spec.Flaps + 1)
		SoundFx.play("Clic", 0.6)
	elseif what == "Camera" then
		a.Camera = if a.Camera == "Cabina" then "Persecucion" else "Cabina"
		a.CamPos = nil
		showSelf(a.Camera ~= "Cabina")
	elseif what == "Parking" then
		a.Parking = not a.Parking
		SoundFx.play("Clic", 0.6)
	elseif what == "Idle" or what == "Full" then
		sim.Throttle = if what == "Full" then 1 else 0
		SoundFx.play("Clic", 0.6)
	elseif what == "Stick" then
		Flying.setInverted(not Flying.inverted())
		Hud.toast("Info", Flying.invertLabel())
		SoundFx.play("Clic", 0.6)
	elseif what == "Exit" then
		if canExit() then
			a.ExitAt = os.clock()
			fire("Exit")
		elseif not sim.OnGround then
			Hud.toast("Info", "En el aire no se baja nadie: aterriza primero ✈️")
		else
			Hud.toast("Info", "Para bajarte, para el avión del todo (motor al mínimo y frenos)")
		end
	end
	TouchLayout.refresh()
end

-- (por el nombre de la tecla: así vale igual con las EnumItem de Roblox y con las de las pruebas en Lune,
-- que no son siempre el mismo objeto)
local TOGGLE_KEYS = {
	G = "Gear",
	F = "Flaps",
	C = "Camera",
	Space = "Exit",
	ButtonY = "Gear",
	DPadDown = "Flaps",
	ButtonR3 = "Camera",
	ButtonA = "Exit",
}

local function onToggleKey(_: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin and active then
		local what = TOGGLE_KEYS[input.KeyCode.Name]
		if what then
			toggle(what)
		end
	end
	-- Volando estas teclas son del avión (que no salten, enciendan la linterna…)
	return if active then Enum.ContextActionResult.Sink else Enum.ContextActionResult.Pass
end

---------------------------------------------------------------------
-- Cámara: persecución (detrás y un poco arriba, suave) o cabina
---------------------------------------------------------------------
-- En la cabina no se ve tu propio personaje (la cámara va en tu cabeza)
function showSelf(visible: boolean)
	local character = player.Character
	for _, d in if character then character:GetDescendants() else {} do
		if d:IsA("BasePart") or d:IsA("Decal") then
			(d :: any).LocalTransparencyModifier = if visible then 0 else 1
		end
	end
end

-- La cámara de persecución de cada avión (studs): detrás, arriba, a qué altura del avión mira, cuánto por
-- delante del morro, lo suave que sigue y lo que deja como poco sobre el suelo
Flying.ChaseCam = {
	Avioneta = { Dist = 44, Up = 15, Focus = 4, Ahead = 22, Follow = 4.5, Clear = 3 },
	Avion = { Dist = 96, Up = 30, Focus = 8, Ahead = 45, Follow = 3.5, Clear = 4 },
}

local function updateCamera(a: Active, rootCF: CFrame, dt: number)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	if a.Camera == "Cabina" then
		showSelf(false)
		local head = a.Seat.CFrame * CFrame.new(0, 3.1, -0.2)
		camera.CFrame = head * CFrame.Angles(math.rad(-6), 0, 0)
		camera.FieldOfView = 80
		return
	end
	-- Persecución (queja del dueño: la cámara iba muy baja detrás del avión): más alta y más lejos, y
	-- suave; mira un poco por delante del morro y nunca se mete en el suelo
	local cam = Flying.ChaseCam[a.Kind] or Flying.ChaseCam.Avioneta
	local sim = a.Sim
	-- Detrás según el rumbo (sin inclinarse con el alabeo) y siguiendo un poco el cabeceo
	local yawCF = CFrame.Angles(0, sim.Yaw, 0) * CFrame.Angles(sim.Pitch * 0.5, 0, 0)
	local focus = rootCF.Position + Vector3.new(0, cam.Focus, 0)
	local want = focus + yawCF:VectorToWorldSpace(Vector3.new(0, cam.Up, cam.Dist))
	-- (que no se meta en el suelo: un rayo desde el avión hasta la cámara y, debajo, el suelo)
	local ok, hit = pcall(function()
		return workspace:Raycast(focus, want - focus, a.Params)
	end)
	if ok and hit then
		want = hit.Position + (focus - want).Unit * 1.5 + Vector3.new(0, 2, 0)
	end
	-- (el suelo bajo la cámara, buscado desde DEBAJO del primer techo que tenga encima: antes el rayo
	-- salía 30 studs más arriba y, dentro del hangar del aeroclub, chocaba con el tejado y subía la
	-- cámara ENCIMA del tejado: captura del dueño, todo chapa oxidada y el avión sin verse)
	local roofY: number? = nil
	local okG, below = pcall(function()
		local top = want + Vector3.new(0, 30, 0)
		local roof = workspace:Raycast(want, Vector3.new(0, 30, 0), a.Params)
		if roof then
			roofY = roof.Position.Y
			top = Vector3.new(want.X, math.max(want.Y, roof.Position.Y - 0.5), want.Z)
		end
		return workspace:Raycast(top, Vector3.new(0, -80, 0), a.Params)
	end)
	local function clamp(p: Vector3): Vector3
		local y = p.Y
		if okG and below then
			y = math.max(y, below.Position.Y + cam.Clear)
		end
		if roofY then
			y = math.min(y, (roofY :: number) - 1) -- (y nunca por encima del techo que tiene encima)
		end
		return Vector3.new(p.X, y, p.Z)
	end
	want = clamp(want)
	local pos = a.CamPos or want
	pos = clamp(pos:Lerp(want, 1 - math.exp(-cam.Follow * dt)))
	a.CamPos = pos
	local ahead = focus + Flight.look(sim) * cam.Ahead
	camera.CFrame = CFrame.lookAt(pos, ahead)
	local speed = sim.Speed
	camera.FieldOfView = 70 + math.clamp(speed / a.Spec.Vmax, 0, 1.2) * 12
end

---------------------------------------------------------------------
-- Empezar y acabar
---------------------------------------------------------------------
local function poseOf(kind: string, rootCF: CFrame): CFrame
	local k = Airport.Kinds[kind]
	return rootCF * CFrame.new(0, -(k.FloorY - 0.3), -k.RootZ)
end

local function setJump(enabled: boolean)
	local humanoid = humanoidOf()
	if not humanoid then
		return
	end
	pcall(function()
		if not enabled and savedJump == nil then
			savedJump = humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)
		end
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, if enabled then savedJump ~= false else false)
		if enabled then
			savedJump = nil
		end
	end)
end

-- Los carteles de tu propio avión («Subir a bordo», «Pilotar») no salen mientras lo pilotas
local function hidePrompts(a: Active)
	for _, d in a.Model:GetDescendants() do
		if d:IsA("ProximityPrompt") then
			a.Prompts[d] = d.Enabled
			d.Enabled = false
			pcall(function()
				table.insert(a.Conns, d:GetPropertyChangedSignal("Enabled"):Connect(function()
					if active == a and d.Enabled then
						d.Enabled = false
					end
				end))
			end)
		end
	end
end

local function restorePrompts(a: Active)
	for _, c in a.Conns do
		c:Disconnect()
	end
	table.clear(a.Conns)
	for prompt, was in a.Prompts do
		if prompt.Parent then
			prompt.Enabled = was
		end
	end
	table.clear(a.Prompts)
end

local function stop()
	local a = active
	if not a then
		return
	end
	active = nil
	table.clear(holds)
	pcall(restorePrompts, a)
	pcall(function()
		RunService:UnbindFromRenderStep(STEP)
	end)
	ContextActionService:UnbindAction(ACTION)
	if a.Engine then
		a.Engine:Destroy()
	end
	if hud then
		AirCombatHud.setEnabled(hud, false)
		SceneGuis.setEnabled(hud.Gui, false)
	end
	TouchLayout.setFlying(false)
	pcall(FlightStick.setCue, nil)
	pcall(FlightStick.setHintText, nil)
	FlightStick.setEnabled(false)
	pcall(Hud.setShipFocus, false)
	pcall(Controls.enable, "Avion")
	pcall(FlightFocus.exit)
	pcall(TopStack.setPiloting, nil)
	setJump(true)
	showSelf(true)
	local camera = workspace.CurrentCamera
	local humanoid = humanoidOf()
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		camera.FieldOfView = 70
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end
end

local function step(dt: number)
	local a = active
	if not a then
		return
	end
	local humanoid = humanoidOf()
	if not a.Model.Parent or not a.Root.Parent or not humanoid or humanoid.SeatPart ~= a.Seat or player:GetAttribute("Piloting") == nil then
		stop()
		return
	end
	if a.ExitAt and os.clock() - a.ExitAt > 2 then
		stop() -- (el servidor no ha contestado: se deja de pilotar igual)
		return
	end
	-- Primer fotograma a los mandos: el servidor suelta el avión (lo tenía anclado para que no se
	-- hundiera en el suelo mientras tanto) y se lo da a este ordenador
	if not a.ReadySent then
		a.ReadySent = true
		fire("Ready")
	end
	local sim = a.Sim
	local inp = readInput()
	if not a.Crashed then
		local events = Flight.advance(sim, inp, dt, envFor(a))
		for _, e in events do
			if e == "Despegue" then
				Hud.toast("Success", "🛫 ¡Despegue!")
			elseif e == "Suave" or e == "Duro" then
				fire("Touchdown", { Sink = sim.Sunk or 0, Result = e })
				if e == "Duro" then
					CameraShake.shake(0.6, 0.4)
					SoundFx.play("ChoqueLeve", 0.6, nil, a.Root)
				end
			elseif e == "TrenArriba" or e == "TrenAbajo" then
				Hud.toast("Info", if e == "TrenArriba" then "Tren arriba (automático)" else "🛬 Tren abajo (automático)")
			elseif e == "Choque" then
				SoundFx.crash(10, a.Root)
				Hud.toast("Info", ("Cuidado: has tocado %s"):format(sim.Bumped or "algo"))
			elseif e == "Accidente" then
				a.Crashed = true
				CameraShake.shake(1.4, 1)
				SoundFx.play("ChoqueFuerte", 1, nil, a.Root)
				fire("Crash", { Reason = sim.Crashed or "Accidente" })
			end
		end
	end
	local rootCF = Airport.rootCFrame(a.Kind, Flight.cframe(sim))
	a.Root.CFrame = rootCF
	a.Root.AssemblyLinearVelocity = if a.Crashed then Vector3.zero else Flight.velocity(sim)
	a.Root.AssemblyAngularVelocity = Vector3.zero
	updateCamera(a, rootCF, dt)
	-- Al servidor: tren, flaps, motor y si va en el aire (5 por segundo, o al cambiar algo)
	local summary = ("%s%s%d"):format(if sim.OnGround then "T" else "A", if sim.Gear then "G" else "g", sim.Flaps)
	local now = os.clock()
	if not a.Crashed and (summary ~= a.Sent or now - a.SentAt > 0.2) then
		a.Sent, a.SentAt = summary, now
		fire("State", { Air = not sim.OnGround, Gear = sim.Gear, Flaps = sim.Flaps, Throttle = sim.Throttle, Speed = sim.Speed })
	end
	-- Motor: sube de tono con el gas
	if a.Engine then
		local base = if a.Kind == "Avion" then 0.55 else 1.15
		a.Engine.PlaybackSpeed = base * (0.75 + sim.Throttle * 0.6)
		a.Engine.Volume = 0.35 + sim.Throttle * 0.35
	end
	if hud then
		a.Brake = inp.Brake
		a.PullUp = not Flying.inverted()
		a.CanExit = canExit()
		PlaneHudClient.update(hud, a :: any, dt)
		-- (la flecha de la palanca: hacia dónde tirar para despegar)
		if FlightStick.available() then
			FlightStick.setCue(a.CueStick, a.CueText)
		end
	end
end

local function start(model: Model, seat: BasePart)
	local root = model:FindFirstChild("Root") :: BasePart?
	local kind = model:GetAttribute("Kind")
	if not root or typeof(kind) ~= "string" or not Flight.Specs[kind] then
		return
	end
	stop()
	local info = pending or {}
	pending = nil
	-- (de donde estaba aparcado: al soltarlo el servidor, puede haber caído un poco antes de llegar aquí)
	local from = if typeof(info.Start) == "CFrame" then info.Start else root.CFrame
	local sim = Flight.new(kind, poseOf(kind, from))
	if typeof(info.Health) == "number" then
		sim.Health = info.Health
	end
	local ignore = ignoreList(model)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = false
	pcall(function()
		params.RespectCanCollide = true
	end)
	local boxParams = RaycastParams.new()
	boxParams.FilterType = Enum.RaycastFilterType.Exclude
	boxParams.FilterDescendantsInstances = ignore
	boxParams.IgnoreWater = true
	pcall(function()
		boxParams.RespectCanCollide = true
	end)
	local a: Active = {
		Model = model,
		Root = root,
		Seat = seat,
		Kind = kind,
		Spec = Flight.Specs[kind],
		Sim = sim,
		Camera = "Persecucion",
		SentAt = 0,
		Sent = "",
		Crashed = false,
		Ignore = ignore,
		Params = params,
		BoxParams = boxParams,
		Prompts = {},
		Conns = {},
		Id = (function()
			local id = model:GetAttribute("PilotPlane")
			return if typeof(id) == "string" then id else model.Name
		end)(),
	}
	active = a
	pcall(hidePrompts, a)
	a.Engine = SoundFx.loop("Motor", root)
	TouchLayout.setFlying(true)
	setJump(false)
	-- Lo del HUD de Valmar que no sirve volando, fuera (el minimapa se queda); los letreros de arriba
	-- no tapan el panel de instrumentos (vuelve todo en stop)
	-- (como la nave: su HUD trae el perfil, la brújula y el radar, así que el estado, la hora y el
	-- minimapa de Valmar se apartan)
	local stick = HAS_TOUCH and FlightStick.init(player:WaitForChild("PlayerGui"))
	pcall(FlightFocus.enter, if stick then nil else { Keep = { "JoystickGui" } })
	pcall(Hud.setShipFocus, true)
	pcall(TopStack.setPiloting, "ShipHud")
	PlaneHudClient.reset()
	if stick then
		FlightStick.setHintText(if Flying.inverted() then "ARRIBA = SUBIR · LADOS = GIRAR" else "ABAJO = SUBIR · LADOS = GIRAR")
		-- La palanca analógica; el control de Roblox (su joystick y su botón de saltar) se aparta
		FlightStick.setEnabled(true)
		Controls.disable("Avion", function()
			return active ~= nil
		end)
	end
	if hud then
		AirCombatHud.setEnabled(hud, true)
		SceneGuis.setEnabled(hud.Gui, true)
	end
	ContextActionService:BindActionAtPriority(ACTION, onToggleKey, false, Enum.ContextActionPriority.High.Value + 50,
		Enum.KeyCode.G, Enum.KeyCode.F, Enum.KeyCode.C, Enum.KeyCode.Space,
		Enum.KeyCode.ButtonY, Enum.KeyCode.DPadDown, Enum.KeyCode.ButtonR3, Enum.KeyCode.ButtonA)
	RunService:BindToRenderStep(STEP, Enum.RenderPriority.Camera.Value + 2, step)
	local first = if kind == "Avion" then "✈️ Avión de línea" else "🛩️ Avioneta"
	local up = if Flying.inverted() then "arriba" else "abajo"
	Hud.toast("Info", first .. if TOUCH
		then (": MOTOR + a tope y, pasados %d km/h, tira de la palanca hacia %s para despegar."):format(a.Spec.Vr, up)
		else (": Shift motor y, pasados %d km/h, W sube el morro. A/D alas, Q/E timón, B frenos."):format(a.Spec.Vr))
end

-- ¿Estás sentado a los mandos? (el servidor dice Piloting y tu personaje está en el PilotSeat)
local pilotingSince = 0
local function watch()
	local humanoid = humanoidOf()
	local seat = humanoid and humanoid.SeatPart
	local flying = player:GetAttribute("Piloting")
	if active then
		return
	end
	-- (se espera al aviso del servidor, que trae de dónde sale; si no llega, se empieza igual)
	if not pending and os.clock() - pilotingSince < 0.6 then
		return
	end
	if flying and seat and seat.Name == "PilotSeat" then
		local model = seat:FindFirstAncestorOfClass("Model")
		if model and model:GetAttribute("PilotPlane") then
			start(model, seat)
		end
	end
end

---------------------------------------------------------------------
-- Para todos los aviones: balizas, destellos y hélices
---------------------------------------------------------------------
local lights: { [BasePart]: { Kind: string, Model: Model } } = {}
local props: { [BasePart]: { Kind: string, Model: Model } } = {}

local function collect(model: Instance)
	if not model:IsA("Model") then
		return
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			local light = d:GetAttribute("Light")
			if typeof(light) == "string" then
				lights[d] = { Kind = light, Model = model }
			end
			local prop = d:GetAttribute("Prop")
			if typeof(prop) == "string" then
				props[d] = { Kind = prop, Model = model }
			end
		end
	end
end

local function forget(model: Instance)
	for part, info in lights do
		if info.Model == model then
			lights[part] = nil
		end
	end
	for part, info in props do
		if info.Model == model then
			props[part] = nil
		end
	end
end

-- ¿Va el motor de este avión? (los de los vuelos: en vuelo; los de los jugadores: EngineOn)
local function engineOn(model: Model): boolean
	if model:GetAttribute("PilotPlane") then
		return model:GetAttribute("EngineOn") == true
	end
	local id = model:GetAttribute("PlaneId")
	local state = ReplicatedStorage:FindFirstChild("FlightState")
	local f = state and typeof(id) == "string" and state:FindFirstChild(id)
	return f ~= nil and f:GetAttribute("Phase") == "Flight"
end

local function blink()
	local t = os.clock()
	local beacon = (t % 1.2) < 0.14
	local s = t % 1.1
	local strobe = s < 0.06 or (s > 0.16 and s < 0.22)
	local running: { [Model]: boolean } = {}
	for part, info in lights do
		if not part.Parent then
			lights[part] = nil
			continue
		end
		local on = running[info.Model]
		if on == nil then
			on = engineOn(info.Model)
			running[info.Model] = on
		end
		local lit = on and (if info.Kind == "Beacon" then beacon else strobe)
		part.LocalTransparencyModifier = if lit then 0 else 1
	end
	for part, info in props do
		if not part.Parent then
			props[part] = nil
			continue
		end
		-- (los de los jugadores los pone el servidor; los de los vuelos, aquí)
		if not info.Model:GetAttribute("PilotPlane") then
			local on = running[info.Model]
			if on == nil then
				on = engineOn(info.Model)
				running[info.Model] = on
			end
			if info.Kind == "Disc" then
				part.Transparency = if on then 0.72 else 1
			else
				part.LocalTransparencyModifier = if on then 1 else 0
			end
		end
	end
end

function Flying.init()
	remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Aviation", 10) :: RemoteEvent?
	hud = PlaneHudClient.new(player:WaitForChild("PlayerGui"), TOUCH)
	do
		local view = hud :: AirCombatHud.View
		-- Las ranuras se tocan (como las de la nave): flaps, tren, cámara, palanca y bajarse
		view.OnSlot = function(id: string)
			-- (ranuras; y los atajos del ordenador: Dodge = cámara, Cloak = bajarse, Mode = la palanca)
			local what = ({ Flaps = "Flaps", Gear = "Gear", Brake = "Parking", Camera = "Camera", Stick = "Stick", Idle = "Idle", Full = "Full", Exit = "Exit", RollLeft = "Flaps", RollRight = "Gear", Dodge = "Camera", Cloak = "Exit", Mode = "Stick" })[id]
			if what then
				toggle(what)
			end
		end
	end
	FlyButtons.register(TouchLayout, {
		Flying = function()
			return active ~= nil
		end,
		Hold = function(slot: string, down: boolean)
			holds[slot] = down
		end,
		Toggle = toggle,
		Status = function()
			local a = active
			if not a then
				return { Throttle = 0, Gear = true, FixedGear = true, Flaps = 0, Brake = false, Camera = "Persecucion", CanExit = false }
			end
			return { Throttle = a.Sim.Throttle, Gear = a.Sim.Gear, FixedGear = a.Spec.FixedGear, Flaps = a.Sim.Flaps, Brake = holds.Brake == true, Camera = a.Camera, CanExit = canExit() }
		end,
	})
	if remote then
		remote.OnClientEvent:Connect(function(action, a, b)
			if action == "Pilot" then
				pending = if type(a) == "table" then a else {}
				task.defer(watch)
			elseif action == "Off" then
				stop()
			elseif action == "Reset" then
				local cur = active
				if cur and type(a) == "table" and typeof(a.CFrame) == "CFrame" then
					local fresh = Flight.new(cur.Kind, poseOf(cur.Kind, a.CFrame))
					fresh.OnGround, fresh.Speed, fresh.Throttle, fresh.Gear, fresh.Flaps = cur.Sim.OnGround, cur.Sim.Speed, cur.Sim.Throttle, cur.Sim.Gear, cur.Sim.Flaps
					cur.Sim = fresh
				end
			elseif action == "Crash" then
				CameraShake.shake(1.2, 0.8)
				stop()
			elseif action == "Menu" and type(b) == "table" then
				task.spawn(function()
					local Dialog = require(script.Parent.Parent.UI.Dialog)
					local choice = Dialog.choose(b.Title or "Aeroclub", b.Text, b.Options or {})
					fire("Choose", a, choice)
				end)
			elseif action == "Theory" and type(b) == "table" then
				task.spawn(function()
					local Dialog = require(script.Parent.Parent.UI.Dialog)
					local answers = {}
					for i, question in b.Questions or {} do
						local choice = Dialog.choose(("📝 Licencia de piloto · pregunta %d de %d"):format(i, #b.Questions), question.Text, question.Options)
						answers[i] = choice or 0
					end
					fire("Answers", a, answers)
				end)
			end
		end)
	end
	player:GetAttributeChangedSignal("Piloting"):Connect(function()
		if player:GetAttribute("Piloting") == nil then
			stop()
		else
			pilotingSince = os.clock()
			task.defer(watch)
		end
	end)
	player.CharacterAdded:Connect(function()
		stop()
	end)
	for _, tag in { "Plane", "PilotPlane" } do
		for _, model in CollectionService:GetTagged(tag) do
			collect(model)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(model)
			task.defer(collect, model)
		end)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(forget)
	end
	local clock = 0
	RunService.Heartbeat:Connect(function(dt)
		clock += dt
		if clock < 0.05 then
			return
		end
		clock = 0
		if not active and player:GetAttribute("Piloting") then
			watch()
		end
		local ok, err = pcall(blink)
		if not ok then
			warn("[Flying] " .. tostring(err))
		end
	end)
end

-- «Tirar hacia abajo para subir» (Ajustes y la ranura PALANCA). Por defecto Sí (como un avión de
-- verdad). inverted() = el ajuste en No: empujar hacia arriba sube el morro (como la nave). Vale para la
-- palanca táctil y el stick del mando; las teclas W/S no cambian. Atributo local del jugador (no se
-- guarda con la partida).
function Flying.inverted(): boolean
	return player:GetAttribute(INVERT_ATTR) == true
end

function Flying.setInverted(on: boolean)
	player:SetAttribute(INVERT_ATTR, if on then true else nil)
	if active and FlightStick.available() then
		FlightStick.setHintText(if on then "ARRIBA = SUBIR · LADOS = GIRAR" else "ABAJO = SUBIR · LADOS = GIRAR")
	end
end

function Flying.pullToClimb(): boolean
	return not Flying.inverted()
end

function Flying.invertLabel(): string
	return if Flying.inverted() then "✈️ Tirar hacia abajo para subir: No" else "✈️ Tirar hacia abajo para subir: Sí"
end

-- (pruebas)
Flying._readInput = readInput
Flying._active = function()
	return active
end
Flying._toggle = toggle

return Flying
