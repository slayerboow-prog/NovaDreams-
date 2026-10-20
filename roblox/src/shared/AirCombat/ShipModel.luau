-- ShipModel: los modelos de las naves del combate aéreo y del espacio (diseño propio, sin marcas ni
-- nada copiado de ninguna saga). Lo usan World/AirArena (la arena de pruebas), Services/AirCombatService,
-- World/SpaceWorld (la nave de exposición del puerto espacial) y el espacio encima de Valmar: la MISMA
-- nave en todas partes.
--
--   ShipModel.build(kind, cf, opts?) -> Model   (PrimaryPart = "Root", invisible y ANCLADO)
--     "Caza"         la nave del jugador, el «HX-7 Halcón» (docs/espacio-aaa/nave-realista.md). Dos formas:
--                    * MALLA (la buena): las piezas hechas en Blender (scripts/nave/nave_blender.py:
--                      Fuselaje, CabinaFrente, Cabina de cristal, Alas, Armas, Motores, TrenPata, BrilloAzul,
--                      BrilloRojo y la versión lejana NaveLOD), con sus texturas PBR. Solo cuando el
--                      servidor ya las ha cargado (World/NaveLoader con los ids de NaveAssetIds, que escribe
--                      scripts/upload-nave.sh al publicar): ShipModel.setMeshTemplate.
--                    * PIEZAS (respaldo): si no hay ids o falla la carga, la de siempre con piezas de
--                      Roblox (blanca, alas afiladas con puntas rojas, DOS motores azules), ≈ 47 piezas.
--                    Las dos tienen lo mismo para el resto del juego: asiento "ShipSeat" hundido en el
--                    fuselaje (el piloto DENTRO: cabeza y hombros bajo la burbuja), motores con brillo y
--                    llama ("Escape" / "Llama": los anima Controllers/AirCombatFx), luces de navegación
--                    ("LuzNavIzq" roja, "LuzNavDer" verde, "LuzCola" blanca), tren ("TrenPata"/"TrenPie",
--                    escondido: Transparency 1), estelas (Trail) y el Root (la caja de choque/selección).
--                    El atributo "NaveVisual" del modelo dice cuál es ("Malla" o "Piezas").
--     "Dron"         dron enemigo en X: núcleo oscuro, ojo rojo, cuatro rotores naranjas que brillan.
--     "CazaEnemigo"  caza enemigo de alas en flecha invertida (silueta en W), morado oscuro con brillos
--                    rojos: no se confunde con el tuyo ni de lejos.
--     "Torreta"      torreta de dos cañones con cúpula blindada y sensor rojo; su base ("Base",
--                    atributo Static) va anclada aparte.
--   Todas las piezas, menos el Root, van soldadas al Root (WeldConstraint), sin masa ni choques: se
--   mueve todo moviendo el Root (su CFrame).
--
--   ShipModel.specs(kind, opts?) -> { PartSpec }   las piezas (puro: lo prueban scripts/test-aircombat
--                                                   y lo dibuja el render de vista previa)
--   ShipModel.setMeshTemplate(folder?)  las MeshPart ya preparadas (World/NaveLoader); nil = respaldo
--   ShipModel.meshReady()               ¿hay malla?
--   ShipModel.meshPlan()                las piezas de la malla (shared/AirCombat/NaveMalla): nombre,
--                                       sitio, tamaño, material
--   ShipModel.upgrade(model)            cambia una nave ya hecha con piezas por la de malla (sin tocar
--                                       el Root ni el asiento: el piloto sigue sentado)
--   ShipModel.lodLevel(dist, own, tier) "Alta" o "Baja" (la tuya siempre de cerca; las de los demás
--                                       lejos, o en el móvil, con la NaveLOD de ≈ 3 mil triángulos)
--   ShipModel.applyLod(model, level)    (en el cliente) enseña una u otra
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
	Body = rgb(214, 218, 226),
	Accent = rgb(60, 150, 255),
	Trim = rgb(235, 60, 40),
	Dark = rgb(38, 42, 50),
	Metal = rgb(92, 98, 112),
	Glass = rgb(120, 200, 255),
	Exhaust = rgb(90, 200, 255),
	NavLeft = rgb(255, 60, 60),
	NavRight = rgb(60, 255, 120),
}

-- Los motores y luces que anima el cliente (nombres de pieza)
ShipModel.Exhaust = "Escape"
ShipModel.Flame = "Llama"
ShipModel.NavLights = { "LuzNavIzq", "LuzNavDer", "LuzCola" }
ShipModel.Gear = "TrenPata"
ShipModel.GearPad = "TrenPie"
ShipModel.HullVariant = "NaveCasco" -- MaterialVariant de la chapa (shared/Cosmos/EspacioLook), si existe

local function C(x: number, y: number, z: number, rx: number?, ry: number?, rz: number?): CFrame
	return CFrame.new(x, y, z) * CFrame.Angles(rx or 0, ry or 0, rz or 0)
end

local HALF = math.pi / 2

---------------------------------------------------------------------
-- La nave del jugador
---------------------------------------------------------------------
local function fighter(opts: Options?): { PartSpec }
	-- (El RESPALDO de la malla: caza LARGO de tres cascos —fuselaje central con morro muy largo y dos
	-- cascos laterales pegados—, alas afiladas hacia atrás con puntas rojas y DOS motores con un brillo
	-- azul intenso, con los colores del HX-7. La cabina, el asiento y el tren son los de siempre.)
	local o = opts or {}
	local K = ShipModel.Colors
	local body = o.Body or K.Body
	local accent = o.Accent or K.Accent
	local trim = o.Trim or K.Trim
	local list: { PartSpec } = {
		-- Fuselaje central (de z = -3.5 a 5.5) con la panza oscura y el lomo detrás de la cabina
		{ Name = "Fuselaje", Size = Vector3.new(4.4, 2.6, 9), At = C(0, 0, 1), Color = body, Shadow = true },
		{ Name = "Panza", Size = Vector3.new(3.6, 0.8, 14), At = C(0, -1.55, 0.5), Color = K.Dark },
		{ Name = "Lomo", Size = Vector3.new(2.4, 0.8, 4.2), At = C(0, 1.7, 4.4), Color = body },
		{ Name = "LomoCola", Class = "WedgePart", Size = Vector3.new(2.4, 0.8, 1.8), At = C(0, 1.7, 7.4, 0, math.pi, 0), Color = body },
		{ Name = "FranjaLomo", Size = Vector3.new(0.7, 0.1, 4.2), At = C(0, 2.12, 4.4), Color = trim, Material = "Neon" },
		-- Morro MUY largo y afilado (dos cuñas: perfil de diamante), con una franja azul
		{ Name = "MorroSup", Class = "WedgePart", Size = Vector3.new(2.4, 1.3, 11), At = C(0, 0.65, -9), Color = body, Shadow = true },
		{ Name = "MorroInf", Class = "WedgePart", Size = Vector3.new(2.4, 1.3, 11), At = C(0, -0.65, -9, 0, 0, math.pi), Color = K.Dark },
		{ Name = "FranjaMorro", Size = Vector3.new(0.6, 0.06, 7.4), At = C(0, 0.69, -9) * CFrame.Angles(-math.atan(1.3 / 11), 0, 0), Color = accent, Material = "Neon" },
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
		local px = side * 3.6
		-- Casco lateral (multicasco): largo, pegado al fuselaje, con la punta en cuña
		table.insert(list, { Name = "Gondola" .. s, Size = Vector3.new(2, 1.9, 15), At = C(px, -0.5, 1.5), Color = body, Shadow = true })
		table.insert(list, { Name = "PuntaGondola" .. s, Class = "WedgePart", Size = Vector3.new(2, 1.9, 4), At = C(px, -0.5, -8), Color = accent })
		-- Ala afilada hacia atrás (una cuña tumbada) con su franja
		table.insert(list, { Name = "Ala" .. s, Class = "WedgePart", Size = Vector3.new(0.45, 8, 9), At = C(side * (4.6 + 4), -0.6, 3.5, 0, 0, -side * HALF), Color = body, Shadow = true })
		table.insert(list, { Name = "AlaFranja" .. s, Class = "WedgePart", Size = Vector3.new(0.1, 3.2, 3.5), At = C(side * (4.6 + 4 + 2.2), -0.32, 5.6, 0, 0, -side * HALF), Color = accent })
		table.insert(list, { Name = "LuzNav" .. s, Shape = "Ball", Size = Vector3.new(0.75, 0.75, 0.75), At = C(side * 12.3, -0.6, 7.6), Color = if side < 0 then K.NavLeft else K.NavRight, Material = "Neon" })
		-- Deriva inclinada hacia fuera, sobre el casco lateral
		table.insert(list, { Name = "Deriva" .. s, Class = "WedgePart", Size = Vector3.new(0.35, 2.8, 3.8), At = C(px, 1.3, 6.5) * CFrame.Angles(0, 0, -side * 0.32), Color = accent })
		-- Motor del casco lateral: góndola, tobera, brillo y llama (las anima el cliente)
		table.insert(list, { Name = "Motor" .. s, Shape = "Cylinder", Size = Vector3.new(3.6, 2.8, 2.8), At = C(px, -0.5, 9.6, 0, HALF, 0), Color = K.Metal, Material = "Metal" })
		table.insert(list, { Name = "Tobera" .. s, Shape = "Cylinder", Size = Vector3.new(0.7, 3.2, 3.2), At = C(px, -0.5, 11.5, 0, HALF, 0), Color = K.Dark, Material = "Metal" })
		table.insert(list, { Name = ShipModel.Exhaust, Shape = "Cylinder", Size = Vector3.new(0.3, 2.7, 2.7), At = C(px, -0.5, 11.85, 0, HALF, 0), Color = K.Exhaust, Material = "Neon" })
		table.insert(list, { Name = ShipModel.Flame, Shape = "Cylinder", Size = Vector3.new(3, 1.6, 1.6), At = C(px, -0.5, 13.5, 0, HALF, 0), Color = K.Exhaust, Material = "Neon", Transparency = 0.45 })
		-- Punta del ala roja que brilla (como la referencia)
		table.insert(list, { Name = "PuntaAla" .. s, Size = Vector3.new(0.5, 0.3, 1.4), At = C(side * 12.2, -0.6, 7.2), Color = trim, Material = "Neon" })
		-- Cañón bajo el morro (los láseres salen de aquí: ShipWeapons.Laser.Muzzle)
		table.insert(list, { Name = "Canon" .. s, Shape = "Cylinder", Size = Vector3.new(5, 0.45, 0.45), At = C(side * 2.6, -1.4, -6.5, 0, HALF, 0), Color = K.Dark, Material = "Metal" })
	end
	table.insert(list, { Name = "LuzCola", Shape = "Ball", Size = Vector3.new(0.55, 0.55, 0.55), At = C(0, 2.25, 6.5), Color = rgb(255, 255, 255), Material = "Neon" })
	-- Tren de aterrizaje (planetas: shared/Cosmos/Landing). Escondido (Transparency 1) y lo enseña el
	-- cliente cerca del suelo (Controllers/AirCombatClient). Patas cortas: posada, el Root queda a
	-- Landing.RestHeight (4,6) sobre el suelo.
	for _, leg in { { 0, -5.2 }, { -2.6, 3.4 }, { 2.6, 3.4 } } do
		table.insert(list, { Name = ShipModel.Gear, Shape = "Cylinder", Size = Vector3.new(2.6, 0.45, 0.45), At = C(leg[1], -3.0, leg[2], 0, 0, HALF), Color = K.Metal, Material = "Metal", Transparency = 1 })
		table.insert(list, { Name = ShipModel.GearPad, Shape = "Cylinder", Size = Vector3.new(0.3, 1.5, 1.5), At = C(leg[1], -4.35, leg[2], 0, 0, HALF), Color = K.Dark, Material = "Metal", Transparency = 1 })
	end
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

-- (Espacio AAA) El dron aliado de la nave: pequeño, con su color según el tipo (combate, defensa,
-- exploración, reparación: opts.Accent), núcleo que brilla y cuatro aletas
local function allyDrone(opts: Options?): { PartSpec }
	local o = opts or {}
	local color = o.Accent or rgb(120, 220, 255)
	local list: { PartSpec } = {
		{ Name = "Nucleo", Shape = "Ball", Size = Vector3.new(2.4, 2.4, 2.4), At = C(0, 0, 0), Color = rgb(60, 66, 80), Material = "Metal" },
		{ Name = "Ojo", Shape = "Ball", Size = Vector3.new(1.2, 1.2, 1.2), At = C(0, 0, -1), Color = color, Material = "Neon" },
		{ Name = "Aro", Shape = "Cylinder", Size = Vector3.new(0.3, 3.4, 3.4), At = C(0, 0, 0, 0, 0, HALF), Color = color, Material = "Neon", Transparency = 0.4 },
	}
	for i = 0, 3 do
		local a = i * HALF + HALF / 2
		table.insert(list, { Name = "Aleta", Size = Vector3.new(0.25, 0.25, 2), At = CFrame.new(math.cos(a) * 1.6, math.sin(a) * 1.6, 0.4), Color = rgb(150, 160, 178), Material = "Metal" })
	end
	return list
end

-- (Trabajos espaciales y Varkun) INTERCEPTOR pirata y AGUJA de los Hilanderos: un dardo largo y fino
-- (se reconoce por la silueta: nada de alas grandes), con dos aletas y el motor que brilla. La Aguja es la
-- misma silueta en hueso y violeta, con «hilos» de luz en vez de aletas (docs/universo/diseno-espacio.md §2)
local function dart(hull: Color3, dark: Color3, glow: Color3, threads: boolean): { PartSpec }
	local list: { PartSpec } = {
		{ Name = "Fuselaje", Size = Vector3.new(1.6, 1.2, 8), At = C(0, 0, 0.6), Color = hull, Material = "Metal" },
		{ Name = "Morro", Class = "WedgePart", Size = Vector3.new(1.4, 1, 5), At = C(0, 0, -5.8), Color = dark, Material = "Metal" },
		{ Name = "Cabina", Class = "WedgePart", Size = Vector3.new(1.1, 0.7, 2), At = C(0, 0.85, -1.4), Color = glow, Material = "Glass", Transparency = 0.3 },
		{ Name = "Motor", Size = Vector3.new(1.4, 1, 0.4), At = C(0, 0, 4.8), Color = glow, Material = "Neon" },
	}
	for _, side in { -1, 1 } do
		local s = if side < 0 then "Izq" else "Der"
		if threads then
			table.insert(list, { Name = "Hilo" .. s, Size = Vector3.new(0.18, 0.18, 9), At = C(side * 2.2, 0, 1.5) * CFrame.Angles(0, side * 0.18, 0), Color = glow, Material = "Neon", Transparency = 0.2 })
		else
			table.insert(list, { Name = "Aleta" .. s, Class = "WedgePart", Size = Vector3.new(0.25, 2.6, 3.2), At = C(side * 1.6, 0, 2.6, 0, 0, side * HALF), Color = dark, Material = "Metal" })
		end
	end
	return list
end

local function interceptor(): { PartSpec }
	return dart(rgb(150, 60, 40), rgb(40, 30, 30), rgb(255, 150, 60), false)
end

local function needle(): { PartSpec }
	return dart(rgb(232, 226, 214), rgb(90, 80, 110), rgb(190, 120, 255), true)
end

-- Cañonera pirata (PESADA, de apoyo): casco ancho, cañón grande delante y una antena que brilla verde
-- (la que recarga los escudos de los suyos)
local function gunship(): { PartSpec }
	local hull = rgb(70, 64, 58)
	local dark = rgb(30, 28, 26)
	local glow = rgb(255, 110, 40)
	local list: { PartSpec } = {
		{ Name = "Casco", Size = Vector3.new(7, 4, 14), At = C(0, 0, 0), Color = hull, Material = "Metal" },
		{ Name = "Proa", Class = "WedgePart", Size = Vector3.new(6, 3, 5), At = C(0, -0.2, -9.4), Color = dark, Material = "Metal" },
		{ Name = "Puente", Size = Vector3.new(3, 2, 4), At = C(0, 3, 2), Color = dark, Material = "Metal" },
		{ Name = "Ventanal", Size = Vector3.new(2.6, 0.6, 0.2), At = C(0, 3.3, -0.05), Color = glow, Material = "Neon" },
		{ Name = "Canon", Shape = "Cylinder", Size = Vector3.new(9, 1.4, 1.4), At = C(0, -1.4, -8, 0, HALF, 0), Color = dark, Material = "Metal" },
		{ Name = "BocaCanon", Shape = "Cylinder", Size = Vector3.new(0.4, 1.6, 1.6), At = C(0, -1.4, -12.6, 0, HALF, 0), Color = glow, Material = "Neon" },
		{ Name = "Antena", Size = Vector3.new(0.3, 3, 0.3), At = C(0, 5.2, 4), Color = dark, Material = "Metal" },
		{ Name = "Apoyo", Shape = "Ball", Size = Vector3.new(1.2, 1.2, 1.2), At = C(0, 6.9, 4), Color = rgb(90, 255, 140), Material = "Neon" },
	}
	for _, side in { -1, 1 } do
		local s = if side < 0 then "Izq" else "Der"
		table.insert(list, { Name = "Motor" .. s, Size = Vector3.new(2, 2, 0.5), At = C(side * 2.4, 0, 7.2), Color = glow, Material = "Neon" })
		table.insert(list, { Name = "Blindaje" .. s, Size = Vector3.new(1, 3, 10), At = C(side * 4, 0, 0), Color = dark, Material = "Metal" })
	end
	return list
end

-- Carguero de los convoyes (amigo): caja de carga larga con contenedores, cabina delante y motores
local function freighter(): { PartSpec }
	local hull = rgb(200, 196, 180)
	local dark = rgb(60, 64, 72)
	local glow = rgb(110, 200, 255)
	local list: { PartSpec } = {
		{ Name = "Espina", Size = Vector3.new(3, 3, 22), At = C(0, 0, 0), Color = dark, Material = "Metal" },
		{ Name = "Cabina", Size = Vector3.new(5, 4, 5), At = C(0, 0.8, -12.5), Color = hull, Material = "Metal" },
		{ Name = "Ventanal", Size = Vector3.new(4, 1, 0.2), At = C(0, 1.6, -15.1), Color = glow, Material = "Neon" },
		{ Name = "Baliza", Shape = "Ball", Size = Vector3.new(1, 1, 1), At = C(0, 3.4, -12.5), Color = rgb(90, 255, 140), Material = "Neon" },
	}
	local colors = { rgb(220, 120, 50), rgb(70, 130, 200), rgb(230, 190, 60) }
	for i = 1, 3 do
		table.insert(list, { Name = "Contenedor", Size = Vector3.new(6, 4.4, 5), At = C(0, 0, -6 + i * 5.5), Color = colors[i], Material = "Metal" })
	end
	for _, side in { -1, 1 } do
		local s = if side < 0 then "Izq" else "Der"
		table.insert(list, { Name = "Motor" .. s, Shape = "Cylinder", Size = Vector3.new(3, 2.2, 2.2), At = C(side * 2.2, 0, 12, 0, HALF, 0), Color = dark, Material = "Metal" })
		table.insert(list, { Name = "Tobera" .. s, Shape = "Cylinder", Size = Vector3.new(0.3, 2, 2), At = C(side * 2.2, 0, 13.6, 0, HALF, 0), Color = glow, Material = "Neon" })
	end
	return list
end

local SPECS: { [string]: (Options?) -> { PartSpec } } = {
	DronAliado = allyDrone,
	Caza = fighter,
	Dron = drone,
	CazaEnemigo = enemyFighter,
	Torreta = turret,
	Interceptor = interceptor,
	Aguja = needle,
	Pesada = gunship,
	Carguero = freighter,
}
ShipModel.Kinds = { "Caza", "Dron", "CazaEnemigo", "Torreta", "Interceptor", "Aguja", "Pesada", "Carguero" }

-- Radio del Root de cada uno (para la selección y los impactos: la pieza que se ve)
local ROOTS: { [string]: Vector3 } = {
	Caza = Vector3.new(4, 2, 8),
	Dron = Vector3.new(4, 4, 4),
	CazaEnemigo = Vector3.new(3, 1.6, 8),
	Torreta = Vector3.new(5, 5, 5),
	DronAliado = Vector3.new(2, 2, 2),
	Interceptor = Vector3.new(2, 1.4, 9),
	Aguja = Vector3.new(2, 1.4, 9),
	Pesada = Vector3.new(8, 5, 16),
	Carguero = Vector3.new(6, 5, 26),
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

local function newRoot(model: Model, kind: string, cf: CFrame): Part
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
	return root
end

local function weld(root: BasePart, p: BasePart)
	p.Anchored = false
	p.Massless = true
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = p
	w.Parent = p
end

local function quiet(p: BasePart)
	p.CanCollide = false
	p.CanTouch = false
	pcall(function()
		p.CanQuery = false
	end)
end

-- Crea las piezas de una lista de PartSpec (soldadas al Root) y devuelve la primera de cada nombre
local function addSpecs(model: Model, root: BasePart, cf: CFrame, specs: { PartSpec }): { [string]: BasePart }
	local parts: { [string]: BasePart } = {}
	for _, spec in specs do
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
		quiet(p)
		if spec.Static then
			p.Anchored = true
			p:SetAttribute("Static", true)
		else
			weld(root, p)
		end
		p.Parent = model
		if parts[spec.Name] == nil then
			parts[spec.Name] = p
		end
	end
	return parts
end

local function engineLight(glow: BasePart)
	local light = Instance.new("PointLight")
	light.Name = "LuzMotor"
	light.Color = ShipModel.Colors.Exhaust
	light.Range = 14
	light.Brightness = 2
	light.Shadows = false
	light.Parent = glow
end

local function addTag(model: Model, name: string)
	pcall(function()
		game:GetService("CollectionService"):AddTag(model, name)
	end)
end

---------------------------------------------------------------------
-- La nave de MALLA (Blender: scripts/nave/nave_blender.py; docs/espacio-aaa/nave-realista.md)
---------------------------------------------------------------------
local Malla = require(script.Parent.NaveMalla)
ShipModel.Malla = Malla
ShipModel.MeshTag = "NaveMalla" -- (CollectionService: el cliente elige la versión lejana)
ShipModel.LodName = "NaveLOD"
-- A partir de cuántos studs se ven las naves de los demás con la versión lejana (según el nivel gráfico)
ShipModel.LodDistance = { Low = 70, Medium = 150, High = 260 }

local meshTemplate: Instance? = nil

export type MeshPiece = { Name: string, Asset: string?, At: CFrame, Size: Vector3, Material: string, Color: Color3?, Set: string?, Lod: boolean, Tris: number }

function ShipModel.meshPlan(): { MeshPiece }
	local list: { MeshPiece } = {}
	for _, p in Malla.Pieces do
		table.insert(list, { Name = p.Name, Asset = p.Asset, At = CFrame.new(p.Center), Size = p.Size, Material = p.Material, Color = p.Color, Set = p.Set, Lod = p.Lod == true, Tris = p.Tris })
	end
	return list
end

-- Las piezas que no son malla (las mismas que usa todo el juego): asiento, brillo y llama de cada
-- tobera, luces de navegación
function ShipModel.meshSpecs(): { PartSpec }
	local K = ShipModel.Colors
	local seat = Malla.Seat or Vector3.new(0, -1.25, -0.3)
	local list: { PartSpec } = {
		{ Name = "ShipSeat", Class = "Seat", Size = Vector3.new(2, 0.4, 2), At = CFrame.new(seat), Color = K.Dark, Transparency = 1 },
	}
	local d = (Malla.EngineRadius or 1.6) * 1.55
	for _, e in Malla.Engines do
		table.insert(list, { Name = ShipModel.Exhaust, Shape = "Cylinder", Size = Vector3.new(0.25, d, d), At = C(e.X, e.Y, e.Z, 0, HALF, 0), Color = K.Exhaust, Material = "Neon" })
		table.insert(list, { Name = ShipModel.Flame, Shape = "Cylinder", Size = Vector3.new(3.4, d * 0.6, d * 0.6), At = C(e.X, e.Y, e.Z + 1.9, 0, HALF, 0), Color = K.Exhaust, Material = "Neon", Transparency = 0.45 })
	end
	local tip = Malla.WingTip
	table.insert(list, { Name = "LuzNavIzq", Shape = "Ball", Size = Vector3.new(0.45, 0.45, 0.45), At = CFrame.new(-tip.X, tip.Y, tip.Z), Color = K.NavLeft, Material = "Neon" })
	table.insert(list, { Name = "LuzNavDer", Shape = "Ball", Size = Vector3.new(0.45, 0.45, 0.45), At = CFrame.new(tip.X, tip.Y, tip.Z), Color = K.NavRight, Material = "Neon" })
	table.insert(list, { Name = "LuzCola", Shape = "Ball", Size = Vector3.new(0.4, 0.4, 0.4), At = CFrame.new(Malla.TailLight), Color = rgb(255, 255, 255), Material = "Neon" })
	return list
end

-- Las MeshPart preparadas (World/NaveLoader: cargadas, con su textura o SurfaceAppearance); nil = respaldo
function ShipModel.setMeshTemplate(template: Instance?)
	meshTemplate = template
end

function ShipModel.meshReady(): boolean
	return meshTemplate ~= nil
end

-- Pone las piezas de malla (y las de siempre) en un modelo que ya tiene Root. withSeat: añadir el asiento.
local function fillMesh(model: Model, root: BasePart, cf: CFrame, withSeat: boolean): boolean
	local template = meshTemplate
	if not template then
		return false
	end
	for _, piece in ShipModel.meshPlan() do
		local src = template:FindFirstChild(piece.Name)
		if src and src:IsA("BasePart") then
			local p = src:Clone()
			p.Name = piece.Name
			p.Size = piece.Size
			p.CFrame = cf * piece.At
			quiet(p)
			p.CastShadow = piece.Name == "Fuselaje" or piece.Name == "Alas" or piece.Name == "Motores"
			if piece.Lod then
				p.Transparency = 1 -- (la enseña el cliente, de lejos: applyLod)
				p:SetAttribute("NaveLOD", true)
			elseif piece.Name == ShipModel.Gear then
				p.Transparency = 1 -- (el tren: lo saca el cliente cerca del suelo)
			else
				p:SetAttribute("NaveAlta", true)
			end
			weld(root, p)
			p.Parent = model
		end
	end
	local specs = ShipModel.meshSpecs()
	if not withSeat then
		specs = table.clone(specs)
		table.remove(specs, 1)
	end
	local parts = addSpecs(model, root, cf, specs)
	local K = ShipModel.Colors
	for _, glow in model:GetChildren() do
		if glow.Name == ShipModel.Exhaust and glow:IsA("BasePart") then
			-- (el cilindro va girado: su eje X local es el eje de la nave)
			trail(glow, "EstelaMotor", Vector3.new(-0.2, 0, 0.6), Vector3.new(-0.2, 0, -0.6), K.Exhaust, 0.28, 0.25, 1)
			engineLight(glow)
		end
	end
	for _, side in { "Izq", "Der" } do
		local nav = parts["LuzNav" .. side]
		if nav then
			trail(nav, "EstelaAla", Vector3.new(0, 0.06, 0), Vector3.new(0, -0.06, 0), rgb(235, 245, 255), 0.55, 0.55, 0.3)
		end
	end
	model:SetAttribute("NaveVisual", "Malla")
	addTag(model, ShipModel.MeshTag)
	return true
end

-- Cambia una nave hecha con piezas por la de malla (al terminar de cargarse la malla). No toca el Root
-- (ni sus ProximityPrompt) ni el asiento: el piloto sigue sentado. true si la ha cambiado.
function ShipModel.upgrade(model: Model): boolean
	if not meshTemplate or model:GetAttribute("NaveVisual") ~= "Piezas" then
		return false
	end
	local root = model.PrimaryPart
	if not root then
		return false
	end
	local anchored = false
	for _, d in model:GetChildren() do
		if d:IsA("BasePart") and d ~= root and d.Anchored then
			anchored = true
		end
	end
	local seat = model:FindFirstChild("ShipSeat")
	for _, d in model:GetChildren() do
		if d:IsA("BasePart") and d ~= root and d ~= seat then
			d:Destroy()
		end
	end
	if seat and seat:IsA("BasePart") then
		-- (el asiento se queda, en el sitio del de la malla)
		seat.CFrame = root.CFrame * CFrame.new(Malla.Seat or Vector3.new(0, -1.25, -0.3))
	end
	if not fillMesh(model, root, root.CFrame, false) then
		return false
	end
	if anchored then
		for _, d in model:GetChildren() do
			if d:IsA("BasePart") then
				d.Anchored = true
			end
		end
	end
	return true
end

-- ¿Alta o baja? Tu nave, siempre la buena; las de los demás, la lejana a partir de LodDistance[tier]
function ShipModel.lodLevel(dist: number, own: boolean, tier: string?): string
	if own then
		return "Alta"
	end
	local far = ShipModel.LodDistance[tier or "Medium"] or ShipModel.LodDistance.Medium
	return if dist > far then "Baja" else "Alta"
end

-- (cliente) Enseña la versión alta o la lejana: cambios locales, no se replican
function ShipModel.applyLod(model: Model, level: string)
	if model:GetAttribute("NaveLodVista") == level then
		return
	end
	model:SetAttribute("NaveLodVista", level)
	local low = level == "Baja"
	for _, d in model:GetChildren() do
		if d:IsA("BasePart") then
			if d:GetAttribute("NaveAlta") then
				d.LocalTransparencyModifier = if low then 1 else 0
			elseif d:GetAttribute("NaveLOD") then
				d.Transparency = if low then 0 else 1
			end
		end
	end
end

function ShipModel.build(kind: string, cf: CFrame, opts: Options?): Model
	local model = Instance.new("Model")
	model.Name = kind
	local root = newRoot(model, kind, cf)
	if kind == "Caza" and meshTemplate and fillMesh(model, root, cf, true) then
		return model
	end
	local parts = addSpecs(model, root, cf, ShipModel.specs(kind, opts))
	if kind == "Caza" then
		model:SetAttribute("NaveVisual", "Piezas")
		addTag(model, "NavePiezas") -- (World/NaveLoader las cambia por la de malla si carga después)
		-- Chapa con textura (MaterialVariant «NaveCasco», si ya está en MaterialService: EspacioLook)
		pcall(function()
			local service = game:GetService("MaterialService")
			local variant = service and service:FindFirstChild(ShipModel.HullVariant)
			if variant and variant:IsA("MaterialVariant") then
				local hull = require(script.Parent.Parent.Cosmos.EspacioLook).HullParts
				for name in parts do
					if hull[name] then
						for _, part in model:GetChildren() do
							if part.Name == name and part:IsA("BasePart") then
								part.Material = Enum.Material.Metal
								part.MaterialVariant = ShipModel.HullVariant
							end
						end
					end
				end
			end
		end)
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
				engineLight(glow)
			end
		end
	end
	return model
end

return ShipModel
