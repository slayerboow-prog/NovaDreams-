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
-- carpeta de historia; los efectos solo en su pantalla). Fase 7, alcance (Scope): Personal (solo tú),
-- Group (quien está cerca en el mismo paso se une a la tuya) y World (los de al lado ven el acontecimiento
-- en el mundo, sin cámara ni bloqueos). Ver «FASE 7 · ALCANCE» más abajo.
--
-- Las misiones la lanzan como una cinemática (CinematicService.play delega aquí si el id es una escena)
-- y la historia sigue cuando acaba (CinematicService.clientDone). También con el efecto Scene = "Id".
--
-- CINEMATIC_SCENE (formato en shared/LifeStory/Sequencer; auditoría §6.1):
--   * VARIANTES y condiciones (If/IfNot con Conditions, Variants): se resuelven AQUÍ al empezar, con la
--     partida del jugador (Flags, Rel, Memories…), más Late (opts.Late o el atributo StoryLate) e Items
--     (la mochila). El cliente recibe el resultado (Variant, Gates) y ve exactamente lo mismo.
--   * DIÁLOGO (pista Dialogue): las frases salen en su pantalla; aquí se giran las MIRADAS: todo el
--     reparto mira a quien habla (Look = "Speaker", por defecto) y quien habla mira a quien le habla.
--   * ENTRADAS y SALIDAS andando (Enter / Exit): aparecen en la puerta y andan a su marca; se van
--     andando y desaparecen al llegar (al saltar: ya en su sitio / ya fuera).
--   * Until = { Event }: la escena acaba con un aviso de StoryEvents (o se queda en el último plano
--     esperándolo). OnSkip: lo que se da por hecho al saltarla.
--   * Al MORIR o salir del juego, la escena se acaba (como saltarla: las consecuencias quedan) y su
--     pantalla lo devuelve todo (cámara, controles, ambiente, luz).
--
-- API: has(id) · play(player, id, opts?) -> segundos · skip(player, id?) · isPlaying(player, id?)
--      onFinished(fn(player, id, skipped)) · onDied(player) · onStoryEvent(player, name, payload)
--      opts = { Instant?, Late? (llegó tarde: condición Late), Sandbox? (Cinemateca: solo mirarla, sin
--      memoria del mundo, sin seguir la historia, sin portales ni nadie más; server/Services/CinematecaService) }

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HappeningIndex = require(ReplicatedStorage.Shared.LifeStory.HappeningIndex)
local Sequencer = require(ReplicatedStorage.Shared.LifeStory.Sequencer)
local ActorStaging = require(ReplicatedStorage.Shared.LifeStory.ActorStaging)
local ReadingTime = require(ReplicatedStorage.Shared.LifeStory.ReadingTime) -- cuánto se queda una frase

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
	Choice: { [string]: any },
	LookFixed: { [string]: boolean }, -- actores con una mirada propia (no siguen a quien habla)
	Speaker: string?,
	SpeakerTo: any,
	LastSpeaker: string?,
	Leaving: { [Model]: boolean }, -- actores que se van andando (Exit)
	Holding: boolean, -- acabó y espera el aviso de Until
	HoldSince: number,
	UntilMet: boolean,
	Marks: { [string]: Vector3 }, -- dónde está (o adónde va) cada actor: nadie se mete en otro
	AdvancedAt: number, -- (tocar para seguir) cuándo saltó a la frase siguiente la última vez
	Queued: boolean?, -- espera su turno detrás de otra escena con cámara (Queue / AfterScene)
	Scope: string, -- (fase 7) "Personal" | "Group" | "World"
	Participants: { Player }, -- (Group) quien la vive contigo, con su cámara
	Payload: { [string]: any }?, -- lo que se mandó al empezar (para quien se une o llega a mitad)
	AudienceAt: number?, -- (World) cuándo se miró por última vez quién está cerca
	Sandbox: boolean?, -- (Cinemateca) solo para mirarla: no toca la memoria del mundo ni la historia
	Frozen: boolean?, -- (Cinemateca) parada mientras el tester escribe un comentario
	StandIns: { [string]: CFrame }?, -- (Cinemateca) dónde va cada actor de la misión si no está (su marca)
	Formation: number?, -- cuántos suplentes sin marca se han colocado ya (en semicírculo delante de ti)
}

local runs: { [Player]: { [number]: Run } } = {}
local serial = 0
local finishedListeners: { (Player, string, boolean) -> () } = {}
local bySerial: { [number]: Run } = {} -- todas las escenas en marcha (también para quien vive la de otro)

---------------------------------------------------------------------
-- FASE 7 · ALCANCE de una escena (Scope). El servidor manda: él empieza, sigue y acaba cada escena.
--   Personal  (por defecto) solo tú: tu cámara, tus actores; a los demás no les pasa nada (y salen
--             ocultos de tus planos: SceneClient).
--   Group     la vive también quien está CERCA (GROUP_RADIUS) y en el MISMO paso de la historia: cuando
--             su historia pide la misma escena mientras la tuya empieza (GROUP_JOIN s), se une a la tuya
--             (mismo reloj, mismos actores; cada uno con su cámara) en vez de tener otra. Sus
--             consecuencias (memoria del mundo) y su historia siguen como si la viera solo. Nadie bloquea
--             a nadie: saltar, morir o irse solo te saca a TI; si se va quien la empezó, los demás acaban
--             con sus consecuencias. Las esperas y los toques los decide quien la empezó.
--   World     un acontecimiento del mundo (el meteorito): la cámara es solo de quien la vive; los que
--             están cerca (AudienceRadius o WORLD_RADIUS) ven lo que pasa en el mundo (efectos, sonido,
--             cielo) SIN perder el control ni la cámara, también si llegan a mitad; quien se aleja deja de
--             verlo. Nunca se baja del vehículo, se mueve ni se teletransporta a quien no la vive.
--   (Audience = "Nearby", el nombre de antes, es World.)
---------------------------------------------------------------------
HappeningService.Scopes = { Personal = true, Group = true, World = true }
HappeningService.GROUP_RADIUS = 60
HappeningService.GROUP_JOIN = 10
HappeningService.WORLD_RADIUS = 250
HappeningService.WORLD_EVERY = 1 -- cada cuánto se mira quién está cerca de un acontecimiento del mundo

function HappeningService.scopeOf(def: { [string]: any }?): string
	if type(def) ~= "table" then
		return "Personal"
	end
	if type(def.Scope) == "string" and HappeningService.Scopes[def.Scope] then
		return def.Scope
	end
	return if def.Audience == "Nearby" then "World" else "Personal"
end

local function isIn(list: { Player }, who: Player): boolean
	return table.find(list, who) ~= nil
end

---------------------------------------------------------------------
-- Dependencias (se pueden cambiar en las pruebas: HappeningService._inject)
---------------------------------------------------------------------
-- Lo que no cuenta para los rayos de la escena: los actores (StoryScenes) y los jugadores
local function sceneSkip(): { Instance }
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
	return skip
end

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
	-- El suelo bajo un punto. El rayo sale de poco por encima (4 studs): desde más arriba, dentro de una
	-- casa daba en el techo y el actor acababa en el tejado. Si ahí no hay suelo, desde más arriba.
	ground = function(position: Vector3): Vector3
		local ok, hit = pcall(function()
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = sceneSkip()
			return workspace:Raycast(position + Vector3.new(0, 4, 0), Vector3.new(0, -54, 0), params)
				or workspace:Raycast(position + Vector3.new(0, 10, 0), Vector3.new(0, -60, 0), params)
		end)
		return if ok and hit then hit.Position else position
	end,
	-- ¿Se llega andando de `from` a `to` sin salir de la sala? (mismo suelo, sin pared en medio, por encima de los muebles). Un
	-- actor que se aparta de otro nunca cruza una pared ni sube al tejado.
	reachable = function(from: Vector3, to: Vector3): boolean
		local ok, result = pcall(function()
			local a, b = deps.ground(from), deps.ground(to)
			if math.abs(a.Y - b.Y) > 1.6 then
				return false
			end
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = sceneSkip()
			params.RespectCanCollide = true
			for _, h in { 3.4 } do -- (por encima de mesas y sofás: solo cuentan las paredes)
				local p, q = a + Vector3.new(0, h, 0), b + Vector3.new(0, h, 0)
				if (q - p).Magnitude > 0.05 and workspace:Raycast(p, q - p, params) then
					return false
				end
			end
			return true
		end)
		return ok and result == true
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
	later = function(seconds: number, fn: () -> ())
		task.delay(seconds, fn)
	end,
	-- La partida del jugador (para las condiciones de las variantes)
	profile = function(player: Player): { [string]: any }?
		return require(script.Parent.DataService).get(player)
	end,
	-- Las condiciones de las misiones (shared/LifeStory/Conditions) con la foto del jugador
	context = function(player: Player, data: { [string]: any }): { [string]: any }
		local story = data.Story or {}
		local rel = {}
		for npc, entry in story.NpcMemory or {} do
			rel[npc] = if type(entry) == "table" then entry.Rel or 0 else 0
		end
		local clock, weekday = 12, 1
		pcall(function()
			local now = require(ReplicatedStorage.Shared.GameClock).now()
			clock, weekday = now.ClockTime, now.Weekday
		end)
		local progress = 1
		pcall(function()
			local hours = require(ReplicatedStorage.Shared.Config).LifeStory.StageHours[data.Life.Stage]
			if hours and hours > 0 then
				progress = (data.Life.StageSeconds or 0) / (hours * 3600)
			end
		end)
		return {
			Rel = rel,
			Traits = story.Traits or {},
			Memories = story.Memories or {},
			LastGrade = story.LastGrade,
			Stage = (data.Life or {}).Stage or "Nino",
			ClockTime = clock,
			Weekday = weekday,
			Completed = story.Completed or {},
			Flags = story.Flags or {},
			Choices = story.Choices or {},
			Discovered = story.Discovered or {},
			StageProgress = progress,
			Season = workspace:GetAttribute("Season"),
			Weather = workspace:GetAttribute("Weather"),
			World = story.World,
		}
	end,
	duties = function(player: Player): { [string]: boolean }?
		local ok, duties = pcall(function()
			return require(script.Parent.RoleService).dutiesOf(player)
		end)
		return if ok then duties else nil
	end,
	events = function(): any
		return require(script.Parent.Parent.LifeStory.StoryEvents)
	end,
	-- Bajarse del vehículo antes de la escena (CinematicService.leaveVehicle)
	dismount = function(player: Player)
		require(script.Parent.CinematicService).leaveVehicle(player)
	end,
	-- ¿Hay algo en ese sitio donde no cabe una persona de pie? (un coche aparcado, una farola, una
	-- pared). floorY (opcional): la altura del suelo donde estás tú; si el suelo de ahí está mucho más
	-- alto, es que hay algo encima (el techo de un coche).
	blocked = function(position: Vector3, floorY: number?): boolean
		local ok, hit = pcall(function()
			local feet = deps.ground(position)
			if floorY and feet.Y - floorY > 1.6 then
				return true
			end
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = sceneSkip()
			-- (el cuerpo, de la rodilla a la cabeza: una alfombra o un escalón no cuentan)
			for _, part in workspace:GetPartBoundsInBox(CFrame.new(feet + Vector3.new(0, 3.1, 0)), Vector3.new(1.4, 3, 1.4), params) do
				if part.CanCollide and part.Transparency < 0.95 and not part:IsA("Terrain") then
					return true
				end
			end
			-- (y la decoración que se ve pero las consultas no: el respaldo de un banco, un seto, un sofá)
			local okDecor, decor = pcall(function()
				return require(script.Parent.Parent.World.SafeSpot).decorAt(feet)
			end)
			return okDecor and decor == true
		end)
		return ok and hit == true
	end,
	-- A cuánto está la pared más cercana (en horizontal, a la altura del pecho y por encima de los
	-- muebles: solo cuentan las paredes, columnas, puertas…), hasta `limit`; math.huge si no hay ninguna
	wallGap = function(position: Vector3, limit: number?): number
		local ok, gap = pcall(function()
			local feet = deps.ground(position)
			local reach = limit or ActorStaging.WallGap
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = sceneSkip()
			params.RespectCanCollide = true
			local best = math.huge
			for i = 0, 7 do
				local a = i * math.pi / 4
				local dir = Vector3.new(math.cos(a), 0, math.sin(a)) * reach
				-- (a 3,4: por encima de los muebles; a 2,2 solo lo alto, ActorStaging.WALL_TALL: la pared
				-- de debajo de una ventana, que a 3,4 ya es el hueco)
				for _, h in ActorStaging.WallRayHeights do
					local hit = workspace:Raycast(feet + Vector3.new(0, h, 0), dir, params)
					if hit and (h >= 3 or (hit.Instance:IsA("BasePart") and hit.Instance.Size.Y >= ActorStaging.WALL_TALL)) then
						best = math.min(best, hit.Distance)
					end
				end
			end
			return best
		end)
		return if ok then gap else math.huge
	end,
	-- Tú, metido en una pared o en un mueble al empezar la escena (en un primer plano se veía tu cara
	-- dentro de la pared): al hueco libre más cerca de la misma sala (la misma regla que los actores)
	unstick = function(player: Player)
		local root = deps.root(player)
		if not root then
			return
		end
		local feet = deps.ground(root.Position)
		if not deps.blocked(feet) then
			return
		end
		local free = ActorStaging.freeMark(feet, {}, nil, nil, function(q: Vector3): boolean
			return not deps.blocked(q) and deps.reachable(feet, q)
		end)
		if free ~= feet then
			deps.scene().teleportTo(player, deps.ground(free))
		end
	end,
	-- Girar al jugador (solo en horizontal) hacia donde mira el ancla de la escena
	turn = function(player: Player, cf: CFrame)
		local character = player.Character
		if character then
			local pivot = character:GetPivot()
			character:PivotTo(CFrame.new(pivot.Position) * cf.Rotation)
		end
	end,
}
HappeningService.deps = deps

-- (LifeStoryService, antes de una conversación escenificada: que no empiece contigo dentro de la pared)
function HappeningService.unstick(player: Player)
	pcall(deps.unstick, player)
end

function HappeningService._inject(overrides: { [string]: any })
	for k, v in overrides do
		(deps :: any)[k] = v
	end
end

---------------------------------------------------------------------
-- Condiciones de las variantes (en el servidor, al empezar)
---------------------------------------------------------------------
-- Una función req -> boolean con la partida de este jugador. Late: opts.Late o el atributo StoryLate
-- (lo pone la historia si llegó tarde al paso). Items = { Objeto = n }: tener al menos n en la mochila.
function HappeningService.checker(player: Player, opts: { [string]: any }?): (req: { [string]: any }) -> boolean
	local options = opts or {}
	local data: { [string]: any }? = nil
	pcall(function()
		data = deps.profile(player)
	end)
	local ctx: { [string]: any }? = nil
	return function(req: { [string]: any }): boolean
		if type(req) ~= "table" then
			return true
		end
		local rest = table.clone(req)
		if rest.Late ~= nil then
			local late = options.Late
			if late == nil then
				late = player:GetAttribute("StoryLate") == true
			end
			if (late == true) ~= (rest.Late == true) then
				return false
			end
			rest.Late = nil
		end
		if rest.Items ~= nil then
			local items = (data and data.Items) or {}
			for id, n in rest.Items do
				if ((items[id] or 0) :: number) < (tonumber(n) or 1) then
					return false
				end
			end
			rest.Items = nil
		end
		if next(rest) == nil then
			return true
		end
		if not data or not data.Story then
			return false -- (sin partida cargada: la escena de siempre)
		end
		if not ctx then
			local ok, built = pcall(deps.context, player, data :: any)
			ctx = if ok then built else nil
		end
		if not ctx then
			return false
		end
		if rest.OnDuty and (ctx :: any).Duties == nil then
			(ctx :: any).Duties = deps.duties(player) or {}
		end
		local ok, result = pcall(function()
			return require(ReplicatedStorage.Shared.LifeStory.Conditions).check(rest, ctx :: any)
		end)
		return ok and result == true
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

-- A quién mira un actor, dicho para el cliente (ActorLife / HappeningClient). `model` (opcional) para
-- las miradas que dependen de él: "Suelo" (vergüenza) y "Away" (piensa, aparta la mirada).
local function lookTarget(run: Run, at: any, model: Model?): any
	if at == nil or at == false then
		return nil
	end
	if (at == "Suelo" or at == "Floor" or at == "Away" or at == "Apartar") and model then
		local ok, cf = pcall(function()
			return model:GetPivot()
		end)
		if not ok or not cf then
			return nil
		end
		if at == "Suelo" or at == "Floor" then
			return cf.Position + cf.LookVector * 2.5 + Vector3.new(0, -3, 0)
		end
		return cf.Position + (cf.LookVector * 0.4 + cf.RightVector).Unit * 8 + Vector3.new(0, 0.8, 0)
	end
	if at == "Player" or at == "Yo" and not (run.Def.Anchors and run.Def.Anchors.Yo) or run.Def.Anchors and run.Def.Anchors[at] == "Player" then
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
		for _, other in run.Participants or {} do
			if other.Parent then
				remote:FireClient(other, kind, payload)
			end
		end
	end
end

-- Quiénes la viven (para que no se escondan unos a otros en los planos: SceneClient)
local function companionsOf(run: Run): { number }
	local list = { run.Player.UserId }
	for _, other in run.Participants or {} do
		table.insert(list, other.UserId)
	end
	return list
end

-- Nombres y voces de quien habla (los del reparto, las criaturas y los actores de la escena)
local function speakers(player: Player, def: { [string]: any }): ({ [string]: string }, { [string]: string })
	local names, voices = {}, {}
	local Cast = require(ReplicatedStorage.Shared.LifeStory.Cast)
	local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
	local StoryCreatures = require(ReplicatedStorage.Shared.LifeStory.StoryCreatures)
	local CastVoices = require(ReplicatedStorage.Shared.LifeStory.CastVoices)
	local spawnSpecs = {}
	for _, d in (def.Tracks or {}).Actors or {} do
		local spec = d.Spawn or d.Enter or d.Use
		if type(spec) == "table" and spec.Key then
			spawnSpecs[spec.Key] = spec
		end
	end
	local all = {}
	for _, line in (def.Tracks or {}).Lines or {} do
		table.insert(all, line)
	end
	for _, line in (def.Tracks or {}).Dialogue or {} do
		table.insert(all, line)
	end
	for _, line in all do
		local who = line.Speaker or line.S
		local named = if type(who) == "string" and type(def.Speakers) == "table" then def.Speakers[who] else nil
		if type(who) == "string" and names[who] == nil and type(named) == "table" then
			-- (quien habla sin ser del reparto, con su nombre y su voz: la rectora de las cabeceras)
			local okName, text = pcall(function()
				return Strings.get(named.Name or who)
			end)
			names[who] = if okName and type(text) == "string" then text else who
			voices[who] = if type(named.Voice) == "string" then named.Voice else who
		elseif type(who) == "string" and names[who] == nil then
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
					-- (una criatura con voz propia en CastVoices, como Chispa; si no, la de un niño)
					voices[who] = if CastVoices.People[who] then who else "Nino"
				elseif Cast.People[npc] then
					local ok, text = pcall(function()
						return Strings.get(Cast.nameOf(npc, { FamilyKey = player:GetAttribute("FamilyKey"), AbuKey = player:GetAttribute("AbuKey") }))
					end)
					names[who] = if ok then text else npc
					voices[who] = npc -- (su voz: CastVoices, la de ese personaje)
				else
					names[who] = (spec and spec.Name) or who
					voices[who] = who -- (no está en el reparto: una voz fija para su nombre)
				end
			end
		end
	end
	return names, voices
end

-- Variables de los textos de la escena, las mismas que en las conversaciones (DialogueService): {nombre},
-- {abu}, {familia}, {Saludo} y el género del jugador (atributo Gender) para «{o/a}». Sin género conocido,
-- Strings deja la forma neutra con barra («encargado/a»).
local function textArgs(player: Player): { [string]: any }
	local args: { [string]: any } = { nombre = player.DisplayName }
	local gender = player:GetAttribute("Gender")
	if gender ~= nil then
		args.genero = gender
	end
	pcall(function()
		local Cast = require(ReplicatedStorage.Shared.LifeStory.Cast)
		local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
		local attrs = { FamilyKey = player:GetAttribute("FamilyKey"), AbuKey = player:GetAttribute("AbuKey") }
		args.abu = Strings.get(Cast.nameOf("Abu", attrs))
		args.familia = Strings.get(Cast.nameOf("Familia", attrs))
	end)
	pcall(function()
		local greeting = require(script.Parent.DialogueService).greeting()
		args.Saludo = greeting
		args.saludo = greeting:lower()
	end)
	return args
end
HappeningService._textArgs = textArgs

---------------------------------------------------------------------
-- Pistas del servidor
---------------------------------------------------------------------
local function actorModel(run: Run, key: string): Model?
	local entry = run.Actors[key]
	return entry and entry.Model or nil
end

-- Dónde va un actor según su Anchor + Offset (su marca)
local function markOf(run: Run, spec: { [string]: any }): (Vector3, CFrame)
	local base = run.Anchors[spec.Anchor or ""] or (deps.root(run.Player) and (deps.root(run.Player) :: BasePart).CFrame) or CFrame.new()
	return base.Position + (if typeof(spec.Offset) == "Vector3" then spec.Offset else Vector3.zero), base
end

-- Dónde están los demás (pies): tú y los otros actores de la escena (su marca o, si no la tiene,
-- donde está ahora)
local function occupied(run: Run, except: string): { Vector3 }
	local list = {}
	local root = deps.root(run.Player)
	if root then
		table.insert(list, root.Position - Vector3.new(0, 3, 0))
	end
	for key, entry in run.Actors do
		if key ~= except then
			local mark = run.Marks[key]
			if not mark and entry.Model then
				pcall(function()
					mark = (entry.Model :: Model):GetPivot().Position - Vector3.new(0, 3, 0)
				end)
			end
			if mark then
				table.insert(list, mark)
			end
		end
	end
	return list
end

-- La marca de un actor validada: sin meterse en nadie (ActorStaging.freeMark) ni dentro de algo del
-- mapa (si cae en un coche aparcado o una farola, el sitio libre más cerca). Queda apuntada.
local function settle(run: Run, key: string, mark: Vector3): Vector3
	-- (solo sitios a los que se llega andando desde su marca: misma sala, mismo suelo. Si no hay
	-- ninguno, se queda en su marca aunque roce a alguien: mejor eso que acabar fuera de la casa)
	-- (y nunca pegado a una pared: a ActorStaging.WallGap como poco, sea la sala grande o pequeña. En el
	-- nacimiento los padres salían aplastados contra la pared del cuarto y la cámara dentro de ella)
	local p = ActorStaging.freeMark(mark, occupied(run, key), nil, nil, function(q: Vector3): boolean
		return not deps.blocked(q) and deps.reachable(mark, q) and deps.wallGap(q) >= ActorStaging.WallGap
	end)
	if (p - mark).Magnitude > 0.05 then
		p = deps.ground(p)
	end
	run.Marks[key] = p
	return p
end

-- ¿Te habla a ti en la escena? (alguna frase suya con To = "Yo"/"Player")
local function talksToYou(run: Run, key: string): boolean
	for _, line in ((run.Def.Tracks or {}).Dialogue or {}) :: { any } do
		if type(line) == "table" and line.S == key and ActorStaging.isPlayer(line.To) then
			return true
		end
	end
	return false
end

-- Quien te habla, en TU sala (vídeo de los primeros pasos: Papá aparecía en la cocina hablándole al bebé,
-- que estaba en el salón, y la cámara enseñaba una pared). Si su marca está en otra sala y estás cerca, se
-- pone a unos pasos de ti, del lado de su marca, donde se llega andando desde ti.
local function nearYou(run: Run, key: string, position: Vector3): Vector3
	if not talksToYou(run, key) then
		return position
	end
	local root = deps.root(run.Player)
	if not root then
		return position
	end
	local me = deps.ground(root.Position)
	local away = Vector3.new(position.X - me.X, 0, position.Z - me.Z)
	-- (hasta NEAR_YOU_MAX: en la casa de 64 × 64 la cocina queda a más de 40 del salón y Mamá se quedaba
	-- allí, hablándole al bebé a través del hueco de la puerta)
	if away.Magnitude > ActorStaging.NearYouMax or (away.Magnitude <= ActorStaging.TalkFar and deps.reachable(me, position)) then
		return position
	end
	local dir = if away.Magnitude > 0.5 then away.Unit else Vector3.new(0, 0, -1)
	for _, turn in { 0, 45, -45, 90, -90, 135, -135, 180 } do
		local c, sn = math.cos(math.rad(turn)), math.sin(math.rad(turn))
		local d = Vector3.new(dir.X * c - dir.Z * sn, 0, dir.X * sn + dir.Z * c)
		local spot = deps.ground(me + d * ActorStaging.TalkGap)
		if deps.reachable(me, spot) and not deps.blocked(spot) and deps.wallGap(spot) >= ActorStaging.WallGap then
			return spot
		end
	end
	return position
end

-- Las marcas de la escena que van contigo (Enter.To = { "Yo", offset, true }): si alguna cae dentro de
-- algo (te bajaste junto a tu coche, hay una farola), la escena se gira a tu alrededor hasta que caben
-- todas, y tú con ella (ActorStaging.clearFacing)
local function stagePlayer(run: Run)
	local def = run.Def
	for name, anchor in def.Anchors or {} do
		if anchor ~= "Player" or not run.Anchors[name] then
			continue
		end
		local offsets = {}
		for _, d in (def.Tracks or {}).Actors or {} do
			local spec = type(d) == "table" and (d.Enter or d.Move) or nil
			local to = type(spec) == "table" and (spec.To or spec.At) or nil
			if type(to) == "table" and to[1] == name and to[3] and typeof(to[2]) == "Vector3" then
				table.insert(offsets, to[2])
			end
		end
		if #offsets == 0 then
			continue
		end
		local base = run.Anchors[name]
		local floor = deps.ground(base.Position).Y
		local cf, yaw = ActorStaging.clearFacing(base, offsets, function(p: Vector3): boolean
			return deps.blocked(p, floor)
		end)
		if yaw ~= 0 then
			run.Anchors[name] = cf
			pcall(deps.turn, run.Player, cf)
		end
	end
end

-- Un punto escrito como nombre de ancla ("Puerta") o como P = { "Ancla", offset?, local? }
local function placeOf(run: Run, spec: any): Vector3?
	if type(spec) == "string" then
		return pointOf(run, { spec })
	end
	return pointOf(run, spec)
end

-- place (opcional) = { At = Vector3 (dónde aparece), Face = Vector3? (hacia dónde mira), Walking = true (At
-- ya validado o es de donde sale andando: no se mueve) }
local function spawnActor(run: Run, spec: { [string]: any }, instant: boolean?, place: { [string]: any }?)
	local key = spec.Key
	local mark, base = markOf(run, spec)
	local position = deps.ground(if place and place.At then place.At else mark)
	if not (place and place.Walking) then
		position = nearYou(run, key, position)
		position = settle(run, key, position) -- (aparece en su sitio: sin meterse en nadie)
	end
	local face = if place and place.Face then place.Face elseif spec.Face then pointOf(run, spec.Face) else nil
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
	elseif d.Enter then
		-- Entra andando: aparece en From (la puerta, la esquina) y anda hasta su marca
		local spec = d.Enter
		local mark = if spec.To ~= nil then placeOf(run, spec.To) else nil
		mark = mark or (markOf(run, spec))
		-- (adonde llega, validado: nadie acaba metido en otro ni en un coche aparcado)
		mark = settle(run, spec.Key, deps.ground(mark))
		local from = if not instant and spec.Walk ~= false then placeOf(run, spec.From) else nil
		if from then
			spawnActor(run, spec, instant, { At = from, Face = mark, Walking = true })
			run.Marks[spec.Key] = mark
			local model = actorModel(run, spec.Key)
			if model then
				A.move(model, mark, spec.Run == true)
			end
		else
			spawnActor(run, spec, instant, { At = mark, Walking = true })
			run.Marks[spec.Key] = mark
		end
	elseif d.Exit then
		-- Se va andando hasta To y desaparece al llegar (sin To, o al saltar: ya)
		local spec = d.Exit
		local entry = run.Actors[spec.Key]
		run.Actors[spec.Key] = nil
		run.Marks[spec.Key] = nil
		run.LookFixed[spec.Key] = nil
		if not entry or not entry.Model then
			return
		end
		local model = entry.Model :: Model
		if entry.Borrowed then
			A.unbind(model) -- (a los de la misión los mueve su misión)
			return
		end
		local to = if spec.To ~= nil then placeOf(run, spec.To) else nil
		if to then
			-- (adonde se va: un sitio libre y sin pared encima, de esa misma sala; StageActors.move lleva
			-- el camino y, si se atasca, se va igual)
			local goal = deps.ground(to)
			to = ActorStaging.freeMark(goal, {}, nil, nil, function(q: Vector3): boolean
				return not deps.blocked(q) and deps.reachable(goal, q) and deps.wallGap(q) >= ActorStaging.WallGap
			end)
		end
		if instant or not to or spec.Walk == false then
			A.despawn(model)
		else
			run.Leaving[model] = true
			A.look(model, nil)
			A.move(model, deps.ground(to), spec.Run == true, function()
				run.Leaving[model] = nil
				pcall(A.despawn, model)
			end)
		end
	elseif d.Use then
		local spec = d.Use
		local model = nil
		pcall(function()
			model = deps.scene().actorOf(run.Player, spec.Npc or spec.Key)
		end)
		if model then
			A.bind(model, spec.Key)
			run.Actors[spec.Key] = { Model = model, Borrowed = true, Npc = spec.Npc or spec.Key }
			-- (el de la misión que te habla y está en otra sala viene a la tuya, como los demás: nearYou.
			-- Al acabar, su misión le devuelve andando a su sitio)
			if talksToYou(run, spec.Key) then
				local feet = nil
				pcall(function()
					feet = deps.ground(model:GetPivot().Position)
				end)
				if feet then
					local near = nearYou(run, spec.Key, feet)
					if (near - feet).Magnitude > 0.5 then
						near = settle(run, spec.Key, near)
						A.place(model, near) -- (la escena empieza con un corte: ya está ahí)
						A.look(model, "Player")
					end
				end
			end
		else
			-- No está (la misión no está activa: la Cinemateca, o se fue): aparece en SU MARCA si se sabe
			-- (StandIns) y, si la escena no dice dónde, en semicírculo delante de ti, mirándote. Antes salían
			-- todos encima de ti, amontonados a tu espalda (v125.5, capturas de la Cinemateca).
			local npc = spec.Npc or spec.Key
			local mark = run.StandIns and run.StandIns[npc]
			local root = deps.root(run.Player)
			if mark then
				spawnActor(run, spec, instant, { At = mark.Position, Face = if root then root.Position else nil })
			elseif spec.Anchor == nil and spec.Offset == nil and root then
				run.Formation = (run.Formation or 0) + 1
				spawnActor(run, spec, instant, { At = HappeningService.formationSpot(root.CFrame, run.Formation), Face = root.Position })
			else
				spawnActor(run, spec, instant)
			end
		end
	elseif d.Move then
		local model = actorModel(run, d.Move.Key)
		local to = pointOf(run, d.Move.To)
		if model and to then
			local entry = run.Actors[d.Move.Key]
			if entry and entry.Borrowed then
				return -- (a los de la misión los mueve su misión)
			end
			to = settle(run, d.Move.Key, deps.ground(to))
			if instant then
				A.place(model, to)
			else
				A.move(model, to, d.Move.Run == true)
			end
		end
	elseif d.Look then
		local key = d.Look.Key
		local model = actorModel(run, key)
		if model then
			if d.Look.At == "Speaker" then
				-- Vuelve a mirar a quien habla
				run.LookFixed[key] = nil
				local target = nil
				if run.Speaker then
					target = if key == run.Speaker then run.SpeakerTo elseif run.Speaker == "Yo" then "Player" else "Key:" .. run.Speaker
				end
				A.look(model, target)
			else
				if not d.Look.Beat then
					run.LookFixed[key] = true -- (su propia mirada manda sobre «mirar a quien habla»)
				end
				A.look(model, lookTarget(run, d.Look.At, model))
			end
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
				-- (el bocadillo se queda al menos lo que se tarda en leerlo)
				local seconds = math.max(tonumber(d.Say.Seconds) or 0, ReadingTime.seconds(d.Say.Text))
				require(script.Parent.Parent.World.Npc).say(model, d.Say.Text, seconds)
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

-- Una frase (pista Dialogue, o Lines con Look = "Speaker"): las miradas. Todo el reparto que no tenga
-- una mirada propia mira a quien habla; quien habla mira a To, a quien habló antes o a ti.
local function applyDialogue(run: Run, line: { [string]: any })
	if run.Def.Look == false then
		return
	end
	local speaker = line.S or line.Speaker
	if type(speaker) ~= "string" or speaker == "Narrador" then
		return
	end
	local previous = run.LastSpeaker
	local to = line.To
	if to == nil then
		to = if previous ~= nil and previous ~= speaker then previous else "Player"
	end
	run.Speaker = speaker
	run.SpeakerTo = lookTarget(run, to)
	run.LastSpeaker = speaker
	local atSpeaker = if speaker == "Yo" then "Player" elseif run.Actors[speaker] then "Key:" .. speaker else nil
	local A = deps.actors()
	for key, entry in run.Actors do
		if entry.Model and not run.LookFixed[key] then
			if key == speaker then
				A.look(entry.Model, run.SpeakerTo)
			elseif atSpeaker then
				A.look(entry.Model, atSpeaker)
			end
		end
	end
end

local function applyEvent(run: Run, e: Sequencer.Event, instant: boolean)
	if not Sequencer.passes(e.Data, run.Inputs) then
		return
	end
	if e.Track == "Dialogue" or e.Track == "Lines" then
		if not instant then
			local ok, err = pcall(applyDialogue, run, e.Data)
			if not ok then
				warn(("[Happening] %s: diálogo: %s"):format(run.Id, tostring(err)))
			end
		end
		return
	end
	if e.Track == "World" then
		if run.Sandbox then
			return -- (Cinemateca: se mira, no se apunta nada en tu mundo)
		end
		pcall(function()
			deps.world().apply(run.Player, e.Data.Set)
		end)
		for _, other in run.Participants or {} do
			pcall(function()
				deps.world().apply(other, e.Data.Set)
			end)
		end
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
-- skipped = la saltó (o murió, o se fue); complete = acabó por Until antes de tiempo. En los dos casos
-- lo que faltaba de servidor se deja hecho (las consecuencias son las mismas que viéndola entera).
local function finish(run: Run, skipped: boolean, complete: boolean?)
	if run.Done then
		return
	end
	if skipped or complete then
		local onSkip = if skipped and type(run.Def.OnSkip) == "table" then run.Def.OnSkip else nil
		if onSkip and type(onSkip.Inputs) == "table" then
			-- Las esperas que no llegaron a pasar: lo que la escena da por hecho al saltarla
			for name, value in onSkip.Inputs do
				if run.Inputs[name] == nil then
					run.Inputs[name] = value == true
				end
			end
		end
		for _, e in Sequencer.skipPlan(run.Timeline, run.Cursor, run.Inputs) do
			applyEvent(run, e, true)
		end
		if onSkip and type(onSkip.World) == "table" and not run.Sandbox then
			pcall(function()
				deps.world().apply(run.Player, onSkip.World)
			end)
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
	-- Los que se iban andando: se van al llegar (o ya, si se saltó o el jugador no está)
	for model in run.Leaving do
		if A then
			if skipped or not run.Player.Parent then
				pcall(A.despawn, model)
			else
				local actors = A
				deps.later(25, function()
					pcall(actors.despawn, model)
				end)
			end
		end
	end
	table.clear(run.Leaving)
	send(run, "Stop", { Skipped = skipped })
	local list = runs[run.Player]
	if list then
		list[run.Serial] = nil
		if next(list) == nil then
			runs[run.Player] = nil
		end
	end
	-- La historia sigue (el paso de cine que la lanzó). En la Cinemateca no hay historia que seguir.
	if not run.Sandbox then
		pcall(function()
			deps.cinematic().clientDone(run.Player, run.Id)
		end)
	end
	for _, fn in finishedListeners do
		task.spawn(fn, run.Player, run.Id, skipped)
	end
	-- (Group) quien la vivía contigo acaba con ella: su historia sigue igual
	local participants = run.Participants or {}
	run.Participants = {}
	for _, other in participants do
		pcall(function()
			deps.cinematic().clientDone(other, run.Id)
		end)
		for _, fn in finishedListeners do
			task.spawn(fn, other, run.Id, skipped)
		end
	end
	table.clear(run.Spectators)
	bySerial[run.Serial] = nil
end

-- (Group) Alguien deja la escena de otro (la salta, muere, se va del juego): solo él. Si la saltó, se
-- le deja hecho lo que faltaba de la memoria del mundo (como al saltar la suya); su historia sigue.
-- gone = se ha ido del juego (no hay a quién avisar).
function HappeningService.detach(run: Run, who: Player, skipped: boolean, gone: boolean?)
	local index = table.find(run.Participants or {}, who)
	if not index then
		return false
	end
	table.remove(run.Participants, index)
	if not gone then
		if skipped then
			for _, e in Sequencer.skipPlan(run.Timeline, run.Cursor, run.Inputs) do
				if e.Track == "World" then
					pcall(function()
						deps.world().apply(who, e.Data.Set)
					end)
				end
			end
		end
		local remote = deps.remote()
		if remote and who.Parent then
			remote:FireClient(who, "Stop", { Run = run.Serial, Id = run.Id, Skipped = skipped })
		end
		pcall(function()
			deps.cinematic().clientDone(who, run.Id)
		end)
		for _, fn in finishedListeners do
			task.spawn(fn, who, run.Id, skipped)
		end
	end
	send(run, "Party", { Companions = companionsOf(run) })
	return true
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
	if run.Frozen then
		return -- (Cinemateca: el reloj está parado mientras se escribe el comentario)
	end
	local now = deps.now()
	if now < run.StartAt then
		return
	end
	-- Condición de final (Until): llegó el aviso, o se acabó la escena y ya no se espera más
	if run.UntilMet then
		finish(run, false, true)
		return
	end
	if run.Holding then
		if now - run.HoldSince >= Sequencer.untilTimeout(run.Def.Until or {}) then
			finish(run, false, true)
		end
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
	local linesLook = run.Def.Look == "Speaker"
	for _, e in Sequencer.due(run.Timeline, run.Cursor, t, nil) do
		local side = Sequencer.sideOf(e.Track)
		if side == "Client" and not (linesLook and e.Track == "Lines") then
			continue
		end
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
		if type(run.Def.Until) == "table" then
			-- Se queda en el último plano hasta que llegue el aviso (o el tope)
			run.Holding = true
			run.HoldSince = now
			run.PausedAt = run.StartAt + run.Paused + run.Timeline.Duration
			send(run, "Pause", { At = run.Timeline.Duration, Until = true })
			return
		end
		finish(run, false)
	end
end

-- (World) Quién ve ahora el acontecimiento: los que están cerca y no lo viven ya. Quien llega a mitad
-- recibe la escena con el reloj de ahora (mismo StartAt y pausas: ve lo que queda); quien se aleja (con
-- un margen, para no parpadear en el borde) o se va del juego deja de verla. Nadie pierde el control.
local function refreshAudience(run: Run)
	if run.Scope ~= "World" or run.Done then
		return
	end
	run.AudienceAt = deps.now()
	local radius = tonumber(run.Def.AudienceRadius) or HappeningService.WORLD_RADIUS
	-- (cerca de quien la vive o de donde pasa algo: los tres cráteres del meteorito están lejos del garaje)
	local centers: { Vector3 } = {}
	local ownerRoot = deps.root(run.Player)
	if ownerRoot then
		table.insert(centers, ownerRoot.Position)
	end
	for name, cf in run.Anchors do
		if (run.Def.Anchors or {})[name] ~= "Rift" then
			table.insert(centers, cf.Position)
		end
	end
	local function distance(position: Vector3): number
		local best = math.huge
		for _, c in centers do
			best = math.min(best, (position - c).Magnitude)
		end
		return best
	end
	local remote = deps.remote()
	for i = #run.Spectators, 1, -1 do
		local spectator = run.Spectators[i]
		local root = deps.root(spectator)
		local far = not root or distance(root.Position) > radius * 1.25
		if not spectator.Parent or far then
			table.remove(run.Spectators, i)
			if spectator.Parent and remote and run.Payload then
				remote:FireClient(spectator, "Stop", { Run = run.Serial, Id = run.Id, Skipped = false })
			end
		end
	end
	for _, other in Players:GetPlayers() do
		if other ~= run.Player and not isIn(run.Spectators, other) and not isIn(run.Participants, other) then
			local root = deps.root(other)
			if root and distance(root.Position) <= radius then
				table.insert(run.Spectators, other)
				if remote and run.Payload then
					local copy = table.clone(run.Payload)
					copy.Run, copy.Id, copy.Spectator = run.Serial, run.Id, true
					copy.Paused = run.Paused
					copy.Companions = nil
					remote:FireClient(other, "Play", copy)
				end
			end
		end
	end
end
HappeningService._refreshAudience = refreshAudience

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
	-- (Group) o vive la de otro
	for _, run in bySerial do
		if not run.Done and (id == nil or run.Id == id) and isIn(run.Participants or {}, player) then
			return true
		end
	end
	return false
end

-- (Group) La escena de otro jugador a la que te puedes unir: la misma, cerca de ti y recién empezada
function HappeningService.joinable(player: Player, id: string): Run?
	local mine = deps.root(player)
	if not mine then
		return nil
	end
	local now = deps.now()
	for _, run in bySerial do
		if run.Id == id and not run.Done and run.Scope == "Group" and run.Player ~= player and run.Player.Parent
			and not isIn(run.Participants, player) then
			local host = deps.root(run.Player)
			local started = run.StartAt > 0 and run.StartAt < math.huge
			local elapsed = if started then Sequencer.sceneTime(run, now) else 0
			if host and (host.Position - mine.Position).Magnitude <= HappeningService.GROUP_RADIUS and elapsed <= HappeningService.GROUP_JOIN then
				return run
			end
		end
	end
	return nil
end

-- (Group) Te unes a la escena de otro: tu cámara, su reloj y sus actores. Devuelve cuánto puede durar.
function HappeningService.join(run: Run, player: Player): number
	-- (tu otra escena con cámara, si la había, se salta: una a la vez)
	for _, other in runs[player] or {} do
		if not other.Light and not other.Done then
			finish(other, true)
		end
	end
	-- La vives: te bajas del vehículo como en la tuya (a los que solo miran no se les toca)
	if run.Def.InVehicle ~= true then
		pcall(deps.dismount, player)
	end
	pcall(deps.unstick, player)
	local index = table.find(run.Spectators, player)
	if index then
		table.remove(run.Spectators, index) -- (miraba: ahora la vive)
	end
	table.insert(run.Participants, player)
	local remote = deps.remote()
	if run.Payload and remote and player.Parent then
		local copy = table.clone(run.Payload)
		copy.Run, copy.Id = run.Serial, run.Id
		copy.Participant, copy.Host = true, run.Player.UserId
		copy.Paused = run.Paused
		copy.Companions = companionsOf(run)
		remote:FireClient(player, "Play", copy)
	end
	send(run, "Party", { Companions = companionsOf(run) })
	pcall(function()
		deps.cinematic().clientSeen(player, run.Id)
	end)
	local left = Sequencer.maxDuration(run.Timeline) + STREAM_WAIT + LEAD + 1
	if run.StartAt > 0 and run.StartAt < math.huge then
		left = math.max(1, left - Sequencer.sceneTime(run, deps.now()))
	end
	return left
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
	-- Variantes y condiciones: se eligen aquí, con la partida del jugador (el cliente recibe lo elegido)
	local choice = { Variant = nil, Gates = {} }
	local okChoice, resolved = pcall(Sequencer.resolve, def, HappeningService.checker(player, options))
	if okChoice and type(resolved) == "table" then
		choice = resolved
	elseif not okChoice then
		warn(("[Happening] %s: no se pudieron mirar las condiciones: %s"):format(id, tostring(resolved)))
	end
	local timeline = Sequencer.compile(id, def, choice)
	def = timeline.Def or def
	local light = Sequencer.isLight(def)
	local scope = HappeningService.scopeOf(def)
	if options.Sandbox == true then
		scope = "Personal" -- (Cinemateca: solo la ve quien la revisa; nadie se une ni mira)
	end
	-- (Group) ¿Alguien cerca está empezando la misma escena? Te unes a la suya (fase 7)
	if scope == "Group" and not light and options.Instant ~= true and deps.remote() ~= nil then
		local host = HappeningService.joinable(player, id)
		if host then
			return HappeningService.join(host, player)
		end
	end
	-- Una escena con cámara a la vez por jugador: si había otra, se salta (sus consecuencias quedan).
	-- Salvo si una de las dos ESPERA SU TURNO (Queue / AfterScene: las cabeceras y finales de capítulo y
	-- las cinemáticas de siempre, Happenings/Capitulos): entonces la nueva sale cuando acabe la otra
	-- (como mucho QUEUE_MAX s; pasado ese rato, la otra se salta como siempre). Antes esto lo hacía la
	-- cola de la pantalla de las cinemáticas viejas (fase 6: un solo motor).
	local behind: { Run } = {}
	if not light then
		for _, other in runs[player] or {} do
			if not other.Light and not other.Done then
				if options.Instant ~= true and HappeningService.queues(def, other.Def) then
					table.insert(behind, other)
				else
					finish(other, true)
				end
			end
		end
	end
	-- Una escena con cámara: antes de nada, te bajas del vehículo (la bici, el coche…): si no, la escena
	-- empezaba contigo montado y los actores se metían en él (las anclas se miran ya con los pies en el
	-- suelo). InVehicle = true en la escena: se queda como está. (Si espera turno, al empezar de verdad.)
	local function settleBody()
		if not light and options.Instant ~= true and def.InVehicle ~= true then
			pcall(deps.dismount, player)
		end
		if not light and options.Instant ~= true then
			pcall(deps.unstick, player)
		end
	end
	if #behind == 0 then
		settleBody()
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
		Sandbox = options.Sandbox == true or nil,
		StandIns = if type(options.StandIns) == "table" then options.StandIns else nil,
		Spectators = {},
		PortalAt = 0,
		Choice = choice,
		LookFixed = {},
		Speaker = nil,
		SpeakerTo = nil,
		LastSpeaker = nil,
		Leaving = {},
		Marks = {},
		Holding = false,
		HoldSince = 0,
		UntilMet = false,
		AdvancedAt = -math.huge,
		Scope = scope,
		Participants = {},
	}
	runs[player] = runs[player] or {}
	runs[player][run.Serial] = run
	bySerial[run.Serial] = run
	if #behind > 0 then
		run.Queued = true
		run.StartAt = math.huge -- (no corre hasta que le toque: step no hace nada)
	end
	if not light and not run.Instant and #behind == 0 then
		pcall(stagePlayer, run)
	end
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
	-- Quién más lo ve (solo lo que pasa en el mundo, sin cámara ni bloqueos): alcance World
	if scope == "World" then
		refreshAudience(run)
	end
	local names, voices = speakers(player, def)
	-- Lo que puede tardar en llegarle el turno (para el tope de quien espera: CinematicService.waitFor)
	local queueWait = 0
	for _, other in behind do
		local okLeft, left = pcall(function()
			local elapsed = if other.StartAt < math.huge then math.max(0, deps.now() - other.StartAt - other.Paused) else 0
			return Sequencer.maxDuration(other.Timeline) - elapsed + LEAD + 1
		end)
		queueWait = math.max(queueWait, if okLeft and type(left) == "number" then left else HappeningService.QUEUE_MAX)
	end
	queueWait = math.clamp(queueWait, 0, HappeningService.QUEUE_MAX)
	task.spawn(function()
		if #behind > 0 then
			-- Espera su turno: sale cuando acaben las de delante (o, pasado el tope, las corta)
			local since = deps.now()
			while not run.Done and player.Parent do
				local busy = false
				for _, other in behind do
					busy = busy or not other.Done
				end
				if not busy then
					break
				end
				if deps.now() - since >= HappeningService.QUEUE_MAX then
					for _, other in behind do
						finish(other, true)
					end
					break
				end
				deps.wait(0.2)
			end
			if run.Done or not player.Parent then
				return
			end
			run.Queued = nil
			-- Ahora sí: las anclas donde estás AHORA, te bajas del vehículo y la escena se coloca
			run.Anchors = HappeningService.resolveAnchors(player, def)
			settleBody()
			if not light then
				pcall(stagePlayer, run)
			end
			if streamWait > 0 then
				local now: { Vector3 } = {}
				for _, cf in run.Anchors do
					table.insert(now, cf.Position)
				end
				deps.stream(player, now, streamWait)
			end
		end
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
			Args = textArgs(player),
			Light = light,
			Skippable = def.Skippable ~= false,
			Variant = choice.Variant,
			Gates = choice.Gates,
		}
		-- (Cinemateca) La gente del paso que la escena no trae ella misma (la foto de grupo: «Todos»
		-- celebran) aparece en su marca, mirándote; se va al acabar
		if run.StandIns and run.Sandbox then
			local named = Sequencer.actorKeys(def)
			local root = deps.root(player)
			for npc, mark in run.StandIns do
				if not named[npc] and not run.Actors[npc] then
					pcall(spawnActor, run, { Key = npc, Npc = npc }, false, { At = mark.Position, Face = if root then root.Position else nil })
				end
			end
		end
		payload.Companions = companionsOf(run)
		run.Payload = payload
		send(run, "Play", payload)
		for _, other in run.Participants do
			local remoteNow = deps.remote()
			if remoteNow and other.Parent then
				local copy = table.clone(payload)
				copy.Run, copy.Id = run.Serial, run.Id
				copy.Participant, copy.Host = true, player.UserId
				remoteNow:FireClient(other, "Play", copy)
			end
		end
		for _, spectator in run.Spectators do
			local remoteNow = deps.remote()
			if remoteNow and spectator.Parent then
				local copy = table.clone(payload)
				copy.Companions = nil
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
			if run.Scope == "World" and not run.Done and deps.now() - (run.AudienceAt or 0) >= HappeningService.WORLD_EVERY then
				pcall(refreshAudience, run)
			end
			deps.wait(TICK)
		end
	end)
	return Sequencer.maxDuration(timeline) + streamWait + LEAD + 1 + queueWait
end

-- ¿La escena nueva (def) espera su turno detrás de la que ya está (other) en vez de cortarla?
HappeningService.QUEUE_MAX = 60 -- segundos, como mucho (una escena colgada no para la siguiente)
function HappeningService.queues(def: { [string]: any }, other: { [string]: any }?): boolean
	local function waits(d: { [string]: any }?): boolean
		return type(d) == "table" and (d.Queue == true or d.AfterScene == true)
	end
	return waits(def) or waits(other)
end

-- Dónde va el suplente número n que no tiene marca: en semicírculo delante de ti (a 6 studs, de izquierda
-- a derecha; a partir del sexto, una fila más atrás), para que nadie se meta en nadie ni te tape
function HappeningService.formationSpot(me: CFrame, n: number): Vector3
	local row = math.floor((n - 1) / 5)
	local k = (n - 1) % 5
	local angle = math.rad(-60 + k * 30) -- (-60º … 60º: a 6 studs, 3 entre uno y otro)
	local radius = 6 + row * 3
	local local3 = Vector3.new(math.sin(angle) * radius, 0, -math.cos(angle) * radius)
	return me:PointToWorldSpace(local3)
end

-- (Cinemateca) Para o sigue la escena de revisión del jugador (solo las de sandbox): el reloj se queda
-- quieto en el servidor y en su pantalla mientras escribe el comentario. Devuelve si ha hecho algo.
function HappeningService.freeze(player: Player, on: boolean): boolean
	local any = false
	for _, run in runs[player] or {} do
		if run.Sandbox and not run.Done and not run.Light then
			local now = deps.now()
			if on and not run.Frozen and not run.Waiting and not run.Holding and now >= run.StartAt then
				run.Frozen = true
				run.PausedAt = now
				send(run, "Pause", { At = Sequencer.sceneTime(run, now), Freeze = true })
				any = true
			elseif not on and run.Frozen then
				run.Frozen = nil
				run.Paused += now - (run.PausedAt or now)
				run.PausedAt = nil
				send(run, "Resume", { Paused = run.Paused, Inputs = run.Inputs })
				any = true
			end
		end
	end
	return any
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

-- Murió: sus escenas se acaban YA (como saltarlas, aunque no se puedan saltar: las consecuencias
-- quedan y su pantalla lo devuelve todo)
function HappeningService.onDied(player: Player)
	for _, run in runs[player] or {} do
		finish(run, true)
	end
	for _, run in bySerial do
		if not run.Done and isIn(run.Participants or {}, player) then
			HappeningService.detach(run, player, true)
		end
	end
end

-- Un aviso de StoryEvents: ¿acaba alguna escena con Until = { Event = name, Match? }?
function HappeningService.onStoryEvent(player: Player, name: string, payload: { [string]: any }?)
	for _, run in runs[player] or {} do
		local spec = run.Def.Until
		if type(spec) == "table" and spec.Event == name and not run.Done then
			local matches = true
			for k, v in (if type(spec.Match) == "table" then spec.Match else {}) do
				if (payload or {})[k] ~= v then
					matches = false
				end
			end
			if matches then
				run.UntilMet = true
			end
		end
	end
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

-- Tocar para seguir (escenas de conversación: Sequencer.canAdvance): el reloj de la escena salta a la
-- frase siguiente (o al final, si era la última). Lo que había entre medias (miradas, gestos) se hace
-- en el siguiente paso, como siempre. Devuelve si ha saltado.
HappeningService.ADVANCE_COOLDOWN = 0.3 -- (dos toques seguidos no se comen dos frases)
function HappeningService.advance(run: Run): boolean
	if run.Done or run.Waiting or run.Holding or run.Instant then
		return false
	end
	local now = deps.now()
	if now < run.StartAt or now - run.AdvancedAt < HappeningService.ADVANCE_COOLDOWN then
		return false
	end
	if not Sequencer.canAdvance(run.Timeline) then
		return false
	end
	local t = Sequencer.sceneTime(run, now)
	local target = Sequencer.advanceTarget(run.Timeline, t, run.Inputs)
	if target <= t then
		return false
	end
	run.AdvancedAt = now
	run.Paused -= target - t -- (el reloj corre hacia delante: t = ahora − StartAt − Paused)
	send(run, "Shift", { Paused = run.Paused })
	step(run)
	return true
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
	if not run then
		-- (Group / World) La escena es de otro: quien la vive contigo solo puede dejarla (saltarla para
		-- él); quien solo mira, nada. Las esperas y los toques los decide quien la empezó.
		local other = if type(serialId) == "number" then bySerial[serialId] else nil
		if other and not other.Done and kind == "Skip" and isIn(other.Participants or {}, player) then
			HappeningService.detach(other, player, true)
		end
		return
	end
	if run.Done then
		return
	end
	if kind == "Skip" then
		if run.Def.Skippable ~= false then
			finish(run, true)
		end
	elseif kind == "Input" and type(value) == "string" and run.Waiting and run.Waiting.Data.Input == value then
		run.InputGot[value] = true
	elseif kind == "Advance" then
		HappeningService.advance(run)
	elseif kind == "Portal" and type(value) == "number" and not run.Sandbox then
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
		-- (la escena de otro que vivía o miraba: sigue para los demás)
		for _, run in bySerial do
			HappeningService.detach(run, player, true, true)
			local index = table.find(run.Spectators, player)
			if index then
				table.remove(run.Spectators, index)
			end
		end
	end)
	-- Condición de final de las escenas (Until = { Event })
	pcall(function()
		deps.events().connect(function(player, name, payload)
			HappeningService.onStoryEvent(player, name, payload)
		end)
	end)
	-- Al morir, la escena se acaba (y su pantalla lo devuelve todo)
	local function hookDeath(player: Player, character: Model)
		task.spawn(function()
			local humanoid = character:WaitForChild("Humanoid", 15) :: Humanoid?
			if humanoid and humanoid:IsA("Humanoid") then
				humanoid.Died:Connect(function()
					HappeningService.onDied(player)
				end)
			end
		end)
	end
	-- Modo pruebas: «/escena Id» lanza una escena (solo el dueño y los testers)
	local function watch(player: Player)
		if player.Character then
			hookDeath(player, player.Character)
		end
		player.CharacterAdded:Connect(function(character)
			hookDeath(player, character)
		end)
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
