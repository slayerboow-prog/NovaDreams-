-- TopStack: los letreros de ARRIBA EN EL CENTRO (marcadores de un deporte, la pista del paso de la
-- misión, el «¡Buen pase!», el panel del karting o del skatepark, el aviso de la Grieta del cielo…),
-- puestos en una sola columna para que nunca se pisen entre ellos ni con el HUD.
--
-- Lo que pidió el dueño («hay mucha información junta»: el marcador de los pases, el aviso de la
-- grieta, su flecha morada y la narración de la escena, todo a la vez y uno encima de otro):
--   * La columna empieza donde empiezan los avisos del HUD (HudLayout.Items.Toasts: debajo del reloj,
--     el GPS, los avisos fijos y las estrellas de búsqueda) y baja de uno en uno, con TopStack.Gap de
--     separación, por orden de prioridad: Story (historia) > Mission (lo que estás jugando de una
--     misión o actividad) > World (avisos del mundo, como la grieta). A igual prioridad, el primero
--     que se registró.
--   * No baja más de TopStack.MaxBottom de la pantalla (el centro es para jugar): lo que no quepa
--     espera (se ve en cuanto se va el de encima; el de más prioridad siempre se ve). Así en el móvil
--     pequeño (640x360) se ve uno cada vez.
--   * En conversaciones, narraciones, escenas de cine y el prólogo NO se ve ninguno (quiet()): vuelven
--     solos al acabar si siguen pedidos.
--   * Los avisos normales del HUD (Hud.toast) van debajo de la columna (TopStack.bottom()).
--   * Las flechas que señalan (la de la grieta va dentro de su propio letrero; la de los primeros
--     pasos, Controllers/Guide) no se ponen encima de los letreros (TopStack.shownRects()).
--   * A los mandos de un avión (TopStack.setPiloting("Flight"), Controllers/Flying) el panel de
--     instrumentos (HudLayout.Items.Flight) es intocable: la columna empieza debajo de él y los avisos
--     del mundo (World: la grieta del cielo y su flecha) esperan a que aterrices (queja del dueño: el
--     aviso «La grieta del cielo se está cerrando…» y su flecha morada tapaban VEL/ALT/RUMBO). Los de
--     historia y misión salen debajo del panel; los avisos del HUD (Hud.toast), debajo de todo.
--     Con el HUD de la nave (los aviones lo usan: TopStack.setPiloting("ShipHud")) el panel que no se
--     tapa es el de arriba en el centro de UI/ShipHudLayout: brújula (B) y avisos (J).
-- Los tamaños NO cambian (nada se encoge): solo dónde va cada uno y si se ve.
--
-- Uso: TopStack.register(frame, TopStack.Priority.Mission) una vez; después TopStack.set(frame, true /
-- false) en lugar de frame.Visible = …, y TopStack.wanted(frame) en lugar de leer frame.Visible.
-- arrange() es puro (lo prueba scripts/test-hud.luau en 932x430, 844x390 y 640x360).

local HudLayout = require(script.Parent.HudLayout)
local ShipHudLayout = require(script.Parent.ShipHudLayout)

local TopStack = {}

TopStack.Priority = { Story = 3, Mission = 2, World = 1 }
TopStack.Gap = 8 -- separación entre letreros (píxeles)
TopStack.MaxBottom = 0.66 -- la columna no baja de aquí (fracción del alto de la pantalla)
TopStack.QuietAttributes = { "InDialogue", "InCinematic", "InPrologue" }

export type Rect = { X: number, Y: number, W: number, H: number }
export type Entry = { Id: string, Priority: number, Order: number?, W: number, H: number }
export type Placed = { X: number, Y: number, W: number, H: number, Shown: boolean }
export type Options = { Touch: boolean?, Inset: number?, Quiet: boolean?, Piloting: string? }

-- El panel de arriba en el centro del HUD de la nave (zonas B, C y J de UI/ShipHudLayout), en el lienzo
local function shipPanel(viewport: Vector2, opts: Options): (Rect, number)
	local l = ShipHudLayout.compute(viewport, { Touch = opts.Touch, Inset = opts.Inset, Vehicle = "Plane" })
	local x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge
	for _, name in { "B", "C", "J" } do
		local r = l.Zones[name]
		if r then
			x0, y0 = math.min(x0, r.X), math.min(y0, r.Y)
			x1, y1 = math.max(x1, r.X + r.W), math.max(y1, r.Y + r.H)
		end
	end
	return { X = x0, Y = y0, W = x1 - x0, H = y1 - y0 }, l.Scale
end

-- Dónde empieza la columna (píxeles desde arriba de la pantalla, contando la franja de Roblox)
function TopStack.origin(viewport: Vector2, options: Options?): number
	local opts = options or {}
	local layout = HudLayout.compute(viewport, { Touch = opts.Touch, Inset = opts.Inset })
	local toasts = layout.Items.Toasts
	local top = math.ceil(toasts.Position.Y.Offset * layout.Scale)
	-- (pilotando: debajo del panel de instrumentos)
	if opts.Piloting == "ShipHud" then
		-- (justo debajo de la brújula y los avisos del HUD de vuelo: el sitio de los avisos normales queda
		-- más abajo y el panel de la invasión tapaba el centro; captura de v117)
		local r, k = shipPanel(viewport, opts)
		return math.ceil((r.Y + r.H) * k + TopStack.Gap)
	end
	local panel = opts.Piloting and layout.Items[opts.Piloting]
	if panel then
		local r = HudLayout.rect(panel, layout.Canvas)
		top = math.max(top, math.ceil((r.Y + r.H) * layout.Scale + TopStack.Gap))
	end
	return top
end

-- El panel que no se puede tapar mientras pilotas (píxeles), o nil
function TopStack.panelRect(viewport: Vector2, options: Options?): Rect?
	local opts = options or {}
	if opts.Piloting == "ShipHud" then
		local r, k = shipPanel(viewport, opts)
		return { X = r.X * k, Y = r.Y * k, W = r.W * k, H = r.H * k }
	end
	local layout = HudLayout.compute(viewport, { Touch = opts.Touch, Inset = opts.Inset })
	local panel = opts.Piloting and layout.Items[opts.Piloting]
	if not panel then
		return nil
	end
	local r = HudLayout.rect(panel, layout.Canvas)
	local k = layout.Scale
	return { X = r.X * k, Y = r.Y * k, W = r.W * k, H = r.H * k }
end

-- Las piezas fijas del HUD que la columna no puede pisar (píxeles): tu estado, el reloj, el GPS, los
-- avisos fijos, las estrellas, el minimapa, la misión y el botón ❓ (un letrero ancho baja hasta
-- debajo de la misión en lugar de taparla)
TopStack.Obstacles = { "Status", "Clock", "Gps", "Activity", "Wanted", "Minimap", "Mission", "Help" }
function TopStack.obstacles(viewport: Vector2, options: Options?): { Rect }
	local opts = options or {}
	-- (con el HUD de vuelo, el de Valmar está escondido (UI/FlightFocus): solo cuenta su panel de arriba)
	if opts.Piloting == "ShipHud" then
		local panel = TopStack.panelRect(viewport, opts)
		return if panel then { panel } else {}
	end
	local layout = HudLayout.compute(viewport, { Touch = opts.Touch, Inset = opts.Inset })
	local k = layout.Scale
	local list = {}
	for _, name in TopStack.Obstacles do
		local p = layout.Items[name]
		if p then
			local r = HudLayout.rect(p, layout.Canvas)
			-- (Activity mide 0 de ancho: crece con lo que lleve; se reserva el ancho del GPS)
			if r.W <= 0 then
				local gps = HudLayout.rect(layout.Items.Gps, layout.Canvas)
				r = { X = gps.X, Y = r.Y, W = gps.W, H = r.H }
			end
			table.insert(list, { X = r.X * k, Y = r.Y * k, W = r.W * k, H = r.H * k })
		end
	end
	local panel = TopStack.panelRect(viewport, opts)
	if panel then
		table.insert(list, panel)
	end
	return list
end

-- Lo que se ve y dónde (píxeles). Devuelve también el borde de abajo de la columna.
function TopStack.arrange(viewport: Vector2, entries: { Entry }, options: Options?): ({ [string]: Placed }, number)
	local opts = options or {}
	local top = TopStack.origin(viewport, opts)
	local blocks = TopStack.obstacles(viewport, opts)
	local placed: { [string]: Placed } = {}
	local sorted = table.clone(entries)
	table.sort(sorted, function(a, b)
		if a.Priority ~= b.Priority then
			return a.Priority > b.Priority
		end
		return (a.Order or 0) < (b.Order or 0)
	end)
	local limit = math.floor(viewport.Y * TopStack.MaxBottom)
	local y = top
	local any = false
	local full = false
	for _, e in sorted do
		local w, h = math.max(0, e.W), math.max(0, e.H)
		-- (pilotando, los avisos del mundo esperan a que aterrices: no tapan nada ni empujan a nadie)
		if opts.Piloting and e.Priority <= TopStack.Priority.World then
			placed[e.Id] = { X = math.floor(viewport.X / 2 - w / 2), Y = top, W = w, H = h, Shown = false }
			continue
		end
		local x = math.floor(viewport.X / 2 - w / 2)
		-- (si pisaría una pieza del HUD, baja hasta debajo de ella)
		local at = y
		for _ = 1, #blocks + 1 do
			local moved = false
			for _, b in blocks do
				if HudLayout.overlaps({ X = x, Y = at, W = w, H = h }, b) then
					at = math.ceil(b.Y + b.H + TopStack.Gap)
					moved = true
				end
			end
			if not moved then
				break
			end
		end
		-- (en orden: si uno no cabe, los de después esperan detrás de él, aunque sean más pequeños)
		local fits = at + h <= limit and not full
		if fits or not any then
			y = at
		end
		if not opts.Quiet and (fits or not any) then
			placed[e.Id] = { X = x, Y = y, W = w, H = h, Shown = true }
			y += h + TopStack.Gap
			any = true
		else
			placed[e.Id] = { X = x, Y = y, W = w, H = h, Shown = false }
			full = full or not opts.Quiet
		end
	end
	return placed, if any then y - TopStack.Gap else top
end

---------------------------------------------------------------------
-- En vivo
---------------------------------------------------------------------
type Slot = { Object: GuiObject, Id: string, Priority: number, Order: number, Wanted: boolean, MinHeight: number }

local slots: { [GuiObject]: Slot } = {}
local nextOrder = 0
local busy = false
local started = false
local bottomPx = 0
local shown: { Rect } = {}
local listeners: { () -> () } = {}
local refreshing = false
local pending = false
local signature = ""
local piloting: string? = nil -- a los mandos de un avión: el panel que no se tapa (HudLayout.Items)

local function localPlayer(): Player?
	local ok, players = pcall(function()
		return game:GetService("Players")
	end)
	return if ok and players then players.LocalPlayer else nil
end

-- ¿Hay una conversación, una narración, una escena de cine o el prólogo? (entonces no se ve nada)
function TopStack.quiet(): boolean
	if busy then
		return true
	end
	local player = localPlayer()
	if not player then
		return false
	end
	for _, name in TopStack.QuietAttributes do
		local value = player:GetAttribute(name)
		if value ~= nil and value ~= false then
			return true
		end
	end
	return false
end

local function viewport(): Vector2
	local camera = workspace.CurrentCamera
	local size = camera and camera.ViewportSize
	if typeof(size) == "Vector2" and size.X > 0 and size.Y > 0 then
		return size
	end
	return Vector2.new(1920, 1080)
end

local function inset(): number
	local value = 58
	pcall(function()
		value = game:GetService("GuiService"):GetGuiInset().Y
	end)
	return value
end

local function touchOnly(): boolean
	local ok, value = pcall(function()
		local UserInputService = game:GetService("UserInputService")
		return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	end)
	return ok and value == true
end

-- La pantalla del letrero: si no se salta la franja de arriba, sus posiciones empiezan debajo de ella;
-- y si lleva escala (UIScale), sus medidas son de lienzo
local function screenOf(object: Instance): (number, number)
	local node: Instance? = object.Parent
	while node and not node:IsA("LayerCollector") do
		node = node.Parent
	end
	local offset, k = 0, 1
	if node then
		local okInset, ignore = pcall(function()
			return (node :: any).IgnoreGuiInset
		end)
		if okInset and ignore == false then
			offset = inset()
		end
		local scaler = node:FindFirstChildOfClass("UIScale")
		if scaler and scaler.Scale > 0 then
			k = scaler.Scale
		end
	end
	return offset, k
end

local function sizeOf(slot: Slot, k: number): (number, number)
	local object = slot.Object
	local w, h = 0, 0
	local okAbs, absolute = pcall(function()
		return object.AbsoluteSize
	end)
	if okAbs and typeof(absolute) == "Vector2" and absolute.X > 0 and absolute.Y > 0 then
		w, h = absolute.X, absolute.Y
	else
		w, h = object.Size.X.Offset * k, object.Size.Y.Offset * k
	end
	return w, math.max(h, slot.MinHeight * k)
end

function TopStack.refresh()
	if refreshing then
		pending = true
		return
	end
	refreshing = true
	local changed = false
	repeat
		pending = false
		local entries: { Entry } = {}
		local info: { [string]: { Slot: Slot, Offset: number, K: number } } = {}
		for object, slot in slots do
			if object.Parent == nil then
				slots[object] = nil
				continue
			end
			if slot.Wanted then
				local offset, k = screenOf(object)
				local w, h = sizeOf(slot, k)
				table.insert(entries, { Id = slot.Id, Priority = slot.Priority, Order = slot.Order, W = w, H = h })
				info[slot.Id] = { Slot = slot, Offset = offset, K = k }
			end
		end
		local before = signature
		local view = viewport()
		local placed, bottom = TopStack.arrange(view, entries, { Touch = touchOnly(), Inset = inset(), Quiet = TopStack.quiet(), Piloting = piloting })
		shown = {}
		local parts = {}
		for object, slot in slots do
			local p = placed[slot.Id]
			local data = info[slot.Id]
			if p and data and p.Shown then
				object.AnchorPoint = Vector2.new(0.5, 0)
				object.Position = UDim2.new(0.5, 0, 0, math.floor((p.Y - data.Offset) / data.K))
				object.Visible = true
				table.insert(shown, { X = p.X, Y = p.Y, W = p.W, H = p.H })
				table.insert(parts, ("%.0f:%.0f:%.0f:%.0f"):format(p.X, p.Y, p.W, p.H))
			elseif object.Visible then
				object.Visible = false
			end
		end
		bottomPx = bottom
		table.sort(parts)
		signature = table.concat(parts, "|") .. "/" .. tostring(bottom)
		changed = changed or signature ~= before
	until not pending
	refreshing = false
	-- (los demás —los avisos del HUD, la flecha de los primeros pasos— solo se recolocan si algo cambió)
	if changed then
		for _, listener in table.clone(listeners) do
			task.spawn(listener)
		end
	end
end

local function start()
	if started then
		return
	end
	started = true
	pcall(function()
		local camera = workspace.CurrentCamera
		if camera then
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(TopStack.refresh)
		end
	end)
	local player = localPlayer()
	if player then
		for _, name in TopStack.QuietAttributes do
			player:GetAttributeChangedSignal(name):Connect(TopStack.refresh)
		end
	end
end

-- Pone un letrero en la columna. opts.Id: su nombre (si no, el del objeto); opts.MinHeight: alto mínimo
-- (para los que crecen solos con AutomaticSize y aún no se han medido)
function TopStack.register(object: GuiObject, priority: number?, opts: { Id: string?, MinHeight: number? }?): GuiObject
	local o = opts or {}
	nextOrder += 1
	local id = (o.Id or object.Name) .. "#" .. nextOrder
	slots[object] = { Object = object, Id = id, Priority = priority or TopStack.Priority.Mission, Order = nextOrder, Wanted = object.Visible, MinHeight = o.MinHeight or 0 }
	object.AnchorPoint = Vector2.new(0.5, 0)
	pcall(function()
		object:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			local slot = slots[object]
			if slot and slot.Wanted then
				TopStack.refresh()
			end
		end)
	end)
	start()
	TopStack.refresh()
	return object
end

-- En lugar de object.Visible = visible
function TopStack.set(object: GuiObject?, visible: boolean)
	if not object then
		return
	end
	local slot = slots[object]
	if not slot then
		object.Visible = visible
		return
	end
	if slot.Wanted == visible then
		return
	end
	slot.Wanted = visible
	TopStack.refresh()
end

-- ¿Lo ha pedido su dueño? (aunque ahora no se vea porque hay una escena o no cabe)
function TopStack.wanted(object: GuiObject?): boolean
	if not object then
		return false
	end
	local slot = slots[object]
	if slot then
		return slot.Wanted
	end
	return object.Visible
end

-- Main.client: en conversaciones y cinemáticas (además de los atributos de quiet())
function TopStack.setBusy(value: boolean)
	if busy ~= value then
		busy = value
		TopStack.refresh()
	end
end

-- A los mandos de un avión (Controllers/Flying): panel = el nombre de su sitio en HudLayout.Items
-- ("Flight"); nil al bajarse
function TopStack.setPiloting(panel: string?)
	if piloting ~= panel then
		piloting = panel
		TopStack.refresh()
	end
end

function TopStack.isPiloting(): boolean
	return piloting ~= nil
end

-- Borde de abajo de la columna (píxeles desde arriba de la pantalla; pilotando, como poco debajo del panel)
function TopStack.bottom(): number
	return bottomPx
end

-- Rectángulos (píxeles) de los letreros que se ven ahora
function TopStack.shownRects(): { Rect }
	return table.clone(shown)
end

function TopStack.onChanged(fn: () -> ())
	table.insert(listeners, fn)
end

-- (pruebas) empezar de cero
function TopStack._reset()
	slots = {}
	nextOrder = 0
	busy = false
	started = false
	piloting = nil
	bottomPx = 0
	shown = {}
	listeners = {}
	signature = ""
end

return TopStack
