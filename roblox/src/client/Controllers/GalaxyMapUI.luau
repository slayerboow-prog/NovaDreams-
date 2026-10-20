-- GalaxyMapUI (cliente): la pantalla del MAPA GALÁCTICO (referencia del dueño:
-- docs/espacio-aaa/referencia-mapa-galactico.png; explicado en docs/espacio-aaa/mapa-galactico.md).
--
--   * Fondo: la galaxia en espiral (assets/espacio/mapa_galaxia.jpg, hecha con
--     scripts/espacio/gen_mapa_galaxia.py) o, hasta que se suba, un degradado azul noche y morado con
--     estrellas y un núcleo que brilla.
--   * Arriba: tu ficha (UI/PlayerCard), el título «MAPA GALÁCTICO» en su marco y la brújula (N/E/S/O); ✕.
--   * Izquierda: LEYENDA (7 rombos de colores) y las misiones (principal, secundaria del tablón y el evento
--     global con su reloj). En el móvil son dos botones que abren su panel.
--   * En medio: el Sistema Valmar en el núcleo y, en la elipse, los 7 planetas con su miniatura (la textura de
--     verdad de cada planeta), su rombo de estado, su nombre y su estado sacado de TU partida
--     (Services/GalaxyMapService). Por dentro, estaciones, campos y sectores (en el móvil, al acercar).
--     Se arrastra y se acerca (pellizco, rueda); tocar el centro acerca para ver lo de dentro.
--   * Abajo a la derecha: la tarjeta del sitio elegido y VIAJAR › por los caminos de siempre
--     (shared/Cosmos/GalaxyMap.travel: salto cuántico, VALMAR o la ruta al puerto). Si no se puede, dice
--     por qué. Abajo: pestañas MAPA GALÁCTICO, MISIONES, INVENTARIO, PERSONAJE y AJUSTES (abren los paneles
--     que ya existen) y el logo.
-- Se abre con M o «Mapa» en el espacio o en un planeta (Controllers/MapUI), con «Galaxia» en el mapa de
-- Valmar y tocando el panel SALTO CUÁNTICO de la nave (Controllers/AirCombatClient).
-- Rendimiento: todo son piezas quietas; solo se recolocan al arrastrar o acercar, y una vez por segundo
-- (con el mapa abierto) se ponen al día la ficha, la brújula y el reloj del evento.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Cosmos = ReplicatedStorage.Shared.Cosmos
local GalaxyMap = require(Cosmos.GalaxyMap)
local EspacioLook = require(Cosmos.EspacioLook)
local EspacioTextureIds = require(Cosmos.EspacioTextureIds)
local SpaceEvents = require(Cosmos.SpaceEvents)
local NavInfo = require(Cosmos.NavInfo)
local Access = require(Cosmos.Access)
local PlanetBodies = require(Cosmos.PlanetBodies)
local Images = require(ReplicatedStorage.Shared.Images)
local Format = require(ReplicatedStorage.Shared.Format)
local Theme = require(script.Parent.Parent.UI.Theme)
local PlayerCard = require(script.Parent.Parent.UI.PlayerCard)
local Layout = require(script.Parent.Parent.UI.GalaxyMapLayout)

local create = Theme.create
local rgb = Color3.fromRGB

local GalaxyMapUI = {}

GalaxyMapUI.MaxZoom = 2.6
GalaxyMapUI.BackgroundKey = "mapa_galaxia"

local K = {
	Panel = rgb(8, 16, 42),
	Edge = rgb(90, 200, 255),
	Title = rgb(120, 220, 255),
	Text = rgb(235, 244, 255),
	Muted = rgb(160, 180, 215),
	Gold = rgb(255, 200, 60),
	Travel = rgb(30, 110, 200),
	Off = rgb(50, 56, 72),
}

local player = Players.LocalPlayer

-- Lo que conecta Main.client (así esto no depende del HUD y se puede probar):
--   runCommand(id) (UI/Hud.runCommand), toast(kind, text), objective() (UI/Hud.objective),
--   quantumTo(destId, name) (AirCombatClient), shipState() (AirCombatClient.quantumState),
--   ship() (AirCombatClient.current), home() (remoto Space "Home"), route(pos, name) (Gps.setManual),
--   registerBig(name, close, isOpen) y closeOthers(name) (UI/Dialog)
local deps: { [string]: any } = {}

local state = {
	Open = false,
	Snap = nil :: { [string]: any }?,
	Entries = {} :: { GalaxyMap.Entry },
	Selected = nil :: string?,
	Zoom = 1,
	Pan = Vector2.new(0, 0),
	Drawer = nil :: string?,
	Layout = nil :: Layout.Layout?,
	Spots = nil :: { [string]: Layout.Spot }?,
	Gui = nil :: ScreenGui?,
	Back = nil :: ScreenGui?,
	Canvas = nil :: Frame?,
	Ring = nil :: Frame?,
	Items = {} :: { [string]: { [string]: any } },
	Parts = {} :: { [string]: any },
	Card = nil :: { [string]: any }?,
	Viewport = nil :: Vector2?,
	Conns = {} :: { RBXScriptConnection },
	Tick = 0,
}

local remote: RemoteEvent? = nil

local function call(name: string, ...): any
	local fn = deps[name]
	if type(fn) == "function" then
		local ok, a, b = pcall(fn, ...)
		if ok then
			return a, b
		end
		warn("[GalaxyMap] " .. name .. ": " .. tostring(a))
	end
	return nil
end

local function toast(kind: string, text: string)
	call("toast", kind, text)
end

---------------------------------------------------------------------
-- Datos
---------------------------------------------------------------------
local function serverNow(): number
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	return if ok and type(t) == "number" then t else os.time()
end

local function where(): { [string]: any }
	local ship = call("ship")
	local w: { [string]: any } = { Planet = player:GetAttribute("Planeta") }
	if type(ship) == "table" then
		w.InShip = true
		w.World = ship.World
		w.Planet = w.Planet or ship.Planet
		local root = ship.Root
		if root and typeof(root) == "Instance" then
			w.Pos = (root :: BasePart).Position
		end
	end
	return w
end

local function mainMission(): { [string]: any }?
	local obj = call("objective")
	if type(obj) == "table" and type(obj.Title) == "string" and obj.Title ~= "" then
		return obj
	end
	return nil
end

local function refreshEntries()
	local main = mainMission()
	state.Entries = GalaxyMap.entries(state.Snap, { Now = serverNow(), Main = main and main.Title, Where = where() })
end

local function entryById(id: string?): GalaxyMap.Entry?
	for _, e in state.Entries do
		if e.Id == id then
			return e
		end
	end
	return nil
end

-- Lo que se sabe aquí para decir si se puede viajar (el servidor lo vuelve a mirar todo)
local function travelState(): { [string]: any }
	local w = where()
	local snap = state.Snap or {}
	local st: { [string]: any } = {
		CanFly = snap.CanFly == true,
		InShip = w.InShip == true,
		World = w.World,
		Planet = w.Planet,
		Found = snap.Found or {},
	}
	local q = call("shipState")
	if type(q) == "table" then
		st.Down, st.Busy, st.InCombat, st.Energy, st.Cooldown, st.Pos = q.Down, q.Busy, q.InCombat, q.Energy, q.Cooldown, q.Pos
	end
	if not st.InShip then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local p = root.Position
			st.NearPort = Vector3.new(p.X - Access.Port.X, 0, p.Z - Access.Port.Z).Magnitude < Access.PadRadius * 3
		end
	end
	return st
end
GalaxyMapUI.travelState = travelState

---------------------------------------------------------------------
-- Piezas pequeñas
---------------------------------------------------------------------
local function label(props: { [string]: any }): TextLabel
	props.BackgroundTransparency = 1
	props.Font = props.Font or Theme.Font
	props.TextColor3 = props.TextColor3 or K.Text
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	return create("TextLabel", props)
end

local function panel(name: string, r: Layout.Rect, parent: Instance, z: number?): Frame
	return create("Frame", {
		Name = name,
		Position = UDim2.fromOffset(r.X, r.Y),
		Size = UDim2.fromOffset(r.W, r.H),
		BackgroundColor3 = K.Panel,
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		ZIndex = z or 30,
		Parent = parent,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 12) }),
		create("UIStroke", { Color = K.Edge, Thickness = 1.5, Transparency = 0.4 }),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(36, 60, 120), rgb(8, 14, 36)) }),
	})
end

-- Rombo de color (la leyenda y el estado de cada sitio)
local function diamond(parent: Instance, size: number, color: Color3, z: number, pos: UDim2?, anchor: Vector2?): Frame
	local holder = create("Frame", {
		Name = "Rombo",
		AnchorPoint = anchor or Vector2.new(0.5, 0.5),
		Position = pos or UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		ZIndex = z,
		Parent = parent,
	})
	create("Frame", {
		Name = "Forma",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.7, 0.7),
		Rotation = 45,
		BackgroundColor3 = rgb(10, 18, 40),
		ZIndex = z,
		Parent = holder,
	}, {
		create("UIStroke", { Color = color, Thickness = 2 }),
		create("Frame", { Name = "Dentro", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.45, 0.45), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z + 1 }),
	})
	return holder
end

-- La miniatura redonda de un planeta: su textura de verdad (el centro de la imagen equirrectangular) con
-- sombra y el aro de la atmósfera; sin textura subida, sus colores (shared/Cosmos/PlanetBodies)
local function planetImage(id: string): string?
	local ids = Images.map(EspacioTextureIds)
	if id == "Valmar" then
		return EspacioLook.id(ids, "valmar_planeta")
	end
	return EspacioLook.planet(ids, id).Texture
end

local function thumb(parent: Instance, e: GalaxyMap.Entry, size: number, z: number): Frame
	local body = e.Planet and PlanetBodies.ById[e.Planet]
	local holder = create("Frame", {
		Name = "Miniatura",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = if body then body.Ground else e.Hue,
		BorderSizePixel = 0,
		ZIndex = z,
		Parent = parent,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = if body then body.Halo else e.Hue, Thickness = 2, Transparency = 0.25 }),
	})
	if not body and e.Kind ~= "Center" then
		create("UIGradient", { Rotation = 45, Color = ColorSequence.new(e.Hue, rgb(30, 30, 50)), Parent = holder })
	end
	local image = if e.Planet then planetImage(e.Planet) else nil
	if image then
		create("ImageLabel", {
			Name = "Textura",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = image,
			ImageRectOffset = Vector2.new(256, 0),
			ImageRectSize = Vector2.new(512, 512),
			ZIndex = z,
			Parent = holder,
		}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	elseif body then
		create("UIGradient", { Rotation = 70, Color = ColorSequence.new(body.Band, body.Ground), Parent = holder })
	end
	-- Sombra (el lado de noche)
	create("Frame", {
		Name = "Sombra",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		ZIndex = z + 1,
		Parent = holder,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIGradient", { Rotation = 35, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.55, 0.92), NumberSequenceKeypoint.new(1, 0.15) }) }),
	})
	-- Anillos (los planetas que los tienen)
	local rings = e.Planet and PlanetBodies.Rings and (PlanetBodies.Rings :: any)[e.Planet]
	if rings then
		create("Frame", {
			Name = "Anillos",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1.7, 0, 0.42, 0),
			Rotation = -12,
			BackgroundTransparency = 1,
			ZIndex = z + 2,
			Parent = holder,
		}, {
			create("UICorner", { CornerRadius = UDim.new(1, 0) }),
			create("UIStroke", { Color = rings.Color or rgb(230, 220, 190), Thickness = 2, Transparency = 0.3 }),
		})
	end
	return holder
end

---------------------------------------------------------------------
-- Fondo: la galaxia (imagen o, hasta que se suba, degradado + estrellas + núcleo)
---------------------------------------------------------------------
local function buildBackground(gui: ScreenGui)
	local bg = create("Frame", {
		Name = "Fondo",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = rgb(4, 6, 22),
		BorderSizePixel = 0,
		ZIndex = 1,
		Parent = gui,
	})
	local image = EspacioLook.id(Images.map(EspacioTextureIds), GalaxyMapUI.BackgroundKey)
	if image then
		create("ImageLabel", { Name = "Galaxia", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = image, ScaleType = Enum.ScaleType.Crop, ZIndex = 2, Parent = bg })
		return
	end
	create("UIGradient", {
		Rotation = 30,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, rgb(10, 14, 48)),
			ColorSequenceKeypoint.new(0.45, rgb(34, 20, 74)),
			ColorSequenceKeypoint.new(0.7, rgb(14, 24, 70)),
			ColorSequenceKeypoint.new(1, rgb(4, 6, 22)),
		}),
		Parent = bg,
	})
	-- Núcleo que brilla: discos concéntricos cada vez más claros
	for i, k in { { 0.62, 0.9, rgb(90, 60, 170) }, { 0.42, 0.84, rgb(150, 90, 200) }, { 0.26, 0.74, rgb(255, 170, 120) }, { 0.12, 0.45, rgb(255, 230, 190) } } do
		create("Frame", {
			Name = "Nucleo" .. i,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.52),
			Size = UDim2.fromScale(k[1], k[1] * 0.75),
			BackgroundColor3 = k[3],
			BackgroundTransparency = k[2],
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = bg,
		}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	end
	-- Estrellas (siempre las mismas)
	local rng = Random.new(7)
	for i = 1, 90 do
		local s = if rng:NextNumber() < 0.15 then 3 else 2
		create("Frame", {
			Name = "Estrella" .. i,
			Position = UDim2.fromScale(rng:NextNumber(), rng:NextNumber()),
			Size = UDim2.fromOffset(s, s),
			BackgroundColor3 = if rng:NextNumber() < 0.3 then rgb(170, 200, 255) else rgb(255, 255, 255),
			BackgroundTransparency = rng:NextNumber() * 0.5,
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = bg,
		})
	end
end

---------------------------------------------------------------------
-- El anillo
---------------------------------------------------------------------
local placeItems: () -> ()

local function select(id: string)
	state.Selected = id
	for itemId, it in state.Items do
		it.Halo.Visible = itemId == id
	end
	GalaxyMapUI._paintCard()
end

local function zoomTo(z: number, focus: Vector2?)
	local lay = state.Layout
	if not lay then
		return
	end
	local old = state.Zoom
	z = math.clamp(z, 1, GalaxyMapUI.MaxZoom)
	-- (lo que hay debajo del dedo se queda debajo del dedo)
	local f = focus or Vector2.new(lay.Ring.Cx, lay.Ring.Cy)
	local c = Vector2.new(lay.Ring.Cx, lay.Ring.Cy) + state.Pan
	local rel = (f - c) / old
	state.Zoom = z
	state.Pan = state.Pan + (f - c) - rel * z
	if z <= 1.001 then
		state.Pan = Vector2.new(0, 0)
	end
	placeItems()
end
GalaxyMapUI.zoomTo = zoomTo

placeItems = function()
	local lay, spots = state.Layout, state.Spots
	if not lay or not spots then
		return
	end
	-- (no dejar que la galaxia se vaya de la pantalla)
	local maxPan = Vector2.new(lay.Ring.Rx * (state.Zoom - 1) + 40, lay.Ring.Ry * (state.Zoom - 1) + 40)
	state.Pan = Vector2.new(math.clamp(state.Pan.X, -maxPan.X, maxPan.X), math.clamp(state.Pan.Y, -maxPan.Y, maxPan.Y))
	local visible = {}
	for _, it in Layout.items(lay, spots, state.Zoom, state.Pan) do
		visible[it.Id] = it
	end
	for id, view in state.Items do
		local it = visible[id]
		view.Button.Visible = it ~= nil
		if it then
			view.Button.Position = UDim2.fromOffset(it.Hit.X, it.Hit.Y)
			view.Button.Size = UDim2.fromOffset(it.Hit.W, it.Hit.H)
			view.Thumb.Position = UDim2.fromOffset(it.Thumb.X - it.Hit.X + it.Size / 2, it.Thumb.Y - it.Hit.Y + it.Size / 2)
			view.Text.Position = UDim2.fromOffset(it.Label.X - it.Hit.X, it.Label.Y - it.Hit.Y)
			view.Text.Size = UDim2.fromOffset(it.Label.W, it.Label.H)
			view.Name.TextXAlignment = if it.Side == "Left" then Enum.TextXAlignment.Right elseif it.Side == "Below" then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left
			view.Status.TextXAlignment = view.Name.TextXAlignment
		end
	end
	local orbit = state.Parts.Orbit
	if orbit then
		local r = lay.Ring
		orbit.Position = UDim2.fromOffset(r.Cx + state.Pan.X, r.Cy + state.Pan.Y)
		orbit.Size = UDim2.fromOffset(r.Rx * 2 * state.Zoom, r.Ry * 2 * state.Zoom)
	end
	local inner = state.Parts.InnerOrbit
	if inner then
		local r = lay.Ring
		inner.Position = UDim2.fromOffset(r.Cx + state.Pan.X, r.Cy + state.Pan.Y)
		inner.Size = UDim2.fromOffset(r.Rx * 1.2 * state.Zoom, r.Ry * 1.2 * state.Zoom)
	end
	local hint = state.Parts.ZoomHint
	if hint then
		hint.Visible = state.Zoom < lay.Ring.PoiZoom - 1e-3
	end
end

local function buildItem(parent: Instance, e: GalaxyMap.Entry, lay: Layout.Layout, spot: Layout.Spot)
	local big = spot.Big
	local z = 12
	local button = create("TextButton", {
		Name = "Sitio_" .. e.Id,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = z,
		Parent = parent,
	})
	local holder = create("Frame", { Name = "Centro", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(spot.Size, spot.Size), BackgroundTransparency = 1, ZIndex = z, Parent = button })
	local halo = create("Frame", {
		Name = "Elegido",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 16, 1, 16),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = z,
		Parent = holder,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = rgb(255, 255, 255), Thickness = 2.5, Transparency = 0.1 }),
	})
	if big then
		thumb(holder, e, spot.Size, z + 1)
		if e.Kind == "Center" then
			-- (el núcleo: un sol que brilla en lugar de una esfera)
			local core = holder:FindFirstChild("Miniatura") :: Frame?
			if core and not planetImage("Valmar") then
				core.BackgroundColor3 = rgb(255, 210, 120)
				create("UIGradient", { Rotation = 45, Color = ColorSequence.new(rgb(255, 250, 220), rgb(255, 140, 60)), Parent = core })
			end
		end
		diamond(holder, math.max(22, spot.Size * 0.34), e.Color, z + 4, UDim2.new(0, 0, 1, 0), Vector2.new(0.25, 0.75))
	else
		diamond(holder, spot.Size, e.Color, z + 1)
	end
	if e.Here then
		-- «Tu posición»: la flecha azul encima
		local you = label({ Name = "TuPosicion", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -2), Size = UDim2.fromOffset(28, 24), Text = "▼", TextSize = 24, TextColor3 = GalaxyMap.Colors.You, TextXAlignment = Enum.TextXAlignment.Center, Font = Theme.FontBold, ZIndex = z + 5, Parent = holder })
		create("UIStroke", { Color = rgb(10, 20, 50), Thickness = 1.5, Parent = you })
	end
	local text = create("Frame", { Name = "Nombre", BackgroundTransparency = 1, ZIndex = z, Parent = button })
	local nameSize = if big then lay.Text.Name else lay.Text.Small
	local nameLabel = label({ Name = "Texto", Size = UDim2.new(1, 0, 0.55, 0), Text = if e.Locked and e.Kind == "Planet" then e.Name else e.Name, TextSize = nameSize, Font = Theme.FontBold, TextTruncate = Enum.TextTruncate.AtEnd, TextStrokeTransparency = 0.4, ZIndex = z + 2, Parent = text })
	local statusColor = if e.Status == "Event" then GalaxyMap.Colors.Event elseif e.Status == "Missions" or e.Status == "MainHere" then GalaxyMap.Colors.Main elseif e.Locked then K.Muted else GalaxyMap.Colors.Visited
	local status = label({ Name = "Estado", Position = UDim2.fromScale(0, 0.55), Size = UDim2.new(1, 0, 0.45, 0), Text = e.StatusText, TextSize = lay.Text.Small, TextColor3 = statusColor, TextTruncate = Enum.TextTruncate.AtEnd, TextStrokeTransparency = 0.5, ZIndex = z + 2, Parent = text })
	button.Activated:Connect(function()
		select(e.Id)
		if e.Kind == "Center" and state.Layout and state.Zoom < state.Layout.Ring.PoiZoom then
			zoomTo(state.Layout.Ring.PoiZoom)
		end
	end)
	state.Items[e.Id] = { Button = button, Thumb = holder, Text = text, Name = nameLabel, Status = status, Halo = halo, Entry = e }
end

---------------------------------------------------------------------
-- Paneles
---------------------------------------------------------------------
local function buildTitle(parent: Instance, lay: Layout.Layout)
	local r = lay.Rects.Title
	local p = panel("Titulo", r, parent, 30)
	p.BackgroundTransparency = 0.3
	-- (marco de ciencia ficción: dos líneas que brillan a los lados)
	for _, side in { 0, 1 } do
		create("Frame", { Name = "Filo", AnchorPoint = Vector2.new(side, 0.5), Position = UDim2.new(side, if side == 0 then -10 else 10, 0.5, 0), Size = UDim2.new(0, 30, 0, 2), BackgroundColor3 = K.Edge, BorderSizePixel = 0, ZIndex = 31, Parent = p })
	end
	local title = label({ Name = "Texto", Position = UDim2.fromScale(0, 0.06), Size = UDim2.fromScale(1, 0.56), Text = GalaxyMap.Title, TextScaled = true, Font = Theme.FontBold, TextColor3 = K.Title, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 31, Parent = p })
	create("UITextSizeConstraint", { MaxTextSize = lay.Text.Title, Parent = title })
	local sub = label({ Name = "Subtitulo", Position = UDim2.fromScale(0.03, 0.6), Size = UDim2.fromScale(0.94, 0.34), Text = GalaxyMap.Subtitle, TextScaled = true, TextColor3 = K.Text, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 31, Parent = p })
	create("UITextSizeConstraint", { MaxTextSize = lay.Text.Sub, MinTextSize = 10, Parent = sub })
end

local function buildCompass(parent: Instance, lay: Layout.Layout)
	local r = lay.Rects.Compass
	if not r then
		return
	end
	local c = create("Frame", {
		Name = "Brujula",
		Position = UDim2.fromOffset(r.X, r.Y),
		Size = UDim2.fromOffset(r.W, r.H),
		BackgroundColor3 = K.Panel,
		BackgroundTransparency = 0.45,
		ZIndex = 30,
		Parent = parent,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = K.Edge, Thickness = 2, Transparency = 0.2 }),
	})
	for _, d in { { "N", 0.5, 0.1 }, { "E", 0.9, 0.5 }, { "S", 0.5, 0.9 }, { "O", 0.1, 0.5 } } do
		label({ Name = d[1], AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(d[2], d[3]), Size = UDim2.fromOffset(24, 24), Text = d[1], TextSize = math.max(15, r.W * 0.15), Font = Theme.FontBold, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 31, Parent = c })
	end
	local arrow = label({ Name = "Aguja", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.5, 0.5), Text = "▲", TextScaled = true, Font = Theme.FontBold, TextColor3 = K.Title, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 32, Parent = c })
	state.Parts.Needle = arrow
end

local function buildLegend(parent: Instance, r: Layout.Rect, lay: Layout.Layout, name: string): Frame
	local p = panel(name, r, parent, 30)
	label({ Name = "Cabecera", Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -60, 0, 30), Text = "✦ LEYENDA", TextSize = lay.Text.Name + 2, Font = Theme.FontBold, TextColor3 = K.Title, ZIndex = 31, Parent = p })
	local rowH = (r.H - 50) / #GalaxyMap.Legend
	for i, row in GalaxyMap.Legend do
		local y = 44 + (i - 1) * rowH
		diamond(p, math.min(26, rowH - 4), GalaxyMap.Colors[row.Id], 31, UDim2.fromOffset(28, y + rowH / 2))
		label({ Name = "Fila_" .. row.Id, Position = UDim2.fromOffset(52, y), Size = UDim2.new(1, -60, 0, rowH), Text = row.Text, TextSize = lay.Text.Body, ZIndex = 31, Parent = p })
	end
	return p
end

local function buildMissions(parent: Instance, r: Layout.Rect, lay: Layout.Layout, name: string): Frame
	local p = panel(name, r, parent, 30)
	local h = (r.H - 12) / 3
	local rows = {}
	for i, def in { { "Main", "◆ MISIÓN PRINCIPAL", GalaxyMap.Colors.Main }, { "Side", "◆ MISIÓN SECUNDARIA", GalaxyMap.Colors.Side }, { "Event", "◆ EVENTO GLOBAL", GalaxyMap.Colors.Event } } do
		local y = 6 + (i - 1) * h
		local row = create("Frame", { Name = def[1], Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, ZIndex = 31, Parent = p })
		label({ Name = "Cabecera", Position = UDim2.fromOffset(12, 2), Size = UDim2.new(1, -24, 0, h * 0.32), Text = def[2], TextScaled = true, Font = Theme.FontBold, TextColor3 = def[3], ZIndex = 31, Parent = row })
		local title = label({ Name = "Titulo", Position = UDim2.fromOffset(12, h * 0.34), Size = UDim2.new(1, -84, 0, h * 0.32), Text = "", TextScaled = true, Font = Theme.FontBold, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 31, Parent = row })
		local hint = label({ Name = "Pista", Position = UDim2.fromOffset(12, h * 0.66), Size = UDim2.new(1, -84, 0, h * 0.3), Text = "", TextScaled = true, TextColor3 = K.Muted, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 31, Parent = row })
		local value = label({ Name = "Dato", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, h * 0.4), Size = UDim2.fromOffset(72, h * 0.4), Text = "", TextScaled = true, Font = Theme.FontBold, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 31, Parent = row })
		for _, l in { title, hint, value } do
			create("UITextSizeConstraint", { MaxTextSize = lay.Text.Body, MinTextSize = 10, Parent = l })
		end
		rows[def[1]] = { Title = title, Hint = hint, Value = value }
	end
	state.Parts.MissionRows = state.Parts.MissionRows or {}
	table.insert(state.Parts.MissionRows, rows)
	return p
end

local function paintMissions()
	local lists = state.Parts.MissionRows
	if not lists then
		return
	end
	local main = mainMission()
	local snap = state.Snap or {}
	local side = snap.SideMissions and snap.SideMissions[1]
	local ev = SpaceEvents.at(serverNow())
	local evTitle, evStep = SpaceEvents.texts(ev)
	local mainDist = ""
	if main and typeof(main.Target) == "Vector3" then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			mainDist = NavInfo.distanceText((root.Position - main.Target).Magnitude)
		end
	end
	for _, rows in lists do
		rows.Main.Title.Text = if main then main.Title else "Sin misión principal"
		rows.Main.Hint.Text = if main then (main.Step or "") else "Sigue tu historia en Valmar"
		rows.Main.Value.Text = mainDist
		rows.Side.Title.Text = if side then side.Title else "Ninguna activa"
		rows.Side.Hint.Text = if side then (if side.TargetName then "→ " .. side.TargetName else "") else "Coge una en el tablón de una estación"
		rows.Side.Value.Text = if side then tostring(side.Progress or "") else ""
		if type(snap.Invasion) == "string" and snap.Invasion ~= "" then
			rows.Event.Title.Text = "Invasión de la Grieta"
			rows.Event.Hint.Text = snap.Invasion
			rows.Event.Value.Text = "⚠"
		else
			rows.Event.Title.Text = evTitle
			rows.Event.Hint.Text = evStep
			rows.Event.Value.Text = SpaceEvents.clock(ev.Left)
		end
	end
end

local function buildCard(parent: Instance, lay: Layout.Layout)
	local r = lay.Rects.Card
	local p = panel("Tarjeta", r, parent, 30)
	local img = math.min(r.H - 16, r.W * 0.34)
	local imageHolder = create("Frame", { Name = "Imagen", Position = UDim2.fromOffset(10, (r.H - img) / 2), Size = UDim2.fromOffset(img, img), BackgroundTransparency = 1, ZIndex = 31, Parent = p })
	local x = img + 22
	local name = label({ Name = "Nombre", Position = UDim2.fromOffset(x, 8), Size = UDim2.new(1, -x - 10, 0, lay.Text.Name + 6), Text = "", TextSize = lay.Text.Name + 1, Font = Theme.FontBold, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 31, Parent = p })
	local lines = label({ Name = "Datos", Position = UDim2.fromOffset(x, 8 + lay.Text.Name + 8), Size = UDim2.new(1, -x - 10, 1, -(lay.Text.Name + 16) - math.max(56, 44 / lay.Scale) - 10), Text = "", TextSize = lay.Text.Small, TextColor3 = K.Muted, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, RichText = true, ZIndex = 31, Parent = p })
	local btnH = math.max(56, 44 / lay.Scale)
	local travel = create("TextButton", {
		Name = "Viajar",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -10, 1, -8),
		Size = UDim2.fromOffset(math.min(190, r.W - x - 10), btnH),
		BackgroundColor3 = K.Travel,
		Text = "VIAJAR ›",
		TextSize = lay.Text.Name + 3,
		Font = Theme.FontBold,
		TextColor3 = K.Text,
		AutoButtonColor = true,
		ZIndex = 32,
		Parent = p,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 10) }),
		create("UIStroke", { Color = K.Edge, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	})
	local reason = label({ Name = "Motivo", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, x, 1, -8), Size = UDim2.new(1, -x - math.min(190, r.W - x - 10) - 18, 0, btnH), Text = "", TextSize = lay.Text.Small, TextColor3 = rgb(255, 190, 120), TextWrapped = true, TextScaled = true, ZIndex = 31, Parent = p })
	create("UITextSizeConstraint", { MaxTextSize = lay.Text.Small, MinTextSize = 10, Parent = reason })
	state.Card = { Frame = p, Image = imageHolder, ImageSize = img, Name = name, Lines = lines, Travel = travel, Reason = reason, Shown = nil }
	travel.Activated:Connect(function()
		GalaxyMapUI.travel()
	end)
end

function GalaxyMapUI._paintCard()
	local card = state.Card
	local e = entryById(state.Selected)
	if not card or not e then
		return
	end
	if card.Shown ~= e.Id then
		card.Shown = e.Id
		for _, child in card.Image:GetChildren() do
			child:Destroy()
		end
		if e.Kind == "Planet" or e.Kind == "Center" then
			thumb(card.Image, e, card.ImageSize, 32)
		else
			diamond(card.Image, card.ImageSize * 0.6, e.Color, 32)
		end
	end
	card.Name.Text = e.Name
	local parts = {}
	if e.Sub ~= "" then
		table.insert(parts, e.Sub)
	end
	for _, line in e.Lines do
		table.insert(parts, ("%s: <font color=\"#ffffff\">%s</font>"):format(line[1], line[2]))
	end
	card.Lines.Text = table.concat(parts, "\n")
	local t = GalaxyMap.travel(e, travelState())
	card.Travel.Text = t.Label .. " ›"
	card.Travel.BackgroundColor3 = if t.Ok then K.Travel else K.Off
	card.Reason.Text = if t.Ok then (t.Reason or (if t.Cost then ("⚡ %d · %s"):format(t.Cost, NavInfo.distanceText(t.Dist or 0)) else "")) else (t.Reason or "")
end

-- VIAJAR: siempre por el camino de siempre (y si no se puede, por qué)
function GalaxyMapUI.travel(): GalaxyMap.Travel?
	local e = entryById(state.Selected)
	if not e then
		return nil
	end
	local t = GalaxyMap.travel(e, travelState())
	if not t.Ok then
		toast("Info", t.Reason or "No se puede viajar ahí ahora")
		GalaxyMapUI._paintCard()
		return t
	end
	if t.Action == "Quantum" and t.Dest then
		local ok, why = call("quantumTo", t.Dest, e.Name)
		if ok == false then
			toast("Info", "⛔ " .. tostring(why or "No se puede saltar ahora"))
			return t
		end
		GalaxyMapUI.close()
	elseif t.Action == "Home" then
		call("home")
		GalaxyMapUI.close()
	elseif t.Action == "Route" then
		call("route", Access.Port, "Puerto espacial")
		if t.Reason then
			toast("Info", t.Reason)
		end
		GalaxyMapUI.close()
	end
	return t
end

local function buildTabs(parent: Instance, lay: Layout.Layout)
	for _, id in Layout.Tabs do
		local r = lay.Rects["Tab_" .. id]
		local selected = id == "Mapa"
		local b = create("TextButton", {
			Name = "Pestana_" .. id,
			Position = UDim2.fromOffset(r.X, r.Y),
			Size = UDim2.fromOffset(r.W, r.H),
			BackgroundColor3 = if selected then rgb(24, 70, 150) else K.Panel,
			BackgroundTransparency = if selected then 0.05 else 0.2,
			Text = "",
			AutoButtonColor = true,
			ZIndex = 30,
			Parent = parent,
		}, {
			create("UICorner", { CornerRadius = UDim.new(0, 10) }),
			create("UIStroke", { Color = K.Edge, Thickness = if selected then 2.5 else 1.2, Transparency = if selected then 0 else 0.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		})
		local icon = ({ Mapa = "🪐", Misiones = "◈", Inventario = "🎒", Personaje = "👤", Ajustes = "⚙" })[id]
		label({ Name = "Icono", Position = UDim2.fromScale(0, 0.04), Size = UDim2.fromScale(1, 0.5), Text = icon, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 31, Parent = b })
		local text = label({ Name = "Texto", Position = UDim2.fromScale(0.04, 0.56), Size = UDim2.fromScale(0.92, 0.38), Text = Layout.TabText[id], TextScaled = true, Font = Theme.FontBold, TextColor3 = if selected then K.Text else K.Muted, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 31, Parent = b })
		create("UITextSizeConstraint", { MaxTextSize = lay.Text.Small, MinTextSize = 9, Parent = text })
		b.Activated:Connect(function()
			GalaxyMapUI.tab(id)
		end)
	end
end

-- Pestañas: abren los paneles que YA existen (nada duplicado)
GalaxyMapUI.TabCommands = { Misiones = "Misiones", Inventario = "Mochila", Personaje = "Personaje", Ajustes = "Menu" }
function GalaxyMapUI.tab(id: string)
	local command = GalaxyMapUI.TabCommands[id]
	if not command then
		return
	end
	GalaxyMapUI.close()
	call("runCommand", command)
end

local function buildLogo(parent: Instance, lay: Layout.Layout)
	local r = lay.Rects.Logo
	if not r then
		return
	end
	local f = create("Frame", { Name = "Logo", Position = UDim2.fromOffset(r.X, r.Y), Size = UDim2.fromOffset(r.W, r.H), BackgroundTransparency = 1, ZIndex = 30, Parent = parent })
	label({ Name = "Emblema", Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(r.H, r.H), Text = "✦", TextScaled = true, TextColor3 = K.Title, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 31, Parent = f })
	local t1 = label({ Name = "Heroes", Position = UDim2.fromOffset(r.H + 4, r.H * 0.08), Size = UDim2.new(1, -r.H - 4, 0.46, 0), Text = "HEROES", TextScaled = true, Font = Theme.FontBold, ZIndex = 31, Parent = f })
	local t2 = label({ Name = "History", Position = UDim2.fromOffset(r.H + 4, r.H * 0.52), Size = UDim2.new(1, -r.H - 4, 0.4, 0), Text = "OF HISTORY", TextScaled = true, Font = Theme.FontBold, TextColor3 = K.Title, ZIndex = 31, Parent = f })
	for _, l in { t1, t2 } do
		create("UIStroke", { Color = rgb(10, 20, 50), Thickness = 2, Parent = l })
	end
end

local function setDrawer(name: string?)
	state.Drawer = if state.Drawer == name then nil else name
	for _, id in { "LegendDrawer", "MissionsDrawer" } do
		local f = state.Parts[id]
		if f then
			f.Visible = state.Drawer == id
		end
	end
end
GalaxyMapUI.setDrawer = setDrawer

local function smallButton(parent: Instance, name: string, r: Layout.Rect, text: string, lay: Layout.Layout, onTap: () -> ()): TextButton
	local b = create("TextButton", {
		Name = name,
		Position = UDim2.fromOffset(r.X, r.Y),
		Size = UDim2.fromOffset(r.W, r.H),
		BackgroundColor3 = K.Panel,
		BackgroundTransparency = 0.15,
		Text = text,
		TextSize = lay.Text.Small,
		Font = Theme.FontBold,
		TextColor3 = K.Text,
		TextWrapped = true,
		AutoButtonColor = true,
		ZIndex = 30,
		Parent = parent,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 10) }),
		create("UIStroke", { Color = K.Edge, Thickness = 1.5, Transparency = 0.3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	})
	b.Activated:Connect(onTap)
	return b
end

---------------------------------------------------------------------
-- La ficha (cada segundo, con el mapa abierto)
---------------------------------------------------------------------
local function paintPlayer()
	local card = state.Parts.Player
	if not card then
		return
	end
	local snap = state.Snap or {}
	local health, maxHealth = 100, 100
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		health, maxHealth = humanoid.Health, math.max(humanoid.MaxHealth, 1)
	end
	local energy = tonumber(player:GetAttribute("Energy")) or 100
	local xp, xpNext = tonumber(player:GetAttribute("Xp")) or 0, math.max(tonumber(player:GetAttribute("XpNext")) or 1, 1)
	card.set({
		Name = player.DisplayName,
		Level = tonumber(player:GetAttribute("Level")) or 1,
		Money = Format.money(tonumber(player:GetAttribute("Money")) or 0),
		UserId = player.UserId,
		Bars = {
			{ K = health / maxHealth, Color = rgb(235, 60, 70) },
			{ K = energy / 100, Color = rgb(60, 160, 255) },
			{ K = xp / xpNext, Color = rgb(90, 220, 110) },
		},
		Counters = {
			{ Icon = "✨", Text = tostring(snap.Chispas or 0), Color = rgb(255, 220, 120) },
			{ Icon = "⛏", Text = ("%d/%d"):format(snap.Cargo or 0, snap.CargoMax or 0), Color = rgb(255, 180, 90) },
			{ Icon = "💎", Text = tostring(snap.Crystals or 0), Color = rgb(150, 220, 255) },
		},
	})
end

local function paintNeedle()
	local needle = state.Parts.Needle
	local camera = workspace.CurrentCamera
	if needle and camera then
		needle.Rotation = NavInfo.heading(camera.CFrame.LookVector)
	end
end

---------------------------------------------------------------------
-- Montar la pantalla
---------------------------------------------------------------------
local function viewport(): Vector2
	local gui = state.Gui
	if gui and gui.AbsoluteSize.X > 10 then
		return gui.AbsoluteSize
	end
	local camera = workspace.CurrentCamera
	return if camera then camera.ViewportSize else Vector2.new(1280, 720)
end

local function render()
	local gui = state.Gui
	if not gui then
		return
	end
	if state.Canvas then
		state.Canvas:Destroy()
	end
	state.Items = {}
	state.Parts = {}
	state.Card = nil
	state.Drawer = nil
	local vp = viewport()
	state.Viewport = vp
	local lay = Layout.layout(vp)
	state.Layout = lay
	refreshEntries()
	state.Spots = Layout.arrange(lay, state.Entries, GalaxyMap.place)
	if not entryById(state.Selected) then
		local here = nil
		for _, e in state.Entries do
			if e.Here and (e.Kind == "Planet" or e.Kind == "Center") then
				here = e.Id
			end
		end
		state.Selected = here or "Valmar"
	end
	local canvas = create("Frame", { Name = "Lienzo", Size = UDim2.fromOffset(lay.Canvas.X, lay.Canvas.Y), BackgroundTransparency = 1, ZIndex = 5, Parent = gui })
	create("UIScale", { Scale = lay.Scale, Parent = canvas })
	state.Canvas = canvas
	-- La galaxia (se arrastra y se acerca)
	local ring = create("Frame", { Name = "Galaxia", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 6, Active = true, Parent = canvas })
	state.Ring = ring
	-- (se arrastra tocando el fondo de la galaxia: los planetas son botones encima)
	ring.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			state.Drag = { Input = input, Last = input.Position }
		end
	end)
	state.Parts.Orbit = create("Frame", { Name = "Orbita", AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 7, Parent = ring }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = rgb(170, 200, 255), Thickness = 1.5, Transparency = 0.55 }),
	})
	state.Parts.InnerOrbit = create("Frame", { Name = "OrbitaDentro", AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 7, Parent = ring }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = rgb(170, 200, 255), Thickness = 1, Transparency = 0.75 }),
	})
	for _, e in state.Entries do
		local spot = state.Spots[e.Id]
		if spot then
			buildItem(ring, e, lay, spot)
		end
	end
	if lay.Ring.PoiZoom > 1 then
		local g = lay.Rects.Galaxy
		state.Parts.ZoomHint = label({ Name = "Pista", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromOffset(g.X + g.W / 2, g.Y + g.H - 2), Size = UDim2.fromOffset(420, 22), Text = "Pellizca o toca Valmar para ver estaciones y campos", TextSize = lay.Text.Small, TextColor3 = K.Muted, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.6, ZIndex = 8, Parent = ring })
	end
	-- Paneles
	buildTitle(canvas, lay)
	buildCompass(canvas, lay)
	local pr = lay.Rects.Player
	local playerHolder = create("Frame", { Name = "FichaJugador", Position = UDim2.fromOffset(pr.X, pr.Y), Size = UDim2.fromOffset(pr.W, pr.H), BackgroundTransparency = 1, ZIndex = 30, Parent = canvas })
	state.Parts.Player = PlayerCard.new(playerHolder, { Compact = not lay.Wide, ZIndex = 30 })
	if lay.Wide then
		buildLegend(canvas, lay.Rects.Legend, lay, "Leyenda")
		buildMissions(canvas, lay.Rects.Missions, lay, "Misiones")
	else
		smallButton(canvas, "BotonLeyenda", lay.Rects.LegendBtn, "✦ LEYENDA", lay, function()
			setDrawer("LegendDrawer")
		end)
		smallButton(canvas, "BotonMisiones", lay.Rects.MissionsBtn, "◆ MISIONES", lay, function()
			setDrawer("MissionsDrawer")
		end)
		local legend = buildLegend(canvas, lay.Rects.LegendDrawer, lay, "LegendDrawer")
		legend.Visible = false
		legend.ZIndex = 40
		local missions = buildMissions(canvas, lay.Rects.MissionsDrawer, lay, "MissionsDrawer")
		missions.Visible = false
		state.Parts.LegendDrawer = legend
		state.Parts.MissionsDrawer = missions
		for _, d in { legend, missions } do
			local x = create("TextButton", { Name = "Cerrar", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(math.max(44, 44 / lay.Scale), math.max(44, 44 / lay.Scale)), BackgroundTransparency = 1, Text = "✕", TextSize = lay.Text.Name + 2, Font = Theme.FontBold, TextColor3 = K.Text, ZIndex = 41, Parent = d })
			x.Activated:Connect(function()
				setDrawer(nil)
			end)
		end
	end
	buildCard(canvas, lay)
	buildTabs(canvas, lay)
	buildLogo(canvas, lay)
	local close = smallButton(canvas, "Cerrar", lay.Rects.Close, "✕", lay, function()
		GalaxyMapUI.close()
	end)
	close.TextSize = lay.Text.Title
	placeItems()
	select(state.Selected :: string)
	paintMissions()
	paintPlayer()
	paintNeedle()
end
GalaxyMapUI._render = render

-- Arrastrar (un dedo o el ratón), pellizcar y la rueda
local function bindInput()
	local function scaleNow(): number
		return if state.Layout then state.Layout.Scale else 1
	end
	table.insert(state.Conns, UserInputService.InputBegan:Connect(function(input, processed)
		if not state.Open then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape and not processed then
			GalaxyMapUI.close()
		end
	end))

	table.insert(state.Conns, UserInputService.InputChanged:Connect(function(input)
		if not state.Open then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			local p = input.Position
			zoomTo(state.Zoom * (if input.Position.Z > 0 then 1.15 else 1 / 1.15), Vector2.new(p.X, p.Y) / scaleNow())
			return
		end
		local drag = state.Drag
		if drag and (input == drag.Input or input.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = input.Position - drag.Last
			drag.Last = input.Position
			if state.Zoom > 1.001 then
				state.Pan = state.Pan + Vector2.new(d.X, d.Y) / scaleNow()
				placeItems()
			end
		end
	end))
	table.insert(state.Conns, UserInputService.InputEnded:Connect(function(input)
		if state.Drag and (input == state.Drag.Input or input.UserInputType == Enum.UserInputType.MouseButton1) then
			state.Drag = nil
		end
	end))
	table.insert(state.Conns, UserInputService.TouchPinch:Connect(function(_touches, scale, _velocity, inputState)
		if not state.Open then
			return
		end
		if inputState == Enum.UserInputState.Begin then
			state.PinchFrom = state.Zoom
		elseif inputState == Enum.UserInputState.Change then
			state.Drag = nil
			zoomTo((state.PinchFrom or state.Zoom) * scale)
		end
	end))
end

local function ensureGuis()
	if state.Gui and state.Gui.Parent then
		return
	end
	local pg = player:WaitForChild("PlayerGui")
	local back = create("ScreenGui", { Name = "MapaGalacticoFondo", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 7, Enabled = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = pg })
	buildBackground(back)
	-- (lo de encima, dentro de la zona segura del móvil: muescas y esquinas redondas)
	local gui = create("ScreenGui", { Name = "MapaGalactico", ResetOnSpawn = false, IgnoreGuiInset = true, ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets, DisplayOrder = 8, Enabled = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = pg })
	state.Back = back
	state.Gui = gui
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if state.Open and state.Viewport and (gui.AbsoluteSize - state.Viewport).Magnitude > 2 then
			render()
		end
	end)
	-- (las cinemáticas apagan y encienden pantallas: el mapa solo se ve si está abierto)
	for _, g in { back, gui } do
		g:GetPropertyChangedSignal("Enabled"):Connect(function()
			if g.Enabled ~= state.Open then
				g.Enabled = state.Open
			end
		end)
	end
end

---------------------------------------------------------------------
-- Abrir y cerrar
---------------------------------------------------------------------
function GalaxyMapUI.isOpen(): boolean
	return state.Open
end

function GalaxyMapUI.open(select_: string?)
	if state.Open then
		return
	end
	call("closeOthers", "GalaxyMap")
	ensureGuis()
	state.Open = true
	state.Zoom, state.Pan = 1, Vector2.new(0, 0)
	if select_ then
		state.Selected = select_
	end
	if remote then
		remote:FireServer("Get")
	end
	render()
	;(state.Back :: ScreenGui).Enabled = true
	;(state.Gui :: ScreenGui).Enabled = true
	bindInput()
	state.Tick += 1
	local tick = state.Tick
	task.spawn(function()
		while state.Open and state.Tick == tick do
			task.wait(1)
			if not (state.Open and state.Tick == tick) then
				break
			end
			pcall(function()
				paintMissions()
				paintPlayer()
				paintNeedle()
				GalaxyMapUI._paintCard()
			end)
		end
	end)
end

function GalaxyMapUI.close()
	if not state.Open then
		return
	end
	state.Open = false
	state.Tick += 1
	for _, c in state.Conns do
		c:Disconnect()
	end
	state.Conns = {}
	if state.Gui then
		state.Gui.Enabled = false
	end
	if state.Back then
		state.Back.Enabled = false
	end
end

function GalaxyMapUI.toggle()
	if state.Open then
		GalaxyMapUI.close()
	else
		GalaxyMapUI.open()
	end
end

-- ¿La M y «Mapa» abren la galaxia en lugar del mapa de Valmar? En el espacio o en un planeta, sí
function GalaxyMapUI.wanted(): boolean
	if player:GetAttribute("Planeta") ~= nil then
		return true
	end
	local ship = call("ship")
	return type(ship) == "table" and (ship.World == "Cosmos" or ship.World == "Planet")
end

local function onSnapshot(snap: any)
	if type(snap) ~= "table" then
		return
	end
	state.Snap = snap
	if state.Open then
		render()
	end
end
GalaxyMapUI._onSnapshot = onSnapshot

function GalaxyMapUI.init(d: { [string]: any }?)
	deps = d or {}
	call("registerBig", "GalaxyMap", GalaxyMapUI.close, GalaxyMapUI.isOpen)
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
		local r = remotes and remotes:WaitForChild("GalaxyMap", 30)
		if r and r:IsA("RemoteEvent") then
			remote = r
			r.OnClientEvent:Connect(function(kind, payload)
				if kind == "Snapshot" then
					local ok, err = pcall(onSnapshot, payload)
					if not ok then
						warn("[GalaxyMap] " .. tostring(err))
					end
				end
			end)
		end
	end)
	-- (si cambia de cinemática, se cierra: no tapa la escena)
	player:GetAttributeChangedSignal("InCinematic"):Connect(function()
		if player:GetAttribute("InCinematic") then
			GalaxyMapUI.close()
		end
	end)
end

-- (pruebas)
GalaxyMapUI._state = state
GalaxyMapUI._setRemote = function(r: any)
	remote = r
end

return GalaxyMapUI
