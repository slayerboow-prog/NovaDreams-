-- SeasonDecor (cliente): los detalles de la estación y del agua alrededor de la cámara (v126,
-- docs/clima/estaciones.md). Todo en tu pantalla, solo en Valmar, cerca de ti y con piezas reutilizadas
-- (los topes por nivel gráfico están en shared/Wetness.Budget):
--
--   * GOTEO de tejados, toldos y balcones: mientras llueve, y un rato después mientras sigue mojado,
--     cae una cortina de gotas por el borde del toldo o del saliente que tienes encima o al lado.
--   * VAPOR tras la lluvia de verano: con sol y el suelo aún mojado, una neblina baja que sube del
--     asfalto caliente (Wetness.steam).
--   * LUCES DE FIESTA en la plaza del centro (del 1 de diciembre al 6 de enero, workspace "Festive"):
--     un árbol de luces genérico (guirnaldas de bombillas que bajan de un mástil y una estrella), que se
--     enciende al anochecer. Sin marcas ni nada de fuera.
-- Nada de esto en el espacio, en los planetas, bajo el mar ni en el metro.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameClock = require(ReplicatedStorage.Shared.GameClock) -- (la hora del juego: GameClock.hour())
local Wetness = require(ReplicatedStorage.Shared.Wetness)
local RainLook = require(ReplicatedStorage.Shared.RainLook)
local Metro = require(ReplicatedStorage.Shared.Metro)
local TerrainPalette = require(ReplicatedStorage.Shared.TerrainPalette)
local Perf = require(script.Parent.Parent.UI.Perf)

local SeasonDecor = {}

local rgb = Color3.fromRGB
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local MAX_DRIPS = 5 -- (el tope de Alto; el nivel gráfico baja cuántos se usan)
local DRIP_REACH = 26 -- un toldo o balcón hasta esta altura sobre la cámara
local PLAZA = Vector3.new(0, 0, 0) -- Valmar Centro (shared/CityPlan.Towns)
local PLAZA_NEAR = 700 -- el árbol de luces se monta con la cámara a menos de esto

local folder: Folder
type Drip = { Part: BasePart, Emitter: ParticleEmitter, Owner: BasePart?, Edge: number }
local drips: { Drip } = {}
local steamPart: BasePart
local steam: ParticleEmitter
local tree: Model? = nil
local treeLit: boolean? = nil

local function envAllows(): boolean
	local ok, allowed = pcall(function()
		return require(script.Parent.EnvDirector).allows("Weather")
	end)
	return not ok or allowed ~= false
end

local function rainNow(): number
	local ok, level = pcall(function()
		return require(script.Parent.Weather).rainLevel()
	end)
	return if ok and type(level) == "number" then level else 0
end

local function invisiblePart(name: string, size: Vector3): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = 1
	p.Size = size
	p.CFrame = CFrame.new(0, -800, 0)
	p.Parent = folder
	return p
end

local function build()
	folder = Instance.new("Folder")
	folder.Name = "SeasonDecor"
	folder.Parent = workspace.CurrentCamera
	for i = 1, MAX_DRIPS do
		local p = invisiblePart("Goteo" .. i, Vector3.new(4, 0.1, 0.2))
		local e = Instance.new("ParticleEmitter")
		e.Name = "Gotas"
		e.Texture = SMOKE
		e.Color = ColorSequence.new(rgb(206, 216, 232))
		e.LightEmission = 0.25
		e.LightInfluence = 0.7
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0.7) })
		e.Size = NumberSequence.new(0.07)
		e.Squash = NumberSequence.new(2.2)
		e.Orientation = Enum.ParticleOrientation.VelocityParallel
		e.EmissionDirection = Enum.NormalId.Bottom
		e.Speed = NumberRange.new(2, 4)
		e.Acceleration = Vector3.new(0, -70, 0)
		e.Lifetime = NumberRange.new(0.5, 0.8)
		e.Rate = 0
		e.Enabled = false
		e.Parent = p
		table.insert(drips, { Part = p, Emitter = e, Owner = nil, Edge = 0 })
	end
	steamPart = invisiblePart("Vapor", Vector3.new(60, 0.2, 60))
	steam = Instance.new("ParticleEmitter")
	steam.Name = "Vapor"
	steam.Texture = SMOKE
	steam.Color = ColorSequence.new(rgb(236, 238, 242))
	steam.LightEmission = 0.1
	steam.LightInfluence = 1
	steam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.88), NumberSequenceKeypoint.new(1, 1) })
	steam.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 8) })
	steam.Speed = NumberRange.new(0.4, 1.1)
	steam.Acceleration = Vector3.new(0.3, 0.25, 0.2)
	steam.EmissionDirection = Enum.NormalId.Top
	steam.Lifetime = NumberRange.new(4, 6)
	steam.RotSpeed = NumberRange.new(-12, 12)
	steam.Rate = 0
	steam.Enabled = false
	steam.Parent = steamPart
end

---------------------------------------------------------------------
-- Goteo de toldos, balcones y tejados
---------------------------------------------------------------------

local coverParams = RaycastParams.new()
coverParams.FilterType = Enum.RaycastFilterType.Exclude

local function ignoreList(): { Instance }
	local list: { Instance } = { workspace.CurrentCamera }
	for _, other in Players:GetPlayers() do
		if other.Character then
			table.insert(list, other.Character)
		end
	end
	return list
end

-- Los toldos o salientes cerca: encima de la cámara y un poco alrededor
local PROBES = { Vector3.new(0, 0, 0), Vector3.new(7, 0, 0), Vector3.new(-7, 0, 0), Vector3.new(0, 0, 7), Vector3.new(0, 0, -7) }
local function coversNear(at: Vector3, want: number): { BasePart }
	coverParams.FilterDescendantsInstances = ignoreList()
	local found: { BasePart } = {}
	local seen: { [BasePart]: boolean } = {}
	for _, offset in PROBES do
		if #found >= want then
			break
		end
		local hit = workspace:Raycast(at + offset, Vector3.new(0, DRIP_REACH, 0), coverParams)
		local part = hit and hit.Instance
		if part and part:IsA("BasePart") and not seen[part] and RainLook.blocksRain(part.Transparency, hit.Material.Name) then
			local size = part.Size
			-- (un toldo, una marquesina, un balcón o el alero: no una fachada entera ni un edificio)
			if size.Y < 6 and math.max(size.X, size.Z) < 140 then
				seen[part] = true
				table.insert(found, part)
			end
		end
	end
	return found
end

local function placeDrip(d: Drip, part: BasePart, camPos: Vector3, rate: number)
	local local_ = part.CFrame:PointToObjectSpace(camPos)
	local center, length, alongX = Wetness.dripEdge(part.Size, Vector3.new(local_.X, 0, local_.Z))
	-- (un borde largo se recorta a la zona que tienes delante)
	local span = math.min(length, 20)
	local slide = 0
	if length > span then
		local along = if alongX then local_.X else local_.Z
		slide = math.clamp(along, -(length - span) / 2, (length - span) / 2)
	end
	local offset = if alongX then Vector3.new(slide, 0, 0) else Vector3.new(0, 0, slide)
	local cf = part.CFrame * CFrame.new(center + offset - Vector3.new(0, 0.05, 0))
	d.Part.Size = if alongX then Vector3.new(span, 0.1, 0.2) else Vector3.new(0.2, 0.1, span)
	d.Part.CFrame = cf
	d.Owner = part
	d.Edge = span
	d.Emitter.Rate = rate
	d.Emitter.Enabled = rate > 0
end

local function releaseDrip(d: Drip)
	d.Owner = nil
	d.Emitter.Enabled = false
	d.Emitter.Rate = 0
	d.Part.CFrame = CFrame.new(0, -800, 0)
end

local function dripsTick(active: boolean)
	local camera = workspace.CurrentCamera
	local budget = Wetness.budget(Perf.tierName())
	local rain = rainNow()
	local wet = workspace:GetAttribute("Wet") or 0
	if not active or not camera or (rain <= 0.02 and wet <= 0.3) then
		for _, d in drips do
			if d.Owner then
				releaseDrip(d)
			end
		end
		return
	end
	local at = camera.CFrame.Position
	local covers = coversNear(at, budget.Drips)
	for i, d in drips do
		local part = covers[i]
		if i > budget.Drips or not part then
			if d.Owner then
				releaseDrip(d)
			end
		else
			placeDrip(d, part, at, Wetness.dripRate(rain, wet, d.Edge > 0 and d.Edge or 10, budget.DripRate))
		end
	end
end

---------------------------------------------------------------------
-- Vapor tras la lluvia de verano
---------------------------------------------------------------------

local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude

local function steamTick(active: boolean, indoor: boolean)
	local camera = workspace.CurrentCamera
	local amount = if active and not indoor then Wetness.steam(workspace:GetAttribute("Season"), workspace:GetAttribute("Weather"), workspace:GetAttribute("Wet") or 0, GameClock.hour()) else 0
	local rate = math.floor(amount * Wetness.budget(Perf.tierName()).Steam + 0.5)
	if rate <= 0 or not camera then
		steam.Enabled = false
		return
	end
	groundParams.FilterDescendantsInstances = ignoreList()
	local hit = workspace:Raycast(camera.CFrame.Position, Vector3.new(0, -80, 0), groundParams)
	if not hit then
		steam.Enabled = false
		return
	end
	steamPart.CFrame = CFrame.new(hit.Position + Vector3.new(0, 0.3, 0))
	steam.Rate = rate
	steam.Enabled = true
end

---------------------------------------------------------------------
-- Luces de fiesta en la plaza (genéricas)
---------------------------------------------------------------------

local OPEN_GROUND = { Cobblestone = true, Concrete = true, Pavement = true, Granite = true, Brick = true, Asphalt = true, Marble = true, Limestone = true }
local BULB_COLORS = { rgb(255, 214, 140), rgb(255, 236, 200), rgb(236, 70, 60), rgb(255, 200, 80), rgb(80, 180, 110) }

-- Un sitio llano y despejado cerca del centro de la plaza (sin la fuente ni bancos encima)
local function plazaSpot(): Vector3?
	groundParams.FilterDescendantsInstances = ignoreList()
	local box = OverlapParams.new()
	box.FilterType = Enum.RaycastFilterType.Exclude
	box.FilterDescendantsInstances = ignoreList()
	for ring = 0, 3 do
		local radius = ring * 22
		local steps = if ring == 0 then 1 else 8
		for k = 0, steps - 1 do
			local a = k / steps * math.pi * 2
			local from = PLAZA + Vector3.new(math.cos(a) * radius, 220, math.sin(a) * radius)
			local hit = workspace:Raycast(from, Vector3.new(0, -300, 0), groundParams)
			if hit and hit.Normal.Y > 0.98 and OPEN_GROUND[hit.Material.Name] then
				local inside = workspace:GetPartBoundsInBox(CFrame.new(hit.Position + Vector3.new(0, 11, 0)), Vector3.new(18, 20, 18), box)
				if #inside == 0 then
					return hit.Position
				end
			end
		end
	end
	return nil
end

local function bulb(parent: Instance, at: Vector3, color: Color3, size: number): BasePart
	local p = Instance.new("Part")
	p.Name = "Bombilla"
	p.Shape = Enum.PartType.Ball
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Size = Vector3.new(size, size, size)
	p.CFrame = CFrame.new(at)
	p.Parent = parent
	return p
end

local function buildTree(at: Vector3)
	local model = Instance.new("Model")
	model.Name = "ArbolDeLuces"
	local bulbs = Wetness.budget(Perf.tierName()).Bulbs
	local strings = if bulbs >= 96 then 16 else 12
	local perString = math.max(4, math.floor(bulbs / strings))
	local height, radius = 24, 8.5
	local top = at + Vector3.new(0, height, 0)
	-- Mástil fino
	local mast = Instance.new("Part")
	mast.Name = "Mastil"
	mast.Anchored = true
	mast.CanCollide = true
	mast.CanQuery = false
	mast.CanTouch = false
	mast.Material = Enum.Material.Metal
	mast.Color = rgb(60, 62, 68)
	mast.Size = Vector3.new(0.6, height, 0.6)
	mast.CFrame = CFrame.new(at + Vector3.new(0, height / 2, 0))
	mast.Parent = model
	for s = 0, strings - 1 do
		local a = s / strings * math.pi * 2
		local foot = at + Vector3.new(math.cos(a) * radius, 0.8, math.sin(a) * radius)
		for b = 1, perString do
			local t = b / (perString + 1)
			-- (la guirnalda cuelga un poco: curva hacia abajo en el medio)
			local p = top:Lerp(foot, t) - Vector3.new(0, math.sin(t * math.pi) * 0.9, 0)
			bulb(model, p, BULB_COLORS[(s + b) % #BULB_COLORS + 1], 0.42)
		end
	end
	local star = bulb(model, top + Vector3.new(0, 0.8, 0), rgb(255, 222, 120), 1.6)
	star.Name = "Estrella"
	for _, y in { height * 0.45, height } do
		local holder = Instance.new("Attachment")
		holder.Position = Vector3.new(0, y - height / 2, 0)
		holder.Parent = mast
		local light = Instance.new("PointLight")
		light.Color = rgb(255, 214, 160)
		light.Range = 22
		light.Brightness = 0
		light.Shadows = false
		light.Parent = holder
	end
	model.Parent = folder
	tree = model
	treeLit = nil
end

local function lightTree(on: boolean)
	if not tree or treeLit == on then
		return
	end
	treeLit = on
	for _, item in tree:GetDescendants() do
		if item:IsA("BasePart") and item.Name ~= "Mastil" then
			item.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
			item.Transparency = if on then 0 else 0.15
		elseif item:IsA("PointLight") then
			item.Brightness = if on then 1.2 else 0
		end
	end
end

local tried = false
local function festiveTick(active: boolean)
	local camera = workspace.CurrentCamera
	local festive = workspace:GetAttribute("Festive") == true
	local near = camera ~= nil and (camera.CFrame.Position * Vector3.new(1, 0, 1) - PLAZA).Magnitude < PLAZA_NEAR
	if not festive then
		if tree then
			tree:Destroy()
			tree = nil
		end
		tried = false
		return
	end
	if active and near and not tree and not tried then
		tried = true -- (se busca sitio una vez; si no hay, no se insiste)
		local spot = plazaSpot()
		if spot then
			buildTree(spot)
		end
	end
	if tree then
		-- Se encienden al atardecer (y con el cielo muy tapado)
		lightTree(GameClock.darkness() > 0.25 or (workspace:GetAttribute("Weather") == "Tormenta"))
	end
end

---------------------------------------------------------------------

function SeasonDecor.init()
	build()
	task.spawn(function()
		while true do
			task.wait(0.5)
			local camera = workspace.CurrentCamera
			local at = if camera then camera.CFrame.Position else Vector3.new()
			local active = envAllows() and at.Y > Metro.Underground and TerrainPalette.inValmar(at)
			local okShelter, shelter = pcall(function()
				return require(script.Parent.Shelter).camera()
			end)
			local indoor = okShelter and shelter.Enclosed == true
			for _, fn in { function()
				dripsTick(active and not indoor)
			end, function()
				steamTick(active, indoor)
			end, function()
				festiveTick(active)
			end } do
				local ok, err = pcall(fn)
				if not ok then
					warn("[SeasonDecor] " .. tostring(err))
				end
			end
		end
	end)
end

return SeasonDecor
