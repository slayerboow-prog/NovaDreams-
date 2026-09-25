-- VehicleHud (cliente): el cuadro de mandos cuando conduces.
--   * Velocímetro de aguja (0 → velocidad máxima del vehículo) con la velocidad en números
--   * Marcha: D (adelante), R (marcha atrás) o N (parado)
--   * Combustible (⛽ gasolina) o batería (🔋 patinete) que baja según conduces, con luz de reserva
--   * Cuentakilómetros total del vehículo y parcial del viaje
-- Los datos de combustible y kilómetros los pone el servidor (VehicleService) en atributos del
-- jugador: Fuel (0..1), FuelType, Odometer, Trip, OutOfFuel. La velocidad la da Driving.luau.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Theme = require(script.Parent.Parent.UI.Theme)

local VehicleHud = {}

local player = Players.LocalPlayer
local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

local gui: ScreenGui
local dial: Frame
local needle: Frame
local ticks: Frame
local speedText: TextLabel
local gearText: TextLabel
local nameText: TextLabel
local fuelBox: Frame
local fuelFill: Frame
local fuelIcon: TextLabel
local fuelText: TextLabel
local warning: TextLabel
local odoText: TextLabel
local tripText: TextLabel
local maxSpeed = 72
local blink = 0

local ARC = 240 -- grados de la esfera

local function angleFor(speed: number): number
	return -ARC / 2 + ARC * math.clamp(speed / maxSpeed, 0, 1)
end

-- Marcas y números de la esfera (se rehacen al cambiar de vehículo)
local function buildTicks()
	for _, child in ticks:GetChildren() do
		child:Destroy()
	end
	local step = if maxSpeed > 60 then 20 elseif maxSpeed > 30 then 10 else 5
	local top = math.ceil(maxSpeed / step) * step
	maxSpeed = top
	local radius = 62
	for v = 0, top, step / 2 do
		local major = v % step == 0
		local a = math.rad(angleFor(v) - 90)
		local r0 = if major then radius - 11 else radius - 6
		local mid = (r0 + radius) / 2
		create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, math.cos(a) * mid, 0.5, math.sin(a) * mid),
			Size = UDim2.fromOffset(if major then 3 else 2, radius - r0),
			Rotation = angleFor(v),
			BackgroundColor3 = if v >= top * 0.85 then rgb(240, 70, 70) else rgb(235, 238, 245),
			BorderSizePixel = 0,
			Parent = ticks,
		})
		if major then
			create("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, math.cos(a) * (radius - 22), 0.5, math.sin(a) * (radius - 22)),
				Size = UDim2.fromOffset(28, 14),
				BackgroundTransparency = 1,
				Text = tostring(v),
				TextColor3 = rgb(210, 216, 228),
				Font = Enum.Font.GothamBold,
				TextSize = 11,
				Parent = ticks,
			})
		end
	end
end

function VehicleHud.init(parent: Instance)
	gui = create("ScreenGui", { Name = "VehicleHud", ResetOnSpawn = false, Enabled = false, Parent = parent })
	local panel = Theme.panel({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -92),
		Size = UDim2.fromOffset(470, 168),
		Parent = gui,
	})
	Theme.padding(10).Parent = panel

	-- Velocímetro
	dial = create("Frame", {
		Size = UDim2.fromOffset(146, 146),
		BackgroundColor3 = rgb(14, 18, 28),
		BorderSizePixel = 0,
		Parent = panel,
	})
	create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = dial })
	create("UIStroke", { Color = rgb(90, 140, 230), Thickness = 2, Parent = dial })
	ticks = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = dial })
	needle = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(4, 54),
		BackgroundColor3 = rgb(255, 80, 60),
		BorderSizePixel = 0,
		Parent = dial,
	})
	create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = needle })
	-- (la aguja gira sobre su punto de abajo: se coloca con un marco que gira entero)
	local cap = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = rgb(40, 44, 54), BorderSizePixel = 0, Parent = dial })
	create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = cap })
	speedText = create("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.62, 0),
		Size = UDim2.fromOffset(90, 26),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextSize = 24,
		TextColor3 = rgb(245, 247, 250),
		Text = "0",
		Parent = dial,
	})
	create("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.8, 0), Size = UDim2.fromOffset(60, 14), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.Muted, Text = "km/h", Parent = dial })

	-- Centro: vehículo y marcha
	nameText = Theme.label({ Position = UDim2.fromOffset(158, 0), Size = UDim2.fromOffset(120, 22), Font = Theme.FontBold, TextSize = 15, Text = "", Parent = panel })
	gearText = Theme.label({
		Position = UDim2.fromOffset(158, 24),
		Size = UDim2.fromOffset(56, 56),
		Font = Enum.Font.GothamBlack,
		TextSize = 40,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "N",
		BackgroundTransparency = 0,
		BackgroundColor3 = rgb(14, 18, 28),
		Parent = panel,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = gearText })
	Theme.label({ Position = UDim2.fromOffset(220, 30), Size = UDim2.fromOffset(70, 44), Text = "D adelante\nR atrás", TextSize = 11, TextColor3 = C.Muted, Parent = panel })

	-- Derecha: combustible
	fuelBox = create("Frame", { Position = UDim2.fromOffset(296, 0), Size = UDim2.fromOffset(150, 80), BackgroundTransparency = 1, Parent = panel })
	fuelIcon = Theme.label({ Size = UDim2.fromOffset(150, 20), Font = Theme.FontBold, TextSize = 14, Text = "⛽ Gasolina", Parent = fuelBox })
	local bar = create("Frame", { Position = UDim2.fromOffset(0, 24), Size = UDim2.fromOffset(150, 18), BackgroundColor3 = rgb(14, 18, 28), BorderSizePixel = 0, Parent = fuelBox })
	create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = bar })
	create("UIStroke", { Color = rgb(70, 80, 100), Parent = bar })
	fuelFill = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(80, 210, 110), BorderSizePixel = 0, Parent = bar })
	create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = fuelFill })
	for i = 1, 3 do
		create("Frame", { Position = UDim2.new(i / 4, 0, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = rgb(14, 18, 28), BorderSizePixel = 0, ZIndex = 3, Parent = bar })
	end
	Theme.label({ Position = UDim2.fromOffset(0, 44), Size = UDim2.fromOffset(20, 14), Text = "E", TextSize = 11, TextColor3 = rgb(240, 90, 90), Parent = fuelBox })
	Theme.label({ Position = UDim2.fromOffset(136, 44), Size = UDim2.fromOffset(20, 14), Text = "F", TextSize = 11, TextColor3 = C.Muted, Parent = fuelBox })
	fuelText = Theme.label({ Position = UDim2.fromOffset(20, 44), Size = UDim2.fromOffset(110, 14), Text = "", TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center, Parent = fuelBox })
	warning = Theme.label({ Position = UDim2.fromOffset(0, 60), Size = UDim2.fromOffset(150, 18), Text = "", Font = Theme.FontBold, TextSize = 13, TextColor3 = rgb(255, 170, 40), Parent = fuelBox })

	-- Abajo: cuentakilómetros y ayuda
	odoText = Theme.label({ Position = UDim2.fromOffset(158, 86), Size = UDim2.fromOffset(290, 20), Font = Enum.Font.Code, TextSize = 15, Text = "", Parent = panel })
	tripText = Theme.label({ Position = UDim2.fromOffset(158, 106), Size = UDim2.fromOffset(290, 18), Font = Enum.Font.Code, TextSize = 13, TextColor3 = C.Muted, Text = "", Parent = panel })
	Theme.label({ Position = UDim2.fromOffset(158, 128), Size = UDim2.fromOffset(290, 16), Text = "W/S acelerar y frenar · A/D girar · H claxon · F bajarse", TextSize = 11, TextColor3 = C.Muted, Parent = panel })
end

function VehicleHud.show(kind: string)
	local vehicle = Gameplay.Vehicles[kind]
	maxSpeed = if vehicle then vehicle.Speed else 60
	nameText.Text = if vehicle then vehicle.Icon .. " " .. vehicle.Name else kind
	buildTicks()
	gui.Enabled = true
end

function VehicleHud.hide()
	gui.Enabled = false
end

-- Cada fotograma (desde Driving.luau): speed en studs/s (negativa = marcha atrás)
function VehicleHud.update(speed: number, dt: number)
	if not gui.Enabled then
		return
	end
	local kmh = math.abs(speed) -- (1 stud ≈ 28 cm: studs/s ≈ km/h)
	needle.Rotation = angleFor(kmh)
	-- La aguja sale del centro: se desplaza con la rotación para girar sobre su base
	local a = math.rad(angleFor(kmh) - 90)
	needle.Position = UDim2.new(0.5, math.cos(a) * 27, 0.5, math.sin(a) * 27 + 27)
	speedText.Text = tostring(math.floor(kmh + 0.5))
	gearText.Text = if speed < -0.5 then "R" elseif math.abs(speed) < 0.5 then "N" else "D"
	gearText.TextColor3 = if speed < -0.5 then rgb(255, 170, 40) else rgb(245, 247, 250)

	local fuel = player:GetAttribute("Fuel")
	if typeof(fuel) == "number" then
		fuelBox.Visible = true
		local battery = player:GetAttribute("FuelType") == "Bateria"
		fuelIcon.Text = if battery then "🔋 Batería" else "⛽ Gasolina"
		fuelFill.Size = UDim2.fromScale(math.clamp(fuel, 0, 1), 1)
		fuelFill.BackgroundColor3 = if fuel <= Gameplay.Fuel.Reserve then rgb(240, 70, 70) elseif fuel < 0.4 then rgb(250, 200, 50) else rgb(80, 210, 110)
		fuelText.Text = ("%d%%"):format(math.floor(fuel * 100 + 0.5))
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
		odoText.Text = ("🧭 %09.1f km"):format(player:GetAttribute("Odometer") or 0)
		tripText.Text = ("Parcial: %.2f km"):format(player:GetAttribute("Trip") or 0)
	else
		-- Bici, monopatín, autobús de la línea…: sin depósito
		fuelBox.Visible = false
		odoText.Text = "🚲 Sin motor: no gasta nada"
		tripText.Text = ""
	end
end

return VehicleHud
