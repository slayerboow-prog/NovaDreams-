-- BeastAnim: las bestias se MUEVEN como seres vivos (estilo MMORPG), solo en tu pantalla. El servidor las mueve
-- por el mapa (Services/BeastService) y les monta articulaciones Motor6D (World/Kit/BeastKit: «Cuerpo» en la
-- raíz, «J_Pata», «J_Pierna», «J_Brazo», «J_Ala», «J_Cola», «J_Cuerpo»); aquí solo se ajusta su Transform:
--
--   * Andar / correr: patas en diagonal (cuadrúpedos), piernas alternas (de pie), patas en trípode (insectos),
--     la serpiente ondula; el cuerpo sube y baja con cada paso y se inclina al correr. Al paso, lento; a la
--     carrera, rápido (según su velocidad de verdad).
--   * Quieta: respira (el cuerpo sube y baja un poco), mueve la cola; las que vuelan, aletean siempre.
--   * Alerta («!»): levanta la cabeza un instante. Prepara (carga, golpe de área, pisotón): se agacha y tiembla.
--   * Golpe (atributo Golpe que sube): se lanza hacia delante y vuelve (los colosos levantan los brazos y bajan).
--   * Le pegan (baja su vida): da un respingo hacia atrás.
--   * Cae (EnemyDown): se vuelca de lado y se hunde mientras se deshace.
-- Solo las cercanas (Range) y como mucho MaxAnimated a la vez.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local BeastAnim = {}

BeastAnim.Range = 220
BeastAnim.MaxAnimated = 40 -- (17-11-2026: hay muchas más bestias)

local player = Players.LocalPlayer

type Joint = { M: Motor6D, Name: string, Side: number, Front: number, Order: number }
type State = {
	Model: Model,
	Root: BasePart,
	Body: Motor6D?,
	Joints: { Joint },
	Shape: string,
	K: number,
	Flies: boolean,
	Phase: number,
	Speed: number,
	LastHp: number,
	Hurt: number, -- (cuándo le pegaron)
	Strike: number, -- (cuándo atacó)
	LastStrike: number,
	Down: number?,
	Seed: number,
}

local states: { [Model]: State } = {}

local function shapeOf(model: Model): string
	local form = model:GetAttribute("Forma")
	if typeof(form) == "string" then
		return form
	end
	-- (por sus piezas: lo que montó BeastKit)
	if model:FindFirstChild("Abdomen") then
		return "Insecto"
	elseif model:FindFirstChild("Pierna") then
		return "Bipedo"
	elseif model:FindFirstChild("Cuerpo") and not model:FindFirstChild("Pata") then
		return "Serpiente"
	end
	return "Cuadrupedo"
end

local function setup(model: Model): State?
	local root = model.PrimaryPart
	if not root then
		return nil
	end
	local joints: { Joint } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Motor6D") and string.sub(d.Name, 1, 2) == "J_" then
			table.insert(joints, {
				M = d,
				Name = string.sub(d.Name, 3),
				Side = tonumber(d:GetAttribute("Lado")) or 1,
				Front = tonumber(d:GetAttribute("Delante")) or 1,
				Order = tonumber(d:GetAttribute("Orden")) or 1,
			})
		end
	end
	local body = root:FindFirstChild("Cuerpo")
	return {
		Model = model,
		Root = root,
		Body = if body and body:IsA("Motor6D") then body else nil,
		Joints = joints,
		Shape = shapeOf(model),
		K = tonumber(model:GetAttribute("Escala")) or 1,
		Flies = model:GetAttribute("Vuela") == true,
		Phase = math.random() * 6.28,
		Speed = 0,
		LastHp = tonumber(model:GetAttribute("Hp")) or 0,
		Hurt = -10,
		Strike = -10,
		LastStrike = tonumber(model:GetAttribute("Golpe")) or 0,
		Down = nil,
		Seed = math.random() * 100,
	}
end

-- Cuánto queda de una animación corta (1 al empezar → 0 al acabar), con forma de «ida y vuelta»
local function pulse(since: number, length: number): number
	if since < 0 or since > length then
		return 0
	end
	return math.sin(since / length * math.pi)
end
BeastAnim.pulse = pulse

-- La postura de una articulación en este instante (aparte para las pruebas)
function BeastAnim.jointPose(shape: string, name: string, side: number, front: number, order: number, phase: number, move: number, t: number, flies: boolean, strike: number, crouch: number): CFrame
	local swing = math.sin(phase) * move
	if name == "Pata" and shape == "Insecto" then
		-- trípode: patas alternas barren adelante y atrás
		local alt = if order % 2 == 0 then 1 else -1
		return CFrame.Angles(0, swing * 0.5 * alt, math.sin(phase * 2) * 0.15 * move * side)
	elseif name == "Pata" then
		-- diagonales: delantera derecha con trasera izquierda
		local diag = if side * front > 0 then 1 else -1
		return CFrame.Angles(swing * 1.0 * diag - crouch * 0.45 * front + strike * 0.5 * front, 0, 0)
	elseif name == "Pierna" then
		return CFrame.Angles(swing * 0.95 * side - crouch * 0.55 - strike * 0.35 * side, 0, 0)
	elseif name == "Brazo" then
		-- brazos: contrarios a las piernas; al golpear, arriba y abajo
		-- (suben por delante hasta encima de la cabeza y caen: el tajo del arma, el golpe del coloso)
		local lift = strike * 2.2
		return CFrame.Angles(-swing * 0.75 * side + lift + crouch * 0.8, 0, side * (crouch * 0.25 + strike * 0.25))
	elseif name == "Ala" then
		local speed = if flies then 18 else 3
		local amp = if flies then 0.55 else 0.08 + move * 0.2
		return CFrame.Angles(0, 0, math.sin(t * speed + order) * amp * side)
	elseif name == "Cola" then
		return CFrame.Angles(math.sin(t * 2.2) * 0.1, math.sin(t * 3 + phase * 0.5) * (0.25 + move * 0.2), 0)
	elseif name == "Cuerpo" then
		-- serpiente: la onda recorre los anillos
		return CFrame.new(math.sin(phase * 1.2 - order * 0.9) * (0.25 + move * 0.35), 0, 0)
	end
	return CFrame.identity
end

-- El cuerpo entero: respirar, el paso, inclinarse al correr, lanzarse al morder, respingo y caer
function BeastAnim.bodyPose(k: number, phase: number, move: number, t: number, flies: boolean, strike: number, hurt: number, crouch: number, alert: number, down: number, shape: string): CFrame
	local breathe = math.sin(t * 2.1) * 0.05 * k
	-- (la masa —slime— avanza a saltitos)
	local step = math.abs(math.sin(phase)) * (if shape == "Masa" then 0.8 else 0.3) * k * move
	local hover = if flies then math.sin(t * 3) * 0.35 * k else 0
	local lean = -0.16 * move
	local y = breathe + step + hover - crouch * 0.35 * k
	local z = -strike * 1.5 * k + hurt * 0.7 * k
	local pitch = lean - strike * 0.4 + hurt * 0.35 + crouch * 0.18 + alert * 0.3
	-- (al trote se balancea de lado a lado)
	local roll = math.sin(phase) * 0.06 * move
	local shake = if crouch > 0 then math.sin(t * 40) * 0.05 * k * crouch else 0
	local cf = CFrame.new(shake, y, z) * CFrame.Angles(pitch, 0, roll)
	if down > 0 then
		-- cae de lado y se hunde
		cf = cf * CFrame.new(0, -down * 0.8 * k, 0) * CFrame.Angles(0, 0, down * math.rad(85))
	end
	if shape == "Serpiente" then
		cf = cf * CFrame.Angles(0, math.sin(phase * 1.2) * 0.08 * move, 0)
	end
	return cf
end

local function animate(s: State, dt: number, t: number)
	local m = s.Model
	local vel = s.Root.AssemblyLinearVelocity
	local flat = Vector3.new(vel.X, 0, vel.Z).Magnitude
	s.Speed += (flat - s.Speed) * math.min(1, dt * 8)
	local move = math.clamp(s.Speed / (6 * math.max(0.6, s.K)), 0, 1)
	-- (los pasos van más rápido cuanto más corre; las grandes, más lentas)
	s.Phase += dt * (2 + s.Speed * 0.55 / math.max(0.6, s.K))
	-- lo que ha pasado desde la última vez
	local hp = tonumber(m:GetAttribute("Hp")) or s.LastHp
	if hp < s.LastHp then
		s.Hurt = t
	end
	s.LastHp = hp
	local g = tonumber(m:GetAttribute("Golpe")) or 0
	if g ~= s.LastStrike then
		s.LastStrike = g
		s.Strike = t
	end
	if m:GetAttribute("EnemyDown") and not s.Down then
		s.Down = t
	end
	local strike = pulse(t - s.Strike, 0.38)
	local hurt = pulse(t - s.Hurt, 0.22)
	local crouch = if m:GetAttribute("Prepara") == true then 1 else 0
	local alert = if m:GetAttribute("Estado") == "Alerta" then 1 else 0
	local down = if s.Down then math.clamp((t - s.Down) / 0.6, 0, 1) else 0
	if s.Body then
		s.Body.Transform = BeastAnim.bodyPose(s.K, s.Phase, move, t + s.Seed, s.Flies, strike, hurt, crouch, alert, down, s.Shape)
	end
	for _, j in s.Joints do
		j.M.Transform = BeastAnim.jointPose(s.Shape, j.Name, j.Side, j.Front, j.Order, s.Phase, if down > 0 then 0 else move, t + s.Seed, s.Flies, strike, crouch)
	end
end

local function step(dt: number)
	local char = player.Character
	local me = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not me then
		return
	end
	local t = os.clock()
	local near = {}
	for _, m in CollectionService:GetTagged("Bestia") do
		if m:IsA("Model") and m.PrimaryPart then
			local d = (m.PrimaryPart.Position - me.Position).Magnitude
			if d <= BeastAnim.Range then
				table.insert(near, { M = m, D = d })
			end
		end
	end
	table.sort(near, function(a, b)
		return a.D < b.D
	end)
	local keep: { [Model]: boolean } = {}
	for i = 1, math.min(#near, BeastAnim.MaxAnimated) do
		local m = near[i].M :: Model
		local s = states[m]
		if not s or s.Root ~= m.PrimaryPart then
			s = setup(m)
			states[m] = s
		end
		if s then
			keep[m] = true
			local ok, err = pcall(animate, s, dt, t)
			if not ok then
				warn("[BeastAnim] " .. tostring(err))
				states[m] = nil
			end
		end
	end
	for m in states do
		if not keep[m] then
			states[m] = nil
		end
	end
end

function BeastAnim.init()
	RunService.RenderStepped:Connect(step)
end

BeastAnim._states = states
BeastAnim._step = step

return BeastAnim
