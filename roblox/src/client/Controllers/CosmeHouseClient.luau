-- CosmeHouseClient (cliente): lo que se ve y se mueve en la casa de Cosme (server/World/CosmeHouse),
-- todo local y solo cerca del jugador (en el móvil no cuesta nada lejos de la casa).
--
--   * Giran los anillos de la máquina del espacio-tiempo, los aros de los portales, rotores,
--     ventiladores… (etiqueta CosmeSpin: SpinSpeed vueltas/s, SpinAxis, SpinCenter). Más deprisa con
--     la máquina encendida (On), el portal activo (Active) o un empujón (BoostUntil).
--   * Los robots pequeños se pasean por su ronda (CosmeRobot, Path) y los drones flotan.
--   * Partículas (CosmeFx) solo encendidas a menos de 80 studs; ráfagas cuando el servidor marca
--     BurstAt en una máquina o un experimento. Remolinos de los portales (SwirlSpeed) que giran.
--   * El portal del salón (CosmeFlicker) falla: aparece unos segundos de vez en cuando (y al pulsar el
--     mando raro: ShowUntil).
--   * Portal activado (Active): temblor de cámara (Controllers/CameraShake), distorsión (desenfoque y
--     color) y chorro de partículas, si estás cerca.
--   * Remoto "CosmeHouse": documentos y pantallas (panel para leer, con botón grande para el móvil) y
--     el telescopio (cámara en el ocular: luna, la Grieta, la ciudad y las estrellas).

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CosmeHouseClient = {}

local player = Players.LocalPlayer
local NEAR = 170 -- a esta distancia de la casa se anima todo
local FX_NEAR = 80

local house: Model? = nil
local active = false

local function now(): number
	return workspace:GetServerTimeNow()
end

local function rootPos(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return if root then root.Position else nil
end

local function siteCenter(): Vector3?
	local site = house and house:GetAttribute("Site")
	return if typeof(site) == "CFrame" then site.Position else nil
end

---------------------------------------------------------------------
-- Giros
---------------------------------------------------------------------
type Spinner = { Target: Instance, Center: CFrame, Parts: { { Part: BasePart, Rel: CFrame } }, Speed: number, Axis: string, Angle: number, Owners: { Instance } }
local spinners: { Spinner } = {}

local function owners(target: Instance): { Instance }
	local list = {}
	local node: Instance? = target
	while node and node ~= house and node ~= workspace do
		if node:GetAttribute("On") ~= nil or node:GetAttribute("Active") ~= nil or node:GetAttribute("BoostUntil") ~= nil or node:HasTag("CosmePortal") or node:GetAttribute("MachinePart") then
			table.insert(list, node)
		end
		node = node.Parent
	end
	-- La máquina del espacio-tiempo entera (sus anillos aceleran al encenderla)
	local machine = target:FindFirstAncestor("MaquinaEspacioTiempo")
	if machine then
		table.insert(list, machine)
	end
	return list
end

local function addSpinner(target: Instance)
	local center = target:GetAttribute("SpinCenter")
	if typeof(center) ~= "CFrame" then
		if target:IsA("BasePart") then
			center = target.CFrame
		elseif target:IsA("Model") then
			center = target:GetPivot()
		else
			return
		end
	end
	local list = {}
	if target:IsA("BasePart") then
		table.insert(list, { Part = target, Rel = (center :: CFrame):ToObjectSpace(target.CFrame) })
	end
	for _, d in target:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(list, { Part = d, Rel = (center :: CFrame):ToObjectSpace(d.CFrame) })
		end
	end
	table.insert(spinners, {
		Target = target,
		Center = center :: CFrame,
		Parts = list,
		Speed = target:GetAttribute("SpinSpeed") or 0.1,
		Axis = target:GetAttribute("SpinAxis") or "Y",
		Angle = 0,
		Owners = owners(target),
	})
end

local function boost(owners_: { Instance }): number
	local t = now()
	for _, o in owners_ do
		if o:GetAttribute("On") == true or o:GetAttribute("Active") == true then
			return 4
		end
		local b = o:GetAttribute("BoostUntil")
		if type(b) == "number" and b > t then
			return 4
		end
	end
	return 1
end

local function stepSpinners(dt: number, focus: Vector3)
	for _, s in spinners do
		if (s.Center.Position - focus).Magnitude < 110 then
			s.Angle = (s.Angle + s.Speed * boost(s.Owners) * dt * math.pi * 2) % (math.pi * 2)
			local rot = if s.Axis == "X" then CFrame.Angles(s.Angle, 0, 0) elseif s.Axis == "Z" then CFrame.Angles(0, 0, s.Angle) else CFrame.Angles(0, s.Angle, 0)
			local frame = s.Center * rot
			for _, p in s.Parts do
				p.Part.CFrame = frame * p.Rel
			end
		end
	end
end

---------------------------------------------------------------------
-- Robots
---------------------------------------------------------------------
type Robot = { Model: Model, Points: { Vector3 }, Speed: number, Leg: number, T: number, Base: CFrame, Kind: string, Phase: number }
local robots: { Robot } = {}

local function addRobot(model: Model)
	local path = model:GetAttribute("Path")
	local base = model:GetPivot()
	local points = {}
	if type(path) == "string" then
		for x, z in string.gmatch(path, "([%-%d%.]+),([%-%d%.]+)") do
			table.insert(points, Vector3.new(tonumber(x) :: number, base.Position.Y, tonumber(z) :: number))
		end
	end
	table.insert(robots, { Model = model, Points = points, Speed = model:GetAttribute("Speed") or 2, Leg = 1, T = 0, Base = base, Kind = model:GetAttribute("Kind") or "Mini", Phase = math.random() * 6 })
end

local function stepRobots(dt: number, focus: Vector3)
	local clock = os.clock()
	for _, r in robots do
		if (r.Base.Position - focus).Magnitude < 90 and r.Model.Parent then
			local pos: Vector3
			local look: Vector3? = nil
			if #r.Points >= 2 then
				local a = r.Points[r.Leg]
				local b = r.Points[r.Leg % #r.Points + 1]
				local len = math.max(0.1, (b - a).Magnitude)
				r.T += dt * r.Speed / len
				if r.T >= 1 then
					r.T = 0
					r.Leg = r.Leg % #r.Points + 1
				end
				pos = a:Lerp(b, r.T)
				look = b - a
			else
				pos = r.Base.Position
			end
			if r.Kind == "Dron" then
				pos += Vector3.new(0, math.sin(clock * 2 + r.Phase) * 0.4, 0)
			end
			local cf = if look and look.Magnitude > 0.01 then CFrame.lookAt(pos, pos + Vector3.new(look.X, 0, look.Z)) else CFrame.new(pos) * r.Base.Rotation
			r.Model:PivotTo(cf)
		end
	end
end

---------------------------------------------------------------------
-- Partículas, remolinos, portal que falla, ráfagas
---------------------------------------------------------------------
local fxParts: { BasePart } = {}
local swirls: { ImageLabel } = {}
local flickers: { Model } = {}
local fxOn: { [BasePart]: boolean } = {}

local function setEmitters(part: BasePart, on: boolean, mult: number?)
	for _, e in part:GetChildren() do
		if e:IsA("ParticleEmitter") then
			e.Enabled = on
			local base = e:GetAttribute("BaseRate")
			if type(base) == "number" then
				e.Rate = base * (mult or 1)
			end
		end
	end
end

local function setVisible(model: Model, visible: boolean)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = if visible then 0 else 1
		elseif d:IsA("ParticleEmitter") then
			d.Enabled = visible
		elseif d:IsA("Beam") or d:IsA("PointLight") or d:IsA("SurfaceGui") then
			(d :: any).Enabled = visible
		end
	end
end

local function burstIn(target: Instance)
	for _, d in target:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			pcall(function()
				d:Emit(25)
			end)
		end
	end
	local part = if target:IsA("BasePart") then target else target:FindFirstChildWhichIsA("BasePart", true)
	if part then
		local flash = Instance.new("PointLight")
		flash.Range = 18
		flash.Brightness = 3
		flash.Color = Color3.fromRGB(200, 220, 255)
		flash.Parent = part
		task.delay(0.5, function()
			flash:Destroy()
		end)
	end
end

---------------------------------------------------------------------
-- Portal activado: temblor y distorsión
---------------------------------------------------------------------
local distortion: { Blur: BlurEffect?, Color: ColorCorrectionEffect? } = {}

local function portalFx(portal: Model)
	local center = portal:GetAttribute("Center")
	local pos = rootPos()
	if typeof(center) ~= "CFrame" or not pos or (center.Position - pos).Magnitude > 80 then
		return
	end
	pcall(function()
		local CameraShake = require(script.Parent.CameraShake) :: any
		CameraShake.shake(0.9, 7)
	end)
	if not distortion.Blur then
		local b = Instance.new("BlurEffect")
		b.Name = "CosmePortalBlur"
		b.Size = 0
		b.Parent = Lighting
		distortion.Blur = b
		local c = Instance.new("ColorCorrectionEffect")
		c.Name = "CosmePortalColor"
		c.Parent = Lighting
		distortion.Color = c
	end
	local t0 = os.clock()
	task.spawn(function()
		while portal:GetAttribute("Active") and os.clock() - t0 < 12 do
			local k = math.sin((os.clock() - t0) * 6) * 0.5 + 0.5
			if distortion.Blur then
				distortion.Blur.Size = 4 + k * 8
			end
			if distortion.Color then
				distortion.Color.TintColor = Color3.fromRGB(220, 200, 255):Lerp(Color3.fromRGB(200, 230, 255), k)
				distortion.Color.Saturation = 0.2 + k * 0.3
				distortion.Color.Contrast = 0.1
			end
			for _, d in portal:GetDescendants() do
				if d:IsA("BasePart") and d:HasTag("CosmeFx") then
					setEmitters(d, true, 4)
				end
			end
			task.wait(0.05)
		end
		if distortion.Blur then
			distortion.Blur.Size = 0
		end
		if distortion.Color then
			distortion.Color.TintColor = Color3.new(1, 1, 1)
			distortion.Color.Saturation = 0
			distortion.Color.Contrast = 0
		end
	end)
end

---------------------------------------------------------------------
-- Documentos y telescopio
---------------------------------------------------------------------
local docGui: ScreenGui? = nil

local function closeDoc()
	if docGui then
		docGui:Destroy()
		docGui = nil
	end
end

local function showDoc(payload: { [string]: any })
	closeDoc()
	local screen = payload.Style == "Screen"
	local gui = Instance.new("ScreenGui")
	gui.Name = "CosmeDocumento"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 40
	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(0.86, 0, 0.62, 0)
	panel.BackgroundColor3 = if screen then Color3.fromRGB(10, 18, 30) else Color3.fromRGB(250, 244, 226)
	panel.BorderSizePixel = 0
	panel.Parent = gui
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(620, 460)
	limit.Parent = panel
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = if screen then Color3.fromRGB(90, 220, 255) else Color3.fromRGB(150, 110, 70)
	stroke.Thickness = 2
	stroke.Parent = panel
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0, 18, 0, 12)
	title.Size = UDim2.new(1, -36, 0, 34)
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.FontFace = Font.fromEnum(Enum.Font.GothamBlack)
	title.TextColor3 = if screen then Color3.fromRGB(120, 230, 255) else Color3.fromRGB(70, 40, 20)
	title.Text = tostring(payload.Title or "")
	title.Parent = panel
	local scroll = Instance.new("ScrollingFrame")
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Position = UDim2.new(0, 18, 0, 54)
	scroll.Size = UDim2.new(1, -36, 1, -124)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new()
	scroll.ScrollBarThickness = 6
	scroll.Parent = panel
	local body = Instance.new("TextLabel")
	body.BackgroundTransparency = 1
	body.Size = UDim2.new(1, -8, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.TextWrapped = true
	body.TextSize = 20
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.FontFace = Font.fromEnum(if screen then Enum.Font.Code else Enum.Font.Gotham)
	body.TextColor3 = if screen then Color3.fromRGB(140, 255, 170) else Color3.fromRGB(40, 30, 20)
	body.Text = tostring(payload.Text or "")
	body.Parent = scroll
	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(0.5, 1)
	close.Position = UDim2.new(0.5, 0, 1, -12)
	close.Size = UDim2.new(0, 200, 0, 50)
	close.BackgroundColor3 = if screen then Color3.fromRGB(40, 120, 170) else Color3.fromRGB(150, 110, 70)
	close.TextColor3 = Color3.new(1, 1, 1)
	close.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	close.TextSize = 22
	close.Text = "Cerrar"
	close.Parent = panel
	local c2 = Instance.new("UICorner")
	c2.CornerRadius = UDim.new(0, 12)
	c2.Parent = close
	close.Activated:Connect(closeDoc)
	gui.Parent = player:WaitForChild("PlayerGui")
	docGui = gui
	-- Si te alejas, se cierra
	local opened = rootPos()
	task.spawn(function()
		while docGui == gui do
			task.wait(0.5)
			local p = rootPos()
			if p and opened and (p - opened).Magnitude > 16 then
				closeDoc()
			end
		end
	end)
end

local telescope: { Gui: ScreenGui?, Conn: RBXScriptConnection?, Index: number, Aim: CFrame?, Old: Enum.CameraType?, Fov: number? } = { Index = 1 }

local function telescopeTargets(aim: CFrame): { { Name: string, Look: Vector3 } }
	local moon = Vector3.new(-0.4, 0.7, 0.3)
	pcall(function()
		moon = Lighting:GetMoonDirection()
	end)
	if moon.Y < 0.1 then
		moon = Vector3.new(moon.X, 0.5, moon.Z)
	end
	local toCity = (Vector3.new(0, 60, 0) - aim.Position)
	return {
		{ Name = "🌙 La Luna", Look = moon.Unit },
		{ Name = "🌌 La Grieta", Look = Vector3.new(0.15, 0.85, -0.5).Unit },
		{ Name = "🏙️ Valmar", Look = Vector3.new(toCity.X, toCity.Y * 0.1, toCity.Z).Unit },
		{ Name = "✨ Estrellas", Look = Vector3.new(0.05, 1, 0.02).Unit },
		{ Name = "🔭 Hacia la rendija", Look = aim.LookVector },
	}
end

local function closeTelescope()
	local camera = workspace.CurrentCamera
	if telescope.Conn then
		telescope.Conn:Disconnect()
		telescope.Conn = nil
	end
	if telescope.Gui then
		telescope.Gui:Destroy()
		telescope.Gui = nil
	end
	if camera and telescope.Old then
		camera.CameraType = telescope.Old
		camera.FieldOfView = telescope.Fov or 70
		telescope.Old = nil
	end
end

local function openTelescope(aim: CFrame)
	closeTelescope()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	telescope.Aim = aim
	telescope.Old = camera.CameraType
	telescope.Fov = camera.FieldOfView
	telescope.Index = 1
	camera.CameraType = Enum.CameraType.Scriptable
	local gui = Instance.new("ScreenGui")
	gui.Name = "CosmeTelescopio"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 45
	-- Viñeta redonda del ocular
	local ring = Instance.new("Frame")
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.Size = UDim2.fromScale(1.6, 1.6)
	ring.BackgroundTransparency = 1
	ring.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 600
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Transparency = 0.05
	stroke.Parent = ring
	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(1, 0)
	rc.Parent = ring
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 0, 24)
	label.Size = UDim2.new(0, 360, 0, 40)
	label.BackgroundTransparency = 0.3
	label.BackgroundColor3 = Color3.fromRGB(10, 20, 40)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	label.TextScaled = true
	label.Parent = gui
	local function button(text: string, pos: UDim2, fn: () -> ())
		local b = Instance.new("TextButton")
		b.AnchorPoint = Vector2.new(0.5, 1)
		b.Position = pos
		b.Size = UDim2.new(0, 120, 0, 56)
		b.BackgroundColor3 = Color3.fromRGB(30, 60, 110)
		b.TextColor3 = Color3.new(1, 1, 1)
		b.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		b.TextSize = 24
		b.Text = text
		b.Parent = gui
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 12)
		c.Parent = b
		b.Activated:Connect(fn)
	end
	local targets = telescopeTargets(aim)
	local function refresh()
		label.Text = targets[telescope.Index].Name
	end
	button("◀", UDim2.new(0.5, -140, 1, -24), function()
		telescope.Index = (telescope.Index - 2) % #targets + 1
		refresh()
	end)
	button("Salir", UDim2.new(0.5, 0, 1, -24), closeTelescope)
	button("▶", UDim2.new(0.5, 140, 1, -24), function()
		telescope.Index = telescope.Index % #targets + 1
		refresh()
	end)
	refresh()
	gui.Parent = player:WaitForChild("PlayerGui")
	telescope.Gui = gui
	local current = aim.LookVector
	local start = rootPos()
	telescope.Conn = RunService.RenderStepped:Connect(function(dt)
		local want = targets[telescope.Index].Look
		current = current:Lerp(want, math.min(1, dt * 2.5)).Unit
		local eye = aim.Position + aim.LookVector * 6
		local drift = Vector3.new(math.sin(os.clock() * 0.3), math.cos(os.clock() * 0.23), 0) * 0.01
		camera.CFrame = CFrame.lookAt(eye, eye + current + drift)
		camera.FieldOfView = 22
		local p = rootPos()
		if not p or (start and (p - start).Magnitude > 10) then
			closeTelescope()
		end
	end)
end

---------------------------------------------------------------------
function CosmeHouseClient.init()
	local found = CollectionService:GetTagged("CosmeHouse")[1]
	while not found do
		task.wait(3)
		found = CollectionService:GetTagged("CosmeHouse")[1]
	end
	house = found
	local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CosmeHouse", 30) :: RemoteEvent?
	if remote then
		remote.OnClientEvent:Connect(function(kind: string, payload: any)
			if kind == "Doc" and type(payload) == "table" then
				showDoc(payload)
			elseif kind == "Telescope" and type(payload) == "table" and typeof(payload.Aim) == "CFrame" then
				openTelescope(payload.Aim)
			end
		end)
	end
	-- Lo que se anima (con streaming, lo de la casa llega por zonas: se recoge al llegar)
	local known: { [Instance]: boolean } = {}
	local burstKnown: { [Instance]: boolean } = {}
	local function scan()
		if not house then
			return
		end
		for _, d in house:GetDescendants() do
			if known[d] then
				continue
			end
			if d:HasTag("CosmeSpin") then
				known[d] = true
				addSpinner(d)
			elseif d:HasTag("CosmeRobot") and d:IsA("Model") then
				known[d] = true
				addRobot(d)
			elseif d:HasTag("CosmeFx") and d:IsA("BasePart") then
				known[d] = true
				table.insert(fxParts, d)
			elseif d:IsA("ImageLabel") and d:GetAttribute("SwirlSpeed") then
				known[d] = true
				table.insert(swirls, d)
			elseif d:HasTag("CosmeFlicker") and d:IsA("Model") then
				known[d] = true
				table.insert(flickers, d)
				setVisible(d, false)
			elseif d:IsA("Model") and d:HasTag("CosmePortal") then
				known[d] = true
				d:GetAttributeChangedSignal("Active"):Connect(function()
					if d:GetAttribute("Active") then
						portalFx(d)
					end
				end)
			end
			-- Ráfagas: el servidor marca BurstAt en la máquina o el experimento (Model o pieza con aviso)
			if not burstKnown[d] and (d:IsA("Model") or (d:IsA("BasePart") and d:FindFirstChildOfClass("ProximityPrompt") ~= nil)) then
				burstKnown[d] = true
				d:GetAttributeChangedSignal("BurstAt"):Connect(function()
					if active then
						burstIn(d)
					end
				end)
			end
		end
	end
	scan()
	task.spawn(function()
		while true do
			task.wait(4)
			local center = siteCenter()
			local pos = rootPos()
			if center and pos and (center - pos).Magnitude < NEAR + 60 then
				pcall(scan)
			end
		end
	end)
	-- Partículas cerca, portal que falla
	local nextFlicker = os.clock() + 10
	local flickerUntil = 0
	task.spawn(function()
		while true do
			task.wait(0.5)
			local pos = rootPos()
			local center = siteCenter()
			active = pos ~= nil and center ~= nil and (center - pos).Magnitude < NEAR
			for _, part in fxParts do
				local on = active and pos ~= nil and part.Parent ~= nil and (part.Position - pos).Magnitude < FX_NEAR
				if fxOn[part] ~= on then
					fxOn[part] = on
					setEmitters(part, on)
				end
			end
			local t = os.clock()
			if t > nextFlicker then
				flickerUntil = t + 3
				nextFlicker = t + 18 + math.random() * 20
			end
			for _, m in flickers do
				local show = m:GetAttribute("ShowUntil")
				local visible = active and (t < flickerUntil or (type(show) == "number" and show > now()))
				if m:GetAttribute("ClientVisible") ~= visible then
					m:SetAttribute("ClientVisible", visible)
					setVisible(m, visible)
				end
			end
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		if not active then
			return
		end
		local camera = workspace.CurrentCamera
		local focus = if camera then camera.CFrame.Position else (rootPos() or Vector3.zero)
		stepSpinners(dt, focus)
		stepRobots(dt, focus)
		for _, s in swirls do
			s.Rotation = (s.Rotation + (s:GetAttribute("SwirlSpeed") or 30) * dt) % 360
		end
	end)
end

return CosmeHouseClient
