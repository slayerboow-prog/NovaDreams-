-- HunterSkillsUI (cliente): los botones de las HABILIDADES DE CAZADOR (shared/HunterSkills;
-- Services/HunterSkillService). Solo se ven en un planeta (atributo «Planeta»).
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

local HunterSkillsUI = {}

local player = Players.LocalPlayer
local create = Theme.create
local rgb = Color3.fromRGB

local gui: ScreenGui
local remote: RemoteEvent
local buttons: { [string]: { Button: TextButton, Cover: Frame, Count: TextLabel, Lock: TextLabel } } = {}
local readyAt: { [string]: number } = {}
local total: { [string]: number } = {}

local function level(): number
	return tonumber(player:GetAttribute("NivelCazador")) or 1
end

local function onPlanet(): boolean
	return type(player:GetAttribute("Planeta")) == "string"
end

local function busy(): boolean
	return player:GetAttribute("InDialogue") == true or player:GetAttribute("InCinematic") == true
end

local function use(sk: { [string]: any })
	if not onPlanet() or busy() then
		return
	end
	if not HunterSkills.unlocked(sk, level()) or (readyAt[sk.Id] or 0) > os.clock() then
		return
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
	local show = onPlanet()
	gui.Enabled = show
	if not show then
		return
	end
	local lvl = level()
	local now = os.clock()
	for _, sk in HunterSkills.List do
		local b = buttons[sk.Id]
		local unlocked = HunterSkills.unlocked(sk, lvl)
		local left = math.max(0, (readyAt[sk.Id] or 0) - now)
		b.Lock.Visible = not unlocked
		b.Cover.Visible = unlocked and left > 0
		b.Count.Visible = unlocked and left > 0
		if left > 0 then
			b.Count.Text = tostring(math.ceil(left))
			b.Cover.Size = UDim2.fromScale(1, math.clamp(left / (total[sk.Id] or sk.Cooldown), 0, 1))
		end
		b.Button.BackgroundColor3 = if not unlocked then rgb(40, 42, 50) elseif left > 0 then rgb(34, 44, 66) else rgb(50, 110, 190)
		b.Button.TextTransparency = if unlocked then 0 else 0.6
	end
end

function HunterSkillsUI.init()
	remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("HunterSkill") :: RemoteEvent
	gui = create("ScreenGui", { Name = "HunterSkillsGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 3, Enabled = false, Parent = player:WaitForChild("PlayerGui") })
	local touch = Theme.isTouch()
	local size = if touch then 50 else 44
	local column = create("Frame", { Name = "Skills", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.42, 0), Size = UDim2.fromOffset(size, (size + 8) * #HunterSkills.List), BackgroundTransparency = 1, Parent = gui })
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = column })
	for i, sk in HunterSkills.List do
		local btn = create("TextButton", { Name = sk.Id, Size = UDim2.fromOffset(size, size), BackgroundColor3 = rgb(50, 110, 190), BackgroundTransparency = 0.15, Text = sk.Icon, TextSize = if touch then 24 else 22, TextColor3 = rgb(255, 255, 255), AutoButtonColor = true, LayoutOrder = i, ClipsDescendants = true, Parent = column })
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = btn })
		create("UIStroke", { Color = rgb(150, 200, 255), Thickness = 1.5, Transparency = 0.3, Parent = btn })
		local cover = create("Frame", { Name = "Espera", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(0, 0, 0), BackgroundTransparency = 0.45, BorderSizePixel = 0, Visible = false, Parent = btn })
		local count = create("TextLabel", { Name = "Cuenta", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", TextSize = 20, Font = Enum.Font.GothamBold, TextColor3 = rgb(255, 255, 255), Visible = false, ZIndex = 3, Parent = btn })
		local lock = create("TextLabel", { Name = "Nivel", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -2), Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Text = "nv. " .. sk.Level, TextSize = 11, Font = Enum.Font.GothamBold, TextColor3 = rgb(255, 210, 120), Visible = false, ZIndex = 3, Parent = btn })
		if not touch then
			create("TextLabel", { Name = "Tecla", Position = UDim2.fromOffset(2, 0), Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1, Text = sk.Key, TextSize = 11, Font = Enum.Font.GothamBold, TextColor3 = rgb(220, 235, 255), ZIndex = 3, Parent = btn })
		end
		buttons[sk.Id] = { Button = btn, Cover = cover, Count = count, Lock = lock }
		btn.Activated:Connect(function()
			if not HunterSkills.unlocked(sk, level()) then
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
