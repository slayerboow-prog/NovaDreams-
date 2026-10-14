-- InvasionClient: lo que ves de la «Invasión de la Grieta» (docs/invasion.md). No decide nada: lo
-- manda todo el servidor (Services/InvasionService) y aquí solo se dibuja y se oye.
--
--   * Panel «EVENTO GLOBAL» arriba en el centro (UI/InvasionHud, en la columna de UI/TopStack: nunca
--     pisa el HUD; a los mandos de un avión, debajo de los instrumentos; en la nave no sale, porque el
--     HUD de la nave lo enseña en su fila EVENTO).
--   * Marcadores: cada zona (nombre y barra de control, de lejos) y los alienígenas cercanos (una
--     flecha roja con su vida; menos en gráficos Bajo).
--   * Efectos de los disparos, explosiones (trozos, chispas y luz: nada de sangre), aterrizajes, los
--     avisos de los ataques del rey (círculos en el suelo), transformaciones y curas, con los sonidos
--     de siempre (Config.Sounds) y los topes de shared/AirCombat/FxBudget.
--   * El CAÑÓN de la avioneta (solo durante la invasión): mantener el botón CAÑÓN (móvil), el clic
--     izquierdo o RB del mando. El servidor decide si da (remoto "Invasion" "PlaneFire").
--   * La gente de tu pantalla huye (Controllers/Ambient: peatones; Traffic: coches) de lo que publica
--     el servidor (atributos InvasionThreats / InvasionSafe; shared/Invasion/Panic) y vuelve poco a poco.
--   * Las naves pueden bajar al cielo de la ciudad mientras dure (shared/Cosmos/Layers.setCityOpen).

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage.Shared
local Races = require(Shared.Invasion.Races)
local Panic = require(Shared.Invasion.Panic)
local Landing = require(Shared.Invasion.Landing)
local Rules = require(Shared.Invasion.Rules)
local Layers = require(Shared.Cosmos.Layers)

local InvasionClient = {}

local player = Players.LocalPlayer
local remote: RemoteEvent? = nil
local state: { [string]: any }? = nil
local view: { [string]: any }? = nil
local gui: ScreenGui? = nil
local zoneMarks: { [string]: BillboardGui } = {}
local alienMarks: { [Instance]: BillboardGui } = {}
local endedAt: number? = nil
local firing = false
local lastShot = 0
local shotSounds = 0
local shotSoundsAt = 0

local function mod(name: string): any
	local ok, m = pcall(function()
		return require(script.Parent[name])
	end)
	return if ok then m else nil
end

local function ui(name: string): any
	local ok, m = pcall(function()
		return require(script.Parent.Parent.UI[name])
	end)
	return if ok then m else nil
end

local function tier(): string
	local t = player:GetAttribute("GraphicsTier")
	return if type(t) == "string" then t else "Medium"
end

local function toast(kind: string, text: string)
	local Hud = ui("Hud")
	if Hud and Hud.toast then
		pcall(Hud.toast, kind, text)
	end
end

local function sound(name: string, at: Vector3?, pitch: number?, volume: number?)
	local SoundFx = mod("SoundFx")
	if SoundFx then
		pcall(SoundFx.play, name, { Volume = volume or 0.9, Pitch = pitch or 1, At = at })
	end
end

local function decode(raw: any): any
	if type(raw) ~= "string" then
		return nil
	end
	local ok, value = pcall(HttpService.JSONDecode, HttpService, raw)
	return if ok then value else nil
end

local function myRoot(): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

---------------------------------------------------------------------
-- El panel
---------------------------------------------------------------------
local function inShip(): boolean
	return player:GetAttribute("AirCombat") ~= nil
end

local function nearestZone(st: { [string]: any }): { [string]: any }?
	local root = myRoot()
	if not root or type(st.Zones) ~= "table" then
		return nil
	end
	local list = {}
	for _, z in st.Zones do
		table.insert(list, { Pos = Vector3.new(z.X, z.Y or 0, z.Z), Z = z })
	end
	local i = Landing.nearest(list, root.Position, 600)
	return if i then list[i].Z else nil
end

local function paint()
	local TopStack = ui("TopStack")
	local InvasionHud = ui("InvasionHud")
	if not view or not TopStack or not InvasionHud then
		return
	end
	local st = state
	local show = st ~= nil and not inShip()
	if show and st then
		local t = InvasionHud.text(st, nearestZone(st), Races.names(st.Races or {}))
		InvasionHud.paint(view, t)
	end
	TopStack.set(view.Frame, show)
end

local function build()
	local TopStack = ui("TopStack")
	local InvasionHud = ui("InvasionHud")
	local Theme = ui("Theme")
	local HudLayout = ui("HudLayout")
	if not TopStack or not InvasionHud or not Theme then
		return
	end
	local g = Instance.new("ScreenGui")
	g.Name = "InvasionGui"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = 5
	g.Parent = player:WaitForChild("PlayerGui")
	if HudLayout then
		pcall(HudLayout.scaleGui, g)
	end
	gui = g
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	view = InvasionHud.build(g, Theme, touch)
	TopStack.register(view.Frame, TopStack.Priority.Mission, { Id = "InvasionPanel" })
end

---------------------------------------------------------------------
-- Marcadores
---------------------------------------------------------------------
local function zoneMark(z: { [string]: any })
	local mark = zoneMarks[z.Id]
	if not mark then
		local holder = workspace:FindFirstChild("InvasionMarks") or Instance.new("Folder")
		holder.Name = "InvasionMarks"
		holder.Parent = workspace
		local anchor = Instance.new("Part")
		anchor.Name = "Zona_" .. tostring(z.Id)
		anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
		anchor.Transparency = 1
		anchor.Size = Vector3.new(1, 1, 1)
		anchor.Parent = holder
		mark = Instance.new("BillboardGui")
		mark.Name = "ZonaInvasion"
		mark.Size = UDim2.fromOffset(150, 40)
		mark.StudsOffset = Vector3.new(0, 30, 0)
		mark.AlwaysOnTop = true
		mark.MaxDistance = 2600
		mark.LightInfluence = 0
		mark.Adornee = anchor
		-- (a los mandos de un avión o de la nave no sale: tapaba CAÑÓN y FRENOS; UI/FlightFocus)
		pcall(function()
			require(script.Parent.Parent.UI.FlightFocus).tagWorld(mark)
		end)
		local label = Instance.new("TextLabel")
		label.Name = "Name"
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, 0, 0, 22)
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0.4
		label.Parent = mark
		local back = Instance.new("Frame")
		back.Name = "Bar"
		back.Position = UDim2.fromOffset(15, 26)
		back.Size = UDim2.new(1, -30, 0, 8)
		back.BackgroundColor3 = Color3.fromRGB(20, 24, 30)
		back.BorderSizePixel = 0
		back.Parent = mark
		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.BorderSizePixel = 0
		fill.Parent = back
		mark.Parent = anchor
		zoneMarks[z.Id] = mark
	end
	local anchor = mark.Adornee :: BasePart
	anchor.Position = Vector3.new(z.X, z.Y or 0, z.Z)
	local label = mark:FindFirstChild("Name") :: TextLabel
	local fill = (mark:FindFirstChild("Bar") :: Frame):FindFirstChild("Fill") :: Frame
	local control = tonumber(z.Control) or 0
	label.Text = (if z.Conquered then "🛸 " elseif control > 0.02 then "⚠ " else "🏳 ") .. tostring(z.Name)
	fill.Size = UDim2.fromScale(if z.Conquered or control > 0.02 then control else 1, 1)
	fill.BackgroundColor3 = if z.Conquered then Color3.fromRGB(235, 70, 90) elseif control > 0.02 then Color3.fromRGB(255, 190, 60) else Color3.fromRGB(80, 210, 120)
end

local function clearZoneMarks()
	for id, mark in zoneMarks do
		if mark.Adornee then
			mark.Adornee:Destroy()
		end
		zoneMarks[id] = nil
	end
end

local MARK_CAP = { Low = 6, Medium = 10, High = 16 }
local MARK_RANGE = { Low = 260, Medium = 450, High = 700 }
local function alienMark(model: Instance): BillboardGui?
	local mark = alienMarks[model]
	if mark then
		return mark
	end
	local root = (model :: Model).PrimaryPart
	if not root then
		return nil
	end
	mark = Instance.new("BillboardGui")
	mark.Name = "MarcaAlien"
	mark.Size = UDim2.fromOffset(46, 28)
	mark.StudsOffset = Vector3.new(0, root.Size.Y / 2 + 3, 0)
	mark.AlwaysOnTop = true
	mark.LightInfluence = 0
	mark.Enabled = false
	local arrow = Instance.new("TextLabel")
	arrow.BackgroundTransparency = 1
	arrow.Size = UDim2.new(1, 0, 0, 18)
	arrow.Text = if model:GetAttribute("Kind") == "King" then "👑" else "▼"
	arrow.TextScaled = true
	arrow.Font = Enum.Font.GothamBlack
	arrow.TextColor3 = Color3.fromRGB(255, 70, 90)
	arrow.TextStrokeTransparency = 0.3
	arrow.Parent = mark
	local back = Instance.new("Frame")
	back.Name = "Bar"
	back.Position = UDim2.fromOffset(3, 20)
	back.Size = UDim2.new(1, -6, 0, 5)
	back.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
	back.BorderSizePixel = 0
	back.Parent = mark
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(255, 80, 90)
	fill.BorderSizePixel = 0
	fill.Parent = back
	mark.Adornee = root
	mark.Parent = root
	alienMarks[model] = mark
	return mark
end

local function refreshAlienMarks()
	local folder = workspace:FindFirstChild("Invasion")
	local root = myRoot()
	if not folder or not root then
		return
	end
	local t = tier()
	local list = {}
	for _, sub in folder:GetChildren() do
		if sub.Name == "Ground" or sub.Name == "Air" then
			for _, m in sub:GetChildren() do
				if m:IsA("Model") and m:GetAttribute("InvasionTarget") and m.PrimaryPart then
					table.insert(list, { M = m, D = (m.PrimaryPart.Position - root.Position).Magnitude })
				end
			end
		end
	end
	table.sort(list, function(a, b)
		return a.D < b.D
	end)
	local cap, range = MARK_CAP[t] or 10, MARK_RANGE[t] or 450
	local seen = {}
	for i, e in list do
		seen[e.M] = true
		local isKing = e.M:GetAttribute("Kind") == "King"
		local on = isKing or (i <= cap and e.D <= range)
		local mark = if on then alienMark(e.M) else alienMarks[e.M]
		if mark then
			mark.Enabled = on
			local hp, max = tonumber(e.M:GetAttribute("Hp")) or 1, tonumber(e.M:GetAttribute("MaxHp")) or 1
			local fill = (mark:FindFirstChild("Bar") :: Frame):FindFirstChild("Fill") :: Frame
			fill.Size = UDim2.fromScale(math.clamp(hp / math.max(max, 1), 0, 1), 1)
		end
	end
	for m, mark in alienMarks do
		if not seen[m] or not m.Parent then
			mark:Destroy()
			alienMarks[m] = nil
		end
	end
end

---------------------------------------------------------------------
-- Efectos
---------------------------------------------------------------------
local function fx(): any
	return mod("AirCombatFx")
end

local function raceOf(id: any): Races.Race?
	return if type(id) == "string" then Races.get(id) else nil
end

local function telegraph(centers: { Vector3 }, attack: string, dir: Vector3?, seconds: number, radius: number?, width: number?, length: number?, raceId: string?)
	local race = raceOf(raceId)
	local color = if race then Races.color(race.Palette.Glow) else Color3.fromRGB(255, 80, 90)
	for _, c in centers do
		if typeof(c) ~= "Vector3" then
			continue
		end
		local p = Instance.new("Part")
		p.Name = "AvisoRey"
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
		p.Material = Enum.Material.Neon
		p.Color = color
		p.Transparency = 0.6
		if attack == "Rayo" and typeof(dir) == "Vector3" then
			local fwd = Vector3.new(dir.X, 0, dir.Z)
			fwd = if fwd.Magnitude > 0.01 then fwd.Unit else Vector3.new(0, 0, -1)
			local len = length or 140
			p.Size = Vector3.new(width or 12, 0.3, len)
			p.CFrame = CFrame.lookAt(c + fwd * len / 2 + Vector3.new(0, 0.3, 0), c + fwd * len + Vector3.new(0, 0.3, 0))
		else
			local r = radius or 30
			p.Shape = Enum.PartType.Cylinder
			p.Size = Vector3.new(0.3, r * 2, r * 2)
			p.CFrame = CFrame.new(c + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
		end
		p.Parent = workspace
		task.spawn(function()
			local t0 = os.clock()
			while os.clock() - t0 < seconds and p.Parent do
				p.Transparency = 0.6 - 0.4 * ((os.clock() - t0) / seconds)
				task.wait(0.05)
			end
			p:Destroy()
		end)
	end
end

local function onEvent(kind: string, data: any)
	local F = fx()
	if kind == "Bolt" and type(data) == "table" and F then
		pcall(F.tracer, data.Pos, data.Dir, data.Speed, data.Life, true)
	elseif kind == "Shot" and type(data) == "table" and F and typeof(data.From) == "Vector3" and typeof(data.To) == "Vector3" then
		local d = data.To - data.From
		if d.Magnitude > 1 then
			pcall(F.tracer, data.From, d.Unit, 700, math.min(d.Magnitude / 700, 1.2), data.Kind ~= "Plane" and data.Kind ~= "Police")
		end
		local now = os.clock()
		if now - shotSoundsAt > 1 then
			shotSoundsAt, shotSounds = now, 0
		end
		if shotSounds < 8 then
			shotSounds += 1
			local race = raceOf(data.Race)
			if data.Kind == "Plane" then
				sound("NaveLaser", data.From, 0.8, 0.6)
			elseif data.Kind == "Police" then
				sound("DisparoPistola", data.From, 1, 0.7)
			elseif race then
				sound(race.Sounds.Shot, data.From, race.Sounds.ShotPitch, 0.7)
			end
		end
	elseif kind == "Boom" and type(data) == "table" and typeof(data.Pos) == "Vector3" then
		if F then
			pcall(F.burst, data.Pos, math.clamp((data.Size or 1) * 0.5, 0.2, 1))
			if (data.Size or 1) >= 1 then
				pcall(F.wreck, data.Pos, Vector3.new(0, -20, 0), math.clamp((data.Size or 1) * 0.5, 0.2, 1))
			end
		end
		local race = raceOf(data.Race)
		sound(if race then race.Sounds.Boom else "NaveEstallido", data.Pos, if race then race.Sounds.BoomPitch else 1, 1)
		local root = myRoot()
		if root and (root.Position - data.Pos).Magnitude < 80 then
			local shake = mod("CameraShake")
			if shake and shake.shake then
				pcall(shake.shake, 0.25 * (data.Size or 1), 0.35)
			end
		end
	elseif kind == "Landing" and type(data) == "table" then
		toast("Error", ("🛸 ¡Una nave aterriza en %s!"):format(tostring(data.Name)))
		sound("NaveMotor", data.Pos, 0.5, 1)
	elseif kind == "Blink" and type(data) == "table" and F then
		pcall(F.hit, data.Pos, nil, nil, true)
	elseif kind == "Swipe" and type(data) == "table" and F then
		pcall(F.hit, data.To, nil, nil, false)
	elseif kind == "KingWarn" and type(data) == "table" then
		telegraph(data.Centers or {}, data.Attack, data.Dir, data.Seconds or 2, data.Radius, data.Width, data.Length, data.Race)
		local race = raceOf(data.Race)
		if race then
			sound(race.Sounds.Roar, (data.Centers or {})[1], race.Sounds.RoarPitch, 1)
		end
	elseif kind == "KingStrike" and type(data) == "table" and F then
		for _, c in data.Centers or {} do
			pcall(F.burst, c, 1)
		end
		sound("NaveEstallido", (data.Centers or {})[1], 0.6, 1)
	elseif kind == "King" and type(data) == "table" then
		if data.Line then
			toast("Error", ("👑 «%s»"):format(tostring(data.Line)))
		end
	elseif kind == "Transform" and type(data) == "table" then
		toast("Info", ("✨ Alguien se ha transformado en %s"):format(tostring(data.Name)))
		if F then
			pcall(F.hit, data.Pos, nil, nil, true)
		end
	elseif kind == "Restore" and type(data) == "table" and F then
		pcall(F.hit, data.Pos, nil, Color3.fromRGB(255, 240, 200), true)
	elseif kind == "Loot" and type(data) == "table" then
		local parts = {}
		for i, item in data do
			if i <= 4 then
				table.insert(parts, ("%s×%d"):format(tostring(item.Name), item.Count or 1))
			end
		end
		toast("Success", "🎁 " .. table.concat(parts, " · "))
		sound("Coger", nil, 1.1, 0.7)
	elseif kind == "World" and type(data) == "table" then
		toast(data.Kind or "Info", tostring(data.Text))
	elseif kind == "Start" then
		sound("Aviso", nil, 0.8, 1)
	elseif kind == "Brief" and type(data) == "table" then
		toast("Info", ("📻 %s — %s"):format(tostring(data.Title), tostring(data.Giver)))
		for i, line in data.Lines or {} do
			task.delay(i * 3, function()
				toast("Info", tostring(line))
			end)
		end
	elseif kind == "MissionDone" and type(data) == "table" then
		sound("MisionCompleta", nil, 1, 1)
		if data.Outro then
			task.delay(1.5, function()
				toast("Success", tostring(data.Outro))
			end)
		end
	elseif kind == "End" and type(data) == "table" then
		toast(if data.Outcome == "Victoria" then "Success" else "Error", ("%s · %d puntos · $%d · %d XP"):format(if data.Outcome == "Victoria" then "🏆 ¡Victoria!" else "La invasión ha acabado", data.Points or 0, data.Money or 0, data.Xp or 0))
	elseif kind == "PlaneHit" and type(data) == "table" then
		if F then
			pcall(F.hit, (myRoot() or { Position = Vector3.zero } :: any).Position, nil, nil, false)
		end
	elseif kind == "Hurt" then
		local shake = mod("CameraShake")
		if shake and shake.shake then
			pcall(shake.shake, 0.15, 0.2)
		end
	end
end

---------------------------------------------------------------------
-- El cañón de la avioneta
---------------------------------------------------------------------
local function planeActive(): any
	local Flying = mod("Flying")
	if not Flying or not Flying._active then
		return nil
	end
	local ok, a = pcall(Flying._active)
	if ok and type(a) == "table" and Rules.PlaneGun.Kinds[a.Kind] and a.Sim and not a.Sim.OnGround then
		return a
	end
	return nil
end

local function gunReady(): boolean
	return state ~= nil and state.State == "Wave" and planeActive() ~= nil
end
InvasionClient.gunReady = gunReady

-- Los alienígenas cercanos que se ven (para la mira del avión: fijar el más centrado)
function InvasionClient.aliens(): { Instance }
	local out = {}
	for model in alienMarks do
		if model.Parent then
			table.insert(out, model)
		end
	end
	return out
end

local function fireStep()
	if not firing or not gunReady() or not remote then
		return
	end
	local now = os.clock()
	if now - lastShot < Rules.PlaneGun.Cooldown then
		return
	end
	lastShot = now
	local a = planeActive()
	local root = a and a.Root
	if root then
		remote:FireServer("PlaneFire", root.CFrame.LookVector)
	end
end

local function registerButton()
	local TouchLayout = ui("TouchLayout")
	if not TouchLayout then
		return
	end
	pcall(TouchLayout.register, {
		Id = "CanonAvion",
		Icon = "disparar",
		Art = "misil",
		Label = "CAÑÓN",
		FlySlot = "CanonAvion",
		Priority = 0.5,
		Key = "Clic",
		Pad = "RB",
		Tint = Color3.fromRGB(200, 60, 60),
		Visible = gunReady,
		Hold = function(down: boolean)
			firing = down
		end,
	})
end

---------------------------------------------------------------------
-- La gente que huye y las naves en el cielo de la ciudad
---------------------------------------------------------------------
local safes: { Panic.Safe } = {}
local function readSafes()
	local list = decode(workspace:GetAttribute("InvasionSafe"))
	safes = {}
	if type(list) == "table" then
		for _, e in list do
			if type(e) == "table" and type(e[1]) == "number" then
				table.insert(safes, { Pos = Vector3.new(e[1], 0, e[2]), Kind = tostring(e[3] or "Door") })
			end
		end
	end
end

local function panicStep()
	local Ambient = mod("Ambient")
	local Traffic = mod("Traffic")
	local threats = Panic.decode(decode(workspace:GetAttribute("InvasionThreats")))
	local caps = Panic.caps(tier())
	if Ambient then
		local root = myRoot()
		local level = if root then Panic.level(root.Position, threats) else 0
		if state and state.State ~= "End" then
			Ambient.CrowdFactor = Panic.streetShare(math.max(level, if #threats > 0 then 0.3 else 0))
		else
			Ambient.CrowdFactor = Panic.returnShare(if endedAt then os.clock() - endedAt else nil)
		end
		if #threats > 0 and Ambient.invasionPanic then
			pcall(Ambient.invasionPanic, threats, safes, caps)
		end
	end
	if Traffic and Traffic.setPanic then
		pcall(Traffic.setPanic, threats, caps.Honks)
	end
end

---------------------------------------------------------------------
-- Arranque
---------------------------------------------------------------------
local function onState()
	local before = state
	state = decode(workspace:GetAttribute("Invasion"))
	if state and type(state.Zones) == "table" then
		for _, z in state.Zones do
			zoneMark(z)
		end
	elseif not state then
		clearZoneMarks()
	end
	if before and before.State ~= "End" and (not state or state.State == "End") then
		endedAt = os.clock()
	end
	paint()
end

function InvasionClient.init()
	remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Invasion", 30) :: RemoteEvent?
	build()
	registerButton()
	Layers.setCityOpen(workspace:GetAttribute("InvasionActive") == true)
	workspace:GetAttributeChangedSignal("InvasionActive"):Connect(function()
		Layers.setCityOpen(workspace:GetAttribute("InvasionActive") == true)
	end)
	workspace:GetAttributeChangedSignal("Invasion"):Connect(onState)
	workspace:GetAttributeChangedSignal("InvasionSafe"):Connect(readSafes)
	player:GetAttributeChangedSignal("AirCombat"):Connect(paint)
	readSafes()
	onState()
	if remote then
		remote.OnClientEvent:Connect(function(kind, data)
			local ok, err = pcall(onEvent, kind, data)
			if not ok then
				warn("[Invasion] " .. tostring(err))
			end
		end)
		remote:FireServer("Sync")
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR1) and gunReady() then
			firing = true
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR1 then
			firing = false
		end
	end)
	local acc, slow = 0, 0
	RunService.Heartbeat:Connect(function(dt)
		fireStep()
		-- (los trazadores y explosiones de AirCombatFx avanzan aquí si no vas en una nave: allí ya avanzan)
		if (state or endedAt) and not inShip() then
			local F = fx()
			if F then
				pcall(F.step, dt)
			end
		end
		acc += dt
		slow += dt
		if acc >= 0.5 then
			acc = 0
			if state then
				pcall(refreshAlienMarks)
				paint()
			end
		end
		if slow >= 1 then
			slow = 0
			if state or (endedAt and os.clock() - endedAt < Panic.ReturnSeconds + 5) then
				pcall(panicStep)
			end
		end
	end)
end

InvasionClient._onEvent = onEvent
InvasionClient._state = function()
	return state
end

return InvasionClient
