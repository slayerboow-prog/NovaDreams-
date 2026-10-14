-- UpdateService: cuando se publica una versión nueva del juego, los servidores viejos se vacían
-- solos. Cada servidor nuevo avisa (MessagingService) con su versión; un servidor de una
-- versión anterior avisa a sus jugadores y, a los pocos segundos, los lleva a un servidor
-- nuevo (TeleportService): primero a un servidor reservado de paso y de ahí a uno normal, para no
-- volver a caer en uno viejo. Antes se guarda todo (DataService, al salir).

local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UpdateService = {}

local TOPIC = "NuevaVersion"
local WARN_SECONDS = 15
local BACK_SECONDS = 8 -- en el servidor puente: espera antes de volver a un servidor normal
local moving = false
local lateJoinConnection: RBXScriptConnection? = nil -- (una sola vez: los reintentos no apilan conexiones)
local reservedCode: string? = nil

-- Lleva a unos jugadores al servidor nuevo. Patrón "soft shutdown": primero a un servidor reservado
-- (que siempre arranca con la versión nueva) y desde ahí vuelven a uno normal. Si no se puede
-- reservar, directamente a uno normal (puede que caigan en otro viejo, pero ese también se vaciará).
local function teleportOut(players: { Player }): (boolean, any)
	if not reservedCode then
		local ok, code = pcall(function()
			return TeleportService:ReserveServer(game.PlaceId)
		end)
		if ok and type(code) == "string" then
			reservedCode = code
		end
	end
	return pcall(function()
		local options = Instance.new("TeleportOptions")
		if reservedCode then
			options.ReservedServerAccessCode = reservedCode
			options:SetTeleportData({ SoftShutdown = true })
		end
		TeleportService:TeleportAsync(game.PlaceId, players, options)
	end)
end

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
	-- Los que entren después de esto también se van al nuevo (conectado una sola vez)
	if not lateJoinConnection then
		lateJoinConnection = Players.PlayerAdded:Connect(function(player)
			task.wait(3)
			if player.Parent then
				teleportOut({ player })
			end
		end)
	end
	local players = Players:GetPlayers()
	if #players == 0 then
		return
	end
	local ok, err = teleportOut(players)
	if not ok then
		warn("[Actualización] No se pudo llevar a los jugadores al servidor nuevo:", err)
		moving = false -- el próximo aviso lo vuelve a intentar
	end
end

-- Servidor puente del soft shutdown: los que llegan con SoftShutdown vuelven a un servidor normal
local function isBridgeServer(): boolean
	return game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
end

local function sendBack(player: Player)
	local joinData = player:GetJoinData()
	local data = joinData and joinData.TeleportData
	if type(data) ~= "table" or not data.SoftShutdown then
		return
	end
	task.wait(BACK_SECONDS)
	if not player.Parent then
		return
	end
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(game.PlaceId, { player })
	end)
	if not ok then
		warn("[Actualización] No se pudo devolver a un servidor normal:", err)
	end
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
	if isBridgeServer() then
		Players.PlayerAdded:Connect(function(player)
			sendBack(player)
		end)
		for _, player in Players:GetPlayers() do
			task.spawn(sendBack, player)
		end
		return -- el puente ya es de la versión nueva: no hace falta avisar a nadie
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
