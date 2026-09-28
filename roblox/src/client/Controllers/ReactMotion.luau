-- ReactMotion (cliente): el cuerpo reacciona a lo que pasa, con animaciones hechas con código.
--
-- GOLPES (CombatController llama a ReactMotion.play)
--   * Quien pega: directo (brazo derecho), cruzado (izquierdo) y gancho de abajo arriba (el golpe
--     fuerte del combo), girando la cintura y con la otra mano en guardia.
--   * Quien recibe: la cabeza va hacia atrás y el cuerpo se dobla; con el golpe fuerte se tambalea
--     hacia atrás con los brazos abiertos. Si se defiende, solo retrocede un poco la guardia.
--   * Defenderse (atributo Blocking): guardia con los dos antebrazos delante de la cara.
--
-- CHOQUES AL ANDAR (se mira en tu pantalla para todos los jugadores cercanos)
--   * Pelota (tag Toy): patada con la pierna derecha.
--   * Piedra (tag Piedra o piezas de roca pequeñas): tropiezo, el cuerpo se va hacia delante y los
--     brazos se adelantan para no caer.
--   * Arena (suelo de arena): pasos pesados, rodillas más dobladas y polvo en los pies.
--   * Arbustos y setos: brazos delante apartando ramas, el arbusto se sacude y caen hojas.
--   * Charcos (los de la lluvia de WetWorld): se levantan más las rodillas y salpica.
--
-- GESTOS DE ACCIONES (los piden otros sistemas con ReactMotion.play / hold)
--   * Alcanzar (Reach): al usar un cartel "pulsa E" la mano va hacia el objeto (alto o bajo).
--   * Coger del suelo (PickUp): se agacha doblando las rodillas y recoge.
--   * Comer (Eat) y beber (Drink): la mano a la boca (dos bocados / la cabeza atrás al beber).
--   * Lanzar (Throw): piedras, con el brazo por encima del hombro.
--   * Pescar: lanzar la caña (Cast), tirar (Reel) y sujetarla con las dos manos (hold "Rod").
--   * Aterrizar (Land): se agacha un poco al caer; desde muy alto, traspiés (Stumble).
--   * Linterna (hold "Flashlight"): el brazo derecho delante, a la altura del pecho.
--   Todos entran y salen suaves (strike: subida con curva, se mantiene y baja con curva).
--
-- Se aplica como retoque de Motor6D.Transform después de las animaciones, de AgeMotion y de
-- Locomotion: es la capa 30 de PoseLayers (que lleva la cuenta de qué puso la animación, así no se
-- acumula). Las posturas son funciones puras: scripts/test-react.luau y scripts/test-motion.luau.
--
-- Ángulos (convención de AgeMotion/WorkAnim, R15):
--   Neck/Waist  x > 0 hacia atrás (mirar arriba / echarse atrás), y > 0 gira a su izquierda
--   Root        x < 0 el cuerpo se inclina hacia delante
--   Shoulder    x > 0 brazo hacia delante/arriba, z abre el brazo (derecho +, izquierdo -)
--   Elbow       x > 0 dobla el brazo
--   Hip         x > 0 pierna hacia delante;  Knee x < 0 dobla la rodilla

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local ReactMotion = {}
local Layers: any = nil -- PoseLayers (se carga en init: las pruebas cargan este módulo sin Roblox)

local sin, abs, pi = math.sin, math.abs, math.pi
local angles = CFrame.Angles

export type Pose = { [string]: CFrame }
type Kind = { Duration: number, Pose: (t: number, opts: { [string]: any }) -> Pose }

local function bell(t: number): number -- 0 → 1 → 0
	return sin(math.clamp(t, 0, 1) * pi)
end

-- Sube rápido hasta `peak`, se mantiene hasta `hold` y vuelve suave
local function strike(t: number, peak: number, hold: number): number
	if t <= 0 or t >= 1 then
		return 0
	elseif t < peak then
		local x = t / peak
		return x * x * (3 - 2 * x)
	elseif t < hold then
		return 1
	end
	local x = (t - hold) / (1 - hold)
	return 1 - x * x * (3 - 2 * x)
end

local function guardRight(w: number): Pose
	return { RightShoulder = angles(1.0 * w, 0, 0.15 * w), RightElbow = angles(1.9 * w, 0, 0) }
end
local function guardLeft(w: number): Pose
	return { LeftShoulder = angles(1.0 * w, 0, -0.15 * w), LeftElbow = angles(1.9 * w, 0, 0) }
end

local function merge(...: Pose): Pose
	local out = {}
	for _, pose in { ... } do
		for name, cf in pose do
			out[name] = if out[name] then out[name] * cf else cf
		end
	end
	return out
end

ReactMotion.Kinds = {
	-- Directo de derecha
	Jab = {
		Duration = 0.34,
		Pose = function(t: number): Pose
			local k = strike(t, 0.35, 0.55)
			local g = bell(t)
			return merge({
				RightShoulder = angles(1.5 * k + 0.9 * (1 - k) * g, 0, 0.1 * g),
				RightElbow = angles(1.9 * (1 - k) * g + 0.05 * g, 0, 0),
				Waist = angles(0, 0.38 * k, 0),
				Neck = angles(-0.05 * g, -0.3 * k, 0),
			}, guardLeft(g))
		end,
	},
	-- Cruzado de izquierda
	Cross = {
		Duration = 0.36,
		Pose = function(t: number): Pose
			local k = strike(t, 0.35, 0.55)
			local g = bell(t)
			return merge({
				LeftShoulder = angles(1.5 * k + 0.9 * (1 - k) * g, 0, -0.1 * g),
				LeftElbow = angles(1.9 * (1 - k) * g + 0.05 * g, 0, 0),
				Waist = angles(0, -0.45 * k, 0),
				Neck = angles(-0.05 * g, 0.35 * k, 0),
				Root = angles(-0.08 * k, 0, 0),
			}, guardRight(g))
		end,
	},
	-- Gancho de abajo arriba (golpe fuerte): se agacha, carga y sube
	Hook = {
		Duration = 0.62,
		Pose = function(t: number): Pose
			local load = strike(t, 0.3, 0.38) * (if t < 0.38 then 1 else 0)
			local hit = strike((t - 0.3) / 0.7, 0.3, 0.55)
			local g = bell(t)
			return merge({
				Root = CFrame.new(0, -0.5 * load, 0) * angles(-0.15 * load - 0.12 * hit, 0, 0),
				Waist = angles(0.1 * hit, -0.5 * load + 0.7 * hit, 0),
				RightShoulder = angles(-0.35 * load + 2.0 * hit, 0, 0.25 * hit),
				RightElbow = angles(1.5 * load + 1.1 * hit, 0, 0),
				RightHip = angles(0.25 * load, 0, 0),
				LeftHip = angles(0.25 * load, 0, 0),
				RightKnee = angles(-0.5 * load, 0, 0),
				LeftKnee = angles(-0.5 * load, 0, 0),
				Neck = angles(0.1 * hit, -0.35 * hit, 0),
			}, guardLeft(g))
		end,
	},
	-- Recibir un golpe normal: la cabeza atrás y un poco de lado
	HitLight = {
		Duration = 0.4,
		Pose = function(t: number, opts): Pose
			local k = strike(t, 0.18, 0.3)
			local side = opts.Side or 1
			return {
				Neck = angles(0.45 * k, 0.25 * side * k, 0.15 * side * k),
				Waist = angles(0.22 * k, 0.12 * side * k, 0),
				RightShoulder = angles(0.3 * k, 0, 0.35 * k),
				LeftShoulder = angles(0.3 * k, 0, -0.35 * k),
				RightElbow = angles(0.6 * k, 0, 0),
				LeftElbow = angles(0.6 * k, 0, 0),
			}
		end,
	},
	-- Golpe fuerte: se dobla, se tambalea hacia atrás con los brazos abiertos y se recupera
	HitHeavy = {
		Duration = 0.95,
		Pose = function(t: number): Pose
			local k = strike(t, 0.15, 0.4)
			local wobble = sin(t * 18) * (1 - t) * 0.12
			return {
				Root = angles(0.35 * k, 0, wobble),
				Waist = angles(0.3 * k, 0, -wobble),
				Neck = angles(0.55 * k, 0, 0),
				RightShoulder = angles(0.6 * k, 0, 0.9 * k),
				LeftShoulder = angles(0.6 * k, 0, -0.9 * k),
				RightElbow = angles(0.4 * k, 0, 0),
				LeftElbow = angles(0.4 * k, 0, 0),
				RightHip = angles(-0.25 * k, 0, 0),
				LeftHip = angles(0.3 * k, 0, 0),
				RightKnee = angles(-0.35 * k, 0, 0),
				LeftKnee = angles(-0.55 * k, 0, 0),
			}
		end,
	},
	-- Golpe parado con la guardia: retrocede un poco
	BlockHit = {
		Duration = 0.25,
		Pose = function(t: number): Pose
			local k = bell(t)
			-- La guardia se va hacia la cara con el impacto y el cuerpo cede un poco
			return {
				Waist = angles(0.22 * k, 0, 0),
				Neck = angles(0.14 * k, 0, 0),
				Root = angles(0.06 * k, 0, 0),
				RightShoulder = angles(-0.35 * k, 0, 0),
				LeftShoulder = angles(-0.35 * k, 0, 0),
			}
		end,
	},
	-- Patada a la pelota
	Kick = {
		Duration = 0.55,
		Pose = function(t: number): Pose
			local back = strike(t, 0.25, 0.3) * (if t < 0.3 then 1 else 0)
			local swing = strike((t - 0.25) / 0.75, 0.25, 0.4)
			return {
				RightHip = angles(-0.6 * back + 1.15 * swing, 0, 0),
				RightKnee = angles(-1.1 * back - 0.15 * swing, 0, 0),
				LeftKnee = angles(-0.25 * (back + swing), 0, 0),
				Waist = angles(0.2 * swing, 0.1 * swing, 0),
				LeftShoulder = angles(0.6 * swing, 0, -0.5 * swing),
				RightShoulder = angles(-0.4 * swing, 0, 0.35 * swing),
				Neck = angles(-0.25 * swing, 0, 0),
			}
		end,
	},
	-- Tropiezo con una piedra
	Trip = {
		Duration = 0.9,
		Pose = function(t: number): Pose
			local k = strike(t, 0.2, 0.45)
			local step = strike((t - 0.2) / 0.6, 0.4, 0.6)
			return {
				Root = angles(-0.45 * k, 0, 0.05 * k),
				Neck = angles(0.35 * k, 0, 0),
				RightShoulder = angles(1.25 * k, 0, 0.45 * k),
				LeftShoulder = angles(1.15 * k, 0, -0.5 * k),
				RightElbow = angles(0.35 * k, 0, 0),
				LeftElbow = angles(0.35 * k, 0, 0),
				RightHip = angles(-0.55 * k + 0.5 * step, 0, 0),
				RightKnee = angles(-0.7 * k, 0, 0),
				LeftHip = angles(0.55 * step, 0, 0),
				LeftKnee = angles(-0.4 * step, 0, 0),
			}
		end,
	},
	-- Alcanzar algo con la mano derecha (al usar un cartel). opts.Height: -1 abajo … 1 arriba
	Reach = {
		Duration = 0.6,
		Pose = function(t: number, opts): Pose
			local k = strike(t, 0.35, 0.6)
			local h = math.clamp(opts.Height or 0, -1, 1)
			return {
				RightShoulder = angles((1.25 + 0.45 * h) * k, 0, 0.12 * k),
				RightElbow = angles(0.3 * k * (1 - bell(t)) + 0.1 * k, 0, 0),
				Waist = angles((-0.06 + 0.04 * h) * k, 0.12 * k, 0),
				Neck = angles(0.2 * h * k, 0.1 * k, 0),
				LeftShoulder = angles(0.12 * k, 0, -0.08 * k),
			}
		end,
	},
	-- Coger algo del suelo: se agacha (rodillas y cintura), recoge con la derecha y se levanta
	PickUp = {
		Duration = 0.85,
		Pose = function(t: number): Pose
			local k = strike(t, 0.35, 0.55)
			return {
				Root = CFrame.new(0, -0.95 * k, 0) * angles(-0.2 * k, 0, 0),
				Waist = angles(-0.5 * k, 0, 0),
				Neck = angles(-0.15 * k, 0, 0),
				RightHip = angles(0.95 * k, 0, 0),
				LeftHip = angles(0.75 * k, 0, 0),
				RightKnee = angles(-1.35 * k, 0, 0),
				LeftKnee = angles(-1.1 * k, 0, 0),
				RightShoulder = angles(0.75 * k, 0, 0.1 * k),
				RightElbow = angles(0.15 * k, 0, 0),
				LeftShoulder = angles(0.3 * k, 0, -0.15 * k),
			}
		end,
	},
	-- Comer: la mano derecha a la boca, dos bocados
	Eat = {
		Duration = 1.3,
		Pose = function(t: number): Pose
			local k = strike(t, 0.2, 0.8)
			local bite = abs(sin(t * pi * 4)) * k
			return {
				RightShoulder = angles((1.05 + 0.12 * bite) * k, 0, -0.35 * k),
				RightElbow = angles(2.0 * k, 0, 0),
				Neck = angles(-0.1 * bite, 0, 0),
				Waist = angles(-0.04 * k, 0, 0),
			}
		end,
	},
	-- Beber: el vaso a la boca y la cabeza hacia atrás
	Drink = {
		Duration = 1.15,
		Pose = function(t: number): Pose
			local k = strike(t, 0.25, 0.75)
			local sip = strike((t - 0.3) / 0.45, 0.3, 0.7)
			return {
				RightShoulder = angles((1.0 + 0.3 * sip) * k, 0, -0.3 * k),
				RightElbow = angles(1.9 * k, 0, 0),
				Neck = angles(0.35 * sip, 0, 0),
				Waist = angles(0.06 * sip, 0, 0),
			}
		end,
	},
	-- Lanzar (piedras): el brazo atrás por encima del hombro y latigazo hacia delante
	Throw = {
		Duration = 0.6,
		Pose = function(t: number): Pose
			local back = strike(t, 0.3, 0.38) * (if t < 0.38 then 1 else 0)
			local fwd = strike((t - 0.3) / 0.7, 0.25, 0.45)
			local g = bell(t)
			return {
				RightShoulder = angles(2.5 * back + 1.35 * fwd, 0, 0.2 * back),
				RightElbow = angles(1.4 * back + 0.1 * fwd, 0, 0),
				LeftShoulder = angles(0.9 * g, 0, -0.2 * g),
				Waist = angles(0.12 * back - 0.15 * fwd, -0.4 * back + 0.35 * fwd, 0),
				Root = angles(-0.08 * fwd, 0, 0),
				RightHip = angles(-0.2 * back + 0.15 * fwd, 0, 0),
				LeftHip = angles(0.3 * back, 0, 0),
			}
		end,
	},
	-- Lanzar la caña: atrás por encima de la cabeza con las dos manos y hacia delante
	Cast = {
		Duration = 0.95,
		Pose = function(t: number): Pose
			local back = strike(t, 0.32, 0.42) * (if t < 0.42 then 1 else 0)
			local fwd = strike((t - 0.34) / 0.66, 0.2, 0.45)
			return {
				RightShoulder = angles(2.3 * back + 0.5 * fwd, 0, 0),
				LeftShoulder = angles(1.9 * back + 0.4 * fwd, 0, 0),
				RightElbow = angles(0.9 * back, 0, 0),
				LeftElbow = angles(1.1 * back, 0, 0),
				Waist = angles(0.18 * back - 0.22 * fwd, 0, 0),
				Root = angles(0.05 * back - 0.1 * fwd, 0, 0),
			}
		end,
	},
	-- Tirar de la caña: un tirón hacia atrás
	Reel = {
		Duration = 0.45,
		Pose = function(t: number): Pose
			local k = strike(t, 0.3, 0.45)
			return {
				RightShoulder = angles(0.45 * k, 0, 0),
				LeftShoulder = angles(0.4 * k, 0, 0),
				RightElbow = angles(0.6 * k, 0, 0),
				LeftElbow = angles(0.6 * k, 0, 0),
				Waist = angles(0.22 * k, 0, 0),
				Root = angles(0.08 * k, 0, 0),
			}
		end,
	},
	-- Aterrizar: se agacha un poco (opts.Strength 0..1, según la altura de la caída)
	Land = {
		Duration = 0.45,
		Pose = function(t: number, opts): Pose
			local s = math.clamp(opts.Strength or 0.5, 0, 1)
			local k = strike(t, 0.16, 0.3) * s
			return {
				Root = CFrame.new(0, -0.75 * k, 0) * angles(-0.12 * k, 0, 0),
				Waist = angles(-0.2 * k, 0, 0),
				Neck = angles(0.12 * k, 0, 0),
				RightHip = angles(0.6 * k, 0, 0),
				LeftHip = angles(0.6 * k, 0, 0),
				RightKnee = angles(-1.05 * k, 0, 0),
				LeftKnee = angles(-1.05 * k, 0, 0),
				RightShoulder = angles(0.25 * k, 0, 0.3 * k),
				LeftShoulder = angles(0.25 * k, 0, -0.3 * k),
			}
		end,
	},
	-- Voltereta al caer de alto corriendo (o tras un salto de parkour): se hace bola y rueda hacia delante
	Roll = {
		Duration = 0.8,
		Pose = function(t: number): Pose
			local k = bell(t)
			local x = math.clamp(t, 0, 1)
			local spin = -2 * pi * x * x * (3 - 2 * x)
			return {
				Root = CFrame.new(0, -1.3 * k, 0) * angles(spin, 0, 0),
				Neck = angles(-0.6 * k, 0, 0),
				Waist = angles(-0.4 * k, 0, 0),
				RightShoulder = angles(1.3 * k, 0, 0.2 * k),
				LeftShoulder = angles(1.3 * k, 0, -0.2 * k),
				RightElbow = angles(1.2 * k, 0, 0),
				LeftElbow = angles(1.2 * k, 0, 0),
				RightHip = angles(1.8 * k, 0, 0),
				LeftHip = angles(1.8 * k, 0, 0),
				RightKnee = angles(-2.0 * k, 0, 0),
				LeftKnee = angles(-2.0 * k, 0, 0),
			}
		end,
	},
	-- Caída desde muy alto: se dobla del todo, se va hacia delante con los brazos fuera y se recupera
	Stumble = {
		Duration = 1.15,
		Pose = function(t: number): Pose
			local k = strike(t, 0.12, 0.4)
			local wobble = sin(t * 15) * (1 - t) * 0.35 * k
			local step = strike((t - 0.25) / 0.6, 0.35, 0.6)
			return {
				Root = CFrame.new(0, -1.1 * k, 0) * angles(-0.38 * k, 0, 0.12 * wobble),
				Waist = angles(-0.25 * k, 0, -0.1 * wobble),
				Neck = angles(0.4 * k, 0, 0),
				RightHip = angles(0.95 * k + 0.35 * step, 0, 0),
				LeftHip = angles(0.8 * k, 0, 0),
				RightKnee = angles(-1.45 * k, 0, 0),
				LeftKnee = angles(-1.3 * k + 0.3 * step, 0, 0),
				RightShoulder = angles(0.9 * k + wobble, 0, 0.7 * k),
				LeftShoulder = angles(0.9 * k - wobble, 0, -0.7 * k),
				RightElbow = angles(0.3 * k, 0, 0),
				LeftElbow = angles(0.3 * k, 0, 0),
			}
		end,
	},
}

-- ¿Qué gesto hace el cuerpo al usar un cartel "pulsa E"? (función pura)
-- text: lo que pone el cartel ("Comer", "Recoger objeto"…); height: dónde está el objeto respecto a
-- la cintura (-1 en el suelo … 1 por encima de la cabeza). nil = ninguno (sentarse, montar, hablar…:
-- de esos se encarga su propia animación).
local NO_GESTURE = {
	"sentar", "montar", "conducir", "subir", "bajar", "hablar", "saludar", "dormir", "descansar",
	"tumbar", "nadar", "bucear", "pescar", "bailar", "jugar", "conversar", "preguntar",
}
local EAT = { "comer", "desayunar", "cenar", "merendar", "almorzar", "probar", "morder" }
local DRINK = { "beber", "tomar", "brindar" }
-- Bebidas (palabras enteras: "agua" sí, "aguacate" no)
local DRINKS = { "cafe", "zumo", "refresco", "batido", "leche", "agua", "cola", "limonada", "te", "infusion", "cacao", "horchata", "bebida", "cafes", "zumos", "refrescos", "batidos" }
local PICK = { "coger", "recoger", "levantar", "agarrar" }
-- Coger algo de comer ("Coger comida", "Coger fruta"): se come (palabras enteras)
local FOODS = { "comida", "fruta", "bocadillo", "menu", "merienda", "almuerzo", "bandeja" }
local ACCENTS = { ["á"] = "a", ["é"] = "e", ["í"] = "i", ["ó"] = "o", ["ú"] = "u", ["ñ"] = "n" }

local function hasWord(text: string, words: { string }): boolean
	for _, word in words do
		if string.find(text, word, 1, true) then
			return true
		end
	end
	return false
end

local function hasWholeWord(text: string, words: { string }): boolean
	for _, word in words do
		if string.find(text, "%f[%a]" .. word .. "%f[%A]") then
			return true
		end
	end
	return false
end

local function plainText(text: string?): string
	local plain = string.lower(text or "")
	for accented, letter in ACCENTS do
		plain = string.gsub(plain, accented, letter)
	end
	return plain
end

function ReactMotion.gestureFor(text: string?, height: number?): string?
	local plain = plainText(text)
	local h = math.clamp(height or 0, -1, 1)
	if hasWord(plain, NO_GESTURE) then
		return nil
	elseif hasWord(plain, EAT) then
		return "Eat"
	elseif hasWord(plain, DRINK) or hasWholeWord(plain, DRINKS) then
		return "Drink"
	elseif hasWord(plain, PICK) and hasWholeWord(plain, FOODS) then
		return "Eat"
	elseif hasWord(plain, PICK) then
		return if h < -0.35 then "PickUp" else "Reach"
	end
	return if h < -0.6 then "PickUp" else "Reach"
end

-- Comer algo de la mochila: ¿se bebe o se come? (por su nombre; función pura)
function ReactMotion.foodGesture(name: string?): string
	return if hasWholeWord(plainText(name), DRINKS) then "Drink" else "Eat"
end

-- Posturas que se mantienen mientras dure la situación (peso 0..1 y la fase del paso)
ReactMotion.Holds = {
	Guard = function(w: number, _phase: number): Pose
		return merge(guardRight(w), guardLeft(w), { RightShoulder = angles(0.25 * w, 0, 0), LeftShoulder = angles(0.25 * w, 0, 0), Neck = angles(-0.15 * w, 0, 0), Waist = angles(-0.08 * w, 0, 0) })
	end,
	-- Arena: pasos pesados, rodillas más dobladas, algo inclinado hacia delante
	Sand = function(w: number, phase: number): Pose
		local s = abs(sin(phase))
		return {
			Root = angles(-0.1 * w, 0, 0),
			RightKnee = angles(-0.25 * w * (0.5 + s), 0, 0),
			LeftKnee = angles(-0.25 * w * (1.5 - s), 0, 0),
			RightHip = angles(0.12 * w, 0, 0),
			LeftHip = angles(0.12 * w, 0, 0),
			RightShoulder = angles(0, 0, 0.12 * w),
			LeftShoulder = angles(0, 0, -0.12 * w),
		}
	end,
	-- Arbustos: brazos delante apartando ramas
	Bush = function(w: number, phase: number): Pose
		local s = sin(phase * 1.3)
		return {
			RightShoulder = angles((0.95 + 0.25 * s) * w, 0, (0.25 + 0.15 * s) * w),
			LeftShoulder = angles((0.95 - 0.25 * s) * w, 0, -(0.25 - 0.15 * s) * w),
			RightElbow = angles(0.55 * w, 0, 0),
			LeftElbow = angles(0.55 * w, 0, 0),
			Waist = angles(-0.08 * w, 0.18 * s * w, 0),
			Neck = angles(-0.12 * w, 0, 0),
		}
	end,
	-- Linterna: el brazo derecho delante, a la altura del pecho, iluminando
	Flashlight = function(w: number, _phase: number): Pose
		return {
			RightShoulder = angles(1.15 * w, 0, -0.15 * w),
			RightElbow = angles(0.75 * w, 0, 0),
		}
	end,
	-- Caña de pescar: sujeta delante con las dos manos, subiendo y bajando un poco
	Rod = function(w: number, phase: number): Pose
		local bob = sin(phase * 0.5) * 0.04 * w
		return {
			RightShoulder = angles(0.95 * w + bob, 0, -0.1 * w),
			LeftShoulder = angles(0.8 * w + bob, 0, 0.25 * w),
			RightElbow = angles(0.7 * w, 0, 0),
			LeftElbow = angles(1.0 * w, 0, 0),
			Waist = angles(-0.04 * w, 0, 0),
		}
	end,
	-- Charco: rodillas altas al pisar el agua, brazos un poco abiertos
	Splash = function(w: number, phase: number): Pose
		local r = math.max(0, sin(phase))
		local l = math.max(0, -sin(phase))
		return {
			RightHip = angles(0.45 * r * w, 0, 0),
			LeftHip = angles(0.45 * l * w, 0, 0),
			RightKnee = angles(-0.6 * r * w, 0, 0),
			LeftKnee = angles(-0.6 * l * w, 0, 0),
			RightShoulder = angles(0, 0, 0.3 * w),
			LeftShoulder = angles(0, 0, -0.3 * w),
			Neck = angles(-0.2 * w, 0, 0),
		}
	end,
}

-- Suma de todo lo que le pasa a un personaje en este momento (función pura)
function ReactMotion.combine(active: { { Kind: string, T: number, Opts: { [string]: any } } }, holds: { [string]: number }, phase: number): Pose
	local poses = {}
	for _, a in active do
		local kind = ReactMotion.Kinds[a.Kind]
		if kind and a.T >= 0 and a.T <= 1 then
			table.insert(poses, kind.Pose(a.T, a.Opts or {}))
		end
	end
	for name, w in holds do
		local hold = ReactMotion.Holds[name]
		if hold and w > 0.001 then
			table.insert(poses, hold(w, phase))
		end
	end
	return merge(table.unpack(poses))
end

---------------------------------------------------------------------
-- Aplicar a los personajes
---------------------------------------------------------------------

local JOINTS = {
	Root = "LowerTorso",
	Waist = "UpperTorso",
	Neck = "Head",
	RightShoulder = "RightUpperArm",
	LeftShoulder = "LeftUpperArm",
	RightElbow = "RightLowerArm",
	LeftElbow = "LeftLowerArm",
	RightHip = "RightUpperLeg",
	LeftHip = "LeftUpperLeg",
	RightKnee = "RightLowerLeg",
	LeftKnee = "LeftLowerLeg",
}

type Body = {
	Model: Model,
	Humanoid: Humanoid,
	Root: BasePart,
	Joints: { [string]: any }, -- Motor6D o AnimationConstraint (los dos tienen Transform)
	Active: { { Kind: string, Start: number, Duration: number, Opts: { [string]: any } } },
	Want: { [string]: boolean }, -- posturas mantenidas que tocan ahora
	Holds: { [string]: number }, -- su peso (suavizado)
	Phase: number,
	Cooldown: { [string]: number },
}

local bodies: { [Model]: Body } = {}

local function bodyOf(model: Model?): Body?
	if not model or not model.Parent then
		return nil
	end
	local body = bodies[model]
	if body then
		return body
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return nil
	end
	local joints = {}
	for name, partName in JOINTS do
		local p = model:FindFirstChild(partName)
		local motor = p and p:FindFirstChild(name)
		-- Con las articulaciones nuevas de Roblox los Motor6D pasan a ser AnimationConstraint
		if motor and (motor:IsA("Motor6D") or motor:IsA("AnimationConstraint")) then
			joints[name] = motor
		end
	end
	if not joints.RightShoulder or not joints.LeftShoulder then
		return nil -- sin brazos que mover: quien llama usa una animación normal de Roblox
	end
	body = {
		Model = model,
		Humanoid = humanoid,
		Root = root :: BasePart,
		Joints = joints,
		Active = {},
		Want = {},
		Holds = {},
		Phase = 0,
		Cooldown = {},
	}
	bodies[model] = body
	model.AncestryChanged:Connect(function(_, parent)
		if not parent then
			bodies[model] = nil
		end
	end)
	return body
end

-- Reproduce una reacción corta en un personaje (se ve en tu pantalla).
-- Devuelve false si ese personaje no se puede mover así (R6 o sin articulaciones).
function ReactMotion.play(model: Model?, kind: string, opts: { [string]: any }?): boolean
	local body = bodyOf(model)
	local def = ReactMotion.Kinds[kind]
	if not body or not def then
		return false
	end
	-- La misma reacción no se repite encima de sí misma: vuelve a empezar
	for i = #body.Active, 1, -1 do
		if body.Active[i].Kind == kind then
			table.remove(body.Active, i)
		end
	end
	table.insert(body.Active, { Kind = kind, Start = os.clock(), Duration = def.Duration * ((opts and opts.Speed) or 1), Opts = opts or {} })
	return true
end

function ReactMotion.hold(model: Model?, name: string, on: boolean)
	local body = bodyOf(model)
	if body then
		body.Want[name] = on or nil
	end
end

local function apply(body: Body, now: number, dt: number)
	-- Fase del paso (según la velocidad)
	local v = body.Root.AssemblyLinearVelocity
	local speed = math.min(Vector3.new(v.X, 0, v.Z).Magnitude, 30)
	body.Phase = (body.Phase + dt * speed * 0.42) % (pi * 2)
	-- Pesos de las posturas mantenidas (entran y salen suave)
	for name in ReactMotion.Holds do
		local target = if body.Want[name] then 1 else 0
		local w = body.Holds[name] or 0
		w += (target - w) * math.min(1, dt * (if target > w then 8 else 5))
		body.Holds[name] = if w > 0.001 or target > 0 then w else nil
	end
	local active = {}
	for i = #body.Active, 1, -1 do
		local a = body.Active[i]
		local t = (now - a.Start) / a.Duration
		if t > 1 then
			table.remove(body.Active, i)
		else
			table.insert(active, { Kind = a.Kind, T = t, Opts = a.Opts })
		end
	end
	local anyHold = next(body.Holds) ~= nil
	if #active == 0 and not anyHold then
		-- Nada que hacer: las articulaciones vuelven solas a la animación (PoseLayers)
		return
	end
	local pose = ReactMotion.combine(active, body.Holds, body.Phase)
	for name, joint in body.Joints do
		local offset = pose[name]
		if offset then
			Layers.write(joint, offset * Layers.read(joint))
		end
	end
end

---------------------------------------------------------------------
-- Choques al andar: pelotas, piedras, arena, arbustos y charcos
---------------------------------------------------------------------

local CELL = 40
local bushGrid: { [string]: { BasePart } } = {}
local stones: { [BasePart]: boolean } = {}
local ROCKY = { [Enum.Material.Rock] = true, [Enum.Material.Slate] = true, [Enum.Material.Basalt] = true, [Enum.Material.Pebble] = true }

local function cellKey(x: number, z: number): string
	return math.floor(x / CELL) .. ":" .. math.floor(z / CELL)
end

local function addBush(inst: Instance)
	local part: BasePart? = nil
	if inst:IsA("BasePart") and (inst.Name == "Bush" or inst.Name == "Hedge") then
		part = inst
	elseif inst:IsA("Model") and inst.Name == "Bush" then
		-- Arbusto de la biblioteca de modelos: cuenta su pieza más grande
		for _, d in inst:GetDescendants() do
			if d:IsA("BasePart") and (not part or d.Size.Magnitude > part.Size.Magnitude) then
				part = d
			end
		end
	end
	if part then
		local key = cellKey(part.Position.X, part.Position.Z)
		bushGrid[key] = bushGrid[key] or {}
		table.insert(bushGrid[key], part)
	end
end

local function addStone(part: Instance)
	if part:IsA("BasePart") and (part:HasTag("Piedra") or (part.Name == "Rock" and part.Size.Y < 3)) then
		stones[part] = true
	end
end

local function nearBush(position: Vector3): BasePart?
	local cx, cz = math.floor(position.X / CELL), math.floor(position.Z / CELL)
	for dx = -1, 1 do
		for dz = -1, 1 do
			for _, bush in bushGrid[(cx + dx) .. ":" .. (cz + dz)] or {} do
				if bush.Parent then
					local rel = bush.CFrame:PointToObjectSpace(position)
					local half = bush.Size / 2 + Vector3.new(1.2, 2, 1.2)
					if abs(rel.X) < half.X and abs(rel.Y) < half.Y + 1 and abs(rel.Z) < half.Z then
						return bush
					end
				end
			end
		end
	end
	return nil
end

-- El arbusto se sacude (solo en tu pantalla) y suelta unas hojas
local shaking: { [BasePart]: number } = {}
local function shakeBush(bush: BasePart)
	if shaking[bush] and os.clock() - shaking[bush] < 0.6 then
		return
	end
	shaking[bush] = os.clock()
	local home = bush.CFrame
	task.spawn(function()
		for i = 1, 8 do
			if not bush.Parent then
				return
			end
			local a = (1 - i / 8) * 0.08
			bush.CFrame = home * CFrame.Angles(a * sin(i * 2.3), 0, a * sin(i * 3.1))
			task.wait(0.04)
		end
		bush.CFrame = home
	end)
	local leaves = Instance.new("ParticleEmitter")
	leaves.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	leaves.Color = ColorSequence.new(bush.Color)
	leaves.Size = NumberSequence.new(0.25)
	leaves.Lifetime = NumberRange.new(0.6, 1.1)
	leaves.Speed = NumberRange.new(2, 4)
	leaves.SpreadAngle = Vector2.new(60, 60)
	leaves.Acceleration = Vector3.new(0, -8, 0)
	leaves.Enabled = false
	leaves.Parent = bush
	leaves:Emit(6)
	task.delay(1.5, function()
		leaves:Destroy()
	end)
end

-- Polvo de arena o salpicadura de agua en los pies
local function puff(at: Vector3, color: Color3, count: number)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.CFrame = CFrame.new(at)
	p.Parent = workspace.CurrentCamera
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.7) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.35, 0.6)
	e.Speed = NumberRange.new(2, 5)
	e.SpreadAngle = Vector2.new(70, 70)
	e.Acceleration = Vector3.new(0, -12, 0)
	e.Enabled = false
	e.Parent = p
	e:Emit(count)
	task.delay(1, function()
		p:Destroy()
	end)
end

local function puddleUnder(position: Vector3): boolean
	local folder = workspace:FindFirstChild("WetWorld") or (workspace.CurrentCamera and workspace.CurrentCamera:FindFirstChild("WetWorld"))
	if not folder then
		return false
	end
	for _, p in folder:GetChildren() do
		if p.Name == "Charco" and p:IsA("BasePart") and p.Transparency < 0.95 then
			local d = Vector3.new(position.X - p.Position.X, 0, position.Z - p.Position.Z).Magnitude
			if d < p.Size.Y / 2 and abs(position.Y - p.Position.Y) < 5 then
				return true
			end
		end
	end
	return false
end

local downParams = RaycastParams.new()
downParams.FilterType = Enum.RaycastFilterType.Exclude
downParams.IgnoreWater = true

local function surroundings(body: Body)
	local root = body.Root
	local v = root.AssemblyLinearVelocity
	local flat = Vector3.new(v.X, 0, v.Z)
	local speed = flat.Magnitude
	local moving = speed > 2 and body.Humanoid.SeatPart == nil
	local feet = root.Position - Vector3.new(0, body.Humanoid.HipHeight + root.Size.Y / 2 - 0.3, 0)
	local now = os.clock()
	-- Linterna encendida (se ve en todos): el brazo delante; no conduciendo ni sentado
	local owner = Players:GetPlayerFromCharacter(body.Model)
	body.Want.Flashlight = (owner ~= nil and owner:GetAttribute("Flashlight") == true and body.Humanoid.SeatPart == nil and owner:GetAttribute("Riding") == nil) or nil
	-- Suelo: arena
	downParams.FilterDescendantsInstances = { body.Model, workspace.CurrentCamera }
	local ground = workspace:Raycast(root.Position, Vector3.new(0, -(body.Humanoid.HipHeight + root.Size.Y / 2 + 1.5), 0), downParams)
	local onSand = ground ~= nil and ground.Material == Enum.Material.Sand
	body.Want.Sand = (onSand and moving) or nil
	if onSand and moving and now - (body.Cooldown.Sand or 0) > 0.32 then
		body.Cooldown.Sand = now
		puff(feet, Color3.fromRGB(226, 206, 160), 5)
	end
	-- Charcos
	local inPuddle = moving and puddleUnder(feet)
	body.Want.Splash = inPuddle or nil
	if inPuddle and now - (body.Cooldown.Splash or 0) > 0.3 then
		body.Cooldown.Splash = now
		puff(feet + Vector3.new(0, 0.2, 0), Color3.fromRGB(170, 200, 230), 9)
	end
	-- Arbustos
	local bush = nearBush(root.Position)
	body.Want.Bush = (bush ~= nil and moving) or nil
	if bush and moving then
		shakeBush(bush)
	end
	if not moving then
		return
	end
	local dir = flat.Unit
	-- Pelotas: si vas hacia ella y la tocas, patada
	if now - (body.Cooldown.Kick or 0) > 0.9 then
		for _, toy in CollectionService:GetTagged("Toy") do
			if toy:IsA("BasePart") then
				local rel = toy.Position - feet
				local d = Vector3.new(rel.X, 0, rel.Z)
				if d.Magnitude < 3.2 and abs(rel.Y) < 3 and d.Unit:Dot(dir) > 0.4 then
					body.Cooldown.Kick = now
					ReactMotion.play(body.Model, "Kick")
					break
				end
			end
		end
	end
	-- Piedras: tropiezo (corriendo o andando hacia ella)
	if speed > 7 and now - (body.Cooldown.Trip or 0) > 2.5 then
		for stone in stones do
			if stone.Parent then
				local rel = stone.Position - feet
				local d = Vector3.new(rel.X, 0, rel.Z)
				local reach = math.max(stone.Size.X, stone.Size.Z) / 2 + 1.3
				if d.Magnitude < reach and d.Magnitude > 0 and d.Unit:Dot(dir) > 0.3 and abs(rel.Y) < 2.5 then
					body.Cooldown.Trip = now
					ReactMotion.play(body.Model, "Trip")
					if body.Model == (Players.LocalPlayer.Character :: Model?) then
						-- Tu personaje (lo mueve tu dispositivo): un traspiés hacia delante
						root.AssemblyLinearVelocity = Vector3.new(v.X * 0.5, v.Y, v.Z * 0.5) + dir * 6
					end
					break
				end
			else
				stones[stone] = nil
			end
		end
	end
	-- Roca del terreno justo delante de los pies (a la altura de los tobillos)
	if speed > 9 and now - (body.Cooldown.Trip or 0) > 2.5 then
		local hit = workspace:Raycast(feet + Vector3.new(0, 0.4, 0), dir * 1.8, downParams)
		if hit and ROCKY[hit.Material] and hit.Instance and hit.Instance:IsA("BasePart") and hit.Instance.Size.Y < 3 then
			body.Cooldown.Trip = now
			ReactMotion.play(body.Model, "Trip")
		end
	end
end

---------------------------------------------------------------------

function ReactMotion.init()
	for _, d in workspace:GetDescendants() do
		addBush(d)
		addStone(d)
	end
	workspace.DescendantAdded:Connect(function(d)
		addBush(d)
		addStone(d)
	end)
	-- Se aplica después de las animaciones, de AgeMotion y de Locomotion (capa 30 de PoseLayers)
	Layers = require(script.Parent.PoseLayers)
	Layers.add("ReactMotion", 30, function(dt, now)
		for model, body in bodies do
			if not model.Parent or body.Humanoid.Health <= 0 then
				bodies[model] = nil
			else
				local ok, err = pcall(apply, body, now, dt)
				if not ok then
					warn("[ReactMotion] " .. tostring(err))
					bodies[model] = nil
				end
			end
		end
	end)
	-- Los choques se miran 7 veces por segundo, para los jugadores cercanos
	task.spawn(function()
		while true do
			task.wait(0.14)
			local me = Players.LocalPlayer.Character
			local myRoot = me and me:FindFirstChild("HumanoidRootPart") :: BasePart?
			for _, other in Players:GetPlayers() do
				local character = other.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root and (not myRoot or (root.Position - myRoot.Position).Magnitude < 80) then
					local body = bodyOf(character)
					if body then
						local ok, err = pcall(surroundings, body)
						if not ok then
							warn("[ReactMotion] " .. tostring(err))
						end
					end
				end
			end
		end
	end)
end

return ReactMotion
