-- FlightHud: los instrumentos del avión cuando lo pilotas (Controllers/Flying), arriba en el centro
-- (UI/HudLayout.Items.Flight: debajo del reloj, del GPS y de las estrellas; no pisa nada).
--
--   VEL (km/h y nudos) · ALT (metros) · RUMBO (grados y punto cardinal) · V/S (metros por segundo,
--   ▲ subiendo / ▼ bajando) · MOTOR (barra y %)
--   Debajo: tren, flaps, frenos y daños; a la derecha los avisos en rojo (⚠ PÉRDIDA, límite del mapa,
--   techo de vuelo). En el ordenador, una línea con las teclas.

local HudLayout = require(script.Parent.HudLayout)
local Theme = require(script.Parent.Theme)

local FlightHud = {}

export type Info = {
	Speed: number, -- km/h (studs/s)
	Altitude: number, -- metros
	Heading: number, -- grados
	Compass: string,
	Climb: number, -- m/s
	Throttle: number, -- 0..1
	Gear: boolean,
	FixedGear: boolean,
	Flaps: number,
	Brake: boolean,
	Health: number,
	Warn: string?, -- "Perdida" | "Limite" | "Techo"
	OnGround: boolean,
}

local create = Theme.create
local C = Theme.Colors
local H = Theme.Hud
local rgb = Color3.fromRGB

local WARN_TEXT = { Perdida = "⚠ PÉRDIDA: baja el morro", Limite = "⚠ LÍMITE DEL MAPA", Techo = "⚠ TECHO DE VUELO" }
FlightHud.Keys = "W/S morro · A/D alas · Q/E timón · Shift/Ctrl motor · B frenos · G tren · F flaps · C cámara"

export type View = { Gui: ScreenGui, Panel: Frame, Values: { [string]: TextLabel }, Units: { [string]: TextLabel }, Bar: Frame, Status: TextLabel, Warning: TextLabel }

function FlightHud.new(parent: Instance, touch: boolean): View
	local gui = create("ScreenGui", { Name = "FlightHud", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 2, Enabled = false, Parent = parent })
	HudLayout.scaleGui(gui)
	local size = HudLayout.Sizes.Flight
	local panel = Theme.hudPanel({ Name = "FlightPanel", Size = UDim2.fromOffset(size.X, size.Y), Parent = gui })
	HudLayout.onChanged(function(layout)
		HudLayout.apply(panel, layout.Items.Flight)
	end)
	local values, units = {}, {}
	local boxes = { { "Speed", "VEL" }, { "Alt", "ALT" }, { "Hdg", "RUMBO" }, { "Vs", "V/S" }, { "Thr", "MOTOR" } }
	local w = (size.X - 20 - 4 * 8) / #boxes
	local bar: Frame? = nil
	for i, def in boxes do
		local box = create("Frame", {
			Name = def[1],
			Position = UDim2.fromOffset(10 + (i - 1) * (w + 8), 6),
			Size = UDim2.fromOffset(w, 56),
			BackgroundColor3 = H.Track,
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
			Parent = panel,
		})
		create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = box })
		Theme.label({ Name = "Caption", Position = UDim2.fromOffset(8, 2), Size = UDim2.new(1, -16, 0, 14), Text = def[2], TextSize = 12, Font = Theme.FontBold, TextColor3 = H.Glow, Parent = box })
		values[def[1]] = Theme.label({ Name = "Value", Position = UDim2.fromOffset(8, 16), Size = UDim2.new(1, -16, 0, 24), Text = "0", TextSize = 22, Font = Theme.FontBold, Parent = box })
		units[def[1]] = Theme.label({ Name = "Unit", Position = UDim2.fromOffset(8, 40), Size = UDim2.new(1, -16, 0, 13), Text = "", TextSize = 11, TextColor3 = C.Muted, Parent = box })
		if def[1] == "Thr" then
			local track = create("Frame", { Name = "Track", Position = UDim2.new(0, 8, 0, 42), Size = UDim2.new(1, -16, 0, 8), BackgroundColor3 = rgb(14, 18, 28), BorderSizePixel = 0, Parent = box })
			create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
			bar = create("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = rgb(70, 220, 120), BorderSizePixel = 0, Parent = track })
			create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })
			units[def[1]].Visible = false
		end
	end
	local status = Theme.label({ Name = "Status", Position = UDim2.fromOffset(12, 64), Size = UDim2.new(0.55, -12, 0, 16), Text = "", TextSize = 13, Font = Theme.FontBold, Parent = panel })
	local warning = Theme.label({ Name = "Warning", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 64), Size = UDim2.new(0.45, 0, 0, 16), Text = "", TextSize = 14, Font = Theme.FontBold, TextColor3 = rgb(255, 90, 80), TextXAlignment = Enum.TextXAlignment.Right, Parent = panel })
	if not touch then
		Theme.label({ Name = "Keys", Position = UDim2.fromOffset(12, 80), Size = UDim2.new(1, -24, 0, 13), Text = FlightHud.Keys, TextSize = 11, TextColor3 = C.Muted, TextXAlignment = Enum.TextXAlignment.Center, Parent = panel })
	end
	return { Gui = gui, Panel = panel, Values = values, Units = units, Bar = bar :: Frame, Status = status, Warning = warning }
end

-- Texto de cada instrumento (puro: lo prueba scripts/test-hud.luau)
function FlightHud.texts(info: Info): { [string]: string }
	local climb = info.Climb
	local arrow = if climb > 0.3 then "▲" elseif climb < -0.3 then "▼" else "="
	local parts = {}
	if not info.FixedGear then
		table.insert(parts, if info.Gear then "TREN ABAJO" else "TREN ARRIBA")
	end
	table.insert(parts, ("FLAPS %d"):format(info.Flaps))
	if info.Brake then
		table.insert(parts, "FRENOS")
	end
	if info.Health < 100 then
		table.insert(parts, ("DAÑOS %d%%"):format(100 - math.floor(info.Health)))
	end
	return {
		Speed = tostring(math.floor(info.Speed + 0.5)),
		SpeedUnit = ("km/h · %d kt"):format(math.floor(info.Speed / 1.852 + 0.5)),
		Alt = tostring(math.floor(info.Altitude + 0.5)),
		AltUnit = "m",
		Hdg = ("%03d°"):format(info.Heading % 360),
		HdgUnit = info.Compass,
		Vs = ("%s %.1f"):format(arrow, math.abs(climb)),
		VsUnit = "m/s",
		Thr = ("%d%%"):format(math.floor(info.Throttle * 100 + 0.5)),
		Status = table.concat(parts, " · "),
		Warning = if info.Warn then WARN_TEXT[info.Warn] or "" else "",
	}
end

function FlightHud.set(view: View, info: Info)
	local t = FlightHud.texts(info)
	view.Values.Speed.Text = t.Speed
	view.Units.Speed.Text = t.SpeedUnit
	view.Values.Alt.Text = t.Alt
	view.Units.Alt.Text = t.AltUnit
	view.Values.Hdg.Text = t.Hdg
	view.Units.Hdg.Text = t.HdgUnit
	view.Values.Vs.Text = t.Vs
	view.Units.Vs.Text = t.VsUnit
	view.Values.Thr.Text = t.Thr
	view.Bar.Size = UDim2.fromScale(math.clamp(info.Throttle, 0, 1), 1)
	view.Status.Text = t.Status
	view.Warning.Text = t.Warning
	-- (la pérdida parpadea)
	view.Warning.Visible = info.Warn ~= "Perdida" or (os.clock() % 0.8) < 0.5
end

return FlightHud
