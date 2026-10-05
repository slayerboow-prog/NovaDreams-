-- Kit: herramientas compartidas para construir la casa de Cosme (las usan Exterior, Interior,
-- Laboratory, PortalSystem, Observatory, Garage y SecretRoom). Todo en coordenadas LOCALES de la
-- parcela (World/CosmeHouse/Layout): Kit.at(ctx, x, y, z, giro) las pasa al mundo.
--
--   * Piezas: box (choca), deco (no choca, sin consultas; lo pequeño lleva la etiqueta CityDetail y
--     el nivel gráfico Bajo lo esconde: Controllers/MaterialDetail), glass, neon, cyl/disc, ball.
--   * Paredes con huecos (puertas, ventanas, cristaleras), losas con agujeros, tramos de escalera,
--     barandillas, puertas de verdad (Furniture.door: shared/Interact las abre y cierra).
--   * Luces con tope (MaxLights): las que pasan del tope no se crean (el neón sigue brillando).
--   * Pantallas con ecuaciones, mapas, coordenadas, cámaras y simulaciones (SurfaceGui).
--   * Avisos de proximidad de la casa (atributo CosmeAction: los conecta CosmeHouse/Interactions).
--   * Efectos que solo se encienden cerca del jugador (etiqueta CosmeFx: Controllers/CosmeHouseClient),
--     piezas que giran (CosmeSpin) y robots que se pasean (CosmeRobot), todo animado en el cliente.
--   * Lo que flota a propósito (esferas magnéticas, hologramas, el portal) lleva la etiqueta Anomaly.

local Builder = require(script.Parent.Parent.Builder)
local Furniture = require(script.Parent.Parent.Furniture)

local Kit = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local M = Enum.Material

Kit.MaxLights = 72
Kit.Colors = {
	Wall = rgb(236, 232, 224),
	WallWarm = rgb(232, 222, 206),
	Dark = rgb(38, 40, 48),
	Steel = rgb(150, 156, 164),
	Chrome = rgb(205, 208, 212),
	Wood = rgb(150, 108, 72),
	WoodDark = rgb(92, 62, 40),
	Floor = rgb(176, 136, 96),
	Concrete = rgb(150, 150, 146),
	Lab = rgb(54, 60, 74),
	LabFloor = rgb(70, 76, 88),
	Cyan = rgb(90, 220, 255),
	Blue = rgb(70, 130, 255),
	Purple = rgb(160, 90, 255),
	Magenta = rgb(240, 80, 220),
	Green = rgb(110, 255, 140),
	Orange = rgb(255, 160, 60),
	Red = rgb(240, 70, 60),
	Yellow = rgb(255, 214, 70),
	Glass = rgb(176, 214, 236),
	White = rgb(242, 242, 238),
}
local C = Kit.Colors

export type Ctx = {
	Model: Model,
	Site: CFrame,
	Rand: any,
	Wood: Color3,
	Fabric: Color3,
	Accent: Color3,
	Lights: number,
	[string]: any,
}

function Kit.new(model: Model, site: CFrame, seed: string?): Ctx
	return {
		Model = model,
		Site = site,
		Rand = Furniture.rng(seed or "CasaCosme"),
		Wood = C.Wood,
		Fabric = rgb(70, 90, 140),
		Accent = C.Cyan,
		Lights = 0,
	}
end

-- Contexto para los muebles de World/Furniture (se construyen dentro de "parent")
function Kit.furn(ctx: Ctx, parent: Instance, wood: Color3?, fabric: Color3?, accent: Color3?): any
	return { Model = parent, Rand = ctx.Rand, Wood = wood or ctx.Wood, Fabric = fabric or ctx.Fabric, Accent = accent or ctx.Accent }
end

function Kit.at(ctx: Ctx, x: number, y: number, z: number, yaw: number?): CFrame
	return ctx.Site * CF(x, y, z) * ANG(0, math.rad(yaw or 0), 0)
end

function Kit.world(ctx: Ctx, local_: CFrame): CFrame
	return ctx.Site * local_
end

function Kit.group(parent: Instance, name: string): Model
	return Builder.model(name, parent)
end

---------------------------------------------------------------------
-- Piezas (cf en LOCAL)
---------------------------------------------------------------------
function Kit.box(ctx: Ctx, parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
	local props: { [string]: any } = { Name = name, Size = size, CFrame = ctx.Site * cf, Color = color, Material = material or M.SmoothPlastic, CanTouch = false, Parent = parent }
	if math.max(size.X, size.Y, size.Z) < 3 then
		props.CastShadow = false
	end
	for k, v in extra or {} do
		props[k] = v
	end
	return Builder.part(props)
end

-- Detalle: no choca, no se consulta; lo pequeño se esconde en el nivel gráfico Bajo
function Kit.deco(ctx: Ctx, parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, transparency: number?, keep: boolean?): BasePart
	local p = Builder.decor({ Name = name, Size = size, CFrame = ctx.Site * cf, Color = color, Material = material or M.SmoothPlastic, Transparency = transparency or 0, Parent = parent })
	if not keep and math.max(size.X, size.Y, size.Z) < 3.5 then
		p:AddTag("CityDetail")
	end
	return p
end

function Kit.neon(ctx: Ctx, parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, transparency: number?): BasePart
	local p = Kit.deco(ctx, parent, name, size, cf, color, M.Neon, transparency, true)
	p.CastShadow = false
	return p
end

function Kit.glass(ctx: Ctx, parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3?, transparency: number?, solid: boolean?): BasePart
	local p = if solid
		then Kit.box(ctx, parent, name, size, cf, color or C.Glass, M.Glass, { Transparency = transparency or 0.55, CastShadow = false })
		else Kit.deco(ctx, parent, name, size, cf, color or C.Glass, M.Glass, transparency or 0.55, true)
	p.CastShadow = false
	p.Reflectance = 0.12
	return p
end

-- Cilindro de pie (eje vertical). solid: choca
function Kit.cyl(ctx: Ctx, parent: Instance, name: string, height: number, diameter: number, cf: CFrame, color: Color3, material: Enum.Material?, solid: boolean?, transparency: number?): BasePart
	local size = V(height, diameter, diameter)
	local p = if solid
		then Kit.box(ctx, parent, name, size, cf * ANG(0, 0, math.pi / 2), color, material, { Transparency = transparency or 0 })
		else Kit.deco(ctx, parent, name, size, cf * ANG(0, 0, math.pi / 2), color, material, transparency, math.max(height, diameter) >= 3.5)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- Cilindro tumbado a lo largo de X local de cf
function Kit.cylX(ctx: Ctx, parent: Instance, name: string, length: number, diameter: number, cf: CFrame, color: Color3, material: Enum.Material?, transparency: number?): BasePart
	local p = Kit.deco(ctx, parent, name, V(length, diameter, diameter), cf, color, material, transparency, math.max(length, diameter) >= 3.5)
	p.Shape = Enum.PartType.Cylinder
	return p
end

function Kit.ball(ctx: Ctx, parent: Instance, name: string, diameter: number, cf: CFrame, color: Color3, material: Enum.Material?, transparency: number?): BasePart
	local p = Kit.deco(ctx, parent, name, V(diameter, diameter, diameter), cf, color, material, transparency, diameter >= 3.5)
	p.Shape = Enum.PartType.Ball
	return p
end

function Kit.wedge(ctx: Ctx, parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, solid: boolean?): BasePart
	local props: { [string]: any } = { ClassName = "WedgePart", Name = name, Size = size, CFrame = ctx.Site * cf, Color = color, Material = material or M.SmoothPlastic, CanTouch = false, Parent = parent }
	if not solid then
		props.CanCollide = false
		props.CanQuery = false
	end
	return Builder.part(props)
end

-- Algo que flota a propósito (la prueba de piezas flotantes lo deja pasar)
function Kit.anomaly(part: Instance): Instance
	part:AddTag("Anomaly")
	if part:IsA("Model") then
		for _, d in part:GetDescendants() do
			if d:IsA("BasePart") then
				d:AddTag("Anomaly")
			end
		end
	end
	return part
end

---------------------------------------------------------------------
-- Luces (con tope) y efectos
---------------------------------------------------------------------
function Kit.light(ctx: Ctx, part: BasePart, range: number?, brightness: number?, color: Color3?, room: string?, kind: string?): Instance?
	if room then
		part:AddTag("RoomLight")
		part:SetAttribute("Room", room)
		part:SetAttribute("OnColor", part.Color)
		part:SetAttribute("OnMaterial", part.Material.Name)
	end
	if ctx.Lights >= Kit.MaxLights then
		return nil
	end
	ctx.Lights += 1
	local light: Instance
	if kind == "Surface" then
		local l = Instance.new("SurfaceLight")
		l.Face = Enum.NormalId.Bottom
		l.Angle = 120
		l.Range = range or 16
		l.Brightness = brightness or 1
		l.Color = color or rgb(255, 240, 220)
		l.Shadows = false
		light = l
	elseif kind == "Spot" then
		local l = Instance.new("SpotLight")
		l.Face = Enum.NormalId.Bottom
		l.Angle = 70
		l.Range = range or 20
		l.Brightness = brightness or 1.5
		l.Color = color or rgb(255, 240, 220)
		l.Shadows = false
		light = l
	else
		local l = Instance.new("PointLight")
		l.Range = range or 16
		l.Brightness = brightness or 1
		l.Color = color or rgb(255, 240, 220)
		l.Shadows = false
		light = l
	end
	light.Parent = part
	return light
end

-- Lámpara de techo de una habitación (se apaga con su interruptor)
function Kit.ceilingLamp(ctx: Ctx, parent: Instance, x: number, y: number, z: number, room: string, style: string?, color: Color3?): BasePart
	local m = Kit.group(parent, "Lampara")
	local c = color or rgb(255, 238, 210)
	local bulb: BasePart
	if style == "Ring" then
		-- Aro de luz (como el del vestíbulo de la imagen)
		Kit.deco(ctx, m, "Cable", V(0.1, 1.2, 0.1), CF(x, y - 0.6, z), C.Dark)
		bulb = Kit.cyl(ctx, m, "Aro", 0.3, 5, CF(x, y - 1.3, z), c, M.Neon)
		Kit.cyl(ctx, m, "AroHueco", 0.32, 4.2, CF(x, y - 1.3, z), C.Dark)
	elseif style == "Bar" then
		bulb = Kit.neon(ctx, m, "Barra", V(6, 0.25, 0.5), CF(x, y - 0.3, z), c)
		Kit.deco(ctx, m, "Soporte", V(6.4, 0.15, 0.8), CF(x, y - 0.08, z), C.Dark)
	elseif style == "Industrial" then
		Kit.deco(ctx, m, "Cable", V(0.12, 3, 0.12), CF(x, y - 1.5, z), C.Dark)
		Kit.cyl(ctx, m, "Pantalla", 0.8, 2.4, CF(x, y - 3.2, z), C.Dark, M.Metal)
		bulb = Kit.ball(ctx, m, "Bombilla", 0.9, CF(x, y - 3.7, z), c, M.Neon)
	else
		Kit.deco(ctx, m, "Base", V(2.2, 0.12, 2.2), CF(x, y - 0.06, z), C.White)
		bulb = Kit.ball(ctx, m, "Plafon", 2.2, CF(x, y - 0.35, z), c, M.Neon)
		bulb.Size = V(2.2, 0.8, 2.2)
	end
	Kit.light(ctx, bulb, 22, 1.1, c, room)
	return bulb
end

-- Interruptor de la luz (shared/Interact "Light"): cf en la pared mirando a la sala
function Kit.switch(ctx: Ctx, parent: Instance, x: number, y: number, z: number, yaw: number, room: string): BasePart
	local plate = Kit.deco(ctx, parent, "LightSwitch", V(0.6, 0.9, 0.12), Kit.atLocal(x, y, z, yaw), C.White, nil, nil, true)
	Kit.deco(ctx, parent, "Toggle", V(0.22, 0.34, 0.08), Kit.atLocal(x, y + 0.08, z, yaw) * CF(0, 0, -0.08), rgb(220, 220, 214))
	return Furniture.usable(plate, "Light", { Room = room })
end

function Kit.atLocal(x: number, y: number, z: number, yaw: number?): CFrame
	return CF(x, y, z) * ANG(0, math.rad(yaw or 0), 0)
end

-- Partículas (apagadas: las enciende el cliente cuando el jugador está cerca)
local FX = {
	Sparks = { Color = { rgb(255, 230, 120), rgb(255, 140, 40) }, Rate = 12, Life = { 0.3, 0.7 }, Speed = { 4, 9 }, Size = { 0.15, 0 }, Spread = 50, Light = 1, Accel = V(0, -20, 0) },
	Energy = { Color = { rgb(140, 220, 255), rgb(120, 80, 255) }, Rate = 18, Life = { 0.8, 1.6 }, Speed = { 0.5, 2 }, Size = { 0.35, 0 }, Spread = 180, Light = 1 },
	Portal = { Color = { rgb(200, 160, 255), rgb(80, 160, 255) }, Rate = 30, Life = { 1, 2 }, Speed = { 1, 3 }, Size = { 0.5, 0 }, Spread = 180, Light = 1 },
	Steam = { Color = { rgb(240, 240, 240), rgb(220, 220, 225) }, Rate = 6, Life = { 1.2, 2 }, Speed = { 1, 2 }, Size = { 0.4, 1.4 }, Spread = 15, Light = 0, Transp = { 0.5, 1 }, Accel = V(0, 1.5, 0) },
	Bubbles = { Color = { rgb(160, 255, 180), rgb(120, 220, 255) }, Rate = 8, Life = { 1, 2 }, Speed = { 1, 2.5 }, Size = { 0.18, 0.05 }, Spread = 10, Light = 0.6 },
	Fireflies = { Color = { rgb(255, 250, 160), rgb(200, 255, 120) }, Rate = 4, Life = { 3, 5 }, Speed = { 0.2, 0.6 }, Size = { 0.2, 0 }, Spread = 180, Light = 1 },
	Dust = { Color = { rgb(240, 220, 255), rgb(150, 120, 255) }, Rate = 6, Life = { 3, 5 }, Speed = { 0.1, 0.4 }, Size = { 0.12, 0 }, Spread = 180, Light = 0.8 },
}
Kit.FxKinds = FX

function Kit.fx(part: BasePart, kind: string, rate: number?): ParticleEmitter
	local spec = FX[kind] or FX.Energy
	local e = Instance.new("ParticleEmitter")
	e.Name = "Fx_" .. kind
	e.Enabled = false
	e.Rate = rate or spec.Rate
	e.Lifetime = NumberRange.new(spec.Life[1], spec.Life[2])
	e.Speed = NumberRange.new(spec.Speed[1], spec.Speed[2])
	e.SpreadAngle = Vector2.new(spec.Spread, spec.Spread)
	e.Size = NumberSequence.new(spec.Size[1], spec.Size[2])
	e.Color = ColorSequence.new(spec.Color[1], spec.Color[2])
	e.LightEmission = spec.Light
	if spec.Transp then
		e.Transparency = NumberSequence.new(spec.Transp[1], spec.Transp[2])
	else
		e.Transparency = NumberSequence.new(0.1, 1)
	end
	if spec.Accel then
		e.Acceleration = spec.Accel
	end
	e:SetAttribute("BaseRate", e.Rate)
	e.Parent = part
	part:AddTag("CosmeFx")
	return e
end

-- Haz de energía entre dos piezas (Beam con textura de rayo si la hay)
function Kit.beam(a: BasePart, b: BasePart, color: Color3, width: number?, segments: number?): Beam
	local a0 = Instance.new("Attachment")
	a0.Name = "BeamA"
	a0.Parent = a
	local a1 = Instance.new("Attachment")
	a1.Name = "BeamB"
	a1.Parent = b
	local beam = Instance.new("Beam")
	beam.Name = "Energia"
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Color = ColorSequence.new(color)
	beam.Width0 = width or 0.4
	beam.Width1 = width or 0.4
	beam.LightEmission = 1
	beam.FaceCamera = true
	beam.Segments = segments or 12
	beam.CurveSize0 = 0
	beam.CurveSize1 = 0
	beam.Transparency = NumberSequence.new(0.15, 0.35)
	beam.TextureSpeed = 2
	beam.Parent = a
	return beam
end

-- Gira en el cliente (Controllers/CosmeHouseClient): velocidad en vueltas por segundo
function Kit.spin(target: Instance, speed: number, axis: string?)
	target:AddTag("CosmeSpin")
	target:SetAttribute("SpinSpeed", speed)
	target:SetAttribute("SpinAxis", axis or "Y")
end

---------------------------------------------------------------------
-- Avisos de la casa (los conecta CosmeHouse/Interactions)
---------------------------------------------------------------------
function Kit.prompt(part: Instance, action: string, object: string, cosmeAction: string, attrs: { [string]: any }?, hold: number?): ProximityPrompt
	local p = Builder.prompt(part, action, object, hold)
	p.Name = "CosmePrompt"
	p.MaxActivationDistance = 8
	p.RequiresLineOfSight = false
	p:SetAttribute("CosmeAction", cosmeAction)
	for k, v in attrs or {} do
		p:SetAttribute(k, v)
	end
	return p
end

-- Documento que se lee (texto con pistas): aviso «Leer»
function Kit.doc(part: Instance, title: string, text: string, propId: string?): ProximityPrompt
	return Kit.prompt(part, "Leer", "📄 " .. title, "Doc", { Title = title, Text = text, PropId = propId })
end

---------------------------------------------------------------------
-- Paredes, losas, escaleras y barandillas
---------------------------------------------------------------------
export type Opening = { A: number, B: number, Bottom: number, Top: number, Kind: string? }

-- Pared recta. axis "X": va a lo largo de X en z = fixed; "Z": a lo largo de Z en x = fixed.
-- openings: huecos { A, B, Bottom, Top, Kind = "door" | "window" | "glass" | nil (hueco) }
function Kit.wall(ctx: Ctx, parent: Instance, axis: string, fixed: number, a: number, b: number, y0: number, y1: number, opts: { [string]: any }?): { BasePart }
	local o = opts or {}
	local thick = o.Thick or 1
	local color = o.Color or C.Wall
	local material = o.Material or M.SmoothPlastic
	local name = o.Name or "Wall"
	local made = {}
	local function piece(u0: number, u1: number, v0: number, v1: number)
		if u1 - u0 < 0.05 or v1 - v0 < 0.05 then
			return
		end
		local mid, len = (u0 + u1) / 2, u1 - u0
		local size = if axis == "X" then V(len, v1 - v0, thick) else V(thick, v1 - v0, len)
		local cf = if axis == "X" then CF(mid, (v0 + v1) / 2, fixed) else CF(fixed, (v0 + v1) / 2, mid)
		table.insert(made, Kit.box(ctx, parent, name, size, cf, color, material, { CanQuery = true }))
	end
	local holes = table.clone(o.Openings or {})
	table.sort(holes, function(p, q)
		return p.A < q.A
	end)
	local cursor = a
	for _, h in holes do
		piece(cursor, h.A, y0, y1)
		piece(h.A, h.B, y0, h.Bottom)
		piece(h.A, h.B, h.Top, y1)
		local mid, len = (h.A + h.B) / 2, h.B - h.A
		local kind = h.Kind
		if kind == "window" or kind == "glass" then
			local hgt = h.Top - h.Bottom
			local size = if axis == "X" then V(len, hgt, 0.2) else V(0.2, hgt, len)
			local cf = if axis == "X" then CF(mid, (h.Bottom + h.Top) / 2, fixed) else CF(fixed, (h.Bottom + h.Top) / 2, mid)
			Kit.glass(ctx, parent, "WindowGlass", size, cf, o.GlassColor, o.GlassTransparency or 0.5, true)
			-- Marco y parteluces
			local frame = o.Frame or C.Dark
			local ft = thick + 0.1
			local function bar(su: number, sv: number, cu: number, cv: number)
				local s = if axis == "X" then V(su, sv, ft) else V(ft, sv, su)
				local c = if axis == "X" then CF(cu, cv, fixed) else CF(fixed, cv, cu)
				Kit.deco(ctx, parent, "WindowFrame", s, c, frame, M.Metal, nil, true)
			end
			bar(len, 0.3, mid, h.Top - 0.15)
			bar(len, 0.3, mid, h.Bottom + 0.15)
			local n = math.max(1, math.floor(len / 5))
			for i = 0, n do
				bar(0.3, hgt, h.A + len * i / n, (h.Bottom + h.Top) / 2)
			end
			if kind == "window" then
				local sill = if axis == "X" then V(len + 0.6, 0.3, thick + 0.8) else V(thick + 0.8, 0.3, len + 0.6)
				local sc = if axis == "X" then CF(mid, h.Bottom - 0.15, fixed) else CF(fixed, h.Bottom - 0.15, mid)
				Kit.deco(ctx, parent, "Sill", sill, sc, C.White, nil, nil, true)
			end
		end
		cursor = h.B
	end
	piece(cursor, b, y0, y1)
	return made
end

-- Losa (suelo o techo) con agujeros. rect = { X0, X1, Z0, Z1 }; holes: lista de rects
function Kit.slab(ctx: Ctx, parent: Instance, name: string, rect: { [string]: number }, yTop: number, thick: number, holes: { { [string]: number } }?, color: Color3?, material: Enum.Material?): { BasePart }
	local made = {}
	local xs = { rect.X0, rect.X1 }
	local list = {}
	for _, h in holes or {} do
		local cx0, cx1 = math.max(h.X0, rect.X0), math.min(h.X1, rect.X1)
		local cz0, cz1 = math.max(h.Z0, rect.Z0), math.min(h.Z1, rect.Z1)
		if cx1 > cx0 and cz1 > cz0 then
			table.insert(list, { X0 = cx0, X1 = cx1, Z0 = cz0, Z1 = cz1 })
			table.insert(xs, cx0)
			table.insert(xs, cx1)
		end
	end
	table.sort(xs)
	for i = 1, #xs - 1 do
		local x0, x1 = xs[i], xs[i + 1]
		if x1 - x0 > 0.01 then
			local mx = (x0 + x1) / 2
			-- Huecos que cortan esta franja
			local cuts = {}
			for _, h in list do
				if h.X0 <= mx and mx <= h.X1 then
					table.insert(cuts, { h.Z0, h.Z1 })
				end
			end
			table.sort(cuts, function(p, q)
				return p[1] < q[1]
			end)
			local z = rect.Z0
			local spans = {}
			for _, c in cuts do
				if c[1] > z then
					table.insert(spans, { z, c[1] })
				end
				z = math.max(z, c[2])
			end
			if rect.Z1 > z then
				table.insert(spans, { z, rect.Z1 })
			end
			for _, s in spans do
				if s[2] - s[1] > 0.01 then
					table.insert(made, Kit.box(ctx, parent, name, V(x1 - x0, thick, s[2] - s[1]), CF(mx, yTop - thick / 2, (s[1] + s[2]) / 2), color or C.Floor, material or M.WoodPlanks, { CanQuery = true }))
				end
			end
		end
	end
	return made
end

-- Pared redonda (torre del observatorio, sala de portales, torre-portal): polígono de Segments lados
-- alrededor de (cx, cz). opts: Skip(θ) -> true para dejar ese lado abierto, Window = { Bottom, Top,
-- Kind = "glass" }, Doors = { { Theta, Top } } (hueco de puerta en el lado más cercano a Theta)
function Kit.ringWall(ctx: Ctx, parent: Instance, cx: number, cz: number, r: number, y0: number, y1: number, opts: { [string]: any }?): Model
	local o = opts or {}
	local m = Kit.group(parent, o.Name or "ParedRedonda")
	local n = o.Segments or 16
	local thick = o.Thick or 1
	local chord = 2 * r * math.sin(math.pi / n) + 0.35
	for i = 0, n - 1 do
		local theta = (i + 0.5) / n * math.pi * 2
		if o.Skip and o.Skip(theta) then
			continue
		end
		local x, z = cx + r * math.cos(theta), cz + r * math.sin(theta)
		local yaw = -(theta + math.pi / 2)
		local function piece(v0: number, v1: number, name: string?, color: Color3?, material: Enum.Material?)
			if v1 - v0 > 0.05 then
				Kit.box(ctx, m, name or o.PieceName or "Wall", V(chord, v1 - v0, thick), CF(x, (v0 + v1) / 2, z) * ANG(0, yaw, 0), color or o.Color or C.Wall, material or o.Material or M.SmoothPlastic, { CanQuery = true })
			end
		end
		local door = nil
		for _, d in o.Doors or {} do
			local diff = math.abs(((theta - d.Theta + math.pi) % (2 * math.pi)) - math.pi)
			if diff < math.pi / n then
				door = d
			end
		end
		if door then
			piece(door.Top, y1)
		elseif o.Window then
			local w = o.Window
			piece(y0, w.Bottom)
			piece(w.Top, y1)
			local glass = Kit.glass(ctx, m, "WindowGlass", V(chord - 0.3, w.Top - w.Bottom, 0.2), CF(x, (w.Bottom + w.Top) / 2, z) * ANG(0, yaw, 0), o.GlassColor, o.GlassTransparency or 0.45, true)
			glass.Name = "WindowGlass"
			Kit.deco(ctx, m, "Parteluz", V(0.3, w.Top - w.Bottom, thick + 0.2), CF(x, (w.Bottom + w.Top) / 2, z) * ANG(0, yaw, 0) * CF(chord / 2 - 0.1, 0, 0), o.Frame or C.Dark, M.Metal, nil, true)
		else
			piece(y0, y1)
		end
	end
	return m
end

-- Disco (suelo redondo de la torre, plataformas)
function Kit.disc(ctx: Ctx, parent: Instance, name: string, x: number, z: number, radius: number, yTop: number, thick: number, color: Color3, material: Enum.Material?): BasePart
	local p = Kit.box(ctx, parent, name, V(thick, radius * 2, radius * 2), CF(x, yTop - thick / 2, z) * ANG(0, 0, math.pi / 2), color, material, { CanQuery = true })
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- Barandilla de cristal entre dos puntos locales (a la altura del suelo de cada punto)
function Kit.railing(ctx: Ctx, parent: Instance, from: Vector3, to: Vector3, height: number?, glass: boolean?)
	local h = height or 3.4
	local m = Kit.group(parent, "Barandilla")
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	local len = flat.Magnitude
	if len < 0.2 then
		return m
	end
	local yaw = math.atan2(-flat.X, -flat.Z)
	local rise = to.Y - from.Y
	local slope = math.atan2(rise, len)
	local mid = (from + to) / 2
	local frame = CF(mid.X, mid.Y, mid.Z) * ANG(0, yaw, 0) * ANG(slope, 0, 0)
	local full = math.sqrt(len * len + rise * rise)
	-- Pasamanos, cristal (choca: no te caes) y postes
	Kit.box(ctx, m, "Pasamanos", V(0.35, 0.25, full), frame * CF(0, h, 0), C.Chrome, M.Metal)
	if glass ~= false then
		Kit.glass(ctx, m, "Cristal", V(0.15, h - 0.6, full), frame * CF(0, h / 2, 0), rgb(200, 230, 245), 0.6, true)
	else
		Kit.box(ctx, m, "Barrote", V(0.15, h - 0.6, full), frame * CF(0, h / 2, 0), C.Dark, M.Metal, { Transparency = 0.2 })
	end
	local posts = math.max(1, math.floor(len / 6))
	for i = 0, posts do
		local t = i / posts
		local p = from:Lerp(to, t)
		Kit.deco(ctx, m, "Poste", V(0.25, h, 0.25), CF(p.X, p.Y + h / 2, p.Z), C.Chrome, M.Metal, nil, true)
	end
	return m
end

-- Un tramo de escalera (Layout.flight): peldaños macizos, zanca con luz y barandilla exterior
function Kit.flight(ctx: Ctx, parent: Instance, stair: { [string]: any }, k: number, steps: { { number } }, color: Color3?, material: Enum.Material?, rails: { [string]: boolean }?)
	local m = Kit.group(parent, "Tramo" .. k)
	local base = stair.Y0 + (k - 1) * stair.Rise
	local bottom = math.min(base, base + stair.Rise)
	for i, s in steps do
		local x0, x1, z0, z1, top = s[1], s[2], s[3], s[4], s[5]
		local h = top - bottom + 0.4
		Kit.box(ctx, m, "Step", V(x1 - x0, h, z1 - z0), CF((x0 + x1) / 2, top - h / 2, (z0 + z1) / 2), color or C.Wood, material or M.Wood, { CanQuery = true })
		-- Tira de luz en la nariz de cada peldaño (cada dos)
		if i % 2 == 0 then
			local zNose = if stair.Rise > 0 == (k % 2 == 1) then z0 else z1
			Kit.neon(ctx, m, "StepLight", V(x1 - x0 - 0.6, 0.08, 0.12), CF((x0 + x1) / 2, top - 0.25, zNose + (if zNose == z0 then -0.02 else 0.02)), C.Cyan, 0.2)
		end
	end
	return m
end

---------------------------------------------------------------------
-- Puertas (World/Furniture.door: se abren con shared/Interact "Door")
---------------------------------------------------------------------
-- x, z: centro del hueco; yaw: hacia dónde abre la hoja (0 = hacia -Z)
function Kit.door(ctx: Ctx, parent: Instance, x: number, y: number, z: number, yaw: number, width: number, height: number, color: Color3?, open: boolean?): BasePart
	local f = Kit.furn(ctx, parent)
	local panel = Furniture.door(f, Kit.at(ctx, x, y, z, yaw), width, height, color, open, parent, true)
	return panel
end

---------------------------------------------------------------------
-- Pantallas con contenido (SurfaceGui). kind: Equations, Map, Coords, Graph, Camera, Anomalies,
-- Plans, Stars, Sim, Portal, Text
---------------------------------------------------------------------
local EQUATIONS = {
	"E = mc²", "∇ × B = μ₀J + μ₀ε₀ ∂E/∂t", "ds² = −c²dt² + dx² + dy² + dz²", "Ψ(x,t) = A·e^{i(kx−ωt)}",
	"Rμν − ½Rgμν = 8πG Tμν", "t' = t / √(1 − v²/c²)", "Δx·Δp ≥ ħ/2", "λ = h / p", "F = G·m₁m₂ / r²",
	"∮E·dA = Q/ε₀", "∂ρ/∂t + ∇·J = 0", "Ω_grieta = 66,6 ± 0,2", "C(apio) ⊗ K = ∞ ???", "e^{iπ} + 1 = 0",
	"Lunas necesarias: 1", "x_portal(t) = r·cos(ωt)", "Σ dimensiones = 66 + B", "¿v > c? ¡SÍ!",
}
local SCREEN_BG = {
	Equations = rgb(14, 22, 38), Map = rgb(10, 30, 26), Coords = rgb(8, 14, 20), Graph = rgb(16, 18, 34),
	Camera = rgb(20, 20, 22), Anomalies = rgb(30, 10, 24), Plans = rgb(18, 40, 90), Stars = rgb(6, 8, 20),
	Sim = rgb(20, 12, 40), Portal = rgb(30, 14, 60), Text = rgb(12, 16, 24),
}

local function label(parent: Instance, text: string, pos: UDim2, size: UDim2, color: Color3, font: Enum.Font?, align: Enum.TextXAlignment?)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = pos
	l.Size = size
	l.Text = text
	l.TextColor3 = color
	l.TextScaled = true
	l.FontFace = Font.fromEnum(font or Enum.Font.Code)
	l.TextXAlignment = align or Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local function frame(parent: Instance, pos: UDim2, size: UDim2, color: Color3, transparency: number?)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.Position = pos
	f.Size = size
	f.BackgroundColor3 = color
	f.BackgroundTransparency = transparency or 0
	f.Parent = parent
	return f
end

function Kit.screen(ctx: Ctx, part: BasePart, kind: string, face: Enum.NormalId?, text: string?): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Pantalla"
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 24
	gui.LightInfluence = 0
	gui.Brightness = 1.4
	gui.MaxDistance = 90
	gui:SetAttribute("ScreenKind", kind)
	gui.Parent = part
	local bg = frame(gui, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), SCREEN_BG[kind] or SCREEN_BG.Text)
	local R = ctx.Rand
	local cyan, green, pink, yellow = rgb(120, 230, 255), rgb(120, 255, 160), rgb(255, 120, 220), rgb(255, 220, 110)
	if kind == "Equations" then
		for i = 0, 4 do
			label(bg, R.pick(EQUATIONS), UDim2.fromScale(0.05, 0.05 + i * 0.18), UDim2.fromScale(0.9, 0.15), R.pick({ cyan, yellow, rgb(240, 240, 240) }))
		end
	elseif kind == "Map" or kind == "Anomalies" then
		-- Rejilla de calles de Valmar y puntos de anomalías
		for i = 1, 5 do
			frame(bg, UDim2.fromScale(i / 6, 0), UDim2.new(0, 2, 1, 0), rgb(40, 110, 90))
			frame(bg, UDim2.fromScale(0, i / 6), UDim2.new(1, 0, 0, 2), rgb(40, 110, 90))
		end
		for i = 1, (if kind == "Anomalies" then 6 else 3) do
			local dot = frame(bg, UDim2.fromScale(R.range(0.1, 0.85), R.range(0.1, 0.8)), UDim2.fromScale(0.06, 0.08), if kind == "Anomalies" then pink else yellow)
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(1, 0)
			corner.Parent = dot
		end
		label(bg, if kind == "Anomalies" then "ANOMALÍAS · 66-B" else "VALMAR · DISTRITO NORTE", UDim2.fromScale(0.03, 0.86), UDim2.fromScale(0.94, 0.12), if kind == "Anomalies" then pink else green, Enum.Font.GothamBold)
	elseif kind == "Coords" then
		for i = 0, 5 do
			local line = ("X %4d  Y %4d  Z %4d  Δt %+.2f"):format(R.int(-999, 999), R.int(0, 300), R.int(-999, 999), R.range(-9, 9))
			label(bg, line, UDim2.fromScale(0.04, 0.04 + i * 0.155), UDim2.fromScale(0.92, 0.13), green)
		end
	elseif kind == "Graph" or kind == "Sim" then
		-- Barras y curva (gráficos científicos)
		local n = 12
		for i = 1, n do
			local h = R.range(0.15, 0.8)
			frame(bg, UDim2.fromScale((i - 1) / n + 0.01, 0.9 - h), UDim2.fromScale(1 / n - 0.02, h), if kind == "Sim" then pink else cyan, 0.15)
		end
		label(bg, if kind == "Sim" then "SIMULACIÓN · PORTAL v7" else "ENERGÍA DE LA GRIETA (kW)", UDim2.fromScale(0.03, 0.02), UDim2.fromScale(0.94, 0.12), yellow, Enum.Font.GothamBold)
	elseif kind == "Camera" then
		frame(bg, UDim2.fromScale(0.05, 0.35), UDim2.fromScale(0.9, 0.5), rgb(60, 70, 66))
		frame(bg, UDim2.fromScale(0.3, 0.2), UDim2.fromScale(0.15, 0.45), rgb(90, 96, 92))
		label(bg, "● CAM " .. R.int(1, 9) .. " · JARDÍN", UDim2.fromScale(0.04, 0.03), UDim2.fromScale(0.6, 0.12), rgb(255, 80, 80), Enum.Font.GothamBold)
		label(bg, "REC 00:0" .. R.int(1, 9) .. ":" .. R.int(10, 59), UDim2.fromScale(0.6, 0.86), UDim2.fromScale(0.36, 0.1), rgb(240, 240, 240))
	elseif kind == "Plans" then
		for i = 1, 4 do
			frame(bg, UDim2.fromScale(R.range(0.05, 0.6), R.range(0.08, 0.6)), UDim2.fromScale(R.range(0.15, 0.35), R.range(0.15, 0.3)), rgb(220, 235, 255), 0.75)
		end
		label(bg, "PLANO · MÁQUINA LUNAR", UDim2.fromScale(0.04, 0.84), UDim2.fromScale(0.9, 0.12), rgb(230, 240, 255), Enum.Font.GothamBold)
	elseif kind == "Stars" then
		for _ = 1, 26 do
			local s = frame(bg, UDim2.fromScale(R.next(), R.next()), UDim2.fromOffset(4, 4), rgb(255, 255, 230))
			s.BackgroundTransparency = R.range(0, 0.5)
		end
		label(bg, "CARTA ESTELAR · LUNA", UDim2.fromScale(0.04, 0.86), UDim2.fromScale(0.9, 0.12), cyan, Enum.Font.GothamBold)
	elseif kind == "Portal" then
		local ring = frame(bg, UDim2.fromScale(0.3, 0.15), UDim2.fromScale(0.4, 0.7), rgb(160, 90, 255), 0.3)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = ring
		label(bg, "PORTAL · " .. (text or "LISTO"), UDim2.fromScale(0.04, 0.86), UDim2.fromScale(0.92, 0.12), pink, Enum.Font.GothamBold)
	else
		label(bg, text or "", UDim2.fromScale(0.05, 0.05), UDim2.fromScale(0.9, 0.9), rgb(230, 240, 255), Enum.Font.GothamBold, Enum.TextXAlignment.Center)
	end
	return gui
end

-- Monitor (con su pantalla) apoyado en una mesa: cf en la mesa, la pantalla mira a -Z
function Kit.monitor(ctx: Ctx, parent: Instance, cf: CFrame, w: number, h: number, kind: string, text: string?): BasePart
	local m = Kit.group(parent, "Monitor")
	Kit.deco(ctx, m, "Pie", V(1, 0.1, 0.7), cf * CF(0, 0.05, 0.2), C.Dark)
	Kit.deco(ctx, m, "Cuello", V(0.25, 0.7, 0.25), cf * CF(0, 0.45, 0.3), C.Dark)
	Kit.deco(ctx, m, "Marco", V(w + 0.2, h + 0.2, 0.2), cf * CF(0, 0.8 + h / 2, 0.25), rgb(22, 22, 26), nil, nil, true)
	local screen = Kit.deco(ctx, m, "Screen", V(w, h, 0.05), cf * CF(0, 0.8 + h / 2, 0.13), rgb(40, 60, 90), M.SmoothPlastic, nil, true)
	Kit.screen(ctx, screen, kind, Enum.NormalId.Front, text)
	return screen
end

-- Pantalla grande colgada en la pared (cf en la pared mirando a la sala)
function Kit.wallScreen(ctx: Ctx, parent: Instance, cf: CFrame, w: number, h: number, kind: string, text: string?): BasePart
	Kit.deco(ctx, parent, "MarcoPantalla", V(w + 0.4, h + 0.4, 0.3), cf * CF(0, 0, -0.15), rgb(20, 20, 24), nil, nil, true)
	local screen = Kit.deco(ctx, parent, "Screen", V(w, h, 0.05), cf * CF(0, 0, -0.33), rgb(40, 60, 90), M.SmoothPlastic, nil, true)
	Kit.screen(ctx, screen, kind, Enum.NormalId.Front, text)
	return screen
end

-- Cartel con texto (pizarras, avisos «NO ENTRAR», «NO TOCAR»…)
function Kit.signText(part: BasePart, text: string, face: Enum.NormalId?, textColor: Color3?, background: Color3?): TextLabel
	return Builder.sign(part, text, face, textColor, background)
end

---------------------------------------------------------------------
-- Robots pequeños que se pasean (los mueve el cliente por los puntos de Path: path = { {x, z} } en
-- coordenadas locales de la parcela, se guardan en las del mundo "x,z;x,z;…")
---------------------------------------------------------------------
function Kit.robot(ctx: Ctx, parent: Instance, x: number, y: number, z: number, kind: string, path: { { number } }?, speed: number?): Model
	local m = Kit.group(parent, "Robot_" .. kind)
	local cf = CF(x, y, z)
	if kind == "Limpiador" then
		Kit.cyl(ctx, m, "Cuerpo", 0.7, 2.2, cf * CF(0, 0.45, 0), rgb(230, 232, 236), M.SmoothPlastic)
		Kit.cyl(ctx, m, "Tapa", 0.15, 1.6, cf * CF(0, 0.85, 0), C.Dark)
		Kit.neon(ctx, m, "Ojo", V(0.6, 0.15, 0.1), cf * CF(0, 0.6, -1.08), C.Cyan)
	elseif kind == "Jardinero" then
		Kit.box(ctx, m, "Cuerpo", V(1.6, 1.4, 1.6), cf * CF(0, 1.3, 0), rgb(80, 150, 90), M.Metal, { CanCollide = false, CanQuery = false })
		Kit.ball(ctx, m, "Cabeza", 1.1, cf * CF(0, 2.4, 0), rgb(200, 210, 220), M.Metal)
		Kit.neon(ctx, m, "Ojo", V(0.7, 0.18, 0.1), cf * CF(0, 2.45, -0.52), C.Green)
		Kit.cyl(ctx, m, "Rueda", 0.6, 0.9, cf * CF(0, 0.45, 0), C.Dark)
		Kit.deco(ctx, m, "Tijeras", V(0.2, 0.2, 1.4), cf * CF(0.9, 1.4, -0.6), C.Chrome, M.Metal)
		Kit.deco(ctx, m, "Regadera", V(0.6, 0.6, 0.8), cf * CF(-0.9, 1.3, 0), rgb(60, 120, 200))
	elseif kind == "Dron" then
		Kit.box(ctx, m, "Cuerpo", V(1.2, 0.35, 1.2), cf, rgb(40, 44, 52), M.Metal, { CanCollide = false, CanQuery = false })
		for _, d in { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } } do
			Kit.deco(ctx, m, "Brazo", V(0.12, 0.1, 1.1), cf * CF(d[1] * 0.45, 0.05, d[2] * 0.45) * ANG(0, math.rad(45 * d[1] * d[2]), 0), C.Dark)
			Kit.cyl(ctx, m, "Helice", 0.05, 0.9, cf * CF(d[1] * 0.85, 0.25, d[2] * 0.85), rgb(200, 200, 205), nil, false, 0.4)
		end
		Kit.neon(ctx, m, "Luz", V(0.3, 0.1, 0.1), cf * CF(0, 0, -0.62), C.Red)
		Kit.anomaly(m)
	else -- Mini (el robot del vestíbulo y de la cocina)
		Kit.box(ctx, m, "Cuerpo", V(1.2, 1, 1), cf * CF(0, 0.75, 0), rgb(236, 236, 240), M.SmoothPlastic, { CanCollide = false, CanQuery = false })
		Kit.box(ctx, m, "Cabeza", V(1, 0.7, 0.8), cf * CF(0, 1.6, 0), rgb(236, 236, 240), M.SmoothPlastic, { CanCollide = false, CanQuery = false })
		Kit.neon(ctx, m, "Visor", V(0.8, 0.25, 0.05), cf * CF(0, 1.62, -0.42), C.Cyan)
		Kit.deco(ctx, m, "Antena", V(0.08, 0.6, 0.08), cf * CF(0, 2.25, 0), C.Dark)
		Kit.ball(ctx, m, "Punta", 0.25, cf * CF(0, 2.6, 0), C.Red, M.Neon)
		Kit.cyl(ctx, m, "Rueda", 0.25, 0.5, cf * CF(0, 0.13, 0), C.Dark)
	end
	m:AddTag("CosmeRobot")
	m:SetAttribute("Kind", kind)
	m:SetAttribute("Speed", speed or 3)
	if path then
		-- Puntos de la ronda en coordenadas del MUNDO (x, z): el cliente lo mueve de uno a otro
		local parts = {}
		for _, p in path do
			local w = (ctx.Site * CF(p[1], y, p[2])).Position
			table.insert(parts, ("%.2f,%.2f"):format(w.X, w.Z))
		end
		m:SetAttribute("Path", table.concat(parts, ";"))
	end
	return m
end

return Kit
