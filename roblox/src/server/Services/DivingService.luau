-- DivingService: nadar, bucear y pesca submarina con fusil o arpón.
--
--   * Cualquiera puede nadar y bucear en el mar, el río y los lagos. Bajo el agua se gasta el aire
--     (atributos Oxygen y OxygenMax): 30 s sin nada, 60 s con gafas y tubo, 4 min con el equipo de
--     buceo y 8 min con el traje abisal (shared/Sea/Diving). Fuera del agua se recupera, y también en
--     las bolsas de aire de las cuevas (tag SeaAirPocket) y junto al barco de pesca. Sin aire, pierdes
--     vida hasta que subes a respirar.
--   * Presión (mar hondo, docs/mar/diseno.md): cada equipo llega hasta una profundidad (12, 25, 75 y
--     180 m). Pasado el límite, aviso claro, el aire se gasta el triple y luego la presión hace daño.
--     Atributos para el HUD: DiveDepth (m), DiveLimit (m), DivePressure ("Ok" | "Warn" | "Over").
--   * Si buceas con el fusil submarino (o el arpón), a tu alrededor nadan peces del agua en la que
--     estás (cerca del barco de pesca es alta mar). Son piezas con la etiqueta SwimFish.
--   * "Disparar": si le das, el pez pierde vida (los grandes aguantan varios disparos y huyen).
--     Cuando no le queda, va a la mochila, da experiencia y sale del banco de peces (FishingService).
--   * Cada pez pide nivel; los grandes, arpón; los del fondo, equipo de buceo (Fishing.spearMissing).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CollectionService = game:GetService("CollectionService")

local Fishing = require(ReplicatedStorage.Shared.Fishing)
local Swim = require(ReplicatedStorage.Shared.Swim)
local SeaDiving = require(ReplicatedStorage.Shared.Sea.Diving)
local Ocean = require(ReplicatedStorage.Shared.Sea.Ocean)
local MarFauna = require(ReplicatedStorage.Shared.Sea.MarFauna) -- (v125: el pez es su malla con textura, no un bloque)
local InventoryService = require(script.Parent.InventoryService)
local FishingService = require(script.Parent.FishingService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local DivingService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.Diving :: RemoteEvent
local DIVE = Fishing.Dive
local TAG = "SwimFish"

type Fish = { Part: BasePart, Owner: Player, Species: any, Water: string, Home: Vector3, Target: Vector3, Born: number, NextTurn: number, Speed: number }

local fishes: { [BasePart]: Fish } = {}
local lastShot: { [Player]: number } = {}
local drowning: { [Player]: boolean } = {}
local overFor: { [Player]: number } = {} -- segundos pasado el límite de profundidad
local warned: { [Player]: string } = {} -- el último aviso de presión
local under: { [Player]: boolean } = {}
local folder: Folder? = nil

local rng = {}
function rng.NextNumber(_self: any, min: number?, max: number?): number
	local lo, hi = min or 0, max or 1
	return lo + math.random() * (hi - lo)
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- ¿Tiene la cabeza bajo el agua? Se mira el centro del cuerpo (HumanoidRootPart), no la cabeza: al
-- nadar tumbado la cabeza baja a la altura de la cadera y parecía que buceabas (el aire bajaba y
-- subía nadando en la superficie). Con margen (Swim.isUnderwater) para que no cambie a cada segundo.
function DivingService.underwater(player: Player): boolean
	local root = rootOf(player)
	local character = player.Character
	if not root or not character then
		under[player] = nil
		return false
	end
	local was = under[player] == true
	local now = Swim.isUnderwater(root.Position.Y, character:GetScale(), was) and FishingService.isWater(root.Position)
	under[player] = now or nil
	return now
end

local function gearOf(player: Player): string?
	return SeaDiving.gearOf(function(id)
		return InventoryService.count(player, id) > 0
	end)
end

local function oxygenMax(player: Player): number
	return SeaDiving.info(gearOf(player)).Oxygen
end

-- ¿Respira aquí aunque esté bajo el agua? (bolsa de aire de una cueva o junto al barco de pesca)
local function inPocket(position: Vector3): boolean
	local ok, found = pcall(function()
		for _, pocket in CollectionService:GetTagged("SeaAirPocket") do
			if pocket:IsA("BasePart") and (pocket.Position - position).Magnitude < (pocket:GetAttribute("Radius") or 12) then
				return true
			end
		end
		if Ocean.meters(position.Y) < 8 then
			for _, deck in CollectionService:GetTagged("FishingBoatDeck") do
				if deck:IsA("BasePart") and (Vector2.new(deck.Position.X, deck.Position.Z) - Vector2.new(position.X, position.Z)).Magnitude < SeaDiving.BoatRadius then
					return true
				end
			end
		end
		return false
	end)
	return ok and found == true
end
DivingService.inPocket = inPocket

local function hasSpear(player: Player): boolean
	return InventoryService.count(player, "FusilSubmarino") > 0 or InventoryService.count(player, "Arpon") > 0
end

local function missing(player: Player, species: any): { string }
	return Fishing.spearMissing(species, FishingService.levelOf(player), FishingService.toolsOf(player))
end

---------------------------------------------------------------------
-- Aire
---------------------------------------------------------------------
local function breathe(player: Player)
	local gear = gearOf(player)
	local max = oxygenMax(player)
	local now = player:GetAttribute("Oxygen")
	if typeof(now) ~= "number" then
		now = max
	end
	local root = rootOf(player)
	local under = DivingService.underwater(player)
	local meters = if root and under then Ocean.meters(root.Position.Y) else 0
	local pocket = under and root ~= nil and inPocket(root.Position)
	local oxygen, damage, over = SeaDiving.tick({ Oxygen = math.min(now, max), Max = max, Under = under, Meters = meters, Gear = gear, Over = overFor[player], Pocket = pocket })
	overFor[player] = if over > 0 then over else nil
	if damage > 0 then
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = math.max(0, humanoid.Health - damage)
		end
	end
	if under and not pocket and oxygen <= 0 then
		if not drowning[player] then
			drowning[player] = true
			Notify:FireClient(player, "Error", "💨 ¡Te quedas sin aire! Sube a respirar.")
		end
	elseif not under or pocket then
		drowning[player] = nil
	end
	-- Presión: un aviso al acercarte al límite y otro (claro) al pasarte
	local pressure = if under then SeaDiving.pressure(meters, gear) else "Ok"
	if pressure ~= "Ok" and warned[player] ~= pressure then
		warned[player] = pressure
		if pressure == "Over" then
			Notify:FireClient(player, "Error", SeaDiving.overText(gear, meters))
		else
			Notify:FireClient(player, "Info", ("🫧 Estás cerca del límite de tu equipo (%d m)."):format(SeaDiving.info(gear).Depth))
		end
	elseif pressure == "Ok" then
		warned[player] = nil
	end
	if pocket and now < max * 0.95 and oxygen >= max * 0.95 then
		Notify:FireClient(player, "Success", "🫧 Aire recuperado.")
	end
	now = oxygen
	player:SetAttribute("DiveDepth", if under then math.floor(meters * 10 + 0.5) / 10 else nil)
	player:SetAttribute("DiveLimit", SeaDiving.info(gear).Depth)
	player:SetAttribute("DivePressure", if under then pressure else nil)
	-- Lo que lleva (para las animaciones y lo que ven los demás: SeaMotion y SeaFx)
	player:SetAttribute("Speargun", if InventoryService.count(player, "Arpon") > 0 then "Arpon" elseif InventoryService.count(player, "FusilSubmarino") > 0 then "FusilSubmarino" else nil)
	player:SetAttribute("DiveGear", gear)
	player:SetAttribute("OxygenMax", max)
	player:SetAttribute("Oxygen", math.min(now, max))
end

---------------------------------------------------------------------
-- Peces que nadan
---------------------------------------------------------------------
local RARITY_COLORS = Fishing.RarityColors

local function fishFolder(): Folder
	if not folder or not folder.Parent then
		local f = Instance.new("Folder")
		f.Name = "SwimFish"
		f.Parent = workspace
		folder = f
	end
	return folder :: Folder
end

-- Entre el fondo (el del mar hondo, shared/Sea/Ocean; en el río y los lagos, 11 studs) y la superficie
local function clampWater(p: Vector3): Vector3
	local floorY = Ocean.floorY(p.X, p.Z)
	local low = if floorY then math.min(floorY + 1.5, DIVE.Surface - 3) else DIVE.Surface - 11
	return Vector3.new(p.X, math.clamp(p.Y, low, DIVE.Surface - 1.5), p.Z)
end

function DivingService.spawn(owner: Player, species: any, position: Vector3, water: string): BasePart
	local kg = (species.Kg[1] + species.Kg[2]) / 2
	local len = math.clamp(0.8 + kg ^ 0.33 * 0.9, 0.8, 9)
	-- (v125, queja del dueño: «son cuadrados»: antes era un bloque del color de su rareza. Ahora la malla de
	-- un pez de MarFauna —con su textura— elegida por la especie; sin mallas, un pez de lado plano: el
	-- cuerpo es una elipse y lleva cola, que sigue siendo la pieza a la que se apunta)
	local meshes = { "PezCirujano", "PezLoro", "PezAngel", "PezBanco" }
	local pick = meshes[1 + (#tostring(species.Id) + string.byte(tostring(species.Id), 1)) % #meshes]
	local part: BasePart = MarFauna.clone(pick, len) or Instance.new("Part")
	part.Name = "SwimFish_" .. species.Id
	if not part:IsA("MeshPart") then
		part.Size = Vector3.new(len * 0.3, len * 0.5, len)
		part.Color = RARITY_COLORS[species.Rarity] or Color3.fromRGB(200, 210, 225)
		part.Material = Enum.Material.SmoothPlastic
		local body = Instance.new("SpecialMesh")
		body.MeshType = Enum.MeshType.Sphere
		body.Parent = part
		local tail = Instance.new("WedgePart")
		tail.Name = "Cola"
		tail.Size = Vector3.new(len * 0.06, len * 0.45, len * 0.3)
		tail.Color = part.Color:Lerp(Color3.new(0, 0, 0), 0.25)
		tail.Anchored = false
		tail.CanCollide = false
		tail.CanTouch = false
		tail.CanQuery = false
		tail.Massless = true
		tail.CFrame = part.CFrame * CFrame.new(0, 0, len * 0.6) * CFrame.Angles(0, math.pi, 0)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = part
		weld.Part1 = tail
		weld.Parent = tail
		tail.Parent = part
	end
	part:SetAttribute("Rarity", species.Rarity)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true
	part.CastShadow = false
	part.CFrame = CFrame.new(clampWater(position))
	local hp = math.max(1, species.Pulls - 1)
	part:SetAttribute("Species", species.Id)
	part:SetAttribute("Hp", hp)
	part:SetAttribute("MaxHp", hp)
	part:AddTag(TAG)
	part.Parent = fishFolder()
	fishes[part] = {
		Part = part,
		Owner = owner,
		Species = species,
		Water = water,
		Home = part.Position,
		Target = part.Position,
		Born = os.clock(),
		NextTurn = 0,
		Speed = 3,
	}
	return part
end

local function despawn(fish: Fish)
	fishes[fish.Part] = nil
	if fish.Part.Parent then
		fish.Part:Destroy()
	end
end

local function countOf(owner: Player): number
	local n = 0
	for _, f in fishes do
		if f.Owner == owner then
			n += 1
		end
	end
	return n
end

-- Pone peces alrededor de los buceadores con fusil
local function populate(player: Player)
	if not hasSpear(player) or not DivingService.underwater(player) or countOf(player) >= DIVE.MaxFish then
		return
	end
	local root = rootOf(player)
	if not root then
		return
	end
	local angle = rng:NextNumber(0, math.pi * 2)
	local dist = rng:NextNumber(10, 22)
	local at = root.Position + Vector3.new(math.cos(angle) * dist, rng:NextNumber(-4, 3), math.sin(angle) * dist)
	if not FishingService.isWater(at) then
		return
	end
	local water = FishingService.waterAt(at)
	local species = Fishing.pickSpear(water, rng :: any, FishingService.pop[water], function(s)
		return #missing(player, s) == 0
	end)
	if species then
		DivingService.spawn(player, species, at, water)
	end
end

local function swim(dt: number)
	local now = os.clock()
	for part, fish in fishes do
		local root = rootOf(fish.Owner)
		if not part.Parent or not fish.Owner.Parent or now - fish.Born > DIVE.FishLife or not root or (root.Position - part.Position).Magnitude > 80 then
			despawn(fish)
			continue
		end
		if now >= fish.NextTurn then
			fish.NextTurn = now + rng:NextNumber(2, 4)
			fish.Speed = math.max(3, fish.Speed * 0.7)
			fish.Target = clampWater(fish.Home + Vector3.new(rng:NextNumber(-8, 8), rng:NextNumber(-2, 2), rng:NextNumber(-8, 8)))
		end
		local delta = fish.Target - part.Position
		if delta.Magnitude > 0.2 then
			local step = delta.Unit * math.min(delta.Magnitude, fish.Speed * dt)
			local nextPos = part.Position + step
			if FishingService.isWater(nextPos) then
				part.CFrame = CFrame.lookAt(nextPos, nextPos + step)
			else
				fish.Target = fish.Home
			end
		end
	end
end

---------------------------------------------------------------------
-- Disparar
---------------------------------------------------------------------
local function onShoot(player: Player, part: any)
	if typeof(part) ~= "Instance" or not part:IsA("BasePart") then
		return
	end
	local fish = fishes[part :: BasePart]
	if not fish then
		return
	end
	if not hasSpear(player) then
		Notify:FireClient(player, "Info", "Necesitas un fusil submarino (tienda de pesca) para pescar buceando.")
		return
	end
	if not DivingService.underwater(player) then
		return
	end
	local now = os.clock()
	if now - (lastShot[player] or 0) < DIVE.ShotGap then
		return
	end
	lastShot[player] = now
	local okTime, serverTime = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	player:SetAttribute("SpearAt", if okTime and type(serverTime) == "number" then serverTime else os.clock())
	local root = rootOf(player)
	if not root or (root.Position - fish.Part.Position).Magnitude > DIVE.Range then
		Notify:FireClient(player, "Info", "Está demasiado lejos. Acércate más.")
		return
	end
	local species = fish.Species
	local need = missing(player, species)
	if #need > 0 then
		Notify:FireClient(player, "Info", ("🔒 %s %s: te falta %s."):format(species.Icon, species.Name, table.concat(need, ", ")))
		Remote:FireClient(player, "Miss", { Fish = fish.Part })
		return
	end
	local hp = (fish.Part:GetAttribute("Hp") or 1) - 1
	-- El arpón hace más daño a los grandes
	if InventoryService.count(player, "Arpon") > 0 and species.Rod < 4 then
		hp -= 1
	end
	fish.Part:SetAttribute("Hp", math.max(0, hp))
	if hp > 0 then
		-- Herido: huye
		local away = (fish.Part.Position - root.Position)
		away = if away.Magnitude > 0.1 then away.Unit else Vector3.new(1, 0, 0)
		fish.Target = clampWater(fish.Part.Position + away * 12)
		fish.Home = fish.Target
		fish.Speed = 9
		fish.NextTurn = now + 2
		Remote:FireClient(player, "Hit", { Fish = fish.Part, Hp = hp, Max = fish.Part:GetAttribute("MaxHp") })
		return
	end
	-- Cazado
	if not InventoryService.add(player, species.Item, 1) then
		Notify:FireClient(player, "Error", "🎒 ¡Mochila llena! Vende pescado antes de seguir.")
		return
	end
	despawn(fish)
	FishingService.consume(fish.Water, species)
	FishingService.addXp(player, species.Xp, species.Id)
	local kg = math.floor(rng:NextNumber(species.Kg[1], species.Kg[2]) * 100 + 0.5) / 100
	Remote:FireClient(player, "Caught", { Name = species.Name, Icon = species.Icon, Kg = kg, Xp = species.Xp, Rarity = species.Rarity, Price = species.Price })
	StoryEvents.emit(player, "CaughtFish", { Species = species.Id, Spear = true })
end

---------------------------------------------------------------------

function DivingService.init()
	Remote.OnServerEvent:Connect(function(player, action, a)
		if action == "Shoot" then
			onShoot(player, a)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastShot[player] = nil
		drowning[player] = nil
		overFor[player] = nil
		warned[player] = nil
		under[player] = nil
		for _, fish in fishes do
			if fish.Owner == player then
				despawn(fish)
			end
		end
	end)
	-- Aire y peces nuevos: cada segundo
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(function()
					breathe(player)
					populate(player)
				end)
				if not ok then
					warn("[DivingService] " .. tostring(err))
				end
			end
		end
	end)
	-- Los peces nadan
	task.spawn(function()
		while true do
			local dt = task.wait(0.2)
			local ok, err = pcall(swim, dt or 0.2)
			if not ok then
				warn("[DivingService] " .. tostring(err))
			end
		end
	end)
end

-- Para las pruebas
DivingService._fishes = fishes

return DivingService
