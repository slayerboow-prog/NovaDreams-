-- SeaAmbient (cliente): la vida grande y lejana del mar enorme (v120, docs/mar/diseno.md «Mar enorme»).
-- Solo en tu pantalla, solo con la cámara bajo el agua y sin choques ni consultas (no estorba a nadie).
-- Las reglas (qué gigante, por dónde pasa, dónde está cada medusa, los topes) están en shared/Sea/Ambient.
--
--   * Gigantes que pasan a lo lejos entre la bruma: ballena, manta gigante y, rara vez en lo hondo, el
--     leviatán. Pasan de largo y se quitan. Como mucho 1 a la vez en el móvil (2 en el ordenador).
--   * Campos de medusas que brillan (Ocean.JellyFields): rosas, cian y violetas, subiendo y bajando
--     despacio. Un montón fijo de piezas que se reutiliza (no se crean ni se destruyen al moverte).
-- Barato: todo se mueve con workspace:BulkMoveTo, lo lejano a menos fotogramas, y el total de piezas
-- nunca pasa de Ambient.Caps (lo prueba test-mar). Lo inicia Controllers/SeaLife.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Ocean = require(ReplicatedStorage.Shared.Sea.Ocean)
local Ambient = require(ReplicatedStorage.Shared.Sea.Ambient)
local MarFauna = require(ReplicatedStorage.Shared.Sea.MarFauna) -- (v125: ballena, manta y medusa con malla y textura)
local Perf = require(script.Parent.Parent.UI.Perf)

local SeaAmbient = {}

local _player = Players.LocalPlayer
local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local sin, cos, random = math.sin, math.cos, math.random

local LITE = Perf.lite == true
local CAPS = Ambient.caps(LITE)

local folder: Folder? = nil
local function getFolder(): Folder
	if not folder or not folder.Parent then
		local f = Instance.new("Folder")
		f.Name = "SeaAmbient"
		f.Parent = workspace
		folder = f
	end
	return folder :: Folder
end

local partCount = 0
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

local function destroy(list: { BasePart })
	for _, p in list do
		partCount -= 1
		p:Destroy()
	end
end

-- Mover muchas piezas de una vez (BulkMoveTo); si no se puede, una a una
local function move(parts: { BasePart }, cframes: { CFrame })
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
-- Gigantes
---------------------------------------------------------------------
type Giant = { Kind: string, Path: Ambient.Path, T: number, Parts: { BasePart }, Pose: (Giant, CFrame, number) -> { CFrame } }
local giants: { Giant } = {}

local WHALE = rgb(44, 58, 74)
local WHALE_BELLY = rgb(150, 162, 168)
-- v125: con la malla de MarFauna (una pieza con su textura) el gigante nada ondulando entero; sin ella,
-- su respaldo de piezas (abajo)
local function meshGiant(name: string, length: number, wave: number): ({ BasePart }, (Giant, CFrame, number) -> { CFrame })?
	local m = MarFauna.clone(name, length)
	if not m then
		return nil
	end
	m.Parent = getFolder()
	partCount += 1
	local function pose(_g: Giant, cf: CFrame, t: number): { CFrame }
		return { cf * ANG(sin(t * 0.9) * wave, 0, sin(t * 0.45) * wave * 0.6) * ANG(0, MarFauna.MeshYaw, 0) }
	end
	return { m }, pose
end

local function makeWhale(): ({ BasePart }, (Giant, CFrame, number) -> { CFrame })
	local L = Ambient.Giants.Whale.Length
	local meshParts, meshPose = meshGiant("Ballena", L, 0.05)
	if meshParts and meshPose then
		return meshParts, meshPose
	end
	local parts = {
		part(V(16, 14, L * 0.6), WHALE, nil, true), -- cuerpo
		part(V(14, 12, 24), WHALE, nil, true), -- cabeza
		part(V(12, 5, L * 0.45), WHALE_BELLY, nil, true), -- vientre
		part(V(7, 6, 26), WHALE, nil, true), -- cola
		part(V(14, 1.2, 8), WHALE, nil, true), -- aleta caudal izquierda
		part(V(14, 1.2, 8), WHALE, nil, true), -- derecha
		part(V(16, 1, 5), WHALE, nil, true), -- aleta pectoral izquierda
		part(V(16, 1, 5), WHALE, nil, true), -- derecha
	}
	local function pose(_g: Giant, cf: CFrame, t: number): { CFrame }
		local beat = sin(t * 0.9) * 0.22
		local tail = cf * CF(0, 0.5, L * 0.3) * ANG(beat, 0, 0)
		local fluke = tail * CF(0, 0, 13) * ANG(beat * 1.2, 0, 0)
		local fin = sin(t * 0.6) * 0.15
		return {
			cf,
			cf * CF(0, -0.5, -L * 0.33),
			cf * CF(0, -5.5, -L * 0.08),
			tail * CF(0, 0, 6),
			fluke * CF(-7, 0, 3) * ANG(0, 0.35, 0),
			fluke * CF(7, 0, 3) * ANG(0, -0.35, 0),
			cf * CF(-10, -4, -L * 0.18) * ANG(0, 0.5, -0.35 + fin),
			cf * CF(10, -4, -L * 0.18) * ANG(0, -0.5, 0.35 - fin),
		}
	end
	return parts, pose
end

local MANTA = rgb(30, 38, 52)
local function makeManta(): ({ BasePart }, (Giant, CFrame, number) -> { CFrame })
	local L = Ambient.Giants.Manta.Length
	local meshParts, meshPose = meshGiant("Manta", L * 0.6, 0.1)
	if meshParts and meshPose then
		return meshParts, meshPose
	end
	local parts = {
		part(V(L * 0.42, 2.6, L * 0.5), MANTA, nil, true), -- cuerpo
		part(V(L * 0.42, 1, L * 0.36), MANTA, nil, true), -- ala izquierda
		part(V(L * 0.42, 1, L * 0.36), MANTA, nil, true), -- ala derecha
		part(V(0.5, 0.5, L * 0.55), MANTA), -- cola
	}
	local function pose(_g: Giant, cf: CFrame, t: number): { CFrame }
		local flap = sin(t * 1.1) * 0.38
		local half = L * 0.21
		return {
			cf,
			cf * CF(-half * 0.8, 0, 1) * ANG(0, 0, flap) * CF(-half, 0, 0),
			cf * CF(half * 0.8, 0, 1) * ANG(0, 0, -flap) * CF(half, 0, 0),
			cf * CF(0, 0, L * 0.5) * ANG(sin(t * 1.1 + 1) * 0.1, 0, 0),
		}
	end
	return parts, pose
end

local LEVIATHAN = rgb(26, 40, 56)
local LEVIATHAN_GLOW = rgb(90, 240, 255)
local function makeLeviathan(): ({ BasePart }, (Giant, CFrame, number) -> { CFrame })
	local def = Ambient.Giants.Leviathan
	local n = def.Parts - 2
	local parts = {}
	for i = 1, n do
		local r = 14 * (1 - (i - 1) / n * 0.7)
		table.insert(parts, part(V(r, r * 0.9, def.Length / n * 1.5), LEVIATHAN, nil, true))
	end
	table.insert(parts, part(V(1.6, 1.6, 1.6), LEVIATHAN_GLOW, Enum.Material.Neon, true)) -- ojos
	table.insert(parts, part(V(1.6, 1.6, 1.6), LEVIATHAN_GLOW, Enum.Material.Neon, true))
	-- puntos de luz por el lomo (unos pocos trozos con brillo)
	for i = 3, n, 3 do
		parts[i].Material = Enum.Material.Neon
		parts[i].Color = rgb(40, 120, 150)
	end
	local spacing = def.Length / n
	local function pose(g: Giant, cf: CFrame, t: number): { CFrame }
		local out = {}
		local dir = cf.LookVector
		local side = cf.RightVector
		local prev: Vector3? = nil
		for i = 1, n do
			local back = (i - 1) * spacing
			local wave = sin(t * 0.7 - i * 0.45) * (6 + i * 0.5)
			local p = cf.Position - dir * back + side * wave + V(0, sin(t * 0.4 - i * 0.3) * 3, 0)
			local aim = if prev then prev else p + dir
			out[i] = CFrame.lookAt(p, aim)
			prev = p
		end
		local head = out[1]
		out[n + 1] = head * CF(-4, 2.5, -5)
		out[n + 2] = head * CF(4, 2.5, -5)
		local _ = g
		return out
	end
	return parts, pose
end

local MAKERS = { Whale = makeWhale, Manta = makeManta, Leviathan = makeLeviathan }

local function giantParts(): number
	local n = 0
	for _, g in giants do
		n += #g.Parts
	end
	return n
end

local function trySpawnGiant(cam: CFrame, zone: string?)
	if #giants >= CAPS.Giants then
		return
	end
	local kind = Ambient.pickGiant(zone, random())
	if not kind then
		return
	end
	-- (el leviatán, rara vez)
	if kind == "Leviathan" and random() > 0.3 then
		return
	end
	local def = Ambient.Giants[kind]
	if partCount + def.Parts > CAPS.Parts then
		return
	end
	local path = Ambient.path(kind, cam.Position, cam.LookVector, random(), random(), random())
	if not path then
		return
	end
	local parts, pose = MAKERS[kind]()
	table.insert(giants, { Kind = kind, Path = path, T = 0, Parts = parts, Pose = pose })
end

local function stepGiants(dt: number, cam: Vector3, all: boolean?)
	for i = #giants, 1, -1 do
		local g = giants[i]
		g.T += dt
		if all or Ambient.done(g.Path, g.T, cam) then
			destroy(g.Parts)
			table.remove(giants, i)
		else
			local pos, dir = Ambient.at(g.Path, g.T)
			move(g.Parts, g.Pose(g, CFrame.lookAt(pos, pos + dir), g.T))
		end
	end
end

---------------------------------------------------------------------
-- Campos de medusas
---------------------------------------------------------------------
type Slot = { Field: any, Index: number, Floor: number, Size: number }
local pool: { { BasePart } } = {} -- { campana, tentáculos }
local slots: { Slot? } = {}
local planKey = ""

local function ensurePool(n: number)
	while #pool < n and partCount + Ambient.JellyParts <= CAPS.Parts - 30 do
		-- (v125: la medusa de MarFauna —campana y tentáculos de cinta en una malla—, que brilla con su color;
		-- sin malla, campana y una cinta plana debajo, no un palo)
		local m = MarFauna.clone("Medusa", 2)
		if m then
			m.Material = Enum.Material.Neon
			m.Parent = getFolder()
			partCount += 1
			table.insert(pool, { m })
		else
			local bell = part(V(2, 1.5, 2), rgb(255, 255, 255), Enum.Material.Neon, true, 0.35)
			local tail = part(V(1, 3, 0.06), rgb(255, 255, 255), Enum.Material.Neon, nil, 0.55)
			table.insert(pool, { bell, tail })
		end
	end
end

local function hideJellies()
	for i, pair in pool do
		if slots[i] then
			slots[i] = nil
			for _, p in pair do
				p.Transparency = 1
			end
		end
	end
	planKey = ""
end

local function replan(cam: Vector3)
	local plan = Ambient.jellyPlan(cam, LITE)
	local key = ""
	local total = 0
	for _, e in plan do
		key ..= e.Field.Name .. e.Count .. ";"
		total += e.Count
	end
	if key == planKey then
		return
	end
	planKey = key
	ensurePool(total)
	local k = 0
	for _, e in plan do
		for i = 1, e.Count do
			k += 1
			local pair = pool[k]
			if not pair then
				break
			end
			local old = slots[k]
			if not (old and old.Field == e.Field and old.Index == i) then
				local _, size, color = Ambient.jelly(e.Field, i, 0, e.Field.Top)
				slots[k] = { Field = e.Field, Index = i, Floor = Ambient.jellyFloor(e.Field, i), Size = size }
				local bell, tail = pair[1], pair[2]
				if tail then
					bell.Size = V(size, size * 0.75, size)
					tail.Size = V(size * 0.5, size * 1.8, 0.06)
					tail.Color = color
					tail.Transparency = 0.55
				else
					local info = MarFauna.Pieces.Medusa
					local k = size / info.Size[1]
					bell.Size = V(info.Size[1] * k, info.Size[2] * k, info.Size[3] * k)
				end
				bell.Color = color
				bell.Transparency = 0.3
			end
		end
	end
	for i = k + 1, #pool do
		if slots[i] then
			slots[i] = nil
			for _, p in pool[i] do
				p.Transparency = 1
			end
		end
	end
end

local jellyParts: { BasePart } = {}
local jellyCFrames: { CFrame } = {}
local function stepJellies(t: number, cam: Vector3, frame: number)
	table.clear(jellyParts)
	table.clear(jellyCFrames)
	for i, slot in slots do
		if slot then
			local pos = Ambient.jelly(slot.Field, slot.Index, t, slot.Floor)
			-- (lo lejano, a menos fotogramas)
			if (pos - cam).Magnitude < 90 or (frame + i) % 3 == 0 then
				local pulse = 1 + sin(t * 2 + i) * 0.08
				local tilt = ANG(sin(t * 0.5 + i) * 0.12, 0, cos(t * 0.4 + i) * 0.12)
				local cf = CF(pos) * tilt
				local pair = pool[i]
				table.insert(jellyParts, pair[1])
				table.insert(jellyCFrames, cf * CF(0, (pulse - 1) * slot.Size, 0))
				if pair[2] then
					table.insert(jellyParts, pair[2])
					table.insert(jellyCFrames, cf * CF(0, -slot.Size * 1.1, 0) * ANG(sin(t * 1.3 + i) * 0.2, 0, 0))
				end
			end
		end
	end
	if #jellyParts > 0 then
		move(jellyParts, jellyCFrames)
	end
end

---------------------------------------------------------------------

function SeaAmbient.partCount(): number
	return partCount
end

function SeaAmbient.counts(): { Giants: number, Jellies: number, Parts: number, GiantParts: number }
	local jellies = 0
	for _, s in slots do
		if s then
			jellies += 1
		end
	end
	return { Giants = #giants, Jellies = jellies, Parts = partCount, GiantParts = giantParts() }
end

-- Una vuelta (la usa init; las pruebas la llaman con una cámara de mentira)
local nextPlan, nextGiant, frame = 0, 0, 0
local zone: string? = nil
local wasUnder = false
function SeaAmbient.step(dt: number, t: number, cam: CFrame)
	local pos = cam.Position
	local under = pos.Y < Ocean.Surface - 1.5 and Ocean.inArea(pos.X, pos.Z)
	if not under then
		if wasUnder then
			wasUnder = false
			hideJellies()
			stepGiants(0, pos, true)
		end
		return
	end
	wasUnder = true
	frame += 1
	if t >= nextPlan then
		nextPlan = t + 1
		zone = Ocean.zoneAt(pos.X, pos.Z)
		replan(pos)
	end
	if t >= nextGiant then
		nextGiant = t + (if LITE then Ambient.Every.Mobile else Ambient.Every.Desktop) * (0.6 + random() * 0.8)
		trySpawnGiant(cam, zone)
	end
	stepGiants(dt, pos)
	stepJellies(t, pos, frame)
end

function SeaAmbient.init()
	RunService.RenderStepped:Connect(function(dt)
		local ok, err = pcall(function()
			local camera = workspace.CurrentCamera
			if camera then
				SeaAmbient.step(dt, os.clock(), camera.CFrame)
			end
		end)
		if not ok then
			warn("[SeaAmbient] " .. tostring(err))
		end
	end)
end

return SeaAmbient
