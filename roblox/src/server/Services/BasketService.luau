-- BasketService (servidor): baloncesto de verdad en las canastas del mapa (las pistas de los colegios
-- e institutos, la media pista del parque, el gimnasio del colegio, la cárcel…) y en los pasos de
-- baloncesto de la historia. Funciona como FootballService:
--
--   * Las canastas salen solas del mapa: cada aro naranja («Rim») con su tablero; con su suelo
--     («Court», «HalfCourt») es pista entera o media pista; sin suelo (el gimnasio), media pista
--     delante del aro (Sports/Court).
--   * Pachanga: pisas una pista y tocas «🏀 Jugar». Libre (tirar y botar), 1 contra 1, 3 contra 3
--     o una tanda de tiros; otros jugadores se unen en el sitio de una máquina.
--   * Historia: MiniGameService llama a startStory (Game = Canastas / Baloncesto) y el resultado de
--     verdad vuelve a la misión con el mismo formato que antes (Sports/BasketStory). Siempre acaba.
--
-- El balón y las máquinas los calcula Sports/BasketSim aquí; a los clientes les llegan fotos (remoto
-- BasketState) y sucesos (remoto Basket). El tiro sale de una semilla que manda el cliente: así su
-- pantalla lo ve salir igual que lo calcula el servidor.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Sports = ReplicatedStorage.Shared.Sports
local Court = require(Sports.Court)
local Sim = require(Sports.BasketSim)
local Story = require(Sports.BasketStory)
local Cast = require(ReplicatedStorage.Shared.LifeStory.Cast)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Npc = require(script.Parent.Parent.World.Npc)
local SportPrompts = require(script.Parent.Parent.World.SportPrompts)

local BasketService = {}

local SNAPSHOT_EVERY = 1 / 15
local BOT_SYNC_EVERY = 0.2
local VIEW_RANGE = 200
local LEAVE_MARGIN = 18
local LEAVE_SECONDS = 8
local STORY_LEAVE_SECONDS = 14
local EMPTY_SECONDS = 12

local TEAM_COLORS = { [1] = Color3.fromRGB(40, 110, 220), [2] = Color3.fromRGB(215, 60, 55) }

type Field = { Id: string, Court: Court.Court, Virtual: boolean? }
type Session = { [string]: any }

local fields: { Field } = {}
local scanned = false
local sessions: { [string]: Session } = {}
local playerSession: { [Player]: Session } = {}
local counter = 0
local initialized = false

local remote: RemoteEvent
local stateRemote: any
local notify: RemoteEvent?
local ProgressionService: any = nil

local function say(player: Player, kind: string, text: string)
	if notify then
		notify:FireClient(player, kind, text)
	end
end

---------------------------------------------------------------------
-- Canastas del mapa
---------------------------------------------------------------------

local function scanCourts()
	scanned = true
	-- (otra búsqueda con partidos en marcha: la pista que ya existía se queda la misma, con su partido)
	local old = {}
	for _, field in fields do
		old[field.Id] = field
	end
	table.clear(fields)
	local courts = Court.scanMap(workspace:GetDescendants(), function(entry)
		-- Sin suelo marcado: el suelo de verdad debajo de delante del aro
		local rim, board = entry.Part, entry.Board
		local normal = Vector3.new(rim.Position.X - board.Position.X, 0, rim.Position.Z - board.Position.Z)
		normal = if normal.Magnitude > 1e-3 then normal.Unit else Vector3.new(1, 0, 0)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { rim, board }
		local hit = workspace:Raycast(rim.Position + normal * 4, Vector3.new(0, -16, 0), params)
		return if hit then hit.Position.Y else nil
	end)
	for _, court in courts do
		table.insert(fields, old[court.Id] or { Id = court.Id, Court = court })
	end
end

-- Carteles «Jugar · Baloncesto» (World/SportPrompts): en la línea de tiros libres de cada canasta y en
-- los balones de baloncesto que hay en las pistas (los del gimnasio del colegio, los del parque…).
-- Antes solo había un botón pequeño «Jugar» al pisar la pista y nadie lo encontraba.
local placePrompts: () -> ()
local promptsPlaced = false
local joinField: (Player, Field) -> ()

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end
local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end
local function feetOf(player: Player): Vector3?
	local root = rootOf(player)
	local humanoid = humanoidOf(player)
	if not root then
		return nil
	end
	local h = if humanoid then humanoid.HipHeight + root.Size.Y / 2 else 3
	return root.Position - Vector3.new(0, h, 0)
end

local function nearestField(position: Vector3, maxOut: number): (Field?, number)
	if not scanned or #fields == 0 then
		scanCourts()
	end
	local best, bestOut = nil, math.huge
	for _, field in fields do
		local c = field.Court
		local loc = Court.toLocal(c, position)
		local outX = math.max(0, math.abs(loc.X) - c.Length / 2)
		local outZ = math.max(0, math.abs(loc.Z) - c.Width / 2)
		local out = math.sqrt(outX * outX + outZ * outZ) + (if math.abs(loc.Y) > 12 then 1000 else 0)
		if out < bestOut then
			best, bestOut = field, out
		end
	end
	if best and bestOut <= maxOut then
		return best, bestOut
	end
	return nil, bestOut
end

function placePrompts()
	promptsPlaced = true
	local folder = SportPrompts.folder("BasketPrompts")
	folder:ClearAllChildren()
	local spec = { Sport = "Baloncesto", Action = "Jugar", Object = "Baloncesto", Distance = 10 }
	for _, field in fields do
		for side, hoop in field.Court.Hoops do
			local spot = Court.freeThrowSpot(field.Court, hoop)
			local at = Court.toWorld(field.Court, Vector3.new(spot.X, 2.5, spot.Z))
			local anchor = SportPrompts.anchor(folder, ("%s_%d"):format(field.Id, side), at)
			SportPrompts.attach(anchor, spec, function(player)
				joinField(player, field)
			end)
		end
	end
	-- Los balones de las pistas: el cartel va con el balón (se patean y vuelven solos a su sitio)
	local ballSpec = { Sport = "Baloncesto", Action = "Jugar", Object = "Baloncesto", Distance = 7 }
	for _, toy in CollectionService:GetTagged("Toy") do
		if toy:IsA("BasePart") and toy:GetAttribute("Toy") == "Baloncesto" and nearestField(toy.CFrame.Position, 3) then
			SportPrompts.attach(toy, ballSpec, function(player, part)
				local field = nearestField(part.CFrame.Position, 6)
				if not field then
					local feet = feetOf(player)
					field = feet and nearestField(feet, 6)
				end
				if field then
					joinField(player, field)
				else
					say(player, "Info", "🏀 Lleva el balón a una pista con canasta para jugar.")
				end
			end)
		end
	end
end

local function describe(field: Field): { [string]: any }
	local c = field.Court
	local hoops = {}
	for side, h in c.Hoops do
		hoops[tostring(side)] = { Rim = h.Rim, Radius = h.Radius, Board = h.Board, BoardHalf = h.BoardHalf, Normal = h.Normal }
	end
	return { Id = field.Id, CFrame = c.CFrame, Length = c.Length, Width = c.Width, Hoops = hoops, BoardMargin = c.BoardX - c.Length / 2 }
end

---------------------------------------------------------------------
-- Máquinas
---------------------------------------------------------------------

local function displayName(name: string?): string
	if not name then
		return "Jugador"
	end
	if Cast.People[name] then
		local ok, text = pcall(function()
			return Strings.get(Cast.nameOf(name, {}))
		end)
		if ok and type(text) == "string" then
			return text
		end
	end
	return name
end

local function botCFrame(session: Session, p: any, model: Model): CFrame
	local c = session.Field.Court
	local feet = Court.toWorld(c, Vector3.new(p.P.X, 0, p.P.Z))
	local facing = Court.dirToWorld(c, p.Facing)
	local up = (model:GetAttribute("FootOffset") :: number?) or 3
	local at = feet + Vector3.new(0, up, 0)
	return CFrame.lookAt(at, at + Vector3.new(facing.X, 0, facing.Z))
end

local function spawnBot(session: Session, p: any)
	local c = session.Field.Court
	local person = p.Npc and Cast.People[p.Npc]
	local look = {
		Skin = person and person.Skin or nil,
		Hair = person and person.Hair or nil,
		Pants = person and person.Pants or nil,
		Shirt = TEAM_COLORS[p.Team],
		Shoes = Color3.fromRGB(240, 240, 240),
		LongSleeves = false,
		LongHair = person and person.LongHair or nil,
	}
	local feet = Court.toWorld(c, Vector3.new(p.P.X, 0, p.P.Z))
	local ok, model = pcall(Npc.create, displayName(p.Npc or p.Name), session.Folder, CFrame.new(feet), look)
	if not ok or not model then
		return
	end
	local scale = p.Scale or 1
	if math.abs(scale - 1) > 0.01 then
		pcall(function()
			model:ScaleTo(scale)
		end)
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if humanoid then
		humanoid.DisplayName = displayName(p.Npc or p.Name)
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	if humanoid and root then
		model:SetAttribute("FootOffset", humanoid.HipHeight + root.Size.Y / 2)
	end
	model:SetAttribute("SportSession", session.Id)
	model:SetAttribute("SportId", p.Id)
	if scale < 0.9 then
		model:SetAttribute("Age", "Nino")
	end
	CollectionService:AddTag(model, "StaticNpc")
	CollectionService:AddTag(model, "NamedActor")
	CollectionService:AddTag(model, "SportBot")
	model:PivotTo(botCFrame(session, p, model))
	session.Bots[p.Id] = model
end

local function removeBot(session: Session, id: string)
	local model = session.Bots[id]
	session.Bots[id] = nil
	if model then
		model:Destroy()
	end
end

local function respawnBots(session: Session)
	for id in session.Bots do
		removeBot(session, id)
	end
	for _, id in session.Sim.Order do
		local p = session.Sim.Players[id]
		if not p.Human then
			spawnBot(session, p)
		end
	end
end

---------------------------------------------------------------------
-- Mensajes
---------------------------------------------------------------------

local function rosterOf(session: Session): { [string]: any }
	local out = {}
	for _, id in session.Sim.Order do
		local p = session.Sim.Players[id]
		local player = session.ById[id]
		out[id] = {
			Name = if player then player.DisplayName else displayName(p.Npc or p.Name),
			Team = p.Team,
			Human = p.Human,
			UserId = if player then player.UserId else nil,
			Model = session.Bots[id] or (if player then player.Character else nil),
		}
	end
	return out
end

local function sessionInfo(session: Session, viewer: Player): { [string]: any }
	local sim = session.Sim
	local story = session.Story
	return {
		S = session.Id,
		Version = session.Version,
		Order = session.Order,
		Field = describe(session.Field),
		Mode = sim.Mode,
		Pickup = session.Pickup,
		Duration = sim.Duration,
		Rounds = sim.Rounds,
		Need = sim.Need,
		Roster = rosterOf(session),
		You = session.Humans[viewer],
		Story = if story then {
			Title = story.Spec.Title,
			Icon = story.Spec.Icon,
			Hint = story.Spec.Hint,
			Game = story.Spec.Game,
			Rival = story.Spec.Rival,
			Mine = story.Player == viewer,
		} else nil,
	}
end

local function sendInfo(session: Session, only: Player?)
	if not only then
		session.Version += 1
		session.Order = table.clone(session.Sim.Order)
	end
	for viewer in session.Viewers do
		if not only or only == viewer then
			remote:FireClient(viewer, "Session", sessionInfo(session, viewer))
		end
	end
end

local function broadcast(session: Session, kind: string, data: { [string]: any })
	data.S = session.Id
	for viewer in session.Viewers do
		remote:FireClient(viewer, kind, data)
	end
end

local function snapshot(session: Session): { [string]: any }
	local sim = session.Sim
	local ball = sim.Ball
	local rows = {}
	for i, id in session.Order do
		local p = sim.Players[id]
		if not p then
			rows[i] = false
			continue
		end
		rows[i] = { p.P, math.floor(math.atan2(p.Facing.Z, p.Facing.X) * 100) / 100, sim.T < p.Jump }
	end
	local owner = sim.Owner and table.find(session.Order, sim.Owner) or 0
	return {
		S = session.Id,
		V = session.Version,
		Ph = sim.Phase,
		B = { ball.P, ball.V, owner, sim.KickSeq },
		P = rows,
		G = { sim.Score[1], sim.Score[2], math.floor(sim.Clock), sim.Round, sim.Rounds, sim.Hits, sim.Taken },
	}
end

---------------------------------------------------------------------
-- Sesiones
---------------------------------------------------------------------

local function humanSpec(player: Player, team: number): { [string]: any }
	local character = player.Character
	local scale = 1
	if character then
		local ok, s = pcall(function()
			return character:GetScale()
		end)
		if ok and type(s) == "number" then
			scale = s
		end
	end
	return { Id = "u" .. player.UserId, Name = player.DisplayName, Team = team, Human = true, Scale = scale }
end

local function botSpeed(player: Player?): number
	local humanoid = player and humanoidOf(player)
	if humanoid and humanoid.WalkSpeed > 4 then
		return math.clamp(humanoid.WalkSpeed * 0.95, 10, 18)
	end
	return 15
end

local function newSession(field: Field): Session
	counter += 1
	local folder = Instance.new("Folder")
	folder.Name = "Baloncesto_" .. field.Id
	folder.Parent = workspace
	local session: Session = {
		Id = field.Id .. "#" .. counter,
		Field = field,
		Sim = nil,
		Humans = {},
		ById = {},
		Bots = {},
		Folder = folder,
		Story = nil,
		Viewers = {},
		Away = {},
		LastSnap = 0,
		LastBotSync = 0,
		Ended = false,
		Version = 0,
		Order = {},
	}
	sessions[field.Id] = session
	return session
end

local function endSession(session: Session)
	if session.Ended then
		return
	end
	session.Ended = true
	if sessions[session.Field.Id] == session then
		sessions[session.Field.Id] = nil
	end
	for player in session.Humans do
		if playerSession[player] == session then
			playerSession[player] = nil
			player:SetAttribute("InSport", nil)
		end
	end
	for viewer in session.Viewers do
		remote:FireClient(viewer, "End", { S = session.Id })
	end
	session.Folder:Destroy()
end

local function buildPickup(session: Session, mode: string, size: number?)
	local first: Player? = next(session.Humans)
	local sim = Sim.new(session.Field.Court, {
		Mode = mode,
		Duration = if mode == "Partido" then 180 else nil,
		Rounds = if mode == "Tiros" then 10 else nil,
		Need = 0,
		Spots = "Variado",
		StopWhenDecided = false,
		BotSpeed = botSpeed(first),
		Seed = math.random(1, 1e6),
	})
	session.Sim = sim
	session.Pickup = mode
	session.Size = size
	local humans = {}
	for player in session.Humans do
		table.insert(humans, player)
	end
	table.sort(humans, function(a, b)
		return a.UserId < b.UserId
	end)
	for i, player in humans do
		local team = if mode == "Partido" and i % 2 == 0 then 2 else 1
		local spec = humanSpec(player, team)
		Sim.addPlayer(sim, spec)
		local feet = feetOf(player)
		if feet then
			Sim.setHuman(sim, spec.Id, Court.toLocal(session.Field.Court, feet))
		end
	end
	if mode == "Partido" then
		Sim.fillTeams(sim, math.clamp(size or 1, 1, 5), {}, {}, { Skill1 = 0.5, Skill2 = 0.5 })
	end
	Sim.start(sim)
	respawnBots(session)
	sendInfo(session)
end

local function joinViewers(session: Session)
	local center = session.Field.Court.CFrame.Position
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		local near = root ~= nil and (root.Position - center).Magnitude < VIEW_RANGE
		if near and not session.Viewers[player] then
			session.Viewers[player] = true
			remote:FireClient(player, "Session", sessionInfo(session, player))
		elseif not near and session.Viewers[player] and not session.Humans[player] then
			session.Viewers[player] = nil
			remote:FireClient(player, "End", { S = session.Id })
		end
	end
end

local deliverStory: (Session, boolean?) -> ()

local function removeHuman(session: Session, player: Player, why: string?)
	local id = session.Humans[player]
	if not id then
		return
	end
	session.Humans[player] = nil
	session.ById[id] = nil
	session.Away[player] = nil
	if playerSession[player] == session then
		playerSession[player] = nil
	end
	player:SetAttribute("InSport", nil)
	if session.Story and session.Story.Player == player then
		if why == "Dead" then
			session.Story.Done = true
			endSession(session)
			return
		end
		deliverStory(session, true)
		return
	end
	Sim.removePlayer(session.Sim, id)
	if session.Pickup == "Partido" and not session.Sim.Over then
		local before = {}
		for _, bid in session.Sim.Order do
			before[bid] = true
		end
		Sim.fillTeams(session.Sim, session.Size or 1, {}, {}, { Skill1 = 0.5, Skill2 = 0.5 })
		for _, bid in session.Sim.Order do
			local p = session.Sim.Players[bid]
			if not before[bid] and not p.Human then
				spawnBot(session, p)
			end
		end
	end
	remote:FireClient(player, "Left", { S = session.Id })
	sendInfo(session)
end

local function addHuman(session: Session, player: Player): boolean
	local sim = session.Sim
	if session.Humans[player] then
		return true
	end
	if sim.Mode == "Tiros" then
		return false
	end
	local team = 1
	if sim.Mode == "Partido" and not sim.Over then
		local humans = { [1] = 0, [2] = 0 }
		for _, id in sim.Order do
			local p = sim.Players[id]
			if p.Human then
				humans[p.Team] += 1
			end
		end
		team = if humans[2] < humans[1] then 2 else 1
		for _, id in sim.Order do
			local p = sim.Players[id]
			if p.Team == team and not p.Human then
				Sim.removePlayer(sim, id)
				removeBot(session, id)
				break
			end
		end
	end
	local spec = humanSpec(player, team)
	Sim.addPlayer(sim, spec)
	Sim.number(sim)
	local feet = feetOf(player)
	if feet then
		Sim.setHuman(sim, spec.Id, Court.toLocal(session.Field.Court, feet))
	end
	session.Humans[player] = spec.Id
	session.ById[spec.Id] = player
	session.Viewers[player] = true
	playerSession[player] = session
	player:SetAttribute("InSport", "Baloncesto")
	sendInfo(session)
	return true
end

local function teleportHuman(session: Session, player: Player, loc: Vector3, facing: Vector3?)
	local character = player.Character
	local root = rootOf(player)
	local humanoid = humanoidOf(player)
	if not character or not root then
		return
	end
	local c = session.Field.Court
	local feet = Court.toWorld(c, Vector3.new(loc.X, 0, loc.Z))
	local h = if humanoid then humanoid.HipHeight + root.Size.Y / 2 else 3
	local f = Court.dirToWorld(c, facing or Vector3.new(1, 0, 0))
	local at = feet + Vector3.new(0, h + 0.1, 0)
	character:PivotTo(CFrame.lookAt(at, at + Vector3.new(f.X, 0, f.Z)))
	root.AssemblyLinearVelocity = Vector3.zero
end

local function addXp(player: Player?, amount: number, reason: string)
	if player and ProgressionService then
		pcall(ProgressionService.addXp, player, amount, reason)
	end
end

local function handleEvents(session: Session, events: { { [string]: any } })
	local sim = session.Sim
	for _, e in events do
		if e.Kind == "Teleport" then
			local player = e.Id and session.ById[e.Id]
			if player and not session.Away[player] then -- (a quien se va de la pista no se le trae de vuelta)
				teleportHuman(session, player, e.P, e.Facing)
			end
			broadcast(session, "Event", { Kind = "Teleport", Id = e.Id, P = e.P, Facing = e.Facing })
		elseif e.Kind == "Basket" then
			local scorer = e.Scorer and session.ById[e.Scorer]
			if scorer then
				addXp(scorer, 5, "BasketCanasta")
			end
			broadcast(session, "Event", e)
		elseif e.Kind == "Over" then
			broadcast(session, "Event", e)
			if session.Story then
				task.delay(3, function()
					deliverStory(session, false)
				end)
			else
				if sim.Mode == "Partido" then
					for player, id in session.Humans do
						local p = sim.Players[id]
						if p and sim.Score[p.Team] > sim.Score[3 - p.Team] then
							addXp(player, 20, "BasketPartido")
						end
					end
				end
				session.BackToFree = os.clock() + 7
			end
		else
			broadcast(session, "Event", e)
		end
	end
end

---------------------------------------------------------------------
-- La historia
---------------------------------------------------------------------

function deliverStory(session: Session, abandoned: boolean?)
	local story = session.Story
	if not story or story.Done then
		return
	end
	story.Done = true
	local result = Story.result(story.Spec, Sim.outcome(session.Sim), abandoned == true)
	if result.Won and story.Spec.Game == "Baloncesto" then
		addXp(story.Player, 20, "BasketPartido")
	end
	endSession(session)
	task.spawn(story.OnDone, result)
end

function BasketService.startStory(player: Player, spec: { [string]: any }, onDone: ({ [string]: any }) -> ()): boolean
	if not initialized or not Story.Games[spec.Game] or playerSession[player] then
		return false
	end
	local feet = feetOf(player)
	if not feet then
		return false
	end
	local field, out = nearestField(feet, 220)
	if not field then
		warn(("[Baloncesto] %s: sin canasta cerca (a %.0f studs); se juega el minijuego de siempre"):format(player.Name, out))
		return false
	end
	local f = field :: Field
	-- Partido en media pista solo si no hay pista entera cerca (la de la cancha del colegio)
	local existing = sessions[f.Id]
	if existing then
		if existing.Story then
			return false
		end
		for other in existing.Humans do
			say(other, "Info", "🏀 La pista se necesita ahora para un partido de la historia.")
		end
		endSession(existing)
	end
	local opts = Story.options(spec)
	local session = newSession(f)
	local me = humanSpec(player, 1)
	local sim = Sim.new(f.Court, {
		Mode = opts.Mode,
		Duration = opts.Duration,
		Rounds = opts.Rounds,
		Need = opts.Need,
		Spots = opts.Spots,
		StopWhenDecided = opts.StopWhenDecided,
		Scale = me.Scale,
		BotSpeed = botSpeed(player),
		Seed = math.random(1, 1e6),
	})
	session.Sim = sim
	Sim.addPlayer(sim, me)
	if opts.Mode == "Partido" then
		Sim.fillTeams(sim, opts.Size, opts.Team, opts.Rivals, { Skill1 = opts.Skill1, Skill2 = opts.Skill2 })
		for _, id in sim.Order do
			local p = sim.Players[id]
			if not p.Human and not p.Npc then
				p.Name = if p.Team == 1 then "Compañero" else "Rival"
			end
		end
	end
	session.Humans[player] = me.Id
	session.ById[me.Id] = player
	session.Viewers[player] = true
	session.Story = { Player = player, Spec = spec, OnDone = onDone, Done = false }
	playerSession[player] = session
	player:SetAttribute("InSport", "Baloncesto")
	Sim.start(sim)
	respawnBots(session)
	joinViewers(session)
	sendInfo(session)
	return true
end

function BasketService.stopStory(player: Player)
	local session = playerSession[player]
	if session and session.Story and session.Story.Player == player then
		deliverStory(session, false)
	end
end

function BasketService.cancelStory(player: Player)
	local session = playerSession[player]
	if session and session.Story and session.Story.Player == player then
		session.Story.Done = true
		endSession(session)
	end
end

---------------------------------------------------------------------
-- Cada frame
---------------------------------------------------------------------

local function stepSession(session: Session, dt: number)
	local sim = session.Sim
	if not sim or session.Ended then
		return
	end
	local c = session.Field.Court
	for player, id in session.Humans do
		local root = rootOf(player)
		local humanoid = humanoidOf(player)
		if not root or not humanoid or humanoid.Health <= 0 or not player.Parent then
			removeHuman(session, player, if player.Parent then "Dead" else "Gone")
			continue
		end
		local loc = Court.toLocal(c, feetOf(player) :: Vector3)
		Sim.setHuman(sim, id, loc, Court.dirToLocal(c, root.AssemblyLinearVelocity), Court.dirToLocal(c, root.CFrame.LookVector))
		local out = math.abs(loc.X) > c.BoardX + LEAVE_MARGIN or math.abs(loc.Z) > c.BoardZ + LEAVE_MARGIN or math.abs(loc.Y) > 20
		if out then
			session.Away[player] = session.Away[player] or os.clock()
			if os.clock() - session.Away[player] > (if session.Story then STORY_LEAVE_SECONDS else LEAVE_SECONDS) then
				if session.Story then
					say(player, "Info", "🏀 Te has ido de la pista: se acaba aquí.")
				end
				removeHuman(session, player, "Away")
				continue
			end
		else
			session.Away[player] = nil
		end
	end
	if session.Ended then
		return
	end
	handleEvents(session, Sim.step(sim, dt))
	if session.Ended then
		return
	end
	if not session.Story then
		if next(session.Humans) == nil then
			session.EmptySince = session.EmptySince or os.clock()
			if os.clock() - session.EmptySince > EMPTY_SECONDS then
				endSession(session)
				return
			end
		else
			session.EmptySince = nil
		end
		if session.BackToFree and os.clock() >= session.BackToFree then
			session.BackToFree = nil
			buildPickup(session, "Libre")
		end
	end
	local now = os.clock()
	if now - session.LastBotSync >= BOT_SYNC_EVERY then
		session.LastBotSync = now
		for id, model in session.Bots do
			local p = sim.Players[id]
			if p and model.PrimaryPart and model.Parent then
				model.PrimaryPart.CFrame = botCFrame(session, p, model)
			end
		end
	end
	if now - session.LastSnap >= SNAPSHOT_EVERY then
		session.LastSnap = now
		local snap = snapshot(session)
		for viewer in session.Viewers do
			stateRemote:FireClient(viewer, snap)
		end
	end
end

---------------------------------------------------------------------
-- Lo que piden los clientes
---------------------------------------------------------------------

local function vec(x: any): Vector3?
	if typeof(x) ~= "Vector3" or x.X ~= x.X or x.Y ~= x.Y or x.Z ~= x.Z or x.Magnitude > 1e5 then
		return nil
	end
	return x
end

-- Entrar a jugar en una pista (botón «Jugar», tecla J o un cartel «Jugar · Baloncesto»)
function joinField(player: Player, field: Field)
	if playerSession[player] then
		return
	end
	local existing = sessions[field.Id]
	if existing and existing.Story then
		say(player, "Info", "🏀 Ahora se está jugando un partido de la historia aquí. ¡Mira y anima!")
		return
	end
	if not existing then
		existing = newSession(field)
		buildPickup(existing, "Libre")
	end
	if not addHuman(existing, player) then
		say(player, "Info", "🏀 Ahora están en una tanda de tiros. Espera un momento y únete.")
		return
	end
	joinViewers(existing)
end

local function onRequest(player: Player, kind: any, data: any)
	if type(kind) ~= "string" then
		return
	end
	data = if type(data) == "table" then data else {}
	local session = playerSession[player]
	if kind == "Shot" then
		if session then
			local quality = tonumber(data.Quality) or 0.5
			if quality ~= quality then
				quality = 0.5
			end
			-- Desde donde se ve en su pantalla (si es razonable): así el tiro sale igual en los dos sitios
			local id = session.Humans[player]
			local me = session.Sim.Players[id]
			local at, facing = vec(data.At), vec(data.Facing)
			if me and at and (Vector3.new(at.X, 0, at.Z) - me.P).Magnitude < 4 then
				Sim.setHuman(session.Sim, id, at, me.V, facing)
			end
			local ok, why = Sim.shoot(session.Sim, id, math.clamp(quality, 0, 1), math.floor(tonumber(data.Seed) or 1))
			if not ok then
				remote:FireClient(player, "ShotRejected", { S = session.Id, Why = why })
			end
		end
	elseif kind == "Pass" then
		if session then
			local ok = Sim.pass(session.Sim, session.Humans[player], if type(data.To) == "string" then data.To else nil, vec(data.Dir))
			if not ok then
				remote:FireClient(player, "ShotRejected", { S = session.Id })
			end
		end
	elseif kind == "Steal" then
		if session then
			Sim.steal(session.Sim, session.Humans[player])
		end
	elseif kind == "Join" then
		if session then
			return
		end
		local feet = feetOf(player)
		local field = feet and nearestField(feet, 6)
		if field then
			joinField(player, field)
		end
	elseif kind == "Leave" then
		if session and not session.Story then
			removeHuman(session, player, "Leave")
		end
	elseif kind == "Mode" then
		if not session or session.Story then
			return
		end
		if data.Mode == "Partido" then
			buildPickup(session, "Partido", math.clamp(math.floor(tonumber(data.Size) or 1), 1, 5))
		elseif data.Mode == "Tiros" then
			local n = 0
			for _ in session.Humans do
				n += 1
			end
			if n > 1 then
				say(player, "Info", "🏀 La tanda de tiros es para jugar solo. Con más gente, ¡un partido!")
				return
			end
			buildPickup(session, "Tiros")
		elseif data.Mode == "Libre" then
			buildPickup(session, "Libre")
		end
	elseif kind == "Fields" then
		if not scanned or #fields == 0 then
			scanCourts()
		end
		if not promptsPlaced then
			pcall(placePrompts)
		end
		local list = {}
		for _, field in fields do
			table.insert(list, describe(field))
		end
		remote:FireClient(player, "Fields", list)
	end
end

function BasketService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remote = remotes:FindFirstChild("Basket") :: RemoteEvent
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = "Basket"
		remote.Parent = remotes
	end
	stateRemote = remotes:FindFirstChild("BasketState")
	if not stateRemote then
		local ok, created = pcall(Instance.new, "UnreliableRemoteEvent")
		stateRemote = if ok and created then created else Instance.new("RemoteEvent")
		stateRemote.Name = "BasketState"
		stateRemote.Parent = remotes
	end
	notify = remotes:FindFirstChild("Notify") :: RemoteEvent?
	pcall(function()
		ProgressionService = require(script.Parent.ProgressionService)
	end)
	remote.OnServerEvent:Connect(function(player, kind, data)
		local ok, err = pcall(onRequest, player, kind, data)
		if not ok then
			warn("[Baloncesto] " .. tostring(err))
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local session = playerSession[player]
		if session then
			pcall(removeHuman, session, player, "Gone")
		end
		for _, s in sessions do
			s.Viewers[player] = nil
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		for _, session in sessions do
			local ok, err = pcall(stepSession, session, dt)
			if not ok then
				warn("[Baloncesto] " .. tostring(err))
				if session.Story then
					pcall(deliverStory, session, false)
				else
					pcall(endSession, session)
				end
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			for _, session in sessions do
				pcall(joinViewers, session)
			end
		end
	end)
	task.delay(26, function()
		pcall(scanCourts)
		local ok, err = pcall(placePrompts)
		if not ok then
			warn("[Baloncesto] carteles: " .. tostring(err))
		end
		-- Las pistas a todos (el botón «Jugar» al pisar una): sin esperar a que cada cliente pregunte
		local list = {}
		for _, field in fields do
			table.insert(list, describe(field))
		end
		pcall(function()
			remote:FireAllClients("Fields", list)
		end)
	end)
	initialized = true
end

return BasketService
