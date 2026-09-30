-- PlayerMenuUI (cliente): menú al tocar a otro jugador y panel del grupo.
--   * Toca (o haz clic) en otro jugador, o acércate y pulsa T: sale su menú con
--     "👥 Invitar al grupo", "💬 Chat" y "🤝 Comerciar".
--   * Si estás en un grupo, a la izquierda ves quién está y "Salir". Ahí salen también tus chats
--     privados (también los que te abre otro: así puedes contestar) y "🌐 Todos", que vuelve al
--     chat general (sale siempre que tengas grupo o algún chat privado; también en el menú).
--   * El chat (privado y de grupo) es el de Roblox: los canales los crea SocialService y los
--     mensajes salen en la ventana del chat de Roblox (que además los filtra).

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local Hud = require(script.Parent.Parent.UI.Hud)
local Social = require(ReplicatedStorage.Shared.Social)

local PlayerMenuUI = {}

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Remote = Remotes:WaitForChild("Social") :: RemoteEvent
local TradeRemote = Remotes:WaitForChild("Trade") :: RemoteEvent
local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

local group: { [string]: any }? = nil
-- Chats privados abiertos: canal -> título ("💬 Ana")
local privates: { [string]: string } = {}
local privateOrder: { string } = {}
local watched: { [Instance]: boolean } = {}
local refresh: () -> () = function() end

local function nameOf(other: Player): string
	return other.DisplayName or other.Name
end

local function busy(): boolean
	return not ProximityPromptService.Enabled or player:GetAttribute("InDialogue") == true
end

---------------------------------------------------------------------
-- Chat (privado y de grupo): se usa el chat de Roblox, no una ventana propia.
-- Los mensajes de los canales privados y del grupo salen en la ventana del chat de Roblox, y
-- "💬 Chat" hace que lo próximo que escribas vaya a ese canal (🌐 Todos vuelve al general).
---------------------------------------------------------------------
local function channelNamed(name: string, wait: boolean?): TextChannel?
	local folder = if wait then TextChatService:WaitForChild(Social.Folder, 5) else TextChatService:FindFirstChild(Social.Folder)
	if not folder then
		return nil
	end
	return (if wait then folder:WaitForChild(name, 5) else folder:FindFirstChild(name)) :: TextChannel?
end

local function general(): TextChannel?
	local channels = TextChatService:FindFirstChild("TextChannels")
	return channels and channels:FindFirstChild("RBXGeneral") :: TextChannel?
end

local function inputConfig(): ChatInputBarConfiguration?
	return TextChatService:FindFirstChildOfClass("ChatInputBarConfiguration")
end

-- Si escribías en ese canal (por el canal o por su nombre; o el tuyo ya no existe), vuelves al
-- chat con todos
local function backToGeneral(channel: Instance?, name: string?)
	local config = inputConfig()
	if not config then
		return
	end
	local target = config.TargetTextChannel
	if target == nil then
		return
	end
	if not (target == channel or (name ~= nil and target.Name == name) or target.Parent == nil) then
		return
	end
	local all = general()
	if all and target ~= all then
		config.TargetTextChannel = all
		Hud.toast("Info", "🌐 Ahora escribes en el chat con todos.")
	end
end

local function dropPrivate(name: string)
	if privates[name] then
		privates[name] = nil
		local i = table.find(privateOrder, name)
		if i then
			table.remove(privateOrder, i)
		end
		refresh()
	end
end

-- Mira un canal: si se borra o te sacan de él, vuelves al general (antes seguías escribiendo a un
-- canal que ya no existía y nadie leía nada)
local function watchChannel(channel: Instance)
	if watched[channel] then
		return
	end
	watched[channel] = true
	local name = channel.Name
	local function gone()
		watched[channel] = nil
		backToGeneral(channel)
		dropPrivate(name)
	end
	pcall(function()
		channel.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				gone()
			end
		end)
		channel.ChildRemoved:Connect(function(child)
			if child:IsA("TextSource") and (child :: any).UserId == player.UserId then
				gone()
			end
		end)
	end)
end

local function talkIn(channel: TextChannel?, title: string)
	local config = inputConfig()
	if not config or not channel then
		Hud.toast("Error", "El chat no está disponible ahora mismo.")
		return
	end
	config.TargetTextChannel = channel
	if channel ~= general() then
		watchChannel(channel)
	end
	Hud.toast("Info", ("💬 %s: escribe en el chat de Roblox (arriba a la izquierda)"):format(title))
end

local function talkToEveryone()
	talkIn(general(), "Chat con todos")
end

local function addPrivate(name: string, title: string)
	if not privates[name] then
		table.insert(privateOrder, name)
	end
	privates[name] = title
	refresh()
	task.spawn(function()
		local channel = channelNamed(name, true)
		if channel then
			watchChannel(channel)
		else
			dropPrivate(name)
		end
	end)
end

---------------------------------------------------------------------
-- Panel del grupo (a la izquierda)
---------------------------------------------------------------------
local groupPanel: Frame? = nil

local function renderGroup(gui: ScreenGui)
	if groupPanel then
		groupPanel:Destroy()
		groupPanel = nil
	end
	local g = group
	local chats = #privateOrder
	if not g and chats == 0 then
		return
	end
	local rows = if g then #g.Members else 0
	local panel = Theme.panel({
		Name = "Group",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(190, 70 + rows * 24 + chats * 30),
		BackgroundTransparency = 0.15,
		Parent = gui,
	})
	groupPanel = panel
	-- Chats privados (uno por fila: tocar para escribir ahí)
	local function privateRows(y: number)
		for i, name in privateOrder do
			local button = Theme.button({ Position = UDim2.fromOffset(8, y + (i - 1) * 30), Size = UDim2.new(1, -16, 0, 26), Text = privates[name], TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd, Parent = panel })
			button.Activated:Connect(function()
				talkIn(channelNamed(name), privates[name] or "Chat privado")
			end)
		end
	end
	if not g then
		-- Sin grupo: solo los chats privados y "🌐 Todos"
		Theme.label({ Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -20, 0, 24), Text = "💬 Chats", Font = Theme.FontBold, TextSize = 15, Parent = panel })
		privateRows(32)
		local all = Theme.button({ Position = UDim2.fromOffset(8, 36 + chats * 30), Size = UDim2.new(1, -16, 0, 30), Text = "🌐 Todos", TextSize = 12, Parent = panel })
		all.Activated:Connect(talkToEveryone)
		return
	end
	Theme.label({ Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -20, 0, 24), Text = ("👥 Grupo (%d/%d)"):format(rows, g.Max), Font = Theme.FontBold, TextSize = 15, Parent = panel })
	for i, m in g.Members do
		Theme.label({
			Position = UDim2.fromOffset(10, 4 + i * 24),
			Size = UDim2.new(1, -20, 0, 22),
			Text = (if m.Leader then "👑 " else "• ") .. m.Name .. (if m.UserId == player.UserId then " (tú)" else ""),
			TextSize = 13,
			TextColor3 = if m.UserId == player.UserId then C.Highlight else C.Text,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = panel,
		})
	end
	privateRows(8 + (rows + 1) * 24)
	local y = 8 + (rows + 1) * 24 + chats * 30
	local chat = Theme.button({ Position = UDim2.fromOffset(8, y), Size = UDim2.new(1 / 3, -8, 0, 30), Text = "💬 Grupo", TextSize = 12, BackgroundColor3 = C.Accent, Parent = panel })
	chat.Activated:Connect(function()
		talkIn(channelNamed(g.Channel), "Chat del grupo")
	end)
	local all = Theme.button({ Position = UDim2.new(1 / 3, 2, 0, y), Size = UDim2.new(1 / 3, -6, 0, 30), Text = "🌐 Todos", TextSize = 12, Parent = panel })
	all.Activated:Connect(talkToEveryone)
	local leave = Theme.button({ Position = UDim2.new(2 / 3, 2, 0, y), Size = UDim2.new(1 / 3, -10, 0, 30), Text = "🚪 Salir", TextSize = 12, Parent = panel })
	leave.Activated:Connect(function()
		Remote:FireServer("Leave")
	end)
end

---------------------------------------------------------------------
-- Menú del jugador
---------------------------------------------------------------------
local function inMyGroup(other: Player): boolean
	local mine = player:GetAttribute("GroupId")
	return mine ~= nil and other:GetAttribute("GroupId") == mine
end

local function openMenu(other: Player)
	if other == player or not other.Parent or busy() then
		return
	end
	local window, content = Dialog.window("PlayerMenu", "👤 " .. nameOf(other), Vector2.new(320, 306))
	-- Si el otro se va del juego, el menú se cierra (antes quedaba abierto con botones que no hacían nada)
	local leftConn = other.AncestryChanged:Connect(function(_, parent)
		if parent == nil and window.Parent then
			window:Destroy()
		end
	end)
	window.Destroying:Connect(function()
		leftConn:Disconnect()
	end)
	local list = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = content })
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	local options = {
		{ if inMyGroup(other) then "👥 Ya está en tu grupo" else "👥 Invitar al grupo", function()
			if not inMyGroup(other) then
				Remote:FireServer("Invite", other.UserId)
			end
		end },
		{ "💬 Chat", function()
			Remote:FireServer("Chat", other.UserId)
		end },
		{ "🤝 Comerciar", function()
			TradeRemote:FireServer("Request", other.UserId)
		end },
		-- (siempre: la forma de volver al chat general, también sin grupo)
		{ "🌐 Hablar con todos", talkToEveryone },
	}
	for i, option in options do
		local button = Theme.button({ Size = UDim2.new(1, 0, 0, 48), Text = option[1], TextSize = 17, LayoutOrder = i, Parent = list })
		button.Activated:Connect(function()
			window:Destroy()
			if other.Parent or i == #options then
				option[2]()
			end
		end)
	end
end

-- Aviso "Opciones" encima de cada jugador cercano (teclado: T; mando: su botón)
local function addPrompt(other: Player, character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root or root:FindFirstChild("PlayerPrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PlayerPrompt"
	prompt.ActionText = "Opciones"
	prompt.ObjectText = "👤 " .. nameOf(other)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.T
	prompt.UIOffset = Vector2.new(0, 40)
	prompt.Parent = root
	prompt.Triggered:Connect(function()
		openMenu(other)
	end)
end

local function watchPlayer(other: Player)
	if other == player then
		return
	end
	if other.Character then
		task.spawn(addPrompt, other, other.Character)
	end
	other.CharacterAdded:Connect(function(character)
		addPrompt(other, character)
	end)
end

-- Tocar (o hacer clic) en un jugador: solo un toque corto, no al mover la cámara
local pressAt: Vector2? = nil
local pressTime = 0

local function playerAt(screen: Vector2): Player?
	local camera = workspace.CurrentCamera
	local ray = camera:ScreenPointToRay(screen.X, screen.Y) -- tiene en cuenta la barra de arriba
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 300, params)
	if not hit then
		return nil
	end
	local model = hit.Instance:FindFirstAncestorOfClass("Model")
	while model do
		local other = Players:GetPlayerFromCharacter(model)
		if other then
			return other
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil
end

local function onPress(input: InputObject, processed: boolean)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		pressAt = Vector2.new(input.Position.X, input.Position.Y)
		pressTime = os.clock()
	end
end

local function onRelease(input: InputObject, processed: boolean)
	local start = pressAt
	pressAt = nil
	if processed or not start then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	local here = Vector2.new(input.Position.X, input.Position.Y)
	if (here - start).Magnitude > 12 or os.clock() - pressTime > 0.4 then
		return -- estaba moviendo la cámara
	end
	local other = playerAt(here)
	if not other then
		return
	end
	local mine = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local theirs = other.Character and other.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if mine and theirs and (mine.Position - theirs.Position).Magnitude <= Social.MenuRange then
		openMenu(other)
	end
end

---------------------------------------------------------------------

-- Pregunta de Dialog.choose que se cierra sola a los `seconds` (cuando la invitación caduca en el
-- servidor). onAnswer recibe la elección (o nil si la cierra); si caduca, no se llama.
local function chooseFor(seconds: number?, title: string, body: string?, options: { string }, onAnswer: (number?) -> ())
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local before: { [Instance]: boolean } = {}
	local dialogs = playerGui and playerGui:FindFirstChild("Dialogs")
	for _, child in (if dialogs then dialogs:GetChildren() else {}) do
		before[child] = true
	end
	local expired = false
	task.spawn(function()
		local choice = Dialog.choose(title, body, options)
		if not expired then
			onAnswer(choice)
		end
	end)
	-- (Dialog.choose crea su ventana antes de esperar: la ventana nueva es la de esta pregunta)
	dialogs = playerGui and playerGui:FindFirstChild("Dialogs")
	local window: Instance? = nil
	for _, child in (if dialogs then dialogs:GetChildren() else {}) do
		if not before[child] and string.sub(child.Name, 1, 6) == "Choose" then
			window = child
		end
	end
	if window and type(seconds) == "number" and seconds > 0 then
		task.delay(seconds, function()
			if window.Parent then
				expired = true
				window:Destroy()
			end
		end)
	end
end

function PlayerMenuUI.init()
	local gui = create("ScreenGui", {
		Name = "Social",
		ResetOnSpawn = false,
		DisplayOrder = 3,
		IgnoreGuiInset = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	Theme.fit(gui)
	refresh = function()
		renderGroup(gui)
	end

	for _, other in Players:GetPlayers() do
		watchPlayer(other)
	end
	Players.PlayerAdded:Connect(watchPlayer)

	UserInputService.InputBegan:Connect(onPress)
	UserInputService.InputEnded:Connect(onRelease)

	Remote.OnClientEvent:Connect(function(action, a)
		if action == "Group" then
			local old = group
			group = a
			-- Sin grupo (o en otro): si escribías en el chat del grupo, vuelves al general
			if old and old.Channel and (not a or a.Channel ~= old.Channel) then
				backToGeneral(nil, old.Channel)
			end
			renderGroup(gui)
		elseif action == "GroupInvite" then
			-- (se cierra sola cuando caduca la invitación)
			chooseFor(a.Seconds, "👥 " .. a.Name .. " te invita a su grupo", "En el grupo tenéis un chat para vosotros y veis quién está.", { "Unirme", "Ahora no" }, function(choice)
				Remote:FireServer("Answer", a.UserId, choice == 1)
			end)
		elseif action == "ChatOpen" then
			addPrivate(a.Channel, a.Title or "💬 Chat privado")
			task.spawn(function()
				talkIn(channelNamed(a.Channel, true), a.Title or "Chat privado")
			end)
		elseif action == "ChatIncoming" then
			-- Otro te ha abierto un chat privado: aviso y el chat en el panel para contestar
			addPrivate(a.Channel, a.Title or "💬 Chat privado")
			Hud.toast("Info", ("💬 %s te escribe en privado. Contesta desde «%s» en el panel de la izquierda."):format(tostring(a.From or "Alguien"), tostring(a.Title or "💬 Chat")))
		end
	end)
end

return PlayerMenuUI
