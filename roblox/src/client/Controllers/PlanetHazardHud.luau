-- PlanetHazardHud (cliente): el medidor de la DESVENTAJA de los planetas nuevos (marco común de los
-- planetas, docs/planetas/marco-planetas.md). Tefra tiene el suyo (Controllers/TefraHud: calor y sirenas).
--
--   * Atributos que pone Services/PlanetHazardService: Peligro (0..Max), PeligroFase y PeligroId. El nombre,
--     el icono, el color y las pistas de cada fase son del planeta (shared/Cosmos/PlanetRegistry: S.Hazard,
--     S.HazardHints, S.HazardTint).
--   * Va en el hueco del panel de buceo (HudLayout.Items.DivePanel: en los planetas no se bucea), como el
--     de Tefra. En Aviso la pantalla se tiñe un poco con el color del planeta; en Peligro, más, y late.
-- Todo lo decide el servidor; aquí solo se pinta.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Theme = require(script.Parent.Parent.UI.Theme)
local HudLayout = require(script.Parent.Parent.UI.HudLayout)
local PlanetRegistry = require(ReplicatedStorage.Shared.Cosmos.PlanetRegistry)

local PlanetHazardHud = {}

local player = Players.LocalPlayer
local create = Theme.create
local H = Theme.Hud
local rgb = Color3.fromRGB

local PANEL = Vector2.new(360, 78)
local COLORS = { Normal = rgb(120, 200, 255), Aviso = rgb(255, 176, 60), Peligro = rgb(255, 80, 60) }

local gui: ScreenGui
local panel: Frame
local panelScale: UIScale
local mainText: TextLabel
local hintText: TextLabel
local fill: Frame
local tint: Frame

-- Texto y color del medidor (puro: lo prueba test-planetas)
function PlanetHazardHud.line(S: any, value: number, phase: string?): (string, Color3, string)
	local Hz = S and S.Hazard
	local icon = Hz and Hz.Icon or "⚠"
	local label = if Hz then Hz.label(value) else "Peligro"
	local hints = (S and S.HazardHints) or {}
	return ("%s %s · %d"):format(icon, label, math.floor(value + 0.5)), COLORS[phase or "Normal"] or COLORS.Normal, hints[phase or "Normal"] or ""
end

local function place(layout: HudLayout.Layout)
	local k = layout.Scale
	local r = HudLayout.rect(layout.Items.DivePanel, layout.Canvas)
	local fit = math.min(1, r.W / PANEL.X)
	panelScale.Scale = k * fit
	panel.Position = UDim2.fromOffset(math.floor(r.X * k + 0.5), math.floor(r.Y * k + 0.5))
end

local function build()
	gui = create("ScreenGui", { Name = "PlanetHazardHud", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 2, Enabled = false, Parent = player:WaitForChild("PlayerGui") })
	tint = create("Frame", { Name = "Tinte", Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(120, 220, 80), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 0, Active = false, Parent = gui })
	panel = Theme.hudPanel({ Name = "PeligroPanel", Size = UDim2.fromOffset(PANEL.X, PANEL.Y), BackgroundColor3 = H.Navy, BackgroundTransparency = 0.3, CornerRadius = 18, Parent = gui })
	panelScale = create("UIScale", { Parent = panel })
	mainText = create("TextLabel", { Name = "Medidor", Position = UDim2.fromOffset(14, 8), Size = UDim2.fromOffset(332, 26), BackgroundTransparency = 1, Font = Theme.FontBold, TextSize = 22, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, Text = "", Parent = panel })
	local track = create("Frame", { Name = "Track", Position = UDim2.fromOffset(14, 38), Size = UDim2.fromOffset(332, 12), BackgroundColor3 = H.Track, BorderSizePixel = 0, Parent = panel }, { Theme.corner(6) })
	fill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = COLORS.Normal, BorderSizePixel = 0, Parent = track }, { Theme.corner(6) })
	hintText = create("TextLabel", { Name = "Pista", Position = UDim2.fromOffset(14, 54), Size = UDim2.fromOffset(332, 18), BackgroundTransparency = 1, Font = Theme.Font, TextSize = 15, TextColor3 = rgb(200, 210, 230), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = "", Parent = panel })
	HudLayout.onChanged(place)
end

local function update()
	local id = player:GetAttribute("Planeta")
	local value = player:GetAttribute("Peligro")
	local S = if type(id) == "string" and id ~= "Tefra" then PlanetRegistry.get(id) else nil
	local show = S ~= nil and S.Hazard ~= nil and type(value) == "number"
	gui.Enabled = show
	if not show then
		tint.BackgroundTransparency = 1
		return
	end
	local phase = player:GetAttribute("PeligroFase")
	local text, color, hint = PlanetHazardHud.line(S, value, phase)
	mainText.Text = text
	hintText.Text = hint
	fill.Size = UDim2.fromScale(math.clamp(value / S.Hazard.Max, 0, 1), 1)
	fill.BackgroundColor3 = color
	tint.BackgroundColor3 = S.HazardTint or rgb(255, 160, 60)
	local pulse = 0.5 + 0.5 * math.sin(os.clock() * 4)
	tint.BackgroundTransparency = if phase == "Peligro" then 0.8 + 0.08 * pulse elseif phase == "Aviso" then 0.92 else 1
end

function PlanetHazardHud.init()
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
			warn("[PlanetHazardHud] " .. tostring(err))
		end
	end)
end

return PlanetHazardHud
