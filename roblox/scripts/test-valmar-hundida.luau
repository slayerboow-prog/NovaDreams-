-- Prueba del bug de la v129 «me devuelve a la ciudad del mar» (docs/bugs/v129-nacara-devuelve), FUERA de
-- Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-valmar-hundida.luau
--
-- El dueño, hondario a 35 m, nadaba hacia el barrio de casas negras con ventanas amarillas (Valmar Hundida,
-- World/OceanBuilder) y aparecía otra vez en su concha de Nácara. No moría: el vigilante anti-enterrados
-- (PositionService.checkBuried) daba por «caído por debajo del mapa» a quien pasara de SafeGround.SafeMinY
-- (−150), sin esperar, y SafeSpot.rescue le llevaba a su cama (la concha). Valmar Hundida está a −174.
--
-- Comprueba:
--   * La causa: el fondo del mar baja de −150 (Valmar Hundida, la fosa del Veril, la Sima del Kraken) y la
--     regla de antes (sin mar) echaba a quien nadara ahí
--   * El arreglo: en el mar, «por debajo del mapa» es por debajo de SU fondo (SafeGround.minYAt +
--     SafeSpot.belowMap); quien nada sobre cualquier fondo del mar no es rescatado, y quien cae de verdad
--     por debajo del fondo, sí. PositionService y SafeSpot.rescue usan esa regla
--   * El barrio negro: Valmar Hundida sin materiales que cambia World/UserMaterials (pizarra, adoquín,
--     mármol, madera: fotos oscuras de los packs del dueño) y en colores claros, como Nácara

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")

local Vector3 = roblox.Vector3
local check = L.check

local Ocean = L.load("src/shared/Sea/Ocean")
local SafeGround = L.load("src/shared/SafeGround")
local UserMaterialChoice = L.load("src/shared/UserMaterialChoice")

---------------------------------------------------------------------
print("▶ La causa: el mar es más hondo que el «fondo del mapa» de antes")
local vh = Ocean.PoiById.ValmarHundida
local vhFloor = Ocean.floorY(vh.X, vh.Z) :: number
check(vhFloor < SafeGround.SafeMinY, ("Valmar Hundida está a y = %.0f (%.0f m), más hondo que SafeMinY = %d"):format(vhFloor, Ocean.meters(vhFloor), SafeGround.SafeMinY))
local swimmer = Vector3.new(vh.X, vhFloor + 6, vh.Z) -- nadando por la calle del barrio
check(SafeGround.belowMap(swimmer, nil), "con la regla de antes (sin mirar el mar), nadar por la calle de Valmar Hundida era «caer por debajo del mapa» (el rescate inmediato a la concha de Nácara)")

---------------------------------------------------------------------
print("\n▶ El arreglo: en el mar, el límite es el fondo de ese sitio")
check(not SafeGround.belowMap(swimmer, vhFloor), "nadando por Valmar Hundida (con su fondo): no está por debajo del mapa")
check(SafeGround.belowMap(Vector3.new(vh.X, vhFloor - SafeGround.SeaMargin - 5, vh.Z), vhFloor), "…y quien cae de verdad por debajo del fondo del mar sigue siendo rescatado")
check(SafeGround.minYAt(nil) == SafeGround.SafeMinY and SafeGround.minYAt(-20) == SafeGround.SafeMinY, "en tierra (o con el fondo por encima de −150) la regla de siempre")

-- Todo el mar: nadar a 2 studs del fondo (o más arriba) nunca es «por debajo del mapa»
local area = Ocean.Area
local samples, bad, deep, deepest = 0, 0, 0, math.huge
for x = area.MinX, area.MaxX, 120 do
	for z = area.MinZ, area.MaxZ, 120 do
		local f = Ocean.floorY(x, z)
		if f then
			samples += 1
			deepest = math.min(deepest, f)
			if f < SafeGround.SafeMinY then
				deep += 1
			end
			if SafeGround.belowMap(Vector3.new(x, f + 2, z), f) then
				bad += 1
			end
		end
	end
end
check(samples > 1000 and deep > 50, ("%d puntos del mar; %d más hondos que −150 (lo más hondo: y = %.0f)"):format(samples, deep, deepest))
check(bad == 0, ("en ningún punto del mar, nadar sobre el fondo te saca (%d malos)"):format(bad))

-- SafeSpot (servidor) usa el fondo de shared/Sea/Ocean
L.services.Players = L.services.Players or { GetPlayers = function()
	return {}
end }
local SafeSpot = L.load("src/server/World/SafeSpot")
check(SafeSpot.seaFloor(vh.X, vh.Z) ~= nil and math.abs((SafeSpot.seaFloor(vh.X, vh.Z) :: number) - vhFloor) < 0.01, "SafeSpot.seaFloor da el fondo del mar de Ocean")
check(not SafeSpot.belowMap(swimmer), "SafeSpot.belowMap: el hondario de la captura (nadando a la calle de Valmar Hundida) ya no es «caído»")
check(SafeSpot.belowMap(Vector3.new(0, -300, 0)), "SafeSpot.belowMap: en tierra, por debajo de −150, sí")
local fakeRoot = { Position = swimmer, CFrame = roblox.CFrame.new(swimmer) }
local fakeCharacter = { FindFirstChild = function(_, name)
	return if name == "HumanoidRootPart" then fakeRoot else nil
end }
local okBuried, buried = pcall(SafeSpot.buried, fakeCharacter)
check(okBuried and buried == false, "SafeSpot.buried: nadando por Valmar Hundida no está enterrado")

-- Nadie más compara con SafeMinY a pelo
local position = fs.readFile("src/server/Services/PositionService.luau")
local safeSpot = fs.readFile("src/server/World/SafeSpot.luau")
check(string.find(position, "SafeSpot.belowMap(root.Position)", 1, true) ~= nil and string.find(position, "Y < SafeGround.SafeMinY", 1, true) == nil, "PositionService.checkBuried: rescate inmediato solo por debajo del fondo de ese sitio")
check(string.find(safeSpot, "Y < SafeGround.SafeMinY", 1, true) == nil and string.find(safeSpot, "Y > SafeGround.SafeMinY", 1, true) == nil, "SafeSpot.buried y SafeSpot.rescue: con belowMap (no con −150 a pelo)")

---------------------------------------------------------------------
print("\n▶ El barrio negro: Valmar Hundida con materiales que no cambian los packs del dueño")
local OceanBuilder = L.load("src/server/World/OceanBuilder")
OceanBuilder.sites()
local mar = L.workspace:FindFirstChild("Mar")
local model = mar and mar:FindFirstChild("ValmarHundida")
check(model ~= nil, "se construye el modelo ValmarHundida")
local swapped = {}
for _, row in UserMaterialChoice.Table do
	swapped[row.Material] = true
end
local allowed = {}
for _, m in OceanBuilder.ValmarHundidaMaterials do
	allowed[m.Name] = true
end
local parts, wrong, dark, houses = 0, {}, 0, 0
for _, d in (if model then model:GetDescendants() else {}) do
	if d:IsA("BasePart") then
		parts += 1
		local name = d.Material.Name
		if swapped[name] or not allowed[name] then
			wrong[name] = (wrong[name] or 0) + 1
		end
		if d.Name == "Casa" or d.Name == "Tejado" or d.Name == "Torre" or d.Name == "Calle" or d.Name == "Plaza" then
			houses += 1
			local c = d.Color
			local lum = 0.2126 * c.R + 0.7152 * c.G + 0.0722 * c.B
			if lum < 0.45 then
				dark += 1
			end
		end
	end
end
local list = {}
for name, n in wrong do
	table.insert(list, ("%s×%d"):format(name, n))
end
check(parts > 100 and #list == 0, ("%d piezas, ninguna de pizarra, adoquín, mármol ni madera (los packs del dueño las ponen casi negras bajo el mar)%s"):format(parts, if #list > 0 then ": " .. table.concat(list, ", ") else ""))
check(houses > 40 and dark == 0, ("casas, tejados, torre, calle y plaza en colores claros (%d piezas, %d oscuras)"):format(houses, dark))
check(not swapped.Sandstone and not swapped.SmoothPlastic, "Sandstone y SmoothPlastic no los cambia World/UserMaterials (como Nácara)")

-- Los demás sitios del mar (pecio, ruinas, batiscafo, ballena, jardines, catedral, cueva, guarida, arco, catedral
-- abisal) y sus cofres: nada de los materiales que cambian los packs del dueño
local siteParts, siteWrong = 0, {}
for _, site in (if mar then mar:GetChildren() else {}) do
	for _, d in site:GetDescendants() do
		if d:IsA("BasePart") and not d:IsA("MeshPart") then
			siteParts += 1
			if swapped[d.Material.Name] then
				local key = site.Name .. ":" .. d.Material.Name
				siteWrong[key] = (siteWrong[key] or 0) + 1
			end
		end
	end
end
local siteList = {}
for k, n in siteWrong do
	table.insert(siteList, ("%s×%d"):format(k, n))
end
check(siteParts > 400 and #siteList == 0, ("todos los sitios del mar (%d piezas): ninguna pieza de pizarra, mármol, adoquín, roca, madera…%s"):format(siteParts, if #siteList > 0 then ": " .. table.concat(siteList, ", ") else ""))
local m1, c1 = OceanBuilder.safeMaterial(roblox.Enum.Material.Slate, roblox.Color3.fromRGB(100, 100, 100))
local m2 = OceanBuilder.safeMaterial(roblox.Enum.Material.Wood, roblox.Color3.fromRGB(100, 70, 40))
check(m1 == roblox.Enum.Material.Sandstone and c1.R > 100 / 255 and m2 == roblox.Enum.Material.SmoothPlastic, "OceanBuilder.safeMaterial: piedra → Sandstone (un poco más clara), madera → SmoothPlastic")

-- Lo más hondo del mar queda por encima de la altura a la que Roblox borra lo que cae
check(OceanBuilder.DestroyHeight < deepest - 100 and OceanBuilder.DestroyHeight < Ocean.Lair.Y - 100, ("FallenPartsDestroyHeight se baja a %d: lo más hondo del mar (y = %.0f) y la guarida (y = %d) quedan por encima"):format(OceanBuilder.DestroyHeight, deepest, Ocean.Lair.Y))
local okSet = pcall(function()
	L.workspace.FallenPartsDestroyHeight = -500
end)
if okSet then
	OceanBuilder.setDestroyHeight()
	check(L.workspace.FallenPartsDestroyHeight == OceanBuilder.DestroyHeight, "OceanBuilder.setDestroyHeight la baja al arrancar el mar")
end
check(string.find(fs.readFile("src/server/World/OceanBuilder.luau"), "\tOceanBuilder.setDestroyHeight()", 1, true) ~= nil, "OceanBuilder.build la llama")

L.finish("Valmar Hundida (bug v129: me devuelve a Nácara)")
