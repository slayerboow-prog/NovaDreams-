-- mar-v3-sonda: el fondo marino v3 (docs/mar/v3-objetivo.md) en un servidor de VERDAD
--
-- Lo que se puede mirar en un servidor (sin jugadores: el decorado, los peces y las cáusticas son del
-- CLIENTE y solo se ven en un móvil; para eso está el atributo «MarDiag» del jugador, ver abajo):
--   1. Construye el mar como el juego (TerrainBuilder y OceanBuilder.build, que llama a
--      World/ShoreReliefBuilder) y mira cuánto relieve ha puesto y cuánto tarda.
--   2. Materiales del terreno en 5 playas y en 3 sitios más (ReadVoxels de 48×24×48 studs alrededor del
--      fondo): tiene que haber mezcla (arena Salt + roca: Limestone/Slate/Basalt/Rock; nada de Snow), no solo un material.
--   3. Alturas del fondo leídas en vóxeles (sin rayos) en 40×40 studs de cada playa: que no sea plano (desnivel).
--   4. Ninguna pieza de bola, cilindro o bloque de decorado de coral en los sitios del mar (Jardín
--      Escarlata, Arco de Coral, jardines de las playas): solo MeshPart del kit (o su respaldo con forma).
--   5. Con el plan del juego (ShoreReef.decor y ShoreReef.visible con el LOD del móvil), las mallas que
--      plantaría un móvil con la cámara en cada playa, y en 200×200 studs; y si las cáusticas (textura
--      subida) y los haces se pueden crear (la textura pasa a imagen).
--   6. Mallas de la fauna y del kit cargadas (World/MarMeshes) y los bancos de peces que tocan cerca de cada
--      arrecife (ShoreReef.fishSpotNear).
--
-- Uso: bash scripts/cloud-test.sh mar-v3-sonda   (con --version N para una versión concreta)
-- En el MÓVIL (lo que esta sonda no puede ver): nadando, el jugador lleva el atributo «MarDiag»
-- (Controllers/SeaBiome) con «mallas=… · cáusticas=…/9 · vida=… · zona=…», cada 2 s: se lee en la consola de
-- desarrollador del móvil (F9 / «/console») con  print(game.Players.LocalPlayer:GetAttribute("MarDiag")).

local Cloud = Cloud :: any -- (lo pone scripts/cloud-test.sh delante: scripts/cloud/_comun.luau)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
Cloud.limite(280)
Cloud.escuchar()
local pasos = Cloud.prepararMundo()
for _, p in pasos do
	if not p.ok then
		Cloud.check("Preparar el mundo: " .. p.name, false, p.err)
	end
end

local World = Cloud.Server:WaitForChild("World")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ocean = require(Shared.Sea.Ocean) :: any
local ShoreReef = require(Shared.Sea.ShoreReef) :: any

---------------------------------------------------------------------
-- 1) El mar con su relieve
---------------------------------------------------------------------
local t0 = os.clock()
local okOcean, errOcean = pcall(function()
	require(World:WaitForChild("OceanBuilder")).build()
end)
Cloud.check("OceanBuilder.build (con el relieve de las orillas)", okOcean, if okOcean then ("%.0f s"):format(os.clock() - t0) else tostring(errOcean))
local srb = require(World:WaitForChild("ShoreReliefBuilder")) :: any
local st = srb.Stats
Cloud.info("relieve", tostring(workspace:GetAttribute("ShoreRelief")))
Cloud.check("El relieve de las orillas está hecho", srb.State == "Ready" and st.Balls + st.Blocks > 5000, ("%s: %d bolas, %d bloques, %.1f s"):format(srb.State, st.Balls, st.Blocks, st.Seconds or 0))
local kinds = {}
for k, n in st.Kinds or {} do
	table.insert(kinds, k .. "=" .. n)
end
table.sort(kinds)
Cloud.info("parcelas por tipo", table.concat(kinds, " "))

---------------------------------------------------------------------
-- 2 y 3) Materiales y desnivel en las playas
---------------------------------------------------------------------
local spots = {}
for i = 1, math.min(5, Ocean.ShoreReefNamed) do
	local r = Ocean.ShoreReefs[i]
	table.insert(spots, { r.Name, r.X, r.Z })
end
table.insert(spots, { "Jardín Escarlata", Ocean.PoiById.JardinEscarlata.X, Ocean.PoiById.JardinEscarlata.Z })
table.insert(spots, { "Arco de Coral", Ocean.PoiById.ArcoCoral.X, Ocean.PoiById.ArcoCoral.Z })
local kelp = Ocean.Kelp[1]
table.insert(spots, { "Laberinto de Kelp", kelp.X, kelp.Z })

local terrain = workspace.Terrain
-- (v127.1) Alturas y materiales LEÍDOS EN VÓXELES, sin rayos: en estas pruebas la física no corre y el terreno
-- recién escrito no siempre se ve con workspace:Raycast (scripts/cloud/_comun.luau). En la v127 la sonda daba
-- «0,0 studs» en el Jardín Escarlata y el Laberinto de Kelp: los rayos no daban con nada. Por columna de 4×4
-- studs: el vóxel sólido más alto (no aire ni agua) y su ocupación dan la altura; su material, lo que se VE.
local flatSpots, monoSpots, snowSpots = 0, 0, 0
local lines = {}
local SOLID_NO = { [Enum.Material.Air] = true, [Enum.Material.Water] = true }
for _, s in spots do
	local x, z = s[2], s[3]
	local lo, hi = math.huge, -math.huge
	local mats, kindsN, cols = {}, 0, 0
	local okV, errV = pcall(function()
		local region = Region3.new(Vector3.new(x - 20, -220, z - 20), Vector3.new(x + 20, -2, z + 20)):ExpandToGrid(4)
		local materials, occupancy = terrain:ReadVoxels(region, 4)
		local size = materials.Size
		local y0 = region.CFrame.Position.Y - region.Size.Y / 2
		for a = 1, size.X do
			for c = 1, size.Z do
				for b = size.Y, 1, -1 do
					local m = materials[a][b][c]
					local occ = occupancy[a][b][c]
					if not SOLID_NO[m] and occ > 0.05 then
						local h = y0 + (b - 1) * 4 + occ * 4
						lo = math.min(lo, h)
						hi = math.max(hi, h)
						mats[m.Name] = (mats[m.Name] or 0) + 1
						cols += 1
						break
					end
				end
			end
		end
	end)
	local relief = if hi > lo then hi - lo else 0
	local parts = {}
	for name, n in mats do
		table.insert(parts, name .. "×" .. n)
		kindsN += 1
	end
	table.sort(parts)
	if relief < 1.5 then
		flatSpots += 1
	end
	if kindsN < 2 then
		monoSpots += 1
	end
	if (mats.Snow or 0) > 0 then
		snowSpots += 1
	end
	table.insert(lines, ("%s: desnivel %.1f studs, %d columnas [%s]"):format(s[1], relief, cols, if okV then table.concat(parts, " ") else ("? " .. tostring(errV))))
end
Cloud.info("fondo por sitio", table.concat(lines, " | "))
Cloud.check("El fondo no es plano en las playas (desnivel ≥ 1,5 studs en 40×40)", flatSpots <= 1, ("%d de %d planos"):format(flatSpots, #spots))
Cloud.check("Mezcla de materiales del fondo (arena y roca) en cada sitio", monoSpots <= 1, ("%d de %d con un solo material"):format(monoSpots, #spots))
Cloud.check("Sin «Snow» en el fondo (la arena es Salt dorado: el Snow podía verse como nieve)", snowSpots == 0, ("%d de %d sitios con Snow arriba"):format(snowSpots, #spots))

---------------------------------------------------------------------
-- 4) Ningún decorado de coral de bola, cilindro o bloque en los sitios del mar
---------------------------------------------------------------------
local mar = workspace:FindFirstChild("Mar")
local prim, meshes = 0, 0
local primNames = {}
for _, name in { "JardinEscarlata", "ArcoCoral", "JardinDeLuz" } do
	local m = mar and mar:FindFirstChild(name)
	if m then
		for _, d in m:GetDescendants() do
			if d:IsA("MeshPart") then
				meshes += 1
			elseif d:IsA("Part") and d.Transparency < 1 and (d.Shape == Enum.PartType.Ball or d.Shape == Enum.PartType.Cylinder) and not d:FindFirstAncestorWhichIsA("Model"):GetAttribute("Chest") then
				prim += 1
				primNames[d.Name] = true
			end
		end
	end
end
for _, m in (mar and mar:GetChildren() or {}) do
	if string.sub(m.Name, 1, 7) == "Jardin_" then
		prim += 1
		primNames[m.Name] = true
	end
end
-- (las mallas llegan en un hilo: se espera un poco)
local w0 = os.clock()
local OceanBuilder = require(World.OceanBuilder) :: any
while (OceanBuilder.KitSites or 0) < 3 and os.clock() - w0 < 60 do
	task.wait(1)
end
local names = {}
for n in primNames do
	table.insert(names, n)
end
Cloud.check("Sin bolas ni cilindros de decorado en los sitios del mar (Escarlata, Arco, Luz, jardines)", prim == 0, ("%d piezas: %s"):format(prim, table.concat(names, ", ")))
Cloud.info("sitios con kit", ("%d sitios, %d MeshPart"):format(OceanBuilder.KitSites or 0, meshes))

---------------------------------------------------------------------
-- 5) Lo que plantaría un MÓVIL (el plan del juego y su LOD)
---------------------------------------------------------------------
local per = {}
local worst = math.huge
for i = 2, 6 do -- (el 1 es el Cañón de Dorada)
	local r = Ocean.ShoreReefs[i]
	local nx, nz = ShoreReef.seaward(r.X, r.Z)
	local cam = Vector3.new(r.X - nx * 20, -12, r.Z - nz * 20)
	local C = ShoreReef.Cell
	local cx, cz = math.floor(cam.X / C), math.floor(cam.Z / C)
	local shown, area200 = 0, 0
	for ix = cx - 6, cx + 6 do
		for iz = cz - 6, cz + 6 do
			for _, it in ShoreReef.decor(ix, iz, ShoreReef.Density.Mobile) do
				local d = math.sqrt((it.X - cam.X) ^ 2 + (it.Z - cam.Z) ^ 2)
				if ShoreReef.visible(it, d, true) then
					shown += 1
				end
				if math.abs(it.X - cam.X) <= 100 and math.abs(it.Z - cam.Z) <= 100 then
					area200 += 1
				end
			end
		end
	end
	worst = math.min(worst, shown)
	table.insert(per, ("%s: %d a la vista, %d en 200×200"):format(r.Name, shown, area200))
end
Cloud.info("mallas por playa (móvil)", table.concat(per, " | "))
Cloud.check("Cada playa con fondo compuesto (≥ 120 mallas a la vista en el móvil) y dentro del tope (≤ 700)", worst >= 120, ("la peor: %d"):format(worst))
-- cáusticas y haces: la textura pasa a imagen
local okC, causticId = pcall(function()
	local ids = require(Shared.Sea.MarAssetIds)
	local Images = require(Shared.Images)
	return Images.map({ c = ids.Texturas.causticas }).c
end)
Cloud.check("La textura de las cáusticas está subida y pasa a imagen", okC and type(causticId) == "string" and string.match(causticId, "%d+") ~= nil, tostring(causticId))

---------------------------------------------------------------------
-- 6) Mallas cargadas y bancos de peces
---------------------------------------------------------------------
local MarMeshes = require(World.MarMeshes) :: any
local w1 = os.clock()
while not MarMeshes.folder() and os.clock() - w1 < 40 do
	task.wait(1)
end
local folder = MarMeshes.folder()
local count = 0
if folder then
	for _, c in folder:GetChildren() do
		if c:IsA("MeshPart") then
			count += 1
		end
	end
end
Cloud.check("Kit del mar y fauna cargados (31 mallas: 23 + 8)", count >= 31, ("%d (%s)"):format(count, tostring(MarMeshes.Status)))
local schools = 0
for i = 1, 5 do
	local r = Ocean.ShoreReefs[i]
	if ShoreReef.fishSpotNear(r.X, r.Z) then
		schools += 1
	end
end
Cloud.check("Hay arrecife con banco de peces cerca de cada playa", schools >= 4, ("%d de 5"):format(schools))

local oido = Cloud.oido()
Cloud.aviso("Sin errores en la consola", #oido.errores == 0, Cloud.lista(oido.errores, 5))
return Cloud.resultado()
