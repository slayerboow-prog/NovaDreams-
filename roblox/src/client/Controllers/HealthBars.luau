-- HealthBars (cliente): lo que se VE del daño por puntos (lo decide el servidor: DamageService).
--   * Barra de vida encima de cada enemigo de TU combate de misión (etiqueta MissionEnemy, atributos
--     EnemyHealth / EnemyMaxHealth) y de los rivales hostiles con los que peleas (etiqueta HostileNpc,
--     su Humanoid). Solo la ves tú (el dueño del combate) y solo si le has hecho daño hace poco o
--     está cerca (shared/EnemyStats.showBar).
--   * Números de daño flotantes (remoto "Damage"): blancos los normales, amarillos en la cabeza;
--     si llegan muy seguidos (una ráfaga, la pistola de agua) se agrupan en uno que va sumando.
--   * Un destello breve en el enemigo al recibir daño.
--   * Tu vida (la barra ❤️ del HUD baja sola con cada impacto): al recibir daño, un borde rojo suave
--     en la pantalla.
-- Nada de esto aplica daño: el remoto "Damage" solo llega del servidor.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local EnemyStats = require(ReplicatedStorage.Shared.EnemyStats)
local MissionCombat = require(ReplicatedStorage.Shared.MissionCombat)
local Theme = require(script.Parent.Parent.UI.Theme)

local HealthBars = {}

local player = Players.LocalPlayer
local create = Theme.create
local rgb = Color3.fromRGB

local WHITE = rgb(255, 255, 255)
local YELLOW = rgb(255, 220, 60)
local IMMUNE = rgb(170, 190, 210)
local HOSTILE_TAG = "HostileNpc"

type Bar = { Gui: BillboardGui, Fill: Frame, Model: Model, LastHit: number?, Shown: number }
local bars: { [Model]: Bar } = {}
local numbers: { [Model]: { Group: { Amount: number, At: number, Head: boolean }, Label: TextLabel, Gui: BillboardGui } } = {}

local function playerGui(): Instance?
	return player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 10)
end

local function anchorOf(model: Model): BasePart?
	local part = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	return if part and part:IsA("BasePart") then part else nil
end

-- Vida de un enemigo (atributos de misión) o de un rival (su Humanoid)
local function healthOf(model: Model): (number, number)
	local max = model:GetAttribute("EnemyMaxHealth")
	if type(max) == "number" then
		local health = model:GetAttribute("EnemyHealth")
		return if type(health) == "number" then health else max, max
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		return humanoid.Health, humanoid.MaxHealth
	end
	return 0, 0
end

-- ¿Es de mi combate?
local function mine(model: Model): boolean
	if model:GetAttribute(MissionCombat.ATTR) ~= nil then
		return model:GetAttribute("Owner") == player.UserId
	end
	return model:GetAttribute("CombatOwner") == player.UserId
end

local function barOf(model: Model): Bar?
	local existing = bars[model]
	if existing then
		return existing
	end
	local anchor = anchorOf(model)
	local parent = playerGui()
	if not anchor or not parent then
		return nil
	end
	local scale = 1
	pcall(function()
		scale = math.clamp(model:GetExtentsSize().Y / 5, 0.6, 3)
	end)
	local gui = create("BillboardGui", {
		Name = "BarraVida",
		Adornee = anchor,
		Size = UDim2.fromOffset(84, 12),
		StudsOffset = Vector3.new(0, 1.6 * scale + 0.6, 0),
		AlwaysOnTop = true,
		Enabled = false,
		ResetOnSpawn = false,
		Parent = parent,
	})
	local back = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = rgb(25, 25, 30),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Parent = gui,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), create("UIStroke", { Color = rgb(0, 0, 0), Transparency = 0.4, Thickness = 1 }) })
	local fill = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = rgb(90, 220, 110),
		BorderSizePixel = 0,
		Parent = back,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local bar: Bar = { Gui = gui, Fill = fill, Model = model, LastHit = nil, Shown = -1 }
	bars[model] = bar
	return bar
end

local function dropBar(model: Model)
	local bar = bars[model]
	if bar then
		bars[model] = nil
		bar.Gui:Destroy()
	end
end

-- Pinta la barra (verde -> amarillo -> rojo)
local function paint(bar: Bar, health: number, max: number)
	local f = if max > 0 then math.clamp(health / max, 0, 1) else 0
	if math.abs(f - bar.Shown) < 0.001 then
		return
	end
	bar.Shown = f
	local color = if f > 0.5 then rgb(90, 220, 110):Lerp(rgb(250, 210, 60), (1 - f) * 2) else rgb(250, 210, 60):Lerp(rgb(235, 70, 60), (0.5 - f) * 2)
	bar.Fill.BackgroundColor3 = color
	TweenService:Create(bar.Fill, TweenInfo.new(0.15), { Size = UDim2.fromScale(f, 1) }):Play()
end

-- Destello breve en el enemigo
local function flash(model: Model, color: Color3?)
	local highlight = create("Highlight", {
		FillColor = color or WHITE,
		FillTransparency = 0.25,
		OutlineTransparency = 1,
		DepthMode = Enum.HighlightDepthMode.Occluded,
		Adornee = model,
		Parent = model,
	})
	TweenService:Create(highlight, TweenInfo.new(0.18), { FillTransparency = 1 }):Play()
	task.delay(0.22, function()
		highlight:Destroy()
	end)
end

-- Número de daño flotante (se agrupa si llegan muy seguidos)
local function popNumber(model: Model, amount: number, head: boolean, immune: boolean)
	local anchor = anchorOf(model)
	local parent = playerGui()
	if not anchor or not parent then
		return
	end
	local now = os.clock()
	local current = numbers[model]
	if current and current.Label.Parent and not immune then
		local group, grouped = EnemyStats.group(current.Group, amount, head, now)
		if grouped then
			current.Label.Text = tostring(group.Amount)
			current.Label.TextColor3 = if group.Head then YELLOW else WHITE
			local scale = current.Label:FindFirstChildOfClass("UIScale")
			if scale then
				scale.Scale = 1.35
				TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = 1 }):Play()
			end
			return
		end
	end
	local gui = create("BillboardGui", {
		Name = "NumeroDano",
		Adornee = anchor,
		Size = UDim2.fromOffset(110, 40),
		StudsOffset = Vector3.new(math.random(-8, 8) / 10, 2.4, 0),
		AlwaysOnTop = true,
		ResetOnSpawn = false,
		Parent = parent,
	})
	local label = Theme.label({
		Size = UDim2.fromScale(1, 1),
		FontFace = Theme.TitleFace,
		Text = if immune then "Inmune" else tostring(amount),
		TextSize = if head then 30 elseif immune then 18 else 24,
		TextColor3 = if immune then IMMUNE elseif head then YELLOW else WHITE,
		TextStrokeTransparency = 0.15,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = gui,
	})
	local scale = create("UIScale", { Scale = 1.4, Parent = label })
	TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	local entry = { Group = { Amount = amount, At = now, Head = head }, Label = label, Gui = gui }
	if not immune then
		numbers[model] = entry
	end
	task.spawn(function()
		-- Sube y se desvanece (si le siguen llegando golpes, espera a que paren)
		local waited = 0
		while waited < 3 and os.clock() - entry.Group.At < EnemyStats.GroupSeconds do
			waited += task.wait(0.05)
		end
		TweenService:Create(gui, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffset = gui.StudsOffset + Vector3.new(0, 1.6, 0) }):Play()
		TweenService:Create(label, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		task.wait(0.75)
		if numbers[model] == entry then
			numbers[model] = nil
		end
		gui:Destroy()
	end)
end

local function onDamage(data: { [string]: any })
	local model = data.Target
	if typeof(model) ~= "Instance" or not model:IsA("Model") or not model.Parent then
		return
	end
	local amount = tonumber(data.Amount) or 0
	local immune = data.Immune == true
	if amount > 0 or immune then
		popNumber(model, math.floor(amount + 0.5), data.Zone == "Head", immune)
	end
	if amount > 0 then
		flash(model, if data.Zone == "Head" then YELLOW else nil)
	end
	local bar = barOf(model)
	if bar then
		bar.LastHit = os.clock()
		local health, max = tonumber(data.Health), tonumber(data.Max)
		if not health or not max then
			health, max = healthOf(model)
		end
		paint(bar, health :: number, max :: number)
		if data.Down then
			bar.Gui.Enabled = false
		end
	end
end

-- Cada poco: qué barras se ven (dañado hace poco o cerca) y su vida
local function refresh()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local me = root and root.Position
	local list: { Instance } = {}
	for _, tag in { MissionCombat.ATTR, HOSTILE_TAG } do
		for _, model in CollectionService:GetTagged(tag) do
			table.insert(list, model)
		end
	end
	local seen: { [Model]: boolean } = {}
	for _, item in list do
		if item:IsA("Model") and item.Parent and mine(item) and not item:GetAttribute("EnemyDown") then
			local model = item :: Model
			local health, max = healthOf(model)
			local anchor = anchorOf(model)
			local distance = if me and anchor then (anchor.Position - me).Magnitude else math.huge
			local bar = bars[model]
			local since = if bar and bar.LastHit then os.clock() - bar.LastHit else nil
			if EnemyStats.showBar(distance, since, health, max) then
				bar = bar or barOf(model)
				if bar then
					seen[model] = true
					paint(bar, health, max)
					bar.Gui.Enabled = true
				end
			elseif bar then
				seen[model] = true
				bar.Gui.Enabled = false
			end
		end
	end
	for model in bars do
		if not seen[model] then
			dropBar(model)
		end
	end
end

---------------------------------------------------------------------
-- Tu vida: borde rojo suave al recibir daño
---------------------------------------------------------------------
local vignette: Frame? = nil
local function buildVignette()
	local parent = playerGui()
	if not parent then
		return
	end
	local gui = create("ScreenGui", { Name = "DanoRecibido", IgnoreGuiInset = true, DisplayOrder = 6, ResetOnSpawn = false, Parent = parent })
	local frame = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = gui })
	-- Cuatro bordes con degradado (rojo fuera, transparente hacia dentro)
	local function edge(size: UDim2, position: UDim2, rotation: number)
		create("Frame", {
			Size = size,
			Position = position,
			BackgroundColor3 = rgb(220, 20, 30),
			BorderSizePixel = 0,
			Parent = frame,
		}, { create("UIGradient", { Rotation = rotation, Transparency = NumberSequence.new(0, 1) }) })
	end
	edge(UDim2.new(1, 0, 0.16, 0), UDim2.fromScale(0, 0), 90)
	edge(UDim2.new(1, 0, 0.16, 0), UDim2.fromScale(0, 0.84), 270)
	edge(UDim2.new(0.12, 0, 1, 0), UDim2.fromScale(0, 0), 0)
	edge(UDim2.new(0.12, 0, 1, 0), UDim2.fromScale(0.88, 0), 180)
	frame.Visible = false
	vignette = frame
end

local hurtId = 0
local function hurtFlash(strength: number)
	local frame = vignette
	if not frame then
		return
	end
	hurtId += 1
	local id = hurtId
	frame.Visible = true
	local alpha = math.clamp(strength, 0.25, 1)
	for _, child in frame:GetChildren() do
		if child:IsA("Frame") then
			child.BackgroundTransparency = 1 - 0.55 * alpha
			TweenService:Create(child, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
		end
	end
	task.delay(0.65, function()
		if hurtId == id then
			frame.Visible = false
		end
	end)
end

local function watchHumanoid(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid then
		return
	end
	local last = humanoid.Health
	humanoid.HealthChanged:Connect(function(health: number)
		if health < last - 0.5 and health > 0 then
			hurtFlash((last - health) / math.max(humanoid.MaxHealth, 1) * 4)
		end
		last = health
	end)
end

function HealthBars.init()
	buildVignette()
	if player.Character then
		task.spawn(watchHumanoid, player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		task.spawn(watchHumanoid, character)
	end)
	task.spawn(function()
		local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Damage", 30) :: RemoteEvent?
		if not remote then
			return
		end
		remote.OnClientEvent:Connect(function(kind: string, data: any)
			if kind == "Damage" and type(data) == "table" then
				local ok, err = pcall(onDamage, data)
				if not ok then
					warn("[Daño] " .. tostring(err))
				end
			end
		end)
	end)
	task.spawn(function()
		while true do
			task.wait(0.2)
			local ok, err = pcall(refresh)
			if not ok then
				warn("[Barras de vida] " .. tostring(err))
				task.wait(2)
			end
		end
	end)
end

return HealthBars
