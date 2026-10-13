-- FootballService (servidor): fútbol de verdad en los campos del mapa (el del colegio, los estadios,
-- los campos de los barrios…) y en los pasos de fútbol de la historia.
--
--   * Los campos salen solos del mapa: cada pieza «Pitch» de césped con sus postes (Sports/Pitch).
--   * Pachanga: pisas un campo y tocas «⚽ Jugar» (FootballClient). Juego libre con el balón y dos
--     porteros; desde ahí, partido 3 contra 3 o 5 contra 5 contra la máquina, o una tanda de
--     penaltis. Otros jugadores de verdad pueden unirse al mismo campo (ocupan el sitio de una máquina).
--     En un partido, «🧤 Ponerme de portero» (petición Keeper): te pones en la portería de tu equipo
--     (el portero de la máquina pasa a tu sitio) y te estiras con «Entrada»; se recuerda para el
--     siguiente partido.
--   * Historia: MiniGameService llama a startStory con el paso (Game = Futbol / Penaltis / Pases) y
--     el resultado de verdad (goles, penaltis metidos, pases buenos) vuelve a la misión con el mismo
--     formato que el minijuego de antes (Sports/FootballStory). Siempre acaba: por tiempo, por rondas
--     o si te vas del campo; y si no hay campo cerca, MiniGameService juega el minijuego de siempre.
--
-- El balón y los jugadores de la máquina los calcula Sports/FootballSim AQUÍ (con autoridad): no se
-- usa la física de Roblox para el balón (sin dueño de red ni tirones). A los clientes cercanos les
-- llega una foto 15 veces por segundo (remoto FutbolState, sin garantía de entrega: si se pierde una,
-- llega la siguiente) y los sucesos (golpeos, goles, paradas…) por el remoto Futbol. Cada cliente
-- repite la física del balón para verlo fluido y su propio golpeo sale al instante (FootballClient).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Sports = ReplicatedStorage.Shared.Sports
local Pitch = require(Sports.Pitch)
local Ball = require(Sports.Ball)
local Sim = require(Sports.FootballSim)
local Story = require(Sports.FootballStory)
local Cast = require(ReplicatedStorage.Shared.LifeStory.Cast)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Npc = require(script.Parent.Parent.World.Npc)
local SportPrompts = require(script.Parent.Parent.World.SportPrompts)

local FootballService = {}

local SNAPSHOT_EVERY = 1 / 15
local BOT_SYNC_EVERY = 0.2 -- (el servidor coloca a las máquinas de verdad 5 veces por segundo; los clientes, en cada frame)
local VIEW_RANGE = 260 -- a esta distancia del campo te llegan las fotos (para ver un partido de otros)
local LEAVE_MARGIN = 22 -- tan fuera del recinto…
local LEAVE_SECONDS = 8 -- …durante este tiempo: te has ido del campo
local STORY_LEAVE_SECONDS = 14
local EMPTY_SECONDS = 12 -- una pachanga sin nadie se recoge

local TEAM_COLORS = { [1] = Color3.fromRGB(40, 110, 220), [2] = Color3.fromRGB(215, 60, 55) }
local KEEPER_COLORS = { [1] = Color3.fromRGB(250, 200, 40), [2] = Color3.fromRGB(60, 200, 110) }

type Field = { Id: string, Pitch: Pitch.Pitch, Part: BasePart?, Toys: { BasePart }, Virtual: boolean?, HasGoals: boolean? }
type Session = {
	Id: string,
	Field: Field,
	Sim: any,
	Humans: { [Player]: string },
	ById: { [string]: Player },
	Bots: { [string]: Model },
	Folder: Folder,
	Story: { Player: Player, Spec: { [string]: any }, OnDone: ({ [string]: any }) -> (), Done: boolean }?,
	Viewers: { [Player]: boolean },
	Away: { [Player]: number },
	LastSnap: number,
	LastBotSync: number,
	EmptySince: number?,
	Ended: boolean,
	Pickup: string?, -- modo de la pachanga ("Libre", "Partido", "Penaltis")
	Version: number, -- cambia con cada lista de jugadores (las fotos van por posición en Order)
	Order: { string },
	Size: number?,
	BackToFree: number?,
	WantKeeper: { [Player]: boolean }?, -- personas que quieren ser porteras en los partidos
}

local fields: { Field } = {}
local fieldById: { [string]: Field } = {}
local scanned = false
local sessions: { [string]: Session } = {}
local playerSession: { [Player]: Session } = {}
local counter = 0
local initialized = false

local remote: RemoteEvent
local stateRemote: any
local notify: RemoteEvent?
local ProgressionService: any = nil
local ToyService: any = nil

local function say(player: Player, kind: string, text: string)
	if notify then
		notify:FireClient(player, kind, text)
	end
end

---------------------------------------------------------------------
-- Campos del mapa
---------------------------------------------------------------------

local function scanFields()
	scanned = true
	-- (otra búsqueda con partidos en marcha: el campo que ya existía se queda el mismo, con su partido)
	local old = table.clone(fieldById)
	table.clear(fields)
	table.clear(fieldById)
	for _, found in Pitch.scanMap(workspace:GetDescendants()) do
		local field: Field = old[found.Id] or { Id = found.Id, Pitch = found.Pitch, Part = found.Part, Toys = found.Toys, HasGoals = found.HasGoals }
		table.insert(fields, field)
		fieldById[field.Id] = field
	end
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

-- Pies del jugador (en el mundo)
local function feetOf(player: Player): Vector3?
	local root = rootOf(player)
	local humanoid = humanoidOf(player)
	if not root then
		return nil
	end
	local h = if humanoid then humanoid.HipHeight + root.Size.Y / 2 else 3
	return root.Position - Vector3.new(0, h, 0)
end

-- El campo más cercano a un punto (en local, cuánto te sales de él)
local function nearestField(position: Vector3, maxOut: number): (Field?, number)
	if not scanned or #fields == 0 then
		scanFields()
	end
	local best, bestOut = nil, math.huge
	for _, field in fields do
		local loc = Pitch.toLocal(field.Pitch, position)
		local outX = math.max(0, math.abs(loc.X) - field.Pitch.Length / 2)
		local outZ = math.max(0, math.abs(loc.Z) - field.Pitch.Width / 2)
		local out = math.sqrt(outX * outX + outZ * outZ) + (if math.abs(loc.Y) > 25 then 1000 else 0)
		if out < bestOut then
			best, bestOut = field, out
		end
	end
	if best and bestOut <= maxOut then
		return best, bestOut
	end
	return nil, bestOut
end

-- Carteles «Jugar · Fútbol» (World/SportPrompts): en el centro del campo, en los puntos de penalti y
-- en los balones de cada campo. Antes solo había un botón pequeño «Jugar» al pisar el césped.
local joinField: (Player, Field) -> ()
local promptsPlaced = false
local function placePrompts()
	promptsPlaced = true
	local folder = SportPrompts.folder("FutbolPrompts")
	folder:ClearAllChildren()
	local spec = { Sport = "Futbol", Action = "Jugar", Object = "Fútbol", Distance = 12 }
	for _, field in fields do
		if not field.Virtual then
			local p = field.Pitch
			local spots = { Vector3.zero }
			if p.GoalWidth > 0 then
				table.insert(spots, Pitch.penaltySpot(p, -1))
				table.insert(spots, Pitch.penaltySpot(p, 1))
			end
			for i, spot in spots do
				local anchor = SportPrompts.anchor(folder, ("%s_%d"):format(field.Id, i), Pitch.toWorld(p, Vector3.new(spot.X, 2.5, spot.Z)))
				SportPrompts.attach(anchor, spec, function(player)
					joinField(player, field)
				end)
			end
			for _, toy in field.Toys or {} do
				SportPrompts.attach(toy, { Sport = "Futbol", Action = "Jugar", Object = "Fútbol", Distance = 7 }, function(player)
					joinField(player, field)
				end)
			end
		end
	end
end

-- Lo que el cliente necesita para conocer un campo (también los de mentira, como los pases en la calle)
local function describe(field: Field): { [string]: any }
	local p = field.Pitch
	return {
		Id = field.Id,
		CFrame = p.CFrame,
		Length = p.Length,
		Width = p.Width,
		GoalLine = p.GoalLine,
		GoalWidth = p.GoalWidth,
		GoalHeight = p.GoalHeight,
		GoalDepth = p.GoalDepth,
		BoardMargin = p.BoardX - p.Length / 2,
		Virtual = field.Virtual == true,
	}
end

---------------------------------------------------------------------
-- Máquinas (los jugadores que no son personas)
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
	local pitch = session.Field.Pitch
	local feet = Pitch.toWorld(pitch, Vector3.new(p.P.X, 0, p.P.Z))
	local facing = Pitch.dirToWorld(pitch, p.Facing)
	local up = (model:GetAttribute("FootOffset") :: number?) or 3
	local at = feet + Vector3.new(0, up, 0)
	return CFrame.lookAt(at, at + Vector3.new(facing.X, 0, facing.Z))
end

local function spawnBot(session: Session, p: any)
	local pitch = session.Field.Pitch
	local person = p.Npc and Cast.People[p.Npc]
	local keeper = p.Role == "GK"
	local look = {
		Skin = person and person.Skin or nil,
		Hair = person and person.Hair or nil,
		Pants = person and person.Pants or nil,
		-- Peto del equipo (los porteros, de otro color)
		Shirt = if keeper then KEEPER_COLORS[p.Team] else TEAM_COLORS[p.Team],
		Shoes = Color3.fromRGB(240, 240, 240),
		LongSleeves = keeper,
		LongHair = person and person.LongHair or nil,
	}
	local feet = Pitch.toWorld(pitch, Vector3.new(p.P.X, 0, p.P.Z))
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
	model:SetAttribute("SportTeam", p.Team)
	if scale < 0.9 then
		model:SetAttribute("Age", "Nino")
	end
	CollectionService:AddTag(model, "StaticNpc") -- (ActorLife: anda y corre con animación)
	CollectionService:AddTag(model, "NamedActor") -- (NameTags: el nombre encima)
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

local function syncBots(session: Session)
	for id, model in session.Bots do
		local p = session.Sim.Players[id]
		local root = model.PrimaryPart
		if p and root and model.Parent then
			root.CFrame = botCFrame(session, p, model)
		end
	end
end

---------------------------------------------------------------------
-- Mensajes a los clientes
---------------------------------------------------------------------

local function rosterOf(session: Session): { [string]: any }
	local out = {}
	for _, id in session.Sim.Order do
		local p = session.Sim.Players[id]
		local player = session.ById[id]
		out[id] = {
			Name = if player then player.DisplayName else displayName(p.Npc or p.Name),
			Team = p.Team,
			Role = p.Role,
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
		Size = session.Size,
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

-- La foto (pequeña: el remoto sin garantía no admite mucho más de 900 bytes). Los jugadores van en el
-- orden de session.Order (lo sabe el cliente por la última lista, con su Version): posición, hacia
-- dónde mira (ángulo), estirada (vector y progreso, o false) y plancha.
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
		local dive: any = false
		if p.Dive and sim.T >= p.Dive.Start then
			local f = math.clamp((sim.T - p.Dive.Start) / p.Dive.Dur, 0, 1)
			dive = { p.Dive.Target - p.Dive.From, math.floor(f * 100) / 100 }
		end
		rows[i] = { p.P, math.floor(math.atan2(p.Facing.Z, p.Facing.X) * 100) / 100, dive, sim.T < p.Slide }
	end
	local owner = sim.Owner and table.find(session.Order, sim.Owner) or 0
	return {
		S = session.Id,
		V = session.Version,
		Ph = sim.Phase,
		B = { ball.P, ball.V, math.floor(ball.Spin * 100) / 100, owner, sim.KickSeq, ball.InGoal },
		P = rows,
		G = { sim.Score[1], sim.Score[2], math.floor(sim.Clock), sim.Round, sim.Rounds, sim.Hits, sim.Taken },
	}
end

---------------------------------------------------------------------
-- Sesiones
---------------------------------------------------------------------

local function setToysHidden(field: Field, hidden: boolean)
	if not ToyService or not ToyService.setHidden then
		return
	end
	for _, part in field.Toys do
		pcall(ToyService.setHidden, part, hidden)
		local prompt = part:FindFirstChild("JugarFutbol")
		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.Enabled = not hidden -- (el balón escondido mientras se juega: sin cartel)
			prompt:SetAttribute("Off", hidden or nil)
		end
	end
end

local function humanSpec(player: Player, team: number, role: string): { [string]: any }
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
	return { Id = "u" .. player.UserId, Name = player.DisplayName, Team = team, Human = true, Role = role, Scale = scale }
end

local function botSpeed(player: Player?): number
	local humanoid = player and humanoidOf(player)
	if humanoid and humanoid.WalkSpeed > 4 then
		return math.clamp(humanoid.WalkSpeed * 0.95, 10, 18)
	end
	return 15
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

local function newSession(field: Field): Session
	counter += 1
	local folder = Instance.new("Folder")
	folder.Name = "Futbol_" .. field.Id
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
		EmptySince = nil,
		Ended = false,
		Version = 0,
		Order = {},
	}
	sessions[field.Id] = session
	setToysHidden(field, true)
	if not field.HasGoals and not field.Virtual then
		-- Un campo sin porterías en el mapa (el patio de la cárcel…): se ponen mientras se juega
		local pitch = field.Pitch
		local white = Color3.fromRGB(250, 250, 250)
		for _, side in { -1, 1 } do
			local x = side * pitch.GoalLine
			local function piece(name: string, size: Vector3, loc: Vector3, transparency: number?, collide: boolean?)
				local part = Instance.new("Part")
				part.Name = name
				part.Size = size
				part.Color = white
				part.Material = Enum.Material.SmoothPlastic
				part.Transparency = transparency or 0
				part.Anchored = true
				part.CanCollide = collide ~= false
				part.CanQuery = false
				part.CFrame = pitch.CFrame * CFrame.new(loc)
				part.Parent = folder
			end
			for _, z in { -pitch.GoalWidth / 2, pitch.GoalWidth / 2 } do
				piece("GoalPost", Vector3.new(0.4, pitch.GoalHeight, 0.4), Vector3.new(x, pitch.GoalHeight / 2, z))
			end
			piece("GoalBar", Vector3.new(0.4, 0.4, pitch.GoalWidth), Vector3.new(x, pitch.GoalHeight, 0))
			piece("Net", Vector3.new(pitch.GoalDepth, pitch.GoalHeight, pitch.GoalWidth), Vector3.new(x + side * pitch.GoalDepth / 2, pitch.GoalHeight / 2, 0), 0.75, false)
		end
	end
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
	setToysHidden(session.Field, false)
end

-- Monta la simulación de una pachanga con las personas que hay
local function buildPickup(session: Session, mode: string, size: number?)
	local first: Player? = next(session.Humans)
	local sim = Sim.new(session.Field.Pitch, {
		Mode = mode,
		Duration = if mode == "Partido" then 240 else nil,
		Rounds = if mode == "Penaltis" then 5 else nil,
		Need = 0,
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
		local keeper = mode == "Partido" and session.WantKeeper ~= nil and session.WantKeeper[player] == true
		local spec = humanSpec(player, team, if keeper then "GK" else "FW")
		Sim.addPlayer(sim, spec)
		local feet = feetOf(player)
		if feet then
			Sim.setHuman(sim, spec.Id, Pitch.toLocal(session.Field.Pitch, feet))
		end
	end
	if mode == "Partido" then
		Sim.fillTeams(sim, math.clamp(size or 3, 2, 6), {}, {}, { Skill1 = 0.5, Skill2 = 0.5 })
	elseif mode == "Penaltis" then
		Sim.addPlayer(sim, { Id = "gk", Name = "Portero", Team = 2, Role = "GK", Skill = 0.5 })
	else
		Sim.addPlayer(sim, { Id = "gk1", Name = "Portero", Team = 2, Role = "GK", Skill = 0.45 })
		Sim.addPlayer(sim, { Id = "gk2", Name = "Portera", Team = 1, Role = "GK", Skill = 0.45 })
	end
	Sim.start(sim)
	respawnBots(session)
	sendInfo(session)
end

local function joinViewers(session: Session)
	local center = session.Field.Pitch.CFrame.Position
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
	if session.WantKeeper then
		session.WantKeeper[player] = nil
	end
	if playerSession[player] == session then
		playerSession[player] = nil
	end
	player:SetAttribute("InSport", nil)
	if session.Story and session.Story.Player == player then
		if why == "Dead" then
			-- Muerto: sin resultado (MiniGameService/la misión lo vuelven a proponer al volver)
			session.Story.Done = true
			endSession(session)
			return
		end
		deliverStory(session, why ~= "Done")
		return
	end
	Sim.removePlayer(session.Sim, id)
	-- En un partido, su sitio lo ocupa una máquina
	if session.Pickup == "Partido" and not session.Sim.Over then
		local before = {}
		for _, bid in session.Sim.Order do
			before[bid] = true
		end
		Sim.fillTeams(session.Sim, session.Size or 3, {}, {}, { Skill1 = 0.5, Skill2 = 0.5 })
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
	if sim.Mode == "Penaltis" or sim.Mode == "Pases" then
		return false
	end
	local team, role = 1, "FW"
	if sim.Mode == "Partido" and not sim.Over then
		-- Al equipo con menos personas, en el sitio de una máquina
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
			if p.Team == team and not p.Human and p.Role ~= "GK" then
				role = p.Role
				Sim.removePlayer(sim, id)
				removeBot(session, id)
				break
			end
		end
	end
	local spec = humanSpec(player, team, role)
	Sim.addPlayer(sim, spec)
	if sim.Mode == "Partido" then
		Sim.arrange(sim)
		sim.Players[spec.Id].Role = role
	end
	local feet = feetOf(player)
	if feet then
		Sim.setHuman(sim, spec.Id, Pitch.toLocal(session.Field.Pitch, feet))
	end
	session.Humans[player] = spec.Id
	session.ById[spec.Id] = player
	session.Viewers[player] = true
	playerSession[player] = session
	player:SetAttribute("InSport", "Futbol")
	sendInfo(session)
	return true
end

---------------------------------------------------------------------
-- Sucesos del partido
---------------------------------------------------------------------

local function teleportHuman(session: Session, player: Player, loc: Vector3, facing: Vector3?)
	local character = player.Character
	local root = rootOf(player)
	local humanoid = humanoidOf(player)
	if not character or not root then
		return
	end
	local pitch = session.Field.Pitch
	local feet = Pitch.toWorld(pitch, Vector3.new(loc.X, 0, loc.Z))
	local h = if humanoid then humanoid.HipHeight + root.Size.Y / 2 else 3
	local f = Pitch.dirToWorld(pitch, facing or Vector3.new(1, 0, 0))
	local at = feet + Vector3.new(0, h + 0.1, 0)
	character:PivotTo(CFrame.lookAt(at, at + Vector3.new(f.X, 0, f.Z)))
	root.AssemblyLinearVelocity = Vector3.zero
end

local function addXp(player: Player?, amount: number, reason: string)
	if not player or not ProgressionService then
		return
	end
	pcall(ProgressionService.addXp, player, amount, reason)
end

local function handleEvents(session: Session, events: { { [string]: any } })
	local sim = session.Sim
	for _, e in events do
		local kind = e.Kind
		if kind == "Teleport" then
			local player = e.Id and session.ById[e.Id]
			if player then
				teleportHuman(session, player, e.P, e.Facing)
			elseif e.Bot and e.Id and session.Bots[e.Id] then
				local p = sim.Players[e.Id]
				if p then
					session.Bots[e.Id]:PivotTo(botCFrame(session, p, session.Bots[e.Id]))
				end
			end
			broadcast(session, "Event", { Kind = "Teleport", Id = e.Id, P = e.P, Facing = e.Facing })
		elseif kind == "Goal" then
			local scorer = e.Scorer and session.ById[e.Scorer]
			if scorer and not e.OwnGoal then
				addXp(scorer, 6, "FutbolGol")
			end
			broadcast(session, "Event", e)
		elseif kind == "Over" then
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
							addXp(player, 20, "FutbolPartido")
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
	local player = story.Player
	-- Experiencia: cada gol tuyo ya la dio; ganar el partido da la del partido
	if result.Won and story.Spec.Game == "Futbol" then
		addXp(player, 20, "FutbolPartido")
	end
	endSession(session)
	task.spawn(story.OnDone, result)
end

-- Empieza un paso de fútbol de la historia. Devuelve false si no se puede (sin campo cerca…): entonces
-- MiniGameService juega el minijuego de siempre.
function FootballService.startStory(player: Player, spec: { [string]: any }, onDone: ({ [string]: any }) -> ()): boolean
	if not initialized or not Story.Games[spec.Game] or playerSession[player] then
		return false
	end
	local root = rootOf(player)
	local feet = feetOf(player)
	if not root or not feet then
		return false
	end
	local field: Field?
	if spec.Arena == "Aqui" then
		-- Aquí mismo (los pases por la calle): un campo de mentira mirando hacia donde miras
		local look = root.CFrame.LookVector
		local flatLook = Vector3.new(look.X, 0, look.Z)
		flatLook = if flatLook.Magnitude > 1e-3 then flatLook.Unit else Vector3.new(1, 0, 0)
		local center = feet + flatLook * 8
		local cf = CFrame.fromMatrix(center, flatLook, Vector3.new(0, 1, 0))
		field = { Id = "Aqui_" .. player.UserId, Pitch = Pitch.new(cf, 34, 22, { GoalWidth = 0, BoardMargin = 2, Id = "Aqui" }), Toys = {}, Virtual = true }
	else
		local found, out = nearestField(feet, 260)
		field = found
		if not found then
			warn(("[Futbol] %s: sin campo cerca (a %.0f studs); se juega el minijuego de siempre"):format(player.Name, out))
			return false
		end
	end
	local f = field :: Field
	local existing = sessions[f.Id]
	if existing then
		if existing.Story then
			return false
		end
		for other in existing.Humans do
			say(other, "Info", "⚽ El campo se necesita ahora para un partido de la historia.")
		end
		endSession(existing)
	end
	local opts = Story.options(spec)
	local session = newSession(f)
	local scale = humanSpec(player, 1, "FW").Scale
	local sim = Sim.new(f.Pitch, {
		Mode = opts.Mode,
		Duration = opts.Duration,
		Rounds = opts.Rounds,
		Need = opts.Need,
		Variant = opts.Variant,
		StopWhenDecided = opts.StopWhenDecided,
		Scale = scale,
		BotSpeed = botSpeed(player),
		Seed = math.random(1, 1e6),
	})
	session.Sim = sim
	local me = humanSpec(player, 1, opts.HumanRole)
	Sim.addPlayer(sim, me)
	if opts.Mode == "Partido" then
		Sim.fillTeams(sim, opts.Size, opts.Team, opts.Rivals, {
			Keeper1 = opts.Keeper1,
			Keeper2 = opts.Keeper2,
			Skill1 = opts.Skill1,
			Skill2 = opts.Skill2,
			KeeperSkill2 = opts.KeeperSkill2,
		})
		-- Los que no tienen nombre: «Compañero» o el rival de la misión
		for _, id in sim.Order do
			local p = sim.Players[id]
			if not p.Human and not p.Npc then
				p.Name = if p.Team == 1 then "Compañero" else "Rival"
			end
		end
	elseif opts.Mode == "Penaltis" then
		local keeper = opts.Rivals[1]
		Sim.addPlayer(sim, { Id = "gk", Name = keeper, Npc = if Cast.People[keeper] then keeper else nil, Team = 2, Role = "GK", Skill = opts.Skill2 })
	elseif opts.Mode == "Pases" then
		local mate = opts.Team[1]
		Sim.addPlayer(sim, { Id = "mate", Name = mate, Npc = if Cast.People[mate] then mate else nil, Team = 1, Role = "MF", Skill = 0.6 })
		sim.Receiver = "mate"
		local start = if f.Virtual then Vector3.new(-8, 0, 0) else Vector3.new(-f.Pitch.GoalLine * 0.45, 0, 0)
		Sim.setHuman(sim, me.Id, start, Vector3.zero, Vector3.new(1, 0, 0))
		if not f.Virtual then
			teleportHuman(session, player, start, Vector3.new(1, 0, 0))
		end
	end
	session.Humans[player] = me.Id
	session.ById[me.Id] = player
	session.Viewers[player] = true
	session.Story = { Player = player, Spec = spec, OnDone = onDone, Done = false }
	playerSession[player] = session
	player:SetAttribute("InSport", "Futbol")
	Sim.start(sim)
	respawnBots(session)
	joinViewers(session)
	sendInfo(session)
	return true
end

-- Se acabó el tiempo del paso (MiniGameService): el resultado de ahora
function FootballService.stopStory(player: Player)
	local session = playerSession[player]
	if session and session.Story and session.Story.Player == player then
		deliverStory(session, false)
	end
end

-- Cancelado sin resultado (has muerto, la misión se ha cortado…)
function FootballService.cancelStory(player: Player)
	local session = playerSession[player]
	if session and session.Story and session.Story.Player == player then
		session.Story.Done = true
		endSession(session)
	end
end

function FootballService.isPlaying(player: Player): boolean
	return playerSession[player] ~= nil
end

---------------------------------------------------------------------
-- Cada frame
---------------------------------------------------------------------

local function stepSession(session: Session, dt: number)
	local sim = session.Sim
	if not sim or session.Ended then
		return
	end
	local pitch = session.Field.Pitch
	-- Las personas: dónde están (y si se han ido)
	for player, id in session.Humans do
		local root = rootOf(player)
		local humanoid = humanoidOf(player)
		if not root or not humanoid or humanoid.Health <= 0 or not player.Parent then
			removeHuman(session, player, if player.Parent then "Dead" else "Gone")
			continue
		end
		local feet = feetOf(player) :: Vector3
		local loc = Pitch.toLocal(pitch, feet)
		Sim.setHuman(sim, id, loc, Pitch.dirToLocal(pitch, root.AssemblyLinearVelocity), Pitch.dirToLocal(pitch, root.CFrame.LookVector))
		local out = math.abs(loc.X) > pitch.BoardX + LEAVE_MARGIN or math.abs(loc.Z) > pitch.BoardZ + LEAVE_MARGIN or math.abs(loc.Y) > 30
		if out then
			session.Away[player] = session.Away[player] or os.clock()
			local limit = if session.Story then STORY_LEAVE_SECONDS else LEAVE_SECONDS
			if os.clock() - session.Away[player] > limit then
				if session.Story then
					say(player, "Info", "⚽ Te has ido del campo: el partido termina aquí.")
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
	-- Pachanga: tras un partido o una tanda, vuelta al juego libre; sin nadie, se recoge
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
		syncBots(session)
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
	if typeof(x) ~= "Vector3" then
		return nil
	end
	if x.X ~= x.X or x.Y ~= x.Y or x.Z ~= x.Z or x.Magnitude > 1e5 then
		return nil
	end
	return x
end

local function num(x: any, lo: number, hi: number, default: number): number
	local n = tonumber(x)
	if not n or n ~= n then
		return default
	end
	return math.clamp(n, lo, hi)
end

-- Una persona se pone de portera (want) o vuelve al campo en el partido en marcha. El portero de la
-- máquina de su equipo pasa a su sitio; al volver al campo, la portería la coge una máquina.
local function setKeeper(session: Session, player: Player, want: boolean): (boolean, string?)
	local sim = session.Sim
	local id = session.Humans[player]
	local me = id and sim and sim.Players[id]
	if not me then
		return false, nil
	end
	if want == (me.Role == "GK") then
		return true, nil
	end
	if want then
		for _, oid in sim.Order do
			local q = sim.Players[oid]
			if q ~= me and q.Team == me.Team and q.Role == "GK" then
				if q.Human then
					return false, "🧤 En tu equipo ya hay alguien de portero."
				end
				q.Role = if me.Role == "GK" then "MF" else me.Role
			end
		end
		me.Role = "GK"
	else
		me.Role = "FW"
	end
	Sim.arrange(sim)
	sendInfo(session)
	return true, nil
end

-- Entrar a jugar en un campo (botón «Jugar», tecla J o un cartel «Jugar · Fútbol»)
function joinField(player: Player, field: Field)
	if playerSession[player] then
		return
	end
	local existing = sessions[field.Id]
	if existing and existing.Story then
		say(player, "Info", "⚽ Ahora se está jugando un partido de la historia en este campo. ¡Mira y anima!")
		return
	end
	if not existing then
		existing = newSession(field)
		buildPickup(existing, "Libre")
	end
	if not addHuman(existing, player) then
		say(player, "Info", "⚽ Ahora están en una tanda de penaltis. Espera un momento y únete.")
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
	if kind == "Kick" then
		if not session then
			return
		end
		local id = session.Humans[player]
		local k = data.Kind
		local cmd = {
			Kind = if k == "Pass" or k == "Lob" then k else "Shoot",
			Dir = vec(data.Dir),
			Power = num(data.Power, 0, 1, 0.6),
			Curl = num(data.Curl, -1, 1, 0),
			Loft = num(data.Loft, 0, 1, 0),
			Dist = num(data.Dist, 2, 70, 15),
			To = if type(data.To) == "string" then data.To else nil,
			BallP = vec(data.BallP),
		}
		local ok, why = Sim.kick(session.Sim, id, cmd)
		if not ok then
			remote:FireClient(player, "KickRejected", { S = session.Id, Why = why, Nonce = data.Nonce })
		end
	elseif kind == "Tackle" then
		if session then
			Sim.tackle(session.Sim, session.Humans[player], vec(data.Dir))
		end
	elseif kind == "Join" then
		if session then
			return
		end
		local feet = feetOf(player)
		if not feet then
			return
		end
		local field = nearestField(feet, 12)
		if not field or (type(data.F) == "string" and data.F ~= field.Id and fieldById[data.F] == nil) then
			return
		end
		joinField(player, field)
	elseif kind == "Keeper" then
		if not session or session.Story then
			return
		end
		local want = data.On == true
		session.WantKeeper = session.WantKeeper or {}
		local wants = session.WantKeeper :: { [Player]: boolean }
		wants[player] = if want then true else nil
		if session.Pickup ~= "Partido" or session.Sim.Over then
			say(player, "Info", if want then "🧤 En el próximo partido te pones de portero." else "🏃 En el próximo partido juegas de campo.")
			return
		end
		local ok, why = setKeeper(session, player, want)
		if not ok and why then
			wants[player] = nil
			say(player, "Info", why)
		elseif ok then
			say(player, "Info", if want then "🧤 ¡Estás de portero! Para estirarte, «Entrada» hacia donde va el balón." else "🏃 Vuelves a jugar de campo.")
		end
	elseif kind == "Leave" then
		if session then
			if session.Story then
				return -- (en la historia se sale yéndose del campo: así no se sale sin querer)
			end
			removeHuman(session, player, "Leave")
		end
	elseif kind == "Mode" then
		if not session or session.Story then
			return
		end
		local mode = data.Mode
		if mode == "Partido" then
			buildPickup(session, "Partido", math.floor(num(data.Size, 2, 6, 3)))
		elseif mode == "Penaltis" then
			local n = 0
			for _ in session.Humans do
				n += 1
			end
			if n > 1 then
				say(player, "Info", "⚽ La tanda de penaltis es para jugar solo. Con más gente, ¡un partido!")
				return
			end
			buildPickup(session, "Penaltis")
		elseif mode == "Libre" then
			buildPickup(session, "Libre")
		end
	elseif kind == "Fields" then
		if not scanned or #fields == 0 then
			scanFields()
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

function FootballService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remote = remotes:FindFirstChild("Futbol") :: RemoteEvent
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = "Futbol"
		remote.Parent = remotes
	end
	stateRemote = remotes:FindFirstChild("FutbolState")
	if not stateRemote then
		-- Sin garantía de entrega (si una foto se pierde, llega la siguiente); si no existe, uno normal
		local ok, created = pcall(Instance.new, "UnreliableRemoteEvent")
		stateRemote = if ok and created then created else Instance.new("RemoteEvent")
		stateRemote.Name = "FutbolState"
		stateRemote.Parent = remotes
	end
	notify = remotes:FindFirstChild("Notify") :: RemoteEvent?
	pcall(function()
		ProgressionService = require(script.Parent.ProgressionService)
	end)
	pcall(function()
		ToyService = require(script.Parent.ToyService)
	end)
	remote.OnServerEvent:Connect(function(player, kind, data)
		local ok, err = pcall(onRequest, player, kind, data)
		if not ok then
			warn("[Futbol] " .. tostring(err))
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
				warn("[Futbol] " .. tostring(err))
				-- Una sesión rota no se queda colgada: la historia sigue
				if session.Story then
					pcall(deliverStory, session, false)
				else
					pcall(endSession, session)
				end
			end
		end
	end)
	-- Quién mira cada partido (los que se acercan ven el balón y a los jugadores)
	task.spawn(function()
		while true do
			task.wait(1)
			for _, session in sessions do
				pcall(joinViewers, session)
			end
		end
	end)
	-- Los campos: cuando el mapa ya está construido
	task.delay(25, function()
		pcall(scanFields)
		local ok, err = pcall(placePrompts)
		if not ok then
			warn("[Fútbol] carteles: " .. tostring(err))
		end
		-- Los campos a todos (el botón «Jugar» al pisar uno): sin esperar a que cada cliente pregunte
		local list = {}
		for _, field in fields do
			if not field.Virtual then
				table.insert(list, describe(field))
			end
		end
		pcall(function()
			remote:FireAllClients("Fields", list)
		end)
	end)
	initialized = true
end

return FootballService
