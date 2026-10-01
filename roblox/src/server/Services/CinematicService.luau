-- CinematicService: prepara y lanza las escenas de cámara de la historia (shared/LifeStory/Cinematics.luau).
-- Para cada jugador busca sus anclas (SU casa, SU ventanal, la zona…), pide al mapa que cargue esas
-- zonas (el mapa se carga por trozos, StreamingEnabled) y, cuando están (o tras un tope corto),
-- manda la escena al cliente, que la dibuja.
-- Devuelve lo que dura la escena, para que la historia siga cuando termine.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cinematics = require(ReplicatedStorage.Shared.LifeStory.Cinematics)
local Family = require(ReplicatedStorage.Shared.LifeStory.Family)
local LocationService = require(script.Parent.LocationService)
local SceneService = require(script.Parent.SceneService)

local CinematicService = {}

local function rootCFrame(player: Player): CFrame?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root and root.CFrame
end

-- Anclas de la escena para este jugador. Si alguna no existe en el mapa, se usa el propio jugador,
-- así la escena se ve igualmente (nunca se queda la cámara en el vacío).
function CinematicService.resolveAnchors(player: Player, cinematic: { [string]: any }): { [string]: CFrame }
	local fallback = rootCFrame(player) or CFrame.new()
	local anchors = {}
	for name, anchor in cinematic.Anchors or {} do
		local cf: CFrame? = nil
		if anchor == "Player" then
			cf = rootCFrame(player)
		else
			local kind, value = anchor:match("^(%a+):(.+)$")
			if kind == "Place" then
				local spot = LocationService.resolve(player, value)
				cf = spot and spot.CFrame
			elseif kind == "Zone" then
				local center = LocationService.zoneCenter(value)
				cf = center and CFrame.new(center)
			elseif kind == "Actor" then
				-- Un personaje de la escena del jugador (para primeros planos)
				local model = SceneService.actorOf(player, value)
				if model then
					local ok, pivot = pcall(function()
						return model:GetPivot()
					end)
					cf = if ok then pivot else nil
				end
			end
		end
		if not cf and anchor ~= "Player" and not anchor:match("^Actor:") then
			warn(("[CinematicService] Ancla '%s' (%s) no encontrada; se usa el jugador"):format(name, anchor))
		end
		anchors[name] = cf or fallback
	end
	return anchors
end

-- Cuánto se espera como mucho a que el mapa cargue las anclas antes de empezar la escena
local STREAM_WAIT = 2.5

-- Lanza la escena y devuelve cuánto dura (0 si no existe).
-- Primero pide al mapa que cargue lo que va a enseñar la cámara (todas las anclas a la vez, con un
-- tope de STREAM_WAIT s) y después la manda al cliente: así la cámara no enseña el vacío. No hace
-- esperar a quien llama (la historia sigue su curso); lo que devuelve incluye esa espera.
function CinematicService.play(player: Player, id: string): number
	local cinematic = Cinematics[id]
	if not cinematic then
		-- ¿Es una ESCENA del motor (planos + efectos + actores + consecuencias)? La dirige HappeningService,
		-- que avisa con clientDone al acabar (shared/LifeStory/HappeningIndex)
		local ok, HappeningService = pcall(function()
			return require(script.Parent.HappeningService)
		end)
		if ok and HappeningService.has(id) then
			return HappeningService.play(player, id)
		end
	end
	local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("LifeStory")
	if not cinematic or not remote then
		warn("[CinematicService] No se puede reproducir", id)
		return 0
	end
	local anchors = CinematicService.resolveAnchors(player, cinematic)
	-- Tu familia (siempre una pareja que existe: Papá y Abu Rosa, o Mamá y Abu Tomás)
	local life = nil
	pcall(function()
		local data = require(script.Parent.DataService).get(player)
		life = data and data.Life
	end)
	local familyKey, abuKey = Family.keysOf(player, life)
	local payload = {
		Id = id,
		Anchors = anchors,
		Names = {
			Abu = abuKey,
			Familia = familyKey,
			Profe = "NPC.PROFE_LUCIA",
			Rectora = "NPC.AMAIA",
		},
		Args = { nombre = player.DisplayName },
	}
	local fired = false
	local function fire()
		if fired then
			return
		end
		fired = true
		if player.Parent then
			remote:FireClient(player, "Cinematic", payload)
		end
	end
	-- Anclas distintas (varias suelen ser el mismo sitio: el jugador)
	local points: { Vector3 } = {}
	for _, cf in anchors do
		local near = false
		for _, p in points do
			if (p - cf.Position).Magnitude < 20 then
				near = true
				break
			end
		end
		if not near then
			table.insert(points, cf.Position)
		end
	end
	local pending = #points
	for _, position in points do
		task.spawn(function()
			pcall(function()
				player:RequestStreamAroundAsync(position, STREAM_WAIT)
			end)
			pending -= 1
			if pending <= 0 then
				fire()
			end
		end)
	end
	if pending <= 0 then
		fire() -- (ya estaba todo o no hay nada que cargar)
		return cinematic.Duration
	end
	task.delay(STREAM_WAIT, fire) -- tope: la escena empieza aunque falte algo
	return cinematic.Duration + STREAM_WAIT
end

-- La historia sigue cuando la escena acaba en la pantalla del jugador (o la salta). Si el cliente no
-- avisa, sigue sola al cabo de `fallback` segundos; pero si su pantalla dijo que la está viendo (le
-- llegó y va a salir, quizá detrás de otra pantalla), se le dan hasta EXTRA segundos más.
-- onDone se llama una sola vez.
local EXTRA = 20
local waiting: { [Player]: { [string]: () -> () } } = {}
local seen: { [Player]: { [string]: boolean } } = {}

function CinematicService.clientSeen(player: Player, id: string)
	seen[player] = seen[player] or {}
	seen[player][id] = true
end

function CinematicService.waitFor(player: Player, id: string, fallback: number, onDone: () -> ())
	if seen[player] then
		seen[player][id] = nil -- (de una vez anterior no cuenta)
	end
	local called = false
	local function once()
		if called then
			return
		end
		called = true
		local list = waiting[player]
		if list and list[id] == once then
			list[id] = nil
		end
		onDone()
	end
	waiting[player] = waiting[player] or {}
	waiting[player][id] = once
	task.delay(fallback, function()
		if seen[player] and seen[player][id] then
			task.delay(EXTRA, once)
		else
			once()
		end
	end)
end

-- El cliente dice que la escena `id` ha terminado (o se ha saltado)
function CinematicService.clientDone(player: Player, id: string)
	local list = waiting[player]
	local done = list and list[id]
	if seen[player] then
		seen[player][id] = nil
	end
	if done then
		task.spawn(done)
	end
end

function CinematicService.init()
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		waiting[player] = nil
		seen[player] = nil
	end)
end

return CinematicService
