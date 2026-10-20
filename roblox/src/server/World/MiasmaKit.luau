-- MiasmaKit (servidor): cómo se VE Miasma (docs/planetas/diseno-mundos.md §3.6; marco común:
-- docs/planetas/marco-planetas.md). El kit que usan World/PlanetCityBuilder (el barrio de Anclaje Siete) y
-- World/PlanetWorld (la flora, los puntos de interés y el mar de niebla).
--
-- Anclaje Siete NO es Bastión Ceniza: aquí no hay calles ni murallas. Son DISCOS de metal claro y cristal
-- con un aro de luz turquesa, anclados con cables a un pico, con barandillas (no se cae nadie), pasarelas
-- colgantes entre ellos y globos de gas que los sostienen. Debajo, la niebla verde. Torres con cúpulas de
-- cristal, chapa violeta remendada en Lastre, casas de madera pintada colgadas de globos en las Góndolas,
-- la Gran Veleta, la torre de la Refinería con su llama, la batería antiaérea y los hangares.
-- Todo con piezas (sin mallas nuevas). Presupuesto: ~2 500 piezas el barrio.

local Builder = require(script.Parent.Builder)

local MiasmaKit = {}

local V3 = Vector3.new
local rgb = Color3.fromRGB

local C = {
	Metal = rgb(158, 164, 180),
	MetalDark = rgb(70, 72, 86),
	Plate = rgb(120, 124, 140),
	Rim = rgb(110, 240, 220), -- el aro de luz turquesa
	Glass = rgb(150, 220, 210),
	Rust = rgb(110, 84, 92),
	Violet = rgb(150, 120, 200),
	Fog = rgb(140, 196, 70),
	Cable = rgb(40, 40, 48),
	Balloon = { rgb(236, 180, 200), rgb(180, 210, 246), rgb(240, 222, 150), rgb(190, 232, 196), rgb(214, 190, 240) },
	Fabric = { rgb(200, 90, 120), rgb(90, 140, 200), rgb(220, 190, 80), rgb(110, 180, 120), rgb(170, 110, 210), rgb(240, 240, 236) },
	Lamp = rgb(160, 255, 236),
	Flame = rgb(255, 210, 120),
}
MiasmaKit.Colors = {
	Metal = C.MetalDark,
	Lamp = C.Lamp,
	Floor = C.Plate,
	FloorMaterial = Enum.Material.DiamondPlate,
	Light = rgb(200, 255, 240),
	Sign = rgb(24, 30, 40),
	SignText = rgb(150, 255, 230),
	Pad = rgb(130, 136, 152),
	PadRing = rgb(110, 240, 220),
	PadLight = rgb(200, 255, 240),
	Poi = rgb(96, 88, 110),
	PoiLight = rgb(160, 255, 200),
}

local function rngOf(seed: number): () -> number
	local s = math.floor(math.abs(seed)) % 2147483647 + 1
	return function()
		s = (s * 16807) % 2147483647
		return s / 2147483647
	end
end

-- Un cable (pieza fina) entre dos puntos del mundo
local function cable(parent: Instance, a: Vector3, b: Vector3, thick: number?, color: Color3?)
	local mid = (a + b) / 2
	local len = (b - a).Magnitude
	if len < 0.5 then
		return
	end
	Builder.decor({ Name = "Cable", Size = V3(thick or 0.3, thick or 0.3, len), CFrame = CFrame.lookAt(mid, b), Color = color or C.Cable, Material = Enum.Material.Metal, Parent = parent })
end
MiasmaKit.cable = cable

local function glow(part: BasePart, color: Color3, range: number, brightness: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = part
end

---------------------------------------------------------------------
-- Los discos y las pasarelas (suelos del plano: MiasmaCity.Floors)
---------------------------------------------------------------------
-- ¿Hay una pasarela saliendo de este disco en la dirección a (radianes)?
local function bridgeAt(ctx: any, d: { [string]: any }, a: number): boolean
	for _, f in ctx.City.Floors do
		if f.Bridge then
			local bx, bz = (f.X0 + f.X1) / 2, (f.Z0 + f.Z1) / 2
			local ba = math.atan2(bz - d.Z, bx - d.X)
			local diff = math.abs((a - ba + math.pi) % (2 * math.pi) - math.pi)
			if diff < (8 / d.R) and math.sqrt((bx - d.X) ^ 2 + (bz - d.Z) ^ 2) < d.R + 30 then
				return true
			end
		end
	end
	return false
end

function MiasmaKit.floor(ctx: any, parent: Instance, f: { [string]: any }): boolean
	local W = ctx.W
	if f.Kind == "Disc" then
		local m = Builder.model(f.Id, parent)
		local top = 0.9
		-- El disco (chapa) y su borde de cristal con el aro de luz
		ctx.column(m, "Disco", W(f.X, f.Z, -2.4), top + 2.4, f.R * 2, C.Plate, Enum.Material.DiamondPlate)
		ctx.column(m, "Borde", W(f.X, f.Z, -3.2), 1.4, f.R * 2 + 2, C.Metal, Enum.Material.Metal, true)
		local rim = ctx.column(m, "Aro", W(f.X, f.Z, -3.6), 0.5, f.R * 2 + 2.6, C.Rim, Enum.Material.Neon, true)
		rim.CastShadow = false
		-- Losas claras en anillo (el dibujo del suelo)
		ctx.column(m, "Anillo", W(f.X, f.Z, top - 0.02), 0.06, f.R * 1.4, C.Metal, Enum.Material.Metal, true)
		ctx.column(m, "Centro", W(f.X, f.Z, top - 0.01), 0.06, f.R * 1.3, C.Plate, Enum.Material.DiamondPlate, true)
		-- Debajo: el cono de la estructura y la columna que lo ancla al pico (hasta el suelo de abajo)
		ctx.ball(m, "Bajos", W(f.X, f.Z, -f.R * 0.28), f.R * 1.1, C.MetalDark, Enum.Material.CorrodedMetal, true)
		ctx.column(m, "Anclaje", W(f.X, f.Z, -150), 150, 8, C.MetalDark, Enum.Material.CorrodedMetal, true)
		-- La barandilla: postes y pasamanos en anillo (con hueco en las pasarelas)
		local n = math.floor(f.R * 2 * math.pi / 8)
		for k = 0, n - 1 do
			local a0 = k / n * math.pi * 2
			local a1 = (k + 1) / n * math.pi * 2
			local am = (a0 + a1) / 2
			if not bridgeAt(ctx, f, am) then
				local r = f.R - 0.6
				local p0 = W(f.X + math.cos(a0) * r, f.Z + math.sin(a0) * r, top)
				local p1 = W(f.X + math.cos(a1) * r, f.Z + math.sin(a1) * r, top)
				local mid = (p0 + p1) / 2
				local len = (p1 - p0).Magnitude
				Builder.part({ Name = "Barandilla", Size = V3(0.4, 3.4, len), CFrame = CFrame.lookAt(mid + V3(0, 1.7, 0), p1 + V3(0, 1.7, 0)), Color = C.Glass, Material = Enum.Material.Glass, Transparency = 0.55, CastShadow = false, Parent = m })
				Builder.decor({ Name = "Pasamanos", Size = V3(0.5, 0.35, len), CFrame = CFrame.lookAt(mid + V3(0, 3.5, 0), p1 + V3(0, 3.5, 0)), Color = C.Metal, Material = Enum.Material.Metal, Parent = m })
			end
		end
		-- Un globo de gas que sostiene el disco (atado con cuatro cables)
		if f.R >= 40 then
			local r = rngOf(f.X * 7 + f.Z * 13)
			local gx, gz = f.X + (r() - 0.5) * f.R * 0.6, f.Z + (r() - 0.5) * f.R * 0.6
			local gy = 70 + r() * 20
			local balloon = ctx.ball(m, "GloboGas", W(gx, gz, gy), 26, C.Balloon[1 + math.floor(r() * #C.Balloon)], Enum.Material.SmoothPlastic, true)
			balloon.CastShadow = false
			ctx.column(m, "Banda", W(gx, gz, gy - 0.6), 1.2, 26.4, C.Fabric[6], Enum.Material.Fabric, true)
			for q = 0, 3 do
				local a = q / 4 * math.pi * 2 + 0.4
				cable(m, W(gx + math.cos(a) * 8, gz + math.sin(a) * 8, gy - 10), W(f.X + math.cos(a) * (f.R - 2), f.Z + math.sin(a) * (f.R - 2), top + 3.5), 0.25)
			end
		end
		return true
	elseif f.Bridge then
		local m = Builder.model(f.Id, parent)
		local alongX = (f.X1 - f.X0) > (f.Z1 - f.Z0)
		ctx.box(m, "Pasarela", f.X0, f.X1, f.Z0, f.Z1, 0, 0.9, C.Plate, Enum.Material.DiamondPlate)
		for _, s in { -1, 1 } do
			if alongX then
				local z = if s < 0 then f.Z0 + 0.3 else f.Z1 - 0.3
				ctx.box(m, "Baranda", f.X0, f.X1, z - 0.2, z + 0.2, 0.9, 4.2, C.Glass, Enum.Material.Glass, false, { Transparency = 0.55 })
				ctx.box(m, "Cuerda", f.X0, f.X1, z - 0.25, z + 0.25, 4.2, 4.6, C.Metal, Enum.Material.Metal, true)
			else
				local x = if s < 0 then f.X0 + 0.3 else f.X1 - 0.3
				ctx.box(m, "Baranda", x - 0.2, x + 0.2, f.Z0, f.Z1, 0.9, 4.2, C.Glass, Enum.Material.Glass, false, { Transparency = 0.55 })
				ctx.box(m, "Cuerda", x - 0.25, x + 0.25, f.Z0, f.Z1, 4.2, 4.6, C.Metal, Enum.Material.Metal, true)
			end
		end
		-- Neón por debajo (de noche se ve la pasarela desde lejos)
		local under = ctx.box(m, "Luz", f.X0, f.X1, (f.Z0 + f.Z1) / 2 - 0.3, (f.Z0 + f.Z1) / 2 + 0.3, -0.5, -0.2, C.Rim, Enum.Material.Neon, true)
		if not alongX then
			under.Size = V3(0.6, 0.3, f.Z1 - f.Z0)
			under.CFrame = CFrame.new(W((f.X0 + f.X1) / 2, (f.Z0 + f.Z1) / 2, -0.35))
		end
		return true
	end
	return false
end

---------------------------------------------------------------------
-- Farolas: poste fino con una cápsula de luz turquesa
---------------------------------------------------------------------
function MiasmaKit.lamp(ctx: any, parent: Instance, cf: CFrame)
	local m = Builder.model("StreetLamp", parent)
	Builder.part({ Name = "Pie", Size = V3(1.2, 0.6, 1.2), CFrame = cf * CFrame.new(0, 0.3, 0), Color = C.MetalDark, Material = Enum.Material.Metal, Parent = m })
	Builder.part({ Name = "Poste", Shape = Enum.PartType.Cylinder, Size = V3(9, 0.4, 0.4), CFrame = cf * CFrame.new(0, 4.8, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = C.MetalDark, Material = Enum.Material.Metal, Parent = m })
	local bulb = Builder.decor({ Name = "Capsula", Shape = Enum.PartType.Ball, Size = V3(1.6, 1.6, 1.6), CFrame = cf * CFrame.new(0, 9.6, 0), Color = C.Lamp, Material = Enum.Material.SmoothPlastic, Tags = { "StreetLamp" }, Parent = m })
	Builder.decor({ Name = "Sombrero", Shape = Enum.PartType.Cylinder, Size = V3(0.3, 2.4, 2.4), CFrame = cf * CFrame.new(0, 10.6, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = C.Metal, Material = Enum.Material.Metal, Parent = m })
	local l = Instance.new("PointLight")
	l.Color = C.Lamp
	l.Range = 26
	l.Brightness = 1.4
	l.Shadows = false
	l.Enabled = false
	l.Parent = bulb
	return m
end

---------------------------------------------------------------------
-- Lo que se añade a los edificios Box (Kit/Building)
---------------------------------------------------------------------
function MiasmaKit.dressBox(ctx: any, model: Model, b: { [string]: any }, cf: CFrame, info: { Top: number, GroundTop: number })
	local w, d = b.W or 20, b.D or 20
	local top = info.Top
	-- Ojos de buey en la fachada que se encienden de noche (luz turquesa o cálida)
	local warm = b.Style ~= "MiasmaCupula"
	for k = 0, 2 do
		local y = info.GroundTop + 2 + k * math.max(2, (top - info.GroundTop - 4) / 3)
		if y < top - 1 then
			local port = Builder.decor({ Name = "OjoDeBuey", Shape = Enum.PartType.Cylinder, Size = V3(0.3, 1.8, 1.8), CFrame = cf * CFrame.new((k - 1) * w * 0.28, y, -d / 2 - 0.12) * CFrame.Angles(0, math.pi / 2, 0), Color = rgb(40, 50, 60), Material = Enum.Material.Glass, Parent = model })
			port:AddTag("NightWindow")
			port:SetAttribute("DayColor", rgb(40, 50, 60))
			port:SetAttribute("NightColor", if warm then rgb(255, 200, 140) else rgb(150, 255, 230))
			port:SetAttribute("OnAt", 17.6 + k * 0.6)
			port:SetAttribute("OffAt", 23.5 + k)
		end
	end
	if b.Balloon then
		-- La casa cuelga de un globo: el globo arriba y cuatro cables a las esquinas
		local r = rngOf(b.X * 11 + b.Z * 3)
		local gy = top + 22
		local balloon = Builder.decor({ Name = "Globo", Shape = Enum.PartType.Ball, Size = Vector3.one * (math.max(w, d) * 1.1), CFrame = cf * CFrame.new(0, gy, 0), Color = C.Balloon[1 + math.floor(r() * #C.Balloon)], Material = Enum.Material.SmoothPlastic, Parent = model })
		balloon.CastShadow = false
		Builder.decor({ Name = "Raya", Shape = Enum.PartType.Cylinder, Size = V3(1, math.max(w, d) * 1.12, math.max(w, d) * 1.12), CFrame = cf * CFrame.new(0, gy, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = C.Fabric[6], Material = Enum.Material.Fabric, Parent = model })
		for _, q in { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } } do
			cable(model, (cf * CFrame.new(q[1] * w * 0.3, gy - math.max(w, d) * 0.4, q[2] * d * 0.3)).Position, (cf * CFrame.new(q[1] * (w / 2 - 0.5), top, q[2] * (d / 2 - 0.5))).Position, 0.2)
		end
		-- Farolillos de colores en la fachada
		for k = -1, 1 do
			local lamp = Builder.decor({ Name = "Farolillo", Shape = Enum.PartType.Ball, Size = Vector3.one * 0.9, CFrame = cf * CFrame.new(k * w * 0.3, info.GroundTop - 0.4, -d / 2 - 0.8), Color = C.Fabric[2 + k], Material = Enum.Material.Neon, Parent = model })
			if k == 0 then
				glow(lamp, rgb(255, 210, 160), 12, 0.8)
			end
		end
	elseif b.Style == "MiasmaCupula" then
		-- Cúpula de cristal en el tejado y una antena con su luz roja
		local r = math.min(w, d) * 0.4
		Builder.decor({ Name = "Cupula", Shape = Enum.PartType.Ball, Size = Vector3.one * r * 2, CFrame = cf * CFrame.new(0, top - r * 0.3, 0), Color = C.Glass, Material = Enum.Material.Glass, Transparency = 0.35, Reflectance = 0.15, Parent = model })
		Builder.decor({ Name = "Antena", Size = V3(0.4, 10, 0.4), CFrame = cf * CFrame.new(w * 0.3, top + 5, d * 0.25), Color = C.Metal, Material = Enum.Material.Metal, Parent = model })
		local tip = Builder.decor({ Name = "Baliza", Shape = Enum.PartType.Ball, Size = Vector3.one * 0.9, CFrame = cf * CFrame.new(w * 0.3, top + 10.2, d * 0.25), Color = rgb(255, 70, 80), Material = Enum.Material.Neon, Parent = model })
		glow(tip, rgb(255, 70, 80), 14, 1)
	elseif b.Style == "MiasmaLastre" then
		-- Remiendos de chapa, tubos y un ventilador del filtro en el tejado
		local r = rngOf(b.X * 5 + b.Z * 9)
		for k = 1, 3 do
			Builder.decor({ Name = "Remiendo", Size = V3(3 + r() * 3, 2 + r() * 2, 0.3), CFrame = cf * CFrame.new((r() - 0.5) * w * 0.7, 3 + r() * (top - 6), -d / 2 - 0.2), Color = if k % 2 == 0 then C.Rust else C.Violet, Material = Enum.Material.CorrodedMetal, Parent = model })
		end
		Builder.decor({ Name = "Tubo", Shape = Enum.PartType.Cylinder, Size = V3(top + 2, 1, 1), CFrame = cf * CFrame.new(w / 2 + 0.6, (top + 2) / 2, d * 0.2) * CFrame.Angles(0, 0, math.pi / 2), Color = C.MetalDark, Material = Enum.Material.CorrodedMetal, Parent = model })
		Builder.decor({ Name = "Ventilador", Shape = Enum.PartType.Cylinder, Size = V3(1.2, 6, 6), CFrame = cf * CFrame.new(-w * 0.2, top + 0.6, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = C.MetalDark, Material = Enum.Material.Metal, Parent = model })
		local fil = Builder.decor({ Name = "Filtro", Shape = Enum.PartType.Cylinder, Size = V3(1.4, 4.4, 4.4), CFrame = cf * CFrame.new(-w * 0.2, top + 1.2, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = C.Fog, Material = Enum.Material.Neon, Parent = model })
		fil.CastShadow = false
	end
end

---------------------------------------------------------------------
-- Las formas que no son Box
---------------------------------------------------------------------
MiasmaKit.Shapes = {}

-- (dirección hacia fuera de una fachada)
local function faceDir(face: string): { number }
	return ({ N = { 0, -1 }, S = { 0, 1 }, E = { 1, 0 }, W = { -1, 0 } })[face] or { 0, -1 }
end

-- Hangar: tres paredes de chapa y una bóveda de medio cilindro; delante, abierto
function MiasmaKit.Shapes.Hangar(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local x0, x1, z0, z1 = ctx.City.footprint(b)
	local h = (b.Height or 12) - 4
	local face = b.Face or "N"
	local alongX = face == "N" or face == "S" -- (la bóveda va de lado a lado, mirando a la fachada)
	local function wall(ax0, ax1, az0, az1)
		ctx.box(m, "Pared", ax0, ax1, az0, az1, 0.9, h, C.Metal, Enum.Material.Metal)
	end
	if face ~= "N" then
		wall(x0, x1, z0, z0 + 0.8)
	end
	if face ~= "S" then
		wall(x0, x1, z1 - 0.8, z1)
	end
	if face ~= "W" then
		wall(x0, x0 + 0.8, z0, z1)
	end
	if face ~= "E" then
		wall(x1 - 0.8, x1, z0, z1)
	end
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
	local span = if alongX then x1 - x0 else z1 - z0
	local len = if alongX then z1 - z0 else x1 - x0
	-- La bóveda: seis chapas en arco (se entra andando por delante)
	local vault: BasePart? = nil
	local radius = span / 2
	for k = 0, 5 do
		local t0, t1 = k / 6 * math.pi, (k + 1) / 6 * math.pi
		local tm = (t0 + t1) / 2
		local across = math.cos(tm) * radius
		local up = h + math.sin(tm) * radius * 0.6
		local width = math.sqrt((math.cos(t1) - math.cos(t0)) ^ 2 + ((math.sin(t1) - math.sin(t0)) * 0.6) ^ 2) * radius + 0.4
		local tilt = math.atan2((math.sin(t1) - math.sin(t0)) * 0.6, math.cos(t1) - math.cos(t0))
		local pos = if alongX then ctx.W(cx + across, cz, up) else ctx.W(cx, cz + across, up)
		local cf = if alongX then CFrame.new(pos) * CFrame.Angles(0, 0, tilt) else CFrame.new(pos) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.Angles(0, 0, -tilt)
		local slab = Builder.part({ Name = "Boveda", Size = V3(width, 0.8, len), CFrame = cf, Color = if k % 2 == 0 then C.MetalDark else C.Metal, Material = Enum.Material.CorrodedMetal, Parent = m })
		vault = vault or slab
	end
	-- Franjas de aviso y focos en la entrada
	local d = faceDir(face)
	local fx, fz = cx + d[1] * (len / 2 + 0.4), cz + d[2] * (len / 2 + 0.4)
	for k = -1, 1, 2 do
		local px, pz = fx + (if alongX then k * span * 0.42 else 0), fz + (if alongX then 0 else k * span * 0.42)
		local foco = ctx.ball(m, "Foco", ctx.W(px, pz, h - 1), 1.2, rgb(255, 240, 200), Enum.Material.Neon, true)
		glow(foco, rgb(255, 240, 200), 20, 1)
	end
	-- Una nave dentro (cuñas: casco, alas)
	Builder.decor({ ClassName = "WedgePart", Name = "Nave", Size = V3(6, 3, 12), CFrame = CFrame.new(ctx.W(cx, cz, 2.6)) * CFrame.Angles(0, if alongX then 0 else math.pi / 2, 0), Color = rgb(200, 204, 214), Material = Enum.Material.Metal, Parent = m })
	Builder.decor({ Name = "Alas", Size = V3(14, 0.5, 4), CFrame = CFrame.new(ctx.W(cx, cz, 2.4)) * CFrame.Angles(0, if alongX then 0 else math.pi / 2, 0), Color = rgb(160, 166, 180), Material = Enum.Material.Metal, Parent = m })
	m.PrimaryPart = vault
	Builder.streamable(m)
	return m
end

-- Batería antiaérea: base, torreta y dos cañones (y sacos alrededor)
function MiasmaKit.Shapes.Cannon(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local base = ctx.column(m, "Base", ctx.W(b.X, b.Z, 0.9), 2.4, (b.R or 6) * 2, C.MetalDark, Enum.Material.Metal)
	local turret = ctx.ball(m, "Torreta", ctx.W(b.X, b.Z, 4.6), 6, C.Metal, Enum.Material.Metal)
	for _, s in { -1, 1 } do
		local from = ctx.W(b.X + s * 1.2, b.Z, 5.2)
		local to = from + V3(3, 6.5, -2)
		Builder.part({ Name = "Canon", Shape = Enum.PartType.Cylinder, Size = V3(7.4, 0.9, 0.9), CFrame = CFrame.lookAt((from + to) / 2, to) * CFrame.Angles(0, math.pi / 2, 0), Color = C.MetalDark, Material = Enum.Material.Metal, Parent = m })
	end
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		Builder.decor({ Name = "Saco", Size = V3(3, 1.4, 1.6), CFrame = CFrame.new(ctx.W(b.X + math.cos(a) * ((b.R or 6) + 1.5), b.Z + math.sin(a) * ((b.R or 6) + 1.5), 1.6)) * CFrame.Angles(0, -a, 0), Color = rgb(150, 140, 110), Material = Enum.Material.Fabric, Parent = m })
	end
	m.PrimaryPart = base
	local _ = turret
	return m
end

-- La Gran Veleta: mástil altísimo, la flecha con su cola y los cuatro brazos con letras
function MiasmaKit.Shapes.Veleta(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local h = b.Height or 46
	local base = ctx.column(m, "Pedestal", ctx.W(b.X, b.Z, 0.9), 3, (b.R or 5) * 2 + 2, C.MetalDark, Enum.Material.Metal)
	ctx.column(m, "Mastil", ctx.W(b.X, b.Z, 3.9), h - 4, 1.6, C.Metal, Enum.Material.Metal)
	for _, y in { 12, 24, 36 } do
		ctx.column(m, "Aro", ctx.W(b.X, b.Z, y), 0.6, 3.2, C.Rim, Enum.Material.Neon, true)
	end
	-- Los cuatro brazos (N, S, E, O) con su letra
	for _, arm in { { 0, -1, "N" }, { 0, 1, "S" }, { 1, 0, "E" }, { -1, 0, "O" } } do
		local p = ctx.W(b.X + arm[1] * 4, b.Z + arm[2] * 4, h - 8)
		Builder.decor({ Name = "Brazo", Size = V3(if arm[1] ~= 0 then 8 else 0.4, 0.4, if arm[2] ~= 0 then 8 else 0.4), CFrame = CFrame.new(ctx.W(b.X + arm[1] * 4, b.Z + arm[2] * 4, h - 8)), Color = C.Metal, Material = Enum.Material.Metal, Parent = m })
		local letter = Builder.decor({ Name = "Letra" .. arm[3], Size = V3(2, 2, 0.3), CFrame = Builder.facing(p + V3(arm[1] * 4.4, 0, arm[2] * 4.4), V3(arm[1], 0, arm[2])), Color = rgb(30, 34, 44), Material = Enum.Material.Metal, Parent = m })
		Builder.sign(letter, arm[3], Enum.NormalId.Front, C.Rim)
	end
	-- La flecha (apunta al bloqueo: hacia el este) y su cola
	local yaw = math.rad(70)
	local cf = CFrame.new(ctx.W(b.X, b.Z, h - 2)) * CFrame.Angles(0, yaw, 0)
	Builder.decor({ Name = "Flecha", Size = V3(0.6, 0.6, 18), CFrame = cf, Color = rgb(240, 200, 90), Material = Enum.Material.Metal, Parent = m })
	Builder.decor({ ClassName = "WedgePart", Name = "Punta", Size = V3(0.6, 2.6, 3.6), CFrame = cf * CFrame.new(0, 0, -10) * CFrame.Angles(0, math.pi, 0), Color = rgb(240, 200, 90), Material = Enum.Material.Metal, Parent = m })
	Builder.decor({ Name = "Cola", Size = V3(0.3, 5, 5), CFrame = cf * CFrame.new(0, 0, 9) * CFrame.Angles(math.rad(45), 0, 0), Color = rgb(240, 200, 90), Material = Enum.Material.Metal, Parent = m })
	local top = ctx.ball(m, "Remate", ctx.W(b.X, b.Z, h), 2, C.Rim, Enum.Material.Neon, true)
	glow(top, C.Rim, 30, 1.4)
	m.PrimaryPart = base
	Builder.streamable(m)
	return m
end

-- La torre de la Refinería: cilindros que se estrechan, pasarelas, tubos que bajan a la niebla y la llama
function MiasmaKit.Shapes.Refineria(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local r, h = b.R or 10, b.Height or 60
	local base = ctx.column(m, "Base", ctx.W(b.X, b.Z, 0.9), 8, r * 2, C.MetalDark, Enum.Material.CorrodedMetal)
	local y, d = 8.9, r * 1.7
	for k = 1, 4 do
		local seg = (h - 14) / 4
		ctx.column(m, "Torre", ctx.W(b.X, b.Z, y), seg, d, if k % 2 == 0 then C.Metal else rgb(186, 176, 120), Enum.Material.Metal)
		ctx.column(m, "Anillo", ctx.W(b.X, b.Z, y + seg - 0.6), 0.6, d + 2.2, C.Cable, Enum.Material.Metal, true)
		y += seg
		d *= 0.78
	end
	local flare = ctx.column(m, "Mechero", ctx.W(b.X, b.Z, y), 4, 2, C.MetalDark, Enum.Material.Metal)
	local flame = ctx.ball(m, "Llama", ctx.W(b.X, b.Z, y + 5), 3, C.Flame, Enum.Material.Neon, true)
	glow(flame, C.Flame, 50, 2)
	local fire = Instance.new("Fire")
	fire.Size = 6
	fire.Heat = 12
	fire.Color = rgb(255, 170, 60)
	fire.SecondaryColor = rgb(255, 240, 160)
	fire.Parent = flame
	-- Los tubos que bajan hasta la niebla (por fuera del disco)
	for k = 0, 2 do
		local a = k / 3 * math.pi * 2 + 0.6
		local px, pz = b.X + math.cos(a) * (r + 1.5), b.Z + math.sin(a) * (r + 1.5)
		ctx.column(m, "Tubo", ctx.W(px, pz, -60), 60 + 20 + k * 6, 1.6, C.Rust, Enum.Material.CorrodedMetal, true)
	end
	local _ = flare
	m.PrimaryPart = base
	Builder.streamable(m)
	return m
end

-- Depósito de gas: una esfera sobre patas con una franja de luz
function MiasmaKit.Shapes.GasTank(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local r, h = b.R or 8, b.Height or 16
	local sphere = ctx.ball(m, "Esfera", ctx.W(b.X, b.Z, h - r), r * 2, rgb(206, 196, 140), Enum.Material.Metal)
	ctx.column(m, "Franja", ctx.W(b.X, b.Z, h - r - 0.5), 1, r * 2 + 0.3, C.Fog, Enum.Material.Neon, true)
	for q = 0, 3 do
		local a = q / 4 * math.pi * 2 + math.pi / 4
		ctx.column(m, "Pata", ctx.W(b.X + math.cos(a) * r * 0.75, b.Z + math.sin(a) * r * 0.75, 0.9), h - r, 1.2, C.MetalDark, Enum.Material.Metal)
	end
	m.PrimaryPart = sphere
	return m
end

---------------------------------------------------------------------
-- Material del planeta para recoger (musgo filtro, plata de rayo)
---------------------------------------------------------------------
function MiasmaKit.gather(ctx: any, parent: Instance, g: { [string]: any })
	if g.Item == "PlataRayo" then
		ctx.column(parent, "Pararrayos", ctx.W(g.X, g.Z, 0.9), 12, 0.5, C.Metal, Enum.Material.Metal, true)
		local tip = ctx.ball(parent, "Chispa", ctx.W(g.X, g.Z, 13), 1.2, rgb(220, 240, 255), Enum.Material.Neon, true)
		glow(tip, rgb(200, 230, 255), 16, 1.2)
		return
	end
	for k = 0, 4 do
		local a = k * 1.3
		ctx.ball(parent, "Musgo", ctx.W(g.X + math.cos(a) * 1.6, g.Z + math.sin(a) * 1.6, 1.2), 1.8 + (k % 2), rgb(170, 180, 70), Enum.Material.Grass, true)
	end
end

---------------------------------------------------------------------
-- Lo propio de Anclaje Siete: la barandilla de los pañuelos, el carguero de Mara, los puestos de la
-- Plaza, cajas, el cartel del filtro obligatorio, las estaciones de filtro y los cables del Ancla
---------------------------------------------------------------------
function MiasmaKit.extras(ctx: any, model: Model)
	local W = ctx.W
	local City = ctx.City
	local m = Builder.model("Anclaje", model)
	-- Los pañuelos de la barandilla (un arco de colores)
	local p = City.SpotById.Panuelos
	if p then
		for k = 0, 15 do
			local a = math.pi * 0.5 + (k - 7.5) * 0.045
			local disc = City.Discs[5]
			local r = disc.R - 0.7
			local x, z = disc.X + math.cos(a) * r, disc.Z + math.sin(a) * r
			Builder.decor({ Name = "Panuelo", Size = V3(0.15, 1.8, 1.1), CFrame = CFrame.new(W(x, z, 3.2)) * CFrame.Angles(0, -a, 0.15), Color = C.Fabric[1 + k % #C.Fabric], Material = Enum.Material.Fabric, Parent = m })
		end
	end
	-- Los puestos de la Plaza de las Veletas (mostrador y toldo de colores)
	for i, st in { { -104, -30, 0 }, { -104, 30, math.pi }, { -142, -28, math.pi / 2 } } do
		local cf = ctx.CF(st[1], st[2], 0.9, st[3])
		Builder.part({ Name = "Mostrador", Size = V3(7, 3.2, 2), CFrame = cf * CFrame.new(0, 1.6, 0), Color = rgb(110, 96, 120), Material = Enum.Material.WoodPlanks, Parent = m })
		for _, s in { -1, 1 } do
			Builder.decor({ Name = "Poste", Size = V3(0.4, 7, 0.4), CFrame = cf * CFrame.new(s * 3.2, 3.5, 1.6), Color = C.MetalDark, Material = Enum.Material.Metal, Parent = m })
		end
		Builder.decor({ Name = "Toldo", Size = V3(7.6, 0.25, 5), CFrame = cf * CFrame.new(0, 7, 0.4) * CFrame.Angles(math.rad(-10), 0, 0), Color = C.Fabric[i], Material = Enum.Material.Fabric, Parent = m })
		Builder.decor({ Name = "Genero", Size = V3(5, 0.8, 1.2), CFrame = cf * CFrame.new(0, 3.6, 0), Color = if i == 1 then C.Fog else rgb(200, 190, 160), Material = Enum.Material.SmoothPlastic, Parent = m })
	end
	-- El carguero de Mara, el «Último Respiro», dentro de su hangar (con la medusa pintada)
	local h = City.BuildingById.Miasma_HangarMara
	if h then
		Builder.decor({ Name = "UltimoRespiro", Size = V3(9, 3, 7), CFrame = ctx.CF(h.X, h.Z, 2.4), Color = rgb(150, 110, 90), Material = Enum.Material.CorrodedMetal, Parent = m })
		local nose = Builder.decor({ ClassName = "WedgePart", Name = "Morro", Size = V3(9, 3, 3), CFrame = ctx.CF(h.X, h.Z - 5, 2.4, math.pi), Color = rgb(150, 110, 90), Material = Enum.Material.CorrodedMetal, Parent = m })
		Builder.decor({ Name = "Medusa", Shape = Enum.PartType.Ball, Size = V3(2.4, 2.4, 2.4), CFrame = ctx.CF(h.X + 4.6, h.Z - 1, 3), Color = rgb(230, 160, 255), Material = Enum.Material.Neon, Parent = m })
		local _ = nose
	end
	-- Cajas de carga junto a los hangares y el cartel del filtro obligatorio
	for k, c in { { 22, 46 }, { 25, 49 }, { 52, 12 }, { -14, 140 }, { 14, 142 }, { 100, -14 } } do
		ctx.box(m, "Caja", c[1] - 1.4, c[1] + 1.4, c[2] - 1.4, c[2] + 1.4, 0.9, 3.3 + (k % 2) * 1.4, if k % 2 == 0 then rgb(120, 110, 90) else rgb(90, 100, 120), Enum.Material.WoodPlanks)
	end
	local b = City.SpotById.BordeLastre
	if b then
		ctx.box(m, "PosteCartel", b.X - 0.2, b.X + 0.2, b.Z - 0.2, b.Z + 0.2, 0.9, 6.5, C.MetalDark, Enum.Material.Metal, true)
		ctx.sign(m, "⚠ FILTRO OBLIGATORIO", CFrame.new(W(b.X, b.Z - 0.3, 6.8)) * CFrame.Angles(0, math.pi, 0), 6, 1.6, rgb(50, 46, 20), rgb(230, 240, 120))
	end
	-- Las estaciones de filtro del borde (oficio de filtrador): un armario con su filtro verde
	local S = ctx.S
	for _, f in S.FilterStations or {} do
		ctx.box(m, "EstacionFiltro", f.X - 1.5, f.X + 1.5, f.Z - 1, f.Z + 1, 0.9, 6, C.MetalDark, Enum.Material.Metal)
		local fil = ctx.column(m, "FiltroSucio", W(f.X, f.Z + 1.2, 3), 2.2, 2.2, rgb(110, 130, 50), Enum.Material.Neon, true)
		fil.CastShadow = false
	end
	-- Luces de borde en cada disco (se ven desde lejos, sobre la niebla) y focos antiaéreos en el Muelle
	for _, d in City.Discs do
		local n = math.floor(d.R / 3)
		for k = 0, n - 1 do
			local a = k / n * math.pi * 2
			local stud = ctx.ball(m, "LuzBorde", W(d.X + math.cos(a) * (d.R + 0.8), d.Z + math.sin(a) * (d.R + 0.8), -0.6), 0.9, if k % 2 == 0 then C.Rim else C.Lamp, Enum.Material.Neon, true)
			stud.CastShadow = false
		end
	end
	for k, a in { 0.8, 2.4, 4.0, 5.6 } do
		local px, pz = math.cos(a) * 56, math.sin(a) * 56
		ctx.column(m, "PosteFoco", W(px, pz, 0.9), 7, 0.8, C.MetalDark, Enum.Material.Metal, true)
		local beam = Builder.decor({ Name = "HazFoco", Size = V3(1.6, 1.6, 90), CFrame = CFrame.lookAt(W(px, pz, 8) + V3(0, 30, 0), W(px * 3, pz * 3, 160)), Color = rgb(220, 255, 250), Material = Enum.Material.Neon, Transparency = 0.86, Parent = m })
		beam.CastShadow = false
		local _ = k
	end
	-- Casitas colgadas por debajo del disco de las Góndolas (cuelgan de cables, sobre la niebla)
	local g = City.Discs[5]
	for k = 0, 3 do
		local a = math.pi * 0.15 + k * math.pi * 0.23
		local hx, hz = g.X + math.cos(a + math.pi) * (g.R + 10), g.Z + math.sin(a + math.pi) * (g.R + 10)
		local hy = -14 - (k % 2) * 6
		ctx.box(m, "CasaColgada", hx - 4, hx + 4, hz - 3.5, hz + 3.5, hy, hy + 6, C.Balloon[1 + k % #C.Balloon], Enum.Material.WoodPlanks, true)
		ctx.box(m, "Tejado", hx - 4.6, hx + 4.6, hz - 4, hz + 4, hy + 6, hy + 6.8, C.Fabric[1 + (k + 2) % #C.Fabric], Enum.Material.Fabric, true)
		local win = ctx.box(m, "Ventana", hx - 1, hx + 1, hz - 3.7, hz - 3.5, hy + 2.4, hy + 4, rgb(40, 50, 60), Enum.Material.Glass, true)
		win:AddTag("NightWindow")
		win:SetAttribute("DayColor", rgb(40, 50, 60))
		win:SetAttribute("NightColor", rgb(255, 210, 150))
		win:SetAttribute("OnAt", 17.8 + k * 0.4)
		win:SetAttribute("OffAt", 24 + k * 0.5)
		for _, s in { -1, 1 } do
			cable(m, W(hx + s * 3, hz, hy + 6.8), W(g.X + math.cos(a + math.pi) * (g.R - 2) + s * 3, g.Z + math.sin(a + math.pi) * (g.R - 2), 0.5), 0.2)
		end
	end
	-- Banderines entre las farolas de la Plaza de las Veletas (por la Copa de Globos)
	for _, line in { { { -100, -20 }, { -144, 24 } }, { { -100, 20 }, { -144, -24 } } } do
		local from, to = W(line[1][1], line[1][2], 10), W(line[2][1], line[2][2], 10)
		cable(m, from, to, 0.12)
		for k = 1, 11 do
			local p = from:Lerp(to, k / 12) - V3(0, math.sin(k / 12 * math.pi) * 1.4, 0)
			Builder.decor({ ClassName = "WedgePart", Name = "Banderin", Size = V3(0.1, 1.2, 1), CFrame = CFrame.new(p - V3(0, 0.7, 0)) * CFrame.Angles(math.pi, 0, 0), Color = C.Fabric[1 + k % #C.Fabric], Material = Enum.Material.Fabric, Parent = m })
		end
	end
	-- Bombonas de gas y barriles por el Muelle y la Refinería
	for k, c in { { 100, 10 }, { 103, 12 }, { 96, -20 }, { -48, -6 }, { -50, -2 }, { 12, 58 }, { -8, 92 }, { 30, -98 } } do
		ctx.column(m, "Bombona", W(c[1], c[2], 0.9), 2.6 + (k % 2), 1.6, if k % 3 == 0 then rgb(206, 196, 140) else C.MetalDark, Enum.Material.Metal, true)
	end
	-- Los cables del Ancla: del Muelle bajan en diagonal hasta el pico (se pierden en la niebla)
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2 + 0.3
		cable(m, W(math.cos(a) * 58, math.sin(a) * 58, -2), W(math.cos(a) * 160, math.sin(a) * 160, -120), 0.8, C.MetalDark)
	end
end

---------------------------------------------------------------------
-- Fuera del barrio: flora, puntos de interés y el mar de niebla
---------------------------------------------------------------------
function MiasmaKit.decor(folder: Instance, d: { [string]: any })
	local r = rngOf(d.Pos.X * 3 + d.Pos.Z)
	if d.Kind == "Musgo" then
		for k = 0, 2 do
			local a = d.Turn + k * 2.1
			Builder.decor({ Name = "Musgo", Shape = Enum.PartType.Ball, Size = Vector3.one * (d.Size * (0.4 + 0.1 * k)), CFrame = CFrame.new(d.Pos + V3(math.cos(a) * d.Size * 0.3, d.Size * 0.12, math.sin(a) * d.Size * 0.3)), Color = if d.Roll < 0.5 then rgb(170, 176, 70) else rgb(140, 160, 80), Material = Enum.Material.Grass, Parent = folder })
		end
	elseif d.Kind == "Roca" then
		Builder.part({ Name = "Roca", Shape = Enum.PartType.Ball, Size = Vector3.one * d.Size, CFrame = CFrame.new(d.Pos + V3(0, d.Size * 0.15, 0)), Color = if d.Roll < 0.6 then rgb(96, 86, 110) else rgb(70, 64, 84), Material = Enum.Material.Slate, Anchored = true, Parent = folder })
	elseif d.Kind == "Cristal" then
		for k = 0, 2 do
			local a = d.Turn + k * 2.2
			local hh = 2 + r() * 3
			Builder.decor({ Name = "Cristal", Size = V3(1.4, hh, 1.4), CFrame = CFrame.new(d.Pos + V3(math.cos(a) * 1.2, hh * 0.4, math.sin(a) * 1.2)) * CFrame.Angles(math.cos(a) * 0.4, a, math.sin(a) * 0.4), Color = rgb(170, 255, 200), Material = Enum.Material.Glass, Transparency = 0.2, Parent = folder })
		end
	elseif d.Kind == "Medusa" then
		-- Medusa de gas: flota sobre la niebla, quieta, brillando un poco
		local at = d.Pos + V3(0, 30 + r() * 40, 0)
		local bell = Builder.decor({ Name = "Medusa", Shape = Enum.PartType.Ball, Size = V3(10, 6, 10), CFrame = CFrame.new(at), Color = rgb(230, 170, 255), Material = Enum.Material.Glass, Transparency = 0.35, Parent = folder })
		Builder.decor({ Name = "Nucleo", Shape = Enum.PartType.Ball, Size = Vector3.one * 3, CFrame = CFrame.new(at), Color = rgb(255, 200, 255), Material = Enum.Material.Neon, Parent = folder })
		local _ = bell
	end
end

function MiasmaKit.poi(model: Instance, p: { [string]: any }, at: Vector3): BasePart?
	if p.Id == "Miasma_TorreSilbadora" then
		local base = Builder.part({ Name = "Base", Shape = Enum.PartType.Cylinder, Size = V3(3, 10, 10), CFrame = CFrame.new(at + V3(0, 1.5, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color = C.MetalDark, Material = Enum.Material.CorrodedMetal, Parent = model })
		for q = 0, 3 do
			local a = q / 4 * math.pi * 2 + 0.4
			cable(model, at + V3(math.cos(a) * 4, 2, math.sin(a) * 4), at + V3(math.cos(a) * 1, 44, math.sin(a) * 1), 0.8, C.MetalDark)
		end
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2
			Builder.decor({ Name = "TuboSilbo", Shape = Enum.PartType.Cylinder, Size = V3(6 + k, 0.9, 0.9), CFrame = CFrame.new(at + V3(math.cos(a) * 1.8, 38 + k * 0.5, math.sin(a) * 1.8)) * CFrame.Angles(0, 0, math.pi / 2), Color = rgb(200, 190, 150), Material = Enum.Material.Metal, Parent = model })
		end
		local tip = Builder.decor({ Name = "Luz", Shape = Enum.PartType.Ball, Size = Vector3.one * 1.8, CFrame = CFrame.new(at + V3(0, 46, 0)), Color = C.Rim, Material = Enum.Material.Neon, Parent = model })
		glow(tip, C.Rim, 30, 1.2)
		return base
	elseif p.Id == "Miasma_Pecio" then
		local hull = Builder.part({ Name = "Gondola", Size = V3(12, 7, 9), CFrame = CFrame.new(at + V3(0, 3, 0)) * CFrame.Angles(0.2, 0.5, 0.3), Color = C.Balloon[2], Material = Enum.Material.WoodPlanks, Parent = model })
		Builder.decor({ Name = "GloboCaido", Shape = Enum.PartType.Ball, Size = V3(18, 3, 14), CFrame = CFrame.new(at + V3(8, 1.2, 4)), Color = C.Balloon[1], Material = Enum.Material.Fabric, Parent = model })
		Builder.decor({ Name = "Panuelo", Size = V3(0.2, 2, 1.2), CFrame = hull.CFrame * CFrame.new(6.1, 0, 0), Color = C.Fabric[5], Material = Enum.Material.Fabric, Parent = model })
		return hull
	elseif p.Id == "Miasma_Lago" then
		local pool = Builder.part({ Name = "Acido", Shape = Enum.PartType.Cylinder, Size = V3(0.6, 50, 50), CFrame = CFrame.new(at + V3(0, 0.4, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color = rgb(150, 255, 90), Material = Enum.Material.Neon, Transparency = 0.25, CanCollide = false, Parent = model })
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2
			Builder.decor({ Name = "Cristal", Size = V3(1.6, 3 + (k % 3), 1.6), CFrame = CFrame.new(at + V3(math.cos(a) * 27, 1.5, math.sin(a) * 27)) * CFrame.Angles(0.3, a, 0.2), Color = rgb(170, 255, 200), Material = Enum.Material.Glass, Transparency = 0.2, Parent = model })
		end
		glow(pool, rgb(150, 255, 90), 40, 1)
		return pool
	end
	return nil
end

-- El mar de niebla: capas de bruma verde sobre el «agua» y humo que se arrastra
function MiasmaKit.world(folder: Instance, S: any)
	local m = Instance.new("Model")
	m.Name = "MarDeNiebla"
	m.Parent = folder
	local y = S.Origin.Y + S.WaterY
	local step = 760
	local n = 0
	for ix = -1, 1 do
		for iz = -1, 1 do
			n += 1
			Builder.decor({
				Name = "Bruma",
				Size = V3(step, 1, step),
				CFrame = CFrame.new(S.Origin.X + ix * step, y + 10 + (n % 3) * 6, S.Origin.Z + iz * step),
				Color = rgb(150, 200, 80),
				Material = Enum.Material.SmoothPlastic,
				Transparency = 0.78,
				CastShadow = false,
				Parent = m,
			})
		end
	end
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		local src = Builder.decor({ Name = "Vaho", Size = V3(4, 1, 4), CFrame = CFrame.new(S.Origin.X + math.cos(a) * 420, y + 4, S.Origin.Z + math.sin(a) * 420), Transparency = 1, CastShadow = false, Parent = m })
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Rate = 2
		e.Lifetime = NumberRange.new(14, 20)
		e.Speed = NumberRange.new(3, 6)
		e.SpreadAngle = Vector2.new(80, 80)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 30), NumberSequenceKeypoint.new(1, 90) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.85), NumberSequenceKeypoint.new(0.5, 0.7), NumberSequenceKeypoint.new(1, 1) })
		e.Color = ColorSequence.new(rgb(170, 210, 90), rgb(120, 160, 70))
		e.Parent = src
	end
end

return MiasmaKit
