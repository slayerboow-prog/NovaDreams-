-- BreakService (servidor): piedras que se cogen del suelo y se lanzan; cristales y puertas que se rompen.
--
--   * Coger (tecla B o botón 🥌 en móvil): de un suelo de tierra, césped, arena o roca. Llevas hasta
--     3, y se ve la piedra en tu mano.
--   * Lanzar (otra vez B): hacia donde apuntas. La piedra la calcula el servidor (con rayos, para no
--     atravesar cristales finos) y cada jugador la dibuja volando (Vandal "Stone").
--   * Cristales (ventanas de casas y edificios, de coches, de balcones…): se rompen en trozos que
--     caen al suelo. Puertas: aguantan unos golpes y se caen. Todo se arregla solo al rato.
--   * Consecuencias: los policías de servicio reciben el aviso («🚨 Vandalismo en …») y los
--     personajes a los que das se quejan.
--   * Las balas (WeaponService) rompen lo mismo con BreakService.hitStructure.
-- Las reglas (qué se rompe, cómo vuela la piedra) están en shared/Breakables.

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Breakables = require(ReplicatedStorage.Shared.Breakables)
local Npc = require(script.Parent.Parent.World.Npc)
local LocationService = require(script.Parent.LocationService)

local BreakService = {}

local Remote: RemoteEvent
local Notify: RemoteEvent

local PICK_COOLDOWN = 0.7
local THROW_COOLDOWN = 0.45
local MAX_RANGE = 250
local MAX_FLIGHT = 4 -- segundos

local lastPick: { [Player]: number } = {}
local lastThrow: { [Player]: number } = {}
local lastAlert: { [Player]: number } = {}

type Broken = { Transparency: number, CanCollide: boolean, CanQuery: boolean, CFrame: CFrame, Anchored: boolean, Color: Color3 }
local broken: { [BasePart]: Broken } = {}
-- Golpes de cada puerta: cuántos, cuándo el último, y su color y sitio de antes de golpearla
local doorHits: { [BasePart]: { Hits: number, Last: number, Color: Color3, CFrame: CFrame } } = {}

type Stone = { Id: number, Player: Player, From: Vector3, Velocity: Vector3, Start: number, Last: Vector3 }
local stones: { Stone } = {}
local nextId = 0

---------------------------------------------------------------------
-- La piedra en la mano
---------------------------------------------------------------------

local function stoneLook(part: BasePart, size: number)
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(size, size * 0.8, size)
	part.Color = Color3.fromRGB(120, 116, 110)
	part.Material = Enum.Material.Slate
end

local function showInHand(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local old = character:FindFirstChild("PiedraMano")
	local count = player:GetAttribute("Stones") or 0
	if count <= 0 then
		if old then
			old:Destroy()
		end
		return
	end
	if old then
		return
	end
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not hand or not hand:IsA("BasePart") then
		return
	end
	local stone = Instance.new("Part")
	stone.Name = "PiedraMano"
	stoneLook(stone, 0.6)
	stone.CanCollide = false
	stone.CanQuery = false
	stone.CanTouch = false
	stone.Massless = true
	stone.CFrame = hand.CFrame * CFrame.new(0, -hand.Size.Y / 2 - 0.15, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hand
	weld.Part1 = stone
	weld.Parent = stone
	stone.Parent = character
end

local function setStones(player: Player, count: number)
	player:SetAttribute("Stones", math.clamp(count, 0, Breakables.MaxStones))
	showInHand(player)
end

---------------------------------------------------------------------
-- Romper
---------------------------------------------------------------------

local function sound(at: Vector3, id: string, volume: number, pitch: number)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.CFrame = CFrame.new(at)
	anchor.Parent = workspace
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume
	s.PlaybackSpeed = pitch
	s.RollOffMaxDistance = 120
	s.Parent = anchor
	s:Play()
	Debris:AddItem(anchor, 3)
end

local function remember(part: BasePart)
	if not broken[part] then
		broken[part] = { Transparency = part.Transparency, CanCollide = part.CanCollide, CanQuery = part.CanQuery, CFrame = part.CFrame, Anchored = part.Anchored, Color = part.Color }
	end
end

local function repairLater(part: BasePart, extra: { BasePart }?)
	task.delay(Breakables.RepairSeconds + math.random() * 60, function()
		for _, p in { part, table.unpack(extra or {}) } do
			local was = broken[p]
			if was and p.Parent then
				p.Anchored = true
				p.AssemblyLinearVelocity = Vector3.zero
				p.AssemblyAngularVelocity = Vector3.zero
				p.CFrame = was.CFrame
				p.Transparency = was.Transparency
				p.CanCollide = was.CanCollide
				p.CanQuery = was.CanQuery
				p.Color = was.Color
			end
			broken[p] = nil
		end
		doorHits[part] = nil
	end)
end

local function breakGlass(part: BasePart, hitAt: Vector3, velocity: Vector3)
	remember(part)
	local color, alpha = part.Color, part.Transparency
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	sound(hitAt, "rbxasset://sounds/collide.wav", 0.9, 1.9)
	-- Trozos de cristal que caen
	local size = part.Size
	for _ = 1, Breakables.shards(size) do
		local shard = Instance.new("WedgePart")
		shard.Name = "Cristal"
		shard.Size = Vector3.new(0.05, 0.3 + math.random() * 0.6, 0.3 + math.random() * 0.6)
		shard.Color = color
		shard.Material = Enum.Material.Glass
		shard.Transparency = math.min(alpha, 0.6)
		shard.CanQuery = false
		shard.CanTouch = false
		local offset = Vector3.new((math.random() - 0.5) * size.X, (math.random() - 0.5) * size.Y, (math.random() - 0.5) * size.Z)
		shard.CFrame = part.CFrame * CFrame.new(offset) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		shard.AssemblyLinearVelocity = velocity * 0.12 + Vector3.new((math.random() - 0.5) * 8, math.random() * 4, (math.random() - 0.5) * 8)
		shard.Parent = workspace
		Debris:AddItem(shard, 4 + math.random() * 2)
	end
	repairLater(part)
end

local function hitDoor(part: BasePart, hitAt: Vector3, velocity: Vector3): boolean
	local entry = doorHits[part]
	if not entry then
		entry = { Hits = 0, Last = 0, Color = part.Color, CFrame = part.CFrame }
		doorHits[part] = entry
	end
	local door = entry :: { Hits: number, Last: number, Color: Color3, CFrame: CFrame }
	door.Hits = Breakables.doorHits(door.Hits, os.clock() - door.Last)
	door.Last = os.clock()
	sound(hitAt, "rbxasset://sounds/collide.wav", 0.8, 0.6)
	if door.Hits < Breakables.DoorHits then
		-- Aguanta: tiembla un momento y se va viendo más estropeada
		part.Color = door.Color:Lerp(Color3.new(0, 0, 0), Breakables.doorDamage(door.Hits))
		local push = velocity.Unit * 0.12
		part.CFrame = door.CFrame + push
		task.delay(0.08, function()
			if doorHits[part] == door and not broken[part] then
				part.CFrame = door.CFrame
			end
		end)
		-- Si nadie la vuelve a golpear en un rato, se «recupera»
		local last = door.Last
		task.delay(Breakables.DoorHeal + 0.5, function()
			if doorHits[part] == door and door.Last == last and not broken[part] then
				part.Color = door.Color
				doorHits[part] = nil
			end
		end)
		return false
	end
	-- Vuelve a su color y a su sitio antes de caerse (para dejarla como estaba al arreglarla)
	part.Color = door.Color
	part.CFrame = door.CFrame
	-- Se cae: la puerta y su pomo (si lo tiene al lado)
	local extra = {}
	local parent = part.Parent
	if parent then
		for _, sibling in parent:GetChildren() do
			if sibling:IsA("BasePart") and sibling ~= part and (sibling.Name:find("Knob") or sibling.Name:find("Handle")) and (sibling.Position - part.Position).Magnitude < 4 then
				table.insert(extra, sibling)
			end
		end
	end
	for _, p in { part, table.unpack(extra) } do
		remember(p)
		p.Anchored = false
		p.CanCollide = true
	end
	part.AssemblyLinearVelocity = velocity.Unit * 12
	sound(hitAt, "rbxasset://sounds/collide.wav", 1, 0.45)
	repairLater(part, extra)
	return true
end

-- ¿Se puede romper? (no lo que tiene cartel para usarse o una etiqueta de algún sistema; las
-- ventanas que se encienden de noche, sí)
local HARMLESS_TAGS = { NightWindow = true }
local function usable(part: BasePart): boolean
	if broken[part] or not part.Anchored then
		return false
	end
	if part:FindFirstChildWhichIsA("ProximityPrompt", true) then
		return false
	end
	for _, tag in CollectionService:GetTags(part) do
		if not HARMLESS_TAGS[tag] then
			return false
		end
	end
	return true
end

-- Las ventanas y puertas de decoración no las ven los rayos (CanQuery = false): se les activa para
-- que la piedra choque con ellas (siguen sin chocar con las personas: CanCollide no cambia)
local function makeHittable(part: Instance)
	if part:IsA("BasePart") and not part.CanQuery and (Breakables.isGlass(part.Name, part.Material, part.Size) or Breakables.isDoor(part.Name, part.Size)) then
		part.CanQuery = true
	end
end

local function personOf(part: BasePart): (Model?, Player?)
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		if model:FindFirstChildOfClass("Humanoid") then
			return model, Players:GetPlayerFromCharacter(model)
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil, nil
end

local function alertPolice(thrower: Player, at: Vector3, what: string)
	if os.clock() - (lastAlert[thrower] or 0) < 20 then
		return
	end
	lastAlert[thrower] = os.clock()
	thrower:SetAttribute("Vandalismo", (thrower:GetAttribute("Vandalismo") or 0) + 1)
	local zone = LocationService.zoneAt(at) or "la ciudad"
	for _, other in Players:GetPlayers() do
		if other ~= thrower and other:GetAttribute("Job") == "Policia" then
			Notify:FireClient(other, "Info", ("🚨 Vandalismo en %s: %s"):format(zone, what))
		end
	end
end

local function impact(stone: Stone, result: RaycastResult, velocity: Vector3)
	local part = result.Instance
	if part:IsA("BasePart") and usable(part) then
		if Breakables.isGlass(part.Name, part.Material, part.Size) then
			breakGlass(part, result.Position, velocity)
			alertPolice(stone.Player, result.Position, "han roto una ventana")
			return
		elseif Breakables.isDoor(part.Name, part.Size) then
			if hitDoor(part, result.Position, velocity) then
				alertPolice(stone.Player, result.Position, "han tirado una puerta abajo")
			end
			return
		end
	end
	if part:IsA("BasePart") then
		local model, victim = personOf(part)
		if victim then
			Notify:FireClient(victim, "Error", "🥌 ¡Te han tirado una piedra!")
		elseif model and model:FindFirstChild("Head") then
			Npc.say(model, "¡Eh! ¿Qué haces?")
			task.delay(3, function()
				if model.Parent then
					Npc.say(model, nil)
				end
			end)
		end
	end
	sound(result.Position, "rbxasset://sounds/collide.wav", 0.5, 1.3)
end

-- Otra cosa que golpea una pieza (una bala de WeaponService): rompe cristales y castiga puertas
-- igual que una piedra. Devuelve "Glass", "Door" o nil (no era rompible).
function BreakService.hitStructure(player: Player, part: Instance, hitAt: Vector3, velocity: Vector3): string?
	if not part:IsA("BasePart") or not usable(part) then
		return nil
	end
	if Breakables.isGlass(part.Name, part.Material, part.Size) then
		breakGlass(part, hitAt, velocity)
		alertPolice(player, hitAt, "han roto una ventana a tiros")
		return "Glass"
	elseif Breakables.isDoor(part.Name, part.Size) then
		if hitDoor(part, hitAt, velocity) then
			alertPolice(player, hitAt, "han tirado una puerta abajo a tiros")
		end
		return "Door"
	end
	return nil
end

-- Una piedra que ha chocado se queda en el suelo un rato
local function dropStone(at: Vector3, velocity: Vector3)
	local rock = Instance.new("Part")
	rock.Name = "Piedra"
	stoneLook(rock, 0.7)
	rock.CanQuery = false
	rock.CanTouch = false
	rock.CFrame = CFrame.new(at - velocity.Unit * 0.4)
	rock.AssemblyLinearVelocity = -velocity * 0.15 + Vector3.new(0, 5, 0)
	rock.Parent = workspace
	Debris:AddItem(rock, 6)
end

---------------------------------------------------------------------
-- Vuelo de las piedras (rayos entre una posición y la siguiente)
---------------------------------------------------------------------

local function gravity(): number
	return workspace.Gravity * Breakables.GravityScale
end

local function stepStones()
	if #stones == 0 then
		return
	end
	local now = workspace:GetServerTimeNow()
	local g = gravity()
	for i = #stones, 1, -1 do
		local stone = stones[i]
		local t = now - stone.Start
		local position = Breakables.positionAt(stone.From, stone.Velocity, g, t)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local ignore: { Instance } = { stone.Player.Character :: Instance }
		params.FilterDescendantsInstances = ignore
		local step = position - stone.Last
		local result = if step.Magnitude > 0.01 then workspace:Raycast(stone.Last, step, params) else nil
		-- Las zonas invisibles (habitaciones, marcas de las misiones…) no paran la piedra
		local tries = 0
		while result and tries < 4 and result.Instance.Transparency > 0.95 and not result.Instance.CanCollide do
			tries += 1
			table.insert(ignore, result.Instance)
			params.FilterDescendantsInstances = ignore
			result = workspace:Raycast(stone.Last, step, params)
		end
		if result then
			local velocity = stone.Velocity + Vector3.new(0, -g * t, 0)
			table.remove(stones, i)
			Remote:FireAllClients("Hit", stone.Id, result.Position)
			local ok, err = pcall(impact, stone, result, velocity)
			if not ok then
				warn("[BreakService] " .. tostring(err))
			end
			dropStone(result.Position, velocity)
		elseif t > MAX_FLIGHT then
			table.remove(stones, i)
			Remote:FireAllClients("Hit", stone.Id, position)
		else
			stone.Last = position
		end
	end
end

---------------------------------------------------------------------
-- Peticiones
---------------------------------------------------------------------

local function rootOf(player: Player): (BasePart?, Humanoid?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or humanoid.Health <= 0 then
		return nil, nil
	end
	return root, humanoid
end

local function canUse(player: Player): boolean
	local _, humanoid = rootOf(player)
	if not humanoid or humanoid.Sit then
		return false
	end
	if player:GetAttribute("LifeStage") == "Bebe" or player:GetAttribute("Crawling") or player:GetAttribute("Sleeping") or player:GetAttribute("Riding") then
		return false
	end
	return true
end

local function pick(player: Player)
	if os.clock() - (lastPick[player] or 0) < PICK_COOLDOWN or not canUse(player) then
		return
	end
	lastPick[player] = os.clock()
	local count = player:GetAttribute("Stones") or 0
	if count >= Breakables.MaxStones then
		Notify:FireClient(player, "Info", ("🥌 Ya llevas %d piedras."):format(count))
		return
	end
	local root = rootOf(player)
	if not root then
		return
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	local ground = workspace:Raycast(root.Position, Vector3.new(0, -10, 0), params)
	if not ground or not Breakables.canPickFrom(ground.Material) then
		Notify:FireClient(player, "Error", "🥌 Aquí no hay piedras: busca tierra, césped, arena o roca.")
		return
	end
	setStones(player, count + 1)
end

local function throw(player: Player, target: any)
	if typeof(target) ~= "Vector3" or target ~= target then
		return
	end
	if os.clock() - (lastThrow[player] or 0) < THROW_COOLDOWN or not canUse(player) then
		return
	end
	local count = player:GetAttribute("Stones") or 0
	if count <= 0 then
		return
	end
	local character = player.Character :: Model
	local head = character:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	local toTarget = target - head.Position
	if toTarget.Magnitude < 1 then
		return
	end
	if toTarget.Magnitude > MAX_RANGE then
		target = head.Position + toTarget.Unit * MAX_RANGE
	end
	lastThrow[player] = os.clock()
	setStones(player, count - 1)
	local from = head.Position + Vector3.new(0, 0.3, 0) + Vector3.new(toTarget.X, 0, toTarget.Z).Unit * 1.5
	local velocity = Breakables.launch(from, target, Breakables.ThrowSpeed, gravity())
	nextId += 1
	local stone: Stone = { Id = nextId, Player = player, From = from, Velocity = velocity, Start = workspace:GetServerTimeNow(), Last = from }
	table.insert(stones, stone)
	Remote:FireAllClients("Stone", stone.Id, from, velocity, stone.Start, gravity())
end

function BreakService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:WaitForChild("Vandal") :: RemoteEvent
	Notify = remotes:WaitForChild("Notify") :: RemoteEvent
	Remote.OnServerEvent:Connect(function(player, action, data)
		if action == "Pick" then
			pick(player)
		elseif action == "Throw" then
			throw(player, data)
		end
	end)
	Players.PlayerAdded:Connect(function(player)
		player:SetAttribute("Stones", 0)
		player.CharacterAdded:Connect(function()
			player:SetAttribute("Stones", 0) -- al reaparecer, sin piedras
		end)
	end)
	for _, player in Players:GetPlayers() do
		player:SetAttribute("Stones", 0)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastPick[player] = nil
		lastThrow[player] = nil
		lastAlert[player] = nil
		for i = #stones, 1, -1 do
			if stones[i].Player == player then
				table.remove(stones, i)
			end
		end
	end)
	task.spawn(function()
		for i, part in workspace:GetDescendants() do
			makeHittable(part)
			if i % 5000 == 0 then
				task.wait()
			end
		end
	end)
	RunService.Heartbeat:Connect(function()
		local ok, err = pcall(stepStones)
		if not ok then
			warn("[BreakService] " .. tostring(err))
		end
	end)
end

return BreakService
