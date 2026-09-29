-- CommandMenu: el menú de comandos, siempre abajo a la izquierda mientras juegas (en el móvil, justo
-- encima del joystick; dónde exactamente lo dice UI/HudLayout).
--
--   * Panel con la pestaña "👑 COMANDOS"; el elegido va en azul brillante y el selector se desliza.
--   * Cambia con el contexto (ContextDetector): lo que tienes delante sale arriba del todo.
--   * Los grupos (Más…) abren submenús; "Volver" (o ← / Retroceso / B) regresa.
--   * Se ven 4-5 comandos; ⌄ despliega todos. El botón de la pestaña lo oculta (se recuerda en la sesión).
--   * El comando elegido es también lo que hace la tecla E / el botón X del mando / el botón Interactuar.
--
-- Controles:
--   Teclado:  ↑ ↓ elegir (con el menú desplegado) · Enter aceptar · ← o Retroceso volver · E usar lo que tienes delante · Tab ocultar
--   Mando:    cruceta ↑ ↓ elegir · cruceta → aceptar · cruceta ← o B volver (← en la lista principal: ocultar)
--   Móvil:    un toque elige un comando y otro toque sobre el elegido lo hace
-- Mientras hablas con alguien o ves una cinemática se aparta (setBusy).

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.UI.Theme)
local HudLayout = require(script.Parent.Parent.UI.HudLayout)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local CommandRegistry = require(script.Parent.CommandRegistry)
local ContextDetector = require(script.Parent.ContextDetector)
local CommandRenderer = require(script.Parent.CommandRenderer)
local UiAudio = require(script.Parent.UiAudio)
local MenuLogic = require(script.Parent.MenuLogic)

local CommandMenu = {}

local player = Players.LocalPlayer
local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local IDLE_RESET = MenuLogic.IdleReset -- segundos sin tocar el menú: lo nuevo que aparece delante pasa a elegido

type Command = CommandRegistry.Command
type Level = { Title: string, Items: { Command }, Index: number, Group: Command? }

local renderer: any
local gui: ScreenGui
local stack: { Level } = {}
local lastInput = -math.huge
local busy = false
local signature = ""
local focusListeners: { (ProximityPrompt?) -> () } = {}
local collapsed = false -- oculto con el botón de la pestaña (se recuerda mientras juegas)
local expanded = false -- desplegado con ⌄ (todos los comandos)

local BACK: Command = { Id = "_Volver", Label = "Volver", Icon = "volver", Priority = 1e9 }

local function current(): Level
	return stack[#stack]
end

local function selected(): Command?
	local level = current()
	return level and level.Items[level.Index]
end

local function toItems(list: { Command }): { any }
	local items = {}
	for _, command in list do
		table.insert(items, {
			Label = command.Label,
			Detail = command.Detail,
			Icon = command.Icon,
			Group = command.Open ~= nil,
			Accent = command.Accent,
			Badge = (command :: any).Badge,
		})
	end
	return items
end

-- La tecla E va con el comando elegido si es algo del mapa; si no, con lo más cercano
local function updateFocus()
	local command = selected()
	ContextDetector.setFocus(command and command.Prompt or nil)
	local focus = ContextDetector.getFocus()
	for _, listener in focusListeners do
		listener(focus)
	end
end

local function keyOf(list: { Command }): string
	local parts = {}
	for _, command in list do
		table.insert(parts, command.Id .. "|" .. command.Label .. "|" .. (command.Detail or "") .. "|" .. tostring((command :: any).Badge))
	end
	return table.concat(parts, ";")
end

local function showLevel(motion: string?)
	local level = current()
	renderer:setHeader(level.Title)
	renderer:setItems(toItems(level.Items), level.Index, motion)
	updateFocus()
end

-- Rehace la lista principal con lo que hay ahora alrededor (sin mover lo que has elegido)
local function refresh()
	if #stack == 0 then
		return
	end
	local ctx = ContextDetector.get()
	local list = CommandRegistry.list(ctx)
	local level = stack[1]
	local key = keyOf(list)
	if key ~= signature then
		signature = key
		-- Lo que habías elegido sigue elegido (aunque la lista cambie); solo si llevas un rato sin tocar
		-- el menú y aparece algo nuevo delante de ti, pasa a eso (MenuLogic.pickIndex)
		local index = MenuLogic.pickIndex(level.Items, level.Index, list, os.clock() - lastInput, IDLE_RESET)
		level.Items = list
		level.Index = index
		level.Title = "Comandos" -- (con quién o qué: en la segunda columna de cada fila)
		if #stack == 1 then
			showLevel(nil)
		end
	elseif #stack == 1 then
		-- La lista es la misma, pero puede haber cambiado cuál está más cerca
		updateFocus()
	end
	renderer:setVisible(not busy and #stack[1].Items > 0)
end

-- Filas que caben: 4-5 normalmente; desplegado, todas las que quepan hasta tu estado
local function applyWindow()
	local layout = HudLayout.current()
	local rows = layout.CommandRows
	if expanded then
		local placement = layout.Items.Commands
		local bottom = layout.Canvas.Y + placement.Position.Y.Offset
		local room = bottom - layout.CommandTop - HudLayout.commandHeight(0, layout.Touch)
		rows = math.max(rows, math.floor(room / HudLayout.Sizes.CommandPitch))
	end
	renderer:setExpanded(expanded, rows)
end

local function setCollapsed(value: boolean)
	collapsed = value
	renderer:setCollapsed(value)
	UiAudio.move()
end

local function move(delta: number)
	local level = current()
	if not level or #level.Items == 0 then
		return
	end
	lastInput = os.clock()
	level.Index = (level.Index - 1 + delta) % #level.Items + 1
	renderer:select(level.Index)
	UiAudio.move()
	updateFocus()
end

local function back(): boolean
	if #stack <= 1 then
		return false
	end
	lastInput = os.clock()
	table.remove(stack)
	UiAudio.cancel()
	showLevel("pop")
	return true
end

local function accept(index: number?)
	local level = current()
	if not level or busy then
		return
	end
	lastInput = os.clock()
	if index then
		level.Index = index
		renderer:select(index)
	end
	local command = level.Items[level.Index]
	if not command then
		return
	end
	if command.Id == BACK.Id then
		back()
		return
	end
	local ctx = ContextDetector.get()
	if command.Open then
		local children = CommandRegistry.open(command, ctx)
		if #children == 0 then
			UiAudio.error()
			renderer:shake(level.Index)
			return
		end
		table.insert(children, BACK)
		UiAudio.open()
		renderer:flash(level.Index)
		table.insert(stack, { Title = command.Label, Items = children, Index = 1, Group = command })
		showLevel("push")
		return
	end
	UiAudio.confirm()
	renderer:flash(level.Index)
	if command.Prompt then
		ContextDetector.trigger(command.Prompt)
	elseif command.Run then
		local ok, err = pcall(command.Run, ctx)
		if not ok then
			warn("[Comandos] " .. tostring(err))
		end
	end
	-- Tras usar algo de un submenú se vuelve a la lista principal
	if #stack > 1 and not (command :: any).Stay then
		stack = { stack[1] }
		signature = ""
		refresh()
		showLevel("pop")
	end
end

local function hint(): string
	if UserInputService.GamepadEnabled and UserInputService:GetLastInputType().Name:find("Gamepad") then
		return "Cruceta elegir · → aceptar · B volver · ← ocultar"
	end
	return "↑↓ elegir · Enter aceptar · E usar · Tab ocultar"
end

-- Enlaza las teclas y la cruceta (solo cuando el menú está a la vista y no se escribe en el chat)
local function bindInput()
	local function available(): boolean
		return not busy and gui.Enabled and renderer.Root.Visible and not UserInputService:GetFocusedTextBox() and GuiService.SelectedObject == nil
	end
	-- Oculto: cualquier flecha lo vuelve a abrir (y no hace nada más)
	local function openIfCollapsed(): boolean
		if collapsed then
			setCollapsed(false)
			return true
		end
		return false
	end
	local function handler(callback: () -> boolean?)
		return function(_, state: Enum.UserInputState)
			if state ~= Enum.UserInputState.Begin or not available() then
				return Enum.ContextActionResult.Pass
			end
			local used = callback()
			return if used == false then Enum.ContextActionResult.Pass else Enum.ContextActionResult.Sink
		end
	end
	-- ↑ ↓ del teclado también mueven al personaje (y aceleran/frenan el coche): solo se quedan
	-- para el menú cuando está desplegado. Conduciendo, ni flechas ni cruceta (sirena, claxon…).
	local function step(delta: number, state: Enum.UserInputState)
		return handler(function()
			if not openIfCollapsed() then
				move(delta)
			end
			return true
		end)(nil, state)
	end
	local function arrows(delta: number)
		return function(_, state: Enum.UserInputState, input: InputObject)
			if player:GetAttribute("Riding") ~= nil then
				return Enum.ContextActionResult.Pass
			end
			local keyboard = input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.Down
			if keyboard and (not expanded or collapsed) then
				return Enum.ContextActionResult.Pass
			end
			return step(delta, state)
		end
	end
	ContextActionService:BindActionAtPriority("CommandUp", arrows(-1), false, 3000, Enum.KeyCode.Up, Enum.KeyCode.DPadUp)
	ContextActionService:BindActionAtPriority("CommandDown", arrows(1), false, 3000, Enum.KeyCode.Down, Enum.KeyCode.DPadDown)
	ContextActionService:BindActionAtPriority("CommandAccept", handler(function()
		if openIfCollapsed() then
			return true
		end
		if collapsed then
			return false
		end
		accept()
		return true
	end), false, 3000, Enum.KeyCode.Return, Enum.KeyCode.KeypadEnter, Enum.KeyCode.DPadRight)
	ContextActionService:BindActionAtPriority("CommandBack", handler(function()
		if collapsed then
			return false
		end
		return back()
	end), false, 3000, Enum.KeyCode.Backspace, Enum.KeyCode.Left, Enum.KeyCode.DPadLeft, Enum.KeyCode.ButtonB)
	-- Ocultar / mostrar: Tab (o ← de la cruceta en la lista principal)
	ContextActionService:BindActionAtPriority("CommandToggle", handler(function()
		CommandMenu.toggle()
		return true
	end), false, 3000, Enum.KeyCode.Tab)
	ContextActionService:BindActionAtPriority("CommandHide", function(_, state: Enum.UserInputState)
		if state ~= Enum.UserInputState.Begin or not available() or collapsed or #stack > 1 then
			return Enum.ContextActionResult.Pass
		end
		CommandMenu.toggle()
		return Enum.ContextActionResult.Sink
	end, false, 2900, Enum.KeyCode.DPadLeft)
	UserInputService.LastInputTypeChanged:Connect(function()
		renderer:setHint(hint())
	end)
end

-- Mientras hablas con alguien o ves una cinemática, el menú se aparta
function CommandMenu.setBusy(value: boolean)
	busy = value
	if renderer then
		renderer:setVisible(not busy and #stack > 0 and #stack[1].Items > 0)
	end
end

-- Quien dibuja los carteles "pulsa E" (y el botón Interactuar) se entera de cuál va con la E
function CommandMenu.onFocus(callback: (ProximityPrompt?) -> ())
	table.insert(focusListeners, callback)
end

-- Ocultar / mostrar el menú (botón de la pestaña, Tab, ← de la cruceta)
function CommandMenu.toggle()
	if renderer then
		setCollapsed(not collapsed)
	end
end

function CommandMenu.isCollapsed(): boolean
	return collapsed
end

-- Botón Interactuar: usa lo que tienes delante (el cartel del foco); si no hay nada, el comando elegido
function CommandMenu.interact()
	if busy then
		return
	end
	local prompt = ContextDetector.getFocus()
	if prompt then
		ContextDetector.trigger(prompt)
		return
	end
	local command = selected()
	if command and command.Prompt then
		ContextDetector.trigger(command.Prompt)
	end
end

-- Vuelve a pedir la lista (p. ej. al cambiar algo que no avisa solo)
function CommandMenu.refresh()
	signature = ""
	refresh()
end

function CommandMenu.init()
	gui = Theme.create("ScreenGui", {
		Name = "CommandMenuGui",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 2,
		Parent = player:WaitForChild("PlayerGui"),
	})
	HudLayout.scaleGui(gui)
	renderer = CommandRenderer.new(gui, TOUCH)
	-- Abajo a la izquierda en todos los dispositivos (en el móvil, encima del joystick)
	HudLayout.onChanged(function(layout)
		HudLayout.apply(renderer.Root, layout.Items.Commands, true)
		applyWindow()
	end)
	renderer.ToggleCallback = CommandMenu.toggle
	renderer.ExpandCallback = function()
		expanded = not expanded
		applyWindow()
		UiAudio.open()
	end

	renderer.HoverCallback = function(index: number)
		local level = current()
		if level and level.Index ~= index then
			lastInput = os.clock()
			level.Index = index
			renderer:select(index)
			UiAudio.move()
			updateFocus()
		end
	end
	renderer.ActivateCallback = function(index: number)
		local level = current()
		-- En el móvil: un toque elige y otro toque sobre el elegido lo hace (nunca sin querer)
		if TOUCH and level and level.Index ~= index then
			lastInput = os.clock()
			level.Index = index
			renderer:select(index)
			UiAudio.move()
			updateFocus()
			return
		end
		accept(index)
	end
	renderer:setHint(hint())

	stack = { { Title = "Comandos", Items = {}, Index = 1 } }
	renderer:setCollapsed(collapsed)
	-- Botón Interactuar (racimo táctil): usa lo que tienes delante y dice qué es ("Hablar", "Entrar"…)
	TouchLayout.register({
		Id = "Interactuar",
		Icon = "interactuar",
		Label = "Interactuar",
		Slot = "Interactuar",
		Priority = 1,
		Key = "E",
		Pad = "X",
		Callback = CommandMenu.interact,
	})
	table.insert(focusListeners, function(prompt: ProximityPrompt?)
		local text = prompt and prompt.ActionText
		TouchLayout.setLabel("Interactuar", if text and text ~= "" and #text <= 12 then text else nil)
		TouchLayout.setDim("Interactuar", prompt == nil)
	end)
	ContextDetector.init()
	ContextDetector.onChanged(refresh)
	bindInput()
	refresh()
	showLevel(nil)
	renderer:setVisible(false)
	refresh()
	-- Lo que está más cerca cambia al andar: se revisa unas veces por segundo
	task.spawn(function()
		while gui.Parent do
			task.wait(0.4)
			refresh()
		end
	end)
end

return CommandMenu
