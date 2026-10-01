-- CombatHud: las barras de la pelea, debajo de tu estado (arriba a la izquierda), solo en plena pelea.
--
--   AGUANTE  verde, en 3 tramos (cada desvanecerse gasta uno; se recupera solo)
--   ENERGÍA  verde-cian de la Grieta; ámbar y brillando cuando está llena (definitiva lista).
--            Solo si la Saga de la Grieta ha despertado tu energía (o en Modo pruebas)
--   GUARDIA  azul, solo mientras te cubres o si la tienes gastada
--   El poder elegido (nombre y lo que cuesta) y el contador de golpes seguidos («×5 GOLPES»).
-- Los valores vienen del servidor (atributos Aguante, Energia, Guardia y Powers del jugador).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)
local HudLayout = require(script.Parent.HudLayout)
local Combat = require(game:GetService("ReplicatedStorage").Shared.Combat)
local Powers = require(game:GetService("ReplicatedStorage").Shared.Powers)

local CombatHud = {}

local create = Theme.create
local H = Theme.Hud
local rgb = Color3.fromRGB
local player = Players.LocalPlayer

CombatHud.Size = Vector2.new(330, 112)

local gui: ScreenGui? = nil
local panel: Frame? = nil
local bars: { [string]: { Row: Frame, Fill: Frame, Text: TextLabel } } = {}
local powerLabel: TextLabel? = nil
local comboLabel: TextLabel? = nil
local shown = false
local comboCount, comboAt = 0, 0
local selected: string? = nil

local function bar(parent: Frame, name: string, caption: string, color: Color3, order: number, segments: number?)
	local row = create("Frame", { Name = name, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, LayoutOrder = order, Parent = parent })
	Theme.label({ Name = "Caption", Size = UDim2.new(0, 84, 1, 0), Text = caption, Font = Theme.FontBold, TextSize = 13, TextStrokeTransparency = 0.5, Parent = row })
	local track = create("Frame", { Name = "Track", Position = UDim2.fromOffset(88, 4), Size = UDim2.new(1, -130, 0, 12), BackgroundColor3 = H.Track, BorderSizePixel = 0, Parent = row }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	local fill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BorderSizePixel = 0, Parent = track }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	for i = 1, (segments or 1) - 1 do
		create("Frame", { Name = "Tramo", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(i / (segments :: number), 0), Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = H.Navy, BorderSizePixel = 0, ZIndex = 2, Parent = track })
	end
	local text = Theme.label({ Name = "Value", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 38, 1, 0), Text = "", TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
	bars[name] = { Row = row, Fill = fill, Text = text }
end

local function place(layout: HudLayout.Layout)
	if not panel then
		return
	end
	local status = layout.Items.Status
	local rect = HudLayout.rect(status, layout.Canvas)
	panel.AnchorPoint = Vector2.new(0, 0)
	panel.Position = UDim2.fromOffset(rect.X, rect.Y + rect.H + 8)
	panel.Size = UDim2.fromOffset(CombatHud.Size.X, CombatHud.Size.Y)
end

function CombatHud.init()
	if gui then
		return
	end
	local playerGui = player:WaitForChild("PlayerGui")
	gui = create("ScreenGui", { Name = "CombatHud", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 3, Enabled = true, Parent = playerGui })
	HudLayout.scaleGui(gui :: ScreenGui)
	panel = Theme.hudPanel({ Name = "Barras", BackgroundTransparency = 0.45, CornerRadius = 10, Visible = false, Parent = gui })
	local p = panel :: Frame
	create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), Parent = p })
	create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = p })
	bar(p, "Aguante", "AGUANTE", rgb(90, 220, 120), 1, 3)
	bar(p, "Energia", "ENERGÍA", rgb(86, 246, 196), 2)
	bar(p, "Guardia", "GUARDIA", rgb(120, 180, 255), 3)
	powerLabel = Theme.label({ Name = "Poder", Size = UDim2.new(1, 0, 0, 18), Text = "", TextSize = 13, TextColor3 = rgb(255, 222, 150), TextStrokeTransparency = 0.5, LayoutOrder = 4, Parent = p })
	comboLabel = Theme.label({
		Name = "Combo",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1, 14, 0.5, 0),
		Size = UDim2.fromOffset(170, 44),
		FontFace = Theme.TitleFace,
		Text = "",
		TextSize = 30,
		TextColor3 = rgb(255, 214, 90),
		TextStrokeTransparency = 0.15,
		Visible = false,
		Parent = p,
	})
	HudLayout.onChanged(place)
end

local function setBar(name: string, value: number?, max: number, visible: boolean)
	local b = bars[name]
	if not b then
		return
	end
	b.Row.Visible = visible
	if not visible then
		return
	end
	local v = math.clamp(value or max, 0, max)
	b.Fill.Size = UDim2.fromScale(v / max, 1)
	Theme.setText(b.Text, tostring(math.floor(v + 0.5)))
	if name == "Energia" then
		b.Fill.BackgroundColor3 = if v >= max then rgb(255, 200, 90) else rgb(86, 246, 196)
	elseif name == "Aguante" then
		b.Fill.BackgroundColor3 = if v < Combat.VanishCost then rgb(230, 120, 70) else rgb(90, 220, 120)
	end
end

-- El poder elegido (CombatController lo cambia con el selector)
function CombatHud.setSelected(id: string?)
	selected = id
end

-- Golpe tuyo que entra: sube el contador (se apaga solo si paras)
function CombatHud.countHit()
	local now = os.clock()
	if now - comboAt > 1.6 then
		comboCount = 0
	end
	comboCount += 1
	comboAt = now
	local label = comboLabel
	if label and comboCount >= 2 then
		label.Visible = true
		Theme.setText(label, ("×%d GOLPES"):format(comboCount))
		local scale = label:FindFirstChildOfClass("UIScale") or create("UIScale", { Parent = label })
		scale.Scale = 1.35
		TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
end

-- Se llama a menudo (CombatController): enseña o esconde y pone los valores
function CombatHud.update(inCombat: boolean, blocking: boolean)
	if not panel then
		return
	end
	local set = Powers.decode(player:GetAttribute("Powers"))
	local guard = player:GetAttribute("Guardia")
	local want = inCombat
	if want ~= shown then
		shown = want
		panel.Visible = want
	end
	if comboLabel and os.clock() - comboAt > 1.6 and comboLabel.Visible then
		comboLabel.Visible = false
		comboCount = 0
	end
	if not want then
		return
	end
	setBar("Aguante", player:GetAttribute("Aguante"), Combat.StaminaMax, true)
	setBar("Energia", player:GetAttribute("Energia"), Combat.EnergyMax, set.Energia == true)
	setBar("Guardia", guard, Combat.GuardMax, blocking or (type(guard) == "number" and guard < Combat.GuardMax - 0.5))
	local label = powerLabel
	if label then
		local p = Powers.get(selected)
		label.Visible = p ~= nil and set[p.Id] == true
		if label.Visible and p then
			Theme.setText(label, ("⚡ %s · %d de energía"):format(p.Name, p.Cost))
		end
	end
end

function CombatHud.isShown(): boolean
	return shown
end

return CombatHud
