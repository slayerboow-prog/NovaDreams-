-- HospitalService: la muerte y el reaparecer en el hospital (reglas en shared/Hospital).
--
-- Al morir (Humanoid.Died) se avisa al cliente (pantalla de HAS MUERTO), se pierden las
-- estrellas de búsqueda y, al reaparecer, se lleva al jugador delante del hospital más cercano
-- al sitio donde murió y se le cobra la factura. Los presos reaparecen en su celda.
-- Para las misiones: StoryEvents "Died" y "Revived".

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hospital = require(ReplicatedStorage.Shared.Hospital)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)
local SceneService = require(script.Parent.SceneService)
local InteriorService = require(script.Parent.InteriorService)
local WantedService = require(script.Parent.WantedService)
local JusticeService = require(script.Parent.JusticeService)

local HospitalService = {}

local Remote: RemoteEvent
local diedAt: { [Player]: Vector3 } = {}
local spots: { { Position: Vector3, Look: Vector3 } }? = nil

local function isHospital(model: Instance): boolean
	local node: Instance? = model
	while node and node ~= workspace do
		if table.find(Hospital.Models, node.Name) then
			return true
		end
		node = node.Parent
	end
	return false
end

-- Sitios donde se reaparece: delante de la puerta de cada hospital y centro de salud
local function hospitalSpots(): { { Position: Vector3, Look: Vector3 } }
	if spots and #spots > 0 then
		return spots
	end
	local found = {}
	for _, building in InteriorService.all() do
		if building.Model and isHospital(building.Model) then
			table.insert(found, { Position = building.Door + building.Out * 5, Look = building.Out })
		end
	end
	if #found == 0 then
		-- Sin puertas conocidas: al lado del edificio
		for _, model in workspace:GetDescendants() do
			if model:IsA("Model") and table.find(Hospital.Models, model.Name) then
				local ok, cf, size = pcall(function()
					return model:GetBoundingBox()
				end)
				if ok then
					table.insert(found, { Position = cf.Position + cf.LookVector * (size.Z / 2 + 8) - Vector3.new(0, size.Y / 2, 0), Look = cf.LookVector })
				end
			end
		end
	end
	spots = found
	return found
end

local function nearestSpot(from: Vector3?): { Position: Vector3, Look: Vector3 }?
	local best, bestDistance = nil, math.huge
	for _, spot in hospitalSpots() do
		local distance = if from then (spot.Position - from).Magnitude else 0
		-- El hospital grande gana a igualdad (y si no se sabe dónde murió)
		if distance < bestDistance then
			best, bestDistance = spot, distance
		end
	end
	return best
end

local function onDied(player: Player, character: Model)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	diedAt[player] = if root then root.Position else Vector3.zero
	player:SetAttribute("Dead", true)
	if player:GetAttribute("Riding") then
		player:SetAttribute("Riding", nil)
	end
	pcall(function()
		if WantedService.stars(player) > 0 then
			WantedService.clear(player)
		end
	end)
	StoryEvents.emit(player, "Died", {})
	Remote:FireClient(player, "Died", { Seconds = Hospital.RespawnSeconds, Jailed = JusticeService.isJailed(player) })
end

local function onRespawn(player: Player, character: Model)
	local from = diedAt[player]
	if not from then
		return
	end
	diedAt[player] = nil
	player:SetAttribute("Dead", nil)
	character:WaitForChild("HumanoidRootPart", 10)
	task.wait(0.2)
	if JusticeService.isJailed(player) then
		JusticeService.sendToCell(player)
		Remote:FireClient(player, "Revived", { Jailed = true })
		StoryEvents.emit(player, "Revived", { Jailed = true })
		return
	end
	local spot = nearestSpot(from)
	if spot then
		SceneService.teleportTo(player, spot.Position)
	end
	local data = DataService.get(player)
	local bill = if data then Hospital.bill(data.Money or 0) else 0
	if bill > 0 then
		DataService.spend(player, bill)
	end
	Remote:FireClient(player, "Revived", { Bill = bill })
	StoryEvents.emit(player, "Revived", { Bill = bill })
end

function HospitalService.isDead(player: Player): boolean
	return diedAt[player] ~= nil
end

function HospitalService.init()
	Players.RespawnTime = Hospital.RespawnSeconds
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:FindFirstChild("Hospital") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "Hospital"
		Remote.Parent = remotes
	end
	local function watch(player: Player)
		local function hook(character: Model)
			task.spawn(onRespawn, player, character)
			local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
			if humanoid then
				humanoid.Died:Connect(function()
					onDied(player, character)
				end)
			end
		end
		player.CharacterAdded:Connect(hook)
		if player.Character then
			task.spawn(hook, player.Character)
		end
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		diedAt[player] = nil
	end)
end

return HospitalService
