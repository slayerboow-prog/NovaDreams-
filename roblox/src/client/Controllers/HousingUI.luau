-- HousingUI (cliente): el timbre y las llaves de tu vivienda (HousingService).
--   * Timbre: cuando alguien llama a tu puerta sale arriba «🔔 Ana llama a tu puerta (3ºB)» con
--     «Abrir» y «No abrir» (se va solo a los 30 s: la visita oye «No abre nadie»).
--   * Llaves (cartel «Llaves y visitas» dentro de tu casa): quién puede entrar (privacidad), los que
--     tienen llave (Quitar), dar llave a los jugadores del servidor (Dar) y las visitas que están
--     dentro (Echar). Se cierra con ✕ o al alejarte.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.UI.Theme)
local SoundFx = require(script.Parent.SoundFx)

local HousingUI = {}

local player = Players.LocalPlayer
local create = Theme.create
local C = Theme.Colors

local gui: ScreenGui
local remote: RemoteEvent
local panel: Frame?
local bellCard: Frame?

local PRIVACY = {
	{ Id = "Grupo", Label = "👥 Grupo y llaves", Hint = "Entran los de tu grupo y los que tienen llave." },
	{ Id = "Llaves", Label = "🔑 Solo llaves", Hint = "Solo entran los que tienen llave." },
	{ Id = "Cerrada", Label = "🔒 Cerrada", Hint = "No entra nadie más que tú (el timbre sigue sonando)." },
}

local function play(name: string)
	pcall(SoundFx.play, name)
end

---------------------------------------------------------------------
-- Timbre
---------------------------------------------------------------------
local function closeBell()
	if bellCard then
		bellCard:Destroy()
		bellCard = nil
	end
end

local function showBell(data: { [string]: any })
	closeBell()
	play("MenuAbrir")
	local card = Theme.panel({ Name = "Doorbell", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 96), Size = UDim2.fromOffset(420, 112), Parent = gui })
	bellCard = card
	Theme.padding(12).Parent = card
	Theme.title({ Size = UDim2.new(1, 0, 0, 26), Text = "🔔 Llaman a tu puerta", TextSize = 19, Parent = card })
	Theme.label({ Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 22), Text = ("%s quiere entrar · %s"):format(tostring(data.From or "Alguien"), tostring(data.Title or "")), TextSize = 15, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card })
	local token = data.Token
	local function answer(open: boolean)
		remote:FireServer("Answer", token, open)
		closeBell()
	end
	local yes = Theme.button({ Name = "Open", Position = UDim2.new(0, 0, 1, -34), Size = UDim2.new(0.5, -4, 0, 34), Text = "🚪 Abrir", TextSize = 16, Parent = card })
	yes.Activated:Connect(function()
		play("MenuOk")
		answer(true)
	end)
	local no = Theme.button({ Name = "Deny", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 1, -34), Size = UDim2.new(0.5, -4, 0, 34), Text = "✋ No abrir", TextSize = 16, Parent = card })
	no.Activated:Connect(function()
		answer(false)
	end)
	task.delay(30, function()
		if bellCard == card then
			closeBell()
		end
	end)
end

---------------------------------------------------------------------
-- Llaves y visitas
---------------------------------------------------------------------
local function close()
	if panel then
		panel:Destroy()
		panel = nil
	end
end

local function row(parent: Instance, order: number, text: string, buttonText: string?, onClick: (() -> ())?)
	local line = create("Frame", { Size = UDim2.new(1, -8, 0, 34), BackgroundTransparency = 1, LayoutOrder = order, Parent = parent })
	Theme.label({ Size = UDim2.new(1, if buttonText then -96 else 0, 1, 0), Text = text, TextSize = 15, TextTruncate = Enum.TextTruncate.AtEnd, Parent = line })
	if buttonText and onClick then
		local button = Theme.button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(90, 28), Text = buttonText, TextSize = 14, Parent = line })
		button.Activated:Connect(function()
			play("MenuOk")
			onClick()
		end)
	end
	return line
end

local function openKeys(data: { [string]: any })
	local keep = panel ~= nil
	close()
	if not keep then
		play("MenuAbrir")
	end
	local unit = { Key = data.Key, Floor = data.Floor, Letter = data.Letter }
	local frame = Theme.panel({ Name = "HouseKeys", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(440, 470), Parent = gui })
	panel = frame
	Theme.padding(14).Parent = frame
	if not keep then
		local scale = create("UIScale", { Scale = 0.85, Parent = frame })
		TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
	Theme.title({ Size = UDim2.new(1, -40, 0, 26), Text = "🔑 Llaves · " .. tostring(data.Title or ""), TextSize = 18, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame })
	Theme.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(34, 30), Text = "✖", TextSize = 18, Parent = frame }).Activated:Connect(close)
	local list = create("ScrollingFrame", { Name = "List", Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 1, -34), AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 6, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = frame })
	create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	local order = 0
	local function header(text: string)
		order += 1
		Theme.label({ Size = UDim2.new(1, 0, 0, 22), Text = text, TextSize = 13, TextColor3 = C.Muted, LayoutOrder = order, Parent = list })
	end
	if data.Id then
		header("VIVIENDA " .. tostring(data.Id))
	end
	header("¿QUIÉN PUEDE ENTRAR?")
	for _, mode in PRIVACY do
		order += 1
		local chosen = data.Privacy == mode.Id
		row(list, order, (if chosen then "● " else "○ ") .. mode.Label, if chosen then nil else "Elegir", function()
			remote:FireServer("Privacy", unit, mode.Id)
		end)
		if chosen then
			order += 1
			Theme.label({ Size = UDim2.new(1, 0, 0, 20), Text = mode.Hint, TextSize = 13, TextColor3 = C.Muted, TextWrapped = true, LayoutOrder = order, Parent = list })
		end
	end
	header("CON LLAVE")
	if #(data.Keys or {}) == 0 then
		order += 1
		Theme.label({ Size = UDim2.new(1, 0, 0, 22), Text = "Nadie más tiene llave.", TextSize = 14, LayoutOrder = order, Parent = list })
	end
	for _, k in data.Keys or {} do
		order += 1
		row(list, order, "🔑 " .. tostring(k.Name), "Quitar", function()
			remote:FireServer("TakeKey", unit, k.UserId)
		end)
	end
	header("VISITAS DENTRO")
	if #(data.Visitors or {}) == 0 then
		order += 1
		Theme.label({ Size = UDim2.new(1, 0, 0, 22), Text = "No hay nadie de visita.", TextSize = 14, LayoutOrder = order, Parent = list })
	end
	for _, v in data.Visitors or {} do
		order += 1
		row(list, order, "🙂 " .. tostring(v.Name), "Echar", function()
			remote:FireServer("Kick", unit, v.UserId)
		end)
	end
	header("DAR UNA LLAVE A…")
	local holders = {}
	for _, k in data.Keys or {} do
		holders[k.UserId] = true
	end
	local any = false
	for _, p in data.Players or {} do
		if not holders[p.UserId] then
			any = true
			order += 1
			row(list, order, "👤 " .. tostring(p.Name), "Dar", function()
				remote:FireServer("GiveKey", unit, p.UserId)
			end)
		end
	end
	if not any then
		order += 1
		Theme.label({ Size = UDim2.new(1, 0, 0, 22), Text = "No hay más jugadores en el servidor.", TextSize = 14, LayoutOrder = order, Parent = list })
	end
	-- Se cierra solo si te alejas
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local origin = root and root.Position
	task.spawn(function()
		while panel == frame do
			task.wait(0.5)
			local now = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not now or not origin or (now.Position - origin).Magnitude > 30 then
				close()
			end
		end
	end)
end

function HousingUI.init()
	gui = create("ScreenGui", { Name = "HousingGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 8, Parent = player:WaitForChild("PlayerGui") })
	local scale = create("UIScale", { Parent = gui })
	local camera = workspace.CurrentCamera
	local function rescale()
		scale.Scale = math.clamp(math.min(camera.ViewportSize.Y / 900, camera.ViewportSize.X / 1700), 0.6, 1.2)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()
	remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Housing") :: RemoteEvent
	remote.OnClientEvent:Connect(function(kind: string, data: any)
		if type(data) ~= "table" then
			return
		end
		if kind == "Doorbell" then
			showBell(data)
		elseif kind == "Keys" then
			openKeys(data)
		end
	end)
end

-- (para las pruebas)
HousingUI.isBellOpen = function(): boolean
	return bellCard ~= nil
end
HousingUI.isKeysOpen = function(): boolean
	return panel ~= nil
end

return HousingUI
