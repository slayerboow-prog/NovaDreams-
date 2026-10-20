-- NacaraService: la plaza de prueba de Nácara (fase 0, docs/mar/civilizacion-marina.md).
--
--   * Cuando el mar hondo está hecho (workspace.OceanReady), World/NacaraBuilder construye la plaza UNA
--     vez (terreno allanado, cúpula de aire, torres, puestos, carteles).
--   * La gente: 8 Hondarios (shared/Sea/Nacara.People) hechos con el personaje de siempre (World/Npc)
--     con cola de piezas (cuatro tramos con Motor6D y la aleta), cresta, aletas en los antebrazos, peto
--     de nácar y la «firma de luz». Siempre vestidos. El cliente (Controllers/NacaraLife) los mece y
--     mueve la cola (barato: solo los cercanos). Etiqueta HondarioNpc; atributo Home = dónde flota.
--   * Ilun (farolero) y Oriana (perlera, desde el agua detrás de su puesto de la Lonja Honda) tienen una
--     charla corta (DialogueService, con StageDirector). La demás gente suelta una frase al pasar.
--   * En el mapa: 🐚 «Nácara (prueba)» (ReplicatedStorage.MapLandmarks, tipo PuntoNacara).
--   * ES UNA PRUEBA: no paga, no vende, no guarda nada (ni DataStore ni datos del jugador nuevos). El aire
--     dentro de la cúpula lo rellena DivingService (la burbuja lleva la etiqueta SeaAirPocket).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Nacara = require(ReplicatedStorage.Shared.Sea.Nacara)
local NacaraBuilder = require(script.Parent.Parent.World.NacaraBuilder)
local Npc = require(script.Parent.Parent.World.Npc)

local NacaraService = {}

NacaraService.People = {} :: { [string]: Model }
NacaraService.Stats = { People = 0, PeopleParts = 0 }
NacaraService.WaitOcean = 900 -- segundos como mucho esperando al mar (si no llega, se construye igual)
NacaraService.BarkRange = 26
NacaraService.BarkEvery = 28

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new

local function service(name: string): any
	local ok, result = pcall(function()
		return require(script.Parent[name])
	end)
	return if ok then result else nil
end

---------------------------------------------------------------------
-- Los Hondarios
---------------------------------------------------------------------
local LEGS = { "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot", "LeftLeg", "RightLeg" }

local function piece(model: Model, to: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?, class: string?): BasePart
	local p = Instance.new(class or "Part") :: BasePart
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.CFrame = to.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = to
	weld.Part1 = p
	weld.Parent = p
	p.Parent = model
	return p
end

-- La cola: tramos con Motor6D (el cliente les da la onda con Transform) y la aleta de dos lóbulos
local function tail(model: Model, hip: BasePart, look: { [string]: any }): number
	local scales: Color3 = look.Scales
	local light = scales:Lerp(Color3.new(1, 1, 1), 0.35)
	local sizes = { V(1.85, 1.5, 1.05), V(1.5, 1.45, 0.9), V(1.1, 1.35, 0.72), V(0.66, 1.05, 0.5) }
	local prev = hip
	local count = 0
	for i, size in sizes do
		local seg = Instance.new("Part")
		seg.Name = "Cola" .. i
		seg.Size = size
		seg.Color = scales:Lerp(light, (i - 1) / 5)
		seg.Material = Enum.Material.SmoothPlastic
		seg.Reflectance = 0.08
		seg.CanCollide = false
		seg.CanQuery = false
		seg.CanTouch = false
		seg.Massless = true
		seg.CastShadow = false
		local motor = Instance.new("Motor6D")
		motor.Name = "ColaJunta" .. i
		motor.Part0 = prev
		motor.Part1 = seg
		motor.C0 = CF(0, -prev.Size.Y / 2 + (if i == 1 then 0.1 else 0.05), 0)
		motor.C1 = CF(0, size.Y / 2, 0)
		seg.CFrame = prev.CFrame * motor.C0 * motor.C1:Inverse()
		motor.Parent = seg
		seg.Parent = model
		count += 1
		prev = seg
	end
	-- la aleta: dos lóbulos que se abren hacia los lados en abanico (láminas finas de delante a atrás:
	-- de frente y de espaldas se ve la aleta entera; v1 eran dos cuñas hacia abajo y parecían piernas)
	for s = -1, 1, 2 do
		piece(model, prev, "Aleta", V(1.5, 0.75, 0.12), CF(s * 0.62, -0.55, 0.05) * CFrame.Angles(math.rad(-10), 0, math.rad(s * 28)), light, Enum.Material.SmoothPlastic)
		count += 1
	end
	-- la firma de luz de la familia: una línea en la cola
	local first = model:FindFirstChild("Cola1") :: BasePart?
	if first then
		piece(model, first, "FirmaCola", V(0.12, 1.3, 0.1), CF(0, 0, -first.Size.Z / 2 - 0.03), look.Crest, Enum.Material.Neon)
		count += 1
	end
	return count
end

-- Viste a un Hondario y le pone cola, cresta y aletas. Devuelve cuántas piezas lleva en total.
function NacaraService.dressHondario(model: Model, person: { [string]: any }): number
	local look = person.Look
	for _, name in LEGS do
		local leg = model:FindFirstChild(name)
		if leg and leg:IsA("BasePart") then
			leg.Transparency = 1
		end
	end
	local hip = (model:FindFirstChild("LowerTorso") or model:FindFirstChild("Torso")) :: BasePart?
	local torso = (model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")) :: BasePart?
	local head = model:FindFirstChild("Head") :: BasePart?
	if hip then
		hip.Color = look.Scales
		tail(model, hip, look)
	end
	if torso then
		local t = torso.Size
		-- peto de nácar y fajín de red
		piece(model, torso, "PetoNacar", V(t.X * 0.82, t.Y * 0.5, 0.18), CF(0, t.Y * 0.12, -t.Z / 2 - 0.08), rgb(232, 226, 240), Enum.Material.SmoothPlastic).Reflectance = 0.2
		piece(model, torso, "Fajin", V(t.X * 1.04, 0.32, t.Z * 1.06), CF(0, -t.Y / 2 + 0.16, 0), look.Crest:Lerp(Color3.new(0, 0, 0), 0.45), Enum.Material.Fabric)
	end
	for _, side in { "Left", "Right" } do
		local upper = model:FindFirstChild(side .. "UpperArm") :: BasePart?
		local lower = model:FindFirstChild(side .. "LowerArm") :: BasePart?
		local sx = if side == "Left" then -1 else 1
		if upper then
			-- hombrera de concha (la Guardia, más grande) y la firma de luz en el brazo
			local big = person.Role == "Guard"
			local pad = piece(model, upper, "Hombrera", if big then V(1.35, 0.6, 1.35) else V(1.1, 0.42, 1.1), CF(0, upper.Size.Y / 2 - 0.05, 0), rgb(220, 214, 232), Enum.Material.SmoothPlastic)
			local mesh = Instance.new("SpecialMesh") -- (concha chafada: bloque con malla de esfera)
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = pad
			piece(model, upper, "FirmaBrazo", V(0.08, upper.Size.Y * 0.8, 0.08), CF(sx * (upper.Size.X / 2 + 0.02), 0, 0), look.Crest, Enum.Material.Neon)
		end
		if lower then
			-- aleta del antebrazo (hace de manga)
			piece(model, lower, "AletaBrazo", V(0.12, lower.Size.Y * 0.9, 0.8), CF(sx * (lower.Size.X / 2 + 0.05), 0, 0.25) * CFrame.Angles(math.rad(-12), 0, 0), look.Scales:Lerp(Color3.new(1, 1, 1), 0.25), Enum.Material.SmoothPlastic)
		end
	end
	if head then
		local s = head.Size
		-- la cresta de aleta (abanico) y las branquias del cuello (rayitas finas)
		piece(model, head, "Cresta", V(0.14, s.Y * 0.75, s.Z * 1.05), CF(0, s.Y * 0.55, 0.12) * CFrame.Angles(math.rad(-10), 0, 0), look.Crest, Enum.Material.SmoothPlastic, "WedgePart")
		for k = -1, 1, 2 do
			piece(model, head, "Branquias", V(0.06, 0.28, 0.4), CF(k * (s.X / 2 - 0.08), -s.Y * 0.42, 0.05), look.Scales:Lerp(Color3.new(0, 0, 0), 0.3), Enum.Material.SmoothPlastic)
		end
	end
	if person.Role == "Guard" then
		local hand = (model:FindFirstChild("RightHand") or model:FindFirstChild("RightLowerArm")) :: BasePart?
		if hand then
			-- bastón-arpón SIN punta (de golpe, no de corte): una perla en lo alto
			local staff = piece(model, hand, "Baston", V(0.3, 7, 0.3), CF(0, 1.6, -0.2), rgb(200, 190, 220), Enum.Material.SmoothPlastic)
			piece(model, staff, "PerlaBaston", V(0.7, 0.7, 0.7), CF(0, 3.6, 0), rgb(150, 230, 255), Enum.Material.Neon).Shape = Enum.PartType.Ball
		end
	end
	local n = 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			n += 1
		end
	end
	return n
end

local function home(model: Model, cf: CFrame)
	model:SetAttribute("Home", cf)
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		root.CFrame = cf
	end
end

-- Un Hondario en su sitio (flotando Y studs sobre el suelo de la plaza)
function NacaraService.spawnPerson(person: { [string]: any }, parent: Instance): Model?
	local x, z, y = Nacara.personSpot(person)
	local at = Nacara.toWorld(x, z, y)
	local face: Vector3
	if person.Face then
		face = Nacara.toWorld(person.Face[1], person.Face[2], y)
	elseif person.Stall then
		face = Nacara.domeCenter() + V(0, y, 0)
	else
		face = Nacara.centerPosition() + V(0, y, 0)
	end
	local dir = (face - at) * V(1, 0, 1)
	local yaw = if dir.Magnitude > 0.1 then math.atan2(-dir.X, -dir.Z) else 0
	local look = person.Look
	local model = Npc.create("Hondario_" .. person.Id, parent, CF(at) * CFrame.Angles(0, yaw, 0), {
		Skin = look.Skin,
		Shirt = look.Tunic,
		Pants = look.Scales,
		Shoes = look.Scales,
		Hair = look.Hair,
		LongSleeves = false,
		LongHair = person.Role ~= "Guard",
		Id = "Nacara:" .. person.Id, -- (su cara con textura: shared/LifeStory/CastLook)
	})
	local count = NacaraService.dressHondario(model, person)
	if not NacaraBuilder.take(count) then
		warn(("[Nacara] sin presupuesto de piezas para %s (%d)"):format(person.Id, count))
		model:Destroy()
		return nil
	end
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		home(model, root.CFrame)
	end
	model:SetAttribute("NpcId", person.Id)
	model:SetAttribute("HondarioRole", person.Role)
	model:SetAttribute("BobSeed", (#person.Id * 7.3) % 6.28)
	CollectionService:AddTag(model, "HondarioNpc")
	NacaraService.People[person.Id] = model
	NacaraService.Stats.People += 1
	NacaraService.Stats.PeopleParts += count
	return model
end

---------------------------------------------------------------------
-- Charlas
---------------------------------------------------------------------
local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Mira hacia el jugador (y lo apunta en Home: el cliente lo mece desde ahí)
local function faceTo(model: Model, point: Vector3)
	local cf = model:GetAttribute("Home")
	if typeof(cf) ~= "CFrame" then
		return
	end
	local pos = (cf :: CFrame).Position
	local flat = V(point.X - pos.X, 0, point.Z - pos.Z)
	if flat.Magnitude > 0.5 then
		home(model, CF(pos) * CFrame.Angles(0, math.atan2(-flat.X, -flat.Z), 0))
	end
end

function NacaraService.talk(player: Player, id: string): boolean
	local lines = Nacara.Dialogues[id]
	local model = NacaraService.People[id]
	if not lines or not model then
		return false
	end
	if player:GetAttribute("InDialogue") then
		return false
	end
	local DialogueService = service("DialogueService")
	if not DialogueService then
		return false
	end
	local root = rootOf(player)
	if root then
		faceTo(model, root.Position)
	end
	local context = {
		actorOf = function(speaker: string): Instance?
			return NacaraService.People[speaker]
		end,
		-- (prueba: nada de efectos ni marcas de historia)
		apply = function() end,
		check = function()
			return true
		end,
	}
	return DialogueService.play(player, { Lines = lines }, context) == true
end

local function prompt(model: Model, person: { [string]: any })
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local p = Instance.new("ProximityPrompt")
	p.Name = "NacaraPrompt"
	p.ActionText = "Hablar"
	p.ObjectText = ("%s · %s"):format(person.Name, person.Title or "")
	p.HoldDuration = 0.2
	p.MaxActivationDistance = 13
	p.RequiresLineOfSight = false
	p.Parent = root
	p.Triggered:Connect(function(player: Player)
		-- (si tu historia del mar te pide hablar con esta persona, la conversación es la de la misión:
		-- Services/SeaCivService; si no, la charla de la plaza)
		local civ = service("SeaCivService")
		if civ and civ.storyTalk(player, person.Id) then
			civ.talk(player, person.Id)
			return
		end
		NacaraService.talk(player, person.Id)
	end)
end

---------------------------------------------------------------------
-- Frases al pasar (bocadillo)
---------------------------------------------------------------------
local lastBark: { [Player]: number } = {}
local function barkTick()
	local DialogueService = service("DialogueService")
	if not DialogueService then
		return
	end
	local now = os.clock()
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root and not player:GetAttribute("InDialogue") and now - (lastBark[player] or -1e9) > NacaraService.BarkEvery then
			for _, person in Nacara.People do
				local model = NacaraService.People[person.Id]
				local list = Nacara.Barks[person.Role]
				if model and list and model.PrimaryPart and (model.PrimaryPart.Position - root.Position).Magnitude < NacaraService.BarkRange then
					lastBark[player] = now
					local text = list[math.random(1, #list)]
					pcall(DialogueService.bark, player, person.Name, text, nil, model)
					break
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- El mapa
---------------------------------------------------------------------
function NacaraService.publishLandmark(): boolean
	local folder = ReplicatedStorage:FindFirstChild("MapLandmarks")
	if not folder then
		return false
	end
	if folder:FindFirstChild("PuntoNacara_Plaza") then
		return true
	end
	local config = Instance.new("Configuration")
	config.Name = "PuntoNacara_Plaza"
	config:SetAttribute("Kind", "PuntoNacara")
	config:SetAttribute("Position", V(Nacara.Center.X, 0, Nacara.Center.Z))
	config:SetAttribute("District", "")
	config.Parent = folder
	return true
end

---------------------------------------------------------------------

-- Construye la plaza y pone a la gente (lo hace init cuando el mar está listo; las pruebas lo llaman)
function NacaraService.setup(terrain: any?)
	NacaraBuilder.build(terrain)
	local folder = NacaraBuilder.folder()
	local people = Instance.new("Folder")
	people.Name = "Hondarios"
	people.Parent = folder
	for _, person in Nacara.People do
		local ok, model = pcall(NacaraService.spawnPerson, person, people)
		if not ok then
			warn("[Nacara] " .. tostring(model))
		elseif model and (person.Role == "Quest" or person.Role == "Shop") then
			prompt(model, person)
		end
	end
	print(("[Nacara] %d Hondarios (%d piezas). Plaza y gente: %d piezas de %d"):format(NacaraService.Stats.People, NacaraService.Stats.PeopleParts, NacaraBuilder.Stats.Parts, Nacara.Budget))
end

function NacaraService.init()
	task.spawn(function()
		-- el punto del mapa (WorldService crea la carpeta al arrancar)
		for _ = 1, 120 do
			if NacaraService.publishLandmark() then
				break
			end
			task.wait(1)
		end
	end)
	task.spawn(function()
		local waited = 0
		while not workspace:GetAttribute("OceanReady") and waited < NacaraService.WaitOcean do
			task.wait(1)
			waited += 1
		end
		local ok, err = pcall(NacaraService.setup)
		if not ok then
			warn("[Nacara] " .. tostring(err))
		end
		while true do
			task.wait(4)
			pcall(barkTick)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastBark[player] = nil
	end)
end

return NacaraService
