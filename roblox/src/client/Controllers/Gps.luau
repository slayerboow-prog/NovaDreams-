-- Gps (cliente): te lleva por las calles hasta donde tienes que ir, como el GPS de un coche.
--
--   * Destino: el sitio que marques en el mapa grande (un lugar de la lista o mantén pulsado en el
--     mapa: "Ir aquí"), "Ruta a casa" del menú rápido o, si no, el objetivo de tu misión o de tu
--     trabajo o del encargo de la ciudad que hayas aceptado (los atributos TaskTarget /
--     CityErrandTarget / StoryTarget, los mismos que usa el haz de luz).
--   * La ruta va por las calles (shared/Gps: grafo de las calles que publica el servidor en
--     ReplicatedStorage.Ambient.Roads y A*). Se calcula al cambiar el destino o si te sales más de
--     25 studs; bajo tierra (metro) o sin calles, una línea recta.
--   * Se ve en el minimapa y en el mapa grande (MapUI dibuja la línea), en el suelo (flechas que
--     brillan en los próximos 120 studs) y bajo la cápsula de la hora: "Gira a la derecha en 40 m",
--     la distancia y el tiempo. Al llegar: "Has llegado" y la ruta se quita.
--   * Menú: "GPS: sí / no". Botón ✕ de la indicación o "Quitar ruta" del mapa grande: la quita.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GpsMath = require(ReplicatedStorage.Shared.Gps)
local Ground = require(ReplicatedStorage.Shared.Ground)
local Theme = require(script.Parent.Parent.UI.Theme)
local Icons = require(script.Parent.Parent.UI.Icons)
local HudLayout = require(script.Parent.Parent.UI.HudLayout)
local Hud = require(script.Parent.Parent.UI.Hud)

local create = Theme.create
local H = Theme.Hud
local rgb = Color3.fromRGB

local Gps = {}

local player = Players.LocalPlayer
local UNDERGROUND = -60 -- por debajo: metro (sin calles)
local SKY = 3000 -- por encima: interiores en el cielo (sin calles)
local ARRIVE = 14 -- studs para "has llegado" (a pie)
local MARKS = 20 -- flechas en el suelo (2 piezas cada una: 40 en total)
local MARK_STEP = 6

type Destination = { Position: Vector3, Name: string, Manual: boolean }

local graph: GpsMath.Graph? = nil
local manual: { Position: Vector3, Name: string }? = nil
local enabled = true
local busy = false
local route: { Vector3 }? = nil
local routeTarget: Vector3? = nil
local lastIndex = -1
local lastReroute = 0
-- Objetivos ya alcanzados (o quitados con ✕): no vuelven hasta que cambien. Una lista, no uno solo:
-- si no, con trabajo y misión a la vez, ✕ solo pasaba de uno a otro y nunca quitaba la ruta
local suppressed: { Vector3 } = {}
local function isSuppressed(target: Vector3): boolean
	for _, p in suppressed do
		if (p - target).Magnitude < 1 then
			return true
		end
	end
	return false
end
local listeners: { (({ Vector3 })?, ({ Vector3 })?, number?) -> () } = {}
local manualListeners: { (({ Position: Vector3, Name: string })?) -> () } = {}

local banner: Frame? = nil
local bannerParts: { [string]: any } = {}
local folder: Folder? = nil
local marks: { { Part } } = {}
local lastMarkPosition: Vector3? = nil

---------------------------------------------------------------------
-- Avisar a quien dibuja la ruta (MapUI)
---------------------------------------------------------------------
-- (full e index: la ruta entera y el tramo en el que vas, para que MapUI reutilice las piezas de la
-- línea mientras la ruta sea la misma)
local function notify(path: { Vector3 }?, full: { Vector3 }?, index: number?)
	for _, listener in listeners do
		task.spawn(listener, path, full, index)
	end
end

-- fn(path, full, index) cada vez que cambia lo que queda de ruta (nil = sin ruta). full: la ruta
-- entera (la misma tabla mientras no se recalcule); path[i] es full[index + i - 1] (salvo path[1],
-- que es donde estás)
function Gps.onChanged(fn: (({ Vector3 })?, ({ Vector3 })?, number?) -> ())
	table.insert(listeners, fn)
	if route then
		task.spawn(fn, route)
	end
end

-- fn(sitio) cuando cambia el sitio marcado (p. ej. al llegar se desmarca)
function Gps.onManual(fn: (({ Position: Vector3, Name: string })?) -> ())
	table.insert(manualListeners, fn)
end

function Gps.path(): { Vector3 }?
	return route
end

---------------------------------------------------------------------
-- Destino
---------------------------------------------------------------------
function Gps.setManual(position: Vector3?, name: string?)
	if position then
		manual = { Position = position, Name = name or "Sitio marcado" }
		table.clear(suppressed)
	else
		manual = nil
	end
	route = nil -- (se recalcula en la próxima vuelta)
	for _, listener in manualListeners do
		task.spawn(listener, manual)
	end
end

function Gps.manual(): { Position: Vector3, Name: string }?
	return manual
end

-- Los objetivos que pone el servidor, por orden de preferencia
local TARGETS = {
	{ Attribute = "TaskTarget", Name = "Tu trabajo" },
	{ Attribute = "CityErrandTarget", Name = "Tu encargo" },
	{ Attribute = "StoryTarget", Name = "Tu misión" },
}

local function currentDestination(): Destination?
	if manual then
		return { Position = manual.Position, Name = manual.Name, Manual = true }
	end
	-- El primer objetivo que haya y que no esté silenciado (si el trabajo ya se alcanzó, sigue con
	-- el encargo o la misión en vez de quedarse sin ruta)
	for _, entry in TARGETS do
		local target = player:GetAttribute(entry.Attribute)
		if typeof(target) == "Vector3" and not isSuppressed(target) then
			return { Position = target, Name = entry.Name, Manual = false }
		end
	end
	return nil
end

-- Quitar la ruta (el sitio marcado, o el objetivo actual hasta que cambie)
function Gps.clear()
	-- ✕ quita la ruta de verdad: se silencian todos los objetivos de ahora
	if not manual then
		for _, entry in TARGETS do
			local target = player:GetAttribute(entry.Attribute)
			if typeof(target) == "Vector3" then
				table.insert(suppressed, target)
			end
		end
	end
	Gps.setManual(nil)
end

-- «Llévame» (Controllers/HelpUI y las pistas): vuelve a poner la ruta a tu misión o trabajo, aunque
-- la hubieras quitado con ✕ o apagado el GPS en el menú
function Gps.follow()
	enabled = true
	table.clear(suppressed)
	Gps.setManual(nil)
end

-- Ruta hasta tu casa familiar (la del atributo FamilyHomeId)
function Gps.routeHome()
	local homeId = player:GetAttribute("FamilyHomeId")
	for _, home in CollectionService:GetTagged("FamilyHome") do
		if homeId ~= nil and home:GetAttribute("HomeId") == homeId and home:IsA("Model") then
			Gps.setManual(home:GetPivot().Position, "Tu casa")
			Hud.toast("Info", "🧭 Ruta a tu casa marcada: sigue las flechas")
			return
		end
	end
	Hud.toast("Info", "🏠 Todavía no tienes casa a la que ir")
end

function Gps.setEnabled(value: boolean)
	enabled = value
	route = nil
	notify(nil)
end

function Gps.isEnabled(): boolean
	return enabled
end

function Gps.setBusy(value: boolean)
	busy = value
end

---------------------------------------------------------------------
-- Flechas en el suelo (piezas reutilizadas: nunca más de 40)
---------------------------------------------------------------------
local function markPart(): Part
	local part = Instance.new("Part")
	part.Name = "GpsFlecha"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = rgb(90, 220, 255)
	part.Transparency = 0.25
	part.Size = Vector3.new(0.35, 0.08, 2.2)
	part.Parent = folder
	return part
end

local function hideMarks()
	for _, pair in marks do
		for _, part in pair do
			part.Transparency = 1
		end
	end
	lastMarkPosition = nil
end

-- El suelo de verdad debajo de un punto: se salta lo que no es suelo (hojas de los árboles, farolas,
-- techos de coches, personas, marcas invisibles…) y sigue mirando hacia abajo
-- base: la lista que ya lleva params (si hay que saltarse algo, se amplía y al terminar se deja
-- otra vez como estaba)
local function groundBelow(from: Vector3, params: RaycastParams, base: { Instance }): Vector3?
	local skip: { Instance }? = nil
	local origin = from
	local function done(result: Vector3?): Vector3?
		if skip then
			params.FilterDescendantsInstances = base
		end
		return result
	end
	for _ = 1, 6 do
		local hit = workspace:Raycast(origin, Vector3.new(0, -60, 0), params)
		if not hit then
			return done(nil)
		end
		local part = hit.Instance
		local model = part:FindFirstAncestorOfClass("Model")
		local isBody = (model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil) or Ground.skipOf(part) ~= nil -- (personas y vehículos)
		local flatEnough = hit.Normal.Y > 0.7
		if hit.Material == Enum.Material.Water or (part.CanCollide and part.Transparency < 0.9 and not isBody and flatEnough and part.Size.Y < 40) or part:IsA("Terrain") then
			return done(hit.Position)
		end
		local list = skip or table.clone(base)
		skip = list
		table.insert(list, part)
		params.FilterDescendantsInstances = list
		origin = hit.Position + Vector3.new(0, -0.05, 0)
	end
	return done(nil)
end

local function placeMarks(path: { Vector3 }, position: Vector3)
	if not folder then
		return
	end
	local ahead = GpsMath.ahead(path, position)
	local list = GpsMath.marks(ahead, MARK_STEP, 120, MARKS)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	-- (la lista se pone una vez, fuera del bucle: groundBelow la deja como estaba al terminar)
	local exclude = { player.Character :: Instance, folder :: Instance, workspace.CurrentCamera :: Instance }
	params.FilterDescendantsInstances = exclude
	for i = 1, MARKS do
		local pair = marks[i]
		if not pair then
			pair = { markPart(), markPart() }
			marks[i] = pair
		end
		local mark = list[i]
		if not mark then
			pair[1].Transparency = 1
			pair[2].Transparency = 1
			continue
		end
		-- En el suelo de verdad (acera, calle, césped…)
		local from = Vector3.new(mark.Position.X, math.max(mark.Position.Y, position.Y) + 6, mark.Position.Z)
		local ground = groundBelow(from, params, exclude) or Vector3.new(mark.Position.X, position.Y - 2.8, mark.Position.Z)
		local base = CFrame.lookAt(ground + Vector3.new(0, 0.12, 0), ground + Vector3.new(0, 0.12, 0) + mark.Direction)
		-- ">" en el suelo: dos barras que se juntan en la punta
		pair[1].CFrame = base * CFrame.new(-0.55, 0, 0) * CFrame.Angles(0, math.rad(-40), 0)
		pair[2].CFrame = base * CFrame.new(0.55, 0, 0) * CFrame.Angles(0, math.rad(40), 0)
		-- las lejanas, más tenues
		local fade = 0.2 + 0.6 * (i / MARKS)
		pair[1].Transparency = fade
		pair[2].Transparency = fade
	end
end

---------------------------------------------------------------------
-- Indicación bajo la cápsula de la hora
---------------------------------------------------------------------
local TURN_ROTATION = { Left = 180, Right = 0, Straight = -90, Arrive = -90 }

local function buildBanner()
	local gui = create("ScreenGui", { Name = "GpsGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 2, Parent = player:WaitForChild("PlayerGui") })
	HudLayout.scaleGui(gui)
	local panel = Theme.hudPanel({ Name = "GpsBanner", BackgroundTransparency = 0.25, CornerRadius = 16, Visible = false, Parent = gui })
	banner = panel
	local disc = create("Frame", { Name = "Turn", Position = UDim2.fromOffset(8, 7), Size = UDim2.fromOffset(44, 44), BackgroundColor3 = H.Select, Parent = panel }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	Theme.edge(disc, H.Glow, 2)
	bannerParts.Arrow = Icons.chevron({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(18, 24), Thickness = 4, Parent = disc })
	bannerParts.Title = Theme.label({ Name = "Instruction", Position = UDim2.fromOffset(62, 4), Size = UDim2.new(1, -110, 0, 28), Font = Theme.FontBold, TextSize = 20, TextTruncate = Enum.TextTruncate.AtEnd, TextStrokeTransparency = 0.6, Parent = panel })
	bannerParts.Sub = Theme.label({ Name = "Distance", Position = UDim2.fromOffset(62, 31), Size = UDim2.new(1, -110, 0, 20), TextSize = 15, TextColor3 = H.SelectLight, TextTruncate = Enum.TextTruncate.AtEnd, Parent = panel })
	local close = create("TextButton", { Name = "Clear", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = H.NavyLight, Text = "", Parent = panel }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	Icons.plus({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 14), Rotation = 45, Thickness = 2.5, Parent = close })
	Theme.pressable(close)
	close.Activated:Connect(function()
		Gps.clear()
		Hud.toast("Info", "🧭 Ruta quitada")
	end)
	HudLayout.onChanged(function(layout)
		HudLayout.apply(panel, layout.Items.Gps)
	end)
end

local function showBanner(turn: { Kind: string, Distance: number, Remaining: number }?, dest: Destination?, speed: number)
	local panel = banner
	if not panel then
		return
	end
	local visible = turn ~= nil and dest ~= nil and not busy and player:GetAttribute("LifeStage") ~= "Bebe"
	panel.Visible = visible
	if not visible or not turn or not dest then
		return
	end
	bannerParts.Arrow.Rotation = TURN_ROTATION[turn.Kind] or -90
	Theme.setText(bannerParts.Title, GpsMath.instructionText(turn))
	Theme.setText(bannerParts.Sub, GpsMath.distanceText(turn.Remaining, speed) .. " · " .. dest.Name)
end

---------------------------------------------------------------------
-- Cada cuarto de segundo: dónde vas, si hay que recalcular, flechas e indicación
---------------------------------------------------------------------
local function straight(from: Vector3, to: Vector3): { Vector3 }
	return { from, to }
end

local function update()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local dest = if enabled then currentDestination() else nil
	if not root or not dest then
		if route then
			route = nil
			routeTarget = nil
			lastIndex = -1
			notify(nil)
		end
		hideMarks()
		showBanner(nil, nil, 0)
		return
	end
	local seated = humanoid ~= nil and humanoid.SeatPart ~= nil
	-- Dentro de un interior (en el cielo, Y ~ 6000) la ruta sale de la puerta del edificio; salvo que
	-- el destino también esté en el cielo (entonces, desde donde estás)
	local door = player:GetAttribute("InteriorDoor")
	local inside = typeof(door) == "Vector3"
	local sky = dest.Position.Y > SKY
	local position = if inside and not sky then door :: Vector3 else root.Position

	-- ¿Has llegado? (los sitios marcados en el mapa y los lugares de la lista no tienen altura de
	-- verdad (Y = 0): con ellos solo cuenta la distancia en el plano)
	local flat = Vector3.new(dest.Position.X - position.X, 0, dest.Position.Z - position.Z)
	local sameHeight = dest.Manual or math.abs(dest.Position.Y - position.Y) < 30
	if flat.Magnitude < (if seated then ARRIVE * 1.8 else ARRIVE) and sameHeight then
		Hud.toast("Success", "📍 Has llegado: " .. dest.Name)
		if dest.Manual then
			Gps.setManual(nil)
		else
			table.insert(suppressed, dest.Position)
		end
		route = nil
		notify(nil)
		hideMarks()
		showBanner(nil, nil, 0)
		return
	end

	-- ¿Hay que (re)calcular la ruta?
	local now = os.clock()
	local changed = route == nil or routeTarget == nil or (routeTarget - dest.Position).Magnitude > 5
	local off = route ~= nil and GpsMath.offRoute(route, position) and now - lastReroute > 1.5
	if changed or off then
		lastReroute = now
		routeTarget = dest.Position
		-- (bajo tierra, en un interior del cielo o en el sueño del prólogo no hay calles: línea recta)
		local underground = position.Y < UNDERGROUND or dest.Position.Y < UNDERGROUND or position.Y > SKY or sky or player:GetAttribute("InPrologue") == true
		route = if graph and not underground then GpsMath.route(graph, position, dest.Position) or straight(position, dest.Position) else straight(position, dest.Position)
		lastIndex = -1
		lastMarkPosition = nil
	end
	local path = route :: { Vector3 }

	-- Lo que queda de ruta, para los mapas (solo cuando avanzas de tramo)
	local at = GpsMath.progress(path, position)
	if at.Index ~= lastIndex then
		lastIndex = at.Index
		-- (lo mismo que GpsMath.ahead, sin volver a calcular el progreso)
		local ahead = { at.Point }
		for i = at.Index + 1, #path do
			table.insert(ahead, path[i])
		end
		notify(ahead, path, at.Index)
	end

	-- Flechas en el suelo (si te has movido un poco). Dentro de un interior no: la ruta empieza en
	-- la puerta y las flechas saldrían en la calle, lejos de ti
	if inside and not sky then
		hideMarks()
	elseif lastMarkPosition == nil or (lastMarkPosition - position).Magnitude > 2 then
		lastMarkPosition = position
		placeMarks(path, position)
	end

	-- Indicación
	local speed = if humanoid then humanoid.WalkSpeed else 16
	if seated and humanoid and humanoid.SeatPart then
		speed = math.max(speed, humanoid.SeatPart.AssemblyLinearVelocity.Magnitude)
	end
	showBanner(GpsMath.nextTurn(path, position, if seated then ARRIVE * 1.8 else ARRIVE), dest, speed)
end

-- (también se puede pedir una vuelta ahora mismo)
Gps.update = update

---------------------------------------------------------------------
local function loadRoads()
	local ambient = ReplicatedStorage:WaitForChild("Ambient", 60)
	local roadFolder = ambient and ambient:WaitForChild("Roads", 60)
	if not roadFolder then
		warn("[GPS] No hay calles publicadas: las rutas serán en línea recta")
		return
	end
	local segments = {}
	for _, config in roadFolder:GetChildren() do
		local a, b = config:GetAttribute("A"), config:GetAttribute("B")
		if typeof(a) == "Vector3" and typeof(b) == "Vector3" and (a - b).Magnitude > 0.5 then
			table.insert(segments, { A = a, B = b })
		end
	end
	local ok, result = pcall(GpsMath.build, segments)
	if ok then
		graph = result
	else
		warn("[GPS] " .. tostring(result))
	end
end

function Gps.init()
	folder = Instance.new("Folder")
	folder.Name = "GpsRuta"
	folder.Parent = workspace.CurrentCamera
	buildBanner()
	Hud.addButton("🧭 Ruta a casa", rgb(20, 150, 140), 1.5, Gps.routeHome)
	task.spawn(loadRoads)
	for _, entry in TARGETS do
		player:GetAttributeChangedSignal(entry.Attribute):Connect(function()
			route = nil
			-- Objetivo nuevo: lo que se silenció al llegar (o con ✕) ya no vale
			table.clear(suppressed)
		end)
	end
	-- Al entrar o salir de un interior, la ruta sale de otro sitio
	player:GetAttributeChangedSignal("InteriorDoor"):Connect(function()
		route = nil
		lastMarkPosition = nil
	end)
	player.CharacterAdded:Connect(function()
		route = nil
		lastMarkPosition = nil
	end)
	task.spawn(function()
		while true do
			task.wait(0.25)
			local ok, err = pcall(update)
			if not ok then
				warn("[GPS] " .. tostring(err))
			end
		end
	end)
end

return Gps
