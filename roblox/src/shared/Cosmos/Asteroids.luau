-- Asteroids: cómo es y cómo se rompe cada asteroide (cuentas puras; docs/espacio-aaa/asteroides.md).
--
--   * Forma (Asteroids.shape): cada asteroide es una roca irregular hecha con unos cuantos bloques y
--     cuñas girados (nunca una bola), con cráteres, vetas de mineral que brillan un poco, grietas
--     (ocultas hasta que se daña) y piedrecitas alrededor. Repetible: el mismo id da la misma roca en
--     el servidor, el cliente, las pruebas y el render de Blender. Si hay mallas subidas
--     (AsteroidAssetIds), el núcleo es una MeshPart y lo demás se pone igual.
--   * Daño (Asteroids.stage): según las unidades que le quedan (Mining.Rock): 0 entero, 1-3 grietas.
--   * Rotura (Asteroids.split): al gastarse, se parte en trozos más pequeños (grande → 3 medianos →
--     2-3 pequeños → polvo). Cada trozo sale hacia fuera con su impulso, su giro y la velocidad de
--     quien lo rompió, y se frena poco a poco (movimiento con rozamiento: posAt/rotAt dan dónde está en
--     cada instante, sin bucles por fotograma en el servidor). Los trozos se pueden minar otra vez y
--     se van solos a los FragmentLife segundos.
--   * Registro (setFamily/isGone/fragment/rockOf/liveIn): qué asteroides están rotos y qué trozos hay.
--     El SERVIDOR lo decide (SpaceService) y lo publica como texto (encode/decode) en un atributo de
--     ReplicatedStorage.AsteroidesEstado; el cliente lo lee para chocar y ver los trozos.
--   * Reaparecer: RespawnSeconds después de romperse, el asteroide vuelve y los trozos que queden se van.
--   * Choques: Asteroids.ramDamage(velocidad) (al escudo de la nave) y ramHits (daño a la roca).
--   * Topes para el móvil: FragmentMax trozos vivos, DebrisMax pedazos sueltos de adorno (cliente).

local Mining = require(script.Parent.Mining)

local Asteroids = {}

-- Tamaños: grande → medianos → pequeños → polvo
export type Tier = { Name: string, Min: number, Children: number, Scale: number }
Asteroids.Tiers = {
	{ Name = "Grande", Min = 34, Children = 3, Scale = 0.52 },
	{ Name = "Mediano", Min = 17, Children = 3, Scale = 0.5 },
	{ Name = "Pequeno", Min = 0, Children = 0, Scale = 0 },
} :: { Tier }
Asteroids.MinChild = 7 -- (un trozo nunca es más pequeño que esto: si no, es polvo)
Asteroids.Drag = 0.55 -- rozamiento de los trozos (1/s): se paran en unos segundos
Asteroids.SpreadSpeed = { 12, 26 } -- studs/s hacia fuera al romperse
Asteroids.SpinSpeed = { 0.7, 1.8 } -- rad/s al romperse (se frena con Drag)
Asteroids.Tumble = 0.05 -- rad/s de giro lento que se queda
Asteroids.InheritMax = 30 -- studs/s como mucho de la velocidad de quien lo rompe
Asteroids.FragmentLife = 75 -- s: los trozos se van solos (si nadie los mina)
Asteroids.RespawnSeconds = Mining.RefillSeconds -- s: el asteroide vuelve entero
Asteroids.FragmentMax = 48 -- trozos vivos a la vez en todo el servidor (si no, se hace polvo)
Asteroids.DebrisMax = 60 -- pedazos de adorno a la vez en cada cliente (Controllers/AsteroidFx)
Asteroids.DebrisLife = { 2.5, 5 }
Asteroids.LodFar = 650 -- más lejos: sin detalles (vetas, cráteres, piedrecitas)
Asteroids.TumbleRange = 900 -- solo giran los cercanos…
Asteroids.TumbleMax = 14 -- …y como mucho estos
Asteroids.ChildUnitsFactor = 0.5 -- un trozo tiene la mitad de mineral que un asteroide de su tamaño

-- Colores y materiales por campo (Hierro: gris pizarra; Brasa: basalto rojizo; Escarcha: gris azulado)
export type Palette = { Base: Color3, Dark: Color3, Light: Color3, Core: Enum.Material, Facet: Enum.Material, Crater: Enum.Material }
local rgb = Color3.fromRGB
Asteroids.Palettes = {
	Hierro = { Base = rgb(98, 92, 88), Dark = rgb(46, 43, 44), Light = rgb(150, 142, 132), Core = Enum.Material.Slate, Facet = Enum.Material.Rock, Crater = Enum.Material.Basalt },
	Brasa = { Base = rgb(104, 76, 64), Dark = rgb(48, 32, 28), Light = rgb(160, 112, 88), Core = Enum.Material.Basalt, Facet = Enum.Material.Rock, Crater = Enum.Material.CrackedLava },
	Escarcha = { Base = rgb(92, 100, 112), Dark = rgb(40, 44, 54), Light = rgb(170, 186, 204), Core = Enum.Material.Slate, Facet = Enum.Material.Glacier, Crater = Enum.Material.Basalt },
} :: { [string]: Palette }
Asteroids.CrackColor = rgb(255, 120, 45)
-- Brillo de cada mineral en sus vetas (el Hierro estelar, un brillo metálico cálido y flojo)
Asteroids.VeinGlow = {
	Hierro = { Color = rgb(214, 160, 112), Transparency = 0.45, Metal = true },
	Cobalto = { Color = rgb(70, 140, 255), Transparency = 0.15, Metal = false },
	Cristal = { Color = rgb(255, 214, 80), Transparency = 0.1, Metal = false },
} :: { [string]: { Color: Color3, Transparency: number, Metal: boolean } }

---------------------------------------------------------------------
-- Números repetibles
---------------------------------------------------------------------
function Asteroids.hash(s: string): number
	local h = 5381
	for i = 1, #s do
		h = (h * 33 + string.byte(s, i)) % 2147483647
	end
	return h
end

local function rng(seed: number): () -> number
	local s = seed % 2147483647
	if s <= 0 then
		s += 2147483646
	end
	return function()
		s = (s * 16807) % 2147483647
		return s / 2147483647
	end
end

local function range(r: () -> number, a: number, b: number): number
	return a + (b - a) * r()
end

local function unitVector(r: () -> number): Vector3
	local z = r() * 2 - 1
	local a = r() * math.pi * 2
	local k = math.sqrt(math.max(0, 1 - z * z))
	return Vector3.new(math.cos(a) * k, z, math.sin(a) * k)
end

local function randomRotation(r: () -> number): CFrame
	return CFrame.Angles(r() * math.pi * 2, r() * math.pi * 2, r() * math.pi * 2)
end

local function frameUp(pos: Vector3, up: Vector3, spin: number): CFrame
	-- (un CFrame en pos cuyo eje Y es up, girado spin sobre él)
	local helper = if math.abs(up.Y) < 0.9 then Vector3.new(0, 1, 0) else Vector3.new(1, 0, 0)
	local right = helper:Cross(up).Unit
	local back = right:Cross(up).Unit
	return CFrame.fromMatrix(pos, right, up, back) * CFrame.Angles(0, spin, 0)
end

---------------------------------------------------------------------
-- Forma
---------------------------------------------------------------------
export type Piece = {
	Kind: string, -- "Block", "Wedge", "CornerWedge" o "Cylinder"
	Role: string, -- "Core", "Facet", "Crater", "Rim", "Vein", "Crack", "Pebble", "Shard"
	Size: Vector3,
	CFrame: CFrame, -- respecto al centro del asteroide
	Color: Color3,
	Material: Enum.Material,
	Transparency: number,
	Stage: number?, -- (grietas) se ve desde este nivel de daño
	Detail: boolean, -- se quita de lejos (LOD)
}
export type Shape = { Variant: number, VariantName: string, Pieces: { Piece }, Radius: number }

Asteroids.Variants = { "Patata", "Losa", "Bloque", "Doble", "Astilla", "Pina" }
-- Medias medidas de los bloques del núcleo (× radio) y cuántos, por variante
local VARIANT_BOX = {
	Patata = { Half = Vector3.new(0.8, 0.5, 0.58), Count = 4, Offset = 0.12 },
	Losa = { Half = Vector3.new(0.82, 0.32, 0.66), Count = 3, Offset = 0.1 },
	Bloque = { Half = Vector3.new(0.68, 0.46, 0.56), Count = 4, Offset = 0.08 },
	Doble = { Half = Vector3.new(0.46, 0.4, 0.44), Count = 5, Offset = 0.26 },
	Astilla = { Half = Vector3.new(0.88, 0.36, 0.4), Count = 3, Offset = 0.16 },
	Pina = { Half = Vector3.new(0.66, 0.42, 0.5), Count = 6, Offset = 0.18 },
}

local FACES = {
	Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
	Vector3.new(0, 1, 0), Vector3.new(0, -1, 0),
	Vector3.new(0, 0, 1), Vector3.new(0, 0, -1),
}

local function shade(c: Color3, k: number): Color3
	return Color3.new(math.clamp(c.R * k, 0, 1), math.clamp(c.G * k, 0, 1), math.clamp(c.B * k, 0, 1))
end

local function insideBox(p: Vector3, cf: CFrame, half: Vector3, margin: number): boolean
	local l = cf:Inverse() * p
	return math.abs(l.X) < half.X - margin and math.abs(l.Y) < half.Y - margin and math.abs(l.Z) < half.Z - margin
end

type Face = { Center: Vector3, Normal: Vector3, Span: Vector2, Exposure: number }

-- Forma de un asteroide (id, radio de choque, mineral, campo). Todo cabe más o menos en la esfera de
-- choque (Zone): los bloques llegan de 0,6 a 1,15 radios del centro.
function Asteroids.shape(id: string, radius: number, ore: string?, field: string?): Shape
	local r = rng(Asteroids.hash(id) + 77)
	local vi = 1 + (Asteroids.hash(id .. "v") % #Asteroids.Variants)
	local vname = Asteroids.Variants[vi]
	local vb = VARIANT_BOX[vname]
	local pal = Asteroids.Palettes[field or ""] or Asteroids.Palettes.Hierro
	local R = radius
	local pieces: { Piece } = {}
	local small = R < 16
	local count = if small then math.max(2, vb.Count - 2) else vb.Count
	-- Núcleo: bloques girados que se pisan (silueta facetada, como una roca de verdad)
	local boxes: { { CF: CFrame, Half: Vector3 } } = {}
	local lobe = unitVector(r)
	for i = 1, count do
		local h = vb.Half * R
		h = Vector3.new(h.X * range(r, 0.85, 1.12), h.Y * range(r, 0.85, 1.12), h.Z * range(r, 0.85, 1.12))
		local off = unitVector(r) * R * vb.Offset * r()
		if vname == "Doble" then
			off += lobe * R * (if i % 2 == 0 then 0.3 else -0.26)
		end
		-- (giros de hasta ±0,75 rad sobre la misma orientación: la losa sigue plana, la astilla alargada)
		local j = if vname == "Pina" then 0.5 elseif vname == "Bloque" then 0.5 else 0.42
		local cf = CFrame.new(off) * CFrame.Angles(range(r, -j, j), range(r, -j, j), range(r, -j, j))
		table.insert(boxes, { CF = cf, Half = h })
		table.insert(pieces, {
			Kind = "Block", Role = "Core", Size = h * 2, CFrame = cf,
			Color = shade(pal.Base, range(r, 0.86, 1.1)), Material = if i == 1 then pal.Core else (if r() < 0.5 then pal.Core else pal.Facet),
			Transparency = 0, Detail = false,
		})
	end
	-- Caras al aire (las que no quedan dentro de otro bloque): ahí van cuñas, cráteres y vetas
	local faces: { Face } = {}
	for bi, b in boxes do
		for _, n in FACES do
			local half = b.Half
			local localCenter = Vector3.new(n.X * half.X, n.Y * half.Y, n.Z * half.Z)
			local center = b.CF * localCenter
			local hidden = false
			for bj, o in boxes do
				if bj ~= bi and insideBox(center, o.CF, o.Half, 0.02 * R) then
					hidden = true
					break
				end
			end
			if not hidden then
				local span = if n.X ~= 0 then Vector2.new(half.Z * 2, half.Y * 2) elseif n.Y ~= 0 then Vector2.new(half.X * 2, half.Z * 2) else Vector2.new(half.X * 2, half.Y * 2)
				local worldN = (b.CF * n) - b.CF.Position
				table.insert(faces, { Center = center, Normal = worldN.Unit, Span = span, Exposure = center.Magnitude })
			end
		end
	end
	table.sort(faces, function(a, b)
		return a.Exposure > b.Exposure
	end)
	local used = 0
	local function nextFace(): Face?
		if #faces == 0 then
			return nil
		end
		used += 1
		return faces[((used - 1) % #faces) + 1]
	end
	-- Cuñas: rompen las caras planas (la silueta deja de ser de caja)
	local wedges = if small then 1 else 3
	for _ = 1, wedges do
		local f = nextFace()
		if not f then
			break
		end
		local w = math.min(f.Span.X, f.Span.Y) * range(r, 0.55, 0.85)
		local t = R * range(r, 0.18, 0.3)
		local cf = frameUp(f.Center + f.Normal * (t * 0.5 - R * 0.04), f.Normal, math.floor(r() * 4) * math.pi / 2)
		table.insert(pieces, {
			Kind = if r() < 0.5 then "Wedge" else "CornerWedge", Role = "Facet", Size = Vector3.new(w, t, w * range(r, 0.7, 1)), CFrame = cf,
			Color = shade(pal.Base, range(r, 0.8, 1.05)), Material = pal.Facet, Transparency = 0, Detail = false,
		})
	end
	-- Cráteres: disco oscuro y un borde más claro (en los grandes)
	local craters = if R >= 40 then 3 elseif R >= 22 then 2 elseif R >= 14 then 1 else 0
	for _ = 1, craters do
		local f = nextFace()
		if not f then
			break
		end
		local d = math.min(f.Span.X, f.Span.Y) * range(r, 0.35, 0.6)
		local jitter = Vector3.new(range(r, -0.15, 0.15), range(r, -0.15, 0.15), range(r, -0.15, 0.15)) * d
		jitter -= f.Normal * jitter:Dot(f.Normal)
		local at = f.Center + jitter
		local axis = frameUp(at, f.Normal, 0) * CFrame.Angles(0, 0, math.pi / 2) -- (el eje X del cilindro, hacia fuera)
		table.insert(pieces, {
			Kind = "Cylinder", Role = "Rim", Size = Vector3.new(R * 0.06, d * 1.3, d * 1.3), CFrame = axis,
			Color = pal.Light, Material = pal.Facet, Transparency = 0, Detail = true,
		})
		table.insert(pieces, {
			Kind = "Cylinder", Role = "Crater", Size = Vector3.new(R * 0.07, d, d), CFrame = axis * CFrame.new(R * 0.012, 0, 0),
			Color = pal.Dark, Material = pal.Crater, Transparency = 0, Detail = true,
		})
	end
	-- Vetas de mineral (finas, un poco salidas, con un brillo flojo)
	local glow = Asteroids.VeinGlow[ore or ""]
	if glow then
		local veins = if R >= 30 then 3 elseif R >= 16 then 2 else 1
		for _ = 1, veins do
			local f = nextFace()
			if not f then
				break
			end
			local len = math.max(f.Span.X, f.Span.Y) * range(r, 0.6, 0.95)
			local cf = frameUp(f.Center + f.Normal * R * 0.015, f.Normal, r() * math.pi)
			table.insert(pieces, {
				Kind = "Block", Role = "Vein", Size = Vector3.new(len, R * 0.035, R * range(r, 0.05, 0.09)), CFrame = cf,
				Color = glow.Color, Material = Enum.Material.Neon, Transparency = glow.Transparency, Detail = true,
			})
			if glow.Metal then
				table.insert(pieces, {
					Kind = "Block", Role = "Vein", Size = Vector3.new(len * 0.8, R * 0.05, R * 0.13), CFrame = cf * CFrame.new(0, -R * 0.01, 0),
					Color = rgb(150, 140, 128), Material = Enum.Material.Metal, Transparency = 0, Detail = true,
				})
			elseif ore == "Cristal" then
				-- (cristales que asoman)
				for k = 1, 2 do
					table.insert(pieces, {
						Kind = "Wedge", Role = "Shard", Size = Vector3.new(R * 0.08, R * range(r, 0.18, 0.3), R * 0.1),
						CFrame = cf * CFrame.new((k - 1.5) * len * 0.4, R * 0.08, 0) * CFrame.Angles(0, r() * math.pi, range(r, -0.3, 0.3)),
						Color = glow.Color, Material = Enum.Material.Glass, Transparency = 0.25, Detail = true,
					})
				end
			end
		end
	end
	-- Grietas (ocultas): se ven al dañarlo (stage 1, 2 y 3)
	for k = 1, 3 do
		local f = faces[1 + ((k * 2 - 1) % math.max(1, #faces))]
		if not f then
			break
		end
		local len = math.max(f.Span.X, f.Span.Y) * range(r, 0.5, 0.9)
		local cf = frameUp(f.Center + f.Normal * R * 0.012, f.Normal, r() * math.pi)
		table.insert(pieces, {
			Kind = "Block", Role = "Crack", Size = Vector3.new(len, R * 0.03, R * 0.045), CFrame = cf,
			Color = Asteroids.CrackColor, Material = Enum.Material.Neon, Transparency = 1, Stage = k, Detail = false,
		})
	end
	-- Piedrecitas alrededor (los grandes: de chinas a rocas, como un enjambre)
	local pebbles = if R >= 40 then 4 elseif R >= 26 then 2 else 0
	for _ = 1, pebbles do
		local s = R * range(r, 0.07, 0.18)
		local at = unitVector(r) * R * range(r, 1.25, 1.75)
		table.insert(pieces, {
			Kind = if r() < 0.6 then "Block" else "CornerWedge", Role = "Pebble",
			Size = Vector3.new(s * range(r, 0.8, 1.4), s * range(r, 0.6, 1), s), CFrame = CFrame.new(at) * randomRotation(r),
			Color = shade(pal.Base, range(r, 0.75, 1)), Material = pal.Core, Transparency = 0, Detail = true,
		})
	end
	return { Variant = vi, VariantName = vname, Pieces = pieces, Radius = R }
end

-- Medidas de la forma (para las pruebas): el radio más cercano y más lejano de las esquinas del núcleo
function Asteroids.extents(shape: Shape): (number, number, Vector3)
	local mn, mx = math.huge, 0
	local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, p in shape.Pieces do
		if p.Role == "Core" then
			local h = p.Size / 2
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local c = p.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)
						mx = math.max(mx, c.Magnitude)
						lo = Vector3.new(math.min(lo.X, c.X), math.min(lo.Y, c.Y), math.min(lo.Z, c.Z))
						hi = Vector3.new(math.max(hi.X, c.X), math.max(hi.Y, c.Y), math.max(hi.Z, c.Z))
					end
				end
			end
			mn = math.min(mn, math.min(h.X, h.Y, h.Z))
		end
	end
	return mn, mx, hi - lo
end

-- Giro fijo de un asteroide (para que no estén todos igual puestos)
function Asteroids.baseRotation(id: string): CFrame
	return randomRotation(rng(Asteroids.hash(id) + 5))
end

-- Giro lento (rad/s) y su eje, para los cercanos (cliente)
function Asteroids.tumble(id: string): (Vector3, number)
	local r = rng(Asteroids.hash(id) + 9)
	return unitVector(r), range(r, 0.025, 0.09) * (if r() < 0.5 then -1 else 1)
end

---------------------------------------------------------------------
-- Daño
---------------------------------------------------------------------
function Asteroids.tierOf(radius: number): Tier
	for _, t in Asteroids.Tiers do
		if radius >= t.Min then
			return t
		end
	end
	return Asteroids.Tiers[#Asteroids.Tiers]
end

-- Nivel de daño 0..3 (0 entero; 3 a punto de romperse) de un Mining.Rock
function Asteroids.stage(rock: Mining.Rock): number
	if rock.Max <= 0 then
		return 0
	end
	local broken = (rock.Max - rock.Units) + rock.Hits / Mining.HitsPerUnit
	return math.clamp(math.floor(broken / rock.Max * 3 + 0.35), 0, 3)
end

-- Mineral de un trozo (la mitad que un asteroide de su tamaño, al menos 1)
function Asteroids.childUnits(radius: number): number
	return math.max(1, math.floor(Mining.units(radius) * Asteroids.ChildUnitsFactor))
end

-- Choque de la nave: daño al escudo (y lo que sobre, al casco) según la velocidad (studs/s)
Asteroids.RamSafe = 18 -- por debajo, un roce sin daño
Asteroids.RamPerStud = 0.32
Asteroids.RamMax = 400
function Asteroids.ramDamage(speed: number): number
	if speed ~= speed or speed <= Asteroids.RamSafe then
		return 0
	end
	return math.min(Asteroids.RamMax, (speed - Asteroids.RamSafe) * Asteroids.RamPerStud)
end
-- …y lo que le hace a la roca (impactos, como los del láser; sin mineral para nadie)
function Asteroids.ramHits(speed: number): number
	if speed ~= speed or speed <= Asteroids.RamSafe then
		return 0
	end
	return math.clamp(math.floor(speed / 55), 1, 12)
end

---------------------------------------------------------------------
-- Trozos
---------------------------------------------------------------------
export type Fragment = {
	Id: string,
	Root: string, -- el asteroide de Zone del que sale
	Field: string,
	Ore: string,
	Radius: number,
	Gen: number, -- 1 mediano, 2 pequeño…
	T0: number,
	Expire: number,
	P0: Vector3,
	V0: Vector3,
	Axis: Vector3,
	W: number,
}
export type Family = { Root: string, Field: string, Respawn: number, Frags: { [string]: Fragment } }
export type RockLike = { Id: string, Field: string, Center: Vector3, Radius: number, Ore: string, Fragment: boolean?, Root: string? }

function Asteroids.posAt(f: Fragment, t: number): Vector3
	local dt = math.max(0, t - f.T0)
	local k = Asteroids.Drag
	return f.P0 + f.V0 * ((1 - math.exp(-k * dt)) / k)
end

function Asteroids.velAt(f: Fragment, t: number): Vector3
	local dt = math.max(0, t - f.T0)
	return f.V0 * math.exp(-Asteroids.Drag * dt)
end

function Asteroids.rotAt(f: Fragment, t: number): CFrame
	local dt = math.max(0, t - f.T0)
	local k = Asteroids.Drag
	local angle = f.W * (1 - math.exp(-k * dt)) / k + Asteroids.Tumble * dt
	return Asteroids.baseRotation(f.Id) * CFrame.fromAxisAngle(f.Axis, angle)
end

-- Parte un asteroide (o un trozo) en trozos más pequeños. parent: lo que se rompe (con su centro AHORA),
-- parentVel: su velocidad ahora (un trozo que aún vuela), push: la velocidad de quien lo rompe (disparo
-- o nave), room: cuántos trozos caben aún (FragmentMax). Devuelve la lista (vacía = se hace polvo).
function Asteroids.split(parent: RockLike, gen: number, t0: number, parentVel: Vector3?, push: Vector3?, room: number?): { Fragment }
	local out: { Fragment } = {}
	local tier = Asteroids.tierOf(parent.Radius)
	local n = tier.Children
	if n <= 0 then
		return out
	end
	local r = rng(Asteroids.hash(parent.Id .. "/" .. tostring(math.floor(t0 * 10))) + 31)
	if tier.Name == "Mediano" and r() < 0.4 then
		n = 2
	end
	n = math.min(n, math.max(0, room or n))
	local childR = parent.Radius * tier.Scale
	if childR < Asteroids.MinChild then
		return out
	end
	-- Direcciones repartidas (en un plano al azar, a 360/n grados, con algo de inclinación)
	local up = unitVector(r)
	local helper = if math.abs(up.Y) < 0.9 then Vector3.new(0, 1, 0) else Vector3.new(1, 0, 0)
	local e1 = helper:Cross(up).Unit
	local e2 = up:Cross(e1).Unit
	local base = r() * math.pi * 2
	local inherit = parentVel or Vector3.zero
	local p = push or Vector3.zero
	if p.Magnitude > Asteroids.InheritMax then
		p = p.Unit * Asteroids.InheritMax
	end
	inherit += p * 0.35
	local root = parent.Root or parent.Id
	for k = 1, n do
		local a = base + (k - 1) / n * math.pi * 2 + range(r, -0.25, 0.25)
		local dir = (e1 * math.cos(a) + e2 * math.sin(a) + up * range(r, -0.35, 0.35)).Unit
		local radius = childR * range(r, 0.85, 1.12)
		table.insert(out, {
			Id = ("%s~%d"):format(parent.Id, k),
			Root = root,
			Field = parent.Field,
			Ore = parent.Ore,
			Radius = radius,
			Gen = gen,
			T0 = t0,
			Expire = t0 + Asteroids.FragmentLife,
			P0 = parent.Center + dir * parent.Radius * 0.45,
			V0 = dir * range(r, Asteroids.SpreadSpeed[1], Asteroids.SpreadSpeed[2]) + inherit,
			Axis = unitVector(r),
			W = range(r, Asteroids.SpinSpeed[1], Asteroids.SpinSpeed[2]),
		})
	end
	return out
end

---------------------------------------------------------------------
-- Registro (lo escribe el servidor; el cliente lo copia de ReplicatedStorage.AsteroidesEstado)
---------------------------------------------------------------------
local families: { [string]: Family } = {}
local fragById: { [string]: Fragment } = {}
local fragCount = 0

-- La hora común (la del servidor en todos los clientes); las pruebas la cambian
Asteroids.clock = function(): number
	local ok, t = pcall(function()
		return (workspace :: any):GetServerTimeNow()
	end)
	return if ok and type(t) == "number" then t else os.clock()
end

local function reindex()
	table.clear(fragById)
	fragCount = 0
	for _, fam in families do
		for id, f in fam.Frags do
			fragById[id] = f
			fragCount += 1
		end
	end
end

function Asteroids.setFamily(root: string, fam: Family?)
	families[root] = fam
	reindex()
end

function Asteroids.family(root: string): Family?
	return families[root]
end

function Asteroids.families(): { [string]: Family }
	return families
end

function Asteroids.clear()
	table.clear(families)
	reindex()
end

function Asteroids.isGone(root: string): boolean
	return families[root] ~= nil
end

function Asteroids.fragment(id: string): Fragment?
	return fragById[id]
end

function Asteroids.fragmentCount(): number
	return fragCount
end

-- Un asteroide o un trozo como roca (con su centro AHORA), o nil si no existe o está roto
function Asteroids.rockOf(id: string, base: RockLike?, t: number?): RockLike?
	local f = fragById[id]
	if f then
		return { Id = f.Id, Field = f.Field, Center = Asteroids.posAt(f, t or Asteroids.clock()), Radius = f.Radius, Ore = f.Ore, Fragment = true, Root = f.Root }
	end
	if base and not families[base.Id] then
		return base
	end
	return nil
end

-- Los trozos vivos de un campo (con su centro en t)
function Asteroids.liveIn(field: string, t: number?): { RockLike }
	local out = {}
	if fragCount == 0 then
		return out
	end
	local now = t or Asteroids.clock()
	for _, f in fragById do
		if f.Field == field and now < f.Expire then
			table.insert(out, { Id = f.Id, Field = f.Field, Center = Asteroids.posAt(f, now), Radius = f.Radius, Ore = f.Ore, Fragment = true, Root = f.Root })
		end
	end
	return out
end

-- (servidor) Lo que toca hacer a la hora t: trozos caducados y asteroides que vuelven.
-- canRespawn(raíz) -> false si no puede volver aún (una nave justo ahí): se retrasa RespawnRetry s.
-- Devuelve (familias cambiadas, raíces que reaparecen)
Asteroids.RespawnRetry = 10
function Asteroids.sweep(t: number, canRespawn: ((string) -> boolean)?): ({ string }, { string })
	local changed, back = {}, {}
	for root, fam in families do
		if t >= fam.Respawn and canRespawn and not canRespawn(root) then
			fam.Respawn = t + Asteroids.RespawnRetry
			table.insert(changed, root)
		end
		if t >= fam.Respawn then
			table.insert(back, root)
		else
			local any = false
			for id, f in fam.Frags do
				if t >= f.Expire then
					fam.Frags[id] = nil
					any = true
				end
			end
			if any then
				table.insert(changed, root)
			end
		end
	end
	for _, root in back do
		families[root] = nil
	end
	if #changed > 0 or #back > 0 then
		reindex()
	end
	return changed, back
end

---------------------------------------------------------------------
-- Texto para replicar (un atributo por familia: «R=<vuelve>;<trozo>;<trozo>…»)
---------------------------------------------------------------------
local function v3(v: Vector3, fmt: string): string
	return (fmt .. "," .. fmt .. "," .. fmt):format(v.X, v.Y, v.Z)
end

function Asteroids.encode(fam: Family): string
	local parts = { ("R=%.2f|%s"):format(fam.Respawn, fam.Field) }
	local ids = {}
	for id in fam.Frags do
		table.insert(ids, id)
	end
	table.sort(ids)
	for _, id in ids do
		local f = fam.Frags[id]
		table.insert(parts, table.concat({
			f.Id, ("%.2f"):format(f.Radius), f.Ore, tostring(f.Gen), ("%.2f"):format(f.T0), ("%.2f"):format(f.Expire),
			v3(f.P0, "%.1f"), v3(f.V0, "%.2f"), v3(f.Axis, "%.3f"), ("%.3f"):format(f.W),
		}, "|"))
	end
	return table.concat(parts, ";")
end

local function readV3(s: string?): Vector3?
	if not s then
		return nil
	end
	local x, y, z = string.match(s, "^([^,]+),([^,]+),([^,]+)$")
	local nx, ny, nz = tonumber(x), tonumber(y), tonumber(z)
	if nx and ny and nz then
		return Vector3.new(nx, ny, nz)
	end
	return nil
end

function Asteroids.decode(root: string, text: any): Family?
	if type(text) ~= "string" or #text > 20000 then
		return nil
	end
	local chunks = string.split(text, ";")
	local head = chunks[1] or ""
	local respawn, field = string.match(head, "^R=([^|]+)|(.*)$")
	local rt = tonumber(respawn)
	if not rt then
		return nil
	end
	local fam: Family = { Root = root, Field = field or "", Respawn = rt, Frags = {} }
	for i = 2, #chunks do
		local f = string.split(chunks[i], "|")
		local radius, gen, t0, expire, w = tonumber(f[2]), tonumber(f[4]), tonumber(f[5]), tonumber(f[6]), tonumber(f[10])
		local p0, v0, axis = readV3(f[7]), readV3(f[8]), readV3(f[9])
		if f[1] and radius and gen and t0 and expire and w and p0 and v0 and axis then
			fam.Frags[f[1]] = {
				Id = f[1], Root = root, Field = fam.Field, Ore = f[3] or "Hierro", Radius = radius, Gen = gen,
				T0 = t0, Expire = expire, P0 = p0, V0 = v0, Axis = if axis.Magnitude > 1e-3 then axis.Unit else Vector3.new(0, 1, 0), W = w,
			}
		end
	end
	return fam
end

---------------------------------------------------------------------
-- Pedazos de adorno (cliente): cola con tope. add() devuelve los que hay que quitar para hacer sitio.
---------------------------------------------------------------------
export type DebrisPool = { Max: number, List: { any } }
function Asteroids.newPool(max: number?): DebrisPool
	return { Max = max or Asteroids.DebrisMax, List = {} }
end
function Asteroids.poolAdd(pool: DebrisPool, item: any): { any }
	local evicted = {}
	while #pool.List >= pool.Max do
		table.insert(evicted, table.remove(pool.List, 1))
	end
	table.insert(pool.List, item)
	return evicted
end

return Asteroids
