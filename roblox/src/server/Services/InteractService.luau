-- InteractService: los muebles de dentro de los edificios se usan (reglas en shared/Interact).
--
--   * Cada vez que se monta una sala (InteriorService.onBuilt) pone un cartel "pulsa E" en cada
--     cosa con la etiqueta "Interact": sentarse, tumbarse o dormir, tele, luces, nevera, grifos,
--     ducha, puertas, armarios, ordenador, piano y ventanas. Los carteles salen solo de cerca.
--   * Lo que cambia (tele encendida, luces, puertas abiertas, agua) se ve para todos: lo cambia el
--     servidor. El cliente pone el sonido, la imagen de la tele y la postura (UseMotion).
--   * La postura del personaje va en su atributo UsePose ("Sit", "Sofa", "Lie", "Tap", "Fridge",
--     "Shower", "Type", "Piano", "Window") y UseAt (hacia dónde mira); todos la ven.
--   * Dueños (PropertyService.access): en tu casa todo (dormir recupera energía, picar algo de la
--     nevera con límite); en la de otro jugador, si no estás invitado (grupo), solo lo inofensivo
--     (sentarse, luces, puertas, mirar). En las tiendas y bares la nevera es de bebidas que se pagan.
--   * Dependientes: en cada ClerkSpot de las tiendas y mostradores se pone una persona.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Interact = require(ReplicatedStorage.Shared.Interact)
local Floors = require(ReplicatedStorage.Shared.Floors)
local Format = require(ReplicatedStorage.Shared.Format)
local Builder = require(script.Parent.Parent.World.Builder)
local Npc = require(script.Parent.Parent.World.Npc)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)
local InteriorService = require(script.Parent.InteriorService)

local InteractService = {}

local Notify: RemoteEvent
local Remote: RemoteEvent

type Use = {
	Pose: string,
	Part: BasePart,
	Seat: Seat?,
	Seconds: number?,
	At: Vector3?,
	Spot: Vector3?,
	Room: Instance?,
	OnEnd: (() -> ())?,
	Connections: { RBXScriptConnection },
	Stand: CFrame?, -- (tumbado) dónde se pone de pie al levantarse
}

local using: { [Player]: Use } = {}
local snacks: { [Player]: number } = {} -- último bocado de la nevera de casa
local DOOR_TIME = 0.45

---------------------------------------------------------------------
-- Ayudas
---------------------------------------------------------------------
local function rootOf(player: Player): (Humanoid?, BasePart?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return humanoid, root
end

-- La sala (Model "Interior_…") donde está esa pieza
local function roomModel(part: Instance): Model?
	local node: Instance? = part
	while node and node ~= workspace do
		if node:IsA("Model") and string.sub(node.Name, 1, 9) == "Interior_" then
			return node
		end
		node = node.Parent
	end
	return nil
end

local function instanceOf(part: Instance): InteriorService.Instance_?
	local model = roomModel(part)
	local key = model and model:GetAttribute("Key")
	return if type(key) == "string" then InteriorService.fromKey(key) else nil
end

-- Qué es esta sala para el jugador (shared/Interact: Owner, Guest, Stranger, Neighbor, ForSale, Public)
function InteractService.accessOf(player: Player, inst: InteriorService.Instance_?): string
	if not inst then
		return "Public"
	end
	if (inst.Room :: any).Kind == "Dorm" then
		-- Habitación de la residencia: la tuya o la de otro estudiante
		local key = inst.Building.Key .. "#" .. Floors.unitId(inst.Floor, inst.Unit)
		return if player:GetAttribute("DormUnit") == key then "Owner" else "Stranger"
	end
	local ok, PropertyService = pcall(function()
		return require(script.Parent.PropertyService) :: any
	end)
	if ok and PropertyService and PropertyService.access then
		local got, access = pcall(PropertyService.access, player, inst.Building, inst.Floor, inst.Unit)
		if got and type(access) == "string" then
			return access
		end
	end
	return "Public"
end

local function kindOf(inst: InteriorService.Instance_?): string?
	return inst and (inst.Room :: any).Kind
end

-- La pieza de la puerta de la nevera, del armario… (las que tienen bisagra) dentro de ese mueble
local function doorsOf(model: Instance): { BasePart }
	local list = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and typeof(d:GetAttribute("Hinge")) == "CFrame" then
			table.insert(list, d)
		end
	end
	return list
end

local function tween(part: BasePart, goal: CFrame, seconds: number)
	local ok = pcall(function()
		TweenService:Create(part, TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = goal }):Play()
	end)
	if not ok then
		part.CFrame = goal
	end
end

-- Cada hoja recuerda su ángulo y su giro en marcha (si la vuelves a pulsar a medio abrir, sigue desde ahí)
type Swinging = { Angle: NumberValue, Tween: Tween?, Parts: { { Part: BasePart, Closed: CFrame } }, Hinge: CFrame }
local swinging: { [BasePart]: Swinging } = setmetatable({}, { __mode = "k" }) :: any

-- Abre o cierra una hoja con bisagra (y lo que va pegado a ella: pomo, tirador, imanes).
-- Se anima el ángulo, no el CFrame: si no, la hoja iba en línea recta de cerrada a abierta y el
-- canto de la bisagra atravesaba la pared (se deslizaba en vez de girar)
local function swing(door: BasePart, open: boolean, seconds: number?)
	local hinge = door:GetAttribute("Hinge") :: CFrame
	local closed = door:GetAttribute("Closed") :: CFrame
	local angle = door:GetAttribute("Swing") or math.rad(95)
	if typeof(hinge) ~= "CFrame" or typeof(closed) ~= "CFrame" then
		return
	end
	local wasOpen = door:GetAttribute("Open") == true
	door:SetAttribute("Open", open)
	local parts = { { Part = door, Closed = closed } }
	local parent = door.Parent
	if parent then
		for _, follower in parent:GetDescendants() do
			if follower:IsA("BasePart") and follower:GetAttribute("FollowDoor") == door.Name then
				local base = follower:GetAttribute("ClosedAt")
				if typeof(base) ~= "CFrame" then
					base = follower.CFrame
					follower:SetAttribute("ClosedAt", base)
				end
				table.insert(parts, { Part = follower, Closed = base :: CFrame })
			end
		end
	end
	local state = swinging[door]
	if not state then
		local value = Instance.new("NumberValue")
		-- (la primera vez parte de donde esté: cerrada, o abierta si ya lo estaba)
		value.Value = if wasOpen then angle else 0
		local new: Swinging = { Angle = value, Tween = nil, Parts = parts, Hinge = hinge }
		value:GetPropertyChangedSignal("Value"):Connect(function()
			local a = value.Value
			-- (en 0, justo su CFrame de cerrada, sin decimales de más)
			local turn = if a == 0 then CFrame.identity else new.Hinge * CFrame.Angles(0, a, 0) * new.Hinge:Inverse()
			for _, entry in new.Parts do
				entry.Part.CFrame = turn * entry.Closed
			end
		end)
		swinging[door] = new
		state = new
	end
	state.Parts = parts
	state.Hinge = hinge
	if state.Tween then
		local running = state.Tween
		pcall(function()
			running:Cancel()
		end)
		state.Tween = nil
	end
	local target = if open then angle else 0
	-- Al final, justo donde se ponía antes (cerrada = su CFrame de cerrada exacto, sin decimales de más)
	local function settle()
		local turn = if open then hinge * CFrame.Angles(0, angle, 0) * hinge:Inverse() else CFrame.identity
		for _, entry in parts do
			entry.Part.CFrame = turn * entry.Closed
		end
	end
	local time = seconds or DOOR_TIME
	local ok = time > 0
		and pcall(function()
			local t = TweenService:Create(state.Angle, TweenInfo.new(time, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Value = target })
			state.Tween = t
			t.Completed:Connect(function(status)
				if status == Enum.PlaybackState.Completed and state.Tween == t then
					state.Tween = nil
					settle()
				end
			end)
			t:Play()
		end)
	if not ok then
		state.Tween = nil
		state.Angle.Value = target
		settle()
	end
end
InteractService.swing = swing

local function promptOf(part: Instance): ProximityPrompt?
	local p = part:FindFirstChild("InteractPrompt")
	return if p and p:IsA("ProximityPrompt") then p else nil
end

local function setText(part: BasePart, text: string)
	local prompt = promptOf(part)
	if prompt then
		prompt.ActionText = text
	end
end

---------------------------------------------------------------------
-- Posturas (UsePose) y fin de cada uso
---------------------------------------------------------------------
function InteractService.stop(player: Player)
	local use = using[player]
	if not use then
		return
	end
	using[player] = nil
	for _, connection in use.Connections do
		connection:Disconnect()
	end
	if use.OnEnd then
		local ok, err = pcall(use.OnEnd)
		if not ok then
			warn("[Muebles] " .. tostring(err))
		end
	end
	player:SetAttribute("UsePose", nil)
	player:SetAttribute("UseAt", nil)
	player:SetAttribute("UseSpot", nil)
end

local function start(player: Player, use: Use)
	InteractService.stop(player)
	using[player] = use
	-- (primero hacia dónde y dónde: el cliente los lee al cambiar UsePose)
	player:SetAttribute("UseAt", use.At)
	player:SetAttribute("UseSpot", use.Spot)
	player:SetAttribute("UsePose", use.Pose)
	local humanoid = rootOf(player)
	if use.Seat and humanoid then
		-- Al levantarse del asiento (saltar) se acaba
		local seat = use.Seat
		table.insert(use.Connections, seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			if seat.Occupant ~= humanoid and using[player] == use then
				InteractService.stop(player)
			end
		end))
	end
	if humanoid then
		table.insert(use.Connections, humanoid.Died:Connect(function()
			if using[player] == use then
				InteractService.stop(player)
			end
		end))
	end
	-- Salir de la sala (ascensor, puerta, reaparecer) lo acaba
	table.insert(use.Connections, player:GetAttributeChangedSignal("InteriorKey"):Connect(function()
		if using[player] == use then
			InteractService.stop(player)
		end
	end))
	if use.Seconds then
		task.delay(use.Seconds, function()
			if using[player] == use then
				InteractService.stop(player)
			end
		end)
	end
end

function InteractService.poseOf(player: Player): string?
	local use = using[player]
	return use and use.Pose
end

---------------------------------------------------------------------
-- Cada cosa
---------------------------------------------------------------------
local actions: { [string]: (Player, BasePart, InteriorService.Instance_?, string) -> () } = {}

-- Sentarse: el asiento de verdad (Seat) de ese mueble más cercano y libre
local function freeSeat(part: BasePart, from: Vector3): Seat?
	if part:IsA("Seat") then
		return if part.Occupant == nil and not part:GetAttribute("Taken") then part else nil
	end
	local function nearest(list: { Instance }, limit: number): Seat?
		local best, bestDistance = nil, limit
		for _, d in list do
			if d:IsA("Seat") and d.Occupant == nil and not d:GetAttribute("Taken") then
				local distance = (d.Position - from).Magnitude
				if distance < bestDistance then
					best, bestDistance = d, distance
				end
			end
		end
		return best
	end
	-- Los asientos de ese mueble; si no tiene (un ordenador sin silla), un taburete de al lado
	local mine = (part.Parent or part):GetDescendants()
	for _, d in mine do
		if d:IsA("Seat") then
			return nearest(mine, math.huge) -- (tiene asientos: el más cercano libre, o ninguno)
		end
	end
	local room = roomModel(part)
	if room then
		local near = {}
		for _, d in room:GetDescendants() do
			if d:IsA("Seat") and (d.Position - part.Position).Magnitude < 5 then
				table.insert(near, d)
			end
		end
		return nearest(near, math.huge)
	end
	return nil
end

local function sitOn(player: Player, part: BasePart, pose: string, onEnd: (() -> ())?): Seat?
	local humanoid, root = rootOf(player)
	if not humanoid or not root then
		return nil
	end
	local seat = freeSeat(part, root.Position)
	if not seat then
		Notify:FireClient(player, "Error", "🪑 Está ocupado.")
		return nil
	end
	if humanoid.SeatPart then
		humanoid.Sit = false
	end
	seat:Sit(humanoid)
	local model = seat.Parent
	local soft = model and (model.Name == "Sofa" or model.Name == "Armchair")
	start(player, { Pose = if pose == "Sit" and soft then "Sofa" else pose, Part = part, Seat = seat, At = part.Position, OnEnd = onEnd, Connections = {} })
	return seat
end

actions.Sit = function(player, part)
	sitOn(player, part, "Sit")
end

-- Tumbarse en la cama (el cuerpo se tumba boca arriba con la cabeza en la almohada)
local function lieFrame(mattress: BasePart, scale: number): (CFrame, CFrame)
	local cf = mattress.CFrame
	local up = Vector3.new(0, 1, 0)
	local toPillow = -cf.LookVector -- (el cabecero está hacia +Z del colchón)
	local right = toPillow:Cross(-up)
	local top = cf.Position + up * (mattress.Size.Y / 2 + 0.55 * scale)
	local along = mattress.Size.Z / 2 - 2.7 * scale
	local lying = CFrame.fromMatrix(top + toPillow * along, right, toPillow)
	-- De pie, a un lado de la cama, mirando hacia fuera (el colchón está a unos 1,6 del suelo)
	local side = cf.Position + cf.RightVector * (mattress.Size.X / 2 + 2.2)
	local floorY = cf.Position.Y - 1.65
	local stand = CFrame.new(Vector3.new(side.X, floorY + 3 * scale, side.Z)) * CFrame.Angles(0, math.atan2(-cf.RightVector.X, -cf.RightVector.Z), 0)
	return lying, stand
end
InteractService.lieFrame = lieFrame

local function standUp(player: Player, stand: CFrame)
	local humanoid, root = rootOf(player)
	player:SetAttribute("Sleeping", nil)
	pcall(function()
		(require(script.Parent.SleepService) :: any).leaveBed(player)
	end)
	if root then
		if (root.Position - stand.Position).Magnitude < 15 then
			-- Se incorpora junto a la cama (si se ha ido a otra sala, no se le trae de vuelta)
			tween(root, stand, 0.5)
			task.delay(0.5, function()
				if root.Parent and not using[player] then
					root.Anchored = false
				end
			end)
		else
			root.Anchored = false
		end
	end
	if humanoid then
		humanoid.PlatformStand = false
	end
end

local function sleepNow(player: Player, use: Use)
	if player:GetAttribute("Sleeping") then
		return
	end
	player:SetAttribute("Sleeping", true)
	Notify:FireClient(player, "Sleep", "Zzz...")
	-- La noche la lleva SleepService (una sola lista de quién duerme y una sola hora de noche y de
	-- despertar): mientras siga tumbado en esta cama, cuenta como dormido
	task.delay(Config.SleepSeconds * 0.6, function()
		if using[player] ~= use then
			return
		end
		pcall(function()
			(require(script.Parent.SleepService) :: any).restInBed(player, function()
				return player.Parent ~= nil and using[player] == use
			end)
		end)
	end)
	task.delay(Config.SleepSeconds, function()
		if player.Parent and using[player] == use then
			player:SetAttribute("Sleeping", nil)
			NeedsService.change(player, 0, Interact.SleepEnergy)
			Notify:FireClient(player, "Success", "🛏 Has dormido genial. ¡Energía al máximo! (Salta para levantarte.)")
			StoryEvents.emit(player, "Slept", {})
		end
	end)
end

actions.Bed = function(player, part, _inst, access)
	local humanoid, root = rootOf(player)
	if not humanoid or not root then
		return
	end
	if humanoid.SeatPart then
		humanoid.Sit = false
	end
	local scale = 1
	pcall(function()
		scale = (player.Character :: Model):GetScale()
	end)
	local lying, stand = lieFrame(part, scale)
	humanoid.PlatformStand = true
	root.Anchored = true
	root.AssemblyLinearVelocity = Vector3.zero
	tween(root, lying, 0.6)
	local use: Use
	use = {
		Pose = "Lie",
		Part = part,
		At = part.Position,
		Connections = {},
		Stand = stand,
		OnEnd = function()
			standUp(player, stand)
		end,
		Seconds = 180, -- (como mucho tres minutos tumbado)
	}
	start(player, use)
	if Interact.canSleep(access) then
		sleepNow(player, use)
	else
		Notify:FireClient(player, "Info", "🛏 Te tumbas un rato. Para dormir y recuperar energía, en tu casa. (Salta para levantarte.)")
	end
end

actions.TV = function(_player, part)
	local on = not part:GetAttribute("On")
	part:SetAttribute("On", on)
	if on then
		local channel = Interact.nextChannel(part:GetAttribute("Channel"))
		part:SetAttribute("Channel", channel)
		local c = Interact.Channels[channel].Colors[1]
		part.Color = Color3.fromRGB(c[1], c[2], c[3])
		part.Material = Enum.Material.Neon
	else
		part.Color = Color3.fromRGB(12, 14, 18)
		part.Material = Enum.Material.Glass
	end
	setText(part, Interact.actionText("TV", on))
end

-- Luces de una habitación (todas las RoomLight con ese Room en la sala)
function InteractService.setLights(model: Instance, room: string, on: boolean)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d:HasTag("RoomLight") and d:GetAttribute("Room") == room then
			for _, light in d:GetChildren() do
				if light:IsA("PointLight") or light:IsA("SpotLight") or light:IsA("SurfaceLight") then
					light.Enabled = on
				end
			end
			local color = d:GetAttribute("OnColor")
			if on then
				local material = d:GetAttribute("OnMaterial")
				d.Material = (Enum.Material :: any)[material] or Enum.Material.Neon
				if typeof(color) == "Color3" then
					d.Color = color
				end
			else
				d.Material = Enum.Material.SmoothPlastic
				if typeof(color) == "Color3" then
					d.Color = color:Lerp(Color3.fromRGB(60, 60, 64), 0.55)
				end
			end
			d:SetAttribute("Lit", on)
		elseif d:IsA("BasePart") and d:GetAttribute("Use") == "Light" and d:GetAttribute("Room") == room then
			d:SetAttribute("On", on)
			setText(d, Interact.actionText("Light", on))
		end
	end
end

actions.Light = function(_player, part)
	local model = roomModel(part)
	local room = part:GetAttribute("Room")
	if not model or type(room) ~= "string" then
		return
	end
	InteractService.setLights(model, room, part:GetAttribute("On") == false)
end

actions.Door = function(_player, part)
	local open = not part:GetAttribute("Open")
	swing(part, open)
	setText(part, Interact.actionText("Door", open))
end

actions.Wardrobe = function(_player, part)
	local open = not part:GetAttribute("Open")
	part:SetAttribute("Open", open)
	for _, door in doorsOf(part.Parent or part) do
		swing(door, open)
	end
	setText(part, Interact.actionText("Wardrobe", open))
end

actions.Fridge = function(player, part, inst, access)
	local model = part.Parent or part
	local doors = doorsOf(model)
	for _, door in doors do
		swing(door, true, 0.5)
	end
	local info = Interact.Uses.Fridge
	start(player, {
		Pose = "Fridge",
		Part = part,
		At = part.Position,
		Seconds = info.Seconds,
		Connections = {},
		OnEnd = function()
			for _, door in doors do
				swing(door, false, 0.5)
			end
		end,
	})
	-- Qué hay dentro para ti (FridgeService): gratis con tus padres en la etapa del colegio; desde la
	-- universidad, lo que hayas comprado y guardado; en las tiendas se paga; lo demás, solo mirar
	local FridgeService = require(script.Parent.FridgeService) :: any
	local ctx = FridgeService.context(player, part, inst, access, kindOf(inst))
	local mode = ctx.Mode
	if mode == "Stock" then
		FridgeService.show(player, ctx, part)
		return
	end
	if mode == "Free" then
		local now = os.clock()
		local ok, wait = Interact.canSnack(snacks[player], now)
		if not ok then
			Notify:FireClient(player, "Info", ("🍎 Aún estás masticando… (%d s)"):format(wait))
			return
		end
		snacks[player] = now
		NeedsService.change(player, Interact.Snack.Hunger, 0)
		Notify:FireClient(player, "Food", "🍎 Has picado algo de la nevera.")
		StoryEvents.emit(player, "Ate", { FoodId = "Nevera" })
	elseif mode == "Pay" then
		local drink = Interact.Drink
		if not DataService.spend(player, drink.Price) then
			Notify:FireClient(player, "Error", ("No tienes %s para la bebida."):format(Format.money(drink.Price)))
			return
		end
		NeedsService.change(player, drink.Hunger, drink.Energy)
		Notify:FireClient(player, "Food", ("🥤 %s: %s"):format(drink.Name, Format.money(drink.Price)))
		StoryEvents.emit(player, "Ate", { FoodId = "Bebida" })
	else
		Notify:FireClient(player, "Info", ctx.Why or "🧊 Echas un vistazo… Mejor no tocar lo que no es tuyo.")
	end
end

-- Agua de un grifo o de la ducha durante unos segundos
local function runWater(part: BasePart, seconds: number)
	local token = (part:GetAttribute("RunToken") or 0) + 1
	part:SetAttribute("RunToken", token)
	part:SetAttribute("Running", true)
	for _, e in part:GetChildren() do
		if e:IsA("ParticleEmitter") then
			e.Enabled = true
		end
	end
	task.delay(seconds, function()
		if part.Parent and part:GetAttribute("RunToken") == token then
			part:SetAttribute("Running", false)
			for _, e in part:GetChildren() do
				if e:IsA("ParticleEmitter") then
					e.Enabled = false
				end
			end
		end
	end)
end

actions.Tap = function(player, part)
	local seconds = Interact.Uses.Tap.Seconds :: number
	runWater(part, seconds)
	local spot = part:GetAttribute("Spot")
	start(player, { Pose = "Tap", Part = part, At = part.Position, Spot = if typeof(spot) == "Vector3" then spot else nil, Seconds = seconds, Connections = {} })
end

actions.Shower = function(player, part, _inst, access)
	local seconds = Interact.Uses.Shower.Seconds :: number
	local head: BasePart? = nil
	for _, d in (part.Parent or part):GetDescendants() do
		if d:IsA("BasePart") and d.Name == "ShowerHead" then
			head = d
		end
	end
	runWater(head or part, seconds)
	local spot = part:GetAttribute("Spot")
	start(player, {
		Pose = "Shower",
		Part = part,
		At = (head or part).Position,
		Spot = if typeof(spot) == "Vector3" then spot else part.Position,
		Seconds = seconds,
		Connections = {},
		OnEnd = function()
			if access == "Owner" or access == "Guest" then
				NeedsService.change(player, 0, 5)
			end
			Notify:FireClient(player, "Success", "🚿 ¡Qué a gusto! Sales fresco y limpio.")
		end,
	})
end

actions.Computer = function(player, part)
	local seat = sitOn(player, part, "Type", function()
		part:SetAttribute("On", false)
		part.Color = Color3.fromRGB(30, 60, 100)
	end)
	if seat then
		part:SetAttribute("On", true)
		part.Color = Color3.fromRGB(90, 170, 240)
	end
end

actions.Piano = function(player, part)
	local seat = sitOn(player, part, "Piano", function()
		part:SetAttribute("Playing", false)
	end)
	if seat then
		part:SetAttribute("Playing", true)
	end
end

local VIEWS = {
	"🪟 Se ve la ciudad de Valmar: tejados, antenas y el mar al fondo.",
	"🪟 Pasa un autobús por la calle y alguien corre a cogerlo.",
	"🪟 Unas palomas se posan en el balcón de enfrente.",
	"🪟 El cielo está precioso hoy.",
	"🪟 Abajo, un perro tira de su dueño hacia el parque.",
}
actions.Window = function(player, part)
	start(player, { Pose = "Window", Part = part, At = part.Position, Seconds = Interact.Uses.Window.Seconds, Connections = {} })
	Notify:FireClient(player, "Info", VIEWS[math.random(1, #VIEWS)])
end

---------------------------------------------------------------------
-- Usar algo (desde su cartel)
---------------------------------------------------------------------
function InteractService.use(player: Player, part: BasePart)
	local use = part:GetAttribute("Use")
	local info = type(use) == "string" and Interact.Uses[use]
	local action = type(use) == "string" and actions[use]
	if not info or not action then
		return
	end
	local humanoid, root = rootOf(player)
	if not humanoid or not root or humanoid.Health <= 0 then
		return
	end
	if player:GetAttribute("InDialogue") or player:GetAttribute("KO") or player:GetAttribute("Riding") then
		return
	end
	-- De cerca (el cartel ya sale solo de cerca; el servidor lo comprueba igual)
	if (root.Position - part.Position).Magnitude > info.Distance + 6 then
		return
	end
	local inst = instanceOf(part)
	local access = InteractService.accessOf(player, inst)
	local ok, why = Interact.allowed(use, access)
	if not ok then
		if why then
			Notify:FireClient(player, "Error", why)
		end
		return
	end
	-- (lo que cambia el mueble —luces, tele, puertas— no quita lo que estés haciendo; lo demás sí)
	local keeps = use == "Light" or use == "TV" or use == "Door" or use == "Wardrobe"
	if not keeps then
		InteractService.stop(player)
	end
	action(player, part, inst, access)
end

---------------------------------------------------------------------
-- Montar los carteles al construir una sala
---------------------------------------------------------------------
local CLERK_NAMES = { "Marta", "Luis", "Carmen", "Jorge", "Lucía", "Pablo", "Elena", "Rafa", "Nuria", "Iván" }
local CLERK_LINES = {
	"¡Buenas! ¿Le puedo ayudar en algo?",
	"Si busca algo, pregúnteme sin problema.",
	"Hoy tenemos ofertas en la nevera, ¿eh?",
	"Pase, pase, está en su casa.",
}

local function addClerk(spot: BasePart, index: number)
	if spot:GetAttribute("Staffed") then
		return
	end
	spot:SetAttribute("Staffed", true)
	local given = spot:GetAttribute("ClerkName")
	local name = if type(given) == "string" then given else CLERK_NAMES[(index - 1) % #CLERK_NAMES + 1]
	local ok, npc = pcall(Npc.create, name, spot.Parent or spot, spot.CFrame, nil)
	if not ok or not npc then
		return
	end
	npc:SetAttribute("Clerk", true)
	pcall(Npc.work, npc, "Type")
	local root = npc.PrimaryPart
	if root then
		local prompt = Builder.prompt(root, "Hablar", "🙂 " .. npc.Name, 0)
		prompt.MaxActivationDistance = 8
		prompt.Triggered:Connect(function()
			pcall(Npc.say, npc, CLERK_LINES[math.random(1, #CLERK_LINES)])
			task.delay(4, function()
				if npc.Parent then
					pcall(Npc.say, npc, nil)
				end
			end)
		end)
	end
end

-- Texto del cartel según la sala (la cama de una casa con dueño es para dormir; la nevera de una
-- tienda se paga)
local function textFor(part: BasePart, use: string, inst: InteriorService.Instance_?): (string, string)
	local info = Interact.Uses[use]
	local object = info.Object
	if use == "Bed" then
		local owned = false
		if inst then
			local ok, PropertyService = pcall(function()
				return require(script.Parent.PropertyService) :: any
			end)
			owned = ok and PropertyService.ownerOf ~= nil and PropertyService.ownerOf(inst.Building, inst.Floor, inst.Unit) ~= nil
		end
		return if owned then "Dormir" else info.Action, object
	elseif use == "Fridge" then
		if part:GetAttribute("FamilyHomeId") ~= nil then
			return "Coger algo de comer", "🍎 Nevera de casa"
		end
		local kind = kindOf(inst)
		if kind and Interact.ShopKinds[kind] then
			return "Comprar bebida", ("🥤 %s · %s"):format(Interact.Drink.Name, Format.money(Interact.Drink.Price))
		end
		return info.Action, object
	elseif use == "Light" then
		return Interact.actionText("Light", part:GetAttribute("On") ~= false), object
	end
	return Interact.actionText(use, part:GetAttribute("On") == true or part:GetAttribute("Open") == true), object
end

-- Cartel de una cosa que se usa (inst = la sala; nil fuera de los interiores: casa familiar)
local function setupPart(part: BasePart, inst: InteriorService.Instance_?)
	do
		local use = part:GetAttribute("Use")
		local info = part:HasTag("Interact") and type(use) == "string" and Interact.Uses[use]
		if not info or promptOf(part) then
			return
		end
		local action, object = textFor(part, use, inst)
		local prompt = Builder.prompt(part, action, object, info.Hold)
		prompt.Name = "InteractPrompt"
		prompt.MaxActivationDistance = info.Distance
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("Use", use)
		if info.Pose then
			-- Estas tienen su propia postura (UseMotion): sin el gesto de alargar la mano (Locomotion)
			prompt:SetAttribute("NoGesture", true)
		end
		prompt.Triggered:Connect(function(player)
			local ok, err = pcall(InteractService.use, player, part)
			if not ok then
				warn("[Muebles] " .. tostring(err))
			end
		end)
		if use == "Sit" or use == "Computer" or use == "Piano" then
			-- Sin sitio libre, el cartel se esconde
			local seats = {}
			if part:IsA("Seat") then
				table.insert(seats, part)
			else
				for _, d in (part.Parent or part):GetDescendants() do
					if d:IsA("Seat") then
						table.insert(seats, d)
					end
				end
			end
			local function refresh()
				local free = false
				for _, s in seats do
					if s.Occupant == nil and not s:GetAttribute("Taken") then
						free = true
					end
				end
				prompt.Enabled = free
			end
			for _, s in seats do
				s:GetPropertyChangedSignal("Occupant"):Connect(refresh)
				-- (la gente de la sala también ocupa sitio: CrowdService marca el asiento con Taken)
				s:GetAttributeChangedSignal("Taken"):Connect(refresh)
			end
			refresh()
		end
		if use == "Door" and part:GetAttribute("StartOpen") then
			swing(part, true, 0)
			setText(part, Interact.actionText("Door", true))
		end
	end
end

function InteractService.setup(inst: InteriorService.Instance_)
	local model = inst.Room.Model
	local clerks = 0
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end
		if part:HasTag("ClerkSpot") then
			clerks += 1
			task.spawn(addClerk, part, clerks + #model.Name) -- (crear a la persona puede tardar: no se espera)
			continue
		end
		setupPart(part, inst)
	end
end

-- Casas familiares (donde naces y creces, tag FamilyHome): su nevera es de tu familia y se come
-- de ella gratis y sin límite (Kit/Home ya la marca; en mapas viejos se marca aquí)
function InteractService.setupFamilyHome(home: Instance)
	local homeId = home:GetAttribute("HomeId")
	if homeId == nil then
		return
	end
	for _, part in home:GetDescendants() do
		if part:IsA("BasePart") and part.Name == "Fridge" then
			if not part:HasTag("Interact") then
				part:AddTag("Interact")
				part:SetAttribute("Use", "Fridge")
			end
			part:SetAttribute("FamilyHomeId", homeId)
			setupPart(part, nil)
		end
	end
end

---------------------------------------------------------------------

function InteractService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Notify = remotes:WaitForChild("Notify") :: RemoteEvent
	Remote = remotes:FindFirstChild("Interact") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "Interact"
		Remote.Parent = remotes
	end
	Remote.OnServerEvent:Connect(function(player: Player, kind: any)
		if kind == "Stop" then
			local use = using[player]
			if not use then
				return
			end
			local humanoid = rootOf(player)
			if use.Seat and humanoid and humanoid.SeatPart == use.Seat then
				humanoid.Sit = false
			end
			InteractService.stop(player)
		end
	end)
	InteriorService.onBuilt(InteractService.setup)
	local CollectionService = game:GetService("CollectionService")
	for _, home in CollectionService:GetTagged("FamilyHome") do
		InteractService.setupFamilyHome(home)
	end
	CollectionService:GetInstanceAddedSignal("FamilyHome"):Connect(function(home)
		task.defer(InteractService.setupFamilyHome, home)
	end)
	Players.PlayerRemoving:Connect(function(player)
		InteractService.stop(player)
		snacks[player] = nil
	end)
	-- En casa, sentado en el sofá se descansa un poquito
	task.spawn(function()
		while true do
			task.wait(1)
			for player, use in using do
				local ok, err = pcall(function()
					if (use.Pose == "Sofa" or use.Pose == "Sit") and player.Parent then
						local inst = instanceOf(use.Part)
						local access = InteractService.accessOf(player, inst)
						if access == "Owner" or access == "Guest" then
							NeedsService.change(player, 0, Interact.RestPerSecond)
						end
					end
				end)
				if not ok then
					warn("[InteractService] " .. tostring(err))
				end
			end
		end
	end)
end

return InteractService
