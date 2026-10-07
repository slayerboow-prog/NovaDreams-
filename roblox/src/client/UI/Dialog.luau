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
		return Theme.touchWindowScale(viewport)
	end
	return math.clamp(viewport.Y / 850, 0.4, 1.25)
end

---------------------------------------------------------------------
-- Paneles grandes: el menú, los controles, las misiones, la tienda y las ventanas de aquí.
-- Al abrir uno se cierran los demás, para que no se amontonen (en el móvil no se ve nada debajo).
---------------------------------------------------------------------
local bigPanels: { [string]: () -> () } = {}
local bigOpen: { [string]: () -> boolean } = {}

-- isOpen (opcional): ¿está abierto ahora? (Dialog.anyOpen: las pistas no salen encima)
function Dialog.registerBig(name: string, close: () -> (), isOpen: (() -> boolean)?)
	bigPanels[name] = close
	bigOpen[name] = isOpen
end

-- ¿Hay alguna ventana abierta? (una de aquí —Mis vehículos, una pregunta…— o un panel grande: la
-- mochila, el mapa, el ValPhone, el ❓, el diario…). Las pistas y avisos de la guía (Controllers/Guide)
-- esperan a que se cierre: si no, la tapaban. except: no cuenta esa (la que pregunta).
function Dialog.anyOpen(except: string?): boolean
	local g = gui
	if g then
		for _, child in g:GetChildren() do
			if child:IsA("GuiObject") and child.Visible and child.Name ~= except then
				return true
			end
		end
	end
	for name, isOpen in bigOpen do
		if name ~= except then
			local ok, value = pcall(isOpen)
			if ok and value == true then
				return true
			end
		end
	end
	return false
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
-- Móvil: escala total mínima de una ventana (con menos, el texto de 14 sale de ~8 px y no se lee)
Dialog.MIN_TOUCH_SCALE = 0.6
-- Móvil: lado mínimo del ✖ en píxeles de pantalla
Dialog.MIN_CLOSE_PX = 37

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
	-- UIScale se multiplica con la del ScreenGui: solo reducimos, nunca agrandamos. En el móvil, nunca
	-- por debajo de 0.6 en total (las ventanas altas se recortan y su contenido se desplaza: Dialog.window).
	local floor = if Theme.isTouch() then math.min(1, Dialog.MIN_TOUCH_SCALE / math.max(base, 0.01)) else 0.3
	fit.Scale = math.clamp(want / base, floor, 1)
	-- Móvil: el ✖ siempre de ~37 px en pantalla (con la escala que haya quedado). Las ventanas que se
	-- colocan solas (NO_SCROLL: el pase) ya lo hacen ellas.
	if Theme.isTouch() and not window:GetAttribute("OwnLayout") then
		local close = window:FindFirstChild("Close") :: GuiObject?
		if close then
			local side = math.max(50, math.ceil(Dialog.MIN_CLOSE_PX / math.max(base * fit.Scale, 0.01)))
			close.Size = UDim2.fromOffset(side, side)
			local title = window:FindFirstChild("Title") :: GuiObject?
			if title then
				title.Size = UDim2.new(1, -(side + 26), 0, 40)
			end
		end
	end
end

-- Móvil: alto máximo de una ventana (en unidades). Más alta, su contenido se desplaza (ScrollingFrame)
-- en vez de encoger toda la ventana hasta que el texto no se lee (Tu personaje de 670, el plano del
-- metro, la economía, el modo pruebas…).
function Dialog.touchMaxHeight(): number?
	if not Theme.isTouch() then
		return nil
	end
	local viewport = workspace.CurrentCamera.ViewportSize
	return math.clamp(math.floor((viewport.Y - 60) / Dialog.baseScale()), 240, 520)
end

-- Ventanas que NO cierran las demás: preguntas y avisos que llegan solos (una invitación, un
-- intercambio) y ventanas de trabajo (caja del súper, barra, charcutería…). Si cerraran la tienda o
-- la lista de misiones, cada invitación te echaba de lo que estabas mirando.
local chooseCount = 0
local KEEP_OTHERS = {
	Choose = true, Trade = true, SuperScan = true, SuperReceipt = true, SuperDeli = true,
	SuperDeliWork = true, Bar = true, ArcadeGame = true, MetroBusk = true, MedicalMeds = true,
}

-- ¿Qué ventana grande tapa ahora la pantalla? Devuelve su nombre (o nil). Mientras haya una, los
-- botones táctiles se apartan (UI/TouchLayout) para no quedar encima de la ventana. No cuentan las
-- preguntas, los intercambios ni las ventanas de trabajo (KEEP_OTHERS), ni el ValPhone (aparta él
-- solo los botones de su esquina).
local NOT_BLOCKING = { Phone = true }
function Dialog.blockingOpen(): string?
	local g = gui
	if g then
		for _, child in g:GetChildren() do
			if child:IsA("GuiObject") and child.Visible and not KEEP_OTHERS[child.Name] and child.Name:sub(1, 6) ~= "Choose" then
				return child.Name
			end
		end
	end
	for name, isOpen in bigOpen do
		if not NOT_BLOCKING[name] then
			local ok, value = pcall(isOpen)
			if ok and value == true then
				return name
			end
		end
	end
	return nil
end

-- Ventanas que calculan su propio tamaño para cada pantalla (no se recortan con contenido desplazable)
local NO_SCROLL = { BattlePass = true }

-- Ventana centrada con título y ✖. Devuelve (ventana, contenido, botón cerrar).
function Dialog.window(name: string, title: string, size: Vector2): (Frame, Frame, TextButton)
	local existing = root():FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	-- Fuera el menú, los controles, las misiones, la tienda, la mochila, el mapa… y las demás ventanas
	-- de aquí (Tu personaje + Mis vehículos salían una encima de otra). Las preguntas (Choose), los
	-- intercambios y las ventanas de trabajo (KEEP_OTHERS) no cierran nada ni se cierran.
	if not KEEP_OTHERS[name] and name:sub(1, 6) ~= "Choose" then
		Dialog.closeOthers(name)
		for _, child in root():GetChildren() do
			if child:IsA("GuiObject") and child.Name ~= name and not KEEP_OTHERS[child.Name] and child.Name:sub(1, 6) ~= "Choose" then
				child:Destroy()
			end
		end
	end
	-- Móvil: una ventana más alta que la pantalla se recorta y su contenido se desplaza (menos las que
	-- ya se miden solas para la pantalla: NO_SCROLL)
	local maxHeight = if NO_SCROLL[name] then nil else Dialog.touchMaxHeight()
	local natural = size.Y
	local scrolls = maxHeight ~= nil and natural > maxHeight
	local window = Theme.panel({
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(size.X, if scrolls then maxHeight else natural),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 0.05,
		Parent = root(),
	})
	create("UIScale", { Name = "FitScale", Parent = window })
	if NO_SCROLL[name] then
		window:SetAttribute("OwnLayout", true)
	end
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
		-- (móvil: ~37 px en pantalla con la escala que tenga: Dialog._fit)
		Size = if Theme.isTouch() then UDim2.fromOffset(50, 50) else UDim2.fromOffset(36, 36),
		Position = if Theme.isTouch() then UDim2.new(1, -8, 0, 4) else UDim2.new(1, -10, 0, 10),
		Text = "✖",
		TextSize = if Theme.isTouch() then 22 else 16,
		ZIndex = 5, -- (encima del contenido aunque se toquen)
		Parent = window,
	})
	local content: Frame
	if scrolls then
		-- (los hijos con tamaño en escala se miden con el lienzo: salen como en la ventana entera)
		content = create("ScrollingFrame", {
			Name = "Content",
			Size = UDim2.new(1, -32, 1, -64),
			Position = UDim2.fromOffset(16, 56),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 6,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			CanvasSize = UDim2.new(1, 0, 0, natural - 64),
			Parent = window,
		}) :: any
	else
		content = create("Frame", {
			Name = "Content",
			Size = UDim2.new(1, -32, 1, -64),
			Position = UDim2.fromOffset(16, 56),
			BackgroundTransparency = 1,
			Parent = window,
		})
	end
	Dialog._fit(window)
	-- Algunas ventanas cambian de alto después (listas); se reajusta al vuelo. En el móvil, si el
	-- contenido se desplaza, el alto nuevo va al lienzo y la ventana sigue recortada.
	local adjusting = false
	window:GetPropertyChangedSignal("Size"):Connect(function()
		if adjusting then
			return
		end
		local cap = Dialog.touchMaxHeight()
		local now = window.Size
		if scrolls and cap and now.Y.Offset ~= cap then
			adjusting = true
			;(content :: any).CanvasSize = UDim2.new(1, 0, 0, math.max(now.Y.Offset, cap) - 64)
			window.Size = UDim2.fromOffset(now.X.Offset, math.min(now.Y.Offset, cap))
			adjusting = false
		end
		Dialog._fit(window)
	end)
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
	local maxHeight = Dialog.touchMaxHeight() or math.max(240, math.floor((viewport.Y - 60) / Dialog.baseScale()))
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

-- Una conversación o una escena empieza: fuera los paneles grandes y las ventanas de aquí, menos las
-- preguntas (Choose), los intercambios y las ventanas de trabajo (KEEP_OTHERS): esas esperan respuesta.
function Dialog.closeForScene()
	Dialog.closeOthers(nil)
	for _, child in root():GetChildren() do
		if child:IsA("GuiObject") and not KEEP_OTHERS[child.Name] and child.Name:sub(1, 6) ~= "Choose" then
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
