-- PostUI (cliente): el panel del repartidor de Correos.
--   Las direcciones de la ruta en orden (✅ entregado, ➡️ la siguiente), qué tipo de paquete es
--   (buzón o en mano) y el tiempo que llevas de ruta.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Parent.UI.Theme)

local PostUI = {}

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Post") :: RemoteEvent
local create = Theme.create
local C = Theme.Colors

local panel: Frame
local header: TextLabel
local body: TextLabel

local PHASES = {
	Load = "📦 Carga los paquetes en la mesa del escáner de Correos.",
	Deliver = "🛵 Reparte: la línea azul te lleva a la siguiente casa.",
	Return = "🏤 ¡Todo entregado! Vuelve a Correos y cierra la ruta.",
}

local function show(route: { [string]: any })
	panel.Visible = true
	local minutes = route.Elapsed // 60
	header.Text = ("📮 Ruta de reparto · %d:%02d"):format(minutes, route.Elapsed % 60)
	local lines = { PHASES[route.Phase] or "" }
	for i, stop in route.Stops do
		local mark = if stop.Done then "✅" elseif stop.Current then "➡️" else "⬜"
		local text = ("%s %d. %s %s"):format(mark, i, stop.Icon, stop.Address)
		if stop.Current then
			text = "<b>" .. text .. "</b>  <font size=\"11\">(" .. stop.Name .. ")</font>"
		end
		table.insert(lines, text)
	end
	body.Text = table.concat(lines, "\n")
	panel.Size = UDim2.fromOffset(290, 70 + #route.Stops * 20)
end

function PostUI.init()
	local gui = create("ScreenGui", { Name = "PostGui", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })
	Theme.fit(gui)
	panel = Theme.panel({
		Name = "Route",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.55, 0),
		Size = UDim2.fromOffset(290, 170),
		Visible = false,
		Parent = gui,
	})
	Theme.padding(8).Parent = panel
	header = Theme.label({ Size = UDim2.new(1, 0, 0, 22), Text = "📮 Ruta de reparto", Font = Theme.FontBold, TextSize = 16, Parent = panel })
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
		if action == "Route" then
			show(payload)
		elseif action == "Start" then
			panel.Visible = true
		elseif action == "Stop" then
			panel.Visible = false
		end
	end)
	player:GetAttributeChangedSignal("Job"):Connect(function()
		if player:GetAttribute("Job") ~= "Repartidor" then
			panel.Visible = false
		end
	end)
end

return PostUI
