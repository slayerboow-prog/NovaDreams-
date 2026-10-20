-- SpaceMarkers: marcadores en pantalla de los PLANETAS y las ESTACIONES con la nave en el espacio
-- (queja del dueño en v120: «no se ven los planetas ni aparece nada sobre los planetas, es muy difícil
-- orientarse»; captura docs/bugs/espacio-cielo-azul.png).
--
--   * Cada marcador (v122, como la referencia del dueño): icono del color del planeta (rombo; aro si tiene
--     anillos; escudo las estaciones) y al lado el nombre en blanco y negrita, la distancia, la señal
--     («100%») y una barrita verde debajo.
--     Los nombres y las distancias son los MISMOS que la lista del SALTO CUÁNTICO (shared/Cosmos/
--     QuantumJump.list: «Órbita de Tefra» → marcador «Tefra», distancia hasta ese punto).
--   * Fuera de la pantalla (o detrás): una flechita en el borde de la zona de la mira (el óvalo de
--     ShipHudLayout.center), apuntando hacia donde está; nunca encima de la mira ni de los paneles.
--   * El destino elegido (SALTO CUÁNTICO) va resaltado en dorado y siempre sale.
--   * Pocos a la vez (Max: 4 en el móvil, 6 en el ordenador): el destino, luego lo que tienes delante y
--     lo más cercano. Cerca del centro se desvanecen (la mira es para apuntar); los nombres no se pisan
--     entre sí ni con los paneles del HUD (si no caben, solo el icono).
-- La parte pura (targets, project, layout) la prueban scripts/test-espacio-aaa.luau y test-space.luau.
-- Lo llama Controllers/ShipHudClient (los destinos, dos veces por segundo); aquí se mueven cada
-- fotograma. Si nadie lo llama en un rato (la nave se fue), se esconde solo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cosmos = ReplicatedStorage.Shared.Cosmos
local QuantumJump = require(Cosmos.QuantumJump)
local PlanetBodies = require(Cosmos.PlanetBodies)
local Planets = require(Cosmos.Planets)
local Stations = require(Cosmos.Stations)
local NavInfo = require(Cosmos.NavInfo)
local ShipHudLayout = require(script.Parent.ShipHudLayout)

local SpaceMarkers = {}

local rgb = Color3.fromRGB

SpaceMarkers.Max = { Touch = 4, Pc = 6 }
SpaceMarkers.Gold = rgb(255, 210, 90)
SpaceMarkers.StationColor = rgb(110, 255, 190)
SpaceMarkers.TextSize = { Touch = 12, Pc = 14 } -- pequeños: nunca más que los textos del HUD
SpaceMarkers.Icon = { Touch = 14, Pc = 16 }
SpaceMarkers.FadeInner = 0.55 -- (fracción del óvalo de la mira) dentro de esto, invisible
SpaceMarkers.StaleSeconds = 1.2
SpaceMarkers.BarColor = rgb(70, 230, 120)
SpaceMarkers.BarW = { Touch = 54, Pc = 72 }
-- Señal de la baliza de navegación (lo que dice el «%» del marcador): entera hasta FullAt studs y baja
-- hasta MinPercent en ZeroAt (todo el Sistema Valmar está a menos de FullAt: casi siempre 100 %)
SpaceMarkers.Signal = { FullAt = 30000, ZeroAt = 90000, MinPercent = 35 }

export type Target = {
	Id: string,
	Name: string,
	Kind: string, -- "Planeta" | "Estacion" | "Destino"
	Pos: Vector3, -- dónde se dibuja (el centro del planeta, la estación)
	Dest: Vector3, -- a dónde lleva el salto (para la distancia, como en la lista)
	Color: Color3,
	Selected: boolean?,
	Dist: number?,
	Shape: string?, -- "Rombo" | "Aro" | "Escudo"
	Percent: number?, -- 0..100 (señal)
}

export type Placed = {
	Id: string,
	Name: string,
	Text: string, -- la distancia
	Kind: string,
	Color: Color3,
	X: number,
	Y: number,
	OnScreen: boolean,
	Rotation: number, -- (fuera de la pantalla) hacia dónde apunta la flecha, en grados (0 = derecha)
	Alpha: number, -- 0..1
	Label: boolean, -- se ve el nombre y la distancia
	LabelSide: string?, -- "Below" | "Above" | "Right" | "Left"
	LabelW: number?,
	LabelH: number?,
	Selected: boolean,
	Shape: string, -- "Rombo" | "Aro" | "Escudo"
	Percent: number, -- 0..100
	PercentText: string, -- «100%»
}

-- La señal (0..100) a esa distancia
function SpaceMarkers.percent(dist: number?): number
	local S = SpaceMarkers.Signal
	local d = dist or 0
	if d <= S.FullAt then
		return 100
	end
	local k = math.clamp((d - S.FullAt) / (S.ZeroAt - S.FullAt), 0, 1)
	return math.floor(100 - (100 - S.MinPercent) * k + 0.5)
end

-- La forma del icono: estación = escudo, planeta con anillos = aro, los demás planetas = rombo, el
-- destino suelto = aro
function SpaceMarkers.shapeOf(kind: string, id: string?): string
	if kind == "Estacion" then
		return "Escudo"
	elseif kind == "Planeta" then
		return if id and PlanetBodies.Rings[id] then "Aro" else "Rombo"
	end
	return "Aro"
end

local function planetColor(id: string): Color3
	local p = Planets.ById[id]
	if p and p.Hue then
		return p.Hue
	end
	local b = PlanetBodies.ById[id]
	return if b then b.Halo else rgb(255, 190, 120)
end

-- Los destinos con marcador desde `pos`: los 7 planetas y las estaciones (los de la lista del salto),
-- con el elegido (sel = { Name, Pos }) marcado. Si el elegido es otra cosa (misión, campo), va aparte.
function SpaceMarkers.targets(pos: Vector3, sel: { Name: string?, Pos: Vector3? }?): { Target }
	local out: { Target } = {}
	local matched = false
	for _, d in QuantumJump.list({}) do
		local t: Target? = nil
		if d.Kind == "Planeta" then
			local id = string.match(d.Id, "^Planeta_(.+)$") or d.Id
			local b = PlanetBodies.ById[id]
			local p = Planets.ById[id]
			if b then
				t = { Id = d.Id, Name = if p then p.Name else id, Kind = "Planeta", Pos = b.Center, Dest = d.Pos, Color = planetColor(id), Shape = SpaceMarkers.shapeOf("Planeta", id) }
			end
		elseif d.Kind == "Estacion" then
			local id = string.match(d.Id, "^Estacion_(.+)$") or d.Id
			local st = Stations.ById[id]
			t = { Id = d.Id, Name = d.Name, Kind = "Estacion", Pos = if st then st.Center else d.Pos, Dest = d.Pos, Color = SpaceMarkers.StationColor, Shape = "Escudo" }
		end
		if t then
			local dt = t :: Target
			dt.Dist = (dt.Dest - pos).Magnitude
			dt.Percent = SpaceMarkers.percent(dt.Dist)
			if sel and sel.Pos and ((sel.Pos - dt.Dest).Magnitude < 2 or (sel.Name ~= nil and sel.Name == d.Name)) then
				dt.Selected = true
				matched = true
			end
			table.insert(out, dt)
		end
	end
	if sel and sel.Pos and not matched then
		local dist = (sel.Pos - pos).Magnitude
		table.insert(out, { Id = "Destino", Name = sel.Name or "Destino", Kind = "Destino", Pos = sel.Pos, Dest = sel.Pos, Color = SpaceMarkers.Gold, Selected = true, Dist = dist, Shape = "Aro", Percent = SpaceMarkers.percent(dist) })
	end
	return out
end

-- Dónde cae `pos` en la pantalla (píxeles; fov vertical en grados). inFront = delante de la cámara.
function SpaceMarkers.project(cam: CFrame, fovDeg: number, viewport: Vector2, pos: Vector3): (number, number, boolean)
	local rel = cam:PointToObjectSpace(pos)
	local forward = -rel.Z
	local k = math.tan(math.rad(fovDeg) / 2)
	local half = viewport.Y / 2
	if forward <= 1e-3 then
		-- (detrás: la dirección en pantalla, para la flecha; muy lejos del centro)
		local v = Vector2.new(rel.X, -rel.Y)
		if v.Magnitude < 1e-6 then
			v = Vector2.new(0, -1)
		end
		v = v.Unit * viewport.Magnitude * 4
		return viewport.X / 2 + v.X, viewport.Y / 2 + v.Y, false
	end
	local x = viewport.X / 2 + (rel.X / forward) / k * half
	local y = viewport.Y / 2 - (rel.Y / forward) / k * half
	return x, y, true
end

type Rect = { X: number, Y: number, W: number, H: number }
local function overlaps(a: Rect, b: Rect): boolean
	return a.X < b.X + b.W and b.X < a.X + a.W and a.Y < b.Y + b.H and b.Y < a.Y + a.H
end
local function inside(x: number, y: number, r: Rect): boolean
	return x >= r.X and x <= r.X + r.W and y >= r.Y and y <= r.Y + r.H
end

-- La mira y los paneles del HUD de la nave, en píxeles
function SpaceMarkers.zones(viewport: Vector2, touch: boolean?, inset: number?): (Rect, { Rect })
	local l = ShipHudLayout.compute(viewport, { Touch = touch, Inset = inset, Vehicle = "Ship" })
	local k = l.Scale
	local function px(r: Rect): Rect
		return { X = r.X * k, Y = r.Y * k, W = r.W * k, H = r.H * k }
	end
	local obstacles = {}
	for name, r in l.Zones do
		if not ShipHudLayout.Overlays[name] and name ~= "Prompt" then
			table.insert(obstacles, px(r))
		end
	end
	for _, r in l.Buttons do
		table.insert(obstacles, px(r))
	end
	if l.Stick then
		table.insert(obstacles, px(l.Stick :: Rect))
	end
	return px(ShipHudLayout.center(l)), obstacles
end

-- Dónde va cada marcador. opts = { Touch, Inset, Max }
function SpaceMarkers.layout(cam: CFrame, fovDeg: number, viewport: Vector2, targets: { Target }, opts: { [string]: any }?): { Placed }
	local o = opts or {}
	local touch = o.Touch == true
	local max = o.Max or (if touch then SpaceMarkers.Max.Touch else SpaceMarkers.Max.Pc)
	local center, obstacles = SpaceMarkers.zones(viewport, touch, o.Inset)
	local cx, cy = center.X + center.W / 2, center.Y + center.H / 2
	local rx, ry = center.W / 2, center.H / 2
	local margin = 24
	-- Cada uno: dónde cae y si se ve
	local items = {}
	for _, t in targets do
		local x, y, front = SpaceMarkers.project(cam, fovDeg, viewport, t.Pos)
		local on = front and x >= margin and x <= viewport.X - margin and y >= margin and y <= viewport.Y - margin
		table.insert(items, { T = t, X = x, Y = y, On = on })
	end
	-- Quiénes salen: el elegido, lo que se ve (lo más cerca primero) y luego lo de fuera
	table.sort(items, function(a, b)
		local sa, sb = a.T.Selected == true, b.T.Selected == true
		if sa ~= sb then
			return sa
		end
		if a.On ~= b.On then
			return a.On
		end
		return (a.T.Dist or 0) < (b.T.Dist or 0)
	end)
	local out: { Placed } = {}
	local labels: { Rect } = {}
	local size = if touch then SpaceMarkers.TextSize.Touch else SpaceMarkers.TextSize.Pc
	for _, it in items do
		if #out >= max then
			break
		end
		local t: Target = it.T
		local x, y = it.X, it.Y
		local rot = 0
		local alpha = 1
		local onScreen = it.On
		-- (en el óvalo de la mira: 0 = el centro, 1 = el borde)
		local ex, ey = (x - cx) / rx, (y - cy) / ry
		local e = math.sqrt(ex * ex + ey * ey)
		if not onScreen then
			-- Flecha en el borde del óvalo de la mira, hacia donde está
			local ang = math.atan2(y - cy, x - cx)
			x, y = cx + math.cos(ang) * rx, cy + math.sin(ang) * ry
			rot = math.deg(ang)
			alpha = 0.9
		elseif e < 1 then
			-- Cerca de la mira: se desvanece (dentro de FadeInner, nada)
			alpha = math.clamp((e - SpaceMarkers.FadeInner) / (1 - SpaceMarkers.FadeInner), 0, 1)
		end
		-- (dos flechas en el mismo sitio: solo la primera; la otra no cuenta)
		local dup = false
		if not onScreen then
			for _, q in out do
				if not q.OnScreen and math.abs(q.X - x) + math.abs(q.Y - y) < 22 then
					dup = true
					break
				end
			end
		end
		-- El icono detrás de un panel del HUD: apagado
		for _, r in obstacles do
			if inside(x, y, r) then
				alpha = math.min(alpha, 0.35)
				break
			end
		end
		-- El nombre: fuera del centro de la mira y sin pisar un panel ni otro nombre. Se prueba debajo,
		-- encima, a la derecha y a la izquierda del icono; si no cabe en ninguno, solo el icono.
		local text = NavInfo.distanceText(t.Dist or 0)
		local percent = t.Percent or SpaceMarkers.percent(t.Dist)
		local barW = if touch then SpaceMarkers.BarW.Touch else SpaceMarkers.BarW.Pc
		-- (nombre, distancia, «100%» y la barrita: tres renglones y la barra)
		local w = math.max((math.max(utf8.len(t.Name) or #t.Name, #text) * size * 0.7 + 8), barW + 4)
		local h = SpaceMarkers.labelHeight(size)
		local label = onScreen and e >= 0.85 and alpha > 0.5
		local labelSide = "Below"
		if label then
			label = false
			-- (al lado del icono, como en la referencia; si no cabe, debajo, a la izquierda o encima)
			for _, cand in {
				{ "Right", x + 14, y - size },
				{ "Below", x - w / 2, y + 12 },
				{ "Left", x - 14 - w, y - size },
				{ "Above", x - w / 2, y - 12 - h },
			} do
				local lr: Rect = { X = cand[2], Y = cand[3], W = w, H = h }
				local ok = lr.X >= 4 and lr.Y >= 4 and lr.X + lr.W <= viewport.X - 4 and lr.Y + lr.H <= viewport.Y - 4
				if ok then
					for _, r in obstacles do
						if overlaps(lr, r) then
							ok = false
							break
						end
					end
				end
				if ok then
					for _, r in labels do
						if overlaps(lr, r) then
							ok = false
							break
						end
					end
				end
				if ok then
					label, labelSide = true, cand[1]
					table.insert(labels, lr)
					break
				end
			end
		end
		-- (el elegido, siempre algo visible fuera de la mira)
		if t.Selected and alpha < 0.3 and e >= SpaceMarkers.FadeInner then
			alpha = 0.3
		end
		if dup then
			continue
		end
		table.insert(out, {
			Id = t.Id,
			Name = t.Name,
			Text = text,
			Kind = t.Kind,
			Color = if t.Selected then SpaceMarkers.Gold else t.Color,
			X = x,
			Y = y,
			OnScreen = onScreen,
			Rotation = rot,
			Alpha = alpha,
			Label = label,
			LabelSide = labelSide,
			LabelW = w,
			LabelH = h,
			Selected = t.Selected == true,
			Shape = t.Shape or SpaceMarkers.shapeOf(t.Kind, nil),
			Percent = percent,
			PercentText = ("%d%%"):format(percent),
		})
	end
	return out
end

-- Alto del bloque del nombre: nombre (algo mayor), distancia y «%» y la barrita
function SpaceMarkers.labelHeight(size: number): number
	return math.floor(size * 1.15) + 2 * (size + 1) + 8
end

-- Dónde va el nombre respecto al icono (la esquina de arriba a la izquierda), según LabelSide
function SpaceMarkers.labelOffset(p: Placed): Vector2
	local w, h = p.LabelW or 120, p.LabelH or 30
	local size = math.max(8, math.floor((h - 10) / 3.15))
	if p.LabelSide == "Above" then
		return Vector2.new(-w / 2, -12 - h)
	elseif p.LabelSide == "Right" then
		return Vector2.new(14, -size)
	elseif p.LabelSide == "Left" then
		return Vector2.new(-14 - w, -size)
	end
	return Vector2.new(-w / 2, 12)
end

---------------------------------------------------------------------
-- En el juego
---------------------------------------------------------------------
type Slot = { Frame: Frame, Icon: Frame, Corner: UICorner, Tip: Frame, Ring: UIStroke, Arrow: TextLabel, Name: TextLabel, Dist: TextLabel, Pct: TextLabel, Bar: Frame, Fill: Frame }
local gui: ScreenGui? = nil
local slots: { Slot } = {}
local current: { Target }? = nil
local aliveAt = -math.huge
local conn: RBXScriptConnection? = nil
local touchOnly = false

local function make(className: string, props: { [string]: any }, parent: Instance?): any
	local i = Instance.new(className)
	for k, v in props do
		(i :: any)[k] = v
	end
	if parent then
		i.Parent = parent
	end
	return i
end

local function ensureGui(): ScreenGui?
	if gui and gui.Parent then
		return gui
	end
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	local pg = player and player:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return nil
	end
	local UserInputService = game:GetService("UserInputService")
	touchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	-- (debajo del HUD de la nave: DisplayOrder 1 < 3)
	local g = make("ScreenGui", { Name = "MarcadoresEspacio", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1, Enabled = false }, pg)
	gui = g
	table.clear(slots)
	local size = if touchOnly then SpaceMarkers.TextSize.Touch else SpaceMarkers.TextSize.Pc
	local icon = if touchOnly then SpaceMarkers.Icon.Touch else SpaceMarkers.Icon.Pc
	for i = 1, math.max(SpaceMarkers.Max.Pc, SpaceMarkers.Max.Touch) + 1 do
		local f = make("Frame", { Name = "Marcador" .. i, Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, Visible = false }, g)
		local ic = make("Frame", { Name = "Icono", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(icon, icon), BackgroundTransparency = 0.65, BorderSizePixel = 0 }, f)
		local corner = make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, ic)
		local ring = make("UIStroke", { Thickness = 2, Transparency = 0 }, ic)
		-- (la punta de abajo del escudo: un cuadrito girado debajo del cuerpo)
		local tip = make("Frame", { Name = "Punta", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 1, -1), Size = UDim2.fromOffset(math.floor(icon * 0.7), math.floor(icon * 0.7)), Rotation = 45, BorderSizePixel = 0, Visible = false, ZIndex = 0 }, ic)
		local arrow = make("TextLabel", { Name = "Flecha", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(icon + 6, icon + 6), BackgroundTransparency = 1, Text = "➤", Font = Enum.Font.GothamBold, TextScaled = true, Visible = false }, f)
		local stroke = { TextStrokeTransparency = 0.4, TextStrokeColor3 = rgb(0, 0, 0) }
		local name = make("TextLabel", { Name = "Nombre", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(0, icon / 2 + 3), Size = UDim2.fromOffset(160, size + 2), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = math.floor(size * 1.15), TextColor3 = rgb(255, 255, 255), TextStrokeTransparency = stroke.TextStrokeTransparency, TextStrokeColor3 = stroke.TextStrokeColor3 }, f)
		local dist = make("TextLabel", { Name = "Distancia", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(0, icon / 2 + size + 5), Size = UDim2.fromOffset(160, size), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = size - 1, TextColor3 = rgb(220, 230, 245), TextStrokeTransparency = stroke.TextStrokeTransparency, TextStrokeColor3 = stroke.TextStrokeColor3 }, f)
		local pct = make("TextLabel", { Name = "Porcentaje", Size = UDim2.fromOffset(160, size), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = size, TextColor3 = rgb(255, 255, 255), TextStrokeTransparency = stroke.TextStrokeTransparency, TextStrokeColor3 = stroke.TextStrokeColor3, Visible = false }, f)
		local barW = if touchOnly then SpaceMarkers.BarW.Touch else SpaceMarkers.BarW.Pc
		local bar = make("Frame", { Name = "Barra", Size = UDim2.fromOffset(barW, 4), BackgroundColor3 = rgb(20, 34, 44), BackgroundTransparency = 0.25, BorderSizePixel = 0, Visible = false }, f)
		make("UICorner", { CornerRadius = UDim.new(0, 2) }, bar)
		local fill = make("Frame", { Name = "Relleno", Size = UDim2.fromScale(1, 1), BackgroundColor3 = SpaceMarkers.BarColor, BorderSizePixel = 0 }, bar)
		make("UICorner", { CornerRadius = UDim.new(0, 2) }, fill)
		table.insert(slots, { Frame = f, Icon = ic, Corner = corner, Tip = tip, Ring = ring, Arrow = arrow, Name = name, Dist = dist, Pct = pct, Bar = bar, Fill = fill })
	end
	return g
end

local function render()
	local g = gui
	if not g then
		return
	end
	local camera = workspace.CurrentCamera
	if not current or not camera or os.clock() - aliveAt > SpaceMarkers.StaleSeconds then
		if g.Enabled then
			g.Enabled = false
		end
		return
	end
	local placed = SpaceMarkers.layout(camera.CFrame, camera.FieldOfView, camera.ViewportSize, current :: { Target }, { Touch = touchOnly })
	g.Enabled = true
	for i, s in slots do
		local p = placed[i]
		if not p or p.Alpha <= 0.02 then
			s.Frame.Visible = false
		else
			s.Frame.Visible = true
			s.Frame.Position = UDim2.fromOffset(p.X, p.Y)
			local fade = 1 - p.Alpha
			s.Icon.Visible = p.OnScreen
			s.Arrow.Visible = not p.OnScreen
			-- Icono: rombo relleno del color del planeta, aro (con anillos o destino) o escudo (estación)
			local shape = p.Shape
			s.Icon.BackgroundColor3 = p.Color
			s.Icon.BackgroundTransparency = if shape == "Aro" then 1 else 0.15 + 0.85 * fade
			s.Ring.Color = if shape == "Aro" then p.Color else rgb(255, 255, 255)
			s.Ring.Thickness = if shape == "Aro" then (if p.Selected then 4 else 3) else (if p.Selected then 2 else 1)
			s.Ring.Transparency = fade
			s.Icon.Rotation = if shape == "Rombo" then 45 else 0
			s.Corner.CornerRadius = if shape == "Aro" then UDim.new(0.5, 0) elseif shape == "Escudo" then UDim.new(0.25, 0) else UDim.new(0, 2)
			s.Tip.Visible = shape == "Escudo"
			s.Tip.BackgroundColor3 = p.Color
			s.Tip.BackgroundTransparency = 0.15 + 0.85 * fade
			s.Arrow.Rotation = p.Rotation
			s.Arrow.TextColor3 = p.Color
			s.Arrow.TextTransparency = fade
			s.Name.Visible = p.Label
			s.Dist.Visible = p.Label
			s.Pct.Visible = p.Label
			s.Bar.Visible = p.Label
			if p.Label then
				local off = SpaceMarkers.labelOffset(p)
				local w = p.LabelW or 120
				local size = s.Dist.TextSize + 1
				local big = s.Name.TextSize
				local align = if p.LabelSide == "Right" then Enum.TextXAlignment.Left elseif p.LabelSide == "Left" then Enum.TextXAlignment.Right else Enum.TextXAlignment.Center
				s.Name.AnchorPoint, s.Dist.AnchorPoint, s.Pct.AnchorPoint = Vector2.zero, Vector2.zero, Vector2.zero
				s.Name.Position = UDim2.fromOffset(off.X, off.Y)
				s.Dist.Position = UDim2.fromOffset(off.X, off.Y + big + 1)
				s.Pct.Position = UDim2.fromOffset(off.X, off.Y + big + size + 2)
				s.Name.Size = UDim2.fromOffset(w, big + 1)
				s.Dist.Size = UDim2.fromOffset(w, size)
				s.Pct.Size = UDim2.fromOffset(w, size)
				s.Name.TextXAlignment, s.Dist.TextXAlignment, s.Pct.TextXAlignment = align, align, align
				local barW = s.Bar.Size.X.Offset
				local bx = if align == Enum.TextXAlignment.Left then off.X elseif align == Enum.TextXAlignment.Right then off.X + w - barW else off.X + (w - barW) / 2
				s.Bar.Position = UDim2.fromOffset(bx, off.Y + big + 2 * size + 5)
				s.Fill.Size = UDim2.fromScale(math.clamp(p.Percent / 100, 0, 1), 1)
				s.Fill.BackgroundTransparency = fade
				s.Bar.BackgroundTransparency = 0.25 + 0.75 * fade
			end
			s.Name.Text = p.Name
			s.Name.TextColor3 = if p.Selected then SpaceMarkers.Gold else Color3.fromRGB(255, 255, 255)
			s.Name.TextTransparency = fade
			s.Dist.Text = p.Text
			s.Dist.TextTransparency = fade
			s.Pct.Text = p.PercentText
			s.Pct.TextTransparency = fade
		end
	end
end

-- Los destinos de ahora (nil = ninguno). Lo llama ShipHudClient con la nave en el espacio.
function SpaceMarkers.set(targets: { Target }?)
	current = targets
	aliveAt = os.clock()
	if not targets then
		if gui then
			gui.Enabled = false
		end
		return
	end
	pcall(ensureGui)
	if not conn then
		conn = game:GetService("RunService").RenderStepped:Connect(function()
			local ok, err = pcall(render)
			if not ok then
				warn("[SpaceMarkers] " .. tostring(err))
			end
		end)
	end
end

function SpaceMarkers.current(): { Target }?
	return current
end

return SpaceMarkers
