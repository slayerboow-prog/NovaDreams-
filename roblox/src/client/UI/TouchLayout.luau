-- TouchLayout (cliente): dónde va cada botón táctil del móvil, para que nada se pise.
--
-- Todos los botones de acción van en arco alrededor del botón de saltar de Roblox (abajo a la
-- derecha), como en los juegos de consola: el más usado (golpear) pegado a él y el resto en un
-- segundo arco. Abajo a la izquierda queda libre para el joystick y abajo en el centro, la barra
-- rápida. Cada sistema pide su hueco por nombre:
--
--   local slot = TouchLayout.slot("Golpear")  -> { Position: UDim2, Size: number }
--   TouchLayout.place(button, "Golpear")      -> coloca (y recoloca al girar la pantalla)

local Players = game:GetService("Players")

local TouchLayout = {}

local player = Players.LocalPlayer

-- Ángulo (grados: 180 = a la izquierda del botón de saltar, 90 = encima), anillo (1 o 2) y tamaño
local SLOTS = {
	Golpear = { Angle = 180, Ring = 1, Size = 64 },
	Defender = { Angle = 132, Ring = 1, Size = 54 },
	Correr = { Angle = 80, Ring = 1, Size = 56 },
	Piedra = { Angle = 170, Ring = 2, Size = 48 },
	Linterna = { Angle = 145, Ring = 2, Size = 46 },
	Foto = { Angle = 118, Ring = 2, Size = 46 },
	Extra = { Angle = 92, Ring = 2, Size = 46 }, -- (bajarse del vehículo, claxon…)
	Claxon = { Angle = 180, Ring = 1, Size = 60 }, -- conduciendo, en el sitio de golpear
	Bajarse = { Angle = 80, Ring = 1, Size = 56 }, -- conduciendo (o de pasajero), en el sitio de correr
	Sirena = { Angle = 132, Ring = 1, Size = 54 },
	-- Pedales (conduciendo; el volante es el joystick de Roblox, a la izquierda)
	Acelerar = { Angle = 130, Ring = 2, Size = 72 },
	Frenar = { Angle = 160, Ring = 2, Size = 64 },
	FrenoMano = { Angle = 105, Ring = 2, Size = 50 },
}

-- Centro del botón de saltar de Roblox (desde la esquina de abajo a la derecha) y su radio
local function jump(): (Vector2, number)
	local view = workspace.CurrentCamera.ViewportSize
	local small = math.min(view.X, view.Y) <= 500
	if small then
		return Vector2.new(60, 55), 35
	end
	return Vector2.new(110, 150), 60
end

function TouchLayout.slot(name: string): { Position: UDim2, Size: number }
	local def = SLOTS[name] or SLOTS.Extra
	local center, radius = jump()
	local ring = radius + 14 + def.Size / 2 + (def.Ring - 1) * 64
	local a = math.rad(def.Angle)
	local x = center.X - math.cos(a) * ring
	local y = center.Y + math.sin(a) * ring
	-- (x, y) = centro del botón medido desde abajo a la derecha
	return { Position = UDim2.new(1, -x, 1, -y), Size = def.Size }
end

-- Altura (px desde abajo) hasta donde llegan los botones que se ven a pie
function TouchLayout.top(): number
	local _, radius = jump()
	local center = jump()
	local top = center.Y + radius
	for _, name in { "Golpear", "Defender", "Correr", "Piedra", "Linterna", "Foto" } do
		local def = SLOTS[name]
		local ring = radius + 14 + def.Size / 2 + (def.Ring - 1) * 64
		top = math.max(top, center.Y + math.sin(math.rad(def.Angle)) * ring + def.Size / 2)
	end
	return top
end

-- Coloca un botón (GuiObject o el de ContextActionService) en su hueco y lo mantiene al girar
function TouchLayout.place(button: GuiObject, name: string)
	local function apply()
		local slot = TouchLayout.slot(name)
		button.AnchorPoint = Vector2.new(0.5, 0.5)
		button.Position = slot.Position
		button.Size = UDim2.fromOffset(slot.Size, slot.Size)
	end
	apply()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(apply)
end

-- Para los botones de ContextActionService (SetPosition usa la esquina de arriba a la izquierda)
function TouchLayout.placeAction(ContextActionService: ContextActionService, action: string, name: string)
	local slot = TouchLayout.slot(name)
	local half = slot.Size / 2
	ContextActionService:SetPosition(action, slot.Position - UDim2.fromOffset(half, half))
	local button = ContextActionService:GetButton(action)
	if button then
		button.Size = UDim2.fromOffset(slot.Size, slot.Size)
	end
end

-- Botón redondo propio en su hueco (en lugar de los de ContextActionService, que Roblox crea con
-- su propio tamaño y se montaban encima de los demás). Empieza escondido: quien lo usa pone Visible.
local buttonsGui: ScreenGui? = nil
function TouchLayout.button(name: string, icon: string, callback: () -> ()): TextButton
	if not buttonsGui then
		local gui = Instance.new("ScreenGui")
		gui.Name = "TouchButtons"
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 3
		gui.Parent = player:WaitForChild("PlayerGui")
		buttonsGui = gui
	end
	local button = Instance.new("TextButton")
	button.Name = name .. "Button"
	button.Text = icon
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.new(1, 1, 1)
	button.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
	button.BackgroundTransparency = 0.3
	button.AutoButtonColor = true
	button.Visible = false
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = button
	local padding = Instance.new("UIPadding")
	for _, side in { "PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight" } do
		(padding :: any)[side] = UDim.new(0.2, 0)
	end
	padding.Parent = button
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = Color3.fromRGB(120, 170, 255)
	stroke.Transparency = 0.4
	stroke.Thickness = 2
	stroke.Parent = button
	button.Activated:Connect(callback)
	TouchLayout.place(button, name)
	button.Parent = buttonsGui
	return button
end

-- ¿Va montado en un vehículo? (a pie se ven unos botones y conduciendo, otros, en los mismos huecos)
function TouchLayout.riding(): boolean
	return player:GetAttribute("Riding") ~= nil
end

-- ¿Va dentro de un vehículo, conduciendo o de pasajero? (entonces fuera los botones de ir a pie)
function TouchLayout.aboard(): boolean
	return player:GetAttribute("Riding") ~= nil or player:GetAttribute("Passenger") ~= nil
end

-- Muestra el botón solo a pie (When = "Pie") o solo conduciendo ("Vehiculo"), y además si extra() lo permite
function TouchLayout.showWhen(button: GuiObject, when: "Pie" | "Vehiculo", extra: (() -> boolean)?)
	local function update()
		local ok = if when == "Vehiculo" then TouchLayout.riding() else not TouchLayout.aboard()
		button.Visible = ok and (extra == nil or extra())
	end
	player:GetAttributeChangedSignal("Riding"):Connect(update)
	player:GetAttributeChangedSignal("Passenger"):Connect(update)
	update()
	return update
end

return TouchLayout
