-- PositionService: al salir del juego se guarda dónde estabas (posición exacta y hacia dónde mirabas)
-- y al volver a entrar apareces en ese mismo sitio, no en la plaza.
--
--  * Se apunta cada pocos segundos y justo antes de cada guardado (DataService.beforeSave),
--    así vale también si el móvil se desconecta de golpe.
--  * Los bebés no: siempre despiertan en su cuna (BabyService).
--  * Si debajo del punto guardado ya no hay suelo (el mapa ha cambiado), se aparece en la plaza.
--  * Al terminar pone el atributo "SpawnReady" en el jugador: la historia (LifeStoryService)
--    espera a eso para montar las escenas donde de verdad estás.

local Players = game:GetService("Players")

local DataService = require(script.Parent.DataService)
local Ground = require(game:GetService("ReplicatedStorage").Shared.Ground)

local PositionService = {}

local RECORD_SECONDS = 3
local V = Vector3.new

local function valid(saved: any): boolean
	if type(saved) ~= "table" then
		return false
	end
	for _, key in { "X", "Y", "Z" } do
		local n = saved[key]
		if type(n) ~= "number" or n ~= n or math.abs(n) > 1e6 then
			return false
		end
	end
	return saved.Y > workspace.FallenPartsDestroyHeight + 20
end

-- ¿Es un buen sitio para volver a aparecer? En el agua (nadando, buceando, en un barco) o en el
-- aire (saltando, cayendo, en parapente…) no: se guarda el último sitio en tierra firme.
local function safeSpot(humanoid: Humanoid): boolean
	local ok, safe = pcall(function()
		local state = humanoid:GetState()
		if state == Enum.HumanoidStateType.Swimming or state == Enum.HumanoidStateType.Freefall
			or state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Jumping
			or state == Enum.HumanoidStateType.Flying then
			return false
		end
		local floor = humanoid.FloorMaterial
		if floor == Enum.Material.Water then
			return false
		end
		local seat = humanoid.SeatPart
		if seat then
			-- En un vehículo: vale si está en tierra (no un barco en el agua ni un avión en el aire)
			return floor ~= Enum.Material.Air or seat.AssemblyLinearVelocity.Magnitude < 1
		end
		return floor ~= Enum.Material.Air
	end)
	return not ok or safe == true
end

-- Apunta en los datos dónde está ahora el jugador (si está vivo y en el mapa)
local function record(player: Player, data: { [string]: any })
	if not player:GetAttribute("SpawnReady") then
		return -- todavía no ha aparecido donde toca: no pisar lo guardado con la plaza
	end
	if data.Life and data.Life.Stage == "Bebe" then
		data.Position = nil
		return
	end
	if player:GetAttribute("InPrologue") then
		return -- en el sueño del prólogo: se guarda donde estaba antes de dormirse
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	local position = root.Position
	-- Dentro de un edificio (sala de InteriorService): se guarda la puerta, en la calle
	local door = player:GetAttribute("InteriorDoor")
	-- Volando (FlightService): se guarda la sala de llegadas del vuelo, en el suelo
	local landing = player:GetAttribute("FlightLanding")
	if typeof(door) == "Vector3" then
		position = door
	elseif typeof(landing) == "Vector3" then
		position = landing
	elseif not safeSpot(humanoid) then
		return -- nadando, en un barco o en el aire: se queda el último sitio seguro que se apuntó
	end
	local look = root.CFrame.LookVector
	local saved = { X = position.X, Y = position.Y, Z = position.Z, Yaw = math.atan2(-look.X, -look.Z) }
	if valid(saved) then
		data.Position = saved
	end
end

-- Pone al jugador donde lo dejó (solo al entrar, no al reaparecer tras caerse)
local function restore(player: Player, data: { [string]: any })
	local saved = data.Position
	if valid(saved) and not (data.Life and data.Life.Stage == "Bebe") then
		local character = player.Character or player.CharacterAdded:Wait()
		local root = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
		task.wait(0.3) -- dejar que LifeService le dé su tamaño
		if root and root.Parent and player.Parent then
			local position = V(saved.X, saved.Y, saved.Z)
			pcall(function()
				player:RequestStreamAroundAsync(position, 5)
			end)
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			local ignore = {}
			for _, other in Players:GetPlayers() do
				if other.Character then
					table.insert(ignore, other.Character)
				end
			end
			params.FilterDescendantsInstances = ignore
			-- Suelo justo debajo de los pies (desde poco más arriba: dentro de un edificio daría con el techo)
			-- (solo suelo de verdad: no encima de un coche aparcado o de un personaje)
			local hit = Ground.cast(position + V(0, 1, 0), V(0, -40, 0), params)
			if hit and hit.Material == Enum.Material.Water then
				hit = nil -- (en el agua no: mejor la cama o la plaza)
			end
			-- Sin suelo debajo (el mapa ha cambiado, era el agua…): a tu cama si tienes, si no se
			-- queda en la entrada del juego
			local bed = data.SpawnPoint
			if not hit and valid(bed) then
				position = V(bed.X, bed.Y, bed.Z)
				pcall(function()
					player:RequestStreamAroundAsync(position, 5)
				end)
				hit = Ground.cast(position + V(0, 1, 0), V(0, -40, 0), params)
			end
			if hit then
				local height = position.Y - hit.Position.Y
				local lift = math.clamp(height, 2, 5)
				root.AssemblyLinearVelocity = Vector3.zero
				character:PivotTo(CFrame.new(hit.Position + V(0, lift, 0)) * CFrame.Angles(0, saved.Yaw or 0, 0))
			end
		end
	end
	if player.Parent then
		player:SetAttribute("SpawnReady", true)
	end
end

function PositionService.init()
	DataService.onLoaded(function(player, data)
		restore(player, data)
	end)
	DataService.beforeSave(record)

	task.spawn(function()
		while true do
			task.wait(RECORD_SECONDS)
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(function()
					local data = DataService.get(player)
					if data then
						record(player, data)
					end
				end)
				if not ok then
					warn("[PositionService] " .. tostring(err))
				end
			end
		end
	end)
end

return PositionService
