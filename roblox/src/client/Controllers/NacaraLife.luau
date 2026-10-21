-- NacaraLife (cliente): lo que se mueve en la plaza de prueba de Nácara (fase 0,
-- docs/mar/civilizacion-marina.md), solo en tu pantalla y solo cerca.
--
--   * Los Hondarios (etiqueta HondarioNpc; los pone Services/NacaraService): se mecen arriba y abajo,
--     se inclinan un poco y la cola hace la onda (Motor6D.Transform de sus tramos). Solo los que están
--     a menos de NpcRange studs; los demás, quietos. Barato: unos pocos CFrame por fotograma.
--   * Vida de la ciudad: un banco de pececillos de colores alrededor de las torres y unas medusas que
--     brillan. Tope de piezas: Caps (móvil / ordenador), y solo con la cámara a menos de LifeRange.
--   * Las perlas de guía de la ruta de buceo (Nacara.routePoints: del jardín de coral más cercano a la
--     plaza, pasando por las Ruinas de Valmar la Vieja): perlas que brillan a lo largo de la corriente
--     guía. Un montón fijo de piezas que se recoloca: solo las cercanas (MarkerRange).
-- Todo sin choques ni consultas (CanCollide/CanQuery/CanTouch false) y movido con BulkMoveTo.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Nacara = require(ReplicatedStorage.Shared.Sea.Nacara)
local MarFauna = require(ReplicatedStorage.Shared.Sea.MarFauna) -- (los peces con malla de Blender, si están subidos)
local Perf = require(script.Parent.Parent.UI.Perf)

local NacaraLife = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local sin, cos = math.sin, math.cos

local LITE = Perf.lite == true
NacaraLife.Caps = { Mobile = { Fish = 10, Jelly = 2, Markers = 8, Npcs = 6, School = 10, Sway = 12, Pulse = 24 }, Desktop = { Fish = 18, Jelly = 4, Markers = 12, Npcs = 8, School = 20, Sway = 30, Pulse = 60 } }
NacaraLife.SwayRange = 160
NacaraLife.SchoolRing = { 44, 70 } -- el banco de peces da vueltas a la plaza a esta distancia
local CAPS = if LITE then NacaraLife.Caps.Mobile else NacaraLife.Caps.Desktop
NacaraLife.NpcRange = 140
NacaraLife.Legs = { "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot", "LeftLeg", "RightLeg" }
NacaraLife.LifeRange = 260
NacaraLife.MarkerRange = 300

local folder: Folder? = nil
local function getFolder(): Folder
	if not folder or not folder.Parent then
		local f = Instance.new("Folder")
		f.Name = "NacaraLife"
		f.Parent = workspace
		folder = f
	end
	return folder :: Folder
end

local partCount = 0
function NacaraLife.partCount(): number
	return partCount
end

local function part(size: Vector3, color: Color3, material: Enum.Material?, sphere: boolean?, transparency: number?): BasePart
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
	if sphere then
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Sphere
		m.Parent = p
	end
	p.Parent = getFolder()
	partCount += 1
	return p
end

local function move(parts: { BasePart }, cframes: { CFrame })
	if #parts == 0 then
		return
	end
	local ok = pcall(function()
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end)
	if not ok then
		for i, p in parts do
			p.CFrame = cframes[i]
		end
	end
end

---------------------------------------------------------------------
-- Los Hondarios
---------------------------------------------------------------------
-- Cuánto se mece y la onda de la cola (puro: lo prueba test-nacara)
function NacaraLife.bob(t: number, seed: number): (number, number)
	return sin(t * 1.1 + seed) * 0.35, sin(t * 0.7 + seed * 1.3) * 0.05
end
function NacaraLife.tailWave(t: number, seed: number, i: number): number
	return sin(t * 2.2 + seed - i * 0.7) * (0.12 + i * 0.05)
end

-- Una vuelta nadando alrededor de su sitio (puro: lo prueba test-hondario). Devuelve el CFrame (mirando
-- hacia donde nada, un poco inclinado hacia delante) y la posición
function NacaraLife.swimLoop(center: Vector3, radius: number, t: number, seed: number): (CFrame, Vector3)
	local a = t * (6 / math.max(radius, 4)) * 0.6 + seed
	local pos = center + V(cos(a) * radius, sin(a * 2) * 1.2, sin(a) * radius)
	local ahead = center + V(cos(a + 0.15) * radius, sin((a + 0.15) * 2) * 1.2, sin(a + 0.15) * radius)
	return CFrame.lookAt(pos, ahead) * ANG(math.rad(-25), 0, 0), pos
end

local function animateNpcs(t: number, camPos: Vector3)
	local n = 0
	for _, model in CollectionService:GetTagged("HondarioNpc") do
		if n >= CAPS.Npcs then
			break
		end
		local home = model:GetAttribute("Home")
		local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
		if typeof(home) == "CFrame" and root and ((home :: CFrame).Position - camPos).Magnitude < NacaraLife.NpcRange then
			n += 1
			local seed = model:GetAttribute("BobSeed") or 0
			-- (en esta pantalla, las piernas nunca: aunque algo las vuelva a pintar, se ve la cola)
			for _, name in NacaraLife.Legs do
				local leg = model:FindFirstChild(name)
				if leg and leg:IsA("BasePart") and leg.LocalTransparencyModifier < 1 then
					leg.LocalTransparencyModifier = 1
				end
			end
			local dy, tilt = NacaraLife.bob(t, seed)
			local swim = model:GetAttribute("SwimRadius")
			local fast = 1
			if type(swim) == "number" and swim > 0 and not model:GetAttribute("Busy") and not model:GetAttribute("StoryAway") then
				-- (los que no atienden a nadie dan vueltas nadando: la cola va más deprisa)
				local cf, _ = NacaraLife.swimLoop((home :: CFrame).Position, swim, t, seed)
				root.CFrame = cf * CF(0, dy, 0)
				fast = 1.8
			else
				root.CFrame = (home :: CFrame) * CF(0, dy, 0) * ANG(tilt, 0, 0)
			end
			for i = 1, 4 do
				local seg = model:FindFirstChild("Cola" .. i)
				local motor = seg and seg:FindFirstChild("ColaJunta" .. i)
				if motor and motor:IsA("Motor6D") then
					motor.Transform = ANG(NacaraLife.tailWave(t * fast, seed, i) * (if fast > 1 then 1.5 else 1), 0, 0)
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- Peces y medusas de la ciudad
---------------------------------------------------------------------
type Fish = { Part: BasePart, Ring: number, Speed: number, Phase: number, Height: number, Tower: { [string]: any } }
local fish: { Fish } = {}
type Jelly = { Bell: BasePart, Glow: BasePart, Phase: number, X: number, Z: number, Y: number }
local jellies: { Jelly } = {}

local FISH_COLORS = { rgb(255, 200, 90), rgb(120, 230, 255), rgb(255, 140, 200), rgb(190, 160, 255), rgb(255, 255, 255) }

type SchoolFish = { Part: BasePart, Ring: number, Speed: number, Phase: number, Y: number }
local school: { SchoolFish } = {}
local SCHOOL_KINDS = { "PezBanco", "PezCirujano", "PezLoro", "PezAngel" }

-- Un pez del banco: con su malla si está subida (MarFauna) y, si no, un cuerpo de pez de piezas
local function schoolFish(i: number): BasePart
	local kind = SCHOOL_KINDS[(i - 1) % #SCHOOL_KINDS + 1]
	local ok, mesh = pcall(MarFauna.clone, kind, 1.6)
	if ok and mesh then
		mesh.Anchored = true
		mesh.CanCollide = false
		mesh.CanQuery = false
		mesh.CanTouch = false
		mesh.CastShadow = false
		mesh.Parent = getFolder()
		partCount += 1
		return mesh
	end
	return part(V(0.4, 0.6, 1.5), FISH_COLORS[(i - 1) % #FISH_COLORS + 1], if i % 4 == 0 then Enum.Material.Neon else Enum.Material.SmoothPlastic, true)
end

local function makeLife()
	for i = 1, CAPS.School do
		local ring = NacaraLife.SchoolRing[1] + (NacaraLife.SchoolRing[2] - NacaraLife.SchoolRing[1]) * ((i * 37) % 10) / 10
		table.insert(school, { Part = schoolFish(i), Ring = ring, Speed = 0.12 + (i % 4) * 0.015, Phase = i * 0.21, Y = 9 + (i * 13) % 14 })
	end
	local towers = {}
	for _, item in Nacara.Layout do
		if item.Kind == "Tower" then
			table.insert(towers, item)
		end
	end
	for i = 1, CAPS.Fish do
		local tower = towers[(i - 1) % #towers + 1]
		local p = part(V(0.35, 0.5, 1.1), FISH_COLORS[(i - 1) % #FISH_COLORS + 1], if i % 3 == 0 then Enum.Material.Neon else Enum.Material.SmoothPlastic, true)
		table.insert(fish, { Part = p, Ring = 9 + (i % 4) * 2.5, Speed = 0.5 + (i % 5) * 0.08, Phase = i * 0.9, Height = 8 + (i * 7) % (tower.H - 12), Tower = tower })
	end
	local glow = { rgb(255, 150, 220), rgb(120, 240, 255), rgb(190, 150, 255), rgb(255, 200, 150) }
	for i = 1, CAPS.Jelly do
		local a = i / CAPS.Jelly * math.pi * 2 + 0.6
		local c = glow[(i - 1) % #glow + 1]
		table.insert(jellies, {
			Bell = part(V(2.6, 1.8, 2.6), c, Enum.Material.Neon, true, 0.35),
			Glow = part(V(0.25, 3.2, 0.25), c, Enum.Material.Neon, false, 0.5),
			Phase = i * 1.7,
			X = cos(a) * 30,
			Z = sin(a) * 30,
			Y = 18 + i * 6,
		})
	end
end

local fishParts: { BasePart } = {}
local fishCF: { CFrame } = {}
local function animateLife(t: number)
	table.clear(fishParts)
	table.clear(fishCF)
	for _, f in fish do
		local tower = f.Tower
		local a = t * f.Speed + f.Phase
		local c = Nacara.toWorld(tower.X, tower.Z, f.Height + sin(t * 0.6 + f.Phase) * 2)
		local pos = c + V(cos(a) * f.Ring, 0, sin(a) * f.Ring)
		local ahead = c + V(cos(a + 0.2) * f.Ring, 0, sin(a + 0.2) * f.Ring)
		table.insert(fishParts, f.Part)
		table.insert(fishCF, CFrame.lookAt(pos, ahead))
	end
	for _, j in jellies do
		local y = j.Y + sin(t * 0.5 + j.Phase) * 3
		local base = Nacara.toWorld(j.X + sin(t * 0.13 + j.Phase) * 4, j.Z + cos(t * 0.11 + j.Phase) * 4, y)
		table.insert(fishParts, j.Bell)
		table.insert(fishCF, CF(base))
		table.insert(fishParts, j.Glow)
		table.insert(fishCF, CF(base - V(0, 2, 0)) * ANG(sin(t + j.Phase) * 0.15, 0, 0))
	end
	for _, f in school do
		local a = t * f.Speed + f.Phase
		local c = Nacara.toWorld(0, 0, f.Y + sin(t * 0.4 + f.Phase) * 1.5)
		local pos = c + V(cos(a) * f.Ring, 0, sin(a) * f.Ring)
		local ahead = c + V(cos(a + 0.05) * f.Ring, 0, sin(a + 0.05) * f.Ring)
		table.insert(fishParts, f.Part)
		table.insert(fishCF, CFrame.lookAt(pos, ahead) * ANG(0, MarFauna.MeshYaw or 0, 0))
	end
	move(fishParts, fishCF)
end

local function clearLife()
	for _, f in fish do
		f.Part:Destroy()
		partCount -= 1
	end
	for _, j in jellies do
		j.Bell:Destroy()
		j.Glow:Destroy()
		partCount -= 2
	end
	for _, f in school do
		f.Part:Destroy()
		partCount -= 1
	end
	table.clear(school)
	table.clear(fish)
	table.clear(jellies)
end

---------------------------------------------------------------------
-- El kelp y los corales que se mecen (NacaraSway) y las perlas que laten (NacaraPulse, MarLamp)
---------------------------------------------------------------------
type Swayer = { Object: Instance, Base: CFrame, Pos: Vector3, Seed: number }
local swayers: { [Instance]: Swayer } = {}
local function baseOf(o: Instance): (CFrame?, Vector3?)
	if o:IsA("BasePart") then
		return o.CFrame, o.Position
	elseif o:IsA("Model") then
		local cf = o:GetPivot()
		return cf, cf.Position
	end
	return nil, nil
end

-- El giro de algo que se mece (puro: lo prueba test-hondario): pequeño, lento y distinto para cada uno
function NacaraLife.swayAngles(t: number, seed: number): (number, number)
	return sin(t * 0.9 + seed * 6) * 0.07, cos(t * 0.7 + seed * 4) * 0.05
end

local function animateSway(t: number, camPos: Vector3)
	local list = {}
	for _, o in CollectionService:GetTagged("NacaraSway") do
		local s = swayers[o]
		if not s then
			local cf, pos = baseOf(o)
			if cf and pos then
				s = { Object = o, Base = cf, Pos = pos, Seed = (pos.X * 0.13 + pos.Z * 0.07) % 1 }
				swayers[o] = s
			end
		end
		if s and (s.Pos - camPos).Magnitude < NacaraLife.SwayRange then
			table.insert(list, s)
		end
	end
	table.sort(list, function(a, b)
		return (a.Pos - camPos).Magnitude < (b.Pos - camPos).Magnitude
	end)
	for i = 1, math.min(#list, CAPS.Sway) do
		local s = list[i]
		local rx, rz = NacaraLife.swayAngles(t, s.Seed)
		local o = s.Object
		if o.Parent then
			if o:IsA("BasePart") then
				local h = o.Size.Y / 2
				o.CFrame = s.Base * CF(0, -h, 0) * ANG(rx, 0, rz) * CF(0, h, 0)
			elseif o:IsA("Model") then
				o:PivotTo(s.Base * ANG(rx, 0, rz))
			end
		end
	end
end

-- El latido de las perlas (puro): transparencia de 0 a 0,45
function NacaraLife.pulse(t: number, phase: number): number
	return 0.225 + sin(t * 1.6 + phase) * 0.225
end

local function animatePulse(t: number, camPos: Vector3)
	local n = 0
	for _, tag in { "NacaraPulse", "MarLamp" } do
		for _, p in CollectionService:GetTagged(tag) do
			if n >= CAPS.Pulse then
				return
			end
			if p:IsA("BasePart") and (p.Position - camPos).Magnitude < 400 then
				n += 1
				local phase = p:GetAttribute("Pulse")
				p.LocalTransparencyModifier = NacaraLife.pulse(t, if type(phase) == "number" then phase else (p.Position.X * 0.05) % 6)
			end
		end
	end
end

---------------------------------------------------------------------
-- Las perlas de guía
---------------------------------------------------------------------
local markers: { BasePart } = {}
local HIDDEN = CF(0, -5000, 0)

-- Las perlas de la ruta más cercanas a un punto (como mucho n). Puro: lo prueba test-nacara.
function NacaraLife.nearestMarkers(points: { { [string]: any } }, at: Vector3, n: number, range: number): { { [string]: any } }
	local list = {}
	for _, m in points do
		local d = (m.Position - at).Magnitude
		if d < range then
			table.insert(list, { Point = m, D = d })
		end
	end
	table.sort(list, function(a, b)
		return a.D < b.D
	end)
	local out = {}
	for i = 1, math.min(n, #list) do
		out[i] = list[i].Point
	end
	return out
end

local markerParts: { BasePart } = {}
local markerCF: { CFrame } = {}
local function animateMarkers(t: number, camPos: Vector3)
	if #markers == 0 then
		for _ = 1, CAPS.Markers do
			table.insert(markers, part(V(1.4, 1.4, 1.4), rgb(170, 245, 255), Enum.Material.Neon, true, 0.15))
		end
	end
	local near = NacaraLife.nearestMarkers(Nacara.routePoints(), camPos, CAPS.Markers, NacaraLife.MarkerRange)
	table.clear(markerParts)
	table.clear(markerCF)
	for i, p in markers do
		local m = near[i]
		table.insert(markerParts, p)
		if m then
			-- (la perla «tira» hacia la plaza: se adelanta y vuelve, como llevada por la corriente)
			local push = (t * 0.6 + i * 0.37) % 1
			table.insert(markerCF, CF(m.Position + m.Dir * (push * 6) + V(0, sin(t * 1.3 + i) * 0.4, 0)))
		else
			table.insert(markerCF, HIDDEN)
		end
	end
	move(markerParts, markerCF)
end

local function clearMarkers()
	for _, p in markers do
		p:Destroy()
		partCount -= 1
	end
	table.clear(markers)
end

---------------------------------------------------------------------

function NacaraLife.init()
	local center = Nacara.centerPosition()
	local lifeOn = false
	local markersOn = false
	local frame = 0
	RunService.RenderStepped:Connect(function()
		frame += 1
		local ok, err = pcall(function()
			local camera = workspace.CurrentCamera
			if not camera then
				return
			end
			local camPos = camera.CFrame.Position
			local t = os.clock()
			local flat = V(camPos.X - center.X, 0, camPos.Z - center.Z).Magnitude
			local under = camPos.Y < Nacara.FloorY + 120
			-- la gente: cada fotograma si está cerca (son pocos)
			if flat < NacaraLife.NpcRange + 20 and under then
				animateNpcs(t, camPos)
			end
			-- la vida de la ciudad
			local wantLife = flat < NacaraLife.LifeRange and under
			if wantLife and not lifeOn then
				makeLife()
				lifeOn = true
			elseif not wantLife and lifeOn then
				clearLife()
				lifeOn = false
			end
			if lifeOn and (not LITE or frame % 2 == 0) then
				animateLife(t)
			end
			-- el kelp y los corales se mecen; las perlas laten (también las boyas de la superficie)
			if flat < NacaraLife.LifeRange + 60 and under and frame % 2 == 0 then
				animateSway(t, camPos)
			end
			if frame % 3 == 0 then
				animatePulse(t, camPos)
			end
			-- las perlas de guía (en cualquier punto de la ruta, bajo el agua)
			local wantMarkers = camPos.Y < -3 and frame % 3 == 0
			if wantMarkers then
				animateMarkers(t, camPos)
				markersOn = true
			elseif markersOn and camPos.Y >= -3 then
				clearMarkers()
				markersOn = false
			end
		end)
		if not ok then
			warn("[NacaraLife] " .. tostring(err))
		end
	end)
end

return NacaraLife
