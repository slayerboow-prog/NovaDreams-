-- ActionService: acciones del personaje que tienen que ver todos los jugadores.
--   * Linterna (tecla L): una luz que sale del pecho del personaje, hacia delante
--   * Sentarse en los bancos y marquesinas (etiqueta "Bench"): cartel "Sentarse"
--     (los asientos no se usan al tocarlos, para no sentarse sin querer al pasar)
-- (Los gestos, bailes, trepar y sentarse los hace el cliente: las animaciones del propio
--  personaje ya se ven en los demás jugadores. Ver client/Controllers/Actions.luau)

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ActionService = {}

local Remote = ReplicatedStorage.Remotes.Actions :: RemoteEvent

local function flashlight(player: Player, on: boolean)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local attachment = root:FindFirstChild("Flashlight")
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "Flashlight"
		attachment.Position = Vector3.new(0, 0.8, -0.8)
		local light = Instance.new("SpotLight")
		light.Name = "Beam"
		light.Angle = 55
		light.Range = 48
		light.Brightness = 3
		light.Color = Color3.fromRGB(255, 244, 222)
		light.Shadows = true
		light.Face = Enum.NormalId.Front
		light.Parent = attachment
		local glow = Instance.new("PointLight")
		glow.Name = "Glow"
		glow.Range = 7
		glow.Brightness = 0.6
		glow.Color = light.Color
		glow.Parent = attachment
		attachment.Parent = root
	end
	for _, light in attachment:GetChildren() do
		if light:IsA("Light") then
			light.Enabled = on
		end
	end
	player:SetAttribute("Flashlight", on)
end

local function setupBench(bench: Instance)
	local seat = bench:FindFirstChild("Seat")
	if not seat or not seat:IsA("Seat") or seat:FindFirstChild("SitPrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SitPrompt"
	prompt.ActionText = "Sentarse"
	prompt.ObjectText = if bench.Name == "BusStop" then "Parada de autobús" else "Banco"
	prompt.MaxActivationDistance = 6
	prompt.RequiresLineOfSight = false
	prompt.Parent = seat
	prompt.Triggered:Connect(function(player)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 and not seat.Occupant and not humanoid.SeatPart then
			seat:Sit(humanoid)
		end
	end)
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		prompt.Enabled = seat.Occupant == nil
	end)
end

function ActionService.init()
	for _, bench in CollectionService:GetTagged("Bench") do
		setupBench(bench)
	end
	CollectionService:GetInstanceAddedSignal("Bench"):Connect(setupBench)
	Remote.OnServerEvent:Connect(function(player, action, value)
		if action == "Flashlight" then
			flashlight(player, value == true)
		end
	end)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			player:SetAttribute("Flashlight", false)
		end)
	end)
end

return ActionService
