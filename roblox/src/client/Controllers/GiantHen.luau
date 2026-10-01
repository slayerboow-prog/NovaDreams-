-- GiantHen (cliente): las gallinas hechas por código (World/Kit/GallinaGigante, etiqueta
-- "GallinaGigante") se mueven como gallinas, solo en tu pantalla y solo cerca de ti:
--   * respiran (el cuerpo sube y baja un poco) y la cola se mece;
--   * la cabeza va «a golpes»: se queda quieta y de repente cambia de postura (mirar a un lado,
--     ladear la cabeza), y a veces picotea el suelo deprisa;
--   * de vez en cuando se acomodan: se ahuecan, sacuden las alas y se agachan un poco;
--   * al andar (Petra persiguiéndote) mueven las patas, aletean y la cabeza va adelante y atrás;
--     si es enorme, cada paso hace temblar el suelo (golpe sordo de SoundIds.golpe_caida).
--
-- Las cuentas (cuánto gira cada articulación) son funciones puras: scripts/test-gallina.luau

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GiantHen = {}

local sin = math.sin
local angles = CFrame.Angles

local RADIUS = 260 -- más lejos no se anima (no se nota)

export type State = {
	Head: Vector3, -- (cabeceo, giro, ladeo) actual
	Goal: Vector3, -- a dónde va la cabeza
	NextJerk: number, -- cuándo cambia de postura
	PeckUntil: number, -- picoteando hasta entonces
	SettleAt: number, -- cuándo se acomoda la próxima vez
	Settle: number, -- (0..1) cuánto de acomodarse queda
	Phase: number,
	Step: number, -- fase de las patas
	LastStep: number,
}

---------------------------------------------------------------------
-- Cuentas (puras)
---------------------------------------------------------------------

function GiantHen.newState(seed: number): State
	return {
		Head = Vector3.zero,
		Goal = Vector3.zero,
		NextJerk = 0,
		PeckUntil = 0,
		SettleAt = 6 + (seed % 7),
		Settle = 0,
		Phase = (seed % 13) * 0.7,
		Step = 0,
		LastStep = 0,
	}
end

-- Un paso de la gallina: tiempo t, dt, velocidad (studs/s), rnd() en [0,1) y si es enorme.
-- Devuelve las posturas de cada articulación (giros, más el leve sube y baja del cuerpo, en unidades
-- del dibujo: el que llama lo multiplica por la escala) y si ha dado un paso que se oye.
function GiantHen.pose(st: State, t: number, dt: number, speed: number, rnd: () -> number): ({ [string]: CFrame }, boolean)
	local moving = speed > 1.5
	-- Cabeza «a golpes»: quieta, y de repente otra postura
	if t >= st.NextJerk then
		if moving then
			st.Goal = Vector3.new(-0.15 + rnd() * 0.1, (rnd() - 0.5) * 0.4, 0)
			st.NextJerk = t + 0.25 + rnd() * 0.2
		elseif rnd() < 0.3 then
			st.PeckUntil = t + 0.22 -- picotazo
			st.Goal = Vector3.new(0.95, (rnd() - 0.5) * 0.2, 0)
			st.NextJerk = t + 0.22
		else
			st.Goal = Vector3.new(-0.2 + rnd() * 0.35, (rnd() - 0.5) * 1.2, (rnd() - 0.5) * 0.5)
			st.NextJerk = t + 0.35 + rnd() * 0.9
		end
	end
	if t >= st.PeckUntil and st.Goal.X > 0.8 then
		st.Goal = Vector3.new(0, st.Goal.Y, 0) -- vuelve a subir la cabeza tras el picotazo
	end
	-- Muy deprisa hacia la nueva postura (las gallinas no giran la cabeza despacio)
	local alpha = 1 - math.exp(-dt * 28)
	st.Head = st.Head:Lerp(st.Goal, alpha)

	-- Acomodarse de vez en cuando (no andando)
	if not moving and t >= st.SettleAt then
		st.Settle = 1
		st.SettleAt = t + 9 + rnd() * 7
	end
	st.Settle = math.max(0, st.Settle - dt / 1.1)
	local settle = st.Settle
	local ruffle = if settle > 0 then sin(settle * 40) * settle else 0

	-- Respirar
	local breath = sin(t * 2.1 + st.Phase)
	local body = CFrame.new(0, breath * 0.03 - settle * 0.25, 0) * angles(breath * 0.012 + settle * 0.05, 0, ruffle * 0.06)
	local head = angles(st.Head.X, st.Head.Y, st.Head.Z)
	local wing = ruffle * 0.25
	local legL, legR = 0, 0
	local stepped = false
	if moving then
		-- Patas alternas (más rápido cuanto más corre) y aleteo
		local freq = math.clamp(speed * 0.35, 3, 9)
		st.Step += dt * freq
		legL = sin(st.Step) * 0.55
		legR = -legL
		wing = sin(t * 13) * 0.35
		body = body * CFrame.new(0, math.abs(sin(st.Step)) * 0.12, 0)
		local half = math.floor(st.Step / math.pi)
		if half ~= st.LastStep then
			st.LastStep = half
			stepped = true
		end
	end
	return {
		Cuerpo = body,
		Cabeza = head,
		AlaL = angles(0, 0, -wing),
		AlaR = angles(0, 0, wing),
		Cola = angles(sin(t * 1.3 + st.Phase) * 0.05, sin(t * 0.9) * 0.06, 0),
		PataL = angles(legL, 0, 0),
		PataR = angles(legR, 0, 0),
	},
		stepped
end

---------------------------------------------------------------------
-- En el juego
---------------------------------------------------------------------

type Entry = { Model: Model, Root: BasePart, Motors: { [string]: Motor6D }, State: State, Thud: Sound? }

local entries: { [Model]: Entry } = {}
local seedCount = 0

local function add(model: Instance)
	if not model:IsA("Model") or entries[model] then
		return
	end
	local root = model:FindFirstChild("GallinaRaiz") :: BasePart?
	if not root then
		return
	end
	local motors = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Motor6D") and d.Name:sub(1, 2) == "M_" then
			motors[d.Name:sub(3)] = d
		end
	end
	seedCount += 1
	entries[model] = { Model = model, Root = root, Motors = motors, State = GiantHen.newState(seedCount * 7 + 3) }
end

local function remove(model: Instance)
	local entry = entries[model :: Model]
	if entry and entry.Thud then
		entry.Thud:Destroy()
	end
	entries[model :: Model] = nil
end

local function thudFor(entry: Entry): Sound?
	if entry.Thud then
		return entry.Thud
	end
	local ok, SoundIds = pcall(require, ReplicatedStorage.Shared.SoundIds)
	local id = ok and SoundIds and SoundIds.golpe_caida
	if not id then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = 0.35
	sound.PlaybackSpeed = 0.45 -- grave: pasos de algo muy grande
	sound.RollOffMaxDistance = 120
	sound.Parent = entry.Root
	entry.Thud = sound
	return sound
end

function GiantHen.init()
	for _, model in CollectionService:GetTagged("GallinaGigante") do
		add(model)
	end
	CollectionService:GetInstanceAddedSignal("GallinaGigante"):Connect(add)
	CollectionService:GetInstanceRemovedSignal("GallinaGigante"):Connect(remove)

	local rng = Random.new()
	local function rnd(): number
		return rng:NextNumber()
	end
	RunService.RenderStepped:Connect(function(dt)
		local camera = workspace.CurrentCamera
		if not camera or next(entries) == nil then
			return
		end
		local from = camera.CFrame.Position
		local t = os.clock()
		for model, entry in entries do
			local root = entry.Root
			if not model.Parent or not root.Parent then
				remove(model)
				continue
			end
			if (root.Position - from).Magnitude > RADIUS then
				continue
			end
			-- Escala actual (Model:ScaleTo la cambia: el rayo encogedor)
			local base = model:GetAttribute("RaizBase")
			local scale = if type(base) == "number" and base > 0 then root.Size.X / base else 1
			local altura = model:GetAttribute("Altura")
			local unit = scale * (if type(altura) == "number" then altura / 10.25 else 1)
			local velocity = root.AssemblyLinearVelocity
			local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
			local poses, stepped = GiantHen.pose(entry.State, t, dt, speed, rnd)
			for name, cf in poses do
				local motor = entry.Motors[name]
				if motor then
					motor.Transform = cf.Rotation + cf.Position * unit
				end
			end
			if stepped and unit * 10.25 > 12 then
				local sound = thudFor(entry)
				if sound then
					sound:Play()
				end
			end
		end
	end)
end

return GiantHen
