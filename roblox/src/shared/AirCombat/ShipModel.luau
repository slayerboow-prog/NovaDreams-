-- ShipModel: los modelos de las naves del combate aéreo y del espacio (diseño propio, sin marcas ni
-- nada copiado de ninguna saga). Lo usan World/AirArena (la arena de pruebas), Services/AirCombatService,
-- World/SpaceWorld (la nave de exposición del puerto espacial) y el espacio encima de Valmar: la MISMA
-- nave en todas partes.
--
--   ShipModel.build(kind, cf, opts?) -> Model   (PrimaryPart = "Root", invisible y ANCLADO)
--     "Caza"         la nave del jugador: caza ligero de ala en delta, morro afilado, cabina de cristal
--                    con el piloto DENTRO (asiento "ShipSeat" hundido en el fuselaje: se ven la cabeza
--                    y los hombros bajo la burbuja), dos derivas inclinadas, dos motores con toberas y
--                    llama de neón ("Escape" / "Llama": los anima Controllers/AirCombatFx según el motor),
--                    luces de navegación (roja a la izquierda, verde a la derecha, blanca en la cola) y
--                    estelas (Trail) en los motores y en las puntas de las alas.
--     "Dron"         dron enemigo en X: núcleo oscuro, ojo rojo, cuatro rotores naranjas que brillan.
--     "CazaEnemigo"  caza enemigo de alas en flecha invertida (silueta en W), morado oscuro con brillos
--                    rojos: no se confunde con el tuyo ni de lejos.
--     "Torreta"      torreta de dos cañones con cúpula blindada y sensor rojo; su base ("Base",
--                    atributo Static) va anclada aparte.
--   Todas las piezas, menos el Root, van soldadas al Root (WeldConstraint), sin masa ni choques: se
--   mueve todo moviendo el Root (su CFrame). Pocas piezas (≈ 40 la nave, ≈ 12-16 los enemigos) para
--   el móvil.
--
--   ShipModel.specs(kind, opts?) -> { PartSpec }   las piezas (puro: lo prueban scripts/test-aircombat
--                                                   y lo dibuja el render de vista previa)
--
-- Ejes: el morro mira a -Z (LookVector), +Y arriba, +X a la derecha.

local ShipModel = {}

local rgb = Color3.fromRGB

export type PartSpec = {
	Name: string,
	Class: string?, -- "Part" (por defecto), "WedgePart", "Seat"
	Shape: string?, -- "Block" (por defecto), "Ball", "Cylinder"
	Size: Vector3,
	At: CFrame, -- respecto al Root
	Color: Color3,
	Material: string?, -- nombre de Enum.Material (SmoothPlastic por defecto)
	Transparency: number?,
	Reflectance: number?,
	Shadow: boolean?,
	Static: boolean?, -- (torreta) anclada aparte, sin soldar
}

export type Options = { Body: Color3?, Accent: Color3?, Trim: Color3? }

-- Colores de la nave del jugador (se pueden cambiar con opts)
ShipModel.Colors = {
	Body = rgb(226, 231, 238),
	Accent = rgb(38, 110, 225),
	Trim = rgb(255, 146, 40),
	Dark = rgb(40, 44, 54),
	Metal = rgb(92, 98, 112),
	Glass = rgb(120, 200, 255),
	Exhaust = rgb(110, 225, 255),
	NavLeft = rgb(255, 60, 60),
	NavRight = rgb(60, 255, 120),
}

-- Los motores y luces que anima el cliente (nombres de pieza)
ShipModel.Exhaust = "Escape"
ShipModel.Flame = "Llama"
ShipModel.NavLights = { "LuzNavIzq", "LuzNavDer", "LuzCola" }

local function C(x: number, y: number, z: number, rx: number?, ry: number?, rz: number?): CFrame
	return CFrame.new(x, y, z) * CFrame.Angles(rx or 0, ry or 0, rz or 0)
end

local HALF = math.pi / 2

---------------------------------------------------------------------
-- La nave del jugador
---------------------------------------------------------------------
local function fighter(opts: Options?): { PartSpec }
	local o = opts or {}
	local K = ShipModel.Colors
	local body = o.Body or K.Body
	local accent = o.Accent or K.Accent
	local trim = o.Trim or K.Trim
	local list: { PartSpec } = {
		-- Fuselaje (de z = -3.5 a 5.5) con la panza oscura y el lomo detrás de la cabina
		{ Name = "Fuselaje", Size = Vector3.new(4.4, 2.6, 9), At = C(0, 0, 1), Color = body, Shadow = true },
		{ Name = "Panza", Size = Vector3.new(3.6, 0.8, 9.5), At = C(0, -1.55, 0.6), Color = K.Dark },
		{ Name = "Lomo", Size = Vector3.new(2.4, 0.8, 4.2), At = C(0, 1.7, 4.4), Color = body },
		{ Name = "LomoCola", Class = "WedgePart", Size = Vector3.new(2.4, 0.8, 1.8), At = C(0, 1.7, 7.4, 0, math.pi, 0), Color = body },
		{ Name = "FranjaLomo", Size = Vector3.new(0.7, 0.1, 4.2), At = C(0, 2.12, 4.4), Color = trim, Material = "Neon" },
		-- Morro afilado (dos cuñas: perfil de diamante) con la punta oscura
		{ Name = "MorroSup", Class = "WedgePart", Size = Vector3.new(3.6, 1.3, 7), At = C(0, 0.65, -7), Color = body, Shadow = true },
		{ Name = "MorroInf", Class = "WedgePart", Size = Vector3.new(3.6, 1.3, 7), At = C(0, -0.65, -7, 0, 0, math.pi), Color = K.Dark },
		{ Name = "FranjaMorro", Size = Vector3.new(0.8, 0.06, 4.6), At = C(0, 0.69, -7) * CFrame.Angles(-math.atan(1.3 / 7), 0, 0), Color = accent },
		-- Tomas de aire a los lados
		{ Name = "TomaIzq", Size = Vector3.new(1.1, 1.7, 4.2), At = C(-2.6, -0.3, -0.6), Color = accent },
		{ Name = "TomaDer", Size = Vector3.new(1.1, 1.7, 4.2), At = C(2.6, -0.3, -0.6), Color = accent },
		{ Name = "BocaIzq", Size = Vector3.new(0.8, 1.3, 0.2), At = C(-2.6, -0.3, -2.75), Color = rgb(12, 14, 20) },
		{ Name = "BocaDer", Size = Vector3.new(0.8, 1.3, 0.2), At = C(2.6, -0.3, -2.75), Color = rgb(12, 14, 20) },
		-- Cabina: burbuja de cristal (parabrisas inclinado, techo y caída de atrás) y el marco
		{ Name = "CabinaFrente", Class = "WedgePart", Size = Vector3.new(3, 1.7, 2.6), At = C(0, 2.15, -3.2), Color = K.Glass, Material = "Glass", Transparency = 0.42, Reflectance = 0.15 },
		{ Name = "Cabina", Size = Vector3.new(3, 1.7, 3), At = C(0, 2.15, -0.4), Color = K.Glass, Material = "Glass", Transparency = 0.42, Reflectance = 0.15 },
		{ Name = "CabinaAtras", Class = "WedgePart", Size = Vector3.new(3, 1.7, 1.6), At = C(0, 2.15, 1.9, 0, math.pi, 0), Color = K.Glass, Material = "Glass", Transparency = 0.42, Reflectance = 0.15 },
		{ Name = "Marco", Size = Vector3.new(0.22, 0.14, 3.2), At = C(0, 3.04, -0.4), Color = K.Dark },
		{ Name = "MarcoFrente", Size = Vector3.new(3.1, 0.18, 0.22), At = C(0, 1.38, -4.45), Color = K.Dark },
		-- El asiento, hundido en el fuselaje: el piloto queda dentro (cabeza y hombros en la burbuja)
		{ Name = "ShipSeat", Class = "Seat", Size = Vector3.new(2, 0.4, 2), At = C(0, -1.25, -0.3), Color = K.Dark, Transparency = 1 },
		{ Name = "Respaldo", Size = Vector3.new(2.2, 3, 0.4), At = C(0, 0.45, 1.1), Color = K.Dark },
	}
	for _, side in { -1, 1 } do
		local s = if side < 0 then "Izq" else "Der"
		-- Ala en delta: una cuña tumbada (borde de ataque en flecha, la punta atrás)
		table.insert(list, { Name = "Ala" .. s, Class = "WedgePart", Size = Vector3.new(0.45, 7.6, 8.4), At = C(side * (2.2 + 3.8), -0.35, 2.3, 0, 0, -side * HALF), Color = body, Shadow = true })
		table.insert(list, { Name = "AlaFranja" .. s, Class = "WedgePart", Size = Vector3.new(0.1, 3.2, 3.5), At = C(side * (2.2 + 3.8 + 2.2), -0.07, 4.75, 0, 0, -side * HALF), Color = accent })
		-- Góndola sobre el ala (sale por detrás del borde de salida), con la luz de navegación delante
		table.insert(list, { Name = "Gondola" .. s, Size = Vector3.new(0.7, 0.7, 4.4), At = C(side * 7.6, -0.35, 6.2), Color = accent })
		table.insert(list, { Name = "LuzNav" .. s, Shape = "Ball", Size = Vector3.new(0.75, 0.75, 0.75), At = C(side * 7.6, -0.35, 3.85), Color = if side < 0 then K.NavLeft else K.NavRight, Material = "Neon" })
		-- Deriva inclinada hacia fuera
		table.insert(list, { Name = "Deriva" .. s, Class = "WedgePart", Size = Vector3.new(0.35, 3.2, 3.8), At = C(side * 1.55, 2.75, 5.3) * CFrame.Angles(0, 0, -side * 0.32), Color = accent })
		-- Motor: góndola, tobera, brillo y llama (las anima el cliente)
		local mx = side * 1.3
		table.insert(list, { Name = "Motor" .. s, Shape = "Cylinder", Size = Vector3.new(4.4, 2.1, 2.1), At = C(mx, -0.25, 5.7, 0, HALF, 0), Color = K.Metal, Material = "Metal" })
		table.insert(list, { Name = "Tobera" .. s, Shape = "Cylinder", Size = Vector3.new(0.7, 2.3, 2.3), At = C(mx, -0.25, 8.1, 0, HALF, 0), Color = K.Dark, Material = "Metal" })
		table.insert(list, { Name = ShipModel.Exhaust, Shape = "Cylinder", Size = Vector3.new(0.3, 1.6, 1.6), At = C(mx, -0.25, 8.4, 0, HALF, 0), Color = K.Exhaust, Material = "Neon" })
		table.insert(list, { Name = ShipModel.Flame, Shape = "Cylinder", Size = Vector3.new(2.2, 1.1, 1.1), At = C(mx, -0.25, 9.6, 0, HALF, 0), Color = K.Exhaust, Material = "Neon", Transparency = 0.45 })
		-- Cañón bajo la raíz del ala (los láseres salen de aquí: ShipWeapons.Laser.Muzzle)
		table.insert(list, { Name = "Canon" .. s, Shape = "Cylinder", Size = Vector3.new(4.2, 0.45, 0.45), At = C(side * 2.6, -0.85, -4.3, 0, HALF, 0), Color = K.Dark, Material = "Metal" })
	end
	table.insert(list, { Name = "LuzCola", Shape = "Ball", Size = Vector3.new(0.55, 0.55, 0.55), At = C(0, 2.25, 6.5), Color = rgb(255, 255, 255), Material = "Neon" })
	return list
end

---------------------------------------------------------------------
-- Enemigos
---------------------------------------------------------------------
local function drone(): { PartSpec }
	local core = rgb(48, 50, 60)
	local glow = rgb(255, 140, 40)
	local list: { PartSpec } = {
		{ Name = "Nucleo", Shape = "Ball", Size = Vector3.new(4.2, 4.2, 4.2), At = C(0, 0, 0), Color = core, Material = "Metal" },
		{ Name = "Visera", Shape = "Cylinder", Size = Vector3.new(0.8, 2.8, 2.8), At = C(0, 0, -1.75, 0, HALF, 0), Color = rgb(20, 20, 26), Material = "Metal" },
		{ Name = "Ojo", Shape = "Ball", Size = Vector3.new(1.7, 1.7, 1.7), At = C(0, 0, -2.05), Color = rgb(255, 50, 50), Material = "Neon" },
		{ Name = "Pincho", Class = "WedgePart", Size = Vector3.new(0.6, 1.8, 1.2), At = C(0, -2.6, 0.2, math.pi, 0, 0), Color = core, Material = "Metal" },
	}
	for i = 0, 3 do
		local a = math.rad(45 + i * 90)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local mid = dir * 2.6
		local tip = dir * 4.4
		table.insert(list, { Name = "Brazo", Size = Vector3.new(0.5, 0.45, 3.2), At = CFrame.new(mid) * CFrame.Angles(0, -a + HALF, 0), Color = core, Material = "Metal" })
		table.insert(list, { Name = "Rotor", Shape = "Cylinder", Size = Vector3.new(0.25, 3, 3), At = CFrame.new(tip + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, HALF), Color = glow, Material = "Neon", Transparency = 0.35 })
	end
	return list
end

local function enemyFighter(): { PartSpec }
	local hull = rgb(58, 40, 82)
	local dark = rgb(26, 20, 36)
	local glow = rgb(255, 70, 50)
	local list: { PartSpec } = {
		{ Name = "Fuselaje", Size = Vector3.new(2.8, 1.7, 7.5), At = C(0, 0, 0.5), Color = hull, Material = "Metal" },
		{ Name = "MorroSup", Class = "WedgePart", Size = Vector3.new(2.4, 0.85, 4.5), At = C(0, 0.42, -5.5), Color = hull, Material = "Metal" },
		{ Name = "MorroInf", Class = "WedgePart", Size = Vector3.new(2.4, 0.85, 4.5), At = C(0, -0.42, -5.5, 0, 0, math.pi), Color = dark, Material = "Metal" },
		{ Name = "Cabina", Class = "WedgePart", Size = Vector3.new(1.8, 1, 2.6), At = C(0, 1.35, -1.6), Color = rgb(255, 90, 60), Material = "Glass", Transparency = 0.25 },
		{ Name = "Motor", Size = Vector3.new(2.2, 1.2, 0.5), At = C(0, 0, 4.4), Color = glow, Material = "Neon" },
	}
	for _, side in { -1, 1 } do
		local s = if side < 0 then "Izq" else "Der"
		-- Alas en flecha invertida: la punta hacia delante (silueta en W)
		table.insert(list, { Name = "Ala" .. s, Class = "WedgePart", Size = Vector3.new(0.35, 6, 5), At = C(side * (1.4 + 3), -0.2, 1.4, 0, math.pi, side * HALF), Color = hull, Material = "Metal" })
		table.insert(list, { Name = "Pua" .. s, Class = "WedgePart", Size = Vector3.new(0.3, 2.6, 2.8), At = C(side * 7.25, 0.9, -0.9), Color = glow, Material = "Neon" })
		table.insert(list, { Name = "Canon" .. s, Shape = "Cylinder", Size = Vector3.new(3, 0.4, 0.4), At = C(side * 1.6, -0.6, -3.4, 0, HALF, 0), Color = dark, Material = "Metal" })
		table.insert(list, { Name = "Aleta" .. s, Class = "WedgePart", Size = Vector3.new(0.3, 1.8, 2.2), At = C(side * 1.1, 1.6, 3.4) * CFrame.Angles(0, 0, side * 0.35), Color = dark, Material = "Metal" })
	end
	return list
end

local function turret(): { PartSpec }
	local armor = rgb(76, 80, 92)
	local dark = rgb(34, 36, 44)
	local list: { PartSpec } = {
		{ Name = "Base", Shape = "Cylinder", Size = Vector3.new(4, 9, 9), At = C(0, -3, 0, 0, 0, HALF), Color = dark, Material = "Metal", Static = true },
		{ Name = "AroBase", Shape = "Cylinder", Size = Vector3.new(0.3, 9.3, 9.3), At = C(0, -1.05, 0, 0, 0, HALF), Color = rgb(255, 90, 40), Material = "Neon", Transparency = 0.35, Static = true },
		{ Name = "Cupula", Shape = "Ball", Size = Vector3.new(5.6, 5.6, 5.6), At = C(0, 0, 0), Color = armor, Material = "Metal" },
		{ Name = "Placa", Size = Vector3.new(4.6, 2.2, 1.2), At = C(0, 0.1, -2.5), Color = dark, Material = "Metal" },
		{ Name = "Sensor", Shape = "Ball", Size = Vector3.new(1.3, 1.3, 1.3), At = C(0, 1.7, -2.3), Color = rgb(255, 50, 50), Material = "Neon" },
	}
	for _, side in { -1, 1 } do
		table.insert(list, { Name = "Canon", Shape = "Cylinder", Size = Vector3.new(6, 0.8, 0.8), At = C(side * 1.2, -0.1, -5, 0, HALF, 0), Color = dark, Material = "Metal" })
		table.insert(list, { Name = "BocaCanon", Shape = "Cylinder", Size = Vector3.new(0.3, 0.95, 0.95), At = C(side * 1.2, -0.1, -8, 0, HALF, 0), Color = rgb(255, 120, 60), Material = "Neon" })
	end
	return list
end

local SPECS: { [string]: (Options?) -> { PartSpec } } = {
	Caza = fighter,
	Dron = drone,
	CazaEnemigo = enemyFighter,
	Torreta = turret,
}
ShipModel.Kinds = { "Caza", "Dron", "CazaEnemigo", "Torreta" }

-- Radio del Root de cada uno (para la selección y los impactos: la pieza que se ve)
local ROOTS: { [string]: Vector3 } = {
	Caza = Vector3.new(4, 2, 8),
	Dron = Vector3.new(4, 4, 4),
	CazaEnemigo = Vector3.new(3, 1.6, 8),
	Torreta = Vector3.new(5, 5, 5),
}

function ShipModel.specs(kind: string, opts: Options?): { PartSpec }
	local fn = SPECS[kind] or SPECS.Caza
	return fn(opts)
end

---------------------------------------------------------------------
-- Construir (Roblox o Lune)
---------------------------------------------------------------------
local function material(name: string?): Enum.Material
	local ok, m = pcall(function()
		return (Enum.Material :: any)[name or "SmoothPlastic"]
	end)
	return if ok and m then m else Enum.Material.SmoothPlastic
end

local function shape(name: string?): Enum.PartType
	if name == "Ball" then
		return Enum.PartType.Ball
	elseif name == "Cylinder" then
		return Enum.PartType.Cylinder
	end
	return Enum.PartType.Block
end

local function trail(parent: BasePart, name: string, a: Vector3, b: Vector3, color: Color3, life: number, transparency: number, emission: number)
	local a0 = Instance.new("Attachment")
	a0.Name = name .. "A"
	a0.Position = a
	a0.Parent = parent
	local a1 = Instance.new("Attachment")
	a1.Name = name .. "B"
	a1.Position = b
	a1.Parent = parent
	local t = Instance.new("Trail")
	t.Name = name
	t.Attachment0 = a0
	t.Attachment1 = a1
	t.Color = ColorSequence.new(color)
	t.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, transparency), NumberSequenceKeypoint.new(1, 1) })
	t.Lifetime = life
	t.LightEmission = emission
	t.FaceCamera = true
	t.MinLength = 0.2
	t.Parent = parent
end

function ShipModel.build(kind: string, cf: CFrame, opts: Options?): Model
	local model = Instance.new("Model")
	model.Name = kind
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = ROOTS[kind] or ROOTS.Caza
	root.CFrame = cf
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	root.CastShadow = false
	root.Parent = model
	model.PrimaryPart = root
	local parts: { [string]: BasePart } = {}
	for _, spec in ShipModel.specs(kind, opts) do
		local p = Instance.new(spec.Class or "Part") :: BasePart
		p.Name = spec.Name
		if p:IsA("Part") and spec.Class ~= "Seat" then
			(p :: Part).Shape = shape(spec.Shape)
		end
		p.Size = spec.Size
		-- (la base de la torreta, siempre derecha: solo la posición)
		p.CFrame = if spec.Static then CFrame.new(cf.Position) * spec.At else cf * spec.At
		p.Color = spec.Color
		p.Material = material(spec.Material)
		p.Transparency = spec.Transparency or 0
		p.Reflectance = spec.Reflectance or 0
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.CastShadow = spec.Shadow == true
		p.CanCollide = false
		p.CanTouch = false
		pcall(function()
			p.CanQuery = false
		end)
		if spec.Static then
			p.Anchored = true
			p:SetAttribute("Static", true)
		else
			p.Anchored = false
			p.Massless = true
			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = p
			w.Parent = p
		end
		p.Parent = model
		if parts[spec.Name] == nil then
			parts[spec.Name] = p
		end
	end
	if kind == "Caza" then
		-- Estelas: brillo de los motores y vapor fino en las puntas de las alas
		local K = ShipModel.Colors
		for _, side in { "Izq", "Der" } do
			local tobera = parts["Tobera" .. side]
			if tobera then
				-- (el cilindro va girado: su eje X local es el eje de la nave)
				trail(tobera, "EstelaMotor", Vector3.new(-0.4, 0, 0.55), Vector3.new(-0.4, 0, -0.55), K.Exhaust, 0.28, 0.25, 1)
			end
			local pod = parts["Gondola" .. side]
			if pod then
				trail(pod, "EstelaAla", Vector3.new(0, 0.08, 2.1), Vector3.new(0, -0.08, 2.1), rgb(235, 245, 255), 0.55, 0.55, 0.3)
			end
		end
		for _, glow in model:GetChildren() do
			if glow.Name == ShipModel.Exhaust and glow:IsA("BasePart") then
				local light = Instance.new("PointLight")
				light.Name = "LuzMotor"
				light.Color = K.Exhaust
				light.Range = 14
				light.Brightness = 2
				light.Shadows = false
				light.Parent = glow
			end
		end
	end
	return model
end

return ShipModel
