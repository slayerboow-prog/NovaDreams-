-- RacketClient (cliente): tenis y pádel de verdad en tu pantalla (RacketService lleva el partido).
--
-- En una pista o campo de deporte sale «Deportes»: tenis (1 contra 1), pádel (2 contra 2) o una
-- carrera de velocidad (RaceService).
-- CONTROLES: muévete hacia el círculo (donde va a botar la pelota) y toca «Golpe» cuando te llegue a
-- la altura de la cintura y a un lado (el botón se enciende cuando está a tu alcance); «Globo» la manda
-- alta por encima del rival. Apuntas con la cámara. Para sacar, «Golpe». «Salir» deja la pista.
-- Ordenador: clic o F = golpe, R = globo. Mando: RT, X.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Theme = require(script.Parent.Parent.UI.Theme)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local SportAnim = require(script.Parent.SportAnim)
local SportInput = require(script.Parent.SportInput)
local Racket = require(ReplicatedStorage.Shared.Sports.RacketSim)

local RacketClient = {}

local player = Players.LocalPlayer
local create = Theme.create
local rgb = Color3.fromRGB

local remote: RemoteEvent? = nil
local match: { [string]: any }? = nil
local areas: { { [string]: any } } = {}
local areaOn: string? = nil
local fakeSim: { [string]: any }? = nil
local ballPart: BasePart? = nil
local marker: BasePart? = nil
local offset = Vector3.zero
local lastSeq = 0
local ignoreUntil = 0
local phase = "Idle"
local server: string? = nil
local targets: { [string]: Vector3 } = {}
local shown: { [string]: Vector3 } = {}

local gui: ScreenGui
local board: Frame
local scoreLabel: TextLabel
local banner: TextLabel
local menu: Frame
local bannerToken = 0

local function showBanner(text: string, color: Color3?, seconds: number?)
	bannerToken += 1
	local token = bannerToken
	banner.Text = text
	banner.TextColor3 = color or Color3.new(1, 1, 1)
	banner.Visible = true
	task.delay(seconds or 1.2, function()
		if bannerToken == token then
			banner.Visible = false
		end
	end)
end

local function build()
	gui = create("ScreenGui", { Name = "RaquetaGui", ResetOnSpawn = false, DisplayOrder = 6, Parent = player:WaitForChild("PlayerGui") })
	board = Theme.panel({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 84), Size = UDim2.fromOffset(320, 40), Visible = false, Parent = gui })
	scoreLabel = Theme.label({ Size = UDim2.fromScale(1, 1), Font = Theme.FontBold, TextSize = 22, RichText = true, TextXAlignment = Enum.TextXAlignment.Center, Parent = board })
	banner = Theme.label({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.32), Size = UDim2.fromOffset(600, 64), Font = Theme.FontBold, TextSize = 44, TextStrokeTransparency = 0.3, TextXAlignment = Enum.TextXAlignment.Center, Visible = false, Parent = gui })
	menu = Theme.panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(280, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, Parent = gui })
	Theme.padding(12).Parent = menu
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = menu })
	Theme.title({ Size = UDim2.new(1, 0, 0, 26), Text = "🏟️ ¿A qué jugamos?", LayoutOrder = 0, Parent = menu })
	for i, option in { { "🎾 Tenis (1 contra 1)", "Tenis" }, { "🎾 Pádel (2 contra 2)", "Padel" }, { "🏃 Carrera de velocidad", "Carrera" }, { "Cerrar", nil } } do
		local button = Theme.button({ Size = UDim2.new(1, 0, 0, 42), Text = option[1], TextSize = 17, LayoutOrder = i, Parent = menu })
		button.Activated:Connect(function()
			menu.Visible = false
			if option[2] == "Carrera" then
				-- (la carrera la lleva RaceService)
				local race = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Carrera")
				if race then
					(race :: RemoteEvent):FireServer("Pickup", { Kind = "Carrera" })
				end
			elseif option[2] and remote then
				remote:FireServer("Join", { Kind = option[2] })
			end
		end)
	end
	Theme.popupScale(gui, { { Frame = menu, Margin = 40 } })
end

local function feet(): Vector3?
	local c = player.Character
	local root = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
	local h = c and c:FindFirstChildOfClass("Humanoid")
	if not root or not match then
		return nil
	end
	return match.CFrame:PointToObjectSpace(root.Position - Vector3.new(0, (if h then h.HipHeight + root.Size.Y / 2 else 3), 0))
end

local function reachable(): boolean
	local me = feet()
	if not me or not match or not fakeSim then
		return false
	end
	if phase == "Serve" then
		return server == match.You
	end
	local b = fakeSim.Ball.P
	local d = Vector3.new(b.X - me.X, 0, b.Z - me.Z).Magnitude
	return phase == "Rally" and b.X * me.X > -1 and d <= fakeSim.Reach + 1 and b.Y >= 0.5 and b.Y <= 6.5
end

local function aimPoint(): Vector3
	local m = match :: any
	local dir = m.CFrame:VectorToObjectSpace(workspace.CurrentCamera.CFrame.LookVector)
	dir = Vector3.new(dir.X, 0, dir.Z)
	dir = if dir.Magnitude > 1e-3 then dir.Unit else Vector3.new(1, 0, 0)
	local me = feet() or Vector3.zero
	local p = me + dir * (m.Half * 1.2)
	local other = if me.X <= 0 then 1 else -1
	return Vector3.new(other * math.clamp(math.abs(p.X), 4, m.Half - 1.5), 0, math.clamp(p.Z, -m.Width / 2 + 1, m.Width / 2 - 1))
end

local function swing(lob: boolean)
	if not match or not remote or not fakeSim or not reachable() then
		return
	end
	local me = feet()
	local quality = nil
	if me and phase == "Rally" then
		quality = Racket.quality(fakeSim, { P = me })
	end
	SportAnim.play(player.Character, if lob then "Tiro" else "Pase")
	remote:FireServer("Hit", { Aim = aimPoint(), Quality = quality, Lob = lob })
end

local function finish()
	match = nil
	fakeSim = nil
	board.Visible = false
	TouchLayout.setSport(false)
	TouchLayout.refresh()
	if ballPart then
		ballPart:Destroy()
		ballPart = nil
	end
	if marker then
		marker:Destroy()
		marker = nil
	end
	targets, shown = {}, {}
end

local function onSession(data: { [string]: any })
	match = data
	local kind = Racket.Kinds[data.Kind] or Racket.Kinds.Tenis
	fakeSim = { Ball = { P = Vector3.new(0, 3, 0), V = Vector3.zero }, Half = data.Half, Width = data.Width, Net = data.Net, Walls = data.Walls, WallHeight = data.WallHeight, Gravity = data.Gravity, Bounce = data.Bounce, Reach = kind.Reach }
	phase = "Serve"
	board.Visible = true
	scoreLabel.Text = ("%s  <font color=\"#FFD54A\">0 - 0</font>"):format(if data.Kind == "Padel" then "🎾 Pádel" else "🎾 Tenis")
	if not ballPart then
		local part = Instance.new("Part")
		part.Name = "PelotaRaqueta"
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.one * Racket.Config.Radius * 2
		part.Color = rgb(215, 245, 60)
		part.Material = Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.Parent = workspace
		ballPart = part
		local ring = Instance.new("Part")
		ring.Name = "DondeBota"
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.05, 1.8, 1.8)
		ring.Material = Enum.Material.Neon
		ring.Color = rgb(255, 230, 80)
		ring.Anchored = true
		ring.CanCollide = false
		ring.CanQuery = false
		ring.Transparency = 1
		ring.Parent = workspace
		marker = ring
	end
	TouchLayout.setSport(true)
	TouchLayout.refresh()
end

local function step(dt: number)
	if not match or not fakeSim then
		return
	end
	local m = match
	local s = fakeSim
	if phase == "Rally" then
		Racket.stepBall(s, dt)
	end
	offset *= math.exp(-10 * dt)
	if ballPart then
		ballPart.CFrame = CFrame.new(m.CFrame:PointToWorldSpace(s.Ball.P + offset))
	end
	-- Dónde va a botar
	if marker then
		local p, v = s.Ball.P, s.Ball.V
		local landing = nil
		if phase == "Rally" and v.Y < 20 then
			local q, w = p, v
			for _ = 1, 120 do
				w = w + Vector3.new(0, -s.Gravity, 0) / 60
				q = q + w / 60
				if q.Y <= Racket.Config.Radius and w.Y < 0 then
					landing = q
					break
				end
			end
		end
		if landing then
			marker.Transparency = 0.3
			marker.CFrame = CFrame.new(m.CFrame:PointToWorldSpace(Vector3.new(landing.X, 0.08, landing.Z))) * CFrame.Angles(0, 0, math.pi / 2)
		else
			marker.Transparency = 1
		end
	end
	for id, r in m.Roster do
		if r.Human or not r.Model or not r.Model.PrimaryPart or not targets[id] then
			continue
		end
		local cur = (shown[id] or targets[id]):Lerp(targets[id], math.min(1, dt * 10))
		shown[id] = cur
		local up = (r.Model:GetAttribute("FootOffset") :: number?) or 3
		local at = m.CFrame:PointToWorldSpace(cur) + Vector3.new(0, up, 0)
		local dir = if r.Team == 1 then 1 else -1
		r.Model.PrimaryPart.CFrame = CFrame.lookAt(at, at + m.CFrame:VectorToWorldSpace(Vector3.new(dir, 0, 0)))
	end
end

local function onEvent(e: { [string]: any })
	if not match or not fakeSim then
		return
	end
	if e.Kind == "Hit" then
		phase = "Rally"
		local err = (fakeSim.Ball.P + offset) - e.P
		fakeSim.Ball.P, fakeSim.Ball.V = e.P, e.V
		offset = if err.Magnitude < 6 then err else Vector3.zero
		lastSeq = math.max(lastSeq, e.Seq or 0)
		ignoreUntil = os.clock() + 0.25
		pcall(function()
			-- (en 3D, desde la bola: el golpe del rival se oye desde su lado de la pista)
			require(script.Parent.SoundFx).play("RaquetaGolpe", { Volume = 0.7 + 0.3 * math.min(1, (e.V and e.V.Magnitude or 40) / 80), At = if typeof(e.P) == "Vector3" then e.P else nil })
		end)
		local r = match.Roster[e.Id]
		if r and r.Model and e.Id ~= match.You then
			SportAnim.play(r.Model, if e.Type == "Globo" then "Tiro" else "Pase")
		end
	elseif e.Kind == "Point" then
		phase = "Point"
		local myTeam = match.Roster[match.You] and match.Roster[match.You].Team or 1
		local mine = e.Team == myTeam
		if mine then
			pcall(function() -- (la grada aplaude tu punto)
				require(script.Parent.SoundFx).play("Punto")
			end)
		end
		local why =({ Red = "a la red", Fuera = "fuera", DosBotes = "dos botes", Pared = "a la pared", Pasada = "¡ganador!" })[e.Why] or ""
		showBanner((if mine then "¡Punto! " else "Punto para ellos · ") .. why, if mine then rgb(120, 240, 140) else rgb(255, 140, 120), 1.4)
		local a, b = e.Score[1], e.Score[2]
		if myTeam == 2 then
			a, b = b, a
		end
		scoreLabel.Text = ("%s  <font color=\"#FFD54A\">%d - %d</font>"):format(if match.Kind == "Padel" then "🎾 Pádel" else "🎾 Tenis", a, b)
	elseif e.Kind == "Serve" then
		phase = "Serve"
		server = e.Id
		if e.Id == match.You then
			showBanner("Te toca sacar", rgb(255, 255, 255), 1)
		end
	elseif e.Kind == "Net" then
		showBanner("¡Red!", rgb(255, 200, 100), 0.7)
	elseif e.Kind == "Over" then
		local myTeam = match.Roster[match.You] and match.Roster[match.You].Team or 1
		local a, b = e.Goals or 0, e.Against or 0
		if myTeam == 2 then
			a, b = b, a
		end
		showBanner(if a > b then ("¡Ganas! %d - %d"):format(a, b) else ("Pierdes %d - %d"):format(a, b), Theme.Colors.Gold, 3)
	end
end

local function onArea(): string?
	local c = player.Character
	local root = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return nil
	end
	for _, a in areas do
		local loc = a.CFrame:PointToObjectSpace(root.Position)
		if math.abs(loc.X) <= a.Length / 2 + 1 and math.abs(loc.Z) <= a.Width / 2 + 1 and math.abs(loc.Y) < 10 then
			return a.Id
		end
	end
	return nil
end

function RacketClient.init()
	build()
	remote = SportInput.remote("Raqueta") :: RemoteEvent?
	local stateRemote: any = SportInput.remote("RaquetaState")
	if not remote then
		return
	end
	remote.OnClientEvent:Connect(function(kind: string, data: any)
		local ok, err = pcall(function()
			if kind == "Session" then
				onSession(data)
			elseif kind == "Event" then
				onEvent(data)
			elseif kind == "End" then
				finish()
			elseif kind == "Areas" then
				areas = data
			elseif kind == "Error" then
				showBanner(data.Text or "", rgb(255, 200, 120), 2)
			end
		end)
		if not ok then
			warn("[Raqueta] " .. tostring(err))
		end
	end)
	if stateRemote then
		(stateRemote :: any).OnClientEvent:Connect(function(snap)
			if not match or not fakeSim or type(snap) ~= "table" then
				return
			end
			phase = snap.Ph or phase
			server = snap.Sv
			local b = snap.B
			if os.clock() >= ignoreUntil and b[3] >= lastSeq then
				local err = (fakeSim.Ball.P + offset) - b[1]
				fakeSim.Ball.P, fakeSim.Ball.V = b[1], b[2]
				offset = if err.Magnitude < 6 then err else Vector3.zero
				lastSeq = b[3]
			end
			for i, row in snap.P do
				local id = match.Order[i]
				if id and row then
					targets[id] = row
				end
			end
		end)
	end
	local function inMatch(): boolean
		return match ~= nil
	end
	TouchLayout.register({ Id = "RaqGolpe", Icon = "saltar", Label = "Golpe", SportSlot = "Ataque", Priority = 1, Key = "Clic / F", Pad = "RT", Visible = inMatch,
		Active = function(): boolean
			return match ~= nil and reachable()
		end,
		Callback = function()
			swing(false)
		end,
	})
	TouchLayout.register({ Id = "RaqGlobo", Icon = "flecha", Label = "Globo", SportSlot = "Defender", Priority = 1, Key = "R", Pad = "X", Visible = inMatch, Callback = function()
		swing(true)
	end })
	TouchLayout.register({ Id = "RaqSalir", Icon = "bajarse", Label = "Salir", SportSlot = "Esquivar", Priority = 1, Key = "Q", Pad = "B", Visible = inMatch, Callback = function()
		if remote then
			remote:FireServer("Leave")
		end
	end })
	TouchLayout.register({ Id = "RaqJugar", Icon = "objetivo", Label = "Deportes", Priority = 10,
		Visible = function(): boolean
			return match == nil and areaOn ~= nil and player:GetAttribute("InSport") == nil and player:GetAttribute("InMiniGame") == nil
		end,
		Callback = function()
			menu.Visible = not menu.Visible
		end,
	})
	ContextActionService:BindActionAtPriority("RaquetaInput", function(_, state, input)
		if not match or state ~= Enum.UserInputState.Begin or SportInput.onButton(input) then
			return Enum.ContextActionResult.Pass
		end
		if input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonX then
			swing(true)
		elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonB then
			if remote then
				remote:FireServer("Leave")
			end
		else
			swing(false)
		end
		return Enum.ContextActionResult.Sink
	end, false, 3100, Enum.KeyCode.F, Enum.KeyCode.ButtonR2, Enum.UserInputType.MouseButton1, Enum.KeyCode.R, Enum.KeyCode.ButtonX, Enum.KeyCode.Q, Enum.KeyCode.ButtonB)
	RunService.RenderStepped:Connect(function(dt)
		local ok, err = pcall(step, dt)
		if not ok then
			warn("[Raqueta] " .. tostring(err))
		end
	end)
	task.spawn(function()
		task.wait(32)
		while #areas == 0 do
			remote:FireServer("Areas")
			task.wait(20)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.5)
			local now = onArea()
			if now ~= areaOn then
				areaOn = now
				TouchLayout.refresh()
			end
		end
	end)
end

return RacketClient
