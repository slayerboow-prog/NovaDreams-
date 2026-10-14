-- FunService: 🎈 la diversión que dan las cosas que ya existían (NeedsService.addFun).
--
--   * Por suceso (StoryEvents): pescar, una partida en los recreativos, una película, tocar en la calle,
--     sacar el barco, adoptar una mascota, cosechar… (Config.Fun y EVENTS de abajo).
--   * Mientras lo haces (cada TICK segundos):
--       - jugando un partido o una pachanga (atributo InSport: fútbol, baloncesto, vóley, raqueta,
--         carreras) → Config.Fun.SportPerMinute
--       - montado y moviéndote (atributo Riding: monopatín, kart, caballo, bici…) →
--         Config.Fun.RidePerMinute[vehículo]
--       - paseando con tu mascota (PetService.following, andando por la calle) → PetWalkPerMinute
--   Lo de los parques, el pícnic, la hoguera y el camping lo da ParkService.
--
-- Para los sistemas nuevos (feria, karts, skate…): NeedsService.addFun(player, cantidad, "Motivo").

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local NeedsService = require(script.Parent.NeedsService)

local FunService = {}

local Fun = Config.Fun
FunService.TICK = 5

-- Suceso de la historia -> { cantidad, motivo }
FunService.Events = {
	CaughtFish = { Fun.Fish, "Fish" },
	ArcadePlayed = { Fun.Arcade, "Arcade" },
	WatchedMovie = { Fun.Movie, "Movie" },
	BuskPlayed = { Fun.Busk, "Busk" },
	BoatLaunched = { Fun.Boat, "Boat" },
	PetAdopted = { Fun.PetAdopted, "PetAdopted" },
	FarmHarvest = { Fun.Harvest, "Harvest" },
}

function FunService.onEvent(player: Player, name: string, _payload: { [string]: any }?): number
	local entry = FunService.Events[name]
	if not entry then
		return 0
	end
	return NeedsService.addFun(player, entry[1], entry[2])
end

local function petService(): any
	return require(script.Parent.PetService)
end

-- Lo que da estar haciendo algo ahora mismo (seconds = cada cuánto se mira)
function FunService.step(player: Player, seconds: number): number
	local per = seconds / 60
	local total = 0
	if player:GetAttribute("InSport") then
		total += NeedsService.addFun(player, Fun.SportPerMinute * per, "Sport")
	end
	local riding = player:GetAttribute("Riding")
	if type(riding) == "string" then
		local rate = Fun.RidePerMinute[riding]
		local speed = 0
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			speed = root.AssemblyLinearVelocity.Magnitude
		end
		if rate and speed > 6 then
			total += NeedsService.addFun(player, rate * per, "Ride_" .. riding)
		end
	else
		-- Paseando con tu mascota (andando, no sentado ni en vehículo)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and root and root:IsA("BasePart") and not humanoid.SeatPart and root.AssemblyLinearVelocity.Magnitude > 4 then
			local ok, following = pcall(function()
				return petService().following(player)
			end)
			if ok and following then
				total += NeedsService.addFun(player, Fun.PetWalkPerMinute * per, "PetWalk")
			end
		end
	end
	return total
end

function FunService.init()
	StoryEvents.connect(function(player, name, payload)
		FunService.onEvent(player, name, payload)
	end)
	task.spawn(function()
		while true do
			task.wait(FunService.TICK)
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(FunService.step, player, FunService.TICK)
				if not ok then
					warn("[FunService] " .. tostring(err))
				end
			end
		end
	end)
end

return FunService
