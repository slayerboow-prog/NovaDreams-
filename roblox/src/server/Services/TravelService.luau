-- TravelService: autobús interurbano entre las ciudades de la región.
-- Cada parada (tag "TravelStop", atributo Town) ofrece viajar a las demás ciudades.
-- Mientras no haya coches conducibles, así se recorre la región sin caminar kilómetros.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Builder = require(script.Parent.Parent.World.Builder)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local LifeService = require(script.Parent.LifeService)

local TravelService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight }
local TRAVEL_SECONDS = 2

local stops: { [string]: BasePart } = {}
local traveling: { [Player]: boolean } = {}

function TravelService.travel(player: Player, destination: string)
	local target = stops[destination]
	local character = player.Character
	if not target or not character or traveling[player] then
		return
	end
	if not LifeService.allows(player, "Travel") then
		return
	end
	traveling[player] = true
	Notify:FireClient(player, "Travel", "🚌 Viajando a " .. destination .. "…")
	task.wait(TRAVEL_SECONDS / 2)
	if player.Parent and player.Character then
		-- Con StreamingEnabled hay que cargar la zona de destino antes de mover al jugador
		pcall(function()
			player:RequestStreamAroundAsync(target.Position, 5)
		end)
		-- Bajamos del autobús en la acera, delante de la parada
		player.Character:PivotTo(target.CFrame * CFrame.new(0, 2, -3))
	end
	task.wait(TRAVEL_SECONDS / 2)
	traveling[player] = nil
	if player.Parent then
		StoryEvents.emit(player, "Traveled", { Town = destination })
	end
end

local function setupStop(stop: Instance)
	if not stop:IsA("BasePart") then
		return
	end
	local town = stop:GetAttribute("Town")
	if typeof(town) ~= "string" then
		return
	end
	stops[town] = stop
end

function TravelService.init()
	for _, stop in CollectionService:GetTagged("TravelStop") do
		setupStop(stop)
	end

	-- Cada parada ofrece un botón por destino (teclas 1, 2, 3…)
	local names = {}
	for name in stops do
		table.insert(names, name)
	end
	table.sort(names)
	for origin, stop in stops do
		local key = 0
		for _, destination in names do
			if destination ~= origin then
				key += 1
				local prompt = Builder.prompt(stop, "Bus a " .. destination, "Autobús interurbano", 0.3)
				prompt.KeyboardKeyCode = KEYS[key] or Enum.KeyCode.E
				prompt.MaxActivationDistance = 12
				prompt.UIOffset = Vector2.new(0, (key - 1) * 58)
				prompt.Triggered:Connect(function(player)
					TravelService.travel(player, destination)
				end)
			end
		end
	end

	game:GetService("Players").PlayerRemoving:Connect(function(player)
		traveling[player] = nil
	end)
end

return TravelService
