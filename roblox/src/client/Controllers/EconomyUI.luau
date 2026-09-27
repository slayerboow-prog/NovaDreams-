-- EconomyUI (cliente): las ventanas de la granja (Remote "Farm") y de los negocios (Remote "Business").
--
-- El servidor manda la ventana ya hecha (título, pestañas y filas con botones) y aquí solo se
-- dibuja. Cada botón le devuelve al servidor su acción; el servidor lo comprueba todo y manda la
-- ventana actualizada. Así la cooperativa, el obrador, la cocina, la gestión de tu negocio y el
-- mostrador de las tiendas usan la misma pantalla (y se ven igual en el móvil y en el ordenador).
--
-- Ventana (del servidor):
--   { Remote, Id, Context?, Title, Subtitle?, Tabs = { { Id, Text } }?, Tab?, Footer?,
--     Rows = { { Header = texto } | { Icon, Title, Text?, Buttons = { { Text, Action, Args, Style?, Disabled? } } } } }
-- Pestañas: FireServer("Panel", Id, pestaña, Context). Botones: FireServer(Action, table.unpack(Args)).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local SoundFx = require(script.Parent.SoundFx)

local EconomyUI = {}

local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

local STYLES = {
	Accent = C.Accent,
	Gold = C.Gold,
	Danger = C.Error,
	Dim = rgb(50, 52, 60),
	Green = rgb(60, 170, 90),
}

local scrollOf: { [string]: Vector2 } = {} -- dónde estaba la lista (para no volver arriba al actualizar)

local function open(remote: RemoteEvent, panel: { [string]: any })
	local id = tostring(panel.Id or "Panel")
	local name = "Eco_" .. id
	local key = id .. ":" .. tostring(panel.Tab or "")
	local window, content, close = Dialog.window(name, tostring(panel.Title or ""), Vector2.new(580, 540))
	local top = 0
	if panel.Subtitle then
		Theme.label({
			Size = UDim2.new(1, 0, 0, 22),
			Text = tostring(panel.Subtitle),
			TextSize = 14,
			TextColor3 = C.Muted,
			TextWrapped = true,
			Parent = content,
		})
		top += 26
	end
	if type(panel.Tabs) == "table" and #panel.Tabs > 0 then
		local bar = create("Frame", { Size = UDim2.new(1, 0, 0, 36), Position = UDim2.fromOffset(0, top), BackgroundTransparency = 1, Parent = content })
		create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), Parent = bar })
		local width = 1 / #panel.Tabs
		for _, tab in panel.Tabs do
			local selected = tab.Id == panel.Tab
			local b = Theme.button({
				Size = UDim2.new(width, -6, 1, 0),
				Text = tostring(tab.Text),
				TextSize = 14,
				TextScaled = false,
				BackgroundColor3 = if selected then C.Accent else C.PanelLight,
				Parent = bar,
			})
			b.Activated:Connect(function()
				if not selected then
					SoundFx.play("Clic")
					remote:FireServer("Panel", panel.Id, tab.Id, panel.Context)
				end
			end)
		end
		top += 44
	end
	local footer = if panel.Footer then 40 else 0
	local list = create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -top - footer),
		Position = UDim2.fromOffset(0, top),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = content,
	})
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	for i, row in if type(panel.Rows) == "table" then panel.Rows else {} do
		if row.Header then
			Theme.label({
				Size = UDim2.new(1, -8, 0, 28),
				Text = tostring(row.Header),
				Font = Theme.FontBold,
				TextSize = 15,
				TextColor3 = C.Gold,
				TextWrapped = true,
				LayoutOrder = i,
				Parent = list,
			})
			continue
		end
		local buttons = if type(row.Buttons) == "table" then row.Buttons else {}
		local buttonsWidth = #buttons * 112
		local frame = create("Frame", { Size = UDim2.new(1, -8, 0, 64), BackgroundColor3 = rgb(20, 32, 56), BackgroundTransparency = 0.2, LayoutOrder = i, Parent = list }, { Theme.corner(10) })
		Theme.label({ Position = UDim2.fromOffset(8, 0), Size = UDim2.fromOffset(40, 64), Text = tostring(row.Icon or ""), TextSize = 28, TextXAlignment = Enum.TextXAlignment.Center, Parent = frame })
		Theme.label({
			Position = UDim2.fromOffset(52, 4),
			Size = UDim2.new(1, -60 - buttonsWidth, 0, 22),
			Text = tostring(row.Title or ""),
			Font = Theme.FontBold,
			TextSize = 15,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = frame,
		})
		Theme.label({
			Position = UDim2.fromOffset(52, 26),
			Size = UDim2.new(1, -60 - buttonsWidth, 0, 36),
			Text = tostring(row.Text or ""),
			TextSize = 12,
			TextColor3 = C.Muted,
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			Parent = frame,
		})
		for k, spec in buttons do
			local style = STYLES[spec.Style or ""] or C.PanelLight
			local b = Theme.button({
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8 - (#buttons - k) * 112, 0.5, 0),
				Size = UDim2.fromOffset(106, 44),
				Text = tostring(spec.Text or ""),
				TextSize = 13,
				TextWrapped = true,
				BackgroundColor3 = if spec.Disabled then STYLES.Dim else style,
				TextColor3 = if spec.Style == "Gold" and not spec.Disabled then C.Ink else C.Text,
				AutoButtonColor = not spec.Disabled,
				Parent = frame,
			})
			b.Activated:Connect(function()
				if spec.Disabled or type(spec.Action) ~= "string" or spec.Action == "" then
					return
				end
				SoundFx.play("Clic")
				scrollOf[key] = list.CanvasPosition
				remote:FireServer(spec.Action, table.unpack(if type(spec.Args) == "table" then spec.Args else {}))
			end)
		end
	end
	if panel.Footer then
		Theme.label({
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 36),
			Text = tostring(panel.Footer),
			TextSize = 12,
			TextColor3 = C.Muted,
			TextWrapped = true,
			Parent = content,
		})
	end
	local saved = scrollOf[key]
	if saved then
		task.defer(function()
			list.CanvasPosition = saved
		end)
	end
	list:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		scrollOf[key] = list.CanvasPosition
	end)
	close.Activated:Connect(function()
		scrollOf[key] = nil
	end)
	local _ = window
end

local function listen(remoteName: string)
	local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(remoteName, 60) :: RemoteEvent?
	if not remote then
		return
	end
	remote.OnClientEvent:Connect(function(action, data)
		if action == "Panel" and type(data) == "table" then
			open(remote, data)
		elseif action == "Close" then
			Dialog.close("Eco_" .. tostring(data))
		end
	end)
end

function EconomyUI.init()
	task.spawn(listen, "Farm")
	task.spawn(listen, "Business")
end

return EconomyUI
