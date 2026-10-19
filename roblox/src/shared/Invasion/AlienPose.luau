-- AlienPose: la animación procedural de los alienígenas v2 y de la gente transformada (mallas de
-- Blender por segmentos: shared/Invasion/AlienMallas). Cuentas puras (las prueba scripts/test-invasion):
-- de lo que está haciendo (velocidad, preparando un ataque, golpeando, encajando un disparo, cayendo)
-- a la rotación de cada articulación (Motor6D.Transform, que pone el cliente: Controllers/AlienAnim).
--
-- Andares (Gait, de la malla):
--   Biped    piernas y brazos alternos, cuerpo que sube y baja y se inclina al correr
--   Crawl    tentáculos en ola (los Mórfagos, el bicho tentacular)
--   Float    flotan: vaivén lento, túnica que se mece, halo que gira y alas que baten (Lumínidos)
--   Quad     cuatro patas en diagonal, cola que se mueve (ciervo, perro tostadora, zorro)
--   Slither  la babosa: ondula
--   Hop      a saltitos (rana, búho)
--   Ship     las naves: el rotor gira y se mecen un poco
--
-- Estado (s): T (segundos), Speed (studs/s), Base (velocidad de andar normal), Windup (0..1, preparando el
-- ataque: se ve venir), Strike (0..1, el golpe o el disparo), Hit (segundos desde el último disparo que
-- encajó; nil = nada), HitSide (-1/1), Dead (0..1, cayendo), Scale (alto / 6), Race.

local AlienPose = {}

export type State = {
	T: number,
	Speed: number?,
	Base: number?,
	Windup: number?,
	Strike: number?,
	Hit: number?,
	HitSide: number?,
	Dead: number?,
	Scale: number?,
	Race: string?,
}

AlienPose.HitTime = 0.35 -- lo que dura el respingo al encajar un disparo
AlienPose.Gaits = { "Biped", "Crawl", "Float", "Quad", "Slither", "Hop", "Ship" }

local sin, cos, clamp = math.sin, math.cos, math.clamp

local function ang(p: number, y: number, r: number): CFrame
	return CFrame.Angles(p, y, r)
end

-- 0..1 andando -> 1..2 corriendo (la amplitud del paso)
function AlienPose.stride(speed: number?, base: number?): (number, number)
	local v = math.max(speed or 0, 0)
	local b = math.max(base or 8, 1)
	local walk = clamp(v / b, 0, 2.2)
	-- pasos por segundo: más rápido al correr, pero sin volverse loco
	local rate = 1.2 + 1.6 * clamp(walk, 0, 1.6)
	return walk, rate
end

-- El respingo: fuerte al principio y se va en HitTime
function AlienPose.flinch(age: number?): number
	if not age or age < 0 or age >= AlienPose.HitTime then
		return 0
	end
	local k = age / AlienPose.HitTime
	return (1 - k) * (1 - k) * (if k < 0.15 then k / 0.15 else 1)
end

-- Preparar y soltar: los brazos van atrás (windup) y luego delante de golpe (strike)
function AlienPose.swing(windup: number?, strike: number?): number
	if strike and strike > 0 then
		local k = clamp(strike, 0, 1)
		return -1 + 2.4 * math.min(k * 3, 1) - 1.4 * math.max(0, k - 0.34) / 0.66
	end
	if windup and windup > 0 then
		return -clamp(windup, 0, 1)
	end
	return 0
end

function AlienPose.pose(gait: string, s: State): { [string]: CFrame }
	local t = s.T
	local walk, rate = AlienPose.stride(s.Speed, s.Base)
	local sc = s.Scale or 1
	local ph = t * rate * math.pi * 2
	local fl = AlienPose.flinch(s.Hit)
	local side = s.HitSide or 1
	local sw = AlienPose.swing(s.Windup, s.Strike)
	local dead = clamp(s.Dead or 0, 0, 1)
	local out: { [string]: CFrame } = {}
	local amp = math.min(walk, 1) * 0.55 + math.max(0, walk - 1) * 0.35
	local idle = sin(t * 1.7) -- respiración

	if gait == "Biped" then
		local bob = math.abs(sin(ph)) * 0.12 * sc * math.min(walk, 1.5)
		local lean = -0.06 * math.min(walk, 2) -- hacia delante al correr
		out.Body = CFrame.new(0, bob + idle * 0.03 * sc, 0) * ang(lean - fl * 0.35 - dead * 0.9, sin(ph) * 0.08 * amp + fl * 0.2 * side, fl * 0.15 * side + dead * 0.3)
		out.LegL = ang(sin(ph) * amp, 0, 0)
		out.LegR = ang(-sin(ph) * amp, 0, 0)
		out.ArmL = ang(-sin(ph) * amp * 0.8 + fl * -0.5 + sw * 0.25, 0, -fl * 0.4 - dead * 0.8)
		out.ArmR = ang(sin(ph) * amp * 0.6 + fl * -0.4 + sw * 0.9, 0, fl * 0.4 + dead * 0.8)
		out.Head = ang(-lean * 0.6 + idle * 0.04 - fl * 0.4 + sw * 0.1, sin(t * 0.6) * 0.15, fl * 0.2 * side)
		out.Cape = ang(0.1 * math.min(walk, 1.5) + sin(t * 2.3) * 0.05, 0, 0)
	elseif gait == "Crawl" then
		local w = math.max(amp, 0.12)
		out.Body = CFrame.new(0, sin(ph * 2) * 0.08 * sc + idle * 0.05 * sc, 0) * ang(-fl * 0.3 - dead * 0.6, sin(ph) * 0.05, fl * 0.2 * side + dead * 0.4)
		for i, j in { "LegL", "LegR", "LegBL", "LegBR" } do
			local p = ph + i * math.pi / 2
			out[j] = ang(sin(p) * w * 0.6, cos(p) * w * 0.3, sin(p + 1) * 0.15 * (if i % 2 == 0 then 1 else -1))
		end
		out.ArmL = ang(sin(t * 2.4) * 0.2 + sw * 0.8 - fl * 0.5, 0, -0.1 - dead * 0.6)
		out.ArmR = ang(sin(t * 2.4 + 1.3) * 0.2 + sw * 0.8 - fl * 0.5, 0, 0.1 + dead * 0.6)
		out.Head = ang(sin(t * 1.3) * 0.08 - fl * 0.35 + sw * 0.2, sin(t * 0.7) * 0.2, 0)
		out.Cape = ang(sin(t * 1.9) * 0.08, 0, 0)
	elseif gait == "Float" then
		local hover = sin(t * 1.6) * 0.25 * sc
		out.Body = CFrame.new(0, hover - dead * 1.0 * sc, 0) * ang(-0.12 * math.min(walk, 1.5) - fl * 0.3 - dead * 0.5, sin(t * 0.9) * 0.06 + fl * 0.25 * side, sin(t * 1.1) * 0.05)
		out.ArmL = ang(sin(t * 1.4) * 0.15 - 0.12 * amp + sw * 0.4 - fl * 0.6, 0, -0.15 - sin(t * 1.4) * 0.06 - dead)
		out.ArmR = ang(sin(t * 1.4 + 2) * 0.15 - 0.12 * amp + sw * 1.0 - fl * 0.5, 0, 0.15 + sin(t * 1.4) * 0.06 + dead)
		out.Head = ang(sin(t * 0.8) * 0.06 - fl * 0.4, sin(t * 0.5) * 0.2, 0)
		out.Halo = ang(0, 0, t * 1.2)
		out.Wings = ang(sin(t * 3.2) * 0.18, 0, 0)
		out.Cape = ang(0.1 * math.min(walk, 1.5) + sin(t * 1.7) * 0.06, 0, 0)
	elseif gait == "Quad" then
		local w = amp * 0.9
		out.Body = CFrame.new(0, math.abs(sin(ph)) * 0.06 * sc, 0) * ang(-fl * 0.25 - dead * 0.3, 0, fl * 0.3 * side + dead * 1.2)
		out.LegL = ang(sin(ph) * w, 0, 0)
		out.LegBR = ang(sin(ph) * w, 0, 0)
		out.LegR = ang(-sin(ph) * w, 0, 0)
		out.LegBL = ang(-sin(ph) * w, 0, 0)
		out.Head = ang(sin(ph * 2) * 0.06 * amp + sin(t * 0.9) * 0.08 - fl * 0.4, sin(t * 0.6) * 0.3 * (1 - math.min(walk, 1)), 0)
		out.Tail = ang(0.1, sin(t * (4 + 6 * math.min(walk, 1))) * 0.45, 0)
	elseif gait == "Slither" then
		local w = 0.15 + amp * 0.3
		out.Body = ang(sin(ph) * 0.04 - fl * 0.2, sin(ph * 0.5) * w * 0.4, 0)
		out.Head = ang(sin(t * 2) * 0.1, sin(ph * 0.5 + 1) * w * 0.8, 0)
	elseif gait == "Hop" then
		local hop = math.max(0, sin(ph)) -- en el aire media vuelta de cada paso
		local up = hop * (0.35 + 0.5 * math.min(walk, 1)) * sc * (if walk > 0.05 then 1 else 0.1)
		out.Body = CFrame.new(0, up, 0) * ang(-hop * 0.15 - fl * 0.3 - dead * 0.6, 0, fl * 0.2 * side + dead)
		out.LegL = ang(-hop * 0.5, 0, 0)
		out.LegR = ang(-hop * 0.5, 0, 0)
		out.LegBL = ang(hop * 0.9, 0, 0)
		out.LegBR = ang(hop * 0.9, 0, 0)
		out.ArmL = ang(0, 0, -sin(t * 14) * 0.6 * hop - 0.1)
		out.ArmR = ang(0, 0, sin(t * 14) * 0.6 * hop + 0.1)
		out.Head = ang(sin(t * 1.1) * 0.1 - fl * 0.3, sin(t * 0.8) * 0.4 * (1 - math.min(walk, 1)), 0)
	else -- Ship
		local axisZ = s.Race == "Vortidos"
		out.Rotor = if axisZ then ang(0, 0, t * 6) else ang(0, t * 9, 0)
		out.Body = ang(sin(t * 0.9) * 0.03, 0, sin(t * 0.7) * 0.05)
	end
	return out
end

-- Al caer: cuánto se ve (0 = entero, 1 = se ha deshecho del todo) y lo que encoge. Nada de sangre:
-- se deshacen en luz y chispas.
AlienPose.DissolveTime = 1.1
function AlienPose.dissolve(age: number): (number, number)
	local k = clamp(age / AlienPose.DissolveTime, 0, 1)
	local fade = k * k
	local shrink = 1 - 0.35 * k
	return fade, shrink
end

-- La transformación de un vecino en criatura (Controllers/AlienAnim): (silueta 0..1 que se va,
-- criatura 0..1 que aparece) a los `age` segundos. Primero brilla la persona, luego gira la espiral
-- y aparece la criatura.
AlienPose.TransformTime = 1.6
function AlienPose.transform(age: number): (number, number)
	local k = clamp(age / AlienPose.TransformTime, 0, 1)
	local person = 1 - clamp((k - 0.15) / 0.45, 0, 1)
	local creature = clamp((k - 0.45) / 0.45, 0, 1)
	return person, creature
end

-- ¿Animar de cerca o pasar a la versión lejana (LOD, sin animar)? Con histéresis para no parpadear
function AlienPose.useLod(distance: number, wasLod: boolean, near: number?, far: number?): boolean
	local n, f = near or 150, far or 170
	if wasLod then
		return distance > n
	end
	return distance > f
end

return AlienPose
