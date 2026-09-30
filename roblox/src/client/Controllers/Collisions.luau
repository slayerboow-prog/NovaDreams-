-- Collisions (cliente): los choques de TU vehículo (lo usa Driving en cada fotograma).
--
-- Los vehículos del juego no usan la física de Roblox (Driving los coloca con rayos), así que los
-- choques se resuelven a mano con shared/Crash, como en un motor de juego:
--   * Cerca (búsqueda 4 veces por segundo, solo en unas carpetas: nada de consultas pesadas en cada
--     fotograma): coches de otros jugadores (workspace.Rides), aparcados (también los de la ciudad,
--     etiqueta ParkedCar), autobuses (workspace.Buses), patrullas (workspace.PoliceResponse) y el
--     tráfico de tu pantalla (Traffic). Cada fotograma solo se miran esos pocos.
--   * Choque: impulso según las masas y la velocidad en el punto del golpe (rebote pequeño, roce,
--     giro si es descentrado, con topes). Tu coche se lleva su parte al momento y queda fuera del
--     otro (nunca metidos). De frente se para en seco; por detrás empuja; de lado hace girar.
--   * Otro jugador: su ordenador hace lo mismo con su coche y, además, el servidor (CrashService)
--     comprueba el golpe y le manda el empujón ("Impact") por si su pantalla no lo vio. El tráfico
--     frena, pita y protesta (Traffic.hit). Motos y bicis aparcadas salen volando (servidor).
--   * Se nota: ruido según la velocidad (SoundFx.crash), temblor de cámara, chispas y trocitos
--     (CrashFx). En moto, bici o patinete, un golpe fuerte te tira al suelo.
--   * Objetos y personas (shared/Knock, KnockService): lo que tu vehículo (o tú andando) toca de lo
--     que se puede tumbar (atributo Knock, balones y conos de juguete) o a una persona se le avisa al
--     servidor, que lo valida y lo lanza. Si te atropellan a ti ("Knocked"), caes al suelo.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")

local Crash = require(ReplicatedStorage.Shared.Crash)
local Knock = require(ReplicatedStorage.Shared.Knock)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Traffic = require(script.Parent.Traffic)
local SoundFx = require(script.Parent.SoundFx)
local CameraShake = require(script.Parent.CameraShake)
local CrashFx = require(script.Parent.CrashFx)
local Nudge = require(script.Parent.Nudge)

local Collisions = {}

local player = Players.LocalPlayer

local BROAD_EVERY = 0.25 -- cada cuánto se buscan los vehículos cercanos
local BROAD_RADIUS = 110
local PROP_EVERY = 0.1 -- cada cuánto se mira qué objetos o personas toca tu vehículo
local FOOT_EVERY = 0.15 -- y andando
local PAIR_GAP = 0.5 -- el mismo golpe no se cuenta dos veces seguidas
local GHOST = 1.2 -- una moto aparcada a la que das: no se choca con ella mientras sale volando

-- Ganchos (los pone Controllers/Vehicles): bajarse ya del vehículo
Collisions.exitVehicle = nil :: (() -> ())?

type Other = {
	Model: Model?,
	Agent: any?,
	Body: Crash.Body,
	Remote: boolean, -- lo conduce otro jugador
	Parked: boolean, -- aparcado (de un jugador o de la ciudad)
	Npc: boolean, -- autobús o patrulla del juego
	Light: boolean, -- moto, bici o patinete aparcado (sale volando)
	LastPos: Vector3?,
	LastAt: number?,
	Vel: Vector3,
	Ghost: number?,
}

local entries: { [Model]: Other } = setmetatable({}, { __mode = "k" }) :: any
local nearModels: { Model } = {}
local rayIgnore: { Instance } = {}
local broadAt = -math.huge
local hitAt: { [any]: number } = setmetatable({}, { __mode = "k" }) :: any
local saidAt: { [any]: number } = setmetatable({}, { __mode = "k" }) :: any
local reportAt: { [any]: number } = setmetatable({}, { __mode = "k" }) :: any
local extents: { [Model]: { Offset: CFrame, Size: Vector3, At: number } } = setmetatable({}, { __mode = "k" }) :: any
local trafficList: { any } = {}
local getState: () -> any = function()
	return nil
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function remote(name: string): RemoteEvent?
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local r = remotes and remotes:FindFirstChild(name)
	return if r and r:IsA("RemoteEvent") then r else nil
end

local function fire(name: string, ...: any)
	local r = remote(name)
	if r then
		r:FireServer(...)
	end
end

-- El grupo de choque de los rayos del coche (atraviesan lo que se puede tumbar). nil = aún no existe
local rayGroupReady: boolean? = nil
function Collisions.rayGroup(): string?
	if rayGroupReady == nil or rayGroupReady == false then
		local ok, registered = pcall(function()
			return PhysicsService:IsCollisionGroupRegistered(Knock.RayGroup)
		end)
		rayGroupReady = ok and registered == true
	end
	return if rayGroupReady then Knock.RayGroup else nil
end

---------------------------------------------------------------------
-- Vehículos cercanos
---------------------------------------------------------------------
local function kindOf(model: Instance): string?
	local kind = model:GetAttribute("Kind")
	if typeof(kind) == "string" then
		return kind
	end
	if Gameplay.Vehicles[model.Name] then
		return model.Name
	end
	if model.Name == "ParkedCar" or model.Name == "PoliceCar" then
		return "Coche"
	end
	return nil
end

-- Caja de un vehículo: la de su base ("Chassis") o la del modelo (guardada y medida cada 2 s)
local function boxOf(model: Model, now: number): (Vector3?, Vector3?, number, number, BasePart?)
	local chassis = model:FindFirstChild("Chassis")
	if chassis and chassis:IsA("BasePart") then
		local cf = chassis.CFrame
		return cf.Position - cf.UpVector * (chassis.Size.Y / 2), cf.LookVector, chassis.Size.Z, chassis.Size.X, chassis
	end
	local ok, pivot = pcall(model.GetPivot, model)
	if not ok then
		return nil, nil, 0, 0, nil
	end
	local cached = extents[model]
	if not cached or now - cached.At > 2 then
		local okBox, box, size = pcall(function()
			return model:GetBoundingBox()
		end)
		if not okBox or typeof(box) ~= "CFrame" then
			return nil, nil, 0, 0, nil
		end
		cached = { Offset = pivot:ToObjectSpace(box), Size = size, At = now }
		extents[model] = cached
	end
	local box = pivot * cached.Offset
	return box.Position - Vector3.new(0, cached.Size.Y / 2, 0), box.LookVector, cached.Size.Z, cached.Size.X, model.PrimaryPart
end

local function consider(model: Instance, mine: Model?, center: Vector3, seen: { [Instance]: boolean })
	if seen[model] or model == mine or not model:IsA("Model") then
		return
	end
	seen[model] = true
	local kind = kindOf(model)
	if not kind or not Crash.collides(kind) then
		return
	end
	local ok, pivot = pcall(model.GetPivot, model)
	if not ok or flat(pivot.Position - center).Magnitude > BROAD_RADIUS then
		return
	end
	table.insert(nearModels, model :: Model)
end

-- Los vehículos cercanos (cada BROAD_EVERY): unas pocas carpetas y la etiqueta ParkedCar
local function gather(mine: Model?, center: Vector3)
	table.clear(nearModels)
	local seen: { [Instance]: boolean } = {}
	for _, name in { "Rides", "Buses" } do
		local folder = workspace:FindFirstChild(name)
		if folder then
			for _, m in folder:GetChildren() do
				consider(m, mine, center, seen)
			end
		end
	end
	local police = workspace:FindFirstChild("PoliceResponse")
	if police then
		for _, group in police:GetChildren() do
			for _, m in group:GetChildren() do
				consider(m, mine, center, seen)
			end
		end
	end
	for _, m in CollectionService:GetTagged("ParkedCar") do
		consider(m, mine, center, seen)
	end
	table.clear(rayIgnore)
	for _, m in nearModels do
		table.insert(rayIgnore, m)
	end
end

-- Los vehículos cercanos, para que los rayos de Driving no los cuenten como paredes (de ellos se
-- encarga el choque de verdad)
function Collisions.rayIgnore(): { Instance }
	return rayIgnore
end

local function entryOf(model: Model, now: number): Other?
	local pos, dir, length, width, chassis = boxOf(model, now)
	if not pos or not dir then
		return nil
	end
	local e = entries[model]
	if not e then
		e = {
			Model = model,
			Body = Crash.body(pos, dir, length, width, Vector3.zero, 0, kindOf(model), true),
			Remote = false,
			Parked = false,
			Npc = false,
			Light = false,
			Vel = Vector3.zero,
		}
		entries[model] = e
	end
	local other = e :: Other
	local kind = kindOf(model)
	local driver = model:GetAttribute("Driver")
	local driven = typeof(driver) == "number" and chassis ~= nil and not chassis.Anchored
	other.Remote = driven and driver ~= player.UserId
	other.Parked = not driven and (model:GetAttribute("Drivable") == true or model.Name == "ParkedCar")
	other.Npc = not driven and not other.Parked
	other.Light = other.Parked and Crash.FallSpeed[kind or ""] ~= nil and chassis ~= nil and chassis.Anchored
	-- Velocidad: la del chasis si lo conduce alguien; si no (anclado y movido por el servidor), la
	-- que se ve de un fotograma a otro
	local vel = Vector3.zero
	if driven and chassis then
		vel = flat(chassis.AssemblyLinearVelocity)
	elseif other.LastPos and other.LastAt and now > other.LastAt then
		local seen = flat(pos - other.LastPos) / (now - other.LastAt)
		vel = if seen.Magnitude < 90 then other.Vel:Lerp(seen, 0.5) else Vector3.zero
	end
	other.LastPos, other.LastAt, other.Vel = pos, now, vel
	local body = other.Body
	body.Pos, body.Dir, body.Length, body.Width, body.Vel, body.Spin = pos, flat(dir).Unit, length, width, vel, 0
	body.Kind = kind
	body.Mass = Crash.mass(kind) or Crash.DefaultMass
	-- Solo se mueven con el choque (en la cuenta) los de otro jugador y las motos aparcadas (salen
	-- volando); los demás, anclados, son como una pared con forma
	body.Kinematic = not (other.Remote or other.Light)
	return other
end

---------------------------------------------------------------------
-- Lo que se nota
---------------------------------------------------------------------
local function feel(s: any, point: Vector3, normal: Vector3, closing: number, kind: string?)
	local k = Crash.strength(closing)
	if k <= 0 then
		return
	end
	SoundFx.crash(closing, s.Chassis)
	local mult = if kind == "Frontal" then 1.25 elseif kind == "Alcance" then 0.8 else 1
	CameraShake.shake(math.clamp(closing / 35, 0.15, 1.4) * mult, 0.25 + 0.2 * k)
	local body = s.Model and s.Model:FindFirstChild("Body")
	CrashFx.hit(point, normal, k, if body and body:IsA("BasePart") then body.Color else nil)
end

-- Caerse de la moto (o de la bici, el patinete o el monopatín)
function Collisions.fall(vel: Vector3, down: number)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") or humanoid.Health <= 0 then
		return
	end
	local h = flat(vel)
	if h.Magnitude > 60 then
		h = h.Unit * 60
	end
	local v = h + Vector3.new(0, math.clamp(vel.Y, 0, 36), 0)
	humanoid.PlatformStand = true
	humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
	root.AssemblyLinearVelocity = v
	local axis = if h.Magnitude > 1e-3 then h.Unit:Cross(Vector3.yAxis) else Vector3.xAxis
	root.AssemblyAngularVelocity = -axis * math.min(4 + h.Magnitude * 0.12, 9)
	CameraShake.shake(math.clamp(v.Magnitude / 40, 0.3, 1.2), 0.4)
	task.delay(math.max(down, 0.8), function()
		if humanoid.Parent and humanoid.Health > 0 and not player:GetAttribute("KO") then
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end

local function thrown(s: any, dv: Vector3)
	if s.Thrown or not Crash.thrown(s.Kind, dv.Magnitude) then
		return
	end
	s.Thrown = true
	local dir = if s.Chassis then s.Chassis.CFrame.LookVector else Vector3.new(0, 0, -1)
	-- Sales despedido hacia donde ibas (el vehículo se para; tú no)
	local vel = flat(dir) * math.min(dv.Magnitude * 0.8, 45) + Vector3.new(0, math.min(10 + dv.Magnitude * 0.3, 28), 0)
	task.defer(function()
		if Collisions.exitVehicle then
			pcall(Collisions.exitVehicle)
		end
		task.wait(0.08)
		Collisions.fall(vel, 2.2)
	end)
end
Collisions.thrown = thrown

-- Golpe contra una pared (Driving): chispas, daños y, en moto, al suelo
function Collisions.wall(s: any, point: Vector3, normal: Vector3, speed: number)
	feel(s, point, normal, speed, "Frontal")
	thrown(s, Vector3.new(speed * 1.15, 0, 0))
	if speed >= Crash.DentAt and os.clock() - (reportAt.bump or -math.huge) > 0.6 then
		reportAt.bump = os.clock()
		fire("Crash", "Bump", { Speed = speed, Point = point })
	end
end

---------------------------------------------------------------------
-- El choque de cada fotograma
---------------------------------------------------------------------
local function headingOf(s: any): Vector3
	return Vector3.new(-math.sin(s.Travel), 0, -math.cos(s.Travel))
end

-- Pone en tu vehículo la velocidad y el giro nuevos (la marcha a lo largo de hacia donde va; el
-- resto, un empujón de lado que se va apagando)
local function applyTo(s: any, vel: Vector3, spin: number, maxSpeed: number)
	local speed, push = Crash.split(flat(vel), headingOf(s))
	s.Speed = math.clamp(speed, -maxSpeed, maxSpeed + 25)
	if push.Magnitude > Crash.MaxDeltaV then
		push = push.Unit * Crash.MaxDeltaV
	end
	s.Push = push
	s.Spin = math.clamp(spin, -Crash.MaxSpin, Crash.MaxSpin)
end

local function npcReact(model: Model, closing: number)
	local now = os.clock()
	if closing < 5 or now - (saidAt[model] or -math.huge) < 4 then
		return
	end
	saidAt[model] = now
	local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if part then
		pcall(Nudge.say, part, if closing > 25 then "¡Pero bueno! ¿Estás loco?" else "¡Eh!", 1.8)
		pcall(SoundFx.play, "Claxon", 0.8, 0.8, part)
	end
end

-- Driving llama a esto con el paso que va a dar tu vehículo: devuelve el paso corregido (fuera de
-- los otros) y cambia la velocidad, el empujón y el giro de s.
function Collisions.solve(s: any, base: Vector3, move: Vector3, forward: Vector3, dt: number, maxSpeed: number): Vector3
	if not Crash.collides(s.Kind) then
		return move
	end
	local now = os.clock()
	local size = s.Chassis.Size
	if now - broadAt >= BROAD_EVERY then
		broadAt = now
		gather(s.Model, base)
	end
	-- Los de esta vez (vehículos cercanos + tráfico)
	local list: { Other } = {}
	for _, model in nearModels do
		if model.Parent then
			local e = entryOf(model, now)
			if e and not (e.Ghost and now < e.Ghost) then
				table.insert(list, e)
			end
		end
	end
	table.clear(trafficList)
	local okTraffic = pcall(Traffic.near, base, 60, trafficList)
	if okTraffic then
		for _, agent in trafficList do
			local body = Crash.body(Vector3.new(agent.Pos.X, base.Y, agent.Pos.Z), agent.Dir, agent.Length, agent.Width, agent.Dir * agent.Speed + (agent.ShoveVel or Vector3.zero), 0, if agent.Kind == "Car" then "Car" else agent.Kind, false)
			table.insert(list, { Agent = agent, Body = body, Remote = false, Parked = false, Npc = false, Light = false, Vel = body.Vel })
		end
	end
	if #list == 0 then
		return move
	end
	local heading = headingOf(s)
	local startVel = heading * s.Speed + (s.Push or Vector3.zero)
	-- Para que ni a mucha velocidad (o con un tirón) se atraviese algo fino: se prueba en trozos
	local steps = math.clamp(math.ceil(move.Magnitude / 1.5), 1, 4)
	for i = 1, steps do
		local at = base + move * (i / steps)
		local me = Crash.body(at, forward, size.Z, size.X, startVel, s.Spin or 0, s.Kind, false)
		me.Pos = Vector3.new(at.X, base.Y, at.Z)
		local touched = false
		for _, o in list do
			local c = Crash.contact(me, o.Body)
			if c then
				touched = true
				local key = o.Model or o.Agent
				local recent = key ~= nil and hitAt[key] ~= nil and now - hitAt[key] < PAIR_GAP
				local before = me.Vel
				local r = Crash.resolve(me, o.Body, c, not recent)
				me.Vel, me.Spin = r.VelA, r.SpinA
				-- Fuera del otro: tu parte, o todo si el otro no lo puede mover tu pantalla
				local out = r.MoveA
				if o.Remote or o.Body.Kinematic or o.Light then
					out = -c.Normal * math.min(c.Depth + Crash.Slop, Crash.MaxCorrection)
				end
				me.Pos += out
				if o.Agent then
					local okHit, said = pcall(Traffic.hit, o.Agent, r.VelB, r.SpinB, r.MoveB, r.Closing)
					local part = o.Agent.Parts and o.Agent.Parts[1]
					if okHit and said and o.Agent.Kind == "Car" and part then
						pcall(SoundFx.play, "Claxon", 0.7, 0.95, part) -- (te pita)
					end
				end
				if r.Impulse > 0 and not recent and r.Closing >= Crash.FeelSpeed then
					if key then
						hitAt[key] = now
					end
					feel(s, c.Point, c.Normal, r.Closing, r.Type)
					thrown(s, me.Vel - before)
					s.Blocker = "Trafico"
					if r.Closing > 8 then
						s.Throttle = 0
					end
					local model = o.Model
					if model then
						if o.Remote or o.Parked then
							-- El servidor lo comprueba y empuja al otro (o lanza la moto aparcada)
							if now - (reportAt[model] or -math.huge) > 0.4 then
								reportAt[model] = now
								fire("Crash", "Hit", model, { Speed = before.Magnitude })
							end
							if o.Light then
								o.Ghost = now + GHOST
							end
						else
							npcReact(model, r.Closing)
							if r.Closing >= Crash.DentAt and now - (reportAt.bump or -math.huge) > 0.6 then
								reportAt.bump = now
								fire("Crash", "Bump", { Speed = r.Closing, Point = c.Point })
							end
						end
					elseif r.Closing >= Crash.DentAt and now - (reportAt.bump or -math.huge) > 0.6 then
						reportAt.bump = now
						fire("Crash", "Bump", { Speed = r.Closing, Point = c.Point })
					end
				end
			end
		end
		if touched then
			applyTo(s, me.Vel, me.Spin, maxSpeed)
			return me.Pos - base
		end
	end
	return move
end

-- El servidor dice que otro jugador te ha dado (ya comprobado y con topes)
local function onImpact(data: any)
	local s = getState()
	if not s or type(data) ~= "table" or data.Model ~= s.Model or typeof(data.Dv) ~= "Vector3" then
		return
	end
	local from = data.From
	local now = os.clock()
	if typeof(from) == "Instance" and hitAt[from] and now - hitAt[from] < PAIR_GAP then
		return -- (tu pantalla ya lo había resuelto)
	end
	if typeof(from) == "Instance" then
		hitAt[from] = now
	end
	local dv = flat(data.Dv)
	if dv.Magnitude ~= dv.Magnitude then
		return
	end
	if dv.Magnitude > Crash.MaxDeltaV then
		dv = dv.Unit * Crash.MaxDeltaV
	end
	local spin = if type(data.Spin) == "number" and data.Spin == data.Spin then math.clamp(data.Spin, -Crash.MaxSpin, Crash.MaxSpin) else 0
	local heading = headingOf(s)
	local vel = heading * s.Speed + (s.Push or Vector3.zero) + dv
	local maxSpeed = (Gameplay.Vehicles[s.Kind] and Gameplay.Vehicles[s.Kind].Speed) or 60
	applyTo(s, vel, (s.Spin or 0) + spin, maxSpeed)
	local closing = if type(data.Closing) == "number" then math.clamp(data.Closing, 0, 200) else dv.Magnitude
	local point = if typeof(data.Point) == "Vector3" then data.Point else s.Chassis.Position
	feel(s, point, if dv.Magnitude > 1e-3 then -dv.Unit else Vector3.zAxis, closing, data.Type)
	thrown(s, dv)
end

---------------------------------------------------------------------
-- Objetos y personas
---------------------------------------------------------------------
local function personOf(part: Instance): Model?
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		if model:FindFirstChildOfClass("Humanoid") then
			return model
		end
		model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
	end
	return nil
end

local propAt = -math.huge
local footAt = -math.huge
local knockCool: { [any]: number } = {}

local function cool(key: any, now: number, gap: number): boolean
	if now - (knockCool[key] or -math.huge) < gap then
		return false
	end
	knockCool[key] = now
	return true
end

-- Tu vehículo toca algo que se puede tumbar, un balón o una persona (Driving, cada fotograma)
function Collisions.touchProps(s: any, base: Vector3, forward: Vector3, speed: number)
	local now = os.clock()
	if now - propAt < PROP_EVERY or math.abs(speed) < Knock.MinSpeed then
		return
	end
	propAt = now
	local size = s.Chassis.Size
	local sign = if speed >= 0 then 1 else -1
	local ahead = math.abs(speed) * 0.12 + 1
	local center = base + Vector3.new(0, 2.4, 0) + forward * sign * (ahead / 2)
	local box = CFrame.lookAt(center, center + forward)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = { s.Model }
	if player.Character then
		table.insert(ignore, player.Character)
	end
	params.FilterDescendantsInstances = ignore
	params.RespectCanCollide = false
	params.MaxParts = 40
	local ok, parts = pcall(function()
		return workspace:GetPartBoundsInBox(box, Vector3.new(size.X + 0.6, 4.2, size.Z + ahead), params)
	end)
	if not ok or type(parts) ~= "table" then
		return
	end
	local vel = headingOf(s) * s.Speed + (s.Push or Vector3.zero)
	local mass = Crash.mass(s.Kind) or Crash.DefaultMass
	for _, part in parts do
		local id = part:GetAttribute("Knock")
		if type(id) == "number" then
			local profile = Knock.Catalog[part:GetAttribute("KnockKind") or ""]
			if profile and profile.MinSpeed and math.abs(speed) < profile.MinSpeed then
				-- Pesado y despacio: es como una pared (los rayos no lo ven: se para aquí)
				if cool("solid" .. id, now, 0.5) then
					feel(s, part.Position, -forward * sign, math.abs(speed), "Frontal")
				end
				s.Speed = -s.Speed * 0.15
				s.Throttle = 0
				s.Blocker = "Pared"
				return
			end
			if cool(id, now, 0.35) then
				fire("Knock", "Prop", id, { Vel = vel })
				-- Tu vehículo pierde un poco (poco con una papelera; más en moto)
				local m = if profile then profile.Mass else 20
				local share = math.min((1 + Knock.Restitution) * m / (mass + m), 0.6)
				s.Speed *= 1 - share
				if math.abs(speed) > 12 then
					pcall(SoundFx.play, "Golpe", math.clamp(math.abs(speed) / 60, 0.3, 0.9), 0.8 + math.random() * 0.3, part)
					CameraShake.shake(math.clamp(math.abs(speed) / 90 * m / 30, 0.05, 0.5), 0.2)
				end
			end
		elseif part:GetAttribute("Toy") ~= nil then
			if cool(part, now, 0.3) then
				fire("Knock", "Prop", part, { Vel = vel })
			end
		else
			local person = personOf(part)
			if person and person ~= player.Character and cool(person, now, 1) then
				fire("Knock", "Person", person, { Vel = vel })
				local hit = Knock.person(vel, mass)
				if hit.Mode ~= "none" and hit.Mode ~= "stumble" then
					s.Speed *= 1 - math.min((1 + Knock.Restitution) * Knock.CharacterMass / (mass + Knock.CharacterMass), 0.5)
					pcall(SoundFx.play, "Golpe", 0.8, 0.7, part)
					CameraShake.shake(0.35, 0.25)
				end
			end
		end
	end
end

-- Andando: tocas algo que se puede tumbar (se vuelca o, corriendo, sale un poco) o chocas corriendo
-- con otra persona (un empujón)
local function footStep()
	local now = os.clock()
	if now - footAt < FOOT_EVERY then
		return
	end
	footAt = now
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") or humanoid.SeatPart or humanoid.Health <= 0 or humanoid.PlatformStand then
		return
	end
	local vel = flat(root.AssemblyLinearVelocity)
	if vel.Magnitude < 3 then
		return
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character :: Instance }
	params.RespectCanCollide = false
	params.MaxParts = 20
	local center = root.Position - Vector3.new(0, 1.2, 0) + vel.Unit * 1.1
	local ok, parts = pcall(function()
		return workspace:GetPartBoundsInRadius(center, 2.1, params)
	end)
	if not ok or type(parts) ~= "table" then
		return
	end
	for _, part in parts do
		local id = part:GetAttribute("Knock")
		if type(id) == "number" then
			local profile = Knock.Catalog[part:GetAttribute("KnockKind") or ""]
			if not (profile and profile.MinSpeed and vel.Magnitude < profile.MinSpeed) and cool(id, now, 0.5) then
				fire("Knock", "Prop", id, { Vel = vel })
			end
		elseif vel.Magnitude > 14 then
			local person = personOf(part)
			if person and person ~= character and cool(person, now, 1.5) then
				fire("Knock", "Shove", person, { Vel = vel })
			end
		end
	end
end

-- Te han atropellado (o empujado): el servidor ya lo ha comprobado
local function onKnocked(data: any)
	if type(data) ~= "table" or typeof(data.Vel) ~= "Vector3" then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.SeatPart or not root or not root:IsA("BasePart") then
		return
	end
	local vel: Vector3 = data.Vel
	if vel.Magnitude ~= vel.Magnitude then
		return
	end
	if data.Mode == "stumble" then
		local h = flat(vel)
		if h.Magnitude > 10 then
			h = h.Unit * 10
		end
		root.AssemblyLinearVelocity += h + Vector3.new(0, 3, 0)
		CameraShake.shake(0.2, 0.2)
		return
	end
	local down = if type(data.Down) == "number" then math.clamp(data.Down, 0.5, 5) else 2.5
	Collisions.fall(vel, down)
end

function Collisions.init(stateGetter: () -> any)
	getState = stateGetter
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
		local crash = remotes and remotes:WaitForChild("Crash", 30)
		if crash and crash:IsA("RemoteEvent") then
			crash.OnClientEvent:Connect(function(action, data)
				if action == "Impact" then
					pcall(onImpact, data)
				end
			end)
		end
		local knock = remotes and remotes:WaitForChild("Knock", 30)
		if knock and knock:IsA("RemoteEvent") then
			knock.OnClientEvent:Connect(function(action, data)
				if action == "Knocked" then
					pcall(onKnocked, data)
				end
			end)
		end
	end)
	RunService.Heartbeat:Connect(function()
		if getState() == nil then
			pcall(footStep)
		end
	end)
end

return Collisions
