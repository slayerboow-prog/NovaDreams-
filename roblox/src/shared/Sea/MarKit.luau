-- MarKit: el kit de piezas del mar (encargo v2 del dueño; docs/mar/diseno-v2.md §Biblioteca).
--
-- Cada pieza tiene una MALLA hecha en Blender (scripts/map/mar_kit_blender.py: assets/mar/<Nombre>.fbx con
-- su textura de color y de normales de 512 px) que sube scripts/upload-mar.sh (shared/Sea/MarAssetIds) y
-- carga World/MarMeshes en ReplicatedStorage.MarMallas. Mientras no estén subidas (o si fallan), cada
-- pieza tiene un RESPALDO de piezas de Roblox (MarKit.fallback): formas pensadas para que se lea qué es
-- (ramas que se bifurcan, el plato del coral mesa, la red del abanico, los tubos huecos de la esponja,
-- el tallo del kelp con sus hojas…), nunca un bloque ni una bola de plastilina sola.
--
--   MarKit.Pieces[Nombre] = { Size = {ancho, alto, fondo} (studs con escala 1, la malla de Blender mide
--       esto), Fill (cuánto de su caja ocupa: la revisión con rayos), Sway (se mece), Glow (brilla),
--       Group (Coral | Roca | Planta | Luz | Vida | Ruina), Tri (triángulos de la malla, LOD0),
--       Tint (la malla va con el color de la paleta de la zona y su material, sin textura: los corales y
--       las plantas cambian de color según la profundidad; las rocas y ruinas llevan su textura) }
--   MarKit.fallback(nombre, alto, color, semilla) -> { Piece }  (en el sitio de la pieza: el pie en 0,0,0)
--   MarKit.PieceCap = { Mobile, Desktop }   tope de piezas de respaldo en la zona (el móvil, menos)
--
-- Piece = { Size: Vector3, CFrame: CFrame, Color: Color3, Material: string, Shape: string?, Mesh: string?,
--           Transparency: number?, Glow: boolean? } (como shared/Sea/ShoreDecor)

local MarKit = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local sin, cos, floor, pi, abs = math.sin, math.cos, math.floor, math.pi, math.abs

MarKit.Pieces = {
	-- Corales (7)
	CoralCuerno = { Size = { 4.0, 2.6, 4.8 }, Fill = 0.65, Group = "Coral", Tint = true, Tri = 1800, Label = "coral cuerno de ciervo (ramas)" },
	CoralCerebro = { Size = { 3.1, 2.0, 2.9 }, Fill = 0.9, Group = "Coral", Tint = true, Tri = 2400, Label = "coral cerebro (con surcos)" },
	CoralMesa = { Size = { 4.3, 2.0, 4.3 }, Fill = 0.55, Group = "Coral", Tint = true, Tri = 900, Label = "coral mesa" },
	Abanico = { Size = { 4.8, 4.4, 0.6 }, Fill = 0.5, Sway = true, Group = "Coral", Tint = true, Tri = 1200, Label = "gorgonia (abanico de red)" },
	Esponjas = { Size = { 3.0, 3.4, 3.0 }, Fill = 0.6, Group = "Coral", Tint = true, Tri = 1300, Label = "esponjas de tubo" },
	CoralBlando = { Size = { 3.1, 2.8, 4.6 }, Fill = 0.6, Sway = true, Group = "Coral", Tint = true, Tri = 1500, Label = "coral blando" },
	CoralPilar = { Size = { 2.4, 5.0, 2.7 }, Fill = 0.5, Group = "Coral", Tint = true, Tri = 1000, Label = "coral pilar" },
	-- Rocas (4)
	RocaPorosa = { Size = { 3.9, 2.6, 3.2 }, Fill = 0.9, Group = "Roca", Tri = 2000, Label = "roca de arrecife porosa (con agujeros)" },
	Canto = { Size = { 2.9, 2.4, 2.7 }, Fill = 0.9, Group = "Roca", Tri = 900, Label = "canto rodado" },
	RocaLaja = { Size = { 5.9, 1.6, 4.0 }, Fill = 0.9, Group = "Roca", Tri = 900, Label = "laja (roca plana)" },
	RocaAguja = { Size = { 2.1, 7.0, 2.4 }, Fill = 0.7, Group = "Roca", Tri = 900, Label = "aguja de roca" },
	-- Plantas (3)
	KelpGigante = { Size = { 14.3, 30.0, 12.4 }, Fill = 0.25, Sway = true, Group = "Planta", Tint = true, Tri = 1600, Label = "kelp gigante (tallo con hojas)" },
	Pradera = { Size = { 1.9, 2.6, 2.3 }, Fill = 0.5, Sway = true, Group = "Planta", Tint = true, Tri = 700, Label = "pradera (hojas curvas de dos caras)" },
	AlgaAncha = { Size = { 3.6, 4.0, 2.9 }, Fill = 0.5, Sway = true, Group = "Planta", Tint = true, Tri = 800, Label = "alga de hoja ancha" },
	-- Luz (2): bioluminiscencia (emisivo; las luces de verdad son pocas: ReefZone.Lights)
	SetaLuz = { Size = { 2.4, 2.4, 2.4 }, Fill = 0.6, Glow = true, Group = "Luz", Tint = true, Tri = 700, Label = "seta de luz" },
	AnemonaLuz = { Size = { 1.2, 1.6, 1.1 }, Fill = 0.6, Glow = true, Sway = true, Group = "Luz", Tint = true, Tri = 900, Label = "anémona que brilla" },
	-- Vida pequeña (4)
	Estrella = { Size = { 1.9, 0.25, 2.1 }, Fill = 0.6, Group = "Vida", Tri = 300, Label = "estrella de mar" },
	Concha = { Size = { 1.4, 0.5, 1.2 }, Fill = 0.8, Group = "Vida", Tri = 300, Label = "concha" },
	Erizo = { Size = { 1.2, 0.7, 1.1 }, Fill = 0.8, Group = "Vida", Tri = 500, Label = "erizo" },
	Cangrejo = { Size = { 2.0, 0.8, 1.3 }, Fill = 0.6, Group = "Vida", Tri = 800, Label = "cangrejo" },
	-- Ruinas y obras (3)
	Pilote = { Size = { 1.8, 12.0, 1.8 }, Fill = 1, Group = "Ruina", Tri = 600, Label = "pilote redondo con percebes y algas" },
	Piramide = { Size = { 26.5, 30.0, 26.5 }, Fill = 1, Glow = true, Group = "Ruina", Tri = 1200, Label = "pirámide hundida (con vetas que brillan)" },
	ColumnaRuina = { Size = { 4.2, 10.0, 4.2 }, Fill = 0.8, Group = "Ruina", Tri = 600, Label = "columna rota con relieves" },
}

-- Tope de piezas de respaldo en la zona (con mallas, una por pieza del kit)
MarKit.PieceCap = { Mobile = 2400, Desktop = 3600 } -- (dentro del cañón SeaBiome no planta nada: su tope queda libre)

---------------------------------------------------------------------
-- Respaldo de piezas
---------------------------------------------------------------------
type Piece = { Size: Vector3, CFrame: CFrame, Color: Color3, Material: string, Shape: string?, Mesh: string?, Transparency: number?, Glow: boolean? }

local function hash(a: number, b: number, c: number): number
	local n = sin(a * 12.9898 + b * 78.233 + c * 37.719) * 43758.5453
	return n - floor(n)
end

local function add(out: { Piece }, size: Vector3, cf: CFrame, color: Color3, material: string?, shape: string?, mesh: string?, glow: boolean?, transparency: number?)
	table.insert(out, { Size = size, CFrame = cf, Color = color, Material = material or "SmoothPlastic", Shape = shape, Mesh = mesh, Glow = glow, Transparency = transparency })
end
-- elipsoide (bloque con SpecialMesh de esfera)
local function egg(out, size, cf, color, material, glow)
	add(out, size, cf, color, material, nil, "Sphere", glow)
end
-- cilindro a lo largo de su Y (Shape Cylinder va en X: se gira)
local function rod(out, length, d, cf, color, material, glow)
	add(out, V(length, d, d), cf * ANG(0, 0, pi / 2), color, material, "Cylinder", nil, glow)
end
-- una rama de base a punta (cilindro entre dos puntos)
local function limb(out, a: Vector3, b: Vector3, d: number, color: Color3, material: string?, glow: boolean?)
	local mid = (a + b) / 2
	local len = (b - a).Magnitude
	if len < 1e-3 then
		return
	end
	local cf = CFrame.lookAt(mid, b) * ANG(pi / 2, 0, 0) -- el eje Y del cilindro de a a b
	rod(out, len, d, cf, color, material, glow)
end

local function shade(c: Color3, k: number): Color3
	return c:Lerp(rgb(20, 24, 40), k)
end
local function light(c: Color3, k: number): Color3
	return c:Lerp(rgb(255, 250, 240), k)
end

local R = {}

-- Coral cuerno de ciervo: tronco corto que se bifurca dos veces; puntas más claras
function R.CoralCuerno(h: number, c: Color3, s: number): { Piece }
	local out = {}
	local branches = 3
	for i = 1, branches do
		local a = (i / branches) * pi * 2 + hash(s, i, 1) * 0.8
		local tilt = 0.35 + hash(i, s, 2) * 0.35
		local base = V(cos(a) * 0.15 * h, 0, sin(a) * 0.15 * h)
		local mid = base + V(cos(a) * sin(tilt) * 0.45 * h, cos(tilt) * 0.5 * h, sin(a) * sin(tilt) * 0.45 * h)
		limb(out, base, mid, 0.16 * h, c, "SmoothPlastic")
		for k = -1, 1, 2 do
			local b = a + k * (0.45 + hash(i, k, 3) * 0.3)
			local tip = mid + V(cos(b) * 0.3 * h, (0.38 + hash(k, i, 4) * 0.2) * h, sin(b) * 0.3 * h)
			limb(out, mid, tip, 0.12 * h, if k > 0 then light(c, 0.3) else c, "SmoothPlastic")
		end
	end
	return out
end

-- Coral cerebro: cúpula aplastada con surcos (anillos más oscuros) y una base
function R.CoralCerebro(h: number, c: Color3, s: number): { Piece }
	local out = {}
	local w = h * 1.7
	egg(out, V(w, h * 1.1, w * 0.92), CF(0, h * 0.45, 0) * ANG(0, s, 0), c, "Salt")
	-- surcos: anillos finos a distintas alturas (se leen como las vetas del cerebro)
	for k = 1, 3 do
		local y = h * (0.35 + k * 0.17)
		local rr = w * 0.5 * math.sqrt(math.max(0.05, 1 - ((y - h * 0.45) / (h * 0.55)) ^ 2))
		add(out, V(0.12 * h, rr * 2.02, rr * 1.9), CF(0, y, 0) * ANG(0, s + k * 0.7, pi / 2), shade(c, 0.35), "SmoothPlastic", "Cylinder")
	end
	egg(out, V(w * 1.05, h * 0.3, w), CF(0, h * 0.08, 0), shade(c, 0.45), "Salt")
	return out
end

-- Coral mesa: pie, plato ancho y borde
function R.CoralMesa(h: number, c: Color3, s: number): { Piece }
	local out = {}
	local w = h * 2.5
	rod(out, h * 0.7, h * 0.35, CF(0, h * 0.35, 0), shade(c, 0.3), "Salt")
	add(out, V(h * 0.22, w, w * 0.92), CF(0, h * 0.8, 0) * ANG(0, s, pi / 2), c, "Salt", "Cylinder")
	add(out, V(h * 0.12, w * 1.04, w * 0.96), CF(0, h * 0.93, 0) * ANG(0, s, pi / 2), light(c, 0.3), "SmoothPlastic", "Cylinder")
	for k = 1, 4 do
		local a = s + k * 1.6
		egg(out, V(0.35, 0.25, 0.35) * h, CF(cos(a) * w * 0.3, h * 1.02, sin(a) * w * 0.3), light(c, 0.5))
	end
	return out
end

-- Gorgonia: lámina fina con nervios (la red) y pie
function R.Abanico(h: number, c: Color3, s: number): { Piece }
	local out = {}
	local w = h * 0.9
	egg(out, V(w, h * 0.92, 0.08 * h), CF(0, h * 0.52, 0), c, "SmoothPlastic", false)
	out[#out].Transparency = 0.15
	for k = -1, 1 do
		local a = k * 0.45
		limb(out, V(0, 0.05 * h, 0), V(sin(a) * w * 0.48, h * (0.95 - abs(k) * 0.08), 0), 0.05 * h, shade(c, 0.35), "SmoothPlastic")
	end
	for k = 1, 2 do
		local y = h * (0.3 + k * 0.24)
		add(out, V(w * (0.95 - k * 0.15), 0.04 * h, 0.1 * h), CF(0, y, 0), shade(c, 0.35))
	end
	rod(out, 0.15 * h, 0.12 * h, CF(0, 0.05 * h, 0), shade(c, 0.5))
	return out
end

-- Esponjas de tubo: tubos de distinta altura con la boca oscura (huecos)
function R.Esponjas(h: number, c: Color3, s: number): { Piece }
	local out = {}
	for i = 1, 3 do
		local a = s + i * 2.09
		local hh = h * (0.55 + hash(s, i, 5) * 0.45)
		local d = h * (0.22 + hash(i, s, 6) * 0.1)
		local p = V(cos(a) * h * 0.18, 0, sin(a) * h * 0.18)
		rod(out, hh, d, CF(p + V(0, hh / 2, 0)) * ANG(cos(a) * 0.12, 0, sin(a) * 0.12), c, "Salt")
		add(out, V(0.04 * h, d * 0.7, d * 0.7), CF(p + V(0, hh + 0.01, 0)) * ANG(0, 0, pi / 2), shade(c, 0.75), "SmoothPlastic", "Cylinder")
	end
	return out
end

-- Coral blando: tallos con racimos de pólipos (bolitas) que se mecen
function R.CoralBlando(h: number, c: Color3, s: number): { Piece }
	local out = {}
	for i = 1, 3 do
		local a = s + i * 2.09 + hash(i, s, 7) * 0.5
		local tip = V(cos(a) * 0.32 * h, h * (0.7 + hash(s, i, 8) * 0.3), sin(a) * 0.32 * h)
		limb(out, V(0, 0, 0), tip, 0.14 * h, light(c, 0.25), "SmoothPlastic")
		for k = 1, 2 do
			local off = V(hash(i, k, 9) - 0.5, hash(k, i, 10) * 0.6, hash(i + k, s, 11) - 0.5) * 0.28 * h
			egg(out, V(0.24, 0.2, 0.24) * h, CF(tip + off), c)
		end
	end
	return out
end

-- Coral pilar: varios dedos verticales
function R.CoralPilar(h: number, c: Color3, s: number): { Piece }
	local out = {}
	for i = 1, 4 do
		local a = s + i * 1.57
		local hh = h * (0.55 + hash(i, s, 12) * 0.45)
		local p = V(cos(a) * h * 0.11, 0, sin(a) * h * 0.11) * (if i == 1 then 0 else 1)
		rod(out, hh, h * 0.13, CF(p + V(0, hh / 2, 0)), c, "Salt")
		egg(out, V(0.13, 0.1, 0.13) * h, CF(p + V(0, hh, 0)), light(c, 0.35))
	end
	return out
end

-- Roca porosa: bloque de bolas de roca con agujeros (manchas oscuras hundidas) y algo de musgo
function R.RocaPorosa(h: number, c: Color3, s: number): { Piece }
	local out = {}
	egg(out, V(h * 1.5, h, h * 1.3), CF(0, h * 0.42, 0) * ANG(0, s, 0.1), c, "Rock")
	egg(out, V(h * 0.9, h * 0.75, h * 0.8), CF(h * 0.45, h * 0.3, -h * 0.2) * ANG(0, s, 0), c:Lerp(rgb(150, 145, 135), 0.2), "Rock")
	for k = 1, 2 do
		local a = s + k * 2.6
		egg(out, V(0.24, 0.2, 0.24) * h, CF(cos(a) * h * 0.62, h * (0.45 + hash(k, s, 13) * 0.25), sin(a) * h * 0.55), rgb(30, 34, 40))
	end
	egg(out, V(h * 1.2, h * 0.18, h * 0.9), CF(0, h * 0.86, 0) * ANG(0, s, 0), rgb(84, 132, 84), "SmoothPlastic")
	return out
end

-- Canto rodado: dos bolas de roca
function R.Canto(h: number, c: Color3, s: number): { Piece }
	local out = {}
	egg(out, V(h * 1.25, h, h * 1.15), CF(0, h * 0.42, 0) * ANG(0, s, 0.15), c, "Rock")
	egg(out, V(h * 0.6, h * 0.5, h * 0.55), CF(h * 0.55, h * 0.2, h * 0.3), shade(c, 0.12), "Rock")
	return out
end

function R.RocaLaja(h: number, c: Color3, s: number): { Piece }
	local out = {}
	egg(out, V(h * 3.7, h, h * 2.5), CF(0, h * 0.4, 0) * ANG(0, s, 0.06), c, "Rock")
	return out
end

function R.RocaAguja(h: number, c: Color3, s: number): { Piece }
	local out = {}
	local y, d = 0, h * 0.34
	for k = 1, 4 do
		local hh = h * 0.3
		egg(out, V(d, hh * 1.3, d), CF(hash(k, s, 14) * 0.2 * h, y + hh * 0.55, 0), c, "Rock")
		y += hh * 0.85
		d *= 0.78
	end
	return out
end

-- Kelp gigante: tallo en tramos y hojas largas alternas (las que se mecen las mueve ReefZoneFx)
function R.KelpGigante(h: number, c: Color3, s: number): { Piece }
	local out = {}
	local segs = math.clamp(floor(h / 4), 4, 9)
	local seg = h / segs
	local x, z = 0, 0
	for k = 1, segs do
		local nx, nz = x + sin(s + k * 0.7) * 0.25, z + cos(s + k * 0.9) * 0.25
		limb(out, V(x, (k - 1) * seg, z), V(nx, k * seg, nz), 0.32, shade(c, 0.15), "SmoothPlastic")
		-- dos hojas por tramo: largas, finas y caídas hacia fuera
		do
			local side = if k % 2 == 0 then 1 else -1
			local a = s + k * 2.4 + side * 1.2
			local cf = CF(nx, k * seg - seg * 0.3, nz) * ANG(0, a, 0) * CF(0.9, 0, 0) * ANG(0, 0, -0.5 * side - 0.2)
			egg(out, V(2.4, 0.08, 0.7), cf, c:Lerp(rgb(180, 170, 70), 0.12), "SmoothPlastic")
		end
		-- vejigas (flotadores) en los tramos de arriba
		if k > segs - 2 then
			egg(out, V(0.35, 0.45, 0.35), CF(nx + 0.3, k * seg - 0.2, nz), light(c, 0.25))
		end
		x, z = nx, nz
	end
	egg(out, V(1.4, 0.5, 1.4), CF(0, 0.2, 0), shade(c, 0.4))
	return out
end

-- Pradera: hojas curvas (dos tramos inclinados), de dos caras
function R.Pradera(h: number, c: Color3, s: number): { Piece }
	local out = {}
	for i = 1, 4 do
		local a = s + i * 1.57
		local p = V(cos(a) * 0.35 * h, 0, sin(a) * 0.35 * h)
		local lean = 0.15 + hash(i, s, 15) * 0.3
		local hh = h * (0.6 + hash(s, i, 16) * 0.4)
		local cf = CF(p) * ANG(0, a, 0)
		add(out, V(0.16 * h, hh * 0.55, 0.03), cf * ANG(0, 0, lean) * CF(0, hh * 0.27, 0), c)
		add(out, V(0.12 * h, hh * 0.5, 0.03), cf * ANG(0, 0, lean) * CF(0, hh * 0.54, 0) * ANG(0, 0, lean * 1.2) * CF(0, hh * 0.24, 0), light(c, 0.15))
	end
	return out
end

function R.AlgaAncha(h: number, c: Color3, s: number): { Piece }
	local out = {}
	for i = 1, 5 do
		local a = s + i * 1.26
		local cf = CF(0, 0, 0) * ANG(0, a, 0) * ANG(0, 0, 0.35 + hash(i, s, 17) * 0.25)
		egg(out, V(h * 0.42, h * 0.95, 0.06 * h), cf * CF(0, h * 0.47, 0), if i % 2 == 0 then c else light(c, 0.15))
	end
	return out
end

-- Seta de luz: pie claro y sombrero que brilla (emisivo; de noche y en la cueva se ve)
function R.SetaLuz(h: number, c: Color3, s: number): { Piece }
	local out = {}
	rod(out, h * 0.8, h * 0.18, CF(0, h * 0.4, 0) * ANG(0.1 * sin(s), 0, 0), rgb(220, 230, 235), "SmoothPlastic")
	egg(out, V(h * 0.85, h * 0.38, h * 0.85), CF(0, h * 0.85, 0), c, "Neon", true)
	egg(out, V(h * 0.55, h * 0.15, h * 0.55), CF(0, h * 0.68, 0), c:Lerp(rgb(255, 255, 255), 0.4), "Neon", true)
	return out
end

function R.AnemonaLuz(h: number, c: Color3, s: number): { Piece }
	local out = {}
	egg(out, V(h * 0.7, h * 0.5, h * 0.7), CF(0, h * 0.25, 0), shade(c, 0.4), "SmoothPlastic")
	for i = 1, 8 do
		local a = s + i * pi / 4
		local tip = V(cos(a) * 0.45 * h, h * (0.85 + hash(i, s, 18) * 0.15), sin(a) * 0.45 * h)
		limb(out, V(cos(a) * 0.15 * h, h * 0.45, sin(a) * 0.15 * h), tip, 0.09 * h, c, "Neon", true)
	end
	return out
end

function R.Estrella(h: number, c: Color3, s: number): { Piece }
	local out = {}
	local w = h * 4.8
	for i = 1, 5 do
		local a = s + i * pi * 2 / 5
		egg(out, V(w * 0.5, h, w * 0.16), CF(cos(a) * w * 0.22, h * 0.4, sin(a) * w * 0.22) * ANG(0, -a, 0), c, "Salt")
	end
	egg(out, V(w * 0.25, h * 1.2, w * 0.25), CF(0, h * 0.5, 0), light(c, 0.2), "Salt")
	return out
end

function R.Concha(h: number, c: Color3, s: number): { Piece }
	local out = {}
	egg(out, V(h * 1.8, h, h * 1.6), CF(0, h * 0.4, 0) * ANG(0, s, 0), light(c, 0.55), "Salt")
	for k = -2, 2 do
		add(out, V(h * 0.1, h * 0.9, h * 1.5), CF(k * h * 0.3, h * 0.45, 0) * ANG(0, s, 0), light(c, 0.3))
	end
	return out
end

function R.Erizo(h: number, c: Color3, s: number): { Piece }
	local out = {}
	egg(out, V(h, h * 0.8, h), CF(0, h * 0.4, 0), rgb(40, 30, 60), "SmoothPlastic")
	for i = 1, 8 do
		local a = s + i * pi / 4
		limb(out, V(0, h * 0.45, 0), V(cos(a) * h * 0.9, h * (0.5 + (i % 2) * 0.4), sin(a) * h * 0.9), 0.06 * h, rgb(60, 40, 90))
	end
	return out
end

function R.Cangrejo(h: number, c: Color3, s: number): { Piece }
	local out = {}
	local body = rgb(226, 92, 58)
	egg(out, V(h * 1.4, h * 0.6, h), CF(0, h * 0.5, 0), body, "SmoothPlastic")
	for side = -1, 1, 2 do
		for k = 1, 2 do
			limb(out, V(side * h * 0.5, h * 0.45, (k - 1.5) * h * 0.4), V(side * h * 1.0, 0, (k - 1.5) * h * 0.6), 0.1 * h, shade(body, 0.2))
		end
		limb(out, V(side * h * 0.4, h * 0.55, -h * 0.4), V(side * h * 0.7, h * 0.6, -h * 0.9), 0.14 * h, body)
		egg(out, V(0.35, 0.25, 0.45) * h, CF(side * h * 0.72, h * 0.62, -h * 1.0), light(body, 0.1))
		egg(out, V(0.12, 0.12, 0.12) * h, CF(side * h * 0.18, h * 0.86, -h * 0.4), rgb(20, 20, 20))
	end
	return out
end

-- Pilote redondo: madera con un collar de percebes y algas en la parte de abajo
function R.Pilote(h: number, c: Color3, s: number): { Piece }
	local out = {}
	rod(out, h, 1.5, CF(0, h / 2, 0), rgb(96, 76, 58), "Wood")
	for k = 1, 3 do
		local y = h * (0.12 + k * 0.08)
		add(out, V(0.5, 1.75, 1.75), CF(0, y, 0) * ANG(0, s + k, pi / 2), if k == 2 then rgb(78, 120, 70) else rgb(190, 184, 170), "Salt", "Cylinder")
	end
	return out
end

-- Pirámide hundida: escalones de piedra oscura con vetas que brillan y una punta de cristal
function R.Piramide(h: number, c: Color3, s: number): { Piece }
	local out = {}
	local steps = 6
	local base = h * 0.88 -- (la malla de Blender: 26,5 de base para 30 de alto)
	for k = 0, steps - 1 do
		local w = base * (1 - k / steps * 0.85)
		local hh = h / steps
		local y = k * hh + hh / 2
		add(out, V(w, hh, w), CF(0, y, 0), if k % 2 == 0 then c else shade(c, 0.12), "Slate")
		add(out, V(w + 0.3, 0.35, w + 0.3), CF(0, y + hh / 2 - 0.4, 0), rgb(80, 236, 255), "Neon", nil, nil, true)
	end
	-- la punta de cristal
	add(out, V(base * 0.12, h * 0.16, base * 0.12), CF(0, h + h * 0.06, 0) * ANG(0, pi / 4, 0), rgb(150, 250, 255), "Glass", nil, nil, true, 0.2)
	-- la puerta (hacia la entrada del cañón, -X)
	add(out, V(0.6, h * 0.22, base * 0.16), CF(-base * 0.5 - 0.2, h * 0.11, 0), rgb(20, 40, 60), "SmoothPlastic")
	add(out, V(0.5, h * 0.03, base * 0.2), CF(-base * 0.5 - 0.3, h * 0.235, 0), rgb(80, 236, 255), "Neon", nil, nil, true)
	return out
end

function R.ColumnaRuina(h: number, c: Color3, s: number): { Piece }
	local out = {}
	rod(out, h * 0.12, h * 0.42, CF(0, h * 0.06, 0), shade(c, 0.1), "Slate")
	rod(out, h * 0.8, h * 0.3, CF(0, h * 0.5, 0) * ANG(0.05 * sin(s), 0, 0.05 * cos(s)), c, "Slate")
	add(out, V(h * 0.31, h * 0.05, h * 0.31), CF(0, h * 0.62, 0), rgb(80, 236, 255), "Neon", "Cylinder", nil, true)
	out[#out].CFrame = CF(0, h * 0.62, 0) * ANG(0, 0, pi / 2)
	out[#out].Size = V(h * 0.05, h * 0.31, h * 0.31)
	return out
end

MarKit.Recipes = R

-- Las piezas de respaldo de una pieza del kit: alto h (studs), color, semilla. Pie en (0,0,0)
function MarKit.fallback(kind: string, h: number, color: Color3, seed: number): { Piece }
	local fn = R[kind]
	if not fn then
		return {}
	end
	return fn(h, color, seed)
end

-- ¿Qué nombres del kit hay? (en orden, para Blender y la subida)
function MarKit.names(): { string }
	local t = {}
	for name in MarKit.Pieces do
		table.insert(t, name)
	end
	table.sort(t)
	return t
end

return MarKit
