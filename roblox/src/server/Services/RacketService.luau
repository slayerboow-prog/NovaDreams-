-- RacketService (servidor): tenis (1 contra 1) y pádel (2 contra 2) de verdad (Sports/RacketSim).
--
--   * En cualquier pista o campo de deporte con sitio (piezas «Court», «HalfCourt», «Pitch» o con la
--     etiqueta «PEArea») sale el botón «🎾 Raqueta» (RacketClient): eliges tenis o pádel y la pista se
--     pinta encima (líneas, red y, en el pádel, cristales) mientras se juega.
--   * Rivales y pareja de la máquina; otros jugadores de verdad pueden unirse en el sitio de una máquina.
--   * Partido corto a 7 puntos (o por tiempo); experiencia al ganar.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Racket = require(ReplicatedStorage.Shared.Sports.RacketSim)
local Npc = require(script.Parent.Parent.World.Npc)

local RacketService = {}

local SNAPSHOT_EVERY = 1 / 15
local TEAM_COLORS = { [1] = Color3.fromRGB(40, 110, 220), [2] = Color3.fromRGB(215, 60, 55) }

type Area = { Id: string, CFrame: CFrame, Length: number, Width: number }

local areas: { Area } = {}
local scanned = false
local sessions: { [string]: { [string]: any } } = {}
local playerSession: { [Player]: { [string]: any } } = {}
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
	local root, h = rootOf(player), humanoidOf(player)
	if not root then
		return nil
	end
	return root.Position - Vector3.new(0, (if h then h.HipHeight + root.Size.Y / 2 else 3), 0)
end

local function scan()
	scanned = true
	table.clear(areas)
	local seen = {}
	local function add(p: Instance)
		if seen[p] or not p:IsA("BasePart") or p.Size.Y > 3 then
			return
		end
		seen[p] = true
		local long, short = math.max(p.Size.X, p.Size.Z), math.min(p.Size.X, p.Size.Z)
		if long < 42 or short < 20 then
			return
		end
		local top = p.CFrame * CFrame.new(0, p.Size.Y / 2, 0)
		local axis = if p.Size.X >= p.Size.Z then top.RightVector else top.LookVector
		axis = Vector3.new(axis.X, 0, axis.Z)
		axis = if axis.Magnitude > 1e-3 then axis.Unit else Vector3.new(1, 0, 0)
		table.insert(areas, {
			Id = ("R%d_%d"):format(math.floor(p.Position.X), math.floor(p.Position.Z)),
			CFrame = CFrame.fromMatrix(top.Position, axis, Vector3.new(0, 1, 0)),
			Length = long,
			Width = short,
		})
	end
	for _, p in CollectionService:GetTagged("PEArea") do
		add(p)
	end
	for _, d in workspace:GetDescendants() do
		if d.Name == "Court" or d.Name == "HalfCourt" or d.Name == "Pitch" then
			add(d)
		end
	end
end

local function areaAt(position: Vector3): Area?
	if not scanned then
		scan()
	end
	for _, a in areas do
		local loc = a.CFrame:PointToObjectSpace(position)
		if math.abs(loc.X) <= a.Length / 2 + 2 and math.abs(loc.Z) <= a.Width / 2 + 2 and math.abs(loc.Y) < 10 then
			return a
		end
	end
	return nil
end

local function paint(session: { [string]: any })
	local sim, cf, folder = session.Sim, session.CFrame, session.Folder
	local function part(name: string, size: Vector3, loc: Vector3, color: Color3, transparency: number?, material: Enum.Material?)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Transparency = transparency or 0
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.CFrame = cf * CFrame.new(loc)
		p.Parent = folder
	end
	local h, w = sim.Half, sim.Width
	local white = Color3.fromRGB(245, 245, 245)
	local floor = if sim.Kind == "Padel" then Color3.fromRGB(40, 110, 190) else Color3.fromRGB(60, 140, 90)
	part("Suelo", Vector3.new(2 * h, 0.05, w), Vector3.new(0, 0.03, 0), floor, 0.25)
	for _, z in { -w / 2, w / 2 } do
		part("Linea", Vector3.new(2 * h, 0.07, 0.25), Vector3.new(0, 0.05, z), white)
	end
	for _, x in { -h, h } do
		part("Linea", Vector3.new(0.25, 0.07, w), Vector3.new(x, 0.05, 0), white)
	end
	part("LineaSaque", Vector3.new(0.2, 0.07, w), Vector3.new(-h * 0.6, 0.05, 0), white)
	part("LineaSaque", Vector3.new(0.2, 0.07, w), Vector3.new(h * 0.6, 0.05, 0), white)
	part("LineaCentro", Vector3.new(h * 1.2, 0.07, 0.2), Vector3.new(0, 0.05, 0), white)
	for _, z in { -w / 2 - 0.5, w / 2 + 0.5 } do
		part("Poste", Vector3.new(0.3, sim.Net + 0.3, 0.3), Vector3.new(0, (sim.Net + 0.3) / 2, z), Color3.fromRGB(60, 60, 66))
	end
	part("Red", Vector3.new(0.08, sim.Net - 0.2, w + 1), Vector3.new(0, (sim.Net - 0.2) / 2, 0), Color3.fromRGB(20, 20, 24), 0.5)
	part("Cinta", Vector3.new(0.1, 0.2, w + 1), Vector3.new(0, sim.Net, 0), white)
	if sim.Walls then
		local glass = Color3.fromRGB(200, 230, 255)
		local wh = sim.WallHeight
		for _, x in { -h, h } do
			part("Cristal", Vector3.new(0.2, wh, w), Vector3.new(x + math.sign(x) * 0.2, wh / 2, 0), glass, 0.75, Enum.Material.Glass)
		end
		for _, z in { -w / 2, w / 2 } do
			part("Cristal", Vector3.new(2 * h, wh * 0.45, 0.2), Vector3.new(0, wh * 0.225, z + math.sign(z) * 0.2), glass, 0.8, Enum.Material.Glass)
		end
	end
end

local function spawnBot(session: { [string]: any }, p: any)
	local look = { Shirt = TEAM_COLORS[p.Team], Pants = Color3.fromRGB(240, 240, 240), Shoes = Color3.fromRGB(240, 240, 240) }
	local ok, model = pcall(Npc.create, p.Name, session.Folder, CFrame.new(session.CFrame:PointToWorldSpace(p.P)), look)
	if not ok or not model then
		return
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if humanoid then
		humanoid.DisplayName = p.Name
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	if humanoid and root then
		model:SetAttribute("FootOffset", humanoid.HipHeight + root.Size.Y / 2)
	end
	CollectionService:AddTag(model, "StaticNpc")
	CollectionService:AddTag(model, "NamedActor")
	CollectionService:AddTag(model, "SportBot")
	session.Bots[p.Id] = model
end

local function roster(session: { [string]: any }): { [string]: any }
	local out = {}
	for _, id in session.Sim.Order do
		local p = session.Sim.Players[id]
		local player = session.ById[id]
		out[id] = { Name = if player then player.DisplayName else p.Name, Team = p.Team, Human = p.Human, Model = session.Bots[id] or (player and player.Character) }
	end
	return out
end

local function sendInfo(session: { [string]: any })
	session.Order = table.clone(session.Sim.Order)
	for player, id in session.Humans do
		remote:FireClient(player, "Session", {
			Kind = session.Sim.Kind,
			CFrame = session.CFrame,
			Half = session.Sim.Half,
			Width = session.Sim.Width,
			Net = session.Sim.Net,
			Walls = session.Sim.Walls,
			WallHeight = session.Sim.WallHeight,
			Gravity = session.Sim.Gravity,
			Bounce = session.Sim.Bounce,
			Order = session.Order,
			Roster = roster(session),
			You = id,
		})
	end
end

local function endSession(session: { [string]: any })
	if session.Ended then
		return
	end
	session.Ended = true
	sessions[session.Area.Id] = nil
	for player in session.Humans do
		playerSession[player] = nil
		player:SetAttribute("InSport", nil)
		remote:FireClient(player, "End", {})
	end
	session.Folder:Destroy()
end

local function removeHuman(session: { [string]: any }, player: Player)
	local id = session.Humans[player]
	if not id then
		return
	end
	session.Humans[player] = nil
	session.ById[id] = nil
	playerSession[player] = nil
	player:SetAttribute("InSport", nil)
	remote:FireClient(player, "End", {})
	if next(session.Humans) == nil then
		endSession(session)
		return
	end
	-- Su sitio, para una máquina
	local p = session.Sim.Players[id]
	p.Human = false
	p.Name = "Jugador"
	spawnBot(session, p)
	sendInfo(session)
end

local function start(player: Player, area: Area, kind: string)
	local sim = Racket.new({ Kind = kind, Seed = math.random(1, 1e6) })
	if area.Length < 2 * sim.Half + 2 or area.Width < sim.Width - 2 then
		remote:FireClient(player, "Error", { Text = "Esta pista es pequeña para eso. Prueba el pádel." })
		return
	end
	local me = "u" .. player.UserId
	Racket.addPlayer(sim, { Id = me, Name = player.DisplayName, Team = 1, Human = true })
	if kind == "Padel" then
		Racket.addPlayer(sim, { Id = "m", Name = "Pareja", Team = 1, Skill = 0.55 })
		Racket.addPlayer(sim, { Id = "r1", Name = "Rival", Team = 2, Skill = 0.45 })
		Racket.addPlayer(sim, { Id = "r2", Name = "Rival", Team = 2, Skill = 0.45 })
	else
		Racket.addPlayer(sim, { Id = "r1", Name = "Rival", Team = 2, Skill = 0.45 })
	end
	local folder = Instance.new("Folder")
	folder.Name = "Raqueta_" .. area.Id
	folder.Parent = workspace
	local session = { Area = area, CFrame = area.CFrame, Sim = sim, Folder = folder, Bots = {}, Humans = { [player] = me }, ById = { [me] = player }, LastSnap = 0, Ended = false, Order = {} }
	sessions[area.Id] = session
	playerSession[player] = session
	player:SetAttribute("InSport", "Raqueta")
	paint(session)
	for _, id in sim.Order do
		local p = sim.Players[id]
		if not p.Human then
			spawnBot(session, p)
		end
	end
	sendInfo(session)
	Racket.start(sim)
end

local function join(player: Player, session: { [string]: any })
	-- En el sitio de una máquina del equipo con menos personas
	local sim = session.Sim
	local count = { [1] = 0, [2] = 0 }
	for _, id in session.Humans do
		count[sim.Players[id].Team] += 1
	end
	local team = if count[2] < count[1] then 2 else 1
	for _, id in sim.Order do
		local p = sim.Players[id]
		if p.Team == team and not p.Human then
			local model = session.Bots[id]
			if model then
				model:Destroy()
				session.Bots[id] = nil
			end
			p.Human = true
			p.Name = player.DisplayName
			session.Humans[player] = id
			session.ById[id] = player
			playerSession[player] = session
			player:SetAttribute("InSport", "Raqueta")
			sendInfo(session)
			return
		end
	end
	remote:FireClient(player, "Error", { Text = "La pista está llena." })
end

local function stepSession(session: { [string]: any }, dt: number)
	local sim = session.Sim
	for player, id in session.Humans do
		local root, humanoid = rootOf(player), humanoidOf(player)
		if not player.Parent or not root or not humanoid or humanoid.Health <= 0 then
			removeHuman(session, player)
			continue
		end
		local loc = session.CFrame:PointToObjectSpace(feetOf(player) :: Vector3)
		if math.abs(loc.X) > sim.Half + 30 or math.abs(loc.Z) > sim.Width / 2 + 30 then
			removeHuman(session, player)
			continue
		end
		Racket.setHuman(sim, id, loc)
	end
	if session.Ended then
		return
	end
	for _, e in Racket.step(sim, dt) do
		if e.Kind == "Teleport" then
			local player = session.ById[e.Id]
			if player and player.Character then
				local root, humanoid = rootOf(player), humanoidOf(player)
				if root and humanoid then
					local at = session.CFrame:PointToWorldSpace(e.P) + Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2 + 0.1, 0)
					local character = player.Character :: Model
					character:PivotTo(CFrame.lookAt(at, at + session.CFrame:VectorToWorldSpace(e.Facing)))
				end
			end
		elseif e.Kind == "Over" then
			for player, id in session.Humans do
				local p = sim.Players[id]
				if p and sim.Score[p.Team] > sim.Score[3 - p.Team] and ProgressionService then
					pcall(ProgressionService.addXp, player, 15, "Raqueta")
				end
			end
			task.delay(5, function()
				endSession(session)
			end)
		end
		for player in session.Humans do
			remote:FireClient(player, "Event", e)
		end
	end
	session.LastSnap += dt
	if session.LastSnap >= SNAPSHOT_EVERY then
		session.LastSnap = 0
		local rows = {}
		for i, id in session.Order do
			local p = sim.Players[id]
			rows[i] = if p then p.P else false
		end
		local snap = { B = { sim.Ball.P, sim.Ball.V, sim.Seq }, P = rows, Ph = sim.Phase, G = { sim.Score[1], sim.Score[2] }, Sv = sim.Server }
		for player in session.Humans do
			stateRemote:FireClient(player, snap)
		end
		for id, model in session.Bots do
			local p = sim.Players[id]
			if p and model.PrimaryPart then
				local at = session.CFrame:PointToWorldSpace(p.P) + Vector3.new(0, (model:GetAttribute("FootOffset") :: number?) or 3, 0)
				model.PrimaryPart.CFrame = CFrame.lookAt(at, at + session.CFrame:VectorToWorldSpace(Vector3.new(-Racket.side(p.Team), 0, 0)))
			end
		end
	end
end

function RacketService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remote = remotes:FindFirstChild("Raqueta") :: RemoteEvent
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = "Raqueta"
		remote.Parent = remotes
	end
	stateRemote = remotes:FindFirstChild("RaquetaState")
	if not stateRemote then
		local ok, created = pcall(Instance.new, "UnreliableRemoteEvent")
		stateRemote = if ok and created then created else Instance.new("RemoteEvent")
		stateRemote.Name = "RaquetaState"
		stateRemote.Parent = remotes
	end
	pcall(function()
		ProgressionService = require(script.Parent.ProgressionService)
	end)
	remote.OnServerEvent:Connect(function(player, kind, data)
		local ok, err = pcall(function()
			data = if type(data) == "table" then data else {}
			local session = playerSession[player]
			if kind == "Areas" then
				if not scanned then
					scan()
				end
				local list = {}
				for _, a in areas do
					table.insert(list, { Id = a.Id, CFrame = a.CFrame, Length = a.Length, Width = a.Width })
				end
				remote:FireClient(player, "Areas", list)
			elseif kind == "Join" then
				if session or player:GetAttribute("InSport") then
					return
				end
				local feet = feetOf(player)
				local area = feet and areaAt(feet)
				if not area then
					return
				end
				local existing = sessions[area.Id]
				if existing then
					join(player, existing)
				else
					start(player, area, if data.Kind == "Padel" then "Padel" else "Tenis")
				end
			elseif kind == "Leave" then
				if session then
					removeHuman(session, player)
				end
			elseif kind == "Hit" and session then
				local sim = session.Sim
				local id = session.Humans[player]
				local aim = if typeof(data.Aim) == "Vector3" and data.Aim.X == data.Aim.X then data.Aim else nil
				local q = tonumber(data.Quality)
				q = if q and q == q then math.clamp(q, 0.1, 1) else nil
				if sim.Phase == "Serve" and sim.Server == id then
					Racket.serve(sim, id, aim, q)
				else
					-- (su pantalla va por delante: un poco más de alcance)
					local me = sim.Players[id]
					local saved = me.P
					local b = sim.Ball.P
					local d = Vector3.new(b.X - me.P.X, 0, b.Z - me.P.Z)
					if d.Magnitude > sim.Reach - 0.3 and d.Magnitude < sim.Reach + 1.8 then
						me.P = Vector3.new(b.X, 0, b.Z) - d.Unit * (sim.Reach - 0.4)
					end
					Racket.hit(sim, id, aim, if data.Lob then "Globo" else "Golpe", q)
					me.P = saved
				end
			end
		end)
		if not ok then
			warn("[Raqueta] " .. tostring(err))
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local s = playerSession[player]
		if s then
			pcall(removeHuman, s, player)
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		for _, session in sessions do
			local ok, err = pcall(stepSession, session, dt)
			if not ok then
				warn("[Raqueta] " .. tostring(err))
				pcall(endSession, session)
			end
		end
	end)
	task.delay(27, function()
		pcall(scan)
	end)
end

return RacketService
