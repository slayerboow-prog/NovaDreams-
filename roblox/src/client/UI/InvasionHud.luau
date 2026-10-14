-- InvasionHud: el panel «EVENTO GLOBAL» de la Invasión de la Grieta (arriba en el centro, en la
-- columna de UI/TopStack: nunca pisa tu estado, la hora, el minimapa ni la misión) y su contenido
-- (docs/invasion.md). Lo usa Controllers/InvasionClient; layout() y text() son puros y los prueba
-- scripts/test-invasion.luau en 932x430, 844x390, 640x360 y 1920x1080.
--
--   ┌───────────────────────────────────────────────────┐
--   │ EVENTO GLOBAL · INVASIÓN          Oleada 2 de 4  ⏱ │  título y estado
--   │ Vórtidos y Mórfagos · Plaza del centro: EN DISPUTA│  quién viene y tu zona
--   │ [██████████░░░░░░░░] control de la zona            │  barra (verde Valmar / rojo alienígena)
--   │ 👑 Kael-Ithra · Fase 2 · blindado [████░░░░]      │  (si hay rey)
--   └───────────────────────────────────────────────────┘
-- A los mandos de un avión va debajo de los instrumentos (TopStack.setPiloting); en la nave no sale
-- (el HUD de la nave lo enseña en su fila EVENTO: SpaceService.infoFor).

local InvasionHud = {}

-- Medidas en unidades de lienzo de HudLayout (el ScreenGui va con HudLayout.scaleGui)
InvasionHud.Sizes = {
	-- (más bajo y estrecho que antes: a los mandos del avión ya no tapa el centro; captura de v117)
	Pc = { W = 500, Row = 24, Pad = 6, Bar = 8 },
	Touch = { W = 560, Row = 30, Pad = 6, Bar = 12 },
}

-- Tamaño del texto más pequeño del panel (en el móvil el HUD va a escala ~0,4: ≥ 9 px en pantalla)
function InvasionHud.TextSize(touch: boolean): number
	return if touch then 23 else 15
end

-- Alto del panel según lo que enseña (filas: título, razas/zona, barra y, si hay rey, la del rey)
function InvasionHud.height(touch: boolean, king: boolean): number
	local S = if touch then InvasionHud.Sizes.Touch else InvasionHud.Sizes.Pc
	return S.Pad * 2 + S.Row * 2 + S.Bar + 6 + (if king then S.Row + S.Bar + 4 else 0)
end

-- El tamaño en PÍXELES (para TopStack.arrange, que mide en píxeles): canvas * escala del HUD
function InvasionHud.pixelSize(scale: number, touch: boolean, king: boolean): (number, number)
	local S = if touch then InvasionHud.Sizes.Touch else InvasionHud.Sizes.Pc
	return math.ceil(S.W * scale), math.ceil(InvasionHud.height(touch, king) * scale)
end

-- Los textos del panel a partir del estado publicado (atributo Invasion de workspace)
-- st = JSON decodificado; zone = la zona más cercana a ti (o nil); raceNames = Races.names
function InvasionHud.text(st: { [string]: any }, zone: { [string]: any }?, raceNames: string): { Title: string, State: string, Line: string, Bar: number, BarColor: string, King: string?, KingBar: number? }
	local title = if st.State == "End" then "EVENTO GLOBAL · FIN DE LA INVASIÓN" else "EVENTO GLOBAL · INVASIÓN"
	local stateText = tostring(st.Text or "")
	if st.State == "End" and st.Outcome then
		stateText = if st.Outcome == "Victoria" then "🏆 ¡Victoria!" else "⚠ Valmar ha quedado tocada"
	elseif st.Left and st.State ~= "End" then
		stateText ..= ("  ⏱ %d:%02d"):format(math.floor(st.Left / 60), st.Left % 60)
	end
	local line = raceNames
	local bar, color = 0, "Valmar"
	if zone then
		local status = if zone.Conquered then "CONQUISTADA" elseif (zone.Control or 0) > 0.02 then "EN DISPUTA" else "de Valmar"
		line = ("%s · %s: %s"):format(raceNames, tostring(zone.Name), status)
		bar = math.clamp(tonumber(zone.Control) or 0, 0, 1)
		color = if zone.Conquered then "Alien" elseif bar > 0.02 then "Disputa" else "Valmar"
	end
	local king, kingBar = nil, nil
	if st.KingAlive and st.KingMax then
		king = ("👑 %s"):format(tostring(st.KingStatus or "El rey"))
		kingBar = math.clamp((st.KingHp or 0) / math.max(st.KingMax, 1), 0, 1)
	end
	return { Title = title, State = stateText, Line = line, Bar = bar, BarColor = color, King = king, KingBar = kingBar }
end

InvasionHud.Colors = {
	Valmar = Color3.fromRGB(80, 210, 120),
	Disputa = Color3.fromRGB(255, 190, 60),
	Alien = Color3.fromRGB(235, 70, 90),
	King = Color3.fromRGB(190, 110, 255),
	Accent = Color3.fromRGB(120, 255, 230),
}

-- Construye el panel (Frame) dentro de `parent`. Devuelve la vista { Frame, Title, State, Line, Fill, KingRow, KingText, KingFill }
function InvasionHud.build(parent: Instance, Theme: any, touch: boolean): { [string]: any }
	local S = if touch then InvasionHud.Sizes.Touch else InvasionHud.Sizes.Pc
	local frame = Theme.hudPanel({
		Name = "InvasionPanel",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 120),
		Size = UDim2.fromOffset(S.W, InvasionHud.height(touch, false)),
		BackgroundTransparency = 0.15,
		Visible = false,
		Parent = parent,
	})
	local stroke = frame:FindFirstChildOfClass("UIStroke") or Theme.create("UIStroke", { Parent = frame })
	stroke.Color = InvasionHud.Colors.Accent
	stroke.Thickness = 2
	local y = S.Pad
	-- Emblema a la izquierda (con los dibujos del HUD: UI/HudArt; si no, nada) y los textos encogen la
	-- letra para caber enteros (antes: «EVENTO…», «Oleada 1 de…»)
	local x = 14
	local okArt, HudArt = pcall(function()
		return require(script.Parent.HudArt)
	end)
	if okArt and HudArt.has("emblema") then
		local e = S.Row * 2 - 4
		local emblem = HudArt.image(frame, "emblema", { Name = "Emblema", Position = UDim2.fromOffset(8, S.Pad + 2), Size = UDim2.fromOffset(e, e) })
		if emblem then
			HudArt.icon(emblem, "rombo_rojo", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.6, 0.6) })
			x = 14 + e
		end
		HudArt.frame(frame)
	end
	local function fit(label: TextLabel, max: number)
		label.TextScaled = true
		Theme.create("UITextSizeConstraint", { MaxTextSize = max, MinTextSize = math.floor(max * 0.55), Parent = label })
	end
	local title = Theme.title({ Name = "Title", Position = UDim2.fromOffset(x, y), Size = UDim2.new(0.62, -x, 0, S.Row), Text = "EVENTO GLOBAL", TextSize = if touch then 24 else 17, TextColor3 = InvasionHud.Colors.Accent, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame })
	fit(title, if touch then 24 else 17)
	local state = Theme.label({ Name = "State", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, y), Size = UDim2.new(0.38, -4, 0, S.Row), Text = "", Font = Theme.FontBold, TextSize = if touch then 23 else 16, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame })
	fit(state, if touch then 23 else 16)
	y += S.Row
	local line = Theme.label({ Name = "Line", Position = UDim2.fromOffset(x, y), Size = UDim2.new(1, -x - 14, 0, S.Row), Text = "", TextSize = InvasionHud.TextSize(touch), TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame })
	fit(line, InvasionHud.TextSize(touch))
	y += S.Row + 2
	local back = Theme.create("Frame", { Name = "Bar", Position = UDim2.fromOffset(x, y), Size = UDim2.new(1, -x - 14, 0, S.Bar), BackgroundColor3 = Color3.fromRGB(20, 26, 36), BorderSizePixel = 0, Parent = frame }, { Theme.corner(4) })
	local fill = Theme.create("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = InvasionHud.Colors.Valmar, BorderSizePixel = 0, Parent = back }, { Theme.corner(4) })
	y += S.Bar + 4
	local kingRow = Theme.create("Frame", { Name = "King", Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, S.Row + S.Bar + 4), BackgroundTransparency = 1, Visible = false, Parent = frame })
	local kingText = Theme.label({ Name = "KingText", Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -28, 0, S.Row), Text = "", Font = Theme.FontBold, TextSize = InvasionHud.TextSize(touch), TextColor3 = InvasionHud.Colors.King, TextTruncate = Enum.TextTruncate.AtEnd, Parent = kingRow })
	local kingBack = Theme.create("Frame", { Position = UDim2.fromOffset(14, S.Row), Size = UDim2.new(1, -28, 0, S.Bar), BackgroundColor3 = Color3.fromRGB(30, 20, 40), BorderSizePixel = 0, Parent = kingRow }, { Theme.corner(4) })
	local kingFill = Theme.create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = InvasionHud.Colors.King, BorderSizePixel = 0, Parent = kingBack }, { Theme.corner(4) })
	return { Frame = frame, Title = title, State = state, Line = line, Fill = fill, KingRow = kingRow, KingText = kingText, KingFill = kingFill, Touch = touch }
end

function InvasionHud.paint(view: { [string]: any }, t: { [string]: any })
	view.Title.Text = t.Title
	view.State.Text = t.State
	view.Line.Text = t.Line
	view.Fill.Size = UDim2.fromScale(if t.BarColor == "Valmar" then 1 - t.Bar else t.Bar, 1)
	view.Fill.BackgroundColor3 = InvasionHud.Colors[t.BarColor] or InvasionHud.Colors.Valmar
	local king = t.King ~= nil
	view.KingRow.Visible = king
	if king then
		view.KingText.Text = t.King
		view.KingFill.Size = UDim2.fromScale(t.KingBar or 0, 1)
	end
	local S = if view.Touch then InvasionHud.Sizes.Touch else InvasionHud.Sizes.Pc
	view.Frame.Size = UDim2.fromOffset(S.W, InvasionHud.height(view.Touch, king))
end

return InvasionHud
