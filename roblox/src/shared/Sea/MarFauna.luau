-- MarFauna: los animales del mar con malla de Blender (v125; queja del dueño en la v124: «los animales
-- marinos no tienen textura ni nada, son cuadrados o círculos»).
--
-- Cada animal tiene una MALLA (scripts/map/mar_fauna_blender.py → assets/mar/<Nombre>.fbx con su textura
-- de color tex/<nombre>_color.png: rayas, manchas, vientre claro y ojo) que sube scripts/upload-mar.sh
-- junto al kit del mar (mismos MarAssetIds) y carga World/MarMeshes en ReplicatedStorage.MarMallas.
-- Mientras no estén subidas (o si la moderación retira una), cada animal tiene un RESPALDO de piezas
-- (MarFauna.fallback) que se lee como animal: cuerpo, cola, aletas y ojos; nunca un bloque ni una bola sola.
--
--   MarFauna.Pieces[Nombre] = { Size = {ancho, alto, largo} (studs; la malla mide esto: mira fauna.json),
--       Tri (triángulos), Label, Transparency? } — la cabeza mira hacia −Z (LookVector), como un Part
--   MarFauna.ForCreature[tipo] = { nombres } (Controllers/SeaLife y SeaAmbient)
--   MarFauna.template(nombre) -> MeshPart? (de ReplicatedStorage.MarMallas)
--   MarFauna.fallback(nombre, largo, color, semilla) -> { Piece } (respecto al centro del animal)
--
-- Piece = { Size: Vector3, CFrame: CFrame, Color: Color3, Material: string, Shape: string?, Mesh: string?,
--           Transparency: number? } (como shared/Sea/MarKit y ShoreDecor)

local MarFauna = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles

MarFauna.Pieces = {
	PezCirujano = { Size = { 0.26, 0.8, 1.3 }, Tri = 600, Label = "pez cirujano (azul, paleta oscura, cola amarilla)" },
	PezLoro = { Size = { 0.25, 0.82, 1.5 }, Tri = 600, Label = "pez loro (verde turquesa con escamas rosas)" },
	PezAngel = { Size = { 0.21, 1.17, 1.1 }, Tri = 600, Label = "pez ángel (amarillo con bandas negras)" },
	PezBanco = { Size = { 0.17, 0.35, 1.1 }, Tri = 400, Label = "pez de banco (plateado, lomo azul)" },
	Medusa = { Size = { 1.8, 3.15, 1.8 }, Tri = 1200, Transparency = 0.25, Label = "medusa (campana y tentáculos de cinta, una sola malla)" },
	Manta = { Size = { 10.53, 0.53, 9.0 }, Tri = 700, Label = "manta (lomo oscuro, vientre blanco)" },
	Ballena = { Size = { 31.0, 9.52, 40.0 }, Tri = 1400, Label = "ballena jorobada (aletas largas, surcos)" },
	Tortuga = { Size = { 4.4, 1.11, 4.0 }, Tri = 1000, Label = "tortuga marina (caparazón con escudos)" },
	-- v4 (docs/mar/v4-objetivo.md: «mucha más actividad»)
	Delfin = { Size = { 4.6, 2.59, 8.0 }, Tri = 1000, Label = "delfín mular (dorsal en hoz, melón y pico corto)" },
	Tiburon = { Size = { 4.03, 2.48, 9.0 }, Tri = 1000, Label = "tiburón de arrecife de puntas negras (tranquilo)" },
	MorenaAsomada = { Size = { 2.1, 2.27, 3.0 }, Tri = 800, Label = "morena asomada de su roca (cabeza, cresta y manchas)" },
}

-- Giro de las mallas sobre su eje vertical (el FBX sale con la cabeza hacia −Z: scripts/map/mar_fauna_blender.py
-- exporta con axis_forward −Z). Si en el juego nadaran hacia atrás, aquí se pone math.pi y ya está.
MarFauna.MeshYaw = 0

-- Qué malla usa cada criatura (la primera que haya cargada; los peces se reparten por banco)
MarFauna.ForCreature = {
	School = { "PezBanco" },
	ReefSchool = { "PezCirujano", "PezAngel", "PezLoro" },
	Ray = { "Manta" },
	Turtle = { "Tortuga" },
	Jelly = { "Medusa" },
	Whale = { "Ballena" },
	Manta = { "Manta" },
}

-- La plantilla cargada (ReplicatedStorage.MarMallas.<nombre>), o nil
function MarFauna.template(name: string): MeshPart?
	local ok, found = pcall(function()
		local folder = game:GetService("ReplicatedStorage"):FindFirstChild("MarMallas")
		return folder and folder:FindFirstChild(name)
	end)
	if ok and found and found:IsA("MeshPart") then
		return found
	end
	return nil
end

-- Una copia lista para el mar (anclada, sin choques ni sombra), con el largo pedido (studs)
function MarFauna.clone(name: string, length: number): MeshPart?
	local template = MarFauna.template(name)
	local info = MarFauna.Pieces[name]
	if not template or not info then
		return nil
	end
	local m = template:Clone()
	local k = length / info.Size[3]
	m.Size = V(info.Size[1] * k, info.Size[2] * k, info.Size[3] * k)
	m.Anchored = true
	m.CanCollide = false
	m.CanQuery = false
	m.CanTouch = false
	m.CastShadow = false
	if info.Transparency then
		m.Transparency = info.Transparency
	end
	return m
end

---------------------------------------------------------------------
-- Respaldo de piezas (sin mallas): se lee como animal
---------------------------------------------------------------------
type Piece = { Size: Vector3, CFrame: CFrame, Color: Color3, Material: string, Shape: string?, Mesh: string?, Transparency: number? }

local function add(out: { Piece }, size: Vector3, cf: CFrame, color: Color3, mesh: string?, material: string?, transparency: number?)
	table.insert(out, { Size = size, CFrame = cf, Color = color, Material = material or "SmoothPlastic", Mesh = mesh, Transparency = transparency })
end

local function darker(c: Color3, k: number): Color3
	return c:Lerp(rgb(0, 0, 0), k)
end

-- Pez: cuerpo de lado plano (elipsoide), cola en cuña, dorsal en cuña y ojos. L = largo.
local function fishParts(L: number, color: Color3, tall: number): { Piece }
	local out = {}
	add(out, V(L * 0.26, L * tall, L * 0.82), CF(0, 0, -L * 0.04), color, "Sphere")
	add(out, V(L * 0.05, L * tall * 0.9, L * 0.3), CF(0, 0, L * 0.43) * ANG(0, math.pi, 0), darker(color, 0.25), "Wedge") -- cola
	add(out, V(L * 0.04, L * tall * 0.35, L * 0.34), CF(0, L * tall * 0.52, 0) * ANG(0, math.pi, 0), darker(color, 0.3), "Wedge") -- dorsal
	add(out, V(L * 0.27, L * 0.06, L * 0.06), CF(0, L * tall * 0.12, -L * 0.3), rgb(20, 20, 24), "Sphere") -- ojos (los dos lados)
	return out
end

MarFauna.Fallback = {
	PezCirujano = function(L, color)
		return fishParts(L, color or rgb(36, 92, 206), 0.62)
	end,
	PezLoro = function(L, color)
		return fishParts(L, color or rgb(40, 170, 140), 0.42)
	end,
	PezAngel = function(L, color)
		return fishParts(L, color or rgb(250, 214, 50), 0.95)
	end,
	PezBanco = function(L, color)
		local out = {}
		local c = color or rgb(170, 190, 210)
		add(out, V(L * 0.18, L * 0.36, L * 0.86), CF(0, 0, -L * 0.04), c, "Sphere")
		add(out, V(L * 0.04, L * 0.34, L * 0.24), CF(0, 0, L * 0.44) * ANG(0, math.pi, 0), darker(c, 0.25), "Wedge")
		return out
	end,
	Medusa = function(L, color)
		local out = {}
		local c = color or rgb(240, 160, 220)
		add(out, V(L, L * 0.6, L), CF(0, L * 0.3, 0), c, "Sphere", "Glass", 0.35) -- campana
		add(out, V(L * 0.9, L * 0.12, L * 0.9), CF(0, L * 0.05, 0), c:Lerp(rgb(255, 255, 255), 0.3), "Sphere", "Glass", 0.4) -- faldón
		-- tentáculos: CINTAS planas onduladas (dos por pieza en cruz), no tubos lisos
		for k = 0, 1 do
			add(out, V(L * 0.5, L * 1.1, L * 0.03), CF(0, -L * 0.5, 0) * ANG(0, k * math.pi / 2, 0.08), c:Lerp(rgb(255, 255, 255), 0.4), nil, "Glass", 0.5)
		end
		return out
	end,
	Manta = function(L, color)
		local out = {}
		local c = color or rgb(30, 38, 52)
		add(out, V(L * 0.3, L * 0.1, L * 0.6), CF(0, 0, 0), c, "Sphere")
		add(out, V(L * 0.48, L * 0.04, L * 0.42), CF(-L * 0.3, 0, L * 0.02) * ANG(0, -math.pi / 2, 0), c, "Wedge")
		add(out, V(L * 0.48, L * 0.04, L * 0.42), CF(L * 0.3, 0, L * 0.02) * ANG(0, math.pi / 2, 0), c, "Wedge")
		add(out, V(L * 0.03, L * 0.02, L * 0.5), CF(0, 0, L * 0.5), darker(c, 0.2))
		return out
	end,
	Delfin = function(L, color)
		local out = {}
		local c = color or rgb(110, 124, 140)
		add(out, V(L * 0.2, L * 0.22, L * 0.8), CF(0, 0, 0), c, "Sphere")
		add(out, V(L * 0.05, L * 0.16, L * 0.16), CF(0, L * 0.14, L * 0.02) * ANG(0, math.pi, 0), darker(c, 0.2), "Wedge") -- dorsal
		add(out, V(L * 0.36, L * 0.03, L * 0.1), CF(0, 0, L * 0.44), darker(c, 0.15)) -- cola
		return out
	end,
	Tiburon = function(L, color)
		local out = {}
		local c = color or rgb(124, 118, 102)
		add(out, V(L * 0.17, L * 0.18, L * 0.82), CF(0, 0, 0), c, "Sphere")
		add(out, V(L * 0.04, L * 0.2, L * 0.18), CF(0, L * 0.16, 0) * ANG(0, math.pi, 0), darker(c, 0.3), "Wedge") -- dorsal
		add(out, V(L * 0.04, L * 0.22, L * 0.16), CF(0, L * 0.04, L * 0.46) * ANG(0, math.pi, 0), darker(c, 0.3), "Wedge") -- cola
		return out
	end,
	MorenaAsomada = function(L, color)
		local out = {}
		local c = color or rgb(190, 172, 70)
		add(out, V(L * 0.6, L * 0.25, L * 0.6), CF(0, 0, L * 0.35), rgb(104, 98, 86), "Sphere") -- la roca
		add(out, V(L * 0.24, L * 0.36, L * 0.6), CF(0, L * 0.05, -L * 0.1), c, "Sphere")
		add(out, V(L * 0.04, L * 0.12, L * 0.4), CF(0, L * 0.22, 0) * ANG(0, math.pi, 0), darker(c, 0.3), "Wedge") -- cresta
		return out
	end,
	Tortuga = function(L, color)
		local out = {}
		local c = color or rgb(96, 110, 60)
		add(out, V(L * 0.8, L * 0.32, L * 0.9), CF(0, 0, 0), c, "Sphere")
		add(out, V(L * 0.22, L * 0.2, L * 0.26), CF(0, 0, -L * 0.55), rgb(150, 145, 105), "Sphere")
		for sx = -1, 1, 2 do
			-- (aletas delanteras en cuña: planas y en punta, como las de una tortuga)
			add(out, V(L * 0.05, L * 0.2, L * 0.5), CF(sx * L * 0.48, -L * 0.04, -L * 0.22) * ANG(0, sx * (math.pi / 2 + 0.4), math.pi / 2), rgb(130, 140, 100), "Wedge")
			add(out, V(L * 0.26, L * 0.05, L * 0.14), CF(sx * L * 0.3, -L * 0.04, L * 0.36) * ANG(0, -sx * 0.3, 0), rgb(130, 140, 100), "Sphere")
		end
		return out
	end,
}

-- Respaldo de un animal (piezas respecto a su centro; la cabeza hacia −Z)
function MarFauna.fallback(name: string, length: number, color: Color3?): { Piece }
	local make = MarFauna.Fallback[name]
	return if make then make(length, color) else {}
end

return MarFauna
