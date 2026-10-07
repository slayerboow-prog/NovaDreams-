-- VehicleHud (cliente): el cuadro de mandos cuando conduces, como el de un coche de verdad.
--   * Va abajo en el centro, justo ENCIMA de la barra rápida del inventario (UI/HudLayout:
--     Items.Dash), pequeño: no tapa la calle. En el móvil cabe entre las flechas de girar (izquierda)
--     y los pedales, luces e intermitentes (derecha); nada se pisa (scripts/test-hud.luau)
--   * Izquierda: velocímetro de aguja (0 → velocidad máxima del vehículo) con los km/h en números
--   * Centro: testigos (intermitentes ⬅ ➡ que parpadean, luces cortas / largas, freno de mano) que
--     se encienden como en el salpicadero, la palanca P R N D con la marcha de ahora iluminada
--     (D adelante, R marcha atrás, N parado, P freno de mano echado), el nombre del vehículo (o el
--     aviso de reserva) y el cuentakilómetros total y parcial
--   * Derecha: el indicador de combustible (⛽ gasolina o 🔋 batería) de aguja, de E a F, con luz de
--     reserva. Sin motor (bici, monopatín…), «sin motor»
-- Los datos de combustible y kilómetros los pone el servidor (VehicleService) en atributos del
-- jugador: Fuel (0..1), FuelType, Odometer, Trip, OutOfFuel. La velocidad la da Driving.luau.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Theme = require(script.Parent.Parent.UI.Theme)
local HudLayout = require(script.Parent.Parent.UI.HudLayout)
local SceneGuis = require(script.Parent.Parent.UI.SceneGuis)

local VehicleHud = {}

local player = Players.LocalPlayer
local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

-- Colores del cuadro
local FACE = rgb(10, 13, 20)
local RING = rgb(80, 120, 200)
local TICK = rgb(225, 230, 240)
local DIM = rgb(70, 78, 94)
local LIT = rgb(245, 247, 250)
local RED = rgb(240, 70, 70)

local gui: ScreenGui
local panel: Frame
local ticks: Frame
local needle: Frame
local speedText: TextLabel
local gears: { [string]: TextLabel } = {}
local nameText: TextLabel
local fuelDial: Frame
local fuelNeedle: Frame
local fuelIcon: TextLabel
local fuelText: TextLabel
local noEngine: TextLabel
local warning: TextLabel
local odoText: TextLabel
local maxSpeed = 72
local blink = 0
local telltales: Frame
local tell: { [string]: TextLabel } = {}
local parked = false
local shownGear = ""

local ARC = 240 -- grados de la esfera del velocímetro
local FUEL_ARC = 120 -- grados del indicador de combustible (de E a F)
local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Medidas (en unidades del lienzo del HUD: HudLayout.Sizes.Dash)
local SPEEDO = 128 -- diámetro del velocímetro
local FUEL = 100 -- diámetro del indicador de combustible

local function angleFor(speed: number): number
	return -ARC / 2 + ARC * math.clamp(speed / maxSpeed, 0, 1)
end

local function fuelAngle(fuel: number): number
	return -FUEL_ARC / 2 + FUEL_ARC * math.clamp(fuel, 0, 1)
end

-- Una esfera redonda con su aro
local function face(size: number, props: { [string]: any }): Frame
	local defaults = {
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = FACE,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
	}
	for k, v in props do
		defaults[k] = v
	end
	local frame = create("Frame", defaults)
	create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = frame })
	create("UIStroke", { Color = RING, Thickness = 2, Parent = frame })
	return frame
end

-- Aguja: un marco cuadrado que gira entero sobre el centro de la esfera, con la aguja hacia arriba
local function makeNeedle(parent: Frame, length: number, width: number, color: Color3): Frame
	local pivot = create("Frame", {
		Name = "Needle",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(length * 2, length * 2),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = parent,
	})
	local bar = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromOffset(width, length),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = pivot,
	})
	create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = bar })
	local cap = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = rgb(40, 44, 54), BorderSizePixel = 0, ZIndex = 4, Parent = parent })
	create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = cap })
	return pivot
end

-- Una raya de la esfera (en el ángulo `angle`, de r0 a r1 del centro)
local function tickAt(parent: Instance, angle: number, r0: number, r1: number, width: number, color: Color3)
	local a = math.rad(angle - 90)
	local mid = (r0 + r1) / 2
	create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, math.cos(a) * mid, 0.5, math.sin(a) * mid),
		Size = UDim2.fromOffset(width, r1 - r0),
		Rotation = angle,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = parent,
	})
end

-- Marcas y números del velocímetro (se rehacen al cambiar de vehículo)
local function buildTicks()
	for _, child in ticks:GetChildren() do
		child:Destroy()
	end
	local step = if maxSpeed > 60 then 20 elseif maxSpeed > 30 then 10 else 5
	local top = math.ceil(maxSpeed / step) * step
	maxSpeed = top
	local radius = SPEEDO / 2 - 4
	for v = 0, top, step / 2 do
		local major = v % step == 0
		tickAt(ticks, angleFor(v), if major then radius - 10 else radius - 5, radius, if major then 3 else 2, if v >= top * 0.85 then RED else TICK)
		if major then
			local a = math.rad(angleFor(v) - 90)
			create("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, math.cos(a) * (radius - 20), 0.5, math.sin(a) * (radius - 20)),
				Size = UDim2.fromOffset(26, 12),
				BackgroundTransparency = 1,
				Text = tostring(v),
				TextColor3 = rgb(200, 208, 222),
				Font = Enum.Font.GothamBold,
				TextSize = 10,
				Parent = ticks,
			})
		end
	end
end

-- Dónde va: encima de la barra rápida (HudLayout.Items.Dash), a la escala del HUD
local scaler: UIScale
local function place(layout: HudLayout.Layout)
	local r = HudLayout.rect(layout.Items.Dash, layout.Canvas)
	local design = HudLayout.Sizes.Dash
	-- (el cuadro se dibuja siempre con sus medidas de diseño y se escala hasta su hueco: en el móvil,
	-- algo más grande, HudLayout.DashTouch)
	scaler.Scale = layout.Scale * r.W / design.X
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.fromOffset(math.floor((r.X + r.W / 2) * layout.Scale + 0.5), math.floor((r.Y + r.H) * layout.Scale + 0.5))
	panel.Size = UDim2.fromOffset(design.X, design.Y)
end

function VehicleHud.init(parent: Instance)
	gui = create("ScreenGui", { Name = "VehicleHud", ResetOnSpawn = false, Enabled = false, IgnoreGuiInset = true, DisplayOrder = 2, Parent = parent })
	local size = HudLayout.Sizes.Dash
	panel = Theme.hudPanel({
		Name = "Dashboard",
		AnchorPoint = Vector2.new(0.5, 1),
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundColor3 = rgb(16, 20, 30),
		BackgroundTransparency = if TOUCH then 0.3 else 0.2,
		CornerRadius = 30,
		Parent = gui,
	})
	scaler = create("UIScale", { Parent = panel })
	HudLayout.onChanged(place)

	-- Izquierda: velocímetro
	local dial = face(SPEEDO, { Name = "Speedometer", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0), Parent = panel })
	ticks = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = dial })
	needle = makeNeedle(dial, SPEEDO / 2 - 12, 3, rgb(255, 80, 60))
	speedText = create("TextLabel", {
		Name = "Speed",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.6, 0),
		Size = UDim2.fromOffset(76, 30),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextSize = 30,
		TextColor3 = LIT,
		Text = "0",
		ZIndex = 5,
		Parent = dial,
	})
	create("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.6, 28), Size = UDim2.fromOffset(50, 13), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.Muted, Text = "km/h", ZIndex = 5, Parent = dial })

	-- Centro: testigos, marcha P R N D, nombre (o aviso) y kilómetros
	local center = create("Frame", { Name = "Center", Position = UDim2.fromOffset(SPEEDO + 14, 6), Size = UDim2.new(1, -(SPEEDO + FUEL + 34), 1, -12), BackgroundTransparency = 1, Parent = panel })
	telltales = create("Frame", { Name = "Telltales", Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Parent = center })
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = telltales })
	for i, def in { { "Left", "⬅️" }, { "Lights", "💡" }, { "Park", "🅿️" }, { "Right", "➡️" } } do
		local label = create("TextLabel", {
			Name = def[1],
			Size = UDim2.fromOffset(40, 24),
			BackgroundColor3 = FACE,
			BackgroundTransparency = 0.2,
			Font = Theme.FontBold,
			TextScaled = true,
			Text = def[2],
			TextColor3 = Color3.new(1, 1, 1),
			TextTransparency = 0.75, -- (apagado: se ve tenue, como en el salpicadero)
			LayoutOrder = i,
			Parent = telltales,
		})
		create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = label })
		tell[def[1]] = label
	end
	local gearRow = create("Frame", { Name = "Gears", Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, Parent = center })
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = gearRow })
	for i, g in { "P", "R", "N", "D" } do
		local label = create("TextLabel", {
			Name = g,
			Size = UDim2.fromOffset(44, 46),
			BackgroundColor3 = FACE,
			BackgroundTransparency = 0.1,
			Font = Enum.Font.GothamBlack,
			TextSize = 34,
			Text = g,
			TextColor3 = DIM,
			LayoutOrder = i,
			Parent = gearRow,
		})
		create("UICorner", { CornerRadius = UDim.new(0, 9), Parent = label })
		gears[g] = label
	end
	nameText = Theme.label({ Name = "Vehicle", Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 0, 16), Font = Theme.FontBold, TextSize = 13, TextColor3 = C.Muted, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, Text = "", Parent = center })
	warning = Theme.label({ Name = "Warning", Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 0, 16), Font = Theme.FontBold, TextSize = 13, TextColor3 = rgb(255, 170, 40), TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, Text = "", Visible = false, Parent = center })
	odoText = Theme.label({ Name = "Odometer", Position = UDim2.fromOffset(0, 98), Size = UDim2.new(1, 0, 0, 16), Font = Enum.Font.Code, TextSize = 13, TextColor3 = rgb(200, 210, 225), TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, Text = "", Parent = center })

	-- Derecha: combustible (E → F)
	fuelDial = face(FUEL, { Name = "Fuel", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Parent = panel })
	local fuelTicks = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = fuelDial })
	for i = 0, 4 do
		local f = i / 4
		tickAt(fuelTicks, fuelAngle(f), FUEL / 2 - 12, FUEL / 2 - 4, if i % 2 == 0 then 3 else 2, if i == 0 then RED else TICK)
	end
	for _, def in { { "E", 0, RED }, { "F", 1, TICK } } do
		local a = math.rad(fuelAngle(def[2] :: number) - 90)
		create("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, math.cos(a) * (FUEL / 2 - 22), 0.5, math.sin(a) * (FUEL / 2 - 22)), Size = UDim2.fromOffset(14, 12), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 11, TextColor3 = def[3], Text = def[1], Parent = fuelTicks })
	end
	fuelNeedle = makeNeedle(fuelDial, FUEL / 2 - 10, 3, rgb(255, 150, 50))
	fuelIcon = create("TextLabel", { Name = "Icon", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.56, 0), Size = UDim2.fromOffset(30, 18), BackgroundTransparency = 1, Font = Theme.FontBold, TextScaled = true, Text = "⛽", ZIndex = 5, Parent = fuelDial })
	fuelText = create("TextLabel", { Name = "Percent", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.56, 18), Size = UDim2.fromOffset(50, 14), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = LIT, Text = "", ZIndex = 5, Parent = fuelDial })
	noEngine = Theme.label({ Name = "NoEngine", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(FUEL, 40), Font = Theme.FontBold, TextSize = 13, TextWrapped = true, TextColor3 = C.Muted, TextXAlignment = Enum.TextXAlignment.Center, Text = "Sin motor:\nno gasta nada", Visible = false, Parent = panel })

	if not TOUCH then
		-- (en el móvil se conduce con las flechas y los pedales en pantalla: no hacen falta las teclas)
		Theme.label({
			Name = "Keys",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 0, -4),
			Size = UDim2.new(1, 120, 0, 14),
			Text = "W/S pedales · A/D girar · Espacio freno de mano · L luces · Q/E intermitentes · X emergencia · H claxon · F bajarse",
			TextSize = 11,
			TextColor3 = C.Muted,
			TextStrokeTransparency = 0.6,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = panel,
		})
	end
end

-- Los testigos (desde Driving, cada fotograma): Left / Right = el intermitente luce ahora;
-- Lights = 0, 1, 2; Parked = freno de mano echado (P en la marcha); Handbrake = tirando de él
local function lamp(label: TextLabel, on: boolean, color: Color3)
	label.TextTransparency = if on then 0 else 0.75
	label.BackgroundColor3 = if on then color else FACE
end
function VehicleHud.setStatus(status: { Left: boolean, Right: boolean, Lights: number, Parked: boolean, Handbrake: boolean })
	if not telltales then
		return
	end
	parked = status.Parked
	lamp(tell.Left, status.Left, rgb(30, 130, 60))
	lamp(tell.Right, status.Right, rgb(30, 130, 60))
	lamp(tell.Lights, status.Lights > 0, if status.Lights == 2 then rgb(40, 90, 200) else rgb(40, 110, 70))
	lamp(tell.Park, status.Parked or status.Handbrake, rgb(170, 40, 40))
end

function VehicleHud.show(kind: string)
	local vehicle = Gameplay.Vehicles[kind]
	maxSpeed = if vehicle then vehicle.Speed else 60
	nameText.Text = if vehicle then vehicle.Icon .. " " .. vehicle.Name else kind
	buildTicks()
	shownGear = ""
	SceneGuis.setEnabled(gui, true) -- (en plena escena se queda apagada hasta el final)
end

function VehicleHud.hide()
	SceneGuis.setEnabled(gui, false) -- (y la escena ya no la enciende al acabar)
	VehicleHud.setStatus({ Left = false, Right = false, Lights = 0, Parked = false, Handbrake = false })
end

-- Marcha que se ve: R marcha atrás, D en marcha, P con el freno de mano echado y N parado
function VehicleHud.gearFor(speed: number, isParked: boolean): string
	if speed < -0.5 then
		return "R"
	elseif math.abs(speed) < 0.5 then
		return if isParked then "P" else "N"
	end
	return "D"
end

local GEAR_COLOR = { P = rgb(170, 40, 40), R = rgb(200, 120, 20), N = rgb(70, 80, 100), D = rgb(30, 130, 60) }

-- Cada fotograma (desde Driving.luau): speed en studs/s (negativa = marcha atrás)
function VehicleHud.update(speed: number, dt: number)
	if not gui.Enabled then
		return
	end
	local kmh = math.abs(speed) -- (1 stud ≈ 28 cm: studs/s ≈ km/h)
	needle.Rotation = angleFor(kmh)
	speedText.Text = tostring(math.floor(kmh + 0.5))
	local gear = VehicleHud.gearFor(speed, parked)
	if gear ~= shownGear then
		shownGear = gear
		for g, label in gears do
			label.TextColor3 = if g == gear then LIT else DIM
			label.BackgroundColor3 = if g == gear then GEAR_COLOR[g] else FACE
		end
	end

	local fuel = player:GetAttribute("Fuel")
	if typeof(fuel) == "number" then
		fuelDial.Visible = true
		noEngine.Visible = false
		local battery = player:GetAttribute("FuelType") == "Bateria"
		fuelIcon.Text = if battery then "🔋" else "⛽"
		fuelNeedle.Rotation = fuelAngle(fuel)
		fuelText.Text = ("%d%%"):format(math.floor(fuel * 100 + 0.5))
		fuelText.TextColor3 = if fuel <= Gameplay.Fuel.Reserve then RED elseif fuel < 0.4 then rgb(250, 200, 50) else LIT
		blink += dt
		if player:GetAttribute("OutOfFuel") then
			warning.Text = if battery then "⚠ SIN BATERÍA" else "⚠ SIN GASOLINA"
			warning.TextColor3 = rgb(255, 80, 80)
			warning.Visible = blink % 1 < 0.6
		elseif fuel <= Gameplay.Fuel.Reserve then
			warning.Text = "⚠ RESERVA · ve a una gasolinera"
			warning.TextColor3 = rgb(255, 170, 40)
			warning.Visible = blink % 1.2 < 0.8
		else
			warning.Visible = false
		end
		nameText.Visible = not warning.Visible
		odoText.Text = ("%08.1f km · parcial %.2f"):format(player:GetAttribute("Odometer") or 0, player:GetAttribute("Trip") or 0)
	else
		-- Bici, monopatín, autobús de la línea…: sin depósito
		fuelDial.Visible = false
		noEngine.Visible = true
		warning.Visible = false
		nameText.Visible = true
		odoText.Text = ""
	end
end

return VehicleHud
