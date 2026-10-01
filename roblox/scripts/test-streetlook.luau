-- Prueba de las calles realistas (shared/StreetLook, World/StreetDress) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):  lune run scripts/test-streetlook.luau
--
-- Los packs de mentira se montan con el contenido real de los docs (docs/assets-usuario.md y
-- docs/assets-usuario-3.md: mismos nombres y BaseMaterial), con scripts metidos dentro, y el road pack
-- con sus Decals (y el cartel de City 17 y el GAZ-Volga, que no se usan). Comprueba que:
--   * cada aspecto apunta a variants que existen en el doc, con su BaseMaterial, y que la pieza puede
--     llevar (mismo material o un cambio seguro); cada uno dice por qué
--   * la elección por tipo de calle: avenida, barrio, casco antiguo, campo; aceras de centro, barrio,
--     casco y campo; plazas
--   * en vivo: no se cambia el BaseMaterial de ningún variant (en un servidor real falla), las piezas
--     que cambian de material guardan su física, y no se tocan marcas viales, pasos de cebra, bordillos,
--     parches, tapas ni lo que no es de las calles
--   * tapas y señales: fuera de pasos de cebra y puertas, en la acera, sin choque salvo el poste, con
--     etiqueta (el nivel Bajo las esconde), sin scripts y sin nada prohibido del pack, con topes
--   * sin carga no se hace nada

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Enum, Color3, Instance, Vector3, CFrame = roblox.Enum, roblox.Color3, roblox.Instance, roblox.Vector3, roblox.CFrame
local V3 = Vector3.new

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local function load(path: string, env: { [string]: any }?): any
	local e = {
		Enum = Enum,
		Color3 = Color3,
		Instance = Instance,
		Vector3 = Vector3,
		CFrame = CFrame,
		PhysicalProperties = roblox.PhysicalProperties,
		warn = print,
		task = { wait = function() end },
	}
	for k, v in env or {} do
		e[k] = v
	end
	setmetatable(e, { __index = getfenv(1) })
	return luau.load(fs.readFile(path), { debugName = path, environment = e })()
end

local CityPlan = load("src/shared/CityPlan.luau")
local StreetLook = load("src/shared/StreetLook.luau", {
	script = { Parent = { CityPlan = "CityPlan" } },
	require = function()
		return CityPlan
	end,
})
local Choice = load("src/shared/UserMaterialChoice.luau")

---------------------------------------------------------------------
-- Los docs: id del pack -> { Name, Base }
---------------------------------------------------------------------
local doc: { [number]: { { Name: string, Base: string, Studs: number, Pattern: string } } } = {}
for _, path in { "docs/assets-usuario.md", "docs/assets-usuario-3.md" } do
	local current: number? = nil
	for line in fs.readFile(path):gmatch("[^\n]+") do
		local id = line:match("^## (%d+) ")
		if id then
			current = tonumber(id)
			doc[current :: number] = doc[current :: number] or {}
		elseif line:match("^## ") then
			current = nil
		elseif current then
			local name, base, studs, pattern = line:match("^| (.-) | (%a+) | ([%d%.]+) | (%a+) |$")
			if name then
				table.insert(doc[current], { Name = name, Base = base, Studs = tonumber(studs) :: number, Pattern = pattern })
			end
		end
	end
end
local packIds: { [string]: number } = { RPacks = StreetLook.Packs.Variants.Id }
for _, pack in Choice.Packs do
	packIds[pack.Short] = pack.Id
end

print("Los docs")
check(doc[13752145820] and #doc[13752145820] == 27 and doc[15221806045] and #doc[15221806045] == 524 and doc[92927007790601] and #doc[92927007790601] == 68, "se leen los packs (Realistic Packs 27, Mega 524, Tyler 68)")

print("Los aspectos")
do
	local okRefs, okBase, okUse, okNum = true, true, true, true
	for key, look in StreetLook.Looks do
		local material = StreetLook.SurfaceMaterial[look.Surface]
		check(#look.Candidates >= 2 and type(look.Why) == "string" and #look.Why > 8, ("%s: al menos un respaldo y su porqué (%s)"):format(key, look.Why))
		for _, cand in look.Candidates do
			local found = nil
			for _, v in doc[packIds[cand.Pack] or 0] or {} do
				if v.Name == cand.Name then
					found = v
					break
				end
			end
			if not found then
				okRefs = false
				print(("     %s: %s/%s no está en el doc"):format(key, cand.Pack, cand.Name))
			elseif found.Base ~= cand.From then
				okBase = false
				print(("     %s: %s/%s va sobre %s, no %s"):format(key, cand.Pack, cand.Name, found.Base, cand.From))
			end
			if not StreetLook.canUse(material, cand.From) then
				okUse = false
				print(("     %s: una pieza de %s no puede llevar un variant de %s"):format(key, material, cand.From))
			end
			if Choice.isBroken(cand.Pack, cand.Name) then
				okRefs = false
			end
		end
		if look.Whiten < 0 or look.Whiten > 1 or (look.Studs and (look.Studs < 4 or look.Studs > 30)) then
			okNum = false
		end
	end
	check(okRefs, "cada candidato existe en su doc (pack y nombre) y no es de los rotos")
	check(okBase, "cada candidato dice bien su BaseMaterial del doc")
	check(okUse, "solo variants con BaseMaterial compatible con la pieza (igual, o acera->Concrete, calzada->Cobblestone)")
	check(okNum, "Whiten 0..1 y StudsPerTile 4-30")
	check(not StreetLook.canUse("Asphalt", "Concrete") and not StreetLook.canUse("Pavement", "Asphalt") and StreetLook.canUse("Asphalt", "Asphalt"), "nada de cambios raros (asfalto->hormigón, acera->asfalto)")
	local names = { Avenida = "Asphalt", Barrio = "Pebbled Asphalt", Campo = "Rocky Asphalt", Casco = "Cobblestone Curved", AceraCentro = "Pavement2", AceraCasco = "Stone Tiles", AceraCampo = "Concrete Tile 1", Plaza = "Stone Tiles" }
	local ok = true
	for key, name in names do
		if StreetLook.Looks[key].Candidates[1].Name ~= name then
			ok = false
			print("     " .. key)
		end
	end
	check(ok, "lo más realista de cada tipo: Asphalt, Pebbled/Rocky Asphalt, Cobblestone Curved, Pavement2, Stone Tiles, Concrete Tile 1")
end

print("Elección por tipo de calle")
do
	local HW = { { Axis = "X", At = 0, From = -1205, To = 1205 }, { Axis = "Z", At = 0, From = -1205, To = 1205 } }
	local function cl(name, material, container, x, z, variant)
		return StreetLook.classify({ Name = name, Material = material, Container = container, X = x, Z = z, Variant = variant }, HW)
	end
	local sr, vv = CityPlan.Towns["San Roque"], CityPlan.Towns["Villaverde"]
	check(cl("Road", "Asphalt", "MainRoads", 0, -1250) == "Avenida" and cl("Junction", "Asphalt", "MainRoads", 1250, 0) == "Avenida" and cl("Road", "Asphalt", "MainRoads", -2000, 0) == "Avenida", "Ronda, rotondas y avenidas: asfalto nuevo")
	check(cl("Road", "Asphalt", "Streets", 600, 0) == "Avenida" and cl("Road", "Asphalt", "Streets", 0, -700) == "Avenida", "las dos calles grandes del centro: asfalto nuevo")
	check(cl("Road", "Asphalt", "Streets", -700, -1900 + 240) == "Barrio" and cl("Road", "Asphalt", "Streets", 600, 600) == "Barrio", "calles de barrio: asfalto gastado")
	check(cl("Road", "Asphalt", "Streets", sr[1] + 240, sr[2]) == "Casco" and cl("Road", "Asphalt", "Streets", vv[1], vv[2] - 240) == "Casco", "San Roque y Villaverde: adoquín")
	check(cl("Road", "Asphalt", "MainRoads", sr[1] + 200, sr[2]) ~= "Casco", "las carreteras principales que llegan al casco siguen de asfalto")
	check(cl("Road", "Asphalt", "MainRoads", -3540, -600) == "Campo" and cl("Road", "Asphalt", "Streets", -3200, 1500) == "Campo", "afueras y campo: asfalto viejo")
	check(cl("Sidewalk", "Pavement", "Streets", 100, 100) == "AceraCentro" and cl("Sidewalk", "Pavement", "MainRoads", 3000, -1000) == "AceraCentro", "aceras del centro y del Este: baldosa")
	check(cl("Sidewalk", "Pavement", "Streets", -700, -1700) == "AceraBarrio" and cl("RingSidewalk", "Pavement", "MainRoads", 0, -2750) == "AceraBarrio", "aceras de barrio")
	check(cl("Sidewalk", "Pavement", "Streets", sr[1], sr[2] + 20) == "AceraCasco" and cl("KerbRamp", "Pavement", "Streets", sr[1], sr[2] + 20) == "AceraCasco", "aceras y rampas del casco: losas")
	check(cl("Sidewalk", "Pavement", "MainRoads", -3540, -600) == "AceraCampo", "aceras del campo: hormigón")
	check(cl("PlazaFloor", "Pavement", nil, 0, -60) == "Plaza" and cl("Plaza", "Pavement", "Distrito", 500, 500) == "Plaza", "plazas: losas de piedra")
	local untouched = true
	for _, n in { "Marking", "Zebra", "Curb", "RoadKerb", "RingCurb", "IslandCurb", "AsphaltPatch", "Manhole", "Drain", "Median", "BusLaneMark", "StopLine", "TreePit" } do
		if cl(n, "Asphalt", "Streets", 600, 600) or cl(n, "SmoothPlastic", "Streets", 600, 600) or cl(n, "Concrete", "Streets", 600, 600) then
			untouched = false
		end
	end
	check(untouched, "marcas viales, pasos de cebra, bordillos, parches, tapas y medianas: nunca")
	check(cl("Road", "Asphalt", "Streets", 600, 600, "PinturaVial") == nil and cl("Road", "SmoothPlastic", "Streets", 600, 600) == nil, "lo que ya lleva variant o no es del material esperado: no")
	check(cl("Road", "Asphalt", "Airport", 600, 600) == nil and cl("Sidewalk", "Pavement", nil, 600, 600) == nil, "calzadas y aceras fuera de las calles (aeropuerto, parcelas): no")
end

---------------------------------------------------------------------
-- Packs de mentira y módulos del servidor
---------------------------------------------------------------------
local function fakeVariantPack(id: number): any
	local model = Instance.new("Model")
	local folder = Instance.new("Folder")
	folder.Parent = model
	for _, v in doc[id] do
		local mv = Instance.new("MaterialVariant")
		mv.Name = v.Name
		mv.BaseMaterial = (Enum.Material :: any)[v.Base]
		mv.StudsPerTile = v.Studs
		mv.MaterialPattern = (Enum.MaterialPattern :: any)[v.Pattern]
		mv.Parent = folder
	end
	local s = Instance.new("Script")
	s.Parent = folder
	return model
end

local function fakeRoadPack(): any
	local model = Instance.new("Model")
	local function plate(name: string, id: number)
		local p = Instance.new("Part")
		p.Name = name
		p.Parent = model
		local d = Instance.new("Decal")
		d.Texture = "rbxassetid://" .. id
		d.Parent = p
		local s = Instance.new("LocalScript")
		s.Parent = p
		return p
	end
	-- (en el pack, la imagen del STOP también está en el cartel prohibido: no se usa esa)
	local bill = Instance.new("Model")
	bill.Name = "c17billboardxccr"
	bill.Parent = model
	local bp = plate("Board", 8612134288)
	bp.Parent = bill
	for kind, id in StreetLook.Decals do
		plate("Sign" .. kind, id)
	end
	local volga = Instance.new("Model")
	volga.Name = "GAZ-Volga"
	volga.Parent = model
	local sc = Instance.new("Script")
	sc.Parent = volga
	return model
end

local function newModules(): (any, any, any)
	local service = Instance.new("MaterialService")
	local storage = Instance.new("Folder")
	local shared = { UserMaterialChoice = Choice, StreetLook = StreetLook, Textures = {}, TextureIds = {} }
	local fakeGame = {
		GetService = function(_, name)
			if name == "ReplicatedStorage" then
				return { Shared = shared }
			elseif name == "MaterialService" then
				return service
			elseif name == "ServerStorage" then
				return storage
			end
			return {}
		end,
	}
	local env = { game = fakeGame, workspace = { DescendantAdded = { Connect = function() end }, Terrain = Instance.new("Terrain"), GetDescendants = function()
		return {}
	end }, require = function(x)
		return x
	end }
	local UserMaterials = load("src/server/World/UserMaterials.luau", env)
	local StreetDress = load("src/server/World/StreetDress.luau", env)
	return UserMaterials, StreetDress, { service = service, storage = storage }
end

local function part(parent: any, name: string, material: string, pos: any, color: any?, size: any?): any
	local p = Instance.new("Part")
	p.Name = name
	p.Material = (Enum.Material :: any)[material]
	p.Color = color or Color3.fromRGB(46, 48, 53)
	p.Size = size or V3(4, 1, 4)
	p.CFrame = CFrame.new(pos)
	p.Parent = parent
	return p
end

local function folder(parent: any, name: string, class: string?): any
	local f = Instance.new(class or "Model")
	f.Name = name
	f.Parent = parent
	return f
end

-- Paso de cebra como los de Kit/Bocacalles (a lo largo de X): centro, largo, ancho
local function zebra(parent: any, c: any, length: number, depth: number): any
	local m = folder(parent, "PasoCebra")
	for _, s in { -1, 1 } do
		local r = part(m, "KerbRamp", "Pavement", c + V3(s * (length / 2 - 0.8), 0.7, 0), Color3.fromRGB(196, 192, 184), V3(depth, 0.6, 1.6))
		r.Color = Color3.fromRGB(196, 192, 184)
	end
	local x0, x1 = -length / 2 + 2.5, length / 2 - 2.5
	local count = math.floor((x1 - x0 + 1.3) / 2.5)
	for k = 0, count - 1 do
		local z = part(m, "Zebra", "SmoothPlastic", c + V3(x0 + 0.55 + k * (x1 - x0 - 1.1) / (count - 1), 0.43, 0), Color3.fromRGB(236, 236, 230), V3(1.1, 0.05, depth))
		z.MaterialVariant = "PinturaVial"
	end
	return m
end

-- Ciudad de mentira: bocas en el Distrito Norte (z = -1700) y una en San Roque, tapas y piezas
local NORTE_Z = -1700
local MOUTHS = {}
for i = 0, 69 do
	table.insert(MOUTHS, V3(-1190 + i * 34, 0, NORTE_Z + 17.5))
end
local SR = CityPlan.Towns["San Roque"]
local SR_MOUTH = V3(SR[1] + 120, 0, SR[2] + 17.5)
table.insert(MOUTHS, SR_MOUTH)
local DOOR_MOUTH = MOUTHS[5]

local function buildTown(): any
	local town = folder(nil, "Town", "Folder")
	local streets = folder(town, "Streets")
	local main = folder(town, "MainRoads")
	local pasos = folder(main, "PasosBocacalle")
	local w = {
		town = town,
		roadBarrio = part(streets, "Road", "Asphalt", V3(-700, 0, -1660)),
		roadCasco = part(streets, "Road", "Asphalt", V3(SR[1] + 240, 0, SR[2])),
		roadCampo = part(streets, "Road", "Asphalt", V3(-3200, 0, 1500)),
		roadAv = part(main, "Road", "Asphalt", V3(0, 0, -1250)),
		junction = part(main, "Junction", "Asphalt", V3(1250, 0, 0)),
		walkCentro = part(streets, "Sidewalk", "Pavement", V3(100, 0.5, 100), Color3.fromRGB(196, 192, 184)),
		walkBarrio = part(streets, "Sidewalk", "Pavement", V3(-700, 0.5, -1700), Color3.fromRGB(196, 192, 184)),
		walkCasco = part(streets, "Sidewalk", "Pavement", V3(SR[1], 0.5, SR[2] + 20), Color3.fromRGB(196, 192, 184)),
		walkCampo = part(main, "Sidewalk", "Pavement", V3(-3540, 0.5, -600), Color3.fromRGB(196, 192, 184)),
		plaza = part(town, "PlazaFloor", "Pavement", V3(0, 0.5, -60), Color3.fromRGB(214, 202, 182)),
		marking = part(streets, "Marking", "SmoothPlastic", V3(600, 0.42, 600), Color3.fromRGB(236, 236, 230)),
		curb = part(streets, "Curb", "Granite", V3(600, 0.7, 612), Color3.fromRGB(214, 211, 204)),
		patch = part(streets, "AsphaltPatch", "Asphalt", V3(600, 0.41, 600)),
		airport = part(folder(town, "Aeropuerto"), "Road", "Asphalt", V3(-2850, 0, 3200)),
	}
	w.marking.MaterialVariant = "PinturaVial"
	w.curb.MaterialVariant = "Bordillo"
	-- Pasos de cebra de las bocas (calle principal a lo largo de X; la de barrio sale hacia +Z)
	for _, c in MOUTHS do
		zebra(pasos, c, 24, 6)
	end
	-- Un paso de cruce de barrio (con semáforo): no lleva STOP
	zebra(streets, V3(600, 0, 640), 24, 7)
	-- Puerta junto a la boca 5 (en la acera de la calle de barrio)
	part(folder(town, "Casa"), "Door", "Wood", DOOR_MOUTH + V3(-13, 3, 21))
	-- Tapas y rejillas: muchas (tope), una dentro de un paso de cebra, y un desagüe de un interior
	local det = folder(streets, "Detalles")
	for i = 1, 300 do
		local m = part(det, "Manhole", "DiamondPlate", V3(-1000 + i * 7, 0.43, NORTE_Z - 300), Color3.fromRGB(44, 44, 46), V3(0.06, 2.6, 2.6))
		m.Shape = Enum.PartType.Cylinder
		m.CFrame = CFrame.new(m.Position) * CFrame.Angles(0, 0, math.rad(90))
	end
	for i = 1, 150 do
		part(det, "Drain", "DiamondPlate", V3(-1000 + i * 9, 0.43, NORTE_Z - 320), Color3.fromRGB(40, 40, 42), V3(1, 0.06, 2.4))
	end
	w.zebraManhole = part(det, "Manhole", "DiamondPlate", MOUTHS[3] + V3(0, 0.43, 0), Color3.fromRGB(44, 44, 46), V3(0.06, 2.6, 2.6))
	w.interiorDrain = part(folder(town, "Interior"), "Drain", "Metal", V3(50, 10, 50), Color3.new(1, 1, 1), V3(0.5, 0.26, 0.5))
	return w
end

-- Qué acera hay en p (en la ciudad de mentira): la de la calle de barrio (fuera de la boca, más allá
-- de la acera de la principal) o la de la principal (fuera de la boca)
local function probe(p: any): (string?, number?)
	for _, c in MOUTHS do
		local dx, dz = p.X - c.X, p.Z - (c.Z - 17.5)
		if math.abs(dx) < 30 then
			if dz > 21 and dz < 60 and math.abs(dx) >= 12 and math.abs(dx) <= 20 then
				return "Streets", 1
			elseif dz >= 14 and dz <= 21 and math.abs(dx) > 12 then
				return "MainRoads", 1
			end
		end
	end
	return nil
end

local function allVariants(service: any, storage: any): { [any]: any }
	local out = {}
	for _, item in service:GetDescendants() do
		if item:IsA("MaterialVariant") then
			out[item] = item.BaseMaterial
		end
	end
	for _, item in storage:GetDescendants() do
		if item:IsA("MaterialVariant") then
			out[item] = item.BaseMaterial
		end
	end
	return out
end

print("Sin carga no se hace nada")
do
	local UserMaterials, StreetDress, w = newModules()
	local t = buildTown()
	local called = false
	UserMaterials.start(function()
		return nil
	end, function()
		called = true
	end)
	check(not called, "si no carga ningún pack de materiales, las calles ni se miran")
	StreetDress.start(w.service, w.storage, function()
		return nil
	end, UserMaterials.unpack, t.town, nil, probe)
	local untouched = t.roadBarrio.MaterialVariant == "" and t.walkCentro.MaterialVariant == "" and t.roadBarrio.Color == Color3.fromRGB(46, 48, 53) and t.town:FindFirstChild("SenalesTrafico") == nil
	check(untouched and #w.service:GetChildren() == 0, "sin packs: ni variants, ni piezas, ni señales")
end

print("Con todos los packs")
do
	local UserMaterials, StreetDress, w = newModules()
	local t = buildTown()
	local loads = {}
	local function loader(id: number): any
		loads[id] = true
		if id == StreetLook.Packs.Road.Id then
			return fakeRoadPack()
		elseif doc[id] and #doc[id] > 0 then
			return fakeVariantPack(id)
		end
		return nil
	end
	-- Como en el servidor: los packs de materiales y luego las calles
	local loaded = {}
	for _, pack in Choice.Packs do
		local a = loader(pack.Id)
		if a then
			loaded[pack.Short] = UserMaterials.unpack(a, pack.Short, w.storage)
		end
	end
	UserMaterials.apply(w.service, w.storage, loaded)
	local before = allVariants(w.service, w.storage)
	local HW = { { Axis = "X", At = 0, From = -1205, To = 1205 }, { Axis = "Z", At = 0, From = -1205, To = 1205 } }
	StreetDress.start(w.service, w.storage, loader, UserMaterials.unpack, t.town, HW, probe)
	check(loads[13752145820] and loads[15004077857], "carga también Realistic Packs y el road pack")
	local after = allVariants(w.service, w.storage)
	local same = true
	for v, base in after do
		if before[v] ~= nil and before[v] ~= base then
			same = false
		end
	end
	check(same, "no cambia el BaseMaterial de ningún variant (en un servidor real falla)")
	local function variantOf(p: any): any
		return w.service:FindFirstChild(p.MaterialVariant)
	end
	local function is(p: any, pack: string, name: string): boolean
		local v = variantOf(p)
		return v ~= nil and v:GetAttribute("SourcePack") == pack and v:GetAttribute("SourceName") == name and v.BaseMaterial == p.Material
	end
	check(is(t.roadAv, "Real", "Asphalt") and is(t.junction, "Real", "Asphalt"), "avenida y rotonda: Asphalt del pack de piedras")
	check(is(t.roadBarrio, "Mega", "Pebbled Asphalt") and is(t.roadCampo, "Mega", "Rocky Asphalt"), "barrio: Pebbled Asphalt; campo: Rocky Asphalt")
	check(is(t.roadCasco, "Mega", "Cobblestone Curved") and t.roadCasco.Material == Enum.Material.Cobblestone, "casco: Cobblestone Curved (la calzada pasa a Cobblestone)")
	local phys = t.roadCasco.CustomPhysicalProperties
	local asphalt = roblox.PhysicalProperties.new(Enum.Material.Asphalt)
	check(phys and math.abs(phys.Friction - asphalt.Friction) < 1e-3 and math.abs(phys.Density - asphalt.Density) < 1e-3, "el adoquín guarda la física del asfalto (los coches agarran igual)")
	check(is(t.walkCentro, "Tyler", "Pavement2") and t.walkCentro.Material == Enum.Material.Concrete and t.walkCentro.CustomPhysicalProperties ~= nil, "acera del centro: Pavement2 de Tyler (pasa a Concrete con la física de Pavement)")
	check(is(t.walkBarrio, "Tyler", "Pavement3") and is(t.walkCasco, "Mega", "Stone Tiles") and is(t.walkCampo, "RPacks", "Concrete Tile 1") and is(t.plaza, "Mega", "Stone Tiles"), "aceras de barrio, casco y campo, y la plaza")
	check(t.roadBarrio.Color.R > 0.6 and t.roadAv.Color.R < t.roadBarrio.Color.R and t.roadCampo.Color.R > t.roadBarrio.Color.R, "aclaradas según su aspecto: la avenida más oscura, el campo más claro")
	check(w.service:GetAttribute("UserOverride_Asphalt") == "U_Real_Asphalt" and w.service.AsphaltName == "U_Real_Asphalt", "el asfalto global sigue siendo el del dueño")
	local pebbled = w.service:FindFirstChild("U_Mega_PebbledAsphalt")
	check(pebbled and pebbled.StudsPerTile == 14 and pebbled.MaterialPattern == Enum.MaterialPattern.Organic and w.service.U_Real_Asphalt.StudsPerTile == 17, "escala y patrón solo en los variants que son solo de las calles (el global no cambia)")
	check(t.marking.MaterialVariant == "PinturaVial" and t.marking.Material == Enum.Material.SmoothPlastic and t.curb.MaterialVariant == "Bordillo" and t.patch.MaterialVariant == "" and t.patch.Color == Color3.fromRGB(46, 48, 53), "marcas viales, bordillos y parches sin tocar")
	local zebraOk = true
	for _, d in t.town:GetDescendants() do
		if d.Name == "Zebra" and (d.MaterialVariant ~= "PinturaVial" or d.Material ~= Enum.Material.SmoothPlastic) then
			zebraOk = false
		end
	end
	check(zebraOk, "pasos de cebra sin tocar")
	check(t.airport.MaterialVariant == "" and t.interiorDrain:GetChildren()[1] == nil, "lo que no es de las calles (aeropuerto, desagüe de un interior) no se toca")

	-- Detalles
	local signs = t.town:FindFirstChild("SenalesTrafico")
	check(signs ~= nil, "las señales y tapas van en Town.SenalesTrafico")
	local scripts = 0
	for _, d in t.town:GetDescendants() do
		if d:IsA("LuaSourceContainer") then
			scripts += 1
		end
	end
	for _, d in w.storage:GetDescendants() do
		if d:IsA("LuaSourceContainer") then
			scripts += 1
		end
	end
	check(scripts == 0, "ningún script de los packs en la ciudad ni en la biblioteca")
	local counts, crossings = {}, {}
	for _, m in t.town:GetDescendants() do
		if m.Name == "PasoCebra" then
			table.insert(crossings, StreetDress.crossingOf(m))
		end
	end
	local okPlace, okCollide, okTags, okDecals, okDoor, okBanned = true, true, true, true, true, true
	local zebraPlate = false
	for _, item in (signs and signs:GetChildren() or {}) do
		if item:IsA("Model") then
			local kind = item.Name:sub(6)
			counts[kind] = (counts[kind] or 0) + 1
			local pole = item:FindFirstChild("SignPole")
			if not pole then
				okPlace = false
			else
				local p = pole.Position
				if StreetLook.inCrossing(p, crossings, 0.5) or not probe(p) then
					okPlace = false
				end
				if (p - (DOOR_MOUTH + V3(-13, 0, 21))).Magnitude < 6 then
					okDoor = false
				end
			end
			for _, d in item:GetDescendants() do
				if d:IsA("BasePart") then
					if d.CanCollide ~= (d.Name == "SignPole") or d.CanTouch then
						okCollide = false
					end
					if not d:HasTag("StreetSign") then
						okTags = false
					end
				end
			end
			local face = item:FindFirstChild("SignFace")
			local dec = face and face:FindFirstChildWhichIsA("Decal")
			if not dec or StreetLook.decalKind(dec.Texture) ~= kind or dec.Face ~= Enum.NormalId.Front then
				okDecals = false
			end
		elseif item:IsA("BasePart") then
			local kind = if item.Name == "TapaAlcantarilla" then "Manhole" else "Drain"
			counts[kind] = (counts[kind] or 0) + 1
			local dec = item:FindFirstChildWhichIsA("Decal")
			if not dec or StreetLook.decalKind(dec.Texture) ~= kind or dec.Face ~= Enum.NormalId.Top or item.CanCollide or item.CanQuery or not item:HasTag("CityDetail") then
				okDecals = false
			end
			if StreetLook.inCrossing(item.Position, crossings, 0) then
				zebraPlate = true
			end
		end
		for _, d in item:GetDescendants() do
			if d:IsA("Decal") and d.Texture:find("8612133612", 1, true) then
				okBanned = false
			end
		end
	end
	print(("     tapas %d, rejillas %d, STOP %d, peatones %d, 30 %d, 20 %d"):format(counts.Manhole or 0, counts.Drain or 0, counts.Stop or 0, counts.Peatones or 0, counts.Velocidad30 or 0, counts.Velocidad20 or 0))
	check(counts.Manhole == StreetLook.Caps.Manhole and counts.Drain == StreetLook.Caps.Drain, ("topes de tapas (%d) y rejillas (%d), con 300 y 150 en la calle"):format(StreetLook.Caps.Manhole, StreetLook.Caps.Drain))
	check(not zebraPlate, "ninguna tapa dentro de un paso de cebra")
	check((counts.Stop or 0) == StreetLook.Caps.Stop and (counts.Peatones or 0) == StreetLook.Caps.Peatones and (counts.Velocidad30 or 0) + (counts.Velocidad20 or 0) <= StreetLook.Caps.Velocidad and (counts.Velocidad30 or 0) > 0, ("topes de señales con 71 bocas: STOP %d, peatones %d, velocidad ≤ %d"):format(StreetLook.Caps.Stop, StreetLook.Caps.Peatones, StreetLook.Caps.Velocidad))
	check(okPlace, "cada señal en una acera y fuera de los pasos de cebra")
	check(okDoor, "ninguna señal delante de la puerta")
	check(okCollide, "solo choca el poste (placa, respaldo y tapas sin colisión ni toques)")
	check(okTags, "todas las piezas de las señales con la etiqueta StreetSign (el nivel Bajo las esconde)")
	check(okDecals, "cada señal y tapa con la imagen que le toca del road pack, en su cara")
	check(okBanned, "nada del cartel de City 17 ni del resto del pack")
	-- STOP: mirando a quien sale de la calle de barrio (hacia +Z), a su derecha
	local stop = nil
	for _, item in signs:GetChildren() do
		if item.Name == "SenalStop" then
			stop = item
			break
		end
	end
	local face = stop and stop.SignFace
	check(face and face.CFrame.LookVector.Z > 0.99, "el STOP mira a los coches que llegan a la boca")
	-- Casco: 20
	local sr20 = false
	local list = StreetLook.mouthSigns({ Center = SR_MOUTH, WalkDir = V3(1, 0, 0), Length = 24, Depth = 6 }, probe)
	for _, s in list do
		if s.Kind == "Velocidad20" then
			sr20 = true
		end
	end
	check(sr20, "en el casco antiguo el límite es 20 (30 en los barrios)")
	check(#StreetLook.mouthSigns({ Center = V3(5000, 0, 5000), WalkDir = V3(1, 0, 0), Length = 24, Depth = 6 }, probe) == 0, "sin acera donde iría el STOP: ninguna señal")
end

print("Cableado")
do
	local main = fs.readFile("src/server/Main.server.luau")
	check(main:find("World.StreetDress", 1, true) and main:find("Region).Highways", 1, true), "Main viste las calles al cargar los materiales del dueño")
	local um = fs.readFile("src/server/World/UserMaterials.luau")
	local a, b = um:find("pcall(dress", 1, true), um:find("UserMaterials.tint(workspace", 1, true)
	check(a and b and a < b, "UserMaterials llama a las calles con pcall antes de aclarar")
	local detail = fs.readFile("src/client/Controllers/MaterialDetail.luau")
	check(detail:find('StreetSign = "CityDetail"', 1, true) and detail:find("CanCollide = not hide", 1, true) and detail:find('IsA("Decal")', 1, true), "MaterialDetail esconde las señales y las tapas en Bajo (también sus imágenes y el choque del poste)")
end

print("")
if failures > 0 then
	print(("❌ %d comprobaciones fallan"):format(failures))
	process.exit(1)
end
print("✅ Calles realistas correctas")
