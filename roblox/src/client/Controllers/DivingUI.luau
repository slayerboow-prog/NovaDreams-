-- DivingUI (cliente): nadar, bucear y pesca submarina.
--   * Nadando salen los botones "⬇️ Bucear" y "⬆️ Subir" (mantener pulsado). En el ordenador:
--     C para bajar y Espacio para subir (mando: LT y A). La física del cuerpo en el agua (flotar,
--     bajar, subir, no tumbarse en el fondo, la cámara) la lleva Controllers/Swimming.
--   * Móvil: nadando, el racimo cambia: fuera Ataque, Defensa, armas, gestos y agacharse
--     (TouchLayout.setSwimming); Bucear va en el hueco grande y Subir (buceando) al lado.
--   * Bajo el agua sale la barra de aire (💨). Si se acaba, pierdes vida: sube a respirar.
--   * Con el fusil submarino (o el arpón) nadan peces a tu alrededor. El que tienes delante se
--     marca; "🔱 Disparar" (o la tecla F) le dispara. Los grandes aguantan varios disparos.

local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.UI.Theme)
local Hud = require(script.Parent.Parent.UI.Hud)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local Fishing = require(ReplicatedStorage.Shared.Fishing)
local Format = require(ReplicatedStorage.Shared.Format)
local SoundFx = require(script.Parent.SoundFx)
local Swimming = require(script.Parent.Swimming)
local Swim = require(ReplicatedStorage.Shared.Swim)

local DivingUI = {}

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Diving") :: RemoteEvent
local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB
local DIVE = Fishing.Dive

local vertical = 0 -- -1 bajar, 1 subir (mientras se mantiene pulsado)
local wasUnder = false
local target: BasePart? = nil
local highlight: Highlight? = nil

local function character(): (BasePart?, Humanoid?, BasePart?)
	local char = player.Character
	if not char then
		return nil, nil, nil
	end
	return char:FindFirstChild("HumanoidRootPart") :: BasePart?, char:FindFirstChildOfClass("Humanoid"), char:FindFirstChild("Head") :: BasePart?
end

-- Lo que llevas: nivel y herramientas (para saber qué peces puedes cazar)
local function gear(): (number, { [string]: boolean })
	local tools = {}
	local ok, slots = pcall(function()
		return HttpService:JSONDecode(player:GetAttribute("Inventory") or "[]")
	end)
	for _, slot in if ok and typeof(slots) == "table" then slots else {} do
		if typeof(slot) == "table" and Fishing.Tools[slot.i] then
			tools[slot.i] = true
		end
	end
	return player:GetAttribute("FishingLevel") or 1, tools
end

-- Con la cabeza bajo el agua: se mira el centro del cuerpo (la postura de nadar baja la cabeza a
-- la altura de la cadera: con la cabeza, nadando en la superficie parecía que buceabas)
local function underwater(): boolean
	local root = character()
	local char = player.Character
	if not root or not char or not Swimming.isSwimming() then
		wasUnder = false
		return false
	end
	wasUnder = Swim.isUnderwater(root.Position.Y, char:GetScale(), wasUnder)
	return wasUnder
end

local function setVertical(value: number)
	vertical = value
	Swimming.setInput(value)
end

-- El pez que tienes delante (el más centrado en la cámara)
local function pickTarget(): BasePart?
	local root = character()
	if not root then
		return nil
	end
	local camera = workspace.CurrentCamera
	local look = camera.CFrame.LookVector
	local best, bestScore = nil, math.huge
	for _, fish in CollectionService:GetTagged("SwimFish") do
		if fish:IsA("BasePart") and fish.Parent then
			local offset = fish.Position - root.Position
			local dist = offset.Magnitude
			if dist <= DIVE.Range and dist > 0.1 then
				local angle = math.deg(math.acos(math.clamp(offset.Unit:Dot(look), -1, 1)))
				if angle < 40 or dist < 8 then
					local score = angle + dist * 0.5
					if score < bestScore then
						best, bestScore = fish, score
					end
				end
			end
		end
	end
	return best
end

local function spearTrail(from: Vector3, to: Vector3)
	local length = (to - from).Magnitude
	local spear = Instance.new("Part")
	spear.Name = "Spear"
	spear.Anchored = true
	spear.CanCollide = false
	spear.CanQuery = false
	spear.CanTouch = false
	spear.Material = Enum.Material.Neon
	spear.Color = rgb(220, 230, 240)
	spear.Size = Vector3.new(0.12, 0.12, length)
	spear.CFrame = CFrame.lookAt((from + to) / 2, to)
	spear.Parent = workspace.CurrentCamera
	local fade = TweenService:Create(spear, TweenInfo.new(0.35), { Transparency = 1 })
	fade:Play()
	fade.Completed:Connect(function()
		spear:Destroy()
	end)
end

local function shoot()
	local fish = target or pickTarget()
	local root = character()
	if not fish or not root then
		Hud.toast("Info", "🔱 No hay ningún pez delante. Gira la cámara hacia uno.")
		return
	end
	spearTrail(root.Position, fish.Position)
	pcall(SoundFx.play, "Aviso", 0.6, 2.2)
	Remote:FireServer("Shoot", fish)
end

-- Etiqueta encima de cada pez: nombre, y candado si aún no lo puedes cazar
local function label(fish: Instance)
	if not fish:IsA("BasePart") then
		return
	end
	local species = Fishing.byId[fish:GetAttribute("Species") or ""]
	if not species then
		return
	end
	local level, tools = gear()
	local need = Fishing.spearMissing(species, level, tools)
	local gui = create("BillboardGui", {
		Name = "FishLabel",
		Size = UDim2.fromOffset(160, 36),
		StudsOffsetWorldSpace = Vector3.new(0, fish.Size.Y / 2 + 1.2, 0),
		MaxDistance = 45,
		AlwaysOnTop = true,
		Parent = fish,
	})
	local text = create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = ("%s%s %s"):format(if #need > 0 then "🔒 " else "", species.Icon, species.Name),
		TextColor3 = Fishing.RarityColors[species.Rarity] or C.Text,
		TextStrokeTransparency = 0.3,
		Font = Theme.FontBold,
		TextScaled = true,
		Parent = gui,
	})
	local function hp()
		local max = fish:GetAttribute("MaxHp") or 1
		local now = fish:GetAttribute("Hp") or max
		if max > 1 then
			text.Text = ("%s%s %s %s"):format(if #need > 0 then "🔒 " else "", species.Icon, species.Name, string.rep("❤️", now))
		end
	end
	fish:GetAttributeChangedSignal("Hp"):Connect(hp)
	hp()
end

---------------------------------------------------------------------

function DivingUI.init()
	local gui = create("ScreenGui", { Name = "DivingGui", ResetOnSpawn = false, DisplayOrder = 2, Parent = player:WaitForChild("PlayerGui") })
	Theme.fit(gui)
	-- Barra de aire
	local air = Theme.panel({ Name = "Air", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.fromOffset(280, 40), Visible = false, Parent = gui })
	local airText = Theme.label({ Position = UDim2.fromOffset(10, 2), Size = UDim2.new(1, -20, 0, 18), Text = "💨 Aire", TextSize = 13, Parent = air })
	local airBar = create("Frame", { Position = UDim2.new(0, 10, 0, 22), Size = UDim2.new(1, -20, 0, 10), BackgroundColor3 = rgb(8, 14, 28), BorderSizePixel = 0, Parent = air }, { Theme.corner(5) })
	local airFill = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(90, 190, 255), BorderSizePixel = 0, Parent = airBar }, { Theme.corner(5) })
	-- Botones de buceo (a la derecha, encima del salto)
	local buttons = create("Frame", { Name = "DiveButtons", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.48, 0), Size = UDim2.fromOffset(120, 176), BackgroundTransparency = 1, Visible = false, Parent = gui })
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = buttons })
	local shootButton = Theme.button({ Size = UDim2.new(1, 0, 0, 52), Text = "🔱 Disparar", TextSize = 17, BackgroundColor3 = rgb(200, 90, 40), LayoutOrder = 1, Visible = false, Parent = buttons })
	local up = Theme.button({ Size = UDim2.new(1, 0, 0, 50), Text = "⬆️ Subir", TextSize = 16, BackgroundColor3 = rgb(30, 110, 170), LayoutOrder = 2, Parent = buttons })
	local down = Theme.button({ Size = UDim2.new(1, 0, 0, 50), Text = "⬇️ Bucear", TextSize = 16, BackgroundColor3 = rgb(20, 70, 130), LayoutOrder = 3, Parent = buttons })
	local function hold(button: GuiButton, dir: number)
		button.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				setVertical(dir)
			end
		end)
		button.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				setVertical(0)
			end
		end)
	end
	hold(up, 1)
	hold(down, -1)
	shootButton.Activated:Connect(shoot)
	-- Móvil: estos botones quedaban debajo del racimo táctil (Saltar, Interactuar…). Van en la columna
	-- de contexto de UI/TouchLayout (en huecos libres) y el marco de aquí no se usa.
	-- Nadando, los huecos de pelear del racimo quedan libres (TouchLayout.setSwimming los esconde):
	-- Bucear en el grande, Subir al lado (solo buceando: en la superficie, Saltar) y el fusil en el
	-- de los gestos.
	local touch = TouchLayout.isTouch()
	local swimmingNow, shootNow, divingNow = false, false, false
	if touch then
		TouchLayout.register({
			Id = "BucearDisparar", Icon = "disparar", Label = "Disparar", Slot = "Gestos", Priority = 6,
			Visible = function()
				return swimmingNow and shootNow
			end,
			Callback = shoot,
		})
		TouchLayout.register({
			Id = "BucearSubir", Icon = "flecha", Label = "Subir", Slot = "Defender", Priority = 7,
			Visible = function()
				return swimmingNow and divingNow
			end,
			Active = function()
				return vertical == 1
			end,
			Hold = function(pressed: boolean)
				setVertical(if pressed then 1 elseif vertical == 1 then 0 else vertical)
			end,
		})
		TouchLayout.register({
			Id = "BucearBajar", Icon = "bajarse", Label = "Bucear", Slot = "Ataque", Priority = 8,
			Visible = function()
				return swimmingNow
			end,
			Active = function()
				return vertical == -1
			end,
			Hold = function(pressed: boolean)
				setVertical(if pressed then -1 elseif vertical == -1 then 0 else vertical)
			end,
		})
	end
	ContextActionService:BindAction("DiveDown", function(_, state)
		setVertical(if state == Enum.UserInputState.Begin then -1 else 0)
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.C, Enum.KeyCode.ButtonL2)
	-- Espacio / A: buceando sube (Swimming); en la superficie salta como siempre (no se quita el salto)
	ContextActionService:BindAction("DiveUp", function(_, state)
		Swimming.setJump(state == Enum.UserInputState.Begin)
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
	ContextActionService:BindAction("DiveShoot", function(_, state)
		if state == Enum.UserInputState.Begin and (buttons.Visible or shootNow) and shootButton.Visible then
			shoot()
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.F)

	-- Etiquetas de los peces
	for _, fish in CollectionService:GetTagged("SwimFish") do
		task.spawn(label, fish)
	end
	CollectionService:GetInstanceAddedSignal("SwimFish"):Connect(label)

	-- Subir y bajar mientras nadas: lo hace Swimming (flotar, bucear, el fondo y la cámara)
	Swimming.init()
	local function swimHud()
		local swimming = Swimming.isSwimming()
		TouchLayout.setSwimming(swimming, Swim.HiddenButtons)
		local diving = swimming and Swimming.mode() == "Dive"
		if touch and (swimmingNow ~= swimming or divingNow ~= diving) then
			swimmingNow, divingNow = swimming, diving
			TouchLayout.refresh()
		end
	end
	Swimming.Changed:Connect(swimHud)
	player:GetAttributeChangedSignal("SwimMode"):Connect(swimHud)

	-- Botones, aire y pez marcado
	task.spawn(function()
		while true do
			task.wait(0.2)
			local swimming = Swimming.isSwimming()
			buttons.Visible = swimming and not touch
			up.Visible = swimming and Swimming.mode() == "Dive"
			if not swimming and vertical ~= 0 then
				setVertical(0)
			end
			swimHud()
			local oxygen, max = player:GetAttribute("Oxygen"), player:GetAttribute("OxygenMax")
			local below = underwater()
			if typeof(oxygen) == "number" and typeof(max) == "number" and max > 0 and (below or oxygen < max) then
				air.Visible = true
				airFill.Size = UDim2.fromScale(math.clamp(oxygen / max, 0, 1), 1)
				airFill.BackgroundColor3 = if oxygen / max < 0.25 then C.Error else rgb(90, 190, 255)
				airText.Text = ("💨 Aire: %d s%s"):format(oxygen, if oxygen <= 0 then " · ¡SUBE A RESPIRAR!" else "")
			else
				air.Visible = false
			end
			local _, tools = gear()
			local armed = tools.FusilSubmarino or tools.Arpon
			shootButton.Visible = below and armed == true
			target = if shootButton.Visible then pickTarget() else nil
			if touch and shootNow ~= shootButton.Visible then
				shootNow = shootButton.Visible
				TouchLayout.refresh()
			end
			if target then
				if not highlight then
					highlight = create("Highlight", { FillTransparency = 0.6, OutlineColor = rgb(255, 230, 90), FillColor = rgb(255, 230, 90), DepthMode = Enum.HighlightDepthMode.AlwaysOnTop })
				end
				(highlight :: Highlight).Adornee = target;
				(highlight :: Highlight).Parent = target
			elseif highlight then
				highlight.Parent = nil
			end
		end
	end)

	Remote.OnClientEvent:Connect(function(action, data)
		if action == "Caught" then
			Hud.toast("Money", ("%s ¡Cazado: %s de %s kg! %s · +%d XP · 🎒 (%s)"):format(data.Icon, string.lower(data.Name), (string.gsub(tostring(data.Kg), "%.", ",")), data.Rarity, data.Xp, Format.money(data.Price)))
			pcall(SoundFx.play, "Aviso", 1, 1.8)
		elseif action == "Hit" then
			Hud.toast("Info", ("🔱 ¡Tocado! Le quedan %d. ¡Otra vez!"):format(data.Hp))
		end
	end)
end

return DivingUI
