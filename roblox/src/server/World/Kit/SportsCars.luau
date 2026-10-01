-- SportsCars: los 13 vehículos premium del pase de temporada, con todo detalle (los datos de cada
-- uno están en shared/PremiumVehicles). Los construye Rides.build cuando el vehículo lleva modelo
-- premium (Rides.build(kind, parent, cf, color, { Model = id })): el resto del juego los ve como un
-- «Coche» o una «Moto» normales (conducción, choques, combustible, ruedas que giran, luces, taller).
--
--   Coches (≤ SportsCars.MaxParts.Coche piezas, solo primitivas: bloques, cuñas y cilindros):
--     carrocería por perfiles (capó / zaga en el centro, aletas y puertas a los lados con los pasos de
--     rueda abiertos y achaflanados), habitáculo con parabrisas, techo, luneta o tapa del motor,
--     ventanillas, montantes y retrovisores; frontal con parrilla, tomas, splitter y aletines; faros
--     LED con firma diurna propia de cada coche; pilotos (redondos, de lado a lado, partidos, en Y o en
--     X), luz de freno central, marcha atrás e intermitentes; difusor con aletas y escapes; taloneras;
--     alerón (GT, cuello de cisne, cola de pato, labio o activo); franjas; rejillas; neón y líneas de
--     luz; interior (asientos baquet, volante, salpicadero con pantallas que brillan, consola) y
--     matrículas VALMAR. Ruedas de perfil bajo con llanta de radios, disco y pinza de color.
--   Motos (≤ SportsCars.MaxParts.Moto): ruedas con disco y pinza, horquilla invertida, chasis,
--     basculante, amortiguador, motor, radiador, escape, depósito, asientos, colín con LED,
--     carenado con cúpula (deportivas) o faro desnudo y manillar ancho (naked), mandos, estriberas,
--     cadena, pata de cabra (como la moto de siempre: Kickstand) y matrícula.
--
-- Nombres reservados que usan otros sistemas (no cambiarlos): Body, Headlight, HeadlightRight,
-- HeadlightSmall, Taillight, ThirdBrake, Reverse, IndicatorFront / IndicatorRear / Indicator,
-- PlateFront / PlateRear / Plate, Wheel (+ Rim, RimInner, Spoke, Hub, BrakeDisc, Cog que giran con
-- ella; Fork, FenderFront y Caliper que giran con el volante: shared/WheelRig), Kickstand.
-- Las piezas que no son simétricas a propósito (volante, cadena, disco trasero…) llevan Asym = true.
--
-- Convención: cf = centro a ras de suelo, el morro mira a −Z, el conductor a la izquierda (−X).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Builder = require(script.Parent.Parent.Builder)
local PremiumVehicles = require(ReplicatedStorage.Shared.PremiumVehicles)

local SportsCars = {}

SportsCars.Specs = PremiumVehicles
SportsCars.MaxParts = { Coche = 220, Moto = 140 }

local rgb = Color3.fromRGB
local function c3(t: { number }?, fallback: Color3): Color3
	return if t then rgb(t[1], t[2], t[3]) else fallback
end

local SMOOTH, METAL, NEON, GLASSM, RUBBER, FABRIC = Enum.Material.SmoothPlastic, Enum.Material.Metal, Enum.Material.Neon, Enum.Material.Glass, Enum.Material.Rubber, Enum.Material.Fabric
local TIRE = rgb(22, 22, 24)
local DARK = rgb(14, 14, 16)
local CARBON = rgb(32, 33, 37)
local GLASS = rgb(30, 40, 52)
local LENS = rgb(222, 232, 250)
local TAIL = rgb(178, 18, 28)
local AMBER = rgb(255, 150, 20)
local REVERSE = rgb(206, 208, 214)
local DISC = rgb(150, 152, 158)
local CHROME = rgb(205, 208, 214)
local INTERIOR = rgb(30, 30, 34)
local SEAT = rgb(26, 26, 30)
local PLATE = rgb(240, 240, 240)
local REFLECT = { Gloss = 0.1, Metallic = 0.22, Matte = 0 }

-- Medidas comunes de los coches
local HW, IW = 3.15, 1.95 -- medio ancho de la carrocería y del centro (capó / zaga)
local Z_NOSE, Z_TAIL = -6.75, 6.75
local YB = 0.62 -- bajo de los laterales
local FLOOR_TOP = 0.94 -- encima del suelo (pieza Body)
local YA, YSTEP, CH, ARCH = 2.85, 1.9, 0.6, 1.62 -- paso de rueda: techo, arranque del chaflán, chaflán y medio largo

local ALONG_Z = CFrame.Angles(0, math.pi / 2, 0) -- (un cilindro va a lo largo de X: así, a lo largo de Z)
local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2) -- (cilindro de pie: a lo largo de Y)

---------------------------------------------------------------------
-- Piezas (estado de la construcción en curso: se construye de una vez, sin esperas)
---------------------------------------------------------------------
type Ctx = {
	m: Model,
	cf: CFrame,
	spec: { [string]: any },
	paint: Color3,
	second: Color3,
	accent: Color3,
	glow: Color3,
	reflect: number,
}
local ctx: Ctx = nil :: any

local function make(class: string, name: string, size: Vector3, lcf: CFrame, color: Color3, mat: Enum.Material?, solid: boolean?, transparency: number?, shape: Enum.PartType?): BasePart
	local props: { [string]: any } = {
		Name = name,
		Size = size,
		CFrame = ctx.cf * lcf,
		Color = color,
		Material = mat or SMOOTH,
		Transparency = transparency or 0,
		Parent = ctx.m,
	}
	if class ~= "Part" then
		props.ClassName = class
	end
	if shape then
		props.Shape = shape
	end
	return if solid then Builder.part(props) else Builder.decor(props)
end
local function box(name: string, size: Vector3, lcf: CFrame, color: Color3, mat: Enum.Material?, solid: boolean?, transparency: number?): BasePart
	return make("Part", name, size, lcf, color, mat, solid, transparency)
end
local function wedge(name: string, size: Vector3, lcf: CFrame, color: Color3, mat: Enum.Material?, solid: boolean?, transparency: number?): BasePart
	return make("WedgePart", name, size, lcf, color, mat, solid, transparency)
end
local function cyl(name: string, length: number, diameter: number, lcf: CFrame, color: Color3, mat: Enum.Material?, solid: boolean?, transparency: number?): BasePart
	return make("Part", name, Vector3.new(length, diameter, diameter), lcf, color, mat, solid, transparency, Enum.PartType.Cylinder)
end
local function at(x: number, y: number, z: number): CFrame
	return CFrame.new(x, y, z)
end
local function mirror(fn: (number) -> ())
	fn(-1)
	fn(1)
end
-- Pintura de la carrocería (brillo según el acabado)
local function painted(part: BasePart): BasePart
	part.Reflectance = ctx.reflect
	return part
end
local function asym(part: BasePart): BasePart
	part:SetAttribute("Asym", true)
	return part
end
local function neon(name: string, size: Vector3, lcf: CFrame, color: Color3?): BasePart
	return box(name, size, lcf, color or ctx.glow, NEON)
end

-- Tubo de a hasta b (puntos locales), a lo largo de su Z (como Rides.tubeFrame)
local function tubeFrame(a: Vector3, b: Vector3): CFrame
	local d = b - a
	local angle = math.atan2(-d.Y, d.Z)
	local yaw = math.atan2(d.X, math.sqrt(d.Y * d.Y + d.Z * d.Z))
	return CFrame.new((a + b) / 2) * CFrame.Angles(angle, 0, 0) * CFrame.Angles(0, yaw, 0)
end
SportsCars.tubeFrame = tubeFrame
local function tube(name: string, a: Vector3, b: Vector3, thickness: number, color: Color3, mat: Enum.Material?): BasePart
	return box(name, Vector3.new(thickness, thickness, (b - a).Magnitude), tubeFrame(a, b), color, mat or METAL)
end

---------------------------------------------------------------------
-- Perfiles: listas de estaciones {z, alto, bajo} de delante a atrás. Cada tramo es un bloque y,
-- si cambia la altura de arriba o la de abajo, una cuña encima o debajo.
---------------------------------------------------------------------
local function extrude(name: string, xc: number, width: number, stations: { { number } }, color: Color3, isSolid: boolean)
	for i = 1, #stations - 1 do
		local a, b = stations[i], stations[i + 1]
		local len = b[1] - a[1]
		if len < 0.02 then
			continue
		end
		local zc = (a[1] + b[1]) / 2
		local tLo, tHi = math.min(a[2], b[2]), math.max(a[2], b[2])
		local bLo, bHi = math.min(a[3], b[3]), math.max(a[3], b[3])
		if tLo - bHi > 0.02 then
			painted(box(name, Vector3.new(width, tLo - bHi, len), at(xc, (tLo + bHi) / 2, zc), color, SMOOTH, isSolid))
		end
		if tHi - tLo > 0.03 then
			local turn = if b[2] > a[2] then CFrame.new() else CFrame.Angles(0, math.pi, 0)
			painted(wedge(name, Vector3.new(width, tHi - tLo, len), at(xc, (tHi + tLo) / 2, zc) * turn, color, SMOOTH, isSolid))
		end
		if bHi - bLo > 0.03 then
			-- (cuña del revés: gruesa donde el bajo está más abajo)
			local turn = if a[3] < b[3] then CFrame.Angles(math.pi, 0, 0) else CFrame.Angles(0, 0, math.pi)
			painted(wedge(name, Vector3.new(width, bHi - bLo, len), at(xc, (bHi + bLo) / 2, zc) * turn, color, SMOOTH, isSolid))
		end
	end
end

-- Altura y pendiente del perfil en z
local function surface(stations: { { number } }, z: number): (number, number)
	for i = 1, #stations - 1 do
		local a, b = stations[i], stations[i + 1]
		if b[1] - a[1] > 0.02 and z >= a[1] - 1e-4 and z <= b[1] + 1e-4 then
			local t = (z - a[1]) / (b[1] - a[1])
			return a[2] + (b[2] - a[2]) * t, math.atan2(b[2] - a[2], b[1] - a[1])
		end
	end
	return stations[#stations][2], 0
end
-- Sitio encima del perfil (apoyado en su pendiente), levantado «lift» por su normal
local function onTop(stations: { { number } }, x: number, z: number, lift: number?): (CFrame, number)
	local y, angle = surface(stations, z)
	return CFrame.new(x, y, z) * CFrame.Angles(-angle, 0, 0) * CFrame.new(0, lift or 0, 0), angle
end
-- Tira fina apoyada en el perfil, de (x0, z0) a (x1, z1)
local function stripOn(stations: { { number } }, name: string, x0: number, z0: number, x1: number, z1: number, width: number, thick: number, color: Color3, mat: Enum.Material?): BasePart
	local base, angle = onTop(stations, (x0 + x1) / 2, (z0 + z1) / 2, thick / 2)
	local ds = (z1 - z0) / math.cos(angle)
	local dx = x1 - x0
	return box(name, Vector3.new(width, thick, math.sqrt(dx * dx + ds * ds)), base * CFrame.Angles(0, math.atan2(dx, ds), 0), color, mat)
end
-- Franja que sigue un tramo del perfil
local function stripSegment(name: string, x: number, width: number, a: { number }, b: { number }, color: Color3): BasePart
	local dz, dy = b[1] - a[1], b[2] - a[2]
	local angle = math.atan2(dy, dz)
	return box(name, Vector3.new(width, 0.03, math.sqrt(dz * dz + dy * dy)), at(x, (a[2] + b[2]) / 2, (a[1] + b[1]) / 2) * CFrame.Angles(-angle, 0, 0) * CFrame.new(0, 0.015, 0), color)
end

local function withBottom(list: { { number } }, bottom: number): { { number } }
	local out = {}
	for _, s in list do
		table.insert(out, { s[1], s[2], bottom })
	end
	return out
end

-- Laterales (aletas y puertas): hombros de la silueta con los pasos de rueda abiertos
local function sideStations(g: { [string]: any }): { { number } }
	local w, sd = g.Wheels, g.Side
	local f0, f1, r0, r1 = w.Front - ARCH, w.Front + ARCH, w.Rear - ARCH, w.Rear + ARCH
	local mid = (sd.Nose + sd.Peak) / 2 + 0.12
	return {
		{ Z_NOSE + 0.05, sd.Nose, YB },
		{ f0, mid, YB },
		{ f0, mid, YSTEP },
		{ f0 + CH, sd.Peak, YA },
		{ f1 - CH, sd.Peak, YA },
		{ f1, sd.DoorF, YSTEP },
		{ f1, sd.DoorF, YB },
		{ r0, sd.DoorR, YB },
		{ r0, sd.DoorR, YSTEP },
		{ r0 + CH, sd.RearPeak, YA },
		{ r1 - CH, sd.RearPeak, YA },
		{ r1, sd.RearPeak - 0.02, YSTEP },
		{ r1, sd.RearPeak - 0.02, YB },
		{ Z_TAIL, sd.Tail, YB },
	}
end

---------------------------------------------------------------------
-- Ruedas de coche: neumático de perfil bajo, llanta, fondo, disco, pinza (no gira), radios y buje
---------------------------------------------------------------------
local RIM_STYLES = {
	Five = { { Bars = 5, Width = 0.3, Radial = true } },
	Ten = { { Bars = 5, Width = 0.13 } },
	Y = { { Bars = 3, Width = 0.13 }, { Bars = 3, Width = 0.13, Offset = 20 } },
	Mesh = { { Bars = 6, Width = 0.07 } },
}
local function carWheel(sx: number, z: number)
	local spec = ctx.spec
	local w = spec.Geometry.Wheels
	local R, width, rimD = w.Radius, w.Width, w.Rim
	local hub = at(sx * w.X, R, z)
	local rimColor = c3(spec.Rims.Color, CHROME)
	local caliper = c3(spec.Caliper, ctx.accent)
	cyl("Wheel", width, R * 2, hub, TIRE, RUBBER)
	cyl("Rim", width + 0.03, rimD, hub, rimColor, METAL)
	cyl("RimInner", width + 0.05, rimD - 0.22, hub, DARK)
	local face = width / 2 + 0.025 -- (cara del fondo oscuro)
	cyl("BrakeDisc", 0.02, rimD - 0.55, hub * CFrame.new(sx * (face + 0.012), 0, 0), DISC, METAL)
	-- Pinza: arriba y hacia el centro del coche (delante, detrás de la rueda; detrás, delante)
	local alpha = if z < 0 then math.rad(35) else math.rad(-35)
	local rc = (rimD - 0.55) / 2 - 0.12
	box("Caliper", Vector3.new(0.035, 0.24, 0.62), hub * CFrame.new(sx * (face + 0.04), rc * math.cos(alpha), rc * math.sin(alpha)) * CFrame.Angles(alpha, 0, 0), caliper)
	local ux = sx * (face + 0.08)
	local rimR = rimD / 2 - 0.08
	for _, layer in RIM_STYLES[spec.Rims.Style or "Ten"] or RIM_STYLES.Ten do
		for k = 0, layer.Bars - 1 do
			local angle = math.rad(layer.Offset or 0)
			if layer.Radial then
				angle += k * math.pi * 2 / layer.Bars
				box("Spoke", Vector3.new(0.06, layer.Width, rimR - 0.18), hub * CFrame.new(ux, 0, 0) * CFrame.Angles(angle, 0, 0) * CFrame.new(0, 0, (rimR + 0.18) / 2), rimColor, METAL)
			else
				angle += k * math.pi / layer.Bars
				box("Spoke", Vector3.new(0.06, layer.Width, rimR * 2), hub * CFrame.new(ux, 0, 0) * CFrame.Angles(angle, 0, 0), rimColor, METAL)
			end
		end
	end
	cyl("Hub", 0.08, 0.42, hub * CFrame.new(sx * (face + 0.1), 0, 0), if spec.Rims.Style == "Mesh" then caliper else DARK, METAL)
end

---------------------------------------------------------------------
-- Coches
---------------------------------------------------------------------
local function buildCar()
	local spec = ctx.spec
	local g = spec.Geometry
	local w, cab = g.Wheels, g.Cabin
	local paint, second, accent, glow = ctx.paint, ctx.second, ctx.accent, ctx.glow
	local f0, f1, r0 = w.Front - ARCH, w.Front + ARCH, w.Rear - ARCH
	local hood = withBottom(g.Hood, FLOOR_TOP)
	local deck = withBottom(g.Deck, FLOOR_TOP)
	local sides = sideStations(g)
	local zW, z0, z1, zB = cab.Base, cab.RoofFront, cab.RoofBack, cab.Back
	local belt, roofY, hc = cab.Belt, cab.Roof, cab.Half
	local isSuper = spec.Shape == "Super"
	local frameColor = if isSuper or spec.BlackRoof then second else paint
	local glassColor = c3(spec.Tint, GLASS)

	-- 1. Carrocería: suelo (Body), capó y zaga en el centro, aletas y puertas a los lados
	painted(box("Body", Vector3.new(IW * 2, 0.36, 12.3), at(0, 0.76, 0), paint, SMOOTH, true))
	extrude("Panel", 0, IW * 2, hood, paint, true)
	extrude("Panel", 0, IW * 2, deck, paint, true)
	mirror(function(sx)
		extrude("Panel", sx * (IW + HW) / 2, HW - IW, sides, paint, true)
	end)
	-- Fondo oscuro de los pasos de rueda (no se ve el interior de la carrocería)
	for _, z in { w.Front, w.Rear } do
		mirror(function(sx)
			box("WheelWell", Vector3.new(0.04, YA - YB, ARCH * 2), at(sx * (IW + 0.025), (YA + YB) / 2, z), DARK)
		end)
	end

	-- 2. Habitáculo
	local rise, run = roofY - belt, z0 - zW
	local wa, wl = math.atan2(rise, run), math.sqrt(rise * rise + run * run)
	local windCf = at(0, (belt + roofY) / 2, (zW + z0) / 2) * CFrame.Angles(-wa, 0, 0)
	box("Windshield", Vector3.new(hc * 2 - 0.25, 0.12, wl), windCf, glassColor, GLASSM, true, 0.4)
	painted(box(if spec.BlackRoof then "Livery" else "Roof", Vector3.new(hc * 2 - 0.35, 0.2, z1 - z0 + 0.1), at(0, roofY - 0.04, (z0 + z1) / 2), if spec.BlackRoof then second else paint, SMOOTH, true))
	local back, drop = zB - z1, roofY - cab.BackY
	local ra, rl = math.atan2(drop, back), math.sqrt(back * back + drop * drop)
	local rearCf = at(0, (roofY + cab.BackY) / 2, (z1 + zB) / 2) * CFrame.Angles(ra, 0, 0)
	local h = roofY - belt - 0.12
	if cab.Style == "Engine" then
		-- Tapa del motor de cristal entre dos arbotantes, con lamas y el motor debajo
		box("EngineCover", Vector3.new(hc * 2 - 1.5, 0.1, rl), rearCf, glassColor, GLASSM, true, 0.45)
		mirror(function(sx)
			painted(box("Panel", Vector3.new(0.72, 0.16, rl), rearCf * CFrame.new(sx * (hc - 0.38), 0.02, 0), paint, SMOOTH, true))
			-- Aleta trasera (sin ventanilla: el arbotante baja hasta la cintura)
			local x = sx * (hc - 0.05)
			painted(box("Panel", Vector3.new(0.12, cab.BackY - belt, back), at(x, (belt + cab.BackY) / 2, (z1 + zB) / 2), paint, SMOOTH, true))
			painted(wedge("Panel", Vector3.new(0.12, roofY - 0.1 - cab.BackY, back), at(x, (roofY - 0.1 + cab.BackY) / 2, (z1 + zB) / 2) * CFrame.Angles(0, math.pi, 0), paint, SMOOTH, true))
		end)
		local slats = if spec.Louvers then 6 else 3
		for i = 1, slats do
			box("EngineSlat", Vector3.new(hc * 2 - 1.6, 0.05, 0.12), rearCf * CFrame.new(0, 0.07, -rl / 2 + rl * i / (slats + 1)), DARK)
		end
		local ey = surface(deck, 2.9)
		box("Engine", Vector3.new(1.9, 0.4, 2.2), at(0, ey + 0.2, 2.9), CARBON, METAL)
		mirror(function(sx)
			box("EngineCap", Vector3.new(0.5, 0.12, 1.8), at(sx * 0.5, ey + 0.46, 2.9), accent, METAL)
		end)
	else
		box("RearWindow", Vector3.new(hc * 2 - 0.35, 0.12, rl), rearCf, glassColor, GLASSM, true, 0.4)
		mirror(function(sx)
			painted(box("PillarC", Vector3.new(0.45, 0.18, rl), rearCf * CFrame.new(sx * (hc - 0.25), 0.02, 0), frameColor, SMOOTH))
			wedge("SideWindowRear", Vector3.new(0.1, h, back), at(sx * (hc - 0.03), belt + h / 2, (z1 + zB) / 2) * CFrame.Angles(0, math.pi, 0), glassColor, GLASSM, true, 0.4)
		end)
	end
	mirror(function(sx)
		local x = sx * (hc - 0.03)
		box("SideWindow", Vector3.new(0.1, h, z1 - z0), at(x, belt + h / 2, (z0 + z1) / 2), glassColor, GLASSM, true, 0.4)
		wedge("SideWindowFront", Vector3.new(0.1, h, z0 - zW), at(x, belt + h / 2, (zW + z0) / 2), glassColor, GLASSM, true, 0.4)
		box("PillarA", Vector3.new(0.18, 0.2, wl), at(x, (belt + roofY) / 2, (zW + z0) / 2) * CFrame.Angles(-wa, 0, 0), frameColor)
		local trimEnd = if cab.Style == "Engine" then z1 else zB
		box("WindowTrim", Vector3.new(0.08, 0.06, trimEnd - zW), at(sx * (hc + 0.01), belt + 0.06, (zW + trimEnd) / 2), if spec.Shape == "Muscle" then CHROME else DARK, METAL)
		-- Retrovisor (brazo, carcasa y espejo mirando atrás)
		local my = surface(sides, zW + 0.6) + 0.05
		box("MirrorArm", Vector3.new(0.55, 0.1, 0.18), at(sx * (hc + 0.3), my + 0.12, zW + 0.6), second)
		painted(box("Mirror", Vector3.new(0.5, 0.36, 0.62), at(sx * (HW + 0.12), my + 0.3, zW + 0.55), if isSuper then second else paint))
		box("MirrorGlass", Vector3.new(0.42, 0.28, 0.04), at(sx * (HW + 0.12), my + 0.3, zW + 0.87), rgb(170, 190, 205), GLASSM)
	end)
	if spec.Bubble then
		-- Techo de doble burbuja
		mirror(function(sx)
			painted(box("Roof", Vector3.new(hc - 0.45, 0.1, z1 - z0 - 0.2), at(sx * (hc / 2 - 0.05), roofY + 0.1, (z0 + z1) / 2), paint))
		end)
	end
	if spec.Airbox then
		-- Toma de aire de monoplaza sobre el techo y aleta de tiburón en la tapa del motor
		painted(wedge("Panel", Vector3.new(0.95, 0.55, 1.3), at(0, roofY + 0.33, z1 - 0.15) * CFrame.Angles(0, math.pi, 0), paint))
		box("AirboxMouth", Vector3.new(0.7, 0.32, 0.05), at(0, roofY + 0.32, z1 - 0.82), DARK)
		painted(box("Fin", Vector3.new(0.06, 0.42, rl * 0.75), rearCf * CFrame.new(0, 0.26, 0.1), paint))
	end

	-- 3. Frontal: parrilla, tomas, faldón, splitter, aletines
	local noseTop = g.Hood[1][2]
	local faceH = noseTop - FLOOR_TOP
	box("Fascia", Vector3.new(IW * 2, 0.36, 0.6), at(0, 0.76, Z_NOSE + 0.3), CARBON, SMOOTH, true)
	if spec.Head == "Grille" then
		-- Muscle: parrilla ancha de lado a lado con los faros dentro
		box("Grille", Vector3.new(IW * 2 - 0.1, faceH * 0.7, 0.06), at(0, FLOOR_TOP + faceH * 0.55, Z_NOSE - 0.02), DARK)
		for i = 0, 2 do
			box("GrilleBar", Vector3.new(IW * 2 - 0.3, 0.05, 0.05), at(0, FLOOR_TOP + faceH * (0.3 + i * 0.18), Z_NOSE - 0.06), CARBON)
		end
	else
		box("Grille", Vector3.new(3.1, faceH * 0.6, 0.06), at(0, FLOOR_TOP + faceH * 0.38, Z_NOSE - 0.02), DARK)
		for i = 0, 1 do
			box("GrilleBar", Vector3.new(2.9, 0.05, 0.05), at(0, FLOOR_TOP + faceH * (0.24 + i * 0.26), Z_NOSE - 0.06), if isSuper then accent else CARBON, METAL)
		end
	end
	mirror(function(sx)
		box("Intake", Vector3.new(0.95, 0.5, 0.06), at(sx * 2.55, 1.12, Z_NOSE + 0.02), DARK)
	end)
	box("Splitter", Vector3.new(6.0, 0.09, 1.0), at(0, 0.58, Z_NOSE + 0.35), CARBON)
	if spec.Canards then
		mirror(function(sx)
			for i = 0, 1 do
				box("Canard", Vector3.new(0.5, 0.05, 0.42), at(sx * 3.08, 0.95 + i * 0.32, Z_NOSE + 0.42) * CFrame.Angles(0, 0, sx * math.rad(-12)), CARBON)
			end
		end)
	end

	-- 4. Faros: proyector (con el foco de verdad) en la cara de delante, grupo LED en la aleta y firma diurna
	local s0, s1 = sides[1], sides[2]
	local function vz(v: number): number -- (0 = punta del morro, 1 = arranque del paso de rueda)
		return s0[1] + (s1[1] - s0[1]) * v
	end
	if spec.Head == "Grille" then
		mirror(function(sx)
			box(if sx < 0 then "Headlight" else "HeadlightRight", Vector3.new(0.75, 0.22, 0.1), at(sx * 1.5, FLOOR_TOP + faceH * 0.72, Z_NOSE - 0.05), LENS, SMOOTH)
			box("HeadlightSmall", Vector3.new(0.9, 0.16, 0.1), at(sx * 2.55, sides[1][2] - 0.25, Z_NOSE + 0.02), LENS, SMOOTH)
		end)
	else
		mirror(function(sx)
			box(if sx < 0 then "Headlight" else "HeadlightRight", Vector3.new(0.8, 0.2, 0.1), at(sx * 2.5, s0[2] - 0.2, Z_NOSE + 0.02), LENS, SMOOTH)
			if spec.Head == "Round" then
				for _, x in { 2.15, 2.85 } do
					cyl("HeadlightSmall", 0.08, 0.46, onTop(sides, sx * x, vz(0.55), 0.03) * UPRIGHT, LENS, SMOOTH)
				end
			elseif spec.Head == "Slim" then
				stripOn(sides, "HeadlightSmall", sx * 2.0, vz(0.78), sx * 3.0, vz(0.62), 0.16, 0.06, LENS, SMOOTH)
			else -- Sharp: grupo afilado (estrecho hacia dentro)
				stripOn(sides, "HeadlightSmall", sx * 2.05, vz(0.62), sx * 3.0, vz(0.45), 0.3, 0.07, LENS, SMOOTH)
			end
		end)
	end
	local drl = spec.Drl
	mirror(function(sx)
		local function d(x0: number, v0: number, x1: number, v1: number)
			stripOn(sides, "DRL", sx * x0, vz(v0), sx * x1, vz(v1), 0.07, 0.07, glow, NEON)
		end
		if drl == "Boomerang" then
			d(2.0, 0.3, 2.95, 0.22)
			d(2.0, 0.3, 2.15, 0.85)
		elseif drl == "Fang" then
			d(2.1, 0.9, 2.05, 0.15)
			neon("DRL", Vector3.new(0.08, 0.5, 0.06), at(sx * 2.05, s0[2] - 0.5, Z_NOSE + 0.02))
		elseif drl == "Arrow" then
			d(2.0, 0.25, 2.55, 0.6)
			d(2.55, 0.6, 3.05, 0.25)
		elseif drl == "X" then
			d(2.05, 0.15, 2.95, 0.85)
			d(2.05, 0.85, 2.95, 0.15)
		elseif drl == "Y" then
			d(2.5, 0.08, 2.5, 0.45)
			d(2.5, 0.45, 2.1, 0.85)
			d(2.5, 0.45, 2.9, 0.85)
		elseif drl == "Halo" then
			for _, x in { 2.15, 2.85 } do
				cyl("DRL", 0.06, 0.6, onTop(sides, sx * x, vz(0.55), 0.01) * UPRIGHT, glow, NEON)
			end
		elseif drl == "Bar" then
			neon("DRL", Vector3.new(1.0, 0.07, 0.06), at(sx * 2.6, s0[2] - 0.06, Z_NOSE + 0.02))
		end
		-- Intermitente en la esquina
		stripOn(sides, "IndicatorFront", sx * 2.95, vz(0.05), sx * 3.05, vz(0.3), 0.2, 0.06, AMBER, NEON)
	end)
	if drl == "Bar" then
		neon("DRL", Vector3.new(IW * 2, 0.07, 0.06), at(0, noseTop - 0.1, Z_NOSE - 0.03))
	end

	-- 5. Capó: rejillas, toma de aire y franjas
	local longest = 1
	for i = 1, #g.Hood - 1 do
		if g.Hood[i + 1][1] - g.Hood[i][1] > g.Hood[longest + 1][1] - g.Hood[longest][1] then
			longest = i
		end
	end
	local va, vb = g.Hood[longest][1], g.Hood[longest + 1][1]
	if spec.HoodVents == 2 then
		mirror(function(sx)
			stripOn(hood, "HoodVent", sx * 0.95, va + (vb - va) * 0.3, sx * 0.95, va + (vb - va) * 0.75, 0.75, 0.05, DARK)
		end)
	elseif spec.HoodVents == 1 then
		stripOn(hood, "HoodVent", 0, va + (vb - va) * 0.35, 0, va + (vb - va) * 0.8, 1.2, 0.05, DARK)
	end
	if spec.Scoop then
		local sz = va + (vb - va) * 0.55
		local base = onTop(hood, 0, sz, 0.2)
		box("HoodScoop", Vector3.new(1.4, 0.4, 1.7), base, second)
		box("ScoopMouth", Vector3.new(1.1, 0.24, 0.05), base * CFrame.new(0, 0.02, -0.86), DARK)
	end
	if spec.Stripes then
		local xs, sw = if spec.Stripes == "Twin" then { -0.45, 0.45 } else { 0 }, if spec.Stripes == "Twin" then 0.5 else 1.5
		for _, x in xs do
			for i = 1, #g.Hood - 1 do
				stripSegment("Livery", x, sw, g.Hood[i], g.Hood[i + 1], second)
			end
			if not spec.BlackRoof then
				box("Livery", Vector3.new(sw, 0.03, z1 - z0 + 0.1), at(x, roofY + 0.075, (z0 + z1) / 2), second)
			end
			for i = 1, #g.Deck - 1 do
				if g.Deck[i][1] >= zB - 0.01 then -- (no sobre la luneta ni la tapa del motor)
					stripSegment("Livery", x, sw, g.Deck[i], g.Deck[i + 1], second)
				end
			end
		end
	end

	-- 6. Laterales: taloneras, juntas, manillas, branquias y tomas
	local doorMid = (f1 + r0) / 2
	mirror(function(sx)
		box("SideSkirt", Vector3.new(0.18, 0.24, r0 - f1 + 0.2), at(sx * (HW - 0.01), 0.66, doorMid), CARBON)
		if spec.GlowLines then
			neon("GlowLine", Vector3.new(0.05, 0.05, r0 - f1), at(sx * (HW + 0.09), 0.8, doorMid))
			local dy, dAngle = surface(sides, doorMid)
			neon("GlowLine", Vector3.new(0.05, 0.05, r0 - f1 - 0.4), at(sx * (HW + 0.01), dy - 0.22, doorMid) * CFrame.Angles(-dAngle, 0, 0))
		else
			box("SkirtBlade", Vector3.new(0.05, 0.05, r0 - f1), at(sx * (HW + 0.09), 0.8, doorMid), second)
		end
		box("DoorLine", Vector3.new(0.03, belt - 1.0, 0.05), at(sx * (HW + 0.005), (belt + 1.0) / 2, f1 + 0.3), DARK)
		box("Handle", Vector3.new(0.04, 0.1, 0.5), at(sx * (HW + 0.02), surface(sides, r0 - 0.9) - 0.35, r0 - 0.9), if spec.Shape == "Muscle" then CHROME else second, METAL)
		if spec.SideVents then
			for i = 0, 1 do
				box("SideVent", Vector3.new(0.04, 0.08, 0.6), at(sx * (HW + 0.01), 1.95 + i * 0.25, f1 + 0.55) * CFrame.Angles(math.rad(-20), 0, 0), DARK)
			end
		end
		if spec.SideIntakes then
			wedge("SideIntake", Vector3.new(0.06, 1.0, 1.5), at(sx * (HW + 0.02), 1.95, r0 - 0.85), DARK)
			box("IntakeFin", Vector3.new(0.05, 0.06, 1.3), at(sx * (HW + 0.05), 1.9, r0 - 0.8), if spec.GlowLines then glow else accent, if spec.GlowLines then NEON else METAL)
		end
	end)
	if spec.GlowLines then
		neon("GlowLine", Vector3.new(5.6, 0.05, 0.05), at(0, 0.64, Z_NOSE - 0.13))
		neon("GlowLine", Vector3.new(3.8, 0.05, 0.05), at(0, 0.98, Z_TAIL + 0.02))
	end
	if spec.Underglow then
		neon("Underglow", Vector3.new(4.6, 0.04, 9.8), at(0, 0.52, 0)).Transparency = 0.3
	end

	-- 7. Zaga: pilotos, freno central, marcha atrás, intermitentes, catadióptricos, difusor, escapes
	local tailTop = math.min(g.Deck[#g.Deck][2], g.Side.Tail)
	local ty = tailTop - 0.42
	local face = Z_TAIL + 0.035
	local tail = spec.Tail
	local function lamp(name: string, size: Vector3, lcf: CFrame, color: Color3, mat: Enum.Material?)
		return box(name, size, lcf, color, mat or SMOOTH)
	end
	mirror(function(sx)
		if tail == "QuadRound" then
			for _, x in { 1.75, 2.55 } do
				cyl("Taillight", 0.08, 0.62, at(sx * x, ty, face) * ALONG_Z, TAIL)
			end
			lamp("Reverse", Vector3.new(0.42, 0.16, 0.07), at(sx * 1.0, ty - 0.08, face), REVERSE)
			lamp("IndicatorRear", Vector3.new(0.4, 0.12, 0.07), at(sx * 2.15, ty - 0.48, face), AMBER, NEON)
		elseif tail == "FullWidth" then
			lamp("Taillight", Vector3.new(0.95, 0.3, 0.07), at(sx * 2.6, ty, face), TAIL)
			lamp("Reverse", Vector3.new(0.5, 0.14, 0.07), at(sx * 1.5, ty - 0.24, face), REVERSE)
			lamp("IndicatorRear", Vector3.new(0.4, 0.12, 0.07), at(sx * 2.6, ty - 0.26, face), AMBER, NEON)
		elseif tail == "Split" then
			for _, x in { 2.0, 2.75 } do
				lamp("Taillight", Vector3.new(0.62, 0.3, 0.07), at(sx * x, ty, face), TAIL)
			end
			lamp("Reverse", Vector3.new(0.42, 0.16, 0.07), at(sx * 1.25, ty, face), REVERSE)
			lamp("IndicatorRear", Vector3.new(0.5, 0.12, 0.07), at(sx * 2.4, ty - 0.3, face), AMBER, NEON)
		elseif tail == "Y" then
			lamp("Taillight", Vector3.new(0.13, 0.45, 0.07), at(sx * 2.4, ty - 0.18, face), TAIL)
			for _, k in { -1, 1 } do
				lamp("Taillight", Vector3.new(0.13, 0.55, 0.07), at(sx * (2.4 + k * 0.2), ty + 0.2, face) * CFrame.Angles(0, 0, k * sx * math.rad(-40)), TAIL)
			end
			lamp("Reverse", Vector3.new(0.42, 0.14, 0.07), at(sx * 1.45, ty - 0.1, face), REVERSE)
			lamp("IndicatorRear", Vector3.new(0.4, 0.12, 0.07), at(sx * 2.95, ty - 0.4, face), AMBER, NEON)
		elseif tail == "X" then
			for _, k in { -1, 1 } do
				lamp("Taillight", Vector3.new(0.13, 0.85, 0.07), at(sx * 2.4, ty, face) * CFrame.Angles(0, 0, k * math.rad(50)), TAIL)
			end
			lamp("Reverse", Vector3.new(0.42, 0.14, 0.07), at(sx * 1.45, ty - 0.1, face), REVERSE)
			lamp("IndicatorRear", Vector3.new(0.4, 0.12, 0.07), at(sx * 2.95, ty - 0.4, face), AMBER, NEON)
		end
		lamp("Reflector", Vector3.new(0.45, 0.1, 0.05), at(sx * 2.6, 1.08, Z_TAIL + 0.03), rgb(150, 20, 26))
	end)
	if tail == "FullWidth" then
		lamp("Taillight", Vector3.new(IW * 2 + 0.2, 0.12, 0.07), at(0, ty + 0.09, face), TAIL)
	end
	if spec.RainLight then
		lamp("ThirdBrake", Vector3.new(0.5, 0.3, 0.07), at(0, 1.45, Z_TAIL + 0.05), TAIL)
	else
		lamp("ThirdBrake", Vector3.new(1.2, 0.07, 0.07), at(0, tailTop - 0.05, Z_TAIL + 0.03), TAIL)
	end
	-- Difusor con aletas
	wedge("Diffuser", Vector3.new(IW * 2, 0.37, 1.4), at(0, 0.765, Z_TAIL - 0.7) * CFrame.Angles(math.pi, 0, 0), CARBON)
	for _, x in { -1.45, -0.65, 0.65, 1.45 } do
		box("DiffuserFin", Vector3.new(0.06, 0.3, 1.1), at(x, 0.78, Z_TAIL - 0.55), CARBON)
	end
	-- Escapes
	local ex = spec.Exhaust
	local ey = if isSuper then 1.25 else 1.12
	local function pipe(x: number, y: number, d: number)
		cyl("Exhaust", 0.4, d, at(x, y, Z_TAIL + 0.12) * ALONG_Z, CHROME, METAL)
	end
	if ex == "Quad" then
		mirror(function(sx)
			pipe(sx * 1.45, ey, 0.42)
			pipe(sx * 2.02, ey, 0.42)
			box("ExhaustSurround", Vector3.new(1.25, 0.6, 0.06), at(sx * 1.73, ey, Z_TAIL + 0.02), DARK)
		end)
	elseif ex == "Twin" then
		mirror(function(sx)
			pipe(sx * 1.85, ey, 0.5)
			box("ExhaustSurround", Vector3.new(0.75, 0.66, 0.06), at(sx * 1.85, ey, Z_TAIL + 0.02), DARK)
		end)
	elseif ex == "CenterTwin" then
		mirror(function(sx)
			pipe(sx * 0.42, ey, 0.5)
		end)
		box("ExhaustSurround", Vector3.new(1.6, 0.66, 0.06), at(0, ey, Z_TAIL + 0.02), DARK)
	elseif ex == "Center" then
		pipe(0, ey - 0.1, 0.62)
		box("ExhaustSurround", Vector3.new(0.9, 0.8, 0.06), at(0, ey - 0.1, Z_TAIL + 0.02), DARK)
	elseif ex == "Hex" then
		mirror(function(sx)
			pipe(sx * 0.42, tailTop - 0.95, 0.46)
		end)
		box("ExhaustSurround", Vector3.new(1.55, 0.62, 0.06), at(0, tailTop - 0.95, Z_TAIL + 0.02), DARK)
	end
	-- Nombre del modelo en la zaga (letras cromadas, sin logos)
	local lettering = box("Lettering", Vector3.new(2.4, 0.2, 0.02), at(0, ty - 0.52, Z_TAIL + 0.02), CHROME, SMOOTH, false, 1)
	Builder.sign(lettering, string.upper(spec.Name), Enum.NormalId.Back, CHROME)

	-- 8. Alerón
	local wing = spec.Wing
	local zw = Z_TAIL - 0.75
	local yd = surface(g.Deck, zw)
	if wing == "GT" or wing == "Swan" then
		local wingY = yd + 1.05
		mirror(function(sx)
			if wing == "GT" then
				box("WingStrut", Vector3.new(0.12, wingY - yd, 0.45), at(sx * 1.5, (yd + wingY) / 2, zw), CARBON)
			else
				-- cuello de cisne: los soportes llegan por encima y sujetan el ala desde arriba
				box("WingStrut", Vector3.new(0.12, wingY - yd + 0.3, 0.4), at(sx * 1.3, (yd + wingY + 0.3) / 2, zw - 0.15), CARBON)
				box("WingStrut", Vector3.new(0.14, 0.08, 0.75), at(sx * 1.3, wingY + 0.28, zw + 0.05), CARBON)
			end
			box("WingEndplate", Vector3.new(0.08, 0.6, 1.35), at(sx * 2.98, wingY + 0.05, zw + 0.05), second)
		end)
		box("Wing", Vector3.new(5.9, 0.12, 1.15), at(0, wingY + 0.03, zw + 0.05) * CFrame.Angles(math.rad(-7), 0, 0), second)
		box("WingGurney", Vector3.new(5.8, 0.1, 0.04), at(0, wingY + 0.14, zw + 0.6), accent)
	elseif wing == "Duck" then
		local yt = surface(g.Deck, Z_TAIL - 0.48)
		painted(wedge("Panel", Vector3.new(IW * 2 + 2.0, 0.32, 0.95), at(0, yt + 0.16, Z_TAIL - 0.48), paint))
	elseif wing == "Lip" then
		local yt = surface(g.Deck, Z_TAIL - 0.25)
		box("Spoiler", Vector3.new(5.4, 0.07, 0.45), at(0, yt + 0.05, Z_TAIL - 0.25) * CFrame.Angles(math.rad(-10), 0, 0), second)
	elseif wing == "Active" then
		local wingY = yd + 0.42
		mirror(function(sx)
			box("WingStrut", Vector3.new(0.1, wingY - yd, 0.3), at(sx * 1.6, (yd + wingY) / 2, zw), CARBON)
		end)
		box("Wing", Vector3.new(5.4, 0.09, 0.85), at(0, wingY + 0.02, zw + 0.05) * CFrame.Angles(math.rad(-4), 0, 0), second)
	end

	-- 9. Interior: suelo, salpicadero con pantallas, volante, consola y asientos baquet
	local seats = spec.SeatLayout
	local dx, sy, sz = seats.Driver[1], seats.Driver[2], seats.Driver[3]
	box("Carpet", Vector3.new(IW * 2 - 0.1, 0.04, g.CabBack - zW), at(0, FLOOR_TOP + 0.02, (zW + g.CabBack) / 2), rgb(22, 22, 25))
	box("Dash", Vector3.new(IW * 2 - 0.1, 0.6, 1.0), at(0, belt - 0.32, zW + 0.5), INTERIOR)
	neon("DashGlow", Vector3.new(IW * 2 - 0.4, 0.04, 0.04), at(0, belt - 0.58, zW + 1.02))
	neon("Screen", Vector3.new(0.6, 0.38, 0.04), at(0, belt - 0.3, zW + 1.02), rgb(70, 160, 255))
	asym(neon("Gauges", Vector3.new(0.8, 0.28, 0.04), at(dx, belt - 0.12, zW + 1.0), glow))
	local wheelCf = at(dx, sy + 1.35, sz - 1.15) * CFrame.Angles(math.rad(-20), 0, 0) * ALONG_Z
	asym(cyl("Steering", 0.1, 0.95, wheelCf, DARK))
	asym(cyl("SteeringHub", 0.14, 0.3, wheelCf, accent, METAL))
	box("Console", Vector3.new(0.55, 0.5, 1.6), at(0, sy, sz - 0.6), INTERIOR)
	box("Shifter", Vector3.new(0.1, 0.3, 0.1), at(0, sy + 0.4, sz - 0.6), CHROME, METAL)
	local tilt = CFrame.Angles(math.rad(12), 0, 0)
	mirror(function(sx)
		local x = sx * math.abs(dx)
		box("SeatCushion", Vector3.new(1.2, 0.3, 1.25), at(x, sy - 0.15, sz + 0.05), SEAT, FABRIC)
		box("SeatBack", Vector3.new(1.2, 1.75, 0.3), at(x, sy + 0.85, sz + 0.75) * tilt, SEAT, FABRIC)
		box("SeatHead", Vector3.new(0.75, 0.45, 0.26), at(x, sy + 1.95, sz + 0.98) * tilt, SEAT, FABRIC)
		box("SeatStripe", Vector3.new(0.22, 1.5, 0.02), at(x, sy + 0.85, sz + 0.58) * tilt, accent)
	end)
	if #seats.Passengers >= 3 then
		local rz = seats.Passengers[2][3]
		mirror(function(sx)
			box("RearSeat", Vector3.new(1.1, 0.3, 1.0), at(sx * 1.0, sy - 0.15, rz + 0.05), SEAT, FABRIC)
			box("RearSeatBack", Vector3.new(1.1, 1.3, 0.28), at(sx * 1.0, sy + 0.6, rz + 0.62) * tilt, SEAT, FABRIC)
		end)
	end

	-- 10. Matrículas
	local a = spec.Anchors
	local front = box("PlateFront", Vector3.new(1.6, 0.4, 0.06), at(a.PlateFront[1], a.PlateFront[2], a.PlateFront[3]), PLATE)
	local rear = box("PlateRear", Vector3.new(1.7, 0.42, 0.06), at(a.PlateRear[1], a.PlateRear[2], a.PlateRear[3]), PLATE)
	Builder.sign(front, spec.Plate, Enum.NormalId.Front, rgb(20, 20, 24), PLATE)
	Builder.sign(rear, spec.Plate, Enum.NormalId.Back, rgb(20, 20, 24), PLATE)

	-- 11. Ruedas
	for _, z in { w.Front, w.Rear } do
		mirror(function(sx)
			carWheel(sx, z)
		end)
	end
end

---------------------------------------------------------------------
-- Motos
---------------------------------------------------------------------
local function motoWheel(z: number, front: boolean)
	local spec = ctx.spec
	local w = spec.Geometry.Wheels
	local R, width, rimD = w.Radius, w.Width, w.Rim
	local hub = at(0, R, z)
	local rimColor = c3(spec.Rims.Color, CHROME)
	local caliper = c3(spec.Caliper, ctx.accent)
	cyl("Wheel", width, R * 2, hub, TIRE, RUBBER)
	cyl("Rim", width + 0.02, rimD, hub, rimColor, METAL)
	cyl("RimInner", width + 0.04, rimD - 0.2, hub, DARK)
	for k = 0, 2 do
		box("Spoke", Vector3.new(width + 0.08, 0.12, rimD - 0.24), hub * CFrame.Angles(k * math.pi / 3, 0, 0), rimColor, METAL)
	end
	cyl("Hub", width + 0.12, 0.34, hub, DARK, METAL)
	local alpha = if front then math.rad(40) else math.rad(-40)
	local rc = rimD / 2 - 0.3
	local sides = if front then { -1, 1 } else { 1 }
	for _, sx in sides do
		local disc = cyl("BrakeDisc", 0.03, rimD - 0.3, hub * CFrame.new(sx * (width / 2 + 0.07), 0, 0), DISC, METAL)
		local cal = box("Caliper", Vector3.new(0.12, 0.2, 0.42), hub * CFrame.new(sx * (width / 2 + 0.12), rc * math.cos(alpha), rc * math.sin(alpha)) * CFrame.Angles(alpha, 0, 0), caliper, METAL)
		if not front then
			asym(disc)
			asym(cal)
		end
	end
	if not front then
		asym(cyl("Cog", 0.04, 0.95, hub * CFrame.new(-(width / 2 + 0.06), 0, 0), rgb(60, 62, 68), METAL))
	end
end

local function buildMoto()
	local spec = ctx.spec
	local g = spec.Geometry
	local paint, second, accent, glow = ctx.paint, ctx.second, ctx.accent, ctx.glow
	local naked = spec.Style == "Naked"
	local wf, wr = g.Wheels.Front, g.Wheels.Rear
	local V = Vector3.new
	local ALLOY = rgb(120, 124, 132)
	local forkColor = if naked then rgb(210, 160, 50) else rgb(40, 40, 44)

	-- 1. Ruedas, horquilla invertida, tijas y guardabarros
	motoWheel(wf, true)
	motoWheel(wr, false)
	local head = V(0, 3.4, -1.55)
	mirror(function(sx)
		tube("Fork", V(sx * 0.31, 1.0, wf), V(sx * 0.31, 2.2, wf + 0.42), 0.24, forkColor)
		tube("Fork", V(sx * 0.31, 2.2, wf + 0.42), head + V(sx * 0.31, 0, 0), 0.17, CHROME)
	end)
	box("Fork", V(0.9, 0.1, 0.38), CFrame.new(head + V(0, 0.02, 0)), ALLOY, METAL)
	painted(box("FenderFront", V(0.58, 0.1, 1.3), at(0, 2.12, wf + 0.02) * CFrame.Angles(math.rad(8), 0, 0), paint))

	-- 2. Chasis, basculante, amortiguador
	local pivot = 0.45
	if naked then
		-- Multitubular a la vista
		mirror(function(sx)
			tube("Frame", V(sx * 0.15, 3.25, -1.45), V(sx * 0.45, 2.1, pivot), 0.13, accent)
			tube("Frame", V(sx * 0.15, 2.95, -1.5), V(sx * 0.45, 1.65, -0.35), 0.13, accent)
			tube("Frame", V(sx * 0.45, 1.65, -0.35), V(sx * 0.45, 2.1, pivot), 0.13, accent)
			tube("Frame", V(sx * 0.45, 2.55, -0.55), V(sx * 0.45, 1.65, -0.35), 0.11, accent)
		end)
	else
		mirror(function(sx)
			tube("Frame", V(sx * 0.32, 3.15, -1.48), V(sx * 0.4, 2.05, pivot), 0.3, ALLOY)
		end)
	end
	mirror(function(sx)
		tube("Frame", V(sx * 0.3, 2.3, pivot - 0.05), V(sx * 0.24, 2.6, 2.2), 0.1, DARK)
		tube("Swingarm", V(sx * 0.37, 1.85, pivot), V(sx * 0.37, 1.0, wr), 0.22, ALLOY)
	end)
	tube("Shock", V(0, 1.55, 0.95), V(0, 2.35, 0.35), 0.16, DARK)
	tube("Spring", V(0, 1.7, 0.83), V(0, 2.2, 0.47), 0.24, accent)

	-- 3. Motor, radiador y escape (bajo el motor)
	box("Engine", V(0.95, 0.95, 1.2), at(0, 1.62, -0.35), rgb(55, 57, 62), METAL)
	box("CylinderHead", V(0.85, 0.5, 0.75), at(0, 2.35, -0.85) * CFrame.Angles(math.rad(-25), 0, 0), rgb(70, 72, 78), METAL)
	cyl("EngineCover", 1.08, 0.75, at(0, 1.45, -0.05), if naked then accent else DARK, METAL)
	box("Radiator", V(1.0, 0.85, 0.1), at(0, 2.2, -1.3) * CFrame.Angles(math.rad(-15), 0, 0), DARK)
	mirror(function(sx)
		tube("Header", V(sx * 0.22, 2.0, -1.05), V(sx * 0.22, 0.75, -0.65), 0.14, rgb(150, 120, 90))
	end)
	box("Exhaust", V(0.6, 0.38, 1.15), at(0, 0.62, 0.1), rgb(40, 40, 44), METAL)
	cyl("ExhaustTip", 0.2, 0.32, at(0, 0.62, 0.75) * ALONG_Z, CHROME, METAL)

	-- 4. Depósito, asientos y colín
	local tank = g.Tank
	painted(box("Body", V(1.15, 0.6, 1.25), at(tank[1], tank[2], tank[3]), paint, SMOOTH, true))
	painted(wedge("Shield", V(1.05, 0.48, 0.55), at(0, 2.89, -1.45), paint, SMOOTH))
	painted(wedge("Shield", V(1.0, 0.42, 0.45), at(0, 2.86, 0.27) * CFrame.Angles(0, math.pi, 0), paint, SMOOTH))
	box("Livery", V(0.36, 0.04, 1.05), at(0, 3.27, -0.55), second)
	box("Seat", V(0.95, 0.22, 1.15), at(0, g.Seat[2] - 0.11, g.Seat[3]), SEAT, FABRIC, true)
	painted(box("Tail", V(0.86, 0.42, 1.5), at(0, 2.46, 1.55), paint, SMOOTH, true))
	box("SeatPillion", V(0.72, 0.12, 0.7), at(0, g.Pillion[2] - 0.06, g.Pillion[3]), if naked then SEAT else second, FABRIC)
	painted(wedge("Tail", V(0.8, 0.33, 0.85), at(0, 2.835, 2.42), paint, SMOOTH))
	box("Hugger", V(0.55, 0.08, 1.1), at(0, 2.15, 2.0) * CFrame.Angles(math.rad(-12), 0, 0), DARK)
	mirror(function(sx)
		box("SidePanelLine", V(0.03, 0.08, 1.4), at(sx * 0.445, 2.42, 1.55), second)
	end)

	-- 5. Luces de atrás, matrícula, intermitentes
	mirror(function(sx)
		box("Taillight", V(0.36, 0.08, 0.08), at(sx * 0.2, 2.86, 2.86) * CFrame.Angles(0, 0, sx * math.rad(15)), TAIL)
		box("Indicator", V(0.2, 0.12, 0.22), at(sx * 0.36, 1.98, 2.82), AMBER, NEON)
	end)
	box("PlateHanger", V(0.12, 0.62, 0.08), at(0, 2.08, 2.74) * CFrame.Angles(math.rad(25), 0, 0), DARK)
	local plate = box("Plate", V(0.8, 0.45, 0.05), at(g.Plate[1], g.Plate[2], g.Plate[3]) * CFrame.Angles(math.rad(10), 0, 0), PLATE)
	Builder.sign(plate, spec.Plate, Enum.NormalId.Back, rgb(20, 20, 24), PLATE)

	-- 6. Frontal: carenado con cúpula (deportivas) o faro desnudo (naked)
	if naked then
		box("HeadlightHousing", V(0.78, 0.6, 0.35), at(0, 3.05, -2.0), DARK)
		mirror(function(sx)
			box(if sx < 0 then "Headlight" else "HeadlightRight", V(0.26, 0.2, 0.06), at(sx * 0.16, 3.02, -2.2), LENS)
			neon("DRL", V(0.06, 0.32, 0.05), at(sx * 0.36, 3.02, -2.19) * CFrame.Angles(0, 0, sx * math.rad(12)))
			painted(wedge("Shield", V(0.1, 0.7, 0.85), at(sx * 0.6, 2.62, -1.15), paint))
		end)
		neon("DRL", V(0.66, 0.05, 0.05), at(0, 3.31, -2.19))
		box("Windscreen", V(0.6, 0.05, 0.4), at(0, 3.45, -1.95) * CFrame.Angles(math.rad(-60), 0, 0), rgb(40, 50, 62), GLASSM, false, 0.3)
		box("Handlebar", V(1.9, 0.1, 0.1), at(0, 3.62, -1.38), DARK, METAL)
		mirror(function(sx)
			tube("Riser", V(sx * 0.2, 3.42, -1.5), V(sx * 0.2, 3.62, -1.38), 0.1, DARK)
			cyl("Grip", 0.4, 0.2, at(sx * 0.82, 3.62, -1.38), DARK, RUBBER)
			box("Lever", V(0.55, 0.05, 0.08), at(sx * 0.65, 3.58, -1.6), CHROME, METAL)
			tube("MirrorStalk", V(sx * 0.95, 3.62, -1.38), V(sx * 1.08, 3.9, -1.3), 0.06, DARK)
			box("Mirror", V(0.4, 0.22, 0.08), at(sx * 1.1, 3.95, -1.3), DARK)
			box("Indicator", V(0.18, 0.12, 0.2), at(sx * 0.5, 2.85, -2.12), AMBER, NEON)
		end)
	else
		painted(wedge("Shield", V(1.05, 0.65, 0.95), at(0, 2.95, -1.98), paint))
		painted(box("Shield", V(1.05, 0.45, 0.7), at(0, 2.4, -1.85), paint))
		mirror(function(sx)
			box(if sx < 0 then "Headlight" else "HeadlightRight", V(0.3, 0.15, 0.06), at(sx * 0.27, 2.5, -2.22), LENS)
			neon("DRL", V(0.36, 0.05, 0.05), at(sx * 0.27, 2.64, -2.22) * CFrame.Angles(0, 0, sx * math.rad(-14)))
			-- Laterales del carenado con rejillas y franja
			painted(box("Shield", V(0.1, 1.0, 1.6), at(sx * 0.56, 2.05, -1.0) * CFrame.Angles(math.rad(-8), 0, 0), paint))
			painted(box("Shield", V(0.1, 0.6, 1.3), at(sx * 0.5, 1.25, -0.45), paint))
			for i = 0, 1 do
				box("FairingVent", V(0.04, 0.1, 0.6), at(sx * 0.62, 1.85 + i * 0.22, -0.9) * CFrame.Angles(math.rad(-18), 0, 0), DARK)
			end
			box("Livery", V(0.03, 0.09, 1.5), at(sx * 0.615, 2.3, -1.0) * CFrame.Angles(math.rad(-8), 0, 0), second)
			-- Retrovisores en el carenado con el intermitente dentro
			tube("MirrorStalk", V(sx * 0.45, 3.0, -1.75), V(sx * 0.68, 3.22, -1.7), 0.06, DARK)
			box("Mirror", V(0.38, 0.2, 0.3), at(sx * 0.78, 3.25, -1.7), paint)
			box("Indicator", V(0.3, 0.05, 0.05), at(sx * 0.78, 3.25, -1.86), AMBER, NEON)
			box("Handlebar", V(0.45, 0.1, 0.1), at(sx * 0.55, 3.25, -1.42), DARK, METAL)
			cyl("Grip", 0.35, 0.2, at(sx * 0.82, 3.25, -1.42), DARK, RUBBER)
			box("Lever", V(0.5, 0.05, 0.08), at(sx * 0.62, 3.21, -1.62), CHROME, METAL)
			if spec.Winglets then
				wedge("Winglet", V(0.36, 0.06, 0.45), at(sx * 0.78, 2.5, -1.55) * CFrame.Angles(0, 0, sx * math.rad(8)), second)
				box("WingletPlate", V(0.04, 0.22, 0.45), at(sx * 0.97, 2.5, -1.55), second)
			end
			if spec.GlowLines then
				neon("GlowLine", V(0.04, 0.05, 1.3), at(sx * 0.62, 2.55, -1.05) * CFrame.Angles(math.rad(-8), 0, 0))
				neon("GlowLine", V(0.04, 0.05, 1.2), at(sx * 0.445, 2.62, 1.55))
			end
		end)
		painted(wedge("Shield", V(0.95, 0.35, 1.2), at(0, 0.98, -0.5) * CFrame.Angles(math.pi, 0, 0), paint))
		box("Windscreen", V(0.85, 0.06, 0.85), at(0, 3.42, -1.72) * CFrame.Angles(math.rad(-55), 0, 0), rgb(40, 50, 62), GLASSM, false, 0.35)
	end
	box("DashHousing", V(0.58, 0.36, 0.12), at(0, 3.45, -1.42) * CFrame.Angles(math.rad(-30), 0, 0), DARK)
	neon("Dash", V(0.48, 0.28, 0.04), at(0, 3.46, -1.35) * CFrame.Angles(math.rad(-30), 0, 0), rgb(70, 160, 255))

	-- 7. Estriberas, cadena y pata de cabra
	mirror(function(sx)
		cyl("Footpeg", 0.3, 0.08, at(sx * 0.55, 1.45, 0.6), CHROME, METAL)
		box("Rearset", V(0.05, 0.35, 0.3), at(sx * 0.45, 1.55, 0.6), ALLOY, METAL)
		cyl("Footpeg", 0.26, 0.07, at(sx * 0.5, 1.75, 1.4), DARK, METAL)
	end)
	asym(tube("Chain", V(-0.4, 1.5, 0.2), V(-0.4, 1.42, wr), 0.06, rgb(70, 70, 74)))
	asym(tube("Chain", V(-0.4, 1.1, 0.25), V(-0.4, 0.6, wr), 0.06, rgb(70, 70, 74)))
	local a, b = V(-0.5, 1.25, 0.15), V(-0.95, 0.05, 0.4)
	local stand = asym(tube("Kickstand", a, b, 0.1, DARK))
	stand:SetAttribute("StandA", a)
	stand:SetAttribute("StandB", b)
	stand:SetAttribute("StandFolded", a + V((b.X - a.X) * 0.25, 0.08, (b - a).Magnitude))
end

---------------------------------------------------------------------
-- API
---------------------------------------------------------------------

-- ¿Hay un premium «id» para este tipo de vehículo?
function SportsCars.has(kind: string, id: any): boolean
	return PremiumVehicles.isPremium(kind, id)
end

-- Construye el premium «id» dentro de m (el modelo de Rides.build). paint = color de la carrocería
-- (nil = el suyo); accent = color de detalle (pinzas, costuras…; nil = el suyo).
function SportsCars.build(m: Model, kind: string, id: string, cf: CFrame, paint: Color3?, accent: Color3?): boolean
	local spec = PremiumVehicles.get(id)
	if not spec or spec.Kind ~= kind then
		return false
	end
	local previous = ctx
	ctx = {
		m = m,
		cf = cf,
		spec = spec,
		paint = paint or c3(spec.Paint, rgb(200, 200, 205)),
		second = c3(spec.Secondary, DARK),
		accent = accent or c3(spec.Accent, rgb(230, 60, 40)),
		glow = c3(spec.Glow, LENS),
		reflect = REFLECT[spec.Finish] or 0.1,
	}
	if accent and spec.Caliper then
		-- (acabado con color de detalle propio, p. ej. el oro del «Faro de Valmar»: pinzas a juego)
		spec = table.clone(spec)
		spec.Caliper = { math.floor(accent.R * 255 + 0.5), math.floor(accent.G * 255 + 0.5), math.floor(accent.B * 255 + 0.5) }
		ctx.spec = spec
	end
	local ok, err = pcall(if kind == "Moto" then buildMoto else buildCar)
	ctx = previous
	if not ok then
		error(err, 0)
	end
	m:SetAttribute("Variant", id)
	m:SetAttribute("Premium", true) -- (sin pinchazos y con menos consumo: lo mira el sistema de ruedas y combustible)
	m:SetAttribute("PremiumModel", id)
	m:SetAttribute("DisplayName", spec.Name)
	m:SetAttribute("Class", spec.Class)
	m:SetAttribute("EnginePitch", spec.EnginePitch or 1)
	m:SetAttribute("Paint", paint or c3(spec.Paint, rgb(200, 200, 205)))
	m:SetAttribute("Lite", false)
	return true
end

-- Asiento del conductor (respecto al centro a ras de suelo) o nil si no es un premium
function SportsCars.driverSeat(id: any): CFrame?
	local spec = PremiumVehicles.get(id)
	if not spec then
		return nil
	end
	local d = spec.SeatLayout.Driver
	return CFrame.new(d[1], d[2], d[3])
end

-- Asientos de pasajero en el formato de Rides.passengerSeats (o nil si no es un premium)
function SportsCars.passengerSeats(id: any): { { Seat: CFrame, Side: number, Label: string, Pose: string } }?
	local spec = PremiumVehicles.get(id)
	if not spec then
		return nil
	end
	local out = {}
	for _, p in spec.SeatLayout.Passengers do
		table.insert(out, { Seat = CFrame.new(p[1], p[2], p[3]), Side = p[4], Label = p[5], Pose = p[6] })
	end
	return out
end

return SportsCars
