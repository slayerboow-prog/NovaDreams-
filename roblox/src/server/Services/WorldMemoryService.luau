-- WorldMemoryService: la MEMORIA DEL MUNDO de cada jugador y los DECORADOS POR FASE.
--
--   * Lo que queda en el mundo por tu historia (un cráter, una nave aparcada, un objeto que se quedó, un
--     personaje que ahora vive en algún sitio) se guarda con la partida en data.Story.World
--     (shared/LifeStory/WorldState: claves "Cielo.Crater.Parque" = "Humeante"…). Lo escriben las
--     escenas (pista World de HappeningService) y las misiones (efecto World = { … } de LifeStoryService);
--     lo leen las condiciones (World / NotWorld en Conditions) y los decorados.
--   * Réplica: el atributo WorldState del jugador (JSON) con toda su memoria del mundo.
--   * Decorados (shared/LifeStory/StageSets): aquí se decide qué decorado toca a cada jugador y en qué
--     estado (al entrar, al cambiar su memoria y cada pocos segundos por si acabó una misión) y se
--     publica en su atributo StageSets (JSON: { [id] = { S = estado, P = {x,y,z}, R = giro } }).
--     Los de un solo jugador los dibuja SU cliente (Controllers/StageSetsClient); los de todos se
--     construyen aquí una vez (workspace.StageSets, una carpeta por estado) y cada cliente enseña la
--     variante de su historia.
-- Así, al volver a entrar, las consecuencias siguen ahí.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldState = require(ReplicatedStorage.Shared.LifeStory.WorldState)
local StageSets = require(ReplicatedStorage.Shared.LifeStory.StageSets)

local WorldMemoryService = {}

local REFRESH_EVERY = 4 -- segundos entre repasos de los decorados (por si acabó una misión)

-- (inyectables en las pruebas)
WorldMemoryService.Defs = StageSets.Defs
local dataServiceOverride: any = nil
local locate: ((Player, { [string]: any }) -> CFrame?)? = nil

local listeners: { (Player, string, any) -> () } = {}
local placements: { [Player]: { [string]: CFrame | false } } = {}
local lastSets: { [Player]: string } = {}
local lastWorld: { [Player]: string } = {}

local function DataService(): any
	return dataServiceOverride or require(script.Parent.DataService)
end

local function encode(value: any): string
	local ok, text = pcall(function()
		return HttpService:JSONEncode(value)
	end)
	return if ok then text else "{}"
end

-- La memoria del mundo del jugador (la crea vacía si su partida es de antes)
local function worldOf(player: Player): { [string]: any }?
	local data = DataService().get(player)
	if not data then
		return nil
	end
	data.Story = data.Story or {}
	if type(data.Story.World) ~= "table" then
		data.Story.World = {}
	end
	return data.Story.World
end

-- Contexto para las condiciones de los decorados (lo de la historia; la hora no cuenta)
local function contextOf(player: Player): { [string]: any }?
	local data = DataService().get(player)
	if not data then
		return nil
	end
	local story = data.Story or {}
	local rel = {}
	for npc, entry in story.NpcMemory or {} do
		if type(entry) == "table" then
			rel[npc] = entry.Rel or 0
		end
	end
	return {
		Stage = (data.Life and data.Life.Stage) or "Adulto",
		ClockTime = 12,
		Weekday = 1,
		Completed = story.Completed or {},
		Flags = story.Flags or {},
		Choices = story.Choices or {},
		Discovered = story.Discovered or {},
		Memories = story.Memories or {},
		Traits = story.Traits or {},
		Rel = rel,
		World = worldOf(player) or {},
		Active = story.Active or {},
	}
end
WorldMemoryService.contextOf = contextOf

---------------------------------------------------------------------
-- Leer y escribir
---------------------------------------------------------------------

function WorldMemoryService.get(player: Player, key: string): any
	local world = worldOf(player)
	return world and world[key]
end

function WorldMemoryService.snapshot(player: Player): { [string]: any }
	return WorldState.copy(worldOf(player))
end

-- Alguien quiere enterarse de los cambios (player, clave, valor nuevo)
function WorldMemoryService.onChanged(fn: (Player, string, any) -> ())
	table.insert(listeners, fn)
end

-- Cambia varias claves a la vez ({ [clave] = valor }; false borra). Devuelve cuántas han cambiado.
function WorldMemoryService.apply(player: Player, changes: { [string]: any }?): number
	local world = worldOf(player)
	if not world or type(changes) ~= "table" then
		return 0
	end
	local changed = {}
	for key, value in changes do
		if WorldState.set(world, key, value) then
			table.insert(changed, key)
		end
	end
	if #changed > 0 then
		for _, key in changed do
			for _, fn in listeners do
				task.spawn(fn, player, key, world[key])
			end
		end
		WorldMemoryService.publish(player)
	end
	return #changed
end

function WorldMemoryService.set(player: Player, key: string, value: any): boolean
	return WorldMemoryService.apply(player, { [key] = value }) > 0
end

---------------------------------------------------------------------
-- Decorados
---------------------------------------------------------------------

-- Dónde va un decorado de jugador (se calcula una vez por sesión: los lugares no se mueven)
local function placementOf(player: Player, id: string, def: { [string]: any }): CFrame?
	local cache = placements[player]
	if not cache then
		cache = {}
		placements[player] = cache
	end
	local known = cache[id]
	if known ~= nil then
		return known or nil
	end
	local cf: CFrame? = nil
	if def.Position then
		cf = CFrame.new(def.Position)
	elseif locate then
		cf = locate(player, def)
	else
		local ok, spot = pcall(function()
			local LocationService = require(script.Parent.LocationService)
			return LocationService.resolve(player, def.Place, { Offset = def.Offset })
		end)
		if ok and spot then
			local position = spot.Position
			-- Apoyado en el suelo (un rayo hacia abajo que no cuenta a las personas ni a las escenas)
			pcall(function()
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				local skip = {}
				local scenes = workspace:FindFirstChild("StoryScenes")
				if scenes then
					table.insert(skip, scenes)
				end
				for _, other in Players:GetPlayers() do
					if other.Character then
						table.insert(skip, other.Character)
					end
				end
				params.FilterDescendantsInstances = skip
				local hit = workspace:Raycast(position + Vector3.new(0, 8, 0), Vector3.new(0, -40, 0), params)
				if hit then
					position = hit.Position
				end
			end)
			cf = CFrame.new(position) * spot.CFrame.Rotation
		end
	end
	if cf then
		cache[id] = cf
	end
	return cf
end

-- Los decorados del jugador (estado y sitio) tal y como se publican
function WorldMemoryService.setsFor(player: Player): { [string]: any }
	local ctx = contextOf(player)
	local out = {}
	if not ctx then
		return out
	end
	for id, def in WorldMemoryService.Defs do
		local ok, state = pcall(StageSets.stateFor, def, ctx)
		if ok and state then
			if def.Scope == "Global" then
				out[id] = { S = state }
			else
				local cf = placementOf(player, id, def)
				if cf then
					local _, yaw = cf:ToOrientation()
					local p = cf.Position
					out[id] = { S = state, P = { math.floor(p.X * 100) / 100, math.floor(p.Y * 100) / 100, math.floor(p.Z * 100) / 100 }, R = math.floor(math.deg(yaw) + 0.5) }
				end
			end
		end
	end
	return out
end

-- Manda al cliente su memoria del mundo y sus decorados (solo si ha cambiado algo)
function WorldMemoryService.publish(player: Player)
	if not player.Parent then
		return
	end
	local world = worldOf(player)
	if not world then
		return
	end
	local worldJson = encode(world)
	if lastWorld[player] ~= worldJson then
		lastWorld[player] = worldJson
		player:SetAttribute("WorldState", worldJson)
	end
	local setsJson = encode(WorldMemoryService.setsFor(player))
	if lastSets[player] ~= setsJson then
		lastSets[player] = setsJson
		player:SetAttribute("StageSets", setsJson)
	end
end

-- Los decorados de todos: se construyen una vez, con una carpeta por estado (el cliente enseña una)
function WorldMemoryService.buildGlobal(parent: Instance?)
	local StageBuilders = require(ReplicatedStorage.Shared.StageBuilders)
	local root = parent or workspace:FindFirstChild("StageSets")
	if not root then
		root = Instance.new("Folder")
		root.Name = "StageSets"
		root.Parent = workspace
	end
	for id, def in WorldMemoryService.Defs do
		if def.Scope == "Global" and def.Position and not root:FindFirstChild(id) then
			local holder = Instance.new("Folder")
			holder.Name = id
			for state in def.States or {} do
				local variant = Instance.new("Folder")
				variant.Name = state
				local ok, err = pcall(StageBuilders.build, def.Builder, variant, CFrame.new(def.Position), StageSets.paramsFor(def, state), "High")
				if not ok then
					warn(("[WorldMemory] No se pudo construir %s/%s: %s"):format(id, state, tostring(err)))
				end
				variant.Parent = holder
			end
			holder.Parent = root
		end
	end
	return root
end

---------------------------------------------------------------------
-- Pruebas: dobles de DataService y del lugar de cada decorado
---------------------------------------------------------------------
function WorldMemoryService._inject(data: any, locator: ((Player, { [string]: any }) -> CFrame?)?)
	dataServiceOverride = data
	locate = locator
end

function WorldMemoryService.forget(player: Player)
	placements[player] = nil
	lastSets[player] = nil
	lastWorld[player] = nil
end

function WorldMemoryService.init()
	local ds = DataService()
	ds.onLoaded(function(player)
		task.defer(WorldMemoryService.publish, player)
	end)
	Players.PlayerRemoving:Connect(WorldMemoryService.forget)
	pcall(WorldMemoryService.buildGlobal)
	task.spawn(function()
		while true do
			task.wait(REFRESH_EVERY)
			for _, player in Players:GetPlayers() do
				pcall(WorldMemoryService.publish, player)
			end
		end
	end)
end

return WorldMemoryService
