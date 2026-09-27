-- AgeMotion (cliente): cada edad se mueve a su manera.
--
--   * Bebé que aún no se ha levantado (atributo Crawling): gatea a cuatro patas, moviendo a la vez
--     el brazo de un lado y la pierna del otro, con la cabeza levantada mirando al frente.
--   * Bebé de pie: pasitos de pato, piernas abiertas y brazos separados para no caerse.
--   * Niño: brazos más sueltos al andar, cabeza alta y no se está quieto.
--   * Adolescente: un poco encorvado, hombros hacia delante y brazos más caídos.
--   * Adulto: como siempre.
--   * Mayor: espalda encorvada, rodillas algo dobladas, pasos cortos y brazos que casi no se balancean.
--   * En el agua y pescando (jugadores): nada, bucea, apunta con el fusil, echa la caña, pelea con
--     el pez… con las posturas de SeaMotion, y lleva sus cosas (SeaFx: caña, fusil, gafas, burbujas).
--   * Trabajando (jugadores): quieto en su puesto hace su oficio con las posturas de WorkAnim
--     (el barista remueve el café, el cajero pasa productos, el bombero sujeta la manguera…) y,
--     si lleva algo (una caja, un plato, un paquete), lo sujeta con las dos manos, también andando.
--
-- Se aplica a los jugadores (según su LifeStage) y a los personajes con el atributo "Age"
-- (compañeros de clase, la abuela…). Todo en tu pantalla, encima de sus animaciones: cada frame,
-- después de que Roblox anime (PreSimulation), se retoca Motor6D.Transform. Así no choca con
-- ActorLife, que mueve C0 (mirada, gestos, tareas).
--
-- Las funciones puras (style, crawlPose, lowestPoint) se prueban fuera de Roblox:
-- scripts/test-agemotion.luau

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local WorkAnim = require(script.Parent.WorkAnim)
local SeaMotion = require(script.Parent.SeaMotion)
local SeaFx = require(script.Parent.SeaFx)

local AgeMotion = {}

local ACTIVE_DISTANCE = 110
local MAX_ACTIVE = 24

local JOINTS = {
	"Root",
	"Waist",
	"Neck",
	"RightShoulder",
	"LeftShoulder",
	"RightElbow",
	"LeftElbow",
	"RightWrist",
	"LeftWrist",
	"RightHip",
	"LeftHip",
	"RightKnee",
	"LeftKnee",
	"RightAnkle",
	"LeftAnkle",
}
AgeMotion.Joints = JOINTS

local ARMS = { RightShoulder = true, LeftShoulder = true, RightElbow = true, LeftElbow = true, RightWrist = true, LeftWrist = true }
local LEGS = { RightHip = true, LeftHip = true, RightKnee = true, LeftKnee = true, RightAnkle = true, LeftAnkle = true }

local sin, cos, abs = math.sin, math.cos, math.abs
local angles = CFrame.Angles
local HALF_PI = math.pi / 2
local CRAWL_TILT = 0.2 -- cuánto más altos van los hombros que la cadera al gatear (radianes)

---------------------------------------------------------------------
-- Estilos por edad (retoques encima de la animación)
---------------------------------------------------------------------

export type Style = {
	Arms: number, -- cuánto se balancean los brazos (1 = como la animación)
	Legs: number, -- cuánto se mueven las piernas
	Offsets: (t: number, move: number, phase: number) -> { [string]: CFrame },
}

local STYLES: { [string]: Style } = {
	-- De pie, recién aprendido a andar: pasitos de pato con los brazos abiertos
	Bebe = {
		Arms = 0.3,
		Legs = 0.85,
		Offsets = function(t, move, phase)
			local waddle = sin(phase) * 0.1 * move + sin(t * 1.3) * 0.02
			return {
				Root = angles(0, 0, waddle),
				Waist = angles(0.05, 0, -waddle * 0.5), -- tripita fuera
				RightShoulder = angles(0.35, 0, 0.45),
				LeftShoulder = angles(0.35, 0, -0.45),
				RightElbow = angles(0.5, 0, 0),
				LeftElbow = angles(0.5, 0, 0),
				RightHip = angles(0, 0, 0.1), -- piernas abiertas
				LeftHip = angles(0, 0, -0.1),
				RightAnkle = angles(0, 0, -0.1), -- con los pies planos
				LeftAnkle = angles(0, 0, 0.1),
			}
		end,
	},
	-- Suelto y con energía: no se está quieto
	Nino = {
		Arms = 1.3,
		Legs = 1.1,
		Offsets = function(t, move, _phase)
			local still = 1 - move
			return {
				Root = angles(0, 0, sin(t * 1.7) * 0.03 * still),
				Neck = angles(0.05, sin(t * 0.9) * 0.12 * still, 0),
			}
		end,
	},
	-- Un poco encorvado, hombros hacia delante
	Adolescente = {
		Arms = 0.8,
		Legs = 1,
		Offsets = function(_t, _move, _phase)
			return {
				Waist = angles(-0.06, 0, 0),
				Neck = angles(-0.06, 0, 0),
				RightShoulder = angles(0.04, 0, -0.06),
				LeftShoulder = angles(0.04, 0, 0.06),
			}
		end,
	},
	-- Espalda encorvada (mira al frente), rodillas algo dobladas, pasos cortos, brazos quietos
	Mayor = {
		Arms = 0.5,
		Legs = 0.7,
		Offsets = function(t, move, phase)
			local sway = sin(phase) * 0.05 * move + sin(t * 1.1) * 0.015
			return {
				Root = angles(0, 0, sway),
				Waist = angles(-0.2, 0, 0),
				Neck = angles(0.17, 0, 0),
				RightShoulder = angles(0.08, 0, 0),
				LeftShoulder = angles(0.08, 0, 0),
				RightElbow = angles(0.3, 0, 0),
				LeftElbow = angles(0.3, 0, 0),
				RightHip = angles(0.1, 0, 0),
				LeftHip = angles(0.1, 0, 0),
				RightKnee = angles(-0.16, 0, 0),
				LeftKnee = angles(-0.16, 0, 0),
			}
		end,
	},
}
AgeMotion.Styles = STYLES

function AgeMotion.style(stage: any): Style?
	if type(stage) ~= "string" then
		return nil
	end
	return STYLES[stage]
end

-- Más o menos giro que la animación (k = 1: igual; 0.5: la mitad)
local function scaled(cf: CFrame, k: number): CFrame
	if k == 1 then
		return cf
	end
	local axis, angle = cf:ToAxisAngle()
	if abs(angle) < 1e-4 then
		return CFrame.new(cf.Position * k)
	end
	return CFrame.new(cf.Position * k) * CFrame.fromAxisAngle(axis, angle * k)
end
AgeMotion.scaled = scaled

---------------------------------------------------------------------
-- Gatear
---------------------------------------------------------------------

-- Postura a cuatro patas. move 0..1 (quieto → gateando), phase = paso. drop baja el cuerpo hasta
-- que manos y rodillas tocan el suelo (lo calcula lowestPoint con las medidas de cada personaje).
function AgeMotion.crawlPose(move: number, phase: number, drop: number): { [string]: CFrame }
	local s = sin(phase) * move
	local reach = 0.35
	-- Los brazos son más largos que los muslos: la espalda baja un poco hacia la cadera, con los
	-- brazos y los muslos rectos hacia el suelo
	local tilt = CRAWL_TILT
	local down = HALF_PI - tilt
	return {
		-- El cuerpo tumbado hacia delante, meciéndose un poco con cada paso
		Root = CFrame.new(0, drop, 0) * angles(-down, 0, s * 0.06),
		Waist = angles(0, s * 0.08, 0),
		Neck = angles(1.15 - tilt, 0, 0), -- cabeza levantada: mira al frente
		-- Brazo derecho con pierna izquierda, y al revés
		RightShoulder = angles(down + reach * s, 0, 0),
		LeftShoulder = angles(down - reach * s, 0, 0),
		RightElbow = angles(math.max(0, cos(phase)) * 0.35 * move, 0, 0),
		LeftElbow = angles(math.max(0, -cos(phase)) * 0.35 * move, 0, 0),
		RightWrist = CFrame.identity,
		LeftWrist = CFrame.identity,
		RightHip = angles(down - reach * s, 0, 0),
		LeftHip = angles(down + reach * s, 0, 0),
		RightKnee = angles(-HALF_PI, 0, 0),
		LeftKnee = angles(-HALF_PI, 0, 0),
		RightAnkle = CFrame.identity,
		LeftAnkle = CFrame.identity,
	}
end

export type RigShape = {
	-- Por articulación: qué pieza mueve (Part0 → Part1) y sus C0/C1
	Joints: { [string]: { Part0: string, Part1: string, C0: CFrame, C1: CFrame } },
	Sizes: { [string]: Vector3 },
}

-- El punto más bajo del cuerpo (relativo a HumanoidRootPart) con esas transformaciones
function AgeMotion.lowestPoint(shape: RigShape, transforms: { [string]: CFrame }): number
	local frames: { [string]: CFrame } = { HumanoidRootPart = CFrame.identity }
	-- Las articulaciones van de dentro hacia fuera: se repite hasta colocar todas las piezas
	local pending = true
	local guard = 0
	while pending and guard < 20 do
		pending = false
		guard += 1
		for name, joint in shape.Joints do
			if frames[joint.Part1] == nil then
				local parent = frames[joint.Part0]
				if parent then
					frames[joint.Part1] = parent * joint.C0 * (transforms[name] or CFrame.identity) * joint.C1:Inverse()
				else
					pending = true
				end
			end
		end
	end
	local lowest = math.huge
	for part, frame in frames do
		local size = shape.Sizes[part]
		if size and part ~= "HumanoidRootPart" then
			local h = size / 2
			for _, x in { -h.X, h.X } do
				for _, y in { -h.Y, h.Y } do
					for _, z in { -h.Z, h.Z } do
						lowest = math.min(lowest, (frame * Vector3.new(x, y, z)).Y)
					end
				end
			end
		end
	end
	return lowest
end

---------------------------------------------------------------------
-- Personajes
---------------------------------------------------------------------

type Body = {
	Model: Model,
	Humanoid: Humanoid,
	Root: BasePart,
	Player: Player?,
	Joints: { [string]: Motor6D },
	Base: { [string]: CFrame }, -- lo que puso la animación este frame
	Written: { [string]: CFrame }, -- lo que pusimos nosotros (si sigue igual, la animación no lo tocó)
	Active: boolean,
	Crawl: number, -- 0..1, suave
	Style: number, -- 0..1, suave (se quita al sentarse, conducir, dormir…)
	StageName: string?,
	Move: number,
	Phase: number,
	LastPos: Vector3?,
	Drop: number?,
	DropScale: number?,
	Seed: number, -- desfase propio (que no hagan todos lo mismo a la vez)
	WorkName: string?, -- tarea para la que están hechos sus objetos de la mano
	Work: number, -- 0..1: cuánto está haciendo su tarea (suave)
	WorkPose: WorkAnim.Pose,
	Props: { WorkAnim.HeldProp },
	Sea: number, -- 0..1: cuánto manda la postura de nadar o pescar (suave)
	SeaPose: { [string]: CFrame }?,
	SeaPhase: number,
	WaterAt: number, -- cuándo se miró por última vez si hay agua debajo
	Water: boolean,
	LastY: number?,
	Fx: any,
}

local bodies: { [Model]: Body } = {}
local active: { Body } = {}

local function smooth(current: number, target: number, rate: number, dt: number): number
	return current + (target - current) * (1 - math.exp(-rate * dt))
end

local function register(model: Model)
	if bodies[model] then
		return
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return
	end
	bodies[model] = {
		Model = model,
		Humanoid = humanoid,
		Root = root,
		Player = Players:GetPlayerFromCharacter(model),
		Joints = {},
		Base = {},
		Written = {},
		Active = false,
		Crawl = 0,
		Style = 0,
		StageName = nil,
		Move = 0,
		Phase = 0,
		LastPos = nil,
		Drop = nil,
		DropScale = nil,
		Seed = math.random() * 100,
		WorkName = nil,
		Work = 0,
		WorkPose = {} :: any,
		Props = {},
		Sea = 0,
		SeaPose = nil,
		SeaPhase = 0,
		WaterAt = 0,
		Water = false,
		LastY = nil,
		Fx = SeaFx.new(),
	}
	WorkAnim.clear(bodies[model].WorkPose)
	model.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			bodies[model] = nil
		end
	end)
end

local function findJoints(body: Body)
	table.clear(body.Joints)
	for _, name in JOINTS do
		local joint = body.Model:FindFirstChild(name, true)
		if joint and joint:IsA("Motor6D") then
			body.Joints[name] = joint
		end
	end
end

-- Edad y si gatea: de su jugador, o del atributo "Age" si es un personaje
local function stageOf(body: Body): (string?, boolean)
	local player = body.Player
	if player then
		return player:GetAttribute("LifeStage"), player:GetAttribute("Crawling") == true
	end
	return body.Model:GetAttribute("Age"), body.Model:GetAttribute("Crawling") == true
end

-- ¿Está sentado, conduciendo o durmiendo? (entonces no se toca: manda esa postura)
local function busy(body: Body): boolean
	if body.Humanoid.Sit then
		return true
	end
	local player = body.Player
	if player and (player:GetAttribute("Riding") or player:GetAttribute("Sleeping")) then
		return true
	end
	return false
end

-- Cuánto hay que bajar el cuerpo para que al gatear toque el suelo (según su tamaño)
local function crawlDrop(body: Body): number
	local scale = body.Model:GetScale()
	if body.Drop and body.DropScale and abs(body.DropScale - scale) < 0.01 then
		return body.Drop
	end
	local shape: RigShape = { Joints = {}, Sizes = {} }
	for name, joint in body.Joints do
		local p0, p1 = joint.Part0, joint.Part1
		if p0 and p1 then
			shape.Joints[name] = { Part0 = p0.Name, Part1 = p1.Name, C0 = joint.C0, C1 = joint.C1 }
			shape.Sizes[p1.Name] = p1.Size
		end
	end
	local floor = -(body.Humanoid.HipHeight + body.Root.Size.Y / 2)
	local lowest = AgeMotion.lowestPoint(shape, AgeMotion.crawlPose(0, 0, 0))
	-- (un poquito por encima del suelo, para que no roce)
	local drop = if lowest == math.huge then 0 else floor - lowest + 0.04 * scale
	body.Drop = drop
	body.DropScale = scale
	return drop
end

-- ¿Es la misma transformación? (casi exacta: lo que se escribe puede volver con un redondeo)
local function same(a: CFrame, b: CFrame): boolean
	return (a.Position - b.Position).Magnitude < 1e-4 and a.LookVector:Dot(b.LookVector) > 0.999999 and a.UpVector:Dot(b.UpVector) > 0.999999
end

-- Qué oficio hace cada trabajo cuando el jugador está quieto en su puesto
local JOB_WORK = {
	Barista = "Coffee",
	Cajero = "Scan",
	Charcutero = "Cut",
	Recepcionista = "Type",
	Taquillero = "Type",
	Medico = "Clipboard",
	Policia = "Traffic",
	Bombero = "Hose",
	Camarero = "Tray",
	Barman = "Wipe",
}
AgeMotion.JobWork = JOB_WORK

-- Lo que se lleva en brazos en cada trabajo (lo pone el servidor en el personaje)
local CARRIED = { CarriedItem = true, CarriedPlate = true, CafeTray = true, PostParcel = true }
AgeMotion.Carried = CARRIED

-- ¿Qué tarea hace ahora este jugador? (nil = ninguna)
local function workOf(body: Body): string?
	local player = body.Player
	if not player then
		return nil
	end
	for name in CARRIED do
		if body.Model:FindFirstChild(name) then
			return "Carry"
		end
	end
	local job = player:GetAttribute("Job")
	return if type(job) == "string" then JOB_WORK[job] else nil
end

-- ¿Está haciendo un gesto (saludar, bailar…)? Entonces el gesto manda sobre la tarea
local function gesturing(body: Body): boolean
	local animator = body.Humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return false
	end
	for _, track in animator:GetPlayingAnimationTracks() do
		if track.Priority == Enum.AnimationPriority.Action and track.WeightCurrent > 0.1 then
			return true
		end
	end
	return false
end

local function restore(body: Body)
	for name, joint in body.Joints do
		local written = body.Written[name]
		if written and same(joint.Transform, written) then
			joint.Transform = body.Base[name] or CFrame.identity
		end
	end
	table.clear(body.Written)
	table.clear(body.Base)
end

-- Deja de animarlo (lejos o sin cuerpo): postura de la animación y fuera los objetos de la mano
local function release(body: Body)
	restore(body)
	WorkAnim.clearProps(body.Props)
	body.WorkName = nil
	body.Work = 0
	SeaFx.clear(body.Fx)
	body.Sea = 0
	body.SeaPose = nil
end

---------------------------------------------------------------------
-- Agua y pesca
---------------------------------------------------------------------
local waterParams: RaycastParams? = nil

-- ¿Hay agua debajo? (se mira como mucho dos veces por segundo)
local function waterBelow(body: Body, position: Vector3, t: number): boolean
	if t - body.WaterAt < 0.5 then
		return body.Water
	end
	body.WaterAt = t
	if not waterParams then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { workspace.Terrain }
		params.IgnoreWater = false
		waterParams = params
	end
	local hit = workspace:Raycast(Vector3.new(position.X, SeaMotion.Surface + 14, position.Z), Vector3.new(0, -30, 0), waterParams)
	body.Water = hit ~= nil and hit.Material == Enum.Material.Water
	return body.Water
end

local function serverNow(): number
	local ok, now = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	return if ok then now else os.clock()
end

-- Nadar, bucear o pescar: postura de SeaMotion y cosas de SeaFx
local function seaPose(body: Body, t: number, dt: number, speed: number, vertical: number, sitting: boolean): { [string]: CFrame }?
	local player = body.Player
	if not player or sitting then
		SeaFx.update(body.Fx, { Model = body.Model, Player = player, State = nil, InWater = false, Underwater = false, Vertical = 0, Fishing = false })
		return nil
	end
	local position = body.Root.Position
	local head = body.Model:FindFirstChild("Head") :: BasePart?
	local inWater = position.Y < SeaMotion.Surface + 0.4 and waterBelow(body, position, t)
	local underwater = inWater and head ~= nil and head.Position.Y < SeaMotion.Surface - 0.8
	local now = serverNow()
	local spearAt = player:GetAttribute("SpearAt")
	local fish = player:GetAttribute("FishAnim")
	local fishAt = player:GetAttribute("FishAnimAt")
	local gun = player:GetAttribute("Speargun")
	body.SeaPhase = (body.SeaPhase + dt * SeaMotion.strokeRate(speed, underwater)) % (math.pi * 200)
	local pose, state = SeaMotion.pose({
		InWater = inWater,
		Underwater = underwater,
		Speed = speed,
		Vertical = vertical,
		Armed = type(gun) == "string",
		ShotAgo = if typeof(spearAt) == "number" then now - spearAt else math.huge,
		Fish = if type(fish) == "string" then fish else nil,
		FishAgo = if typeof(fishAt) == "number" then now - fishAt else 0,
		Phase = body.SeaPhase,
		Seed = body.Seed,
	}, t)
	local gear = player:GetAttribute("DiveGear")
	local fishId = player:GetAttribute("FishAnimFish")
	SeaFx.update(body.Fx, {
		Model = body.Model,
		Player = player,
		State = state,
		InWater = inWater,
		Underwater = underwater,
		Vertical = vertical,
		Fishing = type(fish) == "string" and fish ~= "Reel",
		FishId = if type(fishId) == "string" then fishId else nil,
		Gun = if type(gun) == "string" then gun else nil,
		Gear = if type(gear) == "string" then gear else nil,
	})
	return pose
end

local function update(body: Body, t: number, dt: number)
	local stage, crawling = stageOf(body)
	local style = AgeMotion.style(stage)
	local sitting = busy(body)
	if stage ~= body.StageName then
		body.StageName = stage
		body.Drop = nil -- ha cambiado de tamaño
	end

	-- Velocidad (con física o, si está anclado, por cuánto avanza)
	local position = body.Root.Position
	local speed = 0
	if body.Root.Anchored then
		if body.LastPos and dt > 0 then
			speed = Vector3.new(position.X - body.LastPos.X, 0, position.Z - body.LastPos.Z).Magnitude / dt
		end
	else
		local v = body.Root.AssemblyLinearVelocity
		speed = Vector3.new(v.X, 0, v.Z).Magnitude
	end
	body.LastPos = position
	local vertical = 0
	if body.LastY and dt > 0 then
		vertical = (position.Y - body.LastY) / dt
	end
	body.LastY = position.Y
	speed = math.min(speed, 30)
	body.Move = smooth(body.Move, if speed > 0.6 then 1 else 0, 6, dt)
	-- El paso va con la velocidad y el tamaño (un bebé da pasos cortos): andando normal, un paso
	-- completo (izquierdo y derecho) por segundo; gateando, algo más seguido
	local scale = math.max(0.3, body.Model:GetScale())
	local rate = speed * 0.4 / scale * (if crawling then 1.4 else 1)
	body.Phase = (body.Phase + dt * rate) % (math.pi * 2)

	body.Crawl = smooth(body.Crawl, if crawling and not sitting then 1 else 0, 5, dt)
	body.Style = smooth(body.Style, if style and not sitting then 1 else 0, 4, dt)
	-- Su oficio (jugadores): quieto en su puesto, o llevando algo (también andando)
	local workName = workOf(body)
	local work = WorkAnim.get(workName)
	if workName ~= body.WorkName then
		body.WorkName = workName
		WorkAnim.clearProps(body.Props)
		if work then
			body.Props = WorkAnim.makeProps(body.Model, work)
		end
	end
	local working = work ~= nil
		and not sitting
		and not crawling
		and (body.Move < 0.3 or work.Walk == true)
		and not gesturing(body)
	body.Work = smooth(body.Work, if working then 1 else 0, if working then 3 else 7, dt)
	local W = body.Work
	local w = body.WorkPose
	WorkAnim.clear(w)
	if work and W > 0.001 then
		work.Pose(t, body.Seed, w)
	end
	WorkAnim.showProps(body.Props, W > 0.5)

	-- Nadar, bucear o pescar
	local sea = seaPose(body, t, dt, speed, math.clamp(vertical, -30, 30), sitting)
	if sea then
		body.SeaPose = sea
	end
	body.Sea = smooth(body.Sea, if sea then 1 else 0, if sea then 8 else 5, dt)
	local seaTarget = if body.Sea > 0.001 then body.SeaPose else nil

	if body.Crawl < 0.001 and body.Style < 0.001 and W < 0.001 and not seaTarget then
		restore(body)
		return
	end
	-- La tarea, como retoque de cada articulación (los mismos ángulos que usa ActorLife en C0)
	local workOffsets: { [string]: CFrame }? = nil
	if W > 0.001 then
		workOffsets = {
			Neck = angles(w.np * W, w.ny * W, w.nr * W),
			Waist = angles(w.wp * W, w.wy * W, w.wr * W),
			RightShoulder = angles(w.rx * W, w.rt * W, w.rz * W),
			LeftShoulder = angles(w.lx * W, -w.lt * W, -w.lz * W),
			RightElbow = angles(w.re * W, 0, 0),
			LeftElbow = angles(w.le * W, 0, 0),
		}
	end

	local offsets = if style and body.Style > 0.001 then style.Offsets(t, body.Move, body.Phase) else nil
	local crawl = if body.Crawl > 0.001 then AgeMotion.crawlPose(body.Move, body.Phase, crawlDrop(body)) else nil
	for name, joint in body.Joints do
		local current = joint.Transform
		local written = body.Written[name]
		if written and same(current, written) then
			-- La animación no lo ha tocado este frame: partimos de lo que había debajo
			current = body.Base[name] or CFrame.identity
		end
		body.Base[name] = current
		local out = current
		if style and body.Style > 0.001 then
			local k = if ARMS[name] then style.Arms elseif LEGS[name] then style.Legs else 1
			k = 1 + (k - 1) * body.Style
			out = scaled(out, k)
			local offset = offsets and offsets[name]
			if offset then
				out = CFrame.identity:Lerp(offset, body.Style) * out
			end
		end
		if workOffsets then
			-- Con las manos ocupadas, los brazos dejan de balancearse al andar
			if ARMS[name] then
				out = scaled(out, 1 - W)
			end
			local offset = workOffsets[name]
			if offset then
				out = offset * out
			end
		end
		if crawl then
			out = out:Lerp(crawl[name] or out, body.Crawl)
		end
		local target = seaTarget and seaTarget[name]
		if target then
			out = out:Lerp(target, body.Sea)
		end
		joint.Transform = out
		body.Written[name] = out
	end
end

function AgeMotion.init()
	local function consider(instance: Instance)
		if instance:IsA("Humanoid") then
			local model = instance.Parent
			if model and model:IsA("Model") then
				task.delay(0.5, function()
					if model.Parent then
						register(model)
					end
				end)
			end
		end
	end
	for _, descendant in workspace:GetDescendants() do
		consider(descendant)
	end
	workspace.DescendantAdded:Connect(consider)

	-- Quién está cerca (cada medio segundo): jugadores y personajes con edad
	task.spawn(function()
		while true do
			task.wait(0.5)
			local camera = workspace.CurrentCamera
			local from = camera and camera.CFrame.Position or Vector3.zero
			local list = {}
			for model, body in bodies do
				if not model.Parent or not body.Root.Parent then
					bodies[model] = nil
					continue
				end
				if body.Player == nil and model:GetAttribute("Age") == nil and model:GetAttribute("Crawling") == nil then
					continue
				end
				local distance = (body.Root.Position - from).Magnitude
				if distance < ACTIVE_DISTANCE then
					table.insert(list, { Body = body, Distance = distance })
				end
			end
			table.sort(list, function(a, b)
				return a.Distance < b.Distance
			end)
			local nextActive, keep = {}, {}
			for i, entry in list do
				if i > MAX_ACTIVE then
					break
				end
				table.insert(nextActive, entry.Body)
				keep[entry.Body] = true
			end
			for _, body in active do
				if not keep[body] and body.Active then
					body.Active = false
					pcall(release, body)
				end
			end
			for _, body in nextActive do
				if not body.Active then
					body.Active = true
					findJoints(body)
					body.Drop = nil
				end
			end
			active = nextActive
		end
	end)

	-- Después de que Roblox anime y antes de dibujar
	local signal = (RunService :: any).PreSimulation or RunService.Stepped
	signal:Connect(function(a, b)
		local dt = if typeof(b) == "number" then b else a -- Stepped da (tiempo, dt)
		local t = os.clock()
		for _, body in active do
			if body.Active and body.Model.Parent then
				local ok, err = pcall(update, body, t, dt)
				if not ok then
					warn("[AgeMotion] " .. tostring(err))
					body.Active = false
					pcall(release, body)
					bodies[body.Model] = nil -- no se vuelve a intentar con este
				end
			end
		end
	end)

	-- Tu personaje nuevo (al reaparecer o al crecer) y los de los demás
	local function watch(player: Player)
		player.CharacterAdded:Connect(function(character)
			task.delay(1, function()
				if character.Parent then
					register(character)
				end
			end)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
end

return AgeMotion
