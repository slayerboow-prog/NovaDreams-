-- Prueba de los assets de cielo, tiempo, efectos, luz y sonidos (shared/SkyExtras, World/SkyAssets)
-- FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):  lune run scripts/test-skyextras.luau
--
-- Con un cargador de mentira (packs montados como los describe docs/assets-usuario-4.md y -5.md, con
-- scripts «virus», letreros con marca y piezas de más) comprueba que:
--   * se borran todos los scripts y los letreros/textos; de los cielos con puerta trasera no se carga
--     nada (solo sus imágenes) y del pack clásico solo se copian las caras (el paquete se destruye)
--   * cada cosa queda donde tiene que estar (cielos en SkyLibrary, luna, fuego y nube en FxLibrary,
--     imágenes como atributos) y las piezas ancladas y sin chocar
--   * las cuentas tienen sentido: qué cielo toca, la luna en el cielo, los pasos según el suelo
--   * si nada carga, el juego sigue: cielos hechos a mano, fuego y lluvia de respaldo, sin errores

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Instance, Vector3 = roblox.Instance, roblox.Vector3

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local warnings = {}
local function load(path: string, env: { [string]: any }?): any
	local e = {
		Enum = roblox.Enum,
		Color3 = roblox.Color3,
		Instance = Instance,
		Vector3 = Vector3,
		CFrame = roblox.CFrame,
		NumberRange = roblox.NumberRange,
		NumberSequence = roblox.NumberSequence,
		NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
		ColorSequence = roblox.ColorSequence,
		warn = function(...)
			table.insert(warnings, table.concat({ ... }, " "))
		end,
	}
	for k, v in env or {} do
		e[k] = v
	end
	setmetatable(e, { __index = getfenv(1) })
	return luau.load(fs.readFile(path), { debugName = path, environment = e })()
end

local SkyExtras = load("src/shared/SkyExtras.luau")
local MeshLibrary = load("src/server/World/MeshLibrary.luau")

---------------------------------------------------------------------
print("Cuentas (shared/SkyExtras)")
---------------------------------------------------------------------
local have = { Isla = true, Verde = true, Arcoiris = true, Asteroides = true, Clasico_Roto = true, Clasico_Invierno = true }
check(SkyExtras.pick({ Prologue = true, Moods = { "GrietaVerde" } }, have) == "Isla", "en el sueño del prólogo, el cielo de la isla (gana a todo)")
check(SkyExtras.pick({ Moods = { "GrietaVerde" }, Weather = "Lluvia" }, have) == "Verde", "la Grieta verde pone el cielo verde")
check(SkyExtras.pick({ Moods = { "Tormenta" }, Weather = "Despejado" }, have) == nil, "una capa sin cielo propio no cambia el cielo")
check(SkyExtras.pick({ Sleeping = true }, have) == "Arcoiris", "dormido: cielo de sueño (arcoíris)")
check(SkyExtras.pick({ Day = 7, Hour = 23, Night = true }, have) == "Asteroides", "noche de estrellas fugaces: cielo de asteroides")
check(SkyExtras.pick({ Day = 8, Hour = 23, Night = true }, have) == nil, "otra noche: la Vía Láctea de siempre")
check(SkyExtras.pick({ Weather = "Tormenta", Night = false }, have) == "Clasico_Roto", "tormenta de día: cielo gris clásico")
check(SkyExtras.pick({ Weather = "Tormenta", Night = false }, {}) == "Original", "tormenta sin clásicos: el cielo de siempre (no el azul de foto)")
check(SkyExtras.pick({ Weather = "Despejado", Night = false }, have) == nil, "día despejado: el cielo de foto de día")
check(SkyExtras.pick({ Weather = "Nieve", Night = true }, have) == nil, "de noche el tiempo no cambia el cielo de noche")
check(SkyExtras.classicSlot("Winterness") == "Clasico_Invierno" and SkyExtras.classicSlot("null_plainsky512 [2009-2013]") == "Clasico_Liso" and SkyExtras.classicSlot("Raro") == nil, "nombres de los cielos clásicos en castellano")
for name, def in SkyExtras.Skies do
	local ok = true
	for _, face in SkyExtras.Faces do
		ok = ok and SkyExtras.validFace(def.Faces[face])
	end
	check(ok, "el cielo " .. name .. " tiene sus 6 caras")
end
check(not SkyExtras.validFace("rbxassetid://1; require(123)") and not SkyExtras.validFace(123) and SkyExtras.validFace("http://www.roblox.com/asset/?id=1327355"), "solo valen caras que son un id de imagen")
local d = SkyExtras.moonDiameter(SkyExtras.MoonDistance, SkyExtras.MoonDegrees)
check(d > 20 and d < 120, ("la luna 3D mide %.0f studs a %d (ni enana ni enorme)"):format(d, SkyExtras.MoonDistance))
check(SkyExtras.moonVisible(23, 0.5) and not SkyExtras.moonVisible(13, 0.5) and not SkyExtras.moonVisible(23, -0.2), "la luna 3D solo de noche y por encima del horizonte")
check(SkyExtras.meteorNight(2, 23) and SkyExtras.meteorNight(7, 0.5) and not SkyExtras.meteorNight(2, 12) and not SkyExtras.meteorNight(3, 23), "la lluvia de estrellas: una noche de cada cinco, de 22:00 a 1:30")
local grass, metal, concrete, carpet = SkyExtras.footstep("Grass"), SkyExtras.footstep("DiamondPlate"), SkyExtras.footstep("Concrete"), SkyExtras.footstep("Fabric")
check(grass and metal and concrete and carpet and grass.Id ~= concrete.Id and metal.Id ~= concrete.Id and carpet.Id ~= concrete.Id, "hierba, metal, hormigón y tela suenan distinto")
check(SkyExtras.footstep("Water") == nil and SkyExtras.footstep("Air") == nil, "en el agua y en el aire no hay pasos")
check(SkyExtras.footstep("Wood").Pitch < 1 and SkyExtras.footstep("Glass").Pitch > 1, "la madera suena más grave y el cristal más agudo")
check(SkyExtras.stepInterval(1) == nil and SkyExtras.stepInterval(10) > SkyExtras.stepInterval(24), "parado no suena; corriendo, pasos más seguidos")
local public = { ["rbxassetid://137390607880889"] = true, ["rbxassetid://136262802708360"] = true, ["rbxassetid://5676592633"] = true, ["rbxassetid://133705377"] = true }
local allPublic = true
for _, s in SkyExtras.Steps do
	allPublic = allPublic and public[s.Id] == true
end
check(allPublic, "los pasos solo usan los audios públicos de los dos packs")
check(SkyExtras.imageKey("Spark 12") == "Chispa" and SkyExtras.imageKey("Dense fog_3") == "HumoDenso" and SkyExtras.imageKey("Small fog") == "Humo" and SkyExtras.imageKey("Comet") == "Cometa" and SkyExtras.imageKey("Heart") == nil, "imágenes del pack de partículas por su nombre")
local srcText = fs.readFile("src/shared/SkyExtras.luau")
check(not srcText:find("195181959"), "el cielo de EVE Online (195181959) no se usa")

---------------------------------------------------------------------
print("Carga (World/SkyAssets) con packs de mentira")
---------------------------------------------------------------------

local function virus(parent: Instance)
	local s = Instance.new("Script")
	s.Name = "SkyLink (Dont Remove)"
	s.Parent = parent
	local m = Instance.new("ModuleScript")
	m.Name = "EasyConfiguration"
	m.Parent = s
	local l = Instance.new("LocalScript")
	l.Name = "Flares"
	l.Parent = parent
end
local function brand(parent: Instance)
	local gui = Instance.new("SurfaceGui")
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Text = "SCP Foundation"
	label.Parent = gui
end
local function model(name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	return m
end
local function part(className: string, name: string, size: Vector3, parent: Instance): BasePart
	local p = Instance.new(className) :: BasePart
	p.Name = name
	p.Size = size
	p.Parent = parent
	return p
end

local packs: { [number]: () -> Instance } = {}
packs[SkyExtras.FireId] = function()
	local m = model("Realistic Fire With Smoke")
	local p = part("Part", "Fire", Vector3.new(4, 1, 2), m)
	local e = Instance.new("ParticleEmitter")
	e.Name = "Fire"
	e.Texture = "rbxassetid://160041569"
	e.Rate = 75
	e.Parent = p
	local s = Instance.new("Smoke")
	s.Parent = p
	virus(m)
	brand(p)
	return m
end
packs[SkyExtras.RainId] = function()
	local m = model("Realistic Rain")
	local p = part("Part", "Rain", Vector3.new(18.1, 0.1, 10.1), m)
	for i = 1, 3 do
		local e = Instance.new("ParticleEmitter")
		e.Name = "Rain" .. i
		e.Texture = "rbxassetid://3806148993"
		e.Rate = 15000
		e.Parent = p
	end
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://9064263922"
	sound.Parent = p
	virus(p)
	return m
end
packs[SkyExtras.ParticlesId] = function()
	local m = model("Bingus Particle Pack")
	local names = { "Spark 1", "Spark 2", "Comet", "Lightning bolt", "Dense fog", "Small fog", "Snowflake", "Leaf", "Heart", "Slash 4" }
	for i, name in names do
		local p = part("Part", name, Vector3.new(8, 0.5, 8), m)
		local decal = Instance.new("Decal")
		decal.Texture = "rbxassetid://" .. (5000 + i)
		decal.Parent = p
	end
	brand(m)
	virus(m)
	return m
end
packs[SkyExtras.MoonMeshId] = function()
	local m = model("Most Realistic Moon")
	local moon = part("MeshPart", "Moon", Vector3.new(11.9, 11.9, 11.9), m)
	local sa = Instance.new("SurfaceAppearance")
	sa.Parent = moon
	local bg = part("Part", "Background", Vector3.new(0, 52.8, 66.5), m)
	local decal = Instance.new("Decal")
	decal.Texture = "rbxassetid://7795740122"
	decal.Parent = bg
	virus(m)
	return m
end
packs[SkyExtras.CloudId] = function()
	local m = model("lightning & thunder cloud")
	local cloud = part("Part", "Cloud", Vector3.new(40, 12, 30), m)
	local mesh = Instance.new("SpecialMesh")
	mesh.Parent = cloud
	local light = Instance.new("PointLight")
	light.Parent = cloud
	local bolt = part("Part", "Lightning", Vector3.new(1, 20, 1), m)
	local light2 = Instance.new("PointLight")
	light2.Parent = bolt
	part("Part", "Other", Vector3.new(2, 2, 2), m)
	return m
end
packs[SkyExtras.WaterId] = function()
	local m = model("Realistic Animated water")
	for i = 1, 3 do
		local p = part("Part", "Water" .. i, Vector3.new(20, 1, 20), m)
		for j = 1, 2 do
			local t = Instance.new("Texture")
			t.Texture = "rbxassetid://" .. (7000 + i * 10 + j)
			t.Parent = p
		end
	end
	virus(m)
	return m
end
local classicAsset: Instance? = nil
packs[SkyExtras.ClassicId] = function()
	local m = model("Classic Skyboxes Collection")
	local holder = part("Part", "Skies", Vector3.new(1, 1, 1), m)
	for i, name in { "Winterness", "Starry Night", "Broken Sky", "Alien Red", "Walls Of Autumn" } do
		local sky = Instance.new("Sky")
		sky.Name = name
		for k, face in SkyExtras.Faces do
			(sky :: any)[face] = "http://www.roblox.com/asset/?id=" .. (1327354 + i * 10 + k)
		end
		sky.Parent = holder
		virus(sky)
	end
	local pose = Instance.new("NumberPose")
	pose.Name = "Pose"
	pose.Parent = holder
	virus(m)
	classicAsset = m
	return m
end

local loaded: { number } = {}
local function fakeLoad(id: number): Instance?
	table.insert(loaded, id)
	local make = packs[id]
	return if make then make() else nil
end

local function world()
	local replicated = Instance.new("Folder")
	replicated.Name = "ReplicatedStorage"
	local shared = Instance.new("Folder")
	shared.Name = "Shared"
	shared.Parent = replicated
	local lighting = Instance.new("Folder")
	lighting.Name = "Lighting"
	local sky = Instance.new("Sky")
	sky.Parent = lighting
	return replicated, lighting, sky
end

local SKYEXTRAS, MESHLIB = {}, {}
local function server(replicated: Instance, lighting: Instance): any
	local services = { ReplicatedStorage = replicated, Lighting = lighting }
	local fakeGame = {
		GetService = function(_, name: string)
			return services[name] or error("servicio de mentira: " .. name)
		end,
	}
	return load("src/server/World/SkyAssets.luau", {
		game = fakeGame,
		script = { Parent = { MeshLibrary = MESHLIB } },
		require = function(m)
			if m == MESHLIB then
				return MeshLibrary
			end
			if typeof(m) == "Instance" and m.Name == "SkyExtras" then
				return SkyExtras
			end
			error("require inesperado")
		end,
	})
end

-- (el módulo hace require(ReplicatedStorage.Shared.SkyExtras): un ModuleScript con ese nombre)
local replicated, lighting, lightingSky = world()
local mod = Instance.new("ModuleScript")
mod.Name = "SkyExtras"
mod.Parent = replicated:FindFirstChild("Shared")
local SkyAssets = server(replicated, lighting)

local ok, err = pcall(SkyAssets.start, fakeLoad)
check(ok, "arranca sin errores con todos los packs: " .. tostring(err))

local library = replicated:FindFirstChild(SkyExtras.Library)
local fx = replicated:FindFirstChild(SkyExtras.FxLibrary)
check(library and fx, "crea SkyLibrary y FxLibrary en ReplicatedStorage")

local scripts, labels = 0, 0
for _, root in { library, fx } do
	for _, item in (root :: Instance):GetDescendants() do
		if item:IsA("LuaSourceContainer") then
			scripts += 1
		elseif item:IsA("SurfaceGui") or item:IsA("TextLabel") or item:IsA("NumberPose") then
			labels += 1
		end
	end
end
check(scripts == 0, "no queda ni un script de los packs")
check(labels == 0, "no queda ningún letrero, texto ni NumberPose (marcas y trucos del virus)")

for _, id in { 113036863157630, 135266547724797, 92375378852064, 122782784244668, 4927992927, 195181959, 93376997873263 } do
	check(not table.find(loaded, id), ("el asset %d no se descarga (virus, daño o de otro juego)"):format(id))
end
for _, name in { "Verde", "Isla", "Arcoiris", "Asteroides", "Clasico_Invierno", "Clasico_Estrellas", "Clasico_Roto", "Clasico_Rojo", "Clasico_Otono" } do
	local sky = library:FindFirstChild(name)
	check(sky and sky:IsA("Sky") and #sky:GetChildren() == 0, "cielo " .. name .. " en SkyLibrary, limpio")
end
check(classicAsset ~= nil and classicAsset.Parent == nil, "el pack clásico descargado no se mete en el juego (destruido)")
check(library:FindFirstChild("Clasico_Invierno").SkyboxUp == "http://www.roblox.com/asset/?id=1327370", "del clásico se copian sus caras")

local moon = fx:FindFirstChild("Luna3D")
check(moon and moon:IsA("MeshPart") and moon.Anchored and not moon.CanCollide, "la luna 3D lista, anclada y sin chocar")
check(moon and moon:FindFirstChildOfClass("SurfaceAppearance") and not moon:FindFirstChildOfClass("Decal"), "la luna conserva su PBR y pierde el fondo negro")
check(not fx:FindFirstChild("Background"), "el fondo negro de la luna no se guarda")
local fire = fx:FindFirstChild("Fuego")
local flames = fire and fire:FindFirstChild("Llamas")
check(flames and flames:IsA("ParticleEmitter") and flames.Texture == "rbxassetid://160041569" and fire:FindFirstChild("Humo"), "el fuego: sus llamas (160041569) y su humo")
check(fire and fire.Anchored and fire.Transparency == 1 and not fire.CanCollide, "la pieza del fuego es invisible, anclada y sin chocar")
local cloud = fx:FindFirstChild("NubeTormenta")
check(cloud and cloud.Name == "NubeTormenta" and cloud.Size.X == 40 and not cloud:FindFirstChildWhichIsA("PointLight"), "la nube de tormenta: la pieza grande, sin su luz")
check(fx:GetAttribute("LluviaImagen") == "rbxassetid://3806148993" and fx:GetAttribute("LluviaSonido") == "rbxassetid://9064263922", "la gota y el sonido de la lluvia")
check(fx:GetAttribute("Img_Chispa") == "rbxassetid://5001" and fx:GetAttribute("Img_Cometa") and fx:GetAttribute("Img_Rayo") and fx:GetAttribute("Img_Copo") and fx:GetAttribute("Img_Hoja") and fx:GetAttribute("Img_Humo"), "imágenes del pack de partículas por nombre (la primera de cada)")
check(fx:GetAttribute("Agua1") and fx:GetAttribute("Agua6") and fx:GetAttribute("Agua7") == nil, "las texturas del agua (como mucho 6)")
check(lightingSky.MoonTextureId == SkyExtras.Moon.TextureId and lightingSky.MoonAngularSize == SkyExtras.Moon.AngularSize, "la luna 2D del cielo con la textura y el tamaño de 12737479807")
check(fx:GetAttribute("Listo") == true, "FxLibrary avisa de que ha acabado")

---------------------------------------------------------------------
print("Si nada carga")
---------------------------------------------------------------------
local replicated2, lighting2 = world()
local mod2 = Instance.new("ModuleScript")
mod2.Name = "SkyExtras"
mod2.Parent = replicated2:FindFirstChild("Shared")
local SkyAssets2 = server(replicated2, lighting2)
warnings = {}
local ok2, err2 = pcall(SkyAssets2.start, function()
	return nil
end)
check(ok2, "sin carga no rompe: " .. tostring(err2))
local fx2 = replicated2:FindFirstChild(SkyExtras.FxLibrary)
local lib2 = replicated2:FindFirstChild(SkyExtras.Library)
check(lib2 and lib2:FindFirstChild("Verde") and lib2:FindFirstChild("Arcoiris") and not lib2:FindFirstChild("Clasico_Invierno"), "sin carga siguen los cielos hechos a mano (y no hay clásicos)")
local fire2 = fx2 and fx2:FindFirstChild("Fuego")
check(fire2 and fire2:FindFirstChild("Llamas") and fire2.Llamas.Texture == SkyExtras.FireImage, "sin carga, fuego de respaldo con su imagen")
check(fx2:GetAttribute("LluviaImagen") == SkyExtras.RainImage and not fx2:FindFirstChild("Luna3D") and not fx2:FindFirstChild("NubeTormenta"), "sin carga: gota de respaldo, sin luna 3D ni nube")
local ok3 = pcall(SkyAssets2.start, function()
	error("la tienda no responde")
end)
check(ok3, "si el cargador lanza un error, tampoco rompe")

---------------------------------------------------------------------
print("Compilan los módulos")
---------------------------------------------------------------------
for _, path in { "src/client/Controllers/SkyExtras.luau", "src/client/Controllers/Footsteps.luau", "src/client/Controllers/DayLight.luau", "src/client/Controllers/CombatFx.luau" } do
	local okc, errc = pcall(luau.compile, fs.readFile(path))
	check(okc, path .. " compila " .. (if okc then "" else tostring(errc)))
end
local main = fs.readFile("src/server/Main.server.luau")
check(main:find("World.SkyAssets", 1, true) ~= nil, "Main.server arranca SkyAssets")
local client = fs.readFile("src/client/Main.client.luau")
check(client:find("Controllers.SkyExtras", 1, true) and client:find("Controllers.Footsteps", 1, true), "Main.client arranca SkyExtras y Footsteps")

print("")
if failures > 0 then
	print(("❌ %d comprobaciones fallan"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
