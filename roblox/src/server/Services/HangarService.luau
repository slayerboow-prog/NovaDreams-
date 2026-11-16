-- HangarService: la app «Hangar» del ValPhone (Controllers/Hangar). Desde el teléfono, estés donde estés:
--   * Comprar barcos (shared/Boats, BoatService) y aviones propios (AviationService.Prices).
--   * Desplegarlos: el barco aparece en el agua más cercana (BoatService.deploy) y el avión en un sitio
--     llano y despejado a tu lado (AviationService.deploy). Te sube al timón o a los mandos.
--   * Guardarlos (el barco desde cualquier sitio; el avión, en tierra).
-- Los aviones aterrizan en cualquier suelo firme del planeta (Controllers/Flying, Shared/Flight.Bounds
-- llega hasta las Tierras Exteriores).
--
-- Remoto «Hangar»: cliente → servidor ("Buy" | "Deploy" | "Store", tipo). Atributos para la interfaz:
-- OwnedBoats, BoatOut (BoatService), OwnedPlanes, PlaneOut, PilotLicense, JetReady (AviationService).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Boats = require(ReplicatedStorage.Shared.Boats)
local AviationService = require(script.Parent.AviationService)
local BoatService = require(script.Parent.BoatService)
local DataService = require(script.Parent.DataService)

local HangarService = {}

HangarService.Planes = { "Avioneta", "Avion" }
HangarService.Cooldown = 1.5 -- (un toque cada tanto: el teléfono no dispara dos despliegues)

local last: { [Player]: number } = {}

local function isPlane(kind: any): boolean
	return type(kind) == "string" and AviationService.Prices[kind] ~= nil
end

function HangarService.handle(player: Player, action: any, kind: any): (boolean, string?)
	local now = os.clock()
	if last[player] and now - last[player] < HangarService.Cooldown then
		return false, "Cooldown"
	end
	last[player] = now
	if action == "Store" then
		local a = BoatService.storeAnywhere(player)
		local b = AviationService.store(player)
		return a or b, nil
	end
	if Boats.isBoat(kind) then
		if action == "Buy" then
			return BoatService.buy(player, kind, true)
		elseif action == "Deploy" then
			return BoatService.deploy(player, kind)
		end
	elseif isPlane(kind) then
		if action == "Buy" then
			return AviationService.buy(player, kind)
		elseif action == "Deploy" then
			return AviationService.deploy(player, kind)
		end
	end
	return false, "Unknown"
end

function HangarService.init()
	local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Hangar") :: RemoteEvent
	remote.OnServerEvent:Connect(function(player, action, kind)
		local ok, err = pcall(HangarService.handle, player, action, kind)
		if not ok then
			warn("[HangarService] " .. tostring(err))
		end
	end)
	local function ready(player: Player)
		-- (cuando sus datos han cargado: lo que tiene en el hangar)
		for _ = 1, 60 do
			if not player.Parent then
				return
			end
			if DataService.get(player) then
				AviationService.syncOwned(player)
				BoatService.sync(player)
				return
			end
			task.wait(1)
		end
	end
	for _, player in Players:GetPlayers() do
		task.spawn(ready, player)
	end
	Players.PlayerAdded:Connect(function(player)
		task.spawn(ready, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		last[player] = nil
	end)
	-- (la licencia y los aterrizajes cambian volando: se refresca de vez en cuando)
	task.spawn(function()
		while true do
			task.wait(10)
			for _, player in Players:GetPlayers() do
				if DataService.get(player) then
					pcall(AviationService.syncOwned, player)
				end
			end
		end
	end)
end

return HangarService
