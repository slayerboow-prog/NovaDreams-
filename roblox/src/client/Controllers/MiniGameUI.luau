-- MiniGameUI (cliente): los minijuegos de las misiones.
--   Timing  barra de precisión: la aguja va y viene; pulsa (clic, toque, Espacio) cuando esté en verde.
--           Sirve para pasar el balón, encestar, chutar un penalti…
--   Futbol  un partido por jugadas: pase (precisión), regate (flecha rápida), tiro (precisión pequeña)
--           y, en defensa, robar el balón o parar el tiro. Cambia según tu posición (delantero,
--           defensa o portero). Marcador arriba y comentarios de cada jugada.
-- El servidor (MiniGameService) dice qué jugar y comprueba el resultado.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Theme = require(script.Parent.Parent.UI.Theme)
local StoryAudio = require(script.Parent.StoryAudio)

local create = Theme.create
local C = Theme.Colors

local MiniGameUI = {}

local player = Players.LocalPlayer
local Remote: RemoteEvent

local GREEN = Color3.fromRGB(70, 200, 110)
local RED = Color3.fromRGB(220, 70, 70)

local gui: ScreenGui
local panel: Frame
local titleLabel: TextLabel
local hintLabel: TextLabel
local scoreLabel: TextLabel
local commentLabel: TextLabel
local bar: Frame
local zone: Frame
local needle: Frame
local dots: Frame
local actionButton: TextButton
local arrows: Frame

local pressed: BindableEvent
local lastPress = 0
local token = 0
local cancelled = false

---------------------------------------------------------------------
-- Interfaz
---------------------------------------------------------------------

local function build()
	gui = create("ScreenGui", {
		Name = "MiniGameUI",
		ResetOnSpawn = false,
		DisplayOrder = 7,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local scale = create("UIScale", { Parent = gui })
	local camera = workspace.CurrentCamera
	local function rescale()
		scale.Scale = math.clamp(camera.ViewportSize.Y / 850, 0.65, 1.25)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()

	panel = Theme.panel({
		Name = "MiniGame",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -90),
		Size = UDim2.fromOffset(480, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = gui,
	})
	Theme.padding(14).Parent = panel
	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = panel,
	})
	scoreLabel = Theme.label({
		Size = UDim2.new(1, 0, 0, 24),
		Font = Theme.FontBold,
		TextSize = 20,
		TextColor3 = C.Gold,
		TextXAlignment = Enum.TextXAlignment.Center,
		Visible = false,
		LayoutOrder = 0,
		Parent = panel,
	})
	titleLabel = Theme.label({
		Size = UDim2.new(1, 0, 0, 24),
		Font = Theme.FontBold,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 1,
		Parent = panel,
	})
	hintLabel = Theme.label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 14,
		TextColor3 = C.Muted,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 2,
		Parent = panel,
	})
	bar = create("Frame", {
		Size = UDim2.fromOffset(420, 30),
		BackgroundColor3 = C.PanelLight,
		BorderSizePixel = 0,
		LayoutOrder = 3,
		Parent = panel,
	}, { Theme.corner(8) })
	zone = create("Frame", {
		Size = UDim2.fromScale(0.25, 1),
		BackgroundColor3 = GREEN,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Parent = bar,
	}, { Theme.corner(6) })
	needle = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(0, 6, 1, 10),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = bar,
	}, { Theme.corner(3) })
	arrows = create("Frame", {
		Size = UDim2.fromOffset(300, 64),
		BackgroundTransparency = 1,
		Visible = false,
		LayoutOrder = 4,
		Parent = panel,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 14),
		Parent = arrows,
	})
	commentLabel = Theme.label({
		Size = UDim2.new(1, 0, 0, 22),
		Font = Theme.FontBold,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 5,
		Parent = panel,
	})
	dots = create("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		LayoutOrder = 6,
		Parent = panel,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 6),
		Parent = dots,
	})
	actionButton = Theme.button({
		Size = UDim2.fromOffset(200, 48),
		Text = "¡YA!",
		TextSize = 22,
		BackgroundColor3 = Color3.fromRGB(40, 140, 220),
		LayoutOrder = 7,
		Parent = panel,
	})
	actionButton.Activated:Connect(function()
		pressed:Fire("Action")
	end)
end

local function press(kind: string)
	-- Un toque cuenta una vez (evita dobles pulsaciones)
	if os.clock() - lastPress > 0.12 then
		lastPress = os.clock()
		pressed:Fire(kind)
	end
end

local function setDots(results: { boolean? }, total: number)
	for _, child in dots:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for i = 1, total do
		local r = results[i]
		create("Frame", {
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = if r == true then GREEN elseif r == false then RED else C.PanelLight,
			BorderSizePixel = 0,
			LayoutOrder = i,
			Parent = dots,
		}, { Theme.corner(7) })
	end
end

local function comment(text: string, color: Color3?)
	commentLabel.Text = text
	commentLabel.TextColor3 = color or C.Text
end

---------------------------------------------------------------------
-- Piezas de juego
---------------------------------------------------------------------

-- Una barra de precisión: devuelve true si se paró dentro de la zona
local function timingRound(zoneSize: number, speed: number, myToken: number): boolean
	bar.Visible = true
	arrows.Visible = false
	actionButton.Visible = true
	local start = math.random() * (1 - zoneSize)
	zone.Size = UDim2.fromScale(zoneSize, 1)
	zone.Position = UDim2.fromScale(start, 0)
	local t = math.random() * 0.2
	local position = 0
	local stopped = false
	local connection = RunService.RenderStepped:Connect(function(dt)
		t += dt * 0.85 * speed
		-- ida y vuelta, un poco más rápido en el centro
		position = 0.5 - 0.5 * math.cos(t * math.pi)
		needle.Position = UDim2.fromScale(position, 0.5)
	end)
	local conn2
	conn2 = pressed.Event:Connect(function(kind)
		if kind == "Action" then
			stopped = true
		end
	end)
	local deadline = os.clock() + 6 / math.max(speed, 0.3)
	while not stopped and os.clock() < deadline and token == myToken and not cancelled do
		task.wait()
	end
	connection:Disconnect()
	conn2:Disconnect()
	local hit = stopped and position >= start and position <= start + zoneSize
	needle.BackgroundColor3 = if hit then GREEN else RED
	task.delay(0.5, function()
		needle.BackgroundColor3 = Color3.new(1, 1, 1)
	end)
	return hit
end

local ARROWS = { { "←", "Left" }, { "↑", "Up" }, { "→", "Right" } }

-- Flecha rápida: aparece una dirección y hay que pulsarla a tiempo (flechas, A/W/D o tocar)
local function quickRound(window: number, myToken: number): boolean
	bar.Visible = false
	actionButton.Visible = false
	arrows.Visible = true
	for _, child in arrows:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	local target = ARROWS[math.random(1, #ARROWS)]
	local answer: string? = nil
	for i, arrow in ARROWS do
		local button = Theme.button({
			Size = UDim2.fromOffset(64, 64),
			Text = arrow[1],
			TextSize = 30,
			BackgroundColor3 = if arrow == target then Color3.fromRGB(240, 180, 40) else C.PanelLight,
			LayoutOrder = i,
			Parent = arrows,
		})
		button.Activated:Connect(function()
			answer = answer or arrow[2]
		end)
	end
	local conn = pressed.Event:Connect(function(kind)
		if kind ~= "Action" then
			answer = answer or kind
		end
	end)
	local deadline = os.clock() + window
	while not answer and os.clock() < deadline and token == myToken and not cancelled do
		task.wait()
	end
	conn:Disconnect()
	arrows.Visible = false
	return answer == target[2]
end

---------------------------------------------------------------------
-- Juegos
---------------------------------------------------------------------

local function countdown(myToken: number)
	for _, text in { "3", "2", "1" } do
		if token ~= myToken or cancelled then
			return
		end
		comment(text, C.Gold)
		task.wait(0.45)
	end
	comment("")
end

local function playTiming(spec: { [string]: any }, myToken: number): { [string]: any }
	local rounds = spec.Rounds or 3
	local need = spec.Need or 1
	local zoneSize = spec.Zone or 0.22
	local hits = 0
	local results = {}
	setDots(results, rounds)
	countdown(myToken)
	for i = 1, rounds do
		if token ~= myToken or cancelled then
			break
		end
		local hit = timingRound(zoneSize, spec.Speed or 1, myToken)
		results[i] = hit
		setDots(results, rounds)
		if hit then
			hits += 1
			zoneSize = math.max(0.08, zoneSize - (spec.Shrink or 0))
			comment(if hits >= need then "¡Perfecto!" else ("¡Bien! %d de %d"):format(hits, need), GREEN)
			StoryAudio.sting("Momento")
		else
			comment("¡Casi!", RED)
		end
		task.wait(0.7)
		if hits >= need then
			break
		end
	end
	return { Hits = hits }
end

-- Jugadas según la posición: A = ataque, D = defensa, P = parada del portero
local PLANS = {
	Delantero = { "A", "D", "A", "A", "D", "A" },
	Defensa = { "D", "A", "D", "A", "D", "A" },
	Portero = { "P", "A", "P", "P", "A", "P" },
}

local function playFutbol(spec: { [string]: any }, myToken: number): { [string]: any }
	local plan = PLANS[spec.Position or "Delantero"] or PLANS.Delantero
	local plays = math.min(spec.Plays or #plan, #plan)
	local goals, against = 0, 0
	local rival = spec.Rival or "el rival"
	scoreLabel.Visible = true
	local function score()
		scoreLabel.Text = ("Tu equipo  %d  -  %d  %s"):format(goals, against, rival)
	end
	score()
	setDots({}, 0)
	countdown(myToken)
	for i = 1, plays do
		if token ~= myToken or cancelled then
			break
		end
		local kind = plan[i]
		if kind == "A" then
			hintLabel.Text = "¡Al ataque! Pase, regate y tiro."
			comment("Pase a tu compañero…")
			local pass = timingRound(0.3, 0.9, myToken)
			comment(if pass then "¡Buen pase!" else "Pase flojo…", if pass then GREEN else RED)
			task.wait(0.4)
			comment("¡Regate! Pulsa la flecha dorada")
			local dribble = quickRound(1.4, myToken)
			comment(if dribble then "¡Te has marchado!" else "Te han cerrado…", if dribble then GREEN else RED)
			task.wait(0.4)
			comment("¡Chuta!")
			local shot = timingRound(if pass and dribble then 0.22 else 0.14, 1.15, myToken)
			if shot and (pass or dribble) then
				goals += 1
				comment("¡¡GOOOOL!!", GREEN)
				StoryAudio.sting("Momento")
			else
				comment(if shot then "¡Al palo! Casi…" else "Fuera…", RED)
			end
		elseif kind == "D" then
			hintLabel.Text = "¡Atacan ellos! Roba el balón."
			comment("¡Roba! Pulsa la flecha dorada")
			local steal = quickRound(1.2, myToken)
			if steal then
				comment("¡Balón recuperado!", GREEN)
			elseif math.random() < 0.6 then
				against += 1
				comment("Gol de " .. rival .. "…", RED)
			else
				comment("¡Uf! Han fallado", C.Gold)
			end
		else
			hintLabel.Text = "¡Tiro a puerta! Lánzate hacia el lado bueno."
			comment("¡Para! ¿Hacia dónde tiran?")
			local save = quickRound(1.1, myToken)
			if save then
				comment("¡PARADÓN!", GREEN)
				StoryAudio.sting("Momento")
			elseif math.random() < 0.75 then
				against += 1
				comment("Gol de " .. rival .. "…", RED)
			else
				comment("¡Al larguero! Qué suerte", C.Gold)
			end
		end
		score()
		task.wait(1)
	end
	comment(if goals > against then "¡Victoria!" elseif goals == against then "Empate" else "Derrota… ¡la próxima!", C.Gold)
	task.wait(1.2)
	scoreLabel.Visible = false
	return { Goals = goals, Against = against }
end

local function run(payload: { [string]: any })
	token = payload.Token
	cancelled = false
	local myToken = token
	local spec = payload.Spec or {}
	player:SetAttribute("InMiniGame", true)
	titleLabel.Text = ("%s  %s"):format(spec.Icon or "🎮", spec.Title or "Minijuego")
	hintLabel.Text = spec.Hint or ""
	comment("")
	panel.Visible = true
	panel.Size = UDim2.fromOffset(480, 0)
	local result
	if spec.Game == "Futbol" then
		result = playFutbol(spec, myToken)
	else
		result = playTiming(spec, myToken)
	end
	if token == myToken and not cancelled then
		Remote:FireServer("Result", myToken, result)
		task.wait(0.6)
	end
	if token == myToken then
		panel.Visible = false
		player:SetAttribute("InMiniGame", nil)
	end
end

function MiniGameUI.init()
	pressed = Instance.new("BindableEvent")
	build()
	Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("MiniGame") :: RemoteEvent
	Remote.OnClientEvent:Connect(function(kind: string, payload: { [string]: any })
		if kind == "Start" then
			task.spawn(run, payload)
		elseif kind == "Cancel" and payload.Token == token then
			cancelled = true
			panel.Visible = false
			player:SetAttribute("InMiniGame", nil)
		end
	end)
	-- Teclado: Espacio/clic = ¡ya!; flechas o A/W/D = direcciones. Solo mientras hay minijuego.
	ContextActionService:BindActionAtPriority("MiniGameInput", function(_, state, input)
		if not panel.Visible or state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		local key = input.KeyCode
		if key == Enum.KeyCode.Space or key == Enum.KeyCode.Return or key == Enum.KeyCode.ButtonA then
			press("Action")
		elseif key == Enum.KeyCode.Left or key == Enum.KeyCode.A then
			press("Left")
		elseif key == Enum.KeyCode.Up or key == Enum.KeyCode.W then
			press("Up")
		elseif key == Enum.KeyCode.Right or key == Enum.KeyCode.D then
			press("Right")
		else
			return Enum.ContextActionResult.Pass
		end
		return Enum.ContextActionResult.Sink
	end, false, 3000, Enum.KeyCode.Space, Enum.KeyCode.Return, Enum.KeyCode.ButtonA, Enum.KeyCode.Left, Enum.KeyCode.Up, Enum.KeyCode.Right, Enum.KeyCode.A, Enum.KeyCode.W, Enum.KeyCode.D)
end

return MiniGameUI
