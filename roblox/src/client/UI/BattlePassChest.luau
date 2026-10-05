-- BattlePassChest: al reclamar una recompensa del pase sale un cofre en el centro de la pantalla: cae,
-- tiembla, se abre con un destello y enseña lo que has recibido (icono, nombre, rareza y pista).
--
--   BattlePassChest.show(rewards)   rewards = { { Name, Icon, Rarity?, Track?, Level?, Type?, Amount? } }
--
-- El cofre es el que eligió Sebastián (123778443128832): World/InteriorProps deja una copia LIMPIA (solo
-- mallas, sin sus scripts) en ReplicatedStorage.ModelosPremio.CofreRecompensa. Si aún no ha cargado, se
-- usa uno de madera con herrajes dorados hecho aquí (ese sí abre la tapa).
-- Si se reclama otra cosa con el cofre abierto, se suma a la lista (no se apilan ventanas).
-- Se cierra con «¡GENIAL!», tocando fuera (cuando ya se ha abierto) o sola a los 8 s.
-- Solo se mueve mientras está en pantalla (una conexión a RenderStepped que se quita al cerrar).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)
local View = require(script.Parent.BattlePassView)

local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

local BattlePassChest = {}

local GOLD = View.Colors.Premium
local MAX_LINES = 5 -- recompensas que se ven en la lista (el resto: «y N más»)
local AUTO_CLOSE = 8 -- segundos
local RARITY_COLOR = {
	Comun = rgb(200, 210, 225),
	Rara = rgb(90, 170, 255),
	Epica = rgb(190, 110, 255),
	Legendaria = rgb(255, 196, 64),
}

local current: { [string]: any }? = nil -- la ventana abierta (o nil)

local function sound(pitch: number, volume: number?)
	pcall(function()
		local SoundFx = require(script.Parent.Parent.Controllers.SoundFx :: any)
		SoundFx.play("Aviso", volume or 0.45, pitch)
	end)
end

-- Cofre de reserva: madera, bandas y cierre dorados, y una tapa (Lid) que gira sobre la bisagra de atrás
local function fallbackChest(): Model
	local m = Instance.new("Model")
	m.Name = "Cofre"
	local wood, dark, gold = rgb(122, 74, 40), rgb(84, 50, 26), rgb(230, 182, 70)
	local function part(name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material, parent: Instance?): BasePart
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = mat
		p.Anchored = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = parent or m
		return p
	end
	local body = part("Caja", Vector3.new(3, 1.6, 2), CFrame.new(0, 0.8, 0), wood, Enum.Material.WoodPlanks)
	m.PrimaryPart = body
	for _, x in { -1.2, 1.2 } do
		part("Banda", Vector3.new(0.18, 1.62, 2.04), CFrame.new(x, 0.8, 0), gold, Enum.Material.Metal)
	end
	part("Zocalo", Vector3.new(3.05, 0.14, 2.05), CFrame.new(0, 0.07, 0), dark, Enum.Material.Wood)
	local lid = Instance.new("Model")
	lid.Name = "Lid"
	lid.Parent = m
	local top = part("Tapa", Vector3.new(1.4, 3, 2), CFrame.new(0, 1.6, 0) * CFrame.Angles(0, 0, math.pi / 2), wood, Enum.Material.WoodPlanks, lid)
	top.Shape = Enum.PartType.Cylinder
	part("TapaFondo", Vector3.new(3, 0.1, 2), CFrame.new(0, 1.62, 0), dark, Enum.Material.Wood, lid)
	for _, x in { -1.2, 1.2 } do
		local band = part("Banda", Vector3.new(1.44, 0.18, 2.04), CFrame.new(x, 1.6, 0) * CFrame.Angles(0, 0, math.pi / 2), gold, Enum.Material.Metal, lid)
		band.Shape = Enum.PartType.Cylinder
	end
	part("Cierre", Vector3.new(0.45, 0.55, 0.12), CFrame.new(0, 1.5, -1.05), gold, Enum.Material.Metal, lid)
	local glow = part("Brillo", Vector3.new(2.7, 0.1, 1.7), CFrame.new(0, 1.55, 0), rgb(255, 220, 120), Enum.Material.Neon)
	glow.Transparency = 1
	-- (bisagra: la tapa gira alrededor del borde de atrás)
	lid:SetAttribute("Hinge", Vector3.new(0, 1.6, 1))
	return m
end

local function chestModel(): Model
	local folder = ReplicatedStorage:FindFirstChild("ModelosPremio")
	local source = folder and folder:FindFirstChild("CofreRecompensa")
	if source and source:IsA("Model") then
		local ok, copy = pcall(function()
			return source:Clone()
		end)
		if ok and copy then
			return copy
		end
	end
	return fallbackChest()
end

local function rewardLine(parent: Instance, reward: { [string]: any }, order: number, textSize: number): Frame
	local rarityColor = RARITY_COLOR[tostring(reward.Rarity)] or C.Text
	local line = create("Frame", {
		Name = "Linea",
		Size = UDim2.new(1, 0, 0, textSize * 2.6),
		BackgroundColor3 = rgb(16, 26, 54),
		BackgroundTransparency = 0.15,
		LayoutOrder = order,
		Parent = parent,
	}, { Theme.corner(10), create("UIStroke", { Color = rarityColor, Thickness = 1.5, Transparency = 0.25 }) })
	local scale = create("UIScale", { Scale = 0.2, Parent = line })
	Theme.label({
		Name = "Icono",
		Size = UDim2.new(0, textSize * 2.6, 1, 0),
		Text = tostring(reward.Icon or "🎁"),
		TextSize = textSize * 1.6,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = line,
	})
	local amount = View.amountText(reward)
	Theme.label({
		Name = "Nombre",
		Position = UDim2.new(0, textSize * 2.6, 0, 2),
		Size = UDim2.new(1, -textSize * 2.8, 0.6, 0),
		Text = tostring(reward.Name or "Recompensa") .. (if amount ~= "" then "  ·  " .. amount else ""),
		Font = Theme.FontBold,
		TextSize = textSize,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = line,
	})
	local tags = {}
	local tag = View.rarityTag(reward)
	if tag ~= "" then
		table.insert(tags, tag)
	end
	if reward.Track == "Premium" then
		table.insert(tags, "⭐ PREMIUM")
	elseif reward.Track == "Free" then
		table.insert(tags, "GRATIS")
	end
	if tonumber(reward.Level) then
		table.insert(tags, "NV. " .. View.levelText(tonumber(reward.Level) :: number))
	end
	Theme.label({
		Name = "Etiquetas",
		Position = UDim2.new(0, textSize * 2.6, 0.58, 0),
		Size = UDim2.new(1, -textSize * 2.8, 0.38, 0),
		Text = table.concat(tags, "  ·  "),
		TextSize = math.floor(textSize * 0.72),
		TextColor3 = rarityColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = line,
	})
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	return line
end

local function refreshList(w: { [string]: any })
	for _, child in w.List:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local rewards = w.Rewards
	local n = #rewards
	w.Title.Text = if n == 1 then "¡RECOMPENSA RECIBIDA!" else ("¡%d RECOMPENSAS RECIBIDAS!"):format(n)
	for i = 1, math.min(n, MAX_LINES) do
		rewardLine(w.List, rewards[i], i, w.TextSize)
	end
	if n > MAX_LINES then
		Theme.label({
			Name = "Mas",
			Size = UDim2.new(1, 0, 0, w.TextSize * 1.4),
			Text = ("…y %d más"):format(n - MAX_LINES),
			TextSize = w.TextSize,
			TextColor3 = C.Muted,
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = MAX_LINES + 1,
			Parent = w.List,
		})
	end
end

local function close()
	local w = current
	if not w then
		return
	end
	current = nil
	for _, c in w.Connections do
		c:Disconnect()
	end
	local gui = w.Gui
	TweenService:Create(w.Backdrop, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(w.Scale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.6 }):Play()
	task.delay(0.22, function()
		gui:Destroy()
	end)
end
BattlePassChest.close = close

function BattlePassChest.isOpen(): boolean
	return current ~= nil
end

function BattlePassChest.show(rewards: { { [string]: any } })
	if type(rewards) ~= "table" or #rewards == 0 then
		return
	end
	if current then
		-- (otra recompensa con el cofre abierto: se suma a la lista)
		for _, r in rewards do
			table.insert(current.Rewards, r)
		end
		if current.Opened then
			refreshList(current)
		end
		current.Shown = os.clock()
		return
	end
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return
	end
	local touch = Theme.isTouch()
	local textSize = if touch then 20 else 17
	local w: { [string]: any } = { Rewards = table.clone(rewards), Connections = {}, TextSize = textSize, Opened = false, Shown = os.clock() }
	current = w

	local gui = create("ScreenGui", {
		Name = "BattlePassChest",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 60,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	})
	w.Gui = gui
	local backdrop = create("TextButton", {
		Name = "Fondo",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = rgb(4, 8, 20),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = gui,
	})
	w.Backdrop = backdrop
	TweenService:Create(backdrop, TweenInfo.new(0.25), { BackgroundTransparency = 0.35 }):Play()

	local card = create("Frame", {
		Name = "Tarjeta",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(if touch then 0.92 else 0, if touch then 0 else 440, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = rgb(10, 18, 42),
		Parent = gui,
	}, {
		Theme.corner(16),
		create("UIStroke", { Color = GOLD, Thickness = 2, Transparency = 0.1 }),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(36, 54, 110), rgb(10, 16, 38)) }),
		create("UISizeConstraint", { MaxSize = Vector2.new(480, math.huge) }),
		create("UIListLayout", { Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
		Theme.padding(14),
	})
	w.Scale = create("UIScale", { Scale = 0.6, Parent = card })
	TweenService:Create(w.Scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	w.Title = Theme.label({
		Name = "Titulo",
		Size = UDim2.new(1, 0, 0, textSize * 1.8),
		Text = "¡ABRIENDO COFRE…!",
		FontFace = Theme.TitleFace,
		TextSize = math.floor(textSize * 1.45),
		TextColor3 = GOLD,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 1,
		Parent = card,
	})

	-- El cofre en 3D, con un destello detrás
	local stage = create("Frame", {
		Name = "Escena",
		Size = UDim2.new(1, 0, 0, if touch then 190 else 210),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		LayoutOrder = 2,
		Parent = card,
	})
	local burst = create("Frame", {
		Name = "Destello",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.55),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = rgb(255, 214, 110),
		BackgroundTransparency = 1,
		Parent = stage,
	}, { Theme.corner(999) })
	local rays = {}
	for i = 1, 8 do
		local ray = create("Frame", {
			Name = "Rayo",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.55),
			Size = UDim2.fromOffset(16, 260),
			Rotation = i * 22.5,
			BackgroundColor3 = rgb(255, 230, 150),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = stage,
		}, { create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) }) })
		table.insert(rays, ray)
	end
	local viewport = create("ViewportFrame", {
		Name = "Cofre",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Ambient = rgb(170, 160, 150),
		LightColor = rgb(255, 240, 210),
		LightDirection = Vector3.new(-0.6, -1, -0.8),
		Parent = stage,
	})
	local camera = create("Camera", { FieldOfView = 35, Parent = viewport })
	viewport.CurrentCamera = camera
	local world = create("WorldModel", { Parent = viewport })
	local chest = chestModel()
	for _, d in chest:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	chest.Parent = world
	local boxCf, boxSize = chest:GetBoundingBox()
	-- (se centra en el origen, apoyado en el suelo)
	local base = chest:GetPivot()
	local offset = base.Position - boxCf.Position + Vector3.new(0, boxSize.Y / 2, 0)
	local rest = CFrame.new(offset) * base.Rotation
	local radius = math.max(boxSize.Magnitude * 0.5, 1)
	local dist = radius / math.tan(math.rad(camera.FieldOfView / 2)) * 1.15
	camera.CFrame = CFrame.lookAt(Vector3.new(dist * 0.55, boxSize.Y * 0.5 + dist * 0.35, -dist * 0.8), Vector3.new(0, boxSize.Y * 0.45, 0))
	local lid = chest:FindFirstChild("Lid")
	local lidStart = if lid and lid:IsA("Model") then lid:GetPivot() else nil
	local hinge = if lid then lid:GetAttribute("Hinge") else nil
	local glow = chest:FindFirstChild("Brillo", true)

	w.List = create("Frame", {
		Name = "Lista",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Parent = card,
	}, { create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })

	local ok = Theme.button({
		Name = "Genial",
		Size = UDim2.new(0.7, 0, 0, if touch then 52 else 42),
		Text = "¡GENIAL!",
		TextSize = textSize,
		BackgroundColor3 = GOLD,
		TextColor3 = rgb(40, 28, 6),
		Visible = false,
		LayoutOrder = 4,
		Parent = card,
	})
	table.insert(w.Connections, ok.Activated:Connect(close))
	table.insert(w.Connections, backdrop.Activated:Connect(function()
		if w.Opened then
			close()
		end
	end))

	-- Animación: cae (0–0,45 s), tiembla (0,45–1,25 s), se abre (1,25 s) y destello
	local t0 = os.clock()
	sound(0.8, 0.35)
	local shakeSounds = 0
	table.insert(w.Connections, RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local cf
		if t < 0.45 then
			local k = t / 0.45
			local y = (1 - k) ^ 2 * boxSize.Y * 3
			cf = CFrame.new(0, y, 0) * rest
		elseif t < 1.25 then
			local k = (t - 0.45) / 0.8
			local wobble = math.sin(k * math.pi * 8) * 0.12 * (1 - k * 0.3)
			cf = rest * CFrame.Angles(0, 0, wobble)
			local beat = math.floor(k * 4)
			if beat > shakeSounds then
				shakeSounds = beat
				sound(0.9 + beat * 0.1, 0.25)
			end
		else
			local k = math.min((t - 1.25) / 0.25, 1)
			cf = rest * CFrame.new(0, math.sin(k * math.pi) * 0.3, 0)
			if not w.Opened then
				w.Opened = true
				w.OpenedAt = os.clock()
				sound(1.6, 0.5)
				task.delay(0.12, sound, 2.0, 0.45)
				w.Title.Text = ""
				refreshList(w)
				ok.Visible = true
				burst.BackgroundTransparency = 0.2
				TweenService:Create(burst, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(380, 380), BackgroundTransparency = 1 }):Play()
				for _, ray in rays do
					TweenService:Create(ray, TweenInfo.new(0.4), { BackgroundTransparency = 0.35 }):Play()
				end
				if glow and glow:IsA("BasePart") then
					glow.Transparency = 0.1
				end
			end
		end
		chest:PivotTo(cf)
		-- Tapa: se abre hacia atrás sobre la bisagra (solo el cofre de reserva la tiene)
		if lid and lidStart and typeof(hinge) == "Vector3" then
			local open = if t > 1.25 then math.min((t - 1.25) / 0.35, 1) else 0
			local h = CFrame.new(hinge)
			local relative = h * CFrame.Angles(-math.rad(105) * (1 - (1 - open) ^ 3), 0, 0) * h:Inverse()
			;(lid :: Model):PivotTo(cf * base:Inverse() * relative * lidStart)
		end
		-- Rayos girando detrás cuando ya está abierto
		if w.Opened then
			for i, ray in rays do
				ray.Rotation = i * 22.5 + (os.clock() - w.OpenedAt) * 25
			end
		end
		if w.Opened and os.clock() - w.Shown > AUTO_CLOSE then
			close()
		end
	end))
end

return BattlePassChest
