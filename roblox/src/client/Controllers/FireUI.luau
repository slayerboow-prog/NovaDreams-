-- FireUI (cliente): el panel del bombero/a con el aviso actual.
--   Qué pasa, qué toca hacer (cuántas llamas quedan) y el tiempo. La sirena y sus luces las
--   lleva PoliceUI (tecla K o el botón 🚨, igual que el coche patrulla).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Parent.UI.Theme)

local FireUI = {}

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Fire") :: RemoteEvent
local create = Theme.create
local C = Theme.Colors

local panel: Frame
local body: TextLabel

local function show(incident: { [string]: any }?)
	panel.Visible = true
	if not incident then
		body.Text = "🚒 Todo tranquilo en el parque. Espera el próximo aviso…"
		return
	end
	body.Text = ("%s <b>%s</b>\n%s\n\n➡️ %s\n⏱️ %d:%02d"):format(incident.Icon, incident.Title, incident.Text, incident.Step, incident.Left // 60, incident.Left % 60)
end

function FireUI.init()
	local gui = create("ScreenGui", { Name = "FireGui", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })
	Theme.fit(gui)
	panel = Theme.panel({
		Name = "Incident",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.55, 0),
		Size = UDim2.fromOffset(290, 160),
		Visible = false,
		Parent = gui,
	})
	Theme.padding(8).Parent = panel
	Theme.label({ Size = UDim2.new(1, 0, 0, 22), Text = "🚒 Bomberos · aviso", Font = Theme.FontBold, TextSize = 16, Parent = panel })
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
		if player:GetAttribute("Job") ~= "Bombero" then
			panel.Visible = false
		end
	end)
end

return FireUI
