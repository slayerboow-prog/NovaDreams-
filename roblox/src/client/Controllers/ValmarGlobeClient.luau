-- ValmarGlobeClient (cliente): pinta Valmar como un planeta pequeño y redondo al subir al espacio
-- (shared/Cosmos/ValmarGlobe: las cuentas; petición del dueño en v121). SOLO se ve: no choca, no se
-- toca, no echa sombra; el mundo donde se anda sigue plano y la ciudad no se mueve.
--
--   * Esfera de mar (con la textura «valmar_planeta» —el mapa de verdad— si está subida), la isla en
--     polígonos encima si no hay textura (costa, barrios con su color y carreteras), nubes que giran
--     despacio (textura de nubes si la hay), el aire azul del borde (ForceField: brillo de borde) y las
--     luces de las ciudades en el lado de noche (el sol es el de Roblox: el de la hora del juego).
--   * Aparece y se va con la altura (ValmarGlobe.blend): transparencia de todas las piezas a la vez,
--     solo cuando cambia; arriba del todo, entero. Controllers/SpaceClient apaga a la vez la isla plana.
--   * Cada jugador el suyo (va dentro de la cámara).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cosmos = ReplicatedStorage.Shared.Cosmos
local Layers = require(Cosmos.Layers)
local ValmarGlobe = require(Cosmos.ValmarGlobe)
local EspacioLook = require(Cosmos.EspacioLook)
local EspacioTextureIds = require(Cosmos.EspacioTextureIds)
local CityPlan = require(ReplicatedStorage.Shared.CityPlan)

local ValmarGlobeClient = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB

ValmarGlobeClient.Every = 0.1
ValmarGlobeClient.CloudSpin = 0.35 -- grados por segundo

type Item = { Part: BasePart, Base: number }
local model: Model? = nil
local items: { Item } = {}
local clouds: BasePart? = nil
local lights: { { Part: BasePart, Pos: Vector3 } } = {}
local shownBlend = -1
local textured = false

local function ids(): { [string]: string }
	local ok, map = pcall(function()
		return require(ReplicatedStorage.Shared.Images).map(EspacioTextureIds)
	end)
	return if ok and type(map) == "table" then map else EspacioTextureIds
end

local function part(name: string, parent: Instance, base: number?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	table.insert(items, { Part = p, Base = base or 0 })
	return p
end

local function ball(name: string, radius: number, color: Color3, parent: Instance, base: number?, texture: string?): Part
	local p = part(name, parent, base)
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.one * 2048
	p.Color = color
	p.CFrame = CFrame.new(ValmarGlobe.Center) * CFrame.Angles(0, math.rad(ValmarGlobe.TexYaw), 0)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.one * (radius * 2 / 2048) * (if ValmarGlobe.TexMirror then Vector3.new(-1, 1, 1) else Vector3.one)
	if texture then
		mesh.TextureId = texture
	end
	mesh.Parent = p
	return p
end

-- Un triángulo (dos cuñas) entre tres puntos 3D cualesquiera
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
	for _, info in { { (a + b) / 2, right, math.abs(ab:Dot(back)), back }, { (a + c) / 2, -right, math.abs(ac:Dot(back)), -back } } do
		local w = Instance.new("WedgePart")
		w.Name = "Tierra"
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
		table.insert(items, { Part = w, Base = 0 })
	end
end

-- ¿Dentro de un polígono (x, z)?
local function inPoly(x: number, z: number, poly: { { number } }): boolean
	local inside = false
	local j = #poly
	for i = 1, #poly do
		local xi, zi, xj, zj = poly[i][1], poly[i][2], poly[j][1], poly[j][2]
		if (zi > z) ~= (zj > z) and x < (xj - xi) * (z - zi) / (zj - zi) + xi then
			inside = not inside
		end
		j = i
	end
	return inside
end

-- El color de la tierra en (x, z): el del barrio (ciudad gris en el centro, verde en las afueras)
ValmarGlobeClient.LandColors = {
	Centro = rgb(132, 134, 140),
	Sur = rgb(138, 128, 112),
	Este = rgb(150, 146, 120),
	Norte = rgb(92, 128, 78),
	Oeste = rgb(76, 122, 66),
	Universitario = rgb(98, 136, 92),
}
function ValmarGlobeClient.landColor(x: number, z: number, edge: boolean): Color3
	if edge then
		return rgb(206, 192, 146) -- (la playa)
	end
	for _, d in CityPlan.Districts do
		if inPoly(x, z, d.Poly) then
			return ValmarGlobeClient.LandColors[d.Id] or rgb(84, 126, 72)
		end
	end
	return rgb(84, 126, 72)
end

local function buildLand(parent: Instance)
	local coast = CityPlan.Coast
	local lift = ValmarGlobe.LandLift
	local rings = 3
	local function at(px: number, pz: number): Vector3
		return ValmarGlobe.toSphere(px, pz, lift)
	end
	for i = 1, #coast do
		local p, q = coast[i], coast[(i % #coast) + 1]
		for k = 0, rings - 1 do
			local t0, t1 = k / rings, (k + 1) / rings
			local a0x, a0z, b0x, b0z = p[1] * t0, p[2] * t0, q[1] * t0, q[2] * t0
			local a1x, a1z, b1x, b1z = p[1] * t1, p[2] * t1, q[1] * t1, q[2] * t1
			local edge = k == rings - 1
			local cx, cz = (a0x + a1x + b1x) / 3, (a0z + a1z + b1z) / 3
			local color = ValmarGlobeClient.landColor(cx, cz, false)
			if k == 0 then
				triangle(parent, at(0, 0), at(a1x, a1z), at(b1x, b1z), color)
			else
				triangle(parent, at(a0x, a0z), at(a1x, a1z), at(b1x, b1z), color)
				triangle(parent, at(a0x, a0z), at(b1x, b1z), at(b0x, b0z), if edge then ValmarGlobeClient.landColor(cx, cz, false) else color)
			end
		end
		-- (la franja de playa)
		local s0x, s0z, s1x, s1z = p[1] * 0.97, p[2] * 0.97, q[1] * 0.97, q[2] * 0.97
		triangle(parent, at(s0x, s0z), at(p[1], p[2]), at(q[1], q[2]), ValmarGlobeClient.landColor(0, 0, true))
		triangle(parent, at(s0x, s0z), at(q[1], q[2]), at(s1x, s1z), ValmarGlobeClient.landColor(0, 0, true))
	end
	-- Carreteras: tramos finos sobre la esfera (las autovías más anchas)
	for _, road in CityPlan.Roads do
		local width = if road.Kind == "Autovia" then 46 elseif road.Kind == "Avenida" then 32 else 22
		local pts = road.Points
		for i = 1, #pts - 1 do
			local a, b = pts[i], pts[i + 1]
			local steps = math.max(1, math.ceil(math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2) / 500))
			for s = 0, steps - 1 do
				local u0, u1 = s / steps, (s + 1) / steps
				local A = ValmarGlobe.toSphere(a[1] + (b[1] - a[1]) * u0, a[2] + (b[2] - a[2]) * u0, lift + 3)
				local B = ValmarGlobe.toSphere(a[1] + (b[1] - a[1]) * u1, a[2] + (b[2] - a[2]) * u1, lift + 3)
				local mid = (A + B) / 2
				local len = (B - A).Magnitude
				if len > 1 then
					local r = part("Carretera", parent)
					r.Color = rgb(70, 72, 78)
					r.Size = Vector3.new(width, 2, len + width * 0.5)
					local up = ValmarGlobe.normal(mid)
					r.CFrame = CFrame.lookAt(mid, B, up)
				end
			end
		end
	end
end

function ValmarGlobeClient.build(): Model
	local m = Instance.new("Model")
	m.Name = "ValmarPlaneta"
	table.clear(items)
	table.clear(lights)
	local map = ids()
	local tex = EspacioLook.id(map, "valmar_planeta")
	textured = tex ~= nil
	local R = ValmarGlobe.Radius
	ball("Mar", R, rgb(16, 58, 108), m, 0, tex)
	if not textured then
		buildLand(m)
	end
	-- Nubes (si hay textura de nubes: las de Tálasa sirven, son blancas sobre transparente)
	local cloudTex = EspacioLook.id(map, "nubes_valmar") or EspacioLook.id(map, "nubes_talasa")
	if cloudTex then
		clouds = ball("Nubes", R + ValmarGlobe.CloudLift, rgb(255, 255, 255), m, 0.25, cloudTex)
	end
	-- El aire: brillo azul en el borde (ForceField se ve más en el borde que en el centro)
	local air = ball("Aire", R + ValmarGlobe.AirLift, rgb(110, 180, 255), m, 0.55)
	air.Material = Enum.Material.ForceField
	-- Luces de las ciudades (solo de noche)
	for _, spot in ValmarGlobe.lightSpots() do
		local pos = ValmarGlobe.toSphere(spot[1], spot[2], ValmarGlobe.LandLift + 6)
		local l = part("Luz", m, 0)
		l.Shape = Enum.PartType.Ball
		l.Material = Enum.Material.Neon
		l.Color = rgb(255, 196, 120)
		local size = 40 + 50 * (spot[3] or 1)
		l.Size = Vector3.one * size
		l.CFrame = CFrame.new(pos)
		table.insert(lights, { Part = l, Pos = pos })
	end
	return m
end

-- La transparencia de todo con el blend de ahora
local function applyBlend(g: number)
	for _, it in items do
		it.Part.Transparency = 1 - g * (1 - it.Base)
	end
end

local since = 0
function ValmarGlobeClient.update(dt: number, camPos: Vector3, sunDir: Vector3?)
	local arena = player and player:GetAttribute("AirCombatWorld") == "Arena"
	local g = if Layers.inColumn(camPos, 2000) and not arena then ValmarGlobe.blend(camPos.Y) else 0
	if g <= 0.005 then
		if model and model.Parent then
			model.Parent = nil
		end
		shownBlend = -1
		return g
	end
	if not model then
		model = ValmarGlobeClient.build()
	end
	local m = model :: Model
	if m.Parent ~= workspace.CurrentCamera then
		m.Parent = workspace.CurrentCamera
	end
	if math.abs(g - shownBlend) > 0.03 or (g >= 1 and shownBlend < 1) then
		shownBlend = g
		applyBlend(g)
	end
	local c = clouds
	if c then
		c.CFrame = CFrame.new(ValmarGlobe.Center) * CFrame.Angles(0, math.rad(os.clock() * ValmarGlobeClient.CloudSpin), 0)
	end
	-- Luces: solo en el lado de noche
	if sunDir then
		for _, l in lights do
			local on = ValmarGlobe.night(l.Pos, sunDir)
			local want = if on then 1 - g else 1
			if math.abs(l.Part.Transparency - want) > 0.05 then
				l.Part.Transparency = want
			end
		end
	end
	return g
end

-- Cuánto planeta se ve ahora (para SpaceClient: la isla plana se va a la vez)
function ValmarGlobeClient.blendNow(): number
	return math.max(shownBlend, 0)
end

function ValmarGlobeClient.isTextured(): boolean
	return textured
end

function ValmarGlobeClient.model(): Model?
	return model
end

function ValmarGlobeClient.init()
	local Lighting = game:GetService("Lighting")
	RunService.RenderStepped:Connect(function(dt)
		since += dt
		if since < ValmarGlobeClient.Every then
			return
		end
		local step = since
		since = 0
		local ok, err = pcall(function()
			local camera = workspace.CurrentCamera
			if camera then
				ValmarGlobeClient.update(step, camera.CFrame.Position, Lighting:GetSunDirection())
			end
		end)
		if not ok then
			warn("[ValmarGlobe] " .. tostring(err))
		end
	end)
end

return ValmarGlobeClient
