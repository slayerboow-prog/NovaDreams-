-- CommandMenu: el menú de comandos, siempre presente abajo a la izquierda mientras juegas.
--
--   * Lista vertical; el comando elegido brilla, crece y lleva el cursor ▶.
--   * Cambia con el contexto (ContextDetector): lo que tienes delante sale arriba del todo.
--   * Los grupos (▸) abren submenús; "◂ Volver" (o ← / Retroceso / B) regresa.
--   * El comando elegido es también lo que hace la tecla E / el botón X del mando.
--
-- Controles:
--   Teclado:  ↑ ↓ elegir · Enter aceptar · ← o Retroceso volver · E usar lo que tienes delante
--   Mando:    cruceta ↑ ↓ elegir · cruceta → aceptar · cruceta ← o B volver · X usar
--   Móvil:    tocar un comando lo acepta
-- Mientras hablas con alguien o ves una cinemática se aparta (setBusy).

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.UI.Theme)
local CommandRegistry = require(script.Parent.CommandRegistry)
local ContextDetector = require(script.Parent.ContextDetector)
local CommandRenderer = require(script.Parent.CommandRenderer)
local UiAudio = require(script.Parent.UiAudio)

local CommandMenu = {}

local player = Players.LocalPlayer
local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local IDLE_RESET = 4 -- segundos sin tocar el menú: vuelve a elegirse lo que tienes delante

type Command = CommandRegistry.Command
type Level = { Title: string, Items: { Command }, Index: number, Group: Command? }

local renderer: any
local gui: ScreenGui
local stack: { Level } = {}
local lastInput = -math.huge
local busy = false
local signature = ""
local onFocusChanged: ((ProximityPrompt?) -> ())? = nil

local BACK: Command = { Id = "_Volver", Label = "Volver", Icon = "◂", Priority = 1e9 }

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
	if onFocusChanged then
		onFocusChanged(ContextDetector.getFocus())
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
		local keep = level.Items[level.Index]
		level.Items = list
		level.Index = 1
		-- Si hace poco que elegiste algo, se mantiene; si no, arriba del todo (lo que tienes delante)
		if keep and os.clock() - lastInput < IDLE_RESET then
			for i, command in list do
				if command.Id == keep.Id then
					level.Index = i
				end
			end
		end
		local target = ctx.Target
		level.Title = if target and target.Detail ~= "" then target.Detail else "Comandos"
		if #stack == 1 then
			showLevel(nil)
		end
	elseif #stack == 1 then
		-- La lista es la misma, pero puede haber cambiado cuál está más cerca
		updateFocus()
	end
	renderer:setVisible(not busy and #stack[1].Items > 0)
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
	if not level then
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
		return "✚ elegir · ✚→ aceptar · B volver · X usar"
	end
	return "↑↓ elegir · Enter aceptar · ← volver · E usar"
end

-- Enlaza las teclas y la cruceta (solo cuando el menú está a la vista y no se escribe en el chat)
local function bindInput()
	local function available(): boolean
		return not busy and gui.Enabled and renderer.Root.Visible and not UserInputService:GetFocusedTextBox() and GuiService.SelectedObject == nil
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
	ContextActionService:BindActionAtPriority("CommandUp", handler(function()
		move(-1)
		return true
	end), false, 3000, Enum.KeyCode.Up, Enum.KeyCode.DPadUp)
	ContextActionService:BindActionAtPriority("CommandDown", handler(function()
		move(1)
		return true
	end), false, 3000, Enum.KeyCode.Down, Enum.KeyCode.DPadDown)
	ContextActionService:BindActionAtPriority("CommandAccept", handler(function()
		accept()
		return true
	end), false, 3000, Enum.KeyCode.Return, Enum.KeyCode.KeypadEnter, Enum.KeyCode.DPadRight)
	ContextActionService:BindActionAtPriority("CommandBack", handler(function()
		return back()
	end), false, 3000, Enum.KeyCode.Backspace, Enum.KeyCode.Left, Enum.KeyCode.DPadLeft, Enum.KeyCode.ButtonB)
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

-- Quien dibuja los carteles "pulsa E" se entera de cuál es el que va con la E
function CommandMenu.onFocus(callback: (ProximityPrompt?) -> ())
	onFocusChanged = callback
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
	renderer = CommandRenderer.new(gui, TOUCH)
	local scale = Theme.create("UIScale", { Parent = renderer.Root })
	local camera = workspace.CurrentCamera
	local function layout()
		local view = camera.ViewportSize
		local hud = math.clamp(math.min(view.Y / 900, view.X / 1700), 0.55, 1.2)
		-- en el móvil un poco más grande para poder tocarlo bien
		scale.Scale = if TOUCH then math.max(hud, 0.72) else hud
		renderer.Root.Position = UDim2.new(0, if TOUCH then 10 else 18, 1, if TOUCH then -10 else -16)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
	layout()

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
		accept(index)
	end
	renderer:setHint(hint())

	stack = { { Title = "Comandos", Items = {}, Index = 1 } }
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
