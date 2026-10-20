-- AirCombatHud: el HUD de la nave (combate aéreo y espacio; Controllers/AirCombatClient). Espacio AAA:
-- TODO lo de la imagen de referencia (docs/espacio-aaa/referencia-hud.png), colocado por
-- UI/ShipHudLayout sin pisarse en 1920x1080, 932x430, 844x390 y 640x360 (ver allí cada zona):
--   A piloto (avatar, nivel, nombre, dinero, 3 recursos, barras de casco/escudo/energía) · B brújula,
--   «Sistema Valmar», zona/planeta y distancia · J avisos · D radar con aros · E misiones (PRINCIPAL,
--   SECUNDARIA, EVENTO GLOBAL con su reloj) · Speed arco de velocidad (KM/H), impulso y modo · Defense
--   arcos de ESCUDO y ESTRUCTURA · Jump SALTO CUÁNTICO (destino, distancia, activar) · Target tarjeta
--   OBJETIVO · Keys/Moves «COMANDOS DE VUELO» y «MANIOBRAS ESPECIALES» (ordenador; H las pliega; con
--   mando, sus botones) · Ship la nave en planta con % · Quick giros, esquivar, camuflaje, «Modo
--   Combate ON/OFF» y el reloj · H barra de 8 ranuras · Prompt «HIPERVELOCIDAD – mantén Shift» ·
--   Quantum el selector del salto · (móvil) Help «?» con lo que hace cada botón.
--   F (encima de todo, en píxeles): la mira con su aro, los corchetes de fijación con nombre, nivel,
--   salud y distancia, flechas en el borde, la marca de impacto y el destello al recibir.
-- Por vehículo (ShipHudLayout.Vehicles; setVehicle): la nave lo tiene todo; el avión, sin salto ni
-- escudo. Las funciones de antes siguen (set, setProfile, setNav, setMissions, setSlots, setHints…).
-- Colores: paneles azul oscuro semitransparentes con filo cian, impulso naranja, hostil rojo.
-- Ritmo: el controlador llama a set/setNav/radar… a 10 por segundo y a la brújula a 30; aquí solo se
-- cambia una propiedad si cambia su valor.
-- Lo puro (textos, radar, flechas) lo prueban scripts/test-aircombat.luau y scripts/test-espacio-aaa.luau.
--
-- AVIONES (vehículo "Plane"; queja del dueño: «los controles del avión, la interfaz y todo, debe ser
-- igual que el de las naves espaciales»): Controllers/PlaneHudClient crea este mismo HUD con
-- new(parent, touch, "Plane") y lo llena con setPlane (puro: planeTexts): el arco de velocidad con el
-- MOTOR (donde el IMPULSO) y EN TIERRA / EN VUELO / PÉRDIDA; ESTRUCTURA = daños; la tarjeta de abajo
-- izquierda con ALTITUD, V/S, RUMBO y «FLAPS · TREN · FRENOS»; los atajos con FLAPS, TREN, CÁMARA,
-- BAJARSE y la palanca; la tarjeta OBJETIVO como PISTA (cuánta queda); las ranuras con sus iconos
-- (v.Glyph); las listas de teclas y el «?» del móvil con los mandos del avión (setHintLists,
-- setTouchHelp). Todo lo añadido es opcional: la nave sigue igual.

local HudLayout = require(script.Parent.HudLayout)
local Theme = require(script.Parent.Theme)
local ShipHudLayout = require(script.Parent.ShipHudLayout)
local HudArt = require(script.Parent.HudArt)
local ShipAbilities = require(game:GetService("ReplicatedStorage").Shared.AirCombat.ShipAbilities)
local ShipKeys = require(game:GetService("ReplicatedStorage").Shared.AirCombat.ShipKeys)

local AirCombatHud = {}

local create = Theme.create
local rgb = Color3.fromRGB

AirCombatHud.Keys = "Ratón apuntar · W/S motor · A/D lateral · Q/E alabeo · Clic fuego · 2 misil · Shift impulso · Ctrl freno · C esquiva · B salir"
AirCombatHud.RadarRange = 1400
AirCombatHud.Arrows = 8
AirCombatHud.MaxBlips = 24

AirCombatHud.Colors = {
	Panel = rgb(6, 16, 34),
	Edge = rgb(70, 200, 255),
	Cyan = rgb(110, 230, 255),
	White = rgb(235, 248, 255),
	Muted = rgb(140, 175, 205),
	Boost = rgb(255, 150, 40),
	Hostile = rgb(255, 70, 70),
	Energy = rgb(120, 240, 255),
	Shield = rgb(80, 170, 255),
	Hull = rgb(90, 235, 140),
	Gold = rgb(255, 205, 70),
	Locked = rgb(110, 120, 140),
	Violet = rgb(200, 130, 255),
}
local K = AirCombatHud.Colors

local WARN_TEXT = { Limite = "⚠ LÍMITE: la nave vuelve sola", Lento = "⚠ MUY LENTO: acelera", Calor = "⚠ CAÑONES RECALENTADOS" }

export type Info = {
	Speed: number,
	Boost: number,
	BoostReady: boolean,
	Shield: number,
	MaxShield: number,
	Hull: number,
	MaxHull: number,
	Missiles: number,
	MaxMissiles: number,
	Overheated: boolean,
	Wave: number,
	Score: number,
	Objective: string,
	Warn: string?,
	Mode: string,
	Energy: number?,
	MaxEnergy: number?,
	Weapon: string?, -- "Cannons" | "Laser"
	Heat: number?,
	FlightMode: string?, -- "Combat" | "Cruise"
	Assist: boolean?,
	Boosting: boolean?,
	Alert: string?,
	Flares: number?,
	MaxFlares: number?,
	SpeedMax: number?, -- (el arco de velocidad: lo que es «lleno»)
}

export type View = {
	Gui: ScreenGui,
	Panel: Frame,
	Values: { [string]: TextLabel },
	Bars: { [string]: Frame },
	Objective: TextLabel,
	Warning: TextLabel,
	Radar: Frame,
	Blips: { Frame },
	Overlay: ScreenGui,
	Cross: Frame,
	LockBox: Frame,
	LockStroke: UIStroke,
	Arrows: { TextLabel },
	HitMark: TextLabel,
	Flash: Frame,
	Zones: { [string]: Frame },
	Profile: { [string]: any },
	Nav: { [string]: any },
	Missions: { { [string]: any } },
	Slots: { { [string]: any } },
	Prompt: { [string]: any },
	Quantum: { [string]: any },
	Hints: Frame?,
	RadarLabel: TextLabel,
	RadarNorth: Frame,
	Chips: { [string]: TextLabel },
	LockInfo: TextLabel,
	Touch: boolean,
	OnSlot: ((string) -> ())?,
	Cache: { [Instance]: { [string]: any } },
	Vehicle: string,
	Arcs: { [string]: { Frame } },
	Jump: { [string]: any },
	TargetCard: { [string]: any },
	QuickRows: { [string]: TextLabel },
	Clock: TextLabel?,
	HelpPanel: Frame?,
	HintsSpecial: Frame?,
	HintTitles: { [string]: TextLabel },
	HintsOpen: boolean,
	RadarLetters: { [string]: TextLabel },
	Brackets: { Frame },
	LockHealth: Frame?,
	LockDist: TextLabel?,
	ShieldRows: { GuiObject }?,
	Silhouette: Frame?,
	LastLayout: any,
	HelpTitle: TextLabel?, -- (móvil) el título y la lista del panel «?» (setTouchHelp)
	HelpList: Frame?,
	HintNames: { [string]: string }?, -- títulos propios de las dos listas de teclas (setHintLists)
	PlaneLabeled: boolean?, -- (aviones) los rótulos ya están cambiados (setPlane)
	PathMarker: Frame?, -- (aviones) el marcador de trayectoria (setReticle "Vuelo")
	Art: { [string]: any }, -- los sprites puestos (UI/HudArt; vacío sin ids: el aspecto de siempre)
	Gauges: { [string]: number }, -- lo que enseñan ahora los arcos (se acercan al valor: relleno animado)
	GaugeClock: number?,
}

-- Los datos del panel de un avión (AirCombatHud.setPlane)
export type PlaneInfo = {
	Speed: number, -- km/h (studs/s)
	SpeedMax: number?, -- para el arco
	Altitude: number, -- metros
	Heading: number, -- grados (0 = N)
	Climb: number, -- m/s (+ subiendo)
	Throttle: number, -- 0..1
	Gear: boolean,
	FixedGear: boolean?,
	Flaps: number,
	Brake: boolean,
	Health: number, -- 0..100
	Warn: string?, -- "Perdida" | "Tren" | "Limite" | "Techo" | "FinPista"
	OnGround: boolean,
	Stalled: boolean?,
	Ceiling: number?, -- metros (para la barra de la altitud)
	Alert: string?, -- un aviso que manda sobre los demás
	PullUp: boolean?, -- tirar hacia abajo sube el morro (el ajuste)
}

---------------------------------------------------------------------
-- Ayudantes
---------------------------------------------------------------------
-- Cambia una propiedad solo si cambia (el HUD se actualiza mucho: no tocar lo que no cambia)
local function put(view: View, obj: Instance, prop: string, value: any)
	local c = view.Cache[obj]
	if not c then
		c = {}
		view.Cache[obj] = c
	end
	if c[prop] ~= value then
		c[prop] = value
		;(obj :: any)[prop] = value
	end
end

-- (pcall: fuera de Roblox, en las pruebas con Lune, los botones no tienen eventos)
local function onActivated(button: GuiButton, fn: () -> ()): RBXScriptConnection?
	local ok, conn = pcall(function()
		return button.Activated:Connect(fn)
	end)
	return if ok then conn else nil
end

local function panel(name: string, parent: Instance, transparency: number?): Frame
	local f = create("Frame", { Name = name, BackgroundColor3 = K.Panel, BackgroundTransparency = transparency or 0.28, BorderSizePixel = 0, Parent = parent })
	create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = f })
	create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(40, 90, 150), rgb(6, 14, 30)), Parent = f })
	create("UIStroke", { Name = "Edge", Color = K.Edge, Thickness = 1.6, Transparency = 0.25, Parent = f })
	-- (esquinas brillantes, como la referencia)
	for _, c in { { 0, 0 }, { 1, 1 } } do
		create("Frame", { Name = "Esquina", AnchorPoint = Vector2.new(c[1], c[2]), Position = UDim2.fromScale(c[1], c[2]), Size = UDim2.fromOffset(22, 3), BackgroundColor3 = K.Cyan, BorderSizePixel = 0, Parent = f })
	end
	-- (con sprites: marco biselado con filo cian, esquinas brillantes y degradado; UI/HudArt)
	HudArt.frame(f)
	return f
end

local function label(props: { [string]: any }): TextLabel
	local defaults = { Font = Theme.FontBold, TextColor3 = K.White, TextSize = 16, TextStrokeTransparency = 0.6, TextStrokeColor3 = rgb(0, 10, 20) }
	for k, v in props do
		defaults[k] = v
	end
	return Theme.label(defaults)
end

local function bar(parent: Instance, name: string, color: Color3, pos: UDim2, size: UDim2): Frame
	local track = create("Frame", { Name = name .. "Track", Position = pos, Size = size, BackgroundColor3 = rgb(10, 20, 36), BackgroundTransparency = 0.1, BorderSizePixel = 0, Parent = parent })
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
	create("UIStroke", { Color = color, Thickness = 1, Transparency = 0.6, Parent = track })
	local fill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BorderSizePixel = 0, Parent = track })
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
	create("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(190, 200, 210)), Parent = fill })
	return fill
end

local function ring(parent: Instance, size: UDim2, color: Color3, thick: number, transparency: number?): Frame
	local f = create("Frame", { Name = "Aro", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = size, BackgroundTransparency = 1, Parent = parent })
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = f })
	create("UIStroke", { Color = color, Thickness = thick, Transparency = transparency or 0, Parent = f })
	return f
end

local function line(parent: Instance, pos: UDim2, size: UDim2, rot: number, color: Color3): Frame
	return create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = size, Rotation = rot, BackgroundColor3 = color, BorderSizePixel = 0, Parent = parent })
end

-- Iconos de línea de las ranuras, dibujados con marcos (no dependen de imágenes ni de la fuente)
function AirCombatHud.glyph(parent: Instance, kind: string, color: Color3): Frame
	local g = create("Frame", { Name = "Glifo", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.56, 0.56), BackgroundTransparency = 1, Parent = parent })
	g:SetAttribute("Glyph", kind)
	local c = UDim2.fromScale(0.5, 0.5)
	if kind == "Canon" then
		for _, y in { 0.32, 0.68 } do
			line(g, UDim2.fromScale(0.45, y), UDim2.new(0.8, 0, 0, 4), 0, color)
			line(g, UDim2.fromScale(0.88, y), UDim2.fromOffset(7, 7), 45, color)
		end
	elseif kind == "Misil" then
		line(g, c, UDim2.new(0.85, 0, 0, 5), -45, color)
		line(g, UDim2.fromScale(0.8, 0.2), UDim2.fromOffset(12, 12), 45, color)
		line(g, UDim2.fromScale(0.22, 0.78), UDim2.new(0.3, 0, 0, 3), 45, K.Boost):SetAttribute("Accent", true)
	elseif kind == "Laser" then
		line(g, c, UDim2.new(1, 0, 0, 2), -45, color)
		ring(g, UDim2.fromScale(0.4, 0.4), color, 2).Position = UDim2.fromScale(0.78, 0.22)
	elseif kind == "Escudo" then
		local f = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = c, Size = UDim2.fromScale(0.7, 0.85), BackgroundTransparency = 1, Parent = g })
		create("UICorner", { CornerRadius = UDim.new(0.45, 0), Parent = f })
		create("UIStroke", { Color = color, Thickness = 3, Parent = f })
	elseif kind == "Camuflaje" then
		for i = 0, 5 do
			local a = i / 6 * math.pi * 2
			create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5 + math.cos(a) * 0.38, 0.5 + math.sin(a) * 0.38), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = color, BorderSizePixel = 0, Parent = g }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		end
	elseif kind == "Salto" then
		ring(g, UDim2.fromScale(0.95, 0.95), color, 2.5)
		ring(g, UDim2.fromScale(0.55, 0.55), color, 2, 0.2)
		create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = c, Size = UDim2.fromOffset(6, 6), BackgroundColor3 = color, BorderSizePixel = 0, Parent = g }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	elseif kind == "Hiper" then
		for i, x in { 0.2, 0.5, 0.8 } do
			for _, d in { { 0.35, 40 }, { 0.65, -40 } } do
				local f = line(g, UDim2.fromScale(x, d[1]), UDim2.new(0.34, 0, 0, 4), d[2], if i == 3 then K.Boost else color)
				if i == 3 then
					f:SetAttribute("Accent", true)
				end
			end
		end
	elseif kind == "Flaps" then
		-- (aviones) ala y el flap bajado detrás
		line(g, UDim2.fromScale(0.42, 0.4), UDim2.new(0.7, 0, 0, 5), -6, color)
		line(g, UDim2.fromScale(0.84, 0.56), UDim2.new(0.3, 0, 0, 4), 38, K.Boost):SetAttribute("Accent", true)
	elseif kind == "Tren" then
		-- pata y rueda
		line(g, UDim2.fromScale(0.5, 0.3), UDim2.new(0, 4, 0.5, 0), 0, color)
		line(g, UDim2.fromScale(0.5, 0.08), UDim2.new(0.7, 0, 0, 4), 0, color)
		ring(g, UDim2.fromScale(0.42, 0.42), color, 3).Position = UDim2.fromScale(0.5, 0.74)
	elseif kind == "Frenos" then
		-- disco con las pinzas
		ring(g, UDim2.fromScale(0.85, 0.85), color, 3)
		line(g, UDim2.fromScale(0.36, 0.5), UDim2.new(0, 5, 0.4, 0), 0, K.Boost):SetAttribute("Accent", true)
		line(g, UDim2.fromScale(0.64, 0.5), UDim2.new(0, 5, 0.4, 0), 0, K.Boost):SetAttribute("Accent", true)
	elseif kind == "Camara" then
		local body = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.56), Size = UDim2.fromScale(0.9, 0.62), BackgroundTransparency = 1, Parent = g }, { create("UICorner", { CornerRadius = UDim.new(0.2, 0) }), create("UIStroke", { Color = color, Thickness = 2.5 }) })
		ring(body, UDim2.fromScale(0.42, 0.62), color, 2.5)
		line(g, UDim2.fromScale(0.35, 0.18), UDim2.new(0.26, 0, 0, 4), 0, color)
	elseif kind == "Palanca" then
		-- la palanca y la flecha hacia abajo (tirar = subir)
		ring(g, UDim2.fromScale(0.36, 0.36), color, 3).Position = UDim2.fromScale(0.36, 0.2)
		line(g, UDim2.fromScale(0.36, 0.56), UDim2.new(0, 4, 0.42, 0), 0, color)
		line(g, UDim2.fromScale(0.36, 0.86), UDim2.new(0.5, 0, 0, 4), 0, color)
		line(g, UDim2.fromScale(0.8, 0.45), UDim2.new(0, 4, 0.5, 0), 0, K.Boost):SetAttribute("Accent", true)
		line(g, UDim2.fromScale(0.73, 0.66), UDim2.fromOffset(4, 12), -40, K.Boost):SetAttribute("Accent", true)
		line(g, UDim2.fromScale(0.87, 0.66), UDim2.fromOffset(4, 12), 40, K.Boost):SetAttribute("Accent", true)
	elseif kind == "MotorMax" or kind == "Motor0" then
		-- la palanca de gas: arriba del todo (a tope) o abajo (ralentí)
		line(g, UDim2.fromScale(0.5, 0.5), UDim2.new(0, 4, 0.9, 0), 0, color)
		line(g, UDim2.fromScale(0.5, if kind == "MotorMax" then 0.12 else 0.88), UDim2.new(0.6, 0, 0, 8), 0, K.Boost):SetAttribute("Accent", true)
	elseif kind == "Bajarse" then
		-- puerta y flecha hacia fuera
		create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.32, 0.5), Size = UDim2.fromScale(0.42, 0.9), BackgroundTransparency = 1, Parent = g }, { create("UIStroke", { Color = color, Thickness = 2.5 }) })
		line(g, UDim2.fromScale(0.7, 0.5), UDim2.new(0.5, 0, 0, 4), 0, color)
		line(g, UDim2.fromScale(0.88, 0.4), UDim2.fromOffset(4, 12), -45, color)
		line(g, UDim2.fromScale(0.88, 0.6), UDim2.fromOffset(4, 12), 45, color)
	elseif kind == "Acro" then
		-- (aviones) espiral: el modo acrobático
		ring(g, UDim2.fromScale(0.9, 0.9), color, 2.5)
		ring(g, UDim2.fromScale(0.5, 0.5), K.Boost, 2.5):SetAttribute("Accent", true)
		line(g, UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(6, 6), 45, color)
	elseif kind == "Looping" then
		-- un aro vertical con la flecha arriba
		ring(g, UDim2.fromScale(0.8, 0.8), color, 3).Position = UDim2.fromScale(0.5, 0.45)
		line(g, UDim2.fromScale(0.5, 0.92), UDim2.new(0.8, 0, 0, 4), 0, color)
		line(g, UDim2.fromScale(0.68, 0.1), UDim2.fromOffset(4, 12), -55, K.Boost):SetAttribute("Accent", true)
	elseif kind == "Tonel" then
		-- el avión de frente y un arco que lo rodea
		line(g, UDim2.fromScale(0.5, 0.5), UDim2.new(0.9, 0, 0, 4), -20, color)
		line(g, UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(8, 8), 0, color)
		ring(g, UDim2.fromScale(1, 1), K.Boost, 2, 0.35):SetAttribute("Accent", true)
	elseif kind == "Dron" then
		create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = c, Size = UDim2.fromScale(0.32, 0.32), BackgroundTransparency = 1, Parent = g }, { create("UIStroke", { Color = color, Thickness = 2.5 }) })
		for _, d in { { 0.15, 0.15 }, { 0.85, 0.15 }, { 0.15, 0.85 }, { 0.85, 0.85 } } do
			ring(g, UDim2.fromScale(0.26, 0.26), color, 2).Position = UDim2.fromScale(d[1], d[2])
		end
	end
	return g
end

---------------------------------------------------------------------
-- Construir
---------------------------------------------------------------------
-- Rayitas de un arco (velocidad, escudo, estructura) en un cuadrado del alto del marco
local function arcTicks(parent: Instance, name: string, n: number, from: number, to: number, radius: number, color: Color3, right: boolean): { Frame }
	local square = create("Frame", { Name = name, AnchorPoint = Vector2.new(if right then 1 else 0, 0), Position = UDim2.fromScale(if right then 1 else 0, 0), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = parent })
	create("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height, Parent = square })
	local ticks = {}
	for i, t in ShipHudLayout.arc(n, from, to, radius) do
		ticks[i] = create("Frame", { Name = "Raya" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(t.X, t.Y), Size = UDim2.fromOffset(4, 13), Rotation = t.Rot, BackgroundColor3 = color, BackgroundTransparency = 0.8, BorderSizePixel = 0, Parent = square })
	end
	return ticks
end

-- (con sprites) Los arcos con brillo: la base (segmentos apagados y la escala) y una capa por indicador
-- (un atlas de 21 estados; se tiñe con su color). Van en un marco de 1:2 pegado al lado de la mira.
local function arcArt(view: View, parent: Instance, right: boolean, layers: { { string } }): boolean
	local base = HudArt.id(if right then "arco_base_der" else "arco_base_izq")
	if not base then
		return false
	end
	local holder = create("Frame", { Name = if right then "ArcosDer" else "ArcosIzq", AnchorPoint = Vector2.new(if right then 1 else 0, 0.5), Position = UDim2.fromScale(if right then 1 else 0, 0.5), Size = UDim2.fromScale(1, 1.08), BackgroundTransparency = 1, ZIndex = 0, Parent = parent })
	create("UIAspectRatioConstraint", { AspectRatio = HudArt.Arc.FrameW / HudArt.Arc.FrameH, DominantAxis = Enum.DominantAxis.Height, Parent = holder })
	HudArt.arc(holder, if right then "arco_base_der" else "arco_base_izq", { Name = "Base", ZIndex = 0 })
	for _, l in layers do
		local img = HudArt.arc(holder, l[2], { Name = l[1], ZIndex = 1 })
		if img then
			view.Art["Arc" .. l[1]] = img
		end
	end
	return true
end

-- Un hueco de la HUD sin caja (los arcos van «en el aire», como la referencia)
local function bare(name: string, parent: Instance): Frame
	return create("Frame", { Name = name, BackgroundTransparency = 1, Parent = parent })
end

local function keyChip(parent: Instance, text: string, props: { [string]: any }?): TextLabel
	local p = { Name = "Tecla", Size = UDim2.fromOffset(56, 20), BackgroundColor3 = rgb(20, 40, 70), BackgroundTransparency = 0.15, Text = text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center, Parent = parent }
	for k, v in props or {} do
		p[k] = v
	end
	local chip = label(p)
	create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = chip })
	create("UIStroke", { Color = K.Edge, Thickness = 1, Transparency = 0.35, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = chip })
	return chip
end

-- La nave en planta (para el esquema de abajo a la izquierda y los atajos): marcos, sin imágenes
local function silhouette(parent: Instance, size: UDim2, pos: UDim2, color: Color3): Frame
	local g = create("Frame", { Name = "Silueta", AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = size, BackgroundTransparency = 1, Parent = parent })
	line(g, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.1, 0.9), 0, color)
	line(g, UDim2.fromScale(0.3, 0.62), UDim2.fromScale(0.06, 0.62), -20, color)
	line(g, UDim2.fromScale(0.7, 0.62), UDim2.fromScale(0.06, 0.62), 20, color)
	line(g, UDim2.fromScale(0.5, 0.66), UDim2.fromScale(0.9, 0.05), 0, color)
	line(g, UDim2.fromScale(0.5, 0.9), UDim2.fromScale(0.42, 0.04), 0, color)
	create("Frame", { Name = "Cabina", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromScale(0.12, 0.14), BackgroundColor3 = K.Cyan, BorderSizePixel = 0, Parent = g }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	return g
end

local function buildProfile(view: View, parent: Frame)
	local p = view.Profile
	local touch = view.Touch
	local W = parent.Size.X.Offset
	-- (cuadrado del alto del panel: con ancho 0 la restricción de aspecto lo dejaba en 0 x 0 y solo se veía
	-- un puntito, captura del dueño en la avioneta)
	local avatar = create("ImageLabel", { Name = "Avatar", Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 1, -24), BackgroundColor3 = rgb(10, 30, 60), Image = "", ScaleType = Enum.ScaleType.Crop, Parent = parent })
	create("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height, Parent = avatar })
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = avatar })
	local avatarStroke = create("UIStroke", { Color = K.Cyan, Thickness = 2.5, Parent = avatar })
	p.Avatar = avatar
	-- (con sprites: aro con brillo alrededor del retrato y la insignia de rango debajo)
	local ringArt = HudArt.image(avatar, "aro_avatar", { Name = "Aro", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.2, 1.2), ZIndex = 2 })
	if ringArt then
		avatarStroke.Enabled = false
		view.Art.AvatarRing = ringArt
		view.Art.Rank = HudArt.icon(avatar, "rango", { Name = "Rango", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 1.02), Size = UDim2.fromScale(0.36, 0.36), ZIndex = 3 })
	end
	local x = if touch then 104 else 120
	-- Fila 1: «Nv. 12» · nombre · dinero. El dinero y el nivel encogen su letra para caber (nunca se
	-- montan: la captura del avión tenía «Nv. 100Sib..10.000.014 €»)
	local moneyW = if touch then 132 else 168
	p.Level = label({ Name = "Nivel", Position = UDim2.fromOffset(x, 6), Size = UDim2.fromOffset(66, 26), Text = "Nv. 1", TextSize = 20, TextScaled = true, TextColor3 = K.Cyan, Parent = parent })
	create("UITextSizeConstraint", { MaxTextSize = 20, MinTextSize = 10, Parent = p.Level })
	p.Name = label({ Name = "Nombre", Position = UDim2.fromOffset(x + 70, 6), Size = UDim2.fromOffset(math.max(40, W - (x + 70) - moneyW - 18), 26), Text = "", TextSize = 20, TextTruncate = Enum.TextTruncate.AtEnd, Parent = parent })
	p.Money = label({ Name = "Dinero", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 6), Size = UDim2.fromOffset(moneyW, 26), Text = "$0", TextSize = 19, TextScaled = true, TextColor3 = rgb(120, 240, 140), TextXAlignment = Enum.TextXAlignment.Right, Parent = parent })
	create("UITextSizeConstraint", { MaxTextSize = 19, MinTextSize = 9, Parent = p.Money })
	local coin = HudArt.icon(p.Money, "moneda", { Name = "Moneda", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(22, 22) })
	if coin then
		create("UIPadding", { PaddingLeft = UDim.new(0, 26), Parent = p.Money })
		view.Art.Coin = coin
	end
	-- Barras pequeñas: casco (rojo), escudo (azul), energía (amarilla)
	local barW = if touch then 150 else 180
	local by = if touch then 38 else 42
	local step = if touch then 13 else 15
	p.BarRows = {}
	for i, def in { { "MiniHull", "♥", rgb(255, 80, 80), "corazon" }, { "MiniShield", "◈", K.Shield, "escudo" }, { "MiniEnergy", "⚡", rgb(230, 230, 80), "energia" } } do
		local y = by + (i - 1) * step
		local icon = label({ Name = def[1] .. "Icono", Position = UDim2.fromOffset(x, y - 3), Size = UDim2.fromOffset(14, 14), Text = def[2], TextSize = 12, TextColor3 = def[3], Parent = parent })
		if HudArt.icon(icon, def[4], { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.15, 1.15) }) then
			icon.TextTransparency = 1
		end
		view.Bars[def[1]] = bar(parent, def[1], def[3], UDim2.fromOffset(x + 16, y), UDim2.fromOffset(barW, 7))
		p.BarRows[def[1]] = icon
	end
	-- Los 3 recursos (Chispas, mineral en la bodega, cristales), cada uno con su icono
	local ry = if touch then 78 else 90
	local rw = math.floor((W - x - 12) / 3)
	p.Res = {}
	p.ResIcons = {}
	for i, def in { { "Chispas", "✨ 0", K.Gold, "chispas" }, { "Bodega", "⛏ 0", rgb(200, 210, 225), "mineral" }, { "Cristales", "💎 0", rgb(150, 210, 255), "cristal" } } do
		local chip = label({ Name = def[1], Position = UDim2.fromOffset(x + (i - 1) * rw, ry), Size = UDim2.fromOffset(rw - 6, 24), BackgroundColor3 = rgb(10, 26, 50), BackgroundTransparency = 0.25, Text = def[2], TextSize = 16, TextScaled = true, TextColor3 = def[3], TextXAlignment = Enum.TextXAlignment.Center, Parent = parent })
		create("UITextSizeConstraint", { MaxTextSize = 16, MinTextSize = 9, Parent = chip })
		create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = chip })
		create("UIStroke", { Color = K.Edge, Thickness = 1, Transparency = 0.55, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = chip })
		local icon = HudArt.icon(chip, def[4], { Name = "Icono", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(24, 24) })
		if icon then
			create("UIPadding", { PaddingLeft = UDim.new(0, 28), PaddingRight = UDim.new(0, 4), Parent = chip })
			p.ResIcons[i] = icon
		end
		p.Res[i] = chip
	end
	p.Chispas = p.Res[1]
	-- La nave y su modo (ordenador) o el reloj (móvil), a la derecha de las barras
	p.Ship = label({ Name = "Nave", Position = UDim2.fromOffset(x + barW + 26, by - 4), Size = UDim2.new(1, -(x + barW + 38), 0, 18), Text = "CAZA · COMBATE", TextSize = 13, TextColor3 = K.Muted, TextTruncate = Enum.TextTruncate.AtEnd, Visible = not touch, Parent = parent })
	if touch then
		view.Clock = label({ Name = "Reloj", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, by - 2), Size = UDim2.fromOffset(math.max(40, W - (x + 16 + barW) - 20), 20), Text = "--:--", TextSize = 15, TextColor3 = K.Muted, TextXAlignment = Enum.TextXAlignment.Right, Parent = parent })
	end
end

local function buildNav(view: View, parent: Frame)
	local n = view.Nav
	local strip = create("Frame", { Name = "Brujula", Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -20, 0, 34), BackgroundTransparency = 1, ClipsDescendants = true, Parent = parent })
	create("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0), NumberSequenceKeypoint.new(0.85, 0), NumberSequenceKeypoint.new(1, 1) }), Parent = strip })
	line(strip, UDim2.new(0.5, 0, 1, -2), UDim2.new(1, 0, 0, 1), 0, K.Edge)
	n.Strip = strip
	-- (con sprites: la cinta con rayitas que brillan; se mueve con el rumbo cambiando la ventana)
	local C = HudArt.Compass
	local tape = HudArt.image(strip, "brujula_cinta", { Name = "Cinta", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 24), ImageRectSize = Vector2.new(C.Window * C.PxPerDeg, C.H), ZIndex = 0 })
	n.Tape = tape
	n.Marks = {}
	for i = 1, 12 do
		local m = label({ Name = "Marca" .. i, AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(40, 30), Text = "", TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center, Visible = false, Parent = strip })
		local tick = create("Frame", { Name = "Raya", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.fromOffset(2, 8), BackgroundColor3 = K.Cyan, BorderSizePixel = 0, Visible = tape == nil, Parent = m })
		if tape then
			m.Size = UDim2.fromOffset(40, 20)
			create("UIStroke", { Color = K.Edge, Thickness = 1, Transparency = 0.6, Parent = m })
		end
		n.Marks[i] = { Label = m, Tick = tick }
	end
	-- Marca del destino (rombo dorado) y otras marcas (misión, objetivo) en la tira
	n.Target = create("Frame", { Name = "Destino", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 14), Rotation = 45, BackgroundColor3 = K.Gold, BorderSizePixel = 0, Visible = false, Parent = strip })
	if HudArt.icon(n.Target, "rombo", { Rotation = -45, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.7, 1.7) }) then
		n.Target.BackgroundTransparency = 1
	end
	n.Extra = {}
	for i = 1, 3 do
		n.Extra[i] = create("Frame", { Name = "Marca" .. i .. "Extra", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromOffset(10, 10), Rotation = 45, BackgroundColor3 = K.Hostile, BorderSizePixel = 0, Visible = false, Parent = strip })
	end
	line(parent, UDim2.new(0.5, 0, 0, 40), UDim2.fromOffset(3, 12), 0, K.White)
	n.Heading = label({ Name = "Rumbo", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 40), Size = UDim2.fromOffset(60, 14), Text = "000°", TextSize = 12, TextColor3 = K.Muted, TextXAlignment = Enum.TextXAlignment.Center, Visible = false, Parent = parent })
	-- «Sistema Valmar» / zona o planeta / distancia al destino (como la referencia)
	n.System = label({ Name = "Sistema", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 44), Size = UDim2.new(1, -20, 0, 26), Text = "◆ Sistema Valmar", TextSize = 22, TextColor3 = K.Cyan, TextXAlignment = Enum.TextXAlignment.Center, Parent = parent })
	n.Zone = label({ Name = "Zona", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 70), Size = UDim2.new(1, -24, 0, 20), Text = "", TextSize = 16, TextColor3 = K.White, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, Parent = parent })
	n.Dest = label({ Name = "Destino", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 90), Size = UDim2.new(1, -24, 0, 18), Text = "", TextSize = 14, TextColor3 = K.Gold, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, Parent = parent })
	-- (el estado del salto va en su panel, Jump; esta etiqueta se queda por compatibilidad)
	n.Quantum = label({ Name = "Salto", Size = UDim2.fromOffset(0, 0), Text = "", Visible = false, Parent = parent })
end

-- Izquierda de la mira: arco de velocidad, KM/H, VELOCIDAD, impulso y el modo (se toca)
local function buildSpeed(view: View, parent: Frame)
	local values, bars = view.Values, view.Bars
	local touch = view.Touch
	-- Esfera redonda detrás del número (el «reloj» de velocidad de la referencia): centrada donde el arco
	do
		local H = parent.Size.Y.Offset
		local r = math.floor(H * 0.4)
		local dial = create("Frame", { Name = "Esfera", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(math.floor(H * 0.616), math.floor(H / 2)), Size = UDim2.fromOffset(r * 2, r * 2), BackgroundColor3 = rgb(6, 20, 42), BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = 0, Parent = parent })
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dial })
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(40, 100, 160), rgb(4, 12, 28)), Parent = dial })
		create("UIStroke", { Color = K.Edge, Thickness = 1.5, Transparency = 0.55, Parent = dial })
	end
	view.Arcs.Speed = arcTicks(parent, "ArcoVelocidad", if touch then 18 else 22, 110, 250, 0.46, K.Cyan, false)
	-- (con sprites: arco grueso de velocidad e impulso/motor por dentro, en vez de las rayitas)
	if arcArt(view, parent, false, { { "Speed", "arco_grueso_izq" }, { "Boost", "arco_fino_izq" } }) then
		for _, t in view.Arcs.Speed do
			t.Visible = false
		end
	end
	values.Speed = label({ Name = "Velocidad", Position = UDim2.fromScale(0.3, 0.2), Size = UDim2.fromScale(0.7, 0.22), Text = "0", TextSize = if touch then 30 else 40, TextXAlignment = Enum.TextXAlignment.Center, Parent = parent })
	create("UIStroke", { Name = "Brillo", Color = K.Edge, Thickness = 1.5, Transparency = 0.55, Parent = values.Speed })
	label({ Name = "KmH", Position = UDim2.fromScale(0.3, 0.42), Size = UDim2.fromScale(0.7, 0.09), Text = "KM/H", TextSize = 13, TextColor3 = K.White, TextXAlignment = Enum.TextXAlignment.Center, Parent = parent })
	label({ Name = "Rotulo", Position = UDim2.fromScale(0.3, 0.51), Size = UDim2.fromScale(0.7, 0.08), Text = "VELOCIDAD", TextSize = 11, TextColor3 = K.Muted, TextXAlignment = Enum.TextXAlignment.Center, Parent = parent })
	label({ Name = "BoostCaption", Position = UDim2.fromScale(0.34, 0.62), Size = UDim2.fromScale(0.36, 0.08), Text = "IMPULSO", TextSize = 11, TextColor3 = K.Boost, Parent = parent })
	values.Boost = label({ Name = "Boost", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.96, 0.62), Size = UDim2.fromScale(0.3, 0.08), Text = "", TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, Parent = parent })
	bars.Boost = bar(parent, "Boost", K.Boost, UDim2.fromScale(0.34, 0.71), UDim2.new(0.62, 0, 0, 6))
	-- (el modo se toca: combate → crucero → exploración; en el móvil no hay tecla T)
	local modeButton = create("TextButton", { Name = "Modo", Position = UDim2.fromScale(0.34, 0.8), Size = UDim2.fromScale(0.64, 0.14), BackgroundColor3 = rgb(12, 34, 60), BackgroundTransparency = 0.2, AutoButtonColor = true, Text = "COMBATE", TextSize = 12, Font = Theme.FontBold, TextColor3 = K.Cyan, TextScaled = false, Parent = parent })
	create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = modeButton })
	create("UIStroke", { Color = K.Edge, Thickness = 1, Transparency = 0.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = modeButton })
	onActivated(modeButton, function()
		if view.OnSlot then
			view.OnSlot("Mode")
		end
	end)
	view.Chips.Mode = modeButton :: any
	-- (móvil) todo el hueco de la velocidad cambia el modo: el chip solo sería un blanco diminuto
	if touch then
		local hit = create("TextButton", { Name = "TocarModo", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5, Parent = parent })
		onActivated(hit, function()
			if view.OnSlot then
				view.OnSlot("Mode")
			end
		end)
	end
	view.Panel = parent
end

-- Derecha de la mira: arcos y barras de ESCUDO y ESTRUCTURA (en %)
local function buildDefense(view: View, parent: Frame)
	local values, bars = view.Values, view.Bars
	local touch = view.Touch
	view.Arcs.Shield = arcTicks(parent, "ArcoEscudo", if touch then 16 else 20, 70, -70, 0.46, K.Shield, true)
	view.Arcs.Hull = arcTicks(parent, "ArcoCasco", if touch then 14 else 18, 64, -64, 0.38, K.Hull, true)
	-- (con sprites: escudo por fuera y estructura por dentro, dos arcos concéntricos con brillo)
	if arcArt(view, parent, true, { { "Shield", "arco_grueso_der" }, { "Hull", "arco_medio_der" } }) then
		for _, list in { view.Arcs.Shield, view.Arcs.Hull } do
			for _, t in list do
				t.Visible = false
			end
		end
	end
	local sh = create("Frame", { Name = "FilaEscudo", Size = UDim2.fromScale(0.78, 0.46), BackgroundTransparency = 1, Parent = parent })
	label({ Name = "Caption", Position = UDim2.fromScale(0.06, 0.08), Size = UDim2.fromScale(0.9, 0.24), Text = "ESCUDO", TextSize = 14, TextColor3 = K.Cyan, Parent = sh })
	values.Shield = label({ Name = "Shield", Position = UDim2.fromScale(0.06, 0.36), Size = UDim2.fromScale(0.9, 0.3), Text = "", TextSize = if touch then 16 else 18, Parent = sh })
	if HudArt.icon(sh, "escudo", { Name = "Icono", Position = UDim2.fromScale(0.04, 0.33), Size = UDim2.fromOffset(26, 26) }) then
		values.Shield.Position = UDim2.new(0.06, 30, 0.36, 0)
	end
	bars.Shield = bar(sh, "Shield", K.Shield, UDim2.fromScale(0.06, 0.74), UDim2.new(0.7, 0, 0, 7))
	local hu = create("Frame", { Name = "FilaCasco", Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromScale(0.78, 0.46), BackgroundTransparency = 1, Parent = parent })
	label({ Name = "Caption", Position = UDim2.fromScale(0.06, 0.08), Size = UDim2.fromScale(0.9, 0.24), Text = "ESTRUCTURA", TextSize = 13, TextColor3 = K.White, Parent = hu })
	values.Hull = label({ Name = "Hull", Position = UDim2.fromScale(0.06, 0.36), Size = UDim2.fromScale(0.9, 0.3), Text = "", TextSize = if touch then 16 else 18, Parent = hu })
	if HudArt.icon(hu, "estructura", { Name = "Icono", Position = UDim2.fromScale(0.04, 0.33), Size = UDim2.fromOffset(26, 26) }) then
		values.Hull.Position = UDim2.new(0.06, 30, 0.36, 0)
	end
	bars.Hull = bar(hu, "Hull", K.Hull, UDim2.fromScale(0.06, 0.74), UDim2.new(0.7, 0, 0, 7))
	view.ShieldRows = { sh }
end

local function buildMissions(view: View, parent: Frame)
	local rows = view.Missions
	local h = parent.Size.Y.Offset
	local n = 3 -- PRINCIPAL, SECUNDARIA y EVENTO GLOBAL
	local rowH = math.floor((h - 8 - (if view.Touch then 0 else 16)) / n)
	for i = 1, n do
		local row = create("Frame", { Name = "Fila" .. i, Position = UDim2.fromOffset(0, 4 + (i - 1) * rowH), Size = UDim2.new(1, 0, 0, rowH), BackgroundTransparency = 1, Visible = false, Parent = parent })
		local dot = create("Frame", { Name = "Marca", Position = UDim2.fromOffset(12, 8), Size = UDim2.fromOffset(10, 10), Rotation = 45, BackgroundColor3 = K.Gold, BorderSizePixel = 0, Parent = row })
		-- (con sprites: emblema de la principal, rombo dorado de la secundaria y rojo del evento, sobre
		-- una tira de cabecera)
		local icon = HudArt.icon(row, "emblema", { Name = "Emblema", Position = UDim2.fromOffset(4, -1), Size = UDim2.fromOffset(24, 24), ZIndex = 2 })
		if icon then
			dot.Visible = false
			HudArt.header(row, { Position = UDim2.fromOffset(2, 1), Size = UDim2.new(0.7, 0, 0, 20) })
		end
		local kind = label({ Name = "Tipo", Position = UDim2.fromOffset(30, 2), Size = UDim2.new(1, -40, 0, 18), Text = "", TextSize = 13, TextColor3 = K.Gold, Parent = row })
		local title = label({ Name = "Titulo", Position = UDim2.fromOffset(30, 19), Size = UDim2.new(1, -110, 0, 20), Text = "", TextSize = 16, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row })
		local right = label({ Name = "Dato", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 19), Size = UDim2.fromOffset(78, 20), Text = "", TextSize = 14, TextColor3 = K.Muted, TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
		local stepLabel = label({ Name = "Paso", Position = UDim2.fromOffset(30, 38), Size = UDim2.new(1, -40, 0, 16), Text = "", TextSize = 13, TextColor3 = K.Muted, TextTruncate = Enum.TextTruncate.AtEnd, Visible = rowH >= 54, Parent = row })
		rows[i] = { Row = row, Dot = dot, Kind = kind, Title = title, Right = right, Step = stepLabel, Icon = icon }
	end
end

-- SALTO CUÁNTICO: destino, distancia, coste y la tecla (en el móvil se toca)
local function buildJump(view: View, parent: Frame)
	local J = view.Jump
	-- (con sprites: el vórtice del salto, como el portal de la referencia)
	local vortex = HudArt.image(parent, "vortice", { Name = "Vortice", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.82, 0.5), Size = UDim2.fromScale(1.15, 1.15), SizeConstraint = Enum.SizeConstraint.RelativeYY, ZIndex = 0 })
	if vortex then
		view.Art.Vortex = vortex
	else
		for i, k in { 0.9, 0.62, 0.34 } do
			local r = ring(parent, UDim2.fromScale(k * 0.5, k), K.Violet, 2, 0.3 + i * 0.15)
			r.Position = UDim2.fromScale(0.8, 0.5)
			create("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height, Parent = r })
		end
	end
	J.Title = label({ Name = "Titulo", Position = UDim2.fromOffset(14, 6), Size = UDim2.new(1, -28, 0, 22), Text = "SALTO CUÁNTICO", TextSize = 18, TextColor3 = K.Violet, Parent = parent })
	J.Dest = label({ Name = "Destino", Position = UDim2.fromOffset(14, 30), Size = UDim2.new(0.75, -14, 0, 20), Text = "Destino: —", TextSize = 15, TextTruncate = Enum.TextTruncate.AtEnd, Parent = parent })
	J.Info = label({ Name = "Info", Position = UDim2.fromOffset(14, 50), Size = UDim2.new(0.75, -14, 0, 18), Text = "", TextSize = 13, TextColor3 = K.Muted, TextTruncate = Enum.TextTruncate.AtEnd, Parent = parent })
	J.Key = keyChip(parent, "X", { Name = "Tecla", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -8), Size = UDim2.fromOffset(if view.Touch then 0 else 28, 22) })
	J.Key.Visible = not view.Touch
	J.Action = label({ Name = "Accion", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, if view.Touch then 14 else 50, 1, -8), Size = UDim2.new(0.8, -50, 0, 22), Text = if view.Touch then "Toca para elegir destino" else "Activar", TextSize = 14, TextColor3 = K.White, Parent = parent })
	local hit = create("TextButton", { Name = "Tocar", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5, Parent = parent })
	onActivated(hit, function()
		if view.OnSlot then
			view.OnSlot("Quantum")
		end
	end)
end

-- OBJETIVO: nombre, nivel, distancia y salud del blanco elegido o fijado
local function buildTarget(view: View, parent: Frame)
	local T = view.TargetCard
	local title = label({ Name = "Titulo", Position = UDim2.fromOffset(14, 4), Size = UDim2.new(1, -28, 0, 18), Text = "⚠ OBJETIVO", TextSize = 13, TextColor3 = K.Gold, Parent = parent })
	T.Dot = create("Frame", { Name = "Rombo", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(26, 44), Size = UDim2.fromOffset(16, 16), Rotation = 45, BackgroundColor3 = K.Hostile, BorderSizePixel = 0, Parent = parent })
	-- (con sprites: aviso dorado en la cabecera y el rombo rojo con brillo)
	if HudArt.icon(parent, "aviso", { Name = "Aviso", Position = UDim2.fromOffset(10, 3), Size = UDim2.fromOffset(18, 18) }) then
		HudArt.header(parent, { Position = UDim2.fromOffset(6, 3), Size = UDim2.new(0.75, 0, 0, 20) })
		title.Position = UDim2.fromOffset(32, 4)
		title:SetAttribute("Plain", true)
		title.Text = "OBJETIVO"
		T.Dot.BackgroundTransparency = 1
		HudArt.icon(T.Dot, "rombo_rojo", { Rotation = -45, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.9, 1.9) })
	end
	T.Name = label({ Name = "Nombre", Position = UDim2.fromOffset(44, 24), Size = UDim2.new(1, -130, 0, 20), Text = "", TextSize = 15, TextTruncate = Enum.TextTruncate.AtEnd, Parent = parent })
	T.Level = label({ Name = "Nivel", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 24), Size = UDim2.fromOffset(80, 20), Text = "", TextSize = 13, TextColor3 = K.Muted, TextXAlignment = Enum.TextXAlignment.Right, Parent = parent })
	T.Dist = label({ Name = "Distancia", Position = UDim2.fromOffset(44, 44), Size = UDim2.new(1, -56, 0, 18), Text = "", TextSize = 14, TextColor3 = K.White, Parent = parent })
	T.Bar = bar(parent, "Salud", K.Hostile, UDim2.new(0, 44, 1, -16), UDim2.new(1, -60, 0, 7))
	T.Empty = label({ Name = "Vacio", Position = UDim2.fromOffset(14, 26), Size = UDim2.new(1, -28, 0, 40), Text = if view.Touch then "Sin objetivo · toca OBJETIVO" else "Sin objetivo · Tab para elegir", TextSize = 14, TextColor3 = K.Muted, TextWrapped = true, Parent = parent })
	local hit = create("TextButton", { Name = "Tocar", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5, Parent = parent })
	onActivated(hit, function()
		if view.OnSlot then
			view.OnSlot("TargetNext")
		end
	end)
end

-- Una de las dos listas de teclas del ordenador (se pliegan con H)
local function buildKeyList(view: View, parent: Frame, title: string): Frame
	local t = label({ Name = "Titulo", Position = UDim2.fromOffset(12, 5), Size = UDim2.new(1, -24, 0, 20), Text = title, TextSize = 14, TextColor3 = K.Cyan, Parent = parent })
	HudArt.header(parent, { Position = UDim2.fromOffset(4, 4), Size = UDim2.new(0.8, 0, 0, 22) })
	view.HintTitles[parent.Name] = t
	local list = create("Frame", { Name = "Lista", Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -24, 1, -32), BackgroundTransparency = 1, Parent = parent })
	create("UIListLayout", { Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	return list
end

-- La nave en planta (abajo a la izquierda): escudo, casco y energía en %, misiles, bengalas y el arma
local function buildShip(view: View, parent: Frame)
	local values, bars = view.Values, view.Bars
	-- (con sprites: aro con brillo y la silueta de la nave/avión vista desde arriba)
	local ringArt = HudArt.image(parent, "aro_widget", { Name = "AroArte", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(85, 90), Size = UDim2.fromOffset(168, 168), ImageColor3 = rgb(150, 225, 255), ZIndex = 0 })
	if not ringArt then
		ring(parent, UDim2.fromOffset(150, 150), K.Edge, 2, 0.3).Position = UDim2.fromOffset(85, 90)
		ring(parent, UDim2.fromOffset(120, 120), K.Cyan, 1, 0.7).Position = UDim2.fromOffset(85, 90)
	end
	view.Silhouette = silhouette(parent, UDim2.fromOffset(84, 110), UDim2.fromOffset(85, 90), rgb(170, 200, 230))
	local shipArt = HudArt.image(parent, "silueta_nave", { Name = "SiluetaArte", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(85, 90), Size = UDim2.fromOffset(104, 130), ZIndex = 1 })
	if shipArt then
		view.Silhouette.Visible = false
		view.Art.ShipSilhouettes = view.Art.ShipSilhouettes or {}
		table.insert(view.Art.ShipSilhouettes, shipArt)
	end
	local x = 172
	local rows = { { "ShipShield", "◈", K.Shield, 10, "escudo" }, { "ShipHull", "⬢", K.Hull, 36, "estructura" }, { "Energy", "⚡", rgb(230, 230, 80), 62, "energia" } }
	for _, def in rows do
		local icon = label({ Name = def[1] .. "Icono", Position = UDim2.fromOffset(x, def[4]), Size = UDim2.fromOffset(22, 22), Text = def[2], TextSize = 18, TextColor3 = def[3], Parent = parent })
		local art = HudArt.icon(icon, def[5], { Name = "Arte", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.25, 1.25) })
		if art then
			icon.TextTransparency = 1
			view.Art["RowIcon" .. def[1]] = art
		end
		values[def[1]] = label({ Name = def[1], Position = UDim2.fromOffset(x + 28, def[4]), Size = UDim2.fromOffset(120, 22), Text = "100%", TextSize = 18, Parent = parent })
	end
	view.ShieldRows = view.ShieldRows or {}
	bars.Energy = bar(parent, "Energy", rgb(230, 230, 80), UDim2.fromOffset(x, 88), UDim2.fromOffset(140, 6))
	label({ Name = "MisilesCaption", Position = UDim2.fromOffset(x, 102), Size = UDim2.fromOffset(70, 18), Text = "MISILES", TextSize = 12, TextColor3 = K.Boost, Parent = parent })
	values.Missiles = label({ Name = "Misiles", Position = UDim2.fromOffset(x + 70, 100), Size = UDim2.fromOffset(50, 20), Text = "6/6", TextSize = 16, Parent = parent })
	values.Flares = label({ Name = "Bengalas", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 100), Size = UDim2.fromOffset(40, 20), Text = "", TextSize = 14, TextColor3 = rgb(255, 210, 140), TextXAlignment = Enum.TextXAlignment.Right, Parent = parent })
	values.Weapon = label({ Name = "Arma", Position = UDim2.fromOffset(x, 126), Size = UDim2.fromOffset(140, 18), Text = "CAÑONES", TextSize = 13, TextColor3 = K.Cyan, Parent = parent })
	bars.Heat = bar(parent, "Heat", K.Hostile, UDim2.fromOffset(x, 150), UDim2.fromOffset(140, 6))
end

-- Atajos (abajo a la derecha): giros, esquivar, camuflaje, «Modo Combate ON/OFF» y el reloj
local function buildQuick(view: View, parent: Frame)
	local Q = view.QuickRows
	-- (con sprites: el aro verde-cian con la silueta, como la referencia)
	if HudArt.image(parent, "aro_widget", { Name = "AroArte", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(62, 72), Size = UDim2.fromOffset(116, 116), ImageColor3 = rgb(110, 240, 200), ZIndex = 0 }) then
		local art = HudArt.image(parent, "silueta_nave", { Name = "SiluetaArte", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(62, 72), Size = UDim2.fromOffset(60, 75), ZIndex = 1 })
		view.Art.ShipSilhouettes = view.Art.ShipSilhouettes or {}
		table.insert(view.Art.ShipSilhouettes, art)
	else
		ring(parent, UDim2.fromOffset(104, 104), K.Edge, 2, 0.3).Position = UDim2.fromOffset(62, 72)
		ring(parent, UDim2.fromOffset(84, 84), K.Hull, 2, 0.5).Position = UDim2.fromOffset(62, 72)
		silhouette(parent, UDim2.fromOffset(48, 64), UDim2.fromOffset(62, 72), rgb(170, 200, 230))
	end
	for i, def in { { "RollLeft", "Giro izq." }, { "RollRight", "Giro der." }, { "Dodge", "Esquivar" }, { "Cloak", "Camuflaje" } } do
		local y = 8 + (i - 1) * 30
		local clickable = def[1] == "Dodge" or def[1] == "Cloak"
		local row = create(if clickable then "TextButton" else "Frame", { Name = "Atajo" .. def[1], Position = UDim2.fromOffset(124, y), Size = UDim2.new(1, -132, 0, 26), BackgroundTransparency = 1, Parent = parent })
		if clickable then
			(row :: any).Text = ""
			onActivated(row :: any, function()
				if view.OnSlot then
					view.OnSlot(def[1])
				end
			end)
		end
		local chip = keyChip(row, ShipKeys.label(def[1], "Keyboard"), { Size = UDim2.fromOffset(26, 22), Position = UDim2.fromOffset(0, 2) })
		label({ Name = "Texto", Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -34, 1, 0), Text = def[2], TextSize = 15, Parent = row })
		Q[def[1]] = chip
	end
	label({ Name = "ModoTexto", Position = UDim2.fromOffset(12, 140), Size = UDim2.fromOffset(170, 26), Text = "▸ Modo Combate", TextSize = 14, TextColor3 = K.White, Parent = parent })
	local toggle = create("TextButton", { Name = "ModoCombate", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 140), Size = UDim2.fromOffset(64, 26), BackgroundColor3 = rgb(16, 60, 100), AutoButtonColor = true, Text = "ON", TextSize = 14, Font = Theme.FontBold, TextColor3 = K.Cyan, Parent = parent })
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = toggle })
	create("UIStroke", { Color = K.Edge, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = toggle })
	onActivated(toggle, function()
		if view.OnSlot then
			view.OnSlot("Mode")
		end
	end)
	view.Chips.Combat = toggle :: any
	view.Clock = label({ Name = "Reloj", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -40, 1, -8), Size = UDim2.fromOffset(80, 22), Text = "--:--", TextSize = 16, TextColor3 = K.White, TextXAlignment = Enum.TextXAlignment.Right, Parent = parent })
	for i = 1, 4 do
		create("Frame", { Name = "Senal" .. i, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(1, -34 + i * 5, 1, -10), Size = UDim2.fromOffset(3, 3 + i * 3), BackgroundColor3 = K.Cyan, BorderSizePixel = 0, Parent = parent })
	end
end

-- (móvil) «?»: lo que hace cada botón, en un panel que se abre y se cierra
AirCombatHud.TouchHelp = {
	{ Key = "Palanca", Text = "Dirigir la nave" }, { Key = "Arrastrar", Text = "Apuntar con el pulgar derecho" },
	{ Key = "DISPARO", Text = "Disparar el arma elegida" }, { Key = "MISIL", Text = "Lanzar un misil al blanco fijado" },
	{ Key = "IMPULSO", Text = "Acelerar (mantener)" }, { Key = "FRENO", Text = "Frenar (mantener: emergencia)" },
	{ Key = "ESQUIVA", Text = "Esquivar / rodar" }, { Key = "BENGALAS", Text = "Engañar a los misiles" },
	{ Key = "OBJETIVO", Text = "Cambiar de objetivo" }, { Key = "Ranura 6", Text = "Salto cuántico (o el panel SALTO)" },
	{ Key = "Ranura 7", Text = "Hipervelocidad" }, { Key = "Modo", Text = "Combate / crucero / exploración" },
}

local function buildHelp(view: View, button: Frame, panel: Frame)
	local b = create("TextButton", { Name = "Ayuda", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "?", TextSize = 32, Font = Theme.FontBold, TextColor3 = K.Cyan, Parent = button })
	onActivated(b, function()
		AirCombatHud.toggleHelp(view)
	end)
	panel.Visible = false
	panel.ZIndex = 9
	view.HelpTitle = label({ Name = "Titulo", Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -120, 0, 26), Text = "MANDOS DE LA NAVE", TextSize = 20, TextColor3 = K.Cyan, ZIndex = 10, Parent = panel })
	local close = create("TextButton", { Name = "Cerrar", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 6), Size = UDim2.fromOffset(92, 92), BackgroundColor3 = rgb(60, 20, 30), Text = "✕", TextSize = 22, Font = Theme.FontBold, TextColor3 = K.White, ZIndex = 10, Parent = panel })
	create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = close })
	onActivated(close, function()
		AirCombatHud.toggleHelp(view, false)
	end)
	local list = create("Frame", { Name = "Lista", Position = UDim2.fromOffset(16, 104), Size = UDim2.new(1, -32, 1, -114), BackgroundTransparency = 1, ZIndex = 10, Parent = panel })
	create("UIGridLayout", { CellSize = UDim2.new(0.5, -6, 0, 26), CellPadding = UDim2.fromOffset(12, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	view.HelpList = list
	AirCombatHud.setTouchHelp(view, nil, AirCombatHud.TouchHelp)
	view.HelpPanel = panel
end

-- (móvil) Lo que dice el panel «?»: título (nil: el de siempre) y filas { Key, Text } (los aviones
-- ponen los suyos)
function AirCombatHud.setTouchHelp(view: View, title: string?, rows: { { Key: string, Text: string } })
	if view.HelpTitle then
		view.HelpTitle.Text = title or "MANDOS DE LA NAVE"
	end
	local list = view.HelpList
	if not list then
		return
	end
	for _, c in list:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	for i, h in rows do
		local row = create("Frame", { Name = "Fila" .. i, LayoutOrder = i, BackgroundTransparency = 1, ZIndex = 10, Parent = list })
		keyChip(row, h.Key, { Size = UDim2.fromOffset(96, 22), Position = UDim2.fromOffset(0, 2), ZIndex = 10 })
		label({ Name = "Texto", Position = UDim2.fromOffset(102, 0), Size = UDim2.new(1, -102, 1, 0), Text = h.Text, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 10, Parent = row })
	end
end

local function buildSlots(view: View, parent: Frame, slot: number, gap: number)
	for i = 1, 8 do
		local b = create("TextButton", { Name = "Ranura" .. i, Position = UDim2.fromOffset(8 + (i - 1) * (slot + gap), 6), Size = UDim2.fromOffset(slot, slot), BackgroundColor3 = rgb(8, 22, 44), BackgroundTransparency = 0.15, AutoButtonColor = false, Text = "", Parent = parent })
		create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = b })
		local stroke = create("UIStroke", { Name = "Edge", Color = K.Edge, Thickness = 1.5, Transparency = 0.3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = b })
		local cool = create("Frame", { Name = "Recarga", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0), BackgroundColor3 = rgb(0, 0, 0), BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 3, Parent = b })
		create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = cool })
		-- (con sprites: casilla biselada con brillo abajo, la elegida más luminosa, y la recarga como un
		-- barrido de reloj en vez de la cortina)
		local tile = HudArt.frame(b, "marco_ranura")
		local sweep = nil
		if tile then
			cool.Visible = false
			sweep = HudArt.image(b, "recarga", { Name = "Barrido", ImageRectSize = Vector2.new(HudArt.Cool.Frame, HudArt.Cool.Frame), ImageRectOffset = HudArt.coolOffset(0), ZIndex = 3 })
		end
		local key = label({ Name = "Tecla", Position = UDim2.fromOffset(6, 3), Size = UDim2.fromOffset(20, 16), Text = tostring(i), TextSize = 14, TextColor3 = K.Muted, ZIndex = 4, Parent = b })
		local count = label({ Name = "Cantidad", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 3), Size = UDim2.fromOffset(40, 16), Text = "", TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 4, Parent = b })
		local lock = label({ Name = "Candado", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.6, 0.4), Text = "🔒", TextScaled = true, ZIndex = 5, Visible = false, Parent = b })
		local name = label({ Name = "Nombre", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 2), Size = UDim2.new(1, 8, 0, 16), Text = "", TextSize = 12, TextColor3 = K.White, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, Parent = b })
		local idx = i
		onActivated(b, function()
			local s = view.Slots[idx]
			if s and s.Id and view.OnSlot then
				view.OnSlot(s.Id)
			end
		end)
		view.Slots[i] = { Button = b, Stroke = stroke, Cool = cool, Key = key, Count = count, Lock = lock, Name = name, Glyph = nil, Id = nil, Kind = nil, Tile = tile, Sweep = sweep }
	end
end

-- Lo que el HUD maneja solo (se abre y se cierra): la colocación no lo enciende
local SELF_SHOWN = { Prompt = true, Quantum = true, HelpPanel = true }

-- Coloca las zonas para la pantalla y el vehículo de ahora (y esconde las que ese vehículo no tiene)
local function place(view: View)
	local layout = view.LastLayout
	if not layout then
		return
	end
	local l = ShipHudLayout.compute(layout.Canvas * layout.Scale, { Touch = view.Touch, Vehicle = view.Vehicle })
	for name, f in view.Zones do
		local r = l.Zones[name]
		if r then
			f.AnchorPoint = Vector2.zero
			f.Position = UDim2.fromOffset(r.X, r.Y)
			f.Size = UDim2.fromOffset(r.W, r.H)
			if not SELF_SHOWN[name] then
				f.Visible = true
			end
		else
			f.Visible = false
		end
	end
	-- Listas de teclas plegadas: solo el título
	local keys, moves = view.Zones.Keys, view.Zones.Moves
	if keys and moves and l.Zones.Keys and not view.HintsOpen then
		keys.Size = UDim2.fromOffset(l.Zones.Keys.W, 30)
		moves.Position = UDim2.fromOffset(l.Zones.Moves.X, l.Zones.Keys.Y + 38)
		moves.Size = UDim2.fromOffset(l.Zones.Moves.W, 30)
	end
	local v = ShipHudLayout.vehicle(view.Vehicle)
	for _, f in view.ShieldRows or {} do
		f.Visible = v.Shield
	end
	local shieldArt = view.Art.ArcShield
	for _, t in view.Arcs.Shield or {} do
		t.Visible = v.Shield and shieldArt == nil
	end
	if shieldArt then
		shieldArt.Visible = v.Shield
	end
	for _, k in { "MiniShield" } do
		local b = view.Bars[k]
		if b and b.Parent then
			(b.Parent :: GuiObject).Visible = v.Shield
		end
		local icon = view.Profile.BarRows and view.Profile.BarRows[k]
		if icon then
			icon.Visible = v.Shield
		end
	end
	for _, k in { "ShipShield", "ShipShieldIcono" } do
		local zone = view.Zones.Ship
		local o = zone and zone:FindFirstChild(k)
		if o then
			(o :: GuiObject).Visible = v.Shield
		end
	end
end

function AirCombatHud.new(parent: Instance, touch: boolean, vehicle: string?): View
	local gui = create("ScreenGui", { Name = "AirCombatHud", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 3, Enabled = false, Parent = parent })
	-- (los dibujos se repintan solos cuando el servidor convierte los Decal en imágenes: UI/HudArt)
	HudArt.watch()
	HudLayout.scaleGui(gui)
	local view: View = {
		Gui = gui,
		Panel = nil :: any,
		Values = {},
		Bars = {},
		Objective = nil :: any,
		Warning = nil :: any,
		Radar = nil :: any,
		Blips = {},
		Overlay = nil :: any,
		Cross = nil :: any,
		LockBox = nil :: any,
		LockStroke = nil :: any,
		Arrows = {},
		HitMark = nil :: any,
		Flash = nil :: any,
		Zones = {},
		Profile = {},
		Nav = {},
		Missions = {},
		Slots = {},
		Prompt = {},
		Quantum = {},
		Hints = nil,
		HintsSpecial = nil,
		HintTitles = {},
		HintsOpen = true,
		RadarLabel = nil :: any,
		RadarNorth = nil :: any,
		RadarLetters = {},
		Chips = {},
		LockInfo = nil :: any,
		Touch = touch,
		OnSlot = nil,
		Cache = setmetatable({}, { __mode = "k" }) :: any,
		Vehicle = vehicle or "Ship",
		Arcs = {},
		Jump = {},
		TargetCard = {},
		QuickRows = {},
		Clock = nil,
		HelpPanel = nil,
		Brackets = {},
		LastLayout = nil,
		Art = {},
		Gauges = {},
		GaugeClock = nil,
	}
	local S: any = if touch then ShipHudLayout.Sizes.Touch else ShipHudLayout.Sizes.Pc
	local function zone(name: string, size: Vector2, transparency: number?): Frame
		local f = panel("Zona" .. name, gui, transparency)
		f.Size = UDim2.fromOffset(size.X, size.Y)
		view.Zones[name] = f
		return f
	end
	local function zoneBare(name: string, size: Vector2): Frame
		local f = bare("Zona" .. name, gui)
		f.Size = UDim2.fromOffset(size.X, size.Y)
		view.Zones[name] = f
		return f
	end
	buildProfile(view, zone("A", S.A))
	buildNav(view, zone("B", S.B, 0.4))
	buildSpeed(view, zoneBare("Speed", S.Speed))
	buildDefense(view, zoneBare("Defense", S.Defense))
	-- J: avisos (solo cuando hacen falta)
	local alerts = create("Frame", { Name = "ZonaJ", Size = UDim2.fromOffset(S.J.X, S.J.Y), BackgroundTransparency = 1, Parent = gui })
	view.Zones.J = alerts
	view.Warning = label({ Name = "Aviso", Size = UDim2.fromScale(1, 1), Text = "", TextSize = 18, TextColor3 = K.Hostile, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3, Parent = alerts })
	-- D: radar con aros, cono de delante y N/E/S/O que giran con tu rumbo
	local radar = create("Frame", { Name = "ZonaD", Size = UDim2.fromOffset(S.D, S.D), BackgroundColor3 = rgb(6, 20, 34), BackgroundTransparency = 0.25, BorderSizePixel = 0, Parent = gui })
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = radar })
	create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(20, 70, 100), rgb(4, 12, 24)), Parent = radar })
	create("UIStroke", { Color = K.Edge, Thickness = 3, Transparency = 0.1, Parent = radar })
	view.Zones.D = radar
	-- (con sprites: disco con aros, rejilla, escala y brillo, y un barrido que gira solo)
	local disc = HudArt.image(radar, "radar", { Name = "Disco", ZIndex = 0 })
	if disc then
		radar.BackgroundTransparency = 1
		for _, c in radar:GetChildren() do
			if c:IsA("UIStroke") then
				c.Enabled = false
			end
		end
		local sweep = HudArt.image(radar, "radar_barrido", { Name = "Barrido", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.92, 0.92), ZIndex = 1 })
		view.Art.Sweep = sweep
		-- (el barrido lo gira el motor con una animación sin fin: nada por fotograma en el script)
		pcall(function()
			local TweenService = game:GetService("TweenService")
			TweenService:Create(sweep, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 }):Play()
		end)
	else
		for _, k in { 0.66, 0.33 } do
			ring(radar, UDim2.fromScale(k, k), K.Cyan, 1.2, 0.6)
		end
		line(radar, UDim2.fromScale(0.5, 0.5), UDim2.new(0.92, 0, 0, 1), 0, K.Cyan).BackgroundTransparency = 0.7
		line(radar, UDim2.fromScale(0.5, 0.5), UDim2.new(0, 1, 0.92, 0), 0, K.Cyan).BackgroundTransparency = 0.7
		line(radar, UDim2.fromScale(0.36, 0.3), UDim2.new(0, 1, 0.42, 0), -34, K.Cyan).BackgroundTransparency = 0.55
		line(radar, UDim2.fromScale(0.64, 0.3), UDim2.new(0, 1, 0.42, 0), 34, K.Cyan).BackgroundTransparency = 0.55
	end
	local me = create("Frame", { Name = "Me", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, ZIndex = 4, Parent = radar })
	local meIcon = HudArt.icon(me, if view.Vehicle == "Plane" then "avion" else "hiper", { Name = "Flecha", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.8, 1.8), ZIndex = 4 })
	view.Art.Me = meIcon
	if not meIcon then
		line(me, UDim2.fromScale(0.3, 0.55), UDim2.fromOffset(3, 16), 25, K.White)
		line(me, UDim2.fromScale(0.7, 0.55), UDim2.fromOffset(3, 16), -25, K.White)
	end
	for _, letter in { "N", "E", "S", "O" } do
		view.RadarLetters[letter] = label({ Name = if letter == "N" then "Norte" else "Rumbo" .. letter, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.06), Size = UDim2.fromOffset(22, 22), Text = letter, TextSize = if letter == "N" then 18 else 14, TextColor3 = if letter == "N" then K.White else K.Muted, TextXAlignment = Enum.TextXAlignment.Center, Parent = radar })
	end
	view.RadarNorth = view.RadarLetters.N :: any
	-- El alcance, fuera del círculo (abajo a la izquierda): nunca encima de la N/E/S/O, que giran por
	-- el borde (la captura del avión tenía «RADAR 0,7 km» sobre la N)
	view.RadarLabel = label({ Name = "Alcance", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(0.14, 0, 1, 0), Size = UDim2.fromOffset(110, 16), Text = "RADAR 1,4 km", TextSize = 12, TextColor3 = K.Cyan, TextXAlignment = Enum.TextXAlignment.Right, Parent = radar })
	view.Radar = radar
	for i = 1, AirCombatHud.MaxBlips do
		local b = create("Frame", { Name = "Blip" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundColor3 = K.Hostile, BorderSizePixel = 0, Visible = false, ZIndex = 3, Parent = radar })
		create("UICorner", { Name = "Round", CornerRadius = UDim.new(1, 0), Parent = b })
		create("UIStroke", { Name = "Ring", Color = K.Hostile, Thickness = 2, Enabled = false, Parent = b })
		table.insert(view.Blips, b)
	end
	-- E: misiones
	local missions = zone("E", S.E)
	buildMissions(view, missions)
	view.Objective = label({ Name = "Objetivo", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -4), Size = UDim2.new(1, -24, 0, 16), Text = "", TextSize = 12, TextColor3 = K.Muted, TextTruncate = Enum.TextTruncate.AtEnd, Visible = not touch, Parent = missions })
	buildJump(view, zone("Jump", S.Jump, 0.35))
	buildTarget(view, zone("Target", S.Target, 0.3))
	if touch then
		local help = zone("Help", S.Help, 0.3)
		local helpPanel = zone("HelpPanel", Vector2.new(600, 400), 0.08)
		buildHelp(view, help, helpPanel)
	else
		-- Las dos listas de teclas, la nave en planta y los atajos
		view.Hints = buildKeyList(view, zone("Keys", Vector2.new(S.Keys, 30 + 12 * S.KeyRow), 0.4), "COMANDOS DE VUELO")
		view.HintsSpecial = buildKeyList(view, zone("Moves", Vector2.new(S.Keys, 30 + ShipHudLayout.KeyRows.Moves * S.KeyRow), 0.4), "MANIOBRAS ESPECIALES")
		buildShip(view, zone("Ship", S.Ship, 0.35))
		buildQuick(view, zone("Quick", S.Quick, 0.35))
	end
	-- H: la barra de 8 ranuras
	local barW = S.Slot * 8 + S.Gap * 7 + 16
	local barFrame = zone("H", Vector2.new(barW, S.Slot + 34), 0.45)
	buildSlots(view, barFrame, S.Slot, S.Gap)
	-- (en el móvil no hay esquema de la nave: los valores que van ahí existen igual, sin verse)
	if touch then
		local hidden = create("Frame", { Name = "SinVer", Visible = false, Size = UDim2.fromOffset(330, 180), Parent = gui })
		buildShip(view, hidden)
	end
	-- Letrero de la habilidad en marcha (encima de la barra)
	local prompt = zone("Prompt", S.Prompt, 0.2)
	prompt.Visible = false
	view.Prompt.Frame = prompt
	view.Prompt.Title = label({ Name = "Titulo", Position = UDim2.fromOffset(16, 4), Size = UDim2.new(1, -32, 0, 24), Text = "", TextSize = 20, TextColor3 = K.Cyan, Parent = prompt })
	view.Prompt.Sub = label({ Name = "Texto", Position = UDim2.fromOffset(16, 28), Size = UDim2.new(1, -32, 0, 18), Text = "", TextSize = 14, TextColor3 = K.White, TextTruncate = Enum.TextTruncate.AtEnd, Parent = prompt })
	view.Prompt.Bar = bar(prompt, "Progreso", K.Violet, UDim2.new(0, 16, 1, -8), UDim2.new(1, -32, 0, 4))
	-- (con sprites: emblema redondo con el icono de la hipervelocidad a la izquierda, como la referencia)
	local emblem = HudArt.image(prompt, "emblema", { Name = "Emblema", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -10, 0.5, 0), Size = UDim2.fromScale(1.35, 1.35), SizeConstraint = Enum.SizeConstraint.RelativeYY, ZIndex = 2 })
	if emblem then
		HudArt.icon(emblem, "hiper", { Name = "Icono", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.62, 0.62), ZIndex = 3 })
		local inset = math.floor(S.Prompt.Y * 1.35) - 2
		view.Prompt.Title.Position = UDim2.fromOffset(inset, 4)
		view.Prompt.Title.Size = UDim2.new(1, -inset - 12, 0, 24)
		view.Prompt.Sub.Position = UDim2.fromOffset(inset, 28)
		view.Prompt.Sub.Size = UDim2.new(1, -inset - 12, 0, 18)
		view.Art.Emblem = emblem
	end
	-- Selector del salto cuántico
	local q = zone("Quantum", Vector2.new(580, 520), 0.12)
	q.Visible = false
	q.ZIndex = 10
	view.Quantum.Frame = q
	view.Quantum.Title = label({ Name = "Titulo", Position = UDim2.fromOffset(18, 10), Size = UDim2.new(1, -90, 0, 28), Text = "SALTO CUÁNTICO · DESTINO", TextSize = 22, TextColor3 = K.Violet, ZIndex = 11, Parent = q })
	view.Quantum.Info = label({ Name = "Info", Position = UDim2.fromOffset(18, 40), Size = UDim2.new(1, -36, 0, 18), Text = "", TextSize = 14, TextColor3 = K.Muted, ZIndex = 11, Parent = q })
	local close = create("TextButton", { Name = "Cerrar", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 8), Size = if touch then UDim2.fromOffset(92, 92) else UDim2.fromOffset(56, 44), BackgroundColor3 = rgb(60, 20, 30), Text = "✕", TextSize = 24, Font = Theme.FontBold, TextColor3 = K.White, ZIndex = 11, Parent = q })
	create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = close })
	view.Quantum.Close = close
	local list = create("ScrollingFrame", { Name = "Lista", Position = UDim2.fromOffset(12, if touch then 104 else 64), Size = UDim2.new(1, -24, 1, if touch then -116 else -76), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 11, Parent = q })
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	view.Quantum.List = list
	view.Quantum.Rows = {}
	-- Colocar (y recolocar al cambiar la pantalla)
	HudLayout.onChanged(function(layout)
		view.LastLayout = layout
		place(view)
	end)
	-- F: encima de todo, en píxeles de la pantalla (lo coloca cada fotograma el controlador)
	local overlay = create("ScreenGui", { Name = "AirCombatOverlay", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 2, Enabled = false, Parent = parent })
	-- La mira: pequeña y abierta en el centro (no tapa al enemigo), con un aro
	local cross = create("Frame", { Name = "Cross", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(52, 52), BackgroundTransparency = 1, Parent = overlay })
	-- (con sprites: la mira con aro partido, rayas y brillo)
	if not HudArt.image(cross, "mira", { Name = "Mira", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = if touch then UDim2.fromScale(1.8, 1.8) else UDim2.fromScale(2.6, 2.6) }) then
		for _, d in { { 0.5, 0, 2, 12 }, { 0.5, 1, 2, 12 }, { 0, 0.5, 12, 2 }, { 1, 0.5, 12, 2 } } do
			create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(d[1], d[2]), Size = UDim2.fromOffset(d[3], d[4]), BackgroundColor3 = K.Cyan, BorderSizePixel = 0, Parent = cross })
		end
		ring(cross, UDim2.fromScale(0.62, 0.62), K.Cyan, 2, 0.25)
		ring(cross, UDim2.fromScale(1.6, 1.6), K.Cyan, 1, 0.75)
		create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(4, 4), BackgroundColor3 = K.Cyan, BorderSizePixel = 0, Parent = cross }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	end
	-- Marcador de trayectoria (aviones sin el cañón armado): aro pequeño con alas y aleta, hacia donde
	-- apunta el morro (AirCombatHud.setReticle)
	local path = create("Frame", { Name = "Senda", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(if touch then 34 else 44, if touch then 34 else 44), BackgroundTransparency = 1, Visible = false, Parent = overlay })
	ring(path, UDim2.fromScale(0.46, 0.46), K.Cyan, 2.5, 0)
	for _, d in { { 0.06, 0.5, 0.34, 0 }, { 0.94, 0.5, 0.34, 0 }, { 0.5, 0.12, 0.08, 1 } } do
		local seg = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(d[1], d[2]), Size = if d[4] == 1 then UDim2.new(0, 3, 0.24, 0) else UDim2.new(d[3], 0, 0, 3), BackgroundColor3 = K.Cyan, BorderSizePixel = 0, Parent = path })
		create("UIStroke", { Color = K.Edge, Thickness = 1, Transparency = 0.5, Parent = seg })
	end
	-- Fijación: corchetes en las esquinas, con nombre y nivel, barra de salud y distancia
	local lockBox = create("Frame", { Name = "Lock", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(70, 70), BackgroundTransparency = 1, Visible = false, Parent = overlay })
	local lockStroke = create("UIStroke", { Color = rgb(255, 200, 60), Thickness = 3, Enabled = false, Parent = lockBox })
	for _, c in { { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } } do
		local h = create("Frame", { Name = "Corchete", AnchorPoint = Vector2.new(c[1], c[2]), Position = UDim2.fromScale(c[1], c[2]), Size = UDim2.new(0.32, 0, 0, 3), BackgroundColor3 = rgb(255, 200, 60), BorderSizePixel = 0, Parent = lockBox })
		local v = create("Frame", { Name = "Corchete", AnchorPoint = Vector2.new(c[1], c[2]), Position = UDim2.fromScale(c[1], c[2]), Size = UDim2.new(0, 3, 0.32, 0), BackgroundColor3 = rgb(255, 200, 60), BorderSizePixel = 0, Parent = lockBox })
		table.insert(view.Brackets, h)
		table.insert(view.Brackets, v)
	end
	label({ Name = "Tag", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 4), Size = UDim2.fromOffset(160, 18), Text = "FIJANDO", TextSize = 14, TextColor3 = rgb(255, 200, 60), TextXAlignment = Enum.TextXAlignment.Center, Parent = lockBox })
	view.LockInfo = label({ Name = "Info", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 0, -14), Size = UDim2.fromOffset(200, 34), Text = "", TextSize = 14, TextColor3 = K.Hostile, TextYAlignment = Enum.TextYAlignment.Bottom, Parent = lockBox })
	view.LockHealth = bar(lockBox, "SaludBlanco", K.Hostile, UDim2.new(0, 0, 0, -11), UDim2.fromOffset(110, 5))
	view.LockDist = label({ Name = "Distancia", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, 6, 0.5, 0), Size = UDim2.fromOffset(90, 18), Text = "", TextSize = 13, TextColor3 = K.White, Parent = lockBox })
	local arrows = {}
	for i = 1, AirCombatHud.Arrows do
		table.insert(arrows, label({ Name = "Arrow" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(34, 34), Text = "▲", TextSize = 30, TextColor3 = K.Hostile, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.4, Visible = false, Parent = overlay }))
	end
	local hit = label({ Name = "HitMark", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(44, 44), Text = "✕", TextSize = 40, TextColor3 = rgb(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = 1, TextStrokeTransparency = 1, Parent = overlay })
	local flash = create("Frame", { Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = overlay })
	local flashStroke = create("UIStroke", { Name = "Edge", Color = rgb(80, 200, 255), Thickness = 24, Transparency = 1, Parent = flash })
	flashStroke:SetAttribute("Edge", true)
	view.Overlay = overlay
	view.Cross = cross
	view.PathMarker = path
	view.LockBox = lockBox
	view.LockStroke = lockStroke
	view.Arrows = arrows
	view.HitMark = hit
	view.Flash = flash
	return view
end

-- (con sprites) La silueta de la nave o del avión en el esquema, los atajos y la flecha del radar
local function setSilhouetteArt(view: View, kind: string)
	local plane = kind == "Avion"
	for _, img in view.Art.ShipSilhouettes or {} do
		HudArt.setSprite(img, if plane then "silueta_avion" else "silueta_nave")
	end
	if view.Art.Me then
		HudArt.setIcon(view.Art.Me, if plane then "avion" else "hiper")
	end
end

-- Cambiar de vehículo (nave, avión…): qué zonas y valores se ven. Sin tocar nada más.
function AirCombatHud.setVehicle(view: View, vehicle: string)
	if view.Vehicle == vehicle then
		return
	end
	view.Vehicle = vehicle
	place(view)
	local v = ShipHudLayout.vehicle(vehicle)
	if view.Silhouette then
		view.Silhouette:SetAttribute("Vehicle", v.Silhouette)
	end
	setSilhouetteArt(view, v.Silhouette)
end

-- La mirilla en el centro: mode "Arma" = la mira con su aro (cañón armado o la nave), "Vuelo" = el
-- marcador de trayectoria del avión; nil = ninguna. point = píxeles de la pantalla (nil: el centro,
-- un poco por encima, como la mira de la nave). Lo llama Controllers/PlaneHudClient cada fotograma.
function AirCombatHud.setReticle(view: View, mode: string?, point: Vector2?)
	local pos = if point then UDim2.fromOffset(math.floor(point.X + 0.5), math.floor(point.Y + 0.5)) else UDim2.fromScale(0.5, 0.45)
	put(view, view.Cross, "Visible", mode == "Arma")
	if view.PathMarker then
		put(view, view.PathMarker, "Visible", mode == "Vuelo")
	end
	if mode == "Arma" then
		put(view, view.Cross, "Position", pos)
	elseif mode == "Vuelo" and view.PathMarker then
		put(view, view.PathMarker, "Position", pos)
	end
end

-- Qué mirilla toca (puro): con el arma lista, la mira; si no, el marcador de trayectoria
function AirCombatHud.reticleMode(piloting: boolean, armed: boolean): string?
	if not piloting then
		return nil
	end
	return if armed then "Arma" else "Vuelo"
end

function AirCombatHud.setEnabled(view: View, on: boolean)
	view.Gui.Enabled = on
	view.Overlay.Enabled = on
	if not on then
		AirCombatHud.hideQuantum(view)
	end
end

---------------------------------------------------------------------
-- Arcos: lo que pasó desde la última vez (para el relleno animado; el controlador llama a 10 por segundo)
---------------------------------------------------------------------
local function gaugeStep(view: View): number
	local now = os.clock()
	local last = view.GaugeClock
	view.GaugeClock = now
	return if last then math.clamp(now - last, 0, 0.25) else 0
end

-- Un indicador de arco: se acerca a k (relleno animado) y se tiñe; las rayitas de siempre y, con
-- sprites, el fotograma del atlas (solo cambia la imagen cuando cambia el fotograma)
local function gauge(view: View, name: string, k: number, color: Color3, dt: number)
	local target = math.clamp(if k == k then k else 0, 0, 1)
	local shown = HudArt.approach(view.Gauges[name], target, dt, 7)
	view.Gauges[name] = shown
	local ticks = view.Arcs[name]
	if ticks then
		local n = ShipHudLayout.lit(#ticks, shown)
		for i, f in ticks do
			put(view, f, "BackgroundTransparency", if i <= n then 0.05 else 0.8)
			put(view, f, "BackgroundColor3", color)
		end
	end
	local img = view.Art["Arc" .. name]
	if img then
		put(view, img, "ImageRectOffset", HudArt.arcOffset(shown))
		put(view, img, "ImageColor3", color)
	end
end

---------------------------------------------------------------------
-- Textos del panel (puro)
---------------------------------------------------------------------
function AirCombatHud.texts(info: Info): { [string]: string }
	local warn = info.Warn
	if info.Overheated then
		warn = "Calor"
	end
	local maxE = info.MaxEnergy or 100
	return {
		Speed = tostring(math.floor(info.Speed + 0.5)),
		Boost = if info.BoostReady then ("%d%%"):format(math.floor(info.Boost * 100 + 0.5)) else "ENFRIANDO",
		Shield = tostring(math.max(0, math.floor(info.Shield + 0.5))),
		Hull = tostring(math.max(0, math.floor(info.Hull + 0.5))),
		ShieldPct = ("%d%%"):format(math.floor(math.clamp(if info.MaxShield > 0 then info.Shield / info.MaxShield else 0, 0, 9) * 100 + 0.5)),
		HullPct = ("%d%%"):format(math.floor(math.clamp(if info.MaxHull > 0 then info.Hull / info.MaxHull else 0, 0, 1) * 100 + 0.5)),
		Missiles = ("%d/%d"):format(info.Missiles, info.MaxMissiles),
		Energy = ("%d%%"):format(math.floor(math.clamp((info.Energy or maxE) / maxE, 0, 1) * 100 + 0.5)),
		Weapon = if info.Weapon == "Laser" then "LÁSER" else "CAÑONES",
		Mode = (if info.FlightMode == "Cruise" then "CRUCERO" elseif info.FlightMode == "Explore" then "EXPLORACIÓN" else "COMBATE") .. (if info.Assist == false then " · LIBRE" else ""),
		Flares = if info.MaxFlares and info.MaxFlares > 0 then ("🎇%d"):format(info.Flares or 0) else "",
		Objective = (if info.Mode == "Space" then "🌌 " else "⛰ ") .. info.Objective .. (if info.Score > 0 then ("  ·  %d pts"):format(info.Score) else ""),
		Warning = info.Alert or (if warn then WARN_TEXT[warn] or "" else ""),
	}
end

function AirCombatHud.set(view: View, info: Info)
	local t = AirCombatHud.texts(info)
	-- (escudo y estructura en %, como la referencia; los valores sueltos siguen en texts())
	local shown = { Speed = t.Speed, Boost = t.Boost, Shield = t.ShieldPct, Hull = t.HullPct, ShipShield = t.ShieldPct, ShipHull = t.HullPct, Missiles = t.Missiles, Energy = t.Energy, Weapon = t.Weapon, Flares = t.Flares }
	for k, text in shown do
		local v = view.Values[k]
		if v then
			put(view, v, "Text", text)
		end
	end
	if view.Chips.Mode then
		put(view, view.Chips.Mode, "Text", t.Mode)
		put(view, view.Chips.Mode, "TextColor3", if info.FlightMode == "Cruise" then K.Gold elseif info.FlightMode == "Explore" then K.Violet else K.Cyan)
	end
	local combat = info.FlightMode == nil or info.FlightMode == "Combat"
	if view.Chips.Combat then
		put(view, view.Chips.Combat, "Text", if combat then "ON" else "OFF")
		put(view, view.Chips.Combat, "TextColor3", if combat then K.Cyan else K.Muted)
		put(view, view.Chips.Combat, "BackgroundColor3", if combat then rgb(16, 60, 100) else rgb(30, 34, 44))
	end
	-- Arcos: velocidad (e impulso por dentro), escudo y estructura; naranja/rojo cuando queda poco
	local dt = gaugeStep(view)
	local function arc(name: string, k: number, color: Color3)
		gauge(view, name, k, color, dt)
	end
	local speedK = math.clamp(info.Speed / math.max(info.SpeedMax or 1500, 1), 0, 1)
	local shieldK = if info.MaxShield > 0 then info.Shield / info.MaxShield else 0
	arc("Speed", speedK, HudArt.gaugeColor("Speed", speedK, { Boost = info.Boosting }))
	arc("Boost", info.Boost, if info.BoostReady then HudArt.GaugeColors.Boost else K.Locked)
	arc("Shield", shieldK, HudArt.gaugeColor("Shield", shieldK))
	put(view, view.Objective, "Text", t.Objective)
	put(view, view.Warning, "Text", t.Warning)
	local function fill(name: string, k: number)
		local b = view.Bars[name]
		if b then
			put(view, b, "Size", UDim2.fromScale(math.clamp(math.floor(k * 50 + 0.5) / 50, 0, 1), 1))
		end
	end
	fill("Boost", info.Boost)
	put(view, view.Bars.Boost, "BackgroundColor3", if not info.BoostReady then rgb(120, 120, 140) elseif info.Boosting then rgb(255, 210, 120) else K.Boost)
	fill("Energy", (info.Energy or 100) / math.max(info.MaxEnergy or 100, 1))
	fill("Shield", if info.MaxShield > 0 then info.Shield / info.MaxShield else 0)
	local hull = if info.MaxHull > 0 then info.Hull / info.MaxHull else 0
	fill("Hull", hull)
	arc("Hull", hull, HudArt.gaugeColor("Hull", hull))
	fill("MiniHull", hull)
	fill("MiniShield", if info.MaxShield > 0 then info.Shield / info.MaxShield else 0)
	fill("MiniEnergy", (info.Energy or 100) / math.max(info.MaxEnergy or 100, 1))
	put(view, view.Bars.Hull, "BackgroundColor3", rgb(255, 70, 60):Lerp(K.Hull, math.clamp(math.floor(hull * 10) / 10, 0, 1)))
	fill("Heat", info.Heat or 0)
	put(view, view.Values.Hull, "TextColor3", if hull < 0.3 then K.Hostile else K.White)
end

---------------------------------------------------------------------
-- Aviones (vehículo "Plane"): el mismo HUD con lo del avión
---------------------------------------------------------------------
AirCombatHud.PlaneWarn = {
	Perdida = "⚠ PÉRDIDA: baja el morro y mete motor",
	Tren = "⚠ ¡BAJA EL TREN! (G)",
	Limite = "⚠ LÍMITE DEL MAPA: el avión vuelve solo",
	Techo = "⚠ TECHO DE VUELO",
	FinPista = "⚠ FIN DE PISTA: tira para despegar o frena",
}

-- Textos del panel del avión (puro: scripts/test-hud.luau)
function AirCombatHud.planeTexts(info: PlaneInfo): { [string]: string }
	local climb = info.Climb
	local arrow = if climb > 0.3 then "▲" elseif climb < -0.3 then "▼" else "="
	local heading = math.floor(info.Heading + 0.5) % 360
	local cards = { "N", "NE", "E", "SE", "S", "SO", "O", "NO" }
	local gear = if info.FixedGear then "TREN FIJO" elseif info.Gear then "TREN ↓" else "TREN ↑"
	return {
		Speed = tostring(math.floor(info.Speed + 0.5)),
		Knots = ("KM/H · %d KT"):format(math.floor(info.Speed / 1.852 + 0.5)),
		Throttle = ("%d%%"):format(math.floor(info.Throttle * 100 + 0.5)),
		Altitude = ("%d m"):format(math.floor(info.Altitude + 0.5)),
		Climb = ("%s %.1f m/s"):format(arrow, math.abs(climb)),
		Health = ("%d%%"):format(math.max(0, math.floor(info.Health + 0.5))),
		Heading = ("%03d° %s"):format(heading, cards[math.floor((heading + 22.5) / 45) % 8 + 1]),
		Config = ("FLAPS %d · %s%s"):format(info.Flaps, gear, if info.Brake then " · FRENOS" else ""),
		Mode = if info.Stalled then "⚠ PÉRDIDA" elseif info.OnGround then "EN TIERRA" else "EN VUELO",
		Stick = if info.PullUp == false then "↑ SUBE" else "↓ SUBE",
		Warning = info.Alert or (if info.Warn then AirCombatHud.PlaneWarn[info.Warn] or "" else ""),
	}
end

-- Cambia los rótulos de la nave por los del avión (una vez)
local function planeLabels(view: View)
	if view.PlaneLabeled then
		return
	end
	view.PlaneLabeled = true
	local function relabel(root: Instance?, name: string, text: string)
		local o = root and root:FindFirstChild(name, true)
		if o and o:IsA("TextLabel") then
			o.Text = text
		end
	end
	local speed = view.Zones.Speed
	relabel(speed, "BoostCaption", "MOTOR")
	relabel(speed, "Rotulo", "VELOCIDAD")
	-- La tarjeta de abajo a la izquierda (y la que no se ve en el móvil): ALTITUD, V/S, RUMBO, FLAPS · TREN
	for _, root in { view.Zones.Ship, view.Gui:FindFirstChild("SinVer") } do
		relabel(root, "EnergyIcono", "▲")
		relabel(root, "ShipHullIcono", "♥")
		relabel(root, "MisilesCaption", "RUMBO")
		local heat = root and root:FindFirstChild("HeatTrack", true)
		if heat and heat:IsA("GuiObject") then
			heat.Visible = false
		end
	end
	-- La tarjeta OBJETIVO es la PISTA (cuánta queda)
	local targetTitle = view.Zones.Target and view.Zones.Target:FindFirstChild("Titulo")
	relabel(view.Zones.Target, "Titulo", if targetTitle and targetTitle:GetAttribute("Plain") then "PISTA" else "✈ PISTA")
	-- Los atajos (ordenador): flaps, tren, cámara y bajarse; el interruptor, la palanca
	local quick = view.Zones.Quick
	for action, text in { RollLeft = "Flaps", RollRight = "Tren", Dodge = "Cámara", Cloak = "Bajarse" } do
		local row = quick and quick:FindFirstChild("Atajo" .. action)
		relabel(row, "Texto", text)
		local chip = view.QuickRows[action]
		if chip then
			chip.Text = ({ RollLeft = "F", RollRight = "G", Dodge = "C", Cloak = "Esp" })[action]
		end
	end
	relabel(quick, "ModoTexto", "▸ Tirar ↓ para subir")
	if view.Silhouette then
		view.Silhouette:SetAttribute("Vehicle", "Avion")
	end
	setSilhouetteArt(view, "Avion")
	-- (con sprites) los iconos de las filas del esquema: altitud (motor) y estructura
	if view.Art.RowIconEnergy then
		HudArt.setIcon(view.Art.RowIconEnergy, "avion")
	end
end

function AirCombatHud.setPlane(view: View, info: PlaneInfo)
	planeLabels(view)
	local t = AirCombatHud.planeTexts(info)
	local V = view.Values
	local shown = { Speed = t.Speed, Boost = t.Throttle, Hull = t.Health, ShipHull = t.Health, Energy = t.Altitude, Missiles = t.Heading, Weapon = t.Config, Flares = t.Climb }
	for k, text in shown do
		local v = V[k]
		if v then
			put(view, v, "Text", text)
		end
	end
	local kmh = view.Zones.Speed and view.Zones.Speed:FindFirstChild("KmH")
	if kmh then
		put(view, kmh, "Text", t.Knots)
	end
	if view.Chips.Mode then
		put(view, view.Chips.Mode, "Text", t.Mode)
		put(view, view.Chips.Mode, "TextColor3", if info.Stalled then K.Hostile elseif info.OnGround then K.Gold else K.Cyan)
	end
	if view.Chips.Combat then
		put(view, view.Chips.Combat, "Text", if info.PullUp == false then "NO" else "SÍ")
	end
	put(view, view.Warning, "Text", t.Warning)
	local dt = gaugeStep(view)
	local health = math.clamp(info.Health / 100, 0, 1)
	local speedK = math.clamp(info.Speed / math.max(info.SpeedMax or 160, 1), 0, 1)
	gauge(view, "Speed", speedK, HudArt.gaugeColor("Speed", speedK, { Stall = info.Stalled }), dt)
	gauge(view, "Boost", info.Throttle, HudArt.GaugeColors.Boost, dt)
	gauge(view, "Hull", health, HudArt.gaugeColor("Hull", health), dt)
	local function fill(name: string, k: number)
		local b = view.Bars[name]
		if b then
			put(view, b, "Size", UDim2.fromScale(math.clamp(math.floor(k * 50 + 0.5) / 50, 0, 1), 1))
		end
	end
	fill("Boost", info.Throttle)
	fill("Hull", health)
	fill("MiniHull", health)
	fill("MiniEnergy", info.Throttle)
	fill("Energy", info.Altitude / math.max(info.Ceiling or 390, 1))
	put(view, view.Bars.Hull, "BackgroundColor3", rgb(255, 70, 60):Lerp(K.Hull, math.floor(health * 10) / 10))
	put(view, V.Hull, "TextColor3", if health < 0.3 then K.Hostile else K.White)
	if V.Weapon then
		put(view, V.Weapon, "TextColor3", if info.Warn == "Tren" then K.Hostile else K.Cyan)
	end
end

---------------------------------------------------------------------
-- A · Perfil
---------------------------------------------------------------------
-- El texto de una casilla de recurso: con su icono (sprites) sin el emoji del principio
local function resText(view: View, i: number, text: string, icon: string?): string
	local img = view.Profile.ResIcons and view.Profile.ResIcons[i]
	if not img then
		return text
	end
	if icon then
		HudArt.setIcon(img, icon)
	end
	return HudArt.plain(text)
end

function AirCombatHud.setProfile(view: View, p: { [string]: any })
	local P = view.Profile
	if p.UserId and P.Avatar then
		put(view, P.Avatar, "Image", ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(p.UserId))
	end
	put(view, P.Name, "Text", tostring(p.Name or ""))
	put(view, P.Level, "Text", ("Nv. %d"):format(p.Level or 1))
	put(view, P.Money, "Text", tostring(p.Money or "$0"))
	put(view, P.Chispas, "Text", resText(view, 1, if p.Res1 then tostring(p.Res1) else ("✨ %d"):format(p.Chispas or 0), p.Res1Icon))
	if p.Res1Color then
		put(view, P.Chispas, "TextColor3", p.Res1Color)
	end
	if p.Ship then
		put(view, P.Ship, "Text", p.Ship)
	end
	-- (los otros dos recursos: p.Resources = { { Text, Color? }, … } para las casillas 2 y 3)
	if type(p.Resources) == "table" then
		AirCombatHud.setResources(view, p.Resources)
	end
end

-- Las casillas de recursos 2 y 3 del perfil (la 1 son las Chispas): { { Text, Color?, Icon? } }
-- (Icon: un icono de UI/HudArt, p. ej. "combustible"; con sprites el emoji del texto sobra y se quita)
function AirCombatHud.setResources(view: View, list: { { [string]: any } })
	local res = view.Profile.Res or {}
	for i, r in list do
		local chip = res[i + 1]
		if chip then
			put(view, chip, "Text", resText(view, i + 1, tostring(r.Text or ""), r.Icon))
			if r.Color then
				put(view, chip, "TextColor3", r.Color)
			end
		end
	end
end

-- El reloj (abajo a la derecha; en el móvil, en el perfil)
function AirCombatHud.setClock(view: View, text: string)
	if view.Clock then
		put(view, view.Clock, "Text", text)
	end
end

---------------------------------------------------------------------
-- B · Navegación
---------------------------------------------------------------------
-- extra = { { Bearing, Color } } (hasta 3: la misión, el objetivo…)
function AirCombatHud.setCompass(view: View, heading: number, targetBearing: number?, extra: { { [string]: any } }?)
	local N = view.Nav
	local marks = ShipHudLayout.compass(heading, 120)
	if N.Tape then
		put(view, N.Tape, "ImageRectOffset", Vector2.new(math.floor(HudArt.compassOffset(heading) + 0.5), 0))
	end
	for i, slot in N.Marks do
		local m = marks[i]
		if m then
			put(view, slot.Label, "Visible", true)
			put(view, slot.Label, "Position", UDim2.fromScale(m.X, 0))
			put(view, slot.Label, "Text", m.Text)
			put(view, slot.Label, "TextColor3", if m.Text == "N" then K.Cyan elseif m.Major then K.White else K.Muted)
			put(view, slot.Label, "TextSize", if m.Major then 22 else 16)
			put(view, slot.Tick, "Size", UDim2.fromOffset(2, if m.Text ~= "" then 4 else 8))
		else
			put(view, slot.Label, "Visible", false)
		end
	end
	local tx = if targetBearing then ShipHudLayout.bearingX(heading, targetBearing, 120) else nil
	put(view, N.Target, "Visible", tx ~= nil)
	if tx then
		put(view, N.Target, "Position", UDim2.fromScale(tx, 0.55))
	end
	for i, f in N.Extra or {} do
		local m = extra and extra[i]
		local x = if m and m.Bearing then ShipHudLayout.bearingX(heading, m.Bearing, 120) else nil
		put(view, f, "Visible", x ~= nil)
		if x and m then
			put(view, f, "Position", UDim2.fromScale(x, 0.55))
			put(view, f, "BackgroundColor3", m.Color or K.Hostile)
		end
	end
end

-- nav = { Zone, Detail, Dest (texto), Quantum (texto), QuantumColor }
function AirCombatHud.setNav(view: View, nav: { [string]: any })
	local N = view.Nav
	put(view, N.Zone, "Text", ("%s%s"):format(nav.Zone or "", if nav.Detail and nav.Detail ~= "" then "  ·  " .. nav.Detail else ""))
	put(view, N.Dest, "Text", nav.Dest or "")
	put(view, N.Quantum, "Text", nav.Quantum or "")
	put(view, N.Quantum, "TextColor3", nav.QuantumColor or K.Violet)
	-- (opcional: los aviones van por el espacio aéreo de Valmar, no por el «Sistema Valmar»)
	if nav.System then
		put(view, N.System, "Text", nav.System)
	end
end

---------------------------------------------------------------------
-- D · Radar
---------------------------------------------------------------------
-- Lo de antes (solo enemigos), para quien lo use así
export type Blip = { Point: Vector2, Locked: boolean?, Kind: string? }
function AirCombatHud.blips(view: View, list: { Blip })
	local out = {}
	for _, b in list do
		table.insert(out, { Kind = if b.Locked then "Fijado" else "Enemigo", Point = b.Point, Distance = 0, Above = 0 })
	end
	AirCombatHud.radar(view, out)
end

function AirCombatHud.radar(view: View, list: { ShipHudLayout.Blip }, range: number?, heading: number?)
	for i, frame in view.Blips do
		local b = list[i]
		put(view, frame, "Visible", b ~= nil)
		if b then
			local kind = ShipHudLayout.Kinds[b.Kind] or ShipHudLayout.Kinds.Enemigo
			local color = b.Color or kind.Color
			-- (los planetas lejanos van en el aro de la brújula, cada uno de su color)
			local ring = if b.Edge then 0.47 else 0.44
			put(view, frame, "Position", UDim2.fromScale(0.5 + b.Point.X * ring, 0.5 + b.Point.Y * ring))
			local size = kind.Size
			put(view, frame, "Size", UDim2.fromOffset(size, size))
			local ringShape = kind.Shape == "Aro"
			put(view, frame, "BackgroundTransparency", if ringShape then 1 else 0)
			put(view, frame, "BackgroundColor3", color)
			put(view, frame, "Rotation", if kind.Shape == "Rombo" or kind.Shape == "Cuadro" then 45 else 0)
			local round = frame:FindFirstChild("Round") :: UICorner?
			if round then
				put(view, round, "CornerRadius", if kind.Shape == "Punto" or ringShape then UDim.new(1, 0) else UDim.new(0, 2))
			end
			local stroke = frame:FindFirstChild("Ring") :: UIStroke?
			if stroke then
				put(view, stroke, "Enabled", ringShape)
				put(view, stroke, "Color", color)
			end
		end
	end
	if range then
		put(view, view.RadarLabel, "Text", ("RADAR %s"):format(string.gsub(("%.1f km"):format(range * 0.28 / 1000), "%.", ",")))
	end
	if heading then
		-- La N gira: el radar va con tu rumbo (delante = arriba)
		for letter, off in { N = 0, E = 90, S = 180, O = 270 } do
			local lb = view.RadarLetters[letter]
			if lb then
				local a = math.rad(off - heading)
				put(view, lb, "Position", UDim2.fromScale(0.5 + math.sin(a) * 0.43, 0.5 - math.cos(a) * 0.43))
			end
		end
	end
end

---------------------------------------------------------------------
-- E · Misiones
---------------------------------------------------------------------
-- rows = { { Kind = "PRINCIPAL"|"SECUNDARIA"|"EVENTO", Title, Step, Right, Color } }
function AirCombatHud.setMissions(view: View, rows: { { [string]: any } })
	for i, r in view.Missions do
		local m = rows[i]
		put(view, r.Row, "Visible", m ~= nil)
		if m then
			local color = m.Color or (if m.Kind == "PRINCIPAL" then K.Gold elseif m.Kind == "EVENTO" or m.Kind == "EVENTO GLOBAL" then K.Hostile else K.Cyan)
			put(view, r.Kind, "Text", m.Kind or "")
			put(view, r.Kind, "TextColor3", color)
			put(view, r.Dot, "BackgroundColor3", color)
			if r.Icon then
				HudArt.setIcon(r.Icon, if m.Kind == "PRINCIPAL" then "emblema" elseif m.Kind == "EVENTO" or m.Kind == "EVENTO GLOBAL" then "rombo_rojo" else "rombo")
			end
			put(view, r.Title, "Text", m.Title or "")
			put(view, r.Step, "Text", m.Step or "")
			put(view, r.Right, "Text", m.Right or "")
		end
	end
end

---------------------------------------------------------------------
-- H · Ranuras
---------------------------------------------------------------------
local STATE_COLOR = {
	Ready = K.Edge,
	Active = K.Cyan,
	Cooling = rgb(120, 140, 170),
	NoEnergy = K.Boost,
	Locked = K.Locked,
	Blocked = K.Boost,
}

function AirCombatHud.setSlots(view: View, list: { { [string]: any } }, device: string?)
	for i, s in view.Slots do
		local v = list[i]
		if not v then
			continue
		end
		if s.Id ~= v.Id then
			s.Id = v.Id
			if s.Glyph then
				s.Glyph:Destroy()
			end
			local def = ShipAbilities.SlotById[v.Id]
			-- (v.Glyph: un icono propio, como los de los aviones)
			local kind = v.Glyph or (if def then def.Glyph else "Canon")
			-- (con sprites: el icono dibujado del atlas; si no, el de marcos)
			-- (los glifos sin dibujo en el atlas, como los de las acrobacias, van con marcos)
			local iconName = HudArt.GlyphIcon[kind] or (if ShipAbilities.SlotById[v.Id] then "armas" else nil)
			local art = iconName and HudArt.icon(s.Button, iconName, { Name = "Glifo", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46), Size = UDim2.fromScale(0.72, 0.72), ZIndex = 2 })
			if art then
				art:SetAttribute("Glyph", kind)
				s.Glyph = art :: any
			else
				s.Glyph = AirCombatHud.glyph(s.Button, kind, K.Cyan)
			end
		end
		local locked = v.State == "Locked"
		local color = STATE_COLOR[v.State] or K.Edge
		put(view, s.Lock, "Visible", locked)
		put(view, s.Glyph, "Visible", not locked)
		if s.Glyph:IsA("ImageLabel") then
			-- (sprite: gris si está bloqueada o recargando)
			put(view, s.Glyph, "ImageColor3", if locked then rgb(110, 115, 125) elseif v.State == "Cooling" then rgb(150, 160, 175) else rgb(255, 255, 255))
			put(view, s.Glyph, "ImageTransparency", if v.State == "Cooling" then 0.3 else 0)
		end
		if s.Tile then
			local sel = v.Selected or v.State == "Active"
			HudArt.setSprite(s.Tile, if sel then "marco_ranura_sel" else "marco_ranura")
			put(view, s.Tile, "ImageColor3", if v.State == "NoEnergy" or v.State == "Blocked" then rgb(255, 190, 120) elseif locked then rgb(140, 145, 155) else rgb(255, 255, 255))
		end
		if s.Sweep then
			put(view, s.Sweep, "ImageRectOffset", HudArt.coolOffset(v.Cool or 0))
		end
		for _, d in s.Glyph:GetDescendants() do
			if d:IsA("Frame") and (d.BackgroundTransparency or 0) < 1 then
				put(view, d, "BackgroundColor3", if locked then K.Locked elseif v.State == "Cooling" then K.Muted elseif d:GetAttribute("Accent") then K.Boost else K.Cyan)
			elseif d:IsA("UIStroke") then
				put(view, d, "Color", if locked then K.Locked elseif v.State == "Cooling" then K.Muted else K.Cyan)
			end
		end
		put(view, s.Stroke, "Color", if v.Selected then K.White else color)
		put(view, s.Stroke, "Thickness", if v.Selected or v.State == "Active" then 3 else 1.5)
		put(view, s.Button, "BackgroundColor3", if v.State == "Active" then rgb(16, 60, 100) elseif locked then rgb(14, 18, 26) else rgb(8, 22, 44))
		put(view, s.Cool, "Size", UDim2.fromScale(1, math.clamp(math.floor((v.Cool or 0) * 20 + 0.5) / 20, 0, 1)))
		put(view, s.Count, "Text", v.Count or "")
		put(view, s.Key, "Text", if device == "Touch" then "" else v.Key)
		put(view, s.Name, "Text", if locked then (v.Note or "Próximamente") elseif v.Note and v.State ~= "Ready" and v.State ~= "Active" then v.Note else v.Name)
		put(view, s.Name, "TextColor3", if locked then K.Muted elseif v.State == "NoEnergy" or v.State == "Blocked" then K.Boost elseif v.Selected then K.Cyan else K.White)
	end
end

-- No se puede: la ranura tiembla en rojo un momento
function AirCombatHud.denySlot(view: View, id: string)
	for _, s in view.Slots do
		if s.Id == id then
			local b = s.Button
			local stroke = s.Stroke
			view.Cache[stroke] = nil
			stroke.Color = K.Hostile
			stroke.Thickness = 3
			local base = b.Position
			task.spawn(function()
				for i = 1, 6 do
					b.Position = base + UDim2.fromOffset(if i % 2 == 0 then 4 else -4, 0)
					task.wait(0.03)
				end
				b.Position = base
				view.Cache[stroke] = nil
			end)
		end
	end
end

---------------------------------------------------------------------
-- Teclas (ordenador y mando), salto, objetivo y fijación
---------------------------------------------------------------------
local function fillHints(list: Frame?, hints: { { Key: string, Text: string } })
	if not list then
		return
	end
	for _, c in list:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	for i, h in hints do
		local row = create("Frame", { Name = "Tecla" .. i, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Parent = list })
		keyChip(row, h.Key, { Size = UDim2.fromOffset(78, 18), Position = UDim2.fromOffset(0, 1) })
		label({ Name = "Texto", Position = UDim2.fromOffset(86, 0), Size = UDim2.new(1, -86, 1, 0), Text = h.Text, TextSize = 13, TextColor3 = K.White, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row })
	end
end

-- Las dos listas («COMANDOS DE VUELO» y «MANIOBRAS ESPECIALES») para el teclado o el mando
function AirCombatHud.setHintGroups(view: View, device: string)
	fillHints(view.Hints, ShipKeys.groupHints("Flight", device))
	fillHints(view.HintsSpecial, ShipKeys.groupHints("Special", device))
	for action, chip in view.QuickRows do
		local key = ShipKeys.label(action, device)
		put(view, chip, "Text", if key ~= "" then key else "—")
	end
	AirCombatHud.toggleHints(view, view.HintsOpen)
end

-- Plegar o desplegar las listas de teclas (H)
function AirCombatHud.toggleHints(view: View, open: boolean?)
	if open == nil then
		open = not view.HintsOpen
	end
	view.HintsOpen = open == true
	for name, t in view.HintTitles do
		local base = if name == "ZonaKeys" then "COMANDOS DE VUELO" else "MANIOBRAS ESPECIALES"
		base = (view.HintNames and view.HintNames[name]) or base
		put(view, t, "Text", base .. (if view.HintsOpen then "" else "  ·  H"))
	end
	for _, list in { view.Hints, view.HintsSpecial } do
		if list then
			list.Visible = view.HintsOpen
		end
	end
	place(view)
end

-- (móvil) el panel «?» con lo que hace cada botón
function AirCombatHud.toggleHelp(view: View, open: boolean?)
	local p = view.HelpPanel
	if not p then
		return
	end
	if open == nil then
		open = not p.Visible
	end
	p.Visible = open == true
end

-- SALTO CUÁNTICO: j = { Dest, Info, Action, Color } (Dest nil = «—»)
function AirCombatHud.setJump(view: View, j: { [string]: any })
	local J = view.Jump
	if not J.Dest then
		return
	end
	put(view, J.Dest, "Text", "Destino: " .. tostring(j.Dest or "—"))
	put(view, J.Info, "Text", j.Info or "")
	if j.Action then
		put(view, J.Action, "Text", j.Action)
	end
	put(view, J.Title, "TextColor3", j.Color or K.Violet)
end

-- OBJETIVO: t = { Name, Level, Health (0..1), Dist (texto), Locked } o nil
function AirCombatHud.setTarget(view: View, t: { [string]: any }?)
	local T = view.TargetCard
	if not T.Name then
		return
	end
	local on = t ~= nil
	put(view, T.Empty, "Visible", not on)
	for _, o in { T.Name, T.Level, T.Dist, T.Dot } do
		put(view, o, "Visible", on)
	end
	local track = T.Bar.Parent :: GuiObject
	put(view, track, "Visible", on)
	if t then
		put(view, T.Name, "Text", tostring(t.Name or "Enemigo"))
		put(view, T.Level, "Text", if t.Level then ("Nv. %d"):format(t.Level) else "")
		put(view, T.Dist, "Text", (t.Dist or "") .. (if t.Locked then "  ·  FIJADO" else ""))
		put(view, T.Bar, "Size", UDim2.fromScale(math.clamp(math.floor((t.Health or 1) * 50 + 0.5) / 50, 0, 1), 1))
	end
end

-- Los corchetes de fijación (encima del blanco): color, nombre/nivel, salud y distancia
function AirCombatHud.setLock(view: View, locked: boolean, info: { [string]: any })
	local color = if locked then rgb(255, 60, 60) else rgb(255, 200, 60)
	for _, f in view.Brackets do
		put(view, f, "BackgroundColor3", color)
	end
	put(view, view.LockStroke, "Color", color)
	local tag = view.LockBox:FindFirstChild("Tag") :: TextLabel?
	if tag then
		put(view, tag, "Text", if locked then "FIJADO · MISIL" else "FIJANDO")
		put(view, tag, "TextColor3", color)
	end
	put(view, view.LockInfo, "Text", ("%s%s"):format(info.Name or "Enemigo", if info.Level then ("\nNv. %d"):format(info.Level) else ""))
	if view.LockHealth then
		put(view, view.LockHealth, "Size", UDim2.fromScale(math.clamp(math.floor((info.Health or 1) * 50 + 0.5) / 50, 0, 1), 1))
	end
	if view.LockDist then
		put(view, view.LockDist, "Text", info.Dist or "")
	end
end

-- Las dos listas con lo que se quiera (los aviones): títulos { ZonaKeys = …, ZonaMoves = … } opcionales
function AirCombatHud.setHintLists(view: View, flight: { { Key: string, Text: string } }, special: { { Key: string, Text: string } }, names: { [string]: string }?)
	if names then
		view.HintNames = names
	end
	fillHints(view.Hints, flight)
	fillHints(view.HintsSpecial, special)
	AirCombatHud.toggleHints(view, view.HintsOpen)
end

-- (antes) una sola lista: va a «COMANDOS DE VUELO»
function AirCombatHud.setHints(view: View, hints: { { Key: string, Text: string } })
	fillHints(view.Hints, hints)
end

---------------------------------------------------------------------
-- Letrero de la habilidad en marcha
---------------------------------------------------------------------
function AirCombatHud.setPrompt(view: View, title: string?, sub: string?, progress: number?, color: Color3?)
	local P = view.Prompt
	put(view, P.Frame, "Visible", title ~= nil)
	if title then
		put(view, P.Title, "Text", title)
		put(view, P.Title, "TextColor3", color or K.Cyan)
		put(view, P.Sub, "Text", sub or "")
		put(view, P.Bar, "Size", UDim2.fromScale(math.clamp(progress or 0, 0, 1), 1))
		put(view, P.Bar, "BackgroundColor3", color or K.Violet)
	end
end

---------------------------------------------------------------------
-- Selector del salto cuántico
---------------------------------------------------------------------
-- entries = { { Id, Name, Kind, Dist (texto), Cost, Ok, Reason } }
function AirCombatHud.showQuantum(view: View, entries: { { [string]: any } }, info: string, onPick: (string) -> (), onClose: () -> ())
	local Q = view.Quantum
	for _, r in Q.Rows do
		r:Destroy()
	end
	Q.Rows = {}
	put(view, Q.Info, "Text", info)
	for i, e in entries do
		local ok = e.Ok == true
		local row = create("TextButton", { Name = "Destino_" .. tostring(e.Id), LayoutOrder = i, Size = UDim2.new(1, -8, 0, if view.Touch then 92 else 56), BackgroundColor3 = if ok then rgb(20, 40, 80) else rgb(24, 26, 34), BackgroundTransparency = 0.1, AutoButtonColor = ok, Text = "", ZIndex = 12, Parent = Q.List })
		create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = row })
		create("UIStroke", { Color = if ok then K.Violet else K.Locked, Thickness = 1.5, Transparency = 0.3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = row })
		label({ Name = "Nombre", Position = UDim2.fromOffset(14, 4), Size = UDim2.new(0.62, -14, 0, 24), Text = e.Name, TextSize = 18, TextColor3 = if ok then K.White else K.Muted, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 13, Parent = row })
		label({ Name = "Tipo", Position = UDim2.fromOffset(14, 28), Size = UDim2.new(0.62, -14, 0, 20), Text = if ok then e.Kind else ("🔒 " .. (e.Reason or "")), TextSize = 13, TextColor3 = if ok then K.Muted else K.Boost, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 13, Parent = row })
		label({ Name = "Datos", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 8), Size = UDim2.new(0.38, 0, 0, 40), Text = ("%s\n⚡ %d"):format(e.Dist or "", e.Cost or 0), TextSize = 15, TextColor3 = K.Energy, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 13, Parent = row })
		local id = e.Id
		onActivated(row, function()
			onPick(id)
		end)
		table.insert(Q.Rows, row)
	end
	if Q.CloseConn then
		Q.CloseConn:Disconnect()
	end
	Q.CloseConn = onActivated(Q.Close, onClose)
	Q.Frame.Visible = true
	-- (con mando: el primero queda elegido para moverse con la cruceta)
	pcall(function()
		local UserInputService = game:GetService("UserInputService")
		if UserInputService.GamepadEnabled and Q.Rows[1] then
			game:GetService("GuiService").SelectedObject = Q.Rows[1]
		end
	end)
end

function AirCombatHud.hideQuantum(view: View)
	local Q = view.Quantum
	if Q.Frame then
		Q.Frame.Visible = false
	end
end

function AirCombatHud.quantumOpen(view: View): boolean
	return view.Quantum.Frame ~= nil and view.Quantum.Frame.Visible == true
end

---------------------------------------------------------------------
-- Cuentas puras de antes (radar y flechas)
---------------------------------------------------------------------
-- Punto del radar de un enemigo en `pos` visto desde la nave (puro): x a la derecha, y hacia delante
-- (arriba en el radar), en -1..1; lo que pasa del alcance se queda en el borde.
function AirCombatHud.radarPoint(ship: CFrame, pos: Vector3, range: number?): Vector2
	return ShipHudLayout.radarPoint(ship, pos, range or AirCombatHud.RadarRange)
end

-- Flecha del borde hacia un enemigo que no se ve (puro). screen = punto en la pantalla (como
-- WorldToViewportPoint), behind = está detrás de la cámara. Devuelve la posición (dentro del margen) y
-- el giro de la flecha en grados (0 = ▲ hacia arriba).
function AirCombatHud.edgeArrow(screen: Vector2, viewport: Vector2, behind: boolean, margin: number?): (Vector2, number)
	local m = margin or 48
	local center = viewport / 2
	local d = screen - center
	if behind then
		d = -d
		if d.Magnitude < 1 then
			d = Vector2.new(0, 1)
		end
	end
	if d.Magnitude < 1e-3 then
		d = Vector2.new(0, -1)
	end
	local half = center - Vector2.new(m, m)
	local scale = math.min(if math.abs(d.X) > 1e-6 then half.X / math.abs(d.X) else math.huge, if math.abs(d.Y) > 1e-6 then half.Y / math.abs(d.Y) else math.huge)
	local p = center + d * scale
	local angle = math.deg(math.atan2(d.X, -d.Y))
	return p, angle
end

-- ¿Está este punto de la pantalla dentro (con margen)?
function AirCombatHud.onScreen(screen: Vector2, viewport: Vector2, behind: boolean, margin: number?): boolean
	local m = margin or 20
	return not behind and screen.X >= m and screen.Y >= m and screen.X <= viewport.X - m and screen.Y <= viewport.Y - m
end

return AirCombatHud
