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
--
-- Móvil y tableta: botones redondos con icono y texto, en racimo abajo a la derecha (HudLayout.Cluster):
-- Interactuar arriba; Correr, Defensa y Saltar; Gestos y el Ataque grande; Esquivar y Fijar objetivo.
-- Los de contexto (linterna, foto, piedra, bajarse, sirena…) en una columna a la izquierda, solo cuando
-- sirven. Ordenador y mando: sin botones; en su lugar, una lista pequeña de teclas abajo a la derecha.
-- Si hay un mando conectado, debajo de cada botón redondo sale su letra (Y, A, X, RB…).
--
-- Huecos: Ataque, Interactuar, Correr, Defender, Saltar, Gestos, Esquivar, Fijar (y Extra1-5).
-- Si dos botones visibles piden el mismo hueco, se lo queda el de Priority más baja y el otro pasa
-- a la columna de contexto. Alias para las armas: Slot = "Disparar" usa el hueco del Ataque,
-- "Apuntar" el de Defender y "Recargar" el de Fijar (con Priority < 3 se quedan con el hueco).
--
-- Compatibilidad (API anterior de este módulo): TouchLayout.slot(nombre), place(botón, nombre),
-- placeAction(ContextActionService, acción, nombre), riding() y showWhen(botón, "Pie"|"Vehiculo").

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Theme)
local Icons = require(script.Parent.Icons)
local HudLayout = require(script.Parent.HudLayout)

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
}

type View = { Button: TextButton, Label: TextLabel, Icon: Frame, Badge: TextLabel, Stroke: UIStroke, Fill: Frame, Meter: Frame, MeterFill: Frame, Active: any }

local specs: { [string]: Spec } = {}
local order: { string } = {}
local views: { [string]: View } = {}
local labels: { [string]: string } = {}
local busy = false
local gui: ScreenGui? = nil
local hintsPanel: Frame? = nil
local touch = false
local started = false

-- Huecos con otro nombre (armas: van donde los golpes)
local SLOT_ALIAS = { Disparar = "Ataque", Apuntar = "Defender", Recargar = "Fijar" }

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
local function buildView(spec: Spec): View
	local big = spec.Slot ~= nil and (SLOT_ALIAS[spec.Slot] or spec.Slot) == "Ataque"
	local button = create("TextButton", {
		Name = spec.Id,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(88, 88),
		BackgroundColor3 = H.Navy,
		BackgroundTransparency = 0.28,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		Parent = gui,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(120, 170, 255), rgb(40, 60, 120)) }),
	})
	local stroke = Theme.edge(button, nil, if big then 4 else 2.5)
	Theme.halo(button, H.Glow, if big then 10 else 6, 999)
	-- Disco interior más oscuro (da relieve de botón)
	local fill = create("Frame", {
		Name = "Fill",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.84, 0.84),
		BackgroundColor3 = H.Navy,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Parent = button,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local icon = Icons.new(spec.Icon, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.fromScale(0.44, 0.44),
		Parent = button,
	})
	local label = Theme.label({
		Name = "Caption",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.66),
		Size = UDim2.fromScale(0.96, 0.2),
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
		BackgroundColor3 = H.Gold,
		BackgroundTransparency = 0,
		Font = Theme.FontBold,
		TextScaled = true,
		TextColor3 = Theme.Colors.Ink,
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
		if spec.Callback then
			local ok, err = pcall(spec.Callback)
			if not ok then
				warn("[Botones] " .. tostring(err))
			end
		end
		task.defer(TouchLayout.refresh)
	end)
	if spec.Hold then
		local holding: InputObject? = nil
		button.InputBegan:Connect(function(input)
			local kind = input.UserInputType
			if kind == Enum.UserInputType.Touch or kind == Enum.UserInputType.MouseButton1 then
				holding = input
				pcall(spec.Hold :: any, true)
			end
		end)
		local function release(input: InputObject)
			if holding and (input == holding or input.UserInputType == Enum.UserInputType.MouseButton1) then
				holding = nil
				pcall(spec.Hold :: any, false)
			end
		end
		button.InputEnded:Connect(release)
		-- (si el dedo sale del botón, InputEnded llega igual a UserInputService)
		UserInputService.InputEnded:Connect(release)
	end
	return { Button = button, Label = label, Icon = icon, Badge = badge, Stroke = stroke, Fill = fill, Meter = meter, MeterFill = meterFill }
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
	TweenService:Create(view.Fill, Theme.Fast, {
		BackgroundColor3 = if on then H.Select elseif waiting then WAIT else H.Navy,
		BackgroundTransparency = if on or waiting then 0.15 else 0.45,
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
local function visibleSpecs(): { Spec }
	local list = {}
	for _, id in order do
		local spec = specs[id]
		-- En conversaciones y cinemáticas solo quedan los botones marcados Always (levantarse)
		if spec and (not busy or (spec :: any).Always) and safe(spec.Visible, true) then
			table.insert(list, spec)
		end
	end
	table.sort(list, function(a, b)
		return (a.Priority or 50) < (b.Priority or 50)
	end)
	return list
end

function TouchLayout.refresh()
	if not started then
		return
	end
	local visible = visibleSpecs()
	if not touch then
		refreshHints(visible)
		return
	end
	local layout = HudLayout.current()
	local taken: { [string]: boolean } = {}
	local placed: { [string]: string } = {}
	local extras: { Spec } = {}
	for _, spec in visible do
		local slot = if spec.Slot then (SLOT_ALIAS[spec.Slot] or spec.Slot) else nil
		if slot and layout.Slots[slot] and not taken[slot] then
			taken[slot] = true
			placed[spec.Id] = slot
		else
			table.insert(extras, spec)
		end
	end
	for i, spec in extras do
		if i <= HudLayout.ExtraSlots then
			placed[spec.Id] = "Extra" .. i
		end
	end
	for _, id in order do
		local spec = specs[id]
		local slot = placed[id]
		local view = views[id]
		if slot and not view then
			view = buildView(spec)
			views[id] = view
		end
		if view then
			local was = view.Button.Visible
			view.Button.Visible = slot ~= nil
			if slot then
				HudLayout.apply(view.Button, layout.Slots[slot])
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
				end
				Theme.setText(view.Label, labels[id] or spec.Label)
			end
		end
	end
end

function TouchLayout.register(spec: Spec)
	if not specs[spec.Id] then
		table.insert(order, spec.Id)
	elseif views[spec.Id] then
		views[spec.Id].Button:Destroy()
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
		views[id].Button:Destroy()
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

-- Atenuado (p. ej. Interactuar sin nada delante)
function TouchLayout.setDim(id: string, dim: boolean)
	local view = views[id]
	if view then
		view.Button.BackgroundTransparency = if dim then 0.6 else 0.28
		view.Label.TextTransparency = if dim then 0.45 else 0
	end
end

-- En conversaciones y cinemáticas no hay botones
function TouchLayout.setBusy(value: boolean)
	busy = value
	TouchLayout.refresh()
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

-- Saltar: el botón propio sustituye al de Roblox (se esconde, sin quitarle nada al personaje)
local function jumpSpec(): Spec
	local player = Players.LocalPlayer
	local holding = false
	local function humanoid(): Humanoid?
		local character = player.Character
		return character and character:FindFirstChildOfClass("Humanoid")
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
			holding = down
			local h = humanoid()
			if h and down then
				h.Jump = true
				-- mantener pulsado = seguir saltando (como el botón de Roblox)
				task.spawn(function()
					while holding do
						task.wait(0.1)
						local now = humanoid()
						if holding and now then
							now.Jump = true
						end
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
	for _, attribute in { "LifeStage", "Riding", "KO", "InDialogue" } do
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

-- (pruebas) empezar de cero
function TouchLayout._reset()
	specs, order, views, labels = {}, {}, {}, {}
	busy, gui, hintsPanel, started = false, nil, nil, false
end

return TouchLayout
