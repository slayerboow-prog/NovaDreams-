-- PuertoKit: las piezas del Puerto de Valmar (Kit/Puerto las coloca según shared/Port/PuertoPlan).
--
-- Todo con piezas (funciona sin subir nada). Los cuatro objetos «estrella» (grúa pórtico, contenedor,
-- tetrápodo y bolardo) llevan la etiqueta PuertoMalla con su Kind: cuando estén subidas sus mallas de
-- Blender (scripts/puerto/puerto_blender.py + scripts/upload-puerto.sh -> shared/Port/PuertoAssetIds),
-- World/PuertoMeshes pone la malla y esconde las piezas (las colisiones se quedan).
--
--   PuertoKit.container(parent, cf, long, color, marks?)   contenedor de 20 o 40 pies (cf = centro de la base)
--   PuertoKit.crane(parent, x, plan)                       grúa pórtico de muelle (STS) con pluma de celosía
--   PuertoKit.ship(parent, plan)                           buque portacontenedores amarrado (proa al oeste)
--   PuertoKit.fishingBoat / sailboat / tug / ferry         barcos amarrados
--   PuertoKit.bollard / fender / tyre / ladder / tetrapod  mobiliario del muelle
--   PuertoKit.mast(parent, pos, height)                    torre de iluminación (se enciende de noche)
--   PuertoKit.nave(parent, rect, height, doorsFace, name)  nave (almacén) con puertas enrollables
--   PuertoKit.sign(parent, cf, w, h, text, color)          cartel de pie (con postes)

local Builder = require(script.Parent.Parent.Builder)

local PuertoKit = {}

local rgb = Color3.fromRGB
local V3 = Vector3.new
local CF = CFrame.new

PuertoKit.Colors = {
	Concrete = rgb(176, 172, 164),
	ConcreteDark = rgb(132, 128, 122),
	Apron = rgb(150, 148, 144),
	Asphalt = rgb(62, 64, 68),
	Coping = rgb(232, 196, 40), -- borde de seguridad amarillo
	White = rgb(240, 240, 236),
	Black = rgb(28, 28, 30),
	Rubber = rgb(24, 24, 26),
	Steel = rgb(96, 100, 106),
	CraneBlue = rgb(28, 92, 170),
	CraneWhite = rgb(232, 232, 226),
	Glass = rgb(90, 130, 160),
	Rope = rgb(206, 184, 130),
	Hull = rgb(26, 40, 62),
	Antifouling = rgb(160, 40, 36),
	Wood = rgb(128, 94, 64),
	Float = rgb(40, 42, 46),
	Rock = rgb(118, 114, 108),
	Tetrapod = rgb(186, 182, 172),
	Signal = rgb(20, 70, 130),
}
local C = PuertoKit.Colors

-- Colores de contenedor (sin marcas ni logotipos de navieras reales)
PuertoKit.ContainerColors = {
	rgb(176, 58, 44), rgb(40, 96, 160), rgb(222, 158, 40), rgb(58, 128, 84), rgb(122, 126, 132),
	rgb(228, 228, 222), rgb(126, 70, 136), rgb(204, 108, 40), rgb(24, 70, 110), rgb(146, 40, 40),
	rgb(70, 150, 160), rgb(96, 100, 60),
}

-- Pieza sólida y pieza de adorno (sin colisiones ni consultas)
local function box(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
	local props: { [string]: any } = { Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = parent }
	for k, v in extra or {} do
		props[k] = v
	end
	return Builder.part(props)
end
local function dec(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
	local props: { [string]: any } = { Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = parent }
	for k, v in extra or {} do
		props[k] = v
	end
	return Builder.decor(props)
end
PuertoKit.box = box
PuertoKit.dec = dec

-- Barra recta de `a` a `b` (vigas, tirantes, cabos)
function PuertoKit.bar(parent: Instance, name: string, a: Vector3, b: Vector3, thick: number, color: Color3, material: Enum.Material?, solid: boolean?): BasePart
	local mid, len = (a + b) / 2, (b - a).Magnitude
	local cf = CFrame.lookAt(mid, b + V3(0.0001, 0.0001, 0.0001)) -- (lookAt de Lune falla mirando justo a +Z)
	local size = V3(thick, thick, len)
	if solid then
		return box(parent, name, size, cf, color, material)
	end
	return dec(parent, name, size, cf, color, material)
end
local bar = PuertoKit.bar

-- Cuña en planta: medio casco de proa (triángulo rectángulo visto desde arriba).
-- base = punto del eje del barco donde empieza la proa (centro en altura); dir = +1/-1 en X hacia la punta;
-- side = -1 (lado norte, -Z) o +1 (lado sur); len = largo de la proa; half = media manga; h = alto.
function PuertoKit.bowHalf(parent: Instance, name: string, base: Vector3, dir: number, side: number, len: number, half: number, h: number, color: Color3, solid: boolean?): BasePart
	local vZ = V3(-dir, 0, 0) -- la punta está hacia el -Z local de la cuña
	local vY = V3(0, 0, side) -- el cateto corto (la manga) hacia el costado
	local vX = vY:Cross(vZ)
	local center = base + V3(dir * len / 2, 0, side * half / 2)
	local cf = CFrame.fromMatrix(center, vX, vY, vZ)
	local props = { Name = name, ClassName = "WedgePart", Size = V3(h, half, len), CFrame = cf, Color = color, Parent = parent }
	return if solid then Builder.part(props) else Builder.decor(props)
end

-- Cartel con texto (las dos caras)
function PuertoKit.board(parent: Instance, cf: CFrame, w: number, h: number, text: string, color: Color3, textColor: Color3?): BasePart
	local part = box(parent, "Sign", V3(w, h, 0.4), cf, color)
	Builder.sign(part, text, Enum.NormalId.Front, textColor or C.White, color)
	Builder.sign(part, text, Enum.NormalId.Back, textColor or C.White, color)
	return part
end

-- Cartel de pie, bien plantado: dos postes hasta el suelo y el panel encima. cf = en el suelo, mirando
-- hacia donde se lee.
function PuertoKit.sign(parent: Instance, cf: CFrame, w: number, h: number, text: string, color: Color3?, lift: number?): Model
	local m = Builder.model("Cartel", parent)
	local y = (lift or 2.5) + h / 2
	for _, x in { -w / 2 + 0.8, w / 2 - 0.8 } do
		box(m, "SignPost", V3(0.6, y + h / 2, 0.6), cf * CF(x, (y + h / 2) / 2, 0.4), C.Steel, Enum.Material.Metal)
	end
	PuertoKit.board(m, cf * CF(0, y, 0), w, h, text, color or C.Signal)
	return m
end

---------------------------------------------------------------------
-- Contenedores
---------------------------------------------------------------------

-- Contenedor (cf = centro de la base, el largo a lo largo del X local). long = 34 (40 pies) o 17 (20).
-- marks = código de mentira (sin dueño real) pintado en un costado.
function PuertoKit.container(parent: Instance, cf: CFrame, long: number, color: Color3, marks: string?): BasePart
	local W, H = 6.8, 7.2
	local body = box(parent, "Contenedor", V3(long, H, W), cf * CF(0, H / 2, 0), color, Enum.Material.Metal, {
		Tags = { "PuertoMalla" },
		Attributes = { Kind = if long > 20 then "Contenedor40" else "Contenedor20" },
	})
	-- Largueros de arriba y de abajo (el marco que se ve en un contenedor de verdad)
	local frame = color:Lerp(Color3.new(0, 0, 0), 0.35)
	dec(parent, "ContenedorMarco", V3(long + 0.06, 0.5, W + 0.06), cf * CF(0, H - 0.25, 0), frame, Enum.Material.Metal)
	dec(parent, "ContenedorMarco", V3(long + 0.06, 0.4, W + 0.06), cf * CF(0, 0.2, 0), frame, Enum.Material.Metal)
	if marks then
		local plate = dec(parent, "ContenedorCodigo", V3(9, 1.4, 0.05), cf * CF(long / 2 - 6, H - 1.6, -W / 2 - 0.03), color, Enum.Material.Metal)
		Builder.sign(plate, marks, Enum.NormalId.Front, C.White, nil)
	end
	return body
end

---------------------------------------------------------------------
-- Grúa pórtico de muelle (STS): patas, pórtico con cruces, pluma de celosía sobre el agua,
-- castillete (A) con tirantes, sala de máquinas, carro, cabina y spreader con un contenedor.
---------------------------------------------------------------------

-- plan = PuertoPlan (Ground, CraneRails, CraneSpan, CraneHeight, Boom)
function PuertoKit.crane(parent: Instance, x: number, plan: any, index: number): Model
	local m = Builder.model("GruaPortico", parent)
	Builder.streamable(m)
	m:SetAttribute("Kind", "GruaSTS")
	m:AddTag("PuertoMalla")
	local g = plan.Ground
	local zs, zl = plan.CraneRails.Sea, plan.CraneRails.Land
	local half = plan.CraneSpan / 2
	local top = g + plan.CraneHeight -- viga del pórtico
	local upper = top + 8 -- segunda viga (donde apoya la pluma)
	local boomY = plan.Boom.Y + 1.5
	local blue, white = C.CraneBlue, C.CraneWhite
	-- Patas y bogies sobre los carriles
	for _, z in { zs, zl } do
		for _, s in { -1, 1 } do
			local lx = x + s * half
			box(m, "Pata", V3(2.4, upper - g, 2.4), CF(lx, (g + upper) / 2, z), blue, Enum.Material.Metal)
			dec(m, "Bogie", V3(3.4, 2, 6), CF(lx, g + 1, z), C.Steel, Enum.Material.Metal)
			dec(m, "Franja", V3(2.5, 1.2, 2.5), CF(lx, g + 3.4, z), C.Coping, Enum.Material.SmoothPlastic)
		end
		-- Vigas del pórtico (a lo ancho, a dos alturas)
		box(m, "Portico", V3(plan.CraneSpan + 2.4, 2.6, 2.6), CF(x, top, z), blue, Enum.Material.Metal)
		dec(m, "PorticoAlto", V3(plan.CraneSpan + 2.4, 2, 2), CF(x, upper - 1, z), blue, Enum.Material.Metal)
	end
	for _, s in { -1, 1 } do
		local lx = x + s * half
		-- Largueros entre la pata de tierra y la de mar (abajo y arriba) y cruces de San Andrés
		dec(m, "Larguero", V3(1.8, 1.8, zs - zl), CF(lx, g + 6, (zs + zl) / 2), blue, Enum.Material.Metal)
		box(m, "Larguero", V3(2.4, 2.4, zs - zl), CF(lx, top, (zs + zl) / 2), blue, Enum.Material.Metal)
		bar(m, "Cruz", V3(lx, g + 7, zl), V3(lx, top - 1, zs), 1, blue, Enum.Material.Metal)
		bar(m, "Cruz", V3(lx, g + 7, zs), V3(lx, top - 1, zl), 1, blue, Enum.Material.Metal)
	end
	-- Pluma: dos vigas cajón a lo largo de Z con celosía en los costados (lado tierra = contrapluma)
	local b0, b1 = plan.Boom.Back, plan.Boom.Out
	for _, s in { -1, 1 } do
		local bx = x + s * 5
		box(m, "Pluma", V3(1.8, 3.2, b1 - b0), CF(bx, boomY, (b0 + b1) / 2), white, Enum.Material.Metal)
		dec(m, "PlumaCordon", V3(1, 1, b1 - b0 - 4), CF(bx, boomY + 5, (b0 + b1) / 2 - 2), white, Enum.Material.Metal)
		local z = b0 + 2
		local up = true
		while z + 12 <= b1 - 2 do
			bar(m, "Celosia", V3(bx, boomY + (if up then 1.6 else 5), z), V3(bx, boomY + (if up then 5 else 1.6), z + 12), 0.6, white, Enum.Material.Metal)
			z += 12
			up = not up
		end
	end
	for z = b0 + 6, b1 - 6, 24 do
		dec(m, "PlumaTraviesa", V3(10, 0.8, 0.8), CF(x, boomY + 5, z), white, Enum.Material.Metal)
	end
	-- Castillete en A sobre la pata de mar, con tirantes hasta la punta de la pluma y la contrapluma
	local apex = V3(x, upper + 26, zs - 8)
	for _, s in { -1, 1 } do
		local foot = V3(x + s * half, upper, zs)
		bar(m, "Castillete", foot, apex + V3(s * 3, 0, 0), 1.8, blue, Enum.Material.Metal, true)
		bar(m, "Castillete", V3(x + s * half, upper, zl), apex + V3(s * 3, 0, 0), 1.4, blue, Enum.Material.Metal)
		bar(m, "Tirante", apex + V3(s * 3, 0, 0), V3(x + s * 5, boomY + 5, b1 - 4), 0.5, C.Steel, Enum.Material.Metal)
		bar(m, "Tirante", apex + V3(s * 3, 0, 0), V3(x + s * 5, boomY + 5, (zs + b1) / 2 + 6), 0.5, C.Steel, Enum.Material.Metal)
		bar(m, "Tirante", apex + V3(s * 3, 0, 0), V3(x + s * 5, boomY + 5, b0 + 6), 0.5, C.Steel, Enum.Material.Metal)
	end
	dec(m, "Cumbre", V3(8, 1.6, 1.6), CF(apex), blue, Enum.Material.Metal)
	-- Sala de máquinas en la contrapluma y contrapeso
	box(m, "SalaMaquinas", V3(13, 7, 18), CF(x, boomY + 5.5, b0 + 12), white, Enum.Material.Metal)
	dec(m, "SalaFranja", V3(13.1, 1, 18.1), CF(x, boomY + 7.5, b0 + 12), blue, Enum.Material.Metal)
	-- Carro, cabina del gruista, cables y spreader con un contenedor colgando sobre el buque
	local tz = plan.Ship and plan.Ship.Z or (zs + 24)
	tz += (index % 3 - 1) * 6
	dec(m, "Carro", V3(11, 2.4, 8), CF(x, boomY - 2.6, tz), C.Steel, Enum.Material.Metal)
	local cabin = dec(m, "Cabina", V3(4.2, 3.6, 4.4), CF(x + 3.2, boomY - 5.8, tz - 4), C.Glass, Enum.Material.Glass)
	cabin.Transparency = 0.15
	local hookY = g + 14 + (index % 2) * 6
	for _, s in { -1, 1 } do
		dec(m, "Cable", V3(0.2, boomY - 4 - (hookY + 1), 0.2), CF(x + s * 3, (boomY - 4 + hookY + 1) / 2, tz), C.Black)
	end
	dec(m, "Spreader", V3(34, 0.8, 2.4), CF(x, hookY + 0.6, tz), rgb(232, 196, 40), Enum.Material.Metal)
	if index % 2 == 1 then
		PuertoKit.container(m, CF(x, hookY - 7.2, tz), 34, PuertoKit.ContainerColors[(index * 5) % #PuertoKit.ContainerColors + 1])
	end
	-- Luces bajo la pluma (de noche): una con luz de verdad
	for i, z in { (zs + b1) / 2, b0 + 4 } do
		local lamp = dec(m, "Foco", V3(2.4, 0.6, 1.6), CF(x, boomY - 2, z), rgb(255, 236, 190), Enum.Material.SmoothPlastic, { Tags = { "StreetLamp" } })
		if i == 1 then
			local light = Instance.new("SpotLight")
			light.Face = Enum.NormalId.Bottom
			light.Angle = 110
			light.Range = 60
			light.Brightness = 2.5
			light.Color = rgb(255, 232, 190)
			light.Shadows = false
			light.Enabled = false
			light.Parent = lamp
		end
	end
	-- Balizas rojas en lo alto (aviso para los aviones)
	dec(m, "Baliza", V3(1, 1, 1), CF(apex + V3(0, 1.4, 0)), rgb(220, 40, 30), Enum.Material.Neon, { Shape = Enum.PartType.Ball })
	dec(m, "Baliza", V3(1, 1, 1), CF(x, boomY + 6, b1 - 1), rgb(220, 40, 30), Enum.Material.Neon, { Shape = Enum.PartType.Ball })
	m:SetAttribute("Pivot", V3(x, g, (zs + zl) / 2))
	return m
end

---------------------------------------------------------------------
-- Barcos
---------------------------------------------------------------------

-- Buque portacontenedores amarrado con la proa al oeste (-X). s = plan.Ship
function PuertoKit.ship(parent: Instance, s: any, sea: number): Model
	local m = Builder.model("Buque", parent)
	Builder.streamable(m)
	m:SetAttribute("PlaceName", "Buque portacontenedores «Estrella de Valmar»")
	local L, B = s.Length, s.Beam
	local bowLen = 26
	local x0 = s.X - L / 2 -- punta de la proa (oeste)
	local hullL = L - bowLen
	local hx = x0 + bowLen + hullL / 2
	local yMid = (s.Keel + s.Deck) / 2
	local H = s.Deck - s.Keel
	box(m, "Casco", V3(hullL, H, B), CF(hx, yMid, s.Z), C.Hull)
	for _, side in { -1, 1 } do
		PuertoKit.bowHalf(m, "Proa", V3(x0 + bowLen, yMid, s.Z), -1, side, bowLen, B / 2, H, C.Hull, true)
	end
	-- Pintura roja bajo la línea de flotación (asoma un poco) y franja blanca
	dec(m, "Flotacion", V3(hullL + 0.2, 3, B + 0.2), CF(hx, sea - 1, s.Z), C.Antifouling)
	dec(m, "Franja", V3(hullL + 0.2, 0.6, B + 0.2), CF(hx, s.Deck - 1.4, s.Z), C.White)
	box(m, "Cubierta", V3(hullL - 1, 0.4, B - 1), CF(hx, s.Deck + 0.2, s.Z), rgb(86, 104, 92))
	-- Castillo de proa
	box(m, "Castillo", V3(14, 3, B - 2), CF(x0 + bowLen + 7, s.Deck + 1.5, s.Z), C.Hull)
	-- Superestructura a popa (este): habilitación, puente con alerones, chimenea y mástil
	local sx = s.X + L / 2 - 18
	box(m, "Habilitacion", V3(14, 22, B - 8), CF(sx, s.Deck + 11, s.Z), C.White)
	for i = 0, 3 do
		local y = s.Deck + 4 + i * 5
		dec(m, "Ventanas", V3(0.2, 1.4, B - 9), CF(sx - 7.05, y, s.Z), C.Glass, Enum.Material.Glass, { Tags = { "NightWindow" } })
	end
	box(m, "Puente", V3(9, 3.2, B + 4), CF(sx - 1, s.Deck + 23.6, s.Z), C.White)
	dec(m, "PuenteVentanas", V3(0.2, 1.6, B + 3), CF(sx - 5.55, s.Deck + 23.8, s.Z), rgb(40, 60, 80), Enum.Material.Glass, { Tags = { "NightWindow" } })
	box(m, "Chimenea", V3(6, 9, 7), CF(sx + 9, s.Deck + 19, s.Z), rgb(40, 110, 150))
	dec(m, "ChimeneaBanda", V3(6.1, 1.6, 7.1), CF(sx + 9, s.Deck + 21.5, s.Z), C.White)
	dec(m, "Mastil", V3(0.6, 9, 0.6), CF(sx - 1, s.Deck + 29.5, s.Z), C.White)
	dec(m, "Radar", V3(0.5, 0.4, 5), CF(sx - 1, s.Deck + 32, s.Z), C.Black)
	local name = box(m, "Nombre", V3(16, 2.4, 0.3), Builder.facing(V3(s.X + L / 2 + 0.2, s.Deck - 3, s.Z), V3(1, 0, 0)), C.Hull)
	Builder.sign(name, "ESTRELLA DE VALMAR\nVALMAR", Enum.NormalId.Front, C.White, nil)
	-- Carga: bloques de contenedores por bahía (cada piso de un color)
	local bayL = 17.6
	local xStart = x0 + bowLen + 15
	local xEnd = sx - 9
	local n = 0
	local x = xStart
	while x + bayL <= xEnd do
		n += 1
		local tiers = 2 + (n % 3)
		for t = 0, tiers - 1 do
			local width = if t == tiers - 1 and n % 2 == 0 then B - 10 else B - 3
			local color = PuertoKit.ContainerColors[(n * 3 + t * 5) % #PuertoKit.ContainerColors + 1]
			box(m, "Carga", V3(bayL - 0.6, 7.2, width), CF(x + bayL / 2, s.Deck + 0.4 + 3.6 + t * 7.2, s.Z), color, Enum.Material.Metal)
			dec(m, "CargaJunta", V3(bayL - 0.4, 0.3, width + 0.05), CF(x + bayL / 2, s.Deck + 0.4 + 7.2 + t * 7.2 - 0.1, s.Z), color:Lerp(Color3.new(0, 0, 0), 0.4))
		end
		x += bayL
	end
	return m
end

-- Barco de pesca pequeño (arrastrero de bajura): cf = centro a la altura del agua, proa hacia -Z local
function PuertoKit.fishingBoat(parent: Instance, cf: CFrame, color: Color3, sea: number): Model
	local m = Builder.model("Pesquero", parent)
	Builder.streamable(m)
	local L, W = 26, 8
	local base = cf * CF(0, 0, 0)
	box(m, "Casco", V3(W, 4, L - 6), base * CF(0, 0.2, 3), color)
	-- Proa en punta (dos cuñas en planta, en el marco del barco)
	for _, side in { -1, 1 } do
		local half = W / 2
		local vZ = base:VectorToWorldSpace(V3(0, 0, -1)) * -1 -- la punta hacia -Z del barco
		local vY = base:VectorToWorldSpace(V3(side, 0, 0))
		local vX = vY:Cross(vZ)
		local center = base * V3(side * half / 2, 0.2, -(L - 6) / 2 + 3 - 3)
		Builder.part({ Name = "Proa", ClassName = "WedgePart", Size = V3(4, half, 6), CFrame = CFrame.fromMatrix(center, vX, vY, vZ), Color = color, Parent = m })
	end
	dec(m, "Flotacion", V3(W + 0.1, 0.6, L - 6.1), base * CF(0, -1.4, 3), C.Antifouling)
	box(m, "Cubierta", V3(W - 0.6, 0.3, L - 7), base * CF(0, 2.3, 3), C.Wood, Enum.Material.WoodPlanks)
	box(m, "Puente", V3(5, 4, 5), base * CF(0, 4.4, -2), C.White)
	dec(m, "PuenteVentana", V3(4.2, 1.2, 0.1), base * CF(0, 5.2, -4.55), C.Glass, Enum.Material.Glass)
	dec(m, "Mastil", V3(0.4, 11, 0.4), base * CF(0, 8, 1), C.White)
	dec(m, "Pescante", V3(0.35, 0.35, 10), base * CF(0, 10, 5) * CFrame.Angles(math.rad(-25), 0, 0), C.White)
	dec(m, "Red", V3(4, 1, 3), base * CF(-1, 3, 10), rgb(60, 130, 90), Enum.Material.Fabric)
	dec(m, "Boyas", V3(1.2, 1.2, 1.2), base * CF(2.4, 3.1, 9), rgb(240, 90, 40), nil, { Shape = Enum.PartType.Ball })
	return m
end

-- Velero de recreo (cf = centro a la altura del agua, proa hacia -Z local)
function PuertoKit.sailboat(parent: Instance, cf: CFrame, color: Color3): Model
	local m = Builder.model("Velero", parent)
	local L, W = 18, 6
	box(m, "Casco", V3(W, 2.6, L - 5), cf * CF(0, 0.4, 2.5), color)
	for _, side in { -1, 1 } do
		local vZ = cf:VectorToWorldSpace(V3(0, 0, 1))
		local vY = cf:VectorToWorldSpace(V3(side, 0, 0))
		local vX = vY:Cross(vZ)
		Builder.decor({ Name = "Proa", ClassName = "WedgePart", Size = V3(2.6, W / 2, 5), CFrame = CFrame.fromMatrix(cf * V3(side * W / 4, 0.4, -(L - 5) / 2 + 2.5 - 2.5), vX, vY, vZ), Color = color, Parent = m })
	end
	box(m, "Camarote", V3(3.6, 1.6, 6), cf * CF(0, 2.4, 2), C.White)
	dec(m, "Mastil", V3(0.3, 20, 0.3), cf * CF(0, 11, -1), rgb(210, 210, 214), Enum.Material.Metal)
	dec(m, "Botavara", V3(0.25, 0.25, 8), cf * CF(0, 3.8, 3), rgb(210, 210, 214), Enum.Material.Metal)
	dec(m, "VelaRecogida", V3(0.8, 0.8, 7.4), cf * CF(0, 4.3, 3), rgb(30, 60, 110), Enum.Material.Fabric)
	return m
end

-- Remolcador (cf = centro a la altura del agua, proa hacia -Z local)
function PuertoKit.tug(parent: Instance, cf: CFrame): Model
	local m = Builder.model("Remolcador", parent)
	Builder.streamable(m)
	local L, W = 30, 11
	local red = rgb(176, 40, 36)
	box(m, "Casco", V3(W, 5, L - 8), cf * CF(0, 0.3, 4), red)
	for _, side in { -1, 1 } do
		local vZ = cf:VectorToWorldSpace(V3(0, 0, 1))
		local vY = cf:VectorToWorldSpace(V3(side, 0, 0))
		local vX = vY:Cross(vZ)
		Builder.part({ Name = "Proa", ClassName = "WedgePart", Size = V3(5, W / 2, 8), CFrame = CFrame.fromMatrix(cf * V3(side * W / 4, 0.3, -(L - 8) / 2 + 4 - 4), vX, vY, vZ), Color = red, Parent = m })
	end
	dec(m, "Defensa", V3(W + 1, 1.4, L - 7.6), cf * CF(0, 2.2, 4), C.Rubber, Enum.Material.Rubber)
	box(m, "Cubierta", V3(W - 1, 0.3, L - 9), cf * CF(0, 2.9, 4), rgb(60, 64, 70))
	box(m, "Superestructura", V3(7, 4, 9), cf * CF(0, 5, -1), C.White)
	box(m, "Puente", V3(8, 3, 5), cf * CF(0, 8.5, -2), C.White)
	dec(m, "PuenteVentanas", V3(7.6, 1.2, 0.1), cf * CF(0, 8.8, -4.55), C.Glass, Enum.Material.Glass)
	dec(m, "Chimenea", V3(2.4, 4, 2.4), cf * CF(0, 9, 3), C.Black)
	dec(m, "Gancho", V3(4, 1, 1), cf * CF(0, 3.6, 10), C.Steel, Enum.Material.Metal)
	return m
end

-- Barca de pasajeros de la Isla del Faro (cf = centro a la altura del agua, proa hacia -Z local)
function PuertoKit.ferry(parent: Instance, cf: CFrame): Model
	local m = Builder.model("BarcaIsla", parent)
	Builder.streamable(m)
	local L, W = 40, 13
	local blue = rgb(30, 90, 160)
	box(m, "Casco", V3(W, 4.6, L - 8), cf * CF(0, 0.2, 4), C.White)
	for _, side in { -1, 1 } do
		local vZ = cf:VectorToWorldSpace(V3(0, 0, 1))
		local vY = cf:VectorToWorldSpace(V3(side, 0, 0))
		local vX = vY:Cross(vZ)
		Builder.part({ Name = "Proa", ClassName = "WedgePart", Size = V3(4.6, W / 2, 8), CFrame = CFrame.fromMatrix(cf * V3(side * W / 4, 0.2, -(L - 8) / 2 + 4 - 4), vX, vY, vZ), Color = C.White, Parent = m })
	end
	dec(m, "Franja", V3(W + 0.1, 0.8, L - 7.9), cf * CF(0, 1.2, 4), blue)
	dec(m, "Flotacion", V3(W + 0.1, 0.8, L - 7.9), cf * CF(0, -1.7, 4), C.Antifouling)
	box(m, "Cubierta", V3(W - 1, 0.3, L - 9), cf * CF(0, 2.6, 4), rgb(180, 170, 150), Enum.Material.WoodPlanks)
	box(m, "Cabina", V3(W - 3, 5, 18), cf * CF(0, 5.2, 4), C.White)
	for _, side in { -1, 1 } do
		dec(m, "Ventanas", V3(0.1, 1.8, 16), cf * CF(side * (W - 3) / 2 + side * 0.05, 5.8, 4), C.Glass, Enum.Material.Glass, { Tags = { "NightWindow" } })
	end
	box(m, "Techo", V3(W - 2, 0.4, 20), cf * CF(0, 7.9, 4), blue)
	for _, side in { -1, 1 } do
		dec(m, "Barandilla", V3(0.2, 1.4, 18), cf * CF(side * (W / 2 - 0.4), 8.8, 4), C.White)
	end
	local sign = box(m, "Nombre", V3(10, 1.6, 0.2), cf * CF(0, 9.4, -5.2), blue)
	Builder.sign(sign, "ISLA DEL FARO", Enum.NormalId.Front, C.White, blue)
	return m
end

---------------------------------------------------------------------
-- Mobiliario del muelle
---------------------------------------------------------------------

-- Bolardo (noray) de fundición: fuste y cabeza. p = en el suelo.
function PuertoKit.bollard(parent: Instance, p: Vector3): BasePart
	local b = box(parent, "Bolardo", V3(1.6, 1.8, 1.6), CF(p + V3(0, 0.9, 0)), C.Black, Enum.Material.Metal, {
		Shape = Enum.PartType.Cylinder,
		Tags = { "PuertoMalla" },
		Attributes = { Kind = "Bolardo" },
	})
	b.CFrame = CF(p + V3(0, 0.9, 0)) * CFrame.Angles(0, 0, math.rad(90))
	b.Size = V3(1.8, 1.4, 1.4)
	b.CastShadow = false
	return b
end

-- Defensa de goma vertical en el muro (cara hacia `normal`)
function PuertoKit.fender(parent: Instance, p: Vector3, normal: Vector3, top: number)
	local h = top - (p.Y - 4)
	dec(parent, "Defensa", V3(1.2, h, 1.2) + V3(math.abs(normal.Z) * 1.4, 0, math.abs(normal.X) * 1.4), CF(p.X + normal.X * 0.7, top - h / 2, p.Z + normal.Z * 0.7), C.Rubber, Enum.Material.Rubber)
end

-- Neumático colgado del muro (las defensas de los muelles pesqueros)
function PuertoKit.tyre(parent: Instance, p: Vector3, normal: Vector3)
	local cf = CF(p + normal * 0.6) * CFrame.Angles(0, math.atan2(normal.X, normal.Z), 0) * CFrame.Angles(0, math.rad(90), 0)
	dec(parent, "Neumatico", V3(0.9, 2.6, 2.6), cf, C.Rubber, Enum.Material.Rubber, { Shape = Enum.PartType.Cylinder })
end

-- Escalera de gato (se puede trepar: TrussPart) desde el agua hasta el muelle
function PuertoKit.ladder(parent: Instance, p: Vector3, top: number, bottom: number): BasePart
	local h = top - bottom
	return box(parent, "Escalera", V3(2, h, 2), CF(p.X, bottom + h / 2, p.Z), C.Steel, Enum.Material.Metal, { ClassName = "TrussPart" })
end

-- Tetrápodo de hormigón: cuatro brazos (cono truncado = cilindro) desde el centro, en tetraedro
local TETRA = {
	V3(0, 1, 0),
	V3(0.9428, -0.3333, 0),
	V3(-0.4714, -0.3333, 0.8165),
	V3(-0.4714, -0.3333, -0.8165),
}
function PuertoKit.tetrapod(parent: Instance, center: Vector3, size: number, yaw: number, tilt: number): Model
	local m = Builder.model("Tetrapodo", parent)
	m:AddTag("PuertoMalla")
	m:SetAttribute("Kind", "Tetrapodo")
	m:SetAttribute("Size", size)
	m:SetAttribute("Centro", center)
	m:SetAttribute("Giro", V3(tilt, yaw, tilt * 0.6))
	local rot = CFrame.Angles(tilt, yaw, tilt * 0.6)
	for i, dir in TETRA do
		local d = rot:VectorToWorldSpace(dir)
		local tip = center + d * size * 0.55
		local mid = (center + tip) / 2
		local cf = CFrame.lookAt(mid, tip + V3(0.0001, 0.0001, 0.0001)) * CFrame.Angles(0, math.rad(90), 0)
		local arm = Builder.part({ Name = "Brazo", Shape = Enum.PartType.Cylinder, Size = V3(size * 0.62, size * 0.36, size * 0.36), CFrame = cf, Color = C.Tetrapod, Material = Enum.Material.Concrete, Parent = m })
		arm.CastShadow = i <= 2
	end
	return m
end

-- Torre de iluminación (de noche se encienden los focos: etiqueta StreetLamp, WorldService)
function PuertoKit.mast(parent: Instance, p: Vector3, height: number): Model
	local m = Builder.model("TorreLuz", parent)
	box(m, "Fuste", V3(height, 1.2, 1.2), CF(p + V3(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), C.Steel, Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
	dec(m, "Corona", V3(5, 0.5, 5), CF(p + V3(0, height + 0.2, 0)), C.Steel, Enum.Material.Metal)
	for i, d in { V3(1, 0, 0), V3(-1, 0, 0), V3(0, 0, 1), V3(0, 0, -1) } do
		local lamp = dec(m, "Foco", V3(1.8, 1.2, 0.6) + V3(0, 0, 0), CF(p + V3(0, height + 1, 0) + d * 2.2) * CFrame.Angles(0, math.atan2(d.X, d.Z), 0), rgb(255, 238, 200), Enum.Material.SmoothPlastic, { Tags = { "StreetLamp" } })
		if i == 1 then
			local light = Instance.new("SpotLight")
			light.Face = Enum.NormalId.Bottom
			light.Angle = 120
			light.Range = 60
			light.Brightness = 2.2
			light.Color = rgb(255, 236, 200)
			light.Shadows = false
			light.Enabled = false
			light.Parent = lamp
		end
	end
	return m
end

-- Valla de malla: postes cada `step` y una malla (medio transparente) de `a` a `b` (en el suelo)
function PuertoKit.fence(parent: Instance, a: Vector3, b: Vector3, height: number?)
	local h = height or 7
	local len = (b - a).Magnitude
	local dir = (b - a).Unit
	local mid = (a + b) / 2
	local cf = Builder.facing(mid + V3(0, h / 2, 0), V3(-dir.Z, 0, dir.X))
	box(parent, "Valla", V3(len, h, 0.2), cf, rgb(150, 156, 160), Enum.Material.Metal, { Transparency = 0.55, CastShadow = false })
	local n = math.max(1, math.floor(len / 30))
	for i = 0, n do
		local p = a:Lerp(b, i / n)
		dec(parent, "VallaPoste", V3(0.4, h + 0.6, 0.4), CF(p + V3(0, (h + 0.6) / 2, 0)), C.Steel, Enum.Material.Metal)
	end
	dec(parent, "VallaCable", V3(len, 0.2, 0.2), cf * CF(0, h / 2 + 0.3, 0), C.Steel, Enum.Material.Metal)
end

---------------------------------------------------------------------
-- Edificios
---------------------------------------------------------------------

-- Nave (almacén) de chapa con cubierta a dos aguas y puertas enrollables. r = rect (X0..X1, Z0..Z1);
-- doors = "N" / "S" (fachada de las puertas). Devuelve el modelo.
function PuertoKit.nave(parent: Instance, r: any, ground: number, height: number, doors: string, name: string, color: Color3): Model
	local m = Builder.model("Nave", parent)
	Builder.streamable(m)
	m:SetAttribute("PlaceName", name)
	local w, d = r.X1 - r.X0, r.Z1 - r.Z0
	local cx, cz = (r.X0 + r.X1) / 2, (r.Z0 + r.Z1) / 2
	box(m, "Cuerpo", V3(w, height, d), CF(cx, ground + height / 2, cz), color, Enum.Material.Metal)
	-- Zócalo de hormigón
	dec(m, "Zocalo", V3(w + 0.2, 2.4, d + 0.2), CF(cx, ground + 1.2, cz), C.Concrete, Enum.Material.Concrete)
	-- Cubierta a dos aguas (cumbrera a lo largo de X)
	local rise = 5
	for _, side in { -1, 1 } do
		Builder.part({
			Name = "Cubierta",
			ClassName = "WedgePart",
			Size = V3(w + 1.2, rise, d / 2 + 0.6),
			CFrame = CF(cx, ground + height + rise / 2, cz + side * (d / 4 + 0.3)) * CFrame.Angles(0, if side < 0 then 0 else math.pi, 0),
			Color = rgb(150, 70, 56),
			Material = Enum.Material.Metal,
			Parent = m,
		})
	end
	-- Lucernarios y nervios de la chapa
	dec(m, "Lucernario", V3(w - 8, 0.3, 2.4), CF(cx, ground + height + rise * 0.55, cz - d / 4) * CFrame.Angles(-math.atan2(rise, d / 2), 0, 0), rgb(200, 220, 230), Enum.Material.Glass)
	local face = if doors == "N" then -1 else 1
	local fz = cz + face * (d / 2 + 0.06)
	-- Puertas enrollables (con sus lamas) y un número encima
	local nDoors = math.max(2, math.floor(w / 30))
	for i = 1, nDoors do
		local x = r.X0 + w * (i - 0.5) / nDoors
		local door = dec(m, "PuertaEnrollable", V3(12, 11, 0.12), CF(x, ground + 5.5, fz), rgb(196, 198, 196), Enum.Material.DiamondPlate)
		door.Material = Enum.Material.Metal
		dec(m, "Cajon", V3(13, 1.2, 1), CF(x, ground + 11.6, fz + face * 0.5), C.Steel, Enum.Material.Metal)
		local num = dec(m, "Numero", V3(3, 2.4, 0.1), CF(x, ground + 14, fz + face * 0.02) * CFrame.Angles(0, if face < 0 then math.pi else 0, 0), rgb(232, 196, 40))
		Builder.sign(num, tostring(i), Enum.NormalId.Front, C.Black, rgb(232, 196, 40))
		-- Muelle de carga (rampa)
		dec(m, "MuelleCarga", V3(14, 1.2, 4), CF(x, ground + 0.6, fz + face * 2), C.ConcreteDark, Enum.Material.Concrete)
	end
	local sign = dec(m, "Rotulo", V3(math.min(w * 0.6, 40), 3, 0.15), CF(cx, ground + height - 2.4, fz + face * 0.1) * CFrame.Angles(0, if face < 0 then math.pi else 0, 0), C.Signal)
	Builder.sign(sign, name, Enum.NormalId.Front, C.White, C.Signal)
	return m
end

return PuertoKit
