-- AirCombatClient (cliente): pilotar la nave del combate aéreo y espacial (Services/AirCombatService,
-- docs/combate-aereo.md).
--
-- Cuando el servidor te sienta en la nave ("Start"), tu ordenador la mueve cada fotograma con
-- shared/AirCombat/ShipFlight (predicción: sin retraso) y el servidor comprueba que tenga sentido.
--   * Móvil: el joystick de la izquierda es la palanca (arriba sube el morro, a los lados gira; la nave
--     se inclina y se nivela sola) y el motor va solo a crucero. A la derecha FUEGO (mantener; ayuda a
--     apuntar con un cono más ancho), MISIL (con un blanco fijado), TURBO y FRENO (mantener) y Salir
--     (UI/ShipButtons en HudLayout.Fly, todos ≥ 44 pt).
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
local Joystick = require(script.Parent.Joystick)
local SoundFx = require(script.Parent.SoundFx)
local CameraShake = require(script.Parent.CameraShake)
local AirCombatFx = require(script.Parent.AirCombatFx)
local Hud = require(script.Parent.Parent.UI.Hud)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local ShipButtons = require(script.Parent.Parent.UI.ShipButtons)
local AirCombatHud = require(script.Parent.Parent.UI.AirCombatHud)

local AirCombatClient = {}

local player = Players.LocalPlayer
local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
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
	World: string, -- "Arena" | "Cosmos" (el espacio encima de Valmar: Controllers/SpaceClient)
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

local function buildStars(): Model
	local model = Instance.new("Model")
	model.Name = "AirStars"
	local rng = Random.new(42)
	local count = if TOUCH then 140 else 260
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
	return model
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
	if TOUCH then
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
	if Joystick.active() then
		local v = Joystick.moveVector()
		pitch -= v.Z
		yaw += v.X
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
	setSpace(false)
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
	if not a.Ship.Parent or not a.Root.Parent or not humanoid or player:GetAttribute("AirCombat") == nil then
		stop()
		return
	end
	local list = targets(a, dt)
	local sim = a.Sim
	if not a.Down then
		local events = ShipFlight.advance(sim, readInput(), dt, ENVS[a.World] or ENVS.Arena)
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
		a.Root.CFrame = ShipFlight.cframe(sim)
		a.Root.AssemblyLinearVelocity = ShipFlight.velocity(sim)
		a.Root.AssemblyAngularVelocity = Vector3.zero
	else
		-- Derribado: la nave (escondida) se queda donde estalló; la cámara mira la explosión
		a.Root.CFrame = ShipFlight.cframe(sim)
		a.Root.AssemblyLinearVelocity = Vector3.zero
	end
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
	while os.clock() - t0 < 5 do
		local h = humanoidOf()
		if h and h.SeatPart == seat then
			break
		end
		task.wait(0.05)
	end
	local section = if payload.Section == "Space" then "Space" else "Atmos"
	local cp = if typeof(payload.Checkpoint) == "CFrame" then payload.Checkpoint else root.CFrame
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
		World = if payload.World == "Cosmos" then "Cosmos" else "Arena",
	}
	active = a
	currentWorld = a.World
	a.Engine = SoundFx.loop("NaveMotor", root)
	TouchLayout.setFlying(true)
	TouchLayout.refresh()
	setJump(false)
	setSpace(section == "Space")
	if view then
		AirCombatHud.setEnabled(view, true)
	end
	ContextActionService:BindActionAtPriority(ACTION, onKey, false, Enum.ContextActionPriority.High.Value + 60,
		Enum.KeyCode.F, Enum.KeyCode.X, Enum.KeyCode.Space, Enum.KeyCode.LeftShift, Enum.KeyCode.LeftControl, Enum.KeyCode.Q, Enum.KeyCode.E,
		Enum.KeyCode.C, Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonB, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY, Enum.KeyCode.ButtonR1, Enum.KeyCode.ButtonL1,
		Enum.UserInputType.MouseButton2)
	RunService:BindToRenderStep(STEP, Enum.RenderPriority.Camera.Value + 2, step)
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
	elseif kind == "Respawn" or kind == "Reset" then
		if a and typeof(p.CFrame) == "CFrame" then
			local fresh = ShipFlight.new("Caza", p.CFrame, (if a.World == "Cosmos" then Zone else Arena).modeAt(p.CFrame.Position))
			if kind == "Reset" then
				fresh.Speed, fresh.Throttle, fresh.Boost = a.Sim.Speed, a.Sim.Throttle, a.Sim.Boost
			else
				a.Down = false
				a.CrashSent = false
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
	return { World = a.World, Root = a.Root, Down = a.Down, Mode = a.Mode, Speed = a.Sim.Speed }
end

AirCombatClient._active = function()
	return active
end
AirCombatClient._onEvent = onEvent
AirCombatClient._readInput = readInput

return AirCombatClient
