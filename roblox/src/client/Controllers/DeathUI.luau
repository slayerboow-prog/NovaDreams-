-- DeathUI (cliente): la pantalla de HAS MUERTO y el aviso al despertar en el hospital
-- (HospitalService). La pantalla se tiñe de rojo, sale la cuenta atrás y, al reaparecer,
-- se aclara con el aviso de la factura.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.UI.Theme)
local Hud = require(script.Parent.Parent.UI.Hud)
local Format = require(ReplicatedStorage.Shared.Format)

local DeathUI = {}

local player = Players.LocalPlayer
local create = Theme.create
local rgb = Color3.fromRGB

local gui: ScreenGui
local shade: Frame
local title: TextLabel
local subtitle: TextLabel
local showing = 0

local function show(seconds: number, jailed: boolean)
	showing += 1
	local id = showing
	gui.Enabled = true
	shade.BackgroundTransparency = 1
	title.TextTransparency = 1
	subtitle.TextTransparency = 1
	TweenService:Create(shade, TweenInfo.new(1.2), { BackgroundTransparency = 0.25 }):Play()
	TweenService:Create(title, TweenInfo.new(0.8), { TextTransparency = 0 }):Play()
	TweenService:Create(subtitle, TweenInfo.new(0.8), { TextTransparency = 0 }):Play()
	local scale = title:FindFirstChildOfClass("UIScale") :: UIScale
	scale.Scale = 1.3
	TweenService:Create(scale, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	local place = if jailed then "en la enfermería de la prisión" else "en el hospital"
	for left = seconds, 1, -1 do
		if showing ~= id then
			return
		end
		subtitle.Text = ("Despertarás %s en %d…"):format(place, left)
		task.wait(1)
	end
end

local function hide()
	showing += 1
	local id = showing
	TweenService:Create(shade, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(title, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
	TweenService:Create(subtitle, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
	task.delay(0.9, function()
		if showing == id then
			gui.Enabled = false
		end
	end)
end

function DeathUI.init()
	gui = create("ScreenGui", { Name = "DeathScreen", IgnoreGuiInset = true, DisplayOrder = 10, ResetOnSpawn = false, Enabled = false, Parent = player:WaitForChild("PlayerGui") })
	shade = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(70, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = gui }, {
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(40, 0, 0), rgb(120, 10, 10)) }),
	})
	title = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.44),
		Size = UDim2.new(1, -32, 0, 90),
		FontFace = Theme.TitleFace,
		Text = "HAS MUERTO",
		TextSize = 72,
		TextScaled = true,
		TextColor3 = rgb(230, 40, 40),
		TextStrokeTransparency = 0.3,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = gui,
	})
	create("UITextSizeConstraint", { MaxTextSize = 72, Parent = title })
	create("UIScale", { Parent = title })
	subtitle = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.56),
		Size = UDim2.new(1, -32, 0, 30),
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = gui,
	})

	local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Hospital", 30) :: RemoteEvent?
	if not remote then
		return
	end
	remote.OnClientEvent:Connect(function(kind: string, data: any)
		data = if type(data) == "table" then data else {}
		if kind == "Died" then
			task.spawn(show, tonumber(data.Seconds) or 6, data.Jailed == true)
		elseif kind == "Revived" then
			hide()
			if data.Trial then
				Hud.toast("Info", "⚖️ Te han curado y vuelves al banquillo: el juicio sigue")
			elseif data.Jailed then
				Hud.toast("Info", "🏥 Te han curado en la enfermería de la prisión")
			elseif (data.Bill or 0) > 0 then
				Hud.toast("Money", ("🏥 Te has despertado en el hospital · factura: %s"):format(Format.money(data.Bill)))
			else
				Hud.toast("Info", "🏥 Te has despertado en el hospital")
			end
		end
	end)
end

return DeathUI
