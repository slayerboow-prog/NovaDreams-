-- AirCombatClient (cliente): pilotar la nave del combate aéreo y espacial (Services/AirCombatService,
-- docs/combate-aereo.md).
--
-- Cuando el servidor te sienta en la nave ("Start"), tu ordenador la mueve cada fotograma con
-- shared/AirCombat/ShipFlight (predicción: sin retraso): la nave va ANCLADA y aquí se pone su CFrame
-- (nada de física ni de dueño de red); 20 veces por segundo se manda "Pose" y el servidor comprueba que
-- tenga sentido y la mueve para los demás (Services/AirCombatService).
--   * Móvil: la PALANCA propia de la nave (UI/FlightStick): pon el pulgar en cualquier sitio de la
--     mitad izquierda y arrastra (arriba sube el morro, a los lados gira; la nave se inclina y se nivela
--     sola). No depende del joystick de andar, ni del Humanoid, ni del PlayerModule (antes sí, y en el
--     móvil del dueño la nave no respondía). El motor va solo a crucero. A la derecha FUEGO (mantener;
--     ayuda a apuntar con un cono más ancho), MISIL (con un blanco fijado), TURBO y FRENO (mantener) y
--     Salir (UI/ShipButtons en HudLayout.Fly, todos ≥ 44 pt). Al volar se esconde lo que no sirve del
--     HUD de Valmar (UI/FlightFocus) y vuelve al salir.
--   * Arena: su propio cielo y su luz (cañón al atardecer; arriba, espacio con estrellas y nebulosa),
--     sin la Grieta de Valmar ni la lluvia.
--   * Si algo falla, sale en la consola (F9) con «[AirCombat] …» (y el servidor también lo apunta).
--   * Ordenador: el ratón dirige (apártalo del centro hacia donde quieras ir) · W/S motor · A/D girar ·
--     Q/E alabeo · flechas morro y giro · clic o Espacio fuego · F o clic derecho misil · Shift turbo ·
--     Ctrl freno · X salir.
--   * Mando: joystick izquierdo dirige, el derecho alabea · RT fuego · RB misil · LB turbo · LT freno ·
--     cruceta ↑/↓ motor · B salir.
--   * Fijar: mantén a un enemigo dentro del recuadro del centro (shared/AirCombat/Lock) hasta que se
--     ponga rojo (pitidos) y lanza el misil. Ayuda a apuntar: el láser se va solo un poco hacia el
--     enemigo más centrado (adelantándose a su movimiento).
--   * Panel (UI/AirCombatHud): velocidad, turbo, escudo, casco, misiles, radar, objetivo, flechas en el
--     borde hacia los enemigos que no se ven y el recuadro de fijación. Efectos: Controllers/AirCombatFx.
--   * Espacio: arriba de la arena (Arena.SpaceY) no hay gravedad y el cielo se vuelve negro con
--     estrellas (capa de DayLight + un campo de estrellas local).
--   * Estrellarse o quedarse sin casco: la nave estalla y, a los pocos segundos, reapareces en el punto
--     de control con una nave nueva.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local AC = ReplicatedStorage.Shared.AirCombat
local ShipFlight = require(AC.ShipFlight)
local ShipWeapons = require(AC.ShipWeapons)
local Lock = require(AC.Lock)
local Arena = require(AC.Arena)
local Zone = require(ReplicatedStorage.Shared.Cosmos.Zone)
local Landing = require(ReplicatedStorage.Shared.Cosmos.Landing)
local ShipModel = require(AC.ShipModel)
local Joystick = require(script.Parent.Joystick)
local SoundFx = require(script.Parent.SoundFx)
local CameraShake = require(script.Parent.CameraShake)
local AirCombatFx = require(script.Parent.AirCombatFx)
local Hud = require(script.Parent.Parent.UI.Hud)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local ShipButtons = require(script.Parent.Parent.UI.ShipButtons)
local AirCombatHud = require(script.Parent.Parent.UI.AirCombatHud)
local FlightStick = require(script.Parent.Parent.UI.FlightStick)
local FlightFocus = require(script.Parent.Parent.UI.FlightFocus)
local Controls = require(script.Parent.Controls)
local FxBudget = require(AC.FxBudget)

local AirCombatClient = {}

local player = Players.LocalPlayer
local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local HAS_TOUCH = UserInputService.TouchEnabled -- (tabletas con teclado también: la palanca sale al tocar)
local ACTION = "AirCombatKeys"
local STEP = "AirCombatStep"
local CRUISE = 0.65 -- motor del móvil (sin teclas)

type Active = {
	Ship: Model,
	Root: BasePart,
	Seat: BasePart,
	Sim: ShipFlight.State,
	Gun: ShipWeapons.Gun,
	Lock: Lock.State,
	CamPos: Vector3?,
	Engine: Sound?,
	Down: boolean,
	Mode: string,
	Server: { [string]: any },
	LastBeep: number,
	HudAt: number,
	Enemies: Instance?,
	Prev: { [string]: Vector3 },
	CrashSent: boolean,
	World: string, -- "Arena" | "Cosmos" (el espacio encima de Valmar: Controllers/SpaceClient) | "Planet"
	Planet: string?, -- (World = "Planet") id del planeta (Controllers/PlanetClient)
	Land: Landing.State?, -- (World = "Planet") aterrizar y despegar (shared/Cosmos/Landing)
	Gear: { BasePart }?, -- patas del tren de aterrizaje
	GearShown: boolean?,
	PoseAt: number, -- cuándo se mandó el último "Pose"
	SetPos: Vector3?, -- dónde se puso la nave el fotograma anterior (para ver si otro la mueve)
	Moved: number, -- fotogramas seguidos en los que alguien la ha movido
	Started: number,
	Logged: { [string]: boolean },
}

local active: Active? = nil
local holds: { [string]: boolean } = {}
local remote: RemoteEvent? = nil
local view: AirCombatHud.View? = nil
local savedJump: boolean? = nil
local stars: Model? = nil
local starsAt: Vector3? = nil

local function fire(...)
	if remote then
		remote:FireServer(...)
	end
end

-- Mensajes para la consola (F9): «[AirCombat] …». logOnce: solo la primera vez por vuelo (y, si es un
-- problema, también al servidor, que lo apunta en su consola)
local function log(text: string)
	print("[AirCombat] " .. text)
end
local function logOnce(a: any, key: string, text: string, problem: boolean?)
	if a and a.Logged and not a.Logged[key] then
		a.Logged[key] = true
		if problem then
			warn("[AirCombat] " .. text)
			fire("Diag", text)
		else
			log(text)
		end
	end
end

local function humanoidOf(): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
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

---------------------------------------------------------------------
-- El espacio: cielo oscuro (capa de DayLight) y estrellas alrededor de la cámara
---------------------------------------------------------------------
local SPACE_MOOD = {
	Brightness = 1.1,
	Exposure = -0.35,
	Ambient = Color3.fromRGB(40, 44, 62),
	Outdoor = Color3.fromRGB(70, 76, 110),
	Density = 0,
	Haze = 0,
	Cover = 0,
	CloudDensity = 0,
	Saturation = 0.08,
	Contrast = 0.22,
	Bloom = 1.2,
}

local function budget(): FxBudget.Budget
	local attr = player:GetAttribute("GraphicsTier")
	return FxBudget.get(if type(attr) == "string" then attr else nil)
end

-- La arena (abajo): un cañón del desierto a la hora dorada, con bruma cálida (no el cielo de Valmar)
local ARENA_MOOD = {
	Brightness = 2.6,
	Exposure = 0.05,
	Ambient = Color3.fromRGB(70, 56, 52),
	Outdoor = Color3.fromRGB(150, 118, 104),
	SunTint = Color3.fromRGB(90, 52, 20),
	ShadeTint = Color3.fromRGB(10, 14, 34),
	Density = 0.34,
	Offset = 0.12,
	AtmColor = Color3.fromRGB(246, 196, 150),
	Decay = Color3.fromRGB(150, 96, 84),
	Glare = 0.35,
	Haze = 1.9,
	Tint = Color3.fromRGB(255, 236, 214),
	Saturation = 0.12,
	Contrast = 0.2,
	Cover = 0.35,
	CloudDensity = 0.3,
	CloudColor = Color3.fromRGB(255, 214, 180),
	Bloom = 0.6,
}

local function buildStars(): Model
	local model = Instance.new("Model")
	model.Name = "AirStars"
	local rng = Random.new(42)
	local b = budget()
	local count = math.min(b.Stars, if TOUCH then 160 else 300)
	local root = Instance.new("Part")
	root.Name = "Centro"
	root.Anchored = true
	root.Transparency = 1
	root.CanCollide = false
	root.CanTouch = false
	root.Size = Vector3.one
	root.Parent = model
	model.PrimaryPart = root
	local tints = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 220, 255), Color3.fromRGB(255, 230, 190), Color3.fromRGB(220, 190, 255) }
	for i = 1, count do
		local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1))
		if dir.Magnitude < 0.05 then
			dir = Vector3.new(0, 1, 0)
		end
		local p = Instance.new("Part")
		p.Name = "Estrella"
		p.Shape = Enum.PartType.Ball
		p.Material = Enum.Material.Neon
		p.Color = tints[(i % #tints) + 1]
		local s = rng:NextNumber(2.5, 7)
		p.Size = Vector3.one * s
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CastShadow = false
		p.CFrame = CFrame.new(dir.Unit * 1700)
		p.Parent = model
	end
	-- Nebulosa: nubes de color enormes y muy transparentes alrededor (no en gráficos Bajo)
	local tintsNebula = { Color3.fromRGB(150, 80, 230), Color3.fromRGB(60, 170, 220), Color3.fromRGB(230, 90, 150), Color3.fromRGB(80, 110, 240), Color3.fromRGB(70, 200, 170) }
	for i = 1, b.Nebula do
		local holder = Instance.new("Part")
		holder.Name = "Nebulosa"
		holder.Shape = Enum.PartType.Ball
		holder.Size = Vector3.one * 1900
		holder.Transparency = 1
		holder.Anchored = true
		holder.CanCollide = false
		holder.CanTouch = false
		holder.CastShadow = false
		holder.CFrame = CFrame.Angles(i, i * 2.1, 0)
		holder.Parent = model
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Shape = Enum.ParticleEmitterShape.Sphere
		e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		e.LockedToPart = true
		e.Rate = 0.35
		e.Lifetime = NumberRange.new(18, 20)
		e.Speed = NumberRange.new(0, 0)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 420), NumberSequenceKeypoint.new(1, 760) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.72), NumberSequenceKeypoint.new(0.7, 0.75), NumberSequenceKeypoint.new(1, 1) })
		e.Color = ColorSequence.new(tintsNebula[(i - 1) % #tintsNebula + 1], tintsNebula[i % #tintsNebula + 1])
		e.LightEmission = 0.7
		e.LightInfluence = 0
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-3, 3)
		e.Parent = holder
	end
	return model
end

-- La arena entera (cielo, luz, Grieta, nubes): al entrar y al salir. space: ahora en el espacio.
local arenaEnvOn = false
local function setArenaEnv(on: boolean, space: boolean?)
	pcall(function()
		local DayLight = require(script.Parent.DayLight)
		if on and not space then
			DayLight.pushLayer("AirArena", ARENA_MOOD, 1.5)
		else
			DayLight.popLayer("AirArena", 1.5)
		end
		-- (en el espacio, la Vía Láctea o el de los asteroides; abajo, el cielo azul con nubes)
		DayLight.forceSky(if not on then nil elseif space then { "Night", "Asteroides", "Original" } else { "Day", "Original" })
	end)
	pcall(function()
		require(script.Parent.SkyRift).setSuppressed(on)
	end)
	if on and not arenaEnvOn then
		-- Nubes de la arena: solo si el nivel gráfico las aguanta
		local arena = workspace:FindFirstChild("AirArena")
		if arena then
			local clouds = budget().Clouds
			for _, d in arena:GetDescendants() do
				if d:IsA("ParticleEmitter") and d.Name == "Nube" then
					d.Enabled = clouds
				end
			end
		end
	end
	arenaEnvOn = on
end

local currentWorld = "Arena"

local function setSpace(on: boolean)
	if on and currentWorld == "Cosmos" then
		return -- (encima de Valmar, el cielo y las estrellas los pone Controllers/SpaceClient según la altura)
	end
	pcall(function()
		local DayLight = require(script.Parent.DayLight)
		if on then
			DayLight.pushLayer("AirSpace", SPACE_MOOD, 1.5)
		else
			DayLight.popLayer("AirSpace", 1.5)
		end
	end)
	if currentWorld == "Arena" and arenaEnvOn then
		setArenaEnv(true, on)
	end
	if on then
		if not stars then
			stars = buildStars()
		end
		;(stars :: Model).Parent = workspace.CurrentCamera
		starsAt = nil
	elseif stars then
		stars.Parent = nil
	end
end

local function moveStars(at: Vector3)
	local s = stars
	if not s or not s.Parent then
		return
	end
	if starsAt and (starsAt - at).Magnitude < 60 then
		return
	end
	starsAt = at
	s:PivotTo(CFrame.new(at))
end

---------------------------------------------------------------------
-- Blancos (los enemigos de tu oleada)
---------------------------------------------------------------------
local function targets(a: Active, dt: number): ({ Lock.Target }, { [string]: Model })
	local list, models = {}, {}
	local folder = a.Enemies
	if not folder or not folder.Parent then
		folder = workspace:FindFirstChild("AirEnemies_" .. player.UserId)
		a.Enemies = folder
	end
	if not folder then
		return list, models
	end
	local seen = {}
	for _, m in folder:GetChildren() do
		local id = m:GetAttribute("AirEnemy")
		local root = m:IsA("Model") and m.PrimaryPart
		if type(id) == "string" and root then
			local pos = root.Position
			local prev = a.Prev[id]
			local vel = if prev and dt > 0 then (pos - prev) / dt else Vector3.zero
			a.Prev[id] = pos
			seen[id] = true
			local kind = m:GetAttribute("Kind")
			table.insert(list, { Id = id, Pos = pos, Vel = vel, Kind = if type(kind) == "string" then kind else nil })
			models[id] = m :: Model
		end
	end
	for id in a.Prev do
		if not seen[id] then
			a.Prev[id] = nil
		end
	end
	return list, models
end

---------------------------------------------------------------------
-- Mandos
---------------------------------------------------------------------
local function key(code: Enum.KeyCode): number
	return if UserInputService:IsKeyDown(code) then 1 else 0
end

local function gamepad(): { [string]: number }
	local out = { X = 0, Y = 0, RX = 0, RT = 0, LT = 0, Up = 0, Down = 0 }
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
		elseif code == Enum.KeyCode.Thumbstick2 then
			out.RX = if math.abs(input.Position.X) > 0.2 then input.Position.X else 0
		elseif code == Enum.KeyCode.ButtonR2 then
			out.RT = input.Position.Z
		elseif code == Enum.KeyCode.ButtonL2 then
			out.LT = input.Position.Z
		elseif code == Enum.KeyCode.DPadUp and input.UserInputState == Enum.UserInputState.Begin then
			out.Up = 1
		elseif code == Enum.KeyCode.DPadDown and input.UserInputState == Enum.UserInputState.Begin then
			out.Down = 1
		end
	end
	return out
end

-- Del ratón: lo apartado del centro de la pantalla (-1..1), con zona muerta
local function mouseSteer(): (number, number)
	if TOUCH or not UserInputService.MouseEnabled then
		return 0, 0
	end
	-- (tableta con teclado: si lo último fue un toque o el mando, el ratón no dirige)
	local last = UserInputService:GetLastInputType()
	if last == Enum.UserInputType.Touch or string.find(last.Name, "Gamepad") then
		return 0, 0
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return 0, 0
	end
	local vp = camera.ViewportSize
	local m = UserInputService:GetMouseLocation()
	local half = math.min(vp.X, vp.Y) * 0.35
	local dx = (m.X - vp.X / 2) / half
	local dy = (m.Y - vp.Y * 0.45) / half
	local function dead(v: number): number
		local a = math.abs(v)
		if a < 0.08 then
			return 0
		end
		return math.sign(v) * math.min(1, (a - 0.08) / 0.92)
	end
	return dead(dx), dead(dy)
end

local function readInput(): ShipFlight.Input
	local typing = false
	pcall(function()
		typing = UserInputService:GetFocusedTextBox() ~= nil
	end)
	local pitch, yaw, roll, throttle = 0, 0, 0, 0
	local boost, brake = holds.Boost == true, holds.Brake == true
	local K = Enum.KeyCode
	if not typing and not TOUCH then
		local mx, my = mouseSteer()
		yaw += mx
		pitch -= my
		pitch += key(K.Up) - key(K.Down)
		yaw += key(K.D) - key(K.A) + key(K.Right) - key(K.Left)
		roll += key(K.E) - key(K.Q)
		throttle += key(K.W) - key(K.S)
		boost = boost or key(K.LeftShift) > 0 or key(K.RightShift) > 0
		brake = brake or key(K.LeftControl) > 0 or key(K.RightControl) > 0
	end
	local pad = gamepad()
	pitch += pad.Y
	yaw += pad.X
	roll += pad.RX
	throttle += pad.Up - pad.Down
	brake = brake or pad.LT > 0.4
	if FlightStick.available() then
		-- La palanca de la nave (UI/FlightStick): arriba sube el morro
		local p, y = FlightStick.toInput(FlightStick.read())
		pitch += p
		yaw += y
	elseif Joystick.active() then
		local v = Joystick.moveVector()
		pitch -= v.Z
		yaw += v.X
	elseif HAS_TOUCH then
		-- (último recurso: el joystick de Roblox, leído del PlayerModule)
		local ok, v = pcall(function()
			-- (sin esperar: esto va en cada fotograma)
			local scripts = player:FindFirstChild("PlayerScripts")
			local module = scripts and scripts:FindFirstChild("PlayerModule")
			return if module then (require(module :: any) :: any):GetControls():GetMoveVector() else nil
		end)
		if ok and typeof(v) == "Vector3" then
			pitch -= v.Z
			yaw += v.X
		end
	end
	return {
		Pitch = math.clamp(pitch, -1, 1),
		Yaw = math.clamp(yaw, -1, 1),
		Roll = math.clamp(roll, -1, 1),
		Throttle = math.clamp(throttle, -1, 1),
		SetThrottle = if TOUCH and throttle == 0 then CRUISE else nil,
		Boost = boost,
		Brake = brake,
	}
end

local function firing(): boolean
	if holds.Fire then
		return true
	end
	if TOUCH then
		return false
	end
	local typing = false
	pcall(function()
		typing = UserInputService:GetFocusedTextBox() ~= nil
	end)
	if typing then
		return false
	end
	if key(Enum.KeyCode.Space) > 0 or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
		return true
	end
	return gamepad().RT > 0.4
end

---------------------------------------------------------------------
-- Disparar
---------------------------------------------------------------------
local function shoot(a: Active, list: { Lock.Target })
	local now = os.clock()
	if a.Down or not ShipWeapons.tryLaser(a.Gun, now) then
		return
	end
	local cf = a.Root.CFrame
	local L = ShipWeapons.Laser
	local cone = if TOUCH then Lock.Config.AssistConeTouch else Lock.Config.AssistCone
	local dir = Lock.assist(cf.Position, cf.LookVector, list, cone, L.Speed)
	fire("Fire", dir)
	for _, side in { -1, 1 } do
		local origin = (cf * CFrame.new(side * L.Muzzle, -0.6, -7)).Position
		AirCombatFx.tracer(origin, dir, L.Speed + a.Sim.Speed, L.Life, false)
		AirCombatFx.muzzle(origin, dir, false)
	end
	SoundFx.play("NaveLaser", 1, nil, a.Root)
end

local function launch(a: Active)
	if a.Down then
		return
	end
	local missiles = a.Server.Missiles or a.Gun.Missiles
	if missiles <= 0 then
		Hud.toast("Info", "Sin misiles: se recargan solos")
		SoundFx.play("ArmaSeco", 0.8)
		return
	end
	if not (a.Lock.Locked and a.Lock.Target) then
		Hud.toast("Info", "🎯 Fija un enemigo primero: mantenlo en el recuadro del centro")
		SoundFx.play("ArmaSeco", 0.8)
		return
	end
	if ShipWeapons.tryMissile(a.Gun, os.clock()) then
		fire("Missile", a.Lock.Target)
		SoundFx.play("NaveMisil", 1, nil, a.Root)
		CameraShake.shake(0.15, 0.15)
	end
end

local function press(what: string)
	local a = active
	if not a then
		return
	end
	if what == "Missile" then
		launch(a)
	elseif what == "Exit" then
		fire("Exit")
	end
end

local function onKey(_: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	if not active then
		return Enum.ContextActionResult.Pass
	end
	if state == Enum.UserInputState.Begin then
		local code = input.KeyCode
		if code == Enum.KeyCode.F or code == Enum.KeyCode.ButtonR1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
			press("Missile")
		elseif code == Enum.KeyCode.X or code == Enum.KeyCode.ButtonB then
			press("Exit")
		elseif code == Enum.KeyCode.ButtonL1 then
			holds.Boost = true
		end
	elseif state == Enum.UserInputState.End and input.KeyCode == Enum.KeyCode.ButtonL1 then
		holds.Boost = false
	end
	-- Pilotando, estas teclas son de la nave (que no salten, se levanten ni enciendan nada)
	return Enum.ContextActionResult.Sink
end

---------------------------------------------------------------------
-- Cámara de persecución
---------------------------------------------------------------------
local function updateCamera(a: Active, dt: number)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local cf = a.Root.CFrame
	local look = cf.LookVector
	local up = if a.Mode == "Space" then cf.UpVector else (cf.UpVector * 0.35 + Vector3.new(0, 1, 0) * 0.65).Unit
	local want = cf.Position - look * 30 + up * 9
	local pos = a.CamPos or want
	pos = pos:Lerp(want, 1 - math.exp(-9 * dt))
	a.CamPos = pos
	local target = cf.Position + look * 60 + up * 3
	camera.CFrame = CFrame.lookAt(pos, target, up)
	local speedK = math.clamp((a.Sim.Speed - a.Sim.Spec.MinSpeed) / (a.Sim.Spec.BoostSpeed - a.Sim.Spec.MinSpeed), 0, 1)
	camera.FieldOfView = 70 + speedK * 16
	moveStars(camera.CFrame.Position)
end

---------------------------------------------------------------------
-- HUD de cada fotograma (mira, fijación, flechas, radar)
---------------------------------------------------------------------
local function overlay(a: Active, list: { Lock.Target })
	local v = view
	local camera = workspace.CurrentCamera
	if not v or not camera then
		return
	end
	local vp = camera.ViewportSize
	local cf = a.Root.CFrame
	-- La mira: donde apunta el morro (a 400 studs)
	local aim, onAim = camera:WorldToViewportPoint(cf.Position + cf.LookVector * 400)
	v.Cross.Visible = onAim and not a.Down
	v.Cross.Position = UDim2.fromOffset(aim.X, aim.Y)
	v.HitMark.Position = v.Cross.Position
	-- Recuadro de fijación
	local lock = a.Lock
	local lockedPos: Vector3? = nil
	for _, t in list do
		if t.Id == lock.Target then
			lockedPos = t.Pos
		end
	end
	if lockedPos and not a.Down then
		local p, on = camera:WorldToViewportPoint(lockedPos)
		v.LockBox.Visible = on
		v.LockBox.Position = UDim2.fromOffset(p.X, p.Y)
		local s = 100 - 46 * lock.Progress
		v.LockBox.Size = UDim2.fromOffset(s, s)
		local red = Color3.fromRGB(255, 60, 60)
		local amber = Color3.fromRGB(255, 200, 60)
		v.LockStroke.Color = if lock.Locked then red else amber
		local tag = v.LockBox:FindFirstChild("Tag") :: TextLabel?
		if tag then
			tag.Text = if lock.Locked then "FIJADO · MISIL" else "FIJANDO"
			tag.TextColor3 = if lock.Locked then red else amber
		end
	else
		v.LockBox.Visible = false
	end
	-- Flechas del borde y radar
	local blips: { AirCombatHud.Blip } = {}
	local arrow = 0
	for _, t in list do
		local p, on = camera:WorldToViewportPoint(t.Pos)
		local screen = Vector2.new(p.X, p.Y)
		local behind = p.Z < 0
		if not (on and AirCombatHud.onScreen(screen, vp, behind)) and arrow < #v.Arrows then
			arrow += 1
			local pos, angle = AirCombatHud.edgeArrow(screen, vp, behind)
			local label = v.Arrows[arrow]
			label.Visible = true
			label.Position = UDim2.fromOffset(pos.X, pos.Y)
			label.Rotation = angle
		end
		if #blips < #v.Blips then
			table.insert(blips, { Point = AirCombatHud.radarPoint(cf, t.Pos), Locked = t.Id == lock.Target and lock.Locked, Kind = t.Kind })
		end
	end
	for i = arrow + 1, #v.Arrows do
		v.Arrows[i].Visible = false
	end
	AirCombatHud.blips(v, blips)
end

local function panel(a: Active)
	local v = view
	if not v then
		return
	end
	local s = a.Server
	local sim = a.Sim
	AirCombatHud.set(v, {
		Speed = ShipFlight.kmh(sim),
		Boost = sim.Boost,
		BoostReady = sim.Time >= sim.CoolUntil,
		Shield = s.Shield or 60,
		MaxShield = s.MaxShield or 60,
		Hull = s.Hull or 100,
		MaxHull = s.MaxHull or 100,
		Missiles = s.Missiles or a.Gun.Missiles,
		MaxMissiles = s.MaxMissiles or ShipWeapons.Missile.Ammo,
		Overheated = s.Overheated == true or a.Gun.Overheated,
		Wave = s.Wave or 0,
		Score = s.Score or 0,
		Objective = if a.Down then "💥 Derribado · reapareces en el punto de control…" else s.Objective or "Prepárate",
		Warn = sim.Warn,
		Mode = a.Mode,
	})
end

---------------------------------------------------------------------
-- Cada fotograma
---------------------------------------------------------------------
local ENVS: { [string]: ShipFlight.Env } = {
	Arena = { mode = Arena.modeAt, collide = Arena.collide, bounds = Arena.bounds },
	-- (el cielo y el espacio encima de Valmar: shared/Cosmos/Zone, Controllers/SpaceClient)
	Cosmos = { mode = Zone.modeAt, collide = Zone.collide, bounds = Zone.bounds },
}

-- Geometría de cada mundo puesta desde fuera (Controllers/PlanetClient: los planetas en el espacio y
-- la superficie de un planeta) y quién se entera cuando el servidor mueve la nave ("Relocate")
local customEnv: { [string]: ShipFlight.Env } = {}
local planetGround: ((string?) -> Landing.Ground?)? = nil
local relocateListeners: { (string, string?) -> () } = {}

function AirCombatClient.setEnv(world: string, env: ShipFlight.Env?)
	customEnv[world] = env
end
function AirCombatClient.setGround(fn: ((string?) -> Landing.Ground?)?)
	planetGround = fn
end
function AirCombatClient.onRelocate(fn: (string, string?) -> ())
	table.insert(relocateListeners, fn)
end

local function envFor(world: string): ShipFlight.Env
	return customEnv[world] or ENVS[world] or ENVS.Arena
end

local function setGear(a: Active, shown: boolean)
	if a.GearShown == shown then
		return
	end
	a.GearShown = shown
	if not a.Gear then
		local list = {}
		for _, d in a.Ship:GetChildren() do
			if d:IsA("BasePart") and (d.Name == ShipModel.Gear or d.Name == ShipModel.GearPad) then
				table.insert(list, d)
			end
		end
		a.Gear = list
	end
	for _, p in a.Gear :: { BasePart } do
		p.Transparency = if shown then 0 else 1
	end
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
	if view then
		AirCombatHud.setEnabled(view, false)
	end
	AirCombatFx.clear()
	AirCombatFx.forgetShip(a.Ship)
	setSpace(false)
	setArenaEnv(false)
	FlightStick.setEnabled(false)
	pcall(FlightFocus.exit)
	pcall(Controls.enable, "NaveAerea")
	TouchLayout.setFlying(false)
	setJump(true)
	log(("fin del vuelo (%.0f s, palanca táctil usada %d veces)"):format(os.clock() - a.Started, FlightStick._state().Touches))
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
	if not a.Ship.Parent or not a.Root.Parent or not humanoid or player:GetAttribute("AirCombat") == nil then
		stop()
		return
	end
	local list = targets(a, dt)
	local sim = a.Sim
	if not a.Down then
		local input = readInput()
		local handled = false
		if a.World == "Planet" and a.Land then
			-- Aterrizar y despegar (shared/Cosmos/Landing): cerca del suelo y despacio, se posa sola
			local ground = planetGround and planetGround(a.Planet)
			if ground then
				local ev
				handled, ev = Landing.step(a.Land, sim, input, dt, ground)
				if ev == "Touchdown" then
					SoundFx.play("NaveImpacto", 0.4)
					CameraShake.shake(0.25, 0.25)
					Hud.toast("Success", if TOUCH then "🛬 Posada. BAJAR para salir · palanca ARRIBA para despegar" else "🛬 Posada. X para bajar · W o ratón arriba para despegar")
				elseif ev == "TakeOff" then
					SoundFx.play("NaveMisil", 0.5, nil, a.Root)
				end
				setGear(a, a.Land.Gear or a.Land.Phase ~= "Flying")
			end
		elseif a.GearShown then
			setGear(a, false)
		end
		local events = if handled then {} else ShipFlight.advance(sim, input, dt, envFor(a.World))
		for _, e in events do
			if e == "Crash" and not a.CrashSent then
				a.CrashSent = true
				fire("Crash", sim.Crashed)
			elseif e == "Space" or e == "Atmos" then
				a.Mode = e
				setSpace(e == "Space")
				if a.World == "Cosmos" then
					Hud.toast("Info", if e == "Space" then "🌌 Sales de la atmósfera: ya no hay gravedad. Arriba, el espacio." else "⛰ Vuelves a la atmósfera de Valmar: hay gravedad")
				else
					Hud.toast("Info", if e == "Space" then "🌌 Espacio: sin gravedad. ¡Cuidado con los asteroides!" else "⛰ De vuelta a la atmósfera: hay gravedad")
				end
			elseif e == "BoostEmpty" then
				SoundFx.play("ArmaSeco", 0.6)
			end
		end
		-- (¿la ha movido otro desde el fotograma anterior? física, el servidor… se avisa una vez)
		local was = a.SetPos
		if was and (a.Root.Position - was).Magnitude > 3 then
			a.Moved += 1
			if a.Moved == 30 then
				logOnce(a, "moved", ("algo mueve la nave por su cuenta (anclada: %s); se vuelve a poner cada fotograma"):format(tostring(a.Root.Anchored)), true)
			end
		else
			a.Moved = 0
		end
		local cf = ShipFlight.cframe(sim)
		a.Root.CFrame = cf
		a.SetPos = cf.Position
		-- Al servidor, 20 veces por segundo
		local t = os.clock()
		if t - a.PoseAt >= 0.05 then
			a.PoseAt = t
			fire("Pose", cf)
		end
	else
		-- Derribado: la nave (escondida) se queda donde estalló; la cámara mira la explosión
		a.Root.CFrame = ShipFlight.cframe(sim)
		a.SetPos = a.Root.Position
	end
	AirCombatFx.shipStep(a.Ship, sim.Throttle, sim.Boosting, a.Down, dt)
	ShipWeapons.tick(a.Gun, os.clock(), dt)
	-- Fijación (con pitidos) y disparo
	local cf = a.Root.CFrame
	local ev = if a.Down then nil else Lock.update(a.Lock, cf.Position, cf.LookVector, list, dt)
	local now = os.clock()
	if ev == "Locked" then
		SoundFx.play("NaveFijado", 1)
	elseif a.Lock.Target and not a.Lock.Locked and now - a.LastBeep > 0.3 - a.Lock.Progress * 0.15 then
		a.LastBeep = now
		SoundFx.play("NaveFijando", 1)
	end
	if firing() then
		shoot(a, list)
	end
	-- Motor
	if a.Engine then
		a.Engine.PlaybackSpeed = 1.6 + sim.Throttle * 0.5 + (if sim.Boosting then 0.45 else 0)
		a.Engine.Volume = if a.Down then 0 else 0.25 + sim.Throttle * 0.2 + (if sim.Boosting then 0.15 else 0)
	end
	updateCamera(a, dt)
	AirCombatFx.step(dt)
	overlay(a, list)
	if now - a.HudAt > 0.05 then
		a.HudAt = now
		panel(a)
	end
end

local function start(payload: { [string]: any })
	stop()
	local name = payload.Ship
	if type(name) ~= "string" then
		return
	end
	local ship = workspace:WaitForChild(name, 10) :: Model?
	if not ship then
		return
	end
	local root = ship:WaitForChild("Root", 5) :: BasePart?
	local seat = ship:WaitForChild("ShipSeat", 5) :: BasePart?
	if not root or not seat then
		return
	end
	-- (espera a estar sentado de verdad)
	local t0 = os.clock()
	local seated = false
	while os.clock() - t0 < 5 do
		local h = humanoidOf()
		if h and h.SeatPart == seat then
			seated = true
			break
		end
		task.wait(0.05)
	end
	local section = if payload.Section == "Space" then "Space" else "Atmos"
	local cp = if typeof(payload.Checkpoint) == "CFrame" then payload.Checkpoint else root.CFrame
	local worldName = if payload.World == "Cosmos" or payload.World == "Planet" then payload.World else "Arena"
	local a: Active = {
		Ship = ship,
		Root = root,
		Seat = seat,
		Sim = ShipFlight.new("Caza", cp, section),
		Gun = ShipWeapons.newGun(),
		Lock = Lock.new(),
		Down = false,
		Mode = section,
		Server = {},
		LastBeep = 0,
		HudAt = 0,
		Enemies = nil,
		Prev = {},
		CrashSent = false,
		World = worldName,
		Planet = if worldName == "Planet" and type(payload.Planet) == "string" then payload.Planet else nil,
		Land = if worldName == "Planet" then Landing.new(payload.Landed == true) else nil,
		PoseAt = 0,
		SetPos = nil,
		Moved = 0,
		Started = os.clock(),
		Logged = {},
	}
	active = a
	currentWorld = a.World
	a.Engine = SoundFx.loop("NaveMotor", root)
	TouchLayout.setFlying(true)
	TouchLayout.refresh()
	setJump(false)
	-- Lo del HUD de Valmar que no sirve volando, fuera (vuelve en stop)
	pcall(FlightFocus.enter)
	-- Mandos: la palanca táctil propia; el control de Roblox (su joystick y su botón de saltar) se aparta
	local stick = HAS_TOUCH and FlightStick.init(player:WaitForChild("PlayerGui"), function()
		log("palanca táctil: primer toque recibido")
	end)
	if stick then
		FlightStick.setEnabled(true)
		Controls.disable("NaveAerea", function()
			return active ~= nil
		end)
	end
	if a.World == "Arena" then
		setArenaEnv(true, section == "Space")
	end
	setSpace(section == "Space")
	local devMode = "?"
	pcall(function()
		devMode = player.DevTouchMovementMode.Name
	end)
	log(("vuelo: %s, mundo %s, sentado %s, nave anclada %s, mandos %s (DevTouchMovementMode %s, joystick de andar %s)"):format(
		ship.Name,
		a.World,
		tostring(seated),
		tostring(root.Anchored),
		if stick then "palanca táctil" elseif HAS_TOUCH then "joystick" else "teclado/ratón/mando",
		devMode,
		tostring(Joystick.active())
	))
	if not seated then
		logOnce(a, "seat", "no estás sentado en la nave tras 5 s (el servidor vuelve a sentarte)", true)
	end
	if HAS_TOUCH and not stick then
		logOnce(a, "stick", "sin palanca táctil: se usa el joystick de andar o el de Roblox", true)
	end
	if view then
		AirCombatHud.setEnabled(view, true)
	end
	ContextActionService:BindActionAtPriority(ACTION, onKey, false, Enum.ContextActionPriority.High.Value + 60,
		Enum.KeyCode.F, Enum.KeyCode.X, Enum.KeyCode.Space, Enum.KeyCode.LeftShift, Enum.KeyCode.LeftControl, Enum.KeyCode.Q, Enum.KeyCode.E,
		Enum.KeyCode.C, Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonB, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY, Enum.KeyCode.ButtonR1, Enum.KeyCode.ButtonL1,
		Enum.UserInputType.MouseButton2)
	RunService:BindToRenderStep(STEP, Enum.RenderPriority.Camera.Value + 2, step)
	if a.World == "Planet" then
		if a.Land and a.Land.Phase == "Landed" then
			setGear(a, true)
		end
		Hud.toast("Info", if TOUCH
			then "🚀 Palanca ARRIBA para despegar · FRENO cerca del suelo para posarte · sube del todo para ir al espacio"
			else "🚀 W o ratón arriba: despegar · Ctrl frena (se posa sola cerca del suelo) · X bajar · V Valmar")
		return
	end
	if a.World == "Cosmos" then
		Hud.toast("Info", if TOUCH
			then "🚀 Joystick: dirige · FUEGO láser (también mina asteroides) · TURBO · VALMAR vuelve a casa"
			else "🚀 Ratón: dirige · W/S motor · clic fuego (mina asteroides) · Shift turbo · V Valmar · G atracar/viajar · X aterrizar")
		return
	end
	Hud.toast("Info", if TOUCH
		then "🚀 Joystick: dirige · FUEGO láser · fija un enemigo en el recuadro y MISIL · TURBO y FRENO"
		else "🚀 Ratón: dirige · W/S motor · clic fuego · F misil (fija primero) · Shift turbo · Ctrl freno · X salir")
end

local function onEvent(kind: string, p: any)
	local a = active
	if kind == "Start" and type(p) == "table" then
		task.spawn(start, p)
		return
	elseif kind == "End" then
		stop()
		if type(p) == "table" and p.Reason == "exit" and p.World ~= "Cosmos" then
			Hud.toast("Info", ("🏁 Fuera de la arena · oleada %d · %d derribos · %d puntos"):format(p.Wave or 0, p.Kills or 0, p.Score or 0))
		end
		return
	end
	if type(p) ~= "table" then
		return
	end
	if kind == "Bolt" then
		if typeof(p.Pos) == "Vector3" and typeof(p.Dir) == "Vector3" then
			if p.Enemy then
				AirCombatFx.tracer(p.Pos, p.Dir, p.Speed or 500, p.Life or 1.5, true)
				AirCombatFx.muzzle(p.Pos, p.Dir, true)
				SoundFx.play("NaveLaserEnemigo", 1, nil, p.Pos)
			else
				-- (otro piloto: sus dos cañones)
				AirCombatFx.tracer(p.Pos, p.Dir, p.Speed or 900, p.Life or 1, false)
			end
		end
	elseif kind == "Missile" then
		if typeof(p.Pos) == "Vector3" and typeof(p.Dir) == "Vector3" and type(p.Id) == "string" then
			local id = p.Target
			AirCombatFx.missile(p.Id, p.Pos, p.Dir, function(): Vector3?
				local folder = workspace:FindFirstChild("AirEnemies_" .. player.UserId)
				if folder then
					for _, m in folder:GetChildren() do
						if m:GetAttribute("AirEnemy") == id and m:IsA("Model") and m.PrimaryPart then
							return m.PrimaryPart.Position
						end
					end
				end
				return nil
			end)
		end
	elseif kind == "Boom" then
		if typeof(p.Pos) == "Vector3" then
			AirCombatFx.boom(tostring(p.Id), p.Pos, p.Hit == true)
		end
	elseif kind == "Burst" then
		if typeof(p.Pos) == "Vector3" then
			local size = if p.Kind == "Dron" then 0.45 elseif p.Kind == "Torreta" then 0.7 else 0.85
			AirCombatFx.burst(p.Pos, size, if typeof(p.Look) == "Vector3" then p.Look else nil)
			SoundFx.play("NaveEstallido", 1, nil, p.Pos)
			if p.Wreck then
				local vel = if typeof(p.Look) == "Vector3" and type(p.Speed) == "number" then p.Look * p.Speed else nil
				AirCombatFx.wreck(p.Pos, vel, size)
			end
			if a and (a.Root.Position - p.Pos).Magnitude < 160 then
				CameraShake.shake(0.35, 0.3)
			end
		end
	elseif kind == "HitMark" then
		local v = view
		if v then
			local mark = v.HitMark
			mark.TextColor3 = if p.Kill then Color3.fromRGB(255, 90, 70) elseif p.Shield then Color3.fromRGB(120, 220, 255) else Color3.new(1, 1, 1)
			mark.TextSize = if p.Kill then 56 else 40
			mark.TextTransparency = 0
			mark.TextStrokeTransparency = 0.3
			task.delay(if p.Kill then 0.35 else 0.12, function()
				mark.TextTransparency = 1
				mark.TextStrokeTransparency = 1
			end)
		end
		if typeof(p.Pos) == "Vector3" and not p.Kill then
			AirCombatFx.hit(p.Pos, nil, if p.Shield then Color3.fromRGB(120, 220, 255) else nil, p.Kind == "Missile")
		end
		SoundFx.play("NaveImpacto", if p.Kill then 1 else 0.7)
		if p.Kill then
			CameraShake.shake(0.2, 0.15)
		end
	elseif kind == "Hit" then
		if a then
			local hull = (p.Hull or 0) > 0
			local from = if typeof(p.From) == "Vector3" then p.From else nil
			if (p.Shield or 0) > 0 then
				AirCombatFx.shield(a.Root, from, p.Broke == true)
				SoundFx.play("NaveEscudo", 1)
			end
			if hull then
				AirCombatFx.hit(a.Root.Position + (if from then (from - a.Root.Position).Unit * 4 else Vector3.zero), nil, Color3.fromRGB(255, 160, 60))
				SoundFx.play("NaveCasco", 1)
			end
			CameraShake.shake(if hull then 0.45 else 0.2, if hull then 0.3 else 0.15)
			local v = view
			if v then
				local edge = v.Flash:FindFirstChild("Edge") :: UIStroke?
				if edge then
					edge.Color = if hull then Color3.fromRGB(255, 60, 50) else Color3.fromRGB(80, 200, 255)
					edge.Transparency = 0.25
					task.delay(0.12, function()
						edge.Transparency = 1
					end)
				end
			end
		end
	elseif kind == "State" then
		if a then
			a.Server = p
			if typeof(p.Missiles) == "number" then
				a.Gun.Missiles = p.Missiles
			end
		end
	elseif kind == "Down" then
		if a then
			a.Down = true
			local at = if typeof(p.Pos) == "Vector3" then p.Pos else a.Root.Position
			AirCombatFx.burst(at, 1, a.Root.CFrame.LookVector)
			SoundFx.play("NaveEstallido", 1, nil, at)
			CameraShake.shake(1.2, 0.8)
			AirCombatFx.wreck(at, a.Root.CFrame.LookVector * a.Sim.Speed, 1)
			Hud.toast("Info", ("💥 %s. Reapareces en el punto de control."):format(tostring(p.Reason or "Te han derribado")))
		end
	elseif kind == "Relocate" then
		-- El servidor ha pasado la nave del espacio a un planeta o al revés: MISMA velocidad, motor y
		-- turbo; solo cambian el sitio, el rumbo (ya calculado) y la geometría. Las nubes lo tapan.
		if a and typeof(p.CFrame) == "CFrame" then
			local world = if p.World == "Planet" then "Planet" else "Cosmos"
			a.World = world
			currentWorld = world
			a.Planet = if world == "Planet" and type(p.Planet) == "string" then p.Planet else nil
			a.Land = if world == "Planet" then Landing.new(false) else nil
			if world ~= "Planet" then
				setGear(a, false)
			end
			local sim = a.Sim
			sim.Pos = p.CFrame.Position
			sim.Rot = p.CFrame - p.CFrame.Position
			sim.Sink = 0
			sim.Crashed = nil
			a.SetPos = nil
			a.CamPos = nil
			a.Root.CFrame = p.CFrame
			local mode = envFor(world).mode
			local m = if mode then mode(sim.Pos) else "Atmos"
			sim.Mode = m
			if m ~= a.Mode then
				a.Mode = m
				setSpace(m == "Space")
			end
			for _, fn in relocateListeners do
				task.spawn(fn, world, a.Planet)
			end
		end
	elseif kind == "Respawn" or kind == "Reset" then
		if a and typeof(p.CFrame) == "CFrame" then
			a.SetPos = nil
			if kind == "Reset" then
				log("el servidor ha devuelto la nave al último sitio bueno (salto imposible o fuera de la arena)")
			end
			local modeFn = envFor(a.World).mode
			local fresh = ShipFlight.new("Caza", p.CFrame, if modeFn then modeFn(p.CFrame.Position) else "Atmos")
			if kind == "Reset" then
				fresh.Speed, fresh.Throttle, fresh.Boost = a.Sim.Speed, a.Sim.Throttle, a.Sim.Boost
			else
				a.Down = false
				a.CrashSent = false
				a.Land = if a.World == "Planet" then Landing.new(false) else nil
				a.Gun = ShipWeapons.newGun()
				a.Lock = Lock.new()
				a.CamPos = nil
				Hud.toast("Success", "🛡️ Nave nueva: escudo y casco llenos")
			end
			a.Sim = fresh
			if fresh.Mode ~= a.Mode then
				a.Mode = fresh.Mode
				setSpace(fresh.Mode == "Space")
			end
		end
	elseif kind == "Wave" then
		if p.Done then
			Hud.toast("Success", "🏆 ¡Arena superada!")
		elseif p.Cleared then
			Hud.toast("Success", ("✅ Oleada %d superada"):format(p.Wave or 0))
			SoundFx.play("MisionCompleta", 0.6)
		else
			Hud.toast("Info", ("⚠ Oleada %d: %d enemigos"):format(p.Wave or 0, p.Count or 0))
			SoundFx.play("Tension", 0.5)
		end
	end
end

function AirCombatClient.init()
	remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AirCombat", 10) :: RemoteEvent?
	view = AirCombatHud.new(player:WaitForChild("PlayerGui"), TOUCH)
	ShipButtons.register(TouchLayout, {
		Active = function()
			return active ~= nil and not active.Down
		end,
		Hold = function(slot: string, down: boolean)
			holds[slot] = down
		end,
		Press = press,
		Status = function()
			local a = active
			if not a then
				return { Missiles = 0, MaxMissiles = ShipWeapons.Missile.Ammo, Boost = 1, BoostReady = true, Locked = false, Firing = false, Boosting = false, Braking = false }
			end
			return {
				Missiles = a.Gun.Missiles,
				MaxMissiles = ShipWeapons.Missile.Ammo,
				Boost = a.Sim.Boost,
				BoostReady = a.Sim.Time >= a.Sim.CoolUntil,
				Locked = a.Lock.Locked,
				Firing = holds.Fire == true,
				Boosting = a.Sim.Boosting,
				Braking = a.Sim.Braking,
			}
		end,
	})
	if remote then
		remote.OnClientEvent:Connect(function(kind, payload)
			local ok, err = pcall(onEvent, kind, payload)
			if not ok then
				warn("[AirCombatClient] " .. tostring(err))
			end
		end)
	end
	player:GetAttributeChangedSignal("AirCombat"):Connect(function()
		if player:GetAttribute("AirCombat") == nil then
			stop()
		end
	end)
	player.CharacterAdded:Connect(function()
		stop()
	end)
end

-- (pruebas)
-- La nave que pilotas ahora (para Controllers/SpaceClient): { World, Root, Down, Mode } o nil
function AirCombatClient.current(): { [string]: any }?
	local a = active
	if not a or not a.Root.Parent then
		return nil
	end
	return {
		World = a.World,
		Root = a.Root,
		Down = a.Down,
		Mode = a.Mode,
		Speed = a.Sim.Speed,
		Planet = a.Planet,
		Landed = Landing.landed(a.Land),
		Phase = if a.Land then a.Land.Phase else nil,
	}
end

AirCombatClient._active = function()
	return active
end
AirCombatClient._onEvent = onEvent
AirCombatClient._readInput = readInput

return AirCombatClient
