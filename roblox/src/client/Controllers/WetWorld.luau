-- WetWorld (cliente): la lluvia y la nieve se notan en las cosas.
--
--   * Suelo y objetos al aire libre (calles, aceras, tejados, coches, bancos, fachadas): mojados se
--     ven más oscuros y brillan (reflejos en el asfalto); con nieve, lo de arriba se cubre de blanco.
--     Lo que está bajo techo no se moja. Al dejar de llover se secan poco a poco.
--   * Charcos que reflejan el cielo en las zonas llanas de calles y plazas, y gotas que salpican
--     al caer al suelo.
--   * Personas (jugadores y personajes): bajo la lluvia se mojan (ropa y pelo más oscuros y
--     gotean); a cubierto se secan.
--   * El coche que conduces levanta agua al pasar por el suelo mojado.
--   * La luz: con todo mojado, los reflejos del entorno se notan más.
--
-- Cuánto está mojado todo lo decide el servidor (workspace "Wet" y "Snow": WeatherService), así
-- que todos lo ven igual. Los cambios se hacen solo en tu pantalla y solo cerca de ti. Las cuentas
-- (cuánto oscurecer, cuánto brillar) están en shared/Wetness.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Seasons = require(ReplicatedStorage.Shared.Seasons)
local Wetness = require(ReplicatedStorage.Shared.Wetness)

local WetWorld = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB
local BLACK = Color3.new(0, 0, 0)
local SNOW = rgb(240, 244, 250)
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local RADIUS = 100 -- superficies que se mojan alrededor de la cámara
local NEW_PER_TICK = 350 -- piezas nuevas que se revisan cada vez (con un rayo hacia el cielo)
local PUDDLES = 16
local PEOPLE = 24

local folder: Folder

---------------------------------------------------------------------
-- Estado del tiempo
---------------------------------------------------------------------

local function raining(): number
	local info = Seasons.Weather[workspace:GetAttribute("Weather") or "Despejado"]
	return if info and info.Rain then info.Rain else 0
end

local function wetAmount(): number
	return workspace:GetAttribute("Wet") or 0
end

local function snowAmount(): number
	return workspace:GetAttribute("Snow") or 0
end

-- ¿Le cae el agua encima? (nada sólido por encima; las copas de los árboles no tapan)
local skyParams = RaycastParams.new()
skyParams.FilterType = Enum.RaycastFilterType.Exclude
local function exposed(point: Vector3, ignore: { Instance }): boolean
	skyParams.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(point, Vector3.new(0, 150, 0), skyParams)
	return hit == nil or hit.Instance.Transparency > 0.5 or hit.Material == Enum.Material.LeafyGrass
end

local function ignoreList(): { Instance }
	local list: { Instance } = { folder, workspace.CurrentCamera }
	for _, other in Players:GetPlayers() do
		if other.Character then
			table.insert(list, other.Character)
		end
	end
	return list
end

---------------------------------------------------------------------
-- Superficies
---------------------------------------------------------------------

type Surface = {
	Color: Color3, -- el suyo, sin mojar
	Reflectance: number,
	Floor: boolean,
	Exposed: boolean?,
	WrittenColor: Color3?, -- lo que pusimos (si alguien lo cambia, ese es su color nuevo)
	WrittenReflectance: number?,
	Key: number, -- nivel aplicado (mojado * 10 + nieve)
}

local surfaces: { [BasePart]: Surface } = {}
local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Exclude

local function isPerson(part: BasePart): boolean
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		if model:FindFirstChildOfClass("Humanoid") then
			return true
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return false
end

local function restoreSurface(part: BasePart, s: Surface)
	if s.WrittenColor and part.Color == s.WrittenColor then
		part.Color = s.Color
	end
	if s.WrittenReflectance and math.abs(part.Reflectance - s.WrittenReflectance) < 0.001 then
		part.Reflectance = s.Reflectance
	end
end

local function applySurface(part: BasePart, s: Surface, wet: number, snow: number)
	-- ¿Lo ha cambiado otro sistema (la estación, un fuego…)? Entonces ese es su color de verdad
	if s.WrittenColor and part.Color ~= s.WrittenColor then
		s.Color = part.Color
		s.Key = -1 -- hay que volver a mojarla
	end
	if s.WrittenReflectance and math.abs(part.Reflectance - s.WrittenReflectance) > 0.001 then
		s.Reflectance = part.Reflectance
		s.Key = -1
	end
	local key = wet * 10 + snow
	if key == s.Key then
		return
	end
	s.Key = key
	local darken, reflect, whiten = Wetness.surface(part.Material, wet, snow, s.Floor)
	local color = s.Color:Lerp(BLACK, darken):Lerp(SNOW, whiten)
	part.Color = color
	s.WrittenColor = part.Color
	local reflectance = math.max(s.Reflectance, reflect)
	part.Reflectance = reflectance
	s.WrittenReflectance = part.Reflectance
end

local function surfacesTick()
	local camera = workspace.CurrentCamera
	local wet = Wetness.level(wetAmount())
	local snow = Wetness.level(snowAmount())
	local ignore = ignoreList()
	if wet == 0 and snow == 0 then
		-- Todo seco: devolver lo que quedara cambiado
		for part, s in surfaces do
			if part.Parent then
				restoreSurface(part, s)
			end
		end
		table.clear(surfaces)
		return
	end
	overlap.FilterDescendantsInstances = ignore
	local near = workspace:GetPartBoundsInRadius(camera.CFrame.Position, RADIUS, overlap)
	local seen: { [BasePart]: boolean } = {}
	local checks = 0
	for _, part in near do
		seen[part] = true
		local s = surfaces[part]
		if not s then
			if not Wetness.canGetWet(part.Material, part.Transparency) or part:IsA("Terrain") then
				continue
			end
			local size = part.Size
			if math.max(size.X, size.Y, size.Z) < 0.4 or isPerson(part) then
				continue
			end
			s = {
				Color = part.Color,
				Reflectance = part.Reflectance,
				Floor = part.CFrame.UpVector.Y > 0.9,
				Exposed = nil,
				WrittenColor = nil,
				WrittenReflectance = nil,
				Key = 0,
			}
			surfaces[part] = s
		end
		local surface = s :: Surface
		if surface.Exposed == nil then
			if checks >= NEW_PER_TICK then
				continue -- ya se mirará en la siguiente vuelta
			end
			checks += 1
			local top = part.Position + Vector3.new(0, part.Size.Y / 2 + 0.05, 0)
			surface.Exposed = exposed(top, ignore)
		end
		if surface.Exposed then
			applySurface(part, surface, wet, snow)
		end
	end
	-- Lo que se ha quedado lejos vuelve a su color
	for part, s in surfaces do
		if not seen[part] then
			if part.Parent then
				restoreSurface(part, s)
			end
			surfaces[part] = nil
		end
	end
end

---------------------------------------------------------------------
-- Charcos y salpicaduras
---------------------------------------------------------------------

type Puddle = { Part: BasePart, Size: number, Placed: boolean }
local puddles: { Puddle } = {}
local splashPart: BasePart
local splash: ParticleEmitter

local PAVED = {
	Asphalt = true,
	Concrete = true,
	Pavement = true,
	Cobblestone = true,
	Slate = true,
	Granite = true,
	SmoothPlastic = true,
}

local function buildPuddles()
	for _ = 1, PUDDLES do
		local p = Instance.new("Part")
		p.Name = "Charco"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Shape = Enum.PartType.Cylinder
		p.Material = Enum.Material.Glass
		p.Color = rgb(58, 66, 78)
		p.Transparency = 1
		p.Reflectance = 0.5
		p.Size = Vector3.new(0.04, 1, 1)
		p.CFrame = CFrame.new(0, -500, 0)
		p.Parent = folder
		table.insert(puddles, { Part = p, Size = 4 + math.random() * 6, Placed = false })
	end
	-- Gotas que rebotan en el suelo alrededor de la cámara
	splashPart = Instance.new("Part")
	splashPart.Name = "Salpicaduras"
	splashPart.Anchored = true
	splashPart.CanCollide = false
	splashPart.CanQuery = false
	splashPart.CanTouch = false
	splashPart.Transparency = 1
	splashPart.Size = Vector3.new(70, 0.1, 70)
	splashPart.Parent = folder
	splash = Instance.new("ParticleEmitter")
	splash.Texture = SMOKE
	splash.Color = ColorSequence.new(rgb(210, 220, 235))
	splash.LightEmission = 0.2
	splash.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	splash.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(1, 0.02) })
	splash.Lifetime = NumberRange.new(0.15, 0.3)
	splash.Speed = NumberRange.new(3, 6)
	splash.SpreadAngle = Vector2.new(35, 35)
	splash.Acceleration = Vector3.new(0, -40, 0)
	splash.EmissionDirection = Enum.NormalId.Top
	splash.Rate = 0
	splash.Parent = splashPart
end

local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude

-- Busca un sitio llano de calle o plaza al aire libre cerca de la cámara
local function puddleSpot(around: Vector3, ignore: { Instance }): (Vector3?, Vector3?)
	groundParams.FilterDescendantsInstances = ignore
	for _ = 1, 3 do
		local angle = math.random() * math.pi * 2
		local r = 8 + math.random() * 45
		local from = around + Vector3.new(math.cos(angle) * r, 30, math.sin(angle) * r)
		local hit = workspace:Raycast(from, Vector3.new(0, -80, 0), groundParams)
		if hit and hit.Normal.Y > 0.97 and PAVED[hit.Material.Name] and exposed(hit.Position + Vector3.new(0, 0.2, 0), ignore) then
			return hit.Position, hit.Normal
		end
	end
	return nil, nil
end

local function puddlesTick(wet: number, rain: number, indoor: boolean)
	local camera = workspace.CurrentCamera
	local around = camera.CFrame.Position
	local ignore = ignoreList()
	-- Charcos: aparecen cuando ya está bastante mojado y crecen con la lluvia
	local grow = math.clamp((wet - 0.3) / 0.7, 0, 1)
	local tries = 0
	for _, puddle in puddles do
		local p = puddle.Part
		local far = (p.Position - around).Magnitude > 75
		if grow <= 0 then
			if puddle.Placed then
				p.Transparency = 1
				p.CFrame = CFrame.new(0, -500, 0)
				puddle.Placed = false
			end
		elseif (not puddle.Placed or far) and tries < 4 then
			tries += 1
			local at = puddleSpot(around, ignore)
			if at then
				-- Un poco ovalado y girado: no todos iguales
				local d = puddle.Size
				p.Size = Vector3.new(0.04, d, d * (0.6 + math.random() * 0.4))
				p.CFrame = CFrame.new(at + Vector3.new(0, 0.03, 0)) * CFrame.Angles(0, math.random() * 6.28, 0) * CFrame.Angles(0, 0, math.rad(90))
				puddle.Placed = true
			end
		end
		if puddle.Placed then
			p.Transparency = 1 - 0.55 * grow
		end
	end
	-- Salpicaduras a ras de suelo bajo la cámara
	if rain > 0 and not indoor then
		groundParams.FilterDescendantsInstances = ignore
		local hit = workspace:Raycast(around, Vector3.new(0, -120, 0), groundParams)
		if hit then
			splashPart.CFrame = CFrame.new(hit.Position + Vector3.new(0, 0.1, 0))
			splash.Rate = 260 * rain
			splash.Enabled = true
			return
		end
	end
	splash.Enabled = false
end

---------------------------------------------------------------------
-- Personas mojadas
---------------------------------------------------------------------

type Person = {
	Model: Model,
	Head: BasePart,
	Wet: number,
	Parts: { [BasePart]: { Color: Color3, Written: Color3? } },
	Level: number,
	Drips: ParticleEmitter?,
}
local people: { [Model]: Person } = {}

local function drips(head: BasePart): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = "Goteo"
	e.Texture = SMOKE
	e.Color = ColorSequence.new(rgb(190, 210, 235))
	e.LightEmission = 0.1
	e.Transparency = NumberSequence.new(0.35)
	e.Size = NumberSequence.new(0.07)
	e.Squash = NumberSequence.new(-1.5)
	e.Lifetime = NumberRange.new(0.5, 0.8)
	e.Speed = NumberRange.new(0, 1)
	e.Acceleration = Vector3.new(0, -30, 0)
	e.EmissionDirection = Enum.NormalId.Bottom
	e.SpreadAngle = Vector2.new(60, 60)
	e.Rate = 0
	e.Parent = head
	return e
end

local function dressWet(person: Person, level: number)
	for part, info in person.Parts do
		if not part.Parent then
			person.Parts[part] = nil
			continue
		end
		-- Si otro sistema le ha cambiado la ropa, ese es su color de verdad
		if info.Written and part.Color ~= info.Written then
			info.Color = part.Color
		end
		part.Color = info.Color:Lerp(BLACK, 0.28 * level)
		info.Written = part.Color
	end
end

local function trackPerson(model: Model): Person?
	local head = model:FindFirstChild("Head") :: BasePart?
	if not head or not model:FindFirstChildOfClass("Humanoid") then
		return nil
	end
	local person: Person = { Model = model, Head = head, Wet = 0, Parts = {}, Level = 0, Drips = nil }
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 0.9 and not d.Name:match("^WorkProp_") and d.Material ~= Enum.Material.Glass and d.Material ~= Enum.Material.Neon then
			person.Parts[d] = { Color = d.Color, Written = nil }
		end
	end
	return person
end

local function releasePerson(person: Person)
	dressWet(person, 0)
	if person.Drips then
		person.Drips:Destroy()
	end
end

local function peopleTick(dt: number, rain: number)
	local camera = workspace.CurrentCamera
	local from = camera.CFrame.Position
	local ignore = ignoreList()
	-- Los más cercanos (jugadores y personajes con Humanoid)
	local candidates = {}
	for _, other in Players:GetPlayers() do
		local character = other.Character
		local head = character and character:FindFirstChild("Head") :: BasePart?
		if character and head and (head.Position - from).Magnitude < 80 then
			table.insert(candidates, { Model = character, Distance = (head.Position - from).Magnitude })
		end
	end
	for model in people do
		if model.Parent and not Players:GetPlayerFromCharacter(model) then
			local head = model:FindFirstChild("Head") :: BasePart?
			if head then
				table.insert(candidates, { Model = model, Distance = (head.Position - from).Magnitude })
			end
		end
	end
	-- Personajes del mapa cerca (una búsqueda pequeña)
	overlap.FilterDescendantsInstances = { folder, camera }
	for _, part in workspace:GetPartBoundsInRadius(from, 40, overlap) do
		if part.Name == "Head" and part.Parent and part.Parent:IsA("Model") and not people[part.Parent] and part.Parent:FindFirstChildOfClass("Humanoid") then
			table.insert(candidates, { Model = part.Parent, Distance = (part.Position - from).Magnitude })
		end
	end
	table.sort(candidates, function(a, b)
		return a.Distance < b.Distance
	end)
	local keep: { [Model]: boolean } = {}
	for i, c in candidates do
		if i > PEOPLE then
			break
		end
		keep[c.Model] = true
		local person = people[c.Model]
		if not person then
			person = trackPerson(c.Model)
			if not person then
				continue
			end
			people[c.Model] = person
		end
		local p = person :: Person
		local sheltered = not exposed(p.Head.Position + Vector3.new(0, 1, 0), ignore)
		p.Wet = Wetness.person(p.Wet, rain, sheltered, dt)
		local level = Wetness.level(p.Wet)
		if level ~= p.Level then
			p.Level = level
			dressWet(p, level)
		end
		if p.Wet > 0.2 then
			if not p.Drips then
				p.Drips = drips(p.Head)
			end
			(p.Drips :: ParticleEmitter).Rate = 14 * p.Wet
		elseif p.Drips then
			p.Drips:Destroy()
			p.Drips = nil
		end
	end
	for model, person in people do
		if not keep[model] then
			if model.Parent then
				releasePerson(person)
			end
			people[model] = nil
		end
	end
end

---------------------------------------------------------------------
-- Agua que levantan las ruedas del coche que conduces
---------------------------------------------------------------------

local spray: ParticleEmitter?
local sprayOn: BasePart?

local function sprayTick(wet: number)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	local model = seat and seat:IsA("VehicleSeat") and seat.Parent
	local chassis = model and model:IsA("Model") and model.PrimaryPart
	if not chassis or wet < 0.3 then
		if spray then
			spray.Enabled = false
		end
		return
	end
	if sprayOn ~= chassis then
		if spray then
			spray.Parent:Destroy()
		end
		local attachment = Instance.new("Attachment")
		attachment.Name = "Rocio"
		attachment.Position = Vector3.new(0, -chassis.Size.Y / 2, chassis.Size.Z / 2)
		attachment.Parent = chassis
		local e = Instance.new("ParticleEmitter")
		e.Texture = SMOKE
		e.Color = ColorSequence.new(rgb(200, 210, 222))
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 2) })
		e.Lifetime = NumberRange.new(0.4, 0.7)
		e.Speed = NumberRange.new(4, 8)
		e.SpreadAngle = Vector2.new(30, 15)
		e.EmissionDirection = Enum.NormalId.Back
		e.Acceleration = Vector3.new(0, -8, 0)
		e.Parent = attachment
		spray = e
		sprayOn = chassis
	end
	local speed = chassis.AssemblyLinearVelocity.Magnitude
	local s = spray :: ParticleEmitter
	s.Rate = wet * math.clamp((speed - 8) / 30, 0, 1) * 80
	s.Enabled = s.Rate > 1
end

---------------------------------------------------------------------

local baseSpecular = 1
local baseDiffuse = 1

function WetWorld.init()
	folder = Instance.new("Folder")
	folder.Name = "WetWorld"
	folder.Parent = workspace.CurrentCamera -- solo para este jugador
	buildPuddles()
	baseSpecular = Lighting.EnvironmentSpecularScale
	baseDiffuse = Lighting.EnvironmentDiffuseScale

	-- Superficies: cada segundo y medio
	task.spawn(function()
		while true do
			task.wait(1.5)
			local ok, err = pcall(surfacesTick)
			if not ok then
				warn("[WetWorld] " .. tostring(err))
			end
		end
	end)

	-- Charcos, personas, luz y el agua de las ruedas: cada medio segundo
	local roofParams = RaycastParams.new()
	roofParams.FilterType = Enum.RaycastFilterType.Exclude
	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(0.5)
			local now = os.clock()
			local dt = now - last
			last = now
			local ok, err = pcall(function()
				local wet = wetAmount()
				local rain = raining()
				local camera = workspace.CurrentCamera
				roofParams.FilterDescendantsInstances = ignoreList()
				local roof = workspace:Raycast(camera.CFrame.Position, Vector3.new(0, 80, 0), roofParams)
				local indoor = roof ~= nil and roof.Instance.Transparency < 0.5 and roof.Material ~= Enum.Material.LeafyGrass
				puddlesTick(wet, rain, indoor)
				peopleTick(dt, rain)
				sprayTick(wet)
				-- Con todo mojado, los reflejos del entorno brillan más
				Lighting.EnvironmentSpecularScale = baseSpecular + (1 - baseSpecular) * 0.8 * wet
				Lighting.EnvironmentDiffuseScale = baseDiffuse * (1 - 0.15 * wet)
			end)
			if not ok then
				warn("[WetWorld] " .. tostring(err))
			end
		end
	end)
end

return WetWorld
