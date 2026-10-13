-- WetWorld (cliente): la lluvia y la nieve se notan en las cosas.
--
--   * Suelo y objetos al aire libre (calles, aceras, tejados, coches, bancos, fachadas): mojados se
--     ven más oscuros y brillan (reflejos en el asfalto); con nieve, lo de arriba se cubre de blanco.
--     Lo que está bajo techo no se moja. Al dejar de llover se secan poco a poco.
--   * Charcos de borde suave junto a bordillos y en calles y plazas llanas, y gotas que salpican
--     al caer al suelo.
--   * Personas (jugadores y personajes): bajo la lluvia se mojan (ropa y pelo más oscuros y
--     gotean); a cubierto se secan.
--   * El coche que conduces levanta agua al pasar por el suelo mojado.
--   * La luz: con todo mojado, los reflejos del entorno se notan más (eso lo pinta DayLight con
--     shared/DayGrade.weather; antes se escribía también aquí y las dos se pisaban: parpadeaba de noche).
--   * Nivel gráfico (UI/Perf): cuántos charcos y en qué radio se moja el suelo (shared/Graphics).
--
-- Cuánto está mojado todo lo decide el servidor (workspace "Wet" y "Snow": WeatherService), así
-- que todos lo ven igual. Los cambios se hacen solo en tu pantalla y solo cerca de ti. Las cuentas
-- (cuánto oscurecer, cuánto brillar) están en shared/Wetness.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Seasons = require(ReplicatedStorage.Shared.Seasons)
local Wetness = require(ReplicatedStorage.Shared.Wetness)
local Perf = require(script.Parent.Parent.UI.Perf)
local RainLook = require(ReplicatedStorage.Shared.RainLook)
local Shelter = require(script.Parent.Shelter)
local DayGrade = require(ReplicatedStorage.Shared.DayGrade)

local WetWorld = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB
local BLACK = Color3.new(0, 0, 0)
local SNOW = rgb(240, 244, 250)
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local RADIUS = 100 -- superficies que se mojan alrededor de la cámara (como mucho: lo baja el nivel gráfico)
local NEW_PER_TICK = 350 -- piezas nuevas que se revisan cada vez (con un rayo hacia el cielo)
local PUDDLES = 16 -- (como mucho: el nivel gráfico dice cuántos se usan)
local PEOPLE = 24

local folder: Folder

---------------------------------------------------------------------
-- Estado del tiempo
---------------------------------------------------------------------

-- La lluvia que se VE ahora (Controllers/Weather: entra y sale poco a poco, llovizna o chaparrón).
-- Si Weather aún no ha arrancado, la del tiempo que dice el servidor.
local function raining(): number
	local ok, level = pcall(function()
		return require(script.Parent.Weather).rainLevel()
	end)
	if ok and type(level) == "number" then
		return level
	end
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
	return hit == nil or not RainLook.blocksRain(hit.Instance.Transparency, hit.Material.Name)
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
	local near = workspace:GetPartBoundsInRadius(camera.CFrame.Position, math.min(RADIUS, Perf.tier().WetRadius), overlap)
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

-- Charcos (v109, el dueño: «los charcos son muy falsos»): antes eran discos de cristal (cilindros
-- con bordes duros, todos redondos, cristal azulado) puestos al azar, también en tejados bajos. Ahora:
--   * Forma: dos manchas de borde suave (imagen de humo de Roblox, con transparencia que se difumina),
--     de distinto tamaño y giro, encima una de otra: cada charco es irregular. Sin pieza visible.
--   * Superficie: la pieza es invisible y muy fina, 0,04 por encima del suelo (sin parpadeos); la mancha
--     oscurece y enfría el suelo (agua que refleja el cielo gris) y otra más clara y tenue da el brillo.
--     Con lluvia, ondas pequeñas que se abren SOLO dentro de los charcos (Medio y Alto).
--   * Sitio: solo calzada, acera y plaza llana al aire libre, a la altura del suelo donde estás (nada
--     de tejados ni coches), y sobre todo junto al bordillo o una pared (RainLook.puddleSpot).
--   * Aparecen y se van poco a poco con lo mojado que está todo (RainLook.puddleOpacity).
type Puddle = { Part: BasePart, Lobe: BasePart, Dark: Decal, LobeDark: Decal, Sheen: Decal, Ripples: ParticleEmitter, Size: number, Placed: boolean, Shown: number }
local puddles: { Puddle } = {}
local splashPart: BasePart
local splash: ParticleEmitter

local function buildPuddles()
	for _ = 1, PUDDLES do
		local p = Instance.new("Part")
		p.Name = "Charco"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Transparency = 1
		p.Size = Vector3.new(4, 0.02, 4)
		p.CFrame = CFrame.new(0, -500, 0)
		p.Parent = folder
		-- Agua: mancha oscura y fría de borde suave
		local dark = Instance.new("Decal")
		dark.Name = "Agua"
		dark.Face = Enum.NormalId.Top
		dark.Texture = SMOKE
		dark.Color3 = rgb(34, 40, 50)
		dark.Transparency = 1
		dark.ZIndex = 1
		dark.Parent = p
		-- Brillo: el cielo gris que se refleja, más claro y muy tenue
		local sheen = Instance.new("Decal")
		sheen.Name = "Brillo"
		sheen.Face = Enum.NormalId.Top
		sheen.Texture = SMOKE
		sheen.Color3 = rgb(150, 162, 180)
		sheen.Transparency = 1
		sheen.ZIndex = 2
		sheen.Parent = p
		-- Ondas que se abren en el agua al caer las gotas (tumbadas: VelocityPerpendicular hacia arriba)
		local ripples = Instance.new("ParticleEmitter")
		ripples.Name = "Ondas"
		ripples.Texture = SMOKE
		ripples.Color = ColorSequence.new(rgb(196, 206, 222))
		ripples.LightEmission = 0.1
		ripples.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
		ripples.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.78), NumberSequenceKeypoint.new(1, 1) })
		ripples.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 0.7) })
		ripples.Lifetime = NumberRange.new(0.4, 0.6)
		ripples.Speed = NumberRange.new(0.01, 0.02)
		ripples.EmissionDirection = Enum.NormalId.Top
		ripples.Rate = 0
		ripples.Enabled = false
		ripples.Parent = p
		-- Segunda mancha, más pequeña y desplazada: el borde del charco no es un óvalo perfecto
		local lobe = p:Clone()
		lobe:ClearAllChildren()
		lobe.Name = "CharcoBorde"
		lobe.Parent = folder
		local lobeDark = dark:Clone()
		lobeDark.Parent = lobe
		table.insert(puddles, { Part = p, Lobe = lobe, Dark = dark, LobeDark = lobeDark, Sheen = sheen, Ripples = ripples, Size = 3 + math.random() * 5, Placed = false, Shown = 0 })
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

-- Busca un sitio para un charco: calzada, acera o plaza llana al aire libre, a la altura del suelo que
-- hay bajo la cámara (nada de tejados, coches ni bancos) y mejor junto al bordillo o una pared
local EDGE_DIRS = { Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis }
local function puddleSpot(around: Vector3, groundY: number, ignore: { Instance }): Vector3?
	groundParams.FilterDescendantsInstances = ignore
	for _ = 1, 4 do
		local angle = math.random() * math.pi * 2
		local r = 8 + math.random() * 40
		local from = Vector3.new(around.X + math.cos(angle) * r, groundY + 6, around.Z + math.sin(angle) * r)
		local hit = workspace:Raycast(from, Vector3.new(0, -14, 0), groundParams)
		if hit and exposed(hit.Position + Vector3.new(0, 0.2, 0), ignore) then
			-- ¿Bordillo o pared al lado? (un rayo corto a ras de suelo)
			local edge = false
			for _, dir in EDGE_DIRS do
				if workspace:Raycast(hit.Position + Vector3.new(0, 0.35, 0), dir * 4, groundParams) then
					edge = true
					break
				end
			end
			if RainLook.puddleSpot(hit.Material.Name, hit.Normal.Y, hit.Position.Y - groundY, edge, math.random()) then
				return hit.Position
			end
		end
	end
	return nil
end

local function showPuddle(puddle: Puddle, alpha: number, rippleRate: number)
	puddle.Shown = alpha
	puddle.Dark.Transparency = 1 - 0.62 * alpha
	puddle.LobeDark.Transparency = 1 - 0.5 * alpha
	puddle.Sheen.Transparency = 1 - 0.22 * alpha
	puddle.Ripples.Rate = if alpha > 0.5 then rippleRate else 0
	puddle.Ripples.Enabled = puddle.Ripples.Rate > 0
end

local function puddlesTick(wet: number, rain: number, indoor: boolean)
	local camera = workspace.CurrentCamera
	local around = camera.CFrame.Position
	local ignore = ignoreList()
	-- Cuánto se ven: nada en seco, aparecen cuando ya está bastante mojado (y se van al secarse)
	local target = RainLook.puddleOpacity(wet)
	local tries = 0
	local budget = Perf.tier().Puddles
	-- El suelo bajo la cámara (los charcos van a esa altura)
	groundParams.FilterDescendantsInstances = ignore
	local floor = workspace:Raycast(around, Vector3.new(0, -60, 0), groundParams)
	local groundY = if floor then floor.Position.Y else nil
	local fall = RainLook.falling(rain, Perf.tierName())
	-- Ondas: unas pocas por charco (las de RainLook son para toda la zona)
	local rippleRate = if rain > 0.02 and not indoor then math.floor(fall.RippleRate / 6) else 0
	for i, puddle in puddles do
		local p = puddle.Part
		local far = (p.Position - around).Magnitude > 70
		if target <= 0 or i > budget then
			if puddle.Placed then
				-- Se seca poco a poco y, ya invisible, se aparta
				local alpha = RainLook.approach(puddle.Shown, 0, 0.5, 6)
				showPuddle(puddle, alpha, 0)
				if alpha <= 0 then
					p.CFrame = CFrame.new(0, -500, 0)
					puddle.Lobe.CFrame = p.CFrame
					puddle.Placed = false
				end
			end
			continue
		end
		if (not puddle.Placed or far) and tries < 3 and groundY then
			tries += 1
			local at = puddleSpot(around, groundY :: number, ignore)
			if at then
				-- Forma irregular: ovalado, girado, y la mancha clara algo más pequeña y movida
				local d = puddle.Size * (0.8 + 0.4 * target)
				p.Size = Vector3.new(d, 0.02, d * (0.45 + math.random() * 0.4))
				p.CFrame = CFrame.new(at + Vector3.new(0, 0.04, 0)) * CFrame.Angles(0, math.random() * 6.28, 0)
				local spin = math.random() * 6.28
				local offset = Vector3.new(math.cos(spin), 0, math.sin(spin)) * d * (0.25 + math.random() * 0.15)
				puddle.Lobe.Size = Vector3.new(d * (0.45 + math.random() * 0.2), 0.02, d * (0.3 + math.random() * 0.2))
				-- (un pelo más alta que la otra: dos imágenes en el mismo plano parpadean)
				puddle.Lobe.CFrame = CFrame.new(at + offset + Vector3.new(0, 0.045, 0)) * CFrame.Angles(0, math.random() * 6.28, 0)
				puddle.Placed = true
				showPuddle(puddle, 0, 0) -- (aparece poco a poco, no de golpe)
			end
		end
		if puddle.Placed then
			showPuddle(puddle, RainLook.approach(puddle.Shown, target, 0.5, 4), rippleRate)
		end
	end
	-- Salpicaduras a ras de suelo alrededor (y ondas en el agua), según la intensidad y el nivel gráfico
	if rain > 0.02 and not indoor then
		groundParams.FilterDescendantsInstances = ignore
		local hit = workspace:Raycast(around, Vector3.new(0, -120, 0), groundParams)
		if hit then
			local fall = RainLook.falling(rain, Perf.tierName(), DayGrade.wind(workspace:GetAttribute("Weather"), game:GetService("Lighting").ClockTime))
			splashPart.CFrame = CFrame.new(hit.Position + Vector3.new(0, 0.1, 0))
			splash.Rate = fall.SplashRate
			splash.Enabled = fall.SplashRate > 0
			return
		end
	end
	splash.Enabled = false
end

---------------------------------------------------------------------
-- Personas mojadas
---------------------------------------------------------------------

type Dressed = { Color: Color3, Written: Color3?, Reflectance: number?, WrittenReflectance: number? }
type Person = {
	Model: Model,
	Head: BasePart,
	Wet: number,
	Parts: { [BasePart]: Dressed },
	Tints: { [Instance]: Dressed }, -- ropa clásica (Shirt/Pants: Color3) y accesorios (SpecialMesh: VertexColor)
	Level: number,
	Drips: ParticleEmitter?,
}
local people: { [Model]: Person } = {}

local function drips(head: BasePart): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = "Goteo"
	e.Texture = SMOKE
	e.Color = ColorSequence.new(rgb(190, 210, 235))
	e.LightEmission = 0.15
	e.Transparency = NumberSequence.new(0.3)
	e.Size = NumberSequence.new(0.08)
	e.Squash = NumberSequence.new(1.5) -- (gota alargada hacia abajo: con VelocityParallel, positivo)
	e.Orientation = Enum.ParticleOrientation.VelocityParallel
	e.Lifetime = NumberRange.new(0.5, 0.8)
	e.Speed = NumberRange.new(0, 1)
	e.Acceleration = Vector3.new(0, -30, 0)
	e.EmissionDirection = Enum.NormalId.Bottom
	e.SpreadAngle = Vector2.new(60, 60)
	e.Rate = 0
	e.Parent = head
	return e
end

-- Mojado: ropa, pelo y piel más oscuros y con un brillo de agua (Wetness.look). La ropa clásica
-- (Shirt/Pants) no se tiñe con el color de la pieza: se oscurece su Color3; los accesorios de malla,
-- su VertexColor. Si otro sistema cambia algo, ese es su color de verdad.
local function dressWet(person: Person, level: number)
	local darken, shine = Wetness.look(level)
	for part, info in person.Parts do
		if not part.Parent then
			person.Parts[part] = nil
			continue
		end
		if info.Written and part.Color ~= info.Written then
			info.Color = part.Color
		end
		if info.WrittenReflectance and math.abs(part.Reflectance - info.WrittenReflectance) > 0.001 then
			info.Reflectance = part.Reflectance
		end
		part.Color = info.Color:Lerp(BLACK, darken)
		info.Written = part.Color
		local base = info.Reflectance or 0
		part.Reflectance = if level > 0 then math.max(base, shine) else base
		info.WrittenReflectance = part.Reflectance
	end
	for item, info in person.Tints do
		if not item.Parent then
			person.Tints[item] = nil
			continue
		end
		local ok = pcall(function()
			if item:IsA("Clothing") then
				if info.Written and item.Color3 ~= info.Written then
					info.Color = item.Color3
				end
				item.Color3 = info.Color:Lerp(BLACK, darken)
				info.Written = item.Color3
			elseif item:IsA("SpecialMesh") then
				local current = Color3.new(item.VertexColor.X, item.VertexColor.Y, item.VertexColor.Z)
				if info.Written and current ~= info.Written then
					info.Color = current
				end
				local c = info.Color:Lerp(BLACK, darken)
				item.VertexColor = Vector3.new(c.R, c.G, c.B)
				local v = item.VertexColor -- (lo que queda guardado, con su redondeo)
				info.Written = Color3.new(v.X, v.Y, v.Z)
			end
		end)
		if not ok then
			person.Tints[item] = nil
		end
	end
end

local function trackPerson(model: Model): Person?
	local head = model:FindFirstChild("Head") :: BasePart?
	if not head or not model:FindFirstChildOfClass("Humanoid") then
		return nil
	end
	local person: Person = { Model = model, Head = head, Wet = 0, Parts = {}, Tints = {}, Level = 0, Drips = nil }
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 0.9 and not d.Name:match("^WorkProp_") and d.Material ~= Enum.Material.Glass and d.Material ~= Enum.Material.Neon then
			person.Parts[d] = { Color = d.Color, Written = nil, Reflectance = d.Reflectance }
		elseif d:IsA("Shirt") or d:IsA("Pants") then
			person.Tints[d] = { Color = (d :: any).Color3, Written = nil }
		elseif d:IsA("SpecialMesh") and d.Parent and d.Parent.Name == "Handle" then
			local v = d.VertexColor
			person.Tints[d] = { Color = Color3.new(v.X, v.Y, v.Z), Written = nil }
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
		-- (el rayo sale por encima del sombrero o el pelo: antes, a 1 stud, el gorro de un personaje
		-- contaba como tejado y no se mojaba nunca)
		local sheltered = not exposed(p.Head.Position + Vector3.new(0, 3.5, 0), ignore)
		p.Wet = Wetness.person(p.Wet, rain, sheltered, dt)
		local level = Wetness.level(p.Wet)
		if level ~= p.Level then
			p.Level = level
			dressWet(p, level)
		end
		local dripRate = Wetness.drips(p.Wet)
		if dripRate > 0 then
			if not p.Drips then
				p.Drips = drips(p.Head)
			end
			(p.Drips :: ParticleEmitter).Rate = dripRate
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

function WetWorld.init()
	folder = Instance.new("Folder")
	folder.Name = "WetWorld"
	folder.Parent = workspace.CurrentCamera -- solo para este jugador
	buildPuddles()

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
				-- (la misma regla que la lluvia que cae: bajo un saliente mirando a la calle se ve salpicar)
				local indoor = Shelter.camera().Enclosed
				puddlesTick(wet, rain, indoor)
				peopleTick(dt, rain)
				sprayTick(wet)
			end)
			if not ok then
				warn("[WetWorld] " .. tostring(err))
			end
		end
	end)
end

return WetWorld
