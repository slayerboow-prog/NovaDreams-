-- TouchLayout: los botones de acción (móvil) y sus teclas (ordenador y mando), todos en un solo sitio.
--
-- Cada sistema registra sus botones y este módulo decide dónde van y cuándo se ven, para que nada
-- se pise (los huecos salen de UI/HudLayout):
--
--   TouchLayout.register({
--       Id = "Ataque", Icon = "espada", Label = "Ataque",
--       Slot = "Ataque",            -- (opcional) hueco fijo del racimo; sin Slot va a la columna de contexto
--       Priority = 10,               -- (opcional) orden en la columna de contexto (más bajo = más arriba)
--       Visible = function() return puedoPegar() end, -- (opcional) cuándo sale
--       Callback = function() pegar() end,             -- al tocarlo
--       Hold = function(down) defender(down) end,      -- (opcional) mantener pulsado
--       Active = function() return corriendo end,      -- (opcional) encendido: true (azul) o "wait" (ámbar)
--       Meter = function() return 0.7 end,              -- (opcional) barrita dentro del botón (0..1, nil = sin)
--       Badge = function() return "×3" end,            -- (opcional) numerito en la esquina
--       Key = "X", Pad = "RB",                          -- tecla y botón del mando (para las pistas)
--   })
--   TouchLayout.refresh()        -- vuelve a mirar Visible/Active/Badge (también se hace solo, 2 veces por segundo)
--   TouchLayout.setLabel(id, t)  -- cambia el texto (p. ej. Interactuar -> "Hablar")
--   TouchLayout.setIcon(id, i)   -- cambia el icono (la burbuja «Acciones» enseña el de la primera acción)
--   TouchLayout.setDriving(true) -- al volante (móvil): otra colocación (HudLayout.DriveSlots). Solo tienen
--                                   hueco los que dicen DriveSlot = "…" (pedales, flechas, luces…); los
--                                   demás van a los huecos de contexto de esa colocación
--   TouchLayout.setFlying(true)  -- a los mandos de un avión (Controllers/Flying): HudLayout.FlySlots. Solo
--                                   salen los que dicen FlySlot = "…" (motor, timón, frenos, tren…); los
--                                   demás se esconden (en el ordenador, la lista de teclas igual)
-- Campos para conducir: DriveSlot (hueco al volante), Shape = "Pedal" | "Arrow" (rectángulo redondeado en
-- lugar de círculo; "Arrow" dibuja una flecha grande), Chevron (giro de la flecha: 180 = ◀, 0 = ▶) y
-- Tint (color del disco interior cuando no está encendido: verde el acelerador, rojo el freno…).
--
-- Móvil y tableta: botones redondos oscuros con borde azul, icono y texto, en racimo pegado a la esquina
-- de abajo a la derecha (HudLayout.Cluster, como docs/referencias/hud-movil-botones.jpg): Interactuar
-- arriba a la derecha; Correr, Defensa y Saltar; Agacharse, el Atacar grande y Esquivar. Los de
-- contexto (linterna, piedra, fijar, bajarse, sirena…) en una columna pequeña a la izquierda que se
-- llena desde abajo, solo cuando sirven. A la izquierda, debajo del joystick, Teléfono e Inventario
-- (Shape = "Side": botón redondo con el texto al lado) y, con un arma, el segundo Disparar.
-- Nunca salen dos botones con el mismo texto. Ordenador y mando: sin botones; en su lugar, una lista
-- pequeña de teclas abajo a la derecha. Si hay un mando conectado, debajo de cada botón redondo sale su
-- letra (Y, A, X, RB…).
--
-- Huecos: Ataque, Interactuar, Correr, Defender, Saltar, Agacharse, Esquivar, Contexto, Telefono,
-- Inventario, DispararIzq (y Extra1-5). Un Slot que no existe (Gestos, Fijar) = columna de contexto.
-- Si dos botones visibles piden el mismo hueco, se lo queda el de Priority más baja y el otro pasa
-- a la columna de contexto. Alias para las armas (estilo shooter móvil): Slot = "Disparar" usa el hueco
-- del Ataque, "Apuntar" el de Defender (encima del disparo) y "Recargar" el de Interactuar.
-- Más campos: BadgeColor (color del numerito: rojo en Teléfono). Cada botón sigue a SU dedo: varios a
-- la vez (joystick + Disparar + Apuntar + Saltar) no se estorban. Arrastrar el dedo de un botón no gira
-- la cámara: la gira la de Roblox con otro dedo en la pantalla.
--
-- Compatibilidad (API anterior de este módulo): TouchLayout.slot(nombre), place(botón, nombre),
-- placeAction(ContextActionService, acción, nombre), riding() y showWhen(botón, "Pie"|"Vehiculo").

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Theme)
local Icons = require(script.Parent.Icons)
local HudLayout = require(script.Parent.HudLayout)
local Dialog = require(script.Parent.Dialog)

local create = Theme.create
local H = Theme.Hud
local rgb = Color3.fromRGB

local TouchLayout = {}

export type Spec = {
	Id: string,
	Icon: string,
	Label: string,
	Slot: string?,
	Priority: number?,
	Visible: (() -> boolean)?,
	Callback: (() -> ())?,
	Hold: ((boolean) -> ())?,
	Active: (() -> (boolean | string))?,
	Meter: (() -> number?)?,
	Badge: (() -> string?)?,
	Key: string?,
	Pad: string?,
	DriveSlot: string?,
	FlySlot: string?,
	Shape: string?,
	Chevron: number?,
	Tint: Color3?,
	BadgeColor: Color3?,
}

type View = { Button: TextButton, Label: TextLabel, Icon: Frame, Badge: TextLabel, Stroke: UIStroke, Fill: Frame, Meter: Frame, MeterFill: Frame, Active: any, Tint: Color3?, Conns: { RBXScriptConnection }? }

local specs: { [string]: Spec } = {}
local order: { string } = {}
local views: { [string]: View } = {}
local labels: { [string]: string } = {}
local icons: { [string]: string } = {} -- iconos cambiados con setIcon
local busy = false
local swimHidden: { [string]: boolean }? = nil -- nadando: estos no salen (DivingUI, Shared/Swim.HiddenButtons)
local gui: ScreenGui? = nil
local hintsPanel: Frame? = nil
local touch = false
local started = false
local driving = false -- al volante (móvil): colocación de conducir
local flying = false -- a los mandos de un avión: colocación de volar (manda sobre la de conducir)
local phoneOpen = false -- el ValPhone abierto tapa la esquina de abajo a la izquierda

-- Botón «⋯» (móvil): cuando hay más botones de contexto que huecos, pasa de página
local MORE_ID = "MasBotones"
local extraPage = 1
local moreBadge: string? = nil

-- Huecos con otro nombre (armas: van donde los golpes)
local SLOT_ALIAS = { Disparar = "Ataque", Apuntar = "Defender", Recargar = "Interactuar" }

-- Colores del racimo (la referencia: disco azul marino oscuro, borde azul brillante, icono blanco)
local DISC_TOP = rgb(34, 52, 96)
local DISC_BOTTOM = rgb(8, 14, 34)
local RIM = rgb(80, 185, 255)

local function safe(fn: (() -> any)?, default: any): any
	if not fn then
		return default
	end
	local ok, value = pcall(fn)
	if ok then
		return value
	end
	return default
end

---------------------------------------------------------------------
-- Botón redondo: icono arriba y el texto debajo, dentro del círculo
---------------------------------------------------------------------
local function runCallback(spec: Spec)
	if spec.Callback then
		local ok, err = pcall(spec.Callback)
		if not ok then
			warn("[Botones] " .. tostring(err))
		end
	end
	task.defer(TouchLayout.refresh)
end

-- Botón redondo con el texto AL LADO (Teléfono, Inventario: docs/referencias/hud-movil-joystick.jpg).
-- El botón ocupa todo el hueco (disco + texto): los toques en el texto también cuentan.
local function buildSideView(spec: Spec): View
	local button = create("TextButton", {
		Name = spec.Id,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(176, 68),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		Parent = gui,
	})
	-- El texto, en una pastilla oscura que sale de detrás del disco
	create("Frame", {
		Name = "Pill",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromScale(0.8, 0.6),
		BackgroundColor3 = DISC_BOTTOM,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Parent = button,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local disc = create("Frame", {
		Name = "Disc",
		Size = UDim2.fromScale(1, 1),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundColor3 = H.Navy,
		BackgroundTransparency = 0.2,
		Parent = button,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(DISC_TOP, DISC_BOTTOM) }),
	})
	local stroke = Theme.edge(disc, RIM, 2.5)
	Theme.halo(disc, H.Glow, 6, 999)
	local fill = create("Frame", {
		Name = "Fill",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.84, 0.84),
		BackgroundColor3 = H.Navy,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Parent = disc,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local icon = Icons.new(spec.Icon, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.5, 0.5),
		Parent = disc,
	})
	local label = Theme.label({
		Name = "Caption",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.44, 0.5),
		Size = UDim2.fromScale(0.54, 0.38),
		Text = spec.Label,
		Font = Theme.FontBold,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextStrokeTransparency = 0.5,
		Parent = button,
	})
	-- Globito (rojo en Teléfono: los avisos sin leer del ValPhone)
	local badge = Theme.label({
		Name = "Badge",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.86, 0.12),
		Size = UDim2.fromScale(0.42, 0.42),
		BackgroundColor3 = spec.BadgeColor or H.Gold,
		BackgroundTransparency = 0,
		Font = Theme.FontBold,
		TextScaled = true,
		TextColor3 = if spec.BadgeColor then Color3.new(1, 1, 1) else Theme.Colors.Ink,
		TextXAlignment = Enum.TextXAlignment.Center,
		Visible = false,
		ZIndex = 3,
		Parent = disc,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = badge })
	local meter = create("Frame", { Name = "Meter", Visible = false, BackgroundTransparency = 1, Parent = disc })
	local meterFill = create("Frame", { Name = "MeterFill", BackgroundTransparency = 1, Parent = meter })
	Theme.pressable(button)
	button.Activated:Connect(function()
		runCallback(spec)
	end)
	return { Button = button, Label = label, Icon = icon, Badge = badge, Stroke = stroke, Fill = fill, Meter = meter, MeterFill = meterFill, Tint = spec.Tint }
end

local function buildView(spec: Spec): View
	if spec.Shape == "Side" then
		return buildSideView(spec)
	end
	local big = spec.Slot ~= nil and (SLOT_ALIAS[spec.Slot] or spec.Slot) == "Ataque"
	-- Pedales y flechas: rectángulos redondeados (el resto, círculos)
	local boxy = spec.Shape == "Pedal" or spec.Shape == "Arrow"
	local round = if boxy then UDim.new(0.22, 0) else UDim.new(1, 0)
	local button = create("TextButton", {
		Name = spec.Id,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(88, 88),
		BackgroundColor3 = H.Navy,
		BackgroundTransparency = 0.2,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		Parent = gui,
	}, {
		create("UICorner", { CornerRadius = round }),
		create("UIGradient", { Rotation = 90, Color = if boxy then ColorSequence.new(rgb(120, 170, 255), rgb(40, 60, 120)) else ColorSequence.new(DISC_TOP, DISC_BOTTOM) }),
	})
	local stroke = Theme.edge(button, if boxy then nil else RIM, if big or boxy then 4 else 2.5)
	Theme.halo(button, H.Glow, if big then 10 else 6, if boxy then 18 else 999)
	-- Disco interior más oscuro (da relieve de botón)
	local fill = create("Frame", {
		Name = "Fill",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = if boxy then UDim2.fromScale(0.9, 0.92) else UDim2.fromScale(0.84, 0.84),
		BackgroundColor3 = spec.Tint or H.Navy,
		BackgroundTransparency = if spec.Tint then 0.2 else 0.45,
		BorderSizePixel = 0,
		Parent = button,
	}, { create("UICorner", { CornerRadius = round }) })
	local icon: Frame
	if spec.Chevron then
		-- Flecha de girar: dibujada (grande y sin depender de la fuente)
		icon = Icons.chevron({
			Name = "Icon",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.42),
			Size = UDim2.fromScale(0.5, 0.5),
			Rotation = spec.Chevron,
			Thickness = 7,
			Parent = button,
		})
		create("UIAspectRatioConstraint", { AspectRatio = 1, Parent = icon })
	else
		icon = Icons.new(spec.Icon, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, if boxy then 0.38 else 0.4),
			Size = if boxy then UDim2.fromScale(0.6, 0.34) else UDim2.fromScale(0.44, 0.44),
			Parent = button,
		})
		if boxy then
			create("UIAspectRatioConstraint", { AspectRatio = 1, Parent = icon })
		end
	end
	local label = Theme.label({
		Name = "Caption",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, if boxy then 0.74 else 0.66),
		Size = if boxy then UDim2.fromScale(0.9, 0.14) else UDim2.fromScale(0.96, 0.2),
		Text = spec.Label,
		Font = Theme.FontBold,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.5,
		Parent = button,
	})
	local badge = Theme.label({
		Name = "Badge",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1.02, -0.02),
		Size = UDim2.fromScale(0.42, 0.26),
		BackgroundColor3 = spec.BadgeColor or H.Gold,
		BackgroundTransparency = 0,
		Font = Theme.FontBold,
		TextScaled = true,
		TextColor3 = if spec.BadgeColor then Color3.new(1, 1, 1) else Theme.Colors.Ink,
		TextXAlignment = Enum.TextXAlignment.Center,
		Visible = false,
		Parent = button,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = badge })
	-- Barrita (p. ej. la estamina en Correr)
	local meter = create("Frame", {
		Name = "Meter",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.95),
		Size = UDim2.fromScale(0.5, 0.05),
		BackgroundColor3 = H.Track,
		BorderSizePixel = 0,
		Visible = false,
		Parent = button,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local meterFill = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = H.SelectLight, BorderSizePixel = 0, Parent = meter }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	-- Con mando: su letra debajo del botón (Y, A, X, RB…)
	if spec.Pad then
		local pad = Theme.label({
			Name = "Pad",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 1),
			Size = UDim2.fromOffset(30, 18),
			BackgroundColor3 = H.Navy,
			BackgroundTransparency = 0.1,
			Text = spec.Pad,
			Font = Theme.FontBold,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Center,
			Visible = UserInputService.GamepadEnabled,
			ZIndex = 3,
			Parent = button,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = pad })
		create("UIStroke", { Color = H.Glow, Thickness = 1, Transparency = 0.3, Parent = pad })
	end
	Theme.pressable(button)

	button.Activated:Connect(function()
		runCallback(spec)
	end)
	local conns: { RBXScriptConnection } = {}
	if spec.Hold then
		-- Cada botón sigue a SU dedo: otro dedo (joystick, Apuntar, Saltar…) ni lo suelta ni lo cambia
		local holding: InputObject? = nil
		button.InputBegan:Connect(function(input)
			local kind = input.UserInputType
			if holding and holding ~= input and kind == Enum.UserInputType.Touch then
				return -- (ya hay un dedo en este botón)
			end
			if kind == Enum.UserInputType.Touch or kind == Enum.UserInputType.MouseButton1 then
				holding = input
				pcall(spec.Hold :: any, true)
			end
		end)
		local function release(input: InputObject)
			local mouse = input.UserInputType == Enum.UserInputType.MouseButton1
			if holding and (input == holding or (mouse and holding.UserInputType == Enum.UserInputType.MouseButton1)) then
				holding = nil
				pcall(spec.Hold :: any, false)
			end
		end
		button.InputEnded:Connect(release)
		-- (si el dedo sale del botón, InputEnded llega igual a UserInputService). Estas conexiones son
		-- de UserInputService, no del botón: se guardan para cortarlas al quitarlo (destroyView)
		table.insert(conns, UserInputService.InputEnded:Connect(release))
	end
	return { Button = button, Label = label, Icon = icon, Badge = badge, Stroke = stroke, Fill = fill, Meter = meter, MeterFill = meterFill, Tint = spec.Tint, Conns = conns }
end

-- Quita un botón: corta sus conexiones a UserInputService y lo destruye
local function destroyView(view: View)
	for _, conn in view.Conns or {} do
		conn:Disconnect()
	end
	view.Conns = nil
	view.Button:Destroy()
end

local WAIT = rgb(200, 145, 30) -- pedido pero aún no (ámbar)
local function paintActive(view: View, state: any)
	local on = state == true or state == "on"
	local waiting = state == "wait"
	local key = if on then "on" elseif waiting then "wait" else "off"
	if view.Active == key then
		return
	end
	view.Active = key
	local tint = view.Tint
	TweenService:Create(view.Fill, Theme.Fast, {
		BackgroundColor3 = if on then (if tint then tint:Lerp(Color3.new(1, 1, 1), 0.35) else H.Select) elseif waiting then WAIT else tint or H.Navy,
		BackgroundTransparency = if on or waiting then 0.05 elseif tint then 0.2 else 0.45,
	}):Play()
end

---------------------------------------------------------------------
-- Pistas de teclado y mando (ordenador y consola)
---------------------------------------------------------------------
local function usingGamepad(): boolean
	if not UserInputService.GamepadEnabled then
		return false
	end
	local ok, last = pcall(function()
		return UserInputService:GetLastInputType()
	end)
	return ok and last ~= nil and string.find(last.Name, "Gamepad", 1, true) ~= nil
end

local HINT_ROWS = 7
local function refreshHints(visible: { Spec })
	local panel = hintsPanel
	if not panel then
		return
	end
	local pad = usingGamepad()
	local shown = 0
	for i = 1, HINT_ROWS do
		local row = panel:FindFirstChild("Row" .. i) :: Frame?
		if row then
			row.Visible = false
		end
	end
	for _, spec in visible do
		local key = if pad then spec.Pad else spec.Key
		if key and shown < HINT_ROWS then
			shown += 1
			local row = panel:FindFirstChild("Row" .. shown) :: Frame
			row.Visible = true
			Theme.setText(row:FindFirstChild("Key") :: TextLabel, key)
			Theme.setText(row:FindFirstChild("Text") :: TextLabel, labels[spec.Id] or spec.Label)
			Icons.set(row:FindFirstChild("Icon") :: Frame, spec.Icon)
		end
	end
	panel.Visible = shown > 0 and not busy
	-- Solo tan alto como las filas que hay (anclado abajo a la derecha: encoge hacia abajo)
	panel.Size = UDim2.fromOffset(panel.Size.X.Offset, 16 + shown * 26)
end

local function buildHints(parent: ScreenGui)
	local panel = Theme.hudPanel({ Name = "Hints", BackgroundTransparency = 0.45, CornerRadius = 10, Parent = parent })
	for i = 1, HINT_ROWS do
		local row = create("Frame", {
			Name = "Row" .. i,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 10, 1, -8 - (i - 1) * 26),
			Size = UDim2.new(1, -20, 0, 24),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = panel,
		})
		local key = Theme.label({
			Name = "Key",
			Size = UDim2.fromOffset(58, 22),
			BackgroundColor3 = H.NavyLight,
			BackgroundTransparency = 0.1,
			Font = Theme.FontBold,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = row,
		})
		create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = key })
		create("UIStroke", { Color = H.Edge, Transparency = 0.3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = key })
		Icons.new("mas", { Name = "Icon", Position = UDim2.fromOffset(66, 2), Size = UDim2.fromOffset(20, 20), Parent = row })
		Theme.label({ Name = "Text", Position = UDim2.fromOffset(94, 0), Size = UDim2.new(1, -94, 1, 0), TextSize = 15, TextStrokeTransparency = 0.6, Parent = row })
	end
	hintsPanel = panel
end

---------------------------------------------------------------------
-- Colocar: huecos fijos para los de siempre, la columna de contexto para los demás
---------------------------------------------------------------------
-- Con una ventana grande abierta, el botón que la abre se queda (para cerrarla con el mismo toque)
local KEEP_WITH_WINDOW = { Inventory = "Inventario", Help = "Ayuda" }

-- KO, muerto o en el suelo: como en una conversación, solo los botones Always
local function downed(): boolean
	local player = Players.LocalPlayer
	return (player:GetAttribute("KO") or player:GetAttribute("Dead") or player:GetAttribute("Fallen")) and true or false
end

local function visibleSpecs(): { Spec }
	local list = {}
	local stop = busy or downed()
	-- Móvil: con la mochila, el mapa, las misiones, una tienda… abiertas, los botones se apartan
	-- (antes quedaban encima de la ventana y se tocaban sin querer)
	local okWindow, window = pcall(Dialog.blockingOpen)
	local blocking = if touch and okWindow then window else nil
	local keep = blocking and KEEP_WITH_WINDOW[blocking]
	for _, id in order do
		local spec = specs[id]
		-- En conversaciones y cinemáticas (y KO o muerto) solo quedan los botones marcados Always (levantarse)
		local always = spec ~= nil and (spec :: any).Always == true
		local allowed = (not stop or always) and (not blocking or always or id == keep)
		if spec and allowed and not (swimHidden and swimHidden[id]) and safe(spec.Visible, true) then
			table.insert(list, spec)
		end
	end
	table.sort(list, function(a, b)
		return (a.Priority or 50) < (b.Priority or 50)
	end)
	return list
end

local warned: { [string]: boolean } = {}
local placeButton: (string, string?, { [string]: any }) -> ()

function TouchLayout.refresh()
	if not started then
		return
	end
	local visible = visibleSpecs()
	if flying then
		-- Volando solo cuentan los mandos del avión
		local only = {}
		for _, spec in visible do
			if spec.FlySlot then
				table.insert(only, spec)
			end
		end
		visible = only
	end
	if not touch then
		refreshHints(visible)
		return
	end
	local layout = HudLayout.current()
	-- Al volante: los huecos de conducir (pedales, flechas, luces…); solo los que piden DriveSlot.
	-- Volando: los de volar (FlySlot)
	local slots = if flying and layout.FlySlots then layout.FlySlots elseif driving and layout.DriveSlots then layout.DriveSlots else layout.Slots
	local taken: { [string]: boolean } = {}
	local placed: { [string]: string } = {}
	local extras: { Spec } = {}
	-- Nunca dos botones iguales a la vez (p. ej. dos «Agacharse»): si dos visibles dicen lo mismo, se
	-- queda el de Priority más baja
	local captions: { [string]: boolean } = {}
	for _, spec in visible do
		local caption = labels[spec.Id] or spec.Label
		-- (Twin: el segundo Disparar de la izquierda dice lo mismo que el grande a propósito)
		local twin = (spec :: any).Twin == true
		if captions[caption] and not twin then
			continue
		end
		if not twin then
			captions[caption] = true
		end
		local slot = if flying then spec.FlySlot elseif driving then spec.DriveSlot elseif spec.Slot then (SLOT_ALIAS[spec.Slot] or spec.Slot) else nil
		if phoneOpen and slot and HudLayout.Left[slot] then
			continue -- (el ValPhone abierto tapa la esquina: Teléfono, Inventario y el Disparar de la izquierda se esconden)
		end
		if slot and slots[slot] and not taken[slot] then
			taken[slot] = true
			placed[spec.Id] = slot
		else
			table.insert(extras, spec)
		end
	end
	local room = HudLayout.ExtraSlots
	if #extras > room and specs[MORE_ID] then
		-- Más botones de contexto que huecos (p. ej. con un arma: golpear, defender y fijar pasan aquí):
		-- el último hueco es «⋯» y cada toque enseña la página siguiente. Así ninguno desaparece.
		local per = room - 1
		local pages = math.ceil(#extras / per)
		if extraPage > pages then
			extraPage = 1
		end
		for i = 1, per do
			local spec = extras[(extraPage - 1) * per + i]
			if spec then
				placed[spec.Id] = "Extra" .. i
			end
		end
		placed[MORE_ID] = "Extra" .. room
		moreBadge = ("%d/%d"):format(extraPage, pages)
	else
		extraPage = 1
		for i, spec in extras do
			if i <= room then
				placed[spec.Id] = "Extra" .. i
			end
		end
	end
	-- Cada botón por separado: si uno falla (un icono, una función suya…), los demás salen igual
	-- (antes un error a medias dejaba sin pedales ni flechas al volante)
	for _, id in order do
		local ok, err = pcall(placeButton, id, placed[id], slots)
		if not ok and not warned[id] then
			warned[id] = true
			warn("[Botones] " .. id .. ": " .. tostring(err))
		end
	end
end

function placeButton(id: string, slot: string?, slots: { [string]: any })
	local spec = specs[id]
	local view = views[id]
	if slot and not slots[slot] then
		slot = nil -- (un hueco que no existe en esta colocación: mejor escondido que un error)
	end
	if slot and not view then
		view = buildView(spec)
		views[id] = view
		if icons[id] and not spec.Chevron then
			Icons.set(view.Icon, icons[id])
		end
	end
	if view then
		local was = view.Button.Visible
		view.Button.Visible = slot ~= nil
		if slot then
			HudLayout.apply(view.Button, slots[slot :: string])
			view.Button:SetAttribute("Slot", slot)
			if not was then
				-- aparece con un pequeño salto
				Theme.pop(view.Button, 1.12)
			end
			paintActive(view, safe(spec.Active, false))
			local meter = safe(spec.Meter, nil)
			view.Meter.Visible = type(meter) == "number"
			if type(meter) == "number" then
				view.MeterFill.Size = UDim2.fromScale(math.clamp(meter, 0, 1), 1)
				view.MeterFill.BackgroundColor3 = if meter < 0.2 then rgb(230, 80, 60) else H.SelectLight
			end
			local badge = safe(spec.Badge, nil)
			view.Badge.Visible = type(badge) == "string" and badge ~= ""
			if view.Badge.Visible then
				Theme.setText(view.Badge, badge)
				-- (las balas «12/90» necesitan una pastilla más ancha que un número)
				if spec.Shape ~= "Side" then
					local long = (utf8.len(badge) or #badge) > 3
					view.Badge.Size = if long then UDim2.fromScale(0.9, 0.26) else UDim2.fromScale(0.42, 0.26)
				end
			end
			Theme.setText(view.Label, labels[id] or spec.Label)
		end
	end
end

function TouchLayout.register(spec: Spec)
	if not specs[spec.Id] then
		table.insert(order, spec.Id)
	elseif views[spec.Id] then
		destroyView(views[spec.Id])
		views[spec.Id] = nil
	end
	specs[spec.Id] = spec
	TouchLayout.refresh()
end

function TouchLayout.unregister(id: string)
	specs[id] = nil
	local i = table.find(order, id)
	if i then
		table.remove(order, i)
	end
	if views[id] then
		destroyView(views[id])
		views[id] = nil
	end
	TouchLayout.refresh()
end

function TouchLayout.setLabel(id: string, text: string?)
	labels[id] = text
	local view = views[id]
	local spec = specs[id]
	if view and spec then
		Theme.setText(view.Label, text or spec.Label)
	end
end

function TouchLayout.setIcon(id: string, icon: string?)
	icons[id] = icon
	local view = views[id]
	local spec = specs[id]
	if view and spec and not spec.Chevron then
		Icons.set(view.Icon, icon or spec.Icon)
	end
end

-- Atenuado (p. ej. Interactuar sin nada delante)
function TouchLayout.setDim(id: string, dim: boolean)
	local view = views[id]
	if view then
		view.Button.BackgroundTransparency = if dim then 0.6 else 0.28
		view.Label.TextTransparency = if dim then 0.45 else 0
	end
end

-- El ValPhone abierto (Commands/CommandMenu): los botones de la esquina de abajo a la izquierda se
-- esconden (el teléfono los taparía); se cierra tocando fuera o con su barra de inicio
function TouchLayout.setPhoneOpen(value: boolean)
	if phoneOpen ~= value then
		phoneOpen = value
		TouchLayout.refresh()
	end
end

-- En conversaciones y cinemáticas no hay botones
function TouchLayout.setBusy(value: boolean)
	busy = value
	TouchLayout.refresh()
end

-- Nadando (DivingUI): fuera los botones de `hidden` (pelear, armas, gestos…); sus huecos quedan
-- para Bucear y Subir
function TouchLayout.setSwimming(on: boolean, hidden: { [string]: boolean }?)
	local want = if on then hidden or {} else nil
	if (want == nil) == (swimHidden == nil) then
		return
	end
	swimHidden = want
	TouchLayout.refresh()
end

-- Al volante (Driving): otra colocación en el móvil. Devuelve si ha cambiado.
function TouchLayout.setDriving(on: boolean): boolean
	if driving == on then
		return false
	end
	driving = on
	extraPage = 1
	TouchLayout.refresh()
	return true
end

function TouchLayout.isDriving(): boolean
	return driving
end

-- A los mandos de un avión (Controllers/Flying): colocación de volar. Devuelve si ha cambiado.
function TouchLayout.setFlying(on: boolean): boolean
	if flying == on then
		return false
	end
	flying = on
	extraPage = 1
	TouchLayout.refresh()
	return true
end

function TouchLayout.isFlying(): boolean
	return flying
end

-- ¿Se ven de verdad en pantalla todos estos botones? (Driving: el joystick solo se esconde si las
-- flechas y los pedales han salido; si algo falla, nunca te quedas sin forma de conducir)
function TouchLayout.shows(ids: { string }): boolean
	if not started or not touch then
		return false
	end
	for _, id in ids do
		local view = views[id]
		if not view or not view.Button.Parent or not view.Button.Visible then
			return false
		end
	end
	return true
end

function TouchLayout.isTouch(): boolean
	return touch
end

-- (pruebas) los botones creados
function TouchLayout.buttons(): { [string]: TextButton }
	local out = {}
	for id, view in views do
		out[id] = view.Button
	end
	return out
end

-- Saltar: el botón propio sustituye al de Roblox (se esconde, sin quitarle nada al personaje).
--
-- Antes solo hacía Humanoid.Jump = true al pulsar (y cada 0,1 s mientras se mantenía). En el móvil eso
-- casi nunca saltaba: Humanoid.Jump es una petición que el control de Roblox (ControlModule) vuelve a
-- escribir en cada fotograma con lo que dice SU botón de saltar (que aquí está escondido, o no existe
-- con el joystick propio), así que el true se borraba antes de llegar a la física; los reintentos
-- llegaban en Heartbeat, ya pasada la física. Y como el botón no dispara UserInputService.JumpRequest,
-- tampoco se enteraban el parkour ("Saltar valla"), levantarse de agachado ni dejar una pose (tumbado).
-- Ahora, como la barra espaciadora:
--   1) al pulsar se avisa a quien lo pida (TouchLayout.onJump: parkour, posturas, poses…); si alguno
--      se encarga (devuelve true), ya está;
--   2) si no, y estás de pie en el suelo (no sentado, ni en una conversación o una cinemática), salta
--      ya: Humanoid:ChangeState(Jumping), que no depende de nadie más. Correr no lo impide y la
--      carrera se conserva en el aire (la física del Humanoid mantiene la velocidad);
--   3) mientras se mantiene, Humanoid.Jump = true en cada fotograma justo DESPUÉS del control de
--      Roblox (BindToRenderStep, Input + 2), como si fuera su propio botón: sigue saltando al caer,
--      sube nadando… Al soltar, Jump = false (no se queda un salto pendiente).
-- No gasta ni pide energía ni estamina (con la energía a 0 se anda más despacio, pero se salta igual).
local JUMP_STEP = "SaltarTactil"
local jumpListeners: { (down: boolean, humanoid: Humanoid) -> boolean? } = {}

-- Quien quiera enterarse del botón Saltar (pulsar y soltar). Devolver true al pulsar = "ya me encargo".
function TouchLayout.onJump(listener: (down: boolean, humanoid: Humanoid) -> boolean?)
	table.insert(jumpListeners, listener)
end

-- Desde dónde se salta (de pie: andando, corriendo, parado, recién caído o levantándose)
local function jumpFrom(state: Enum.HumanoidStateType): boolean
	local S = Enum.HumanoidStateType
	return state == S.Running or state == S.RunningNoPhysics or state == S.Landed or state == S.GettingUp
end

-- ¿Puede saltar ahora mismo? (de pie en el suelo y sin nada que lo impida)
function TouchLayout.canJump(h: Humanoid): boolean
	local player = Players.LocalPlayer
	if h.Health <= 0 or h.SeatPart ~= nil or h.Sit or h.PlatformStand or h.JumpHeight <= 0 then
		return false
	end
	if player:GetAttribute("InDialogue") or player:GetAttribute("InCinematic") or player:GetAttribute("KO") then
		return false
	end
	if not h:GetStateEnabled(Enum.HumanoidStateType.Jumping) then
		return false -- (agachado, parkour delante, volando…: lo lleva otro sistema)
	end
	return h.FloorMaterial ~= Enum.Material.Air and jumpFrom(h:GetState())
end

-- Pulsar (down = true) o soltar el botón Saltar. Devuelve true si se ha saltado (o alguien se ha encargado).
function TouchLayout.jump(down: boolean): boolean
	local player = Players.LocalPlayer
	local character = player.Character
	local h = character and character:FindFirstChildOfClass("Humanoid")
	if not h then
		return false
	end
	local handled = false
	for _, listener in jumpListeners do
		local ok, result = pcall(listener, down, h)
		if not ok then
			warn("[Saltar] " .. tostring(result))
		elseif down and result == true then
			handled = true
		end
	end
	if not down then
		h.Jump = false
		return false
	end
	if handled then
		return true
	end
	if player:GetAttribute("InDialogue") or player:GetAttribute("InCinematic") then
		return false
	end
	h.Jump = true
	if TouchLayout.canJump(h) then
		h:ChangeState(Enum.HumanoidStateType.Jumping)
		return true
	end
	return false
end

local function jumpSpec(): Spec
	local player = Players.LocalPlayer
	local RunService = game:GetService("RunService")
	local holding = false
	local bound = false
	local function humanoid(): Humanoid?
		local character = player.Character
		return character and character:FindFirstChildOfClass("Humanoid")
	end
	local function unbind()
		if bound then
			bound = false
			pcall(function()
				RunService:UnbindFromRenderStep(JUMP_STEP)
			end)
		end
	end
	return {
		Id = "Saltar",
		Icon = "saltar",
		Label = "Saltar",
		Slot = "Saltar",
		Priority = 2,
		Key = "Espacio",
		Pad = "A",
		-- Sentado (sobre todo en un coche en marcha) saltar te echa del asiento: fuera el botón
		Visible = function()
			local h = humanoid()
			return h == nil or h.SeatPart == nil
		end,
		Hold = function(down: boolean)
			if down == holding then
				return
			end
			holding = down
			TouchLayout.jump(down)
			if not down then
				unbind()
				return
			end
			if not bound then
				bound = true
				-- Justo después del control de Roblox (Input) y del suavizado de Locomotion (Input + 1)
				RunService:BindToRenderStep(JUMP_STEP, Enum.RenderPriority.Input.Value + 2, function()
					local h = humanoid()
					if not holding then
						unbind()
					elseif h and not player:GetAttribute("InDialogue") and not player:GetAttribute("InCinematic") then
						h.Jump = true
					end
				end)
			end
		end,
	}
end

-- Esconde el botón de saltar de Roblox (el nuestro hace lo mismo)
local function hideRobloxJump()
	local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
	local touchGui = playerGui and playerGui:FindFirstChild("TouchGui")
	local frame = touchGui and touchGui:FindFirstChild("TouchControlFrame")
	local jump = frame and frame:FindFirstChild("JumpButton")
	if jump and jump:IsA("GuiObject") then
		jump.Visible = false
		jump:GetPropertyChangedSignal("Visible"):Connect(function()
			if jump.Visible then
				jump.Visible = false
			end
		end)
		return true
	end
	return false
end

function TouchLayout.init(parent: Instance?)
	if started then
		return
	end
	started = true
	touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local playerGui = parent or Players.LocalPlayer:WaitForChild("PlayerGui")
	gui = create("ScreenGui", {
		Name = "TouchLayout",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 4, -- por encima del HUD: ningún panel les quita los toques
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	})
	HudLayout.scaleGui(gui :: ScreenGui)
	if not touch then
		buildHints(gui :: ScreenGui)
	end
	HudLayout.onChanged(function(layout)
		if hintsPanel and layout.Items.Hints then
			HudLayout.apply(hintsPanel, layout.Items.Hints)
		end
		TouchLayout.refresh()
	end)
	TouchLayout.register(jumpSpec())
	if touch then
		TouchLayout.register({
			Id = MORE_ID,
			Icon = "mas",
			Label = "Más",
			-- (nunca entra en la lista normal: lo coloca refresh() solo cuando hace falta)
			Visible = function()
				return false
			end,
			Badge = function()
				return moreBadge
			end,
			Callback = function()
				extraPage += 1
			end,
		})
	end
	if touch then
		task.spawn(function()
			for _ = 1, 20 do
				if hideRobloxJump() then
					break
				end
				task.wait(1)
			end
		end)
	end
	-- Lo que depende del momento (de noche, montado, con piedras…): una revisión para todos
	task.spawn(function()
		while gui and gui.Parent do
			task.wait(0.5)
			TouchLayout.refresh()
		end
	end)
	-- Las letras del mando bajo los botones: solo con un mando conectado (se puede enchufar a mitad)
	local function refreshPads()
		for _, view in views do
			local pad = view.Button:FindFirstChild("Pad")
			if pad and pad:IsA("GuiObject") then
				pad.Visible = UserInputService.GamepadEnabled
			end
		end
	end
	local function onInputChanged()
		refreshPads()
		if not touch then
			TouchLayout.refresh()
		end
	end
	UserInputService.LastInputTypeChanged:Connect(onInputChanged)
	UserInputService.GamepadConnected:Connect(onInputChanged)
	UserInputService.GamepadDisconnected:Connect(onInputChanged)
	local player = Players.LocalPlayer
	for _, attribute in { "LifeStage", "Riding", "KO", "Dead", "Fallen", "InDialogue" } do
		player:GetAttributeChangedSignal(attribute):Connect(TouchLayout.refresh)
	end
end

---------------------------------------------------------------------
-- Compatibilidad con la API anterior (botones colocados a mano por cada sistema)
---------------------------------------------------------------------
-- Nombre antiguo del hueco -> hueco del racimo
local OLD_SLOTS = {
	Golpear = "Ataque",
	Defender = "Defender",
	Correr = "Correr",
	Claxon = "Ataque", -- conduciendo no hay Ataque: el claxon va en su sitio
	Bajarse = "Correr", -- conduciendo no hay Correr
	Sirena = "Defender",
	Piedra = "Extra1",
	Linterna = "Extra2",
	Foto = "Extra3",
	Extra = "Extra4",
	-- Pedales (conduciendo: Driving; el volante es el joystick)
	Acelerar = "Ataque",
	Frenar = "Esquivar",
	FrenoMano = "Fijar",
}

-- Hueco en píxeles de pantalla (para botones en pantallas sin la escala del HUD)
function TouchLayout.slot(name: string): { Position: UDim2, Size: number }
	local layout = HudLayout.compute(workspace.CurrentCamera.ViewportSize, { Touch = true })
	local p = layout.Slots[OLD_SLOTS[name] or name] or layout.Slots.Extra5
	local s = layout.Scale
	return {
		Position = UDim2.new(p.Position.X.Scale, p.Position.X.Offset * s, p.Position.Y.Scale, p.Position.Y.Offset * s),
		Size = p.Size.X * s,
	}
end

-- Coloca un botón (en una pantalla sin escala) en su hueco y lo mantiene al girar
function TouchLayout.place(button: GuiObject, name: string)
	local function apply()
		local slot = TouchLayout.slot(name)
		button.AnchorPoint = Vector2.new(0.5, 0.5)
		button.Position = slot.Position
		button.Size = UDim2.fromOffset(slot.Size, slot.Size)
	end
	apply()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(apply)
end

-- Para los botones de ContextActionService (SetPosition usa la esquina de arriba a la izquierda)
function TouchLayout.placeAction(ContextActionService: ContextActionService, action: string, name: string)
	local slot = TouchLayout.slot(name)
	local half = slot.Size / 2
	ContextActionService:SetPosition(action, slot.Position - UDim2.fromOffset(half, half))
	local button = ContextActionService:GetButton(action)
	if button then
		button.Size = UDim2.fromOffset(slot.Size, slot.Size)
	end
end

-- ¿Va montado en un vehículo?
function TouchLayout.riding(): boolean
	return Players.LocalPlayer:GetAttribute("Riding") ~= nil
end

-- ¿Va dentro de un vehículo, conduciendo o de pasajero? (entonces fuera los botones de ir a pie)
function TouchLayout.aboard(): boolean
	local player = Players.LocalPlayer
	return player:GetAttribute("Riding") ~= nil or player:GetAttribute("Passenger") ~= nil
end

-- Altura (px desde abajo) hasta donde llega el racimo de botones
function TouchLayout.top(): number
	local layout = HudLayout.compute(workspace.CurrentCamera.ViewportSize, { Touch = true })
	local top = math.huge
	for _, p in layout.Slots do
		top = math.min(top, HudLayout.rect(p, layout.Canvas).Y)
	end
	return (layout.Canvas.Y - top) * layout.Scale
end

-- Botón redondo en su hueco, hecho a mano (en una pantalla sin la escala del HUD). Empieza escondido.
-- (Mejor TouchLayout.register: así el racimo sabe que existe y nada se pisa.)
local buttonsGui: ScreenGui? = nil
function TouchLayout.button(name: string, icon: string, callback: () -> ()): TextButton
	if not buttonsGui then
		buttonsGui = create("ScreenGui", { Name = "TouchButtons", ResetOnSpawn = false, DisplayOrder = 3, Parent = Players.LocalPlayer:WaitForChild("PlayerGui") })
	end
	local button = create("TextButton", {
		Name = name .. "Button",
		Text = icon,
		TextScaled = true,
		Font = Theme.FontBold,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = H.Navy,
		BackgroundTransparency = 0.3,
		Visible = false,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
		create("UIPadding", { PaddingTop = UDim.new(0.2, 0), PaddingBottom = UDim.new(0.2, 0), PaddingLeft = UDim.new(0.2, 0), PaddingRight = UDim.new(0.2, 0) }),
	})
	Theme.edge(button, nil, 2)
	button.Activated:Connect(callback)
	TouchLayout.place(button, name)
	button.Parent = buttonsGui
	return button
end

-- Muestra el botón solo a pie ("Pie") o solo conduciendo ("Vehiculo"), y además si extra() lo permite
function TouchLayout.showWhen(button: GuiObject, when: string, extra: (() -> boolean)?)
	local function update()
		local ok = if when == "Vehiculo" then TouchLayout.riding() else not TouchLayout.aboard()
		button.Visible = ok and (extra == nil or extra())
	end
	Players.LocalPlayer:GetAttributeChangedSignal("Riding"):Connect(update)
	Players.LocalPlayer:GetAttributeChangedSignal("Passenger"):Connect(update)
	update()
	return update
end

-- (pruebas) la definición de un botón (para quitarlo y volverlo a poner)
function TouchLayout._spec(id: string): Spec?
	return specs[id]
end

-- (pruebas) empezar de cero
function TouchLayout._reset()
	specs, order, views, labels, icons = {}, {}, {}, {}, {}
	busy, gui, hintsPanel, started = false, nil, nil, false
	driving = false
	flying = false
	phoneOpen = false
	swimHidden = nil
	extraPage, moreBadge = 1, nil
end

return TouchLayout
