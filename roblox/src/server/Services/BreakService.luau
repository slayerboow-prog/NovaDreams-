-- BreakService (servidor): piedras que se cogen del suelo y se lanzan; cristales y puertas que se rompen.
--
--   * Coger (tecla B o botón 🥌 en móvil): de un suelo de tierra, césped, arena o roca. Llevas hasta
--     3, y se ve la piedra en tu mano.
--   * Lanzar (otra vez B): hacia donde apuntas. La piedra la calcula el servidor (con rayos, para no
--     atravesar cristales finos) y cada jugador la dibuja volando (Vandal "Stone").
--   * Qué rompe (BreakService.hit, reglas en shared/Breakables):
--       - piedras, balas de armas de verdad (WeaponService; las de agua y pintura no), golpes fuertes
--         (CombatService.attack -> BreakService.meleeHit) y vehículos a velocidad (cliente
--         Collisions -> KnockService "Break" -> BreakService.vehicleHit).
--       - Cristales (ventanas de casas y edificios, escaparates, puertas de cristal, marquesinas del
--         bus, balcones…): se rompen en trozos con física que se desvanecen, con su sonido. Los
--         escaparates y las franjas de ventanas grandes se parten en tramos y solo se rompe el tramo
--         donde das (o los que toca el coche). Mientras está roto, el hueco NO choca: se puede pasar
--         (huir por un escaparate). Si detrás no hay hueco (un cristal pegado a la fachada), queda
--         un hueco oscuro.
--       - Puertas (de madera de los edificios, las de las salas por dentro): aguantan unos golpes
--         (12 pedradas, 4 balazos, 5 patadas) y se caen (las de dentro se abren de golpe). Un
--         vehículo rápido la tira de una.
--   * Todo se arregla solo y rápido: cristal a los 20–30 s, puertas a los 30–45 s, nunca con alguien
--     en el hueco, apareciendo poco a poco.
--   * Topes: cada jugador rompe como mucho Breakables.Budget.PerPlayer cosas cada pocos segundos; si
--     hay demasiadas rotas a la vez, la más antigua se arregla ya; y un máximo de trozos volando.
--   * Consecuencias: los policías de servicio reciben el aviso («🚨 Vandalismo en …»), los
--     personajes a los que das se quejan, va a tu historial de comportamiento (ConductService) y,
--     si lo ve alguien y nadie te buscaba, «Daños» (1 estrella, WantedService; no con balas: eso ya
--     es «Disparos en la vía pública»).
-- Las reglas (qué se rompe, cómo vuela la piedra, tiempos y topes) están en shared/Breakables.

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Breakables = require(ReplicatedStorage.Shared.Breakables)
local Npc = require(script.Parent.Parent.World.Npc)
local LocationService = require(script.Parent.LocationService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local BreakService = {}

local Remote: RemoteEvent
local Notify: RemoteEvent

local PICK_COOLDOWN = 0.7
local THROW_COOLDOWN = 0.45
local MAX_RANGE = 250
local MAX_FLIGHT = 4 -- segundos
local HOLE_COLOR = Color3.fromRGB(22, 24, 28) -- hueco oscuro de un cristal pegado a la fachada

local lastPick: { [Player]: number } = {}
local lastThrow: { [Player]: number } = {}
local lastAlert: { [Player]: number } = {}
local lastVandal: { [Player]: number } = {}
local history: { [Player]: { number } } = {}

-- Cómo estaba cada pieza antes de romperse (para dejarla igual)
type Saved = {
	Transparency: number,
	CanCollide: boolean,
	CanQuery: boolean,
	CFrame: CFrame,
	Anchored: boolean,
	Color: Color3,
	Material: Enum.Material,
	Reflectance: number,
}
-- Lo roto: qué es, cómo estaba, cuándo se arregla y lo que se cayó con ella (pomo, tirador…)
type Piece = {
	Kind: string, -- "Glass", "Door" (se cae) o "Swing" (puerta de dentro: se abre de golpe)
	Saved: Saved,
	Size: Vector3,
	BrokenAt: number,
	RepairAt: number,
	Extra: { BasePart },
	ExtraSaved: { Saved },
}
local broken: { [BasePart]: Piece } = {}
local brokenCount = 0
-- Golpes de cada puerta: aguante, cuándo el último, y su color y sitio de antes de golpearla
type DoorState = { Health: number, Last: number, Color: Color3, CFrame: CFrame }
local doorState: { [BasePart]: DoorState } = {}
-- Cristales grandes partidos en tramos: el original queda escondido mientras haya tramos
type Split = { Segments: { BasePart }, Axis: string, Length: number, N: number, Saved: Saved }
local split: { [BasePart]: Split } = {}
local segmentOf: { [BasePart]: BasePart } = {}
local liveShards = 0

type Stone = { Id: number, Player: Player, From: Vector3, Velocity: Vector3, Start: number, Last: Vector3 }
local stones: { Stone } = {}
local nextId = 0

-- (pruebas)
BreakService._broken = broken
BreakService._split = split
BreakService._doors = doorState

---------------------------------------------------------------------
-- La piedra en la mano
---------------------------------------------------------------------

local function stoneLook(part: BasePart, size: number)
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(size, size * 0.8, size)
	part.Color = Color3.fromRGB(120, 116, 110)
	part.Material = Enum.Material.Slate
end

local function showInHand(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local old = character:FindFirstChild("PiedraMano")
	local count = player:GetAttribute("Stones") or 0
	if count <= 0 then
		if old then
			old:Destroy()
		end
		return
	end
	if old then
		return
	end
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not hand or not hand:IsA("BasePart") then
		return
	end
	local stone = Instance.new("Part")
	stone.Name = "PiedraMano"
	stoneLook(stone, 0.6)
	stone.CanCollide = false
	stone.CanQuery = false
	stone.CanTouch = false
	stone.Massless = true
	stone.CFrame = hand.CFrame * CFrame.new(0, -hand.Size.Y / 2 - 0.15, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hand
	weld.Part1 = stone
	weld.Parent = stone
	stone.Parent = character
end

local function setStones(player: Player, count: number)
	player:SetAttribute("Stones", math.clamp(count, 0, Breakables.MaxStones))
	showInHand(player)
end

---------------------------------------------------------------------
-- Sonido, trozos y fundidos
---------------------------------------------------------------------

local function sound(at: Vector3, id: string, volume: number, pitch: number)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.CFrame = CFrame.new(at)
	anchor.Parent = workspace
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume
	s.PlaybackSpeed = pitch
	s.RollOffMaxDistance = 120
	-- Cada cliente lo mete en su grupo de efectos (SoundFx): así «Sonidos: no» también lo calla
	s:SetAttribute("SfxGroup", "SFX")
	s.Parent = anchor
	s:Play()
	Debris:AddItem(anchor, 3)
end

-- Cristal que estalla: un golpe seco y agudo y el tintineo de los trozos
local function glassSound(at: Vector3)
	sound(at, "rbxasset://sounds/collide.wav", 0.9, 2.1 + math.random() * 0.3)
	sound(at, "rbxasset://sounds/electronicpingshort.wav", 0.18, 3.2 + math.random() * 0.6)
end

local function fade(part: BasePart, goal: number, seconds: number)
	local ok = pcall(function()
		TweenService:Create(part, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = goal }):Play()
	end)
	if not ok then
		part.Transparency = goal
	end
end

local function remember(part: BasePart): Saved
	return {
		Transparency = part.Transparency,
		CanCollide = part.CanCollide,
		CanQuery = part.CanQuery,
		CFrame = part.CFrame,
		Anchored = part.Anchored,
		Color = part.Color,
		Material = part.Material,
		Reflectance = part.Reflectance,
	}
end

-- Trozos de cristal que salen volando y caen (con física), y se desvanecen a los 4–6 s
local function shards(part: BasePart, color: Color3, alpha: number, velocity: Vector3)
	local size = part.Size
	local count = math.min(Breakables.shards(size), Breakables.Budget.MaxShards - liveShards)
	if count <= 0 then
		return
	end
	liveShards += count
	local push = if velocity.Magnitude > 0.01 then velocity.Unit else Vector3.zero
	local life = 4 + math.random() * 2
	for _ = 1, count do
		local shard = Instance.new("WedgePart")
		shard.Name = "Cristal"
		shard.Size = Vector3.new(0.05, 0.3 + math.random() * 0.6, 0.3 + math.random() * 0.6)
		shard.Color = color
		shard.Material = Enum.Material.Glass
		shard.Reflectance = 0.2
		shard.Transparency = math.clamp(alpha, 0.15, 0.6)
		shard.CanQuery = false
		shard.CanTouch = false
		shard.CastShadow = false
		shard.Massless = true
		local offset = Vector3.new((math.random() - 0.5) * size.X, (math.random() - 0.5) * size.Y, (math.random() - 0.5) * size.Z)
		shard.CFrame = part.CFrame * CFrame.new(offset) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		shard.AssemblyLinearVelocity = push * (8 + math.random() * 10) + Vector3.new((math.random() - 0.5) * 8, math.random() * 5, (math.random() - 0.5) * 8)
		shard.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 20
		shard.Parent = workspace
		task.delay(life - 0.9, function()
			if shard.Parent then
				fade(shard, 1, 0.8)
			end
		end)
		Debris:AddItem(shard, life)
	end
	task.delay(life, function()
		liveShards = math.max(0, liveShards - count)
	end)
end

---------------------------------------------------------------------
-- Qué se puede romper
---------------------------------------------------------------------

-- ¿Se puede romper? (no lo que tiene cartel para usarse o una etiqueta de algún sistema; las
-- ventanas que se encienden de noche, sí). Las puertas de las salas (Interact "Door") van aparte.
local HARMLESS_TAGS = { NightWindow = true }
local function plainPart(part: BasePart): boolean
	if broken[part] or not part.Anchored or split[part] then
		return false
	end
	if part:FindFirstChildWhichIsA("ProximityPrompt", true) then
		return false
	end
	for _, tag in CollectionService:GetTags(part) do
		if not HARMLESS_TAGS[tag] then
			return false
		end
	end
	return true
end

-- Puerta con bisagra de una sala por dentro (World/Furniture.door): se abre de golpe a patadas o a
-- tiros. Las de las viviendas (UnitDoor: tienen dueño y llave) no.
local function swingDoor(part: BasePart): boolean
	return not broken[part]
		and part:HasTag("Interact")
		and part:GetAttribute("Use") == "Door"
		and typeof(part:GetAttribute("Hinge")) == "CFrame"
		and typeof(part:GetAttribute("Closed")) == "CFrame"
		and not part:HasTag("UnitDoor")
		and part:GetAttribute("Open") ~= true
end

-- "Glass", "Segmented", "Door", "Swing" o nil
local function kindOf(part: Instance): string?
	if not part:IsA("BasePart") then
		return nil
	end
	if split[part] then
		return "Segmented" -- (el original de un escaparate ya partido: un coche lo pudo ver antes)
	end
	if swingDoor(part) then
		return "Swing"
	end
	if not plainPart(part) then
		return nil
	end
	if segmentOf[part] then
		return "Glass" -- (un tramo se rompe entero, aunque sea grande)
	end
	local glass = Breakables.glassKind(part.Name, part.Material, part.Size)
	if glass == "Pane" then
		return "Glass"
	elseif glass == "Segmented" then
		return "Segmented"
	elseif Breakables.isDoor(part.Name, part.Size) then
		return "Door"
	end
	return nil
end
BreakService.kindOf = kindOf

-- Las ventanas y puertas de decoración no las ven los rayos (CanQuery = false): se les activa para
-- que la piedra, las balas y los coches choquen con ellas (siguen sin chocar con las personas:
-- CanCollide no cambia)
local function makeHittable(part: Instance)
	if part:IsA("BasePart") and not part.CanQuery and (Breakables.glassKind(part.Name, part.Material, part.Size) ~= nil or Breakables.isDoor(part.Name, part.Size)) then
		part.CanQuery = true
	end
end

---------------------------------------------------------------------
-- Romper
---------------------------------------------------------------------

local function track(part: BasePart, kind: string, saved: Saved, extra: { BasePart }?, extraSaved: { Saved }?)
	local now = os.clock()
	broken[part] = {
		Kind = kind,
		Saved = saved,
		Size = part.Size,
		BrokenAt = now,
		RepairAt = now + Breakables.repairDelay(if kind == "Glass" then "Glass" else "Door", math.random()),
		Extra = extra or {},
		ExtraSaved = extraSaved or {},
	}
	brokenCount += 1
	part:SetAttribute("Broken", true)
end

-- Un cristal entero (o un tramo) se rompe: trozos, sonido y hueco (que no choca: se puede pasar)
local function breakPane(part: BasePart, hitAt: Vector3, velocity: Vector3)
	local saved = remember(part)
	-- Cristal de decoración pegado a la fachada (no choca): detrás no hay nada, queda un hueco oscuro
	local backed = not part.CanCollide
	track(part, "Glass", saved)
	shards(part, saved.Color, saved.Transparency, velocity)
	if backed then
		part.Material = Enum.Material.SmoothPlastic
		part.Color = HOLE_COLOR
		part.Reflectance = 0
		part.Transparency = 0.05
	else
		part.Transparency = 1
	end
	part.CanCollide = false
	part.CanQuery = false
	glassSound(hitAt)
end

-- Parte un escaparate (o una franja de ventanas) en tramos: el original se esconde y en su sitio
-- quedan copias de un tramo cada una (iguales: color, material, luz de noche…)
local function splitGlass(original: BasePart): Split
	local existing = split[original]
	if existing then
		return existing
	end
	local axis, n, width = Breakables.segmentLayout(original.Size)
	local length = if axis == "X" then original.Size.X else original.Size.Z
	local info: Split = { Segments = {}, Axis = axis, Length = length, N = n, Saved = remember(original) }
	for i = 1, n do
		local seg = original:Clone()
		for _, child in seg:GetChildren() do
			child:Destroy()
		end
		local along = -length / 2 + (i - 0.5) * width
		if axis == "X" then
			seg.Size = Vector3.new(width, original.Size.Y, original.Size.Z)
			seg.CFrame = original.CFrame * CFrame.new(along, 0, 0)
		else
			seg.Size = Vector3.new(original.Size.X, original.Size.Y, width)
			seg.CFrame = original.CFrame * CFrame.new(0, 0, along)
		end
		seg:SetAttribute("Segment", i)
		seg.Parent = original.Parent
		segmentOf[seg] = original
		info.Segments[i] = seg
	end
	split[original] = info
	original:SetAttribute("Broken", true)
	original.Transparency = 1
	original.CanCollide = false
	original.CanQuery = false
	return info
end

-- Cuando todos sus tramos están arreglados, vuelve el cristal entero (una sola pieza, como siempre)
local function mergeGlass(original: BasePart)
	local info = split[original]
	if not info then
		return
	end
	for _, seg in info.Segments do
		if broken[seg] then
			return
		end
	end
	for _, seg in info.Segments do
		segmentOf[seg] = nil
		seg:Destroy()
	end
	split[original] = nil
	local saved = info.Saved
	original.CanCollide = saved.CanCollide
	original.CanQuery = saved.CanQuery
	original.Transparency = saved.Transparency
	original:SetAttribute("Broken", nil)
end

-- Tramos que rompe un golpe en `at` (half = medio ancho de lo que golpea: un coche rompe varios)
local function segmentsHit(original: BasePart, at: Vector3, half: number): { BasePart }
	local info = splitGlass(original)
	local localAt = original.CFrame:PointToObjectSpace(at)
	local coord = if info.Axis == "X" then localAt.X else localAt.Z
	local list = {}
	for _, i in Breakables.segmentsAround(coord, half, info.Length, info.N) do
		local seg = info.Segments[i]
		if seg and not broken[seg] then
			table.insert(list, seg)
		end
	end
	return list
end

-- Una puerta recibe un golpe: se va estropeando y, sin aguante, se cae (o se abre de golpe, las de
-- las salas). Devuelve true si ha cedido.
local function hitDoor(part: BasePart, hitAt: Vector3, velocity: Vector3, damage: number, swing: boolean): boolean
	if damage <= 0 then
		return false
	end
	local now = os.clock()
	local door = doorState[part]
	if not door then
		door = { Health = Breakables.DoorHealth, Last = now, Color = part.Color, CFrame = part.CFrame }
		doorState[part] = door
	end
	local state = door :: DoorState
	state.Health = Breakables.doorHealthAfter(state.Health, damage, now - state.Last)
	state.Last = now
	sound(hitAt, "rbxasset://sounds/collide.wav", 0.8, 0.95)
	local push = if velocity.Magnitude > 0.01 then velocity.Unit else Vector3.zero
	if state.Health > 0 then
		-- Aguanta: tiembla un momento y se va viendo más estropeada
		part.Color = state.Color:Lerp(Color3.new(0, 0, 0), Breakables.doorShade(state.Health))
		if not swing then
			part.CFrame = state.CFrame + push * 0.12
			task.delay(0.08, function()
				if doorState[part] == state and not broken[part] then
					part.CFrame = state.CFrame
				end
			end)
		end
		-- Si nadie la vuelve a golpear en un rato, se «recupera»
		local last = state.Last
		task.delay(Breakables.DoorHeal + 0.5, function()
			if doorState[part] == state and state.Last == last and not broken[part] then
				part.Color = state.Color
				doorState[part] = nil
			end
		end)
		return false
	end
	-- Vuelve a su color (y a su sitio) antes de ceder (para dejarla como estaba al arreglarla)
	part.Color = state.Color
	if swing then
		local saved = remember(part)
		track(part, "Swing", saved)
		part:SetAttribute("Forced", true)
		local InteractService = require(script.Parent.InteractService) :: any
		pcall(InteractService.swing, part, true, 0.25)
		sound(hitAt, "rbxasset://sounds/collide.wav", 1, 0.9)
		return true
	end
	part.CFrame = state.CFrame
	-- Se cae: la puerta y su pomo (si lo tiene al lado)
	local extra: { BasePart } = {}
	local parent = part.Parent
	if parent then
		for _, sibling in parent:GetChildren() do
			if sibling:IsA("BasePart") and sibling ~= part and (sibling.Name:find("Knob") or sibling.Name:find("Handle")) and (sibling.Position - part.Position).Magnitude < 4 and not broken[sibling] then
				table.insert(extra, sibling)
			end
		end
	end
	local extraSaved = {}
	for i, p in extra do
		extraSaved[i] = remember(p)
	end
	track(part, "Door", remember(part), extra, extraSaved)
	for _, p in { part, table.unpack(extra) } do
		p.Anchored = false
		-- (sigue chocando con el suelo, pero el hueco queda libre: no vuelve a su sitio)
		p.CanCollide = true
		p.CanQuery = false
	end
	part.AssemblyLinearVelocity = push * 14 + Vector3.new(0, 4, 0)
	sound(hitAt, "rbxasset://sounds/collide.wav", 1, 0.9)
	return true
end

---------------------------------------------------------------------
-- Arreglar
---------------------------------------------------------------------

local function restoreProps(p: BasePart, saved: Saved, fadeIn: boolean)
	p.Anchored = true -- (todo lo que se rompe estaba anclado: plainPart)
	p.AssemblyLinearVelocity = Vector3.zero
	p.AssemblyAngularVelocity = Vector3.zero
	p.CFrame = saved.CFrame
	p.Color = saved.Color
	p.Material = saved.Material
	p.Reflectance = saved.Reflectance
	p.CanCollide = saved.CanCollide
	p.CanQuery = saved.CanQuery
	-- Las franjas «Soft» (WorldService) cambian de transparencia con la luz de noche
	local target = saved.Transparency
	if p:GetAttribute("Soft") and p:HasTag("NightWindow") then
		target = if p.Material == Enum.Material.Neon then 0.45 else 0
	end
	if fadeIn then
		p.Transparency = 1
		fade(p, target, Breakables.FadeIn)
	else
		p.Transparency = target
	end
end

local function repair(part: BasePart, piece: Piece)
	broken[part] = nil
	brokenCount = math.max(0, brokenCount - 1)
	part:SetAttribute("Broken", nil)
	if not part.Parent then
		doorState[part] = nil
		return
	end
	if piece.Kind == "Swing" then
		part:SetAttribute("Forced", nil)
		doorState[part] = nil
		if part:GetAttribute("Open") == true then
			local InteractService = require(script.Parent.InteractService) :: any
			pcall(InteractService.swing, part, false)
		end
		return
	end
	restoreProps(part, piece.Saved, true)
	for i, p in piece.Extra do
		local saved = piece.ExtraSaved[i]
		if saved and p.Parent then
			restoreProps(p, saved, true)
		end
	end
	doorState[part] = nil
	local original = segmentOf[part]
	if original then
		task.delay(Breakables.FadeIn + 0.1, function()
			if split[original] then
				mergeGlass(original)
			end
		end)
	end
end

-- Dónde está la gente (para no arreglar nada con alguien en el hueco)
local function peoplePoints(): { Vector3 }
	local points = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			table.insert(points, root.Position)
		end
	end
	return points
end

-- Cada medio segundo: lo que toca arreglar (si el hueco está libre). points: dónde está la gente
-- (las pruebas lo pasan; si no, los jugadores)
function BreakService.stepRepairs(now: number?, points: { Vector3 }?)
	local t = now or os.clock()
	local people = points or peoplePoints()
	-- Demasiadas cosas rotas a la vez: la más antigua se arregla ya (si el hueco está libre)
	if brokenCount > Breakables.Budget.MaxBroken then
		local oldest, oldestAt = nil, math.huge
		for part, piece in broken do
			if piece.BrokenAt < oldestAt then
				oldest, oldestAt = part, piece.BrokenAt
			end
		end
		if oldest then
			broken[oldest].RepairAt = math.min(broken[oldest].RepairAt, t)
		end
	end
	local due = {}
	for part, piece in broken do
		if piece.RepairAt <= t then
			table.insert(due, part)
		end
	end
	for _, part in due do
		local piece = broken[part]
		if piece then
			local home = if piece.Kind == "Swing" then part:GetAttribute("Closed") else piece.Saved.CFrame
			if typeof(home) == "CFrame" and Breakables.occupied(home, piece.Size, people) then
				piece.RepairAt = t + Breakables.RepairRetry
			else
				local ok, err = pcall(repair, part, piece)
				if not ok then
					warn("[BreakService] " .. tostring(err))
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- Consecuencias
---------------------------------------------------------------------

local function personOf(part: BasePart): (Model?, Player?)
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		if model:FindFirstChildOfClass("Humanoid") then
			return model, Players:GetPlayerFromCharacter(model)
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil, nil
end

local function alertPolice(player: Player, at: Vector3, what: string, source: string)
	-- «Daños» si lo ve alguien (WantedService decide: testigos, policía, edad, modo pruebas)
	local stars = player:GetAttribute("Wanted")
	local crime = Breakables.vandalCrime(source, if type(stars) == "number" then stars else 0, os.clock() - (lastVandal[player] or -math.huge))
	if crime then
		lastVandal[player] = os.clock()
		local WantedService = require(script.Parent.WantedService) :: any
		task.spawn(function()
			local ok, err = pcall(WantedService.crime, player, crime, at)
			if not ok then
				warn("[BreakService] " .. tostring(err))
			end
		end)
	end
	if os.clock() - (lastAlert[player] or 0) < 20 then
		return
	end
	lastAlert[player] = os.clock()
	player:SetAttribute("Vandalismo", (player:GetAttribute("Vandalismo") or 0) + 1)
	StoryEvents.emit(player, "Vandalism", { What = what }) -- (al historial de comportamiento)
	local zone = LocationService.zoneAt(at) or "la ciudad"
	for _, other in Players:GetPlayers() do
		if other ~= player and other:GetAttribute("Job") == "Policia" and Notify then
			Notify:FireClient(other, "Info", ("🚨 Vandalismo en %s: %s"):format(zone, what))
		end
	end
end

local HOW = { Stone = "", Bullet = " a tiros", Melee = " a golpes", MeleeHeavy = " a golpes", Vehicle = " con un coche" }

-- Algo golpea una pieza. source: "Stone", "Bullet", "Melee", "MeleeHeavy" o "Vehicle".
-- opts.Speed (vehículo: studs/s) y opts.Half (medio ancho de lo que golpea: un coche rompe varios
-- tramos de un escaparate). Devuelve "Glass", "Door" o nil (no se rompe / no le hace nada).
function BreakService.hit(player: Player, part: Instance, hitAt: Vector3, velocity: Vector3, source: string, opts: { Speed: number?, Half: number? }?): string?
	local kind = kindOf(part)
	if not kind then
		return nil
	end
	local p = part :: BasePart
	local speed = opts and opts.Speed
	if kind == "Glass" or kind == "Segmented" then
		if not Breakables.breaksGlass(source, speed) then
			sound(hitAt, "rbxasset://sounds/collide.wav", 0.4, 1.8)
			return nil
		end
		history[player] = history[player] or {}
		if not Breakables.allow(history[player], os.clock()) then
			return nil
		end
		if kind == "Segmented" then
			local list = segmentsHit(p, hitAt, opts and opts.Half or 0)
			if #list == 0 then
				return nil -- (ese tramo ya estaba roto)
			end
			for _, seg in list do
				breakPane(seg, hitAt, velocity)
			end
		else
			breakPane(p, hitAt, velocity)
		end
		alertPolice(player, hitAt, "han roto un cristal" .. (HOW[source] or ""), source)
		return "Glass"
	end
	-- Puertas
	local damage = Breakables.doorDamageFrom(source, speed)
	if damage <= 0 then
		return nil
	end
	local state = doorState[p]
	local wouldBreak = (state and Breakables.doorHealthAfter(state.Health, damage, os.clock() - state.Last) or Breakables.DoorHealth - damage) <= 0
	if wouldBreak then
		history[player] = history[player] or {}
		if not Breakables.allow(history[player], os.clock()) then
			return nil
		end
	end
	if hitDoor(p, hitAt, velocity, damage, kind == "Swing") then
		alertPolice(player, hitAt, (if kind == "Swing" then "han reventado una puerta" else "han tirado una puerta abajo") .. (HOW[source] or ""), source)
	end
	return "Door"
end

-- Una bala de WeaponService: rompe cristales y castiga puertas. weaponKind: Kind del arma (solo
-- "Real": las de agua y de pintura no rompen nada). Devuelve "Glass", "Door" o nil.
function BreakService.hitStructure(player: Player, part: Instance, hitAt: Vector3, velocity: Vector3, weaponKind: string?): string?
	if weaponKind ~= nil and not Breakables.bulletBreaks(weaponKind) then
		return nil
	end
	return BreakService.hit(player, part, hitAt, velocity, "Bullet")
end

-- Un golpe cuerpo a cuerpo que no ha dado a nadie (CombatService): ¿hay delante un cristal o una
-- puerta? heavy = el golpe fuerte del combo (rompe cristales; los flojos solo dañan puertas)
function BreakService.meleeHit(player: Player, origin: Vector3, look: Vector3, reach: number, heavy: boolean): string?
	if look.Magnitude < 0.01 then
		return nil
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	local result = workspace:Raycast(origin, look.Unit * reach, params)
	if not result then
		return nil
	end
	return BreakService.hit(player, result.Instance, result.Position, look.Unit * 30, if heavy then "MeleeHeavy" else "Melee")
end

-- Un vehículo (KnockService ya ha comprobado que es de verdad: que está al lado y a esa velocidad)
function BreakService.vehicleHit(player: Player, part: Instance, at: Vector3, velocity: Vector3, half: number): string?
	return BreakService.hit(player, part, at, velocity, "Vehicle", { Speed = velocity.Magnitude, Half = half })
end

local function impact(stone: Stone, result: RaycastResult, velocity: Vector3)
	local part = result.Instance
	local what = BreakService.hit(stone.Player, part, result.Position, velocity, "Stone")
	if what then
		return
	end
	if part:IsA("BasePart") then
		local model, victim = personOf(part)
		if victim then
			Notify:FireClient(victim, "Error", "🥌 ¡Te han tirado una piedra!")
		elseif model and model:FindFirstChild("Head") then
			Npc.say(model, "¡Eh! ¿Qué haces?")
			task.delay(3, function()
				if model.Parent then
					Npc.say(model, nil)
				end
			end)
		end
	end
	sound(result.Position, "rbxasset://sounds/collide.wav", 0.5, 1.3)
end

-- Una piedra que ha chocado se queda en el suelo un rato
local function dropStone(at: Vector3, velocity: Vector3)
	local rock = Instance.new("Part")
	rock.Name = "Piedra"
	stoneLook(rock, 0.7)
	rock.CanQuery = false
	rock.CanTouch = false
	rock.CFrame = CFrame.new(at - velocity.Unit * 0.4)
	rock.AssemblyLinearVelocity = -velocity * 0.15 + Vector3.new(0, 5, 0)
	rock.Parent = workspace
	Debris:AddItem(rock, 6)
end

---------------------------------------------------------------------
-- Vuelo de las piedras (rayos entre una posición y la siguiente)
---------------------------------------------------------------------

local function gravity(): number
	return workspace.Gravity * Breakables.GravityScale
end

local function stepStones()
	if #stones == 0 then
		return
	end
	local now = workspace:GetServerTimeNow()
	local g = gravity()
	for i = #stones, 1, -1 do
		local stone = stones[i]
		local t = now - stone.Start
		local position = Breakables.positionAt(stone.From, stone.Velocity, g, t)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local ignore: { Instance } = { stone.Player.Character :: Instance }
		params.FilterDescendantsInstances = ignore
		local step = position - stone.Last
		local result = if step.Magnitude > 0.01 then workspace:Raycast(stone.Last, step, params) else nil
		-- Las zonas invisibles (habitaciones, marcas de las misiones…) no paran la piedra
		local tries = 0
		while result and tries < 4 and result.Instance.Transparency > 0.95 and not result.Instance.CanCollide do
			tries += 1
			table.insert(ignore, result.Instance)
			params.FilterDescendantsInstances = ignore
			result = workspace:Raycast(stone.Last, step, params)
		end
		if result then
			local velocity = stone.Velocity + Vector3.new(0, -g * t, 0)
			table.remove(stones, i)
			Remote:FireAllClients("Hit", stone.Id, result.Position)
			local ok, err = pcall(impact, stone, result, velocity)
			if not ok then
				warn("[BreakService] " .. tostring(err))
			end
			dropStone(result.Position, velocity)
		elseif t > MAX_FLIGHT then
			table.remove(stones, i)
			Remote:FireAllClients("Hit", stone.Id, position)
		else
			stone.Last = position
		end
	end
end

---------------------------------------------------------------------
-- Peticiones
---------------------------------------------------------------------

local function rootOf(player: Player): (BasePart?, Humanoid?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or humanoid.Health <= 0 then
		return nil, nil
	end
	return root, humanoid
end

local function canUse(player: Player): boolean
	local _, humanoid = rootOf(player)
	if not humanoid or humanoid.Sit then
		return false
	end
	if player:GetAttribute("LifeStage") == "Bebe" or player:GetAttribute("Crawling") or player:GetAttribute("Sleeping") or player:GetAttribute("Riding") then
		return false
	end
	return true
end

local function pick(player: Player)
	if os.clock() - (lastPick[player] or 0) < PICK_COOLDOWN or not canUse(player) then
		return
	end
	lastPick[player] = os.clock()
	local count = player:GetAttribute("Stones") or 0
	if count >= Breakables.MaxStones then
		Notify:FireClient(player, "Info", ("🥌 Ya llevas %d piedras."):format(count))
		return
	end
	local root = rootOf(player)
	if not root then
		return
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	local ground = workspace:Raycast(root.Position, Vector3.new(0, -10, 0), params)
	if not ground or not Breakables.canPickFrom(ground.Material) then
		Notify:FireClient(player, "Error", "🥌 Aquí no hay piedras: busca tierra, césped, arena o roca.")
		return
	end
	setStones(player, count + 1)
end

local function throw(player: Player, target: any)
	if typeof(target) ~= "Vector3" or target ~= target then
		return
	end
	if os.clock() - (lastThrow[player] or 0) < THROW_COOLDOWN or not canUse(player) then
		return
	end
	local count = player:GetAttribute("Stones") or 0
	if count <= 0 then
		return
	end
	local character = player.Character :: Model
	local head = character:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	local toTarget = target - head.Position
	if toTarget.Magnitude < 1 then
		return
	end
	if toTarget.Magnitude > MAX_RANGE then
		target = head.Position + toTarget.Unit * MAX_RANGE
	end
	lastThrow[player] = os.clock()
	setStones(player, count - 1)
	-- (si el blanco está justo encima o debajo, .Unit daría NaN: se usa hacia dónde mira)
	local flat = Vector3.new(toTarget.X, 0, toTarget.Z)
	local from = head.Position + Vector3.new(0, 0.3, 0) + (if flat.Magnitude > 0.01 then flat.Unit else head.CFrame.LookVector) * 1.5
	local velocity = Breakables.launch(from, target, Breakables.ThrowSpeed, gravity())
	nextId += 1
	local stone: Stone = { Id = nextId, Player = player, From = from, Velocity = velocity, Start = workspace:GetServerTimeNow(), Last = from }
	table.insert(stones, stone)
	Remote:FireAllClients("Stone", stone.Id, from, velocity, stone.Start, gravity())
end

function BreakService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:WaitForChild("Vandal") :: RemoteEvent
	Notify = remotes:WaitForChild("Notify") :: RemoteEvent
	Remote.OnServerEvent:Connect(function(player, action, data)
		if action == "Pick" then
			pick(player)
		elseif action == "Throw" then
			throw(player, data)
		end
	end)
	local function onPlayer(player: Player)
		player:SetAttribute("Stones", 0)
		player.CharacterAdded:Connect(function()
			player:SetAttribute("Stones", 0) -- al reaparecer, sin piedras
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	-- (los que ya estaban dentro antes de que arrancara este servicio)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayer, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastPick[player] = nil
		lastThrow[player] = nil
		lastAlert[player] = nil
		lastVandal[player] = nil
		history[player] = nil
		for i = #stones, 1, -1 do
			if stones[i].Player == player then
				table.remove(stones, i)
			end
		end
	end)
	task.spawn(function()
		for i, part in workspace:GetDescendants() do
			makeHittable(part)
			if i % 5000 == 0 then
				task.wait()
			end
		end
	end)
	-- Lo roto se arregla solo (cada medio segundo se mira qué toca y si el hueco está libre)
	task.spawn(function()
		while true do
			task.wait(0.5)
			local ok, err = pcall(BreakService.stepRepairs)
			if not ok then
				warn("[BreakService] " .. tostring(err))
			end
		end
	end)
	RunService.Heartbeat:Connect(function()
		local ok, err = pcall(stepStones)
		if not ok then
			warn("[BreakService] " .. tostring(err))
		end
	end)
end

return BreakService
