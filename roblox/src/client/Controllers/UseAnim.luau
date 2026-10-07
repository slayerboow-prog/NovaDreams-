-- UseAnim (cliente): posturas al usar los muebles de dentro de los edificios (InteractService).
--
-- El servidor pone al jugador el atributo UsePose y UseMotion mueve su cuerpo con estas posturas,
-- encima de las animaciones de Roblox (capa de PoseLayers). Todo con código, sin animaciones subidas.
--
--   Sit     sentado en una silla: manos en el regazo, respira y mira alrededor
--   Sofa    en el sofá o un sillón: recostado hacia atrás, brazos sueltos
--   Lie     tumbado en la cama boca arriba (el servidor tumba el cuerpo): piernas estiradas,
--           brazos a los lados, la cabeza en la almohada; dormido, la cabeza ladeada
--   Tap     en el grifo: inclinado, las manos bajo el agua frotándose
--   Fridge  abrir la nevera: tira de la puerta, se asoma, coge algo y se lo lleva a la boca
--   Shower  en la ducha: brazos arriba lavándose el pelo
--   Type    sentado al ordenador: manos en el teclado, tecleando, mirando la pantalla
--   Piano   sentado al piano: manos sobre las teclas, moviéndose por el teclado al ritmo
--   Window  asomado a la ventana: manos en el alféizar, mirando a un lado y a otro
--
-- Cada postura es una función pura pose(u, seed, sleeping) -> { Set, Add }:
--   Set  transformación de la articulación que manda (se mezcla hacia ella con el peso)
--   Add  retoque que se suma encima de lo que haya (la animación o las otras capas)
-- u = segundos desde que empezó. Ángulos como en WorkAnim/AgeMotion: hombro x > 0 levanta el brazo
-- hacia delante, z > 0 lo abre (el izquierdo con el signo cambiado), codo > 0 dobla, rodilla < 0
-- dobla, cintura x < 0 se inclina hacia delante, cuello x < 0 mira abajo.
-- Se prueba fuera de Roblox: scripts/test-interiors.luau

local UseAnim = {}

export type Pose = { Set: { [string]: CFrame }?, Add: { [string]: CFrame }? }

local sin, clamp = math.sin, math.clamp
local angles = CFrame.Angles

UseAnim.BlendIn = 0.45 -- segundos para entrar en la postura
UseAnim.BlendOut = 0.35 -- y para salir

-- Suave al entrar y al salir (sin tirones: la velocidad empieza y acaba en 0)
function UseAnim.ease(x: number): number
	local t = clamp(x, 0, 1)
	return t * t * t * (t * (t * 6 - 15) + 10)
end

-- 0 → 1 entre a y a + len (suave)
local function ramp(u: number, a: number, len: number): number
	return UseAnim.ease((u - a) / len)
end

-- Brazos: hombro (adelante, giro hacia dentro, abrir) y codo, con el lado izquierdo en espejo
local function arms(set: { [string]: CFrame }, rx: number, ry: number, rz: number, re: number, lx: number, ly: number, lz: number, le: number)
	set.RightShoulder = angles(rx, ry, rz)
	set.LeftShoulder = angles(lx, -ly, -lz)
	set.RightElbow = angles(re, 0, 0)
	set.LeftElbow = angles(le, 0, 0)
end

local POSES: { [string]: (number, number, boolean?) -> Pose } = {}

POSES.Sit = function(u, seed)
	local breathe = sin(u * 1.7 + seed) * 0.015
	local look = sin(u * 0.23 + seed * 2) * 0.35
	local set = {}
	arms(set, 0.3, 0.35, -0.05, 0.7, 0.3, 0.35, -0.05, 0.7)
	return {
		Set = set,
		Add = {
			Waist = angles(breathe, look * 0.2, 0),
			Neck = angles(-0.05 + breathe, look * 0.6, 0),
		},
	}
end

POSES.Sofa = function(u, seed)
	local breathe = sin(u * 1.4 + seed) * 0.02
	local look = sin(u * 0.17 + seed) * 0.25
	local set = {}
	arms(set, 0.15, 0.1, 0.32, 0.45, 0.2, 0.3, 0.1, 0.6)
	return {
		Set = set,
		Add = {
			Root = angles(0.1, 0, 0),
			Waist = angles(0.16 + breathe, look * 0.2, 0),
			Neck = angles(-0.18, look * 0.5, 0),
		},
	}
end

POSES.Lie = function(u, seed, sleeping)
	local breathe = sin(u * (if sleeping then 1.1 else 1.6) + seed) * 0.025
	local side = if sleeping then 0.45 else sin(u * 0.2 + seed) * 0.25
	local set = {
		Root = CFrame.identity,
		Waist = angles(breathe, 0, 0),
		Neck = angles(-0.3, side, 0),
		RightHip = angles(0.02, 0, 0.04),
		LeftHip = angles(0.02, 0, -0.04),
		RightKnee = angles(-0.1, 0, 0),
		LeftKnee = angles(-0.1, 0, 0),
		RightAnkle = angles(0.25, 0, 0),
		LeftAnkle = angles(0.25, 0, 0),
		RightWrist = CFrame.identity,
		LeftWrist = CFrame.identity,
	}
	if sleeping then
		-- Una mano sobre la tripa
		arms(set, 0.2, 1, -0.4, 1.2, 0.05, 0, 0.18, 0.3)
	else
		arms(set, 0.05, 0, 0.2, 0.25, 0.05, 0, 0.2, 0.25)
	end
	return { Set = set }
end

POSES.Tap = function(u, seed)
	local rub = sin(u * 9 + seed)
	local set = {}
	arms(set, 0.8, 0.45 + rub * 0.1, -0.12, 0.6 + rub * 0.08, 0.8, 0.45 - rub * 0.1, -0.12, 0.6 - rub * 0.08)
	return {
		Set = set,
		Add = {
			Waist = angles(-0.22, 0, 0),
			Neck = angles(-0.38, 0, 0),
		},
	}
end

POSES.Fridge = function(u, seed)
	-- 0–0,6 s alarga la mano a la puerta; 0,6–1,1 tira (el brazo se abre); 1,1–1,9 se asoma y
	-- mete la otra mano; 1,9–2,6 se lleva lo que ha cogido a la boca
	local reach = ramp(u, 0, 0.6)
	local pull = ramp(u, 0.6, 0.5)
	local peek = ramp(u, 1.1, 0.6) * (1 - ramp(u, 2.1, 0.5))
	local grab = ramp(u, 1.2, 0.6)
	local eat = ramp(u, 1.9, 0.5)
	local set = {}
	local rx = 1.1 * reach - 0.4 * pull
	local rz = 0.55 * pull
	local lx = 1.25 * grab * (1 - eat) + 1.5 * eat
	local le = 0.3 * grab * (1 - eat) + 1.6 * eat
	arms(set, rx, 0.15 * reach, rz, 0.35 * reach, lx, 0.2 + 0.8 * eat, -0.05 - 0.35 * eat, le)
	return {
		Set = set,
		Add = {
			Waist = angles(-0.2 * peek, 0.12 * pull, 0),
			Neck = angles(-0.25 * peek + 0.05 * eat, 0.1 * pull + sin(u * 3 + seed) * 0.03, 0),
		},
	}
end

POSES.Shower = function(u, seed)
	local scrub = sin(u * 7 + seed)
	local scrub2 = sin(u * 7 + seed + 1.3)
	local set = {}
	arms(set, 2.55 + scrub * 0.12, 0.35, 0.5, 1.95 + scrub2 * 0.15, 2.55 - scrub * 0.12, 0.35, 0.5, 1.95 - scrub2 * 0.15)
	return {
		Set = set,
		Add = {
			Waist = angles(0.04, sin(u * 0.9 + seed) * 0.12, 0),
			Neck = angles(0.28, sin(u * 0.7) * 0.1, 0),
		},
	}
end

POSES.Type = function(u, seed)
	-- De vez en cuando mira al teclado; si no, a la pantalla
	local glance = UseAnim.ease(clamp((sin(u * 0.45 + seed) - 0.7) * 5, 0, 1))
	local tap = sin(u * 16 + seed) * 0.05
	local tap2 = sin(u * 16 + seed + 1.9) * 0.05
	local set = {}
	arms(set, 0.5, 0.2, -0.14, 0.9 + tap, 0.5, 0.2, -0.14, 0.9 + tap2)
	set.RightWrist = angles(-0.2 + tap, 0, 0)
	set.LeftWrist = angles(-0.2 + tap2, 0, 0)
	return {
		Set = set,
		Add = {
			Waist = angles(-0.06, 0, 0),
			Neck = angles(-0.15 - 0.25 * glance, sin(u * 0.3 + seed) * 0.05, 0),
		},
	}
end

POSES.Piano = function(u, seed)
	-- Las manos recorren el teclado; el cuerpo se mece con la música
	local beat = u * 2.2
	local sweep = sin(beat * 0.5 + seed) * 0.28
	local r1 = sin(beat * 3.1) * 0.05
	local l1 = sin(beat * 3.1 + 1.4) * 0.05
	local set = {}
	arms(set, 0.85 + r1, 0.08 + sweep, 0.06, 0.25 + r1, 0.85 + l1, 0.08 - sweep, 0.06, 0.25 + l1)
	set.RightWrist = angles(-0.1 + r1, 0, 0)
	set.LeftWrist = angles(-0.1 + l1, 0, 0)
	return {
		Set = set,
		Add = {
			Waist = angles(-0.08 + sin(beat) * 0.03, sweep * 0.25, sin(beat * 0.5) * 0.04),
			Neck = angles(-0.2 + sin(beat) * 0.05, sweep * 0.4, 0),
		},
	}
end

POSES.Window = function(u, seed)
	local look = sin(u * 0.5 + seed) * 0.55
	local set = {}
	arms(set, 0.5, 0.25, -0.08, 0.55, 0.5, 0.25, -0.08, 0.55)
	return {
		Set = set,
		Add = {
			Waist = angles(-0.12, look * 0.15, 0),
			Neck = angles(0.05 + sin(u * 0.33) * 0.06, look, 0),
		},
	}
end

UseAnim.Names = {}
for name in POSES do
	table.insert(UseAnim.Names, name)
end
table.sort(UseAnim.Names)

-- ¿Se hace sentado? (la animación de sentarse de Roblox pone las piernas)
UseAnim.Seated = { Sit = true, Sofa = true, Type = true, Piano = true }

function UseAnim.get(name: any): ((number, number, boolean?) -> Pose)?
	if type(name) ~= "string" then
		return nil
	end
	return POSES[name]
end

-- La postura en el momento u (segundos desde que empezó)
function UseAnim.pose(name: string, u: number, seed: number, sleeping: boolean?): Pose?
	local f = POSES[name]
	return if f then f(math.max(u, 0), seed, sleeping) else nil
end

-- Una articulación con la postura mezclada con peso w (0 = como estaba, 1 = la postura entera)
function UseAnim.apply(current: CFrame, pose: Pose, joint: string, w: number): CFrame
	if w <= 0 then
		return current
	end
	local out = current
	local set = pose.Set and pose.Set[joint]
	if set then
		out = out:Lerp(set, w)
	end
	local add = pose.Add and pose.Add[joint]
	if add then
		out = CFrame.identity:Lerp(add, w) * out
	end
	return out
end

-- Los brazos (hombros, codos y muñecas). Un personaje con una tarea en las manos (atributo Work: leer
-- un libro en el banco, el móvil, hacer punto…) los mueve con su tarea (ActorLife/WorkAnim, en el C0):
-- la postura de sentarse no se los toca. Antes los ponía además en el regazo (encima de la tarea) y el
-- brazo se doblaba dos veces: el libro del que lee en el banco acababa metido dentro del pecho.
UseAnim.ArmJoints = { RightShoulder = true, LeftShoulder = true, RightElbow = true, LeftElbow = true, RightWrist = true, LeftWrist = true }

-- ¿Tiene las manos ocupadas con su tarea? (work = el atributo Work del personaje)
function UseAnim.armsBusy(work: any): boolean
	return type(work) == "string" and work ~= ""
end

-- Como apply, pero con las manos ocupadas los brazos se quedan como están
function UseAnim.applyJoint(current: CFrame, pose: Pose, joint: string, w: number, armsBusy: boolean?): CFrame
	if armsBusy and UseAnim.ArmJoints[joint] then
		return current
	end
	return UseAnim.apply(current, pose, joint, w)
end

-- Peso que entra o sale (lineal; UseAnim.ease lo suaviza al aplicarlo)
function UseAnim.fade(weight: number, on: boolean, dt: number): number
	local seconds = if on then UseAnim.BlendIn else UseAnim.BlendOut
	return clamp(weight + (if on then dt else -dt) / seconds, 0, 1)
end

return UseAnim
