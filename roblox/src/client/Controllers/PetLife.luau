-- PetLife (cliente): los perros, gatos y animales de granja que tienen su sitio (no salen al azar
-- alrededor de cada jugador, como antes). Se pintan en cada dispositivo y solo cerca: sin coste de red.
--
--   * Tu mascota y las de los demás (workspace.Mascotas, PetService): te sigue un poco por detrás y a
--     un lado (shared/Pets.stepFollow: anda, corre para alcanzarte y, si te vas lejos, aparece a tu
--     lado). Bajo techo (tienda, portal) te espera sentada en la puerta; en el metro o en una sala de
--     un edificio no entra (te espera y reaparece contigo al salir); si vas en coche, moto o a
--     caballo, tampoco corre detrás: aparece a tu lado al bajarte. «Sentarse»: se queda donde
--     estaba. «A casa»: en el jardín de tu parcela o contigo dentro de tu vivienda. Su nombre encima.
--     Cartel para su dueño: «Sentarse / Seguir» y «Mis mascotas».
--   * Vagabundos (Pets.Strays, 3): en su sitio (protectora, callejón, parque). «Llamar» → te sigue;
--     al rato, «Adoptar» (PetService). Si alguien lo adopta, ese sitio se queda vacío un tiempo.
--   * Gatos de casa (Pets.HouseCats): uno en la puerta de algunas casas; como mucho 2 a la vista.
--   * Protectora: en cada chenil, su perro o su gato (etiqueta PetShelterKennel), dentro de su jaula.
--   * Campos de Valmar (shared/FarmAnimals): vacas, toro, ovejas y cabras en rebaño, cerdos y caballos
--     dentro de sus cercados (pastan, hozan, miran, se tumban), solo si estás cerca.
--   * Caballo montado (workspace.Rides, Kind = "Caballo"): las patas al paso, al trote o al galope
--     según la velocidad (FarmAnimals.legSwing) y un letrero con el aire en el que vas.
--   Todos se asustan si pasas pegado (salto y voz) sin salir de su sitio. Cómo se mueven: AnimalPose.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Pets = require(ReplicatedStorage.Shared.Pets)
local FarmAnimals = require(ReplicatedStorage.Shared.FarmAnimals)
local Ground = require(ReplicatedStorage.Shared.Ground)
local AnimalPose = require(script.Parent.AnimalPose)
local Nudge = require(script.Parent.Nudge)
local Hud = require(script.Parent.Parent.UI.Hud)

local PetLife = {}

local player = Players.LocalPlayer
local folder: Folder
local remote: RemoteEvent? = nil

type Critter = {
	Role: string, -- "pet" | "stray" | "cat" | "kennel" | "farm"
	Kind: string,
	Pieces: { AnimalPose.Piece },
	Info: AnimalPose.Info,
	Pose: AnimalPose.State,
	Frames: { CFrame },
	Root: CFrame,
	Stand: number,
	State: string,
	Timer: number,
	Phase: number,
	Speed: number,
	Target: Vector3?,
	Home: Vector3?,
	Radius: number,
	Pen: FarmAnimals.Pen?,
	Follow: Pets.Follower?,
	ReactAt: number?,
	Visible: boolean,
	Prompts: { ProximityPrompt },
	Label: BillboardGui?,
	Key: string,
}

local critters: { [string]: Critter } = {}
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function rgb3(t: { number }?): Color3?
	return if t then Color3.fromRGB(t[1], t[2], t[3]) else nil
end

-- Aspecto de una raza (shared/Pets) para AnimalPose
local function lookOf(kind: string, breed: string?, coat: number?, collar: boolean?): AnimalPose.Look
	local l = breed and Pets.look(kind, breed, coat)
	if not l then
		return { Collar = if collar then Color3.fromRGB(200, 40, 40) else nil }
	end
	return { Coat = rgb3(l.Coat), Accent = rgb3(l.Accent), Scale = l.Scale, Spots = l.Spots, Fluffy = l.Fluffy, Collar = if collar then Color3.fromRGB(200, 40, 40) else nil }
end

local function ground(x: number, z: number, fromY: number, depth: number?): RaycastResult?
	local exclude: { Instance } = { folder, workspace.CurrentCamera }
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(exclude, p.Character)
		end
	end
	rayParams.FilterDescendantsInstances = exclude
	return Ground.cast(Vector3.new(x, fromY, z), Vector3.new(0, -(depth or 30), 0), rayParams)
end

-- ¿Hay techo encima de esta posición? (tienda, portal, casa): la mascota no entra, espera fuera
local upParams = RaycastParams.new()
upParams.FilterType = Enum.RaycastFilterType.Exclude
local function roofed(at: Vector3, character: Model?): boolean
	upParams.FilterDescendantsInstances = { folder, workspace.CurrentCamera, character :: any }
	local origin = at + Vector3.new(0, 2.5, 0)
	for _ = 1, 3 do
		local hit = workspace:Raycast(origin, Vector3.new(0, 60, 0), upParams)
		if not hit then
			return false
		end
		if Ground.isGround(hit) and hit.Instance.CanCollide and hit.Instance.Transparency < 0.9 then
			return true
		end
		origin = hit.Position + Vector3.new(0, 0.05, 0)
	end
	return false
end

local function newCritter(key: string, role: string, kind: string, look: AnimalPose.Look?): Critter
	local pieces, info = AnimalPose.build(kind, look)
	for _, p in pieces do
		p.Part.Parent = folder
	end
	local c: Critter = {
		Role = role, Kind = kind, Pieces = pieces, Info = info, Pose = AnimalPose.newState(kind), Frames = {},
		Root = CFrame.new(0, -500, 0), Stand = info.Stand, State = "idle", Timer = 1 + math.random() * 3,
		Phase = math.random() * 10, Speed = AnimalPose.WalkSpeed[kind] or 2, Radius = 4, Visible = true, Prompts = {}, Key = key,
	}
	c.Pose.Action = AnimalPose.chooseAction(kind)
	critters[key] = c
	return c
end

local function destroy(c: Critter)
	for _, p in c.Pieces do
		p.Part:Destroy()
	end
	if c.Label then
		c.Label:Destroy()
	end
	critters[c.Key] = nil
end

local function setVisible(c: Critter, visible: boolean)
	if c.Visible == visible then
		return
	end
	c.Visible = visible
	if not visible then
		for _, p in c.Pieces do
			p.Part.CFrame = CFrame.new(0, -500, 0)
		end
		for _, prompt in c.Prompts do
			prompt.Enabled = false
		end
	else
		for _, prompt in c.Prompts do
			prompt.Enabled = true
		end
	end
end

local function render(c: Critter, t: number, dt: number, around: Vector3?)
	if not c.Visible then
		return
	end
	local pose = c.Pose
	pose.State = c.State
	pose.Phase = c.Phase
	local lookYaw: number? = nil
	local near = false
	if around then
		local rel = c.Root:PointToObjectSpace(around)
		local distance = Vector2.new(rel.X, rel.Z).Magnitude
		if distance < 12 then
			local yaw = math.atan2(-rel.X, -rel.Z)
			if math.abs(yaw) < 2 then
				lookYaw = yaw
			end
		end
		near = distance < 8
	end
	AnimalPose.step(pose, dt, c.Speed, lookYaw, near)
	AnimalPose.pose(c.Pieces, c.Info, pose, t, c.Frames)
	local parts, frames = table.create(#c.Pieces), table.create(#c.Pieces)
	for i, p in c.Pieces do
		parts[i] = p.Part
		frames[i] = c.Root * c.Frames[i]
	end
	workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
end

local function placeAt(c: Critter, x: number, z: number, fromY: number, yaw: number?): boolean
	local hit = ground(x, z, fromY, 40)
	if not hit or not Pets.looseSpotOk(hit.Position.Y) then
		return false
	end
	local pos = hit.Position + Vector3.new(0, c.Stand, 0)
	c.Root = CFrame.new(pos) * CFrame.Angles(0, math.rad(yaw or math.random() * 360), 0)
	c.Home = c.Home or hit.Position
	return true
end

-- Andar hacia c.Target (si lo tiene); devuelve true al llegar
local function walkTo(c: Critter, dt: number): boolean
	local target = c.Target
	if not target then
		return true
	end
	local pos = c.Root.Position
	local flat = Vector3.new(target.X - pos.X, 0, target.Z - pos.Z)
	if flat.Magnitude < 0.3 then
		return true
	end
	local stepLen = math.min(flat.Magnitude, c.Speed * dt)
	local newPos = pos + flat.Unit * stepLen
	newPos = Vector3.new(newPos.X, pos.Y + (target.Y - pos.Y) * math.min(1, dt * 4), newPos.Z)
	c.Root = CFrame.lookAt(newPos, newPos + flat.Unit)
	return false
end

local function say(c: Critter, text: string?)
	if text and c.Pieces[1] then
		Nudge.say(c.Pieces[1].Part, text, 1.4)
	end
end

local VOICES = { Perro = "¡Guau!", Gato = "¡Miau!", Vaca = "¡Muuu!", Toro = "¡MUUU!", Oveja = "¡Beee!", Cabra = "¡Meee!", Cerdo = "¡Oink!", Caballo = "¡Hiiii!" }

-- Susto si pasas pegado: salta y "dice" algo (sin moverse de su sitio)
local function maybeStartle(c: Critter, t: number, around: Vector3?)
	if not around or t < (c.ReactAt or 0) then
		return
	end
	local pos = c.Root.Position
	if Vector2.new(pos.X - around.X, pos.Z - around.Z).Magnitude < 3.2 and math.abs(pos.Y - around.Y) < 5 then
		c.ReactAt = t + 3
		AnimalPose.startle(c.Pose)
		say(c, VOICES[c.Kind])
	end
end

-- Quieto un rato o paseando cerca de su sitio (vagabundos, gatos, cheniles, granja)
local function wander(c: Critter, t: number, dt: number, around: Vector3?, pick: () -> (number?, number?))
	maybeStartle(c, t, around)
	c.Timer -= dt
	if c.State == "idle" then
		if c.Timer <= 0 then
			local x, z = pick()
			if x and z then
				local hit = ground(x, z, c.Root.Position.Y + 6, 14)
				if hit and math.abs(hit.Position.Y - (c.Root.Position.Y - c.Stand)) < 2.5 then
					c.Target = hit.Position + Vector3.new(0, c.Stand, 0)
					c.State = "walk"
					c.Timer = 10
					return
				end
			end
			c.Timer = 2 + math.random() * 3
		end
	elseif c.State == "walk" then
		if walkTo(c, dt) or c.Timer <= 0 then
			c.State = "idle"
			c.Target = nil
			local action = AnimalPose.chooseAction(c.Kind)
			c.Pose.Action = action
			c.Timer = if action == "lie" or action == "sit" or action == "graze" or action == "root" then 6 + math.random() * 10 else 2 + math.random() * 5
		end
	end
end

local function nameLabel(c: Critter, text: string)
	if c.Label then
		(c.Label:FindFirstChildOfClass("TextLabel") :: TextLabel).Text = text
		return
	end
	local head = c.Pieces[2] and c.Pieces[2].Part or c.Pieces[1].Part
	local gui = Instance.new("BillboardGui")
	gui.Name = "NombreMascota"
	gui.Size = UDim2.fromOffset(140, 26)
	gui.StudsOffset = Vector3.new(0, 1.6 * c.Info.Scale, 0)
	gui.MaxDistance = 45
	gui.AlwaysOnTop = false
	gui.Adornee = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 244, 220)
	label.TextStrokeTransparency = 0.4
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = gui
	gui.Parent = folder
	c.Label = gui
end

local function addPrompt(c: Critter, action: string, object: string, key: Enum.KeyCode?, onTrigger: () -> ()): ProximityPrompt
	local part = c.Pieces[1].Part
	part.CanQuery = true -- (los carteles necesitan poder "ver" la pieza)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	if key then
		prompt.KeyboardKeyCode = key
		prompt.UIOffset = Vector2.new(0, 58)
	end
	prompt.Triggered:Connect(onTrigger)
	prompt.Parent = part
	table.insert(c.Prompts, prompt)
	return prompt
end

local function fire(...)
	if remote then
		(remote :: RemoteEvent):FireServer(...)
	end
end

local function myRoot(): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

---------------------------------------------------------------------
-- Mascotas de los jugadores
---------------------------------------------------------------------
local petInfo: { [string]: { Place: string, Check: number, Waiting: boolean, CallAt: number?, Hidden: boolean } } = {}

local function petKey(config: Instance): string
	return "pet:" .. config.Name
end

local function ensurePet(config: Configuration): Critter?
	local key = petKey(config)
	local kind, breed, coat = config:GetAttribute("Kind"), config:GetAttribute("Breed"), config:GetAttribute("Coat")
	if type(kind) ~= "string" or not Pets.Kinds[kind] then
		return nil
	end
	local c = critters[key]
	local sig = ("%s/%s/%s/%s"):format(tostring(config:GetAttribute("PetId")), kind, tostring(breed), tostring(coat))
	if c and (c :: any).Sig ~= sig then
		destroy(c)
		c = nil
	end
	if not c then
		c = newCritter(key, "pet", kind, lookOf(kind, breed, coat, true))
		local cc = c :: Critter
		;(cc :: any).Sig = sig
		cc.Follow = { Pos = Vector3.new(0, -500, 0), Speed = 0, Moving = false, Facing = Vector3.new(0, 0, -1) }
		cc.Visible = false
		petInfo[key] = { Place = "outside", Check = 0, Waiting = false, Hidden = true }
		if config:GetAttribute("Owner") == player.UserId then
			addPrompt(cc, "Sentarse / Seguir", "🐾 " .. tostring(config:GetAttribute("PetName") or "Tu mascota"), nil, function()
				local mode = config:GetAttribute("Mode")
				fire(if mode == "Sit" then "Follow" else "Sit", config:GetAttribute("PetId"))
			end)
			addPrompt(cc, "Mis mascotas", "🐾", Enum.KeyCode.R, function()
				fire("Panel", "Mascotas")
			end)
			for _, prompt in cc.Prompts do
				prompt.Enabled = false
			end
		end
	end
	nameLabel(c :: Critter, tostring(config:GetAttribute("PetName") or ""))
	return c
end

local function stepPet(config: Configuration, t: number, dt: number, around: Vector3?)
	local c = ensurePet(config)
	if not c then
		return
	end
	local key = petKey(config)
	local info = petInfo[key]
	local owner = Players:GetPlayerByUserId(config:GetAttribute("Owner") or 0)
	local character = owner and owner.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local f = c.Follow :: Pets.Follower
	if not root then
		setVisible(c, false)
		return
	end
	local ownerPos = root.Position
	-- Lejos de ti: no hace falta ni moverla
	if around and (ownerPos - around).Magnitude > 260 and (f.Pos - around).Magnitude > 260 then
		setVisible(c, false)
		info.Hidden = true
		return
	end
	local mode = config:GetAttribute("Mode")
	-- Dónde está su dueño (cada medio segundo: rayos)
	if t >= info.Check then
		info.Check = t + 0.5
		local feet = ownerPos - Vector3.new(0, 2.5, 0)
		info.Place = Pets.ownerPlace(ownerPos.Y, ownerPos.Y < 3000 and ownerPos.Y > -12 and roofed(feet, character))
	end
	local place = info.Place
	local action: string? = nil
	local target: Vector3? = nil
	local visible = true
	if mode == "Home" then
		local homeAt = config:GetAttribute("HomeAt")
		if typeof(homeAt) == "Vector3" then
			-- En el jardín de su casa: se queda por allí
			target = homeAt
			action = "lie"
		elseif config:GetAttribute("OwnerHome") and ownerPos.Y > 3000 then
			-- Contigo dentro de tu vivienda
			target = Pets.heel(ownerPos, root.CFrame.LookVector)
		else
			visible = false
		end
	elseif mode == "Sit" then
		local at = config:GetAttribute("SitAt")
		target = if typeof(at) == "Vector3" then at else f.Pos
		action = "sit"
		if (target - ownerPos).Magnitude > 220 then
			visible = false
		end
	else
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local seat = humanoid and humanoid.SeatPart
		if seat and (seat:IsA("VehicleSeat") or seat.Name == "RideSeat") then
			place = "hidden" -- vas en coche, en moto o a caballo: te espera y aparece contigo al bajar
		end
		if place == "hidden" then
			visible = false -- en el metro o en una sala: no entra
			info.Hidden = true
		elseif place == "indoors" then
			-- Bajo techo: te espera en la puerta, sentada
			info.Waiting = true
			action = "sit"
			if info.Hidden then
				visible = false
			end
		else
			info.Waiting = false
			target = Pets.heel(ownerPos, root.CFrame.LookVector)
			if info.Hidden then
				-- Vuelve a aparecer a tu lado (al salir del metro, de una sala, al llegar)
				f.Pos = target + Vector3.new(0, 50, 0)
				info.Hidden = false
			end
		end
	end
	-- «Llamar»: si está lejos, viene corriendo (o aparece a tu lado) y ladra
	local callAt = config:GetAttribute("CallAt")
	if type(callAt) == "number" and callAt ~= info.CallAt then
		info.CallAt = callAt
		if place == "outside" then
			local heel = Pets.heel(ownerPos, root.CFrame.LookVector)
			if (f.Pos - heel).Magnitude > 40 then
				f.Pos = heel + Vector3.new(0, 50, 0)
			end
			say(c, Pets.Kinds[c.Kind].Voice)
		end
	end
	setVisible(c, visible)
	if not visible then
		return
	end
	if target then
		-- El suelo donde tiene que estar
		local hit = ground(target.X, target.Z, target.Y + 4, 30)
		local goal = if hit then hit.Position + Vector3.new(0, c.Stand, 0) else Vector3.new(target.X, f.Pos.Y, target.Z)
		if f.Pos.Y < -400 then
			f.Pos = goal
		end
		if f.Pos.Y > goal.Y + 20 then
			f.Pos = goal -- (aparece en el suelo, no cae del cielo)
		end
		local result = Pets.stepFollow(f, goal, dt)
		c.Speed = math.max(f.Speed, 1)
		if result == "walk" then
			c.State = "walk"
		else
			c.State = "idle"
			if action then
				c.Pose.Action = action
			elseif t > c.Timer then
				c.Timer = t + 4 + math.random() * 6
				c.Pose.Action = if (around and (around - f.Pos).Magnitude < 6) then "sit" else AnimalPose.chooseAction(c.Kind)
			end
		end
		local facing = f.Facing
		if c.State == "idle" and (ownerPos - f.Pos).Magnitude > 1 then
			local toOwner = Vector3.new(ownerPos.X - f.Pos.X, 0, ownerPos.Z - f.Pos.Z)
			if toOwner.Magnitude > 0.1 then
				facing = c.Root.LookVector:Lerp(toOwner.Unit, math.min(1, dt * 3))
			end
		end
		facing = Vector3.new(facing.X, 0, facing.Z)
		if facing.Magnitude < 0.05 then
			facing = Vector3.new(0, 0, -1)
		end
		c.Root = CFrame.lookAt(f.Pos, f.Pos + facing.Unit)
	else
		c.State = "idle"
		c.Pose.Action = action or "sit"
	end
	render(c, t, dt, around)
end

---------------------------------------------------------------------
-- Vagabundos
---------------------------------------------------------------------
local strayFollow: { [string]: number } = {} -- id → cuándo empezó a seguirte (os.clock)
local function strayTaken(id: string): boolean
	local box = workspace:FindFirstChild("Mascotas")
	local untilAt = box and box:GetAttribute("StrayTaken_" .. id)
	return type(untilAt) == "number" and workspace:GetServerTimeNow() < untilAt
end

local function stepStray(s: { [string]: any }, t: number, dt: number, around: Vector3?)
	local key = "stray:" .. s.Id
	local c = critters[key]
	local d = if around then Vector2.new(around.X - s.At[1], around.Z - s.At[2]).Magnitude else math.huge
	local following = strayFollow[s.Id] ~= nil
	if strayTaken(s.Id) or (d > 140 and not following) then
		if c then
			destroy(c)
		end
		strayFollow[s.Id] = nil
		return
	end
	if not c then
		local cc = newCritter(key, "stray", s.Kind, lookOf(s.Kind, s.Breed, s.Coat, false))
		if not placeAt(cc, s.At[1], s.At[2], 8) then
			destroy(cc)
			return
		end
		cc.Radius = s.Radius or 5
		local call = addPrompt(cc, "Llamar", Pets.Kinds[s.Kind].Icon .. " Sin dueño", nil, function()
			fire("StrayCall", s.Id)
		end)
		local adopt = addPrompt(cc, "Adoptar", Pets.Kinds[s.Kind].Icon .. " Te sigue", Enum.KeyCode.R, function()
			fire("StrayAdopt", s.Id)
		end)
		adopt.Enabled = false
		;(cc :: any).Call = call
		;(cc :: any).Adopt = adopt
		c = cc
	end
	local cc = c :: Critter
	local since = strayFollow[s.Id]
	local root = myRoot()
	if since and root then
		-- Te sigue (como una mascota) y, al rato, se deja adoptar
		local f = cc.Follow
		if not f then
			f = { Pos = cc.Root.Position, Speed = 0, Moving = false, Facing = cc.Root.LookVector }
			cc.Follow = f
		end
		local ff = f :: Pets.Follower
		local target = Pets.heel(root.Position, root.CFrame.LookVector)
		local hit = ground(target.X, target.Z, root.Position.Y + 2, 30)
		local goal = if hit then hit.Position + Vector3.new(0, cc.Stand, 0) else ff.Pos
		local result = Pets.stepFollow(ff, goal, dt)
		cc.Speed = math.max(ff.Speed, 1)
		cc.State = if result == "walk" then "walk" else "idle"
		cc.Pose.Action = "sit"
		local face = Vector3.new(ff.Facing.X, 0, ff.Facing.Z)
		cc.Root = CFrame.lookAt(ff.Pos, ff.Pos + (if face.Magnitude > 0.05 then face.Unit else Vector3.new(0, 0, -1)))
		local ready = os.clock() - since >= Pets.STRAY_FOLLOW_TIME
		;((cc :: any).Adopt :: ProximityPrompt).Enabled = ready
		;((cc :: any).Call :: ProximityPrompt).Enabled = false
		-- Si te alejas mucho (coche, metro…), se cansa y vuelve a su sitio
		if os.clock() - since > Pets.STRAY_CALL_WINDOW or root.Position.Y < -12 or root.Position.Y > 3000 or (ff.Pos - root.Position).Magnitude > 60 or Vector2.new(root.Position.X - s.At[1], root.Position.Z - s.At[2]).Magnitude > 150 then
			strayFollow[s.Id] = nil
			destroy(cc)
			return
		end
	else
		local home = cc.Home :: Vector3
		wander(cc, t, dt, around, function()
			local a = math.random() * math.pi * 2
			local r = math.random() * cc.Radius
			return home.X + math.cos(a) * r, home.Z + math.sin(a) * r
		end)
	end
	render(cc, t, dt, around)
end

---------------------------------------------------------------------
-- Gatos de casa, cheniles y granja
---------------------------------------------------------------------
local function stepHouseCats(t: number, dt: number, around: Vector3?)
	-- Los 2 más cercanos (a menos de HOUSE_CAT_RADIUS)
	local near = {}
	if around then
		for i, spot in Pets.HouseCats do
			local d = Vector2.new(around.X - spot[1], around.Z - spot[2]).Magnitude
			if d < Pets.HOUSE_CAT_RADIUS then
				table.insert(near, { i, d })
			end
		end
		table.sort(near, function(a, b)
			return a[2] < b[2]
		end)
	end
	local keep = {}
	for k = 1, math.min(#near, Pets.HOUSE_CATS_VISIBLE) do
		keep["cat:" .. near[k][1]] = near[k][1]
	end
	for key, c in critters do
		if c.Role == "cat" and not keep[key] then
			destroy(c)
		end
	end
	for key, index in keep do
		local c = critters[key]
		if not c then
			local spot = Pets.HouseCats[index]
			local breed, coat = Pets.houseCatLook(index)
			local cc = newCritter(key, "cat", "Gato", lookOf("Gato", breed, coat, true))
			if not placeAt(cc, spot[1], spot[2], 8, spot[3]) then
				destroy(cc)
				continue
			end
			cc.Radius = 1.5
			cc.Pose.Action = "sit"
			c = cc
		end
		local cc = c :: Critter
		local home = cc.Home :: Vector3
		wander(cc, t, dt, around, function()
			local a = math.random() * math.pi * 2
			return home.X + math.cos(a) * cc.Radius, home.Z + math.sin(a) * cc.Radius
		end)
		render(cc, t, dt, around)
	end
end

local function stepKennels(t: number, dt: number, around: Vector3?)
	for _, spotPart in CollectionService:GetTagged("PetShelterKennel") do
		if not spotPart:IsA("BasePart") then
			continue
		end
		local key = "kennel:" .. spotPart:GetFullName()
		local pos = spotPart.Position
		local far = not around or (around - pos).Magnitude > 110
		local c = critters[key]
		if far then
			if c then
				destroy(c)
			end
			continue
		end
		if not c then
			local kind = spotPart:GetAttribute("Kind")
			if type(kind) ~= "string" or not Pets.Kinds[kind] then
				continue
			end
			local cc = newCritter(key, "kennel", kind, lookOf(kind, spotPart:GetAttribute("Breed"), spotPart:GetAttribute("Coat"), false))
			local _, yaw = spotPart.CFrame:ToOrientation()
			cc.Root = CFrame.new(pos + Vector3.new(0, cc.Stand, 0)) * CFrame.Angles(0, yaw, 0)
			cc.Home = pos
			cc.Radius = 1.6
			c = cc
		end
		local cc = c :: Critter
		local home = cc.Home :: Vector3
		wander(cc, t, dt, around, function()
			local a = math.random() * math.pi * 2
			return home.X + math.cos(a) * cc.Radius, home.Z + math.sin(a) * cc.Radius
		end)
		render(cc, t, dt, around)
	end
end

local function rand(): number
	return math.random()
end

local function stepFarm(t: number, dt: number, around: Vector3?)
	for _, pen in FarmAnimals.Pens do
		local cx, cz = FarmAnimals.center(pen)
		local near = around ~= nil and Vector2.new(around.X - cx, around.Z - cz).Magnitude < FarmAnimals.SHOW_RADIUS and around.Y > -12 and around.Y < 3000
		for _, kind in pen.Order do
			for i = 1, math.min(pen.Animals[kind] or 0, FarmAnimals.MAX_PER_PEN) do
				local key = ("farm:%s:%s:%d"):format(pen.Id, kind, i)
				local c = critters[key]
				if not near then
					if c then
						destroy(c)
					end
					continue
				end
				if not c then
					local cc = newCritter(key, "farm", kind, nil)
					local x, z = FarmAnimals.pick(pen, rand)
					if not placeAt(cc, x, z, FarmAnimals.GROUND_Y + 8) then
						destroy(cc)
						continue
					end
					cc.Pen = pen
					c = cc
				end
				local cc = c :: Critter
				wander(cc, t, dt, around, function()
					if kind == "Oveja" or kind == "Cabra" then
						-- En rebaño: cerca de los demás
						local points = {}
						for _, other in critters do
							if other.Pen == pen and (other.Kind == "Oveja" or other.Kind == "Cabra") then
								table.insert(points, { other.Root.X, other.Root.Z })
							end
						end
						local fx, fz = FarmAnimals.flockCenter(points)
						return FarmAnimals.pick(pen, rand, { fx, fz, FarmAnimals.FLOCK_RADIUS })
					end
					return FarmAnimals.pick(pen, rand, { cc.Root.X, cc.Root.Z, if kind == "Caballo" then 22 else 12 })
				end)
				-- Nunca fuera del cercado
				local p = cc.Root.Position
				if not FarmAnimals.inside(pen, p.X, p.Z, FarmAnimals.MARGIN - 0.5) then
					local x, z = FarmAnimals.clamp(pen, p.X, p.Z)
					cc.Root = CFrame.new(x, p.Y, z) * cc.Root.Rotation
					cc.Target = nil
					cc.State = "idle"
				end
				render(cc, t, dt, around)
			end
		end
	end
end

---------------------------------------------------------------------
-- Caballo montado: patas al paso, al trote o al galope
---------------------------------------------------------------------
local horseLegs: { [Model]: { Welds: { Weld }, Phase: number, Gait: string?, Label: TextLabel? } } = setmetatable({}, { __mode = "k" }) :: any

local function stepHorses(dt: number, around: Vector3?)
	local rides = workspace:FindFirstChild("Rides")
	if not rides or not around then
		return
	end
	for _, model in rides:GetChildren() do
		if not model:IsA("Model") or model:GetAttribute("Kind") ~= "Caballo" then
			continue
		end
		local chassis = model.PrimaryPart
		if not chassis or (chassis.Position - around).Magnitude > 220 then
			continue
		end
		local entry = horseLegs[model]
		if not entry then
			local welds = {}
			for _, d in model:GetDescendants() do
				if d:IsA("Weld") and d.Name == "LegWeld" then
					table.insert(welds, d)
				end
			end
			entry = { Welds = welds, Phase = 0 }
			horseLegs[model] = entry
		end
		local v = chassis.AssemblyLinearVelocity
		local speed = Vector3.new(v.X, 0, v.Z).Magnitude
		local gait = FarmAnimals.gait(speed)
		entry.Phase = (entry.Phase + dt * gait.Rate * math.pi * 2) % (math.pi * 2)
		for _, weld in entry.Welds do
			local base = weld:GetAttribute("HipC0")
			local leg = weld:GetAttribute("Leg")
			if typeof(base) == "CFrame" and type(leg) == "number" then
				weld.C0 = base * CFrame.Angles(FarmAnimals.legSwing(leg, entry.Phase, speed), 0, 0)
			end
		end
		-- El aire en el que vas (solo el tuyo)
		local seat = model:FindFirstChild("DriverSeat") :: VehicleSeat?
		local mine = seat and seat.Occupant and seat.Occupant.Parent == player.Character
		if mine and gait.Name ~= entry.Gait then
			entry.Gait = gait.Name
			if gait.Name ~= "Parado" then
				Nudge.say(chassis, "🐴 " .. gait.Name, 1.2)
			end
		end
	end
end

---------------------------------------------------------------------

local function update(t: number, dt: number)
	local root = myRoot()
	local around = root and root.Position
	-- Mascotas de todos (también la tuya)
	local box = workspace:FindFirstChild("Mascotas")
	local seen = {}
	if box then
		for _, config in box:GetChildren() do
			if config:IsA("Configuration") then
				seen[petKey(config)] = true
				local ok, err = pcall(stepPet, config, t, dt, around)
				if not ok then
					warn("[PetLife] " .. tostring(err))
				end
			end
		end
	end
	for key, c in critters do
		if c.Role == "pet" and not seen[key] then
			destroy(c)
			petInfo[key] = nil
		end
	end
	local outside = around ~= nil and around.Y > -12 and around.Y < 3000
	for _, s in Pets.Strays do
		if outside or strayFollow[s.Id] then
			stepStray(s, t, dt, around)
		elseif critters["stray:" .. s.Id] then
			destroy(critters["stray:" .. s.Id])
		end
	end
	stepHouseCats(t, dt, if outside then around else nil)
	stepKennels(t, dt, if outside then around else nil)
	stepFarm(t, dt, around)
	stepHorses(dt, around)
end

-- Cuántos hay ahora de cada tipo (para pruebas y el panel de depuración)
function PetLife.counts(): { [string]: number }
	local out = {}
	for _, c in critters do
		out[c.Role] = (out[c.Role] or 0) + 1
	end
	return out
end

function PetLife.init()
	folder = Instance.new("Folder")
	folder.Name = "PetLife"
	folder.Parent = workspace.CurrentCamera -- solo existe para este jugador
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes", 60)
		local r = remotes and remotes:WaitForChild("Pets", 60)
		if r and r:IsA("RemoteEvent") then
			remote = r
			r.OnClientEvent:Connect(function(action, id)
				if action == "StrayFollow" and type(id) == "string" then
					strayFollow[id] = os.clock()
				end
			end)
		end
	end)
	-- App del teléfono: «Mascotas» (tus mascotas: sacar, sentarse, llamar, a casa)
	Hud.addButton("🐾 Mascotas", Color3.fromRGB(60, 150, 120), 6.5, function()
		fire("Panel", "Mascotas")
	end)
	local since, t = 0, 0
	RunService.Heartbeat:Connect(function(dt)
		t += dt
		since += dt
		if since < 1 / 30 then
			return
		end
		local ok, err = pcall(update, t, since)
		since = 0
		if not ok then
			warn("[PetLife] " .. tostring(err))
		end
	end)
end

return PetLife
