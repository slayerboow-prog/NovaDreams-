-- AirCombatHud: el HUD de la nave (combate aéreo y espacio; Controllers/AirCombatClient). Espacio AAA:
-- por zonas como la imagen de referencia (docs/espacio-aaa/referencia-hud.png), colocadas por
-- UI/ShipHudLayout sin pisarse en 1920x1080, 932x430, 844x390 y 640x360:
--
--   A arriba izq.   PERFIL: foto del avatar, nombre, nivel, dinero y ✨ Chispas
--   B arriba centro NAVEGACIÓN: brújula que gira con la nave, «Sistema Valmar», zona, destino (distancia)
--                   y estado del salto cuántico
--   C bajo B        NAVE: velocidad (y modo), IMPULSO (naranja), ENERGÍA, ESCUDO, CASCO, MISILES y ARMA
--                   (calor); J debajo: avisos solo cuando hacen falta
--   D arriba der.   RADAR: delante = arriba, cada cosa con su icono y color, solo dentro del alcance
--   E bajo D        MISIONES: principal (historia), secundarias (tablón) y eventos, con distancia
--   G abajo izq.    (ordenador) tarjeta de teclas; con mando, sus botones; en el móvil la palanca
--                   (UI/FlightStick, aparte)
--   H abajo centro  BARRA DE 8 RANURAS (shared/AirCombat/ShipAbilities): icono, tecla, cantidad, recarga,
--                   estado y selección; las bloqueadas dicen «Próximamente» (se tocan en el móvil)
--   Prompt          encima de H: el letrero de la hipervelocidad o el salto en marcha
--   Quantum         el selector del salto cuántico (lista de destinos)
--   F (encima de todo, en píxeles): la mira (pequeña: no tapa al enemigo), el recuadro de fijación con
--     nombre, distancia y amenaza, flechas en el borde, la marca de impacto y el destello al recibir.
-- Colores: paneles azul oscuro semitransparentes con filo cian, impulso naranja, hostil rojo.
-- Ritmo: el controlador llama a set/setNav/radar… a 10 por segundo y a la brújula a 30; aquí solo se
-- cambia una propiedad si cambia su valor.
-- Lo puro (textos, radar, flechas) lo prueban scripts/test-aircombat.luau y scripts/test-espacio-aaa.luau.

local HudLayout = require(script.Parent.HudLayout)
local Theme = require(script.Parent.Theme)
local ShipHudLayout = require(script.Parent.ShipHudLayout)
local ShipAbilities = require(game:GetService("ReplicatedStorage").Shared.AirCombat.ShipAbilities)

local AirCombatHud = {}

local create = Theme.create
local rgb = Color3.fromRGB

AirCombatHud.Keys = "Ratón apuntar · W/S motor · A/D lateral · Q/E alabeo · Clic fuego · 2 misil · Shift impulso · Ctrl freno · C esquiva · B salir"
AirCombatHud.RadarRange = 1400
AirCombatHud.Arrows = 8
AirCombatHud.MaxBlips = 24

AirCombatHud.Colors = {
	Panel = rgb(6, 16, 34),
	Edge = rgb(70, 200, 255),
	Cyan = rgb(110, 230, 255),
	White = rgb(235, 248, 255),
	Muted = rgb(140, 175, 205),
	Boost = rgb(255, 150, 40),
	Hostile = rgb(255, 70, 70),
	Energy = rgb(120, 240, 255),
	Shield = rgb(80, 170, 255),
	Hull = rgb(90, 235, 140),
	Gold = rgb(255, 205, 70),
	Locked = rgb(110, 120, 140),
	Violet = rgb(200, 130, 255),
}
local K = AirCombatHud.Colors

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
	Energy: number?,
	MaxEnergy: number?,
	Weapon: string?, -- "Cannons" | "Laser"
	Heat: number?,
	FlightMode: string?, -- "Combat" | "Cruise"
	Assist: boolean?,
	Boosting: boolean?,
	Alert: string?,
	Flares: number?,
	MaxFlares: number?,
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
	Zones: { [string]: Frame },
	Profile: { [string]: any },
	Nav: { [string]: any },
	Missions: { { [string]: any } },
	Slots: { { [string]: any } },
	Prompt: { [string]: any },
	Quantum: { [string]: any },
	Hints: Frame?,
	RadarLabel: TextLabel,
	RadarNorth: Frame,
	Chips: { [string]: TextLabel },
	LockInfo: TextLabel,
	Touch: boolean,
	OnSlot: ((string) -> ())?,
	Cache: { [Instance]: { [string]: any } },
}

---------------------------------------------------------------------
-- Ayudantes
---------------------------------------------------------------------
-- Cambia una propiedad solo si cambia (el HUD se actualiza mucho: no tocar lo que no cambia)
local function put(view: View, obj: Instance, prop: string, value: any)
	local c = view.Cache[obj]
	if not c then
		c = {}
		view.Cache[obj] = c
	end
	if c[prop] ~= value then
		c[prop] = value
		;(obj :: any)[prop] = value
	end
end

-- (pcall: fuera de Roblox, en las pruebas con Lune, los botones no tienen eventos)
local function onActivated(button: GuiButton, fn: () -> ()): RBXScriptConnection?
	local ok, conn = pcall(function()
		return button.Activated:Connect(fn)
	end)
	return if ok then conn else nil
end

local function panel(name: string, parent: Instance, transparency: number?): Frame
	local f = create("Frame", { Name = name, BackgroundColor3 = K.Panel, BackgroundTransparency = transparency or 0.28, BorderSizePixel = 0, Parent = parent })
	create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = f })
	create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(40, 90, 150), rgb(6, 14, 30)), Parent = f })
	create("UIStroke", { Name = "Edge", Color = K.Edge, Thickness = 1.6, Transparency = 0.25, Parent = f })
	-- (esquinas brillantes, como la referencia)
	for _, c in { { 0, 0 }, { 1, 1 } } do
		create("Frame", { Name = "Esquina", AnchorPoint = Vector2.new(c[1], c[2]), Position = UDim2.fromScale(c[1], c[2]), Size = UDim2.fromOffset(22, 3), BackgroundColor3 = K.Cyan, BorderSizePixel = 0, Parent = f })
	end
	return f
end

local function label(props: { [string]: any }): TextLabel
	local defaults = { Font = Theme.FontBold, TextColor3 = K.White, TextSize = 16, TextStrokeTransparency = 0.6, TextStrokeColor3 = rgb(0, 10, 20) }
	for k, v in props do
		defaults[k] = v
	end
	return Theme.label(defaults)
end

local function bar(parent: Instance, name: string, color: Color3, pos: UDim2, size: UDim2): Frame
	local track = create("Frame", { Name = name .. "Track", Position = pos, Size = size, BackgroundColor3 = rgb(10, 20, 36), BackgroundTransparency = 0.1, BorderSizePixel = 0, Parent = parent })
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
	create("UIStroke", { Color = color, Thickness = 1, Transparency = 0.6, Parent = track })
	local fill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BorderSizePixel = 0, Parent = track })
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
	create("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(190, 200, 210)), Parent = fill })
	return fill
end

local function ring(parent: Instance, size: UDim2, color: Color3, thick: number, transparency: number?): Frame
	local f = create("Frame", { Name = "Aro", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = size, BackgroundTransparency = 1, Parent = parent })
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = f })
	create("UIStroke", { Color = color, Thickness = thick, Transparency = transparency or 0, Parent = f })
	return f
end

local function line(parent: Instance, pos: UDim2, size: UDim2, rot: number, color: Color3): Frame
	return create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = size, Rotation = rot, BackgroundColor3 = color, BorderSizePixel = 0, Parent = parent })
end

-- Iconos de línea de las ranuras, dibujados con marcos (no dependen de imágenes ni de la fuente)
function AirCombatHud.glyph(parent: Instance, kind: string, color: Color3): Frame
	local g = create("Frame", { Name = "Glifo", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.56, 0.56), BackgroundTransparency = 1, Parent = parent })
	g:SetAttribute("Glyph", kind)
	local c = UDim2.fromScale(0.5, 0.5)
	if kind == "Canon" then
		for _, y in { 0.32, 0.68 } do
			line(g, UDim2.fromScale(0.45, y), UDim2.new(0.8, 0, 0, 4), 0, color)
			line(g, UDim2.fromScale(0.88, y), UDim2.fromOffset(7, 7), 45, color)
		end
	elseif kind == "Misil" then
		line(g, c, UDim2.new(0.85, 0, 0, 5), -45, color)
		line(g, UDim2.fromScale(0.8, 0.2), UDim2.fromOffset(12, 12), 45, color)
		line(g, UDim2.fromScale(0.22, 0.78), UDim2.new(0.3, 0, 0, 3), 45, K.Boost):SetAttribute("Accent", true)
	elseif kind == "Laser" then
		line(g, c, UDim2.new(1, 0, 0, 2), -45, color)
		ring(g, UDim2.fromScale(0.4, 0.4), color, 2).Position = UDim2.fromScale(0.78, 0.22)
	elseif kind == "Escudo" then
		local f = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = c, Size = UDim2.fromScale(0.7, 0.85), BackgroundTransparency = 1, Parent = g })
		create("UICorner", { CornerRadius = UDim.new(0.45, 0), Parent = f })
		create("UIStroke", { Color = color, Thickness = 3, Parent = f })
	elseif kind == "Camuflaje" then
		for i = 0, 5 do
			local a = i / 6 * math.pi * 2
			create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5 + math.cos(a) * 0.38, 0.5 + math.sin(a) * 0.38), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = color, BorderSizePixel = 0, Parent = g }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		end
	elseif kind == "Salto" then
		ring(g, UDim2.fromScale(0.95, 0.95), color, 2.5)
		ring(g, UDim2.fromScale(0.55, 0.55), color, 2, 0.2)
		create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = c, Size = UDim2.fromOffset(6, 6), BackgroundColor3 = color, BorderSizePixel = 0, Parent = g }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	elseif kind == "Hiper" then
		for i, x in { 0.2, 0.5, 0.8 } do
			for _, d in { { 0.35, 40 }, { 0.65, -40 } } do
				local f = line(g, UDim2.fromScale(x, d[1]), UDim2.new(0.34, 0, 0, 4), d[2], if i == 3 then K.Boost else color)
				if i == 3 then
					f:SetAttribute("Accent", true)
				end
			end
		end
	elseif kind == "Dron" then
		create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = c, Size = UDim2.fromScale(0.32, 0.32), BackgroundTransparency = 1, Parent = g }, { create("UIStroke", { Color = color, Thickness = 2.5 }) })
		for _, d in { { 0.15, 0.15 }, { 0.85, 0.15 }, { 0.15, 0.85 }, { 0.85, 0.85 } } do
			ring(g, UDim2.fromScale(0.26, 0.26), color, 2).Position = UDim2.fromScale(d[1], d[2])
		end
	end
	return g
end

---------------------------------------------------------------------
-- Construir
---------------------------------------------------------------------
local function buildProfile(view: View, parent: Frame)
	local p = view.Profile
	local avatar = create("ImageLabel", { Name = "Avatar", Position = UDim2.fromOffset(10, 10), Size = UDim2.new(0, 0, 1, -20), BackgroundColor3 = rgb(10, 30, 60), Image = "", ScaleType = Enum.ScaleType.Crop, Parent = parent })
	create("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height, Parent = avatar })
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = avatar })
	create("UIStroke", { Color = K.Cyan, Thickness = 2.5, Parent = avatar })
	p.Avatar = avatar
	local x = if view.Touch then 100 else 112
	p.Level = label({ Name = "Nivel", Position = UDim2.fromOffset(x, 8), Size = UDim2.fromOffset(84, 26), Text = "Nv. 1", TextSize = 20, TextColor3 = K.Cyan, Parent = parent })
	p.Name = label({ Name = "Nombre", Position = UDim2.fromOffset(x + 86, 8), Size = UDim2.new(1, -(x + 96), 0, 26), Text = "", TextSize = 20, TextTruncate = Enum.TextTruncate.AtEnd, Parent = parent })
	p.Money = label({ Name = "Dinero", Position = UDim2.fromOffset(x, 40), Size = UDim2.new(0.5, -x / 2, 0, 24), Text = "$0", TextSize = 19, TextColor3 = rgb(120, 240, 140), Parent = parent })
	p.Chispas = label({ Name = "Chispas", Position = UDim2.new(0.5, x / 2, 0, 40), Size = UDim2.new(0.5, -x / 2 - 10, 0, 24), Text = "✨ 0", TextSize = 19, TextColor3 = K.Gold, Parent = parent })
	p.Ship = label({ Name = "Nave", Position = UDim2.fromOffset(x, 68), Size = UDim2.new(1, -(x + 10), 0, 20), Text = "CAZA · MODO COMBATE", TextSize = 14, TextColor3 = K.Muted, Parent = parent })
end

local function buildNav(view: View, parent: Frame)
	local n = view.Nav
	local strip = create("Frame", { Name = "Brujula", Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -20, 0, 34), BackgroundTransparency = 1, ClipsDescendants = true, Parent = parent })
	create("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0), NumberSequenceKeypoint.new(0.85, 0), NumberSequenceKeypoint.new(1, 1) }), Parent = strip })
	line(strip, UDim2.new(0.5, 0, 1, -2), UDim2.new(1, 0, 0, 1), 0, K.Edge)
	n.Strip = strip
	n.Marks = {}
	for i = 1, 12 do
		local m = label({ Name = "Marca" .. i, AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(40, 30), Text = "", TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center, Visible = false, Parent = strip })
		local tick = create("Frame", { Name = "Raya", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.fromOffset(2, 8), BackgroundColor3 = K.Cyan, BorderSizePixel = 0, Parent = m })
		n.Marks[i] = { Label = m, Tick = tick }
	end
	-- Marca del destino (rombo) y el centro (tu rumbo)
	local target = create("Frame", { Name = "Destino", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 14), Rotation = 45, BackgroundColor3 = K.Gold, BorderSizePixel = 0, Visible = false, Parent = strip })
	n.Target = target
	line(parent, UDim2.new(0.5, 0, 0, 40), UDim2.fromOffset(3, 12), 0, K.White)
	n.Heading = label({ Name = "Rumbo", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 40), Size = UDim2.fromOffset(60, 14), Text = "000°", TextSize = 12, TextColor3 = K.Muted, TextXAlignment = Enum.TextXAlignment.Center, Visible = false, Parent = parent })
	n.System = label({ Name = "Sistema", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 44), Size = UDim2.new(1, -20, 0, 26), Text = "◆ Sistema Valmar", TextSize = 22, TextColor3 = K.Cyan, TextXAlignment = Enum.TextXAlignment.Center, Parent = parent })
	n.Zone = label({ Name = "Zona", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 70), Size = UDim2.new(0.54, 0, 0, 22), Text = "", TextSize = 16, TextColor3 = K.White, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, Parent = parent })
	n.Quantum = label({ Name = "Salto", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 70), Size = UDim2.new(0.22, -10, 0, 22), Text = "", TextSize = 13, TextColor3 = K.Violet, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = parent })
	n.Dest = label({ Name = "Destino", Position = UDim2.new(0, 10, 0, 70), Size = UDim2.new(0.22, -10, 0, 22), Text = "", TextSize = 13, TextColor3 = K.Gold, TextTruncate = Enum.TextTruncate.AtEnd, Parent = parent })
end

local function buildStatus(view: View, parent: Frame)
	local values, bars = view.Values, view.Bars
	local W = parent.Size.X.Offset
	local touch = view.Touch
	-- Velocidad grande a la izquierda
	values.Speed = label({ Name = "Velocidad", Position = UDim2.fromOffset(12, 4), Size = UDim2.fromOffset(110, 40), Text = "0", TextSize = 36, TextXAlignment = Enum.TextXAlignment.Center, Parent = parent })
	label({ Name = "KmH", Position = UDim2.fromOffset(12, 42), Size = UDim2.fromOffset(110, 16), Text = "KM/H", TextSize = 13, TextColor3 = K.Muted, TextXAlignment = Enum.TextXAlignment.Center, Parent = parent })
	view.Chips.Mode = label({ Name = "Modo", Position = UDim2.fromOffset(12, 58), Size = UDim2.fromOffset(110, 18), Text = "COMBATE", TextSize = 13, TextColor3 = K.Cyan, TextXAlignment = Enum.TextXAlignment.Center, Parent = parent })
	-- Barras en dos columnas
	local x0 = 132
	local colW = math.floor((W - x0 - (if touch then 128 else 148) - 10) / 2)
	local rows = { { "Boost", "IMPULSO", K.Boost }, { "Energy", "ENERGÍA", K.Energy }, { "Shield", "ESCUDO", K.Shield }, { "Hull", "CASCO", K.Hull } }
	for i, def in rows do
		local col = (i - 1) // 2
		local row = (i - 1) % 2
		local x = x0 + col * (colW + 10)
		local y = 6 + row * 38
		label({ Name = def[1] .. "Caption", Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(colW - 50, 16), Text = def[2], TextSize = 13, TextColor3 = def[3], Parent = parent })
		values[def[1]] = label({ Name = def[1], AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromOffset(x + colW, y), Size = UDim2.fromOffset(80, 16), Text = "", TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right, Parent = parent })
		bars[def[1]] = bar(parent, def[1], def[3], UDim2.fromOffset(x, y + 19), UDim2.fromOffset(colW, 9))
	end
	-- Misiles y arma a la derecha
	local rx = W - (if touch then 108 else 124)
	label({ Name = "MisilesCaption", Position = UDim2.fromOffset(rx, 6), Size = UDim2.fromOffset(120, 16), Text = "MISILES", TextSize = 13, TextColor3 = K.Boost, Parent = parent })
	values.Missiles = label({ Name = "Misiles", Position = UDim2.fromOffset(rx, 22), Size = UDim2.fromOffset(120, 20), Text = "6/6", TextSize = 18, Parent = parent })
	values.Flares = label({ Name = "Bengalas", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromOffset(W - 8, 22), Size = UDim2.fromOffset(56, 20), Text = "", TextSize = 14, TextColor3 = rgb(255, 210, 140), TextXAlignment = Enum.TextXAlignment.Right, Parent = parent })
	values.Weapon = label({ Name = "Arma", Position = UDim2.fromOffset(rx, 44), Size = UDim2.fromOffset(120, 16), Text = "CAÑONES", TextSize = 13, TextColor3 = K.Cyan, Parent = parent })
	bars.Heat = bar(parent, "Heat", K.Hostile, UDim2.fromOffset(rx, 64), UDim2.fromOffset(if touch then 96 else 116, 7))
	view.Panel = parent
end

local function buildMissions(view: View, parent: Frame)
	local rows = view.Missions
	local h = parent.Size.Y.Offset
	local n = if view.Touch then 3 else 4
	local rowH = math.floor((h - 8) / n)
	for i = 1, n do
		local row = create("Frame", { Name = "Fila" .. i, Position = UDim2.fromOffset(0, 4 + (i - 1) * rowH), Size = UDim2.new(1, 0, 0, rowH), BackgroundTransparency = 1, Visible = false, Parent = parent })
		local dot = create("Frame", { Name = "Marca", Position = UDim2.fromOffset(12, 8), Size = UDim2.fromOffset(10, 10), Rotation = 45, BackgroundColor3 = K.Gold, BorderSizePixel = 0, Parent = row })
		local kind = label({ Name = "Tipo", Position = UDim2.fromOffset(30, 2), Size = UDim2.new(1, -40, 0, 18), Text = "", TextSize = 13, TextColor3 = K.Gold, Parent = row })
		local title = label({ Name = "Titulo", Position = UDim2.fromOffset(30, 19), Size = UDim2.new(1, -110, 0, 20), Text = "", TextSize = 16, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row })
		local right = label({ Name = "Dato", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 19), Size = UDim2.fromOffset(78, 20), Text = "", TextSize = 14, TextColor3 = K.Muted, TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
		local step = label({ Name = "Paso", Position = UDim2.fromOffset(30, 38), Size = UDim2.new(1, -40, 0, 16), Text = "", TextSize = 13, TextColor3 = K.Muted, TextTruncate = Enum.TextTruncate.AtEnd, Visible = rowH >= 54, Parent = row })
		rows[i] = { Row = row, Dot = dot, Kind = kind, Title = title, Right = right, Step = step }
	end
end

local function buildSlots(view: View, parent: Frame, slot: number, gap: number)
	for i = 1, 8 do
		local b = create("TextButton", { Name = "Ranura" .. i, Position = UDim2.fromOffset(8 + (i - 1) * (slot + gap), 6), Size = UDim2.fromOffset(slot, slot), BackgroundColor3 = rgb(8, 22, 44), BackgroundTransparency = 0.15, AutoButtonColor = false, Text = "", Parent = parent })
		create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = b })
		local stroke = create("UIStroke", { Name = "Edge", Color = K.Edge, Thickness = 1.5, Transparency = 0.3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = b })
		local cool = create("Frame", { Name = "Recarga", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0), BackgroundColor3 = rgb(0, 0, 0), BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 3, Parent = b })
		create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = cool })
		local key = label({ Name = "Tecla", Position = UDim2.fromOffset(6, 3), Size = UDim2.fromOffset(20, 16), Text = tostring(i), TextSize = 14, TextColor3 = K.Muted, ZIndex = 4, Parent = b })
		local count = label({ Name = "Cantidad", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 3), Size = UDim2.fromOffset(40, 16), Text = "", TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 4, Parent = b })
		local lock = label({ Name = "Candado", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.6, 0.4), Text = "🔒", TextScaled = true, ZIndex = 5, Visible = false, Parent = b })
		local name = label({ Name = "Nombre", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 2), Size = UDim2.new(1, 8, 0, 16), Text = "", TextSize = 12, TextColor3 = K.White, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, Parent = b })
		local idx = i
		onActivated(b, function()
			local s = view.Slots[idx]
			if s and s.Id and view.OnSlot then
				view.OnSlot(s.Id)
			end
		end)
		view.Slots[i] = { Button = b, Stroke = stroke, Cool = cool, Key = key, Count = count, Lock = lock, Name = name, Glyph = nil, Id = nil, Kind = nil }
	end
end

function AirCombatHud.new(parent: Instance, touch: boolean): View
	local gui = create("ScreenGui", { Name = "AirCombatHud", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 3, Enabled = false, Parent = parent })
	HudLayout.scaleGui(gui)
	local view: View = {
		Gui = gui,
		Panel = nil :: any,
		Values = {},
		Bars = {},
		Objective = nil :: any,
		Warning = nil :: any,
		Radar = nil :: any,
		Blips = {},
		Overlay = nil :: any,
		Cross = nil :: any,
		LockBox = nil :: any,
		LockStroke = nil :: any,
		Arrows = {},
		HitMark = nil :: any,
		Flash = nil :: any,
		Zones = {},
		Profile = {},
		Nav = {},
		Missions = {},
		Slots = {},
		Prompt = {},
		Quantum = {},
		Hints = nil,
		RadarLabel = nil :: any,
		RadarNorth = nil :: any,
		Chips = {},
		LockInfo = nil :: any,
		Touch = touch,
		OnSlot = nil,
		Cache = setmetatable({}, { __mode = "k" }) :: any,
	}
	local S = if touch then ShipHudLayout.Sizes.Touch else ShipHudLayout.Sizes.Pc
	local function zone(name: string, size: Vector2, transparency: number?): Frame
		local f = panel("Zona" .. name, gui, transparency)
		f.Size = UDim2.fromOffset(size.X, size.Y)
		view.Zones[name] = f
		return f
	end
	buildProfile(view, zone("A", S.A))
	buildNav(view, zone("B", S.B, 0.4))
	buildStatus(view, zone("C", S.C))
	-- J: avisos (solo cuando hacen falta)
	local alerts = create("Frame", { Name = "ZonaJ", Size = UDim2.fromOffset(S.J.X, S.J.Y), BackgroundTransparency = 1, Parent = gui })
	view.Zones.J = alerts
	view.Warning = label({ Name = "Aviso", Size = UDim2.fromScale(1, 1), Text = "", TextSize = 18, TextColor3 = K.Hostile, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3, Parent = alerts })
	-- D: radar
	local radar = create("Frame", { Name = "ZonaD", Size = UDim2.fromOffset(S.D, S.D), BackgroundColor3 = rgb(6, 20, 34), BackgroundTransparency = 0.25, BorderSizePixel = 0, Parent = gui })
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = radar })
	create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(20, 70, 100), rgb(4, 12, 24)), Parent = radar })
	create("UIStroke", { Color = K.Edge, Thickness = 3, Transparency = 0.1, Parent = radar })
	view.Zones.D = radar
	for _, k in { 0.66, 0.33 } do
		ring(radar, UDim2.fromScale(k, k), K.Cyan, 1.2, 0.6)
	end
	line(radar, UDim2.fromScale(0.5, 0.5), UDim2.new(0.92, 0, 0, 1), 0, K.Cyan).BackgroundTransparency = 0.7
	line(radar, UDim2.fromScale(0.5, 0.5), UDim2.new(0, 1, 0.92, 0), 0, K.Cyan).BackgroundTransparency = 0.7
	-- (el cono de delante, la nave en el centro y la N que gira con tu rumbo)
	line(radar, UDim2.fromScale(0.36, 0.3), UDim2.new(0, 1, 0.42, 0), -34, K.Cyan).BackgroundTransparency = 0.55
	line(radar, UDim2.fromScale(0.64, 0.3), UDim2.new(0, 1, 0.42, 0), 34, K.Cyan).BackgroundTransparency = 0.55
	local me = create("Frame", { Name = "Me", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, Parent = radar })
	line(me, UDim2.fromScale(0.3, 0.55), UDim2.fromOffset(3, 16), 25, K.White)
	line(me, UDim2.fromScale(0.7, 0.55), UDim2.fromOffset(3, 16), -25, K.White)
	view.RadarNorth = label({ Name = "Norte", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.06), Size = UDim2.fromOffset(22, 22), Text = "N", TextSize = 18, TextColor3 = K.White, TextXAlignment = Enum.TextXAlignment.Center, Parent = radar }) :: any
	view.RadarLabel = label({ Name = "Alcance", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.fromOffset(120, 16), Text = "RADAR 1,4 km", TextSize = 12, TextColor3 = K.Cyan, TextXAlignment = Enum.TextXAlignment.Center, Parent = radar })
	view.Radar = radar
	for i = 1, AirCombatHud.MaxBlips do
		local b = create("Frame", { Name = "Blip" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundColor3 = K.Hostile, BorderSizePixel = 0, Visible = false, ZIndex = 3, Parent = radar })
		create("UICorner", { Name = "Round", CornerRadius = UDim.new(1, 0), Parent = b })
		create("UIStroke", { Name = "Ring", Color = K.Hostile, Thickness = 2, Enabled = false, Parent = b })
		table.insert(view.Blips, b)
	end
	-- E: misiones
	local missions = zone("E", S.E)
	buildMissions(view, missions)
	view.Objective = label({ Name = "Objetivo", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -4), Size = UDim2.new(1, -24, 0, 16), Text = "", TextSize = 12, TextColor3 = K.Muted, TextTruncate = Enum.TextTruncate.AtEnd, Visible = not touch, Parent = missions })
	-- G (ordenador): las teclas
	if not touch then
		local hints = zone("G", S.G, 0.4)
		label({ Name = "Titulo", Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 18), Text = "MANDOS DE VUELO", TextSize = 14, TextColor3 = K.Cyan, Parent = hints })
		local list = create("Frame", { Name = "Lista", Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -24, 1, -34), BackgroundTransparency = 1, Parent = hints })
		create("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 28), CellPadding = UDim2.fromOffset(8, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
		view.Hints = list
	end
	-- H: la barra de 8 ranuras
	local barW = S.Slot * 8 + S.Gap * 7 + 16
	local barFrame = zone("H", Vector2.new(barW, S.Slot + 34), 0.45)
	buildSlots(view, barFrame, S.Slot, S.Gap)
	-- Letrero de la habilidad en marcha (encima de la barra)
	local prompt = zone("Prompt", S.Prompt, 0.2)
	prompt.Visible = false
	view.Prompt.Frame = prompt
	view.Prompt.Title = label({ Name = "Titulo", Position = UDim2.fromOffset(16, 4), Size = UDim2.new(1, -32, 0, 24), Text = "", TextSize = 20, TextColor3 = K.Cyan, Parent = prompt })
	view.Prompt.Sub = label({ Name = "Texto", Position = UDim2.fromOffset(16, 28), Size = UDim2.new(1, -32, 0, 18), Text = "", TextSize = 14, TextColor3 = K.White, TextTruncate = Enum.TextTruncate.AtEnd, Parent = prompt })
	view.Prompt.Bar = bar(prompt, "Progreso", K.Violet, UDim2.new(0, 16, 1, -8), UDim2.new(1, -32, 0, 4))
	-- Selector del salto cuántico
	local q = zone("Quantum", Vector2.new(580, 520), 0.12)
	q.Visible = false
	q.ZIndex = 10
	view.Quantum.Frame = q
	view.Quantum.Title = label({ Name = "Titulo", Position = UDim2.fromOffset(18, 10), Size = UDim2.new(1, -90, 0, 28), Text = "SALTO CUÁNTICO · DESTINO", TextSize = 22, TextColor3 = K.Violet, ZIndex = 11, Parent = q })
	view.Quantum.Info = label({ Name = "Info", Position = UDim2.fromOffset(18, 40), Size = UDim2.new(1, -36, 0, 18), Text = "", TextSize = 14, TextColor3 = K.Muted, ZIndex = 11, Parent = q })
	local close = create("TextButton", { Name = "Cerrar", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 8), Size = UDim2.fromOffset(56, 44), BackgroundColor3 = rgb(60, 20, 30), Text = "✕", TextSize = 24, Font = Theme.FontBold, TextColor3 = K.White, ZIndex = 11, Parent = q })
	create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = close })
	view.Quantum.Close = close
	local list = create("ScrollingFrame", { Name = "Lista", Position = UDim2.fromOffset(12, 64), Size = UDim2.new(1, -24, 1, -76), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 11, Parent = q })
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	view.Quantum.List = list
	view.Quantum.Rows = {}
	-- Colocar (y recolocar al cambiar la pantalla)
	HudLayout.onChanged(function(layout)
		local l = ShipHudLayout.compute(layout.Canvas * layout.Scale, { Touch = layout.Touch })
		for name, f in view.Zones do
			local r = l.Zones[name]
			if r then
				f.AnchorPoint = Vector2.zero
				f.Position = UDim2.fromOffset(r.X, r.Y)
				f.Size = UDim2.fromOffset(r.W, r.H)
			end
		end
	end)
	-- F: encima de todo, en píxeles de la pantalla (lo coloca cada fotograma el controlador)
	local overlay = create("ScreenGui", { Name = "AirCombatOverlay", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 2, Enabled = false, Parent = parent })
	-- La mira: pequeña y abierta en el centro (no tapa al enemigo)
	local cross = create("Frame", { Name = "Cross", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(44, 44), BackgroundTransparency = 1, Parent = overlay })
	for _, d in { { 0.5, 0, 2, 10 }, { 0.5, 1, 2, 10 }, { 0, 0.5, 10, 2 }, { 1, 0.5, 10, 2 } } do
		create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(d[1], d[2]), Size = UDim2.fromOffset(d[3], d[4]), BackgroundColor3 = K.Cyan, BorderSizePixel = 0, Parent = cross })
	end
	ring(cross, UDim2.fromScale(0.7, 0.7), K.Cyan, 1.5, 0.35)
	create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(3, 3), BackgroundColor3 = K.Cyan, BorderSizePixel = 0, Parent = cross })
	local lockBox = create("Frame", { Name = "Lock", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(70, 70), BackgroundTransparency = 1, Visible = false, Parent = overlay })
	local lockStroke = create("UIStroke", { Color = rgb(255, 200, 60), Thickness = 3, Parent = lockBox })
	label({ Name = "Tag", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 4), Size = UDim2.fromOffset(160, 18), Text = "FIJANDO", TextSize = 14, TextColor3 = rgb(255, 200, 60), TextXAlignment = Enum.TextXAlignment.Center, Parent = lockBox })
	view.LockInfo = label({ Name = "Info", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -4), Size = UDim2.fromOffset(200, 34), Text = "", TextSize = 14, TextColor3 = K.Hostile, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Bottom, Parent = lockBox })
	local arrows = {}
	for i = 1, AirCombatHud.Arrows do
		table.insert(arrows, label({ Name = "Arrow" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(34, 34), Text = "▲", TextSize = 30, TextColor3 = K.Hostile, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.4, Visible = false, Parent = overlay }))
	end
	local hit = label({ Name = "HitMark", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(44, 44), Text = "✕", TextSize = 40, TextColor3 = rgb(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = 1, TextStrokeTransparency = 1, Parent = overlay })
	local flash = create("Frame", { Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = overlay })
	local flashStroke = create("UIStroke", { Name = "Edge", Color = rgb(80, 200, 255), Thickness = 24, Transparency = 1, Parent = flash })
	flashStroke:SetAttribute("Edge", true)
	view.Overlay = overlay
	view.Cross = cross
	view.LockBox = lockBox
	view.LockStroke = lockStroke
	view.Arrows = arrows
	view.HitMark = hit
	view.Flash = flash
	return view
end

function AirCombatHud.setEnabled(view: View, on: boolean)
	view.Gui.Enabled = on
	view.Overlay.Enabled = on
	if not on then
		AirCombatHud.hideQuantum(view)
	end
end

---------------------------------------------------------------------
-- Textos del panel (puro)
---------------------------------------------------------------------
function AirCombatHud.texts(info: Info): { [string]: string }
	local warn = info.Warn
	if info.Overheated then
		warn = "Calor"
	end
	local maxE = info.MaxEnergy or 100
	return {
		Speed = tostring(math.floor(info.Speed + 0.5)),
		Boost = if info.BoostReady then ("%d%%"):format(math.floor(info.Boost * 100 + 0.5)) else "ENFRIANDO",
		Shield = tostring(math.max(0, math.floor(info.Shield + 0.5))),
		Hull = tostring(math.max(0, math.floor(info.Hull + 0.5))),
		Missiles = ("%d/%d"):format(info.Missiles, info.MaxMissiles),
		Energy = ("%d%%"):format(math.floor(math.clamp((info.Energy or maxE) / maxE, 0, 1) * 100 + 0.5)),
		Weapon = if info.Weapon == "Laser" then "LÁSER" else "CAÑONES",
		Mode = (if info.FlightMode == "Cruise" then "CRUCERO" elseif info.FlightMode == "Explore" then "EXPLORACIÓN" else "COMBATE") .. (if info.Assist == false then " · LIBRE" else ""),
		Flares = if info.MaxFlares and info.MaxFlares > 0 then ("🎇%d"):format(info.Flares or 0) else "",
		Objective = (if info.Mode == "Space" then "🌌 " else "⛰ ") .. info.Objective .. (if info.Score > 0 then ("  ·  %d pts"):format(info.Score) else ""),
		Warning = info.Alert or (if warn then WARN_TEXT[warn] or "" else ""),
	}
end

function AirCombatHud.set(view: View, info: Info)
	local t = AirCombatHud.texts(info)
	for _, k in { "Speed", "Boost", "Shield", "Hull", "Missiles", "Energy", "Weapon", "Flares" } do
		local v = view.Values[k]
		if v then
			put(view, v, "Text", t[k])
		end
	end
	if view.Chips.Mode then
		put(view, view.Chips.Mode, "Text", t.Mode)
		put(view, view.Chips.Mode, "TextColor3", if info.FlightMode == "Cruise" then K.Gold elseif info.FlightMode == "Explore" then K.Violet else K.Cyan)
	end
	put(view, view.Objective, "Text", t.Objective)
	put(view, view.Warning, "Text", t.Warning)
	local function fill(name: string, k: number)
		local b = view.Bars[name]
		if b then
			put(view, b, "Size", UDim2.fromScale(math.clamp(math.floor(k * 50 + 0.5) / 50, 0, 1), 1))
		end
	end
	fill("Boost", info.Boost)
	put(view, view.Bars.Boost, "BackgroundColor3", if not info.BoostReady then rgb(120, 120, 140) elseif info.Boosting then rgb(255, 210, 120) else K.Boost)
	fill("Energy", (info.Energy or 100) / math.max(info.MaxEnergy or 100, 1))
	fill("Shield", if info.MaxShield > 0 then info.Shield / info.MaxShield else 0)
	local hull = if info.MaxHull > 0 then info.Hull / info.MaxHull else 0
	fill("Hull", hull)
	put(view, view.Bars.Hull, "BackgroundColor3", rgb(255, 70, 60):Lerp(K.Hull, math.clamp(math.floor(hull * 10) / 10, 0, 1)))
	fill("Heat", info.Heat or 0)
	put(view, view.Values.Hull, "TextColor3", if hull < 0.3 then K.Hostile else K.White)
end

---------------------------------------------------------------------
-- A · Perfil
---------------------------------------------------------------------
function AirCombatHud.setProfile(view: View, p: { [string]: any })
	local P = view.Profile
	if p.UserId and P.Avatar then
		put(view, P.Avatar, "Image", ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(p.UserId))
	end
	put(view, P.Name, "Text", tostring(p.Name or ""))
	put(view, P.Level, "Text", ("Nv. %d"):format(p.Level or 1))
	put(view, P.Money, "Text", tostring(p.Money or "$0"))
	put(view, P.Chispas, "Text", ("✨ %d"):format(p.Chispas or 0))
	if p.Ship then
		put(view, P.Ship, "Text", p.Ship)
	end
end

---------------------------------------------------------------------
-- B · Navegación
---------------------------------------------------------------------
function AirCombatHud.setCompass(view: View, heading: number, targetBearing: number?)
	local N = view.Nav
	local marks = ShipHudLayout.compass(heading, 120)
	for i, slot in N.Marks do
		local m = marks[i]
		if m then
			put(view, slot.Label, "Visible", true)
			put(view, slot.Label, "Position", UDim2.fromScale(m.X, 0))
			put(view, slot.Label, "Text", m.Text)
			put(view, slot.Label, "TextColor3", if m.Text == "N" then K.Cyan elseif m.Major then K.White else K.Muted)
			put(view, slot.Label, "TextSize", if m.Major then 22 else 16)
			put(view, slot.Tick, "Size", UDim2.fromOffset(2, if m.Text ~= "" then 4 else 8))
		else
			put(view, slot.Label, "Visible", false)
		end
	end
	local tx = if targetBearing then ShipHudLayout.bearingX(heading, targetBearing, 120) else nil
	put(view, N.Target, "Visible", tx ~= nil)
	if tx then
		put(view, N.Target, "Position", UDim2.fromScale(tx, 0.55))
	end
end

-- nav = { Zone, Detail, Dest (texto), Quantum (texto), QuantumColor }
function AirCombatHud.setNav(view: View, nav: { [string]: any })
	local N = view.Nav
	put(view, N.Zone, "Text", ("%s%s"):format(nav.Zone or "", if nav.Detail and nav.Detail ~= "" then "  ·  " .. nav.Detail else ""))
	put(view, N.Dest, "Text", nav.Dest or "")
	put(view, N.Quantum, "Text", nav.Quantum or "")
	put(view, N.Quantum, "TextColor3", nav.QuantumColor or K.Violet)
end

---------------------------------------------------------------------
-- D · Radar
---------------------------------------------------------------------
-- Lo de antes (solo enemigos), para quien lo use así
export type Blip = { Point: Vector2, Locked: boolean?, Kind: string? }
function AirCombatHud.blips(view: View, list: { Blip })
	local out = {}
	for _, b in list do
		table.insert(out, { Kind = if b.Locked then "Fijado" else "Enemigo", Point = b.Point, Distance = 0, Above = 0 })
	end
	AirCombatHud.radar(view, out)
end

function AirCombatHud.radar(view: View, list: { ShipHudLayout.Blip }, range: number?, heading: number?)
	for i, frame in view.Blips do
		local b = list[i]
		put(view, frame, "Visible", b ~= nil)
		if b then
			local kind = ShipHudLayout.Kinds[b.Kind] or ShipHudLayout.Kinds.Enemigo
			put(view, frame, "Position", UDim2.fromScale(0.5 + b.Point.X * 0.44, 0.5 + b.Point.Y * 0.44))
			local size = kind.Size
			put(view, frame, "Size", UDim2.fromOffset(size, size))
			local ringShape = kind.Shape == "Aro"
			put(view, frame, "BackgroundTransparency", if ringShape then 1 else 0)
			put(view, frame, "BackgroundColor3", kind.Color)
			put(view, frame, "Rotation", if kind.Shape == "Rombo" or kind.Shape == "Cuadro" then 45 else 0)
			local round = frame:FindFirstChild("Round") :: UICorner?
			if round then
				put(view, round, "CornerRadius", if kind.Shape == "Punto" or ringShape then UDim.new(1, 0) else UDim.new(0, 2))
			end
			local stroke = frame:FindFirstChild("Ring") :: UIStroke?
			if stroke then
				put(view, stroke, "Enabled", ringShape)
				put(view, stroke, "Color", kind.Color)
			end
		end
	end
	if range then
		put(view, view.RadarLabel, "Text", ("RADAR %s"):format(string.gsub(("%.1f km"):format(range * 0.28 / 1000), "%.", ",")))
	end
	if heading then
		-- La N gira: el radar va con tu rumbo (delante = arriba)
		local a = math.rad(-heading)
		put(view, view.RadarNorth, "Position", UDim2.fromScale(0.5 + math.sin(a) * 0.43, 0.5 - math.cos(a) * 0.43))
	end
end

---------------------------------------------------------------------
-- E · Misiones
---------------------------------------------------------------------
-- rows = { { Kind = "PRINCIPAL"|"SECUNDARIA"|"EVENTO", Title, Step, Right, Color } }
function AirCombatHud.setMissions(view: View, rows: { { [string]: any } })
	for i, r in view.Missions do
		local m = rows[i]
		put(view, r.Row, "Visible", m ~= nil)
		if m then
			local color = m.Color or (if m.Kind == "PRINCIPAL" then K.Gold elseif m.Kind == "EVENTO" then K.Hostile else K.Cyan)
			put(view, r.Kind, "Text", m.Kind or "")
			put(view, r.Kind, "TextColor3", color)
			put(view, r.Dot, "BackgroundColor3", color)
			put(view, r.Title, "Text", m.Title or "")
			put(view, r.Step, "Text", m.Step or "")
			put(view, r.Right, "Text", m.Right or "")
		end
	end
end

---------------------------------------------------------------------
-- H · Ranuras
---------------------------------------------------------------------
local STATE_COLOR = {
	Ready = K.Edge,
	Active = K.Cyan,
	Cooling = rgb(120, 140, 170),
	NoEnergy = K.Boost,
	Locked = K.Locked,
	Blocked = K.Boost,
}

function AirCombatHud.setSlots(view: View, list: { { [string]: any } }, device: string?)
	for i, s in view.Slots do
		local v = list[i]
		if not v then
			continue
		end
		if s.Id ~= v.Id then
			s.Id = v.Id
			if s.Glyph then
				s.Glyph:Destroy()
			end
			local def = ShipAbilities.SlotById[v.Id]
			s.Glyph = AirCombatHud.glyph(s.Button, if def then def.Glyph else "Canon", K.Cyan)
		end
		local locked = v.State == "Locked"
		local color = STATE_COLOR[v.State] or K.Edge
		put(view, s.Lock, "Visible", locked)
		put(view, s.Glyph, "Visible", not locked)
		for _, d in s.Glyph:GetDescendants() do
			if d:IsA("Frame") and d.BackgroundTransparency < 1 then
				put(view, d, "BackgroundColor3", if locked then K.Locked elseif v.State == "Cooling" then K.Muted elseif d:GetAttribute("Accent") then K.Boost else K.Cyan)
			elseif d:IsA("UIStroke") then
				put(view, d, "Color", if locked then K.Locked elseif v.State == "Cooling" then K.Muted else K.Cyan)
			end
		end
		put(view, s.Stroke, "Color", if v.Selected then K.White else color)
		put(view, s.Stroke, "Thickness", if v.Selected or v.State == "Active" then 3 else 1.5)
		put(view, s.Button, "BackgroundColor3", if v.State == "Active" then rgb(16, 60, 100) elseif locked then rgb(14, 18, 26) else rgb(8, 22, 44))
		put(view, s.Cool, "Size", UDim2.fromScale(1, math.clamp(math.floor((v.Cool or 0) * 20 + 0.5) / 20, 0, 1)))
		put(view, s.Count, "Text", v.Count or "")
		put(view, s.Key, "Text", if device == "Touch" then "" else v.Key)
		put(view, s.Name, "Text", if locked then (v.Note or "Próximamente") elseif v.Note and v.State ~= "Ready" and v.State ~= "Active" then v.Note else v.Name)
		put(view, s.Name, "TextColor3", if locked then K.Muted elseif v.State == "NoEnergy" or v.State == "Blocked" then K.Boost elseif v.Selected then K.Cyan else K.White)
	end
end

-- No se puede: la ranura tiembla en rojo un momento
function AirCombatHud.denySlot(view: View, id: string)
	for _, s in view.Slots do
		if s.Id == id then
			local b = s.Button
			local stroke = s.Stroke
			view.Cache[stroke] = nil
			stroke.Color = K.Hostile
			stroke.Thickness = 3
			local base = b.Position
			task.spawn(function()
				for i = 1, 6 do
					b.Position = base + UDim2.fromOffset(if i % 2 == 0 then 4 else -4, 0)
					task.wait(0.03)
				end
				b.Position = base
				view.Cache[stroke] = nil
			end)
		end
	end
end

---------------------------------------------------------------------
-- G · Teclas (ordenador y mando)
---------------------------------------------------------------------
function AirCombatHud.setHints(view: View, hints: { { Key: string, Text: string } })
	local list = view.Hints
	if not list then
		return
	end
	for _, c in list:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	for i, h in hints do
		local row = create("Frame", { Name = "Tecla" .. i, LayoutOrder = i, BackgroundTransparency = 1, Parent = list })
		local key = label({ Name = "Tecla", Size = UDim2.new(0, 64, 1, -4), Position = UDim2.fromOffset(0, 2), BackgroundColor3 = rgb(20, 40, 70), BackgroundTransparency = 0.2, Text = h.Key, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center, Parent = row })
		create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = key })
		create("UIStroke", { Color = K.Edge, Thickness = 1, Transparency = 0.4, Parent = key })
		label({ Name = "Texto", Position = UDim2.fromOffset(70, 0), Size = UDim2.new(1, -70, 1, 0), Text = h.Text, TextSize = 13, TextColor3 = K.White, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row })
	end
end

---------------------------------------------------------------------
-- Letrero de la habilidad en marcha
---------------------------------------------------------------------
function AirCombatHud.setPrompt(view: View, title: string?, sub: string?, progress: number?, color: Color3?)
	local P = view.Prompt
	put(view, P.Frame, "Visible", title ~= nil)
	if title then
		put(view, P.Title, "Text", title)
		put(view, P.Title, "TextColor3", color or K.Cyan)
		put(view, P.Sub, "Text", sub or "")
		put(view, P.Bar, "Size", UDim2.fromScale(math.clamp(progress or 0, 0, 1), 1))
		put(view, P.Bar, "BackgroundColor3", color or K.Violet)
	end
end

---------------------------------------------------------------------
-- Selector del salto cuántico
---------------------------------------------------------------------
-- entries = { { Id, Name, Kind, Dist (texto), Cost, Ok, Reason } }
function AirCombatHud.showQuantum(view: View, entries: { { [string]: any } }, info: string, onPick: (string) -> (), onClose: () -> ())
	local Q = view.Quantum
	for _, r in Q.Rows do
		r:Destroy()
	end
	Q.Rows = {}
	put(view, Q.Info, "Text", info)
	for i, e in entries do
		local ok = e.Ok == true
		local row = create("TextButton", { Name = "Destino_" .. tostring(e.Id), LayoutOrder = i, Size = UDim2.new(1, -8, 0, 56), BackgroundColor3 = if ok then rgb(20, 40, 80) else rgb(24, 26, 34), BackgroundTransparency = 0.1, AutoButtonColor = ok, Text = "", ZIndex = 12, Parent = Q.List })
		create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = row })
		create("UIStroke", { Color = if ok then K.Violet else K.Locked, Thickness = 1.5, Transparency = 0.3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = row })
		label({ Name = "Nombre", Position = UDim2.fromOffset(14, 4), Size = UDim2.new(0.62, -14, 0, 24), Text = e.Name, TextSize = 18, TextColor3 = if ok then K.White else K.Muted, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 13, Parent = row })
		label({ Name = "Tipo", Position = UDim2.fromOffset(14, 28), Size = UDim2.new(0.62, -14, 0, 20), Text = if ok then e.Kind else ("🔒 " .. (e.Reason or "")), TextSize = 13, TextColor3 = if ok then K.Muted else K.Boost, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 13, Parent = row })
		label({ Name = "Datos", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 8), Size = UDim2.new(0.38, 0, 0, 40), Text = ("%s\n⚡ %d"):format(e.Dist or "", e.Cost or 0), TextSize = 15, TextColor3 = K.Energy, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 13, Parent = row })
		local id = e.Id
		onActivated(row, function()
			onPick(id)
		end)
		table.insert(Q.Rows, row)
	end
	if Q.CloseConn then
		Q.CloseConn:Disconnect()
	end
	Q.CloseConn = onActivated(Q.Close, onClose)
	Q.Frame.Visible = true
	-- (con mando: el primero queda elegido para moverse con la cruceta)
	pcall(function()
		local UserInputService = game:GetService("UserInputService")
		if UserInputService.GamepadEnabled and Q.Rows[1] then
			game:GetService("GuiService").SelectedObject = Q.Rows[1]
		end
	end)
end

function AirCombatHud.hideQuantum(view: View)
	local Q = view.Quantum
	if Q.Frame then
		Q.Frame.Visible = false
	end
end

function AirCombatHud.quantumOpen(view: View): boolean
	return view.Quantum.Frame ~= nil and view.Quantum.Frame.Visible == true
end

---------------------------------------------------------------------
-- Cuentas puras de antes (radar y flechas)
---------------------------------------------------------------------
-- Punto del radar de un enemigo en `pos` visto desde la nave (puro): x a la derecha, y hacia delante
-- (arriba en el radar), en -1..1; lo que pasa del alcance se queda en el borde.
function AirCombatHud.radarPoint(ship: CFrame, pos: Vector3, range: number?): Vector2
	return ShipHudLayout.radarPoint(ship, pos, range or AirCombatHud.RadarRange)
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
