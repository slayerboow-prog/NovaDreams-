-- SirocoKit (servidor): cómo se VE Siroco (docs/planetas/diseno-mundos.md §3.2; marco común:
-- docs/planetas/marco-planetas.md). El kit que usan World/PlanetCityBuilder (el barrio de Puerto Calcina) y
-- World/PlanetWorld (la flora, los puntos de interés y el desierto).
--
-- Puerto Calcina NO es Bastión Ceniza: adobe rojo de cantos redondeados, excavado en las paredes del
-- cañón, remendado con chapa y lleno de toldos de colores, antenas y farolillos. La Recta es una calle-
-- circuito con bordillos rojos y blancos que pasa bajo el Arco del Campeón (los nombres tallados de los
-- ganadores; el de Rafa, tachado). Veleros de arena en el Muelle, deslizadores aparcados, bidones de
-- agua, cactus de agua. Fuera: dunas, cactus, árboles de vidrio de tormenta, chatarra, el Cementerio de
-- Deslizadores y la Esfinge Ciega. Todo con piezas (sin mallas nuevas).

local Builder = require(script.Parent.Builder)

local SirocoKit = {}

local V3 = Vector3.new
local rgb = Color3.fromRGB

local C = {
	Adobe = { rgb(186, 104, 70), rgb(198, 120, 80), rgb(172, 96, 66), rgb(206, 138, 92) },
	AdobeLight = rgb(226, 170, 120),
	Road = rgb(84, 62, 56),
	Curb1 = rgb(210, 60, 50),
	Curb2 = rgb(240, 236, 226),
	Tile = rgb(196, 140, 100),
	Iron = rgb(60, 50, 46),
	Tin = rgb(150, 140, 130),
	Rust = rgb(150, 90, 60),
	Fabric = { rgb(220, 70, 60), rgb(240, 170, 40), rgb(40, 150, 170), rgb(230, 230, 220), rgb(160, 60, 120), rgb(80, 160, 90) },
	Lamp = rgb(255, 196, 120),
	Water = rgb(80, 150, 200),
	Cactus = rgb(98, 140, 78),
	Glass = rgb(150, 210, 230),
	Stone = rgb(200, 160, 120),
}
SirocoKit.Colors = {
	Metal = C.Iron,
	Lamp = C.Lamp,
	Floor = C.Tile,
	FloorMaterial = Enum.Material.Sandstone,
	Light = rgb(255, 200, 140),
	Sign = rgb(60, 30, 24),
	SignText = rgb(255, 214, 140),
	Pad = rgb(176, 136, 110),
	PadRing = rgb(255, 150, 70),
	PadLight = rgb(255, 214, 160),
	Poi = rgb(150, 100, 70),
	PoiLight = rgb(255, 196, 120),
}

local function rngOf(seed: number): () -> number
	local s = math.floor(math.abs(seed)) % 2147483647 + 1
	return function()
		s = (s * 16807) % 2147483647
		return s / 2147483647
	end
end

local function glow(part: BasePart, color: Color3, range: number, brightness: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = part
end

local function cable(parent: Instance, a: Vector3, b: Vector3, thick: number?, color: Color3?)
	local len = (b - a).Magnitude
	if len < 0.5 then
		return
	end
	Builder.decor({ Name = "Cuerda", Size = V3(thick or 0.2, thick or 0.2, len), CFrame = CFrame.lookAt((a + b) / 2, b), Color = color or C.Iron, Material = Enum.Material.Fabric, Parent = parent })
end

-- Un toldo de tela (inclinado) delante de una fachada
local function awning(parent: Instance, cf: CFrame, w: number, color: Color3)
	Builder.decor({ Name = "Toldo", Size = V3(w, 0.25, 4), CFrame = cf * CFrame.Angles(math.rad(18), 0, 0), Color = color, Material = Enum.Material.Fabric, Parent = parent })
	for _, s in { -1, 1 } do
		Builder.decor({ Name = "Vara", Size = V3(0.25, 0.25, 4.2), CFrame = cf * CFrame.new(s * (w / 2 - 0.2), -0.2, 0) * CFrame.Angles(math.rad(18), 0, 0), Color = C.Iron, Material = Enum.Material.Metal, Parent = parent })
	end
end

---------------------------------------------------------------------
-- Suelos: La Recta (circuito con bordillos) y la plaza del Arco (baldosas)
---------------------------------------------------------------------
function SirocoKit.floor(ctx: any, parent: Instance, f: { [string]: any }): boolean
	if f.Road then
		local m = Builder.model(f.Id, parent)
		ctx.box(m, "Calzada", f.X0, f.X1, f.Z0, f.Z1, -0.4, 0.35, C.Road, Enum.Material.Slate)
		-- Bordillos rojos y blancos (tramos de 6 studs) y la línea de salida
		local n = 0
		for z = f.Z0, f.Z1 - 6, 6 do
			n += 1
			local color = if n % 2 == 0 then C.Curb1 else C.Curb2
			ctx.box(m, "Bordillo", f.X0 - 1.2, f.X0, z, z + 6, 0, 0.7, color, Enum.Material.SmoothPlastic, true)
			ctx.box(m, "Bordillo", f.X1, f.X1 + 1.2, z, z + 6, 0, 0.7, color, Enum.Material.SmoothPlastic, true)
		end
		for k = 0, 7 do
			ctx.box(m, "Salida", f.X0 + k * 3, f.X0 + k * 3 + 1.5, f.Z0 + 4, f.Z0 + 5.5, 0.35, 0.4, if k % 2 == 0 then C.Curb2 else rgb(20, 20, 20), Enum.Material.SmoothPlastic, true)
		end
		-- Marcas de frenada (negro gastado)
		for k, z in { -60, 10, 96, 150 } do
			ctx.box(m, "Frenada", -3 + k, -2.2 + k, z, z + 14, 0.35, 0.38, rgb(40, 32, 30), Enum.Material.SmoothPlastic, true)
		end
		return true
	elseif f.Plaza then
		local m = Builder.model(f.Id, parent)
		ctx.box(m, "Plaza", f.X0, f.X1, f.Z0, f.Z1, -0.4, 0.5, C.Tile, Enum.Material.Sandstone)
		-- Un mosaico de agua (redondo) en el centro, a los pies del Arco
		ctx.column(m, "Mosaico", ctx.W((f.X0 + f.X1) / 2, (f.Z0 + f.Z1) / 2 + 12, 0.5), 0.06, 16, rgb(60, 130, 160), Enum.Material.Glass, true)
		return true
	end
	return false
end

-- El Pozo del Silencio: un brocal de adobe y una polea (y el agujero, el del terreno)
function SirocoKit.pit(ctx: any, parent: Instance, p: { [string]: any })
	if p.Kind ~= "Disc" then
		return
	end
	local m = Builder.model(p.Id or "Pozo", parent)
	local n = 10
	for k = 0, n - 1 do
		local a = k / n * math.pi * 2
		local x, z = p.X + math.cos(a) * (p.R + 0.6), p.Z + math.sin(a) * (p.R + 0.6)
		Builder.part({ Name = "Brocal", Size = V3(1.2, 2.6, 3), CFrame = CFrame.new(ctx.W(x, z, 1.3)) * CFrame.Angles(0, -a, 0), Color = C.AdobeLight, Material = Enum.Material.Sandstone, Parent = m })
	end
	for _, s in { -1, 1 } do
		ctx.column(m, "Poste", ctx.W(p.X + s * (p.R + 0.6), p.Z, 2.6), 5, 0.5, C.Iron, Enum.Material.Wood, true)
	end
	ctx.box(m, "Polea", p.X - p.R - 0.6, p.X + p.R + 0.6, p.Z - 0.2, p.Z + 0.2, 7.4, 7.8, C.Iron, Enum.Material.Wood, true)
end

---------------------------------------------------------------------
-- Farolas: un farolillo de hierro colgado de un poste curvo (luz cálida)
---------------------------------------------------------------------
function SirocoKit.lamp(ctx: any, parent: Instance, cf: CFrame)
	local m = Builder.model("StreetLamp", parent)
	Builder.part({ Name = "Pie", Size = V3(1.4, 1, 1.4), CFrame = cf * CFrame.new(0, 0.5, 0), Color = C.AdobeLight, Material = Enum.Material.Sandstone, Parent = m })
	Builder.part({ Name = "Poste", Size = V3(0.45, 9, 0.45), CFrame = cf * CFrame.new(0, 5.5, 0), Color = C.Iron, Material = Enum.Material.Metal, Parent = m })
	Builder.decor({ Name = "Brazo", Size = V3(0.3, 0.3, 2.4), CFrame = cf * CFrame.new(0, 9.8, -1), Color = C.Iron, Material = Enum.Material.Metal, Parent = m })
	local bulb = Builder.decor({ Name = "Farolillo", Size = V3(1.2, 1.6, 1.2), CFrame = cf * CFrame.new(0, 9, -2), Color = C.Lamp, Material = Enum.Material.SmoothPlastic, Tags = { "StreetLamp" }, Parent = m })
	local l = Instance.new("PointLight")
	l.Color = C.Lamp
	l.Range = 24
	l.Brightness = 1.5
	l.Shadows = false
	l.Enabled = false
	l.Parent = bulb
	return m
end

---------------------------------------------------------------------
-- Lo que se añade a los edificios Box (Kit/Building): toldos, antenas, depósitos de agua, chapas
---------------------------------------------------------------------
function SirocoKit.dressBox(ctx: any, model: Model, b: { [string]: any }, cf: CFrame, info: { Top: number, GroundTop: number })
	local w, d = b.W or 20, b.D or 20
	local top = info.Top
	local r = rngOf(b.X * 7 + b.Z * 3)
	-- Toldo de colores sobre la puerta (el sol de Siroco no perdona)
	awning(model, cf * CFrame.new(0, info.GroundTop - 0.6, -d / 2 - 2), math.min(w * 0.6, 12), C.Fabric[1 + math.floor(r() * #C.Fabric)])
	-- Pretil redondeado en lo alto (adobe) y un bidón de agua con antena en el tejado
	Builder.decor({ Name = "Pretil", Size = V3(w + 0.4, 1.2, d + 0.4), CFrame = cf * CFrame.new(0, top + 0.6, 0), Color = C.AdobeLight, Material = Enum.Material.Sandstone, Parent = model })
	Builder.decor({ Name = "Hueco", Size = V3(w - 1.6, 1.4, d - 1.6), CFrame = cf * CFrame.new(0, top + 0.75, 0), Color = rgb(120, 70, 50), Material = Enum.Material.Sandstone, Parent = model })
	local tank = Builder.decor({ Name = "Bidon", Shape = Enum.PartType.Cylinder, Size = V3(3, 3.4, 3.4), CFrame = cf * CFrame.new(w * 0.25, top + 2.2, d * 0.15) * CFrame.Angles(0, 0, math.pi / 2), Color = C.Water, Material = Enum.Material.Metal, Parent = model })
	local _ = tank
	Builder.decor({ Name = "Antena", Size = V3(0.3, 7, 0.3), CFrame = cf * CFrame.new(-w * 0.3, top + 4, -d * 0.2), Color = C.Iron, Material = Enum.Material.Metal, Parent = model })
	Builder.decor({ Name = "Plato", Shape = Enum.PartType.Cylinder, Size = V3(0.3, 3, 3), CFrame = cf * CFrame.new(-w * 0.3, top + 6.6, -d * 0.2) * CFrame.Angles(0, 0.6, 0.5), Color = C.Tin, Material = Enum.Material.Metal, Parent = model })
	if b.Style == "SirocoChatarra" then
		-- Chapas onduladas remendadas y una franja de pintura de escudería
		for k = 1, 3 do
			Builder.decor({ Name = "Chapa", Size = V3(3 + r() * 3, 2.5 + r() * 2, 0.25), CFrame = cf * CFrame.new((r() - 0.5) * w * 0.7, 3 + r() * math.max(1, top - 8), -d / 2 - 0.15), Color = if k % 2 == 0 then C.Rust else C.Tin, Material = Enum.Material.CorrodedMetal, Parent = model })
		end
		Builder.decor({ Name = "Franja", Size = V3(w, 0.8, 0.2), CFrame = cf * CFrame.new(0, top - 1.4, -d / 2 - 0.3), Color = if b.Id == "Siroco_BoxHierro" then rgb(40, 40, 46) else C.Fabric[3], Material = Enum.Material.SmoothPlastic, Parent = model })
	end
end

---------------------------------------------------------------------
-- Formas propias
---------------------------------------------------------------------
SirocoKit.Shapes = {}

-- Un puesto del zoco: mostrador, toldo y género (bidones, piezas, telas)
function SirocoKit.Shapes.Puesto(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local yaw = ({ N = 0, S = math.pi, E = -math.pi / 2, W = math.pi / 2 })[b.Face or "E"]
	local cf = ctx.CF(b.X, b.Z, 0.9, yaw)
	local w = b.W or 8
	local counter = Builder.part({ Name = "Mostrador", Size = V3(w, 3.2, 2), CFrame = cf * CFrame.new(0, 1.6, -1), Color = rgb(130, 90, 60), Material = Enum.Material.WoodPlanks, Parent = m })
	for _, s in { -1, 1 } do
		Builder.decor({ Name = "Poste", Size = V3(0.4, 7.4, 0.4), CFrame = cf * CFrame.new(s * (w / 2 - 0.3), 3.7, 2), Color = C.Iron, Material = Enum.Material.Wood, Parent = m })
	end
	Builder.decor({ Name = "Toldo", Size = V3(w + 1, 0.25, 5.4), CFrame = cf * CFrame.new(0, 7.3, 0.2) * CFrame.Angles(math.rad(-10), 0, 0), Color = C.Fabric[2], Material = Enum.Material.Fabric, Parent = m })
	for k = -1, 1 do
		Builder.decor({ Name = "Genero", Shape = Enum.PartType.Cylinder, Size = V3(1.4, 1.2, 1.2), CFrame = cf * CFrame.new(k * (w / 3), 3.9, -1) * CFrame.Angles(0, 0, math.pi / 2), Color = if k == 0 then C.Water else C.Rust, Material = Enum.Material.Metal, Parent = m })
	end
	m.PrimaryPart = counter
	return m
end

-- Casas en la roca (las Gradas): tres o cuatro casitas de adobe apiladas contra la pared del cañón, con
-- puertas, ventanas que se encienden de noche, escaleras de mano y balcones de madera
function SirocoKit.Shapes.CasaRoca(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local x0, x1, z0, z1 = ctx.City.footprint(b)
	local face = b.Face or "E"
	local fd = ({ E = { 1, 0 }, W = { -1, 0 }, N = { 0, -1 }, S = { 0, 1 } })[face]
	local h = b.Height or 24
	local r = rngOf(b.X * 3 + b.Z * 11)
	local main = ctx.box(m, "Roca", x0, x1, z0, z1, 0, h, C.Adobe[3], Enum.Material.Sandstone)
	-- Las casitas (cajas que salen de la roca) en dos alturas
	local alongZ = fd[1] ~= 0
	local span = if alongZ then z1 - z0 else x1 - x0
	local n = math.max(2, math.floor(span / 9))
	for level = 0, 1 do
		for k = 0, n - 1 do
			if level == 0 or r() < 0.7 then
				local cw = span / n - 1
				local u = (if alongZ then z0 else x0) + (k + 0.5) * (span / n)
				local depth = 4 + r() * 2
				local y0 = level * 10
				local hh = 8 + r() * 2
				local fx = if alongZ then (if fd[1] > 0 then x1 else x0 - depth) else u - cw / 2
				local fx1 = if alongZ then (if fd[1] > 0 then x1 + depth else x0) else u + cw / 2
				local fz = if alongZ then u - cw / 2 else (if fd[2] > 0 then z1 else z0 - depth)
				local fz1 = if alongZ then u + cw / 2 else (if fd[2] > 0 then z1 + depth else z0)
				if level == 1 then
					-- (la de arriba, metida en la roca: no sale por encima de la calle)
					fx, fx1 = if alongZ then (if fd[1] > 0 then x1 - 2 else x0 - depth + 2) else fx, if alongZ then (if fd[1] > 0 then x1 + depth - 2 else x0 + 2) else fx1
				end
				local color = C.Adobe[1 + math.floor(r() * #C.Adobe)]
				ctx.box(m, "Casita", fx, fx1, fz, fz1, y0, y0 + hh, color, Enum.Material.Sandstone)
				-- Puerta y ventana (de noche, con luz)
				local cx, cz = (fx + fx1) / 2 + fd[1] * ((fx1 - fx) / 2 + 0.1), (fz + fz1) / 2 + fd[2] * ((fz1 - fz) / 2 + 0.1)
				local doorCF = Builder.facing(ctx.W(cx, cz, y0 + 3), V3(fd[1], 0, fd[2]))
				Builder.decor({ Name = "Puerta", Size = V3(2.6, 5, 0.2), CFrame = doorCF * CFrame.new(-cw * 0.2, 0, 0), Color = C.Fabric[1 + math.floor(r() * #C.Fabric)], Material = Enum.Material.Fabric, Parent = m })
				local win = Builder.decor({ Name = "Ventana", Size = V3(1.8, 1.6, 0.2), CFrame = doorCF * CFrame.new(cw * 0.22, 1.5, 0), Color = rgb(70, 40, 30), Material = Enum.Material.Glass, Parent = m })
				win:AddTag("NightWindow")
				win:SetAttribute("DayColor", rgb(70, 40, 30))
				win:SetAttribute("NightColor", rgb(255, 190, 110))
				win:SetAttribute("OnAt", 17.8 + r() * 2)
				win:SetAttribute("OffAt", 23 + r() * 3)
				if level == 1 then
					-- Balcón de madera con barandilla
					Builder.decor({ Name = "Balcon", Size = V3(cw * 0.7, 0.4, 2.4), CFrame = doorCF * CFrame.new(0, -2.8, -1.2), Color = rgb(120, 80, 50), Material = Enum.Material.WoodPlanks, Parent = m })
				end
			end
		end
	end
	-- Una escalera de mano y una cuerda de banderines de un lado a otro
	local ux = if alongZ then (if fd[1] > 0 then x1 + 6 else x0 - 6) else (x0 + x1) / 2
	local uz = if alongZ then (z0 + z1) / 2 else (if fd[2] > 0 then z1 + 6 else z0 - 6)
	Builder.decor({ Name = "Escalera", Size = V3(1.6, 12, 0.3), CFrame = Builder.facing(ctx.W(ux - fd[1] * 1.5, uz - fd[2] * 1.5, 6), V3(fd[1], 0, fd[2])) * CFrame.Angles(math.rad(-12), 0, 0), Color = rgb(130, 90, 60), Material = Enum.Material.Wood, Parent = m })
	m.PrimaryPart = main
	Builder.streamable(m)
	return m
end

-- La fuente de Pozo Hondo: una pila redonda de adobe, el caño y el agua (poca)
function SirocoKit.Shapes.Fuente(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local r = b.R or 6
	local basin = ctx.column(m, "Pila", ctx.W(b.X, b.Z, 0.9), 2.4, r * 2, C.AdobeLight, Enum.Material.Sandstone)
	ctx.column(m, "Agua", ctx.W(b.X, b.Z, 3.0), 0.3, r * 2 - 1.4, C.Water, Enum.Material.Glass, true).Transparency = 0.2
	local spout = ctx.column(m, "Cano", ctx.W(b.X, b.Z, 3.3), 5, 1.6, C.Stone, Enum.Material.Sandstone)
	Builder.decor({ Name = "Chorro", Size = V3(0.3, 2.2, 0.3), CFrame = CFrame.new(ctx.W(b.X + 1, b.Z, 6.6)), Color = C.Water, Material = Enum.Material.Glass, Transparency = 0.4, Parent = m })
	-- La cola de bidones
	for k = 0, 5 do
		ctx.column(m, "Bidon", ctx.W(b.X - r - 2 - k * 2.4, b.Z - 4, 0.9), 2.4, 1.8, if k % 2 == 0 then C.Water else rgb(200, 190, 170), Enum.Material.Metal, true)
	end
	local _ = spout
	m.PrimaryPart = basin
	return m
end

---------------------------------------------------------------------
-- Material del planeta para recoger
---------------------------------------------------------------------
function SirocoKit.gather(ctx: any, parent: Instance, g: { [string]: any })
	if g.Item == "AguaFresca" then
		local body = ctx.column(parent, "Cactus", ctx.W(g.X, g.Z, 0.9), 6, 3, C.Cactus, Enum.Material.Grass, true)
		local _ = body
		ctx.ball(parent, "Cabeza", ctx.W(g.X, g.Z, 7), 3.2, C.Cactus, Enum.Material.Grass, true)
		for _, s in { -1, 1 } do
			ctx.ball(parent, "Brazo", ctx.W(g.X + s * 2.2, g.Z, 4.4), 1.8, C.Cactus, Enum.Material.Grass, true)
		end
		ctx.ball(parent, "Flor", ctx.W(g.X, g.Z, 8.6), 1, rgb(255, 120, 160), Enum.Material.Neon, true)
	elseif g.Item == "SalRocio" then
		for k = 0, 4 do
			ctx.box(parent, "Sal", g.X - 1 + k * 0.6, g.X + k * 0.6, g.Z - 0.6 + (k % 2), g.Z + 0.6 + (k % 2), 0.9, 1.6 + (k % 3) * 0.4, rgb(240, 236, 228), Enum.Material.Salt, true)
		end
	else
		for k = 0, 3 do
			ctx.box(parent, "Chatarra", g.X - 2 + k, g.X + k, g.Z - 1, g.Z + 1, 0.9, 1.6 + k * 0.4, if k % 2 == 0 then C.Rust else C.Tin, Enum.Material.CorrodedMetal, true)
		end
	end
end

---------------------------------------------------------------------
-- Lo propio de Puerto Calcina: el Arco del Campeón, banderines sobre La Recta, deslizadores, veleros de
-- arena, bidones y los cables de farolillos
---------------------------------------------------------------------
function SirocoKit.extras(ctx: any, model: Model)
	local W = ctx.W
	local City = ctx.City
	local m = Builder.model("Calcina", model)
	-- El Arco del Campeón (dos pilares y un dintel con los nombres; uno, tachado)
	local a = City.SpotById.Arco
	if a then
		for _, s in { -1, 1 } do
			ctx.box(m, "Pilar", a.X + s * 18 - 3, a.X + s * 18 + 3, a.Z - 3, a.Z + 3, 0.5, 24, C.Stone, Enum.Material.Sandstone)
			ctx.box(m, "Capitel", a.X + s * 18 - 3.8, a.X + s * 18 + 3.8, a.Z - 3.8, a.Z + 3.8, 24, 25.4, C.AdobeLight, Enum.Material.Sandstone)
		end
		ctx.box(m, "Dintel", a.X - 22, a.X + 22, a.Z - 3, a.Z + 3, 25.4, 31, C.Stone, Enum.Material.Sandstone)
		local names = Builder.decor({ Name = "Nombres", Size = V3(36, 4.6, 0.3), CFrame = CFrame.new(W(a.X, a.Z - 3.2, 28.2)) * CFrame.Angles(0, math.pi, 0), Color = C.Stone, Material = Enum.Material.Sandstone, Parent = m })
		Builder.sign(names, "GRAN VUELTA · VIENTOALTO · A. DUNA · R. QUIROGA · HIERRO", Enum.NormalId.Front, rgb(110, 60, 40))
		Builder.decor({ Name = "Tachado", Size = V3(7, 0.5, 0.2), CFrame = CFrame.new(W(a.X + 5.5, a.Z - 3.5, 28.2)) * CFrame.Angles(0, 0, 0.15), Color = rgb(60, 20, 20), Material = Enum.Material.SmoothPlastic, Parent = m })
		-- Flores frescas bajo el nombre tachado (el gancho de «El copiloto»)
		for k = 0, 2 do
			ctx.ball(m, "Flor", W(a.X + 15 + k * 0.8, a.Z - 4, 0.9), 0.8, C.Fabric[1 + (k * 2) % #C.Fabric], Enum.Material.Neon, true)
		end
	end
	-- Banderines de colores cruzando La Recta (con farolillos que se encienden de noche)
	for _, z in { -80, -20, 90, 150 } do
		local from, to = W(-20, z, 12), W(20, z, 12)
		cable(m, from, to, 0.15)
		for k = 1, 9 do
			local p = from:Lerp(to, k / 10) - V3(0, math.sin(k / 10 * math.pi) * 1.2, 0)
			local flag = Builder.decor({ ClassName = "WedgePart", Name = "Banderin", Size = V3(0.1, 1.4, 1.2), CFrame = CFrame.new(p - V3(0, 0.8, 0)) * CFrame.Angles(math.pi, 0, 0), Color = C.Fabric[1 + k % #C.Fabric], Material = Enum.Material.Fabric, Parent = m })
			local _ = flag
		end
		for _, x in { -20, 20 } do
			ctx.box(m, "PosteBanderin", x - 0.25, x + 0.25, z - 0.25, z + 0.25, 0.9, 12.4, C.Iron, Enum.Material.Metal, true)
		end
	end
	-- Deslizadores aparcados delante de los Boxes (cuñas y una cabina)
	for k, p in { { 30, -60 }, { 30, -24 }, { 32, 12 }, { 30, 70 } } do
		local cf = ctx.CF(p[1], p[2], 1.6, 0)
		Builder.part({ ClassName = "WedgePart", Name = "Deslizador", Size = V3(4, 1.6, 8), CFrame = cf * CFrame.Angles(0, math.pi, 0), Color = C.Fabric[k], Material = Enum.Material.Metal, Parent = m })
		Builder.decor({ Name = "Cola", Size = V3(4.4, 1.2, 2), CFrame = cf * CFrame.new(0, 0, 4.4), Color = C.Iron, Material = Enum.Material.Metal, Parent = m })
		Builder.decor({ Name = "Cabina", Shape = Enum.PartType.Ball, Size = V3(2.4, 1.6, 3), CFrame = cf * CFrame.new(0, 1, 1), Color = rgb(40, 60, 70), Material = Enum.Material.Glass, Parent = m })
	end
	-- Los veleros de arena del Muelle de Velas (casco sobre patines, mástil y vela)
	for k, p in { { 66, -160 }, { 90, -150 }, { -70, -156 } } do
		local cf = ctx.CF(p[1], p[2], 1.4, 0.2 * k)
		Builder.part({ Name = "Casco", Size = V3(4, 1.6, 12), CFrame = cf, Color = rgb(150, 100, 60), Material = Enum.Material.WoodPlanks, Parent = m })
		for _, s in { -1, 1 } do
			Builder.decor({ Name = "Patin", Size = V3(0.4, 0.4, 13), CFrame = cf * CFrame.new(s * 2.6, -0.9, 0), Color = C.Iron, Material = Enum.Material.Metal, Parent = m })
		end
		Builder.decor({ Name = "Mastil", Size = V3(0.5, 16, 0.5), CFrame = cf * CFrame.new(0, 8.6, -1), Color = rgb(120, 80, 50), Material = Enum.Material.Wood, Parent = m })
		Builder.decor({ ClassName = "WedgePart", Name = "Vela", Size = V3(0.2, 13, 8), CFrame = cf * CFrame.new(0, 8.6, 2.6), Color = C.Fabric[(k % #C.Fabric) + 1], Material = Enum.Material.Fabric, Parent = m })
	end
	-- Bidones de agua y cajas por el Zoco y Pozo Hondo
	for k, p in { { -40, -44 }, { -38, -40 }, { -64, 40 }, { -40, 110 }, { -44, 112 }, { 40, -30 }, { 74, 100 } } do
		ctx.column(m, "Bidon", W(p[1], p[2], 0.9), 2.6, 2, if k % 2 == 0 then C.Water else C.Rust, Enum.Material.Metal)
	end
	-- Un cable de farolillos de colores entre las casas de la roca y la plaza
	local from, to = W(-110, 60, 16), W(-36, 40, 10)
	cable(m, from, to, 0.12)
	for k = 1, 7 do
		local p = from:Lerp(to, k / 8) - V3(0, math.sin(k / 8 * math.pi) * 1.4, 0)
		local bulb = ctx.ball(m, "Farolillo", p, 0.8, C.Fabric[1 + k % #C.Fabric], Enum.Material.Neon, true)
		if k == 4 then
			glow(bulb, rgb(255, 200, 140), 14, 0.8)
		end
	end
end

---------------------------------------------------------------------
-- Fuera del barrio
---------------------------------------------------------------------
function SirocoKit.decor(folder: Instance, d: { [string]: any })
	local r = rngOf(d.Pos.X * 3 + d.Pos.Z)
	if d.Kind == "Cactus" then
		local h = 4 + d.Size * 0.4
		Builder.decor({ Name = "Cactus", Shape = Enum.PartType.Cylinder, Size = V3(h, 1.8, 1.8), CFrame = CFrame.new(d.Pos + V3(0, h / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color = C.Cactus, Material = Enum.Material.Grass, Parent = folder })
		Builder.decor({ Name = "Copa", Shape = Enum.PartType.Ball, Size = Vector3.one * 2, CFrame = CFrame.new(d.Pos + V3(0, h, 0)), Color = C.Cactus, Material = Enum.Material.Grass, Parent = folder })
		if d.Roll < 0.6 then
			Builder.decor({ Name = "Brazo", Shape = Enum.PartType.Ball, Size = V3(1.4, 2.6, 1.4), CFrame = CFrame.new(d.Pos + V3(1.4, h * 0.6, 0)), Color = C.Cactus, Material = Enum.Material.Grass, Parent = folder })
		end
	elseif d.Kind == "Roca" then
		Builder.part({ Name = "Roca", Shape = Enum.PartType.Ball, Size = V3(d.Size, d.Size * 0.7, d.Size), CFrame = CFrame.new(d.Pos + V3(0, d.Size * 0.15, 0)), Color = if d.Roll < 0.5 then rgb(160, 84, 58) else rgb(186, 120, 80), Material = Enum.Material.Sandstone, Parent = folder })
	elseif d.Kind == "Vidrio" then
		-- Árbol de vidrio de tormenta: ramas de cristal azul que salen de la arena
		for k = 0, 3 do
			local a = d.Turn + k * 1.6
			local hh = 3 + r() * 4
			Builder.decor({ Name = "Vidrio", Size = V3(1, hh, 1), CFrame = CFrame.new(d.Pos + V3(math.cos(a) * 0.8, hh * 0.45, math.sin(a) * 0.8)) * CFrame.Angles(math.cos(a) * 0.5, a, math.sin(a) * 0.5), Color = C.Glass, Material = Enum.Material.Glass, Transparency = 0.25, Parent = folder })
		end
	elseif d.Kind == "Chatarra" then
		Builder.part({ ClassName = "WedgePart", Name = "Chatarra", Size = V3(3, 1.4, 5), CFrame = CFrame.new(d.Pos + V3(0, 0.5, 0)) * CFrame.Angles(0.2, d.Turn, 0.3), Color = if d.Roll < 0.5 then C.Rust else C.Tin, Material = Enum.Material.CorrodedMetal, Parent = folder })
	end
end

function SirocoKit.poi(model: Instance, p: { [string]: any }, at: Vector3): BasePart?
	if p.Id == "Siroco_Cementerio" then
		local main: BasePart? = nil
		local r = rngOf(at.X)
		for k = 0, 13 do
			local a = k / 14 * math.pi * 2
			local d = 10 + r() * 28
			local part = Builder.part({ ClassName = if k % 2 == 0 then "WedgePart" else "Part", Name = "Deslizador", Size = V3(4, 1.8, 8), CFrame = CFrame.new(at + V3(math.cos(a) * d, 1 + r() * 2, math.sin(a) * d)) * CFrame.Angles(r() - 0.5, r() * 6, r() - 0.5), Color = if k % 3 == 0 then C.Rust else C.Fabric[1 + k % #C.Fabric], Material = Enum.Material.CorrodedMetal, Parent = model })
			main = main or part
		end
		return main
	elseif p.Id == "Siroco_Esfinge" then
		-- Una estatua tumbada de bloques de arenisca, con una venda de piedra sobre los ojos
		local body = Builder.part({ Name = "Cuerpo", Size = V3(16, 10, 34), CFrame = CFrame.new(at + V3(0, 5, 6)), Color = C.Stone, Material = Enum.Material.Sandstone, Parent = model })
		local head = Builder.part({ Name = "Cabeza", Size = V3(12, 12, 10), CFrame = CFrame.new(at + V3(0, 14, -12)), Color = C.Stone, Material = Enum.Material.Sandstone, Parent = model })
		Builder.decor({ Name = "Venda", Size = V3(12.4, 2.4, 10.4), CFrame = head.CFrame * CFrame.new(0, 1.5, 0), Color = rgb(150, 110, 80), Material = Enum.Material.Sandstone, Parent = model })
		for _, s in { -1, 1 } do
			Builder.part({ Name = "Pata", Size = V3(4, 4, 14), CFrame = CFrame.new(at + V3(s * 5, 2, -20)), Color = C.Stone, Material = Enum.Material.Sandstone, Parent = model })
		end
		return body
	elseif p.Id == "Siroco_Salinas" then
		local post = Builder.part({ Name = "Hito", Size = V3(2, 6, 2), CFrame = CFrame.new(at + V3(0, 3, 0)), Color = C.Curb2, Material = Enum.Material.SmoothPlastic, Parent = model })
		Builder.decor({ Name = "Banda", Size = V3(2.1, 1, 2.1), CFrame = CFrame.new(at + V3(0, 4.4, 0)), Color = C.Curb1, Material = Enum.Material.SmoothPlastic, Parent = model })
		return post
	end
	return nil
end

-- El desierto: remolinos de polvo que corren por las dunas
function SirocoKit.world(folder: Instance, S: any)
	local m = Instance.new("Model")
	m.Name = "Desierto"
	m.Parent = folder
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2 + 0.5
		local x, z = S.Origin.X + math.cos(a) * 520, S.Origin.Z + math.sin(a) * 520
		local src = Builder.decor({ Name = "Remolino", Size = V3(4, 1, 4), CFrame = CFrame.new(x, S.heightAt(x, z) + 2, z), Transparency = 1, CastShadow = false, Parent = m })
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Rate = 3
		e.Lifetime = NumberRange.new(4, 7)
		e.Speed = NumberRange.new(6, 12)
		e.SpreadAngle = Vector2.new(20, 20)
		e.RotSpeed = NumberRange.new(90, 200)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(1, 18) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
		e.Color = ColorSequence.new(rgb(220, 150, 100), rgb(180, 110, 70))
		e.Parent = src
	end
end

return SirocoKit
