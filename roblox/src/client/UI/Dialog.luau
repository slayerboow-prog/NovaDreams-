-- Dialog: ventanas de la interfaz que se repiten en varios sistemas.
--   Dialog.choose(title, body, options)  -> índice elegido o nil si se cierra (espera la respuesta)
--   Dialog.window(name, title, size)     -> ventana con título y botón de cerrar (para paneles propios)

local Players = game:GetService("Players")

local Theme = require(script.Parent.Theme)

local create = Theme.create
local C = Theme.Colors

local Dialog = {}

local gui: ScreenGui? = nil

local function root(): ScreenGui
	if not gui then
		local g = create("ScreenGui", {
			Name = "Dialogs",
			ResetOnSpawn = false,
			DisplayOrder = 5,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
		})
		local scale = create("UIScale", { Parent = g })
		local camera = workspace.CurrentCamera
		local function rescale()
			scale.Scale = math.clamp(camera.ViewportSize.Y / 850, 0.65, 1.25)
		end
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
		rescale()
		gui = g
	end
	return gui :: ScreenGui
end

-- Ventana centrada con título y ✕. Devuelve (ventana, contenido, botón cerrar).
function Dialog.window(name: string, title: string, size: Vector2): (Frame, Frame, TextButton)
	local existing = root():FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	local window = Theme.panel({
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(size.X, size.Y),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 0.05,
		Parent = root(),
	})
	Theme.label({
		Name = "Title",
		Size = UDim2.new(1, -60, 0, 40),
		Position = UDim2.fromOffset(16, 8),
		Text = title,
		Font = Theme.FontBold,
		TextSize = 22,
		TextWrapped = true,
		Parent = window,
	})
	local close = Theme.button({
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0),
		Size = UDim2.fromOffset(36, 36),
		Position = UDim2.new(1, -10, 0, 10),
		Text = "✕",
		Parent = window,
	})
	local content = create("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -32, 1, -64),
		Position = UDim2.fromOffset(16, 56),
		BackgroundTransparency = 1,
		Parent = window,
	})
	close.Activated:Connect(function()
		window:Destroy()
	end)
	return window, content, close
end

-- Pregunta con varias respuestas. Espera hasta que el jugador elige (o cierra: nil).
function Dialog.choose(title: string, body: string?, options: { string }): number?
	local height = 90 + (if body then 60 else 0) + #options * 54
	local window, content = Dialog.window("Choose", title, Vector2.new(460, height))
	local list = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = content })
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	if body then
		Theme.label({
			Size = UDim2.new(1, 0, 0, 52),
			Text = body,
			TextSize = 16,
			TextColor3 = C.Muted,
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			LayoutOrder = 0,
			Parent = list,
		})
	end
	local done = Instance.new("BindableEvent")
	local answered = false
	local function answer(value: number?)
		if not answered then
			answered = true
			done:Fire(value)
		end
	end
	for i, text in options do
		local button = Theme.button({
			Size = UDim2.new(1, 0, 0, 46),
			Text = text,
			TextSize = 16,
			TextWrapped = true,
			LayoutOrder = i,
			Parent = list,
		})
		button.Activated:Connect(function()
			answer(i)
		end)
	end
	window.Destroying:Connect(function()
		answer(nil)
	end)
	local result = done.Event:Wait()
	if window.Parent then
		window:Destroy()
	end
	done:Destroy()
	return result
end

function Dialog.close(name: string)
	local existing = root():FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
end

return Dialog
