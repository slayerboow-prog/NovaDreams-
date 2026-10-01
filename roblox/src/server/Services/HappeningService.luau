-- HappeningService: el DIRECTOR de las escenas de la historia (shared/LifeStory/HappeningIndex).
--
-- Para cada jugador, una escena es una línea de tiempo (shared/LifeStory/Sequencer) que corre a la vez
-- en el servidor y en su pantalla, con el mismo reloj (workspace:GetServerTimeNow()):
--   * Aquí: se buscan las anclas (SU garaje, SU parque…), se pide al mapa que cargue esas zonas, y se
--     hacen las pistas del servidor: ACTORES (aparecer, andar, mirar, emoción, gestos, irse:
--     server/LifeStory/StageActors) y MUNDO (memoria del mundo: WorldMemoryService). Las ESPERAS
--     («¡Cúbrete!», «acércate al portal», «cuando llegue Pip») las decide el servidor.
--   * En su pantalla (client/Controllers/HappeningClient): cámara, efectos, cielo, sonido, música,
--     diálogos en el mundo y rótulos. Puede SALTARLA: el servidor deja hechas las consecuencias que
--     faltaban (las mismas que viéndola entera) y la historia sigue.
-- Cada jugador vive su propia escena: lo de uno no para ni toca la de otro (los actores van en su
-- carpeta de historia; los efectos solo en su pantalla; con Audience = "Nearby" los de al lado ven los
-- efectos, sin cámara ni bloqueos).
--
-- Las misiones la lanzan como una cinemática (CinematicService.play delega aquí si el id es una escena)
-- y la historia sigue cuando acaba (CinematicService.clientDone). También con el efecto Scene = "Id".
--
-- API: has(id) · play(player, id, opts?) -> segundos · skip(player, id?) · isPlaying(player, id?)
--      onFinished(fn(player, id, skipped))

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HappeningIndex = require(ReplicatedStorage.Shared.LifeStory.HappeningIndex)
local Sequencer = require(ReplicatedStorage.Shared.LifeStory.Sequencer)

local HappeningService = {}

local LEAD = 0.5 -- segundos de margen para que el aviso llegue a la pantalla antes de empezar
local STREAM_WAIT = 2.5
local TICK = 0.05

type Run = {
	Serial: number,
	Id: string,
	Player: Player,
	Def: { [string]: any },
	Timeline: Sequencer.Timeline,
	StartAt: number,
	Paused: number,
	PausedAt: number?,
	Cursor: number,
	Anchors: { [string]: CFrame },
	Actors: { [string]: { Model: Model?, Borrowed: boolean, Npc: string? } },
	Inputs: { [string]: boolean },
	Waiting: Sequencer.Event?,
	WaitSince: number,
	InputGot: { [string]: boolean },
	Done: boolean,
	Light: boolean,
	Instant: boolean,
	Spectators: { Player },
	PortalAt: number,
}

local runs: { [Player]: { [number]: Run } } = {}
local serial = 0
local finishedListeners: { (Player, string, boolean) -> () } = {}

---------------------------------------------------------------------
-- Dependencias (se pueden cambiar en las pruebas: HappeningService._inject)
---------------------------------------------------------------------
local deps = {
	now = function(): number
		local ok, t = pcall(function()
			return workspace:GetServerTimeNow()
		end)
		return if ok and type(t) == "number" then t else os.clock()
	end,
	remote = function(): RemoteEvent?
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		return remotes and remotes:FindFirstChild("Happening") :: RemoteEvent?
	end,
	actors = function(): any
		return require(script.Parent.Parent.LifeStory.StageActors)
	end,
	world = function(): any
		return require(script.Parent.WorldMemoryService)
	end,
	scene = function(): any
		return require(script.Parent.SceneService)
	end,
	cinematic = function(): any
		return require(script.Parent.CinematicService)
	end,
	locate = function(player: Player, placeId: string, offset: Vector3?): CFrame?
		local LocationService = require(script.Parent.LocationService)
		local spot = LocationService.resolve(player, placeId, if offset then { Offset = offset } else nil)
		return spot and spot.CFrame
	end,
	zone = function(name: string): Vector3?
		return require(script.Parent.LocationService).zoneCenter(name)
	end,
	root = function(player: Player): BasePart?
		local character = player.Character
		return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	end,
	ground = function(position: Vector3): Vector3
		local ok, hit = pcall(function()
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
			return workspace:Raycast(position + Vector3.new(0, 10, 0), Vector3.new(0, -60, 0), params)
		end)
		return if ok and hit then hit.Position else position
	end,
	stream = function(player: Player, points: { Vector3 }, seconds: number)
		for _, p in points do
			task.spawn(function()
				pcall(function()
					player:RequestStreamAroundAsync(p, seconds)
				end)
			end)
		end
	end,
	wait = function(seconds: number)
		task.wait(seconds)
	end,
}
HappeningService.deps = deps

function HappeningService._inject(overrides: { [string]: any })
	for k, v in overrides do
		(deps :: any)[k] = v
	end
end

---------------------------------------------------------------------
-- Anclas
---------------------------------------------------------------------
-- Dónde está la Grieta para el servidor (su pantalla la ve a 450 studs hacia Los Pinos; aquí basta
-- con algo arriba y lejos para que los actores miren al cielo)
local function riftGuess(player: Player): CFrame
	local root = deps.root(player)
	local base = if root then root.Position else Vector3.zero
	return CFrame.new(base + Vector3.new(-160, 300, -160))
end

function HappeningService.resolveAnchors(player: Player, def: { [string]: any }): { [string]: CFrame }
	local root = deps.root(player)
	local fallback = if root then root.CFrame else CFrame.new()
	local anchors: { [string]: CFrame } = {}
	for name, anchor in def.Anchors or {} do
		local cf: CFrame? = nil
		local ok = pcall(function()
			if type(anchor) == "table" then
				cf = deps.locate(player, anchor.Place, anchor.Offset)
				if cf and anchor.Ground then
					cf = CFrame.new(deps.ground(cf.Position)) * cf.Rotation
				end
			elseif anchor == "Player" then
				cf = if root then root.CFrame else nil
			elseif anchor == "Rift" then
				cf = riftGuess(player)
			else
				local kind, value = anchor:match("^(%a+):(.+)$")
				if kind == "Place" then
					cf = deps.locate(player, value, nil)
				elseif kind == "Zone" then
					local center = deps.zone(value)
					cf = center and CFrame.new(center)
				elseif kind == "Actor" then
					local model = deps.scene().actorOf(player, value)
					cf = model and model:GetPivot()
				end
			end
		end)
		if not ok or not cf then
			cf = fallback
		end
		anchors[name] = cf :: CFrame
	end
	return anchors
end

-- Un punto { "Ancla", offset? } con lo que sabe el servidor (actores de la escena incluidos)
local function pointOf(run: Run, spec: any): Vector3?
	if type(spec) ~= "table" then
		return nil
	end
	local name = spec[1]
	local offset = if typeof(spec[2]) == "Vector3" then spec[2] else Vector3.zero
	local base: CFrame? = nil
	if name == "Player" then
		local root = deps.root(run.Player)
		base = root and root.CFrame
	elseif type(name) == "string" and name:sub(1, 6) == "Actor:" then
		local entry = run.Actors[name:sub(7)]
		if entry and entry.Model and entry.Model.Parent then
			base = entry.Model:GetPivot()
		end
	else
		base = run.Anchors[name]
	end
	if not base then
		return nil
	end
	return if spec[3] then base:PointToWorldSpace(offset) else base.Position + offset
end

-- A quién mira un actor, dicho para el cliente (ActorLife / HappeningClient)
local function lookTarget(run: Run, at: any): any
	if at == nil or at == false then
		return nil
	end
	if at == "Player" or run.Def.Anchors and run.Def.Anchors[at] == "Player" then
		return "Player"
	end
	if type(at) == "string" and at:sub(1, 6) == "Actor:" then
		return "Key:" .. at:sub(7)
	end
	if run.Actors[at] then
		return "Key:" .. at
	end
	if run.Def.Anchors and run.Def.Anchors[at] == "Rift" then
		return "Rift"
	end
	local cf = run.Anchors[at]
	return cf and cf.Position
end

---------------------------------------------------------------------
-- Enviar al cliente
---------------------------------------------------------------------
local function send(run: Run, kind: string, payload: { [string]: any })
	if run.Instant then
		return
	end
	local remote = deps.remote()
	if not remote then
		return
	end
	payload.Run = run.Serial
	payload.Id = run.Id
	if run.Player.Parent then
		remote:FireClient(run.Player, kind, payload)
	end
	if kind ~= "Play" then
		for _, spectator in run.Spectators do
			if spectator.Parent then
				remote:FireClient(spectator, kind, payload)
			end
		end
	end
end

-- Nombres y voces de quien habla (los del reparto, las criaturas y los actores de la escena)
local function speakers(player: Player, def: { [string]: any }): ({ [string]: string }, { [string]: string })
	local names, voices = {}, {}
	local Cast = require(ReplicatedStorage.Shared.LifeStory.Cast)
	local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
	local StoryCreatures = require(ReplicatedStorage.Shared.LifeStory.StoryCreatures)
	local spawnSpecs = {}
	for _, d in (def.Tracks or {}).Actors or {} do
		local spec = d.Spawn or d.Use
		if type(spec) == "table" and spec.Key then
			spawnSpecs[spec.Key] = spec
		end
	end
	for _, line in (def.Tracks or {}).Lines or {} do
		local who = line.Speaker
		if type(who) == "string" and names[who] == nil then
			if who == "Narrador" then
				names[who] = ""
				voices[who] = "Narrador"
			elseif who == "Yo" then
				names[who] = player.DisplayName
			else
				local spec = spawnSpecs[who]
				local npc = (spec and spec.Npc) or who
				local creature = spec and spec.Creature and StoryCreatures.get(spec.Creature)
				if creature then
					names[who] = creature.Name
					voices[who] = "Nino"
				elseif Cast.People[npc] then
					local ok, text = pcall(function()
						return Strings.get(Cast.nameOf(npc, { FamilyKey = player:GetAttribute("FamilyKey"), AbuKey = player:GetAttribute("AbuKey") }))
					end)
					names[who] = if ok then text else npc
					voices[who] = Cast.People[npc].Voice or "Narrador"
				else
					names[who] = (spec and spec.Name) or who
					voices[who] = "Narrador"
				end
			end
		end
	end
	return names, voices
end

---------------------------------------------------------------------
-- Pistas del servidor
---------------------------------------------------------------------
local function actorModel(run: Run, key: string): Model?
	local entry = run.Actors[key]
	return entry and entry.Model or nil
end

local function spawnActor(run: Run, spec: { [string]: any }, instant: boolean?)
	local key = spec.Key
	local base = run.Anchors[spec.Anchor or ""] or (deps.root(run.Player) and (deps.root(run.Player) :: BasePart).CFrame) or CFrame.new()
	local position = base.Position + (if typeof(spec.Offset) == "Vector3" then spec.Offset else Vector3.zero)
	position = deps.ground(position)
	local face = if spec.Face then pointOf(run, spec.Face) else nil
	local cf = if face and (face - position).Magnitude > 0.1
		then CFrame.lookAt(position, Vector3.new(face.X, position.Y, face.Z))
		else CFrame.new(position) * base.Rotation
	local ok, model = pcall(function()
		return deps.actors().spawn(run.Player, key, spec, cf)
	end)
	run.Actors[key] = { Model = if ok then model else nil, Borrowed = false, Npc = spec.Npc }
	if not ok then
		warn(("[Happening] %s: no se pudo crear el actor %s: %s"):format(run.Id, key, tostring(model)))
	end
	local _ = instant
end

local function applyActor(run: Run, d: { [string]: any }, instant: boolean)
	local A = deps.actors()
	if d.Spawn then
		spawnActor(run, d.Spawn, instant)
	elseif d.Use then
		local spec = d.Use
		local model = nil
		pcall(function()
			model = deps.scene().actorOf(run.Player, spec.Npc or spec.Key)
		end)
		if model then
			A.bind(model, spec.Key)
			run.Actors[spec.Key] = { Model = model, Borrowed = true, Npc = spec.Npc or spec.Key }
		else
			spawnActor(run, spec, instant) -- (no está: aparece donde diga)
		end
	elseif d.Move then
		local model = actorModel(run, d.Move.Key)
		local to = pointOf(run, d.Move.To)
		if model and to then
			local entry = run.Actors[d.Move.Key]
			if entry and entry.Borrowed then
				return -- (a los de la misión los mueve su misión)
			end
			to = deps.ground(to)
			if instant then
				A.place(model, to)
			else
				A.move(model, to, d.Move.Run == true)
			end
		end
	elseif d.Look then
		local model = actorModel(run, d.Look.Key)
		if model then
			A.look(model, lookTarget(run, d.Look.At))
		end
	elseif d.Mood then
		local model = actorModel(run, d.Mood.Key)
		if model then
			A.mood(model, d.Mood.Mood)
		end
	elseif d.Gesture and not instant then
		local entry = run.Actors[d.Gesture.Key]
		if entry and entry.Model then
			if entry.Borrowed and entry.Npc then
				pcall(function()
					deps.scene().gesture(run.Player, entry.Npc, d.Gesture.Play)
				end)
			else
				A.play(entry.Model, d.Gesture.Play)
			end
		end
	elseif d.Say and not instant then
		local model = actorModel(run, d.Say.Key)
		if model then
			pcall(function()
				require(script.Parent.Parent.World.Npc).say(model, d.Say.Text, d.Say.Seconds or 3)
			end)
		end
	elseif d.Face then
		local model = actorModel(run, d.Face.Key)
		local to = pointOf(run, d.Face.At and { d.Face.At } or nil)
		if model and to then
			pcall(function()
				local pivot = model:GetPivot()
				model:PivotTo(CFrame.lookAt(pivot.Position, Vector3.new(to.X, pivot.Position.Y, to.Z)))
			end)
		end
	elseif d.Despawn then
		local entry = run.Actors[d.Despawn.Key]
		if entry and entry.Model then
			if entry.Borrowed then
				A.unbind(entry.Model)
			else
				A.despawn(entry.Model)
			end
		end
		run.Actors[d.Despawn.Key] = nil
	end
end

local function applyEvent(run: Run, e: Sequencer.Event, instant: boolean)
	if not Sequencer.passes(e.Data, run.Inputs) then
		return
	end
	if e.Track == "World" then
		pcall(function()
			deps.world().apply(run.Player, e.Data.Set)
		end)
	elseif e.Track == "Actors" then
		local ok, err = pcall(applyActor, run, e.Data, instant)
		if not ok then
			warn(("[Happening] %s: actor: %s"):format(run.Id, tostring(err)))
		end
	end
end

---------------------------------------------------------------------
-- Correr una escena
---------------------------------------------------------------------
local function finish(run: Run, skipped: boolean)
	if run.Done then
		return
	end
	if skipped then
		-- Lo que faltaba de servidor, hecho de golpe (las consecuencias son las mismas)
		for _, e in Sequencer.skipPlan(run.Timeline, run.Cursor, run.Inputs) do
			applyEvent(run, e, true)
		end
	end
	run.Done = true
	-- Al acabar: los actores de la escena se van (salvo Keep) y los prestados vuelven a ser como eran
	local A = nil
	pcall(function()
		A = deps.actors()
	end)
	for key, entry in run.Actors do
		local model = entry.Model
		if A and model then
			if entry.Borrowed then
				pcall(A.unbind, model)
			elseif not run.Def.KeepActors then
				pcall(A.despawn, model)
			end
		end
		run.Actors[key] = nil
	end
	send(run, "Stop", { Skipped = skipped })
	local list = runs[run.Player]
	if list then
		list[run.Serial] = nil
		if next(list) == nil then
			runs[run.Player] = nil
		end
	end
	-- La historia sigue (el paso de cine que la lanzó)
	pcall(function()
		deps.cinematic().clientDone(run.Player, run.Id)
	end)
	for _, fn in finishedListeners do
		task.spawn(fn, run.Player, run.Id, skipped)
	end
end

local function waitMet(run: Run, w: { [string]: any }, now: number): (boolean, boolean?)
	local elapsed = now - run.WaitSince
	local timeout = math.min(tonumber(w.Timeout or w.Seconds) or Sequencer.MAX_WAIT, Sequencer.MAX_WAIT)
	if w.Seconds then
		return elapsed >= w.Seconds, nil
	elseif w.Input then
		if run.InputGot[w.Input] then
			return true, true
		end
		return elapsed >= timeout, false
	elseif w.Near then
		local root = deps.root(run.Player)
		local spec = w.Near
		local target = pointOf(run, { spec[1], spec[3] })
		if root and target then
			local d = root.Position - target
			if Vector3.new(d.X, 0, d.Z).Magnitude <= (spec[2] or 8) then
				return true, true
			end
		end
		return elapsed >= timeout, false
	elseif w.Arrived then
		local model = actorModel(run, w.Arrived)
		if not model or model:GetAttribute("Arrived") == true then
			return true, true
		end
		return elapsed >= timeout, false
	end
	return true, nil
end

local function step(run: Run)
	if run.Done then
		return
	end
	if not run.Player.Parent then
		finish(run, true)
		return
	end
	local now = deps.now()
	if now < run.StartAt then
		return
	end
	if run.Waiting then
		local w = run.Waiting
		local met, result = waitMet(run, w.Data, now)
		if not met then
			return
		end
		if w.Data.Input then
			run.Inputs[w.Data.Input] = result == true
		elseif result ~= nil and type(w.Data.Result) == "string" then
			run.Inputs[w.Data.Result] = result == true
		end
		run.Paused += now - (run.PausedAt or now)
		run.PausedAt = nil
		run.Waiting = nil
		send(run, "Resume", { Paused = run.Paused, Inputs = run.Inputs })
		return
	end
	local t = Sequencer.sceneTime(run, now)
	for _, e in Sequencer.due(run.Timeline, run.Cursor, t, "Server") do
		if e.Track == "Wait" then
			run.Cursor = e.At
			run.Waiting = e
			run.WaitSince = now
			run.PausedAt = run.StartAt + run.Paused + e.At
			send(run, "Pause", { At = e.At })
			return
		end
		applyEvent(run, e, false)
		run.Cursor = e.At
	end
	run.Cursor = math.max(run.Cursor, t)
	if t >= run.Timeline.Duration then
		finish(run, false)
	end
end

-- Escena sin pantalla que la vea (pruebas, servidor sin remotos): las consecuencias (memoria del
-- mundo), de golpe. Los actores no hacen falta: nadie los vería.
local function runInstant(run: Run)
	for _, e in run.Timeline.Events do
		if e.Track == "World" then
			applyEvent(run, e, true)
		end
	end
	run.Cursor = run.Timeline.Duration
	finish(run, false)
end

function HappeningService.has(id: any): boolean
	return HappeningIndex.has(id)
end

function HappeningService.isPlaying(player: Player, id: string?): boolean
	for _, run in runs[player] or {} do
		if id == nil or run.Id == id then
			return true
		end
	end
	return false
end

-- Lanza la escena `id` para este jugador. Devuelve cuánto puede tardar como mucho (con las esperas a
-- tope y el margen de carga): sirve de tope a quien espera (CinematicService.waitFor). La historia sigue
-- antes si acaba antes (el servidor avisa con CinematicService.clientDone).
function HappeningService.play(player: Player, id: string, opts: { [string]: any }?): number
	local def = HappeningIndex.get(id)
	if not def then
		warn("[Happening] Escena desconocida", id)
		return 0
	end
	local options = opts or {}
	local timeline = Sequencer.compile(id, def)
	local light = def.Light == true or (def.Tracks or {}).Camera == nil
	-- Una escena con cámara a la vez por jugador: si había otra, se salta (sus consecuencias quedan)
	if not light then
		for _, other in runs[player] or {} do
			if not other.Light then
				finish(other, true)
			end
		end
	end
	serial += 1
	local remote = deps.remote()
	local run: Run = {
		Serial = serial,
		Id = id,
		Player = player,
		Def = def,
		Timeline = timeline,
		StartAt = 0,
		Paused = 0,
		PausedAt = nil,
		Cursor = -1,
		Anchors = HappeningService.resolveAnchors(player, def),
		Actors = {},
		Inputs = {},
		Waiting = nil,
		WaitSince = 0,
		InputGot = {},
		Done = false,
		Light = light,
		Instant = remote == nil or options.Instant == true,
		Spectators = {},
		PortalAt = 0,
	}
	runs[player] = runs[player] or {}
	runs[player][run.Serial] = run
	if run.Instant then
		runInstant(run)
		return 0.1
	end
	-- Que el mapa cargue lo que va a enseñar la cámara (como CinematicService)
	local points: { Vector3 } = {}
	for _, cf in run.Anchors do
		local near = false
		for _, p in points do
			if (p - cf.Position).Magnitude < 40 then
				near = true
				break
			end
		end
		if not near then
			table.insert(points, cf.Position)
		end
	end
	local streamWait = if light then 0 else STREAM_WAIT
	if streamWait > 0 then
		deps.stream(player, points, streamWait)
	end
	-- Quién más lo ve (solo efectos): Audience = "Nearby"
	if def.Audience == "Nearby" then
		local center = (run.Anchors.Yo or (deps.root(player) and (deps.root(player) :: BasePart).CFrame) or CFrame.new()).Position
		for _, other in Players:GetPlayers() do
			local root = deps.root(other)
			if other ~= player and root and (root.Position - center).Magnitude <= (def.AudienceRadius or 250) then
				table.insert(run.Spectators, other)
			end
		end
	end
	local names, voices = speakers(player, def)
	task.spawn(function()
		if streamWait > 0 then
			deps.wait(math.min(streamWait, 1.2)) -- (lo justo: no se hace esperar de más)
		end
		if run.Done then
			return
		end
		run.StartAt = deps.now() + LEAD
		local payload = {
			StartAt = run.StartAt,
			Anchors = run.Anchors,
			Names = names,
			Voices = voices,
			Args = { nombre = player.DisplayName },
			Light = light,
			Skippable = def.Skippable ~= false,
		}
		send(run, "Play", payload)
		for _, spectator in run.Spectators do
			local remoteNow = deps.remote()
			if remoteNow and spectator.Parent then
				local copy = table.clone(payload)
				copy.Run, copy.Id, copy.Spectator = run.Serial, run.Id, true
				remoteNow:FireClient(spectator, "Play", copy)
			end
		end
		pcall(function()
			deps.cinematic().clientSeen(player, id)
		end)
		while not run.Done do
			local ok, err = pcall(step, run)
			if not ok then
				warn(("[Happening] %s: %s"):format(id, tostring(err)))
				finish(run, true)
				break
			end
			deps.wait(TICK)
		end
	end)
	return Sequencer.maxDuration(timeline) + streamWait + LEAD + 1
end

-- Salta la escena (todas las del jugador si no se dice cuál)
function HappeningService.skip(player: Player, idOrSerial: any?): boolean
	local any = false
	for _, run in runs[player] or {} do
		if idOrSerial == nil or run.Id == idOrSerial or run.Serial == idOrSerial then
			if run.Def.Skippable ~= false then
				finish(run, true)
				any = true
			end
		end
	end
	return any
end

function HappeningService.onFinished(fn: (Player, string, boolean) -> ())
	table.insert(finishedListeners, fn)
end

-- (pruebas) avanzar todas las escenas a mano
function HappeningService._step()
	for _, list in runs do
		for _, run in list do
			step(run)
		end
	end
end

function HappeningService._runs(player: Player): { [number]: Run }
	return runs[player] or {}
end

---------------------------------------------------------------------
-- Lo que pide el cliente (validado)
---------------------------------------------------------------------
local function runFor(player: Player, serialId: any): Run?
	local list = runs[player]
	return if list and type(serialId) == "number" then list[serialId] else nil
end

function HappeningService.onClient(player: Player, kind: any, serialId: any, value: any)
	local run = runFor(player, serialId)
	if not run or run.Done then
		return
	end
	if kind == "Skip" then
		if run.Def.Skippable ~= false then
			finish(run, true)
		end
	elseif kind == "Input" and type(value) == "string" and run.Waiting and run.Waiting.Data.Input == value then
		run.InputGot[value] = true
	elseif kind == "Portal" and type(value) == "number" then
		-- Atravesar un portal de la escena: si de verdad estás junto a él, al otro lado
		local now = deps.now()
		if now - run.PortalAt < 1 then
			return
		end
		local fx = (run.Def.Tracks or {}).Fx or {}
		local spec = fx[value]
		local teleport = spec and spec.Params and spec.Params.Teleport
		if not spec or spec.Play ~= "Portal" or type(teleport) ~= "table" then
			return
		end
		local center = pointOf(run, { spec.Anchor or "Player", spec.Offset })
		local root = deps.root(player)
		local radius = ((spec.Params and spec.Params.Radius) or 4) * ((spec.Params and spec.Params.Scale) or 1)
		if not center or not root or (root.Position - center).Magnitude > radius * 2 + 6 then
			return
		end
		local destination = pointOf(run, teleport)
		if destination then
			run.PortalAt = now
			pcall(function()
				deps.scene().teleportTo(player, destination)
			end)
		end
	end
end

---------------------------------------------------------------------
-- Arranque
---------------------------------------------------------------------
local function isTester(player: Player): boolean
	if game.CreatorId == player.UserId then
		return true
	end
	local ok, result = pcall(function()
		return require(script.Parent.TesterService).isTester(player)
	end)
	if ok and result == true then
		return true
	end
	local okStudio, studio = pcall(function()
		return game:GetService("RunService"):IsStudio()
	end)
	return okStudio and studio == true
end

function HappeningService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local remote = remotes:FindFirstChild("Happening") :: RemoteEvent?
	if not remote then
		local created = Instance.new("RemoteEvent")
		created.Name = "Happening"
		created.Parent = remotes
		remote = created
	end
	(remote :: RemoteEvent).OnServerEvent:Connect(function(player, kind, serialId, value)
		HappeningService.onClient(player, kind, serialId, value)
	end)
	Players.PlayerRemoving:Connect(function(player)
		for _, run in runs[player] or {} do
			finish(run, true)
		end
		runs[player] = nil
	end)
	-- Modo pruebas: «/escena Id» lanza una escena (solo el dueño y los testers)
	local function watch(player: Player)
		player.Chatted:Connect(function(message)
			local id = message:match("^/escena%s+([%w_]+)")
			if id and isTester(player) then
				if HappeningIndex.has(id) then
					HappeningService.play(player, id)
				else
					warn("[Happening] No existe la escena", id)
				end
			end
		end)
	end
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerAdded:Connect(watch)
end

return HappeningService
