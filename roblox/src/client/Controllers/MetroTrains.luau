-- MetroTrains (cliente): los trenes del metro, fluidos y a la vez en todas las pantallas.
--   * El servidor publica el estado de cada tren en ReplicatedStorage.MetroState.<línea> (fase, tramo,
--     hora de salida…). Aquí se calcula con Shared/Metro.positionAt dónde va el tren en cada
--     fotograma y se colocan los coches (el mismo cálculo que el servidor: todos lo ven igual).
--   * Si vas de pie dentro de un coche, el coche te lleva: se puede andar por el tren en marcha,
--     cambiar de coche por los pasos entre coches y mirar por las ventanas.
--   * Los viajeros NPC sentados (tag MetroRider) van con su coche.
--   * Megafonía: gong, voz ("Próxima estación: …", "Las puertas van a cerrarse") y subtítulo.
--   * Sonido del tren en marcha (si hay ID en Config.Sounds.MetroTren) y pitido de las puertas.
--   * De noche, las luces de las estaciones bajan un poco (tag MetroLamp).
--   * El tren de Cercanías (Shared/Rail, tag RailTrain, estado en ReplicatedStorage.RailState) se mueve
--     igual: mismas cuentas, y también te lleva si vas de pie.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Metro = require(ReplicatedStorage.Shared.Metro)
local Rail = require(ReplicatedStorage.Shared.Rail)
local Theme = require(script.Parent.Parent.UI.Theme)
local SoundFx = require(script.Parent.SoundFx)

local MetroTrains = {}

local player = Players.LocalPlayer
local ACTIVE_RANGE = 900 -- solo se mueven los trenes que tienes a esta distancia (o en los que vas)

-- Root: carpeta de ReplicatedStorage con el estado; Cars y Step: coches del tren y distancia entre ellos
type LineData = { Line: { Id: string }, Points: { Vector3 }, Centers: { number }, State: Instance?, Root: string, Cars: number, Step: number }
local lines: { [string]: LineData } = {}
local cars: { [string]: { [number]: BasePart } } = {} -- línea -> coche -> Root
local lastCF: { [BasePart]: CFrame } = {}
-- En qué fotograma se colocó cada coche por última vez (para saber si «antes» es de verdad el
-- fotograma anterior o una posición vieja)
local lastFrame: { [BasePart]: number } = {}
local frameNumber = 0
local subtitle: TextLabel? = nil
local subtitleUntil = 0
local rideLoop: Sound? = nil
local riding = false

local function now(): number
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	return if ok then t else os.clock()
end

local function stateOf(data: LineData): { [string]: any }?
	local f = data.State
	if not f then
		local root = ReplicatedStorage:FindFirstChild(data.Root)
		f = root and root:FindFirstChild(data.Line.Id)
		data.State = f
	end
	if not f then
		return nil
	end
	local phase = f:GetAttribute("Phase")
	if not phase then
		return nil
	end
	return {
		Phase = phase,
		S = f:GetAttribute("S") or 0,
		From = f:GetAttribute("From") or 0,
		To = f:GetAttribute("To") or 0,
		Duration = f:GetAttribute("Duration") or 1,
		T0 = f:GetAttribute("T0") or 0,
		Speed = f:GetAttribute("Speed"),
	}
end

-- Dónde va cada coche (el mismo cálculo que MetroService.placeTrain)
local function carCFrame(data: LineData, s: number, k: number, count: number): CFrame
	local offset = (k - (count + 1) / 2) * data.Step
	local p, t = Metro.sample(data.Points, s - offset)
	return CFrame.lookAt(p, p + t) * CFrame.new(0, -0.3, 0)
end

local function collectTrain(model: Instance)
	local lineId = model:GetAttribute("Line")
	if typeof(lineId) ~= "string" then
		return
	end
	local data = lines[lineId]
	local list = cars[lineId] or {}
	cars[lineId] = list
	for k = 1, if data then data.Cars else Metro.Cars do
		local car = model:FindFirstChild("Car" .. k)
		local root = car and car:FindFirstChild("Root")
		if root and root:IsA("BasePart") then
			list[k] = root
		end
	end
end

local function refreshTrains()
	for _, tag in { "MetroTrain", "RailTrain" } do
		for _, model in CollectionService:GetTagged(tag) do
			collectTrain(model)
		end
	end
end

---------------------------------------------------------------------
-- Cada fotograma: coloca los trenes y te lleva si vas de pie
---------------------------------------------------------------------
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function standingCar(character: Model, root: BasePart, humanoid: Humanoid): BasePart?
	if humanoid.SeatPart or humanoid.Sit then
		return nil
	end
	rayParams.FilterDescendantsInstances = { character }
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -8, 0), rayParams)
	if not hit then
		return nil
	end
	for _, list in cars do
		for _, carRoot in list do
			if hit.Instance == carRoot or hit.Instance:IsDescendantOf(carRoot.Parent :: Instance) then
				return carRoot
			end
		end
	end
	return nil
end

local function update()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local camera = workspace.CurrentCamera
	local eye = if camera then camera.CFrame.Position else Vector3.zero
	local t = now()
	-- ¿Sobre qué coche estás de pie? (antes de mover los trenes, con su posición de antes)
	local under: BasePart? = nil
	if character and root and humanoid then
		under = standingCar(character, root, humanoid)
	end
	local parts, cframes = {}, {}
	for lineId, data in lines do
		local list = cars[lineId]
		local state = stateOf(data)
		if list and state then
			local s = Metro.positionAt(state, t)
			local mid = list[math.ceil(data.Cars / 2)] or list[1]
			local near = mid ~= nil and (mid.Position - eye).Magnitude < ACTIVE_RANGE
			if near or (under ~= nil and table.find(list, under) ~= nil) then
				for k, carRoot in list do
					if carRoot.Parent then
						table.insert(parts, carRoot)
						table.insert(cframes, carCFrame(data, s, k, data.Cars))
					end
				end
			end
		end
	end
	if #parts == 0 then
		return
	end
	frameNumber += 1
	-- (solo si el coche se colocó en el fotograma anterior: si no, «antes» sería una posición vieja)
	local before = if under and lastFrame[under] == frameNumber - 1 then lastCF[under] else nil
	local ok = pcall(function()
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end)
	if not ok then
		for i, p in parts do
			p.CFrame = cframes[i]
		end
	end
	for i, p in parts do
		lastCF[p] = cframes[i]
		lastFrame[p] = frameNumber
	end
	-- De pie en un coche: el coche te lleva (lo que se ha movido el coche, te mueve a ti)
	if under and before and root then
		local after = lastCF[under] or under.CFrame
		local delta = after * before:Inverse()
		-- (aunque el móvil vaya a tirones y el coche haya avanzado mucho en un fotograma, te lleva
		-- igual: antes, con un tirón de más de medio segundo, te quedabas en el túnel)
		if delta.Position.Magnitude < 400 then
			local moved = delta * root.CFrame
			-- (solo el giro en horizontal: que no te tumbe en las curvas)
			local look = moved.LookVector
			local flat = Vector3.new(look.X, 0, look.Z)
			root.CFrame = if flat.Magnitude > 0.01 then CFrame.lookAt(moved.Position, moved.Position + flat) else CFrame.new(moved.Position)
		end
	end
	-- Viajeros NPC: con su coche
	for _, npc in CollectionService:GetTagged("MetroRider") do
		local list = cars[npc:GetAttribute("MetroLine") or ""]
		local carRoot = list and list[npc:GetAttribute("MetroCar") or 1]
		local rel = npc:GetAttribute("MetroOffset")
		if carRoot and typeof(rel) == "CFrame" and npc:IsA("Model") and (carRoot.Position - eye).Magnitude < 300 then
			npc:PivotTo((lastCF[carRoot] or carRoot.CFrame) * rel)
		end
	end
end

---------------------------------------------------------------------
-- Megafonía y sonidos
---------------------------------------------------------------------
local function showSubtitle(text: string)
	local label = subtitle
	if not label then
		return
	end
	label.Text = "🔊 " .. text
	label.Visible = true
	subtitleUntil = os.clock() + math.clamp(#text * 0.07 + 2, 3, 9)
end

local function onAnnounce(data: { [string]: any })
	if typeof(data) ~= "table" or typeof(data.Text) ~= "string" then
		return
	end
	-- En una escena o una conversación la megafonía no se mete encima
	if SoundFx.busy() then
		return
	end
	SoundFx.play("MetroGong")
	task.delay(0.6, function()
		SoundFx.voice(data.Text, 1.05, 0.9)
	end)
	showSubtitle(data.Text)
end

local function setRiding(value: boolean)
	if value == riding then
		return
	end
	riding = value
	if rideLoop then
		rideLoop:Destroy()
		rideLoop = nil
	end
	if value then
		-- En la carpeta de SoundFx (no en el personaje): si mueres, el bucle no se pierde colgado
		rideLoop = SoundFx.loop("MetroTren")
	end
end

---------------------------------------------------------------------
-- De noche, luz más baja en las estaciones
---------------------------------------------------------------------
local night = false
local function lampLevel(lamp: Instance)
	for _, light in lamp:GetChildren() do
		if light:IsA("Light") then
			local base = light:GetAttribute("DayBrightness")
			if typeof(base) ~= "number" then
				base = light.Brightness
				light:SetAttribute("DayBrightness", base)
			end
			light.Brightness = if night then base * 0.55 else base
		end
	end
	if lamp:IsA("BasePart") then
		lamp.Color = if night then Color3.fromRGB(255, 226, 190) else Color3.fromRGB(250, 250, 255)
	end
end

local function setNight(value: boolean)
	if value == night then
		return
	end
	night = value
	for _, lamp in CollectionService:GetTagged("MetroLamp") do
		lampLevel(lamp)
	end
end

---------------------------------------------------------------------

function MetroTrains.init()
	for _, line in Metro.Lines do
		local points, centers = Metro.path(line)
		lines[line.Id] = { Line = line, Points = points, Centers = centers, State = nil, Root = "MetroState", Cars = Metro.Cars, Step = Metro.CarLength + Metro.CarGap }
	end
	do
		local points, centers = Rail.path()
		lines[Rail.Line.Id] = { Line = Rail.Line, Points = points, Centers = centers, State = nil, Root = "RailState", Cars = Rail.Cars, Step = Rail.CarLength + Rail.CarGap }
	end
	refreshTrains()
	-- Al reaparecer (has muerto) ya no vas en el tren: se para su sonido
	player.CharacterAdded:Connect(function()
		setRiding(false)
	end)
	CollectionService:GetInstanceAddedSignal("MetroTrain"):Connect(collectTrain)
	CollectionService:GetInstanceAddedSignal("RailTrain"):Connect(collectTrain)
	CollectionService:GetInstanceAddedSignal("MetroLamp"):Connect(lampLevel)
	-- (con la carga por zonas los coches llegan poco a poco: se vuelven a buscar de vez en cuando)
	task.spawn(function()
		while true do
			task.wait(3)
			refreshTrains()
			local state = ReplicatedStorage:FindFirstChild("MetroState")
			if state then
				setNight(state:GetAttribute("Night") == true)
			end
		end
	end)

	local gui = Instance.new("ScreenGui")
	gui.Name = "MetroAnnounce"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	gui.Parent = player:WaitForChild("PlayerGui")
	Theme.fit(gui)
	subtitle = Theme.label({
		Name = "Subtitle",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -220),
		Size = UDim2.fromOffset(620, 30),
		Text = "",
		TextSize = 16,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.3,
		Visible = false,
		Parent = gui,
	})

	-- Megafonía, puertas y sonidos del viaje: los mismos para el metro y para Cercanías
	local function onRemote(action: any, data: any)
		if action == "Announce" then
			onAnnounce(data)
		elseif action == "Doors" then
			-- Pitido de cierre de puertas si estás cerca de ese tren
			local list = typeof(data) == "table" and cars[data.Line]
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if list and root then
				for _, carRoot in list do
					if (carRoot.Position - root.Position).Magnitude < 60 then
						SoundFx.play("MetroPuertas")
						task.delay(0.35, function()
							SoundFx.play("MetroPuertas")
						end)
						break
					end
				end
			end
		elseif action == "Board" then
			setRiding(true)
		elseif action == "Off" then
			setRiding(false)
		elseif action == "Arrive" then
			SoundFx.play("MetroFreno")
		end
	end
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local Remote = remotes:WaitForChild("Metro") :: RemoteEvent
	Remote.OnClientEvent:Connect(onRemote)
	local railRemote = remotes:FindFirstChild("Rail")
	if railRemote and railRemote:IsA("RemoteEvent") then
		railRemote.OnClientEvent:Connect(onRemote)
	end

	-- Antes de pintar (para que se vea fluido aunque llegue la posición del servidor) y antes de la
	-- física (para que el coche te lleve). Moverlo dos veces no duplica nada: cada vez solo se aplica
	-- lo que el coche se ha movido desde la anterior.
	local warned = false
	local function safeUpdate()
		local ok, err = pcall(update)
		if not ok and not warned then
			warned = true
			warn("[MetroTrains] " .. tostring(err))
		end
	end
	RunService.PreRender:Connect(safeUpdate)
	RunService.PreSimulation:Connect(safeUpdate)
	RunService.Heartbeat:Connect(function()
		local label = subtitle
		if label and label.Visible and os.clock() > subtitleUntil then
			label.Visible = false
		end
	end)
end

return MetroTrains
