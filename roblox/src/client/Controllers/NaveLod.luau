-- NaveLod: las naves de MALLA (el «HX-7 Halcón», shared/AirCombat/ShipModel) de los demás se ven con
-- la versión lejana (NaveLOD, ≈ 3 mil triángulos) cuando están lejos, y antes en el móvil (nivel gráfico
-- Low). La tuya, siempre la buena. Cambios locales (no se replican). Cada medio segundo.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NaveLod = {}

local started = false

local function step(ShipModel: any)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local player = Players.LocalPlayer
	local tier = player:GetAttribute("GraphicsTier")
	local mine = "Nave_" .. tostring(player.UserId)
	local character = player.Character
	for _, model in CollectionService:GetTagged(ShipModel.MeshTag) do
		if model:IsA("Model") and model.PrimaryPart and model:IsDescendantOf(workspace) then
			local seat = model:FindFirstChild("ShipSeat")
			local occupant = seat and seat:IsA("Seat") and seat.Occupant
			local own = model.Name == mine or (occupant ~= nil and character ~= nil and occupant.Parent == character)
			local dist = (model.PrimaryPart.Position - camera.CFrame.Position).Magnitude
			ShipModel.applyLod(model, ShipModel.lodLevel(dist, own, if type(tier) == "string" then tier else nil))
		end
	end
end

function NaveLod.init()
	if started then
		return
	end
	started = true
	local ShipModel = require(ReplicatedStorage.Shared.AirCombat.ShipModel)
	task.spawn(function()
		while true do
			task.wait(0.5)
			pcall(step, ShipModel)
		end
	end)
end

return NaveLod
