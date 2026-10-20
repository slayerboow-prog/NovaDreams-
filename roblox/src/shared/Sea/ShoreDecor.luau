-- ShoreDecor: las recetas del fondo de la orilla y de los arrecifes (v122, docs/mar/orilla.md).
--
-- El dueño, en la orilla de noche: «el mar sigue siendo una puta mierda» (captura
-- docs/mar/captura-dueno-v121-orilla.png). Las «rocas» eran bloques de basalto (cubos negros), las
-- conchas cuadrados planos rosas y la hierba cuatro briznas. Aquí está, en funciones puras (sin
-- Instance: se prueban con Lune en scripts/test-mar.luau), CÓMO es cada cosa del fondo; las piezas las
-- crea Controllers/SeaBiome, solo en tu pantalla, por trozos alrededor de ti.
--
--   CoralHead  coral cerebro/montaña: cúpula grande medio enterrada + bultos y pólipos de color
--   Branch     coral de ramas (cuerno de ciervo): ramas que se abren y puntas redondas
--   Table      coral mesa: un plato ancho sobre un pie
--   Fan        gorgonia (abanico de mar): lámina ovalada fina que se mece, con nervios
--   Anemone    anémona: pie y tentáculos que se mecen; las puntas brillan de noche (bioluminiscencia)
--   Seagrass   pradera: muchas hojas largas (hasta 5 studs) en dos tramos que se mecen
--   Rock       roca irregular de verdad: la malla de asteroide de Blender (si el servidor la ha cargado:
--              ReplicatedStorage.AsteroideMallas) o un racimo de bolas hundidas en la arena; con musgo
--              y percebes. NUNCA un bloque.
--   Shell      conchas (vieiras con nervios y porcelanas brillantes), de colores claros
--   Starfish   estrella de mar de cinco brazos redondeados
--   Crab       cangrejo (cuerpo, pinzas, patas y ojos) que se mueve de lado (SeaBiome lo anima)
--   Urchin     erizo con púas
--
-- Cada receta devuelve { Pieces, Sways, Crab?, MeshRock? }:
--   Piece  { Size, CFrame, Color, Material (nombre de Enum.Material), Shape ("Ball" | "Cylinder" | nil),
--            Mesh ("Sphere" | "Cylinder" | nil: SpecialMesh que redondea un bloque), Transparency?,
--            Glow? (de noche pasa a Neon) }
--   Sway   { Base, Heights, Width, Depth, Color, Amount, Seed, Mesh?, Material?, Glow? } (tramos que se mecen)
-- Materiales: solo los que no sustituye World/UserMaterials (SmoothPlastic, Salt, Neon…) salvo Rock,
-- cuya textura de roca de la tienda es buena. Nada de Basalt (salía negro) ni de bloques sin malla.

local ShoreDecor = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local sin, cos, floor, pi = math.sin, math.cos, math.floor, math.pi

export type Piece = {
	Size: Vector3,
	CFrame: CFrame,
	Color: Color3,
	Material: string,
	Shape: string?,
	Mesh: string?,
	Transparency: number?,
	Glow: boolean?,
}
export type Sway = {
	Base: CFrame,
	Heights: { number },
	Width: number,
	Depth: number,
	Color: Color3,
	Amount: number,
	Seed: number,
	Mesh: string?,
	Material: string?,
	Glow: boolean?,
}
export type Recipe = { Pieces: { Piece }, Sways: { Sway }, Crab: boolean?, MeshRock: { [string]: any }? }
export type Opts = { Mobile: boolean?, MeshRocks: boolean? }

-- Colores (vivos: se ven a través del agua turquesa; nada de marrones)
ShoreDecor.Coral = {
	rgb(255, 96, 120), -- rosa coral
	rgb(255, 150, 70), -- naranja
	rgb(178, 96, 230), -- violeta
	rgb(255, 214, 90), -- amarillo
	rgb(80, 210, 220), -- turquesa
	rgb(240, 90, 170), -- fucsia
	rgb(120, 220, 150), -- verde menta
}
ShoreDecor.Grass = { rgb(64, 156, 84), rgb(88, 176, 72), rgb(52, 138, 96), rgb(112, 178, 64) }
ShoreDecor.RockColor = { rgb(150, 154, 156), rgb(136, 142, 150), rgb(160, 156, 146) }
ShoreDecor.Moss = { rgb(74, 140, 84), rgb(104, 152, 70), rgb(62, 124, 104) }
ShoreDecor.ShellColor = { rgb(250, 238, 216), rgb(252, 196, 168), rgb(255, 250, 242), rgb(246, 160, 104), rgb(214, 186, 236) }
ShoreDecor.StarColor = { rgb(255, 120, 50), rgb(232, 64, 76), rgb(166, 84, 226), rgb(255, 184, 60) }
ShoreDecor.GlowColor = { rgb(90, 245, 255), rgb(255, 120, 220), rgb(150, 255, 170), rgb(170, 140, 255) }

local function pick(list: { Color3 }, r: number): Color3
	return list[1 + floor(r * #list) % #list]
end

local function recipe(): Recipe
	return { Pieces = {}, Sways = {} }
end

local function add(out: Recipe, size: Vector3, cf: CFrame, color: Color3, material: string?, shape: string?, mesh: string?, glow: boolean?, transparency: number?)
	table.insert(out.Pieces, { Size = size, CFrame = cf, Color = color, Material = material or "SmoothPlastic", Shape = shape, Mesh = mesh, Glow = glow, Transparency = transparency })
end

-- Una bola «de verdad» (Shape Ball: siempre redonda)
local function ball(out: Recipe, d: number, at: Vector3, color: Color3, material: string?, glow: boolean?)
	add(out, V(d, d, d), CF(at), color, material, "Ball", nil, glow)
end

-- Un elipsoide (bloque con SpecialMesh de esfera: aplastado o alargado)
local function ellipsoid(out: Recipe, size: Vector3, cf: CFrame, color: Color3, material: string?, glow: boolean?)
	add(out, size, cf, color, material, nil, "Sphere", glow)
end

-- Un cilindro a lo largo de su X (Shape Cylinder)
local function rod(out: Recipe, length: number, d: number, cf: CFrame, color: Color3, material: string?, glow: boolean?)
	add(out, V(length, d, d), cf, color, material, "Cylinder", nil, glow)
end

---------------------------------------------------------------------
-- Recetas
---------------------------------------------------------------------
-- Coral cerebro / montaña: cúpula medio enterrada, bultos alrededor y pólipos de otro color
function ShoreDecor.CoralHead(at: Vector3, r: number, h: (number, number, number) -> number, opts: Opts?): Recipe
	local out = recipe()
	local color = pick(ShoreDecor.Coral, r)
	local accent = pick(ShoreDecor.Coral, h(at.X, at.Z, 61))
	local d = 2.6 + r * 3.2
	ball(out, d, at + V(0, d * 0.12, 0), color, "Salt")
	local lumps = if opts and opts.Mobile then 2 else 4
	for i = 1, lumps do
		local a = h(at.X, i, 62) * pi * 2
		local s = d * (0.35 + h(i, at.Z, 63) * 0.3)
		local off = V(cos(a), 0, sin(a)) * d * 0.42
		ball(out, s, at + off + V(0, d * 0.32, 0), color:Lerp(accent, 0.25), "Salt")
	end
	-- pólipos (las puntas brillan de noche)
	for i = 1, 3 do
		local a = h(i, at.X, 64) * pi * 2
		local p = at + V(cos(a) * d * 0.25, d * 0.6, sin(a) * d * 0.25)
		ball(out, 0.45 + h(at.Z, i, 65) * 0.3, p, accent, "SmoothPlastic", i == 1)
	end
	return out
end

-- Coral de ramas (cuerno de ciervo)
function ShoreDecor.Branch(at: Vector3, r: number, h: (number, number, number) -> number, opts: Opts?): Recipe
	local out = recipe()
	local color = pick(ShoreDecor.Coral, r)
	local n = if opts and opts.Mobile then 4 else 6
	ball(out, 1.2, at + V(0, 0.3, 0), color, "SmoothPlastic")
	for i = 1, n do
		local a = (i / n) * pi * 2 + h(at.X, i, 66)
		local tilt = math.rad(30 + h(i, at.Z, 67) * 30)
		local len = 1.6 + h(at.Z, i, 68) * 1.8
		-- la rama sube inclinada desde el centro (el cilindro va a lo largo de su X: se gira para que suba)
		local base = CF(at + V(0, 0.4, 0)) * ANG(0, a, 0) * ANG(0, 0, pi / 2 - tilt)
		rod(out, len, 0.34, base * CF(len / 2, 0, 0), color, "SmoothPlastic")
		local tip = (base * CF(len, 0, 0)).Position
		ball(out, 0.5, tip, color:Lerp(rgb(255, 255, 255), 0.35), "SmoothPlastic", i % 3 == 0)
		-- una ramita más en las largas
		if len > 2.4 and not (opts and opts.Mobile) then
			local mid = base * CF(len * 0.6, 0, 0)
			local twig = mid * ANG(0, 0, -0.6)
			rod(out, len * 0.45, 0.26, twig * CF(len * 0.22, 0, 0), color, "SmoothPlastic")
		end
	end
	return out
end

-- Coral mesa: plato ancho sobre un pie corto
function ShoreDecor.Table(at: Vector3, r: number, h: (number, number, number) -> number, _opts: Opts?): Recipe
	local out = recipe()
	local color = pick(ShoreDecor.Coral, h(at.X, at.Z, 69))
	local w = 3.4 + r * 3
	rod(out, 1.4, 0.9, CF(at + V(0, 0.7, 0)) * ANG(0, 0, pi / 2), color:Lerp(rgb(80, 80, 90), 0.2), "Salt")
	ellipsoid(out, V(w, 0.55, w * 0.85), CF(at + V(0, 1.5, 0)) * ANG(0, r * 6, 0.05), color, "Salt")
	ellipsoid(out, V(w * 0.55, 0.4, w * 0.5), CF(at + V(w * 0.15, 1.75, 0)) * ANG(0, r * 3, 0), color:Lerp(rgb(255, 255, 255), 0.2), "Salt")
	return out
end

-- Gorgonia (abanico de mar): lámina ovalada que se mece y un pie
function ShoreDecor.Fan(at: Vector3, r: number, h: (number, number, number) -> number, _opts: Opts?): Recipe
	local out = recipe()
	local fans = { rgb(176, 64, 180), rgb(232, 62, 86), rgb(250, 140, 60), rgb(255, 210, 80) }
	local color = pick(fans, r)
	local w = 2.2 + r * 2
	local yaw = h(at.X, at.Z, 70) * pi * 2
	rod(out, 0.8, 0.3, CF(at + V(0, 0.4, 0)) * ANG(0, 0, pi / 2), color:Lerp(rgb(60, 40, 60), 0.3), "SmoothPlastic")
	table.insert(out.Sways, { Base = CF(at + V(0, 0.6, 0)) * ANG(0, yaw, 0), Heights = { w * 0.95 }, Width = w, Depth = 0.12, Color = color, Amount = 0.07, Seed = r, Mesh = "Sphere", Material = "SmoothPlastic" })
	return out
end

-- Anémona: pie redondo y tentáculos que se mecen; las puntas brillan de noche
function ShoreDecor.Anemone(at: Vector3, r: number, h: (number, number, number) -> number, opts: Opts?): Recipe
	local out = recipe()
	local bodies = { rgb(236, 120, 140), rgb(250, 190, 150), rgb(140, 210, 190), rgb(200, 120, 220) }
	local body = pick(bodies, r)
	local tent = body:Lerp(rgb(255, 255, 255), 0.25)
	ellipsoid(out, V(1.6, 1, 1.6), CF(at + V(0, 0.35, 0)), body, "SmoothPlastic")
	local n = if opts and opts.Mobile then 6 else 10
	for i = 1, n do
		local a = (i / n) * pi * 2 + r
		local base = CF(at + V(cos(a) * 0.45, 0.75, sin(a) * 0.45)) * ANG(0, -a, 0) * ANG(0, 0, -0.35)
		local len = 1 + h(at.X, i, 71) * 0.9
		table.insert(out.Sways, { Base = base, Heights = { len }, Width = 0.18, Depth = 0.18, Color = tent, Amount = 0.22, Seed = h(i, at.Z, 72), Mesh = "Cylinder", Material = "SmoothPlastic", Glow = i % 2 == 0 })
	end
	return out
end

-- Pradera de hierba marina: hojas largas en dos tramos que se mecen
function ShoreDecor.Seagrass(at: Vector3, r: number, h: (number, number, number) -> number, opts: Opts?): Recipe
	local out = recipe()
	local n = if opts and opts.Mobile then 8 else 13
	for i = 1, n do
		local a = h(at.X, at.Z, i) * pi * 2
		local off = V(cos(a), 0, sin(a)) * h(at.Z, at.X, i) * 2.2
		local hgt = 2.4 + h(at.X + i, at.Z, 3) * 2.6
		local base = CF(at + off) * ANG((h(i, at.X, 4) - 0.5) * 0.3, a, (h(at.Z, i, 5) - 0.5) * 0.3)
		table.insert(out.Sways, { Base = base, Heights = { hgt * 0.55, hgt * 0.45 }, Width = 0.32, Depth = 0.06, Color = pick(ShoreDecor.Grass, h(i, i, at.X)), Amount = 0.16, Seed = h(at.X, i, 6), Material = "SmoothPlastic" })
	end
	return out
end

-- Roca irregular: la malla de asteroide o un racimo de bolas hundidas, con musgo y percebes
function ShoreDecor.Rock(at: Vector3, r: number, h: (number, number, number) -> number, opts: Opts?): Recipe
	local out = recipe()
	local color = pick(ShoreDecor.RockColor, h(at.X, at.Z, 73))
	local moss = pick(ShoreDecor.Moss, r)
	local size = 2.2 + r * 4.5
	if opts and opts.MeshRocks then
		-- (la malla: SeaBiome la clona de ReplicatedStorage.AsteroideMallas, sin la textura del espacio)
		out.MeshRock = {
			Variant = 1 + floor(h(at.Z, at.X, 74) * 6) % 6,
			Size = V(size * 1.3, size * 0.75, size),
			CFrame = CF(at + V(0, size * 0.18, 0)) * ANG(h(at.X, 1, 75) * 0.4, r * 6, h(at.Z, 2, 75) * 0.4),
			Color = color,
			Material = "Rock",
		}
	else
		local parts = if opts and opts.Mobile then 3 else 4
		for i = 1, parts do
			local a = h(at.X, i, 76) * pi * 2
			local s = size * (0.55 + h(i, at.Z, 77) * 0.45) * (if i == 1 then 1 else 0.75)
			local off = if i == 1 then V(0, 0, 0) else V(cos(a), 0, sin(a)) * size * 0.32
			ball(out, s, at + off + V(0, s * 0.18, 0), color:Lerp(rgb(110, 116, 124), h(i, i, 78) * 0.4), "Rock")
		end
	end
	-- musgo encima (un casquete aplastado) y unos percebes claros
	ellipsoid(out, V(size * 0.8, size * 0.22, size * 0.7), CF(at + V(0, size * 0.48, 0)) * ANG(0, r * 4, 0), moss, "SmoothPlastic")
	for i = 1, 2 do
		local a = h(i, at.X, 79) * pi * 2
		ball(out, 0.35, at + V(cos(a) * size * 0.4, size * 0.3, sin(a) * size * 0.4), rgb(236, 232, 220), "SmoothPlastic")
	end
	return out
end

-- Conchas: vieiras (abanico con nervios) y porcelanas (brillantes)
function ShoreDecor.Shell(at: Vector3, r: number, h: (number, number, number) -> number, opts: Opts?): Recipe
	local out = recipe()
	local n = if opts and opts.Mobile then 2 else 3
	for i = 1, n do
		local p = at + V(h(i, at.X, 80) * 3 - 1.5, 0.12, h(at.Z, i, 81) * 3 - 1.5)
		local color = pick(ShoreDecor.ShellColor, h(i, at.Z, 82))
		local yaw = h(i, i, 83) * pi * 2
		if (i + floor(r * 4)) % 2 == 0 then
			-- vieira: abanico aplastado y tres nervios
			local cf = CF(p) * ANG(0, yaw, 0)
			ellipsoid(out, V(1.1, 0.28, 0.95), cf, color, "SmoothPlastic")
			for k = -1, 1 do
				rod(out, 0.9, 0.08, cf * CF(0, 0.12, 0) * ANG(0, k * 0.45 + pi / 2, 0) * CF(0.35, 0, 0), color:Lerp(rgb(200, 120, 90), 0.3), "SmoothPlastic")
			end
		else
			-- porcelana: huevo brillante con una raya
			local cf = CF(p) * ANG(0, yaw, 0)
			ellipsoid(out, V(0.6, 0.36, 0.95), cf, color, "Glass")
			ellipsoid(out, V(0.12, 0.38, 0.8), cf * CF(0, 0.02, 0), color:Lerp(rgb(120, 70, 50), 0.45), "SmoothPlastic")
		end
	end
	return out
end

-- Estrella de mar: cinco brazos redondeados
function ShoreDecor.Starfish(at: Vector3, r: number, h: (number, number, number) -> number, _opts: Opts?): Recipe
	local out = recipe()
	local color = pick(ShoreDecor.StarColor, r)
	local s = 0.8 + h(at.X, at.Z, 84) * 0.6
	local base = CF(at + V(0, 0.1, 0)) * ANG(0, r * 6, 0)
	ellipsoid(out, V(0.7 * s, 0.25 * s, 0.7 * s), base, color, "SmoothPlastic")
	for i = 0, 4 do
		ellipsoid(out, V(0.36 * s, 0.2 * s, 1.15 * s), base * ANG(0, i * pi * 2 / 5, 0) * CF(0, 0, -0.5 * s), color, "SmoothPlastic")
	end
	return out
end

-- Cangrejo (SeaBiome lo hace andar de lado)
function ShoreDecor.Crab(at: Vector3, r: number, _h: (number, number, number) -> number, opts: Opts?): Recipe
	local out = recipe()
	out.Crab = true
	local shell = if r > 0.5 then rgb(232, 84, 52) else rgb(246, 132, 60)
	local base = CF(at + V(0, 0.45, 0)) * ANG(0, r * 6, 0)
	ellipsoid(out, V(1.5, 0.6, 1.1), base, shell, "SmoothPlastic")
	for side = -1, 1, 2 do
		-- pinzas delante
		ellipsoid(out, V(0.55, 0.4, 0.75), base * CF(side * 0.7, 0.05, -0.85) * ANG(0, side * 0.4, 0), shell:Lerp(rgb(255, 200, 160), 0.2), "SmoothPlastic")
		-- ojos
		ball(out, 0.18, (base * CF(side * 0.25, 0.42, -0.45)).Position, rgb(20, 20, 26), "SmoothPlastic")
		-- patas
		local legs = if opts and opts.Mobile then 2 else 3
		for k = 1, legs do
			local z = -0.3 + (k - 1) * 0.35
			rod(out, 0.9, 0.12, base * CF(side * 0.95, -0.15, z) * ANG(0, 0, side * 0.6), shell:Lerp(rgb(150, 50, 40), 0.25), "SmoothPlastic")
		end
	end
	return out
end

-- Erizo: bola oscura violeta con púas
function ShoreDecor.Urchin(at: Vector3, r: number, h: (number, number, number) -> number, opts: Opts?): Recipe
	local out = recipe()
	local color = if r > 0.5 then rgb(84, 40, 120) else rgb(40, 50, 110)
	ball(out, 0.9, at + V(0, 0.4, 0), color, "SmoothPlastic")
	local n = if opts and opts.Mobile then 4 else 7
	for i = 1, n do
		local a = (i / n) * pi * 2 + r
		local tilt = 0.3 + h(i, at.X, 85) * 0.8
		rod(out, 1.1, 0.07, CF(at + V(0, 0.45, 0)) * ANG(0, a, tilt) * CF(0.5, 0, 0), color:Lerp(rgb(200, 180, 240), 0.2), "SmoothPlastic")
	end
	return out
end

-- Por nombre (OceanBiomes.Zones[z].Flora)
ShoreDecor.Kinds = {
	CoralHead = ShoreDecor.CoralHead,
	Branch = ShoreDecor.Branch,
	Table = ShoreDecor.Table,
	Fan = ShoreDecor.Fan,
	Anemone = ShoreDecor.Anemone,
	Seagrass = ShoreDecor.Seagrass,
	Rock = ShoreDecor.Rock,
	Shell = ShoreDecor.Shell,
	Starfish = ShoreDecor.Starfish,
	Crab = ShoreDecor.Crab,
	Urchin = ShoreDecor.Urchin,
}

-- Piezas que gasta una receta (las que se mecen cuentan un tramo cada una)
function ShoreDecor.count(rec: Recipe): number
	local n = #rec.Pieces + (if rec.MeshRock then 1 else 0)
	for _, s in rec.Sways do
		n += #s.Heights
	end
	return n
end

-- ¿Es «marrón» este color? (para la prueba: la paleta del fondo no puede ser de barro)
function ShoreDecor.isBrown(c: Color3): boolean
	local h, s, v = c:ToHSV()
	return h >= 15 / 360 and h <= 50 / 360 and s > 0.25 and v < 0.7
end

-- Presupuesto de piezas del fondo en tu pantalla (SeaBiome): por encima, los trozos nuevos se plantan
-- con menos cosas
ShoreDecor.Budget = { Mobile = 1400, Desktop = 3000 }

return ShoreDecor
