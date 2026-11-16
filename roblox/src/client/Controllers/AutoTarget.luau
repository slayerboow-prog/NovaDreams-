-- AutoTarget (cliente): el COMBATE DE MMO (petición del dueño, con su captura de referencia de un MMO de móvil).
--
--   * OBJETIVO: tocar (o pulsar con el ratón) una bestia la elige; si no hay ninguna elegida, el botón Atacar
--     elige la más cercana. Arriba en el centro sale su ficha: nombre (del color de su dificultad), nivel, ★ si
--     es campeona, 👑 si es jefe, y su vida. Un contorno rojo la marca. La ✕ de la ficha la suelta.
--   * ATACAR: un toque (o mantenerlo) y tu personaje CORRE solo hacia ella, se gira y encadena golpes con lo que
--     lleves en la mano (puños o tu arma blanca: CombatController.swing, mismo ritmo que el servidor). Al
--     caer, si hay otra bestia cerca, sigue con ella. Moverte con el joystick (o las teclas) lo para.
--   * VIDA y ESPÍRITU: en plena caza, debajo de tu ficha, tus dos barras (roja y azul). El espíritu lo gastan
--     las habilidades (Controllers/HunterSkillsUI, Services/HunterSkillService).
-- Quien decide los golpes sigue siendo el servidor (CombatService: alcance hasta el borde del cuerpo).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Combat = require(ReplicatedStorage.Shared.Combat)
local Theme = require(script.Parent.Parent.UI.Theme)
local HudLayout = require(script.Parent.Parent.UI.HudLayout)

local AutoTarget = {}

AutoTarget.PickRange = 45 -- el Atacar elige la bestia más cercana a menos de esto
AutoTarget.NextRange = 22 -- al caer una, sigue con otra si está así de cerca
AutoTarget.LoseRange = 75 -- más lejos, se suelta
AutoTarget.FightNear = 40 -- tus barras de vida y espíritu salen con una bestia así de cerca

local player = Players.LocalPlayer
local create = Theme.create
local rgb = Color3.fromRGB

local target: Model? = nil
local active = false -- persiguiendo y golpeando
local swingFn: (() -> boolean)? = nil
local lastMoveTo = 0
local highlight: Highlight? = nil

local gui: ScreenGui
local frame: Frame
local nameLabel: TextLabel
local hpFill: Frame
local hpText: TextLabel
local bars: Frame
local lifeFill: Frame
local lifeText: TextLabel
local manaFill: Frame
local manaText: TextLabel

local function body(): (Humanoid?, BasePart?)
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid"), character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function alive(m: Model?): boolean
	if not m or not m.Parent or not m.PrimaryPart then
		return false
	end
	if m:GetAttribute("EnemyDown") then
		return false
	end
	local hp = tonumber(m:GetAttribute("Hp"))
	return hp == nil or hp > 0
end

local function flat(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

-- Lo que mide su cuerpo de medio (para llegar a su piel, no a su centro)
local function padOf(m: Model): number
	local root = m.PrimaryPart
	return if root then math.min(math.max(root.Size.X, root.Size.Z) / 2, 14) else 0
end

-- La bestia viva más cercana a `from` (sin contar `skip`)
local function nearest(from: Vector3, range: number, skip: Model?): Model?
	local best, bestD = nil, range
	for _, m in CollectionService:GetTagged("Bestia") do
		if m:IsA("Model") and m ~= skip and alive(m) then
			local d = flat(m.PrimaryPart.Position, from) - padOf(m)
			if d < bestD then
				best, bestD = m, d
			end
		end
	end
	return best
end

-- ¿El jugador se está moviendo él (joystick o teclas)?
local controls: any = nil
local function steering(): boolean
	if not controls then
		pcall(function()
			local module = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule") :: any)
			controls = module:GetControls()
		end)
	end
	local v = Vector3.zero
	if controls then
		pcall(function()
			v = controls:GetMoveVector()
		end)
	end
	return v.Magnitude > 0.35
end

local function setHighlight(m: Model?)
	if highlight then
		highlight:Destroy()
		highlight = nil
	end
	if m then
		local h = Instance.new("Highlight")
		h.Name = "ObjetivoMMO"
		h.FillTransparency = 1
		h.OutlineColor = rgb(255, 70, 50)
		h.OutlineTransparency = 0.1
		h.DepthMode = Enum.HighlightDepthMode.Occluded
		h.Adornee = m
		h.Parent = gui
		highlight = h
	end
end

function AutoTarget.select(m: Model?)
	if m == target then
		return
	end
	target = if m and alive(m) then m else nil
	if not target then
		active = false
	end
	setHighlight(target)
end

function AutoTarget.current(): Model?
	return if alive(target) then target else nil
end

function AutoTarget.active(): boolean
	return active and alive(target)
end

function AutoTarget.stop()
	active = false
	local hum, root = body()
	if hum and root then
		hum:MoveTo(root.Position)
	end
end

function AutoTarget.setSwing(fn: () -> boolean)
	swingFn = fn
end

-- El botón Atacar: elige (si hace falta) y empieza a perseguir y golpear. false = no hay bestia cerca
-- (entonces CombatController hace el golpe de siempre)
function AutoTarget.engage(): boolean
	local _, root = body()
	if not root then
		return false
	end
	if not alive(target) or flat(target.PrimaryPart.Position, root.Position) > AutoTarget.LoseRange then
		AutoTarget.select(nearest(root.Position, AutoTarget.PickRange, nil))
	end
	if not target then
		return false
	end
	active = true
	return true
end

-- Cada fotograma: perseguir, girarse y golpear
local function step()
	if not active then
		return
	end
	local hum, root = body()
	if not hum or not root or hum.Health <= 0 or hum.Sit then
		active = false
		return
	end
	if steering() then
		active = false -- (el jugador manda: se mueve él)
		return
	end
	if not alive(target) then
		local nextOne = nearest(root.Position, AutoTarget.NextRange, target)
		AutoTarget.select(nextOne)
		if not nextOne then
			active = false
			return
		end
	end
	local m = target :: Model
	local pos = m.PrimaryPart.Position
	local d = flat(pos, root.Position)
	if d > AutoTarget.LoseRange then
		AutoTarget.select(nil)
		return
	end
	local style = Combat.weaponStyle(player:GetAttribute("EstiloArma"))
	local reach = Combat.Range + (style.Reach or 0) - 0.8 + padOf(m)
	local now = os.clock()
	if d > reach then
		if now - lastMoveTo > 0.2 then
			lastMoveTo = now
			local dir = Vector3.new(pos.X - root.Position.X, 0, pos.Z - root.Position.Z).Unit
			hum:MoveTo(pos - dir * (padOf(m) + 2.5))
		end
		return
	end
	if now - lastMoveTo < 1 then
		lastMoveTo = 0
		hum:MoveTo(root.Position) -- (llegó: se para)
	end
	-- mirando a la bestia
	local look = Vector3.new(pos.X, root.Position.Y, pos.Z)
	if (look - root.Position).Magnitude > 0.5 then
		root.CFrame = CFrame.lookAt(root.Position, look)
	end
	if swingFn then
		swingFn()
	end
end

---------------------------------------------------------------------
-- Ficha del objetivo y tus barras
---------------------------------------------------------------------
local function difficultyColor(level: number?): Color3
	local mine = tonumber(player:GetAttribute("Level")) or 1
	if not level then
		return rgb(255, 255, 255)
	end
	local gap = level - mine
	if gap >= 5 then
		return rgb(255, 80, 70)
	elseif gap >= 2 then
		return rgb(255, 160, 60)
	elseif gap >= -2 then
		return rgb(255, 230, 120)
	elseif gap >= -8 then
		return rgb(120, 230, 120)
	end
	return rgb(170, 170, 170)
end

local function bar(parent: Instance, y: number, color: Color3, label: string): (Frame, TextLabel)
	local track = create("Frame", { Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, 19), BackgroundColor3 = rgb(20, 20, 26), BackgroundTransparency = 0.2, BorderSizePixel = 0, Parent = parent })
	create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = track })
	create("UIStroke", { Color = rgb(0, 0, 0), Thickness = 1.5, Transparency = 0.3, Parent = track })
	local fill = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BorderSizePixel = 0, Parent = track })
	create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = fill })
	create("UIGradient", { Color = ColorSequence.new(color:Lerp(rgb(255, 255, 255), 0.25), color), Rotation = 90, Parent = fill })
	local text = create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = label, TextSize = 14, Font = Enum.Font.GothamBold, TextColor3 = rgb(255, 255, 255), TextStrokeTransparency = 0.4, ZIndex = 3, Parent = track })
	return fill, text
end

local function buildUi()
	gui = create("ScreenGui", { Name = "CombateMMO", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 4, Parent = player:WaitForChild("PlayerGui") })
	HudLayout.scaleGui(gui)
	-- Ficha del objetivo (arriba en el centro, bajo la hora y el GPS)
	frame = create("Frame", { Name = "Objetivo", AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(400, 66), BackgroundColor3 = rgb(16, 16, 22), BackgroundTransparency = 0.25, Visible = false, Parent = gui })
	create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = frame })
	create("UIStroke", { Color = rgb(200, 60, 50), Thickness = 1.5, Transparency = 0.2, Parent = frame })
	nameLabel = create("TextLabel", { Position = UDim2.fromOffset(10, 3), Size = UDim2.new(1, -40, 0, 26), BackgroundTransparency = 1, Text = "", TextSize = 19, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = rgb(255, 255, 255), TextStrokeTransparency = 0.5, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame })
	local close = create("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 3), Size = UDim2.fromOffset(26, 22), BackgroundTransparency = 1, Text = "✕", TextSize = 16, Font = Enum.Font.GothamBold, TextColor3 = rgb(220, 220, 230), Parent = frame })
	close.Activated:Connect(function()
		AutoTarget.stop()
		AutoTarget.select(nil)
	end)
	local hpHolder = create("Frame", { Position = UDim2.fromOffset(10, 34), Size = UDim2.new(1, -20, 0, 20), BackgroundTransparency = 1, Parent = frame })
	hpFill, hpText = bar(hpHolder, 0, rgb(210, 40, 40), "")
	-- Tus barras: vida y espíritu (debajo de tu ficha, en plena caza)
	bars = create("Frame", { Name = "VidaEspiritu", Size = UDim2.fromOffset(300, 44), BackgroundTransparency = 1, Visible = false, Parent = gui })
	lifeFill, lifeText = bar(bars, 0, rgb(205, 35, 45), "")
	manaFill, manaText = bar(bars, 23, rgb(40, 110, 230), "")
	HudLayout.onChanged(function(layout)
		local gps = layout.Items.Activity or layout.Items.Gps
		if gps then
			frame.Position = gps.Position + UDim2.fromOffset(0, 4)
		end
		local st = layout.Items.Status
		if st then
			bars.Position = st.Position + UDim2.fromOffset(4, st.Size.Y + 6)
		end
	end)
end

local function paint()
	local m = AutoTarget.current()
	frame.Visible = m ~= nil
	if m then
		local lvl = tonumber(m:GetAttribute("Nivel"))
		local boss = m:GetAttribute("Boss") == true
		local champ = m:GetAttribute("Campeon") == true
		local name = m:GetAttribute("NombreBestia") or m:GetAttribute("BeastName") or m.Name
		nameLabel.Text = ("%s%s%s"):format(if boss then "👑 " elseif champ then "★ " else "", tostring(name), if lvl then ("  nv. %d"):format(lvl) else "")
		nameLabel.TextColor3 = if boss then rgb(255, 120, 90) else difficultyColor(lvl)
		local hp = tonumber(m:GetAttribute("Hp")) or 1
		local max = math.max(1, tonumber(m:GetAttribute("MaxHp")) or tonumber(m:GetAttribute("EnemyMaxHealth")) or hp)
		hpFill.Size = UDim2.fromScale(math.clamp(hp / max, 0, 1), 1)
		hpText.Text = ("%d / %d"):format(math.max(0, math.floor(hp)), math.floor(max))
	end
	-- tus barras: con una bestia cerca (o un objetivo)
	local hum, root = body()
	local show = m ~= nil or (root ~= nil and nearest(root.Position, AutoTarget.FightNear, nil) ~= nil)
	bars.Visible = show and hum ~= nil
	if show and hum then
		lifeFill.Size = UDim2.fromScale(math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1), 1)
		lifeText.Text = ("❤ %d / %d"):format(math.floor(hum.Health), math.floor(hum.MaxHealth))
		local mana = tonumber(player:GetAttribute("Espiritu")) or 0
		local manaMax = math.max(1, tonumber(player:GetAttribute("EspirituMax")) or 100)
		manaFill.Size = UDim2.fromScale(math.clamp(mana / manaMax, 0, 1), 1)
		manaText.Text = ("✦ Espíritu %d / %d"):format(math.floor(mana), math.floor(manaMax))
	end
end

-- Tocar (o pulsar) una bestia la elige como objetivo
local function pickAt(screen: Vector2)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local ray = camera:ViewportPointToRay(screen.X, screen.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 400, params)
	local node: Instance? = hit and hit.Instance
	while node and node ~= workspace do
		if node:IsA("Model") and CollectionService:HasTag(node, "Bestia") then
			AutoTarget.select(node :: Model)
			return
		end
		node = node.Parent
	end
end

function AutoTarget.init()
	buildUi()
	RunService.RenderStepped:Connect(function()
		local ok, err = pcall(step)
		if not ok then
			active = false
			warn("[AutoTarget] " .. tostring(err))
		end
	end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 0.15 then
			acc = 0
			pcall(paint)
			if target and not alive(target) and not active then
				AutoTarget.select(nil)
			end
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			pickAt(Vector2.new(input.Position.X, input.Position.Y))
		end
	end)
	player.CharacterAdded:Connect(function()
		active = false
		AutoTarget.select(nil)
	end)
end

return AutoTarget
