-- NameTags (cliente): el nombre encima de los personajes de la historia (actores con la marca
-- "NamedActor", que pone SceneService).
--   * Letra blanca y gruesa con borde oscuro sobre una pastilla semitransparente: se lee sobre
--     cualquier fondo (el nombre de serie de Roblox era gris, fino y casi no se veía).
--   * Se esconde mientras ese personaje habla (el bocadillo ya lleva su nombre y no se pisan),
--     en las escenas de cámara, si el personaje está oculto en tu pantalla y de lejos.
--   * Jugadores con cosméticos del pase de temporada (UI/BattlePassCosmetics, solo con el pase
--     encendido): el mismo cartel, con su TÍTULO encima y su PLACA (colores de la pastilla). Mientras
--     lo llevan, el nombre de serie de Roblox se esconde (en tu pantalla) para no salir dos veces. Los
--     atributos BP_Title / BP_Nameplate los pone solo el servidor.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local SpeechBubbles = require(script.Parent.Parent.UI.SpeechBubbles)
local Cosmetics = require(script.Parent.Parent.UI.BattlePassCosmetics)

local NameTags = {}

local player = Players.LocalPlayer
local MAX_DISTANCE = 45
local TAG = "NamedActor"

type Entry = { Model: Model, Gui: BillboardGui, Label: TextLabel, Pill: Frame, Owner: Player?, Title: TextLabel?, Plate: UIStroke?, Look: string? }

local entries: { [Model]: Entry } = {}
local folder: Folder? = nil

local function headOf(model: Model): BasePart?
	local head = model:FindFirstChild("Head")
	return if head and head:IsA("BasePart") then head else nil
end

local function nameOf(model: Model): string
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local name = humanoid and humanoid.DisplayName
	return if name and name ~= "" then name else model.Name
end

local PILL_COLOR = Color3.fromRGB(18, 22, 34)

-- owner: el jugador (cartel con título y placa del pase); nil para los personajes de la historia
local function build(model: Model, owner: Player?)
	if entries[model] or not folder then
		return
	end
	local head = headOf(model)
	if not head then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "NameTag_" .. model.Name
	gui.Adornee = head
	gui.Size = UDim2.fromOffset(240, if owner then 50 else 30)
	gui.StudsOffsetWorldSpace = Vector3.new(0, head.Size.Y / 2 + (if owner then 1.5 else 1.1), 0)
	gui.MaxDistance = MAX_DISTANCE
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	local pill = Instance.new("Frame")
	pill.Name = "Pill"
	pill.AnchorPoint = if owner then Vector2.new(0.5, 1) else Vector2.new(0.5, 0.5)
	pill.Position = if owner then UDim2.new(0.5, 0, 1, -2) else UDim2.fromScale(0.5, 0.5)
	pill.Size = UDim2.fromOffset(0, 26)
	pill.AutomaticSize = Enum.AutomaticSize.X
	pill.BackgroundColor3 = PILL_COLOR
	pill.BackgroundTransparency = 0.35
	pill.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = pill
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = pill
	local label = Instance.new("TextLabel")
	label.Name = "Name"
	label.Size = UDim2.fromScale(0, 1)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 17
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeColor3 = Color3.fromRGB(10, 12, 20)
	label.TextStrokeTransparency = 0.4
	label.Text = nameOf(model)
	label.Parent = pill
	local entry: Entry = { Model = model, Gui = gui, Label = label, Pill = pill, Owner = owner }
	if owner then
		-- Título del pase: una línea pequeña encima de la pastilla
		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.AnchorPoint = Vector2.new(0.5, 1)
		title.Position = UDim2.new(0.5, 0, 1, -30)
		title.Size = UDim2.new(1, 0, 0, 18)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.TextSize = 14
		title.TextColor3 = Color3.new(1, 1, 1)
		title.TextStrokeColor3 = Color3.fromRGB(10, 12, 20)
		title.TextStrokeTransparency = 0.35
		title.TextTruncate = Enum.TextTruncate.AtEnd
		title.Visible = false
		title.Parent = gui
		entry.Title = title
		-- Placa del pase: el borde de la pastilla (apagado sin placa)
		local plate = Instance.new("UIStroke")
		plate.Name = "Plate"
		plate.Thickness = 2
		plate.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		plate.Enabled = false
		plate.Parent = pill
		entry.Plate = plate
	end
	gui.Parent = folder
	entries[model] = entry
end

-- Título y placa del pase de un jugador (solo se reescribe si algo cambia)
local function style(entry: Entry)
	local owner = entry.Owner
	if not owner then
		return
	end
	local text, color = Cosmetics.title(owner)
	local plate = Cosmetics.nameplate(owner)
	local look = ("%s|%s|%s"):format(text or "", tostring(color), tostring(owner:GetAttribute("BP_Nameplate")))
	if entry.Look == look then
		return
	end
	entry.Look = look
	local title = entry.Title :: TextLabel
	title.Visible = text ~= nil
	title.Text = text or ""
	title.TextColor3 = color or Color3.new(1, 1, 1)
	local stroke = entry.Plate :: UIStroke
	stroke.Enabled = plate ~= nil
	entry.Pill.BackgroundColor3 = if plate then plate.Background else PILL_COLOR
	entry.Pill.BackgroundTransparency = if plate then 0.12 else 0.35
	if plate then
		stroke.Color = plate.Stroke or plate.Background
	end
	entry.Label.TextColor3 = if plate and plate.Text then plate.Text else Color3.new(1, 1, 1)
end

local function drop(model: Model)
	local entry = entries[model]
	if entry then
		entry.Gui:Destroy()
		entries[model] = nil
		if entry.Owner then
			-- (vuelve el nombre de serie de Roblox)
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.DisplayDistanceType == Enum.HumanoidDisplayDistanceType.None then
				humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
			end
		end
	end
end

-- Los demás jugadores con título o placa del pase llevan nuestro cartel (sin ellos, el de Roblox)
local function trackPlayers()
	if not Cosmetics.enabled() then
		return -- (pase apagado: los jugadores conservan el nombre de serie de Roblox)
	end
	for _, other in Players:GetPlayers() do
		local character = other.Character
		if other == player or not character or not headOf(character) then
			continue
		end
		local entry = entries[character]
		if Cosmetics.hasTag(other) then
			if not entry then
				build(character, other)
			end
		elseif entry and entry.Owner then
			drop(character)
		end
	end
end

local function track(instance: Instance)
	if instance:IsA("Model") then
		if headOf(instance) then
			build(instance)
		else
			-- El personaje llega a trozos: se espera a su cabeza
			task.delay(1, function()
				if instance.Parent and CollectionService:HasTag(instance, TAG) then
					build(instance)
				end
			end)
		end
	end
end

-- ¿Hay una escena de cámara? (la cámara la mueve un guion)
local function inCinematic(): boolean
	local camera = workspace.CurrentCamera
	return camera ~= nil and camera.CameraType == Enum.CameraType.Scriptable
end

local function update()
	local cinematic = inCinematic()
	trackPlayers()
	for model, entry in entries do
		local head = headOf(model)
		if not model.Parent or not head or (entry.Owner and entry.Owner.Parent == nil) then
			drop(model)
			continue
		end
		if entry.Owner then
			style(entry)
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.DisplayDistanceType ~= Enum.HumanoidDisplayDistanceType.None then
				humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None -- (solo en tu pantalla)
			end
		end
		local hidden = head.LocalTransparencyModifier > 0.5 or head.Transparency > 0.9
		entry.Gui.Enabled = not cinematic and not hidden and not SpeechBubbles.isSpeaking(model)
		local name = nameOf(model)
		if entry.Label.Text ~= name then
			entry.Label.Text = name
		end
	end
end

-- Red de seguridad: cualquier personaje que no sea un jugador y enseñe el nombre de serie de Roblox
-- (gris y fino, encima de los bocadillos) pasa a llevar el nuestro. Los jugadores lo conservan.
local watched: { [Humanoid]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local function adopt(humanoid: Humanoid)
	if watched[humanoid] then
		return
	end
	local model = humanoid.Parent
	if not model or not model:IsA("Model") or Players:GetPlayerFromCharacter(model) then
		return
	end
	watched[humanoid] = true
	local function fix()
		if humanoid.DisplayDistanceType ~= Enum.HumanoidDisplayDistanceType.None then
			local name = humanoid.DisplayName
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			-- (solo los que tenían nombre que enseñar: los peatones sin nombre siguen sin él)
			if name ~= nil and name ~= "" and humanoid.Parent and not entries[humanoid.Parent :: Model] then
				track(humanoid.Parent :: Model)
			end
		end
	end
	humanoid:GetPropertyChangedSignal("DisplayDistanceType"):Connect(fix)
	fix()
end

function NameTags.init()
	local gui = Instance.new("Folder")
	gui.Name = "NameTags"
	gui.Parent = player:WaitForChild("PlayerGui")
	folder = gui
	CollectionService:GetInstanceAddedSignal(TAG):Connect(track)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(instance)
		if instance:IsA("Model") then
			drop(instance)
		end
	end)
	for _, instance in CollectionService:GetTagged(TAG) do
		track(instance)
	end
	workspace.DescendantAdded:Connect(function(d)
		if d:IsA("Humanoid") then
			task.defer(adopt, d)
		end
	end)
	task.spawn(function()
		for _, d in workspace:GetDescendants() do
			if d:IsA("Humanoid") then
				adopt(d)
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.15)
			local ok, err = pcall(update)
			if not ok then
				warn("[NameTags] " .. tostring(err))
			end
		end
	end)
end

return NameTags
