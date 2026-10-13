-- VolleyClient (cliente): el vóley playa de verdad en tu pantalla (VolleyService lleva el partido).
--
-- CONTROLES: muévete con el joystick hacia el círculo de la arena (donde va a caer el balón) y toca
-- «Golpear» cuando el balón te llegue: abajo, recibes hacia tu pareja; si te la coloca, junto a la red
-- y con el balón alto, rematas hacia donde mira la cámara. El botón se enciende cuando el balón está a
-- tu alcance; cuanto mejor la altura, mejor sale. Para sacar, «Golpear» (apunta con la cámara).
-- Ordenador: clic o F. Mando: RT.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Theme = require(script.Parent.Parent.UI.Theme)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local SportAnim = require(script.Parent.SportAnim)
local SportInput = require(script.Parent.SportInput)
local Volley = require(ReplicatedStorage.Shared.Sports.VolleySim)

local VolleyClient = {}

local player = Players.LocalPlayer
local create = Theme.create
local rgb = Color3.fromRGB

local remote: RemoteEvent? = nil
local game_: { [string]: any }? = nil
local ballPart: BasePart? = nil
local marker: BasePart? = nil
local ball = { P = Vector3.zero, V = Vector3.zero }
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
local infoLabel: TextLabel
local banner: TextLabel
local bannerToken = 0

local function showBanner(text: string, color: Color3?, seconds: number?)
	bannerToken += 1
	local token = bannerToken
	banner.Text = text
	banner.TextColor3 = color or Color3.new(1, 1, 1)
	banner.Visible = true
	task.delay(seconds or 1.3, function()
		if bannerToken == token then
			banner.Visible = false
		end
	end)
end

local function build()
	gui = create("ScreenGui", { Name = "VoleyGui", ResetOnSpawn = false, DisplayOrder = 6, Parent = player:WaitForChild("PlayerGui") })
	board = Theme.panel({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 84), Size = UDim2.fromOffset(360, 58), Visible = false, Parent = gui })
	scoreLabel = Theme.label({ Size = UDim2.new(1, 0, 0, 30), Font = Theme.FontBold, TextSize = 22, RichText = true, TextXAlignment = Enum.TextXAlignment.Center, Parent = board })
	infoLabel = Theme.label({ Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 22), TextSize = 14, TextWrapped = true, TextColor3 = Theme.Colors.Gold, TextXAlignment = Enum.TextXAlignment.Center, Parent = board })
	banner = Theme.label({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.32), Size = UDim2.fromOffset(600, 64), Font = Theme.FontBold, TextSize = 44, TextStrokeTransparency = 0.3, TextXAlignment = Enum.TextXAlignment.Center, Visible = false, Parent = gui })
end

local function feet(): Vector3?
	local c = player.Character
	local root = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
	local h = c and c:FindFirstChildOfClass("Humanoid")
	if not root or not game_ then
		return nil
	end
	local w = root.Position - Vector3.new(0, (if h then h.HipHeight + root.Size.Y / 2 else 3), 0)
	return game_.CFrame:PointToObjectSpace(w)
end

-- Un «sim» de mentira para usar las cuentas compartidas (dónde cae, si llego…)
local function fake(): { [string]: any }
	local g = game_ :: any
	return { Ball = ball, Half = g.Half, Width = g.Width, NetHeight = g.NetHeight, Scale = 1, Phase = phase, T = os.clock(), TouchTeam = 0, Touches = 0 }
end

local function reachable(): boolean
	local me = feet()
	if not me or not game_ then
		return false
	end
	if phase == "Serve" then
		return server == game_.You
	end
	local d = Vector3.new(ball.P.X - me.X, 0, ball.P.Z - me.Z).Magnitude
	return phase == "Rally" and me.X * ball.P.X > -2 and d <= 3.4 + 0.8 and ball.P.Y <= 9.5 and ball.P.Y >= 0.8
end

local function aimPoint(): Vector3
	local g = game_ :: any
	local camera = workspace.CurrentCamera
	local dir = g.CFrame:VectorToObjectSpace(camera.CFrame.LookVector)
	dir = Vector3.new(dir.X, 0, dir.Z)
	dir = if dir.Magnitude > 1e-3 then dir.Unit else Vector3.new(1, 0, 0)
	local me = feet() or Vector3.zero
	local p = me + dir * 18
	return Vector3.new(math.clamp(math.max(p.X, 3), 3, g.Half - 1.5), 0, math.clamp(p.Z, -g.Width / 2 + 1.5, g.Width / 2 - 1.5))
end

local function hit()
	if not game_ or not remote or not reachable() then
		return
	end
	local me = feet()
	local quality = nil
	if me and phase == "Rally" then
		local nearNet = math.abs(me.X) < 6
		local kind = if nearNet and ball.P.Y >= game_.NetHeight - 0.3 then "Remate" else "Recibir"
		quality = Volley.quality(fake(), { P = me }, kind)
		SportAnim.play(player.Character, if kind == "Remate" then "Bandeja" else "Estirada")
		if kind == "Remate" then
			local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if h then
				h.Jump = true
			end
		end
	else
		SportAnim.play(player.Character, "Tiro")
	end
	remote:FireServer("Hit", { Aim = aimPoint(), Quality = quality })
end

local function stepBall(dt: number)
	local g = Volley.Config.Gravity
	if phase == "Rally" then
		local before = ball.P
		ball.V = (ball.V + Vector3.new(0, -g, 0) * dt) * math.exp(-Volley.Config.Drag * dt)
		ball.P = ball.P + ball.V * dt
		if ball.P.Y < Volley.Config.Radius then
			ball.P = Vector3.new(ball.P.X, Volley.Config.Radius, ball.P.Z)
			ball.V = Vector3.zero
		end
		local _ = before
	end
	offset *= math.exp(-10 * dt)
end

local function step(dt: number)
	if not game_ then
		return
	end
	local g = game_
	stepBall(dt)
	if ballPart then
		ballPart.CFrame = CFrame.new(g.CFrame:PointToWorldSpace(ball.P + offset))
	end
	-- Dónde va a caer
	if marker then
		local _, land = Volley.landing(fake(), 0.9, 4)
		if land and phase == "Rally" then
			marker.Transparency = 0.35
			marker.CFrame = CFrame.new(g.CFrame:PointToWorldSpace(Vector3.new(land.X, 0.06, land.Z))) * CFrame.Angles(0, 0, math.pi / 2)
			marker.Color = if land.X < 0 then rgb(255, 220, 70) else rgb(255, 255, 255)
		else
			marker.Transparency = 1
		end
	end
	-- Las máquinas, suaves
	for id, r in g.Roster do
		if r.Human or not r.Model or not r.Model.PrimaryPart or not targets[id] then
			continue
		end
		local cur = shown[id] or targets[id]
		cur = cur:Lerp(targets[id], math.min(1, dt * 10))
		shown[id] = cur
		local up = (r.Model:GetAttribute("FootOffset") :: number?) or 3
		local at = g.CFrame:PointToWorldSpace(cur) + Vector3.new(0, up, 0)
		local side = if r.Team == 1 then 1 else -1
		r.Model.PrimaryPart.CFrame = CFrame.lookAt(at, at + g.CFrame:VectorToWorldSpace(Vector3.new(side, 0, 0)))
	end
end

local function finish()
	game_ = nil
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
	game_ = data
	phase = "Serve"
	board.Visible = true
	scoreLabel.Text = ("%s  <font color=\"#FFD54A\">0 - 0</font>  Rivales"):format("Tu pareja")
	infoLabel.Text = data.Hint or "Ve al círculo donde cae el balón y toca «Golpear» cuando te llegue"
	local part = Instance.new("Part")
	part.Name = "BalonVoley"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.one * Volley.Config.Radius * 2
	part.Color = rgb(250, 230, 90)
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Parent = workspace
	ballPart = part
	local ring = Instance.new("Part")
	ring.Name = "DondeCae"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.05, 2.4, 2.4)
	ring.Material = Enum.Material.Neon
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.Transparency = 1
	ring.Parent = workspace
	marker = ring
	TouchLayout.setSport(true)
	TouchLayout.refresh()
end

local function onEvent(e: { [string]: any })
	if not game_ then
		return
	end
	local g = game_
	if e.Kind == "Hit" then
		phase = "Rally"
		local err = (ball.P + offset) - e.P
		ball.P, ball.V = e.P, e.V
		offset = if err.Magnitude < 8 then err else Vector3.zero
		lastSeq = math.max(lastSeq, e.Seq or 0)
		ignoreUntil = os.clock() + 0.25
		pcall(function() -- (el golpe al balón: un remate suena más fuerte que un toque)
			require(script.Parent.SoundFx).play("VoleyGolpe", { Volume = if e.Type == "Remate" then 1 else 0.7, Pitch = if e.Type == "Remate" then 0.9 else 1, At = if typeof(e.P) == "Vector3" then e.P else nil })
		end)
		local r = g.Roster[e.Id]
		if r and r.Model and e.Id ~= g.You then
			SportAnim.play(r.Model, if e.Type == "Remate" then "Bandeja" elseif e.Type == "Saque" then "Tiro" else "Estirada")
		end
		if e.Id == g.You then
			showBanner(if e.Quality >= 0.9 then "¡Perfecto!" elseif e.Quality >= 0.6 then "Bien" else "Uy…", if e.Quality >= 0.6 then rgb(120, 240, 140) else rgb(255, 170, 110), 0.7)
		end
	elseif e.Kind == "Point" then
		phase = "Point"
		local ours = e.Team == 1
		if ours then
			pcall(function()
				require(script.Parent.SoundFx).play("Punto")
			end)
		end
		showBanner(if ours then "¡Punto!" else "Punto para ellos", if ours then rgb(120, 240, 140) else rgb(255, 140, 120), 1.4)
		scoreLabel.Text = ("Tu pareja  <font color=\"#FFD54A\">%d - %d</font>  Rivales"):format(e.Score[1], e.Score[2])
	elseif e.Kind == "Serve" then
		phase = "Serve"
		server = e.Id
		if e.Id == g.You then
			infoLabel.Text = "Te toca sacar: apunta con la cámara y toca «Golpear»"
		end
	elseif e.Kind == "Net" then
		showBanner("¡Red!", rgb(255, 200, 100), 0.8)
	elseif e.Kind == "Over" then
		local won = (e.Goals or 0) > (e.Against or 0)
		showBanner(if won then ("¡Ganáis! %d - %d"):format(e.Goals, e.Against) else ("Perdéis %d - %d"):format(e.Goals or 0, e.Against or 0), Theme.Colors.Gold, 3)
	end
end

function VolleyClient.init()
	build()
	remote = SportInput.remote("Voley") :: RemoteEvent?
	local stateRemote: any = SportInput.remote("VoleyState")
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
			end
		end)
		if not ok then
			warn("[Vóley] " .. tostring(err))
		end
	end)
	if stateRemote then
		(stateRemote :: any).OnClientEvent:Connect(function(snap)
			if not game_ or type(snap) ~= "table" then
				return
			end
			phase = snap.Ph or phase
			server = snap.Sv
			local b = snap.B
			if os.clock() >= ignoreUntil and b[3] >= lastSeq then
				local err = (ball.P + offset) - b[1]
				ball.P, ball.V = b[1], b[2]
				offset = if err.Magnitude < 8 then err else Vector3.zero
				lastSeq = b[3]
			end
			for i, row in snap.P do
				local id = game_.Order[i]
				if id then
					targets[id] = row[1]
				end
			end
		end)
	end
	TouchLayout.register({ Id = "VolGolpear", Icon = "saltar", Label = "Golpear", SportSlot = "Ataque", Priority = 1, Key = "Clic / F", Pad = "RT",
		Visible = function(): boolean
			return game_ ~= nil
		end,
		Active = function(): boolean
			return game_ ~= nil and reachable()
		end,
		Callback = hit,
	})
	ContextActionService:BindActionAtPriority("VoleyInput", function(_, state, input)
		if not game_ or state ~= Enum.UserInputState.Begin or SportInput.onButton(input) then
			return Enum.ContextActionResult.Pass
		end
		hit()
		return Enum.ContextActionResult.Sink
	end, false, 3100, Enum.KeyCode.F, Enum.KeyCode.ButtonR2, Enum.UserInputType.MouseButton1)
	RunService.RenderStepped:Connect(function(dt)
		local ok, err = pcall(step, dt)
		if not ok then
			warn("[Vóley] " .. tostring(err))
		end
	end)
end

return VolleyClient
