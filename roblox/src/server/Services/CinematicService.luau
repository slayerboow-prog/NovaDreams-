-- CinematicService: prepara y lanza las escenas de cámara de la historia (shared/LifeStory/Cinematics.luau).
-- Para cada jugador busca sus anclas (SU casa, SU ventanal, la zona…), pide al mapa que cargue esas
-- zonas (el mapa se carga por trozos, StreamingEnabled) y, cuando están (o tras un tope corto),
-- manda la escena al cliente, que la dibuja.
-- Devuelve lo que dura la escena, para que la historia siga cuando termine.
--
-- InScene (M-04): el SERVIDOR sabe cuándo un jugador está viendo una escena. Al lanzarla se marca el
-- atributo InScene = true (y SceneId = la escena) en el jugador; se quita cuando su pantalla dice que
-- ha acabado (clientDone), cuando su latido se corta (Remotes.Scene "Beat", cada segundo desde
-- SceneClient) o al llegar a un tope. Lo leen BabyService (Abu no habla encima del nacimiento) y la
-- historia (no se lanzan avisos ni frases en mitad de una escena). Ver inScene/beginScene/endScene.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cinematics = require(ReplicatedStorage.Shared.LifeStory.Cinematics)
local Family = require(ReplicatedStorage.Shared.LifeStory.Family)
local LocationService = require(script.Parent.LocationService)
local SceneService = require(script.Parent.SceneService)

local CinematicService = {}

local open: { [Player]: { [string]: any } } = {} -- escenas abiertas por jugador (más abajo: InScene)

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

-- Antes de CUALQUIER escena de la historia (cinemática, escena del motor o conversación escenificada):
-- te bajas del vehículo (bici, patinete, monopatín, coche, moto…). El de alquiler se retira y el tuyo
-- se queda aparcado (VehicleService.exitAny). Si no, la escena empezaba contigo montado y los actores
-- llegaban hasta ti y se metían en la bici (vídeo de la Plaza Mayor). Devuelve si te ha bajado.
function CinematicService.leaveVehicle(player: Player): boolean
	local RideState = require(ReplicatedStorage.Shared.RideState)
	if not RideState.inVehicle(player) then
		return false
	end
	pcall(function()
		require(script.Parent.VehicleService).exitAny(player, true)
	end)
	-- (sentado en algo que no es de VehicleService, como el autobús: de pie)
	pcall(function()
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.SeatPart and RideState.inVehicle(player) then
			humanoid.Sit = false
		end
	end)
	return true
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
			local duration = HappeningService.play(player, id)
			-- Solo si sigue en marcha: una escena que acaba en el acto (sin pantalla, Instant, un error al
			-- empezar) ya avisó con clientDone ANTES de llegar aquí, y abrirla ahora la dejaba marcada como
			-- «en escena» sin nadie que la cerrara (la historia no ofrecía nada hasta los relojes de tope)
			if type(duration) == "number" and duration > 0 and (type(HappeningService.isPlaying) ~= "function" or HappeningService.isPlaying(player, id)) then
				CinematicService.beginScene(player, id, duration)
			end
			return duration
		end
	end
	local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("LifeStory")
	if not cinematic or not remote then
		warn("[CinematicService] No se puede reproducir", id)
		return 0
	end
	CinematicService.leaveVehicle(player)
	local anchors = CinematicService.resolveAnchors(player, cinematic)
	CinematicService.beginScene(player, id, cinematic.Duration + STREAM_WAIT)
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
	-- (la pantalla la tiene: cuenta como señal de vida de esa escena)
	local scene = open[player] and open[player][id]
	if scene then
		scene.Beats += 1
		scene.LastBeat = CinematicService.now()
	end
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
		-- La historia sigue sin noticias de la pantalla: si nunca dio señales de vida (sin latido),
		-- tampoco se la da por ocupada
		local scene = open[player] and open[player][id]
		if scene and scene.Beats == 0 then
			CinematicService.endScene(player, id, "SinNoticias")
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
	CinematicService.endScene(player, id, "Fin")
	if done then
		task.spawn(done)
	end
end

---------------------------------------------------------------------
-- InScene: ¿está el jugador viendo una escena? (lo sabe el servidor)
---------------------------------------------------------------------

-- Tiempos (segundos). StartGrace: lo que se espera al primer latido (el mapa carga, la escena puede
-- esperar turno detrás de otra pantalla). BeatTimeout: sin latido este rato, la escena se cierra.
-- CapExtra: margen sobre la duración; pasado el tope se cierra aunque siga latiendo.
-- Quiet: un latido que llega justo después de cerrar una escena no abre otra.
CinematicService.Timing = { StartGrace = 8, BeatTimeout = 5, CapExtra = 60, MinBeatGap = 0.25, Quiet = 2 }
CinematicService.now = os.clock -- (las pruebas lo cambian)

type Open = { Started: number, LastBeat: number, Beats: number, Cap: number, Client: boolean? }
local lastClosed: { [Player]: number } = {}
local lastBeatAt: { [Player]: number } = {}
CinematicService.CLIENT_ID = "Cliente" -- una escena que solo conoce la pantalla (la lanzó otro sistema)
local CLIENT_ID = CinematicService.CLIENT_ID

local function now(): number
	return CinematicService.now()
end

-- El atributo sigue a la lista: InScene = true y SceneId = la más reciente, o nada
local function publish(player: Player)
	local list = open[player]
	local newest, newestAt = nil, -math.huge
	for id, scene in list or {} do
		if scene.Started > newestAt then
			newest, newestAt = id, scene.Started
		end
	end
	if newest == nil then
		open[player] = nil
	end
	pcall(function()
		player:SetAttribute("InScene", if newest then true else nil)
		player:SetAttribute("SceneId", newest)
	end)
end

-- ¿Ya no vale? Devuelve el motivo (o nil)
local function expired(scene: Open, t: number): string?
	if t >= scene.Cap then
		return "Tope"
	end
	if scene.Beats == 0 then
		-- (nunca latió: se le da tiempo a llegar a la pantalla)
		return if t - scene.Started >= CinematicService.Timing.StartGrace then "SinLatido" else nil
	end
	return if t - scene.LastBeat >= CinematicService.Timing.BeatTimeout then "SinLatido" else nil
end

local function nextCheck(scene: Open): number
	local at = if scene.Beats == 0
		then scene.Started + CinematicService.Timing.StartGrace
		else scene.LastBeat + CinematicService.Timing.BeatTimeout
	return math.min(scene.Cap, at)
end

local check: (player: Player, id: string, scene: Open) -> ()

local function schedule(player: Player, id: string, scene: Open)
	task.delay(math.max(0.05, nextCheck(scene) - now()), check, player, id, scene)
end

function check(player: Player, id: string, scene: Open)
	local list = open[player]
	if not list or list[id] ~= scene then
		return -- (ya cerrada o sustituida)
	end
	local reason = expired(scene, now())
	if not reason then
		schedule(player, id, scene)
		return
	end
	CinematicService.endScene(player, id, reason)
	-- La pantalla latía y dejó de hacerlo (se colgó, se cerró el juego): la historia no espera más
	if reason == "SinLatido" and scene.Beats > 0 then
		local waiter = waiting[player] and waiting[player][id]
		if waiter then
			task.spawn(waiter)
		end
	end
end

-- Abre una escena (o la renueva si ya estaba). maxSeconds: lo que dura como mucho (sin el margen).
function CinematicService.beginScene(player: Player, id: string, maxSeconds: number?)
	if type(id) ~= "string" then
		return
	end
	local t = now()
	local list = open[player] or {}
	open[player] = list
	local scene: Open = { Started = t, LastBeat = t, Beats = 0, Cap = t + (maxSeconds or 60) + CinematicService.Timing.CapExtra }
	list[id] = scene
	-- (la escena «Cliente» se sustituye por la de verdad)
	if id ~= CLIENT_ID then
		list[CLIENT_ID] = nil
	end
	publish(player)
	schedule(player, id, scene)
end

-- Cierra una escena (id = nil: todas). Devuelve si había algo que cerrar.
function CinematicService.endScene(player: Player, id: string?, _reason: string?): boolean
	local list = open[player]
	if not list then
		return false
	end
	local closed = false
	if id == nil then
		closed = next(list) ~= nil
		table.clear(list)
	elseif list[id] then
		list[id] = nil
		closed = true
	end
	if closed then
		lastClosed[player] = now()
		publish(player)
	end
	return closed
end

-- Quita al momento lo que ya no vale (sin esperar a los relojes)
local function sweep(player: Player)
	local list = open[player]
	if not list then
		return
	end
	local t = now()
	local due = {}
	for id, scene in list do
		if expired(scene, t) then
			table.insert(due, { id, scene })
		end
	end
	for _, pair in due do
		check(player, pair[1], pair[2])
	end
end

-- ¿Está viendo una escena? (lo mismo que el atributo InScene, pero al día al instante)
function CinematicService.inScene(player: Player): boolean
	sweep(player)
	return open[player] ~= nil and next(open[player]) ~= nil
end

-- La escena abierta más reciente (o nil)
function CinematicService.sceneOf(player: Player): string?
	if not CinematicService.inScene(player) then
		return nil
	end
	return player:GetAttribute("SceneId")
end

-- Latido de la pantalla: «sigo viendo algo». Renueva todas sus escenas abiertas; si no hay ninguna
-- (la lanzó un sistema que no pasa por aquí, p. ej. una escena desde un efecto), abre «Cliente», que
-- se cierra sola cuando el latido para.
function CinematicService.beat(player: Player)
	local t = now()
	if lastBeatAt[player] and t - lastBeatAt[player] < CinematicService.Timing.MinBeatGap then
		return -- (demasiado seguido)
	end
	lastBeatAt[player] = t
	local list = open[player]
	if not list or next(list) == nil then
		-- Un latido que llega justo después de cerrar (iba por el camino) no reabre nada
		if lastClosed[player] and t - lastClosed[player] < CinematicService.Timing.Quiet then
			return
		end
		local scene: Open = { Started = t, LastBeat = t, Beats = 1, Cap = math.huge, Client = true }
		open[player] = { [CLIENT_ID] = scene }
		publish(player)
		schedule(player, CLIENT_ID, scene)
		return
	end
	for _, scene in list do
		scene.Beats += 1
		scene.LastBeat = t
	end
end

-- Espera (cediendo) a que el jugador no esté en ninguna escena; devuelve true si lo está a tiempo
function CinematicService.waitUntilFree(player: Player, timeout: number?): boolean
	local limit = now() + (timeout or 60)
	while player.Parent and CinematicService.inScene(player) do
		if now() >= limit then
			return false
		end
		task.wait(0.5)
	end
	return true
end

-- Se va del juego: no queda nada suyo (ni escenas abiertas ni historias esperando)
function CinematicService.forget(player: Player)
	waiting[player] = nil
	seen[player] = nil
	open[player] = nil
	lastClosed[player] = nil
	lastBeatAt[player] = nil
end

function CinematicService.init()
	Players.PlayerRemoving:Connect(CinematicService.forget)
	-- El latido de las pantallas (SceneClient)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 10)
	if remotes then
		local remote = remotes:FindFirstChild("Scene")
		if not remote then
			local created = Instance.new("RemoteEvent")
			created.Name = "Scene"
			created.Parent = remotes
			remote = created
		end
		(remote :: RemoteEvent).OnServerEvent:Connect(function(player, kind)
			if kind == "Beat" then
				CinematicService.beat(player)
			end
		end)
	end
end

return CinematicService
