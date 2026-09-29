-- HospitalService: la muerte y el reaparecer en el hospital (reglas en shared/Hospital).
--
-- Al morir (Humanoid.Died) se avisa al cliente (pantalla de HAS MUERTO) y, al reaparecer, se lleva
-- al jugador delante del hospital más cercano al sitio donde murió y se le cobra la factura. Morir
-- no libra de la búsqueda: si te buscaban, al reaparecer te detienen (a disposición judicial).
-- Los presos reaparecen en su celda (o en la de aislamiento, si estaban castigados).
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
local PrisonService = require(script.Parent.PrisonService)

local HospitalService = {}

local Remote: RemoteEvent
local diedAt: { [Player]: Vector3 } = {}
local spots: { { Position: Vector3, Look: Vector3 } }? = nil
local retryAt = 0 -- si no se encontró ningún hospital, no se vuelve a buscar hasta esta hora

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
	-- Sin hospitales: la búsqueda recorre todo el mapa, así que el "no hay" se recuerda 30 s
	if spots and os.clock() < retryAt then
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
	if #found == 0 then
		retryAt = os.clock() + 30
	end
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
	-- Dentro de un edificio (las salas están en el cielo): cuenta la puerta por la que entraste
	local door = player:GetAttribute("InteriorDoor")
	diedAt[player] = if typeof(door) == "Vector3" then door elseif root then root.Position else Vector3.zero
	player:SetAttribute("Dead", true)
	player:SetAttribute("KO", nil)
	-- Se apunta en la partida: si se sale estando muerto, al volver se le cura igual (factura y, si le
	-- buscaban, detención). Antes salir y entrar libraba de las dos cosas
	local data = DataService.get(player)
	if data then
		data.PendingRevive = true
	end
	if player:GetAttribute("Riding") then
		player:SetAttribute("Riding", nil)
	end
	-- (las estrellas se quedan: al reaparecer te detienen)
	StoryEvents.emit(player, "Died", {})
	Remote:FireClient(player, "Died", { Seconds = Hospital.RespawnSeconds, Jailed = JusticeService.isJailed(player) })
end

local function revive(player: Player, character: Model, from: Vector3)
	character:WaitForChild("HumanoidRootPart", 10)
	task.wait(0.2)
	if JusticeService.isJailed(player) then
		-- Castigado en aislamiento: vuelve allí (el tiempo sigue corriendo)
		if not PrisonService.sendToIsolation(player) then
			JusticeService.sendToCell(player)
		end
		Remote:FireClient(player, "Revived", { Jailed = true })
		StoryEvents.emit(player, "Revived", { Jailed = true })
		return
	end
	if JusticeService.returnToDock(player) then
		-- Murió en pleno juicio: vuelve al banquillo, sin factura (el juicio sigue).
		-- (a la historia se le dice "Jailed": así no le lleva a ningún sitio)
		Remote:FireClient(player, "Revived", { Bill = 0, Trial = true })
		StoryEvents.emit(player, "Revived", { Bill = 0, Jailed = true })
		return
	end
	if player:GetAttribute("LifeStage") == "Bebe" then
		-- Un bebé no va al hospital ni paga: vuelve a su cuna (BabyService)
		Remote:FireClient(player, "Revived", { Bill = 0 })
		StoryEvents.emit(player, "Revived", { Bill = 0 })
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

local function onRespawn(player: Player, character: Model)
	local from = diedAt[player]
	if not from then
		return
	end
	diedAt[player] = nil
	local data = DataService.get(player)
	if data then
		data.PendingRevive = nil
	end
	local ok, err = pcall(revive, player, character, from)
	if not ok then
		warn("[Hospital] " .. tostring(err))
	end
	-- Hasta aquí seguía «muerto» (la policía no le da por escapado mientras reaparece).
	-- Si le buscaban, morir no le libra: detenido como si le hubieran alcanzado (sin premio a nadie)
	player:SetAttribute("Dead", nil)
	if player.Parent and not JusticeService.isJailed(player) and WantedService.stars(player) > 0 then
		WantedService.arrest(player, nil)
	end
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

	-- Se fue estando muerto (PendingRevive): al volver despierta en el hospital, paga la factura y, si
	-- le buscaban, le detienen, igual que si hubiera reaparecido sin salir del juego
	DataService.onLoaded(function(player, data)
		if not data.PendingRevive then
			return
		end
		-- Esperar a que PositionService le ponga donde estaba (si no, luego nos movería a ese sitio)
		local deadline = os.clock() + 30
		while player.Parent and not player:GetAttribute("SpawnReady") and os.clock() < deadline do
			task.wait(0.2)
		end
		local character = player.Character
		if not player.Parent or not character or diedAt[player] then
			return -- (se ha ido otra vez: la marca sigue guardada; o ha vuelto a morir: ya se ocupa onRespawn)
		end
		data.PendingRevive = nil
		local saved = data.Position
		local from = if type(saved) == "table" and type(saved.X) == "number" and type(saved.Z) == "number"
			then Vector3.new(saved.X, saved.Y or 0, saved.Z)
			else nil
		local ok, err = pcall(revive, player, character, from or Vector3.zero)
		if not ok then
			warn("[Hospital] " .. tostring(err))
		end
		-- La búsqueda guardada vuelve unos segundos después de entrar (WantedService): se espera a ella
		if (tonumber(data.Wanted) or 0) > 0 then
			local until_ = os.clock() + 12
			while player.Parent and WantedService.stars(player) <= 0 and os.clock() < until_ do
				task.wait(0.5)
			end
			if player.Parent and not JusticeService.isJailed(player) and WantedService.stars(player) > 0 then
				WantedService.arrest(player, nil)
			end
		end
	end)
end

return HospitalService
