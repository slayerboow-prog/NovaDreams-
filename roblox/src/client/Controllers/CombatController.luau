-- CombatController (cliente): pegar, defenderse y ver los golpes.
--
-- Controles:
--   Ordenador: X golpear (pulsa seguido para el combo de 3) · mantén Z para defenderte
--   Mando:     RB golpear · mantén LB para defenderte
--   Móvil:     botón 👊 (golpear) y botón 🛡 (mantener para defenderte), encima del de saltar
--   Menú de comandos: ATACAR
-- Quien decide si el golpe entra es el servidor (CombatService); aquí solo se anima y se enseña:
-- el golpe (animación y sonido), el número de daño, el destello rojo, el empujón y el K.O.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Combat = require(ReplicatedStorage.Shared.Combat)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local Theme = require(script.Parent.Parent.UI.Theme)
local ReactMotion = require(script.Parent.ReactMotion)
local PunchAnim = require(script.Parent.PunchAnim)
local SoundFx = require(script.Parent.SoundFx)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)

local CombatController = {}

local player = Players.LocalPlayer
local create = Theme.create
local rgb = Color3.fromRGB
local Remote: RemoteEvent

-- Directo, cruzado y patada: los tres golpes del combo (PunchAnim; si no se puede, ReactMotion
-- con el gancho de golpe fuerte)
local MOVES = { "Jab", "Cross", "Kick" }
local PUNCHES = { "Jab", "Cross", "Hook" }

-- Golpe número `combo` en un personaje: PunchAnim (C0, se ve siempre) o, si no, ReactMotion
local function swingPose(character: Model?, combo: number): boolean
	return PunchAnim.play(character, MOVES[combo] or "Jab") or ReactMotion.play(character, PUNCHES[combo] or "Jab")
end

-- Guardia: igual, PunchAnim y si no ReactMotion
local function guardPose(character: Model?, on: boolean)
	if not PunchAnim.hold(character, "Guard", on) then
		ReactMotion.hold(character, "Guard", on)
	end
end

local function isR15(model: Model?): boolean
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.RigType == Enum.HumanoidRigType.R15
end

-- Animaciones de Roblox de golpear con herramienta (sirven para puñetazo y golpe fuerte)
local ANIMS = {
	R15 = { Punch = 522635514, Heavy = 522638767 },
	R6 = { Punch = 129967390, Heavy = 129967478 },
}

local localCombo, localComboAt = 0, 0
local blocking = false
local tracks: { [string]: AnimationTrack } = {}
local koGui: ScreenGui? = nil

local function parts(): (Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	return character:FindFirstChildOfClass("Humanoid"), character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- ¿Puedo pegar ahora? (el servidor lo vuelve a comprobar todo)
function CombatController.canAttack(): boolean
	local humanoid = parts()
	local stage = player:GetAttribute("LifeStage")
	return humanoid ~= nil
		and humanoid.Health > 0
		and humanoid.SeatPart == nil
		and not player:GetAttribute("KO")
		and not player:GetAttribute("InDialogue")
		and (stage == nil or Stages.inRange(stage, Combat.MinStage, nil))
end

local function track(name: string): AnimationTrack?
	local humanoid = parts()
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not humanoid or not animator then
		return nil
	end
	local rig = if humanoid.RigType == Enum.HumanoidRigType.R15 then "R15" else "R6"
	local key = rig .. name
	local existing = tracks[key]
	if existing and existing.Parent then
		return existing
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://" .. ANIMS[rig][name]
	local ok, loaded = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok then
		return nil
	end
	loaded.Priority = Enum.AnimationPriority.Action
	tracks[key] = loaded
	return loaded
end

function CombatController.attack()
	if not CombatController.canAttack() then
		return
	end
	local now = os.clock()
	-- Misma pausa que el servidor, para que la animación no vaya por delante del golpe
	if not Combat.ready(localCombo, localComboAt, now) then
		return
	end
	localCombo = Combat.nextCombo(localCombo, localComboAt, now)
	localComboAt = now
	if blocking then
		CombatController.setBlocking(false)
	end
	-- Puñetazo hecho con código (R15); si este cuerpo no se puede mover así, animación de Roblox
	if not (isR15(player.Character) and swingPose(player.Character, localCombo)) then
		local anim = track(if localCombo == 3 then "Heavy" else "Punch")
		if anim then
			anim:Play(0.05, 1, if localCombo == 3 then 1.1 else 1.6)
		end
	end
	-- Sonido del golpe al aire (los demás lo oyen con "Swing")
	local _, root = parts()
	if root then
		SoundFx.play("Salto", 0.7, if localCombo == 3 then 0.8 else 1.3, root)
	end
	Remote:FireServer("Attack")
end

function CombatController.setBlocking(value: boolean)
	if value and not CombatController.canAttack() then
		value = false
	end
	if blocking == value then
		return
	end
	blocking = value
	-- La guardia se ve al momento en tu pantalla (sin esperar a que el servidor la confirme)
	guardPose(player.Character, value or player:GetAttribute("Blocking") == true)
	Remote:FireServer("Block", value)
end

---------------------------------------------------------------------
-- Lo que se ve y se oye
---------------------------------------------------------------------

-- Número de daño que sube y se desvanece sobre la cabeza
local function damageNumber(model: Model, amount: number, blocked: boolean, heavy: boolean)
	local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
	if not head or amount <= 0 then
		return
	end
	local billboard = create("BillboardGui", {
		Size = UDim2.fromOffset(90, 40),
		StudsOffset = Vector3.new(math.random(-10, 10) / 10, 2.2, 0),
		AlwaysOnTop = true,
		Adornee = head,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local label = Theme.label({
		Size = UDim2.fromScale(1, 1),
		FontFace = Theme.TitleFace,
		Text = (if blocked then "🛡 " else "") .. "-" .. tostring(amount),
		TextSize = if heavy then 30 else 24,
		TextColor3 = if blocked then rgb(160, 200, 255) elseif heavy then rgb(255, 120, 60) else rgb(255, 230, 90),
		TextStrokeTransparency = 0.2,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = billboard,
	})
	TweenService:Create(billboard, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffset = billboard.StudsOffset + Vector3.new(0, 1.6, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(0.85, function()
		billboard:Destroy()
	end)
end

-- Destello rojo (o azul si se ha defendido)
local function flash(model: Model, blocked: boolean)
	local highlight = create("Highlight", {
		FillColor = if blocked then rgb(120, 180, 255) else rgb(255, 60, 60),
		FillTransparency = 0.35,
		OutlineTransparency = 1,
		DepthMode = Enum.HighlightDepthMode.Occluded,
		Adornee = model,
		Parent = model,
	})
	TweenService:Create(highlight, TweenInfo.new(0.25), { FillTransparency = 1 }):Play()
	task.delay(0.3, function()
		highlight:Destroy()
	end)
end

local function shake(strength: number)
	local camera = workspace.CurrentCamera
	task.spawn(function()
		for i = 1, 6 do
			local fade = 1 - i / 6
			camera.CFrame *= CFrame.new((math.random() - 0.5) * strength * fade, (math.random() - 0.5) * strength * fade, 0)
			task.wait()
		end
	end)
end

-- K.O.: te caes, no puedes moverte y cuenta atrás; al acabar te levantas
local function showKnockOut(on: boolean)
	local humanoid = parts()
	if humanoid then
		humanoid.PlatformStand = on
		if not on then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end
	if koGui then
		koGui:Destroy()
		koGui = nil
	end
	if not on then
		return
	end
	local gui = create("ScreenGui", { Name = "KnockOut", ResetOnSpawn = true, IgnoreGuiInset = true, DisplayOrder = 8, Parent = player:WaitForChild("PlayerGui") })
	koGui = gui
	local shade = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(60, 0, 0), BackgroundTransparency = 1, Parent = gui })
	TweenService:Create(shade, TweenInfo.new(0.4), { BackgroundTransparency = 0.55 }):Play()
	Theme.label({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(400, 80), FontFace = Theme.TitleFace, Text = "K.O.", TextSize = 72, TextColor3 = rgb(255, 90, 80), TextStrokeTransparency = 0.2, TextXAlignment = Enum.TextXAlignment.Center, Parent = gui })
	local counter = Theme.label({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.53), Size = UDim2.fromOffset(400, 30), Text = "", TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center, Parent = gui })
	task.spawn(function()
		local left = Combat.KOSeconds
		while koGui == gui and left > 0 do
			counter.Text = ("Te levantas en %d…"):format(math.ceil(left))
			left -= task.wait(0.2)
		end
	end)
end

local function onHit(data: { [string]: any })
	local model = data.Victim :: Model?
	if not model or not model.Parent then
		return
	end
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	local heavy = data.Combo == 3
	SoundFx.play("Golpe", if heavy then 1.2 else 0.8, if data.Blocked then 1.6 else (if heavy then 0.8 else 1.1), root)
	flash(model, data.Blocked)
	-- El cuerpo reacciona: cabeza atrás, tambaleo o caída si es el gancho
	if data.Blocked then
		ReactMotion.play(model, "BlockHit")
	elseif heavy then
		ReactMotion.play(model, "HitHeavy")
	else
		ReactMotion.play(model, "HitLight", { Side = if math.random() < 0.5 then -1 else 1 })
	end
	damageNumber(model, data.Amount, data.Blocked, heavy)
	local mine = model == player.Character
	if mine then
		-- El empujón se aplica aquí: tu personaje lo mueve tu dispositivo
		local _, myRoot = parts()
		if myRoot and data.Knockback > 0 then
			myRoot.AssemblyLinearVelocity += data.Direction * data.Knockback + Vector3.new(0, if heavy then 14 else 4, 0)
		end
		shake(if heavy then 1.2 else 0.5)
	elseif data.Attacker == player then
		shake(if heavy then 0.5 else 0.2)
	end
end

local function onSwing(attacker: Player, combo: number)
	local character = attacker.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		SoundFx.play("Salto", 0.7, if combo == 3 then 0.8 else 1.3, root)
	end
	swingPose(character, combo)
end

-- 🛡 encima de quien se está defendiendo
local shields: { [Player]: BillboardGui } = {}
local function updateShield(other: Player)
	local on = other:GetAttribute("Blocking") == true
	-- (tu propia guardia sigue a tu dedo, aunque el servidor tarde en confirmarla)
	guardPose(other.Character, on or (other == player and blocking))
	local existing = shields[other]
	if on and not existing then
		local head = other.Character and other.Character:FindFirstChild("Head")
		if head then
			local billboard = create("BillboardGui", { Size = UDim2.fromOffset(40, 40), StudsOffset = Vector3.new(0, 2.6, 0), AlwaysOnTop = true, Adornee = head, Parent = player:WaitForChild("PlayerGui") })
			Theme.label({ Size = UDim2.fromScale(1, 1), Text = "🛡", TextSize = 28, TextXAlignment = Enum.TextXAlignment.Center, Parent = billboard })
			shields[other] = billboard
		end
	elseif not on and existing then
		existing:Destroy()
		shields[other] = nil
	end
end

---------------------------------------------------------------------
-- Controles
---------------------------------------------------------------------
local function roundButton(gui: ScreenGui, icon: string, size: number, position: UDim2): TextButton
	local button = Theme.button({
		AnchorPoint = Vector2.new(1, 1),
		Size = UDim2.fromOffset(size, size),
		Position = position,
		Text = icon,
		TextSize = math.floor(size * 0.45),
		BackgroundTransparency = 0.3,
		Parent = gui,
	})
	local corner = button:FindFirstChildOfClass("UICorner")
	if corner then
		corner.CornerRadius = UDim.new(0.5, 0)
	end
	return button
end

function CombatController.init()
	Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat", 30) :: RemoteEvent
	if not Remote then
		warn("[Combate] No está el remoto Combat")
		return
	end
	Remote.OnClientEvent:Connect(function(kind: string, a: any, b: any)
		if kind == "Hit" then
			onHit(a)
		elseif kind == "Swing" and a ~= player then
			onSwing(a, b)
		end
	end)

	local function typing(): boolean
		return UserInputService:GetFocusedTextBox() ~= nil
	end
	ContextActionService:BindAction("CombatAttack", function(_, state)
		if state == Enum.UserInputState.Begin and not typing() then
			CombatController.attack()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.X, Enum.KeyCode.ButtonR1)
	ContextActionService:BindAction("CombatBlock", function(_, state)
		if not typing() then
			CombatController.setBlocking(state == Enum.UserInputState.Begin)
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.Z, Enum.KeyCode.ButtonL1)

	-- Móvil: 👊 y 🛡 en el arco del botón de saltar (TouchLayout); conduciendo no se ven
	if UserInputService.TouchEnabled then
		local gui = create("ScreenGui", { Name = "CombatGui", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })
		local punch = roundButton(gui, "👊", 64, UDim2.new())
		TouchLayout.place(punch, "Golpear")
		TouchLayout.showWhen(punch, "Pie")
		punch.Activated:Connect(CombatController.attack)
		local guard = roundButton(gui, "🛡", 54, UDim2.new())
		TouchLayout.place(guard, "Defender")
		TouchLayout.showWhen(guard, "Pie")
		guard.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				CombatController.setBlocking(true)
			end
		end)
		guard.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				CombatController.setBlocking(false)
			end
		end)
		-- Los bebés no pelean: sin botones
		local function refresh()
			local stage = player:GetAttribute("LifeStage")
			gui.Enabled = stage == nil or Stages.inRange(stage, Combat.MinStage, nil)
		end
		player:GetAttributeChangedSignal("LifeStage"):Connect(refresh)
		refresh()
	end

	player:GetAttributeChangedSignal("KO"):Connect(function()
		local ko = player:GetAttribute("KO") == true
		if ko then
			blocking = false
			guardPose(player.Character, false)
		end
		showKnockOut(ko)
	end)
	player.CharacterAdded:Connect(function()
		tracks = {}
		blocking = false
		showKnockOut(false)
	end)

	local function watch(other: Player)
		other:GetAttributeChangedSignal("Blocking"):Connect(function()
			updateShield(other)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, other in Players:GetPlayers() do
		watch(other)
	end
	Players.PlayerRemoving:Connect(function(other)
		if shields[other] then
			shields[other]:Destroy()
			shields[other] = nil
		end
	end)
end

return CombatController
