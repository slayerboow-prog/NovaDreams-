-- UpdateService: cuando se publica una versión nueva del juego, los servidores viejos se vacían
-- solos. Cada servidor nuevo avisa (MessagingService) con su versión; un servidor de una
-- versión anterior avisa a sus jugadores y, a los pocos segundos, los lleva a un servidor
-- nuevo (TeleportService). Antes se guarda todo (DataService, al salir).

local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UpdateService = {}

local TOPIC = "NuevaVersion"
local WARN_SECONDS = 15
local moving = false

local function moveEveryone(version: number)
	if moving then
		return
	end
	moving = true
	local remote = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("Update") :: RemoteEvent?
	if remote then
		remote:FireAllClients("Soon", { Seconds = WARN_SECONDS, Version = version })
	end
	task.wait(WARN_SECONDS)
	local players = Players:GetPlayers()
	if #players == 0 then
		return
	end
	local ok, err = pcall(function()
		local options = Instance.new("TeleportOptions")
		TeleportService:TeleportAsync(game.PlaceId, players, options)
	end)
	if not ok then
		warn("[Actualización] No se pudo llevar a los jugadores al servidor nuevo:", err)
		moving = false
	end
	-- Los que entren después de esto también se van al nuevo
	Players.PlayerAdded:Connect(function(player)
		task.wait(3)
		pcall(function()
			TeleportService:TeleportAsync(game.PlaceId, { player })
		end)
	end)
end

function UpdateService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	if not remotes:FindFirstChild("Update") then
		local remote = Instance.new("RemoteEvent")
		remote.Name = "Update"
		remote.Parent = remotes
	end
	if RunService:IsStudio() or game.PlaceId == 0 then
		return
	end
	local mine = game.PlaceVersion
	task.spawn(function()
		pcall(function()
			MessagingService:SubscribeAsync(TOPIC, function(message)
				local version = tonumber(message.Data)
				if version and version > mine then
					moveEveryone(version)
				end
			end)
		end)
		-- Avisar a los servidores viejos de que ya hay uno nuevo (unas veces, por si alguno no lo oye)
		for _ = 1, 3 do
			pcall(function()
				MessagingService:PublishAsync(TOPIC, mine)
			end)
			task.wait(60)
		end
	end)
end

return UpdateService
