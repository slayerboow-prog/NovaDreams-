-- SeaEventService: catástrofes marinas (reglas en shared/SeaEvents.luau).
--
-- Cada 10-20 minutos (si hay alguien jugando) pasa una al azar. Las que más dañan (tsunami, temporal,
-- remolino) tienen un tiempo mínimo largo entre una y otra (MinGap: el tsunami, 2 horas). Se avisa a todos y, tras la cuenta
-- atrás, empieza el peligro. Aquí se decide todo lo que importa (daño, premios, pesca cerrada…);
-- lo que se ve (la ola, los rayos, el remolino, las aletas…) lo pinta cada jugador (SeaEventsUI).
--
-- Remote "SeaEvent" al cliente: "Start" (datos del suceso), "End" (texto), "Hit" (te ha pillado la
-- ola: empujón), "Strike" (cae un rayo en Pos), "Bite" (mordisco o picadura: sacudida).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeaEvents = require(ReplicatedStorage.Shared.SeaEvents)
local Fishing = require(ReplicatedStorage.Shared.Fishing)
local Format = require(ReplicatedStorage.Shared.Format)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local FishingService = require(script.Parent.FishingService)
local DivingService = require(script.Parent.DivingService)
local WeatherService = require(script.Parent.WeatherService)

local SeaEventService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.SeaEvent :: RemoteEvent
local KINDS = SeaEvents.Kinds
local TICK = 0.5

type Event = {
	Kind: any,
	Site: { [string]: any }?,
	Center: Vector3,
	Dir: Vector3,
	StartAt: number, -- (hora del servidor) empieza el peligro
	EndAt: number,
	Hit: { [Player]: boolean },
	Warned: { [Player]: boolean },
	Patches: { BasePart },
	Cleaners: { [Player]: boolean },
	Folder: Instance?,
	NextStrike: number,
	Shark: BasePart?,
	Hunter: Player?,
	HunterHad: number,
	Saved: { [string]: any },
}

local current: Event? = nil
-- Números al azar (con math.random: funciona igual en Roblox y en las pruebas)
local rng = {}
function rng.NextNumber(_self: any, min: number?, max: number?): number
	local lo, hi = min or 0, max or 1
	return lo + math.random() * (hi - lo)
end
function rng.NextInteger(_self: any, min: number, max: number): number
	return math.random(min, max)
end

local function now(): number
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	return if ok and type(t) == "number" then t else os.clock()
end

local function nameOf(player: Player): string
	return player.DisplayName or player.Name
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function hurt(player: Player, amount: number)
	local humanoid = humanoidOf(player)
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = math.max(0, humanoid.Health - amount)
	end
end

-- ¿Está en el agua? (el cuerpo bajo la superficie y agua debajo)
local function swimming(player: Player): boolean
	local root = rootOf(player)
	return root ~= nil and root.Position.Y < Fishing.Dive.Surface + 0.6 and FishingService.isWater(root.Position)
end

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function tellAll(kind: string, text: string)
	for _, player in Players:GetPlayers() do
		Notify:FireClient(player, kind, text)
	end
end

local function deck(): BasePart?
	for _, part in CollectionService:GetTagged("FishingBoatDeck") do
		if part:IsA("BasePart") then
			return part
		end
	end
	return nil
end

-- ¿Tiene techo encima? (dentro de un edificio la ola no te arrastra)
local function sheltered(player: Player): boolean
	local character = player.Character
	local head = character and character:FindFirstChild("Head") :: BasePart?
	if not head then
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character :: Instance }
	local ok, hit = pcall(function()
		return workspace:Raycast(head.Position, Vector3.new(0, 60, 0), params)
	end)
	return ok and hit ~= nil and hit.Instance ~= workspace.Terrain
end

---------------------------------------------------------------------
-- Marea negra: manchas que se limpian
---------------------------------------------------------------------
local finish: (text: string, kind: string?) -> ()

local function cleanPatch(player: Player, patch: BasePart)
	local e = current
	if not e or e.Kind.Id ~= "MareaNegra" or not patch.Parent then
		return
	end
	local i = table.find(e.Patches, patch)
	if not i then
		return
	end
	table.remove(e.Patches, i)
	patch:Destroy()
	e.Cleaners[player] = true
	DataService.addMoney(player, e.Kind.Reward, true)
	Notify:FireClient(player, "Money", ("+%s · 🛢️ ¡Mancha de petróleo limpia! Quedan %d"):format(Format.money(e.Kind.Reward), #e.Patches))
	workspace:SetAttribute("SeaEventLeft", #e.Patches)
	if #e.Patches == 0 then
		for cleaner in e.Cleaners do
			if cleaner.Parent then
				DataService.addMoney(cleaner, e.Kind.Bonus, true)
				Notify:FireClient(cleaner, "Money", ("+%s · ¡Premio por limpiar la marea negra!"):format(Format.money(e.Kind.Bonus)))
			end
		end
		finish("🛢️ ¡Habéis limpiado toda la marea negra! Los peces vuelven a la costa.", "Success")
	end
end

local function spillOil(e: Event)
	local folder = Instance.new("Folder")
	folder.Name = "MareaNegra"
	folder.Parent = workspace
	e.Folder = folder
	local out = -e.Dir -- hacia el mar
	local side = Vector3.new(-out.Z, 0, out.X)
	local tries = 0
	while #e.Patches < e.Kind.Patches and tries < 80 do
		tries += 1
		local at = e.Center + out * rng:NextNumber(15, e.Kind.Radius) + side * rng:NextNumber(-e.Kind.Radius, e.Kind.Radius)
		if FishingService.isWater(Vector3.new(at.X, Fishing.Dive.Surface - 1, at.Z)) then
			local patch = Instance.new("Part")
			patch.Name = "ManchaPetroleo"
			patch.Anchored = true
			patch.CanCollide = false
			patch.CanTouch = false
			patch.CanQuery = false
			patch.CastShadow = false
			patch.Size = Vector3.new(rng:NextNumber(14, 22), 0.25, rng:NextNumber(14, 22))
			patch.CFrame = CFrame.new(at.X, Fishing.Dive.Surface + 0.12, at.Z) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0)
			patch.Color = Color3.fromRGB(14, 14, 18)
			patch.Material = Enum.Material.SmoothPlastic
			patch.Reflectance = 0.25
			patch:AddTag("OilPatch")
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Limpiar"
			prompt.ObjectText = "🛢️ Mancha de petróleo"
			prompt.HoldDuration = 2.5
			prompt.MaxActivationDistance = 16
			prompt.RequiresLineOfSight = false
			prompt.Parent = patch
			prompt.Triggered:Connect(function(player)
				cleanPatch(player, patch)
			end)
			patch.Parent = folder
			table.insert(e.Patches, patch)
		end
	end
	workspace:SetAttribute("SeaEventLeft", #e.Patches)
end

---------------------------------------------------------------------
-- Empezar y acabar
---------------------------------------------------------------------

function finish(text: string, kind: string?)
	local e = current
	if not e then
		return
	end
	current = nil
	if e.Folder then
		e.Folder:Destroy()
	end
	if e.Shark and e.Shark.Parent then
		e.Shark:Destroy()
	end
	if e.Kind.Id == "Temporal" then
		WeatherService.force(nil)
		pcall(function()
			if e.Saved.WaveSize then
				workspace.Terrain.WaterWaveSize = e.Saved.WaveSize
				workspace.Terrain.WaterWaveSpeed = e.Saved.WaveSpeed
			end
		end)
	end
	for _, name in { "SeaEvent", "SeaEventAt", "SeaEventEnd", "SeaEventPos", "SeaEventDir", "SeaEventSite", "SeaEventLeft" } do
		workspace:SetAttribute(name, nil)
	end
	tellAll(kind or "Info", text)
	Remote:FireAllClients("End", { Text = text })
end

-- Cuándo salió cada tipo por última vez (al arrancar el servidor cuenta como "ahora": así un
-- tsunami no sale nada más entrar, sino como pronto al cabo de su MinGap)
local lastAt: { [string]: number } = {}
local bootAt = os.clock()

-- ¿Puede volver a salir este tipo? (ha pasado su MinGap)
function SeaEventService.ready(id: string): boolean
	local kind = KINDS[id]
	if not kind then
		return false
	end
	return os.clock() - (lastAt[id] or bootAt) >= (kind.MinGap or 0)
end

-- Empieza una catástrofe (kind: id de SeaEvents.Kinds; siteName opcional). Devuelve si ha empezado.
function SeaEventService.start(kindId: string, siteName: string?): boolean
	local kind = KINDS[kindId]
	if not kind or current then
		return false
	end
	local site = nil
	local center, dir
	if kindId == "Temporal" or kindId == "Remolino" then
		local d = deck()
		local base = if d then d.Position else Vector3.new(4700, 0, -1000)
		center = Vector3.new(base.X, Fishing.Dive.Surface, base.Z)
		if kindId == "Remolino" then
			for _ = 1, 20 do
				local a = rng:NextNumber(0, math.pi * 2)
				local at = center + Vector3.new(math.cos(a), 0, math.sin(a)) * rng:NextNumber(60, 110)
				if FishingService.isWater(Vector3.new(at.X, Fishing.Dive.Surface - 1, at.Z)) then
					center = at
					break
				end
			end
		end
		dir = Vector3.new(-1, 0, 0)
	else
		site = if siteName then SeaEvents.site(siteName) else nil
		site = site or SeaEvents.Sites[rng:NextInteger(1, #SeaEvents.Sites)]
		center = Vector3.new(site.X, Fishing.Dive.Surface, site.Z)
		dir = Vector3.new(site.Dir[1], 0, site.Dir[2])
	end
	local t = now()
	local e: Event = {
		Kind = kind,
		Site = site,
		Center = center,
		Dir = dir,
		StartAt = t + kind.Warning,
		EndAt = t + kind.Warning + kind.Duration,
		Hit = {},
		Warned = {},
		Patches = {},
		Cleaners = {},
		Folder = nil,
		NextStrike = 0,
		Shark = nil,
		Hunter = nil,
		HunterHad = 0,
		Saved = {},
	}
	current = e
	lastAt[kind.Id] = os.clock()
	workspace:SetAttribute("SeaEvent", kind.Id)
	workspace:SetAttribute("SeaEventAt", e.StartAt)
	workspace:SetAttribute("SeaEventEnd", e.EndAt)
	workspace:SetAttribute("SeaEventPos", center)
	workspace:SetAttribute("SeaEventDir", dir)
	workspace:SetAttribute("SeaEventSite", if site then site.Name else "alta mar")
	if kindId == "Temporal" then
		WeatherService.force("Tormenta")
		pcall(function()
			local terrain = workspace.Terrain
			e.Saved.WaveSize = terrain.WaterWaveSize
			e.Saved.WaveSpeed = terrain.WaterWaveSpeed
			terrain.WaterWaveSize = 0.6
			terrain.WaterWaveSpeed = 30
		end)
	elseif kindId == "MareaNegra" then
		spillOil(e)
	end
	local where = if site then site.Name else "alta mar"
	tellAll("Error", ("%s ¡ALERTA: %s en %s! %s."):format(kind.Icon, string.upper(kind.Name), where, kind.Tip))
	Remote:FireAllClients("Start", { Kind = kind.Id, Site = where })
	return true
end

---------------------------------------------------------------------
-- Cada medio segundo
---------------------------------------------------------------------

local function warnOnce(e: Event, player: Player, text: string)
	if not e.Warned[player] then
		e.Warned[player] = true
		Notify:FireClient(player, "Error", text)
	end
end

local function tick()
	local e = current
	if not e then
		return
	end
	local t = now()
	if t >= e.EndAt then
		local endings = {
			Tsunami = "🌊 El agua se ha retirado. Ya ha pasado el tsunami.",
			Temporal = "⛈️ El temporal ha pasado. Vuelve la calma al mar.",
			Remolino = "🌀 El remolino se ha deshecho.",
			MareaNegra = "🛢️ La marea negra se ha dispersado mar adentro.",
			Tiburon = "🦈 El tiburón se ha ido mar adentro. Ya se puede volver al agua.",
			Medusas = "🪼 Las medusas se han ido con la corriente.",
		}
		finish(endings[e.Kind.Id] or "El mar vuelve a la calma.")
		return
	end
	if t < e.StartAt then
		return -- aún en el aviso
	end
	local kind = e.Kind
	local id = kind.Id
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if not root then
			continue
		end
		local pos = root.Position
		if id == "Tsunami" and not e.Hit[player] and e.Site then
			local inPath, along = SeaEvents.inWavePath(e.Site, pos)
			local front = SeaEvents.waveFront(e.StartAt, t)
			if inPath and front >= along - 4 and front <= along + 45 and front <= kind.Inland + 20 then
				if pos.Y < kind.SafeHeight and not sheltered(player) then
					e.Hit[player] = true
					hurt(player, kind.Damage)
					Remote:FireClient(player, "Hit", { Dir = e.Dir })
					Notify:FireClient(player, "Error", "🌊 ¡Te ha arrastrado la ola del tsunami!")
				end
			end
		elseif id == "Remolino" then
			if swimming(player) and flatDistance(pos, e.Center) < kind.CoreRadius then
				hurt(player, kind.Damage * TICK)
				warnOnce(e, player, "🌀 ¡El remolino te arrastra al fondo! ¡Nada hacia fuera!")
			end
		elseif id == "MareaNegra" then
			if swimming(player) then
				for _, patch in e.Patches do
					if flatDistance(pos, patch.Position) < math.max(patch.Size.X, patch.Size.Z) * 0.6 then
						hurt(player, kind.Damage * TICK)
						warnOnce(e, player, "🛢️ ¡Estás nadando en petróleo! Sal de la mancha.")
						break
					end
				end
			end
		elseif id == "Tiburon" then
			if swimming(player) and flatDistance(pos, e.Center) < kind.Radius and rng:NextNumber() < kind.BiteChance * TICK / 1.5 then
				hurt(player, kind.Damage)
				Remote:FireClient(player, "Bite", { Kind = "Tiburon" })
				Notify:FireClient(player, "Error", "🦈 ¡Te ha mordido el tiburón! ¡Sal del agua!")
			end
		elseif id == "Medusas" then
			local protected = InventoryService.count(player, "Botella") > 0
			if not protected and swimming(player) and flatDistance(pos, e.Center) < kind.Radius and rng:NextNumber() < kind.StingChance * TICK / 2 then
				hurt(player, kind.Damage)
				Remote:FireClient(player, "Bite", { Kind = "Medusas" })
				Notify:FireClient(player, "Error", "🪼 ¡Te ha picado una medusa! ¡Qué escozor!")
			end
		end
	end
	-- Rayos del temporal
	if id == "Temporal" and t >= e.NextStrike then
		e.NextStrike = t + kind.StrikeEvery
		local near = {}
		for _, player in Players:GetPlayers() do
			local root = rootOf(player)
			if root and flatDistance(root.Position, e.Center) < kind.Radius then
				table.insert(near, root)
			end
		end
		local target
		if #near > 0 then
			local root = near[rng:NextInteger(1, #near)]
			local a = rng:NextNumber(0, math.pi * 2)
			target = Vector3.new(root.Position.X, Fishing.Dive.Surface, root.Position.Z) + Vector3.new(math.cos(a), 0, math.sin(a)) * rng:NextNumber(3, 18)
		else
			local a = rng:NextNumber(0, math.pi * 2)
			target = e.Center + Vector3.new(math.cos(a), 0, math.sin(a)) * rng:NextNumber(20, kind.Radius)
		end
		Remote:FireAllClients("Strike", { Pos = target })
		for _, player in Players:GetPlayers() do
			local root = rootOf(player)
			if root and flatDistance(root.Position, target) < kind.StrikeRange then
				hurt(player, kind.StrikeDamage)
				Notify:FireClient(player, "Error", "⚡ ¡Te ha caído un rayo cerca! ¡Resguárdate!")
			end
		end
	end
	-- El tiburón de la playa se puede cazar buceando con arpón
	if id == "Tiburon" then
		if e.Shark and not e.Shark.Parent then
			local hunter = e.Hunter
			if hunter and hunter.Parent and InventoryService.count(hunter, "Pez_TiburonAzul") > e.HunterHad then
				DataService.addMoney(hunter, 150, true)
				Notify:FireClient(hunter, "Money", "+150 € · ¡Recompensa por cazar al tiburón de la playa!")
				finish(("🦈 ¡%s ha cazado al tiburón de la playa! Ya se puede volver al agua."):format(nameOf(hunter)), "Success")
				return
			end
			e.Shark = nil
		end
		if not e.Shark then
			for _, player in Players:GetPlayers() do
				local root = rootOf(player)
				if root and InventoryService.count(player, "Arpon") > 0 and DivingService.underwater(player) and flatDistance(root.Position, e.Center) < kind.Radius then
					local at = root.Position + Vector3.new(rng:NextNumber(-10, 10), 0, rng:NextNumber(-10, 10))
					e.Shark = DivingService.spawn(player, Fishing.byId.TiburonAzul, at, "Mar")
					e.Hunter = player
					e.HunterHad = InventoryService.count(player, "Pez_TiburonAzul")
					Notify:FireClient(player, "Info", "🦈 ¡Ahí está el tiburón de la playa! Cázalo con el arpón.")
					break
				end
			end
		end
	end
end

---------------------------------------------------------------------

function SeaEventService.current(): string?
	return if current then current.Kind.Id else nil
end

function SeaEventService.stop()
	finish("El mar vuelve a la calma.")
end

function SeaEventService.init()
	Players.PlayerRemoving:Connect(function(player)
		local e = current
		if e then
			e.Hit[player] = nil
			e.Warned[player] = nil
			e.Cleaners[player] = nil
			if e.Hunter == player then
				e.Hunter = nil
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(TICK)
			local ok, err = pcall(tick)
			if not ok then
				warn("[SeaEventService] " .. tostring(err))
			end
		end
	end)
	-- De vez en cuando, una catástrofe al azar
	task.spawn(function()
		while true do
			task.wait(rng:NextNumber(SeaEvents.Every[1], SeaEvents.Every[2]))
			if not current and #Players:GetPlayers() > 0 then
				local id = SeaEvents.pick(rng:NextNumber(), SeaEventService.ready)
				if id then
					pcall(SeaEventService.start, id)
				end
			end
		end
	end)
end

-- Para las pruebas
SeaEventService._tick = tick
SeaEventService._event = function()
	return current
end

return SeaEventService
