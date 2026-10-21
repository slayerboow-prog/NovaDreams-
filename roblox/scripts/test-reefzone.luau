-- Prueba de la zona de referencia del mar v2, el Cañón de Dorada (shared/Sea/ReefZone, shared/Sea/MarKit,
-- World/ReefZoneBuilder, World/MarMeshes, Controllers/ReefZoneFx), FUERA de Roblox, con Lune.
-- (Lo que se ve desde la cámara lo mide scripts/test-reefzone-camera.luau.)
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-reefzone.luau
--
-- Comprueba:
--   * la costa, las playas, los puertos y los barcos: nada sólido por encima de -9 (2 m bajo la
--     superficie) y nada a menos de 40 studs de tierra
--   * se puede recorrer: del jardín al borde del abismo hay agua por el cañón (por debajo del arco), la
--     cueva tiene boca, y las profundidades piden el equipo que toca (la entrada sin equipo)
--   * hay de todo (encargo §4, §5, §10): paredes altas, repisas, salientes, arco, cueva con claraboyas,
--     columnas, agujas lejanas, kelp gigante, jardín de luz, ruinas con pirámide; las 5 regiones A-E
--   * el kit (MarKit): cada pieza con su tamaño y su respaldo de piezas (nunca vacío, nunca un bloque
--     solo); con la malla subida, la zona usa la malla (una pieza) y no el respaldo
--   * la paleta (corales cálidos arriba, fríos abajo; nada marrón) y la mezcla de materiales del fondo
--     (arena dorada, arenisca, caliza, roca, tierra y fango; la arena ya no es casi blanca)
--   * el móvil: topes de piezas, luces, emisores y lo que se mece

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")

local Ocean = L.load("src/shared/Sea/Ocean")
local ReefZone = L.load("src/shared/Sea/ReefZone")
local MarKit = L.load("src/shared/Sea/MarKit")
local ShoreDecor = L.load("src/shared/Sea/ShoreDecor")
local Diving = L.load("src/shared/Sea/Diving")
local Boats = L.load("src/shared/Boats")
local OceanBiomes = L.load("src/shared/Sea/OceanBiomes")

local Color3 = roblox.Color3

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local floorCache = {}
local function floorY(x: number, z: number): number?
	local gx, gz = math.floor(x / 2 + 0.5), math.floor(z / 2 + 0.5)
	local key = gx * 100000 + gz
	local v = floorCache[key]
	if v == nil then
		local f = Ocean.floorY(gx * 2, gz * 2)
		v = if f then f else false
		floorCache[key] = v
	end
	return if v == false then nil else v
end

local ops = ReefZone.ops()
local placements = ReefZone.placements(floorY)

---------------------------------------------------------------------
print("▶ La costa, los barcos y la superficie")
check(ReefZone.highestTop() <= ReefZone.TopLimit + 1e-6 and ReefZone.TopLimit <= Boats.SeaLevel - Boats.Draft - 4, ("Nada sólido por encima de %d (lo más alto: %.1f): los barcos pasan por encima y se nada en la superficie"):format(ReefZone.TopLimit, ReefZone.highestTop()))
do
	local nearest, at = math.huge, ""
	for _, op in ops do
		if op.Material ~= "Water" then
			local r = op.R or math.max(op.SX or 0, op.SZ or 0) / 2
			local d = Ocean.landDistance(op.X, op.Z) - r
			if d < nearest then
				nearest, at = d, op.Tag
			end
		end
	end
	check(nearest > 35, ("Nada de la zona toca la costa ni las playas (lo más cerca: %.0f studs, %s)"):format(nearest, at))
	local keepOk = true
	for _, k in Ocean.Keep do
		local b = ReefZone.Box
		local dx = math.max(b.MinX - k.X, 0, k.X - b.MaxX)
		local dz = math.max(b.MinZ - k.Z, 0, k.Z - b.MaxZ)
		if math.sqrt(dx * dx + dz * dz) < k.R + 100 then
			keepOk = false
			print("    cerca de " .. k.Name)
		end
	end
	check(keepOk, "Lejos de los puertos, el puerto deportivo y las islas (el puerto lo lleva otro trabajo)")
	-- la playa de delante: el fondo junto a la arena sigue como estaba
	local shoreSame = true
	for z = -460, -140, 20 do
		for x = 4200, 4300, 5 do
			local s = Ocean.sample(x, z)
			if s.Floor and s.D < 60 and math.abs(s.Floor - Ocean.CoastY) > 1e-6 then
				shoreSame = false
			end
		end
	end
	check(shoreSame, "Junto a la arena de Playa Dorada el fondo es el de siempre (-14)")
end

---------------------------------------------------------------------
print("\n▶ Se puede recorrer")
do
	local blocked = nil
	for x = 4336, 4870, 3 do
		local bed = ReefZone.bedAt(x)
		local z = ReefZone.axisZ(x)
		local y = math.min(bed + 7, ReefZone.Surface - 3)
		if ReefZone.solid(x, y, z, floorY) then
			blocked = x
			break
		end
	end
	check(blocked == nil, "Del jardín al borde del abismo, por el centro del cañón, todo es agua (también bajo el arco)" .. (if blocked then (" (choca en x=%d)"):format(blocked) else ""))
	local cx, cz = ReefZone.where({ X = 4504, Cave = 20 })
	check(not ReefZone.solid(cx, -37, cz, floorY) and not ReefZone.solid(4498, -40, ReefZone.where({ X = 4498, Cave = 4 }) and select(2, ReefZone.where({ X = 4498, Cave = 4 })), floorY), "La Cueva de la Luz: la sala y la boca son agua (se entra desde el cañón)")
	local sky = false
	for y = -40, -8 do
		local sx, sz = ReefZone.where({ X = 4506, Cave = 22 })
		if y > -12 and not ReefZone.solid(sx, y, sz, floorY) then
			sky = true
		end
	end
	check(sky, "Las claraboyas llegan a la cima de la meseta (por ahí baja la luz)")
	local function meters(y: number): number
		return (ReefZone.Surface - y) / Ocean.StudsPerMeter
	end
	local entrance = meters(ReefZone.bedAt(4420))
	local ruins = meters(ReefZone.bedAt(4660))
	local abyss = meters(ReefZone.bedAt(4860))
	check(entrance <= Diving.Gear.Base.Depth, ("La entrada del cañón (%.1f m) se ve y se nada sin equipo (límite %d m)"):format(entrance, Diving.Gear.Base.Depth))
	check(ruins <= Diving.Gear.Gafas.Depth and ruins > Diving.Gear.Base.Depth, ("La Pirámide Hundida (%.1f m) pide gafas y tubo: un objetivo"):format(ruins))
	check(abyss <= Diving.Gear.Botella.Depth and abyss > Diving.Gear.Gafas.Depth, ("El borde del abismo (%.1f m) pide botella"):format(abyss))
	check(Ocean.zoneAt(4500, ReefZone.axisZ(4500)) == "Canon" and Ocean.zoneAt(4300, -300) == "Coral", "El HUD dice «Cañón de Dorada» dentro y «Jardín de coral» en la entrada")
	local poiOk = true
	for _, id in { "CanonDorada", "CuevaLuz", "PiramideHundida" } do
		local poi = Ocean.PoiById[id]
		if not (poi and poi.Zone == "Canon") then
			poiOk = false
		end
	end
	check(poiOk, "Tres sitios para descubrir: el cañón, la Cueva de la Luz y la Pirámide Hundida")
end

---------------------------------------------------------------------
print("\n▶ Geografía de verdad (encargo §4 y §12)")
do
	local tags = {}
	for _, op in ops do
		tags[op.Tag] = (tags[op.Tag] or 0) + 1
	end
	check((tags.Wall or 0) > 100 and (tags.Plateau or 0) > 60 and (tags.Ledge or 0) >= 15, ("Paredes de bolas con salientes (%d), mesetas (%d) y repisas (%d)"):format(tags.Wall or 0, tags.Plateau or 0, tags.Ledge or 0))
	check((tags.Arch or 0) > 10 and (tags.Cave or 0) >= 3 and (tags.Skylight or 0) >= 2 and (tags.Column or 0) > 8 and (tags.Spire or 0) > 15, "Un arco, la cueva con dos claraboyas, columnas de piedra y agujas lejanas")
	-- altura de las paredes: de la cima al lecho
	local tallest, lowest = 0, math.huge
	for x = 4400, 4740, 20 do
		local bed = ReefZone.bedAt(x)
		for _, side in { -1, 1 } do
			local h = ReefZone.topAt(x, side) - bed
			tallest = math.max(tallest, h)
			lowest = math.min(lowest, h)
		end
	end
	check(tallest >= 60 and lowest >= 15, ("Paredes de %.0f a %.0f studs (el jugador mide 5): formaciones que lo hacen pequeño"):format(lowest, tallest))
	-- salientes: puntos de agua con roca encima en la pared
	local over = 0
	for x = 4400, 4740, 8 do
		local _, hw = ReefZone.bedAt(x)
		for _, side in { -1, 1 } do
			for y = -50, -14, 4 do
				local z = ReefZone.axisZ(x) + side * (hw - 1)
				if not ReefZone.solid(x, y, z, floorY) and ReefZone.solid(x, y + 6, z, floorY) then
					over += 1
				end
			end
		end
	end
	check(over >= 10, ("Salientes en las paredes (agua con roca encima): %d"):format(over))
	local mats = {}
	for _, op in ops do
		mats[op.Material] = true
	end
	check(mats.Rock and mats.Limestone and mats.Sandstone and mats.Ground and mats.Mud and mats.Water, "Mezcla de materiales: roca, caliza, ondas de arenisca, tierra, fango (y huecos de agua)")
	local tb = fs.readFile("src/server/World/TerrainBuilder.luau")
	-- (v125: los colores del fondo están en shared/TerrainPalette.Sea; TerrainBuilder los usa)
	local tp = fs.readFile("src/shared/TerrainPalette.luau")
	local r, g, b = string.match(tp, "Salt = rgb%((%d+), (%d+), (%d+)%)")
	local lum = (tonumber(r) * 0.3 + tonumber(g) * 0.59 + tonumber(b) * 0.11) / 255
	check(lum < 0.78 and tonumber(r) > tonumber(b) + 30, ("La arena del fondo ya no es casi blanca: dorada clara (%s,%s,%s; luz %.2f)"):format(r, g, b, lum))
	check(string.find(tb, "Sandstone = TerrainPalette.Sea.Sandstone", 1, true) ~= nil and (string.find(tp, "Sandstone = rgb(", 1, true) ~= nil or string.find(tp, "Sandstone = if V4 then rgb(", 1, true) ~= nil), "La arenisca de las ondas tiene su color (TerrainBuilder.Colors; con la v4, la arena del fondo)")
	local um = fs.readFile("src/server/World/UserMaterials.luau")
	check(string.find(um, "Salt", 1, true) == nil and string.find(um, "Sandstone", 1, true) == nil, "Ni la arena del fondo (Salt) ni las ondas (Sandstone) llevan la textura de playa del dueño (World/UserMaterials: marrón bajo el agua)")
end

---------------------------------------------------------------------
print("\n▶ El kit del mar (MarKit)")
do
	local n, corals, rocks = 0, 0, 0
	local allFallback = true
	local noBlock = true
	for name, info in MarKit.Pieces do
		n += 1
		if info.Group == "Coral" then
			corals += 1
		elseif info.Group == "Roca" then
			rocks += 1
		end
		local pieces = MarKit.fallback(name, info.Size[2], Color3.fromRGB(200, 100, 120), 1.3)
		if #pieces < 1 then
			allFallback = false
			print("    sin respaldo: " .. name)
		end
		if #pieces == 1 and pieces[1].Shape == nil and pieces[1].Mesh == nil and name ~= "RocaLaja" then
			noBlock = false
			print("    respaldo de un solo bloque: " .. name)
		end
		for _, p in pieces do
			if p.Size.X ~= p.Size.X or p.Size.Magnitude <= 0 then
				allFallback = false
			end
		end
		if not (info.Tri and info.Tri <= 2400) then
			allFallback = false
			print("    sin presupuesto de triángulos (≤ 2400, móvil): " .. name)
		end
	end
	check(n >= 22 and corals >= 7 and rocks >= 4, ("%d piezas: %d corales, %d rocas, plantas, luz, vida pequeña, pilote, pirámide y columna"):format(n, corals, rocks))
	check(allFallback, "Cada pieza tiene su respaldo de piezas de Roblox y un presupuesto de triángulos de móvil")
	check(noBlock, "Ningún respaldo es un bloque solo")
	local unknown = {}
	local regions = {}
	for _, p in placements do
		if not MarKit.Pieces[p.Kind] then
			table.insert(unknown, p.Kind)
		end
		regions[p.Region] = (regions[p.Region] or 0) + 1
	end
	check(#unknown == 0, "Todo lo que se pone en la zona es una pieza del kit")
	check(regions.A and regions.B and regions.C and regions.D and regions.E, ("Las 5 regiones del encargo: A arrecife %d · B jardín %d · C caverna %d · D abismo %d · E ruinas %d"):format(regions.A or 0, regions.B or 0, regions.C or 0, regions.D or 0, regions.E or 0))
	local kinds = {}
	for _, p in placements do
		kinds[p.Kind] = true
	end
	check(kinds.KelpGigante and kinds.SetaLuz and kinds.Piramide and kinds.ColumnaRuina and kinds.Abanico and kinds.CoralMesa, "Kelp gigante, jardín de luz, pirámide con columnas, abanicos y corales mesa")
	-- Los ids de la subida y los nombres del kit
	local ids = L.load("src/shared/Sea/MarAssetIds")
	local okIds = type(ids.Mallas) == "table" and type(ids.Texturas) == "table"
	local MarFauna = L.load("src/shared/Sea/MarFauna") -- (v125: la fauna sube con el kit, a los mismos ids)
	for k in ids.Mallas do
		if not MarKit.Pieces[k] and not MarFauna.Pieces[k] then
			okIds = false
		end
	end
	check(okIds, "shared/Sea/MarAssetIds: mallas con el nombre de su pieza (lo escribe scripts/upload-mar.sh)")
	-- Las mallas de Blender (assets/mar/manifest.json) miden lo que dice MarKit (si no, Roblox las estiraría)
	if fs.isFile("assets/mar/manifest.json") then
		local serde = require("@lune/serde")
		local man = serde.decode("json", fs.readFile("assets/mar/manifest.json"))
		local sameSize, inBudget, files = true, true, true
		local seen = 0
		for _, e in man.Piezas do
			local info = MarKit.Pieces[e.Nombre]
			if not info then
				sameSize = false
				print("    pieza de Blender que no está en MarKit: " .. e.Nombre)
				continue
			end
			seen += 1
			for k = 1, 3 do
				if math.abs(e.Size[k] - info.Size[k]) > 0.06 * info.Size[k] + 0.06 then
					sameSize = false
					print(("    %s: Blender %.2f, MarKit %.2f"):format(e.Nombre, e.Size[k], info.Size[k]))
				end
			end
			if e.Tris > info.Tri then
				inBudget = false
			end
			if not fs.isFile("assets/mar/" .. e.FBX) then
				files = false
			end
			if not info.Tint and not (e.Texturas and fs.isFile("assets/mar/" .. e.Texturas.color) and fs.isFile("assets/mar/" .. e.Texturas.normal)) then
				files = false
				print("    sin texturas horneadas: " .. e.Nombre)
			end
		end
		local count = 0
		for _ in MarKit.Pieces do
			count += 1
		end
		check(seen == count and sameSize, ("Las %d mallas de Blender miden lo que dice MarKit (ancho, alto y fondo)"):format(seen))
		check(inBudget and files and fs.isFile("assets/mar/tex/causticas.png"), "Cada malla en su presupuesto de triángulos, con su FBX, sus texturas de 512 px (las que no van con la paleta) y la de cáusticas")
	else
		check(false, "Falta assets/mar/manifest.json (python3 scripts/map/mar_kit_blender.py)")
	end
	local up = fs.readFile("scripts/upload-mar.sh")
	check(string.find(up, "MarAssetIds.luau", 1, true) ~= nil and string.find(up, "image_of_decal", 1, true) ~= nil and string.find(up, "ROBLOX_API_KEY", 1, true) ~= nil, "scripts/upload-mar.sh sube las mallas y las texturas (Decal → imagen) y escribe MarAssetIds")
	local mm = fs.readFile("src/server/World/MarMeshes.luau")
	check(string.find(mm, "Images.resolve", 1, true) ~= nil and string.find(mm, "RenderFidelity.Automatic", 1, true) ~= nil, "World/MarMeshes pasa los Decal a imagen (shared/Images) y deja el LOD automático")
end

---------------------------------------------------------------------
print("\n▶ Con la malla subida, la zona usa la malla (y si no, el respaldo)")
do
	local ok, Builder = pcall(L.load, "src/server/World/ReefZoneBuilder")
	if not ok then
		check(false, "World/ReefZoneBuilder se carga: " .. tostring(Builder))
	else
		local meshes = roblox.Instance.new("Folder")
		local mp = roblox.Instance.new("MeshPart")
		mp.Name = "CoralCuerno"
		mp.Parent = meshes
		local parent = roblox.Instance.new("Folder")
		local p = { Kind = "CoralCuerno", X = 4300, Y = -14, Z = -300, Yaw = 0, Scale = 3, Color = { 240, 120, 140 }, Group = "Jardin", Region = "B" }
		local budget = { Left = 100 }
		local okMesh, made = pcall(Builder.makePiece, p, parent, meshes, budget)
		check(okMesh and made and made:IsA("MeshPart") and budget.Left == 100 and math.abs(made.Size.Y - 3) < 1e-3, "Con MarMallas: una MeshPart de 3 studs (sin gastar piezas de respaldo)" .. (if okMesh then "" else ": " .. tostring(made)))
		local okFb, fb = pcall(Builder.makePiece, p, parent, nil, budget)
		check(okFb and fb and fb:IsA("Model") and #fb:GetChildren() > 3 and budget.Left < 100, "Sin mallas: el respaldo de piezas (un modelo con sus ramas)" .. (if okFb then "" else ": " .. tostring(fb)))
		if okMesh and made then
			check(made.CanCollide == false and made.CanQuery == false and made.CanTouch == false and made.Anchored and made.CastShadow == false, "Decorado: sin choques, sin consultas, sin toques, anclado y sin sombra")
		end
		-- el total del respaldo cabe en el tope del móvil
		local total = 0
		for _, q in placements do
			total += Builder.fallbackCount(q)
		end
		check(total <= MarKit.PieceCap.Mobile, ("Todo el respaldo de la zona son %d piezas (tope del móvil: %d)"):format(total, MarKit.PieceCap.Mobile))
	end
end

---------------------------------------------------------------------
print("\n▶ Una malla retirada por la moderación de Roblox: esa pieza sigue con su respaldo (docs/bugs/moderacion/)")
do
	local ok, MarMeshes = pcall(L.load, "src/server/World/MarMeshes")
	local okR, Retiradas = pcall(L.load, "src/server/World/MallasRetiradas")
	if not ok or not okR then
		check(false, "World/MarMeshes y World/MallasRetiradas se cargan: " .. tostring(if ok then Retiradas else MarMeshes))
	else
		local retired = next(Retiradas.Ids)
		local function asset(meshId: number): any
			local m = roblox.Instance.new("Model")
			local mp = roblox.Instance.new("MeshPart")
			mp.MeshId = "rbxassetid://" .. meshId
			mp.Parent = m
			return m
		end
		local assets = { [11] = asset(retired), [12] = asset(5012), [13] = asset(5013) }
		local ids = { Mallas = { Pilote = "rbxassetid://11", CoralCuerno = "rbxassetid://12", RocaAguja = "rbxassetid://13" }, Texturas = {} }
		local okP, folder, why = pcall(MarMeshes.prepare, ids, MarKit, function(id)
			return assets[id]
		end)
		check(okP and folder and folder:FindFirstChild("CoralCuerno") and folder:FindFirstChild("RocaAguja") and folder:FindFirstChild("Pilote") == nil and table.find(MarMeshes.Retiradas, "Pilote") ~= nil,
			"MarMeshes: la pieza de malla retirada no entra en MarMallas (las demás sí) y no hay error" .. (if okP then "" else ": " .. tostring(folder)))
		local okB, Builder = pcall(L.load, "src/server/World/ReefZoneBuilder")
		if okB and okP and folder then
			local parent = roblox.Instance.new("Folder")
			local p = { Kind = "Pilote", X = 4300, Y = -14, Z = -300, Yaw = 0, Scale = 1, Color = { 120, 100, 80 }, Group = "Ruina", Region = "B" }
			local okM, made = pcall(Builder.makePiece, p, parent, folder, { Left = 100 })
			check(okM and made and made:IsA("Model") and #made:GetChildren() > 0, "…y en la zona ese pilote sale con su respaldo de piezas")
		end
		-- una malla que no carga en el servidor (CreateMeshPartAsync falla) también se queda fuera
		local okV, folder2 = pcall(MarMeshes.prepare, ids, MarKit, function(id)
			return assets[id]
		end, function(all)
			return Retiradas.bad(all, function(content)
				if string.find(content, "5013", 1, true) then
					error("not approved")
				end
				return true
			end)
		end)
		check(okV and folder2 and folder2:FindFirstChild("RocaAguja") == nil and folder2:FindFirstChild("CoralCuerno") ~= nil, "MarMeshes: una malla que no carga también sigue con el respaldo")
	end
end

---------------------------------------------------------------------
print("\n▶ La paleta y la luz")
do
	local warmY, coolY, nw, nc = 0, 0, 0, 0
	local function same(a, b)
		return a[1] == b[1] and a[2] == b[2] and a[3] == b[3]
	end
	local function inList(c, list)
		for _, x in list do
			if same(c, x) then
				return true
			end
		end
		return false
	end
	local brown = false
	for _, p in placements do
		local info = MarKit.Pieces[p.Kind]
		if info.Group == "Coral" then
			if inList(p.Color, ReefZone.Palette.Warm) then
				warmY += p.Y
				nw += 1
			elseif inList(p.Color, ReefZone.Palette.Cool) then
				coolY += p.Y
				nc += 1
			end
			if ShoreDecor.isBrown(Color3.fromRGB(p.Color[1], p.Color[2], p.Color[3])) then
				brown = true
			end
		end
	end
	check(nw > 20 and nc > 10 and warmY / nw > coolY / nc + 8, ("Corales cálidos arriba (media %.0f) y fríos abajo (media %.0f)"):format(warmY / math.max(nw, 1), coolY / math.max(nc, 1)))
	check(not brown, "Ningún coral marrón")
	check(#ReefZone.Lights <= 4 and #ReefZone.Shafts <= 6 and #ReefZone.Emitters <= 6, ("Pocas luces de verdad (%d), haces (%d) y emisores (%d)"):format(#ReefZone.Lights, #ReefZone.Shafts, #ReefZone.Emitters))
	local kinds = {}
	for _, e in ReefZone.Emitters do
		kinds[e.Kind] = true
	end
	check(kinds.Plancton and kinds.Motas and kinds.Burbujas and kinds.Nieve, "Partículas de varios tamaños y velocidades (plancton, motas, burbujas de una fumarola, nieve marina)")
	local canon = OceanBiomes.look("Canon", 3)
	local deep = OceanBiomes.look("Canon", 30)
	local shore = OceanBiomes.look("Orilla", 2)
	local function lum(c)
		return c.R * 0.3 + c.G * 0.59 + c.B * 0.11
	end
	check(lum(shore.Fog) < 0.5 and lum(shore.Tint) < 0.85, ("La orilla ya no es cian claro y plano (bruma %.2f, tinte %.2f)"):format(lum(shore.Fog), lum(shore.Tint)))
	check(lum(deep.Fog) < lum(canon.Fog) and deep.Exposure < canon.Exposure and deep.Visibility < canon.Visibility, "En el cañón, más hondo = más azul y oscuro (la profundidad se nota)")
end

---------------------------------------------------------------------
print("\n▶ El móvil y lo que se mueve")
do
	local fx = fs.readFile("src/client/Controllers/ReefZoneFx.luau")
	local Fx = L.load("src/client/Controllers/ReefZoneFx")
	check(Fx.MaxSway <= 48 and string.find(fx, "Perf.mobile then math.floor(ReefZoneFx.MaxSway / 3)", 1, true) ~= nil and string.find(fx, "BulkMoveTo", 1, true) ~= nil, "Se mecen como mucho 48 cosas (16 en el móvil), las más cercanas, todas con BulkMoveTo")
	local a1 = Fx.swayAngle(10, 0.1, 30)
	local a2 = Fx.swayAngle(10, 0.6, 30)
	check(math.abs(a1 - a2) > 1e-3, "Cada una a su ritmo (no se mecen todas a la vez)")
	local biome = fs.readFile("src/client/Controllers/SeaBiome.luau")
	check(string.find(biome, "not ReefZone.contains(x, z)", 1, true) ~= nil, "SeaBiome no planta su decorado dentro del cañón (no se duplica)")
	check(string.find(biome, "plantKit(cell, kind, at, r)", 1, true) ~= nil and string.find(biome, "MarMallas", 1, true) ~= nil, "SeaBiome usa las mallas del kit en toda la orilla cuando están subidas")
	check(string.find(biome, "Ocean.noise(cx, cz, 46, 77)", 1, true) ~= nil, "SeaBiome planta en racimos (parches de arrecife y sendas de arena), no repartido por igual")
	local builder = fs.readFile("src/server/World/ReefZoneBuilder.luau")
	check(string.find(builder, "ModelStreamingMode.Atomic", 1, true) ~= nil and string.find(builder, "MarKit.PieceCap.Mobile", 1, true) ~= nil, "Las piezas van por grupos con streaming (Atomic) y con el tope del móvil")
	check(string.find(builder, "Enum.Material.Water", 1, true) ~= nil, "Los huecos (cueva, arco, claraboyas) se rellenan de AGUA, no de aire")
end

if failures > 0 then
	print(("\n❌ %d comprobaciones fallidas"):format(failures))
	process.exit(1)
end
print("\n✅ Cañón de Dorada: todo correcto")
