-- Prueba del PAISAJE (v118, docs/paisaje/paisaje.md): relieve natural fuera de la ciudad, bosques,
-- suelo lejano, cielo de día propio y luz del día. Con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-paisaje.luau                 (cuentas puras: relieve, terreno, siluetas, cielo)
--   lune run scripts/test-paisaje.luau X.rbxl          (además, el mapa construido:
--       rojo build default.project.json -o X.rbxl && lune run scripts/build-place.luau X.rbxl)
--
-- Comprueba que:
--   * el relieve es continuo, va de 0 a ~270 studs, no sube junto a lo construido, el río, los lagos ni
--     la playa, y en los acantilados sube antes; el mapa horneado se guarda y se lee igual
--   * el terreno del relieve solo AÑADE (no toca el agua ni baja nada) y pone roca en lo empinado,
--     hierba con briznas solo en las lomas (el llano es LeafyGrass) y tierra debajo
--   * con el mapa construido: NINGUNA pieza de la ciudad (calles, edificios, aeropuerto, puertos, vía del
--     tren, zonas verdes, ocio, marcas de la historia) queda bajo el relieve; los sitios que se montan
--     al arrancar (zonas de misión, pueblos de la historia, lugares del plano) quedan llanos; los
--     árboles del campo están a ras del suelo; los bosques nuevos gastan pocas piezas y se cargan con
--     su versión de lejos (StreamingMesh)
--   * el suelo lejano (shared/Horizon) solo se ve desde el aire, sobre Valmar y fuera de los interiores,
--     con piezas de como mucho 2048 studs; las lomas lejanas se esconden al acercarte
--   * el cielo de día propio solo se usa con sus 6 caras subidas; las caras existen y miden 1024
--   * la luz del día: aire limpio desde el avión solo con el paisaje lejano (Medio y Alto)

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")

local Enum, Vector3 = roblox.Enum, roblox.Vector3

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local Relief = L.load("src/shared/Relief")
local CityPlan = L.load("src/shared/CityPlan")
local Horizon = L.load("src/shared/Horizon")
local SkyChoice = L.load("src/shared/SkyChoice")
local Graphics = L.load("src/shared/Graphics")

---------------------------------------------------------------------
print("Relieve (shared/Relief): forma, horneado y lectura")
---------------------------------------------------------------------
local minS, maxS, okRange = math.huge, -math.huge, true
for i = 1, 4000 do
	local x, z = (i * 7919) % 9000 - 4500, (i * 104729) % 8000 - 4000
	local s = Relief.shape(x, z)
	minS, maxS = math.min(minS, s), math.max(maxS, s)
	if s < 0 or s > 1 or s ~= s then
		okRange = false
	end
end
check(okRange and maxS - minS > 0.5, ("forma entre 0 y 1 y con variedad (%.2f..%.2f)"):format(minS, maxS))
check(Relief.shape(1234, -2345) == Relief.shape(1234, -2345), "la forma es siempre la misma en cada punto (sin azar)")
local jump = 0
for i = 0, 400 do
	local x = -3000 + i * 4
	jump = math.max(jump, math.abs(Relief.shape(x + 4, -3100) - Relief.shape(x, -3100)))
end
check(jump < 0.08, ("la forma es continua (salto máx. %.3f cada 4 studs)"):format(jump))

-- Un plano pequeño de prueba: una manzana construida en el centro, el resto libre
local rects = { { X0 = -200, X1 = 200, Z0 = -200, Z1 = 200 } }
local field, stats = Relief.bake(CityPlan, rects, { { X = 2500, Z = 2000, R = 150 } })
check(field.NX == Relief.NX and field.NZ == Relief.NZ and #field.Amp == Relief.NX * Relief.NZ, "rejilla del mapa del tamaño esperado")
check(stats.Max > 200 and stats.Max <= Relief.MaxAmp + 1, ("sierras altas en lo salvaje (máx. %.0f studs)"):format(stats.Max))
local function maxNear(x: number, z: number, r: number): number
	local m = 0
	for a = 0, 15 do
		for d = 0, r, 8 do
			local px, pz = x + math.cos(a / 16 * math.pi * 2) * d, z + math.sin(a / 16 * math.pi * 2) * d
			m = math.max(m, Relief.height(field, px, pz))
		end
	end
	return m
end
check(Relief.height(field, 0, 0) == 0 and maxNear(0, 0, 200 + Relief.Clear - 8) < 0.5, "llano en lo construido y en su franja de alrededor")
check(maxNear(2500, 2000, 150) < 0.5, "llano en los círculos que se piden (zonas de misión…)")
local riverOk = true
for _, p in CityPlan.River.Points do
	if Relief.height(field, p[1], p[2]) > 0.5 then
		riverOk = false
	end
end
check(riverOk, "el río va por un valle llano")
local lakeOk = true
for _, lake in CityPlan.Lakes do
	if maxNear(lake.X, lake.Z, lake.R + 40) > 0.5 then
		lakeOk = false
	end
end
check(lakeOk, "los lagos y su orilla, llanos")
-- Playa: la franja de arena de la costa (no acantilado) queda llana
local beachOk, beachChecked = true, 0
local coast = CityPlan.Coast
for k = 12, 30 do
	local a, b = coast[k], coast[k + 1]
	local mx, mz = (a[1] + b[1]) / 2, (a[2] + b[2]) / 2
	-- hacia dentro: hacia el centro de la isla
	local len = math.sqrt(mx * mx + mz * mz)
	for d = 0, Relief.Beach, 10 do
		local x, z = mx - mx / len * d, mz - mz / len * d
		if CityPlan.inside(CityPlan.Coast, x, z) then
			beachChecked += 1
			if Relief.height(field, x, z) > 1 then
				beachOk = false
			end
		end
	end
end
check(beachOk and beachChecked > 20, "la playa de la costa (sin acantilado) queda llana")
local enc = Relief.encode(field)
local back = Relief.decode(enc)
check(back ~= nil and #enc == Relief.NX * Relief.NZ and Relief.encode(back :: any) == enc, "el mapa se guarda en texto y se lee igual")
check(Relief.decode("abc") == nil, "un mapa roto no se usa")
local builtText = Relief.encodeBuilt(field)
local builtBack = Relief.decodeBuilt(builtText, field)
check(builtBack ~= nil and Relief.builtAt(field, 0, 0) > 0.9 and Relief.builtAt(field, 2600, -1500) < 0.1, "lo construido alrededor de cada nudo (ciudad gris de lejos)")

---------------------------------------------------------------------
print("Terreno del relieve (World/TerrainBuilder.reliefChunk)")
---------------------------------------------------------------------
L.globals.Region3 = roblox.Region3
local TerrainBuilder = L.load("src/server/World/TerrainBuilder")
-- Terreno de mentira: llano a Y = -1 (hierba hasta -1: vóxel [-4, 0] ocupado 0,75) y un charco de agua
local written: { any } = {}
local fakeTerrain = {}
function fakeTerrain:ReadVoxels(region: any, res: number)
	local size = region.Size
	local origin = region.CFrame.Position - size / 2
	local nx, ny, nz = math.round(size.X / res), math.round(size.Y / res), math.round(size.Z / res)
	local mats, occs = {}, {}
	for i = 1, nx do
		mats[i], occs[i] = {}, {}
		for y = 1, ny do
			mats[i][y], occs[i][y] = {}, {}
			local bottom = origin.Y + (y - 1) * res
			for k = 1, nz do
				local x = origin.X + (i - 0.5) * res
				local water = x < origin.X + 16 -- (una franja de agua en el borde oeste del trozo)
				local occ = math.clamp((-1 - bottom) / res, 0, 1)
				if water and bottom < -2 then
					mats[i][y][k], occs[i][y][k] = Enum.Material.Water, 1
				else
					mats[i][y][k], occs[i][y][k] = if occ > 0 then Enum.Material.LeafyGrass else Enum.Material.Air, occ
				end
			end
		end
	end
	return mats, occs
end
function fakeTerrain:WriteVoxels(region: any, res: number, mats: any, occs: any)
	table.insert(written, { Region = region, Mats = mats, Occs = occs })
end
-- Un trozo con relieve alto: el de más amplitud del mapa de prueba
local bestK, bestA = 1, 0
for k, a in field.Amp do
	if a > bestA then
		bestK, bestA = k, a
	end
end
local bi, bj = (bestK - 1) % field.NX, (bestK - 1) // field.NX
local cx = field.MinX + math.floor(bi * field.Cell / 256) * 256
local cz = field.MinZ + math.floor(bj * field.Cell / 256) * 256
local changed = TerrainBuilder.reliefChunk(fakeTerrain :: any, field, cx, cz)
check(changed > 0 and #written == 1, ("escribe el trozo con relieve (%d vóxeles)"):format(changed))
local w = written[1]
local onlyAdds, waterKept, mats = true, true, {}
if w then
	local before = { fakeTerrain:ReadVoxels(w.Region, 4) }
	for i, plane in w.Occs do
		for y, row in plane do
			for k, occ in row do
				local oldOcc, oldMat = before[2][i][y][k], before[1][i][y][k]
				if occ < oldOcc - 1e-6 then
					onlyAdds = false
				end
				if oldMat == Enum.Material.Water and (w.Mats[i][y][k] ~= Enum.Material.Water or occ ~= oldOcc) then
					waterKept = false
				end
				if occ > 0 then
					local name = w.Mats[i][y][k].Name
					mats[name] = (mats[name] or 0) + 1
				end
			end
		end
	end
end
check(onlyAdds, "el relieve solo añade terreno (no baja nada de lo que había)")
check(waterKept, "el agua se queda como estaba")
check((mats.Grass or 0) > 0 and ((mats.Rock or 0) + (mats.Slate or 0)) > 0 and (mats.Ground or 0) > 0, ("hierba en las lomas, roca en lo empinado y tierra debajo (%s)"):format((function()
	local parts = {}
	for k, v in mats do
		table.insert(parts, k .. "=" .. v)
	end
	table.sort(parts)
	return table.concat(parts, " ")
end)()))
local flatChunk = TerrainBuilder.reliefChunk(fakeTerrain :: any, field, -128, -128)
check(flatChunk == 0, "en la ciudad (sin relieve) no se escribe nada")
check(Relief.material(1, 0.1, 100, 100) == "LeafyGrass" and Relief.material(80, 1.6, 100, 100) ~= "Grass" and Relief.material(60, 0.1, 500, 500) ~= "Rock", "materiales: pie de loma sin briznas, roca en lo empinado, hierba en lo suave")

---------------------------------------------------------------------
print("Briznas, colores y cielo")
---------------------------------------------------------------------
local T = Graphics.Tiers
check(not T.Low.GrassBlades and T.Medium.GrassBlades and T.High.GrassBlades, "briznas 3D en Medio y Alto, no en Bajo")
local tb = fs.readFile("src/server/World/TerrainBuilder.luau")
check(tb:find("TerrainBuilder.Flat = Enum.Material.LeafyGrass", 1, true) ~= nil, "el llano de la isla es LeafyGrass (las briznas solo salen en Grass)")
local landmarks = fs.readFile("src/server/World/Kit/Landmarks.luau")
check(not landmarks:find("HILL_RADIUS, Enum.Material.Grass)", 1, true), "la colina del mirador sin briznas (sus caminos son piezas finas)")
check(SkyChoice.ownDay({}) == nil and SkyChoice.ownDay(nil) == nil, "sin caras subidas, el cielo de día de siempre")
local six = {}
for _, s in { "bk", "dn", "ft", "lf", "rt", "up" } do
	six["cielo_dia_" .. s] = "rbxassetid://" .. (100 + #s)
end
local own = SkyChoice.ownDay(six)
check(own ~= nil and own.SkyboxFt == six.cielo_dia_ft and own.SkyboxUp == six.cielo_dia_up, "con las 6 caras subidas, el cielo de día propio")
local five = table.clone(six)
five.cielo_dia_dn = nil
check(SkyChoice.ownDay(five) == nil, "con una cara de menos, no (un cielo a medias se vería roto)")
local facesOk = true
for _, s in { "bk", "dn", "ft", "lf", "rt", "up" } do
	local path = "assets/paisaje/cielo_dia_" .. s .. ".jpg"
	if not fs.isFile(path) then
		facesOk = false
	else
		local data = fs.readFile(path)
		-- (tamaño del JPG: marcador SOF0/SOF2 con alto y ancho)
		local sof = data:find("\255\192", 1, true) or data:find("\255\194", 1, true)
		if not sof then
			facesOk = false
		else
			local h = data:byte(sof + 5) * 256 + data:byte(sof + 6)
			local wv = data:byte(sof + 7) * 256 + data:byte(sof + 8)
			if h ~= 1024 or wv ~= 1024 then
				facesOk = false
			end
		end
	end
end
check(facesOk, "las 6 caras del cielo de día existen y miden 1024 × 1024 (scripts/paisaje/gen_cielo.py)")
local ids = L.load("src/shared/PaisajeTextureIds")
check(type(ids) == "table", "shared/PaisajeTextureIds existe (lo rellena scripts/upload-paisaje.sh)")
check(fs.isFile("scripts/upload-paisaje.sh") and fs.readFile("scripts/upload-paisaje.sh"):find("PaisajeTextureIds", 1, true) ~= nil, "script de subida del cielo (no se sube nada desde aquí)")
local loader = fs.readFile("src/server/World/SkyLoader.luau")
check(loader:find("SkyLoader.ownDay", 1, true) ~= nil and loader:find("PaisajeTextureIds", 1, true) ~= nil, "el cargador de cielos usa el cielo propio si está subido")
local dl = fs.readFile("src/client/Controllers/DayLight.luau")
check(dl:find("DayLight.aerial", 1, true) ~= nil and dl:find("tier.FarRange", 1, true) ~= nil, "aire más limpio desde el avión solo con el paisaje lejano (Medio y Alto)")

---------------------------------------------------------------------
print("Paisaje lejano (shared/Horizon)")
---------------------------------------------------------------------
local ground = Horizon.groundPieces(field)
local sizeOk, aerialOk, classes = true, true, {}
for _, p in ground do
	if p.Size.X > Horizon.MaxSize or p.Size.Z > Horizon.MaxSize or p.Size.X <= 0 or p.Size.Z <= 0 then
		sizeOk = false
	end
	if not p.Aerial or not p.Box or not p.Far then
		aerialOk = false
	end
	classes[p.Name] = (classes[p.Name] or 0) + 1
end
check(#ground > 50 and #ground < 2500, ("suelo lejano en %d losas"):format(#ground))
check(sizeOk, "ninguna losa pasa de 2048 studs")
check(aerialOk, "todas solo desde el aire, en losa y solo en Medio y Alto")
check((classes.SueloGreen or 0) > 0 and (classes.SueloDeep or 0) > 0 and (classes.SueloShallow or 0) > 0 and (classes.SueloSand or 0) > 0 and (classes.SueloCity or 0) > 0, "isla verde, ciudad gris, playa, bajíos turquesa y mar hondo")
local yOk = true
for _, p in ground do
	if p.Center.Y + p.Size.Y / 2 > -1.5 then
		yOk = false
	end
end
check(yOk, "las losas quedan por debajo del terreno de verdad (tierra a -1, agua a -2)")
local sample = ground[1]
check(not Horizon.visible(sample, Vector3.new(0, 10, 0)), "a pie no se ve el suelo lejano")
check(Horizon.visible(sample, Vector3.new(0, 300, 0)), "desde el avión, sí")
check(not Horizon.visible(sample, Vector3.new(0, 300, 0), true), "dentro de un interior (salas en el cielo), no")
check(not Horizon.visible(sample, Vector3.new(24000, 300, 24000)), "lejos de Valmar (arena del combate aéreo, Tefra), no")
check(not Horizon.visible(sample, Vector3.new(-3400, 700, -3400)), "en la isla del sueño del prólogo, no")
local hills = Horizon.reliefPieces(field)
local hillOk = #hills > 0
for _, h in hills do
	if h.Aerial or not h.HideWithin or h.Size.Y > Horizon.MaxSize then
		hillOk = false
	end
end
check(hillOk, ("%d siluetas de lomas: se ven de lejos y se esconden al acercarte"):format(#hills))
check(#Horizon.reliefPieces(nil) == 0, "sin mapa de relieve, sin siluetas")

---------------------------------------------------------------------
-- Con el mapa construido
---------------------------------------------------------------------
local placePath = process.args[1]
if placePath then
	print("Mapa construido: " .. placePath)
	local game = roblox.deserializePlace(fs.readFile(placePath))
	local town = game:GetService("Workspace"):FindFirstChild("Town")
	local value = game:GetService("ServerStorage"):FindFirstChild("ReliefMap")
	local replicated = game:GetService("ReplicatedStorage"):FindFirstChild("ReliefMap")
	check(town ~= nil, "el archivo trae la ciudad")
	check(value ~= nil and replicated ~= nil, "el mapa del relieve está en ServerStorage (terreno) y en ReplicatedStorage (siluetas)")
	local real = Relief.fromValue(value)
	check(real ~= nil and real.Built ~= nil, "el mapa se lee (amplitudes y ciudad)")
	if town and real then
		local movable = { Tree = true, Cypress = true, Palm = true, Bush = true, Arbol = true }
		local buried, checkedParts, worst = 0, 0, ""
		local treesOff, trees = 0, 0
		local bosqueParts, bosqueTrees, tiles, lodOk = 0, 0, 0, true
		for _, d in town:GetDescendants() do
			if d:IsA("BasePart") and not d:HasTag("EditOnly") then
				local model = d:FindFirstAncestorWhichIsA("Model")
				local inForest = d:FindFirstAncestor("Bosques") ~= nil
				if inForest then
					bosqueParts += 1
					if d.Name == "Trunk" then
						bosqueTrees += 1
						local p = d.CFrame.Position - Vector3.new(0, d.Size.X / 2, 0)
						local surface = Relief.surfaceY(real, p.X, p.Z)
						if math.abs(p.Y - surface) > 3 then
							treesOff += 1
						end
					end
				elseif not (model and movable[model.Name]) and d.Name ~= "Piedra" and d.Name ~= "Bush" then
					local cf, s = d.CFrame, d.Size
					local pos = cf.Position
					if pos.Y > -10 and pos.Y < 160 then
						checkedParts += 1
						-- el centro y las 4 esquinas de su planta
						for _, o in { { 0, 0 }, { 0.5, 0.5 }, { -0.5, 0.5 }, { 0.5, -0.5 }, { -0.5, -0.5 } } do
							local p = (cf * roblox.CFrame.new(s.X * o[1], 0, s.Z * o[2])).Position
							local h = Relief.height(real, p.X, p.Z)
							if h > 0.5 then
								buried += 1
								if worst == "" then
									worst = ("%s (%d, %d) +%.1f"):format(d:GetFullName(), p.X, p.Z, h)
								end
								break
							end
						end
					end
				elseif model and movable[model.Name] then
					local trunk = model:FindFirstChild("Trunk")
					if trunk and trunk == d then
						trees += 1
					end
				end
			elseif d:IsA("Model") and d.Name == "Bosque" then
				tiles += 1
				local okLod = pcall(function()
					if (d :: any).LevelOfDetail ~= Enum.ModelLevelOfDetail.StreamingMesh or (d :: any).ModelStreamingMode ~= Enum.ModelStreamingMode.Atomic then
						lodOk = false
					end
				end)
				if not okLod then
					lodOk = false
				end
			end
		end
		check(checkedParts > 100000 and buried == 0, ("ninguna pieza de la ciudad bajo el relieve (%d piezas mirando su planta; %d enterradas %s)"):format(checkedParts, buried, worst))
		check(bosqueTrees > 1000 and bosqueTrees <= 5200, ("bosques en las lomas: %d árboles"):format(bosqueTrees))
		check(bosqueParts <= bosqueTrees * 3, ("pocas piezas por árbol (%.2f de media)"):format(bosqueParts / math.max(bosqueTrees, 1)))
		check(treesOff == 0, ("cada árbol del bosque con el pie en el suelo del relieve (%d fuera)"):format(treesOff))
		check(tiles > 20 and lodOk, ("%d grupos de bosque que se cargan enteros y de lejos se ven simplificados (StreamingMesh)"):format(tiles))
		-- Árboles del campo y del monte: a ras del suelo (el relieve o las montañas de siempre)
		local floating = 0
		for _, model in town:GetDescendants() do
			if model:IsA("Model") and (model.Name == "Tree" or model.Name == "Cypress") then
				local trunk = model:FindFirstChild("Trunk")
				if trunk and trunk:IsA("BasePart") then
					local p = trunk.CFrame.Position
					local h = Relief.height(real, p.X, p.Z)
					if h > 0.5 then
						local surface = math.max(Relief.Base + h, Relief.domeY(CityPlan.Mountains, p.X, p.Z))
						local bottom = p.Y - trunk.Size.Y / 2
						if math.abs(bottom - surface) > 4 then
							floating += 1
						end
					end
				end
			end
		end
		check(floating == 0, ("los árboles del campo que quedan en una loma, a ras del suelo (%d fuera)"):format(floating))
		-- Sitios que se montan al arrancar (y los de ocio y zonas verdes): llanos
		local OcioSitios = L.load("src/shared/OcioSitios")
		local flatOk, bad = true, ""
		local function flatAt(x: number, z: number, r: number, name: string)
			for a = 0, 7 do
				for _, d in { 0, r * 0.5, r } do
					local px, pz = x + math.cos(a * math.pi / 4) * d, z + math.sin(a * math.pi / 4) * d
					if Relief.height(real, px, pz) > 0.5 then
						flatOk = false
						bad = name
						return
					end
				end
			end
		end
		for _, s in OcioSitios.List do
			flatAt(s.Center[1], s.Center[2], math.max(s.Size[1], s.Size[2]) / 2, s.Id)
		end
		for name, t in CityPlan.Towns do
			flatAt(t[1], t[2], 360, name)
		end
		for name, p in CityPlan.Places do
			flatAt(p[1], p[2], 100, name)
		end
		flatAt(-3100, -2900, 120, "Meteorito")
		check(flatOk, "llanos los sitios de ocio, los pueblos de la historia, los lugares del plano y las zonas de misión " .. bad)
		local value2 = value :: any
		print(("  · relieve: %s celdas con lomas, máx. %s studs, %s árboles subidos, bosques %s árboles / %s piezas"):format(
			tostring(value2:GetAttribute("Raised")), tostring(value2:GetAttribute("Max")), tostring(value2:GetAttribute("Lifted")),
			tostring(value2:GetAttribute("ForestTrees")), tostring(value2:GetAttribute("ForestParts"))))
	end
end

print()
if failures > 0 then
	print(("❌ %d comprobaciones fallan"):format(failures))
	process.exit(1)
end
print("✅ Paisaje correcto")
