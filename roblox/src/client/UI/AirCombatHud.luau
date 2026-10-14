-- AirCombatHud: el panel de la nave del combate aéreo (Controllers/AirCombatClient), con el estilo del HUD.
--
--   Arriba en el centro (el sitio de los instrumentos del avión, HudLayout.Items.Flight: no pisa nada):
--     radar redondo (enemigos como puntos; el fijado, más grande) · VEL · TURBO · ESCUDO · CASCO ·
--     MISILES y puntos. Debajo, la línea del OBJETIVO y los avisos (límite, lento, recalentado).
--   Encima de todo (pantalla entera): la mira, el recuadro de fijación (se cierra al fijar y se pone
--   rojo), flechas en el borde hacia los enemigos que no se ven, la marca de impacto (✕) y un destello
--   en el borde al recibir (azul si para el escudo, rojo si da en el casco).
-- Lo que se puede calcular sin pantalla (textos, el punto del radar, las flechas) es puro y lo prueba
-- scripts/test-aircombat.luau.

local HudLayout = require(script.Parent.HudLayout)
local Theme = require(script.Parent.Theme)

local AirCombatHud = {}

local create = Theme.create
local C = Theme.Colors
local H = Theme.Hud
local rgb = Color3.fromRGB

AirCombatHud.Keys = "Ratón apuntar · W/S motor · A/D girar · Q/E alabeo · Clic fuego · F misil · Shift turbo · Ctrl freno · X salir"
AirCombatHud.RadarRange = 1400
AirCombatHud.Arrows = 8

local WARN_TEXT = { Limite = "⚠ LÍMITE: la nave vuelve sola", Lento = "⚠ MUY LENTO: acelera", Calor = "⚠ CAÑONES RECALENTADOS" }

export type Info = {
	Speed: number,
	Boost: number,
	BoostReady: boolean,
	Shield: number,
	MaxShield: number,
	Hull: number,
	MaxHull: number,
	Missiles: number,
	MaxMissiles: number,
	Overheated: boolean,
	Wave: number,
	Score: number,
	Objective: string,
	Warn: string?,
	Mode: string,
}

export type View = {
	Gui: ScreenGui,
	Panel: Frame,
	Values: { [string]: TextLabel },
	Bars: { [string]: Frame },
	Objective: TextLabel,
	Warning: TextLabel,
	Radar: Frame,
	Blips: { Frame },
	Overlay: ScreenGui,
	Cross: Frame,
	LockBox: Frame,
	LockStroke: UIStroke,
	Arrows: { TextLabel },
	HitMark: TextLabel,
	Flash: Frame,
}

local function bar(parent: Instance, name: string, color: Color3, y: number): Frame
	local track = create("Frame", { Name = name .. "Track", Position = UDim2.new(0, 8, 0, y), Size = UDim2.new(1, -16, 0, 8), BackgroundColor3 = rgb(14, 18, 28), BorderSizePixel = 0, Parent = parent })
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
	local fill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BorderSizePixel = 0, Parent = track })
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
	return fill
end

function AirCombatHud.new(parent: Instance, touch: boolean): View
	local gui = create("ScreenGui", { Name = "AirCombatHud", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 3, Enabled = false, Parent = parent })
	HudLayout.scaleGui(gui)
	local size = HudLayout.Sizes.Flight
	local panel = Theme.hudPanel({ Name = "AirPanel", Size = UDim2.fromOffset(size.X, size.Y), Parent = gui })
	HudLayout.onChanged(function(layout)
		HudLayout.apply(panel, layout.Items.Flight)
	end)
	-- Radar (a la izquierda del panel)
	local radar = create("Frame", { Name = "Radar", Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(62, 62), BackgroundColor3 = rgb(10, 24, 30), BackgroundTransparency = 0.15, BorderSizePixel = 0, ClipsDescendants = false, Parent = panel })
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = radar })
	create("UIStroke", { Color = H.Glow, Thickness = 1.5, Transparency = 0.2, Parent = radar })
	create("Frame", { Name = "Me", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = rgb(120, 220, 255), BorderSizePixel = 0, Parent = radar }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	local blips = {}
	for i = 1, 14 do
		local b = create("Frame", { Name = "Blip" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = rgb(255, 80, 70), BorderSizePixel = 0, Visible = false, Parent = radar })
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = b })
		table.insert(blips, b)
	end
	-- Cajas: VEL, TURBO, ESCUDO, CASCO, MISILES
	local values, bars = {}, {}
	local boxes = { { "Speed", "VEL" }, { "Boost", "TURBO" }, { "Shield", "ESCUDO" }, { "Hull", "CASCO" }, { "Missiles", "MISILES" } }
	local x0 = 78
	local w = (size.X - x0 - 10 - 4 * 6) / #boxes
	for i, def in boxes do
		local box = create("Frame", { Name = def[1], Position = UDim2.fromOffset(x0 + (i - 1) * (w + 6), 6), Size = UDim2.fromOffset(w, 56), BackgroundColor3 = H.Track, BackgroundTransparency = 0.25, BorderSizePixel = 0, Parent = panel })
		create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = box })
		Theme.label({ Name = "Caption", Position = UDim2.fromOffset(8, 2), Size = UDim2.new(1, -16, 0, 14), Text = def[2], TextSize = 12, Font = Theme.FontBold, TextColor3 = H.Glow, Parent = box })
		values[def[1]] = Theme.label({ Name = "Value", Position = UDim2.fromOffset(8, 16), Size = UDim2.new(1, -16, 0, 24), Text = "0", TextSize = 22, Font = Theme.FontBold, Parent = box })
		if def[1] == "Boost" then
			bars.Boost = bar(box, "Boost", rgb(90, 190, 255), 42)
		elseif def[1] == "Shield" then
			bars.Shield = bar(box, "Shield", rgb(80, 220, 255), 42)
		elseif def[1] == "Hull" then
			bars.Hull = bar(box, "Hull", rgb(80, 230, 120), 42)
		end
	end
	local objective = Theme.label({ Name = "Objective", Position = UDim2.fromOffset(x0, 64), Size = UDim2.new(0.62, -x0, 0, 16), Text = "", TextSize = 14, Font = Theme.FontBold, Parent = panel })
	local warning = Theme.label({ Name = "Warning", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 64), Size = UDim2.new(0.38, 0, 0, 16), Text = "", TextSize = 14, Font = Theme.FontBold, TextColor3 = rgb(255, 90, 80), TextXAlignment = Enum.TextXAlignment.Right, Parent = panel })
	if not touch then
		Theme.label({ Name = "Keys", Position = UDim2.fromOffset(12, 80), Size = UDim2.new(1, -24, 0, 13), Text = AirCombatHud.Keys, TextSize = 11, TextColor3 = C.Muted, TextXAlignment = Enum.TextXAlignment.Center, Parent = panel })
	end
	-- Encima de todo, en píxeles de la pantalla (lo coloca cada fotograma el controlador)
	local overlay = create("ScreenGui", { Name = "AirCombatOverlay", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 2, Enabled = false, Parent = parent })
	local cross = create("Frame", { Name = "Cross", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(34, 34), BackgroundTransparency = 1, Parent = overlay })
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = cross })
	create("UIStroke", { Color = rgb(150, 240, 255), Thickness = 2, Transparency = 0.15, Parent = cross })
	create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(4, 4), BackgroundColor3 = rgb(150, 240, 255), BorderSizePixel = 0, Parent = cross })
	local lockBox = create("Frame", { Name = "Lock", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(70, 70), BackgroundTransparency = 1, Visible = false, Parent = overlay })
	local lockStroke = create("UIStroke", { Color = rgb(255, 200, 60), Thickness = 3, Parent = lockBox })
	Theme.label({ Name = "Tag", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 4), Size = UDim2.fromOffset(120, 18), Text = "FIJANDO", TextSize = 14, Font = Theme.FontBold, TextColor3 = rgb(255, 200, 60), TextXAlignment = Enum.TextXAlignment.Center, Parent = lockBox })
	local arrows = {}
	for i = 1, AirCombatHud.Arrows do
		table.insert(arrows, Theme.label({ Name = "Arrow" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(34, 34), Text = "▲", TextSize = 30, Font = Theme.FontBold, TextColor3 = rgb(255, 90, 70), TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.4, Visible = false, Parent = overlay }))
	end
	local hit = Theme.label({ Name = "HitMark", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(44, 44), Text = "✕", TextSize = 40, Font = Theme.FontBold, TextColor3 = rgb(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = 1, TextStrokeTransparency = 1, Parent = overlay })
	local flash = create("Frame", { Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = overlay })
	local flashStroke = create("UIStroke", { Name = "Edge", Color = rgb(80, 200, 255), Thickness = 24, Transparency = 1, Parent = flash })
	flashStroke:SetAttribute("Edge", true)
	return {
		Gui = gui,
		Panel = panel,
		Values = values,
		Bars = bars,
		Objective = objective,
		Warning = warning,
		Radar = radar,
		Blips = blips,
		Overlay = overlay,
		Cross = cross,
		LockBox = lockBox,
		LockStroke = lockStroke,
		Arrows = arrows,
		HitMark = hit,
		Flash = flash,
	}
end

function AirCombatHud.setEnabled(view: View, on: boolean)
	view.Gui.Enabled = on
	view.Overlay.Enabled = on
end

-- Textos del panel (puro)
function AirCombatHud.texts(info: Info): { [string]: string }
	local warn = info.Warn
	if info.Overheated then
		warn = "Calor"
	end
	return {
		Speed = tostring(math.floor(info.Speed + 0.5)),
		Boost = if info.BoostReady then ("%d%%"):format(math.floor(info.Boost * 100 + 0.5)) else "ENFRIANDO",
		Shield = tostring(math.max(0, math.floor(info.Shield + 0.5))),
		Hull = tostring(math.max(0, math.floor(info.Hull + 0.5))),
		Missiles = ("%d/%d"):format(info.Missiles, info.MaxMissiles),
		Objective = (if info.Mode == "Space" then "🌌 " else "⛰ ") .. info.Objective .. (if info.Score > 0 then ("  ·  %d pts"):format(info.Score) else ""),
		Warning = if warn then WARN_TEXT[warn] or "" else "",
	}
end

function AirCombatHud.set(view: View, info: Info)
	local t = AirCombatHud.texts(info)
	for _, k in { "Speed", "Boost", "Shield", "Hull", "Missiles" } do
		view.Values[k].Text = t[k]
	end
	view.Objective.Text = t.Objective
	view.Warning.Text = t.Warning
	view.Bars.Boost.Size = UDim2.fromScale(math.clamp(info.Boost, 0, 1), 1)
	view.Bars.Boost.BackgroundColor3 = if info.BoostReady then rgb(90, 190, 255) else rgb(120, 120, 140)
	local shield = if info.MaxShield > 0 then info.Shield / info.MaxShield else 0
	local hull = if info.MaxHull > 0 then info.Hull / info.MaxHull else 0
	view.Bars.Shield.Size = UDim2.fromScale(math.clamp(shield, 0, 1), 1)
	view.Bars.Hull.Size = UDim2.fromScale(math.clamp(hull, 0, 1), 1)
	view.Bars.Hull.BackgroundColor3 = rgb(255, 70, 60):Lerp(rgb(80, 230, 120), math.clamp(hull, 0, 1))
end

-- Punto del radar de un enemigo en `pos` visto desde la nave (puro): x a la derecha, y hacia delante
-- (arriba en el radar), en -1..1; lo que pasa del alcance se queda en el borde.
function AirCombatHud.radarPoint(ship: CFrame, pos: Vector3, range: number?): Vector2
	local r = range or AirCombatHud.RadarRange
	local rel = ship:PointToObjectSpace(pos)
	local v = Vector2.new(rel.X, rel.Z) / r -- (Z de la nave: + hacia atrás = abajo en el radar)
	if v.Magnitude > 1 then
		v = v.Unit
	end
	return v
end

export type Blip = { Point: Vector2, Locked: boolean?, Kind: string? }
function AirCombatHud.blips(view: View, list: { Blip })
	for i, frame in view.Blips do
		local b = list[i]
		frame.Visible = b ~= nil
		if b then
			frame.Position = UDim2.fromScale(0.5 + b.Point.X * 0.46, 0.5 + b.Point.Y * 0.46)
			local big = b.Locked == true
			frame.Size = if big then UDim2.fromOffset(10, 10) elseif b.Kind == "Torreta" then UDim2.fromOffset(7, 7) else UDim2.fromOffset(6, 6)
			frame.BackgroundColor3 = if big then rgb(255, 210, 60) elseif b.Kind == "Caza" then rgb(255, 150, 60) else rgb(255, 80, 70)
		end
	end
end

-- Flecha del borde hacia un enemigo que no se ve (puro). screen = punto en la pantalla (como
-- WorldToViewportPoint), behind = está detrás de la cámara. Devuelve la posición (dentro del margen) y
-- el giro de la flecha en grados (0 = ▲ hacia arriba).
function AirCombatHud.edgeArrow(screen: Vector2, viewport: Vector2, behind: boolean, margin: number?): (Vector2, number)
	local m = margin or 48
	local center = viewport / 2
	local d = screen - center
	if behind then
		d = -d
		if d.Magnitude < 1 then
			d = Vector2.new(0, 1)
		end
	end
	if d.Magnitude < 1e-3 then
		d = Vector2.new(0, -1)
	end
	local half = center - Vector2.new(m, m)
	local scale = math.min(if math.abs(d.X) > 1e-6 then half.X / math.abs(d.X) else math.huge, if math.abs(d.Y) > 1e-6 then half.Y / math.abs(d.Y) else math.huge)
	local p = center + d * scale
	local angle = math.deg(math.atan2(d.X, -d.Y))
	return p, angle
end

-- ¿Está este punto de la pantalla dentro (con margen)?
function AirCombatHud.onScreen(screen: Vector2, viewport: Vector2, behind: boolean, margin: number?): boolean
	local m = margin or 20
	return not behind and screen.X >= m and screen.Y >= m and screen.X <= viewport.X - m and screen.Y <= viewport.Y - m
end

return AirCombatHud
