-- GymPoses (cliente): las posturas de cada ejercicio del gimnasio, hechas con código (R15).
--
-- Cada ejercicio tiene:
--   Pose(t, ctx)  -> { [articulación] = CFrame }: el Motor6D.Transform de todo el cuerpo en el
--                    momento t (0..1 del ciclo). GymMotion lo mezcla con la animación normal.
--   Load(t)       -> 0..1: cuánto va "cargada" la máquina (pesas arriba, plataforma empujada…):
--                    lo usa GymMotion para mover las piezas de la máquina a la vez que el cuerpo.
--   Loop          -> cardio que no para (cinta, bici…). Si no, cada repetición es un ciclo entero
--                    que empieza y acaba en la postura de reposo (t = 0 y t = 1 son iguales).
--   Period        -> segundos que dura un ciclo
--   Props         -> cosas en las manos (mancuernas, guantes, comba), solo en tu pantalla
--
-- ctx = { Lift = altura de la raíz sobre el suelo de pie (HipHeight + media raíz), Scale = tamaño
-- del cuerpo (1 = R15 normal), Geo = medidas de la máquina (Shared/Gym: altura del asiento…) }.
--
-- Ángulos (la convención de AgeMotion/ReactMotion):
--   Root        x < 0 el cuerpo se inclina hacia delante; x = +π/2 tumbado boca arriba (cabeza atrás)
--   Waist/Neck  x > 0 hacia atrás, y > 0 gira a su izquierda, z inclina de lado
--   Shoulder    x > 0 brazo hacia delante/arriba, z abre el brazo (derecho +, izquierdo -)
--   Elbow       x > 0 dobla el brazo
--   Hip         x > 0 pierna hacia delante;  Knee x < 0 dobla la rodilla;  Ankle x > 0 punta arriba
--
-- Funciones puras: se prueban fuera de Roblox (scripts/test-gym.luau).

local GymPoses = {}

local sin, cos, pi = math.sin, math.cos, math.pi
local A = CFrame.Angles
local TAU = pi * 2

GymPoses.Joints = {
	"Root", "Waist", "Neck",
	"RightShoulder", "LeftShoulder", "RightElbow", "LeftElbow", "RightWrist", "LeftWrist",
	"RightHip", "LeftHip", "RightKnee", "LeftKnee", "RightAnkle", "LeftAnkle",
}

-- Medidas del R15 normal (tamaño 1) que hacen falta para colocar el cuerpo
local THIGH = 0.82 -- de la cadera a la rodilla
local SHIN = 0.9 -- de la rodilla al tobillo
local HALF_DEPTH = 0.5 -- medio grosor del muslo y de la espalda
local REACH = 3.5 -- de la cadera a las manos con los brazos estirados hacia arriba

export type Ctx = { Lift: number, Scale: number, Geo: { [string]: number } }
export type Pose = { [string]: CFrame }
export type PropPart = {
	Name: string,
	Hand: "Right" | "Left",
	Size: Vector3,
	Offset: CFrame,
	Color: Color3,
	Material: Enum.Material?,
	Shape: Enum.PartType?,
}
export type Kind = {
	Loop: boolean,
	Period: number,
	Pose: (t: number, ctx: Ctx) -> Pose,
	Load: (t: number) -> number,
	Props: { PropPart }?,
}

---------------------------------------------------------------------
-- Ayudas
---------------------------------------------------------------------

-- Subida y bajada suave (0 → 1)
function GymPoses.ease(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end
local ease = GymPoses.ease

local function mix(a: number, b: number, w: number): number
	return a + (b - a) * w
end

-- 0 → 1 → 0 a lo largo del ciclo (una repetición): empieza y acaba en reposo
local function bell(t: number): number
	return 0.5 - 0.5 * cos(TAU * t)
end
GymPoses.bell = bell

-- Repetición con la subida en `up` (fracción del ciclo) y la bajada más lenta
local function stroke(t: number, up: number): number
	t = t % 1
	if t < up then
		return ease(t / up)
	end
	return 1 - ease((t - up) / (1 - up))
end
GymPoses.stroke = stroke

-- Brazo derecho y su espejo izquierdo
local function arms(p: Pose, x: number, y: number, z: number, e: number)
	p.RightShoulder = A(x, y, z)
	p.LeftShoulder = A(x, -y, -z)
	p.RightElbow = A(e, 0, 0)
	p.LeftElbow = A(e, 0, 0)
end

local function legs(p: Pose, hip: number, knee: number, ankle: number?)
	p.RightHip = A(hip, 0, 0)
	p.LeftHip = A(hip, 0, 0)
	p.RightKnee = A(knee, 0, 0)
	p.LeftKnee = A(knee, 0, 0)
	p.RightAnkle = A(ankle or 0, 0, 0)
	p.LeftAnkle = A(ankle or 0, 0, 0)
end

-- Postura completa en reposo (todas las articulaciones), para que ninguna quede sin escribir
local function base(): Pose
	local p: Pose = {}
	for _, name in GymPoses.Joints do
		p[name] = CFrame.identity
	end
	return p
end

-- Sentado en un asiento a `seat` studs del suelo: cuánto baja la raíz
local function seatDrop(ctx: Ctx, seat: number): number
	return seat + HALF_DEPTH * ctx.Scale - ctx.Lift
end
GymPoses.seatDrop = seatDrop

-- Con las piernas dobladas (ángulo del muslo y de la espinilla respecto a la vertical, hacia
-- delante > 0): cuánto baja la cadera y cuánto va hacia atrás para que los pies no se muevan
function GymPoses.plant(thigh: number, shin: number, scale: number): (number, number)
	local down = THIGH * cos(thigh) + SHIN * cos(shin)
	local forward = THIGH * sin(thigh) + SHIN * sin(shin)
	return (down - THIGH - SHIN) * scale, forward * scale
end
local plant = GymPoses.plant

-- Sentado recto (muslos horizontales, espinillas hacia abajo)
local function sitting(p: Pose, ctx: Ctx, seat: number)
	p.Root = CFrame.new(0, seatDrop(ctx, seat), 0)
	legs(p, pi / 2, -pi / 2)
end

-- Tumbado boca arriba sobre algo a `top` studs del suelo (la cabeza hacia atrás)
local function lying(p: Pose, ctx: Ctx, top: number)
	p.Root = CFrame.new(0, top + HALF_DEPTH * ctx.Scale - ctx.Lift, 0) * A(pi / 2, 0, 0)
end

---------------------------------------------------------------------
-- Ejercicios
---------------------------------------------------------------------
local kinds: { [string]: Kind } = {}

-- Cinta de correr: carrera con los brazos doblados, rebote y algo inclinado hacia delante
kinds.Cinta = {
	Loop = true,
	Period = 0.72,
	Load = function(t)
		return t
	end,
	Pose = function(t, ctx)
		local p = base()
		local a = TAU * t
		local s = sin(a)
		local bounce = 0.07 * ctx.Scale * (0.5 + 0.5 * cos(2 * a))
		p.Root = CFrame.new(0, (ctx.Geo.Belt or 0) + bounce, 0) * A(-0.12, 0, 0)
		p.Waist = A(0, 0.14 * s, 0)
		p.Neck = A(0.1, -0.14 * s, 0)
		p.RightHip = A(0.12 + 0.65 * s, 0, 0)
		p.LeftHip = A(0.12 - 0.65 * s, 0, 0)
		p.RightKnee = A(-(0.3 + 0.55 * (1 - s)), 0, 0)
		p.LeftKnee = A(-(0.3 + 0.55 * (1 + s)), 0, 0)
		p.RightAnkle = A(0.15 * s, 0, 0)
		p.LeftAnkle = A(-0.15 * s, 0, 0)
		p.RightShoulder = A(-0.6 * s, 0, 0.1)
		p.LeftShoulder = A(0.6 * s, 0, -0.1)
		p.RightElbow = A(1.45, 0, 0)
		p.LeftElbow = A(1.45, 0, 0)
		return p
	end,
}

-- Bicicleta estática: sentado en el sillín, inclinado a por el manillar y pedaleando
kinds.Bici = {
	Loop = true,
	Period = 1.0,
	Load = function(t)
		return t
	end,
	Pose = function(t, ctx)
		local p = base()
		local a = TAU * t
		p.Root = CFrame.new(0, seatDrop(ctx, ctx.Geo.Seat or 1.75), 0)
		p.Waist = A(-0.38, 0, 0)
		p.Neck = A(0.32, 0, 0)
		arms(p, 1.2, 0, 0.08, 0.35)
		for side, phase in { Right = 0, Left = pi } do
			local s = sin(a + phase)
			p[side .. "Hip"] = A(1.05 + 0.42 * s, 0, 0)
			p[side .. "Knee"] = A(-(0.85 + 0.75 * (0.5 + 0.5 * s)), 0, 0)
			p[side .. "Ankle"] = A(0.25 - 0.15 * s, 0, 0)
		end
		return p
	end,
}

-- Elíptica: de pie en los pedales, piernas en óvalo y los brazos empujando las manetas
kinds.Eliptica = {
	Loop = true,
	Period = 1.2,
	Load = function(t)
		return t
	end,
	Pose = function(t, ctx)
		local p = base()
		local a = TAU * t
		local s, c = sin(a), cos(a)
		p.Root = CFrame.new(0, (ctx.Geo.Pedal or 0.7) + 0.06 * ctx.Scale * c, 0) * A(-0.06, 0, 0)
		p.Waist = A(0, 0.08 * s, 0)
		p.RightHip = A(0.12 + 0.3 * s, 0, 0)
		p.LeftHip = A(0.12 - 0.3 * s, 0, 0)
		p.RightKnee = A(-(0.2 + 0.25 * (1 + c)), 0, 0)
		p.LeftKnee = A(-(0.2 + 0.25 * (1 - c)), 0, 0)
		p.RightShoulder = A(0.55 - 0.35 * s, 0, 0.1)
		p.LeftShoulder = A(0.55 + 0.35 * s, 0, -0.1)
		p.RightElbow = A(1.1 + 0.35 * s, 0, 0)
		p.LeftElbow = A(1.1 - 0.35 * s, 0, 0)
		return p
	end,
}

-- Remo: tirón de piernas, espalda hacia atrás y brazos al pecho; vuelta despacio hacia delante
local function rowDrive(t: number): number
	return stroke(t, 0.4)
end
kinds.Remo = {
	Loop = true,
	Period = 2.0,
	Load = rowDrive,
	Pose = function(t, ctx)
		local p = base()
		local d = rowDrive(t)
		p.Root = CFrame.new(0, seatDrop(ctx, ctx.Geo.Seat or 0.9), 1.1 * ctx.Scale * d)
		p.Waist = A(mix(-0.4, 0.28, d), 0, 0)
		p.Neck = A(mix(0.3, -0.15, d), 0, 0)
		legs(p, mix(2.2, 1.5, d), mix(-2.2, -0.12, d), mix(0.5, -0.1, d))
		arms(p, mix(1.55, 0.2, d), 0, mix(0.05, 0.35, d), mix(0.05, 1.9, d))
		return p
	end,
}

-- Press de banca: tumbado, baja la barra al pecho y la sube (reposo: brazos estirados)
kinds.PressBanca = {
	Loop = false,
	Period = 1.6,
	Load = bell,
	Pose = function(t, ctx)
		local p = base()
		local l = bell(t)
		lying(p, ctx, ctx.Geo.Bench or 1.5)
		p.Neck = A(-0.15, 0, 0)
		legs(p, 0.25, -1.8, 0.3)
		p.RightHip = A(0.25, 0, 0.18)
		p.LeftHip = A(0.25, 0, -0.18)
		arms(p, mix(1.57, 0.85, l), 0, mix(0.22, 0.95, l), mix(0.05, 1.7, l))
		return p
	end,
}

-- Press de hombros (máquina): sentado, de las orejas a arriba del todo
kinds.PressHombros = {
	Loop = false,
	Period = 1.5,
	Load = bell,
	Pose = function(t, ctx)
		local p = base()
		local l = bell(t)
		sitting(p, ctx, ctx.Geo.Seat or 1.35)
		p.Waist = A(0.06, 0, 0)
		arms(p, mix(1.5, 2.95, l), 0, mix(0.45, 0.15, l), mix(1.55, 0.1, l))
		return p
	end,
}

-- Jalón al pecho: sentado, brazos arriba cogiendo la barra y tirando hasta el pecho
kinds.Jalon = {
	Loop = false,
	Period = 1.5,
	Load = bell,
	Pose = function(t, ctx)
		local p = base()
		local l = bell(t)
		sitting(p, ctx, ctx.Geo.Seat or 1.35)
		p.Waist = A(0.18 * l, 0, 0)
		p.Neck = A(0.2 - 0.15 * l, 0, 0)
		arms(p, mix(2.95, 1.0, l), 0, mix(0.35, 0.95, l), mix(0.15, 2.0, l))
		return p
	end,
}

-- Prensa de piernas: recostado y empujando la plataforma con las piernas
local RECLINE = 0.8
kinds.Prensa = {
	Loop = false,
	Period = 1.7,
	Load = bell,
	Pose = function(t, ctx)
		local p = base()
		local l = bell(t)
		p.Root = CFrame.new(0, seatDrop(ctx, ctx.Geo.Seat or 1.3), 0) * A(RECLINE, 0, 0)
		p.Neck = A(-0.45, 0, 0)
		legs(p, mix(2.05, 1.3, l), mix(-1.9, -0.12, l), mix(0.35, 0.05, l))
		arms(p, 0.35, 0, 0.3, 0.9)
		return p
	end,
}

-- Sentadilla con barra: la barra en los hombros; baja con la espalda recta y los pies quietos
kinds.Sentadilla = {
	Loop = false,
	Period = 1.8,
	Load = bell,
	Pose = function(t, ctx)
		local p = base()
		local l = bell(t)
		local lean = -0.45 * l
		local thigh = 1.5 * l -- ángulo del muslo respecto a la vertical
		local shin = -0.45 * l
		local dy, dz = plant(thigh, shin, ctx.Scale)
		p.Root = CFrame.new(0, dy, dz) * A(lean, 0, 0)
		p.Waist = A(-0.05 * l, 0, 0)
		p.Neck = A(0.35 * l, 0, 0)
		p.RightHip = A(thigh - lean, 0, 0.12 * l)
		p.LeftHip = A(thigh - lean, 0, -0.12 * l)
		p.RightKnee = A(shin - thigh, 0, 0)
		p.LeftKnee = A(shin - thigh, 0, 0)
		local foot = -(lean + (thigh - lean) + (shin - thigh)) -- pies planos en el suelo
		p.RightAnkle = A(foot, 0, 0)
		p.LeftAnkle = A(foot, 0, 0)
		arms(p, 0.35, 0, 1.25, 1.95) -- manos en la barra, detrás del cuello
		return p
	end,
}

-- Mancuernas: sentado en el banco, curl de bíceps alternando brazos
kinds.Mancuernas = {
	Loop = false,
	Period = 2.0,
	Load = bell,
	Pose = function(t, ctx)
		local p = base()
		sitting(p, ctx, ctx.Geo.Seat or 1.35)
		local right = if t < 0.5 then bell(t * 2) else 0
		local left = if t >= 0.5 then bell(t * 2 - 1) else 0
		p.RightShoulder = A(0.12 + 0.15 * right, 0, 0.1)
		p.LeftShoulder = A(0.12 + 0.15 * left, 0, -0.1)
		p.RightElbow = A(0.2 + 2.0 * right, 0, 0)
		p.LeftElbow = A(0.2 + 2.0 * left, 0, 0)
		p.Neck = A(-0.1, 0.12 * (left - right), 0)
		return p
	end,
	Props = {
		{ Name = "MancuernaD", Hand = "Right", Size = Vector3.new(1.3, 0.34, 0.34), Offset = CFrame.new(0, -0.1, 0), Color = Color3.fromRGB(40, 40, 44), Material = Enum.Material.Metal, Shape = Enum.PartType.Cylinder },
		{ Name = "MancuernaI", Hand = "Left", Size = Vector3.new(1.3, 0.34, 0.34), Offset = CFrame.new(0, -0.1, 0), Color = Color3.fromRGB(40, 40, 44), Material = Enum.Material.Metal, Shape = Enum.PartType.Cylinder },
	},
}

-- Dominadas: colgado de la barra, sube hasta la barbilla y baja despacio
kinds.Dominadas = {
	Loop = false,
	Period = 1.8,
	Load = function(t)
		return stroke(t, 0.4)
	end,
	Pose = function(t, ctx)
		local p = base()
		local l = stroke(t, 0.4)
		local hang = (ctx.Geo.Bar or 7.4) - REACH * ctx.Scale - ctx.Lift
		p.Root = CFrame.new(0, hang + 1.15 * ctx.Scale * l, 0)
		p.Neck = A(0.25 * l, 0, 0)
		arms(p, mix(3.05, 2.2, l), 0, mix(0.3, 0.75, l), mix(0.08, 2.1, l))
		legs(p, 0.3, -0.7, 0.3)
		return p
	end,
}

-- Saco de boxeo: en guardia, directo con la derecha y con la izquierda
local function punch(t: number): (number, number)
	local right = if t < 0.5 then stroke(t * 2, 0.35) else 0
	local left = if t >= 0.5 then stroke(t * 2 - 1, 0.35) else 0
	return right, left
end
kinds.Saco = {
	Loop = true,
	Period = 1.1,
	Load = function(t)
		local right, left = punch(t)
		return right - left -- el saco se va hacia atrás con cada golpe (y al otro lado con el otro)
	end,
	Pose = function(t, ctx)
		local p = base()
		local right, left = punch(t)
		local bob = 0.05 * ctx.Scale * sin(TAU * t * 2)
		local dy, dz = plant(0.12, -0.12, ctx.Scale)
		p.Root = CFrame.new(0, dy + bob, dz)
		p.Waist = A(-0.05, 0.3 * (left - right), 0)
		p.Neck = A(0.05, -0.2 * (left - right), 0)
		p.RightHip = A(-0.05, 0, 0.05)
		p.LeftHip = A(0.3, 0, -0.05)
		p.RightKnee = A(-0.35, 0, 0)
		p.LeftKnee = A(-0.35, 0, 0)
		p.RightShoulder = A(mix(1.0, 1.55, right), 0, mix(0.15, 0.05, right))
		p.LeftShoulder = A(mix(1.0, 1.55, left), 0, mix(-0.15, -0.05, left))
		p.RightElbow = A(mix(1.9, 0.1, right), 0, 0)
		p.LeftElbow = A(mix(1.9, 0.1, left), 0, 0)
		return p
	end,
	Props = {
		{ Name = "GuanteD", Hand = "Right", Size = Vector3.new(0.75, 0.75, 0.75), Offset = CFrame.new(0, -0.1, 0), Color = Color3.fromRGB(200, 30, 36), Shape = Enum.PartType.Ball },
		{ Name = "GuanteI", Hand = "Left", Size = Vector3.new(0.75, 0.75, 0.75), Offset = CFrame.new(0, -0.1, 0), Color = Color3.fromRGB(200, 30, 36), Shape = Enum.PartType.Ball },
	},
}

-- Abdominales: tumbado en la esterilla con las rodillas dobladas, sube el tronco y vuelve
kinds.Abdominales = {
	Loop = false,
	Period = 1.4,
	Load = bell,
	Pose = function(t, ctx)
		local p = base()
		local l = bell(t)
		lying(p, ctx, ctx.Geo.Mat or 0.12)
		p.Waist = A(-0.75 * l, 0, 0)
		p.Neck = A(-0.35 * l, 0, 0)
		legs(p, 0.95, -1.75, 0.45)
		arms(p, 2.55, 0, 0.7, 2.3) -- manos detrás de la cabeza
		return p
	end,
}

-- Yoga: de pie en la esterilla, brazos arriba estirando de un lado al otro, respirando despacio
kinds.Yoga = {
	Loop = true,
	Period = 6.0,
	Load = function(t)
		return bell(t)
	end,
	Pose = function(t, ctx)
		local p = base()
		local a = TAU * t
		local side = sin(a)
		local breath = 0.5 - 0.5 * cos(2 * a)
		p.Root = CFrame.new(0, ctx.Geo.Mat or 0.12, 0)
		p.Waist = A(0.05 * breath, 0, 0.32 * side)
		p.Neck = A(0.1, 0, -0.15 * side)
		p.RightShoulder = A(2.9 - 0.1 * breath, 0, 0.25 - 0.15 * side)
		p.LeftShoulder = A(2.9 - 0.1 * breath, 0, -0.25 - 0.15 * side)
		p.RightElbow = A(0.15, 0, 0)
		p.LeftElbow = A(0.15, 0, 0)
		p.RightHip = A(0, 0, 0.06)
		p.LeftHip = A(0, 0, -0.06)
		return p
	end,
}

-- Comba: saltitos con los codos pegados y las muñecas dando vueltas (la cuerda pasa bajo los pies
-- justo cuando está en el aire: t = 0.5)
function GymPoses.ropeAngle(t: number): number
	return TAU * t -- 0 = por encima de la cabeza, π = bajo los pies
end
kinds.Comba = {
	Loop = true,
	Period = 0.6,
	Load = function(t)
		return t
	end,
	Pose = function(t, ctx)
		local p = base()
		local a = TAU * t
		local air = 0.5 - 0.5 * cos(a) -- 0 en el suelo, 1 arriba (t = 0.5)
		local land = 1 - air
		local dy, dz = plant(0.25 * land, -0.25 * land, ctx.Scale)
		p.Root = CFrame.new(0, dy + 0.35 * ctx.Scale * air, dz)
		p.RightHip = A(0.25 * land, 0, 0)
		p.LeftHip = A(0.25 * land, 0, 0)
		p.RightKnee = A(-0.5 * land, 0, 0)
		p.LeftKnee = A(-0.5 * land, 0, 0)
		p.RightAnkle = A(0.25 * land - 0.3 * air, 0, 0)
		p.LeftAnkle = A(0.25 * land - 0.3 * air, 0, 0)
		p.RightShoulder = A(0.25, 0, 0.35)
		p.LeftShoulder = A(0.25, 0, -0.35)
		p.RightElbow = A(0.9, 0, 0)
		p.LeftElbow = A(0.9, 0, 0)
		p.RightWrist = A(0.35 * sin(a), 0, 0.3 * cos(a))
		p.LeftWrist = A(0.35 * sin(a), 0, -0.3 * cos(a))
		return p
	end,
	Props = {
		{ Name = "MangoD", Hand = "Right", Size = Vector3.new(0.22, 0.7, 0.22), Offset = CFrame.new(0, -0.15, 0), Color = Color3.fromRGB(240, 170, 40) },
		{ Name = "MangoI", Hand = "Left", Size = Vector3.new(0.22, 0.7, 0.22), Offset = CFrame.new(0, -0.15, 0), Color = Color3.fromRGB(240, 170, 40) },
	},
}

GymPoses.Kinds = kinds

function GymPoses.get(kind: any): Kind?
	if type(kind) ~= "string" then
		return nil
	end
	return kinds[kind]
end

-- Mezcla la postura del ejercicio con lo que puso la animación (w = 0: la animación; 1: el ejercicio)
function GymPoses.blend(current: CFrame, target: CFrame, w: number): CFrame
	if w <= 0 then
		return current
	elseif w >= 1 then
		return target
	end
	return current:Lerp(target, w)
end

-- Peso de la mezcla al empezar y al terminar: entra y sale suave en `seconds`
function GymPoses.weight(current: number, want: number, dt: number, seconds: number): number
	local step = dt / math.max(seconds, 1e-3)
	if want > current then
		return math.min(want, current + step)
	end
	return math.max(want, current - step)
end

return GymPoses
