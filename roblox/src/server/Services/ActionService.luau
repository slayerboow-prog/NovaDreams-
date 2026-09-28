-- ActionService: acciones del personaje que tienen que ver todos los jugadores.
--   * Linterna (tecla L): una luz que sale del pecho del personaje, hacia delante
--   * Sentarse en los bancos y marquesinas (etiqueta "Bench"): cartel "Sentarse"
--   * Postura (agacharse / tumbarse): el cliente la pide y aquí se comprueba (shared/Movement) y se
--     pone el atributo "Stance" del jugador ("Stand", "Crouch", "Prone"), que ven todos. Se vuelve a
--     "Stand" al montar, sentarse, morir o reaparecer.
--   * Saltos de parkour: el cliente avisa y aquí se pone el atributo "Vault" ("Tipo|inicio|duración")
--     para que los demás vean la postura.
--     (los asientos no se usan al tocarlos, para no sentarse sin querer al pasar)
-- (Los gestos, bailes, trepar y sentarse los hace el cliente: las animaciones del propio
--  personaje ya se ven en los demás jugadores. Ver client/Controllers/Actions.luau)

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Movement = require(ReplicatedStorage.Shared.Movement)

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

---------------------------------------------------------------------
-- Postura y saltos
---------------------------------------------------------------------
local lastStance: { [Player]: { Count: number, Since: number } } = {}
local lastVault: { [Player]: number } = {}

local function stanceContext(player: Player): Movement.StanceContext
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return {
		Stage = player:GetAttribute("LifeStage"),
		Crawling = player:GetAttribute("Crawling") == true,
		Riding = player:GetAttribute("Riding") ~= nil or player:GetAttribute("Passenger") ~= nil,
		Seated = humanoid ~= nil and (humanoid.SeatPart ~= nil or humanoid.Sit),
		Swimming = humanoid ~= nil and humanoid:GetState() == Enum.HumanoidStateType.Swimming,
		Dead = humanoid == nil or humanoid.Health <= 0,
		KO = player:GetAttribute("KO") == true,
	}
end

-- Pide una postura: si vale, se pone; si no, se le dice al cliente cuál tiene (y por qué)
function ActionService.setStance(player: Player, stance: any): boolean
	-- Como mucho 8 cambios por segundo
	local now = os.clock()
	local rate = lastStance[player]
	if not rate or now - rate.Since > 1 then
		rate = { Count = 0, Since = now }
		lastStance[player] = rate
	end
	rate.Count += 1
	local ok, why = Movement.allowed(stance, stanceContext(player))
	if rate.Count > 8 then
		ok, why = false, nil
	end
	if not ok then
		Remote:FireClient(player, "Stance", player:GetAttribute("Stance") or "Stand", why)
		return false
	end
	player:SetAttribute("Stance", stance)
	return true
end

-- Un salto de parkour (para que los demás lo vean)
function ActionService.vault(player: Player, data: any): boolean
	if type(data) ~= "table" or type(data.Kind) ~= "string" or type(data.Duration) ~= "number" then
		return false
	end
	local kinds = { Speed = true, Kong = true, Climb = true, Ledge = true }
	local now = os.clock()
	if not kinds[data.Kind] or data.Duration < 0.2 or data.Duration > 2.5 or now - (lastVault[player] or 0) < 0.3 then
		return false
	end
	local ctx = stanceContext(player)
	if ctx.Dead or ctx.Riding or ctx.Seated or ctx.Stage == "Bebe" or ctx.Crawling then
		return false
	end
	lastVault[player] = now
	local start = workspace:GetServerTimeNow()
	if type(data.Start) == "number" and math.abs(data.Start - start) < 1 then
		start = data.Start -- el momento en que empezó en su pantalla
	end
	player:SetAttribute("Vault", ("%s|%.3f|%.2f"):format(data.Kind, start, data.Duration))
	return true
end

function ActionService.init()
	for _, bench in CollectionService:GetTagged("Bench") do
		setupBench(bench)
	end
	CollectionService:GetInstanceAddedSignal("Bench"):Connect(setupBench)
	Remote.OnServerEvent:Connect(function(player, action, value)
		if action == "Flashlight" then
			flashlight(player, value == true)
		elseif action == "Stance" then
			ActionService.setStance(player, value)
		elseif action == "Vault" then
			ActionService.vault(player, value)
		end
	end)
	-- Montar, sentarse o morir: de pie
	local function standUp(player: Player)
		if player:GetAttribute("Stance") ~= "Stand" then
			player:SetAttribute("Stance", "Stand")
		end
	end
	local function onPlayer(player: Player)
		player:SetAttribute("Stance", "Stand")
		local function onCharacter(character: Model)
			player:SetAttribute("Flashlight", false)
			standUp(player)
			local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
			if humanoid then
				humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
					if humanoid.SeatPart then
						standUp(player)
					end
				end)
				humanoid.Died:Connect(function()
					standUp(player)
				end)
			end
		end
		player.CharacterAdded:Connect(onCharacter)
		if player.Character then
			task.spawn(onCharacter, player.Character)
		end
		for _, attribute in { "Riding", "Passenger" } do
			player:GetAttributeChangedSignal(attribute):Connect(function()
				if player:GetAttribute(attribute) ~= nil then
					standUp(player)
				end
			end)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	-- (los que ya estaban dentro antes de que arrancara este servicio)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayer, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastStance[player] = nil
		lastVault[player] = nil
	end)
end

return ActionService
