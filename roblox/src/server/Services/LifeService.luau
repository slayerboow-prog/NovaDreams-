-- LifeService: cómo se nota la etapa de vida en el cuerpo y en lo que puedes hacer.
--   * Tamaño del personaje (bebé pequeñito, niño, adolescente, adulto) con Model:ScaleTo
--   * Velocidad al andar y altura del salto (NeedsService usa el atributo StageWalkSpeed)
--   * Límites por edad: LifeService.allows(player, "Work") -> un bebé no trabaja, un niño no se compra casa
-- La etapa la decide la historia de vida (atributo LifeStage); aquí solo se aplica.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)

local LifeService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent

local function bodyFor(player: Player)
	local stage = player:GetAttribute("LifeStage")
	return Config.StageBody[stage or ""] or Config.StageBody.Adulto
end

-- Velocidad base según la etapa (el bebé que aún gatea va más despacio)
local function applySpeed(player: Player)
	local body = bodyFor(player)
	local speed = body.WalkSpeed
	if player:GetAttribute("Crawling") then
		speed = Config.Baby.CrawlSpeed
	end
	player:SetAttribute("StageWalkSpeed", speed)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = math.min(humanoid.WalkSpeed, speed) -- NeedsService lo ajusta del todo en su siguiente vuelta
		humanoid.UseJumpPower = false
		humanoid.JumpHeight = if player:GetAttribute("Crawling") then 0 else body.JumpHeight
	end
end

local function applyBody(player: Player)
	local character = player.Character
	if not character or not character:FindFirstChildOfClass("Humanoid") then
		return
	end
	local scale = bodyFor(player).Scale
	if math.abs(character:GetScale() - scale) > 0.01 then
		local ok, err = pcall(function()
			character:ScaleTo(scale)
		end)
		if not ok then
			warn("[LifeService] No se pudo escalar el personaje:", err)
		end
	end
	applySpeed(player)
end

-- ¿Puede este jugador hacer esto a su edad? Si no, se le explica con un aviso.
function LifeService.allows(player: Player, action: string, silent: boolean?): boolean
	local ok = Stages.allows(player:GetAttribute("LifeStage"), action, Config.StageLimits)
	if not ok and not silent then
		Notify:FireClient(player, "Error", Strings.get("LIMIT." .. action))
	end
	return ok
end

function LifeService.refresh(player: Player)
	applyBody(player)
end

local function watch(player: Player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid", 10)
		task.defer(applyBody, player)
	end)
	player:GetAttributeChangedSignal("LifeStage"):Connect(function()
		applyBody(player)
	end)
	player:GetAttributeChangedSignal("Crawling"):Connect(function()
		applySpeed(player)
	end)
	if player.Character then
		task.defer(applyBody, player)
	end
end

function LifeService.init()
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
end

return LifeService
