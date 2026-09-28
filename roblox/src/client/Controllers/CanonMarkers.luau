-- CanonMarkers (cliente): las misiones canónicas de la saga se ven SIEMPRE hasta que las haces.
--   * En el mundo: un pilar de luz dorado con «❗ Título» encima (se ve de lejos).
--   * En el minimapa y en el mapa grande: MapUI lee CanonMarkers.list().
-- El servidor manda la lista en el atributo del jugador «CanonMarks» (JSON; LifeStoryService).
-- Al llegar al sitio, la misión empieza sola.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local CanonMarkers = {}

local player = Players.LocalPlayer
local GOLD = Color3.fromRGB(255, 200, 60)

export type Mark = { Id: string, Title: string, X: number, Y: number, Z: number, From: number?, To: number? }

local marks: { Mark } = {}
local pillars: { [string]: Model } = {}
local folder: Folder

local function hoursText(mark: Mark): string
	if mark.From and mark.To then
		return ("  (de %d:00 a %d:00)"):format(mark.From, mark.To)
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
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(260, 60)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 9, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 900
	gui.Parent = ring
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = GOLD
	label.TextStrokeTransparency = 0.2
	label.Text = "❗ " .. mark.Title .. hoursText(mark)
	label.Parent = gui
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
end

return CanonMarkers
