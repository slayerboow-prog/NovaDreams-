-- ShipHudLayout: dónde va cada zona del HUD de la nave y las cuentas de la brújula y el radar (puro;
-- Espacio AAA, docs/espacio-aaa/diseno.md y referencia-hud.png). Lo dibuja UI/AirCombatHud.
--
-- Zonas (en el lienzo de HudLayout: ~1700 de ancho, la misma escala que el resto del HUD):
--   A arriba izq.   perfil del piloto            B arriba centro  brújula, sistema, zona, destino, salto
--   C bajo B        estado de la nave            D arriba der.    radar
--   E bajo D        misiones y eventos           F centro         mira y fijación (en píxeles, aparte)
--   G abajo izq.    palanca (táctil) o teclas    H abajo centro   barra de 8 ranuras
--   I abajo der.    botones grandes (táctil: HudLayout.Fly) o lista de teclas (ordenador)
--   J               avisos (bajo C) y el letrero de la habilidad en marcha (encima de H)
-- Nada se pisa en 1920x1080, 932x430, 844x390 ni 640x360 (scripts/test-espacio-aaa.luau).
-- Los aviones del aeroclub usan las mismas zonas (UI/AirCombatHud con Variant = "Plane"): compute con
-- { Slots = 5, Buttons = ShipHudLayout.PlaneButtonSlots } (sus botones grandes MOTOR +, MOTOR − y
-- FRENOS; scripts/test-hud.luau comprueba que nada se pisa en las mismas cuatro pantallas).

local HudLayout = require(script.Parent.HudLayout)

local ShipHudLayout = {}

export type Rect = { X: number, Y: number, W: number, H: number }
export type Layout = {
	Scale: number,
	Canvas: Vector2,
	Touch: boolean,
	Zones: { [string]: Rect },
	Buttons: { [string]: Rect }, -- (táctil) los botones grandes de la nave
	Stick: Rect?, -- (táctil) el aro de la palanca en reposo
	SlotSize: number,
	SlotGap: number,
}

local MARGIN = 16
local ROBLOX_BUTTONS = 250 -- píxeles reales de los botones de Roblox de arriba a la izquierda

ShipHudLayout.Sizes = {
	Pc = { A = Vector2.new(430, 112), B = Vector2.new(620, 104), C = Vector2.new(660, 86), J = Vector2.new(560, 32), D = 220, E = Vector2.new(400, 250), Slot = 84, Gap = 8, G = Vector2.new(330, 210), Prompt = Vector2.new(480, 58) },
	Touch = { A = Vector2.new(390, 100), B = Vector2.new(540, 98), C = Vector2.new(600, 80), J = Vector2.new(520, 32), D = 180, E = Vector2.new(360, 140), Slot = 90, Gap = 6, G = Vector2.new(0, 0), Prompt = Vector2.new(440, 54) },
}

-- Los botones de la nave en el móvil (huecos de HudLayout.Fly)
ShipHudLayout.ButtonSlots = { "Fuego", "Misil", "Turbo", "FrenoNave", "EsquivaNave", "BengalasNave", "ObjetivoNave", "SalirNave", "ValmarNave", "AccionNave" }
-- Los de los aviones (UI/FlyButtons: el motor como el IMPULSO y los frenos como el FRENO de la nave)
ShipHudLayout.PlaneButtonSlots = { "MotorMas", "MotorMenos", "Frenos" }
ShipHudLayout.PlaneSlots = 5 -- ranuras del avión: FLAPS, TREN, CÁMARA, PALANCA y BAJARSE

local function rect(x: number, y: number, w: number, h: number): Rect
	return { X = x, Y = y, W = w, H = h }
end

-- options.Slots (cuántas ranuras tiene la barra H; 8 por defecto) y options.Buttons (los huecos de
-- HudLayout.Fly de los botones grandes; los de la nave por defecto) son para los aviones
function ShipHudLayout.compute(viewport: Vector2, options: { Touch: boolean?, Inset: number?, Slots: number?, Buttons: { string }? }?): Layout
	local opts = options or {}
	local touch = opts.Touch == true
	local base = HudLayout.compute(viewport, { Touch = touch, Inset = opts.Inset })
	local scale = base.Scale
	local canvas = base.Canvas
	local W, H = canvas.X, canvas.Y
	local S = if touch then ShipHudLayout.Sizes.Touch else ShipHudLayout.Sizes.Pc
	local inset = (opts.Inset or 58) / scale
	local z: { [string]: Rect } = {}
	-- A: debajo de los botones de Roblox (como tu estado de siempre)
	local aTop = math.max(inset + 4, 64)
	z.A = rect(MARGIN, aTop, S.A.X, S.A.Y)
	-- B: arriba en el centro; si los botones de Roblox llegan, baja bajo su franja (móvil pequeño)
	-- (primero se aparta a la derecha, sin llegar al radar; si no cabe, baja)
	local bTop = 8
	local cx = W / 2
	local rb = ROBLOX_BUTTONS / scale + 8
	if cx - S.B.X / 2 < rb then
		local room = W - MARGIN - S.D - 12
		if rb + math.max(S.B.X, S.C.X) <= room then
			cx = rb + math.max(S.B.X, S.C.X) / 2
		else
			bTop = inset + 8
		end
	end
	z.B = rect(cx - S.B.X / 2, bTop, S.B.X, S.B.Y)
	z.C = rect(cx - S.C.X / 2, bTop + S.B.Y + 6, S.C.X, S.C.Y)
	z.J = rect(cx - S.J.X / 2, z.C.Y + S.C.Y + 6, S.J.X, S.J.Y)
	-- D y E: arriba a la derecha
	z.D = rect(W - MARGIN - S.D, 10, S.D, S.D)
	z.E = rect(W - MARGIN - S.E.X, 10 + S.D + 12, S.E.X, S.E.Y)
	-- H: la barra de 8 ranuras abajo en el centro
	local nSlots = opts.Slots or 8
	local barW = S.Slot * nSlots + S.Gap * (nSlots - 1) + 16
	local barH = S.Slot + 34
	local barBottom = if touch then 8 else MARGIN
	z.H = rect(W / 2 - barW / 2, H - barBottom - barH, barW, barH)
	-- J2: el letrero de la habilidad en marcha (hipervelocidad, salto), encima de la barra
	z.Prompt = rect(W / 2 - S.Prompt.X / 2, z.H.Y - S.Prompt.Y - 8, S.Prompt.X, S.Prompt.Y)
	-- El selector del salto cuántico (encima de todo, en el centro; se cierra solo)
	local qH = math.min(560, H - 140)
	z.Quantum = rect(W / 2 - 290, math.max(70, H / 2 - qH / 2), 580, qH)
	local buttons: { [string]: Rect } = {}
	local stick: Rect? = nil
	if touch then
		for _, id in opts.Buttons or ShipHudLayout.ButtonSlots do
			local p = base.FlySlots[id]
			if p then
				buttons[id] = HudLayout.rect(p, canvas)
			end
		end
		if base.Items.FlightStick then
			stick = HudLayout.rect(base.Items.FlightStick, canvas)
		end
	else
		-- G: la tarjeta de teclas abajo a la izquierda; I: la lista de teclas de los botones (TouchLayout)
		z.G = rect(MARGIN, H - MARGIN - S.G.Y, S.G.X, S.G.Y)
		if base.Items.Hints then
			z.I = HudLayout.rect(base.Items.Hints, canvas)
		end
	end
	return { Scale = scale, Canvas = canvas, Touch = touch, Zones = z, Buttons = buttons, Stick = stick, SlotSize = S.Slot, SlotGap = S.Gap }
end

function ShipHudLayout.overlaps(a: Rect, b: Rect): boolean
	return a.X < b.X + b.W and b.X < a.X + a.W and a.Y < b.Y + b.H and b.Y < a.Y + a.H
end

-- Lo que se pisa (debe estar vacío): zonas entre sí (menos el selector del salto, que va encima), con los
-- botones y con la palanca; y lo que se sale de la pantalla
function ShipHudLayout.clashes(l: Layout): { string }
	local out = {}
	local names = {}
	for name in l.Zones do
		if name ~= "Quantum" then
			table.insert(names, name)
		end
	end
	table.sort(names)
	local function inside(r: Rect): boolean
		return r.X >= -1 and r.Y >= -1 and r.X + r.W <= l.Canvas.X + 1 and r.Y + r.H <= l.Canvas.Y + 1
	end
	for i, a in names do
		local ra = l.Zones[a]
		if not inside(ra) then
			table.insert(out, a .. " fuera de la pantalla")
		end
		for j = i + 1, #names do
			local b = names[j]
			if ShipHudLayout.overlaps(ra, l.Zones[b]) then
				table.insert(out, a .. "/" .. b)
			end
		end
		for id, r in l.Buttons do
			if ShipHudLayout.overlaps(ra, r) then
				table.insert(out, a .. "/" .. id)
			end
		end
		if l.Stick and ShipHudLayout.overlaps(ra, l.Stick) then
			table.insert(out, a .. "/palanca")
		end
	end
	return out
end

-- El centro de la pantalla (la mira y lo que se ve del combate): ninguna zona lo tapa
function ShipHudLayout.center(l: Layout): Rect
	local w, h = l.Canvas.X * 0.3, l.Canvas.Y * 0.22
	return rect(l.Canvas.X / 2 - w / 2, l.Canvas.Y * 0.45 - h / 2, w, h)
end

---------------------------------------------------------------------
-- Brújula (zona B): marcas visibles para un rumbo (grados; 0 = N) en una ventana de `span` grados
---------------------------------------------------------------------
local CARDINAL = { [0] = "N", [45] = "NE", [90] = "E", [135] = "SE", [180] = "S", [225] = "SO", [270] = "O", [315] = "NO" }

export type Mark = { Text: string, X: number, Major: boolean, Deg: number }
function ShipHudLayout.compass(heading: number, span: number?): { Mark }
	local half = (span or 120) / 2
	local out = {}
	for deg = 0, 345, 15 do
		local d = ((deg - heading + 540) % 360) - 180
		if math.abs(d) <= half then
			table.insert(out, { Text = CARDINAL[deg] or "", X = 0.5 + d / (half * 2), Major = CARDINAL[deg] ~= nil and deg % 90 == 0, Deg = deg })
		end
	end
	table.sort(out, function(a, b)
		return a.X < b.X
	end)
	return out
end

-- Dónde cae en la brújula una dirección hacia un sitio (0..1, o nil si queda fuera de la ventana)
function ShipHudLayout.bearingX(heading: number, bearing: number, span: number?): number?
	local half = (span or 120) / 2
	local d = ((bearing - heading + 540) % 360) - 180
	if math.abs(d) > half then
		return nil
	end
	return 0.5 + d / (half * 2)
end

---------------------------------------------------------------------
-- Radar (zona D): delante = arriba; solo lo que está dentro del alcance
---------------------------------------------------------------------
ShipHudLayout.RadarRange = { Combat = 1400, Cruise = 4000, Explore = 6000 }
ShipHudLayout.Kinds = {
	Enemigo = { Color = Color3.fromRGB(255, 70, 70), Size = 10, Shape = "Rombo" },
	Fijado = { Color = Color3.fromRGB(255, 210, 60), Size = 16, Shape = "Rombo" },
	Aliado = { Color = Color3.fromRGB(90, 170, 255), Size = 10, Shape = "Punto" },
	Estacion = { Color = Color3.fromRGB(110, 255, 190), Size = 14, Shape = "Cuadro" },
	Planeta = { Color = Color3.fromRGB(255, 190, 120), Size = 16, Shape = "Punto" },
	Campo = { Color = Color3.fromRGB(170, 170, 185), Size = 12, Shape = "Aro" },
	Baliza = { Color = Color3.fromRGB(190, 140, 255), Size = 12, Shape = "Rombo" },
	Mision = { Color = Color3.fromRGB(255, 205, 70), Size = 14, Shape = "Aro" },
	Salto = { Color = Color3.fromRGB(200, 120, 255), Size = 14, Shape = "Aro" },
	-- (aviones) las pistas y los otros aviones
	Pista = { Color = Color3.fromRGB(235, 248, 255), Size = 14, Shape = "Cuadro" },
	Avion = { Color = Color3.fromRGB(90, 170, 255), Size = 11, Shape = "Rombo" },
}

export type Contact = { Kind: string, Pos: Vector3, Id: string?, Radius: number? }
export type Blip = { Kind: string, Point: Vector2, Distance: number, Above: number, Id: string? }

function ShipHudLayout.radarPoint(ship: CFrame, pos: Vector3, range: number): Vector2
	local rel = ship:PointToObjectSpace(pos)
	local v = Vector2.new(rel.X, rel.Z) / range
	if v.Magnitude > 1 then
		v = v.Unit
	end
	return v
end

-- Los puntos del radar: solo lo que está a menos de `range` (si tiene radio, contando su borde)
function ShipHudLayout.blips(ship: CFrame, contacts: { Contact }, range: number, max: number?): { Blip }
	local out = {}
	for _, c in contacts do
		local dist = (c.Pos - ship.Position).Magnitude - (c.Radius or 0)
		if dist <= range then
			local rel = ship:PointToObjectSpace(c.Pos)
			table.insert(out, { Kind = c.Kind, Point = ShipHudLayout.radarPoint(ship, c.Pos, range), Distance = math.max(0, dist), Above = rel.Y, Id = c.Id })
		end
	end
	-- (lo más importante primero: enemigos y fijado, luego lo más cercano)
	table.sort(out, function(a, b)
		local pa = if a.Kind == "Fijado" then 0 elseif a.Kind == "Enemigo" then 1 else 2
		local pb = if b.Kind == "Fijado" then 0 elseif b.Kind == "Enemigo" then 1 else 2
		if pa ~= pb then
			return pa < pb
		end
		return a.Distance < b.Distance
	end)
	if max then
		while #out > max do
			table.remove(out)
		end
	end
	return out
end

return ShipHudLayout
