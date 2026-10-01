-- KnockService (servidor): lo que sale despedido al darle con un vehículo o al chocar andando.
--
--   * Objetos de la calle (shared/Knock.Catalog: papeleras, conos, vallas de obra, sillas, mesas y
--     sombrillas de terraza, pizarras, cajas de fruta, macetas, sombrillas de playa, motos de adorno,
--     bancos del parque, señales…). Al arrancar se buscan UNA vez en la ciudad (poco a poco, sin
--     parar el servidor) y cada uno queda marcado con el atributo Knock = número y el grupo de choque
--     Knock.Group (los rayos del coche los atraviesan: el coche no frena en seco contra una papelera).
--     Siguen anclados y quietos (no gastan nada) hasta que alguien les da.
--   * Remoto "Knock" (cliente → servidor): "Prop" (objeto), "Person" (persona) o "Shove" (empujón
--     andando). El servidor comprueba que quien avisa está de verdad al lado y no va más rápido de lo
--     que puede (Knock.plausible, con su vehículo o su cuerpo según el servidor), limita la frecuencia
--     y calcula él el golpe (Knock.launch / Knock.person), con topes.
--   * Un objeto golpeado se suelta (física del servidor, igual para todos) y sale despedido; a los
--     25 s quieto (o 45 s como mucho, o si se cae del mapa) se desvanece y vuelve anclado a su sitio,
--     nunca con alguien encima de su sitio. Como mucho Knock.Budget a la vez (el más antiguo vuelve).
--   * Balones y conos de juguete (ToyService): el coche también los patea, más fuerte.
--   * Personas: a otro jugador le quita vida con las reglas de siempre (CombatService.applyHit: K.O.,
--     protección, delitos de WantedService) y su ordenador le tira al suelo ("Knocked"). A los NPC del
--     servidor (anclados) se les anima la caída y se levantan; a los agentes, además, les quita vida.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Knock = require(ReplicatedStorage.Shared.Knock)
local Crash = require(ReplicatedStorage.Shared.Crash)
local Toys = require(ReplicatedStorage.Shared.Toys)
local VehicleService = require(script.Parent.VehicleService)
local CrashService = require(script.Parent.CrashService)

local KnockService = {}

type Saved = { Anchored: boolean, CanCollide: boolean, Transparency: number }
type Unit = {
	Id: number,
	Root: Instance,
	Primary: BasePart,
	Parts: { BasePart },
	Homes: { CFrame },
	Saved: { Saved },
	Profile: Knock.Profile,
	Reach: number,
	Welds: { Instance }?,
	Fading: boolean?,
}

local units: { [number]: Unit } = {}
local claimed: { [Instance]: boolean } = {}
local loose: { [Unit]: Knock.Loose } = {}
local lastHit: { [string]: number } = {}
local bursts: { [Player]: { number } } = {}
local nextId = 0
local Remote: RemoteEvent? = nil

KnockService._units = units -- (pruebas)
KnockService._loose = loose

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

---------------------------------------------------------------------
-- Registro de los objetos
---------------------------------------------------------------------
local function ancestorsOf(instance: Instance): { string }
	local list = {}
	local node = instance.Parent
	for _ = 1, 5 do
		if not node or node == workspace then
			break
		end
		table.insert(list, node.Name)
		node = node.Parent
	end
	return list
end

local function setGroup(part: BasePart)
	pcall(function()
		part.CollisionGroup = Knock.Group
	end)
end

-- Da de alta un objeto (una pieza con sus compañeras, o un Model entero)
function KnockService.register(seed: Instance): Unit?
	if claimed[seed] then
		return nil
	end
	local size: Vector3? = nil
	if seed:IsA("BasePart") then
		size = seed.Size
	elseif seed:IsA("Model") then
		local ok, _, s = pcall(function()
			return seed:GetBoundingBox()
		end)
		size = if ok then s else nil
	else
		return nil
	end
	local profile = Knock.profile(seed.Name, if seed:IsA("Model") then "Model" else "BasePart", ancestorsOf(seed), size)
	if not profile then
		return nil
	end
	local parts: { BasePart } = {}
	if seed:IsA("Model") then
		for _, d in seed:GetDescendants() do
			if d:IsA("BasePart") then
				table.insert(parts, d)
			end
		end
	else
		local part = seed :: BasePart
		table.insert(parts, part)
		if profile.Companions and part.Parent then
			local reach = profile.Reach or 1.5
			for _, other in part.Parent:GetChildren() do
				if other ~= part and other:IsA("BasePart") and not claimed[other] and table.find(profile.Companions, other.Name) then
					if flat(other.Position - part.Position).Magnitude <= reach then
						table.insert(parts, other)
					end
				end
			end
		end
	end
	if #parts == 0 then
		return nil
	end
	for _, part in parts do
		if not part.Anchored then
			return nil -- (algo que ya tiene física por su cuenta)
		end
	end
	local primary, volume = parts[1], 0
	for _, part in parts do
		local v = part.Size.X * part.Size.Y * part.Size.Z
		if v > volume then
			primary, volume = part, v
		end
	end
	nextId += 1
	local unit: Unit = {
		Id = nextId,
		Root = seed,
		Primary = primary,
		Parts = parts,
		Homes = {},
		Saved = {},
		Profile = profile,
		Reach = if size then math.sqrt(size.X * size.X + size.Z * size.Z) / 2 else 1.5,
	}
	for i, part in parts do
		claimed[part] = true
		unit.Homes[i] = part.CFrame
		unit.Saved[i] = { Anchored = part.Anchored, CanCollide = part.CanCollide, Transparency = part.Transparency }
		part:SetAttribute("Knock", nextId)
		part:SetAttribute("KnockKind", seed.Name) -- (el cliente sabe si es pesado: Knock.Catalog)
		setGroup(part)
	end
	claimed[seed] = true
	units[nextId] = unit
	return unit
end

-- Busca los objetos en la ciudad (una vez; de poco en poco para no parar el servidor)
local function scan(root: Instance)
	local count = 0
	for _, d in root:GetDescendants() do
		count += 1
		if count % 4000 == 0 then
			task.wait()
		end
		if (d:IsA("BasePart") or d:IsA("Model")) and Knock.Catalog[d.Name] and not claimed[d] then
			pcall(KnockService.register, d)
		end
	end
end

---------------------------------------------------------------------
-- Soltar y volver a su sitio
---------------------------------------------------------------------
local function seatBusy(unit: Unit): boolean
	for _, part in unit.Parts do
		if (part:IsA("Seat") or part:IsA("VehicleSeat")) and part.Occupant then
			return true
		end
	end
	return false
end

local function respawn(unit: Unit, instant: boolean?)
	if unit.Fading then
		return
	end
	unit.Fading = true
	local function place()
		for i, part in unit.Parts do
			if part.Parent then
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
				part.Anchored = true
				part.CFrame = unit.Homes[i]
				part.CanCollide = unit.Saved[i].CanCollide
				part.Transparency = unit.Saved[i].Transparency
			end
		end
		for _, weld in unit.Welds or {} do
			weld:Destroy()
		end
		unit.Welds = nil
		loose[unit] = nil
		unit.Fading = nil
	end
	if instant then
		place()
		return
	end
	for _, part in unit.Parts do
		if part.Parent then
			pcall(function()
				TweenService:Create(part, TweenInfo.new(Knock.FadeSeconds), { Transparency = 1 }):Play()
			end)
		end
	end
	task.delay(Knock.FadeSeconds + 0.05, place)
end
KnockService.respawn = respawn

-- Suelta el objeto y le da la velocidad (y el giro) del golpe
function KnockService.knock(unit: Unit, vel: Vector3, spin: Vector3): boolean
	if unit.Fading or seatBusy(unit) or not unit.Primary.Parent then
		return false
	end
	local now = os.clock()
	local state = loose[unit]
	if not state then
		local ok, oldest = Knock.admit(loose, Knock.Budget)
		if not ok then
			if oldest then
				respawn(oldest, true)
			else
				return false
			end
		end
		if #unit.Parts > 1 and not unit.Welds then
			local welds = {}
			for _, part in unit.Parts do
				if part ~= unit.Primary then
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = unit.Primary
					weld.Part1 = part
					weld.Parent = unit.Primary
					table.insert(welds, weld)
				end
			end
			unit.Welds = welds
		end
		for _, part in unit.Parts do
			part.Anchored = false
			part.CanCollide = true
		end
		pcall(function()
			unit.Primary:SetNetworkOwner(nil) -- lo simula el servidor: igual para todos
		end)
		state = { Since = now }
		loose[unit] = state
	end
	unit.Primary.AssemblyLinearVelocity = vel
	unit.Primary.AssemblyAngularVelocity = spin
	;(state :: Knock.Loose).RestSince = nil
	return true
end

---------------------------------------------------------------------
-- Personas
---------------------------------------------------------------------
local LINES = { "¡Ay!", "¡Eh! ¡Mira por dónde vas!", "¡Pero bueno!", "¡Socorro!", "¡Que me matas!" }
local downNpc: { [Model]: boolean } = {}

-- NPC del servidor (anclados): se les anima la caída (Knock.personPose) y se levantan en su sitio
local function knockNpc(model: Model, hit: Knock.PersonHit)
	if downNpc[model] or model:GetAttribute("Down") then
		return
	end
	local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local ok, Npc = pcall(function()
		return require(script.Parent.Parent.World.Npc)
	end)
	if ok and Npc and hit.Mode ~= "stumble" then
		pcall(Npc.say, model, LINES[math.random(1, #LINES)], 2)
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not root.Anchored then
		-- Con física (poco habitual): se le tumba y se le empuja
		if humanoid and hit.Mode ~= "stumble" then
			humanoid.PlatformStand = true
			task.delay(hit.Down + 0.5, function()
				if humanoid.Parent then
					humanoid.PlatformStand = false
				end
			end)
		end
		root.AssemblyLinearVelocity = hit.Vel
		return
	end
	downNpc[model] = true
	model:SetAttribute("Knocked", true)
	local start = root.CFrame
	local dir = flat(hit.Vel)
	local axis = if dir.Magnitude > 1e-3 then dir.Unit:Cross(Vector3.yAxis) else Vector3.xAxis
	local total = Knock.personTime(hit)
	local t0 = os.clock()
	local conn: RBXScriptConnection? = nil
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		local offset, lie, done = Knock.personPose(t, hit)
		if done or t > total + 0.5 or not root.Parent then
			if conn then
				conn:Disconnect()
			end
			if root.Parent then
				root.CFrame = start -- de pie en su sitio
			end
			downNpc[model] = nil
			model:SetAttribute("Knocked", nil)
			return
		end
		-- Al levantarse vuelve poco a poco a su sitio (los NPC del mapa tienen su sitio fijo)
		local back = if lie < 1 and t > total - Knock.GetUp then 1 - lie else 0
		local pos = start.Position + offset * (1 - back) - Vector3.new(0, lie * 1.9, 0)
		root.CFrame = CFrame.new(pos) * CFrame.fromAxisAngle(axis, -lie * math.pi / 2) * start.Rotation
	end)
end

function KnockService.person(attacker: Player, model: Model, relVel: Vector3, hitterMass: number)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return
	end
	local hit = Knock.person(relVel, hitterMass)
	if hit.Mode == "none" then
		return
	end
	local victim = Players:GetPlayerFromCharacter(model)
	local dir = if flat(relVel).Magnitude > 1e-3 then flat(relVel).Unit else Vector3.new(0, 0, -1)
	local CombatService = require(script.Parent.CombatService) :: any
	-- Atropellar a alguien con un vehículo es delito grave (la víctima, si es un NPC, llama a la policía)
	if hitterMass > Knock.CharacterMass * 2 and not (victim and (victim == attacker or humanoid.SeatPart)) then
		local WantedService = require(script.Parent.WantedService) :: any
		pcall(WantedService.crime, attacker, "Atropello", root.Position, { Witness = if victim then nil else model })
	end
	if victim then
		if victim == attacker or humanoid.SeatPart then
			return
		end
		if hit.Damage > 0 then
			-- Las reglas de siempre: protección, K.O., rematar y delitos (HitSomeone → WantedService)
			local ok, result = pcall(CombatService.applyHit, attacker, model, { Amount = hit.Damage, Direction = dir, Heavy = hit.Mode == "launch", At = root.Position })
			if not ok or not result or not result.Hit then
				return
			end
		end
		if Remote then
			Remote:FireClient(victim, "Knocked", { Vel = hit.Vel, Down = hit.Down, Mode = hit.Mode })
		end
		return
	end
	if model:GetAttribute("Officer") and hit.Damage > 0 then
		pcall(CombatService.applyHit, attacker, model, { Amount = hit.Damage, Direction = dir, Heavy = true, At = root.Position })
	end
	if model.Parent and not model:GetAttribute("Down") then
		knockNpc(model, hit)
	end
end

---------------------------------------------------------------------
-- Avisos de los clientes
---------------------------------------------------------------------
-- Quien golpea según el servidor: su vehículo (si conduce) o su cuerpo
local function hitter(player: Player): (Vector3?, number, number, number, Vector3)
	local model = VehicleService.rideModel(player)
	if model then
		local body = CrashService.bodyOf(model)
		if body and Crash.collides(body.Kind) then
			local reach = math.sqrt(body.Length * body.Length + body.Width * body.Width) / 2
			return body.Pos, reach, CrashService.maxSpeed(body.Kind), body.Mass, body.Vel
		end
		return nil, 0, 0, 0, Vector3.zero
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return nil, 0, 0, 0, Vector3.zero
	end
	return root.Position - Vector3.new(0, 3, 0), 1.5, math.max(humanoid.WalkSpeed, 16) * 1.6 + 8, Knock.CharacterMass, root.AssemblyLinearVelocity
end

local function allowed(player: Player, key: string, now: number): boolean
	bursts[player] = bursts[player] or {}
	if not Crash.burst(bursts[player], now, Knock.Server.Burst, Knock.Server.BurstWindow) then
		return false
	end
	return Crash.rate(lastHit, key, now, Knock.Server.Gap)
end

-- La velocidad del golpe: la que dice (dirección fina) con el tope de lo que puede ir
local function velocityOf(info: any, maxSpeed: number, serverVel: Vector3): Vector3?
	local v = if type(info) == "table" and typeof(info.Vel) == "Vector3" then flat(info.Vel) else flat(serverVel)
	if v.Magnitude ~= v.Magnitude then
		return nil
	end
	local limit = maxSpeed * Knock.Server.SpeedSlack + 6
	if v.Magnitude > limit then
		return nil
	end
	return v
end

local function onProp(player: Player, target: any, info: any)
	local now = os.clock()
	local pos, reach, maxSpeed, mass, serverVel = hitter(player)
	if not pos then
		return
	end
	local vel = velocityOf(info, maxSpeed, serverVel)
	if not vel then
		return
	end
	-- Balón o cono de juguete (ToyService)
	if typeof(target) == "Instance" and target:IsA("BasePart") and CollectionService:HasTag(target, "Toy") then
		local kind = Toys.Kinds[target:GetAttribute("Toy") or ""]
		if not kind or not allowed(player, "toy" .. player.UserId .. tostring(target:GetFullName()), now) then
			return
		end
		local ok = Knock.plausible(pos, reach, target.Position, 1.5, vel.Magnitude, maxSpeed)
		if not ok then
			return
		end
		local launch, spin, mode = Knock.launch({ Mass = 3, Lift = kind.Lift }, vel - flat(target.AssemblyLinearVelocity), mass, flat(target.Position - pos))
		if mode ~= "none" then
			local ToyService = require(script.Parent.ToyService) :: any
			if ToyService.push then
				pcall(ToyService.push, target, launch, spin)
			end
		end
		return
	end
	if type(target) ~= "number" then
		return
	end
	local unit = units[target]
	if not unit or not unit.Primary.Parent then
		return
	end
	if not allowed(player, target .. ":" .. player.UserId, now) then
		return
	end
	local at = unit.Primary.Position
	local ok = Knock.plausible(pos, reach, at, unit.Reach, vel.Magnitude, maxSpeed)
	if not ok then
		return
	end
	local rel = vel - flat(unit.Primary.AssemblyLinearVelocity)
	local launch, spin, mode = Knock.launch(unit.Profile, rel, mass, flat(at - pos))
	if mode == "none" then
		return
	end
	KnockService.knock(unit, launch, spin)
end

-- Tu vehículo entra en un cristal o una puerta (BreakService: escaparates, puertas de los edificios…).
-- Solo en vehículo, al lado de verdad y a una velocidad que puede llevar; BreakService decide si se
-- rompe (según la velocidad) y lleva su propio tope de roturas.
local function onBreak(player: Player, target: any, info: any)
	if typeof(target) ~= "Instance" or not target:IsA("BasePart") or not target:IsDescendantOf(workspace) then
		return
	end
	local now = os.clock()
	local pos, reach, maxSpeed, mass, serverVel = hitter(player)
	if not pos or mass <= Knock.CharacterMass * 2 then
		return -- (andando no: a pie se rompe a golpes, CombatService)
	end
	local vel = velocityOf(info, maxSpeed, serverVel)
	if not vel or not allowed(player, "b" .. player.UserId .. ":" .. target:GetFullName(), now) then
		return
	end
	-- Punto de la pieza más cerca del vehículo
	local half = target.Size / 2
	local l = target.CFrame:PointToObjectSpace(pos)
	local contact = target.CFrame:PointToWorldSpace(Vector3.new(math.clamp(l.X, -half.X, half.X), math.clamp(l.Y, -half.Y, half.Y), math.clamp(l.Z, -half.Z, half.Z)))
	if not Knock.plausible(pos, reach, contact, 1, vel.Magnitude, maxSpeed) then
		return
	end
	local BreakService = require(script.Parent.BreakService) :: any
	BreakService.vehicleHit(player, target, contact, vel, math.min(reach, 4))
end
KnockService._onBreak = onBreak -- (pruebas)

local onPedestrian: (Player, any) -> ()
local function onPerson(player: Player, target: any, info: any, shove: boolean)
	if typeof(target) ~= "Instance" or not target:IsA("Model") or not target:IsDescendantOf(workspace) then
		return
	end
	local now = os.clock()
	local pos, reach, maxSpeed, mass, serverVel = hitter(player)
	if not pos then
		return
	end
	if shove and mass > Knock.CharacterMass then
		return -- (el empujón es andando)
	end
	local vel = velocityOf(info, maxSpeed, serverVel)
	local root = target:FindFirstChild("HumanoidRootPart")
	if not vel or not root or not root:IsA("BasePart") then
		return
	end
	if not allowed(player, "p" .. tostring(target:GetFullName()) .. player.UserId, now) then
		return
	end
	local feet = root.Position - Vector3.new(0, 3, 0)
	if not Knock.plausible(pos, reach, feet, 1.5, vel.Magnitude, maxSpeed) then
		return
	end
	KnockService.person(player, target, vel - flat(root.AssemblyLinearVelocity), mass)
end

-- Un peatón de la calle (solo existe en la pantalla de quien conduce): el servidor no lo ve, así
-- que solo se cree el aviso si vas en un vehículo, a velocidad de atropello y el sitio está a tu lado.
local lastPed: { [Player]: number } = {}
onPedestrian = function(player: Player, info: any)
	local pos, reach, maxSpeed, mass, serverVel = hitter(player)
	if not pos or mass <= Knock.CharacterMass * 2 or type(info) ~= "table" or typeof(info.Pos) ~= "Vector3" then
		return
	end
	local now = os.clock()
	if now - (lastPed[player] or -math.huge) < 4 then
		return
	end
	local vel = velocityOf(info, maxSpeed, serverVel)
	if not vel or vel.Magnitude < Knock.PersonSpeeds.Stumble or not Knock.plausible(pos, reach, info.Pos, 1.5, vel.Magnitude, maxSpeed) then
		return
	end
	lastPed[player] = now
	local WantedService = require(script.Parent.WantedService) :: any
	pcall(WantedService.crime, player, "Atropello", info.Pos)
end

---------------------------------------------------------------------
function KnockService.init()
	-- Grupos de choque: los rayos del coche (Knock.RayGroup) atraviesan los objetos sueltos
	pcall(function()
		if not PhysicsService:IsCollisionGroupRegistered(Knock.Group) then
			PhysicsService:RegisterCollisionGroup(Knock.Group)
		end
		if not PhysicsService:IsCollisionGroupRegistered(Knock.RayGroup) then
			PhysicsService:RegisterCollisionGroup(Knock.RayGroup)
		end
		PhysicsService:CollisionGroupSetCollidable(Knock.RayGroup, Knock.Group, false)
	end)

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local remote = remotes:FindFirstChild("Knock") :: RemoteEvent?
	if not remote then
		local created = Instance.new("RemoteEvent")
		created.Name = "Knock"
		created.Parent = remotes
		remote = created
	end
	Remote = remote
	;(remote :: RemoteEvent).OnServerEvent:Connect(function(player, action, target, info)
		local ok, err = pcall(function()
			if action == "Prop" then
				onProp(player, target, info)
			elseif action == "Person" then
				onPerson(player, target, info, false)
			elseif action == "Shove" then
				onPerson(player, target, info, true)
			elseif action == "Ped" then
				onPedestrian(player, info)
			elseif action == "Break" then
				onBreak(player, target, info)
			end
		end)
		if not ok then
			warn("[KnockService] " .. tostring(err))
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastPed[player] = nil
		bursts[player] = nil
	end)

	task.defer(function()
		local town = workspace:FindFirstChild("Town")
		if town then
			scan(town)
		end
	end)

	-- Cada medio segundo: ¿qué objetos sueltos vuelven ya a su sitio?
	task.spawn(function()
		while true do
			task.wait(0.5)
			local now = os.clock()
			local roots: { Vector3 } = {}
			for _, p in Players:GetPlayers() do
				local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				if r and r:IsA("BasePart") then
					table.insert(roots, r.Position)
				end
			end
			for unit, state in loose do
				local ok = pcall(function()
					if not unit.Primary.Parent then
						loose[unit] = nil
						return
					end
					Knock.rest(state, now, unit.Primary.AssemblyLinearVelocity.Magnitude)
					local home = unit.Homes[table.find(unit.Parts, unit.Primary) or 1].Position
					local busy = false
					for _, r in roots do
						if flat(r - home).Magnitude < Knock.SpotClear + unit.Reach and math.abs(r.Y - home.Y) < 8 then
							busy = true
							break
						end
					end
					if Knock.shouldRespawn(state, now, unit.Primary.Position, home, busy) then
						respawn(unit)
					end
				end)
				if not ok then
					loose[unit] = nil
				end
			end
			for key, at in lastHit do
				if now - at > 10 then
					lastHit[key] = nil
				end
			end
		end
	end)
end

return KnockService
