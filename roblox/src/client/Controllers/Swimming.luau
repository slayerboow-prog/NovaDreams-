-- Swimming (cliente): el cuerpo de TU personaje en el agua (lo arranca DivingUI.init).
--
-- Roblox, solo, hace nadar así: flotas según lo que pesa el cuerpo, y al avanzar vas hacia donde mira
-- la cámara (con la cámara un poco hacia abajo, que es lo normal, te ibas al fondo sin querer y al
-- parar subías de golpe). El fondo del mar está a 12 studs: en medio segundo estabas abajo y otra
-- vez arriba, y te quedabas tumbado en la arena. Aquí se lleva la altura con reglas claras
-- (Shared/Swim, probadas en scripts/test-swim.luau):
--   * En la superficie: flotas con la cabeza fuera (quieto de pie en el agua, nadando a ras).
--   * Bucear (botón, C o LT) baja; Subir (botón, Espacio o A) sube. Sin tocar nada, te quedas a esa
--     profundidad (flotabilidad neutra). Nunca bajas hasta tumbarte en el fondo.
--   * El cuerpo va siempre derecho (AlignOrientation: la postura de nadar la pone SeaMotion encima).
--   * UN SOLO dueño del giro del cuerpo (v125, «bucea al revés» en el móvil del dueño por 3.ª vez):
--     mientras este control lleva el cuerpo, el estado Swimming del Humanoid se APAGA
--     (SetStateEnabled). Ese estado de Roblox tumba el HumanoidRootPart hacia donde nadas DURANTE la
--     física, después de que AgeMotion calcule la postura (PreSimulation): la corrección
--     SeaMotion.uprightRoot llegaba con el giro del frame anterior y la AlignOrientation peleaba con
--     él; tumbado 90° por Roblox + 90° de la postura = cabeza abajo y la tripa arriba. Sin ese
--     estado el Humanoid queda en Freefall (derecho, gira con AutoRotate y avanza con WalkSpeed), la
--     altura la lleva SwimLift y el tumbarse lo pone SOLO SeaMotion (Root) encima de un
--     HumanoidRootPart derecho. Saltar en la superficie: ChangeState(Jumping) (desde Freefall
--     Roblox no salta solo). Al salir del agua se vuelve a encender. Quien toque el cuerpo en el agua
--     (la cola de Hondario, la cúpula de Nácara…) no debe volver a encender Swimming ni girar el
--     HumanoidRootPart: la postura va en SeaMotion (Root) y el «nadando» se mira con
--     Swimming.isSwimming() o el atributo SwimMode, NO con Humanoid:GetState() == Swimming.
--   * En la orilla, donde se hace pie, no se toca nada: andas por el fondo.
--   * Saltar en la superficie (para subir a un muelle o a una roca) lo hace Roblox, como siempre.
--   * La cámara: nunca dentro de la arena del fondo, y flotando va por encima del agua (sin quedarse
--     partida en la superficie). La luz de debajo del agua la pone SeaBiome/DayLight.
--   * Mar hondo (shared/Sea/Ocean, hasta 156 m): Correr buceando sube y baja más deprisa
--     (Swim.SprintBoost) y las corrientes (Ocean.currentAt: la Garganta Negra, el kelp, el talud)
--     empujan suave a quien bucea (una VectorForce pequeña: se nada contra ella sin problema).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Swim = require(ReplicatedStorage.Shared.Swim)
local Ocean = require(ReplicatedStorage.Shared.Sea.Ocean)
local Nacara = require(ReplicatedStorage.Shared.Sea.Nacara) -- (la cúpula de aire de Nácara: dentro se anda)
local SoundFx: any = nil -- (Controllers/SoundFx; se carga en la primera brazada)

local Swimming = {}

local player = Players.LocalPlayer

local mode: Swim.Mode = "Surface"
local engaged = false -- el control está llevando el cuerpo (estás nadando en agua que cubre)
local input = 0 -- -1 bajar, 1 subir (DivingUI: botones y teclas)
local jumpHeld = false -- Espacio / A pulsado (DivingUI): buceando es subir
local jumpUntil = 0 -- saltando en la superficie: Roblox manda un momento
local changed = Instance.new("BindableEvent")

local STATES_OFF = {
	[Enum.HumanoidStateType.Dead] = true,
	[Enum.HumanoidStateType.Seated] = true,
	[Enum.HumanoidStateType.Climbing] = true,
	[Enum.HumanoidStateType.Physics] = true,
	[Enum.HumanoidStateType.Ragdoll] = true,
	[Enum.HumanoidStateType.PlatformStanding] = true,
}

-- DivingUI: lo que pulsas (-1 bajar, 0 nada, 1 subir)
function Swimming.setInput(value: number)
	input = math.clamp(value, -1, 1)
end

-- DivingUI: Espacio (o A del mando) pulsado o soltado
function Swimming.setJump(held: boolean)
	jumpHeld = held
end

function Swimming.input(): number
	return input
end

-- ¿Estás nadando (en agua que cubre)?
function Swimming.isSwimming(): boolean
	return engaged
end

-- "Surface" (flotando) o "Dive" (buceando)
function Swimming.mode(): Swim.Mode
	return mode
end

Swimming.Changed = changed.Event

-- El estado Swimming de Roblox: apagado mientras este control lleva el cuerpo (ver arriba)
local stateHumanoid: Humanoid? = nil
local function ownSwimState(humanoid: Humanoid?, on: boolean)
	if on and humanoid then
		if stateHumanoid ~= humanoid then
			stateHumanoid = humanoid
			pcall(function()
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
			end)
		end
		if humanoid:GetState() == Enum.HumanoidStateType.Swimming then
			pcall(function()
				humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
			end)
		end
	elseif stateHumanoid then
		local h = stateHumanoid
		stateHumanoid = nil
		pcall(function()
			h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
		end)
	end
end
Swimming._ownSwimState = ownSwimState -- (las pruebas)

local function setEngaged(on: boolean)
	if not on then
		ownSwimState(nil, false)
	end
	if engaged == on then
		return
	end
	engaged = on
	if not on then
		mode = "Surface"
	end
	player:SetAttribute("SwimMode", if on then mode else nil)
	changed:Fire(on)
end

-- Restricciones (se crean una vez por personaje y solo se encienden en el agua)
type Rig = { Root: BasePart, Attachment: Attachment, Lift: LinearVelocity, Upright: AlignOrientation, Current: VectorForce }
local rig: Rig? = nil

local function makeRig(root: BasePart): Rig
	local attachment = Instance.new("Attachment")
	attachment.Name = "SwimAttachment"
	-- Eje principal (X del attachment) hacia arriba: AlignOrientation solo endereza, no gira
	attachment.CFrame = CFrame.fromMatrix(Vector3.zero, Vector3.yAxis, Vector3.zAxis)
	attachment.Parent = root
	local lift = Instance.new("LinearVelocity")
	lift.Name = "SwimLift"
	lift.Attachment0 = attachment
	lift.RelativeTo = Enum.ActuatorRelativeTo.World
	lift.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
	lift.LineDirection = Vector3.yAxis
	lift.LineVelocity = 0
	lift.MaxForce = 0
	lift.Enabled = false
	lift.Parent = root
	local upright = Instance.new("AlignOrientation")
	upright.Name = "SwimUpright"
	upright.Mode = Enum.OrientationAlignmentMode.OneAttachment
	upright.Attachment0 = attachment
	upright.PrimaryAxisOnly = true
	upright.PrimaryAxis = Vector3.yAxis
	upright.Responsiveness = 30
	upright.MaxTorque = 1e6
	-- (rígida: el estado Swimming del Humanoid tumba el HumanoidRootPart hacia donde nadas y, con la
	-- postura de SeaMotion encima, el cuerpo quedaba cabeza abajo —v123—. AgeMotion además corrige la
	-- postura con el giro real del HumanoidRootPart: SeaMotion.uprightRoot)
	upright.RigidityEnabled = true
	upright.Enabled = false
	upright.Parent = root
	local current = Instance.new("VectorForce")
	current.Name = "SwimCurrent"
	current.Attachment0 = attachment
	current.RelativeTo = Enum.ActuatorRelativeTo.World
	current.ApplyAtCenterOfMass = true
	current.Force = Vector3.zero
	current.Enabled = false
	current.Parent = root
	return { Root = root, Attachment = attachment, Lift = lift, Upright = upright, Current = current }
end

local floorParams = RaycastParams.new()
floorParams.FilterType = Enum.RaycastFilterType.Exclude
floorParams.IgnoreWater = true
floorParams.RespectCanCollide = true

local waterParams = RaycastParams.new()
waterParams.FilterType = Enum.RaycastFilterType.Include
waterParams.IgnoreWater = false

-- El fondo debajo de un punto (sin el agua; nil si no hay nada en 600 studs: la sima llega a -560)
local function floorBelow(at: Vector3, ignore: { Instance }): number?
	floorParams.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(at, Vector3.new(0, -600, 0), floorParams)
	return if hit then hit.Position.Y else nil
end

-- ¿Hay agua (del terreno) en esta columna?
local function waterAt(x: number, z: number): boolean
	waterParams.FilterDescendantsInstances = { workspace.Terrain }
	local hit = workspace:Raycast(Vector3.new(x, Swim.Surface + 14, z), Vector3.new(0, -30, 0), waterParams)
	return hit ~= nil and hit.Material == Enum.Material.Water
end

function Swimming.init()
	local waterCheckAt, waterHere = 0, false
	local floorY: number? = nil
	local clock = 0 -- tiempo de juego (suma de los frames)
	local nextStroke = 0 -- cuándo suena la siguiente brazada

	RunService.Heartbeat:Connect(function(dt: number)
		clock += math.min(dt or 0, 0.1)
		local ok, err = pcall(function()
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not character or not humanoid or not root then
				setEngaged(false)
				return
			end
			if not rig or rig.Root ~= root or not rig.Attachment.Parent then
				rig = makeRig(root)
			end
			local r = rig :: Rig
			local scale = math.max((character :: Model):GetScale(), 0.3)
			local pos = root.Position
			local state = humanoid:GetState()
			local now = clock
			if now - waterCheckAt > 0.25 then
				waterCheckAt = now
				waterHere = pos.Y < Swim.Surface + 1 * scale and waterAt(pos.X, pos.Z)
			end
			floorY = if waterHere then floorBelow(pos, { character :: Instance, workspace.CurrentCamera :: Instance }) else nil
			local can = waterHere
				and humanoid.Health > 0
				and not STATES_OFF[state]
				and humanoid.SeatPart == nil
				and not humanoid.Sit
				and not humanoid.PlatformStand
				and player:GetAttribute("Riding") == nil
				and player:GetAttribute("Passenger") == nil
				and not root.Anchored
				and Swim.deepEnough(floorY, scale)
				and not Nacara.inDome(pos) -- (dentro de la cúpula de aire de Nácara no hay agua: se anda)
			-- Entras al agua cuando el cuerpo baja de la superficie; sales si subes fuera (saltando, a un
			-- muelle) o si se hace pie
			local inside = pos.Y < Swim.Surface + (if engaged then 0.6 else 0.1) * scale
			setEngaged(can and inside)
			if not engaged then
				r.Lift.Enabled = false
				r.Upright.Enabled = false
				r.Current.Enabled = false
				return
			end
			-- Saltar en la superficie: sale del agua como siempre (Roblox), sin el control un momento
			local jump = jumpHeld or humanoid.Jump
			if jump and mode == "Surface" and input <= 0 and now > jumpUntil then
				jumpUntil = now + 0.45
				-- (sin el estado Swimming, Roblox no salta desde el agua: se le pide el salto)
				pcall(function()
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end)
			end
			local jumping = now < jumpUntil
			-- Un solo dueño del giro: fuera el estado Swimming de Roblox (salvo en el salto, que sale del agua)
			if not jumping then
				ownSwimState(humanoid, true)
			end
			local want = input
			if want == 0 and mode == "Dive" and jump then
				want = 1 -- buceando, Saltar es subir
			end
			local v = root.AssemblyLinearVelocity
			local moving = math.clamp((Vector3.new(v.X, 0, v.Z).Magnitude - 1.5) / 6, 0, 1)
			local boost = if player:GetAttribute("Sprinting") == true then Swim.SprintBoost else 1
			local newMode, vy = Swim.step({ Mode = mode, RootY = pos.Y, FloorY = floorY, Scale = scale, Input = want, Moving = moving, Boost = boost })
			if newMode ~= mode then
				mode = newMode
				player:SetAttribute("SwimMode", mode)
			end
			r.Lift.Enabled = not jumping
			r.Lift.LineVelocity = vy
			r.Lift.MaxForce = root.AssemblyMass * (Swim.Accel + workspace.Gravity)
			r.Upright.Enabled = true
			-- Corriente: solo buceando (en la superficie ya te mueven las olas)
			local push = if mode == "Dive" then Ocean.currentAt(pos) + Nacara.currentAt(pos) else Vector3.zero -- (y la corriente guía hacia Nácara)
			r.Current.Enabled = push.Magnitude > 0.05
			r.Current.Force = push * root.AssemblyMass * 4
			-- Brazadas en la superficie: una cada medio paso de crol (más seguidas cuanto más rápido)
			if mode == "Surface" and moving > 0.25 and now >= nextStroke then
				nextStroke = now + 0.95 - 0.35 * moving
				SoundFx = SoundFx or require(script.Parent.SoundFx)
				SoundFx.play("Brazada", { At = root, Volume = 0.6 + 0.4 * moving })
			end
		end)
		if not ok then
			warn("[Swimming] " .. tostring(err))
		end
	end)

	-- La cámara: después de la de Roblox, nunca dentro del fondo ni partida en la superficie
	RunService:BindToRenderStep("SwimCamera", Enum.RenderPriority.Camera.Value + 1, function()
		if not engaged then
			return
		end
		local camera = workspace.CurrentCamera
		if not camera or camera.CameraType ~= Enum.CameraType.Custom then
			return
		end
		local cf = camera.CFrame
		local pos = cf.Position
		local focus = camera.Focus.Position
		local floor: number? = nil
		if pos.Y < Swim.Surface + 1 then
			-- (desde la altura del personaje: en una cueva, el suelo de la cueva y no su techo)
			local fromY = math.min(Swim.Surface + 1, math.max(focus.Y, pos.Y) + 1)
			floor = floorBelow(Vector3.new(pos.X, fromY, pos.Z), { player.Character :: Instance, camera :: Instance })
		end
		local fixed = Swim.cameraPosition(pos, focus, floor)
		fixed = Vector3.new(fixed.X, Swim.cameraY(fixed.Y, mode), fixed.Z)
		if (fixed - pos).Magnitude > 1e-3 then
			camera.CFrame = cf.Rotation + fixed
		end
	end)

	player.CharacterAdded:Connect(function()
		rig = nil
		input = 0
		jumpHeld = false
		jumpUntil = 0
		setEngaged(false)
	end)
end

return Swimming
