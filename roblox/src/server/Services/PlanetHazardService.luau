-- PlanetHazardService (servidor): la DESVENTAJA de cada planeta con su medidor (marco común de los
-- planetas, docs/planetas/marco-planetas.md; diseño docs/planetas/diseno-mundos.md §2.7). Tefra lleva la
-- suya a mano (Services/TefraService: calor y bombardeos); este servicio lleva la de los DEMÁS planetas
-- del registro (shared/Cosmos/PlanetRegistry) que tengan S.Hazard (shared/Cosmos/PlanetHazard).
--
--   * Cada TickSeconds, a cada jugador A PIE en su planeta: el planeta dice qué le rodea
--     (S.hazardContext(pos, info) → { Near, Zone, Exposed }) y aquí se añade lo de siempre: el refugio
--     (S.City.shelterAt: Cool), el equipo de la mochila (Hazard.gearFactor), el consumible activo y la
--     ayuda de las primeras horas (data.Story.Counters["<Planeta>Segundos"]).
--   * Atributos del jugador (los pinta Controllers/PlanetHazardHud): Peligro (0..Max), PeligroFase
--     ("Normal" | "Aviso" | "Peligro"), PeligroId (Toxinas, Sed…) y HeatSlow (lo que te frena al andar:
--     NeedsService, el mismo que el calor de Tefra). PlanetaModo = el momento del planeta (S.moment:
--     tormenta, marea…), para el sonido (EnvDirector → Soundscapes Modes).
--   * En Peligro pierdes vida poco a poco (nunca de golpe); lleno un rato o con poca vida, te «Derriba» y
--     despiertas dentro del refugio más cercano (o en la plataforma), con el medidor a AfterKnock y SIN
--     perder nada. Nada de esto pasa en mitad de una escena o una conversación.
--   * La contramedida se usa desde la mochila (InventoryService.onUse del Consumable de cada planeta).
--   * La historia lo oye: HazardChanged { Planet, Hazard, Phase }, HazardSurvived { Hazard } (al volver a
--     Normal tras un aviso) y HazardCountered { Planet, Hazard, Item } (al usar la contramedida).
-- API: valueOf(player) · counter(player, itemId) · knockDown(player, why) · _tick(dt) · _reset()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local GameClock = require(Shared.GameClock)
local PlanetRegistry = require(Shared.Cosmos.PlanetRegistry)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local PlanetHazardService = {}

PlanetHazardService.Tick = 0.5

type State = { Planet: string, Value: number, Phase: string, Full: number, BoostUntil: number, WasBad: boolean, Slow: number, Mode: string? }
local states: { [Player]: State } = {}
local notify: RemoteEvent? = nil

PlanetHazardService.Clock = os.clock
local function now(): number
	return PlanetHazardService.Clock()
end

local function service(name: string): any
	return require(script.Parent[name])
end

local function toast(player: Player, kind: string, text: string)
	if notify and player.Parent then
		notify:FireClient(player, kind, text)
	end
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function dataOf(player: Player): { [string]: any }?
	local ok, data = pcall(function()
		return service("DataService").get(player)
	end)
	return if ok then data else nil
end

local function busy(player: Player): boolean
	return player:GetAttribute("InScene") == true or player:GetAttribute("InDialogue") == true or player:GetAttribute("InCinematic") == true
end

-- El planeta (con desventaja genérica) donde está a pie: (id, superficie) o nil
function PlanetHazardService.planetOf(player: Player): (string?, any)
	local id = player:GetAttribute("Planeta")
	if type(id) ~= "string" or id == "Tefra" then
		return nil, nil
	end
	local S = PlanetRegistry.get(id)
	if not S or not S.Hazard then
		return nil, nil
	end
	local root = rootOf(player)
	if not root or not S.inRegion(root.Position) then
		return nil, nil
	end
	local ok, world = pcall(function()
		return service("AirCombatService").world(player)
	end)
	if ok and world ~= nil then
		return nil, nil
	end
	return id, S
end

-- El contexto del medidor para un jugador (lo que lee Hazard.rate)
function PlanetHazardService.context(S: any, player: Player?, position: Vector3, data: { [string]: any }?, st: State?): { [string]: any }
	local H = S.Hazard
	local clock = GameClock.hour()
	local info = { Clock = clock, Day = clock >= 9 and clock < 19, Items = data and data.Items, Player = player }
	local ctx: { [string]: any } = if S.hazardContext then S.hazardContext(position, info) else {}
	local lx, lz = S.toLocal(position)
	local City = S.City
	if City and City.shelterAt then
		local _, shelter = City.shelterAt(lx, lz)
		if shelter and position.Y - (S.Origin.Y + S.padY()) < 14 then
			ctx.Shelter = shelter.Cool
		end
	end
	ctx.Gear = H.gearFactor(data and data.Items)
	ctx.Boost = st ~= nil and st.BoostUntil > now()
	local counters = data and data.Story and data.Story.Counters
	ctx.Newbie = (tonumber(counters and counters[S.Id .. "Segundos"]) or 0) < H.NewbieSeconds
	return ctx
end

local function setSlow(player: Player, st: State, factor: number)
	if math.abs(st.Slow - factor) < 1e-3 then
		return
	end
	st.Slow = factor
	player:SetAttribute("HeatSlow", if factor < 1 then factor else nil)
	pcall(function()
		service("NeedsService").refreshSpeed(player)
	end)
end

local function clear(player: Player)
	local st = states[player]
	if st then
		setSlow(player, st, 1)
	end
	states[player] = nil
	if player.Parent then
		player:SetAttribute("Peligro", nil)
		player:SetAttribute("PeligroFase", nil)
		player:SetAttribute("PeligroId", nil)
		player:SetAttribute("PlanetaModo", nil)
	end
end

-- Te derriba la desventaja: despiertas en el refugio más cercano (o en la plataforma), sin perder nada
function PlanetHazardService.knockDown(player: Player, why: string)
	local id = player:GetAttribute("Planeta")
	local S = PlanetRegistry.get(if type(id) == "string" then id else nil)
	local root = rootOf(player)
	if not S or not root then
		return
	end
	local lx, lz = S.toLocal(root.Position)
	local City = S.City
	local tx, tz, name = 0, 30, "la plataforma"
	if City and City.nearestShelter then
		local _, _, sid = City.nearestShelter(lx, lz)
		if sid then
			tx, tz = City.shelterInside(sid)
			local sh = City.Shelters[sid]
			name = sh and sh.Name or name
		end
	end
	local target = S.toWorld(tx, tz, S.Origin.Y + S.padY() + 3)
	local humanoid = humanoidOf(player)
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = math.max(humanoid.Health, humanoid.MaxHealth * 0.5)
	end
	local ok = pcall(function()
		service("SceneService").teleportTo(player, target, { Dip = true })
	end)
	if not ok then
		root.CFrame = CFrame.new(target)
	end
	toast(player, "Info", ("%s Despiertas en %s. No has perdido nada."):format(why, name))
end

local function stepPlayer(player: Player, dt: number)
	local id, S = PlanetHazardService.planetOf(player)
	if not id then
		if states[player] then
			clear(player)
		end
		return
	end
	local H = S.Hazard
	local root = rootOf(player) :: BasePart
	local data = dataOf(player)
	local st = states[player]
	if not st or st.Planet ~= id then
		st = { Planet = id :: string, Value = 0, Phase = "Normal", Full = 0, BoostUntil = 0, WasBad = false, Slow = 1 }
		states[player] = st
	end
	local s = st :: State
	-- (el tiempo en el planeta: la ayuda de las primeras horas)
	if data and type(data.Story) == "table" then
		data.Story.Counters = if type(data.Story.Counters) == "table" then data.Story.Counters else {}
		local key = S.Id .. "Segundos"
		data.Story.Counters[key] = (tonumber(data.Story.Counters[key]) or 0) + dt
	end
	local ctx = PlanetHazardService.context(S, player, root.Position, data, s)
	s.Value = H.step(s.Value, ctx, dt)
	s.Full = if s.Value >= H.Max then s.Full + dt else 0
	local phase = H.phase(s.Value)
	if phase ~= s.Phase then
		local before = s.Phase
		s.Phase = phase
		StoryEvents.emit(player, "HazardChanged", { Planet = id, Hazard = H.Id, Phase = phase, From = before })
		if phase == "Normal" and s.WasBad then
			s.WasBad = false
			StoryEvents.emit(player, "HazardSurvived", { Hazard = H.Id, Planet = id })
		end
		if phase ~= "Normal" then
			s.WasBad = true
			if not busy(player) then
				local lines = S.HazardToasts or {}
				toast(player, if phase == "Peligro" then "Error" else "Info", lines[phase] or H.label(s.Value))
			end
		end
	end
	setSlow(player, s, H.slow(phase))
	player:SetAttribute("Peligro", math.floor(s.Value + 0.5))
	player:SetAttribute("PeligroFase", phase)
	player:SetAttribute("PeligroId", H.Id)
	-- El momento del planeta (tormenta de arena, marea de niebla…): para el sonido
	local mode = if S.moment then S.moment(GameClock.hour(), root.Position) else nil
	if mode ~= s.Mode then
		s.Mode = mode
		player:SetAttribute("PlanetaModo", mode)
	end
	if phase == "Peligro" and not busy(player) then
		local humanoid = humanoidOf(player)
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = math.max(H.KnockHealth - 1, humanoid.Health - H.DangerDamage * dt)
			if H.knocked(s.Value, s.Full, humanoid.Health) then
				s.Value = H.AfterKnock
				s.Full = 0
				PlanetHazardService.knockDown(player, S.KnockText or ("💫 %s te ha derribado."):format(H.Name))
			end
		end
	end
end

-- La contramedida (desde la mochila: InventoryService.onUse)
function PlanetHazardService.counter(player: Player, itemId: string): boolean
	local id = player:GetAttribute("Planeta")
	local S = PlanetRegistry.get(if type(id) == "string" then id else nil)
	local H = S and S.Hazard
	local C = H and H.Consumable
	local Inventory = service("InventoryService")
	if Inventory.count(player, itemId) <= 0 then
		return false
	end
	if not C or C.Item ~= itemId then
		toast(player, "Info", "Esto solo sirve en su planeta. Guárdalo.")
		return false
	end
	Inventory.remove(player, itemId, 1)
	local st = states[player]
	if not st then
		st = { Planet = id :: string, Value = 0, Phase = "Normal", Full = 0, BoostUntil = 0, WasBad = false, Slow = 1 }
		states[player] = st
	end
	local s = st :: State
	s.Value = math.max(0, s.Value - C.Drop)
	s.BoostUntil = now() + C.Seconds
	player:SetAttribute("Peligro", math.floor(s.Value + 0.5))
	toast(player, "Success", S.CounterText or ("%s %s: baja de golpe y durante un rato casi no sube"):format(H.Icon, H.Name))
	StoryEvents.emit(player, "HazardCountered", { Planet = id, Hazard = H.Id, Item = itemId })
	return true
end

function PlanetHazardService.valueOf(player: Player): number
	local st = states[player]
	return st and st.Value or 0
end

function PlanetHazardService._tick(dt: number)
	for _, p in Players:GetPlayers() do
		local ok, err = pcall(stepPlayer, p, dt)
		if not ok then
			warn("[PlanetHazardService] " .. tostring(err))
		end
	end
end
PlanetHazardService._states = states
function PlanetHazardService._reset()
	for p in table.clone(states) do
		clear(p)
	end
end

function PlanetHazardService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	notify = remotes:FindFirstChild("Notify") :: RemoteEvent?
	-- Las contramedidas de cada planeta se usan desde la mochila
	for _, id in PlanetRegistry.ids() do
		local S = PlanetRegistry.get(id)
		local C = S and S.Hazard and S.Hazard.Consumable
		if C and id ~= "Tefra" then
			pcall(function()
				service("InventoryService").onUse(C.Item, function(player: Player)
					return PlanetHazardService.counter(player, C.Item)
				end)
			end)
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(PlanetHazardService.Tick)
			PlanetHazardService._tick(PlanetHazardService.Tick)
		end
	end)
end

return PlanetHazardService
