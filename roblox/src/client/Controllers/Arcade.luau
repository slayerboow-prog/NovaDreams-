-- Arcade: los minijuegos de los recreativos y el mostrador de premios.
--   Lanzabolas: 6 bolas. Una barra de fuerza sube y baja; pulsa en la zona dorada (100 puntos).
--   Canastas: 20 segundos en la máquina de verdad (la jaula de los recreativos), con la física del
--     baloncesto (Sports/ArcadeHoops): mantén «Tirar», suelta con la barra en la franja dorada y el
--     balón vuela al aro (puede tocar aro, dar en el tablero, entrar o salirse). Si no se encuentra
--     la jaula, la versión de la barra: pulsa cuando el balón pase por la canasta verde.
-- La puntuación la calcula el servidor (Gameplay.bolasScore) y da los tickets.

local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local ArcadeHoops = require(ReplicatedStorage.Shared.Sports.ArcadeHoops)
local Court = require(ReplicatedStorage.Shared.Sports.Court)
local SportInput = require(script.Parent.SportInput)
local SoundFx = require(script.Parent.SoundFx)
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
	-- (en el móvil no hay teclas: el texto va sin «(espacio)» ni «(Q)»)
	local throw = Theme.button({ Size = UDim2.new(1, -100, 0, 60), Position = UDim2.fromOffset(92, 240), Text = if Theme.isTouch() then "¡LANZAR!" else "¡LANZAR! (espacio)", TextSize = 20, BackgroundColor3 = rgb(200, 40, 160), Parent = content })

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
	-- (en el móvil no hay teclas: el texto va sin «(espacio)» ni «(Q)»)
	local shoot = Theme.button({ Size = UDim2.new(1, -20, 0, 56), Position = UDim2.fromOffset(10, 140), Text = if Theme.isTouch() then "¡TIRAR!" else "¡TIRAR! (espacio)", TextSize = 20, BackgroundColor3 = rgb(230, 110, 40), Parent = content })

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
-- Canastas de verdad: en la máquina de los recreativos, con la física del baloncesto
-- (Sports/ArcadeHoops). Si no se encuentra la jaula de la máquina, la de la barra (playCanasta).
---------------------------------------------------------------------

-- La máquina de canastas más cercana: el mostrador, el aro, el tablero y el suelo de la jaula
local function findMachine(): { [string]: any }?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return nil
	end
	local console: BasePart? = nil
	local best = 30
	for _, part in CollectionService:GetTagged("ArcadeMachine") do
		if part:IsA("BasePart") and part:GetAttribute("GameId") == "Canasta" then
			local d = (part.Position - root.Position).Magnitude
			if d < best then
				best, console = d, part
			end
		end
	end
	if not console or not console.Parent then
		return nil
	end
	local function nearest(name: string): BasePart?
		local found, dist = nil, 20
		for _, child in (console :: BasePart).Parent:GetChildren() do
			if child.Name == name and child:IsA("BasePart") then
				local d = (child.Position - (console :: BasePart).Position).Magnitude
				if d < dist then
					found, dist = child, d
				end
			end
		end
		return found
	end
	local hoop, board = nearest("Hoop"), nearest("Backboard")
	if not hoop or not board then
		return nil
	end
	local floor = nearest("CageFloor")
	local floorY = if floor then floor.Position.Y + floor.Size.Y / 2 else console.Position.Y - console.Size.Y / 2
	local flat = Vector3.new(hoop.Position.X - console.Position.X, 0, hoop.Position.Z - console.Position.Z)
	if flat.Magnitude < 4 then
		return nil
	end
	local axis = flat.Unit
	local shooter = console.Position + Vector3.new(0, console.Size.Y / 2 + 1.4, 0) - axis * 0.4
	local net = nearest("CageNet")
	local halfWidth = if net then math.max(1.6, math.abs((net.Position - hoop.Position):Dot(Vector3.new(-axis.Z, 0, axis.X))) - 0.3) else 2.4
	local machine = ArcadeHoops.machine(shooter, hoop.Position, Court.rimRadius(hoop), board.Position, board.Size, floorY, halfWidth)
	return { Machine = machine, Console = console, Hoop = hoop, Axis = axis, Shooter = shooter }
end

local function playCanasta3D(token: string, info: { [string]: any }, found: { [string]: any })
	local m = found.Machine
	local court = m.Court
	local camera = workspace.CurrentCamera
	local oldType, oldSubject = camera.CameraType, camera.CameraSubject
	local axis: Vector3 = found.Axis
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(found.Shooter - axis * 5.5 + Vector3.new(0, 2.4, 0), found.Hoop.Position - Vector3.new(0, 0.6, 0))

	-- Los balones (solo en tu pantalla)
	local folder = Instance.new("Folder")
	folder.Name = "ArcadeBalls"
	folder.Parent = camera
	local function newBall(): BasePart
		local ball = Instance.new("Part")
		ball.Name = "ArcadeBall"
		ball.Shape = Enum.PartType.Ball
		ball.Size = Vector3.new(1.2, 1.2, 1.2)
		ball.Color = rgb(230, 110, 40)
		ball.Material = Enum.Material.SmoothPlastic
		ball.Anchored = true
		ball.CanCollide = false
		ball.CanQuery = false
		ball.CanTouch = false
		ball.Parent = folder
		return ball
	end
	local inHand = newBall()
	inHand.CFrame = CFrame.new(found.Shooter)

	-- El panel de abajo: tiempo, canastas, la barra de fuerza y los botones
	local gui = create("ScreenGui", { Name = "ArcadeHoopsGui", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })
	Theme.fit(gui)
	local panel = Theme.panel({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.fromOffset(440, 150), Parent = gui })
	Theme.padding(10).Parent = panel
	local status = Theme.label({ Size = UDim2.new(1, 0, 0, 26), Font = Theme.FontBold, TextSize = 22, TextColor3 = C.Gold, Parent = panel })
	local meter = create("Frame", { Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = rgb(10, 16, 30), BorderSizePixel = 0, Parent = panel }, { Theme.corner(6) })
	local fill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = rgb(230, 110, 40), BorderSizePixel = 0, Parent = meter }, { Theme.corner(6) })
	local W = ArcadeHoops.Window
	create("Frame", { Position = UDim2.fromScale(ArcadeHoops.Sweet - W, 0), Size = UDim2.fromScale(W * 2, 1), BackgroundColor3 = rgb(255, 210, 50), BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 2, Parent = meter })
	local needle = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(0, 5, 1, 8), BackgroundColor3 = rgb(255, 255, 255), BorderSizePixel = 0, ZIndex = 3, Parent = meter }, { Theme.corner(2) })
	local shoot = Theme.button({ Position = UDim2.fromOffset(0, 64), Size = UDim2.new(0.72, 0, 0, 56), Text = if Theme.isTouch() then "🏀 Tirar (mantén)" else "🏀 Tirar (mantén Espacio)", TextSize = 19, BackgroundColor3 = rgb(230, 110, 40), Parent = panel })
	local leave = Theme.button({ Position = UDim2.new(0.74, 0, 0, 64), Size = UDim2.new(0.26, 0, 0, 56), Text = if Theme.isTouch() then "Salir" else "Salir (Q)", TextSize = 15, BackgroundColor3 = rgb(50, 52, 60), Parent = panel })

	local rng = Random.new()
	local baskets, streak, left = 0, 0, info.Seconds
	local holdStart: number? = nil
	local nextBall = 0
	local flying: { { State: any, Part: BasePart, Age: number, Scored: boolean } } = {}
	local finished = false
	local connection: RBXScriptConnection? = nil

	local function redraw()
		status.Text = ("🏀 %d canastas   ·   ⏱ %d s%s"):format(baskets, math.ceil(math.max(left, 0)), if streak >= 3 then ("   ·   🔥 racha de %d"):format(streak) else "")
	end
	local function cleanup()
		ContextActionService:UnbindAction("ArcadeShoot")
		ContextActionService:UnbindAction("ArcadeLeave")
		if connection then
			connection:Disconnect()
		end
		folder:Destroy()
		gui:Destroy()
		camera.CameraType = oldType
		camera.CameraSubject = oldSubject
	end
	local function finish(send: boolean)
		if finished then
			return
		end
		finished = true
		holdStart = nil
		Remote:FireServer(if send then "Result" else "Cancel", token, if send then baskets else nil)
		if send then
			shoot.Text = ("¡Tiempo! %d canastas"):format(baskets)
			task.delay(1.6, cleanup)
		else
			cleanup()
		end
	end
	local function press()
		if finished or holdStart or os.clock() < nextBall or #flying >= ArcadeHoops.MaxInAir then
			return
		end
		holdStart = os.clock()
	end
	local function release()
		if finished or not holdStart then
			return
		end
		local power = ArcadeHoops.meter(os.clock() - (holdStart :: number), streak)
		holdStart = nil
		nextBall = os.clock() + ArcadeHoops.Reload
		local state = ArcadeHoops.shoot(m, power, rng)
		local part = newBall()
		part.CFrame = CFrame.new(Court.toWorld(court, state.P))
		table.insert(flying, { State = state, Part = part, Age = 0, Scored = false })
		inHand.Transparency = 1
		pcall(SoundFx.play, "Clic", 0.5, 0.8)
	end

	shoot.MouseButton1Down:Connect(press)
	shoot.MouseButton1Up:Connect(release)
	shoot.MouseLeave:Connect(release)
	leave.Activated:Connect(function()
		finish(false)
	end)
	ContextActionService:BindActionAtPriority("ArcadeShoot", function(_, state, input)
		if input and SportInput.onButton(input) then
			return Enum.ContextActionResult.Pass -- (el clic es para un botón de la interfaz)
		end
		if state == Enum.UserInputState.Begin then
			press()
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			release()
		end
		return Enum.ContextActionResult.Sink
	end, false, 3000, Enum.KeyCode.Space, Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonR2, Enum.UserInputType.MouseButton1)
	ContextActionService:BindActionAtPriority("ArcadeLeave", function(_, state)
		if state == Enum.UserInputState.Begin then
			finish(false)
		end
		return Enum.ContextActionResult.Sink
	end, false, 3000, Enum.KeyCode.Q, Enum.KeyCode.ButtonB)

	redraw()
	connection = RunService.RenderStepped:Connect(function(dt)
		dt = math.min(dt, 0.1)
		-- Si te vas de la máquina (o mueres), la partida se anula
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not finished and (not root or (root.Position - found.Console.Position).Magnitude > 14) then
			finish(false)
			return
		end
		if not finished then
			left -= dt
			if left <= 0 then
				finish(true)
			end
		end
		-- La barra de fuerza
		local power = if holdStart then ArcadeHoops.meter(os.clock() - holdStart, streak) else 0
		fill.Size = UDim2.fromScale(power, 1)
		needle.Position = UDim2.fromScale(power, 0.5)
		local gold = math.abs(power - ArcadeHoops.Sweet) <= W
		needle.BackgroundColor3 = if gold then rgb(255, 230, 90) else rgb(255, 255, 255)
		-- El balón en la mano: aparece cuando ya puedes tirar otro
		inHand.Transparency = if not finished and os.clock() >= nextBall and #flying < ArcadeHoops.MaxInAir then 0 else 1
		inHand.CFrame = CFrame.new(found.Shooter + Vector3.new(0, if holdStart then -0.4 * power else 0, 0))
		-- Los balones en el aire, con la física de verdad
		for i = #flying, 1, -1 do
			local b = flying[i]
			b.Age += dt
			local scored, events = ArcadeHoops.step(m, b.State, dt)
			for _, e in events do
				if e.Kind == "Rim" and (e.Speed or 0) > 6 then
					pcall(SoundFx.play, "Clic", 0.4, 0.6)
				end
			end
			if scored and not finished then
				b.Scored = true
				baskets += 1
				streak += 1
				pcall(SoundFx.play, "Aviso", 0.6, 1.6 + math.min(streak, 8) * 0.05)
				redraw()
			end
			b.Part.CFrame = CFrame.new(Court.toWorld(court, b.State.P))
			if b.Age > ArcadeHoops.Life then
				if not b.Scored then
					streak = 0
				end
				b.Part:Destroy()
				table.remove(flying, i)
			end
		end
		if not finished then
			redraw()
		end
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
				button.Text = "✔ Ya lo tienes"
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
				local ok, found = pcall(findMachine)
				if ok and found then
					playCanasta3D(token, info, found)
				else
					playCanasta(token, info)
				end
			end
		elseif action == "Prizes" then
			openPrizes()
		end
	end)
end

return Arcade
