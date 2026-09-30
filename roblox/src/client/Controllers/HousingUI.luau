-- HousingUI (cliente): el timbre y las llaves de tu vivienda (HousingService).
--   * Timbre: cuando alguien llama a tu puerta sale arriba «🔔 Ana llama a tu puerta (3ºB)» con
--     «Abrir» y «No abrir» (se va solo a los 30 s: la visita oye «No abre nadie»). Si llaman
--     varios, los avisos se apilan (uno por timbre); antes el segundo borraba el del primero.
--   * Llaves (cartel «Llaves y visitas» dentro de tu casa): quién puede entrar (privacidad), los que
--     tienen llave (Quitar), dar llave a los jugadores del servidor (Dar) y las visitas que están
--     dentro (Echar). Se cierra con ✕ o al alejarte.
--   * Encargos de los vecinos: el aviso «Un vecino te pide un favor» con «Aceptar» y «Ahora no», y
--     mientras lo haces, un cartelito a la izquierda con lo que toca («Recoge el paquete…»).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Format = require(ReplicatedStorage.Shared.Format)
local Theme = require(script.Parent.Parent.UI.Theme)
local SoundFx = require(script.Parent.SoundFx)

local HousingUI = {}

local player = Players.LocalPlayer
local create = Theme.create
local C = Theme.Colors

local gui: ScreenGui
local remote: RemoteEvent
local panel: Frame?
-- Avisos del timbre abiertos, en orden de llegada (cada uno con su Token)
local bellCards: { { Token: string, Card: Frame } } = {}
local MAX_BELLS = 4
local errandCard: Frame?
local errandTracker: Frame?

local PRIVACY = {
	{ Id = "Grupo", Label = "👥 Grupo y llaves", Hint = "Entran los que tienen llave y tu grupo (si eres el líder)." },
	{ Id = "Llaves", Label = "🔑 Solo llaves", Hint = "Solo entran los que tienen llave." },
	{ Id = "Cerrada", Label = "🔒 Cerrada", Hint = "No entra nadie más que tú (el timbre sigue sonando)." },
}

local function play(name: string)
	pcall(SoundFx.play, name)
end

---------------------------------------------------------------------
-- Timbre
---------------------------------------------------------------------
-- Coloca los avisos uno debajo de otro
local function stackBells()
	for i, entry in bellCards do
		entry.Card.Position = UDim2.new(0.5, 0, 0, 96 + (i - 1) * 120)
	end
end

local function closeBell(token: string)
	for i, entry in bellCards do
		if entry.Token == token then
			table.remove(bellCards, i)
			entry.Card:Destroy()
			break
		end
	end
	stackBells()
end

local function showBell(data: { [string]: any })
	local token = tostring(data.Token)
	closeBell(token) -- (el mismo timbre otra vez: se cambia)
	-- Como mucho MAX_BELLS a la vez: se quita el más antiguo
	while #bellCards >= MAX_BELLS do
		closeBell(bellCards[1].Token)
	end
	play("MenuAbrir")
	local card = Theme.panel({ Name = "Doorbell", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 96), Size = UDim2.fromOffset(420, 112), Parent = gui })
	table.insert(bellCards, { Token = token, Card = card })
	stackBells()
	Theme.padding(12).Parent = card
	Theme.title({ Size = UDim2.new(1, 0, 0, 26), Text = "🔔 Llaman a tu puerta", TextSize = 19, Parent = card })
	Theme.label({ Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 22), Text = ("%s quiere entrar · %s"):format(tostring(data.From or "Alguien"), tostring(data.Title or "")), TextSize = 15, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card })
	local function answer(open: boolean)
		remote:FireServer("Answer", data.Token, open)
		closeBell(token)
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
	task.delay(tonumber(data.Seconds) or 30, function()
		if card.Parent then
			closeBell(token)
		end
	end)
end

---------------------------------------------------------------------
-- Encargos de los vecinos
---------------------------------------------------------------------
local function closeErrandOffer()
	if errandCard then
		errandCard:Destroy()
		errandCard = nil
	end
end

local function showErrandOffer(data: { [string]: any })
	closeErrandOffer()
	play("MenuAbrir")
	local card = Theme.panel({ Name = "ErrandOffer", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 96), Size = UDim2.fromOffset(440, 168), Parent = gui })
	errandCard = card
	Theme.padding(12).Parent = card
	Theme.title({ Size = UDim2.new(1, 0, 0, 24), Text = "🙋 " .. tostring(data.Title or "Un vecino te pide un favor"), TextSize = 18, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card })
	Theme.label({ Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 58), Text = tostring(data.Text or ""), TextSize = 14, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Parent = card })
	Theme.label({ Position = UDim2.fromOffset(0, 86), Size = UDim2.new(1, 0, 0, 20), Text = ("Recompensa: %s y +%s de experiencia"):format(Format.money(tonumber(data.Money) or 0), tostring(data.Xp or 0)), TextSize = 13, TextColor3 = C.Muted, Parent = card })
	local token = data.Token
	local function answer(accept: boolean)
		remote:FireServer("ErrandAnswer", token, accept)
		closeErrandOffer()
	end
	local yes = Theme.button({ Name = "Accept", Position = UDim2.new(0, 0, 1, -34), Size = UDim2.new(0.5, -4, 0, 34), Text = "👍 Aceptar", TextSize = 16, Parent = card })
	yes.Activated:Connect(function()
		play("MenuOk")
		answer(true)
	end)
	local no = Theme.button({ Name = "Decline", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 1, -34), Size = UDim2.new(0.5, -4, 0, 34), Text = "✋ Ahora no", TextSize = 16, Parent = card })
	no.Activated:Connect(function()
		answer(false)
	end)
	task.delay(30, function()
		if errandCard == card then
			closeErrandOffer()
		end
	end)
end

-- El cartelito del encargo en marcha (Done: se quita)
local function showErrand(data: { [string]: any })
	if errandTracker then
		errandTracker:Destroy()
		errandTracker = nil
	end
	if data.Done then
		return
	end
	local frame = Theme.panel({ Name = "ErrandTracker", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.38, 0), Size = UDim2.fromOffset(300, 70), Parent = gui })
	errandTracker = frame
	Theme.padding(8).Parent = frame
	Theme.title({ Size = UDim2.new(1, 0, 0, 20), Text = "📋 " .. tostring(data.Title or "Encargo"), TextSize = 15, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame })
	Theme.label({ Name = "Goal", Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 1, -22), Text = tostring(data.Goal or ""), TextSize = 13, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Parent = frame })
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
		elseif kind == "DoorbellGone" then
			-- (la visita se ha ido o el timbre ha caducado en el servidor)
			closeBell(tostring(data.Token))
		elseif kind == "Keys" then
			openKeys(data)
		elseif kind == "ErrandOffer" then
			showErrandOffer(data)
		elseif kind == "Errand" then
			showErrand(data)
		end
	end)
end

-- (para las pruebas)
HousingUI.isBellOpen = function(): boolean
	return #bellCards > 0
end
HousingUI.isKeysOpen = function(): boolean
	return panel ~= nil
end
HousingUI.isErrandShown = function(): boolean
	return errandTracker ~= nil
end

return HousingUI
