-- CanteenService: el comedor de cada colegio e instituto, con comida GRATIS para los alumnos.
--
--   * Todos los colegios tienen comedor. Si el mapa guardado no lo tiene (el instituto del Campus no
--     cabía detrás del campo), se construye al fondo del patio, igual que hace ahora Kit/Civic.
--   * La barra se llena: bandejas con plato, pan, fruta y vaso; olla humeante; frutero; jarras de agua y
--     una fuente para beber. Las mesas, puestas con sus bandejas. Detrás de la barra, la cocinera.
--   * "Coger comida" en la barra: te llevas la bandeja (se ve en tus manos un rato), comes y se te quita
--     mucha hambre. "Coger fruta" en el frutero y "Beber agua" en la fuente. Sin límite, solo con una
--     pequeña espera entre una y otra (SchoolLife.Food). Para niños y adolescentes, mientras el colegio
--     está abierto (y siempre de 14:00 a 15:00).
--   * Coger la bandeja cuenta para el día de cole (StoryEvents "SchoolMeal") y como comer ("Ate").
--   * En los bancos de las mesas hay sitios para sentarse (Bench: ActionService pone "Sentarse").
-- Todo lo decorativo va sin colisión, sin consultas y sin sombra (no cuesta nada).

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SchoolLife = require(ReplicatedStorage.Shared.LifeStory.SchoolLife)
local Builder = require(script.Parent.Parent.World.Builder)
local Npc = require(script.Parent.Parent.World.Npc)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)
local LocationService = require(script.Parent.LocationService)

local CanteenService = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local C = CFrame.new

local Notify: RemoteEvent
local lastMeal: { [Player]: { [string]: number } } = {}
local trays: { [Player]: Instance } = {}
local dressed: { [Instance]: boolean } = {}

-- Sitios de la escena de la comida (en los ejes del comedor): ahí no se pone asiento para el jugador
local ACTOR_SPOTS = { V(-13, 0, 1.5), V(-9, 0, -2), V(-13, 0, -2) }

---------------------------------------------------------------------
-- Comer
---------------------------------------------------------------------

-- Bandeja en las manos (delante, a la altura de la cintura) durante unos segundos
local function carryTray(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	if trays[player] then
		trays[player]:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "BandejaComedor"
	local function piece(name: string, size: Vector3, offset: CFrame, color: Color3, shape: Enum.PartType?, material: Enum.Material?): BasePart
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		if shape then
			p.Shape = shape
		end
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Massless = true
		p.Anchored = false
		local at = root.CFrame * C(0, -root.Size.Y * 0.08, -(root.Size.Z / 2 + 0.75)) * offset
		p.CFrame = at
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = p
		weld.Parent = p
		p.Parent = model
		return p
	end
	piece("Bandeja", V(1.7, 0.1, 1.2), C(), rgb(90, 150, 210))
	piece("Plato", V(0.08, 0.9, 0.9), C(-0.3, 0.1, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(250, 250, 250), Enum.PartType.Cylinder)
	piece("Comida", V(0.6, 0.18, 0.5), C(-0.3, 0.2, 0), rgb(220, 150, 70))
	piece("Pan", V(0.45, 0.25, 0.3), C(0.45, 0.15, -0.25), rgb(215, 170, 100))
	piece("Vaso", V(0.28, 0.4, 0.28), C(0.5, 0.25, 0.3), rgb(200, 230, 245), nil, Enum.Material.Glass)
	model.Parent = character
	trays[player] = model
	task.delay(12, function()
		if trays[player] == model then
			trays[player] = nil
		end
		model:Destroy()
	end)
end

-- Come algo del comedor (kind: "Menu", "Fruta" o "Agua"). Devuelve si ha comido.
function CanteenService.eat(player: Player, kind: string): boolean
	local food = SchoolLife.Food[kind]
	if not food or not DataService.get(player) then
		return false
	end
	local ok, reason = SchoolLife.canEat(player:GetAttribute("LifeStage"), Lighting.ClockTime)
	if not ok then
		Notify:FireClient(player, "Error", if reason == "Alumnos" then "🍽 El comedor es para los alumnos del colegio." else "🍽 El comedor está cerrado: abre con el colegio (de 8:30 a 17:00).")
		return false
	end
	lastMeal[player] = lastMeal[player] or {}
	local ready, left = SchoolLife.ready(lastMeal[player][kind], os.clock(), food.Cooldown)
	if not ready then
		Notify:FireClient(player, "Info", ("🍽 Aún estás comiendo… prueba otra vez en %d s."):format(left))
		return false
	end
	lastMeal[player][kind] = os.clock()
	NeedsService.change(player, food.Hunger, food.Energy or 0)
	if kind == "Menu" then
		carryTray(player)
		Notify:FireClient(player, "Food", "🍽 ¡Que aproveche! Menú del comedor (gratis)")
		StoryEvents.emit(player, "SchoolMeal", { Kind = kind })
	else
		Notify:FireClient(player, "Food", ("🍽 %s"):format(food.Name))
	end
	StoryEvents.emit(player, "Ate", { FoodId = "Comedor" .. kind })
	return true
end

local function prompt(part: BasePart, kind: string)
	local food = SchoolLife.Food[kind]
	local p = Builder.prompt(part, food.Action, food.Name .. " · gratis", 0.2)
	p.Name = "CanteenPrompt"
	p.MaxActivationDistance = 8
	p:SetAttribute("Canteen", kind)
	p.Triggered:Connect(function(player)
		CanteenService.eat(player, kind)
	end)
	return p
end

---------------------------------------------------------------------
-- El comedor por dentro
---------------------------------------------------------------------

local function decor(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?, material: Enum.Material?): BasePart
	local p = Builder.decor({ Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = parent })
	if shape then
		p.Shape = shape
	end
	p.CastShadow = false
	return p
end

-- Bandeja puesta (sobre una mesa o en la barra): bandeja, plato con comida y, a veces, vaso y pan
local function setTray(parent: Instance, top: CFrame, k: number)
	local colors = { rgb(90, 150, 210), rgb(230, 120, 90), rgb(120, 190, 120), rgb(240, 200, 80) }
	local foods = { rgb(220, 150, 70), rgb(200, 90, 60), rgb(240, 220, 150), rgb(120, 170, 80) }
	decor(parent, "Bandeja", V(1.5, 0.08, 1.1), top * C(0, 0.04, 0), colors[k % #colors + 1])
	decor(parent, "Plato", V(0.06, 0.85, 0.85), top * C(-0.25, 0.1, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(250, 250, 250), Enum.PartType.Cylinder)
	decor(parent, "Comida", V(0.55, 0.16, 0.45), top * C(-0.25, 0.2, 0), foods[k % #foods + 1])
	if k % 2 == 0 then
		decor(parent, "Vaso", V(0.26, 0.38, 0.26), top * C(0.45, 0.27, 0.25), rgb(200, 230, 245), nil, Enum.Material.Glass).Transparency = 0.3
	else
		decor(parent, "Pan", V(0.42, 0.22, 0.28), top * C(0.45, 0.19, -0.2), rgb(215, 170, 100))
	end
end

local function inside(area: BasePart, position: Vector3, margin: number): boolean
	local rel = area.CFrame:PointToObjectSpace(position)
	return math.abs(rel.X) <= area.Size.X / 2 + margin and math.abs(rel.Z) <= area.Size.Z / 2 + margin
end

-- Sillas para el jugador en los bancos (ActionService les pone "Sentarse")
local function benchSeats(folder: Instance, area: BasePart, bench: BasePart, tableX: number?)
	local top = bench.CFrame * C(0, bench.Size.Y / 2, 0)
	local benchX = area.CFrame:PointToObjectSpace(bench.Position).X
	local toTable = if tableX then (if tableX < benchX then -1 else 1) else 1
	-- Un sitio por banco (muchos carteles de "Sentarse" juntos llenarían el menú) y, en el banco de la
	-- escena de la comida, el tuyo: enfrente de tu amigo del día
	local spots = { 4.5 }
	if math.abs(benchX - (-9)) < 0.6 then
		table.insert(spots, 1.5)
	end
	for _, z in spots do
		local spot = top * C(0, 0, z)
		local rel = area.CFrame:PointToObjectSpace(spot.Position)
		local free = true
		for _, actor in ACTOR_SPOTS do
			if math.abs(rel.X - actor.X) < 1.5 and math.abs(rel.Z - actor.Z) < 2 then
				free = false
			end
		end
		if free then
			local m = Instance.new("Model")
			m.Name = "Bench"
			local look = area.CFrame:VectorToWorldSpace(V(toTable, 0, 0))
			local seat = Builder.part({
				ClassName = "Seat", Name = "Seat", Size = V(1.6, 0.2, 1.6),
				CFrame = CFrame.lookAt(spot.Position + V(0, 0.1, 0), spot.Position + V(0, 0.1, 0) + look),
				Transparency = 1, CanTouch = false, CanQuery = true, CastShadow = false, Parent = m,
			})
			seat:SetAttribute("Canteen", true)
			m.Parent = folder
			m:AddTag("Bench")
		end
	end
end

local function dress(area: BasePart)
	if dressed[area] or area:GetAttribute("AreaId") ~= "Comedor" then
		return
	end
	local building = area.Parent
	if not building then
		return
	end
	dressed[area] = true
	local folder = Instance.new("Folder")
	folder.Name = "ComedorVivo"
	folder.Parent = building
	local floor = area.CFrame * C(0, -area.Size.Y / 2, 0) -- suelo del comedor, en sus ejes

	-- La barra: bandejas preparadas, olla, pan, frutero y jarras
	local counter: BasePart? = nil
	for _, child in building:GetChildren() do
		if child:IsA("BasePart") and child.Name == "ServingCounter" and inside(area, child.Position, 2) then
			counter = child
		end
	end
	if counter then
		local top = counter.CFrame * C(0, counter.Size.Y / 2, 0)
		-- (la barra va a lo largo de su eje Z; las bandejas de siempre ya están en el centro)
		for k, z in { -4.8, -1.8, 1.2, 4.2 } do
			decor(folder, "Plato", V(0.06, 0.85, 0.85), top * C(0, 0.18, z) * CFrame.Angles(0, 0, math.rad(90)), rgb(250, 250, 250), Enum.PartType.Cylinder)
			decor(folder, "Comida", V(0.55, 0.16, 0.45), top * C(0, 0.28, z), ({ rgb(220, 150, 70), rgb(200, 90, 60), rgb(240, 220, 150), rgb(120, 170, 80) })[k])
			decor(folder, "Pan", V(0.4, 0.22, 0.28), top * C(0.35, 0.22, z + 0.45), rgb(215, 170, 100))
		end
		local pot = decor(folder, "Olla", V(1.2, 1.4, 1.4), top * C(0.6, 0.6, -6.2) * CFrame.Angles(0, 0, math.rad(90)), rgb(170, 175, 185), Enum.PartType.Cylinder, Enum.Material.Metal)
		local steam = Instance.new("ParticleEmitter")
		steam.Texture = "rbxasset://textures/particles/smoke_main.dds"
		steam.Color = ColorSequence.new(Color3.new(1, 1, 1))
		steam.Transparency = NumberSequence.new(0.6, 1)
		steam.Size = NumberSequence.new(0.4, 1.4)
		steam.Lifetime = NumberRange.new(1.2, 2)
		steam.Rate = 3
		steam.Speed = NumberRange.new(1, 2)
		steam.EmissionDirection = Enum.NormalId.Right -- (la olla está tumbada: su "arriba" es la derecha)
		steam.Parent = pot
		local bowl = decor(folder, "Frutero", V(0.5, 1.5, 1.5), top * C(0, 0.25, 6.1) * CFrame.Angles(0, 0, math.rad(90)), rgb(160, 110, 70), Enum.PartType.Cylinder, Enum.Material.Wood)
		for k, fruit in { { rgb(220, 40, 40), V(-0.3, 0.55, 5.9) }, { rgb(250, 190, 40), V(0.25, 0.55, 6.3) }, { rgb(120, 200, 60), V(0.1, 0.8, 6.0) }, { rgb(240, 140, 40), V(-0.1, 0.55, 6.45) } } do
			decor(folder, "Fruta" .. k, V(0.45, 0.45, 0.45), top * C(fruit[2]), fruit[1], Enum.PartType.Ball)
		end
		for k, z in { -3.3, 2.7 } do
			decor(folder, "Jarra" .. k, V(0.45, 0.7, 0.45), top * C(-0.6, 0.35, z), rgb(210, 235, 250), Enum.PartType.Cylinder, Enum.Material.Glass).Transparency = 0.35
		end
		prompt(counter, "Menu")
		prompt(bowl, "Fruta")
		-- La cocinera, al final de la barra, removiendo la olla y mirando a la sala
		task.spawn(function()
			local back = counter.CFrame * C(0, -counter.Size.Y / 2, -(counter.Size.Z / 2 + 1.6))
			local look = area.CFrame:VectorToWorldSpace(V(-1, 0, 0))
			local ok, cook = pcall(Npc.create, "Cocinera", folder, CFrame.lookAt(back.Position, back.Position + look), {
				Skin = rgb(230, 190, 150), Shirt = rgb(250, 250, 250), Pants = rgb(60, 70, 90),
			})
			if ok and cook then
				Npc.work(cook, "Stir")
				local humanoid = cook:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.DisplayName = "Cocinera"
					humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
					humanoid.NameDisplayDistance = 25
				end
			end
		end)
	end

	-- Fuente de agua junto a la pared (en la esquina de enfrente de la barra)
	local fountainAt = floor * C(-area.Size.X / 2 + 0.9, 0, -area.Size.Z / 2 + 1.6)
	decor(folder, "FuentePie", V(0.8, 2.6, 0.8), fountainAt * C(0, 1.3, 0), rgb(200, 205, 210), nil, Enum.Material.Metal)
	local basin = decor(folder, "FuentePila", V(1.4, 0.4, 1.4), fountainAt * C(0, 2.8, 0), rgb(225, 230, 235), nil, Enum.Material.Metal)
	decor(folder, "FuenteGrifo", V(0.2, 0.4, 0.2), fountainAt * C(0, 3.15, 0.3), rgb(150, 155, 160), nil, Enum.Material.Metal)
	prompt(basin, "Agua")

	-- Mesas puestas y sitios para sentarse
	local tables: { number } = {}
	for _, child in building:GetChildren() do
		if child:IsA("BasePart") and child.Name == "Table" and inside(area, child.Position, 1) then
			local x = area.CFrame:PointToObjectSpace(child.Position).X
			table.insert(tables, x)
			local top = child.CFrame * C(0, child.Size.Y / 2, 0)
			local k = 0
			for _, side in { -0.7, 0.7 } do
				for _, z in { -4.5, 0, 4.5 } do
					k += 1
					local look = if side < 0 then CFrame.Angles(0, math.rad(90), 0) else CFrame.Angles(0, math.rad(-90), 0)
					setTray(folder, top * C(side, 0, z) * look, k + math.floor(x))
				end
			end
		end
	end
	for _, child in building:GetChildren() do
		if child:IsA("BasePart") and child.Name == "Bench" and inside(area, child.Position, 1) then
			local x = area.CFrame:PointToObjectSpace(child.Position).X
			local nearest: number? = nil
			for _, tx in tables do
				if not nearest or math.abs(tx - x) < math.abs(nearest - x) then
					nearest = tx
				end
			end
			benchSeats(folder, area, child, nearest)
		end
	end
end

---------------------------------------------------------------------
-- Colegios sin comedor (mapas guardados antes de que el instituto lo tuviera)
---------------------------------------------------------------------

local function hasCanteen(school: Instance): boolean
	for _, d in school:GetDescendants() do
		if d:IsA("BasePart") and d:HasTag("StoryArea") and d:GetAttribute("AreaId") == "Comedor" then
			return true
		end
	end
	return false
end

local function ensureCanteen(recess: BasePart)
	local school = recess.Parent
	if not school or recess:GetAttribute("CanteenChecked") then
		return
	end
	recess:SetAttribute("CanteenChecked", true)
	if hasCanteen(school) then
		return
	end
	local length = recess.Size.X + 10 -- (el patio mide lo que la parcela menos 10)
	local playground = school:FindFirstChild("Playground")
	local soft = playground and playground:FindFirstChild("SoftFloor", true) :: BasePart?
	if length < 190 or not soft then
		return
	end
	-- Mismas cuentas que Kit/Civic.school: al fondo del patio, del lado del parque infantil
	local Civic = require(script.Parent.Parent.World.Kit.Civic)
	local right = recess.CFrame.RightVector
	local along = if (soft.Position - recess.Position):Dot(right) >= 0 then right else -right
	local inward = -recess.CFrame.LookVector
	local ground = recess.Position - V(0, recess.Size.Y / 2, 0)
	local center = ground + along * Civic.yardCanteenU(length) + inward * Civic.YardCanteenV
	local cf = CFrame.new(center) * recess.CFrame.Rotation
	-- Lo que estorba (un árbol en la esquina del fondo)
	for _, child in school:GetChildren() do
		if child:IsA("Model") and string.find(child.Name, "Tree") then
			local rel = cf:PointToObjectSpace(child:GetPivot().Position)
			if math.abs(rel.X) < 22 and math.abs(rel.Z) < 27 then
				child:Destroy()
			end
		end
	end
	local town = nil
	for _, d in school:GetDescendants() do
		if d:IsA("BasePart") and d:HasTag("StoryArea") and type(d:GetAttribute("School")) == "string" then
			town = d:GetAttribute("School")
			break
		end
	end
	local ok, err = pcall(Civic.schoolCanteen, school, cf, town or LocationService.zoneAt(recess.Position))
	if not ok then
		warn("[CanteenService] " .. tostring(err))
	end
end

function CanteenService.init()
	Notify = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify") :: RemoteEvent
	Players.PlayerRemoving:Connect(function(player)
		lastMeal[player] = nil
		trays[player] = nil
	end)
	local function onArea(area: Instance)
		if area:IsA("BasePart") and area:GetAttribute("AreaId") == "Comedor" then
			task.defer(function()
				local ok, err = pcall(dress, area)
				if not ok then
					warn("[CanteenService] " .. tostring(err))
				end
			end)
		end
	end
	CollectionService:GetInstanceAddedSignal("StoryArea"):Connect(onArea)
	for _, recess in CollectionService:GetTagged("RecessArea") do
		if recess:IsA("BasePart") then
			ensureCanteen(recess)
		end
	end
	CollectionService:GetInstanceAddedSignal("RecessArea"):Connect(function(recess)
		if recess:IsA("BasePart") then
			task.defer(ensureCanteen, recess)
		end
	end)
	for _, area in CollectionService:GetTagged("StoryArea") do
		onArea(area)
	end
end

return CanteenService
