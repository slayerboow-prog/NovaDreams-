-- Prueba de los ACTORES de las escenas: entrar, salir, mirar y emociones (Lune, fuera de Roblox).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-actors.luau
--
-- Comprueba (auditoría C-01, C-02, C-03, C-06 y la tabla de emociones del encargo):
--   1. Las reglas (shared/LifeStory/ActorStaging): Enter / Exit, cómo se va cada uno según dónde
--      estás, adónde se aleja, que no se van todos a la vez, cuándo un salto lleva fundido y a quién
--      mira quien habla (To, contestar a una pregunta, comentar lo que dijo otro).
--   2. Las emociones (ActorMoods + Emotion): alegría, tristeza, enfado, sorpresa, nervios y vergüenza,
--      sutiles (sin exagerar), con su forma de mirar; las frases las adivinan por el texto.
--   3. El SceneService de verdad con un Roblox de mentira: quien sobra al cambiar de paso NO se borra de
--      golpe (se va andando y se desvanece), se van escalonados, vuelve si se le necesita otra vez (sin
--      duplicados), los lejanos y los enemigos se desvanecen, vuelven a su sitio de siempre, Exit = lugar,
--      Exit = "Fade" / "Stay", Enter = { From } (entra andando, también con Delay), Mood, quitar la escena
--      de una misión, salir del juego (se borra todo ya) y el salto del jugador con fundido (SceneDip).
--   4. El cliente (ActorLife, SceneDip) tiene lo que hace falta: todo el reparto mira a quien habla,
--      To, escuchar con vida, fundido al irse, posturas de nervios y vergüenza, la pantalla vuelve siempre.

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local task = require("@lune/task")
local L = require("./lib/ModuleLoader")

local Vector3, CFrame = roblox.Vector3, L.CFrame
local Enum = roblox.Enum
local check = L.check

---------------------------------------------------------------------
-- Un Roblox de mentira (solo lo que usa SceneService)
---------------------------------------------------------------------
local function signal()
	local handlers = {}
	local s = {}
	function s:Connect(fn)
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
	function s:Fire(...)
		for _, fn in table.clone(handlers) do
			fn(...)
		end
	end
	return s
end

local PARTS = { Part = true, Seat = true }
local Fake = {}
local FakeMeta = {}

local function new(className: string)
	local obj = setmetatable({
		__props = { ClassName = className, Name = className },
		__attrs = {},
		__attrSignals = {},
		__tags = {},
		__children = {},
	}, FakeMeta)
	if PARTS[className] then
		obj.__props.CFrame = CFrame.new()
		obj.__props.Size = Vector3.new(2, 2, 1)
		obj.__props.Anchored = false
		obj.__props.AssemblyLinearVelocity = Vector3.zero
	elseif className == "Humanoid" then
		obj.__props.RigType = Enum.HumanoidRigType.R15
		obj.__props.HipHeight = 2
		obj.__props.WalkSpeed = 16
		obj.__props.MoveDirection = Vector3.zero
		obj.__props.Jump = false
	elseif className == "ProximityPrompt" then
		obj.__props.Triggered = signal()
		obj.__props.Enabled = true
	end
	return obj
end

FakeMeta.__index = function(self, key)
	local f = Fake[key]
	if f then
		return f
	end
	local props = rawget(self, "__props")
	if key == "Position" and props.CFrame then
		return props.CFrame.Position
	end
	if props[key] ~= nil then
		return props[key]
	end
	for _, child in rawget(self, "__children") do
		if child.__props.Name == key then
			return child
		end
	end
	return nil
end
FakeMeta.__newindex = function(self, key, value)
	local props = rawget(self, "__props")
	if key == "Parent" then
		local old = props.Parent
		if old then
			local i = table.find(old.__children, self)
			if i then
				table.remove(old.__children, i)
			end
		end
		props.Parent = value
		if value then
			table.insert(value.__children, self)
		end
		return
	end
	if key == "Position" then
		props.CFrame = CFrame.new(value) * (props.CFrame or CFrame.new()).Rotation
		return
	end
	props[key] = value
end

function Fake.IsA(self, name)
	local class = self.__props.ClassName
	return class == name or name == "Instance" or (name == "BasePart" and PARTS[class] ~= nil)
end
function Fake.Destroy(self)
	if self.__destroyed then
		return
	end
	self.__destroyed = true
	for _, child in table.clone(self.__children) do
		child:Destroy()
	end
	self.Parent = nil
end
function Fake.GetAttribute(self, name)
	return self.__attrs[name]
end
function Fake.SetAttribute(self, name, value)
	self.__attrs[name] = value
	if self.__attrSignals[name] then
		self.__attrSignals[name]:Fire()
	end
end
function Fake.GetAttributeChangedSignal(self, name)
	self.__attrSignals[name] = self.__attrSignals[name] or signal()
	return self.__attrSignals[name]
end
function Fake.AddTag(self, tag)
	self.__tags[tag] = true
end
function Fake.RemoveTag(self, tag)
	self.__tags[tag] = nil
end
function Fake.HasTag(self, tag)
	return self.__tags[tag] == true
end
function Fake.GetChildren(self)
	return table.clone(self.__children)
end
function Fake.GetDescendants(self)
	local list = {}
	local function walk(node)
		for _, child in node.__children do
			table.insert(list, child)
			walk(child)
		end
	end
	walk(self)
	return list
end
function Fake.FindFirstChild(self, name, recursive)
	for _, child in self.__children do
		if child.__props.Name == name then
			return child
		end
	end
	if recursive then
		for _, child in self.__children do
			local found = child:FindFirstChild(name, true)
			if found then
				return found
			end
		end
	end
	return nil
end
function Fake.FindFirstChildOfClass(self, class)
	for _, child in self.__children do
		if child.__props.ClassName == class then
			return child
		end
	end
	return nil
end
function Fake.FindFirstChildWhichIsA(self, class)
	for _, child in self.__children do
		if child:IsA(class) then
			return child
		end
	end
	return nil
end
function Fake.IsDescendantOf(self, other)
	local node = self.__props.Parent
	while node do
		if node == other then
			return true
		end
		node = node.__props.Parent
	end
	return false
end
function Fake.GetPivot(self)
	local root = self:FindFirstChild("HumanoidRootPart")
	if root then
		return root.CFrame
	end
	return self.__props.CFrame or CFrame.new()
end
function Fake.PivotTo(self, cf)
	local root = self:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = cf
	else
		self.__props.CFrame = cf
	end
end
function Fake.GetScale()
	return 1
end
function Fake.ScaleTo() end
function Fake.SetNetworkOwner() end
-- Humanoide: MoveTo lleva la raíz al punto en el acto (si no está anclada): así se ve si llega
function Fake.MoveTo(self, target)
	self.__props.MoveTarget = target
	local model = self.__props.Parent
	local root = model and model:FindFirstChild("HumanoidRootPart")
	if root and not root.Anchored then
		root.CFrame = CFrame.new(target + Vector3.new(0, 3, 0)) * root.CFrame.Rotation
	end
end
function Fake.LoadAnimation()
	return { Play = function() end, Stop = function() end, AdjustSpeed = function() end, Length = 1, IsPlaying = false }
end

local function part(name: string, position: Vector3)
	local p = new("Part")
	p.Name = name
	p.CFrame = CFrame.new(position)
	return p
end

-- Un personaje R15 de mentira (raíz, cabeza, humanoide)
local function figure(): any
	local model = new("Model")
	local root = part("HumanoidRootPart", Vector3.new(0, 3, 0))
	root.Size = Vector3.new(2, 2, 1)
	root.Parent = model
	local head = part("Head", Vector3.new(0, 4.5, 0))
	head.Parent = model
	local humanoid = new("Humanoid")
	humanoid.Parent = model
	model.PrimaryPart = root
	return model
end

for _, class in { "Folder", "Model", "Part", "Seat", "Humanoid", "ProximityPrompt", "Animator", "Animation", "Highlight", "PointLight", "ParticleEmitter" } do
	L.fakeClasses[class] = function()
		return new(class)
	end
end
L.fakeClasses.HumanoidDescription = function()
	return {}
end

local workspaceRoot = new("Folder")
workspaceRoot.Name = "Workspace"
L.workspace = workspaceRoot

local playerList = {}
local removing = signal()
local tagged: { [string]: { any } } = {}
L.services.Players = {
	GetPlayers = function()
		return playerList
	end,
	PlayerRemoving = removing,
	PlayerAdded = signal(),
	CreateHumanoidModelFromDescription = function()
		return figure()
	end,
}
L.services.CollectionService = {
	AddTag = function(_, inst, tag)
		inst.__tags[tag] = true
	end,
	HasTag = function(_, inst, tag)
		return inst.__tags[tag] == true
	end,
	GetTagged = function(_, tag)
		return tagged[tag] or {}
	end,
}
L.services.TweenService = {
	Create = function(_, inst, _info, goal)
		return {
			Play = function()
				for k, v in goal do
					inst[k] = v
				end
			end,
		}
	end,
}
L.services.PathfindingService = {
	CreatePath = function()
		local path = { Status = Enum.PathStatus.Success, Blocked = signal(), Points = {} }
		function path:ComputeAsync(_from, to)
			self.Points = { { Position = to, Action = Enum.PathWaypointAction.Walk } }
		end
		function path:GetWaypoints()
			return self.Points
		end
		return path
	end,
}
-- Globales de Roblox que el cargador no trae (RaycastParams, TweenInfo): SceneService se carga aquí
-- con un entorno igual que el de ModuleLoader más esas dos
local luau = require("@lune/luau")
local EXTRA = {
	RaycastParams = {
		new = function()
			return {}
		end,
	},
	TweenInfo = {
		new = function(...)
			return { ... }
		end,
	},
	ColorSequence = roblox.ColorSequence,
	NumberSequence = roblox.NumberSequence,
	NumberRange = roblox.NumberRange,
}
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
local function loadWithExtras(path: string): any
	local env = setmetatable({
		script = node(path),
		require = function(target)
			return L.load(rawget(target, "__path"))
		end,
		game = L.game,
		workspace = L.workspace,
		task = task,
		Vector3 = roblox.Vector3,
		Vector2 = roblox.Vector2,
		Color3 = roblox.Color3,
		CFrame = L.CFrame,
		Enum = roblox.Enum,
		Instance = L.Instance,
		Random = L.Random,
		typeof = roblox.typeof or typeof,
		warn = function(...)
			local parts = {}
			for i = 1, select("#", ...) do
				table.insert(parts, tostring((select(i, ...))))
			end
			table.insert(L.warnings, table.concat(parts, " "))
		end,
	}, { __index = _G })
	for key, value in EXTRA do
		env[key] = value
	end
	local chunk = luau.load(fs.readFile(path .. ".luau"), { debugName = path, environment = env })
	local result = chunk()
	L.mock(path, result)
	return result
end

-- Lugares del mapa de mentira
local PLACES = {
	Patio = Vector3.new(0, 0, 0),
	Puerta = Vector3.new(0, 0, 30),
	Pasillo = Vector3.new(-40, 0, 0),
	Lejos = Vector3.new(400, 0, 0),
	Comedor = Vector3.new(0, 0, -20),
}
local spotParts = {}
L.mock("src/server/Services/LocationService", {
	resolve = function(_player, placeId, options)
		local at = PLACES[placeId]
		if not at then
			return nil
		end
		if options and options.Offset then
			at += options.Offset
		end
		local p = spotParts[placeId] or part("Spot_" .. placeId, at)
		spotParts[placeId] = p
		return { Position = at, CFrame = CFrame.new(at), Instance = p }
	end,
	isAt = function()
		return true
	end,
})
L.mock("src/shared/Ground", {
	castVisible = function()
		return nil
	end,
	cast = function()
		return nil
	end,
})
L.mock("src/server/World/Npc", {
	placeFeet = function(model, cf)
		model:PivotTo(cf * CFrame.new(0, 3, 0))
	end,
	setPose = function(model, pose)
		model:SetAttribute("UsePose", pose)
	end,
	dress = function() end,
	atomic = function() end,
})
L.mock("src/server/World/RoadGuard", {
	kerb = function()
		return nil, false
	end,
	mustWait = function()
		return false
	end,
})
L.mock("src/server/World/SafeSpot", {
	stuckAt = function()
		return false
	end,
	find = function(p)
		return p
	end,
	place = function(character, feet)
		character:PivotTo(CFrame.new(feet + Vector3.new(0, 3, 0)))
	end,
	release = function() end,
	buried = function()
		return false
	end,
	rescue = function() end,
})
L.mock("src/server/World/Kit/GallinaGigante", { costume = function() end })
L.mock("src/server/World/Kit/Cucaracha", { costume = function() end })
L.mock("src/server/World/Kit/Platillo", { build = function() end })
L.mock("src/server/Services/VehicleService", { standUp = function() end })

---------------------------------------------------------------------
print("\n▶ 1. Reglas de entrar, salir y mirar (ActorStaging)")
---------------------------------------------------------------------
local ActorStaging = L.load("src/shared/LifeStory/ActorStaging")

local e = ActorStaging.enter({ Npc = "Nico", Enter = "Puerta" })
check(e and e.From == "Puerta" and e.Walk == true and e.Delay == 0, "Enter = \"Puerta\": entra andando desde la puerta")
e = ActorStaging.enter({ Npc = "Nico", Enter = { From = "Pasillo", Delay = 2 } })
check(e and e.From == "Pasillo" and e.Delay == 2, "Enter = { From, Delay }: espera y entra")
check(ActorStaging.enter({ Npc = "Nico" }) == nil and ActorStaging.enter({ Npc = "Nico", Enter = { From = "Puerta", Walk = false } }) == nil, "sin Enter (o Walk = false), como siempre: aparece en su sitio con un fundido")
check(ActorStaging.enter({ Enter = { From = "Puerta", Delay = 999 } }).Delay <= 20, "un Delay absurdo se recorta")

local x = ActorStaging.exit({ Npc = "Nico" })
check(x.Walk and not x.Fade and not x.Stay and x.To == nil, "sin Exit: se va andando (nunca de golpe)")
check(ActorStaging.exit({ Exit = "Pasillo" }).To == "Pasillo" and ActorStaging.exit({ Exit = { To = "Pasillo" } }).To == "Pasillo", "Exit = lugar: se va andando hasta allí")
check(ActorStaging.exit({ Exit = "Fade" }).Fade and ActorStaging.exit({ Exit = { Fade = true } }).Fade and ActorStaging.exit({ Exit = { Walk = false } }).Fade, "Exit = \"Fade\": se desvanece")
check(ActorStaging.exit({ Exit = "Stay" }).Stay and ActorStaging.exit({ Exit = { Stay = true } }).Stay, "Exit = \"Stay\": se queda mientras miras")
check(ActorStaging.check({ Enter = "Puerta", Exit = { To = "Pasillo" } }) == nil and ActorStaging.check({ Enter = 3 }) ~= nil and ActorStaging.check({ Exit = { Hola = 1 } }) ~= nil, "el validador puede comprobar Enter y Exit")
local named = ActorStaging.places({ Enter = "Puerta", Exit = "Pasillo" })
check(#named == 2 and table.find(named, "Puerta") and table.find(named, "Pasillo"), "y los lugares que nombran")

local plain = ActorStaging.exit({})
check(ActorStaging.exitMode(plain, { Distance = 10 }) == "Away", "cerca de ti y sin sitio: se aleja unos pasos")
check(ActorStaging.exitMode(plain, { Distance = 10, HasHome = true }) == "Home", "cerca de ti y con su sitio de siempre cerca: vuelve allí")
check(ActorStaging.exitMode(plain, { Distance = 500 }) == "Fade" and ActorStaging.exitMode(plain, {}) == "Fade", "lejos de ti (o sin ti): se desvanece, no hace falta el paseo")
check(ActorStaging.exitMode(plain, { Distance = 10, Mode = "Hunt" }) == "Fade" and ActorStaging.exitMode(plain, { Distance = 10, Enemy = true }) == "Fade", "los enemigos se desvanecen")
check(ActorStaging.exitMode(plain, { Distance = 10, Relocate = true }) == "Fade", "si va a aparecer lejos (otro sitio), aquí se desvanece")
check(ActorStaging.exitMode(ActorStaging.exit({ Exit = "Pasillo" }), { Distance = 10, HasHome = true }) == "WalkTo", "Exit = lugar manda sobre su sitio de siempre")
check(ActorStaging.exitMode(ActorStaging.exit({ Exit = "Stay" }), { Distance = 10 }) == "Stay", "Stay cerca de ti")

check(ActorStaging.stagger(1) == 0 and ActorStaging.stagger(2) > 0 and ActorStaging.stagger(3) > ActorStaging.stagger(2) and ActorStaging.stagger(50) <= ActorStaging.StaggerMax, "si se van varios, cada uno sale un poco después (no todos a la vez)")
local me = Vector3.new(0, 0, 0)
local a1 = ActorStaging.awayPoint(Vector3.new(5, 0, 0), me, 1)
local a2 = ActorStaging.awayPoint(Vector3.new(5, 0, 0), me, 2)
check((a1 - me).Magnitude > 5 + ActorStaging.AwayDistance * 0.8 and (a1 - Vector3.new(5, 0, 0)).Magnitude > ActorStaging.AwayDistance - 0.01, "se aleja de ti (no hacia ti)")
check((a1 - a2).Magnitude > 2, "y cada uno hacia un lado (no en fila)")
check(ActorStaging.awayPoint(Vector3.new(0, 0, 0), me, 1).Magnitude > 1, "aunque esté justo donde tú")

check(ActorStaging.needsDip(Vector3.new(0, 0, 0), Vector3.new(100, 0, 0)) and not ActorStaging.needsDip(Vector3.new(0, 0, 0), Vector3.new(3, 0, 0)), "un salto largo lleva fundido; un ajuste de un par de pasos, no")

-- A quién mira quien habla
local t, ack = ActorStaging.addressee({ Speaker = "Omar", To = "Sara" }, nil)
check(t == "Sara" and ack == nil, "To = \"Sara\": mira a Sara")
t = ActorStaging.addressee({ Speaker = "Omar", To = "Jugador" }, { Speaker = "Sara", Question = true, Since = 1 })
check(t == "Player", "To = \"Jugador\": te mira a ti aunque Sara le haya preguntado")
t = ActorStaging.addressee({ Speaker = "Omar" }, { Speaker = "Sara", Question = true, Since = 2 })
check(t == "Sara", "contesta a la pregunta de Sara: mira a Sara (no a ti)")
local ackSeconds
t, ack, ackSeconds = ActorStaging.addressee({ Speaker = "Omar" }, { Speaker = "Sara", Question = false, Since = 2 })
check(t == "Player" and ack == "Sara" and ackSeconds > 0, "comenta lo que dijo Sara: la mira un momento y luego a ti")
t, ack = ActorStaging.addressee({ Speaker = "Omar" }, { Speaker = "Omar", Question = true, Since = 1 })
check(t == "Player" and ack == nil, "sigue hablando él: te mira a ti")
t = ActorStaging.addressee({ Speaker = "Omar" }, { Speaker = "Yo", IsPlayer = true, Question = true, Since = 1 })
check(t == "Player", "te contesta a ti")
t, ack = ActorStaging.addressee({ Speaker = "Omar" }, { Speaker = "Sara", Question = true, Since = 60 })
check(t == "Player" and ack == nil, "una pregunta de hace un minuto ya no cuenta")
check(ActorStaging.isQuestion("Ask", nil) and ActorStaging.isQuestion("Calm", "¿Vienes?") and ActorStaging.isQuestion(nil, "«¿Y tú?»") and not ActorStaging.isQuestion("Calm", "Ven."), "sabe cuándo es una pregunta")

---------------------------------------------------------------------
print("\n▶ 2. Emociones (ActorMoods + Emotion): la tabla del encargo, sin exagerar")
---------------------------------------------------------------------
local ActorMoods = L.load("src/shared/LifeStory/ActorMoods")
local Emotion = L.load("src/shared/LifeStory/Emotion")
local TABLE = { Alegria = "Joy", Tristeza = "Sad", Enfado = "Angry", Sorpresa = "Surprise", Nervios = "Nervous", ["Vergüenza"] = "Shame" }
for alias, name in TABLE do
	check(ActorMoods.name(alias) == name and ActorMoods.valid(name), ("%s = %s"):format(alias, name))
end
check(ActorMoods.name("Verguenza") == "Shame" and ActorMoods.name("Nerviosa") == "Nervous" and ActorMoods.name("Triste") == "Sad", "más alias en español")
for name, mood in ActorMoods.List do
	local a = ActorMoods.acting(name)
	check(a.Tempo >= 0.6 and a.Tempo <= 1.35 and math.abs(a.Head) <= 0.22 and math.abs(a.Open) <= 0.7 and a.Fidget <= 1 and a.Recoil <= 1.5, name .. ": sutil (ritmo, cabeza, postura y paso atrás con medida)")
	if mood.Pose then
		check(Emotion.Poses[mood.Pose] or ActorMoods.ExtraPoses[mood.Pose], name .. ": su postura la entiende ActorLife")
	end
end
local joy, sad, angry, surprise, nervous, shame = ActorMoods.acting("Joy"), ActorMoods.acting("Sad"), ActorMoods.acting("Angry"), ActorMoods.acting("Surprise"), ActorMoods.acting("Nervous"), ActorMoods.acting("Shame")
check(joy.Tempo > 1 and joy.Open > 0, "alegría: movimientos rápidos, postura abierta")
check(sad.Tempo < 1 and sad.Head < 0 and sad.Open < 0 and sad.Gaze == "Down", "tristeza: cabeza baja, movimientos lentos, postura cerrada")
check(angry.Tempo > 1 and angry.Gaze == "Hold", "enfado: movimientos bruscos, sostiene la mirada")
check(surprise.Recoil > 0 and surprise.Recoil < 1.5, "sorpresa: retrocede (poco) y se para")
check(nervous.Gaze == "Around" and nervous.Fidget > 0, "nervios: mira alrededor, se toca las manos, cambia el peso de pierna")
check(shame.Gaze == "Avoid" and shame.Head < 0, "vergüenza: evita la mirada, baja la cabeza")
check(ActorMoods.acting(nil).Tempo == 1 and ActorMoods.acting("Volar").Gaze == nil, "sin emoción (o una que no existe): normal")
check(ActorMoods.fromPose("Ashamed") == "Shame" and ActorMoods.fromPose("Nervous") == "Nervous" and ActorMoods.fromPose("Happy") == "Joy" and ActorMoods.fromPose("Calm") == nil, "la emoción de la frase actúa igual que la que dura")
check(Emotion.valid("Nervous") and Emotion.valid("Ashamed"), "las frases pueden pedir A = \"Nervous\" / \"Ashamed\"")
check(Emotion.of({ S = "Mateo", T = "Y-yo… no sé si esto es buena idea." }) == "Nervous", "tartamudear = nervios")
check(Emotion.of({ S = "Mateo", T = "Es que… no lo he hecho a propósito." }) == "Nervous", "«Es que…» = nervios")
check(Emotion.of({ S = "Lucía", T = "Me da vergüenza decirlo." }) == "Ashamed" and Emotion.of({ S = "Bruno", T = "Fue culpa mía." }) == "Ashamed", "«Me da vergüenza», «fue culpa mía» = vergüenza")
check(Emotion.of({ S = "Nico", T = "¡Hola, {nombre}!" }) == "Wave" and Emotion.of({ S = "Abu", T = "Lo siento mucho, cariño." }) == "Sad" and Emotion.of({ S = "Sara", T = "¿Vienes?" }) == "Ask" and Emotion.of({ S = "Nico", T = "Es un día normal." }) == "Calm", "lo de antes sigue igual (saluda, triste, pregunta, tranquilo)")

---------------------------------------------------------------------
print("\n▶ 3. SceneService de verdad: entrar, salir y saltar")
---------------------------------------------------------------------
-- Tiempos cortos para la prueba (los mismos caminos que en el juego)
ActorStaging.LeaveSeconds = 1.2
ActorStaging.LeaveToSeconds = 1.6
ActorStaging.FadeSeconds = 0.05
ActorStaging.Stagger = 0.15
ActorStaging.StaggerMax = 0.6
ActorStaging.StaySeconds = 1.5

local SceneService = loadWithExtras("src/server/Services/SceneService")
SceneService.init()
local stories = workspaceRoot:FindFirstChild("StoryScenes")
check(stories ~= nil, "la carpeta de las escenas existe")

local player = L.player("Prueba", 101)
player.Parent = true
local character = figure()
character.Name = "Prueba"
character.Parent = workspaceRoot
player.Character = character
character:PivotTo(CFrame.new(0, 3, 10))
table.insert(playerList, player)
player:SetAttribute("StoryFocus", "Q1")

local function folderOf(p)
	return stories:FindFirstChild("Scene_" .. p.UserId)
end
local function modelsOf(p, npc)
	local list = {}
	local f = folderOf(p)
	for _, m in if f then f:GetChildren() else {} do
		if m:GetAttribute("NpcId") == npc then
			table.insert(list, m)
		end
	end
	return list
end
local function liveOf(p, npc)
	for _, m in modelsOf(p, npc) do
		if not m:GetAttribute("Leaving") then
			return m
		end
	end
	return nil
end
local function settle(seconds)
	local t0 = os.clock()
	while os.clock() - t0 < seconds do
		SceneService.tick()
		task.wait(0.05)
	end
end
local function waitQueue()
	-- (las escenas se montan en una cola: se espera a que esté hecha)
	task.wait(0.05)
	settle(0.15)
end

-- Paso 1: tres compañeros en el patio
local CAST = { "Nico", "Sara", "Omar" }
local step1 = {}
for i, npc in CAST do
	table.insert(step1, { Npc = npc, Place = "Patio", Offset = Vector3.new(i * 3, 0, 0) })
end
SceneService.set(player, "Q1", step1, {}, nil)
waitQueue()
check(liveOf(player, "Nico") and liveOf(player, "Sara") and liveOf(player, "Omar"), "paso 1: los tres en el patio")
local nico = liveOf(player, "Nico")
check(nico and nico.HumanoidRootPart:FindFirstChildOfClass("ProximityPrompt") ~= nil, "con su botón de hablar")

-- Paso 2: sin reparto (antes se borraban todos a la vez, de golpe)
SceneService.set(player, "Q1", {}, {}, nil)
waitQueue()
check(#modelsOf(player, "Nico") == 1 and #modelsOf(player, "Sara") == 1 and #modelsOf(player, "Omar") == 1, "paso sin reparto: NO desaparecen de golpe (siguen en el mapa yéndose)")
check(nico and nico.Parent ~= nil and nico:GetAttribute("Leaving") == true, "están marcados como que se van (el cliente no les habla ni les hace mirar)")
check(nico and nico.HumanoidRootPart:FindFirstChildOfClass("ProximityPrompt") == nil, "sin botón: ya no se les puede hablar")
check(SceneService.actorOf(player, "Nico") == nil and not SceneService.hasActor(player, "Q1", "Nico"), "ya no son del reparto (la historia no los busca)")
local startTimes = {}
for _, npc in CAST do
	local m = modelsOf(player, npc)[1]
	local leaver = m and SceneService._leaving[player] and SceneService._leaving[player][m]
	startTimes[npc] = leaver and leaver.Leaving.StartAt or 0
end
local distinct = {}
for _, v in startTimes do
	distinct[string.format("%.2f", v)] = true
end
local count = 0
for _ in distinct do
	count += 1
end
check(count == 3, "cada uno echa a andar en un momento distinto (escalonados)")
settle(0.9)
local walked = nico and nico.Parent and (nico.HumanoidRootPart.Position - Vector3.new(3, 3, 0)).Magnitude > 4
check(walked or (nico and not nico.Parent), "se van andando (se alejan de su sitio)")
local away = nico and nico.Parent and nico.HumanoidRootPart.Position
if away then
	local me = character.HumanoidRootPart.Position
	check((away - me).Magnitude > (Vector3.new(3, 3, 0) - me).Magnitude, "y se alejan de ti, no hacia ti")
end
settle(2.2)
check(#modelsOf(player, "Nico") == 0 and #modelsOf(player, "Sara") == 0 and #modelsOf(player, "Omar") == 0, "al final se desvanecen y se quitan")
check(SceneService._leaving[player] == nil, "y no queda nadie colgado en la lista de los que se van")

-- Vuelve a necesitarle mientras se va: se da la vuelta (no sale otro)
SceneService.set(player, "Q1", { { Npc = "Nico", Place = "Patio" } }, {}, nil)
waitQueue()
local first = liveOf(player, "Nico")
SceneService.set(player, "Q1", {}, {}, nil)
waitQueue()
check(first and first:GetAttribute("Leaving") == true, "Nico se va…")
SceneService.set(player, "Q1", { { Npc = "Nico", Place = "Comedor" } }, {}, nil)
waitQueue()
check(#modelsOf(player, "Nico") == 1 and liveOf(player, "Nico") == first, "…y el paso siguiente le necesita: es el mismo Nico que vuelve (nunca dos)")
check(first and first:GetAttribute("Leaving") == nil and first:GetAttribute("FadeOut") == nil, "vuelve a ser del reparto (y se ve)")
check(first and first.HumanoidRootPart:FindFirstChildOfClass("ProximityPrompt") ~= nil and SceneService.hasActor(player, "Q1", "Nico"), "con su botón otra vez")
settle(1.5)
check(first and (first.HumanoidRootPart.Position - Vector3.new(0, 3, -20)).Magnitude < 4, "y va andando a su sitio nuevo")

-- Lejos de ti: se desvanece (no hace falta el paseo)
SceneService.set(player, "Q1", { { Npc = "Nico", Place = "Comedor" }, { Npc = "Sara", Place = "Lejos" } }, {}, nil)
waitQueue()
local sara = liveOf(player, "Sara")
SceneService.set(player, "Q1", { { Npc = "Nico", Place = "Comedor" } }, {}, nil)
waitQueue()
check(sara and sara:GetAttribute("FadeOut") == true, "lejos de ti: se desvanece en su sitio")
settle(0.4)
check(sara and sara.Parent == nil, "y se quita al acabar el fundido")

-- Exit = lugar: se va andando hasta allí
SceneService.set(player, "Q1", { { Npc = "Nico", Place = "Comedor" }, { Npc = "Omar", Place = "Patio", Exit = "Pasillo" } }, {}, nil)
waitQueue()
local omar = liveOf(player, "Omar")
SceneService.set(player, "Q1", { { Npc = "Nico", Place = "Comedor" } }, {}, nil)
waitQueue()
settle(0.5)
check(omar and (not omar.Parent or (omar.HumanoidRootPart.Position - Vector3.new(-40, 3, 0)).Magnitude < 5), "Exit = \"Pasillo\": se va andando hasta el pasillo")
settle(1.8)
check(omar and omar.Parent == nil, "y allí se desvanece")

-- Exit = "Fade" y Exit = "Stay"
SceneService.set(player, "Q1", { { Npc = "Nico", Place = "Comedor", Exit = "Stay" }, { Npc = "Sara", Place = "Patio", Exit = "Fade" } }, {}, nil)
waitQueue()
local nicoStay, saraFade = liveOf(player, "Nico"), liveOf(player, "Sara")
SceneService.set(player, "Q1", {}, {}, nil)
waitQueue()
check(saraFade and saraFade:GetAttribute("FadeOut") == true, "Exit = \"Fade\": se desvanece ya")
check(nicoStay and nicoStay.Parent and nicoStay:GetAttribute("FadeOut") == nil, "Exit = \"Stay\": se queda mientras estás cerca")
character:PivotTo(CFrame.new(0, 3, 300)) -- te vas lejos
settle(0.5)
check(nicoStay and nicoStay.Parent == nil, "y se va cuando te alejas")
character:PivotTo(CFrame.new(0, 3, 10))

-- Vuelve a su sitio de siempre en el mapa (el personaje fijo del mapa le «recoge»)
local staticNico = figure()
staticNico:SetAttribute("NpcId", "Nico")
staticNico:PivotTo(CFrame.new(-20, 3, 0))
staticNico.Parent = workspaceRoot
tagged.StaticNpc = { staticNico }
SceneService.set(player, "Q1", { { Npc = "Nico", Place = "Patio" } }, {}, nil)
waitQueue()
local sceneNico = liveOf(player, "Nico")
settle(1.2) -- (sale de donde está el de siempre y llega andando a su sitio)
SceneService.set(player, "Q1", {}, {}, nil)
waitQueue()
local info = sceneNico and SceneService._leaving[player] and SceneService._leaving[player][sceneNico]
check(info and info.Leaving.Mode == "Home", "sin Exit y con su sitio de siempre cerca: vuelve allí")
settle(1.5)
check(sceneNico and sceneNico.Parent == nil, "y al llegar se quita (sin parpadeo: allí ya está el de siempre)")
tagged.StaticNpc = {}

-- Enter = { From }: entra andando desde la puerta
SceneService.set(player, "Q1", { { Npc = "Sara", Place = "Patio", Enter = "Puerta" } }, {}, nil)
waitQueue()
local entering = liveOf(player, "Sara")
check(entering ~= nil, "Enter: aparece")
settle(1)
check(entering and (entering.HumanoidRootPart.Position - Vector3.new(0, 3, 0)).Magnitude < 4, "Enter = \"Puerta\": llega andando a su sitio")
SceneService.set(player, "Q1", {}, {}, nil)
waitQueue()
settle(2)
-- (con Delay: espera en la puerta y luego entra)
SceneService.set(player, "Q1", { { Npc = "Omar", Place = "Patio", Enter = { From = "Puerta", Delay = 0.6 } } }, {}, nil)
waitQueue()
local late = liveOf(player, "Omar")
check(late and (late.HumanoidRootPart.Position - Vector3.new(0, 3, 30)).Magnitude < 4, "Enter con Delay: empieza en la puerta")
settle(0.25)
check(late and (late.HumanoidRootPart.Position - Vector3.new(0, 3, 30)).Magnitude < 4, "y espera…")
settle(1.2)
check(late and (late.HumanoidRootPart.Position - Vector3.new(0, 3, 0)).Magnitude < 4, "…y luego entra hasta su sitio")
-- (Enter desde un lugar que no existe: aparece en su sitio, como siempre)
SceneService.set(player, "Q1", { { Npc = "Omar", Place = "Patio", Enter = { From = "Puerta", Delay = 0.6 } }, { Npc = "Nico", Place = "Comedor", Enter = "NoExiste" } }, {}, nil)
waitQueue()
local noDoor = liveOf(player, "Nico")
check(noDoor and (noDoor.HumanoidRootPart.Position - Vector3.new(0, 3, -20)).Magnitude < 4, "Enter desde un sitio que no está en el mapa: aparece en su sitio (no se pierde)")

-- Mood: la emoción que dura llega al cliente; la sorpresa da un paso atrás
SceneService.set(player, "Q1", { { Npc = "Omar", Place = "Patio", Mood = "Nervios" }, { Npc = "Nico", Place = "Comedor", Mood = "Sorpresa" } }, {}, nil)
waitQueue()
check(late and late:GetAttribute("Mood") == "Nervous", "Mood = \"Nervios\" → atributo Mood = Nervous (ActorLife)")
check(noDoor and noDoor:GetAttribute("Mood") == "Surprise", "Mood = \"Sorpresa\" → Surprise")
check(noDoor and (noDoor.HumanoidRootPart.Position - Vector3.new(0, 3, -20)).Magnitude > 0.3, "la sorpresa: un paso atrás")
SceneService.set(player, "Q1", { { Npc = "Omar", Place = "Patio" }, { Npc = "Nico", Place = "Comedor" } }, {}, nil)
waitQueue()
check(late and late:GetAttribute("Mood") == nil, "sin Mood: se le quita")

-- Enemigos: se desvanecen
SceneService.set(player, "Q1", { { Npc = "Omar", Place = "Patio" }, { Npc = "Nico", Place = "Comedor" }, { Npc = "Sara", Place = "Patio", Mode = "Hunt", Enemy = true, Prompt = false } }, {}, nil)
waitQueue()
local enemy = liveOf(player, "Sara")
SceneService.set(player, "Q1", { { Npc = "Omar", Place = "Patio" }, { Npc = "Nico", Place = "Comedor" } }, {}, nil)
waitQueue()
check(enemy and enemy:GetAttribute("FadeOut") == true, "un enemigo que ya no está: se desvanece (no se pasea)")

-- Quitar la escena de una misión (terminada): también se van, no de golpe
SceneService.clear(player, "Q1")
waitQueue()
check(#modelsOf(player, "Omar") == 1 and liveOf(player, "Omar") == nil, "misión terminada: su gente se va (no desaparece de golpe)")
settle(2.5)
check(#modelsOf(player, "Omar") == 0 and #modelsOf(player, "Nico") == 0, "y al rato ya no están")

-- Dos jugadores: lo de uno no toca al otro
local other = L.player("Otra", 202)
other.Parent = true
local otherChar = figure()
otherChar.Parent = workspaceRoot
other.Character = otherChar
otherChar:PivotTo(CFrame.new(0, 3, 12))
table.insert(playerList, other)
other:SetAttribute("StoryFocus", "Q2")
SceneService.set(player, "Q1", { { Npc = "Nico", Place = "Patio" } }, {}, nil)
SceneService.set(other, "Q2", { { Npc = "Nico", Place = "Patio" } }, {}, nil)
waitQueue()
local mine, theirs = liveOf(player, "Nico"), liveOf(other, "Nico")
SceneService.set(player, "Q1", {}, {}, nil)
waitQueue()
check(mine and mine:GetAttribute("Leaving") and theirs and not theirs:GetAttribute("Leaving"), "multijugador: el Nico que se va es el tuyo; el de la otra jugadora sigue")
-- Sale del juego: todo lo suyo se borra ya (también lo que se estaba yendo)
removing:Fire(player)
check(mine and mine.Parent == nil and folderOf(player) == nil, "sales del juego: tus actores (también los que se iban) se quitan ya")
check(theirs and theirs.Parent ~= nil, "y los de la otra jugadora siguen")
table.remove(playerList, table.find(playerList, player))

-- El salto del jugador: con fundido (SceneDip) si es largo
local jumper = other
local before = jumper:GetAttribute("SceneDip")
SceneService.teleport(jumper, "Lejos")
check((jumper:GetAttribute("SceneDip") or 0) == (before or 0) + 1, "un salto de la historia (teleport) lleva fundido: SceneDip")
check((otherChar.HumanoidRootPart.Position - Vector3.new(400, 3, 0)).Magnitude < 5, "y el salto se hace en el acto (la historia no espera)")
before = jumper:GetAttribute("SceneDip")
SceneService.teleport(jumper, { Place = "Lejos", Offset = Vector3.new(2, 0, 0) })
check(jumper:GetAttribute("SceneDip") == before, "un ajuste de un par de pasos no lleva fundido")
SceneService.teleport(jumper, "Patio", { Dip = false })
check(jumper:GetAttribute("SceneDip") == before, "Dip = false: sin fundido (quien ya tapa el salto con lo suyo)")
SceneService.teleportTo(jumper, Vector3.new(0, 0, 200))
check(jumper:GetAttribute("SceneDip") == before, "teleportTo sin opciones: como siempre (cárcel, hospital, edificios… tienen lo suyo)")
SceneService.teleport(jumper, "Pasillo", { Lead = 0.3 })
check(jumper:GetAttribute("SceneDip") == before + 1 and jumper:GetAttribute("SceneDipLead") == 0.3, "Lead: primero se oscurece…")
check((otherChar.HumanoidRootPart.Position - Vector3.new(0, 3, 200)).Magnitude < 5, "…sin saltar todavía…")
task.wait(0.45)
check((otherChar.HumanoidRootPart.Position - Vector3.new(-40, 3, 0)).Magnitude < 5, "…y salta a negro")

---------------------------------------------------------------------
print("\n▶ 4. El cliente tiene lo que hace falta (ActorLife, SceneDip)")
---------------------------------------------------------------------
local life = fs.readFile("src/client/Controllers/ActorLife.luau")
local dip = fs.readFile("src/client/Controllers/SceneDip.luau")
local scene = fs.readFile("src/server/Services/SceneService.luau")
local function has(src, fragment)
	return string.find(src, fragment, 1, true) ~= nil
end
check(has(life, "local function inTalk(") and has(life, "ActorStaging.GroupRadius") and has(life, "isMine(rig.Model)"), "todo el reparto de tu escena que está cerca mira a quien habla (no solo quien ya habló)")
check(has(life, "ActorStaging.addressee(") and has(life, "function ActorLife.speak(model: Instance?, emotion: string?, seconds: number, gesture: string?, to: any?, text: string?)"), "speak acepta To (a quién habla) y deduce a quién contesta")
check(not has(life, "			else\n				target = myHead\n			end"), "quien habla ya no te mira SIEMPRE a ti")
check(has(life, "listenGlance(") and has(life, "rig.NodAt") and has(life, "moodActing.Fidget"), "escuchando: asienten, apartan la vista un instante, cambian el peso de pierna")
check(has(life, "\"Nervous\", \"Ashamed\"") and has(life, "P.Nervous") and has(life, "P.Ashamed"), "posturas de nervios y vergüenza")
check(has(life, "GetAttributeChangedSignal(\"FadeOut\")") and has(life, "isLeaving(model)"), "los que se van se desvanecen y ya no cuentan (ni find ni cast)")
check(has(life, "require(script.Parent.SceneDip).init()"), "ActorLife arranca SceneDip")
check(has(dip, "ActorStaging.DipMax") and has(dip, "ResetOnSpawn = false") and has(dip, "CharacterAdded") and has(dip, "InCinematic"), "SceneDip: la pantalla vuelve siempre (tope de tiempo, al reaparecer) y no pisa una cinemática")
check(not has(dip, "Controls"), "SceneDip no bloquea los controles (no hay nada que devolver)")
check(not has(scene, "		if not wanted[npc] then\n			actor.Model:Destroy()"), "SceneService: ya no borra de golpe a quien sobra")

if L.failures > 0 then
	for _, w in L.warnings do
		print("  (aviso) " .. w)
	end
end
L.finish("test-actors")
process.exit(0)
