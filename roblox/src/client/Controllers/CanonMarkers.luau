-- CanonMarkers (cliente): las misiones canónicas de la saga se ven SIEMPRE hasta que las haces.
--   * En el mundo: un pilar de luz dorado (siempre) con una pastilla de UNA línea «! SAGA  Título»
--     encima, pequeña (título de 16 pt) y solo unos segundos (CARD_SECONDS): al aparecer la misión y al
--     acercarte (a menos de CLOSE studs); luego queda el pilar, el minimapa y el mapa grande.
--   * En pantalla: al aparecer una misión nueva, un aviso corto arriba («❗ Saga: Título», Hud.toast:
--     bajo la hora, no en el centro), que se va solo.
--   * En el minimapa y en el mapa grande: MapUI lee CanonMarkers.list().
-- El servidor manda la lista en el atributo del jugador «CanonMarks» (JSON; LifeStoryService).
-- Al llegar al sitio, la misión empieza sola.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local CanonMarkers = {}

local player = Players.LocalPlayer
local GOLD = Color3.fromRGB(255, 200, 60)
local NEAR = 22 -- a menos de esto ya estás allí: el cartel se quita
local CLOSE = 150 -- al acercarte a menos de esto, el cartel vuelve a salir un momento
local CARD_SECONDS = 6 -- lo que se ve el cartel cada vez

export type Mark = { Id: string, Title: string, X: number, Y: number, Z: number, From: number?, To: number? }

local marks: { Mark } = {}
local pillars: { [string]: Model } = {}
local folder: Folder
local shownUntil: { [string]: number } = {} -- hasta cuándo se ve el cartel de cada misión
local wasClose: { [string]: boolean } = {}
local announced: { [string]: boolean } = {}
local started = false

local function hoursText(mark: Mark): string
	if mark.From and mark.To then
		return (" · %d-%dh"):format(mark.From, mark.To)
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
	-- Cartel: una pastilla de una línea (oscura con borde dorado, el ! en un círculo, «SAGA» y el
	-- título) bien por encima del sitio. De tamaño fijo en pantalla (~55 % de la tarjeta de antes): no
	-- se hace enorme al acercarte y no tapa la calle
	local gui = Instance.new("BillboardGui")
	gui.Name = "Cartel"
	gui.Size = UDim2.fromOffset(260, 40)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 16, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 900
	gui.LightInfluence = 0
	gui.Parent = ring
	local card = Instance.new("Frame")
	card.Name = "Tarjeta"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.fromOffset(0, 32)
	card.AutomaticSize = Enum.AutomaticSize.X
	card.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
	card.BackgroundTransparency = 0.15
	card.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = GOLD
	stroke.Thickness = 1.5
	stroke.Transparency = 0.2
	stroke.Parent = card
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 5)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = card
	local row = Instance.new("UIListLayout")
	row.FillDirection = Enum.FillDirection.Horizontal
	row.VerticalAlignment = Enum.VerticalAlignment.Center
	row.Padding = UDim.new(0, 7)
	row.SortOrder = Enum.SortOrder.LayoutOrder
	row.Parent = card
	local badge = Instance.new("TextLabel")
	badge.Name = "Aviso"
	badge.Size = UDim2.fromOffset(22, 22)
	badge.BackgroundColor3 = GOLD
	badge.Font = Enum.Font.GothamBlack
	badge.TextSize = 15
	badge.TextColor3 = Color3.fromRGB(30, 22, 6)
	badge.Text = "!"
	badge.LayoutOrder = 1
	badge.Parent = card
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(1, 0)
	round.Parent = badge
	local texts = Instance.new("Frame")
	texts.Name = "Textos"
	texts.Size = UDim2.fromOffset(0, 24)
	texts.AutomaticSize = Enum.AutomaticSize.X
	texts.BackgroundTransparency = 1
	texts.LayoutOrder = 2
	texts.Parent = card
	local column = Instance.new("UIListLayout")
	column.FillDirection = Enum.FillDirection.Horizontal -- (una sola línea: «SAGA · 9-13h  Título»)
	column.Padding = UDim.new(0, 6)
	column.VerticalAlignment = Enum.VerticalAlignment.Center
	column.SortOrder = Enum.SortOrder.LayoutOrder
	column.Parent = texts
	local kicker = Instance.new("TextLabel")
	kicker.Name = "Tipo"
	kicker.Size = UDim2.fromOffset(0, 20)
	kicker.AutomaticSize = Enum.AutomaticSize.X
	kicker.BackgroundTransparency = 1
	kicker.Font = Enum.Font.GothamBlack
	kicker.TextSize = 14
	kicker.TextColor3 = GOLD
	kicker.TextXAlignment = Enum.TextXAlignment.Left
	kicker.Text = "SAGA" .. hoursText(mark)
	kicker.LayoutOrder = 1
	kicker.Parent = texts
	local title = Instance.new("TextLabel")
	title.Name = "Titulo"
	title.Size = UDim2.fromOffset(0, 22)
	title.AutomaticSize = Enum.AutomaticSize.X
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
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
			shownUntil[mark.Id] = os.clock() + CARD_SECONDS
			-- Una misión nueva (no las que ya había al entrar): un aviso corto arriba, que se va solo
			if started and not announced[mark.Id] then
				local ok, Hud = pcall(require, script.Parent.Parent.UI.Hud)
				if ok and Hud then
					pcall(Hud.toast, "Info", "❗ Saga: " .. mark.Title)
				end
			end
			announced[mark.Id] = true
		end
	end
	for id, model in pillars do
		if not keep[id] then
			model:Destroy()
			pillars[id] = nil
			shownUntil[id] = nil
			wasClose[id] = nil
		end
	end
end

-- ¿Se ve ahora el cartel? (pruebas y el bucle de abajo)
function CanonMarkers.cardVisible(id: string, distance: number?, busy: boolean?): boolean
	local now = os.clock()
	if distance then
		local close = distance < CLOSE
		if close and not wasClose[id] then
			shownUntil[id] = now + CARD_SECONDS -- te acercas: vuelve a salir un momento
		end
		wasClose[id] = distance < CLOSE + 30 and (close or wasClose[id] == true)
	end
	local near = distance ~= nil and distance < NEAR
	return not busy and not near and now < (shownUntil[id] or 0)
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
	started = true
	-- El cartel no estorba: se quita al llegar al sitio, mientras hablas y en las escenas de cámara
	task.spawn(function()
		while true do
			task.wait(0.25)
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local camera = workspace.CurrentCamera
			local busy = player:GetAttribute("InDialogue") == true or (camera ~= nil and camera.CameraType == Enum.CameraType.Scriptable)
			for id, model in pillars do
				local ring = model.PrimaryPart
				local cartel = ring and ring:FindFirstChild("Cartel") :: BillboardGui?
				if ring and cartel then
					local distance = if root then (root.Position - ring.Position).Magnitude else nil
					cartel.Enabled = CanonMarkers.cardVisible(id, distance, busy)
				end
			end
		end
	end)
end

return CanonMarkers
