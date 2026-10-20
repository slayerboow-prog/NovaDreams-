-- GalaxyMapLayout: dónde va cada pieza del MAPA GALÁCTICO (Controllers/GalaxyMapUI) en cada pantalla, en
-- cuentas puras para poder probarlo sin Roblox (scripts/test-mapagalactico.luau). Referencia del dueño:
-- docs/espacio-aaa/referencia-mapa-galactico.png.
--
-- Todo se mide en un LIENZO (píxeles / Scale) que luego se escala con un UIScale, como el mapa de Valmar
-- (shared/MapScreen). Dos formas:
--   * Ancha (ordenador y tableta): como el dibujo. Arriba a la izquierda tu ficha; arriba en medio el título;
--     arriba a la derecha la brújula y ✕; a la izquierda LEYENDA y las misiones; abajo a la izquierda el logo,
--     abajo en medio las pestañas y abajo a la derecha la tarjeta del sistema elegido con VIAJAR.
--   * Compacta (móvil apaisado, 640x360 … 932x430): la ficha, el título, la brújula y ✕ arriba; LEYENDA y
--     MISIONES son dos botones que abren su panel; las pestañas abajo a lo ancho y la tarjeta encima, a la
--     derecha. La galaxia ocupa el hueco del medio (y se mueve y se acerca con los dedos).
-- Lo que se toca mide ≥ 44 px de verdad (en la pantalla, ya escalado). Nada se pisa (lo comprueba la prueba).

local GalaxyMapLayout = {}

GalaxyMapLayout.MinScale = 0.72
GalaxyMapLayout.MaxScale = 1.4
GalaxyMapLayout.Touch = 44 -- px mínimos de lo que se toca
GalaxyMapLayout.Margin = 14
GalaxyMapLayout.Topbar = Vector2.new(250, 58) -- botones de Roblox arriba a la izquierda (px)
GalaxyMapLayout.Tabs = { "Mapa", "Misiones", "Inventario", "Personaje", "Ajustes" }
GalaxyMapLayout.TabText = { Mapa = "MAPA GALÁCTICO", Misiones = "MISIONES", Inventario = "INVENTARIO", Personaje = "PERSONAJE", Ajustes = "AJUSTES" }

export type Rect = { X: number, Y: number, W: number, H: number }
export type Layout = {
	Scale: number,
	Canvas: Vector2,
	Wide: boolean,
	Rects: { [string]: Rect },
	Fixed: { string }, -- lo que se ve siempre (no se puede pisar)
	Drawers: { string }, -- (compacta) paneles que se abren encima
	Ring: { Cx: number, Cy: number, Rx: number, Ry: number, Thumb: number, Icon: number, Hit: number, LabelW: number, LabelH: number, SmallW: number, SmallH: number },
	Text: { Title: number, Sub: number, Body: number, Small: number, Name: number },
}

local function R(x: number, y: number, w: number, h: number): Rect
	return { X = x, Y = y, W = w, H = h }
end

function GalaxyMapLayout.overlaps(a: Rect, b: Rect): boolean
	return a.X < b.X + b.W and b.X < a.X + a.W and a.Y < b.Y + b.H and b.Y < a.Y + a.H
end

function GalaxyMapLayout.inside(r: Rect, canvas: Vector2): boolean
	return r.X >= -0.01 and r.Y >= -0.01 and r.X + r.W <= canvas.X + 0.01 and r.Y + r.H <= canvas.Y + 0.01
end

function GalaxyMapLayout.scaleFor(viewport: Vector2): number
	return math.clamp(math.min(viewport.X / 1560, viewport.Y / 860), GalaxyMapLayout.MinScale, GalaxyMapLayout.MaxScale)
end

-- Pestañas repartidas en `row` (con un hueco de `gap` entre ellas)
local function splitTabs(rects: { [string]: Rect }, row: Rect, gap: number)
	local n = #GalaxyMapLayout.Tabs
	local w = (row.W - gap * (n - 1)) / n
	for i, id in GalaxyMapLayout.Tabs do
		rects["Tab_" .. id] = R(row.X + (i - 1) * (w + gap), row.Y, w, row.H)
	end
end

-- viewport: tamaño de la zona segura (px). opts.Topbar: hueco de los botones de Roblox (px)
function GalaxyMapLayout.layout(viewport: Vector2, opts: { [string]: any }?): Layout
	local o = opts or {}
	local scale = GalaxyMapLayout.scaleFor(viewport)
	local W, H = viewport.X / scale, viewport.Y / scale
	local M = GalaxyMapLayout.Margin
	local topbar = (o.Topbar or GalaxyMapLayout.Topbar) :: Vector2
	local tbW, tbH = topbar.X / scale, topbar.Y / scale
	local touch = GalaxyMapLayout.Touch / scale -- lo mínimo que se toca, en el lienzo
	local wide = W >= 1250 and H >= 700
	local rects: { [string]: Rect } = {}
	local fixed: { string } = {}
	local drawers: { string } = {}
	local text
	local galaxy: Rect

	local closeS = math.max(64, touch)
	rects.Close = R(W - M - closeS, 8, closeS, closeS)
	if wide then
		text = { Title = 40, Sub = 19, Body = 17, Small = 15, Name = 19 }
		local compass = math.clamp(H * 0.15, 110, 150)
		rects.Compass = R(rects.Close.X - 12 - compass, 6, compass, compass)
		local titleW = math.min(560, W * 0.36)
		rects.Title = R((W - titleW) / 2, 10, titleW, 82)
		local playerW = math.clamp(W * 0.27, 400, 470)
		rects.Player = R(M, math.max(M, tbH + 6), playerW, 116)
		-- (la ficha no puede llegar al título: si la pantalla es justa, más estrecha)
		if rects.Player.X + rects.Player.W > rects.Title.X - 12 then
			rects.Player.W = rects.Title.X - 12 - rects.Player.X
		end
		local leftW = math.clamp(W * 0.19, 290, 340)
		local logoH = 92
		rects.Logo = R(M, H - M - logoH, leftW, logoH)
		local cardW, cardH = math.clamp(W * 0.27, 400, 480), 190
		rects.Card = R(W - M - cardW, H - M - cardH, cardW, cardH)
		-- Pestañas: entre el logo y la tarjeta, abajo
		local tabH = math.max(84, touch)
		local tabsX = rects.Logo.X + rects.Logo.W + 14
		local tabsW = math.min(rects.Card.X - 14 - tabsX, 860)
		tabsX = tabsX + (rects.Card.X - 14 - tabsX - tabsW) / 2
		rects.Tabs = R(tabsX, H - M - tabH, tabsW, tabH)
		splitTabs(rects, rects.Tabs, 8)
		-- LEYENDA (7 filas) y las misiones, a la izquierda
		local top = rects.Player.Y + rects.Player.H + 12
		local missionsH = 236
		local avail = rects.Logo.Y - 12 - top - 12 - missionsH
		local row = math.clamp(math.floor((avail - 54) / 7), 26, 36)
		rects.Legend = R(M, top, leftW, 54 + 7 * row)
		rects.Missions = R(M, rects.Legend.Y + rects.Legend.H + 12, leftW, missionsH)
		if rects.Missions.Y + rects.Missions.H > rects.Logo.Y - 10 then
			-- (pantalla baja: sin logo, las misiones bajan hasta el borde)
			rects.Logo = nil
			rects.Missions.H = math.min(missionsH, H - M - rects.Missions.Y)
		end
		for _, id in { "Close", "Compass", "Title", "Player", "Legend", "Missions", "Card", "Tabs" } do
			table.insert(fixed, id)
		end
		if rects.Logo then
			table.insert(fixed, "Logo")
		end
		local gx = rects.Legend.X + rects.Legend.W + 8
		local gy = rects.Title.Y + rects.Title.H
		galaxy = R(gx, gy, W - M - gx, rects.Tabs.Y - gy)
	else
		text = { Title = 30, Sub = 15, Body = 16, Small = 15, Name = 17 }
		-- Arriba, en una fila: [botones de Roblox] TÍTULO (brújula) LEYENDA MISIONES ✕
		local btnW = math.max(86, touch)
		rects.MissionsBtn = R(rects.Close.X - 8 - btnW, rects.Close.Y, btnW, rects.Close.H)
		rects.LegendBtn = R(rects.MissionsBtn.X - 8 - btnW, rects.Close.Y, btnW, rects.Close.H)
		local compass = 74
		rects.Compass = R(rects.LegendBtn.X - 10 - compass, 4, compass, compass)
		local titleX = tbW + 8
		local titleW = rects.Compass.X - 10 - titleX
		if titleW < 300 then
			-- (no cabe con la brújula: fuera la brújula)
			rects.Compass = nil
			titleW = rects.LegendBtn.X - 10 - titleX
		end
		rects.Title = R(titleX, 6, math.min(titleW, 520), 66)
		if titleW > 520 then
			rects.Title.X = titleX + (titleW - 520) / 2
		end
		local playerW = math.min(330, W * 0.31)
		rects.Player = R(M, math.max(rects.Title.Y + rects.Title.H + 6, tbH + 4), playerW, 80)
		local tabH = math.max(62, touch)
		rects.Tabs = R(M, H - M - tabH, W - 2 * M, tabH)
		splitTabs(rects, rects.Tabs, 6)
		local cardW, cardH = math.min(380, W * 0.38), 124
		rects.Card = R(W - M - cardW, rects.Tabs.Y - 8 - cardH, cardW, cardH)
		-- Los paneles que se abren: del alto de la ficha hasta las pestañas, sin tapar la tarjeta
		local drawerW = math.min(340, rects.Card.X - 12 - M)
		rects.LegendDrawer = R(M, rects.Player.Y, drawerW, rects.Tabs.Y - 8 - rects.Player.Y)
		rects.MissionsDrawer = R(M, rects.Player.Y, drawerW, rects.Tabs.Y - 8 - rects.Player.Y)
		drawers = { "LegendDrawer", "MissionsDrawer" }
		for _, id in { "Close", "Title", "Player", "LegendBtn", "MissionsBtn", "Card", "Tabs" } do
			table.insert(fixed, id)
		end
		if rects.Compass then
			table.insert(fixed, "Compass")
		end
		local gy = rects.Title.Y + rects.Title.H
		galaxy = R(0, gy, W, rects.Tabs.Y - gy)
	end
	rects.Galaxy = galaxy

	-- El anillo: elipse centrada en el hueco, con sitio para las miniaturas y sus nombres
	local thumb = math.clamp(math.min(W, H) * 0.1, math.max(62, touch), 104)
	local labelW, labelH = if wide then 220 else 142, if wide then 50 else 42
	local icon = if wide then 42 else 38
	local hit = math.max(touch, icon + 8)
	local cx = galaxy.X + galaxy.W / 2
	local cy = galaxy.Y + galaxy.H / 2
	local rx = math.max(galaxy.W / 2 - thumb / 2 - 12, 120)
	local ry = math.max(math.min(galaxy.H / 2 - thumb / 2 - 8, rx * 0.62), 80)
	return {
		Scale = scale,
		Canvas = Vector2.new(W, H),
		Wide = wide,
		Rects = rects,
		Fixed = fixed,
		Drawers = drawers,
		-- PoiZoom: con cuánto zoom salen los puntos de dentro (en el móvil no caben todos a la vez)
		Ring = { Cx = cx, Cy = cy, Rx = rx, Ry = ry, Thumb = thumb, Icon = icon, Hit = hit, LabelW = labelW, LabelH = labelH, SmallW = if wide then 196 else 150, SmallH = if wide then 42 else 36, PoiZoom = if wide then 1 else 1.7 },
		Text = text,
	}
end

export type Item = { Id: string, X: number, Y: number, Size: number, Thumb: Rect, Label: Rect, Hit: Rect, Side: string }
export type Spot = { Dx: number, Dy: number, Side: string, MinZoom: number, Big: boolean, Size: number }

local function itemAt(layout: Layout, id: string, x: number, y: number, size: number, big: boolean, side: string): Item
	local ring = layout.Ring
	local lw = if big then ring.LabelW else ring.SmallW
	local lh = if big then ring.LabelH else ring.SmallH
	local label: Rect
	if side == "Below" then
		label = { X = x - lw / 2, Y = y + size / 2 + 2, W = lw, H = lh }
	elseif side == "Right" then
		label = { X = x + size / 2 + 4, Y = y - lh / 2, W = lw, H = lh }
	else
		label = { X = x - size / 2 - 4 - lw, Y = y - lh / 2, W = lw, H = lh }
	end
	-- Lo que se toca: la miniatura (≥ 44 px) y su nombre
	local hs = math.max(size, ring.Hit)
	local hx, hy = x - hs / 2, y - hs / 2
	local minX, minY = math.min(hx, label.X), math.min(hy, label.Y)
	local maxX, maxY = math.max(hx + hs, label.X + label.W), math.max(hy + hs, label.Y + label.H)
	return {
		Id = id,
		X = x,
		Y = y,
		Size = size,
		Thumb = { X = x - size / 2, Y = y - size / 2, W = size, H = size },
		Label = label,
		Hit = { X = minX, Y = minY, W = maxX - minX, H = maxY - minY },
		Side = side,
	}
end

-- Coloca cada cosa del anillo UNA vez por pantalla: prueba su sitio (ángulo y radio de shared/Cosmos/GalaxyMap)
-- y, si pisa algo (otro planeta, un nombre, un panel), lo corre un poco (ángulo, radio, lado del nombre)
-- hasta que cabe. Los planetas y Valmar con el zoom 1; los puntos de dentro con el zoom PoiZoom.
-- place(entry, cx, cy, rx, ry) -> x, y. Devuelve { [id] = Spot } (desplazamiento desde el centro con zoom 1)
local function arrangeOnce(layout: Layout, ordered: { any }, place: (any, number, number, number, number) -> (number, number)): ({ [string]: Spot }, number)
	local fails = 0
	local ring = layout.Ring
	local spots: { [string]: Spot } = {}
	local blockers: { Rect } = {}
	for _, id in layout.Fixed do
		table.insert(blockers, layout.Rects[id])
	end
	local function free(it: Item, zoom: number): boolean
		local area = layout.Rects.Galaxy
		if zoom <= 1 then
			if it.Hit.X < 0 or it.Hit.Y < area.Y - 4 or it.Hit.X + it.Hit.W > layout.Canvas.X or it.Hit.Y + it.Hit.H > area.Y + area.H + 4 then
				return false
			end
			for _, b in blockers do
				if GalaxyMapLayout.overlaps(it.Hit, b) then
					return false
				end
			end
		end
		-- (los ya colocados, vistos con el mismo zoom)
		for id, sp in spots do
			local o = itemAt(layout, id, ring.Cx + sp.Dx * zoom, ring.Cy + sp.Dy * zoom, sp.Size, sp.Big, sp.Side)
			if GalaxyMapLayout.overlaps(it.Hit, o.Hit) then
				return false
			end
		end
		return true
	end
	for _, e in ordered do
		local big = e.Kind == "Planet" or e.Kind == "Center"
		local size = if e.Kind == "Center" then ring.Thumb * 1.3 elseif big then ring.Thumb * math.clamp(e.Size or 1, 0.8, 1.2) else ring.Icon
		local zoom = if big then 1 else ring.PoiZoom
		local best: Item? = nil
		local bestSpot: Spot? = nil
		local dAs = if e.Kind == "Center" then { 0 } else { 0, 6, -6, 12, -12, 18, -18, 24, -24, 32, -32, 40, -40 }
		local dRs = if e.Kind == "Center" then { 0 } elseif big then { 0, -0.06, -0.12, 0.05, -0.18, -0.24 } else { 0, -0.08, 0.08, -0.16, 0.16, 0.24 }
		for _, dR in dRs do
			for _, dA in dAs do
				local probe = { Angle = (e.Angle or 0) + dA, Ring = math.max((e.Ring or 0) + dR, 0) }
				local x, y = place(probe, ring.Cx, ring.Cy, ring.Rx, ring.Ry)
				local dx, dy = (x - ring.Cx) * zoom, (y - ring.Cy) * zoom
				-- (los planetas, con el nombre hacia dentro; los de dentro, hacia fuera)
				local sides: { string }
				if e.Kind == "Center" then
					sides = { "Below" }
				elseif big then
					sides = if dx <= 0 then { "Right", "Left" } else { "Left", "Right" }
				else
					sides = if dx <= 0 then { "Left", "Right" } else { "Right", "Left" }
				end
				for _, side in sides do
					local it = itemAt(layout, e.Id, ring.Cx + dx, ring.Cy + dy, size, big, side)
					if free(it, zoom) then
						best = it
						bestSpot = { Dx = dx / zoom, Dy = dy / zoom, Side = side, MinZoom = zoom, Big = big, Size = size }
						break
					end
				end
				if best then
					break
				end
			end
			if best then
				break
			end
		end
		if not best then
			fails += 1
			-- (no cabe sin pisar nada: en su sitio de siempre, se verá al acercarse)
			local x, y = place(e, ring.Cx, ring.Cy, ring.Rx, ring.Ry)
			local dx, dy = x - ring.Cx, y - ring.Cy
			best = itemAt(layout, e.Id, ring.Cx + dx * zoom, ring.Cy + dy * zoom, size, big, if big then "Right" else "Left")
			bestSpot = { Dx = dx, Dy = dy, Side = if big then "Right" else "Left", MinZoom = zoom * 1.4, Big = big, Size = size }
		end
		spots[e.Id] = bestSpot :: Spot
	end
	return spots, fails
end

function GalaxyMapLayout.arrange(layout: Layout, entries: { any }, place: (any, number, number, number, number) -> (number, number)): { [string]: Spot }
	-- Valmar primero; luego los planetas y los puntos de dentro. Se prueban varios órdenes de los planetas
	-- (el primero que se coloca escoge sitio) y se queda el primero en el que todos caben.
	local center, planets, inner = {}, {}, {}
	for _, e in entries do
		if e.Kind == "Center" then
			table.insert(center, e)
		elseif e.Kind == "Planet" then
			table.insert(planets, e)
		else
			table.insert(inner, e)
		end
	end
	local best, bestFails = nil, math.huge
	local n = #planets
	for attempt = 0, n * 2 - 1 do
		local ordered = table.clone(center)
		for i = 1, n do
			local k = (attempt % n + i - 1) % n + 1
			if attempt >= n then
				k = n - k + 1
			end
			table.insert(ordered, planets[k])
		end
		for _, e in inner do
			table.insert(ordered, e)
		end
		local spots, fails = arrangeOnce(layout, ordered, place)
		if fails < bestFails then
			best, bestFails = spots, fails
		end
		if fails == 0 then
			break
		end
	end
	return best :: { [string]: Spot }
end

-- Dónde se ve cada cosa con este zoom y este desplazamiento (lienzo). Las que aún no salen con este zoom
-- (MinZoom) no están en la lista.
function GalaxyMapLayout.items(layout: Layout, spots: { [string]: Spot }, zoom: number, pan: Vector2?): { Item }
	local ring = layout.Ring
	local p = pan or Vector2.new(0, 0)
	local out: { Item } = {}
	for id, s in spots do
		if zoom >= s.MinZoom - 1e-3 then
			table.insert(out, itemAt(layout, id, ring.Cx + p.X + s.Dx * zoom, ring.Cy + p.Y + s.Dy * zoom, s.Size, s.Big, s.Side))
		end
	end
	table.sort(out, function(a, b)
		return a.Id < b.Id
	end)
	return out
end

return GalaxyMapLayout
