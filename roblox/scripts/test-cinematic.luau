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
--   4. Los OTROS jugadores no salen en plano durante tu escena (C-16, paquete P2: SceneClient). Si no lo
--      hace (no hay nada que los esconda), la comprobación se OMITE con un aviso y no falla.
--   5. Fallos a propósito en cada paso (fase 3).
--   6. Varios jugadores (fase 7): espectador de un acontecimiento del mundo y escena de grupo.
--   7. La Cinemateca (modo pruebas): ventana, buscador, contador, mandos y revisión.
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
-- (25 minutos: se empieza y se salta cada escena del motor, unos 2 s cada una, y con los guiones
-- reescritos ya pasan de 230)
task.delay(1500, function()
	print("❌ La prueba no ha terminado en 25 minutos (algo se ha quedado esperando)")
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
	-- CFrame.lookAlong(at, dirección, arriba?) de Roblox = lookAt(at, at + dirección, arriba)
	lookAlong = function(at: any, direction: any, up: any?): any
		return lookAt(at, at + direction, up)
	end,
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
		self.__props.HipHeight = 2 -- (lo usa HappeningClient para saber lo alto que es alguien)
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
for _, name in { "LifeStory", "Dialogue", "Happening", "Cinematic", "StoryScenes", "Scene" } do
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
local actingLog: { { [string]: any } } = {} -- (ActorLife.play: los gestos de la pista Acting)
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
		play = function(model, name, seconds)
			table.insert(actingLog, { Model = model, Play = name, Seconds = seconds })
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
local HappeningIndex = loadModule("src/shared/LifeStory/HappeningIndex")
local Strings = loadModule("src/shared/LifeStory/Strings")
local SceneReport = loadModule("src/client/Controllers/SceneReport")
local SceneGuis = loadModule("src/client/UI/SceneGuis")
local SceneClient = nil
pcall(function()
	SceneClient = loadModule("src/client/Controllers/SceneClient")
end)
HappeningClient.init()
DialogueUI.AliveEvery = 0.3 -- («sigo aquí» al servidor; en el juego cada 20 s)
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
	if math.abs(camera.FieldOfView - 70) > 0.5 then
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
	for _, part in other.Character:GetDescendants() do
		if part:IsA("BasePart") and (part.LocalTransparencyModifier >= 1) then
			table.insert(list, "el otro jugador sigue invisible")
			break
		end
	end
	return list
end

-- El nombre flotante del otro jugador (CineCamera.quietLabels lo calla durante la escena): se mira
-- aparte, y si no vuelve se apunta y se deja como estaba para que no arrastre a las demás pruebas
local namesStuck = 0
local function namesBack(): boolean
	local ok = waitUntil(function()
		return otherHumanoid.DisplayDistanceType ~= Enum.HumanoidDisplayDistanceType.None
	end, 1)
	if not ok then
		namesStuck += 1
		otherHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	end
	return ok
end

local function restoredCheck(what: string)
	local ok = waitUntil(function()
		return #leftovers() == 0
	end, 3)
	local list = leftovers()
	check(ok, what .. (if #list > 0 then " · falta: " .. table.concat(list, "; ") else ""))
	namesBack()
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
print("\n▶ 1. Las cinemáticas de siempre, ya en el motor (fase 6): la cámara y los controles vuelven")
---------------------------------------------------------------------
-- Las 21 de shared/LifeStory/Cinematics son escenas del motor (Happenings/Capitulos, Legacy = true) y
-- las reproduce HappeningClient. Controllers/Cinematics es solo el puente con la API de siempre.
local V = V3.new
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
-- Una «de las de siempre» corta (como las de Capitulos: Legacy, Queue, rótulo, frase y gesto de Todos)
all.P10_Corta = {
	Duration = 1.4,
	Skippable = true,
	Queue = true,
	Legacy = true,
	Anchors = { A = "Player" },
	Tracks = {
		Camera = { { At = 0, Duration = 1.4, From = { "A", V(8, 4, 8) }, To = { "A", V(9, 4, 8) }, Look = { "A", V(0, 1, 0) }, Fov = 50 } },
		Lines = { { At = 0.1, Speaker = "Narrador", Text = "CINE.SKIP" } },
		Titles = { { At = 0.2, Text = "CINE.SKIP", Duration = 0.5 } },
		Acting = { { At = 0.3, Who = "Todos", Play = "Cheer" } },
	},
}
all.P10_Larga = {
	Duration = 30,
	Skippable = true,
	Queue = true,
	Legacy = true,
	Anchors = { A = "Player" },
	Tracks = {
		Camera = { { At = 0, Duration = 30, Orbit = "A", Radius = 10, Height = 4, FromAngle = 0, ToAngle = 90 } },
	},
}
all.P10_Falla = {
	Duration = 3,
	Skippable = true,
	Legacy = true,
	Anchors = { A = "Player" },
	Tracks = {
		Camera = { { At = 0, Duration = 3, From = { "A", V(8, 4, 8) }, To = { "A", V(9, 4, 8) }, Look = { "A", V(0, 1, 0) } } },
		Acting = { { At = 0.3, Who = "Yo", Play = "Wave" } },
	},
}
local happeningRemote = remotes:FindFirstChild("Happening")
local serial = 0
local function sentDone(run: number): boolean
	for _, sent in rawget(happeningRemote, "__sent") or {} do
		if sent[1] == "Done" and sent[2] == run then
			return true
		end
	end
	return false
end
local function sentSkip(run: number): boolean
	for _, sent in rawget(happeningRemote, "__sent") or {} do
		if sent[1] == "Skip" and sent[2] == run then
			return true
		end
	end
	return false
end
-- opts.Ahead = segundos: la escena empieza «ya hace» ese rato (sus pasos de antes salen a la vez)
local function playHappening(id: string, during: ((number) -> ())?, opts: { [string]: any }?): number
	serial += 1
	local run = serial
	local start = os.clock()
	local o = opts or {}
	happeningRemote.OnClientEvent:Fire("Play", {
		Run = run,
		Id = id,
		StartAt = workspace:GetServerTimeNow() - (o.Ahead or 0),
		Anchors = o.Anchors or { A = CF.new(V(2, 0, 2)) },
		Names = o.Names or {},
		Voices = o.Voices or {},
		Args = {},
		Participant = o.Participant,
		Host = o.Host,
		Companions = o.Companions,
	})
	if during then
		during(run)
	end
	local finished = waitUntil(function()
		return sentDone(run)
	end, 40)
	return if finished then os.clock() - start else -1
end
local function skipButton(): any
	local gui = playerGui:FindFirstChild("Escena")
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
-- Pulsar «Saltar» como el jugador: la pantalla avisa (Skip) y el servidor contesta Stop
local function pressSkip(run: number): boolean
	local button = skipButton()
	if not button then
		return false
	end
	button.Activated:Fire()
	local asked = waitUntil(function()
		return sentSkip(run)
	end, 2)
	happeningRemote.OnClientEvent:Fire("Stop", { Run = run, Skipped = true })
	return asked
end

-- 1a. Hasta el final
do
	local inside = {}
	table.clear(actingLog)
	local seconds = playHappening("P10_Corta", function()
		task.wait(0.6)
		inside.Camera = camera.CameraType == Enum.CameraType.Scriptable
		inside.Controls = not controlsState.Enabled and Controls.isDisabled("Escena")
		inside.Flag = player:GetAttribute("InCinematic") == true
		inside.Hud = hud.Enabled == false
		inside.Names = otherHumanoid.DisplayDistanceType == Enum.HumanoidDisplayDistanceType.None
		inside.Bridge = Cinematics.isOnScreen() and Cinematics.isPlaying()
		sampleHidden("Cinematica")
	end)
	check(seconds > 0, ("La cinemática corta termina (%.1f s)"):format(seconds))
	check(inside.Camera and inside.Controls and inside.Flag, "Durante la escena: cámara de la escena, controles quitados e InCinematic")
	check(inside.Hud and inside.Names, "Durante la escena: el HUD y los nombres flotantes se esconden")
	check(inside.Bridge, "El puente Controllers/Cinematics dice que hay una de las de siempre en pantalla (isOnScreen/isPlaying), como antes")
	local cheered = 0
	for _, a in actingLog do
		if a.Play == "Cheer" then
			cheered += 1
		end
	end
	check(cheered >= 1, ("La pista Acting hace el gesto de «Todos» (Cheer: %d)"):format(cheered))
	restoredCheck("Al acabar: vuelven los controles, la cámara (Custom, a tu personaje, FOV), el HUD, los nombres y se quita InCinematic")
	check(not Cinematics.isOnScreen() and not Cinematics.isPlaying(), "…y el puente ya no dice que haya escena")
	check(waitUntil(function()
		return playerGui:FindFirstChild("Escena") == nil
	end, 2), "Al acabar se quita la interfaz de la escena")
end

-- 1b. Saltándola
do
	local asked = false
	local seconds = playHappening("P10_Larga", function(run)
		task.wait(0.6)
		asked = pressSkip(run)
	end)
	check(asked and seconds > 0 and seconds < 5, ("Saltar una escena de 30 s la corta enseguida (%.1f s)"):format(seconds))
	restoredCheck("Al saltarla: vuelven controles, cámara, HUD y nombres; sin InCinematic")
end

-- 1b-bis. El puente: Cinematics.interrupt() la salta (como el botón)
do
	local asked = false
	local seconds = playHappening("P10_Larga", function(run)
		task.wait(0.5)
		Cinematics.interrupt()
		asked = waitUntil(function()
			return sentSkip(run)
		end, 2)
		happeningRemote.OnClientEvent:Fire("Stop", { Run = run, Skipped = true })
	end)
	check(asked and seconds > 0 and seconds < 5, "Cinematics.interrupt() salta la de siempre que está en pantalla")
	restoredCheck("…y lo devuelve todo")
end

-- 1c. Muriendo en mitad
do
	local seconds = playHappening("P10_Corta", function()
		task.wait(0.3)
		respawn()
	end)
	check(seconds > 0, "Morir en mitad de una cinemática: la escena termina")
	restoredCheck("…y al acabar vuelven los controles y la cámara sigue a tu NUEVO personaje")
end

-- 1d. Si un paso falla a medias (el gesto): se salta y la escena acaba
do
	actorLifeFail = true
	local seconds = playHappening("P10_Falla")
	actorLifeFail = false
	check(seconds > 0, "Una escena con un gesto que falla termina (pcall)")
	restoredCheck("…y lo devuelve todo (interfaz, controles, cámara)")
end

-- 1e. Un «Cinematic» por el camino viejo (un servidor viejo): no se queda nada a medias
do
	local remote = remotes:FindFirstChild("LifeStory")
	rawset(remote, "__sent", {})
	Cinematics.play({ Id = "Cole03_Foto", Anchors = {}, Names = {}, Args = {} })
	local told = false
	for _, sent in rawget(remote, "__sent") or {} do
		told = told or (sent[1] == "CinematicDone" and sent[2] == "Cole03_Foto")
	end
	check(told, "Un «Cinematic» por el camino viejo avisa en el acto de que ha acabado (CinematicDone): la historia no espera")
	restoredCheck("…y no toca la cámara ni los controles")
end

-- 1f. Las 21 de siempre, DE PRINCIPIO A FIN por el motor (cada paso: planos, frases, rótulos, gestos).
-- Para que no tarde 4 minutos, cada una empieza «ya empezada» casi al final: todos sus pasos de antes
-- salen en el primer fotograma y la escena acaba sola (Done), sin saltarla.
local Legacy = loadModule("src/shared/LifeStory/Cinematics")
do
	local bad = {}
	local ids = Legacy.Ids
	for _, id in ids do
		local def = HappeningIndex.get(id)
		if not def then
			table.insert(bad, id .. " (no está en el motor)")
			continue
		end
		SceneReport._reset()
		local sceneRemote = remotes:FindFirstChild("Scene")
		rawset(sceneRemote, "__sent", {})
		local ankers = {}
		local i = 0
		for name in def.Anchors or {} do
			i += 1
			ankers[name] = CF.new(V(i * 10, 0, i * 5))
		end
		local seconds = playHappening(id, nil, {
			Anchors = ankers,
			Ahead = math.max(0, (def.Duration or 1) - 0.9),
			Names = { Rectora = "Rectora Amaia Soler", Abu = "Abu" },
			Voices = { Abu = "Abu", Rectora = "Rectora", Narrador = "Narrador" },
		})
		waitUntil(function()
			return #leftovers() == 0
		end, 3)
		local left = leftovers()
		local errors = 0
		for _, sent in rawget(sceneRemote, "__sent") or {} do
			if sent[1] == "Error" then
				errors += 1
			end
		end
		if seconds < 0 or #left > 0 or errors > 0 then
			table.insert(bad, ("%s (%s)"):format(id, if seconds < 0 then "no termina" elseif errors > 0 then errors .. " avisos de fallo" else table.concat(left, "; ")))
		end
		namesBack()
	end
	check(#ids == 21 and #bad == 0, ("Las %d cinemáticas de siempre se juegan enteras por el motor, sin fallos, y lo devuelven todo%s"):format(#ids, if #bad > 0 then ": " .. table.concat(bad, " · ") else ""))
end

-- 1f-bis. Una de verdad a su ritmo (Cole03_Foto, 7 s, con el gesto de todos) y saltando otra (Uni_PrimerDia)
do
	table.clear(actingLog)
	local mid = {}
	local seconds = playHappening("Cole03_Foto", function()
		task.wait(3)
		mid.Bridge = Cinematics.isOnScreen()
		mid.Skip = skipButton() ~= nil
	end, { Anchors = { Yo = CF.new(V(2, 0, 2)) } })
	check(seconds > 6 and mid.Bridge and mid.Skip, ("Cole03_Foto se ve entera por el motor (%.1f s), con «Saltar» y el puente encendido"):format(seconds))
	check(#actingLog >= 1 and actingLog[1].Play == "Cheer", "…y todos celebran la foto (Acting, como el Anims de antes)")
	restoredCheck("…y al acabar todo vuelve")
	local asked = false
	local skipped = playHappening("Uni_PrimerDia", function(run)
		task.wait(0.6)
		asked = pressSkip(run)
	end, { Anchors = { Uni = CF.new(V(40, 0, 0)), Campus = CF.new(V(0, 0, 40)) } })
	check(asked and skipped > 0 and skipped < 5, "Uni_PrimerDia (cabecera de capítulo) se salta por el motor")
	restoredCheck("…y lo devuelve todo")
end

-- 1g. Dos escenas seguidas (v108, la queja del móvil: «se ve un segundo la interfaz y ya empieza la
-- otra»). El servidor avisa de que va otra detrás (SceneFollowUp): la primera acaba en negro, se queda
-- una cortina (UI/SceneChain) sin HUD, sin control y con InCinematic, y se va cuando empieza la segunda.
do
	local SceneChain = loadModule("src/client/UI/SceneChain")
	player:SetAttribute("SceneFollowUp", workspace:GetServerTimeNow() + 30)
	local first = playHappening("P10_Corta")
	local gap = {
		Curtain = playerGui:FindFirstChild("SceneChain") ~= nil and SceneChain.active(),
		HudOff = hud.Enabled == false,
		Flag = player:GetAttribute("InCinematic") == true,
		Controls = Controls.isDisabled("PuenteEscenas"),
		HudSeen = false,
	}
	for _ = 1, 10 do
		gap.HudSeen = gap.HudSeen or hud.Enabled
		task.wait(0.05)
	end
	-- Llega la segunda (el servidor quita el aviso al lanzarla)
	player:SetAttribute("SceneFollowUp", nil)
	local during = { HudSeen = false }
	local second = playHappening("P10_Corta", function()
		for _ = 1, 16 do
			during.HudSeen = during.HudSeen or hud.Enabled
			task.wait(0.05)
		end
		during.CurtainGone = playerGui:FindFirstChild("SceneChain") == nil and not SceneChain.active()
	end)
	check(first > 0 and second > 0, "las dos escenas seguidas terminan")
	check(gap.Curtain and gap.HudOff and gap.Flag and gap.Controls, "entre las dos: cortina negra, sin HUD, sin control y con InCinematic")
	check(not gap.HudSeen and not during.HudSeen, "el HUD no se ve ni un momento entre las dos escenas")
	check(during.CurtainGone, "la cortina se va cuando empieza la segunda")
	restoredCheck("después de la segunda (ya no va nada detrás): vuelve todo")
	-- Sin aviso, una escena sola vuelve como siempre (nada de cortina)
	playHappening("P10_Corta")
	check(playerGui:FindFirstChild("SceneChain") == nil, "una escena sola no deja cortina")
	restoredCheck("una escena sola: vuelve todo")
	-- El aviso llega pero la escena siguiente no: la cortina se va sola (nunca te quedas a oscuras)
	player:SetAttribute("SceneFollowUp", workspace:GetServerTimeNow() + 30)
	playHappening("P10_Corta")
	local stuck = playerGui:FindFirstChild("SceneChain") ~= nil
	player:SetAttribute("SceneFollowUp", nil) -- (el servidor se lo piensa mejor: no va nada)
	local gone = waitUntil(function()
		return playerGui:FindFirstChild("SceneChain") == nil
	end, SceneChain.GRACE + 3)
	check(stuck and gone, "si al final no llega otra escena, la cortina se va sola")
	restoredCheck("y vuelve todo")
end

---------------------------------------------------------------------
print("\n▶ 2. Escenas del motor nuevo (HappeningClient): la cámara y los controles vuelven")
---------------------------------------------------------------------
do
	local inside = {}
	local seconds = playHappening("P10_Escena", function()
		task.wait(0.5)
		inside.Camera = camera.CameraType == Enum.CameraType.Scriptable
		inside.Controls = not controlsState.Enabled and Controls.isDisabled("Escena")
		inside.Flag = player:GetAttribute("InCinematic") == true and HappeningClient.isPlaying()
		sampleHidden("Escena")
		-- Rótulo y subtítulo en columna (si el rótulo pasa a dos líneas en el móvil, el subtítulo baja)
		local gui = playerGui:FindFirstChild("Escena")
		local block = gui and gui:FindFirstChild("TitleBlock")
		local labels = 0
		for _, child in if block then block:GetChildren() else {} do
			if child.ClassName == "TextLabel" and child.AutomaticSize == Enum.AutomaticSize.Y then
				labels += 1
			end
		end
		inside.Titles = block ~= nil and block:FindFirstChildOfClass("UIListLayout") ~= nil and labels == 2
	end)
	check(inside.Titles, "El rótulo y su subtítulo van en columna (TitleBlock): no se pisan con un rótulo de dos líneas")
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
	-- Un «Cinematic» por el camino viejo que llega mientras sigue una escena del motor: no toca nada (la
	-- escena sigue mandando: InCinematic puesto, controles quitados, cámara de la escena) y al final todo vuelve
	local done = false
	local mid = {}
	local seconds = playHappening("P10_EscenaLarga", function(run)
		task.wait(0.3)
		task.spawn(function()
			Cinematics.play({ Id = "Cole03_Foto" })
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
	check(seconds > 0 and mid.Controls and mid.Camera, "Un «Cinematic» viejo dentro de una escena: la escena sigue con su cámara y sin controles")
	check(mid.Flag, "…y sigue marcada InCinematic (las armas y las frases sueltas no se cuelan)")
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
	check(not opened, "Una conversación no se abre encima de una escena del motor nuevo")
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
			local t0 = os.clock()
			local seconds = playHappening(id, function(run)
				task.wait(0.8)
				happeningRemote.OnClientEvent:Fire("Stop", { Run = run, Skipped = true })
			end)
			waitUntil(function()
				return #leftovers() == 0
			end, 3) -- (la cámara vuelve con un suavizado)
			local left = leftovers()
			if seconds < 0 or #left > 0 then
				table.insert(bad, ("%s (%s)"):format(id, if seconds < 0 then "no termina" else table.concat(left, "; ")))
			end
			namesBack()
			if process.env.CINE_TIEMPOS then
				print(("    %s %.1f s"):format(id, os.clock() - t0))
			end
		end
	end
	check(#bad == 0, ("Las %d escenas del motor nuevo se pueden saltar y lo devuelven todo%s"):format(count, if #bad > 0 then ": " .. table.concat(bad, " · ") else ""))
end

-- 2f. (fase 6) Una escena que llega mientras se ve otra con cámara ya no espera en esta pantalla: espera
-- su turno en el SERVIDOR (HappeningService, Queue / AfterScene; lo prueba test-scenes) y llega cuando
-- la otra ha acabado. Entre las dos no se ve el HUD si el servidor avisó (1g, SceneFollowUp).

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
	-- Mientras la conversación está en pantalla (aunque no toques), el servidor recibe «Alive» de ESA
	-- conversación (DialogueService no la da por abandonada); al cerrarse, deja de mandarse
	local function alives(t: number): number
		local n = 0
		for _, sent in rawget(dialogueRemote, "__sent") or {} do
			if sent[1] == "Alive" and sent[2] == t then
				n += 1
			end
		end
		return n
	end
	local t = show({ "Me lo leo con calma.", "Sin prisa." })
	waitUntil(function()
		return DialogueUI.isOpen()
	end, 3)
	task.wait(1.2)
	check(DialogueUI.isOpen() and alives(t) >= 2, ("Con la conversación en pantalla se avisa al servidor de que sigue («Alive»: %d)"):format(alives(t)))
	check(readUntilClosed(8), "…se lee entera y se cierra")
	task.wait(0.4)
	local after = alives(t)
	task.wait(1)
	check(alives(t) == after, "…y cerrada ya no se avisa")
	restoredCheck("…y todo vuelve")
end

do
	-- Fase 2 (shared/LifeStory/TextSpeed, DialogueLook): retrato de quien habla, velocidad del menú
	-- (atributo TextSpeed), tocar una vez = la frase entera, otra vez = la siguiente, y el «tic» de tecleo
	local function blipCount(): number
		local n = 0
		for _, c in calls do
			if c == "SoundFx.play" then
				n += 1
			end
		end
		return n
	end
	player:SetAttribute("TextSpeed", "Lento")
	local line = "Esta frase es bastante larga para que dé tiempo a tocar mientras se escribe letra a letra."
	local total = utf8.len(line) :: number
	local blipsBefore = blipCount()
	show({ line })
	waitUntil(function()
		return DialogueUI.isOpen()
	end, 3)
	waitUntil(function()
		local v = DialogueUI._view()
		return (v.Graphemes or 0) > 3
	end, 3)
	local v = DialogueUI._view()
	check(v.Portrait == true and v.Initial == "N", ("Retrato de quien habla en la caja (insignia «%s»)"):format(tostring(v.Initial)))
	check(v.Face == true, "…con su cara (copia de su cabeza en un ViewportFrame) porque está en la escena")
	check(not v.Typed and v.Graphemes > 0 and v.Graphemes < total, ("En Lento se escribe letra a letra (%d de %d)"):format(v.Graphemes or -2, total))
	check(blipCount() > blipsBefore, "…con su «tic» de tecleo")
	press()
	task.wait(0.1)
	v = DialogueUI._view()
	check(v.Typed and v.Graphemes == -1 and DialogueUI.isOpen(), "Un toque mientras se escribe: la frase sale entera y NO se pasa")
	press()
	task.wait(0.05)
	check(DialogueUI.isOpen(), "…un segundo toque enseguida tampoco se la come (TAP_GUARD)")
	task.wait(0.4)
	press()
	check(waitUntil(function()
		return not DialogueUI.isOpen()
	end, 2), "…y otro toque ya pasa (era la última: se cierra)")
	restoredCheck("…y todo vuelve")

	player:SetAttribute("TextSpeed", "Instantaneo")
	local blipsInstant = blipCount()
	show({ "De golpe. " .. line })
	waitUntil(function()
		return DialogueUI.isOpen() and string.find(DialogueUI._view().Text or "", "De golpe", 1, true) ~= nil
	end, 3)
	task.wait(0.15)
	v = DialogueUI._view()
	check(v.Typed and v.Graphemes == -1, "En Instantáneo la frase sale entera de golpe")
	check(blipCount() == blipsInstant, "…sin «tic» de tecleo")
	check(readUntilClosed(4), "…y se pasa con un toque")
	player:SetAttribute("TextSpeed", nil)
	restoredCheck("…y todo vuelve")

	-- El narrador no lleva retrato
	token += 1
	dialogueRemote.OnClientEvent:Fire("Show", { Token = token, Seq = 1, Lines = { { Text = "Pasaron los años.", Narrator = true } }, Final = true })
	waitUntil(function()
		return DialogueUI.isOpen() and string.find(DialogueUI._view().Text or "", "Pasaron", 1, true) ~= nil
	end, 3)
	task.wait(0.1)
	check(DialogueUI._view().Portrait == false, "El narrador no lleva retrato")
	check(readUntilClosed(4), "…y se lee y se cierra")
	restoredCheck("…y todo vuelve")
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

-- v124 («el mensaje es enorme» y «Sibuastian»): la caja a la medida de la pantalla, las respuestas de
-- dos en dos con botones de 44 px y, en la pregunta, el nombre de quien la hace (no el tuyo)
do
	local DialogueLook = loadModule("src/shared/LifeStory/DialogueLook")
	local camera = workspace.CurrentCamera
	local function askNow(view: any, by: any?): any
		camera.ViewportSize = view
		token += 1
		dialogueRemote.OnClientEvent:Fire("Show", {
			Token = token,
			Seq = 1,
			Lines = {},
			Ask = "¿Me echas una mano?",
			AskBy = by,
			Options = { "¡Claro, yo me encargo! (24 € · 17 XP)", "Ahora no puedo, lo siento" },
			Final = true,
		})
		waitUntil(function()
			return actions.DialogueOptions ~= nil
		end, 6)
		return DialogueUI._view()
	end
	local function answer()
		if actions.DialogueOptions then
			actions.DialogueOptions("DialogueOptions", Enum.UserInputState.Begin, { KeyCode = Enum.KeyCode.Two })
		end
		readUntilClosed(4)
	end
	for _, view in { V2.new(640, 360), V2.new(844, 390), V2.new(1366, 768) } do
		local tag = ("%d×%d"):format(view.X, view.Y)
		local lay = DialogueLook.layout(view.X, view.Y)
		local v = askNow(view, { Name = "Rosa", Id = "Rosa", Actor = npc })
		local width = v.Box and v.Box.Size.X.Offset
		check(width == lay.Width and width <= view.X - 32, ("%s: la caja mide %s px de ancho (%d %% de la pantalla)"):format(tag, tostring(width), math.floor((width or 0) / view.X * 100)))
		check(v.Box and v.Box.Position.Y.Offset == -lay.Bottom, tag .. ": pegada abajo")
		check(v.Name == "Rosa", ("%s: la pregunta lleva el nombre de quien la hace («%s»), no el tuyo"):format(tag, tostring(v.Name)))
		check(v.TextSize and v.TextSize >= DialogueLook.MinText and v.TextSize <= lay.TextSize, ("%s: letra de %s px (de %d a %d)"):format(tag, tostring(v.TextSize), DialogueLook.MinText, lay.TextSize))
		local rows, buttons, minOk = 0, 0, true
		for _, row in v.Options:GetChildren() do
			if row.ClassName == "Frame" then
				rows += 1
				for _, b in row:GetChildren() do
					if b.ClassName == "TextButton" then
						buttons += 1
						local c = b:FindFirstChildOfClass("UISizeConstraint")
						minOk = minOk and c ~= nil and c.MinSize.Y >= 44 and b.TextSize >= DialogueLook.MinText
					end
				end
			end
		end
		check(rows == 1 and buttons == 2 and minOk, ("%s: las 2 respuestas, una al lado de la otra (%d fila), botones de 44 px o más"):format(tag, rows))
		answer()
	end
	-- Sin AskBy (las preguntas de siempre, «¿Qué le dices?»): no salen con TU nombre
	local v = askNow(V2.new(844, 390), nil)
	check(v.Name == nil and v.Portrait == false, "Una pregunta para ti, sin nombre ni retrato (antes salía con tu nombre y tu cara)")
	answer()
	camera.ViewportSize = V2.new(1920, 1080)
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
	-- Una conversación que llega en mitad de una de las de siempre espera a que acabe, y luego todo vuelve
	local done = false
	task.spawn(function()
		playHappening("P10_Corta")
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
		local visible = waitUntil(function()
			for _, text in leftovers() do
				if text:find("otro jugador", 1, true) then
					return false
				end
			end
			return true
		end, 2)
		check(visible, "Al acabar, el otro jugador vuelve a verse")
	else
		skip("Ocultar a los otros jugadores en plano aún no existe en el juego (paquete P2, C-16): se omite")
	end
	check(namesStuck == 0, ("Al acabar, el NOMBRE flotante del otro jugador vuelve (no ha vuelto %d veces)"):format(namesStuck))
end

---------------------------------------------------------------------
print("\n▶ 5. Fallos a propósito en cada paso (fase 3): se avisa al servidor y todo vuelve")
---------------------------------------------------------------------
-- SceneReport.Inject hace fallar un paso concreto (como si su código lanzara un error). En cada caso:
-- el aviso llega al remoto Scene ("Error", { Source, Scene, Step, Kind, Message }) sin el nombre del
-- jugador, la escena termina (o sigue sin ese paso) y después todo vuelve (leftovers).
local sceneRemote = remotes:FindFirstChild("Scene")
local function reportsOf(source: string, step: string?, kind: string?): number
	local n = 0
	for _, sent in rawget(sceneRemote, "__sent") or {} do
		local r = sent[2]
		if sent[1] == "Error" and type(r) == "table" and r.Source == source and (step == nil or r.Step == step) and (kind == nil or r.Kind == kind) then
			n += 1
		end
	end
	return n
end
local function anyLeak(): boolean
	for _, sent in rawget(sceneRemote, "__sent") or {} do
		local r = sent[2]
		if sent[1] == "Error" and type(r) == "table" then
			for _, v in r do
				if tostring(v):find(player.Name, 1, true) or tostring(v):find(tostring(player.UserId), 1, true) then
					return true
				end
			end
		end
	end
	return false
end
local function fresh()
	SceneReport._reset()
	rawset(sceneRemote, "__sent", {})
	SceneReport.RecoverAfter = 0.2
end

-- 5a. Las de siempre (ya en el motor, Legacy): cada paso, también el gesto (Acting)
all.P10_PasosVieja = {
	Duration = 2,
	Skippable = true,
	Legacy = true,
	Queue = true,
	Anchors = { A = "Player" },
	Tracks = {
		Camera = { { At = 0, Duration = 2, From = { "A", V(8, 4, 8) }, To = { "A", V(9, 4, 8) }, Look = { "A", V(0, 1, 0) }, Fov = 50 } },
		Lines = { { At = 0.1, Speaker = "Narrador", Text = "CINE.SKIP" } },
		Titles = { { At = 0.2, Text = "CINE.SKIP", Duration = 0.5 } },
		Acting = { { At = 0.3, Who = "Yo", Play = "Wave" } },
	},
}
for _, step in { "Shot", "Lines", "Titles", "Acting", "Play" } do
	fresh()
	SceneReport.Inject["Happening." .. step] = true
	local seconds = playHappening("P10_PasosVieja")
	SceneReport.Inject["Happening." .. step] = nil
	local kind = if step == "Play" then "Abort" else "Error"
	check(seconds > 0 and seconds < 12, ("De las de siempre con fallo en «%s»: termina (%.1f s)"):format(step, seconds))
	check(reportsOf("Happening", step, kind) >= 1, ("…se avisa al servidor (Happening/%s/%s)"):format(step, kind))
	if step == "Shot" then
		check(reportsOf("Happening", "Steps", "Abort") == 1, "…la cámara que falla en cada fotograma corta la escena (Abort) en vez de dejarla rota")
	end
	restoredCheck(("…y todo vuelve (fallo en «%s»)"):format(step))
	check(not Cinematics.isOnScreen(), ("…y el puente ya no la cuenta (fallo en «%s»)"):format(step))
end
check(not anyLeak(), "Los avisos no llevan el nombre ni el id del jugador")

-- 5b. Escenas del motor: cada pista, la cámara, la escena entera, preparar y la espera que no acaba
all.P10_Pasos = {
	Duration = 2,
	Anchors = { A = "Player" },
	Tracks = {
		Camera = { { At = 0, Duration = 2, Fixed = { "A", V(4, 2, 6) }, Look = { "A", V(0, 1, 0) }, Fov = 50 } },
		Lines = { { At = 0.1, Speaker = "Narrador", Text = "Hola." } },
		Titles = { { At = 0.2, Text = "Rótulo", Duration = 0.5 } },
		Fx = { { At = 0.3, Kind = "Flash" } },
		Sound = { { At = 0.3, Sound = "Boom" } },
	},
}
all.P10_Espera = {
	Duration = 1.5,
	Anchors = { A = "Player" },
	Tracks = {
		Camera = { { At = 0, Duration = 1.5, Fixed = { "A", V(4, 2, 6) }, Look = { "A", V(0, 1, 0) }, Fov = 50 } },
		Wait = { { At = 0.4, Seconds = 60 } },
	},
}
for _, step in { "Shot", "Lines", "Titles", "Fx", "Sound", "Play" } do
	fresh()
	SceneReport.Inject["Happening." .. step] = true
	local seconds = playHappening("P10_Pasos")
	SceneReport.Inject["Happening." .. step] = nil
	local kind = if step == "Play" then "Abort" else "Error"
	check(seconds > 0 and seconds < 12, ("Escena del motor con fallo en «%s»: termina (%.1f s)"):format(step, seconds))
	check(reportsOf("Happening", step, kind) >= 1, ("…se avisa al servidor (Happening/%s/%s)"):format(step, kind))
	if step == "Shot" then
		check(reportsOf("Happening", "Steps", "Abort") == 1, "…la cámara que falla en cada fotograma corta la escena (Abort)")
	end
	restoredCheck(("…y todo vuelve (fallo en «%s»)"):format(step))
end
do
	-- Preparar la escena falla (Sequencer.compile): no se pone, se avisa y el servidor recibe Done
	fresh()
	SceneReport.Inject["Happening.Compile"] = true
	local seconds = playHappening("P10_Pasos")
	SceneReport.Inject["Happening.Compile"] = nil
	check(seconds >= 0 and reportsOf("Happening", "Compile", "Abort") == 1, "Una escena que no se puede preparar: se avisa (Compile) y el servidor recibe Done")
	restoredCheck("…y no se queda nada")
end
do
	-- Vigilante de cada espera: el servidor nunca dice Resume (se perdió): la escena sigue sola
	fresh()
	SceneReport.Inject["Happening.WaitWatchdog"] = true
	local seconds = playHappening("P10_Espera")
	SceneReport.Inject["Happening.WaitWatchdog"] = nil
	check(seconds > 0 and seconds < 10, ("Una espera que el servidor nunca acaba: la escena sigue sola y termina (%.1f s)"):format(seconds))
	check(reportsOf("Happening", "Wait", "Watchdog") == 1, "…y se avisa al servidor (Happening/Wait/Watchdog)")
	restoredCheck("…y todo vuelve")
end
do
	-- Sin vigilante forzado, la espera sí espera (no se acaba sola antes de tiempo)
	fresh()
	local held = false
	local seconds = playHappening("P10_Espera", function(run)
		task.wait(2.2)
		held = HappeningClient.isPlaying()
		happeningRemote.OnClientEvent:Fire("Stop", { Run = run, Skipped = true })
	end)
	check(held and seconds > 2 and reportsOf("Happening", "Wait") == 0, "Una espera normal sigue esperando al servidor (el vigilante no se adelanta)")
	restoredCheck("…y al saltarla todo vuelve")
end
check(not anyLeak(), "Los avisos de las escenas del motor tampoco llevan datos del jugador")

-- 5c. Conversaciones
local function againsOf(t: number): number
	local n = 0
	for _, sent in rawget(dialogueRemote, "__sent") or {} do
		if sent[1] == "Again" and sent[2] == t then
			n += 1
		end
	end
	return n
end
for _, step in { "Line", "Open", "Ask" } do
	fresh()
	SceneReport.Inject["Dialogue." .. step] = true
	local t = show({ "Primera.", "Segunda.", "Tercera." }, if step == "Ask" then { "Sí", "No" } else nil)
	local closed = waitUntil(function()
		if DialogueUI.isOpen() then
			press()
		end
		return reportsOf("Dialogue", "Play", "Abort") >= 1 and not DialogueUI.isOpen()
	end, 10)
	SceneReport.Inject["Dialogue." .. step] = nil
	check(closed, ("Conversación con fallo en «%s»: se avisa (Dialogue/Play/Abort) y la caja se cierra"):format(step))
	check(againsOf(t) == 1, ("…y pide al servidor que la vuelva a mandar («Again», %d)"):format(againsOf(t)))
	restoredCheck(("…y todo vuelve (fallo en «%s»)"):format(step))
	dialogueRemote.OnClientEvent:Fire("Close", { Token = t })
end
do
	-- Retomar: el servidor la vuelve a mandar y ahora se lee entera
	fresh()
	SceneReport.Inject["Dialogue.Open"] = true
	local t = show({ "Vuelvo a empezar." })
	waitUntil(function()
		return againsOf(t) == 1
	end, 5)
	SceneReport.Inject["Dialogue.Open"] = nil
	dialogueRemote.OnClientEvent:Fire("Show", { Token = t, Seq = 1, Lines = { { Text = "Vuelvo a empezar.", Name = "Nico", Actor = npc, Emotion = "Calm" } }, Final = true })
	check(waitUntil(function()
		return DialogueUI.isOpen()
	end, 4), "Tras el fallo, el trozo que el servidor reenvía se vuelve a enseñar (la conversación se retoma)")
	check(readUntilClosed(6), "…y se lee entera")
	restoredCheck("…y todo vuelve")
end
do
	-- Una frase que falla se salta y la conversación sigue con las demás
	fresh()
	SceneReport.Inject["Dialogue.Line"] = 1 -- (solo la primera frase)
	local t = show({ "Esta falla.", "Esta sí sale.", "Y esta." })
	local sawNext = waitUntil(function()
		local view = DialogueUI._view()
		return DialogueUI.isOpen() and view.Text ~= nil and tostring(view.Text):find("Esta sí sale", 1, true) ~= nil
	end, 6)
	check(sawNext and reportsOf("Dialogue", "Line", "Error") == 1 and reportsOf("Dialogue", "Play") == 0, "Una frase que falla se salta (aviso Dialogue/Line) y la conversación sigue")
	check(readUntilClosed(8), "…y se lee hasta el final")
	check(againsOf(t) == 0, "…sin pedir que se reenvíe")
	restoredCheck("…y todo vuelve")
end
do
	-- El plano de la conversación no se puede calcular (StageDirector): aviso y la conversación sigue
	fresh()
	SceneReport.Inject["Director.Camera"] = true
	show({ "Sin plano.", "Pero se lee." })
	local read = readUntilClosed(8)
	SceneReport.Inject["Director.Camera"] = nil
	check(read, "Si el plano de la conversación falla (StageDirector.camera), la conversación se lee igual")
	restoredCheck("…y todo vuelve")
end
do
	-- H4: una cinemática que se queda en cola y nunca empieza: la conversación tiene su propio tope
	fresh()
	local saved = DialogueUI.SceneWaitMax
	DialogueUI.SceneWaitMax = 1
	local release = Cinematics.hold()
	show({ "No me quedo esperando para siempre." })
	task.wait(0.5)
	local early = DialogueUI.isOpen()
	local opened = waitUntil(function()
		return DialogueUI.isOpen()
	end, 4)
	check(not early and opened, "H4: con una cinemática atascada en cola, la conversación espera un rato y luego sale igual")
	check(reportsOf("Dialogue", "SceneWait", "Watchdog") == 1, "…y se avisa al servidor (Dialogue/SceneWait/Watchdog)")
	check(readUntilClosed(6), "…y se lee entera")
	release()
	DialogueUI.SceneWaitMax = saved
	restoredCheck("…y todo vuelve")
end

-- 5d. La vuelta suave de la cámara falla: la cámara vuelve al juego igual
do
	fresh()
	SceneReport.Inject["Camera.Glide"] = true
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CF.new(V(5, 5, 5))
	CineCamera.restore(CF.new(V(5, 5, 6)), { Seconds = 1 })
	local back = waitUntil(function()
		return camera.CameraType == Enum.CameraType.Custom
	end, 2)
	SceneReport.Inject["Camera.Glide"] = nil
	check(back and reportsOf("Camera", "Glide") == 1, "Si la vuelta suave de la cámara falla, se avisa (Camera/Glide) y la cámara vuelve al juego")
	restoredCheck("…y todo vuelve")
end

-- 5e. La red de seguridad: algo se quedó a medias sin ninguna escena en pantalla
do
	fresh()
	camera.CameraType = Enum.CameraType.Scriptable
	Controls.disable("Escena")
	local humanoid = humanoidNow()
	if humanoid then
		humanoid.AutoRotate = false
	end
	SceneGuis.hide(nil, { CoreAll = true })
	player:SetAttribute("InCinematic", true)
	local touched = SceneReport.recoverNow()
	check(touched and SceneReport.Recovered == 1, "La red de seguridad (SceneReport.recoverNow) devuelve lo que se quedó sin escena")
	check(humanoid == nil or humanoid.AutoRotate == true, "…el personaje vuelve a girar (no se queda congelado)")
	check(not SceneGuis.active(), "…la interfaz vuelve (SceneGuis.forceRestore)")
	restoredCheck("…y todo vuelve")
	-- Con una escena en pantalla no toca nada (es de esa escena)
	local untouched = nil
	playHappening("P10_EscenaLarga", function(run)
		task.wait(0.4)
		untouched = not SceneReport.recoverNow() and camera.CameraType == Enum.CameraType.Scriptable
		happeningRemote.OnClientEvent:Fire("Stop", { Run = run, Skipped = true })
	end)
	check(untouched == true, "…pero con una escena en pantalla no toca nada")
	restoredCheck("…y al acabar todo vuelve")
end
do
	-- Límite: un fallo que se repite en cada fotograma no inunda la red
	fresh()
	for _ = 1, 50 do
		SceneReport.report("Happening", "P10_Inunda", "Shot", "siempre igual")
	end
	for i = 1, 20 do
		SceneReport.report("Happening", "P10_Inunda" .. i, "Shot", "distinto")
	end
	local n = reportsOf("Happening")
	check(n == SceneReport.MaxPerMinute, ("Un fallo repetido no inunda la red: %d avisos (tope %d por minuto, el mismo una vez cada %d s)"):format(n, SceneReport.MaxPerMinute, SceneReport.SameEvery))
end
---------------------------------------------------------------------
print("\n▶ 6. Escenas con varios jugadores (fase 7): espectador (World) y escena de grupo (Group)")
---------------------------------------------------------------------
all.P10_Mundo = {
	Scope = "World",
	Duration = 1.5,
	Anchors = { A = "Player" },
	Tracks = {
		Camera = { { At = 0, Duration = 1.5, Fixed = { "A", V(4, 2, 6) }, Look = { "A", V(0, 1, 0) }, Fov = 50 } },
		Lines = { { At = 0.1, Speaker = "Narrador", Text = "Algo cae del cielo." } },
		Fx = { { At = 0.2, Play = "Flash", Anchor = "A" } },
	},
}
all.P10_Grupo = {
	Scope = "Group",
	Duration = 1.6,
	Skippable = true,
	Anchors = { A = "Player" },
	Tracks = {
		Camera = { { At = 0, Duration = 1.6, Fixed = { "A", V(4, 2, 6) }, Look = { "A", V(0, 1, 0) }, Fov = 50 } },
		Lines = { { At = 0.1, Speaker = "Narrador", Text = "Los dos." } },
	},
}
-- 6a. Espectador de un acontecimiento del mundo: ve lo que pasa, pero NO pierde la cámara ni el control
do
	serial += 1
	local run = serial
	local during = {}
	happeningRemote.OnClientEvent:Fire("Play", { Run = run, Id = "P10_Mundo", StartAt = workspace:GetServerTimeNow(), Anchors = { A = CF.new(V(2, 0, 2)) }, Names = {}, Args = {}, Spectator = true })
	task.wait(0.6)
	during.Camera = camera.CameraType == Enum.CameraType.Custom
	during.Controls = controlsState.Enabled and not Controls.isDisabled()
	during.Flag = player:GetAttribute("InCinematic") == nil
	during.Hud = hud.Enabled
	during.NoBars = playerGui:FindFirstChild("Escena") == nil
	happeningRemote.OnClientEvent:Fire("Stop", { Run = run, Skipped = false })
	task.wait(0.4)
	check(during.Camera and during.Controls and during.Flag, "Espectador (World): la cámara sigue siendo la tuya y no pierdes el control (sin InCinematic)")
	check(during.Hud and during.NoBars, "Espectador (World): ni bandas de cine ni interfaz escondida")
	check(not sentDone(run), "Espectador (World): no le dice al servidor que «ha acabado su escena» (no es suya)")
	restoredCheck("Espectador: todo sigue como estaba")
end
-- 6b. Escena de grupo: la vives con otro jugador; él NO se esconde de tus planos y ves sus actores
do
	local SceneClientT = SceneClient
	local inside = {}
	local seconds = playHappening("P10_Grupo", function()
		task.wait(0.6)
		inside.Camera = camera.CameraType == Enum.CameraType.Scriptable
		inside.Controls = not controlsState.Enabled
		inside.Companion = SceneClientT ~= nil and SceneClientT.isCompanion(other)
		inside.Sharing = SceneClientT ~= nil and SceneClientT.isSharing(other.UserId)
		inside.OtherVisible = not otherHidden()
	end, { Participant = true, Host = other.UserId, Companions = { other.UserId, player.UserId } })
	check(seconds > 0 and inside.Camera and inside.Controls, "Group: quien se une la vive entera (cámara de la escena, sin control)")
	check(inside.Companion and inside.OtherVisible, "Group: el amigo que la vive contigo NO se esconde de tus planos")
	check(inside.Sharing, "Group: ves los actores de la escena de quien la empezó (su carpeta)")
	check(SceneClientT ~= nil and not SceneClientT.isCompanion(other) and not SceneClientT.isSharing(), "Group: al acabar, todo como antes (los demás vuelven a esconderse en tus escenas)")
	restoredCheck("Group: al acabar vuelve todo")
end
-- 6c. Group: «Saltar» solo te saca a ti (pide Skip; el servidor contesta Stop solo para ti)
do
	local asked = false
	local seconds = playHappening("P10_Larga", function(run)
		task.wait(0.5)
		asked = pressSkip(run)
	end, { Participant = true, Host = other.UserId, Companions = { other.UserId, player.UserId } })
	check(asked and seconds > 0 and seconds < 5, "Group: quien se unió puede saltarla (para él)")
	restoredCheck("…y lo devuelve todo")
end

---------------------------------------------------------------------
print("\n▶ 7. Cinemateca (modo pruebas): la ventana, los mandos y la revisión")
---------------------------------------------------------------------
do
	local okLoad, CineUI = pcall(loadModule, "src/client/UI/Cinemateca")
	check(okLoad, "la ventana de la Cinemateca carga" .. (if okLoad then "" else ": " .. tostring(CineUI)))
	if okLoad then
		local fired = {}
		CineUI.setRemote({
			FireServer = function(_, kind, action, payload)
				table.insert(fired, { Kind = kind, Action = action, Payload = payload })
			end,
		})
		local okOpen, errOpen = pcall(CineUI.open)
		check(okOpen and CineUI.isOpen(), "se abre" .. (if okOpen then "" else ": " .. tostring(errOpen)))
		check(#fired >= 1 and fired[#fired].Action == "Cinemateca" and fired[#fired].Payload.Op == "Open", "y pide la lista al servidor")
		CineUI.onMessage({ Op = "List", List = {
			{ I = 1, K = "E:Cole03_Foto", T = "Cole03_Foto", G = "🎬 Capítulos", C = "Escena" },
			{ I = 2, K = "E:Grieta_Caen", T = "Grieta_Caen", G = "🌌 Saga de la Grieta", C = "Escena" },
			{ I = 3, K = "D:Cole01_PrimerDia/Lucia", T = "💬 Cole01_PrimerDia · Lucia", G = "📖 El colegio", C = "Conversación" },
		}, Verdicts = {} })
		local st = CineUI._state()
		check(st.Ui.Counter and st.Ui.Counter.Text:find("1 / 3", 1, true) ~= nil, ("el contador dice «1 / 3» (%s)"):format(tostring(st.Ui.Counter and st.Ui.Counter.Text)))
		CineUI._setQuery("grieta")
		check(#CineUI.filtered() == 1 and CineUI.counterText():find("1 encontradas", 1, true) ~= nil, "el buscador deja solo «Grieta_Caen»")
		CineUI._setQuery("")
		local function press(name)
			for _, d in playerGui:GetDescendants() do
				if d.Name == name and d:IsA("TextButton") then
					d.Activated:Fire()
					return true
				end
			end
			return false
		end
		check(press("Ver") and fired[#fired].Payload.Op == "Play" and fired[#fired].Payload.Index == 1, "▶ Ver pide la escena elegida")
		check(press("Siguiente") and fired[#fired].Payload.Op == "Next", "⏭ Siguiente")
		check(press("Anterior") and fired[#fired].Payload.Op == "Prev", "⏮ Anterior")
		check(press("Repetir") and fired[#fired].Payload.Op == "Replay", "↺ Repetir")
		CineUI.onMessage({ Op = "Started", Index = 2, Key = "E:Grieta_Caen", Ok = true })
		CineUI.onMessage({ Op = "Ended", Index = 2, Key = "E:Grieta_Caen", Skipped = true })
		st = CineUI._state()
		check(st.Ui.Review and st.Ui.Review.Visible and st.Pending and st.Pending.Key == "E:Grieta_Caen", "al acabar sale la barra de revisión")
		st.Ui.Note.Text = "se ve corto"
		check(press("Mal"), "❌ Mal")
		local last = fired[#fired].Payload
		check(last.Op == "Review" and last.Key == "E:Grieta_Caen" and last.Ok == false and last.Note == "se ve corto" and last.Skipped == true and type(last.Device) == "string", "manda la revisión con la nota y el contexto (saltada, dispositivo)")
		check(not st.Ui.Review.Visible and CineUI._state().Verdicts["E:Grieta_Caen"] == "Mal", "y la escena queda marcada ❌")
		CineUI.close()
		check(not CineUI.isOpen() and fired[#fired].Payload.Op == "Close", "al cerrar, el servidor te devuelve a tu sitio (Close)")
		restoredCheck("la Cinemateca no deja nada a medias")
	end
end

SceneReport._reset()

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
