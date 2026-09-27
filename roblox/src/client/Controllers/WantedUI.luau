-- WantedUI (cliente): el nivel de búsqueda.
--   * Estrellas bajo el reloj (★★★☆☆). Parpadean cuando la policía te ha perdido de vista:
--     si sigue sin verte un rato, te libras.
--   * Avisos: "🚨 La policía te ha visto", "📞 Un testigo ha llamado…", "Has despistado a la policía".
--   * Pantalla de DETENIDO con la multa.
--   * Las hélices de los helicópteros giran y la alarma de la tienda suena (efectos solo aquí).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Wanted = require(ReplicatedStorage.Shared.Wanted)
local Format = require(ReplicatedStorage.Shared.Format)
local Theme = require(script.Parent.Parent.UI.Theme)
local Hud = require(script.Parent.Parent.UI.Hud)
local SoundFx = require(script.Parent.SoundFx)

local WantedUI = {}

local player = Players.LocalPlayer
local create = Theme.create
local rgb = Color3.fromRGB

local GOLD = rgb(255, 205, 60)
local EMPTY = rgb(70, 80, 100)

local stars: { TextLabel } = {}
local bar: Frame

local HOW = {
	Police = "🚨 La policía te ha visto",
	Witness = "📞 Un testigo ha llamado a la policía",
	Passerby = "📞 Alguien ha llamado a la policía",
	Alarm = "🔔 Ha saltado la alarma",
}

local function paint()
	local level = player:GetAttribute("Wanted") or 0
	local searching = player:GetAttribute("WantedSearching") == true
	bar.Visible = level > 0
	local blinkOff = searching and (math.floor(os.clock() * 3) % 2 == 0)
	for i, star in stars do
		local on = i <= level
		star.TextColor3 = if on and not blinkOff then GOLD else EMPTY
		star.TextTransparency = if on then 0 else 0.35
	end
end

-- Pantalla grande (DETENIDO)
local function bigScreen(title: string, subtitle: string, color: Color3)
	local gui = create("ScreenGui", { Name = "Busted", IgnoreGuiInset = true, DisplayOrder = 9, ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })
	local shade = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Parent = gui })
	TweenService:Create(shade, TweenInfo.new(0.5), { BackgroundTransparency = 0.35 }):Play()
	local titleLabel = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(600, 90),
		FontFace = Theme.TitleFace,
		Text = title,
		TextSize = 70,
		TextColor3 = color,
		TextStrokeTransparency = 0.2,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = gui,
	})
	local scale = create("UIScale", { Scale = 1.4, Parent = titleLabel })
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	Theme.label({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.56), Size = UDim2.fromOffset(600, 30), Text = subtitle, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center, Parent = gui })
	task.delay(3.2, function()
		TweenService:Create(shade, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		task.wait(0.4)
		gui:Destroy()
	end)
end

local function onEvent(kind: string, data: any)
	if kind == "Crime" then
		SoundFx.play("Aviso", 1.2, 0.8)
		local text = ("%s · %s  %s"):format(HOW[data.How] or "🚨", data.Crime, string.rep("★", data.Stars))
		Hud.toast("Error", text)
		-- Las estrellas nuevas entran con un salto
		for i = data.Before + 1, data.Stars do
			local star = stars[i]
			if star then
				local s = star:FindFirstChildOfClass("UIScale") :: UIScale
				s.Scale = 2
				TweenService:Create(s, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			end
		end
	elseif kind == "Evaded" then
		Hud.toast("Success", "😎 Has despistado a la policía")
	elseif kind == "Busted" then
		local by = if data.By then " por " .. data.By else ""
		bigScreen("DETENIDO", ("Te han detenido%s · multa de %s"):format(by, Format.money(data.Fine)), rgb(120, 170, 255))
	elseif kind == "Alarm" then
		local entrance = data :: BasePart
		if typeof(entrance) == "Instance" and entrance:IsA("BasePart") then
			for i = 0, 5 do
				task.delay(i * 0.5, function()
					SoundFx.play("Aviso", 1.5, if i % 2 == 0 then 1.6 else 1.2, entrance)
				end)
			end
		end
	end
end

-- Hélices de los helicópteros de la policía (el servidor mueve el helicóptero; aquí giran)
local blades: { [BasePart]: { Hub: BasePart, Phase: number } } = {}
local function trackBlade(blade: Instance)
	if not blade:IsA("BasePart") then
		return
	end
	local hub = blade.Parent and blade.Parent:FindFirstChild("RotorHub") :: BasePart?
	if hub then
		local rel = hub.CFrame:ToObjectSpace(blade.CFrame)
		local _, yaw = rel:ToEulerAnglesYXZ()
		blades[blade] = { Hub = hub, Phase = yaw }
	end
end

function WantedUI.init()
	local gui = create("ScreenGui", { Name = "WantedGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 3, Parent = player:WaitForChild("PlayerGui") })
	local scale = create("UIScale", { Parent = gui })
	local camera = workspace.CurrentCamera
	local function rescale()
		scale.Scale = math.clamp(math.min(camera.ViewportSize.Y / 900, camera.ViewportSize.X / 1700), 0.55, 1.2)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()
	-- Justo debajo del reloj (el reloj mide 10 + 54 arriba en el centro)
	bar = create("Frame", {
		Name = "WantedStars",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 70),
		Size = UDim2.fromOffset(230, 40),
		BackgroundColor3 = rgb(8, 14, 34),
		BackgroundTransparency = 0.25,
		Visible = false,
		Parent = gui,
	}, {
		Theme.corner(10),
		create("UIStroke", { Color = rgb(255, 205, 60), Thickness = 1.5, Transparency = 0.3 }),
	})
	local row = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = bar })
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4), Parent = row })
	for i = 1, Wanted.MaxStars do
		local star = Theme.label({ Size = UDim2.fromOffset(38, 38), Text = "★", TextSize = 32, TextColor3 = EMPTY, TextStrokeTransparency = 0.4, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = i, Parent = row })
		create("UIScale", { Parent = star })
		table.insert(stars, star)
	end

	local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Wanted", 30) :: RemoteEvent
	if remote then
		remote.OnClientEvent:Connect(onEvent)
	end
	player:GetAttributeChangedSignal("Wanted"):Connect(paint)
	paint()

	for _, blade in CollectionService:GetTagged("HeliBlade") do
		trackBlade(blade)
	end
	CollectionService:GetInstanceAddedSignal("HeliBlade"):Connect(trackBlade)
	RunService.RenderStepped:Connect(function()
		if bar.Visible then
			paint()
		end
		local spin = os.clock() * 28
		for blade, info in blades do
			if not blade.Parent or not info.Hub.Parent then
				blades[blade] = nil
			else
				blade.CFrame = info.Hub.CFrame * CFrame.Angles(0, info.Phase + spin, 0)
			end
		end
	end)
end

return WantedUI
