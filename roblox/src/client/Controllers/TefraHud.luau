-- TefraHud (cliente): lo que enseña la pantalla en Tefra (docs/planetas/tefra-misiones.md).
--
--   * El medidor de 🌡 CALOR (atributos TefraCalor y TefraFase que pone Services/TefraService): en el hueco
--     del panel de buceo (HudLayout.Items.DivePanel: en Tefra no se bucea), con su barra y el aviso de la
--     fase. En Aviso la pantalla se tiñe un poco de naranja; en Peligro, más, y late.
--   * Las SIRENAS de los bombardeos (atributo TefraWar de workspace, JSON): «🚨 Bombardeo en 34 s ·
--     corre a un refugio 🛡», luego «💥 Fuego de Ovilla» y, después, «🕊 Han parado».
-- Todo lo decide el servidor; aquí solo se pinta.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Theme = require(script.Parent.Parent.UI.Theme)
local HudLayout = require(script.Parent.Parent.UI.HudLayout)

local TefraHud = {}

local player = Players.LocalPlayer
local create = Theme.create
local H = Theme.Hud
local rgb = Color3.fromRGB

local PANEL = Vector2.new(360, 96)
local COLORS = { Normal = rgb(120, 200, 255), Aviso = rgb(255, 176, 60), Peligro = rgb(255, 80, 60) }

local gui: ScreenGui
local panel: Frame
local panelScale: UIScale
local heatText: TextLabel
local phaseText: TextLabel
local fill: Frame
local warText: TextLabel
local tint: Frame

-- Lo que dice el aviso de la guerra (puro: lo prueba test-tefra)
function TefraHud.warLine(war: { [string]: any }?, serverNow: number): string?
	if type(war) ~= "table" then
		return nil
	end
	if war.State == "Aviso" then
		local left = math.max(0, math.floor((tonumber(war.FireAt) or serverNow) - serverNow + 0.5))
		return ("🚨 Bombardeo en %d s · corre a un refugio 🛡"):format(left)
	elseif war.State == "Fuego" then
		return "💥 ¡Fuego de Ovilla! Quédate en el refugio"
	elseif war.State == "Despues" then
		return "🕊 Han parado · pan de sirena en la Panadería"
	end
	return nil
end

-- Texto y color del medidor (puro)
function TefraHud.heatLine(heat: number, phase: string?): (string, Color3)
	local label = if phase == "Peligro" then "¡Demasiado calor!" elseif phase == "Aviso" then "Hace mucho calor" else "Calor"
	return ("🌡 %s · %d"):format(label, math.floor(heat + 0.5)), COLORS[phase or "Normal"] or COLORS.Normal
end

local function place(layout: HudLayout.Layout)
	local k = layout.Scale
	local r = HudLayout.rect(layout.Items.DivePanel, layout.Canvas)
	local fit = math.min(1, r.W / PANEL.X)
	panelScale.Scale = k * fit
	panel.Position = UDim2.fromOffset(math.floor(r.X * k + 0.5), math.floor(r.Y * k + 0.5))
end

local function build()
	gui = create("ScreenGui", { Name = "TefraHud", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 2, Enabled = false, Parent = player:WaitForChild("PlayerGui") })
	tint = create("Frame", { Name = "Calor", Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(255, 110, 30), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 0, Active = false, Parent = gui })
	panel = Theme.hudPanel({ Name = "TefraPanel", Size = UDim2.fromOffset(PANEL.X, PANEL.Y), BackgroundColor3 = H.Navy, BackgroundTransparency = 0.3, CornerRadius = 18, Parent = gui })
	panelScale = create("UIScale", { Parent = panel })
	heatText = create("TextLabel", { Name = "Heat", Position = UDim2.fromOffset(14, 8), Size = UDim2.fromOffset(332, 26), BackgroundTransparency = 1, Font = Theme.FontBold, TextSize = 22, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, Text = "🌡 Calor", Parent = panel })
	local track = create("Frame", { Name = "Track", Position = UDim2.fromOffset(14, 38), Size = UDim2.fromOffset(332, 12), BackgroundColor3 = H.Track, BorderSizePixel = 0, Parent = panel }, { Theme.corner(6) })
	fill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = COLORS.Normal, BorderSizePixel = 0, Parent = track }, { Theme.corner(6) })
	phaseText = create("TextLabel", { Name = "Phase", Position = UDim2.fromOffset(14, 54), Size = UDim2.fromOffset(332, 18), BackgroundTransparency = 1, Font = Theme.Font, TextSize = 15, TextColor3 = rgb(200, 210, 230), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = "", Parent = panel })
	warText = create("TextLabel", { Name = "War", Position = UDim2.fromOffset(14, 72), Size = UDim2.fromOffset(332, 20), BackgroundTransparency = 1, Font = Theme.FontBold, TextSize = 16, TextColor3 = rgb(255, 120, 100), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = "", Parent = panel })
	HudLayout.onChanged(place)
end

local function decodeWar(): { [string]: any }?
	local raw = workspace:GetAttribute("TefraWar")
	if type(raw) ~= "string" or raw == "" then
		return nil
	end
	local ok, value = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	return if ok and type(value) == "table" then value else nil
end

local function update()
	local heat = player:GetAttribute("TefraCalor")
	local onTefra = player:GetAttribute("Planeta") == "Tefra"
	local war = if onTefra then decodeWar() else nil
	local show = onTefra and (type(heat) == "number" or war ~= nil)
	gui.Enabled = show
	if not show then
		tint.BackgroundTransparency = 1
		return
	end
	local phase = player:GetAttribute("TefraFase")
	local h = if type(heat) == "number" then heat else 0
	local text, color = TefraHud.heatLine(h, phase)
	heatText.Text = text
	fill.Size = UDim2.fromScale(math.clamp(h / 100, 0, 1), 1)
	fill.BackgroundColor3 = color
	phaseText.Text = if phase == "Peligro" then "Pierdes vida: 🧴 gel térmico (mochila) o un refugio 🛡"
		elseif phase == "Aviso" then "Vas más lento. Aléjate de la lava o usa gel"
		else "Junto a la lava y en las Fundiciones sube rápido"
	local serverNow = workspace:GetServerTimeNow()
	warText.Text = TefraHud.warLine(war, serverNow) or ""
	-- El tinte del calor (y en Peligro, late)
	local pulse = 0.5 + 0.5 * math.sin(os.clock() * 4)
	tint.BackgroundTransparency = if phase == "Peligro" then 0.8 + 0.08 * pulse elseif phase == "Aviso" then 0.92 else 1
end

function TefraHud.init()
	build()
	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		acc += dt
		if acc < 0.1 then
			return
		end
		acc = 0
		local ok, err = pcall(update)
		if not ok then
			warn("[TefraHud] " .. tostring(err))
		end
	end)
end

return TefraHud
