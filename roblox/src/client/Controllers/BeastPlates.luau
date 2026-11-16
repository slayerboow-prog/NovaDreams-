-- BeastPlates: la PLACA encima de cada bestia cercana, como en los MMORPG: su nombre del color de lo difícil que
-- es para TU nivel (gris, verde, amarillo, naranja, rojo: shared/Cosmos/HuntRules.con), su nivel, una ★ si es
-- campeona, 👑 si es jefe, y su barra de vida. Solo pinta: la vida y el nivel los pone el servidor
-- (Services/BeastService: atributos Hp, MaxHp, Nivel, Campeon, Boss; etiqueta «Bestia»).
--   * Como mucho MaxPlates placas a la vez (las más cercanas) y solo a menos de Range studs (jefes, más).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local HuntRules = require(ReplicatedStorage.Shared.Cosmos.HuntRules)

local BeastPlates = {}

BeastPlates.Range = 90
BeastPlates.BossRange = 220
BeastPlates.MaxPlates = 10
BeastPlates.Every = 0.15

local player = Players.LocalPlayer
local rgb = Color3.fromRGB

type Plate = { Gui: BillboardGui, Name: TextLabel, Level: TextLabel, Fill: Frame, Model: Model }
local plates: { [Model]: Plate } = {}

local function holder(): Instance?
	return player:FindFirstChildOfClass("PlayerGui")
end

local function make(model: Model): Plate?
	local root = model.PrimaryPart
	local parent = holder()
	if not root or not parent then
		return nil
	end
	local boss = model:GetAttribute("Boss") == true
	local hum = model:FindFirstChildOfClass("Humanoid")
	local ok, ext = pcall(function()
		return model:GetExtentsSize()
	end)
	local tall = if ok then ext.Y else root.Size.Y * 2
	local hip = if hum then hum.HipHeight else 0
	local gui = Instance.new("BillboardGui")
	gui.Name = "PlacaBestia"
	gui.Adornee = root
	gui.Size = if boss then UDim2.fromOffset(230, 44) else UDim2.fromOffset(160, 34)
	gui.StudsOffsetWorldSpace = Vector3.new(0, math.max(1.5, tall - hip - root.Size.Y / 2 + 1.6), 0)
	gui.MaxDistance = if boss then BeastPlates.BossRange else BeastPlates.Range
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	gui.Enabled = false
	local name = Instance.new("TextLabel")
	name.Name = "Nombre"
	name.BackgroundTransparency = 1
	name.Size = UDim2.new(1, 0, 0, if boss then 22 else 16)
	name.Font = Enum.Font.GothamBold
	name.TextScaled = true
	name.TextStrokeTransparency = 0.35
	name.Parent = gui
	local back = Instance.new("Frame")
	back.Name = "Barra"
	back.AnchorPoint = Vector2.new(0.5, 1)
	back.Position = UDim2.new(0.5, 0, 1, -2)
	back.Size = UDim2.new(1, -38, 0, if boss then 10 else 8)
	back.BackgroundColor3 = rgb(18, 18, 24)
	back.BackgroundTransparency = 0.2
	back.BorderSizePixel = 0
	back.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 3)
	corner.Parent = back
	local stroke = Instance.new("UIStroke")
	stroke.Color = rgb(0, 0, 0)
	stroke.Thickness = 1
	stroke.Parent = back
	local fill = Instance.new("Frame")
	fill.Name = "Vida"
	fill.BorderSizePixel = 0
	fill.BackgroundColor3 = rgb(220, 60, 60)
	fill.Size = UDim2.fromScale(1, 1)
	fill.Parent = back
	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(0, 3)
	fc.Parent = fill
	local level = Instance.new("TextLabel")
	level.Name = "Nivel"
	level.BackgroundTransparency = 1
	level.AnchorPoint = Vector2.new(0, 1)
	level.Position = UDim2.new(0, 0, 1, 0)
	level.Size = UDim2.new(0, 34, 0, if boss then 14 else 12)
	level.Font = Enum.Font.GothamBlack
	level.TextScaled = true
	level.TextStrokeTransparency = 0.3
	level.Parent = gui
	gui.Parent = parent
	return { Gui = gui, Name = name, Level = level, Fill = fill, Model = model }
end

-- El texto y los colores de una placa (aparte para las pruebas)
function BeastPlates.look(model: Instance, myLevel: number?): (string, Color3, string, Color3)
	local boss = model:GetAttribute("Boss") == true
	local champion = model:GetAttribute("Campeon") == true
	local lvl = tonumber(model:GetAttribute("Nivel"))
	local con = HuntRules.con(myLevel, lvl)
	local base = model:GetAttribute("NombreBestia") or model:GetAttribute("BeastName") or "Bestia"
	local text = (if boss then "👑 " elseif champion then "★ " else "") .. tostring(base)
	local nameColor = if champion and not boss then HuntRules.Champion.Color else con.Color
	return text, nameColor, if lvl then tostring(lvl) else "?", con.Color
end

local acc = 0
local function step(dt: number)
	acc += dt
	if acc < BeastPlates.Every then
		return
	end
	acc = 0
	local char = player.Character
	local me = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local wanted: { [Model]: boolean } = {}
	if me then
		local list = {}
		for _, m in CollectionService:GetTagged("Bestia") do
			if m:IsA("Model") and m.PrimaryPart and not m:GetAttribute("EnemyDown") then
				local d = (m.PrimaryPart.Position - me.Position).Magnitude
				local range = if m:GetAttribute("Boss") == true then BeastPlates.BossRange else BeastPlates.Range
				if d <= range then
					table.insert(list, { M = m, D = d })
				end
			end
		end
		table.sort(list, function(a, b)
			return a.D < b.D
		end)
		local myLevel = tonumber(player:GetAttribute("Level"))
		for i = 1, math.min(#list, BeastPlates.MaxPlates) do
			local m = list[i].M :: Model
			wanted[m] = true
			local p = plates[m] or make(m)
			if p then
				plates[m] = p
				local text, nameColor, lvlText, lvlColor = BeastPlates.look(m, myLevel)
				p.Name.Text = text
				p.Name.TextColor3 = nameColor
				p.Level.Text = lvlText
				p.Level.TextColor3 = lvlColor
				local hp = tonumber(m:GetAttribute("Hp")) or 1
				local max = math.max(1, tonumber(m:GetAttribute("MaxHp")) or 1)
				local k = math.clamp(hp / max, 0, 1)
				p.Fill.Size = UDim2.fromScale(k, 1)
				p.Fill.BackgroundColor3 = if k > 0.5 then rgb(220, 60, 60) elseif k > 0.25 then rgb(240, 140, 50) else rgb(250, 210, 60)
				p.Gui.Enabled = true
			end
		end
	end
	for m, p in plates do
		if not wanted[m] or not m.Parent then
			p.Gui:Destroy()
			plates[m] = nil
		end
	end
end

function BeastPlates.init()
	RunService.Heartbeat:Connect(function(dt)
		local ok, err = pcall(step, dt)
		if not ok then
			warn("[BeastPlates] " .. tostring(err))
		end
	end)
end

BeastPlates._plates = plates
BeastPlates._step = step

return BeastPlates
