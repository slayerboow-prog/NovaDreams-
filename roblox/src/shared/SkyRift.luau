-- SkyRift: la Grieta del cielo (Saga de la Grieta). Cuentas puras: se prueban fuera de Roblox
-- (scripts/test-skyrift.luau). La dibuja el cliente (Controllers/SkyRift) con Beams y pocas partículas.
--
--   * Forma: una raja principal dentada que cruza el cielo en diagonal (como una fisura en un cristal)
--     y de 6 a 14 ramas laterales más finas que salen de puntos de la principal y se estrechan hasta
--     acabar en punta. Ruido determinista con semilla fija: todos los jugadores ven la misma grieta.
--   * Capas (de dentro afuera): núcleo blanco-amarillo incandescente muy fino, fuego naranja/ámbar más
--     ancho (como metal fundido) y un halo verde-cian muy ancho y transparente, tipo nebulosa (el verde
--     es el color de Cosme y de la Grieta en la historia: el halo lo conserva). Puntos brillantes en las
--     uniones y chispas/escombros que salen despacio.
--   * Fases de la saga (phaseFor): cuánto está abierta (Open 0..1: crece desde el centro hacia los
--     extremos y le van saliendo las ramas) y cuánto brilla (Intensity 0..1).
--   * Nivel gráfico Bajo: solo núcleo y fuego, sin halo ni partículas.
--
-- Coordenadas de la forma: un plano 2D en "unidades" (la principal va de X≈-1 a X≈1, ya girada en
-- diagonal). El cliente multiplica por la escala de la colocación (Placement) para pasar a studs.

local SkyRift = {}

export type Point = { X: number, Y: number }
export type Path = {
	Points: { Point },
	Widths: { number }, -- ancho (de la capa de fuego) en cada punto, en unidades
	T: number, -- dónde nace en la principal (0..1; la principal: 0)
	Main: boolean,
}
export type Joint = { Point: Point, T: number, Weight: number }
export type Shape = { Main: Path, Branches: { Path }, Joints: { Joint } }
export type Segment = {
	Path: number, -- 0 = la principal; 1.. = ramas
	Index: number,
	A: Point,
	B: Point,
	W0: number,
	W1: number,
	Visible: boolean,
}

SkyRift.Seed = 4207 -- semilla fija: la grieta es siempre la misma
SkyRift.MainPoints = 21 -- puntos de la línea principal (20 tramos)
SkyRift.Tilt = math.rad(30) -- la diagonal: sube hacia la derecha
SkyRift.MainWidth = 0.022 -- ancho máximo del fuego en la principal (unidades)
SkyRift.MinBranches = 6
SkyRift.MaxBranches = 14
SkyRift.MaxJoints = 8 -- puntos brillantes como mucho

-- Capas: color (RGB 0-255), cuánto más ancha que el fuego, transparencia base, emisión y brillo.
-- (El resplandor del juego —Bloom— hace el resto: el núcleo pasa con creces su umbral.)
SkyRift.Layers = {
	Core = { Color = { 255, 250, 228 }, Color2 = { 255, 236, 170 }, WidthMul = 0.3, Transparency = 0, LightEmission = 1, Brightness = 7 },
	Fire = { Color = { 255, 138, 34 }, Color2 = { 255, 186, 64 }, WidthMul = 1, Transparency = 0.08, LightEmission = 1, Brightness = 3.2 },
	Halo = { Color = { 70, 200, 255 }, Color2 = { 86, 246, 196 }, WidthMul = 6, Pad = 0.05, Transparency = 0.5, LightEmission = 1, Brightness = 1.4 },
}
SkyRift.LayerOrder = { "Halo", "Fire", "Core" }
-- Textura del halo (de Roblox, viene con el juego): bordes suaves, parece nebulosa
SkyRift.HaloTexture = "rbxasset://textures/particles/smoke_main.dds"
SkyRift.SparkTexture = "rbxasset://textures/particles/sparkles_main.dds"
SkyRift.HaloEvery = 3 -- el halo de la principal va en tramos largos (uno cada 3 de la principal)

-- Fases de la saga. Mode "Sky": en el cielo de Valmar (sigue a la cámara, muy lejos);
-- "Dream": sobre la isla del sueño del prólogo (fija en el mundo, como la de antes).
export type Phase = { Open: number, Intensity: number, Sparks: number, Mode: string }
SkyRift.Phases = {
	Ninguna = { Open = 0, Intensity = 0, Sparks = 0, Mode = "Sky" },
	Sueno = { Open = 0.6, Intensity = 0.9, Sparks = 0.6, Mode = "Dream" }, -- prólogo (el sueño)
	Rasguno = { Open = 0.28, Intensity = 0.5, Sparks = 0.3, Mode = "Sky" }, -- «un rasguño en el aire» (tras conocer a Cosme)
	Crece = { Open = 0.55, Intensity = 0.8, Sparks = 1, Mode = "Sky" }, -- La grieta en el cielo: ha crecido y caen cosas
	Grande = { Open = 0.8, Intensity = 0.9, Sparks = 1.2, Mode = "Sky" }, -- la noche de las cosas perdidas
	Abierta = { Open = 1, Intensity = 1, Sparks = 1.4, Mode = "Sky" }, -- Coser el cielo (antes de coserla)
	Cosida = { Open = 0.12, Intensity = 0.16, Sparks = 0, Mode = "Sky" }, -- una cicatriz finísima
	Hilachas = { Open = 0.3, Intensity = 0.45, Sparks = 0.4, Mode = "Sky" }, -- Acto II: las costuras se sueltan
	Rota = { Open = 0.75, Intensity = 0.9, Sparks = 1.2, Mode = "Sky" }, -- Acto III: la costura se rompió
	Inminente = { Open = 0.9, Intensity = 0.95, Sparks = 1.4, Mode = "Sky" }, -- Acto IV: llega la Gran Fusión
	Fusion = { Open = 1, Intensity = 1, Sparks = 2, Mode = "Sky" }, -- la batalla final
	Ultima = { Open = 0.5, Intensity = 0.6, Sparks = 0.6, Mode = "Sky" }, -- la última costura
	Cerrada = { Open = 0, Intensity = 0, Sparks = 0, Mode = "Sky" }, -- cerrada para siempre
} :: { [string]: Phase }

-- Dónde se dibuja. Sky: dirección desde la cámara (hacia Los Pinos, al norte, a media altura),
-- distancia y escala (studs por unidad). Dream: encima de la isla del sueño (World/Kit/DreamIsland:
-- origen -3400, 700, -3400 y 164 de largo), fija.
SkyRift.Placement = {
	Sky = { Direction = { 0.25, 0.78, -1 }, Distance = 450, Scale = 400 },
	Dream = { Center = { -3400 + 82, 700 + 80, -3400 - 6 }, Yaw = math.rad(12), Pitch = math.rad(-72), Scale = 115 },
}

-- Velocidad a la que se abre o se cierra (Open por segundo)
SkyRift.OpenRate = 0.12
SkyRift.CloseRate = 0.2

local PROLOGUE = "Prologo_Sueno" -- (StoryContext.PrologueId)

---------------------------------------------------------------------
-- Ruido determinista (no usa Random: igual en Roblox y en las pruebas)
---------------------------------------------------------------------
local function rng(seed: number): () -> number
	local s = seed % 2147483647
	if s <= 0 then
		s += 2147483646
	end
	return function(): number
		s = (s * 48271) % 2147483647
		return s / 2147483647
	end
end

local function between(r: () -> number, a: number, b: number): number
	return a + (b - a) * r()
end

local function rotate(p: Point, angle: number): Point
	local c, s = math.cos(angle), math.sin(angle)
	return { X = p.X * c - p.Y * s, Y = p.X * s + p.Y * c }
end

local function lerp(a: Point, b: Point, k: number): Point
	return { X = a.X + (b.X - a.X) * k, Y = a.Y + (b.Y - a.Y) * k }
end

local function dist(a: Point, b: Point): number
	return math.sqrt((a.X - b.X) ^ 2 + (a.Y - b.Y) ^ 2)
end

---------------------------------------------------------------------
-- La forma
---------------------------------------------------------------------
function SkyRift.shape(seed: number?): Shape
	local r = rng(seed or SkyRift.Seed)
	local n = SkyRift.MainPoints
	local step = 2 / (n - 1)

	-- Línea principal: una curva suave (arco) + zigzag dentado que alterna de lado
	local raw: { Point } = {}
	local widths: { number } = {}
	local bow = between(r, 0.06, 0.12)
	local phase = between(r, 0, math.pi)
	local side = 1
	for i = 0, n - 1 do
		local t = i / (n - 1)
		local inner = i > 0 and i < n - 1
		local u = -1 + 2 * t + (if inner then between(r, -0.3, 0.3) * step else 0)
		-- Zigzag: casi siempre cambia de lado, pero no siempre (si no, parece un dibujo)
		if r() < 0.72 then
			side = -side
		end
		local jag = if inner then side * between(r, 0.006, 0.034) + between(r, -0.012, 0.012) else 0
		local v = bow * math.sin(t * math.pi * 1.2 + phase) + jag
		table.insert(raw, { X = u, Y = v })
		-- Más ancha en el centro, fina en las puntas, y algo irregular
		local body = math.sin(math.pi * t) ^ 0.7
		table.insert(widths, SkyRift.MainWidth * (0.12 + 0.88 * body) * (if inner then between(r, 0.75, 1.2) else 1))
	end

	local main: Path = { Points = {}, Widths = widths, T = 0, Main = true }
	for _, p in raw do
		table.insert(main.Points, rotate(p, SkyRift.Tilt))
	end

	-- Ramas: de puntos interiores de la principal, a un lado u otro, abiertas 25-65 grados
	-- (de 9 a 13 según la semilla: dentro del margen de 6 a 14, tirando a ramificada)
	local count = SkyRift.MinBranches + 3 + math.floor(r() * (SkyRift.MaxBranches - SkyRift.MinBranches - 3))
	count = math.clamp(count, SkyRift.MinBranches, SkyRift.MaxBranches)
	local branches: { Path } = {}
	local fromCount: { [number]: number } = {}
	for b = 1, count do
		-- Repartidas a lo largo de la principal (sin las dos primeras ni las dos últimas)
		local slot = (b - 0.5) / count
		local idx = math.clamp(math.floor(3 + slot * (n - 5) + between(r, -0.8, 0.8) + 0.5), 3, n - 2)
		fromCount[idx] = (fromCount[idx] or 0) + 1
		local t = (idx - 1) / (n - 1)
		local prev, nxt = raw[idx - 1], raw[idx + 1]
		local dx, dy = nxt.X - prev.X, nxt.Y - prev.Y
		local len = math.sqrt(dx * dx + dy * dy)
		dx, dy = dx / len, dy / len
		if r() < 0.35 then
			dx, dy = -dx, -dy -- algunas ramas van "hacia atrás"
		end
		local side = if (b + fromCount[idx]) % 2 == 0 then 1 else -1
		local angle = side * math.rad(between(r, 25, 65))
		local dir = rotate({ X = dx, Y = dy }, angle)
		local total = between(r, 0.16, 0.42) * (0.45 + 0.55 * math.sin(math.pi * t))
		local pts = 3 + math.floor(r() * 3) -- 3 a 5 puntos
		local here = raw[idx]
		local points = { here }
		local w0 = widths[idx] * between(r, 0.5, 0.7)
		local bw = { w0 }
		for k = 2, pts do
			dir = rotate(dir, math.rad(between(r, -24, 24)))
			here = { X = here.X + dir.X * total / (pts - 1), Y = here.Y + dir.Y * total / (pts - 1) }
			table.insert(points, here)
			-- Se estrecha hasta la punta
			local f = (k - 1) / (pts - 1)
			table.insert(bw, w0 * (1 - 0.9 * f))
		end
		local path: Path = { Points = {}, Widths = bw, T = t, Main = false }
		for _, p in points do
			table.insert(path.Points, rotate(p, SkyRift.Tilt))
		end
		table.insert(branches, path)
	end

	-- Uniones: donde nacen ramas (más brillantes cuantas más ramas) y el punto más ancho del centro
	local joints: { Joint } = {}
	for idx, k in fromCount do
		table.insert(joints, { Point = main.Points[idx], T = (idx - 1) / (n - 1), Weight = 1 + k })
	end
	local widest = 2
	for i = 2, n - 1 do
		if widths[i] > widths[widest] then
			widest = i
		end
	end
	if not fromCount[widest] then
		table.insert(joints, { Point = main.Points[widest], T = (widest - 1) / (n - 1), Weight = 2 })
	end
	table.sort(joints, function(a, b)
		if a.Weight ~= b.Weight then
			return a.Weight > b.Weight
		end
		return a.T < b.T
	end)
	while #joints > SkyRift.MaxJoints do
		table.remove(joints)
	end

	return { Main = main, Branches = branches, Joints = joints }
end

---------------------------------------------------------------------
-- Abrirse: qué se ve con Open (0..1)
---------------------------------------------------------------------
-- La principal se abre desde el centro hacia las puntas; a cada rama le llega su turno cuando la
-- principal ya ha pasado por su nacimiento, y crece desde ahí. Todo engorda un poco al abrirse.
local function widthScale(open: number): number
	return 0.35 + 0.65 * open
end
SkyRift.widthScale = widthScale

-- Hasta dónde llega una rama (0..1 de su largo) con esta apertura
function SkyRift.branchGrowth(t: number, open: number): number
	local need = math.abs(t - 0.5) * 2 -- lo que tiene que abrirse la principal para llegar aquí
	return math.clamp((open - need) / 0.3, 0, 1)
end

-- Los tramos de un camino recortados hasta la fracción visible [lo, hi] de su largo (por puntos)
local function clipPath(path: Path, pathIndex: number, lo: number, hi: number, wScale: number, out: { Segment })
	local pts = path.Points
	local n = #pts
	for i = 1, n - 1 do
		local a, b = (i - 1) / (n - 1), i / (n - 1)
		local seg: Segment = {
			Path = pathIndex,
			Index = i,
			A = pts[i],
			B = pts[i + 1],
			W0 = path.Widths[i] * wScale,
			W1 = path.Widths[i + 1] * wScale,
			Visible = false,
		}
		if hi > lo and b > lo and a < hi then
			seg.Visible = true
			local ka = math.clamp((lo - a) / (b - a), 0, 1)
			local kb = math.clamp((hi - a) / (b - a), 0, 1)
			if ka > 0 then
				seg.A = lerp(pts[i], pts[i + 1], ka)
				seg.W0 = (path.Widths[i] + (path.Widths[i + 1] - path.Widths[i]) * ka) * wScale
			end
			if kb < 1 then
				seg.B = lerp(pts[i], pts[i + 1], kb)
				-- La punta que avanza, afilada
				seg.W1 = (path.Widths[i] + (path.Widths[i + 1] - path.Widths[i]) * kb) * wScale * 0.35
			end
			if dist(seg.A, seg.B) < 1e-4 then
				seg.Visible = false
			end
		end
		table.insert(out, seg)
	end
end

-- Todos los tramos (siempre los mismos, en el mismo orden: el cliente crea uno por cada uno y aquí
-- dice si se ve, dónde empieza y acaba y qué ancho tiene)
function SkyRift.reveal(shape: Shape, open: number): { Segment }
	open = math.clamp(open, 0, 1)
	local out: { Segment } = {}
	local wScale = widthScale(open)
	clipPath(shape.Main, 0, 0.5 - open / 2, 0.5 + open / 2, wScale, out)
	for b, path in shape.Branches do
		clipPath(path, b, 0, SkyRift.branchGrowth(path.T, open), wScale, out)
	end
	return out
end

-- El halo: tramos largos sobre la principal (uno cada HaloEvery) y uno por rama, muy anchos.
-- Mismo formato que reveal (Path 0 = principal, Path b = rama b).
function SkyRift.halo(shape: Shape, open: number): { Segment }
	open = math.clamp(open, 0, 1)
	local out: { Segment } = {}
	local spec = SkyRift.Layers.Halo
	local wScale = widthScale(open)
	local main = shape.Main
	local n = #main.Points
	local every = SkyRift.HaloEvery
	local lo, hi = 0.5 - open / 2, 0.5 + open / 2
	local index = 0
	local i = 1
	while i < n do
		local j = math.min(i + every, n)
		index += 1
		local a, b = (i - 1) / (n - 1), (j - 1) / (n - 1)
		local w = 0
		for k = i, j do
			w = math.max(w, main.Widths[k])
		end
		local width = (w * spec.WidthMul + spec.Pad) * wScale
		local seg: Segment = { Path = 0, Index = index, A = main.Points[i], B = main.Points[j], W0 = width, W1 = width, Visible = false }
		if hi > lo and b > lo and a < hi then
			seg.Visible = true
			local ka = math.clamp((lo - a) / (b - a), 0, 1)
			local kb = math.clamp((hi - a) / (b - a), 0, 1)
			seg.A = lerp(main.Points[i], main.Points[j], ka)
			seg.B = lerp(main.Points[i], main.Points[j], kb)
			if dist(seg.A, seg.B) < 1e-4 then
				seg.Visible = false
			end
		end
		table.insert(out, seg)
		i = j
	end
	for bi, path in shape.Branches do
		local g = SkyRift.branchGrowth(path.T, open)
		local first, last = path.Points[1], path.Points[#path.Points]
		local width = (path.Widths[1] * spec.WidthMul * 0.8 + spec.Pad * 0.5) * wScale
		table.insert(out, {
			Path = bi,
			Index = 1,
			A = first,
			B = lerp(first, last, g),
			W0 = width,
			W1 = width * 0.4,
			Visible = g > 0.02,
		})
	end
	return out
end

---------------------------------------------------------------------
-- Fases de la saga
---------------------------------------------------------------------
local function any(map: { [string]: any }, ids: { string }): boolean
	for _, id in ids do
		if map[id] then
			return true
		end
	end
	return false
end

export type StoryLike = { Active: { [string]: any }?, Completed: { [string]: any }?, Flags: { [string]: any }? }

-- Qué fase toca según la historia del jugador (lo publica el servidor en el atributo SkyRift)
function SkyRift.phaseFor(story: StoryLike): string
	local A = story.Active or {}
	local C = story.Completed or {}
	local F = story.Flags or {}
	if A[PROLOGUE] then
		return "Sueno"
	end
	if C.Saga_24_Final or F.SagaCompleta then
		return "Cerrada"
	end
	if A.Saga_24_Final or C.Saga_23_Fusion then
		return "Ultima"
	end
	if A.Saga_23_Fusion then
		return "Fusion"
	end
	if C.Saga_18_Precio or any(A, { "Saga_19_Recuerdos", "Saga_20_Aliados", "Saga_21_Consorcio", "Saga_22_Ancla" }) then
		return "Inminente"
	end
	if C.Saga_12_Graduacion then
		return "Rota"
	end
	if C.Saga_06_Coser then
		if C.Saga_07_Costuras or any(A, { "Saga_07_Costuras", "Saga_08_MegaVerso", "Saga_09_Archivo", "Saga_10_Fiesta", "Saga_11_Cronos", "Saga_12_Graduacion" }) then
			return "Hilachas"
		end
		return "Cosida"
	end
	if A.Saga_06_Coser then
		return "Abierta"
	end
	if A.Saga_05_Perdidas or C.Saga_05_Perdidas then
		return "Grande"
	end
	if C.Saga_02_Grieta or any(A, { "Saga_02_Grieta", "Saga_03_Pez", "Saga_04_Ventanilla" }) then
		return "Crece"
	end
	if C.Loco_N1_Cosme or F.GrietaVista then
		return "Rasguno"
	end
	return "Ninguna"
end

function SkyRift.phase(name: string?): Phase
	return SkyRift.Phases[name or "Ninguna"] or SkyRift.Phases.Ninguna
end

-- Acercar el valor actual al objetivo (se abre despacio y se cierra algo más deprisa)
function SkyRift.approach(current: number, target: number, dt: number): number
	if target > current then
		return math.min(target, current + SkyRift.OpenRate * dt)
	end
	return math.max(target, current - SkyRift.CloseRate * dt)
end

---------------------------------------------------------------------
-- Aspecto: niveles gráficos, pulso y brillo
---------------------------------------------------------------------
export type TierLook = { Layers: { string }, BranchLayers: { string }, Halo: boolean, Particles: boolean }

-- Bajo: sin halo ni partículas (y las ramas, solo fuego)
function SkyRift.tierLook(tierName: string): TierLook
	if tierName == "Low" then
		return { Layers = { "Fire", "Core" }, BranchLayers = { "Fire" }, Halo = false, Particles = false }
	end
	return { Layers = { "Fire", "Core" }, BranchLayers = { "Fire", "Core" }, Halo = true, Particles = true }
end

-- Cuántas instancias gasta (para el presupuesto del móvil)
function SkyRift.budget(shape: Shape, tierName: string): { Beams: number, Emitters: number }
	local look = SkyRift.tierLook(tierName)
	local mainSegs = #shape.Main.Points - 1
	local branchSegs = 0
	for _, path in shape.Branches do
		branchSegs += #path.Points - 1
	end
	local beams = mainSegs * #look.Layers + branchSegs * #look.BranchLayers
	local emitters = 0
	if look.Halo then
		beams += #SkyRift.halo(shape, 1)
	end
	if look.Particles then
		emitters = #shape.Joints + #SkyRift.SparkSpots
	end
	return { Beams = beams, Emitters = emitters }
end

-- Dónde salen chispas y escombros (t a lo largo de la principal)
SkyRift.SparkSpots = { 0.32, 0.5, 0.68 }

-- Pulso: un latido lento y un parpadeo rápido muy leve; cada tramo (k) un poco desfasado
function SkyRift.pulse(time: number, k: number): number
	local slow = math.sin(time * 1.7 + k * 0.55)
	local flicker = math.sin(time * 11.3 + k * 2.9) * math.sin(time * 6.1 + k * 1.3)
	return 0.86 + 0.1 * slow + 0.06 * flicker
end

-- Cuánto se ve según la hora: de noche, del todo; a pleno día, bastante menos
function SkyRift.skyFactor(clockTime: number): number
	local h = clockTime % 24
	-- 1 de 20:00 a 5:00; 0.55 de 8:00 a 17:00; suave entre medias
	local dayness
	if h >= 8 and h <= 17 then
		dayness = 1
	elseif h > 5 and h < 8 then
		dayness = (h - 5) / 3
	elseif h > 17 and h < 20 then
		dayness = (20 - h) / 3
	else
		dayness = 0
	end
	return 1 - 0.45 * dayness
end

-- Transparencia y brillo de una capa con esta intensidad (0 = no se ve), pulso y hora
function SkyRift.layerLook(layer: string, intensity: number, pulse: number, sky: number): (number, number)
	local spec = SkyRift.Layers[layer]
	local vis = math.clamp(intensity * sky, 0, 1)
	if vis <= 0.001 then
		return 1, 0
	end
	local transparency = 1 - (1 - spec.Transparency) * vis * (if layer == "Halo" then (0.85 + 0.15 * pulse) else 1)
	local brightness = spec.Brightness * pulse * (0.5 + 0.5 * vis)
	return math.clamp(transparency, 0, 1), brightness
end

return SkyRift
