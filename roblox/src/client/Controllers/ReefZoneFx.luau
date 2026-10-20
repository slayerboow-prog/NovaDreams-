-- ReefZoneFx (cliente): lo que se mueve en el Cañón de Dorada (shared/Sea/ReefZone, World/ReefZoneBuilder),
-- solo en tu pantalla y solo cerca:
--   * Balanceo: el kelp gigante, las praderas, los abanicos y las anémonas (etiqueta «ReefSway») se mecen
--     con la corriente, cada uno a su ritmo (fase y velocidad propias: nunca todos a la vez). Como mucho
--     ReefZoneFx.MaxSway a la vez (los más cercanos, a menos de SwayDistance); el móvil, un tercio.
--   * Haces de luz: de día se ven, de noche casi nada (la luna da poca luz).
--   * Cáusticas (la luz que ondula en el fondo): una lámina con la textura «causticas» (shared/Sea/
--     MarAssetIds, sube scripts/upload-mar.sh) a ras del suelo bajo la cámara cuando el fondo es llano y
--     hay poca agua; la textura se desliza. Sin la textura subida no se pone nada.
-- Funciones puras para las pruebas: ReefZoneFx.swayAngle, ReefZoneFx.pickNearest (scripts/test-reefzone.luau).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ReefZoneFx = {}

ReefZoneFx.SwayDistance = 90
ReefZoneFx.MaxSway = 48
ReefZoneFx.CausticDepth = 40 -- studs: más hondo, la luz ya no dibuja nada en el fondo

local sin = math.sin

-- Cuánto se inclina algo que se mece (radianes) en el tiempo t, con su semilla (fase y ritmo propios)
function ReefZoneFx.swayAngle(t: number, seed: number, tall: number): (number, number)
	local rate = 0.55 + (seed % 1) * 0.5
	local amp = math.clamp(0.05 + tall * 0.004, 0.05, 0.16)
	local a = sin(t * rate + seed * 6.28) * amp + sin(t * rate * 2.3 + seed * 3.1) * amp * 0.35
	local b = sin(t * rate * 0.7 + seed * 4.1) * amp * 0.5
	return a, b
end

-- Los n más cercanos de una lista de { Pos } a menos de maxDist
function ReefZoneFx.pickNearest(list: { any }, from: Vector3, n: number, maxDist: number): { any }
	local near = {}
	for _, item in list do
		local d = (item.Pos - from).Magnitude
		if d < maxDist then
			table.insert(near, { Item = item, D = d })
		end
	end
	table.sort(near, function(a, b)
		return a.D < b.D
	end)
	local out = {}
	for i = 1, math.min(n, #near) do
		out[i] = near[i].Item
	end
	return out
end

type Swayer = { Object: Instance, Pos: Vector3, Base: { [BasePart]: CFrame }, Pivot: CFrame, Seed: number, Tall: number }

function ReefZoneFx.init()
	local Perf = require(script.Parent.Parent.UI.Perf)
	local ReefZone = require(ReplicatedStorage.Shared.Sea.ReefZone)
	local GameClock = require(ReplicatedStorage.Shared.GameClock)
	local maxSway = if Perf.mobile then math.floor(ReefZoneFx.MaxSway / 3) else ReefZoneFx.MaxSway
	local swayers: { [Instance]: Swayer } = {}
	local list: { Swayer } = {}

	local function register(object: Instance)
		if swayers[object] then
			return
		end
		local parts: { BasePart } = {}
		if object:IsA("BasePart") then
			table.insert(parts, object)
		else
			for _, d in object:GetDescendants() do
				if d:IsA("BasePart") then
					table.insert(parts, d)
				end
			end
		end
		if #parts == 0 then
			return
		end
		-- el pie: lo más bajo de la pieza (se mece desde ahí)
		local low, top = math.huge, -math.huge
		local sum = Vector3.zero
		for _, p in parts do
			low = math.min(low, p.Position.Y - p.Size.Y / 2)
			top = math.max(top, p.Position.Y + p.Size.Y / 2)
			sum += p.Position
		end
		local center = sum / #parts
		local s: Swayer = { Object = object, Pos = center, Base = {}, Pivot = CFrame.new(center.X, low, center.Z), Seed = (center.X * 0.137 + center.Z * 0.071) % 1, Tall = top - low }
		for _, p in parts do
			s.Base[p] = p.CFrame
		end
		swayers[object] = s
		table.insert(list, s)
	end
	for _, o in CollectionService:GetTagged("ReefSway") do
		register(o)
	end
	CollectionService:GetInstanceAddedSignal("ReefSway"):Connect(function(o)
		task.defer(register, o) -- (cuando ya tiene sus piezas dentro)
	end)
	CollectionService:GetInstanceRemovedSignal("ReefSway"):Connect(function(o)
		local s = swayers[o]
		swayers[o] = nil
		if s then
			local i = table.find(list, s)
			if i then
				table.remove(list, i)
			end
		end
	end)

	-- Cáusticas (solo si la textura está subida)
	local causticId: string? = nil
	pcall(function()
		local ids = require(ReplicatedStorage.Shared.Sea.MarAssetIds)
		local id = ids.Texturas and ids.Texturas.causticas
		if type(id) == "string" and string.match(id, "%d+") then
			local Images = require(ReplicatedStorage.Shared.Images)
			causticId = Images.map({ c = id }).c or id
		end
	end)
	local sheet: Part? = nil
	local texture: Texture? = nil
	if causticId then
		local p = Instance.new("Part")
		p.Name = "Causticas"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Transparency = 1
		p.Size = Vector3.new(70, 0.2, 70)
		local tx = Instance.new("Texture")
		tx.Texture = causticId
		tx.Face = Enum.NormalId.Top
		tx.StudsPerTileU = 18
		tx.StudsPerTileV = 18
		tx.Transparency = 0.55
		tx.Color3 = Color3.fromRGB(220, 250, 255)
		tx.Parent = p
		sheet, texture = p, tx
	end
	local floorParams = RaycastParams.new()
	floorParams.FilterType = Enum.RaycastFilterType.Include
	floorParams.IgnoreWater = true

	local active: { Swayer } = {}
	local pickAt = 0
	local clock = 0
	RunService.RenderStepped:Connect(function(dt: number)
		clock += dt
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local cam = camera.CFrame.Position
		local inZone = ReefZone.contains(cam.X, cam.Z) and cam.Y < ReefZone.Surface + 30
		-- Balanceo
		if clock - pickAt > 0.5 then
			pickAt = clock
			-- (las que dejan de moverse vuelven a su sitio)
			local keep = if inZone then ReefZoneFx.pickNearest(list, cam, maxSway, ReefZoneFx.SwayDistance) else {}
			local set = {}
			for _, s in keep do
				set[s] = true
			end
			for _, s in active do
				if not set[s] then
					for p, cf in s.Base do
						if p.Parent then
							p.CFrame = cf
						end
					end
				end
			end
			active = keep
		end
		-- (todas de una vez: BulkMoveTo es mucho más barato que una a una)
		local parts, frames = {}, {}
		for _, s in active do
			local a, b = ReefZoneFx.swayAngle(clock, s.Seed, s.Tall)
			local rot = s.Pivot * CFrame.Angles(b, 0, a) * s.Pivot:Inverse()
			for p, cf in s.Base do
				table.insert(parts, p)
				table.insert(frames, rot * cf)
			end
		end
		if #parts > 0 then
			workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
		end
		-- Haces de luz de día o de noche
		local hour = GameClock.hour()
		local day = math.clamp(1 - math.abs(hour - 13) / 7, 0, 1)
		local mar = workspace:FindFirstChild("Mar")
		local luz = mar and mar:FindFirstChild("CanonDorada") and mar.CanonDorada:FindFirstChild("Luz")
		if luz and inZone then
			for _, d in luz:GetChildren() do
				if d:IsA("BasePart") and d:GetAttribute("Haz") then
					d.Transparency = 0.985 - 0.075 * day
				end
			end
		end
		-- Cáusticas: a ras de un fondo llano bajo la cámara, con poca agua y de día
		if sheet and texture then
			local under = cam.Y < ReefZone.Surface
			local show = false
			if under and day > 0.2 then
				floorParams.FilterDescendantsInstances = { workspace.Terrain }
				local hit = workspace:Raycast(cam, Vector3.new(0, -60, 0), floorParams)
				if hit and hit.Normal.Y > 0.93 and ReefZone.Surface - hit.Position.Y < ReefZoneFx.CausticDepth then
					show = true
					sheet.CFrame = CFrame.new(hit.Position.X, hit.Position.Y + 0.12, hit.Position.Z)
					texture.OffsetStudsU = (clock * 1.3) % 18
					texture.OffsetStudsV = (clock * 0.8 + math.sin(clock * 0.4) * 2) % 18
					texture.Transparency = 0.85 - 0.3 * day
				end
			end
			sheet.Parent = if show then workspace else nil
		end
	end)
end

return ReefZoneFx
