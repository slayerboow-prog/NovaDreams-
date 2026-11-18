-- HunterSkillsUI (cliente): los botones de las HABILIDADES DE CAZADOR (shared/HunterSkills;
-- Services/HunterSkillService). Se ven siempre.
--   * Una columna de botones redondos en el borde izquierdo, a media altura (lejos del joystick, de la mochila
--     y de los botones de la derecha). Cada uno: su icono, su tecla en el ordenador (Z, X, C, V), el nivel que
--     pide si aún no la tienes y la cuenta atrás de su espera.
--   * Pulsar (o su tecla) pide «Use» al servidor, que lo comprueba todo. Con la Embestida, además, el personaje
--     sale lanzado hacia delante (lo mueve su dueño: el cliente).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local HunterSkills = require(ReplicatedStorage.Shared.HunterSkills)
local Theme = require(script.Parent.Parent.UI.Theme)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local HudArt = require(script.Parent.Parent.UI.HudArt)

local HunterSkillsUI = {}

local player = Players.LocalPlayer
local create = Theme.create
local rgb = Color3.fromRGB

local gui: ScreenGui
local remote: RemoteEvent
local buttons: { [string]: { Button: TextButton, Cover: Frame, Count: TextLabel, Lock: TextLabel } } = {}
local readyAt: { [string]: number } = {}
local total: { [string]: number } = {}

local SHORT = { TajoCircular = "Tajo", Embestida = "Embestida", Furia = "Furia", GolpeSismico = "Sísmico", TormentaAcero = "Tormenta", Coraza = "Coraza" }

local function level(): number
	if player:GetAttribute("HabilidadesTodas") == true then
		return 999 -- (modo pruebas: todas desbloqueadas)
	end
	return tonumber(player:GetAttribute("NivelCazador")) or 1
end

-- Lo que te ha enseñado la Academia (atributo HabilidadesSabidas: shared/HunterSkills.knownFromText)
local function known(): { [string]: any }?
	return HunterSkills.knownFromText(player:GetAttribute("HabilidadesSabidas"))
end

local function onPlanet(): boolean
	return true -- (salen siempre: en Valmar pegan a enemigos de misión y alienígenas)
end

local function busy(): boolean
	return player:GetAttribute("InDialogue") == true or player:GetAttribute("InCinematic") == true
end

local function use(sk: { [string]: any })
	if not onPlanet() or busy() then
		return
	end
	if not HunterSkills.unlocked(sk, level(), if level() >= 999 then nil else known()) or (readyAt[sk.Id] or 0) > os.clock() then
		return
	end
	-- (hacia tu objetivo: te giras a él antes de soltarla)
	local okT, AutoTarget = pcall(function()
		return require(script.Parent.AutoTarget) :: any
	end)
	local target = okT and AutoTarget.current() or nil
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if target and root and target.PrimaryPart then
		local p = target.PrimaryPart.Position
		root.CFrame = CFrame.lookAt(root.Position, Vector3.new(p.X, root.Position.Y, p.Z))
	end
	remote:FireServer("Use", sk.Id)
end

local function dash(sk: { [string]: any })
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local look = root.CFrame.LookVector
	local dir = Vector3.new(look.X, 0, look.Z)
	if dir.Magnitude < 0.01 then
		return
	end
	local att = Instance.new("Attachment")
	att.Parent = root
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att
	lv.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	lv.MaxAxesForce = Vector3.new(1e5, 0, 1e5)
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.VectorVelocity = dir.Unit * (sk.Distance / 0.28)
	lv.Parent = root
	task.delay(0.28, function()
		lv:Destroy()
		att:Destroy()
	end)
end

local function refresh()
	-- (en el móvil van en el arco del Atacar: TouchLayout; en las escenas se esconde como el resto del HUD)
	local show = onPlanet() and not Theme.isTouch() and player:GetAttribute("InCinematic") ~= true
	gui.Enabled = show
	if not show then
		return
	end
	local lvl = level()
	local now = os.clock()
	for _, sk in HunterSkills.List do
		local b = buttons[sk.Id]
		local unlocked = HunterSkills.unlocked(sk, lvl, if lvl >= 999 then nil else known())
		local left = math.max(0, (readyAt[sk.Id] or 0) - now)
		b.Lock.Visible = not unlocked
		b.Cover.Visible = unlocked and left > 0
		b.Count.Visible = unlocked and left > 0
		if left > 0 then
			b.Count.Text = tostring(math.ceil(left))
			b.Cover.Size = UDim2.fromScale(1, math.clamp(left / (total[sk.Id] or sk.Cooldown), 0, 1))
		end
		local art = b.Button:FindFirstChild("Arte") :: ImageLabel?
		if art then
			art.ImageColor3 = if not unlocked then rgb(90, 90, 100) elseif left > 0 then rgb(150, 150, 170) else rgb(255, 255, 255)
		else
			b.Button.BackgroundColor3 = if not unlocked then rgb(40, 42, 50) elseif left > 0 then rgb(34, 44, 66) else rgb(50, 110, 190)
			b.Button.TextTransparency = if unlocked then 0 else 0.6
		end
	end
end

function HunterSkillsUI.init()
	remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("HunterSkill") :: RemoteEvent
	gui = create("ScreenGui", { Name = "HunterSkillsGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 3, Enabled = false, Parent = player:WaitForChild("PlayerGui") })
	local touch = Theme.isTouch()
	local size = if touch then 46 else 44
	-- (dos filas de tres, justo encima del joystick: debajo de la ficha del jugador, sin taparla; comprobado en
	-- Studio con la pantalla del móvil, 15-11-2026)
	-- (en el ordenador, 18-11-2026: una BARRA de seis casillas abajo en el centro, encima de la barra rápida, como
	-- en la imagen del dueño; las pociones van a su izquierda: UI/MmoHud)
	if not touch then
		size = 52
	end
	local perRow = if touch then 3 else #HunterSkills.List
	local rows = math.ceil(#HunterSkills.List / perRow)
	local column = create("Frame", { Name = "Skills", AnchorPoint = if touch then Vector2.new(0, 1) else Vector2.new(0.5, 1), Position = if touch then UDim2.new(0, 10, 1, -112) else UDim2.new(0.5, 0, 1, -112), Size = UDim2.fromOffset(perRow * (size + 6), rows * (size + 6)), BackgroundTransparency = 1, Parent = gui })
	create("UIGridLayout", { CellSize = UDim2.fromOffset(size, size), CellPadding = UDim2.fromOffset(6, 6), FillDirection = Enum.FillDirection.Horizontal, FillDirectionMaxCells = perRow, SortOrder = Enum.SortOrder.LayoutOrder, Parent = column })
	for i, sk in HunterSkills.List do
		local btn = create("TextButton", { Name = sk.Id, Size = UDim2.fromOffset(size, size), BackgroundColor3 = rgb(50, 110, 190), BackgroundTransparency = 0.15, Text = sk.Icon, TextSize = if touch then 24 else 22, TextColor3 = rgb(255, 255, 255), AutoButtonColor = true, LayoutOrder = i, ClipsDescendants = true, Parent = column })
		create("UICorner", { CornerRadius = if touch then UDim.new(1, 0) else UDim.new(0, 10), Parent = btn })
		create("UIStroke", { Color = if touch then rgb(150, 200, 255) else rgb(120, 170, 240), Thickness = if touch then 1.5 else 2, Transparency = 0.3, Parent = btn })
		-- (18-11-2026) el icono PINTADO (scripts/hud/gen_skills.py) con su marco dorado; si aún no está subido, el emoji
		if sk.Art and HudArt.has(sk.Art) then
			btn.Text = ""
			btn.BackgroundTransparency = 1
			local art = HudArt.image(btn, sk.Art, { Name = "Arte", ZIndex = 1 })
			if art then
				create("UICorner", { CornerRadius = if touch then UDim.new(1, 0) else UDim.new(0, 10), Parent = art })
			end
			HudArt.image(btn, if touch then "marco_hab_redondo" else "marco_hab", { Name = "Marco", ZIndex = 4 })
			local st = btn:FindFirstChildOfClass("UIStroke")
			if st then
				st.Enabled = false
			end
		end
		local cover = create("Frame", { Name = "Espera", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(0, 0, 0), BackgroundTransparency = 0.45, BorderSizePixel = 0, Visible = false, Parent = btn })
		create("UICorner", { CornerRadius = if touch then UDim.new(1, 0) else UDim.new(0, 10), Parent = cover })
		cover.ZIndex = 2
		local count = create("TextLabel", { Name = "Cuenta", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", TextSize = 22, Font = Enum.Font.GothamBlack, TextColor3 = rgb(255, 255, 255), TextStrokeTransparency = 0.2, Visible = false, ZIndex = 5, Parent = btn })
		local lock = create("TextLabel", { Name = "Nivel", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -2), Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Text = "nv. " .. sk.Level, TextSize = 11, Font = Enum.Font.GothamBold, TextColor3 = rgb(255, 210, 120), TextStrokeTransparency = 0.2, Visible = false, ZIndex = 5, Parent = btn })
		if not touch then
			create("TextLabel", { Name = "Tecla", Position = UDim2.fromOffset(4, 2), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, Text = sk.Key, TextSize = 14, Font = Enum.Font.GothamBlack, TextColor3 = rgb(255, 255, 255), TextStrokeTransparency = 0.3, ZIndex = 5, Parent = btn })
		end
		buttons[sk.Id] = { Button = btn, Cover = cover, Count = count, Lock = lock }
		btn.Activated:Connect(function()
			if not HunterSkills.unlocked(sk, level(), if level() >= 999 then nil else known()) then
				local okHud, Hud = pcall(function()
					return require(script.Parent.Parent.UI.Hud) :: any
				end)
				if okHud and Hud.toast then
					Hud.toast("Info", ("%s %s: se desbloquea con nivel de cazador %d. %s"):format(sk.Icon, sk.Name, sk.Level, sk.Desc))
				end
				return
			end
			use(sk)
		end)
	end
	-- Móvil: las seis habilidades en arco alrededor del Atacar (HudLayout.Cluster Hab1..Hab6), con su cuenta
	-- atrás dentro del botón; apagadas si no te llega el espíritu
	for i, sk in HunterSkills.List do
		TouchLayout.register({
			Id = "Hab_" .. sk.Id,
			Icon = sk.Icon,
			Image = sk.Art,
			Label = SHORT[sk.Id] or sk.Name, -- (cada uno el suyo: dos botones con el mismo texto no salen)
			Slot = "Hab" .. i,
			Priority = 2,
			Visible = function()
				return onPlanet() and not busy() and player:GetAttribute("Riding") == nil and player:GetAttribute("Piloting") == nil and player:GetAttribute("Swimming") ~= true
			end,
			Callback = function()
				if not HunterSkills.unlocked(sk, level(), if level() >= 999 then nil else known()) then
					local okHud, Hud = pcall(function()
						return require(script.Parent.Parent.UI.Hud) :: any
					end)
					if okHud and Hud.toast then
						Hud.toast("Info", ("%s %s: se desbloquea con nivel de cazador %d. %s"):format(sk.Icon, sk.Name, sk.Level, sk.Desc))
					end
					return
				end
				use(sk)
			end,
			Active = function()
				local mana = tonumber(player:GetAttribute("Espiritu")) or 999
				return if HunterSkills.unlocked(sk, level(), if level() >= 999 then nil else known()) and mana < (sk.Mana or 0) then "wait" else false
			end,
			Meter = function()
				local left = math.max(0, (readyAt[sk.Id] or 0) - os.clock())
				return if left > 0 then 1 - math.clamp(left / (total[sk.Id] or sk.Cooldown), 0, 1) else nil
			end,
			Badge = function()
				if not HunterSkills.unlocked(sk, level(), if level() >= 999 then nil else known()) then
					local k = known()
					return if k and not k.Graduated then "🎓" else "nv." .. sk.Level -- (🎓: te la enseñan en la Academia)
				end
				local left = math.max(0, (readyAt[sk.Id] or 0) - os.clock())
				return if left > 0 then tostring(math.ceil(left)) else nil
			end,
			Key = sk.Key,
		})
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		for _, sk in HunterSkills.List do
			if input.KeyCode.Name == sk.Key then
				use(sk)
			end
		end
	end)
	remote.OnClientEvent:Connect(function(kind: string, id: any, extra: any)
		local sk = HunterSkills.get(id)
		if kind == "Used" and sk then
			total[sk.Id] = tonumber(extra) or sk.Cooldown
			readyAt[sk.Id] = os.clock() + total[sk.Id]
			if sk.Kind == "Dash" then
				dash(sk)
			end
		elseif kind == "No" and type(extra) == "string" then
			local okHud, Hud = pcall(function()
				return require(script.Parent.Parent.UI.Hud) :: any
			end)
			if okHud and Hud.toast then
				Hud.toast("Info", extra)
			end
		end
	end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 0.2 then
			acc = 0
			refresh()
		end
	end)
end

return HunterSkillsUI
