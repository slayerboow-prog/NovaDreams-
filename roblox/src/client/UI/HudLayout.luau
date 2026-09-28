-- HudLayout: dónde va cada pieza del HUD, calculado en un solo sitio para que nada se pise.
--
--   Arriba a la izquierda  -> tu estado (debajo de los botones de Roblox)
--   Arriba en el centro    -> la cápsula de la hora, la fecha y el tiempo
--   Arriba a la derecha    -> minimapa y, a su derecha, el menú rápido (o el botón del teléfono)
--   Derecha                -> la misión, debajo del minimapa
--   Abajo a la izquierda   -> el menú de comandos (en el móvil, encima del joystick)
--   Abajo en el centro     -> la barra rápida del inventario
--   Abajo a la derecha     -> los botones táctiles en racimo (en el ordenador, las teclas)
--   Junto a la misión      -> el botón ❓ "¿Qué hago ahora?" (a su izquierda, bajo el minimapa)
--   Abajo en el centro     -> encima de la barra rápida: la tarjeta de los primeros pasos, pistas y consejos
--
-- Todo se mide en "unidades de lienzo": cada pantalla del HUD lleva un UIScale con HudLayout.scale()
-- y el lienzo mide ViewportSize / escala (unos 1700 de ancho siempre; en el móvil unos 785 de alto).
-- compute() es puro (no toca Roblox más que para leer Vector2/UDim2): así lo prueba scripts/test-hud.luau.

local HudLayout = {}

export type Placement = { Anchor: Vector2, Position: UDim2, Size: Vector2 }
export type Options = { Touch: boolean?, Inset: number?, QuickOpen: boolean? }
export type Layout = {
	Scale: number,
	Canvas: Vector2,
	Touch: boolean,
	QuickOpen: boolean,
	Items: { [string]: Placement },
	Slots: { [string]: Placement },
	CommandRows: number,
	CommandTop: number, -- hasta dónde puede crecer el menú de comandos al desplegarlo
}

local MARGIN = 16
local WIDTH = 1700 -- ancho de diseño
local HEIGHT = 780 -- alto mínimo de diseño (móvil apaisado)

-- Medidas (en unidades de lienzo)
HudLayout.Sizes = {
	Status = Vector2.new(440, 168),
	Clock = Vector2.new(600, 64),
	Minimap = 210, -- diámetro del círculo
	MinimapLabel = 24, -- el nombre de la zona, debajo
	Quick = Vector2.new(280, 178),
	QuickTab = Vector2.new(64, 64),
	Mission = Vector2.new(440, 110),
	CommandWidth = 340,
	CommandHeader = 34,
	CommandPitch = 40, -- alto de cada fila + separación
	CommandFooter = 26, -- el desplegable ⌄ y el relleno
	CommandHint = 18, -- (ordenador) la línea de teclas
	Hotbar = Vector2.new(718, 86),
	Joystick = 210,
	Hints = Vector2.new(300, 196),
	Gps = Vector2.new(440, 58), -- indicación del GPS, bajo la cápsula de la hora
	Help = 76, -- diámetro del botón ❓ "¿Qué hago ahora?"
	Guide = Vector2.new(640, 150), -- tarjeta de los primeros pasos, pistas y consejos
}

-- Racimo de botones táctiles (abajo a la derecha): centro de cada hueco respecto al de Ataque y su radio.
-- Igual que la imagen de referencia: Interactuar arriba; Correr, Defensa y Saltar en fila; Gestos a la
-- izquierda del Ataque grande; Esquivar abajo a la izquierda y Fijar objetivo a la derecha, un poco más abajo.
-- Los botones de contexto (linterna, foto, piedra, bajarse…) van en una columna a la izquierda.
HudLayout.Cluster = {
	Ataque = { 0, 0, 64 },
	Interactuar = { -60, -225, 44 },
	Correr = { -178, -128, 44 },
	Defender = { -62, -128, 44 },
	Saltar = { 62, -128, 46 },
	Gestos = { -175, -12, 44 },
	Esquivar = { -120, 82, 44 },
	Fijar = { 96, 72, 32 },
}
HudLayout.ExtraSlots = 5
local EXTRA_X, EXTRA_R, EXTRA_STEP, EXTRA_FIRST = -285, 32, 72, -196
local CLUSTER_RIGHT = 128 -- lo que sobresale el racimo a la derecha del centro del Ataque
local CLUSTER_BOTTOM = 124 -- y por debajo

function HudLayout.scaleFor(viewport: Vector2): number
	return math.clamp(math.min(viewport.Y / HEIGHT, viewport.X / WIDTH), 0.45, 1.3)
end

local function place(anchor: Vector2, position: UDim2, size: Vector2): Placement
	return { Anchor = anchor, Position = position, Size = size }
end

-- Filas visibles del menú de comandos (sin desplegar)
function HudLayout.commandHeight(rows: number, touch: boolean): number
	local s = HudLayout.Sizes
	return s.CommandHeader + rows * s.CommandPitch + s.CommandFooter + (if touch then 0 else s.CommandHint)
end

function HudLayout.compute(viewport: Vector2, options: Options?): Layout
	local opts = options or {}
	local touch = opts.Touch == true
	local scale = HudLayout.scaleFor(viewport)
	local canvas = viewport / scale
	local inset = (opts.Inset or 58) / scale
	local s = HudLayout.Sizes
	local W, H = canvas.X, canvas.Y
	local items: { [string]: Placement } = {}
	local slots: { [string]: Placement } = {}

	-- Arriba
	local statusTop = math.max(inset + 4, 64)
	items.Status = place(Vector2.new(0, 0), UDim2.fromOffset(MARGIN, statusTop), s.Status)
	items.Clock = place(Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 8), s.Clock)
	local quickOpen = opts.QuickOpen ~= false
	items.Quick = place(Vector2.new(1, 0), UDim2.new(1, -MARGIN, 0, 10), s.Quick)
	items.QuickTab = place(Vector2.new(1, 0), UDim2.new(1, -MARGIN, 0, 10), s.QuickTab)
	local miniRight = MARGIN + s.Quick.X + 12
	items.Minimap = place(Vector2.new(1, 0), UDim2.new(1, -miniRight, 0, 10), Vector2.new(s.Minimap, s.Minimap + s.MinimapLabel))
	local missionTop = 10 + s.Minimap + s.MinimapLabel + 10
	items.Mission = place(Vector2.new(1, 0), UDim2.new(1, -MARGIN, 0, missionTop), s.Mission)
	-- El botón ❓ a la izquierda de la misión (siempre ahí, aunque no haya misión)
	local helpCenterX = MARGIN + s.Mission.X + 12 + s.Help / 2
	items.Help = place(Vector2.new(0.5, 0.5), UDim2.new(1, -helpCenterX, 0, missionTop + s.Help / 2), Vector2.new(s.Help, s.Help))
	-- Debajo del reloj: la indicación del GPS, avisos fijos (examen…) y estrellas de búsqueda
	items.Gps = place(Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 8 + s.Clock.Y + 8), s.Gps)
	items.Activity = place(Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 8 + s.Clock.Y + 8 + s.Gps.Y + 8), Vector2.new(0, 34))
	items.Wanted = place(Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 8 + s.Clock.Y + 8 + s.Gps.Y + 50), Vector2.new(230, 40))

	-- Abajo
	items.Hotbar = place(Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -MARGIN), s.Hotbar)
	-- Encima de la barra rápida: tarjeta de los primeros pasos, pistas y consejos (Controllers/Guide)
	items.Guide = place(Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -(MARGIN + s.Hotbar.Y + 14)), s.Guide)
	local statusBottom = statusTop + s.Status.Y
	local commandBottom: number
	if touch then
		local stick = s.Joystick
		items.Joystick = place(Vector2.new(0, 1), UDim2.new(0, 145, 1, -20), Vector2.new(stick, stick))
		commandBottom = 20 + stick + 10
	else
		commandBottom = MARGIN
	end
	-- Cuántas filas caben entre tu estado y el hueco de abajo (4 o 5, las demás con ⌄)
	local room = H - commandBottom - (statusBottom + 12)
	local rows = if touch then 4 else 5
	while rows > 2 and HudLayout.commandHeight(rows, touch) > room do
		rows -= 1
	end
	items.Commands = place(Vector2.new(0, 1), UDim2.new(0, MARGIN, 1, -commandBottom), Vector2.new(s.CommandWidth, HudLayout.commandHeight(rows, touch)))

	if touch then
		-- Racimo táctil (centro del Ataque)
		local ax, ay = W - MARGIN - CLUSTER_RIGHT, H - MARGIN - CLUSTER_BOTTOM
		for id, def in HudLayout.Cluster do
			local r = def[3]
			slots[id] = place(Vector2.new(0.5, 0.5), UDim2.new(1, -(W - (ax + def[1])), 1, -(H - (ay + def[2]))), Vector2.new(r * 2, r * 2))
		end
		-- El botón ❓ también es un hueco (TouchLayout lo dibuja como los demás botones redondos)
		slots.Ayuda = items.Help
		for i = 1, HudLayout.ExtraSlots do
			local y = ay + EXTRA_FIRST + (i - 1) * EXTRA_STEP
			slots["Extra" .. i] = place(Vector2.new(0.5, 0.5), UDim2.new(1, -(W - (ax + EXTRA_X)), 1, -(H - y)), Vector2.new(EXTRA_R * 2, EXTRA_R * 2))
		end
	else
		items.Hints = place(Vector2.new(1, 1), UDim2.new(1, -MARGIN, 1, -MARGIN), s.Hints)
	end

	return {
		Scale = scale,
		Canvas = canvas,
		Touch = touch,
		QuickOpen = quickOpen,
		Items = items,
		Slots = slots,
		CommandRows = rows,
		CommandTop = statusBottom + 12,
	}
end

-- Rectángulo (x, y, ancho, alto) en el lienzo de una colocación
function HudLayout.rect(p: Placement, canvas: Vector2): { X: number, Y: number, W: number, H: number }
	local x = p.Position.X.Scale * canvas.X + p.Position.X.Offset - p.Anchor.X * p.Size.X
	local y = p.Position.Y.Scale * canvas.Y + p.Position.Y.Offset - p.Anchor.Y * p.Size.Y
	return { X = x, Y = y, W = p.Size.X, H = p.Size.Y }
end

function HudLayout.overlaps(a: { X: number, Y: number, W: number, H: number }, b: { X: number, Y: number, W: number, H: number }): boolean
	return a.X < b.X + b.W and b.X < a.X + a.W and a.Y < b.Y + b.H and b.Y < a.Y + a.H
end

-- Coloca un objeto (posición, ancla y, si se pide, tamaño)
function HudLayout.apply(object: GuiObject, p: Placement, keepSize: boolean?)
	object.AnchorPoint = p.Anchor
	object.Position = p.Position
	if not keepSize then
		object.Size = UDim2.fromOffset(p.Size.X, p.Size.Y)
	end
end

---------------------------------------------------------------------
-- Estado en vivo (la pantalla de verdad): lo usan el HUD, el minimapa, la barra rápida, los comandos,
-- el joystick y los botones táctiles. Cada uno se recoloca cuando cambia algo.
---------------------------------------------------------------------
local current: Layout? = nil
local listeners: { (Layout) -> () } = {}
local options: Options = { QuickOpen = nil }
local started = false
local scalers: { UIScale } = {}

local function touchOnly(): boolean
	local UserInputService = game:GetService("UserInputService")
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function recompute()
	local camera = workspace.CurrentCamera
	local viewport = if camera then camera.ViewportSize else Vector2.new(1920, 1080)
	local inset = 58
	pcall(function()
		inset = game:GetService("GuiService"):GetGuiInset().Y
	end)
	local touch = touchOnly()
	if options.QuickOpen == nil then
		-- En el móvil el menú rápido empieza cerrado (se abre con el botón del teléfono)
		options.QuickOpen = not touch
	end
	current = HudLayout.compute(viewport, { Touch = touch, Inset = inset, QuickOpen = options.QuickOpen })
	for _, scaler in scalers do
		scaler.Scale = (current :: Layout).Scale
	end
	for _, listener in table.clone(listeners) do
		listener(current :: Layout)
	end
end

function HudLayout.start()
	if started then
		return
	end
	started = true
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(recompute)
	end
	recompute()
end

function HudLayout.current(): Layout
	if not current then
		recompute()
	end
	return current :: Layout
end

function HudLayout.scale(): number
	return HudLayout.current().Scale
end

-- Llama a fn ahora y cada vez que cambie la colocación
function HudLayout.onChanged(fn: (Layout) -> ())
	table.insert(listeners, fn)
	fn(HudLayout.current())
end

-- Pone a una pantalla la escala del HUD (y la mantiene al girar el móvil o cambiar la ventana)
function HudLayout.scaleGui(gui: ScreenGui): UIScale
	local scaler = Instance.new("UIScale")
	scaler.Scale = HudLayout.scale()
	scaler.Parent = gui
	table.insert(scalers, scaler)
	return scaler
end

function HudLayout.setQuickOpen(open: boolean)
	if options.QuickOpen ~= open then
		options.QuickOpen = open
		recompute()
	end
end

-- (pruebas) empezar de cero
function HudLayout._reset()
	current = nil
	listeners = {}
	options = { QuickOpen = nil }
	started = false
	scalers = {}
end

return HudLayout
