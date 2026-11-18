-- PostWar (servidor): la ciudad normal convertida en la Valmar de después de la Caída, al arrancar el
-- servidor y sobre lo que ya está construido (19-11-2026, el dueño: «no se ve post-apocalíptica»).
-- Es un pase rápido y reversible (Config.PostWar), no la Valmar en ruinas del Vol. IV, que va aparte.
--
--   * RemoveLeisure: fuera los parques infantiles (columpios, toboganes) y las canastas y porterías.
--     Las pistas en sí se quedan (la de la Academia es «la pista» de las misiones) y NUNCA se toca un
--     StoryProp_ / StorySpot_ / StoryArea_ (anclas de las misiones).
--   * BrokenWindows: una parte de los cristales de la ciudad, rotos (invisibles); otra parte, sucios.
--   * Escombros y barricadas a lo largo de las calles: montones de cascotes junto al bordillo y, en
--     algunos cruces, barricadas de tablones y bidones. Deterministas (el mismo sitio en cada servidor).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local PostWar = {}

local rgb = Color3.fromRGB

local LEISURE_PARTS = { SwingBar = true, SwingPost = true, SwingSeat = true, Slide = true, GoalBar = true, GoalPost = true, Basketball = true }
local function isStoryAnchor(inst: Instance): boolean
	local n = inst.Name
	return n:sub(1, 11) == "StoryProp_" or n:sub(1, 10) == "StorySpot_" or n:sub(1, 10) == "StoryArea_"
		or n:sub(1, 10) == "StoryProp_" or n:find("^Story") ~= nil
end

function PostWar.removeLeisure(root: Instance): number
	local removed = 0
	local doomed: { Instance } = {}
	for _, d in root:GetDescendants() do
		if isStoryAnchor(d) then
			continue
		end
		if d:IsA("Model") and d.Name == "Playground" then
			table.insert(doomed, d)
		elseif d:IsA("BasePart") then
			if LEISURE_PARTS[d.Name] then
				table.insert(doomed, d)
			elseif d.Name == "Backboard" or d.Name == "HoopPost" or ((d.Name == "Hoop" or d.Name == "Net") and d.Parent and (d.Parent:FindFirstChild("Backboard") or d.Parent:FindFirstChild("GoalPost"))) then
				table.insert(doomed, d)
			elseif d.Name == "Rope" and d:HasTag("Swing") then
				table.insert(doomed, d)
			end
		end
	end
	for _, d in doomed do
		if d.Parent then
			-- (si dentro lleva un ancla de misión, se deja: mejor un columpio que una misión rota)
			local anchor = false
			for _, c in d:GetDescendants() do
				if isStoryAnchor(c) then
					anchor = true
					break
				end
			end
			if not anchor then
				d:Destroy()
				removed += 1
			end
		end
	end
	return removed
end

local function hash(n: number): number
	local x = math.sin(n * 12.9898 + 78.233) * 43758.5453
	return x - math.floor(x)
end

function PostWar.breakWindows(root: Instance, fraction: number): number
	local broken = 0
	local i = 0
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "Glass" then
			i += 1
			local r = hash(i)
			if r < fraction then
				d.Transparency = 1
				d.CanCollide = false
				broken += 1
			elseif r < fraction + 0.35 then
				d.Color = d.Color:Lerp(rgb(70, 70, 66), 0.55) -- (sucio, con hollín)
				d.Reflectance = 0
			end
		end
	end
	return broken
end

local function ground(at: Vector3, ignore: { Instance }): Vector3?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(at + Vector3.new(0, 60, 0), Vector3.new(0, -140, 0), params)
	return if hit then hit.Position else nil
end

local RUBBLE = { rgb(120, 116, 110), rgb(98, 94, 90), rgb(140, 132, 120), rgb(80, 76, 72) }
local function rubblePile(parent: Instance, at: Vector3, seed: number)
	local m = Instance.new("Model")
	m.Name = "Escombros"
	for k = 1, 5 do
		local p = Instance.new("Part")
		p.Name = "Cascote"
		p.Anchored = true
		p.CanQuery = false
		p.CastShadow = k <= 2
		p.Material = if k % 2 == 0 then Enum.Material.Concrete else Enum.Material.Slate
		p.Color = RUBBLE[1 + (seed + k) % #RUBBLE]
		local s = 1.2 + hash(seed * 3 + k) * 2.6
		p.Size = Vector3.new(s, s * (0.35 + hash(seed + k * 7) * 0.4), s * (0.6 + hash(seed * 5 + k) * 0.6))
		local off = Vector3.new((hash(seed + k) - 0.5) * 4, p.Size.Y / 2 - 0.2, (hash(seed * 2 + k) - 0.5) * 4)
		p.CFrame = CFrame.new(at + off) * CFrame.Angles((hash(seed + k * 11) - 0.5) * 0.8, hash(seed * 7 + k) * 6.28, (hash(seed + k * 13) - 0.5) * 0.8)
		p.Parent = m
	end
	m.Parent = parent
end

local function barricade(parent: Instance, at: Vector3, dir: Vector3, seed: number)
	local m = Instance.new("Model")
	m.Name = "Barricada"
	local side = Vector3.new(-dir.Z, 0, dir.X)
	for k = -1, 1 do
		local plank = Instance.new("Part")
		plank.Name = "Tablon"
		plank.Anchored = true
		plank.Material = Enum.Material.WoodPlanks
		plank.Color = if k == 0 then rgb(110, 84, 58) else rgb(92, 70, 50)
		plank.Size = Vector3.new(9, 0.8, 0.4)
		local pos = at + Vector3.new(0, 1.4 + k * 1.1, 0)
		plank.CFrame = CFrame.lookAt(pos, pos + dir) * CFrame.Angles(0, math.rad(90), math.rad((hash(seed + k) - 0.5) * 14))
		plank.Parent = m
	end
	for k = -1, 1, 2 do
		local barrel = Instance.new("Part")
		barrel.Name = "Bidon"
		barrel.Shape = Enum.PartType.Cylinder
		barrel.Anchored = true
		barrel.Material = Enum.Material.CorrodedMetal
		barrel.Color = if hash(seed * 3 + k) > 0.5 then rgb(96, 60, 44) else rgb(60, 74, 66)
		barrel.Size = Vector3.new(3, 2.2, 2.2)
		local pos = at + side * (k * 5.2) + Vector3.new(0, 1.5, 0)
		barrel.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
		barrel.Parent = m
	end
	m.Parent = parent
end

-- segments: los tramos de calle de World/Kit/Roads ({ A, B, Width })
function PostWar.scatterDebris(segments: { any }, maxPiles: number?): number
	local folder = Instance.new("Folder")
	folder.Name = "Posguerra"
	folder.Parent = workspace
	local ignore = { folder }
	local cap = maxPiles or 260
	local placed = 0
	for i, seg in segments do
		if placed >= cap then
			break
		end
		local a: Vector3 = seg.A
		local b: Vector3 = seg.B
		local len = (b - a).Magnitude
		if len < 40 then
			continue
		end
		local dir = (b - a).Unit
		local side = Vector3.new(-dir.Z, 0, dir.X)
		local half = (seg.Width or 20) / 2
		local steps = math.floor(len / 85)
		for k = 1, steps do
			if placed >= cap then
				break
			end
			local seed = i * 31 + k
			if hash(seed) < 0.55 then
				local t = k / (steps + 1)
				local flip = if hash(seed * 2) < 0.5 then -1 else 1
				local spot = a + dir * (len * t) + side * flip * (half - 2.5)
				local g = ground(spot, ignore)
				if g then
					rubblePile(folder, g, seed)
					placed += 1
				end
			end
		end
		-- algunas barricadas cruzadas al final de un tramo (media calle cortada)
		if hash(i * 17) < 0.08 and placed < cap then
			local spot = b - dir * 10 + side * (half * 0.35)
			local g = ground(spot, ignore)
			if g then
				barricade(folder, g, dir, i)
				placed += 1
			end
		end
	end
	return placed
end

function PostWar.apply(segments: { any }?)
	local pw = Config.PostWar
	if type(pw) ~= "table" then
		return
	end
	local town = workspace:FindFirstChild("Town")
	if town and pw.RemoveLeisure then
		PostWar.removeLeisure(town)
	end
	if town and type(pw.BrokenWindows) == "number" and pw.BrokenWindows > 0 then
		PostWar.breakWindows(town, pw.BrokenWindows)
	end
	if pw.Debris ~= false then
		-- (los tramos de calle los pide aquí si no han llegado: el paso del tráfico corre en su propio hilo)
		local list = segments
		if not list or #list == 0 then
			list = {}
			local ok, Roads = pcall(function()
				return require(script.Parent.Kit.Roads) :: any
			end)
			if ok then
				for _, seg in Roads.segments() do
					table.insert(list, { A = seg.A, B = seg.B, Width = Roads.Kinds[seg.Kind] and Roads.Kinds[seg.Kind].Road or 20 })
				end
			end
		end
		PostWar.scatterDebris(list)
	end
end

return PostWar
