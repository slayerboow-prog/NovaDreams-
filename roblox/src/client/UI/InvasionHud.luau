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
--   │ 🎯 Defiende o recupera una zona                    │  lo que tienes que hacer (tu misión del evento)
-- A los mandos de un avión va debajo de los instrumentos (TopStack.setPiloting); en la nave no sale
-- (el HUD de la nave lo enseña en su fila EVENTO: SpaceService.infoFor).
--
-- UN SOLO aviso del evento (captura del dueño: dos paneles «EVENTO GLOBAL» a la vez, el del centro y la
-- tarjeta de misión de la derecha, todo el rato, tapando la pantalla del móvil). Ahora este panel es el
-- único sitio (la tarjeta de misión sigue con TU misión) y:
--   * Al empezar una oleada (o al llegar el rey, o al acabar) se ve entero FullSeconds (3 s).
--   * Después se encoge a una píldora pequeña en la franja de arriba, junto al reloj (pillRect), sin tapar
--     el centro ni el minimapa:  «🛸 Oleada 1/4» y debajo «⏱ 2:46»
--   * Tocándola se abre otra vez (3 s); tocando el panel abierto, se cierra. Con una ventana grande
--     abierta (MISIONES, ValPhone…) no sale ninguno de los dos (TopStack.quiet).
--   mode(), expand(), toggle() y pillText() son puros (los prueba scripts/test-invasion.luau).

local InvasionHud = {}

-- Medidas en unidades de lienzo de HudLayout (el ScreenGui va con HudLayout.scaleGui)
InvasionHud.Sizes = {
	-- (más bajo y estrecho que antes: a los mandos del avión ya no tapa el centro; captura de v117)
	Pc = { W = 500, Row = 24, Pad = 6, Bar = 8, PillW = 200, PillH = 40 },
	Touch = { W = 560, Row = 30, Pad = 6, Bar = 12, PillW = 230, PillH = 60 },
}

InvasionHud.FullSeconds = 3 -- (el dueño: «la misión que aparece en el centro de la pantalla molesta»: como mucho ~3 s)

-- ¿Panel entero o píldora? mem: una tabla que guarda el cliente ({} al principio). Se abre solo
-- FullSeconds cada vez que cambia la fase (aviso, oleada N, el rey, el final).
function InvasionHud.mode(mem: { [string]: any }, st: { [string]: any }?, now: number): string
	if not st then
		mem.Key = nil
		return "Hidden"
	end
	local key = ("%s:%s:%s"):format(tostring(st.State), tostring(st.Wave), if st.KingAlive then "rey" else "")
	if mem.Key ~= key then
		mem.Key = key
		mem.Until = now + InvasionHud.FullSeconds
	end
	return if now < (mem.Until or 0) then "Full" else "Pill"
end

function InvasionHud.expand(mem: { [string]: any }, now: number)
	mem.Until = now + InvasionHud.FullSeconds
end

-- Tocar: la píldora se abre; el panel abierto se cierra
function InvasionHud.toggle(mem: { [string]: any }, now: number)
	if now < (mem.Until or 0) then
		mem.Until = 0
	else
		InvasionHud.expand(mem, now)
	end
end

InvasionHud.RobloxButtons = 260 -- (píxeles reales) los botones de Roblox de arriba a la izquierda
InvasionHud.PillMinW = 80 -- (lienzo) más estrecha no cabe el texto

-- Dónde va la píldora (en unidades de lienzo de HudLayout): en la FRANJA DE ARRIBA, en el hueco libre
-- más ancho entre los botones de Roblox, el reloj y las balas del arma (que van junto al minimapa).
-- Nunca en el centro de la pantalla ni encima del minimapa. layout = HudLayout.compute(...)
function InvasionHud.pillRect(HudLayout: any, layout: any, touch: boolean): { X: number, Y: number, W: number, H: number }
	local S = if touch then InvasionHud.Sizes.Touch else InvasionHud.Sizes.Pc
	local gap = 10
	local ammo = HudLayout.rect(layout.Items.Ammo, layout.Canvas)
	local clock = HudLayout.rect(layout.Items.Clock, layout.Canvas)
	local rowY, rowH = ammo.Y, math.min(ammo.H, S.PillH)
	local left = InvasionHud.RobloxButtons / layout.Scale + gap
	local right = ammo.X - gap
	local gaps = {}
	if clock.Y < rowY + rowH and clock.Y + clock.H > rowY then
		-- el reloj está en la misma franja: a su izquierda o a su derecha
		table.insert(gaps, { L = left, R = clock.X - gap })
		table.insert(gaps, { L = clock.X + clock.W + gap, R = right })
	else
		table.insert(gaps, { L = left, R = right })
	end
	local best = gaps[1]
	for _, g in gaps do
		if g.R - g.L > best.R - best.L then
			best = g
		end
	end
	local w = math.min(S.PillW, best.R - best.L)
	-- (hueco a la derecha del reloj: pegada al reloj; a su izquierda: pegada al reloj también)
	local x = if best.R == clock.X - gap then best.R - w else best.L
	return { X = x, Y = rowY, W = math.max(w, 0), H = rowH }
end

-- El texto de la píldora: icono, oleada corta y el tiempo que queda
function InvasionHud.pillText(st: { [string]: any }): string
	local head
	if st.State == "Wave" then
		head = ("Oleada %d/%d"):format(tonumber(st.Wave) or 1, tonumber(st.Waves) or 4)
		if st.KingAlive then
			head = "👑 " .. head
		end
	elseif st.State == "Warn" then
		head = "¡Llegan naves!"
	elseif st.State == "End" then
		head = if st.Outcome == "Victoria" then "🏆 ¡Victoria!" else "Fin de la invasión"
	else
		head = "Invasión"
	end
	-- (dos líneas: en el hueco de arriba del móvil cabe así con letra legible)
	local clock = if st.Left and st.State ~= "End" then ("\n⏱ %d:%02d"):format(math.floor(st.Left / 60), st.Left % 60) else ""
	return "🛸 " .. head .. clock
end

-- Tamaño del texto más pequeño del panel (en el móvil el HUD va a escala ~0,4: ≥ 9 px en pantalla)
function InvasionHud.TextSize(touch: boolean): number
	return if touch then 23 else 15
end

-- Alto del panel según lo que enseña (filas: título, razas/zona, barra y, si hay rey, la del rey)
function InvasionHud.height(touch: boolean, king: boolean): number
	local S = if touch then InvasionHud.Sizes.Touch else InvasionHud.Sizes.Pc
	return S.Pad * 2 + S.Row * 3 + S.Bar + 6 + (if king then S.Row + S.Bar + 4 else 0)
end

-- El tamaño en PÍXELES (para TopStack.arrange, que mide en píxeles): canvas * escala del HUD.
-- pill = la píldora (lo que se ve casi siempre)
function InvasionHud.pixelSize(scale: number, touch: boolean, king: boolean, pill: boolean?): (number, number)
	local S = if touch then InvasionHud.Sizes.Touch else InvasionHud.Sizes.Pc
	if pill then
		return math.ceil(S.PillW * scale), math.ceil(S.PillH * scale)
	end
	return math.ceil(S.W * scale), math.ceil(InvasionHud.height(touch, king) * scale)
end

-- Los textos del panel a partir del estado publicado (atributo Invasion de workspace)
-- st = JSON decodificado; zone = la zona más cercana a ti (o nil); raceNames = Races.names
-- step = lo que tienes que hacer (el paso de tu misión del evento; nil = nada)
function InvasionHud.text(st: { [string]: any }, zone: { [string]: any }?, raceNames: string, step: string?): { Title: string, State: string, Line: string, Bar: number, BarColor: string, King: string?, KingBar: number?, Step: string, Pill: string }
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
	local todo = if step and step ~= "" then "🎯 " .. step elseif st.State == "End" then "" else "🎯 Defiende o recupera una zona"
	return { Title = title, State = stateText, Line = line, Bar = bar, BarColor = color, King = king, KingBar = kingBar, Step = todo, Pill = InvasionHud.pillText(st) }
end

InvasionHud.Colors = {
	Valmar = Color3.fromRGB(80, 210, 120),
	Disputa = Color3.fromRGB(255, 190, 60),
	Alien = Color3.fromRGB(235, 70, 90),
	King = Color3.fromRGB(190, 110, 255),
	Accent = Color3.fromRGB(120, 255, 230),
}

-- Construye el panel (Frame) y la píldora dentro de `parent`. Devuelve la vista { Frame, Full, Pill, PillText, Tap, PillTap,
-- Title, State, Line, Fill, Step, KingRow, KingText, KingFill }. view.Tap.Activated: lo conecta quien lo usa.
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
	local full = Theme.create("Frame", { Name = "Full", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = frame })
	local y = S.Pad
	-- Emblema a la izquierda (con los dibujos del HUD: UI/HudArt; si no, nada) y los textos encogen la
	-- letra para caber enteros (antes: «EVENTO…», «Oleada 1 de…»)
	local x = 14
	local okArt, HudArt = pcall(function()
		return require(script.Parent.HudArt)
	end)
	if okArt and HudArt.has("emblema") then
		local e = S.Row * 2 - 4
		local emblem = HudArt.image(full, "emblema", { Name = "Emblema", Position = UDim2.fromOffset(8, S.Pad + 2), Size = UDim2.fromOffset(e, e) })
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
	local title = Theme.title({ Name = "Title", Position = UDim2.fromOffset(x, y), Size = UDim2.new(0.62, -x, 0, S.Row), Text = "EVENTO GLOBAL", TextSize = if touch then 24 else 17, TextColor3 = InvasionHud.Colors.Accent, TextTruncate = Enum.TextTruncate.AtEnd, Parent = full })
	fit(title, if touch then 24 else 17)
	local state = Theme.label({ Name = "State", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, y), Size = UDim2.new(0.38, -4, 0, S.Row), Text = "", Font = Theme.FontBold, TextSize = if touch then 23 else 16, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = full })
	fit(state, if touch then 23 else 16)
	y += S.Row
	local line = Theme.label({ Name = "Line", Position = UDim2.fromOffset(x, y), Size = UDim2.new(1, -x - 14, 0, S.Row), Text = "", TextSize = InvasionHud.TextSize(touch), TextTruncate = Enum.TextTruncate.AtEnd, Parent = full })
	fit(line, InvasionHud.TextSize(touch))
	y += S.Row + 2
	local back = Theme.create("Frame", { Name = "Bar", Position = UDim2.fromOffset(x, y), Size = UDim2.new(1, -x - 14, 0, S.Bar), BackgroundColor3 = Color3.fromRGB(20, 26, 36), BorderSizePixel = 0, Parent = full }, { Theme.corner(4) })
	local fill = Theme.create("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = InvasionHud.Colors.Valmar, BorderSizePixel = 0, Parent = back }, { Theme.corner(4) })
	y += S.Bar + 2
	local step = Theme.label({ Name = "Step", Position = UDim2.fromOffset(14, y), Size = UDim2.new(1, -28, 0, S.Row), Text = "", TextSize = InvasionHud.TextSize(touch), TextTruncate = Enum.TextTruncate.AtEnd, Parent = full })
	fit(step, InvasionHud.TextSize(touch))
	y += S.Row + 2
	local kingRow = Theme.create("Frame", { Name = "King", Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, S.Row + S.Bar + 4), BackgroundTransparency = 1, Visible = false, Parent = full })
	local kingText = Theme.label({ Name = "KingText", Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -28, 0, S.Row), Text = "", Font = Theme.FontBold, TextSize = InvasionHud.TextSize(touch), TextColor3 = InvasionHud.Colors.King, TextTruncate = Enum.TextTruncate.AtEnd, Parent = kingRow })
	local kingBack = Theme.create("Frame", { Position = UDim2.fromOffset(14, S.Row), Size = UDim2.new(1, -28, 0, S.Bar), BackgroundColor3 = Color3.fromRGB(30, 20, 40), BorderSizePixel = 0, Parent = kingRow }, { Theme.corner(4) })
	local kingFill = Theme.create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = InvasionHud.Colors.King, BorderSizePixel = 0, Parent = kingBack }, { Theme.corner(4) })
	-- La píldora (casi siempre): su propio marco en la franja de arriba (no va en la columna del centro)
	local pill = Theme.hudPanel({ Name = "InvasionPill", Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(S.PillW, S.PillH), BackgroundTransparency = 0.2, CornerRadius = 20, Visible = false, Parent = parent })
	local pillStroke = pill:FindFirstChildOfClass("UIStroke") or Theme.create("UIStroke", { Parent = pill })
	pillStroke.Color = InvasionHud.Colors.Accent
	pillStroke.Thickness = 1.5
	local pillText = Theme.label({ Name = "PillText", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -12, 1, -6), Text = "🛸 Invasión", Font = Theme.FontBold, TextSize = if touch then 26 else 16, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, Parent = pill })
	fit(pillText, if touch then 26 else 16)
	-- Tocar: la píldora abre el panel; el panel abierto se cierra
	local tap = Theme.create("TextButton", { Name = "Tap", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 5, Parent = frame })
	local pillTap = Theme.create("TextButton", { Name = "Tap", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 5, Parent = pill })
	return { Frame = frame, Full = full, Pill = pill, PillText = pillText, Tap = tap, PillTap = pillTap, Title = title, State = state, Line = line, Fill = fill, Step = step, KingRow = kingRow, KingText = kingText, KingFill = kingFill, Touch = touch }
end

-- El panel entero (lo que va en la columna del centro). mode: "Full" o "Pill". Devuelve si va entero.
function InvasionHud.paint(view: { [string]: any }, t: { [string]: any }, mode: string?)
	local S = if view.Touch then InvasionHud.Sizes.Touch else InvasionHud.Sizes.Pc
	local isFull = mode == "Full"
	view.Full.Visible = true
	view.PillText.Text = t.Pill or t.State
	view.Title.Text = t.Title
	view.State.Text = t.State
	view.Line.Text = t.Line
	view.Step.Text = t.Step or ""
	view.Fill.Size = UDim2.fromScale(if t.BarColor == "Valmar" then 1 - t.Bar else t.Bar, 1)
	view.Fill.BackgroundColor3 = InvasionHud.Colors[t.BarColor] or InvasionHud.Colors.Valmar
	local king = t.King ~= nil
	view.KingRow.Visible = king
	if king then
		view.KingText.Text = t.King
		view.KingFill.Size = UDim2.fromScale(t.KingBar or 0, 1)
	end
	view.Frame.Size = UDim2.fromOffset(S.W, InvasionHud.height(view.Touch, king))
	return isFull
end

-- Coloca la píldora (rect = pillRect, en lienzo) y la enseña o la esconde. Solo se ve UNO: el panel
-- (columna del centro, TopStack) o la píldora.
function InvasionHud.placePill(view: { [string]: any }, rect: { X: number, Y: number, W: number, H: number }, visible: boolean)
	view.Pill.Position = UDim2.fromOffset(rect.X, rect.Y)
	view.Pill.Size = UDim2.fromOffset(rect.W, rect.H)
	view.Pill.Visible = visible and rect.W >= InvasionHud.PillMinW
end

return InvasionHud
