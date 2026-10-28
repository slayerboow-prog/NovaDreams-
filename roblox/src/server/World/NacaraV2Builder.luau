-- NacaraV2Builder (servidor): Nácara v2, la ciudad del mapa del dueño (docs/mar/nacara-v2/diseno.md). Los 16
-- barrios, cada uno en su isla de roca y coral, unidos por tubos de cristal curvos y pasarelas con luz. Los datos
-- (dónde, radio, fase) están en shared/Sea/NacaraV2.
--
-- SOLO si Config.Sea.NacaraV2 = true (APAGADO hasta que el dueño apruebe): lo llama Services/SeaCivService.setup
-- después de NacaraCityBuilder, y entonces construye los barrios de la fase NacaraV2.BuildPhase (la 1: Palacio Real
-- y Plaza Central). Las vistas previas (scripts/map/nacara-export.luau … v2) dibujan los 16 con plan({ All = true }).
--
--   NacaraV2Builder.plan(opts?)   { Parts, Kit, Terrain }: piezas, mallas del kit del mar y rellenos de terreno
--                                 (cuentas puras: las usan las pruebas y la vista previa)
--   NacaraV2Builder.build(terrain) lo construye: un modelo Atomic por barrio en workspace.NacaraCiudad
--
-- Reglas (roblox-building / roblox-lighting / roblox-performance y el bug del barrio negro de la v129): piezas solo
-- de SmoothPlastic, Glass, Neon y Fabric (nada que cambie World/UserMaterials), ancladas, sin sombras y sin choques
-- salvo suelos, muros y bases; el brillo es Neon (gratis) y como mucho NacaraV2.MaxLights luces de verdad por barrio,
-- sin sombras; el coral, las rocas, el kelp y las plantas que brillan son las MALLAS del kit del mar (World/MarMeshes,
-- una pieza cada una) con su respaldo de piezas si no han llegado; nada más alto que Nacara.MaxTop.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Nacara = require(ReplicatedStorage.Shared.Sea.Nacara)
local NacaraV2 = require(ReplicatedStorage.Shared.Sea.NacaraV2)
local Civ = require(ReplicatedStorage.Shared.Sea.Civ)

local NacaraV2Builder = {}

NacaraV2Builder.State = "None"
NacaraV2Builder.Stats = { Parts = 0, Lights = 0, Fills = 0, Kit = 0 }
NacaraV2Builder.Materials = { "SmoothPlastic", "Glass", "Neon", "Fabric" }

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local rad = math.rad
local cos, sin, pi = math.cos, math.sin, math.pi

-- Paleta (noche azul con ventanas cálidas, como el mapa)
local NACRE = rgb(236, 230, 244)
local NACRE_B = rgb(200, 226, 242)
local PEARL = rgb(246, 214, 230)
local CYAN = rgb(110, 236, 255)
local AQUA = rgb(90, 200, 255)
local GOLD = rgb(255, 210, 130)
local WARM = rgb(255, 196, 110)
local VIOLET = rgb(190, 130, 255)
local GLASS = rgb(150, 220, 255)
local CORALS = { { 255, 120, 160 }, { 255, 170, 90 }, { 190, 120, 255 }, { 110, 220, 255 }, { 130, 240, 170 }, { 255, 220, 120 }, { 255, 140, 210 } }
local GLOWS = { { 90, 245, 255 }, { 255, 130, 230 }, { 150, 255, 190 }, { 200, 150, 255 } }
local CORAL_KINDS = { "CoralCuerno", "CoralCerebro", "CoralMesa", "Abanico", "Esponjas", "CoralBlando", "CoralPilar" }

export type Spec = {
	Name: string,
	Shape: string, -- "Block" | "Cylinder" | "Ball" (Ball con tamaños distintos = elipsoide: SpecialMesh)
	Size: Vector3,
	CFrame: CFrame,
	Color: Color3,
	Material: string,
	Transparency: number?,
	Collide: boolean?,
	Light: { Color: Color3, Range: number, Brightness: number }?,
	Sign: { Title: string, Sub: string? }?,
	District: string?,
}

local function hash(a: number, b: number): number
	local n = sin(a * 12.9898 + b * 78.233) * 43758.5453
	return n - math.floor(n)
end

local function upright(at: Vector3): CFrame
	return CF(at) * ANG(0, 0, rad(90))
end

---------------------------------------------------------------------
-- El contexto de un barrio: helpers en coordenadas LOCALES (x al este, z al sur, y sobre la cara de la isla)
---------------------------------------------------------------------
local function context(out: any, d: any)
	local top = Nacara.FloorY + (d.Top or NacaraV2.IslandTop)
	local cx, cz = Nacara.Center.X + d.X, Nacara.Center.Z + d.Z
	local ctx = { D = d, Top = top, CX = cx, CZ = cz, Lights = 0, Seed = 0 }
	function ctx.at(x: number, z: number, y: number?): Vector3
		return V(cx + x, top + (y or 0), cz + z)
	end
	function ctx.add(s: any): any
		s.District = d.Id
		if s.Light then
			if ctx.Lights >= NacaraV2.MaxLights then
				s.Light = nil
			else
				ctx.Lights += 1
			end
		end
		table.insert(out.Parts, s)
		return s
	end
	-- cilindro de pie de y0 a y0 + h
	function ctx.cyl(name: string, x: number, z: number, y0: number, h: number, r: number, color: Color3, material: string?, o: any?)
		o = o or {}
		return ctx.add({ Name = name, Shape = "Cylinder", Size = V(h, r * 2, r * 2), CFrame = upright(ctx.at(x, z, y0 + h / 2)), Color = color, Material = material or "SmoothPlastic", Transparency = o.T, Collide = o.Collide, Light = o.Light })
	end
	function ctx.band(x: number, z: number, y: number, r: number, color: Color3?)
		return ctx.cyl("Franja", x, z, y - 0.3, 0.6, r, color or CYAN, "Neon")
	end
	function ctx.box(name: string, x: number, z: number, y0: number, sx: number, sy: number, sz: number, color: Color3, material: string?, yaw: number?, o: any?)
		o = o or {}
		return ctx.add({ Name = name, Shape = "Block", Size = V(sx, sy, sz), CFrame = CF(ctx.at(x, z, y0 + sy / 2)) * ANG(0, yaw or 0, 0), Color = color, Material = material or "SmoothPlastic", Transparency = o.T, Collide = o.Collide, Light = o.Light, Sign = o.Sign })
	end
	function ctx.ball(name: string, x: number, z: number, y: number, size: Vector3, color: Color3, material: string?, o: any?)
		o = o or {}
		return ctx.add({ Name = name, Shape = "Ball", Size = size, CFrame = CF(ctx.at(x, z, y)), Color = color, Material = material or "SmoothPlastic", Transparency = o.T, Light = o.Light })
	end
	-- cúpula de cristal: media elipse (la otra mitad queda dentro del tambor o de la isla) y su anillo de luz
	function ctx.dome(x: number, z: number, y: number, r: number, h: number, tint: Color3?, ring: Color3?)
		ctx.ball("Cupula", x, z, y, V(r * 2, h * 2, r * 2), tint or GLASS, "Glass", { T = 0.45 })
		ctx.band(x, z, y + 0.3, r + 0.4, ring or CYAN)
	end
	-- ventanas cálidas alrededor de un tambor de radio r
	function ctx.windows(x: number, z: number, y: number, r: number, n: number, w: number?, h: number?, color: Color3?)
		for i = 1, n do
			local a = (i - 0.5) / n * pi * 2
			local p = ctx.at(x + cos(a) * (r + 0.05), z + sin(a) * (r + 0.05), y)
			ctx.add({ Name = "Ventana", Shape = "Block", Size = V(w or 1.6, h or 2.2, 0.3), CFrame = CFrame.lookAt(p, p + V(cos(a), 0, sin(a))), Color = color or WARM, Material = "Neon" })
		end
	end
	-- aguja: tres tramos que se estrechan y una perla de luz
	function ctx.spire(x: number, z: number, y0: number, h: number, r: number, color: Color3?, tip: Color3?, collide: boolean?)
		local y = y0
		for i, s in { { 1, 0.5 }, { 0.7, 0.32 }, { 0.38, 0.18 } } do
			local hh = h * s[2]
			ctx.cyl("Aguja", x, z, y, hh, r * s[1], if i == 2 then (color or PEARL) else NACRE, nil, { Collide = collide and i == 1 })
			y += hh
		end
		ctx.ball("PuntaAguja", x, z, y + 0.4, V(r * 0.9, r * 0.9, r * 0.9) + V(0.8, 0.8, 0.8), tip or CYAN, "Neon")
	end
	-- arco de luz (puerta) mirando hacia fuera del centro
	function ctx.arch(x: number, z: number, y0: number, w: number, h: number, color: Color3?)
		local a = math.atan2(z, x)
		local p = ctx.at(x, z, y0)
		local f = CFrame.lookAt(p, p + V(cos(a), 0, sin(a)))
		for s = -1, 1, 2 do
			ctx.add({ Name = "Jamba", Shape = "Block", Size = V(0.5, h, 0.5), CFrame = f * CF(s * w / 2, h / 2, 0), Color = color or GOLD, Material = "Neon" })
		end
		ctx.add({ Name = "Dintel", Shape = "Block", Size = V(w + 0.5, 0.5, 0.5), CFrame = f * CF(0, h, 0), Color = color or GOLD, Material = "Neon" })
	end
	-- aro vertical (Zona de Entrenamiento) de n tramos
	function ctx.hoop(x: number, z: number, y: number, r: number, yaw: number, color: Color3, n: number)
		local c = CF(ctx.at(x, z, y)) * ANG(0, yaw, 0)
		for i = 1, n do
			local a = (i - 0.5) / n * pi * 2
			ctx.add({ Name = "Aro", Shape = "Block", Size = V(2 * pi * r / n + 0.1, 0.5, 0.5), CFrame = c * CF(cos(a) * r, sin(a) * r, 0) * ANG(0, 0, a + pi / 2), Color = color, Material = "Neon" })
		end
	end
	-- una malla del kit del mar (Kind de shared/Sea/MarKit), y = sobre la isla o, con floor = true, sobre el fondo
	function ctx.kit(kind: string, x: number, z: number, scale: number, color: { number }?, glow: boolean?, y: number?)
		ctx.Seed += 1
		-- (lo que ya existe en Nácara no se tapa: barrios de la fase 1, perlas-farola, carteles, la plaza)
		local px, pz = d.X + x, d.Z + z
		for _, a in out.Avoid do
			if (px - a[1]) ^ 2 + (pz - a[2]) ^ 2 < a[3] * a[3] then
				return
			end
		end
		table.insert(out.Kit, {
			Kind = kind, X = cx + x, Y = top + (y or 0), Z = cz + z, Yaw = hash(ctx.Seed, d.X) * pi * 2, Scale = scale,
			Color = color or CORALS[1 + ctx.Seed % #CORALS], Glow = glow, Sway = kind == "KelpGigante" or kind == "Abanico" or kind == "CoralBlando" or kind == "AnemonaLuz",
			Group = "NacaraV2", Region = d.Id, District = d.Id,
		})
	end
	function ctx.terrain(op: any)
		op.District = d.Id
		table.insert(out.Terrain, op)
	end
	return ctx
end

---------------------------------------------------------------------
-- La isla: basalto con acantilado de peñascos, grano claro arriba, coral al borde, kelp alrededor y luces vivas
---------------------------------------------------------------------
-- ¿Ese ángulo (local, atan2(z, x)) va hacia un enlace? (ahí no se ponen peñascos, coral ni kelp: es la entrada)
local function towardLink(ctx: any, a: number): boolean
	for _, g in ctx.Gaps or {} do
		if math.abs(((a - g + pi) % (2 * pi)) - pi) < rad(9) then
			return true
		end
	end
	return false
end

local function island(ctx: any, opts: any?)
	opts = opts or {}
	local d = ctx.D
	local R = d.R
	local h = (d.Top or NacaraV2.IslandTop)
	if not opts.NoRock then
		ctx.terrain({ Op = "Cylinder", Pos = ctx.at(0, 0, -11), H = 20, R = R, Material = "Basalt" })
		ctx.terrain({ Op = "Cylinder", Pos = ctx.at(0, 0, -1.5), H = 3, R = R - 2, Material = "Salt" })
	end
	-- peñascos del acantilado
	local n = math.floor(R * 2 * pi / 11)
	for i = 1, n do
		local a = (i + hash(i, d.X) * 0.6) / n * pi * 2
		local rr = R + (opts.RimOut or 1) + hash(i, d.Z) * 3
		local br = 4 + hash(i, 7) * 4
		if towardLink(ctx, a) then
			continue
		end
		ctx.terrain({ Op = "Ball", Pos = ctx.at(cos(a) * rr, sin(a) * rr, -h * 0.5 + hash(i, 3) * 4 - (opts.Low or 0)), R = br, Material = if i % 3 == 0 then "Rock" else "Basalt" })
	end
	-- coral al borde (mallas del kit)
	local m = math.floor(R * 2 * pi / (opts.CoralStep or 8))
	for i = 1, m do
		local a = (i + hash(i, d.X + 1) * 0.5) / m * pi * 2
		if towardLink(ctx, a) then
			continue
		end
		local out_ = opts.CoralOut or 0
		local rr = R - 2.5 - hash(i, 11) * 4 + out_
		local kind = CORAL_KINDS[1 + (i + #d.Id) % #CORAL_KINDS]
		ctx.kit(kind, cos(a) * rr, sin(a) * rr, 2.6 + hash(i, 13) * 3.4, nil, false)
		if i % 4 == 0 then
			local gr = if out_ > 0 then rr + 3 else rr - 3
			ctx.kit(if i % 8 == 0 then "SetaLuz" else "AnemonaLuz", cos(a) * gr, sin(a) * gr, 1.6 + hash(i, 17) * 1.2, GLOWS[1 + i % #GLOWS], true)
		end
		if i % 9 == 0 then
			ctx.kit("RocaAguja", cos(a) * (rr + 1), sin(a) * (rr + 1), 6 + hash(i, 19) * 6, nil, false)
		end
	end
	-- kelp gigante en el fondo, alrededor de la isla
	local k = opts.Kelp or math.max(3, math.floor(R / 14))
	for i = 1, k do
		local a = (i + 0.37) / k * pi * 2 + hash(i, d.Z) * 0.5
		if towardLink(ctx, a) then
			continue
		end
		ctx.kit("KelpGigante", cos(a) * (R + 9), sin(a) * (R + 9), 22 + hash(i, 23) * 12, { 70, 150, 90 }, false, -h)
	end
end

---------------------------------------------------------------------
-- Los 16 barrios (silueta del mapa del dueño; ver docs/mar/nacara-v2/diseno.md §3)
---------------------------------------------------------------------
local Districts = {}

-- Palacio Real: el hito. Terraza, tambor con ventanas cálidas, gran cúpula de cristal cian con el corazón de luz,
-- la aguja mayor y cuatro agujas en los hombros de la cúpula, doce agujas alrededor y cuatro puertas de oro.
function Districts.Palacio(c: any)
	local P = NacaraV2.Palace
	island(c, { CoralStep = 6 })
	c.cyl("Terraza", 0, 0, 0, 1.2, P.Terrace.R, NACRE, nil, { Collide = true })
	c.band(0, 0, 0.3, P.Terrace.R + 0.8, CYAN)
	local dr, dh = P.Drum.R, P.Drum.H
	c.cyl("Tambor", 0, 0, 1.2, dh, dr, NACRE_B, nil, { Collide = true })
	c.band(0, 0, 3.6, dr + 0.3, CYAN)
	c.band(0, 0, 1.2 + dh - 0.8, dr + 0.3, GOLD)
	c.windows(0, 0, 6.4, dr, 20, 1.4, 2.6)
	for k = 0, 3 do
		local a = k * pi / 2
		c.arch(cos(a) * (dr + 0.3), sin(a) * (dr + 0.3), 1.2, 5, 7.5, GOLD)
	end
	local domeY = 1.2 + dh
	c.dome(0, 0, domeY, P.Dome.R, P.Dome.H, GLASS, GOLD)
	-- costillas de luz de la cúpula (8 meridianos hechos de tramos)
	for k = 1, 8 do
		local a = k / 8 * pi * 2
		for s = 1, 4 do
			local t0, t1 = (s - 1) / 4 * (pi / 2), s / 4 * (pi / 2)
			local p0 = c.at(cos(a) * P.Dome.R * cos(t0), sin(a) * P.Dome.R * cos(t0), domeY + P.Dome.H * sin(t0))
			local p1 = c.at(cos(a) * P.Dome.R * cos(t1), sin(a) * P.Dome.R * cos(t1), domeY + P.Dome.H * sin(t1))
			c.add({ Name = "Costilla", Shape = "Block", Size = V(0.35, 0.35, (p1 - p0).Magnitude + 0.3), CFrame = CFrame.lookAt((p0 + p1) / 2, p1), Color = CYAN, Material = "Neon", Transparency = 0.2 })
		end
	end
	c.cyl("ColumnaLuz", 0, 0, 1.2, P.Dome.H + dh - 4, 2.2, CYAN, "Neon", { T = 0.1 })
	c.ball("PerlaCorazon", 0, 0, domeY + 5, V(7, 7, 7), rgb(220, 250, 255), "Neon", { Light = { Color = CYAN, Range = 60, Brightness = 1.6 } })
	-- la aguja mayor (hasta Crown sobre el suelo de la plaza) y cuatro en los hombros
	local crownLocal = Nacara.FloorY + P.Crown - c.Top
	local base = domeY + P.Dome.H - 2
	c.spire(0, 0, base, crownLocal - base - 1, 3, PEARL, GOLD)
	for k = 0, 3 do
		local a = k * pi / 2 + pi / 4
		local r = P.Dome.R * 0.62
		c.spire(cos(a) * r, sin(a) * r, domeY + P.Dome.H * 0.72, 30, 1.8, NACRE_B, CYAN)
	end
	for k = 1, P.Spires.Count do
		local a = (k - 0.5) / P.Spires.Count * pi * 2
		c.spire(cos(a) * P.Spires.Ring, sin(a) * P.Spires.Ring, 1.2, if k % 2 == 0 then P.Spires.High else P.Spires.Low, 2.2, if k % 2 == 0 then PEARL else NACRE_B, if k % 2 == 0 then GOLD else CYAN, true)
	end
	c.box("Cartel", 0, P.Terrace.R - 3, 1.2, 10, 3, 0.3, rgb(18, 34, 62), nil, pi, { Collide = true, Sign = { Title = "PALACIO REAL", Sub = "Sala del Consejo al oeste" } })
	c.box("MarcoCartel", 0, P.Terrace.R - 3, 4.2, 10.6, 0.3, 0.4, GOLD, "Neon", pi)
end

-- Plaza Central: la plaza de la fase 0 (no se toca): anillo de peñascos alrededor, borde de luz y cuatro obeliscos
function Districts.Plaza(c: any)
	island(c, { NoRock = true, RimOut = 6, Low = -6, CoralStep = 9, CoralOut = 9 })
	local rim = NacaraV2.PlazaRim
	for k = 0, 39 do
		local deg = k * 9 + 4.5
		local gap = false
		for _, g in rim.Gaps do
			if math.abs(((deg - g + 180) % 360) - 180) < 12 then
				gap = true
			end
		end
		if not gap then
			local a = rad(deg)
			local p = c.at(sin(a) * rim.R, -cos(a) * rim.R, 0.2)
			c.add({ Name = "BordePlaza", Shape = "Block", Size = V(8.8, 0.4, 0.8), CFrame = CF(p) * ANG(0, -a, 0), Color = CYAN, Material = "Neon", Transparency = 0.2 })
		end
	end
	for _, g in rim.Gaps do
		local a = rad(g)
		for s = -1, 1, 2 do
			local b = a + s * rad(14)
			c.spire(sin(b) * (rim.R + 1), -cos(b) * (rim.R + 1), 0, 14, 1.2, NACRE_B, CYAN)
		end
	end
	c.box("Cartel", 22, -56, 6, 9, 3, 0.3, rgb(18, 34, 62), nil, pi, { Collide = true, Sign = { Title = "PLAZA CENTRAL", Sub = "Nácara · la fuente de luz" } })
	c.box("MarcoCartel", 22, -56, 9, 9.6, 0.3, 0.4, GOLD, "Neon", pi)
	c.cyl("PosteCartel", 22, -56, 0, 6, 0.25, NACRE)
end

-- Una concha-casa: tambor, tapa de cristal, puerta de luz y dos ventanas
local function shellHouse(c: any, x: number, z: number, r: number, h: number, tint: Color3)
	c.cyl("Casa", x, z, 0, h, r, NACRE_B, nil, { Collide = true })
	c.dome(x, z, h, r + 0.2, r * 0.8, tint, GOLD)
	local a = math.atan2(-z, -x)
	c.arch(x + cos(a) * (r + 0.1), z + sin(a) * (r + 0.1), 0, 2.4, 3.6, GOLD)
	c.windows(x, z, h * 0.6, r, 3, 1.1, 1.4)
end

-- Residencias de Sirenas: conchas en arco con su cúpula, dos torres de pisos de coral con balcones y luz cálida
function Districts.Residencias(c: any)
	island(c)
	for i = 1, 8 do
		local a = (i - 1) / 8 * pi * 1.6 + pi * 0.7
		shellHouse(c, cos(a) * 34, sin(a) * 34, 5.5, 5, if i % 2 == 0 then rgb(170, 220, 255) else rgb(220, 180, 255))
	end
	for i, t in { { -8, -6, 34, PEARL }, { 12, 8, 28, NACRE_B } } do
		local x, z, h, col = t[1], t[2], t[3], t[4]
		c.cyl("TorrePisos", x, z, 0, h, 5, col, nil, { Collide = true })
		for f = 1, math.floor(h / 6) do
			c.cyl("Balcon", x, z, f * 6 - 0.4, 0.4, 6.4, NACRE)
			c.windows(x, z, f * 6 - 2.6, 5, 6, 1.2, 1.8)
		end
		c.dome(x, z, h, 5.4, 4, GLASS, CYAN)
		c.spire(x, z, h + 3, 9, 1.2, PEARL, if i == 1 then GOLD else CYAN)
	end
	c.ball("PerlaFarola", 0, 18, 7, V(2.4, 2.4, 2.4), WARM, "Neon", { Light = { Color = WARM, Range = 30, Brightness = 1.2 } })
	c.cyl("PosteFarola", 0, 18, 0, 6, 0.35, NACRE)
end

-- Universidad Marina: gran sala redonda con columnata, cúpula de cristal, campanario y dos alas con cúpula
function Districts.Universidad(c: any)
	island(c)
	c.cyl("Escalinata", 0, 0, 0, 1.2, 32, NACRE, nil, { Collide = true })
	c.cyl("Sala", 0, 0, 1.2, 12, 23, NACRE_B, nil, { Collide = true })
	c.windows(0, 0, 7, 23, 18, 1.4, 3.2)
	c.band(0, 0, 13.2, 23.4, GOLD)
	for i = 1, 16 do
		local a = i / 16 * pi * 2
		c.cyl("Columna", cos(a) * 28, sin(a) * 28, 1.2, 11, 0.8, NACRE)
	end
	c.cyl("Cornisa", 0, 0, 12.2, 1, 29, NACRE)
	c.dome(0, 0, 13.2, 21, 16, GLASS, CYAN)
	c.cyl("Linterna", 0, 0, 27, 6, 3, NACRE_B)
	c.windows(0, 0, 30, 3, 6, 0.8, 2.2, CYAN)
	c.spire(0, 0, 33, 14, 1.6, PEARL, GOLD)
	for s = -1, 1, 2 do
		c.cyl("Ala", s * 40, 6, 0, 7, 9, NACRE, nil, { Collide = true })
		c.windows(s * 40, 6, 3.5, 9, 8)
		c.dome(s * 40, 6, 7, 8.6, 7, rgb(170, 210, 255), CYAN)
	end
	c.arch(0, 32.5, 1.2, 6, 9, GOLD)
	c.ball("Faro", 0, 0, 22, V(4, 4, 4), CYAN, "Neon", { Light = { Color = CYAN, Range = 46, Brightness = 1.3 } })
end

-- Hospital Marino: pabellón blanco con cúpula verde agua, torre con el signo de la concha verde (no la cruz roja)
function Districts.Hospital(c: any)
	island(c)
	local WHITE = rgb(244, 248, 250)
	c.cyl("Pabellon", 0, 0, 0, 13, 17, WHITE, nil, { Collide = true })
	c.windows(0, 0, 4, 17, 14, 1.6, 2)
	c.windows(0, 0, 9, 17, 14, 1.6, 2)
	c.band(0, 0, 12.8, 17.3, rgb(120, 255, 210))
	c.dome(0, 0, 13, 16, 10, rgb(160, 245, 225), rgb(120, 255, 210))
	c.cyl("Torre", 20, -8, 0, 27, 6, WHITE, nil, { Collide = true })
	for f = 1, 4 do
		c.windows(20, -8, f * 6, 6, 6, 1.2, 1.8)
	end
	c.dome(20, -8, 27, 6.2, 4, GLASS, CYAN)
	-- el signo: concha verde de luz en la cara de la torre (mirando al sur)
	c.ball("SignoConcha", 20, -1.6, 22, V(5, 5, 0.6), rgb(90, 240, 180), "Neon", { Light = { Color = rgb(120, 255, 210), Range = 34, Brightness = 1.1 } })
	c.box("SignoBarra", 20, -1.2, 21.2, 0.8, 1.8, 0.4, WHITE, "Neon")
	c.box("SignoBarra", 20, -1.2, 21.9, 1.8, 0.8, 0.4, WHITE, "Neon")
	c.arch(0, 17.2, 0, 5, 6, rgb(120, 255, 210))
end

-- Mercado Submarino: anillo de puestos con toldos de colores y farolillos, nave de cristal en medio, guirnaldas
function Districts.Mercado(c: any)
	island(c)
	for i = 1, 14 do
		local a = i / 14 * pi * 2
		local r = 30 + (i % 2) * 6
		local x, z = cos(a) * r, sin(a) * r
		local col = CORALS[1 + i % #CORALS]
		c.box("Puesto", x, z, 0, 5, 3, 4, NACRE, nil, -a, { Collide = true })
		c.box("Toldo", x, z, 4.4, 6.4, 0.5, 5.4, rgb(col[1], col[2], col[3]), "Fabric", -a)
		for s = -1, 1, 2 do
			c.cyl("Palo", x + cos(a + pi / 2) * s * 2.8, z + sin(a + pi / 2) * s * 2.8, 0, 4.4, 0.2, NACRE)
		end
		c.ball("Farolillo", x, z, 3.6, V(1.1, 1.3, 1.1), WARM, "Neon")
	end
	c.cyl("Nave", 0, 0, 0, 5, 13, NACRE_B, nil, { Collide = true })
	c.windows(0, 0, 2.6, 13, 10, 2, 2.4)
	c.dome(0, 0, 5, 13.5, 11, rgb(255, 210, 160), GOLD)
	-- guirnaldas de farolillos de la nave a los puestos
	for g = 1, 6 do
		local a = g / 6 * pi * 2 + 0.2
		local p0, p1 = V(cos(a) * 14, 12, sin(a) * 14), V(cos(a) * 30, 5, sin(a) * 30)
		for k = 1, 5 do
			local t = k / 6
			local p = p0:Lerp(p1, t) - V(0, sin(t * pi) * 2, 0)
			c.ball("Farolillo", p.X, p.Z, p.Y, V(0.8, 0.9, 0.8), if k % 2 == 0 then rgb(255, 140, 120) else WARM, "Neon")
		end
	end
	c.ball("Lampara", 0, 0, 17, V(3, 3, 3), WARM, "Neon", { Light = { Color = WARM, Range = 44, Brightness = 1.3 } })
end

-- Comercios y Tiendas: galería redonda rosa con escaparates de luz, cúpula violeta y quioscos
function Districts.Comercios(c: any)
	island(c)
	c.cyl("Galeria", 0, 0, 0, 10, 20, PEARL, nil, { Collide = true })
	for i = 1, 10 do
		local a = (i - 0.5) / 10 * pi * 2
		local p = c.at(cos(a) * 20.1, sin(a) * 20.1, 3)
		local col = CORALS[1 + i % #CORALS]
		c.add({ Name = "Escaparate", Shape = "Block", Size = V(5, 4.4, 0.3), CFrame = CFrame.lookAt(p, p + V(cos(a), 0, sin(a))), Color = WARM, Material = "Neon", Transparency = 0.15 })
		local q = c.at(cos(a) * 20.2, sin(a) * 20.2, 7.2)
		c.add({ Name = "Letrero", Shape = "Block", Size = V(4.4, 1, 0.3), CFrame = CFrame.lookAt(q, q + V(cos(a), 0, sin(a))), Color = rgb(col[1], col[2], col[3]), Material = "Neon" })
	end
	c.band(0, 0, 9.8, 20.4, rgb(255, 160, 230))
	c.dome(0, 0, 10, 18, 13, rgb(210, 160, 255), rgb(255, 160, 230))
	c.spire(0, 0, 22, 10, 1.4, PEARL, rgb(255, 160, 230))
	for i = 1, 5 do
		local a = i / 5 * pi * 2 + 0.3
		c.cyl("Quiosco", cos(a) * 33, sin(a) * 33, 0, 4, 3.4, NACRE_B, nil, { Collide = true })
		c.dome(cos(a) * 33, sin(a) * 33, 4, 3.6, 3, rgb(255, 200, 230), WARM)
	end
	c.ball("Lampara", 0, 0, 14, V(3, 3, 3), rgb(255, 180, 240), "Neon", { Light = { Color = rgb(255, 170, 230), Range = 40, Brightness = 1.2 } })
end

-- Biblioteca de las Profundidades: tres pisos escalonados con franjas de oro y ventanas, cúpula y torres-estante
function Districts.Biblioteca(c: any)
	island(c)
	local y = 0
	for i, t in { { 24, 8 }, { 18, 7 }, { 12, 6 } } do
		c.cyl("Piso", 0, 0, y, t[2], t[1], if i % 2 == 1 then NACRE_B else NACRE, nil, { Collide = true })
		c.windows(0, 0, y + t[2] * 0.5, t[1], 10 + (3 - i) * 6, 1.2, t[2] * 0.5)
		c.band(0, 0, y + t[2] - 0.2, t[1] + 0.3, GOLD)
		y += t[2]
	end
	c.dome(0, 0, y, 11, 8, rgb(160, 210, 255), GOLD)
	c.spire(0, 0, y + 7, 9, 1.2, PEARL, GOLD)
	for i = 1, 6 do
		local a = i / 6 * pi * 2
		c.box("Estante", cos(a) * 33, sin(a) * 33, 0, 3, 9, 3, NACRE, nil, -a)
		c.box("Libros", cos(a) * 33, sin(a) * 33, 3, 3.2, 3, 3.2, if i % 2 == 0 then WARM else CYAN, "Neon", -a)
	end
	c.arch(0, 24.2, 0, 5, 6.5, GOLD)
	c.ball("Lampara", 0, 0, y + 3, V(3, 3, 3), WARM, "Neon", { Light = { Color = WARM, Range = 40, Brightness = 1.2 } })
end

-- Cueva de las Perlas: una cueva de roca (terreno) con la boca al este, almeja gigante con la perla que brilla,
-- cristales violeta y anémonas de luz
function Districts.Cueva(c: any)
	island(c)
	c.terrain({ Op = "Ball", Pos = c.at(-4, 0, 8), R = 22, Material = "Basalt" })
	c.terrain({ Op = "Ball", Pos = c.at(-4, 0, 12), R = 12, Material = "Water" })
	c.terrain({ Op = "Block", Pos = c.at(16, 0, 6), Size = V(18, 12, 14), Material = "Water" })
	c.kit("AlmejaGigante", -6, 0, 6, nil, false)
	c.ball("Perla", -6, 0, 5, V(3.4, 3.4, 3.4), rgb(240, 225, 255), "Neon", { Light = { Color = VIOLET, Range = 36, Brightness = 1.5 } })
	for i = 1, 10 do
		local a = i / 10 * pi * 2
		local r = 6 + (i % 3) * 2
		local h = 3 + (i % 4) * 1.6
		c.add({ Name = "Cristal", Shape = "Cylinder", Size = V(h, 1, 1), CFrame = CF(c.at(-4 + cos(a) * r, sin(a) * r, h / 2)) * ANG(rad(12 * (i % 3 - 1)), a, rad(90 + 10 * (i % 2))), Color = VIOLET, Material = "Neon", Transparency = 0.15 })
	end
	for i = 1, 8 do
		c.kit("AnemonaLuz", 18 + (i % 3) * 3, -8 + i * 2, 1.8, GLOWS[1 + i % #GLOWS], true)
	end
	c.arch(22, 0, 0, 10, 10, VIOLET)
	c.ball("Farol", 28, 0, 9, V(2, 2, 2), WARM, "Neon")
end

-- Templo de los Sirenos: nave alta con tejado en aguja escalonada, seis agujas de oro, rosetón y puerta ojival
function Districts.Templo(c: any)
	island(c)
	c.cyl("Escalinata", 0, 0, 0, 1.4, 30, NACRE, nil, { Collide = true })
	c.cyl("Nave", 0, 0, 1.4, 20, 14, NACRE_B, nil, { Collide = true })
	c.windows(0, 0, 10, 14, 12, 1.2, 7, WARM)
	local y, r = 21.4, 14.6
	for i = 1, 4 do
		c.cyl("Tejado", 0, 0, y, 4, r, if i % 2 == 0 then PEARL else NACRE)
		c.band(0, 0, y + 0.2, r + 0.2, GOLD)
		y += 4
		r *= 0.68
	end
	c.spire(0, 0, y, 14, 1.6, GOLD, GOLD)
	for i = 1, 6 do
		local a = i / 6 * pi * 2 + pi / 6
		c.spire(cos(a) * 22, sin(a) * 22, 1.4, 30 + (i % 2) * 8, 2, PEARL, GOLD, true)
	end
	-- fachada: puerta ojival y rosetón (mirando al oeste, hacia la ciudad)
	c.arch(-14.2, 0, 1.4, 6, 12, GOLD)
	local p = c.at(-14.4, 0, 16)
	c.add({ Name = "Roseton", Shape = "Cylinder", Size = V(0.4, 6, 6), CFrame = CF(p), Color = GOLD, Material = "Neon" })
	c.ball("Lampara", 0, 0, 14, V(3, 3, 3), GOLD, "Neon", { Light = { Color = GOLD, Range = 42, Brightness = 1.3 } })
end

-- Santuario del Océano: anillo de columnas con perlas, estanque de luz, columna de luz con tres puntas y dos lunas
function Districts.Santuario(c: any)
	island(c)
	c.cyl("Anillo", 0, 0, 0, 1.4, 26, NACRE, nil, { Collide = true })
	c.cyl("Estanque", 0, 0, 1.2, 0.4, 14, rgb(60, 200, 255), "Neon", { T = 0.35 })
	for i = 1, 10 do
		local a = i / 10 * pi * 2
		c.cyl("Columna", cos(a) * 22, sin(a) * 22, 1.4, 15, 1.1, NACRE_B, nil, { Collide = true })
		c.ball("PerlaColumna", cos(a) * 22, sin(a) * 22, 17.4, V(2, 2, 2), CYAN, "Neon")
	end
	c.cyl("ColumnaLuz", 0, 0, 1.4, 26, 1.6, CYAN, "Neon", { Light = { Color = CYAN, Range = 50, Brightness = 1.5 } })
	for s = -1, 1 do
		local x = s * 3.6
		c.cyl("Punta", x, 0, 27.4 - math.abs(s) * 2, 7 - math.abs(s) * 2, 0.6, CYAN, "Neon")
	end
	c.box("Travesano", 0, 0, 26.6, 8, 0.6, 0.6, CYAN, "Neon")
	-- las dos lunas (arcos de tramos) a los lados
	for s = -1, 1, 2 do
		for k = 0, 8 do
			local t0, t1 = k / 9 * pi, (k + 1) / 9 * pi
			local p0 = c.at(s * 14, 0 + cos(t0) * 12, 2 + sin(t0) * 16)
			local p1 = c.at(s * 14, 0 + cos(t1) * 12, 2 + sin(t1) * 16)
			c.add({ Name = "Luna", Shape = "Block", Size = V(1.2, 1.2, (p1 - p0).Magnitude + 0.4), CFrame = CFrame.lookAt((p0 + p1) / 2, p1), Color = if k % 2 == 0 then NACRE_B else PEARL, Material = "SmoothPlastic" })
		end
		c.ball("PuntaLuna", s * 14, 12, 2, V(1.6, 1.6, 1.6), CYAN, "Neon")
	end
end

-- Torre de Observación: base redonda, fuste alto con una rampa de luz en espiral, mirador de cristal y una cúpula
function Districts.Torre(c: any)
	island(c, { CoralStep = 5.5 })
	c.cyl("Base", 0, 0, 0, 6, 12, NACRE, nil, { Collide = true })
	c.windows(0, 0, 3, 12, 10, 1.6, 2.4)
	c.cyl("Fuste", 0, 0, 6, 34, 4.6, NACRE_B, nil, { Collide = true })
	for k = 1, 24 do
		local a = k / 7 * pi
		local y = 6 + k * 1.4
		c.box("Rampa", cos(a) * 5.4, sin(a) * 5.4, y, 2.6, 0.3, 0.6, CYAN, "Neon", -a + pi / 2)
	end
	c.cyl("Mirador", 0, 0, 40, 2, 9, NACRE, nil, { Collide = true })
	c.band(0, 0, 42, 9.3, CYAN)
	c.dome(0, 0, 42, 8.6, 7, GLASS, CYAN)
	c.spire(0, 0, 48.5, 3, 0.8, PEARL, CYAN)
	c.ball("Fanal", 0, 0, 45, V(3, 3, 3), rgb(220, 250, 255), "Neon", { Light = { Color = CYAN, Range = 50, Brightness = 1.3 } })
	c.cyl("Anexo", 20, 6, 0, 4, 9, NACRE_B, nil, { Collide = true })
	c.windows(20, 6, 2.2, 9, 8, 1.4, 1.8)
	c.dome(20, 6, 4, 9.4, 8, GLASS, CYAN)
end

-- Zona de Entrenamiento: tres estanques redondos con borde de luz, aros para nadar y gradas
function Districts.Entrenamiento(c: any)
	island(c)
	for i, t in { { 0, 0, 17 }, { 28, 16, 10 }, { -26, 18, 9 } } do
		c.cyl("Estanque", t[1], t[2], 0, 1.4, t[3], NACRE, nil, { Collide = true })
		c.cyl("Agua", t[1], t[2], 1.2, 0.3, t[3] - 1.2, rgb(60, 170, 230), "Glass", { T = 0.3 })
		c.band(t[1], t[2], 1.5, t[3] + 0.2, if i == 1 then CYAN else GOLD)
	end
	for i = 1, 4 do
		local a = i / 4 * pi * 2 + 0.4
		c.hoop(cos(a) * 9, sin(a) * 9, 7, 3.2, a, if i % 2 == 0 then CYAN else GOLD, 10)
	end
	for s = 0, 2 do
		c.box("Grada", 0, -27 - s * 2.4, s * 1.4, 26, 1.4, 2.4, NACRE_B, nil, 0, { Collide = true })
	end
	for i = 1, 5 do
		c.cyl("Poste", -16 + i * 6, -22, 0, 7, 0.4, NACRE)
		c.ball("Diana", -16 + i * 6, -22, 7.6, V(1.6, 1.6, 1.6), if i % 2 == 0 then CYAN else GOLD, "Neon")
	end
	c.ball("Lampara", 0, 0, 14, V(2.6, 2.6, 2.6), CYAN, "Neon", { Light = { Color = CYAN, Range = 42, Brightness = 1.2 } })
end

-- Acuario Gigante: la cúpula de cristal más grande de la ciudad sobre un zócalo con ventanas, coral dentro
function Districts.Acuario(c: any)
	island(c)
	c.cyl("Zocalo", 0, 0, 0, 3, 44, NACRE, nil, { Collide = true })
	c.windows(0, 0, 1.6, 44, 26, 2, 1.6, CYAN)
	c.dome(0, 0, 3, 42, 30, rgb(140, 215, 255), CYAN)
	for i = 1, 6 do
		local a = i / 6 * pi * 2
		local p0 = c.at(cos(a) * 42, sin(a) * 42, 3)
		for s = 1, 4 do
			local t0, t1 = (s - 1) / 4 * (pi / 2), s / 4 * (pi / 2)
			local q0 = c.at(cos(a) * 42 * cos(t0), sin(a) * 42 * cos(t0), 3 + 30 * sin(t0))
			local q1 = c.at(cos(a) * 42 * cos(t1), sin(a) * 42 * cos(t1), 3 + 30 * sin(t1))
			c.add({ Name = "Costilla", Shape = "Block", Size = V(0.4, 0.4, (q1 - q0).Magnitude + 0.3), CFrame = CFrame.lookAt((q0 + q1) / 2, q1), Color = CYAN, Material = "Neon", Transparency = 0.3 })
		end
		local _ = p0
	end
	for i = 1, 18 do
		local a = i / 18 * pi * 2
		local r = 10 + (i % 3) * 9
		c.kit(CORAL_KINDS[1 + i % #CORAL_KINDS], cos(a) * r, sin(a) * r, 3 + (i % 3), nil, false, 3)
	end
	c.kit("KelpGigante", 4, -6, 24, { 70, 160, 100 }, false, 3)
	c.arch(0, 43.5, 0, 8, 8, CYAN)
	c.ball("Lampara", 0, 0, 22, V(3, 3, 3), CYAN, "Neon", { Light = { Color = CYAN, Range = 56, Brightness = 1.4 } })
end

-- Puerto de Sirenas: muelles con luces de borde, dos submarinos con ventanas de luz y la capitanía con cúpula
function Districts.Puerto(c: any)
	island(c)
	for i = 0, 3 do
		local x = -21 + i * 13
		c.box("Muelle", x, 10, 0, 3.4, 1.2, 40, NACRE_B, nil, 0, { Collide = true })
		for k = 0, 4 do
			c.ball("LuzMuelle", x + 1.9, -8 + k * 9, 1.6, V(0.6, 0.6, 0.6), if k % 2 == 0 then WARM else CYAN, "Neon")
		end
	end
	for n, dx in { -14.5, 11.5 } do
		local col = if n == 1 then rgb(255, 196, 90) else rgb(120, 200, 255)
		c.ball("Casco", dx, 12, 6, V(7, 7, 24), col, "SmoothPlastic")
		c.cyl("Torreta", dx, 8, 9, 4, 2, col)
		c.ball("Helice", dx, 24.5, 6, V(4, 4, 0.6), NACRE, "SmoothPlastic")
		for k = -1, 1 do
			c.ball("Ojo", dx + 3.4, 12 + k * 5, 6.4, V(1.2, 1.2, 1.2), WARM, "Neon")
			c.ball("Ojo", dx - 3.4, 12 + k * 5, 6.4, V(1.2, 1.2, 1.2), WARM, "Neon")
		end
	end
	c.cyl("Capitania", 20, -24, 0, 9, 9, NACRE, nil, { Collide = true })
	c.windows(20, -24, 5, 9, 10, 1.4, 2)
	c.dome(20, -24, 9, 9.4, 6, GLASS, CYAN)
	c.spire(20, -24, 14, 10, 1, PEARL, GOLD)
	c.ball("Fanal", 20, -24, 25.6, V(2.4, 2.4, 2.4), WARM, "Neon", { Light = { Color = WARM, Range = 46, Brightness = 1.3 } })
end

-- Jardines de Coral: el más vivo: tres terrazas de coral denso, invernadero de cristal y sendas de luz
function Districts.Jardines(c: any)
	island(c, { CoralStep = 6 })
	for t = 1, 3 do
		c.cyl("Terraza", 0, 0, (t - 1) * 1.2, 1.2, 40 - t * 9, NACRE_B, nil, { Collide = true })
		c.band(0, 0, t * 1.2, 40 - t * 9 + 0.2, rgb(150, 255, 200))
	end
	for i = 1, 42 do
		local a = hash(i, 31) * pi * 2
		local r = 6 + hash(i, 37) * 40
		local y = if r < 13 then 3.6 elseif r < 22 then 2.4 elseif r < 31 then 1.2 else 0
		local kind = if i % 7 == 0 then "SetaLuz" elseif i % 5 == 0 then "AnemonaLuz" else CORAL_KINDS[1 + i % #CORAL_KINDS]
		local glow = kind == "SetaLuz" or kind == "AnemonaLuz"
		c.kit(kind, cos(a) * r, sin(a) * r, if glow then 2 else 2.4 + hash(i, 41) * 3.6, if glow then GLOWS[1 + i % #GLOWS] else nil, glow, y)
	end
	c.cyl("Invernadero", 0, 0, 3.6, 3, 7, NACRE)
	c.dome(0, 0, 6.6, 7.4, 6, rgb(150, 245, 200), rgb(150, 255, 200))
	for i = 1, 4 do
		local a = i / 4 * pi * 2
		c.box("Senda", cos(a) * 30, sin(a) * 30, 0.1, 20, 0.2, 1, rgb(150, 255, 200), "Neon", -a)
	end
	c.ball("Lampara", 0, 0, 10, V(2.4, 2.4, 2.4), rgb(170, 255, 210), "Neon", { Light = { Color = rgb(150, 255, 200), Range = 44, Brightness = 1.2 } })
end

---------------------------------------------------------------------
-- Enlaces: tubos de cristal CURVOS (arquean hacia arriba) y pasarelas con barandilla de luz
---------------------------------------------------------------------
local function linkParts(out: any, a: any, b: any, kind: string)
	local ya = Nacara.FloorY + (if a.Id == "Plaza" then 0 else NacaraV2.IslandTop)
	local yb = Nacara.FloorY + (if b.Id == "Plaza" then 0 else NacaraV2.IslandTop)
	local A = V(Nacara.Center.X + a.X, ya, Nacara.Center.Z + a.Z)
	local B = V(Nacara.Center.X + b.X, yb, Nacara.Center.Z + b.Z)
	local flat = (B - A) * V(1, 0, 1)
	local u = flat.Unit
	local side = V(-u.Z, 0, u.X)
	local p0 = A + u * (a.R - 3)
	local p1 = B - u * (b.R - 3)
	-- curva: se levanta en medio y se tuerce un poco de lado (como en el mapa)
	local lift = if kind == "Tube" then 12 else 3
	local bend = side * ((p1 - p0).Magnitude * 0.12) * (if (a.X + b.Z) % 2 == 0 then 1 else -1)
	local mid = (p0 + p1) / 2 + V(0, lift, 0) + bend
	local n = if kind == "Tube" then 10 else 8
	local function at(t: number): Vector3
		return p0 * (1 - t) ^ 2 + mid * 2 * (1 - t) * t + p1 * t * t
	end
	local id = a.Id .. "-" .. b.Id
	for i = 1, n do
		local q0, q1 = at((i - 1) / n), at(i / n)
		local len = (q1 - q0).Magnitude + 0.25
		local f = CFrame.lookAt((q0 + q1) / 2, q1)
		table.insert(out.Parts, { Name = "SueloEnlace", Shape = "Block", Size = V(if kind == "Tube" then 5 else 6, 0.6, len), CFrame = f, Color = NACRE, Material = "SmoothPlastic", Collide = true, District = id })
		if kind == "Tube" then
			table.insert(out.Parts, { Name = "Tubo", Shape = "Cylinder", Size = V(len, 11, 11), CFrame = f * CF(0, 4.6, 0) * ANG(0, rad(90), 0), Color = GLASS, Material = "Glass", Transparency = 0.7, District = id })
			table.insert(out.Parts, { Name = "FranjaTubo", Shape = "Block", Size = V(0.35, 0.35, len), CFrame = f * CF(0, 10, 0), Color = CYAN, Material = "Neon", District = id })
		else
			for s = -1, 1, 2 do
				table.insert(out.Parts, { Name = "Barandilla", Shape = "Block", Size = V(0.3, 0.3, len), CFrame = f * CF(s * 3, 1.4, 0), Color = if s == 1 then CYAN else GOLD, Material = "Neon", District = id })
			end
		end
	end
end

---------------------------------------------------------------------

-- ¿Se construye este barrio? (opts.All: todos, para las vistas previas)
local function wanted(d: any, opts: any): boolean
	if opts.Only then
		return table.find(opts.Only, d.Id) ~= nil
	end
	return opts.All == true or (d.Phase or 99) <= NacaraV2.BuildPhase
end

function NacaraV2Builder.plan(opts: any?): { Parts: { Spec }, Kit: { any }, Terrain: { any } }
	opts = opts or {}
	local out = { Parts = {}, Kit = {}, Terrain = {}, Avoid = {} }
	if not opts.All then
		for _, a in Civ.Areas do
			if a.Id ~= "Plaza" and a.Id ~= "Palacio" then
				table.insert(out.Avoid, { a.X, a.Z, a.R + 5 })
			end
		end
		for _, l in Civ.Lamps do
			table.insert(out.Avoid, { l.X, l.Z, 5 })
		end
		for _, sg in Nacara.Signs do
			table.insert(out.Avoid, { sg.X, sg.Z, 5 })
		end
		for _, item in Nacara.Layout do
			table.insert(out.Avoid, { item.X, item.Z, item.R + 3 })
		end
	end
	for _, d in NacaraV2.Districts do
		if wanted(d, opts) and Districts[d.Id] then
			local ctx = context(out, if d.Id == "Plaza" then setmetatable({ Top = 0 }, { __index = d }) else d)
			ctx.Gaps = {}
			for _, l in NacaraV2.Links do
				local other = if l[1] == d.Id then NacaraV2.ById[l[2]] elseif l[2] == d.Id then NacaraV2.ById[l[1]] else nil
				if other then
					table.insert(ctx.Gaps, math.atan2(other.Z - d.Z, other.X - d.X))
				end
			end
			Districts[d.Id](ctx)
		end
	end
	for _, l in NacaraV2.Links do
		local a, b = NacaraV2.ById[l[1]], NacaraV2.ById[l[2]]
		if wanted(a, opts) and wanted(b, opts) then
			linkParts(out, a, b, l.Kind)
		end
	end
	return out
end

---------------------------------------------------------------------

local function folder(): Instance
	local f = workspace:FindFirstChild("NacaraCiudad")
	if not f then
		f = Instance.new("Folder")
		f.Name = "NacaraCiudad"
		f.Parent = workspace
	end
	return f :: Instance
end

local function label(board: BasePart, title: string, sub: string?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, if sub then 0.58 else 1)
	t.BackgroundTransparency = 1
	t.Text = title
	t.TextScaled = true
	t.Font = Enum.Font.GothamBold
	t.TextColor3 = rgb(255, 240, 200)
	t.Parent = gui
	if sub then
		local s = Instance.new("TextLabel")
		s.Position = UDim2.fromScale(0.04, 0.6)
		s.Size = UDim2.fromScale(0.92, 0.34)
		s.BackgroundTransparency = 1
		s.Text = sub
		s.TextScaled = true
		s.Font = Enum.Font.Gotham
		s.TextColor3 = rgb(150, 230, 245)
		s.Parent = gui
	end
	gui.Parent = board
end

local function make(parent: Instance, s: Spec): BasePart
	local p = Instance.new("Part")
	p.Name = s.Name
	p.Anchored = true
	p.Size = s.Size
	p.CFrame = s.CFrame
	p.Color = s.Color
	p.Material = (Enum.Material :: any)[s.Material]
	if s.Shape == "Ball" and (math.abs(s.Size.X - s.Size.Y) > 0.01 or math.abs(s.Size.X - s.Size.Z) > 0.01) then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	elseif s.Shape ~= "Block" then
		p.Shape = (Enum.PartType :: any)[s.Shape]
	end
	p.CanCollide = s.Collide == true
	p.CanQuery = s.Collide == true
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = s.Transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if s.Light then
		NacaraV2Builder.Stats.Lights += 1
		local l = Instance.new("PointLight")
		l.Color = s.Light.Color
		l.Range = s.Light.Range
		l.Brightness = s.Light.Brightness
		l.Shadows = false
		l.Parent = p
	end
	if s.Sign then
		label(p, s.Sign.Title, s.Sign.Sub)
	end
	p.Parent = parent
	return p
end

local function fill(terrain: any, op: any)
	local m = (Enum.Material :: any)[op.Material]
	if op.Op == "Cylinder" then
		terrain:FillCylinder(CF(op.Pos), op.H, op.R, m)
	elseif op.Op == "Ball" then
		terrain:FillBall(op.Pos, op.R, m)
	elseif op.Op == "Block" then
		terrain:FillBlock(CF(op.Pos), op.Size, m)
	end
	NacaraV2Builder.Stats.Fills += 1
end

-- Las mallas del kit (como OceanBuilder.kitSite): cuando MarMeshes las tiene; si no, su respaldo de piezas
local function kit(models: { [string]: Model }, list: { any })
	task.spawn(function()
		local MarMeshes = require(script.Parent.MarMeshes)
		local Builder = require(script.Parent.ReefZoneBuilder)
		local t0 = os.clock()
		while not MarMeshes.folder() and os.clock() - t0 < 150 and not string.find(tostring(MarMeshes.Status or ""), "respaldo", 1, true) do
			task.wait(2)
		end
		local meshes = MarMeshes.folder()
		local budget = { Left = NacaraV2.KitBudget }
		for _, p in list do
			local m = models[p.District]
			if m then
				local ok = pcall(Builder.makePiece, p, m, meshes, budget)
				if ok then
					NacaraV2Builder.Stats.Kit += 1
				end
			end
		end
	end)
end

function NacaraV2Builder.build(terrain: any?)
	if NacaraV2Builder.State ~= "None" then
		return
	end
	NacaraV2Builder.State = "Building"
	local plan = NacaraV2Builder.plan()
	local t = terrain or workspace.Terrain
	for _, op in plan.Terrain do
		local ok, err = pcall(fill, t, op)
		if not ok then
			warn("[NacaraV2Builder] terreno: " .. tostring(err))
		end
	end
	local models: { [string]: Model } = {}
	local function modelFor(id: string): Model
		local m = models[id]
		if not m then
			m = Instance.new("Model")
			m.Name = "Nacara_V2_" .. id
			pcall(function()
				(m :: any).ModelStreamingMode = Enum.ModelStreamingMode.Atomic
			end)
			models[id] = m
		end
		return m :: Model
	end
	for _, s in plan.Parts do
		NacaraV2Builder.Stats.Parts += 1
		make(modelFor(s.District or "Enlaces"), s)
	end
	for _, m in models do
		m.Parent = folder()
	end
	kit(models, plan.Kit)
	NacaraV2Builder.State = "Ready"
	print(("[NacaraV2Builder] Nácara v2 (fase %d): %d piezas, %d luces, %d rellenos, %d mallas del kit en camino"):format(NacaraV2.BuildPhase, NacaraV2Builder.Stats.Parts, NacaraV2Builder.Stats.Lights, NacaraV2Builder.Stats.Fills, #plan.Kit))
end

function NacaraV2Builder._reset()
	NacaraV2Builder.State = "None"
	NacaraV2Builder.Stats = { Parts = 0, Lights = 0, Fills = 0, Kit = 0 }
end

return NacaraV2Builder
