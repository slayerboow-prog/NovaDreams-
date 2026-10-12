-- FootballClient (cliente): el fútbol de verdad en tu pantalla (FootballService lleva el partido).
--
-- CONTROLES (móvil; los botones salen en el racimo de siempre en lugar de los de pelear)
--   Joystick     correr con el balón pegado al pie (se conduce solo al pasar cerca de él)
--   Chutar       mantener = cargar la fuerza (la barrita del botón); soltar = chutar hacia donde
--                miras con la cámara. Cerca de la portería apunta solo a la portería y el joystick
--                mueve la mira de poste a poste (la diana sale en la portería). Pasarse de fuerza manda
--                el balón por encima del larguero. Correr de lado al soltar = tiro con efecto.
--   Pasar        pase raso al compañero que tengas delante (o al frente, si no hay nadie); de lejos, por alto
--   Entrar       entrada en plancha para robar el balón (de portero: estirada)
--   Correr       el sprint de siempre (con la estamina)
--   Ordenador: clic o F = chutar (mantener), R = pasar, Q = entrar, Mayús = correr. Mando: RT, X, B, L3.
--
-- EL BALÓN: cada cliente repite la física (Sports/Ball) desde las fotos del servidor y corrige poco a
-- poco el error (nunca da saltos). Tu golpeo sale al instante en tu pantalla y el servidor lo
-- confirma; si lo rechaza (estabas lejos), el balón vuelve a donde dice el servidor. Las máquinas se
-- dibujan entre dos fotos (100 ms por detrás), así que se mueven fluidas aunque lleguen 15 por segundo.
-- LA CÁMARA: se va girando sola hacia la portería rival cuando llevas el balón o cargas un tiro (si
-- la mueves tú con el dedo o el ratón, te deja un rato).

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.UI.Theme)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local SportAnim = require(script.Parent.SportAnim)
local SportInput = require(script.Parent.SportInput)
local Pitch = require(ReplicatedStorage.Shared.Sports.Pitch)
local Ball = require(ReplicatedStorage.Shared.Sports.Ball)

local FootballClient = {}

local player = Players.LocalPlayer
local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

local remote: RemoteEvent? = nil
local BUFFER = 0.11 -- las máquinas se dibujan este tiempo por detrás (entre dos fotos)
local CHARGE_TIME = 1.05 -- de nada a fuerza máxima
local TEAM_NAMES = { [1] = "Tu equipo", [2] = "Rival" }

type View = {
	S: string,
	Info: { [string]: any },
	Pitch: Pitch.Pitch,
	Ball: Ball.State,
	Offset: Vector3, -- error visual que se va corrigiendo
	Part: BasePart?,
	Shadow: BasePart?,
	Owner: string?,
	Seq: number,
	Players: { [string]: { any } }, -- id -> lista de fotos { t, P, Facing, DiveVec, Dive, Slide }
	Last: { [string]: any }?,
	Spin: CFrame,
	PredictOwn: number?,
	Ignore: number, -- hasta cuándo no se hace caso a las fotos (tu golpeo, aún sin confirmar)
	IgnoreSeq: number,
	NoCarryUntil: number,
}

local views: { [string]: View } = {}
local mine: View? = nil
local fields: { { [string]: any } } = {}
local fieldOn: string? = nil

-- Estado de los controles
local charging = false
local chargeStart = 0
local lastKickAt = 0
local cameraFreeUntil = 0
local snapCamera = false

-- Interfaz
local gui: ScreenGui
local board: Frame
local scoreLabel: TextLabel
local infoLabel: TextLabel
local banner: TextLabel
local hintCard: Frame
local hintLabel: TextLabel
local menu: Frame
local reticle: BasePart? = nil
local bannerToken = 0

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------

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

local function pitchFrom(d: { [string]: any }): Pitch.Pitch
	return Pitch.new(d.CFrame, d.Length, d.Width, {
		Id = d.Id,
		GoalLine = d.GoalLine,
		GoalWidth = d.GoalWidth,
		GoalHeight = d.GoalHeight,
		GoalDepth = d.GoalDepth,
		BoardMargin = d.BoardMargin,
	})
end

local function myTeam(view: View): number
	local you = view.Info.You
	local entry = you and view.Info.Roster and view.Info.Roster[you]
	return if entry then entry.Team else 1
end

local function attackSide(view: View): number
	return if myTeam(view) == 2 then -1 else 1
end

local function showBanner(text: string, color: Color3?, seconds: number?)
	bannerToken += 1
	local token = bannerToken
	banner.Text = text
	banner.TextColor3 = color or Color3.new(1, 1, 1)
	banner.Visible = true
	Theme.pop(banner, 0.12)
	task.delay(seconds or 1.6, function()
		if bannerToken == token then
			banner.Visible = false
		end
	end)
end

local function sound(name: string, pitch: number?, volume: number?)
	pcall(function()
		local SoundFx = require(script.Parent.SoundFx)
		SoundFx.play(name, volume, pitch)
	end)
end

---------------------------------------------------------------------
-- Interfaz
---------------------------------------------------------------------

local function build()
	gui = create("ScreenGui", {
		Name = "FutbolGui",
		ResetOnSpawn = false,
		DisplayOrder = 6,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	board = Theme.panel({
		Name = "Marcador",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 84),
		Size = UDim2.fromOffset(360, 58),
		Visible = false,
		Parent = gui,
	})
	scoreLabel = Theme.label({
		Size = UDim2.new(1, 0, 0, 30),
		Font = Theme.FontBold,
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Center,
		RichText = true,
		Parent = board,
	})
	infoLabel = Theme.label({
		Position = UDim2.fromOffset(0, 30),
		Size = UDim2.new(1, 0, 0, 22),
		TextSize = 15,
		TextColor3 = C.Gold,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = board,
	})
	banner = Theme.label({
		Name = "Banner",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.32),
		Size = UDim2.fromOffset(600, 64),
		Font = Theme.FontBold,
		TextSize = 44,
		TextStrokeTransparency = 0.3,
		TextXAlignment = Enum.TextXAlignment.Center,
		Visible = false,
		Parent = gui,
	})
	hintCard = Theme.panel({
		Name = "Pista",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 148),
		Size = UDim2.fromOffset(420, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = gui,
	})
	Theme.padding(8).Parent = hintCard
	hintLabel = Theme.label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 15,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = hintCard,
	})
	Theme.touchText(hintLabel, 16)
	-- Menú de la pachanga: partido, penaltis, libre
	menu = Theme.panel({
		Name = "ModoFutbol",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(300, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = gui,
	})
	Theme.padding(12).Parent = menu
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = menu })
	Theme.title({ Size = UDim2.new(1, 0, 0, 26), Text = "⚽ ¿A qué jugamos?", LayoutOrder = 0, Parent = menu })
	local options = {
		{ "Partido 3 contra 3", { Mode = "Partido", Size = 3 } },
		{ "Partido 5 contra 5", { Mode = "Partido", Size = 5 } },
		{ "Tanda de penaltis", { Mode = "Penaltis" } },
		{ "Jugar libre con el balón", { Mode = "Libre" } },
		{ "🧤 Ponerme de portero", { Keeper = true } },
		{ "🏃 Jugar de campo", { Keeper = false } },
		{ "Dejar de jugar", { Leave = true } },
		{ "Cerrar", { Close = true } },
	}
	for i, option in options do
		local button = Theme.button({ Size = UDim2.new(1, 0, 0, 42), Text = option[1], TextSize = 17, LayoutOrder = i, Parent = menu })
		button.Activated:Connect(function()
			menu.Visible = false
			local o = option[2]
			if o.Close then
				return
			elseif o.Leave then
				if remote then
					remote:FireServer("Leave")
				end
			elseif o.Keeper ~= nil then
				if remote then
					remote:FireServer("Keeper", { On = o.Keeper })
				end
			elseif remote then
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
	local snap = view.Last
	local info = view.Info
	local mode = info.Mode
	board.Visible = true
	if mode == "Partido" then
		local you = myTeam(view)
		local rival = (info.Story and info.Story.Rival) or TEAM_NAMES[2]
		local left, right = snap.G[1], snap.G[2]
		local nameLeft = if info.You then TEAM_NAMES[1] else "Azules"
		local nameRight = if info.You then rival else "Rojos"
		if you == 2 then
			left, right = right, left
		end
		scoreLabel.Text = ("%s  <font color=\"#FFD54A\">%d - %d</font>  %s"):format(nameLeft, left, right, nameRight)
		local remaining = math.max(0, (info.Duration or 0) - (snap.G[3] or 0))
		infoLabel.Text = ("⏱ %d:%02d"):format(math.floor(remaining / 60), math.floor(remaining % 60))
	elseif mode == "Penaltis" then
		local g = snap.G
		scoreLabel.Text = ("🥅 Penaltis: <font color=\"#FFD54A\">%d</font> de %d"):format(g[6], g[7])
		infoLabel.Text = if (info.Need or 0) > 0 then ("Tiro %d de %d · necesitas %d"):format(math.min(g[4], g[5]), g[5], info.Need) else ("Tiro %d de %d"):format(math.min(g[4], g[5]), g[5])
	elseif mode == "Pases" then
		local g = snap.G
		scoreLabel.Text = ("👟 Pases buenos: <font color=\"#FFD54A\">%d</font> de %d"):format(g[6], g[7])
		infoLabel.Text = ("Pase %d de %d · necesitas %d"):format(math.min(g[4], g[5]), g[5], info.Need or 1)
	else
		scoreLabel.Text = ("⚽ Juego libre  <font color=\"#FFD54A\">%d - %d</font>"):format(snap.G[1], snap.G[2])
		infoLabel.Text = if Theme.isTouch() then "Toca «Modo» para jugar un partido o unos penaltis" else "Pulsa M para jugar un partido o unos penaltis"
	end
end

---------------------------------------------------------------------
-- Balón (lo que se ve)
---------------------------------------------------------------------

local function makeBall(view: View)
	local part = Instance.new("Part")
	part.Name = "BalonFutbol"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.one * Ball.Config.Radius * 2
	part.Color = rgb(248, 248, 248)
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = true
	-- Manchas negras (se ve cómo gira)
	for i, offset in { Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, -1, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) } do
		local patch = Instance.new("Part")
		patch.Name = "Mancha" .. i
		patch.Shape = Enum.PartType.Ball
		patch.Size = Vector3.one * Ball.Config.Radius * 0.75
		patch.Color = rgb(30, 30, 34)
		patch.Material = Enum.Material.SmoothPlastic
		patch.Anchored = false
		patch.Massless = true
		patch.CanCollide = false
		patch.CanQuery = false
		patch.CanTouch = false
		patch.CastShadow = false
		patch.CFrame = part.CFrame + offset * Ball.Config.Radius * 0.72
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = part
		weld.Part1 = patch
		weld.Parent = patch
		patch.Parent = part
	end
	part.Parent = workspace
	view.Part = part
	-- Sombra en el césped (ayuda a ver la altura en el móvil)
	local shadow = Instance.new("Part")
	shadow.Name = "SombraBalon"
	shadow.Shape = Enum.PartType.Cylinder
	shadow.Size = Vector3.new(0.05, 1.3, 1.3)
	shadow.Color = rgb(20, 30, 20)
	shadow.Transparency = 0.55
	shadow.Material = Enum.Material.SmoothPlastic
	shadow.Anchored = true
	shadow.CanCollide = false
	shadow.CanQuery = false
	shadow.CanTouch = false
	shadow.CastShadow = false
	shadow.Parent = workspace
	view.Shadow = shadow
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
	if view.Shadow then
		view.Shadow:Destroy()
	end
	if mine == view then
		mine = nil
		TouchLayout.setSport(false)
		hintCard.Visible = false
		menu.Visible = false
		charging = false
		player:SetAttribute("SportCarry", nil)
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

-- Posición (local) de un jugador ahora mismo en tu pantalla
local function playerLocal(view: View, id: string): (Vector3?, Vector3?)
	if id == myId() then
		local c, root = character()
		local feet = feetOf(c)
		if feet and root then
			return Pitch.toLocal(view.Pitch, feet), Pitch.dirToLocal(view.Pitch, root.CFrame.LookVector)
		end
		return nil, nil
	end
	local entry = view.Info.Roster and view.Info.Roster[id]
	if entry and entry.Human then
		local model = modelOf(view, id)
		local feet = feetOf(model)
		local root = model and model:FindFirstChild("HumanoidRootPart") :: BasePart?
		if feet and root then
			return Pitch.toLocal(view.Pitch, feet), Pitch.dirToLocal(view.Pitch, root.CFrame.LookVector)
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

local runPhase = 0

local function renderBall(view: View, dt: number)
	local ownerId = view.Owner
	if view.PredictOwn then
		ownerId = myId()
	end
	local pitch = view.Pitch
	local s = view.Ball
	if ownerId then
		local p, facing = playerLocal(view, ownerId)
		if p and facing then
			local speed = 0
			if ownerId == myId() then
				local _, root = character()
				if root then
					speed = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude
				end
				runPhase += speed * dt
			end
			local before = s.P
			s.P = Ball.carryPosition(p, facing, speed, if ownerId == myId() then runPhase else os.clock() * 12)
			s.V = if dt > 0 then Pitch.flat(s.P - before) / dt else Vector3.zero
		end
	else
		Ball.step(s, dt, pitch)
	end
	-- El error de antes se va borrando poco a poco (sin saltos)
	view.Offset = view.Offset * math.exp(-11 * dt)
	local shown = s.P + view.Offset
	-- Que ruede: gira según lo que avanza
	local move = Pitch.flat(s.V) * dt
	if move.Magnitude > 1e-4 then
		local axis = Vector3.new(move.Z, 0, -move.X).Unit
		view.Spin = CFrame.fromAxisAngle(axis, -move.Magnitude / Ball.Config.Radius) * view.Spin
	end
	local world = Pitch.toWorld(pitch, shown)
	if view.Part then
		view.Part.CFrame = CFrame.new(world) * pitch.CFrame.Rotation * view.Spin
	end
	if view.Shadow then
		local ground = Pitch.toWorld(pitch, Vector3.new(shown.X, 0.03, shown.Z))
		local size = math.clamp(1.4 - (shown.Y - Ball.Config.Radius) * 0.06, 0.5, 1.4)
		view.Shadow.Size = Vector3.new(0.05, size, size)
		view.Shadow.CFrame = CFrame.new(ground) * CFrame.Angles(0, 0, math.pi / 2)
		view.Shadow.Transparency = if shown.Y > 1.2 then 0.55 else 1
	end
end

---------------------------------------------------------------------
-- Máquinas (entre dos fotos)
---------------------------------------------------------------------

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
		-- Las dos fotos alrededor de «ahora - BUFFER»
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
		local dive = a.Dive + (b.Dive - a.Dive) * f
		local diveVec = b.DiveVec
		local slide = b.Slide
		b.Shown = p
		b.ShownFacing = facing
		local pitch = view.Pitch
		local up = (model:GetAttribute("FootOffset") :: number?) or 3
		local feet = Pitch.toWorld(pitch, Vector3.new(p.X, 0, p.Z))
		local look = Pitch.dirToWorld(pitch, facing.Unit)
		local at = feet + Vector3.new(0, up, 0)
		local cf = CFrame.lookAt(at, at + Vector3.new(look.X, 0, look.Z))
		if dive > 0 and diveVec.Magnitude > 0.1 then
			-- Estirada: el cuerpo se tumba hacia el lado del balón y baja
			local side = Pitch.dirToWorld(pitch, diveVec)
			local lateral = cf.RightVector:Dot(Vector3.new(side.X, 0, side.Z).Unit)
			local roll = math.sin(math.min(dive, 1) * math.pi * 0.5) * 1.25 * (if lateral >= 0 then -1 else 1)
			local reach = Vector3.new(side.X, 0, side.Z) * math.min(dive, 1) * 0.55
			cf = (cf + reach - Vector3.new(0, up * 0.45 * math.min(dive, 1), 0)) * CFrame.Angles(0, 0, roll)
		elseif slide > 0 then
			cf = (cf - Vector3.new(0, up * 0.55, 0)) * CFrame.Angles(0.9, 0, 0)
		end
		root.CFrame = cf
	end
end

---------------------------------------------------------------------
-- Fotos y sucesos del servidor
---------------------------------------------------------------------

local function latency(): number
	local ok, ping = pcall(function()
		return player:GetNetworkPing()
	end)
	return if ok and type(ping) == "number" then math.clamp(ping, 0, 0.3) else 0.08
end

-- Pone el balón en un estado del servidor (corrigiendo poco a poco lo que se ve)
local function adoptBall(view: View, p: Vector3, v: Vector3, spin: number, inGoal: number, ahead: number)
	local target = Ball.new(p)
	target.V = v
	target.Spin = spin
	target.InGoal = inGoal
	if ahead > 0 and v.Magnitude > 0.1 then
		Ball.step(target, ahead, view.Pitch)
	end
	local shownBefore = view.Ball.P + view.Offset
	local err = shownBefore - target.P
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
	local b = snap.B
	local order = view.Info.Order or {}
	local owner = if b[4] and b[4] > 0 then order[b[4]] else nil
	local seq = b[5]
	-- Tu golpeo aún no confirmado: no se hace caso a fotos de antes
	local waiting = now < view.Ignore and seq <= view.IgnoreSeq
	if not waiting then
		view.Ignore = 0
		if view.PredictOwn and owner ~= myId() and now - view.PredictOwn > 0.4 then
			view.PredictOwn = nil -- (el servidor no te lo ha dado: otro llegó antes)
		end
		if owner == myId() then
			view.PredictOwn = nil
		end
		if owner and owner ~= myId() and not view.PredictOwn then
			view.Owner = owner
		elseif owner == myId() then
			view.Owner = owner
		else
			view.Owner = nil
			if not view.PredictOwn then
				adoptBall(view, b[1], b[2], b[3], b[6], latency())
			end
		end
		view.Seq = seq
	end
	-- Jugadores (en el orden de la última lista: si la foto es de otra lista, se espera a la nueva)
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
			local yaw = row[2]
			local dive = row[3]
			table.insert(list, {
				t = now,
				P = row[1],
				Facing = Vector3.new(math.cos(yaw), 0, math.sin(yaw)),
				DiveVec = if dive then dive[1] else Vector3.zero,
				Dive = if dive then dive[2] else 0,
				Slide = if row[4] then 1 else 0,
			})
			while #list > 6 do
				table.remove(list, 1)
			end
		end
	end
	if view == mine then
		updateBoard(view)
	end
end

local function phaseHint(view: View, kind: string)
	if view ~= mine then
		return
	end
	local info = view.Info
	if kind == "PenSetup" then
		hintLabel.Text = if Theme.isTouch()
			then "Gira la cámara hacia un lado de la portería (la diana te dice dónde va) y mantén «Chutar». ¡Ni flojo ni pasado!"
			else "Apunta con la cámara (la diana te dice dónde va) y mantén clic o F. ¡Ni flojo ni pasado!"
		hintCard.Visible = true
	elseif kind == "PassSetup" then
		hintLabel.Text = if info.Story and info.Story.Hint then info.Story.Hint else "Mira hacia tu compañero y toca «Pasar»"
		hintCard.Visible = true
	end
end

local function onEvent(kind: string, e: { [string]: any })
	local view = views[e.S]
	if not view then
		return
	end
	local isMine = view == mine
	local me = myId()
	if kind == "Kick" then
		local model = modelOf(view, e.Id)
		if e.Id ~= me then
			SportAnim.play(model, if e.Type == "Pass" then "Pase" else "Chute")
			-- El golpeo de otro: el balón sale ya (sin esperar a la foto)
			view.Owner = nil
			view.PredictOwn = nil
			adoptBall(view, e.P, e.V, e.Spin or 0, 0, latency())
			view.Seq = math.max(view.Seq, e.Seq or 0)
			sound("FutbolChute", 0.9 + (e.Power or 0.5) * 0.3, 0.35 + (e.Power or 0.5) * 0.4)
		else
			-- El tuyo: confirmado (ya salió en tu pantalla)
			view.Ignore = 0
			view.Seq = math.max(view.Seq, e.Seq or 0)
		end
	elseif kind == "Goal" then
		local mineScored = isMine and myTeam(view) == e.Team
		local scorer = e.Scorer and view.Info.Roster and view.Info.Roster[e.Scorer]
		local name = if e.Scorer == me then "¡GOOOOL TUYO!" elseif scorer then ("¡GOL de %s!"):format(scorer.Name) else "¡GOOOL!"
		if e.OwnGoal then
			name = "¡Gol en propia puerta!"
		end
		showBanner(name, if mineScored or not isMine then rgb(120, 240, 140) else rgb(255, 120, 110), 2.4)
		sound("FutbolSilbato", 1, 0.5)
		pcall(function()
			require(script.Parent.StoryAudio).sting("Momento")
		end)
		local model = e.Scorer and modelOf(view, e.Scorer)
		if model then
			SportAnim.play(model, "Celebrar")
		end
	elseif kind == "Save" then
		local model = modelOf(view, e.Id)
		SportAnim.play(model, "Estirada")
		if isMine then
			showBanner("¡Paradón!", rgb(255, 220, 90), 1.2)
		end
	elseif kind == "Post" then
		sound("FutbolPoste", 1, 0.7)
		if isMine then
			showBanner(if e.Type == "Bar" then "¡Al larguero!" else "¡Al poste!", rgb(255, 220, 90), 1.2)
		end
	elseif kind == "Tackle" then
		if isMine and e.Ok and e.Victim == me then
			showBanner("Te han robado el balón", rgb(255, 160, 120), 1)
		elseif isMine and e.Ok and e.Id == me then
			showBanner("¡Robado!", rgb(120, 240, 140), 1)
		end
	elseif kind == "Slide" then
		if e.Id ~= me then
			SportAnim.play(modelOf(view, e.Id), "Plancha")
		end
	elseif kind == "Dive" then
		if e.Id ~= me then
			SportAnim.play(modelOf(view, e.Id), "Estirada")
		end
	elseif kind == "Out" then
		if isMine then
			showBanner(if e.Type == "Side" then "Fuera de banda" else "Fuera", rgb(230, 230, 230), 1)
		end
		sound("FutbolSilbato", 1.1, 0.35)
	elseif kind == "Restart" then
		if isMine then
			local text = if e.Type == "Corner" then "Córner" elseif e.Type == "GoalKick" then "Saque de puerta" else "Saque de banda"
			showBanner(text, rgb(230, 230, 230), 1)
		end
	elseif kind == "Kickoff" then
		if isMine then
			snapCamera = true
			sound("FutbolSilbato", 1, 0.5)
		end
	elseif kind == "Teleport" then
		if e.Id == me then
			snapCamera = true
		end
	elseif kind == "PenSetup" or kind == "PassSetup" then
		if isMine then
			snapCamera = true
			phaseHint(view, kind)
		end
	elseif kind == "PenResult" or kind == "PassResult" then
		if isMine then
			local text, color
			if e.Ok then
				text, color = if kind == "PenResult" then "¡GOL!" else "¡Buen pase!", rgb(120, 240, 140)
			elseif e.Reason == "Save" then
				text, color = "¡Lo ha parado!", rgb(255, 160, 120)
			elseif e.Reason == "Post" then
				text, color = "¡Al palo!", rgb(255, 200, 100)
			elseif e.Reason == "Timeout" then
				text, color = "Se acabó el tiempo", rgb(255, 160, 120)
			else
				text, color = if kind == "PenResult" then "Fuera…" else "No le ha llegado", rgb(255, 160, 120)
			end
			showBanner(text, color, 1.6)
			if e.Ok then
				pcall(function()
					require(script.Parent.StoryAudio).sting("Momento")
				end)
			end
		end
	elseif kind == "Over" then
		if isMine then
			local info = view.Info
			local text = "¡Final!"
			if info.Mode == "Partido" then
				local you = myTeam(view)
				local a, b = e.Goals or 0, e.Against or 0
				if you == 2 then
					a, b = b, a
				end
				text = if a > b then ("¡Victoria! %d - %d"):format(a, b) elseif a == b then ("Empate %d - %d"):format(a, b) else ("Derrota %d - %d"):format(a, b)
			elseif info.Mode == "Penaltis" then
				text = ("%d de %d penaltis"):format(e.Hits or 0, e.Taken or 0)
			elseif info.Mode == "Pases" then
				text = ("%d pases buenos"):format(e.Hits or 0)
			end
			showBanner(text, C.Gold, 3)
			sound("FutbolSilbato", 0.9, 0.6)
			hintCard.Visible = false
		end
	end
end

local function onSession(info: { [string]: any })
	local view = views[info.S]
	if not view then
		view = {
			S = info.S,
			Info = info,
			Pitch = pitchFrom(info.Field),
			Ball = Ball.new(),
			Offset = Vector3.zero,
			Part = nil,
			Shadow = nil,
			Owner = nil,
			Seq = 0,
			Players = {},
			Last = nil,
			Spin = CFrame.new(),
			PredictOwn = nil,
			Ignore = 0,
			IgnoreSeq = 0,
			NoCarryUntil = 0,
		}
		views[info.S] = view
		makeBall(view)
	end
	view.Info = info
	-- Las máquinas que ya no están
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
		TouchLayout.setSport(true)
		snapCamera = true
		if info.Story and info.Story.Mine then
			hintLabel.Text = ("%s %s\n%s"):format(info.Story.Icon or "⚽", info.Story.Title or "", info.Story.Hint or "")
			hintCard.Visible = true
			task.delay(7, function()
				if mine == view and hintCard.Visible and hintLabel.Text:find(info.Story.Title or "", 1, true) then
					hintCard.Visible = false
				end
			end)
		else
			hintCard.Visible = false
		end
	elseif mine == view then
		mine = nil
		TouchLayout.setSport(false)
		hintCard.Visible = false
	end
	updateBoard(mine)
	TouchLayout.refresh()
end

---------------------------------------------------------------------
-- Golpeos (tú): sale ya en tu pantalla y se lo pides al servidor
---------------------------------------------------------------------

local function canReach(view: View): (boolean, Vector3?)
	local c = character()
	local feet = feetOf(c)
	if not feet then
		return false, nil
	end
	local loc = Pitch.toLocal(view.Pitch, feet)
	local ball = view.Ball.P + view.Offset
	if view.Owner == myId() or view.PredictOwn then
		return true, loc
	end
	if view.Owner then
		return false, loc
	end
	local scale = c and (c :: Model):GetScale() or 1
	local d = Vector3.new(ball.X - loc.X, 0, ball.Z - loc.Z).Magnitude
	return d <= 3.8 * scale + 1.2 and ball.Y < 3.6 * scale, loc
end

-- Hacia dónde apunta un tiro ahora (local): mira de la cámara, y cerca de la portería, a la portería
local function aimDirection(view: View, ballLoc: Vector3): (Vector3, Vector3?)
	local camera = workspace.CurrentCamera
	local look = Pitch.dirToLocal(view.Pitch, camera.CFrame.LookVector)
	local aim = Pitch.unitFlat(look)
	local side = attackSide(view)
	if view.Info.Mode == "Libre" then
		-- Sin equipos: la portería que tengas delante
		side = if aim.X >= 0 then 1 else -1
	end
	if view.Pitch.GoalWidth <= 0 then
		return aim, nil
	end
	local goal = Pitch.goalCenter(view.Pitch, side)
	local toGoal = Pitch.flat(goal - ballLoc)
	local dist = toGoal.Magnitude
	if dist < 52 and dist > 1 and aim:Dot(toGoal.Unit) > math.cos(math.rad(55)) then
		-- Donde corta la mira con la línea de gol, y el joystick la mueve de poste a poste
		local t = (goal.X - ballLoc.X) / (if math.abs(aim.X) > 1e-3 then aim.X else 1e-3)
		local z = ballLoc.Z + aim.Z * t
		local _, _, humanoid = character()
		if humanoid then
			local move = Pitch.dirToLocal(view.Pitch, humanoid.MoveDirection)
			local right = Vector3.new(-toGoal.Unit.Z, 0, toGoal.Unit.X)
			z += move:Dot(right) * view.Pitch.GoalWidth * 0.35
		end
		local hw = view.Pitch.GoalWidth / 2
		z = math.clamp(z, -hw - 2.5, hw + 2.5)
		local target = Vector3.new(goal.X, 0, z)
		return Pitch.unitFlat(target - ballLoc), target
	end
	return aim, nil
end

local function chargePower(): number
	if not charging then
		return 0
	end
	return math.clamp(0.15 + (os.clock() - chargeStart) / CHARGE_TIME * 0.85, 0.15, 1)
end

local nonce = 0
local function doKick(kind: string, power: number)
	local view = mine
	if not view or not remote or os.clock() - lastKickAt < 0.3 then
		return
	end
	local ok, myLoc = canReach(view)
	if not ok or not myLoc then
		if view.Info.Mode == "Penaltis" then
			showBanner("Acércate al balón", rgb(230, 230, 230), 0.8)
		end
		return
	end
	lastKickAt = os.clock()
	nonce += 1
	local c, root, humanoid = character()
	local ballLoc = view.Ball.P + view.Offset
	local cmd: { [string]: any } = { Nonce = nonce, BallP = ballLoc }
	local myVel = if root then Pitch.flat(Pitch.dirToLocal(view.Pitch, root.AssemblyLinearVelocity)) else Vector3.zero
	if kind == "Pass" then
		-- Al compañero que tengas delante (el de la cámara); si no hay, al frente
		local camera = workspace.CurrentCamera
		local aim = Pitch.unitFlat(Pitch.dirToLocal(view.Pitch, camera.CFrame.LookVector))
		local myTeamId = myTeam(view)
		local best, bestScore, bestPos = nil, -math.huge, nil
		for id, entry in view.Info.Roster or {} do
			if id == myId() or entry.Team ~= myTeamId then
				continue
			end
			local p = playerLocal(view, id)
			if p then
				local to = Pitch.flat(p - ballLoc)
				local d = to.Magnitude
				if d > 3 and d < 60 then
					local cos = aim:Dot(to.Unit)
					if cos > 0.45 then
						local score = cos * 30 - d * 0.25
						if score > bestScore then
							best, bestScore, bestPos = id, score, p
						end
					end
				end
			end
		end
		local dir, dist = aim, 16
		if best and bestPos then
			-- Un poco por delante de él si va corriendo
			local list = view.Players[best]
			local lead = Vector3.zero
			if list and #list >= 2 then
				local a, b = list[#list - 1], list[#list]
				if b.t > a.t then
					lead = Pitch.flat(b.P - a.P) / (b.t - a.t) * 0.45
				end
			end
			local target = bestPos + lead
			dir = Pitch.unitFlat(target - ballLoc, aim)
			dist = Pitch.flat(target - ballLoc).Magnitude
			cmd.To = best
		end
		cmd.Kind = if dist > Ball.Config.Pass.LobMin then "Lob" else "Pass"
		cmd.Dir = dir
		cmd.Dist = dist
		cmd.Power = 0.5
	else
		local dir = aimDirection(view, ballLoc)
		-- Precisión: con mucha fuerza o corriendo a tope, un poco menos (la Destreza ayuda)
		local skill = math.clamp((player:GetAttribute("Stat_Destreza") or 0) / 50, 0, 1)
		local spread = math.rad((power ^ 3) * 5 + (if myVel.Magnitude > 20 then 1.5 else 0)) * (1 - 0.5 * skill)
		local angle = (math.random() * 2 - 1) * spread
		dir = Vector3.new(dir.X * math.cos(angle) - dir.Z * math.sin(angle), 0, dir.X * math.sin(angle) + dir.Z * math.cos(angle))
		-- Efecto: corriendo de lado al soltar
		local curl = 0
		if humanoid and power > 0.45 then
			local move = Pitch.dirToLocal(view.Pitch, humanoid.MoveDirection)
			local right = Vector3.new(-dir.Z, 0, dir.X)
			curl = math.clamp(move:Dot(right), -1, 1) * 0.8
		end
		cmd.Kind = "Shoot"
		cmd.Dir = dir
		cmd.Power = power
		cmd.Curl = curl
		cmd.Loft = 0
	end
	-- En tu pantalla, ya
	local s = view.Ball
	s.P = Vector3.new(ballLoc.X, math.max(ballLoc.Y, Ball.Config.Radius), ballLoc.Z)
	view.Offset = Vector3.zero
	if cmd.Kind == "Pass" or cmd.Kind == "Lob" then
		s.V = Ball.passVelocity(cmd.Dir, cmd.Dist, cmd.Kind == "Lob")
		s.Spin = 0
	else
		s.V, s.Spin = Ball.shotVelocity(cmd.Dir, cmd.Power, cmd.Loft, cmd.Curl)
	end
	s.V += myVel * 0.25
	s.InGoal = 0
	view.Owner = nil
	view.PredictOwn = nil
	view.NoCarryUntil = os.clock() + 0.45
	view.Ignore = os.clock() + 0.7
	view.IgnoreSeq = view.Seq
	SportAnim.play(c, if cmd.Kind == "Shoot" then "Chute" else "Pase")
	sound("FutbolChute", 0.9 + power * 0.3, 0.35 + power * 0.4)
	remote:FireServer("Kick", cmd)
end

local function tackle()
	local view = mine
	if not view or not remote then
		return
	end
	local c, root, humanoid = character()
	if not root or not humanoid then
		return
	end
	local dir = humanoid.MoveDirection
	if dir.Magnitude < 0.2 then
		dir = root.CFrame.LookVector
	end
	local entry = view.Info.Roster and view.Info.Roster[myId()]
	if entry and entry.Role == "GK" then
		SportAnim.play(c, "Estirada")
		root.AssemblyLinearVelocity = Vector3.new(dir.X, 0, dir.Z).Unit * 30 + Vector3.new(0, 18, 0)
	else
		SportAnim.play(c, "Plancha")
		root.AssemblyLinearVelocity = Vector3.new(dir.X, 0, dir.Z).Unit * 34
	end
	remote:FireServer("Tackle", { Dir = Pitch.dirToLocal(view.Pitch, dir) })
end

---------------------------------------------------------------------
-- Diana de la portería (mientras cargas un tiro)
---------------------------------------------------------------------

local function updateReticle(view: View?)
	if not view or not charging then
		if reticle then
			reticle.Transparency = 1
		end
		return
	end
	local ballLoc = view.Ball.P + view.Offset
	local dir, target = aimDirection(view, ballLoc)
	if not target then
		if reticle then
			reticle.Transparency = 1
		end
		return
	end
	if not reticle then
		local part = Instance.new("Part")
		part.Name = "DianaFutbol"
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(0.1, 1.4, 1.4)
		part.Material = Enum.Material.Neon
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Parent = workspace
		reticle = part
	end
	-- A qué altura llegaría con la fuerza de ahora (la misma cuenta que el tiro)
	local power = chargePower()
	local probe = Ball.new(ballLoc)
	probe.V, probe.Spin = Ball.shotVelocity(dir, power, 0, 0)
	local _, cross = Ball.crossX(probe, view.Pitch, target.X - math.sign(target.X) * 0.3, 1.5)
	local y = if cross then cross.Y else view.Pitch.GoalHeight + 1
	local over = y > view.Pitch.GoalHeight
	local world = Pitch.toWorld(view.Pitch, Vector3.new(target.X, math.clamp(y, 0.6, view.Pitch.GoalHeight + 1.5), target.Z))
	local r = reticle :: BasePart
	r.CFrame = CFrame.new(world) * view.Pitch.CFrame.Rotation
	r.Transparency = 0.25
	r.Color = if over then rgb(255, 80, 70) elseif power > 0.85 then rgb(255, 200, 60) else rgb(110, 255, 140)
end

---------------------------------------------------------------------
-- Cámara: detrás de ti y girando sola hacia la portería
---------------------------------------------------------------------

local function cameraAssist(dt: number)
	local view = mine
	local camera = workspace.CurrentCamera
	if not view or not camera or camera.CameraType ~= Enum.CameraType.Custom then
		return
	end
	local _, root = character()
	if not root then
		return
	end
	local pitch = view.Pitch
	local me = Pitch.toLocal(pitch, root.Position)
	local side = attackSide(view)
	local ownBall = view.Owner == myId() or view.PredictOwn ~= nil
	local want: Vector3
	local rate: number
	if charging or ownBall then
		local goalSide = if view.Info.Mode == "Libre" then (if Pitch.dirToLocal(pitch, camera.CFrame.LookVector).X >= 0 then 1 else -1) else side
		want = Pitch.flat(Pitch.goalCenter(pitch, goalSide) - me)
		rate = if charging then 1.2 else 2.2
	else
		local ball = view.Ball.P + view.Offset
		want = Pitch.flat(ball - me)
		rate = 1.4
		if want.Magnitude < 6 then
			return
		end
	end
	if want.Magnitude < 1 then
		return
	end
	local wantWorld = Pitch.dirToWorld(pitch, want.Unit)
	local look = camera.CFrame.LookVector
	local current = math.atan2(-look.X, -look.Z)
	local goal = math.atan2(-wantWorld.X, -wantWorld.Z)
	local diff = (goal - current + math.pi) % (2 * math.pi) - math.pi
	local step: number
	if snapCamera then
		snapCamera = false
		step = diff
	elseif os.clock() < cameraFreeUntil or math.abs(diff) < math.rad(12) or (not charging and math.abs(diff) > math.rad(150)) then
		return
	else
		step = diff * math.min(1, dt * rate)
	end
	local focus = root.Position
	camera.CFrame = CFrame.new(focus) * CFrame.Angles(0, step, 0) * CFrame.new(-focus) * camera.CFrame
end

---------------------------------------------------------------------
-- Cada frame
---------------------------------------------------------------------

local function predictCarry(view: View)
	if view ~= mine or view.Owner or view.PredictOwn or os.clock() < view.NoCarryUntil or view.Info.Mode == "Penaltis" then
		return
	end
	local c, root = character()
	local feet = feetOf(c)
	if not feet or not root then
		return
	end
	local loc = Pitch.toLocal(view.Pitch, feet)
	local ball = view.Ball
	local scale = (c :: Model):GetScale()
	local d = Vector3.new(ball.P.X - loc.X, 0, ball.P.Z - loc.Z).Magnitude
	local rel = Pitch.flat(ball.V - Pitch.dirToLocal(view.Pitch, root.AssemblyLinearVelocity)).Magnitude
	if d < (1.75 + Ball.Config.Radius) * scale + 0.4 and ball.P.Y < 2.3 * scale and rel < 46 and ball.InGoal == 0 then
		view.PredictOwn = os.clock()
	end
end

local function onFieldNow(): string?
	local _, root = character()
	if not root then
		return nil
	end
	for _, d in fields do
		local p = d._pitch
		if not p then
			p = pitchFrom(d)
			d._pitch = p
		end
		local loc = Pitch.toLocal(p, root.Position)
		if math.abs(loc.X) < p.Length / 2 + 2 and math.abs(loc.Z) < p.Width / 2 + 2 and math.abs(loc.Y) < 12 then
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
	updateReticle(mine)
	-- (llevas el balón: lo puede mirar quien quiera, p. ej. para correr un poco más despacio)
	local carry = if mine and (mine.Owner == myId() or mine.PredictOwn) then true else nil
	if player:GetAttribute("SportCarry") ~= carry then
		player:SetAttribute("SportCarry", carry)
	end
end

---------------------------------------------------------------------
-- Botones y teclas
---------------------------------------------------------------------

local function inSport(): boolean
	return mine ~= nil
end

local function startCharge()
	if not mine or charging then
		return
	end
	charging = true
	chargeStart = os.clock()
end

local function releaseCharge()
	if not charging then
		return
	end
	local power = chargePower()
	local held = os.clock() - chargeStart
	charging = false
	if held < 0.12 then
		power = 0.42 -- (un toque: tiro suave y colocado)
	end
	doKick("Shoot", power)
end

local function registerButtons()
	TouchLayout.register({
		Id = "FutChutar",
		Icon = "balon",
		Label = "Chutar",
		SportSlot = "Ataque",
		Priority = 1,
		Key = "Clic / F",
		Pad = "RT",
		Visible = inSport,
		Hold = function(down: boolean)
			if down then
				startCharge()
			else
				releaseCharge()
			end
		end,
		Meter = function(): number?
			return if charging then chargePower() else nil
		end,
		Active = function(): boolean
			return charging
		end,
	})
	TouchLayout.register({
		Id = "FutPasar",
		Icon = "pase",
		Label = "Pasar",
		SportSlot = "Defender",
		Priority = 1,
		Key = "R",
		Pad = "X",
		Visible = inSport,
		Callback = function()
			doKick("Pass", 0.5)
		end,
	})
	TouchLayout.register({
		Id = "FutEntrar",
		Icon = "entrada",
		Label = "Entrar",
		SportSlot = "Esquivar",
		Priority = 1,
		Key = "Q",
		Pad = "B",
		Visible = inSport,
		Callback = tackle,
	})
	TouchLayout.register({
		Id = "FutModo",
		Icon = "menu",
		Label = "Modo",
		SportSlot = "Interactuar",
		Priority = 2,
		Key = "M",
		Pad = "Y",
		Visible = function(): boolean
			return mine ~= nil and not (mine.Info.Story and mine.Info.Story.Mine)
		end,
		Callback = function()
			menu.Visible = not menu.Visible
		end,
	})
	-- Fuera del partido: pisar un campo enseña «Jugar»
	TouchLayout.register({
		Id = "FutJugar",
		Icon = "balon",
		Label = "Jugar",
		Priority = 9,
		Key = "J",
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
	ContextActionService:BindActionAtPriority("FutbolInput", function(_, state, input)
		if not mine then
			return Enum.ContextActionResult.Pass
		end
		local key = input.KeyCode
		local mouse = input.UserInputType
		if key == Enum.KeyCode.F or key == Enum.KeyCode.ButtonR2 or mouse == Enum.UserInputType.MouseButton1 then
			if UserInputService:GetFocusedTextBox() or (state == Enum.UserInputState.Begin and SportInput.onButton(input)) then
				return Enum.ContextActionResult.Pass -- (el clic es para un botón de la interfaz)
			end
			if state == Enum.UserInputState.Begin then
				startCharge()
			elseif state == Enum.UserInputState.End then
				releaseCharge()
			end
			return Enum.ContextActionResult.Sink
		elseif state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		elseif key == Enum.KeyCode.R or key == Enum.KeyCode.ButtonX then
			doKick("Pass", 0.5)
		elseif key == Enum.KeyCode.Q or key == Enum.KeyCode.ButtonB then
			tackle()
		elseif key == Enum.KeyCode.M or key == Enum.KeyCode.ButtonY then
			if not (mine.Info.Story and mine.Info.Story.Mine) then
				menu.Visible = not menu.Visible
			end
		else
			return Enum.ContextActionResult.Pass
		end
		return Enum.ContextActionResult.Sink
	end, false, 3100, Enum.KeyCode.F, Enum.KeyCode.ButtonR2, Enum.UserInputType.MouseButton1, Enum.KeyCode.R, Enum.KeyCode.ButtonX, Enum.KeyCode.Q, Enum.KeyCode.ButtonB, Enum.KeyCode.M, Enum.KeyCode.ButtonY)
	-- J: unirse en el campo (en el ordenador; en el móvil, el botón «Jugar»)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or mine or not fieldOn or not remote then
			return
		end
		if input.KeyCode == Enum.KeyCode.J then
			remote:FireServer("Join", { F = fieldOn })
		end
	end)
	-- Si mueves tú la cámara (dedo fuera de los botones, ratón con el botón derecho, stick derecho),
	-- la cámara automática te deja un rato
	UserInputService.InputChanged:Connect(function(input, processed)
		if not mine then
			return
		end
		if input.UserInputType == Enum.UserInputType.Touch and not processed then
			local w = workspace.CurrentCamera.ViewportSize.X
			if input.Position.X > w * 0.35 then
				cameraFreeUntil = os.clock() + 1.6
			end
		elseif input.UserInputType == Enum.UserInputType.MouseMovement and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			cameraFreeUntil = os.clock() + 1.6
		elseif input.KeyCode == Enum.KeyCode.Thumbstick2 and input.Position.Magnitude > 0.3 then
			cameraFreeUntil = os.clock() + 1.6
		end
	end)
end

function FootballClient.init()
	build()
	SportAnim.register()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remote = remotes:WaitForChild("Futbol", 60) :: RemoteEvent?
	local stateRemote = remotes:WaitForChild("FutbolState", 60)
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
					charging = false
					view.Info.You = nil
					board.Visible = false
				end
			elseif kind == "Event" then
				onEvent(data.Kind, data)
			elseif kind == "KickRejected" then
				local view = views[data.S]
				if view then
					view.Ignore = 0
				end
			elseif kind == "Fields" then
				fields = data
			end
		end)
		if not ok then
			warn("[Futbol] " .. tostring(err))
		end
	end)
	if stateRemote then
		(stateRemote :: any).OnClientEvent:Connect(function(snap)
			local ok, err = pcall(onSnapshot, snap)
			if not ok then
				warn("[Futbol] " .. tostring(err))
			end
		end)
	end
	registerButtons()
	bindKeys()
	RunService.RenderStepped:Connect(function(dt)
		local ok, err = pcall(step, dt)
		if not ok then
			warn("[Futbol] " .. tostring(err))
		end
	end)
	RunService:BindToRenderStep("FutbolCamera", Enum.RenderPriority.Camera.Value + 2, function(dt)
		pcall(cameraAssist, dt)
	end)
	-- Los campos (para el botón «Jugar»): se piden al servidor y se mira si pisas uno
	task.spawn(function()
		task.wait(30)
		while #fields == 0 do
			remote:FireServer("Fields")
			task.wait(20)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.5)
			local now = onFieldNow()
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

return FootballClient
