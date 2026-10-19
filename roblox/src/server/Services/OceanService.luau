-- OceanService: explorar el mar hondo de Valmar (docs/mar/diseno.md). Todo lo decide el servidor.
--
--   * Recursos del fondo: conchas, perlas, muestras de coral, muestras bioluminiscentes y doblones,
--     repartidos por zonas (OceanBiomes.Zones[z].Loot) en sitios fijos (workspace.Mar.Recursos). Se
--     cogen con «Recoger» (ProximityPrompt) y se comprueba: que estás cerca y bajo el agua, que el
--     recurso sigue ahí, el ritmo (no más de 30 por minuto), la presión de tu equipo y que te quepa en
--     la mochila (shared/Sea/Diving.pickupProblem). Vuelven a salir al rato. Se venden en la lonja.
--   * Cofres (tag SeaChest, World/OceanBuilder): «Abrir cofre» una vez al día por persona y cofre:
--     dinero, doblones y perlas (Diving.Chests).
--   * Sitios (POI, shared/Sea/Ocean.Pois): al acercarte buceando se descubren y se guardan
--     (data.Sea.Found). Cinco salen en el mapa como «Punto de buceo».
--   * Misiones del mar (Diving.Missions): explorar el arrecife, recolectar, encontrar el pecio,
--     fotografiar al megalodón y llegar a la guarida del Kraken. Recompensa al terminar (data.Sea.Done).
--   * Atributos para el HUD (Controllers/DiveHud): SeaFound («ArcoCoral,Pecio»), SeaMission (id de la
--     misión que toca) y SeaMissionProgress («1/2»).
-- Remote «Sea»: el servidor avisa «Found», «Mission» y «Loot»; el cliente pide «Photo» (SeaBeastService
-- comprueba la foto y llama a OceanService.photo).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ocean = require(ReplicatedStorage.Shared.Sea.Ocean)
local OceanBiomes = require(ReplicatedStorage.Shared.Sea.OceanBiomes)
local SeaDiving = require(ReplicatedStorage.Shared.Sea.Diving)
local Format = require(ReplicatedStorage.Shared.Format)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local DivingService = require(script.Parent.DivingService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local OceanService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local function remote(): RemoteEvent?
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	return remotes and remotes:FindFirstChild("Sea") :: RemoteEvent?
end

local rgb = Color3.fromRGB
local V = Vector3.new

type Node = { Id: number, Loot: string, Zone: string, Position: Vector3, Part: BasePart?, Prompt: ProximityPrompt?, Active: boolean, BackAt: number }
local nodes: { Node } = {}
local picks: { [Player]: { number } } = {} -- cuándo recogió (para el ritmo)
local poiPositions: { [string]: Vector3 } = {}
OceanService._nodes = nodes

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function seaData(player: Player): { [string]: any }?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	if type(data.Sea) ~= "table" then
		data.Sea = {}
	end
	local sea = data.Sea
	for _, key in { "Found", "Done", "Chests", "Photos", "Loot" } do
		if type(sea[key]) ~= "table" then
			sea[key] = {}
		end
	end
	return sea
end

local function fire(player: Player, kind: string, payload: any)
	local r = remote()
	if r then
		r:FireClient(player, kind, payload)
	end
end

local function gearOf(player: Player): string?
	return SeaDiving.gearOf(function(id)
		return InventoryService.count(player, id) > 0
	end)
end

---------------------------------------------------------------------
-- Atributos para el HUD y misiones
---------------------------------------------------------------------
local function publish(player: Player)
	local sea = seaData(player)
	if not sea then
		return
	end
	local found = {}
	for _, poi in Ocean.Pois do
		if sea.Found[poi.Id] then
			table.insert(found, poi.Id)
		end
	end
	player:SetAttribute("SeaFound", table.concat(found, ","))
	local mission = SeaDiving.current(sea)
	player:SetAttribute("SeaMission", if mission then mission.Id else nil)
	if mission then
		local done, total = SeaDiving.progress(mission, sea)
		player:SetAttribute("SeaMissionProgress", ("%d/%d"):format(done, total))
	else
		player:SetAttribute("SeaMissionProgress", nil)
	end
end

local function checkMissions(player: Player)
	local sea = seaData(player)
	if not sea then
		return
	end
	for _, m in SeaDiving.Missions do
		if not sea.Done[m.Id] then
			local done, total = SeaDiving.progress(m, sea)
			if total > 0 and done >= total then
				sea.Done[m.Id] = true
				DataService.addMoney(player, m.Reward, true)
				Notify:FireClient(player, "Success", ("🌊 Misión del mar: «%s» · +%s"):format(m.Title, Format.money(m.Reward)))
				fire(player, "Mission", { Id = m.Id, Title = m.Title, Reward = m.Reward })
				StoryEvents.emit(player, "SeaMission", { Mission = m.Id })
			end
		end
	end
	publish(player)
end
OceanService.checkMissions = checkMissions

---------------------------------------------------------------------
-- Sitios (descubrir)
---------------------------------------------------------------------
function OceanService.discover(player: Player, poiId: string): boolean
	local poi = Ocean.PoiById[poiId]
	local sea = seaData(player)
	if not poi or not sea or sea.Found[poiId] then
		return false
	end
	sea.Found[poiId] = true
	DataService.addMoney(player, 25, true)
	Notify:FireClient(player, "Success", ("📍 Has descubierto: %s · +%s"):format(poi.Name, Format.money(25)))
	fire(player, "Found", { Id = poiId, Name = poi.Name })
	StoryEvents.emit(player, "SeaDiscover", { Poi = poiId })
	checkMissions(player)
	return true
end

local function discoverTick()
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root and root.Position.Y < Ocean.Surface - 1 then
			local sea = seaData(player)
			if sea then
				for _, poi in Ocean.Pois do
					if not sea.Found[poi.Id] then
						local at = poiPositions[poi.Id]
						if at and (at - root.Position).Magnitude < poi.Radius then
							OceanService.discover(player, poi.Id)
						end
					end
				end
			end
		end
	end
end
OceanService._discoverTick = discoverTick

---------------------------------------------------------------------
-- Recursos del fondo
---------------------------------------------------------------------
local function lootFolder(): Folder
	local mar = workspace:FindFirstChild("Mar")
	if not mar then
		mar = Instance.new("Folder")
		mar.Name = "Mar"
		mar.Parent = workspace
	end
	local f = mar:FindFirstChild("Recursos")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Recursos"
		f.Parent = mar
	end
	return f :: Folder
end

-- Dónde van los recursos de cada zona (siempre los mismos sitios)
OceanService.Quota = { Orilla = 14, Arrecife = 30, Kelp = 20, Llanura = 24, Talud = 20, Garganta = 12, Catedrales = 16, Abismo = 18, Sima = 12 }
local function candidate(zone: string, i: number): (number, number)
	local h1, h2, h3 = Ocean.hash(i, 1, 61), Ocean.hash(i, 2, 61), Ocean.hash(i, 3, 61)
	local function inDisk(list)
		local d = list[1 + math.floor(h1 * #list) % #list]
		local a, r = h2 * math.pi * 2, math.sqrt(h3) * d.R
		return d.X + math.cos(a) * r, d.Z + math.sin(a) * r
	end
	local function onLine(line, spread)
		local pts = line.Points
		local seg = 1 + math.floor(h1 * (#pts - 1)) % (#pts - 1)
		local a, b = pts[seg], pts[seg + 1]
		local x, z = a[1] + (b[1] - a[1]) * h2, a[2] + (b[2] - a[2]) * h2
		local dx, dz = b[1] - a[1], b[2] - a[2]
		local len = math.sqrt(dx * dx + dz * dz)
		local off = (h3 - 0.5) * 2 * spread
		return x - dz / len * off, z + dx / len * off
	end
	if zone == "Arrecife" then
		return inDisk(Ocean.Reefs)
	elseif zone == "Kelp" then
		return inDisk(Ocean.Kelp)
	elseif zone == "Garganta" then
		return onLine(Ocean.Canyon, Ocean.Canyon.HalfWidth)
	elseif zone == "Sima" then
		return onLine(Ocean.Trench, Ocean.Trench.HalfWidth)
	elseif zone == "Catedrales" then
		return onLine(Ocean.Cathedrals, Ocean.Cathedrals.HalfWidth)
	elseif zone == "Abismo" then
		local b = Ocean.Basin
		local a, r = h2 * math.pi * 2, math.sqrt(h3) * b.Core
		return b.X + math.cos(a) * r * b.RX, b.Z + math.sin(a) * r * b.RZ
	end
	local area = Ocean.Area
	return area.MinX + h1 * (area.MaxX - area.MinX), area.MinZ + h2 * (area.MaxZ - area.MinZ)
end

-- Los sitios de los recursos (puro: lo prueba test-mar)
function OceanService.plan(): { { Loot: string, Zone: string, Position: Vector3 } }
	local list = {}
	local world = OceanBiomes.world()
	for _, zone in world.ZoneOrder do
		local want = OceanService.Quota[zone] or 0
		local got, i = 0, 0
		while got < want and i < want * 60 do
			i += 1
			local x, z = candidate(zone, i + #zone * 1000)
			local s = Ocean.sample(x, z)
			if s.Floor and s.Zone == zone then
				local loot = SeaDiving.pickLoot(world.Zones[zone].Loot, Ocean.hash(x, z, 62))
				if loot then
					got += 1
					table.insert(list, { Loot = loot, Zone = zone, Position = V(x, s.Floor + 0.4, z) })
				end
			end
		end
	end
	return list
end

local function nodeLook(node: Node): BasePart
	local def = SeaDiving.Loot[node.Loot]
	local p = Instance.new("Part")
	p.Name = "Recurso_" .. node.Loot
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CastShadow = false
	p.Color = def.Color
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if node.Loot == "Concha" then
		p.Shape = Enum.PartType.Ball
		p.Size = V(1.2, 0.5, 1)
		p.Material = Enum.Material.SmoothPlastic
	elseif node.Loot == "Perla" then
		-- una ostra entreabierta con la perla
		p.Size = V(1.6, 0.4, 1.3)
		p.Color = rgb(120, 110, 100)
		p.Material = Enum.Material.Slate
		local pearl = Instance.new("Part")
		pearl.Name = "Perla"
		pearl.Shape = Enum.PartType.Ball
		pearl.Size = V(0.6, 0.6, 0.6)
		pearl.Anchored = true
		pearl.CanCollide = false
		pearl.CanQuery = false
		pearl.Color = def.Color
		pearl.Material = Enum.Material.Glass
		pearl.CFrame = CFrame.new(node.Position + V(0, 0.4, 0))
		pearl.Parent = p
	elseif node.Loot == "Coral" then
		p.Size = V(0.5, 1.6, 0.5)
		p.Material = Enum.Material.Pebble
	elseif node.Loot == "Bio" then
		p.Shape = Enum.PartType.Ball
		p.Size = V(0.9, 0.9, 0.9)
		p.Material = Enum.Material.Neon
	else
		p.Shape = Enum.PartType.Cylinder
		p.Size = V(0.2, 1, 1)
		p.Material = Enum.Material.Metal
	end
	p.CFrame = CFrame.new(node.Position) * (if node.Loot == "Doblon" then CFrame.Angles(0, 0, math.rad(80)) else CFrame.new())
	-- Un brillo suave para encontrarlos (Neon pequeño encima)
	local glint = Instance.new("Attachment")
	glint.Parent = p
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Rate = 1.5
	sparkle.Lifetime = NumberRange.new(1, 1.6)
	sparkle.Speed = NumberRange.new(0.2, 0.6)
	sparkle.Size = NumberSequence.new(0.25)
	sparkle.Color = ColorSequence.new(def.Color)
	sparkle.LightEmission = 1
	sparkle.Parent = glint
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Recoger"
	prompt.ObjectText = def.Icon .. " " .. def.Name
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = p
	node.Prompt = prompt
	p:SetAttribute("SeaLoot", node.Loot)
	p.Parent = lootFolder()
	return p
end

local function setActive(node: Node, on: boolean)
	node.Active = on
	local part = node.Part
	if part then
		part.Transparency = if on then 0 else 1
		for _, d in part:GetDescendants() do
			if d:IsA("BasePart") then
				d.Transparency = if on then 0 else 1
			elseif d:IsA("ParticleEmitter") then
				d.Enabled = on
			end
		end
	end
	if node.Prompt then
		node.Prompt.Enabled = on
	end
end

function OceanService.collect(player: Player, node: Node): (boolean, string?)
	local root = rootOf(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local now = os.clock()
	local list = picks[player] or {}
	picks[player] = list
	for i = #list, 1, -1 do
		if now - list[i] > 60 then
			table.remove(list, i)
		end
	end
	local problem = SeaDiving.pickupProblem({
		Alive = humanoid ~= nil and humanoid.Health > 0,
		Active = node.Active,
		Distance = if root then (root.Position - node.Position).Magnitude else math.huge,
		Underwater = DivingService.underwater(player),
		SinceLast = if #list > 0 then now - list[#list] else math.huge,
		LastMinute = #list,
		Meters = if root then Ocean.meters(root.Position.Y) else 0,
		Gear = gearOf(player),
	})
	if problem then
		if problem == "lejos" then
			Notify:FireClient(player, "Info", "Acércate más para recogerlo.")
		elseif problem == "fuera del agua" then
			Notify:FireClient(player, "Info", "Bucea hasta él para recogerlo.")
		elseif problem == "presión" then
			Notify:FireClient(player, "Error", SeaDiving.overText(gearOf(player), if root then Ocean.meters(root.Position.Y) else 0))
		end
		return false, problem
	end
	local def = SeaDiving.Loot[node.Loot]
	if not InventoryService.add(player, def.Item, 1) then
		Notify:FireClient(player, "Error", "🎒 ¡Mochila llena! Vende algo en la lonja de la pescadería.")
		return false, "mochila"
	end
	table.insert(list, now)
	setActive(node, false)
	node.BackAt = now + SeaDiving.Pickup.Respawn
	local sea = seaData(player)
	if sea then
		sea.Loot[node.Loot] = (sea.Loot[node.Loot] or 0) + 1
	end
	fire(player, "Loot", { Id = node.Loot, Name = def.Name, Icon = def.Icon, Price = def.Price })
	Notify:FireClient(player, "Money", ("%s %s a la mochila (la lonja lo paga a %s)"):format(def.Icon, def.Name, Format.money(def.Price)))
	StoryEvents.emit(player, "SeaLoot", { Loot = node.Loot })
	checkMissions(player)
	return true, nil
end

local function respawnTick()
	local now = os.clock()
	for _, node in nodes do
		if not node.Active and now >= node.BackAt then
			setActive(node, true)
		end
	end
end

---------------------------------------------------------------------
-- Cofres
---------------------------------------------------------------------
function OceanService.openChest(player: Player, part: BasePart): (boolean, string?)
	local id = part:GetAttribute("ChestId")
	local def = type(id) == "string" and SeaDiving.Chests[id]
	local root = rootOf(player)
	local sea = seaData(player)
	if not def or not root or not sea then
		return false, "nada"
	end
	if (root.Position - part.Position).Magnitude > SeaDiving.ChestRange + 4 then
		return false, "lejos"
	end
	if not DivingService.underwater(player) then
		return false, "fuera del agua"
	end
	local ready, left = SeaDiving.chestReady(sea.Chests[id], os.time())
	if not ready then
		Notify:FireClient(player, "Info", ("🧰 Este cofre ya lo has abierto. Vuelve en %d h."):format(math.ceil(left / 3600)))
		return false, "pronto"
	end
	sea.Chests[id] = os.time()
	DataService.addMoney(player, def.Money, true)
	local got = { Format.money(def.Money) }
	for lootId, n in def.Loot do
		local loot = SeaDiving.Loot[lootId]
		if loot and InventoryService.add(player, loot.Item, n) then
			table.insert(got, ("%d %s %s"):format(n, loot.Icon, string.lower(loot.Name)))
		end
	end
	Notify:FireClient(player, "Money", "🧰 ¡Tesoro! " .. table.concat(got, " · "))
	StoryEvents.emit(player, "SeaChest", { Chest = id })
	checkMissions(player)
	return true, nil
end

local function setupChest(part: Instance)
	if not part:IsA("BasePart") or part:FindFirstChild("ChestPrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ChestPrompt"
	prompt.ActionText = "Abrir cofre"
	prompt.ObjectText = "🧰 Tesoro"
	prompt.HoldDuration = 0.8
	prompt.MaxActivationDistance = SeaDiving.ChestRange
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	prompt.Triggered:Connect(function(player)
		OceanService.openChest(player, part :: BasePart)
	end)
end

---------------------------------------------------------------------
-- Fotos (las comprueba SeaBeastService: que la criatura esté cerca y delante)
---------------------------------------------------------------------
function OceanService.photo(player: Player, beastId: string): boolean
	local sea = seaData(player)
	if not sea then
		return false
	end
	local first = not sea.Photos[beastId]
	sea.Photos[beastId] = true
	if first then
		Notify:FireClient(player, "Success", ("📷 ¡Foto del %s! Va a tu álbum."):format(if beastId == "Kraken" then "Kraken" else "megalodón"))
	end
	checkMissions(player)
	return first
end

---------------------------------------------------------------------
-- El mapa: puntos de buceo
---------------------------------------------------------------------
local LANDMARKS = { "ArcoCoral", "Pecio", "Ruinas", "JardinLuz", "ValmarHundida" }
local function publishLandmarks()
	local folder = ReplicatedStorage:FindFirstChild("MapLandmarks")
	if not folder then
		return
	end
	for _, id in LANDMARKS do
		local poi = Ocean.PoiById[id]
		if poi and not folder:FindFirstChild("PuntoBuceo_" .. id) then
			local config = Instance.new("Configuration")
			config.Name = "PuntoBuceo_" .. id
			config:SetAttribute("Kind", "PuntoBuceo")
			config:SetAttribute("Position", V(poi.X, 0, poi.Z))
			config:SetAttribute("District", "")
			config.Parent = folder
		end
	end
end

---------------------------------------------------------------------

function OceanService.init()
	for _, poi in Ocean.Pois do
		poiPositions[poi.Id] = Ocean.poiPosition(poi)
	end
	-- Recursos
	for i, spec in OceanService.plan() do
		local node: Node = { Id = i, Loot = spec.Loot, Zone = spec.Zone, Position = spec.Position, Active = true, BackAt = 0 }
		node.Part = nodeLook(node)
		local prompt = node.Prompt
		if prompt then
			prompt.Triggered:Connect(function(player)
				OceanService.collect(player, node)
			end)
		end
		table.insert(nodes, node)
	end
	-- Cofres
	for _, part in CollectionService:GetTagged("SeaChest") do
		setupChest(part)
	end
	CollectionService:GetInstanceAddedSignal("SeaChest"):Connect(setupChest)
	-- Datos y atributos
	Players.PlayerAdded:Connect(function(player)
		task.delay(3, function()
			if player.Parent then
				publish(player)
			end
		end)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(publish, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		picks[player] = nil
	end)
	task.delay(5, function()
		pcall(publishLandmarks)
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			local ok, err = pcall(function()
				discoverTick()
				respawnTick()
			end)
			if not ok then
				warn("[OceanService] " .. tostring(err))
			end
		end
	end)
end

return OceanService
