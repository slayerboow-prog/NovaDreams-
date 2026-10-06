-- HudLayout: dónde va cada pieza del HUD, calculado en un solo sitio para que nada se pise.
--
--   Arriba a la izquierda  -> tu estado (debajo de los botones de Roblox)
--   Arriba en el centro    -> la cápsula de la hora, la fecha y el tiempo (y el GPS justo debajo)
--   Arriba a la derecha    -> el minimapa, pegado a la esquina (las apps del antiguo menú rápido
--                             están ahora en el menú de comandos)
--   Junto al minimapa      -> con un arma en la mano, las balas («6 / 120», el arma y SEMI/AUTO), a su
--                             izquierda, arriba: ni encima del minimapa ni de los botones de disparar
--   Derecha                -> la misión, justo debajo del minimapa
--   Abajo a la izquierda   -> el ValPhone (UI/Phone): en el ordenador asoma pegado a la esquina; en el
--                             móvil lo abre el botón «Teléfono», debajo del joystick, junto a
--                             «Inventario» (HudLayout.Left). Al tocarlo (Tab / Select) sube entero con todas
--                             las apps (Items.Phone, Items.PhoneOpen). Al volante o a los mandos de un
--                             avión asoma debajo de tu estado (Items.PhoneDrive: abajo van las flechas).
--                             Sus notificaciones bajan encima (Items.PhoneBanner). El resto de la
--                             izquierda queda libre (ya no está el menú COMANDOS)
--   Junto a los botones    -> la tira de acciones de AHORA (Hablar con Marta, Comprar billete,
--                             Disparar…: Commands/ContextStrip). Móvil: la burbuja «Acciones» del
--                             racimo, a la izquierda de Interactuar (Cluster.Contexto), y su lista
--                             (Items.Context) se abre a su izquierda. Ordenador: encima de las teclas
--   Abajo en el centro     -> la barra rápida del inventario (en el móvil, pegada al borde)
--   Abajo a la derecha     -> los botones táctiles en racimo, pegados a la esquina (en el ordenador,
--                             las teclas). Al volante (móvil): pedales, freno de mano, luces e
--                             intermitentes a la derecha y las flechas de girar a la izquierda (DriveSlots)
--   Junto a la misión     -> el botón ❓ "¿Qué hago ahora?" (a su izquierda, bajo el minimapa)
--   Abajo en el centro     -> encima de la barra rápida: la tarjeta de los primeros pasos, pistas y consejos
--                             (y, en el metro, el panel del tren: Items.Ride)
--
-- Todo se mide en "unidades de lienzo": cada pantalla del HUD lleva un UIScale con HudLayout.scale()
-- y el lienzo mide ViewportSize / escala (unos 1700 de ancho siempre; en el móvil unos 785 de alto).
-- compute() es puro (no toca Roblox más que para leer Vector2/UDim2): así lo prueba scripts/test-hud.luau.

local HudLayout = {}

export type Placement = { Anchor: Vector2, Position: UDim2, Size: Vector2 }
export type Options = { Touch: boolean?, Inset: number? }
export type Layout = {
	Scale: number,
	Canvas: Vector2,
	Touch: boolean,
	Items: { [string]: Placement },
	Slots: { [string]: Placement },
	DriveSlots: { [string]: Placement }, -- (móvil, al volante: HudLayout.Drive y DriveLeft)
	FlySlots: { [string]: Placement }, -- (móvil, a los mandos de un avión: HudLayout.Fly)
	ContextRows: number, -- acciones que caben a la vista en la tira (Items.Context)
}

local MARGIN = 16
local WIDTH = 1700 -- ancho de diseño
local HEIGHT = 780 -- alto mínimo de diseño (móvil apaisado)
local ROBLOX_BUTTONS = 250 -- ancho (en píxeles reales) de los botones de Roblox de arriba a la izquierda

-- Medidas (en unidades de lienzo)
HudLayout.Sizes = {
	Status = Vector2.new(440, 168),
	Clock = Vector2.new(600, 64),
	Minimap = 210, -- diámetro del círculo
	MinimapLabel = 24, -- el nombre de la zona, debajo
	Mission = Vector2.new(440, 110),
	LeftColumn = 410, -- columna izquierda que no usan los paneles de trabajo en el móvil (jobArea)
	PhonePeek = Vector2.new(112, 140), -- el ValPhone cerrado, asomando en la esquina
	PhoneBanner = Vector2.new(340, 92), -- la notificación que baja del teléfono (cabe en la columna izquierda)
	ContextWidth = 300, -- la tira de acciones
	ContextPitch = 50, -- alto de cada acción + separación
	Hotbar = Vector2.new(718, 86),
	Joystick = 210,
	Hints = Vector2.new(300, 196),
	Gps = Vector2.new(440, 58), -- indicación del GPS, bajo la cápsula de la hora
	Help = 76, -- diámetro del botón ❓ "¿Qué hago ahora?"
	Guide = Vector2.new(640, 150), -- tarjeta de los primeros pasos, pistas y consejos
	Ammo = Vector2.new(210, 64), -- las balas del arma (Controllers/WeaponController)
	Ride = Vector2.new(660, 176), -- panel del metro en el tren (Controllers/MetroUI): ancho y alto MÁXIMO
	Flight = Vector2.new(580, 96), -- instrumentos del avión (Controllers/Flying): velocidad, altitud, rumbo…
}

-- Racimo de botones táctiles (abajo a la derecha): centro de cada hueco respecto al de Ataque y su radio.
-- Igual que la imagen de referencia (docs/referencias/hud-movil-botones.jpg): arriba a la derecha
-- Interactuar; en la fila del medio Correr, Defensa y Saltar; abajo Agacharse, el Atacar grande en el
-- centro y Esquivar. Nada más en el racimo: lo que no sale en la referencia (Gestos, Foto) va en el
-- ValPhone, y lo de contexto (linterna, piedra, fijar en una pelea, bajarse…) en una columna pequeña a
-- la izquierda, pegada al racimo y llenándose DESDE ABAJO (Extra1 es el de abajo del todo).
-- Contexto: la burbuja «Acciones» de la tira de acciones (Commands/ContextStrip), a la izquierda de
-- Interactuar, encima de Defensa y sin tocar la misión.
-- Con un arma de fuego (estilo shooter móvil): Disparar en el hueco del Atacar, Apuntar en el de Defensa
-- (justo encima del disparo) y Recargar, con las balas, en el de Interactuar (TouchLayout: alias).
HudLayout.Cluster = {
	Ataque = { 0, 0, 64 },
	Agacharse = { -140, -4, 46 },
	Esquivar = { 136, -4, 46 },
	Correr = { -122, -130, 46 },
	Defender = { 0, -130, 46 },
	Saltar = { 122, -130, 48 },
	Interactuar = { 112, -240, 46 },
	Contexto = { -6, -244, 34 },
}
HudLayout.ExtraSlots = 5
local EXTRA_X, EXTRA_R, EXTRA_STEP, EXTRA_FIRST = -238, 30, 66, 34

-- Lado izquierdo (móvil, a pie): el joystick y, debajo, Teléfono e Inventario (botón redondo con el
-- texto al lado, docs/referencias/hud-movil-joystick.jpg). Con un arma de fuego, el segundo Disparar a
-- la derecha del joystick, un poco por encima de su centro (el pulgar izquierdo dispara mientras el
-- derecho mueve la cámara). { x, y, ancho, alto } del centro respecto a la esquina de abajo a la
-- izquierda (menos el margen).
HudLayout.Left = {
	Telefono = { 96, -42, 192, 84 },
	Inventario = { 312, -42, 212, 84 },
	DispararIzq = { 356, -252, 92, 92 },
}
local LEFT_ROW = 84 -- alto de la fila de Teléfono e Inventario
local STICK_X = 82 -- borde izquierdo del joystick (desde el margen)
-- Conduciendo (móvil, al volante): otra colocación (TouchLayout.setDriving). { x, y, ancho, alto } del
-- centro de cada hueco respecto a la esquina de abajo a la derecha (menos el margen):
--   abajo, los pedales: FRENO y el ACELERAR alto pegado a la esquina (el pulgar derecho los pisa sin
--   mirar); a su izquierda el freno de mano y las luces, y luego Bajarse y el claxon; encima de los
--   pedales, la fila de intermitentes ⬅ ⚠ ➡; y arriba, los de contexto (sirena, linterna…).
-- A la izquierda (en lugar del joystick, que se esconde) las dos flechas de girar ◀ ▶: HudLayout.DriveLeft,
-- respecto a la esquina de abajo a la izquierda. Todo cabe entre la barra rápida, la misión y el
-- ValPhone en todas las pantallas (scripts/test-hud.luau lo comprueba).
HudLayout.Drive = {
	Acelerar = { -60, -120, 120, 240 },
	Frenar = { -190, -90, 120, 180 },
	FrenoMano = { -310, -50, 92, 92 },
	Luces = { -310, -150, 80, 80 },
	Bajarse = { -405, -50, 80, 80 },
	Claxon = { -405, -150, 80, 80 },
	IntIzq = { -310, -285, 72, 72 },
	Emergencia = { -190, -285, 72, 72 },
	IntDer = { -60, -285, 72, 72 },
	Extra1 = { -405, -250, 64, 64 },
	Extra2 = { -405, -330, 64, 64 },
	Extra3 = { -310, -365, 60, 60 },
	Extra4 = { -190, -365, 60, 60 },
	Extra5 = { -60, -365, 60, 60 },
}
HudLayout.DriveLeft = {
	GiroIzq = { 85, -89, 150, 170 },
	GiroDer = { 265, -89, 150, 170 },
}
-- Volando (móvil, a los mandos de un avión: TouchLayout.setFlying). Como Drive, desde la esquina de abajo
-- a la derecha: el MOTOR + (alto) y MOTOR − pegados a la esquina; a su izquierda los FRENOS y, encima, el
-- timón ◀ ▶; luego el tren y los flaps, y en la última columna la cámara y Bajarse. El joystick de la
-- izquierda (el de andar) es la palanca: alabeo y cabeceo. Nada pisa la barra rápida ni la misión.
HudLayout.Fly = {
	MotorMas = { -60, -230, 110, 150 },
	MotorMenos = { -60, -85, 110, 120 },
	Frenos = { -190, -75, 100, 100 },
	TimonIzq = { -310, -195, 96, 96 },
	TimonDer = { -190, -195, 96, 96 },
	Tren = { -310, -75, 80, 80 },
	Flaps = { -405, -75, 72, 72 },
	Camara = { -405, -165, 72, 72 },
	Bajarse = { -405, -255, 72, 72 },
}
local CONTEXT_CAPTION = 24 -- el título «ACCIONES» encima de la tira
local CLUSTER_RIGHT = 182 -- lo que sobresale el racimo a la derecha del centro del Ataque
local CLUSTER_BOTTOM = 64 -- y por debajo

function HudLayout.scaleFor(viewport: Vector2): number
	-- Suelo 0.36: en móviles 16:9 pequeños (640x360) el lienzo sigue midiendo 1700 de ancho;
	-- con un suelo más alto el lienzo se estrecha y el minimapa pisa el reloj.
	return math.clamp(math.min(viewport.Y / HEIGHT, viewport.X / WIDTH), 0.36, 1.3)
end

local function place(anchor: Vector2, position: UDim2, size: Vector2): Placement
	return { Anchor = anchor, Position = position, Size = size }
end

-- Tamaño del ValPhone abierto en un lienzo de alto `height` (proporción de teléfono, 1:2)
function HudLayout.phoneSize(height: number): Vector2
	local h = math.clamp(math.floor(height - 130), 520, 720)
	return Vector2.new(math.floor(h * 0.5), h)
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
	local drive: { [string]: Placement } = {}
	local fly: { [string]: Placement } = {}

	-- Arriba
	local statusTop = math.max(inset + 4, 64)
	items.Status = place(Vector2.new(0, 0), UDim2.fromOffset(MARGIN, statusTop), s.Status)
	-- En móviles muy estrechos (640x360) el reloj, centrado, llega hasta los botones de Roblox de
	-- arriba a la izquierda: entonces la columna del centro (reloj, GPS, avisos) baja bajo esa barra.
	local clockTop = 8
	if W / 2 - s.Clock.X / 2 < ROBLOX_BUTTONS / scale + 8 then
		clockTop = inset + 8
	end
	items.Clock = place(Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, clockTop), s.Clock)
	-- El minimapa pegado a la esquina (con el nombre de la zona debajo)
	items.Minimap = place(Vector2.new(1, 0), UDim2.new(1, -MARGIN, 0, 10), Vector2.new(s.Minimap, s.Minimap + s.MinimapLabel))
	-- Las balas del arma, a la izquierda del minimapa (entre el reloj y el minimapa)
	items.Ammo = place(Vector2.new(1, 0), UDim2.new(1, -(MARGIN + s.Minimap + 12), 0, 10), s.Ammo)
	local missionTop = 10 + s.Minimap + s.MinimapLabel + 10
	items.Mission = place(Vector2.new(1, 0), UDim2.new(1, -MARGIN, 0, missionTop), s.Mission)
	-- El botón ❓ a la izquierda de la misión (siempre ahí, aunque no haya misión)
	local helpCenterX = MARGIN + s.Mission.X + 12 + s.Help / 2
	items.Help = place(Vector2.new(0.5, 0.5), UDim2.new(1, -helpCenterX, 0, missionTop + s.Help / 2), Vector2.new(s.Help, s.Help))
	-- Debajo del reloj: la indicación del GPS, avisos fijos (examen…) y estrellas de búsqueda
	-- (en el móvil, el GPS casi pegado al reloj: la columna del centro ocupa menos)
	local gpsTop = clockTop + s.Clock.Y + (if touch then 4 else 8)
	items.Gps = place(Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, gpsTop), s.Gps)
	items.Activity = place(Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, gpsTop + s.Gps.Y + 8), Vector2.new(0, 34))
	items.Wanted = place(Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, gpsTop + s.Gps.Y + 50), Vector2.new(230, 40))
	-- Avisos (toasts) y el cartel de zona: debajo de las estrellas, para no tapar nada de arriba
	local toastTop = gpsTop + s.Gps.Y + 50 + 40 + 12
	items.Toasts = place(Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, toastTop), Vector2.new(520, 0))
	-- Volando: los instrumentos del avión, debajo de las estrellas (arriba en el centro, siempre a la vista)
	items.Flight = place(Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, gpsTop + s.Gps.Y + 50 + 40 + 8), s.Flight)

	-- Abajo (en el móvil la barra rápida va pegada al borde de abajo)
	local hotbarGap = if touch then 8 else MARGIN
	items.Hotbar = place(Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -hotbarGap), s.Hotbar)
	-- Encima de la barra rápida: tarjeta de los primeros pasos, pistas y consejos (Controllers/Guide)
	items.Guide = place(Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -(hotbarGap + s.Hotbar.Y + 14)), s.Guide)
	-- En el metro, el panel del tren va en ese mismo sitio (la tarjeta se quita mientras vas en él: Guide)
	items.Ride = place(Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -(hotbarGap + s.Hotbar.Y + 14)), s.Ride)
	local statusBottom = statusTop + s.Status.Y
	local missionBottom = missionTop + s.Mission.Y
	-- El ValPhone: cerrado asoma en la esquina de abajo a la izquierda (en el móvil, a la izquierda del
	-- joystick); abierto sube entero desde ahí. Al volante (móvil) asoma debajo de tu estado: abajo van
	-- las flechas de girar. Sus notificaciones bajan encima (en el móvil, encima del joystick).
	items.Phone = place(Vector2.new(0, 1), UDim2.new(0, MARGIN, 1, -MARGIN), s.PhonePeek)
	items.PhoneOpen = place(Vector2.new(0, 1), UDim2.new(0, MARGIN, 1, -MARGIN), HudLayout.phoneSize(H))
	if touch then
		-- El joystick encima de la fila Teléfono / Inventario (el ValPhone ya no asoma: lo abre el botón
		-- Teléfono); el aviso del teléfono baja encima del joystick
		local stick = s.Joystick
		local stickBottom = MARGIN + LEFT_ROW + 10
		items.Joystick = place(Vector2.new(0, 1), UDim2.new(0, MARGIN + STICK_X, 1, -stickBottom), Vector2.new(stick, stick))
		items.PhoneDrive = place(Vector2.new(0, 0), UDim2.new(0, MARGIN, 0, statusBottom + 12), s.PhonePeek)
		items.PhoneBanner = place(Vector2.new(0, 1), UDim2.new(0, MARGIN, 1, -(stickBottom + stick + 12)), s.PhoneBanner)
		-- Al volante o volando el aviso baja a la derecha del teléfono que asoma (debajo de tu estado:
		-- abajo van las flechas o, volando, el joystick)
		items.PhoneBannerDrive = place(Vector2.new(0, 0), UDim2.new(0, MARGIN + s.PhonePeek.X + 12, 0, statusBottom + 12), s.PhoneBanner)
	else
		items.PhoneDrive = items.Phone
		items.PhoneBannerDrive = place(Vector2.new(0, 1), UDim2.new(0, MARGIN, 1, -(MARGIN + s.PhonePeek.Y + 12)), s.PhoneBanner)
		items.PhoneBanner = place(Vector2.new(0, 1), UDim2.new(0, MARGIN, 1, -(MARGIN + s.PhonePeek.Y + 12)), s.PhoneBanner)
	end
	-- La tira de acciones de AHORA (Commands/ContextStrip)
	local contextRows: number
	if touch then
		-- Móvil: la lista de la burbuja «Acciones» (Cluster.Contexto) se abre a su izquierda, hacia
		-- arriba (encima de lo que haya: se cierra sola al usar una acción)
		local ax, ay = W - MARGIN - CLUSTER_RIGHT, H - MARGIN - CLUSTER_BOTTOM
		local bubble = HudLayout.Cluster.Contexto
		local right = ax + bubble[1] - bubble[3] - 10
		local bottom = ay + bubble[2] + bubble[3]
		local room = bottom - (statusTop + 8) - CONTEXT_CAPTION
		contextRows = math.max(1, math.min(6, math.floor((room + 6) / s.ContextPitch)))
		items.Context = place(Vector2.new(1, 1), UDim2.new(1, -(W - right), 1, -(H - bottom)), Vector2.new(s.ContextWidth, CONTEXT_CAPTION + contextRows * s.ContextPitch))
	else
		-- Ordenador: encima de la lista de teclas, abajo a la derecha (debajo de la misión)
		local bottom = MARGIN + s.Hints.Y + 12
		local room = H - bottom - (missionBottom + 12) - CONTEXT_CAPTION
		contextRows = math.max(1, math.min(7, math.floor((room + 6) / s.ContextPitch)))
		items.Context = place(Vector2.new(1, 1), UDim2.new(1, -MARGIN, 1, -bottom), Vector2.new(s.ContextWidth, CONTEXT_CAPTION + contextRows * s.ContextPitch))
	end

	if touch then
		-- Racimo táctil (centro del Ataque)
		local ax, ay = W - MARGIN - CLUSTER_RIGHT, H - MARGIN - CLUSTER_BOTTOM
		for id, def in HudLayout.Cluster do
			local r = def[3]
			slots[id] = place(Vector2.new(0.5, 0.5), UDim2.new(1, -(W - (ax + def[1])), 1, -(H - (ay + def[2]))), Vector2.new(r * 2, r * 2))
		end
		-- El botón ❓ también es un hueco (TouchLayout lo dibuja como los demás botones redondos)
		slots.Ayuda = items.Help
		-- Lado izquierdo: Teléfono, Inventario y el segundo Disparar
		for id, def in HudLayout.Left do
			slots[id] = place(Vector2.new(0.5, 0.5), UDim2.new(0, MARGIN + def[1], 1, -MARGIN + def[2]), Vector2.new(def[3], def[4]))
		end
		for i = 1, HudLayout.ExtraSlots do
			local y = ay + EXTRA_FIRST - (i - 1) * EXTRA_STEP
			slots["Extra" .. i] = place(Vector2.new(0.5, 0.5), UDim2.new(1, -(W - (ax + EXTRA_X)), 1, -(H - y)), Vector2.new(EXTRA_R * 2, EXTRA_R * 2))
		end
		-- Al volante
		for id, def in HudLayout.Drive do
			drive[id] = place(Vector2.new(0.5, 0.5), UDim2.new(1, -MARGIN + def[1], 1, -MARGIN + def[2]), Vector2.new(def[3], def[4]))
		end
		for id, def in HudLayout.DriveLeft do
			drive[id] = place(Vector2.new(0.5, 0.5), UDim2.new(0, MARGIN + def[1], 1, -MARGIN + def[2]), Vector2.new(def[3], def[4]))
		end
		drive.Ayuda = items.Help
		-- Volando
		for id, def in HudLayout.Fly do
			fly[id] = place(Vector2.new(0.5, 0.5), UDim2.new(1, -MARGIN + def[1], 1, -MARGIN + def[2]), Vector2.new(def[3], def[4]))
		end
		fly.Ayuda = items.Help
	else
		items.Hints = place(Vector2.new(1, 1), UDim2.new(1, -MARGIN, 1, -MARGIN), s.Hints)
	end

	return {
		Scale = scale,
		Canvas = canvas,
		Touch = touch,
		Items = items,
		Slots = slots,
		DriveSlots = drive,
		FlySlots = fly,
		ContextRows = contextRows,
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
-- Estado en vivo (la pantalla de verdad): lo usan el HUD, el minimapa, la barra rápida, el ValPhone,
-- el joystick y los botones táctiles. Cada uno se recoloca cuando cambia algo.
---------------------------------------------------------------------
local current: Layout? = nil
local listeners: { (Layout) -> () } = {}

local started = false
local scalers: { UIScale } = {}

local function touchOnly(): boolean
	local UserInputService = game:GetService("UserInputService")
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- Paneles de trabajo (barista, taquilla, recepción…): a la derecha en el ordenador. En el móvil, a la
-- derecha de la columna izquierda (allí asoman el ValPhone y sus avisos y está el joystick; a la derecha
-- los botones táctiles): desde el pie de tu estado hasta encima de la barra rápida. Si el panel es más
-- alto que ese hueco, su contenido va en una lista que se desplaza. Llamar con el panel ya montado.
local jobPanels: { [GuiObject]: () -> () } = {}

-- Rectángulo del hueco (en píxeles de pantalla, contando la franja de arriba)
function HudLayout.jobArea(layout: Layout): { X: number, Y: number, W: number, H: number }
	local s = layout.Scale
	local status = HudLayout.rect(layout.Items.Status, layout.Canvas)
	local hotbar = HudLayout.rect(layout.Items.Hotbar, layout.Canvas)
	local left = MARGIN + HudLayout.Sizes.LeftColumn + 12
	local top = status.Y + status.H + 10
	local bottom = hotbar.Y - 10
	return { X = left * s, Y = top * s, W = (layout.Canvas.X / 2 - left) * s, H = (bottom - top) * s }
end

local function mountJobPanel(panel: GuiObject)
	local gui = panel.Parent
	if gui and gui:IsA("ScreenGui") then
		-- Encima del HUD, la tira de acciones (2) y la tarjeta de tu vida; debajo de los botones táctiles (4)
		gui.DisplayOrder = 3
		gui.IgnoreGuiInset = true
	end
	panel:SetAttribute("JobPanel", true) -- (Theme.fit no lo cuenta: se recorta él solo)
	-- Todo lo de dentro (menos bordes, esquinas y relleno) pasa a una lista que se desplaza
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "JobScroll"
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 5
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	local keep = { UICorner = true, UIStroke = true, UIGradient = true, UIPadding = true, UIScale = true, UISizeConstraint = true }
	for _, child in panel:GetChildren() do
		if not keep[child.ClassName] then
			child.Parent = scroll
		end
	end
	scroll.Parent = panel
	local padding = panel:FindFirstChildOfClass("UIPadding")
	local design = panel.Size.Y.Offset -- alto que pide el panel (lo cambian al añadir filas)
	-- El alto que puso apply() la última vez. Un cambio de Size a ese alto es el nuestro y no cuenta
	-- como alto de diseño. (Antes se usaba una bandera «busy», pero con las señales diferidas de
	-- Roblox el aviso llega cuando la bandera ya está apagada: el alto recortado pasaba a ser el de
	-- diseño y la lista no se podía desplazar en el móvil.)
	local lastApplied: number? = nil
	local busy = false
	local function apply()
		local ui = gui and gui:FindFirstChildOfClass("UIScale")
		local k = if ui then ui.Scale else 1
		local area = HudLayout.jobArea(HudLayout.current())
		local pad = if padding then padding.PaddingTop.Offset + padding.PaddingBottom.Offset else 0
		local height = math.max(60, math.min(design, math.floor(area.H / k)))
		lastApplied = height
		busy = true
		panel.AnchorPoint = Vector2.new(0, 0)
		panel.Position = UDim2.fromOffset(math.floor(area.X / k), math.floor(area.Y / k))
		panel.Size = UDim2.fromOffset(panel.Size.X.Offset, height)
		busy = false
		-- (los hijos con tamaño en escala se miden contra el lienzo: el alto de diseño)
		scroll.CanvasSize = UDim2.fromOffset(0, math.max(0, design - pad))
	end
	panel:GetPropertyChangedSignal("Size"):Connect(function()
		local height = panel.Size.Y.Offset
		if busy or height == lastApplied then
			return
		end
		design = height
		apply()
	end)
	local ui = gui and gui:FindFirstChildOfClass("UIScale")
	if ui then
		ui:GetPropertyChangedSignal("Scale"):Connect(apply)
	end
	jobPanels[panel] = apply
	HudLayout.onChanged(function()
		if panel.Parent then
			apply()
		end
	end)
end

function HudLayout.jobPanel(panel: GuiObject)
	if touchOnly() then
		if not jobPanels[panel] then
			mountJobPanel(panel)
		end
	else
		panel.AnchorPoint = Vector2.new(1, 0.5)
		panel.Position = UDim2.new(1, -12, 0.55, 0)
	end
end

---------------------------------------------------------------------
-- Móvil: textos del HUD más grandes. El HUD se dibuja a escala 0.4-0.5 (el diseño mide 1700 de ancho
-- y en el móvil no se puede estrechar: el minimapa pisaría el reloj y la misión los botones), así que
-- los textos quedaban de 7-9 px. Cada texto crece hasta 1,5 veces, pero solo lo que quepa en su caja
-- (TextScaled con tope), para que nada se salga ni se pise.
---------------------------------------------------------------------
local TEXT_BOOST = 1.5

-- Cuánto se agranda (o encoge) un objeto por los UIScale de él y de sus padres hasta su pantalla
local function scaleOf(object: Instance): number
	local k = 1
	local node: Instance? = object
	while node do
		local scaler = node:FindFirstChildOfClass("UIScale")
		if scaler then
			k *= scaler.Scale
		end
		if node:IsA("LayerCollector") then
			break
		end
		node = node.Parent
	end
	return k
end

function HudLayout.boostText(object: Instance)
	if not (object:IsA("TextLabel") or object:IsA("TextButton")) then
		return
	end
	local label = object :: TextLabel
	if label.TextScaled or label:GetAttribute("TouchText") or label.AutomaticSize ~= Enum.AutomaticSize.None then
		return
	end
	label:SetAttribute("TouchText", true)
	local size = label.TextSize
	if label.TextTruncate ~= Enum.TextTruncate.None then
		-- Con «…»: más grande hasta el alto de la caja (lo que no quepa a lo ancho se corta con «…»)
		local height = label.Size.Y.Offset
		if label.Size.Y.Scale == 0 and height - 2 > size then
			label.TextSize = math.min(math.floor(size * TEXT_BOOST), height - 2)
		end
		return
	end
	-- Sin TextScaled (se recalculaba en cada cambio de texto: la zona del minimapa 10 veces por
	-- segundo, la distancia del GPS, el dinero que sube…): un tamaño fijo según el alto de la caja,
	-- entre el suyo y 1,5 veces. Solo se vuelve a mirar si cambia la caja (AbsoluteSize) o el texto;
	-- si con el texto nuevo no cabe (TextFits), se encoge un punto cada vez hasta su tamaño de siempre.
	local minSize = math.max(1, math.min(size, 100))
	local maxSize = math.clamp(math.floor(size * TEXT_BOOST), 1, 100)
	local height: number? = nil -- alto de la caja (en las mismas unidades que TextSize)
	local busy = false
	local function measure()
		if label.Size.Y.Scale == 0 then
			height = label.Size.Y.Offset
			return
		end
		local absolute = label.AbsoluteSize
		if typeof(absolute) == "Vector2" and absolute.Y > 0 then
			height = absolute.Y / math.max(scaleOf(label), 1e-3)
		end
	end
	local function fit()
		if busy or not height then
			return
		end
		busy = true
		local target = math.clamp(math.floor(math.min(maxSize, (height :: number) - 2)), minSize, maxSize)
		if label.TextSize ~= target then
			label.TextSize = target
		end
		while target > minSize and label.TextFits == false do
			target -= 1
			label.TextSize = target
		end
		busy = false
	end
	measure()
	fit()
	label:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		measure()
		fit()
	end)
	label:GetPropertyChangedSignal("Text"):Connect(fit)
end

local function boostGui(gui: ScreenGui)
	for _, object in gui:GetDescendants() do
		HudLayout.boostText(object)
	end
	gui.DescendantAdded:Connect(HudLayout.boostText)
end

local function recompute()
	local camera = workspace.CurrentCamera
	local viewport = if camera then camera.ViewportSize else Vector2.new(1920, 1080)
	local inset = 58
	pcall(function()
		inset = game:GetService("GuiService"):GetGuiInset().Y
	end)
	current = HudLayout.compute(viewport, { Touch = touchOnly(), Inset = inset })
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
	if touchOnly() then
		boostGui(gui)
	end
	return scaler
end

-- (pruebas) empezar de cero
function HudLayout._reset()
	current = nil
	listeners = {}
	started = false
	scalers = {}
	jobPanels = {}
end

return HudLayout
