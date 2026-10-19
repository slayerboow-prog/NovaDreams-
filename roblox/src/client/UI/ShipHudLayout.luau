-- ShipHudLayout: dónde va cada zona del HUD de la nave y las cuentas de la brújula, el radar y los
-- arcos (puro; Espacio AAA, docs/espacio-aaa/diseno.md y referencia-hud.png). Lo dibuja UI/AirCombatHud.
--
-- Zonas (en el lienzo de HudLayout: ~1700 de ancho, la misma escala que el resto del HUD), como la
-- imagen de referencia:
--   A       arriba izq.   piloto: avatar, nivel, nombre, dinero, 3 recursos y barras de casco/escudo/energía
--   B       arriba centro brújula N/E/S/O con marcas, «Sistema Valmar», zona/planeta y distancia al destino
--   J       bajo B        avisos (solo cuando hacen falta)
--   D       arriba der.   radar con aros       E bajo D: misiones (PRINCIPAL, SECUNDARIA, EVENTO GLOBAL)
--   Speed   izq. de la mira: arco de velocidad (KM/H), impulso y el modo
--   Defense der. de la mira: arcos de ESCUDO y ESTRUCTURA
--   Jump    der.          SALTO CUÁNTICO: destino, distancia y tecla/botón para activarlo
--   Target  der.          tarjeta OBJETIVO: nombre, nivel, distancia y salud
--   Keys / Moves (ordenador) «COMANDOS DE VUELO» y «MANIOBRAS ESPECIALES» (se pliegan con H)
--   Ship    (ordenador) abajo izq.: la nave en planta con escudo, casco y energía en %
--   Quick   (ordenador) abajo der.: giros, esquivar, camuflaje, «Modo Combate ON/OFF» y el reloj
--   H       abajo centro: barra de 8 ranuras con cantidades; Prompt encima (HIPERVELOCIDAD – mantén Shift)
--   Help    (móvil) botón «?» junto a A; HelpPanel: lo que hace cada botón (encima de todo)
--   Quantum el selector del salto cuántico (encima de todo)
-- En el móvil van los mismos datos en compacto (la palanca y los botones grandes ocupan las esquinas de
-- abajo): sin Keys/Moves/Ship/Quick; el reloj va en A y el modo en Speed.
-- Por VEHÍCULO (Vehicles): cada uno dice qué zonas tiene (la nave todas; el avión sin salto ni escudo…).
-- Nada se pisa en 1920x1080, 932x430, 844x390 ni 640x360 (scripts/test-espacio-aaa.luau).

local HudLayout = require(script.Parent.HudLayout)

local ShipHudLayout = {}

export type Rect = { X: number, Y: number, W: number, H: number }
export type Layout = {
	Scale: number,
	Canvas: Vector2,
	Touch: boolean,
	Vehicle: string,
	Zones: { [string]: Rect },
	Buttons: { [string]: Rect }, -- (táctil) los botones grandes de la nave
	Stick: Rect?, -- (táctil) el aro de la palanca en reposo
	SlotSize: number,
	SlotGap: number,
}

local MARGIN = 16
local ROBLOX_BUTTONS = 250 -- píxeles reales de los botones de Roblox de arriba a la izquierda

ShipHudLayout.Sizes = {
	Pc = {
		A = Vector2.new(520, 124), B = Vector2.new(620, 116), J = Vector2.new(560, 32), D = 220, E = Vector2.new(400, 220),
		Speed = Vector2.new(220, 230), Defense = Vector2.new(165, 230), Jump = Vector2.new(300, 120), Target = Vector2.new(300, 96),
		Keys = 300, KeyRow = 21, Ship = Vector2.new(330, 180), Quick = Vector2.new(300, 210),
		Slot = 84, Gap = 8, Prompt = Vector2.new(480, 58),
	},
	Touch = {
		A = Vector2.new(400, 108), B = Vector2.new(540, 108), J = Vector2.new(520, 32), D = 180, E = Vector2.new(360, 150),
		Speed = Vector2.new(180, 200), Defense = Vector2.new(160, 200), Jump = Vector2.new(320, 96), Target = Vector2.new(320, 92),
		Help = Vector2.new(92, 92), Slot = 90, Gap = 6, Prompt = Vector2.new(440, 54),
	},
}

-- Qué zonas tiene cada vehículo (y qué enseña). Otros controladores (el avión…) añaden el suyo con
-- defineVehicle sin tocar lo demás.
local ALL = { "A", "B", "J", "D", "E", "Speed", "Defense", "Jump", "Target", "Keys", "Moves", "Ship", "Quick", "H", "Prompt", "Quantum", "Help", "HelpPanel" }
local function set(list: { string }, without: { string }?): { [string]: boolean }
	local out = {}
	for _, n in list do
		out[n] = true
	end
	for _, n in without or {} do
		out[n] = nil
	end
	return out
end
export type Vehicle = { Name: string, Panels: { [string]: boolean }, Shield: boolean, Slots: number, Silhouette: string }
ShipHudLayout.Vehicles = {
	Ship = { Name = "NAVE", Panels = set(ALL), Shield = true, Slots = 8, Silhouette = "Nave" },
	Plane = { Name = "AVIÓN", Panels = set(ALL, { "Jump", "Quantum" }), Shield = false, Slots = 8, Silhouette = "Avion" },
} :: { [string]: Vehicle }
ShipHudLayout.Panels = ALL

-- Un vehículo nuevo: sus zonas son todas menos `Without`
function ShipHudLayout.defineVehicle(id: string, v: { Name: string?, Without: { string }?, Shield: boolean?, Slots: number?, Silhouette: string? })
	ShipHudLayout.Vehicles[id] = {
		Name = v.Name or string.upper(id),
		Panels = set(ALL, v.Without),
		Shield = v.Shield ~= false,
		Slots = v.Slots or 8,
		Silhouette = v.Silhouette or "Nave",
	}
end

function ShipHudLayout.vehicle(id: string?): Vehicle
	return ShipHudLayout.Vehicles[id or "Ship"] or ShipHudLayout.Vehicles.Ship
end

-- Los botones de la nave en el móvil (huecos de HudLayout.Fly)
ShipHudLayout.ButtonSlots = { "Fuego", "Misil", "Turbo", "FrenoNave", "EsquivaNave", "BengalasNave", "ObjetivoNave", "SalirNave", "ValmarNave", "AccionNave", "LoopingNave", "TonelNave" }
-- Los del avión (UI/FlyButtons, en los sitios de DISPARO, MISIL y FRENO): compute(…, { Buttons = … })
ShipHudLayout.PlaneButtonSlots = { "MotorMas", "MotorMenos", "Frenos" }

-- Filas de las dos listas de teclas (las de ShipKeys.Groups; aquí solo para el alto)
ShipHudLayout.KeyRows = { Keys = 12, Moves = 10 }

local function rect(x: number, y: number, w: number, h: number): Rect
	return { X = x, Y = y, W = w, H = h }
end

-- (options.Buttons: los huecos de HudLayout.Fly de los botones grandes; los de la nave por defecto)
function ShipHudLayout.compute(viewport: Vector2, options: { Touch: boolean?, Inset: number?, Vehicle: string?, Buttons: { string }? }?): Layout
	local opts = options or {}
	local touch = opts.Touch == true
	local vehicle = ShipHudLayout.vehicle(opts.Vehicle)
	local base = HudLayout.compute(viewport, { Touch = touch, Inset = opts.Inset })
	local scale = base.Scale
	local canvas = base.Canvas
	local W, H = canvas.X, canvas.Y
	local S: any = if touch then ShipHudLayout.Sizes.Touch else ShipHudLayout.Sizes.Pc
	local inset = (opts.Inset or 58) / scale
	local z: { [string]: Rect } = {}
	-- A: debajo de los botones de Roblox (como tu estado de siempre)
	local aTop = math.max(inset + 4, 64)
	z.A = rect(MARGIN, aTop, S.A.X, S.A.Y)
	-- B: arriba en el centro; si los botones de Roblox llegan, se aparta a la derecha (sin llegar al
	-- radar) o baja bajo su franja
	local bTop = 8
	local cx = W / 2
	local rb = ROBLOX_BUTTONS / scale + 8
	if cx - S.B.X / 2 < rb then
		local room = W - MARGIN - S.D - 12
		if rb + S.B.X <= room then
			cx = rb + S.B.X / 2
		else
			bTop = inset + 8
		end
	end
	z.B = rect(cx - S.B.X / 2, bTop, S.B.X, S.B.Y)
	z.J = rect(cx - S.J.X / 2, z.B.Y + S.B.Y + 6, S.J.X, S.J.Y)
	-- D y E: arriba a la derecha
	z.D = rect(W - MARGIN - S.D, 10, S.D, S.D)
	z.E = rect(W - MARGIN - S.E.X, 10 + S.D + 12, S.E.X, S.E.Y)
	-- Los arcos, a los lados de la mira (sin tapar el centro)
	local center = ShipHudLayout.center({ Canvas = canvas })
	local midY = H * 0.45
	z.Speed = rect(center.X - 10 - S.Speed.X, midY - S.Speed.Y / 2, S.Speed.X, S.Speed.Y)
	z.Defense = rect(center.X + center.W + 10, midY - S.Defense.Y / 2, S.Defense.X, S.Defense.Y)
	-- H: la barra de ranuras abajo en el centro; el letrero encima
	local barW = S.Slot * 8 + S.Gap * 7 + 16
	local barH = S.Slot + 34
	local barBottom = if touch then 8 else MARGIN
	z.H = rect(W / 2 - barW / 2, H - barBottom - barH, barW, barH)
	z.Prompt = rect(W / 2 - S.Prompt.X / 2, z.H.Y - S.Prompt.Y - 8, S.Prompt.X, S.Prompt.Y)
	-- El selector del salto cuántico (encima de todo, en el centro; se cierra solo)
	local qH = math.min(560, H - 140)
	z.Quantum = rect(W / 2 - 290, math.max(70, H / 2 - qH / 2), 580, qH)
	local buttons: { [string]: Rect } = {}
	local stick: Rect? = nil
	if touch then
		-- Salto y objetivo, en compacto bajo A (la palanca empieza más abajo); «?» junto a A
		z.Jump = rect(MARGIN, z.A.Y + z.A.H + 10, S.Jump.X, S.Jump.Y)
		z.Target = rect(MARGIN, z.Jump.Y + S.Jump.Y + 8, S.Target.X, S.Target.Y)
		z.Help = rect(z.A.X + z.A.W + 10, z.A.Y, S.Help.X, S.Help.Y)
		z.HelpPanel = rect(W / 2 - 300, math.max(60, H / 2 - 200), 600, math.min(400, H - 120))
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
		-- Derecha: salto y objetivo bajo las misiones; abajo, los atajos con el modo y el reloj
		z.Jump = rect(W - MARGIN - S.Jump.X, z.E.Y + z.E.H + 12, S.Jump.X, S.Jump.Y)
		z.Target = rect(W - MARGIN - S.Target.X, z.Jump.Y + S.Jump.Y + 12, S.Target.X, S.Target.Y)
		z.Quick = rect(W - MARGIN - S.Quick.X, H - MARGIN - S.Quick.Y, S.Quick.X, S.Quick.Y)
		-- Izquierda: las dos listas de teclas bajo A y la nave en planta abajo
		local kh = 30 + ShipHudLayout.KeyRows.Keys * S.KeyRow
		local mh = 30 + ShipHudLayout.KeyRows.Moves * S.KeyRow
		z.Keys = rect(MARGIN, z.A.Y + z.A.H + 12, S.Keys, kh)
		z.Moves = rect(MARGIN, z.Keys.Y + kh + 8, S.Keys, mh)
		z.Ship = rect(MARGIN, H - MARGIN - S.Ship.Y, S.Ship.X, S.Ship.Y)
	end
	-- Solo las zonas del vehículo
	for name in z do
		if not vehicle.Panels[name] then
			z[name] = nil
		end
	end
	return { Scale = scale, Canvas = canvas, Touch = touch, Vehicle = opts.Vehicle or "Ship", Zones = z, Buttons = buttons, Stick = stick, SlotSize = S.Slot, SlotGap = S.Gap }
end

-- Zonas que van encima de todo (se abren y se cierran) y no cuentan para «se pisa»
ShipHudLayout.Overlays = { Quantum = true, HelpPanel = true }

function ShipHudLayout.overlaps(a: Rect, b: Rect): boolean
	return a.X < b.X + b.W and b.X < a.X + a.W and a.Y < b.Y + b.H and b.Y < a.Y + a.H
end

-- Lo que se pisa (debe estar vacío): zonas entre sí (menos el selector del salto, que va encima), con los
-- botones y con la palanca; y lo que se sale de la pantalla
function ShipHudLayout.clashes(l: Layout): { string }
	local out = {}
	local names = {}
	for name in l.Zones do
		if not ShipHudLayout.Overlays[name] then
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
function ShipHudLayout.center(l: { Canvas: Vector2 }): Rect
	local w, h = l.Canvas.X * 0.3, l.Canvas.Y * 0.22
	return rect(l.Canvas.X / 2 - w / 2, l.Canvas.Y * 0.45 - h / 2, w, h)
end

---------------------------------------------------------------------
-- Arcos (Speed y Defense): n rayitas a lo largo de un arco de `from` a `to` grados (0 = derecha,
-- 90 = abajo; pantalla), en 0..1 del marco, con su giro (tangente). Se encienden las primeras k*n.
---------------------------------------------------------------------
export type Tick = { X: number, Y: number, Rot: number }
function ShipHudLayout.arc(n: number, from: number, to: number, radius: number?, cx: number?, cy: number?): { Tick }
	local r = radius or 0.45
	local out = {}
	for i = 0, n - 1 do
		local a = from + (to - from) * (if n > 1 then i / (n - 1) else 0)
		local rad = math.rad(a)
		table.insert(out, { X = (cx or 0.5) + math.cos(rad) * r, Y = (cy or 0.5) + math.sin(rad) * r, Rot = a + 90 })
	end
	return out
end

function ShipHudLayout.lit(n: number, k: number): number
	return math.clamp(math.floor(k * n + 0.5), 0, n)
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
	-- (aviones) las cabeceras de las pistas y los otros aviones
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
