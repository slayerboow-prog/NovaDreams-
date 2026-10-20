-- mar-v125-sonda: el fondo del mar en un servidor de VERDAD (colores del terreno, MaterialService, materiales del fondo)
--
-- La 4.ª queja del dueño (v124): el fondo junto a la orilla se veía blanco nieve. La causa
-- (shared/TerrainPalette): World/PlanetWorld.setupLooks pintaba los colores de Tefra en el MISMO
-- terreno (Salt ceniza clara) después de TerrainBuilder. Esta sonda lo mide con el motor de Roblox:
--
--   1. Arranca el terreno como el juego (TerrainBuilder.build) y, como en Main.server, DESPUÉS
--      PlanetWorld.setupLooks(). Lee Terrain:GetMaterialColor de Salt, Sandstone, Limestone, Sand,
--      Slate, Basalt y Mud: Salt/Sandstone/Limestone tienen que ser los de shared/TerrainPalette.Sea
--      (dorado), no blanco ni la ceniza de Tefra.
--   2. MaterialService: qué MaterialVariant sustituye cada material del fondo
--      (GetBaseMaterialOverride) y qué MaterialVariant hay con BaseMaterial Salt/Sand/Sandstone.
--   3. Materiales del fondo en las orillas de las capturas (Talud del Naufragio / Arrecife Escarlata,
--      Jardín Escarlata, Cañón de Dorada) y en las otras playas: rayo hacia abajo (sin agua) y
--      ReadVoxels de una caja pequeña: qué material y cuánta agua hay encima.
--   4. Que el estado Swimming se puede apagar en un Humanoid del servidor (SetStateEnabled, la base
--      del arreglo de nadar al revés; lo de verdad está en el CLIENTE y solo se ve en un móvil).
--
-- Uso: bash scripts/cloud-test.sh mar-v125-sonda      (con --version N para una versión concreta)
-- Qué mirar: todas en verde; en «info», colores_terreno y materiales_fondo. Si «Salt tras
-- setupLooks» sale (186,178,182) es que la versión publicada aún pinta Tefra en el servidor.

local Cloud = Cloud :: any -- (lo pone scripts/cloud-test.sh delante: scripts/cloud/_comun.luau)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

Cloud.escuchar()
local pasos = Cloud.prepararMundo()
for _, p in pasos do
	if not p.ok then
		Cloud.check("Preparar el mundo: " .. p.name, false, p.err)
	end
end

local terrain = workspace.Terrain
local function rgb(c: Color3?): string
	if not c then
		return "?"
	end
	return ("(%d,%d,%d)"):format(math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
local function colorOf(name: string): Color3?
	local ok, c = pcall(function()
		return terrain:GetMaterialColor((Enum.Material :: any)[name])
	end)
	return if ok then c else nil
end

local okPalette, TerrainPalette = pcall(function()
	return require(ReplicatedStorage.Shared:WaitForChild("TerrainPalette", 5)) :: any
end)
if not okPalette or not TerrainPalette then
	Cloud.check("shared/TerrainPalette está en el juego publicado", false, "no está: la versión publicada es anterior al arreglo v125")
end

local MATERIALS = { "Salt", "Sandstone", "Limestone", "Sand", "Slate", "Basalt", "Mud", "Rock" }

---------------------------------------------------------------------
-- 1) Colores del terreno: tras TerrainBuilder y tras PlanetWorld.setupLooks
---------------------------------------------------------------------
local before = {}
for _, name in MATERIALS do
	before[name] = colorOf(name)
end
-- El océano (Mud y Basalt los pone OceanBuilder.terrain; aquí solo los colores, sin rellenar)
pcall(function()
	local OceanBuilder = require(Cloud.Server.World:WaitForChild("OceanBuilder")) :: any
	if OceanBuilder.terrain and TerrainPalette then
		terrain:SetMaterialColor(Enum.Material.Mud, TerrainPalette.Sea.Mud)
		terrain:SetMaterialColor(Enum.Material.Basalt, TerrainPalette.Sea.Basalt)
	end
end)
local okLooks, errLooks = pcall(function()
	require(Cloud.Server.World:WaitForChild("PlanetWorld")).setupLooks()
end)
Cloud.aviso("PlanetWorld.setupLooks se ejecuta", okLooks, if okLooks then "" else tostring(errLooks))
local after = {}
local lines = {}
for _, name in MATERIALS do
	after[name] = colorOf(name)
	table.insert(lines, ("%s %s→%s"):format(name, rgb(before[name]), rgb(after[name])))
end
Cloud.info("colores_terreno (tras TerrainBuilder → tras setupLooks)", table.concat(lines, "; "))
for _, name in { "Salt", "Sandstone", "Limestone" } do
	local c = after[name]
	local want = okPalette and TerrainPalette and TerrainPalette.Sea[name]
	local okColor = c ~= nil and want ~= nil and TerrainPalette.same(c, want) and not TerrainPalette.snowy(c)
	Cloud.check(("%s del fondo del mar sigue dorado tras setupLooks"):format(name), okColor, ("es %s, tiene que ser %s"):format(rgb(c), rgb(want)))
end

---------------------------------------------------------------------
-- 2) MaterialService: sustituciones del fondo
---------------------------------------------------------------------
local MaterialService = game:GetService("MaterialService")
local overrides = {}
for _, name in MATERIALS do
	local ok, variant = pcall(function()
		return MaterialService:GetBaseMaterialOverride((Enum.Material :: any)[name])
	end)
	table.insert(overrides, ("%s=%s"):format(name, if ok then (if variant == "" then "—" else tostring(variant)) else "?"))
end
Cloud.info("MaterialService_overrides", table.concat(overrides, "; "))
local variants = {}
for _, v in MaterialService:GetDescendants() do
	if v:IsA("MaterialVariant") and (v.BaseMaterial == Enum.Material.Salt or v.BaseMaterial == Enum.Material.Sandstone or v.BaseMaterial == Enum.Material.Sand) then
		table.insert(variants, ("%s(%s)"):format(v.Name, v.BaseMaterial.Name))
	end
end
Cloud.info("MaterialVariant_de_arena", if #variants > 0 then table.concat(variants, ", ") else "ninguno")
local okSalt, saltOverride = pcall(function()
	return MaterialService:GetBaseMaterialOverride(Enum.Material.Salt)
end)
Cloud.check("Ningún MaterialVariant sustituye Salt (el fondo usa su color)", okSalt and saltOverride == "", tostring(saltOverride))
Cloud.info("Use2022Materials", tostring(MaterialService.Use2022Materials))

---------------------------------------------------------------------
-- 3) El fondo en las orillas (el terreno de TerrainBuilder: -24..-14 Salt, agua hasta -2)
---------------------------------------------------------------------
local okOcean, Ocean = pcall(function()
	return require(ReplicatedStorage.Shared.Sea.Ocean) :: any
end)
local points = {}
if okOcean then
	for _, poi in Ocean.Pois or {} do
		if poi.Id == "JardinEscarlata" or poi.Id == "ArcoCoral" then
			table.insert(points, { poi.Name, poi.X, poi.Z })
		end
	end
	for i, reef in Ocean.ShoreReefs or {} do
		if i <= 9 then
			table.insert(points, { reef.Name, reef.X, reef.Z })
		end
	end
end
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { terrain }
params.IgnoreWater = true
local found = {}
local white = 0
for _, p in points do
	local hit = workspace:Raycast(Vector3.new(p[2], 20, p[3]), Vector3.new(0, -80, 0), params)
	local text = if hit then ("%s Y=%.0f"):format(hit.Material.Name, hit.Position.Y) else "sin terreno"
	-- ReadVoxels: una caja de 8×40×8 studs encima del fondo
	local okV, mats = pcall(function()
		local region = Region3.new(Vector3.new(p[2] - 4, -26, p[3] - 4), Vector3.new(p[2] + 4, 2, p[3] + 4)):ExpandToGrid(4)
		local m, _ = terrain:ReadVoxels(region, 4)
		local counts = {}
		for x = 1, m.Size.X do
			for y = 1, m.Size.Y do
				for z = 1, m.Size.Z do
					local name = m[x][y][z].Name
					counts[name] = (counts[name] or 0) + 1
				end
			end
		end
		local parts = {}
		for name, n in counts do
			table.insert(parts, name .. "×" .. n)
		end
		table.sort(parts)
		return table.concat(parts, " ")
	end)
	table.insert(found, ("%s: %s [%s]"):format(p[1], text, if okV then mats else "?"))
	if hit and okPalette and TerrainPalette then
		local c = colorOf(hit.Material.Name)
		if c and TerrainPalette.snowy(c) then
			white += 1
		end
	end
end
Cloud.info("materiales_fondo", table.concat(found, " | "))
Cloud.check("Ningún fondo de orilla con un material de color blanco nieve", white == 0, ("%d de %d"):format(white, #points))

---------------------------------------------------------------------
-- 4) Apagar el estado Swimming (lo que hace Controllers/Swimming en el cliente)
---------------------------------------------------------------------
do
	local okH, detail = pcall(function()
		local model = Instance.new("Model")
		local humanoid = Instance.new("Humanoid")
		humanoid.Parent = model
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
		local off = humanoid:GetStateEnabled(Enum.HumanoidStateType.Swimming)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
		local on = humanoid:GetStateEnabled(Enum.HumanoidStateType.Swimming)
		model:Destroy()
		return ("apagado=%s, encendido=%s"):format(tostring(not off), tostring(on))
	end)
	Cloud.check("Humanoid:SetStateEnabled(Swimming) funciona en este motor", okH and detail == "apagado=true, encendido=true", tostring(detail))
end

local oido = Cloud.oido()
Cloud.aviso("Sin errores en la consola", #oido.errores == 0, Cloud.lista(oido.errores, 5))
return Cloud.resultado()
