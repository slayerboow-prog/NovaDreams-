-- GalaxyMapService (servidor): los datos DE VERDAD del jugador para el MAPA GALÁCTICO
-- (Controllers/GalaxyMapUI, cuentas en shared/Cosmos/GalaxyMap; docs/espacio-aaa/mapa-galactico.md).
--
--   * Remoto "GalaxyMap" (cliente → servidor): "Get" → (servidor → cliente) "Snapshot" con:
--       SagaDone, Tester, CanFly, Planets = { [id] = { Status, Need, Text, Done, Visited, Missions } },
--       Found (puntos descubiertos), SideMissions (tablón de las estaciones), Chispas, Cargo, CargoMax,
--       Crystals, Invasion (texto si la Invasión de la Grieta está en marcha).
--     Con un mínimo de tiempo entre dos peticiones (MinGap). No cambia nada de la partida.
--   * Visitas: cuando el jugador llega a un planeta (atributo "Planeta", lo pone Services/PlanetService) se
--     apunta en data.Space.Visited[id] = os.time() (se guarda con la partida, como todo data.Space).
--   * Misiones por planeta: los episodios de la Saga 2 pueden decir cuántas misiones activas tiene el
--     jugador en su planeta con GalaxyMapService.setPlanetMissions(id, fn(player) -> número).
-- Nada de aquí mueve al jugador: viajar va por los caminos de siempre (salto cuántico, VALMAR, la nave).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cosmos = ReplicatedStorage.Shared.Cosmos
local Planets = require(Cosmos.Planets)
local Access = require(Cosmos.Access)
local NavInfo = require(Cosmos.NavInfo)
local Mining = require(Cosmos.Mining)

local GalaxyMapService = {}

GalaxyMapService.MinGap = 0.5

local remote: RemoteEvent? = nil
local lastAsk: { [Player]: number } = {}
local missionSources: { [string]: (Player) -> number } = {}

local function service(name: string): any
	return require((script.Parent :: any)[name])
end

-- Los episodios de la Saga 2: cuántas misiones activas hay en su planeta para este jugador
function GalaxyMapService.setPlanetMissions(id: string, fn: ((Player) -> number)?)
	local canonical = Planets.canonical(id) or id
	missionSources[canonical] = fn
end

-- Apunta que ha estado en un planeta (data.Space.Visited)
function GalaxyMapService.markVisited(player: Player, id: any): boolean
	if type(id) ~= "string" then
		return false
	end
	id = Planets.canonical(id) :: string
	if not Planets.ById[id] then
		return false
	end
	local ok, sp = pcall(function()
		return service("SpaceService").spaceData(player)
	end)
	if not ok or type(sp) ~= "table" then
		return false
	end
	if type(sp.Visited) ~= "table" then
		sp.Visited = {}
	end
	if not sp.Visited[id] then
		sp.Visited[id] = os.time()
	end
	return true
end

-- Lo que manda el servidor al mapa (todo de la partida del jugador)
function GalaxyMapService.snapshot(player: Player): { [string]: any }
	local Space = service("SpaceService")
	local data = nil
	pcall(function()
		data = service("DataService").get(player)
	end)
	local sp = nil
	pcall(function()
		sp = Space.spaceData(player)
	end)
	local tester = false
	pcall(function()
		tester = service("TesterService").isTester(player) == true
	end)
	local sagaDone = Access.sagaDone(data)
	local canFly = Access.canFly({ SagaDone = sagaDone, Tester = tester })
	local planets = {}
	local done = (sp and type(sp.Planets) == "table") and sp.Planets or {}
	local visited = (sp and type(sp.Visited) == "table") and sp.Visited or {}
	local pistas = (sp and type(sp.Pistas) == "table") and sp.Pistas or {}
	for _, p in Planets.List do
		local status, need = "Locked", nil
		pcall(function()
			status, need = Space.planetStatus(player, p.Id)
		end)
		local missions = 0
		local src = missionSources[p.Id]
		if src then
			local okM, n = pcall(src, player)
			if okM and type(n) == "number" then
				missions = math.max(0, math.floor(n))
			end
		end
		-- (Tefra: quien ya encontró pistas en su superficie estuvo allí antes de que se apuntaran las visitas)
		local wasThere = visited[p.Id] ~= nil or (p.Id == "Tefra" and next(pistas) ~= nil)
		planets[p.Id] = {
			Status = status,
			Need = need,
			Text = if status ~= "Ready" then Planets.message(p.Id, status, need) else nil,
			Done = done[p.Id] ~= nil and done[p.Id] ~= false,
			Visited = wasThere,
			Missions = missions,
		}
	end
	local side = {}
	if sp then
		for _, m in NavInfo.missionTargets(sp.Missions) do
			table.insert(side, { Id = m.Id, Title = m.Title, Progress = m.Progress, Done = m.Done, Count = m.Count, TargetName = m.TargetName })
		end
	end
	local invasion: string? = nil
	pcall(function()
		local Inv = service("InvasionService")
		if Inv.active and Inv.active() then
			invasion = (Inv.shipEventText and Inv.shipEventText(player)) or "Invasión de la Grieta en Valmar"
		end
	end)
	local found = {}
	if sp and type(sp.Found) == "table" then
		for id, v in sp.Found do
			if v then
				found[id] = true
			end
		end
	end
	local ore = (sp and type(sp.Ore) == "table") and sp.Ore or {}
	return {
		SagaDone = sagaDone,
		Tester = tester,
		CanFly = canFly,
		Planets = planets,
		Found = found,
		SideMissions = side,
		Chispas = if sp then math.floor(tonumber(sp.Chispas) or 0) else 0,
		Cargo = Mining.cargo(ore),
		CargoMax = Mining.CargoMax,
		Crystals = math.floor(tonumber(ore.Cristal) or 0),
		Invasion = invasion,
	}
end

local function onRemote(player: Player, action: any)
	if action ~= "Get" then
		return
	end
	local t = os.clock()
	if t - (lastAsk[player] or -math.huge) < GalaxyMapService.MinGap then
		return
	end
	lastAsk[player] = t
	local ok, snap = pcall(GalaxyMapService.snapshot, player)
	if ok and remote then
		remote:FireClient(player, "Snapshot", snap)
	elseif not ok then
		warn("[GalaxyMap] " .. tostring(snap))
	end
end

local function watch(player: Player)
	local function check()
		local id = player:GetAttribute("Planeta")
		if id ~= nil then
			GalaxyMapService.markVisited(player, id)
		end
	end
	player:GetAttributeChangedSignal("Planeta"):Connect(check)
	check()
end

function GalaxyMapService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local existing = remotes:FindFirstChild("GalaxyMap") :: RemoteEvent?
	if not existing then
		local created = Instance.new("RemoteEvent")
		created.Name = "GalaxyMap"
		created.Parent = remotes
		existing = created
	end
	remote = existing
	;(existing :: RemoteEvent).OnServerEvent:Connect(function(player, action)
		local ok, err = pcall(onRemote, player, action)
		if not ok then
			warn("[GalaxyMap] " .. tostring(err))
		end
	end)
	Players.PlayerAdded:Connect(watch)
	for _, p in Players:GetPlayers() do
		watch(p)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastAsk[player] = nil
	end)
end

-- (pruebas)
GalaxyMapService._onRemote = onRemote

return GalaxyMapService
