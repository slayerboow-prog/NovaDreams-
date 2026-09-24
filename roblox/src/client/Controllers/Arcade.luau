-- Arcade: los minijuegos de los recreativos y el mostrador de premios.
--   Lanzabolas: 6 bolas. Una barra de fuerza sube y baja; pulsa en la zona dorada (100 puntos).
--   Canastas: 20 segundos. Pulsa cuando el balón pase por la canasta verde; cada acierto la hace más difícil.
-- La puntuación la calcula el servidor (Gameplay.bolasScore) y da los tickets.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)

local create = Theme.create
local C = Theme.Colors

local Arcade = {}

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Arcade") :: RemoteEvent

local rgb = Color3.fromRGB
local ZONES = { -- fuerza desde abajo (0) hasta arriba (1)
	{ 0, 0.6, rgb(90, 90, 110), "10" },
	{ 0.6, 0.74, rgb(60, 130, 230), "30" },
	{ 0.74, 0.86, rgb(60, 190, 100), "50" },
	{ 0.86, 0.94, rgb(255, 200, 40), "100" },
	{ 0.94, 1, rgb(220, 60, 60), "20" },
}

-- Botón grande + barra espaciadora mientras dura el juego
local function bindAction(button: TextButton, action: () -> ())
	button.Activated:Connect(action)
	ContextActionService:BindAction("ArcadeAction", function(_, state)
		if state == Enum.UserInputState.Begin then
			action()
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
end

local function unbind()
	ContextActionService:UnbindAction("ArcadeAction")
end

---------------------------------------------------------------------
-- Lanzabolas
---------------------------------------------------------------------
local function playBolas(token: string, info: { [string]: any })
	local window, content = Dialog.window("ArcadeGame", "🎳 Lanzabolas", Vector2.new(440, 400))
	local track = create("Frame", {
		Size = UDim2.fromOffset(56, 300),
		Position = UDim2.fromOffset(10, 10),
		BackgroundColor3 = C.PanelLight,
		BorderSizePixel = 0,
		Parent = content,
	}, { Theme.corner(8) })
	for _, zone in ZONES do
		local frame = create("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Size = UDim2.fromScale(1, zone[2] - zone[1]),
			Position = UDim2.fromScale(0, 1 - zone[1]),
			BackgroundColor3 = zone[3],
			BorderSizePixel = 0,
			Parent = track,
		})
		Theme.label({ Size = UDim2.fromScale(1, 1), Text = zone[4], TextSize = 13, Font = Theme.FontBold, TextXAlignment = Enum.TextXAlignment.Center, Parent = frame })
	end
	local marker = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(1.4, 0, 0, 6),
		Position = UDim2.fromScale(0.5, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = track,
	})
	local status = Theme.label({ Size = UDim2.new(1, -100, 0, 30), Position = UDim2.fromOffset(92, 10), Font = Theme.FontBold, TextSize = 20, Parent = content })
	local total = Theme.label({ Size = UDim2.new(1, -100, 0, 40), Position = UDim2.fromOffset(92, 44), Font = Theme.FontBold, TextSize = 30, TextColor3 = C.Gold, Parent = content })
	local history = Theme.label({ Size = UDim2.new(1, -100, 0, 80), Position = UDim2.fromOffset(92, 90), TextSize = 16, TextColor3 = C.Muted, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Parent = content })
	local throw = Theme.button({ Size = UDim2.new(1, -100, 0, 60), Position = UDim2.fromOffset(92, 240), Text = "¡LANZAR! (espacio)", TextSize = 20, BackgroundColor3 = rgb(200, 40, 160), Parent = content })

	local powers, scores = {}, {}
	local t, speed, power = 0, 2.4, 0
	local finished = false
	local function redraw()
		status.Text = ("Bola %d de %d"):format(math.min(#powers + 1, info.Balls), info.Balls)
		local sum = 0
		for _, s in scores do
			sum += s
		end
		total.Text = tostring(sum) .. " puntos"
		history.Text = table.concat(scores, "  ·  ")
	end
	redraw()
	local connection = RunService.RenderStepped:Connect(function(dt)
		if finished then
			return
		end
		t += dt
		power = (math.sin(t * speed - math.pi / 2) + 1) / 2
		marker.Position = UDim2.fromScale(0.5, 1 - power)
	end)
	local function finish(send: boolean)
		if finished then
			return
		end
		finished = true
		connection:Disconnect()
		unbind()
		if send then
			Remote:FireServer("Result", token, powers)
		else
			Remote:FireServer("Cancel", token)
		end
	end
	bindAction(throw, function()
		if finished or #powers >= info.Balls then
			return
		end
		table.insert(powers, power)
		table.insert(scores, Gameplay.bolasScore(power))
		speed += 0.35 -- cada bola, un poco más rápido
		redraw()
		if #powers >= info.Balls then
			throw.Text = "¡Fin de la partida!"
			task.delay(1.2, function()
				finish(true)
				if window.Parent then
					window:Destroy()
				end
			end)
		end
	end)
	window.Destroying:Connect(function()
		finish(#powers >= info.Balls)
	end)
end

---------------------------------------------------------------------
-- Canastas
---------------------------------------------------------------------
local function playCanasta(token: string, info: { [string]: any })
	local window, content = Dialog.window("ArcadeGame", "🏀 Canastas", Vector2.new(460, 300))
	local track = create("Frame", {
		Size = UDim2.new(1, -20, 0, 50),
		Position = UDim2.fromOffset(10, 70),
		BackgroundColor3 = C.PanelLight,
		BorderSizePixel = 0,
		Parent = content,
	}, { Theme.corner(8) })
	local zone = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromScale(0.18, 1),
		Position = UDim2.fromScale(0.5, 0),
		BackgroundColor3 = rgb(60, 190, 100),
		BorderSizePixel = 0,
		Parent = track,
	}, { Theme.corner(8) })
	local ball = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(40, 40),
		Position = UDim2.fromScale(0, 0.5),
		Text = "🏀",
		TextSize = 32,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 3,
		Parent = track,
	})
	local status = Theme.label({ Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(10, 10), Font = Theme.FontBold, TextSize = 22, TextColor3 = C.Gold, Parent = content })
	local shoot = Theme.button({ Size = UDim2.new(1, -20, 0, 56), Position = UDim2.fromOffset(10, 140), Text = "¡TIRAR! (espacio)", TextSize = 20, BackgroundColor3 = rgb(230, 110, 40), Parent = content })

	local baskets, left = 0, info.Seconds
	local t, speed, width = 0, 3, 0.18
	local position, lastShot = 0, 0
	local finished = false
	local function redraw()
		status.Text = ("🏀 %d canastas   ·   ⏱ %d s"):format(baskets, math.ceil(math.max(left, 0)))
	end
	local function finish(send: boolean)
		if finished then
			return
		end
		finished = true
		unbind()
		Remote:FireServer(if send then "Result" else "Cancel", token, if send then baskets else nil)
	end
	local connection
	connection = RunService.RenderStepped:Connect(function(dt)
		if finished then
			connection:Disconnect()
			return
		end
		t += dt
		left -= dt
		position = (math.sin(t * speed) + 1) / 2
		ball.Position = UDim2.fromScale(position, 0.5)
		redraw()
		if left <= 0 then
			shoot.Text = "¡Tiempo!"
			finish(true)
			task.delay(1.5, function()
				if window.Parent then
					window:Destroy()
				end
			end)
		end
	end)
	bindAction(shoot, function()
		if finished or os.clock() - lastShot < 0.35 then
			return
		end
		lastShot = os.clock()
		local center = zone.Position.X.Scale
		if math.abs(position - center) <= width / 2 then
			baskets += 1
			speed += 0.15
			width = math.max(0.08, width - 0.006)
			shoot.Text = "¡CANASTA! 🎉"
		else
			shoot.Text = "Fallo…"
		end
		zone.Size = UDim2.fromScale(width, 1)
		zone.Position = UDim2.fromScale(0.15 + math.random() * 0.7, 0)
		redraw()
	end)
	window.Destroying:Connect(function()
		finish(left <= 0)
	end)
end

---------------------------------------------------------------------
-- Premios
---------------------------------------------------------------------
local function has(attribute: string, key: string): boolean
	local list = player:GetAttribute(attribute)
	return typeof(list) == "string" and string.find("," .. list .. ",", "," .. key .. ",", 1, true) ~= nil
end

local function openPrizes()
	local window, content = Dialog.window("Prizes", "🎟 Mostrador de premios", Vector2.new(460, 470))
	local list = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = content })
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	local tickets = Theme.label({ Size = UDim2.new(1, 0, 0, 26), Font = Theme.FontBold, TextSize = 18, TextColor3 = C.Gold, LayoutOrder = 0, Parent = list })
	local keys = {}
	for key in Gameplay.Prizes do
		table.insert(keys, key)
	end
	table.sort(keys, function(a, b)
		return Gameplay.Prizes[a].Order < Gameplay.Prizes[b].Order
	end)
	local rows = {}
	for i, key in keys do
		local prize = Gameplay.Prizes[key]
		local row = Theme.panel({ Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = C.PanelLight, BackgroundTransparency = 0, LayoutOrder = i, Parent = list })
		Theme.padding(10).Parent = row
		Theme.label({ Size = UDim2.new(1, -150, 1, 0), Text = ("%s  %s  ·  %d 🎟"):format(prize.Icon, prize.Name, prize.Tickets), Font = Theme.FontBold, TextSize = 16, Parent = row })
		local button = Theme.button({ AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.fromOffset(140, 38), Position = UDim2.fromScale(1, 0.5), TextSize = 14, Parent = row })
		button.Activated:Connect(function()
			if prize.Kind == "Wear" and has("Prizes", key) then
				Remote:FireServer("Wear", key)
			else
				Remote:FireServer("Redeem", key)
			end
		end)
		rows[key] = button
	end
	local function refresh()
		if not window.Parent then
			return
		end
		tickets.Text = ("Tienes %d tickets"):format(player:GetAttribute("Tickets") or 0)
		for key, button in rows do
			local prize = Gameplay.Prizes[key]
			if prize.Kind == "Wear" and has("Prizes", key) then
				button.Text = if has("Wearing", key) then "Quitarse" else "Ponerse"
				button.BackgroundColor3 = rgb(0, 120, 170)
			elseif prize.Kind == "Vehicle" and has("OwnedVehicles", key) then
				button.Text = "✓ Ya lo tienes"
				button.BackgroundColor3 = C.PanelLight
			else
				button.Text = "Canjear"
				button.BackgroundColor3 = if (player:GetAttribute("Tickets") or 0) >= prize.Tickets then rgb(0, 150, 80) else C.PanelLight
			end
		end
	end
	local connections = {}
	for _, attribute in { "Tickets", "Prizes", "Wearing", "OwnedVehicles" } do
		table.insert(connections, player:GetAttributeChangedSignal(attribute):Connect(refresh))
	end
	window.Destroying:Connect(function()
		for _, connection in connections do
			connection:Disconnect()
		end
	end)
	refresh()
end

function Arcade.init()
	Remote.OnClientEvent:Connect(function(action, token, gameId, info)
		if action == "Play" then
			if gameId == "Bolas" then
				playBolas(token, info)
			elseif gameId == "Canasta" then
				playCanasta(token, info)
			end
		elseif action == "Prizes" then
			openPrizes()
		end
	end)
end

return Arcade
