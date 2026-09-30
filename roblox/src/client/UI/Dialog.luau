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
			scale.Scale = Dialog.baseScale()
			-- Cada ventana grande se encoge un poco más si aún no cabe.
			for _, child in g:GetChildren() do
				local fit = child:FindFirstChild("FitScale")
				if fit then
					Dialog._fit(child :: Frame)
				end
			end
		end
		gui = g
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
		rescale()
	end
	return gui :: ScreenGui
end

-- Escala base de las ventanas. Ordenador: alto / 850 (suelo 0.4). Móvil: con alto / 850 salían a
-- 0.42-0.46 (texto de ~7 px); ahora mínimo 0.6. Lo que no quepa lo encoge FitScale en cada ventana.
function Dialog.baseScale(): number
	local viewport = workspace.CurrentCamera.ViewportSize
	if Theme.isTouch() then
		return math.clamp(math.min(viewport.Y / 560, viewport.X / 1000), 0.6, 1.25)
	end
	return math.clamp(viewport.Y / 850, 0.4, 1.25)
end

---------------------------------------------------------------------
-- Paneles grandes: el menú, los controles, las misiones, la tienda y las ventanas de aquí.
-- Al abrir uno se cierran los demás, para que no se amontonen (en el móvil no se ve nada debajo).
---------------------------------------------------------------------
local bigPanels: { [string]: () -> () } = {}

function Dialog.registerBig(name: string, close: () -> ())
	bigPanels[name] = close
end

-- Cierra todos los paneles grandes menos `except`
function Dialog.closeOthers(except: string?)
	for name, close in bigPanels do
		if name ~= except then
			local ok, err = pcall(close)
			if not ok then
				warn("[Dialog] " .. tostring(err))
			end
		end
	end
end

-- Encoge una ventana para que quepa entera en pantalla: alto menos la barra de Roblox (~60)
-- y ancho con un margen de 12 a cada lado. Así el ✖ nunca queda debajo de la barra superior.
function Dialog._fit(window: Frame)
	local g = gui
	local fit = window:FindFirstChild("FitScale") :: UIScale?
	if not g or not fit then
		return
	end
	local viewport = workspace.CurrentCamera.ViewportSize
	local base = (g:FindFirstChildOfClass("UIScale") :: UIScale).Scale
	local size = window.Size
	local w, h = math.max(size.X.Offset, 1), math.max(size.Y.Offset, 1)
	local want = math.min((viewport.Y - 60) / h, (viewport.X - 24) / w)
	-- UIScale se multiplica con la del ScreenGui: solo reducimos, nunca agrandamos.
	fit.Scale = math.clamp(want / base, 0.3, 1)
end

-- Ventanas que NO cierran las demás: preguntas y avisos que llegan solos (una invitación, un
-- intercambio) y ventanas de trabajo (caja del súper, barra, charcutería…). Si cerraran la tienda o
-- la lista de misiones, cada invitación te echaba de lo que estabas mirando.
local chooseCount = 0
local KEEP_OTHERS = {
	Choose = true, Trade = true, SuperScan = true, SuperReceipt = true, SuperDeli = true,
	SuperDeliWork = true, Bar = true, ArcadeGame = true, MetroBusk = true, MedicalMeds = true,
}

-- Ventana centrada con título y ✖. Devuelve (ventana, contenido, botón cerrar).
function Dialog.window(name: string, title: string, size: Vector2): (Frame, Frame, TextButton)
	local existing = root():FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	-- Fuera el menú, los controles, las misiones o la tienda que hubiera abiertos
	if not KEEP_OTHERS[name] and name:sub(1, 6) ~= "Choose" then
		Dialog.closeOthers(name)
	end
	local window = Theme.panel({
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(size.X, size.Y),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 0.05,
		Parent = root(),
	})
	create("UIScale", { Name = "FitScale", Parent = window })
	Dialog._fit(window)
	-- Algunas ventanas cambian de alto después (listas); se reajusta al vuelo.
	window:GetPropertyChangedSignal("Size"):Connect(function()
		Dialog._fit(window)
	end)
	Theme.label({
		Name = "Title",
		Size = UDim2.new(1, if Theme.isTouch() then -76 else -60, 0, 40),
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
		-- (móvil: ~36 px en pantalla también con la escala mínima 0.6)
		Size = if Theme.isTouch() then UDim2.fromOffset(50, 50) else UDim2.fromOffset(36, 36),
		Position = UDim2.new(1, -10, 0, 10),
		Text = "✖",
		TextSize = if Theme.isTouch() then 22 else 16,
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
	-- Con muchas opciones la ventana no crece más que la pantalla: la lista se desplaza
	-- (antes FitScale la encogía hasta que el texto no se leía)
	local viewport = workspace.CurrentCamera.ViewportSize
	local maxHeight = math.max(240, math.floor((viewport.Y - 60) / Dialog.baseScale()))
	-- (cada pregunta con su nombre: antes una invitación que llegaba cerraba la pregunta abierta
	-- —una del examen de conducir contaba como fallada— y la siguiente cerraba la invitación)
	chooseCount += 1
	local window, content = Dialog.window("Choose" .. chooseCount, title, Vector2.new(460, math.min(height, maxHeight)))
	local list = create("ScrollingFrame", {
		Name = "Options",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = content,
	})
	create("UIPadding", { PaddingRight = UDim.new(0, if height > maxHeight then 10 else 0), Parent = list })
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

-- Cierra todas las ventanas de aquí menos `except` (y los paneles grandes)
function Dialog.closeAll(except: string?)
	Dialog.closeOthers(except)
	for _, child in root():GetChildren() do
		if child:IsA("GuiObject") and child.Name ~= except then
			child:Destroy()
		end
	end
end

function Dialog.close(name: string)
	local existing = root():FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
end

return Dialog
