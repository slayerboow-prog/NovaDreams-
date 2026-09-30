-- ToyService (servidor): balones y conos con física que todos ven igual.
--
--   * Los juguetes del mapa (etiqueta "Toy", atributo Toy = Futbol | Playa | Baloncesto | Cono;
--     los coloca shared/Toys.make) están quietos (anclados) hasta que alguien se acerca: entonces
--     se sueltan y tienen física de verdad (botan, ruedan, flotan en el agua).
--   * Al tocarlos corriendo o andando, salen disparados hacia donde vas: una patada (Toys.kickVelocity).
--   * Si se caen del mapa, o se quedan lejos de su sitio sin nadie cerca, vuelven solos a su sitio
--     y se vuelven a anclar (no gastan servidor mientras nadie juega con ellos).
-- La física la calcula el servidor (dueño de la pieza) para que la patada sea igual para todos.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Toys = require(ReplicatedStorage.Shared.Toys)

local ToyService = {}

local WAKE_DISTANCE = 90 -- con alguien más cerca que esto, el juguete tiene física
local KICK_COOLDOWN = 0.3

type Toy = {
	Part: BasePart,
	Kind: Toys.Kind,
	Home: CFrame,
	Awake: boolean,
	LastKick: number,
}

local toys: { [BasePart]: Toy } = {}

local function sound(part: BasePart)
	local kick = Instance.new("Sound")
	kick.Name = "Kick"
	kick.SoundId = "rbxasset://sounds/collide.wav"
	kick.Volume = 0.6
	kick.RollOffMaxDistance = 80
	-- Cada cliente lo mete en su grupo de efectos (SoundFx): así «Sonidos: no» también lo calla
	kick:SetAttribute("SfxGroup", "SFX")
	kick.Parent = part
end

local function wake(toy: Toy)
	if toy.Awake or not toy.Part.Parent then
		return
	end
	toy.Awake = true
	local part = toy.Part
	part.Anchored = false
	part.CanCollide = true
	part.CanTouch = true
	pcall(function()
		part:SetNetworkOwner(nil) -- lo simula el servidor: la patada es igual para todos
	end)
end

local function sleep(toy: Toy)
	local part = toy.Part
	part.AssemblyLinearVelocity = Vector3.zero
	part.AssemblyAngularVelocity = Vector3.zero
	part.Anchored = true
	part.CFrame = toy.Home
	toy.Awake = false
end

local function characterOf(hit: BasePart): (Model?, Humanoid?, BasePart?)
	local model = hit:FindFirstAncestorOfClass("Model")
	while model do
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			return model, humanoid, model:FindFirstChild("HumanoidRootPart") :: BasePart?
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil, nil, nil
end

local function kick(toy: Toy, hit: BasePart)
	if not toy.Awake or os.clock() - toy.LastKick < KICK_COOLDOWN then
		return
	end
	local character, humanoid, root = characterOf(hit)
	if not character or not humanoid or not root or humanoid.Health <= 0 then
		return
	end
	-- Solo los jugadores patean (los personajes del mapa están anclados)
	if not Players:GetPlayerFromCharacter(character) then
		return
	end
	toy.LastKick = os.clock()
	local part = toy.Part
	local velocity = Toys.kickVelocity(toy.Kind, part.Position, root.Position, root.AssemblyLinearVelocity)
	part:ApplyImpulse(velocity * part.AssemblyMass)
	local s = part:FindFirstChild("Kick") :: Sound?
	if s then
		s.PlaybackSpeed = 0.9 + math.random() * 0.3
		s:Play()
	end
end

-- Un vehículo le da (KnockService, ya validado): sale con esta velocidad (y este giro)
function ToyService.push(part: BasePart, velocity: Vector3, spin: Vector3?): boolean
	local toy = toys[part]
	if not toy or not part.Parent then
		return false
	end
	wake(toy)
	toy.LastKick = os.clock()
	part.AssemblyLinearVelocity = velocity
	if spin then
		part.AssemblyAngularVelocity = spin
	end
	local s = part:FindFirstChild("Kick") :: Sound?
	if s then
		s.PlaybackSpeed = 0.8 + math.random() * 0.2
		s:Play()
	end
	return true
end

local function add(instance: Instance)
	if not instance:IsA("BasePart") or toys[instance] then
		return
	end
	local kind = Toys.Kinds[instance:GetAttribute("Toy") or ""]
	if not kind then
		return
	end
	local part = instance
	part.CustomPhysicalProperties = PhysicalProperties.new(kind.Density, kind.Friction, kind.Elasticity, 1, 1)
	part.CanTouch = true
	part.CanQuery = true
	local toy: Toy = { Part = part, Kind = kind, Home = part.CFrame, Awake = false, LastKick = 0 }
	toys[part] = toy
	sound(part)
	part.Touched:Connect(function(hit)
		kick(toy, hit)
	end)
	part.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			toys[part] = nil
		end
	end)
end

-- Distancia al jugador más cercano
local function nearest(position: Vector3, roots: { Vector3 }): number
	local best = math.huge
	for _, p in roots do
		best = math.min(best, (p - position).Magnitude)
	end
	return best
end

function ToyService.init()
	for _, part in CollectionService:GetTagged("Toy") do
		add(part)
	end
	CollectionService:GetInstanceAddedSignal("Toy"):Connect(add)

	-- Despertar los que tienen a alguien cerca y devolver a su sitio los perdidos (cada segundo)
	task.spawn(function()
		while true do
			task.wait(1)
			local roots = {}
			for _, player in Players:GetPlayers() do
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root then
					table.insert(roots, root.Position)
				end
			end
			for part, toy in toys do
				-- Un juguete con error no para al resto
				local ok, err = pcall(function()
					if not part.Parent then
						toys[part] = nil
						return -- (dentro del pcall: pasa al siguiente juguete)
					end
					local distance = nearest(part.Position, roots)
					local homeDistance = nearest(toy.Home.Position, roots)
					if toy.Awake then
						if Toys.shouldReset(part.Position, toy.Home.Position, math.min(distance, homeDistance)) then
							sleep(toy)
						elseif distance > WAKE_DISTANCE * 1.5 and homeDistance > WAKE_DISTANCE * 1.5 and (part.Position - toy.Home.Position).Magnitude < 3 then
							sleep(toy) -- en su sitio y sin nadie: a dormir
						end
					elseif homeDistance < WAKE_DISTANCE then
						wake(toy)
					end
				end)
				if not ok then
					warn("[ToyService] " .. tostring(err))
				end
			end
		end
	end)
end

return ToyService
