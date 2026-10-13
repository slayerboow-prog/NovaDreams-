-- BasketClient (cliente): el baloncesto de verdad en tu pantalla (BasketService lleva el partido).
--
-- CONTROLES (móvil; los botones del deporte salen en el racimo en lugar de los de pelear)
--   Joystick   moverte botando (el balón se coge solo al pasar cerca)
--   Tirar      mantener = saltas y se llena el medidor; suelta en la franja verde (lanzamiento perfecto).
--              Antes o después, el tiro sale corto/largo o torcido. Cerca del aro, bandeja (más fácil).
--              Con un rival encima se falla más.
--   Pasar      al compañero que tengas delante (el de la cámara)
--   Robar      quitarle el balón al que bota, o saltar a taponar un tiro
--   Correr     el sprint de siempre
--   Ordenador: clic o F = tirar (mantener), R = pasar, Q = robar, Mayús = correr. Mando: RT, X, B, L3.
--
-- El balón: como en el fútbol (FootballClient), cada cliente repite la física (Sports/Hoops) desde
-- las fotos del servidor y corrige poco a poco. Tu tiro sale de una semilla que también usa el
-- servidor: lo que ves es lo que pasa.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.UI.Theme)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local SportAnim = require(script.Parent.SportAnim)
local SportInput = require(script.Parent.SportInput)
local Court = require(ReplicatedStorage.Shared.Sports.Court)
local Hoops = require(ReplicatedStorage.Shared.Sports.Hoops)
local BasketSim = require(ReplicatedStorage.Shared.Sports.BasketSim)

local BasketClient = {}

local player = Players.LocalPlayer
local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

local remote: RemoteEvent? = nil
local BUFFER = 0.11
local METER_TIME = 0.85 -- del vacío al lleno
local PERFECT_LO, PERFECT_HI = 0.68, 0.84 -- la franja verde del medidor

type View = { [string]: any }

local views: { [string]: View } = {}
local mine: View? = nil
local fields: { { [string]: any } } = {}
local fieldOn: string? = nil

local charging = false
local chargeStart = 0
local lastActionAt = 0

local gui: ScreenGui
local board: Frame
local scoreLabel: TextLabel
local infoLabel: TextLabel
local banner: TextLabel
local hintCard: Frame
local hintLabel: TextLabel
local menu: Frame
local meter: Frame
local meterFill: Frame
local bannerToken = 0

local function myId(): string
	return "u" .. player.UserId
end

local function character(): (Model?, BasePart?, Humanoid?)
	local c = player.Character
	local root = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = c and c:FindFirstChildOfClass("Humanoid")
	return c, root, humanoid
end

local function feetOf(model: Model?): Vector3?
	if not model then
		return nil
	end
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not root then
		return nil
	end
	local h = if humanoid then humanoid.HipHeight + root.Size.Y / 2 else 3
	return root.Position - Vector3.new(0, h, 0)
end

local function courtFrom(d: { [string]: any }): Court.Court
	local hoops = {}
	for key, h in d.Hoops or {} do
		local side = tonumber(key) or 1
		hoops[side] = { Side = side, Rim = h.Rim, Radius = h.Radius, Board = h.Board, BoardHalf = h.BoardHalf, Normal = h.Normal }
	end
	return Court.new(d.CFrame, d.Length, d.Width, hoops, { Id = d.Id, BoardMargin = d.BoardMargin })
end

local function myTeam(view: View): number
	local you = view.Info.You
	local entry = you and view.Info.Roster and view.Info.Roster[you]
	return if entry then entry.Team else 1
end

local function showBanner(text: string, color: Color3?, seconds: number?)
	bannerToken += 1
	local token = bannerToken
	banner.Text = text
	banner.TextColor3 = color or Color3.new(1, 1, 1)
	banner.Visible = true
	Theme.pop(banner, 0.12)
	task.delay(seconds or 1.5, function()
		if bannerToken == token then
			banner.Visible = false
		end
	end)
end

local function sound(name: string, pitch: number?, volume: number?)
	pcall(function()
		require(script.Parent.SoundFx).play(name, volume, pitch)
	end)
end

local function SoundFx()
	return require(script.Parent.SoundFx)
end

---------------------------------------------------------------------
-- Interfaz
---------------------------------------------------------------------

local function build()
	gui = create("ScreenGui", { Name = "BaloncestoGui", ResetOnSpawn = false, DisplayOrder = 6, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui") })
	board = Theme.panel({ Name = "Marcador", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 84), Size = UDim2.fromOffset(360, 58), Visible = false, Parent = gui })
	scoreLabel = Theme.label({ Size = UDim2.new(1, 0, 0, 30), Font = Theme.FontBold, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center, RichText = true, Parent = board })
	infoLabel = Theme.label({ Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 22), TextSize = 15, TextColor3 = C.Gold, TextXAlignment = Enum.TextXAlignment.Center, Parent = board })
	banner = Theme.label({ Name = "Banner", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.32), Size = UDim2.fromOffset(600, 64), Font = Theme.FontBold, TextSize = 44, TextStrokeTransparency = 0.3, TextXAlignment = Enum.TextXAlignment.Center, Visible = false, Parent = gui })
	hintCard = Theme.panel({ Name = "Pista", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 148), Size = UDim2.fromOffset(420, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, Parent = gui })
	Theme.padding(8).Parent = hintCard
	hintLabel = Theme.label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 15, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, Parent = hintCard })
	Theme.touchText(hintLabel, 16)
	-- El medidor del tiro: a la derecha del personaje, se llena de abajo arriba; la franja verde es la buena
	meter = create("Frame", { Name = "Medidor", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.58, 0.5), Size = UDim2.fromOffset(22, 150), BackgroundColor3 = rgb(15, 20, 32), BackgroundTransparency = 0.2, BorderSizePixel = 0, Visible = false, Parent = gui }, { Theme.corner(8) })
	create("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1 - PERFECT_LO), Size = UDim2.fromScale(1, PERFECT_HI - PERFECT_LO), BackgroundColor3 = rgb(70, 220, 110), BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 2, Parent = meter })
	meterFill = create("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0), BackgroundColor3 = rgb(255, 255, 255), BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 3, Parent = meter }, { Theme.corner(8) })
	menu = Theme.panel({ Name = "ModoBaloncesto", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(300, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, Parent = gui })
	Theme.padding(12).Parent = menu
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = menu })
	Theme.title({ Size = UDim2.new(1, 0, 0, 26), Text = "🏀 ¿A qué jugamos?", LayoutOrder = 0, Parent = menu })
	local options = {
		{ "Uno contra uno", { Mode = "Partido", Size = 1 } },
		{ "Tres contra tres", { Mode = "Partido", Size = 3 } },
		{ "Tanda de tiros", { Mode = "Tiros" } },
		{ "Tirar libre", { Mode = "Libre" } },
		{ "Dejar de jugar", { Leave = true } },
		{ "Cerrar", { Close = true } },
	}
	for i, option in options do
		local button = Theme.button({ Size = UDim2.new(1, 0, 0, 42), Text = option[1], TextSize = 17, LayoutOrder = i, Parent = menu })
		button.Activated:Connect(function()
			menu.Visible = false
			local o = option[2]
			if o.Close or not remote then
				return
			elseif o.Leave then
				remote:FireServer("Leave")
			else
				remote:FireServer("Mode", o)
			end
		end)
	end
	Theme.popupScale(gui, { { Frame = menu, Margin = 40 } })
end

local function updateBoard(view: View?)
	if not view or not view.Last then
		board.Visible = false
		return
	end
	local g = view.Last.G
	local info = view.Info
	board.Visible = true
	if info.Mode == "Partido" then
		local you = myTeam(view)
		local a, b = g[1], g[2]
		if you == 2 then
			a, b = b, a
		end
		local rival = (info.Story and info.Story.Rival) or "Rival"
		scoreLabel.Text = ("%s  <font color=\"#FFD54A\">%d - %d</font>  %s"):format(if info.You then "Tu equipo" else "Azules", a, b, if info.You then rival else "Rojos")
		local remaining = math.max(0, (info.Duration or 0) - g[3])
		infoLabel.Text = ("⏱ %d:%02d"):format(math.floor(remaining / 60), math.floor(remaining % 60))
	elseif info.Mode == "Tiros" then
		scoreLabel.Text = ("🏀 Canastas: <font color=\"#FFD54A\">%d</font> de %d"):format(g[6], g[7])
		infoLabel.Text = if (info.Need or 0) > 0 then ("Tiro %d de %d · necesitas %d"):format(math.min(g[4], g[5]), g[5], info.Need) else ("Tiro %d de %d"):format(math.min(g[4], g[5]), g[5])
	else
		scoreLabel.Text = ("🏀 Tiro libre  <font color=\"#FFD54A\">%d</font>"):format(g[1] + g[2])
		infoLabel.Text = if Theme.isTouch() then "Toca «Modo» para un partido o una tanda" else "Pulsa M para un partido o una tanda"
	end
end

---------------------------------------------------------------------
-- Balón y jugadores en pantalla
---------------------------------------------------------------------

local function makeBall(view: View)
	local part = Instance.new("Part")
	part.Name = "BalonBaloncesto"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.one * Hoops.Config.Radius * 2
	part.Color = rgb(225, 105, 35)
	part.Material = Enum.Material.Fabric
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Parent = workspace
	view.Part = part
end

local function dropView(id: string)
	local view = views[id]
	if not view then
		return
	end
	views[id] = nil
	if view.Part then
		view.Part:Destroy()
	end
	if mine == view then
		mine = nil
		TouchLayout.setSport(false)
		hintCard.Visible = false
		menu.Visible = false
		meter.Visible = false
		charging = false
		board.Visible = false
	end
end

local function modelOf(view: View, id: string): Model?
	local entry = view.Info.Roster and view.Info.Roster[id]
	local model = entry and entry.Model
	if typeof(model) == "Instance" and model:IsA("Model") and model.Parent then
		return model
	end
	if entry and entry.UserId then
		local p = Players:GetPlayerByUserId(entry.UserId)
		return p and p.Character
	end
	return nil
end

local function playerLocal(view: View, id: string): (Vector3?, Vector3?)
	local entry = view.Info.Roster and view.Info.Roster[id]
	if id == myId() or (entry and entry.Human) then
		local model = if id == myId() then player.Character else modelOf(view, id)
		local feet = feetOf(model)
		local root = model and model:FindFirstChild("HumanoidRootPart") :: BasePart?
		if feet and root then
			return Court.toLocal(view.Court, feet), Court.dirToLocal(view.Court, root.CFrame.LookVector)
		end
		return nil, nil
	end
	local list = view.Players[id]
	local last = list and list[#list]
	if last then
		return last.Shown or last.P, last.ShownFacing or last.Facing
	end
	return nil, nil
end

local function renderBall(view: View, dt: number)
	local owner = if view.PredictOwn then myId() else view.Owner
	local s = view.Ball
	if owner then
		local p, facing = playerLocal(view, owner)
		if p and facing then
			view.Phase = (view.Phase or 0) + dt * 7
			s.P = Hoops.dribblePosition(p, facing, view.Phase, view.Scale or 1)
			s.V = Vector3.zero
		end
	else
		local evs = Hoops.step(s, dt, view.Court)
		for _, e in evs do
			-- (más fuerte cuanto más rápido; sin su audio subido, los de Roblox de siempre)
			if e.Kind == "Bounce" and (e.Speed or 0) > 6 then
				if SoundFx().id("BalonBote") then
					sound("BalonBote", 1, math.clamp((e.Speed or 0) / 30, 0.35, 1))
				else
					sound("FutbolChute", 1.6, 0.25)
				end
			elseif e.Kind == "Rim" and (e.Speed or 0) > 4 then
				if SoundFx().id("AroRebote") then
					sound("AroRebote", 1, math.clamp((e.Speed or 0) / 25, 0.4, 1))
				else
					sound("FutbolPoste", 1.4, 0.4)
				end
			end
		end
	end
	view.Offset = view.Offset * math.exp(-11 * dt)
	if view.Part then
		view.Part.CFrame = CFrame.new(Court.toWorld(view.Court, s.P + view.Offset))
	end
end

local function renderBots(view: View)
	local now = os.clock() - BUFFER
	for id, list in view.Players do
		local entry = view.Info.Roster and view.Info.Roster[id]
		if not entry or entry.Human then
			continue
		end
		local model = modelOf(view, id)
		local root = model and model.PrimaryPart
		if not model or not root then
			continue
		end
		local a, b = list[1], list[#list]
		for i = #list, 1, -1 do
			if list[i].t <= now then
				a = list[i]
				b = list[i + 1] or list[i]
				break
			end
		end
		local f = if b.t > a.t then math.clamp((now - a.t) / (b.t - a.t), 0, 1) else 1
		local p = a.P:Lerp(b.P, f)
		local facing = a.Facing:Lerp(b.Facing, f)
		if facing.Magnitude < 1e-3 then
			facing = Vector3.new(1, 0, 0)
		end
		b.Shown = p
		b.ShownFacing = facing
		local up = (model:GetAttribute("FootOffset") :: number?) or 3
		local feet = Court.toWorld(view.Court, Vector3.new(p.X, 0, p.Z))
		local look = Court.dirToWorld(view.Court, facing.Unit)
		-- Saltando (tiro o tapón): sube y baja
		local jump = if b.Jump then 1 else 0
		view.JumpT = view.JumpT or {}
		local jt = view.JumpT[id] or 0
		jt = if jump > 0 then math.min(1, jt + 0.12) else math.max(0, jt - 0.12)
		view.JumpT[id] = jt
		local at = feet + Vector3.new(0, up + math.sin(jt * math.pi * 0.5) * 2.2 * (model:GetScale()), 0)
		root.CFrame = CFrame.lookAt(at, at + Vector3.new(look.X, 0, look.Z))
	end
end

---------------------------------------------------------------------
-- Fotos y sucesos
---------------------------------------------------------------------

local function latency(): number
	local ok, ping = pcall(function()
		return player:GetNetworkPing()
	end)
	return if ok and type(ping) == "number" then math.clamp(ping, 0, 0.3) else 0.08
end

local function adoptBall(view: View, p: Vector3, v: Vector3, ahead: number)
	local target = Hoops.new(p)
	target.V = v
	if ahead > 0 and v.Magnitude > 0.1 then
		Hoops.step(target, ahead, view.Court)
	end
	local err = (view.Ball.P + view.Offset) - target.P
	view.Ball = target
	view.Offset = if err.Magnitude > 9 then Vector3.zero else err
end

local function onSnapshot(snap: { [string]: any })
	if type(snap) ~= "table" then
		return
	end
	local view = views[snap.S]
	if not view then
		return
	end
	local now = os.clock()
	view.Last = snap
	local order = view.Info.Order or {}
	local b = snap.B
	local owner = if b[3] and b[3] > 0 then order[b[3]] else nil
	local seq = b[4]
	local waiting = now < view.Ignore and seq <= view.IgnoreSeq
	if not waiting then
		view.Ignore = 0
		if view.PredictOwn and owner ~= myId() and now - view.PredictOwn > 0.4 then
			view.PredictOwn = nil
		end
		if owner == myId() then
			view.PredictOwn = nil
		end
		if owner then
			view.Owner = owner
		else
			view.Owner = nil
			if not view.PredictOwn then
				adoptBall(view, b[1], b[2], latency())
			end
		end
		view.Seq = seq
	end
	if snap.V == view.Info.Version then
		for i, row in snap.P do
			local id = order[i]
			if not id or not row then
				continue
			end
			local list = view.Players[id]
			if not list then
				list = {}
				view.Players[id] = list
			end
			table.insert(list, { t = now, P = row[1], Facing = Vector3.new(math.cos(row[2]), 0, math.sin(row[2])), Jump = row[3] })
			while #list > 6 do
				table.remove(list, 1)
			end
		end
	end
	if view == mine then
		updateBoard(view)
	end
end

local function onEvent(kind: string, e: { [string]: any })
	local view = views[e.S]
	if not view then
		return
	end
	local isMine = view == mine
	local me = myId()
	if kind == "Shot" or kind == "Pass" then
		if e.Id ~= me then
			SportAnim.play(modelOf(view, e.Id), if kind == "Shot" then (if e.Layup then "Bandeja" else "Tiro") else "Pase")
			view.Owner = nil
			view.PredictOwn = nil
			adoptBall(view, e.P, e.V, latency())
		else
			view.Ignore = 0
		end
		view.Seq = math.max(view.Seq, e.Seq or 0)
	elseif kind == "Basket" then
		local scorer = e.Scorer and view.Info.Roster and view.Info.Roster[e.Scorer]
		local ours = isMine and myTeam(view) == e.Team
		local text = if e.Scorer == me then ("¡CANASTA! +%d"):format(e.Points or 2) elseif scorer then ("Canasta de %s (+%d)"):format(scorer.Name, e.Points or 2) else "¡Canasta!"
		showBanner(text, if ours or not isMine then rgb(120, 240, 140) else rgb(255, 140, 120), 1.6)
		sound("Canasta", 1, if e.Points == 3 then 1 else 0.8) -- «swish» de la red y la grada
		if e.Scorer == me or e.Points == 3 then
			pcall(function()
				require(script.Parent.StoryAudio).sting("Momento")
			end)
		end
		local model = e.Scorer and modelOf(view, e.Scorer)
		if model then
			SportAnim.play(model, "Celebrar")
		end
	elseif kind == "Block" then
		SportAnim.play(modelOf(view, e.Id), "Estirada")
		if isMine then
			showBanner(if e.Id == me then "¡TAPÓN!" elseif e.Victim == me then "Te han taponado" else "¡Tapón!", rgb(255, 220, 90), 1.2)
		end
	elseif kind == "Steal" then
		if isMine and e.Ok then
			showBanner(if e.Id == me then "¡Robado!" elseif e.Victim == me then "Te han robado" else "¡Robo!", rgb(255, 220, 90), 1)
		end
	elseif kind == "Out" then
		if isMine then
			showBanner("Fuera", rgb(230, 230, 230), 0.9)
		end
	elseif kind == "ShotSetup" then
		if isMine then
			hintLabel.Text = if view.Info.Story and view.Info.Story.Hint then view.Info.Story.Hint else "Mantén «Tirar» y suelta en la franja verde del medidor"
			hintCard.Visible = true
		end
	elseif kind == "ShotResult" then
		if isMine then
			showBanner(if e.Ok then "¡Dentro!" elseif e.Reason == "Timeout" then "Se acabó el tiempo" elseif e.Reason == "Rim" then "¡Uy, el aro!" else "Fuera…", if e.Ok then rgb(120, 240, 140) else rgb(255, 160, 120), 1.4)
		end
	elseif kind == "Over" then
		if isMine then
			local text = "¡Final!"
			if view.Info.Mode == "Partido" then
				local a, b = e.Goals or 0, e.Against or 0
				if myTeam(view) == 2 then
					a, b = b, a
				end
				text = if a > b then ("¡Victoria! %d - %d"):format(a, b) elseif a == b then ("Empate %d - %d"):format(a, b) else ("Derrota %d - %d"):format(a, b)
			elseif view.Info.Mode == "Tiros" then
				text = ("%d de %d canastas"):format(e.Hits or 0, e.Taken or 0)
			end
			showBanner(text, C.Gold, 3)
			hintCard.Visible = false
			sound("FutbolSilbato", 0.9, 0.6)
		end
	end
end

local function onSession(info: { [string]: any })
	local view = views[info.S]
	if not view then
		view = { S = info.S, Info = info, Court = courtFrom(info.Field), Ball = Hoops.new(), Offset = Vector3.zero, Players = {}, Seq = 0, Ignore = 0, IgnoreSeq = 0, NoCarryUntil = 0 }
		views[info.S] = view
		makeBall(view)
	end
	view.Info = info
	for id in view.Players do
		if not (info.Roster and info.Roster[id]) then
			view.Players[id] = nil
		end
	end
	if info.You then
		if mine and mine ~= view then
			dropView(mine.S)
		end
		mine = view
		local c = player.Character
		view.Scale = if c then c:GetScale() else 1
		TouchLayout.setSport(true)
		if info.Story and info.Story.Mine then
			hintLabel.Text = ("%s %s\n%s"):format(info.Story.Icon or "🏀", info.Story.Title or "", info.Story.Hint or "")
			hintCard.Visible = true
		else
			hintCard.Visible = false
		end
	elseif mine == view then
		mine = nil
		TouchLayout.setSport(false)
	end
	updateBoard(mine)
	TouchLayout.refresh()
end

---------------------------------------------------------------------
-- Tirar, pasar, robar
---------------------------------------------------------------------

local function owning(view: View): boolean
	return view.Owner == myId() or view.PredictOwn ~= nil
end

local function fill(): number
	if not charging then
		return 0
	end
	return math.clamp((os.clock() - chargeStart) / METER_TIME, 0, 1)
end

-- La calidad del lanzamiento según dónde soltaste (1 en la franja verde)
local function qualityOf(f: number): number
	if f >= PERFECT_LO and f <= PERFECT_HI then
		return 1
	end
	local miss = if f < PERFECT_LO then PERFECT_LO - f else f - PERFECT_HI
	return math.clamp(1 - miss * 2.6, 0, 1)
end

local function startShot()
	local view = mine
	if not view or charging or not owning(view) then
		return
	end
	charging = true
	chargeStart = os.clock()
	meter.Visible = true
	local c, _, humanoid = character()
	SportAnim.play(c, "Tiro")
	if humanoid then
		humanoid.Jump = true
	end
end

local function releaseShot()
	if not charging then
		return
	end
	local f = fill()
	charging = false
	task.delay(0.4, function()
		if not charging then
			meter.Visible = false
		end
	end)
	local view = mine
	if not view or not remote or not owning(view) then
		return
	end
	local quality = qualityOf(f)
	meterFill.BackgroundColor3 = if quality >= 0.99 then rgb(90, 255, 130) elseif quality > 0.6 then rgb(255, 210, 70) else rgb(255, 90, 80)
	local seed = math.random(1, 1e6)
	-- En tu pantalla, ya: el mismo tiro que va a calcular el servidor
	local c, root = character()
	local feet = feetOf(c)
	local at, facing = nil, nil
	if feet and root then
		at = Court.toLocal(view.Court, feet)
		facing = Court.dirToLocal(view.Court, root.CFrame.LookVector)
		local me = {
			P = Court.toLocal(view.Court, feet),
			Facing = Court.dirToLocal(view.Court, root.CFrame.LookVector),
			Team = myTeam(view),
			Scale = view.Scale or 1,
		}
		local fake = { Court = view.Court, Mode = view.Info.Mode, Order = {}, Players = {} }
		local ok, from, v = pcall(BasketSim.shotFor, fake, me, quality, seed, 0)
		if ok and from and v then
			view.Ball = Hoops.new(from)
			view.Ball.V = v
			view.Offset = Vector3.zero
		end
	end
	view.Owner = nil
	view.PredictOwn = nil
	view.NoCarryUntil = os.clock() + 0.5
	view.Ignore = os.clock() + 0.7
	view.IgnoreSeq = view.Seq
	lastActionAt = os.clock()
	remote:FireServer("Shot", { Quality = quality, Seed = seed, At = at, Facing = facing })
end

local function pass()
	local view = mine
	if not view or not remote or not owning(view) or os.clock() - lastActionAt < 0.3 then
		return
	end
	lastActionAt = os.clock()
	local camera = workspace.CurrentCamera
	local aim = Court.dirToLocal(view.Court, camera.CFrame.LookVector)
	aim = Vector3.new(aim.X, 0, aim.Z)
	aim = if aim.Magnitude > 1e-3 then aim.Unit else Vector3.new(1, 0, 0)
	local myLoc = playerLocal(view, myId())
	local best, bestScore = nil, -math.huge
	if myLoc then
		for id, entry in view.Info.Roster or {} do
			if id ~= myId() and entry.Team == myTeam(view) then
				local p = playerLocal(view, id)
				if p then
					local to = Vector3.new(p.X - myLoc.X, 0, p.Z - myLoc.Z)
					if to.Magnitude > 2 then
						local score = aim:Dot(to.Unit) * 20 - to.Magnitude * 0.2
						if score > bestScore then
							best, bestScore = id, score
						end
					end
				end
			end
		end
	end
	SportAnim.play(player.Character, "Pase")
	view.NoCarryUntil = os.clock() + 0.5
	remote:FireServer("Pass", { To = best, Dir = aim })
end

local function steal()
	local view = mine
	if not view or not remote or os.clock() - lastActionAt < 0.3 then
		return
	end
	lastActionAt = os.clock()
	local c, _, humanoid = character()
	if humanoid then
		humanoid.Jump = true
	end
	SportAnim.play(c, "Estirada")
	remote:FireServer("Steal", {})
end

---------------------------------------------------------------------
-- Cada frame
---------------------------------------------------------------------

local function predictCarry(view: View)
	if view ~= mine or view.Owner or view.PredictOwn or os.clock() < view.NoCarryUntil or view.Info.Mode == "Tiros" then
		return
	end
	local c = player.Character
	local feet = feetOf(c)
	if not feet then
		return
	end
	local loc = Court.toLocal(view.Court, feet)
	local s = view.Scale or 1
	local b = view.Ball.P
	local d = Vector3.new(b.X - loc.X, 0, b.Z - loc.Z).Magnitude
	if d < (BasketSim.Config.ControlRadius + Hoops.Config.Radius) * s + 0.4 and b.Y < 5.5 * s and view.Ball.V.Magnitude < 40 then
		view.PredictOwn = os.clock()
	end
end

local function onCourtNow(): string?
	local _, root = character()
	if not root then
		return nil
	end
	for _, d in fields do
		local c = d._court
		if not c then
			c = courtFrom(d)
			d._court = c
		end
		local loc = Court.toLocal(c, root.Position)
		if math.abs(loc.X) < c.Length / 2 + 1 and math.abs(loc.Z) < c.Width / 2 + 1 and math.abs(loc.Y) < 10 then
			return d.Id
		end
	end
	return nil
end

local function step(dt: number)
	for _, view in views do
		predictCarry(view)
		renderBall(view, dt)
		renderBots(view)
	end
	if charging then
		local f = fill()
		meterFill.Size = UDim2.fromScale(1, f)
		meterFill.BackgroundColor3 = if f >= PERFECT_LO and f <= PERFECT_HI then rgb(90, 255, 130) else rgb(255, 255, 255)
		if f >= 1 then
			releaseShot() -- (lleno del todo: sale solo, y tarde)
		end
	end
end

---------------------------------------------------------------------
-- Botones y teclas
---------------------------------------------------------------------

local function inSport(): boolean
	return mine ~= nil
end

local function registerButtons()
	TouchLayout.register({
		Id = "BasTirar", Icon = "canasta", Label = "Tirar", SportSlot = "Ataque", Priority = 1, Key = "Clic / F", Pad = "RT",
		Visible = inSport,
		Hold = function(down: boolean)
			if down then
				startShot()
			else
				releaseShot()
			end
		end,
		Meter = function(): number?
			return if charging then fill() else nil
		end,
		Active = function(): boolean
			return charging
		end,
	})
	TouchLayout.register({ Id = "BasPasar", Icon = "pase", Label = "Pasar", SportSlot = "Defender", Priority = 1, Key = "R", Pad = "X", Visible = inSport, Callback = pass })
	TouchLayout.register({ Id = "BasRobar", Icon = "robar", Label = "Robar", SportSlot = "Esquivar", Priority = 1, Key = "Q", Pad = "B", Visible = inSport, Callback = steal })
	TouchLayout.register({
		Id = "BasModo", Icon = "menu", Label = "Modo", SportSlot = "Interactuar", Priority = 2, Key = "M", Pad = "Y",
		Visible = function(): boolean
			return mine ~= nil and not (mine.Info.Story and mine.Info.Story.Mine)
		end,
		Callback = function()
			menu.Visible = not menu.Visible
		end,
	})
	TouchLayout.register({
		Id = "BasJugar", Icon = "canasta", Label = "Baloncesto", Priority = 9, Key = "J",
		Visible = function(): boolean
			return mine == nil and fieldOn ~= nil and player:GetAttribute("InSport") == nil and player:GetAttribute("InMiniGame") == nil
		end,
		Callback = function()
			if remote and fieldOn then
				remote:FireServer("Join", { F = fieldOn })
			end
		end,
	})
end

local function bindKeys()
	ContextActionService:BindActionAtPriority("BaloncestoInput", function(_, state, input)
		if not mine then
			return Enum.ContextActionResult.Pass
		end
		local key = input.KeyCode
		if key == Enum.KeyCode.F or key == Enum.KeyCode.ButtonR2 or input.UserInputType == Enum.UserInputType.MouseButton1 then
			if UserInputService:GetFocusedTextBox() or (state == Enum.UserInputState.Begin and SportInput.onButton(input)) then
				return Enum.ContextActionResult.Pass
			end
			if state == Enum.UserInputState.Begin then
				startShot()
			elseif state == Enum.UserInputState.End then
				releaseShot()
			end
			return Enum.ContextActionResult.Sink
		elseif state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		elseif key == Enum.KeyCode.R or key == Enum.KeyCode.ButtonX then
			pass()
		elseif key == Enum.KeyCode.Q or key == Enum.KeyCode.ButtonB then
			steal()
		elseif key == Enum.KeyCode.M or key == Enum.KeyCode.ButtonY then
			if not (mine.Info.Story and mine.Info.Story.Mine) then
				menu.Visible = not menu.Visible
			end
		else
			return Enum.ContextActionResult.Pass
		end
		return Enum.ContextActionResult.Sink
	end, false, 3100, Enum.KeyCode.F, Enum.KeyCode.ButtonR2, Enum.UserInputType.MouseButton1, Enum.KeyCode.R, Enum.KeyCode.ButtonX, Enum.KeyCode.Q, Enum.KeyCode.ButtonB, Enum.KeyCode.M, Enum.KeyCode.ButtonY)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or mine or not fieldOn or not remote or player:GetAttribute("InSport") then
			return
		end
		if input.KeyCode == Enum.KeyCode.J then
			remote:FireServer("Join", { F = fieldOn })
		end
	end)
end

function BasketClient.init()
	build()
	SportAnim.register()
	remote = SportInput.remote("Basket") :: RemoteEvent?
	local stateRemote: any = SportInput.remote("BasketState")
	if not remote then
		return
	end
	remote.OnClientEvent:Connect(function(kind: string, data: any)
		local ok, err = pcall(function()
			if kind == "Session" then
				onSession(data)
			elseif kind == "End" then
				dropView(data.S)
			elseif kind == "Left" then
				if mine and mine.S == data.S then
					local view = mine
					mine = nil
					TouchLayout.setSport(false)
					hintCard.Visible = false
					menu.Visible = false
					meter.Visible = false
					board.Visible = false
					view.Info.You = nil
				end
			elseif kind == "Event" then
				onEvent(data.Kind, data)
			elseif kind == "ShotRejected" then
				local view = views[data.S]
				if view then
					view.Ignore = 0
				end
			elseif kind == "Fields" then
				fields = data
			end
		end)
		if not ok then
			warn("[Baloncesto] " .. tostring(err))
		end
	end)
	if stateRemote then
		(stateRemote :: any).OnClientEvent:Connect(function(snap)
			local ok, err = pcall(onSnapshot, snap)
			if not ok then
				warn("[Baloncesto] " .. tostring(err))
			end
		end)
	end
	registerButtons()
	bindKeys()
	SportInput.watchPrompts() -- (los carteles «Jugar» de las pistas se apagan mientras juegas)
	RunService.RenderStepped:Connect(function(dt)
		local ok, err = pcall(step, dt)
		if not ok then
			warn("[Baloncesto] " .. tostring(err))
		end
	end)
	task.spawn(function()
		-- (en cuanto hay remoto; el servidor además las manda a todos cuando acaba de buscarlas)
		task.wait(3)
		while #fields == 0 do
			remote:FireServer("Fields")
			task.wait(10)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.5)
			local now = onCourtNow()
			if now ~= fieldOn then
				fieldOn = now
				TouchLayout.refresh()
			end
		end
	end)
	player.CharacterAdded:Connect(function()
		charging = false
	end)
end

return BasketClient
