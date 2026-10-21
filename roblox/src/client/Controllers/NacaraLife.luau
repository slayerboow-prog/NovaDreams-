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
local Perf = require(script.Parent.Parent.UI.Perf)

local NacaraLife = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local sin, cos = math.sin, math.cos

local LITE = Perf.lite == true
NacaraLife.Caps = { Mobile = { Fish = 10, Jelly = 2, Markers = 8, Npcs = 6 }, Desktop = { Fish = 18, Jelly = 4, Markers = 12, Npcs = 8 } }
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
			root.CFrame = (home :: CFrame) * CF(0, dy, 0) * ANG(tilt, 0, 0)
			for i = 1, 4 do
				local seg = model:FindFirstChild("Cola" .. i)
				local motor = seg and seg:FindFirstChild("ColaJunta" .. i)
				if motor and motor:IsA("Motor6D") then
					motor.Transform = ANG(NacaraLife.tailWave(t, seed, i), 0, 0)
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

local function makeLife()
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
	table.clear(fish)
	table.clear(jellies)
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
