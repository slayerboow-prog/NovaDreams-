-- Prueba: el cliente ARRANCA sin errores FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-clientboot.luau
--
-- test-compile.luau ya detecta los errores de escritura. Esta prueba va un paso más allá: carga
-- src/client/Main.client.luau (que carga e inicia todos los módulos del cliente) en un Roblox de
-- mentira muy permisivo y deja correr el juego un rato (tiempo simulado, con fotogramas y esperas).
-- Cualquier error al cargar un módulo, al iniciarlo o en lo que arranca (un require que falla, un
-- índice nil al cargar, una propiedad que no existe…) sale en la lista y la prueba falla: son los
-- errores que en el juego dejan al jugador sin interfaz ("el cliente se para y no sale nada").
-- Después carga también cada módulo de src/client y src/shared que Main no haya cargado.
--
-- Se hace dos veces: como en el ordenador (1920x1080, teclado) y como en el móvil (844x390, táctil).
--
-- El Roblox de mentira: las instancias tienen Parent/Name/hijos/atributos/etiquetas, FindFirstChild,
-- WaitForChild (con tiempo de espera; sin él, si no aparece en 5 s, se crea un sustituto y se apunta),
-- señales que se pueden conectar y esperar, y propiedades con su valor por defecto según la API de
-- Roblox. Lo que no se conoce devuelve un objeto comodín al que se puede llamar e indexar.
-- Los errores que salen solo porque el doble no imita algo se arreglan aquí, en la prueba.

local fs = require("@lune/fs")
-- ¿Pase de temporada encendido para todos? (BattlePassConfig.Enabled)
local BP_ON = string.find(fs.readFile("src/shared/BattlePass/Config.luau"), "BattlePassConfig.Enabled = true", 1, true) ~= nil
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local db = roblox.getReflectionDatabase()
local realClock = os.clock

local V3, V2, C3 = roblox.Vector3, roblox.Vector2, roblox.Color3
local Enum = roblox.Enum

-- CFrame.lookAt de Lune da la vuelta al mirar hacia -Z: aquí, el de Roblox
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

local serverLog: { any } = {} -- lo que el cliente manda al servidor (FireServer)
local SIM_SECONDS = 110 -- tiempo de juego simulado en cada modo (el móvil conduce cada vehículo al final)
local FPS = 20
local REAL_BUDGET = 120 -- segundos reales como mucho en cada modo
local ROOT = "src"

---------------------------------------------------------------------
-- La API de Roblox (tipos de las propiedades)
---------------------------------------------------------------------
local classCache: { [string]: any } = {}
local function classOf(name: string): any
	local c = classCache[name]
	if c == nil then
		c = db:GetClass(name) or false
		classCache[name] = c
	end
	return c or nil
end

local function isA(className: string, other: string): boolean
	if className == other or other == "Instance" then
		return true
	end
	local class = classOf(className)
	while class do
		if class.Name == other then
			return true
		end
		class = class.Superclass and classOf(class.Superclass)
	end
	return false
end

local propTypeCache: { [string]: any } = {}
local function propType(className: string, name: string): string?
	local cacheKey = className .. "." .. name
	local cached = propTypeCache[cacheKey]
	if cached ~= nil then
		return cached or nil
	end
	local found: string? = nil
	local class = classOf(className)
	while class do
		local p = class.Properties[name]
		if p then
			found = tostring(p.Datatype)
			break
		end
		class = class.Superclass and classOf(class.Superclass)
	end
	propTypeCache[cacheKey] = found or false
	return found
end

---------------------------------------------------------------------
-- Una arrancada completa (un modo: ordenador o móvil)
---------------------------------------------------------------------
local function boot(mode: { Name: string, Viewport: any, Touch: boolean })
	local now = 0
	local errors: { { Where: string, Message: string, Trace: string } } = {}
	local errorSeen: { [string]: boolean } = {}
	local warnings: { [string]: number } = {}
	local placeholders: { string } = {}
	local oddWrites: { [string]: boolean } = {}
	local loaded: { [string]: boolean } = {}

	local function report(where: string, err: any, thread: thread?)
		local text = tostring(err)
		local message, rest = string.match(text, "^([^\n]*)\n(.*)$")
		message = message or text
		if errorSeen[message] then
			return
		end
		errorSeen[message] = true
		local trace = rest or (if thread then debug.traceback(thread) else debug.traceback())
		table.insert(errors, { Where = where, Message = message, Trace = trace })
	end

	-----------------------------------------------------------------
	-- Hilos: task.* con reloj simulado
	-----------------------------------------------------------------
	local sleeping: { { Thread: thread, At: number, Args: any, Where: string } } = {}
	local deferred: { { Thread: thread, Args: any, Where: string } } = {}
	local cancelled: { [thread]: boolean } = {}

	local function whereOf(fn: any): string
		if type(fn) ~= "function" then
			return "hilo"
		end
		local source, line = debug.info(fn, "sl")
		return ("%s:%s"):format(tostring(source):gsub("^.*/src/", ""), tostring(line))
	end

	local function resume(thread: thread, where: string, ...)
		if cancelled[thread] or coroutine.status(thread) ~= "suspended" then
			return
		end
		local ok, err = coroutine.resume(thread, ...)
		if not ok then
			report(where, err, thread)
		end
	end

	local function threadOf(fn: any): thread
		if type(fn) == "thread" then
			return fn
		end
		assert(type(fn) == "function", "task: se esperaba una función, llegó " .. typeof(fn))
		return coroutine.create(fn)
	end

	local fakeTask = {}
	function fakeTask.spawn(fn: any, ...)
		local thread = threadOf(fn)
		resume(thread, whereOf(fn), ...)
		return thread
	end
	function fakeTask.defer(fn: any, ...)
		local thread = threadOf(fn)
		table.insert(deferred, { Thread = thread, Args = table.pack(...), Where = whereOf(fn) })
		return thread
	end
	function fakeTask.delay(seconds: number?, fn: any, ...)
		local thread = threadOf(fn)
		table.insert(sleeping, { Thread = thread, At = now + (tonumber(seconds) or 0), Args = table.pack(...), Where = whereOf(fn) })
		return thread
	end
	function fakeTask.wait(seconds: number?)
		local thread = coroutine.running()
		local start = now
		table.insert(sleeping, { Thread = thread, At = now + math.max(tonumber(seconds) or 0, 1 / FPS), Args = nil, Where = "task.wait", Start = start } :: any)
		coroutine.yield()
		return now - start, now
	end
	function fakeTask.cancel(thread: thread)
		cancelled[thread] = true
		pcall(coroutine.close, thread)
	end
	function fakeTask.synchronize() end
	function fakeTask.desynchronize() end

	-----------------------------------------------------------------
	-- Comodín: todo lo que no se conoce
	-----------------------------------------------------------------
	local mockMeta = {}
	local function U(label: string): any
		return setmetatable({ __mock = label }, mockMeta)
	end
	local function connection(): any
		local c = { __conn = true, Connected = true }
		function c.Disconnect(self)
			c.Connected = false
		end
		return c
	end
	mockMeta.__index = function(self, key)
		if key == "Connect" or key == "Once" or key == "ConnectParallel" then
			return function()
				return connection()
			end
		elseif key == "Wait" then
			return function()
				coroutine.yield() -- nunca llega
			end
		elseif key == "Disconnect" or key == "Destroy" then
			return function() end
		end
		local child = U(rawget(self, "__mock") .. "." .. tostring(key))
		rawset(self, key, child)
		return child
	end
	mockMeta.__call = function(self)
		return U(rawget(self, "__mock") .. "()")
	end
	for _, op in { "__add", "__sub", "__mul", "__div", "__mod", "__pow", "__idiv" } do
		mockMeta[op] = function()
			return U("op")
		end
	end
	mockMeta.__unm = function()
		return U("op")
	end
	mockMeta.__len = function()
		return 0
	end
	mockMeta.__lt = function()
		return false
	end
	mockMeta.__le = function()
		return false
	end
	mockMeta.__concat = function(a, b)
		return tostring(a) .. tostring(b)
	end
	mockMeta.__tostring = function(self)
		return "<" .. rawget(self, "__mock") .. ">"
	end
	mockMeta.__iter = function()
		return next, {}
	end

	-----------------------------------------------------------------
	-- Señales
	-----------------------------------------------------------------
	local signalMeta = {}
	signalMeta.__call = function(self)
		return U("llamada a " .. rawget(self, "__name"))
	end
	local function Signal(name: string): any
		local s = setmetatable({ __signal = true, __name = name, Handlers = {}, Waiting = {} }, signalMeta)
		function s.Connect(self2, fn)
			local c = connection()
			table.insert(s.Handlers, { Fn = fn, Conn = c })
			return c
		end
		s.ConnectParallel = s.Connect
		function s.Once(self2, fn)
			local c
			c = s:Connect(function(...)
				c:Disconnect()
				fn(...)
			end)
			return c
		end
		function s.Wait()
			table.insert(s.Waiting, coroutine.running())
			return coroutine.yield()
		end
		function s.Fire(self2, ...)
			for _, h in table.clone(s.Handlers) do
				if h.Conn.Connected then
					fakeTask.spawn(h.Fn, ...)
				end
			end
			local waiting = s.Waiting
			s.Waiting = {}
			for _, thread in waiting do
				resume(thread, "Wait de " .. name, ...)
			end
		end
		return s
	end

	-----------------------------------------------------------------
	-- Instancias
	-----------------------------------------------------------------
	local instanceMeta = {}
	local tagged: { [string]: { [any]: boolean } } = {}
	local tagSignals: { [string]: { Added: any, Removed: any } } = {}

	local function tagSignal(tag: string)
		tagSignals[tag] = tagSignals[tag] or { Added = Signal("TagAdded " .. tag), Removed = Signal("TagRemoved " .. tag) }
		return tagSignals[tag]
	end

	local SPECIAL: { [string]: any } = {
		Visible = true, Enabled = true, Archivable = true, CanCollide = true, CanQuery = true, CanTouch = true,
		AutoJumpEnabled = true, Health = 100, MaxHealth = 100, WalkSpeed = 16, JumpPower = 50, JumpHeight = 7.2,
		HipHeight = 2, Volume = 0.5, TextSize = 14, PlaybackSpeed = 1, FieldOfView = 70, Scale = 1,
		MaxVisibleGraphemes = -1, Brightness = 1, Gravity = 196.2, ClockTime = 14, Speed = 1, Length = 1,
		MaxDistance = 100, RollOffMaxDistance = 100, LineHeight = 1, Density = 0.3, Range = 8, ZIndex = 1,
		WeightCurrent = 1, WeightTarget = 1, Thickness = 1, TimeLength = 1, MaxSlopeAngle = 89,
	}
	local function defaultFor(className: string, key: string, dt: string): any
		local special = SPECIAL[key]
		if dt == "Bool" then
			return if type(special) == "boolean" then special else false
		elseif dt == "Float32" or dt == "Float64" or dt == "Int32" or dt == "Int64" then
			return if type(special) == "number" then special else 0
		elseif dt == "String" or dt == "Content" or dt == "ContentId" or dt == "BinaryString" then
			return if key == "Name" then className else ""
		elseif dt == "Vector3" then
			if key == "Size" then
				return V3.new(4, 1.2, 2)
			end
			return V3.zero
		elseif dt == "Vector2" then
			if key == "ViewportSize" or key == "AbsoluteWindowSize" then
				return mode.Viewport
			elseif key == "AbsoluteSize" then
				return V2.new(200, 50)
			elseif key == "TextBounds" then
				return V2.new(80, 18)
			end
			return V2.zero
		elseif dt == "CFrame" or dt == "OptionalCFrame" then
			return CF.new()
		elseif dt == "Color3" or dt == "Color3uint8" then
			return C3.new(0.6, 0.6, 0.6)
		elseif dt == "UDim2" then
			return roblox.UDim2.new()
		elseif dt == "UDim" then
			return roblox.UDim.new()
		elseif dt == "Font" then
			return roblox.Font.fromEnum(Enum.Font.SourceSans)
		elseif dt == "Rect" then
			return roblox.Rect.new(0, 0, 0, 0)
		elseif dt == "NumberRange" then
			return roblox.NumberRange.new(0, 0)
		elseif dt == "NumberSequence" then
			return roblox.NumberSequence.new(0)
		elseif dt == "ColorSequence" then
			return roblox.ColorSequence.new(C3.new(1, 1, 1))
		elseif dt == "BrickColor" then
			return roblox.BrickColor.new("Medium stone grey")
		elseif string.sub(dt, 1, 5) == "Enum." then
			local enumName = string.sub(dt, 6)
			local preferred = ({ CameraType = "Custom", HumanoidRigType = "R15", Material = "Plastic", Font = "SourceSans", HumanoidStateType = "Running" })[enumName]
			local ok, item = pcall(function()
				local e = (Enum :: any)[enumName]
				return if preferred then e[preferred] else e:GetEnumItems()[1]
			end)
			return if ok then item else nil
		end
		return nil
	end

	local function new(className: string, name: string?): any
		local o = setmetatable({
			__class = className,
			__props = { Name = name or className },
			__children = {},
			__attrs = {},
			__signals = {},
			__attrSignals = {},
			__propSignals = {},
			__tags = {},
		}, instanceMeta)
		return o
	end

	local function signalOf(o: any, key: string): any
		local signals = rawget(o, "__signals")
		signals[key] = signals[key] or Signal(tostring(rawget(o, "__props").Name) .. "." .. key)
		return signals[key]
	end
	local function fireIf(o: any, key: string, ...)
		local s = rawget(o, "__signals")[key]
		if s then
			s:Fire(...)
		end
	end

	local methods: { [string]: any } = {}
	function methods:GetChildren()
		return table.clone(rawget(self, "__children"))
	end
	function methods:GetDescendants()
		local out = {}
		local function walk(object)
			for _, child in rawget(object, "__children") do
				table.insert(out, child)
				walk(child)
			end
		end
		walk(self)
		return out
	end
	function methods:FindFirstChild(name, recursive)
		for _, child in rawget(self, "__children") do
			if rawget(child, "__props").Name == name then
				return child
			end
		end
		if recursive then
			for _, child in rawget(self, "__children") do
				local found = child:FindFirstChild(name, true)
				if found then
					return found
				end
			end
		end
		return nil
	end
	function methods:FindFirstChildOfClass(className)
		for _, child in rawget(self, "__children") do
			if rawget(child, "__class") == className then
				return child
			end
		end
		return nil
	end
	function methods:FindFirstChildWhichIsA(className, recursive)
		for _, child in rawget(self, "__children") do
			if isA(rawget(child, "__class"), className) then
				return child
			end
		end
		if recursive then
			for _, child in rawget(self, "__children") do
				local found = child:FindFirstChildWhichIsA(className, true)
				if found then
					return found
				end
			end
		end
		return nil
	end
	function methods:FindFirstDescendant(name)
		return self:FindFirstChild(name, true)
	end
	function methods:FindFirstAncestor(name)
		local p = self.Parent
		while p do
			if p.Name == name then
				return p
			end
			p = p.Parent
		end
		return nil
	end
	function methods:FindFirstAncestorOfClass(className)
		local p = self.Parent
		while p do
			if rawget(p, "__class") == className then
				return p
			end
			p = p.Parent
		end
		return nil
	end
	function methods:FindFirstAncestorWhichIsA(className)
		local p = self.Parent
		while p do
			if rawget(p, "__class") and isA(rawget(p, "__class"), className) then
				return p
			end
			p = p.Parent
		end
		return nil
	end
	local function guessClass(name: string, parent: any): string
		if parent and rawget(parent, "__props").Name == "Remotes" then
			return "RemoteEvent"
		end
		return ({
			Humanoid = "Humanoid", HumanoidRootPart = "Part", Head = "Part", UpperTorso = "Part", Torso = "Part",
			Animator = "Animator", PlayerModule = "ModuleScript", PlayerGui = "PlayerGui", PlayerScripts = "PlayerScripts",
		})[name] or "Folder"
	end
	function methods:WaitForChild(name, timeout)
		local found = self:FindFirstChild(name)
		if found then
			return found
		end
		local limit = if timeout then tonumber(timeout) or 0 else 5
		local waited = 0
		while waited < limit do
			waited += fakeTask.wait(0.1)
			found = self:FindFirstChild(name)
			if found then
				return found
			end
		end
		if timeout then
			return nil
		end
		-- En Roblox se quedaría esperando para siempre: aquí aparece un sustituto (y se apunta)
		table.insert(placeholders, ("%s:WaitForChild(%q)"):format(self:GetFullName(), tostring(name)))
		local child = new(guessClass(name, self), name)
		child.Parent = self
		return child
	end
	function methods:IsA(className)
		return isA(rawget(self, "__class"), className)
	end
	function methods:IsDescendantOf(other)
		local p = self.Parent
		while p do
			if p == other then
				return true
			end
			p = p.Parent
		end
		return false
	end
	function methods:IsAncestorOf(other)
		return other ~= nil and other:IsDescendantOf(self)
	end
	function methods:Destroy()
		if rawget(self, "__destroyed") then
			return
		end
		fireIf(self, "Destroying")
		for _, child in table.clone(rawget(self, "__children")) do
			child:Destroy()
		end
		self.Parent = nil
		rawset(self, "__destroyed", true)
	end
	function methods:ClearAllChildren()
		for _, child in table.clone(rawget(self, "__children")) do
			child:Destroy()
		end
	end
	function methods:Clone()
		local copy = new(rawget(self, "__class"))
		for k, v in rawget(self, "__props") do
			if k ~= "Parent" then
				rawget(copy, "__props")[k] = v
			end
		end
		for k, v in rawget(self, "__attrs") do
			rawget(copy, "__attrs")[k] = v
		end
		for tag in rawget(self, "__tags") do
			copy:AddTag(tag)
		end
		for _, child in rawget(self, "__children") do
			child:Clone().Parent = copy
		end
		return copy
	end
	function methods:GetAttribute(name)
		return rawget(self, "__attrs")[name]
	end
	function methods:GetAttributes()
		return table.clone(rawget(self, "__attrs"))
	end
	function methods:SetAttribute(name, value)
		local attrs = rawget(self, "__attrs")
		if attrs[name] == value then
			return
		end
		attrs[name] = value
		local s = rawget(self, "__attrSignals")[name]
		if s then
			s:Fire()
		end
		fireIf(self, "AttributeChanged", name)
	end
	function methods:GetAttributeChangedSignal(name)
		local signals = rawget(self, "__attrSignals")
		signals[name] = signals[name] or Signal("Atributo " .. tostring(name))
		return signals[name]
	end
	function methods:GetPropertyChangedSignal(name)
		local signals = rawget(self, "__propSignals")
		signals[name] = signals[name] or Signal("Propiedad " .. tostring(name))
		return signals[name]
	end
	function methods:HasTag(tag)
		return rawget(self, "__tags")[tag] == true
	end
	function methods:AddTag(tag)
		if not rawget(self, "__tags")[tag] then
			rawget(self, "__tags")[tag] = true
			tagged[tag] = tagged[tag] or {}
			tagged[tag][self] = true
			tagSignal(tag).Added:Fire(self)
		end
	end
	function methods:RemoveTag(tag)
		if rawget(self, "__tags")[tag] then
			rawget(self, "__tags")[tag] = nil
			if tagged[tag] then
				tagged[tag][self] = nil
			end
			tagSignal(tag).Removed:Fire(self)
		end
	end
	function methods:GetTags()
		local out = {}
		for tag in rawget(self, "__tags") do
			table.insert(out, tag)
		end
		return out
	end
	function methods:GetFullName()
		local names = {}
		local o = self
		while o and rawget(o, "__class") ~= "DataModel" do
			table.insert(names, 1, tostring(rawget(o, "__props").Name))
			o = rawget(o, "__props").Parent
		end
		return table.concat(names, ".")
	end
	function methods:GetDebugId()
		return tostring(self)
	end
	local function partCFrame(o: any): any
		local props = rawget(o, "__props")
		return props.CFrame or CF.new()
	end
	function methods:GetPivot()
		if isA(rawget(self, "__class"), "BasePart") then
			return partCFrame(self)
		end
		local primary = rawget(self, "__props").PrimaryPart
		if primary then
			return partCFrame(primary)
		end
		local part = self:FindFirstChildWhichIsA("BasePart", true)
		return if part then partCFrame(part) else CF.new()
	end
	function methods:PivotTo(cf)
		if isA(rawget(self, "__class"), "BasePart") then
			self.CFrame = cf
			return
		end
		local pivot = self:GetPivot()
		for _, d in self:GetDescendants() do
			if isA(rawget(d, "__class"), "BasePart") then
				d.CFrame = cf * pivot:ToObjectSpace(partCFrame(d))
			end
		end
	end
	function methods:GetBoundingBox()
		return self:GetPivot(), V3.new(4, 5, 2)
	end
	function methods:GetExtentsSize()
		return V3.new(4, 5, 2)
	end
	function methods:GetMass()
		return 10
	end
	function methods:GetConnectedParts()
		return { self }
	end
	function methods:GetTouchingParts()
		return {}
	end
	function methods:GetScale()
		return 1
	end
	function methods:ScaleTo() end
	function methods:SetNetworkOwner() end
	function methods:ApplyImpulse() end
	function methods:FireServer(...)
		table.insert(serverLog, { Remote = rawget(self, "__props") and rawget(self, "__props").Name or tostring(self), Args = table.pack(...) })
	end
	function methods:InvokeServer()
		return nil
	end
	function methods:Play()
		fireIf(self, "Played")
	end
	function methods:Stop()
		fireIf(self, "Stopped")
	end
	function methods:Pause() end
	function methods:Resume() end

	instanceMeta.__index = function(self, key)
		local m = methods[key]
		if m then
			return m
		end
		local props = rawget(self, "__props")
		local v = props[key]
		if v ~= nil then
			return v
		end
		local className = rawget(self, "__class")
		if key == "ClassName" then
			return className
		elseif key == "Parent" then
			return nil
		elseif key == "Position" and isA(className, "BasePart") then
			return partCFrame(self).Position
		elseif key == "Orientation" and isA(className, "BasePart") then
			local rx, ry, rz = partCFrame(self):ToOrientation()
			return V3.new(math.deg(rx), math.deg(ry), math.deg(rz))
		elseif key == "AssemblyLinearVelocity" or key == "AssemblyAngularVelocity" then
			return V3.zero
		end
		local dt = if type(key) == "string" then propType(className, key) else nil
		if dt == nil and type(key) == "string" then
			-- Un hijo por su nombre (gui.Status)
			for _, child in rawget(self, "__children") do
				if rawget(child, "__props").Name == key then
					return child
				end
			end
		end
		if dt then
			local value = defaultFor(className, key, dt)
			if value ~= nil then
				props[key] = value
			end
			return value
		end
		-- Evento o método que no conoce el doble: se puede conectar y llamar
		return signalOf(self, tostring(key))
	end
	instanceMeta.__newindex = function(self, key, value)
		local props = rawget(self, "__props")
		local className = rawget(self, "__class")
		if key == "Parent" then
			if rawget(self, "__destroyed") and value ~= nil then
				error(("The Parent property of %s is locked, current parent: NULL, new parent %s"):format(tostring(props.Name), tostring(value)), 2)
			end
			if value ~= nil and (type(value) ~= "table" or rawget(value, "__children") == nil) then
				error(("Parent: se esperaba una instancia, llegó %s"):format(typeof(value)), 2)
			end
			local old = props.Parent
			if old == value then
				return
			end
			if old then
				local list = rawget(old, "__children")
				local i = table.find(list, self)
				if i then
					table.remove(list, i)
				end
				fireIf(old, "ChildRemoved", self)
			end
			props.Parent = value
			if value then
				table.insert(rawget(value, "__children"), self)
				fireIf(value, "ChildAdded", self)
				local p = value
				while p do
					fireIf(p, "DescendantAdded", self)
					p = rawget(p, "__props").Parent
				end
			end
			fireIf(self, "AncestryChanged", self, value)
		elseif key == "Position" and isA(className, "BasePart") and typeof(value) == "Vector3" then
			props.CFrame = partCFrame(self).Rotation + value
		else
			if type(key) == "string" and key ~= "Name" and propType(className, key) == nil and classOf(className) then
				oddWrites[className .. "." .. key] = true
			end
			props[key] = value
		end
		local s = rawget(self, "__propSignals")[key]
		if s then
			s:Fire()
		end
		fireIf(self, "Changed", key)
	end
	instanceMeta.__tostring = function(self)
		return tostring(rawget(self, "__props").Name)
	end

	local InstanceLib = {}
	function InstanceLib.new(className: string, parent: any?)
		if type(className) ~= "string" or not classOf(className) then
			error(("Unable to create an Instance of type %q"):format(tostring(className)), 2)
		end
		local o = new(className)
		if parent then
			o.Parent = parent
		end
		return o
	end
	function InstanceLib.fromExisting(other: any)
		return other:Clone()
	end

	-- Pistas de animación
	local function track(): any
		local t = new("AnimationTrack")
		local props = rawget(t, "__props")
		props.Length, props.Speed, props.IsPlaying, props.TimePosition, props.Looped = 1, 1, false, 0, false
		rawset(t, "Play", function(self)
			props.IsPlaying = true
		end)
		rawset(t, "Stop", function(self)
			props.IsPlaying = false
			fireIf(self, "Stopped")
		end)
		for _, name in { "AdjustSpeed", "AdjustWeight" } do
			rawset(t, name, function() end)
		end
		rawset(t, "GetMarkerReachedSignal", function(self, name)
			return signalOf(self, "Marker " .. tostring(name))
		end)
		rawset(t, "GetTimeOfKeyframe", function()
			return 0
		end)
		return t
	end
	methods.LoadAnimation = function()
		return track()
	end
	methods.GetPlayingAnimationTracks = function()
		return {}
	end

	-----------------------------------------------------------------
	-- El juego: servicios
	-----------------------------------------------------------------
	local game = new("DataModel", "Game")
	local services: { [string]: any } = {}
	local function service(name: string): any
		local s = services[name]
		if not s then
			s = new(if classOf(name) then name else "Folder", name)
			rawget(s, "__props").Parent = nil
			table.insert(rawget(game, "__children"), s)
			rawget(s, "__props").Parent = game
			services[name] = s
		end
		return s
	end
	rawset(game, "GetService", function(_, name)
		return service(name)
	end)
	rawset(game, "FindService", function(_, name)
		return services[name]
	end)
	rawset(game, "IsLoaded", function()
		return true
	end)
	rawset(game, "BindToClose", function() end)
	rawget(game, "__props").PlaceId = 0
	rawget(game, "__props").GameId = 0
	rawget(game, "__props").JobId = "prueba"
	rawget(game, "__props").CreatorId = 0
	rawget(game, "__props").PlaceVersion = 1

	local function fn(object: any, name: string, f: any)
		rawset(object, name, f)
	end

	-- Workspace y cámara
	local workspace = service("Workspace")
	rawget(game, "__props").Workspace = workspace
	local camera = new("Camera", "Camera")
	camera.CFrame = CF.lookAt(V3.new(0, 12, 24), V3.new(0, 3, 0))
	camera.Parent = workspace
	rawget(workspace, "__props").CurrentCamera = camera
	local function project(point: any): (any, boolean)
		local cf = camera.CFrame
		local rel = cf:PointToObjectSpace(point)
		local vp = mode.Viewport
		local depth = -rel.Z
		if depth <= 0.01 then
			return V3.new(vp.X / 2, vp.Y / 2, depth), false
		end
		local f = (vp.Y / 2) / math.tan(math.rad(camera.FieldOfView) / 2)
		local x = vp.X / 2 + rel.X / depth * f
		local y = vp.Y / 2 - rel.Y / depth * f
		return V3.new(x, y, depth), x >= 0 and x <= vp.X and y >= 0 and y <= vp.Y
	end
	fn(camera, "WorldToViewportPoint", function(_, p)
		return project(p)
	end)
	fn(camera, "WorldToScreenPoint", function(_, p)
		return project(p)
	end)
	fn(camera, "ViewportPointToRay", function()
		return roblox.Ray.new(camera.CFrame.Position, camera.CFrame.LookVector)
	end)
	fn(camera, "ScreenPointToRay", function()
		return roblox.Ray.new(camera.CFrame.Position, camera.CFrame.LookVector)
	end)
	fn(camera, "GetPartsObscuringTarget", function()
		return {}
	end)
	local terrain = new("Terrain", "Terrain")
	terrain.Parent = workspace
	rawget(workspace, "__props").Terrain = terrain
	fn(workspace, "Raycast", function()
		return nil
	end)
	for _, name in { "GetPartBoundsInRadius", "GetPartBoundsInBox", "GetPartsInPart" } do
		fn(workspace, name, function()
			return {}
		end)
	end
	for _, name in { "Blockcast", "Spherecast", "Shapecast" } do
		fn(workspace, name, function()
			return nil
		end)
	end
	fn(workspace, "GetServerTimeNow", function()
		return 1.7e9 + now
	end)
	fn(workspace, "GetRealPhysicsFPS", function()
		return 60
	end)
	rawget(workspace, "__props").Gravity = 196.2
	rawget(workspace, "__props").DistributedGameTime = 0

	-- Players y tú
	local players = service("Players")
	local localPlayer = new("Player", "Rayo")
	local lp = rawget(localPlayer, "__props")
	lp.DisplayName, lp.UserId, lp.AccountAge = "Rayo", 1, 100
	localPlayer.Parent = players
	rawget(players, "__props").LocalPlayer = localPlayer
	local playerGui = new("PlayerGui", "PlayerGui")
	playerGui.Parent = localPlayer
	local playerScripts = new("PlayerScripts", "PlayerScripts")
	playerScripts.Parent = localPlayer
	new("Backpack", "Backpack").Parent = localPlayer
	local mouse = new("Mouse", "Mouse")
	rawget(mouse, "__props").Hit = CF.new()
	rawget(mouse, "__props").X = 400
	rawget(mouse, "__props").Y = 300
	fn(localPlayer, "GetMouse", function()
		return mouse
	end)
	fn(localPlayer, "GetNetworkPing", function()
		return 0.05
	end)
	fn(localPlayer, "GetRankInGroup", function()
		return 0
	end)
	fn(localPlayer, "IsInGroup", function()
		return false
	end)
	fn(localPlayer, "HasAppearanceLoaded", function()
		return true
	end)
	fn(players, "GetPlayers", function()
		return { localPlayer }
	end)
	fn(players, "GetPlayerFromCharacter", function(_, model)
		return if model ~= nil and model == localPlayer.Character then localPlayer else nil
	end)
	fn(players, "GetPlayerByUserId", function(_, id)
		return if id == 1 then localPlayer else nil
	end)
	fn(players, "GetUserThumbnailAsync", function()
		return "rbxthumb://type=AvatarHeadShot&id=1&w=150&h=150", true
	end)
	fn(players, "GetNameFromUserIdAsync", function()
		return "Rayo"
	end)

	-- Servicios con algo de comportamiento
	local runService = service("RunService")
	for name, value in { IsClient = true, IsServer = false, IsStudio = false, IsRunning = true, IsRunMode = false, IsEdit = false } do
		fn(runService, name, function()
			return value
		end)
	end
	local renderSteps: { [string]: any } = {}
	fn(runService, "BindToRenderStep", function(_, name, _, f)
		renderSteps[name] = f
	end)
	fn(runService, "UnbindFromRenderStep", function(_, name)
		renderSteps[name] = nil
	end)

	local uis = service("UserInputService")
	local up = rawget(uis, "__props")
	up.TouchEnabled, up.KeyboardEnabled, up.MouseEnabled = mode.Touch, not mode.Touch, not mode.Touch
	up.GamepadEnabled, up.AccelerometerEnabled, up.GyroscopeEnabled, up.VREnabled = false, false, false, false
	for name, value in {
		GetFocusedTextBox = nil, IsKeyDown = false, IsMouseButtonPressed = false, GetGamepadConnected = false,
		IsGamepadButtonDown = false, GetStringForKeyCode = "E", GetImageForKeyCode = "",
	} :: { [string]: any } do
		fn(uis, name, function()
			return value
		end)
	end
	fn(uis, "GetFocusedTextBox", function()
		return nil
	end)
	for _, name in { "GetConnectedGamepads", "GetNavigationGamepads", "GetKeysPressed", "GetMouseButtonsPressed", "GetSupportedGamepadKeyCodes", "GetGamepadState" } do
		fn(uis, name, function()
			return {}
		end)
	end
	fn(uis, "GetLastInputType", function()
		return if mode.Touch then Enum.UserInputType.Touch else Enum.UserInputType.Keyboard
	end)
	fn(uis, "GetMouseLocation", function()
		return V2.new(400, 300)
	end)
	fn(uis, "GetMouseDelta", function()
		return V2.zero
	end)

	local tweenService = service("TweenService")
	fn(tweenService, "Create", function(_, object, info, goals)
		local tween = new("Tween", "Tween")
		rawget(tween, "__props").PlaybackState = Enum.PlaybackState.Begin
		fn(tween, "Play", function(self)
			for key, value in goals do
				object[key] = value
			end
			rawget(tween, "__props").PlaybackState = Enum.PlaybackState.Completed
			local completed = signalOf(tween, "Completed")
			fakeTask.delay(if type(info) == "table" then info.Time or 0 else 0, function()
				completed:Fire(Enum.PlaybackState.Completed)
			end)
		end)
		fn(tween, "Cancel", function() end)
		fn(tween, "Pause", function() end)
		return tween
	end)
	fn(tweenService, "GetValue", function(_, alpha)
		return alpha
	end)

	local cas = service("ContextActionService")
	for _, name in { "BindAction", "BindActionAtPriority", "UnbindAction", "SetTitle", "SetImage", "SetPosition", "SetDescription", "BindActivate", "UnbindActivate", "UnbindAllActions" } do
		fn(cas, name, function() end)
	end
	fn(cas, "GetButton", function()
		return nil
	end)
	fn(cas, "GetAllBoundActionInfo", function()
		return {}
	end)
	fn(cas, "GetBoundActionInfo", function()
		return {}
	end)

	local collection = service("CollectionService")
	fn(collection, "GetTagged", function(_, tag)
		local out = {}
		for o in tagged[tag] or {} do
			table.insert(out, o)
		end
		return out
	end)
	fn(collection, "GetInstanceAddedSignal", function(_, tag)
		return tagSignal(tag).Added
	end)
	fn(collection, "GetInstanceRemovedSignal", function(_, tag)
		return tagSignal(tag).Removed
	end)
	fn(collection, "HasTag", function(_, o, tag)
		return o:HasTag(tag)
	end)
	fn(collection, "AddTag", function(_, o, tag)
		o:AddTag(tag)
	end)
	fn(collection, "RemoveTag", function(_, o, tag)
		o:RemoveTag(tag)
	end)
	fn(collection, "GetTags", function(_, o)
		return o:GetTags()
	end)
	fn(collection, "GetAllTags", function()
		local out = {}
		for tag in tagged do
			table.insert(out, tag)
		end
		return out
	end)

	local guiService = service("GuiService")
	fn(guiService, "GetGuiInset", function()
		return V2.new(0, 58), V2.new(0, 0)
	end)
	rawget(guiService, "__props").TopbarInset = roblox.Rect.new(0, 0, mode.Viewport.X - 120, 58)
	fn(guiService, "IsTenFootInterface", function()
		return false
	end)

	local textService = service("TextService")
	fn(textService, "GetTextSize", function(_, text, size, _, frame)
		local s = tonumber(size) or 14
		local width = #tostring(text) * s * 0.5
		local maxW = if typeof(frame) == "Vector2" then frame.X else math.huge
		local lines = math.max(1, math.ceil(width / math.max(1, maxW)))
		return V2.new(math.min(width, maxW), lines * s)
	end)

	local starterGui = service("StarterGui")
	fn(starterGui, "SetCore", function() end)
	fn(starterGui, "SetCoreGuiEnabled", function() end)
	fn(starterGui, "GetCore", function()
		return nil
	end)
	fn(starterGui, "GetCoreGuiEnabled", function()
		return true
	end)

	local lighting = service("Lighting")
	rawget(lighting, "__props").ClockTime = 14
	fn(lighting, "GetMinutesAfterMidnight", function()
		return lighting.ClockTime * 60
	end)
	fn(lighting, "SetMinutesAfterMidnight", function(_, m)
		lighting.ClockTime = m / 60
	end)
	fn(lighting, "GetSunDirection", function()
		return V3.new(0.3, 0.9, 0.2).Unit
	end)
	fn(lighting, "GetMoonDirection", function()
		return V3.new(-0.3, 0.9, -0.2).Unit
	end)
	for _, className in { "Atmosphere", "Sky", "BloomEffect", "SunRaysEffect", "ColorCorrectionEffect", "DepthOfFieldEffect" } do
		local name = ({ BloomEffect = "Bloom", SunRaysEffect = "SunRays", ColorCorrectionEffect = "ColorCorrection", DepthOfFieldEffect = "DepthOfField" })[className] or className
		new(className, name).Parent = lighting
	end
	-- La tecnología de luz, como la pone el archivo del juego (default.project.json)
	do
		local project = serde.decode("json", fs.readFile("default.project.json"))
		local tech = project.tree.Lighting["$properties"].Technology
		rawget(lighting, "__props").Technology = (Enum.Technology :: any)[tech]
	end

	local http = service("HttpService")
	fn(http, "JSONEncode", function(_, v)
		return serde.encode("json", v)
	end)
	fn(http, "JSONDecode", function(_, s)
		return serde.decode("json", s)
	end)
	local guid = 0
	fn(http, "GenerateGUID", function()
		guid += 1
		return "guid-" .. guid
	end)
	fn(http, "UrlEncode", function(_, s)
		return s
	end)

	local market = service("MarketplaceService")
	fn(market, "UserOwnsGamePassAsync", function()
		return false
	end)
	fn(market, "GetProductInfo", function()
		return { Name = "", PriceInRobux = 0, Description = "" }
	end)
	local debris = service("Debris")
	fn(debris, "AddItem", function(_, o, t)
		fakeTask.delay(t or 10, function()
			o:Destroy()
		end)
	end)
	local contentProvider = service("ContentProvider")
	fn(contentProvider, "PreloadAsync", function() end)
	local pathfinding = service("PathfindingService")
	fn(pathfinding, "CreatePath", function()
		local path = new("Path", "Path")
		rawget(path, "__props").Status = Enum.PathStatus.NoPath
		fn(path, "ComputeAsync", function() end)
		fn(path, "GetWaypoints", function()
			return {}
		end)
		return path
	end)
	local policy = service("PolicyService")
	fn(policy, "GetPolicyInfoForPlayerAsync", function()
		return { IsPaidItemTradingAllowed = true, ArePaidRandomItemsRestricted = false, AllowedExternalLinkReferences = {}, IsSubjectToChinaPolicies = false }
	end)
	local soundService = service("SoundService")
	fn(soundService, "PlayLocalSound", function() end)
	local haptics = service("HapticService")
	fn(haptics, "IsVibrationSupported", function()
		return false
	end)
	fn(haptics, "IsMotorSupported", function()
		return false
	end)

	-----------------------------------------------------------------
	-- ReplicatedStorage (Shared = src/shared, Remotes del proyecto) y el cliente
	-----------------------------------------------------------------
	local replicated = service("ReplicatedStorage")
	local function mount(dir: string, parent: any, name: string)
		local folder = new("Folder", name)
		folder.Parent = parent
		for _, entry in fs.readDir(dir) do
			local path = dir .. "/" .. entry
			if fs.isDir(path) then
				mount(path, folder, entry)
			elseif string.match(entry, "%.luau$") then
				local base = string.gsub(entry, "%.luau$", "")
				local className = "ModuleScript"
				if string.match(base, "%.client$") then
					base = string.gsub(base, "%.client$", "")
					className = "LocalScript"
				elseif string.match(base, "%.server$") then
					base = string.gsub(base, "%.server$", "")
					className = "Script"
				end
				local s = new(className, base)
				rawset(s, "__file", path)
				rawset(s, "__source", fs.readFile(path)) -- ahora: fs de Lune no se puede usar dentro de los hilos simulados
				s.Parent = folder
			end
		end
		return folder
	end
	mount(ROOT .. "/shared", replicated, "Shared")
	local remotes = new("Folder", "Remotes")
	remotes.Parent = replicated
	local project = serde.decode("json", fs.readFile("default.project.json"))
	for name, spec in project.tree.ReplicatedStorage.Remotes do
		if type(spec) == "table" and spec["$className"] then
			new(spec["$className"], name).Parent = remotes
		end
	end
	new("Folder", "Musica").Parent = replicated
	-- Lo que el servidor publica para los mapas (vacío): así el minimapa se monta enseguida
	for _, name in { "Ambient", "MapZones", "MapLandmarks" } do
		new("Folder", name).Parent = replicated
	end
	local client = mount(ROOT .. "/client", playerScripts, "Client")
	-- El PlayerModule de Roblox (controles y cámara)
	local playerModule = new("ModuleScript", "PlayerModule")
	local controls = { Enable = function() end, Disable = function() end, GetMoveVector = function()
		return V3.zero
	end }
	rawset(playerModule, "__value", {
		GetControls = function()
			return controls
		end,
		GetCameras = function()
			return U("Cameras")
		end,
	})
	playerModule.Parent = playerScripts

	-----------------------------------------------------------------
	-- require y el entorno de cada script
	-----------------------------------------------------------------
	local cache: { [any]: any } = {}
	local loading: { [any]: boolean } = {}
	local typeofReal = typeof
	local function fakeTypeof(v: any): string
		if type(v) == "table" then
			if rawget(v, "__class") then
				return "Instance"
			elseif rawget(v, "__signal") then
				return "RBXScriptSignal"
			elseif rawget(v, "__conn") then
				return "RBXScriptConnection"
			elseif getmetatable(v) == mockMeta then
				return "Instance"
			end
		end
		return typeofReal(v)
	end

	local function warnFn(...)
		local parts = {}
		for i = 1, select("#", ...) do
			table.insert(parts, tostring((select(i, ...))))
		end
		local line = table.concat(parts, " ")
		warnings[line] = (warnings[line] or 0) + 1
	end

	local fakeOs = setmetatable({
		clock = function()
			return now
		end,
		time = function(t)
			return if t then os.time(t) else math.floor(1.7e9 + now)
		end,
	}, { __index = os })

	local sharedTable = {}
	local userSettings = new("UserSettings", "UserSettings")
	rawset(userSettings, "GetService", function(_, name)
		return service(name)
	end)
	rawget(service("UserGameSettings"), "__props").SavedQualityLevel = Enum.SavedQualitySetting.Automatic
	local requireFn
	local function envFor(scriptInstance: any): any
		return setmetatable({
			script = scriptInstance,
			require = requireFn,
			game = game,
			workspace = workspace,
			Workspace = workspace,
			task = fakeTask,
			wait = fakeTask.wait,
			delay = fakeTask.delay,
			spawn = fakeTask.spawn,
			tick = function()
				return 1.7e9 + now
			end,
			time = function()
				return now
			end,
			elapsedTime = function()
				return now
			end,
			os = fakeOs,
			Instance = InstanceLib,
			Vector3 = V3,
			Vector2 = V2,
			CFrame = CF,
			Color3 = C3,
			Enum = Enum,
			UDim = roblox.UDim,
			UDim2 = roblox.UDim2,
			Font = roblox.Font,
			BrickColor = roblox.BrickColor,
			NumberRange = roblox.NumberRange,
			NumberSequence = roblox.NumberSequence,
			NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
			ColorSequence = roblox.ColorSequence,
			ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
			Rect = roblox.Rect,
			Ray = roblox.Ray,
			Region3 = roblox.Region3,
			PhysicalProperties = roblox.PhysicalProperties,
			Faces = roblox.Faces,
			Axes = roblox.Axes,
			Vector3int16 = roblox.Vector3int16,
			Vector2int16 = roblox.Vector2int16,
			TweenInfo = {
				new = function(t, style, direction, repeatCount, reverses, delayTime)
					return {
						Time = t or 1,
						EasingStyle = style or Enum.EasingStyle.Quad,
						EasingDirection = direction or Enum.EasingDirection.Out,
						RepeatCount = repeatCount or 0,
						Reverses = reverses or false,
						DelayTime = delayTime or 0,
					}
				end,
			},
			RaycastParams = {
				new = function()
					return { FilterDescendantsInstances = {}, FilterType = Enum.RaycastFilterType.Exclude, IgnoreWater = false, CollisionGroup = "Default", RespectCanCollide = false, AddToFilter = function() end }
				end,
			},
			OverlapParams = {
				new = function()
					return { FilterDescendantsInstances = {}, FilterType = Enum.RaycastFilterType.Exclude, MaxParts = 0, CollisionGroup = "Default", RespectCanCollide = false, AddToFilter = function() end }
				end,
			},
			Random = {
				new = function()
					local r = {}
					function r.NextNumber(_, a, b)
						a, b = a or 0, b or 1
						return a + math.random() * (b - a)
					end
					function r.NextInteger(_, a, b)
						return math.random(a, b)
					end
					function r.NextUnitVector()
						return V3.new(0, 1, 0)
					end
					function r.Shuffle() end
					function r.Clone()
						return r
					end
					return r
				end,
			},
			DateTime = {
				now = function()
					local t = math.floor(1.7e9 + now)
					return {
						UnixTimestamp = t,
						UnixTimestampMillis = t * 1000,
						ToLocalTime = function()
							return { Year = 2026, Month = 9, Day = 28, Hour = 12, Minute = 0, Second = 0, Millisecond = 0 }
						end,
						ToUniversalTime = function()
							return { Year = 2026, Month = 9, Day = 28, Hour = 12, Minute = 0, Second = 0, Millisecond = 0 }
						end,
						FormatLocalTime = function()
							return ""
						end,
						FormatUniversalTime = function()
							return ""
						end,
					}
				end,
			},
			typeof = fakeTypeof,
			warn = warnFn,
			print = function() end,
			settings = function()
				return U("settings()")
			end,
			UserSettings = function()
				return userSettings
			end,
			shared = sharedTable,
		}, { __index = _G })
	end

	local function run(scriptInstance: any): any
		local file = rawget(scriptInstance, "__file")
		local source = rawget(scriptInstance, "__source")
		local chunk = luau.load(source, { debugName = file, environment = envFor(scriptInstance) })
		return chunk()
	end

	requireFn = function(target: any): any
		if type(target) == "number" then
			return U("require(" .. target .. ")")
		end
		if type(target) ~= "table" or rawget(target, "__class") == nil then
			error("require: se esperaba un ModuleScript, llegó " .. fakeTypeof(target), 2)
		end
		if rawget(target, "__class") ~= "ModuleScript" then
			error(("require: %s no es un ModuleScript"):format(target:GetFullName()), 2)
		end
		if cache[target] ~= nil then
			return cache[target]
		end
		if rawget(target, "__value") ~= nil then
			return rawget(target, "__value")
		end
		if not rawget(target, "__file") then
			return U("require(" .. target:GetFullName() .. ")") -- sustituto (PlayerModule…)
		end
		if loading[target] then
			if loading[target] == coroutine.running() then
				error("require en bucle: " .. target:GetFullName(), 2)
			end
			-- Otro hilo lo está cargando (y espera algo): como en Roblox, se espera a que acabe
			local waited = 0
			while loading[target] and waited < 30 do
				waited += fakeTask.wait(0.1)
			end
			if cache[target] ~= nil then
				return cache[target]
			end
			error("require: " .. target:GetFullName() .. " no termina de cargar", 2)
		end
		loading[target] = coroutine.running()
		local ok, result = xpcall(run, function(e)
			return tostring(e) .. "\n" .. debug.traceback()
		end, target)
		loading[target] = nil
		if not ok then
			report("require " .. rawget(target, "__file"), result)
			error(("Requested module experienced an error while loading: %s"):format(target:GetFullName()), 2)
		end
		if result == nil then
			report("require " .. rawget(target, "__file"), "el módulo no devuelve nada")
		end
		loaded[rawget(target, "__file")] = true
		cache[target] = result
		return result
	end

	-----------------------------------------------------------------
	-- Tu personaje (aparece a los 2 s, como en el juego)
	-----------------------------------------------------------------
	local function spawnCharacter()
		local model = new("Model", "Rayo")
		local function part(name: string, size: any, offset: any)
			local p = new("Part", name)
			p.Size = size
			p.CFrame = CF.new(V3.new(0, 3, 0) + offset)
			p.Parent = model
			return p
		end
		local root = part("HumanoidRootPart", V3.new(2, 2, 1), V3.zero)
		local head = part("Head", V3.new(1.2, 1.2, 1.2), V3.new(0, 1.9, 0))
		local upper = part("UpperTorso", V3.new(2, 1.6, 1), V3.new(0, 0.6, 0))
		local lower = part("LowerTorso", V3.new(2, 0.4, 1), V3.new(0, -0.3, 0))
		local limbs: { [string]: any } = {}
		for _, side in { "Left", "Right" } do
			local x = if side == "Left" then -1.5 else 1.5
			limbs[side .. "UpperArm"] = part(side .. "UpperArm", V3.new(1, 1.2, 1), V3.new(x, 0.6, 0))
			limbs[side .. "LowerArm"] = part(side .. "LowerArm", V3.new(1, 1.1, 1), V3.new(x, -0.4, 0))
			limbs[side .. "Hand"] = part(side .. "Hand", V3.new(1, 0.3, 1), V3.new(x, -1.1, 0))
			limbs[side .. "UpperLeg"] = part(side .. "UpperLeg", V3.new(1, 1.2, 1), V3.new(x / 3, -1.1, 0))
			limbs[side .. "LowerLeg"] = part(side .. "LowerLeg", V3.new(1, 1.2, 1), V3.new(x / 3, -2.2, 0))
			limbs[side .. "Foot"] = part(side .. "Foot", V3.new(1, 0.3, 1), V3.new(x / 3, -2.9, 0))
		end
		-- Ordenador: Motor6D. Móvil: las articulaciones nuevas de Roblox (AnimationConstraint entre dos
		-- Attachment, sin C0/C1/Part0/Part1), como los avatares del juego publicado: así se prueba que lo
		-- que mueve el cuerpo con código (agacharse…) funciona con las dos.
		local function motor(name: string, owner: any, part0: any, c0: any?, c1: any?)
			if mode.Touch then
				local a0 = new("Attachment", name .. "RigAttachment")
				a0.CFrame = c0 or CF.new()
				a0.Parent = part0
				local a1 = new("Attachment", name .. "RigAttachment")
				a1.CFrame = c1 or CF.new()
				a1.Parent = owner
				local m = new("AnimationConstraint", name)
				m.Attachment0, m.Attachment1, m.Transform = a0, a1, CF.new()
				m.Parent = owner
				return
			end
			local m = new("Motor6D", name)
			m.Part0, m.Part1 = part0, owner
			m.C0, m.C1, m.Transform = CF.new(), CF.new(), CF.new()
			m.Parent = owner
		end
		motor("Root", lower, root)
		motor("Waist", upper, lower)
		motor("Neck", head, upper)
		for _, side in { "Left", "Right" } do
			local x = if side == "Left" then -0.5 else 0.5
			motor(side .. "Shoulder", limbs[side .. "UpperArm"], upper)
			motor(side .. "Elbow", limbs[side .. "LowerArm"], limbs[side .. "UpperArm"])
			motor(side .. "Wrist", limbs[side .. "Hand"], limbs[side .. "LowerArm"])
			-- (piernas con medidas de R15: cadera → rodilla → tobillo)
			motor(side .. "Hip", limbs[side .. "UpperLeg"], lower, CF.new(x, -0.2, 0), CF.new(0, 0.45, 0))
			motor(side .. "Knee", limbs[side .. "LowerLeg"], limbs[side .. "UpperLeg"], CF.new(0, -0.45, 0), CF.new(0, 0.4, 0))
			motor(side .. "Ankle", limbs[side .. "Foot"], limbs[side .. "LowerLeg"], CF.new(0, -0.45, 0), CF.new(0, 0.1, 0))
		end
		local humanoid = new("Humanoid", "Humanoid")
		local hp = rawget(humanoid, "__props")
		hp.RigType = Enum.HumanoidRigType.R15
		hp.RootPart = root
		hp.MoveDirection = V3.zero
		hp.FloorMaterial = Enum.Material.Plastic
		fn(humanoid, "GetState", function()
			return Enum.HumanoidStateType.Running
		end)
		for _, name in { "ChangeState", "Move", "MoveTo", "SetStateEnabled", "EquipTool", "UnequipTools", "TakeDamage", "ApplyDescription", "AddAccessory", "BuildRigFromAttachments" } do
			fn(humanoid, name, function() end)
		end
		fn(humanoid, "GetStateEnabled", function()
			return true
		end)
		fn(humanoid, "GetAccessories", function()
			return {}
		end)
		fn(humanoid, "GetAppliedDescription", function()
			return new("HumanoidDescription")
		end)
		humanoid.Parent = model
		new("Animator", "Animator").Parent = humanoid
		rawget(model, "__props").PrimaryPart = root
		model.Parent = workspace
		lp.Character = model
		signalOf(localPlayer, "CharacterAdded"):Fire(model)
		signalOf(localPlayer, "CharacterAppearanceLoaded"):Fire(model)
		return model
	end

	-- Un vecino (para los bocadillos que llegan del servidor)
	local function spawnNpc(name: string, at: any): any
		local model = new("Model", name)
		local root = new("Part", "HumanoidRootPart")
		root.CFrame = CF.new(at)
		root.Parent = model
		local head = new("Part", "Head")
		head.Size = V3.new(1.2, 1.2, 1.2)
		head.CFrame = CF.new(at + V3.new(0, 1.9, 0))
		head.Parent = model
		new("Humanoid", "Humanoid").Parent = model
		rawget(model, "__props").PrimaryPart = root
		model.Parent = workspace
		return model
	end

	-----------------------------------------------------------------
	-- A correr
	-----------------------------------------------------------------
	local main = client:FindFirstChild("Main")
	assert(main, "no está src/client/Main.client.luau")
	local mainDone = false
	local mainThread = fakeTask.spawn(function()
		local ok, err = xpcall(run, function(e)
			return tostring(e) .. "\n" .. debug.traceback()
		end, main)
		if not ok then
			report("Main.client", err)
		end
		loaded[rawget(main, "__file")] = true
		mainDone = true
	end)

	local checks: { { any } } = {}
	local realStart = realClock()
	local frames = math.floor(SIM_SECONDS * FPS)
	local dt = 1 / FPS
	-- Las apps del ValPhone (todas, se vean o no): por su nombre («Tienda») y por su comando («AppTienda»)
	local function rowLabels(): { [string]: boolean }
		local out = {}
		local phone = playerGui:FindFirstChild("PhoneGui")
		for _, object in (phone and phone:GetDescendants()) or {} do
			local command = object:GetAttribute("Command")
			if command then
				out[tostring(command)] = true
				local label = object:FindFirstChild("Label")
				if label then
					out[tostring(label.Text)] = true
				end
			end
		end
		return out
	end
	local events = {
		[math.floor(2 * FPS)] = function()
			spawnCharacter()
		end,
		[math.floor(3 * FPS)] = function()
			-- Una misión canónica pendiente (LifeStoryService): su ❗ en el minimapa
			localPlayer:SetAttribute("CanonMarks", '[{"Id":"Grieta01","Title":"La grieta","X":40,"Y":0,"Z":-60}]')
		end,
		[math.floor(3.5 * FPS)] = function()
			-- La Grieta del cielo abierta (Controllers/SkyRift): se construye, se abre y late
			localPlayer:SetAttribute("SkyRift", "Abierta")
		end,
		[math.floor(13.5 * FPS)] = function()
			local folder = workspace:FindFirstChild("CieloGrieta")
			local drawn, rocks = 0, 0
			for _, d in (if folder then folder:GetDescendants() else {}) do
				if d.ClassName == "Frame" or d.ClassName == "ImageLabel" then
					drawn += 1
				elseif d.ClassName == "WedgePart" then
					rocks += 1
				end
			end
			table.insert(checks, { folder ~= nil and drawn >= 10, ("la Grieta del cielo se dibuja (%d capas/tramos en el lienzo, %d rocas)"):format(drawn, rocks) })
			localPlayer:SetAttribute("SkyRift", "Cerrada")
		end,
		[math.floor(23 * FPS)] = function()
			-- Gráficos: DayLight pinta los efectos de imagen y el menú tiene «✨ Gráficos»
			local lightingNow = game:GetService("Lighting")
			local bloom = lightingNow:FindFirstChild("Bloom")
			local cc = lightingNow:FindFirstChild("ColorCorrection")
			table.insert(checks, {
				bloom ~= nil and bloom.Intensity > 0 and cc ~= nil and cc.Contrast > 0,
				"gráficos: la luz de la hora llega a los efectos (resplandor y color)",
			})
			local menuRow = false
			for _, d in playerGui:GetDescendants() do
				if rawget(d, "__class") == "TextButton" and string.find(tostring(d.Text), "Gráficos", 1, true) then
					menuRow = true
				end
			end
			table.insert(checks, { menuRow, "gráficos: el menú tiene la opción «✨ Gráficos»" })
		end,
		[math.floor(41.5 * FPS)] = function()
			-- (aquí el juego va a 20 fotogramas por segundo simulados, como un móvil justo: el modo
			-- «Auto» baja de Alto a Medio, pero NO a Bajo (suelo de Medio con más de 20 fps); las sombras
			-- del sol siguen al nivel y el botón del menú dice el nivel de ahora)
			local lightingNow = game:GetService("Lighting")
			local tier = localPlayer:GetAttribute("GraphicsTier") or "Medium"
			local label = ""
			for _, d in playerGui:GetDescendants() do
				if rawget(d, "__class") == "TextButton" and string.find(tostring(d.Text), "Gráficos", 1, true) then
					label = tostring(d.Text)
				end
			end
			table.insert(checks, {
				tier == "Medium" and lightingNow.GlobalShadows == true and string.find(label, "ahora Medio", 1, true) ~= nil,
				("gráficos: a 20 fps el Auto se queda en Medio (no cae a Bajo), con sombras, y el menú lo dice (%s, sombras %s, «%s»)"):format(tostring(tier), tostring(lightingNow.GlobalShadows), label),
			})
		end,
		[math.floor(5 * FPS)] = function()
			local found = false
			for _, d in playerGui:GetDescendants() do
				if d.Name ~= "Title" and rawget(d, "__class") == "TextLabel" and d.Text == "❗" and d.Visible then
					found = true
				end
			end
			table.insert(checks, { found, "las misiones canónicas pendientes salen en el mapa (❗)" })
		end,
		[math.floor(6 * FPS)] = function()
			-- Lo que manda el servidor mientras juegas: bocadillos, la familia, una conversación
			local a = spawnNpc("Vecina", V3.new(4, 3, -4))
			local b = spawnNpc("Vecino", V3.new(5, 3, -4))
			local speech = remotes:FindFirstChild("Speech")
			if speech then
				speech.OnClientEvent:Fire({ Speaker = a, Text = "¡Buenos días! Qué calor hace hoy, ¿eh?" })
				speech.OnClientEvent:Fire({ Speaker = b, Text = "Ni que lo digas.", Seconds = 3 })
				speech.OnClientEvent:Fire({ Speaker = a, Text = "Me voy a la playa." })
			end
			local baby = remotes:FindFirstChild("Baby")
			if baby then
				baby.OnClientEvent:Fire("Say", { SpeakerKey = "NPC.ABU_ROSA", TextKey = "DLG.ABU.BEBE.LEVANTATE", Role = "Abu", Speaker = a })
				baby.OnClientEvent:Fire("Say", { TextKey = "BABY.TOYS" })
			end
			local dialogue = remotes:FindFirstChild("Dialogue")
			if dialogue then
				dialogue.OnClientEvent:Fire("Show", {
					Token = "t1",
					Lines = {
						{ Name = "Vecina", Text = "¿Me ayudas con la compra?", Actor = a, Voice = "Narrador" },
						{ Name = "Rayo", Text = "¡Claro!", Actor = localPlayer.Character, Me = true },
						{ Text = "Y así empezó todo.", Narrator = true },
					},
					Options = { "Sí", "No" },
					Ask = "¿Qué le dices?",
				})
			end
		end,
		[math.floor(7 * FPS)] = function()
			-- Un bocadillo por personaje: la Vecina habló tres veces (y es quien habla en la
			-- conversación), el Vecino una: dos bocadillos, cada uno sobre su cabeza
			local byHead: { [any]: number } = {}
			local total = 0
			for _, child in playerGui:GetChildren() do
				if child.Name == "SpeechBubble" and child.Enabled then
					total += 1
					byHead[child.Adornee] = (byHead[child.Adornee] or 0) + 1
				end
			end
			local a, b = workspace:FindFirstChild("Vecina"), workspace:FindFirstChild("Vecino")
			table.insert(checks, {
				total == 2 and byHead[a and a.Head] == 1 and byHead[b and b.Head] == 1,
				("bocadillos: uno encima de cada personaje que habla, sin repetir (%d)"):format(total),
			})
			local line
			for _, d in playerGui:GetDescendants() do
				if d.Name == "Line" and d.Parent and d.Parent.Name == "Panel" and d.Parent.Parent.Adornee == (a and a.Head) then
					line = d.Text
				end
			end
			table.insert(checks, { line == "¿Me ayudas con la compra?", "la frase de la conversación sale en el bocadillo de quien la dice (la nueva sustituye a la vieja)" })
			-- La frase de la conversación va encima de todo (las paredes no la tapan); la de la calle, no
			local onTop, streetOnTop = nil, nil
			for _, child in playerGui:GetChildren() do
				if child.Name == "SpeechBubble" and child.Adornee == (a and a.Head) then
					onTop = child.AlwaysOnTop
				elseif child.Name == "SpeechBubble" and child.Adornee == (b and b.Head) then
					streetOnTop = child.AlwaysOnTop
				end
			end
			table.insert(checks, { onTop == true and streetOnTop == false, "el bocadillo de la conversación va encima de todo (AlwaysOnTop) y el de la calle no" })
			-- Un choque con quien te está hablando: ni «¡Eh!» ni se corta la frase
			local nudgeModule = client:FindFirstChild("Controllers") and client.Controllers:FindFirstChild("Nudge")
			local okNudge, Nudge = pcall(requireFn, nudgeModule)
			if okNudge and Nudge and Nudge.say and a then
				local said = Nudge.say(a.Head, "¡Oye, mira por dónde vas!", 1.8)
				local after
				for _, d in playerGui:GetDescendants() do
					if d.Name == "Line" and d.Parent and d.Parent.Name == "Panel" and d.Parent.Parent.Adornee == a.Head then
						after = d.Text
					end
				end
				table.insert(checks, { said == false and after == "¿Me ayudas con la compra?", "un empujón no corta la frase de la conversación (ni sale «¡Oye…!»)" })
				table.insert(checks, { Nudge.quiet(a) == true, "en plena conversación, quien te habla no reacciona a un empujón" })
			else
				table.insert(checks, { false, "no se pudo cargar Nudge (" .. tostring(Nudge) .. ")" })
			end
			-- Mientras hablas con alguien, la calle calla (frases sueltas del servidor)
			local speech3 = remotes:FindFirstChild("Speech")
			if speech3 and b and localPlayer:GetAttribute("InDialogue") then
				speech3.OnClientEvent:Fire({ Speaker = b, Text = "¡Oferta de sandías!", Seconds = 3 })
				local cut = false
				for _, d in playerGui:GetDescendants() do
					if d.Name == "Line" and d.Text == "¡Oferta de sandías!" then
						cut = true
					end
				end
				table.insert(checks, { not cut, "durante una conversación no salen las frases sueltas de la calle" })
			end
			local dialogueGui = playerGui:FindFirstChild("DialogueUI")
			local box = dialogueGui and dialogueGui:FindFirstChild("Dialogue")
			table.insert(checks, { box ~= nil and box.Visible, "la caja de la conversación sigue abajo (Toca para seguir / respuestas)" })
		end,
		[math.floor(12 * FPS)] = function()
			local b = workspace:FindFirstChild("Vecino")
			local still = false
			for _, child in playerGui:GetChildren() do
				if child.Name == "SpeechBubble" and child.Adornee == (b and b.Head) then
					still = true
				end
			end
			table.insert(checks, { not still, "el bocadillo con duración se va solo" })
			-- Durante una escena de cámara, la calle calla (sus frases sueltas no salen)
			local speech2 = remotes:FindFirstChild("Speech")
			if speech2 and b then
				localPlayer:SetAttribute("InCinematic", true)
				speech2.OnClientEvent:Fire({ Speaker = b, Text = "¡Oferta de melones!", Seconds = 3 })
				local shown = false
				for _, child in playerGui:GetChildren() do
					if child.Name == "SpeechBubble" and child.Enabled and child.Adornee == b.Head then
						shown = true
					end
				end
				localPlayer:SetAttribute("InCinematic", nil)
				table.insert(checks, { not shown, "durante una cinemática no salen los bocadillos de la calle" })
			end
			-- Peatones: en cada extremo de la acera siguen recto por la calle de enfrente (también si
			-- está dibujada al revés) o, si no sigue ninguna, se dan la vuelta antes de la calzada que cruza
			local controllers = client:FindFirstChild("Controllers")
			local ambientModule = controllers and controllers:FindFirstChild("Ambient")
			local okAmbient, Ambient = pcall(requireFn, ambientModule)
			if okAmbient and Ambient and Ambient.link then
				local function road(a: any, b: any)
					local dir = (b - a).Unit
					return { A = a, Dir = dir, Perp = V3.new(-dir.Z, 0, dir.X), Len = (b - a).Magnitude, From = 0, To = (b - a).Magnitude, Walk = 14.5, Half = 11, StartMargin = 0, EndMargin = 0 }
				end
				local r1, r2 = road(V3.new(0, 0, 0), V3.new(100, 0, 0)), road(V3.new(100, 0, 0), V3.new(200, 0, 0))
				local r3, r4 = road(V3.new(300, 0, 0), V3.new(200, 0, 0)), road(V3.new(100, 0, 0), V3.new(100, 0, 100))
				Ambient.link({ r1, r2, r3, r4 })
				table.insert(checks, {
					r1.Ahead and r1.Ahead.Road == r2 and not r1.Ahead.Flip and r2.Behind and r2.Behind.Road == r1
						and r2.Ahead and r2.Ahead.Road == r3 and r2.Ahead.Flip and r3.Ahead and r3.Ahead.Road == r2,
					"peatones: al final de la acera siguen por la de enfrente (sin desaparecer en el cruce)",
				})
				table.insert(checks, {
					r4.Behind == nil and math.abs(r4.StartMargin - 12.5) < 0.01 and r1.Behind == nil and r1.StartMargin == 0,
					"peatones: sin calle que siga, se dan la vuelta antes de pisar la calzada que cruza",
				})
			else
				table.insert(checks, { false, "peatones: no se pudo cargar Ambient.link (" .. tostring(Ambient) .. ")" })
			end
			local speech = remotes:FindFirstChild("Speech")
			if speech then
				speech.OnClientEvent:Fire({ Speaker = workspace:FindFirstChild("Vecina"), Text = nil })
			end
		end,
		[math.floor(14 * FPS)] = function()
			-- Llega un jugador nuevo (lo que pone OnboardingService al cargar su perfil). Aún hay
			-- una conversación abierta: la tarjeta de los primeros pasos espera
			localPlayer:SetAttribute("Tutorial", "Pendiente")
			localPlayer:SetAttribute("TutorialSteps", "")
		end,
		[math.floor(15 * FPS)] = function()
			local guide = playerGui:FindFirstChild("GuideGui")
			local card = guide and guide:FindFirstChild("TutorialCard")
			table.insert(checks, { card ~= nil and localPlayer:GetAttribute("InDialogue") == true and card.Visible == false, "primeros pasos: en una conversación la tarjeta no sale" })
			local help = playerGui:FindFirstChild("HelpGui")
			local touchGui = playerGui:FindFirstChild("TouchLayout")
			local button = (help and help:FindFirstChild("HelpButton")) or (touchGui and touchGui:FindFirstChild("Ayuda"))
			table.insert(checks, { button ~= nil, "el botón ❓ «¿Qué hago ahora?» existe" })
			localPlayer:SetAttribute("InDialogue", nil) -- (acaba la conversación)
		end,
		[math.floor(16 * FPS)] = function()
			local guide = playerGui:FindFirstChild("GuideGui")
			local card = guide and guide:FindFirstChild("TutorialCard")
			table.insert(checks, { card ~= nil and card.Visible, "primeros pasos: al acabar la conversación, la tarjeta sale a un jugador nuevo" })
			-- En el prólogo se aparta
			localPlayer:SetAttribute("InPrologue", true)
		end,
		[math.floor(17 * FPS)] = function()
			local guide = playerGui:FindFirstChild("GuideGui")
			local card = guide and guide:FindFirstChild("TutorialCard")
			table.insert(checks, { card ~= nil and card.Visible == false, "en el prólogo (InPrologue) no sale la tarjeta" })
			localPlayer:SetAttribute("InPrologue", nil)
		end,

		-- La historia se entiende (Controllers/Prologue, LifeStory, StoryJournal)
		[math.floor(18 * FPS)] = function()
			-- Se cierra la conversación de antes (el servidor la corta)
			local dialogue = remotes:FindFirstChild("Dialogue")
			if dialogue then
				dialogue.OnClientEvent:Fire("Close", { Token = "t1" })
			end
		end,
		[math.floor(19 * FPS)] = function()
			-- Prólogo: el servidor pone InPrologue y manda el paso de saltar
			localPlayer:SetAttribute("InPrologue", true)
			local story = remotes:FindFirstChild("LifeStory")
			if story then
				story.OnClientEvent:Fire("State", {
					Prologue = true,
					Others = {},
					Tracked = {
						QuestId = "Prologo_Sueno", Kind = "Main", TitleKey = "Prólogo: el sueño", TextKey = "Salta la valla de flores",
						Icon = "✨", Beat = "Jump", StepNum = 3, StepTotal = 7,
						Hint = { Pc = "Pulsa Espacio para saltar", Touch = "Pulsa el botón de saltar (abajo a la derecha)" },
					},
				})
			end
		end,
		[math.floor(20 * FPS)] = function()
			local hints = playerGui:FindFirstChild("PrologueHints")
			local card = hints and hints:FindFirstChild("HintCard")
			local texts = {}
			for _, d in (card and card:GetDescendants()) or {} do
				if rawget(d, "__class") == "TextLabel" then
					table.insert(texts, tostring(d.Text))
				end
			end
			local all = table.concat(texts, " | ")
			table.insert(checks, { hints ~= nil and hints.Enabled and card ~= nil and card.Visible and all:find("Salta la valla", 1, true) ~= nil and all:find("Paso 3 de 7", 1, true) ~= nil,
				"prólogo: la tarjeta de ayuda sale con el objetivo y el paso (" .. all .. ")" })
			local wanted = if mode.Touch then "botón de saltar" else "Espacio"
			table.insert(checks, { all:find(wanted, 1, true) ~= nil, "prólogo: la ayuda es la de este dispositivo (" .. wanted .. ")" })
			-- Saltar: dos toques (el primero pregunta "¿Seguro?")
			local skip = card and card:FindFirstChild("Skip", true)
			if skip then
				skip.Activated:Fire()
				table.insert(checks, { tostring(skip.Text):find("Seguro", 1, true) ~= nil, "prólogo: el primer toque en Saltar pregunta si estás seguro" })
				skip.Activated:Fire()
			else
				table.insert(checks, { false, "prólogo: hay botón Saltar" })
			end
			-- (sin conversación abierta, algo dejó la cámara bloqueada a medias)
			localPlayer:SetAttribute("InDialogue", nil)
			workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
		end,
		[math.floor(21 * FPS)] = function()
			localPlayer:SetAttribute("InPrologue", nil) -- el servidor cierra el prólogo
		end,
		[math.floor(22 * FPS)] = function()
			local hints = playerGui:FindFirstChild("PrologueHints")
			table.insert(checks, { hints ~= nil and not hints.Enabled, "prólogo: al acabar (o saltarlo) la tarjeta se va" })
			local controllers = client:FindFirstChild("Controllers")
			local ok, Controls = pcall(requireFn, controllers and controllers:FindFirstChild("Controls"))
			table.insert(checks, { ok and Controls and not Controls.isDisabled(), "prólogo: al saltarlo, los controles vuelven" })
			table.insert(checks, { workspace.CurrentCamera.CameraType ~= Enum.CameraType.Scriptable, ("prólogo: y la cámara no se queda bloqueada (%s, conversación: %s)"):format(tostring(workspace.CurrentCamera.CameraType), tostring(localPlayer:GetAttribute("InDialogue"))) })
			-- «Anteriormente en tu vida…» mientras hay una conversación: espera
			localPlayer:SetAttribute("InDialogue", true)
			local story = remotes:FindFirstChild("LifeStory")
			if story then
				story.OnClientEvent:Fire("Recap", {
					ChapterTitleKey = "CHAPTER.NINO.TITLE", Stage = "Nino", StageName = "Infancia (el colegio)",
					Recent = {
						{ Kind = "Memory", Key = "Tu primer día de colegio", Icon = "🏫" },
						{ Kind = "Choice", Key = "Te sientas con Mateo", Icon = "🔀" },
					},
					Objective = { TitleKey = "La mochila perdida", TextKey = "Busca a Mateo en el patio", Icon = "⭐" },
				})
			end
		end,
		[math.floor(24 * FPS)] = function()
			local lifeGui = playerGui:FindFirstChild("LifeStory")
			table.insert(checks, { lifeGui ~= nil and lifeGui:FindFirstChild("Recap") == nil, "resumen al volver: no sale encima de una conversación" })
			localPlayer:SetAttribute("InDialogue", nil)
		end,
		[math.floor(26 * FPS)] = function()
			local lifeGui = playerGui:FindFirstChild("LifeStory")
			local recap = lifeGui and lifeGui:FindFirstChild("Recap")
			local texts = {}
			for _, d in (recap and recap:GetDescendants()) or {} do
				if rawget(d, "__class") == "TextLabel" then
					table.insert(texts, tostring(d.Text))
				end
			end
			local all = table.concat(texts, " | ")
			table.insert(checks, { all:find("Anteriormente", 1, true) ~= nil and all:find("El colegio", 1, true) ~= nil and all:find("Elegiste: Te sientas con Mateo", 1, true) ~= nil and all:find("La mochila perdida", 1, true) ~= nil,
				"resumen al volver: sale al acabar la conversación, con capítulo, lo último que pasó y lo que hacías" })
			if recap then
				recap.Activated:Fire() -- tocar para seguir
			end
		end,
		[math.floor(27 * FPS)] = function()
			local lifeGui = playerGui:FindFirstChild("LifeStory")
			table.insert(checks, { lifeGui ~= nil and lifeGui:FindFirstChild("Recap") == nil, "resumen al volver: se cierra al tocarlo" })
			-- Oferta con contexto: quién lo pide y por qué
			local story = remotes:FindFirstChild("LifeStory")
			if story then
				story.OnClientEvent:Fire("Offer", {
					QuestId = "Loco_N2_Bigotes", TitleKey = "Bigotes, emperador de Gatonia", TextKey = "¡Miau! (Bigotes te mira muy serio)",
					Description = "Unas cucarachas del espacio persiguen al gato del cole.", Icon = "🌀", Label = "Misión loca (con Cosme)", Asker = "Bigotes XVII",
				})
			end
		end,
		[math.floor(28 * FPS)] = function()
			local lifeGui = playerGui:FindFirstChild("LifeStory")
			local texts = {}
			for _, d in (lifeGui and lifeGui:GetDescendants()) or {} do
				if rawget(d, "__class") == "TextLabel" then
					table.insert(texts, tostring(d.Text))
				end
			end
			local all = table.concat(texts, " | ")
			table.insert(checks, { all:find("Te lo pide: Bigotes XVII", 1, true) ~= nil and all:find("cucarachas del espacio", 1, true) ~= nil and all:find("Misión loca", 1, true) ~= nil,
				"ofertas: dicen quién lo pide, por qué y qué tipo de misión es" })
			-- «Mi historia»
			local controllers = client:FindFirstChild("Controllers")
			local ok, Journal = pcall(requireFn, controllers and controllers:FindFirstChild("StoryJournal"))
			if ok and Journal then
				Journal.open("People")
				local story = remotes:FindFirstChild("LifeStory")
				if story then
					local people = {}
					for i = 1, 12 do
						table.insert(people, { Id = "P" .. i, Name = if i == 1 then "Mateo" else "Persona " .. i, Who = "El chico nuevo del barrio.", RelText = "😊 Buenos amigos" })
					end
					story.OnClientEvent:Fire("Journal", {
						Chapters = { { Id = "Nino_ElColegio", TitleKey = "CHAPTER.NINO.TITLE", IntroKey = "CHAPTER.NINO.INTRO", Current = true } },
						People = people,
						Memories = { { Key = "PrimerAmigo", Icon = "🤝", Text = "Tu primer amigo" } },
						Choices = {},
					})
				end
			else
				table.insert(checks, { false, "diario: no se pudo cargar StoryJournal" })
			end
		end,
		[math.floor(29 * FPS)] = function()
			local journal = playerGui:FindFirstChild("StoryJournal")
			local list = journal and journal:FindFirstChild("List", true)
			local texts = {}
			for _, d in (list and list:GetDescendants()) or {} do
				if rawget(d, "__class") == "TextLabel" then
					table.insert(texts, tostring(d.Text))
				end
			end
			local all = table.concat(texts, " | ")
			table.insert(checks, { journal ~= nil and journal.Enabled and all:find("Mateo", 1, true) ~= nil and all:find("Buenos amigos", 1, true) ~= nil,
				"diario «Mi historia»: la pestaña Personajes enseña a quien conoces y cómo os lleváis" })
			table.insert(checks, { list ~= nil and rawget(list, "__class") == "ScrollingFrame" and list.AutomaticCanvasSize == Enum.AutomaticSize.Y,
				"diario: la lista tiene scroll (para el móvil)" })
			local tab = journal and journal:FindFirstChild("TabChapters", true)
			if tab then
				tab.Activated:Fire()
			end
		end,
		[math.floor(30 * FPS)] = function()
			local journal = playerGui:FindFirstChild("StoryJournal")
			local list = journal and journal:FindFirstChild("List", true)
			local texts = {}
			for _, d in (list and list:GetDescendants()) or {} do
				if rawget(d, "__class") == "TextLabel" or rawget(d, "__class") == "TextButton" then
					table.insert(texts, tostring(d.Text))
				end
			end
			local all = table.concat(texts, " | ")
			table.insert(checks, { all:find("El colegio", 1, true) ~= nil and all:find("Volver a jugar el prólogo", 1, true) ~= nil,
				"diario: la pestaña Capítulos enseña el capítulo de ahora y deja volver a jugar el prólogo" })
			local controllers = client:FindFirstChild("Controllers")
			local ok, Journal = pcall(requireFn, controllers and controllers:FindFirstChild("StoryJournal"))
			if ok and Journal then
				Journal.close()
			end
		end,

		-- Viviendas (Controllers/HousingUI): el timbre y las llaves
		[math.floor(32 * FPS)] = function()
			local housing = remotes:FindFirstChild("Housing")
			if housing then
				housing.OnClientEvent:Fire("Doorbell", { Token = "b1", From = "Ana", Title = "Torre Norte · 3ºB" })
			end
		end,
		[math.floor(33 * FPS)] = function()
			local hg = playerGui:FindFirstChild("HousingGui")
			local card = hg and hg:FindFirstChild("Doorbell")
			local texts = {}
			for _, d in (card and card:GetDescendants()) or {} do
				if rawget(d, "__class") == "TextLabel" then
					table.insert(texts, tostring(d.Text))
				end
			end
			table.insert(checks, { card ~= nil and table.concat(texts, " "):find("Ana quiere entrar", 1, true) ~= nil, "timbre: sale el aviso de quién llama" })
			local open = card and card:FindFirstChild("Open", true)
			table.clear(serverLog)
			if open then
				open.Activated:Fire()
			end
			local sent = false
			for _, call in serverLog do
				if call.Remote == "Housing" and call.Args[1] == "Answer" and call.Args[2] == "b1" and call.Args[3] == true then
					sent = true
				end
			end
			table.insert(checks, { sent and hg:FindFirstChild("Doorbell") == nil, "timbre: «Abrir» contesta al servidor y el aviso se va" })
			local housing = remotes:FindFirstChild("Housing")
			if housing then
				housing.OnClientEvent:Fire("Keys", {
					Key = "Torre", Floor = 3, Letter = "B", Title = "Torre Norte · 3ºB", Id = "D01-E004-0302", Privacy = "Grupo",
					Keys = { { UserId = 7, Name = "Luis" } }, Players = { { UserId = 7, Name = "Luis" }, { UserId = 8, Name = "Marta" } }, Visitors = { { UserId = 8, Name = "Marta" } },
				})
			end
		end,
		[math.floor(34 * FPS)] = function()
			local hg = playerGui:FindFirstChild("HousingGui")
			local keys = hg and hg:FindFirstChild("HouseKeys")
			local texts = {}
			for _, d in (keys and keys:GetDescendants()) or {} do
				if rawget(d, "__class") == "TextLabel" or rawget(d, "__class") == "TextButton" then
					table.insert(texts, tostring(d.Text))
				end
			end
			local all = table.concat(texts, " | ")
			table.insert(checks, { all:find("D01-E004-0302", 1, true) ~= nil and all:find("🔑 Luis", 1, true) ~= nil and all:find("🙂 Marta", 1, true) ~= nil and all:find("👤 Marta", 1, true) ~= nil and all:find("👤 Luis", 1, true) == nil,
				"llaves: el panel enseña la vivienda, quién tiene llave, las visitas y a quién dársela (" .. all .. ")" })
		end,
		-- Encargos de los vecinos (Controllers/HousingUI): el aviso con «Aceptar» y el cartelito
		[math.floor(35 * FPS)] = function()
			local housing = remotes:FindFirstChild("Housing")
			if housing then
				housing.OnClientEvent:Fire("ErrandOffer", { Token = "e1", From = "Carmen García", Title = "Entrega en el 5ºB", Text = "Carmen García (3ºA): «¿Se lo subes tú?»", Money = 60, Xp = 20 })
			end
		end,
		[math.floor(36 * FPS)] = function()
			local hg = playerGui:FindFirstChild("HousingGui")
			local card = hg and hg:FindFirstChild("ErrandOffer")
			local texts = {}
			for _, d in (card and card:GetDescendants()) or {} do
				if rawget(d, "__class") == "TextLabel" then
					table.insert(texts, tostring(d.Text))
				end
			end
			local all = table.concat(texts, " | ")
			table.insert(checks, { card ~= nil and all:find("Entrega en el 5ºB", 1, true) ~= nil and all:find("Recompensa", 1, true) ~= nil, "encargo: sale el favor que te piden y la recompensa (" .. all .. ")" })
			local accept = card and card:FindFirstChild("Accept", true)
			table.clear(serverLog)
			if accept then
				accept.Activated:Fire()
			end
			local sent = false
			for _, call in serverLog do
				if call.Remote == "Housing" and call.Args[1] == "ErrandAnswer" and call.Args[2] == "e1" and call.Args[3] == true then
					sent = true
				end
			end
			table.insert(checks, { sent and hg:FindFirstChild("ErrandOffer") == nil, "encargo: «Aceptar» contesta al servidor y el aviso se va" })
			local housing = remotes:FindFirstChild("Housing")
			if housing then
				housing.OnClientEvent:Fire("Errand", { Title = "Entrega en el 5ºB", Goal = "📦 Recoge el paquete en los buzones del portal." })
			end
		end,
		[math.floor(37 * FPS)] = function()
			local hg = playerGui:FindFirstChild("HousingGui")
			local tracker = hg and hg:FindFirstChild("ErrandTracker")
			local goal = tracker and tracker:FindFirstChild("Goal", true)
			table.insert(checks, { goal ~= nil and tostring(goal.Text):find("buzones", 1, true) ~= nil, "encargo: el cartelito dice lo que toca" })
			local housing = remotes:FindFirstChild("Housing")
			if housing then
				housing.OnClientEvent:Fire("Errand", { Done = true })
			end
		end,
		[math.floor(38 * FPS)] = function()
			local hg = playerGui:FindFirstChild("HousingGui")
			table.insert(checks, { hg ~= nil and hg:FindFirstChild("ErrandTracker") == nil, "encargo: al acabar, el cartelito se quita" })
		end,
		-- Sin menú rápido junto al minimapa ni menú COMANDOS: todo son apps del ValPhone; y «Modo
		-- pruebas» solo sale con el atributo Tester
		[math.floor(38.4 * FPS)] = function()
			local popups = playerGui:FindFirstChild("HudPopups")
			table.insert(checks, { popups ~= nil and popups:FindFirstChild("Phone") == nil and popups:FindFirstChild("PhoneButton") == nil, "HUD: ya no hay menú rápido junto al minimapa" })
			table.insert(checks, { playerGui:FindFirstChild("CommandMenuGui") == nil and playerGui:FindFirstChild("PhoneGui") ~= nil and playerGui:FindFirstChild("ContextStripGui") ~= nil, "HUD: sin el panel COMANDOS; en su lugar el ValPhone y la tira de acciones" })
			local labels = rowLabels()
			table.insert(checks, { labels["Ir a casa"] and labels["Tienda"] and labels["Vehículos"] and labels["Gestos"] and labels["Ruta a casa"], "ValPhone: las apps de siempre (Ir a casa, Ruta a casa, Tienda, Vehículos, Gestos…)" })
			-- Todo lo que había en COMANDOS (menos lo de ahora, que va en la tira) es una app
			local missing = {}
			for _, id in { "Mapa", "Objetos", "AppIr a casa", "AppRuta a casa", "AppTienda", "AppVehículos", "AppGestos", "AppMetro", "AppMercadillo", "AppGuía de pesca", "Misiones", "Historia", "Personaje", "Viviendas", "Carrera", "Controles", "Menu", "Mensajes", "Cartera", "Ayuda" } do
				if not labels[id] then
					table.insert(missing, id)
				end
			end
			table.insert(checks, { #missing == 0, "ValPhone: todo lo de COMANDOS es una app (Mapa, Mochila, Metro, Mercadillo, Pesca, Misiones, Mi historia, Personaje, Viviendas, Carrera, Controles, Ajustes…) y además Mensajes, Cartera y Ayuda" .. (if #missing > 0 then ": faltan " .. table.concat(missing, ", ") else "") })
			table.insert(checks, { not labels["Modo pruebas"] and not labels.ModoPruebas, "ValPhone: sin el atributo Tester no sale «Modo pruebas»" })
			-- Pase de temporada apagado (BattlePassConfig.Enabled = false): ni app, ni ventana, ni remoto
			local bpRemote = remotes:FindFirstChild("BattlePass")
			local dialogs = playerGui:FindFirstChild("Dialogs")
			-- (ya encendido para todos: BattlePassConfig.Enabled = true; entonces sale su app)
			local bpOn = BP_ON
			if bpOn then
				-- (la app sale cuando el servidor manda el estado de la temporada, que aquí no hay: eso lo
				-- prueba test-battlepassui. Aquí: sin estado, ni app ni ventana abierta sola)
				table.insert(checks, { not labels.PaseTemporada and (dialogs == nil or dialogs:FindFirstChild("BattlePass") == nil or not dialogs.BattlePass.Visible), "pase de temporada encendido: sin estado del servidor, ni app «Pase» ni ventana abierta (la app la prueba test-battlepassui)" })
			else
				table.insert(checks, { not labels.PaseTemporada and bpRemote == nil and (dialogs == nil or dialogs:FindFirstChild("BattlePass") == nil) and playerGui:FindFirstChild("BattlePassTip") == nil, "pase de temporada apagado: sin app «Pase», sin ventana y sin remoto" })
			end
			localPlayer:SetAttribute("Tester", true)
			-- «📱 Abu Rosa quiere hablar contigo»: llega al ValPhone como mensaje
			local story = remotes:FindFirstChild("LifeStory")
			if story then
				story.OnClientEvent:Fire("Ping", { Icon = "📱", Text = "📱 Abu Rosa quiere hablar contigo — bájate para hablar", Reason = "Ride", QuestId = "Q" })
			end
		end,
		[math.floor(39 * FPS)] = function()
			table.insert(checks, { rowLabels()["Modo pruebas"] == true, "ValPhone: con Tester = true sale la app «Modo pruebas»" })
			local phone = playerGui:FindFirstChild("PhoneGui")
			local banner = phone and phone:FindFirstChild("PhoneBanner")
			local said = false
			for _, d in (banner and banner:GetDescendants()) or {} do
				if rawget(d, "__class") == "TextLabel" and tostring(d.Text):find("Abu Rosa quiere hablar contigo", 1, true) then
					said = true
				end
			end
			local lifeGui = playerGui:FindFirstChild("LifeStory")
			table.insert(checks, { banner ~= nil and banner.Visible and said and (lifeGui == nil or lifeGui:FindFirstChild("StoryPing") == nil), "ValPhone: «📱 Abu Rosa quiere hablar contigo» baja como notificación del teléfono (y queda en Mensajes)" })
			localPlayer:SetAttribute("Tester", nil)
			-- Móvil: la pestaña «Tu vida» se aparta mientras se ve la tarjeta de la misión
			local hud = playerGui:FindFirstChild("MainHud")
			local mission = hud and hud:FindFirstChild("Mission")
			local tab = playerGui:FindFirstChild("LifeStoryTab", true)
			table.insert(checks, { not mode.Touch or not (mission and mission.Visible) or not (tab and tab.Visible), "móvil: con la misión a la vista, la pestaña «Tu vida» se aparta" })
		end,
		-- Ordenador: al volante, W acelera y A / D giran (teclado; sin botones en pantalla)
		[math.floor(40.2 * FPS)] = function()
			if mode.Touch then
				return
			end
			local character = localPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not humanoid then
				table.insert(checks, { false, "ordenador al volante: falta el personaje" })
				return
			end
			local ground = new("Part", "Suelo")
			ground.Parent = workspace
			fn(workspace, "Raycast", function(_, origin, direction)
				if direction.Y < -0.5 and origin.Y >= 0 and origin.Y + direction.Y <= 0 then
					local t = origin.Y / -direction.Y
					return { Instance = ground, Position = origin + direction * t, Normal = V3.yAxis, Material = Enum.Material.Asphalt, Distance = direction.Magnitude * t }
				end
				return nil
			end)
			local held: { [any]: boolean } = {}
			fn(uis, "IsKeyDown", function(_, key)
				return held[key.Name] == true
			end)
			local function wait(seconds: number)
				for _ = 1, math.ceil(seconds / 0.05) do
					fakeTask.wait(0.05)
				end
			end
			local function yawOf(cf: any): number
				local look = cf.LookVector
				return math.atan2(-look.X, -look.Z)
			end
			local vehicle = new("Model", "Coche")
			vehicle:SetAttribute("Drivable", true)
			vehicle:SetAttribute("Kind", "Coche")
			local chassis = new("Part", "Chassis")
			rawget(chassis, "__props").Size = V3.new(6.4, 2, 13.6)
			rawget(chassis, "__props").CFrame = CF.new(0, 1, 0)
			rawget(chassis, "__props").Anchored = false
			chassis.Parent = vehicle
			rawget(vehicle, "__props").PrimaryPart = chassis
			local seat = new("VehicleSeat", "DriverSeat")
			seat.Parent = vehicle
			vehicle.Parent = workspace
			local hp = rawget(humanoid, "__props")
			hp.SeatPart = seat
			hp.Sit = true
			signalOf(humanoid, "Seated"):Fire(true, seat)
			wait(0.5)
			local from = chassis.CFrame.Position
			held["W"] = true
			wait(1.5)
			local ahead = (chassis.CFrame.Position - from):Dot(chassis.CFrame.LookVector)
			table.insert(checks, { ahead > 3, ("ordenador al volante: W arranca hacia delante (%.1f studs)"):format(ahead) })
			local yaw0 = yawOf(chassis.CFrame)
			held["D"] = true
			wait(1)
			local right = yawOf(chassis.CFrame) - yaw0
			held["D"] = nil
			held["A"] = true
			local yaw1 = yawOf(chassis.CFrame)
			wait(1)
			local left = yawOf(chassis.CFrame) - yaw1
			held = {}
			table.insert(checks, { right < -0.2 and left > 0.2, ("ordenador al volante: D gira a la derecha (%.2f rad) y A a la izquierda (%.2f rad)"):format(right, left) })
			hp.SeatPart = nil
			hp.Sit = false
			signalOf(humanoid, "Seated"):Fire(false, nil)
			wait(0.3)
			vehicle.Parent = nil
			fn(uis, "IsKeyDown", function()
				return false
			end)
			fn(workspace, "Raycast", function()
				return nil
			end)
			ground.Parent = nil
		end,
		-- Móvil: el botón «Agacharse» (el de verdad: TouchLayout → Controllers/Stances). Tocarlo agacha y
		-- volver a tocarlo levanta, sin arma y con el revólver en la mano; solo hay UN botón así y el
		-- cuerpo baja de verdad (con las articulaciones nuevas de Roblox del personaje de móvil)
		[math.floor(40.5 * FPS)] = function()
			if not mode.Touch then
				return
			end
			local controllersF = client:FindFirstChild("Controllers")
			local okLayers, Layers = pcall(requireFn, controllersF and controllersF:FindFirstChild("PoseLayers"))
			local character = localPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local knee = character and character:FindFirstChild("RightKnee", true)
			local CAPTIONS = { Agacharse = true, Agachado = true, Tumbado = true }
			local function crouchButtons(): { any }
				local out = {}
				local touchGui = playerGui:FindFirstChild("TouchLayout")
				for _, b in (touchGui and touchGui:GetChildren()) or {} do
					local caption = b:FindFirstChild("Caption")
					if b.Visible and caption and CAPTIONS[tostring(caption.Text)] then
						table.insert(out, b)
					end
				end
				return out
			end
			-- Pasa el tiempo con las capas de postura (PoseLayers no arranca solo fuera de Roblox)
			local function run(seconds: number)
				for _ = 1, math.ceil(seconds / 0.05) do
					fakeTask.wait(0.05)
					if okLayers then
						Layers.step(0.05, now)
					end
				end
			end
			-- Un toque con el dedo, como en el móvil
			local function tap(button: any)
				local input = new("InputObject", "InputObject")
				rawget(input, "__props").UserInputType = Enum.UserInputType.Touch
				rawget(input, "__props").UserInputState = Enum.UserInputState.Begin
				signalOf(button, "InputBegan"):Fire(input)
				fakeTask.wait(0.1)
				rawget(input, "__props").UserInputState = Enum.UserInputState.End
				signalOf(button, "InputEnded"):Fire(input)
				signalOf(uis, "InputEnded"):Fire(input, true)
				signalOf(button, "Activated"):Fire(input, 1)
				run(0.6)
			end
			local function sentStance(): string?
				local last = nil
				for _, call in serverLog do
					if call.Remote == "Actions" and call.Args[1] == "Stance" then
						last = call.Args[2]
					end
				end
				return last
			end
			local function probe(tag: string)
				local list = crouchButtons()
				table.insert(checks, { #list == 1 and list[1].Name == "Agacharse", ("móvil %s: hay un solo botón «Agacharse» y es el de Stances (%d)"):format(tag, #list) })
				if #list ~= 1 or not humanoid then
					return
				end
				local standHip = humanoid.HipHeight
				table.clear(serverLog)
				tap(list[1])
				local crouchedHip = humanoid.HipHeight
				local bent = knee ~= nil and select(1, knee.Transform:ToEulerAnglesXYZ()) < -0.3
				table.insert(checks, { localPlayer:GetAttribute("StanceLocal") == "Crouch" and sentStance() == "Crouch",
					("móvil %s: tocar «Agacharse» agacha (%s) y se lo dice al servidor (%s)"):format(tag, tostring(localPlayer:GetAttribute("StanceLocal")), tostring(sentStance())) })
				table.insert(checks, { crouchedHip < standHip - 0.2 and bent,
					("móvil %s: el cuerpo baja de verdad (cadera %.2f → %.2f) y dobla las rodillas (%s)"):format(tag, standHip, crouchedHip, tostring(bent)) })
				local again = crouchButtons()
				table.insert(checks, { #again == 1 and tostring(again[1]:FindFirstChild("Caption").Text) == "Agachado", ("móvil %s: agachado, el botón dice «Agachado» (sigue siendo uno)"):format(tag) })
				if #again == 1 then
					tap(again[1])
				end
				table.insert(checks, { localPlayer:GetAttribute("StanceLocal") == "Stand" and sentStance() == "Stand" and math.abs(humanoid.HipHeight - standHip) < 0.01,
					("móvil %s: tocarlo otra vez te levanta (%s, cadera %.2f)"):format(tag, tostring(localPlayer:GetAttribute("StanceLocal")), humanoid.HipHeight) })
			end
			probe("sin arma")
			localPlayer:SetAttribute("Weapon", "Revolver")
			fakeTask.wait(1)
			local touchGui = playerGui:FindFirstChild("TouchLayout")
			local shoot = touchGui and touchGui:FindFirstChild("Disparar")
			table.insert(checks, { shoot ~= nil and shoot.Visible, "móvil con el revólver: salen los botones del arma (Disparar)" })
			probe("con el revólver")
			localPlayer:SetAttribute("Weapon", nil)
			-- Al volante de un coche (articulaciones nuevas de Roblox, AnimationConstraint): RidePose pone
			-- las manos en el volante escribiendo Transform en esas articulaciones (antes solo buscaba
			-- Motor6D y se iba sentado sin postura)
			local shoulder = character and character:FindFirstChild("RightShoulder", true)
			if not (okLayers and humanoid and shoulder) then
				table.insert(checks, { false, "móvil al volante: falta el personaje o PoseLayers" })
				return
			end
			local car = new("Model", "Coche")
			car:SetAttribute("Drivable", true)
			car:SetAttribute("Kind", "Coche")
			local seat = new("VehicleSeat", "DriverSeat")
			seat.Parent = car
			car.Parent = workspace
			local hp = rawget(humanoid, "__props")
			hp.SeatPart = seat
			hp.Sit = true
			local worst = 0
			-- (RidePose solo mira a quien está cerca de la cámara: aquí la cámara de mentira se queda lejos)
			local camera = workspace.CurrentCamera
			local root = character:FindFirstChild("HumanoidRootPart")
			for _ = 1, 24 do
				if camera and root then
					rawget(camera, "__props").CFrame = root.CFrame * CF.new(0, 5, 12)
				end
				fakeTask.wait(0.05)
				Layers.step(0.05, now)
				local rx = select(1, shoulder.Transform:ToEulerAnglesXYZ())
				worst = math.max(worst, math.abs(rx))
			end
			table.insert(checks, { shoulder.ClassName == "AnimationConstraint" and worst > 0.3,
				("móvil al volante: con AnimationConstraint las manos van al volante (hombro %.2f rad)"):format(worst) })
			hp.SeatPart = nil
			hp.Sit = false
			car.Parent = nil
			for _ = 1, 10 do
				fakeTask.wait(0.05)
				Layers.step(0.05, now)
			end
			-- Al volante en el móvil, en CADA vehículo que se conduce: salen las flechas y los pedales
			-- (y el joystick solo se esconde si salen); ACELERAR anda, ▶ / ◀ giran, y al bajarse
			-- vuelve el joystick (Controllers/Driving + UI/DriveButtons + UI/TouchLayout)
			do
				local touchGui = playerGui:FindFirstChild("TouchLayout")
				local stickGui = playerGui:FindFirstChild("JoystickGui")
				local stick = stickGui and stickGui:FindFirstChild("Joystick")
				-- Suelo plano a y = 0 (los rayos hacia abajo dan en él)
				local ground = new("Part", "Suelo")
				ground.Parent = workspace
				fn(workspace, "Raycast", function(_, origin, direction)
					if direction.Y < -0.5 and origin.Y >= 0 and origin.Y + direction.Y <= 0 then
						local t = origin.Y / -direction.Y
						return { Instance = ground, Position = origin + direction * t, Normal = V3.yAxis, Material = Enum.Material.Asphalt, Distance = direction.Magnitude * t }
					end
					return nil
				end)
				local function shown(id: string): boolean
					local b = touchGui and touchGui:FindFirstChild(id)
					return b ~= nil and b.Visible == true
				end
				local function hold(id: string, down: boolean, input: any?): any
					local b = touchGui and touchGui:FindFirstChild(id)
					if not b then
						return nil
					end
					local i = input or new("InputObject", "InputObject")
					rawget(i, "__props").UserInputType = Enum.UserInputType.Touch
					if down then
						rawget(i, "__props").UserInputState = Enum.UserInputState.Begin
						signalOf(b, "InputBegan"):Fire(i)
					else
						rawget(i, "__props").UserInputState = Enum.UserInputState.End
						signalOf(b, "InputEnded"):Fire(i)
						signalOf(uis, "InputEnded"):Fire(i, true)
					end
					return i
				end
				local function yawOf(cf: any): number
					local look = cf.LookVector
					return math.atan2(-look.X, -look.Z)
				end
				local sizes = { Coche = V3.new(6.4, 2, 13.6), Patrulla = V3.new(6.4, 2, 13.6), Moto = V3.new(2.6, 2, 5.8), Bici = V3.new(2, 2, 5), Patinete = V3.new(1.6, 1, 4), Monopatin = V3.new(1.6, 0.6, 3.4), Autobus = V3.new(11, 3, 34), Camion = V3.new(9, 3, 26), Bomberos = V3.new(9, 3, 28) }
				local seatedSignal = signalOf(humanoid, "Seated")
				for _, kind in { "Coche", "Moto", "Bici", "Patinete", "Monopatin", "Patrulla", "Autobus", "Camion", "Bomberos" } do
					local vehicle = new("Model", kind)
					vehicle:SetAttribute("Drivable", true)
					vehicle:SetAttribute("Kind", kind)
					local chassis = new("Part", "Chassis")
					rawget(chassis, "__props").Size = sizes[kind]
					rawget(chassis, "__props").CFrame = CF.new(0, sizes[kind].Y / 2, 0)
					rawget(chassis, "__props").Anchored = false
					chassis.Parent = vehicle
					rawget(vehicle, "__props").PrimaryPart = chassis
					local driverSeat = new("VehicleSeat", "DriverSeat")
					driverSeat.Parent = vehicle
					vehicle.Parent = workspace
					hp.SeatPart = driverSeat
					hp.Sit = true
					seatedSignal:Fire(true, driverSeat)
					run(0.6)
					local arrows = shown("GiroIzq") and shown("GiroDer")
					local pedals = shown("Acelerar") and shown("Frenar")
					table.insert(checks, { arrows and pedals, ("móvil al volante (%s): salen las flechas ◀ ▶ y los pedales ACELERAR / FRENO (%s, %s)"):format(kind, tostring(arrows), tostring(pedals)) })
					table.insert(checks, { stick ~= nil and stick.Visible == not (arrows and pedals), ("móvil al volante (%s): el joystick solo se esconde si salen los mandos (joystick %s)"):format(kind, tostring(stick and stick.Visible)) })
					-- Parado: ACELERAR anda hacia delante
					local startPos = chassis.CFrame.Position
					local startYaw = yawOf(chassis.CFrame)
					local gas = hold("Acelerar", true)
					run(1.5)
					local moved = (chassis.CFrame.Position - startPos)
					local ahead = moved:Dot(startPos + chassis.CFrame.LookVector - startPos)
					table.insert(checks, { ahead > 3, ("móvil al volante (%s): mantener ACELERAR parado arranca hacia delante (%.1f studs)"):format(kind, ahead) })
					-- Acelerando y manteniendo ▶: gira a la derecha (dos dedos a la vez)
					local right = hold("GiroDer", true)
					run(1)
					local turned = yawOf(chassis.CFrame) - startYaw
					table.insert(checks, { turned < -0.2, ("móvil al volante (%s): con ACELERAR y ▶ a la vez gira a la derecha (%.2f rad)"):format(kind, turned) })
					hold("GiroDer", false, right)
					hold("Acelerar", false, gas)
					-- Despacio, ◀ también gira
					local yaw0 = yawOf(chassis.CFrame)
					local left = hold("GiroIzq", true)
					run(0.8)
					local turnedLeft = yawOf(chassis.CFrame) - yaw0
					table.insert(checks, { turnedLeft > 0.02, ("móvil al volante (%s): soltando el pedal (despacio), ◀ gira a la izquierda (%.2f rad)"):format(kind, turnedLeft) })
					hold("GiroIzq", false, left)
					-- Bajarse: fuera los mandos y vuelve el joystick
					hp.SeatPart = nil
					hp.Sit = false
					seatedSignal:Fire(false, nil)
					run(0.6)
					table.insert(checks, { not shown("Acelerar") and not shown("GiroIzq") and stick ~= nil and stick.Visible, ("móvil (%s): al bajarse se quitan los mandos y vuelve el joystick"):format(kind) })
					-- Si las flechas no salen (lo que sea que falle), el joystick NO se esconde y conduce
					if kind == "Coche" and stick then
						local uiF = client:FindFirstChild("UI")
						local okTL, TL = pcall(requireFn, uiF and uiF:FindFirstChild("TouchLayout"))
						local saved = if okTL then { TL._spec("GiroIzq"), TL._spec("GiroDer") } else {}
						if okTL then
							TL.unregister("GiroIzq")
							TL.unregister("GiroDer")
						end
						hp.SeatPart = driverSeat
						hp.Sit = true
						seatedSignal:Fire(true, driverSeat)
						run(0.6)
						table.insert(checks, { okTL and not shown("GiroIzq") and stick.Visible, ("móvil al volante (%s) sin flechas en pantalla: el joystick sigue a la vista (%s)"):format(kind, tostring(stick.Visible)) })
						local from = chassis.CFrame.Position
						local finger = new("InputObject", "InputObject")
						rawget(finger, "__props").UserInputType = Enum.UserInputType.Touch
						rawget(finger, "__props").UserInputState = Enum.UserInputState.Begin
						local centre = stick.AbsolutePosition + stick.AbsoluteSize / 2
						rawget(finger, "__props").Position = V3.new(centre.X + 30, centre.Y - 60, 0)
						signalOf(stick, "InputBegan"):Fire(finger)
						run(1.5)
						local went = (chassis.CFrame.Position - from).Magnitude
						rawget(finger, "__props").UserInputState = Enum.UserInputState.End
						signalOf(uis, "InputEnded"):Fire(finger, false)
						table.insert(checks, { went > 3, ("móvil al volante (%s) sin flechas: el joystick hace andar el vehículo (%.1f studs)"):format(kind, went) })
						for _, spec in saved do
							TL.register(spec)
						end
						run(0.6)
						table.insert(checks, { shown("GiroIzq") and not stick.Visible, ("móvil al volante (%s): al volver las flechas, el joystick se vuelve a esconder"):format(kind) })
						hp.SeatPart = nil
						hp.Sit = false
						seatedSignal:Fire(false, nil)
						run(0.6)
					end
					vehicle.Parent = nil
				end
				fn(workspace, "Raycast", function()
					return nil
				end)
				ground.Parent = nil
			end
		end,
		[math.floor(39.6 * FPS)] = function()
			table.insert(checks, { not rowLabels()["Modo pruebas"], "ValPhone: al quitar Tester, «Modo pruebas» se va" })
		end,
	}
	for frame = 1, frames do
		now += dt
		rawget(workspace, "__props").DistributedGameTime = now
		if events[frame] then
			fakeTask.spawn(events[frame])
		end
		local queue = deferred
		deferred = {}
		for _, d in queue do
			resume(d.Thread, d.Where, table.unpack(d.Args, 1, d.Args.n))
		end
		for _, name in { "PreRender", "RenderStepped", "PreAnimation", "Stepped", "PreSimulation", "PostSimulation", "Heartbeat" } do
			local s = rawget(runService, "__signals")[name]
			if s then
				if name == "Stepped" then
					s:Fire(now, dt)
				else
					s:Fire(dt)
				end
			end
		end
		for name, f in table.clone(renderSteps) do
			fakeTask.spawn(f, dt)
		end
		local due = {}
		local keep = {}
		for _, entry in sleeping do
			if entry.At <= now then
				table.insert(due, entry)
			else
				table.insert(keep, entry)
			end
		end
		sleeping = keep
		table.sort(due, function(x, y)
			return x.At < y.At
		end)
		for _, entry in due do
			if entry.Args then
				resume(entry.Thread, entry.Where, table.unpack(entry.Args, 1, entry.Args.n))
			else
				resume(entry.Thread, entry.Where, now - ((entry :: any).Start or now), now)
			end
		end
		if realClock() - realStart > REAL_BUDGET then
			table.insert(placeholders, ("(se acabó el tiempo real a los %.1f s simulados)"):format(now))
			break
		end
	end

	if not mainDone and #errors == 0 then
		report("Main.client", "Main.client no llega al final (se queda esperando algo)", mainThread)
	end

	-- Cada módulo que Main no haya cargado: que al menos cargue
	local extra = 0
	local function requireAll(folder: any)
		for _, child in folder:GetDescendants() do
			if rawget(child, "__class") == "ModuleScript" and rawget(child, "__file") and not loaded[rawget(child, "__file")] then
				extra += 1
				fakeTask.spawn(function()
					pcall(requireFn, child)
				end)
			end
		end
	end
	requireAll(client)
	requireAll(replicated:FindFirstChild("Shared"))

	-- ¿Se ve la interfaz?
	local screens = {}
	for _, child in playerGui:GetChildren() do
		if rawget(child, "__class") == "ScreenGui" then
			table.insert(screens, child.Name)
		end
	end
	local modulesLoaded = 0
	for _ in loaded do
		modulesLoaded += 1
	end
	return {
		Errors = errors,
		Warnings = warnings,
		Placeholders = placeholders,
		OddWrites = oddWrites,
		Screens = screens,
		Modules = modulesLoaded,
		Extra = extra,
		Simulated = now,
		Real = realClock() - realStart,
		Checks = checks,
	}
end

---------------------------------------------------------------------
-- Informe
---------------------------------------------------------------------
local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

for _, mode in {
	{ Name = "ordenador (1920x1080, teclado)", Viewport = V2.new(1920, 1080), Touch = false },
	{ Name = "móvil (844x390, táctil)", Viewport = V2.new(844, 390), Touch = true },
} do
	print(("\n▶ Arranque en %s"):format(mode.Name))
	local result = boot(mode)
	print(("  %d módulos cargados (%d más cargados aparte), %.0f s simulados en %.1f s"):format(result.Modules, result.Extra, result.Simulated, result.Real))
	for _, e in result.Errors do
		print(("  ❌ [%s] %s"):format(e.Where, e.Message))
		local shown = 0
		for line in string.gmatch(e.Trace, "[^\n]+") do
			if string.find(line, "src/", 1, true) and not string.find(line, "scripts/", 1, true) and shown < 6 then
				shown += 1
				print("       " .. line)
			end
		end
	end
	check(#result.Errors == 0, ("ningún error al cargar, iniciar ni en los primeros %d s de juego"):format(SIM_SECONDS))
	local hasHud = table.find(result.Screens, "MainHud") ~= nil
	check(#result.Screens >= 10 and hasHud, ("la interfaz aparece (%d pantallas: %s…)"):format(#result.Screens, table.concat(result.Screens, ", ", 1, math.min(6, #result.Screens))))
	for _, c in result.Checks do
		check(c[1], c[2])
	end
	if #result.Placeholders > 0 then
		print("  ℹ️  Esperas que en Roblox no acabarían aquí (se usó un sustituto):")
		for _, p in result.Placeholders do
			print("       " .. p)
		end
	end
	local warnList = {}
	for line, count in result.Warnings do
		table.insert(warnList, ("%s%s"):format(line, if count > 1 then (" (x%d)"):format(count) else ""))
	end
	table.sort(warnList)
	if #warnList > 0 then
		print(("  ℹ️  Avisos (warn) del juego: %d distintos"):format(#warnList))
		for i = 1, math.min(15, #warnList) do
			print("       " .. string.sub(warnList[i], 1, 200))
		end
	end
	local odd = {}
	for key in result.OddWrites do
		table.insert(odd, key)
	end
	table.sort(odd)
	if #odd > 0 then
		print("  ℹ️  Propiedades que no están en la API conocida (revisar si son nuevas o erratas): " .. table.concat(odd, ", "))
	end
end

print("")
if failures > 0 then
	print(("❌ %d comprobaciones fallan"):format(failures))
	process.exit(1)
end
print("✅ El cliente arranca bien (ordenador y móvil)")
process.exit(0)
