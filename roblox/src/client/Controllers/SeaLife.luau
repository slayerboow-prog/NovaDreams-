-- SeaLife (cliente): la vida del mar hondo, solo en tu pantalla y solo cerca de ti (docs/mar/diseno.md).
--
--   * Según la zona (shared/Sea/OceanBiomes.Zones[z].Fauna): bancos de peces que se mueven con «boids»
--     (se juntan, van en la misma dirección, no se chocan y se apartan de ti), rayas que planean,
--     tortugas, medusas que brillan, delfines junto a la superficie en mar abierto y criaturas del
--     abismo con luz propia (peces linterna, rapes con su señuelo).
--   * Las criaturas grandes las mueve el servidor (Services/SeaBeastService, workspace.SeaBeasts): aquí
--     se dibujan el megalodón (suavizado entre lo que dice el servidor) y el kraken (su cuerpo en la boca
--     de la guarida y el tentáculo que se levanta al avisar y golpea).
--   * Golpes: el servidor manda el empujón (remote «Sea» «Knock») y aquí se aplica al personaje (es tuyo).
--   * Barato para el móvil: radio de 140 studs, todo sin choques ni consultas, boids a 30 veces por
--     segundo (y menos con lo lejano), pocas luces. Presupuesto: ≤ 160 piezas en el móvil, ≤ 260 en el
--     ordenador (SeaLife.Budget; lo prueba scripts/test-mar.luau leyendo esta tabla).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Ocean = require(ReplicatedStorage.Shared.Sea.Ocean)
local OceanBiomes = require(ReplicatedStorage.Shared.Sea.OceanBiomes)
local SeaBeasts = require(ReplicatedStorage.Shared.Sea.SeaBeasts)
local Perf = require(script.Parent.Parent.UI.Perf)

local SeaLife = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local sin, cos, random = math.sin, math.cos, math.random
local SURFACE = Ocean.Surface

SeaLife.Budget = { Mobile = 160, Desktop = 260 }
SeaLife.Radius = 140
-- Cuántos de cada uno (por cada punto de peso de la zona) y piezas que gasta cada uno
SeaLife.Per = {
	Schools = { Count = 1, Parts = if Perf.mobile then 10 else 16 },
	Rays = { Count = 1, Parts = 3 },
	Turtles = { Count = 1, Parts = 6 },
	Jellies = { Count = 1, Parts = 5 },
	Dolphins = { Count = 1, Parts = 12 },
	Abyssal = { Count = 1, Parts = 4 },
}

local folder: Folder? = nil
local function getFolder(): Folder
	if not folder or not folder.Parent then
		local f = Instance.new("Folder")
		f.Name = "SeaLife"
		f.Parent = workspace
		folder = f
	end
	return folder :: Folder
end

local partCount = 0
local lights = 0
local MAX_LIGHTS = if Perf.mobile then 2 else 6

local function part(size: Vector3, color: Color3, material: Enum.Material?, mesh: string?, transparency: number?): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	if mesh == "Sphere" then
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Sphere
		m.Parent = p
	elseif mesh == "Wedge" then
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Wedge
		m.Parent = p
	end
	p.Parent = getFolder()
	partCount += 1
	return p
end

local function light(p: BasePart, color: Color3, range: number)
	if lights >= MAX_LIGHTS then
		return
	end
	lights += 1
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = 1.4
	l.Parent = p
	p:SetAttribute("Light", true)
end

local function destroyParts(list: { BasePart })
	for _, p in list do
		if p:GetAttribute("Light") then
			lights = math.max(0, lights - 1)
		end
		partCount -= 1
		p:Destroy()
	end
end

local floorParams = RaycastParams.new()
floorParams.FilterType = Enum.RaycastFilterType.Include
floorParams.IgnoreWater = true
local function floorAt(x: number, z: number): number
	floorParams.FilterDescendantsInstances = { workspace.Terrain }
	local hit = workspace:Raycast(V(x, SURFACE - 0.5, z), V(0, -640, 0), floorParams)
	return if hit then hit.Position.Y else (Ocean.floorY(x, z) or SURFACE - 12)
end

---------------------------------------------------------------------
-- Criaturas pequeñas
---------------------------------------------------------------------
type Creature = { Kind: string, Parts: { BasePart }, Pos: Vector3, Vel: Vector3, Anchor: Vector3, Floor: number, Phase: number, Data: { [string]: any } }
local creatures: { Creature } = {}

-- Boids: un banco de peces
local FISH_COLORS = { rgb(200, 215, 230), rgb(250, 205, 70), rgb(80, 160, 235), rgb(245, 130, 60), rgb(120, 230, 210) }
local function makeSchool(at: Vector3, floorY: number, glowing: boolean): Creature
	local n = SeaLife.Per.Schools.Parts
	local color = FISH_COLORS[random(1, #FISH_COLORS)]
	local parts, data = {}, { Fish = {} }
	for i = 1, n do
		local p = part(V(0.32, 0.55, 1.1), if glowing then rgb(90, 240, 255) else color, if glowing then Enum.Material.Neon else Enum.Material.SmoothPlastic)
		table.insert(parts, p)
		local pos = at + V(random() * 6 - 3, random() * 3 - 1.5, random() * 6 - 3)
		table.insert(data.Fish, { Pos = pos, Vel = V(random() - 0.5, 0, random() - 0.5).Unit * 4 })
	end
	return { Kind = "School", Parts = parts, Pos = at, Vel = V(random() - 0.5, 0, random() - 0.5).Unit * 2, Anchor = at, Floor = floorY, Phase = random() * 10, Data = data }
end

local function stepSchool(c: Creature, dt: number, me: Vector3?)
	local fish = c.Data.Fish
	-- El banco entero pasea despacio (y gira al acercarse al fondo, a la superficie o lejos de su sitio)
	c.Phase += dt
	local wander = V(sin(c.Phase * 0.21), 0, cos(c.Phase * 0.17))
	c.Pos += wander * dt * 2.2
	local low, high = c.Floor + 2.5, SURFACE - 2
	c.Pos = V(c.Pos.X, math.clamp(c.Pos.Y, math.min(low, high), high), c.Pos.Z)
	local center, heading = Vector3.zero, Vector3.zero
	for _, f in fish do
		center += f.Pos
		heading += f.Vel
	end
	center /= #fish
	heading /= #fish
	for i, f in fish do
		local sep = Vector3.zero
		for j, o in fish do
			if i ~= j then
				local d = f.Pos - o.Pos
				local m = d.Magnitude
				if m < 1.6 and m > 1e-3 then
					sep += d.Unit * (1.6 - m)
				end
			end
		end
		local acc = (center - f.Pos) * 0.6 + (heading - f.Vel) * 0.8 + sep * 6 + (c.Pos - f.Pos) * 0.5
		if me then
			local away = f.Pos - me
			if away.Magnitude < 9 then
				acc += away.Unit * (9 - away.Magnitude) * 4 -- se apartan de ti
			end
		end
		if f.Pos.Y < low then
			acc += V(0, (low - f.Pos.Y) * 3, 0)
		elseif f.Pos.Y > high then
			acc -= V(0, (f.Pos.Y - high) * 3, 0)
		end
		local vel = f.Vel + acc * dt
		local speed = vel.Magnitude
		if speed > 7 then
			vel = vel.Unit * 7
		elseif speed < 2.5 and speed > 1e-3 then
			vel = vel.Unit * 2.5
		end
		f.Vel = vel
		f.Pos += vel * dt
		local p = c.Parts[i]
		if vel.Magnitude > 0.1 then
			p.CFrame = CFrame.lookAt(f.Pos, f.Pos + vel) * ANG(0, sin(c.Phase * 14 + i) * 0.25, 0)
		end
	end
end

-- Raya: cuerpo plano y dos alas que baten despacio
local function makeRay(at: Vector3, floorY: number): Creature
	local body = part(V(3, 0.5, 4), rgb(60, 70, 80), Enum.Material.SmoothPlastic, "Sphere")
	local left = part(V(5, 0.25, 3), rgb(60, 70, 80), Enum.Material.SmoothPlastic, "Wedge")
	local right = part(V(5, 0.25, 3), rgb(60, 70, 80), Enum.Material.SmoothPlastic, "Wedge")
	return { Kind = "Ray", Parts = { body, left, right }, Pos = at, Vel = Vector3.zero, Anchor = at, Floor = floorY, Phase = random() * 10, Data = { R = 18 + random() * 14 } }
end

local function stepRay(c: Creature, dt: number)
	c.Phase += dt
	local a = c.Phase * 0.18
	local r = c.Data.R
	local y = math.min(c.Floor + 6 + sin(c.Phase * 0.4) * 2, SURFACE - 3)
	local pos = c.Anchor + V(cos(a) * r, 0, sin(a) * r)
	pos = V(pos.X, y, pos.Z)
	local ahead = c.Anchor + V(cos(a + 0.05) * r, 0, sin(a + 0.05) * r)
	local cf = CFrame.lookAt(pos, V(ahead.X, y, ahead.Z)) * ANG(0, 0, 0.15)
	c.Pos = pos
	local flap = sin(c.Phase * 2.2) * 0.35
	c.Parts[1].CFrame = cf
	c.Parts[2].CFrame = cf * CF(-2.6, 0, 0.3) * ANG(0, 0, flap) * CF(-1.2, 0, 0) * ANG(0, math.rad(-90), 0)
	c.Parts[3].CFrame = cf * CF(2.6, 0, 0.3) * ANG(0, 0, -flap) * CF(1.2, 0, 0) * ANG(0, math.rad(90), 0)
end

-- Tortuga: caparazón, cabeza y cuatro aletas
local function makeTurtle(at: Vector3, floorY: number): Creature
	local shell = part(V(3, 1.3, 3.6), rgb(96, 110, 60), Enum.Material.SmoothPlastic, "Sphere")
	local head = part(V(0.8, 0.7, 1), rgb(140, 150, 110), Enum.Material.SmoothPlastic, "Sphere")
	local fins = {}
	for _ = 1, 4 do
		table.insert(fins, part(V(1.8, 0.2, 0.8), rgb(130, 140, 100), Enum.Material.SmoothPlastic, "Sphere"))
	end
	return { Kind = "Turtle", Parts = { shell, head, fins[1], fins[2], fins[3], fins[4] }, Pos = at, Vel = Vector3.zero, Anchor = at, Floor = floorY, Phase = random() * 10, Data = { R = 22 + random() * 10 } }
end

local function stepTurtle(c: Creature, dt: number)
	c.Phase += dt
	local a = c.Phase * 0.12
	local r = c.Data.R
	local y = math.min(c.Floor + 5 + sin(c.Phase * 0.3) * 3, SURFACE - 2.5)
	local pos = V(c.Anchor.X + cos(a) * r, y, c.Anchor.Z + sin(a) * r)
	local ahead = V(c.Anchor.X + cos(a + 0.05) * r, y, c.Anchor.Z + sin(a + 0.05) * r)
	local cf = CFrame.lookAt(pos, ahead)
	c.Pos = pos
	local flap = sin(c.Phase * 2.4) * 0.5
	c.Parts[1].CFrame = cf
	c.Parts[2].CFrame = cf * CF(0, 0.1, -2.1)
	c.Parts[3].CFrame = cf * CF(-1.7, -0.1, -0.9) * ANG(0, 0.4, flap)
	c.Parts[4].CFrame = cf * CF(1.7, -0.1, -0.9) * ANG(0, -0.4, -flap)
	c.Parts[5].CFrame = cf * CF(-1.2, -0.1, 1.3) * ANG(0, -0.3, -flap * 0.5)
	c.Parts[6].CFrame = cf * CF(1.2, -0.1, 1.3) * ANG(0, 0.3, flap * 0.5)
end

-- Medusa que brilla (más en lo hondo y de noche)
local function makeJelly(at: Vector3, floorY: number, deep: boolean): Creature
	local color = if deep then rgb(120, 200, 255):Lerp(rgb(220, 120, 255), random()) else rgb(240, 170, 220):Lerp(rgb(170, 210, 255), random())
	local bell = part(V(1.8, 1.3, 1.8), color, if deep then Enum.Material.Neon else Enum.Material.Glass, "Sphere", if deep then 0.35 else 0.45)
	local parts = { bell }
	for _ = 1, 4 do
		table.insert(parts, part(V(0.07, 2.2, 0.07), color, Enum.Material.Neon, nil, 0.45))
	end
	if deep then
		light(bell, color, 10)
	end
	return { Kind = "Jelly", Parts = parts, Pos = at, Vel = Vector3.zero, Anchor = at, Floor = floorY, Phase = random() * 10, Data = {} }
end

local function stepJelly(c: Creature, dt: number)
	c.Phase += dt
	local pulse = 1 + sin(c.Phase * 2.2) * 0.1
	local at = c.Anchor + V(sin(c.Phase * 0.2) * 1.2, sin(c.Phase * 0.5) * 1.6, cos(c.Phase * 0.17) * 1.2)
	c.Pos = at
	local mesh = c.Parts[1]:FindFirstChildOfClass("SpecialMesh")
	if mesh then
		mesh.Scale = V(pulse, 1 / pulse, pulse)
	end
	c.Parts[1].CFrame = CF(at)
	for i = 2, #c.Parts do
		local a = (i - 2) * math.pi / 2
		c.Parts[i].CFrame = CF(at + V(cos(a) * 0.45, -1.4, sin(a) * 0.45)) * ANG(sin(c.Phase * 1.5 + i) * 0.25, 0, cos(c.Phase * 1.3 + i) * 0.25)
	end
end

-- Delfines: grupo de 3 que nada junto a la superficie y salta
local function makeDolphins(at: Vector3, floorY: number): Creature
	local parts = {}
	for _ = 1, 3 do
		table.insert(parts, part(V(1.4, 1.5, 5.5), rgb(120, 135, 150), Enum.Material.SmoothPlastic, "Sphere"))
		table.insert(parts, part(V(0.2, 1.2, 1), rgb(110, 125, 140), Enum.Material.SmoothPlastic, "Wedge"))
		table.insert(parts, part(V(2.2, 0.2, 0.8), rgb(110, 125, 140), Enum.Material.SmoothPlastic, "Sphere"))
		table.insert(parts, part(V(0.6, 0.5, 1.4), rgb(110, 125, 140), Enum.Material.SmoothPlastic, "Sphere"))
	end
	return { Kind = "Dolphins", Parts = parts, Pos = at, Vel = Vector3.zero, Anchor = V(at.X, SURFACE, at.Z), Floor = floorY, Phase = random() * 10, Data = { R = 45 + random() * 20 } }
end

local function stepDolphins(c: Creature, dt: number)
	c.Phase += dt
	for k = 0, 2 do
		local a = c.Phase * 0.22 + k * 0.12
		local r = c.Data.R + k * 4
		local hop = math.max(0, sin(c.Phase * 0.9 + k)) -- saltos
		local y = SURFACE - 3 + hop * 5.5
		local pos = V(c.Anchor.X + cos(a) * r, y, c.Anchor.Z + sin(a) * r)
		local ahead = V(c.Anchor.X + cos(a + 0.05) * r, y + cos(c.Phase * 0.9 + k) * 0.5, c.Anchor.Z + sin(a + 0.05) * r)
		local cf = CFrame.lookAt(pos, ahead)
		c.Parts[k * 4 + 1].CFrame = cf
		c.Parts[k * 4 + 2].CFrame = cf * CF(0, 1.1, 0.2)
		c.Parts[k * 4 + 3].CFrame = cf * CF(0, 0, 2.9) * ANG(sin(c.Phase * 6 + k) * 0.3, 0, 0)
		c.Parts[k * 4 + 4].CFrame = cf * CF(0, -0.2, -3)
		if k == 0 then
			c.Pos = pos
		end
	end
end

-- Abisal: rape con su señuelo de luz, o pez linterna con puntos que brillan
local function makeAbyssal(at: Vector3, floorY: number): Creature
	local body = part(V(1.8, 1.6, 2.6), rgb(30, 26, 34), Enum.Material.SmoothPlastic, "Sphere")
	local jaw = part(V(1.6, 0.4, 1), rgb(40, 30, 40), Enum.Material.SmoothPlastic)
	local stalk = part(V(0.1, 1.2, 0.1), rgb(40, 30, 40))
	local lure = part(V(0.45, 0.45, 0.45), rgb(120, 255, 230), Enum.Material.Neon, "Sphere")
	light(lure, rgb(120, 255, 230), 9)
	return { Kind = "Abyssal", Parts = { body, jaw, stalk, lure }, Pos = at, Vel = Vector3.zero, Anchor = at, Floor = floorY, Phase = random() * 10, Data = { R = 8 + random() * 6 } }
end

local function stepAbyssal(c: Creature, dt: number)
	c.Phase += dt
	local a = c.Phase * 0.15
	local r = c.Data.R
	local y = c.Floor + 4 + sin(c.Phase * 0.3) * 1.5
	local pos = V(c.Anchor.X + cos(a) * r, y, c.Anchor.Z + sin(a) * r)
	local ahead = V(c.Anchor.X + cos(a + 0.05) * r, y, c.Anchor.Z + sin(a + 0.05) * r)
	local cf = CFrame.lookAt(pos, ahead)
	c.Pos = pos
	c.Parts[1].CFrame = cf
	c.Parts[2].CFrame = cf * CF(0, -0.5, -1.2) * ANG(sin(c.Phase * 1.3) * 0.2 - 0.2, 0, 0)
	c.Parts[3].CFrame = cf * CF(0, 1.2, -1) * ANG(-0.6, 0, 0)
	c.Parts[4].CFrame = cf * CF(0, 1.6, -1.8 + sin(c.Phase * 2) * 0.1)
end

local STEP = { School = stepSchool, Ray = stepRay, Turtle = stepTurtle, Jelly = stepJelly, Dolphins = stepDolphins, Abyssal = stepAbyssal }

local function budget(): number
	return if Perf.mobile then SeaLife.Budget.Mobile else SeaLife.Budget.Desktop
end

-- Lo que debería haber cerca según la zona (y la hora: más medusas de noche)
local function spawnAround(center: Vector3, zone: string)
	local z = OceanBiomes.zone(zone)
	if not z then
		return
	end
	local scale = if Perf.mobile then 0.6 else 1
	local counts = { School = 0, Ray = 0, Turtle = 0, Jelly = 0, Dolphins = 0, Abyssal = 0 }
	for _, c in creatures do
		counts[c.Kind] += 1
	end
	local want = {
		School = math.ceil(z.Fauna.Schools * scale),
		Ray = math.floor(z.Fauna.Rays * scale + 0.4),
		Turtle = math.floor(z.Fauna.Turtles * scale + 0.4),
		Jelly = math.ceil(z.Fauna.Jellies * scale),
		Dolphins = math.min(1, z.Fauna.Dolphins),
		Abyssal = math.ceil(z.Fauna.Abyssal * scale),
	}
	for kind, n in want do
		if counts[kind] < n and partCount < budget() - 20 then
			local a = random() * math.pi * 2
			local d = 25 + random() * 60
			local x, zz = center.X + cos(a) * d, center.Z + sin(a) * d
			local s = Ocean.sample(x, zz)
			if s.Floor then
				local floorY = floorAt(x, zz)
				local deep = Ocean.meters(floorY) > 30
				local y = math.clamp(center.Y + random() * 10 - 5, floorY + 3, SURFACE - 3)
				local at = V(x, y, zz)
				local c: Creature
				if kind == "School" then
					c = makeSchool(at, floorY, deep and zone ~= "Talud")
				elseif kind == "Ray" then
					c = makeRay(at, floorY)
				elseif kind == "Turtle" then
					c = makeTurtle(at, floorY)
				elseif kind == "Jelly" then
					c = makeJelly(at, floorY, deep)
				elseif kind == "Dolphins" then
					if s.D < 250 then
						continue
					end
					c = makeDolphins(at, floorY)
				else
					c = makeAbyssal(V(x, floorY + 4, zz), floorY)
				end
				table.insert(creatures, c)
				return -- uno cada vez (no se nota el tirón)
			end
		end
	end
end

local function cullFar(center: Vector3, all: boolean?)
	for i = #creatures, 1, -1 do
		local c = creatures[i]
		if all or (c.Pos - center).Magnitude > SeaLife.Radius + 20 then
			destroyParts(c.Parts)
			table.remove(creatures, i)
		end
	end
end

---------------------------------------------------------------------
-- Megalodón y kraken (los mueve el servidor)
---------------------------------------------------------------------
type Beast = { Parts: { [string]: BasePart }, Pos: Vector3, Look: Vector3, Phase: number }
local mega: Beast? = nil
local krakenView: { Body: BasePart?, Eyes: { BasePart }, Tentacle: { BasePart }, Reach: number, Ink: ParticleEmitter? }? = nil

local function makeMega(): Beast
	local grey, belly = rgb(78, 92, 104), rgb(200, 205, 210)
	local L = SeaBeasts.Megalodon.Length
	local p = {
		Body = part(V(13, 14, L * 0.62), grey, Enum.Material.SmoothPlastic, "Sphere"),
		Belly = part(V(11, 7, L * 0.5), belly, Enum.Material.SmoothPlastic, "Sphere"),
		Head = part(V(11, 10, 16), grey, Enum.Material.SmoothPlastic, "Sphere"),
		Jaw = part(V(9, 2.5, 10), rgb(60, 66, 74), Enum.Material.SmoothPlastic),
		Teeth = part(V(8.5, 0.6, 0.6), rgb(240, 240, 230), Enum.Material.SmoothPlastic),
		Dorsal = part(V(1.2, 10, 9), grey, Enum.Material.SmoothPlastic, "Wedge"),
		Tail = part(V(1.2, 10, 8), grey, Enum.Material.SmoothPlastic, "Wedge"),
		TailLow = part(V(1.2, 7, 6), grey, Enum.Material.SmoothPlastic, "Wedge"),
		TailBase = part(V(6, 6, 16), grey, Enum.Material.SmoothPlastic, "Sphere"),
		FinL = part(V(10, 0.8, 5), grey, Enum.Material.SmoothPlastic, "Sphere"),
		FinR = part(V(10, 0.8, 5), grey, Enum.Material.SmoothPlastic, "Sphere"),
		EyeL = part(V(0.9, 0.9, 0.9), rgb(10, 10, 10), Enum.Material.Glass, "Sphere"),
		EyeR = part(V(0.9, 0.9, 0.9), rgb(10, 10, 10), Enum.Material.Glass, "Sphere"),
	}
	for _, x in p do
		x.Name = "Megalodon"
	end
	return { Parts = p, Pos = Vector3.zero, Look = V(0, 0, -1), Phase = 0 }
end

local function poseMega(b: Beast, mode: string)
	local L = SeaBeasts.Megalodon.Length
	local swish = sin(b.Phase * (if mode == "Charge" then 9 else 4)) * (if mode == "Hooked" then 0.6 else 0.22)
	local cf = CFrame.lookAt(b.Pos, b.Pos + b.Look)
	local p = b.Parts
	p.Body.CFrame = cf
	p.Belly.CFrame = cf * CF(0, -3.5, 0)
	p.Head.CFrame = cf * CF(0, 0.5, -L * 0.36)
	local open = if mode == "Charge" then 0.35 else 0.05
	p.Jaw.CFrame = cf * CF(0, -3.6, -L * 0.4) * ANG(-open, 0, 0)
	p.Teeth.CFrame = cf * CF(0, -2.4, -L * 0.45)
	p.Dorsal.CFrame = cf * CF(0, 10, -2) * ANG(0, math.pi, 0)
	local tail = cf * CF(0, 0, L * 0.33) * ANG(0, swish, 0)
	p.TailBase.CFrame = tail * CF(0, 0, 6)
	p.Tail.CFrame = tail * CF(0, 5, 15) * ANG(0, math.pi, 0) * ANG(math.rad(-25), 0, 0)
	p.TailLow.CFrame = tail * CF(0, -3.5, 14) * ANG(0, math.pi, 0) * ANG(math.rad(200), 0, 0)
	p.FinL.CFrame = cf * CF(-8, -4, -6) * ANG(0, 0.3, 0.35)
	p.FinR.CFrame = cf * CF(8, -4, -6) * ANG(0, -0.3, -0.35)
	p.EyeL.CFrame = cf * CF(-4.6, 2, -L * 0.42)
	p.EyeR.CFrame = cf * CF(4.6, 2, -L * 0.42)
end

local function makeKraken()
	local L = Ocean.Lair
	local mouth = V(L.X, L.Y - 4, L.Z + 70)
	local body = part(V(26, 20, 30), rgb(120, 40, 60), Enum.Material.SmoothPlastic, "Sphere")
	body.CFrame = CF(V(L.X, L.Y - 4, L.Z + 40))
	local eyes = {}
	for _, dx in { -6, 6 } do
		local e = part(V(3, 3, 1.4), rgb(255, 210, 60), Enum.Material.Neon, "Sphere")
		e.CFrame = CF(V(L.X + dx, L.Y + 2, L.Z + 54))
		table.insert(eyes, e)
	end
	light(eyes[1], rgb(255, 200, 80), 30)
	local tentacle = {}
	for i = 1, 10 do
		local seg = part(V(3.2 - i * 0.22, 3.2 - i * 0.22, 9), rgb(150, 50, 70), Enum.Material.SmoothPlastic, "Sphere")
		seg.CFrame = CF(mouth)
		table.insert(tentacle, seg)
	end
	local ink = Instance.new("ParticleEmitter")
	ink.Texture = "rbxasset://textures/particles/smoke_main.dds"
	ink.Color = ColorSequence.new(rgb(10, 6, 20))
	ink.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(1, 14) })
	ink.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	ink.Lifetime = NumberRange.new(2, 3)
	ink.Speed = NumberRange.new(4, 8)
	ink.SpreadAngle = Vector2.new(60, 60)
	ink.Rate = 0
	ink.Parent = body
	krakenView = { Body = body, Eyes = eyes, Tentacle = tentacle, Reach = 0, Ink = ink }
end

local function poseKraken(mode: string, at: Vector3?, t: number, dt: number)
	local k = krakenView
	if not k then
		return
	end
	local L = Ocean.Lair
	local mouth = V(L.X, L.Y - 4, L.Z + 70)
	local want = if mode == "Warn" then 0.35 elseif mode == "Strike" then 1 else 0
	k.Reach += (want - k.Reach) * math.min(1, dt * (if mode == "Strike" then 14 else 3))
	if k.Ink then
		k.Ink.Rate = if mode == "Warn" then 30 else 0
	end
	local target = at or (mouth + V(0, -6, 30))
	local n = #k.Tentacle
	for i, seg in k.Tentacle do
		local u = i / n
		local reachPoint = mouth:Lerp(target, u * k.Reach)
		local wave = V(sin(t * 3 + i * 0.7) * 2 * (1 - k.Reach), cos(t * 2.4 + i) * 1.5, 0)
		local pos = reachPoint + wave + (if k.Reach < 0.05 then V(sin(t + i) * 1.5, -i * 0.6, i * 1.8) else Vector3.zero)
		local nextPos = mouth:Lerp(target, math.min(1, (i + 1) / n) * k.Reach + 0.001) + wave
		seg.CFrame = CFrame.lookAt(pos, nextPos + V(0, 0, 0.01))
	end
	for _, e in k.Eyes do
		e.Transparency = if mode == "Lurk" then 0.4 + 0.3 * sin(t * 0.8) else 0
	end
end

local function updateBeasts(t: number, dt: number, cam: Vector3)
	local f = workspace:FindFirstChild("SeaBeasts")
	if not f then
		return
	end
	-- Megalodón: cerca de la cámara, se dibuja y se suaviza
	local mc = f:FindFirstChild("Megalodon")
	local pos = mc and mc:GetAttribute("Pos")
	local mode = mc and mc:GetAttribute("Mode") or "Gone"
	if typeof(pos) == "Vector3" and mode ~= "Gone" and (pos - cam).Magnitude < 420 then
		if not mega then
			mega = makeMega()
			mega.Pos = pos
		end
		local b = mega :: Beast
		local look = mc:GetAttribute("Look")
		b.Pos = b.Pos:Lerp(pos, math.min(1, dt * 6))
		if typeof(look) == "Vector3" and look.Magnitude > 0.1 then
			b.Look = b.Look:Lerp(look.Unit, math.min(1, dt * 5)).Unit
		end
		b.Phase += dt
		poseMega(b, mode)
	elseif mega then
		local list = {}
		for _, p in mega.Parts do
			table.insert(list, p)
		end
		destroyParts(list)
		mega = nil
	end
	-- Kraken: solo si estás cerca de la sima
	local kc = f:FindFirstChild("Kraken")
	local L = Ocean.Lair
	local near = (V(L.X, L.Y, L.Z) - cam).Magnitude < 360
	local kmode = kc and kc:GetAttribute("Mode") or "Gone"
	if near and kmode ~= "Gone" then
		if not krakenView then
			makeKraken()
		end
		local at = kc and kc:GetAttribute("At")
		poseKraken(kmode, if typeof(at) == "Vector3" then at else nil, t, dt)
	elseif krakenView then
		local list = { krakenView.Body :: BasePart }
		for _, e in krakenView.Eyes do
			table.insert(list, e)
		end
		for _, s in krakenView.Tentacle do
			table.insert(list, s)
		end
		destroyParts(list)
		krakenView = nil
	end
end

-- El megalodón más cerca (para la cámara de fotos y el HUD): posición o nil
function SeaLife.nearestBeast(from: Vector3): (string?, Vector3?)
	local f = workspace:FindFirstChild("SeaBeasts")
	if not f then
		return nil, nil
	end
	local best, bestPos, bestD = nil, nil, math.huge
	for _, id in { "Megalodon", "Kraken" } do
		local c = f:FindFirstChild(id)
		local pos = c and (c:GetAttribute("At") or c:GetAttribute("Pos"))
		if typeof(pos) == "Vector3" and c:GetAttribute("Mode") ~= "Gone" then
			local d = (pos - from).Magnitude
			if d < bestD then
				best, bestPos, bestD = id, pos, d
			end
		end
	end
	return best, bestPos
end

function SeaLife.partCount(): number
	return partCount
end

---------------------------------------------------------------------

function SeaLife.init()
	-- Empujones de los golpes (el personaje es tuyo: lo mueve tu ordenador)
	local sea = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Sea") :: RemoteEvent
	if sea then
		sea.OnClientEvent:Connect(function(kind, data)
			if kind == "Knock" and type(data) == "table" and typeof(data.Velocity) == "Vector3" then
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root then
					root.AssemblyLinearVelocity = data.Velocity
				end
				pcall(function()
					require(script.Parent.CameraShake).shake(0.8, 0.5)
				end)
			end
		end)
	end
	local zone: string? = nil
	local nextZone, nextSpawn = 0, 0
	local frame = 0
	RunService.RenderStepped:Connect(function(dt)
		local ok, err = pcall(function()
			local t = os.clock()
			local cam = workspace.CurrentCamera.CFrame.Position
			local under = cam.Y < SURFACE + 6
			if t >= nextZone then
				nextZone = t + 1
				zone = if under then Ocean.zoneAt(cam.X, cam.Z) else nil
			end
			updateBeasts(t, dt, cam)
			if not zone then
				if #creatures > 0 then
					cullFar(cam, true)
				end
				return
			end
			if t >= nextSpawn then
				nextSpawn = t + 0.5
				cullFar(cam)
				spawnAround(cam, zone :: string)
			end
			frame += 1
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local me = if root then root.Position else nil
			for i, c in creatures do
				-- lo lejano, a la mitad de fotogramas
				local far = (c.Pos - cam).Magnitude > 70
				if not far or (frame + i) % 2 == 0 then
					local step = STEP[c.Kind]
					if step then
						step(c, if far then dt * 2 else dt, me)
					end
				end
			end
		end)
		if not ok then
			warn("[SeaLife] " .. tostring(err))
		end
	end)
end

return SeaLife
