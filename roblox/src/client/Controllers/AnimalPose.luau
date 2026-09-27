-- AnimalPose (cliente): el cuerpo de cada animal (hecho con piezas) y cómo se mueve.
-- Wildlife decide dónde está y qué hace cada animal; aquí se colocan sus piezas.
--
--   * Andar: las patas giran desde la cadera; los de cuatro patas mueven a la vez la delantera de
--     un lado y la trasera del otro. El cuerpo sube y baja con cada paso. Las palomas y las
--     gallinas adelantan la cabeza a cada paso.
--   * Qué hacen cuando están quietos (Action):
--       Perro: de pie, sentado u olfateando el suelo. Mueve la cola, y mucho más si estás cerca.
--       Gato: de pie, sentado, tumbado o lamiéndose. La cola se mece despacio.
--       Vaca y oveja: pastan (cabeza abajo, rumiando) o miran alrededor; la cola espanta moscas.
--       Gallina: picotea o escarba con una pata. Paloma: picotea.
--       Pato: nada o mete la cabeza en el agua con la cola hacia arriba.
--   * Si te acercas, el perro, el gato, la vaca y la oveja te miran. Las orejas se mueven de vez
--     en cuando.
--
-- Se prueba fuera de Roblox: scripts/test-animals.luau

local AnimalPose = {}

export type Piece = { Part: BasePart, Offset: CFrame, Role: string? }

local rgb = Color3.fromRGB
local V = Vector3.new
local C = CFrame.new
local BALL = Enum.PartType.Ball
local sin, abs, clamp = math.sin, math.abs, math.clamp
local angles = CFrame.Angles

-- Carpeta donde se crean las piezas (la pone Wildlife: solo existe para este jugador)
AnimalPose.folder = nil :: Instance?

local function piece(list: { Piece }, size: Vector3, color: Color3, offset: CFrame, role: string?, shape: Enum.PartType?, material: Enum.Material?)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = AnimalPose.folder
	table.insert(list, { Part = p, Offset = offset, Role = role })
end

-- Modelos hechos con piezas (sin mallas: ligeros y siempre disponibles).
-- Roles: Head (se mueve con el cuello), Ear (con la cabeza, y se agita), Tail, Leg1..4
-- (1 delantera izq., 2 delantera dcha., 3 trasera izq., 4 trasera dcha.), WingL/WingR, Glow.
local BUILDERS: { [string]: (list: { Piece }) -> () } = {
	-- Pájaro pequeño (gorrión, golondrina)
	Pajaro = function(l)
		local body, wing = rgb(96, 74, 56), rgb(70, 54, 42)
		piece(l, V(0.5, 0.45, 0.8), body, C(0, 0, 0), nil, BALL)
		piece(l, V(0.36, 0.36, 0.36), body, C(0, 0.2, -0.42), nil, BALL)
		piece(l, V(0.08, 0.08, 0.18), rgb(230, 170, 60), C(0, 0.18, -0.64))
		piece(l, V(0.7, 0.05, 0.4), wing, C(-0.45, 0.08, 0), "WingL")
		piece(l, V(0.7, 0.05, 0.4), wing, C(0.45, 0.08, 0), "WingR")
		piece(l, V(0.25, 0.05, 0.4), wing, C(0, 0.05, 0.55))
	end,
	Gaviota = function(l)
		local body, wing = rgb(240, 240, 240), rgb(170, 176, 186)
		piece(l, V(0.8, 0.7, 1.4), body, C(0, 0, 0), nil, BALL)
		piece(l, V(0.55, 0.55, 0.55), body, C(0, 0.3, -0.7), nil, BALL)
		piece(l, V(0.12, 0.12, 0.35), rgb(240, 200, 60), C(0, 0.25, -1.05))
		piece(l, V(1.6, 0.06, 0.6), wing, C(-0.95, 0.12, 0), "WingL")
		piece(l, V(1.6, 0.06, 0.6), wing, C(0.95, 0.12, 0), "WingR")
		piece(l, V(0.4, 0.06, 0.5), wing, C(0, 0.08, 0.85))
	end,
	Paloma = function(l)
		local body, wing = rgb(150, 150, 160), rgb(120, 120, 132)
		piece(l, V(0.7, 0.65, 1), body, C(0, 0, 0), nil, BALL)
		piece(l, V(0.42, 0.42, 0.42), rgb(96, 110, 120), C(0, 0.35, -0.45), "Head", BALL)
		piece(l, V(0.08, 0.08, 0.2), rgb(60, 60, 60), C(0, 0.32, -0.72), "Head")
		piece(l, V(0.9, 0.05, 0.45), wing, C(-0.4, 0.15, 0.05), "WingL")
		piece(l, V(0.9, 0.05, 0.45), wing, C(0.4, 0.15, 0.05), "WingR")
		piece(l, V(0.3, 0.05, 0.45), wing, C(0, 0.1, 0.6), "Tail")
		piece(l, V(0.06, 0.35, 0.06), rgb(220, 110, 110), C(-0.15, -0.45, 0), "Leg1")
		piece(l, V(0.06, 0.35, 0.06), rgb(220, 110, 110), C(0.15, -0.45, 0), "Leg2")
	end,
	Mariposa = function(l)
		local colors = { rgb(250, 190, 40), rgb(120, 170, 250), rgb(250, 250, 250), rgb(240, 120, 60), rgb(200, 120, 230) }
		local color = colors[math.random(1, #colors)]
		piece(l, V(0.06, 0.06, 0.35), rgb(40, 30, 30), C(0, 0, 0))
		piece(l, V(0.4, 0.02, 0.35), color, C(-0.22, 0, 0), "WingL", nil, Enum.Material.Neon)
		piece(l, V(0.4, 0.02, 0.35), color, C(0.22, 0, 0), "WingR", nil, Enum.Material.Neon)
	end,
	Luciernaga = function(l)
		piece(l, V(0.15, 0.15, 0.15), rgb(220, 255, 120), C(0, 0, 0), "Glow", BALL, Enum.Material.Neon)
	end,
	Pato = function(l)
		piece(l, V(0.9, 0.6, 1.4), rgb(120, 96, 70), C(0, 0, 0), nil, BALL)
		piece(l, V(0.5, 0.5, 0.5), rgb(30, 110, 60), C(0, 0.45, -0.55), "Head", BALL)
		piece(l, V(0.3, 0.1, 0.35), rgb(240, 190, 50), C(0, 0.4, -0.9), "Head")
		piece(l, V(0.3, 0.1, 0.3), rgb(250, 250, 250), C(0, 0.25, -0.35))
		piece(l, V(0.35, 0.12, 0.4), rgb(90, 70, 50), C(0, 0.12, 0.72), "Tail")
	end,
	Perro = function(l)
		local coat = ({ rgb(200, 150, 90), rgb(60, 50, 45), rgb(230, 220, 200) })[math.random(1, 3)]
		piece(l, V(0.9, 0.8, 1.8), coat, C(0, 0, 0))
		piece(l, V(0.7, 0.7, 0.7), coat, C(0, 0.45, -1.1), "Head")
		piece(l, V(0.35, 0.3, 0.4), coat:Lerp(Color3.new(0, 0, 0), 0.2), C(0, 0.3, -1.55), "Head")
		piece(l, V(0.12, 0.1, 0.06), rgb(20, 20, 22), C(0, 0.4, -1.76), "Head") -- hocico
		piece(l, V(0.2, 0.35, 0.15), coat:Lerp(Color3.new(0, 0, 0), 0.3), C(-0.25, 0.9, -1.05), "EarL")
		piece(l, V(0.2, 0.35, 0.15), coat:Lerp(Color3.new(0, 0, 0), 0.3), C(0.25, 0.9, -1.05), "EarR")
		piece(l, V(0.15, 0.15, 0.7), coat, C(0, 0.35, 1.1) * angles(math.rad(35), 0, 0), "Tail")
		for i, pos in { V(-0.3, -0.7, -0.6), V(0.3, -0.7, -0.6), V(-0.3, -0.7, 0.6), V(0.3, -0.7, 0.6) } do
			piece(l, V(0.22, 0.7, 0.22), coat, C(pos), "Leg" .. i)
		end
	end,
	Gato = function(l)
		local coat = ({ rgb(230, 140, 50), rgb(40, 40, 44), rgb(160, 160, 165), rgb(245, 240, 230) })[math.random(1, 4)]
		piece(l, V(0.6, 0.55, 1.3), coat, C(0, 0, 0))
		piece(l, V(0.55, 0.5, 0.5), coat, C(0, 0.35, -0.8), "Head")
		piece(l, V(0.12, 0.2, 0.08), coat, C(-0.17, 0.68, -0.8), "EarL")
		piece(l, V(0.12, 0.2, 0.08), coat, C(0.17, 0.68, -0.8), "EarR")
		piece(l, V(0.1, 0.1, 0.9), coat, C(0, 0.45, 0.95) * angles(math.rad(-50), 0, 0), "Tail")
		for i, pos in { V(-0.2, -0.45, -0.45), V(0.2, -0.45, -0.45), V(-0.2, -0.45, 0.45), V(0.2, -0.45, 0.45) } do
			piece(l, V(0.14, 0.45, 0.14), coat, C(pos), "Leg" .. i)
		end
	end,
	Vaca = function(l)
		local white, black = rgb(245, 245, 240), rgb(30, 30, 32)
		piece(l, V(2, 1.8, 3.4), white, C(0, 0, 0))
		piece(l, V(1.2, 1.2, 0.1), black, C(0.5, 0.3, 0.2) * angles(0, math.rad(90), 0))
		piece(l, V(1.2, 1.2, 1.4), white, C(0, 0.5, -2.1), "Head")
		piece(l, V(0.9, 0.6, 0.4), rgb(240, 170, 170), C(0, 0.2, -2.85), "Head")
		piece(l, V(0.15, 0.4, 0.15), rgb(230, 220, 190), C(-0.5, 1.25, -2), "Head") -- cuernos
		piece(l, V(0.15, 0.4, 0.15), rgb(230, 220, 190), C(0.5, 1.25, -2), "Head")
		piece(l, V(0.4, 0.15, 0.3), white, C(-0.75, 0.85, -1.85), "EarL")
		piece(l, V(0.4, 0.15, 0.3), white, C(0.75, 0.85, -1.85), "EarR")
		piece(l, V(0.15, 1.4, 0.15), white, C(0, -0.1, 1.75), "Tail")
		for i, pos in { V(-0.7, -1.4, -1.2), V(0.7, -1.4, -1.2), V(-0.7, -1.4, 1.2), V(0.7, -1.4, 1.2) } do
			piece(l, V(0.4, 1.3, 0.4), white, C(pos), "Leg" .. i)
		end
	end,
	Oveja = function(l)
		local wool, face = rgb(240, 238, 230), rgb(50, 45, 45)
		piece(l, V(1.4, 1.2, 1.9), wool, C(0, 0, 0), nil, nil, Enum.Material.Fabric)
		piece(l, V(0.6, 0.7, 0.7), face, C(0, 0.3, -1.2), "Head")
		piece(l, V(0.3, 0.12, 0.2), face, C(-0.4, 0.5, -1.1), "EarL")
		piece(l, V(0.3, 0.12, 0.2), face, C(0.4, 0.5, -1.1), "EarR")
		piece(l, V(0.3, 0.4, 0.2), wool, C(0, 0.1, 1.0), "Tail", nil, Enum.Material.Fabric)
		for i, pos in { V(-0.4, -0.9, -0.6), V(0.4, -0.9, -0.6), V(-0.4, -0.9, 0.6), V(0.4, -0.9, 0.6) } do
			piece(l, V(0.2, 0.8, 0.2), face, C(pos), "Leg" .. i)
		end
	end,
	Gallina = function(l)
		local body = ({ rgb(250, 245, 235), rgb(170, 90, 40) })[math.random(1, 2)]
		piece(l, V(0.7, 0.7, 0.9), body, C(0, 0, 0), nil, BALL)
		piece(l, V(0.4, 0.4, 0.4), body, C(0, 0.45, -0.35), "Head", BALL)
		piece(l, V(0.1, 0.2, 0.25), rgb(220, 40, 40), C(0, 0.72, -0.35), "Head")
		piece(l, V(0.1, 0.1, 0.18), rgb(240, 190, 50), C(0, 0.45, -0.6), "Head")
		piece(l, V(0.3, 0.4, 0.2), body, C(0, 0.25, 0.45), "Tail")
		piece(l, V(0.06, 0.35, 0.06), rgb(240, 190, 50), C(-0.15, -0.5, 0), "Leg1")
		piece(l, V(0.06, 0.35, 0.06), rgb(240, 190, 50), C(0.15, -0.5, 0), "Leg2")
	end,
}

-- Altura del centro del cuerpo sobre el suelo: justo lo que miden las patas, para que toquen el
-- suelo (antes el perro, la vaca y la oveja flotaban un poco)
AnimalPose.Stand = { Paloma = 0.62, Perro = 1.05, Gato = 0.68, Vaca = 2.05, Oveja = 1.3, Gallina = 0.68, Pato = 0.15, Gaviota = 0.25 }
AnimalPose.WalkSpeed = { Paloma = 1.2, Perro = 5, Gato = 3, Vaca = 1.6, Oveja = 2, Gallina = 2.2 }

-- Qué pueden hacer quietos (se elige una al azar cada vez que se paran)
AnimalPose.Actions = {
	Perro = { "stand", "sit", "sit", "sniff" },
	Gato = { "stand", "sit", "lie", "lie", "groom" },
	Vaca = { "graze", "graze", "stand" },
	Oveja = { "graze", "graze", "stand" },
	Gallina = { "peck", "peck", "scratch" },
	Paloma = { "peck" },
	Pato = { "swim", "swim", "dabble" },
}

-- Te miran si te acercas
AnimalPose.Lookers = { Perro = true, Gato = true, Vaca = true, Oveja = true }

-- Dónde gira la cabeza (el cuello), en el espacio del cuerpo
local NECK = {
	Perro = V(0, 0.35, -0.8),
	Gato = V(0, 0.25, -0.6),
	Vaca = V(0, 0.6, -1.5),
	Oveja = V(0, 0.3, -0.9),
	Gallina = V(0, 0.3, -0.2),
	Paloma = V(0, 0.25, -0.3),
	Pato = V(0, 0.3, -0.4),
}

local POSES = { "sit", "lie", "graze", "sniff", "groom", "peck", "scratch", "dabble" }
local GRAZE_PITCH = -0.95
local PECK_PITCH = -0.9

export type Info = {
	LegLen: number,
	Legs: { [number]: Vector3 }, -- índice de la pieza → punto de la cadera
	Pivots: { [number]: Vector3 }, -- índice → punto de giro (cola, orejas)
	Back: Vector3, -- entre las caderas traseras (para sentarse)
	Neck: Vector3,
	Quadruped: boolean,
	GrazeDrop: number, -- cuánto más baja la cabeza para llegar a la hierba (además de inclinarse)
	PeckDrop: number,
}

export type State = {
	Kind: string,
	State: string, -- "idle" | "walk" | "fly" | "flee" | "float"
	Action: string?,
	Phase: number,
	Stride: number,
	Moving: number, -- 0..1: cuánto está andando (suave, para no dar saltos al pararse)
	LookYaw: number, -- hacia dónde gira la cabeza para mirarte (ya suave)
	Looking: number, -- 0..1
	Excited: number, -- 0..1 (el perro, si estás cerca)
	Weights: { [string]: number },
}

-- Crea las piezas de un animal y mide su cuerpo (caderas, cuello, cola)
function AnimalPose.build(kind: string): ({ Piece }, Info)
	local list: { Piece } = {}
	BUILDERS[kind](list)
	local info: Info = { LegLen = 0, Legs = {}, Pivots = {}, Back = Vector3.zero, Neck = NECK[kind] or V(0, 0.3, -0.5), Quadruped = false, GrazeDrop = 0, PeckDrop = 0 }
	local back, backCount = Vector3.zero, 0
	for i, p in list do
		local role = p.Role
		local size = p.Part.Size
		if role and role:sub(1, 3) == "Leg" then
			local hip = p.Offset.Position + V(0, size.Y / 2, 0)
			info.Legs[i] = hip
			info.LegLen = math.max(info.LegLen, size.Y)
			if tonumber(role:sub(4)) == 4 then
				info.Quadruped = true
			end
			if hip.Z > 0 then
				back += hip
				backCount += 1
			end
		elseif role == "Tail" then
			-- La cola gira desde donde toca el cuerpo (su punta delantera)
			local long = if size.Y > size.Z then V(0, size.Y / 2, 0) else V(0, 0, -size.Z / 2)
			info.Pivots[i] = (p.Offset * CFrame.new(long)).Position
		elseif role == "EarL" or role == "EarR" then
			info.Pivots[i] = (p.Offset * CFrame.new(0, -size.Y / 2, 0)).Position
		end
	end
	info.Back = if backCount > 0 then back / backCount else V(0, 0, 0.5)
	-- Cuánto tiene que bajar la cabeza (además de inclinarla) para que la boca llegue al suelo
	local ground = -(AnimalPose.Stand[kind] or 0)
	local function reach(pitch: number): number
		local rotation = CFrame.new(info.Neck) * angles(pitch, 0, 0) * CFrame.new(-info.Neck)
		local low = math.huge
		for _, p in list do
			if p.Role == "Head" then
				local frame = rotation * p.Offset
				local h = p.Part.Size / 2
				for _, x in { -h.X, h.X } do
					for _, y in { -h.Y, h.Y } do
						for _, z in { -h.Z, h.Z } do
							low = math.min(low, (frame * V(x, y, z)).Y)
						end
					end
				end
			end
		end
		return if low == math.huge then 0 else math.max(0, low - (ground + 0.1))
	end
	info.GrazeDrop = reach(GRAZE_PITCH)
	info.PeckDrop = reach(PECK_PITCH)
	return list, info
end

function AnimalPose.newState(kind: string): State
	local weights = {}
	for _, name in POSES do
		weights[name] = 0
	end
	return { Kind = kind, State = "idle", Action = nil, Phase = math.random() * 10, Stride = 0, Moving = 0, LookYaw = 0, Looking = 0, Excited = 0, Weights = weights }
end

-- Elige qué hace ahora que se ha parado
function AnimalPose.chooseAction(kind: string): string?
	local list = AnimalPose.Actions[kind]
	return if list then list[math.random(1, #list)] else nil
end

local function smooth(current: number, target: number, rate: number, dt: number): number
	return current + (target - current) * (1 - math.exp(-rate * dt))
end

-- Avanza el paso, las posturas y la mirada. lookYaw: ángulo hacia el jugador (nil = lejos)
function AnimalPose.step(s: State, dt: number, speed: number, lookYaw: number?, near: boolean?)
	local walking = s.State == "walk"
	s.Moving = smooth(s.Moving, if walking then 1 else 0, 8, dt)
	if s.Moving > 0.01 then
		s.Stride = (s.Stride + dt * speed * 3) % (math.pi * 2)
	end
	for _, name in POSES do
		local want = if not walking and s.Action == name then 1 else 0
		s.Weights[name] = smooth(s.Weights[name], want, 3, dt)
	end
	local looking = lookYaw ~= nil and AnimalPose.Lookers[s.Kind] == true
	s.Looking = smooth(s.Looking, if looking then 1 else 0, 3, dt)
	if lookYaw then
		s.LookYaw = smooth(s.LookYaw, clamp(lookYaw, -0.9, 0.9), 4, dt)
	end
	s.Excited = smooth(s.Excited, if near then 1 else 0, 2, dt)
end

local function around(pivot: Vector3, rotation: CFrame): CFrame
	return CFrame.new(pivot) * rotation * CFrame.new(-pivot)
end

-- Dónde va cada pieza (relativo a la raíz del animal) en este momento
function AnimalPose.pose(pieces: { Piece }, info: Info, s: State, t: number, out: { CFrame })
	local W = s.Weights
	local ph = s.Phase
	local kind = s.Kind
	local walking = s.State == "walk"
	local flying = s.State == "fly" or s.State == "flee"
	local legLen = info.LegLen
	local stride = s.Stride
	local moving = s.Moving

	-- Alas
	local flap = 0
	if flying then
		flap = sin(t * (if kind == "Gaviota" then 9 else 22) + ph) * 0.9
	elseif kind == "Mariposa" then
		flap = sin(t * 18 + ph) * 1.1
	end

	-- Cuerpo: sube y baja al andar; se sienta, se tumba o mete la cabeza en el agua
	local body = CFrame.identity
	if moving > 0.001 and legLen > 0 then
		local bob = if info.Quadruped then abs(sin(stride * 2)) else abs(sin(stride))
		body = C(0, bob * 0.05 * legLen * moving, 0)
	end
	local sit, lie = W.sit, W.lie
	if sit > 0.001 then
		body = C(0, -legLen * 0.5 * sit, 0) * around(info.Back, angles(0.35 * sit, 0, 0)) * body
	end
	if lie > 0.001 then
		body = C(0, -legLen * 0.85 * lie, 0) * body
	end
	if W.dabble > 0.001 then
		body = around(V(0, -0.1, 0), angles(-1.1 * W.dabble, 0, 0)) * body
	end
	if kind == "Pato" then
		body = angles(0, 0, sin(t * 3 + ph) * 0.05) * body -- se mece en el agua
	end
	-- Respira (quieto)
	if not flying and legLen > 0 then
		body = C(0, sin(t * 2.2 + ph) * 0.01 * legLen * (1 - moving), 0) * body
	end

	-- Cabeza: mirar, pastar, olfatear, lamerse, picotear
	local headPitch, headYaw, headRoll = 0, 0, 0
	local busyHead = W.graze + W.sniff + W.groom + W.peck
	local free = math.max(0, 1 - busyHead)
	headYaw += s.LookYaw * s.Looking * free
	headPitch += 0.1 * s.Looking * free
	headPitch += W.graze * (GRAZE_PITCH + sin(t * 5 + ph) * 0.06) -- rumiando
	headPitch += W.sniff * -0.6
	headYaw += W.sniff * sin(t * 2 + ph) * 0.45
	headPitch += W.groom * (-0.45 + sin(t * 9 + ph) * 0.08)
	headYaw += W.groom * 1.3
	local pk = math.max(0, sin(t * 3 + ph)) ^ 2 * W.peck
	headPitch += PECK_PITCH * pk
	headPitch += -0.25 * W.sit -- sentado, con el cuerpo inclinado, la cabeza sigue recta
	local head = around(info.Neck, angles(headPitch, headYaw, headRoll))
	-- Al pastar o picotear, el cuello baja hasta que la boca toca el suelo
	local drop = info.GrazeDrop * W.graze + info.PeckDrop * pk
	if drop > 0.001 then
		head = C(0, -drop, 0) * head
	end
	-- Paloma y gallina: la cabeza va adelante y atrás a cada paso
	if moving > 0.001 and (kind == "Paloma" or kind == "Gallina") then
		head = C(0, 0, -abs(sin(stride)) * 0.15 * moving) * head
	end

	-- Orejas: de vez en cuando se agitan
	local twitch = math.max(0, sin(t * 0.8 + ph * 3)) ^ 16

	-- Cola
	local tailYaw, tailPitch = 0, 0
	if kind == "Perro" then
		-- (la velocidad no cambia con la emoción: si cambiara, la cola daría saltos)
		tailYaw = sin(t * 11 + ph) * (0.25 + 0.35 * s.Excited)
		tailPitch = 0.2 * s.Excited
	elseif kind == "Gato" then
		tailYaw = sin(t * 1.2 + ph) * 0.45
		tailPitch = sin(t * 0.7 + ph) * 0.15
	elseif kind == "Vaca" or kind == "Oveja" then
		-- Espanta moscas a ratos
		tailYaw = sin(t * 3 + ph) * 0.35 * math.max(0, sin(t * 0.4 + ph))
	elseif kind == "Pato" then
		tailPitch = 0.6 * W.dabble
	end

	for i, p in pieces do
		local offset = p.Offset
		local role = p.Role
		if role == "WingL" or role == "WingR" then
			local x = offset.Position.X
			local side = if role == "WingL" then 1 else -1
			offset = C(x * 0.2, offset.Position.Y, offset.Position.Z) * angles(0, 0, flap * side) * C(x * 0.8, 0, 0)
		elseif role == "Head" then
			offset = head * offset
		elseif role == "EarL" or role == "EarR" then
			local side = if role == "EarL" then 1 else -1
			offset = head * around(info.Pivots[i], angles(0, 0, twitch * 0.35 * side)) * offset
		elseif role == "Tail" then
			offset = around(info.Pivots[i], angles(tailPitch, tailYaw, 0)) * offset
		elseif role and role:sub(1, 3) == "Leg" then
			local n = tonumber(role:sub(4)) or 1
			local hip = info.Legs[i]
			local front = hip.Z < 0
			local swing = 0
			if moving > 0.001 then
				-- Cuatro patas: en diagonal (1 con 4, 2 con 3). Dos patas: una y otra
				local sign = if info.Quadruped then (if n == 1 or n == 4 then 1 else -1) else (if n == 1 then 1 else -1)
				swing = sin(stride) * 0.5 * sign * moving
			end
			-- Sentado: las traseras dobladas hacia delante y las delanteras rectas
			if front then
				swing -= 0.35 * sit
			else
				swing += 1.1 * sit
			end
			-- Tumbado: las patas recogidas
			swing += 1.45 * lie
			-- Escarbar (gallina): la pata izquierda rasca hacia atrás
			if n == 1 and W.scratch > 0.001 then
				swing -= math.max(0, sin(t * 7 + ph)) * 0.9 * W.scratch
			end
			offset = around(hip, angles(swing, 0, 0)) * offset
		end
		out[i] = body * offset
	end
end

return AnimalPose
