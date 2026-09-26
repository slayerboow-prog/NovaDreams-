-- PoliceService: oficio de policía (desde mayor de edad).
--
--   1) Tablón "Trabajar" de la comisaría -> te pones el uniforme (gorra y chaleco) y empiezan los
--      AVISOS por la ciudad. Fuera tienes el COCHE PATRULLA (carnet B), con sirena (tecla K).
--   2) Tipos de aviso (la línea azul y tu panel te dicen dónde y qué hacer):
--        🦹 Robo        -> un ladrón con un bolso. Al verte llegar, sale corriendo: alcánzale y
--                          "Detener".
--        🅿️ Multa        -> un coche aparcado en la acera con los intermitentes: "Poner multa".
--        💥 Accidente   -> dos coches chocados echando humo: "Poner conos" y "Atender al herido".
--        🧓 Perdido     -> alguien desorientado: "Tomar datos" y luego "Entregar informe" en el
--                          mostrador de la comisaría.
--   3) Cobras por aviso resuelto (más si está lejos). Cada aviso cuenta para la historia
--      (JobTaskDone con JobId "Policia"). Si tardas mucho, el aviso se cancela y llega otro.
-- Todo lo del aviso solo lo ve y lo usa el policía que lo tiene (JobOnly / OwnerUserId).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Format = require(ReplicatedStorage.Shared.Format)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local Npc = require(script.Parent.Parent.World.Npc)
local CarModel = require(script.Parent.Parent.World.Kit.CarModel)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)
local LifeService = require(script.Parent.LifeService)
local MonetizationService = require(script.Parent.MonetizationService)
local RoleService = require(script.Parent.RoleService)
local JobService = require(script.Parent.JobService)
local VehicleService = require(script.Parent.VehicleService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local PoliceService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.Police :: RemoteEvent
local P = Gameplay.Police
local WALK = 1

local KINDS = {
	Robo = { Icon = "🦹", Title = "Robo en la calle", Text = "Una vecina denuncia un tirón de bolso." },
	Multa = { Icon = "🅿️", Title = "Coche mal aparcado", Text = "Un coche bloquea la acera." },
	Accidente = { Icon = "💥", Title = "Accidente de tráfico", Text = "Dos coches han chocado." },
	Perdido = { Icon = "🧓", Title = "Persona desorientada", Text = "Alguien no sabe volver a casa." },
}
local KIND_LIST = { "Robo", "Multa", "Accidente", "Perdido" }

type Station = { Model: Model, Desk: BasePart, Patrol: BasePart? }
type Incident = {
	Kind: string,
	Position: Vector3,
	Along: Vector3,
	ToRoad: Vector3,
	Folder: Folder,
	Step: string,
	Started: number,
	Distance: number,
	Busy: boolean,
	Npc: Model?,
	Fleeing: boolean?,
}
type Shift = { Player: Player, Station: Station, Incident: Incident?, Uniform: Folder? }

local stations: { Station } = {}
local shifts: { [Player]: Shift } = {}
local world: Folder

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function stationNear(position: Vector3, range: number): Station?
	local best, bestDist = nil, range
	for _, s in stations do
		local d = (s.Desk.Position - position).Magnitude
		if d < bestDist then
			best, bestDist = s, d
		end
	end
	return best
end

---------------------------------------------------------------------
-- Uniforme
---------------------------------------------------------------------

local function dress(shift: Shift)
	if shift.Uniform then
		shift.Uniform:Destroy()
		shift.Uniform = nil
	end
	local character = shift.Player.Character
	local head = character and character:FindFirstChild("Head") :: BasePart?
	local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")) :: BasePart?
	if not head or not torso then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "PoliceUniform"
	local function piece(to: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?): BasePart
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CFrame = to.CFrame * offset
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = to
		weld.Part1 = p
		weld.Parent = p
		p.Parent = folder
		return p
	end
	local h, t = head.Size, torso.Size
	local navy = Color3.fromRGB(24, 40, 90)
	piece(head, "Cap", Vector3.new(h.X * 1.1, h.Y * 0.35, h.Z * 1.1), CFrame.new(0, h.Y * 0.45, 0), navy, Enum.Material.Fabric)
	piece(head, "CapPeak", Vector3.new(h.X * 0.9, 0.08, h.Z * 0.45), CFrame.new(0, h.Y * 0.3, -h.Z * 0.62), Color3.fromRGB(20, 20, 24))
	piece(head, "CapBand", Vector3.new(h.X * 1.12, h.Y * 0.1, h.Z * 1.12), CFrame.new(0, h.Y * 0.3, 0), Color3.fromRGB(240, 240, 240))
	piece(head, "CapBadge", Vector3.new(h.X * 0.22, h.Y * 0.2, 0.05), CFrame.new(0, h.Y * 0.47, -h.Z * 0.56), Color3.fromRGB(250, 200, 40), Enum.Material.Metal)
	piece(torso, "Vest", Vector3.new(t.X * 1.06, t.Y * 0.95, t.Z * 1.12), CFrame.new(0, -t.Y * 0.02, 0), Color3.fromRGB(200, 230, 40), Enum.Material.Fabric)
	piece(torso, "VestStripe", Vector3.new(t.X * 1.08, t.Y * 0.1, t.Z * 1.14), CFrame.new(0, -t.Y * 0.2, 0), Color3.fromRGB(220, 220, 220), Enum.Material.Neon)
	local back = piece(torso, "VestBack", Vector3.new(t.X * 0.8, t.Y * 0.3, 0.05), CFrame.new(0, t.Y * 0.15, t.Z * 0.58), navy)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.CanvasSize = Vector2.new(200, 60)
	gui.Parent = back
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "POLICÍA"
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.fromRGB(250, 250, 250)
	label.Parent = gui
	piece(torso, "Badge", Vector3.new(t.X * 0.14, t.X * 0.16, 0.05), CFrame.new(-t.X * 0.28, t.Y * 0.22, -t.Z * 0.58), Color3.fromRGB(250, 200, 40), Enum.Material.Metal)
	piece(torso, "Radio", Vector3.new(t.X * 0.12, t.Y * 0.3, 0.2), CFrame.new(t.X * 0.3, t.Y * 0.2, -t.Z * 0.62), Color3.fromRGB(30, 30, 34))
	folder.Parent = character
	shift.Uniform = folder
end

---------------------------------------------------------------------
-- Dónde pasan los avisos: en las aceras de las calles publicadas (ReplicatedStorage.Ambient.Roads)
---------------------------------------------------------------------

local function sidewalkSpot(origin: Vector3): (Vector3?, Vector3, Vector3)
	local ambient = ReplicatedStorage:FindFirstChild("Ambient")
	local roads = ambient and ambient:FindFirstChild("Roads")
	if not roads then
		return nil, Vector3.new(0, 0, 1), Vector3.new(1, 0, 0)
	end
	local list = roads:GetChildren()
	for _ = 1, 40 do
		local config = list[math.random(1, #list)]
		local a, b = config:GetAttribute("A"), config:GetAttribute("B")
		if typeof(a) == "Vector3" and typeof(b) == "Vector3" and config:GetAttribute("Kind") ~= "Autovia" and (b - a).Magnitude > 60 then
			local dir = (b - a).Unit
			local perp = Vector3.new(-dir.Z, 0, dir.X)
			local width = config:GetAttribute("Width") or 24
			local t = 20 + math.random() * ((b - a).Magnitude - 40)
			local side = if math.random() < 0.5 then 1 else -1
			local p = a + dir * t + perp * side * (width / 2 + 3.5)
			local spot = Vector3.new(p.X, WALK, p.Z)
			local d = Vector3.new(spot.X - origin.X, 0, spot.Z - origin.Z).Magnitude
			if d >= P.MinDistance and d <= P.MaxDistance then
				return spot, dir, -perp * side -- (de la acera hacia la calzada)
			end
		end
	end
	return nil, Vector3.new(0, 0, 1), Vector3.new(1, 0, 0)
end

---------------------------------------------------------------------
-- Avisos
---------------------------------------------------------------------

local newIncident -- se define más abajo

local function publish(shift: Shift)
	local player = shift.Player
	local inc = shift.Incident
	if not inc then
		Remote:FireClient(player, "Incident", nil)
		player:SetAttribute("TaskTarget", nil)
		player:SetAttribute("TaskText", "Espera el próximo aviso")
		return
	end
	local kind = KINDS[inc.Kind]
	local steps = {
		Robo = if inc.Fleeing then "¡Huye! Alcánzale y deténle." else "Ve al lugar del robo.",
		Multa = "Pon la multa al coche mal aparcado.",
		Cones = "Pon los conos para cortar el paso.",
		Injured = "Atiende al herido.",
		Perdido = "Habla con la persona y toma sus datos.",
		Report = "Entrega el informe en el mostrador de la comisaría.",
	}
	local left = math.max(0, math.floor(P.TimeLimit - (os.clock() - inc.Started)))
	Remote:FireClient(player, "Incident", { Icon = kind.Icon, Title = kind.Title, Text = kind.Text, Step = steps[inc.Step] or "", Left = left })
	local target = inc.Position
	if inc.Step == "Report" then
		target = shift.Station.Desk.Position
	elseif inc.Npc and inc.Npc.PrimaryPart then
		target = inc.Npc.PrimaryPart.Position
	end
	player:SetAttribute("TaskTarget", target)
	player:SetAttribute("TaskText", ("%s %s · %s"):format(kind.Icon, kind.Title, steps[inc.Step] or ""))
end

local function ownPrompt(shift: Shift, parent: Instance, action: string, object: string, hold: number, callback: () -> ()): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = hold
	p.MaxActivationDistance = 10
	p.RequiresLineOfSight = false
	p:SetAttribute("JobOnly", "Policia")
	p:SetAttribute("OwnerUserId", shift.Player.UserId)
	p.Parent = parent
	p.Triggered:Connect(function(player)
		if player == shift.Player and shifts[player] == shift then
			callback()
		end
	end)
	return p
end

local function clearIncident(inc: Incident, delay: number?)
	local folder = inc.Folder
	if delay and delay > 0 then
		-- Los prompts se quitan ya; lo demás se va al cabo de un rato
		for _, d in folder:GetDescendants() do
			if d:IsA("ProximityPrompt") and d:GetAttribute("OwnerUserId") then
				d:Destroy()
			end
		end
		task.delay(delay, function()
			folder:Destroy()
		end)
	else
		folder:Destroy()
	end
end

local function solve(shift: Shift)
	local inc = shift.Incident
	if not inc then
		return
	end
	local player = shift.Player
	shift.Incident = nil
	clearIncident(inc, 15)
	local pay = math.floor(((P.Pay[inc.Kind] or 20) + inc.Distance * P.PerStud) * MonetizationService.payMultiplier(player))
	DataService.addMoney(player, pay, true)
	local data = DataService.get(player)
	if data then
		data.Stats.TasksDone += 1
	end
	NeedsService.change(player, 0, -P.EnergyCost)
	Notify:FireClient(player, "Money", ("+%s · %s resuelto"):format(Format.money(pay), KINDS[inc.Kind].Title))
	StoryEvents.emit(player, "JobTaskDone", { JobId = "Policia", Pay = pay })
	publish(shift)
	if not NeedsService.canWork(player) then
		PoliceService.quit(player, true)
		Notify:FireClient(player, "Error", "Estás agotado. Come algo o duerme antes de seguir trabajando.")
		return
	end
	task.delay(5, function()
		if shifts[player] == shift and not shift.Incident then
			newIncident(shift)
		end
	end)
end

local function cone(parent: Instance, position: Vector3)
	local base = Instance.new("Part")
	base.Name = "ConeBase"
	base.Size = Vector3.new(1.4, 0.2, 1.4)
	base.CFrame = CFrame.new(position + Vector3.new(0, 0.1, 0))
	base.Color = Color3.fromRGB(30, 30, 34)
	base.Anchored = true
	base.CanCollide = false
	base.Parent = parent
	local body = Instance.new("Part")
	body.Name = "Cone"
	body.Shape = Enum.PartType.Cylinder
	body.Size = Vector3.new(2, 0.9, 0.9)
	body.CFrame = CFrame.new(position + Vector3.new(0, 1.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	body.Color = Color3.fromRGB(250, 110, 20)
	body.Anchored = true
	body.CanCollide = false
	body.Parent = parent
	local band = body:Clone()
	band.Name = "ConeBand"
	band.Size = Vector3.new(0.4, 0.95, 0.95)
	band.Color = Color3.fromRGB(250, 250, 250)
	band.CFrame = CFrame.new(position + Vector3.new(0, 1.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
	band.Parent = parent
end

local BUILD = {}

function BUILD.Robo(shift: Shift, inc: Incident)
	local cf = CFrame.lookAt(inc.Position, inc.Position + inc.Along)
	local thief = Npc.create("Ladron", inc.Folder, cf, { Shirt = Color3.fromRGB(30, 30, 34), Pants = Color3.fromRGB(40, 40, 46) })
	inc.Npc = thief
	local root = thief.PrimaryPart :: BasePart
	-- Bolso robado en la mano y la víctima gritando
	local bag = Instance.new("Part")
	bag.Name = "StolenBag"
	bag.Size = Vector3.new(0.9, 1, 0.5)
	bag.Color = Color3.fromRGB(200, 40, 90)
	bag.CanCollide = false
	bag.Massless = true
	bag.CFrame = root.CFrame * CFrame.new(1.2, -1, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = bag
	weld.Parent = bag
	bag.Parent = thief
	local victim = Npc.create("Victima", inc.Folder, cf * CFrame.new(3, 0, -4), nil)
	Npc.say(victim, "¡Al ladrón! ¡Se ha llevado mi bolso!")
	ownPrompt(shift, root, "Detener", "🦹 Ladrón", 0.6, function()
		inc.Busy = true
		Npc.say(thief, "Vale, vale… me rindo.")
		Npc.say(victim, "¡Gracias, agente! Mi bolso…")
		local cuffs = Instance.new("Part")
		cuffs.Name = "Handcuffs"
		cuffs.Size = Vector3.new(1.2, 0.2, 0.4)
		cuffs.Color = Color3.fromRGB(200, 204, 210)
		cuffs.Material = Enum.Material.Metal
		cuffs.CanCollide = false
		cuffs.Massless = true
		cuffs.CFrame = root.CFrame * CFrame.new(0, -1, 0.7)
		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = cuffs
		w.Parent = cuffs
		cuffs.Parent = thief
		solve(shift)
	end)
	-- Cuando el policía se acerca, sale corriendo por la acera
	task.spawn(function()
		while shift.Incident == inc and thief.Parent do
			local r = rootOf(shift.Player)
			if r and (r.Position - root.Position).Magnitude < 30 then
				inc.Fleeing = true
				Npc.say(thief, "¡La poli!")
				publish(shift)
				local from = root.Position - Vector3.new(0, root.Position.Y - WALK, 0)
				Npc.walkTo(thief, { from + inc.Along * 45, from + inc.Along * 90 }, P.FleeSpeed)
				if shift.Incident == inc and not inc.Busy then
					Npc.say(thief, "Uf… no puedo más.")
				end
				break
			end
			task.wait(0.3)
		end
	end)
end

function BUILD.Multa(shift: Shift, inc: Incident)
	local cf = CFrame.lookAt(inc.Position, inc.Position + inc.Along) * CFrame.new(0, 0, 0)
	local car = CarModel.build(inc.Folder, cf * CFrame.Angles(0, math.rad(8), 0), Color3.fromHSV(math.random(), 0.6, 0.7), { Name = "BadlyParked", Lite = true })
	local body = car:FindFirstChild("Body") :: BasePart?
	-- Intermitentes de emergencia encendidos
	for _, d in car:GetDescendants() do
		if d:IsA("BasePart") and (d.Name == "Taillight" or d.Name == "Headlight" or d.Name == "HeadlightRight") then
			d.Color = Color3.fromRGB(255, 160, 30)
		end
	end
	ownPrompt(shift, body or car:FindFirstChildWhichIsA("BasePart") :: BasePart, "Poner multa", "🅿️ Mal aparcado", 1.5, function()
		if body then
			local ticket = Instance.new("Part")
			ticket.Name = "Ticket"
			ticket.Size = Vector3.new(0.8, 0.05, 1.2)
			ticket.Color = Color3.fromRGB(250, 240, 120)
			ticket.Anchored = true
			ticket.CanCollide = false
			ticket.CFrame = body.CFrame * CFrame.new(0, body.Size.Y / 2 + 1.1, -2.6)
			ticket.Parent = inc.Folder
		end
		solve(shift)
	end)
end

function BUILD.Accidente(shift: Shift, inc: Incident)
	local along = inc.Along
	local perp = -inc.ToRoad -- de la calzada hacia la acera
	local lane = inc.Position - perp * 9
	local road = Vector3.new(lane.X, 0.4, lane.Z) -- sobre el asfalto
	local c1 = CarModel.build(inc.Folder, CFrame.lookAt(road, road + along) * CFrame.Angles(0, math.rad(25), 0), Color3.fromRGB(200, 40, 40), { Name = "Crash1", Lite = true })
	local c2 = CarModel.build(inc.Folder, CFrame.lookAt(road + along * 11, road) * CFrame.Angles(0, math.rad(-35), 0), Color3.fromRGB(40, 90, 180), { Name = "Crash2", Lite = true })
	for _, car in { c1, c2 } do
		local body = car:FindFirstChild("Body") :: BasePart?
		if body then
			local smoke = Instance.new("Smoke")
			smoke.Color = Color3.fromRGB(90, 90, 96)
			smoke.Opacity = 0.35
			smoke.RiseVelocity = 3
			smoke.Size = 3
			smoke.Parent = body
		end
	end
	-- Cristales rotos en el suelo
	for _ = 1, 6 do
		local shard = Instance.new("Part")
		shard.Name = "Glass"
		shard.Size = Vector3.new(0.4 + math.random() * 0.5, 0.05, 0.3 + math.random() * 0.4)
		shard.Color = Color3.fromRGB(200, 230, 240)
		shard.Material = Enum.Material.Glass
		shard.Transparency = 0.3
		shard.Anchored = true
		shard.CanCollide = false
		shard.CFrame = CFrame.new(road + along * 5.5 + Vector3.new(math.random(-3, 3), 0.45, math.random(-3, 3))) * CFrame.Angles(0, math.random() * 6, 0)
		shard.Parent = inc.Folder
	end
	local injured = Npc.create("Herido", inc.Folder, CFrame.lookAt(inc.Position, inc.Position - perp), nil)
	inc.Npc = injured
	Npc.say(injured, "Ay… me duele el brazo.")
	local site = Instance.new("Part")
	site.Name = "Site"
	site.Size = Vector3.new(3, 3, 3)
	site.CFrame = CFrame.new(road + along * 5.5 + Vector3.new(0, 2, 0))
	site.Transparency = 1
	site.Anchored = true
	site.CanCollide = false
	site.Parent = inc.Folder
	inc.Step = "Cones"
	ownPrompt(shift, site, "Poner conos", "💥 Accidente", 1.5, function()
		if inc.Step ~= "Cones" then
			return
		end
		for _, k in { -1, 0, 1 } do
			cone(inc.Folder, road - along * 8 + perp * (k * 4) + Vector3.new(0, 0.4, 0))
			cone(inc.Folder, road + along * 19 + perp * (k * 4) + Vector3.new(0, 0.4, 0))
		end
		inc.Step = "Injured"
		publish(shift)
	end)
	ownPrompt(shift, injured.PrimaryPart :: BasePart, "Atender al herido", "🤕 Herido", 1.5, function()
		if inc.Step ~= "Injured" then
			Notify:FireClient(shift.Player, "Info", "Primero corta el paso con los conos.")
			return
		end
		Npc.say(injured, "Gracias, agente. Ya viene la ambulancia.")
		solve(shift)
	end)
end

function BUILD.Perdido(shift: Shift, inc: Incident)
	local lost = Npc.create("Perdido", inc.Folder, CFrame.lookAt(inc.Position, inc.Position + inc.Along), { Hair = Color3.fromRGB(200, 200, 205) } :: any)
	inc.Npc = lost
	Npc.say(lost, "Perdone… no sé dónde estoy. Yo vivía por aquí…")
	ownPrompt(shift, lost.PrimaryPart :: BasePart, "Tomar datos", "🧓 Persona desorientada", 1.2, function()
		if inc.Step ~= "Perdido" then
			return
		end
		Npc.say(lost, "Me llamo Ramón. Mi hija se llama Pilar… ¡gracias!")
		inc.Step = "Report"
		Notify:FireClient(shift.Player, "Info", "Datos tomados. Entrega el informe en el mostrador de la comisaría.")
		publish(shift)
	end)
end

function newIncident(shift: Shift)
	if shift.Incident then
		clearIncident(shift.Incident)
		shift.Incident = nil
	end
	local origin = shift.Station.Desk.Position
	local position, along, toRoad = sidewalkSpot(origin)
	if not position then
		Notify:FireClient(shift.Player, "Info", "Todo tranquilo por ahora.")
		publish(shift)
		return
	end
	local kind = KIND_LIST[math.random(1, #KIND_LIST)]
	local folder = Instance.new("Folder")
	folder.Name = "Incident_" .. kind
	folder.Parent = world
	local inc: Incident = {
		Kind = kind,
		Position = position,
		Along = along,
		ToRoad = toRoad,
		Folder = folder,
		Step = kind,
		Started = os.clock(),
		Distance = Vector3.new(position.X - origin.X, 0, position.Z - origin.Z).Magnitude,
		Busy = false,
	}
	shift.Incident = inc
	local ok, err = pcall(BUILD[kind], shift, inc)
	if not ok then
		warn("[PoliceService] " .. tostring(err))
	end
	Notify:FireClient(shift.Player, "Info", ("📻 Aviso: %s %s"):format(KINDS[kind].Icon, KINDS[kind].Title))
	publish(shift)
end

local function onDesk(player: Player)
	local shift = shifts[player]
	local inc = shift and shift.Incident
	if not inc or inc.Step ~= "Report" then
		return
	end
	solve(shift :: Shift)
end

---------------------------------------------------------------------
-- Sirena del coche patrulla
---------------------------------------------------------------------

local function toggleSiren(player: Player)
	if not shifts[player] then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	local car = seat and seat:FindFirstAncestorOfClass("Model")
	if car and car:HasTag("PoliceCar") then
		car:SetAttribute("Siren", not car:GetAttribute("Siren"))
	end
end

---------------------------------------------------------------------
-- Turno
---------------------------------------------------------------------

function PoliceService.start(player: Player)
	if not DataService.get(player) or not LifeService.allows(player, "Work") then
		return
	end
	if not Stages.inRange(player:GetAttribute("LifeStage") or "", P.MinStage, nil) then
		Notify:FireClient(player, "Error", "Para ser policía hay que ser mayor de edad.")
		return
	end
	if not NeedsService.canWork(player) then
		Notify:FireClient(player, "Error", "Estás demasiado cansado o hambriento para trabajar.")
		return
	end
	local root = rootOf(player)
	local station = root and stationNear(root.Position, 120)
	if not station then
		return
	end
	JobService.quit(player, true)
	local shift: Shift = { Player = player, Station = station }
	shifts[player] = shift
	RoleService.setOnDuty(player, "Policia")
	player:SetAttribute("Job", "Policia")
	dress(shift)
	Remote:FireClient(player, "Start")
	Notify:FireClient(player, "Success", "¡De servicio! Fuera tienes el coche patrulla (sirena: tecla K).")
	newIncident(shift)
end

function PoliceService.quit(player: Player, silent: boolean?)
	local shift = shifts[player]
	if not shift then
		return
	end
	shifts[player] = nil
	if shift.Incident then
		clearIncident(shift.Incident)
	end
	if shift.Uniform then
		shift.Uniform:Destroy()
	end
	RoleService.offDuty(player, "Policia")
	if player:GetAttribute("Job") == "Policia" then
		player:SetAttribute("Job", nil)
	end
	player:SetAttribute("TaskTarget", nil)
	player:SetAttribute("TaskText", nil)
	Remote:FireClient(player, "Stop")
	if not silent then
		Notify:FireClient(player, "Info", "Has terminado el servicio.")
	end
end

local function setupStation(model: Instance)
	if not model:IsA("Model") then
		return
	end
	for _, s in stations do
		if s.Model == model then
			return
		end
	end
	local desk, patrol
	for _, d in model:GetDescendants() do
		if d:HasTag("PoliceDesk") then
			desk = d
		elseif d:HasTag("PolicePatrol") then
			patrol = d
		end
	end
	if not desk then
		return
	end
	table.insert(stations, { Model = model, Desk = desk, Patrol = patrol })
	local report = Instance.new("ProximityPrompt")
	report.ActionText = "Entregar informe"
	report.ObjectText = "🚔 Mostrador"
	report.HoldDuration = 0.8
	report.MaxActivationDistance = 10
	report.RequiresLineOfSight = false
	report:SetAttribute("JobOnly", "Policia")
	report.Parent = desk
	report.Triggered:Connect(onDesk)
	if patrol then
		local p = Instance.new("ProximityPrompt")
		p.ActionText = "Coche patrulla"
		p.ObjectText = "🚓 Policía (carnet B)"
		p.HoldDuration = 0.4
		p.MaxActivationDistance = 10
		p.RequiresLineOfSight = false
		p:SetAttribute("JobOnly", "Policia")
		p.Parent = patrol
		p.Triggered:Connect(function(player)
			if shifts[player] and not VehicleService.mount(player, "Patrulla", { Rented = true }) then
				Notify:FireClient(player, "Info", "Para el coche patrulla hace falta el carnet B.")
			end
		end)
	end
end

function PoliceService.init()
	world = Instance.new("Folder")
	world.Name = "PoliceIncidents"
	world.Parent = workspace
	for _, model in CollectionService:GetTagged("PoliceStation") do
		setupStation(model)
	end
	CollectionService:GetInstanceAddedSignal("PoliceStation"):Connect(setupStation)
	JobService.setHandler("Policia", { Start = PoliceService.start, Quit = PoliceService.quit })
	Remote.OnServerEvent:Connect(function(player, action)
		if action == "Siren" then
			toggleSiren(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		PoliceService.quit(player, true)
	end)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			local shift = shifts[player]
			if shift then
				task.wait(1)
				dress(shift)
			end
		end)
	end)
	-- Avisos caducados y panel al día
	task.spawn(function()
		while true do
			task.wait(2)
			for player, shift in shifts do
				local inc = shift.Incident
				if inc and not inc.Busy and os.clock() - inc.Started > P.TimeLimit then
					Notify:FireClient(player, "Info", "📻 El aviso lo ha cogido otra patrulla. Hay uno nuevo.")
					newIncident(shift)
				else
					publish(shift)
				end
			end
		end
	end)
end

return PoliceService
