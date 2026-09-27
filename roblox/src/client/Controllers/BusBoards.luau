-- BusBoards (cliente): los paneles de llegada de las paradas de autobús, con luces ámbar.
--
--   🚏 PLAZA MAYOR                 14:05
--   [L2] → Valmar Norte          3 min
--   [L1] → Playa Dorada       Llegando
--
-- El servidor (BusService) deja cada 2 s los próximos autobuses de cada parada en el atributo
-- "Board" de su poste (BusLines.encodeBoard). Aquí solo se pintan los paneles de las paradas que
-- tienes cerca (el panel es la pieza EtaBoard de la marquesina); los lejanos se quitan.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BusLines = require(ReplicatedStorage.Shared.BusLines)

local BusBoards = {}

local player = Players.LocalPlayer
local RANGE = 130 -- a esta distancia se enciende el panel
local AMBER = Color3.fromRGB(255, 176, 40)
local DIM = Color3.fromRGB(150, 96, 20)
local ROWS = 3

type Row = { Badge: Frame, BadgeText: TextLabel, Where: TextLabel, When: TextLabel }
type View = { Guis: { SurfaceGui }, Rows: { Row }, Clocks: { TextLabel }, Changed: RBXScriptConnection }

local views: { [BasePart]: View } = {}
local folder: Folder

local function led(parent: Instance, props: { [string]: any }): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.TextColor3 = AMBER
	label.FontFace = Font.fromEnum(Enum.Font.Arcade)
	label.TextXAlignment = Enum.TextXAlignment.Left
	for k, v in props do
		(label :: any)[k] = v
	end
	label.Parent = parent
	return label
end

local blink = false

local function render(sign: BasePart, view: View)
	local list = BusLines.decodeBoard(sign:GetAttribute("Board"))
	for n, row in view.Rows do
		local i = (n - 1) % ROWS + 1 -- (las dos caras del panel: filas 1..ROWS y otra vez)
		local a = list[i]
		row.Badge.Visible = a ~= nil
		if a then
			local def = BusLines.byId[a.Line]
			row.Badge.BackgroundColor3 = if def then BusLines.color(def) else DIM
			row.BadgeText.Text = a.Line
			row.Where.Text = "→ " .. a.Headsign
			local soon = a.AtStop or a.Seconds < 30
			row.When.Text = BusLines.formatEta(a.Seconds, a.AtStop)
			row.When.TextTransparency = if soon and blink then 0.6 else 0
		else
			row.Where.Text = if i == 1 then "Sin servicio ahora" else ""
			row.When.Text = ""
		end
	end
	local h = math.floor(Lighting.ClockTime)
	local m = math.floor((Lighting.ClockTime - h) * 60)
	for _, clock in view.Clocks do
		clock.Text = ("%02d:%02d"):format(h, m)
	end
end

local function open(sign: BasePart)
	local model = sign.Parent
	local board = model and model:FindFirstChild("EtaBoard") :: BasePart?
	if not board then
		return
	end
	local view: View = { Guis = {}, Rows = {}, Clocks = {}, Changed = nil :: any }
	local name = string.upper(tostring(sign:GetAttribute("StopName") or "Parada"))
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Name = "BusBoard"
		gui.Adornee = board
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
		gui.CanvasSize = Vector2.new(540, 150)
		gui.LightInfluence = 0
		gui.Brightness = 1.6
		gui.MaxDistance = RANGE + 40
		gui.Parent = folder
		table.insert(view.Guis, gui)
		local back = Instance.new("Frame")
		back.Size = UDim2.fromScale(1, 1)
		back.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
		back.BorderSizePixel = 0
		back.Parent = gui
		led(back, { Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -140, 0, 30), Text = "🚏 " .. name, TextColor3 = DIM })
		table.insert(view.Clocks, led(back, { Position = UDim2.new(1, -120, 0, 4), Size = UDim2.fromOffset(108, 30), TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Right }))
		for i = 1, ROWS do
			local y = 38 + (i - 1) * 37
			local badge = Instance.new("Frame")
			badge.Position = UDim2.fromOffset(12, y + 3)
			badge.Size = UDim2.fromOffset(52, 30)
			badge.BorderSizePixel = 0
			badge.Parent = back
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = badge
			local badgeText = led(badge, { Size = UDim2.fromScale(1, 1), TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Center })
			local where = led(back, { Position = UDim2.fromOffset(74, y), Size = UDim2.new(1, -240, 0, 34) })
			local when = led(back, { Position = UDim2.new(1, -160, 0, y), Size = UDim2.fromOffset(148, 34), TextXAlignment = Enum.TextXAlignment.Right })
			table.insert(view.Rows, { Badge = badge, BadgeText = badgeText, Where = where, When = when })
		end
	end
	view.Changed = sign:GetAttributeChangedSignal("Board"):Connect(function()
		render(sign, view)
	end)
	views[sign] = view
	render(sign, view)
end

local function close(sign: BasePart)
	local view = views[sign]
	if view then
		view.Changed:Disconnect()
		for _, gui in view.Guis do
			gui:Destroy()
		end
		views[sign] = nil
	end
end

function BusBoards.init()
	folder = Instance.new("Folder")
	folder.Name = "BusBoards"
	folder.Parent = player:WaitForChild("PlayerGui")
	task.spawn(function()
		while true do
			task.wait(0.5)
			blink = not blink
			local camera = workspace.CurrentCamera
			local from = camera and camera.CFrame.Position
			if from then
				for _, sign in CollectionService:GetTagged("BusStop") do
					if sign:IsA("BasePart") and sign:IsDescendantOf(workspace) then
						local near = (sign.Position - from).Magnitude < RANGE
						if near and not views[sign] then
							open(sign)
						elseif not near and views[sign] and (sign.Position - from).Magnitude > RANGE + 30 then
							close(sign)
						end
					end
				end
			end
			for sign, view in views do
				if not sign:IsDescendantOf(workspace) then
					close(sign)
				else
					render(sign, view)
				end
			end
		end
	end)
end

return BusBoards
