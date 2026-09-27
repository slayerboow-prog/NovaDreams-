-- LifeService: cómo se nota la etapa de vida en el cuerpo y en lo que puedes hacer.
--   * Tamaño del personaje (bebé pequeñito, niño, adolescente, adulto) con Model:ScaleTo
--   * Velocidad al andar y altura del salto (NeedsService usa el atributo StageWalkSpeed)
--   * Límites por edad: LifeService.allows(player, "Work") -> un bebé no trabaja, un niño no se compra casa
--   * Músculo: la Fuerza del gimnasio (atributo GymStrength, GymService) ensancha hombros, brazos y
--     torso (BodyWidthScale y BodyDepthScale del Humanoid). Se multiplica con el tamaño de la edad:
--     primero se ponen las medidas a tamaño 1 y luego se escala a la edad (como hace AvatarService).
-- La etapa la decide la historia de vida (atributo LifeStage); aquí solo se aplica.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Gym = require(ReplicatedStorage.Shared.Gym)

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

-- Medidas del cuerpo que cambia el gimnasio. Se apunta la de base (la del aspecto) para multiplicar
-- siempre desde ella; si otro sistema la cambia (AvatarService al vestir), esa pasa a ser la base.
local MUSCLE_VALUES = { "BodyWidthScale", "BodyDepthScale" }

local function muscleWants(player: Player, humanoid: Humanoid): { [NumberValue]: number }
	local wants = {}
	if humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return wants
	end
	local width, depth = Gym.bodyScale(player:GetAttribute("GymStrength"))
	for i, name in MUSCLE_VALUES do
		local value = humanoid:FindFirstChild(name)
		if not value then
			value = Instance.new("NumberValue")
			value.Name = name
			value.Value = 1
			value.Parent = humanoid
		end
		if value:IsA("NumberValue") then
			local base = value:GetAttribute("GymBase")
			local written = value:GetAttribute("GymWritten")
			if type(base) ~= "number" or type(written) ~= "number" or math.abs(value.Value - written) > 1e-3 then
				base = value.Value
				value:SetAttribute("GymBase", base)
			end
			local want = base * (if i == 1 then width else depth)
			if math.abs(value.Value - want) > 1e-3 then
				wants[value] = want
			end
		end
	end
	return wants
end

local function applyBody(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid then
		return
	end
	local scale = bodyFor(player).Scale
	-- Músculo (gimnasio): con el personaje a tamaño 1, y luego se vuelve a su tamaño
	local wants = muscleWants(player, humanoid)
	if next(wants) ~= nil then
		pcall(function()
			if math.abs(character:GetScale() - 1) > 0.01 then
				character:ScaleTo(1)
			end
		end)
		for value, want in wants do
			value.Value = want
			value:SetAttribute("GymWritten", want)
		end
	end
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
	player:GetAttributeChangedSignal("GymStrength"):Connect(function()
		applyBody(player)
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
