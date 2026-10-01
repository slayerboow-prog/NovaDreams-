-- Flying (cliente): pilotar los aviones del aeroclub (Services/AviationService) con Shared/Flight.
--
-- Cuando el servidor te sienta en el asiento del piloto ("PilotSeat" de un modelo PilotPlane; atributo
-- Piloting), tu ordenador mueve el avión cada fotograma (es dueño de sus piezas) con el modelo de vuelo:
--   * Ordenador: W/S morro (W abajo, S arriba, como la palanca) · A/D alabeo · Q/E timón (en tierra
--     gira la rueda de morro) · Shift/Ctrl motor · B frenos (mantener) · G tren · F flaps · C cámara
--     (persecución / cabina) · Espacio bajarse (parado en tierra). También las flechas para el morro y
--     el alabeo.
--   * Mando: joystick izquierdo palanca, RT/LT motor, RB/LB timón, X frenos, Y tren, ↓ flaps,
--     R3 cámara, A bajarse.
--   * Móvil: el joystick de la izquierda es la palanca; a la derecha MOTOR +/−, FRENOS, timón ◀ ▶,
--     tren, flaps, cámara y Bajarse (UI/FlyButtons en HudLayout.Fly: nada se pisa).
--   * Panel de instrumentos arriba en el centro (UI/FlightHud): velocidad, altitud, rumbo, velocidad
--     vertical, motor, tren, flaps, frenos, daños y los avisos (PÉRDIDA, límite del mapa, techo).
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
local FlyButtons = require(script.Parent.Parent.UI.FlyButtons)
local FlightHud = require(script.Parent.Parent.UI.FlightHud)

local Flying = {}

local player = Players.LocalPlayer
local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
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
	Crashed: boolean,
	Ignore: { Instance },
	Params: RaycastParams,
	BoxParams: RaycastParams,
}

local active: Active? = nil
local holds: { [string]: boolean } = {}
local pending: { [string]: any }? = nil -- lo que dijo el servidor al subirte ("Pilot")
local hud: FlightHud.View? = nil
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
	local brake = holds.Brake == true
	if not typing then
		local K = Enum.KeyCode
		pitch += key(K.S) - key(K.W) + key(K.Down) - key(K.Up)
		roll += key(K.D) - key(K.A) + key(K.Right) - key(K.Left)
		yaw += key(K.E) - key(K.Q)
		throttle += math.max(key(K.LeftShift), key(K.RightShift)) - math.max(key(K.LeftControl), key(K.RightControl))
		brake = brake or key(K.B) > 0
	end
	local pad = gamepad()
	pitch += -pad.Y
	roll += pad.X
	yaw += pad.RB - pad.LB
	throttle += pad.RT - pad.LT
	brake = brake or pad.Brake > 0
	-- El joystick de la pantalla es la palanca (abajo = morro arriba)
	if Joystick.active() then
		local v = Joystick.moveVector()
		pitch += v.Z
		roll += v.X
	end
	yaw += (if holds.RudderRight then 1 else 0) - (if holds.RudderLeft then 1 else 0)
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

local function toggle(what: string)
	local a = active
	if not a or a.Crashed then
		return
	end
	local sim = a.Sim
	if what == "Gear" then
		if a.Spec.FixedGear then
			return
		end
		if sim.OnGround and sim.Gear then
			Hud.toast("Info", "En tierra el tren no se sube 🛬")
			return
		end
		sim.Gear = not sim.Gear
		SoundFx.play("Clic", 0.6)
	elseif what == "Flaps" then
		sim.Flaps = (sim.Flaps + 1) % (a.Spec.Flaps + 1)
		SoundFx.play("Clic", 0.6)
	elseif what == "Camera" then
		a.Camera = if a.Camera == "Cabina" then "Persecucion" else "Cabina"
		a.CamPos = nil
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

local TOGGLE_KEYS = {
	[Enum.KeyCode.G] = "Gear",
	[Enum.KeyCode.F] = "Flaps",
	[Enum.KeyCode.C] = "Camera",
	[Enum.KeyCode.Space] = "Exit",
	[Enum.KeyCode.ButtonY] = "Gear",
	[Enum.KeyCode.DPadDown] = "Flaps",
	[Enum.KeyCode.ButtonR3] = "Camera",
	[Enum.KeyCode.ButtonA] = "Exit",
}

local function onToggleKey(_: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin and active then
		local what = TOGGLE_KEYS[input.KeyCode]
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
local function updateCamera(a: Active, rootCF: CFrame, dt: number)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	if a.Camera == "Cabina" then
		local head = a.Seat.CFrame * CFrame.new(0, 3.1, -0.2)
		camera.CFrame = head * CFrame.Angles(math.rad(-6), 0, 0)
		camera.FieldOfView = 80
		return
	end
	local big = a.Kind == "Avion"
	local dist = if big then 78 else 34
	local up = if big then 18 else 9
	local sim = a.Sim
	-- Detrás según el rumbo (sin inclinarse con el alabeo) y siguiendo un poco el cabeceo
	local yawCF = CFrame.Angles(0, sim.Yaw, 0) * CFrame.Angles(sim.Pitch * 0.6, 0, 0)
	local focus = rootCF.Position + Vector3.new(0, if big then 6 else 3, 0)
	local want = focus + yawCF:VectorToWorldSpace(Vector3.new(0, up, dist))
	local pos = a.CamPos or want
	pos = pos:Lerp(want, 1 - math.exp(-6 * dt))
	a.CamPos = pos
	local ahead = focus + Flight.look(sim) * (if big then 30 else 14)
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

local function stop()
	local a = active
	if not a then
		return
	end
	active = nil
	table.clear(holds)
	pcall(function()
		RunService:UnbindFromRenderStep(STEP)
	end)
	ContextActionService:UnbindAction(ACTION)
	if a.Engine then
		a.Engine:Destroy()
	end
	if hud then
		hud.Gui.Enabled = false
	end
	TouchLayout.setFlying(false)
	setJump(true)
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
		local look = Flight.heading(sim)
		FlightHud.set(hud, {
			Speed = sim.Speed,
			Altitude = math.max(0, sim.Pos.Y - Airport.GROUND) * Flight.METERS,
			Heading = look,
			Compass = Flight.compass(look),
			Climb = sim.Climb * Flight.METERS,
			Throttle = sim.Throttle,
			Gear = sim.Gear,
			FixedGear = a.Spec.FixedGear,
			Flaps = sim.Flaps,
			Brake = inp.Brake and sim.OnGround,
			Health = sim.Health,
			Warn = sim.Warn,
			OnGround = sim.OnGround,
		})
	end
end

local function start(model: Model, seat: BasePart)
	local root = model:FindFirstChild("Root") :: BasePart?
	local kind = model:GetAttribute("Kind")
	if not root or typeof(kind) ~= "string" or not Flight.Specs[kind] then
		return
	end
	stop()
	local sim = Flight.new(kind, poseOf(kind, root.CFrame))
	local info = pending or {}
	pending = nil
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
	}
	active = a
	a.Engine = SoundFx.loop("Motor", root)
	TouchLayout.setFlying(true)
	setJump(false)
	if hud then
		hud.Gui.Enabled = true
	end
	ContextActionService:BindActionAtPriority(ACTION, onToggleKey, false, Enum.ContextActionPriority.High.Value + 50,
		Enum.KeyCode.G, Enum.KeyCode.F, Enum.KeyCode.C, Enum.KeyCode.Space,
		Enum.KeyCode.ButtonY, Enum.KeyCode.DPadDown, Enum.KeyCode.ButtonR3, Enum.KeyCode.ButtonA)
	RunService:BindToRenderStep(STEP, Enum.RenderPriority.Camera.Value + 2, step)
	local first = if kind == "Avion" then "✈️ Avión de línea" else "🛩️ Avioneta"
	Hud.toast("Info", first .. if TOUCH then ": MOTOR + para rodar, el joystick es la palanca (abajo sube el morro)." else ": Shift motor, S sube el morro al pasar Vr, A/D alas, Q/E timón, B frenos.")
end

-- ¿Estás sentado a los mandos? (el servidor dice Piloting y tu personaje está en el PilotSeat)
local function watch()
	local humanoid = humanoidOf()
	local seat = humanoid and humanoid.SeatPart
	local flying = player:GetAttribute("Piloting")
	if active then
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
	hud = FlightHud.new(player:WaitForChild("PlayerGui"), TOUCH)
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

-- (pruebas)
Flying._active = function()
	return active
end
Flying._toggle = toggle

return Flying
