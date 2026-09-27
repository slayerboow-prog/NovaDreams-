-- Furniture: los muebles de dentro de los edificios (los usa World/Interiors).
--
-- Cada mueble se construye en un CFrame "cf" con el suelo en y = 0 y su parte de delante hacia -Z
-- (un sofá mira hacia -Z y tiene el respaldo en +Z; una tele enseña la pantalla hacia -Z; una
-- ventana o un cuadro, pegados a la pared, miran hacia la sala). Cada mueble es un Model aparte.
--
-- Lo que se usa lleva la etiqueta "Interact" y el atributo Use (shared/Interact: sentarse, cama,
-- tele, luces, nevera, grifos, ducha, puertas, armarios, ordenador, piano, ventana). Las luces de
-- cada habitación llevan la etiqueta "RoomLight" y el atributo Room (el interruptor de esa
-- habitación las apaga y las enciende).
--
-- Rendimiento: lo que no se pisa ni estorba no choca (Builder.decor: sin colisión, sin consultas;
-- lo pequeño, sin sombra). Los muebles grandes chocan (no se atraviesan) pero no se consultan.
-- Todo sale de un número fijo por edificio (rng): cada casa distinta, pero siempre la misma.

local Builder = require(script.Parent.Builder)

local Furniture = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local PI = math.pi
local M = Enum.Material

Furniture.WHITE = rgb(240, 240, 236)
Furniture.DARK = rgb(44, 46, 52)
Furniture.STEEL = rgb(160, 166, 172)
Furniture.CHROME = rgb(205, 208, 212)
local WHITE, DARK, STEEL, CHROME = Furniture.WHITE, Furniture.DARK, Furniture.STEEL, Furniture.CHROME

Furniture.Palette = {
	Walls = { rgb(236, 230, 218), rgb(222, 232, 236), rgb(238, 226, 210), rgb(214, 226, 212), rgb(242, 238, 232), rgb(232, 214, 206), rgb(212, 222, 238), rgb(236, 222, 190) },
	Woods = { rgb(150, 110, 76), rgb(96, 64, 40), rgb(186, 150, 110), rgb(120, 84, 56), rgb(214, 190, 156), rgb(70, 50, 36) },
	Fabrics = { rgb(70, 90, 140), rgb(150, 60, 60), rgb(80, 120, 90), rgb(190, 170, 130), rgb(110, 110, 120), rgb(200, 140, 80), rgb(90, 70, 110), rgb(60, 120, 130), rgb(170, 170, 160), rgb(60, 60, 66) },
	Accents = { rgb(230, 190, 90), rgb(220, 90, 80), rgb(90, 160, 210), rgb(120, 190, 120), rgb(240, 240, 236), rgb(200, 110, 160), rgb(250, 150, 60) },
	Floors = {
		{ rgb(176, 140, 100), M.WoodPlanks },
		{ rgb(196, 160, 118), M.WoodPlanks },
		{ rgb(140, 100, 70), M.WoodPlanks },
		{ rgb(214, 208, 196), M.Marble },
		{ rgb(190, 186, 176), M.Slate },
	},
	Tiles = { rgb(226, 230, 232), rgb(200, 214, 220), rgb(236, 232, 222), rgb(180, 196, 190), rgb(90, 96, 104) },
	Carpets = { rgb(170, 160, 150), rgb(120, 130, 150), rgb(190, 176, 150), rgb(150, 120, 120), rgb(110, 130, 110) },
	Books = { rgb(150, 40, 40), rgb(40, 70, 130), rgb(40, 110, 70), rgb(200, 160, 60), rgb(90, 60, 110), rgb(230, 230, 220), rgb(30, 30, 34), rgb(200, 90, 50), rgb(70, 140, 160) },
	Products = { rgb(220, 60, 50), rgb(250, 200, 60), rgb(60, 150, 220), rgb(90, 180, 90), rgb(240, 240, 236), rgb(240, 140, 50), rgb(160, 90, 170), rgb(120, 80, 50) },
}

---------------------------------------------------------------------
-- Números "al azar" que siempre salen igual para el mismo edificio
---------------------------------------------------------------------
export type Rng = {
	next: () -> number, -- 0..1
	int: (number, number) -> number,
	range: (number, number) -> number,
	pick: <T>({ T }) -> T,
	chance: (number) -> boolean,
}

function Furniture.hash(text: string): number
	local h = 5381
	for i = 1, #text do
		h = (h * 33 + string.byte(text, i)) % 2147483647
	end
	return h
end

function Furniture.rng(seed: string): Rng
	local state = Furniture.hash(seed) % 2147483646 + 1
	local r = {} :: any
	function r.next(): number
		-- (Park-Miller: cabe entero en un número de Luau, sin perder precisión)
		state = (state * 16807) % 2147483647
		return (state - 1) / 2147483646
	end
	function r.int(a: number, b: number): number
		return a + math.floor(r.next() * (b - a + 1) - 1e-9)
	end
	function r.range(a: number, b: number): number
		return a + (b - a) * r.next()
	end
	function r.pick(list)
		return list[r.int(1, #list)]
	end
	function r.chance(p: number): boolean
		return r.next() < p
	end
	return r
end

---------------------------------------------------------------------
-- Piezas
---------------------------------------------------------------------
export type Ctx = {
	Model: Model,
	Rand: Rng,
	Wood: Color3,
	Fabric: Color3,
	Accent: Color3,
	[string]: any,
}

-- Mueble grande: choca (no se atraviesa), pero no lo consultan los rayos ni los toques
local function solid(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
	local props: { [string]: any } = { Name = name, Size = size, CFrame = cf, Color = color, Material = material or M.SmoothPlastic, CanQuery = false, CanTouch = false, Parent = parent }
	if math.max(size.X, size.Y, size.Z) < 3 then
		props.CastShadow = false
	end
	for k, v in extra or {} do
		props[k] = v
	end
	return Builder.part(props)
end
Furniture.solid = solid

-- Detalle: sin colisión, sin consultas, sin sombra si es pequeño (Builder.decor)
local function deco(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, transparency: number?): BasePart
	return Builder.decor({ Name = name, Size = size, CFrame = cf, Color = color, Material = material or M.SmoothPlastic, Transparency = transparency or 0, Parent = parent })
end
Furniture.deco = deco

local function ball(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): BasePart
	local p = deco(parent, name, size, cf, color, material)
	p.Shape = Enum.PartType.Ball
	return p
end
Furniture.ball = ball

-- Cilindro de pie (el eje de los cilindros de Roblox es X: se gira para que quede vertical)
local function cyl(parent: Instance, name: string, height: number, diameter: number, cf: CFrame, color: Color3, material: Enum.Material?): BasePart
	local p = deco(parent, name, V(height, diameter, diameter), cf * ANG(0, 0, PI / 2), color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end
Furniture.cyl = cyl

local function group(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end
Furniture.group = group

local function usable(part: BasePart, use: string, attributes: { [string]: any }?): BasePart
	part:AddTag("Interact")
	part:SetAttribute("Use", use)
	for k, v in attributes or {} do
		part:SetAttribute(k, v)
	end
	return part
end
Furniture.usable = usable

-- Asiento de verdad (Seat): se usa con el cartel "Sentarse", no al rozarlo
local function seatPart(parent: Instance, cf: CFrame, size: Vector3?, color: Color3?, material: Enum.Material?, visible: boolean?): Seat
	local s = Instance.new("Seat")
	s.Name = "Seat"
	s.Anchored = true
	s.Size = size or V(2, 0.3, 2)
	s.CFrame = cf
	s.CanTouch = false
	s.CanQuery = false
	s.CanCollide = visible == true
	s.CastShadow = false
	s.TopSurface = Enum.SurfaceType.Smooth
	s.BottomSurface = Enum.SurfaceType.Smooth
	s.Color = color or DARK
	s.Material = material or M.Fabric
	s.Transparency = if visible then 0 else 1
	s.Parent = parent
	return s
end
Furniture.seatPart = seatPart

-- Agua que sale (grifos, ducha): el servidor la enciende un rato
local function water(part: BasePart, spread: number?, rate: number?)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Water"
	emitter.Enabled = false
	emitter.Rate = rate or 45
	emitter.Lifetime = NumberRange.new(0.35, 0.55)
	emitter.Speed = NumberRange.new(5, 7)
	emitter.SpreadAngle = Vector2.new(spread or 4, spread or 4)
	emitter.EmissionDirection = Enum.NormalId.Bottom
	emitter.Acceleration = V(0, -20, 0)
	emitter.Size = NumberSequence.new(0.12, 0.06)
	emitter.Transparency = NumberSequence.new(0.25, 0.8)
	emitter.Color = ColorSequence.new(rgb(190, 225, 255))
	emitter.LightEmission = 0.25
	emitter.Parent = part
end

-- Punto de luz que se apaga con el interruptor de su habitación
local function roomLight(part: BasePart, room: string, range: number?, brightness: number?, color: Color3?)
	part:AddTag("RoomLight")
	part:SetAttribute("Room", room)
	part:SetAttribute("OnColor", part.Color)
	part:SetAttribute("OnMaterial", part.Material.Name)
	local light = Instance.new("PointLight")
	light.Range = range or 20
	light.Brightness = brightness or 1.1
	light.Color = color or rgb(255, 236, 206)
	light.Shadows = false
	light.Parent = part
end
Furniture.roomLight = roomLight

---------------------------------------------------------------------
-- Luces, interruptores, puertas y ventanas
---------------------------------------------------------------------

-- Lámpara de techo (cf en el techo). kind: "Dome" | "Pendant" | "Panel" | "Chandelier" | "Spot"
function Furniture.ceilingLight(ctx: Ctx, cf: CFrame, room: string, kind: string?, parent: Instance?)
	local m = group(parent or ctx.Model, "CeilingLight")
	local k = kind or "Dome"
	if k == "Pendant" then
		deco(m, "Cord", V(0.08, 2, 0.08), cf * CF(0, -1, 0), DARK)
		local shade = deco(m, "Shade", V(1.8, 1, 1.8), cf * CF(0, -2.3, 0), ctx.Accent, M.SmoothPlastic)
		shade.Shape = Enum.PartType.Ball
		local bulb = ball(m, "Bulb", V(0.8, 0.8, 0.8), cf * CF(0, -2.8, 0), rgb(255, 244, 220), M.Neon)
		roomLight(bulb, room, 18, 1)
	elseif k == "Panel" then
		deco(m, "Frame", V(4.4, 0.2, 2.4), cf * CF(0, -0.1, 0), WHITE)
		local panel = deco(m, "Panel", V(4, 0.1, 2), cf * CF(0, -0.22, 0), rgb(250, 250, 245), M.Neon)
		roomLight(panel, room, 22, 1.1, rgb(250, 248, 240))
	elseif k == "Chandelier" then
		deco(m, "Chain", V(0.12, 1.6, 0.12), cf * CF(0, -0.8, 0), rgb(200, 170, 90), M.Metal)
		local ring = cyl(m, "Ring", 0.3, 4, cf * CF(0, -1.8, 0), rgb(210, 180, 100), M.Metal)
		ring.Shape = Enum.PartType.Cylinder
		for i = 0, 5 do
			local a = i / 6 * PI * 2
			ball(m, "Candle", V(0.5, 0.7, 0.5), cf * CF(math.cos(a) * 1.8, -1.35, math.sin(a) * 1.8), rgb(255, 236, 190), M.Neon)
		end
		local core = ball(m, "Crystal", V(1.2, 1.6, 1.2), cf * CF(0, -2.4, 0), rgb(240, 240, 255), M.Glass)
		core.Transparency = 0.3
		roomLight(core, room, 26, 1.3)
	elseif k == "Spot" then
		local spot = cyl(m, "Spot", 0.3, 0.9, cf * CF(0, -0.15, 0), rgb(255, 246, 226), M.Neon)
		roomLight(spot, room, 14, 0.8)
	else
		deco(m, "Base", V(2, 0.12, 2), cf * CF(0, -0.06, 0), WHITE)
		local dome = ball(m, "Dome", V(2.2, 0.8, 2.2), cf * CF(0, -0.3, 0), rgb(255, 246, 228), M.Neon)
		roomLight(dome, room, 20, 1.1)
	end
	return m
end

-- Interruptor en la pared (cf en la superficie de la pared, mirando a la sala)
function Furniture.lightSwitch(ctx: Ctx, cf: CFrame, room: string, parent: Instance?): BasePart
	local plate = deco(parent or ctx.Model, "LightSwitch", V(0.6, 0.9, 0.1), cf * CF(0, 0, -0.05), WHITE)
	deco(parent or ctx.Model, "Toggle", V(0.22, 0.34, 0.08), cf * CF(0, 0.08, -0.12), rgb(220, 220, 214))
	return usable(plate, "Light", { Room = room })
end

-- Puerta con bisagra (cf: centro del hueco en el suelo; la hoja gira hacia -Z)
function Furniture.door(ctx: Ctx, cf: CFrame, width: number, height: number, color: Color3?, open: boolean?, parent: Instance?, left: boolean?): BasePart
	local m = group(parent or ctx.Model, "Door")
	local hingeLeft = if left ~= nil then left else ctx.Rand.chance(0.5)
	local side = if hingeLeft then -1 else 1
	local closed = cf * CF(0, height / 2, 0)
	local panel = solid(m, "DoorPanel", V(width - 0.1, height - 0.1, 0.3), closed, color or ctx.Wood, M.Wood)
	local hinge = cf * CF(side * width / 2, height / 2, 0)
	usable(panel, "Door", {
		Hinge = hinge,
		Closed = closed,
		Swing = if hingeLeft then math.rad(95) else math.rad(-95),
		Open = false,
	})
	-- Pomo (sigue a la hoja: se suelda en el servidor al abrir; aquí va pegado)
	local knob = deco(m, "DoorKnob", V(0.3, 0.3, 0.7), closed * CF(-side * (width / 2 - 0.5), -0.6, 0), rgb(210, 190, 120), M.Metal)
	knob:SetAttribute("FollowDoor", "DoorPanel")
	-- Marco
	for _, x in { -width / 2 - 0.15, width / 2 + 0.15 } do
		deco(m, "DoorFrame", V(0.3, height, 0.7), cf * CF(x, height / 2, 0), WHITE)
	end
	deco(m, "DoorFrame", V(width + 0.6, 0.3, 0.7), cf * CF(0, height + 0.15, 0), WHITE)
	if open then
		panel:SetAttribute("StartOpen", true)
	end
	return panel
end

-- Ventana (cf en la superficie de la pared, mirando a la sala)
function Furniture.window(ctx: Ctx, cf: CFrame, w: number, h: number, room: string, curtains: Color3?, parent: Instance?): BasePart
	local m = group(parent or ctx.Model, "Window")
	local glass = deco(m, "WindowGlass", V(w, h, 0.1), cf * CF(0, 0, 0.02), rgb(176, 214, 242), M.Neon, 0.25)
	usable(glass, "Window", {})
	local light = Instance.new("SurfaceLight")
	light.Face = Enum.NormalId.Front
	light.Range = 14
	light.Brightness = 0.6
	light.Angle = 80
	light.Color = rgb(230, 240, 255)
	light.Shadows = false
	light.Parent = glass
	local frame = rgb(245, 245, 242)
	deco(m, "WindowFrame", V(w + 0.6, 0.3, 0.3), cf * CF(0, h / 2 + 0.15, -0.1), frame)
	deco(m, "WindowFrame", V(0.3, h, 0.3), cf * CF(-w / 2 - 0.15, 0, -0.1), frame)
	deco(m, "WindowFrame", V(0.3, h, 0.3), cf * CF(w / 2 + 0.15, 0, -0.1), frame)
	deco(m, "Mullion", V(0.2, h, 0.2), cf * CF(0, 0, -0.08), frame)
	deco(m, "Mullion", V(w, 0.2, 0.2), cf * CF(0, h * 0.15, -0.08), frame)
	deco(m, "Sill", V(w + 1, 0.3, 0.8), cf * CF(0, -h / 2 - 0.15, -0.35), frame)
	if curtains then
		local cw = math.max(1, w * 0.22)
		deco(m, "CurtainRod", V(w + 3, 0.15, 0.15), cf * CF(0, h / 2 + 0.8, -0.45), DARK, M.Metal)
		for _, s in { -1, 1 } do
			deco(m, "Curtain", V(cw, h + 1.6, 0.25), cf * CF(s * (w / 2 + cw / 2 - 0.3), -0.1, -0.45), curtains, M.Fabric)
		end
	end
	return glass
end

-- Cuadro (cf en la pared, mirando a la sala)
function Furniture.picture(ctx: Ctx, cf: CFrame, w: number, h: number, parent: Instance?)
	local m = group(parent or ctx.Model, "Picture")
	local R = ctx.Rand
	deco(m, "PictureFrame", V(w, h, 0.2), cf * CF(0, 0, -0.1), R.pick({ rgb(200, 170, 90), DARK, WHITE, rgb(120, 84, 56) }), M.Wood)
	local bg = R.pick({ rgb(240, 236, 226), rgb(40, 60, 90), rgb(230, 210, 170), rgb(170, 200, 220) })
	deco(m, "Canvas", V(w - 0.4, h - 0.4, 0.05), cf * CF(0, 0, -0.22), bg)
	local style = R.int(1, 3)
	if style == 1 then
		-- Paisaje: cielo, montaña, sol
		deco(m, "Hill", V(w - 0.4, (h - 0.4) * 0.4, 0.05), cf * CF(0, -(h - 0.4) * 0.3, -0.25), rgb(90, 140, 80))
		ball(m, "Sun", V(0.8, 0.8, 0.05), cf * CF(w * 0.2, h * 0.18, -0.25), rgb(250, 200, 70))
	elseif style == 2 then
		for i = 1, 3 do
			deco(m, "Block", V((w - 0.6) * R.range(0.2, 0.45), (h - 0.6) * R.range(0.2, 0.5), 0.05), cf * CF(R.range(-w / 4, w / 4), R.range(-h / 4, h / 4), -0.25 - i * 0.01), R.pick(Furniture.Palette.Accents))
		end
	else
		ball(m, "Circle", V(math.min(w, h) * 0.5, math.min(w, h) * 0.5, 0.05), cf * CF(0, 0, -0.25), R.pick(Furniture.Palette.Accents))
	end
end

-- Zócalo (cf en el suelo junto a la pared, mirando a la sala)
function Furniture.baseboard(ctx: Ctx, cf: CFrame, length: number, color: Color3?, parent: Instance?)
	deco(parent or ctx.Model, "Baseboard", V(length, 0.6, 0.15), cf * CF(0, 0.3, -0.08), color or WHITE)
end

---------------------------------------------------------------------
-- Salón
---------------------------------------------------------------------
function Furniture.sofa(ctx: Ctx, cf: CFrame, color: Color3, seats: number?, parent: Instance?): Model
	local m = group(parent or ctx.Model, "Sofa")
	local n = seats or 3
	local w = n * 2.4 + 1.6
	local legs = ctx.Wood
	local base = solid(m, "SofaBase", V(w, 1.1, 3.2), cf * CF(0, 0.85, 0), color, M.Fabric)
	usable(base, "Sit")
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			deco(m, "Leg", V(0.3, 0.3, 0.3), cf * CF(sx * (w / 2 - 0.4), 0.15, sz * 1.3), legs, M.Wood)
		end
		solid(m, "SofaArm", V(0.8, 1.9, 3.2), cf * CF(sx * (w / 2 - 0.4), 1.25, 0), color, M.Fabric)
	end
	solid(m, "SofaBack", V(w, 2.5, 0.8), cf * CF(0, 1.95, 1.2), color, M.Fabric)
	local inner = w - 1.6
	local cw = inner / n
	local cushion = color:Lerp(WHITE, 0.08)
	for i = 1, n do
		local x = -inner / 2 + (i - 0.5) * cw
		deco(m, "Cushion", V(cw - 0.1, 0.5, 2.4), cf * CF(x, 1.65, -0.2), cushion, M.Fabric)
		deco(m, "BackCushion", V(cw - 0.15, 1.6, 0.5), cf * CF(x, 2.55, 0.62) * ANG(math.rad(-10), 0, 0), cushion, M.Fabric)
		seatPart(m, cf * CF(x, 1.75, -0.3))
	end
	-- Cojines de colores
	for _, s in { -1, 1 } do
		if ctx.Rand.chance(0.7) then
			deco(m, "Pillow", V(1.4, 1.3, 0.45), cf * CF(s * (inner / 2 - 0.6), 2.4, 0.25) * ANG(math.rad(-15), s * 0.3, 0), ctx.Accent, M.Fabric)
		end
	end
	if ctx.Rand.chance(0.4) then
		deco(m, "Throw", V(1.8, 0.12, 2.6), cf * CF(inner / 2 - 1.2, 1.95, -0.2), ctx.Rand.pick(Furniture.Palette.Fabrics), M.Fabric)
	end
	return m
end

function Furniture.armchair(ctx: Ctx, cf: CFrame, color: Color3, parent: Instance?): Model
	local m = group(parent or ctx.Model, "Armchair")
	local base = solid(m, "ChairBase", V(3.2, 1.1, 3), cf * CF(0, 0.85, 0), color, M.Fabric)
	usable(base, "Sit")
	for _, sx in { -1, 1 } do
		solid(m, "ChairArm", V(0.6, 1.8, 3), cf * CF(sx * 1.3, 1.2, 0), color, M.Fabric)
		for _, sz in { -1, 1 } do
			deco(m, "Leg", V(0.25, 0.3, 0.25), cf * CF(sx * 1.3, 0.15, sz * 1.2), ctx.Wood, M.Wood)
		end
	end
	solid(m, "ChairBack", V(3.2, 2.6, 0.7), cf * CF(0, 2, 1.15) * ANG(math.rad(-6), 0, 0), color, M.Fabric)
	deco(m, "Cushion", V(2, 0.45, 2.3), cf * CF(0, 1.62, -0.2), color:Lerp(WHITE, 0.1), M.Fabric)
	seatPart(m, cf * CF(0, 1.72, -0.3))
	return m
end

function Furniture.coffeeTable(ctx: Ctx, cf: CFrame, w: number?, d: number?, parent: Instance?): Model
	local m = group(parent or ctx.Model, "CoffeeTable")
	local tw, td = w or 4.5, d or 2.6
	local R = ctx.Rand
	local glass = R.chance(0.35)
	solid(m, "TableTop", V(tw, 0.2, td), cf * CF(0, 1.4, 0), if glass then rgb(200, 225, 235) else ctx.Wood, if glass then M.Glass else M.Wood, { Transparency = if glass then 0.4 else 0 })
	deco(m, "Shelf", V(tw - 0.4, 0.12, td - 0.4), cf * CF(0, 0.45, 0), ctx.Wood, M.Wood)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			deco(m, "Leg", V(0.2, 1.3, 0.2), cf * CF(sx * (tw / 2 - 0.25), 0.65, sz * (td / 2 - 0.25)), if glass then CHROME else ctx.Wood, if glass then M.Metal else M.Wood)
		end
	end
	-- Cosas encima: revistas, taza, mando, un jarrón o una planta pequeña
	deco(m, "Magazine", V(1, 0.08, 1.4), cf * CF(-tw / 4, 1.54, 0) * ANG(0, R.range(-0.4, 0.4), 0), R.pick(Furniture.Palette.Accents))
	cyl(m, "Mug", 0.5, 0.45, cf * CF(tw / 4, 1.75, -0.4), R.pick({ WHITE, rgb(200, 60, 50), rgb(60, 90, 150) }))
	deco(m, "Remote", V(0.3, 0.12, 0.9), cf * CF(tw / 6, 1.56, 0.5) * ANG(0, 0.3, 0), DARK)
	if R.chance(0.5) then
		cyl(m, "Vase", 0.9, 0.5, cf * CF(0, 1.95, 0.3), R.pick(Furniture.Palette.Accents), M.Glass)
		ball(m, "Flowers", V(0.9, 0.9, 0.9), cf * CF(0, 2.6, 0.3), R.pick({ rgb(230, 90, 130), rgb(250, 220, 90), rgb(240, 240, 240) }), M.Grass)
	end
	-- Libros apilados en la balda de abajo
	for i = 0, R.int(1, 3) do
		deco(m, "Book", V(1.2, 0.2, 0.9), cf * CF(tw / 4, 0.62 + i * 0.2, 0) * ANG(0, R.range(-0.3, 0.3), 0), R.pick(Furniture.Palette.Books))
	end
	return m
end

-- Mueble de la tele con la tele (la pantalla, etiqueta Interact Use = "TV")
function Furniture.tvUnit(ctx: Ctx, cf: CFrame, w: number?, parent: Instance?): BasePart
	local m = group(parent or ctx.Model, "TVUnit")
	local uw = w or 8
	local R = ctx.Rand
	solid(m, "TVStand", V(uw, 2, 2), cf * CF(0, 1, 0), ctx.Wood, M.Wood)
	for i = -1, 1, 2 do
		deco(m, "Drawer", V(uw / 2 - 0.4, 1.4, 0.1), cf * CF(i * uw / 4, 1, -1.02), ctx.Wood:Lerp(DARK, 0.15), M.Wood)
	end
	local tvw = math.min(uw - 1, R.pick({ 5.5, 6.5, 7 }))
	local tvh = tvw * 0.56
	deco(m, "TVStandFoot", V(1.6, 0.15, 1), cf * CF(0, 2.08, 0), DARK)
	deco(m, "TVNeck", V(0.3, 0.6, 0.3), cf * CF(0, 2.4, 0.1), DARK)
	deco(m, "TV", V(tvw, tvh, 0.3), cf * CF(0, 2.7 + tvh / 2, 0.1), rgb(18, 18, 22))
	local screen = deco(m, "TVScreen", V(tvw - 0.3, tvh - 0.3, 0.05), cf * CF(0, 2.7 + tvh / 2, -0.07), rgb(12, 14, 18), M.Glass)
	usable(screen, "TV", { On = false, Channel = 0 })
	-- Consola, altavoces, una planta o unos libros
	if R.chance(0.6) then
		deco(m, "Console", V(1.4, 0.4, 1.2), cf * CF(uw / 2 - 1.2, 2.2, 0), R.pick({ WHITE, DARK }))
	end
	for _, s in { -1, 1 } do
		if R.chance(0.5) then
			deco(m, "Speaker", V(0.8, 1.8, 0.8), cf * CF(s * (uw / 2 - 0.5), 2.9, 0.2), DARK)
		end
	end
	if R.chance(0.5) then
		cyl(m, "Pot", 0.8, 0.8, cf * CF(-uw / 2 + 0.8, 2.4, 0), WHITE)
		ball(m, "Leaves", V(1.2, 1.4, 1.2), cf * CF(-uw / 2 + 0.8, 3.3, 0), rgb(70, 130, 60), M.Grass)
	end
	return screen
end

-- Estantería con libros (y algún objeto)
function Furniture.bookshelf(ctx: Ctx, cf: CFrame, w: number?, h: number?, parent: Instance?): Model
	local m = group(parent or ctx.Model, "Bookshelf")
	local sw, sh = w or 6, h or 7.5
	local R = ctx.Rand
	local wood = ctx.Wood
	solid(m, "ShelfBack", V(sw, sh, 0.2), cf * CF(0, sh / 2, 0.8), wood, M.Wood)
	for _, s in { -1, 1 } do
		solid(m, "ShelfSide", V(0.25, sh, 1.8), cf * CF(s * (sw / 2 - 0.125), sh / 2, 0), wood, M.Wood)
	end
	local rows = math.max(2, math.floor(sh / 1.9))
	local gap = sh / rows
	for row = 0, rows do
		deco(m, "Board", V(sw - 0.3, 0.18, 1.7), cf * CF(0, row * gap + 0.09, 0), wood, M.Wood)
	end
	for row = 0, rows - 1 do
		local y = row * gap + 0.18
		local x = -sw / 2 + 0.35
		local stop = sw / 2 - 0.35
		local ornament = R.chance(0.35)
		while x < stop - 0.3 do
			if ornament and x > 0 and x < 0.6 then
				-- Un objeto entre los libros (jarrón, caja o figurita)
				ball(m, "Ornament", V(0.8, 0.9, 0.8), cf * CF(x + 0.4, y + 0.45, 0), R.pick(Furniture.Palette.Accents), M.SmoothPlastic)
				x += 1
				continue
			end
			local bw = R.range(0.22, 0.45)
			local bh = math.min(gap - 0.35, R.range(1, 1.5))
			local tilt = if R.chance(0.08) then 0.25 else 0
			deco(m, "Book", V(bw, bh, 1.2), cf * CF(x + bw / 2, y + bh / 2, 0.05) * ANG(0, 0, tilt), R.pick(Furniture.Palette.Books))
			x += bw + 0.04
		end
	end
	return m
end

function Furniture.floorLamp(ctx: Ctx, cf: CFrame, room: string, parent: Instance?)
	local m = group(parent or ctx.Model, "FloorLamp")
	cyl(m, "LampBase", 0.2, 1.4, cf * CF(0, 0.1, 0), DARK, M.Metal)
	deco(m, "LampPole", V(0.15, 5.6, 0.15), cf * CF(0, 2.9, 0), DARK, M.Metal)
	local shade = cyl(m, "LampShade", 1.3, 1.7, cf * CF(0, 6, 0), rgb(250, 236, 206), M.Neon)
	roomLight(shade, room, 12, 0.7, rgb(255, 214, 160))
end

function Furniture.tableLamp(ctx: Ctx, cf: CFrame, room: string, parent: Instance?)
	local m = group(parent or ctx.Model, "TableLamp")
	cyl(m, "LampFoot", 0.8, 0.5, cf * CF(0, 0.4, 0), ctx.Accent, M.SmoothPlastic)
	local shade = cyl(m, "LampShade", 0.8, 1.1, cf * CF(0, 1.15, 0), rgb(250, 238, 214), M.Neon)
	roomLight(shade, room, 9, 0.6, rgb(255, 214, 160))
end

-- Planta en maceta. size ~ 1 (pequeña) … 1.6 (grande)
function Furniture.plant(ctx: Ctx, cf: CFrame, size: number?, parent: Instance?)
	local m = group(parent or ctx.Model, "Plant")
	local s = size or 1
	local R = ctx.Rand
	local pot = R.pick({ rgb(170, 90, 60), WHITE, DARK, rgb(200, 180, 150) })
	local potPart = solid(m, "Pot", V(1.6, 1.6, 1.6) * s, cf * CF(0, 0.8 * s, 0), pot, M.Slate)
	potPart.CastShadow = false
	deco(m, "Soil", V(1.4, 0.1, 1.4) * s, cf * CF(0, 1.62 * s, 0), rgb(70, 50, 36), M.Ground)
	local kind = R.int(1, 3)
	local green = R.pick({ rgb(70, 130, 60), rgb(60, 110, 70), rgb(90, 150, 70) })
	if kind == 1 then
		ball(m, "Leaves", V(3, 3, 3) * s, cf * CF(0, 3 * s, 0), green, M.Grass)
	elseif kind == 2 then
		-- Planta alta (tipo ficus): tronco y copa
		deco(m, "Trunk", V(0.25, 3, 0.25) * s, cf * CF(0, 3 * s, 0), rgb(110, 80, 50), M.Wood)
		ball(m, "Leaves", V(2.6, 2.4, 2.6) * s, cf * CF(0, 4.8 * s, 0), green, M.Grass)
		ball(m, "Leaves", V(1.8, 1.8, 1.8) * s, cf * CF(0.6 * s, 3.8 * s, 0.2 * s), green:Lerp(WHITE, 0.08), M.Grass)
	else
		-- Hojas largas en abanico
		for i = 0, 4 do
			local a = i / 5 * PI * 2
			deco(m, "Leaf", V(0.4, 2.6, 0.15) * s, cf * CF(0, 2.6 * s, 0) * ANG(0, a, 0.35) * CF(0, 0, 0), green, M.Grass)
		end
	end
end

function Furniture.rug(ctx: Ctx, cf: CFrame, w: number, d: number, color: Color3?, parent: Instance?)
	local m = group(parent or ctx.Model, "Rug")
	local c = color or ctx.Rand.pick(Furniture.Palette.Fabrics)
	deco(m, "Rug", V(w, 0.08, d), cf * CF(0, 0.06, 0), c, M.Fabric)
	if ctx.Rand.chance(0.6) then
		deco(m, "RugBorder", V(w - 0.8, 0.09, d - 0.8), cf * CF(0, 0.065, 0), c:Lerp(WHITE, 0.35), M.Fabric)
		deco(m, "RugCenter", V(w - 1.6, 0.1, d - 1.6), cf * CF(0, 0.07, 0), c, M.Fabric)
	end
end

function Furniture.sideTable(ctx: Ctx, cf: CFrame, room: string?, parent: Instance?)
	local m = group(parent or ctx.Model, "SideTable")
	solid(m, "SideTop", V(1.8, 0.2, 1.8), cf * CF(0, 2, 0), ctx.Wood, M.Wood)
	deco(m, "SideLeg", V(0.3, 1.9, 0.3), cf * CF(0, 0.95, 0), ctx.Wood, M.Wood)
	if room then
		Furniture.tableLamp(ctx, cf * CF(0, 2.1, 0), room, m)
	end
end

function Furniture.fireplace(ctx: Ctx, cf: CFrame, room: string, parent: Instance?)
	local m = group(parent or ctx.Model, "Fireplace")
	local stone = rgb(200, 190, 176)
	solid(m, "Chimney", V(7, 6, 1.6), cf * CF(0, 3, 0.4), stone, M.Brick)
	deco(m, "Hearth", V(4, 3, 0.3), cf * CF(0, 1.6, -0.4), rgb(30, 26, 24))
	deco(m, "Mantel", V(8, 0.4, 2.2), cf * CF(0, 6.2, 0.2), ctx.Wood, M.Wood)
	for i = -1, 1 do
		deco(m, "Log", V(2.6, 0.5, 0.5), cf * CF(0, 0.5, -0.6 + i * 0.05) * ANG(0, i * 0.3, 0), rgb(90, 60, 36), M.Wood)
	end
	local fire = deco(m, "Fire", V(2, 1.2, 0.6), cf * CF(0, 1.1, -0.6), rgb(255, 140, 40), M.Neon, 0.2)
	roomLight(fire, room, 14, 1.2, rgb(255, 160, 80))
	ball(m, "Vase", V(0.7, 1.2, 0.7), cf * CF(-2.8, 7, 0.2), ctx.Accent, M.Glass)
	deco(m, "Clock", V(1.4, 1.4, 0.3), cf * CF(2.6, 7.1, 0.3), rgb(200, 170, 90), M.Wood)
end

function Furniture.piano(ctx: Ctx, cf: CFrame, parent: Instance?): Model
	local m = group(parent or ctx.Model, "Piano")
	local black = rgb(20, 20, 22)
	local body = solid(m, "PianoBody", V(6, 4.6, 2.2), cf * CF(0, 2.3, 0.6), black, M.SmoothPlastic, { Reflectance = 0.1 })
	usable(body, "Piano")
	deco(m, "KeyBed", V(5.6, 0.4, 1.2), cf * CF(0, 2.9, -1.1), black)
	deco(m, "WhiteKeys", V(5.3, 0.12, 1), cf * CF(0, 3.15, -1.15), WHITE)
	for i = 0, 17 do
		if i % 7 ~= 2 and i % 7 ~= 6 then
			deco(m, "BlackKey", V(0.15, 0.14, 0.55), cf * CF(-2.45 + i * 0.29, 3.25, -0.95), black)
		end
	end
	deco(m, "MusicStand", V(2.4, 1.2, 0.1), cf * CF(0, 4.9, -0.4) * ANG(math.rad(-15), 0, 0), black)
	deco(m, "Sheet", V(1.8, 1, 0.05), cf * CF(0, 4.92, -0.47) * ANG(math.rad(-15), 0, 0), WHITE)
	-- Banqueta (se sienta mirando al teclado)
	local bench = cf * CF(0, 0, -3.2)
	solid(m, "PianoBench", V(3.2, 0.5, 1.4), bench * CF(0, 1.75, 0), black)
	for _, sx in { -1, 1 } do
		deco(m, "BenchLeg", V(0.25, 1.5, 1.2), bench * CF(sx * 1.4, 0.75, 0), black)
	end
	-- (mirando al teclado: hacia +Z del piano)
	seatPart(m, bench * CF(0, 2.05, 0) * ANG(0, PI, 0))
	return m
end

---------------------------------------------------------------------
-- Comedor
---------------------------------------------------------------------
function Furniture.chair(ctx: Ctx, cf: CFrame, color: Color3?, parent: Instance?): Seat
	local m = group(parent or ctx.Model, "Chair")
	local c = color or ctx.Wood
	local seat = seatPart(m, cf * CF(0, 1.85, 0), V(1.9, 0.3, 1.9), c, M.Wood, true)
	usable(seat, "Sit")
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			deco(m, "ChairLeg", V(0.18, 1.7, 0.18), cf * CF(sx * 0.78, 0.85, sz * 0.78), c, M.Wood)
		end
	end
	deco(m, "ChairBack", V(1.9, 2, 0.2), cf * CF(0, 3, 0.85), c, M.Wood)
	if ctx.Rand.chance(0.5) then
		deco(m, "ChairCushion", V(1.6, 0.15, 1.6), cf * CF(0, 2.07, 0), ctx.Fabric, M.Fabric)
	end
	return seat
end

function Furniture.stool(ctx: Ctx, cf: CFrame, color: Color3?, height: number?, parent: Instance?): Seat
	local m = group(parent or ctx.Model, "Stool")
	local h = height or 3
	-- (el asiento de verdad va sin girar: el cojín redondo es solo lo que se ve)
	local seat = seatPart(m, cf * CF(0, h + 0.05, 0), V(1.6, 0.3, 1.6))
	local cushion = cyl(m, "StoolTop", 0.35, 1.7, cf * CF(0, h, 0), color or rgb(160, 40, 50), M.Leather)
	usable(cushion, "Sit")
	deco(m, "StoolPost", V(0.2, h - 0.2, 0.2), cf * CF(0, (h - 0.2) / 2, 0), CHROME, M.Metal)
	cyl(m, "StoolFoot", 0.12, 1.2, cf * CF(0, 0.06, 0), CHROME, M.Metal)
	deco(m, "FootRing", V(1.1, 0.1, 1.1), cf * CF(0, h * 0.4, 0), CHROME, M.Metal)
	return seat
end

function Furniture.table(ctx: Ctx, cf: CFrame, w: number, d: number, color: Color3?, parent: Instance?): Model
	local m = group(parent or ctx.Model, "Table")
	local c = color or ctx.Wood
	solid(m, "TableTop", V(w, 0.3, d), cf * CF(0, 3, 0), c, M.Wood)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			deco(m, "TableLeg", V(0.3, 2.85, 0.3), cf * CF(sx * (w / 2 - 0.4), 1.43, sz * (d / 2 - 0.4)), c, M.Wood)
		end
	end
	return m
end

-- Mesa con sillas alrededor (seats: 2, 4, 6 u 8)
function Furniture.diningSet(ctx: Ctx, cf: CFrame, seats: number, parent: Instance?): Model
	local m = group(parent or ctx.Model, "DiningSet")
	local R = ctx.Rand
	local perSide = math.max(1, math.floor(seats / 2))
	local w = math.max(3.5, perSide * 2.5 + 0.8)
	local d = 3.6
	Furniture.table(ctx, cf, w, d, ctx.Wood, m)
	deco(m, "TableRunner", V(w - 1, 0.05, 1), cf * CF(0, 3.17, 0), R.pick({ WHITE, ctx.Accent, rgb(200, 180, 140) }), M.Fabric)
	-- Centro de mesa: frutero o jarrón
	if R.chance(0.5) then
		cyl(m, "FruitBowl", 0.35, 1.5, cf * CF(0, 3.35, 0), WHITE)
		for k, c in { rgb(220, 50, 40), rgb(250, 190, 40), rgb(110, 170, 60), rgb(240, 120, 40) } do
			ball(m, "Fruit", V(0.5, 0.5, 0.5), cf * CF((k - 2.5) * 0.35, 3.65, (k % 2) * 0.3 - 0.15), c)
		end
	else
		cyl(m, "Vase", 1, 0.6, cf * CF(0, 3.65, 0), ctx.Accent, M.Glass)
		ball(m, "Flowers", V(1, 1, 1), cf * CF(0, 4.4, 0), R.pick({ rgb(230, 90, 130), rgb(250, 220, 90), rgb(200, 120, 220) }), M.Grass)
	end
	for i = 1, perSide do
		local x = -w / 2 + 0.4 + (i - 0.5) * (w - 0.8) / perSide
		for _, side in { -1, 1 } do
			-- Plato y vaso delante de cada silla
			cyl(m, "Plate", 0.08, 1.1, cf * CF(x, 3.2, side * (d / 2 - 0.8)), WHITE)
			Furniture.chair(ctx, cf * CF(x, 0, side * (d / 2 + 0.9)) * ANG(0, if side < 0 then PI else 0, 0), ctx.Wood, m)
		end
	end
	if seats % 2 == 1 or seats >= 6 then
		Furniture.chair(ctx, cf * CF(w / 2 + 0.9, 0, 0) * ANG(0, PI / 2, 0), ctx.Wood, m)
	end
	return m
end

---------------------------------------------------------------------
-- Cocina
---------------------------------------------------------------------

-- Nevera (etiqueta Use = "Fridge"; la puerta gira sobre su bisagra y dentro hay comida)
function Furniture.fridge(ctx: Ctx, cf: CFrame, color: Color3?, parent: Instance?): BasePart
	local m = group(parent or ctx.Model, "Fridge")
	local c = color or ctx.Rand.pick({ WHITE, CHROME, rgb(40, 42, 46), rgb(200, 220, 230) })
	local w, h, d = 3.2, 7.2, 2.8
	-- Caja hueca por delante: al abrir se ve lo de dentro
	local body = solid(m, "FridgeBody", V(w, h, 0.2), cf * CF(0, h / 2, d / 2 - 0.1), c, M.Metal)
	usable(body, "Fridge")
	for _, s in { -1, 1 } do
		solid(m, "FridgeSide", V(0.2, h, d), cf * CF(s * (w / 2 - 0.1), h / 2, 0), c, M.Metal)
	end
	solid(m, "FridgeTop", V(w, 0.2, d), cf * CF(0, h - 0.1, 0), c, M.Metal)
	solid(m, "FridgeBottom", V(w, 0.4, d), cf * CF(0, 0.2, 0), c, M.Metal)
	local inner = deco(m, "FridgeLight", V(w - 0.5, 0.1, d - 0.5), cf * CF(0, h - 0.3, 0), rgb(245, 250, 255), M.Neon)
	inner.Transparency = 0.2
	for _, y in { 2.2, 4, 5.6 } do
		deco(m, "FridgeShelf", V(w - 0.45, 0.08, d - 0.5), cf * CF(0, y, 0), rgb(220, 235, 240), M.Glass, 0.3)
	end
	local R = ctx.Rand
	for i = 1, 6 do
		local y = ({ 2.2, 4, 5.6 })[(i - 1) % 3 + 1]
		local x = R.range(-0.9, 0.9)
		if R.chance(0.5) then
			cyl(m, "Bottle", 1.1, 0.4, cf * CF(x, y + 0.6, R.range(-0.5, 0.5)), R.pick({ rgb(90, 170, 90), rgb(240, 240, 236), rgb(230, 140, 40) }), M.Glass)
		else
			deco(m, "Food", V(R.range(0.6, 1), R.range(0.4, 0.8), 0.8), cf * CF(x, y + 0.4, R.range(-0.5, 0.5)), R.pick(Furniture.Palette.Products))
		end
	end
	local hingeCf = cf * CF(w / 2, h / 2, -d / 2 - 0.15)
	local closed = cf * CF(0, h / 2, -d / 2 - 0.15)
	local door = solid(m, "FridgeDoor", V(w, h, 0.3), closed, c, M.Metal)
	door:SetAttribute("Hinge", hingeCf)
	door:SetAttribute("Closed", closed)
	door:SetAttribute("Swing", math.rad(-100))
	local handle = deco(m, "FridgeHandle", V(0.15, 2.4, 0.3), closed * CF(-w / 2 + 0.4, 0.8, -0.3), DARK, M.Metal)
	handle:SetAttribute("FollowDoor", "FridgeDoor")
	local line = deco(m, "FridgeLine", V(w - 0.1, 0.08, 0.05), closed * CF(0, -0.9, -0.17), c:Lerp(DARK, 0.3))
	line:SetAttribute("FollowDoor", "FridgeDoor")
	-- Imanes y una nota
	for i = 1, R.int(1, 3) do
		local mg = deco(m, "Magnet", V(0.35, 0.35, 0.05), closed * CF(R.range(-1, 1), R.range(0.6, 2.4), -0.17), R.pick(Furniture.Palette.Accents))
		mg:SetAttribute("FollowDoor", "FridgeDoor")
	end
	return body
end

-- Encimera con muebles bajos, fregadero (grifo), placa, horno, muebles altos, campana y
-- electrodomésticos. cf: en el suelo contra la pared (+Z), a lo largo de X.
function Furniture.kitchenRun(ctx: Ctx, cf: CFrame, length: number, parent: Instance?): Model
	local m = group(parent or ctx.Model, "Kitchen")
	local R = ctx.Rand
	local cab = R.pick({ WHITE, rgb(220, 216, 204), rgb(90, 110, 130), rgb(150, 110, 76), rgb(70, 90, 80), rgb(200, 60, 50) })
	local top = R.pick({ { rgb(60, 62, 66), M.Granite }, { rgb(236, 234, 228), M.Marble }, { rgb(160, 120, 80), M.Wood }, { rgb(30, 30, 34), M.Slate } })
	local L = length
	solid(m, "BaseCabinets", V(L, 3.3, 2.4), cf * CF(0, 1.75, 0), cab, M.Wood)
	deco(m, "Plinth", V(L, 0.3, 2.2), cf * CF(0, 0.15, 0.05), DARK)
	solid(m, "Worktop", V(L + 0.2, 0.25, 2.7), cf * CF(0, 3.52, -0.1), top[1], top[2])
	-- Puertas y tiradores
	local doors = math.max(2, math.floor(L / 2.1))
	local dw = L / doors
	for i = 1, doors do
		local x = -L / 2 + (i - 0.5) * dw
		deco(m, "CabinetDoor", V(dw - 0.15, 2.8, 0.1), cf * CF(x, 1.85, -1.24), cab:Lerp(WHITE, 0.08), M.Wood)
		deco(m, "Knob", V(0.6, 0.12, 0.12), cf * CF(x, 3, -1.33), CHROME, M.Metal)
	end
	-- Fregadero con grifo (Use = "Tap": sale agua)
	local sx = L / 2 - 2
	deco(m, "Sink", V(2.4, 0.12, 1.7), cf * CF(sx, 3.6, -0.1), rgb(180, 184, 188), M.Metal)
	deco(m, "SinkHole", V(2, 0.13, 1.3), cf * CF(sx, 3.6, -0.1), rgb(120, 124, 130), M.Metal)
	deco(m, "TapPost", V(0.2, 1.2, 0.2), cf * CF(sx, 4.2, 0.8), CHROME, M.Metal)
	local spout = deco(m, "TapSpout", V(0.2, 0.2, 0.8), cf * CF(sx, 4.75, 0.45), CHROME, M.Metal)
	usable(spout, "Tap", { Spot = (cf * CF(sx, 0, -2.4)).Position })
	water(spout)
	-- Placa y horno
	local hx = -L / 2 + 2.4
	deco(m, "Hob", V(2.4, 0.06, 2), cf * CF(hx, 3.66, -0.1), rgb(20, 20, 24), M.Glass)
	for _, o in { { -0.6, -0.5 }, { 0.6, -0.5 }, { -0.6, 0.5 }, { 0.6, 0.5 } } do
		cyl(m, "Burner", 0.05, 0.8, cf * CF(hx + o[1], 3.7, -0.1 + o[2]), rgb(70, 70, 76))
	end
	deco(m, "OvenDoor", V(2.3, 1.8, 0.1), cf * CF(hx, 1.8, -1.28), rgb(28, 28, 32), M.Glass)
	deco(m, "OvenHandle", V(2, 0.15, 0.15), cf * CF(hx, 2.85, -1.38), CHROME, M.Metal)
	deco(m, "OvenLight", V(1.8, 0.1, 0.05), cf * CF(hx, 2.55, -1.34), rgb(255, 160, 60), M.Neon)
	if R.chance(0.6) then
		cyl(m, "Pan", 0.3, 1.2, cf * CF(hx - 0.6, 3.85, -0.6), DARK, M.Metal)
	end
	if R.chance(0.6) then
		cyl(m, "Pot", 0.9, 1.1, cf * CF(hx + 0.6, 4.15, 0.4), CHROME, M.Metal)
	end
	-- Campana y muebles altos
	deco(m, "Hood", V(2.8, 0.8, 1.8), cf * CF(hx, 7.3, 0.25), CHROME, M.Metal)
	deco(m, "HoodChimney", V(1.2, 3, 1), cf * CF(hx, 9.2, 0.7), CHROME, M.Metal)
	-- (encima del fregadero no hay muebles altos: ahí va la ventana)
	local ux0, ux1 = hx + 1.8, sx - 2.2
	if ux1 - ux0 > 2 then
		local uw = ux1 - ux0
		solid(m, "WallCabinets", V(uw, 2.6, 1.3), cf * CF((ux0 + ux1) / 2, 7.6, 0.55), cab, M.Wood)
		local n = math.max(1, math.floor(uw / 2))
		for i = 1, n do
			local x = ux0 + (i - 0.5) * uw / n
			deco(m, "WallDoor", V(uw / n - 0.15, 2.4, 0.08), cf * CF(x, 7.6, -0.12), cab:Lerp(WHITE, 0.08), M.Wood)
		end
		-- Luz bajo los muebles altos
		local strip = deco(m, "UnderLight", V(uw - 0.4, 0.08, 0.2), cf * CF((ux0 + ux1) / 2, 6.25, 0), rgb(255, 244, 220), M.Neon)
		strip.CastShadow = false
	end
	-- Pequeños electrodomésticos y cosas de la encimera
	local free = { -L / 2 + 5, 0, L / 2 - 4.5 }
	local items = { "Microwave", "Kettle", "Toaster", "Knives", "Board", "Herbs", "CoffeeMaker" }
	for _, x in free do
		if x > -L / 2 + 4 and x < L / 2 - 3.2 then
			local item = R.pick(items)
			local at = cf * CF(x, 3.65, 0)
			if item == "Microwave" then
				deco(m, "Microwave", V(1.8, 1.1, 1.3), at * CF(0, 0.55, 0.3), R.pick({ WHITE, CHROME, DARK }), M.Metal)
				deco(m, "MicrowaveDoor", V(1.1, 0.8, 0.05), at * CF(-0.2, 0.55, -0.38), DARK, M.Glass)
			elseif item == "Kettle" then
				cyl(m, "Kettle", 0.9, 0.7, at * CF(0, 0.45, 0.4), R.pick(Furniture.Palette.Accents), M.Metal)
			elseif item == "Toaster" then
				deco(m, "Toaster", V(1.2, 0.8, 0.7), at * CF(0, 0.4, 0.4), R.pick({ CHROME, rgb(200, 60, 50), WHITE }), M.Metal)
			elseif item == "Knives" then
				deco(m, "KnifeBlock", V(0.6, 1, 0.7), at * CF(0, 0.5, 0.6), ctx.Wood, M.Wood)
			elseif item == "Board" then
				deco(m, "CuttingBoard", V(1.6, 0.1, 1), at * CF(0, 0.05, -0.2), rgb(190, 150, 100), M.Wood)
				ball(m, "Tomato", V(0.4, 0.4, 0.4), at * CF(0.3, 0.3, -0.2), rgb(220, 50, 40))
			elseif item == "Herbs" then
				for k = -1, 1 do
					cyl(m, "HerbPot", 0.5, 0.5, at * CF(k * 0.6, 0.25, 0.6), rgb(170, 90, 60))
					ball(m, "Herb", V(0.6, 0.6, 0.6), at * CF(k * 0.6, 0.7, 0.6), rgb(80, 150, 60), M.Grass)
				end
			else
				deco(m, "CoffeeMaker", V(1, 1.4, 1), at * CF(0, 0.7, 0.4), DARK, M.Metal)
			end
		end
	end
	return m
end

-- Isla o barra de desayuno con taburetes
function Furniture.island(ctx: Ctx, cf: CFrame, length: number, parent: Instance?)
	local m = group(parent or ctx.Model, "Island")
	solid(m, "IslandBase", V(length, 3.3, 2.4), cf * CF(0, 1.75, 0), ctx.Wood, M.Wood)
	solid(m, "IslandTop", V(length + 0.3, 0.25, 3.2), cf * CF(0, 3.52, -0.3), rgb(236, 234, 228), M.Marble)
	local n = math.max(1, math.floor(length / 2.6))
	for i = 1, n do
		local x = -length / 2 + (i - 0.5) * length / n
		Furniture.stool(ctx, cf * CF(x, 0, -2.6) * ANG(0, PI, 0), ctx.Fabric, 2.4, m)
	end
	cyl(m, "FruitBowl", 0.35, 1.5, cf * CF(length / 2 - 1.2, 3.8, -0.3), WHITE)
	for k, c in { rgb(220, 50, 40), rgb(250, 190, 40), rgb(110, 170, 60) } do
		ball(m, "Fruit", V(0.5, 0.5, 0.5), cf * CF(length / 2 - 1.2 + (k - 2) * 0.35, 4.1, -0.3), c)
	end
end

---------------------------------------------------------------------
-- Dormitorio
---------------------------------------------------------------------

-- Cama (cf en el suelo; el cabecero hacia +Z). El colchón lleva Use = "Bed".
function Furniture.bed(ctx: Ctx, cf: CFrame, width: number?, parent: Instance?): BasePart
	local m = group(parent or ctx.Model, "Bed")
	local R = ctx.Rand
	local w = width or 5.6
	local L = 7.6
	local wood = ctx.Wood
	solid(m, "BedFrame", V(w + 0.4, 1.1, L + 0.4), cf * CF(0, 0.65, 0), wood, M.Wood)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			deco(m, "BedLeg", V(0.35, 0.3, 0.35), cf * CF(sx * (w / 2), 0.15, sz * (L / 2)), wood:Lerp(DARK, 0.3), M.Wood)
		end
	end
	local headColor = if R.chance(0.5) then wood else ctx.Fabric
	solid(m, "Headboard", V(w + 0.8, 4.4, 0.5), cf * CF(0, 2.2, L / 2 + 0.3), headColor, if headColor == wood then M.Wood else M.Fabric)
	deco(m, "Footboard", V(w + 0.6, 1.6, 0.35), cf * CF(0, 0.95, -L / 2 - 0.25), wood, M.Wood)
	local mattress = solid(m, "Mattress", V(w, 0.9, L), cf * CF(0, 1.65, 0), rgb(245, 245, 248), M.Fabric)
	usable(mattress, "Bed")
	local duvet = R.pick(Furniture.Palette.Fabrics)
	deco(m, "Duvet", V(w + 0.15, 0.3, L * 0.66), cf * CF(0, 2.2, -L * 0.17), duvet, M.Fabric)
	deco(m, "DuvetFold", V(w + 0.2, 0.35, 0.7), cf * CF(0, 2.28, L * 0.16), duvet:Lerp(WHITE, 0.5), M.Fabric)
	local pillows = if w >= 5 then 2 else 1
	for i = 1, pillows do
		local x = if pillows == 1 then 0 else (i - 1.5) * (w / 2)
		deco(m, "Pillow", V(w / pillows - 0.4, 0.6, 1.3), cf * CF(x, 2.4, L / 2 - 1) * ANG(math.rad(-14), 0, 0), WHITE, M.Fabric)
	end
	if R.chance(0.6) then
		deco(m, "Cushion", V(1.4, 1.2, 0.4), cf * CF(0, 2.6, L / 2 - 1.9) * ANG(math.rad(-20), 0, 0), ctx.Accent, M.Fabric)
	end
	return mattress
end

function Furniture.nightstand(ctx: Ctx, cf: CFrame, room: string?, parent: Instance?)
	local m = group(parent or ctx.Model, "Nightstand")
	local R = ctx.Rand
	solid(m, "Nightstand", V(2, 2.2, 1.8), cf * CF(0, 1.1, 0), ctx.Wood, M.Wood)
	deco(m, "NightDrawer", V(1.7, 0.8, 0.08), cf * CF(0, 1.5, -0.93), ctx.Wood:Lerp(WHITE, 0.1), M.Wood)
	deco(m, "NightKnob", V(0.3, 0.12, 0.12), cf * CF(0, 1.5, -1), CHROME, M.Metal)
	if room then
		Furniture.tableLamp(ctx, cf * CF(0.3, 2.2, 0.2), room, m)
	end
	if R.chance(0.6) then
		deco(m, "Book", V(0.9, 0.2, 1.2), cf * CF(-0.4, 2.3, -0.2) * ANG(0, R.range(-0.5, 0.5), 0), R.pick(Furniture.Palette.Books))
	end
	if R.chance(0.4) then
		deco(m, "Alarm", V(0.6, 0.5, 0.3), cf * CF(-0.5, 2.45, 0.3), R.pick(Furniture.Palette.Accents))
	end
end

-- Armario: por dentro, ropa colgada (se ve al abrir sus puertas). Use = "Wardrobe".
function Furniture.wardrobe(ctx: Ctx, cf: CFrame, w: number?, parent: Instance?): BasePart
	local m = group(parent or ctx.Model, "Wardrobe")
	local R = ctx.Rand
	local ww, h, d = w or 6, 8, 2.4
	local c = R.pick({ ctx.Wood, WHITE, rgb(220, 214, 200) })
	local back = solid(m, "WardrobeBack", V(ww, h, 0.2), cf * CF(0, h / 2, d / 2 - 0.1), c, M.Wood)
	usable(back, "Wardrobe")
	for _, s in { -1, 1 } do
		solid(m, "WardrobeSide", V(0.2, h, d), cf * CF(s * (ww / 2 - 0.1), h / 2, 0), c, M.Wood)
	end
	solid(m, "WardrobeTop", V(ww, 0.3, d), cf * CF(0, h - 0.15, 0), c, M.Wood)
	solid(m, "WardrobeBase", V(ww, 0.5, d), cf * CF(0, 0.25, 0), c, M.Wood)
	deco(m, "Rail", V(ww - 0.5, 0.12, 0.12), cf * CF(0, h - 1.2, 0), CHROME, M.Metal)
	local x = -ww / 2 + 0.6
	while x < ww / 2 - 0.6 do
		local cw = R.range(0.35, 0.6)
		deco(m, "Clothes", V(cw, R.range(2.6, 4), 1.6), cf * CF(x + cw / 2, h - 1.3 - 1.6, 0) * CF(0, 0, 0), R.pick(Furniture.Palette.Fabrics), M.Fabric)
		x += cw + 0.08
	end
	deco(m, "ShoeRow", V(ww - 0.6, 0.4, 1), cf * CF(0, 0.7, 0.2), R.pick(Furniture.Palette.Products))
	for _, s in { -1, 1 } do
		local dw = ww / 2 - 0.1
		local closed = cf * CF(s * (ww / 4), h / 2, -d / 2 - 0.08)
		local door = solid(m, "WardrobeDoor", V(dw, h - 0.3, 0.15), closed, c:Lerp(WHITE, 0.06), M.Wood)
		door:SetAttribute("Hinge", cf * CF(s * (ww / 2 - 0.05), h / 2, -d / 2 - 0.08))
		door:SetAttribute("Closed", closed)
		door:SetAttribute("Swing", if s < 0 then math.rad(100) else math.rad(-100))
		door.Name = if s < 0 then "WardrobeDoorL" else "WardrobeDoorR"
		local knob = deco(m, "WardrobeKnob", V(0.12, 0.9, 0.2), closed * CF(-s * (dw / 2 - 0.3), 0, -0.15), CHROME, M.Metal)
		knob:SetAttribute("FollowDoor", door.Name)
	end
	return back
end

function Furniture.dresser(ctx: Ctx, cf: CFrame, parent: Instance?)
	local m = group(parent or ctx.Model, "Dresser")
	local R = ctx.Rand
	solid(m, "Dresser", V(5, 3.2, 2), cf * CF(0, 1.6, 0), ctx.Wood, M.Wood)
	for k = 0, 2 do
		deco(m, "Drawer", V(4.6, 0.85, 0.08), cf * CF(0, 0.6 + k * 0.95, -1.03), ctx.Wood:Lerp(WHITE, 0.12), M.Wood)
		deco(m, "DrawerHandle", V(1, 0.12, 0.12), cf * CF(0, 0.6 + k * 0.95, -1.1), rgb(200, 180, 110), M.Metal)
	end
	deco(m, "Mirror", V(3.4, 3.6, 0.15), cf * CF(0, 5.2, 0.8), rgb(200, 215, 225), M.Glass).Reflectance = 0.5
	deco(m, "MirrorFrame", V(3.8, 4, 0.1), cf * CF(0, 5.2, 0.9), ctx.Wood, M.Wood)
	deco(m, "JewelBox", V(0.8, 0.5, 1.2), cf * CF(1.6, 3.45, 0), R.pick({ rgb(150, 40, 60), DARK, rgb(40, 60, 110) }), M.Fabric)
	cyl(m, "Perfume", 0.6, 0.35, cf * CF(-1.4, 3.5, 0.2), R.pick(Furniture.Palette.Accents), M.Glass)
end

-- Escritorio: tablero, cajonera, ordenador (pantalla con Use = "Computer") y silla
function Furniture.desk(ctx: Ctx, cf: CFrame, opts: { [string]: any }?, parent: Instance?): BasePart
	local o = opts or {}
	local m = group(parent or ctx.Model, "Desk")
	local R = ctx.Rand
	local w = o.Width or 5
	local c = o.Color or ctx.Wood
	-- La persona se sienta en -Z mirando a +Z; la pantalla en +Z mirando a -Z
	local top = solid(m, "DeskTop", V(w, 0.25, 2.6), cf * CF(0, 2.9, 0), c, M.Wood)
	solid(m, "DeskDrawers", V(1.6, 2.75, 2.4), cf * CF(w / 2 - 0.9, 1.4, 0), c:Lerp(DARK, 0.1), M.Wood)
	deco(m, "DeskPanel", V(0.2, 2.75, 2.4), cf * CF(-w / 2 + 0.2, 1.4, 0), c, M.Wood)
	deco(m, "Modesty", V(w - 0.4, 1.6, 0.12), cf * CF(0, 2, 1.15), c, M.Wood)
	if o.Computer ~= false then
		deco(m, "MonitorFoot", V(1, 0.08, 0.7), cf * CF(0, 3.06, 0.6), DARK)
		deco(m, "MonitorNeck", V(0.2, 0.8, 0.2), cf * CF(0, 3.45, 0.75), DARK)
		deco(m, "Monitor", V(2.8, 1.7, 0.15), cf * CF(0, 4.4, 0.7), rgb(24, 24, 28))
		local screen = deco(m, "Screen", V(2.6, 1.5, 0.05), cf * CF(0, 4.4, 0.61), rgb(30, 60, 100), M.Neon)
		usable(screen, "Computer", { On = false })
		deco(m, "Keyboard", V(2, 0.1, 0.7), cf * CF(0, 3.08, -0.4), R.pick({ DARK, WHITE }))
		deco(m, "Mouse", V(0.3, 0.12, 0.45), cf * CF(1.5, 3.08, -0.4), DARK)
		if o.Tower then
			deco(m, "PCTower", V(0.9, 2, 2), cf * CF(-w / 2 + 0.9, 1, 0.2), DARK)
		end
	end
	-- Cosas: taza, papeles, bote de lápices, foto, lámpara
	if R.chance(0.7) then
		cyl(m, "Mug", 0.5, 0.45, cf * CF(-w / 2 + 0.8, 3.28, -0.3), R.pick({ WHITE, rgb(200, 60, 50), rgb(60, 90, 150) }))
	end
	if R.chance(0.7) then
		deco(m, "Papers", V(1.1, 0.12, 1.4), cf * CF(-w / 2 + 1.2, 3.08, 0.4) * ANG(0, R.range(-0.3, 0.3), 0), WHITE)
	end
	if R.chance(0.5) then
		cyl(m, "PenCup", 0.6, 0.4, cf * CF(w / 2 - 0.7, 3.33, 0.8), R.pick(Furniture.Palette.Accents))
	end
	if R.chance(0.35) then
		deco(m, "Photo", V(0.8, 0.7, 0.1), cf * CF(w / 2 - 1.4, 3.4, 0.9) * ANG(math.rad(-12), 0, 0), rgb(200, 170, 120), M.Wood)
	end
	if o.Lamp and o.Room then
		Furniture.tableLamp(ctx, cf * CF(-w / 2 + 0.7, 3.02, 0.8), o.Room, m)
	end
	if o.Chair ~= false then
		Furniture.officeChair(ctx, cf * CF(0, 0, -2.3) * ANG(0, PI, 0), o.ChairColor, m)
	end
	return top
end

function Furniture.officeChair(ctx: Ctx, cf: CFrame, color: Color3?, parent: Instance?): Seat
	local m = group(parent or ctx.Model, "OfficeChair")
	local c = color or DARK
	for i = 0, 4 do
		local a = i / 5 * PI * 2
		deco(m, "ChairFoot", V(0.2, 0.15, 1.1), cf * CF(0, 0.2, 0) * ANG(0, a, 0) * CF(0, 0, -0.5), DARK)
	end
	deco(m, "ChairPost", V(0.25, 1.4, 0.25), cf * CF(0, 0.95, 0), CHROME, M.Metal)
	local seat = seatPart(m, cf * CF(0, 1.8, 0), V(2, 0.35, 2), c, M.Fabric, true)
	usable(seat, "Sit")
	deco(m, "ChairBack", V(1.9, 2.2, 0.25), cf * CF(0, 3.1, 0.95) * ANG(math.rad(-8), 0, 0), c, M.Fabric)
	return seat
end

---------------------------------------------------------------------
-- Baño
---------------------------------------------------------------------
function Furniture.toilet(ctx: Ctx, cf: CFrame, parent: Instance?)
	local m = group(parent or ctx.Model, "Toilet")
	solid(m, "ToiletBowl", V(1.6, 1.6, 2), cf * CF(0, 0.8, -0.2), WHITE, M.SmoothPlastic)
	solid(m, "ToiletTank", V(1.8, 1.6, 0.8), cf * CF(0, 2.2, 0.8), WHITE, M.SmoothPlastic)
	deco(m, "ToiletLid", V(1.5, 0.12, 1.8), cf * CF(0, 1.66, -0.3), rgb(250, 250, 250))
	deco(m, "Flush", V(0.35, 0.08, 0.35), cf * CF(0, 3.04, 0.8), CHROME, M.Metal)
	local seat = seatPart(m, cf * CF(0, 1.6, -0.2), V(1.6, 0.2, 1.6))
	usable(seat, "Sit")
	-- Rollo de papel en la pared
	cyl(m, "PaperRoll", 0.4, 0.5, cf * CF(1.5, 2.3, 0.5) * ANG(0, 0, PI / 2), WHITE)
end

-- Lavabo con grifo (Use = "Tap"), espejo y luz
function Furniture.vanity(ctx: Ctx, cf: CFrame, room: string, parent: Instance?)
	local m = group(parent or ctx.Model, "Vanity")
	local R = ctx.Rand
	local c = R.pick({ WHITE, ctx.Wood, rgb(90, 110, 130) })
	solid(m, "VanityCabinet", V(3.6, 2.8, 1.8), cf * CF(0, 1.4, 0), c, M.Wood)
	solid(m, "VanityTop", V(3.8, 0.2, 2), cf * CF(0, 2.9, 0), WHITE, M.Marble)
	deco(m, "Basin", V(2, 0.12, 1.3), cf * CF(0, 3.0, -0.1), rgb(235, 238, 240))
	deco(m, "TapPost", V(0.18, 0.8, 0.18), cf * CF(0, 3.4, 0.7), CHROME, M.Metal)
	local spout = deco(m, "TapSpout", V(0.18, 0.18, 0.6), cf * CF(0, 3.75, 0.45), CHROME, M.Metal)
	usable(spout, "Tap", { Spot = (cf * CF(0, 0, -2)).Position })
	water(spout)
	local mirror = deco(m, "Mirror", V(3, 3, 0.1), cf * CF(0, 5.4, 0.85), rgb(200, 215, 225), M.Glass)
	mirror.Reflectance = 0.5
	local bar = deco(m, "MirrorLight", V(2.6, 0.2, 0.3), cf * CF(0, 7.1, 0.75), rgb(255, 250, 240), M.Neon)
	roomLight(bar, room, 10, 0.7)
	cyl(m, "Toothbrushes", 0.6, 0.4, cf * CF(1.3, 3.3, 0.5), R.pick(Furniture.Palette.Accents), M.Glass)
	deco(m, "Soap", V(0.5, 0.25, 0.35), cf * CF(-1.3, 3.1, 0.5), R.pick({ rgb(240, 200, 220), rgb(200, 240, 210), WHITE }))
end

-- Ducha (plato con Use = "Shower", mampara y alcachofa con agua)
function Furniture.shower(ctx: Ctx, cf: CFrame, size: number?, parent: Instance?)
	-- (la mampara va en el lado -X y en parte de delante; la alcachofa en la esquina +X del fondo)
	local m = group(parent or ctx.Model, "Shower")
	local s = size or 4.4
	local tray = solid(m, "ShowerTray", V(s, 0.25, s), cf * CF(0, 0.12, 0), WHITE)
	usable(tray, "Shower", { Spot = (cf * CF(0, 0, 0)).Position })
	deco(m, "Drain", V(0.5, 0.26, 0.5), cf * CF(0, 0.13, 0), CHROME, M.Metal)
	local glass = rgb(200, 225, 240)
	deco(m, "ShowerGlass", V(0.12, 7.2, s), cf * CF(-s / 2, 3.85, 0), glass, M.Glass, 0.6)
	deco(m, "ShowerGlass", V(s * 0.45, 7.2, 0.12), cf * CF(-s / 2 + s * 0.225, 3.85, -s / 2), glass, M.Glass, 0.6)
	deco(m, "ShowerPipe", V(0.15, 6.4, 0.15), cf * CF(s / 2 - 0.4, 3.6, s / 2 - 0.2), CHROME, M.Metal)
	deco(m, "ShowerArm", V(0.15, 0.15, 1.4), cf * CF(s / 2 - 0.4, 6.8, s / 2 - 0.9), CHROME, M.Metal)
	local head = cyl(m, "ShowerHead", 0.15, 1.2, cf * CF(s / 2 - 0.4, 6.7, s / 2 - 1.6), CHROME, M.Metal)
	water(head, 18, 90)
	deco(m, "ShowerTap", V(0.4, 0.4, 0.2), cf * CF(s / 2 - 0.4, 3.8, s / 2 - 0.1), CHROME, M.Metal)
	deco(m, "ShampooShelf", V(1.4, 0.12, 0.6), cf * CF(-s / 2 + 1, 4.2, s / 2 - 0.35), CHROME, M.Metal)
	for k = 0, 2 do
		deco(m, "Bottle", V(0.3, 0.7, 0.3), cf * CF(-s / 2 + 0.6 + k * 0.4, 4.6, s / 2 - 0.35), ctx.Rand.pick(Furniture.Palette.Accents))
	end
end

function Furniture.bathtub(ctx: Ctx, cf: CFrame, parent: Instance?)
	local m = group(parent or ctx.Model, "Bathtub")
	solid(m, "Tub", V(3.4, 2.2, 7), cf * CF(0, 1.1, 0), WHITE)
	deco(m, "TubInside", V(2.8, 0.1, 6.4), cf * CF(0, 2.2, 0), rgb(236, 240, 244))
	deco(m, "TubWater", V(2.7, 0.1, 6.2), cf * CF(0, 1.9, 0), rgb(150, 200, 230), M.Glass, 0.4)
	deco(m, "TubTap", V(0.2, 1, 0.2), cf * CF(0, 2.7, 3.2), CHROME, M.Metal)
	local spout = deco(m, "TapSpout", V(0.2, 0.2, 0.7), cf * CF(0, 3.1, 2.95), CHROME, M.Metal)
	usable(spout, "Tap", { Spot = (cf * CF(-2.6, 0, 1.5)).Position })
	water(spout, 6, 70)
	deco(m, "RubberDuck", V(0.5, 0.5, 0.5), cf * CF(0.5, 2.1, -1), rgb(250, 210, 40))
end

function Furniture.towelRail(ctx: Ctx, cf: CFrame, parent: Instance?)
	local m = group(parent or ctx.Model, "TowelRail")
	deco(m, "Rail", V(3, 0.15, 0.15), cf * CF(0, 5, -0.3), CHROME, M.Metal)
	for k = -1, 1, 2 do
		deco(m, "Towel", V(1.3, 2.4, 0.2), cf * CF(k * 0.7, 3.9, -0.35), ctx.Rand.pick({ WHITE, ctx.Accent, rgb(120, 170, 210), rgb(240, 200, 170) }), M.Fabric)
	end
end

---------------------------------------------------------------------
-- Oficinas, aulas y tiendas
---------------------------------------------------------------------
-- Tele colgada en la pared (cf en la pared, mirando a la sala)
function Furniture.wallTV(ctx: Ctx, cf: CFrame, w: number?, parent: Instance?): BasePart
	local m = group(parent or ctx.Model, "WallTV")
	local tw = w or 6
	local th = tw * 0.56
	deco(m, "TV", V(tw, th, 0.3), cf * CF(0, 0, -0.2), rgb(18, 18, 22))
	local screen = deco(m, "TVScreen", V(tw - 0.3, th - 0.3, 0.05), cf * CF(0, 0, -0.37), rgb(12, 14, 18), M.Glass)
	return usable(screen, "TV", { On = false, Channel = 0 })
end

function Furniture.printer(ctx: Ctx, cf: CFrame, parent: Instance?)
	local m = group(parent or ctx.Model, "Printer")
	solid(m, "PrinterStand", V(2.4, 2.4, 2), cf * CF(0, 1.2, 0), rgb(200, 200, 204))
	deco(m, "Printer", V(2.2, 1.2, 1.8), cf * CF(0, 3, 0), rgb(236, 236, 236))
	deco(m, "PrinterTray", V(1.4, 0.1, 0.8), cf * CF(0, 3.2, -1), WHITE)
	deco(m, "PrinterPanel", V(0.6, 0.3, 0.05), cf * CF(0.6, 3.4, -0.92), rgb(60, 160, 230), M.Neon)
end

function Furniture.waterCooler(ctx: Ctx, cf: CFrame, parent: Instance?)
	local m = group(parent or ctx.Model, "WaterCooler")
	solid(m, "CoolerBody", V(1.6, 3.4, 1.6), cf * CF(0, 1.7, 0), WHITE)
	cyl(m, "Bottle", 1.8, 1.4, cf * CF(0, 4.3, 0), rgb(150, 200, 240), M.Glass).Transparency = 0.3
	local tap = deco(m, "TapSpout", V(0.3, 0.3, 0.4), cf * CF(0, 2.8, -0.9), rgb(60, 120, 220))
	usable(tap, "Tap", { Spot = (cf * CF(0, 0, -2.2)).Position })
	water(tap, 2, 30)
	for k = 0, 3 do
		cyl(m, "Cup", 0.4, 0.4, cf * CF(0.95, 2.2 + k * 0.1, 0), WHITE)
	end
end

function Furniture.filingCabinet(ctx: Ctx, cf: CFrame, parent: Instance?): BasePart
	local m = group(parent or ctx.Model, "Cabinet")
	local c = solid(m, "Archivo", V(2.2, 4.4, 2), cf * CF(0, 2.2, 0), STEEL, M.Metal)
	for k = 0, 2 do
		deco(m, "Drawer", V(1.9, 1.2, 0.08), cf * CF(0, 0.9 + k * 1.35, -1.03), rgb(176, 182, 190), M.Metal)
		deco(m, "Handle", V(0.8, 0.12, 0.12), cf * CF(0, 1.2 + k * 1.35, -1.1), DARK, M.Metal)
	end
	return c
end

function Furniture.whiteboard(ctx: Ctx, cf: CFrame, w: number?, parent: Instance?)
	local m = group(parent or ctx.Model, "Whiteboard")
	local bw = w or 8
	deco(m, "BoardFrame", V(bw + 0.3, 4.3, 0.15), cf * CF(0, 6, -0.08), STEEL, M.Metal)
	deco(m, "Board", V(bw, 4, 0.1), cf * CF(0, 6, -0.18), WHITE)
	-- Garabatos de colores
	local R = ctx.Rand
	for i = 1, 5 do
		deco(m, "Scribble", V(R.range(1, bw * 0.4), 0.15, 0.04), cf * CF(R.range(-bw / 3, bw / 3), 6 + R.range(-1.4, 1.4), -0.25), R.pick({ rgb(40, 60, 170), rgb(200, 40, 40), rgb(30, 130, 60), DARK }))
	end
	deco(m, "Tray", V(bw * 0.6, 0.15, 0.4), cf * CF(0, 3.9, -0.3), STEEL, M.Metal)
end

-- Estantería de tienda con productos (kind: "Food" | "Clothes" | "Pharmacy" | "Tools" | "Books" | "Tech" | "Toys")
function Furniture.shopShelf(ctx: Ctx, cf: CFrame, w: number, kind: string?, parent: Instance?)
	local m = group(parent or ctx.Model, "ShopShelf")
	local R = ctx.Rand
	local k = kind or "Food"
	if k == "Books" then
		Furniture.bookshelf(ctx, cf, w, 7.5, m)
		return m
	end
	if k == "Clothes" then
		-- Burro con perchas
		for _, s in { -1, 1 } do
			deco(m, "RackPost", V(0.2, 5.5, 0.2), cf * CF(s * (w / 2 - 0.2), 2.75, 0), CHROME, M.Metal)
			deco(m, "RackFoot", V(0.2, 0.15, 1.6), cf * CF(s * (w / 2 - 0.2), 0.08, 0), CHROME, M.Metal)
		end
		deco(m, "RackBar", V(w, 0.15, 0.15), cf * CF(0, 5.4, 0), CHROME, M.Metal)
		local x = -w / 2 + 0.6
		while x < w / 2 - 0.6 do
			deco(m, "Garment", V(0.3, R.range(2.4, 3.4), 1.8), cf * CF(x, 3.8, 0), R.pick(Furniture.Palette.Fabrics), M.Fabric)
			x += 0.45
		end
		return m
	end
	local white = k == "Pharmacy" or k == "Tech"
	local c = if white then WHITE elseif k == "Tools" then rgb(70, 90, 130) else R.pick({ ctx.Wood, rgb(200, 200, 204) })
	solid(m, "ShelfUnit", V(w, 7, 0.4), cf * CF(0, 3.5, 0.9), c)
	for _, s in { -1, 1 } do
		solid(m, "ShelfEnd", V(0.3, 7, 2.2), cf * CF(s * (w / 2 - 0.15), 3.5, 0), c)
	end
	for row = 0, 3 do
		local y = 0.4 + row * 1.7
		deco(m, "ShelfBoard", V(w - 0.4, 0.15, 2), cf * CF(0, y, 0), c:Lerp(DARK, 0.08))
		local x = -w / 2 + 0.5
		while x < w / 2 - 0.5 do
			local pw = R.range(0.5, 0.9)
			local ph = R.range(0.6, 1.3)
			local color = R.pick(Furniture.Palette.Products)
			if k == "Pharmacy" then
				color = R.pick({ WHITE, rgb(60, 170, 90), rgb(90, 150, 220), rgb(240, 200, 220) })
			end
			if k == "Tools" and R.chance(0.4) then
				cyl(m, "PaintCan", ph, pw, cf * CF(x + pw / 2, y + 0.08 + ph / 2, 0), color, M.Metal)
			elseif R.chance(0.25) then
				cyl(m, "Jar", ph, pw * 0.9, cf * CF(x + pw / 2, y + 0.08 + ph / 2, 0), color, M.Glass)
			else
				deco(m, "Product", V(pw, ph, 1.1), cf * CF(x + pw / 2, y + 0.08 + ph / 2, 0), color)
			end
			x += pw + 0.12
		end
		-- Etiqueta del precio
		deco(m, "PriceStrip", V(w - 0.6, 0.25, 0.05), cf * CF(0, y - 0.05, -1.02), rgb(250, 230, 90))
	end
	return m
end

-- Mostrador con caja registradora y sitio del dependiente (ClerkSpot)
function Furniture.checkout(ctx: Ctx, cf: CFrame, w: number, color: Color3?, parent: Instance?): BasePart
	local m = group(parent or ctx.Model, "Checkout")
	-- El cliente está en -Z; el dependiente detrás, en +Z
	local counter = solid(m, "Counter", V(w, 3.6, 2.4), cf * CF(0, 1.8, 0), color or rgb(170, 60, 60), M.Wood)
	solid(m, "CounterTop", V(w + 0.4, 0.2, 2.8), cf * CF(0, 3.7, 0), WHITE, M.Marble)
	deco(m, "Register", V(1.6, 0.8, 1.4), cf * CF(w / 2 - 1.4, 4.2, 0.3), DARK)
	deco(m, "RegisterScreen", V(1.2, 0.8, 0.1), cf * CF(w / 2 - 1.4, 4.9, 0.1) * ANG(math.rad(-20), 0, 0), rgb(80, 200, 140), M.Neon)
	deco(m, "CardReader", V(0.5, 0.2, 0.8), cf * CF(w / 2 - 2.8, 3.9, -0.6), DARK)
	deco(m, "Scale", V(1.2, 0.2, 1.2), cf * CF(-w / 2 + 1.2, 3.9, 0), CHROME, M.Metal)
	-- Chucherías junto a la caja
	for i = 0, 3 do
		deco(m, "Candy", V(0.5, 0.3, 0.8), cf * CF(-w / 2 + 2.6 + i * 0.6, 3.95, -0.8), ctx.Rand.pick(Furniture.Palette.Products))
	end
	Builder.part({ Name = "ClerkSpot", Size = V(2, 2, 2), CFrame = cf * CF(0, 0, 2.6) * ANG(0, PI, 0), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Tags = { "ClerkSpot" }, Parent = m })
	return counter
end

-- Nevera de bebidas (tiendas y bares): Use = "Fridge" (en las tiendas se paga)
function Furniture.drinksCooler(ctx: Ctx, cf: CFrame, parent: Instance?): BasePart
	local m = group(parent or ctx.Model, "Cooler")
	local body = solid(m, "CoolerBack", V(4, 7, 0.3), cf * CF(0, 3.5, 1.1), rgb(40, 44, 50), M.Metal)
	usable(body, "Fridge")
	for _, s in { -1, 1 } do
		solid(m, "CoolerSide", V(0.3, 7, 2.4), cf * CF(s * 1.85, 3.5, 0), rgb(40, 44, 50), M.Metal)
	end
	solid(m, "CoolerBase", V(4, 0.8, 2.4), cf * CF(0, 0.4, 0), rgb(40, 44, 50), M.Metal)
	local sign = deco(m, "CoolerSign", V(3.6, 0.8, 0.2), cf * CF(0, 6.6, -1.1), rgb(40, 150, 230), M.Neon)
	sign.CastShadow = false
	local R = ctx.Rand
	for row = 0, 3 do
		local y = 1.2 + row * 1.35
		deco(m, "CoolerShelf", V(3.4, 0.08, 2), cf * CF(0, y, 0), rgb(200, 210, 220), M.Metal)
		for k = 0, 5 do
			cyl(m, "Can", 0.9, 0.45, cf * CF(-1.4 + k * 0.56, y + 0.5, 0), R.pick({ rgb(220, 40, 40), rgb(250, 200, 40), rgb(60, 160, 230), rgb(60, 180, 90), rgb(240, 120, 30) }), M.Metal)
		end
	end
	local closed = cf * CF(0, 3.5, -1.25)
	local door = deco(m, "CoolerDoor", V(3.6, 6.8, 0.1), closed, rgb(200, 230, 245), M.Glass, 0.55)
	door:SetAttribute("Hinge", cf * CF(1.8, 3.5, -1.25))
	door:SetAttribute("Closed", closed)
	door:SetAttribute("Swing", math.rad(-95))
	return body
end

function Furniture.bench(ctx: Ctx, cf: CFrame, length: number, color: Color3?, parent: Instance?): Model
	local m = group(parent or ctx.Model, "Bench")
	local c = color or ctx.Wood
	local top = solid(m, "BenchSeat", V(length, 0.4, 1.8), cf * CF(0, 1.8, 0), c, M.Wood)
	usable(top, "Sit")
	deco(m, "BenchBack", V(length, 1.6, 0.25), cf * CF(0, 2.9, 0.85) * ANG(math.rad(-8), 0, 0), c, M.Wood)
	for _, s in { -1, 1 } do
		deco(m, "BenchLeg", V(0.3, 1.6, 1.6), cf * CF(s * (length / 2 - 0.4), 0.8, 0), DARK, M.Metal)
	end
	local n = math.max(1, math.floor(length / 2.3))
	for i = 1, n do
		seatPart(m, cf * CF(-length / 2 + (i - 0.5) * length / n, 2.05, 0))
	end
	return m
end

-- Taquilla metálica (vestuarios, taller, cuartel)
function Furniture.lockers(ctx: Ctx, cf: CFrame, count: number, color: Color3?, parent: Instance?)
	local m = group(parent or ctx.Model, "Lockers")
	local c = color or rgb(90, 110, 140)
	local w = count * 1.6
	solid(m, "Lockers", V(w, 7, 2), cf * CF(0, 3.5, 0), c, M.Metal)
	for i = 0, count - 1 do
		local x = -w / 2 + 0.8 + i * 1.6
		deco(m, "LockerDoor", V(1.45, 6.6, 0.08), cf * CF(x, 3.5, -1.03), c:Lerp(WHITE, 0.1), M.Metal)
		for k = 0, 2 do
			deco(m, "Vent", V(0.9, 0.08, 0.05), cf * CF(x, 6 + k * 0.25, -1.08), DARK)
		end
		deco(m, "LockerHandle", V(0.12, 0.6, 0.12), cf * CF(x + 0.5, 3.6, -1.12), CHROME, M.Metal)
	end
end

function Furniture.clock(ctx: Ctx, cf: CFrame, parent: Instance?)
	local m = group(parent or ctx.Model, "Clock")
	local face = deco(m, "ClockFace", V(0.2, 2, 2), cf * CF(0, 0, -0.1) * ANG(0, PI / 2, 0), WHITE)
	face.Shape = Enum.PartType.Cylinder
	deco(m, "HourHand", V(0.12, 0.6, 0.05), cf * CF(0, 0.25, -0.25), DARK)
	deco(m, "MinuteHand", V(0.7, 0.08, 0.05), cf * CF(0.3, 0, -0.25), DARK)
end

return Furniture
