-- RaceService (servidor): atletismo de verdad (Sports/RaceSim) en los pasos de la historia.
--
--   * La recta se pinta (calles, salida, meta y zonas de relevo) sobre la pista o el campo de deporte
--     más cercano (piezas «PEArea», «Pitch» o «Court» de al menos 50 de largo) mientras dura la carrera.
--   * «Preparados… listos… ¡YA!»: corres alternando los botones Izquierda y Derecha (RaceClient); si
--     te mueves o pulsas antes del disparo, salida nula. En el relevo corres la última posta y coges
--     el testigo con su botón cuando llega tu compañero.
--   * Las máquinas (rivales y compañeros) corren aquí; las personas, con su personaje (el servidor lee
--     dónde están). El resultado (puesto) vuelve a la misión (Sports/RaceStory). Siempre acaba: la
--     carrera tiene tiempo máximo y si no hay sitio, MiniGameService juega el panel de siempre.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Sports = ReplicatedStorage.Shared.Sports
local Track = require(Sports.Track)
local Race = require(Sports.RaceSim)
local Story = require(Sports.RaceStory)
local Cast = require(ReplicatedStorage.Shared.LifeStory.Cast)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Npc = require(script.Parent.Parent.World.Npc)

local RaceService = {}

local SNAPSHOT_EVERY = 1 / 15
local LANE_COLORS = { Color3.fromRGB(40, 110, 220), Color3.fromRGB(215, 60, 55), Color3.fromRGB(240, 190, 40), Color3.fromRGB(70, 180, 90), Color3.fromRGB(160, 80, 200), Color3.fromRGB(240, 130, 40) }

type Session = { [string]: any }

local sessions: { [Player]: Session } = {}
local initialized = false
local remote: RemoteEvent
local stateRemote: any
local ProgressionService: any = nil

local function rootOf(player: Player): BasePart?
	local c = player.Character
	local r = c and c:FindFirstChild("HumanoidRootPart")
	return if r and r:IsA("BasePart") then r else nil
end
local function humanoidOf(player: Player): Humanoid?
	local c = player.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end
local function feetOf(player: Player): Vector3?
	local root, humanoid = rootOf(player), humanoidOf(player)
	if not root then
		return nil
	end
	return root.Position - Vector3.new(0, (if humanoid then humanoid.HipHeight + root.Size.Y / 2 else 3), 0)
end

local function displayName(name: string?): string
	if name and Cast.People[name] then
		local ok, text = pcall(function()
			return Strings.get(Cast.nameOf(name, {}))
		end)
		if ok and type(text) == "string" then
			return text
		end
	end
	return name or "Corredor"
end

-- La pieza de deporte más cercana con sitio para una recta (o nil)
local function arenaNear(position: Vector3, minLength: number): BasePart?
	local candidates = {}
	for _, p in CollectionService:GetTagged("PEArea") do
		table.insert(candidates, p)
	end
	for _, d in workspace:GetDescendants() do
		if d:IsA("BasePart") and (d.Name == "Pitch" or d.Name == "Court") then
			table.insert(candidates, d)
		end
	end
	local best, bestD = nil, 250
	for _, p in candidates do
		if p:IsA("BasePart") and math.max(p.Size.X, p.Size.Z) >= minLength and p.Size.Y < 3 then
			local d = (p.Position - position).Magnitude
			if d < bestD then
				best, bestD = p, d
			end
		end
	end
	return best
end

-- Las calles pintadas mientras se corre
local function paint(session: Session)
	local t = session.Track
	local folder = session.Folder
	local function strip(name: string, size: Vector3, loc: Vector3, color: Color3)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Color = color
		part.Material = Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.CFrame = t.CFrame * CFrame.new(loc)
		part.Parent = folder
	end
	local width = t.Lanes * t.LaneWidth
	local white = Color3.fromRGB(245, 245, 245)
	for i = 0, t.Lanes do
		strip("LaneLine", Vector3.new(t.Length + 4, 0.06, 0.2), Vector3.new(t.Length / 2, 0.04, -width / 2 + i * t.LaneWidth), white)
	end
	strip("Salida", Vector3.new(0.4, 0.07, width), Vector3.new(0, 0.05, 0), white)
	strip("Meta", Vector3.new(0.6, 0.07, width), Vector3.new(t.Length, 0.05, 0), Color3.fromRGB(230, 40, 40))
	for lane = 1, t.Lanes do
		local p = Track.lanePoint(t, lane, -1.2)
		strip("Taco", Vector3.new(0.8, 0.3, 1), Vector3.new(p.X, 0.15, p.Z), LANE_COLORS[(lane - 1) % #LANE_COLORS + 1])
	end
	if session.Sim.Mode == "Relevo" then
		local yellow = Color3.fromRGB(250, 210, 40)
		local a, b = Race.zone(session.Sim)
		for _, x in { 0, t.Length } do
			strip("ZonaRelevo", Vector3.new(a + b, 0.065, width), Vector3.new(x + (if x == 0 then (b - a) / 2 else -(b - a) / 2), 0.045, 0), yellow)
		end
	end
end

local function spawnBot(session: Session, r: any)
	local person = r.Npc and Cast.People[r.Npc]
	local look = {
		Skin = person and person.Skin or nil,
		Hair = person and person.Hair or nil,
		Pants = person and person.Pants or nil,
		Shirt = LANE_COLORS[(r.Lane - 1) % #LANE_COLORS + 1],
		Shoes = Color3.fromRGB(240, 240, 240),
		LongHair = person and person.LongHair or nil,
	}
	local ok, model = pcall(Npc.create, displayName(r.Npc or r.Name), session.Folder, CFrame.new(Track.toWorld(session.Track, Race.position(session.Sim, r))), look)
	if not ok or not model then
		return
	end
	if math.abs(session.Scale - 1) > 0.01 then
		pcall(function()
			model:ScaleTo(session.Scale)
		end)
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if humanoid then
		humanoid.DisplayName = displayName(r.Npc or r.Name)
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	if humanoid and root then
		model:SetAttribute("FootOffset", humanoid.HipHeight + root.Size.Y / 2)
	end
	model:SetAttribute("SportId", r.Id)
	if session.Scale < 0.9 then
		model:SetAttribute("Age", "Nino")
	end
	CollectionService:AddTag(model, "StaticNpc")
	CollectionService:AddTag(model, "NamedActor")
	CollectionService:AddTag(model, "SportBot")
	session.Bots[r.Id] = model
end

local function botCFrame(session: Session, r: any, model: Model): CFrame
	local p = Track.toWorld(session.Track, Race.position(session.Sim, r))
	local dir = Track.dirToWorld(session.Track, Vector3.new(Race.direction(session.Sim, r), 0, 0))
	if session.Sim.Mode == "Natacion" then
		-- Nadando: tumbado a ras de agua
		local at = p + Vector3.new(0, 0.1, 0)
		return CFrame.lookAt(at, at + dir) * CFrame.Angles(-math.pi / 2, 0, 0)
	end
	local at = p + Vector3.new(0, (model:GetAttribute("FootOffset") :: number?) or 3, 0)
	return CFrame.lookAt(at, at + dir)
end

local function placeHuman(session: Session, r: any)
	local player = session.Player
	local character = player.Character
	local root, humanoid = rootOf(player), humanoidOf(player)
	if not character or not root then
		return
	end
	-- Un poco detrás de su línea, mirando hacia donde va a correr
	local dir = Race.direction(session.Sim, r)
	local loc = Race.position(session.Sim, r) - Vector3.new(dir * 1.4, 0, 0)
	local feet = Track.toWorld(session.Track, loc)
	local at = feet + Vector3.new(0, (if humanoid then humanoid.HipHeight + root.Size.Y / 2 else 3) + 0.1, 0)
	character:PivotTo(CFrame.lookAt(at, at + Track.dirToWorld(session.Track, Vector3.new(dir, 0, 0))))
	root.AssemblyLinearVelocity = Vector3.zero
	session.Mark = Track.toLocal(session.Track, feet)
end

local function endSession(session: Session)
	if session.Ended then
		return
	end
	session.Ended = true
	sessions[session.Player] = nil
	session.Player:SetAttribute("InSport", nil)
	remote:FireClient(session.Player, "End", {})
	session.Folder:Destroy()
end

local function deliver(session: Session, abandoned: boolean?)
	if session.Done then
		return
	end
	session.Done = true
	local result = Story.result(session.Spec, Race.outcome(session.Sim), abandoned == true)
	if result.Won and ProgressionService then
		pcall(ProgressionService.addXp, session.Player, 15, "Carrera")
	end
	endSession(session)
	if session.OnDone then
		task.spawn(session.OnDone, result)
	end
end

-- ¿Está en el agua (el mar de terreno) y hay agua libre por delante para una recta de natación?
local function swimTrack(player: Player, lanes: number): Track.Track?
	local root = rootOf(player)
	if not root or root.Position.Y > 2 then
		return nil
	end
	local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	look = if look.Magnitude > 1e-3 then look.Unit else Vector3.new(1, 0, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	params.IgnoreWater = false
	local surface = -2 -- (shared/Swim.Surface)
	local start = Vector3.new(root.Position.X, surface, root.Position.Z)
	local cf = CFrame.fromMatrix(start, look, Vector3.new(0, 1, 0))
	local track = Track.new(cf, 50, lanes, 4, "Calles")
	for lane = 1, lanes do
		for x = 0, 50, 10 do
			local p = Track.toWorld(track, Track.lanePoint(track, lane, x))
			local hit = workspace:Raycast(p + Vector3.new(0, 12, 0), Vector3.new(0, -14, 0), params)
			if not hit or hit.Material ~= Enum.Material.Water then
				return nil
			end
		end
	end
	return track
end

local begin: (Player, { [string]: any }, (({ [string]: any }) -> ())?, Track.Track?) -> boolean

function RaceService.startStory(player: Player, spec: { [string]: any }, onDone: ({ [string]: any }) -> ()): boolean
	if not Story.Games[spec.Game] then
		return false
	end
	return begin(player, spec, onDone, nil)
end

-- Una carrera por gusto: «Carrera» (velocidad, en la pista de deporte más cercana) o «Natacion» (en el
-- agua, hacia donde miras). Devuelve el motivo si no se puede.
function RaceService.startPickup(player: Player, kind: string): (boolean, string?)
	if sessions[player] or player:GetAttribute("InSport") then
		return false, "Busy"
	end
	if kind == "Natacion" then
		local track = swimTrack(player, 4)
		if not track then
			return false, "Agua"
		end
		return begin(player, { Game = "Natacion", Title = "Carrera de natación", Icon = "🏊", Rivals = { "Nadador", "Nadadora", "Nadador" }, Puesto = 1 }, nil, track), nil
	end
	return begin(player, { Game = "Carrera", Title = "Carrera de velocidad", Icon = "🏃", Rivals = { "Corredor", "Corredora", "Corredor" }, Puesto = 1 }, nil, nil), "Pista"
end

function begin(player: Player, spec: { [string]: any }, onDone: (({ [string]: any }) -> ())?, given: Track.Track?): boolean
	if not initialized or sessions[player] then
		return false
	end
	local feet = feetOf(player)
	if not feet then
		return false
	end
	local opts = Story.options(spec)
	if spec.Game == "Natacion" then
		opts.Mode = "Natacion"
	end
	local relay = opts.Mode == "Relevo"
	local track = given
	if not track then
		local arena = arenaNear(feet, 50)
		if not arena then
			warn(("[Carrera] %s: sin pista cerca; se juega el minijuego de siempre"):format(player.Name))
			return false
		end
		local lanes = if relay then 2 else opts.Lanes
		track = Track.fromPart(arena, lanes, if relay then 45 else 60, "Recta")
	end
	local track = track :: Track.Track
	local character = player.Character
	local scale = 1
	pcall(function()
		scale = (character :: Model):GetScale()
	end)
	local humanoid = humanoidOf(player)
	local speedScale = if humanoid and humanoid.WalkSpeed > 4 then humanoid.WalkSpeed / 16 else 1
	local sim = Race.new(track, { Mode = opts.Mode, SpeedScale = speedScale, Seed = math.random(1, 1e6) })
	local me = "u" .. player.UserId
	if relay then
		local team = opts.Team
		for leg = 1, 4 do
			if leg == 4 then
				Race.addRunner(sim, { Id = me, Name = player.DisplayName, Team = 1, Lane = 1, Leg = 4, Human = true })
			else
				local name = team[leg]
				Race.addRunner(sim, { Id = "t" .. leg, Name = name or "Compañero", Npc = name, Team = 1, Lane = 1, Leg = leg, Skill = opts.Skill1 })
			end
			local rival = opts.Rivals[leg]
			Race.addRunner(sim, { Id = "r" .. leg, Name = rival or "Rival", Npc = rival, Team = 2, Lane = 2, Leg = leg, Skill = opts.Skill2 })
		end
	else
		Race.addRunner(sim, { Id = me, Name = player.DisplayName, Lane = 1, Human = true })
		for i, name in opts.Rivals do
			Race.addRunner(sim, { Id = "r" .. i, Name = name, Npc = name, Lane = i + 1, Skill = opts.Skill2 })
		end
	end
	local folder = Instance.new("Folder")
	folder.Name = "Carrera_" .. player.UserId
	folder.Parent = workspace
	local session: Session = {
		Player = player,
		Spec = spec,
		OnDone = onDone,
		Track = track,
		Sim = sim,
		Folder = folder,
		Bots = {},
		Scale = scale,
		Me = me,
		LastSnap = 0,
		Done = false,
		Ended = false,
	}
	sessions[player] = session
	player:SetAttribute("InSport", "Carrera")
	paint(session)
	for _, id in sim.Order do
		local r = sim.Runners[id]
		if not r.Human then
			spawnBot(session, r)
		end
	end
	local roster = {}
	for _, id in sim.Order do
		local r = sim.Runners[id]
		roster[id] = { Name = if r.Human then player.DisplayName else displayName(r.Npc or r.Name), Lane = r.Lane, Team = r.Team, Leg = r.Leg, Human = r.Human, Model = session.Bots[id] }
	end
	Race.start(sim)
	remote:FireClient(player, "Session", {
		Mode = sim.Mode,
		Track = { CFrame = track.CFrame, Length = track.Length, Lanes = track.Lanes, LaneWidth = track.LaneWidth },
		Order = sim.Order,
		Roster = roster,
		You = me,
		Title = spec.Title,
		Icon = spec.Icon,
		Hint = spec.Hint,
		Puesto = opts.Puesto,
		SpeedScale = speedScale,
		Water = sim.Mode == "Natacion",
	})
	return true
end

function RaceService.stopStory(player: Player)
	local s = sessions[player]
	if s then
		deliver(s, false)
	end
end

function RaceService.cancelStory(player: Player)
	local s = sessions[player]
	if s then
		s.Done = true
		endSession(s)
	end
end

local function stepSession(session: Session, dt: number)
	local player = session.Player
	local sim = session.Sim
	local root, humanoid = rootOf(player), humanoidOf(player)
	if not player.Parent or not root or not humanoid or humanoid.Health <= 0 then
		if player.Parent then
			session.Done = true
			endSession(session) -- (muerto: sin resultado; la misión lo vuelve a proponer)
		else
			deliver(session, true)
		end
		return
	end
	local me = sim.Runners[session.Me]
	local loc = Track.toLocal(session.Track, feetOf(player) :: Vector3)
	if math.abs(loc.Z) > session.Track.Lanes * session.Track.LaneWidth + 30 or loc.X < -40 or loc.X > session.Track.Length + 40 then
		session.Away = session.Away or os.clock()
		if os.clock() - session.Away > 10 then
			deliver(session, true)
			return
		end
	else
		session.Away = nil
	end
	if me and not me.Done then
		local dir = Race.direction(sim, me)
		local run = if dir > 0 then loc.X else session.Track.Length - loc.X
		if (sim.Phase == "Marks" or sim.Phase == "Set") and me.Active and session.Mark then
			-- Moverse antes del disparo es salida nula
			if Vector3.new(loc.X - session.Mark.X, 0, loc.Z - session.Mark.Z).Magnitude > 2.5 then
				Race.humanGo(sim, session.Me)
			end
		elseif sim.Phase == "Run" and me.Active and not me.Running and run > 0.5 then
			Race.humanGo(sim, session.Me)
		end
		local v = root.AssemblyLinearVelocity
		Race.setHuman(sim, session.Me, run, Vector3.new(v.X, 0, v.Z).Magnitude)
	end
	for _, e in Race.step(sim, dt) do
		if e.Kind == "Place" and e.Id == session.Me then
			placeHuman(session, sim.Runners[session.Me])
		elseif e.Kind == "Over" then
			remote:FireClient(player, "Event", e)
			task.delay(2.5, function()
				deliver(session, false)
			end)
			continue
		end
		remote:FireClient(player, "Event", e)
	end
	session.LastSnap += dt
	if session.LastSnap >= SNAPSHOT_EVERY then
		session.LastSnap = 0
		local rows = {}
		for i, id in sim.Order do
			local r = sim.Runners[id]
			rows[i] = { math.floor(r.X * 100) / 100, r.Active and not r.Done }
		end
		stateRemote:FireClient(player, { P = rows, Ph = sim.Phase })
		for id, model in session.Bots do
			local r = sim.Runners[id]
			if r and model.PrimaryPart then
				model.PrimaryPart.CFrame = botCFrame(session, r, model)
			end
		end
	end
end

function RaceService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remote = remotes:FindFirstChild("Carrera") :: RemoteEvent
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = "Carrera"
		remote.Parent = remotes
	end
	stateRemote = remotes:FindFirstChild("CarreraState")
	if not stateRemote then
		local ok, created = pcall(Instance.new, "UnreliableRemoteEvent")
		stateRemote = if ok and created then created else Instance.new("RemoteEvent")
		stateRemote.Name = "CarreraState"
		stateRemote.Parent = remotes
	end
	pcall(function()
		ProgressionService = require(script.Parent.ProgressionService)
	end)
	remote.OnServerEvent:Connect(function(player, kind, data)
		if kind == "Pickup" and type(data) == "table" and not sessions[player] then
			local ok, why = RaceService.startPickup(player, if data.Kind == "Natacion" then "Natacion" else "Carrera")
			if not ok then
				remote:FireClient(player, "Error", { Text = if why == "Agua" then "Métete en el mar, con agua libre por delante, para la carrera de natación." else "Aquí no hay sitio para una carrera." })
			end
			return
		end
		local session = sessions[player]
		if not session then
			return
		end
		if kind == "Pickup" then
			return
		elseif kind == "Go" then
			Race.humanGo(session.Sim, session.Me)
		elseif kind == "Take" then
			Race.take(session.Sim, session.Me)
		elseif kind == "Leave" then
			deliver(session, true)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local s = sessions[player]
		if s then
			pcall(deliver, s, true)
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		for _, session in sessions do
			local ok, err = pcall(stepSession, session, dt)
			if not ok then
				warn("[Carrera] " .. tostring(err))
				pcall(deliver, session, false)
			end
		end
	end)
	initialized = true
end

return RaceService
