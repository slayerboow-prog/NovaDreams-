-- Prueba de la interfaz del PASE DE TEMPORADA FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-battlepassui.luau
--
-- Monta UI/BattlePassUI (con UI/Dialog, UI/Theme y Controllers/BattlePassClient de verdad) en un
-- Roblox de mentira en el que cada propiedad que se escribe se comprueba contra la API de Roblox, y le
-- manda estados del servidor de mentira con la forma del contrato (docs/pase-de-temporada.md §12),
-- hechos con las recompensas de verdad de la temporada 1. Comprueba que:
--   * con BattlePassConfig.Enabled = false no aparece NADA (ni fila, ni ventana, ni tecla, ni peticiones)
--   * encendido: la fila «🏆 Pase de temporada» sale como app del ValPhone solo con la temporada en marcha, con el
--     punto rojo si hay algo que reclamar; y la ventana se abre desde ella y con la tecla N
--   * cabecera (temporada, nivel, XP, días), fila 01…50, estados BLOQUEADA / DISPONIBLE / RECLAMADA /
--     PREMIUM BLOQUEADA, rareza con su color, la actual y la siguiente resaltadas
--   * RECLAMAR, RECLAMAR TODO, EQUIPAR, Comprar, SEGUIR, CAMBIAR, la decisión de la historia y CANJEAR
--     mandan la petición correcta al servidor (y nada más: no se repiten mientras contesta)
--   * la oferta del premium sin presión y «Próximamente» sin Game Pass; vista previa 3D y sus reservas
--   * el aviso discreto «RECOMPENSA DESBLOQUEADA» y el tooltip del ordenador
--   * NADA se pisa ni se sale de la pantalla (1920x1080, 1600x900, 1366x768, 1280x720 y móviles
--     640x360, 667x375, 844x390, 932x430, 1024x768, 2400x1080), el texto se lee y los botones son cómodos


local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local db = roblox.getReflectionDatabase()

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

---------------------------------------------------------------------
-- Señales y objetos de mentira
---------------------------------------------------------------------
local function signal()
	local handlers = {}
	local self = {}
	function self:Connect(fn)
		table.insert(handlers, fn)
		return {
			Disconnect = function()
				local i = table.find(handlers, fn)
				if i then
					table.remove(handlers, i)
				end
			end,
		}
	end
	function self:Once(fn)
		return self:Connect(fn)
	end
	function self:Wait() end
	function self:Fire(...)
		for _, fn in table.clone(handlers) do
			fn(...)
		end
	end
	return self
end

local function hasProperty(className: string, name: string): boolean
	local class = db:GetClass(className)
	while class do
		if class.Properties[name] ~= nil then
			return true
		end
		class = class.Superclass and db:GetClass(class.Superclass)
	end
	return false
end

local function isA(className: string, other: string): boolean
	local class = db:GetClass(className)
	while class do
		if class.Name == other then
			return true
		end
		class = class.Superclass and db:GetClass(class.Superclass)
	end
	return false
end

local badWrites: { string } = {}
local Instance = {}
local instanceMeta = {}

local function newInstance(className: string): any
	assert(db:GetClass(className), "Clase desconocida: " .. className)
	local data = {
		__class = className,
		__props = { Name = className, Visible = true, ZIndex = 1 },
		__children = {},
		__attributes = {},
		__signals = {},
		__attrSignals = {},
		__propSignals = {},
	}
	return setmetatable(data, instanceMeta)
end
Instance.new = newInstance

local methods = {}
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
function methods:FindFirstChild(name)
	for _, child in rawget(self, "__children") do
		if child.Name == name then
			return child
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
function methods:FindFirstChildWhichIsA(className)
	for _, child in rawget(self, "__children") do
		if isA(rawget(child, "__class"), className) then
			return child
		end
	end
	return nil
end
function methods:WaitForChild(name)
	return self:FindFirstChild(name) or error("WaitForChild se quedaría esperando: " .. tostring(name))
end
function methods:IsA(className)
	return isA(rawget(self, "__class"), className)
end
function methods:IsDescendantOf(other)
	local parent = self.Parent
	while parent do
		if parent == other then
			return true
		end
		parent = parent.Parent
	end
	return false
end
function methods:Destroy()
	self.Parent = nil
	for _, child in rawget(self, "__children") do
		child:Destroy()
	end
end
function methods:ClearAllChildren()
	for _, child in rawget(self, "__children") do
		child:Destroy()
	end
end
function methods:GetAttribute(name)
	return rawget(self, "__attributes")[name]
end
function methods:SetAttribute(name, value)
	rawget(self, "__attributes")[name] = value
	local s = rawget(self, "__attrSignals")[name]
	if s then
		s:Fire()
	end
end
function methods:GetAttributeChangedSignal(name)
	local signals = rawget(self, "__attrSignals")
	signals[name] = signals[name] or signal()
	return signals[name]
end
function methods:GetPropertyChangedSignal(name)
	local signals = rawget(self, "__propSignals")
	signals[name] = signals[name] or signal()
	return signals[name]
end
function methods:FireServer(...) end

instanceMeta.__index = function(self, key)
	if methods[key] then
		return methods[key]
	end
	local props = rawget(self, "__props")
	if props[key] ~= nil then
		return props[key]
	end
	if key == "ClassName" then
		return rawget(self, "__class")
	end
	if key == "Parent" then
		return nil
	end
	-- Un hijo por su nombre (como en Roblox: gui.Status)
	if typeof(key) == "string" and not hasProperty(rawget(self, "__class"), key) then
		for _, child in rawget(self, "__children") do
			if rawget(child, "__props").Name == key then
				return child
			end
		end
	end
	-- Un evento (Activated, MouseEnter, HealthChanged, OnClientEvent…): empieza con mayúscula y
	-- no es una propiedad
	if typeof(key) == "string" and not hasProperty(rawget(self, "__class"), key) then
		local signals = rawget(self, "__signals")
		signals[key] = signals[key] or signal()
		return signals[key]
	end
	return nil
end
instanceMeta.__newindex = function(self, key, value)
	local className = rawget(self, "__class")
	if key ~= "Parent" and key ~= "Name" and not hasProperty(className, key) then
		table.insert(badWrites, ("%s.%s"):format(className, tostring(key)))
		return
	end
	local props = rawget(self, "__props")
	if key == "Parent" then
		local old = props.Parent
		if old then
			local list = rawget(old, "__children")
			local i = table.find(list, self)
			if i then
				table.remove(list, i)
			end
		end
		if value then
			table.insert(rawget(value, "__children"), self)
		end
	end
	props[key] = value
	local s = rawget(self, "__propSignals")[key]
	if s then
		s:Fire()
	end
end
instanceMeta.__tostring = function(self)
	return rawget(self, "__props").Name
end

local function find(root, path: string)
	local current = root
	for part in path:gmatch("[^/]+") do
		current = current and current:FindFirstChild(part)
	end
	return current
end


---------------------------------------------------------------------
-- Servicios
---------------------------------------------------------------------
local function service(className: string, extra: { [string]: any }?)
	local object = newInstance(className)
	for key, value in extra or {} do
		rawget(object, "__props")[key] = value
	end
	return object
end

local TweenInfo = { new = function(...)
	return { ... }
end }
local tweenService = service("TweenService")
rawset(tweenService, "Create", function(_, object, _, goals)
	return {
		Play = function()
			for key, value in goals do
				object[key] = value
			end
		end,
		Completed = signal(),
		Cancel = function() end,
	}
end)

local replicatedStorage = service("ReplicatedStorage")
local remotes = newInstance("Folder")
remotes.Name = "Remotes"
remotes.Parent = replicatedStorage

-- Lo que el cliente pide al servidor por el remoto del pase
local sent: { { any } } = {}
local bpRemote = newInstance("RemoteEvent")
bpRemote.Name = "BattlePass"
rawset(bpRemote, "FireServer", function(_, ...)
	table.insert(sent, { ... })
end)

local players = service("Players")
local localPlayer = newInstance("Player")
rawget(localPlayer, "__props").DisplayName = "Rayo"
rawget(localPlayer, "__props").UserId = 1
local playerGui = newInstance("PlayerGui")
playerGui.Name = "PlayerGui"
playerGui.Parent = localPlayer
rawget(players, "__props").LocalPlayer = localPlayer

local camera = newInstance("Camera")
rawget(camera, "__props").ViewportSize = roblox.Vector2.new(1920, 1080)
local fakeWorkspace = newInstance("Workspace")
rawget(fakeWorkspace, "__props").CurrentCamera = camera

local userInput = service("UserInputService", { TouchEnabled = false, KeyboardEnabled = true, GamepadEnabled = false })
rawset(userInput, "GetFocusedTextBox", function()
	return nil
end)
rawset(userInput, "GetMouseLocation", function()
	return roblox.Vector2.new(400, 300)
end)

local services = {
	TweenService = tweenService,
	ReplicatedStorage = replicatedStorage,
	Players = players,
	UserInputService = userInput,
	RunService = service("RunService"),
	GuiService = service("GuiService"),
}
local fakeGame = { GetService = function(_, name)
	return services[name] or error("Servicio sin simular: " .. name)
end }

local fakeTask = {
	spawn = function(fn, ...)
		local thread = coroutine.create(fn)
		local ok, err = coroutine.resume(thread, ...)
		if not ok then
			error(err)
		end
		return thread
	end,
	defer = function(fn, ...)
		fn(...)
	end,
	delay = function() end,
	wait = function()
		coroutine.yield()
	end,
}

---------------------------------------------------------------------
-- Cargar módulos (ReplicatedStorage.Shared -> src/shared; script -> src/client)
---------------------------------------------------------------------
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
rawget(replicatedStorage, "__props").Shared = node("src/shared")

local cache: { [string]: any } = {}
-- Avisos y menú de comandos: dobles que apuntan lo que pasa
local toasts: { string } = {}
local menuRefreshes = 0
local STUBS = {
	["src/client/UI/Hud"] = function()
		return { toast = function(_, text)
			table.insert(toasts, text)
		end }
	end,
	["src/client/Commands/CommandMenu"] = function()
		return { refresh = function()
			menuRefreshes += 1
		end }
	end,
}
local function loadModule(path: string): any
	if cache[path] ~= nil then
		return cache[path]
	end
	if STUBS[path] then
		cache[path] = STUBS[path]()
		return cache[path]
	end
	local file = path .. ".luau"
	assert(fs.isFile(file), "Módulo no encontrado: " .. path)
	local env = setmetatable({
		script = node(path),
		require = function(target)
			return loadModule(rawget(target, "__path"))
		end,
		game = fakeGame,
		workspace = fakeWorkspace,
		task = fakeTask,
		Instance = Instance,
		TweenInfo = TweenInfo,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		Vector2 = roblox.Vector2,
		Vector3 = roblox.Vector3,
		Color3 = roblox.Color3,
		ColorSequence = roblox.ColorSequence,
		ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
		NumberSequence = roblox.NumberSequence,
		NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
		Font = roblox.Font,
		Enum = roblox.Enum,
		CFrame = roblox.CFrame,
		typeof = function(value)
			if getmetatable(value) == instanceMeta then
				return "Instance"
			end
			return typeof(value)
		end,
		warn = function(...)
			print("[warn]", ...)
		end,
	}, { __index = _G })
	local result = luau.load(fs.readFile(file), { debugName = file, environment = env })()
	cache[path] = result
	return result
end

---------------------------------------------------------------------
-- Un estado del servidor de mentira (con la forma del contrato: docs/pase-de-temporada.md §12)
---------------------------------------------------------------------
local Season1 = loadModule("src/shared/BattlePass/Season1")
local BPConfig = loadModule("src/shared/BattlePass/Config")

local function snapshot(opts: { [string]: any }): { [string]: any }
	local level = opts.Level or 12
	local premium = opts.Premium == true
	local claimedFree = opts.ClaimedFree or {}
	local claimedPremium = opts.ClaimedPremium or {}
	local rewards = {}
	local available = 0
	for _, def in Season1.Rewards do
		local claimed = if def.Track == "Free" then claimedFree[def.Level] else claimedPremium[def.Level]
		local state = if claimed then "CLAIMED" elseif def.Track == "Premium" and not premium then "PREMIUM_LOCKED" elseif level >= def.Level then "AVAILABLE" else "LOCKED"
		if state == "AVAILABLE" then
			available += 1
		end
		local rarity = BPConfig.Rarities[def.Rarity] or BPConfig.Rarities.Comun
		local preview = if type(def.Preview) == "table" then table.clone(def.Preview) else { Kind = def.Type }
		preview.Colors = preview.Colors or def.Colors
		preview.Color = preview.Color or def.Color
		if def.Type == "VehicleSkin" or def.Type == "Decor" then
			preview.Model = "BattlePassPreviews/" .. def.Id
		end
		if def.Type == "Emote" then
			preview.AnimationId = def.AnimationId
		end
		table.insert(rewards, {
			Id = def.Id, Level = def.Level, Track = def.Track, Type = def.Type, TypeName = BPConfig.TypeNames[def.Type] or def.Type,
			Name = def.Name, Description = def.Description, Icon = def.Icon, Rarity = def.Rarity, RarityName = rarity.Name,
			RarityColor = rarity.Color, Amount = def.Amount, Kind = def.Kind, State = state, Milestone = def.Level % 5 == 0,
			Preview = preview, Owned = claimed == true,
			Usable = if def.Type == "Boat" then false else nil,
			UsableText = if def.Type == "Boat" then "Llega con el puerto deportivo" else nil,
		})
	end
	table.sort(rewards, function(a, b)
		if a.Level ~= b.Level then
			return a.Level < b.Level
		end
		return a.Track == "Free" and b.Track ~= "Free"
	end)
	local now = 1791158400 + 40 * 86400
	local shop = {}
	for _, item in Season1.TokenShop do
		table.insert(shop, { Id = item.Id, Type = item.Type, TypeName = BPConfig.TypeNames[item.Type], Name = item.Name, Icon = item.Icon, Rarity = item.Rarity, Cost = item.Cost, Description = item.Description, Owned = item.Id == "S1_T_Phone", Preview = { Kind = item.Type } })
	end
	return {
		Season = { Id = "S1", Number = 1, Name = Season1.Name, Subtitle = Season1.Subtitle, StartsAt = Season1.StartsAt, EndsAt = Season1.EndsAt, ClaimUntil = Season1.EndsAt + 7 * 86400, Now = now, Status = opts.Status or "Active", MaxLevel = 50, Colors = Season1.Colors },
		Premium = { Owned = premium, Purchased = premium, Simulated = false, PurchaseEnabled = not premium and not opts.ComingSoon, ComingSoon = opts.ComingSoon == true, GamePassId = if opts.ComingSoon then 0 else 123456, PriceRobux = if opts.ComingSoon then nil else 449, RewardCount = 100 },
		Progress = { Level = level, Xp = 300, XpForNext = 1320, TotalXp = 20000, IsMax = level >= 50, Available = available, Tokens = 3, DailyXp = 200, DailyCap = 1400, EventMultiplier = opts.Multiplier or 1 },
		Rewards = rewards,
		Missions = {
			Daily = { ResetsAt = now + 5 * 3600, List = {
				{ Id = "D_Turno", Kind = "Daily", Title = "Turno completo", Description = "Haz 5 tareas de tu trabajo", Icon = "💼", Progress = 3, Goal = 5, Xp = 150, Done = false, Place = "Centro", Tracked = false },
				{ Id = "D_Metro", Kind = "Daily", Title = "Viaja en metro", Description = "Un viaje en metro", Icon = "🚇", Progress = 1, Goal = 1, Xp = 100, Done = true, Tracked = false },
				{ Id = "D_Cocina", Kind = "Daily", Title = "Cocina algo", Description = "Prepara una comida", Icon = "🍳", Progress = 0, Goal = 1, Xp = 120, Done = false, Tracked = false },
			} },
			Weekly = { ResetsAt = now + 3 * 86400, List = {
				{ Id = "W_Barrios", Kind = "Weekly", Title = "Tres barrios", Description = "Visita 3 barrios distintos", Icon = "🧭", Progress = 1, Goal = 3, Xp = 500, Done = false, Tracked = false },
			} },
			Season = { List = {
				{ Id = "T_Km", Kind = "Season", Title = "40 km al volante", Description = "Conduce 40 km", Icon = "🚗", Progress = 12.5, Goal = 40, Unit = "km", Xp = 1200, Tokens = 1, Done = false, Tracked = false },
			} },
			Event = { List = {} },
			Story = { {
				Id = "H_Faro", Title = "Se apaga el faro", Icon = "🗼", Intro = "El faro de Valmar se ha apagado.", Phase = 7, Phases = 7, Done = false, Tracked = false,
				Reward = { Id = "S1_H_Title", Name = "Guardián/a del faro", Icon = "🗼" },
				Current = { Id = "F7", Title = "Decide", Text = "¿Qué hacemos con el faro?", Progress = 0, Goal = 1, Xp = 400, Choices = { { Id = "Arreglar", Text = "Arreglarlo" }, { Id = "Modernizar", Text = "Modernizarlo" } } },
			} },
			Tracked = nil,
			CanReroll = opts.CanReroll == true,
		},
		Events = {},
		Equipped = { Title = opts.EquippedTitle, VehicleSkin = {}, Decor = {} },
		Collection = {},
		TokenShop = shop,
		History = {},
	}
end

---------------------------------------------------------------------
-- Geometría: dónde queda cada cosa (con Position/Size/AnchorPoint, como Roblox)
---------------------------------------------------------------------
local function absRect(object, stopAt): { X: number, Y: number, W: number, H: number }
	local chain = {}
	local current = object
	while current and current ~= stopAt do
		table.insert(chain, 1, current)
		current = current.Parent
	end
	local x, y = 0, 0
	local pw, ph = 0, 0
	local ow, oh = 0, 0
	if stopAt then
		pw, ph = (stopAt.Size or roblox.UDim2.new()).X.Offset, (stopAt.Size or roblox.UDim2.new()).Y.Offset
	end
	for _, item in chain do
		local size, pos = item.Size or roblox.UDim2.new(), item.Position or roblox.UDim2.new()
		local anchor = item.AnchorPoint or roblox.Vector2.new(0, 0)
		local w = pw * size.X.Scale + size.X.Offset
		local h = ph * size.Y.Scale + size.Y.Offset
		x += pw * pos.X.Scale + pos.X.Offset - anchor.X * w
		y += ph * pos.Y.Scale + pos.Y.Offset - anchor.Y * h
		ow, oh = w, h
		-- (dentro de un ScrollingFrame se mide sobre su lienzo)
		if rawget(item, "__class") == "ScrollingFrame" then
			local canvas = item.CanvasSize
			pw = math.max(w, canvas.X.Offset)
			ph = math.max(h, canvas.Y.Offset)
		else
			pw, ph = w, h
		end
	end
	return { X = x, Y = y, W = ow, H = oh }
end

local function overlaps(a, b): boolean
	return a.X < b.X + b.W - 0.01 and b.X < a.X + a.W - 0.01 and a.Y < b.Y + b.H - 0.01 and b.Y < a.Y + a.H - 0.01
end

local function inside(inner, outer): boolean
	return inner.X >= outer.X - 0.5 and inner.Y >= outer.Y - 0.5 and inner.X + inner.W <= outer.X + outer.W + 0.5 and inner.Y + inner.H <= outer.Y + outer.H + 0.5
end

local function describe(r): string
	return ("(%d,%d %dx%d)"):format(r.X, r.Y, r.W, r.H)
end

local function visibleChain(object, stopAt): boolean
	local current = object
	while current and current ~= stopAt do
		if current.Visible == false then
			return false
		end
		current = current.Parent
	end
	return true
end

local function isGui(object): boolean
	return isA(rawget(object, "__class"), "GuiObject")
end

local function inScroll(object, stopAt): boolean
	local current = object.Parent
	while current and current ~= stopAt do
		if rawget(current, "__class") == "ScrollingFrame" then
			return true
		end
		current = current.Parent
	end
	return false
end

-- Los hijos visibles de un contenedor no se pisan entre sí (salvo los adornos)
local DECOR = { Halo = true, Dot = true, RarityBar = true, Fallback = true, Viewport = true, Hint = true, Fill = true }
local function siblingsClear(container, label: string)
	local items = {}
	for _, child in container:GetChildren() do
		if isGui(child) and child.Visible ~= false and not DECOR[child.Name] then
			table.insert(items, { Name = child.Name, Rect = absRect(child, container) })
		end
	end
	local clashes = {}
	for i = 1, #items do
		for j = i + 1, #items do
			if overlaps(items[i].Rect, items[j].Rect) then
				table.insert(clashes, items[i].Name .. describe(items[i].Rect) .. " / " .. items[j].Name .. describe(items[j].Rect))
			end
		end
	end
	check(#clashes == 0, label .. ": nada se pisa (" .. #items .. " piezas)" .. (if #clashes > 0 then ": " .. table.concat(clashes, "; ") else ""))
end

local function textOf(root, text: string): boolean
	for _, object in root:GetDescendants() do
		local value = rawget(object, "__props").Text
		if typeof(value) == "string" and value:find(text, 1, true) then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
-- Montar la interfaz del pase (como en Main.client: BattlePassUI.init)
---------------------------------------------------------------------
local providers: { any } = {}
local function mount(touch: boolean, x: number, y: number, enabledFlag: boolean)
	table.clear(cache)
	table.clear(badWrites)
	table.clear(sent)
	table.clear(toasts)
	menuRefreshes = 0
	for _, child in playerGui:GetChildren() do
		child:Destroy()
	end
	bpRemote.Parent = nil
	-- (lo conectado por el montaje anterior no cuenta: cada montaje empieza de cero)
	rawget(bpRemote, "__signals").OnClientEvent = nil
	rawget(userInput, "__signals").InputBegan = nil
	rawget(userInput, "__signals").InputChanged = nil
	rawget(userInput, "__signals").InputEnded = nil
	rawget(camera, "__propSignals").ViewportSize = nil
	rawget(camera, "__props").ViewportSize = roblox.Vector2.new(x, y)
	rawget(userInput, "__props").TouchEnabled = touch
	rawget(userInput, "__props").KeyboardEnabled = not touch
	localPlayer:SetAttribute("LifeStage", "Adulto")
	local config = loadModule("src/shared/BattlePass/Config")
	config.Enabled = enabledFlag
	-- (como el servidor: el remoto solo existe con el pase encendido o, apagado, para un tester)
	if enabledFlag or localPlayer:GetAttribute("Tester") == true then
		bpRemote.Parent = remotes
	end
	local registry = loadModule("src/client/Commands/CommandRegistry")
	local UI = loadModule("src/client/UI/BattlePassUI")
	local ok, err = pcall(UI.init)
	return UI, registry, ok, err
end

local function rowFor(registry, stage: string?)
	for _, command in registry.list({ Stage = stage or "Adulto", Targets = {} }) do
		if command.Id == "PaseTemporada" then
			return command
		end
	end
	return nil
end

local function push(state)
	bpRemote.OnClientEvent:Fire("State", state)
end

local function sentHas(action: string, a: any?, b: any?): boolean
	for _, entry in sent do
		if entry[1] == action and (a == nil or entry[2] == a) and (b == nil or entry[3] == b) then
			return true
		end
	end
	return false
end

local function count(action: string): number
	local n = 0
	for _, entry in sent do
		if entry[1] == action then
			n += 1
		end
	end
	return n
end

local function levels(from: number, to: number): { [number]: boolean }
	local out = {}
	for i = from, to do
		out[i] = true
	end
	return out
end

-- Modelo 3D de mentira en ReplicatedStorage.BattlePassPreviews (como los que monta el servidor)
local function fakeModel(name: string)
	local model = newInstance("Model")
	model.Name = name
	local part = newInstance("Part")
	part.Parent = model
	rawset(model, "PivotTo", function() end)
	rawset(model, "GetBoundingBox", function()
		return roblox.CFrame.new(), roblox.Vector3.new(4, 3, 6)
	end)
	rawset(model, "Clone", function()
		return fakeModel(name)
	end)
	return model
end
local previews = newInstance("Folder")
previews.Name = "BattlePassPreviews"
previews.Parent = replicatedStorage
fakeModel("S1_P05").Parent = previews

---------------------------------------------------------------------
-- Comprobaciones de una ventana abierta (en cualquier tamaño)
---------------------------------------------------------------------
local function layoutChecks(UI, where: string, x: number, y: number, touch: boolean)
	local dbg = UI._debug()
	local ui = dbg.Ui
	check(ui ~= nil and UI.isOpen(), where .. ": la ventana se abre")
	if not ui then
		return
	end
	local window = ui.Window
	local L = ui.Layout
	local dialogs = playerGui:FindFirstChild("Dialogs")
	local base = dialogs and dialogs:FindFirstChildOfClass("UIScale")
	local fit = window:FindFirstChild("FitScale")
	local s = (base and base.Scale or 1) * (fit and fit.Scale or 1)
	check(fit and fit.Scale == 1, where .. ": cabe sin encogerla (FitScale = 1, el texto no se hace diminuto)")
	local pw, ph = window.Size.X.Offset * s, window.Size.Y.Offset * s
	check(pw <= x - 24 + 0.5 and ph <= y - 60 + 0.5, ("%s: la ventana cabe en la pantalla (%dx%d px en %dx%d, sin la barra de Roblox)"):format(where, pw, ph, x, y))
	-- Todo lo visible (salvo el halo y lo que va dentro de las listas) queda dentro de la ventana
	local W, Hh = window.Size.X.Offset, window.Size.Y.Offset
	local outside = {}
	for _, object in window:GetDescendants() do
		if isGui(object) and object.Name ~= "Halo" and object.Name ~= "Dot" and visibleChain(object, window) and not inScroll(object, window) then
			local r = absRect(object, window)
			if r.W > 0 and r.H > 0 and not inside(r, { X = 0, Y = 0, W = W, H = Hh }) then
				table.insert(outside, object.Name .. describe(r))
			end
		end
	end
	check(#outside == 0, where .. ": nada se sale de la ventana" .. (if #outside > 0 then ": " .. table.concat(outside, ", ") else ""))
	siblingsClear(window, where .. " · barra del título")
	local content = window:FindFirstChild("Content")
	siblingsClear(content, where .. " · cabecera, secciones y página")
	siblingsClear(content.Header, where .. " · nivel y XP")
	siblingsClear(content.Tabs, where .. " · pestañas RECOMPENSAS / MISIONES / FICHAS")
	local rewards = content.Page.Rewards
	if rewards.Visible then
		siblingsClear(rewards, where .. " · recompensa elegida, carriles, franja y fila")
		siblingsClear(rewards.Featured, where .. " · recompensa elegida")
		siblingsClear(rewards.Lanes, where .. " · GRATIS / PREMIUM / RECLAMAR TODO")
		if rewards.Strip.Offer.Visible then
			siblingsClear(rewards.Strip.Offer, where .. " · oferta del premium")
		end
		if rewards:FindFirstChild("Spotlight") then
			siblingsClear(rewards.Spotlight, where .. " · misión destacada")
		end
		local card = rewards.Track:FindFirstChild("Card01")
		siblingsClear(card, where .. " · tarjeta de una recompensa")
		local cardRect = absRect(card, rewards.Track)
		check(cardRect.H <= rewards.Track.Size.Y.Offset - L.Rewards.ScrollBar, where .. " · las tarjetas caben en la fila sin tapar la barra de desplazamiento")
		local cardInner = {}
		for _, child in card:GetChildren() do
			if isGui(child) and not inside(absRect(child, card), { X = 0, Y = 0, W = card.Size.X.Offset, H = card.Size.Y.Offset }) then
				table.insert(cardInner, child.Name)
			end
		end
		check(#cardInner == 0, where .. " · todo lo de la tarjeta queda dentro" .. (if #cardInner > 0 then ": " .. table.concat(cardInner, ", ") else ""))
	end
	-- Texto legible (en píxeles de pantalla) y botones cómodos
	local smallest, smallestName = math.huge, ""
	local shortest, shortestName = math.huge, ""
	for _, object in window:GetDescendants() do
		local class = rawget(object, "__class")
		if (class == "TextLabel" or class == "TextButton") and visibleChain(object, window) and object.TextScaled ~= true and tostring(object.Text or "") ~= "" then
			local px = object.TextSize * s
			if px < smallest then
				smallest, smallestName = px, object.Name
			end
		end
		if class == "TextButton" and visibleChain(object, window) and object.Name ~= "Card" and not string.match(object.Name, "^Card%d") and object.Size.Y.Offset > 0 then
			local px = object.Size.Y.Offset * s
			if px < shortest then
				shortest, shortestName = px, object.Name
			end
		end
	end
	local minText = if touch then 9.5 else 10.5
	check(smallest >= minText, ("%s: el texto más pequeño se lee (%.1f px: %s)"):format(where, smallest, smallestName))
	local minButton = if touch then 28 else 26
	check(shortest >= minButton, ("%s: los botones son cómodos de pulsar (el más bajo: %.0f px, %s)"):format(where, shortest, shortestName))
	check(#badWrites == 0, where .. ": todas las propiedades existen en Roblox" .. (if #badWrites > 0 then ": " .. table.concat(badWrites, ", ") else ""))
end

---------------------------------------------------------------------
print("\n▶ Pase APAGADO (BattlePassConfig.Enabled = false)")
do
	local UI, registry, ok, err = mount(false, 1920, 1080, false)
	check(ok, "BattlePassUI.init no falla" .. (if ok then "" else ": " .. tostring(err)))
	check(#sent == 0, "No pide nada al servidor")
	check(rowFor(registry) == nil, "No sale la app «Pase de temporada» en el ValPhone")
	UI.open()
	UI.toggle()
	local dialogs = playerGui:FindFirstChild("Dialogs")
	check(not UI.isOpen() and (dialogs == nil or dialogs:FindFirstChild("BattlePass") == nil), "La ventana no se abre ni con open() ni con la tecla")
	userInput.InputBegan:Fire({ KeyCode = roblox.Enum.KeyCode.N, UserInputType = roblox.Enum.UserInputType.Keyboard }, false)
	check(not UI.isOpen(), "La tecla N no hace nada")
	check(UI.swallowNotify == nil, "Ya no hay filtro de avisos por texto (el servidor no manda el de nivel si la interfaz lo enseña)")
	-- Cosméticos equipados: apagado, nada se pinta aunque haya atributos
	localPlayer:SetAttribute("BP_HudSkin", "S1_P08")
	localPlayer:SetAttribute("BP_PhoneTheme", "S1_P03")
	localPlayer:SetAttribute("BP_Title", "Vecino/a de Valmar")
	localPlayer:SetAttribute("BP_Emotes", "S1_P02")
	local Cos = loadModule("src/client/UI/BattlePassCosmetics")
	local ThemeOff = loadModule("src/client/UI/Theme")
	Cos.start()
	check(ThemeOff.accent("Hud") == nil and ThemeOff.accent("Phone") == nil, "Apagado: ni tema del HUD ni del teléfono")
	check(Cos.title(localPlayer) == nil and Cos.nameplate(localPlayer) == nil and not Cos.hasTag(localPlayer), "Apagado: ni título ni placa encima de la cabeza")
	check(#Cos.emotes(localPlayer) == 0, "Apagado: ningún gesto del pase")
	for _, key in { "BP_HudSkin", "BP_PhoneTheme", "BP_Title", "BP_Emotes" } do
		localPlayer:SetAttribute(key, nil)
	end
	check(#toasts == 0 and playerGui:FindFirstChild("BattlePassTip") == nil, "Ni avisos ni tooltips")
end

---------------------------------------------------------------------
print("\n▶ Ordenador (1920x1080), pase encendido")
local UI, registry, ok, err = mount(false, 1920, 1080, true)
check(ok, "BattlePassUI.init no falla" .. (if ok then "" else ": " .. tostring(err)))
check(sentHas("Get", "Ui"), "Al conectar pide el estado al servidor («Get») y le dice que el aviso de nivel lo enseña la interfaz")
check(rowFor(registry) == nil, "Sin estado todavía: no sale la fila")
push(snapshot({ Level = 12, ClaimedFree = levels(1, 5), Status = "Upcoming" }))
check(rowFor(registry) == nil, "Temporada que aún no ha empezado: no sale la fila")
push(snapshot({ Level = 12, ClaimedFree = levels(1, 5) }))
local row = rowFor(registry)
check(row ~= nil and row.Label == "Pase de temporada" and row.Icon == "🏆", "Temporada en marcha: sale la app «🏆 Pase de temporada» en el ValPhone")
check(row and row.Badge == true and tostring(row.Detail):find("por reclamar", 1, true) ~= nil, "Con punto rojo y «Nv. 12 · n por reclamar» (" .. tostring(row and row.Detail) .. ")")
check(row and row.Priority > 51 and row.Priority < 59, "Va con las apps (después de Mapa, antes de Modo pruebas y Más)")
check(menuRefreshes > 0, "El menú de comandos se refresca al cambiar")
check(rowFor(registry, "Bebe") == nil, "De bebé no sale")
local before = menuRefreshes
push(snapshot({ Level = 12, ClaimedFree = levels(1, 5) }))
check(menuRefreshes == before, "El mismo estado otra vez no vuelve a refrescar el menú (sin trabajo de más)")

-- Abrir desde la fila
row.Run({})
layoutChecks(UI, "1920x1080", 1920, 1080, false)
local ui = UI._debug().Ui
local window = ui.Window
local content = window.Content
local page = content.Page
local rewards = page.Rewards
local track = rewards.Track
check(window.Title.Text == "🏆 TEMPORADA 1 · LUCES DE VALMAR", "Cabecera «🏆 TEMPORADA 1 · LUCES DE VALMAR» (" .. tostring(window.Title.Text) .. ")")
check(content.Header.Level.Text == "NIVEL 12 / 50", "«NIVEL 12 / 50»")
check(content.Header.Xp.Text == "300 / 1.320 XP", "XP del nivel: «300 / 1.320 XP»")
check(math.abs(content.Header.XpBar.Fill.Size.X.Scale - 300 / 1320) < 0.001, "La barra de XP va a su sitio")
check(tostring(window.Days.Text):find("Quedan 23 días", 1, true) ~= nil, "Días que quedan: " .. tostring(window.Days.Text))
local cardCount = 0
for _, child in track:GetChildren() do
	if string.match(child.Name, "^Card%d%d$") then
		cardCount += 1
	end
end
check(cardCount == 50, "Fila de niveles 01…50 (" .. cardCount .. " tarjetas)")
check(track.ScrollingDirection == roblox.Enum.ScrollingDirection.X and track.CanvasSize.X.Offset > track.Size.X.Offset, "La fila se desplaza en horizontal")
local c1, c6, c12, c13 = track.Card01, track.Card06, track.Card12, track.Card13
check(c1.State.Text == "✔ RECLAMADA" and c1.State:GetAttribute("State") == "CLAIMED", "Nivel 1 gratis: RECLAMADA")
check(c6.State.Text == "RECLAMAR" and c6.State:GetAttribute("State") == "AVAILABLE", "Nivel 6 gratis: DISPONIBLE con RECLAMAR")
check(c13.State.Text == "🔒 BLOQUEADA" and c13.State:GetAttribute("State") == "LOCKED", "Nivel 13: BLOQUEADA")
check(c12.Badge.Text == "ACTUAL" and c13.Badge.Text == "SIGUIENTE", "Resalta la recompensa actual y la siguiente")
check(track.Card05.Badge.Text == "★ HITO" or track.Card05.Badge.Text == "ACTUAL", "Los hitos (cada 5) se marcan")
check(c6.RewardName.Text ~= "" and c6.Meta.Text:find("·", 1, true) ~= nil and c6.Level.Text == "NV. 06" and c6.Icon.Text ~= "", "Cada tarjeta: icono, nombre, rareza · tipo y nivel")
check(c1.Meta.TextColor3 == BPConfig.Rarities.Comun.Color and track.Card05.Meta.TextColor3 == BPConfig.Rarities.Rara.Color, "La rareza con su color")
-- Recompensa elegida por defecto: la primera disponible
local featured = rewards.Featured
check(featured.RewardName.Text == c6.RewardName.Text and featured.Primary.Text == "RECLAMAR", "Al abrir se enseña en grande la primera disponible con [RECLAMAR]")
check(featured.LevelLine.Text:find("Nivel 06", 1, true) ~= nil and featured.LevelLine.Text:find("GRATIS", 1, true) ~= nil and featured.LevelLine.Text:find("DISPONIBLE", 1, true) ~= nil, "Con nivel, pista y estado: " .. featured.LevelLine.Text)
check(rewards.Strip.NextLine.Visible and rewards.Strip.NextLine.Text:find("Nivel 13", 1, true) ~= nil, "Franja: la siguiente recompensa (" .. rewards.Strip.NextLine.Text .. ")")
check(rewards:FindFirstChild("Spotlight") and rewards.Spotlight.Mission.Text:find("Turno completo", 1, true) ~= nil, "Misión destacada con su XP (" .. tostring(rewards.Spotlight and rewards.Spotlight.Mission.Text) .. ")")
check(rewards.Lanes.FreeLane.Text:find("GRATIS", 1, true) ~= nil and rewards.Lanes.PremiumLane.Text:find("PREMIUM", 1, true) ~= nil, "Carriles GRATIS / PREMIUM")

-- Reclamar
table.clear(sent)
c6.State.Activated:Fire()
check(sentHas("Claim", "Free", 6), "RECLAMAR pide «Claim» (Free, 6) al servidor")
check(c6.State.Text == "…", "Mientras contesta, el botón espera («…»)")
c6.State.Activated:Fire()
check(count("Claim") == 1, "Pulsar otra vez no manda otra petición")
c13.State.Activated:Fire()
check(count("Claim") == 1, "Una bloqueada no pide nada")
push(snapshot({ Level = 12, ClaimedFree = levels(1, 6) }))
check(c6.State.Text == "✔ RECLAMADA", "Con el estado nuevo del servidor, queda RECLAMADA")
rewards.Lanes.ClaimAll.Activated:Fire()
check(sentHas("ClaimAll"), "RECLAMAR TODO pide «ClaimAll»")

-- Elegir una ya reclamada que se equipa (título)
c1.Activated:Fire()
check(featured.RewardName.Text == c1.RewardName.Text and featured.Primary.Text == "✔ RECLAMADA", "Al tocar una tarjeta se enseña en grande")
check(featured.Secondary.Visible and featured.Secondary.Text == "EQUIPAR", "Lo que ya es tuyo y se equipa: [EQUIPAR]")
siblingsClear(featured, "1920x1080 · recompensa elegida con dos botones")
featured.Secondary.Activated:Fire()
check(sentHas("Equip", "Title", "S1_F01"), "EQUIPAR pide «Equip» (Title, S1_F01)")
push((function()
	local s = snapshot({ Level = 12, ClaimedFree = levels(1, 6), EquippedTitle = "S1_F01" })
	return s
end)())
check(featured.Secondary.Text == "QUITAR", "Si ya lo llevas: [QUITAR]")

-- Tooltip (ordenador)
track.Card13.MouseEnter:Fire()
local tip = playerGui:FindFirstChild("BattlePassTip")
check(tip and tip.Tip.Visible and tip.Tip.TipName.Text:find(track.Card13.RewardName.Text, 1, true) ~= nil and tip.Tip.TipState.Text == "BLOQUEADA", "Al pasar el ratón: tooltip con nombre, descripción y estado")
track.Card13.MouseLeave:Fire()
check(tip and not tip.Tip.Visible, "Y se va al salir")

-- Carril PREMIUM sin comprar: oferta sin presión
rewards.Lanes.PremiumLane.Activated:Fire()
local p1 = track.Card01
check(p1.State.Text == "🔒 PREMIUM" and p1.State:GetAttribute("State") == "PREMIUM_LOCKED" and p1.Badge.Text ~= "", "Carril PREMIUM sin el pase: PREMIUM BLOQUEADA")
local offer = rewards.Strip.Offer
check(offer.Visible and offer.OfferText.Text == "PASE PREMIUM · Temporada 1 · 50 recompensas", "Franja «PASE PREMIUM · Temporada 1 · 50 recompensas»")
check(offer.PreviewButton.Text == "Vista previa" and offer.Buy.Text == "Comprar · R$ 449", "Con [Vista previa] y [Comprar · R$ 449] (precio de Roblox, no del código)")
layoutChecks(UI, "1920x1080 (carril premium)", 1920, 1080, false)
table.clear(sent)
offer.Buy.Activated:Fire()
check(sentHas("Buy"), "Comprar pide «Buy» (el servidor abre la compra de Roblox)")
offer.Buy.Activated:Fire()
check(count("Buy") == 1, "Mientras tanto no se repite")
bpRemote.OnClientEvent:Fire("Result", { Action = "Buy", Ok = true })
check(offer.Buy.Text == "Comprar · R$ 449", "Al contestar el servidor, el botón vuelve")
offer.PreviewButton.Activated:Fire()
check(featured.RewardName.Text == "Faro de Valmar" and UI._debug().Selected.Level == 50, "Vista previa: enseña la legendaria del nivel 50 («" .. featured.RewardName.Text .. "»)")
check(featured.Primary.Text:find("Comprar", 1, true) ~= nil, "Y desde ahí también se puede comprar")
-- Vista previa 3D (acabado del patinete, nivel 5 premium) y muestra de colores (tema del teléfono)
track.Card05.Activated:Fire()
check(featured.Preview:FindFirstChild("Viewport") ~= nil and featured.Preview.Viewport:FindFirstChildOfClass("WorldModel") ~= nil, "Vista previa 3D: el modelo en un ViewportFrame")
check(featured.Preview:FindFirstChild("Hint") ~= nil and featured.Preview.Hint.Text:find("arrastra", 1, true) ~= nil, "Con la pista «arrastra para girar»")
track.Card03.Activated:Fire()
check(featured.Preview:FindFirstChild("Viewport") == nil and featured.Preview:FindFirstChild("Fallback") ~= nil and featured.Preview.Fallback:FindFirstChild("Swatch1") ~= nil, "Sin modelo: icono y muestra de colores (tema del teléfono)")
track.Card35.Activated:Fire()
check(featured.Preview.Fallback:FindFirstChild("Note") ~= nil and featured.Preview.Fallback.Note.Text == "Llega con el puerto deportivo", "Barco: icono y «Llega con el puerto deportivo»")
check(#badWrites == 0, "Vistas previas: todas las propiedades existen en Roblox" .. (if #badWrites > 0 then ": " .. table.concat(badWrites, ", ") else ""))

-- Premium «Próximamente» (GamePassId = 0)
push(snapshot({ Level = 12, ClaimedFree = levels(1, 6), ComingSoon = true }))
check(offer.Buy.Text == "Próximamente" and offer.Buy.Active == false, "Sin Game Pass (GamePassId = 0): «Próximamente»")
table.clear(sent)
offer.Buy.Activated:Fire()
check(not sentHas("Buy"), "Y no pide comprar")
-- Con premium
push(snapshot({ Level = 12, ClaimedFree = levels(1, 6), Premium = true, ClaimedPremium = levels(1, 12) }))
check(not offer.Visible and rewards.Strip.NextLine.Text:find("Pase premium activo", 1, true) ~= nil, "Con el pase: sin oferta, «Pase premium activo»")
check(track.Card01.State.Text == "✔ RECLAMADA", "Y las premium alcanzadas, reclamadas")

-- Misiones
content.Tabs.MissionsTab.Activated:Fire()
local missions = page.Missions
check(missions.Visible and not rewards.Visible, "MISIONES: la sección cambia")
local turno = missions:FindFirstChild("Mission_D_Turno")
check(turno ~= nil and turno.Progress.Text == "3 / 5" and turno.Xp.Text == "+150 XP", "Diaria con progreso y XP («3 / 5», «+150 XP»)")
check(missions:FindFirstChild("Mission_D_Metro").Progress.Text == "✔ Hecha", "Hecha: «✔ Hecha»")
check(missions:FindFirstChild("Mission_T_Km").Progress.Text == "12,5 / 40 km" and missions.Mission_T_Km.Xp.Text == "+1.200 XP · +1 🪙", "De temporada en km y con fichas")
check(textOf(missions, "DIARIAS · se renuevan en 5 h") and textOf(missions, "SEMANALES") and textOf(missions, "DE TEMPORADA") and textOf(missions, "HISTORIA"), "Diarias, semanales, de temporada e historia")
check(turno:FindFirstChild("Reroll") == nil, "Sin la comodidad premium no sale «Cambiar»")
table.clear(sent)
turno.Track.Activated:Fire()
check(sentHas("Track", "D_Turno"), "📍 SEGUIR pide «Track» (el servidor pone SeasonTarget: GPS y marcador)")
local story = missions:FindFirstChild("Story_H_Faro")
story.Choice1.Activated:Fire()
check(sentHas("StoryChoice", "H_Faro", "Arreglar"), "La decisión de la historia pide «StoryChoice»")
siblingsClear(story, "1920x1080 · historia con decisión")
siblingsClear(turno, "1920x1080 · fila de misión")
local s2 = snapshot({ Level = 12, ClaimedFree = levels(1, 6), Premium = true, CanReroll = true })
push(s2)
turno = missions:FindFirstChild("Mission_D_Turno")
check(turno:FindFirstChild("Reroll") ~= nil, "Con la comodidad premium: «🔄 CAMBIAR» en las diarias")
siblingsClear(turno, "1920x1080 · fila de misión con Cambiar")
turno.Reroll.Activated:Fire()
check(sentHas("Reroll", "D_Turno"), "CAMBIAR pide «Reroll»")
local rowsInside = true
for _, child in missions:GetChildren() do
	if isGui(child) and absRect(child, missions).X + absRect(child, missions).W > absRect(missions, window).W + 0.5 then
		rowsInside = false
	end
end
check(rowsInside, "Las filas caben a lo ancho")

-- Fichas
content.Tabs.ShopTab.Activated:Fire()
local shop = page.Shop
check(shop.Visible and content.Tabs.ShopTab.Text == "FICHAS · 🪙 3", "FICHAS: la tienda, con tus fichas en la pestaña")
check(shop.Item_S1_T_Title.Buy.Text == "CANJEAR · 🪙 3", "Con fichas suficientes: CANJEAR")
check(shop.Item_S1_T_Plate.Buy.Text == "Faltan 1 🪙", "Sin fichas suficientes: cuántas faltan")
check(shop.Item_S1_T_Phone.Buy.Text == "✔ TUYO", "Lo que ya tienes: ✔ TUYO")
table.clear(sent)
shop.Item_S1_T_Plate.Buy.Activated:Fire()
check(not sentHas("BuyToken"), "Sin fichas no pide nada")
shop.Item_S1_T_Title.Buy.Activated:Fire()
check(sentHas("BuyToken", "S1_T_Title"), "CANJEAR pide «BuyToken»")
siblingsClear(shop.Item_S1_T_Title, "1920x1080 · artículo de la tienda")

-- Aviso discreto al subir de nivel (y sin repetir el del servidor)
table.clear(toasts)
bpRemote.OnClientEvent:Fire("Unlocked", { From = 12, Level = 13, Rewards = { { Level = 13, Track = "Free", Id = "S1_F13", Name = "250 €", Icon = "💶", Rarity = "Comun", Premium = false, State = "AVAILABLE" }, { Level = 13, Track = "Premium", Id = "S1_P13", Name = "Conjunto Playa Dorada", Premium = true, State = "PREMIUM_LOCKED" } } })
check(#toasts == 1 and toasts[1]:find("RECOMPENSA DESBLOQUEADA", 1, true) ~= nil and toasts[1]:find("250 €", 1, true) ~= nil, "Aviso discreto «RECOMPENSA DESBLOQUEADA» (" .. tostring(toasts[1]) .. ")")
table.clear(toasts)
bpRemote.OnClientEvent:Fire("Unlocked", { From = 13, Level = 14, Notified = false, Rewards = { { Level = 14, Track = "Premium", Id = "S1_P14", Name = "Tema", Premium = true, State = "PREMIUM_LOCKED" } } })
check(#toasts == 1 and toasts[1]:find("Nv. 14", 1, true) ~= nil, "Nada que reclamar y sin aviso del servidor: sale un aviso corto del nivel (" .. tostring(toasts[1]) .. ")")
table.clear(toasts)
bpRemote.OnClientEvent:Fire("Unlocked", { From = 14, Level = 15, Notified = true, Rewards = {} })
check(#toasts == 0, "Si el servidor ya avisó, no se repite")
do
	local main = fs.readFile("src/client/Main.client.luau")
	local uiSource = fs.readFile("src/client/UI/BattlePassUI.luau")
	check(main:find("swallowNotify", 1, true) == nil and uiSource:find("Pase de temporada: ¡nivel", 1, true) == nil, "Main.client ya no se come avisos por su texto")
end

-- Cosméticos equipados (encendido): los atributos los pone el servidor; aquí solo se pintan
do
	local Cos = loadModule("src/client/UI/BattlePassCosmetics")
	local ThemeOn = loadModule("src/client/UI/Theme")
	local PhoneUI = loadModule("src/client/UI/Phone")
	local Catalog = loadModule("src/shared/BattlePass/Catalog")
	local hud, phone, plate = Catalog.get("S1_P08"), Catalog.get("S1_P03"), Catalog.get("S1_F10")
	local stroke = newInstance("UIStroke")
	local gradient = newInstance("UIGradient")
	gradient.Color = ThemeOn.EdgeGradient
	gradient.Parent = stroke
	ThemeOn.skinEdge(stroke)
	local tint, tinted = nil, 0
	ThemeOn.onAccent("Phone", function(color)
		tint = color
		tinted += 1
	end)
	localPlayer:SetAttribute("BP_HudSkin", "S1_P08")
	localPlayer:SetAttribute("BP_PhoneTheme", "S1_P03")
	Cos.start()
	check(ThemeOn.accent("Hud") == hud.Colors.Accent and gradient.Color ~= ThemeOn.EdgeGradient, "Tema del HUD: el filo de los paneles toma su color (" .. hud.Name .. ")")
	check(ThemeOn.accent("Phone") == phone.Colors.Accent and tint == phone.Colors.Accent, "Tema del teléfono: el ValPhone toma su color (" .. phone.Name .. ")")
	check(PhoneUI.wallpaper(nil) ~= PhoneUI.wallpaper(phone.Colors.Accent), "El fondo de pantalla del ValPhone cambia con el tema (y vuelve al de la marca sin él)")
	localPlayer:SetAttribute("BP_HudSkin", "S1_P03") -- (un tema de teléfono no es de HUD)
	check(ThemeOn.accent("Hud") == nil and gradient.Color == ThemeOn.EdgeGradient, "Algo que no es un tema de HUD no cambia nada (y el filo vuelve al de siempre)")
	localPlayer:SetAttribute("BP_PhoneTheme", nil)
	check(ThemeOn.accent("Phone") == nil and tint == nil and tinted == 2, "Sin tema del teléfono: el ValPhone de siempre")
	localPlayer:SetAttribute("BP_HudSkin", nil)
	-- Título y placa (encima de la cabeza: Controllers/NameTags)
	local other = newInstance("Player")
	check(not Cos.hasTag(other), "Sin título ni placa: el nombre de siempre")
	other:SetAttribute("BP_Title", "Vecino/a de Valmar")
	other:SetAttribute("BP_TitleColor", roblox.Color3.fromRGB(230, 230, 235))
	other:SetAttribute("BP_Nameplate", "S1_F10")
	local text, color = Cos.title(other)
	local colors = Cos.nameplate(other)
	check(text == "Vecino/a de Valmar" and color ~= nil and colors == plate.Colors and Cos.hasTag(other), "Título y placa de otro jugador (" .. plate.Name .. ")")
	other:SetAttribute("BP_Nameplate", "S1_P08")
	check(Cos.nameplate(other) == nil, "Una placa que no es placa no se pinta")
	-- Gestos del pase
	other:SetAttribute("BP_Emotes", "S1_P02,S1_F07,NoExiste,S1_P08")
	local emotes = Cos.emotes(other)
	check(#emotes == 2 and emotes[1].Id == "S1_P02" and type(emotes[1].AnimationId) == "number" and emotes[2].Name == "Aplauso de la plaza", "Gestos del pase: solo los que existen y son gestos")
	local actions = fs.readFile("src/client/Controllers/Actions.luau")
	local commands = fs.readFile("src/client/Commands/DefaultCommands.luau")
	local tags = fs.readFile("src/client/Controllers/NameTags.luau")
	check(actions:find("Cosmetics.emotes(player)", 1, true) ~= nil and commands:find("GestosPase", 1, true) ~= nil, "Los gestos del pase van con los del juego (Actions) y salen en el ValPhone")
	check(tags:find("Cosmetics.hasTag", 1, true) ~= nil and tags:find("BillboardGui", 1, true) ~= nil, "El título y la placa van en el cartel de nombres de siempre (NameTags), no en otro")
end

-- Tecla N
userInput.InputBegan:Fire({ KeyCode = roblox.Enum.KeyCode.N, UserInputType = roblox.Enum.UserInputType.Keyboard }, false)
check(not UI.isOpen(), "N cierra la ventana")
userInput.InputBegan:Fire({ KeyCode = roblox.Enum.KeyCode.N, UserInputType = roblox.Enum.UserInputType.Keyboard }, true)
check(not UI.isOpen(), "Si N ya la usó otra cosa (escribiendo en el chat…), no hace nada")
userInput.InputBegan:Fire({ KeyCode = roblox.Enum.KeyCode.N, UserInputType = roblox.Enum.UserInputType.Keyboard }, false)
check(UI.isOpen(), "N la vuelve a abrir")
UI.close()

-- Estado de temporada acabada con la ventana abierta: se cierra y la fila se va
UI.open()
push(snapshot({ Level = 12, Status = "Ended" }))
check(not UI.isOpen() and rowFor(registry) == nil, "Temporada acabada del todo: la fila se va y la ventana se cierra")

---------------------------------------------------------------------
-- Más tamaños (ordenador y móvil)
---------------------------------------------------------------------
local SIZES = {
	{ false, 1600, 900 },
	{ false, 1366, 768 },
	{ false, 1280, 720 },
	{ true, 844, 390 },
	{ true, 640, 360 },
	{ true, 667, 375 },
	{ true, 932, 430 },
	{ true, 1024, 768 },
	{ true, 2400, 1080 },
}
for _, size in SIZES do
	local touch, x, y = size[1], size[2], size[3]
	local where = ("%s %dx%d"):format(if touch then "Móvil" else "Ordenador", x, y)
	print(("\n▶ %s"):format(where))
	local U, reg, okMount, errMount = mount(touch, x, y, true)
	check(okMount, where .. ": se monta sin errores" .. (if okMount then "" else ": " .. tostring(errMount)))
	push(snapshot({ Level = 12, ClaimedFree = levels(1, 5), CanReroll = true }))
	local r = rowFor(reg)
	check(r ~= nil, where .. ": app en el ValPhone")
	r.Run({})
	layoutChecks(U, where, x, y, touch)
	local u = U._debug().Ui
	if u then
		local L = u.Layout
		check(L.Touch == touch, where .. ": diseño " .. (if touch then "móvil" else "ordenador"))
		if touch then
			check(u.Window.Content.Page.Rewards:FindFirstChild("Spotlight") == nil, where .. ": en el móvil, menos piezas a la vez (la misión destacada está en MISIONES)")
			check(playerGui:FindFirstChild("BattlePassTip") == nil, where .. ": sin tooltips de ratón")
			check(u.Window.Size.Y.Offset * L.Scale >= (y - 60) * 0.95 or u.Window.Size.Y.Offset >= 620, where .. ": hoja casi a pantalla completa (todo el alto)")
		end
		-- Carril premium con la oferta, y las otras secciones
		local rw = u.Window.Content.Page.Rewards
		rw.Lanes.PremiumLane.Activated:Fire()
		layoutChecks(U, where .. " (premium)", x, y, touch)
		u.Window.Content.Tabs.MissionsTab.Activated:Fire()
		local list = u.Window.Content.Page.Missions
		local turno2 = list:FindFirstChild("Mission_D_Turno")
		check(turno2 ~= nil, where .. ": misiones")
		if turno2 then
			siblingsClear(turno2, where .. " · fila de misión")
			local st = list:FindFirstChild("Story_H_Faro")
			siblingsClear(st, where .. " · historia")
		end
		layoutChecks(U, where .. " (misiones)", x, y, touch)
		u.Window.Content.Tabs.ShopTab.Activated:Fire()
		local item = u.Window.Content.Page.Shop:FindFirstChild("Item_S1_T_Title")
		check(item ~= nil and absRect(item, u.Window.Content.Page.Shop).W <= absRect(u.Window.Content.Page.Shop, u.Window).W, where .. ": tienda de fichas")
		if item then
			siblingsClear(item, where .. " · artículo")
		end
		layoutChecks(U, where .. " (fichas)", x, y, touch)
	end
	-- La medida pura (BattlePassLayout) tampoco se pisa
	local Layout = loadModule("src/client/UI/BattlePassLayout")
	local L2 = Layout.compute(roblox.Vector2.new(x, y), touch)
	local rects = Layout.flatten(L2)
	local clashes = {}
	for i = 1, #rects do
		for j = i + 1, #rects do
			if Layout.overlaps(rects[i].Rect, rects[j].Rect) then
				table.insert(clashes, rects[i].Name .. " / " .. rects[j].Name)
			end
		end
		if not Layout.inside(rects[i].Rect, { X = 0, Y = 0, W = L2.Window.X, H = L2.Window.Y }) then
			table.insert(clashes, rects[i].Name .. " fuera")
		end
	end
	check(#clashes == 0, where .. ": BattlePassLayout sin choques" .. (if #clashes > 0 then ": " .. table.concat(clashes, ", ") else ""))
end

---------------------------------------------------------------------
print("\n▶ Panel de pruebas (UI/TesterPanel): sección del pase")
do
	mount(false, 1920, 1080, true)
	local testerRemote = remotes:FindFirstChild("Tester") or newInstance("RemoteEvent")
	testerRemote.Name = "Tester"
	testerRemote.Parent = remotes
	local testerSent = {}
	rawset(testerRemote, "FireServer", function(_, ...)
		table.insert(testerSent, { ... })
	end)
	rawget(testerRemote, "__signals").OnClientEvent = nil
	localPlayer:SetAttribute("Tester", true)
	local Panel = loadModule("src/client/UI/TesterPanel")
	local okInit, errInit = pcall(Panel.init)
	check(okInit, "El panel arranca" .. (if okInit then "" else ": " .. tostring(errInit)))
	local base = { Money = false, Bypass = false, Stage = "Adulto", Stages = { "Nino", "Adulto" }, Places = {}, Hours = { 8 } }
	local withBp = table.clone(base)
	withBp.BattlePass = { SimulatedPremium = false, RealPremium = false, Level = 12, ClockShift = 0 }
	testerRemote.OnClientEvent:Fire("Open", withBp)
	local dialogs = playerGui:FindFirstChild("Dialogs")
	local panel = dialogs and dialogs:FindFirstChild("TesterPanel")
	check(panel ~= nil and textOf(panel, "PASE DE TEMPORADA · nivel 12") and textOf(panel, "Premium simulado: NO"), "Con el pase encendido: sección «PASE DE TEMPORADA» con nivel y premium simulado")
	local function press(text: string)
		for _, object in panel:GetDescendants() do
			if rawget(object, "__class") == "TextButton" and object.Text == text then
				object.Activated:Fire()
				return true
			end
		end
		return false
	end
	local function testerHas(op: string, value: any?): boolean
		for _, entry in testerSent do
			if entry[1] == "Action" and entry[2] == "BattlePass" and type(entry[3]) == "table" and entry[3].Op == op and (value == nil or entry[3].Value == value) then
				return true
			end
		end
		return false
	end
	press("⭐ Premium simulado: NO")
	press("🎟 +1.000 XP")
	press("Nivel 30")
	press("🕒 Día siguiente")
	press("♻ Reiniciar el pase")
	check(testerHas("Premium") and testerHas("AddXp", 1000) and testerHas("SetLevel", 30) and testerHas("NextDay") and testerHas("Reset"), "Premium simulado, +XP, nivel, reloj y reiniciar piden su acción a TesterService")
	withBp.BattlePass = { SimulatedPremium = true, RealPremium = false, Level = 30, ClockShift = 86400 }
	testerRemote.OnClientEvent:Fire("State", withBp)
	check(textOf(panel, "Premium simulado: SÍ") and textOf(panel, "nivel 30") and textOf(panel, "reloj +24 h"), "Se actualiza con el estado del servidor")
	check(#badWrites == 0, "Todas las propiedades existen en Roblox" .. (if #badWrites > 0 then ": " .. table.concat(badWrites, ", ") else ""))
	Panel.close()
	testerRemote.OnClientEvent:Fire("Open", base)
	panel = playerGui:FindFirstChild("Dialogs"):FindFirstChild("TesterPanel")
	check(panel ~= nil and not textOf(panel, "PASE DE TEMPORADA"), "Con el pase apagado (sin BattlePass en el estado) no sale la sección")
end

---------------------------------------------------------------------
print("\n▶ Panel de pruebas: «🏎️ Vehículos del pase»")
do
	local testerRemote = remotes:FindFirstChild("Tester")
	local testerSent = {}
	rawset(testerRemote, "FireServer", function(_, ...)
		table.insert(testerSent, { ... })
	end)
	local Catalog = loadModule("src/shared/BattlePass/Catalog")
	local list = {}
	for _, entry in Catalog.vehicles() do
		table.insert(list, { Id = entry.Id, Name = entry.Name, Icon = entry.Icon, Kind = entry.Kind, Rarity = entry.Rarity })
	end
	local function deep(root, name: string)
		for _, object in (if root then root:GetDescendants() else {}) do
			if object.Name == name then
				return object
			end
		end
		return nil
	end
	local Panel = loadModule("src/client/UI/TesterPanel")
	Panel.close()
	testerRemote.OnClientEvent:Fire("Open", { Money = false, Bypass = false, Stage = "Adulto", Stages = {}, Places = {}, Hours = {}, PassVehicles = list })
	local panel = playerGui:FindFirstChild("Dialogs"):FindFirstChild("TesterPanel")
	local buttons = 0
	for _, entry in list do
		local b = deep(panel, "PassVehicle_" .. entry.Id)
		if b and string.find(b.Text, entry.Name, 1, true) then
			buttons += 1
		end
	end
	check(panel ~= nil and textOf(panel, "🏎️ Vehículos del pase") and buttons == 14, ("Sección «🏎️ Vehículos del pase» con un «Sacar» por vehículo (%d de 14)"):format(buttons))
	local all = deep(panel, "PassVehiclesAll")
	check(all ~= nil and string.find(all.Text, "Darme todos", 1, true) ~= nil, "Y el botón «Darme todos»")
	if all then
		all.Activated:Fire()
	end
	local storm = deep(panel, "PassVehicle_Storm")
	if storm then
		storm.Activated:Fire()
	end
	local askedAll, askedStorm = false, false
	for _, entry in testerSent do
		askedAll = askedAll or (entry[1] == "Action" and entry[2] == "PassVehiclesAll")
		askedStorm = askedStorm or (entry[1] == "Action" and entry[2] == "PassVehicle" and entry[3] == "Storm")
	end
	check(askedAll and askedStorm, "«Darme todos» y «Sacar» piden su acción a TesterService (con el id del vehículo)")
	check(not Panel.isOpen(), "Al sacar uno, el panel se cierra (para verlo)")
	check(#badWrites == 0, "Todas las propiedades existen en Roblox" .. (if #badWrites > 0 then ": " .. table.concat(badWrites, ", ") else ""))
end

---------------------------------------------------------------------
print("\n▶ Pase APAGADO pero eres tester (modo pruebas)")
do
	localPlayer:SetAttribute("Tester", true)
	local UI, registry, ok, err = mount(false, 1920, 1080, false)
	check(ok, "BattlePassUI.init no falla" .. (if ok then "" else ": " .. tostring(err)))
	check(UI.enabled() and sentHas("Get", "Ui"), "Para el tester el pase está activo: pide su estado al servidor")
	push(snapshot({ Level = 50 }))
	check(rowFor(registry) ~= nil, "Sale la fila «Pase de temporada»")
	UI.open()
	check(UI.isOpen(), "Y la ventana del pase se abre (vistas previas, reclamar…)")
	UI.close()
	localPlayer:SetAttribute("Tester", nil)
	local UI2, registry2 = mount(false, 1920, 1080, false)
	check(not UI2.enabled() and #sent == 0 and rowFor(registry2) == nil, "Sin el atributo Tester, apagado: nada (ni petición ni fila)")
end

print()
if failures > 0 then
	print(("❌ %d fallo(s)"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
