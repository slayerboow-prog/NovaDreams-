-- BattlePassLayout: dónde va cada pieza de la pantalla del pase de temporada, calculado en un solo
-- sitio y SIN tocar Roblox (solo números y Vector2): así scripts/test-battlepassui.luau comprueba que
-- nada se pisa ni se sale de la pantalla en el ordenador y en el móvil.
--
-- La ventana es una de UI/Dialog (su escala es Dialog.baseScale()) casi a pantalla completa. Todo se
-- mide en unidades de esa ventana; los rectángulos son { X, Y, W, H } relativos a su contenedor:
--   Window              tamaño de la ventana
--   Title, Tabs, Money, Close   la barra de arriba: «🏆 PASE DE TEMPORADA», las secciones (RECOMPENSAS,
--                       MISIONES, FICHAS), tu dinero y el ✖ (sin repetir el menú del juego ni el ValPhone)
--   Content             debajo de la barra; Page = el contenido entero (cada sección lo ocupa)
--   Hero.*              cabecera grande: Info (emblema, «TEMPORADA 1», título, subtítulo, cuenta atrás
--                       y botón dorado) y Featured (la recompensa estrella en 3D con cielo de atardecer)
--   Rows.*              las dos filas que se desplazan: Lanes (GRATIS / PREMIUM a la izquierda) y Scroll
--                       (fila gratis, línea de niveles y fila premium, que se mueven juntas)
--   Footer.*            pie: hexágono TU NIVEL, barra de XP, IR A MI NIVEL, RECLAMAR TODO y la caja
--                       del premium con VER BENEFICIOS
--   Card                dentro de cada tarjeta (icono, cantidad, candado/check y RECLAMAR)
--
-- Móvil (pantalla horizontal pequeña): la ventana ocupa toda la pantalla, botones de 44 unidades
-- (unos 28 px como mínimo), texto más grande y la cabecera se compacta (cuenta atrás y botón en una
-- fila). Ordenador: más aire, cabecera alta y tarjetas grandes.

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
	local W = math.min(maxW, if touch then 1180 else 1240)
	local H = math.min(maxH, if touch then 720 else 780)
	local L: { [string]: any } = {
		Scale = s,
		Touch = touch,
		Window = Vector2.new(W, H),
		Button = if touch then 44 else 36, -- alto de los botones
		Text = {
			Title = if touch then 20 else 20,
			Big = if touch then 24 else 22,
			Body = if touch then 17 else 15,
			Small = if touch then 15 else 13,
			Button = if touch then 16 else 14,
		},
	}
	local T = L.Text

	-- Barra de arriba (de derecha a izquierda: ✖, dinero, secciones y el título con lo que sobra)
	local topH = if touch then 54 else 52
	local closeW = if touch then 44 else 36
	L.TopBar = topH
	L.Close = rect(W - 10 - closeW, math.floor((topH - closeW) / 2), closeW, closeW)
	local moneyW = if touch then 150 else 170
	L.Money = rect(L.Close.X - 10 - moneyW, math.floor((topH - L.Button) / 2), moneyW, L.Button)
	local tabW = if touch then 124 else 132
	local tabsW = tabW * 3 + 8 * 2
	L.TabWidth = tabW
	L.Tabs = rect(L.Money.X - 14 - tabsW, math.floor((topH - L.Button) / 2), tabsW, L.Button)
	L.Title = rect(16, math.floor((topH - 36) / 2), math.max(0, L.Tabs.X - 12 - 16), 36)

	-- Contenido
	local cw, ch = W - 32, H - topH - 8
	L.Content = rect(16, topH, cw, ch)
	L.Page = rect(0, 0, cw, ch)
	local gap = if touch then 6 else 10

	-- Pie
	local footH = if touch then 50 else 60
	-- Filas: tarjetas del alto que quepa (sin pasarse), el resto para la cabecera
	local lineH = if touch then 32 else 38
	local scrollBar = if touch then 8 else 6
	local heroMin = if touch then 150 else 200
	local rowsSpace = ch - footH - heroMin - 2 * gap
	local cardH = math.clamp(math.floor((rowsSpace - lineH - scrollBar) / 2), 64, if touch then 118 else 128)
	local cardW = if touch then math.max(84, math.min(104, cardH)) else math.max(96, math.min(122, cardH))
	local rowsH = 2 * cardH + lineH + scrollBar
	local heroH = math.max(heroMin, ch - footH - rowsH - 2 * gap)
	local compact = heroH < 230

	-- Cabecera
	local featuredW = math.floor(cw * (if touch then 0.44 else 0.46))
	local infoW = cw - featuredW - gap
	local Hero: { [string]: any } = {
		Frame = rect(0, 0, cw, heroH),
		Info = rect(0, 0, infoW, heroH),
		Featured = rect(infoW + gap, 0, featuredW, heroH),
		Compact = compact,
	}
	-- Dentro de Info
	do
		local pad = if touch then 8 else 12
		local emblem = if compact then math.min(heroH - 2 * pad - L.Button - 8, 76) else math.min(118, math.floor(heroH * 0.42))
		emblem = math.max(emblem, 48)
		local tx = pad + emblem + 12
		local tw = infoW - tx - pad
		local I: { [string]: any } = {}
		I.Emblem = rect(pad, pad, emblem, emblem)
		local kickerH = if touch then 18 else 20
		local titleH = if compact then (if touch then 30 else 34) else 46
		local y = pad
		I.Kicker = rect(tx, y, tw, kickerH)
		y += kickerH + 2
		I.Name = rect(tx, y, tw, titleH)
		y += titleH + 2
		local subH = if compact then (if touch then 18 else 20) else 40
		local subX = if compact then tx else pad
		local subY = if compact then y else math.max(y, pad + emblem + 6)
		I.Subtitle = rect(subX, subY, infoW - subX - pad, subH)
		local buyH = if touch then L.Button else (if compact then 40 else 48)
		local bottom = heroH - pad
		if compact then
			-- Cuenta atrás y botón en una fila, abajo
			local countW = math.floor((infoW - 2 * pad) * 0.42)
			I.Countdown = rect(pad, bottom - buyH, countW, buyH)
			I.Buy = rect(pad + countW + 8, bottom - buyH, infoW - 2 * pad - countW - 8, buyH)
		else
			local countH = 36
			I.Buy = rect(pad, bottom - buyH, math.min(infoW - 2 * pad, 380), buyH)
			I.Countdown = rect(pad, I.Buy.Y - 8 - countH, math.min(infoW - 2 * pad, 320), countH)
			I.Subtitle.H = math.max(18, math.min(I.Subtitle.H, I.Countdown.Y - 6 - I.Subtitle.Y))
		end
		Hero.InfoParts = I
	end
	-- Dentro de Featured: el 3D ocupa todo; a la derecha, el texto y los botones
	do
		local fw, fh = featuredW, heroH
		local pad = if touch then 8 else 12
		local colW = math.min(if touch then 210 else 250, math.floor(fw * 0.52))
		local cx = fw - pad - colW
		local F: { [string]: any } = {}
		F.Sky = rect(0, 0, fw, fh)
		F.Viewport = rect(0, 0, cx, fh)
		local y = pad
		F.Kicker = rect(cx, y, colW, if touch then 18 else 18)
		y += F.Kicker.H + 2
		local nameH = if fh >= 230 then 52 else (if touch then 24 else 28)
		F.Name = rect(cx, y, colW, nameH)
		y += nameH + 4
		F.Rarity = rect(cx, y, math.min(colW, if touch then 120 else 130), if touch then 22 else 24)
		y += F.Rarity.H + 4
		local btnH = L.Button
		F.Buttons = rect(cx, fh - pad - btnH, colW, btnH)
		local half = math.floor((colW - 6) / 2)
		F.See = rect(cx, fh - pad - btnH, colW, btnH)
		F.SeeHalf = rect(cx, fh - pad - btnH, half, btnH)
		F.Action = rect(cx + half + 6, fh - pad - btnH, colW - half - 6, btnH)
		F.Detail = rect(cx, y, colW, math.max(0, F.Buttons.Y - 4 - y))
		Hero.FeaturedParts = F
	end
	L.Hero = Hero

	-- Filas
	local laneW = if touch then 112 else 168
	local rowsY = heroH + gap
	local scrollX = laneW + gap
	local Rows: { [string]: any } = {
		Frame = rect(0, rowsY, cw, rowsH),
		Lanes = rect(0, 0, laneW, rowsH),
		Scroll = rect(scrollX, 0, cw - scrollX, rowsH),
		CardW = cardW,
		CardH = cardH,
		LineH = lineH,
		Gap = if touch then 8 else 10,
		ScrollBar = scrollBar,
		Free = rect(0, 0, laneW, cardH),
		Premium = rect(0, cardH + lineH, laneW, cardH),
		LineLabel = rect(0, cardH, laneW, lineH),
	}
	Rows.Pitch = cardW + Rows.Gap
	L.Rows = Rows

	-- Dentro de cada tarjeta
	do
		local pad = 6
		local status = if touch then 22 else 22
		local amountH = if touch then 18 else 18
		local claimH = if touch then 22 else 24
		local amountY = cardH - pad - 4 - amountH
		local claimY = cardH - pad - 4 - claimH
		-- (el icono, encima de la cantidad y de RECLAMAR; el candado o el ✔ van en su esquina, encima)
		local icon = math.max(24, math.min(cardW - 2 * pad - 8, math.min(amountY, claimY) - pad - 2))
		L.Card = {
			Icon = rect(math.floor((cardW - icon) / 2), pad, icon, icon),
			Status = rect(cardW - pad - status, pad, status, status),
			Amount = rect(pad, amountY, cardW - 2 * pad, amountH),
			Claim = rect(pad, claimY, cardW - 2 * pad, claimH),
			Rarity = rect(8, cardH - 4, cardW - 16, 3),
		}
	end

	-- Pie
	do
		local fy = rowsY + rowsH + gap
		local Fo: { [string]: any } = { Frame = rect(0, fy, cw, footH) }
		local hex = footH
		Fo.Hex = rect(0, 0, hex, hex)
		local btn = L.Button
		local by = math.floor((footH - btn) / 2)
		local premiumW = math.floor(cw * (if touch then 0.38 else 0.36))
		Fo.Premium = rect(cw - premiumW, 0, premiumW, footH)
		local claimW = if touch then 150 else 170
		local jumpW = if touch then 130 else 150
		Fo.ClaimAll = rect(Fo.Premium.X - 10 - claimW, by, claimW, btn)
		Fo.Jump = rect(Fo.ClaimAll.X - 8 - jumpW, by, jumpW, btn)
		local xpX = hex + 10
		Fo.Xp = rect(xpX, 0, math.max(60, Fo.Jump.X - 12 - xpX), footH)
		-- Dentro de la caja del premium
		local bw = if touch then 150 else 160
		Fo.PremiumButton = rect(premiumW - 8 - bw, math.floor((footH - btn) / 2), bw, btn)
		Fo.PremiumIcon = rect(8, math.floor((footH - 24) / 2), 24, 24)
		Fo.PremiumText = rect(38, 4, Fo.PremiumButton.X - 8 - 38, footH - 8)
		L.Footer = Fo
	end

	-- «VER BENEFICIOS»: hoja encima del contenido
	do
		local bw = math.min(cw - 40, if touch then 640 else 620)
		local bh = math.min(ch - 16, if touch then 400 else 470)
		L.Benefits = rect(math.floor((cw - bw) / 2), math.floor((ch - bh) / 2), bw, bh)
	end

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
	add("Tabs", L.Tabs, 0, 0)
	add("Money", L.Money, 0, 0)
	add("Close", L.Close, 0, 0)
	add("Hero.Info", L.Hero.Info, c.X, c.Y)
	add("Hero.Featured", L.Hero.Featured, c.X, c.Y)
	local r = L.Rows.Frame
	add("Rows.Lanes", L.Rows.Lanes, c.X + r.X, c.Y + r.Y)
	add("Rows.Scroll", L.Rows.Scroll, c.X + r.X, c.Y + r.Y)
	local f = L.Footer.Frame
	for _, key in { "Hex", "Xp", "Jump", "ClaimAll", "Premium" } do
		add("Footer." .. key, L.Footer[key], c.X + f.X, c.Y + f.Y)
	end
	return out
end

-- Las piezas de dentro de la cabecera (para las pruebas)
function BattlePassLayout.heroParts(L: { [string]: any }): { { Name: string, Rect: Rect } }
	local out = {}
	for _, key in { "Emblem", "Kicker", "Name", "Subtitle", "Countdown", "Buy" } do
		table.insert(out, { Name = "Info." .. key, Rect = L.Hero.InfoParts[key] })
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
