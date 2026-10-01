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
--       Granja (shared/FarmAnimals): el cerdo hoza (hocico al suelo, moviéndolo de lado a lado) y se
--       tumba; vaca, oveja, cabra y caballo pastan, miran y se tumban; el toro escarba con una pata.
--   * Si te acercas, el perro, el gato y los de granja te miran. Las orejas se mueven de vez en cuando.
--   * Aspecto (look, opcional): color, color de detalle, manchas, pelo largo y tamaño (las razas de
--     shared/Pets). Con collar = mascota con dueño (la correa se engancha en "Collar").
--
-- Se prueba fuera de Roblox: scripts/test-animals.luau

local AnimalPose = {}

export type Piece = { Part: BasePart, Offset: CFrame, Role: string?, Hip: Vector3? }

local rgb = Color3.fromRGB
local V = Vector3.new
local C = CFrame.new
local BALL = Enum.PartType.Ball
local sin, abs, clamp = math.sin, math.abs, math.clamp
local angles = CFrame.Angles

-- Carpeta donde se crean las piezas (la pone Wildlife: solo existe para este jugador)
AnimalPose.folder = nil :: Instance?

local function piece(list: { Piece }, size: Vector3, color: Color3, offset: CFrame, role: string?, shape: Enum.PartType?, material: Enum.Material?, hip: Vector3?)
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
	table.insert(list, { Part = p, Offset = offset, Role = role, Hip = hip })
end

export type Look = { Coat: Color3?, Accent: Color3?, Scale: number?, Spots: boolean?, Fluffy: boolean?, Collar: Color3? }

-- Pata con pezuña (o pie) de otro color: la pezuña gira con la pata (misma cadera)
local function hoofLeg(l: { Piece }, i: number, pos: Vector3, size: Vector3, color: Color3, hoofColor: Color3, hoofH: number)
	local hip = pos + V(0, size.Y / 2, 0)
	piece(l, size, color, C(pos), "Leg" .. i)
	local bottom = pos.Y - size.Y / 2
	piece(l, V(size.X * 1.12, hoofH, size.Z * 1.12), hoofColor, C(pos.X, bottom + hoofH / 2 - 0.02, pos.Z), "Leg" .. i, nil, nil, hip)
end

-- Modelos hechos con piezas (sin mallas: ligeros y siempre disponibles).
-- Roles: Head (se mueve con el cuello), Ear (con la cabeza, y se agita), Tail, Leg1..4
-- (1 delantera izq., 2 delantera dcha., 3 trasera izq., 4 trasera dcha.), WingL/WingR, Glow.
local BUILDERS: { [string]: (list: { Piece }, look: Look) -> () } = {
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
	Perro = function(l, look)
		local coat = look.Coat or ({ rgb(200, 150, 90), rgb(60, 50, 45), rgb(230, 220, 200) })[math.random(1, 3)]
		local accent = look.Accent or coat:Lerp(Color3.new(0, 0, 0), 0.2)
		piece(l, V(0.9, 0.8, 1.8), coat, C(0, 0, 0), nil, nil, if look.Fluffy then Enum.Material.Fabric else nil)
		if look.Accent and not look.Spots then
			piece(l, V(0.94, 0.3, 1.2), accent, C(0, 0.3, 0.15)) -- manta del lomo (pastor, beagle)
		end
		if look.Spots then
			for _, sp in { V(0.46, 0.15, -0.4), V(-0.46, 0.05, 0.3), V(0.46, -0.1, 0.5), V(-0.46, 0.2, -0.5), V(0, 0.41, 0.1) } do
				local flat = if sp.Y > 0.4 then V(0.3, 0.02, 0.28) else V(0.02, 0.26, 0.3)
				piece(l, flat, accent, C(sp))
			end
		end
		piece(l, V(0.7, 0.7, 0.7), coat, C(0, 0.45, -1.1), "Head")
		piece(l, V(0.35, 0.3, 0.4), coat:Lerp(Color3.new(0, 0, 0), 0.2), C(0, 0.3, -1.55), "Head")
		piece(l, V(0.12, 0.1, 0.06), rgb(20, 20, 22), C(0, 0.4, -1.76), "Head") -- hocico
		piece(l, V(0.2, 0.35, 0.15), accent:Lerp(Color3.new(0, 0, 0), 0.15), C(-0.25, 0.9, -1.05), "EarL")
		piece(l, V(0.2, 0.35, 0.15), accent:Lerp(Color3.new(0, 0, 0), 0.15), C(0.25, 0.9, -1.05), "EarR")
		if look.Collar then
			piece(l, V(0.76, 0.14, 0.5), look.Collar, C(0, 0.25, -0.86), "Collar") -- collar (aquí va la correa)
		end
		piece(l, V(0.15, 0.15, 0.7), coat, C(0, 0.35, 1.1) * angles(math.rad(35), 0, 0), "Tail")
		for i, pos in { V(-0.3, -0.7, -0.6), V(0.3, -0.7, -0.6), V(-0.3, -0.7, 0.6), V(0.3, -0.7, 0.6) } do
			piece(l, V(0.22, 0.7, 0.22), coat, C(pos), "Leg" .. i)
		end
	end,
	Gato = function(l, look)
		local coat = look.Coat or ({ rgb(230, 140, 50), rgb(40, 40, 44), rgb(160, 160, 165), rgb(245, 240, 230) })[math.random(1, 4)]
		local accent = look.Accent or coat
		local fur = if look.Fluffy then Enum.Material.Fabric else nil
		piece(l, if look.Fluffy then V(0.7, 0.62, 1.35) else V(0.6, 0.55, 1.3), coat, C(0, 0, 0), nil, nil, fur)
		if look.Accent then
			piece(l, V(0.64, 0.2, 0.8), accent, C(0, 0.2, 0.15)) -- manchas del lomo
		end
		piece(l, V(0.55, 0.5, 0.5), coat, C(0, 0.35, -0.8), "Head", nil, fur)
		piece(l, V(0.3, 0.2, 0.08), if look.Accent then accent else coat:Lerp(Color3.new(1, 1, 1), 0.3), C(0, 0.27, -1.06), "Head") -- hocico
		piece(l, V(0.06, 0.06, 0.04), rgb(220, 120, 130), C(0, 0.33, -1.1), "Head") -- nariz
		piece(l, V(0.12, 0.2, 0.08), accent, C(-0.17, 0.68, -0.8), "EarL")
		piece(l, V(0.12, 0.2, 0.08), accent, C(0.17, 0.68, -0.8), "EarR")
		if look.Collar then
			piece(l, V(0.5, 0.1, 0.36), look.Collar, C(0, 0.15, -0.62), "Collar")
		end
		piece(l, V(0.1, 0.1, 0.9), accent, C(0, 0.45, 0.95) * angles(math.rad(-50), 0, 0), "Tail")
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
	-- Cerdo rosado: hocico chato, orejas caídas y rabito
	Cerdo = function(l, look)
		local pink = look.Coat or ({ rgb(240, 170, 165), rgb(232, 158, 150), rgb(214, 150, 130) })[math.random(1, 3)]
		local dark = pink:Lerp(rgb(150, 70, 70), 0.3)
		piece(l, V(1.4, 1.15, 2.3), pink, C(0, 0, 0))
		piece(l, V(1.2, 0.95, 0.6), pink, C(0, 0.02, 1.0)) -- culo redondo
		piece(l, V(0.95, 0.9, 0.75), pink, C(0, 0.12, -1.42), "Head")
		piece(l, V(0.55, 0.42, 0.28), dark, C(0, -0.02, -1.92), "Head") -- hocico
		piece(l, V(0.08, 0.1, 0.04), rgb(90, 40, 40), C(-0.12, -0.02, -2.07), "Head")
		piece(l, V(0.08, 0.1, 0.04), rgb(90, 40, 40), C(0.12, -0.02, -2.07), "Head")
		piece(l, V(0.36, 0.08, 0.32), dark, C(-0.36, 0.55, -1.42) * angles(0.5, 0, 0.35), "EarL")
		piece(l, V(0.36, 0.08, 0.32), dark, C(0.36, 0.55, -1.42) * angles(0.5, 0, -0.35), "EarR")
		piece(l, V(0.1, 0.1, 0.4), dark, C(0, 0.35, 1.38) * angles(math.rad(50), 0, 0), "Tail")
		for i, pos in { V(-0.42, -0.72, -0.7), V(0.42, -0.72, -0.7), V(-0.42, -0.72, 0.75), V(0.42, -0.72, 0.75) } do
			hoofLeg(l, i, pos, V(0.3, 0.56, 0.3), pink, rgb(120, 80, 70), 0.12)
		end
	end,
	-- Caballo: cuello largo, crin, cola de crin y cascos oscuros
	Caballo = function(l, look)
		local coat = look.Coat or ({ rgb(120, 72, 40), rgb(60, 40, 30), rgb(200, 190, 175), rgb(160, 110, 60) })[math.random(1, 4)]
		local hair = look.Accent or coat:Lerp(Color3.new(0, 0, 0), 0.6)
		piece(l, V(1.6, 1.8, 4.3), coat, C(0, 0, 0))
		piece(l, V(1.7, 1.6, 1.3), coat, C(0, 0.05, 1.75)) -- grupa
		piece(l, V(0.85, 2.3, 1.05), coat, C(0, 1.25, -2.15) * angles(-0.55, 0, 0), "Head") -- cuello
		piece(l, V(0.22, 2.2, 0.4), hair, C(0, 1.45, -1.85) * angles(-0.55, 0, 0), "Head") -- crin
		piece(l, V(0.72, 0.78, 1.75), coat, C(0, 2.2, -3.15) * angles(-0.65, 0, 0), "Head") -- cabeza
		piece(l, V(0.62, 0.55, 0.55), coat:Lerp(Color3.new(0, 0, 0), 0.35), C(0, 1.62, -3.78), "Head") -- morro
		piece(l, V(0.14, 0.4, 0.14), coat, C(-0.22, 2.95, -2.7), "EarL")
		piece(l, V(0.14, 0.4, 0.14), coat, C(0.22, 2.95, -2.7), "EarR")
		if look.Collar then
			piece(l, V(1.0, 1.0, 0.12), look.Collar, C(0, 0.05, -2.6) * angles(-0.55, 0, 0), "Collar")
		end
		piece(l, V(0.36, 2.3, 0.36), hair, C(0, -0.3, 2.55) * angles(0.25, 0, 0), "Tail")
		local hoof = rgb(45, 40, 38)
		for i, pos in { V(-0.5, -2.15, -1.55), V(0.5, -2.15, -1.55), V(-0.5, -2.15, 1.6), V(0.5, -2.15, 1.6) } do
			hoofLeg(l, i, pos, V(0.42, 2.5, 0.46), coat, hoof, 0.3)
		end
	end,
	-- Cabra: pequeña, barba, cuernos hacia atrás y rabo corto y tieso
	Cabra = function(l, look)
		local coat = look.Coat or ({ rgb(240, 236, 228), rgb(150, 110, 75), rgb(70, 60, 55) })[math.random(1, 3)]
		local horn = rgb(170, 150, 120)
		piece(l, V(1.05, 1.0, 1.75), coat, C(0, 0, 0))
		piece(l, V(0.5, 0.6, 0.75), coat, C(0, 0.6, -1.12), "Head")
		piece(l, V(0.36, 0.34, 0.3), coat:Lerp(Color3.new(0, 0, 0), 0.15), C(0, 0.42, -1.55), "Head")
		piece(l, V(0.14, 0.38, 0.14), coat:Lerp(Color3.new(1, 1, 1), 0.2), C(0, 0.12, -1.48), "Head") -- barba
		piece(l, V(0.1, 0.55, 0.1), horn, C(-0.13, 1.08, -1.0) * angles(0.6, 0, -0.1), "Head")
		piece(l, V(0.1, 0.55, 0.1), horn, C(0.13, 1.08, -1.0) * angles(0.6, 0, 0.1), "Head")
		piece(l, V(0.36, 0.1, 0.16), coat, C(-0.38, 0.72, -1.05), "EarL")
		piece(l, V(0.36, 0.1, 0.16), coat, C(0.38, 0.72, -1.05), "EarR")
		piece(l, V(0.14, 0.32, 0.12), coat, C(0, 0.55, 0.9) * angles(-0.4, 0, 0), "Tail")
		for i, pos in { V(-0.32, -0.95, -0.58), V(0.32, -0.95, -0.58), V(-0.32, -0.95, 0.6), V(0.32, -0.95, 0.6) } do
			hoofLeg(l, i, pos, V(0.17, 0.95, 0.17), coat, rgb(60, 50, 45), 0.12)
		end
	end,
	-- Toro: negro y fuerte, con morrillo, cuernos hacia delante y aro en la nariz
	Toro = function(l, look)
		local coat = look.Coat or ({ rgb(30, 26, 26), rgb(70, 40, 28) })[math.random(1, 2)]
		local horn = rgb(232, 222, 196)
		piece(l, V(2.3, 2.0, 3.6), coat, C(0, 0, 0))
		piece(l, V(1.9, 0.7, 1.4), coat, C(0, 1.1, -0.9)) -- morrillo
		piece(l, V(1.35, 1.25, 1.35), coat, C(0, 0.45, -2.15), "Head")
		piece(l, V(1.0, 0.6, 0.4), coat:Lerp(rgb(180, 120, 110), 0.35), C(0, 0.12, -2.95), "Head")
		piece(l, V(0.45, 0.45, 0.08), rgb(210, 175, 70), C(0, -0.22, -3.15), "Head", nil, Enum.Material.Metal) -- aro
		piece(l, V(0.9, 0.24, 0.24), horn, C(-0.95, 1.05, -2.15) * angles(0, 0.35, 0.5), "Head")
		piece(l, V(0.9, 0.24, 0.24), horn, C(0.95, 1.05, -2.15) * angles(0, -0.35, -0.5), "Head")
		piece(l, V(0.4, 0.15, 0.3), coat, C(-0.82, 0.62, -1.95), "EarL")
		piece(l, V(0.4, 0.15, 0.3), coat, C(0.82, 0.62, -1.95), "EarR")
		piece(l, V(0.16, 1.5, 0.16), coat, C(0, -0.1, 1.85), "Tail")
		for i, pos in { V(-0.75, -1.45, -1.2), V(0.75, -1.45, -1.2), V(-0.75, -1.45, 1.2), V(0.75, -1.45, 1.2) } do
			hoofLeg(l, i, pos, V(0.46, 1.3, 0.46), coat, rgb(40, 36, 34), 0.2)
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
AnimalPose.Stand = { Paloma = 0.62, Perro = 1.05, Gato = 0.68, Vaca = 2.05, Oveja = 1.3, Gallina = 0.68, Pato = 0.15, Gaviota = 0.25, Cerdo = 1.0, Caballo = 3.4, Cabra = 1.425, Toro = 2.1 }
AnimalPose.WalkSpeed = { Paloma = 1.2, Perro = 5, Gato = 3, Vaca = 1.6, Oveja = 2, Gallina = 2.2, Cerdo = 1.8, Caballo = 3.2, Cabra = 2.2, Toro = 1.5 }

-- Qué pueden hacer quietos (se elige una al azar cada vez que se paran)
AnimalPose.Actions = {
	Perro = { "stand", "sit", "sit", "sniff" },
	Gato = { "stand", "sit", "lie", "lie", "groom" },
	Vaca = { "graze", "graze", "stand", "lie" },
	Oveja = { "graze", "graze", "stand", "lie" },
	Cerdo = { "root", "root", "stand", "lie" },
	Caballo = { "graze", "graze", "stand", "stand" },
	Cabra = { "graze", "stand", "stand", "lie" },
	Toro = { "stand", "graze", "paw" },
	Gallina = { "peck", "peck", "scratch" },
	Paloma = { "peck" },
	Pato = { "swim", "swim", "dabble" },
}

-- Te miran si te acercas
AnimalPose.Lookers = { Perro = true, Gato = true, Vaca = true, Oveja = true, Cerdo = true, Caballo = true, Cabra = true, Toro = true }

-- Dónde gira la cabeza (el cuello), en el espacio del cuerpo
local NECK = {
	Perro = V(0, 0.35, -0.8),
	Gato = V(0, 0.25, -0.6),
	Vaca = V(0, 0.6, -1.5),
	Oveja = V(0, 0.3, -0.9),
	Gallina = V(0, 0.3, -0.2),
	Paloma = V(0, 0.25, -0.3),
	Pato = V(0, 0.3, -0.4),
	Cerdo = V(0, 0.15, -1.05),
	Caballo = V(0, 0.45, -1.8),
	Cabra = V(0, 0.35, -0.8),
	Toro = V(0, 0.6, -1.5),
}

local POSES = { "sit", "lie", "graze", "sniff", "groom", "peck", "scratch", "dabble", "root", "paw" }
local GRAZE_PITCH = -0.95
-- (el caballo tiene el cuello muy largo: lo baja más para llegar a la hierba)
local GRAZE_BY_KIND = { Caballo = -1.65 }
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
	Stand: number, -- altura del centro del cuerpo sobre el suelo (con su tamaño)
	Scale: number,
	Collar: number?, -- índice de la pieza del collar (si lleva)
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
	Startle: number, -- 1 → 0: el susto (salto, cabeza y cola arriba) cuando te acercas o chocas
	Weights: { [string]: number },
}

-- Crea las piezas de un animal y mide su cuerpo (caderas, cuello, cola)
function AnimalPose.build(kind: string, look: Look?): ({ Piece }, Info)
	local list: { Piece } = {}
	local lk = look or {}
	BUILDERS[kind](list, lk)
	local scale = math.clamp(tonumber(lk.Scale) or 1, 0.4, 2)
	local neck = NECK[kind] or V(0, 0.3, -0.5)
	if scale ~= 1 then
		-- Más grande o más pequeño (razas): todo a escala, también dónde gira cada cosa
		for _, p in list do
			p.Part.Size *= scale
			p.Offset = CFrame.new(p.Offset.Position * scale) * p.Offset.Rotation
			if p.Hip then
				p.Hip *= scale
			end
		end
		neck *= scale
	end
	local info: Info = { LegLen = 0, Legs = {}, Pivots = {}, Back = Vector3.zero, Neck = neck, Quadruped = false, GrazeDrop = 0, PeckDrop = 0, Stand = (AnimalPose.Stand[kind] or 0) * scale, Scale = scale }
	local back, backCount = Vector3.zero, 0
	for i, p in list do
		local role = p.Role
		local size = p.Part.Size
		if role and role:sub(1, 3) == "Leg" then
			local hip = p.Hip or (p.Offset.Position + V(0, size.Y / 2, 0))
			info.Legs[i] = hip
			info.LegLen = math.max(info.LegLen, size.Y)
			if tonumber(role:sub(4)) == 4 then
				info.Quadruped = true
			end
			if hip.Z > 0 and not p.Hip then
				back += hip
				backCount += 1
			end
		elseif role == "Collar" then
			info.Collar = i
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
	local ground = -info.Stand
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
	info.GrazeDrop = reach(GRAZE_BY_KIND[kind] or GRAZE_PITCH)
	info.PeckDrop = reach(PECK_PITCH)
	return list, info
end

function AnimalPose.newState(kind: string): State
	local weights = {}
	for _, name in POSES do
		weights[name] = 0
	end
	return { Kind = kind, State = "idle", Action = nil, Phase = math.random() * 10, Stride = 0, Moving = 0, LookYaw = 0, Looking = 0, Excited = 0, Startle = 0, Weights = weights }
end

-- Elige qué hace ahora que se ha parado
function AnimalPose.chooseAction(kind: string): string?
	local list = AnimalPose.Actions[kind]
	return if list then list[math.random(1, #list)] else nil
end

-- Susto: cuánto dura y lo alto que salta cada uno (el gato, el que más)
AnimalPose.StartleTime = { Perro = 0.6, Gato = 0.55, Vaca = 0.8, Oveja = 0.6, Gallina = 0.7, Paloma = 0.5, Pato = 0.6, Cerdo = 0.6, Caballo = 0.8, Cabra = 0.6, Toro = 0.9 }
local HOP = { Perro = 0.9, Gato = 1.3, Vaca = 0.35, Oveja = 0.7, Gallina = 0.8, Paloma = 0.5, Pato = 0.3, Cerdo = 0.5, Caballo = 0.45, Cabra = 0.9, Toro = 0.3 }

-- Empieza un susto (lo lleva AnimalPose.step)
function AnimalPose.startle(s: State)
	s.Startle = 1
end

-- Cómo se mueve el cuerpo en el susto (función pura): salto, cabeza arriba, cola arriba y aleteo.
-- startle: 1 al empezar → 0 al acabar
function AnimalPose.reaction(kind: string, startle: number): { Hop: number, HeadPitch: number, TailUp: number, Flap: number, Crouch: number }
	if startle <= 0 or startle ~= startle then
		return { Hop = 0, HeadPitch = 0, TailUp = 0, Flap = 0, Crouch = 0 }
	end
	local u = 1 - math.min(startle, 1)
	-- Se encoge un momento y salta
	local crouch = if u < 0.2 then math.sin(u / 0.2 * math.pi) * 0.12 else 0
	local air = if u >= 0.15 then math.sin(math.clamp((u - 0.15) / 0.7, 0, 1) * math.pi) else 0
	local up = math.sin(u * math.pi)
	return {
		Hop = air * (HOP[kind] or 0.6),
		HeadPitch = 0.4 * up,
		TailUp = 0.9 * up,
		Flap = if kind == "Gallina" or kind == "Paloma" or kind == "Pato" then up else 0,
		Crouch = crouch,
	}
end

-- Los de patas largas dan pasos más lentos (si no, la pezuña iría a saltos) y cambian de postura
-- más despacio (el cuello del caballo es muy largo)
local STRIDE = { Caballo = 0.55, Toro = 0.85 }
local POSE_RATE = { Caballo = 1.5 }

local function smooth(current: number, target: number, rate: number, dt: number): number
	return current + (target - current) * (1 - math.exp(-rate * dt))
end

-- Avanza el paso, las posturas y la mirada. lookYaw: ángulo hacia el jugador (nil = lejos)
function AnimalPose.step(s: State, dt: number, speed: number, lookYaw: number?, near: boolean?)
	local walking = s.State == "walk"
	s.Moving = smooth(s.Moving, if walking then 1 else 0, 8, dt)
	if s.Moving > 0.01 then
		s.Stride = (s.Stride + dt * speed * 3 * (STRIDE[s.Kind] or 1)) % (math.pi * 2)
	end
	for _, name in POSES do
		local want = if not walking and s.Action == name then 1 else 0
		s.Weights[name] = smooth(s.Weights[name], want, POSE_RATE[s.Kind] or 3, dt)
	end
	local looking = lookYaw ~= nil and AnimalPose.Lookers[s.Kind] == true
	s.Looking = smooth(s.Looking, if looking then 1 else 0, 3, dt)
	if lookYaw then
		s.LookYaw = smooth(s.LookYaw, clamp(lookYaw, -0.9, 0.9), 4, dt)
	end
	s.Excited = smooth(s.Excited, if near then 1 else 0, 2, dt)
	if s.Startle > 0 then
		s.Startle = math.max(0, s.Startle - dt / (AnimalPose.StartleTime[s.Kind] or 0.6))
	end
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

	local react = AnimalPose.reaction(kind, s.Startle or 0)
	-- Alas
	local flap = 0
	if react.Flap > 0.001 then
		flap = sin(t * 26 + ph) * 0.9 * react.Flap
	end
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
	-- Susto: se encoge, pega un salto y cae
	if react.Hop > 0.001 or react.Crouch > 0.001 then
		body = C(0, react.Hop - react.Crouch * math.min(legLen, 1.6), 0) * body
	end
	-- Respira (quieto)
	if not flying and legLen > 0 then
		body = C(0, sin(t * 2.2 + ph) * 0.01 * legLen * (1 - moving), 0) * body
	end

	-- Cabeza: mirar, pastar, olfatear, lamerse, picotear
	local headPitch, headYaw, headRoll = 0, 0, 0
	local busyHead = W.graze + W.sniff + W.groom + W.peck + W.root
	local free = math.max(0, 1 - busyHead)
	headYaw += s.LookYaw * s.Looking * free
	headPitch += 0.1 * s.Looking * free
	headPitch += W.graze * ((GRAZE_BY_KIND[kind] or GRAZE_PITCH) + sin(t * 5 + ph) * 0.06) -- rumiando
	headPitch += W.sniff * -0.6
	-- Hozar (cerdo): el hocico al suelo, moviéndolo de lado a lado
	headPitch += W.root * (GRAZE_PITCH * 0.8 + sin(t * 4 + ph) * 0.08)
	headYaw += W.root * sin(t * 2.6 + ph) * 0.35
	headYaw += W.sniff * sin(t * 2 + ph) * 0.45
	headPitch += W.groom * (-0.45 + sin(t * 9 + ph) * 0.08)
	headYaw += W.groom * 1.3
	local pk = math.max(0, sin(t * 3 + ph)) ^ 2 * W.peck
	headPitch += PECK_PITCH * pk
	headPitch += -0.25 * W.sit -- sentado, con el cuerpo inclinado, la cabeza sigue recta
	headPitch += react.HeadPitch
	local head = around(info.Neck, angles(headPitch, headYaw, headRoll))
	-- Al pastar o picotear, el cuello baja hasta que la boca toca el suelo
	local drop = info.GrazeDrop * W.graze + info.GrazeDrop * 0.85 * W.root + info.PeckDrop * pk
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
	elseif kind == "Cerdo" then
		tailYaw = sin(t * 6 + ph) * 0.4
	elseif kind == "Vaca" or kind == "Oveja" or kind == "Caballo" or kind == "Toro" or kind == "Cabra" then
		-- Espanta moscas a ratos
		tailYaw = sin(t * 3 + ph) * 0.35 * math.max(0, sin(t * 0.4 + ph))
	elseif kind == "Pato" then
		tailPitch = 0.6 * W.dabble
	end
	tailPitch += react.TailUp

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
			-- El toro escarba: la delantera derecha adelante y atrás, rozando el suelo
			if n == 2 and W.paw > 0.001 then
				swing += sin(t * 5 + ph) * 0.45 * W.paw
			end
			offset = around(hip, angles(swing, 0, 0)) * offset
		end
		out[i] = body * offset
	end
end

return AnimalPose
