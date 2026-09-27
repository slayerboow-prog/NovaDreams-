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

-- Apunta en los datos dónde está ahora el jugador (si está vivo y en el mapa)
local function record(player: Player, data: { [string]: any })
	if not player:GetAttribute("SpawnReady") then
		return -- todavía no ha aparecido donde toca: no pisar lo guardado con la plaza
	end
	if data.Life and data.Life.Stage == "Bebe" then
		data.Position = nil
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	local position = root.Position
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
			local hit = workspace:Raycast(position + V(0, 1, 0), V(0, -40, 0), params)
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
				local data = DataService.get(player)
				if data then
					record(player, data)
				end
			end
		end
	end)
end

return PositionService
