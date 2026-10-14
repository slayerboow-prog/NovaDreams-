-- SpaceClient (cliente): el cielo y el espacio encima de Valmar (Services/SpaceService, docs/espacio.md).
--
--   * El cielo según la ALTURA de la cámara (shared/Cosmos/Layers): hasta 1800 el de siempre (el de
--     los aviones); entre 1800 y 3400 se oscurece poco a poco (capa "SpaceSky" de DayLight) y salen las
--     estrellas; desde 3400, negro con estrellas.
--   * Valmar desde arriba: la isla dibujada en grande (costa de shared/CityPlan, mar y el centro) que
--     solo se pone cuando estás muy alto (de cerca, la ciudad de verdad).
--   * Los 7 planetas de la Saga 2 (shared/Cosmos/Planets) como estrellas brillantes al fondo, cada una
--     con su color, sus rayos y su forma de titilar. En el espacio se ven bien; desde Valmar, de noche,
--     muy flojitas. Mírala con el morro un momento (o tócala) y sale su nombre y VIAJAR.
--   * Botones de la nave en el espacio (HudLayout.Fly): VALMAR (volver a casa, siempre; tecla V, mando Y)
--     y el de contexto (tecla G, mando X): ATRACAR junto al muelle de una estación o VIAJAR mirando a
--     un planeta. Salir (X) aterriza si estás bajo (Layers.LandY).
--   * Lo que manda el servidor: menús de la tienda y del tablón (Dialog.choose), minar (chispas en el
--     asteroide y la bodega) y los mensajes de los planetas.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Cosmos = ReplicatedStorage.Shared.Cosmos
local Layers = require(Cosmos.Layers)
local Planets = require(Cosmos.Planets)
local PlanetBodies = require(Cosmos.PlanetBodies)
local Stations = require(Cosmos.Stations)
local Mining = require(Cosmos.Mining)
local CityPlan = require(ReplicatedStorage.Shared.CityPlan)
local GameClock = require(ReplicatedStorage.Shared.GameClock)
local AirCombatClient = require(script.Parent.AirCombatClient)
local AirCombatFx = require(script.Parent.AirCombatFx)
local SoundFx = require(script.Parent.SoundFx)
local Hud = require(script.Parent.Parent.UI.Hud)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local Dialog = require(script.Parent.Parent.UI.Dialog)

local SpaceClient = {}

local player = Players.LocalPlayer
local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local STEP = "SpaceClientStep"
local KEYS = "SpaceClientKeys"
local rgb = Color3.fromRGB

local remote: RemoteEvent? = nil
local stars: Model? = nil
local starParts: { BasePart } = {}
local starsAt: Vector3? = nil
local starAlpha = -1
local island: Model? = nil
local lastBlend = -1
local planetViews: { [string]: { [string]: any } } = {}
local planetFolder: Folder? = nil
local aimId: string? = nil
local aimSince = 0
local action: string? = nil -- "Dock" | "Planet"
local actionPlanet: string? = nil
local keysBound = false
local lastCosmos: string? = nil
local lastMineToast = 0
local lastPlanetAsk = 0

local SPACE_MOOD = {
	Brightness = 1.1,
	Exposure = -0.35,
	Ambient = rgb(40, 44, 62),
	Outdoor = rgb(70, 76, 110),
	Density = 0,
	Haze = 0,
	Cover = 0,
	CloudDensity = 0,
	Saturation = 0.08,
	Contrast = 0.22,
	Bloom = 1.2,
}

local skyOwner = false
-- Controllers/PlanetClient se queda con la luz del cielo mientras entras en un planeta o estás en él
function SpaceClient.setSkyOwner(on: boolean)
	skyOwner = on
end
SpaceClient.SpaceMood = SPACE_MOOD

local function fire(...)
	if remote then
		remote:FireServer(...)
	end
end

local function inCosmosShip(): boolean
	local cur = AirCombatClient.current()
	return cur ~= nil and cur.World == "Cosmos" and not cur.Down
end

-- (VALMAR también en la superficie de un planeta: docs/planetas.md)
local function inSpaceOrPlanetShip(): boolean
	local cur = AirCombatClient.current()
	return cur ~= nil and (cur.World == "Cosmos" or cur.World == "Planet") and not cur.Down
end

---------------------------------------------------------------------
-- Estrellas (un campo alrededor de la cámara que aparece con la altura)
---------------------------------------------------------------------
local function buildStars(): Model
	local model = Instance.new("Model")
	model.Name = "SpaceStars"
	local rng = Random.new(77)
	local count = if TOUCH then 150 else 280
	local root = Instance.new("Part")
	root.Name = "Centro"
	root.Anchored = true
	root.Transparency = 1
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.Size = Vector3.one
	root.Parent = model
	model.PrimaryPart = root
	local tints = { rgb(255, 255, 255), rgb(190, 220, 255), rgb(255, 230, 190), rgb(220, 190, 255) }
	for i = 1, count do
		local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.35, 1), rng:NextNumber(-1, 1))
		if dir.Magnitude < 0.05 then
			dir = Vector3.new(0, 1, 0)
		end
		local p = Instance.new("Part")
		p.Name = "Estrella"
		p.Shape = Enum.PartType.Ball
		p.Material = Enum.Material.Neon
		p.Color = tints[(i % #tints) + 1]
		p.Size = Vector3.one * rng:NextNumber(2.5, 7)
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
		p.CFrame = CFrame.new(dir.Unit * 1750)
		p.Parent = model
		table.insert(starParts, p)
	end
	return model
end

local function setStars(alpha: number, at: Vector3)
	if alpha <= 0.02 then
		if stars then
			stars.Parent = nil
		end
		starAlpha = 0
		return
	end
	if not stars then
		stars = buildStars()
	end
	local s = stars :: Model
	if s.Parent ~= workspace.CurrentCamera then
		s.Parent = workspace.CurrentCamera
		starsAt = nil
	end
	if math.abs(alpha - starAlpha) > 0.05 then
		starAlpha = alpha
		for _, p in starParts do
			p.Transparency = 1 - alpha
		end
	end
	if not starsAt or (starsAt - at).Magnitude > 60 then
		starsAt = at
		s:PivotTo(CFrame.new(at))
	end
end

---------------------------------------------------------------------
-- Valmar desde muy arriba: la isla dibujada en grande (solo cuando estás alto)
---------------------------------------------------------------------
-- Un triángulo con dos cuñas (WedgePart)
local function triangle(parent: Instance, a: Vector3, b: Vector3, c: Vector3, color: Color3)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab)
	if right.Magnitude < 1e-3 then
		return
	end
	right = right.Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	for i, info in { { (a + b) / 2, right, math.abs(ab:Dot(back)), back }, { (a + c) / 2, -right, math.abs(ac:Dot(back)), -back } } do
		local w = Instance.new("WedgePart")
		w.Name = "Isla" .. i
		w.Anchored = true
		w.CanCollide = false
		w.CanTouch = false
		w.CanQuery = false
		w.CastShadow = false
		w.Material = Enum.Material.SmoothPlastic
		w.Color = color
		w.Size = Vector3.new(1, math.max(0.2, height), math.max(0.2, info[3]))
		w.CFrame = CFrame.fromMatrix(info[1], info[2], up, info[4])
		w.Parent = parent
	end
end

function SpaceClient.buildIsland(): Model
	local model = Instance.new("Model")
	model.Name = "ValmarDesdeArriba"
	local y = -0.5
	local green, sand = rgb(78, 128, 70), rgb(196, 182, 140)
	local coast = CityPlan.Coast
	local O = Vector3.new(0, y, 0)
	for i = 1, #coast do
		local p, q = coast[i], coast[(i % #coast) + 1]
		local A, B = Vector3.new(p[1], y, p[2]), Vector3.new(q[1], y, q[2])
		-- (en tiras: ninguna pieza pasa de 2048 studs)
		local n = 3
		for k = 0, n - 1 do
			local t0, t1 = k / n, (k + 1) / n
			local a0, b0 = O:Lerp(A, t0), O:Lerp(B, t0)
			local a1, b1 = O:Lerp(A, t1), O:Lerp(B, t1)
			local color = if k == n - 1 then green:Lerp(sand, 0.25) else green
			if k == 0 then
				triangle(model, O, a1, b1, color)
			else
				triangle(model, a0, a1, b1, color)
				triangle(model, a0, b1, b0, color)
			end
		end
	end
	-- El centro (gris de la ciudad) y el mar alrededor
	for _, c in { { 0, 0, 1900 }, { 0, -900, 1500 }, { 0, 900, 1500 } } do
		local disc = Instance.new("Part")
		disc.Name = "Ciudad"
		disc.Shape = Enum.PartType.Cylinder
		disc.Anchored = true
		disc.CanCollide = false
		disc.CanTouch = false
		disc.CanQuery = false
		disc.CastShadow = false
		disc.Material = Enum.Material.SmoothPlastic
		disc.Color = rgb(128, 132, 140)
		disc.Size = Vector3.new(0.4, c[3], c[3])
		disc.CFrame = CFrame.new(c[1], y + 0.6, c[2]) * CFrame.Angles(0, 0, math.pi / 2)
		disc.Parent = model
	end
	for ix = -3, 3 do
		for iz = -3, 3 do
			local sea = Instance.new("Part")
			sea.Name = "Mar"
			sea.Anchored = true
			sea.CanCollide = false
			sea.CanTouch = false
			sea.CanQuery = false
			sea.CastShadow = false
			sea.Material = Enum.Material.SmoothPlastic
			sea.Color = rgb(24, 70, 120)
			sea.Size = Vector3.new(2000, 1, 2000)
			sea.CFrame = CFrame.new(ix * 2000, y - 2, iz * 2000)
			sea.Parent = model
		end
	end
	return model
end

local function setIsland(show: boolean)
	if show then
		if not island then
			island = SpaceClient.buildIsland()
		end
		if (island :: Model).Parent ~= workspace.CurrentCamera then
			(island :: Model).Parent = workspace.CurrentCamera
		end
	elseif island and island.Parent then
		island.Parent = nil
	end
end

---------------------------------------------------------------------
-- Los 7 planetas: estrellas con halo, rayos y nombre
---------------------------------------------------------------------
local function round(parent: Instance, name: string, size: number, color: Color3, soft: boolean): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5, 0.5)
	f.Size = UDim2.fromOffset(size, size)
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = f
	if soft then
		local g = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.5, 0.65), NumberSequenceKeypoint.new(1, 1) })
		g.Rotation = 90
		g.Parent = f
	end
	return f
end

local function buildPlanet(p: Planets.Planet, gui: Instance, folder: Instance): { [string]: any }
	local anchor = Instance.new("Part")
	anchor.Name = "Planeta" .. p.Id
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Parent = folder
	local bb = Instance.new("BillboardGui")
	bb.Name = "Estrella" .. p.Id
	bb.Adornee = anchor
	bb.Size = UDim2.fromOffset(150, 170)
	bb.LightInfluence = 0
	bb.AlwaysOnTop = false
	bb.ResetOnSpawn = false
	bb.Active = true
	bb.Enabled = false
	bb.Parent = gui
	local box = Instance.new("TextButton")
	box.Name = "Toque"
	box.Text = ""
	box.BackgroundTransparency = 1
	box.AutoButtonColor = false
	box.Size = UDim2.fromOffset(150, 150)
	box.Parent = bb
	local glow = round(box, "Halo", p.Size * 3.2, p.Glow, true)
	local rays = Instance.new("Frame")
	rays.Name = "Rayos"
	rays.AnchorPoint = Vector2.new(0.5, 0.5)
	rays.Position = UDim2.fromScale(0.5, 0.5)
	rays.Size = UDim2.fromOffset(140, 140)
	rays.BackgroundTransparency = 1
	rays.Parent = box
	local rayList = {}
	for i = 1, p.Rays do
		local r = Instance.new("Frame")
		r.Name = "Rayo"
		r.AnchorPoint = Vector2.new(0.5, 0.5)
		r.Position = UDim2.fromScale(0.5, 0.5)
		local long = if i % 2 == 0 then 0.65 else 1
		r.Size = UDim2.fromOffset(if p.Rays >= 8 then 2 else 3, math.floor(130 * long))
		r.Rotation = (i - 1) * 180 / p.Rays
		r.BackgroundColor3 = p.Hue
		r.BorderSizePixel = 0
		r.Parent = rays
		local g = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.1), NumberSequenceKeypoint.new(1, 1) })
		g.Rotation = 90
		g.Parent = r
		table.insert(rayList, r)
	end
	local core = round(box, "Nucleo", p.Size, p.Hue, false)
	local white = round(core, "Brillo", math.floor(p.Size * 0.45), rgb(255, 255, 255), false)
	local label = Instance.new("TextLabel")
	label.Name = "Nombre"
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 0, 132)
	label.Size = UDim2.fromOffset(150, 36)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = p.Hue
	label.TextStrokeTransparency = 0.3
	label.Text = ("%s · ep. %d"):format(p.Name, p.Episode)
	label.Visible = false
	label.Parent = bb
	local view = { Anchor = anchor, Gui = bb, Glow = glow, Rays = rays, RayList = rayList, Core = core, White = white, Label = label, Planet = p, ShownUntil = 0 }
	box.Activated:Connect(function()
		local now = os.clock()
		if now - lastPlanetAsk < 1 then
			return
		end
		lastPlanetAsk = now
		view.ShownUntil = now + 4
		fire("Planet", p.Id)
	end)
	return view
end

local function ensurePlanets()
	if planetFolder then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "PlanetasSaga2"
	folder.Parent = workspace.CurrentCamera
	planetFolder = folder
	local gui = player:WaitForChild("PlayerGui")
	for _, p in Planets.List do
		planetViews[p.Id] = buildPlanet(p, gui, folder)
	end
end

local function isNight(): boolean
	local h = GameClock.hour()
	return h >= 20.5 or h < 5.5
end

local function updatePlanets(camPos: Vector3, blend: number, t: number, aimed: string?)
	local night = if isNight() and blend < 0.5 then 0.3 else 0
	local vis = math.max(blend, night)
	if vis <= 0.02 then
		for _, v in planetViews do
			v.Gui.Enabled = false
		end
		return
	end
	ensurePlanets()
	local small = blend < 0.5
	local camera = workspace.CurrentCamera
	local fov = if camera then camera.FieldOfView else 70
	local vpY = if camera then camera.ViewportSize.Y else 720
	for _, v in planetViews do
		local p = v.Planet
		-- (la estrella está donde está el planeta de verdad, shared/Cosmos/PlanetBodies; al acercarte se
		-- apaga y Controllers/PlanetClient dibuja la esfera con su textura)
		local body = PlanetBodies.ById[p.Id]
		local starK = 1
		local dir = p.Dir
		if body then
			local pv = PlanetBodies.view(body, camPos, fov, vpY)
			dir = pv.Dir
			starK = pv.Star
		end
		v.Anchor.CFrame = CFrame.new(camPos + dir * Planets.Distance)
		v.Gui.Enabled = starK > 0.02
		local b = Planets.brightness(p, t) * vis * starK
		local pulse = if p.Pulse then 0.85 + 0.15 * math.sin(t * p.Pulse * math.pi * 2) else 1
		local k = if small then 0.4 else 1
		v.Core.BackgroundTransparency = 1 - math.clamp(b * 1.1, 0, 1)
		v.White.BackgroundTransparency = 1 - math.clamp(b, 0, 1)
		v.Glow.BackgroundTransparency = 1 - math.clamp(b * 0.75, 0, 1)
		v.Glow.Size = UDim2.fromOffset(math.floor(p.Size * 3.2 * pulse * k), math.floor(p.Size * 3.2 * pulse * k))
		v.Core.Size = UDim2.fromOffset(math.floor(p.Size * k), math.floor(p.Size * k))
		v.Rays.Visible = not small
		v.Rays.Rotation = Planets.rayAngle(p, t)
		for _, r in v.RayList do
			r.BackgroundTransparency = 1 - math.clamp(b * 0.9, 0, 1)
		end
		v.Label.Visible = not small and (aimed == p.Id or (v.ShownUntil or 0) > t)
	end
end

---------------------------------------------------------------------
-- Botones y teclas de la nave en el espacio
---------------------------------------------------------------------
local function goHome()
	task.spawn(function()
		local choice = Dialog.choose("🏠 Volver a Valmar", "Un fundido rápido y apareces en el puerto espacial del islote.", { "Sí, volver a Valmar", "Seguir volando" })
		if choice == 1 then
			fire("Home")
		end
	end)
end

local function doAction()
	if action == "Dock" then
		fire("Dock")
	elseif action == "Planet" and actionPlanet then
		fire("Planet", actionPlanet)
	end
end

local function onKey(_: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	if not inSpaceOrPlanetShip() then
		return Enum.ContextActionResult.Pass
	end
	local typing = false
	pcall(function()
		typing = game:GetService("UserInputService"):GetFocusedTextBox() ~= nil
	end)
	if typing then
		return Enum.ContextActionResult.Pass -- (escribiendo en el chat)
	end
	if state == Enum.UserInputState.Begin then
		local code = input.KeyCode
		if code == Enum.KeyCode.V or code == Enum.KeyCode.ButtonY then
			goHome()
		elseif code == Enum.KeyCode.G or code == Enum.KeyCode.F or code == Enum.KeyCode.ButtonX then
			doAction()
		end
	end
	return Enum.ContextActionResult.Sink
end

local function bindKeys(on: boolean)
	if on == keysBound then
		return
	end
	keysBound = on
	if on then
		ContextActionService:BindActionAtPriority(KEYS, onKey, false, Enum.ContextActionPriority.High.Value + 70, Enum.KeyCode.V, Enum.KeyCode.G, Enum.KeyCode.F, Enum.KeyCode.ButtonY, Enum.KeyCode.ButtonX)
	else
		ContextActionService:UnbindAction(KEYS)
	end
end

local function setAction(kind: string?, planet: string?)
	if kind == action and planet == actionPlanet then
		return
	end
	action, actionPlanet = kind, planet
	if kind == "Dock" then
		TouchLayout.setLabel("NaveAccion", "ATRACAR")
		TouchLayout.setIcon("NaveAccion", "puerta")
	elseif kind == "Planet" then
		local p = planet and Planets.ById[planet]
		TouchLayout.setLabel("NaveAccion", if p then "VIAJAR" else "VIAJAR")
		TouchLayout.setIcon("NaveAccion", "objetivo")
		if p then
			Hud.toast("Info", ("🪐 %s (%s) · pulsa VIAJAR%s"):format(p.Name, p.City, if TOUCH then "" else " o F"))
		end
	end
	TouchLayout.refresh()
end

---------------------------------------------------------------------
-- Cada fotograma
---------------------------------------------------------------------
local function step(_dt: number)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local camPos = camera.CFrame.Position
	-- (junto a un planeta, fuera de la columna, sigue siendo el espacio)
	local column = Layers.inColumn(camPos, 600) or PlanetBodies.approachAt(camPos, 600) ~= nil
	local blend = if column then Layers.skyBlend(camPos.Y) else 0
	-- (la arena de pruebas tiene su propio cielo: aquí nada)
	if player:GetAttribute("AirCombatWorld") == "Arena" then
		blend = 0
	end
	-- (entrando en un planeta o en su superficie, la luz la pone Controllers/PlanetClient: skyOwner)
	local lightBlend = if skyOwner then 0 else blend
	if math.abs(lightBlend - lastBlend) > 0.02 or (lightBlend <= 0.01) ~= (lastBlend <= 0.01) then
		lastBlend = lightBlend
		pcall(function()
			local DayLight = require(script.Parent.DayLight)
			if lightBlend > 0.01 then
				DayLight.pushLayer("SpaceSky", SPACE_MOOD, 0.4, lightBlend)
			else
				DayLight.popLayer("SpaceSky", 0.8)
			end
		end)
	end
	setStars(blend, camPos)
	setIsland(Layers.inColumn(camPos, 600) and camPos.Y > Layers.TransitionY - 200 and player:GetAttribute("AirCombatWorld") ~= "Arena")
	-- La nave en el espacio: muelle, planeta al que apuntas, botones y teclas
	local cur = AirCombatClient.current()
	local cosmos = cur ~= nil and cur.World == "Cosmos" and not cur.Down
	local inCosmos = cur ~= nil and cur.World == "Cosmos"
	local onPlanet = cur ~= nil and cur.World == "Planet"
	bindKeys(inCosmos or onPlanet)
	local label = if inCosmos then "Aterrizar" elseif onPlanet then "BAJAR" else "Salir"
	if label ~= lastCosmos then
		lastCosmos = label
		-- (encima de Valmar, Salir es aterrizar: solo cerca del suelo; en un planeta, bajarse posada)
		TouchLayout.setLabel("NaveSalir", label)
	end
	local aimed: string? = nil
	local t = os.clock()
	if cosmos and cur then
		local root = cur.Root :: BasePart
		local pos = root.Position
		local look = root.CFrame.LookVector
		if Stations.dockAt(pos) then
			setAction("Dock", nil)
		else
			-- (el planeta al que apuntas, de lejos: de cerca ya estás ahí y se baja volando hacia él)
			local body = if blend > 0.5 and not PlanetBodies.approachAt(pos) then PlanetBodies.aimed(pos, look, math.rad(3)) else nil
			local p = if body then Planets.ById[body.Id] else nil
			if p then
				if aimId ~= p.Id then
					aimId, aimSince = p.Id, t
				end
				aimed = p.Id
				if t - aimSince >= Planets.AimSeconds then
					setAction("Planet", p.Id)
				end
			else
				aimId = nil
				setAction(nil, nil)
			end
		end
	else
		aimId = nil
		setAction(nil, nil)
	end
	updatePlanets(camPos, blend, t, aimed)
end

---------------------------------------------------------------------
-- Lo que dice el servidor
---------------------------------------------------------------------
local function onEvent(kind: string, p: any)
	if type(p) ~= "table" then
		return
	end
	if kind == "Menu" then
		local token, options = p.Token, p.Options
		if type(token) ~= "string" or type(options) ~= "table" then
			return
		end
		task.spawn(function()
			local choice = Dialog.choose(tostring(p.Title or "Estación"), if type(p.Body) == "string" then p.Body else nil, options)
			if choice then
				fire("Menu", token, choice)
			end
		end)
	elseif kind == "Mine" then
		local ore = Mining.Ores[p.Ore or ""]
		if typeof(p.Pos) == "Vector3" then
			AirCombatFx.hit(p.Pos, nil, if ore then ore.Color else nil, true)
		end
		SoundFx.play("NaveImpacto", 1)
		local now = os.clock()
		if p.Full then
			Hud.toast("Info", ("⛏ Bodega llena (%d/%d): vende el mineral en la tienda de una estación"):format(p.Cargo or 0, Mining.CargoMax))
		elseif now - lastMineToast > 1.2 and ore then
			lastMineToast = now
			Hud.toast("Success", ("⛏ +1 %s · bodega %d/%d%s"):format(ore.Name, p.Cargo or 0, Mining.CargoMax, if p.Empty then " · asteroide agotado" else ""))
		end
	elseif kind == "Chip" then
		if typeof(p.Pos) == "Vector3" then
			AirCombatFx.hit(p.Pos, nil, if p.Dry then rgb(90, 90, 96) else rgb(200, 190, 170), false)
		end
	elseif kind == "Planet" then
		if type(p.Text) == "string" then
			Hud.toast(if p.Status == "Ready" then "Success" else "Info", p.Text)
		end
	end
end

function SpaceClient.init()
	remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Space", 10) :: RemoteEvent?
	if remote then
		remote.OnClientEvent:Connect(function(kind, payload)
			local ok, err = pcall(onEvent, kind, payload)
			if not ok then
				warn("[SpaceClient] " .. tostring(err))
			end
		end)
	end
	TouchLayout.register({
		Id = "NaveValmar",
		Icon = "casa",
		Label = "VALMAR",
		FlySlot = "ValmarNave",
		Priority = 1.4,
		Key = "V",
		Pad = "Y",
		Visible = inSpaceOrPlanetShip,
		Callback = goHome,
	})
	TouchLayout.register({
		Id = "NaveAccion",
		Icon = "puerta",
		Label = "ATRACAR",
		FlySlot = "AccionNave",
		Priority = 1.5,
		Key = "G",
		Pad = "X",
		Visible = function()
			return inCosmosShip() and action ~= nil
		end,
		Callback = doAction,
		Active = function()
			return action ~= nil
		end,
	})
	RunService:BindToRenderStep(STEP, Enum.RenderPriority.Camera.Value + 3, function(dt)
		local ok, err = pcall(step, dt)
		if not ok then
			warn("[SpaceClient] " .. tostring(err))
		end
	end)
end

-- (pruebas)
SpaceClient._onEvent = onEvent
SpaceClient._step = step

return SpaceClient
