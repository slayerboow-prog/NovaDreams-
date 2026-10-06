-- SettingsService: los ajustes del jugador que se guardan con su partida (de momento, los gráficos).
--
--   * Gráficos (menú «✨ Gráficos» / Ajustes): Auto, Bajo, Medio o Alto. Se guarda en data.Graphics
--     y vuelve al entrar en el atributo GraphicsChoice; el cliente (UI/Perf) lo pone ANTES de que el
--     «Auto» empiece a medir, así quien lo deja en Alto entra en Alto (antes, al entrar con el móvil,
--     siempre empezaba en Bajo).
--   * El consejo de subir también la calidad de Roblox (móvil) sale una sola vez: data.GraphicsTipSeen
--     -> atributo GraphicsTipSeen.
-- Remoto GraphicsChoice: ("Choice", "Auto" | "Low" | "Medium" | "High") o ("TipSeen").

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Graphics = require(ReplicatedStorage.Shared.Graphics)
local DataService = require(script.Parent.DataService)

local SettingsService = {}

-- Lo guardado (o «Auto» si no hay nada o no vale)
function SettingsService.graphicsOf(data: { [string]: any }?): string
	local value = data and data.Graphics
	return if Graphics.isChoice(value) then value else "Auto"
end

function SettingsService.handle(player: Player, action: any, value: any)
	local data = DataService.get(player)
	if action == "Choice" then
		if not Graphics.isChoice(value) then
			return
		end
		if data then
			data.Graphics = value
		end
		player:SetAttribute("GraphicsChoice", value)
	elseif action == "TipSeen" then
		if data then
			data.GraphicsTipSeen = true
		end
		player:SetAttribute("GraphicsTipSeen", true)
	end
end

function SettingsService.loaded(player: Player, data: { [string]: any })
	player:SetAttribute("GraphicsTipSeen", data.GraphicsTipSeen == true)
	player:SetAttribute("GraphicsChoice", SettingsService.graphicsOf(data))
end

local lastCall: { [Player]: number } = {}
function SettingsService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local remote = remotes:FindFirstChild("GraphicsChoice") :: RemoteEvent?
	if not remote then
		local created = Instance.new("RemoteEvent")
		created.Name = "GraphicsChoice"
		created.Parent = remotes
		remote = created
	end
	(remote :: RemoteEvent).OnServerEvent:Connect(function(player, action, value)
		-- (sin abusar: como mucho unas cuantas veces por segundo)
		local now = os.clock()
		if now - (lastCall[player] or -1) < 0.2 then
			return
		end
		lastCall[player] = now
		SettingsService.handle(player, action, value)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastCall[player] = nil
	end)
	DataService.onLoaded(SettingsService.loaded)
end

return SettingsService
