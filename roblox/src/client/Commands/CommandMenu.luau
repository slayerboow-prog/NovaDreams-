-- CommandMenu: lleva los comandos del juego a donde se usan. Ya no hay panel «COMANDOS» a la
-- izquierda: el mismo registro de comandos (CommandRegistry + ContextDetector) se reparte así
-- (Commands/PhoneApps.split):
--
--   * Las ACCIONES DE AHORA (lo que tienes delante, saludar, bajarse, pelear, disparar, apuntar,
--     recargar, robar, detener…) -> la tira de acciones junto a los botones (Commands/ContextStrip):
--       Ordenador: píldoras encima de la lista de teclas; ratón para elegir, Enter para hacerla,
--                  E usa lo del mapa (la elegida si es algo del mapa; si no, lo más cercano).
--       Mando:     cruceta ↑ ↓ elegir · cruceta → hacerla · X usar lo de delante.
--       Móvil:     el botón Interactuar hace lo de delante (dice qué: «Hablar», «Entrar»…) y la
--                  burbuja «Acciones» (a su izquierda) el resto: con una sola, la hace; con varias,
--                  abre la lista y un toque hace cada una.
--   * Todo lo demás (Mapa, Mochila, Ir a casa, Tienda, Vehículos, Gestos, Metro, Mercadillo, Pesca,
--     Pase de temporada, Misiones, Mi historia, Personaje, Viviendas, Carrera, Controles, Ajustes,
--     Mensajes, Cartera, Ayuda, Modo pruebas…) -> apps del ValPhone (UI/Phone), que asoma abajo a
--     la izquierda: tocarlo, Tab o Select del mando lo abre. Dentro: flechas / cruceta para elegir,
--     Enter o A para abrir, Retroceso o B atrás.
--   * Al volante o volando el teléfono solo se abre parado (en marcha se guarda solo).
-- Mientras hablas con alguien o ves una cinemática todo se aparta (setBusy).

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.UI.Theme)
local HudLayout = require(script.Parent.Parent.UI.HudLayout)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local Phone = require(script.Parent.Parent.UI.Phone)
local PhoneInbox = require(script.Parent.Parent.UI.PhoneInbox)
local CommandRegistry = require(script.Parent.CommandRegistry)
local ContextDetector = require(script.Parent.ContextDetector)
local ContextStrip = require(script.Parent.ContextStrip)
local PhoneApps = require(script.Parent.PhoneApps)
local UiAudio = require(script.Parent.UiAudio)
local MenuLogic = require(script.Parent.MenuLogic)

local CommandMenu = {}

local player = Players.LocalPlayer
local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local IDLE_RESET = MenuLogic.IdleReset
local MOVING_SPEED = 4 -- studs/s: más rápido que esto, el vehículo va en marcha (el teléfono no se abre)

type Command = CommandRegistry.Command
type Level = { Title: string, Items: { Command }, Index: number }

local gui: ScreenGui
local strip: any
local started = false
local busy = false
local lastInput = -math.huge
local focusListeners: { (ProximityPrompt?) -> () } = {}
local context: { Command } = {} -- todas las acciones de ahora (para la tira)
local levels: { Level } = {} -- la tira: [1] las de ahora; más arriba, un grupo abierto («Aquí ▸»…)
local stripOpen = false -- (móvil) la lista de la burbuja abierta
local appById: { [string]: Command } = {}
local appList: { Command } = {}
local badgeState: { [string]: number } = {}
local primed = false -- (la primera vez no se avisa de nada: no es nuevo)
local settings: { any } = {}
local messages: { any } = {}

local BACK: Command = { Id = "_Volver", Label = "Volver", Icon = "volver", Priority = 1e9 }

local function hud(): any
	local ok, module = pcall(require, script.Parent.Parent.UI.Hud :: any)
	return if ok then module else nil
end

local function toast(kind: string, text: string)
	local Hud = hud()
	if Hud and Hud.toast then
		Hud.toast(kind, text)
	end
end

---------------------------------------------------------------------
-- La tira de acciones
---------------------------------------------------------------------
-- Móvil: lo de delante lo hace el botón Interactuar; la burbuja lleva el resto
local function touchList(list: { Command }): { Command }
	if not TOUCH then
		return list
	end
	local focus = ContextDetector.getFocus()
	local out = {}
	for _, command in list do
		if not (focus and command.Prompt == focus) then
			table.insert(out, command)
		end
	end
	return out
end

local function level(): Level?
	return levels[#levels]
end

local function selected(): Command?
	local now = level()
	return now and now.Items[now.Index]
end

-- La tecla E va con la acción elegida si es algo del mapa; si no, con lo más cercano
local function updateFocus()
	local command = if TOUCH then nil else selected()
	ContextDetector.setFocus(command and command.Prompt or nil)
	local focus = ContextDetector.getFocus()
	for _, listener in focusListeners do
		listener(focus)
	end
end

local function toItems(list: { Command }, index: number): { any }
	local items = {}
	for i, command in list do
		table.insert(items, {
			Label = command.Label,
			Detail = command.Detail,
			Icon = command.Icon,
			Group = command.Open ~= nil,
			Accent = command.Accent,
			Key = if i == index then (if command.Prompt then "E" else "Enter") else nil,
		})
	end
	return items
end

local function showStrip()
	if not strip then
		return
	end
	local now = level()
	if not now then
		return
	end
	local index = if TOUCH then 0 else now.Index
	strip:setItems(toItems(now.Items, index), index, if #levels > 1 then now.Title else "Acciones")
	local visible = not busy and #now.Items > 0 and (not TOUCH or stripOpen)
	strip:setVisible(visible)
end

local function closeStrip()
	if stripOpen then
		stripOpen = false
		while #levels > 1 do
			table.remove(levels)
		end
		showStrip()
		TouchLayout.refresh()
	end
end

-- El botón burbuja (móvil): icono y texto de la primera acción, y cuántas hay
local function paintBubble()
	if not TOUCH then
		return
	end
	local main = levels[1]
	local list = main and main.Items or {}
	local first = list[1]
	if #list == 1 and first then
		TouchLayout.setLabel("Contexto", if #first.Label <= 12 then first.Label else "Acción")
	else
		TouchLayout.setLabel("Contexto", nil)
	end
	TouchLayout.setIcon("Contexto", if first then first.Icon else nil)
	if #list == 0 then
		closeStrip()
	end
end

local function runCommand(command: Command, ctx: { [string]: any })
	if command.Prompt then
		ContextDetector.trigger(command.Prompt)
	elseif command.Run then
		local ok, err = pcall(command.Run, ctx)
		if not ok then
			warn("[Comandos] " .. tostring(err))
		end
	end
end

local function back(): boolean
	if #levels <= 1 then
		return false
	end
	lastInput = os.clock()
	table.remove(levels)
	UiAudio.cancel()
	showStrip()
	updateFocus()
	return true
end

-- Hace la acción `index` de la tira (o abre su grupo)
local function acceptStrip(index: number?)
	local now = level()
	if not now or busy then
		return
	end
	lastInput = os.clock()
	if index then
		now.Index = index
	end
	local command = now.Items[now.Index]
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
			return
		end
		table.insert(children, BACK)
		UiAudio.open()
		table.insert(levels, { Title = command.Label, Items = children, Index = 1 })
		showStrip()
		updateFocus()
		return
	end
	UiAudio.confirm()
	strip:flash(now.Index)
	runCommand(command, ctx)
	local stay = (command :: any).Stay == true
	-- Tras usar algo de un grupo se vuelve a las de ahora; en el móvil la lista se cierra (salvo las
	-- que se repiten: disparar, atacar, defenderse…)
	if not stay then
		while #levels > 1 do
			table.remove(levels)
		end
		if TOUCH then
			stripOpen = false
		end
	end
	CommandMenu.refresh()
end

-- (móvil) la burbuja: con una acción la hace; con varias abre (o cierra) la lista
local function onBubble()
	if busy then
		return
	end
	local main = levels[1]
	local list = main and main.Items or {}
	if #list == 1 and not list[1].Open and not stripOpen then
		main.Index = 1
		acceptStrip(1)
		return
	end
	stripOpen = not stripOpen
	if stripOpen then
		Phone.close()
		UiAudio.open()
		local button = TouchLayout.buttons().Contexto
		if button then
			local half = button.Size.X.Offset / 2
			strip:anchorAt(button.Position + UDim2.fromOffset(-(half + 10), half))
		end
	else
		UiAudio.cancel()
		while #levels > 1 do
			table.remove(levels)
		end
	end
	showStrip()
end

local function moveStrip(delta: number): boolean
	local now = level()
	if not now or #now.Items == 0 then
		return false
	end
	lastInput = os.clock()
	now.Index = (now.Index - 1 + delta) % #now.Items + 1
	UiAudio.move()
	showStrip()
	updateFocus()
	return true
end

---------------------------------------------------------------------
-- El ValPhone: apps y pantallas
---------------------------------------------------------------------
local function appView(command: Command): any
	local meta = PhoneApps.meta(command)
	return {
		Id = command.Id,
		Name = meta.Name,
		Icon = meta.Icon,
		Color = meta.Color,
		Badge = PhoneApps.badgeCount(command),
		Screen = meta.Screen,
		Group = command.Open ~= nil,
	}
end

-- Avisos que bajan del teléfono cuando una app enciende su punto rojo (pase, misiones…)
local NOTICES = {
	PaseTemporada = "🏆 ¡Tienes recompensas del pase por reclamar!",
	Misiones = "📋 Tienes una misión nueva",
}

local function noticeBadges()
	local fresh, after = PhoneApps.newBadges(badgeState, appList)
	badgeState = after
	if not primed then
		primed = true
		return
	end
	for _, command in fresh do
		-- (los mensajes avisan solos: PhoneInbox)
		if command.Id ~= "Mensajes" and not busy and not Phone.isOpen() then
			local meta = PhoneApps.meta(command)
			Phone.notify({ App = command.Id, Title = meta.Name, Text = NOTICES[command.Id] or command.Detail or ("Novedades en " .. meta.Name) })
		end
	end
end

local function jobName(): string
	local id = player:GetAttribute("Job")
	if not id then
		return "Sin trabajo"
	end
	local ok, name = pcall(function()
		local Config = require(ReplicatedStorage.Shared.Config :: any)
		local Gameplay = require(ReplicatedStorage.Shared.Gameplay :: any)
		local job = Config.Jobs[id] or Gameplay.Jobs[id]
		return job and job.DisplayName
	end)
	return if ok and name then name else tostring(id)
end

local function money(amount: number): string
	local ok, text = pcall(function()
		local Format = require(ReplicatedStorage.Shared.Format :: any)
		return Format.money(amount)
	end)
	return if ok then text else tostring(amount)
end

-- Pantallas propias del teléfono
local function showAjustes()
	settings = {}
	local Hud = hud()
	local rows = {}
	for _, toggle in (Hud and Hud.menuToggles and Hud.menuToggles()) or {} do
		table.insert(settings, toggle)
		table.insert(rows, { Label = toggle.Text })
	end
	Phone.showScreen("Ajustes", "Ajustes", rows, "Sin ajustes por ahora")
end

local function showMensajes()
	messages = PhoneInbox.list()
	local rows = {}
	for _, message in messages do
		table.insert(rows, {
			Icon = message.Icon,
			Color = { 48, 209, 88 },
			Label = message.From or "Valmar",
			Detail = message.Text,
			Wrap = true,
			Unread = not message.Read,
			Id = message.Open,
		})
	end
	Phone.showScreen("Mensajes", "Mensajes", rows, "No tienes mensajes. Cuando alguien quiera hablar contigo, te escribirá aquí.")
	PhoneInbox.markAllRead()
end

local function showCartera()
	local homes = player:GetAttribute("Homes")
	local count = 0
	if type(homes) == "string" then
		for _ in string.gmatch(homes, "[^\n]+") do
			count += 1
		end
	end
	local tickets = tonumber(player:GetAttribute("Tickets")) or 0
	local rows = {
		{ Icon = "dinero", Color = { 30, 150, 95 }, Label = "Dinero", Value = money(tonumber(player:GetAttribute("Money")) or 0) },
		{ Icon = "personaje", Color = { 146, 104, 255 }, Label = "Nivel", Value = tostring(player:GetAttribute("Level") or 1) },
		{ Icon = "trabajo", Color = { 255, 159, 10 }, Label = "Trabajo", Detail = jobName() },
		{ Icon = "viviendas", Color = { 88, 86, 214 }, Label = "Viviendas", Value = tostring(count) },
	}
	if tickets > 0 then
		table.insert(rows, { Icon = "🎟", Color = { 210, 40, 60 }, Label = "Billetes", Value = tostring(tickets) })
	end
	Phone.showScreen("Cartera", "Cartera", rows)
end

local groupChildren: { Command } = {}

local function launch(id: string)
	local command = appById[id]
	if not command then
		return
	end
	local meta = PhoneApps.meta(command)
	UiAudio.confirm()
	if meta.Screen == "Ajustes" then
		showAjustes()
	elseif meta.Screen == "Mensajes" then
		showMensajes()
	elseif meta.Screen == "Cartera" then
		showCartera()
	elseif command.Open then
		-- Un grupo (p. ej. «Gestos del pase»): su lista dentro del teléfono
		groupChildren = CommandRegistry.open(command, ContextDetector.get())
		local rows = {}
		for _, child in groupChildren do
			table.insert(rows, { Id = child.Id, Icon = child.Icon, Label = child.Label, Detail = child.Detail, Color = meta.Color })
		end
		Phone.showScreen("Lista:" .. id, meta.Name, rows, "Aquí no hay nada todavía")
	else
		-- Las demás abren su ventana de siempre: el teléfono se guarda primero
		Phone.close()
		runCommand(command, ContextDetector.get())
	end
end

local function onRow(screen: string, index: number, row: any)
	if screen == "Ajustes" then
		local toggle = settings[index]
		if toggle then
			local before = toggle.Text
			local ok, text = pcall(toggle.Press)
			if ok and type(text) == "string" then
				Phone.setRowLabel(index, text)
			end
			UiAudio.confirm()
			-- Las que no cambian de texto son acciones que abren algo (Mi historia, ver el tutorial):
			-- el teléfono se guarda para que se vea
			if ok and text == before then
				Phone.close()
			end
		end
	elseif screen == "Mensajes" then
		-- Un mensaje que lleva a algo (p. ej. «síguela en Misiones»): abre esa app
		if row.Id and appById[row.Id] then
			launch(row.Id)
		end
	elseif string.sub(screen, 1, 6) == "Lista:" then
		local child = groupChildren[index]
		if child then
			UiAudio.confirm()
			if not (child :: any).Stay then
				Phone.close()
			end
			runCommand(child, ContextDetector.get())
		end
	end
end

---------------------------------------------------------------------
-- Rehacer todo con lo que hay ahora alrededor
---------------------------------------------------------------------
local signature = ""
local function keyOf(list: { Command }): string
	local out = {}
	for _, command in list do
		table.insert(out, command.Id .. "|" .. command.Label .. "|" .. (command.Detail or "") .. "|" .. tostring((command :: any).Badge))
	end
	return table.concat(out, ";")
end

local function refresh()
	if not started then
		return
	end
	local ctx = ContextDetector.get()
	local list = CommandRegistry.list(ctx)
	local actions, apps = PhoneApps.split(list, function(group)
		return CommandRegistry.open(group, ctx)
	end)
	context = actions
	-- Apps del teléfono
	appById = {}
	appList = apps
	local views = {}
	for _, command in apps do
		appById[command.Id] = command
		table.insert(views, appView(command))
	end
	Phone.setApps(views)
	noticeBadges()
	-- La tira (sin mover lo que has elegido: MenuLogic.pickIndex)
	local main = levels[1]
	local shown = touchList(actions)
	local key = keyOf(shown)
	if key ~= signature then
		signature = key
		local index = MenuLogic.pickIndex(main.Items, main.Index, shown, os.clock() - lastInput, IDLE_RESET)
		main.Items = shown
		main.Index = index
	end
	paintBubble()
	showStrip()
	updateFocus()
end

-- Al volante / volando: el teléfono asoma en otro sitio y solo se abre parado
local function vehicleState()
	local atWheel = player:GetAttribute("Riding") ~= nil or TouchLayout.isFlying() or TouchLayout.isDriving()
	local inMotion = false
	if atWheel then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local seat = humanoid and humanoid.SeatPart
		local ok, speed = pcall(function()
			return (seat :: any).AssemblyLinearVelocity.Magnitude
		end)
		inMotion = ok and type(speed) == "number" and speed > MOVING_SPEED
	end
	Phone.setVehicle(atWheel, inMotion)
end

---------------------------------------------------------------------
-- Teclado y mando
---------------------------------------------------------------------
local function bindInput()
	local function typing(): boolean
		return UserInputService:GetFocusedTextBox() ~= nil
	end
	local PASS, SINK = Enum.ContextActionResult.Pass, Enum.ContextActionResult.Sink
	-- Tab / Select del mando: el ValPhone
	ContextActionService:BindActionAtPriority("PhoneToggle", function(_, state: Enum.UserInputState)
		if state ~= Enum.UserInputState.Begin or typing() or busy then
			return PASS
		end
		CommandMenu.toggle()
		return SINK
	end, false, 3000, Enum.KeyCode.Tab, Enum.KeyCode.ButtonSelect)
	-- Flechas / cruceta: con el teléfono abierto, moverse por las apps; cerrado, la cruceta ↑ ↓ elige
	-- en la tira (las flechas del teclado son para andar)
	local DIRS = {
		[Enum.KeyCode.Up] = { 0, -1 },
		[Enum.KeyCode.Down] = { 0, 1 },
		[Enum.KeyCode.Left] = { -1, 0 },
		[Enum.KeyCode.Right] = { 1, 0 },
		[Enum.KeyCode.DPadUp] = { 0, -1 },
		[Enum.KeyCode.DPadDown] = { 0, 1 },
		[Enum.KeyCode.DPadLeft] = { -1, 0 },
		[Enum.KeyCode.DPadRight] = { 1, 0 },
	}
	ContextActionService:BindActionAtPriority("PhoneNavigate", function(_, state: Enum.UserInputState, input: InputObject)
		if state ~= Enum.UserInputState.Begin or typing() then
			return PASS
		end
		local dir = DIRS[input.KeyCode]
		if not dir then
			return PASS
		end
		if Phone.isOpen() then
			Phone.navigate(dir[1], dir[2])
			UiAudio.move()
			return SINK
		end
		-- Cerrado: solo la cruceta, y no conduciendo (sirena, claxon…)
		local pad = input.KeyCode == Enum.KeyCode.DPadUp or input.KeyCode == Enum.KeyCode.DPadDown or input.KeyCode == Enum.KeyCode.DPadRight
		if not pad or busy or player:GetAttribute("Riding") ~= nil then
			return PASS
		end
		if input.KeyCode == Enum.KeyCode.DPadRight then
			if selected() then
				acceptStrip()
				return SINK
			end
			return PASS
		end
		return if moveStrip(dir[2]) then SINK else PASS
	end, false, 3000, Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right, Enum.KeyCode.DPadUp, Enum.KeyCode.DPadDown, Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadRight)
	-- Enter (o A con el teléfono abierto): abrir la app elegida; cerrado, hacer la acción elegida
	ContextActionService:BindActionAtPriority("CommandAccept", function(_, state: Enum.UserInputState, input: InputObject)
		if state ~= Enum.UserInputState.Begin or typing() or busy then
			return PASS
		end
		if Phone.isOpen() then
			Phone.accept()
			return SINK
		end
		if input.KeyCode == Enum.KeyCode.ButtonA then
			return PASS -- (A es saltar)
		end
		if selected() then
			acceptStrip()
			return SINK
		end
		return PASS
	end, false, 3000, Enum.KeyCode.Return, Enum.KeyCode.KeypadEnter, Enum.KeyCode.ButtonA)
	-- Retroceso / B: atrás en el teléfono (o lo cierra); en la tira, sale del grupo
	ContextActionService:BindActionAtPriority("CommandBack", function(_, state: Enum.UserInputState)
		if state ~= Enum.UserInputState.Begin or typing() then
			return PASS
		end
		if Phone.isOpen() then
			Phone.back()
			UiAudio.cancel()
			return SINK
		end
		if stripOpen and #levels <= 1 then
			closeStrip()
			return SINK
		end
		return if back() then SINK else PASS
	end, false, 3000, Enum.KeyCode.Backspace, Enum.KeyCode.ButtonB)
end

---------------------------------------------------------------------
-- API
---------------------------------------------------------------------
-- Mientras hablas con alguien o ves una cinemática, todo se aparta
function CommandMenu.setBusy(value: boolean)
	busy = value
	if not started then
		return
	end
	if value then
		stripOpen = false
	end
	Phone.setHidden(value)
	showStrip()
end

-- Quien dibuja los carteles "pulsa E" (y el botón Interactuar) se entera de cuál va con la E
function CommandMenu.onFocus(callback: (ProximityPrompt?) -> ())
	table.insert(focusListeners, callback)
end

-- Abrir / cerrar el ValPhone (botón, Tab, Select)
function CommandMenu.toggle()
	if not started then
		return
	end
	if Phone.isOpen() then
		Phone.close()
	else
		CommandMenu.openPhone()
	end
end

function CommandMenu.openPhone(): boolean
	if not started or busy then
		return false
	end
	closeStrip()
	return Phone.open()
end

function CommandMenu.closePhone()
	if started then
		Phone.close()
	end
end

function CommandMenu.isPhoneOpen(): boolean
	return started and Phone.isOpen()
end

-- ¿Está libre la cruceta? (Stances: cruceta abajo = agacharse). Sí con el teléfono cerrado y sin
-- acciones en la tira.
function CommandMenu.isCollapsed(): boolean
	if not started then
		return true
	end
	local main = levels[1]
	return not Phone.isOpen() and (main == nil or #main.Items == 0)
end

-- Botón Interactuar: usa lo que tienes delante (el cartel del foco); si no hay nada, la acción elegida
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

-- (pruebas) lo que hay ahora: acciones de la tira, apps del teléfono y la tira (renderer)
function CommandMenu._state(): { [string]: any }
	local main = levels[1]
	return {
		Context = context,
		Strip = main and main.Items or {},
		Apps = appList,
		StripOpen = stripOpen,
		Renderer = strip,
		Launch = launch,
		AcceptStrip = acceptStrip,
		Bubble = onBubble,
		Vehicle = vehicleState,
	}
end

function CommandMenu.init()
	gui = Theme.create("ScreenGui", {
		Name = "PhoneGui",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 5, -- por encima de los botones táctiles (4): abierto, nada lo tapa
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	HudLayout.scaleGui(gui)
	local stripGui = Theme.create("ScreenGui", {
		Name = "ContextStripGui",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 5,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	HudLayout.scaleGui(stripGui)
	strip = ContextStrip.new(stripGui, TOUCH)
	Phone.mount(gui, TOUCH)
	started = true
	levels = { { Title = "Acciones", Items = {}, Index = 1 } }

	HudLayout.onChanged(function(layout)
		strip:place(layout.Items.Context, layout.ContextRows)
	end)
	strip.HoverCallback = function(index: number)
		local now = level()
		if now and now.Index ~= index then
			lastInput = os.clock()
			now.Index = index
			UiAudio.move()
			showStrip()
			updateFocus()
		end
	end
	strip.ActivateCallback = function(index: number)
		acceptStrip(index)
	end
	strip.CloseCallback = function()
		closeStrip()
	end

	Phone.LaunchCallback = launch
	Phone.RowCallback = onRow
	Phone.OpenedCallback = function(open: boolean)
		if open then
			UiAudio.open()
			closeStrip()
		else
			UiAudio.cancel()
		end
	end
	Phone.BlockedCallback = function()
		UiAudio.error()
		toast("Info", "📱 Para el vehículo para usar el ValPhone")
	end
	-- Los mensajes nuevos bajan del teléfono (y su app enciende el punto rojo)
	PhoneInbox.setDisplay(function(message)
		if not busy then
			Phone.notify({ App = "Mensajes", Icon = message.Icon, Title = message.From or "Mensajes", Text = message.Text })
		end
	end)
	PhoneInbox.onChanged(function()
		CommandMenu.refresh()
	end)

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
	-- La burbuja «Acciones» (móvil): el resto de lo de ahora, a la izquierda de Interactuar
	if TOUCH then
		TouchLayout.register({
			Id = "Contexto",
			Icon = "interactuar",
			Label = "Acciones",
			Slot = "Contexto",
			Priority = 1.6,
			Visible = function()
				local main = levels[1]
				return not busy and main ~= nil and #main.Items > 0
			end,
			Active = function()
				return stripOpen
			end,
			Badge = function()
				local main = levels[1]
				local count = if main then #main.Items else 0
				return if count > 1 then tostring(count) else nil
			end,
			Callback = onBubble,
		})
	end
	table.insert(focusListeners, function(prompt: ProximityPrompt?)
		local text = prompt and prompt.ActionText
		TouchLayout.setLabel("Interactuar", if text and text ~= "" and #text <= 12 then text else nil)
		TouchLayout.setDim("Interactuar", prompt == nil)
	end)
	ContextDetector.init()
	ContextDetector.onChanged(refresh)
	bindInput()
	refresh()
	for _, attribute in { "Riding", "Passenger" } do
		player:GetAttributeChangedSignal(attribute):Connect(vehicleState)
	end
	vehicleState()
	-- Lo que está más cerca cambia al andar (y el vehículo arranca y para): unas veces por segundo
	task.spawn(function()
		while gui.Parent do
			task.wait(0.4)
			refresh()
			vehicleState()
		end
	end)
end

return CommandMenu
