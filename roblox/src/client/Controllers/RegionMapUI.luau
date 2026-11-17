-- RegionMapUI: la VISTA DE UNA REGIÓN dentro del mapa definitivo (17-11-2026, los dibujos del dueño:
-- docs/mapa/region-bosque-a.png y region-bosque-b.png). Se abre al tocar una región en el mapa grande
-- (Controllers/WorldMapUI) y ocupa la misma ventana:
--
--   [← Volver al Mapa]          (🌲) Bosque Etéreo · Nv. 10 - 30                       [N]
--                               Un bosque misterioso lleno de vida…
--   ┌ Información de la Zona ┐   el dibujo de la región (o el trozo del mapa grande)   ┌ Misiones de la Zona ┐
--   │ Nivel recomendado      │   con sus lugares (icono, nombre, Nv.) y tú             │ ✓ contratos de caza │
--   │ Monstruos · Jefe       │                                                         └─────────────────────┘
--   │ Recompensas            │                                    [📍 Colocar Destino]
--   └────────────────────────┘
--   [Consejo: …]                                                                     [− 100% +]
--
-- Datos: shared/Cosmos/RegionGuide (lugares, descripción, consejo, dibujo) y ValmarRegions / Bestiary (niveles,
-- monstruos, jefe y material raro). «Colocar Destino» pone el GPS en el lugar elegido (Controllers/Gps.setManual).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MapTextureIds = require(ReplicatedStorage.Shared.MapTextureIds)
local Images = require(ReplicatedStorage.Shared.Images)
local VR = require(ReplicatedStorage.Shared.Cosmos.ValmarRegions)
local RegionGuide = require(ReplicatedStorage.Shared.Cosmos.RegionGuide)
local Bestiary = require(ReplicatedStorage.Shared.Cosmos.Bestiary)
local Theme = require(script.Parent.Parent.UI.Theme)

local create = Theme.create
local rgb = Color3.fromRGB

local RegionMapUI = {}

local player = Players.LocalPlayer

type View = { Root: Frame, Open: (string) -> (), Close: () -> (), IsOpen: () -> boolean }

-- El trozo del mapa grande que se usa cuando una región aún no tiene su dibujo (píxeles del mapa definitivo)
RegionMapUI.CropW, RegionMapUI.CropH = 420, 264

local function panel(parent: Instance, name: string, props: { [string]: any }): Frame
	props.Name = name
	props.BackgroundColor3 = rgb(12, 18, 34)
	props.BackgroundTransparency = 0.12
	props.Parent = parent
	return create("Frame", props, {
		create("UICorner", { CornerRadius = UDim.new(0, 14) }),
		create("UIStroke", { Color = rgb(70, 100, 150), Thickness = 1.5 }),
	})
end

local function text(parent: Instance, props: { [string]: any }): TextLabel
	props.BackgroundTransparency = 1
	props.Font = props.Font or Theme.Font
	props.TextColor3 = props.TextColor3 or rgb(235, 240, 250)
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	props.TextWrapped = true
	props.Parent = parent
	return create("TextLabel", props)
end

-- toArt: la función del mundo al dibujo del mapa grande (WorldMapUI.toArt)
function RegionMapUI.build(window: Frame, toArt: (number, number) -> (number, number), onBack: () -> ()): View
	local root = create("Frame", { Name = "Region", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 20, Parent = window })
	local current: string? = nil
	local selected: { [string]: any }? = nil

	-- el dibujo
	local area = create("Frame", { Name = "Dibujo", Position = UDim2.fromOffset(12, 66), Size = UDim2.new(1, -24, 1, -132), BackgroundColor3 = rgb(8, 30, 60), ClipsDescendants = true, Parent = root }, {
		create("UICorner", { CornerRadius = UDim.new(0, 12) }),
	})
	local holder = create("Frame", { Name = "Encaje", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = area })
	local aspect = create("UIAspectRatioConstraint", { AspectRatio = 1.6, AspectType = Enum.AspectType.ScaleWithParentSize, DominantAxis = Enum.DominantAxis.Width, Parent = holder })
	local image = create("ImageLabel", { Name = "Imagen", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Stretch, ZIndex = 2, Parent = holder })
	local markers = create("Frame", { Name = "Lugares", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 3, Parent = holder })
	local me = create("TextLabel", { Name = "Tu", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(34, 34), BackgroundColor3 = rgb(16, 22, 40), Text = "🏠", TextScaled = true, Font = Theme.FontBold, TextColor3 = rgb(80, 170, 255), ZIndex = 9, Visible = false, Parent = holder }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = rgb(80, 170, 255), Thickness = 2 }),
	})

	-- cabecera: volver, título y brújula
	local back = create("TextButton", { Name = "Volver", Position = UDim2.fromOffset(14, 10), Size = UDim2.fromOffset(210, 42), BackgroundColor3 = rgb(16, 22, 40), Text = "←  Volver al Mapa", Font = Theme.FontBold, TextSize = 19, TextColor3 = rgb(255, 255, 255), ZIndex = 21, Parent = root }, {
		create("UICorner", { CornerRadius = UDim.new(0, 12) }),
		create("UIStroke", { Color = rgb(70, 100, 150), Thickness = 1.5 }),
	})
	back.Activated:Connect(onBack)
	local head = panel(root, "Titulo", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 4), Size = UDim2.fromOffset(560, 100), ZIndex = 22 })
	local headIcon = create("TextLabel", { Name = "Icono", Position = UDim2.fromOffset(12, 10), Size = UDim2.fromOffset(62, 62), BackgroundColor3 = rgb(40, 120, 60), Text = "🌲", TextScaled = true, Font = Theme.FontBold, ZIndex = 23, Parent = head }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = rgb(200, 255, 200), Thickness = 2 }),
	})
	local headName = text(head, { Name = "Nombre", Position = UDim2.fromOffset(86, 6), Size = UDim2.new(1, -96, 0, 36), Font = Theme.FontBold, TextSize = 32, TextColor3 = rgb(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 23 })
	local headLevel = text(head, { Name = "Nivel", Position = UDim2.fromOffset(86, 40), Size = UDim2.new(1, -96, 0, 28), Font = Theme.FontBold, TextSize = 24, TextColor3 = rgb(140, 255, 100), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 23 })
	local headDesc = text(head, { Name = "Descripcion", Position = UDim2.fromOffset(10, 72), Size = UDim2.new(1, -20, 0, 24), TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 23 })
	create("TextLabel", { Name = "Brujula", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -76, 0, 10), Size = UDim2.fromOffset(52, 52), BackgroundColor3 = rgb(16, 22, 40), Text = "N\n▲", TextScaled = true, Font = Theme.FontBold, TextColor3 = rgb(255, 255, 255), ZIndex = 21, Parent = root }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = rgb(150, 190, 250), Thickness = 2 }),
	})

	-- información de la zona (izquierda)
	local info = panel(root, "Informacion", { Position = UDim2.fromOffset(24, 116), Size = UDim2.fromOffset(300, 300), ZIndex = 22 })
	create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 10), Parent = info })
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = info })
	text(info, { Name = "T", Size = UDim2.new(1, 0, 0, 26), Text = "🌳  Información de la Zona", Font = Theme.FontBold, TextSize = 20, LayoutOrder = 1, ZIndex = 23 })
	local infoLevel = text(info, { Name = "Nivel", Size = UDim2.new(1, 0, 0, 22), TextSize = 16, LayoutOrder = 2, ZIndex = 23, RichText = true })
	local infoMonsters = text(info, { Name = "Monstruos", Size = UDim2.new(1, 0, 0, 62), TextSize = 15, LayoutOrder = 3, ZIndex = 23, RichText = true, TextYAlignment = Enum.TextYAlignment.Top })
	local infoBoss = text(info, { Name = "Jefe", Size = UDim2.new(1, 0, 0, 42), TextSize = 15, LayoutOrder = 4, ZIndex = 23, RichText = true, TextYAlignment = Enum.TextYAlignment.Top })
	text(info, { Name = "R", Size = UDim2.new(1, 0, 0, 20), Text = "Recompensas:", Font = Theme.FontBold, TextSize = 16, TextColor3 = rgb(255, 200, 80), LayoutOrder = 5, ZIndex = 23 })
	local rewards = create("Frame", { Name = "Recompensas", Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, LayoutOrder = 6, ZIndex = 23, Parent = info }, {
		create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	-- misiones de la zona (derecha) y colocar destino
	local quests = panel(root, "Misiones", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 400), Size = UDim2.fromOffset(300, 190), ZIndex = 22 })
	create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 8), Parent = quests })
	create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = quests })
	text(quests, { Name = "T", Size = UDim2.new(1, 0, 0, 24), Text = "❗ Misiones de la Zona", Font = Theme.FontBold, TextSize = 19, TextColor3 = rgb(255, 210, 70), LayoutOrder = 0, ZIndex = 23 })
	local destino = create("TextButton", { Name = "ColocarDestino", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -78), Size = UDim2.fromOffset(300, 54), BackgroundColor3 = rgb(40, 110, 230), Text = "📍  Colocar Destino", Font = Theme.FontBold, TextSize = 22, TextColor3 = rgb(255, 255, 255), ZIndex = 22, Parent = root }, {
		create("UICorner", { CornerRadius = UDim.new(0, 14) }),
		create("UIStroke", { Color = rgb(150, 200, 255), Thickness = 2 }),
	})
	local chosen = text(root, { Name = "Elegido", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -136), Size = UDim2.fromOffset(300, 22), TextSize = 15, TextXAlignment = Enum.TextXAlignment.Center, Text = "Toca un lugar del mapa", ZIndex = 22 })
	destino.Activated:Connect(function()
		local target = selected
		if not target then
			return
		end
		local ok, Gps = pcall(function()
			return require(script.Parent.Gps) :: any
		end)
		if ok and Gps.setManual then
			Gps.setManual(Vector3.new(target.X, 10, target.Z), target.Place.Name)
			chosen.Text = "📍 Destino: " .. target.Place.Name
		end
	end)

	-- consejo (abajo a la izquierda)
	local tip = panel(root, "Consejo", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 24, 1, -78), Size = UDim2.fromOffset(330, 70), ZIndex = 22 })
	text(tip, { Name = "Icono", Position = UDim2.fromOffset(8, 12), Size = UDim2.fromOffset(40, 40), Text = "❗", TextScaled = true, TextColor3 = rgb(255, 200, 40), ZIndex = 23 })
	text(tip, { Name = "T", Position = UDim2.fromOffset(54, 6), Size = UDim2.new(1, -60, 0, 22), Text = "Consejo:", Font = Theme.FontBold, TextSize = 17, TextColor3 = rgb(255, 210, 70), ZIndex = 23 })
	local tipText = text(tip, { Name = "Texto", Position = UDim2.fromOffset(54, 28), Size = UDim2.new(1, -60, 0, 38), TextSize = 14, ZIndex = 23, TextYAlignment = Enum.TextYAlignment.Top })

	local placed: { { Entry: { [string]: any }, Ui: GuiObject } } = {}
	local project: ((number, number) -> (number?, number?))? = nil

	local function chip(entry: { [string]: any }, px: number, py: number, withLabel: boolean): GuiObject
		local place = entry.Place
		local b = create("TextButton", {
			Name = "Lugar_" .. place.Id,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(px, py),
			Size = if withLabel then UDim2.fromOffset(190, 48) else UDim2.fromOffset(170, 50),
			BackgroundColor3 = rgb(14, 18, 30),
			BackgroundTransparency = if withLabel then 0.15 else 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 6,
			Parent = markers,
		})
		if withLabel then
			create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = b })
			text(b, { Name = "Icono", Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(40, 40), Text = RegionGuide.Icons[place.Kind] or "📍", TextScaled = true, ZIndex = 7 })
			text(b, { Name = "Nombre", Position = UDim2.fromOffset(48, 2), Size = UDim2.new(1, -52, 0, 24), Text = place.Name, Font = Theme.FontBold, TextSize = 15, TextColor3 = rgb(255, 255, 255), ZIndex = 7 })
			text(b, { Name = "Nivel", Position = UDim2.fromOffset(48, 24), Size = UDim2.new(1, -52, 0, 20), Text = if place.Level then ("Nv. %d+"):format(place.Level) else "Zona segura", Font = Theme.FontBold, TextSize = 15, TextColor3 = if place.Level then rgb(255, 214, 80) else rgb(110, 255, 140), ZIndex = 7 })
		end
		local stroke = create("UIStroke", { Color = rgb(255, 220, 90), Thickness = 3, Enabled = false, Parent = b })
		b.Activated:Connect(function()
			selected = entry
			for _, other in placed do
				local s = other.Ui:FindFirstChildOfClass("UIStroke")
				if s then
					s.Enabled = other.Entry == entry
				end
			end
			stroke.Enabled = true
			chosen.Text = "Elegido: " .. place.Name
		end)
		return b
	end

	local function fill(regionId: string)
		for _, p in placed do
			p.Ui:Destroy()
		end
		table.clear(placed)
		selected = nil
		chosen.Text = "Toca un lugar del mapa"
		local reg = VR.ById[regionId]
		local guide = RegionGuide.List[regionId] or {}
		headIcon.Text = reg.Icon
		headIcon.BackgroundColor3 = reg.Color:Lerp(rgb(0, 0, 0), 0.35)
		headName.Text = reg.Name
		headLevel.Text = ("Nv. %d - %d"):format(reg.MinLevel, reg.MaxLevel)
		headDesc.Text = guide.Description or reg.Lore or ""
		infoLevel.Text = ("<b>Nivel recomendado:</b> <font color=\"#9CFF6A\">%d - %d</font>"):format(reg.MinLevel, reg.MaxLevel)
		local names = {}
		for _, sid in reg.Species do
			local sp = Bestiary.Species[sid]
			table.insert(names, if sp then sp.Name else sid)
		end
		infoMonsters.Text = "<b>Monstruos:</b> " .. table.concat(names, ", ")
		local boss = Bestiary.Species[reg.Boss]
		infoBoss.Text = ("<b><font color=\"#FFC850\">Jefe de Zona:</font></b> %s"):format(if boss then boss.Name else reg.Boss)
		for _, c in rewards:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		for i, icon in { "⚔", "🛡", "💎", "💰" } do
			create("TextLabel", { Size = UDim2.fromOffset(52, 52), BackgroundColor3 = rgb(30, 40, 66), Text = icon, TextScaled = true, Font = Theme.FontBold, LayoutOrder = i, ZIndex = 23, Parent = rewards }, {
				create("UICorner", { CornerRadius = UDim.new(0, 10) }),
				create("UIStroke", { Color = rgb(90, 120, 180), Thickness = 1.5 }),
				create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
			})
		end
		tipText.Text = guide.Tip or "Explora la zona para descubrir lugares secretos y mazmorras."
		-- el dibujo: el de la región si está subido; si no, el trozo del mapa grande
		local artId = guide.Art and MapTextureIds[guide.Art.Id]
		if type(artId) == "string" and string.match(artId, "^rbxassetid://%d+$") then
			image.Image = Images.of(artId)
			image.ImageRectOffset = Vector2.zero
			image.ImageRectSize = Vector2.zero
			aspect.AspectRatio = guide.Art.W / guide.Art.H
			project = function(x: number, z: number): (number?, number?)
				local off, t = RegionGuide.toLocal(regionId, x, z)
				if math.abs(off) > 24 or t < -0.2 or t > 1.1 then
					return nil, nil
				end
				local px, py = RegionGuide.artOf(off, t, 1, 1)
				return px, py
			end
			-- (el dibujo ya trae los nombres: los lugares se tocan encima de su cartel dibujado)
			for _, e in RegionGuide.all() do
				if e.Region == regionId and e.Place.Art then
					table.insert(placed, { Entry = e, Ui = chip(e, e.Place.Art[1] / guide.Art.W, e.Place.Art[2] / guide.Art.H, false) })
				end
			end
		else
			image.Image = Images.of(MapTextureIds.definitivo or "")
			local cx, cy = toArt(VR.point(reg, 6200))
			local W, H = RegionMapUI.CropW, RegionMapUI.CropH
			local ox = math.clamp(cx - W / 2, 0, 1024 - W)
			local oy = math.clamp(cy - H / 2, 0, 482 - H)
			image.ImageRectOffset = Vector2.new(ox, oy)
			image.ImageRectSize = Vector2.new(W, H)
			aspect.AspectRatio = W / H
			project = function(x: number, z: number): (number?, number?)
				local px, py = toArt(x, z)
				local u, v = (px - ox) / W, (py - oy) / H
				if u < 0 or u > 1 or v < 0 or v > 1 then
					return nil, nil
				end
				return u, v
			end
			for _, e in RegionGuide.all() do
				if e.Region == regionId then
					local u, v = (project :: any)(e.X, e.Z)
					if u then
						table.insert(placed, { Entry = e, Ui = chip(e, u, v, true) })
					end
				end
			end
		end
		-- las misiones de la zona: los contratos de caza que llevas de esta región
		for _, c in quests:GetChildren() do
			if c:IsA("TextLabel") and c.Name == "Mision" then
				c:Destroy()
			end
		end
		local lines = {}
		local raw = player:GetAttribute("HuntContracts")
		if type(raw) == "string" then
			local ok, list = pcall(function()
				return game:GetService("HttpService"):JSONDecode(raw)
			end)
			if ok and type(list) == "table" then
				for _, c in list do
					if type(c.Title) == "string" and string.find(c.Title, reg.Name, 1, true) then
						table.insert(lines, ("✓ %s (%d / %d)"):format(c.Title, tonumber(c.Have) or 0, tonumber(c.Need) or 1))
					end
				end
			end
		end
		if #lines == 0 then
			table.insert(lines, "Coge contratos de caza en el tablón de la Academia o de un campamento.")
		end
		for i, l in lines do
			text(quests, { Name = "Mision", Size = UDim2.new(1, 0, 0, 44), Text = l, TextSize = 15, LayoutOrder = i, ZIndex = 23, TextYAlignment = Enum.TextYAlignment.Top })
		end
	end

	RunService.RenderStepped:Connect(function()
		if not root.Visible or not project then
			return
		end
		local c = player.Character
		local hrp = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then
			me.Visible = false
			return
		end
		local u, v = (project :: any)(hrp.Position.X, hrp.Position.Z)
		me.Visible = u ~= nil
		if u then
			me.Position = UDim2.fromScale(u, v)
		end
	end)

	return {
		Root = root,
		Open = function(regionId: string)
			current = regionId
			fill(regionId)
			root.Visible = true
		end,
		Close = function()
			current = nil
			root.Visible = false
		end,
		IsOpen = function(): boolean
			return current ~= nil
		end,
	}
end

return RegionMapUI
