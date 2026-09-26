-- PoliceUI (cliente): el panel del policía y las sirenas (también las del camión de bomberos).
--   * Panel con el aviso actual: qué ha pasado, qué toca hacer y el tiempo que queda.
--   * Tecla K (o el botón 🚨 en móvil): enciende o apaga la sirena del coche patrulla.
--   * Las luces azules y rojas de los coches patrulla con la sirena encendida parpadean
--     (lo ve todo el mundo: cada cliente las anima por su cuenta).

local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.UI.Theme)

local PoliceUI = {}

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Police") :: RemoteEvent
local create = Theme.create
local C = Theme.Colors

local panel: Frame
local body: TextLabel
local sirenButton: TextButton?

local function show(incident: { [string]: any }?)
	panel.Visible = true
	if not incident then
		body.Text = "📻 Todo tranquilo. Espera el próximo aviso…"
		return
	end
	body.Text = ("%s <b>%s</b>\n%s\n\n➡️ %s\n⏱️ %d:%02d"):format(incident.Icon, incident.Title, incident.Text, incident.Step, incident.Left // 60, incident.Left % 60)
end

---------------------------------------------------------------------
-- Luces de sirena
---------------------------------------------------------------------
type Lamp = { Part: BasePart, On: Color3, Off: Color3, Blue: boolean }
local cars: { [Model]: { Lamp } } = {}

local function track(model: Instance)
	if not model:IsA("Model") or cars[model] then
		return
	end
	local lamps = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and (d.Name == "SirenBlue" or d.Name == "SirenRed") then
			table.insert(lamps, { Part = d, On = d:GetAttribute("On") or d.Color, Off = d.Color, Blue = d.Name == "SirenBlue" })
		end
	end
	cars[model] = lamps
end

local function animate()
	local t = os.clock()
	local phase = math.floor(t * 6) % 2 == 0
	for model, lamps in cars do
		if not model.Parent then
			cars[model] = nil
			continue
		end
		local on = model:GetAttribute("Siren") == true
		for _, lamp in lamps do
			local lit = on and (lamp.Blue == phase)
			lamp.Part.Color = if lit then lamp.On else lamp.Off
			lamp.Part.Material = if lit then Enum.Material.Neon else Enum.Material.SmoothPlastic
		end
	end
end

local FireRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Fire") :: RemoteEvent

local function siren()
	local job = player:GetAttribute("Job")
	if job == "Policia" then
		Remote:FireServer("Siren")
	elseif job == "Bombero" then
		FireRemote:FireServer("Siren")
	end
end

function PoliceUI.init()
	local gui = create("ScreenGui", { Name = "PoliceGui", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })
	Theme.fit(gui)
	panel = Theme.panel({
		Name = "Incident",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.55, 0),
		Size = UDim2.fromOffset(290, 150),
		Visible = false,
		Parent = gui,
	})
	Theme.padding(8).Parent = panel
	Theme.label({ Size = UDim2.new(1, 0, 0, 22), Text = "🚔 Policía · aviso", Font = Theme.FontBold, TextSize = 16, Parent = panel })
	body = Theme.label({
		Position = UDim2.fromOffset(0, 26),
		Size = UDim2.new(1, 0, 1, -26),
		Text = "",
		RichText = true,
		TextSize = 13,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = C.Text,
		Parent = panel,
	})
	if UserInputService.TouchEnabled then
		sirenButton = Theme.button({
			Name = "SirenButton",
			AnchorPoint = Vector2.new(1, 1),
			Size = UDim2.fromOffset(56, 56),
			Position = UDim2.new(1, -316, 1, -28),
			Text = "🚨",
			TextSize = 26,
			BackgroundTransparency = 0.3,
			Visible = false,
			Parent = gui,
		})
		local corner = (sirenButton :: TextButton):FindFirstChildOfClass("UICorner")
		if corner then
			corner.CornerRadius = UDim.new(0.5, 0)
		end
		(sirenButton :: TextButton).Activated:Connect(siren)
	end
	ContextActionService:BindAction("PoliceSiren", function(_, state)
		if state == Enum.UserInputState.Begin and not UserInputService:GetFocusedTextBox() then
			siren()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.K)

	Remote.OnClientEvent:Connect(function(action, payload)
		if action == "Incident" then
			show(payload)
		elseif action == "Start" then
			panel.Visible = true
		elseif action == "Stop" then
			panel.Visible = false
		end
	end)
	player:GetAttributeChangedSignal("Job"):Connect(function()
		local job = player:GetAttribute("Job")
		if job ~= "Policia" then
			panel.Visible = false
		end
		if sirenButton then
			sirenButton.Visible = job == "Policia" or job == "Bombero"
		end
	end)

	for _, tag in { "PoliceCar", "SirenCar" } do
		for _, model in CollectionService:GetTagged(tag) do
			track(model)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(track)
	end
	RunService.Heartbeat:Connect(animate)
end

return PoliceUI
