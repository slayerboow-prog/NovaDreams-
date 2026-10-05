-- Prueba de las zonas de misión fuera de la ciudad (World/MissionZones) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):  lune run scripts/test-missionzones.luau
--
-- Comprueba que:
--   * cada variant que pide existe en el Mega Pack (docs/assets-usuario.md) con su BaseMaterial, no es de
--     los rotos y no es de sangre, calaveras, huesos ni piel humana; usa los 14 asfaltos «Lab», la lava,
--     el metal sci-fi, la roca alienígena y la textura orgánica
--   * todos los sitios están fuera de la ciudad (sin distrito), en tierra, y la mina está DENTRO de su
--     montaña (la boca a ras de suelo, las cámaras con roca encima) y se vacía el terreno donde va
--   * cada sitio lleva la etiqueta ZonaMision con Zona y Nombre; la lava, Peligro = "Lava" y sin daño
--   * pozas con luz, valla de aviso que choca, luces con tope, decorado con CityDetail (gráficos Bajo)
--   * con el Mega Pack: cada pieza con una COPIA del variant (U_Zona_…) sobre su material y su color;
--     sin el pack (o si falla) se monta igual, sin errores

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Enum, Color3, Instance, Vector3, CFrame = roblox.Enum, roblox.Color3, roblox.Instance, roblox.Vector3, roblox.CFrame

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

-- Random de mentira (Lune no lo trae): siempre el mismo
local FakeRandom = {}
FakeRandom.__index = FakeRandom
function FakeRandom.new(seed: number)
	return setmetatable({ s = seed % 2147483647 + 1 }, FakeRandom)
end
function FakeRandom:NextNumber(a: number?, b: number?): number
	self.s = (self.s * 16807) % 2147483647
	local r = self.s / 2147483647
	return (a or 0) + r * ((b or 1) - (a or 0))
end

local tags: { [any]: { [string]: boolean } } = {}
local function tagged(inst: any, tag: string): boolean
	return tags[inst] ~= nil and tags[inst][tag] == true
end
local fakeCS = {
	AddTag = function(_, inst, tag)
		tags[inst] = tags[inst] or {}
		tags[inst][tag] = true
	end,
}
local storage = Instance.new("Folder")
local fakeGame = {
	GetService = function(_, name)
		if name == "CollectionService" then
			return fakeCS
		elseif name == "ServerStorage" then
			return storage
		end
		error("sin " .. name)
	end,
}
local fills = {}
local fakeTerrain = {
	FillBlock = function(_, cf, size, material)
		table.insert(fills, { CFrame = cf, Size = size, Material = material })
	end,
}
local env = {
	game = fakeGame,
	workspace = { Terrain = fakeTerrain },
	Random = FakeRandom,
	Enum = Enum, Color3 = Color3, Instance = Instance, Vector3 = Vector3, CFrame = CFrame, UDim2 = roblox.UDim2,
	task = { wait = function() end },
	warn = print,
}
setmetatable(env, { __index = getfenv(1) })
local Z = luau.load(fs.readFile("src/server/World/MissionZones.luau"), { debugName = "MissionZones", environment = env })()
local CityPlan = luau.load(fs.readFile("src/shared/CityPlan.luau"), { environment = setmetatable({ script = {} }, { __index = getfenv(1) }) })()
Z.CityPlan = CityPlan
local Choice = luau.load(fs.readFile("src/shared/UserMaterialChoice.luau"), { environment = setmetatable({ Color3 = Color3 }, { __index = getfenv(1) }) })()

-- El Mega Pack del doc
local mega: { [string]: string } = {}
do
	local inMega = false
	for line in fs.readFile("docs/assets-usuario.md"):gmatch("[^\n]+") do
		if line:match("^## ") then
			inMega = line:match("^## 15221806045 ") ~= nil
		elseif inMega then
			local name, base = line:match("^| (.-) | (%a+) | ([%d%.]+) | (%a+) |$")
			if name and mega[name] == nil then
				mega[name] = base
			end
		end
	end
end

print("Los variants")
do
	local okRefs, okBroken, okGore = true, true, true
	local n = 0
	for name, base in Z.Variants do
		n += 1
		if mega[name] ~= base then
			okRefs = false
			print(("     %s: en el doc va sobre %s, no %s"):format(name, tostring(mega[name]), base))
		end
		if Choice.isBroken("Mega", name) then
			okBroken = false
		end
		local low = string.lower(name)
		for _, word in { "blood", "skull", "bone", "flesh", "skin", "gore" } do
			if string.find(low, word, 1, true) then
				okGore = false
			end
		end
	end
	check(n > 70 and okRefs, ("%d variants del Mega Pack, cada uno con su BaseMaterial del doc"):format(n))
	check(okBroken, "ninguno de los rotos (Lava, Obsidian, Skulls In Ground…)")
	check(okGore, "nada de sangre, calaveras, huesos ni piel humana")
	local labs = 0
	for name, base in mega do
		if name:match(" Lab$") and base == "Asphalt" then
			labs += 1
			if not table.find(Z.LabFloors, name) then
				print("     falta " .. name)
			end
		end
	end
	check(labs == 14 and #Z.LabFloors == 14, "los 14 asfaltos «Lab» de colores, en el suelo del laboratorio")
	check(Z.Variants["Hot Lava"] and Z.Variants["Spaceship Panels"] and Z.Variants["Lunar Rock"] and Z.Variants["Meat"] and Z.Variants["Cavern Walls"], "lava, metal sci-fi, roca lunar, orgánico y roca de cueva")
end

print("Montaje")
local folder
do
	folder = Z.start(Instance.new("Folder"), fakeTerrain, Instance.new("Folder"), Instance.new("MaterialService"), 0)
	check(folder and folder.Name == "ZonasMision" and #folder:GetDescendants() > 200, ("se montan las zonas (%d instancias)"):format(#folder:GetDescendants()))
	local zones = {}
	for _, m in folder:GetDescendants() do
		if tagged(m, "ZonaMision") then
			zones[m:GetAttribute("Zona")] = m
			if type(m:GetAttribute("Nombre")) ~= "string" or m:GetAttribute("Danio") ~= false then
				zones.bad = true
			end
		end
	end
	local ids = { "Mina", "CamaraLava", "CuevaAlien", "Laboratorio", "MuroOrganico", "CraterLava", "Meteorito", "RiscosMontes" }
	local all = true
	for _, id in ids do
		if not zones[id] then
			all = false
			print("     falta " .. id)
		end
	end
	check(all and not zones.bad, "8 sitios con la etiqueta ZonaMision, su Zona y su Nombre, sin daño (Danio = false)")
	check(zones.CamaraLava:GetAttribute("Peligro") == "Lava" and zones.CraterLava:GetAttribute("Peligro") == "Lava" and zones.CuevaAlien:GetAttribute("Peligro") == nil, "la cámara y el cráter de lava avisan de su peligro")
	-- Fuera de la ciudad y en tierra
	local okOut = true
	for _, part in folder:GetDescendants() do
		if part:IsA("BasePart") then
			local p = part.CFrame.Position
			if CityPlan.districtAt(p.X, p.Z) or not CityPlan.inside(CityPlan.Coast, p.X, p.Z) then
				okOut = false
				print(("     %s en %d, %d"):format(part.Name, p.X, p.Z))
				break
			end
		end
	end
	check(okOut, "todo fuera de los 6 distritos de Valmar y en tierra")
	-- La mina dentro de su montaña
	local mt = Z.Mountain
	local entrance = zones.Mina:GetAttribute("Entrada")
	check(math.abs(Z.groundAt(mt, Z.MineDepth) - entrance.Y) < 1, ("la boca de la mina a ras de suelo (Y = %d)"):format(entrance.Y))
	local covered = true
	for _, part in zones.Mina:GetDescendants() do
		if part:IsA("BasePart") and part.Name == "TechoZona" then
			local p = part.CFrame.Position
			local d = math.sqrt((p.X - mt.X) ^ 2 + (p.Z - mt.Z) ^ 2)
			local top = Z.groundAt(mt, d)
			-- (la galería empieza en la boca: solo el principio puede asomar)
			if d < Z.MineDepth - 40 and top < p.Y + 4 then
				covered = false
				print(("     techo a %d bajo un suelo de %d"):format(p.Y, top))
			end
		end
	end
	check(covered, "galerías y cámaras dentro de la montaña (roca encima)")
	local air = 0
	for _, f in fills do
		if f.Material == Enum.Material.Air then
			air += 1
		end
	end
	check(air >= 4, ("se vacía el terreno de la galería y las cámaras (%d huecos)"):format(air))
	check(Z.groundAt({ R = 380, H = 180, Rock = true }, 0) > 180, "el cráter va sobre la roca de la cumbre (más alta que la hierba)")
	-- Lava, luces, valla, decorado
	local pools, poolLights, lightsN, fenceSolid, decorOk, names = 0, 0, 0, true, true, true
	for _, part in folder:GetDescendants() do
		if part:IsA("PointLight") then
			lightsN += 1
		elseif part:IsA("BasePart") then
			if part.Name == "PozaLava" then
				pools += 1
				if part:FindFirstChildWhichIsA("PointLight") then
					poolLights += 1
				end
			elseif part.Name == "VallaAviso" or part.Name == "PosteAviso" then
				if not part.CanCollide then
					fenceSolid = false
				end
			end
			local decor = part.Name == "Cristal" or part.Name == "RestoNave" or part.Name == "Traviesa" or part.Name == "RocaVolcanica"
			if decor and not (tagged(part, "CityDetail") and not part.CanCollide) then
				decorOk = false
			end
			if (part.Name == "SueloZona" or part.Name == "ParedZona") and tagged(part, "CityDetail") then
				decorOk = false
			end
			if part.Name == "Floor" or part.Name == "Wall" or part.Name == "Ceiling" or part.Name == "Roof" then
				names = false
			end
		end
	end
	check(pools == 3 and poolLights == 3, "3 pozas de lava (2 en la cámara y la del cráter), cada una con su luz")
	check(lightsN <= Z.MaxLights and lightsN >= 10, ("luces con tope (%d de %d)"):format(lightsN, Z.MaxLights))
	check(fenceSolid, "la valla de aviso choca (no se cae nadie a la lava) y no hace daño")
	check(decorOk, "cristales, restos, traviesas y rocas sueltas: decorado (CityDetail, sin choque); suelos y paredes no")
	check(names, "ninguna pieza se llama Floor/Wall/Ceiling/Roof (no la vestirían los de las casas)")
end

print("Variants del Mega Pack")
do
	local lib = Instance.new("Folder")
	local megaFolder = Instance.new("Folder")
	megaFolder.Name = "Mega"
	megaFolder.Parent = lib
	for name, base in Z.Variants do
		local v = Instance.new("MaterialVariant")
		v.Name = Choice.variantName("Mega", name)
		v.BaseMaterial = (Enum.Material :: any)[base]
		v:SetAttribute("SourcePack", "Mega")
		v:SetAttribute("SourceName", name)
		v.Parent = megaFolder
	end
	local service = Instance.new("MaterialService")
	local before = #megaFolder:GetChildren()
	-- (algo la aclara antes, como UserMaterials.tint)
	local meat
	for _, p in folder:GetDescendants() do
		if p:IsA("BasePart") and p.Name == "MuroOrganico" then
			meat = p
			p.Color = Color3.new(1, 1, 1)
		end
	end
	local n, used = Z.dress(folder, megaFolder, service)
	local unused = {}
	for name in Z.Variants do
		if not service:FindFirstChild("U_Zona_" .. name:gsub("[^%w]", "")) then
			table.insert(unused, name)
		end
	end
	check(#unused == 0, "se usan todos los variants de la lista" .. (if #unused > 0 then " (faltan: " .. table.concat(unused, ", ") .. ")" else ""))
	local okAll = true
	for _, p in folder:GetDescendants() do
		if p:IsA("BasePart") and p:GetAttribute("ZonaVariant") then
			local v = service:FindFirstChild(p.MaterialVariant)
			if not v or v.BaseMaterial ~= p.Material or p.MaterialVariant:sub(1, 7) ~= "U_Zona_" then
				okAll = false
			end
		end
	end
	check(n > 200 and okAll, ("%d piezas con su variant (copia U_Zona_… sobre su material)"):format(n))
	check(used > 60 and #service:GetChildren() == used and #megaFolder:GetChildren() == before, ("%d variants copiados a MaterialService; los del Mega Pack siguen en la biblioteca"):format(used))
	check(meat and meat.Color == Color3.fromRGB(150, 90, 180) and meat.MaterialVariant == "U_Zona_Meat", "el muro orgánico, morado alienígena (su color vuelve aunque lo aclaren)")
	local n2 = Z.dress(folder, megaFolder, service)
	check(n2 == 0, "vestir dos veces no hace nada")
end

print("Sin el Mega Pack o con fallos")
do
	local okRun = pcall(function()
		local f = Z.start(Instance.new("Folder"), { FillBlock = function()
			error("sin terreno")
		end }, nil, Instance.new("MaterialService"), 0)
		assert(f and #f:GetDescendants() > 200)
		for _, p in f:GetDescendants() do
			if p:IsA("BasePart") then
				assert(p.MaterialVariant == "")
			end
		end
	end)
	check(okRun, "sin el Mega Pack (y aunque falle el terreno) se monta todo con los materiales de Roblox, sin errores")
end

print("Cableado")
do
	local main = fs.readFile("src/server/Main.server.luau")
	check(main:find("World.MissionZones", 1, true) and main:find("[MissionZones]", 1, true), "Main arranca MissionZones en un hilo aparte con pcall")
end

print("")
if failures > 0 then
	print(("❌ %d comprobaciones fallan"):format(failures))
	process.exit(1)
end
print("✅ Zonas de misión correctas")
