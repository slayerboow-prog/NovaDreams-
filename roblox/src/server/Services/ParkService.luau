-- ParkService: lo que se usa en las zonas verdes (parques vivos, Jardines de la Plaza Mayor, huertos
-- de la Puerta de Villaverde, orilla del lago y Camping). Lo construye World/Kit/ZonasVerdes; aquí
-- cobra vida por etiquetas:
--
--   FunSwing (Seat)       columpio: al sentarte se mece (gira alrededor de su Pivot) y sube la diversión
--                         (Config.Fun.SwingPerMinute; niños ×ChildBonus)
--   FunSlide (pieza)      «Tirarse por el tobogán»: subes (TopAt) y bajas por la rampa (BottomAt)
--   FunSeat (Seat)        sentado sube la diversión (FunPerMinute; NightOnly = solo de noche: la
--                         hoguera) y, si lo dice, la energía (EnergyPerMinute)
--   PicnicTable (pieza)   «Comer de la mochila»: la primera comida de tu mochila, con un poco más de
--                         hambre y energía y +diversión
--   DogRunPost (pieza)    «Lanzar la pelota»: tu mascota corre a por ella (PetService.fetch)
--   DogRun (zona)         con tu mascota dentro sube la diversión
--   Campfire (pieza)      la hoguera: de noche se enciende (luz, fuego y grillos) y «Tostar malvaviscos»
--   CampTent (pieza)      «Dormir en la tienda»: la alquilas (Config.Camping.TentPrice) y duermes como
--                         en cualquier cama (SleepService: de noche pasa la noche)
--   CampPitch (pieza)     «Montar mi tienda»: una parcela libre del Camping para tu propia tienda (gratis)
--   HuertoCocina (pieza)  «Cocinar con la cosecha»: la cocina de FarmService al aire libre
--
-- Todo pasa por PromptGate (una pulsación, una acción). Cada cosa avisa a la historia y al pase con
-- StoryEvents «ParkPlayed» { Kind = … }.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local GameClock = require(ReplicatedStorage.Shared.GameClock)
local Items = require(ReplicatedStorage.Shared.Items)
local Format = require(ReplicatedStorage.Shared.Format)
local Builder = require(script.Parent.Parent.World.Builder)
local PromptGate = require(script.Parent.Parent.World.PromptGate)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)

local ParkService = {}

local Fun = Config.Fun
local TENT_PRICE = 15
ParkService.TentPrice = TENT_PRICE
ParkService.TICK = 1

-- Relojes (las pruebas los cambian)
ParkService._clock = function(): number
	return os.clock()
end
ParkService._isNight = function(): boolean
	return GameClock.lampsOn()
end

local notifyRemote: RemoteEvent? = nil
local function notify(player: Player, kind: string, text: string)
	if not notifyRemote then
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		notifyRemote = remotes and remotes:FindFirstChild("Notify") :: RemoteEvent?
	end
	if notifyRemote then
		notifyRemote:FireClient(player, kind, text)
	end
end
ParkService._notify = notify

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end
local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function childBonus(player: Player): number
	local stage = player:GetAttribute("LifeStage")
	return if stage == "Nino" or stage == "Bebe" then Fun.ChildBonus else 1
end

-- Lo que hay que esperar entre dos usos de lo mismo
local lastUse: { [Player]: { [string]: number } } = {}
local function ready(player: Player, key: string, seconds: number): boolean
	local now = ParkService._clock()
	local mine = lastUse[player]
	if not mine then
		mine = {}
		lastUse[player] = mine
	end
	if mine[key] and now - mine[key] < seconds then
		return false
	end
	mine[key] = now
	return true
end

local function prompt(part: BasePart, action: string, object: string, hold: number?, distance: number?): ProximityPrompt
	local p = Builder.prompt(part, action, object, hold)
	p.MaxActivationDistance = distance or 9
	return p
end

local function played(player: Player, kind: string)
	StoryEvents.emit(player, "ParkPlayed", { Kind = kind })
end

---------------------------------------------------------------------
-- Columpios: se mecen mientras hay alguien sentado
---------------------------------------------------------------------
type Swing = { Seat: Seat, Parts: { { Part: BasePart, Base: CFrame } }, Pivot: CFrame, Angle: NumberValue, Tween: Tween? }
local swings: { [Instance]: Swing } = {}
ParkService._swings = swings

local function placeSwing(s: Swing)
	local rot = s.Pivot * CFrame.Angles(math.rad(s.Angle.Value), 0, 0) * s.Pivot:Inverse()
	for _, entry in s.Parts do
		entry.Part.CFrame = rot * entry.Base
	end
end

local function swingMotion(s: Swing, on: boolean)
	if s.Tween then
		s.Tween:Cancel()
		s.Tween = nil
	end
	if on then
		s.Angle.Value = -24
		local ok, t = pcall(function()
			return TweenService:Create(s.Angle, TweenInfo.new(1.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Value = 24 })
		end)
		if ok and t then
			s.Tween = t
			t:Play()
		end
	else
		s.Angle.Value = 0
	end
	placeSwing(s)
end

local function setupSwing(seat: Instance)
	if not seat:IsA("Seat") or swings[seat] then
		return
	end
	local group = seat.Parent
	local pivotAt = seat:GetAttribute("Pivot")
	if not group or typeof(pivotAt) ~= "Vector3" then
		return
	end
	-- El giro: alrededor del travesaño (el eje X del asiento)
	local look = seat.CFrame.LookVector
	local pivot = CFrame.fromMatrix(pivotAt, seat.CFrame.RightVector, Vector3.yAxis, -look)
	local s: Swing = { Seat = seat :: Seat, Parts = {}, Pivot = pivot, Angle = Instance.new("NumberValue") }
	for _, d in group:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(s.Parts, { Part = d, Base = d.CFrame })
		end
	end
	swings[seat] = s
	s.Angle.Changed:Connect(function()
		placeSwing(s)
	end)
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		swingMotion(s, (seat :: Seat).Occupant ~= nil)
	end)
end
ParkService._setupSwing = setupSwing
ParkService._swingMotion = swingMotion

---------------------------------------------------------------------
-- Tobogán
---------------------------------------------------------------------
local sliding: { [Player]: boolean } = {}

function ParkService.slide(player: Player, spot: BasePart): boolean
	local top, bottom = spot:GetAttribute("TopAt"), spot:GetAttribute("BottomAt")
	local root = rootOf(player)
	local humanoid = humanoidOf(player)
	if typeof(top) ~= "Vector3" or typeof(bottom) ~= "Vector3" or not root or not humanoid or sliding[player] then
		return false
	end
	if humanoid.SeatPart then
		return false
	end
	if not ready(player, "Slide", 1.5) then
		return false
	end
	sliding[player] = true
	local look = Vector3.new(bottom.X - top.X, 0, bottom.Z - top.Z)
	local face = if look.Magnitude > 0.01 then look.Unit else Vector3.new(0, 0, -1)
	local function at(p: Vector3): CFrame
		return CFrame.lookAt(p, p + face)
	end
	root.Anchored = true
	root.CFrame = at(top)
	pcall(function()
		TweenService:Create(root, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = at(bottom) }):Play()
	end)
	task.delay(0.95, function()
		if root.Parent then
			root.CFrame = at(bottom)
			root.Anchored = false
		end
		sliding[player] = nil
	end)
	local gained = NeedsService.addFun(player, Fun.Slide * childBonus(player), "Slide")
	notify(player, "Success", ("¡Uiii! 🛝%s"):format(if gained > 0 then "  +🎈" else ""))
	played(player, "Slide")
	return true
end

---------------------------------------------------------------------
-- Pícnic: comer lo que llevas en la mochila
---------------------------------------------------------------------
-- La primera comida de la mochila (por orden de nombre: siempre la misma)
function ParkService.firstFood(player: Player): string?
	local data = DataService.get(player)
	if not data or type(data.Items) ~= "table" then
		return nil
	end
	local ids = {}
	for id, count in data.Items do
		local item = Items.get(id)
		if type(count) == "number" and count > 0 and item and item.Kind == "Food" then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	return ids[1]
end

function ParkService.picnic(player: Player): boolean
	local data = DataService.get(player)
	if not data then
		return false
	end
	local id = ParkService.firstFood(player)
	if not id then
		notify(player, "Info", "🧺 No llevas comida en la mochila. Compra algo en el súper, en un quiosco o en la cafetería y vuelve a la mesa.")
		return false
	end
	if not ready(player, "Picnic", 2) then
		return false
	end
	local item = Items.get(id) :: any
	local InventoryService = require(script.Parent.InventoryService) :: any
	InventoryService.remove(player, id, 1)
	-- En el pícnic sabe mejor: un poco más de hambre y energía, y diversión
	NeedsService.change(player, math.floor((item.Hunger or 0) * 1.2 + 0.5), (item.Energy or 0) + 5)
	local gained = NeedsService.addFun(player, Fun.PicnicMeal, "Picnic")
	notify(player, "Food", ("🧺 Pícnic: %s %s%s"):format(item.Icon or "", item.Name or id, if gained > 0 then "  +🎈" else ""))
	StoryEvents.emit(player, "Ate", { FoodId = id, Picnic = true })
	played(player, "Picnic")
	return true
end

---------------------------------------------------------------------
-- Pipicán: la pelota y la mascota
---------------------------------------------------------------------
local dogRuns: { BasePart } = {}
ParkService._dogRuns = dogRuns

local function petService(): any
	return require(script.Parent.PetService)
end

-- Un sitio dentro del pipicán donde cae la pelota (va dando la vuelta: no siempre el mismo)
local throwCount: { [Player]: number } = {}
local function landing(player: Player, area: BasePart): Vector3
	local n = (throwCount[player] or 0) + 1
	throwCount[player] = n
	local a = n * 2.4
	local local_ = Vector3.new(math.cos(a) * area.Size.X * 0.32, -area.Size.Y / 2 + 0.6, math.sin(a) * area.Size.Z * 0.32)
	return area.CFrame:PointToWorldSpace(local_)
end

local function areaOf(post: BasePart): BasePart?
	local best, bestD = nil, math.huge
	for _, area in dogRuns do
		if area.Parent then
			local d = (area.CFrame.Position - post.CFrame.Position).Magnitude
			if d < bestD then
				best, bestD = area, d
			end
		end
	end
	return if bestD < 80 then best else nil
end

local function ballArc(from: Vector3, to: Vector3)
	local ball = Builder.decor({ Name = "PelotaPerro", Shape = Enum.PartType.Ball, Size = Vector3.new(0.8, 0.8, 0.8), CFrame = CFrame.new(from), Color = Color3.fromRGB(200, 230, 60), Material = Enum.Material.Fabric, Parent = workspace })
	task.spawn(function()
		for i = 1, 8 do
			local t = i / 8
			local p = from:Lerp(to, t) + Vector3.new(0, math.sin(t * math.pi) * 6, 0)
			ball.CFrame = CFrame.new(p)
			task.wait(0.06)
		end
		task.wait(2.2)
		ball:Destroy()
	end)
end

function ParkService.fetch(player: Player, post: BasePart): boolean
	local area = areaOf(post)
	if not area then
		return false
	end
	if not petService().following(player) then
		notify(player, "Info", "🐾 Aquí se juega con tu mascota. Adopta una en la Protectora de Valmar (o sácala de casa desde 🐾 Mis mascotas).")
		return false
	end
	if not ready(player, "Fetch", 3) then
		return false
	end
	local at = landing(player, area)
	if not petService().fetch(player, at) then
		return false
	end
	ballArc(post.CFrame.Position + Vector3.new(0, 2, 0), at)
	local gained = NeedsService.addFun(player, Fun.Fetch, "Fetch")
	notify(player, "Success", ("🎾 ¡A por ella!%s"):format(if gained > 0 then "  +🎈" else ""))
	played(player, "Fetch")
	return true
end

local function insideArea(area: BasePart, p: Vector3): boolean
	local l = area.CFrame:PointToObjectSpace(p)
	return math.abs(l.X) <= area.Size.X / 2 and math.abs(l.Z) <= area.Size.Z / 2 and math.abs(l.Y) <= area.Size.Y / 2 + 4
end

function ParkService.inDogRun(player: Player): boolean
	local root = rootOf(player)
	if not root then
		return false
	end
	for _, area in dogRuns do
		if area.Parent and insideArea(area, root.CFrame.Position) then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
-- Hoguera: de noche, encendida; malvaviscos
---------------------------------------------------------------------
local fires: { BasePart } = {}
ParkService._fires = fires

local function lightFire(part: BasePart, on: boolean)
	if part:GetAttribute("Lit") == on then
		return
	end
	part:SetAttribute("Lit", on)
	part.Transparency = if on then 0.2 else 1
	for _, d in part:GetChildren() do
		if d:IsA("Light") then
			d.Enabled = on
		elseif d:IsA("Fire") or d:IsA("ParticleEmitter") then
			(d :: any).Enabled = on
		elseif d:IsA("Sound") then
			if on then
				d:Play()
			else
				d:Stop()
			end
		end
	end
end

local function setupFire(part: Instance)
	if not part:IsA("BasePart") or table.find(fires, part) then
		return
	end
	table.insert(fires, part)
	-- Llamas de verdad y el ambiente de la noche (grillos, Config.Sounds.Grillos) junto al fuego
	pcall(function()
		local flame = Instance.new("Fire")
		flame.Size = 4
		flame.Heat = 7
		flame.Parent = part
		local sound = Instance.new("Sound")
		sound.Name = "NocheHoguera"
		local id = Config.Sounds and Config.Sounds.Grillos and Config.Sounds.Grillos.Id
		sound.SoundId = if type(id) == "number" and id > 0 then "rbxassetid://" .. id else ""
		sound.Looped = true
		sound.Volume = 0.45
		sound.RollOffMaxDistance = 70
		sound.RollOffMinDistance = 8
		local group = game:GetService("SoundService"):FindFirstChild("Ambience")
		if group and group:IsA("SoundGroup") then
			sound.SoundGroup = group
		end
		sound.Parent = part
	end)
	lightFire(part, ParkService._isNight())
	local p = prompt(part, "Tostar malvaviscos", "🔥 Hoguera", 1.2, 12)
	p.Name = "MalvaviscosPrompt"
	p.Triggered:Connect(function(player)
		PromptGate.run(player, part.Position, function()
			ParkService.marshmallow(player, part)
		end)
	end)
end
ParkService._setupFire = setupFire

function ParkService.marshmallow(player: Player, fire: BasePart): boolean
	if not ParkService._isNight() then
		notify(player, "Info", "🔥 La hoguera se enciende al anochecer. Vuelve de noche para tostar malvaviscos.")
		return false
	end
	if not ready(player, "Marshmallow", 8) then
		return false
	end
	NeedsService.change(player, 6, 2)
	local gained = NeedsService.addFun(player, Fun.Marshmallow, "Marshmallow")
	notify(player, "Food", ("🔥 Malvavisco tostado, ¡qué rico!%s"):format(if gained > 0 then "  +🎈" else ""))
	played(player, "Marshmallow")
	return true
end

---------------------------------------------------------------------
-- Tiendas de campaña y parcelas del Camping
---------------------------------------------------------------------
local rentals: { [string]: { Player: Player, Until: number } } = {} -- TentId -> quién la tiene alquilada
local pitched: { [Player]: { Model: Model, Pitch: BasePart } } = {}
ParkService._rentals = rentals
ParkService._pitched = pitched

local function sleepIn(player: Player, bed: BasePart)
	local root = rootOf(player)
	local lie = bed:GetAttribute("LieAt")
	if root and typeof(lie) == "Vector3" then
		root.CFrame = CFrame.new(lie + Vector3.new(0, 1.5, 0))
	end
	NeedsService.addFun(player, Fun.TentNight, "Tent")
	played(player, "Tent")
	local SleepService = require(script.Parent.SleepService) :: any
	task.spawn(SleepService.sleep, player, bed)
end

function ParkService.useTent(player: Player, bed: BasePart): boolean
	local owner = bed:GetAttribute("Owner")
	if owner ~= nil then
		-- Tu tienda (la que has montado): gratis, solo tú
		if owner ~= player.UserId then
			notify(player, "Error", "⛺ Esta tienda es de otro campista.")
			return false
		end
		sleepIn(player, bed)
		return true
	end
	local id = tostring(bed:GetAttribute("TentId") or bed:GetFullName())
	local now = ParkService._clock()
	local rent = rentals[id]
	if rent and rent.Player ~= player and rent.Player.Parent and now < rent.Until then
		notify(player, "Error", "⛺ Esta tienda ya está alquilada. Prueba con otra o monta la tuya en una parcela libre.")
		return false
	end
	if not rent or rent.Player ~= player or now >= rent.Until then
		if not DataService.spend(player, TENT_PRICE) then
			notify(player, "Error", ("⛺ Alquilar la tienda cuesta %s. No te llega."):format(Format.money(TENT_PRICE)))
			return false
		end
		-- (como mucho una tienda alquilada por jugador)
		for other, r in rentals do
			if r.Player == player then
				rentals[other] = nil
			end
		end
		rentals[id] = { Player = player, Until = now + 15 * 60 }
		notify(player, "Success", ("⛺ Tienda alquilada (%s). ¡Buenas noches!"):format(Format.money(TENT_PRICE)))
	end
	sleepIn(player, bed)
	return true
end

local TENT_COLORS = { Color3.fromRGB(230, 120, 40), Color3.fromRGB(60, 140, 90), Color3.fromRGB(60, 110, 190), Color3.fromRGB(190, 60, 60) }

function ParkService.pitch(player: Player, pitch: BasePart): boolean
	for other, entry in pitched do
		if entry.Pitch == pitch and other ~= player and other.Parent then
			notify(player, "Error", "⛺ En esta parcela ya hay una tienda montada.")
			return false
		end
	end
	local mine = pitched[player]
	if mine and mine.Pitch == pitch then
		-- Ya está montada aquí: a dormir
		local bed = mine.Model:FindFirstChild("CamaTienda", true)
		if bed and bed:IsA("BasePart") then
			sleepIn(player, bed)
		end
		return true
	end
	if mine then
		mine.Model:Destroy()
		pitched[player] = nil
	end
	local Juegos = require(script.Parent.Parent.World.Kit.ZonasVerdes.Juegos) :: any
	local color = TENT_COLORS[player.UserId % #TENT_COLORS + 1]
	local model = Juegos.tent(pitch.Parent or workspace, pitch.CFrame * CFrame.new(0, -pitch.Size.Y / 2, 0), color, "Parcela_" .. player.UserId, false)
	model.Name = "TiendaDe_" .. player.Name
	local bed = model:FindFirstChild("CamaTienda")
	if bed then
		bed:SetAttribute("Owner", player.UserId) -- (solo duerme en ella quien la monta, gratis)
	end
	pitched[player] = { Model = model, Pitch = pitch }
	notify(player, "Success", "⛺ ¡Tienda montada! Vuelve a pulsar en la parcela para dormir en ella.")
	played(player, "Pitch")
	return true
end

---------------------------------------------------------------------
-- Cada segundo: diversión (y energía) de lo que estás haciendo
---------------------------------------------------------------------
function ParkService.step(player: Player, seconds: number)
	local humanoid = humanoidOf(player)
	local seat = humanoid and humanoid.SeatPart
	local per = seconds / 60
	if seat and seat:HasTag("FunSwing") then
		NeedsService.addFun(player, Fun.SwingPerMinute * per * childBonus(player), "Swing")
	elseif seat and seat:HasTag("FunSeat") then
		local night = seat:GetAttribute("NightOnly") ~= true or ParkService._isNight()
		if night then
			local rate = seat:GetAttribute("FunPerMinute")
			if type(rate) == "number" and rate > 0 then
				local bonus = if seat:GetAttribute("ChildBonus") then childBonus(player) else 1
				NeedsService.addFun(player, rate * per * bonus, tostring(seat:GetAttribute("Reason") or "Seat"))
			end
			local energy = seat:GetAttribute("EnergyPerMinute")
			if type(energy) == "number" and energy > 0 then
				NeedsService.change(player, 0, energy * per)
			end
		end
	end
	if #dogRuns > 0 and ParkService.inDogRun(player) and petService().following(player) then
		NeedsService.addFun(player, Fun.DogParkPerMinute * per, "DogPark")
	end
end

---------------------------------------------------------------------
-- Montaje
---------------------------------------------------------------------
local function each(tag: string, fn: (Instance) -> ())
	for _, d in CollectionService:GetTagged(tag) do
		task.spawn(fn, d)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(function(d)
		task.defer(fn, d)
	end)
end

local setups: { [string]: (Instance) -> () } = {
	FunSwing = setupSwing,
	FunSlide = function(part)
		if not part:IsA("BasePart") or part:FindFirstChild("SlidePromptP") then
			return
		end
		local p = prompt(part, "Tirarse", "🛝 Tobogán", 0, 8)
		p.Name = "SlidePromptP"
		p.Triggered:Connect(function(player)
			PromptGate.run(player, part.Position, function()
				ParkService.slide(player, part)
			end)
		end)
	end,
	PicnicTable = function(part)
		if not part:IsA("BasePart") or part:FindFirstChild("PicnicPrompt") then
			return
		end
		local p = prompt(part, "Comer de la mochila", "🧺 Mesa de pícnic", 0.3, 9)
		p.Name = "PicnicPrompt"
		p.Triggered:Connect(function(player)
			PromptGate.run(player, part.Position, function()
				ParkService.picnic(player)
			end)
		end)
	end,
	DogRun = function(part)
		if part:IsA("BasePart") and not table.find(dogRuns, part) then
			table.insert(dogRuns, part)
		end
	end,
	DogRunPost = function(part)
		if not part:IsA("BasePart") or part:FindFirstChild("FetchPrompt") then
			return
		end
		local p = prompt(part, "Lanzar la pelota", "🐾 Pipicán", 0, 10)
		p.Name = "FetchPrompt"
		p.Triggered:Connect(function(player)
			PromptGate.run(player, part.Position, function()
				ParkService.fetch(player, part)
			end)
		end)
	end,
	Campfire = setupFire,
	CampTent = function(part)
		if not part:IsA("BasePart") or part:FindFirstChild("TentPrompt") then
			return
		end
		local owned = part:GetAttribute("Owner") ~= nil
		local p = prompt(part, "Dormir en la tienda", if owned then "⛺ Tu tienda" else ("⛺ Tienda · %s la noche"):format(Format.money(TENT_PRICE)), 0.6, 9)
		p.Name = "TentPrompt"
		p.Triggered:Connect(function(player)
			PromptGate.run(player, part.Position, function()
				ParkService.useTent(player, part)
			end)
		end)
	end,
	CampPitch = function(part)
		if not part:IsA("BasePart") or part:FindFirstChild("PitchPrompt") then
			return
		end
		local p = prompt(part, "Montar mi tienda", "⛺ Parcela libre · gratis", 0.8, 10)
		p.Name = "PitchPrompt"
		p.Triggered:Connect(function(player)
			PromptGate.run(player, part.Position, function()
				ParkService.pitch(player, part)
			end)
		end)
	end,
	HuertoCocina = function(part)
		if not part:IsA("BasePart") or part:FindFirstChild("CookPrompt") then
			return
		end
		local p = prompt(part, "Cocinar con la cosecha", "🍳 Cocina del huerto", 0.3, 9)
		p.Name = "CookPrompt"
		p.Triggered:Connect(function(player)
			PromptGate.run(player, part.Position, function()
				local FarmService = require(script.Parent.FarmService) :: any
				FarmService.openKitchen(player, part)
			end)
		end)
	end,
}
ParkService._setups = setups

function ParkService.init()
	for tag, fn in setups do
		each(tag, fn)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastUse[player] = nil
		sliding[player] = nil
		throwCount[player] = nil
		local mine = pitched[player]
		if mine then
			mine.Model:Destroy()
			pitched[player] = nil
		end
		for id, r in rentals do
			if r.Player == player then
				rentals[id] = nil
			end
		end
	end)
	task.spawn(function()
		local wasNight: boolean? = nil
		while true do
			task.wait(ParkService.TICK)
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(ParkService.step, player, ParkService.TICK)
				if not ok then
					warn("[ParkService] " .. tostring(err))
				end
			end
			local night = ParkService._isNight()
			if night ~= wasNight then
				wasNight = night
				for _, fire in fires do
					if fire.Parent then
						lightFire(fire, night)
					end
				end
			end
		end
	end)
end

return ParkService
