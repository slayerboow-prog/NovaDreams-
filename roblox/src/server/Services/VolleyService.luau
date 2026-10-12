-- VolleyService (servidor): vóley playa 2 contra 2 de verdad (Sports/VolleySim) en la historia.
--
--   * La pista se monta en la arena donde estás (líneas, postes y red) mientras dura el partido, de
--     frente a donde miras; si no hay sitio llano, MiniGameService juega el panel de siempre.
--   * Tú y tu pareja (la máquina) contra dos rivales (la máquina). Golpeas con un botón (VolleyClient):
--     recibir, colocar o rematar según dónde estés, y la calidad según la altura del balón.
--   * El resultado (puntos) vuelve a la misión (Sports/VolleyStory). Siempre acaba: a 7 puntos o por
--     tiempo, y si sacas tarde, el saque sale solo.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Sports = ReplicatedStorage.Shared.Sports
local Volley = require(Sports.VolleySim)
local Story = require(Sports.VolleyStory)
local Cast = require(ReplicatedStorage.Shared.LifeStory.Cast)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Npc = require(script.Parent.Parent.World.Npc)

local VolleyService = {}

local SNAPSHOT_EVERY = 1 / 15
local TEAM_COLORS = { [1] = Color3.fromRGB(40, 110, 220), [2] = Color3.fromRGB(215, 60, 55) }

local sessions: { [Player]: { [string]: any } } = {}
local initialized = false
local remote: RemoteEvent
local stateRemote: any

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
local function displayName(name: string?): string
	if name and Cast.People[name] then
		local ok, text = pcall(function()
			return Strings.get(Cast.nameOf(name, {}))
		end)
		if ok and type(text) == "string" then
			return text
		end
	end
	return name or "Jugador"
end

-- ¿Hay sitio llano para la pista? (la arena a la altura de tus pies en las esquinas)
local function flatEnoughRaw(cf: CFrame, half: number, width: number, ignore: { Instance }): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	for _, corner in { Vector3.new(-half, 0, -width / 2), Vector3.new(half, 0, -width / 2), Vector3.new(-half, 0, width / 2), Vector3.new(half, 0, width / 2), Vector3.zero } do
		local p = cf:PointToWorldSpace(corner)
		local hit = workspace:Raycast(p + Vector3.new(0, 8, 0), Vector3.new(0, -16, 0), params)
		if not hit or math.abs(hit.Position.Y - p.Y) > 2.5 or hit.Material == Enum.Material.Water then
			return false
		end
	end
	return true
end

local function flatEnough(cf: CFrame, half: number, width: number, ignore: { Instance }): boolean
	local ok, result = pcall(flatEnoughRaw, cf, half, width, ignore)
	return ok and result == true
end

local function paint(session: { [string]: any })
	local sim, cf, folder = session.Sim, session.CFrame, session.Folder
	local function part(name: string, size: Vector3, loc: Vector3, color: Color3, transparency: number?)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.Transparency = transparency or 0
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = transparency == nil
		p.CFrame = cf * CFrame.new(loc)
		p.Parent = folder
	end
	local h, w, net = sim.Half, sim.Width, sim.NetHeight
	local blue = Color3.fromRGB(40, 120, 230)
	part("Linea", Vector3.new(2 * h, 0.06, 0.3), Vector3.new(0, 0.04, -w / 2), blue)
	part("Linea", Vector3.new(2 * h, 0.06, 0.3), Vector3.new(0, 0.04, w / 2), blue)
	part("Linea", Vector3.new(0.3, 0.06, w), Vector3.new(-h, 0.04, 0), blue)
	part("Linea", Vector3.new(0.3, 0.06, w), Vector3.new(h, 0.04, 0), blue)
	for _, z in { -w / 2 - 0.6, w / 2 + 0.6 } do
		part("Poste", Vector3.new(0.35, net + 0.6, 0.35), Vector3.new(0, (net + 0.6) / 2, z), Color3.fromRGB(230, 230, 235))
	end
	part("Red", Vector3.new(0.1, 3, w + 1.2), Vector3.new(0, net - 1.5, 0), Color3.fromRGB(20, 20, 24), 0.55)
	part("Cinta", Vector3.new(0.12, 0.25, w + 1.2), Vector3.new(0, net, 0), Color3.fromRGB(245, 245, 245))
end

local function spawnBot(session: { [string]: any }, p: any)
	local person = p.Npc and Cast.People[p.Npc]
	local look = {
		Skin = person and person.Skin or nil,
		Hair = person and person.Hair or nil,
		Pants = Color3.fromRGB(30, 30, 40),
		Shirt = TEAM_COLORS[p.Team],
		LongHair = person and person.LongHair or nil,
	}
	local ok, model = pcall(Npc.create, displayName(p.Npc or p.Name), session.Folder, CFrame.new(session.CFrame:PointToWorldSpace(p.P)), look)
	if not ok or not model then
		return
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
	CollectionService:AddTag(model, "StaticNpc")
	CollectionService:AddTag(model, "NamedActor")
	CollectionService:AddTag(model, "SportBot")
	session.Bots[p.Id] = model
end

local function endSession(session: { [string]: any })
	if session.Ended then
		return
	end
	session.Ended = true
	sessions[session.Player] = nil
	session.Player:SetAttribute("InSport", nil)
	remote:FireClient(session.Player, "End", {})
	session.Folder:Destroy()
end

local function deliver(session: { [string]: any }, abandoned: boolean?)
	if session.Done then
		return
	end
	session.Done = true
	local result = Story.result(session.Spec, Volley.outcome(session.Sim), abandoned == true)
	endSession(session)
	task.spawn(session.OnDone, result)
end

function VolleyService.startStory(player: Player, spec: { [string]: any }, onDone: ({ [string]: any }) -> ()): boolean
	if not initialized or not Story.Games[spec.Game] or sessions[player] then
		return false
	end
	local root, feet = rootOf(player), feetOf(player)
	if not root or not feet then
		return false
	end
	local opts = Story.options(spec)
	local sim = Volley.new({ Points = opts.Points, Duration = opts.Duration, Seed = math.random(1, 1e6) })
	-- La pista: delante de ti, en tu lado; prueba a girarla si no hay sitio llano
	local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	look = if look.Magnitude > 1e-3 then look.Unit else Vector3.new(1, 0, 0)
	local cf: CFrame? = nil
	for turn = 0, 3 do
		local a = turn * math.pi / 2
		local dir = Vector3.new(look.X * math.cos(a) - look.Z * math.sin(a), 0, look.X * math.sin(a) + look.Z * math.cos(a))
		local candidate = CFrame.fromMatrix(feet + dir * (sim.Half * 0.55), dir, Vector3.new(0, 1, 0))
		if flatEnough(candidate, sim.Half + 2, sim.Width + 2, { player.Character :: Instance }) then
			cf = candidate
			break
		end
	end
	if not cf then
		warn(("[Vóley] %s: sin sitio llano para la pista; se juega el minijuego de siempre"):format(player.Name))
		return false
	end
	local me = "u" .. player.UserId
	Volley.addPlayer(sim, { Id = me, Name = player.DisplayName, Team = 1, Human = true })
	local mate = opts.Team[1]
	Volley.addPlayer(sim, { Id = "m", Name = mate or "Pareja", Npc = mate, Team = 1, Skill = opts.Skill1 })
	for i = 1, 2 do
		local rival = opts.Rivals[i]
		Volley.addPlayer(sim, { Id = "r" .. i, Name = rival or "Rival", Npc = rival, Team = 2, Skill = opts.Skill2 })
	end
	local folder = Instance.new("Folder")
	folder.Name = "Voley_" .. player.UserId
	folder.Parent = workspace
	local session = { Player = player, Spec = spec, OnDone = onDone, Sim = sim, CFrame = cf, Folder = folder, Bots = {}, Me = me, LastSnap = 0, Done = false, Ended = false }
	sessions[player] = session
	player:SetAttribute("InSport", "Voley")
	paint(session)
	for _, id in sim.Order do
		local p = sim.Players[id]
		if not p.Human then
			spawnBot(session, p)
		end
	end
	local roster = {}
	for _, id in sim.Order do
		local p = sim.Players[id]
		roster[id] = { Name = if p.Human then player.DisplayName else displayName(p.Npc or p.Name), Team = p.Team, Human = p.Human, Model = session.Bots[id] }
	end
	remote:FireClient(player, "Session", {
		CFrame = cf,
		Half = sim.Half,
		Width = sim.Width,
		NetHeight = sim.NetHeight,
		Points = sim.Points,
		Order = sim.Order,
		Roster = roster,
		You = me,
		Title = spec.Title,
		Icon = spec.Icon,
		Hint = spec.Hint,
	})
	Volley.start(sim)
	return true
end

function VolleyService.stopStory(player: Player)
	local s = sessions[player]
	if s then
		deliver(s, false)
	end
end

function VolleyService.cancelStory(player: Player)
	local s = sessions[player]
	if s then
		s.Done = true
		endSession(s)
	end
end

local function stepSession(session: { [string]: any }, dt: number)
	local player, sim = session.Player, session.Sim
	local root, humanoid = rootOf(player), humanoidOf(player)
	if not player.Parent or not root or not humanoid or humanoid.Health <= 0 then
		if player.Parent then
			session.Done = true
			endSession(session)
		else
			deliver(session, true)
		end
		return
	end
	local loc = session.CFrame:PointToObjectSpace(feetOf(player) :: Vector3)
	if math.abs(loc.X) > sim.Half + 30 or math.abs(loc.Z) > sim.Width / 2 + 30 then
		session.Away = session.Away or os.clock()
		if os.clock() - session.Away > 12 then
			deliver(session, true)
			return
		end
	else
		session.Away = nil
	end
	Volley.setHuman(sim, session.Me, loc, session.CFrame:VectorToObjectSpace(root.AssemblyLinearVelocity), session.CFrame:VectorToObjectSpace(root.CFrame.LookVector))
	for _, e in Volley.step(sim, dt) do
		if e.Kind == "Teleport" and e.Id == session.Me then
			local f = session.CFrame:VectorToWorldSpace(e.Facing)
			local at = session.CFrame:PointToWorldSpace(e.P) + Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2 + 0.1, 0)
			local character = player.Character :: Model
			character:PivotTo(CFrame.lookAt(at, at + f))
		elseif e.Kind == "Over" then
			task.delay(2.5, function()
				deliver(session, false)
			end)
		end
		remote:FireClient(player, "Event", e)
	end
	session.LastSnap += dt
	if session.LastSnap >= SNAPSHOT_EVERY then
		session.LastSnap = 0
		local rows = {}
		for i, id in sim.Order do
			local p = sim.Players[id]
			rows[i] = { p.P, sim.T < p.Jump }
		end
		stateRemote:FireClient(player, { B = { sim.Ball.P, sim.Ball.V, sim.Seq }, P = rows, Ph = sim.Phase, G = { sim.Score[1], sim.Score[2] }, Sv = sim.Server })
		for id, model in session.Bots do
			local p = sim.Players[id]
			if p and model.PrimaryPart then
				local at = session.CFrame:PointToWorldSpace(p.P) + Vector3.new(0, (model:GetAttribute("FootOffset") :: number?) or 3, 0)
				model.PrimaryPart.CFrame = CFrame.lookAt(at, at + session.CFrame:VectorToWorldSpace(p.Facing))
			end
		end
	end
end

function VolleyService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remote = remotes:FindFirstChild("Voley") :: RemoteEvent
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = "Voley"
		remote.Parent = remotes
	end
	stateRemote = remotes:FindFirstChild("VoleyState")
	if not stateRemote then
		local ok, created = pcall(Instance.new, "UnreliableRemoteEvent")
		stateRemote = if ok and created then created else Instance.new("RemoteEvent")
		stateRemote.Name = "VoleyState"
		stateRemote.Parent = remotes
	end
	remote.OnServerEvent:Connect(function(player, kind, data)
		local session = sessions[player]
		if not session or type(data) ~= "table" then
			return
		end
		local sim = session.Sim
		local aim = if typeof(data.Aim) == "Vector3" and data.Aim.X == data.Aim.X then data.Aim else nil
		local q = tonumber(data.Quality)
		if q and q ~= q then
			q = nil
		end
		if kind == "Hit" then
			if sim.Phase == "Serve" and sim.Server == session.Me then
				Volley.serve(sim, session.Me, aim, if q then math.clamp(q, 0.3, 1) else nil)
			else
				-- (su pantalla va por delante: se le da un poco más de alcance)
				local me = sim.Players[session.Me]
				local ball = sim.Ball.P
				local d = Vector3.new(ball.X - me.P.X, 0, ball.Z - me.P.Z).Magnitude
				if d <= 3.4 + 1.6 then
					local saved = me.P
					if d > 3.2 then
						me.P = Vector3.new(ball.X, 0, ball.Z) - Vector3.new(ball.X - me.P.X, 0, ball.Z - me.P.Z).Unit * 3
					end
					Volley.hit(sim, session.Me, aim, if q then math.clamp(q, 0.1, 1) else nil)
					me.P = saved
				end
			end
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
				warn("[Vóley] " .. tostring(err))
				pcall(deliver, session, false)
			end
		end
	end)
	initialized = true
end

return VolleyService
