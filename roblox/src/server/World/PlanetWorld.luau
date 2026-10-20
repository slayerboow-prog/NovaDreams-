-- PlanetWorld (servidor): construye la superficie de Tefra (shared/Cosmos/Tefra) y prepara los
-- cielos y materiales del espacio (shared/Cosmos/EspacioLook). docs/planetas.md.
--
--   * PlanetWorld.setupLooks(): al arrancar (barato): Sky «EspacioProfundo» y «CieloTefra» en
--     ReplicatedStorage.SkyLibrary si sus 6 caras están subidas; MaterialVariant «NaveCasco» y
--     «TefraRoca» (en un servidor de verdad solo si scripts/build-place.luau ya los dejó en el archivo);
--     y el color de los materiales del terreno de Tefra (Limestone, Sandstone, Slate, Basalt, Salt y
--     CrackedLava: el terreno de Valmar no los usa, así que la ciudad no cambia).
--   * PlanetWorld.ensure(): la PRIMERA vez que alguien se acerca a Tefra (o baja), en un hilo aparte
--     y poco a poco (para que el servidor no se trabe): el terreno por trozos de 64 studs
--     (Terrain:WriteVoxels con ocupación: colinas suaves, no escalones; lagos con agua), la plataforma
--     de aterrizaje, los puntos de interés (baliza, ruinas, restos de nave), el mineral y la flora.
--     Todo en workspace.Planetas.Tefra; el streaming (StreamingEnabled) solo lo manda a quien está
--     cerca: desde Valmar no llega nada.
--   * Bastión Ceniza, la ciudad (World/TefraCityBuilder, plano en shared/Cosmos/TefraCity): calles,
--     edificios, muralla, foso y canales de lava alrededor de la plataforma. Se construye con el resto
--     (PlanetWorld.buildCity, poco a poco); sus avisos «Mirar» son del tipo "City".
--   * PlanetWorld.park(player, cf) / unpark(player): la nave aparcada cuando te bajas («Subir a la nave»).
--   * Los avisos (ProximityPrompt) los conecta Services/PlanetService con PlanetWorld.prompts().
--   * (marco común de los planetas, docs/planetas/marco-planetas.md) Los DEMÁS planetas jugables
--     (shared/Cosmos/PlanetRegistry): PlanetWorld.ensure(id) construye, la primera vez que alguien se
--     acerca, su terreno (PlanetWorld.chunk con su superficie), su plataforma, sus puntos de interés,
--     su mineral, su flora (el kit del planeta la dibuja: World/<S.Kit>) y su barrio (World/
--     PlanetCityBuilder). Todo en workspace.Planetas.<id>. Sin id (o "Tefra"), lo de siempre.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tefra = require(ReplicatedStorage.Shared.Cosmos.Tefra)
local EspacioLook = require(ReplicatedStorage.Shared.Cosmos.EspacioLook)
local EspacioTextureIds = require(ReplicatedStorage.Shared.Cosmos.EspacioTextureIds)
local Mining = require(ReplicatedStorage.Shared.Cosmos.Mining)
local ShipModel = require(ReplicatedStorage.Shared.AirCombat.ShipModel)
local PlanetRegistry = require(ReplicatedStorage.Shared.Cosmos.PlanetRegistry)

local PlanetWorld = {}

PlanetWorld.Chunk = 64 -- studs por trozo de terreno
PlanetWorld.ChunksPerYield = 6
PlanetWorld.State = "None" -- "None" | "Building" | "Ready"

local rgb = Color3.fromRGB
-- (Tefra: los avisos de la vida de Bastión Ceniza —la Forja, el invernadero, el pan de sirena—, que lleva
-- Services/TefraService)
-- (los demás planetas: "Gather" = recoger su material; "Planeta" = avisos propios de su servicio)
local prompts: { [string]: { ProximityPrompt } } = { Node = {}, Poi = {}, Ship = {}, City = {}, Tefra = {}, Gather = {}, Planeta = {} }
PlanetWorld.States = {} :: { [string]: string } -- (los demás planetas) "Building" | "Ready"
PlanetWorld.CityStatsById = {} :: { [string]: { [string]: any } }
local nodeModels: { [string]: Model } = {}
local parked: { [Player]: Model } = {}
local listeners: { () -> () } = {}

local function images(): { [string]: string }
	local ok, map = pcall(function()
		return require(ReplicatedStorage.Shared.Images).map(EspacioTextureIds)
	end)
	return if ok and type(map) == "table" then map else EspacioTextureIds
end

---------------------------------------------------------------------
-- Cielos, materiales y colores (al arrancar)
---------------------------------------------------------------------
function PlanetWorld.setupLooks(): { string }
	local done = {}
	local ids = images()
	-- Cielos
	pcall(function()
		local library = ReplicatedStorage:FindFirstChild("SkyLibrary")
		if not library then
			library = Instance.new("Folder")
			library.Name = "SkyLibrary"
			library.Parent = ReplicatedStorage
		end
		-- (si ya estaba —PlanetService lo crea al arrancar, ANTES de que Images.resolve pase los Decal a
		-- imagen—, se le ponen las caras nuevas: antes se quedaba con los ids de Decal, que no pintan nada,
		-- y en el espacio salía el cielo azul de serie de Roblox: captura del dueño en v120)
		for name, prefix in EspacioLook.Skies do
			local faces = EspacioLook.skyFaces(ids, prefix)
			if faces then
				local found = library:FindFirstChild(name)
				local fresh = not (found and found:IsA("Sky"))
				local sky: any = if fresh then Instance.new("Sky") else found
				local changed = fresh
				for prop, id in faces do
					local okRead, now = pcall(function()
						return tostring(sky[prop])
					end)
					if fresh or not okRead or now ~= id then
						sky[prop] = id
						changed = true
					end
				end
				if fresh then
					sky.Name = name
					sky.StarCount = 0
					sky.Parent = library
				end
				if changed then
					table.insert(done, name)
				end
			end
		end
	end)
	-- MaterialVariant (sin sustituir el material en todo el juego)
	pcall(function()
		local service = game:GetService("MaterialService")
		for name, def in EspacioLook.Variants do
			local maps = EspacioLook.variantMaps(ids, name)
			if maps then
				local existing = service:FindFirstChild(name)
				local variant: any = if existing and existing:IsA("MaterialVariant") then existing else Instance.new("MaterialVariant")
				local ok = pcall(function()
					variant.Name = name
					if variant.BaseMaterial ~= (Enum.Material :: any)[def.Base] then
						variant.BaseMaterial = (Enum.Material :: any)[def.Base]
					end
					variant.StudsPerTile = def.Studs
				end)
				if ok then
					pcall(function()
						variant.MaterialPattern = (Enum.MaterialPattern :: any)[def.Pattern]
					end)
					for prop, id in maps do
						pcall(function()
							if variant[prop] ~= id then
								variant[prop] = id
							end
						end)
					end
					variant.Parent = service
					table.insert(done, name)
				elseif not existing then
					variant:Destroy()
				end
			end
		end
	end)
	-- Colores del terreno de Tefra: YA NO aquí. El terreno es uno para todo el place y Tefra usa los
	-- mismos materiales que el fondo del mar de Valmar (Salt, Sandstone, Limestone, Slate, Basalt): pintarlo
	-- desde el servidor dejaba el mar de Valmar gris ceniza, «nieve» (capturas del dueño v123 y v124).
	-- Los pinta Controllers/TerrainPaletteClient en tu pantalla solo mientras estás en Tefra (shared/TerrainPalette).
	local _ = Tefra.TerrainColors
	return done
end

---------------------------------------------------------------------
-- Piezas
---------------------------------------------------------------------
local function part(props: { [string]: any }): BasePart
	local p = Instance.new(props.Class or "Part") :: BasePart
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		if k ~= "Class" and k ~= "Parent" and k ~= "Variant" then
			(p :: any)[k] = v
		end
	end
	if props.Variant then
		pcall(function()
			local service = game:GetService("MaterialService")
			if service:FindFirstChild(props.Variant) then
				p.MaterialVariant = props.Variant
			end
		end)
	end
	p.Parent = props.Parent
	return p
end

local function ball(parent: Instance, name: string, at: Vector3, size: number, color: Color3, material: Enum.Material, extra: { [string]: any }?): BasePart
	local props = { Name = name, Shape = Enum.PartType.Ball, Size = Vector3.one * size, CFrame = CFrame.new(at), Color = color, Material = material, Parent = parent, CastShadow = size > 6 }
	for k, v in extra or {} do
		props[k] = v
	end
	return part(props)
end

local function cylinder(parent: Instance, name: string, cf: CFrame, length: number, diameter: number, color: Color3, material: Enum.Material, extra: { [string]: any }?): BasePart
	-- (el eje del cilindro es X: lo ponemos de pie con el giro)
	local props = { Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(length, diameter, diameter), CFrame = cf * CFrame.Angles(0, 0, math.pi / 2), Color = color, Material = material, Parent = parent }
	for k, v in extra or {} do
		props[k] = v
	end
	return part(props)
end

local function prompt(parent: Instance, kind: string, id: string, action: string, object: string, hold: number?): ProximityPrompt
	local pp = Instance.new("ProximityPrompt")
	pp.Name = "Aviso"
	pp.ActionText = action
	pp.ObjectText = object
	pp.HoldDuration = hold or 0
	pp.MaxActivationDistance = 14
	pp.RequiresLineOfSight = false
	pp:SetAttribute("Kind", kind)
	pp:SetAttribute("Id", id)
	pp.Parent = parent
	table.insert(prompts[kind], pp)
	for _, fn in listeners do
		task.spawn(fn)
	end
	return pp
end

---------------------------------------------------------------------
-- El terreno
---------------------------------------------------------------------
local function materialEnum(name: string): Enum.Material
	return (Enum.Material :: any)[name] or Enum.Material.Limestone
end

-- Un trozo de terreno (x0, z0: esquina en el mundo, múltiplos de 4). surface = la superficie (sin ella, Tefra)
function PlanetWorld.chunk(terrain: any, x0: number, z0: number, size: number, surface: any?)
	local Tefra = surface or Tefra
	local n = size // 4
	local heights = table.create(n + 2)
	local minH, maxH = math.huge, -math.huge
	-- alturas en el centro de cada columna (y una de margen para la pendiente)
	for i = 0, n + 1 do
		local row = table.create(n + 2)
		for k = 0, n + 1 do
			local h = Tefra.heightAt(x0 + (i - 1) * 4 + 2, z0 + (k - 1) * 4 + 2)
			row[k + 1] = h
			if i >= 1 and i <= n and k >= 1 and k <= n then
				minH = math.min(minH, h)
				maxH = math.max(maxH, h)
			end
		end
		heights[i + 1] = row
	end
	local water = Tefra.Origin.Y + Tefra.WaterY
	local bottom = math.floor((math.min(minH, water) - 8) / 4) * 4
	local top = math.ceil((math.max(maxH, water) + 6) / 4) * 4
	-- lo de debajo, macizo
	local floor = Tefra.Origin.Y + Tefra.Floor
	if bottom > floor then
		terrain:FillBlock(CFrame.new(x0 + size / 2, (floor + bottom) / 2, z0 + size / 2), Vector3.new(size, bottom - floor, size), Enum.Material.Basalt)
	end
	local ny = (top - bottom) // 4
	local mats, occs = table.create(n), table.create(n)
	for i = 1, n do
		local mx, ox = table.create(ny), table.create(ny)
		for j = 1, ny do
			mx[j] = table.create(n)
			ox[j] = table.create(n)
		end
		for k = 1, n do
			local h = heights[i + 1][k + 1]
			local dx = (heights[i + 2][k + 1] - heights[i][k + 1]) / 8
			local dz = (heights[i + 1][k + 2] - heights[i + 1][k]) / 8
			local slope = math.sqrt(dx * dx + dz * dz)
			local x, z = x0 + (i - 1) * 4 + 2, z0 + (k - 1) * 4 + 2
			local m = materialEnum(Tefra.materialAt(x, z, h, slope))
			for j = 1, ny do
				local yc = bottom + (j - 1) * 4 + 2
				local occ = math.clamp((h - (yc - 2)) / 4, 0, 1)
				if occ > 0.02 then
					mx[j][k] = m
					ox[j][k] = occ
				elseif yc - 2 < water then
					mx[j][k] = Enum.Material.Water
					ox[j][k] = 1
				else
					mx[j][k] = Enum.Material.Air
					ox[j][k] = 0
				end
			end
		end
		mats[i], occs[i] = mx, ox
	end
	local region = Region3.new(Vector3.new(x0, bottom, z0), Vector3.new(x0 + size, top, z0 + size))
	terrain:WriteVoxels(region, 4, mats, occs)
end

local function buildTerrain(onProgress: ((number) -> ())?, surface: any?)
	local Tefra = surface or Tefra
	local terrain = workspace.Terrain
	local size = PlanetWorld.Chunk
	local half = Tefra.Half
	local x0 = Tefra.Origin.X - half
	local z0 = Tefra.Origin.Z - half
	local count = (2 * half) // size
	local done = 0
	-- (de dentro a fuera: lo de la plataforma primero)
	local order = {}
	for i = 0, count - 1 do
		for k = 0, count - 1 do
			table.insert(order, { i, k, math.max(math.abs(i - count / 2 + 0.5), math.abs(k - count / 2 + 0.5)) })
		end
	end
	table.sort(order, function(a, b)
		return a[3] < b[3]
	end)
	for _, c in order do
		local ok, err = pcall(PlanetWorld.chunk, terrain, x0 + c[1] * size, z0 + c[2] * size, size, surface)
		if not ok then
			warn("[PlanetWorld] terreno: " .. tostring(err))
			return
		end
		done += 1
		if done % PlanetWorld.ChunksPerYield == 0 then
			if onProgress then
				onProgress(done / #order)
			end
			task.wait()
		end
	end
end

---------------------------------------------------------------------
-- Lo de encima
---------------------------------------------------------------------
local function at(lx: number, lz: number, up: number?): Vector3
	local x, z = Tefra.Origin.X + lx, Tefra.Origin.Z + lz
	return Vector3.new(x, Tefra.heightAt(x, z) + (up or 0), z)
end

local function buildPad(folder: Instance)
	local model = Instance.new("Model")
	model.Name = "Plataforma"
	model.Parent = folder
	local p = Tefra.PoiById.Plataforma
	local y = Tefra.Origin.Y + Tefra.padY()
	local center = Vector3.new(Tefra.Origin.X + p.X, y, Tefra.Origin.Z + p.Z)
	local R = Tefra.PadRadius
	local base = cylinder(model, "Base", CFrame.new(center - Vector3.new(0, 2.5, 0)), 6, R * 2, rgb(150, 140, 150), Enum.Material.Concrete)
	cylinder(model, "Anillo", CFrame.new(center + Vector3.new(0, 0.55, 0)), 0.2, R * 1.4, rgb(255, 196, 90), Enum.Material.Neon, { Transparency = 0.2 })
	cylinder(model, "Centro", CFrame.new(center + Vector3.new(0, 0.6, 0)), 0.2, R * 1.3, rgb(150, 140, 150), Enum.Material.Concrete)
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		local q = center + Vector3.new(math.cos(a) * (R - 3), 0.8, math.sin(a) * (R - 3))
		ball(model, "Luz", q, 1.4, if k % 2 == 0 then rgb(255, 220, 140) else rgb(255, 120, 80), Enum.Material.Neon, { CanCollide = false, CastShadow = false })
	end
	model.PrimaryPart = base
	prompt(base, "Poi", "Plataforma", "Mirar", p.Name)
end

local function buildBeacon(folder: Instance)
	local model = Instance.new("Model")
	model.Name = "Baliza"
	model.Parent = folder
	local p = Tefra.PoiById.Baliza
	local base = at(p.X, p.Z)
	local foot = cylinder(model, "Pie", CFrame.new(base + Vector3.new(0, 1.5, 0)), 3, 12, rgb(80, 74, 84), Enum.Material.Metal)
	cylinder(model, "Mastil", CFrame.new(base + Vector3.new(0, 22, 0)), 40, 1.6, rgb(120, 116, 124), Enum.Material.Metal)
	ball(model, "Antena", base + Vector3.new(0, 43, 0), 3, rgb(255, 70, 70), Enum.Material.Neon, { CanCollide = false })
	local dish = ball(model, "Plato", base + Vector3.new(2.5, 32, 0), 7, rgb(170, 166, 176), Enum.Material.Metal)
	dish.Size = Vector3.new(7, 7, 7)
	local light = Instance.new("PointLight")
	light.Color = rgb(255, 80, 80)
	light.Range = 28
	light.Brightness = 3
	light.Parent = model:FindFirstChild("Antena")
	ball(model, "Caja", base + Vector3.new(-4, 2.5, 3), 4, rgb(70, 76, 66), Enum.Material.Metal)
	model.PrimaryPart = foot
	prompt(foot, "Poi", "Baliza", "Escuchar la señal", p.Name, 0.5)
end

local function buildRuins(folder: Instance)
	local model = Instance.new("Model")
	model.Name = "Ruinas"
	model.Parent = folder
	local p = Tefra.PoiById.Ruinas
	local wall, dark = rgb(196, 178, 184), rgb(60, 54, 58)
	local first: BasePart? = nil
	for i, d in { { 0, 0, 34 }, { 30, 22, 26 }, { -26, 24, 22 } } do
		local c = at(p.X + d[1], p.Z + d[2], -d[3] * 0.18)
		local dome = ball(model, "Cupula", c, d[3], wall, Enum.Material.Limestone)
		first = first or dome
		-- boquete quemado (una bola oscura que asoma: la cúpula está partida)
		ball(model, "Boquete", c + Vector3.new(d[3] * 0.3, d[3] * 0.32, -d[3] * 0.18), d[3] * 0.42, dark, Enum.Material.CrackedLava, { CanCollide = false })
		if i == 1 then
			ball(model, "Puerta", c + Vector3.new(0, -d[3] * 0.1, -d[3] * 0.47), d[3] * 0.32, rgb(40, 34, 38), Enum.Material.Slate, { CanCollide = false })
		end
	end
	-- Torre en espiral (sin terminar)
	local tbase = at(p.X - 6, p.Z - 34)
	for k = 0, 6 do
		local r = 9 - k * 0.9
		cylinder(model, "Torre", CFrame.new(tbase + Vector3.new(math.cos(k * 0.9) * 1.2, k * 5 + 2.5, math.sin(k * 0.9) * 1.2)) * CFrame.Angles(0, k * 0.35, 0), 5, r * 2, if k % 2 == 0 then wall else rgb(170, 150, 160), Enum.Material.Limestone)
	end
	-- Escombros redondeados y la bufanda en la viga
	local r = Tefra.rng(4242)
	for _ = 1, 10 do
		local q = at(p.X + (r() - 0.5) * 70, p.Z + (r() - 0.5) * 70)
		ball(model, "Escombro", q, 2 + r() * 4, if r() < 0.5 then wall else dark, Enum.Material.Limestone)
	end
	local beam = part({ Name = "Viga", Size = Vector3.new(16, 1.2, 1.2), CFrame = CFrame.new(at(p.X + 14, p.Z - 6, 3)) * CFrame.Angles(0, 0.4, 0.3), Color = rgb(90, 70, 60), Material = Enum.Material.Wood, Parent = model })
	part({ Name = "Bufanda", Size = Vector3.new(0.4, 4, 1.4), CFrame = beam.CFrame * CFrame.new(3, -2, 0), Color = rgb(220, 120, 140), Material = Enum.Material.Fabric, CanCollide = false, Parent = model })
	model.PrimaryPart = first
	prompt(first :: BasePart, "Poi", "Ruinas", "Examinar", p.Name, 0.5)
end

local function buildWreck(folder: Instance)
	local model = Instance.new("Model")
	model.Name = "Restos"
	model.Parent = folder
	local p = Tefra.PoiById.Restos
	local c = at(p.X, p.Z, 2)
	local hull = cylinder(model, "Casco", CFrame.new(c) * CFrame.Angles(0.15, 0.6, 1.2), 26, 7, rgb(70, 74, 64), Enum.Material.CorrodedMetal)
	part({ Name = "Ala", Class = "WedgePart", Size = Vector3.new(1, 9, 16), CFrame = CFrame.new(c + Vector3.new(9, 0.5, 6)) * CFrame.Angles(0.2, 1.1, 0.4), Color = rgb(64, 66, 58), Material = Enum.Material.CorrodedMetal, Parent = model })
	part({ Name = "Cola", Class = "WedgePart", Size = Vector3.new(1, 7, 8), CFrame = CFrame.new(c + Vector3.new(-12, 2, -5)) * CFrame.Angles(0.1, 0.3, -0.3), Color = rgb(64, 66, 58), Material = Enum.Material.CorrodedMetal, Parent = model })
	ball(model, "Quemado", c + Vector3.new(0, -2, 0), 18, rgb(40, 34, 34), Enum.Material.CrackedLava, { CanCollide = false })
	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "Humo"
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Rate = 3
	smoke.Lifetime = NumberRange.new(6, 9)
	smoke.Speed = NumberRange.new(4, 7)
	smoke.SpreadAngle = Vector2.new(12, 12)
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(1, 18) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
	smoke.Color = ColorSequence.new(rgb(70, 64, 66))
	smoke.Acceleration = Vector3.new(1.5, 2, 0)
	smoke.Parent = hull
	model.PrimaryPart = hull
	prompt(hull, "Poi", "Restos", "Revisar", p.Name, 0.5)
end

local NODE_LOOK = {
	Obsidiana = { Rock = rgb(110, 96, 112), Vein = rgb(214, 150, 230) },
	Hierro = { Rock = rgb(92, 84, 82), Vein = rgb(180, 160, 150) },
	Cobalto = { Rock = rgb(80, 82, 98), Vein = rgb(80, 140, 255) },
}

local function buildNode(folder: Instance, node: Tefra.Node)
	local model = Instance.new("Model")
	model.Name = "Nodo_" .. node.Id
	model:SetAttribute("NodeId", node.Id)
	model:SetAttribute("Ore", node.Ore)
	model.Parent = folder
	local look = NODE_LOOK[node.Ore] or NODE_LOOK.Hierro
	local r = Tefra.rng(#node.Id * 977 + math.floor(node.Pos.X))
	local base = ball(model, "Roca", node.Pos + Vector3.new(0, node.Radius * 0.3, 0), node.Radius * 2, look.Rock, Enum.Material.Basalt, { Variant = "TefraRoca" })
	if node.Ore == "Obsidiana" then
		for k = 1, 5 do
			local a = k / 5 * math.pi * 2 + r()
			local len = 4 + r() * 6
			part({
				Name = "Cristal",
				Size = Vector3.new(1.2 + r(), len, 1.2 + r()),
				CFrame = CFrame.new(node.Pos + Vector3.new(math.cos(a) * 1.6, node.Radius * 0.6 + len * 0.35, math.sin(a) * 1.6)) * CFrame.Angles(math.cos(a) * 0.45, a, math.sin(a) * 0.45),
				Color = look.Vein,
				Material = Enum.Material.Glass,
				Transparency = 0.15,
				Reflectance = 0.1,
				CanCollide = false,
				Parent = model,
			})
		end
	else
		for _ = 1, 3 do
			local d = Vector3.new(r() - 0.5, r() * 0.6 + 0.2, r() - 0.5).Unit
			ball(model, "Veta", base.Position + d * node.Radius * 0.9, 1.4 + r() * 1.2, look.Vein, Enum.Material.Neon, { CanCollide = false, CastShadow = false })
		end
	end
	model.PrimaryPart = base
	nodeModels[node.Id] = model
	prompt(base, "Node", node.Id, "Extraer", (Mining.Ores[node.Ore] or Mining.Ores.Hierro).Name, 1)
end

-- Un mineral vacío se apaga (sus vetas y cristales se ven grises) y vuelve a brillar al rellenarse
function PlanetWorld.setNodeLit(id: string, lit: boolean)
	local model = nodeModels[id]
	if not model then
		return
	end
	model:SetAttribute("Empty", not lit)
	local look = NODE_LOOK[model:GetAttribute("Ore") or "Hierro"] or NODE_LOOK.Hierro
	for _, d in model:GetChildren() do
		if d:IsA("BasePart") and (d.Name == "Cristal" or d.Name == "Veta") then
			d.Color = if lit then look.Vein else rgb(90, 86, 92)
			d.Material = if lit then (if d.Name == "Cristal" then Enum.Material.Glass else Enum.Material.Neon) else Enum.Material.Slate
		end
	end
	local pp = model.PrimaryPart and model.PrimaryPart:FindFirstChild("Aviso")
	if pp and pp:IsA("ProximityPrompt") then
		pp.Enabled = lit
	end
end

local function buildDecor(folder: Instance)
	local flora = Instance.new("Folder")
	flora.Name = "Flora"
	flora.Parent = folder
	for _, d in Tefra.decor("Pelusa") do
		local h = d.Size * 1.6
		cylinder(flora, "Tallo", CFrame.new(d.Pos + Vector3.new(0, h / 2, 0)), h, 0.35, rgb(120, 110, 118), Enum.Material.Wood, { CanCollide = false, CastShadow = false })
		ball(flora, "Pelusa", d.Pos + Vector3.new(0, h + d.Size * 0.3, 0), d.Size, if d.Roll < 0.5 then rgb(236, 226, 236) else rgb(214, 206, 214), Enum.Material.Fabric, { CanCollide = false })
	end
	for _, d in Tefra.decor("Arbusto") do
		local col = if d.Roll < 0.5 then rgb(122, 112, 130) else rgb(140, 124, 120)
		for k = 0, 2 do
			local a = d.Turn + k * 2.1
			ball(flora, "Arbusto", d.Pos + Vector3.new(math.cos(a) * d.Size * 0.35, d.Size * 0.3, math.sin(a) * d.Size * 0.35), d.Size * (0.7 + 0.15 * k), col, Enum.Material.Grass, { CanCollide = false })
		end
	end
	local rocks = Instance.new("Folder")
	rocks.Name = "Rocas"
	rocks.Parent = folder
	for _, d in Tefra.decor("Roca") do
		ball(rocks, "Roca", d.Pos + Vector3.new(0, d.Size * 0.15, 0), d.Size, if d.Roll < 0.6 then rgb(84, 76, 88) else rgb(120, 110, 120), Enum.Material.Basalt, { Variant = "TefraRoca" })
	end
end

---------------------------------------------------------------------
-- Construir (una vez)
---------------------------------------------------------------------
function PlanetWorld.folder(id: string?): Instance?
	local root = workspace:FindFirstChild("Planetas")
	return root and root:FindFirstChild(id or Tefra.Id)
end

-- (mundo volcánico) Lagos de lava que brillan y fumarolas que echan humo: decorado (no chocan ni dañan)
local function buildLava(folder: Instance)
	local model = Instance.new("Model")
	model.Name = "Volcanico"
	model.Parent = folder
	for i, pool in Tefra.LavaPools do
		local c = at(pool.X, pool.Z, 0.6)
		cylinder(model, "Lava", CFrame.new(c), 0.6, pool.R * 2, rgb(255, 110, 30), Enum.Material.Neon, { CanCollide = false, CastShadow = false })
		cylinder(model, "Costra", CFrame.new(c + Vector3.new(0, 0.2, 0)), 0.5, pool.R * 2.5, rgb(40, 24, 20), Enum.Material.CrackedLava, { CanCollide = false })
		if i <= 2 then
			local light = Instance.new("PointLight")
			light.Color = rgb(255, 120, 50)
			light.Range = 40
			light.Brightness = 2
			light.Parent = model:FindFirstChild("Lava")
		end
	end
	for _, v in Tefra.Vents do
		local base = ball(model, "Fumarola", at(v.X, v.Z, 1), 8, rgb(50, 36, 34), Enum.Material.CrackedLava, { CanCollide = false })
		local smoke = Instance.new("ParticleEmitter")
		smoke.Name = "Humo"
		smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
		smoke.Rate = 2
		smoke.Lifetime = NumberRange.new(8, 11)
		smoke.Speed = NumberRange.new(6, 9)
		smoke.SpreadAngle = Vector2.new(8, 8)
		smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 6), NumberSequenceKeypoint.new(1, 26) })
		smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) })
		smoke.Color = ColorSequence.new(rgb(90, 80, 82), rgb(60, 54, 58))
		smoke.Parent = base
		local ember = Instance.new("ParticleEmitter")
		ember.Name = "Brasas"
		ember.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		ember.Rate = 4
		ember.Lifetime = NumberRange.new(1.5, 2.5)
		ember.Speed = NumberRange.new(5, 10)
		ember.LightEmission = 1
		ember.Color = ColorSequence.new(rgb(255, 160, 60), rgb(255, 60, 20))
		ember.Size = NumberSequence.new(0.6, 0)
		ember.Parent = base
	end
end

-- La ciudad (una vez). yield: para ceder entre trozos (en el servidor, task.wait)
PlanetWorld.CityStats = nil :: { [string]: any }?
function PlanetWorld.buildCity(folder: Instance, yield: (() -> ())?): Instance?
	local existing = folder:FindFirstChild("Ciudad")
	if existing then
		return existing
	end
	local TefraCityBuilder = require(script.Parent.TefraCityBuilder)
	local model, stats = TefraCityBuilder.build(folder, prompt, { Yield = yield })
	PlanetWorld.CityStats = stats
	-- Zonas de paseo (gente andando: Services/CrowdService)
	pcall(function()
		local CrowdService = require(script.Parent.Parent.Services.CrowdService) :: any
		if CrowdService.addArea then
			for _, area in stats.Areas or {} do
				CrowdService.addArea(area, "Tefra")
			end
		end
	end)
	return model
end

function PlanetWorld.buildProps(): Instance
	local root = workspace:FindFirstChild("Planetas")
	if not root then
		root = Instance.new("Folder")
		root.Name = "Planetas"
		root.Parent = workspace
	end
	local existing = root:FindFirstChild(Tefra.Id)
	if existing then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = Tefra.Id
	folder.Parent = root
	local poi = Instance.new("Folder")
	poi.Name = "PuntosDeInteres"
	poi.Parent = folder
	buildPad(poi)
	buildBeacon(poi)
	buildRuins(poi)
	buildWreck(poi)
	local nodes = Instance.new("Folder")
	nodes.Name = "Mineral"
	nodes.Parent = folder
	for _, node in Tefra.nodes() do
		buildNode(nodes, node)
	end
	buildDecor(folder)
	buildLava(folder)
	return folder
end

function PlanetWorld.ensure(id: string?): string
	if id ~= nil and id ~= Tefra.Id then
		return PlanetWorld.ensurePlanet(id)
	end
	if PlanetWorld.State ~= "None" then
		return PlanetWorld.State
	end
	PlanetWorld.State = "Building"
	task.spawn(function()
		local t0 = os.clock()
		local ok, err = pcall(function()
			buildTerrain(nil)
			local folder = PlanetWorld.buildProps()
			PlanetWorld.buildCity(folder, function()
				task.wait()
			end)
		end)
		if not ok then
			warn("[PlanetWorld] " .. tostring(err))
		end
		PlanetWorld.State = "Ready"
		local stats = PlanetWorld.CityStats
		print(("[PlanetWorld] Tefra lista en %.1f s (Bastión Ceniza: %s piezas, %s edificios)"):format(os.clock() - t0, tostring(stats and stats.Parts), tostring(stats and stats.Buildings)))
	end)
	return PlanetWorld.State
end

---------------------------------------------------------------------
-- Los demás planetas (marco común: shared/Cosmos/PlanetRegistry)
---------------------------------------------------------------------
local function kitOf(S: any): any
	local ok, PlanetCityBuilder = pcall(require, script.Parent.PlanetCityBuilder)
	if ok then
		return PlanetCityBuilder.loadKit(S)
	end
	return {}
end

-- La plataforma de aterrizaje (el punto de interés con Pad = true)
local function genericPad(folder: Instance, S: any, kit: any)
	local p = nil
	for _, poi in S.POIs do
		if poi.Pad then
			p = poi
		end
	end
	if not p then
		return
	end
	local model = Instance.new("Model")
	model.Name = p.Id
	model.Parent = folder
	local colors = kit.Colors or {}
	local y = S.Origin.Y + S.padY()
	local center = Vector3.new(S.Origin.X + p.X, y, S.Origin.Z + p.Z)
	local R = S.PadRadius
	local base = cylinder(model, "Base", CFrame.new(center - Vector3.new(0, 2.5, 0)), 6, R * 2, colors.Pad or rgb(140, 140, 146), Enum.Material.Concrete)
	cylinder(model, "Anillo", CFrame.new(center + Vector3.new(0, 0.55, 0)), 0.2, R * 1.4, colors.PadRing or rgb(120, 220, 255), Enum.Material.Neon, { Transparency = 0.2 })
	cylinder(model, "Centro", CFrame.new(center + Vector3.new(0, 0.6, 0)), 0.2, R * 1.3, colors.Pad or rgb(140, 140, 146), Enum.Material.Concrete)
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		local q = center + Vector3.new(math.cos(a) * (R - 3), 0.8, math.sin(a) * (R - 3))
		ball(model, "Luz", q, 1.4, colors.PadLight or rgb(200, 240, 255), Enum.Material.Neon, { CanCollide = false, CastShadow = false })
	end
	model.PrimaryPart = base
	prompt(base, "Poi", p.Id, "Mirar", p.Name)
end

-- Un punto de interés (si el kit no lo dibuja: un mojón con su luz)
local function genericPoi(folder: Instance, S: any, kit: any, p: { [string]: any })
	local model = Instance.new("Model")
	model.Name = p.Id
	model.Parent = folder
	local at = Vector3.new(S.Origin.X + p.X, S.Origin.Y + S.poiY(p.Id), S.Origin.Z + p.Z)
	local main: BasePart? = nil
	if kit.poi then
		main = kit.poi(model, p, at)
	end
	if not main then
		local colors = kit.Colors or {}
		main = cylinder(model, "Mojon", CFrame.new(at + Vector3.new(0, 3, 0)), 6, 3, colors.Poi or rgb(110, 104, 100), Enum.Material.Slate)
		local glow = ball(model, "Luz", at + Vector3.new(0, 6.6, 0), 1.6, colors.PoiLight or rgb(255, 220, 140), Enum.Material.Neon, { CanCollide = false })
		local l = Instance.new("PointLight")
		l.Range = 18
		l.Color = glow.Color
		l.Parent = glow
	end
	model.PrimaryPart = main
	prompt(main :: BasePart, "Poi", p.Id, p.Action or "Examinar", p.Name, 0.5)
end

local function genericNode(folder: Instance, S: any, node: any)
	local model = Instance.new("Model")
	model.Name = "Nodo_" .. node.Id
	model:SetAttribute("NodeId", node.Id)
	model:SetAttribute("Ore", node.Ore)
	model.Parent = folder
	local look = NODE_LOOK[node.Ore] or { Rock = rgb(96, 92, 96), Vein = (Mining.Ores[node.Ore] or Mining.Ores.Hierro).Color }
	local r = S.rng(#node.Id * 977 + math.floor(node.Pos.X))
	local base = ball(model, "Roca", node.Pos + Vector3.new(0, node.Radius * 0.3, 0), node.Radius * 2, look.Rock, Enum.Material.Slate)
	for _ = 1, 3 do
		local d = Vector3.new(r() - 0.5, r() * 0.6 + 0.2, r() - 0.5).Unit
		ball(model, "Veta", base.Position + d * node.Radius * 0.9, 1.4 + r() * 1.2, look.Vein, Enum.Material.Neon, { CanCollide = false, CastShadow = false })
	end
	model.PrimaryPart = base
	nodeModels[node.Id] = model
	prompt(base, "Node", node.Id, "Extraer", (Mining.Ores[node.Ore] or Mining.Ores.Hierro).Name, 1)
end

-- Lo de encima del terreno de un planeta (una vez): plataforma, puntos, mineral, flora y lo del kit
function PlanetWorld.buildPlanetProps(id: string): Instance?
	local S = PlanetRegistry.get(id)
	if not S then
		return nil
	end
	local root = workspace:FindFirstChild("Planetas")
	if not root then
		root = Instance.new("Folder")
		root.Name = "Planetas"
		root.Parent = workspace
	end
	local existing = root:FindFirstChild(id)
	if existing then
		return existing
	end
	local kit = kitOf(S)
	local folder = Instance.new("Folder")
	folder.Name = id
	folder.Parent = root
	local poi = Instance.new("Folder")
	poi.Name = "PuntosDeInteres"
	poi.Parent = folder
	genericPad(poi, S, kit)
	for _, p in S.POIs do
		if not p.Pad then
			genericPoi(poi, S, kit, p)
		end
	end
	local nodes = Instance.new("Folder")
	nodes.Name = "Mineral"
	nodes.Parent = folder
	for _, node in S.nodes() do
		genericNode(nodes, S, node)
	end
	local flora = Instance.new("Folder")
	flora.Name = "Flora"
	flora.Parent = folder
	for kind in S.DecorCounts do
		for _, d in S.decor(kind) do
			if kit.decor then
				kit.decor(flora, d)
			else
				ball(flora, kind, d.Pos + Vector3.new(0, d.Size * 0.15, 0), d.Size, rgb(110, 104, 100), Enum.Material.Slate)
			end
		end
	end
	if kit.world then
		local ok, err = pcall(kit.world, folder, S)
		if not ok then
			warn("[PlanetWorld] " .. id .. " (kit.world): " .. tostring(err))
		end
	end
	return folder
end

-- El barrio de un planeta (una vez). yield: para ceder entre trozos
function PlanetWorld.buildPlanetCity(id: string, folder: Instance, yield: (() -> ())?): (Instance?, { [string]: any }?)
	local S = PlanetRegistry.get(id)
	if not S or not S.City then
		return nil, nil
	end
	local existing = folder:FindFirstChild("Ciudad")
	if existing then
		return existing, PlanetWorld.CityStatsById[id]
	end
	local PlanetCityBuilder = require(script.Parent.PlanetCityBuilder) :: any
	local model, stats = PlanetCityBuilder.build(folder, prompt, S, { Yield = yield })
	PlanetWorld.CityStatsById[id] = stats
	pcall(function()
		local CrowdService = require(script.Parent.Parent.Services.CrowdService) :: any
		if CrowdService.addArea then
			for _, area in stats.Areas or {} do
				CrowdService.addArea(area, id)
			end
		end
	end)
	return model, stats
end

-- Construye (una vez, poco a poco, en un hilo aparte) un planeta del registro
function PlanetWorld.ensurePlanet(id: string): string
	local state = PlanetWorld.States[id]
	if state then
		return state
	end
	local S = PlanetRegistry.get(id)
	if not S then
		return "None"
	end
	PlanetWorld.States[id] = "Building"
	task.spawn(function()
		local t0 = os.clock()
		local ok, err = pcall(function()
			buildTerrain(nil, S)
			local folder = PlanetWorld.buildPlanetProps(id)
			if folder then
				PlanetWorld.buildPlanetCity(id, folder, function()
					task.wait()
				end)
			end
		end)
		if not ok then
			warn("[PlanetWorld] " .. id .. ": " .. tostring(err))
		end
		PlanetWorld.States[id] = "Ready"
		local stats = PlanetWorld.CityStatsById[id]
		print(("[PlanetWorld] %s listo en %.1f s (%s: %s piezas, %s edificios)"):format(id, os.clock() - t0, S.City and S.City.Name or "-", tostring(stats and stats.Parts), tostring(stats and stats.Buildings)))
	end)
	return "Building"
end

-- (pruebas y kits) crear un aviso con el registro de PlanetWorld
PlanetWorld.prompt = prompt

-- Los avisos (para conectarlos en Services/PlanetService); onNew se llama cuando se crean más
function PlanetWorld.prompts(onNew: (() -> ())?): { [string]: { ProximityPrompt } }
	if onNew then
		table.insert(listeners, onNew)
	end
	return prompts
end

---------------------------------------------------------------------
-- La nave aparcada (al bajarte)
---------------------------------------------------------------------
function PlanetWorld.park(player: Player, cf: CFrame): Model
	PlanetWorld.unpark(player)
	local model = ShipModel.build("Caza", cf)
	model.Name = "NaveAparcada_" .. player.UserId
	model:SetAttribute("Owner", player.UserId)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and (d.Name == ShipModel.Gear or d.Name == ShipModel.GearPad) then
			d.Transparency = 0
		elseif d:IsA("Trail") then
			d.Enabled = false
		end
	end
	local folder = workspace:FindFirstChild("Planetas") or workspace
	model.Parent = folder
	local body = model:FindFirstChild("Fuselaje") or model.PrimaryPart
	local pp = prompt(body :: Instance, "Ship", tostring(player.UserId), "Subir a la nave", "Tu nave", 0)
	pp.MaxActivationDistance = 18
	parked[player] = model
	return model
end

function PlanetWorld.unpark(player: Player)
	local model = parked[player]
	parked[player] = nil
	if model then
		for _, pp in model:GetDescendants() do
			if pp:IsA("ProximityPrompt") then
				local list = prompts.Ship
				local i = table.find(list, pp)
				if i then
					table.remove(list, i)
				end
			end
		end
		model:Destroy()
	end
end

function PlanetWorld.parked(player: Player): Model?
	return parked[player]
end

return PlanetWorld
