-- PlayerMenuUI (cliente): menú al tocar a otro jugador, panel del grupo y ventanas de chat.
--   * Toca (o haz clic) en otro jugador, o acércate y pulsa T: sale su menú con
--     "👥 Invitar al grupo", "💬 Chat" y "🤝 Comerciar".
--   * Si estás en un grupo, a la izquierda ves quién está, el chat del grupo y "Salir".
--   * El chat usa los canales de TextChatService que crea SocialService (Roblox filtra los mensajes).

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

local function nameOf(other: Player): string
	return other.DisplayName or other.Name
end

local function escape(text: string): string
	return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function busy(): boolean
	return not ProximityPromptService.Enabled or player:GetAttribute("InDialogue") == true
end

---------------------------------------------------------------------
-- Chat (privado y de grupo)
---------------------------------------------------------------------
local history: { [string]: { string } } = {}
local chatWindow: Frame? = nil
local chatChannel: string? = nil
local chatList: ScrollingFrame? = nil

local function channelNamed(name: string, wait: boolean?): TextChannel?
	local folder = if wait then TextChatService:WaitForChild(Social.Folder, 5) else TextChatService:FindFirstChild(Social.Folder)
	if not folder then
		return nil
	end
	return (if wait then folder:WaitForChild(name, 5) else folder:FindFirstChild(name)) :: TextChannel?
end

local function renderChat()
	local list = chatList
	if not list or not chatChannel then
		return
	end
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local lines = history[chatChannel] or {}
	if #lines == 0 then
		Theme.label({ Size = UDim2.new(1, 0, 0, 24), Text = "Escribe algo para empezar a hablar.", TextSize = 13, TextColor3 = C.Muted, Parent = list })
	end
	for i, line in lines do
		Theme.label({
			Size = UDim2.new(1, -6, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = line,
			RichText = true,
			TextSize = 14,
			TextWrapped = true,
			LayoutOrder = i,
			Parent = list,
		})
	end
	task.defer(function()
		list.CanvasPosition = Vector2.new(0, math.max(0, list.AbsoluteCanvasSize.Y - list.AbsoluteSize.Y))
	end)
end

local function openChat(name: string, title: string)
	local window, content = Dialog.window("Chat", title, Vector2.new(400, 360))
	chatWindow, chatChannel = window, name
	window.Destroying:Connect(function()
		if chatWindow == window then
			chatWindow, chatChannel, chatList = nil, nil, nil
		end
	end)
	local list = create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -50),
		BackgroundColor3 = rgb(8, 14, 28),
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = content,
	})
	create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	Theme.padding(6).Parent = list
	chatList = list
	local box = create("TextBox", {
		Position = UDim2.new(0, 0, 1, -42),
		Size = UDim2.new(1, -96, 0, 40),
		BackgroundColor3 = rgb(8, 14, 28),
		TextColor3 = C.Text,
		PlaceholderText = "Escribe un mensaje…",
		Text = "",
		Font = Theme.Font,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Parent = content,
	}, { Theme.corner(8), Theme.padding(8) })
	local send = Theme.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 1, -42), Size = UDim2.fromOffset(88, 40), Text = "Enviar", TextSize = 15, BackgroundColor3 = C.Accent, Parent = content })
	local function submit()
		local text = box.Text
		if text:match("^%s*$") then
			return
		end
		box.Text = ""
		task.spawn(function()
			local channel = channelNamed(name, true)
			if not channel then
				Hud.toast("Error", "El chat ya no está disponible.")
				return
			end
			local ok = pcall(function()
				channel:SendAsync(text)
			end)
			if not ok then
				Hud.toast("Error", "No se ha podido enviar el mensaje.")
			end
		end)
	end
	send.Activated:Connect(submit)
	box.FocusLost:Connect(function(enter)
		if enter then
			submit()
		end
	end)
	renderChat()
end

local function onMessage(message: TextChatMessage)
	local channel = message.TextChannel
	if not channel or not channel.Parent or channel.Parent.Name ~= Social.Folder then
		return
	end
	if message.Status ~= Enum.TextChatMessageStatus.Success then
		return
	end
	local source = message.TextSource
	local from = source and Players:GetPlayerByUserId(source.UserId)
	local who = if from then escape(nameOf(from)) else "?"
	local mine = from == player
	local color = if mine then "#9fd4ff" else "#ffd166"
	local lines = history[channel.Name] or {}
	history[channel.Name] = lines
	table.insert(lines, ('<font color="%s"><b>%s</b></font>: %s'):format(color, who, message.Text))
	while #lines > Social.History do
		table.remove(lines, 1)
	end
	if chatChannel == channel.Name then
		renderChat()
	elseif not mine then
		local isGroup = channel.Name:sub(1, #Social.GroupPrefix) == Social.GroupPrefix
		if not chatWindow and not busy() then
			-- Nadie lo tenía abierto: se abre solo (como un mensaje de móvil)
			openChat(channel.Name, if isGroup then "💬 Chat del grupo" else "💬 " .. (if from then nameOf(from) else "Chat"))
		else
			Hud.toast("Info", ("💬 %s: %s"):format(if from then nameOf(from) else "?", message.Text))
		end
	end
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
	if not g then
		return
	end
	local rows = #g.Members
	local panel = Theme.panel({
		Name = "Group",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(190, 70 + rows * 24),
		BackgroundTransparency = 0.15,
		Parent = gui,
	})
	groupPanel = panel
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
	local y = 8 + (rows + 1) * 24
	local chat = Theme.button({ Position = UDim2.fromOffset(8, y), Size = UDim2.new(0.5, -12, 0, 30), Text = "💬 Chat", TextSize = 13, BackgroundColor3 = C.Accent, Parent = panel })
	chat.Activated:Connect(function()
		openChat(g.Channel, "💬 Chat del grupo")
	end)
	local leave = Theme.button({ Position = UDim2.new(0.5, 4, 0, y), Size = UDim2.new(0.5, -12, 0, 30), Text = "🚪 Salir", TextSize = 13, Parent = panel })
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
	local window, content = Dialog.window("PlayerMenu", "👤 " .. nameOf(other), Vector2.new(320, 250))
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
	}
	for i, option in options do
		local button = Theme.button({ Size = UDim2.new(1, 0, 0, 48), Text = option[1], TextSize = 17, LayoutOrder = i, Parent = list })
		button.Activated:Connect(function()
			window:Destroy()
			option[2]()
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

function PlayerMenuUI.init()
	local gui = create("ScreenGui", {
		Name = "Social",
		ResetOnSpawn = false,
		DisplayOrder = 3,
		IgnoreGuiInset = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	Theme.fit(gui)

	for _, other in Players:GetPlayers() do
		watchPlayer(other)
	end
	Players.PlayerAdded:Connect(watchPlayer)

	UserInputService.InputBegan:Connect(onPress)
	UserInputService.InputEnded:Connect(onRelease)

	TextChatService.MessageReceived:Connect(onMessage)

	Remote.OnClientEvent:Connect(function(action, a)
		if action == "Group" then
			group = a
			renderGroup(gui)
		elseif action == "GroupInvite" then
			task.spawn(function()
				local choice = Dialog.choose("👥 " .. a.Name .. " te invita a su grupo", "En el grupo tenéis un chat para vosotros y veis quién está.", { "Unirme", "Ahora no" })
				Remote:FireServer("Answer", a.UserId, choice == 1)
			end)
		elseif action == "ChatOpen" then
			task.spawn(function()
				channelNamed(a.Channel, true) -- espera a que llegue el canal
				openChat(a.Channel, a.Title)
			end)
		end
	end)
end

return PlayerMenuUI
