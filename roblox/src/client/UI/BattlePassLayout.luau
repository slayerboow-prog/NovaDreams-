-- BattlePassLayout: dónde va cada pieza de la ventana del pase de temporada, calculado en un solo
-- sitio y SIN tocar Roblox (solo números y Vector2): así scripts/test-battlepassui.luau comprueba que
-- nada se pisa ni se sale de la pantalla en el ordenador y en el móvil.
--
-- La ventana es una de UI/Dialog (su escala es Dialog.baseScale()). Todo se mide en unidades de esa
-- ventana; los rectángulos son { X, Y, W, H } relativos a su contenedor:
--   Window            tamaño de la ventana (Dialog.window)
--   Title / Days      título y «Quedan n días» (en la barra del título, a la izquierda del ✖)
--   Content           el marco de contenido de Dialog (16, 56)
--   Header, Tabs      dentro del contenido: nivel + barra de XP, y las secciones (RECOMPENSAS…)
--   Page              lo de debajo (cada sección ocupa la página entera)
--   Rewards.*         dentro de la página: recompensa elegida (Featured), carriles GRATIS/PREMIUM
--                     (Lanes), franja del premium o de la siguiente (Strip), fila de niveles (Track)
--                     y misión destacada (Spotlight; solo en el ordenador)
--   Featured.*        dentro de Featured: vista previa, nombre, textos y botones
--
-- En el móvil la ventana es una hoja casi a pantalla completa (alto entero, botones grandes, texto
-- más grande y menos piezas a la vez: sin misión destacada, que está en MISIONES). En el ordenador es
-- una ventana compacta en el centro.

local BattlePassLayout = {}

export type Rect = { X: number, Y: number, W: number, H: number }

local TOPBAR = 60 -- la barra de Roblox de arriba (como en UI/Dialog)
local SIDE = 24 -- margen total a los lados

local function rect(x: number, y: number, w: number, h: number): Rect
	return { X = x, Y = y, W = w, H = h }
end

-- La misma escala que UI/Dialog.baseScale (para las pruebas y por si se llama sin Dialog)
function BattlePassLayout.dialogScale(viewport: Vector2, touch: boolean): number
	if touch then
		return math.clamp(math.min(viewport.Y / 560, viewport.X / 1000), 0.6, 1.25)
	end
	return math.clamp(viewport.Y / 850, 0.4, 1.25)
end

function BattlePassLayout.compute(viewport: Vector2, touch: boolean, scale: number?): { [string]: any }
	local s = scale or BattlePassLayout.dialogScale(viewport, touch)
	local maxW = math.floor((viewport.X - SIDE) / s)
	local maxH = math.floor((viewport.Y - TOPBAR) / s)
	local W, H
	if touch then
		W = math.min(maxW, 1000)
		H = math.min(maxH, 620)
	else
		W = math.min(maxW, 940)
		H = math.min(maxH, 560)
	end
	local L: { [string]: any } = {
		Scale = s,
		Touch = touch,
		Window = Vector2.new(W, H),
		Button = if touch then 48 else 36, -- alto de los botones
		Text = {
			Title = if touch then 26 else 22,
			Big = if touch then 26 else 22,
			Body = if touch then 20 else 15,
			Small = if touch then 17 else 14,
			Button = if touch then 18 else 14,
		},
	}
	-- Barra del título (de Dialog: título en (16, 8) de 40 de alto; ✖ arriba a la derecha)
	local closeW = if touch then 50 else 36
	local daysW = if touch then 230 else 220
	L.Close = rect(W - 10 - closeW, 10, closeW, closeW)
	L.Days = rect(W - 10 - closeW - 12 - daysW, 12, daysW, 32)
	L.Title = rect(16, 8, L.Days.X - 8 - 16, 40)
	-- Contenido (el de Dialog)
	-- (en el móvil el ✖ es más grande: el contenido empieza un poco más abajo)
	local contentTop = if touch then 64 else 56
	local cw, ch = W - 32, H - contentTop - 8
	L.Content = rect(16, contentTop, cw, ch)
	local headerH = if touch then 56 else 60
	local tabW = if touch then 148 else 132
	local tabsW = tabW * 3 + 8 * 2
	L.TabWidth = tabW
	L.Tabs = rect(cw - tabsW, math.floor((headerH - L.Button) / 2), tabsW, L.Button)
	L.Header = rect(0, 0, cw - tabsW - 16, headerH)
	local pageY = headerH + 8
	L.Page = rect(0, pageY, cw, ch - pageY - 4)
	local pw, ph = L.Page.W, L.Page.H

	-- Recompensas
	local featuredW = if touch then 250 else 280
	local gap = 10
	local rx = featuredW + 12
	local rw = pw - rx
	local laneH = L.Button
	local stripH = L.Button
	local spotlightH = if touch then 0 else 50
	local trackY = laneH + 6 + stripH + 6
	local trackH = ph - trackY - (if spotlightH > 0 then spotlightH + 8 else 0)
	local R: { [string]: any } = {
		Featured = rect(0, 0, featuredW, ph),
		Lanes = rect(rx, 0, rw, laneH),
		Strip = rect(rx, laneH + 6, rw, stripH),
		Track = rect(rx, trackY, rw, trackH),
		Spotlight = if spotlightH > 0 then rect(rx, trackY + trackH + 8, rw, spotlightH) else nil,
	}
	local scrollBar = if touch then 10 else 6
	R.ScrollBar = scrollBar
	R.CardGap = gap
	R.Card = Vector2.new(if touch then 150 else 138, trackH - scrollBar - 6)
	R.LaneTab = Vector2.new(if touch then 170 else 140, laneH)
	R.ClaimAll = Vector2.new(if touch then 210 else 180, laneH)
	L.Rewards = R

	-- Dentro de la tarjeta de cada recompensa
	local card = R.Card
	local pad = 8
	local chip = if touch then 22 else 20
	local btn = if touch then 44 else 32
	local nameH = if touch then 44 else 36
	local metaH = if touch then 20 else 18
	local iconSize = math.max(28, math.min(card.X - 2 * pad, card.Y - (pad + chip + 6) - (nameH + metaH + btn + pad + 12)))
	L.Card = {
		Level = rect(pad, pad, 56, chip),
		Badge = rect(card.X - pad - 64, pad, 64, chip),
		Icon = rect(math.floor((card.X - iconSize) / 2), pad + chip + 4, iconSize, iconSize),
		Name = rect(pad, card.Y - pad - btn - 6 - metaH - nameH, card.X - 2 * pad, nameH),
		Meta = rect(pad, card.Y - pad - btn - 6 - metaH, card.X - 2 * pad, metaH),
		State = rect(pad, card.Y - pad - btn, card.X - 2 * pad, btn),
	}

	-- Dentro de la recompensa elegida (Featured)
	local fw, fh = R.Featured.W, R.Featured.H
	local fpad = 10
	local inner = fw - 2 * fpad
	local buttonsH = L.Button
	local previewH = if touch then math.min(130, math.max(80, fh - 250)) else 150
	local y = fpad
	local F: { [string]: any } = {}
	F.Preview = rect(fpad, y, inner, previewH)
	y += previewH + 8
	F.Name = rect(fpad, y, inner, if touch then 28 else 26)
	y += F.Name.H + 2
	F.Meta = rect(fpad, y, inner, if touch then 20 else 18)
	y += F.Meta.H + 2
	F.Level = rect(fpad, y, inner, if touch then 20 else 18)
	y += F.Level.H + 4
	local buttonsY = fh - fpad - buttonsH
	F.Description = rect(fpad, y, inner, math.max(0, buttonsY - 6 - y))
	-- Botones en una fila: el principal (RECLAMAR…) y, si hace falta, uno secundario a su derecha
	-- (EQUIPAR, PROBAR); sin secundario, el principal ocupa toda la fila
	F.Buttons = rect(fpad, buttonsY, inner, L.Button)
	local secondaryW = math.floor(inner * 0.42)
	F.Primary = rect(fpad, buttonsY, inner - secondaryW - 8, L.Button)
	F.Secondary = rect(fpad + inner - secondaryW, buttonsY, secondaryW, L.Button)
	L.Featured = F

	-- Misiones y fichas (listas con desplazamiento vertical, a lo ancho de la página)
	L.Missions = {
		Row = if touch then 84 else 70,
		Section = if touch then 32 else 28,
		Gap = 8,
		ButtonW = if touch then 124 else 104,
		ScrollBar = if touch then 10 else 6,
	}
	L.Shop = {
		Card = Vector2.new(if touch then 210 else 196, if touch then 210 else 186),
		Gap = 10,
		Info = if touch then 34 else 30,
	}
	return L
end

-- Todos los rectángulos con nombre, en unidades de la ventana (para las pruebas: que no se pisen y
-- que quepan). Devuelve { { Name, Rect } }.
function BattlePassLayout.flatten(L: { [string]: any }): { { Name: string, Rect: Rect } }
	local out = {}
	local function add(name: string, r: Rect?, ox: number, oy: number)
		if r then
			table.insert(out, { Name = name, Rect = rect(r.X + ox, r.Y + oy, r.W, r.H) })
		end
	end
	local c = L.Content
	add("Title", L.Title, 0, 0)
	add("Days", L.Days, 0, 0)
	add("Close", L.Close, 0, 0)
	add("Header", L.Header, c.X, c.Y)
	add("Tabs", L.Tabs, c.X, c.Y)
	local px, py = c.X + L.Page.X, c.Y + L.Page.Y
	for _, key in { "Featured", "Lanes", "Strip", "Track", "Spotlight" } do
		add("Rewards." .. key, L.Rewards[key], px, py)
	end
	return out
end

function BattlePassLayout.overlaps(a: Rect, b: Rect): boolean
	return a.X < b.X + b.W and b.X < a.X + a.W and a.Y < b.Y + b.H and b.Y < a.Y + a.H
end

function BattlePassLayout.inside(inner: Rect, outer: Rect): boolean
	return inner.X >= outer.X - 0.5 and inner.Y >= outer.Y - 0.5 and inner.X + inner.W <= outer.X + outer.W + 0.5 and inner.Y + inner.H <= outer.Y + outer.H + 0.5
end

return BattlePassLayout
