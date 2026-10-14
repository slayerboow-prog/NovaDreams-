-- SeaMotion (cliente): animaciones de nadar, bucear, pesca submarina y pesca con caña.
--
-- Todo con código (sin subir animaciones a Roblox). AgeMotion llama a SeaMotion.pose cada frame
-- para cada jugador cercano y mezcla el resultado con su animación (Motor6D.Transform), así que
-- cada jugador ve las animaciones de todos.
--
-- NADAR Y BUCEAR (se sabe por dónde está el cuerpo: en el agua, con la cabeza fuera o dentro)
--   Flotar     quieto en la superficie: piernas en bicicleta y manos que reman a los lados
--   Crol       nadando en la superficie: brazadas alternas, patada rápida y la cabeza respira
--   Bucear     bajo el agua avanzando: cuerpo horizontal, brazadas de braza y patada de delfín
--   Quieto     bajo el agua sin avanzar: cuerpo inclinado, aleteo lento y manos que reman
--   Bajar      de cabeza hacia el fondo (el cuerpo se inclina según si bajas o subes)
--   Subir      hacia la superficie, mirando arriba y pataleando fuerte
--   Apuntar    buceando con el fusil o el arpón: brazos estirados al frente con el arma
--   Disparo    retroceso del arma (atributo SpearAt)
--
-- PESCA CON CAÑA (el servidor pone en el jugador FishAnim, FishAnimAt y FishAnimFish)
--   Cast       echar la caña: se lleva la caña atrás por encima del hombro y latigazo adelante
--   Wait       esperar: caña delante, las dos manos, se mece un poco
--   Bite       pica: tirón seco hacia arriba
--   Fight      pelea: se echa atrás, bombea la caña y la otra mano recoge el carrete
--   Catch      lo saca: caña arriba y enseña el pez con la otra mano
--   Lost       se escapa: hombros caídos y niega con la cabeza
--   Reel       recoger: sube la caña y la recoge hacia el cuerpo
--   Heave      monstruo marino: todos tiran hacia atrás con fuerza a cada tirón
--
-- Ángulos (los mismos que AgeMotion y WorkAnim): hombro x > 0 lleva el brazo hacia delante y arriba
-- (π/2 = horizontal delante, π = hacia arriba); z > 0 lo abre hacia fuera (el izquierdo con signo
-- contrario). Cadera x > 0 lleva la pierna adelante; rodilla x < 0 la dobla. Root x < 0 tumba el
-- cuerpo hacia delante (−π/2 = boca abajo). Cuello x > 0 levanta la cabeza.

local SeaMotion = {}

local sin, cos, abs, exp, clamp = math.sin, math.cos, math.abs, math.exp, math.clamp
local angles = CFrame.Angles
local PI = math.pi
local HALF_PI = PI / 2

SeaMotion.Surface = -2 -- altura del agua (mar, río y lagos)

export type Input = {
	InWater: boolean, -- el cuerpo está en el agua
	Underwater: boolean, -- con la cabeza dentro
	Speed: number, -- velocidad horizontal
	Vertical: number, -- velocidad vertical (> 0 sube)
	Armed: boolean, -- lleva fusil submarino o arpón
	ShotAgo: number, -- segundos desde el último disparo (grande si hace mucho)
	Fish: string?, -- estado de la pesca con caña (FishAnim)
	FishAgo: number, -- segundos desde que empezó ese estado
	Phase: number, -- fase de la brazada (sube con el tiempo y la velocidad)
	Seed: number,
}

export type Pose = { [string]: CFrame }

-- 0..1 con forma de campana entre a y b (sube y baja suave)
local function bump(x: number, a: number, b: number): number
	if x <= a or x >= b then
		return 0
	end
	return sin((x - a) / (b - a) * PI)
end

-- Paso suave de 0 a 1 entre a y b
local function ease(x: number, a: number, b: number): number
	local k = clamp((x - a) / (b - a), 0, 1)
	return k * k * (3 - 2 * k)
end

local function lerp(a: number, b: number, k: number): number
	return a + (b - a) * k
end

---------------------------------------------------------------------
-- Nadar y bucear
---------------------------------------------------------------------

-- Flotando quieto en la superficie
function SeaMotion.tread(t: number, seed: number): Pose
	local s = sin(t * 3.2 + seed)
	local c = cos(t * 3.2 + seed)
	local scull = sin(t * 4.1 + seed)
	return {
		Root = angles(-0.12, 0, s * 0.03),
		Waist = angles(0.05, 0, 0),
		Neck = angles(0.12 + s * 0.03, sin(t * 0.7 + seed) * 0.25, 0),
		-- Las manos reman a los lados, con los codos algo doblados
		RightShoulder = angles(0.35, scull * 0.55, 0.85),
		LeftShoulder = angles(0.35, -scull * 0.55, -0.85),
		RightElbow = angles(0.55 + scull * 0.15, 0, 0),
		LeftElbow = angles(0.55 - scull * 0.15, 0, 0),
		-- Bicicleta: una pierna sube mientras la otra baja
		RightHip = angles(0.55 + s * 0.4, 0, 0.08),
		LeftHip = angles(0.55 - s * 0.4, 0, -0.08),
		RightKnee = angles(-(0.8 + c * 0.45), 0, 0),
		LeftKnee = angles(-(0.8 - c * 0.45), 0, 0),
		RightAnkle = angles(0.3, 0, 0),
		LeftAnkle = angles(0.3, 0, 0),
	}
end

-- Crol: tumbado boca abajo en la superficie, brazos que dan la vuelta alternos
function SeaMotion.crawl(phase: number, t: number, seed: number): Pose
	-- Cada brazo: delante (π) → tira por debajo (π/2) → atrás hasta la cadera (0) → por encima (−π/2)
	local right = PI - (phase % (2 * PI))
	local left = PI - ((phase + PI) % (2 * PI))
	-- El codo se dobla al sacar el brazo del agua (recobro) y un poco al tirar
	local function elbow(a: number): number
		return if a < 0 then 1.2 * bump(a, -PI, 0) else 0.35 * bump(a, 0, PI)
	end
	local kick = sin(t * 11 + seed)
	-- Respira girando la cabeza hacia el brazo que sale del agua (cada vuelta completa)
	local breathe = bump((phase % (2 * PI)), PI * 1.1, PI * 1.9)
	local roll = sin(phase) * 0.35 -- el cuerpo rota un poco con cada brazada
	return {
		Root = angles(-HALF_PI + 0.12, 0, roll * 0.5),
		Waist = angles(0, roll * 0.4, 0),
		Neck = angles(0.35, breathe * 1.1, 0),
		RightShoulder = angles(right, 0, 0.08),
		LeftShoulder = angles(left, 0, -0.08),
		RightElbow = angles(elbow(right), 0, 0),
		LeftElbow = angles(elbow(left), 0, 0),
		RightWrist = CFrame.identity,
		LeftWrist = CFrame.identity,
		-- Patada rápida de crol: piernas casi rectas
		RightHip = angles(kick * 0.28, 0, 0.03),
		LeftHip = angles(-kick * 0.28, 0, -0.03),
		RightKnee = angles(-(0.15 + math.max(0, kick) * 0.35), 0, 0),
		LeftKnee = angles(-(0.15 + math.max(0, -kick) * 0.35), 0, 0),
		RightAnkle = angles(-0.6, 0, 0),
		LeftAnkle = angles(-0.6, 0, 0),
	}
end

-- Cuánto se tumba el cuerpo buceando (ángulo X de Root: −π/2 = horizontal boca abajo). Bajando va
-- de cabeza, subiendo mira arriba y quieto se pone más de pie; pero nunca más de MaxHeadDown por
-- debajo de horizontal (antes llegaba a 125°: se veía boca abajo, con los pies para arriba).
SeaMotion.MaxHeadDown = 0.5
SeaMotion.MaxHeadUp = 1.0
function SeaMotion.bodyPitch(vertical: number, moving: number): number
	local tilt = clamp(-vertical / 10, -1, 1) -- 1 bajando, −1 subiendo
	local pitch = -HALF_PI - tilt * (if tilt > 0 then SeaMotion.MaxHeadDown else 0.6) + (1 - clamp(moving, 0, 1)) * 0.5
	return clamp(pitch, -HALF_PI - SeaMotion.MaxHeadDown, -HALF_PI + SeaMotion.MaxHeadUp)
end

-- Buceando: cuerpo horizontal (o de cabeza si bajas), braza con los brazos y delfín con las piernas
function SeaMotion.dive(phase: number, t: number, seed: number, vertical: number, moving: number): Pose
	-- Inclinación: baja → de cabeza; sube → mirando arriba
	local tilt = clamp(-vertical / 10, -1, 1)
	local body = SeaMotion.bodyPitch(vertical, moving)
	local cycle = phase % (2 * PI)
	-- Braza: brazos delante juntos, se abren hacia fuera y vuelven al pecho, y otra vez delante
	local sweep = bump(cycle, 0, PI) -- abrir y tirar
	local tuck = bump(cycle, PI * 0.8, PI * 1.5) -- recoger al pecho
	local armX = lerp(PI - 0.1, HALF_PI + 0.3, sweep) - tuck * 0.6
	local armZ = sweep * 0.9
	local armElbow = tuck * 1.6 + sweep * 0.3
	-- Delfín: las dos piernas juntas, en onda
	local wave = sin(t * (5 + moving * 3) + seed)
	local legAmp = 0.15 + moving * 0.25
	return {
		Root = angles(body, 0, 0),
		Waist = angles(wave * 0.08 * moving, 0, 0),
		Neck = angles(0.55 + tilt * 0.2, sin(t * 0.9 + seed) * 0.2, 0),
		RightShoulder = angles(lerp(0.4, armX, moving), 0, armZ * moving + (1 - moving) * 0.7),
		LeftShoulder = angles(lerp(0.4, armX, moving), 0, -(armZ * moving + (1 - moving) * 0.7)),
		RightElbow = angles(armElbow * moving + (1 - moving) * (0.5 + sin(t * 3.5 + seed) * 0.2), 0, 0),
		LeftElbow = angles(armElbow * moving + (1 - moving) * (0.5 - sin(t * 3.5 + seed) * 0.2), 0, 0),
		RightHip = angles(wave * legAmp, 0, 0.04),
		LeftHip = angles(wave * legAmp, 0, -0.04),
		RightKnee = angles(-(0.2 + math.max(0, wave) * 0.5 * (0.5 + moving)), 0, 0),
		LeftKnee = angles(-(0.2 + math.max(0, wave) * 0.5 * (0.5 + moving)), 0, 0),
		RightAnkle = angles(-0.9, 0, 0),
		LeftAnkle = angles(-0.9, 0, 0),
	}
end

-- Pesca submarina: brazos estirados al frente con el arma; retroceso al disparar
function SeaMotion.aim(t: number, seed: number, vertical: number, shotAgo: number): Pose
	local recoil = if shotAgo < 0.6 then exp(-shotAgo * 9) * (1 - exp(-shotAgo * 60)) else 0
	local tilt = clamp(-vertical / 12, -1, 1)
	local kick = sin(t * 4.5 + seed)
	return {
		Root = angles(clamp(-HALF_PI + 0.35 - tilt * 0.5 + recoil * 0.25, -HALF_PI - SeaMotion.MaxHeadDown, -0.3), 0, 0),
		Waist = angles(recoil * 0.2, 0, 0),
		Neck = angles(0.75, 0, 0), -- mira por encima del arma
		-- El brazo derecho sujeta el arma estirado; el izquierdo la acompaña por debajo
		RightShoulder = angles(PI - 0.2 - recoil * 0.55, 0, -0.05),
		LeftShoulder = angles(PI - 0.35 - recoil * 0.45, 0, 0.28),
		RightElbow = angles(0.08 + recoil * 0.7, 0, 0),
		LeftElbow = angles(0.3 + recoil * 0.6, 0, 0),
		RightHip = angles(kick * 0.3, 0, 0.05),
		LeftHip = angles(-kick * 0.3, 0, -0.05),
		RightKnee = angles(-(0.3 + math.max(0, kick) * 0.4), 0, 0),
		LeftKnee = angles(-(0.3 + math.max(0, -kick) * 0.4), 0, 0),
		RightAnkle = angles(-0.9, 0, 0),
		LeftAnkle = angles(-0.9, 0, 0),
	}
end

---------------------------------------------------------------------
-- Pesca con caña (solo la parte de arriba: las piernas siguen su animación)
---------------------------------------------------------------------

-- Caña delante con las dos manos (esperar)
local function hold(t: number, seed: number): Pose
	local sway = sin(t * 1.3 + seed) * 0.04
	return {
		Waist = angles(0.02, -0.12, 0),
		Neck = angles(-0.18, -0.05, 0), -- mira el corcho
		RightShoulder = angles(0.95 + sway, 0.15, 0.08),
		RightElbow = angles(0.75, 0, 0),
		LeftShoulder = angles(0.75 + sway, -0.35, -0.05),
		LeftElbow = angles(1.2, 0, 0),
	}
end
SeaMotion.hold = hold

local function mix(a: Pose, b: Pose, k: number): Pose
	if k <= 0 then
		return a
	elseif k >= 1 then
		return b
	end
	local out = {}
	for name, cf in a do
		out[name] = cf:Lerp(b[name] or CFrame.identity, k)
	end
	for name, cf in b do
		if out[name] == nil then
			out[name] = CFrame.identity:Lerp(cf, k)
		end
	end
	return out
end
SeaMotion.mix = mix

-- Echar la caña (dura 1 s y se queda esperando)
function SeaMotion.cast(ago: number, t: number, seed: number): Pose
	local back = ease(ago, 0, 0.35) * (1 - ease(ago, 0.4, 0.55)) -- caña atrás por encima del hombro
	local whip = bump(ago, 0.4, 0.8) -- latigazo adelante
	local pose: Pose = {
		Waist = angles(0.12 * back - 0.18 * whip, 0.45 * back - 0.25 * whip, 0),
		Neck = angles(0.15 * back - 0.1 * whip, -0.2 * back, 0),
		RightShoulder = angles(0.95 + 1.9 * back + 0.45 * whip, 0.15, 0.1 + 0.25 * back),
		RightElbow = angles(0.75 + 0.7 * back - 0.5 * whip, 0, 0),
		LeftShoulder = angles(0.75 + 0.6 * back + 0.3 * whip, -0.35, -0.05),
		LeftElbow = angles(1.2 - 0.4 * whip, 0, 0),
	}
	return mix(pose, hold(t, seed), ease(ago, 0.75, 1.05))
end

-- Pica: tirón seco hacia arriba
function SeaMotion.bite(ago: number, t: number, seed: number): Pose
	local jerk = bump(ago, 0, 0.45)
	local base = hold(t, seed)
	return {
		Waist = base.Waist * angles(0.18 * jerk, 0, 0),
		Neck = base.Neck * angles(0.25 * jerk, 0, 0),
		RightShoulder = base.RightShoulder * angles(0.75 * jerk, 0, 0),
		RightElbow = base.RightElbow * angles(0.35 * jerk, 0, 0),
		LeftShoulder = base.LeftShoulder * angles(0.55 * jerk, 0, 0),
		LeftElbow = base.LeftElbow,
	}
end

-- Pelea con un pez grande: echado atrás, bombea la caña y recoge carrete con la izquierda.
-- `ago` = desde el último tirón (cada tirón da un empujón hacia atrás)
function SeaMotion.fight(ago: number, t: number, seed: number, strength: number?): Pose
	local k = strength or 1
	local pump = sin(t * 7 + seed) * 0.18
	local tug = bump(ago, 0, 0.35)
	local crank = t * 12 + seed
	return {
		Root = angles(0.12 * k + 0.1 * tug, 0, 0),
		Waist = angles(0.22 * k + 0.2 * tug, -0.1, sin(t * 2 + seed) * 0.05),
		Neck = angles(-0.05 - 0.1 * tug, 0, 0),
		RightShoulder = angles(1.35 + pump + 0.45 * tug, 0.1, 0.12),
		RightElbow = angles(0.95 - pump * 0.5 + 0.3 * tug, 0, 0),
		-- La mano izquierda da vueltas al carrete
		LeftShoulder = angles(0.95 + sin(crank) * 0.18, -0.4 + cos(crank) * 0.15, -0.05),
		LeftElbow = angles(1.35 + cos(crank) * 0.25, 0, 0),
		RightHip = angles(0.12 * k, 0, 0.12),
		LeftHip = angles(-0.1 * k, 0, -0.12),
		RightKnee = angles(-0.25 * k, 0, 0),
		LeftKnee = angles(-0.2 * k, 0, 0),
	}
end

-- Lo saca y lo enseña: caña arriba, y la mano izquierda levanta el pez
function SeaMotion.catch(ago: number, t: number, seed: number): Pose
	local lift = ease(ago, 0, 0.35)
	local show = ease(ago, 0.35, 0.8) * (1 - ease(ago, 2.2, 2.6))
	local pose: Pose = {
		Waist = angles(0.12 * lift - 0.05 * show, 0.25 * show, 0),
		Neck = angles(0.15 * show, 0.35 * show, 0), -- mira el pez
		RightShoulder = angles(0.95 + 1.2 * lift - 0.4 * show, 0.15, 0.15),
		RightElbow = angles(0.75 - 0.3 * lift, 0, 0),
		LeftShoulder = angles(0.75 + 1.0 * show, -0.35 + 0.2 * show, -0.05 + 0.35 * show),
		LeftElbow = angles(1.2 - 0.9 * show + sin(t * 9) * 0.05 * show, 0, 0),
	}
	return mix(pose, hold(t, seed), ease(ago, 2.4, 2.9))
end

-- Se ha escapado (o solo era basura): hombros caídos y niega con la cabeza
function SeaMotion.lost(ago: number, t: number, seed: number): Pose
	local sad = bump(ago, 0, 1.6)
	local base = hold(t, seed)
	return {
		Waist = base.Waist * angles(-0.12 * sad, 0, 0),
		Neck = base.Neck * angles(-0.25 * sad, sin(ago * 14) * 0.3 * sad, 0),
		RightShoulder = base.RightShoulder * angles(-0.5 * sad, 0, 0),
		RightElbow = base.RightElbow,
		LeftShoulder = base.LeftShoulder * angles(-0.55 * sad, 0, 0.1 * sad),
		LeftElbow = base.LeftElbow * angles(-0.5 * sad, 0, 0),
	}
end

-- Recoger el sedal: sube la caña y la trae al cuerpo (después, los brazos se sueltan)
function SeaMotion.reel(ago: number, t: number, seed: number): Pose
	local up = bump(ago, 0, 0.5)
	local tuck = ease(ago, 0.3, 0.8)
	local base = hold(t, seed)
	return {
		Waist = base.Waist,
		Neck = base.Neck * angles(0.1 * up, 0, 0),
		RightShoulder = CFrame.identity:Lerp(angles(0.95 + 0.9 * up, 0.15, 0.08), 1) * angles(-0.7 * tuck, 0, 0),
		RightElbow = angles(0.75 + 0.8 * tuck, 0, 0),
		LeftShoulder = angles(0.75 + 0.5 * up - 0.5 * tuck, -0.35, -0.05),
		LeftElbow = angles(1.2 + 0.3 * tuck, 0, 0),
	}
end

-- Tirar de un monstruo marino entre todos: tirón fuerte hacia atrás a cada toque
function SeaMotion.heave(ago: number, t: number, seed: number): Pose
	local pose = SeaMotion.fight(ago, t, seed, 1.8)
	local tug = bump(ago, 0, 0.4)
	pose.Root = angles(0.25 + 0.2 * tug, 0, 0)
	pose.RightShoulder = angles(1.6 + 0.6 * tug, 0.1, 0.12)
	pose.LeftShoulder = angles(1.45 + 0.5 * tug, -0.2, -0.1)
	pose.LeftElbow = angles(0.6 + 0.4 * tug, 0, 0)
	return pose
end

-- Cuánto dura cada estado de la pesca antes de quedarse esperando (nil = sigue mientras dure)
SeaMotion.FishDurations = { Reel = 1.1 }

---------------------------------------------------------------------
-- Elegir la postura
---------------------------------------------------------------------

-- Devuelve la postura y el nombre del estado (o nil si no hay nada que animar)
function SeaMotion.pose(input: Input, t: number): (Pose?, string?)
	local seed = input.Seed
	if input.InWater then
		local moving = clamp((input.Speed - 1.5) / 6, 0, 1)
		if input.Underwater then
			if input.Armed and (moving < 0.6 or input.ShotAgo < 1.2) then
				return SeaMotion.aim(t, seed, input.Vertical, input.ShotAgo), "Aim"
			end
			local state = if input.Vertical < -3 then "Down" elseif input.Vertical > 3 then "Up" elseif moving > 0.2 then "Dive" else "Hover"
			return SeaMotion.dive(input.Phase, t, seed, input.Vertical, math.max(moving, if state == "Down" or state == "Up" then 0.7 else 0)), state
		end
		if moving > 0.25 then
			return SeaMotion.crawl(input.Phase, t, seed), "Crawl"
		end
		return SeaMotion.tread(t, seed), "Tread"
	end
	local fish = input.Fish
	if not fish then
		return nil, nil
	end
	local ago = math.max(0, input.FishAgo)
	local limit = SeaMotion.FishDurations[fish]
	if limit and ago > limit then
		return nil, nil
	end
	if fish == "Cast" then
		return SeaMotion.cast(ago, t, seed), fish
	elseif fish == "Bite" then
		return SeaMotion.bite(ago, t, seed), fish
	elseif fish == "Fight" then
		return SeaMotion.fight(ago, t, seed), fish
	elseif fish == "Catch" then
		return SeaMotion.catch(ago, t, seed), fish
	elseif fish == "Lost" then
		return SeaMotion.lost(ago, t, seed), fish
	elseif fish == "Reel" then
		return SeaMotion.reel(ago, t, seed), fish
	elseif fish == "Heave" then
		return SeaMotion.heave(ago, t, seed), fish
	end
	return hold(t, seed), "Wait"
end

-- Velocidad de la brazada según cómo nada
function SeaMotion.strokeRate(speed: number, underwater: boolean): number
	return (if underwater then 1.6 else 2.2) + math.min(speed, 20) * 0.18
end

return SeaMotion
