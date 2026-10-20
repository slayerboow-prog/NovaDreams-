-- DiveHud (cliente): el HUD de buceo del mar hondo, como en docs/mar/referencia-submarina.png.
--
--   * Panel a la izquierda, bajo tu estado (HudLayout.Items.DivePanel): profundidad en metros (con el
--     límite de tu equipo: en ámbar cerca, en rojo pasado), «Vida marina» (la zona: Arrecife Escarlata,
--     Laberinto de Kelp…), temperatura del agua y el oxígeno con su barra (min:s).
--   * Cápsula del objetivo bajo la hora (HudLayout.Items.DiveObjective, en el sitio del GPS): la misión
--     del mar que toca (o el sitio sin descubrir más cerca), a cuántos metros/km y una flecha hacia él.
--   * Buceando, fuera el GPS y las notas (UI/DiveFocus); la barra de aire de arriba (DivingUI) se esconde
--     porque el aire va en el panel.
--   * Botones (móvil): Bucear y Subir (DivingUI), Correr = nadar rápido (también vertical), Atacar
--     (espanta al megalodón o al tentáculo del kraken; con la cámara, «Fotografiar»), Cambiar (mano o
--     cámara), Linterna e Interactuar (los de siempre). Ordenador: V atacar/fotografiar y T cambiar.
-- Todo lo que importa (aire, presión, daño, fotos) lo decide el servidor; aquí solo se enseña y se pide.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Theme = require(script.Parent.Parent.UI.Theme)
local HudLayout = require(script.Parent.Parent.UI.HudLayout)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local DiveFocus = require(script.Parent.Parent.UI.DiveFocus)
local Hud = require(script.Parent.Parent.UI.Hud)
local Ocean = require(ReplicatedStorage.Shared.Sea.Ocean)
local OceanBiomes = require(ReplicatedStorage.Shared.Sea.OceanBiomes)
local SeaDiving = require(ReplicatedStorage.Shared.Sea.Diving)
local SeaBiome = require(script.Parent.SeaBiome)
local SeaLife = require(script.Parent.SeaLife)
local Swimming = require(script.Parent.Swimming)

local DiveHud = {}

local player = Players.LocalPlayer
local create = Theme.create
local H = Theme.Hud
local rgb = Color3.fromRGB
local AMBER, RED = rgb(255, 196, 70), rgb(255, 90, 90)

local gui: ScreenGui
local panel: Frame
local panelScale: UIScale
local objective: Frame
local objectiveScale: UIScale
local depthText: TextLabel
local limitText: TextLabel
local zoneText: TextLabel
local tempText: TextLabel
local airText: TextLabel
local airFill: Frame
local goalTitle: TextLabel
local goalLine: TextLabel
local goalArrow: TextLabel

local tool = "Mano" -- Mano | Camara
local shown = false
local diving = false

-- Lo que se enseña (puro: lo prueba test-mar)
function DiveHud.format(meters: number): string
	if meters < 1000 then
		return ("%d m"):format(math.floor(meters + 0.5))
	end
	return (("%.1f km"):format(meters / 1000):gsub("%.", ","))
end

function DiveHud.clock(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	return ("%d:%02d"):format(seconds // 60, seconds % 60)
end

-- El objetivo: la misión del mar que toca o el sitio sin descubrir más cerca. found = { [id] = true }
function DiveHud.goal(missionId: string?, found: { [string]: boolean }, from: Vector3): ({ [string]: any }?, string?)
	local mission = missionId and SeaDiving.MissionById[missionId]
	-- (v122) misión de «cualquiera de estos sitios»: el más cercano sin descubrir (el jardín de coral de
	-- tu playa, no el Arco de Coral a 2,6 km)
	if mission and mission.FoundAny then
		local best, bestD = nil, math.huge
		for _, id in mission.FoundAny do
			local poi = Ocean.PoiById[id]
			if poi and not found[id] then
				local d = (Vector3.new(poi.X, from.Y, poi.Z) - from).Magnitude
				if d < bestD then
					best, bestD = poi, d
				end
			end
		end
		if best then
			return best, mission.Title
		end
	end
	if mission and mission.Target then
		local poi = Ocean.PoiById[mission.Target]
		if poi then
			return poi, mission.Title
		end
	end
	local best, bestD = nil, math.huge
	for _, poi in Ocean.Pois do
		if not found[poi.Id] then
			local d = (Vector3.new(poi.X, from.Y, poi.Z) - from).Magnitude
			if d < bestD then
				best, bestD = poi, d
			end
		end
	end
	return best, if best then "Explora: " .. best.Name else nil
end

local function place(layout: HudLayout.Layout)
	local k = layout.Scale
	local r = HudLayout.rect(layout.Items.DivePanel, layout.Canvas)
	local design = HudLayout.Sizes.DivePanel
	-- (se dibuja a su tamaño de diseño y se encoge si en el móvil hay menos sitio)
	local fit = math.min(1, r.H / design.Y)
	panelScale.Scale = k * fit
	panel.Position = UDim2.fromOffset(math.floor(r.X * k + 0.5), math.floor(r.Y * k + 0.5))
	local o = HudLayout.rect(layout.Items.DiveObjective, layout.Canvas)
	objectiveScale.Scale = k
	objective.Position = UDim2.fromOffset(math.floor((o.X + o.W / 2) * k + 0.5), math.floor(o.Y * k + 0.5))
end

local function row(parent: Instance, y: number, icon: string, caption: string): TextLabel
	create("TextLabel", { Name = "Icon", Position = UDim2.fromOffset(12, y), Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1, Font = Theme.FontBold, TextScaled = true, Text = icon, Parent = parent })
	create("TextLabel", { Name = "Caption", Position = UDim2.fromOffset(60, y - 2), Size = UDim2.fromOffset(180, 18), BackgroundTransparency = 1, Font = Theme.Font, TextSize = 17, TextColor3 = rgb(170, 205, 235), TextXAlignment = Enum.TextXAlignment.Left, Text = caption, Parent = parent })
	return create("TextLabel", { Name = "Value", Position = UDim2.fromOffset(60, y + 15), Size = UDim2.fromOffset(280, 32), BackgroundTransparency = 1, Font = Theme.FontBold, TextSize = 30, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, Text = "", Parent = parent })
end

local function build()
	gui = create("ScreenGui", { Name = "DiveHud", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 2, Enabled = false, Parent = player:WaitForChild("PlayerGui") })
	local size = HudLayout.Sizes.DivePanel
	panel = Theme.hudPanel({ Name = "DivePanel", Size = UDim2.fromOffset(size.X, size.Y), BackgroundColor3 = H.Navy, BackgroundTransparency = 0.3, CornerRadius = 18, Parent = gui })
	panelScale = create("UIScale", { Parent = panel })
	depthText = row(panel, 8, "🌊", "Profundidad")
	limitText = create("TextLabel", { Name = "Limit", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 30), Size = UDim2.fromOffset(150, 22), BackgroundTransparency = 1, Font = Theme.FontBold, TextSize = 17, TextColor3 = rgb(170, 205, 235), TextXAlignment = Enum.TextXAlignment.Right, Text = "", Parent = panel })
	zoneText = row(panel, 56, "🐟", "Vida marina")
	-- (los nombres largos, como «Cañón de las Catedrales», se encogen para caber en el panel)
	zoneText.TextScaled = true
	create("UITextSizeConstraint", { MaxTextSize = 30, MinTextSize = 14, Parent = zoneText })
	tempText = row(panel, 104, "🌡️", "Temperatura")
	-- Oxígeno
	airText = create("TextLabel", { Name = "Air", Position = UDim2.fromOffset(12, 154), Size = UDim2.fromOffset(336, 22), BackgroundTransparency = 1, Font = Theme.FontBold, TextSize = 20, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, Text = "💨 Oxígeno", Parent = panel })
	local track = create("Frame", { Name = "AirTrack", Position = UDim2.fromOffset(12, 180), Size = UDim2.fromOffset(336, 12), BackgroundColor3 = H.Track, BorderSizePixel = 0, Parent = panel }, { Theme.corner(6) })
	airFill = create("Frame", { Name = "AirFill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(90, 200, 255), BorderSizePixel = 0, Parent = track }, { Theme.corner(6) })
	-- Objetivo
	local osize = HudLayout.Sizes.DiveObjective
	objective = Theme.hudPanel({ Name = "DiveObjective", AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(osize.X, osize.Y), BackgroundColor3 = H.Navy, BackgroundTransparency = 0.3, CornerRadius = 32, Parent = gui })
	objectiveScale = create("UIScale", { Parent = objective })
	goalArrow = create("TextLabel", { Name = "Arrow", Position = UDim2.fromOffset(10, 8), Size = UDim2.fromOffset(48, 48), BackgroundTransparency = 1, Font = Theme.FontBold, TextScaled = true, TextColor3 = H.Glow, Text = "➤", Parent = objective })
	goalTitle = create("TextLabel", { Name = "Title", Position = UDim2.fromOffset(66, 6), Size = UDim2.fromOffset(400, 28), BackgroundTransparency = 1, Font = Theme.FontBold, TextSize = 24, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = "", Parent = objective })
	goalLine = create("TextLabel", { Name = "Line", Position = UDim2.fromOffset(66, 34), Size = UDim2.fromOffset(400, 22), BackgroundTransparency = 1, Font = Theme.Font, TextSize = 18, TextColor3 = rgb(170, 205, 235), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = "", Parent = objective })
	HudLayout.onChanged(place)
end

local function rootOf(): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function foundSet(): { [string]: boolean }
	local set = {}
	for id in string.gmatch(player:GetAttribute("SeaFound") or "", "[^,]+") do
		set[id] = true
	end
	return set
end

local remote: RemoteEvent? = nil
local function strike()
	local root = rootOf()
	if not root or not remote then
		return
	end
	if tool == "Camara" then
		local beast, at = SeaLife.nearestBeast(root.Position)
		if beast and at and (at - root.Position).Magnitude <= SeaDiving.Photo.Range * 1.1 then
			remote:FireServer("Photo", { Beast = beast })
			pcall(function()
				local flash = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = gui })
				task.delay(0.12, function()
					flash:Destroy()
				end)
			end)
		else
			Hud.toast("Info", "📷 No hay ninguna criatura grande cerca para fotografiar.")
		end
		return
	end
	remote:FireServer("Strike")
end

local function cycleTool()
	tool = if tool == "Mano" then "Camara" else "Mano"
	pcall(TouchLayout.setLabel, "BucearAtacar", if tool == "Camara" then "Fotografiar" else "Atacar")
	pcall(TouchLayout.setIcon, "BucearAtacar", if tool == "Camara" then "camara" else "espada")
	Hud.toast("Info", if tool == "Camara" then "📷 Cámara: «Fotografiar» a una criatura grande (megalodón, kraken)" else "✋ Mano: «Atacar» espanta al megalodón o al tentáculo")
end

local function update()
	local root = rootOf()
	local swimming = Swimming.isSwimming()
	local sea = SeaBiome.state()
	local want = swimming and root ~= nil and sea.Sea
	diving = want and Swimming.mode() == "Dive"
	if want ~= shown then
		shown = want
		gui.Enabled = want
		player:SetAttribute("DiveHudOn", if want then true else nil)
		TouchLayout.refresh()
	end
	if diving then
		DiveFocus.enter()
	else
		DiveFocus.exit()
	end
	if not want or not root then
		return
	end
	local meters = Ocean.meters(root.Position.Y)
	local limit = player:GetAttribute("DiveLimit") or SeaDiving.Gear.Base.Depth
	local pressure = player:GetAttribute("DivePressure") or "Ok"
	depthText.Text = DiveHud.format(meters)
	depthText.TextColor3 = if pressure == "Over" then RED elseif pressure == "Warn" then AMBER else Color3.new(1, 1, 1)
	limitText.Text = ("límite %d m"):format(limit)
	limitText.TextColor3 = if pressure == "Over" then RED elseif pressure == "Warn" then AMBER else rgb(170, 205, 235)
	local zone = OceanBiomes.zone(sea.Zone)
	zoneText.Text = if zone then zone.Name else "—"
	tempText.Text = ("%d °C"):format(math.floor(OceanBiomes.temperature(sea.Zone, meters) + 0.5))
	local oxygen, max = player:GetAttribute("Oxygen"), player:GetAttribute("OxygenMax")
	if type(oxygen) == "number" and type(max) == "number" and max > 0 then
		local k = math.clamp(oxygen / max, 0, 1)
		airFill.Size = UDim2.fromScale(k, 1)
		airFill.BackgroundColor3 = if k < 0.25 then RED elseif k < 0.5 then AMBER else rgb(90, 200, 255)
		airText.Text = ("💨 Oxígeno %s%s"):format(DiveHud.clock(oxygen), if oxygen <= 0 then " · ¡SUBE A RESPIRAR!" else "")
	end
	-- Objetivo
	local poi, title = DiveHud.goal(player:GetAttribute("SeaMission"), foundSet(), root.Position)
	objective.Visible = poi ~= nil
	if poi then
		local at = Ocean.poiPosition(poi)
		local flat = Vector3.new(at.X - root.Position.X, 0, at.Z - root.Position.Z)
		local dist = flat.Magnitude / Ocean.StudsPerMeter
		local progress = player:GetAttribute("SeaMissionProgress")
		goalTitle.Text = title or poi.Name
		local depthGoal = Ocean.meters(at.Y)
		goalLine.Text = ("%s · %s · prof. %d m%s"):format(DiveHud.format(dist), poi.Name, math.floor(depthGoal + 0.5), if progress then " · " .. progress else "")
		local cam = workspace.CurrentCamera.CFrame.LookVector
		local camYaw = math.atan2(cam.X, -cam.Z)
		local goalYaw = math.atan2(flat.X, -flat.Z)
		goalArrow.Rotation = math.deg(goalYaw - camYaw) - 90
	end
end

function DiveHud.init()
	build()
	remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Sea") :: RemoteEvent
	local function underwaterNow(): boolean
		return shown and diving
	end
	TouchLayout.register({
		Id = "BucearAtacar", Icon = "espada", Label = "Atacar", Slot = "Agacharse", Priority = 8.5, Key = "V", Pad = "X",
		Visible = underwaterNow,
		Callback = strike,
	})
	TouchLayout.register({
		Id = "BucearCambiar", Icon = "habilidades", Label = "Cambiar", Slot = "Esquivar", Priority = 8.6, Key = "T", Pad = "LB",
		Visible = underwaterNow,
		Active = function(): boolean
			return tool == "Camara"
		end,
		Callback = cycleTool,
	})
	ContextActionService:BindAction("DiveStrike", function(_, state)
		if state == Enum.UserInputState.Begin and underwaterNow() then
			strike()
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.V, Enum.KeyCode.ButtonX)
	ContextActionService:BindAction("DiveTool", function(_, state)
		if state == Enum.UserInputState.Begin and underwaterNow() then
			cycleTool()
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.T)
	remote.OnClientEvent:Connect(function(kind, data)
		if kind == "Found" and type(data) == "table" then
			pcall(function()
				Theme.pop(objective, 1.08)
			end)
		end
	end)
	local since = 0
	RunService.Heartbeat:Connect(function(dt)
		since += dt
		if since < 0.15 then
			return
		end
		since = 0
		local ok, err = pcall(update)
		if not ok then
			warn("[DiveHud] " .. tostring(err))
		end
	end)
end

return DiveHud
