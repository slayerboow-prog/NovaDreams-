-- GarbageUI (cliente): el panel del basurero.
--   Cuántas papeleras llenas quedan en tu ruta, cuántas bolsas llevas y el tiempo de ruta.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Parent.UI.Theme)

local GarbageUI = {}

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Garbage") :: RemoteEvent
local create = Theme.create
local C = Theme.Colors

local panel: Frame
local header: TextLabel
local body: TextLabel

local function show(route: { [string]: any })
	panel.Visible = true
	header.Text = ("♻ Limpieza · %d:%02d"):format(route.Elapsed // 60, route.Elapsed % 60)
	local done = route.Total - route.Left
	local bar = string.rep("🟩", done) .. string.rep("⬜", route.Left)
	local lines = {
		("🗑️ Papeleras: <b>%d / %d</b>"):format(done, route.Total),
		bar,
		("🛍️ Bolsas que llevas: <b>%d</b>"):format(route.Bags),
		if route.Phase == "Unload"
			then "✅ ¡Ruta limpia! Descarga en los contenedores del Punto Limpio."
			else "Sigue la línea azul a la papelera llena más cercana. Las bolsas sueltas de la calle también cuentan.",
	}
	body.Text = table.concat(lines, "\n")
end

function GarbageUI.init()
	local gui = create("ScreenGui", { Name = "GarbageGui", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })
	panel = Theme.panel({
		Name = "Route",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.55, 0),
		Size = UDim2.fromOffset(280, 150),
		Visible = false,
		Parent = gui,
	})
	Theme.padding(8).Parent = panel
	header = Theme.label({ Size = UDim2.new(1, 0, 0, 22), Text = "♻ Limpieza", Font = Theme.FontBold, TextSize = 16, Parent = panel })
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
		if player:GetAttribute("Job") ~= "Basurero" then
			panel.Visible = false
		end
	end)
end

return GarbageUI
