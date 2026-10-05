-- Prueba de CLIENTE de las escenas (Lune, fuera de Roblox): la cámara y los controles SIEMPRE vuelven.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-cinematic.luau
--
-- Carga los módulos de verdad del cliente (Controls, CineCamera, Cinematics, HappeningClient,
-- DialogueUI) en un Roblox de mentira pequeño (instancias, señales, fotogramas, cámara, jugador con su
-- PlayerModule) y juega escenas de los tres sistemas:
--   1. Cinemáticas viejas (Cinematics): al acabar, al saltarlas, al morir en mitad, si fallan a medias,
--      y TODAS las de shared/LifeStory/Cinematics saltándolas.
--   2. Escenas del motor nuevo (HappeningClient): al acabar, al saltarlas (Stop) y al morir.
--   3. Conversaciones (DialogueUI): al acabar, con pregunta, al morir, si el servidor las corta y si
--      empiezan durante una cinemática.
-- En cada caso, después: los controles vuelven (PlayerModule:Enable y ningún motivo en Controls), la
-- cámara vuelve al juego (Custom, mirando a TU personaje, con su campo de visión), la interfaz vuelve,
-- se quitan InCinematic / InDialogue y los nombres flotantes de los demás vuelven.
--   4. Los OTROS jugadores no salen en plano durante tu escena (C-16, paquete P2). Si el juego aún no lo
--      hace (no hay nada que los esconda), la comprobación se OMITE con un aviso y no falla.
--
-- Los errores que salgan solo porque el doble no imita algo se arreglan aquí, en la prueba.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local task = require("@lune/task")

local V3, V2 = roblox.Vector3, roblox.Vector2
local Enum = roblox.Enum

-- Que nunca se quede colgada
task.delay(420, function()
	print("❌ La prueba no ha terminado en 7 minutos (algo se ha quedado esperando)")
	process.exit(1)
end)

-- CFrame.lookAt de Roblox (el de Lune da la vuelta al mirar hacia -Z)
local function lookAt(at: any, target: any, up: any?): any
	local look = target - at
	if look.Magnitude < 1e-6 then
		return roblox.CFrame.new(at)
	end
	look = look.Unit
	local right = look:Cross(up or V3.yAxis)
	if right.Magnitude < 1e-6 then
		right = look:Cross(V3.zAxis)
	end
	right = right.Unit
	return roblox.CFrame.fromMatrix(at, right, right:Cross(look).Unit, -look)
end
local CF = setmetatable({
	lookAt = lookAt,
	new = function(...)
		local a, b = ...
		if select("#", ...) == 2 and typeof(a) == "Vector3" and typeof(b) == "Vector3" then
			return lookAt(a, b)
		end
		return roblox.CFrame.new(...)
	end,
}, { __index = roblox.CFrame })

local failures, skipped = 0, 0
local function check(condition: any, message: string)
	if condition then
		print("  ✅ " .. message)
	else
		failures += 1
		print("  ❌ " .. message)
	end
end
local function skip(message: string)
	skipped += 1
	print("  ⏭ " .. message)
end
-- Fallo CONOCIDO del juego (apuntado en el informe, lo arregla otro paquete): se avisa sin fallar.
-- Cuando se arregle sale ✅ solo; entonces se puede cambiar a check.
local known = 0
local function knownBug(condition: any, message: string, where: string)
	if condition then
		print("  ✅ " .. message)
	else
		known += 1
		print("  ⚠ " .. message .. " — FALLO CONOCIDO: " .. where)
	end
end

---------------------------------------------------------------------
-- Señales
---------------------------------------------------------------------
local function Signal()
	local s = { handlers = {}, waiting = {} }
	function s.Connect(self, fn)
		local c = { Connected = true, fn = fn }
		function c.Disconnect(conn)
			conn.Connected = false
		end
		table.insert(self.handlers, c)
		return c
	end
	function s.Once(self, fn)
		local c
		c = self:Connect(function(...)
			c:Disconnect()
			fn(...)
		end)
		return c
	end
	function s.Wait(self)
		table.insert(self.waiting, coroutine.running())
		return coroutine.yield()
	end
	function s.Fire(self, ...)
		for _, c in table.clone(self.handlers) do
			if c.Connected then
				task.spawn(c.fn, ...)
			end
		end
		local waiting = self.waiting
		self.waiting = {}
		for _, thread in waiting do
			task.spawn(thread, ...)
		end
	end
	return s
end

---------------------------------------------------------------------
-- Instancias de mentira
---------------------------------------------------------------------
local GROUPS = {
	BasePart = { Part = true, MeshPart = true, WedgePart = true, UnionOperation = true, TrussPart = true },
	GuiObject = { Frame = true, TextLabel = true, TextButton = true, ImageLabel = true, ImageButton = true, ScrollingFrame = true, TextBox = true, CanvasGroup = true, ViewportFrame = true },
	GuiButton = { TextButton = true, ImageButton = true },
	LayerCollector = { ScreenGui = true, BillboardGui = true, SurfaceGui = true },
	GuiBase2d = { ScreenGui = true, BillboardGui = true, SurfaceGui = true, Frame = true, TextLabel = true, TextButton = true, ImageLabel = true, ImageButton = true },
	PVInstance = { Model = true, Part = true, MeshPart = true },
	ValueBase = { StringValue = true, NumberValue = true, BoolValue = true, ObjectValue = true, IntValue = true },
	Light = { PointLight = true, SpotLight = true, SurfaceLight = true },
}
local EVENTS = {
	Activated = true, MouseButton1Click = true, MouseButton1Down = true, MouseButton1Up = true, MouseEnter = true,
	MouseLeave = true, SelectionGained = true, SelectionLost = true, Changed = true, ChildAdded = true,
	ChildRemoved = true, DescendantAdded = true, DescendantRemoving = true, AncestryChanged = true,
	CharacterAdded = true, CharacterRemoving = true, Died = true, Event = true, OnClientEvent = true,
	Completed = true, Triggered = true, Touched = true, FocusLost = true, Destroying = true,
	InputBegan = true, InputEnded = true, InputChanged = true, MoveToFinished = true, StateChanged = true,
	HealthChanged = true, Running = true, Stopped = true, DidLoop = true, Ended = true,
}
local DEFAULTS = {
	Enabled = true, Visible = true, Text = "", Transparency = 0, LocalTransparencyModifier = 0,
	BackgroundTransparency = 0, TextTransparency = 0, ImageTransparency = 0, Health = 100, MaxHealth = 100,
	Sit = false, AutoRotate = true, Anchored = false, MaxVisibleGraphemes = -1, TextScaled = false,
	WalkSpeed = 16, JumpPower = 50, Archivable = true, Volume = 0.5, Playing = false, IsLoaded = true,
	AbsoluteSize = V2.new(100, 30), AbsolutePosition = V2.new(0, 0), TextBounds = V2.new(80, 20),
	ZIndex = 1, LayoutOrder = 0, Rotation = 0, TimePosition = 0, TimeLength = 1,
}

local InstMeta = {}
local Methods = {}
local function isFake(value: any): boolean
	return type(value) == "table" and getmetatable(value) == InstMeta
end

local function newInstance(class: string, props: { [string]: any }?)
	local self = setmetatable({
		__class = class,
		__props = { Name = class, ClassName = class },
		__children = {},
		__attrs = {},
		__signals = {},
		__attrSignals = {},
		__propSignals = {},
		__tags = {},
	}, InstMeta)
	if GROUPS.BasePart[class] then
		self.__props.CFrame = roblox.CFrame.new()
		self.__props.Size = V3.new(2, 2, 2)
	elseif class == "Humanoid" then
		self.__props.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	elseif class == "Camera" then
		self.__props.CFrame = roblox.CFrame.new(0, 10, 20)
		self.__props.CameraType = Enum.CameraType.Custom
		self.__props.FieldOfView = 70
		self.__props.ViewportSize = V2.new(1920, 1080)
	elseif class == "BindableEvent" then
		self.__props.Event = Signal()
	end
	for k, v in props or {} do
		self[k] = v
	end
	return self
end

local function signalOf(self, name: string)
	local s = rawget(self, "__signals")[name]
	if not s then
		s = Signal()
		rawget(self, "__signals")[name] = s
	end
	return s
end

local function descendants(self, list)
	for _, child in rawget(self, "__children") do
		table.insert(list, child)
		descendants(child, list)
	end
	return list
end

InstMeta.__index = function(self, key)
	local method = Methods[key]
	if method then
		return method
	end
	local props = rawget(self, "__props")
	local value = props[key]
	if value ~= nil then
		return value
	end
	if key == "Position" and props.CFrame then
		return props.CFrame.Position
	end
	if EVENTS[key] then
		return signalOf(self, key)
	end
	if key == "Parent" then
		return nil
	end
	-- Un hijo con ese nombre (como en Roblox: instancia.Hijo)
	for _, child in rawget(self, "__children") do
		if child.Name == key then
			return child
		end
	end
	return DEFAULTS[key]
end

InstMeta.__newindex = function(self, key, value)
	local props = rawget(self, "__props")
	if key == "Parent" then
		local old = props.Parent
		if old == value then
			return
		end
		if old then
			local list = rawget(old, "__children")
			local index = table.find(list, self)
			if index then
				table.remove(list, index)
			end
			signalOf(old, "ChildRemoved"):Fire(self)
		end
		props.Parent = value
		if value then
			table.insert(rawget(value, "__children"), self)
			signalOf(value, "ChildAdded"):Fire(self)
			local node = value
			while node do
				signalOf(node, "DescendantAdded"):Fire(self)
				node = rawget(node, "__props").Parent
			end
		end
		signalOf(self, "AncestryChanged"):Fire(self, value)
		return
	end
	if key == "Position" and GROUPS.BasePart[rawget(self, "__class")] then
		local cf = props.CFrame or roblox.CFrame.new()
		props.CFrame = roblox.CFrame.new(value) * cf.Rotation
		return
	end
	local old = props[key]
	props[key] = value
	if old ~= value then
		local s = rawget(self, "__propSignals")[key]
		if s then
			s:Fire()
		end
	end
end
InstMeta.__tostring = function(self)
	return rawget(self, "__props").Name
end

function Methods.IsA(self, name: string): boolean
	local class = rawget(self, "__class")
	return name == class or name == "Instance" or (GROUPS[name] ~= nil and GROUPS[name][class] == true)
end
function Methods.GetChildren(self)
	return table.clone(rawget(self, "__children"))
end
function Methods.GetDescendants(self)
	return descendants(self, {})
end
function Methods.FindFirstChild(self, name: string, recursive: boolean?)
	for _, child in rawget(self, "__children") do
		if child.Name == name then
			return child
		end
	end
	if recursive then
		for _, d in descendants(self, {}) do
			if d.Name == name then
				return d
			end
		end
	end
	return nil
end
function Methods.FindFirstChildOfClass(self, class: string)
	for _, child in rawget(self, "__children") do
		if rawget(child, "__class") == class then
			return child
		end
	end
	return nil
end
function Methods.FindFirstChildWhichIsA(self, class: string, recursive: boolean?)
	for _, child in (if recursive then descendants(self, {}) else rawget(self, "__children")) do
		if child:IsA(class) then
			return child
		end
	end
	return nil
end
function Methods.FindFirstAncestorOfClass(self, class: string)
	local node = self.Parent
	while node do
		if rawget(node, "__class") == class then
			return node
		end
		node = node.Parent
	end
	return nil
end
function Methods.FindFirstAncestorWhichIsA(self, class: string)
	local node = self.Parent
	while node do
		if node:IsA(class) then
			return node
		end
		node = node.Parent
	end
	return nil
end
function Methods.WaitForChild(self, name: string, timeout: number?)
	local deadline = os.clock() + (timeout or 5)
	while os.clock() < deadline do
		local child = self:FindFirstChild(name)
		if child then
			return child
		end
		task.wait(0.05)
	end
	return self:FindFirstChild(name)
end
function Methods.IsDescendantOf(self, other)
	local node = self.Parent
	while node do
		if node == other then
			return true
		end
		node = node.Parent
	end
	return false
end
function Methods.IsAncestorOf(self, other)
	return other:IsDescendantOf(self)
end
function Methods.Destroy(self)
	signalOf(self, "Destroying"):Fire()
	self.Parent = nil
	rawset(self, "__destroyed", true)
	for _, child in table.clone(rawget(self, "__children")) do
		child:Destroy()
	end
end
function Methods.ClearAllChildren(self)
	for _, child in table.clone(rawget(self, "__children")) do
		child:Destroy()
	end
end
function Methods.Clone(self)
	local copy = newInstance(rawget(self, "__class"))
	for k, v in rawget(self, "__props") do
		if k ~= "Parent" then
			rawget(copy, "__props")[k] = v
		end
	end
	return copy
end
function Methods.GetAttribute(self, name: string)
	return rawget(self, "__attrs")[name]
end
function Methods.SetAttribute(self, name: string, value: any)
	local attrs = rawget(self, "__attrs")
	local old = attrs[name]
	attrs[name] = value
	if old ~= value then
		local s = rawget(self, "__attrSignals")[name]
		if s then
			s:Fire()
		end
	end
end
function Methods.GetAttributes(self)
	return table.clone(rawget(self, "__attrs"))
end
function Methods.GetAttributeChangedSignal(self, name: string)
	local list = rawget(self, "__attrSignals")
	list[name] = list[name] or Signal()
	return list[name]
end
function Methods.GetPropertyChangedSignal(self, name: string)
	local list = rawget(self, "__propSignals")
	list[name] = list[name] or Signal()
	return list[name]
end
function Methods.AddTag(self, tag: string)
	rawget(self, "__tags")[tag] = true
end
function Methods.RemoveTag(self, tag: string)
	rawget(self, "__tags")[tag] = nil
end
function Methods.HasTag(self, tag: string)
	return rawget(self, "__tags")[tag] == true
end
function Methods.GetTags(self)
	local list = {}
	for tag in rawget(self, "__tags") do
		table.insert(list, tag)
	end
	return list
end
function Methods.GetPivot(self)
	local props = rawget(self, "__props")
	if props.CFrame then
		return props.CFrame
	end
	local primary = props.PrimaryPart or self:FindFirstChild("HumanoidRootPart") or self:FindFirstChildWhichIsA("BasePart", true)
	return if primary then primary.CFrame else roblox.CFrame.new()
end
function Methods.PivotTo(self, cf)
	local current = self:GetPivot()
	for _, d in descendants(self, {}) do
		if d:IsA("BasePart") then
			d.CFrame = cf * current:ToObjectSpace(d.CFrame)
		end
	end
end
function Methods.GetBoundingBox(self)
	return self:GetPivot(), V3.new(4, 5, 2)
end
function Methods.GetExtentsSize()
	return V3.new(4, 5, 2)
end
function Methods.GetScale()
	return 1
end
function Methods.Fire(self, ...) -- BindableEvent
	self.Event:Fire(...)
end
function Methods.FireServer(self, ...) -- RemoteEvent
	local sent = rawget(self, "__sent") or {}
	rawset(self, "__sent", sent)
	table.insert(sent, { ... })
end
function Methods.LoadAnimation()
	return {
		Play = function() end, Stop = function() end, AdjustSpeed = function() end, AdjustWeight = function() end,
		IsPlaying = false, Length = 1, Stopped = Signal(), Ended = Signal(), GetMarkerReachedSignal = function()
			return Signal()
		end,
	}
end
function Methods.GetPlayingAnimationTracks()
	return {}
end
function Methods.Play() end
function Methods.Stop() end
function Methods.Pause() end
function Methods.Resume() end
function Methods.Emit() end
function Methods.MoveTo() end
function Methods.ChangeState() end
function Methods.GetState()
	return Enum.HumanoidStateType.Running
end
function Methods.SetStateEnabled() end
function Methods.TakeDamage(self, amount)
	self.Health -= amount
end
function Methods.GetAppliedDescription()
	return newInstance("HumanoidDescription")
end
function Methods.CaptureFocus() end
function Methods.ReleaseFocus() end
function Methods.IsFocused()
	return false
end

local function typeofFake(value: any): string
	if isFake(value) then
		return "Instance"
	end
	return typeof(value)
end

---------------------------------------------------------------------
-- El mundo: workspace, cámara, jugadores
---------------------------------------------------------------------
local workspace = newInstance("Workspace", { Name = "Workspace" })
local camera = newInstance("Camera", { Name = "Camera", Parent = workspace })
workspace.CurrentCamera = camera
function workspace.Raycast()
	return nil
end
local serverClock0 = os.clock()
rawget(workspace, "__props").GetServerTimeNow = function()
	return 1000 + os.clock() - serverClock0
end
rawget(workspace, "__props").DistributedGameTime = 0
local storyScenes = newInstance("Folder", { Name = "StoryScenes", Parent = workspace })

-- El PlayerModule de Roblox: GetControls():Enable()/Disable(). Al reaparecer, Roblox los enciende solo.
local controlsState = { Enabled = true, Disables = 0 }
local controlsObject = {
	Enable = function()
		controlsState.Enabled = true
	end,
	Disable = function()
		controlsState.Enabled = false
		controlsState.Disables += 1
	end,
}

local function makeCharacter(name: string, at: any)
	local model = newInstance("Model", { Name = name })
	local root = newInstance("Part", { Name = "HumanoidRootPart", CFrame = roblox.CFrame.new(at), Parent = model })
	newInstance("Part", { Name = "Head", CFrame = roblox.CFrame.new(at + V3.new(0, 1.5, 0)), Parent = model })
	newInstance("Part", { Name = "UpperTorso", CFrame = roblox.CFrame.new(at + V3.new(0, 0.5, 0)), Parent = model })
	local humanoid = newInstance("Humanoid", { Name = "Humanoid", Parent = model })
	newInstance("Animator", { Name = "Animator", Parent = humanoid })
	model.PrimaryPart = root
	model.Parent = workspace
	return model, humanoid
end

local function makePlayer(name: string, userId: number, at: any)
	local p = newInstance("Player", { Name = name, DisplayName = name, UserId = userId })
	local gui = newInstance("PlayerGui", { Name = "PlayerGui", Parent = p })
	local scripts = newInstance("PlayerScripts", { Name = "PlayerScripts", Parent = p })
	local module = newInstance("ModuleScript", { Name = "PlayerModule", Parent = scripts })
	rawset(module, "__module", {
		GetControls = function()
			return controlsObject
		end,
	})
	local character = makeCharacter(name, at)
	p.Character = character
	return p, gui
end

local player, playerGui = makePlayer("Heroe", 101, V3.new(0, 3, 0))
-- Otro jugador, justo donde mira la cámara de las escenas (en el plano)
local other = makePlayer("Otra", 202, V3.new(2, 3, 2))
local otherHumanoid = other.Character:FindFirstChildOfClass("Humanoid")
camera.CameraSubject = player.Character:FindFirstChildOfClass("Humanoid")

-- La interfaz del juego (el HUD): tiene que volver después de cada escena
local hud = newInstance("ScreenGui", { Name = "HUD", Parent = playerGui })

local playerList = { player, other }
local Players = newInstance("Players", { Name = "Players" })
rawget(Players, "__props").LocalPlayer = player
function Players.GetPlayers()
	return playerList
end
function Players.GetPlayerFromCharacter(_, character)
	for _, p in playerList do
		if p.Character == character then
			return p
		end
	end
	return nil
end

-- Morir y reaparecer como en Roblox: Died, se quita el personaje, Roblox enciende los controles
-- (el PlayerModule nuevo) y la cámara sigue al nuevo personaje
local function respawn()
	local old = player.Character
	local humanoid = old:FindFirstChildOfClass("Humanoid")
	humanoid.Health = 0
	humanoid.Died:Fire()
	task.wait(0.2)
	player.CharacterRemoving:Fire(old)
	old.Parent = nil
	task.wait(0.2)
	local character, newHumanoid = makeCharacter("Heroe", V3.new(30, 3, 30))
	controlsState.Enabled = true
	player.Character = character
	camera.CameraSubject = newHumanoid
	player.CharacterAdded:Fire(character)
	task.wait(0.1)
	return character, newHumanoid
end

---------------------------------------------------------------------
-- Servicios
---------------------------------------------------------------------
local RenderStepped, Heartbeat, Stepped = Signal(), Signal(), Signal()
local RunService = {
	RenderStepped = RenderStepped, Heartbeat = Heartbeat, Stepped = Stepped, PreRender = RenderStepped, PreSimulation = Stepped, PostSimulation = Heartbeat,
	IsClient = function() return true end,
	IsServer = function() return false end,
	IsStudio = function() return false end,
	BindToRenderStep = function() end,
	UnbindFromRenderStep = function() end,
}
local frames = true
task.spawn(function()
	local last = os.clock()
	while frames do
		task.wait(1 / 60)
		local now = os.clock()
		local dt = now - last
		last = now
		RenderStepped:Fire(dt)
		Stepped:Fire(now, dt)
		Heartbeat:Fire(dt)
	end
end)

local TweenService = {}
function TweenService.Create(_, instance, info, goal)
	local tween = { Completed = Signal(), PlaybackState = Enum.PlaybackState.Begin }
	function tween.Play()
		for k, v in goal do
			instance[k] = v
		end
		tween.PlaybackState = Enum.PlaybackState.Completed
		task.delay((info and info.Time) or 0, function()
			tween.Completed:Fire(Enum.PlaybackState.Completed)
		end)
	end
	function tween.Cancel() end
	function tween.Pause() end
	function tween.Destroy() end
	return tween
end
function TweenService.GetValue(_, alpha)
	return alpha
end

local coreGui: { [any]: boolean } = {}
local StarterGui = {
	SetCoreGuiEnabled = function(_, kind, on)
		coreGui[kind] = on
	end,
	GetCoreGuiEnabled = function(_, kind)
		local value = coreGui[kind]
		return if value == nil then true else value
	end,
	SetCore = function() end,
	GetCore = function() return nil end,
}

local UserInputService = {
	InputBegan = Signal(), InputEnded = Signal(), InputChanged = Signal(), TouchTap = Signal(), JumpRequest = Signal(),
	LastInputTypeChanged = Signal(),
	TouchEnabled = false, KeyboardEnabled = true, MouseEnabled = true, GamepadEnabled = false, VREnabled = false,
	MouseBehavior = Enum.MouseBehavior.Default, MouseIconEnabled = true,
	GetFocusedTextBox = function() return nil end,
	GetLastInputType = function() return Enum.UserInputType.Keyboard end,
	IsKeyDown = function() return false end,
	GetMouseLocation = function() return V2.new(960, 540) end,
	GetConnectedGamepads = function() return {} end,
}
local actions: { [string]: any } = {}
local ContextActionService = {
	BindAction = function(_, name, fn)
		actions[name] = fn
	end,
	BindActionAtPriority = function(_, name, fn)
		actions[name] = fn
	end,
	UnbindAction = function(_, name)
		actions[name] = nil
	end,
	SetTitle = function() end,
	SetImage = function() end,
	SetPosition = function() end,
	GetButton = function() return nil end,
}

local remotes = newInstance("Folder", { Name = "Remotes" })
for _, name in { "LifeStory", "Dialogue", "Happening", "Cinematic", "StoryScenes" } do
	newInstance("RemoteEvent", { Name = name, Parent = remotes })
end

local nodeMeta = {}
local function node(path: string)
	return setmetatable({ __path = path }, nodeMeta)
end
nodeMeta.__index = function(self, key)
	local path = rawget(self, "__path")
	if key == "Parent" then
		return node((path:match("^(.*)/[^/]+$")))
	end
	return node(path .. "/" .. key)
end

local ReplicatedStorage = { Shared = node("src/shared"), Remotes = remotes }
function ReplicatedStorage.WaitForChild(self, name)
	return rawget(self, name)
end
function ReplicatedStorage.FindFirstChild(self, name)
	return rawget(self, name)
end

local CollectionService = {
	GetTagged = function(_, tag)
		local list = {}
		for _, d in workspace:GetDescendants() do
			if d:HasTag(tag) then
				table.insert(list, d)
			end
		end
		return list
	end,
	HasTag = function(_, instance, tag)
		return isFake(instance) and instance:HasTag(tag)
	end,
	AddTag = function(_, instance, tag)
		instance:AddTag(tag)
	end,
	RemoveTag = function(_, instance, tag)
		instance:RemoveTag(tag)
	end,
	GetInstanceAddedSignal = function()
		return Signal()
	end,
	GetInstanceRemovedSignal = function()
		return Signal()
	end,
}

local services = {
	Players = Players,
	RunService = RunService,
	TweenService = TweenService,
	StarterGui = StarterGui,
	UserInputService = UserInputService,
	ContextActionService = ContextActionService,
	ReplicatedStorage = ReplicatedStorage,
	CollectionService = CollectionService,
	Workspace = workspace,
	Lighting = newInstance("Lighting", { Name = "Lighting", ClockTime = 14 }),
	SoundService = newInstance("SoundService", { Name = "SoundService" }),
	Debris = { AddItem = function() end },
	HttpService = {
		JSONEncode = function(_, v) return serde.encode("json", v) end,
		JSONDecode = function(_, v) return serde.decode("json", v) end,
		GenerateGUID = function() return tostring(math.random(1, 1e9)) end,
	},
	GuiService = { GetGuiInset = function() return V2.new(0, 36), V2.new(0, 0) end, SelectedObject = nil },
	TextService = { GetTextSize = function() return V2.new(100, 20) end },
}
local game = { PlaceId = 1, JobId = "prueba", CreatorId = 1 }
function game.GetService(_, name)
	local s = services[name]
	if s == nil then
		error("Servicio sin doble: " .. name)
	end
	return s
end

---------------------------------------------------------------------
-- Cargador de módulos (src/client y src/shared) con dobles para lo que no se prueba aquí
---------------------------------------------------------------------
local calls: { string } = {}
local function stub(name: string, overrides: { [string]: any }?)
	return setmetatable(overrides or {}, {
		__index = function(_, key)
			return function()
				table.insert(calls, name .. "." .. tostring(key))
				return nil
			end
		end,
	})
end
local actorLifeFail = false
local mocks: { [string]: any } = {
	["src/client/Controllers/StoryAudio"] = stub("StoryAudio"),
	["src/client/Controllers/DayLight"] = stub("DayLight"),
	["src/client/Controllers/SoundFx"] = stub("SoundFx"),
	["src/client/Controllers/SkyRift"] = stub("SkyRift", { worldPoint = function() return V3.new(0, 300, 0) end }),
	["src/client/Controllers/StoryFx"] = stub("StoryFx"),
	["src/client/Controllers/LifeStory"] = stub("LifeStory", { isShowing = function() return false end }),
	["src/client/Controllers/ActorLife"] = stub("ActorLife", {
		cast = function() return {} end,
		find = function() return nil end,
		play = function()
			if actorLifeFail then
				error("fallo a propósito en mitad de la escena")
			end
		end,
	}),
	["src/client/UI/SpeechBubbles"] = stub("SpeechBubbles", {
		show = function() return false end,
		isOnScreen = function() return true end,
	}),
}

local warnings: { string } = {}
local cache: { [string]: any } = {}
local loadModule
local function requireTarget(target: any)
	if isFake(target) then
		local module = rawget(target, "__module")
		if module then
			return module
		end
		error("require de una instancia sin módulo: " .. tostring(target))
	end
	return loadModule(rawget(target, "__path"))
end
local Instance = {
	new = function(class: string, parent: any?)
		local instance = newInstance(class)
		if parent then
			instance.Parent = parent
		end
		return instance
	end,
}
local RaycastParams = { new = function() return {} end }
local OverlapParams = { new = function() return {} end }
local TweenInfo = {
	new = function(time, ...)
		return { Time = time or 1 }
	end,
}
local baseEnv = getfenv(1)
function loadModule(path: string): any
	if mocks[path] ~= nil then
		return mocks[path]
	end
	if cache[path] ~= nil then
		return cache[path]
	end
	local file = path .. ".luau"
	if not fs.isFile(file) then
		error("Módulo no encontrado: " .. path)
	end
	local env = setmetatable({
		script = node(path),
		require = requireTarget,
		game = game,
		workspace = workspace,
		task = task,
		Instance = Instance,
		Vector3 = V3,
		Vector2 = V2,
		CFrame = CF,
		Color3 = roblox.Color3,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		Rect = roblox.Rect,
		Enum = Enum,
		Font = roblox.Font,
		ColorSequence = roblox.ColorSequence,
		ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
		NumberSequence = roblox.NumberSequence,
		NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
		NumberRange = roblox.NumberRange,
		TweenInfo = TweenInfo,
		RaycastParams = RaycastParams,
		OverlapParams = OverlapParams,
		Random = { new = function() return { NextNumber = function(_, a, b) return (a or 0) + ((b or 1) - (a or 0)) * 0.5 end, NextInteger = function(_, a) return a end } end },
		typeof = typeofFake,
		warn = function(...)
			local parts = {}
			for i = 1, select("#", ...) do
				table.insert(parts, tostring((select(i, ...))))
			end
			table.insert(warnings, table.concat(parts, " "))
		end,
		print = function() end,
	}, { __index = baseEnv })
	local chunk = luau.load(fs.readFile(file), { debugName = file, environment = env })
	local result = chunk()
	cache[path] = result
	return result
end

local Controls = loadModule("src/client/Controllers/Controls")
local CineCamera = loadModule("src/client/Controllers/CineCamera")
local Cinematics = loadModule("src/client/Controllers/Cinematics")
local HappeningClient = loadModule("src/client/Controllers/HappeningClient")
local DialogueUI = loadModule("src/client/Controllers/DialogueUI")
local Definitions = loadModule("src/shared/LifeStory/Cinematics")
local HappeningIndex = loadModule("src/shared/LifeStory/HappeningIndex")
local Strings = loadModule("src/shared/LifeStory/Strings")
local SceneClient = nil
pcall(function()
	SceneClient = loadModule("src/client/Controllers/SceneClient")
end)
HappeningClient.init()
DialogueUI.init()
if SceneClient and SceneClient.init then
	task.spawn(SceneClient.init)
end
task.wait(0.3)

---------------------------------------------------------------------
-- Comprobaciones comunes
---------------------------------------------------------------------
local function humanoidNow()
	return player.Character and player.Character:FindFirstChildOfClass("Humanoid")
end

local function waitUntil(condition: () -> boolean, seconds: number): boolean
	local deadline = os.clock() + seconds
	while os.clock() < deadline do
		if condition() then
			return true
		end
		task.wait(0.05)
	end
	return condition()
end

-- ¿Se ha devuelto todo? (lista de lo que falta)
local function leftovers(): { string }
	local list = {}
	if not controlsState.Enabled then
		table.insert(list, "controles apagados (PlayerModule)")
	end
	if Controls.isDisabled() then
		local reasons = {}
		for _, reason in { "Cinematica", "Escena", "Dialogo" } do
			if Controls.isDisabled(reason) then
				table.insert(reasons, reason)
			end
		end
		table.insert(list, "Controls sigue con motivo " .. table.concat(reasons, ", "))
	end
	if camera.CameraType ~= Enum.CameraType.Custom then
		table.insert(list, "cámara " .. tostring(camera.CameraType))
	end
	if camera.CameraSubject ~= humanoidNow() then
		table.insert(list, "la cámara no sigue a tu personaje")
	end
	if math.abs(camera.FieldOfView - 70) > 0.01 then
		table.insert(list, ("campo de visión %.1f"):format(camera.FieldOfView))
	end
	if player:GetAttribute("InCinematic") ~= nil then
		table.insert(list, "InCinematic sigue puesto")
	end
	if player:GetAttribute("InDialogue") ~= nil then
		table.insert(list, "InDialogue sigue puesto")
	end
	if not hud.Enabled then
		table.insert(list, "el HUD sigue escondido")
	end
	if otherHumanoid.DisplayDistanceType == Enum.HumanoidDisplayDistanceType.None then
		table.insert(list, "el nombre del otro jugador sigue escondido")
	end
	for _, part in other.Character:GetDescendants() do
		if part:IsA("BasePart") and (part.LocalTransparencyModifier >= 1) then
			table.insert(list, "el otro jugador sigue invisible")
			break
		end
	end
	return list
end

local function restoredCheck(what: string)
	local ok = waitUntil(function()
		return #leftovers() == 0
	end, 3)
	local list = leftovers()
	check(ok, what .. (if #list > 0 then " · falta: " .. table.concat(list, "; ") else ""))
end

-- ¿El otro jugador está escondido en tu pantalla? (cualquiera de las formas: invisible localmente,
-- transparente o fuera del workspace)
local function otherHidden(): boolean
	local character = other.Character
	if not character or not character:IsDescendantOf(workspace) then
		return true
	end
	local parts, hidden = 0, 0
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			parts += 1
			if part.LocalTransparencyModifier >= 1 or part.Transparency >= 1 then
				hidden += 1
			end
		end
	end
	return parts > 0 and hidden == parts
end

-- ¿Existe en el juego algo que esconda a los demás jugadores durante una escena? (C-16, paquete P2:
-- una función exportada con ese fin en los módulos de cámara y escenas). Si no existe, se omite.
local function hideFeature(): string?
	local modules = { CineCamera = CineCamera, Cinematics = Cinematics, HappeningClient = HappeningClient, DialogueUI = DialogueUI, Controls = Controls, SceneClient = SceneClient }
	for name, module in modules do
		if type(module) == "table" then
			for key, value in module do
				if type(value) == "function" and type(key) == "string" then
					local lower = key:lower()
					if (lower:find("hide", 1, true) or lower:find("ocult", 1, true) or lower:find("hidden", 1, true))
						and (lower:find("player", 1, true) or lower:find("other", 1, true) or lower:find("otros", 1, true) or lower:find("jugador", 1, true)) then
						return name .. "." .. key
					end
				end
			end
		end
	end
	return nil
end
-- Conversaciones: el servidor manda trozos (Show) y el jugador pasa frases con Espacio
local dialogueRemote = remotes:FindFirstChild("Dialogue")
local npc = makeCharacter("Nico", V3.new(6, 3, 0))
local token = 0
local function show(lines: { any }, options: { string }?, final: boolean?)
	token += 1
	local list = {}
	for _, text in lines do
		table.insert(list, { Text = text, Name = "Nico", Actor = npc, Emotion = "Calm" })
	end
	dialogueRemote.OnClientEvent:Fire("Show", { Token = token, Seq = 1, Lines = list, Options = options, Ask = if options then "¿Y tú?" else nil, Final = final ~= false })
	return token
end
local function press()
	UserInputService.InputBegan:Fire({ KeyCode = Enum.KeyCode.Space, UserInputType = Enum.UserInputType.Keyboard }, false)
end
local function readUntilClosed(seconds: number): boolean
	return waitUntil(function()
		if DialogueUI.isOpen() then
			press()
		end
		return not DialogueUI.isOpen()
	end, seconds)
end

local hideResults: { [string]: boolean } = {}
local function sampleHidden(scene: string)
	hideResults[scene] = otherHidden()
end

---------------------------------------------------------------------
print("\n▶ 1. Cinemáticas (Cinematics): la cámara y los controles vuelven")
---------------------------------------------------------------------
local V = V3.new
Definitions.P10_Corta = {
	Duration = 1.4,
	Shots = { { From = { "A", V(8, 4, 8) }, To = { "A", V(9, 4, 8) }, Look = { "A", V(0, 1, 0) }, Duration = 1.4, Fov = 50 } },
	Lines = { { At = 0.1, TextKey = "CINE.SKIP" } },
	Titles = { { At = 0.2, TextKey = "CINE.SKIP", Duration = 0.5 } },
}
Definitions.P10_Larga = {
	Duration = 30,
	Shots = { { Orbit = "A", Radius = 10, Height = 4, FromAngle = 0, ToAngle = 90, Duration = 30 } },
}
Definitions.P10_Falla = {
	Duration = 3,
	Shots = { { From = { "A", V(8, 4, 8) }, To = { "A", V(9, 4, 8) }, Look = { "A", V(0, 1, 0) }, Duration = 3 } },
	Anims = { { At = 0.3, Who = "Player", Play = "Wave" } },
}
local anchors = { A = CF.new(V(2, 0, 2)) }

local function playCinematic(id: string, during: (() -> ())?): number
	local done = false
	local start = os.clock()
	task.spawn(function()
		Cinematics.play({ Id = id, Anchors = anchors, Names = {}, Args = {} })
		done = true
	end)
	if during then
		during()
	end
	waitUntil(function()
		return done
	end, 40)
	return if done then os.clock() - start else -1
end

local function skipButton(): any
	local gui = playerGui:FindFirstChild("Cinematic")
	if not gui then
		return nil
	end
	local label = Strings.get("CINE.SKIP")
	for _, d in gui:GetDescendants() do
		if d:IsA("TextButton") and d.Text == label then
			return d
		end
	end
	return nil
end

-- 1a. Hasta el final
do
	local inside = {}
	local seconds = playCinematic("P10_Corta", function()
		task.wait(0.6)
		inside.Camera = camera.CameraType == Enum.CameraType.Scriptable
		inside.Controls = not controlsState.Enabled and Controls.isDisabled("Cinematica")
		inside.Flag = player:GetAttribute("InCinematic") == true
		inside.Hud = hud.Enabled == false
		inside.Names = otherHumanoid.DisplayDistanceType == Enum.HumanoidDisplayDistanceType.None
		sampleHidden("Cinematica")
	end)
	check(seconds > 0, ("La cinemática corta termina (%.1f s)"):format(seconds))
	check(inside.Camera and inside.Controls and inside.Flag, "Durante la escena: cámara de la escena, controles quitados e InCinematic")
	check(inside.Hud and inside.Names, "Durante la escena: el HUD y los nombres flotantes se esconden")
	restoredCheck("Al acabar: vuelven los controles, la cámara (Custom, a tu personaje, FOV), el HUD, los nombres y se quita InCinematic")
	check(playerGui:FindFirstChild("Cinematic") == nil, "Al acabar se quita la interfaz de la escena")
	local remote = remotes:FindFirstChild("LifeStory")
	local told = false
	for _, sent in rawget(remote, "__sent") or {} do
		told = told or (sent[1] == "CinematicDone" and sent[2] == "P10_Corta")
	end
	check(told, "Al acabar se avisa al servidor (CinematicDone)")
end

-- 1b. Saltándola
do
	local found = false
	local seconds = playCinematic("P10_Larga", function()
		task.wait(0.6)
		local button = skipButton()
		found = button ~= nil
		if button then
			button.Activated:Fire()
		end
	end)
	check(found and seconds > 0 and seconds < 5, ("Saltar una escena de 30 s la corta enseguida (%.1f s)"):format(seconds))
	restoredCheck("Al saltarla: vuelven controles, cámara, HUD y nombres; sin InCinematic")
end

-- 1c. Muriendo en mitad
do
	local after = {}
	local seconds = playCinematic("P10_Corta", function()
		task.wait(0.3)
		respawn()
		after.StillDisabled = waitUntil(function()
			return not controlsState.Enabled
		end, 0.5)
	end)
	check(seconds > 0, "Morir en mitad de una cinemática: la escena termina igual")
	check(after.StillDisabled, "…mientras sigue, al reaparecer no se puede mover (Controls reaplica el bloqueo)")
	restoredCheck("…y al acabar vuelven los controles y la cámara sigue a tu NUEVO personaje")
end

-- 1d. Si la escena falla a medias
do
	actorLifeFail = true
	local seconds = playCinematic("P10_Falla")
	actorLifeFail = false
	check(seconds > 0, "Una escena que falla a medias termina (pcall)")
	restoredCheck("…y lo devuelve todo (interfaz, controles, cámara)")
	check(playerGui:FindFirstChild("Cinematic") == nil, "…y quita su interfaz")
end

-- 1e. Dos seguidas sin esperar (la segunda llega mientras la primera aún se ve)
do
	local doneA, doneB = false, false
	task.spawn(function()
		Cinematics.play({ Id = "P10_Corta", Anchors = anchors })
		doneA = true
	end)
	task.wait(0.4)
	task.spawn(function()
		Cinematics.play({ Id = "P10_Corta", Anchors = anchors })
		doneB = true
	end)
	waitUntil(function()
		return doneA and doneB
	end, 15)
	check(doneA and doneB, "Dos cinemáticas solapadas terminan las dos")
	restoredCheck("…y al acabar la última todo vuelve (el contador de motivos no se queda colgado)")
end

-- 1f. Todas las cinemáticas del juego, saltándolas
do
	local ids = {}
	for id, def in Definitions do
		if type(def) == "table" and def.Duration and not id:find("^P10_") then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	local bad = {}
	for _, id in ids do
		local def = Definitions[id]
		local ankers = {}
		local i = 0
		for name in def.Anchors or {} do
			i += 1
			ankers[name] = CF.new(V(i * 10, 0, i * 5))
		end
		local done = false
		task.spawn(function()
			Cinematics.play({ Id = id, Anchors = ankers, Names = {}, Args = {} })
			done = true
		end)
		task.wait(0.35)
		local button = skipButton()
		if button then
			button.Activated:Fire()
		end
		waitUntil(function()
			return done
		end, 8)
		local left = leftovers()
		if not done or not button or #left > 0 then
			table.insert(bad, ("%s (%s)"):format(id, if not done then "no termina" elseif not button then "sin botón Saltar" else table.concat(left, "; ")))
			waitUntil(function()
				return #leftovers() == 0
			end, 2)
		end
	end
	check(#ids > 20 and #bad == 0, ("Las %d cinemáticas del juego se pueden saltar y lo devuelven todo%s"):format(#ids, if #bad > 0 then ": " .. table.concat(bad, " · ") else ""))
end

---------------------------------------------------------------------
print("\n▶ 2. Escenas del motor nuevo (HappeningClient): la cámara y los controles vuelven")
---------------------------------------------------------------------
local all = HappeningIndex.all()
all.P10_Escena = {
	Duration = 1.2,
	Anchors = { A = "Player" },
	Tracks = {
		Camera = { { At = 0, Duration = 1.2, Fixed = { "A", V(4, 2, 6) }, Look = { "A", V(0, 1, 0) }, Fov = 50 } },
		Lines = { { At = 0.1, Speaker = "Narrador", Text = "Hola." } },
	},
}
all.P10_EscenaLarga = {
	Duration = 30,
	Anchors = { A = "Player" },
	Tracks = {
		Camera = { { At = 0, Duration = 30, Orbit = "A", Radius = 10, Height = 4, FromAngle = 0, ToAngle = 90 } },
	},
}
local happeningRemote = remotes:FindFirstChild("Happening")
local serial = 0
local function playHappening(id: string, during: ((number) -> ())?): number
	serial += 1
	local run = serial
	local start = os.clock()
	happeningRemote.OnClientEvent:Fire("Play", { Run = run, Id = id, StartAt = workspace:GetServerTimeNow(), Anchors = { A = CF.new(V(2, 0, 2)) }, Names = {}, Args = {} })
	if during then
		during(run)
	end
	local finished = waitUntil(function()
		for _, sent in rawget(happeningRemote, "__sent") or {} do
			if sent[1] == "Done" and sent[2] == run then
				return true
			end
		end
		return false
	end, 40)
	return if finished then os.clock() - start else -1
end

do
	local inside = {}
	local seconds = playHappening("P10_Escena", function()
		task.wait(0.5)
		inside.Camera = camera.CameraType == Enum.CameraType.Scriptable
		inside.Controls = not controlsState.Enabled and Controls.isDisabled("Escena")
		inside.Flag = player:GetAttribute("InCinematic") == true and HappeningClient.isPlaying()
		sampleHidden("Escena")
	end)
	check(seconds > 0, ("La escena termina sola (%.1f s)"):format(seconds))
	check(inside.Camera and inside.Controls and inside.Flag, "Durante la escena: cámara de la escena, controles quitados e InCinematic")
	restoredCheck("Al acabar: vuelven los controles, la cámara, el HUD y los nombres; sin InCinematic")
end

do
	local seconds = playHappening("P10_EscenaLarga", function(run)
		task.wait(0.6)
		happeningRemote.OnClientEvent:Fire("Stop", { Run = run, Skipped = true })
	end)
	check(seconds > 0 and seconds < 5, ("Saltar (el servidor dice Stop) corta la escena enseguida (%.1f s)"):format(seconds))
	restoredCheck("Al saltarla lo devuelve todo")
end

do
	local seconds = playHappening("P10_Escena", function()
		task.wait(0.3)
		respawn()
	end)
	check(seconds > 0, "Morir en mitad de una escena: termina igual")
	restoredCheck("…y al acabar vuelven los controles y la cámara sigue a tu nuevo personaje")
end

do
	-- Una cinemática vieja que acaba mientras sigue una escena del motor nuevo: la escena sigue mandando
	-- (InCinematic puesto, controles quitados, cámara de la escena) y al final todo vuelve
	local done = false
	local mid = {}
	local seconds = playHappening("P10_EscenaLarga", function(run)
		task.wait(0.3)
		task.spawn(function()
			Cinematics.play({ Id = "P10_Corta", Anchors = anchors })
			done = true
		end)
		waitUntil(function()
			return done
		end, 10)
		task.wait(0.3)
		mid.Flag = player:GetAttribute("InCinematic") == true
		mid.Controls = not controlsState.Enabled
		mid.Camera = camera.CameraType == Enum.CameraType.Scriptable
		happeningRemote.OnClientEvent:Fire("Stop", { Run = run, Skipped = true })
	end)
	check(seconds > 0 and mid.Controls and mid.Camera, "Cinemática dentro de una escena: al acabar la cinemática, la escena sigue con su cámara y sin controles")
	knownBug(mid.Flag, "…y sigue marcada InCinematic (las armas y las frases sueltas no se cuelan)",
		"Cinematics.luau:224 quita InCinematic sin mirar HappeningClient.isPlaying()")
	restoredCheck("…y al acabar la escena todo vuelve")
end

do
	-- Una conversación que llega en mitad de una escena del motor nuevo: tendría que esperar (como con
	-- las cinemáticas viejas), y al final todo vuelve
	local opened = false
	local seconds = playHappening("P10_EscenaLarga", function(run)
		task.wait(0.4)
		show({ "Hola en mitad de la escena." })
		task.wait(0.5)
		opened = DialogueUI.isOpen()
		happeningRemote.OnClientEvent:Fire("Stop", { Run = run, Skipped = true })
	end)
	knownBug(not opened, "Una conversación no se abre encima de una escena del motor nuevo",
		"DialogueUI.luau:641/654 solo espera a Cinematics.isPlaying(), no a HappeningClient.isPlaying()")
	readUntilClosed(6)
	check(seconds > 0, "Escena + conversación: la escena termina")
	restoredCheck("…y al final todo vuelve (cámara, controles, InDialogue, InCinematic)")
end

do
	-- Las escenas de verdad: empezar y saltar
	local bad, count = {}, 0
	for id in all do
		if not id:find("^P10_") then
			count += 1
			local seconds = playHappening(id, function(run)
				task.wait(0.8)
				happeningRemote.OnClientEvent:Fire("Stop", { Run = run, Skipped = true })
			end)
			local left = leftovers()
			if seconds < 0 or #left > 0 then
				table.insert(bad, ("%s (%s)"):format(id, if seconds < 0 then "no termina" else table.concat(left, "; ")))
				waitUntil(function()
					return #leftovers() == 0
				end, 2)
			end
		end
	end
	check(#bad == 0, ("Las %d escenas del motor nuevo se pueden saltar y lo devuelven todo%s"):format(count, if #bad > 0 then ": " .. table.concat(bad, " · ") else ""))
end

---------------------------------------------------------------------
print("\n▶ 3. Conversaciones (DialogueUI): la cámara y los controles vuelven")
---------------------------------------------------------------------
do
	show({ "Hola.", "¿Qué tal el día?" })
	local opened = waitUntil(function()
		return DialogueUI.isOpen()
	end, 3)
	task.wait(0.3)
	local inside = {
		Camera = camera.CameraType == Enum.CameraType.Scriptable,
		Controls = not controlsState.Enabled and Controls.isDisabled("Dialogo"),
		Flag = player:GetAttribute("InDialogue") == true,
	}
	sampleHidden("Dialogo")
	check(opened and inside.Camera and inside.Controls and inside.Flag, "Durante la conversación: plano de diálogo, controles quitados e InDialogue")
	check(readUntilClosed(8), "La conversación se lee entera y se cierra")
	restoredCheck("Al acabar: vuelven los controles, la cámara, los nombres; sin InDialogue")
end

do
	show({ "Una pregunta." }, { "Sí", "No" })
	waitUntil(function()
		return actions.DialogueOptions ~= nil or not DialogueUI.isOpen()
	end, 6)
	local asked = false
	for _ = 1, 60 do
		if actions.DialogueOptions then
			asked = true
			actions.DialogueOptions("DialogueOptions", Enum.UserInputState.Begin, { KeyCode = Enum.KeyCode.Two })
			break
		end
		press()
		task.wait(0.1)
	end
	check(asked, "Sale la pregunta con sus opciones")
	local answered = waitUntil(function()
		for _, sent in rawget(dialogueRemote, "__sent") or {} do
			if sent[1] == "Next" and sent[2] == token and sent[3] == 2 then
				return true
			end
		end
		return false
	end, 3)
	check(answered, "La respuesta elegida llega al servidor")
	check(readUntilClosed(4), "Tras contestar se cierra (no llega nada más)")
	restoredCheck("…y todo vuelve")
end

do
	show({ "Esto es muy largo y no lo vas a terminar.", "Otra frase." })
	waitUntil(function()
		return DialogueUI.isOpen()
	end, 3)
	task.wait(0.3)
	respawn()
	check(waitUntil(function()
		return not DialogueUI.isOpen()
	end, 3), "Al morir en plena conversación se cierra")
	restoredCheck("…y vuelven los controles y la cámara (al nuevo personaje)")
end

do
	local t = show({ "El servidor me va a cortar.", "Otra." })
	waitUntil(function()
		return DialogueUI.isOpen()
	end, 3)
	task.wait(0.3)
	dialogueRemote.OnClientEvent:Fire("Close", { Token = t })
	check(waitUntil(function()
		return not DialogueUI.isOpen()
	end, 3), "Si el servidor corta la conversación, se cierra")
	restoredCheck("…y todo vuelve")
end

do
	-- Una conversación que llega en mitad de una cinemática espera a que acabe, y luego todo vuelve
	local done = false
	task.spawn(function()
		Cinematics.play({ Id = "P10_Corta", Anchors = anchors })
		done = true
	end)
	task.wait(0.3)
	show({ "Ya ha terminado la escena." })
	task.wait(0.3)
	check(not DialogueUI.isOpen(), "Una conversación no se abre encima de una cinemática")
	waitUntil(function()
		return done
	end, 10)
	check(waitUntil(function()
		return DialogueUI.isOpen()
	end, 4), "…se abre cuando la cinemática acaba")
	check(readUntilClosed(6), "…y se lee entera")
	restoredCheck("Cinemática + conversación: al final todo vuelve")
end

---------------------------------------------------------------------
print("\n▶ 4. Los otros jugadores no salen en tu escena (C-16)")
---------------------------------------------------------------------
do
	local feature = hideFeature()
	local anyHidden = false
	for _, hidden in hideResults do
		anyHidden = anyHidden or hidden
	end
	if feature or anyHidden then
		for _, scene in { "Cinematica", "Escena", "Dialogo" } do
			check(hideResults[scene] == true, ("Durante una %s, el otro jugador que está en el plano no se ve en tu pantalla"):format(scene:lower()))
		end
		local list = leftovers()
		local visible = true
		for _, text in list do
			visible = visible and not text:find("otro jugador", 1, true)
		end
		check(visible, "Al acabar, el otro jugador vuelve a verse")
	else
		skip("Ocultar a los otros jugadores en plano aún no existe en el juego (paquete P2, C-16): se omite")
	end
end

frames = false
if #warnings > 0 then
	print("\n  Avisos del juego durante la prueba (" .. #warnings .. "):")
	local seen = {}
	for _, w in warnings do
		if not seen[w] then
			seen[w] = true
			print("    · " .. w:sub(1, 200))
		end
	end
end
print(("\n%s%s%s"):format(
	if failures == 0 then "✅ Todo correcto" else ("❌ %d fallos"):format(failures),
	if skipped > 0 then (" (%d omitidas)"):format(skipped) else "",
	if known > 0 then (" (%d fallos conocidos del juego, ⚠)"):format(known) else ""
))
process.exit(if failures == 0 then 0 else 1)
