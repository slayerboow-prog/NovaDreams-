-- FireService: oficio de bombero/a (desde mayor de edad).
--
--   1) Tablón "Trabajar" del parque de bomberos -> casco y chaqueta con franjas reflectantes, y
--      empiezan los AVISOS. Tienes el CAMIÓN DE BOMBEROS (carnet B), con sirena (tecla K).
--   2) Tipos de aviso (línea azul y panel):
--        🏠 Casa        -> una casa de verdad de Valmar ardiendo por ventanas y tejado; un vecino
--                          pide ayuda. Echa agua a cada llama ("Apagar fuego") hasta que no quede ninguna.
--        🚗 Coche       -> un coche en llamas en la calzada.
--        🗑️ Papelera    -> una papelera ardiendo en la acera.
--        🐱 Gato        -> un gato subido a una farola; su dueña está preocupada: "Rescatar al gato".
--      Si tardas, el fuego CRECE: las llamas se hacen más grandes y cuesta más apagarlas.
--   3) Cobras por aviso resuelto (más si está lejos). Cada aviso cuenta para la historia
--      (JobTaskDone con JobId "Bombero").
-- Lo del aviso solo lo ve y lo usa el bombero que lo tiene (JobOnly / OwnerUserId).

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

local FireService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.Fire :: RemoteEvent
local F = Gameplay.Fire

local KINDS = {
	Casa = { Icon = "🏠", Title = "Incendio en una vivienda", Text = "Sale humo de una casa." },
	Coche = { Icon = "🚗", Title = "Coche en llamas", Text = "Un coche arde en plena calle." },
	Papelera = { Icon = "🗑️", Title = "Papelera ardiendo", Text = "Alguien tiró una colilla encendida." },
	Gato = { Icon = "🐱", Title = "Gato en apuros", Text = "Un gato no sabe bajar de una farola." },
}
local KIND_LIST = { "Casa", "Casa", "Coche", "Papelera", "Gato" }

type Flame = { Part: BasePart, Hits: number, Fire: Fire, Smoke: Smoke, Glow: BasePart? }
type Incident = {
	Kind: string,
	Position: Vector3,
	Folder: Folder,
	Flames: { Flame },
	Started: number,
	LastGrow: number,
	Distance: number,
	Address: string?,
	Done: boolean,
}
type Station = { Model: Model, Base: BasePart, Truck: BasePart? }
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
		local d = (s.Base.Position - position).Magnitude
		if d < bestDist then
			best, bestDist = s, d
		end
	end
	return best
end

local function anchoredPart(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, transparency: number?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Parent = parent
	return p
end

---------------------------------------------------------------------
-- Uniforme: casco y chaqueta con franjas reflectantes
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
	folder.Name = "FireUniform"
	local function piece(to: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): BasePart
		local p = Instance.new("Part")
		p.Name = name
		p.Shape = shape or Enum.PartType.Block
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
	local yellow = Color3.fromRGB(250, 210, 40)
	local tan = Color3.fromRGB(200, 170, 110)
	local reflect = Color3.fromRGB(250, 250, 200)
	piece(head, "Helmet", Vector3.new(h.X * 1.25, h.Y * 0.95, h.Z * 1.3), CFrame.new(0, h.Y * 0.3, 0.02), yellow, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	piece(head, "HelmetBrim", Vector3.new(h.X * 1.4, 0.1, h.Z * 1.6), CFrame.new(0, h.Y * 0.08, 0.1), yellow)
	piece(head, "HelmetBadge", Vector3.new(h.X * 0.3, h.Y * 0.3, 0.05), CFrame.new(0, h.Y * 0.45, -h.Z * 0.64), Color3.fromRGB(200, 30, 30), Enum.Material.Metal)
	piece(head, "Visor", Vector3.new(h.X * 1.05, h.Y * 0.3, 0.08), CFrame.new(0, h.Y * 0.1, -h.Z * 0.62), Color3.fromRGB(200, 170, 60), Enum.Material.Glass, nil)
	piece(torso, "Jacket", Vector3.new(t.X * 1.08, t.Y * 1.02, t.Z * 1.14), CFrame.new(0, 0, 0), tan, Enum.Material.Fabric)
	for _, y in { -0.25, 0.15 } do
		piece(torso, "Reflective", Vector3.new(t.X * 1.1, t.Y * 0.09, t.Z * 1.16), CFrame.new(0, t.Y * y, 0), reflect, Enum.Material.Neon)
	end
	local back = piece(torso, "JacketBack", Vector3.new(t.X * 0.8, t.Y * 0.28, 0.05), CFrame.new(0, t.Y * 0.3, t.Z * 0.58), tan)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.CanvasSize = Vector2.new(220, 60)
	gui.Parent = back
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "BOMBEROS"
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.fromRGB(200, 30, 30)
	label.Parent = gui
	-- Extintor en la espalda
	piece(torso, "Extinguisher", Vector3.new(t.X * 0.3, t.Y * 1.1, t.X * 0.3), CFrame.new(t.X * 0.25, 0, t.Z * 0.75), Color3.fromRGB(210, 30, 30), Enum.Material.Metal)
	folder.Parent = character
	shift.Uniform = folder
end

---------------------------------------------------------------------
-- Llamas
---------------------------------------------------------------------

local function flameSize(hits: number): number
	return 4 + hits * 2
end

local function addFlame(inc: Incident, position: Vector3, hits: number): Flame
	local part = anchoredPart(inc.Folder, "Flame", Vector3.new(2.5, 2.5, 2.5), CFrame.new(position), Color3.new(1, 1, 1), nil, 1)
	local fire = Instance.new("Fire")
	fire.Heat = 12
	fire.Size = flameSize(hits)
	fire.Color = Color3.fromRGB(255, 120, 30)
	fire.SecondaryColor = Color3.fromRGB(255, 220, 80)
	fire.Parent = part
	local smoke = Instance.new("Smoke")
	smoke.Color = Color3.fromRGB(60, 60, 64)
	smoke.Opacity = 0.35
	smoke.RiseVelocity = 6
	smoke.Size = 6
	smoke.Parent = part
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 140, 50)
	light.Range = 18
	light.Brightness = 2
	light.Parent = part
	local flame: Flame = { Part = part, Hits = hits, Fire = fire, Smoke = smoke }
	table.insert(inc.Flames, flame)
	return flame
end

local function refreshFlame(flame: Flame)
	flame.Fire.Size = flameSize(flame.Hits)
	flame.Fire.Heat = 6 + flame.Hits * 4
end

---------------------------------------------------------------------
-- Avisos
---------------------------------------------------------------------

local newIncident -- se define más abajo

local function flamesLeft(inc: Incident): number
	local n = 0
	for _, flame in inc.Flames do
		if flame.Hits > 0 then
			n += 1
		end
	end
	return n
end

local function publish(shift: Shift)
	local player = shift.Player
	local inc = shift.Incident
	if not inc then
		Remote:FireClient(player, "Incident", nil)
		player:SetAttribute("TaskTarget", nil)
		player:SetAttribute("TaskText", "Espera el próximo aviso en el parque")
		return
	end
	local kind = KINDS[inc.Kind]
	local step = if inc.Kind == "Gato" then "Sube y rescata al gato de la farola." else ("Apaga las llamas: quedan %d."):format(flamesLeft(inc))
	local left = math.max(0, math.floor(F.TimeLimit - (os.clock() - inc.Started)))
	Remote:FireClient(player, "Incident", {
		Icon = kind.Icon,
		Title = kind.Title,
		Text = if inc.Address then kind.Text .. " (" .. inc.Address .. ")" else kind.Text,
		Step = step,
		Left = left,
	})
	player:SetAttribute("TaskTarget", inc.Position)
	player:SetAttribute("TaskText", ("%s %s · %s"):format(kind.Icon, kind.Title, step))
end

local function ownPrompt(shift: Shift, parent: Instance, action: string, object: string, hold: number, callback: () -> ()): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = hold
	p.MaxActivationDistance = 14
	p.RequiresLineOfSight = false
	p:SetAttribute("JobOnly", "Bombero")
	p:SetAttribute("OwnerUserId", shift.Player.UserId)
	p.Parent = parent
	p.Triggered:Connect(function(player)
		if player == shift.Player and shifts[player] == shift then
			callback()
		end
	end)
	return p
end

local function solve(shift: Shift)
	local inc = shift.Incident
	if not inc or inc.Done then
		return
	end
	inc.Done = true
	local player = shift.Player
	shift.Incident = nil
	for _, d in inc.Folder:GetDescendants() do
		if d:IsA("ProximityPrompt") then
			d:Destroy()
		end
	end
	local folder = inc.Folder
	task.delay(20, function()
		folder:Destroy()
	end)
	local pay = math.floor(((F.Pay[inc.Kind] or 20) + inc.Distance * F.PerStud) * MonetizationService.payMultiplier(player))
	DataService.addMoney(player, pay, true)
	local data = DataService.get(player)
	if data then
		data.Stats.TasksDone += 1
	end
	NeedsService.change(player, 0, -F.EnergyCost)
	Notify:FireClient(player, "Money", ("+%s · %s resuelto"):format(Format.money(pay), KINDS[inc.Kind].Title))
	StoryEvents.emit(player, "JobTaskDone", { JobId = "Bombero", Pay = pay })
	publish(shift)
	if not NeedsService.canWork(player) then
		FireService.quit(player, true)
		Notify:FireClient(player, "Error", "Estás agotado. Come algo o duerme antes de seguir trabajando.")
		return
	end
	task.delay(6, function()
		if shifts[player] == shift and not shift.Incident then
			newIncident(shift)
		end
	end)
end

-- Echar agua a una llama: se hace más pequeña; al llegar a 0 se apaga (queda un poco de vapor)
local function douse(shift: Shift, inc: Incident, flame: Flame)
	if flame.Hits <= 0 or inc.Done then
		return
	end
	flame.Hits -= 1
	local steam = Instance.new("Smoke")
	steam.Color = Color3.fromRGB(235, 240, 245)
	steam.Opacity = 0.5
	steam.RiseVelocity = 8
	steam.Size = 5
	steam.Parent = flame.Part
	task.delay(2, function()
		steam.Enabled = false
	end)
	if flame.Hits <= 0 then
		flame.Fire.Enabled = false
		flame.Smoke.Color = Color3.fromRGB(150, 150, 154)
		flame.Smoke.Opacity = 0.15
		local light = flame.Part:FindFirstChildOfClass("PointLight")
		if light then
			light.Enabled = false
		end
		local prompt = flame.Part:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt:Destroy()
		end
		if flame.Glow then
			flame.Glow.Color = Color3.fromRGB(40, 36, 34) -- chamuscado
			flame.Glow.Material = Enum.Material.Slate
		end
	else
		refreshFlame(flame)
	end
	if flamesLeft(inc) == 0 then
		Notify:FireClient(shift.Player, "Success", "🔥 ¡Fuego apagado!")
		solve(shift)
	else
		publish(shift)
	end
end

local function flameWithPrompt(shift: Shift, inc: Incident, position: Vector3, hits: number): Flame
	local flame = addFlame(inc, position, hits)
	ownPrompt(shift, flame.Part, "Apagar fuego", "🧯 Llama", 1.2, function()
		douse(shift, inc, flame)
	end)
	return flame
end

-- Punto de acera al azar entre las calles publicadas (para coches, papeleras y farolas se usan
-- las piezas del mapa; esto es para el coche en llamas)
local function roadSpot(origin: Vector3): (Vector3?, Vector3)
	local ambient = ReplicatedStorage:FindFirstChild("Ambient")
	local roads = ambient and ambient:FindFirstChild("Roads")
	if not roads then
		return nil, Vector3.new(0, 0, 1)
	end
	local list = roads:GetChildren()
	for _ = 1, 40 do
		local config = list[math.random(1, #list)]
		local a, b = config:GetAttribute("A"), config:GetAttribute("B")
		if typeof(a) == "Vector3" and typeof(b) == "Vector3" and config:GetAttribute("Kind") ~= "Autovia" and (b - a).Magnitude > 60 then
			local dir = (b - a).Unit
			local perp = Vector3.new(-dir.Z, 0, dir.X)
			local width = config:GetAttribute("Width") or 24
			local p = a + dir * (20 + math.random() * ((b - a).Magnitude - 40)) + perp * (width / 4)
			local spot = Vector3.new(p.X, 0.4, p.Z)
			local d = Vector3.new(spot.X - origin.X, 0, spot.Z - origin.Z).Magnitude
			if d >= F.MinDistance and d <= F.MaxDistance then
				return spot, dir
			end
		end
	end
	return nil, Vector3.new(0, 0, 1)
end

local function taggedNear(tag: string, origin: Vector3): BasePart?
	local candidates = {}
	for _, part in CollectionService:GetTagged(tag) do
		if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
			local d = Vector3.new(part.Position.X - origin.X, 0, part.Position.Z - origin.Z).Magnitude
			if d >= F.MinDistance and d <= F.MaxDistance then
				table.insert(candidates, part)
			end
		end
	end
	return if #candidates > 0 then candidates[math.random(1, #candidates)] else nil
end

local BUILD = {}

function BUILD.Casa(shift: Shift, inc: Incident, origin: Vector3): boolean
	local mailbox = taggedNear("Buzon", origin)
	local house = mailbox and mailbox:FindFirstAncestorOfClass("Model")
	local body = house and house:FindFirstChild("Body") :: BasePart?
	if not mailbox or not body then
		return false
	end
	inc.Address = mailbox:GetAttribute("Address")
	local cf, size = body.CFrame, body.Size
	inc.Position = (mailbox:GetAttribute("DoorSpot") or mailbox.Position) :: Vector3
	-- Llamas en las ventanas de delante, en un lateral y en el tejado; ventanas iluminadas de naranja
	local spots = {
		cf * CFrame.new(size.X / 4, -size.Y / 2 + 4.5, -size.Z / 2 - 0.6),
		cf * CFrame.new(-size.X / 2 - 0.6, 0, 0),
		cf * CFrame.new(0, size.Y / 2 + 1.5, 0),
	}
	if size.Y > 14 then
		table.insert(spots, cf * CFrame.new(-size.X / 4, size.Y / 2 - 4, -size.Z / 2 - 0.6))
	end
	for i, spot in spots do
		local flame = flameWithPrompt(shift, inc, spot.Position, F.FlameHits + (if i == 3 then 1 else 0))
		if i ~= 3 then
			flame.Glow = anchoredPart(inc.Folder, "BurningWindow", Vector3.new(3.4, 3.4, 0.2), spot * CFrame.new(0, 0, 0.45), Color3.fromRGB(255, 120, 30), Enum.Material.Neon)
		end
	end
	-- El vecino, fuera en el jardín, mirando a su casa
	local out = Vector3.new(inc.Position.X - cf.Position.X, 0, inc.Position.Z - cf.Position.Z)
	local feet = inc.Position + (if out.Magnitude > 0.1 then out.Unit * 6 else Vector3.new(0, 0, -6))
	local neighbour = Npc.create("Vecino", inc.Folder, CFrame.lookAt(feet, Vector3.new(cf.Position.X, feet.Y, cf.Position.Z)), nil)
	Npc.say(neighbour, "¡Fuego! ¡Ayuda! ¡Mi casa está ardiendo!")
	return true
end

function BUILD.Coche(shift: Shift, inc: Incident, origin: Vector3): boolean
	local position, along = roadSpot(origin)
	if not position then
		return false
	end
	inc.Position = position
	local car = CarModel.build(inc.Folder, CFrame.lookAt(position, position + along), Color3.fromRGB(50, 46, 44), { Name = "BurningCar", Lite = true })
	for _, d in car:GetDescendants() do
		if d:IsA("BasePart") and (d.Name == "Body" or d.Name == "Roof") then
			d.Material = Enum.Material.Slate
		end
	end
	flameWithPrompt(shift, inc, position + Vector3.new(0, 3.2, 0) - along * 4, F.FlameHits + 1)
	flameWithPrompt(shift, inc, position + Vector3.new(0, 4.5, 0), F.FlameHits)
	return true
end

function BUILD.Papelera(shift: Shift, inc: Incident, origin: Vector3): boolean
	local bin = taggedNear("Papelera", origin)
	if not bin then
		return false
	end
	inc.Position = bin.Position
	flameWithPrompt(shift, inc, bin.Position + Vector3.new(0, 1.6, 0), F.FlameHits)
	return true
end

function BUILD.Gato(shift: Shift, inc: Incident, origin: Vector3): boolean
	local lens = taggedNear("StreetLamp", origin)
	if not lens then
		return false
	end
	local lamp = lens:FindFirstAncestorOfClass("Model")
	local base = lamp and lamp:FindFirstChild("Base") :: BasePart?
	local ground = if base then Vector3.new(base.Position.X, base.Position.Y - base.Size.Y / 2, base.Position.Z) else lens.Position - Vector3.new(0, 13.9, 0)
	inc.Position = ground
	-- El gato: cuerpo, cabeza con orejas y cola, encima de la farola
	local top = lens.Position + Vector3.new(0, 0.6, 0)
	local fur = ({ Color3.fromRGB(230, 140, 50), Color3.fromRGB(40, 40, 44), Color3.fromRGB(240, 240, 240) })[math.random(1, 3)]
	local cat = anchoredPart(inc.Folder, "Cat", Vector3.new(0.7, 0.7, 1.4), CFrame.new(top), fur)
	anchoredPart(inc.Folder, "CatHead", Vector3.new(0.7, 0.6, 0.6), CFrame.new(top + Vector3.new(0, 0.4, -0.8)), fur)
	for _, x in { -0.2, 0.2 } do
		anchoredPart(inc.Folder, "CatEar", Vector3.new(0.18, 0.3, 0.1), CFrame.new(top + Vector3.new(x, 0.85, -0.8)), fur)
	end
	anchoredPart(inc.Folder, "CatTail", Vector3.new(0.15, 0.15, 1), CFrame.new(top + Vector3.new(0, 0.5, 0.9)) * CFrame.Angles(math.rad(40), 0, 0), fur)
	local owner = Npc.create("Dueña", inc.Folder, CFrame.lookAt(ground + Vector3.new(3, 0, 3), ground), nil)
	Npc.say(owner, "¡Misi no sabe bajar! ¡Por favor, ayúdenla!")
	local rescue = anchoredPart(inc.Folder, "RescuePoint", Vector3.new(3, 5, 3), CFrame.new(ground + Vector3.new(0, 2.5, 0)), Color3.new(1, 1, 1), nil, 1)
	ownPrompt(shift, rescue, "Rescatar al gato", "🐱 Gato en la farola", 2.5, function()
		for _, d in inc.Folder:GetChildren() do
			if d:IsA("BasePart") and string.sub(d.Name, 1, 3) == "Cat" then
				d.CFrame = d.CFrame - Vector3.new(0, top.Y - ground.Y - 0.5, 0) + Vector3.new(2, 0, 2)
			end
		end
		cat.Name = "CatSafe"
		Npc.say(owner, "¡Misi! ¡Gracias, gracias!")
		solve(shift)
	end)
	return true
end

function newIncident(shift: Shift)
	if shift.Incident then
		shift.Incident.Folder:Destroy()
		shift.Incident = nil
	end
	local origin = shift.Station.Base.Position
	for _ = 1, 4 do
		local kind = KIND_LIST[math.random(1, #KIND_LIST)]
		local folder = Instance.new("Folder")
		folder.Name = "Fire_" .. kind
		folder.Parent = world
		local inc: Incident = { Kind = kind, Position = origin, Folder = folder, Flames = {}, Started = os.clock(), LastGrow = os.clock(), Distance = 0, Done = false }
		shift.Incident = inc
		local ok, built = pcall(BUILD[kind], shift, inc, origin)
		if ok and built then
			inc.Distance = Vector3.new(inc.Position.X - origin.X, 0, inc.Position.Z - origin.Z).Magnitude
			Notify:FireClient(shift.Player, "Info", ("🚨 Aviso: %s %s"):format(KINDS[kind].Icon, KINDS[kind].Title))
			publish(shift)
			return
		end
		if not ok then
			warn("[FireService] " .. tostring(built))
		end
		folder:Destroy()
		shift.Incident = nil
	end
	publish(shift)
end

---------------------------------------------------------------------
-- Sirena del camión
---------------------------------------------------------------------

local function toggleSiren(player: Player)
	if not shifts[player] then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	local truck = seat and seat:FindFirstAncestorOfClass("Model")
	if truck and truck:HasTag("SirenCar") then
		truck:SetAttribute("Siren", not truck:GetAttribute("Siren"))
	end
end

---------------------------------------------------------------------
-- Turno
---------------------------------------------------------------------

function FireService.start(player: Player)
	if not DataService.get(player) or not LifeService.allows(player, "Work") then
		return
	end
	if not Stages.inRange(player:GetAttribute("LifeStage") or "", F.MinStage, nil) then
		Notify:FireClient(player, "Error", "Para ser bombero hay que ser mayor de edad.")
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
	RoleService.setOnDuty(player, "Bombero")
	player:SetAttribute("Job", "Bombero")
	dress(shift)
	Remote:FireClient(player, "Start")
	Notify:FireClient(player, "Success", "¡De guardia! El camión está en la plaza amarilla (sirena: tecla K).")
	newIncident(shift)
end

function FireService.quit(player: Player, silent: boolean?)
	local shift = shifts[player]
	if not shift then
		return
	end
	shifts[player] = nil
	if shift.Incident then
		shift.Incident.Folder:Destroy()
	end
	if shift.Uniform then
		shift.Uniform:Destroy()
	end
	RoleService.offDuty(player, "Bombero")
	if player:GetAttribute("Job") == "Bombero" then
		player:SetAttribute("Job", nil)
	end
	player:SetAttribute("TaskTarget", nil)
	player:SetAttribute("TaskText", nil)
	Remote:FireClient(player, "Stop")
	if not silent then
		Notify:FireClient(player, "Info", "Has terminado la guardia.")
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
	local truck
	for _, d in model:GetDescendants() do
		if d:HasTag("FireTruckSpot") then
			truck = d
		end
	end
	if not truck then
		return
	end
	table.insert(stations, { Model = model, Base = truck, Truck = truck })
	local p = Instance.new("ProximityPrompt")
	p.ActionText = "Camión de bomberos"
	p.ObjectText = "🚒 Bomberos (carnet B)"
	p.HoldDuration = 0.4
	p.MaxActivationDistance = 10
	p.RequiresLineOfSight = false
	p:SetAttribute("JobOnly", "Bombero")
	p.Parent = truck
	p.Triggered:Connect(function(player)
		if shifts[player] and not VehicleService.mount(player, "Bomberos", { Rented = true }) then
			Notify:FireClient(player, "Info", "Para el camión hace falta el carnet B.")
		end
	end)
end

function FireService.init()
	world = Instance.new("Folder")
	world.Name = "FireIncidents"
	world.Parent = workspace
	for _, model in CollectionService:GetTagged("FireStation") do
		setupStation(model)
	end
	CollectionService:GetInstanceAddedSignal("FireStation"):Connect(setupStation)
	JobService.setHandler("Bombero", { Start = FireService.start, Quit = FireService.quit })
	Remote.OnServerEvent:Connect(function(player, action)
		if action == "Siren" then
			toggleSiren(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		FireService.quit(player, true)
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
	-- El fuego crece si se tarda; avisos caducados; panel al día
	task.spawn(function()
		while true do
			task.wait(2)
			for player, shift in shifts do
				local inc = shift.Incident
				if inc and not inc.Done then
					if os.clock() - inc.Started > F.TimeLimit then
						Notify:FireClient(player, "Info", "🚨 Otra dotación se ha hecho cargo. Hay un aviso nuevo.")
						newIncident(shift)
						continue
					end
					if #inc.Flames > 0 and os.clock() - inc.LastGrow > F.GrowEvery then
						inc.LastGrow = os.clock()
						local burning = {}
						for _, flame in inc.Flames do
							if flame.Hits > 0 and flame.Hits < F.MaxHits then
								table.insert(burning, flame)
							end
						end
						if #burning > 0 then
							local flame = burning[math.random(1, #burning)]
							flame.Hits += 1
							refreshFlame(flame)
							Notify:FireClient(player, "Error", "🔥 ¡El fuego está creciendo! Date prisa.")
						end
					end
				end
				publish(shift)
			end
		end
	end)
end

return FireService
