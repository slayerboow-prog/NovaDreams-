-- Joystick (cliente, solo móvil y tableta): el joystick fijo de abajo a la izquierda, con el estilo del HUD.
--
--   * Aro azul brillante con flechas ▲▼◀▶ dibujadas y un pomo azul que sigue al dedo.
--   * Mueve al personaje con Humanoid:Move(dirección, true): relativo a la cámara, con zona muerta
--     y velocidad según lo lejos que lleves el pomo. Al soltar, el pomo vuelve al centro.
--   * Montado en un vehículo: el mismo joystick acelera, frena y gira (ThrottleFloat / SteerFloat).
--   * El resto de la pantalla sigue moviendo la cámara (pulgar derecho); los botones y el joystick no.
--   * Se usa en lugar del joystick de Roblox (DevTouchMovementMode = Scriptable). Si Roblox no deja
--     cambiarlo, no se crea y se queda el de Roblox, que sigue funcionando.
-- En el ordenador y la consola no aparece.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.UI.Theme)
local Icons = require(script.Parent.Parent.UI.Icons)
local HudLayout = require(script.Parent.Parent.UI.HudLayout)

local create = Theme.create
local H = Theme.Hud
local rgb = Color3.fromRGB

local Joystick = {}

local player = Players.LocalPlayer
local DEADZONE = 0.12
local KNOB = 0.42 -- tamaño del pomo respecto al aro
local STEP = "ValmarJoystick"

local gui: ScreenGui? = nil
local base: Frame? = nil
local knob: Frame? = nil
local active: InputObject? = nil
local vector = Vector2.zero -- (-1..1, -1..1): x a la derecha, y hacia abajo
local rawPush = 0 -- lo lejos que está el dedo del centro (sin zona muerta; 1 = el borde)
local busy = false
local stepping = false

local function humanoid(): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

-- Aplica el vector al personaje (o al vehículo). Lo usa el bucle mientras tocas y las pruebas.
function Joystick.drive(v: Vector2)
	local h = humanoid()
	if not h then
		return
	end
	local seat = h.SeatPart
	if seat and seat:IsA("VehicleSeat") then
		-- Arriba = acelerar, abajo = frenar / marcha atrás, los lados = girar
		seat.ThrottleFloat = -v.Y
		seat.SteerFloat = v.X
		seat.Throttle = math.sign(-v.Y) * (if math.abs(v.Y) > 0.3 then 1 else 0)
		seat.Steer = math.sign(v.X) * (if math.abs(v.X) > 0.3 then 1 else 0)
		return
	end
	-- Relativo a la cámara: -Z es hacia delante (arriba en el joystick)
	h:Move(Vector3.new(v.X, 0, v.Y), true)
end

-- Del desplazamiento del dedo (en píxeles) al vector (con zona muerta y magnitud analógica)
function Joystick.vectorFrom(offset: Vector2, radius: number): Vector2
	local raw = offset / math.max(radius, 1)
	local magnitude = raw.Magnitude
	if magnitude < DEADZONE then
		return Vector2.zero
	end
	local clamped = math.min(magnitude, 1)
	local scaled = (clamped - DEADZONE) / (1 - DEADZONE)
	return raw.Unit * scaled
end

local function placeKnob(v: Vector2, animate: boolean)
	if not knob then
		return
	end
	local reach = (1 - KNOB) / 2
	local target = UDim2.fromScale(0.5 + v.X * reach, 0.5 + v.Y * reach)
	if animate then
		TweenService:Create(knob, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = target }):Play()
	else
		knob.Position = target
	end
end

local function stopStepping()
	if stepping then
		stepping = false
		pcall(function()
			RunService:UnbindFromRenderStep(STEP)
		end)
	end
end

local function release()
	active = nil
	vector = Vector2.zero
	rawPush = 0
	stopStepping()
	Joystick.drive(Vector2.zero)
	placeKnob(Vector2.zero, true)
	if base then
		local edge = base:FindFirstChild("Edge") :: UIStroke?
		if edge then
			edge.Thickness = 3
		end
	end
end

local function update(position: Vector3)
	if not base then
		return
	end
	local center = base.AbsolutePosition + base.AbsoluteSize / 2
	local radius = base.AbsoluteSize.X / 2
	local v = Joystick.vectorFrom(Vector2.new(position.X, position.Y) - center, radius)
	vector = v
	local raw = (Vector2.new(position.X, position.Y) - center) / math.max(radius, 1)
	rawPush = raw.Magnitude
	if raw.Magnitude > 1 then
		raw = raw.Unit
	end
	placeKnob(raw, false)
end

local function startStepping()
	if stepping then
		return
	end
	stepping = true
	-- A la vez que el control de Roblox (Locomotion suaviza después): cada fotograma, porque la cámara gira
	RunService:BindToRenderStep(STEP, Enum.RenderPriority.Input.Value, function()
		if busy then
			return
		end
		Joystick.drive(vector)
	end)
end

local function build(parent: Instance)
	gui = create("ScreenGui", {
		Name = "JoystickGui",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 4,
		Parent = parent,
	})
	HudLayout.scaleGui(gui :: ScreenGui)
	base = create("Frame", {
		Name = "Joystick",
		Active = true, -- los toques que empiezan aquí no mueven la cámara
		BackgroundColor3 = H.Navy,
		BackgroundTransparency = 0.45,
		Parent = gui,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(120, 170, 255), rgb(30, 50, 110)) }),
	})
	Theme.edge(base :: Frame, nil, 3)
	Theme.halo(base :: Frame, H.Glow, 12, 999)
	-- Aro interior fino
	create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.72, 0.72),
		BackgroundTransparency = 1,
		Parent = base,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = H.Edge, Thickness = 1.5, Transparency = 0.5 }),
	})
	-- Flechas ▲ ▼ ◀ ▶ (dibujadas)
	for _, arrow in { { 0.5, 0.1, -90 }, { 0.5, 0.9, 90 }, { 0.1, 0.5, 180 }, { 0.9, 0.5, 0 } } do
		Icons.chevron({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(arrow[1], arrow[2]),
			Size = UDim2.fromScale(0.1, 0.1),
			Rotation = arrow[3],
			Color = H.Glow,
			Thickness = 3,
			Parent = base,
		})
	end
	knob = create("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(KNOB, KNOB),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = base,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(120, 210, 255), rgb(20, 90, 230)) }),
		create("UIStroke", { Color = H.Glow, Thickness = 2, Transparency = 0.1 }),
	})

	base.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch or active or busy then
			return
		end
		active = input
		local edge = (base :: Frame):FindFirstChild("Edge") :: UIStroke?
		if edge then
			edge.Thickness = 4.5
		end
		update(input.Position)
		startStepping()
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == active then
			update(input.Position)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input == active then
			release()
		end
	end)
	HudLayout.onChanged(function(layout)
		local placement = layout.Items.Joystick
		if placement and base then
			HudLayout.apply(base, placement)
		end
	end)
end

-- Mientras hablas con alguien o ves una cinemática, el joystick se aparta (y suelta)
function Joystick.setBusy(value: boolean)
	busy = value
	if value and active then
		release()
	end
	if base then
		base.Visible = not value
	end
end

function Joystick.init()
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	if not touch then
		return
	end
	-- Sin el joystick de Roblox (y sin su botón de saltar: el nuestro está en el racimo)
	local ok = pcall(function()
		player.DevTouchMovementMode = Enum.DevTouchMovementMode.Scriptable
	end)
	if not ok then
		warn("[Joystick] No se pudo cambiar el control táctil: se queda el joystick de Roblox")
		return
	end
	build(player:WaitForChild("PlayerGui"))
	player.CharacterAdded:Connect(release)
end

-- ¿Está el joystick propio en uso? (si no, el de Roblox) y cuánto se empuja (0..1)
function Joystick.active(): boolean
	return base ~= nil
end

-- Lo que pide el joystick como el control de Roblox (relativo a la cámara, -Z adelante)
function Joystick.moveVector(): Vector3
	return Vector3.new(vector.X, 0, vector.Y)
end

function Joystick.push(): number
	if not active then
		return 0
	end
	return math.min(1, rawPush)
end

-- (pruebas) estado interno
function Joystick._state()
	return { Gui = gui, Base = base, Knob = knob, Vector = vector }
end

return Joystick
