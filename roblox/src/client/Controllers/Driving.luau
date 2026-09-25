-- Driving (cliente): conducir coches, motos, bicis, monopatines y patinetes.
--
-- Cuando te sientas en el asiento de conductor ("DriverSeat") de un vehículo con el atributo
-- Drivable, este script lo mueve cada fotograma:
--   * W/S (o el joystick / gatillos del mando): acelerar, frenar y marcha atrás
--   * A/D: girar (se gira más despacio cuanto más rápido vas, como en la realidad)
--   * Sigue el suelo con rayos: sube bordillos pequeños y cuestas, y se inclina con ellas
--   * Choca con paredes, farolas y árboles (se para en seco) y no entra en el agua
--   * Motos y bicis se inclinan en las curvas; en el monopatín y el patinete vas de pie
--   * Velocímetro abajo en el centro
-- Saltar (Espacio) o F para bajarse. El servidor (VehicleService) le da el control a tu
-- ordenador, así que se mueve sin retraso y los demás lo ven igual.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Theme = require(script.Parent.Parent.UI.Theme)

local Driving = {}

local player = Players.LocalPlayer
local IDLE = { R15 = 507766388, R6 = 180435571 } -- postura de pie (monopatín, patinete)

type State = {
	Model: Model,
	Chassis: BasePart,
	Seat: VehicleSeat,
	Kind: string,
	Speed: number,
	Yaw: number,
	Up: Vector3,
	Lean: number,
	Base: Vector3, -- dónde está (a ras de suelo) según este script, no según la física
	Pose: AnimationTrack?,
}
local state: State? = nil
local gui: ScreenGui
local speedLabel: TextLabel

local function yawOf(cf: CFrame): number
	local look = cf.LookVector
	return math.atan2(-look.X, -look.Z)
end

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
		Up = Vector3.yAxis,
		Lean = 0,
		Base = chassis.Position - chassis.CFrame.UpVector * (chassis.Size.Y / 2),
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
				track:Play(0.2)
				s.Pose = track
			end
		end
	end
	state = s
	gui.Enabled = true
end

local function stop()
	if state and state.Pose then
		state.Pose:Stop(0.2)
	end
	state = nil
	gui.Enabled = false
end

-- Suelo bajo un punto (ignora el vehículo, las personas y lo que no choca). nil = agua o vacío
local function ground(params: RaycastParams, point: Vector3, top: number): RaycastResult?
	local hit = workspace:Raycast(Vector3.new(point.X, top, point.Z), Vector3.new(0, -(top - point.Y) - 14, 0), params)
	if hit and hit.Material == Enum.Material.Water then
		return nil
	end
	return hit
end

local function step(dt: number)
	local s = state
	if not s then
		return
	end
	if not s.Chassis.Parent or s.Chassis.Anchored then
		return -- el servidor aún no lo ha soltado (o ya lo ha aparcado)
	end
	local tuning = Gameplay.Driving[s.Kind]
	local maxSpeed = Gameplay.Vehicles[s.Kind].Speed
	local throttle = s.Seat.ThrottleFloat
	local steer = s.Seat.SteerFloat

	-- Acelerar / frenar / marcha atrás
	if throttle > 0.05 then
		if s.Speed < 0 then
			s.Speed = math.min(0, s.Speed + tuning.Brake * dt)
		else
			s.Speed = math.min(maxSpeed, s.Speed + tuning.Accel * throttle * dt)
		end
	elseif throttle < -0.05 then
		if s.Speed > 0 then
			s.Speed = math.max(0, s.Speed - tuning.Brake * dt)
		else
			s.Speed = math.max(-tuning.Reverse, s.Speed - tuning.Accel * 0.6 * dt)
		end
	else
		-- Sin pisar nada se va parando poco a poco
		local drag = 6 + math.abs(s.Speed) * 0.12
		s.Speed = if s.Speed > 0 then math.max(0, s.Speed - drag * dt) else math.min(0, s.Speed + drag * dt)
	end

	-- Girar: más fácil despacio, más suave rápido (y al revés en marcha atrás)
	local moving = math.clamp(math.abs(s.Speed) / 6, 0, 1)
	local fast = 1 - 0.45 * math.clamp(math.abs(s.Speed) / maxSpeed, 0, 1)
	local direction = if s.Speed >= 0 then 1 else -1
	s.Yaw -= steer * tuning.Turn * moving * fast * direction * dt

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
	local move = forward * s.Speed * dt

	-- Choques: un rayo por delante (o por detrás) a media altura, desde las dos esquinas
	if math.abs(s.Speed) > 0.1 then
		local sign = if s.Speed > 0 then 1 else -1
		local right = Vector3.new(-forward.Z, 0, forward.X)
		for _, side in { -0.4, 0.4 } do
			local origin = base + Vector3.new(0, 1.6, 0) + right * size.X * side + forward * sign * (size.Z / 2 - 0.5)
			local hit = workspace:Raycast(origin, forward * sign * (math.abs(s.Speed) * dt + 0.8), params)
			if hit and hit.Normal.Y < 0.6 then
				s.Speed = -s.Speed * 0.15 -- rebote suave
				move = Vector3.zero
				break
			end
		end
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
	-- Si el suelo baja mucho (un escalón hacia abajo), cae suave en vez de pegarse de golpe
	if y < target.Y - 0.5 then
		y = math.max(y, target.Y - 60 * dt)
	end
	s.Up = s.Up:Lerp(up, math.min(1, dt * 10)).Unit

	-- Inclinarse en las curvas (motos, bicis, patinetes)
	local leanTarget = -steer * math.rad(tuning.Lean) * math.clamp(math.abs(s.Speed) / (maxSpeed * 0.6), 0, 1)
	s.Lean += (leanTarget - s.Lean) * math.min(1, dt * 6)

	local position = Vector3.new(target.X, y, target.Z)
	s.Base = position
	local look = (forward - s.Up * forward:Dot(s.Up)).Unit
	local oriented = CFrame.lookAt(position, position + look, s.Up) * CFrame.Angles(0, 0, s.Lean)
	s.Chassis.CFrame = oriented * CFrame.new(0, size.Y / 2, 0)
	s.Chassis.AssemblyLinearVelocity = forward * s.Speed
	s.Chassis.AssemblyAngularVelocity = Vector3.zero

	speedLabel.Text = ("%s  %d km/h"):format(Gameplay.Vehicles[s.Kind].Icon, math.floor(math.abs(s.Speed) + 0.5))
end

function Driving.init()
	gui = Theme.create("ScreenGui", { Name = "DrivingGui", ResetOnSpawn = false, Enabled = false, Parent = player:WaitForChild("PlayerGui") })
	local panel = Theme.panel({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -96),
		Size = UDim2.fromOffset(250, 58),
		Parent = gui,
	})
	speedLabel = Theme.label({
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.fromOffset(0, 4),
		Text = "",
		Font = Theme.FontBold,
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = panel,
	})
	Theme.label({
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.fromOffset(0, 34),
		Text = "W/S acelerar y frenar · A/D girar · F bajarse",
		TextSize = 12,
		TextColor3 = Theme.Colors.Muted,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = panel,
	})

	local function watch(character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if not humanoid then
			return
		end
		humanoid.Seated:Connect(function(active, seat)
			if active and seat and seat:IsA("VehicleSeat") and seat.Name == "DriverSeat" then
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
end

return Driving
