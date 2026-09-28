-- CanonMarkers (cliente): las misiones canónicas de la saga se ven SIEMPRE hasta que las haces.
--   * En el mundo: un pilar de luz dorado con una tarjeta «❗ Título» encima (se ve de lejos).
--   * En el minimapa y en el mapa grande: MapUI lee CanonMarkers.list().
-- El servidor manda la lista en el atributo del jugador «CanonMarks» (JSON; LifeStoryService).
-- Al llegar al sitio, la misión empieza sola.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local CanonMarkers = {}

local player = Players.LocalPlayer
local GOLD = Color3.fromRGB(255, 200, 60)
local NEAR = 22 -- a menos de esto ya estás allí: el cartel se quita

export type Mark = { Id: string, Title: string, X: number, Y: number, Z: number, From: number?, To: number? }

local marks: { Mark } = {}
local pillars: { [string]: Model } = {}
local folder: Folder

local function hoursText(mark: Mark): string
	if mark.From and mark.To then
		return (" · DE %d:00 A %d:00"):format(mark.From, mark.To)
	end
	return ""
end

local function makePillar(mark: Mark): Model
	local model = Instance.new("Model")
	model.Name = "Canon_" .. mark.Id
	local base = Vector3.new(mark.X, mark.Y, mark.Z)
	local beam = Instance.new("Part")
	beam.Name = "Pilar"
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CanTouch = false
	beam.CastShadow = false
	beam.Material = Enum.Material.Neon
	beam.Color = GOLD
	beam.Transparency = 0.55
	beam.Shape = Enum.PartType.Cylinder
	beam.Size = Vector3.new(120, 2.2, 2.2)
	beam.CFrame = CFrame.new(base + Vector3.new(0, 60, 0)) * CFrame.Angles(0, 0, math.rad(90))
	beam.Parent = model
	local ring = Instance.new("Part")
	ring.Name = "Anillo"
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Material = Enum.Material.Neon
	ring.Color = GOLD
	ring.Transparency = 0.3
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.3, 9, 9)
	ring.CFrame = CFrame.new(base + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = model
	-- Cartel: una tarjeta pequeña (pastilla oscura con borde dorado, el ❗ en un círculo y el título en
	-- blanco) bien por encima del sitio. De tamaño fijo en pantalla: no se hace enorme al acercarte
	local gui = Instance.new("BillboardGui")
	gui.Name = "Cartel"
	gui.Size = UDim2.fromOffset(300, 64)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 16, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 900
	gui.LightInfluence = 0
	gui.Parent = ring
	local card = Instance.new("Frame")
	card.Name = "Tarjeta"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.fromOffset(0, 52)
	card.AutomaticSize = Enum.AutomaticSize.X
	card.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
	card.BackgroundTransparency = 0.15
	card.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 26)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = GOLD
	stroke.Thickness = 2
	stroke.Transparency = 0.1
	stroke.Parent = card
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 16)
	padding.Parent = card
	local row = Instance.new("UIListLayout")
	row.FillDirection = Enum.FillDirection.Horizontal
	row.VerticalAlignment = Enum.VerticalAlignment.Center
	row.Padding = UDim.new(0, 10)
	row.SortOrder = Enum.SortOrder.LayoutOrder
	row.Parent = card
	local badge = Instance.new("TextLabel")
	badge.Name = "Aviso"
	badge.Size = UDim2.fromOffset(36, 36)
	badge.BackgroundColor3 = GOLD
	badge.Font = Enum.Font.GothamBlack
	badge.TextSize = 24
	badge.TextColor3 = Color3.fromRGB(30, 22, 6)
	badge.Text = "!"
	badge.LayoutOrder = 1
	badge.Parent = card
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(1, 0)
	round.Parent = badge
	local texts = Instance.new("Frame")
	texts.Name = "Textos"
	texts.Size = UDim2.fromOffset(0, 40)
	texts.AutomaticSize = Enum.AutomaticSize.X
	texts.BackgroundTransparency = 1
	texts.LayoutOrder = 2
	texts.Parent = card
	local column = Instance.new("UIListLayout")
	column.VerticalAlignment = Enum.VerticalAlignment.Center
	column.SortOrder = Enum.SortOrder.LayoutOrder
	column.Parent = texts
	local kicker = Instance.new("TextLabel")
	kicker.Name = "Tipo"
	kicker.Size = UDim2.fromOffset(0, 14)
	kicker.AutomaticSize = Enum.AutomaticSize.X
	kicker.BackgroundTransparency = 1
	kicker.Font = Enum.Font.GothamBold
	kicker.TextSize = 11
	kicker.TextColor3 = GOLD
	kicker.TextXAlignment = Enum.TextXAlignment.Left
	kicker.Text = "MISIÓN DE LA SAGA" .. hoursText(mark)
	kicker.LayoutOrder = 1
	kicker.Parent = texts
	local title = Instance.new("TextLabel")
	title.Name = "Titulo"
	title.Size = UDim2.fromOffset(0, 22)
	title.AutomaticSize = Enum.AutomaticSize.X
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = mark.Title
	title.LayoutOrder = 2
	title.Parent = texts
	model.PrimaryPart = ring
	model.Parent = folder
	return model
end

local function refresh()
	local raw = player:GetAttribute("CanonMarks")
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(if type(raw) == "string" then raw else "[]")
	end)
	marks = if ok and type(decoded) == "table" then decoded else {}
	local keep = {}
	for _, mark in marks do
		keep[mark.Id] = true
		if not pillars[mark.Id] then
			pillars[mark.Id] = makePillar(mark)
		end
	end
	for id, model in pillars do
		if not keep[id] then
			model:Destroy()
			pillars[id] = nil
		end
	end
end

-- Para el mapa: dónde están las misiones canónicas pendientes
function CanonMarkers.list(): { Mark }
	return marks
end

function CanonMarkers.init()
	folder = Instance.new("Folder")
	folder.Name = "CanonMarkers"
	folder.Parent = workspace
	player:GetAttributeChangedSignal("CanonMarks"):Connect(refresh)
	refresh()
	-- El cartel no estorba: se quita al llegar al sitio, mientras hablas y en las escenas de cámara
	task.spawn(function()
		while true do
			task.wait(0.25)
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local camera = workspace.CurrentCamera
			local busy = player:GetAttribute("InDialogue") == true or (camera ~= nil and camera.CameraType == Enum.CameraType.Scriptable)
			for _, model in pillars do
				local ring = model.PrimaryPart
				local cartel = ring and ring:FindFirstChild("Cartel") :: BillboardGui?
				if ring and cartel then
					local near = root ~= nil and (root.Position - ring.Position).Magnitude < NEAR
					cartel.Enabled = not busy and not near
				end
			end
		end
	end)
end

return CanonMarkers
