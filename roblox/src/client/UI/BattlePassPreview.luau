-- BattlePassPreview: vista previa de una recompensa del pase de temporada (§26).
--
--   local preview = BattlePassPreview.mount(frame, reward, { Touch = bool, TextSize = n })
--   preview.Kind      -> "Model" (3D que se gira), "Character" (tu personaje con la ropa o el gesto),
--                        "Swatch" (muestra de colores) o "Icon" (el icono grande)
--   preview:destroy()
--
-- 3D: el servidor deja un modelo por cada acabado de vehículo y cada decoración en
-- ReplicatedStorage.BattlePassPreviews (con el Id de la recompensa); los conjuntos apuntan al de
-- dentro (Preview.Model). La ropa y los gestos se ven sobre un clon de TU personaje. Se gira
-- arrastrando (ratón o dedo) y, en el ordenador, la rueda acerca y aleja. Nada va por fotograma: la
-- cámara solo se mueve cuando arrastras. Si algo falla o no hay modelo, sale el icono (nunca un error).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Theme)

local create = Theme.create
local C = Theme.Colors
local H = Theme.Hud

local BattlePassPreview = {}

-- Partes del aspecto de Valmar que pinta cada color de un conjunto (como AvatarService.dress)
local OUTFIT_PARTS = {
	Hoodie = { "UpperTorso", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "Torso", "Left Arm", "Right Arm", "Hood" },
	HoodLining = { "HoodLining", "HoodEdge" },
	Tee = { "Tee", "TeeHem" },
	Pants = { "LowerTorso", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "Left Leg", "Right Leg", "BaggyLeg" },
	Shoes = { "LeftFoot", "RightFoot", "Sneaker" },
}

-- El modelo ya montado por el servidor (o nil)
local function findModel(reward: { [string]: any }): Instance?
	local preview = reward.Preview
	local path = type(preview) == "table" and preview.Model
	local folder = ReplicatedStorage:FindFirstChild("BattlePassPreviews")
	if not folder then
		return nil
	end
	local id = if type(path) == "string" then (path:match("([^/]+)$") or path) else reward.Id
	local model = folder:FindFirstChild(tostring(id))
	return if model and model:IsA("Model") then model else nil
end

-- Clon de tu personaje (sin scripts) para la ropa y los gestos
local function cloneCharacter(): Model?
	local character = Players.LocalPlayer.Character
	if not character then
		return nil
	end
	local was = character.Archivable
	character.Archivable = true
	local ok, copy = pcall(function()
		return character:Clone()
	end)
	character.Archivable = was
	if not ok or not copy then
		return nil
	end
	for _, item in copy:GetDescendants() do
		if item:IsA("BaseScript") or item:IsA("Sound") or item:IsA("BillboardGui") or item:IsA("ProximityPrompt") then
			item:Destroy()
		end
	end
	return copy
end

local function paintOutfit(model: Model, colors: { [string]: any })
	for key, names in OUTFIT_PARTS do
		local color = colors[key]
		if typeof(color) == "Color3" then
			for _, item in model:GetDescendants() do
				if item:IsA("BasePart") and table.find(names, item.Name) then
					item.Color = color
				end
			end
		end
	end
end

-- Muestra de colores (temas de vivienda, del teléfono, del HUD, placas) debajo del icono
local function swatchColors(reward: { [string]: any }): { Color3 }
	local out = {}
	local preview = type(reward.Preview) == "table" and reward.Preview or {}
	local colors = preview.Colors
	if type(colors) == "table" then
		for _, key in { "Background", "Wall", "Floor", "Accent", "Stroke", "Text", "Primary", "Hoodie", "Tee", "Pants", "Shoes" } do
			if typeof(colors[key]) == "Color3" then
				table.insert(out, colors[key])
			end
		end
	end
	for _, key in { "Color", "Floor", "Wall" } do
		if typeof(preview[key]) == "Color3" then
			table.insert(out, preview[key])
		end
	end
	return out
end

local function iconFallback(frame: GuiObject, reward: { [string]: any }, opts: { [string]: any }): string
	local holder = create("Frame", { Name = "Fallback", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = frame })
	local colors = swatchColors(reward)
	local hasSwatch = #colors > 0
	Theme.label({
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, if hasSwatch then 0.4 else 0.5),
		Size = UDim2.fromScale(0.9, if hasSwatch then 0.62 else 0.8),
		Text = tostring(reward.Icon or "🎁"),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = holder,
	})
	if hasSwatch then
		local n = math.min(#colors, 5)
		for i = 1, n do
			create("Frame", {
				Name = "Swatch" .. i,
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, (i - (n + 1) / 2) * 30, 1, -8),
				Size = UDim2.fromOffset(24, 16),
				BackgroundColor3 = colors[i],
				BorderSizePixel = 0,
				Parent = holder,
			}, { create("UICorner", { CornerRadius = UDim.new(0, 4) }), create("UIStroke", { Color = C.Stroke, Transparency = 0.5, Thickness = 1 }) })
		end
	end
	-- Barco sin puerto deportivo todavía, u otra nota del servidor
	if type(reward.UsableText) == "string" then
		Theme.label({
			Name = "Note",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -4),
			Size = UDim2.new(1, -12, 0, 18),
			Text = reward.UsableText,
			TextSize = opts.TextSize or 13,
			TextColor3 = H.Gold,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextWrapped = true,
			Parent = holder,
		})
	end
	return if hasSwatch then "Swatch" else "Icon"
end

-- Monta el modelo en un ViewportFrame con una cámara que gira alrededor al arrastrar
local function mountViewport(frame: GuiObject, model: Model, animate: { [string]: any }?, opts: { [string]: any }): { RBXScriptConnection }
	local connections: { RBXScriptConnection } = {}
	local viewport = create("ViewportFrame", {
		Name = "Viewport",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(150, 160, 190),
		LightColor = Color3.fromRGB(255, 250, 240),
		LightDirection = Vector3.new(-1, -1.4, -0.8),
		Parent = frame,
	})
	local camera = create("Camera", { FieldOfView = 40, Parent = viewport })
	viewport.CurrentCamera = camera
	local world = create("WorldModel", { Parent = viewport })
	model:PivotTo(CFrame.new())
	model.Parent = world
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then
			item.Anchored = true
		end
	end
	local boxCFrame, size = model:GetBoundingBox()
	local center = boxCFrame.Position
	local radius = math.max(size.Magnitude * 0.5, 1)
	local distance = radius / math.tan(math.rad(camera.FieldOfView / 2)) * 1.05
	local yaw, pitch, zoom = math.rad(35), math.rad(-12), 1
	local function aim()
		local rotation = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
		camera.CFrame = CFrame.new(center) * rotation * CFrame.new(0, 0, distance * zoom)
	end
	aim()
	-- Arrastrar para girar (ratón o dedo); rueda para acercar (ordenador)
	local dragging: InputObject? = nil
	local last: Vector3? = nil
	table.insert(connections, viewport.InputBegan:Connect(function(input)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			dragging = input
			last = input.Position
		elseif kind == Enum.UserInputType.MouseWheel then
			zoom = math.clamp(zoom - input.Position.Z * 0.1, 0.6, 1.6)
			aim()
		end
	end))
	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if not dragging or not last then
			return
		end
		local kind = input.UserInputType
		if (kind == Enum.UserInputType.MouseMovement and dragging.UserInputType == Enum.UserInputType.MouseButton1) or input == dragging then
			local delta = input.Position - last
			last = input.Position
			yaw -= math.rad(delta.X * 0.6)
			pitch = math.clamp(pitch - math.rad(delta.Y * 0.3), math.rad(-45), math.rad(20))
			aim()
		end
	end))
	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if dragging and (input == dragging or input.UserInputType == Enum.UserInputType.MouseButton1) then
			dragging = nil
			last = nil
		end
	end))
	-- Gesto: se reproduce en el clon (dentro del WorldModel las animaciones funcionan)
	if animate and animate.AnimationId then
		pcall(function()
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local animator = humanoid and (humanoid:FindFirstChildOfClass("Animator") or create("Animator", { Parent = humanoid }))
			if animator then
				local animation = create("Animation", { AnimationId = "rbxassetid://" .. tostring(animate.AnimationId) })
				local track = (animator :: Animator):LoadAnimation(animation)
				track.Looped = true
				track:Play(0.2, 1, tonumber(animate.Speed) or 1)
			end
		end)
	end
	-- Pista para girar
	Theme.label({
		Name = "Hint",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -6, 1, -4),
		Size = UDim2.fromOffset(140, 16),
		Text = if opts.Touch then "↻ desliza para girar" else "↻ arrastra para girar",
		TextSize = opts.HintSize or 12,
		TextColor3 = C.Muted,
		TextTransparency = 0.2,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = frame,
	})
	return connections
end

function BattlePassPreview.mount(frame: GuiObject, reward: { [string]: any }?, options: { [string]: any }?)
	local opts = options or {}
	local handle = { Kind = "Icon", Connections = {} :: { RBXScriptConnection } }
	function handle.destroy()
		for _, connection in handle.Connections do
			connection:Disconnect()
		end
		table.clear(handle.Connections)
		for _, child in frame:GetChildren() do
			if child.Name == "Viewport" or child.Name == "Fallback" or child.Name == "Hint" then
				child:Destroy()
			end
		end
	end
	handle.destroy()
	if not reward then
		return handle
	end
	local preview = if type(reward.Preview) == "table" then reward.Preview else {}
	local kind = preview.Kind
	local ok, err = pcall(function()
		local model: Model? = nil
		local animate = nil
		if kind == "Vehicle" or kind == "Decor" or preview.Model then
			local source = findModel(reward)
			if source then
				model = source:Clone()
			end
		elseif kind == "Outfit" or kind == "Emote" then
			model = cloneCharacter()
			if model and kind == "Outfit" and type(preview.Colors) == "table" then
				paintOutfit(model, preview.Colors)
			end
			if model and kind == "Emote" then
				animate = preview
			end
		end
		if model then
			handle.Connections = mountViewport(frame, model, animate, opts)
			handle.Kind = if kind == "Outfit" or kind == "Emote" then "Character" else "Model"
		end
	end)
	if not ok then
		warn("[BattlePassPreview] " .. tostring(err))
		handle.destroy()
	end
	if handle.Kind == "Icon" then
		handle.Kind = iconFallback(frame, reward, opts)
	end
	return handle
end

return BattlePassPreview
