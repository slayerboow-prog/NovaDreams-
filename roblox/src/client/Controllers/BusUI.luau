-- BusUI (cliente): cartel para los pasajeros del autobús urbano.
-- Sentado en un asiento del autobús se ve la línea, la próxima parada y cómo bajarse.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Theme = require(script.Parent.Parent.UI.Theme)

local BusUI = {}

local player = Players.LocalPlayer

function BusUI.init()
	local gui = Theme.create("ScreenGui", { Name = "BusGui", ResetOnSpawn = false, Enabled = false, Parent = player:WaitForChild("PlayerGui") })
	Theme.fit(gui)
	local label = Theme.label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -100),
		Size = UDim2.fromOffset(460, 44),
		BackgroundTransparency = 0.15,
		BackgroundColor3 = Theme.Colors.Panel,
		Font = Theme.FontBold,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = gui,
	})
	Theme.corner(10).Parent = label
	-- 5 veces por segundo basta (antes iba cada frame)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.2 then
			return
		end
		elapsed = 0
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local seat = humanoid and humanoid.SeatPart
		local bus = seat and seat.Name == "PassengerSeat" and seat.Parent
		if not bus or not bus:GetAttribute("BusLine") then
			gui.Enabled = false
			return
		end
		gui.Enabled = true
		local current = bus:GetAttribute("CurrentStop")
		if current and bus:GetAttribute("DoorsOpen") then
			Theme.setText(label, ("🚌 %s · Parada: %s · salta (Espacio) para bajarte"):format(bus:GetAttribute("BusLine"), current))
		else
			Theme.setText(label, ("🚌 %s · Próxima parada: %s"):format(bus:GetAttribute("BusLine"), tostring(bus:GetAttribute("NextStop") or "…")))
		end
	end)
end

return BusUI
