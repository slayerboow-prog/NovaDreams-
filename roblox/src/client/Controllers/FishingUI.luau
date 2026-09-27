-- FishingUI (cliente): la pesca.
--   * Al lanzar: caña en la mano, sedal y corcho flotando en el agua. Abajo, el botón "¡TIRAR!"
--     (en el ordenador también la tecla R). Cuando el corcho se hunde, ¡a tirar rápido!
--   * Tienda de pesca: cañas y cebo.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local Format = require(ReplicatedStorage.Shared.Format)
local SoundFx = require(script.Parent.SoundFx)

local FishingUI = {}

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Fishing") :: RemoteEvent
local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

local panel: Frame
local status: TextLabel
local reelButton: TextButton
local stopButton: TextButton

type Session = { Token: number, Bobber: BasePart?, Rod: BasePart?, Beam: Beam?, Base: Vector3, Bite: boolean, Done: boolean, Folder: Folder }
local session: Session? = nil

local function cleanup()
	if session then
		session.Folder:Destroy()
		if session.Rod then
			session.Rod:Destroy()
		end
	end
	session = nil
	panel.Visible = false
	ContextActionService:UnbindAction("FishReel")
end

local function setButton(text: string, color: Color3)
	reelButton.Text = text
	reelButton.BackgroundColor3 = color
end

local function reel()
	local s = session
	if not s then
		return
	end
	if s.Done then
		Remote:FireServer("Again")
		return
	end
	Remote:FireServer("Reel", s.Token)
end

-- Caña en la mano, sedal y corcho
local function props(bobberAt: Vector3): (BasePart?, BasePart, Beam?, Folder)
	local folder = Instance.new("Folder")
	folder.Name = "Fishing"
	folder.Parent = workspace.CurrentCamera
	local bobber = Instance.new("Part")
	bobber.Name = "Bobber"
	bobber.Shape = Enum.PartType.Ball
	bobber.Size = Vector3.new(0.7, 0.7, 0.7)
	bobber.Color = rgb(230, 40, 40)
	bobber.Anchored = true
	bobber.CanCollide = false
	bobber.CanQuery = false
	bobber.CFrame = CFrame.new(bobberAt)
	bobber.Parent = folder
	local top = Instance.new("Part")
	top.Name = "BobberTop"
	top.Shape = Enum.PartType.Ball
	top.Size = Vector3.new(0.45, 0.45, 0.45)
	top.Color = rgb(250, 250, 250)
	top.Anchored = true
	top.CanCollide = false
	top.CanQuery = false
	top.CFrame = CFrame.new(bobberAt + Vector3.new(0, 0.4, 0))
	top.Parent = bobber
	local hand = player.Character and (player.Character:FindFirstChild("RightHand") or player.Character:FindFirstChild("Right Arm")) :: BasePart?
	if not hand then
		return nil, bobber, nil, folder
	end
	local rod = Instance.new("Part")
	rod.Name = "FishingRod"
	rod.Size = Vector3.new(0.14, 0.14, 7)
	rod.Color = rgb(40, 40, 44)
	rod.Material = Enum.Material.Metal
	rod.CanCollide = false
	rod.CanQuery = false
	rod.Massless = true
	rod.CFrame = hand.CFrame * CFrame.new(0, -0.2, -3.2) * CFrame.Angles(math.rad(35), 0, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hand
	weld.Part1 = rod
	weld.Parent = rod
	rod.Parent = player.Character
	local tip = Instance.new("Attachment")
	tip.Position = Vector3.new(0, 0, -3.5)
	tip.Parent = rod
	local float = Instance.new("Attachment")
	float.Parent = bobber
	local beam = Instance.new("Beam")
	beam.Attachment0 = tip
	beam.Attachment1 = float
	beam.Width0 = 0.04
	beam.Width1 = 0.04
	beam.Color = ColorSequence.new(rgb(240, 240, 240))
	beam.CurveSize0 = -2
	beam.FaceCamera = true
	beam.Parent = rod
	return rod, bobber, beam, folder
end

local function onCast(data: { [string]: any })
	cleanup()
	local rod, bobber, beam, folder = props(data.Bobber)
	session = { Token = data.Token, Bobber = bobber, Rod = rod, Beam = beam, Base = data.Bobber, Bite = false, Done = false, Folder = folder }
	panel.Visible = true
	status.Text = ("🎣 Pescando en %s con tu %s%s… espera a que el corcho se hunda"):format(
		data.Water,
		string.lower(data.Rod),
		if data.Bait then (" (cebo: te quedan %d)"):format(data.BaitLeft) else ""
	)
	status.TextColor3 = C.Text
	setButton("¡TIRAR!", rgb(60, 70, 90))
	ContextActionService:BindAction("FishReel", function(_, state)
		if state == Enum.UserInputState.Begin then
			reel()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.R, Enum.KeyCode.ButtonR2)
end

local function onBite(data: { [string]: any })
	local s = session
	if not s or s.Token ~= data.Token then
		return
	end
	s.Bite = true
	status.Text = "🐟 ¡PICA! ¡Tira ya!"
	status.TextColor3 = C.Gold
	setButton("¡TIRAR YA!", rgb(40, 170, 80))
	pcall(SoundFx.play, "Aviso", 1, 1.4)
end

local RESULTS = {
	Early = "Has tirado demasiado pronto: el pez se ha asustado. Espera a que el corcho se hunda.",
	Late = "¡Se ha escapado! Cuando se hunda el corcho, hay que tirar rápido.",
}

local function onResult(data: { [string]: any })
	local s = session
	if not s or s.Token ~= data.Token then
		return
	end
	s.Done = true
	s.Bite = false
	if data.Kind == "Catch" then
		status.Text = ("%s ¡Has pescado %s de %s kg!%s  (se vende a %s)"):format(data.Icon, string.lower(data.Name), (string.gsub(tostring(data.Kg), "%.", ",")), if data.Rare then " ⭐ ¡Es raro!" else "", Format.money(data.Price))
		status.TextColor3 = C.Money
		pcall(SoundFx.play, "Aviso", 1, 1.8)
	elseif data.Kind == "Junk" then
		status.Text = ("%s Has sacado %s. A la basura…"):format(data.Icon, data.Name)
		status.TextColor3 = C.Muted
	elseif data.Kind == "Full" then
		status.Text = ("%s ¡Mochila llena! Sueltas %s. Vende el pescado en el supermercado."):format(data.Icon, string.lower(data.Name))
		status.TextColor3 = C.Error
	else
		status.Text = RESULTS[data.Kind] or ""
		status.TextColor3 = C.Error
	end
	setButton("🎣 Lanzar otra vez", C.Accent)
	if s.Bobber then
		s.Bobber.Transparency = 1
		for _, child in s.Bobber:GetChildren() do
			if child:IsA("BasePart") then
				child.Transparency = 1
			end
		end
	end
	if s.Beam then
		s.Beam.Enabled = false
	end
end

---------------------------------------------------------------------
-- Tienda de pesca
---------------------------------------------------------------------
local function openShop(list: { any })
	local window, content, close = Dialog.window("FishingShop", "🎣 Tienda de pesca", Vector2.new(460, 360))
	local layout = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = content })
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = layout })
	for i, it in list do
		local row = create("Frame", { Size = UDim2.new(1, 0, 0, 62), BackgroundColor3 = rgb(20, 32, 56), BackgroundTransparency = 0.2, LayoutOrder = i, Parent = layout }, { Theme.corner(10) })
		Theme.label({ Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -140, 0, 26), Text = ("%s <b>%s</b> · %s"):format(it.Icon, it.Name, Format.money(it.Price)), RichText = true, TextSize = 15, Parent = row })
		Theme.label({ Position = UDim2.fromOffset(10, 30), Size = UDim2.new(1, -140, 0, 28), Text = it.Desc .. (if it.Have then (" (tienes %d)"):format(it.Have) else ""), TextSize = 12, TextColor3 = C.Muted, TextWrapped = true, Parent = row })
		local buy = Theme.button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(110, 40),
			Text = if it.Owned then "✅ La tienes" else "Comprar",
			TextSize = 14,
			BackgroundColor3 = if it.Owned then rgb(50, 52, 60) else C.Accent,
			Parent = row,
		})
		buy.Activated:Connect(function()
			if not it.Owned then
				Remote:FireServer("Buy", it.Id)
			end
		end)
	end
	Theme.label({ Size = UDim2.new(1, 0, 0, 40), Text = "Pesca en el muelle del puerto, en los lagos y en el río. Vende lo que pesques en la pescadería del supermercado.", TextSize = 12, TextColor3 = C.Muted, TextWrapped = true, LayoutOrder = 100, Parent = layout })
	close.Activated:Connect(function()
		window:Destroy()
	end)
end

---------------------------------------------------------------------

function FishingUI.init()
	local gui = create("ScreenGui", { Name = "FishingGui", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })
	Theme.fit(gui)
	panel = Theme.panel({
		Name = "Fishing",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -110),
		Size = UDim2.fromOffset(460, 118),
		Visible = false,
		Parent = gui,
	})
	Theme.padding(10).Parent = panel
	status = Theme.label({ Size = UDim2.new(1, 0, 0, 42), Text = "", TextSize = 15, TextWrapped = true, Parent = panel })
	reelButton = Theme.button({ Position = UDim2.fromOffset(0, 50), Size = UDim2.new(0.68, 0, 0, 46), Text = "¡TIRAR!", TextSize = 20, Parent = panel })
	stopButton = Theme.button({ Position = UDim2.new(0.7, 0, 0, 50), Size = UDim2.new(0.3, 0, 0, 46), Text = "Recoger", TextSize = 15, BackgroundColor3 = rgb(50, 52, 60), Parent = panel })
	reelButton.Activated:Connect(reel)
	stopButton.Activated:Connect(function()
		Remote:FireServer("Stop")
	end)

	Remote.OnClientEvent:Connect(function(action, data)
		if action == "Cast" then
			onCast(data)
		elseif action == "Bite" then
			onBite(data)
		elseif action == "Result" then
			onResult(data)
		elseif action == "Stop" then
			cleanup()
		elseif action == "Shop" then
			openShop(data)
		end
	end)
	player.CharacterRemoving:Connect(cleanup)

	-- El corcho flota; cuando pica, da tirones
	RunService.RenderStepped:Connect(function()
		local s = session
		local bobber = s and s.Bobber
		if not s or not bobber or s.Done then
			return
		end
		local t = os.clock()
		local y = if s.Bite then -0.35 + math.sin(t * 28) * 0.25 else math.sin(t * 2.4) * 0.08
		local cf = CFrame.new(s.Base + Vector3.new(0, y, 0))
		bobber.CFrame = cf
		local top = bobber:FindFirstChild("BobberTop") :: BasePart?
		if top then
			top.CFrame = cf * CFrame.new(0, 0.4, 0)
		end
	end)
end

return FishingUI
