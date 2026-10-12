-- SportAnim (cliente): los gestos del deporte (chutar, pasar, entrar en plancha, estirarse, tirar a
-- canasta…) como golpes de PunchAnim: mismas articulaciones (C0), misma mezcla con la animación de
-- andar y correr, y se ven en todos los cuerpos (tú, los demás jugadores y las máquinas).
--
--   SportAnim.register()            añade los gestos a PunchAnim.Moves (una vez)
--   SportAnim.play(model, "Chute")  Chute | Pase | Plancha | Estirada | Tiro | Bandeja | Celebrar
--
-- Las posturas son funciones puras de t (0..1): se pueden probar fuera de Roblox.

local PunchAnim = require(script.Parent.PunchAnim)

local SportAnim = {}

local angles = CFrame.Angles
local sin, pi = math.sin, math.pi

local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- Los tres tiempos de un gesto (como PunchAnim): a = preparación, k = golpe, g = presencia
local function phases(t: number, wind: number, impact: number, hold: number): (number, number, number)
	return PunchAnim._phases(t, wind, impact, hold)
end

local function bell(t: number): number
	return sin(math.clamp(t, 0, 1) * pi)
end

SportAnim.Moves = {
	-- Chute: la pierna derecha atrás con la rodilla doblada, barre hacia delante con todo el cuerpo y
	-- sigue un poco hacia arriba (acompañar el golpeo); los brazos abiertos para equilibrar
	Chute = {
		Duration = 0.55,
		Impact = 0.36,
		Limb = "RightFoot",
		Reach = "Forward",
		Legs = true,
		Pose = function(t: number): { [string]: CFrame }
			local a, k, g = phases(t, 0.26, 0.36, 0.55)
			local follow = smooth((t - 0.36) / 0.2) * (1 - smooth((t - 0.6) / 0.4))
			return {
				Root = CFrame.new(0, -0.15 * g, -0.25 * k) * angles(0.12 * a - 0.1 * k, 0.25 * a - 0.15 * k, 0),
				RightHip = angles(-0.75 * a + 1.25 * k + 0.35 * follow, 0, 0),
				RightKnee = angles(-1.35 * a - 0.15 * k, 0, 0),
				LeftHip = angles(0.25 * g, 0, 0),
				LeftKnee = angles(-0.35 * g, 0, 0),
				Waist = angles(-0.12 * k + 0.1 * a, -0.2 * a + 0.15 * k, 0),
				Neck = angles(0.18 * g, 0, 0),
				RightShoulder = angles(-0.5 * g, 0, 0.55 * g),
				LeftShoulder = angles(0.55 * g, 0, -0.7 * g),
				LeftElbow = angles(0.4 * g, 0, 0),
			}
		end,
	},
	-- Pase: con el interior, la pierna gira hacia fuera y empuja corto
	Pase = {
		Duration = 0.4,
		Impact = 0.3,
		Limb = "RightFoot",
		Reach = "Forward",
		Legs = true,
		Pose = function(t: number): { [string]: CFrame }
			local a, k, g = phases(t, 0.18, 0.3, 0.5)
			return {
				Root = CFrame.new(0, -0.1 * g, 0) * angles(0, 0.2 * a - 0.1 * k, 0),
				RightHip = angles(-0.35 * a + 0.75 * k, 0.55 * g, 0),
				RightKnee = angles(-0.6 * a - 0.2 * k, 0, 0),
				LeftKnee = angles(-0.25 * g, 0, 0),
				Waist = angles(-0.05 * k, 0.1 * k, 0),
				Neck = angles(0.2 * g, 0, 0),
				LeftShoulder = angles(0.3 * g, 0, -0.4 * g),
				RightShoulder = angles(-0.2 * g, 0, 0.35 * g),
			}
		end,
	},
	-- Entrada en plancha: se tira al suelo deslizando con la pierna derecha por delante
	Plancha = {
		Duration = 0.7,
		Impact = 0.3,
		Limb = "RightFoot",
		Reach = "Forward",
		Legs = true,
		Pose = function(t: number): { [string]: CFrame }
			local _, k = phases(t, 0.12, 0.3, 0.72)
			return {
				Root = CFrame.new(0, -1.5 * k, 0.4 * k) * angles(0.95 * k, 0, 0.12 * k),
				RightHip = angles(1.2 * k, 0, 0),
				RightKnee = angles(-0.1 * k, 0, 0),
				LeftHip = angles(0.6 * k, 0, 0),
				LeftKnee = angles(-1.3 * k, 0, 0),
				Waist = angles(-0.35 * k, 0, 0),
				Neck = angles(0.45 * k, 0, 0),
				RightShoulder = angles(0.6 * k, 0, 0.4 * k),
				LeftShoulder = angles(-0.3 * k, 0, -0.9 * k),
			}
		end,
	},
	-- Estirada del portero: los dos brazos arriba y el cuerpo de lado
	Estirada = {
		Duration = 0.9,
		Impact = 0.35,
		Limb = "RightHand",
		Reach = "Up",
		Legs = true,
		Pose = function(t: number): { [string]: CFrame }
			local _, k = phases(t, 0.1, 0.35, 0.75)
			return {
				RightShoulder = angles(2.7 * k, 0, 0.25 * k),
				LeftShoulder = angles(2.7 * k, 0, -0.25 * k),
				RightElbow = angles(0.15 * k, 0, 0),
				LeftElbow = angles(0.15 * k, 0, 0),
				Waist = angles(-0.1 * k, 0, 0),
				RightHip = angles(0.3 * k, 0, 0),
				LeftKnee = angles(-0.6 * k, 0, 0),
			}
		end,
	},
	-- Tiro a canasta: flexiona las piernas, sube los brazos y suelta con la muñeca (salto pequeño)
	Tiro = {
		Duration = 0.7,
		Impact = 0.45,
		Limb = "RightHand",
		Reach = "Up",
		Legs = true,
		Pose = function(t: number): { [string]: CFrame }
			local a, k, g = phases(t, 0.3, 0.45, 0.7)
			local crouch = a
			return {
				Root = CFrame.new(0, -0.45 * crouch + 0.35 * k, 0),
				RightHip = angles(0.6 * crouch, 0, 0),
				LeftHip = angles(0.6 * crouch, 0, 0),
				RightKnee = angles(-1.1 * crouch, 0, 0),
				LeftKnee = angles(-1.1 * crouch, 0, 0),
				RightShoulder = angles(1.6 * g + 1.1 * k, 0, 0),
				RightElbow = angles(1.5 * g * (1 - k) + 0.1 * k, 0, 0),
				LeftShoulder = angles(1.5 * g + 0.5 * k, 0, -0.25 * g),
				LeftElbow = angles(1.2 * g, 0, 0),
				Neck = angles(0.25 * g, 0, 0),
			}
		end,
	},
	-- Bandeja: un paso largo, rodilla arriba y la mano derecha estirada hacia el aro
	Bandeja = {
		Duration = 0.75,
		Impact = 0.5,
		Limb = "RightHand",
		Reach = "Up",
		Legs = true,
		Pose = function(t: number): { [string]: CFrame }
			local a, k, g = phases(t, 0.3, 0.5, 0.7)
			return {
				Root = CFrame.new(0, 0.6 * k, -0.4 * k),
				LeftHip = angles(1.4 * (a + k) * 0.6, 0, 0),
				LeftKnee = angles(-1.6 * (a + k) * 0.6, 0, 0),
				RightShoulder = angles(1.2 * g + 1.6 * k, 0, 0),
				RightElbow = angles(0.6 * g * (1 - k), 0, 0),
				LeftShoulder = angles(0.6 * g, 0, -0.3 * g),
				Neck = angles(0.35 * k, 0, 0),
			}
		end,
	},
	-- Celebrar: puños arriba dos veces
	Celebrar = {
		Duration = 1.2,
		Impact = 0.3,
		Limb = "RightHand",
		Reach = "Up",
		Pose = function(t: number): { [string]: CFrame }
			local g = bell(t)
			local pump = 0.5 + 0.5 * sin(t * pi * 4)
			return {
				RightShoulder = angles(2.4 * g + 0.3 * pump * g, 0, 0.3 * g),
				LeftShoulder = angles(2.4 * g + 0.3 * pump * g, 0, -0.3 * g),
				RightElbow = angles(0.9 * g * (1 - pump), 0, 0),
				LeftElbow = angles(0.9 * g * (1 - pump), 0, 0),
				Neck = angles(-0.3 * g, 0, 0),
			}
		end,
	},
}

local registered = false
function SportAnim.register()
	if registered then
		return
	end
	registered = true
	for name, move in SportAnim.Moves do
		PunchAnim.Moves["Sport" .. name] = move :: any
	end
end

function SportAnim.play(model: Instance?, name: string): boolean
	if not model or not model:IsA("Model") or not SportAnim.Moves[name] then
		return false
	end
	SportAnim.register()
	local ok, played = pcall(PunchAnim.play, model, "Sport" .. name)
	return ok and played == true
end

return SportAnim
